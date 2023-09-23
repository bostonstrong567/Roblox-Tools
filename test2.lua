local Player = game:GetService("Players").LocalPlayer
local Module = {}
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

function Module.GetCharacterAndHRP()
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    return Character, HumanoidRootPart
end

do
    local originalIndex = {}
    local spoofedProperties = {}

    function Module.Spoof(obj, property, value)
        if not spoofedProperties[obj] then
            spoofedProperties[obj] = {}
        end
        spoofedProperties[obj][property] = value
        if not originalIndex[obj] then
            local mt = getmetatable(obj)
            if mt and type(mt.__index) == "function" then
                originalIndex[obj] = mt.__index
                mt.__index = function(o, p)
                    if spoofedProperties[o] and spoofedProperties[o][p] then
                        return spoofedProperties[o][p]
                    end
                    return originalIndex[o](o, p)
                end
            end
        end
    end

    function Module.UnSpoof(obj, property)
        if spoofedProperties[obj] then
            spoofedProperties[obj][property] = nil
        end
    end
end

function Module.EnableNoClip(enable)
    local connection
    if enable then
        if setfflag then
            setfflag("HumanoidParallelRemoveNoPhysics", "False")
            setfflag("HumanoidParallelRemoveNoPhysicsNoSimulate2", "False")
        end

        connection = RunService.Stepped:Connect(function()
            for _, v in pairs(Player.Character:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                elseif v:IsA("Humanoid") then
                    v:ChangeState(11)
                end
            end
        end)
    else
        if connection then
            connection:Disconnect()
        end
        if setfflag then
            setfflag("HumanoidParallelRemoveNoPhysics", "True")
            setfflag("HumanoidParallelRemoveNoPhysicsNoSimulate2", "True")
        end
    end
    return connection
end

function Module.UltimateTween(object_to_tween, destination, options)
    local Character, HumanoidRootPart = Module.GetCharacterAndHRP()
    local update_rate = options.updateRate or 1/30
    local enableNoClip = options.noClip or true
    local walk_speed = Character.Humanoid.WalkSpeed
    local reachedDestination = false  -- Flag to control the loop

    local function randomInRange(min, max)
        return min + math.random() * (max - min)
    end

    local function applyTween(target, end_cframe, tween_info)
        local tween_goal = {}
        tween_goal.CFrame = end_cframe
        local tween = TweenService:Create(target, tween_info, tween_goal)
        tween:Play()
    end

    local function getBasePart(object)
        return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
    end

    local function hasReachedDestination(basePart, destination)
        return (basePart.Position - destination.Position).Magnitude < 0.1
    end

    local function updateTween()
        local time, easing_style, easing_direction = 5, Enum.EasingStyle.Linear, Enum.EasingDirection.In
        local tween_speed = options.speed or "Default"
        local basePart = object_to_tween:IsA("Model") and getBasePart(object_to_tween) or object_to_tween

        Module.UnSpoof(basePart, 'CFrame')  -- Unspoof the previous CFrame

        if tween_speed == "AntiCheat" then
            local distance_to_destination = (destination.Position - basePart.Position).Magnitude
            time = distance_to_destination / walk_speed

            -- AntiCheat measures here
            time = randomInRange(1, 10)
            local currentPos = basePart.Position
            local alteredDestination = destination.Position + Vector3.new(randomInRange(-5, 5), randomInRange(-5, 5), randomInRange(-5, 5))

            local rotation = CFrame.Angles(0, math.rad(randomInRange(0, 360)), 0)
            local altitudeChange = CFrame.new(0, randomInRange(-2, 2), 0)

            if basePart.Position.y > destination.Position.y then
                alteredDestination = alteredDestination + Vector3.new(0, -9.81, 0)
            end

            local lookAtCFrame = CFrame.lookAt(currentPos, alteredDestination)
            Module.Spoof(basePart, 'CFrame', lookAtCFrame * rotation * altitudeChange)
        end

        local tween_info = TweenInfo.new(time, easing_style, easing_direction)

        if object_to_tween:IsA("Model") then
            local target_part = getBasePart(object_to_tween)
            if target_part then
                applyTween(target_part, CFrame.new(destination.Position), tween_info)
            end
        else
            applyTween(object_to_tween, CFrame.new(destination.Position), tween_info)
        end

        if hasReachedDestination(basePart, destination) then
            reachedDestination = true  -- Update the flag
        end
    end

    local noClipConnection = Module.EnableNoClip(enableNoClip)  -- Start NoClip

    while not reachedDestination do  -- Use the flag to control the loop
        wait(update_rate)
        updateTween()
    end

    if noClipConnection then  -- Disconnect NoClip
        noClipConnection:Disconnect()
    end
    Module.EnableNoClip(false)  -- Disabling NoClip after tweening
end

return Module
