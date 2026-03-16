--!nocheck
-- AdaptiveWorldNavigator_Ultimate
-- Real-time adaptive navigator with:
-- - automatic body/profile derivation from the current Humanoid and character extents
-- - workspace auto-mapping + descendant change tracking + dynamic-part dirtying
-- - hazard memory and support-aware planning
-- - short-horizon trajectory scoring each frame
-- - state-aware humanoid controller with proactive jump / safe-drop validation
-- - PreSimulation stepping when available, Heartbeat fallback otherwise
--
-- Public API intentionally stays minimal:
--   local NAV = require(Module).new():Start()
--   local mover = NAV:CreateMover(humanoid)
--   mover:SetGoal(Vector3.new(...))
--   mover:SetLookAt(optionalVector3)
--   mover:Stop()

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Navigator = {}
Navigator.__index = Navigator

local STEP_SIGNAL = RunService.PreSimulation or RunService.Heartbeat

local SEARCH_NODE_LIMIT = 2000
local CLEARANCE_PAD = 0.15
local RAY_MARGIN_Y = 256
local RAY_DEPTH = 900
local CACHE_SOFT_LIMIT = 28000
local DIRTY_REGION_TTL = 3.5
local DIRTY_REGION_MAX = 768
local DYNAMIC_SCAN_BUDGET = 6
local DYNAMIC_MOVE_EPS = 0.35
local HAZARD_MAX = 256
local HAZARD_TTL = 12
local TRAJECTORY_SAMPLE_CAP = 4
local STUCK_EPS = 0.65
local TURN_RESPONSIVENESS = 55

local SQRT2 = math.sqrt(2)
local HUGE = math.huge

local AIR_STATES = {
    [Enum.HumanoidStateType.Freefall] = true,
    [Enum.HumanoidStateType.FallingDown] = true,
    [Enum.HumanoidStateType.Jumping] = true,
}

local GROUNDED_STATES = {
    [Enum.HumanoidStateType.Running] = true,
    [Enum.HumanoidStateType.RunningNoPhysics] = true,
    [Enum.HumanoidStateType.Landed] = true,
    [Enum.HumanoidStateType.Climbing] = true,
    [Enum.HumanoidStateType.PlatformStanding] = true,
    [Enum.HumanoidStateType.Seated] = true,
}

local function nowS()
    return os.clock()
end

local function clamp(n, mn, mx)
    if n < mn then return mn end
    if n > mx then return mx end
    return n
end

local function flat(v)
    return Vector3.new(v.X, 0, v.Z)
end

local function safeUnit(v)
    local m = v.Magnitude
    if m < 1e-5 then
        return Vector3.zero
    end
    return v / m
end

local function keyOf(prefix, cx, cz)
    return prefix .. ":" .. tostring(cx) .. ":" .. tostring(cz)
end

local function cellIndex(v, cellSize)
    return math.floor(v / cellSize + 0.5)
end

local function lerpNumber(a, b, t)
    return a + (b - a) * t
end

local function perpendicularLeft(v)
    return Vector3.new(-v.Z, 0, v.X)
end

local function signedAngleFlat(a, b)
    local ua = safeUnit(flat(a))
    local ub = safeUnit(flat(b))
    if ua.Magnitude < 0.01 or ub.Magnitude < 0.01 then
        return 0
    end
    local dot = clamp(ua:Dot(ub), -1, 1)
    local cross = ua.X * ub.Z - ua.Z * ub.X
    return math.atan2(cross, dot)
end

local function humanoidAncestor(inst)
    if not inst then
        return nil
    end
    local model = inst:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return model
    end
    return nil
end

local function isBlockingPart(inst, ignoreModel)
    if not inst or not inst:IsA("BasePart") then
        return false
    end
    local part = inst
    if not part.Parent then
        return false
    end
    if not part.CanCollide then
        return false
    end
    if part.Transparency >= 1 then
        return false
    end
    local humModel = humanoidAncestor(part)
    if humModel and ignoreModel and humModel == ignoreModel then
        return false
    end
    return true
end

local function getRootAndCharacter(humanoid)
    local char = humanoid.Parent
    if not char or not char:IsA("Model") then
        return nil, nil
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return nil, nil
    end
    return root, char
end

local function getHumanoidJumpPower(humanoid, gravity)
    local jumpPower = humanoid.JumpPower
    if humanoid.UseJumpPower == false then
        local jumpHeight = humanoid.JumpHeight
        if jumpHeight > 0 then
            jumpPower = math.sqrt(2 * gravity * jumpHeight)
        end
    end
    if jumpPower <= 0 then
        jumpPower = math.sqrt(2 * gravity * math.max(humanoid.HipHeight + 2, 3))
    end
    return jumpPower
end

local MinHeap = {}
MinHeap.__index = MinHeap

function MinHeap.new()
    return setmetatable({items = {}}, MinHeap)
end

function MinHeap:push(item, priority)
    local items = self.items
    local node = {item = item, priority = priority}
    table.insert(items, node)
    local i = #items
    while i > 1 do
        local p = math.floor(i / 2)
        if items[p].priority <= items[i].priority then
            break
        end
        items[p], items[i] = items[i], items[p]
        i = p
    end
end

function MinHeap:pop()
    local items = self.items
    local n = #items
    if n == 0 then
        return nil
    end
    local root = items[1]
    if n == 1 then
        items[1] = nil
        return root.item
    end
    items[1] = items[n]
    items[n] = nil
    n -= 1
    local i = 1
    while true do
        local l = i * 2
        local r = l + 1
        local s = i
        if l <= n and items[l].priority < items[s].priority then
            s = l
        end
        if r <= n and items[r].priority < items[s].priority then
            s = r
        end
        if s == i then
            break
        end
        items[i], items[s] = items[s], items[i]
        i = s
    end
    return root.item
end

function MinHeap:isEmpty()
    return #self.items == 0
end

function Navigator.new()
    local self = setmetatable({}, Navigator)
    self._cells = {}
    self._dirtyRegions = {}
    self._hazards = {}
    self._cons = {}
    self._worldBounds = {hasAny = false, maxY = 0}
    self._activeMovers = {}
    self._started = false
    self._dynamicParts = {}
    self._dynamicList = {}
    self._dynamicCursor = 1
    self._planBatchWorst = 0
    return self
end

function Navigator:_touchBounds(part)
    local half = part.Size * 0.5
    local maxY = part.Position.Y + half.Y
    if not self._worldBounds.hasAny or maxY > self._worldBounds.maxY then
        self._worldBounds.maxY = maxY
        self._worldBounds.hasAny = true
    end
end

function Navigator:_pushDirtyRegion(minX, maxX, minZ, maxZ)
    table.insert(self._dirtyRegions, {
        minX = math.min(minX, maxX),
        maxX = math.max(minX, maxX),
        minZ = math.min(minZ, maxZ),
        maxZ = math.max(minZ, maxZ),
        stamp = nowS(),
    })
    if #self._dirtyRegions > DIRTY_REGION_MAX then
        local cut = math.floor(DIRTY_REGION_MAX * 0.25)
        for i = 1, cut do
            table.remove(self._dirtyRegions, 1)
        end
    end
end

function Navigator:_markPartDirty(part)
    self:_touchBounds(part)
    local half = part.Size * 0.5 + Vector3.new(8, 0, 8)
    local p = part.Position
    self:_pushDirtyRegion(p.X - half.X, p.X + half.X, p.Z - half.Z, p.Z + half.Z)
end

function Navigator:InvalidateRadius(position, radius)
    self:_pushDirtyRegion(position.X - radius, position.X + radius, position.Z - radius, position.Z + radius)
end

function Navigator:_pruneDirtyRegions()
    local t = nowS()
    local out = {}
    for _, region in ipairs(self._dirtyRegions) do
        if t - region.stamp <= DIRTY_REGION_TTL then
            table.insert(out, region)
        end
    end
    self._dirtyRegions = out
end

function Navigator:_cacheTrimIfNeeded()
    local count = 0
    for _ in pairs(self._cells) do
        count += 1
        if count > CACHE_SOFT_LIMIT then
            self._cells = {}
            return
        end
    end
end

function Navigator:_pruneHazards()
    local t = nowS()
    local out = {}
    for _, hazard in ipairs(self._hazards) do
        if hazard.expiresAt > t then
            table.insert(out, hazard)
        end
    end
    self._hazards = out
end

function Navigator:_registerDynamic(part)
    if self._dynamicParts[part] then
        return
    end
    self._dynamicParts[part] = {
        position = part.Position,
        size = part.Size,
    }
    table.insert(self._dynamicList, part)
end

function Navigator:_unregisterDynamic(part)
    if not self._dynamicParts[part] then
        return
    end
    self._dynamicParts[part] = nil
    for i = #self._dynamicList, 1, -1 do
        if self._dynamicList[i] == part then
            table.remove(self._dynamicList, i)
            if self._dynamicCursor > #self._dynamicList then
                self._dynamicCursor = 1
            end
            break
        end
    end
end

function Navigator:_processDynamicParts()
    local list = self._dynamicList
    local n = #list
    if n == 0 then
        return
    end
    local budget = math.min(DYNAMIC_SCAN_BUDGET, n)
    for _ = 1, budget do
        if self._dynamicCursor > n then
            self._dynamicCursor = 1
        end
        local part = list[self._dynamicCursor]
        self._dynamicCursor += 1
        if not part or not part.Parent then
            if part then
                self:_unregisterDynamic(part)
                n = #list
            end
        else
            local record = self._dynamicParts[part]
            if record then
                local moved = (part.Position - record.position).Magnitude > DYNAMIC_MOVE_EPS
                local resized = (part.Size - record.size).Magnitude > 0.01
                local dynamicMotion = (part.AssemblyLinearVelocity.Magnitude > 0.05) or (part.AssemblyAngularVelocity.Magnitude > 0.05)
                if moved or resized or dynamicMotion then
                    self:_markPartDirty(part)
                    record.position = part.Position
                    record.size = part.Size
                end
            end
        end
    end
end

function Navigator:RecordHazard(position, radius, score, ttl)
    table.insert(self._hazards, {
        position = position,
        radius = math.max(radius, 1),
        score = math.max(score, 0),
        expiresAt = nowS() + math.max(ttl or HAZARD_TTL, 0.5),
    })
    if #self._hazards > HAZARD_MAX then
        table.remove(self._hazards, 1)
    end
end

function Navigator:_hazardAt(position)
    local total = 0
    local t = nowS()
    for i = #self._hazards, 1, -1 do
        local h = self._hazards[i]
        if h.expiresAt <= t then
            table.remove(self._hazards, i)
        else
            local d = (flat(position) - flat(h.position)).Magnitude
            if d <= h.radius then
                local falloff = 1 - (d / math.max(h.radius, 1e-3))
                total += h.score * falloff
            end
        end
    end
    return total
end

function Navigator:Start()
    if self._started then
        return self
    end
    self._started = true

    -- No blocking initial scan — bounds and dynamic parts discovered lazily via events
    table.insert(self._cons, Workspace.DescendantAdded:Connect(function(inst)
        if inst:IsA("BasePart") then
            self:_touchBounds(inst)
            self:_markPartDirty(inst)
            if (not inst.Anchored) or humanoidAncestor(inst) then
                self:_registerDynamic(inst)
            end
        end
    end))

    table.insert(self._cons, Workspace.DescendantRemoving:Connect(function(inst)
        if inst:IsA("BasePart") then
            self:_markPartDirty(inst)
            self:_unregisterDynamic(inst)
        end
    end))

    -- Background scan: time-budgeted, not count-based
    task.spawn(function()
        local descendants = Workspace:GetDescendants()
        local scanT0 = nowS()
        for _, inst in ipairs(descendants) do
            if inst:IsA("BasePart") then
                self:_touchBounds(inst)
                if (not inst.Anchored) or humanoidAncestor(inst) then
                    self:_registerDynamic(inst)
                end
            end
            if nowS() - scanT0 >= 0.003 then
                RunService.Heartbeat:Wait()
                scanT0 = nowS()
            end
        end
    end)

    local lastHousekeep = 0
    table.insert(self._cons, STEP_SIGNAL:Connect(function()
        local t = nowS()
        if t - lastHousekeep < 2 then return end
        lastHousekeep = t
        self:_pruneDirtyRegions()
        self:_pruneHazards()
        self:_processDynamicParts()
    end))

    return self
end

function Navigator:Destroy()
    for _, con in ipairs(self._cons) do
        con:Disconnect()
    end
    self._cons = {}
    self._cells = {}
    self._dirtyRegions = {}
    self._hazards = {}
    self._dynamicParts = {}
    self._dynamicList = {}
    self._activeMovers = {}
end

function Navigator:_profile(humanoid)
    local root, character = getRootAndCharacter(humanoid)
    if not root or not character then
        return nil
    end

    local extents = character:GetExtentsSize()
    local gravity = Workspace.Gravity
    local jumpPower = getHumanoidJumpPower(humanoid, gravity)
    local velocity = root.AssemblyLinearVelocity
    local horizontalSpeed = flat(velocity).Magnitude
    local walkSpeed = math.max(humanoid.WalkSpeed, horizontalSpeed)
    local maxSlopeAngle = clamp(humanoid.MaxSlopeAngle or 45, 10, 89)
    local slopeNormalY = math.cos(math.rad(maxSlopeAngle + 1.5))

    local radius = math.max(root.Size.X, root.Size.Z, extents.X * 0.45, extents.Z * 0.45) * 0.5 + 0.15
    local height = math.max(extents.Y, humanoid.HipHeight * 2 + root.Size.Y + 1)
    local stepHeight = clamp(humanoid.HipHeight + root.Size.Y * 0.35 + 0.5, root.Size.Y * 0.5, math.max(3, height * 0.45))
    local cellSize = clamp(radius * 1.7, math.max(2.5, radius * 1.15), math.max(5.5, radius * 2.25))
    local maxRise = (jumpPower * jumpPower) / (2 * gravity)
    local flight = (2 * jumpPower) / gravity
    local jumpBoost = clamp(1 + horizontalSpeed / math.max(walkSpeed, 1), 1, 1.4)
    local jumpReach = math.max(cellSize * 1.75, walkSpeed * flight * jumpBoost)
    local probeDistance = clamp(radius * 2.25 + walkSpeed * 0.12, radius * 1.5, jumpReach * 0.45)
    local dynamicRadius = clamp(walkSpeed * 2.75 + radius * 5, cellSize * 5, jumpReach * 2.5 + radius * 4)
    local replanInterval = clamp((cellSize / math.max(1, walkSpeed)) * 0.85, 1 / 60, 0.22)
    local reachedRadius = math.max(radius * 1.5, cellSize * 0.8)
    local safeDrop = math.max(maxRise * 0.95, humanoid.HipHeight + root.Size.Y * 1.25)
    local brakingDistance = math.max(radius * 2, horizontalSpeed * replanInterval * 3 + cellSize * 0.75)
    local horizon = clamp((cellSize * 1.5 + radius * 2) / math.max(1, walkSpeed), 0.16, 0.42)

    local prefix = table.concat({
        tostring(math.round(cellSize * 10)),
        tostring(math.round(radius * 10)),
        tostring(math.round(height * 10)),
        tostring(math.round(maxSlopeAngle * 10)),
    }, "|")

    return {
        Root = root,
        Character = character,
        Gravity = gravity,
        JumpPower = jumpPower,
        WalkSpeed = walkSpeed,
        Radius = radius,
        Height = height,
        StepHeight = stepHeight,
        CellSize = cellSize,
        MaxRise = maxRise,
        JumpReach = jumpReach,
        JumpBoost = jumpBoost,
        ProbeDistance = probeDistance,
        DynamicRadius = dynamicRadius,
        ReplanInterval = replanInterval,
        ReachedRadius = reachedRadius,
        SlopeNormalY = slopeNormalY,
        Prefix = prefix,
        SafeDrop = safeDrop,
        BrakingDistance = brakingDistance,
        Horizon = horizon,
        HorizontalSpeed = horizontalSpeed,
    }
end

function Navigator:_getRayParams(exclusions)
    if not self._cachedRayParams then
        self._cachedRayParams = RaycastParams.new()
        self._cachedRayParams.FilterType = Enum.RaycastFilterType.Exclude
    end
    self._cachedRayParams.FilterDescendantsInstances = exclusions or {}
    return self._cachedRayParams
end

function Navigator:_getOverlapParams(exclusions)
    if not self._cachedOverlapParams then
        self._cachedOverlapParams = OverlapParams.new()
        self._cachedOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
        self._cachedOverlapParams.MaxParts = 64
    end
    self._cachedOverlapParams.FilterDescendantsInstances = exclusions or {}
    return self._cachedOverlapParams
end

-- Keep old names working
function Navigator:_makeRayParams(exclusions)
    return self:_getRayParams(exclusions)
end

function Navigator:_makeOverlapParams(exclusions)
    return self:_getOverlapParams(exclusions)
end

function Navigator:_cellWorld(profile, cx, cz)
    return Vector3.new(cx * profile.CellSize, 0, cz * profile.CellSize)
end

function Navigator:_isDirty(profile, cx, cz, computedAt)
    local p = self:_cellWorld(profile, cx, cz)
    for i = #self._dirtyRegions, 1, -1 do
        local region = self._dirtyRegions[i]
        if region.stamp > computedAt then
            if p.X >= region.minX and p.X <= region.maxX and p.Z >= region.minZ and p.Z <= region.maxZ then
                return true
            end
        else
            break
        end
    end
    return false
end

function Navigator:_floorHit(profile, position, ignoreModel, extraHeight)
    local highY = math.max(
        position.Y + (extraHeight or (profile.Height + profile.StepHeight + 8)),
        self._worldBounds.hasAny and (self._worldBounds.maxY + 64) or RAY_MARGIN_Y
    )

    local hit = Workspace:Raycast(
        Vector3.new(position.X, highY, position.Z),
        Vector3.new(0, -(highY + RAY_DEPTH), 0),
        self:_getRayParams(ignoreModel and {ignoreModel} or {})
    )

    if not hit or not hit.Instance then
        return nil
    end
    if hit.Normal.Y < profile.SlopeNormalY then
        return nil
    end
    return hit
end

function Navigator:_clearanceBox(profile, floorPos)
    return CFrame.new(floorPos.X, floorPos.Y + profile.Height * 0.5 + CLEARANCE_PAD, floorPos.Z), Vector3.new(
        profile.Radius * 2,
        math.max(0.5, profile.Height - CLEARANCE_PAD),
        profile.Radius * 2
    )
end

function Navigator:_hasClearance(profile, floorPos, ignoreModel)
    local cf, size = self:_clearanceBox(profile, floorPos)
    local overlaps = Workspace:GetPartBoundsInBox(cf, size, self:_makeOverlapParams(ignoreModel and {ignoreModel} or {}))
    for _, part in ipairs(overlaps) do
        if isBlockingPart(part, ignoreModel) then
            return false
        end
    end
    return true
end

function Navigator:_supportScore(profile, floorPos, baseFloorY, ignoreModel)
    local offsets = {
        Vector3.zero,
        Vector3.new(profile.Radius * 0.55, 0, 0),
        Vector3.new(-profile.Radius * 0.55, 0, 0),
        Vector3.new(0, 0, profile.Radius * 0.55),
        Vector3.new(0, 0, -profile.Radius * 0.55),
    }
    local good = 0
    local total = #offsets
    for _, offset in ipairs(offsets) do
        local hit = self:_floorHit(profile, floorPos + offset + Vector3.new(0, profile.Height * 0.25, 0), ignoreModel, profile.Height + profile.StepHeight + 10)
        if hit and math.abs(hit.Position.Y - baseFloorY) <= math.max(profile.StepHeight, profile.Root.Size.Y * 0.6) then
            good += 1
        end
    end
    return good / math.max(total, 1)
end

function Navigator:_standInfo(profile, position, ignoreModel, extraHeight)
    local hit = self:_floorHit(profile, position, ignoreModel, extraHeight)
    if not hit then
        return nil
    end
    local floorPos = Vector3.new(position.X, hit.Position.Y, position.Z)
    if not self:_hasClearance(profile, floorPos, ignoreModel) then
        return nil
    end
    local support = self:_supportScore(profile, floorPos, floorPos.Y, ignoreModel)
    if support <= 0 then
        return nil
    end
    return {
        pos = floorPos,
        floorY = floorPos.Y,
        normal = hit.Normal,
        instance = hit.Instance,
        support = support,
    }
end

function Navigator:_computeNode(profile, cx, cz, ignoreModel)
    local center = self:_cellWorld(profile, cx, cz)
    local node = {
        key = keyOf(profile.Prefix, cx, cz),
        cx = cx,
        cz = cz,
        pos = center,
        floorY = -HUGE,
        normal = Vector3.yAxis,
        walkable = false,
        support = 1,
        computedAt = nowS(),
    }

    -- Lightweight: just floor hit + clearance check (2 ops instead of 7)
    local hit = self:_floorHit(profile, center, ignoreModel, profile.Height + profile.StepHeight + 12)
    if not hit then
        return node
    end
    local floorPos = Vector3.new(center.X, hit.Position.Y, center.Z)
    if not self:_hasClearance(profile, floorPos, ignoreModel) then
        return node
    end

    node.walkable = true
    node.pos = floorPos
    node.floorY = floorPos.Y
    node.normal = hit.Normal
    node.support = 1
    return node
end

function Navigator:_getNode(profile, cx, cz, ignoreModel)
    local key = keyOf(profile.Prefix, cx, cz)
    local cached = self._cells[key]
    if cached and not self:_isDirty(profile, cx, cz, cached.computedAt) then
        return cached
    end
    local node = self:_computeNode(profile, cx, cz, ignoreModel)
    self._cells[key] = node
    return node
end

function Navigator:_nearestWalkable(profile, position, ignoreModel, rings)
    local maxRings = rings or 5
    local baseCX = cellIndex(position.X, profile.CellSize)
    local baseCZ = cellIndex(position.Z, profile.CellSize)
    local best = nil
    local bestScore = HUGE

    for r = 0, maxRings do
        for dx = -r, r do
            for dz = -r, r do
                if r == 0 or math.abs(dx) == r or math.abs(dz) == r then
                    local node = self:_getNode(profile, baseCX + dx, baseCZ + dz, ignoreModel)
                    if node.walkable then
                        local dist = (node.pos - position).Magnitude
                        local score = dist + self:_hazardAt(node.pos) * profile.CellSize * 0.75 - node.support * profile.CellSize
                        if score < bestScore then
                            best = node
                            bestScore = score
                        end
                    end
                end
            end
        end
        if best then
            return best
        end
    end
    return nil
end

function Navigator:_sweptCollision(profile, fromPos, toPos, ignoreModel)
    local delta = toPos - fromPos
    if delta.Magnitude < 0.05 then
        return nil
    end
    local origin = CFrame.new(fromPos.X, fromPos.Y + profile.Height * 0.5, fromPos.Z)
    local size = Vector3.new(profile.Radius * 2, math.max(0.5, profile.Height - CLEARANCE_PAD), profile.Radius * 2)
    local result = Workspace:Blockcast(origin, size, delta, self:_makeRayParams(ignoreModel and {ignoreModel} or {}))
    if result and result.Instance and isBlockingPart(result.Instance, ignoreModel) then
        return result
    end
    return nil
end

function Navigator:_groundDirect(profile, aNode, bNode, ignoreModel)
    local dy = math.abs(bNode.floorY - aNode.floorY)
    local dist = flat(bNode.pos - aNode.pos).Magnitude

    -- Allow slopes: check rise per horizontal distance, not total height
    -- StepHeight per cellSize is the max slope the humanoid can walk
    local maxRiseForDist = profile.StepHeight + dist * 0.6 -- ~31 degree slope tolerance
    if dy > maxRiseForDist then
        return false, nil
    end

    -- Swept collision check
    local hit = self:_sweptCollision(profile, aNode.pos, bNode.pos, ignoreModel)
    if hit then
        return false, nil
    end

    return true, {action = "walk", confidence = math.min(aNode.support or 1, bNode.support or 1)}
end

function Navigator:_jumpFeasible(profile, fromNode, toNode, ignoreModel)
    local delta = toNode.pos - fromNode.pos
    local dy = delta.Y
    local planar = flat(delta)
    local dist = planar.Magnitude
    if dist < profile.CellSize * 0.85 then
        return false, nil
    end
    if dy > profile.MaxRise + profile.StepHeight then
        return false, nil
    end
    if toNode.support <= 0.25 then
        return false, nil
    end

    local g = profile.Gravity
    local v0 = profile.JumpPower
    local disc = v0 * v0 - 2 * g * dy
    if disc < 0 then
        return false, nil
    end

    local sqrtDisc = math.sqrt(disc)
    local t1 = (v0 - sqrtDisc) / g
    local t2 = (v0 + sqrtDisc) / g
    local airTime = math.max(t1, t2)
    if airTime <= 0 then
        return false, nil
    end

    local requiredSpeed = dist / airTime
    if requiredSpeed > profile.WalkSpeed * math.max(profile.JumpBoost, 1) then
        return false, nil
    end

    local dir = safeUnit(planar)
    local landingStand = self:_standInfo(profile, toNode.pos, ignoreModel, profile.Height + profile.MaxRise + profile.StepHeight + 14)
    if not landingStand then
        return false, nil
    end
    if landingStand.support <= 0.3 then
        return false, nil
    end

    local samples = math.max(5, math.ceil(dist / math.max(1, profile.CellSize * 0.4)))
    local prevPoint = fromNode.pos
    for i = 1, samples do
        local alpha = i / samples
        local t = airTime * alpha
        local point = fromNode.pos
            + dir * (requiredSpeed * t)
            + Vector3.new(0, v0 * t - 0.5 * g * t * t, 0)
        local hit = self:_sweptCollision(profile, prevPoint, point, ignoreModel)
        if hit then
            return false, nil
        end
        prevPoint = point
    end

    local confidence = clamp((landingStand.support + toNode.support) * 0.5, 0, 1)
    return true, {
        action = "jump",
        airTime = airTime,
        requiredSpeed = requiredSpeed,
        confidence = confidence,
        landing = landingStand.pos,
    }
end

function Navigator:_dropFeasible(profile, fromNode, toNode, ignoreModel)
    local delta = toNode.pos - fromNode.pos
    local planar = flat(delta)
    local dist = planar.Magnitude
    local dropHeight = fromNode.floorY - toNode.floorY
    if dropHeight <= profile.StepHeight then
        return false, nil
    end
    if dropHeight > profile.SafeDrop * math.max(0.6 + toNode.support, 0.75) then
        return false, nil
    end
    if toNode.support <= 0.35 then
        return false, nil
    end

    local gravity = profile.Gravity
    local fallTime = math.sqrt((2 * math.max(0.05, dropHeight)) / gravity)
    local requiredSpeed = dist / math.max(fallTime, 1e-3)
    local availableSpeed = math.max(profile.HorizontalSpeed, profile.WalkSpeed * 0.7)
    if requiredSpeed > availableSpeed * 1.15 + profile.CellSize then
        return false, nil
    end

    local dir = safeUnit(planar)
    local landingStand = self:_standInfo(profile, toNode.pos, ignoreModel, profile.Height + dropHeight + profile.StepHeight + 18)
    if not landingStand then
        return false, nil
    end
    if landingStand.support <= 0.4 then
        return false, nil
    end

    local samples = math.max(4, math.ceil(dist / math.max(1, profile.CellSize * 0.5)))
    local prevPoint = fromNode.pos
    for i = 1, samples do
        local alpha = i / samples
        local t = fallTime * alpha
        local point = fromNode.pos
            + dir * (requiredSpeed * t)
            + Vector3.new(0, -0.5 * gravity * t * t, 0)
        local hit = self:_sweptCollision(profile, prevPoint, point, ignoreModel)
        if hit then
            return false, nil
        end
        prevPoint = point
    end

    local confidence = clamp((landingStand.support + toNode.support) * 0.5, 0, 1)
    return true, {
        action = "drop",
        airTime = fallTime,
        requiredSpeed = requiredSpeed,
        confidence = confidence,
        landing = landingStand.pos,
    }
end

function Navigator:_segment(profile, aNode, bNode, ignoreModel)
    local dy = bNode.floorY - aNode.floorY
    local absDy = math.abs(dy)
    local dist = flat(bNode.pos - aNode.pos).Magnitude

    -- Small height difference: definitely walkable
    if dist <= profile.CellSize * 1.35 and absDy <= profile.StepHeight then
        return true, {action = "walk", confidence = math.min(aNode.support or 1, bNode.support or 1)}
    end

    -- Larger height difference: check if there's a steppable path between them
    -- Sample the midpoint to see if intermediate ground connects them
    if dist <= profile.CellSize * 1.5 and absDy > profile.StepHeight then
        local midPos = aNode.pos:Lerp(bNode.pos, 0.5)
        local midHit = self:_floorHit(profile, midPos, ignoreModel, profile.Height + absDy + profile.StepHeight + 8)
        if midHit then
            local midY = midHit.Position.Y
            local stepA = math.abs(midY - aNode.floorY)
            local stepB = math.abs(midY - bNode.floorY)
            -- If each half-step is within StepHeight, it's walkable stairs/terrain
            if stepA <= profile.StepHeight * 1.5 and stepB <= profile.StepHeight * 1.5 then
                return true, {action = "walk", confidence = math.min(aNode.support or 1, bNode.support or 1)}
            end
        end
    end

    local walkOK, walkInfo = self:_groundDirect(profile, aNode, bNode, ignoreModel)
    if walkOK then
        return true, walkInfo
    end

    if dy < -profile.StepHeight then
        return self:_dropFeasible(profile, aNode, bNode, ignoreModel)
    end
    return self:_jumpFeasible(profile, aNode, bNode, ignoreModel)
end

function Navigator:_neighborOffsets()
    return {
        {1, 0, 1}, {-1, 0, 1}, {0, 1, 1}, {0, -1, 1},
        {1, 1, SQRT2}, {1, -1, SQRT2}, {-1, 1, SQRT2}, {-1, -1, SQRT2},
    }
end

function Navigator:_buildNeighbors(profile, node, goalNode, ignoreModel)
    local out = {}

    local function edgeCost(other, info, costMul)
        local dy = other.floorY - node.floorY
        local dist = flat(other.pos - node.pos).Magnitude * (costMul or 1)
        local hazard = self:_hazardAt(other.pos)
        local supportPenalty = (1 - math.min(other.support or 1, info.confidence or 1)) * profile.CellSize * 3
        local actionMul = 1
        if info.action == "jump" then
            actionMul = 1.1 + math.max(0, dy) / math.max(profile.MaxRise, 1)
        elseif info.action == "drop" then
            actionMul = 1.25 + math.max(0, -dy) / math.max(profile.SafeDrop, 1)
        end
        return dist * actionMul + math.abs(dy) * 0.2 + supportPenalty + hazard * profile.CellSize * 1.75
    end

    for _, item in ipairs(self:_neighborOffsets()) do
        local dx, dz, costMul = item[1], item[2], item[3]
        local other = self:_getNode(profile, node.cx + dx, node.cz + dz, ignoreModel)
        if other.walkable then
            local ok, info = self:_segment(profile, node, other, ignoreModel)
            if ok then
                table.insert(out, {node = other, cost = edgeCost(other, info, costMul), info = info})
            end
        end
    end

    local jumpDirs = {
        Vector2.new(1, 0), Vector2.new(-1, 0), Vector2.new(0, 1), Vector2.new(0, -1),
    }
    for _, dir in ipairs(jumpDirs) do
        local other = self:_getNode(profile, node.cx + dir.X * 2, node.cz + dir.Y * 2, ignoreModel)
        if other.walkable then
            local ok, info = self:_segment(profile, node, other, ignoreModel)
            if ok and info.action ~= "walk" then
                table.insert(out, {node = other, cost = edgeCost(other, info, 1), info = info})
            end
        end
    end

    if goalNode and goalNode.key ~= node.key then
        local ok, info = self:_segment(profile, node, goalNode, ignoreModel)
        if ok then
            table.insert(out, {node = goalNode, cost = edgeCost(goalNode, info, 1), info = info})
        end
    end

    return out
end

function Navigator:_reconstruct(cameFrom, refs, endKey)
    local ordered = {}
    local cursor = endKey
    while cursor do
        local n = refs[cursor]
        if not n then break end
        local edge = cameFrom[cursor]
        table.insert(ordered, 1, {
            Position = n.pos,
            Action = edge and edge.info and edge.info.action or "walk",
            Confidence = edge and edge.info and edge.info.confidence or (n.support or 1),
            FloorY = n.floorY,
        })
        cursor = edge and edge.from or nil
    end
    return ordered
end

function Navigator:_smooth(profile, waypoints, ignoreModel)
    if #waypoints <= 2 then
        return waypoints
    end
    local out = {waypoints[1]}
    local i = 1
    while i < #waypoints do
        local bestJ = i + 1
        local bestInfo = {action = waypoints[i + 1].Action, confidence = waypoints[i + 1].Confidence or 1}
        local a = self:_nearestWalkable(profile, waypoints[i].Position, ignoreModel, 1)
        if not a then break end
        for j = #waypoints, i + 1, -1 do
            local b = self:_nearestWalkable(profile, waypoints[j].Position, ignoreModel, 1)
            if b then
                local ok, info = self:_segment(profile, a, b, ignoreModel)
                if ok then
                    bestJ = j
                    bestInfo = info
                    break
                end
            end
        end
        table.insert(out, {
            Position = waypoints[bestJ].Position,
            Action = bestInfo.action,
            Confidence = bestInfo.confidence,
            FloorY = waypoints[bestJ].FloorY,
        })
        i = bestJ
    end
    return out
end

function Navigator:Plan(startPos, goalPos, humanoid, ignoreModel)
    local profile = self:_profile(humanoid)
    if not profile then
        return {Status = "NoCharacter", Waypoints = {}, Expanded = 0}
    end
    self:_pruneDirtyRegions()
    self:_cacheTrimIfNeeded()
    self:_pruneHazards()

    local startNode = self:_nearestWalkable(profile, startPos, ignoreModel, 2)
    local goalNode = self:_nearestWalkable(profile, goalPos, ignoreModel, 3)
    if not startNode or not goalNode then
        return {Status = "NoSurface", Waypoints = {}, Expanded = 0}
    end

    local open = MinHeap.new()
    local closed = {}
    local gScore = {}
    local refs = {}
    local cameFrom = {}
    local expanded = 0

    refs[startNode.key] = startNode
    gScore[startNode.key] = 0
    open:push(startNode.key, flat(goalNode.pos - startNode.pos).Magnitude)

    local BATCH_TIME_BUDGET = 0.003 -- 3ms max per batch
    local batchT0 = nowS()

    while not open:isEmpty() and expanded < SEARCH_NODE_LIMIT do
        local currentKey = open:pop()
        if not currentKey or closed[currentKey] then
            continue
        end
        closed[currentKey] = true
        expanded += 1

        -- Yield when time budget is exceeded, not after fixed node count
        local elapsed = nowS() - batchT0
        if elapsed >= BATCH_TIME_BUDGET then
            local batchMs = elapsed * 1000
            if self._planBatchWorst == nil or batchMs > self._planBatchWorst then
                self._planBatchWorst = batchMs
            end
            RunService.Heartbeat:Wait()
            batchT0 = nowS()
        end

        local current = refs[currentKey]
        if not current then
            continue
        end

        if currentKey == goalNode.key or flat(current.pos - goalNode.pos).Magnitude <= profile.CellSize then
            refs[goalNode.key] = goalNode
            if currentKey ~= goalNode.key and not cameFrom[goalNode.key] then
                cameFrom[goalNode.key] = {from = currentKey, info = {action = "walk", confidence = math.min(current.support or 1, goalNode.support or 1)}}
            end
            local raw = self:_reconstruct(cameFrom, refs, goalNode.key)
            return {
                Status = "Success",
                Waypoints = raw,
                Expanded = expanded,
            }
        end

        local currentG = gScore[currentKey] or HUGE
        for _, edge in ipairs(self:_buildNeighbors(profile, current, goalNode, ignoreModel)) do
            local nk = edge.node.key
            local tentative = currentG + edge.cost
            if tentative < (gScore[nk] or HUGE) then
                gScore[nk] = tentative
                refs[nk] = edge.node
                cameFrom[nk] = {from = currentKey, info = edge.info}
                local h = flat(goalNode.pos - edge.node.pos).Magnitude
                    + math.abs(goalNode.floorY - edge.node.floorY) * 0.2
                    + self:_hazardAt(edge.node.pos) * profile.CellSize
                    + (1 - (edge.node.support or 1)) * profile.CellSize
                open:push(nk, tentative + h)
            end
        end
    end

    return {Status = "Failed", Waypoints = {}, Expanded = expanded}
end

function Navigator:_ensureFacing(root)
    local attachment = root:FindFirstChild("NavigatorFacingAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "NavigatorFacingAttachment"
        attachment.Parent = root
    end
    local align = root:FindFirstChild("NavigatorFacingAlign")
    if not align then
        align = Instance.new("AlignOrientation")
        align.Name = "NavigatorFacingAlign"
        align.Mode = Enum.OrientationAlignmentMode.OneAttachment
        align.Attachment0 = attachment
        align.RigidityEnabled = false
        align.MaxTorque = math.huge
        align.Responsiveness = TURN_RESPONSIVENESS
        align.Parent = root
    end
    return align
end

function Navigator:_obstacleAhead(profile, moveDir, ignoreModel)
    if moveDir.Magnitude < 0.01 then
        return nil
    end
    return Workspace:Raycast(
        profile.Root.Position + Vector3.new(0, math.max(1.5, profile.Height * 0.35), 0),
        safeUnit(moveDir) * profile.ProbeDistance,
        self:_makeRayParams(ignoreModel and {ignoreModel} or {})
    )
end

function Navigator:_voidAhead(profile, moveDir, ignoreModel)
    local dir = safeUnit(moveDir)
    if dir.Magnitude < 0.01 then
        return false
    end
    local params = self:_getRayParams(ignoreModel and {ignoreModel} or {})
    local rootY = profile.Root.Position.Y
    local rayDown = Vector3.new(0, -(profile.Height + profile.MaxRise + 8), 0)

    -- Check 3 distances: close, medium, far
    -- If ANY probe finds ground at a safe height, it's not a real void (just a crack/gap)
    local probes = {
        profile.Radius + profile.CellSize * 0.3,   -- close (right at feet)
        profile.Radius + profile.CellSize * 0.6,   -- medium
        profile.Radius + profile.CellSize * 1.0,   -- far (past small gaps)
    }

    local foundGround = false
    local allVoid = true
    for _, dist in ipairs(probes) do
        local probePos = profile.Root.Position + dir * dist
        local hit = Workspace:Raycast(
            Vector3.new(probePos.X, rootY + 2, probePos.Z),
            rayDown, params
        )
        if hit and rootY - hit.Position.Y <= profile.SafeDrop then
            foundGround = true
            allVoid = false
            break
        end
        if hit then
            allVoid = false
        end
    end

    -- Only report void if ALL probes found nothing or unsafe drops
    if foundGround then
        return false
    end
    return allVoid or not foundGround
end

function Navigator:_lateral(profile, moveDir, ignoreModel)
    local dir = safeUnit(moveDir)
    if dir.Magnitude < 0.01 then
        return Vector3.zero
    end
    local left = Vector3.new(-dir.Z, 0, dir.X)
    local right = Vector3.new(dir.Z, 0, -dir.X)
    local params = self:_makeRayParams(ignoreModel and {ignoreModel} or {})
    local origin = profile.Root.Position + Vector3.new(0, math.max(1.5, profile.Height * 0.35), 0)
    local leftHit = Workspace:Raycast(origin, left * profile.ProbeDistance, params)
    local rightHit = Workspace:Raycast(origin, right * profile.ProbeDistance, params)
    if leftHit and not rightHit then return right end
    if rightHit and not leftHit then return left end
    if not leftHit then return left end
    if not rightHit then return right end
    return -dir
end

function Navigator:_supportAhead(profile, moveDir, ignoreModel, distance)
    local dir = safeUnit(moveDir)
    if dir.Magnitude < 0.01 then
        return nil
    end
    local probeDistance = distance or (profile.Radius + profile.CellSize * 0.5)
    local probe = profile.Root.Position + dir * probeDistance
    return self:_standInfo(profile, probe, ignoreModel, profile.Height + profile.MaxRise + profile.StepHeight + 16)
end

function Navigator:_bestJumpLanding(profile, currentNode, moveDir, preferredNode, goalPos, ignoreModel)
    local dir = safeUnit(moveDir)
    if dir.Magnitude < 0.01 then
        return nil, nil
    end

    local bestNode = nil
    local bestInfo = nil
    local bestScore = -HUGE
    local jumpCells = clamp(math.floor(profile.JumpReach / profile.CellSize), 2, 6)
    local lateral = perpendicularLeft(dir)

    local function consider(node)
        if not node or not node.walkable then
            return
        end
        local ok, info = self:_jumpFeasible(profile, currentNode, node, ignoreModel)
        if not ok then
            return
        end
        local progress = goalPos and ((flat(goalPos - currentNode.pos).Magnitude - flat(goalPos - node.pos).Magnitude)) or 0
        local directional = flat(node.pos - currentNode.pos):Dot(dir)
        local lateralPenalty = math.abs(flat(node.pos - currentNode.pos):Dot(lateral))
        local hazard = self:_hazardAt(node.pos)
        local score = progress + directional + info.confidence * profile.CellSize * 4 - lateralPenalty * 0.25 - hazard * profile.CellSize * 1.5
        if score > bestScore then
            bestScore = score
            bestNode = node
            bestInfo = info
        end
    end

    if preferredNode and flat(preferredNode.pos - currentNode.pos):Dot(dir) > 0 then
        consider(preferredNode)
    end

    for step = 2, jumpCells do
        local base = currentNode.pos + dir * (step * profile.CellSize)
        local probePositions = {
            base,
            base + lateral * profile.CellSize * 0.5,
            base - lateral * profile.CellSize * 0.5,
        }
        for _, probe in ipairs(probePositions) do
            local node = self:_nearestWalkable(profile, probe, ignoreModel, 1)
            consider(node)
        end
    end

    return bestNode, bestInfo
end

function Navigator:_bestDropLanding(profile, currentNode, preferredNode, goalPos, ignoreModel)
    local bestNode = nil
    local bestInfo = nil
    local bestScore = -HUGE
    local maxRings = clamp(math.ceil(profile.SafeDrop / math.max(profile.CellSize, 1)) + 2, 2, 7)

    local function consider(node)
        if not node or not node.walkable then
            return
        end
        local ok, info = self:_dropFeasible(profile, currentNode, node, ignoreModel)
        if not ok then
            return
        end
        local progress = goalPos and (flat(goalPos - currentNode.pos).Magnitude - flat(goalPos - node.pos).Magnitude) or 0
        local hazard = self:_hazardAt(node.pos)
        local score = progress + info.confidence * profile.CellSize * 4 - hazard * profile.CellSize * 2
        if score > bestScore then
            bestScore = score
            bestNode = node
            bestInfo = info
        end
    end

    consider(preferredNode)
    for r = 1, maxRings do
        for dx = -r, r do
            for dz = -r, r do
                if math.abs(dx) == r or math.abs(dz) == r then
                    consider(self:_getNode(profile, currentNode.cx + dx, currentNode.cz + dz, ignoreModel))
                end
            end
        end
    end
    return bestNode, bestInfo
end

function Navigator:_trajectoryScore(profile, startPos, targetPos, goalPos, supportMin, accumulatedRisk, accumulatedTurn)
    local targetDistance = flat(targetPos - (goalPos or targetPos)).Magnitude
    local startDistance = goalPos and flat(startPos - goalPos).Magnitude or flat(targetPos - startPos).Magnitude
    local progress = (startDistance - targetDistance)
    local score = progress * 2
    score += supportMin * profile.CellSize * 4
    score -= accumulatedRisk * profile.CellSize * 1.5
    score -= accumulatedTurn * profile.CellSize * 0.25
    return score
end

function Navigator:_groundTrajectory(profile, startPos, moveDir, goalPos, ignoreModel)
    local dir = safeUnit(moveDir)
    if dir.Magnitude < 0.01 then
        return nil
    end

    local distance = math.max(profile.BrakingDistance, profile.WalkSpeed * profile.Horizon)
    local samples = clamp(math.ceil(distance / math.max(1, profile.CellSize * 0.45)), 3, TRAJECTORY_SAMPLE_CAP)
    local lastPos = startPos
    local bestPos = startPos
    local supportMin = 1
    local risk = 0
    local turnCost = 0

    for i = 1, samples do
        local alpha = i / samples
        local probe = startPos + dir * distance * alpha
        local stand = self:_standInfo(profile, probe, ignoreModel, profile.Height + profile.MaxRise + profile.StepHeight + 18)
        if not stand then
            return nil
        end
        if stand.floorY < lastPos.Y - profile.SafeDrop * 0.9 then
            return nil
        end
        local hit = self:_sweptCollision(profile, lastPos, stand.pos, ignoreModel)
        if hit then
            return nil
        end
        supportMin = math.min(supportMin, stand.support)
        risk += self:_hazardAt(stand.pos)
        turnCost += math.abs(signedAngleFlat(flat(stand.pos - lastPos), dir))
        lastPos = stand.pos
        bestPos = stand.pos
    end

    return {
        kind = "move",
        dir = dir,
        endPos = bestPos,
        score = self:_trajectoryScore(profile, startPos, bestPos, goalPos, supportMin, risk, turnCost),
        confidence = clamp(supportMin - risk * 0.08, 0, 1),
    }
end

function Navigator:_jumpTrajectory(profile, startPos, currentNode, moveDir, preferredNode, goalPos, ignoreModel)
    local landingNode, jumpInfo = self:_bestJumpLanding(profile, currentNode, moveDir, preferredNode, goalPos, ignoreModel)
    if not landingNode or not jumpInfo then
        return nil
    end
    local risk = self:_hazardAt(landingNode.pos)
    local progress = goalPos and (flat(goalPos - startPos).Magnitude - flat(goalPos - landingNode.pos).Magnitude) or 0
    local score = progress * 2 + jumpInfo.confidence * profile.CellSize * 5 - risk * profile.CellSize * 2
    return {
        kind = "jump",
        dir = safeUnit(moveDir),
        endPos = landingNode.pos,
        score = score,
        confidence = clamp(jumpInfo.confidence - risk * 0.08, 0, 1),
        airTime = jumpInfo.airTime,
        landingNode = landingNode,
    }
end

function Navigator:_dropTrajectory(profile, startPos, currentNode, preferredNode, goalPos, ignoreModel)
    local landingNode, dropInfo = self:_bestDropLanding(profile, currentNode, preferredNode, goalPos, ignoreModel)
    if not landingNode or not dropInfo then
        return nil
    end
    local risk = self:_hazardAt(landingNode.pos)
    local progress = goalPos and (flat(goalPos - startPos).Magnitude - flat(goalPos - landingNode.pos).Magnitude) or 0
    local score = progress * 1.6 + dropInfo.confidence * profile.CellSize * 4 - risk * profile.CellSize * 2.5
    return {
        kind = "drop",
        dir = safeUnit(flat(landingNode.pos - startPos)),
        endPos = landingNode.pos,
        score = score,
        confidence = clamp(dropInfo.confidence - risk * 0.1, 0, 1),
        airTime = dropInfo.airTime,
        landingNode = landingNode,
    }
end

function Navigator:CreateMover(humanoid)
    local root, character = getRootAndCharacter(humanoid)
    assert(root and character, "CreateMover requires a Humanoid inside a character model with HumanoidRootPart")

    local mover = {}
    mover.Navigator = self
    mover.Humanoid = humanoid
    mover.Root = root
    mover.Character = character
    mover.Goal = nil
    mover.LookAt = nil
    mover.Path = nil
    mover.PathIndex = 1
    mover.LastPlanAt = 0
    mover.LastDynamicAt = 0
    mover.LastPosition = root.Position
    mover.StuckFor = 0
    mover.Planning = false
    mover.PlanTicket = 0
    mover.Active = true
    mover.Align = nil
    mover.DebugState = {
        Current = humanoid:GetState(),
        Previous = humanoid:GetState(),
        StateChangedAt = nowS(),
        RunningSpeed = 0,
        Grounded = humanoid.FloorMaterial ~= Enum.Material.Air,
        Jumping = false,
        FreeFalling = false,
        Climbing = false,
        Swimming = false,
        Seated = false,
        LastGroundedAt = nowS(),
        LastSafePos = root.Position,
        LastSafeFloorY = root.Position.Y,
        PlannedAirUntil = 0,
        NearMissAt = 0,
    }

    function mover:SetGoal(goal)
        self.Goal = goal
        self.Path = nil
        self.PathIndex = 1
        self.LastPlanAt = 0
        self.PlanTicket += 1
    end

    function mover:SetLookAt(target)
        self.LookAt = target
    end

    function mover:Stop()
        self.Active = false
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        for _, con in ipairs(self.StateConnections or {}) do
            con:Disconnect()
        end
        self.StateConnections = nil
        if self.Align then
            self.Align:Destroy()
            self.Align = nil
        end
        pcall(function()
            self.Humanoid.AutoRotate = true
            self.Humanoid:Move(Vector3.zero, false)
        end)
        self.Navigator._activeMovers[self] = nil
    end

    mover._planQueued = false

    function mover:_requestPlan()
        if not self.Goal or not self.Active then
            return
        end
        if self.Planning then
            return
        end
        local t = nowS()
        if t - self.LastPlanAt < 1 then
            return
        end
        if self._planQueued then
            return
        end
        self._planQueued = true
    end

    -- Plan runner — checks for queued plans on PreSimulation (runs before physics, after render)
    local planCon
    planCon = (RunService.PreSimulation or RunService.Heartbeat):Connect(function()
        if not mover.Active then
            planCon:Disconnect()
            return
        end
        if not mover._planQueued or not mover.Goal or mover.Planning then
            return
        end
        mover._planQueued = false
        mover.Planning = true
        mover.LastPlanAt = nowS()
        mover.PlanTicket += 1
        local myTicket = mover.PlanTicket
        local startPos = mover.Root.Position
        local goalPos = mover.Goal

        -- Run plan in a coroutine so it can yield with Heartbeat:Wait() inside Plan()
        task.spawn(function()
            local result = mover.Navigator:Plan(startPos, goalPos, mover.Humanoid, mover.Character)
            if mover.Active and myTicket == mover.PlanTicket then
                if result.Status == "Success" and #result.Waypoints > 0 then
                    mover.Path = result.Waypoints
                    mover.PathIndex = math.min(2, #mover.Path)
                else
                    mover.Path = nil
                    mover.PathIndex = 1
                end
            end
            mover.Planning = false
        end)
    end)

    function mover:_currentWaypoint()
        return self.Path and self.Path[self.PathIndex] or nil
    end

    function mover:_nextWaypoint()
        return self.Path and self.Path[math.min((self.PathIndex or 1) + 1, #self.Path)] or nil
    end

    function mover:_advance(profile)
        local wp = self:_currentWaypoint()
        if not wp then return end
        local flatDistance = flat(wp.Position - self.Root.Position).Magnitude
        local verticalDistance = math.abs((wp.FloorY or wp.Position.Y) - self.Root.Position.Y)
        local reached = flatDistance <= math.max(profile.ReachedRadius, profile.CellSize * 0.7)
        if wp.Action == "jump" or wp.Action == "drop" then
            reached = reached and verticalDistance <= math.max(profile.StepHeight, self.Root.Size.Y * 0.9)
        end
        if reached then
            self.PathIndex += 1
            if self.PathIndex > #self.Path then
                self.PathIndex = #self.Path
            end
        end
    end

    function mover:_corridorDirection(profile)
        local wp = self:_currentWaypoint()
        local nextWp = self:_nextWaypoint()
        if wp then
            local target = wp.Position
            if nextWp then
                local blend = wp.Position:Lerp(nextWp.Position, 0.35)
                target = blend
            end
            return safeUnit(flat(target - self.Root.Position)), wp
        end
        return self.Goal and safeUnit(flat(self.Goal - self.Root.Position)) or Vector3.zero, nil
    end

    function mover:_updateFacing(moveDir)
        if not self.Align then
            self.Align = self.Navigator:_ensureFacing(self.Root)
            self.Humanoid.AutoRotate = false
        end
        local targetPos = nil
        if typeof(self.LookAt) == "Vector3" then
            targetPos = self.LookAt
        elseif moveDir.Magnitude > 0.01 then
            targetPos = self.Root.Position + safeUnit(moveDir) * 10
        elseif self.Goal then
            targetPos = self.Goal
        end
        if targetPos then
            local dir = safeUnit(flat(targetPos - self.Root.Position))
            if dir.Magnitude > 0.01 then
                self.Align.CFrame = CFrame.lookAt(Vector3.zero, dir)
            end
        end
    end

    function mover:_moveScale(profile, candidate)
        local corridorDir = select(1, self:_corridorDirection(profile))
        local turnAngle = math.abs(signedAngleFlat(corridorDir, candidate.dir))
        local turnPenalty = clamp(turnAngle / math.pi, 0, 1)
        local state = self.DebugState
        local grounded = state.Grounded
        local base = candidate.confidence
        if not grounded then
            base = math.max(base, 0.55)
        end
        local scale = clamp(base * (1 - turnPenalty * 0.35), 0.2, 1)
        if candidate.kind == "drop" then
            scale = clamp(scale * 0.85, 0.2, 0.9)
        end
        return scale
    end

    function mover:_collectCandidates(profile)
        local state = self.DebugState
        local corridorDir, wp = self:_corridorDirection(profile)
        local goalDir = self.Goal and safeUnit(flat(self.Goal - self.Root.Position)) or Vector3.zero
        local baseDir = corridorDir.Magnitude > 0.01 and corridorDir or goalDir
        if baseDir.Magnitude < 0.01 then
            return {}
        end

        local left = perpendicularLeft(baseDir)
        local right = -left
        local softLeft = safeUnit(baseDir + left * 0.35)
        local softRight = safeUnit(baseDir + right * 0.35)

        local dirs = {baseDir, softLeft, softRight}
        local unique = {}
        local out = {}
        local currentNode = self.Navigator:_nearestWalkable(profile, self.Root.Position, self.Character, 1)
        local preferredNode = wp and self.Navigator:_nearestWalkable(profile, wp.Position, self.Character, 1) or nil
        local needsJump = wp and (wp.Action == "jump" or wp.Action == "drop")
        local groundFailed = false

        for _, dir in ipairs(dirs) do
            local u = safeUnit(dir)
            if u.Magnitude > 0.01 then
                local k = tostring(math.round(u.X * 100)) .. ":" .. tostring(math.round(u.Z * 100))
                if not unique[k] then
                    unique[k] = true
                    local candidate = self.Navigator:_groundTrajectory(profile, self.Root.Position, u, self.Goal, self.Character)
                    if candidate then
                        table.insert(out, candidate)
                    else
                        groundFailed = true
                    end
                end
            end
        end

        -- Only evaluate jump/drop when the path actually requires it or ground movement failed
        if state.Grounded and currentNode and (needsJump or groundFailed) then
            local jumpCandidate = self.Navigator:_jumpTrajectory(profile, self.Root.Position, currentNode, baseDir, preferredNode, self.Goal, self.Character)
            if jumpCandidate then
                table.insert(out, jumpCandidate)
            end
            local dropCandidate = self.Navigator:_dropTrajectory(profile, self.Root.Position, currentNode, preferredNode, self.Goal, self.Character)
            if dropCandidate then
                table.insert(out, dropCandidate)
            end
        end

        if #out == 0 and baseDir.Magnitude > 0.01 then
            table.insert(out, {
                kind = "move",
                dir = baseDir,
                endPos = self.Root.Position + baseDir * profile.CellSize,
                score = -HUGE * 0.5,
                confidence = 0.1,
            })
        end

        table.sort(out, function(a, b)
            return a.score > b.score
        end)

        return out
    end

    function mover:_bestRecoveryDirection(profile)
        local candidates = {}
        local goalDir = self.Goal and safeUnit(flat(self.Goal - self.Root.Position)) or Vector3.zero
        if goalDir.Magnitude > 0.01 then
            table.insert(candidates, goalDir)
            local left = perpendicularLeft(goalDir)
            table.insert(candidates, safeUnit(goalDir + left * 0.6))
            table.insert(candidates, safeUnit(goalDir - left * 0.6))
        end
        table.insert(candidates, Vector3.new(1, 0, 0))
        table.insert(candidates, Vector3.new(-1, 0, 0))
        table.insert(candidates, Vector3.new(0, 0, 1))
        table.insert(candidates, Vector3.new(0, 0, -1))

        local best = Vector3.zero
        local bestScore = -HUGE
        for _, dir in ipairs(candidates) do
            local stand = self.Navigator:_supportAhead(profile, dir, self.Character, profile.JumpReach * 0.35)
            if stand then
                local score = stand.support * profile.CellSize * 4 - self.Navigator:_hazardAt(stand.pos) * profile.CellSize
                if self.Goal then
                    score += flat(self.Goal - self.Root.Position).Magnitude - flat(self.Goal - stand.pos).Magnitude
                end
                if score > bestScore then
                    bestScore = score
                    best = safeUnit(flat(stand.pos - self.Root.Position))
                end
            end
        end
        return best
    end

    function mover:_chooseCandidate(profile)
        local state = self.DebugState
        if state.FreeFalling or state.Current == Enum.HumanoidStateType.Jumping then
            local recovery = self:_bestRecoveryDirection(profile)
            if recovery.Magnitude > 0.01 then
                return {
                    kind = "air",
                    dir = recovery,
                    confidence = 0.7,
                    score = 0,
                }
            end
        end

        local candidates = self:_collectCandidates(profile)
        return candidates[1]
    end

    function mover:_needPlan(profile, dt)
        local t = nowS()
        if not self.Path then
            return true
        end
        if t - self.LastPlanAt >= profile.ReplanInterval then
            return true
        end
        if self.StuckFor >= math.max(profile.ReplanInterval * 3, 0.35) then
            self.StuckFor = 0
            return true
        end
        local wp = self:_currentWaypoint()
        if wp and self.Navigator:_hazardAt(wp.Position) > 1.5 then
            return true
        end
        return false
    end

    function mover:_applyCandidate(profile, candidate)
        if not candidate then
            self.Humanoid:Move(Vector3.zero, false)
            return
        end

        local state = self.DebugState
        local moveScale = self:_moveScale(profile, candidate)
        self:_updateFacing(candidate.dir)

        if candidate.kind == "jump" and state.Grounded then
            self.Humanoid.Jump = true
            state.PlannedAirUntil = nowS() + math.max(candidate.airTime or profile.Horizon, profile.ReplanInterval * 2)
        elseif candidate.kind == "drop" then
            state.PlannedAirUntil = nowS() + math.max(candidate.airTime or profile.Horizon, profile.ReplanInterval * 2)
        end

        self.Humanoid:Move(candidate.dir * moveScale, false)
    end

    function mover:_observeSafety(profile)
        local state = self.DebugState
        if state.Grounded then
            local stand = self.Navigator:_standInfo(profile, self.Root.Position, self.Character, profile.Height + profile.StepHeight + 12)
            if stand and stand.support > 0.3 then
                state.LastSafePos = stand.pos
                state.LastSafeFloorY = stand.floorY
            end
            return
        end

        if state.FreeFalling and nowS() > state.PlannedAirUntil then
            self.Navigator:RecordHazard(state.LastSafePos, profile.DynamicRadius * 0.45, 1.5, HAZARD_TTL)
        end
    end

    mover._stepReason = "init"
    mover._perf = {
        stepMs = 0,
        candidateMs = 0,
        planMs = 0,
        planBatchMs = 0,
        stepCount = 0,
        slowFrames = 0,
        candidateCount = 0,
    }

    function mover:_step(dt)
        local stepT0 = nowS()

        if not self.Active then self._stepReason = "inactive" return end
        if not self.Root.Parent or self.Humanoid.Health <= 0 then
            self._stepReason = "dead/noroot"
            self:Stop()
            return
        end
        if not self.Goal then
            self._stepReason = "no_goal"
            self.Humanoid:Move(Vector3.zero, false)
            return
        end

        local profile = self.Navigator:_profile(self.Humanoid)
        if not profile then
            self._stepReason = "no_profile"
            return
        end

        local state = self.DebugState
        state.Grounded = self.Humanoid.FloorMaterial ~= Enum.Material.Air or GROUNDED_STATES[state.Current] == true
        state.FreeFalling = AIR_STATES[state.Current] == true and self.Humanoid.FloorMaterial == Enum.Material.Air
        state.Climbing = state.Current == Enum.HumanoidStateType.Climbing
        state.Swimming = state.Current == Enum.HumanoidStateType.Swimming
        state.Seated = state.Current == Enum.HumanoidStateType.Seated

        if flat(self.Root.Position - self.Goal).Magnitude <= profile.ReachedRadius then
            self._stepReason = "reached_goal"
            self.Goal = nil
            self.Path = nil
            self.PathIndex = 1
            self.Humanoid:Move(Vector3.zero, false)
            return
        end

        -- Cache stays valid unless parts physically change (DescendantAdded/Removing)
        -- No periodic radius invalidation — static maps don't need it

        local traveled = (self.Root.Position - self.LastPosition).Magnitude
        if traveled < STUCK_EPS and state.Grounded then
            self.StuckFor += dt
        else
            self.StuckFor = 0
        end
        self.LastPosition = self.Root.Position

        self:_observeSafety(profile)

        if self:_needPlan(profile, dt) then
            self:_requestPlan()
        end

        self:_advance(profile)
        local wp = self:_currentWaypoint()
        local moveDir = wp and safeUnit(flat(wp.Position - self.Root.Position)) or safeUnit(flat(self.Goal - self.Root.Position))
        local grounded = state.Grounded

        local shouldJump = false
        local params = self.Navigator:_getRayParams(self.Character and {self.Character} or {})

        -- In air: steer toward waypoint/goal
        if not grounded then
            self._stepReason = "air:steering"
            self:_updateFacing(moveDir)
            self.Humanoid:Move(moveDir, false)
            local stepMs = (nowS() - stepT0) * 1000
            self._perf.stepMs = stepMs
            self._perf.stepCount += 1
            if stepMs > 8 then self._perf.slowFrames += 1 end
            return
        end

        -- Landing check: raycast down at a position to verify ground exists
        -- Returns hit position Y or nil
        local function findLanding(dir, dist)
            local probe = self.Root.Position + safeUnit(dir) * dist
            local hit = Workspace:Raycast(
                Vector3.new(probe.X, self.Root.Position.Y + profile.MaxRise + 4, probe.Z),
                Vector3.new(0, -(profile.MaxRise + profile.SafeDrop + 12), 0),
                params
            )
            return hit and hit.Position.Y or nil
        end

        -- Can we make this jump? Check physics
        local function canMakeJump(targetPos)
            local delta = targetPos - self.Root.Position
            local flatDist = flat(delta).Magnitude
            local dy = delta.Y
            -- Jump arc: v0 = JumpPower, time to reach height dy
            -- For going UP: need v0^2 >= 2*g*dy AND horizontal reach
            -- For going DOWN: always reachable if there's landing
            if dy > profile.MaxRise then
                return false -- too high
            end
            local g = profile.Gravity
            local v0 = profile.JumpPower
            if dy > 0 then
                -- Going up: check if jump power is enough
                if v0 * v0 < 2 * g * dy then
                    return false
                end
            end
            -- Check horizontal reach during air time
            local disc = v0 * v0 - 2 * g * math.max(dy, 0)
            if disc < 0 then return false end
            local airTime = (v0 + math.sqrt(disc)) / g
            local reach = profile.WalkSpeed * airTime * 1.1
            return flatDist <= reach
        end

        -- Figure out target height relative to us
        local targetPos = wp and wp.Position or self.Goal
        local heightDiff = targetPos and (targetPos.Y - self.Root.Position.Y) or 0

        -- Grounded movement logic
        if moveDir.Magnitude > 0.01 then
            local obstacleHit = self.Navigator:_obstacleAhead(profile, moveDir, self.Character)

            if obstacleHit then
                -- Check if we can hop over it (clear above)
                local highRay = Workspace:Raycast(
                    self.Root.Position + Vector3.new(0, profile.StepHeight + 1, 0),
                    safeUnit(moveDir) * profile.ProbeDistance, params
                )
                local landingY = findLanding(moveDir, profile.ProbeDistance)

                if not highRay and landingY then
                    -- Clear above, ground ahead — hop over
                    shouldJump = true
                    self._stepReason = "jump:hop"
                elseif wp and wp.Action == "jump" and landingY and canMakeJump(wp.Position) then
                    -- A* says jump and physics check passes
                    shouldJump = true
                    self._stepReason = "jump:planned"
                elseif heightDiff > profile.StepHeight and canMakeJump(targetPos) then
                    -- Target is above us, we can reach it by jumping
                    shouldJump = true
                    self._stepReason = "jump:climb"
                else
                    -- Can't jump over, go around
                    moveDir = self.Navigator:_lateral(profile, moveDir, self.Character)
                    self:_requestPlan()
                    self._stepReason = "lateral"
                end

            elseif self.Navigator:_voidAhead(profile, moveDir, self.Character) then
                local landingY = findLanding(moveDir, profile.JumpReach * 0.5)

                if landingY then
                    local dropHeight = self.Root.Position.Y - landingY

                    if dropHeight > 0 and dropHeight <= profile.SafeDrop then
                        -- Safe drop — just walk off, don't need to jump
                        self._stepReason = "dropping"
                    elseif wp and wp.Action == "jump" and canMakeJump(wp.Position) then
                        -- A* says jump across gap
                        shouldJump = true
                        self._stepReason = "jump:gap"
                    elseif dropHeight > profile.SafeDrop and canMakeJump(Vector3.new(self.Root.Position.X + safeUnit(moveDir).X * profile.JumpReach * 0.4, landingY, self.Root.Position.Z + safeUnit(moveDir).Z * profile.JumpReach * 0.4)) then
                        -- Far landing but reachable with a jump
                        shouldJump = true
                        self._stepReason = "jump:far_drop"
                    else
                        -- No safe way across
                        self.Humanoid:Move(Vector3.zero, false)
                        self:_requestPlan()
                        self._stepReason = "void_stop"
                        local stepMs = (nowS() - stepT0) * 1000
                        self._perf.stepMs = stepMs
                        self._perf.stepCount += 1
                        if stepMs > 8 then self._perf.slowFrames += 1 end
                        return
                    end
                else
                    -- Check further out — maybe it's a small gap with ground past it
                    local farLandingY = findLanding(moveDir, profile.CellSize * 1.5)
                    if farLandingY and math.abs(self.Root.Position.Y - farLandingY) <= profile.SafeDrop then
                        -- Small gap, ground on other side at safe height
                        shouldJump = true
                        self._stepReason = "jump:small_gap"
                    else
                        self.Humanoid:Move(Vector3.zero, false)
                        self:_requestPlan()
                        self._stepReason = "void_stop"
                        local stepMs = (nowS() - stepT0) * 1000
                        self._perf.stepMs = stepMs
                        self._perf.stepCount += 1
                        if stepMs > 8 then self._perf.slowFrames += 1 end
                        return
                    end
                end
            end
        end

        -- A* says jump — verify with physics
        if not shouldJump and wp and wp.Action == "jump" then
            if canMakeJump(wp.Position) then
                shouldJump = true
                self._stepReason = "jump:waypoint"
            else
                self:_requestPlan()
                self._stepReason = "jump:impossible"
            end
        end

        -- Goal is significantly below us and we're stuck — consider dropping down
        if not shouldJump and self.Goal and self.StuckFor > 1.5 then
            local goalDy = self.Goal.Y - self.Root.Position.Y
            if goalDy < -profile.StepHeight then
                -- Goal is below, check if we can safely drop toward it
                local dropDir = safeUnit(flat(self.Goal - self.Root.Position))
                local dropLandingY = findLanding(dropDir, profile.CellSize)
                if dropLandingY and self.Root.Position.Y - dropLandingY <= profile.SafeDrop then
                    moveDir = dropDir
                    self._stepReason = "drop:to_goal"
                end
            end
        end

        if shouldJump then
            self.Humanoid.Jump = true
        end

        if not self._stepReason or self._stepReason == "init" then
            self._stepReason = "moving"
        end

        self:_updateFacing(moveDir)
        self.Humanoid:Move(moveDir, false)

        local stepMs = (nowS() - stepT0) * 1000
        self._perf.stepMs = stepMs
        self._perf.stepCount += 1
        if stepMs > 8 then
            self._perf.slowFrames += 1
        end
    end

    mover.StateConnections = {
        humanoid.StateChanged:Connect(function(oldState, newState)
            local state = mover.DebugState
            state.Previous = oldState
            state.Current = newState
            state.StateChangedAt = nowS()
            state.Grounded = GROUNDED_STATES[newState] == true or humanoid.FloorMaterial ~= Enum.Material.Air
            if state.Grounded then
                state.FreeFalling = false
                state.Jumping = false
                state.LastGroundedAt = state.StateChangedAt
            end
            if newState == Enum.HumanoidStateType.Jumping then
                state.Jumping = true
                state.Grounded = false
            elseif newState == Enum.HumanoidStateType.Freefall then
                state.FreeFalling = true
                state.Grounded = false
            elseif newState == Enum.HumanoidStateType.Landed then
                state.Grounded = true
                state.FreeFalling = false
                state.Jumping = false
            elseif newState == Enum.HumanoidStateType.Dead then
                local profile = mover.Navigator:_profile(humanoid)
                if profile then
                    mover.Navigator:RecordHazard(mover.Root.Position, profile.DynamicRadius * 0.5, 2.5, HAZARD_TTL * 2)
                end
            end
        end),
        humanoid.Running:Connect(function(speed)
            mover.DebugState.RunningSpeed = speed
        end),
        humanoid.Jumping:Connect(function(active)
            mover.DebugState.Jumping = active
            if active then
                mover.DebugState.PlannedAirUntil = math.max(mover.DebugState.PlannedAirUntil, nowS() + 0.3)
            end
        end),
        humanoid.FreeFalling:Connect(function(active)
            mover.DebugState.FreeFalling = active
            if active and nowS() > mover.DebugState.PlannedAirUntil then
                local profile = mover.Navigator:_profile(humanoid)
                if profile then
                    mover.Navigator:RecordHazard(mover.DebugState.LastSafePos, profile.DynamicRadius * 0.35, 1.25, HAZARD_TTL)
                end
            end
        end),
        humanoid.Climbing:Connect(function(_)
            mover.DebugState.Climbing = humanoid:GetState() == Enum.HumanoidStateType.Climbing
        end),
        humanoid.Swimming:Connect(function(_)
            mover.DebugState.Swimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming
        end),
        humanoid.Seated:Connect(function(active)
            mover.DebugState.Seated = active
        end),
        humanoid.Died:Connect(function()
            local profile = mover.Navigator:_profile(humanoid)
            if profile then
                mover.Navigator:RecordHazard(mover.Root.Position, profile.DynamicRadius * 0.5, 2.5, HAZARD_TTL * 2)
            end
        end),
    }

    local MOVER_STEP_NAME = "NavUltimateMover_" .. tostring(math.random(100000, 999999))
    local lastStepTime = os.clock()
    RunService:BindToRenderStep(MOVER_STEP_NAME, Enum.RenderPriority.Input.Value + 1, function()
        local now = os.clock()
        local dt = now - lastStepTime
        lastStepTime = now
        local ok, err = pcall(function()
            mover:_step(dt)
        end)
        if not ok then
            mover._stepReason = "error:" .. tostring(err)
        end
    end)
    mover.Connection = {
        Disconnect = function()
            pcall(function() RunService:UnbindFromRenderStep(MOVER_STEP_NAME) end)
        end,
    }

    self._activeMovers[mover] = true
    return mover
end

return Navigator
