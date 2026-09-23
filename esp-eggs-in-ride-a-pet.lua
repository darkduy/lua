--//====================================================
--// RenderedEggs ESP - Optimized
--// Model Name + Distance
--// X = Disable ESP + Destroy GUI
--//====================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Folder = workspace:FindFirstChild("RenderedEggs")

if not Folder then
    warn("[ESP] Không tìm thấy workspace.RenderedEggs")
    return
end

--====================================================
-- CONFIG
--====================================================

local UPDATE_RATE = 0.20       -- Cập nhật khoảng cách mỗi 0.2 giây
local MAX_DISTANCE = 1000      -- Khoảng cách tối đa để hiện ESP
local SHOW_HIGHLIGHT = true

--====================================================
-- STATE
--====================================================

local ESPs = {}
local Connections = {}
local Running = true

local Character
local RootPart

--====================================================
-- CHARACTER CACHE
--====================================================

local function updateCharacter(character)
    Character = character
    RootPart = character and character:FindFirstChild("HumanoidRootPart")
end

if LocalPlayer.Character then
    updateCharacter(LocalPlayer.Character)
end

Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(character)
    RootPart = character:WaitForChild("HumanoidRootPart", 5)
    Character = character
end)

--====================================================
-- FIND ROOT PART
--====================================================

local function getRootPart(model)
    local primary = model.PrimaryPart

    if primary and primary:IsA("BasePart") then
        return primary
    end

    return model:FindFirstChildWhichIsA("BasePart", true)
end

--====================================================
-- CREATE ESP
--====================================================

local function createESP(model)
    if not Running then
        return
    end

    if not model:IsA("Model") or ESPs[model] then
        return
    end

    local part = getRootPart(model)

    if not part then
        return
    end

    local highlight

    if SHOW_HIGHLIGHT then
        highlight = Instance.new("Highlight")
        highlight.Name = "RenderedEggsESP"
        highlight.Adornee = model
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.75
        highlight.OutlineTransparency = 0
        highlight.Parent = model
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RenderedEggsESP"
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(180, 36)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = true
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Text = model.Name
    label.Parent = billboard

    ESPs[model] = {
        Part = part,
        Billboard = billboard,
        Label = label,
        Highlight = highlight
    }
end

--====================================================
-- REMOVE ESP
--====================================================

local function removeESP(model)
    local data = ESPs[model]

    if not data then
        return
    end

    if data.Billboard then
        data.Billboard:Destroy()
    end

    if data.Highlight then
        data.Highlight:Destroy()
    end

    ESPs[model] = nil
end

--====================================================
-- REMOVE ALL ESP
--====================================================

local function removeAllESP()
    for model, data in pairs(ESPs) do
        if data.Billboard then
            data.Billboard:Destroy()
        end

        if data.Highlight then
            data.Highlight:Destroy()
        end

        ESPs[model] = nil
    end
end

--====================================================
-- INITIAL SCAN
--====================================================

for _, object in ipairs(Folder:GetDescendants()) do
    if object:IsA("Model") then
        createESP(object)
    end
end

--====================================================
-- NEW MODEL
--====================================================

Connections.DescendantAdded = Folder.DescendantAdded:Connect(function(object)
    if object:IsA("Model") then
        task.defer(createESP, object)
    end
end)

--====================================================
-- REMOVED MODEL
--====================================================

Connections.DescendantRemoving = Folder.DescendantRemoving:Connect(function(object)
    if ESPs[object] then
        removeESP(object)
    end
end)

--====================================================
-- DISTANCE UPDATE
--====================================================

task.spawn(function()
    while Running do
        task.wait(UPDATE_RATE)

        if not Running then
            break
        end

        if not RootPart or not RootPart.Parent then
            Character = LocalPlayer.Character

            if Character then
                RootPart = Character:FindFirstChild("HumanoidRootPart")
            end
        end

        if RootPart then
            local myPosition = RootPart.Position

            for model, data in pairs(ESPs) do
                if not model.Parent or not data.Part or not data.Part.Parent then
                    removeESP(model)
                else
                    local distance = (myPosition - data.Part.Position).Magnitude

                    if distance <= MAX_DISTANCE then
                        if not data.Billboard.Enabled then
                            data.Billboard.Enabled = true
                        end

                        data.Label.Text =
                            model.Name ..
                            "\n[" .. math.floor(distance) .. " studs]"
                    else
                        if data.Billboard.Enabled then
                            data.Billboard.Enabled = false
                        end
                    end
                end
            end
        end
    end
end)

--====================================================
-- GUI
--====================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RenderedEggsESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(230, 125)
Main.Position = UDim2.new(0.5, -115, 0.12, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

--====================================================
-- TITLE
--====================================================

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(12, 0)
Title.Size = UDim2.new(1, -50, 0, 35)
Title.Font = Enum.Font.GothamBold
Title.Text = "RenderedEggs ESP"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

--====================================================
-- CLOSE BUTTON
--====================================================

local Close = Instance.new("TextButton")
Close.Name = "Close"
Close.BackgroundTransparency = 1
Close.Position = UDim2.new(1, -35, 0, 3)
Close.Size = UDim2.fromOffset(30, 30)
Close.Font = Enum.Font.GothamBold
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(255, 90, 90)
Close.TextSize = 22
Close.Parent = Main

--====================================================
-- TOGGLE BUTTON
--====================================================

local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.Position = UDim2.fromOffset(12, 42)
Toggle.Size = UDim2.new(1, -24, 0, 40)
Toggle.BackgroundColor3 = Color3.fromRGB(50, 170, 90)
Toggle.BorderSizePixel = 0
Toggle.Font = Enum.Font.GothamBold
Toggle.Text = "ESP: ON"
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.TextSize = 15
Toggle.Parent = Main

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = Toggle

--====================================================
-- INFO
--====================================================

local Info = Instance.new("TextLabel")
Info.Name = "Info"
Info.BackgroundTransparency = 1
Info.Position = UDim2.fromOffset(12, 88)
Info.Size = UDim2.new(1, -24, 0, 25)
Info.Font = Enum.Font.Gotham
Info.Text = "Workspace.RenderedEggs"
Info.TextColor3 = Color3.fromRGB(180, 180, 180)
Info.TextSize = 12
Info.Parent = Main

--====================================================
-- ESP TOGGLE
--====================================================

local ESPEnabled = true

local function setESPEnabled(state)
    ESPEnabled = state

    for _, data in pairs(ESPs) do
        if data.Billboard then
            data.Billboard.Enabled = state
        end

        if data.Highlight then
            data.Highlight.Enabled = state
        end
    end
end

Toggle.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled

    setESPEnabled(ESPEnabled)

    if ESPEnabled then
        Toggle.Text = "ESP: ON"
        Toggle.BackgroundColor3 = Color3.fromRGB(50, 170, 90)
    else
        Toggle.Text = "ESP: OFF"
        Toggle.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
    end
end)

--====================================================
-- CLOSE EVERYTHING
--====================================================

local function shutdown()
    if not Running then
        return
    end

    Running = false

    -- Tắt + xóa toàn bộ ESP
    removeAllESP()

    -- Ngắt tất cả connection
    for _, connection in pairs(Connections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end

    table.clear(Connections)

    -- Xóa GUI hoàn toàn
    if ScreenGui then
        ScreenGui:Destroy()
    end
end

Close.MouseButton1Click:Connect(shutdown)

--====================================================
-- DRAG GUI
--====================================================

local dragging = false
local dragStart
local startPosition
local dragConnection

local function beginDrag(input)
    dragging = true
    dragStart = input.Position
    startPosition = Main.Position

    if dragConnection then
        dragConnection:Disconnect()
    end

    dragConnection = UserInputService.InputChanged:Connect(function(changedInput)
        if not dragging then
            return
        end

        if changedInput.UserInputType ~= Enum.UserInputType.MouseMovement
            and changedInput.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = changedInput.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

local function endDrag()
    dragging = false

    if dragConnection then
        dragConnection:Disconnect()
        dragConnection = nil
    end
end

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        beginDrag(input)
    end
end)

Title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        endDrag()
    end
end)

print("[ESP] RenderedEggs ESP loaded")
