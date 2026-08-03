local Players = game:GetService("Players")
local player = Players.LocalPlayer

local godEnabled = false
local connections = {}

local function enableGodMode(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.MaxHealth = math.huge
    humanoid.Health = math.huge

    local healthConn = humanoid.HealthChanged:Connect(function(health)
        if health < math.huge then
            humanoid.Health = math.huge
        end
    end)
    table.insert(connections, healthConn)
end

local function disableGodMode(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
end

local function clearConnections()
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
end

local gui = Instance.new("ScreenGui")
gui.Name = "GodModeGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 70)
frame.Position = UDim2.new(0.5, -100, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "God Mode (Education)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 30)
toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleButton.Text = "Enable God Mode"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = frame

toggleButton.MouseButton1Click:Connect(function()
    godEnabled = not godEnabled

    if godEnabled then
        toggleButton.Text = "Disable God Mode"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)

        if player.Character then
            enableGodMode(player.Character)
        end

        local charAddedConn = player.CharacterAdded:Connect(function(character)
            if godEnabled then
                enableGodMode(character)
            end
        end)
        table.insert(connections, charAddedConn)
    else
        toggleButton.Text = "Enable God Mode"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)

        clearConnections()

        if player.Character then
            disableGodMode(player.Character)
        end
    end
end)

print("GUI God Mode ready.")
