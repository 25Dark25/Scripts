local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local highlighted = {}

local function addHighlight(character)
    if not character or highlighted[character] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "ClientHighlight"
    hl.Adornee = character
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(0, 255, 0)
    hl.Parent = LocalPlayer:WaitForChild("PlayerGui")
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
    -- aplica highlight
    addHighlight(character)
    -- remueve al morir
    local humano = character:WaitForChild("Humanoid")
    humano.Died:Connect(function()
        removeHighlight(character)
    end)
end

local function onPlayerAdded(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(onCharacterAdded)
        if player.Character then
            onCharacterAdded(player.Character)
        end
    end
end

-- Conexiones
Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end
