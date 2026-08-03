--[[
    GodModeGUI.lua
    A LocalScript-friendly Roblox GUI for toggling a high-health "god mode"
    in your own experiences or Studio test sessions.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local GOD_HEALTH = 1000000000
local DEFAULT_MAX_HEALTH = 100
local DEFAULT_HEALTH = 100

local PROTECTED_STATES = {
    Enum.HumanoidStateType.Dead,
    Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Ragdoll,
}

local godEnabled = false
local activeCharacter = nil
local originalStatsByHumanoid = {}
local fallHealthByHumanoid = {}
local connections = {}

local function trackConnection(connection)
    table.insert(connections, connection)
    return connection
end

local function disconnectAll()
    for _, connection in ipairs(connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end

    for index = #connections, 1, -1 do
        connections[index] = nil
    end
end

local function getHumanoid(character)
    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
end

local function rememberOriginalStats(humanoid)
    if originalStatsByHumanoid[humanoid] then
        return
    end

    fallHealthByHumanoid[humanoid] = nil

    originalStatsByHumanoid[humanoid] = {
        MaxHealth = humanoid.MaxHealth,
        Health = humanoid.Health,
        BreakJointsOnDeath = humanoid.BreakJointsOnDeath,
        StateEnabled = {},
    }

    for _, state in ipairs(PROTECTED_STATES) do
        originalStatsByHumanoid[humanoid].StateEnabled[state] = humanoid:GetStateEnabled(state)
    end
end

local function restoreHumanoid(humanoid)
    if not humanoid then
        return
    end

    local originalStats = originalStatsByHumanoid[humanoid]
    if originalStats then
        humanoid.BreakJointsOnDeath = originalStats.BreakJointsOnDeath
        humanoid.MaxHealth = originalStats.MaxHealth
        humanoid.Health = math.clamp(originalStats.Health, 0, originalStats.MaxHealth)
        for state, wasEnabled in pairs(originalStats.StateEnabled) do
            humanoid:SetStateEnabled(state, wasEnabled)
        end

        originalStatsByHumanoid[humanoid] = nil
        fallHealthByHumanoid[humanoid] = nil
    else
        humanoid.BreakJointsOnDeath = true
        humanoid.MaxHealth = DEFAULT_MAX_HEALTH
        humanoid.Health = DEFAULT_HEALTH
    end
end

local function protectHumanoid(humanoid)
    if not humanoid then
        return
    end

    rememberOriginalStats(humanoid)
    humanoid.BreakJointsOnDeath = false

    for _, state in ipairs(PROTECTED_STATES) do
        humanoid:SetStateEnabled(state, false)
    end

    humanoid.MaxHealth = GOD_HEALTH
    humanoid.Health = GOD_HEALTH

    trackConnection(humanoid.HealthChanged:Connect(function(health)
        if godEnabled and health < GOD_HEALTH then
            humanoid.Health = GOD_HEALTH
        end
    end))

    trackConnection(humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        if godEnabled and humanoid.MaxHealth < GOD_HEALTH then
            humanoid.MaxHealth = GOD_HEALTH
        end
    end))

    trackConnection(humanoid.StateChanged:Connect(function(_, newState)
        if not godEnabled then
            return
        end

        if newState == Enum.HumanoidStateType.Freefall then
            fallHealthByHumanoid[humanoid] = math.max(humanoid.Health, GOD_HEALTH)
            humanoid.Health = GOD_HEALTH
            return
        end

        if newState == Enum.HumanoidStateType.Landed then
            local fallHealth = fallHealthByHumanoid[humanoid] or GOD_HEALTH
            humanoid.Health = math.max(humanoid.Health, fallHealth, GOD_HEALTH)
            fallHealthByHumanoid[humanoid] = nil
            return
        end

        if newState == Enum.HumanoidStateType.Dead or newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.Ragdoll then
            humanoid.Health = GOD_HEALTH
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end))

    trackConnection(humanoid.Died:Connect(function()
        if godEnabled then
            humanoid.Health = GOD_HEALTH
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end))
end

local function enableGodMode(character)
    activeCharacter = character
    protectHumanoid(getHumanoid(character))
end

local function disableGodMode()
    disconnectAll()

    if activeCharacter then
        restoreHumanoid(getHumanoid(activeCharacter))
    elseif player.Character then
        restoreHumanoid(getHumanoid(player.Character))
    end

    activeCharacter = nil
end

local function createCorner(parent, radius)
    if not Instance.new then
        return nil
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function makeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart = nil
    local startPosition = nil

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

local playerGui = player:WaitForChild("PlayerGui")
local existingGui = playerGui:FindFirstChild("GodModeGUI")
if existingGui then
    existingGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "GodModeGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 240, 0, 110)
frame.Position = UDim2.new(0.5, -120, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
frame.BorderSizePixel = 0
frame.Parent = gui
createCorner(frame, 10)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -16, 0, 28)
title.Position = UDim2.new(0, 8, 0, 6)
title.BackgroundTransparency = 1
title.Text = "God Mode (Studio)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 22)
statusLabel.Position = UDim2.new(0, 10, 0, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: OFF"
statusLabel.TextColor3 = Color3.fromRGB(255, 130, 130)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Parent = frame

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, -20, 0, 36)
toggleButton.Position = UDim2.new(0, 10, 0, 66)
toggleButton.BackgroundColor3 = Color3.fromRGB(205, 55, 55)
toggleButton.Text = "Enable God Mode"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = frame
createCorner(toggleButton, 8)

makeDraggable(frame, title)

local function refreshButton()
    if godEnabled then
        statusLabel.Text = "Status: ON"
        statusLabel.TextColor3 = Color3.fromRGB(130, 255, 150)
        toggleButton.Text = "Disable God Mode"
        toggleButton.BackgroundColor3 = Color3.fromRGB(45, 170, 80)
    else
        statusLabel.Text = "Status: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 130, 130)
        toggleButton.Text = "Enable God Mode"
        toggleButton.BackgroundColor3 = Color3.fromRGB(205, 55, 55)
    end
end

local function setGodMode(enabled)
    if godEnabled == enabled then
        return
    end

    godEnabled = enabled

    if godEnabled then
        enableGodMode(player.Character or player.CharacterAdded:Wait())
        trackConnection(player.CharacterAdded:Connect(function(character)
            if godEnabled then
                enableGodMode(character)
            end
        end))
    else
        disableGodMode()
    end

    refreshButton()
end

toggleButton.MouseButton1Click:Connect(function()
    setGodMode(not godEnabled)
end)

gui.Destroying:Connect(function()
    if godEnabled then
        godEnabled = false
        disableGodMode()
    else
        disconnectAll()
    end
end)

refreshButton()
print("God Mode GUI ready. Toggle it from the on-screen button.")
