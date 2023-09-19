local FPSBoost = {}

FPSBoost.settings = {
    LowQualityParts = false,
    RemoveDecalsAndTextures = false,
    DisableParticles = false,
    DisableLights = false,
    DisableEffects = false,
}

local connections = {}

local function storeOriginalValues()
    local originalValues = {}
    for i, v in pairs(game.Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            originalValues[v] = {Material = v.Material, Transparency = v.Transparency}
        elseif v:IsA("Decal") or v:IsA("Texture") then
            originalValues[v] = {Transparency = v.Transparency}
        elseif v:IsA("Light") then
            originalValues[v] = {IsEnabled = v.Enabled}
        end
    end
    for i, e in ipairs(game.Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            originalValues[e] = {IsEnabled = e.Enabled}
        end
    end
    return originalValues
end

FPSBoost.originalValues = storeOriginalValues()

function FPSBoost:modifyDescendant(descendant)
    if descendant:IsA("BasePart") then
        if self.settings.LowQualityParts then
            descendant.Material = "SmoothPlastic"
        else
            descendant.Material = self.originalValues[descendant] and self.originalValues[descendant].Material or descendant.Material
        end
    end

    if descendant:IsA("Decal") or descendant:IsA("Texture") then
        if self.settings.RemoveDecalsAndTextures then
            descendant.Transparency = 1
        else
            descendant.Transparency = self.originalValues[descendant] and self.originalValues[descendant].Transparency or descendant.Transparency
        end
    end

    if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
        if self.settings.DisableParticles then
            descendant.Enabled = false
        else
            descendant.Enabled = true
        end
    end

    if descendant:IsA("Light") then
        if self.settings.DisableLights then
            descendant.Enabled = false
        else
            descendant.Enabled = self.originalValues[descendant] and self.originalValues[descendant].IsEnabled or descendant.Enabled
        end
    end
end

function FPSBoost:applySettings()
    for i, v in pairs(game.Workspace:GetDescendants()) do
        self:modifyDescendant(v)
    end
end

function FPSBoost:setupConnections()
    if connections.descendantAdded then
        connections.descendantAdded:Disconnect()
    end

    connections.descendantAdded = game.Workspace.DescendantAdded:Connect(function(descendant)
        FPSBoost:modifyDescendant(descendant)
    end)
end

FPSBoost:setupConnections()

return FPSBoost
