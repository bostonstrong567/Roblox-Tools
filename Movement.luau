local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ActiveMoves = setmetatable({}, { __mode = "k" })

local function ForceMove(TargetArg, SpeedArg, NoClipArg, CallbackArg, ReturnToStartArg, OptionsArg)
	local Speed = 250
	local UseNoClip = true
	local Target = TargetArg
	local Callback = CallbackArg
	local ReturnToStart = ReturnToStartArg == true
	local Options = OptionsArg or {}

	if typeof(TargetArg) ~= "Instance" and typeof(TargetArg) ~= "Vector3" then
		Target = SpeedArg
		Speed = type(TargetArg) == "number" and TargetArg or Speed
		UseNoClip = NoClipArg ~= false
		Callback = CallbackArg
		ReturnToStart = ReturnToStartArg == true
		Options = OptionsArg or Options
	else
		if type(SpeedArg) == "number" then Speed = SpeedArg end
		if type(SpeedArg) == "table" then Options = SpeedArg end
		if NoClipArg ~= nil then UseNoClip = NoClipArg ~= false end
	end

	if type(Options) == "table" then
		if type(Options.Speed) == "number" then Speed = Options.Speed end
		if Options.NoClip ~= nil then UseNoClip = Options.NoClip == true end
		if Options.Callback ~= nil then Callback = Options.Callback end
		if Options.ReturnToStart ~= nil then ReturnToStart = Options.ReturnToStart == true end
	end

	local Player = (type(Options) == "table" and Options.Player) or Players.LocalPlayer
	local Char = (type(Options) == "table" and Options.Character) or (Player and Player.Character)
	if not Char then
		if Player and Player.CharacterAdded then
			Char = Player.CharacterAdded:Wait()
		else
			return function() end
		end
	end

	local Hrp = Char:WaitForChild("HumanoidRootPart")
	local Hum = Char:FindFirstChildOfClass("Humanoid")

	local Prev = ActiveMoves[Hrp]
	if Prev then Prev() end

	local function GetGoal()
		if typeof(Target) == "Vector3" then return Target end
		if typeof(Target) == "Instance" then
			if Target:IsA("BasePart") then return Target.Position end
			if Target:IsA("Model") then return Target:GetPivot().Position end
		end
	end

	if Speed < 0 then Speed = 0 end
	local Reach = (type(Options) == "table" and Options.ReachRadius) or 5
	local UseFlatXZ = type(Options) == "table" and Options.UseFlatXZ
	if UseFlatXZ == nil then
		local GoalHint = GetGoal()
		if GoalHint and math.abs(GoalHint.Y - Hrp.Position.Y) > 0.05 then
			UseFlatXZ = false
		else
			UseFlatXZ = true
		end
	end
	local BaseY = type(Options) == "table" and Options.BaseY
	if UseFlatXZ and type(BaseY) ~= "number" then BaseY = Hrp.Position.Y end
	local MaxYSpeed = (type(Options) == "table" and Options.MaxYSpeed) or 250

	local Att = Hrp:FindFirstChild("CFMAtt")
	if Att then Att:Destroy() end
	local LV = Hrp:FindFirstChild("CFMLV")
	if LV then LV:Destroy() end
	local AO = Hrp:FindFirstChild("CFMAO")
	if AO then AO:Destroy() end

	Att = Instance.new("Attachment")
	Att.Name = "CFMAtt"
	Att.Parent = Hrp

	LV = Instance.new("LinearVelocity")
	LV.Name = "CFMLV"
	LV.Attachment0 = Att
	LV.RelativeTo = Enum.ActuatorRelativeTo.World
	LV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	LV.MaxForce = 1e9
	LV.Enabled = false
	LV.Parent = Hrp

	AO = Instance.new("AlignOrientation")
	AO.Name = "CFMAO"
	AO.Attachment0 = Att
	AO.Mode = Enum.OrientationAlignmentMode.OneAttachment
	AO.MaxTorque = 1e9
	AO.Responsiveness = 200
	AO.Enabled = false
	AO.Parent = Hrp

	local _, Y, _ = Hrp.CFrame:ToOrientation()
	Hrp.AssemblyLinearVelocity = Vector3.zero
	Hrp.AssemblyAngularVelocity = Vector3.zero
	if Hum then
		Hum.PlatformStand = true
		Hum.AutoRotate = false
	end
	LV.Enabled = true
	AO.Enabled = true

	local NoClipOn = false
	local PrevCollide = {}
	local function SetNoClip(On)
		if not Char or On == NoClipOn then return end
		NoClipOn = On
		if On then
			PrevCollide = {}
			for _, D in ipairs(Char:GetDescendants()) do
				if D:IsA("BasePart") then
					PrevCollide[D] = D.CanCollide
					D.CanCollide = false
				end
			end
		else
			for P, V in pairs(PrevCollide) do
				if P and P.Parent then
					P.CanCollide = V
				end
			end
			PrevCollide = {}
		end
	end

	if UseNoClip then
		SetNoClip(true)
	end

	local StartPos = Hrp.Position
	local Returning = false
	local Done = false
	local Conn
	local function Stop()
		if Done then return end
		Done = true
		if ActiveMoves[Hrp] == Stop then
			ActiveMoves[Hrp] = nil
		end
		if Conn then Conn:Disconnect() end
		if LV then LV.VectorVelocity = Vector3.zero end
		if Hrp then
			Hrp.AssemblyLinearVelocity = Vector3.zero
			Hrp.AssemblyAngularVelocity = Vector3.zero
		end
		if LV then LV:Destroy() end
		if AO then AO:Destroy() end
		if Att then Att:Destroy() end
		if UseNoClip then
			SetNoClip(false)
		end
		if Hum then
			Hum.PlatformStand = false
			Hum.AutoRotate = true
		end
	end

	ActiveMoves[Hrp] = Stop

	Conn = RunService.Heartbeat:Connect(function()
		if Done then return end
		if not Hrp or not Hrp.Parent then
			Stop()
			return
		end
		local Goal = Returning and StartPos or GetGoal()
		if not Goal then
			Stop()
			return
		end
		if UseFlatXZ then
			Goal = Vector3.new(Goal.X, BaseY, Goal.Z)
		end

		local Pos = Hrp.Position
		local Dx = Goal.X - Pos.X
		local Dy = Goal.Y - Pos.Y
		local Dz = Goal.Z - Pos.Z
		local DistXZ = math.sqrt(Dx * Dx + Dz * Dz)
		local Dist3 = math.sqrt(Dx * Dx + Dy * Dy + Dz * Dz)
		local ReachDist = UseFlatXZ and DistXZ or Dist3
		if ReachDist <= Reach then
			LV.VectorVelocity = Vector3.zero
			Hrp.AssemblyLinearVelocity = Vector3.zero
			Hrp.AssemblyAngularVelocity = Vector3.zero
			if not Returning then
				if Callback then
					task.spawn(Callback)
				end
				if ReturnToStart then
					Returning = true
					return
				end
			end
			Stop()
			return
		end

		AO.CFrame = CFrame.Angles(0, Y, 0)

		local Vx, Vy, Vz = 0, 0, 0
		if UseFlatXZ then
			if DistXZ > 1e-3 then
				Vx = Dx / DistXZ * Speed
				Vz = Dz / DistXZ * Speed
			end
			local YErr = BaseY - Pos.Y
			Vy = math.clamp(YErr * 14, -MaxYSpeed, MaxYSpeed)
		else
			if Dist3 > 1e-3 then
				Vx = Dx / Dist3 * Speed
				Vy = math.clamp((Dy / Dist3) * Speed, -MaxYSpeed, MaxYSpeed)
				Vz = Dz / Dist3 * Speed
			end
		end

		LV.VectorVelocity = Vector3.new(Vx, Vy, Vz)
	end)

	return Stop
end

return ForceMove
