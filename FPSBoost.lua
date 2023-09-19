if not game:IsLoaded() then
    repeat
        task.wait()
    until game:IsLoaded()
end

local FPSBoost = {}

FPSBoost.FPSBoostSettings = {
    ["FPS Cap"] = true, -- Set this true to uncap FPS,
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

local Players = game:GetService("Players")
local ME = Players.LocalPlayer

FPSBoost.originalInstanceSettings = {}

local function PartOfCharacter(Instance)
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= ME and v.Character and Instance:IsDescendantOf(v.Character) then
            return true
        end
    end
    return false
end

local function DescendantOfIgnore(Instance)
    for i, v in pairs(_G.Ignore) do
        if Instance:IsDescendantOf(v) then
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
        {setting = FPSBoost.AdvancedFPSBoostSettings.MeshPartSettings, attribute = "RenderFidelity", condition = "LowerQuality", changeTo = Enum.RenderFidelity.Performance, method = "ChangeAttribute", originalValue = Enum.RenderFidelity.Automatic},
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

local function CheckIfBad(Instance)
    if not Instance:IsDescendantOf(Players) then
        if FPSBoost.AdvancedFPSBoostSettings.PlayerSettings["Ignore Me"] and ME.Character and Instance:IsDescendantOf(ME.Character) then
            return
        end
        if FPSBoost.AdvancedFPSBoostSettings.PlayerSettings["Ignore Others"] and PartOfCharacter(Instance) then
            return
        end
        if FPSBoost.AdvancedFPSBoostSettings.PlayerSettings["Ignore Tools"] and (Instance:IsA("BackpackItem") or Instance:FindFirstAncestorWhichIsA("BackpackItem")) then
            return
        end
        
        for className, settings in pairs(settingsMapping) do
            if Instance:IsA(className) then
                for _, settingInfo in ipairs(settings) do
                    if settingInfo.setting[settingInfo.condition] then
                        if not FPSBoost.originalInstanceSettings[tostring(Instance)] then
                            FPSBoost.originalInstanceSettings[tostring(Instance)] = {}
                        end
                        if settingInfo.method == "Destroy" then
                            Instance:Destroy()
                        else
                            FPSBoost.originalInstanceSettings[tostring(Instance)][settingInfo.attribute] = Instance[settingInfo.attribute]
                            Instance[settingInfo.attribute] = settingInfo.changeTo
                        end
                    end
                end
                break
            end
        end

        if Instance:IsA("BasePart") and FPSBoost.FPSBoostSettings["Low Quality Parts"] then
            Instance.Material = Enum.Material.Plastic
            Instance.Reflectance = 0
        end
    end
end

local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local MaterialService = game:GetService("MaterialService")
local workspace = game:GetService("Workspace")

function FPSBoost:applyLowWaterGraphics()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        if self.FPSBoostSettings["Low Water Graphics"] then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
            if sethiddenproperty then
                sethiddenproperty(terrain, "Decoration", false)
            else
                warn("Your exploit does not support sethiddenproperty, please use a different exploit.")
            end
        elseif settingsMapping.LowWaterGraphics.Decoration then
            terrain.WaterWaveSize = settingsMapping.LowWaterGraphics.WaterWaveSize
            terrain.WaterWaveSpeed = settingsMapping.LowWaterGraphics.WaterWaveSpeed
            terrain.WaterReflectance = settingsMapping.LowWaterGraphics.WaterReflectance
            terrain.WaterTransparency = settingsMapping.LowWaterGraphics.WaterTransparency
            if sethiddenproperty then
                sethiddenproperty(terrain, "Decoration", settingsMapping.LowWaterGraphics.Decoration)
            end
        end
    end
end

function FPSBoost:applyNoShadows()
    if self.FPSBoostSettings["No Shadows"] then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        if sethiddenproperty then
            sethiddenproperty(Lighting, "Technology", 2)
        else
            warn("Your exploit does not support sethiddenproperty, please use a different exploit.")
        end
    elseif settingsMapping.NoShadows.Technology then
        Lighting.GlobalShadows = settingsMapping.NoShadows.GlobalShadows
        Lighting.FogEnd = settingsMapping.NoShadows.FogEnd
        Lighting.ShadowSoftness = settingsMapping.NoShadows.ShadowSoftness
        if sethiddenproperty then
            sethiddenproperty(Lighting, "Technology", settingsMapping.NoShadows.Technology)
        end
    end
end

function FPSBoost:applyLowRendering()
    if self.FPSBoostSettings["Low Rendering"] then
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    else
        settings().Rendering.QualityLevel = settingsMapping.LowRendering.QualityLevel
        settings().Rendering.MeshPartDetailLevel = settingsMapping.LowRendering.MeshPartDetailLevel
    end
end

function FPSBoost:applyFPSCap()
    local fpsCap = self.FPSBoostSettings["FPS Cap"]
    if fpsCap then
        if setfpscap then
            local capValue = (type(fpsCap) == "number" or type(fpsCap) == "string") and tonumber(fpsCap) or (fpsCap == true and 1e6 or settingsMapping.FPSCap.Cap)
            setfpscap(capValue)
            warn("FPS Capped to " .. tostring(capValue))
        else
            warn("FPS Cap Failed")
        end
    elseif settingsMapping.FPSCap.Cap then
        setfpscap(settingsMapping.FPSCap.Cap)
    end
end

function FPSBoost:initialize()
    self:applyLowWaterGraphics()
    self:applyNoShadows()
    self:applyLowRendering()
    self:applyFPSCap()

    workspace.DescendantAdded:Connect(function(instance)
        CheckIfBad(instance)
    end)
end

FPSBoost:initialize(settingsMapping)

return FPSBoost
