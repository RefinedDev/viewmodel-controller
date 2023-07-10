local replicatedStorage = game:GetService("ReplicatedStorage")

local player = game.Players.LocalPlayer

local animations = {}
local loaded = false

local viewmodelController = require(replicatedStorage:WaitForChild("ViewmodelController"))

local raycastHitbox = require(replicatedStorage:WaitForChild("RaycastHitboxV4"))
local hitbox = raycastHitbox.new(script.Parent:WaitForChild("Wood"))
hitbox.Visualizer = false

local ray_params = RaycastParams.new()
ray_params.FilterType = Enum.RaycastFilterType.Exclude

hitbox.RaycastParams = ray_params

script.Parent.Equipped:Connect(function()
	if not loaded then
		local character = player.Character or player.CharacterAdded:Wait()
		local animator = character:WaitForChild("Humanoid"):WaitForChild("Animator")
		local toolAnims = script.Parent:WaitForChild("ToolAnimations")

		animations["idle"] = animator:LoadAnimation(toolAnims.Idle)
		animations["equip"] = animator:LoadAnimation(toolAnims.Equip)

		for _, v in pairs(animations) do
			v:SetAttribute("viewmodelplayable", true)
		end

		ray_params.FilterDescendantsInstances = { character }

		loaded = true
	end

	animations["equip"]:Play()
	viewmodelController:equip(script.Parent)
	task.wait(0.2)
	animations["idle"]:Play()
end)

script.Parent.Unequipped:Connect(function()
	for _, v in pairs(animations) do
		v:Stop()
	end

	viewmodelController:unequip(script.Parent)
end)

script.Parent.Activated:Connect(function()
	hitbox:HitStart()
	script.Parent.Wood.Trail.Enabled = true
	wait(3)
	hitbox:HitStop()
	script.Parent.Wood.Trail.Enabled = false
end)

hitbox.OnHit:Connect(function(_hit, humanoid)
	humanoid:TakeDamage(25)
end)
