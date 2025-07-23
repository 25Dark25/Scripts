local P = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local LP = P.LocalPlayer
local CAM = workspace.CurrentCamera

local ENABLED = true
local IGNORE_TEAM = false
local MARKED = {}
local CONNECTIONS = {}
local PAUSED = false

local guiRoot = Instance.new("ScreenGui")
guiRoot.Name = "MainInterface"
guiRoot.ResetOnSpawn = false
guiRoot.DisplayOrder = 9999
guiRoot.Parent = LP:WaitForChild("PlayerGui")

local mainWnd = Instance.new("Frame", guiRoot)
mainWnd.Name = "Window"
mainWnd.Size = UDim2.new(0, 250, 0, 150)
mainWnd.Position = UDim2.new(0.5, -125, 0.5, -75)
mainWnd.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainWnd.Active = true  -- Necesario para arrastrar

local function makeBtn(parent, txt, size, pos, color)
    local b = Instance.new("TextButton", parent)
    b.Name = txt:gsub("%s", "") .. "_btn"
    b.Size = size
    b.Position = pos
    b.Text = txt
    b.TextColor3 = Color3.new(0, 0, 0)
    b.BackgroundColor3 = color
    b.AutoLocalize = false
    return b
end

local closeBtn = makeBtn(mainWnd, "X", UDim2.new(0,30,0,30), UDim2.new(1,-35,0,5), Color3.fromRGB(255,0,0))
local minBtn = makeBtn(mainWnd, "-", UDim2.new(0,30,0,30), UDim2.new(1,-70,0,5), Color3.fromRGB(200,200,200))
local toggleBtn = makeBtn(mainWnd, "Disable", UDim2.new(0.8,0,0,30), UDim2.new(0.1,0,0.45,0), Color3.fromRGB(200,200,200))
local teamBtn = makeBtn(mainWnd, "Ignore team: OFF", UDim2.new(0.8,0,0,30), UDim2.new(0.1,0,0.75,0), Color3.fromRGB(200,200,200))

local minimizedBtn = Instance.new("ImageButton", guiRoot)
minimizedBtn.Name = "MiniBtn"
minimizedBtn.Size = UDim2.new(0,40,0,40)
minimizedBtn.Position = UDim2.new(0.5, -20, 0, 10)
minimizedBtn.BackgroundTransparency = 1
minimizedBtn.Image = "rbxassetid://119268860825586"
minimizedBtn.Visible = false
minimizedBtn.AutoButtonColor = true
Instance.new("UICorner", minimizedBtn).CornerRadius = UDim.new(1, 0)

local function markCharacter(char)
    if MARKED[char] or not ENABLED or PAUSED then return end
    local plr = P:GetPlayerFromCharacter(char)
    if not plr or (IGNORE_TEAM and plr.Team == LP.Team) then return end
    local high = Instance.new("Highlight")
    high.Name = "Hlight"
    high.Adornee = char
    high.FillTransparency = 1
    high.OutlineTransparency = 0
    high.Parent = char
    MARKED[char] = high
end

local function checkVisibility(char)
    if not char or not char:FindFirstChild("Head") then return false end
    local head = char.Head
    local origin = CAM.CFrame.Position
    local dir = (head.Position - origin).Unit * (head.Position - origin).Magnitude
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LP.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local ray = workspace:Raycast(origin, dir, params)
    return (not ray or ray.Instance:IsDescendantOf(char))
end

local function refreshColors()
    for char, hl in pairs(MARKED) do
        if char and hl and char:FindFirstChild("Head") then
            if checkVisibility(char) then
                if hl.OutlineColor ~= Color3.fromRGB(0, 255, 0) then
                    hl.OutlineColor = Color3.fromRGB(0, 255, 0)
                end
            else
                if hl.OutlineColor ~= Color3.fromRGB(255, 0, 0) then
                    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end
end

local function unmarkCharacter(char)
    local hl = MARKED[char]
    if hl then
        hl:Destroy()
        MARKED[char] = nil
    end
end

local function charAdded(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    if ENABLED and not PAUSED then markCharacter(char) end
    humanoid.Died:Connect(function()
        unmarkCharacter(char)
    end)
end

local function playerAdded(plr)
    if plr == LP then return end
    plr.CharacterAdded:Connect(charAdded)
    if plr.Character then charAdded(plr.Character) end
    plr:GetPropertyChangedSignal("Team"):Connect(function()
        if ENABLED then refreshESP() end
    end)
end

function refreshESP()
    for char in pairs(MARKED) do
        unmarkCharacter(char)
    end
    for _, plr in ipairs(P:GetPlayers()) do
        if plr ~= LP and plr.Character then
            markCharacter(plr.Character)
        end
    end
end

function toggleESP()
    ENABLED = not ENABLED
    toggleBtn.Text = ENABLED and "Disable" or "Enable"
    if not ENABLED then
        for char in pairs(MARKED) do
            unmarkCharacter(char)
        end
    else
        for _, plr in ipairs(P:GetPlayers()) do
            if plr ~= LP and plr.Character then
                markCharacter(plr.Character)
            end
        end
    end
end

local function cleanup()
    ENABLED = false
    PAUSED = true
    for char in pairs(MARKED) do
        unmarkCharacter(char)
    end
    for _, conn in ipairs(CONNECTIONS) do
        if conn.Connected then conn:Disconnect() end
    end
    CONNECTIONS = {}
    if guiRoot and guiRoot.Parent then guiRoot:Destroy() end
end

closeBtn.MouseButton1Click:Connect(cleanup)
minBtn.MouseButton1Click:Connect(function()
    mainWnd.Visible = false
    minimizedBtn.Visible = true
end)
minimizedBtn.MouseButton1Click:Connect(function()
    mainWnd.Visible = true
    minimizedBtn.Visible = false
end)
toggleBtn.MouseButton1Click:Connect(toggleESP)
teamBtn.MouseButton1Click:Connect(function()
    IGNORE_TEAM = not IGNORE_TEAM
    teamBtn.Text = IGNORE_TEAM and "Ignore team: ON" or "Ignore team: OFF"
    toggleESP()
    toggleESP()
end)

table.insert(CONNECTIONS, P.PlayerAdded:Connect(playerAdded))
for _, plr in ipairs(P:GetPlayers()) do
    playerAdded(plr)
end

local function dragWnd(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
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

task.spawn(function()
    while true do
        task.wait(0.25)  -- más espaciamiento para menos llamadas
        if ENABLED and not PAUSED then
            refreshColors()
        end
    end
end)

dragWnd(mainWnd)
dragWnd(minimizedBtn)
