-- VIEWMODEL INITIALIZER, UPDATER AND ANIMATION REPLICATOR
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local viewmodelController = require(replicatedStorage:WaitForChild("ViewmodelController"))

local loadedAnimations = {}

local updateConnection

local viewmodelanims = viewmodelController:init(character) -- intializes the viewmodel and returns a table having the vm's uneqip and idle anim
local viewmodelUnequipAnimation = viewmodelanims[1]
local viewmodelIdleAnimation = viewmodelanims[2]

viewmodelUnequipAnimation:Play()
viewmodelIdleAnimation:Play()

-- listen for animations played
-- check if animation can be played in a viewmodel, then it checks if it exists in the loadedAnimations table
-- create if otherwise
humanoid:WaitForChild("Animator").AnimationPlayed:Connect(function(animtrack)
	if not animtrack:GetAttribute("viewmodelplayable") then
		return
	end

	local tool = character:FindFirstChildWhichIsA("Tool")

	if not loadedAnimations[animtrack] and tool then
		local viewmodel = viewmodelController["viewmodel"]
		local animator = viewmodel:WaitForChild("AnimationController"):WaitForChild("Animator")

		loadedAnimations[animtrack] = animator:LoadAnimation(tool.ViewmodelAnimations[animtrack.Animation.Name])
	end
end)

-- make the tool invis for player
-- stop sole viewmodel animations
character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") and child:FindFirstChild("HandlePart") then
		task.delay(0.1, function() -- delaying cause the weapon animation looks weird without it 
			viewmodelUnequipAnimation:Stop()
			viewmodelIdleAnimation:Stop()
		end)

		for _, v in pairs(child:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Transparency = 1
			end
		end
	end
end)

-- if player is not holding a tool anymore, hide the vm
character.ChildRemoved:Connect(function()
	if not character:FindFirstChildWhichIsA("Tool") then
		viewmodelUnequipAnimation:Play()
		task.wait(0.2)
		viewmodelIdleAnimation:Play()
	end
end)

updateConnection = runService.RenderStepped:Connect(function(dt: number)
	-- update vm's state
	viewmodelController:update(dt, character)

	-- replicate character tool animations and viewmodel animations
	for characteranim, viewmodelanim in pairs(loadedAnimations) do
		if characteranim.IsPlaying ~= viewmodelanim.IsPlaying then
			if characteranim.IsPlaying then
				viewmodelanim:Play()
			else
				viewmodelanim:Stop()
			end
		end

		viewmodelanim.TimePosition = characteranim.TimePosition
		viewmodelanim:AdjustWeight(characteranim.WeightCurrent, 0)
	end

	-- localtransparencymodifying for legs
	-- for _, v in pairs(character:GetChildren()) do
	-- 	if v:IsA("BasePart") then
	-- 		if v.Name:match("Foot") or v.Name:match("Leg") then
	-- 			v.LocalTransparencyModifier = 0
	-- 		end
	-- 	end
	-- end
end)

humanoid.Died:Connect(function()
	viewmodelController:died()
	updateConnection:Disconnect()
end)
