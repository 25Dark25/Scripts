local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local espEnabled = true
local highlighted = {}
local connections = {}

-- Crear GUI
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "DarkGui"
screenGui.ResetOnSpawn = false

-- Main Frame
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 120)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -60)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

-- Botones
local closeButton = Instance.new("TextButton", mainFrame)
closeButton.Name = "CloseButton"
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(250, 0, 0)

local minimizeButton = Instance.new("TextButton", mainFrame)
minimizeButton.Name = "MinimizeButton"
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -70, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

local toggleESPButton = Instance.new("TextButton", mainFrame)
toggleESPButton.Name = "ToggleESPButton"
toggleESPButton.Text = "Desactivar ESP"
toggleESPButton.TextColor3 = Color3.new(1, 1, 1)
toggleESPButton.Size = UDim2.new(0.8, 0, 0, 40)
toggleESPButton.Position = UDim2.new(0.1, 0, 0.5, 0)
toggleESPButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

-- Minimized Bar
local minimizedBar = Instance.new("TextButton", screenGui)
minimizedBar.Name = "MinimizedBar"
minimizedBar.Text = "Dark"
minimizedBar.TextColor3 = Color3.new(1, 1, 1)
minimizedBar.Size = UDim2.new(0, 80, 0, 30)
minimizedBar.Position = UDim2.new(0.5, -40, 0, 10)
minimizedBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
minimizedBar.Visible = false

-- Highlight functions
local function addHighlight(character)
	if highlighted[character] or not espEnabled then return end
	local hl = Instance.new("Highlight")
	hl.Name = "ClientHighlight"
	hl.Adornee = character
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.OutlineColor = Color3.fromRGB(0, 255, 0)
	hl.Parent = character
	highlighted[character] = hl
end

local function removeHighlight(character)
	local hl = highlighted[character]
	if hl then
		hl:Destroy()
		highlighted[character] = nil
	end
end

local function onCharacterAdded(character)
	if espEnabled then
		addHighlight(character)
	end
	local humanoid = character:WaitForChild("Humanoid")
	table.insert(connections, humanoid.Died:Connect(function()
		removeHighlight(character)
	end))
end

local function onPlayerAdded(player)
	if player == LocalPlayer then return end
	table.insert(connections, player.CharacterAdded:Connect(onCharacterAdded))
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

-- Toggle ESP
local function toggleESP()
	espEnabled = not espEnabled
	toggleESPButton.Text = espEnabled and "Desactivar ESP" or "Activar ESP"
	if not espEnabled then
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

-- Shutdown y limpieza total
local function shutdown()
	espEnabled = false
	for _, conn in ipairs(connections) do
		if conn and typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	table.clear(connections)

	for char, hl in pairs(highlighted) do
		if hl then hl:Destroy() end
	end
	table.clear(highlighted)

	if screenGui then
		screenGui:Destroy()
	end
end

-- Botones GUI
table.insert(connections, closeButton.MouseButton1Click:Connect(shutdown))

table.insert(connections, minimizeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	minimizedBar.Visible = true
end))

table.insert(connections, minimizedBar.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	minimizedBar.Visible = false
end))

table.insert(connections, toggleESPButton.MouseButton1Click:Connect(toggleESP))

-- Start ESP
table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

-- Arrastrar MainFrame
local dragging, dragInput, dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

table.insert(connections, mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		table.insert(connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end))
	end
end))

table.insert(connections, mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end))

table.insert(connections, game:GetService("UserInputService").InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end))

-- Arrastrar MinimizedBar
local draggingMini, dragInputMini, dragStartMini, startPosMini

local function updateMini(input)
	local delta = input.Position - dragStartMini
	minimizedBar.Position = UDim2.new(
		startPosMini.X.Scale,
		startPosMini.X.Offset + delta.X,
		startPosMini.Y.Scale,
		startPosMini.Y.Offset + delta.Y
	)
end

table.insert(connections, minimizedBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingMini = true
		dragStartMini = input.Position
		startPosMini = minimizedBar.Position

		table.insert(connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingMini = false
			end
		end))
	end
end))

table.insert(connections, minimizedBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInputMini = input
	end
end))

table.insert(connections, game:GetService("UserInputService").InputChanged:Connect(function(input)
	if input == dragInputMini and draggingMini then
		updateMini(input)
	end
end))
