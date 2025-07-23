local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local espEnabled = true
local highlighted = {}
local connections = {}

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DarkGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 120)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -60)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

-- Buttons helper function
local function createButton(parent, text, size, position, color)
    local btn = Instance.new("TextButton", parent)
    btn.Name = text:gsub("%s", "") .. "Button"
    btn.Size = size
    btn.Position = position
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(0, 0, 0) -- en vez de blanco
    btn.BackgroundColor3 = color
    btn.AutoLocalize = false
    return btn
end

local closeButton = createButton(mainFrame, "X", UDim2.new(0, 30, 0, 30), UDim2.new(1, -35, 0, 5), Color3.fromRGB(255, 0, 0))
local minimizeButton = createButton(mainFrame, "-", UDim2.new(0, 30, 0, 30), UDim2.new(1, -70, 0, 5), Color3.fromRGB(200, 200, 200))
local toggleESPButton = createButton(mainFrame, "Disable ESP", UDim2.new(0.8, 0, 0, 40), UDim2.new(0.1, 0, 0.5, 0), Color3.fromRGB(200, 200, 200))

local minimizedBar = createButton(screenGui, "Dark", UDim2.new(0, 80, 0, 30), UDim2.new(0.5, -40, 0, 10), Color3.fromRGB(40, 40, 40))
minimizedBar.Visible = false
minimizedBar.AutoLocalize = false

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
    character:WaitForChild("Humanoid").Died:Connect(function()
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
    toggleESPButton.Text = espEnabled and "Disable ESP" or "Enable ESP"
    if not espEnabled then
        for char in pairs(highlighted) do
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

-- Cleanup function to remove GUI and disconnect events
local function cleanup()
    espEnabled = false
    for char in pairs(highlighted) do
        removeHighlight(char)
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

-- Connect players
table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end

-- Drag function reusable
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
