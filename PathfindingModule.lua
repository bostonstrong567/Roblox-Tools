local pathfind = {}
local human = game.Players.LocalPlayer.Character.Humanoid
local Body = game.Players.LocalPlayer.Character.HumanoidRootPart
pathfind.Destination = nil
local path = game:GetService("PathfindingService"):CreatePath()
pathfind.path:ComputeAsync(Body.Position, pathfind.Destination.Position)
if path.Status == Enum.PathStatus.Success then
   local wayPoints = path:GetWaypoints()
   for i = 1, #wayPoints do
       local point = wayPoints[i]
       human:MoveTo(point.Position)
       local success = human.MoveToFinished:Wait()
       if point.Action == Enum.PathWaypointAction.Jump then
           human.WalkSpeed = 0
           wait(0.2)
           human.WalkSpeed = 16
           human.Jump = true
       end
       if not success then
           print("trying again")
           human.Jump = true
           human:MoveTo(point.Position)
           if not human.MoveToFinished:Wait() then
               break
           end
       end
   end
end
