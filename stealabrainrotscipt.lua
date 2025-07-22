local gui = script.Parent
local mainFrame = gui:WaitForChild("MainFrame")
local closeButton = mainFrame:WaitForChild("CloseButton")
local minimizeButton = mainFrame:WaitForChild("MinimizeButton")
local toggleESPButton = mainFrame:WaitForChild("ToggleESPButton")
local minimizedBar = gui:WaitForChild("MinimizedBar")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local highlighted = {}
local espEnabled = true

local function addHighlight(character)
	if not character or highlighted[character] then return end
	local hl = Instance.new("Highlight")
	hl.Name = "ClientHighlight"
	hl.Adornee = character
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.OutlineColor = Color3.fromRGB(0, 255, 0)
	hl.Parent = LocalPlayer:WaitForChild("PlayerGui")
	highlighted[character] = hl
end

-- Remover Highlight
local function removeHighlight(character)
	local hl = highlighted[character]
	if hl then
		hl:Destroy()
		highlighted[character] = nil
	end
end

local function onCharacterAdded(character)
	if not espEnabled then return end
	addHighlight(character)
	local humano = character:WaitForChild("Humanoid")
	humano.Died:Connect(function()
		removeHighlight(character)
	end)
end

local function onPlayerAdded(player)
	if player == LocalPlayer then return end
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

local function toggleESP()
	espEnabled = not espEnabled
	toggleESPButton.Text = espEnabled and "Desactivar ESP" or "Activar ESP"
	if not espEnabled then
		-- Eliminar todos los highlights
		for char, _ in pairs(highlighted) do
			removeHighlight(char)
		end
	else
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				addHighlight(p.Character)
			end
		end
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	minimizedBar.Visible = false
end)

minimizeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	minimizedBar.Visible = true
end)

minimizedBar.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	minimizedBar.Visible = false
end)

toggleESPButton.MouseButton1Click:Connect(toggleESP)
