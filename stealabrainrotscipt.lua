local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera


local espEnabled = true
local ignoreTeammates = false
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
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

-- Buttons helper function
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

-- Minimized Bar (ImageButton with logo)
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

local function addHighlight(character)
    if highlighted[character] or not espEnabled then return end
    local player = Players:GetPlayerFromCharacter(character)
    if not player or (ignoreTeammates and player.Team == LocalPlayer.Team) then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ClientHighlight"
    hl.Adornee = character
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.Parent = character
    highlighted[character] = hl
end

local function isVisible(character)
    if not character or not character:FindFirstChild("Head") then return false end

    local head = character.Head
    local origin = Camera.CFrame.Position
    local direction = (head.Position - origin).Unit * (head.Position - origin).Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction, raycastParams)
    return (not result or result.Instance:IsDescendantOf(character))
end


local function updateHighlightColors()
    for character, hl in pairs(highlighted) do
        if character and hl and character:FindFirstChild("Head") then
            if isVisible(character) then
                if hl.OutlineColor ~= Color3.fromRGB(0, 255, 0) then
                    hl.OutlineColor = Color3.fromRGB(0, 255, 0) -- Verde si visible
                end
            else
                if hl.OutlineColor ~= Color3.fromRGB(255, 0, 0) then
                    hl.OutlineColor = Color3.fromRGB(255, 0, 0) -- Rojo si oculto
                end
            end
        end
    end
end



local function removeHighlight(character)
    local hl = highlighted[character]
    if hl then
        hl:Destroy()
        highlighted[character] = nil
    end
end

local function onCharacterAdded(character)
    -- Esperar que humanoide exista
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    -- Añadir highlight si ESP está activado
    if espEnabled then
        addHighlight(character)
    end

    -- Cuando el humanoide muere, quitar highlight
    humanoid.Died:Connect(function()
        removeHighlight(character)
    end)
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end

    -- Cuando el personaje se añade
    player.CharacterAdded:Connect(onCharacterAdded)

    -- Si el personaje ya existe al momento de unirse
    if player.Character then
        onCharacterAdded(player.Character)
    end

    -- Opcional: refrescar ESP si el jugador cambia de equipo
    player:GetPropertyChangedSignal("Team"):Connect(function()
        if espEnabled then
            refreshESP()
        end
    end)
end

local function refreshESP()
    -- Limpiar todos los highlights actuales
    for char in pairs(highlighted) do
        removeHighlight(char)
    end
    -- Re-agregar highlights solo a los personajes que cumplen condición
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            addHighlight(p.Character)
        end
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
toggleTeamButton.MouseButton1Click:Connect(function()
    ignoreTeammates = not ignoreTeammates
    toggleTeamButton.Text = ignoreTeammates and "Ignore teammates: ON" or "Ignore teammates: OFF"
    toggleESP()
    toggleESP()
end)

-- Connect players
table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end

-- Make draggable
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

-- Optimización: actualización del color ESP cada 0.2s en lugar de cada frame
task.spawn(function()
    while true do
        task.wait(0.2)
        if espEnabled then
            updateHighlightColors()
        end
    end
end)


makeDraggable(mainFrame)
makeDraggable(minimizedBar)
