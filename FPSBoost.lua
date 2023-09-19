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
    local originalValues = self.originalValues[descendant]

    if descendant:IsA("BasePart") and not descendant:IsA("Texture") then
        if not originalValues then
            originalValues = { Material = descendant.Material, Transparency = descendant.Transparency }
            self.originalValues[descendant] = originalValues
        end

        if self.settings.LowQualityParts then
            descendant.Material = Enum.Material.SmoothPlastic
            descendant.Reflectance = 0
        else
            descendant.Material = originalValues.Material
            descendant.Transparency = originalValues.Transparency
        end
    end

    if (descendant:IsA("Decal") or descendant:IsA("Texture")) then
        if not originalValues then
            originalValues = { Transparency = descendant.Transparency }
            self.originalValues[descendant] = originalValues
        end

        if self.settings.RemoveDecalsAndTextures then
            descendant.Transparency = 1
        else
            descendant.Transparency = originalValues.Transparency
        end
    end

    if (descendant:IsA("ParticleEmitter") or descendant:IsA("Trail")) then
        if not originalValues then
            originalValues = { Enabled = descendant.Enabled }
            self.originalValues[descendant] = originalValues
        end

        if self.settings.DisableParticles then
            descendant.Enabled = false
        else
            descendant.Enabled = originalValues.Enabled
        end
    end

    if descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
        if not originalValues then
            originalValues = { Enabled = descendant.Enabled }
            self.originalValues[descendant] = originalValues
        end

        if self.settings.DisableLights then
            descendant.Enabled = false
        else
            descendant.Enabled = originalValues.Enabled
        end
    end
end

function FPSBoost:applySettings()
    for descendant, originalValues in pairs(self.originalValues) do
        if descendant then
            if descendant:IsA("BasePart") and not descendant:IsA("Texture") then
                if self.settings.LowQualityParts then
                    descendant.Material = Enum.Material.SmoothPlastic
                    descendant.Reflectance = 0
                else
                    descendant.Material = originalValues.Material
                    descendant.Transparency = originalValues.Transparency
                end
            end

            if (descendant:IsA("Decal") or descendant:IsA("Texture")) then
                if self.settings.RemoveDecalsAndTextures then
                    descendant.Transparency = 1
                else
                    descendant.Transparency = originalValues.Transparency
                end
            end

            if (descendant:IsA("ParticleEmitter") or descendant:IsA("Trail")) then
                if self.settings.DisableParticles then
                    descendant.Enabled = false
                else
                    descendant.Enabled = originalValues.Enabled
                end
            end

            if descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
                if self.settings.DisableLights then
                    descendant.Enabled = false
                else
                    descendant.Enabled = originalValues.Enabled
                end
            end
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
