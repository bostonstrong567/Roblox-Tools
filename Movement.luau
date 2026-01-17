local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function CoolForceMove(Target, Options)
	Options = Options or {}
	local Player = Options.Player or Players.LocalPlayer
	local Char = Options.Character or (Player and Player.Character)
	if not Char then
		if Player and Player.CharacterAdded then
			Char = Player.CharacterAdded:Wait()
		else
			return function() end
		end
	end

	local Hrp = Char:WaitForChild("HumanoidRootPart")
	local Hum = Char:FindFirstChildOfClass("Humanoid")

	local Speed = Options.Speed or 1250
	if Speed < 0 then Speed = 0 end
	local Reach = Options.ReachRadius or 5
	local UseFlatXZ = Options.UseFlatXZ
	if UseFlatXZ == nil then UseFlatXZ = true end
	local BaseY = Options.BaseY
	if UseFlatXZ and type(BaseY) ~= "number" then BaseY = Hrp.Position.Y end
	local MaxYSpeed = Options.MaxYSpeed or 250

	local function GetGoal()
		if typeof(Target) == "Vector3" then return Target end
		if typeof(Target) == "Instance" then
			if Target:IsA("BasePart") then return Target.Position end
			if Target:IsA("Model") then return Target:GetPivot().Position end
		end
	end

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

	local Done = false
	local Conn
	local function Stop()
		if Done then return end
		Done = true
		if Conn then Conn:Disconnect() end
		if LV then LV:Destroy() end
		if AO then AO:Destroy() end
		if Att then Att:Destroy() end
		if Hum then
			Hum.PlatformStand = false
			Hum.AutoRotate = true
		end
	end

	Conn = RunService.Heartbeat:Connect(function()
		if Done then return end
		if not Hrp or not Hrp.Parent then
			Stop()
			return
		end
		local Goal = GetGoal()
		if not Goal then
			Stop()
			return
		end
		if UseFlatXZ then
			Goal = Vector3.new(Goal.X, BaseY, Goal.Z)
		end

		local Pos = Hrp.Position
		local Dx = Goal.X - Pos.X
		local Dz = Goal.Z - Pos.Z
		local DistXZ = math.sqrt(Dx * Dx + Dz * Dz)
		if DistXZ <= Reach then
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
			local Dy = Goal.Y - Pos.Y
			local Dist3 = math.sqrt(Dx * Dx + Dy * Dy + Dz * Dz)
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

return CoolForceMove
