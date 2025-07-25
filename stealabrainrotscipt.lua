local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local espEnabled = true
local aimbotEnabled = false
local ignoreTeammates = false
local aimbotKey = Enum.UserInputType.MouseButton2
local aimbotHold = false
local smoothing = 0.15
local fovRadius = 100

local highlighted = {}
local connections = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DarkGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.DisplayOrder = 10000

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 250)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local minimized = false
local savedPosition = mainFrame.Position

local logoImage = Instance.new("ImageButton")
logoImage.Name = "LogoImage"
logoImage.Size = UDim2.new(0, 50, 0, 50)
local savedPosition = UDim2.new(0.5, -25, 0.5, -25)
logoImage.BackgroundTransparency = 1
logoImage.Image = "rbxassetid://119268860825586"
logoImage.Visible = false
logoImage.Parent = screenGui
logoImage.ZIndex = 999999

local logoUICorner = Instance.new("UICorner")
logoUICorner.CornerRadius = UDim.new(1, 0)
logoUICorner.Parent = logoImage

local dragging, offset
logoImage.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        offset = Vector2.new(logoImage.Size.X.Offset, logoImage.Size.Y.Offset) / 2
    end
end)


UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        savedPosition = logoImage.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        logoImage.Position = UDim2.new(0, input.Position.X - offset.X, 0, input.Position.Y - offset.Y)
    end
end)

local draggingMain, dragInput, startPos, dragStart
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMain = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMain = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingMain and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

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

local closeButton = createButton(mainFrame, "X", UDim2.new(0, 30, 0, 20), UDim2.new(1, -35, 0, 5), Color3.fromRGB(255, 0, 0))
local minimizeButton = createButton(mainFrame, "-", UDim2.new(0, 30, 0, 20), UDim2.new(1, -70, 0, 5), Color3.fromRGB(200, 200, 200))
local toggleESPButton = createButton(mainFrame, "Disable ESP", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.30, 0), Color3.fromRGB(200, 200, 200))
local toggleTeamButton = createButton(mainFrame, "Ignore teammates: OFF", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.50, 0), Color3.fromRGB(200, 200, 200))
local toggleAimbotButton = createButton(mainFrame, "Enable Aimbot", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.70, 0), Color3.fromRGB(200, 200, 200))
local aimbotKeyButton = createButton(mainFrame, "Change Aimbot Key", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.90, 0), Color3.fromRGB(100, 100, 255))

minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    mainFrame.Visible = not minimized
    logoImage.Visible = minimized
    logoImage.Position = savedLogoPosition
end)

logoImage.MouseButton1Click:Connect(function()
    minimized = false
    logoImage.Visible = false
    mainFrame.Visible = true
end)

local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Thickness = 1
fovCircle.Radius = fovRadius
fovCircle.NumSides = 64
fovCircle.Transparency = 1
fovCircle.Visible = false
fovCircle.Filled = false

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

local function removeHighlight(character)
    local hl = highlighted[character]
    if hl then
        hl:Destroy()
        highlighted[character] = nil
    end
end

local function isVisible(character)
    if not character or not character:FindFirstChild("Head") then return false end
    local origin = Camera.CFrame.Position
    local direction = (character.Head.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, direction, params)
    return (not result or result.Instance:IsDescendantOf(character))
end

local function updateHighlightColors()
    for character, hl in pairs(highlighted) do
        if character and hl and character:FindFirstChild("Head") then
            if isVisible(character) then
                hl.OutlineColor = Color3.fromRGB(0, 255, 0)
            else
                hl.OutlineColor = Color3.fromRGB(255, 0, 0)
            end
        end
    end
end

local function refreshESP()
    for char in pairs(highlighted) do
        removeHighlight(char)
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            addHighlight(p.Character)
        end
    end
end

local function getClosestTarget()
    local closest = nil
    local shortest = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if not ignoreTeammates or player.Team ~= LocalPlayer.Team then
                local head = player.Character.Head
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen and isVisible(player.Character) then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                    if distance < fovRadius and distance < shortest then
                        closest = head
                        shortest = distance
                    end
                end
            end
        end
    end
    return closest
end

local function aimAtTarget(target)
    if not target then return end
    local screenPoint = Camera:WorldToViewportPoint(target.Position)
    local mousePos = UserInputService:GetMouseLocation()
    local aimPos = Vector2.new(screenPoint.X, screenPoint.Y)
    local move = (aimPos - Vector2.new(mousePos.X, mousePos.Y)) * smoothing
    mousemoverel(move.X, move.Y)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == aimbotKey then
        aimbotHold = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == aimbotKey then
        aimbotHold = false
    end
end)

closeButton.MouseButton1Click:Connect(function()
    espEnabled = false
    aimbotEnabled = false
    for char in pairs(highlighted) do removeHighlight(char) end
    for _, conn in ipairs(connections) do if conn.Connected then conn:Disconnect() end end
    screenGui:Destroy()
end)

toggleESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    toggleESPButton.Text = espEnabled and "Disable ESP" or "Enable ESP"
    refreshESP()
end)

toggleTeamButton.MouseButton1Click:Connect(function()
    ignoreTeammates = not ignoreTeammates
    toggleTeamButton.Text = ignoreTeammates and "Ignore teammates: ON" or "Ignore teammates: OFF"
    refreshESP()
end)

toggleAimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    fovCircle.Visible = aimbotEnabled
    toggleAimbotButton.Text = aimbotEnabled and "Disable Aimbot" or "Enable Aimbot"
end)

aimbotKeyButton.MouseButton1Click:Connect(function()
    aimbotKeyButton.Text = "Press new key..."
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType.Name:match("Mouse") then
            aimbotKey = input.UserInputType
            aimbotKeyButton.Text = "Aimbot Key: " .. input.UserInputType.Name
            conn:Disconnect()
        end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(char)
            wait(1)
            if espEnabled then addHighlight(char) end
        end)
        if player.Character then
            addHighlight(player.Character)
        end
    end
end

local lastColorUpdate = 0
local colorUpdateInterval = 0.05 

RunService.RenderStepped:Connect(function(dt)
    if espEnabled then
        lastColorUpdate = lastColorUpdate + dt
        if lastColorUpdate >= colorUpdateInterval then
            lastColorUpdate = 0
            updateHighlightColors()
        end
    end

    if aimbotEnabled and aimbotHold then
        local target = getClosestTarget()
        aimAtTarget(target)
    end

    local viewportSize = Camera.ViewportSize
    fovCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    fovCircle.Radius = fovRadius
end)
