--!nocheck
-- AdaptiveWorldNavigator_Auto
-- Public API: no gameplay tuning values required.
-- Movement, jump reach, cell scale, replan rate, probe distance, dynamic rescan range,
-- and steering are derived from the current Humanoid + current character extents.
--
-- Uses:
-- - live workspace descendant tracking
-- - dirty-region cache invalidation
-- - A* over lazy nav cells
-- - ballistic jump/drop tests
-- - real-time obstacle avoidance + async replanning
-- - separate facing control so the humanoid can strafe while keeping a target in view

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Navigator = {}
Navigator.__index = Navigator

local SEARCH_NODE_LIMIT = 12000
local SLOPE_LIMIT_DEG = 42
local CLEARANCE_PAD = 0.15
local RAY_MARGIN_Y = 256
local RAY_DEPTH = 768
local CACHE_SOFT_LIMIT = 24000
local DIRTY_REGION_TTL = 3.0
local DIRTY_REGION_MAX = 512
local JUMP_SAMPLES = 7
local BASE_REACHED_RADIUS = 3
local STUCK_DISTANCE_EPS = 0.75
local STUCK_TIME = 0.8
local TURN_RESPONSIVENESS = 45

local SQRT2 = math.sqrt(2)
local HUGE = math.huge
local SLOPE_NORMAL_Y = math.cos(math.rad(SLOPE_LIMIT_DEG))

local function nowS(): number
    return os.clock()
end

local function keyOf(prefix: string, cx: number, cz: number): string
    return prefix .. ":" .. tostring(cx) .. ":" .. tostring(cz)
end

local function cellIndex(v: number, cellSize: number): number
    return math.floor(v / cellSize + 0.5)
end

local function clamp(n: number, mn: number, mx: number): number
    if n < mn then return mn end
    if n > mx then return mx end
    return n
end

local function flat(v: Vector3): Vector3
    return Vector3.new(v.X, 0, v.Z)
end

local function safeUnit(v: Vector3): Vector3
    local m = v.Magnitude
    if m < 1e-5 then
        return Vector3.zero
    end
    return v / m
end

local function humanoidAncestor(inst: Instance?): Model?
    if not inst then
        return nil
    end
    local model = inst:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return model
    end
    return nil
end

local function isBlockingPart(inst: Instance?): boolean
    if not inst then
        return false
    end
    if not inst:IsA("BasePart") then
        return false
    end
    local part = inst :: BasePart
    if not part.Parent then
        return false
    end
    if humanoidAncestor(part) then
        return false
    end
    if not part.CanCollide then
        return false
    end
    if part.Transparency >= 1 then
        return false
    end
    return true
end

local function getRootAndCharacter(humanoid: Humanoid)
    local char = humanoid.Parent
    if not char or not char:IsA("Model") then
        return nil, nil
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return nil, nil
    end
    return root :: BasePart, char :: Model
end

local function getHumanoidJumpPower(humanoid: Humanoid, gravity: number)
    local jumpPower = humanoid.JumpPower
    if humanoid.UseJumpPower == false then
        local jumpHeight = humanoid.JumpHeight
        if jumpHeight > 0 then
            jumpPower = math.sqrt(2 * gravity * jumpHeight)
        end
    end
    if jumpPower <= 0 then
        jumpPower = 50
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
    self._cons = {}
    self._worldBounds = {
        hasAny = false,
        maxY = 0,
    }
    self._activeMovers = {}
    self._started = false
    return self
end

function Navigator:_touchBounds(part: BasePart)
    local half = part.Size * 0.5
    local maxY = part.Position.Y + half.Y
    if not self._worldBounds.hasAny or maxY > self._worldBounds.maxY then
        self._worldBounds.maxY = maxY
        self._worldBounds.hasAny = true
    end
end

function Navigator:_pushDirtyRegion(minX: number, maxX: number, minZ: number, maxZ: number)
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

function Navigator:_markPartDirty(part: BasePart)
    self:_touchBounds(part)
    local half = part.Size * 0.5 + Vector3.new(8, 0, 8)
    local p = part.Position
    self:_pushDirtyRegion(p.X - half.X, p.X + half.X, p.Z - half.Z, p.Z + half.Z)
end

function Navigator:InvalidateRadius(position: Vector3, radius: number)
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

function Navigator:Start()
    if self._started then
        return self
    end
    self._started = true

    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") then
            self:_touchBounds(inst)
        end
    end

    table.insert(self._cons, Workspace.DescendantAdded:Connect(function(inst)
        if inst:IsA("BasePart") then
            self:_markPartDirty(inst)
        end
    end))

    table.insert(self._cons, Workspace.DescendantRemoving:Connect(function(inst)
        if inst:IsA("BasePart") then
            self:_markPartDirty(inst)
        end
    end))

    table.insert(self._cons, RunService.Heartbeat:Connect(function()
        self:_pruneDirtyRegions()
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
    self._activeMovers = {}
end

function Navigator:_profile(humanoid: Humanoid)
    local root, character = getRootAndCharacter(humanoid)
    if not root or not character then
        return nil
    end

    local extents = character:GetExtentsSize()
    local gravity = Workspace.Gravity
    local jumpPower = getHumanoidJumpPower(humanoid, gravity)
    local velocity = root.AssemblyLinearVelocity
    local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
    local walkSpeed = math.max(humanoid.WalkSpeed, horizontalSpeed)

    local radius = math.max(root.Size.X, root.Size.Z, extents.X * 0.45, extents.Z * 0.45) * 0.5 + 0.15
    local height = math.max(extents.Y, humanoid.HipHeight * 2 + root.Size.Y + 1)
    local stepHeight = clamp(humanoid.HipHeight + root.Size.Y * 0.35 + 0.5, 2, math.max(3, height * 0.45))
    local cellSize = clamp(radius * 1.75, 3, 6)
    local maxRise = (jumpPower * jumpPower) / (2 * gravity)
    local flight = (2 * jumpPower) / gravity
    local jumpBoost = clamp(1.12 + horizontalSpeed * 0.005, 1.12, 1.35)
    local jumpReach = math.max(cellSize * 2, walkSpeed * jumpBoost * flight)
    local replanInterval = clamp((cellSize / math.max(1, walkSpeed)) * 0.75, 0.06, 0.25)
    local dynamicRadius = clamp(walkSpeed * 2.5 + radius * 4, 18, 72)
    local probeDistance = clamp(radius * 2.5 + walkSpeed * 0.12, 4, 14)
    local reachedRadius = math.max(BASE_REACHED_RADIUS, radius * 1.5)

    local prefix = table.concat({
        tostring(math.round(cellSize * 10)),
        tostring(math.round(radius * 10)),
        tostring(math.round(height * 10)),
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
        ReplanInterval = replanInterval,
        DynamicRadius = dynamicRadius,
        ProbeDistance = probeDistance,
        ReachedRadius = reachedRadius,
        Prefix = prefix,
    }
end

function Navigator:_makeRayParams(exclusions)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = exclusions or {}
    return params
end

function Navigator:_makeOverlapParams(exclusions)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = exclusions or {}
    params.MaxParts = 32
    return params
end

function Navigator:_cellWorld(profile, cx: number, cz: number)
    return Vector3.new(cx * profile.CellSize, 0, cz * profile.CellSize)
end

function Navigator:_isDirty(profile, cx: number, cz: number, computedAt: number)
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

function Navigator:_computeNode(profile, cx: number, cz: number, ignoreModel: Model?)
    local center = self:_cellWorld(profile, cx, cz)
    local highY = self._worldBounds.hasAny and math.max(RAY_MARGIN_Y, self._worldBounds.maxY + 64) or RAY_MARGIN_Y

    local exclude = {}
    if ignoreModel then
        table.insert(exclude, ignoreModel)
    end

    local hit = nil
    for _ = 1, 5 do
        hit = Workspace:Raycast(
            Vector3.new(center.X, highY, center.Z),
            Vector3.new(0, -(RAY_DEPTH + highY), 0),
            self:_makeRayParams(exclude)
        )
        if not hit then
            break
        end
        local humModel = humanoidAncestor(hit.Instance)
        if humModel then
            table.insert(exclude, humModel)
            hit = nil
        else
            break
        end
    end

    local node = {
        key = keyOf(profile.Prefix, cx, cz),
        cx = cx,
        cz = cz,
        pos = center,
        walkable = false,
        floorY = -HUGE,
        normal = Vector3.yAxis,
        computedAt = nowS(),
    }

    if not hit or not hit.Instance then
        return node
    end
    if hit.Normal.Y < SLOPE_NORMAL_Y then
        return node
    end

    local floorPos = hit.Position
    local boxCenter = Vector3.new(center.X, floorPos.Y + profile.Height * 0.5 + CLEARANCE_PAD, center.Z)
    local boxSize = Vector3.new(profile.Radius * 2, math.max(0.5, profile.Height - CLEARANCE_PAD), profile.Radius * 2)
    local overlaps = Workspace:GetPartBoundsInBox(CFrame.new(boxCenter), boxSize, self:_makeOverlapParams(ignoreModel and {ignoreModel} or {}))

    for _, part in ipairs(overlaps) do
        if part ~= hit.Instance and isBlockingPart(part) then
            return node
        end
    end

    node.walkable = true
    node.floorY = floorPos.Y
    node.pos = Vector3.new(center.X, floorPos.Y, center.Z)
    node.normal = hit.Normal
    return node
end

function Navigator:_getNode(profile, cx: number, cz: number, ignoreModel: Model?)
    local key = keyOf(profile.Prefix, cx, cz)
    local cached = self._cells[key]
    if cached and not self:_isDirty(profile, cx, cz, cached.computedAt) then
        return cached
    end
    local node = self:_computeNode(profile, cx, cz, ignoreModel)
    self._cells[key] = node
    return node
end

function Navigator:_nearestWalkable(profile, position: Vector3, ignoreModel: Model?, rings: number?)
    local maxRings = rings or 5
    local baseCX = cellIndex(position.X, profile.CellSize)
    local baseCZ = cellIndex(position.Z, profile.CellSize)
    local best = nil
    local bestDist = HUGE

    for r = 0, maxRings do
        for dx = -r, r do
            for dz = -r, r do
                if r == 0 or math.abs(dx) == r or math.abs(dz) == r then
                    local node = self:_getNode(profile, baseCX + dx, baseCZ + dz, ignoreModel)
                    if node.walkable then
                        local d = (node.pos - position).Magnitude
                        if d < bestDist then
                            best = node
                            bestDist = d
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

function Navigator:_jumpFeasible(profile, fromNode, toNode, ignoreModel: Model?)
    local delta = toNode.pos - fromNode.pos
    local dy = delta.Y
    local dist = flat(delta).Magnitude
    if dist < profile.CellSize * 1.2 then
        return false, nil
    end
    if dy > profile.MaxRise + 1 then
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
    if requiredSpeed > profile.WalkSpeed * profile.JumpBoost then
        return false, nil
    end

    local dir = safeUnit(flat(delta))
    local overlapsParams = self:_makeOverlapParams(ignoreModel and {ignoreModel} or {})
    local boxSize = Vector3.new(profile.Radius * 2, profile.Height, profile.Radius * 2)
    local halfHeight = profile.Height * 0.5

    for i = 1, JUMP_SAMPLES - 1 do
        local a = i / JUMP_SAMPLES
        local t = airTime * a
        local point = fromNode.pos
            + dir * (requiredSpeed * t)
            + Vector3.new(0, v0 * t - 0.5 * g * t * t, 0)
        local overlaps = Workspace:GetPartBoundsInBox(CFrame.new(point.X, point.Y + halfHeight, point.Z), boxSize, overlapsParams)
        for _, part in ipairs(overlaps) do
            if isBlockingPart(part) then
                return false, nil
            end
        end
    end

    if dy > profile.StepHeight then
        return true, "jump"
    end
    if dy < -profile.StepHeight then
        return true, "drop"
    end
    return true, "jump"
end

function Navigator:_groundDirect(profile, aNode, bNode, ignoreModel: Model?)
    local dist = flat(bNode.pos - aNode.pos).Magnitude
    local steps = math.max(2, math.ceil(dist / math.max(1, profile.CellSize * 0.5)))
    local last = aNode
    for i = 1, steps do
        local alpha = i / steps
        local probe = aNode.pos:Lerp(bNode.pos, alpha)
        local node = self:_nearestWalkable(profile, probe, ignoreModel, 1)
        if not node then
            return false
        end
        if math.abs(node.floorY - last.floorY) > profile.StepHeight then
            return false
        end
        last = node
    end
    return true
end

function Navigator:_segment(profile, aNode, bNode, ignoreModel: Model?)
    local dy = math.abs(bNode.floorY - aNode.floorY)
    local dist = flat(bNode.pos - aNode.pos).Magnitude
    if dist <= profile.CellSize * 1.5 and dy <= profile.StepHeight then
        return true, "walk"
    end
    if self:_groundDirect(profile, aNode, bNode, ignoreModel) then
        return true, "walk"
    end
    return self:_jumpFeasible(profile, aNode, bNode, ignoreModel)
end

function Navigator:_neighborOffsets()
    return {
        {1, 0, 1}, {-1, 0, 1}, {0, 1, 1}, {0, -1, 1},
        {1, 1, SQRT2}, {1, -1, SQRT2}, {-1, 1, SQRT2}, {-1, -1, SQRT2},
    }
end

function Navigator:_buildNeighbors(profile, node, goalNode, ignoreModel: Model?)
    local out = {}
    for _, item in ipairs(self:_neighborOffsets()) do
        local dx, dz, costMul = item[1], item[2], item[3]
        local other = self:_getNode(profile, node.cx + dx, node.cz + dz, ignoreModel)
        if other.walkable then
            local dy = other.floorY - node.floorY
            if math.abs(dy) <= profile.StepHeight then
                table.insert(out, {node = other, cost = profile.CellSize * costMul + math.abs(dy) * 0.25, action = "walk"})
            else
                local ok, action = self:_jumpFeasible(profile, node, other, ignoreModel)
                if ok then
                    table.insert(out, {node = other, cost = flat(other.pos - node.pos).Magnitude * 1.1, action = action})
                end
            end
        end
    end

    local jumpCells = clamp(math.floor(profile.JumpReach / profile.CellSize), 2, 5)
    local jumpDirs = {
        Vector2.new(1, 0), Vector2.new(-1, 0), Vector2.new(0, 1), Vector2.new(0, -1),
        Vector2.new(1, 1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(-1, -1),
    }
    for _, dir in ipairs(jumpDirs) do
        for step = 2, jumpCells do
            local nx = node.cx + dir.X * step
            local nz = node.cz + dir.Y * step
            local other = self:_getNode(profile, nx, nz, ignoreModel)
            if other.walkable then
                local ok, action = self:_jumpFeasible(profile, node, other, ignoreModel)
                if ok then
                    table.insert(out, {node = other, cost = flat(other.pos - node.pos).Magnitude * 1.05, action = action})
                end
            end
        end
    end

    if goalNode and goalNode.key ~= node.key then
        local ok, action = self:_segment(profile, node, goalNode, ignoreModel)
        if ok then
            table.insert(out, {node = goalNode, cost = flat(goalNode.pos - node.pos).Magnitude, action = action or "walk"})
        end
    end

    return out
end

function Navigator:_reconstruct(cameFrom, refs, endKey: string, goalPos: Vector3?)
    local ordered = {}
    local cursor = endKey
    while cursor do
        local n = refs[cursor]
        if not n then break end
        local edge = cameFrom[cursor]
        table.insert(ordered, 1, {
            Position = n.pos,
            Action = edge and edge.action or "walk",
        })
        cursor = edge and edge.from or nil
    end
    if goalPos and #ordered > 0 then
        local last = ordered[#ordered]
        if (last.Position - goalPos).Magnitude > 2 then
            table.insert(ordered, {Position = goalPos, Action = "walk"})
        end
    end
    return ordered
end

function Navigator:_smooth(profile, waypoints, ignoreModel: Model?)
    if #waypoints <= 2 then
        return waypoints
    end
    local out = {waypoints[1]}
    local i = 1
    while i < #waypoints do
        local bestJ = i + 1
        local bestAction = waypoints[i + 1].Action
        local a = self:_nearestWalkable(profile, waypoints[i].Position, ignoreModel, 1)
        if not a then break end
        for j = #waypoints, i + 1, -1 do
            local b = self:_nearestWalkable(profile, waypoints[j].Position, ignoreModel, 1)
            if b then
                local ok, action = self:_segment(profile, a, b, ignoreModel)
                if ok then
                    bestJ = j
                    bestAction = action or waypoints[j].Action
                    break
                end
            end
        end
        table.insert(out, {Position = waypoints[bestJ].Position, Action = bestAction})
        i = bestJ
    end
    return out
end

function Navigator:Plan(startPos: Vector3, goalPos: Vector3, humanoid: Humanoid, ignoreModel: Model?)
    local profile = self:_profile(humanoid)
    if not profile then
        return {Status = "NoCharacter", Waypoints = {}, Expanded = 0}
    end
    self:_pruneDirtyRegions()
    self:_cacheTrimIfNeeded()

    local startNode = self:_nearestWalkable(profile, startPos, ignoreModel, 4)
    local goalNode = self:_nearestWalkable(profile, goalPos, ignoreModel, 6)
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

    while not open:isEmpty() and expanded < SEARCH_NODE_LIMIT do
        local currentKey = open:pop()
        if not currentKey or closed[currentKey] then
            continue
        end
        closed[currentKey] = true
        expanded += 1

        local current = refs[currentKey]
        if not current then
            continue
        end

        if currentKey == goalNode.key or flat(current.pos - goalNode.pos).Magnitude <= profile.CellSize then
            refs[goalNode.key] = goalNode
            if currentKey ~= goalNode.key and not cameFrom[goalNode.key] then
                cameFrom[goalNode.key] = {from = currentKey, action = "walk"}
            end
            local raw = self:_reconstruct(cameFrom, refs, goalNode.key, goalPos)
            return {
                Status = "Success",
                Waypoints = self:_smooth(profile, raw, ignoreModel),
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
                cameFrom[nk] = {from = currentKey, action = edge.action}
                local h = flat(goalNode.pos - edge.node.pos).Magnitude + math.abs(goalNode.floorY - edge.node.floorY) * 0.2
                open:push(nk, tentative + h)
            end
        end
    end

    return {Status = "Failed", Waypoints = {}, Expanded = expanded}
end

function Navigator:_ensureFacing(root: BasePart)
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

function Navigator:_obstacleAhead(profile, moveDir: Vector3, ignoreModel: Model?)
    if moveDir.Magnitude < 0.01 then
        return nil
    end
    return Workspace:Raycast(
        profile.Root.Position + Vector3.new(0, math.max(1.5, profile.Height * 0.35), 0),
        safeUnit(moveDir) * profile.ProbeDistance,
        self:_makeRayParams(ignoreModel and {ignoreModel} or {})
    )
end

function Navigator:_microHop(profile, moveDir: Vector3, ignoreModel: Model?)
    local dir = safeUnit(moveDir)
    if dir.Magnitude < 0.01 then
        return false
    end
    local low = Workspace:Raycast(
        profile.Root.Position + Vector3.new(0, math.max(1.5, profile.Height * 0.3), 0),
        dir * (profile.Radius * 2 + 1.5),
        self:_makeRayParams(ignoreModel and {ignoreModel} or {})
    )
    if not low then
        return false
    end
    local high = Workspace:Raycast(
        profile.Root.Position + Vector3.new(0, profile.StepHeight + profile.Height * 0.35 + 1, 0),
        dir * (profile.Radius * 2 + 1.5),
        self:_makeRayParams(ignoreModel and {ignoreModel} or {})
    )
    return high == nil
end

function Navigator:_lateral(profile, moveDir: Vector3, ignoreModel: Model?)
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

function Navigator:CreateMover(humanoid: Humanoid)
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
    mover.Planning = false
    mover.PlanTicket = 0
    mover.Active = true
    mover.LastPosition = root.Position
    mover.StuckFor = 0
    mover.Align = nil

    function mover:SetGoal(goal: Vector3)
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

    function mover:_requestPlan(force: boolean?)
        if not self.Goal or not self.Active then
            return
        end
        if self.Planning and not force then
            return
        end
        self.Planning = true
        self.LastPlanAt = nowS()
        self.PlanTicket += 1
        local myTicket = self.PlanTicket
        local startPos = self.Root.Position
        local goalPos = self.Goal
        task.spawn(function()
            local result = self.Navigator:Plan(startPos, goalPos, self.Humanoid, self.Character)
            if not self.Active or myTicket ~= self.PlanTicket then
                return
            end
            self.Planning = false
            if result.Status == "Success" and #result.Waypoints > 0 then
                self.Path = result.Waypoints
                self.PathIndex = math.min(2, #self.Path)
            else
                self.Path = nil
                self.PathIndex = 1
            end
        end)
    end

    function mover:_currentWaypoint()
        if not self.Path then return nil end
        return self.Path[self.PathIndex]
    end

    function mover:_advance(profile)
        local wp = self:_currentWaypoint()
        if not wp then return end
        local dist = flat(wp.Position - self.Root.Position).Magnitude
        if dist <= math.max(profile.ReachedRadius * 0.8, profile.CellSize * 0.7) then
            self.PathIndex += 1
            if self.PathIndex > #self.Path then
                self.PathIndex = #self.Path
            end
        end
    end

    function mover:_updateFacing(profile, moveDir)
        if not self.Align then
            self.Align = self.Navigator:_ensureFacing(self.Root)
            self.Humanoid.AutoRotate = false
        end
        local targetPos = nil
        if typeof(self.LookAt) == "Vector3" then
            targetPos = self.LookAt
        elseif self.Goal and moveDir.Magnitude > 0.01 then
            targetPos = self.Root.Position + safeUnit(moveDir) * 10
        end
        if targetPos then
            local dir = safeUnit(flat(targetPos - self.Root.Position))
            if dir.Magnitude > 0.01 then
                self.Align.CFrame = CFrame.lookAt(Vector3.zero, dir)
            end
        end
    end

    function mover:_step(dt)
        if not self.Active then return end
        if not self.Root.Parent or self.Humanoid.Health <= 0 then
            self:Stop()
            return
        end
        if not self.Goal then
            self.Humanoid:Move(Vector3.zero, false)
            return
        end

        local profile = self.Navigator:_profile(self.Humanoid)
        if not profile then
            return
        end

        if flat(self.Root.Position - self.Goal).Magnitude <= profile.ReachedRadius then
            self.Humanoid:Move(Vector3.zero, false)
            return
        end

        local t = nowS()
        if t - self.LastDynamicAt >= profile.ReplanInterval then
            self.LastDynamicAt = t
            self.Navigator:InvalidateRadius(self.Root.Position, profile.DynamicRadius)
        end

        local traveled = (self.Root.Position - self.LastPosition).Magnitude
        if traveled < STUCK_DISTANCE_EPS then
            self.StuckFor += dt
        else
            self.StuckFor = 0
        end
        self.LastPosition = self.Root.Position

        local needPlan = false
        if not self.Path then
            needPlan = true
        elseif t - self.LastPlanAt >= profile.ReplanInterval then
            needPlan = true
        elseif self.StuckFor >= STUCK_TIME then
            self.StuckFor = 0
            needPlan = true
        end
        if needPlan then
            self:_requestPlan(true)
        end

        self:_advance(profile)
        local wp = self:_currentWaypoint()
        local moveDir = wp and safeUnit(flat(wp.Position - self.Root.Position)) or safeUnit(flat(self.Goal - self.Root.Position))

        if moveDir.Magnitude > 0.01 then
            local hit = self.Navigator:_obstacleAhead(profile, moveDir, self.Character)
            if hit then
                if self.Navigator:_microHop(profile, moveDir, self.Character) then
                    self.Humanoid.Jump = true
                else
                    moveDir = self.Navigator:_lateral(profile, moveDir, self.Character)
                    self:_requestPlan(true)
                end
            end
        end

        if wp and (wp.Action == "jump" or wp.Action == "drop") then
            local dist = flat(wp.Position - self.Root.Position).Magnitude
            if dist <= math.max(profile.CellSize * 1.15, profile.ReachedRadius) then
                self.Humanoid.Jump = true
            end
        end

        self:_updateFacing(profile, moveDir)
        self.Humanoid:Move(moveDir, false)
    end

    mover.Connection = RunService.Heartbeat:Connect(function(dt)
        local ok, err = pcall(function()
            mover:_step(dt)
        end)
        if not ok then
            warn("[AdaptiveWorldNavigator_Auto] mover error:", err)
        end
    end)

    self._activeMovers[mover] = true
    return mover
end

return Navigator
