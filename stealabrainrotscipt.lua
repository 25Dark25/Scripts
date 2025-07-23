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
mainFrame.Size = UDim2.new(0, 250, 0, 200)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local minimized = false
local savedMainFramePos = mainFrame.Position
local savedLogoPos = UDim2.new(0, 100, 0, 100)

-- Crear el logo redondo que se muestra al minimizar
local logoImage = Instance.new("ImageButton")
logoImage.Name = "LogoImage"
logoImage.Size = UDim2.new(0, 50, 0, 50)
logoImage.Position = savedLogoPos
logoImage.BackgroundTransparency = 1
logoImage.Image = "rbxassetid://119268860825586"
logoImage.Visible = false
logoImage.Parent = screenGui
logoImage.ZIndex = 999999

local logoUICorner = Instance.new("UICorner")
logoUICorner.CornerRadius = UDim.new(1, 0)
logoUICorner.Parent = logoImage

-- Movimiento del logo
local draggingLogo, offset
logoImage.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingLogo = true
		offset = Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(logoImage.AbsolutePosition.X + logoImage.AbsoluteSize.X / 2, logoImage.AbsolutePosition.Y + logoImage.AbsoluteSize.Y / 2)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingLogo = false
		savedLogoPos = logoImage.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingLogo and input.UserInputType == Enum.UserInputType.MouseMovement then
		local newX = input.Position.X - offset.X - logoImage.AbsoluteSize.X / 2
		local newY = input.Position.Y - offset.Y - logoImage.AbsoluteSize.Y / 2
		logoImage.Position = UDim2.new(0, newX, 0, newY)
	end
end)

-- Movimiento del mainFrame
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
		savedMainFramePos = mainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingMain and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

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
local toggleESPButton = createButton(mainFrame, "Disable ESP", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.30, 0), Color3.fromRGB(200, 200, 200))
local toggleTeamButton = createButton(mainFrame, "Ignore teammates: OFF", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.50, 0), Color3.fromRGB(200, 200, 200))
local toggleAimbotButton = createButton(mainFrame, "Enable Aimbot", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.70, 0), Color3.fromRGB(200, 200, 200))
local aimbotKeyButton = createButton(mainFrame, "Change Aimbot Key", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.1, 0, 0.90, 0), Color3.fromRGB(100, 100, 255))

-- FUNCIONES DE BOTONES
minimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	mainFrame.Visible = not minimized
	logoImage.Visible = minimized
	if not minimized then
		mainFrame.Position = savedMainFramePos
	end
end)

logoImage.MouseButton1Click:Connect(function()
	minimized = false
	logoImage.Visible = false
	mainFrame.Visible = true
	mainFrame.Position = savedMainFramePos
end)

closeButton.MouseButton1Click:Connect(function()
	espEnabled = false
	aimbotEnabled = false
	for char in pairs(highlighted) do removeHighlight(char) end
	for _, conn in ipairs(connections) do if conn.Connected then conn:Disconnect() end end
	screenGui:Destroy()
end)

-- (El resto de tu script continúa igual como ya lo tienes...)


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

-- RENDER LOOP
RunService.RenderStepped:Connect(function()
    if espEnabled then
        updateHighlightColors()
    end
    if aimbotEnabled and aimbotHold then
        local target = getClosestTarget()
        aimAtTarget(target)
    end
    local viewportSize = Camera.ViewportSize
    fovCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    fovCircle.Radius = fovRadius
end)
