local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local espEnabled = true
local ignoreTeammates = false
local highlighted = {}
local connections = {}

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DarkGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

-- Helper for buttons
local function createButton(parent, text, size, position, color)
    local btn = Instance.new("TextButton", parent)
    btn.Name = text:gsub("%s", "") .. "Button"
    btn.Size = size
    btn.Position = position
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundColor3 = color
    btn.AutoLocalize = false
    return btn
end

local closeButton = createButton(mainFrame, "X", UDim2.new(0, 30, 0, 30), UDim2.new(1, -35, 0, 5), Color3.fromRGB(255, 0, 0))
local minimizeButton = createButton(mainFrame, "-", UDim2.new(0, 30, 0, 30), UDim2.new(1, -70, 0, 5), Color3.fromRGB(200, 200, 200))
local toggleESPButton = createButton(mainFrame, "Disable ESP", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.45, 0), Color3.fromRGB(200, 200, 200))
local toggleTeamButton = createButton(mainFrame, "Ignore teammates: OFF", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.75, 0), Color3.fromRGB(200, 200, 200))

local minimizedBar = Instance.new("ImageButton", screenGui)
minimizedBar.Name = "MinimizedBar"
minimizedBar.Size = UDim2.new(0, 40, 0, 40)
minimizedBar.Position = UDim2.new(0.5, -20, 0, 10)
minimizedBar.BackgroundTransparency = 1
minimizedBar.Image = "rbxassetid://119268860825586"
minimizedBar.Visible = false
minimizedBar.AutoButtonColor = true

local corner = Instance.new("UICorner", minimizedBar)
corner.CornerRadius = UDim.new(1, 0)

-- Highlight management
local function removeHighlight(character)
    local hl = highlighted[character]
    if hl then
        hl:Destroy()
        highlighted[character] = nil
    end
end

local function addHighlight(character)
    if highlighted[character] or not espEnabled then return end
    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then return end
    if ignoreTeammates and player.Team == LocalPlayer.Team then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ClientHighlight"
    hl.Adornee = character
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(0, 255, 0)
    hl.Parent = character
    highlighted[character] = hl
end

local function refreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            removeHighlight(player.Character)
            addHighlight(player.Character)
        end
    end
end

local function onCharacterAdded(character)
    if espEnabled then
        addHighlight(character)
    end
    character:WaitForChild("Humanoid").Died:Connect(function()
        removeHighlight(character)
    end)
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    table.insert(connections, player.CharacterAdded:Connect(onCharacterAdded))
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

-- Main toggle logic
local function toggleESP()
    espEnabled = not espEnabled
    toggleESPButton.Text = espEnabled and "Disable ESP" or "Enable ESP"
    if espEnabled then
        refreshESP()
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                removeHighlight(player.Character)
            end
        end
    end
end

local function cleanup()
    espEnabled = false
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            removeHighlight(player.Character)
        end
    end
    for _, conn in ipairs(connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    connections = {}
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
end

-- Button logic
closeButton.MouseButton1Click:Connect(cleanup)
minimizeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    minimizedBar.Visible = true
end)
minimizedBar.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    minimizedBar.Visible = false
end)
toggleESPButton.MouseButton1Click:Connect(toggleESP)
toggleTeamButton.MouseButton1Click:Connect(function()
    ignoreTeammates = not ignoreTeammates
    toggleTeamButton.Text = ignoreTeammates and "Ignore teammates: ON" or "Ignore teammates: OFF"
    if espEnabled then
        refreshESP()
    end
end)

-- Connect all current and future players
table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end

-- Make GUI draggable
local function makeDraggable(frame)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(mainFrame)
makeDraggable(minimizedBar)
