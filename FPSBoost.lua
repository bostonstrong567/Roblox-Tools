local settings = {}
function settings:returnSettings(Settings)
    if not _G.Ignore then
        _G.Ignore = {}
    end
    if not _G.WaitPerAmount then
        _G.WaitPerAmount = 500
    end
    if _G.ConsoleLogs == nil then
        _G.ConsoleLogs = false
    end
    if not game:IsLoaded() then
        repeat
            task.wait()
        until game:IsLoaded()
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
        if not Instance:IsDescendantOf(Players) and (Settings.PlayerSettings["Ignore Others"] and not PartOfCharacter(Instance) or not Settings.PlayerSettings["Ignore Others"]) and (Settings.PlayerSettings["Ignore Me"] and ME.Character and not Instance:IsDescendantOf(ME.Character) or not Settings.PlayerSettings["Ignore Me"]) and (Settings.PlayerSettings["Ignore Tools"] and not Instance:IsA("BackpackItem") and not Instance:FindFirstAncestorWhichIsA("BackpackItem") or not Settings.PlayerSettings["Ignore Tools"]) and (not DescendantOfIgnore(Instance)) then
            if Instance:IsA("DataModelMesh") then
                if Settings.MeshSettings.NoMesh and Instance:IsA("SpecialMesh") then
                    Instance.MeshId = ""
                end
                if Settings.MeshSettings.NoTexture and Instance:IsA("SpecialMesh") then
                    Instance.TextureId = ""
                end
                if Settings.MeshSettings.Destroy then
                    Instance:Destroy()
                end
            elseif Instance:IsA("FaceInstance") then
                if Settings.ImageSettings.Invisible then
                    Instance.Transparency = 1
                end
                if Settings.ImageSettings.Destroy then
                    Instance:Destroy()
                end
            elseif Instance:IsA("ShirtGraphic") then
                if Settings.ImageSettings.Invisible then
                    Instance.Graphic = ""
                end
                if Settings.ImageSettings.Destroy then
                    Instance:Destroy()
                end
            elseif table.find(CanBeEnabled, Instance.ClassName) then
                if Settings.ParticleSettings.Invisible then
                    Instance.Enabled = false
                end
                if Settings.ParticleSettings.Destroy then
                    Instance:Destroy()
                end
            elseif Instance:IsA("PostEffect") and Settings.FPSBoostSettings["No Camera Effects"] then
                Instance.Enabled = false
            elseif Instance:IsA("Explosion") then
                if Settings.ExplosionSettings.Smaller then
                    Instance.BlastPressure = 1
                    Instance.BlastRadius = 1
                end
                if Settings.ExplosionSettings.Invisible then
                    Instance.BlastPressure = 1
                    Instance.BlastRadius = 1
                    Instance.Visible = false
                end
                if Settings.ExplosionSettings.Destroy then
                    Instance:Destroy()
                end
            elseif Instance:IsA("Clothing") and Settings.FPSBoostSettings["No Clothes"] then
                Instance:Destroy()
            elseif Instance:IsA("BasePart") and not Instance:IsA("MeshPart") and Settings.FPSBoostSettings["Low Quality Parts"] then
                Instance.Material = Enum.Material.Plastic
                Instance.Reflectance = 0
            elseif Instance:IsA("TextLabel") and Instance:IsDescendantOf(workspace) then
                if Settings.TextLabelSettings.LowerQuality then
                    Instance.Font = Enum.Font.SourceSans
                    Instance.TextScaled = false
                    Instance.RichText = false
                    Instance.TextSize = 14
                end
                if Settings.TextLabelSettings.Invisible then
                    Instance.Visible = false
                end
                if Settings.TextLabelSettings.Destroy then
                    Instance:Destroy()
                end
            elseif Instance:IsA("MeshPart") then
                if Settings.MeshPartSettings.LowerQuality then
                    Instance.RenderFidelity = 2
                    Instance.Reflectance = 0
                    Instance.Material = Enum.Material.Plastic
                end
                if Settings.MeshPartSettings.Invisible then
                    Instance.Transparency = 1
                end
                if Settings.MeshPartSettings.NoTexture then
                    Instance.TextureID = ""
                end
                if Settings.MeshPartSettings.NoMesh then
                    Instance.MeshId = ""
                end
                if Settings.MeshPartSettings.Destroy then
                    Instance:Destroy()
                end
            end
        end
    end
    coroutine.wrap(pcall)(function()
        if Settings.FPSBoostSettings["Low Water Graphics"] then
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
        if Settings.FPSBoostSettings["No Shadows"] then
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
        if Settings.FPSBoostSettings["Low Rendering"] then
            settings().Rendering.QualityLevel = 1
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
            if _G.ConsoleLogs then
                warn("Low Rendering Enabled")
            end
        end
    end)
    coroutine.wrap(pcall)(function()
        if Settings.FPSBoostSettings["Reset Materials"] then
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
        if Settings.FPSBoostSettings["FPS Cap"] then
            if setfpscap then
                if type(Settings.FPSBoostSettings["FPS Cap"]) == "string" or type(Settings.FPSBoostSettings["FPS Cap"]) == "number" then
                    setfpscap(tonumber(Settings.FPSBoostSettings["FPS Cap"]))
                    if _G.ConsoleLogs then
                        warn("FPS Capped to " .. tostring(Settings.FPSBoostSettings["FPS Cap"]))
                    end
                elseif Settings.FPSBoostSettings["FPS Cap"] == true then
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
end
