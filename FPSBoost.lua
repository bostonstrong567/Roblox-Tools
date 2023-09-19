if not game:IsLoaded() then
    repeat
        task.wait(0.1)
    until game:IsLoaded()
end

local FPSBoost = {}
local Players = game:GetService("Players")
local ME = Players.LocalPlayer
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
        if player ~= ME and character and Instance:IsDescendantOf(character) then
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

local function DescendantOfIgnore(Instance)
    for i, v in pairs(_G.Ignore) do
        if Instance:IsDescendantOf(v) then
            return true
        end
    end
    return false
end

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
        if Instance:IsA("MeshPart") then
            if FPSBoost.AdvancedFPSBoostSettings.MeshPartSettings.LowerQuality then
                Instance.Reflectance = 0
                Instance.Material = Enum.Material.Plastic
            end
            if FPSBoost.AdvancedFPSBoostSettings.MeshPartSettings.Invisible then
                Instance.Transparency = 1
                Instance.Reflectance = 0
                Instance.Material = Enum.Material.Plastic
            end
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
    else
        settings().Rendering.QualityLevel = renderingSettings.QualityLevel
        settings().Rendering.MeshPartDetailLevel = renderingSettings.MeshPartDetailLevel
    end
end

function FPSBoost:applyNoParticles()
    if not self.OriginalSettings.NoParticles then
        self.OriginalSettings.NoParticles = {}
    end

    if self.FPSBoostSettings["No Particles"] then
        for _, particle in pairs(workspace:FindPartsInRegion3(workspace:FindPartOnRay(Ray.new(workspace.Position, (workspace.Size + Vector3.new(1, 1, 1)) * 2)), nil, false)) do
            if particle:IsA("ParticleEmitter") or particle:IsA("Trail") then
                table.insert(self.OriginalSettings.NoParticles, {particle = particle, state = particle.Enabled})
                
                if self.AdvancedFPSBoostSettings.ParticleSettings.Destroy then
                    particle:Destroy()
                else
                    particle.Enabled = not self.AdvancedFPSBoostSettings.ParticleSettings.Invisible
                end
            end
        end
    else
        for _, data in pairs(self.OriginalSettings.NoParticles) do
            if data.particle and data.particle:IsA("BasePart") then  -- Check if the particle still exists
                data.particle.Enabled = data.state
            end
        end
        self.OriginalSettings.NoParticles = {}  -- Clear the original settings after reverting
    end
end

function FPSBoost:applyNoCameraEffects()
    local StarterGui = game:GetService("StarterGui")
    
    if not self.OriginalSettings.NoCameraEffects then
        self.OriginalSettings.NoCameraEffects = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.All)
    end
    
    if self.FPSBoostSettings["No Camera Effects"] then
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    else
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, self.OriginalSettings.NoCameraEffects)
    end
end


function FPSBoost:applyNoExplosions()
    if not self.OriginalSettings.NoExplosions then
        self.OriginalSettings.NoExplosions = {}
    end

    workspace.DescendantAdded:Connect(function(item)
        if item:IsA("Explosion") then
            if self.FPSBoostSettings["No Explosions"] then
                local originalSettings = {
                    Visible = item.Visible,
                    BlastPressure = item.BlastPressure,
                    BlastRadius = item.BlastRadius
                }
                table.insert(self.OriginalSettings.NoExplosions, {item = item, settings = originalSettings})

                if self.AdvancedFPSBoostSettings.ExplosionSettings.Destroy then
                    item:Destroy()
                else
                    item.Visible = not self.AdvancedFPSBoostSettings.ExplosionSettings.Invisible
                    item.BlastPressure = self.AdvancedFPSBoostSettings.ExplosionSettings.Smaller and 1 or item.BlastPressure
                    item.BlastRadius = self.AdvancedFPSBoostSettings.ExplosionSettings.Smaller and 1 or item.BlastRadius
                end
            else
                for _, data in pairs(self.OriginalSettings.NoExplosions) do
                    if data.item and data.item:IsA("Explosion") then
                        data.item.Visible = data.settings.Visible
                        data.item.BlastPressure = data.settings.BlastPressure
                        data.item.BlastRadius = data.settings.BlastRadius
                    end
                end
                self.OriginalSettings.NoExplosions = {}
            end
        end
    end)
end

function FPSBoost:applyNoClothes()
    if not self.OriginalSettings.NoClothes then
        self.OriginalSettings.NoClothes = {}
    end

    workspace.DescendantAdded:Connect(function(item)
        if item:IsA("Clothing") or item:IsA("Pants") or item:IsA("Shirt") then
            if self.FPSBoostSettings["No Clothes"] then
                local originalParent = item.Parent
                table.insert(self.OriginalSettings.NoClothes, {item = item, parent = originalParent})
                item:Destroy()
            else
                for _, data in pairs(self.OriginalSettings.NoClothes) do
                    if data.item then
                        data.item.Parent = data.parent
                    end
                end
                self.OriginalSettings.NoClothes = {}
            end
        end
    end)
end

function FPSBoost:applyLowQualityParts()
    if not self.OriginalSettings.LowQualityParts then
        self.OriginalSettings.LowQualityParts = {}
    end

    workspace.DescendantAdded:Connect(function(item)
        if item:IsA("Part") or item:IsA("MeshPart") then
            if self.FPSBoostSettings["Low Quality Parts"] then
                local originalSettings = {
                    Material = item.Material,
                    Reflectance = item.Reflectance,
                    TextureID = item:IsA("MeshPart") and item.TextureID or nil,
                    MeshId = item:IsA("MeshPart") and item.MeshId or nil
                }
                table.insert(self.OriginalSettings.LowQualityParts, {item = item, settings = originalSettings})

                if self.AdvancedFPSBoostSettings.MeshPartSettings.LowerQuality then
                    item.Material = Enum.Material.Plastic
                    item.Reflectance = 0
                end
                if self.AdvancedFPSBoostSettings.MeshPartSettings.NoTexture then
                    item.TextureID = ""
                end
                if self.AdvancedFPSBoostSettings.MeshPartSettings.NoMesh and item:IsA("MeshPart") then
                    item.MeshId = ""
                end
                if self.AdvancedFPSBoostSettings.MeshPartSettings.Destroy then
                    item:Destroy()
                end
            else
                for _, data in pairs(self.OriginalSettings.LowQualityParts) do
                    if data.item then
                        data.item.Material = data.settings.Material
                        data.item.Reflectance = data.settings.Reflectance
                        if data.item:IsA("MeshPart") then
                            data.item.TextureID = data.settings.TextureID
                            data.item.MeshId = data.settings.MeshId
                        end
                    end
                end
                self.OriginalSettings.LowQualityParts = {}
            end
        end
    end)
end

function FPSBoost:updateSettings()
    self:applyLowWaterGraphics()
    self:applyNoShadows()
    self:applyLowRendering()
    print("FPSBoost settings updated.")
end

function FPSBoost:initialize()
    self:applyLowWaterGraphics()
    self:applyNoShadows()
    self:applyLowRendering()

    workspace.DescendantAdded:Connect(function(instance)
        CheckIfBad(instance)
    end)
end

FPSBoost:initialize()

return FPSBoost
