game.Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		local m6d = Instance.new("Motor6D")
		m6d.Name = "HandlePart"
		m6d.Parent = char

		char.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and child:FindFirstChild("HandlePart") then
				m6d.Part0 = char.UpperTorso
				m6d.Part1 = child.HandlePart
			end
		end)

		char.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child:FindFirstChild("HandlePart") then
				m6d.Part1 = nil
			end
		end)
	end)
end)
