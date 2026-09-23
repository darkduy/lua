--//====================================================
--// RenderedEggs ESP + Egg Selector + Teleport
--// Optimized
--// X = shutdown toàn bộ
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

local UPDATE_RATE = 0.20
local MAX_DISTANCE = 1000
local SHOW_HIGHLIGHT = true

--====================================================
-- STATE
--====================================================

local ESPs = {}
local EggButtons = {}
local Connections = {}

local Running = true
local ESPEnabled = true
local SelectedEgg = nil

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
    Character = character
    RootPart = character:WaitForChild("HumanoidRootPart", 5)
end)

--====================================================
-- FIND PART
--====================================================

local function getRootPart(model)
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end

    return model:FindFirstChildWhichIsA("BasePart", true)
end

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
Main.Size = UDim2.fromOffset(280, 370)
Main.Position = UDim2.new(0.5, -140, 0.1, 0)
Main.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

--====================================================
-- TITLE
--====================================================

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(12, 0)
Title.Size = UDim2.new(1, -50, 0, 38)
Title.Font = Enum.Font.GothamBold
Title.Text = "RenderedEggs"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

--====================================================
-- CLOSE
--====================================================

local Close = Instance.new("TextButton")
Close.BackgroundTransparency = 1
Close.Position = UDim2.new(1, -38, 0, 3)
Close.Size = UDim2.fromOffset(32, 32)
Close.Font = Enum.Font.GothamBold
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(255, 80, 80)
Close.TextSize = 22
Close.Parent = Main

--====================================================
-- ESP TOGGLE
--====================================================

local Toggle = Instance.new("TextButton")
Toggle.Position = UDim2.fromOffset(12, 40)
Toggle.Size = UDim2.new(1, -24, 0, 38)
Toggle.BackgroundColor3 = Color3.fromRGB(50, 170, 90)
Toggle.BorderSizePixel = 0
Toggle.Font = Enum.Font.GothamBold
Toggle.Text = "ESP: ON"
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.TextSize = 14
Toggle.Parent = Main

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = Toggle

--====================================================
-- SELECTED LABEL
--====================================================

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Position = UDim2.fromOffset(12, 82)
SelectedLabel.Size = UDim2.new(1, -24, 0, 25)
SelectedLabel.Font = Enum.Font.Gotham
SelectedLabel.Text = "Đang chọn: Chưa chọn"
SelectedLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
SelectedLabel.TextSize = 12
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.Parent = Main

--====================================================
-- EGG LIST
--====================================================

local List = Instance.new("ScrollingFrame")
List.Name = "EggList"
List.Position = UDim2.fromOffset(12, 110)
List.Size = UDim2.new(1, -24, 0, 190)
List.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
List.BorderSizePixel = 0
List.ScrollBarThickness = 4
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.Parent = Main

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 8)
ListCorner.Parent = List

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.SortOrder = Enum.SortOrder.Name
Layout.Parent = List

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 6)
Padding.PaddingBottom = UDim.new(0, 6)
Padding.PaddingLeft = UDim.new(0, 6)
Padding.PaddingRight = UDim.new(0, 6)
Padding.Parent = List

--====================================================
-- TELEPORT BUTTON
--====================================================

local TeleportButton = Instance.new("TextButton")
TeleportButton.Position = UDim2.fromOffset(12, 310)
TeleportButton.Size = UDim2.new(1, -24, 0, 40)
TeleportButton.BackgroundColor3 = Color3.fromRGB(70, 120, 210)
TeleportButton.BorderSizePixel = 0
TeleportButton.Font = Enum.Font.GothamBold
TeleportButton.Text = "Teleport tới egg đã chọn"
TeleportButton.TextColor3 = Color3.new(1, 1, 1)
TeleportButton.TextSize = 13
TeleportButton.Parent = Main

local TeleportCorner = Instance.new("UICorner")
TeleportCorner.CornerRadius = UDim.new(0, 8)
TeleportCorner.Parent = TeleportButton

--====================================================
-- INFO
--====================================================

local Info = Instance.new("TextLabel")
Info.BackgroundTransparency = 1
Info.Position = UDim2.fromOffset(12, 350)
Info.Size = UDim2.new(1, -24, 0, 18)
Info.Font = Enum.Font.Gotham
Info.Text = "Workspace.RenderedEggs"
Info.TextColor3 = Color3.fromRGB(130, 130, 130)
Info.TextSize = 10
Info.Parent = Main

--====================================================
-- CREATE ESP
--====================================================

local function createESP(model)
    if not Running or not model:IsA("Model") or ESPs[model] then
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
        highlight.Enabled = ESPEnabled
        highlight.Parent = model
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RenderedEggsESP"
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(180, 36)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = ESPEnabled
    billboard.Parent = part

    local label = Instance.new("TextLabel")
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
-- CREATE EGG BUTTON
--====================================================

local function createEggButton(model)
    if not model:IsA("Model") or EggButtons[model] then
        return
    end

    local Button = Instance.new("TextButton")
    Button.Name = model.Name
    Button.Size = UDim2.new(1, -12, 0, 34)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Button.BorderSizePixel = 0
    Button.Font = Enum.Font.GothamSemibold
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 12
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.Text = model.Name .. "  [-- studs]"
    Button.Parent = List

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Button

    local ButtonPadding = Instance.new("UIPadding")
    ButtonPadding.PaddingLeft = UDim.new(0, 10)
    ButtonPadding.Parent = Button

    EggButtons[model] = Button

    Button.MouseButton1Click:Connect(function()
        if not Running or not model.Parent then
            return
        end

        SelectedEgg = model
        SelectedLabel.Text = "Đang chọn: " .. model.Name

        for egg, btn in pairs(EggButtons) do
            if btn and btn.Parent then
                btn.BackgroundColor3 =
                    (egg == SelectedEgg)
                    and Color3.fromRGB(65, 110, 180)
                    or Color3.fromRGB(40, 40, 40)
            end
        end
    end)
end

--====================================================
-- REMOVE EGG BUTTON
--====================================================

local function removeEggButton(model)
    local button = EggButtons[model]

    if button then
        button:Destroy()
        EggButtons[model] = nil
    end

    if SelectedEgg == model then
        SelectedEgg = nil
        SelectedLabel.Text = "Đang chọn: Chưa chọn"
    end
end

--====================================================
-- INITIAL SCAN
--====================================================

for _, object in ipairs(Folder:GetDescendants()) do
    if object:IsA("Model") then
        createESP(object)
        createEggButton(object)
    end
end

--====================================================
-- NEW OBJECT
--====================================================

Connections.DescendantAdded = Folder.DescendantAdded:Connect(function(object)
    if object:IsA("Model") then
        task.defer(function()
            if Running and object.Parent then
                createESP(object)
                createEggButton(object)
            end
        end)
    end
end)

--====================================================
-- REMOVED OBJECT
--====================================================

Connections.DescendantRemoving = Folder.DescendantRemoving:Connect(function(object)
    if ESPs[object] then
        removeESP(object)
    end

    if EggButtons[object] then
        removeEggButton(object)
    end
end)

--====================================================
-- UPDATE DISTANCE
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
                    local distance =
                        (myPosition - data.Part.Position).Magnitude

                    if distance <= MAX_DISTANCE then
                        data.Billboard.Enabled = ESPEnabled
                        data.Label.Text =
                            model.Name ..
                            "\n[" .. math.floor(distance) .. " studs]"
                    else
                        data.Billboard.Enabled = false
                    end

                    -- Cập nhật khoảng cách trong danh sách
                    local button = EggButtons[model]

                    if button and button.Parent then
                        button.Text =
                            model.Name ..
                            "  [" .. math.floor(distance) .. " studs]"
                    end
                end
            end
        end
    end
end)

--====================================================
-- ESP TOGGLE
--====================================================

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
-- TELEPORT
--====================================================

TeleportButton.MouseButton1Click:Connect(function()
    if not SelectedEgg or not SelectedEgg.Parent then
        SelectedLabel.Text = "Đang chọn: Egg không còn tồn tại"
        SelectedEgg = nil
        return
    end

    local targetPart = getRootPart(SelectedEgg)

    if not targetPart then
        SelectedLabel.Text = "Đang chọn: Không tìm thấy vị trí egg"
        return
    end

    Character = LocalPlayer.Character
    RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

    if not RootPart then
        return
    end

    -- Đặt phía trên egg một chút
    RootPart.CFrame =
        targetPart.CFrame + Vector3.new(0, 3, 0)

    SelectedLabel.Text =
        "Đã teleport: " .. SelectedEgg.Name
end)

--====================================================
-- CLOSE EVERYTHING
--====================================================

local function shutdown()
    if not Running then
        return
    end

    Running = false

    -- Xóa ESP
    for model, data in pairs(ESPs) do
        if data.Billboard then
            data.Billboard:Destroy()
        end

        if data.Highlight then
            data.Highlight:Destroy()
        end

        ESPs[model] = nil
    end

    -- Xóa connection chính
    for _, connection in pairs(Connections) do
        if connection then
            connection:Disconnect()
        end
    end

    table.clear(Connections)

    -- Xóa GUI
    ScreenGui:Destroy()
end

Close.MouseButton1Click:Connect(shutdown)

--====================================================
-- DRAG GUI
--====================================================

local dragging = false
local dragStart
local startPosition

local function updateDrag(input)
    if not dragging then
        return
    end

    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

Title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

Connections.InputChanged = UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        updateDrag(input)
    end
end)

print("[ESP] RenderedEggs ESP + Selector + Teleport loaded")
