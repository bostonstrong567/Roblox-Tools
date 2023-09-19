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
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("Texture") then
            originalValues[v] = { Material = v.Material, Transparency = v.Transparency }
        elseif v:IsA("Decal") or v:IsA("Texture") then
            originalValues[v] = { Transparency = v.Transparency }
        elseif v:IsA("Light") then
            originalValues[v] = { Enabled = v.Enabled }
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            originalValues[v] = { Enabled = v.Enabled }
        end
    end
    for _, e in ipairs(game:GetService("Lighting"):GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            originalValues[e] = { Enabled = e.Enabled }
        end
    end
    return originalValues
end

FPSBoost.originalValues = storeOriginalValues()

function FPSBoost:applySettings()
    self:toggleLowQualityParts()
    self:toggleRemoveDecalsAndTextures()
    self:toggleDisableParticles()
    self:toggleDisableLights()
    self:toggleDisableEffects()
end

function FPSBoost:toggleLowQualityParts()
    for descendant, originalValues in pairs(self.originalValues) do
        if descendant:IsA("BasePart") and not descendant:IsA("Texture") then
            if self.settings.LowQualityParts then
                descendant.Material = Enum.Material.SmoothPlastic
                descendant.Transparency = 1
            else
                descendant.Material = originalValues.Material
                descendant.Transparency = originalValues.Transparency
            end
        end
    end
end

function FPSBoost:toggleDecalsAndTextures()
    print("Toggling Decals and Textures") 
    for descendant, originalValues in pairs(self.originalValues) do
        if descendant:IsA("Decal") or descendant:IsA("Texture") then
            if self.settings.RemoveDecalsAndTextures then
                descendant.Transparency = 1
            else
                descendant.Transparency = originalValues.Transparency
            end
        end
    end
end

function FPSBoost:toggleParticles()
    print("Toggling Particles") 
    for descendant, originalValues in pairs(self.originalValues) do
        if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
            if self.settings.DisableParticles then
                descendant.Enabled = false
            else
                descendant.Enabled = originalValues.Enabled
            end
        end
    end
end

function FPSBoost:toggleLights()
    print("Toggling Lights") 
    for descendant, originalValues in pairs(self.originalValues) do
        if descendant:IsA("Light") then
            if self.settings.DisableLights then
                descendant.Enabled = false
            else
                descendant.Enabled = originalValues.Enabled
            end
        end
    end
end

function FPSBoost:toggleEffects()
    print("Toggling Effects")
    for _, e in pairs(game.Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            if self.settings.DisableEffects then
                e.Enabled = false
            else
                e.Enabled = self.originalValues[e] and self.originalValues[e].Enabled or true
            end
        end
    end
end

return FPSBoost
