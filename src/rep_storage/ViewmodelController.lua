-- efficiency is key

local module = {}

function module:init(character: Model): table
	local replicated_Storage = game:GetService("ReplicatedStorage")

	local springModule = require(replicated_Storage:WaitForChild("Spring"))

	local viewmodel_clone = replicated_Storage:WaitForChild("Viewmodel"):Clone()

	local body_colors = character:FindFirstChildWhichIsA("BodyColors")
	if body_colors then
		viewmodel_clone.LeftArm.Color = body_colors.LeftArmColor3
		viewmodel_clone.RightArm.Color = body_colors.RightArmColor3
	end

	viewmodel_clone.Parent = game.Workspace.CurrentCamera

	self.viewmodel = viewmodel_clone
	self.weapons = {}

	self.recoilSpring = springModule.new()
	self.bobble = springModule.new()
	self.sway = springModule.new()
	self.breath = springModule.new()

	-- returning two loaded sole-viewmodel animations
	local animator = viewmodel_clone:WaitForChild("AnimationController"):WaitForChild("Animator")
	return {
		animator:LoadAnimation(viewmodel_clone:WaitForChild("UnequipAnimation")),
		animator:LoadAnimation(viewmodel_clone:WaitForChild("IdleAnimation")),
	}
end

function module:update(dt: number, char: Model)
	local model = self.viewmodel
	local camera = game.Workspace.CurrentCamera

	model.HumanoidRootPart.CFrame = camera.CFrame

	local bobbleVector = Vector3.new(self:viewBobbing(10), self:viewBobbing(5), self:viewBobbing(5))
	local delta = game:GetService("UserInputService"):GetMouseDelta()

	self.bobble:shove(bobbleVector / 10 * (char.HumanoidRootPart.Velocity.Magnitude / 40))
	self.sway:shove(Vector3.new(-delta.X / 1000, delta.Y / 1000, 0))

	local recoilUpdate = self.recoilSpring:update(dt)
	local updatebob = self.bobble:update(dt)
	local swayUpdate = self.sway:update(dt)

	model.HumanoidRootPart.CFrame = model.HumanoidRootPart.CFrame:ToWorldSpace(CFrame.new(updatebob.Y, updatebob.X, 0)) -- view bobbing
	model.HumanoidRootPart.CFrame *= CFrame.new(swayUpdate.X, swayUpdate.Y, 0) -- swaying
	model.HumanoidRootPart.CFrame *= CFrame.Angles(math.rad(recoilUpdate.X) * 1, 0, 0) -- camera
	camera.CFrame *= CFrame.Angles(math.rad(recoilUpdate.X), math.rad(recoilUpdate.Y), math.rad(recoilUpdate.Z)) -- recoil

	if char.Humanoid.MoveDirection.Magnitude <= 0 then -- perform the idle breath "animation"
		local breathVector = Vector3.new(self:idleBreathing()[1], self:idleBreathing()[2], 0) -- (x, y)
		self.breath:shove(breathVector / 30)
	end

	local breathUpdate = self.breath:update(dt)
	model.HumanoidRootPart.CFrame =
		model.HumanoidRootPart.CFrame:ToWorldSpace(CFrame.new(breathUpdate.X, breathUpdate.Y, 0)) -- idle breath
end

function module:equip(tool: Tool)
	if not self.weapons[tool] then
		print("creating viewmodel tool")
		self:__convertTooltoModel(tool)
		self:__setupViewmodelWeapon(tool)
	end

	local viewmodel = self.viewmodel
	local handle_m6d = viewmodel:WaitForChild("HumanoidRootPart"):FindFirstChild("HandlePart")

	local weapon = self.weapons[tool]
	local weapon_handle = weapon.HandlePart

	handle_m6d.Part1 = weapon_handle
	weapon.Parent = viewmodel
end

function module:unequip(tool: Tool)
	local weapon = self.weapons[tool]
	local viewmodel = self.viewmodel
	local handle_m6d = viewmodel:WaitForChild("HumanoidRootPart"):FindFirstChild("HandlePart")

	handle_m6d.Part1 = nil
	weapon.Parent = nil
end

function module:died()
	self.viewmodel:Destroy()
end

-- function module.playCameraAnimation(folder: Folder)
-- 	local camera = game.Workspace.CurrentCamera
-- 	local ogCframe = camera.CFrame

-- 	local runService = game:GetService("RunService")

-- 	local connection
-- 	local frame = 0

-- 	connection = runService.RenderStepped:Connect(function(deltaTime)
-- 		local cframevalue = folder.Frames:FindFirstChild(math.floor(frame))

-- 		if cframevalue then
-- 			camera.CFrame = cframevalue.Value
-- 		else
-- 			connection:Disconnect()
-- 			camera.CFrame = ogCframe
-- 		end

-- 		frame += deltaTime * 60
-- 	end)
-- end

function module:viewBobbing(addition: number): number
	return math.sin(tick() * addition * 1.3) * 0.5
end

function module:idleBreathing(): table
	return { 0.2 * math.sin(tick()), math.cos(2 * tick() + 0.5) } -- (x , y)
end

function module:__convertTooltoModel(tool: Tool)
	if not self.weapons[tool] then
		local model = Instance.new("Model")
		model.Name = tool.Name .. "Viewmodel"

		for _, v in pairs(tool:GetChildren()) do
			if not v:IsA("BaseScript") then
				v:Clone().Parent = model
			end
		end

		self.weapons[tool] = model
	end
end

function module:__setupViewmodelWeapon(tool: Tool)
	local model = self.weapons[tool]
	local handlepart = model:FindFirstChild("HandlePart")

	if model and handlepart then
		for _, v in pairs(model:GetDescendants()) do
			if v:IsA("BasePart") and v ~= handlepart then
				v.Transparency = 0

				local m6d = Instance.new("Motor6D")
				m6d.Name = "HandlePart -->" .. v.Name
				m6d.Part0 = handlepart
				m6d.Part1 = v
				m6d.C0 = m6d.Part0.CFrame:Inverse() * m6d.Part1.CFrame
				m6d.Parent = handlepart
			elseif v:IsA("Weld") or v:IsA("WeldConstraint") then
				v:Destroy()
			end
		end
	else
		error("The tool or the 'HandlePart' was not found")
	end
end

return module
