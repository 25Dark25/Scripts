-- SERVICIOS Y VARIABLES PRINCIPALES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ESTADOS
local espEnabled = true
local aimbotEnabled = false
local ignoreTeammates = false
local aimbotKey = Enum.UserInputType.MouseButton2
local aimbotHold = false
local smoothing = 0.15
local fovRadius = 100

-- TRACKING
local highlighted = {}
local connections = {}

-- GUI PRINCIPAL
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DarkGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.DisplayOrder = 10000

-- FRAME PRINCIPAL
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 250)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
mainFrame.Draggable = true

-- FUNCION PARA CREAR BOTONES
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

-- BOTONES DE CONTROL
local closeButton = createButton(mainFrame, "X", UDim2.new(0, 30, 0, 30), UDim2.new(1, -35, 0, 5), Color3.fromRGB(255, 0, 0))
local minimizeButton = createButton(mainFrame, "-", UDim2.new(0, 30, 0, 30), UDim2.new(1, -70, 0, 5), Color3.fromRGB(200, 200, 200))
local toggleESPButton = createButton(mainFrame, "Disable ESP", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.25, 0), Color3.fromRGB(200, 200, 200))
local toggleTeamButton = createButton(mainFrame, "Ignore teammates: OFF", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.40, 0), Color3.fromRGB(200, 200, 200))
local toggleAimbotButton = createButton(mainFrame, "Enable Aimbot", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.55, 0), Color3.fromRGB(200, 200, 200))
local aimbotKeyButton = createButton(mainFrame, "Change Aimbot Key", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.70, 0), Color3.fromRGB(100, 100, 255))

-- NUEVOS SLIDERS PARA FOV Y SMOOTHING
local fovSlider = createButton(mainFrame, "FOV: 100", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.85, 0), Color3.fromRGB(180, 180, 180))
local smoothSlider = createButton(mainFrame, "Smooth: 0.15", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 1.00, 0), Color3.fromRGB(180, 180, 180))

-- CÍRCULO DE FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Thickness = 1
fovCircle.Radius = fovRadius
fovCircle.NumSides = 64
fovCircle.Transparency = 1
fovCircle.Visible = false
fovCircle.Filled = false
fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- FUNCIONES
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

-- EVENTOS
fovSlider.MouseButton1Click:Connect(function()
    fovRadius = fovRadius >= 300 and 50 or fovRadius + 50
    fovSlider.Text = "FOV: " .. fovRadius
end)

smoothSlider.MouseButton1Click:Connect(function()
    smoothing = smoothing >= 1 and 0.05 or math.round((smoothing + 0.05) * 100) / 100
    smoothSlider.Text = "Smooth: " .. smoothing
end)

closeButton.MouseButton1Click:Connect(function()
    espEnabled = false
    aimbotEnabled = false
    for char in pairs(highlighted) do char:Destroy() end
    screenGui:Destroy()
end)

minimizeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    minimizedLogo.Visible = true
end)


-- LOGO CUANDO ESTÁ MINIMIZADO
local minimizedLogo = Instance.new("ImageButton")
minimizedLogo.Name = "MinimizedLogo"
minimizedLogo.Size = UDim2.new(0, 60, 0, 60)
minimizedLogo.Position = UDim2.new(0.5, -30, 0, 10) -- posición inicial centrada arriba
minimizedLogo.Image = "rbxassetid://119268860825586" -- ID del logo
minimizedLogo.BackgroundTransparency = 1
minimizedLogo.Visible = false
minimizedLogo.Parent = screenGui

-- Redondear el logo (hacerlo circular)
local uiCorner = Instance.new("UICorner", minimizedLogo)
uiCorner.CornerRadius = UDim.new(1, 0)

-- Permitir mover el logo
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    minimizedLogo.Position = UDim2.new(
        0, startPos.X.Offset + delta.X,
        0, startPos.Y.Offset + delta.Y
    )
end

minimizedLogo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = minimizedLogo.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

minimizedLogo.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Mostrar GUI al hacer clic en el logo
minimizedLogo.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    minimizedLogo.Visible = false
end)


toggleESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    toggleESPButton.Text = espEnabled and "Disable ESP" or "Enable ESP"
end)

toggleTeamButton.MouseButton1Click:Connect(function()
    ignoreTeammates = not ignoreTeammates
    toggleTeamButton.Text = ignoreTeammates and "Ignore teammates: ON" or "Ignore teammates: OFF"
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

RunService.RenderStepped:Connect(function()
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
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

    if aimbotEnabled and aimbotHold then
        local target = getClosestTarget()
        aimAtTarget(target)
    end
end)
