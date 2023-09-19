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
            originalValues[v] = { Material = v.Material, Transparency = v.Transparency }
        elseif v:IsA("Decal") or v:IsA("Texture") then
            originalValues[v] = { Transparency = v.Transparency }
        elseif v:IsA("Light") then
            originalValues[v] = { IsEnabled = v.Enabled }
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            originalValues[v] = { IsEnabled = v.Enabled }
        end
    end
    for i, e in ipairs(game.Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            originalValues[e] = { IsEnabled = e.Enabled }
        end
    end
    return originalValues
end

FPSBoost.originalValues = storeOriginalValues()

function FPSBoost:modifyDescendant(descendant)
    if descendant:IsA("BasePart") then
        if self.settings.LowQualityParts then
            descendant.Material = Enum.Material.SmoothPlastic
        else
            descendant.Material = self.originalValues[descendant] and self.originalValues[descendant].Material or descendant.Material
            descendant.Transparency = self.originalValues[descendant] and self.originalValues[descendant].Transparency or descendant.Transparency
        end
    end

    if (descendant:IsA("Decal") or descendant:IsA("Texture")) and self.settings.RemoveDecalsAndTextures then
        descendant.Transparency = 1
    end

    if (descendant:IsA("ParticleEmitter") or descendant:IsA("Trail")) and self.settings.DisableParticles then
        descendant.Enabled = false
    end

    if descendant:IsA("Light") and self.settings.DisableLights then
        descendant.Enabled = false
    end

    -- Store the original values of the new descendant
    if not self.originalValues[descendant] then
        if descendant:IsA("BasePart") then
            self.originalValues[descendant] = {Material = descendant.Material, Transparency = descendant.Transparency}
        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
            self.originalValues[descendant] = {Transparency = descendant.Transparency}
        elseif descendant:IsA("Light") or descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
            self.originalValues[descendant] = {IsEnabled = descendant.Enabled}
        end
    end
end

FPSBoost:setupConnections()

return FPSBoost
