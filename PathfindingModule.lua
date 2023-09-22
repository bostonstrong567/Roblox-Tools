local PathfindingModule = {}

local pathfinding = loadstring(game:HttpGet("https://raw.githubusercontent.com/Blissful4992/pathfinding/main/pathfinding_heap.lua"))()
local mapping = loadstring(game:HttpGet("https://raw.githubusercontent.com/Blissful4992/pathfinding/main/mapping.lua"))()

local V3, CF = Vector3.new, CFrame.new
local Params = RaycastParams.new()
Params.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
Params.FilterType = Enum.RaycastFilterType.Blacklist

local function createPart(name, pos, color, size)
    local World_Points = workspace:FindFirstChild("_Points") or Instance.new("Folder", workspace)
    World_Points.Name = "_Points"

    local p = Instance.new("Part", World_Points)
    p.Name = name
    p.CanCollide = false
    p.Anchored = true
    p.Color = color
    p.Position = pos
    p.Size = size
    return p
end

local function newLine(info)
    local Lines_Folder = workspace:FindFirstChild("_Lines") or Instance.new("Folder", workspace)
    Lines_Folder.Name = "_Lines"

    local PointA, PointB = info.PointA or V3(0,0,0), info.PointB or V3(0,0,0)
    local Line = Instance.new("Part", Lines_Folder)
    Line.TopSurface = Enum.SurfaceType.Smooth
    Line.Color = info.Color or Color3.fromRGB(0, 255, 0)
    Line.Anchored = true
    Line.CanCollide = false
    Line.Transparency = 0.4
    Line.Material = Enum.Material.Neon
    Line.Name = "Path"

    local magnitude = (PointA - PointB).magnitude
    Line.Size = V3(info.Thickness, info.Thickness, magnitude)
    Line.CFrame = CF(PointA:Lerp(PointB, 0.5), PointB)
    return Line
end

function PathfindingModule.GoToPart(model, Visualization, TimeItTakes)
    local Player = game.Players.LocalPlayer
    local Root = Player.Character.HumanoidRootPart.CFrame
    local Start = (Root * CF(0, -2, 0)).p
    local End = model:IsA("Model") and model.PrimaryPart.Position or model.Position

    if Visualization then
        createPart("Start", Start, Color3.fromRGB(0,255,0), V3(0.5,0.5,0.5))
        createPart("End", End, Color3.fromRGB(255,0,0), V3(0.5,0.5,0.5))
    end

    local MAP = mapping:createMap(Root.p+V3(-100, 0, -100), Root.p+V3(100, 0, 100), V3(1,1,1), 5, Params)

    local startTime = TimeItTakes and os.clock() or nil
    local Path = pathfinding:getPath(MAP, Start, End, V3(1,1,1), true)

    if TimeItTakes then
        warn("Time taken for pathfinding: ", os.clock() - startTime)
    end

    if Visualization then
        local previous = Path[1]
        for _, node in next, Path do
            newLine({
                PointA = previous,
                PointB = node,
                Thickness = 0.15,
                Color = Color3.fromRGB(255, 0, 255)
            })
            previous = node
        end
    end

    for _, p in next, Path do
        Player.Character.Humanoid:MoveTo(p)
        Player.Character.Humanoid.MoveToFinished:Wait()
    end
end

return PathfindingModule
