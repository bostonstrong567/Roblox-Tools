if not game:IsLoaded() then
    repeat
        task.wait(0.1)
    until game:IsLoaded()
end

local FPSBoost = {}
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

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

local playerCharacters = {}
for _, player in pairs(Players:GetPlayers()) do
    playerCharacters[player] = player.Character
end

local function PartOfCharacter(Instance)
    for player, character in pairs(playerCharacters) do
        if player ~= player and character and Instance:IsDescendantOf(character) then
            return true
        end
    end
    return false
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

local function CheckIfBad(instance)
    if not instance:IsDescendantOf(Players) then
        local playerCharacter = PartOfCharacter(instance)
        local playerSettings = FPSBoost.AdvancedFPSBoostSettings.PlayerSettings
        if (playerSettings["Ignore Me"] and player.Character and instance:IsDescendantOf(player.Character)) or 
           (playerSettings["Ignore Others"] and playerCharacter) or 
           (playerSettings["Ignore Tools"] and (instance:IsA("BackpackItem") or instance:FindFirstAncestorWhichIsA("BackpackItem"))) then
            return
        end

        local settingsToCheck = settingsMapping[instance.ClassName] or {}
        for _, settingInfo in ipairs(settingsToCheck) do
            if settingInfo.setting[settingInfo.condition] then
                if not FPSBoost.originalInstanceSettings[instance] then
                    FPSBoost.originalInstanceSettings[instance] = {}
                end
                if settingInfo.method == "Destroy" then
                    if instance:IsA("Part") or instance:IsA("MeshPart") then
                        for _, child in ipairs(instance:GetChildren()) do
                            if child:IsA("Trail") or child:IsA("Attachment") then
                                child:Destroy()
                            end
                        end
                    end
                    instance:Destroy()
                else
                    FPSBoost.originalInstanceSettings[instance][settingInfo.attribute] = instance[settingInfo.attribute]
                    instance[settingInfo.attribute] = settingInfo.changeTo
                end
            end
        end
        if instance:IsA("BasePart") and FPSBoost.FPSBoostSettings["Low Quality Parts"] then
            instance.Material = Enum.Material.Plastic
            instance.Reflectance = 0
        end
        if instance:IsA("MeshPart") then
            if FPSBoost.AdvancedFPSBoostSettings.MeshPartSettings.LowerQuality then
                instance.Reflectance = 0
                instance.Material = Enum.Material.Plastic
            end
            if FPSBoost.AdvancedFPSBoostSettings.MeshPartSettings.Invisible then
                instance.Transparency = 1
                instance.Reflectance = 0
                instance.Material = Enum.Material.Plastic
            end
        end
    end
end

local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local MaterialService = game:GetService("MaterialService")
local workspace = game:GetService("Workspace")

local function applySettings(settingKey, className, applySetting, revertSetting)
    if not FPSBoost.OriginalSettings[settingKey] then
        FPSBoost.OriginalSettings[settingKey] = {}
    end

    workspace.DescendantAdded:Connect(function(item)
        if item:IsA(className) then
            if FPSBoost.FPSBoostSettings[settingKey] then
                local originalSettings = applySetting(item)
                table.insert(FPSBoost.OriginalSettings[settingKey], {item = item, settings = originalSettings})
            else
                for _, data in pairs(FPSBoost.OriginalSettings[settingKey]) do
                    revertSetting(data)
                end
                FPSBoost.OriginalSettings[settingKey] = {}
            end
        end
    end)
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
                data.item.Parent = data.settings.Parent
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

    if noShadows then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        sethiddenproperty(Lighting, "Technology", 2)
    elseif lightingSettings.Technology then
        Lighting.GlobalShadows = lightingSettings.GlobalShadows
        Lighting.FogEnd = lightingSettings.FogEnd
        Lighting.ShadowSoftness = lightingSettings.ShadowSoftness
        sethiddenproperty(Lighting, "Technology", lightingSettings.Technology)
    end
end

function FPSBoost:applyLowRendering()
    local lowRendering = self.FPSBoostSettings["Low Rendering"]
    local renderingSettings = settingsMapping.LowRendering

    if lowRendering then
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        workspace.Terrain.WaterTransparency = 1
        workspace.Terrain.WaterWaveSize = 0
    else
        settings().Rendering.QualityLevel = renderingSettings.QualityLevel
        settings().Rendering.MeshPartDetailLevel = renderingSettings.MeshPartDetailLevel
        workspace.Terrain.WaterTransparency = renderingSettings.WaterTransparency or 0.6
        workspace.Terrain.WaterWaveSize = renderingSettings.WaterWaveSize or 8
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

function FPSBoost:updateSettings(settingKey, value)
    self.FPSBoostSettings[settingKey] = value
    self:initialize()
end

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
        CheckIfBad(instance)
    end)
end

FPSBoost:initialize()

return FPSBoost
