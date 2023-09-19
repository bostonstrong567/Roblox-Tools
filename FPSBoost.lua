if not game:IsLoaded() then
    repeat
        task.wait(0.1)
    until game:IsLoaded()
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local MaterialService = game:GetService("MaterialService")

local FPSBoost = {}

FPSBoost.FPSBoostSettings = {
    ["No Particles"] = false,
    ["No Camera Effects"] = false,
    ["No Explosions"] = false,
    ["No Clothes"] = false,
    ["Low Water Graphics"] = false,
    ["No Shadows"] = false,
    ["Low Rendering"] = false,
    ["Low Quality Parts"] = false
}

FPSBoost.AdvancedFPSBoostSettings = {
    PlayerSettings = {
        ["Ignore Me"] = true,
        ["Ignore Others"] = true,
        ["Ignore Tools"] = true
    },
    MeshSettings = {
        NoMesh = false,
        NoTexture = false,
        Destroy = false
    },
    ImageSettings = {
        Invisible = true,
        Destroy = false
    },
    ExplosionSettings = {
        Smaller = true,
        Invisible = false,
        Destroy = false
    },
    ParticleSettings = {
        Invisible = true,
        Destroy = false
    },
    TextLabelSettings = {
        LowerQuality = false,
        Invisible = false,
        Destroy = false
    },
    MeshPartSettings = {
        LowerQuality = true,
        Invisible = false,
        NoTexture = false,
        NoMesh = false,
        Destroy = false
    },
}

FPSBoost.OriginalSettings = {}
FPSBoost.originalInstanceSettings = {}

function FPSBoost:PartOfCharacter(instance)
    local playerCharacter = player.Character
    if playerCharacter and instance:IsDescendantOf(playerCharacter) then
        return true
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local character = p.Character
            if character and instance:IsDescendantOf(character) then
                return true
            end
        end
    end

    return false
end

function FPSBoost:applySettings(settingKey, className, applySetting, revertSetting, nonWorkspace)
    if not self.OriginalSettings[settingKey] then
        self.OriginalSettings[settingKey] = {}
    end

    workspace.DescendantAdded:Connect(function(item)
        if item and item:IsA(className) then
            if self.FPSBoostSettings[settingKey] then
                local originalSettings = applySetting(item)
                if originalSettings then
                    table.insert(self.OriginalSettings[settingKey], {item = item, settings = originalSettings})
                end
            else
                for _, data in pairs(self.OriginalSettings[settingKey]) do
                    if data and data.item and data.settings then
                        revertSetting(data)
                    end
                end
                self.OriginalSettings[settingKey] = {}
            end
        end
    end)
end

function FPSBoost:modifyAttribute(instance, attribute, value)
    if not self.originalInstanceSettings[instance] then
        self.originalInstanceSettings[instance] = {}
    end
    self.originalInstanceSettings[instance][attribute] = instance[attribute]
    instance[attribute] = value
end

local settingsMapping = {
    DataModelMesh = {
        {setting = FPSBoost.AdvancedFPSBoostSettings.MeshSettings, attribute = "MeshId", condition = "NoMesh", changeTo = "", method = "ChangeAttribute", originalValue = ""},
        {setting = FPSBoost.AdvancedFPSBoostSettings.MeshSettings, attribute = "TextureId", condition = "NoTexture", changeTo = "", method = "ChangeAttribute", originalValue = ""},
        {setting = FPSBoost.AdvancedFPSBoostSettings.MeshSettings, condition = "Destroy", method = "Destroy"},
    },
    ImageLabel = {
        {setting = FPSBoost.AdvancedFPSBoostSettings.ImageSettings, attribute = "ImageTransparency", condition = "Invisible", changeTo = 1, method = "ChangeAttribute", originalValue = 0},
        {setting = FPSBoost.AdvancedFPSBoostSettings.ImageSettings, condition = "Destroy", method = "Destroy"},
    },
    ImageButton = {
        {setting = FPSBoost.AdvancedFPSBoostSettings.ImageSettings, attribute = "ImageTransparency", condition = "Invisible", changeTo = 1, method = "ChangeAttribute", originalValue = 0},
        {setting = FPSBoost.AdvancedFPSBoostSettings.ImageSettings, condition = "Destroy", method = "Destroy"},
    },
    Explosion = {
        {setting = FPSBoost.AdvancedFPSBoostSettings.ExplosionSettings, attribute = "BlastPressure", condition = "Smaller", changeTo = 100000, method = "ChangeAttribute", originalValue = 500000},
        {setting = FPSBoost.AdvancedFPSBoostSettings.ExplosionSettings, attribute = "BlastRadius", condition = "Smaller", changeTo = 10, method = "ChangeAttribute", originalValue = 50},
        {setting = FPSBoost.AdvancedFPSBoostSettings.ExplosionSettings, attribute = "Visible", condition = "Invisible", changeTo = false, method = "ChangeAttribute", originalValue = true},
        {setting = FPSBoost.AdvancedFPSBoostSettings.ExplosionSettings, condition = "Destroy", method = "Destroy"},
    },
    ParticleEmitter = {
        {setting = FPSBoost.AdvancedFPSBoostSettings.ParticleSettings, attribute = "Enabled", condition = "Invisible", changeTo = false, method = "ChangeAttribute", originalValue = true},
        {setting = FPSBoost.AdvancedFPSBoostSettings.ParticleSettings, condition = "Destroy", method = "Destroy"},
    },
    Trail = {
        {setting = FPSBoost.AdvancedFPSBoostSettings.ParticleSettings, attribute = "Enabled", condition = "Invisible", changeTo = false, method = "ChangeAttribute", originalValue = true},
        {setting = FPSBoost.AdvancedFPSBoostSettings.ParticleSettings, condition = "Destroy", method = "Destroy"},
    },
    Smoke = {
        {setting = FPSBoost.AdvancedFPSBoostSettings.ParticleSettings, attribute = "Enabled", condition = "Invisible", changeTo = false, method = "ChangeAttribute", originalValue = true},
        {setting = FPSBoost.AdvancedFPSBoostSettings.ParticleSettings, condition = "Destroy", method = "Destroy"},
    },
    Fire = {
        {setting = FPSBoost.AdvancedFPSBoostSettings.ParticleSettings, attribute = "Enabled", condition = "Invisible", changeTo = false, method = "ChangeAttribute", originalValue = true},
        {setting = FPSBoost.AdvancedFPSBoostSettings.ParticleSettings, condition = "Destroy", method = "Destroy"},
    },
    Sparkles = {
        {setting = FPSBoost.AdvancedFPSBoostSettings.ParticleSettings, attribute = "Enabled", condition = "Invisible", changeTo = false, method = "ChangeAttribute", originalValue = true},
        {setting = FPSBoost.AdvancedFPSBoostSettings.ParticleSettings, condition = "Destroy", method = "Destroy"},
    },
    TextLabel = {
        {setting = FPSBoost.AdvancedFPSBoostSettings.TextLabelSettings, attribute = "Font", condition = "LowerQuality", changeTo = Enum.Font.SourceSans, method = "ChangeAttribute", originalValue = Enum.Font.SourceSansBold},
        {setting = FPSBoost.AdvancedFPSBoostSettings.TextLabelSettings, attribute = "TextScaled", condition = "LowerQuality", changeTo = false, method = "ChangeAttribute", originalValue = true},
        {setting = FPSBoost.AdvancedFPSBoostSettings.TextLabelSettings, attribute = "RichText", condition = "LowerQuality", changeTo = false, method = "ChangeAttribute", originalValue = true},
        {setting = FPSBoost.AdvancedFPSBoostSettings.TextLabelSettings, attribute = "TextSize", condition = "LowerQuality", changeTo = 12, method = "ChangeAttribute", originalValue = 24},
        {setting = FPSBoost.AdvancedFPSBoostSettings.TextLabelSettings, attribute = "Visible", condition = "Invisible", changeTo = false, method = "ChangeAttribute", originalValue = true},
        {setting = FPSBoost.AdvancedFPSBoostSettings.TextLabelSettings, condition = "Destroy", method = "Destroy"},
    },
    MeshPart = {
        -- {setting = FPSBoost.AdvancedFPSBoostSettings.MeshPartSettings, attribute = "RenderFidelity", condition = "LowerQuality", changeTo = Enum.RenderFidelity.Performance, method = "ChangeAttribute", originalValue = Enum.RenderFidelity.Automatic},
        {setting = FPSBoost.AdvancedFPSBoostSettings.MeshPartSettings, attribute = "Material", condition = "LowerQuality", changeTo = Enum.Material.Plastic, method = "ChangeAttribute", originalValue = Enum.Material.SmoothPlastic},
        {setting = FPSBoost.AdvancedFPSBoostSettings.MeshPartSettings, attribute = "Reflectance", condition = "LowerQuality", changeTo = 0, method = "ChangeAttribute", originalValue = 0.5},
        {setting = FPSBoost.AdvancedFPSBoostSettings.MeshPartSettings, attribute = "Transparency", condition = "Invisible", changeTo = 1, method = "ChangeAttribute", originalValue = 0},
        {setting = FPSBoost.AdvancedFPSBoostSettings.MeshPartSettings, condition = "Destroy", method = "Destroy"},
    },

    LowWaterGraphics = workspace:FindFirstChildOfClass("Terrain") and {
        WaterWaveSize = workspace:FindFirstChildOfClass("Terrain").WaterWaveSize,
        WaterWaveSpeed = workspace:FindFirstChildOfClass("Terrain").WaterWaveSpeed,
        WaterReflectance = workspace:FindFirstChildOfClass("Terrain").WaterReflectance,
        WaterTransparency = workspace:FindFirstChildOfClass("Terrain").WaterTransparency,
        Decoration = sethiddenproperty and gethiddenproperty(workspace:FindFirstChildOfClass("Terrain"), "Decoration")
    } or {},
        NoShadows = {
        GlobalShadows = game.Lighting.GlobalShadows,
        FogEnd = game.Lighting.FogEnd,
        ShadowSoftness = game.Lighting.ShadowSoftness,
        Technology = sethiddenproperty and gethiddenproperty(game.Lighting, "Technology")
    },
    LowRendering = {
        QualityLevel = settings().Rendering.QualityLevel,
        MeshPartDetailLevel = settings().Rendering.MeshPartDetailLevel
    }
}

function FPSBoost:initialize()
    self:applyLowWaterGraphics()
    self:applyNoShadows()
    self:applyLowRendering()
    self:applyNoParticles()
    self:applyNoCameraEffects()
    self:applyNoExplosions()
    self:applyNoClothes()
    self:applyLowQualityParts()

    workspace.DescendantAdded:Connect(function(instance)
        self:CheckIfBad(instance)
    end)
end

function FPSBoost:CheckIfBad(instance)
    if not instance:IsDescendantOf(Players) then
        local playerCharacter = self:PartOfCharacter(instance)
        local playerSettings = self.AdvancedFPSBoostSettings.PlayerSettings
        if (playerSettings["Ignore Me"] and player.Character and instance:IsDescendantOf(player.Character)) or 
           (playerSettings["Ignore Others"] and playerCharacter) or 
           (playerSettings["Ignore Tools"] and (instance:IsA("BackpackItem") or instance:FindFirstAncestorWhichIsA("BackpackItem"))) then
            return
        end

        local settingsToCheck = settingsMapping[instance.ClassName] or {}
        for _, settingInfo in ipairs(settingsToCheck) do
            if settingInfo.setting[settingInfo.condition] then
                if not self.originalInstanceSettings[instance] then
                    self.originalInstanceSettings[instance] = {}
                end
                if settingInfo.method == "Destroy" then
                    if instance:IsA("Part") or instance:IsA("MeshPart") then
                        for _, child in ipairs(instance:GetChildren()) do
                            if child:IsA("Trail") or child:IsA("Attachment") then
                                child:Destroy()
                            end
                        end
                    end
                    -- Adding a check to avoid removing essential components
                    if instance.Name ~= "Crystal" then
                        pcall(function()
                            instance:Destroy()
                        end)
                    end
                else
                    pcall(function()
                        self.originalInstanceSettings[instance][settingInfo.attribute] = instance[settingInfo.attribute]
                        instance[settingInfo.attribute] = settingInfo.changeTo
                    end)
                end
            end
        end
        self:applyInstanceSettings(instance)
    end
end

function FPSBoost:applyInstanceSettings(instance)
    if instance:IsA("BasePart") and self.FPSBoostSettings["Low Quality Parts"] then
        instance.Material = Enum.Material.Plastic
        instance.Reflectance = 0
    end
    if instance:IsA("MeshPart") then
        if self.AdvancedFPSBoostSettings.MeshPartSettings.LowerQuality then
            instance.Reflectance = 0
            instance.Material = Enum.Material.Plastic
        end
        if self.AdvancedFPSBoostSettings.MeshPartSettings.Invisible then
            instance.Transparency = 1
            instance.Reflectance = 0
            instance.Material = Enum.Material.Plastic
        end
    end
end

function FPSBoost:applyNoParticles()
    self:applySettings(
        "No Particles",
        function(item)
            return item:IsA("ParticleEmitter") or item:IsA("Trail")
        end,
        function(item)
            return {Enabled = item.Enabled}
        end,
        function(data)
            if data.item and data.item:IsA("BasePart") then
                data.item.Enabled = data.settings.Enabled
            end
        end
    )
end

function FPSBoost:applyNoCameraEffects()
    self:applySettings(
        "No Camera Effects",
        function(item)
            return false  -- This function does not apply to any specific item type
        end,
        function()
            return {CoreGuiEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.All)}
        end,
        function(data)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, data.settings.CoreGuiEnabled)
        end,
        true  -- Indicates that this function does not apply to workspace descendants
    )
end

function FPSBoost:applyNoExplosions()
    self:applySettings(
        "No Explosions",
        function(item)
            return item:IsA("Explosion")
        end,
        function(item)
            return {
                Visible = item.Visible,
                BlastPressure = item.BlastPressure,
                BlastRadius = item.BlastRadius
            }
        end,
        function(data)
            if data.item and data.item:IsA("Explosion") then
                data.item.Visible = data.settings.Visible
                data.item.BlastPressure = data.settings.BlastPressure
                data.item.BlastRadius = data.settings.BlastRadius
            end
        end
    )
end

function FPSBoost:applyNoClothes()
    self:applySettings(
        "No Clothes",
        function(item)
            return item:IsA("Clothing") or item:IsA("Pants") or item:IsA("Shirt")
        end,
        function(item)
            return {Parent = item.Parent}
        end,
        function(data)
            if data.item then
                if self.FPSBoostSettings["No Clothes"] then
                    data.item.Parent = nil
                else
                    data.item.Parent = data.settings.Parent
                end
            end
        end
    )
end

function FPSBoost:applyLowWaterGraphics()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        local lowWaterGraphics = self.FPSBoostSettings["Low Water Graphics"]
        local terrainSettings = settingsMapping.LowWaterGraphics

        if not self.OriginalSettings.LowWaterGraphics then
            self.OriginalSettings.LowWaterGraphics = {
                WaterWaveSize = terrain.WaterWaveSize,
                WaterWaveSpeed = terrain.WaterWaveSpeed,
                WaterReflectance = terrain.WaterReflectance,
                WaterTransparency = terrain.WaterTransparency,
                Decoration = gethiddenproperty(terrain, "Decoration")
            }
        end

        if lowWaterGraphics then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
            sethiddenproperty(terrain, "Decoration", false)
        else
            local original = self.OriginalSettings.LowWaterGraphics
            terrain.WaterWaveSize = original.WaterWaveSize
            terrain.WaterWaveSpeed = original.WaterWaveSpeed
            terrain.WaterReflectance = original.WaterReflectance
            terrain.WaterTransparency = original.WaterTransparency
            sethiddenproperty(terrain, "Decoration", original.Decoration)
        end
    end
end

function FPSBoost:applyNoShadows()
    local noShadows = self.FPSBoostSettings["No Shadows"]
    local lightingSettings = settingsMapping.NoShadows

    if not self.OriginalSettings.NoShadows then
        self.OriginalSettings.NoShadows = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            ShadowSoftness = Lighting.ShadowSoftness,
            Technology = gethiddenproperty(Lighting, "Technology")
        }
    end

    if noShadows then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        sethiddenproperty(Lighting, "Technology", 2)
    else
        local original = self.OriginalSettings.NoShadows
        Lighting.GlobalShadows = original.GlobalShadows
        Lighting.FogEnd = original.FogEnd
        Lighting.ShadowSoftness = original.ShadowSoftness
        sethiddenproperty(Lighting, "Technology", original.Technology)
    end
end

function FPSBoost:applyLowRendering()
    local lowRendering = self.FPSBoostSettings["Low Rendering"]
    local renderingSettings = settingsMapping.LowRendering

    if not self.OriginalSettings.LowRendering then
        self.OriginalSettings.LowRendering = {
            QualityLevel = settings().Rendering.QualityLevel,
            MeshPartDetailLevel = settings().Rendering.MeshPartDetailLevel,
            WaterTransparency = workspace.Terrain.WaterTransparency,
            WaterWaveSize = workspace.Terrain.WaterWaveSize
        }
    end

    if lowRendering then
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        workspace.Terrain.WaterTransparency = 1
        workspace.Terrain.WaterWaveSize = 0
    else
        local original = self.OriginalSettings.LowRendering
        settings().Rendering.QualityLevel = original.QualityLevel
        settings().Rendering.MeshPartDetailLevel = original.MeshPartDetailLevel
        workspace.Terrain.WaterTransparency = original.WaterTransparency or 0.6
        workspace.Terrain.WaterWaveSize = original.WaterWaveSize or 8
    end
end

function FPSBoost:applyLowQualityParts()
    self:applySettings(
        "Low Quality Parts",
        function(item)
            return item:IsA("Part") or item:IsA("MeshPart")
        end,
        function(item)
            local originalSettings = {
                Material = item.Material,
                Reflectance = item.Reflectance
            }
            if item:IsA("MeshPart") then
                originalSettings.TextureID = item.TextureID
                originalSettings.MeshId = item.MeshId
            end
            return originalSettings
        end,
        function(data)
            if data.item then
                data.item.Material = data.settings.Material
                data.item.Reflectance = data.settings.Reflectance
                if data.item:IsA("MeshPart") then
                    data.item.TextureID = data.settings.TextureID
                    data.item.MeshId = data.settings.MeshId
                end
            end
        end
    )
end

function FPSBoost:updateSettings(key, value)
    if self.FPSBoostSettings[key] ~= nil then
        self.FPSBoostSettings[key] = value
    else
        for category, settings in pairs(self.AdvancedFPSBoostSettings) do
            if settings[key] ~= nil then
                settings[key] = value
                break
            end
        end
    end
    
    -- Apply the updated settings
    if key == "No Particles" then
        self:applyNoParticles()
    elseif key == "No Camera Effects" then
        self:applyNoCameraEffects()
    elseif key == "No Explosions" then
        self:applyNoExplosions()
    elseif key == "No Clothes" then
        self:applyNoClothes()
    elseif key == "Low Water Graphics" then
        self:applyLowWaterGraphics()
    elseif key == "No Shadows" then
        self:applyNoShadows()
    elseif key == "Low Rendering" then
        self:applyLowRendering()
    elseif key == "Low Quality Parts" then
        self:applyLowQualityParts()
    end
end

FPSBoost:initialize()

return FPSBoost
