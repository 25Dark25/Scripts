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

-- GUI PRINCIPAL
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DarkGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.DisplayOrder = 10000

-- FRAME PRINCIPAL
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 350)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui -- Importante: agregar a screenGui

-- FUNCION PARA CREAR BOTONES
local function createButton(parent, text, size, position, color)
    local btn = Instance.new("TextButton")
    btn.Name = text:gsub("%s", "") .. "Button"
    btn.Size = size
    btn.Position = position
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundColor3 = color
    btn.AutoLocalize = false
    btn.AutoButtonColor = true -- Aseguramos que esté activo para efecto visual y clics
    btn.Parent = parent
    return btn
end

-- FUNCION PARA CREAR SLIDER (igual que antes)
local function createSlider(parent, labelText, minValue, maxValue, defaultValue, size, position)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16
    label.Text = labelText .. ": " .. tostring(defaultValue)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local sliderBackground = Instance.new("Frame")
    sliderBackground.Size = UDim2.new(1, -20, 0, 10)
    sliderBackground.Position = UDim2.new(0, 10, 0, 25)
    sliderBackground.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    sliderBackground.BorderSizePixel = 0
    sliderBackground.ClipsDescendants = true
    sliderBackground.Name = "SliderBackground"
    sliderBackground.Parent = frame

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((defaultValue - minValue) / (maxValue - minValue), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Name = "SliderFill"
    sliderFill.Parent = sliderBackground

    local sliderHandle = Instance.new("ImageLabel")
    sliderHandle.Size = UDim2.new(0, 20, 1, 0)
    sliderHandle.BackgroundTransparency = 1
    sliderHandle.Image = "rbxassetid://3570695787" -- círculo blanco
    sliderHandle.ImageColor3 = Color3.fromRGB(255, 255, 255)
    sliderHandle.Position = UDim2.new(sliderFill.Size.X.Scale - 0.05, 0, 0, 0)
    sliderHandle.Name = "SliderHandle"
    sliderHandle.Active = true
    sliderHandle.Selectable = true
    sliderHandle.Draggable = true
    sliderHandle.Parent = sliderBackground

    local dragging = false
    local currentValue = defaultValue

    local function updateSlider(input)
        local relativePos = math.clamp(input.Position.X - sliderBackground.AbsolutePosition.X, 0, sliderBackground.AbsoluteSize.X)
        local percent = relativePos / sliderBackground.AbsoluteSize.X
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderHandle.Position = UDim2.new(percent - 0.05, 0, 0, 0)
        local value = minValue + percent * (maxValue - minValue)
        currentValue = value
        label.Text = labelText .. ": " .. string.format("%.2f", value)
        if frame.ValueChanged then
            frame.ValueChanged(value)
        end
    end

    sliderHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    sliderHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    sliderBackground.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)

    function frame.GetValue()
        return currentValue
    end

    return frame
end

-- CREACION DE BOTONES
local closeButton = createButton(mainFrame, "X", UDim2.new(0, 30, 0, 30), UDim2.new(1, -35, 0, 5), Color3.fromRGB(255, 0, 0))
local minimizeButton = createButton(mainFrame, "-", UDim2.new(0, 30, 0, 30), UDim2.new(1, -70, 0, 5), Color3.fromRGB(200, 200, 200))
local toggleESPButton = createButton(mainFrame, "Disable ESP", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.25, 0), Color3.fromRGB(200, 200, 200))
local toggleTeamButton = createButton(mainFrame, "Ignore teammates: OFF", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.40, 0), Color3.fromRGB(200, 200, 200))
local toggleAimbotButton = createButton(mainFrame, "Enable Aimbot", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.55, 0), Color3.fromRGB(200, 200, 200))
local aimbotKeyButton = createButton(mainFrame, "Change Aimbot Key", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.70, 0), Color3.fromRGB(100, 100, 255))

-- CREACION DE SLIDERS
local fovSlider = createSlider(mainFrame, "FOV", 50, 300, fovRadius, UDim2.new(0.8, 0, 0, 40), UDim2.new(0.1, 0, 0.85, 0))
local smoothSlider = createSlider(mainFrame, "Smooth", 0.05, 1, smoothing, UDim2.new(0.8, 0, 0, 40), UDim2.new(0.1, 0, 0.95, 0))

-- CÍRCULO DE FOV
local Drawing = Drawing -- si usas Drawing library disponible
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Thickness = 1
fovCircle.Radius = fovRadius
fovCircle.NumSides = 64
fovCircle.Transparency = 1
fovCircle.Visible = false
fovCircle.Filled = false
fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- FUNCIONES PARA FILTRADO, ESP, AIMBOT ETC.

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

-- EVENTOS PARA SLIDERS

fovSlider.ValueChanged = function(value)
    fovRadius = math.floor(value)
    fovSlider:FindFirstChildOfClass("TextLabel").Text = "FOV: " .. fovRadius
    fovCircle.Radius = fovRadius
end

smoothSlider.ValueChanged = function(value)
    smoothing = tonumber(string.format("%.2f", value))
    smoothSlider:FindFirstChildOfClass("TextLabel").Text = "Smooth: " .. smoothing
end

-- EVENTOS PARA BOTONES

closeButton.MouseButton1Click:Connect(function()
    espEnabled = false
    aimbotEnabled = false
    for char, hl in pairs(highlighted) do
        if hl and hl.Parent then hl:Destroy() end
    end
    screenGui:Destroy()
end)

minimizeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    local mini = Instance.new("ImageButton", screenGui)
    mini.Name = "MinimizedBar"
    mini.Image = "rbxassetid://119268860825586"
    mini.Size = UDim2.new(0, 40, 0, 40)
    mini.Position = UDim2.new(0.5, -20, 0, 10)
    mini.BackgroundTransparency = 1
    mini.Active = true
    mini.Draggable = true
    mini.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        mini:Destroy()
    end)
end)

toggleESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    toggleESPButton.Text = espEnabled and "Disable ESP" or "Enable ESP"
    if not espEnabled then
        for char, hl in pairs(highlighted) do
            if hl and hl.Parent then hl:Destroy() end
        end
        highlighted = {}
    end
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

-- INPUTS PARA AIMBOT KEY

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

-- LOOP PRINCIPAL

RunService.RenderStepped:Connect(function()
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local character = player.Character
                if ignoreTeammates and player.Team == LocalPlayer.Team then
                    if highlighted[character] then
                        highlighted[character]:Destroy()
                        highlighted[character] = nil
                    end
                else
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
    else
        for char, hl in pairs(highlighted) do
            if hl and hl.Parent then
                hl:Destroy()
            end
        end
        highlighted = {}
    end

    if aimbotEnabled and aimbotHold then
        local target = getClosestTarget()
        aimAtTarget(target)
    end

    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)
