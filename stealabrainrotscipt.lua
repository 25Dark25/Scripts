-- Servicios
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables
local espEnabled = true
local aimbotEnabled = false
local ignoreTeammates = false
local aimbotKey = Enum.UserInputType.MouseButton2
local aimbotHold = false
local smoothing = 0.15
local fovRadius = 100

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DarkGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 300)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Redondear
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Funciones utiles
local function createTextLabel(text, pos)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0, 20)
    label.Position = pos
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Text = text
    label.Parent = mainFrame
end

local function createToggleButton(name, defaultText, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 0, 30)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    btn.Text = defaultText
    btn.TextColor3 = Color3.new(0, 0, 0)
    btn.Parent = mainFrame
    btn.MouseButton1Click:Connect(callback)
end

-- Minimize y cerrar
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeButton.Parent = mainFrame
closeButton.MouseButton1Click:Connect(function()
    espEnabled = false
    aimbotEnabled = false
    screenGui:Destroy()
end)

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -70, 0, 5)
minimizeButton.Text = "-"
minimizeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
minimizeButton.Parent = mainFrame

minimizeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    local mini = Instance.new("ImageButton")
    mini.Image = "rbxassetid://119268860825586"
    mini.Size = UDim2.new(0, 40, 0, 40)
    mini.Position = UDim2.new(0.5, -20, 0, 10)
    mini.BackgroundTransparency = 1
    mini.Active = true
    mini.Draggable = true
    mini.Parent = screenGui
    mini.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        mini:Destroy()
    end)
end)

-- Toggle buttons
createToggleButton("ESP", "Toggle ESP", UDim2.new(0.1, 0, 0.25, 0), function()
    espEnabled = not espEnabled
end)

createToggleButton("Teammates", "Toggle Ignore Teammates", UDim2.new(0.1, 0, 0.35, 0), function()
    ignoreTeammates = not ignoreTeammates
end)

createToggleButton("Aimbot", "Toggle Aimbot", UDim2.new(0.1, 0, 0.45, 0), function()
    aimbotEnabled = not aimbotEnabled
    fovCircle.Visible = aimbotEnabled
end)

-- Sliders (FOV & Suavizado)
local function createSlider(name, min, max, step, default, pos, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0, 20)
    label.Position = pos
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Text = name .. ": " .. default
    label.Parent = mainFrame

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(0.8, 0, 0, 20)
    slider.Position = pos + UDim2.new(0, 0, 0, 20)
    slider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    slider.Text = ""
    slider.Parent = mainFrame

    slider.MouseButton1Down:Connect(function()
        local moveConn, releaseConn
        moveConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local scale = (input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X
                scale = math.clamp(scale, 0, 1)
                local value = math.floor(((min + (max - min) * scale) / step) + 0.5) * step
                callback(value)
                label.Text = name .. ": " .. value
            end
        end)
        releaseConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                moveConn:Disconnect()
                releaseConn:Disconnect()
            end
        end)
    end)
end

createSlider("FOV", 50, 300, 10, fovRadius, UDim2.new(0.1, 0, 0.55, 0), function(val)
    fovRadius = val
    fovCircle.Radius = fovRadius
end)

createSlider("Smooth", 0.05, 1, 0.05, smoothing, UDim2.new(0.1, 0, 0.7, 0), function(val)
    smoothing = val
end)

-- Circulo Aimbot
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Thickness = 1
fovCircle.Radius = fovRadius
fovCircle.NumSides = 64
fovCircle.Transparency = 1
fovCircle.Visible = false
fovCircle.Filled = false

-- Highlight
local highlighted = {}

local function isVisible(character)
    if not character or not character:FindFirstChild("Head") then return false end
    local origin = Camera.CFrame.Position
    local direction = (character.Head.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, direction, params)
    return (not result or result.Instance:IsDescendantOf(character))
end

local function getClosestTarget()
    local closest, shortest = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if not ignoreTeammates or player.Team ~= LocalPlayer.Team then
                local head = player.Character.Head
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                if onScreen and isVisible(player.Character) and distance < fovRadius and distance < shortest then
                    closest = head
                    shortest = distance
                end
            end
        end
    end
    return closest
end

local function aimAtTarget(target)
    if not target then return end
    local screenPoint = Camera:WorldToViewportPoint(target.Position)
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local move = (Vector2.new(screenPoint.X, screenPoint.Y) - center) * smoothing
    mousemoverel(move.X, move.Y)
end

-- Input de Aimbot
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.UserInputType == aimbotKey then
        aimbotHold = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == aimbotKey then
        aimbotHold = false
    end
end)

-- Loop principal
RunService.RenderStepped:Connect(function()
    -- ESP
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not ignoreTeammates or player.Team ~= LocalPlayer.Team then
                    local character = player.Character
                    if not highlighted[character] then
                        local hl = Instance.new("Highlight")
                        hl.Name = "ClientHighlight"
                        hl.Adornee = character
                        hl.FillTransparency = 1
                        hl.OutlineTransparency = 0
                        hl.Parent = character
                        highlighted[character] = hl
                    end
                    local hl = highlighted[character]
                    hl.OutlineColor = isVisible(character) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end

    -- Aimbot
    if aimbotEnabled and aimbotHold then
        local target = getClosestTarget()
        aimAtTarget(target)
    end

    -- FOV circle position
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)
