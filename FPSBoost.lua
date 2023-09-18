if not _G.Ignore then
    _G.Ignore = {} -- Add Instances to this table to ignore them (e.g. _G.Ignore = {workspace.Map, workspace.Map2})
end
if not _G.WaitPerAmount then
    _G.WaitPerAmount = 500 -- Set Higher or Lower depending on your computer's performance
end
if _G.ConsoleLogs == nil then
    _G.ConsoleLogs = false -- Set to true if you want console logs (mainly for debugging)
end

if not game:IsLoaded() then
    repeat
        task.wait()
    until game:IsLoaded()
end
if not _G.Settings then
    _G.Settings = {
        PlayerSettings = {
            ["Ignore Me"] = true, -- If set to true, the script will ignore the local player
            ["Ignore Others"] = true, -- If set to true, the script will ignore other players
            ["Ignore Tools"] = true -- If set to true, the script will ignore tools
        },
        MeshSettings = {
            NoMesh = false, -- If set to true, it will remove meshes from the game
            NoTexture = false, -- If set to true, it will remove textures from the meshes
            Destroy = false -- If set to true, it will destroy the mesh instances
        },
        ImageSettings = {
            Invisible = true, -- If set to true, it will make the images invisible
            Destroy = false -- If set to true, it will destroy the image instances
        },
        ExplosionSettings = {
            Smaller = true, -- If set to true, it will make the explosions smaller
            Invisible = false, -- If set to true, it will make the explosions invisible (not recommended for PVP games)
            Destroy = false -- If set to true, it will destroy the explosion instances (not recommended for PVP games)
        },
        ParticleSettings = {
            Invisible = true, -- If set to true, it will make the particles invisible
            Destroy = false -- If set to true, it will destroy the particle instances
        },
        TextLabelSettings = {
            LowerQuality = false, -- If set to true, it will reduce the quality of text labels
            Invisible = false, -- If set to true, it will make the text labels invisible
            Destroy = false -- If set to true, it will destroy the text label instances
        },
        MeshPartSettings = {
            LowerQuality = true, -- If set to true, it will reduce the quality of mesh parts
            Invisible = false, -- If set to true, it will make the mesh parts invisible
            NoTexture = false, -- If set to true, it will remove the texture from the mesh parts
            NoMesh = false, -- If set to true, it will remove the mesh from the mesh parts
            Destroy = false -- If set to true, it will destroy the mesh part instances
        },
        FPSBoostSettings = {
            ["No Particles"] = true, -- Disables all ParticleEmitter, Trail, Smoke, Fire, and Sparkles
            ["No Camera Effects"] = true, -- Disables all PostEffect's (Camera/Lighting Effects)
            ["No Explosions"] = true, -- Makes Explosion's invisible
            ["No Clothes"] = true, -- Removes Clothing from the game
            ["Low Water Graphics"] = true, -- Removes Water Quality
            ["No Shadows"] = true, -- Remove Shadows
            ["Low Rendering"] = true, -- Lower Rendering
            ["Low Quality Parts"] = true -- Lower quality parts
        }
    }
end

local Players, Lighting, MaterialService = game:GetService("Players"), game:GetService("Lighting"), game:GetService("MaterialService")
local ME, CanBeEnabled = Players.LocalPlayer, {"ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles"}

local function PartOfCharacter(Instance)
    for i, v in pairs(Players:GetPlayers()) do
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
    if not Instance:IsDescendantOf(Players) and (_G.Settings.PlayerSettings["Ignore Others"] and not PartOfCharacter(Instance) or not _G.Settings.PlayerSettings["Ignore Others"]) and (_G.Settings.PlayerSettings["Ignore Me"] and ME.Character and not Instance:IsDescendantOf(ME.Character) or not _G.Settings.PlayerSettings["Ignore Me"]) and (_G.Settings.PlayerSettings["Ignore Tools"] and not Instance:IsA("BackpackItem") and not Instance:FindFirstAncestorWhichIsA("BackpackItem") or not _G.Settings.PlayerSettings["Ignore Tools"]) and (not DescendantOfIgnore(Instance)) then
        if Instance:IsA("DataModelMesh") then
            if _G.Settings.MeshSettings.NoMesh and Instance:IsA("SpecialMesh") then
                Instance.MeshId = ""
            end
            if _G.Settings.MeshSettings.NoTexture and Instance:IsA("SpecialMesh") then
                Instance.TextureId = ""
            end
            if _G.Settings.MeshSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("FaceInstance") then
            if _G.Settings.ImageSettings.Invisible then
                Instance.Transparency = 1
            end
            if _G.Settings.ImageSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("ShirtGraphic") then
            if _G.Settings.ImageSettings.Invisible then
                Instance.Graphic = ""
            end
            if _G.Settings.ImageSettings.Destroy then
                Instance:Destroy()
            end
        elseif table.find(CanBeEnabled, Instance.ClassName) then
            if _G.Settings.ParticleSettings.Invisible then
                Instance.Enabled = false
            end
            if _G.Settings.ParticleSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("PostEffect") and _G.Settings.FPSBoostSettings["No Camera Effects"] then
            Instance.Enabled = false
        elseif Instance:IsA("Explosion") then
            if _G.Settings.ExplosionSettings.Smaller then
                Instance.BlastPressure = 1
                Instance.BlastRadius = 1
            end
            if _G.Settings.ExplosionSettings.Invisible then
                Instance.BlastPressure = 1
                Instance.BlastRadius = 1
                Instance.Visible = false
            end
            if _G.Settings.ExplosionSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("Clothing") and _G.Settings.FPSBoostSettings["No Clothes"] then
            Instance:Destroy()
        elseif Instance:IsA("BasePart") and not Instance:IsA("MeshPart") and _G.Settings.FPSBoostSettings["Low Quality Parts"] then
            Instance.Material = Enum.Material.Plastic
            Instance.Reflectance = 0
        elseif Instance:IsA("TextLabel") and Instance:IsDescendantOf(workspace) then
            if _G.Settings.TextLabelSettings.LowerQuality then
                Instance.Font = Enum.Font.SourceSans
                Instance.TextScaled = false
                Instance.RichText = false
                Instance.TextSize = 14
            end
            if _G.Settings.TextLabelSettings.Invisible then
                Instance.Visible = false
            end
            if _G.Settings.TextLabelSettings.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("MeshPart") then
            if _G.Settings.MeshPartSettings.LowerQuality then
                Instance.RenderFidelity = 2
                Instance.Reflectance = 0
                Instance.Material = Enum.Material.Plastic
            end
            if _G.Settings.MeshPartSettings.Invisible then
                Instance.Transparency = 1
            end
            if _G.Settings.MeshPartSettings.NoTexture then
                Instance.TextureID = ""
            end
            if _G.Settings.MeshPartSettings.NoMesh then
                Instance.MeshId = ""
            end
            if _G.Settings.MeshPartSettings.Destroy then
                Instance:Destroy()
            end
        end
    end
end

coroutine.wrap(pcall)(function()
    if _G.Settings.FPSBoostSettings["Low Water Graphics"] then
        if not workspace:FindFirstChildOfClass("Terrain") then
            repeat
                task.wait()
            until workspace:FindFirstChildOfClass("Terrain")
        end
        workspace:FindFirstChildOfClass("Terrain").WaterWaveSize = 0
        workspace:FindFirstChildOfClass("Terrain").WaterWaveSpeed = 0
        workspace:FindFirstChildOfClass("Terrain").WaterReflectance = 0
        workspace:FindFirstChildOfClass("Terrain").WaterTransparency = 0
        if sethiddenproperty then
            sethiddenproperty(workspace:FindFirstChildOfClass("Terrain"), "Decoration", false)
        else
            warn("Your exploit does not support sethiddenproperty, please use a different exploit.")
        end
        if _G.ConsoleLogs then
            warn("Low Water Graphics Enabled")
        end
    end
end)

coroutine.wrap(pcall)(function()
    if _G.Settings.FPSBoostSettings["No Shadows"] then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        if sethiddenproperty then
            sethiddenproperty(Lighting, "Technology", 2)
        else
            warn("Your exploit does not support sethiddenproperty, please use a different exploit.")
        end
        if _G.ConsoleLogs then
            warn("No Shadows Enabled")
        end
    end
end)

coroutine.wrap(pcall)(function()
    if _G.Settings.FPSBoostSettings["Low Rendering"] then
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        if _G.ConsoleLogs then
            warn("Low Rendering Enabled")
        end
    end
end)

coroutine.wrap(pcall)(function()
    if _G.Settings.FPSBoostSettings["Reset Materials"] then
        for i, v in pairs(MaterialService:GetChildren()) do
            v:Destroy()
        end
        MaterialService.Use2022Materials = false
        if _G.ConsoleLogs then
            warn("Reset Materials Enabled")
        end
    end
end)

coroutine.wrap(pcall)(function()
    if _G.Settings.FPSBoostSettings["FPS Cap"] then
        if setfpscap then
            if type(_G.Settings.FPSBoostSettings["FPS Cap"]) == "string" or type(_G.Settings.FPSBoostSettings["FPS Cap"]) == "number" then
                setfpscap(tonumber(_G.Settings.FPSBoostSettings["FPS Cap"]))
                if _G.ConsoleLogs then
                    warn("FPS Capped to " .. tostring(_G.Settings.FPSBoostSettings["FPS Cap"]))
                end
            elseif _G.Settings.FPSBoostSettings["FPS Cap"] == true then
                setfpscap(1e6)
                if _G.ConsoleLogs then
                    warn("FPS Uncapped")
                end
            end
        else
            warn("FPS Cap Failed")
        end
    end
end)

game.DescendantAdded:Connect(function(value)
    wait(_G.LoadedWait or 1)
    CheckIfBad(value)
end)

local Descendants = game:GetDescendants()
local StartNumber = _G.WaitPerAmount or 500
local WaitNumber = _G.WaitPerAmount or 500
if _G.ConsoleLogs then
    warn("Checking " .. #Descendants .. " Instances...")
end
for i, v in pairs(Descendants) do
    CheckIfBad(v)
    if i == WaitNumber then
        task.wait()
        if _G.ConsoleLogs then
            print("Loaded " .. i .. "/" .. #Descendants)
        end
        WaitNumber = WaitNumber + StartNumber
    end
end
warn("FPS Booster Loaded!")
--game.DescendantAdded:Connect(CheckIfBad)
--[[game.DescendantAdded:Connect(function(value)
    CheckIfBad(value)
end)]]
