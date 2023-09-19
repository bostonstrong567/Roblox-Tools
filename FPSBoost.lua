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
    for i, e in ipairs(game.Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            originalValues[e] = { Enabled = e.Enabled }
        end
    end
    return originalValues
end

FPSBoost.originalValues = storeOriginalValues()

function FPSBoost:modifyDescendant(descendant)
    if not self.originalValues[descendant] then
        if descendant:IsA("BasePart") and not descendant:IsA("Texture") then
            self.originalValues[descendant] = { Material = descendant.Material, Transparency = descendant.Transparency }
        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
            self.originalValues[descendant] = { Transparency = descendant.Transparency }
        elseif descendant:IsA("Light") then
            self.originalValues[descendant] = { Enabled = descendant.Enabled }
        elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
            self.originalValues[descendant] = { Enabled = descendant.Enabled }
        end
    end

    if descendant:IsA("BasePart") and not descendant:IsA("Texture") then
        if self.settings.LowQualityParts then
            descendant.Material = Enum.Material.SmoothPlastic
            descendant.Reflectance = 0
        else
            descendant.Material = self.originalValues[descendant].Material
            descendant.Transparency = self.originalValues[descendant].Transparency
        end
    end

    if (descendant:IsA("Decal") or descendant:IsA("Texture")) and self.settings.RemoveDecalsAndTextures then
        descendant.Transparency = 1
    elseif self.originalValues[descendant] then
        descendant.Transparency = self.originalValues[descendant].Transparency
    end

    if (descendant:IsA("ParticleEmitter") or descendant:IsA("Trail")) and self.settings.DisableParticles then
        descendant.Enabled = false
    elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
        descendant.Enabled = self.originalValues[descendant].Enabled
    end

    if descendant:IsA("Light") and self.settings.DisableLights then
        descendant.Enabled = false
    elseif descendant:IsA("Light") then
        descendant.Enabled = self.originalValues[descendant].Enabled
    end
end

function FPSBoost:applySettings()
    for descendant, values in pairs(self.originalValues) do
        if descendant and descendant:IsA("BasePart") and not descendant:IsA("Texture") then
            if self.settings.LowQualityParts then
                descendant.Material = Enum.Material.SmoothPlastic
                descendant.Reflectance = 0
            else
                descendant.Material = values.Material
                descendant.Transparency = values.Transparency
            end
        end

        if (descendant and descendant:IsA("Decal") or descendant:IsA("Texture")) and self.settings.RemoveDecalsAndTextures then
            descendant.Transparency = 1
        elseif descendant and values then
            descendant.Transparency = values.Transparency
        end

        if (descendant and descendant:IsA("ParticleEmitter") or descendant:IsA("Trail")) and self.settings.DisableParticles then
            descendant.Enabled = false
        elseif descendant and values then
            descendant.Enabled = values.Enabled
        end

        if descendant and descendant:IsA("Light") and self.settings.DisableLights then
            descendant.Enabled = false
        elseif descendant and values then
            descendant.Enabled = values.Enabled
        end
    end

    for i, e in ipairs(game.Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            if self.settings.DisableEffects then
                e.Enabled = false
            else
                e.Enabled = self.originalValues[e] and self.originalValues[e].Enabled or true
            end
        end
    end
end

function FPSBoost:setupConnections()
    if connections.descendantAdded then
        connections.descendantAdded:Disconnect()
    end

    connections.descendantAdded = game.Workspace.DescendantAdded:Connect(function(descendant)
        self:modifyDescendant(descendant)
    end)
end

FPSBoost:setupConnections()

return FPSBoost
