if not game:IsLoaded() then
    repeat
        task.wait()
    until game:IsLoaded()
end

local Players = game:GetService("Players")
local ME = Players.LocalPlayer

_G.FPSBoostSettings = {
    OtherSettings = {
        ["FPS Cap"] = 240, -- Set this true to uncap FPS
        ["No Particles"] = false,
        ["No Camera Effects"] = false,
        ["No Explosions"] = false,
        ["No Clothes"] = false,
        ["Low Water Graphics"] = false,
        ["No Shadows"] = false,
        ["Low Rendering"] = false,
        ["Low Quality Parts"] = false
    }
}

_G.AdvancedFPSBoostSettings = {
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

local function CheckIfBad(Instance)
    if not Instance:IsDescendantOf(Players) then
        if _G.AdvancedFPSBoostSettings.PlayerSettings["Ignore Me"] and ME.Character and Instance:IsDescendantOf(ME.Character) then
            return
        end
        if _G.AdvancedFPSBoostSettings.PlayerSettings["Ignore Others"] and PartOfCharacter(Instance) then
            return
        end
        if _G.AdvancedFPSBoostSettings.PlayerSettings["Ignore Tools"] and (Instance:IsA("BackpackItem") or Instance:FindFirstAncestorWhichIsA("BackpackItem")) then
            return
        end

        if Instance:IsA("DataModelMesh") then
            if _G.AdvancedFPSBoostSettings.MeshSettings.NoMesh and Instance:IsA("SpecialMesh") then
                Instance.MeshId = ""
            end
            if _G.AdvancedFPSBoostSettings.MeshSettings.NoTexture and Instance:IsA("SpecialMesh") then
                Instance.TextureId = ""
            end
            if _G.AdvancedFPSBoostSettings.MeshSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("ImageLabel") or Instance:IsA("ImageButton") then
            if _G.AdvancedFPSBoostSettings.ImageSettings.Invisible then
                Instance.ImageTransparency = 1
            end
            if _G.AdvancedFPSBoostSettings.ImageSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("Explosion") then
            if _G.AdvancedFPSBoostSettings.ExplosionSettings.Smaller then
                Instance.BlastPressure = 1
                Instance.BlastRadius = 1
            end
            if _G.AdvancedFPSBoostSettings.ExplosionSettings.Invisible then
                Instance.Visible = false
            end
            if _G.AdvancedFPSBoostSettings.ExplosionSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("ParticleEmitter") or Instance:IsA("Trail") or Instance:IsA("Smoke") or Instance:IsA("Fire") or Instance:IsA("Sparkles") then
            if _G.AdvancedFPSBoostSettings.ParticleSettings.Invisible then
                Instance.Enabled = false
            end
            if _G.AdvancedFPSBoostSettings.ParticleSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("TextLabel") then
            if _G.AdvancedFPSBoostSettings.TextLabelSettings.LowerQuality then
                Instance.Font = Enum.Font.SourceSans
                Instance.TextScaled = false
                Instance.RichText = false
                Instance.TextSize = 14
            end
            if _G.AdvancedFPSBoostSettings.TextLabelSettings.Invisible then
                Instance.Visible = false
            end
            if _G.AdvancedFPSBoostSettings.TextLabelSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("MeshPart") then
            if _G.AdvancedFPSBoostSettings.MeshPartSettings.LowerQuality then
                Instance.RenderFidelity = Enum.RenderFidelity.Performance
                Instance.Material = Enum.Material.Plastic
                Instance.Reflectance = 0
            end
            if _G.AdvancedFPSBoostSettings.MeshPartSettings.Invisible then
                Instance.Transparency = 1
            end
            if _G.AdvancedFPSBoostSettings.MeshPartSettings.NoTexture then
                Instance.TextureID = ""
            end
            if _G.AdvancedFPSBoostSettings.MeshPartSettings.NoMesh then
                Instance.MeshId = ""
            end
            if _G.AdvancedFPSBoostSettings.MeshPartSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("BasePart") and _G.FPSBoostSettings.OtherSettings["Low Quality Parts"] then
            Instance.Material = Enum.Material.Plastic
            Instance.Reflectance = 0
        end
    end
end

local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local MaterialService = game:GetService("MaterialService")
local workspace = game:GetService("Workspace")

coroutine.wrap(function()
    if _G.FPSBoostSettings.OtherSettings["Low Water Graphics"] then
        if not workspace:FindFirstChildOfClass("Terrain") then
            repeat
                task.wait()
            until workspace:FindFirstChildOfClass("Terrain")
        end
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
        if sethiddenproperty then
            sethiddenproperty(terrain, "Decoration", false)
        else
            warn("Your exploit does not support sethiddenproperty, please use a different exploit.")
        end
    end
end)()

coroutine.wrap(function()
    if _G.FPSBoostSettings.OtherSettings["No Shadows"] then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        if sethiddenproperty then
            sethiddenproperty(Lighting, "Technology", 2)
        else
            warn("Your exploit does not support sethiddenproperty, please use a different exploit.")
        end
    end
end)()

coroutine.wrap(function()
    if _G.FPSBoostSettings.OtherSettings["Low Rendering"] then
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    end
end)()

coroutine.wrap(function()
    local fpsCap = _G.FPSBoostSettings.OtherSettings["FPS Cap"]
    if fpsCap then
        if setfpscap then
            if type(fpsCap) == "string" or type(fpsCap) == "number" then
                setfpscap(tonumber(fpsCap))
                warn("FPS Capped to " .. tostring(fpsCap))
            elseif fpsCap == true then
                setfpscap(1e6)
                warn("FPS Uncapped")
            end
        else
            warn("FPS Cap Failed")
        end
    end
end)()

local function onDescendantAdded(descendant)
    task.wait(_G.FPSBoostSettings.OtherSettings.LoadedWait or 1)
    CheckIfBad(descendant)
end

game.DescendantAdded:Connect(onDescendantAdded)
local descendants = game:GetDescendants()
local startNumber = _G.FPSBoostSettings.OtherSettings.WaitPerAmount or 500
local waitNumber = startNumber

for i, descendant in pairs(descendants) do
    CheckIfBad(descendant)
    if i == waitNumber then
        task.wait()
        waitNumber = waitNumber + startNumber
    end
end

print("FPS Booster Loaded!")
print("FPS Booster script fully initialized and running.")
