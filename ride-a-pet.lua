--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              RENDERED EGGS ESP + TELEPORT                  ║
    ║                                                              ║
    ║  • ESP tất cả Egg trong workspace.RenderedEggs              ║
    ║  • Hiện tên + khoảng cách (studs)                           ║
    ║  • Nhóm Egg cùng tên                                        ║
    ║  • Có thể thu gọn / mở rộng từng nhóm                      ║
    ║  • ESP ON/OFF toàn bộ                                       ║
    ║  • ESP ON/OFF từng loại Egg                                 ║
    ║  • Search Egg                                               ║
    ║  • Chọn Egg → Teleport                                      ║
    ║  • Egg mới spawn tự động được phát hiện                     ║
    ║  • TP cao hơn mặt trên Egg +5 studs                         ║
    ║  • TP cao hơn mặt trên Baseplate plot +5 studs              ║
    ║  • Tự tìm Plot của LocalPlayer qua Data.Owner               ║
    ║  • Quét workspace.Plots tối đa 2 lần                        ║
    ║  • Có kiểm tra khoảng cách / vị trí trước khi TP            ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local RenderedEggs = workspace:FindFirstChild("RenderedEggs")
local Plots = workspace:FindFirstChild("Plots")

if not RenderedEggs then
    warn("[Egg ESP] Không tìm thấy workspace.RenderedEggs")
    return
end

if not Plots then
    warn("[Egg ESP] Không tìm thấy workspace.Plots")
end


--==============================================================
-- SETTINGS
--==============================================================

local UPDATE_RATE = 0.25

local MAX_DISTANCE = 1000

local HEIGHT_OFFSET = 5

local DEFAULT_ESP = true

local SHOW_HIGHLIGHT = true

local MAX_TELEPORT_DISTANCE = 3000

local MAX_PLOT_SCANS = 2


--==============================================================
-- STATE
--==============================================================

local Running = true

local GlobalESPEnabled = true

local ESPs = {}

local EggEntries = {}

local EggGroups = {}

local Connections = {}

local SelectedEgg = nil

local Character = nil
local RootPart = nil

local PlotScanCount = 0

local CachedMyPlot = nil
local CachedBaseplate = nil


--==============================================================
-- UTILITY
--==============================================================

local function isFiniteNumber(value)
    return typeof(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
end


local function isValidPosition(position)
    if typeof(position) ~= "Vector3" then
        return false
    end

    return isFiniteNumber(position.X)
        and isFiniteNumber(position.Y)
        and isFiniteNumber(position.Z)
end


local function getCharacter()
    Character = LocalPlayer.Character

    if not Character then
        return nil
    end

    RootPart =
        Character:FindFirstChild("HumanoidRootPart")
        or Character:FindFirstChild("UpperTorso")
        or Character:FindFirstChild("Torso")

    return Character
end


getCharacter()


Connections.CharacterAdded =
    LocalPlayer.CharacterAdded:Connect(function(character)

        Character = character

        RootPart =
            character:WaitForChild(
                "HumanoidRootPart",
                10
            )

    end)


--==============================================================
-- FIND ROOT PART OF EGG
--==============================================================

local function getRootPart(model)

    if not model
        or not model:IsA("Model") then
        return nil
    end

    local primary = model.PrimaryPart

    if primary
        and primary:IsA("BasePart") then
        return primary
    end

    local root =
        model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("RootPart")
        or model:FindFirstChild("Handle")

    if root
        and root:IsA("BasePart") then
        return root
    end

    return model:FindFirstChildWhichIsA(
        "BasePart",
        true
    )
end


--==============================================================
-- GROUP ESP STATE
--==============================================================

local function getEggTypeEnabled(model)

    if not model then
        return true
    end

    local group = EggGroups[model.Name]

    if group then
        return group.TypeESPEnabled
    end

    return true
end


--==============================================================
-- CREATE ESP
--==============================================================

local function createESP(model)

    if not model
        or not model:IsA("Model")
        or not model.Parent then
        return
    end

    if ESPs[model] then
        return
    end

    local root = getRootPart(model)

    if not root then
        return
    end

    local billboard =
        Instance.new("BillboardGui")

    billboard.Name = "EggESP"

    billboard.Adornee = root

    billboard.AlwaysOnTop = true

    billboard.Size =
        UDim2.new(
            0,
            180,
            0,
            45
        )

    billboard.StudsOffset =
        Vector3.new(0, 2.5, 0)

    billboard.Enabled =
        GlobalESPEnabled
        and getEggTypeEnabled(model)

    billboard.Parent = root


    local label =
        Instance.new("TextLabel")

    label.Name = "Info"

    label.BackgroundTransparency = 1

    label.Size =
        UDim2.fromScale(1, 1)

    label.Font =
        Enum.Font.GothamBold

    label.TextSize = 14

    label.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    label.TextStrokeTransparency = 0

    label.Text =
        model.Name

    label.Parent = billboard


    local highlight = nil

    if SHOW_HIGHLIGHT then

        highlight =
            Instance.new("Highlight")

        highlight.Name = "EggHighlight"

        highlight.FillTransparency = 0.75

        highlight.OutlineTransparency = 0

        highlight.Enabled =
            GlobalESPEnabled
            and getEggTypeEnabled(model)

        highlight.Adornee = model

        highlight.Parent = model

    end


    ESPs[model] = {
        Billboard = billboard,
        Label = label,
        Highlight = highlight
    }
end


--==============================================================
-- DESTROY ESP
--==============================================================

local function destroyESP(model)

    local esp = ESPs[model]

    if not esp then
        return
    end

    if esp.Billboard then
        esp.Billboard:Destroy()
    end

    if esp.Highlight then
        esp.Highlight:Destroy()
    end

    ESPs[model] = nil
end


--==============================================================
-- GUI
--==============================================================

local ScreenGui =
    Instance.new("ScreenGui")

ScreenGui.Name =
    "RenderedEggESP"

ScreenGui.ResetOnSpawn = false

ScreenGui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

ScreenGui.Parent = PlayerGui


local Main =
    Instance.new("Frame")

Main.Name = "Main"

Main.Size =
    UDim2.new(
        0,
        390,
        0,
        520
    )

Main.Position =
    UDim2.new(
        0.5,
        -195,
        0.5,
        -260
    )

Main.BackgroundColor3 =
    Color3.fromRGB(
        25,
        25,
        30
    )

Main.BorderSizePixel = 0

Main.Parent = ScreenGui


local MainCorner =
    Instance.new("UICorner")

MainCorner.CornerRadius =
    UDim.new(0, 10)

MainCorner.Parent = Main


--==============================================================
-- TOP BAR
--==============================================================

local TopBar =
    Instance.new("Frame")

TopBar.Size =
    UDim2.new(
        1,
        0,
        0,
        45
    )

TopBar.BackgroundColor3 =
    Color3.fromRGB(
        35,
        35,
        42
    )

TopBar.BorderSizePixel = 0

TopBar.Parent = Main


local Title =
    Instance.new("TextLabel")

Title.BackgroundTransparency = 1

Title.Position =
    UDim2.new(
        0,
        12,
        0,
        0
    )

Title.Size =
    UDim2.new(
        1,
        -60,
        1,
        0
    )

Title.Font =
    Enum.Font.GothamBold

Title.TextSize = 16

Title.TextXAlignment =
    Enum.TextXAlignment.Left

Title.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

Title.Text =
    "Rendered Eggs ESP"

Title.Parent = TopBar


local Close =
    Instance.new("TextButton")

Close.Size =
    UDim2.new(
        0,
        40,
        0,
        35
    )

Close.Position =
    UDim2.new(
        1,
        -45,
        0,
        5
    )

Close.BackgroundColor3 =
    Color3.fromRGB(
        180,
        55,
        55
    )

Close.Text =
    "X"

Close.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

Close.Font =
    Enum.Font.GothamBold

Close.TextSize = 16

Close.Parent = TopBar


local CloseCorner =
    Instance.new("UICorner")

CloseCorner.CornerRadius =
    UDim.new(0, 7)

CloseCorner.Parent = Close


--==============================================================
-- GLOBAL ESP BUTTON
--==============================================================

local GlobalToggle =
    Instance.new("TextButton")

GlobalToggle.Size =
    UDim2.new(
        0,
        110,
        0,
        35
    )

GlobalToggle.Position =
    UDim2.new(
        0,
        10,
        0,
        55
    )

GlobalToggle.Font =
    Enum.Font.GothamBold

GlobalToggle.TextSize = 13

GlobalToggle.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

GlobalToggle.BackgroundColor3 =
    Color3.fromRGB(
        50,
        120,
        70
    )

GlobalToggle.Text =
    "ESP: ON"

GlobalToggle.Parent = Main


local GlobalCorner =
    Instance.new("UICorner")

GlobalCorner.CornerRadius =
    UDim.new(0, 7)

GlobalCorner.Parent = GlobalToggle


--==============================================================
-- PLOT TP BUTTON
--==============================================================

local PlotTP =
    Instance.new("TextButton")

PlotTP.Size =
    UDim2.new(
        0,
        130,
        0,
        35
    )

PlotTP.Position =
    UDim2.new(
        0,
        130,
        0,
        55
    )

PlotTP.Font =
    Enum.Font.GothamBold

PlotTP.TextSize = 13

PlotTP.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

PlotTP.BackgroundColor3 =
    Color3.fromRGB(
        70,
        90,
        150
    )

PlotTP.Text =
    "TP My Plot +5"

PlotTP.Parent = Main


local PlotTPCorner =
    Instance.new("UICorner")

PlotTPCorner.CornerRadius =
    UDim.new(0, 7)

PlotTPCorner.Parent = PlotTP


--==============================================================
-- SEARCH
--==============================================================

local Search =
    Instance.new("TextBox")

Search.Size =
    UDim2.new(
        1,
        -20,
        0,
        35
    )

Search.Position =
    UDim2.new(
        0,
        10,
        0,
        100
    )

Search.BackgroundColor3 =
    Color3.fromRGB(
        40,
        40,
        47
    )

Search.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

Search.PlaceholderColor3 =
    Color3.fromRGB(
        150,
        150,
        150
    )

Search.PlaceholderText =
    "Search egg..."

Search.Text =
    ""

Search.ClearTextOnFocus = false

Search.Font =
    Enum.Font.Gotham

Search.TextSize = 13

Search.Parent = Main


local SearchCorner =
    Instance.new("UICorner")

SearchCorner.CornerRadius =
    UDim.new(0, 7)

SearchCorner.Parent = Search


--==============================================================
-- SELECTED LABEL
--==============================================================

local SelectedLabel =
    Instance.new("TextLabel")

SelectedLabel.Size =
    UDim2.new(
        1,
        -20,
        0,
        30
    )

SelectedLabel.Position =
    UDim2.new(
        0,
        10,
        0,
        140
    )

SelectedLabel.BackgroundTransparency = 1

SelectedLabel.Font =
    Enum.Font.Gotham

SelectedLabel.TextSize = 13

SelectedLabel.TextColor3 =
    Color3.fromRGB(
        210,
        210,
        210
    )

SelectedLabel.TextXAlignment =
    Enum.TextXAlignment.Left

SelectedLabel.Text =
    "Selected: None"

SelectedLabel.Parent = Main


--==============================================================
-- SCROLL LIST
--==============================================================

local List =
    Instance.new("ScrollingFrame")

List.Size =
    UDim2.new(
        1,
        -20,
        0,
        280
    )

List.Position =
    UDim2.new(
        0,
        10,
        0,
        170
    )

List.BackgroundColor3 =
    Color3.fromRGB(
        30,
        30,
        36
    )

List.BorderSizePixel = 0

List.ScrollBarThickness = 5

List.CanvasSize =
    UDim2.new(
        0,
        0,
        0,
        0
    )

List.Parent = Main


local ListLayout =
    Instance.new("UIListLayout")

ListLayout.Padding =
    UDim.new(0, 4)

ListLayout.SortOrder =
    Enum.SortOrder.Name

ListLayout.Parent = List


ListLayout:GetPropertyChangedSignal(
    "AbsoluteContentSize"
):Connect(function()

    List.CanvasSize =
        UDim2.new(
            0,
            0,
            0,
            ListLayout.AbsoluteContentSize.Y + 8
        )

end)


--==============================================================
-- TP SELECTED EGG
--==============================================================

local TeleportEgg =
    Instance.new("TextButton")

TeleportEgg.Size =
    UDim2.new(
        1,
        -20,
        0,
        38
    )

TeleportEgg.Position =
    UDim2.new(
        0,
        10,
        0,
        458
    )

TeleportEgg.BackgroundColor3 =
    Color3.fromRGB(
        65,
        105,
        170
    )

TeleportEgg.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

TeleportEgg.Font =
    Enum.Font.GothamBold

TeleportEgg.TextSize = 13

TeleportEgg.Text =
    "TP Above Egg +5"

TeleportEgg.Parent = Main


local TeleportCorner =
    Instance.new("UICorner")

TeleportCorner.CornerRadius =
    UDim.new(0, 7)

TeleportCorner.Parent =
    TeleportEgg


--==============================================================
-- STATUS
--==============================================================

local Status =
    Instance.new("TextLabel")

Status.Size =
    UDim2.new(
        1,
        -20,
        0,
        25
    )

Status.Position =
    UDim2.new(
        0,
        10,
        0,
        425
    )

Status.BackgroundTransparency = 1

Status.Font =
    Enum.Font.Gotham

Status.TextSize = 12

Status.TextColor3 =
    Color3.fromRGB(
        170,
        170,
        170
    )

Status.TextXAlignment =
    Enum.TextXAlignment.Left

Status.Text =
    "Đang quét Egg..."

Status.Parent = Main


--==============================================================
-- DRAG GUI
--==============================================================

local dragging = false
local dragStart
local startPosition


TopBar.InputBegan:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            dragging = true

            dragStart =
                input.Position

            startPosition =
                Main.Position

        end

    end
)


TopBar.InputEnded:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            dragging = false

        end

    end
)


UserInputService.InputChanged:Connect(
    function(input)

        if not dragging then
            return
        end

        if input.UserInputType ~=
            Enum.UserInputType.MouseMovement
            and input.UserInputType ~=
            Enum.UserInputType.Touch then
            return
        end

        local delta =
            input.Position - dragStart

        Main.Position =
            UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )

    end
)


--==============================================================
-- CREATE EGG GROUP
--==============================================================

local function createEggGroup(groupName)

    if EggGroups[groupName] then
        return EggGroups[groupName]
    end

    local group = {

        Name = groupName,

        Eggs = {},

        Expanded = true,

        TypeESPEnabled = true,

        Frame = nil,

        HeaderTitle = nil,

        TypeESPButton = nil

    }


    local Header =
        Instance.new("Frame")

    Header.Name =
        "Group_" .. groupName

    Header.Size =
        UDim2.new(
            1,
            -8,
            0,
            32
        )

    Header.BackgroundColor3 =
        Color3.fromRGB(
            50,
            50,
            60
        )

    Header.Parent = List


    local Toggle =
        Instance.new("TextButton")

    Toggle.Size =
        UDim2.new(
            1,
            -80,
            1,
            0
        )

    Toggle.BackgroundTransparency = 1

    Toggle.Font =
        Enum.Font.GothamBold

    Toggle.TextSize = 13

    Toggle.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    Toggle.TextXAlignment =
        Enum.TextXAlignment.Left

    Toggle.Text =
        "▼ " .. groupName

    Toggle.Parent = Header


    local TypeESP =
        Instance.new("TextButton")

    TypeESP.Size =
        UDim2.new(
            0,
            70,
            0,
            26
        )

    TypeESP.Position =
        UDim2.new(
            1,
            -74,
            0,
            3
        )

    TypeESP.BackgroundColor3 =
        Color3.fromRGB(
            50,
            120,
            70
        )

    TypeESP.Text =
        "ESP ON"

    TypeESP.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    TypeESP.Font =
        Enum.Font.GothamBold

    TypeESP.TextSize = 11

    TypeESP.Parent = Header


    local Container =
        Instance.new("Frame")

    Container.Size =
        UDim2.new(
            1,
            -8,
            0,
            0
        )

    Container.BackgroundTransparency = 1

    Container.AutomaticSize =
        Enum.AutomaticSize.Y

    Container.Visible = true

    Container.Parent = List


    local ContainerLayout =
        Instance.new("UIListLayout")

    ContainerLayout.Padding =
        UDim.new(0, 2)

    ContainerLayout.Parent =
        Container


    group.Frame = Container

    group.HeaderTitle = Toggle

    group.TypeESPButton = TypeESP

    EggGroups[groupName] = group


    Toggle.MouseButton1Click:Connect(
        function()

            group.Expanded =
                not group.Expanded

            Container.Visible =
                group.Expanded

            if group.Expanded then

                Toggle.Text =
                    "▼ " .. groupName

            else

                Toggle.Text =
                    "▶ " .. groupName

            end

        end
    )


    TypeESP.MouseButton1Click:Connect(
        function()

            group.TypeESPEnabled =
                not group.TypeESPEnabled

            if group.TypeESPEnabled then

                TypeESP.Text =
                    "ESP ON"

                TypeESP.BackgroundColor3 =
                    Color3.fromRGB(
                        50,
                        120,
                        70
                    )

            else

                TypeESP.Text =
                    "ESP OFF"

                TypeESP.BackgroundColor3 =
                    Color3.fromRGB(
                        120,
                        55,
                        55
                    )

            end


            for model in pairs(group.Eggs) do

                local esp =
                    ESPs[model]

                if esp then

                    local enabled =
                        GlobalESPEnabled
                        and group.TypeESPEnabled

                    esp.Billboard.Enabled =
                        enabled

                    if esp.Highlight then
                        esp.Highlight.Enabled =
                            enabled
                    end

                end

            end

        end
    )


    return group
end


--==============================================================
-- FILTER SEARCH
--==============================================================

local function updateSearch()

    local query =
        string.lower(
            Search.Text or ""
        )


    for _, entry in pairs(EggEntries) do

        if entry.Model
            and entry.Frame
            and entry.Model.Parent then

            local name =
                string.lower(
                    entry.Model.Name
                )

            local visible =
                query == ""
                or string.find(
                    name,
                    query,
                    1,
                    true
                ) ~= nil

            entry.Frame.Visible =
                visible

        end

    end

end


Search:GetPropertyChangedSignal(
    "Text"
):Connect(updateSearch)


--==============================================================
-- CREATE EGG ENTRY
--==============================================================

local function createEggEntry(model)

    if EggEntries[model] then
        return
    end

    if not model
        or not model:IsA("Model")
        or not model.Parent then
        return
    end


    local group =
        createEggGroup(
            model.Name
        )


    group.Eggs[model] = true


    local Row =
        Instance.new("Frame")

    Row.Name =
        "Egg"

    Row.Size =
        UDim2.new(
            1,
            -4,
            0,
            30
        )

    Row.BackgroundColor3 =
        Color3.fromRGB(
            42,
            42,
            50
        )

    Row.Parent =
        group.Frame


    local Select =
        Instance.new("TextButton")

    Select.Size =
        UDim2.new(
            1,
            -70,
            1,
            0
        )

    Select.BackgroundTransparency = 1

    Select.Text =
        model.Name

    Select.TextColor3 =
        Color3.fromRGB(
            230,
            230,
            230
        )

    Select.TextXAlignment =
        Enum.TextXAlignment.Left

    Select.Font =
        Enum.Font.Gotham

    Select.TextSize = 12

    Select.Parent = Row


    local TP =
        Instance.new("TextButton")

    TP.Size =
        UDim2.new(
            0,
            62,
            0,
            25
        )

    TP.Position =
        UDim2.new(
            1,
            -65,
            0,
            2
        )

    TP.BackgroundColor3 =
        Color3.fromRGB(
            65,
            105,
            170
        )

    TP.Text =
        "TP +5"

    TP.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    TP.Font =
        Enum.Font.GothamBold

    TP.TextSize = 11

    TP.Parent = Row


    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, 5)

    corner.Parent = TP


    local entry = {

        Model = model,

        Frame = Row,

        Select = Select,

        TP = TP

    }


    EggEntries[model] = entry


    Select.MouseButton1Click:Connect(
        function()

            if not model
                or not model.Parent then
                return
            end

            SelectedEgg = model

            SelectedLabel.Text =
                "Selected: "
                .. model.Name

        end
    )


    TP.MouseButton1Click:Connect(
        function()

            if not Running then
                return
            end

            if not model
                or not model.Parent then

                Status.Text =
                    "Egg không còn tồn tại"

                return
            end


            getCharacter()

            if not Character
                or not RootPart then

                Status.Text =
                    "Không tìm thấy nhân vật"

                return
            end


            local target =
                getEggTopCFrame(model)

            if not target then

                Status.Text =
                    "Egg chưa sẵn sàng để TP"

                return

            end


            local success, reason =
                safeTeleport(
                    Character,
                    RootPart,
                    target
                )


            if success then

                Status.Text =
                    "Đã TP tới "
                    .. model.Name
                    .. " +5"

            else

                Status.Text =
                    "TP thất bại: "
                    .. tostring(reason)

            end

        end
    )

end


--==============================================================
-- REGISTER MODEL
--==============================================================

local function registerModel(model)

    if not Running then
        return
    end

    if not model
        or not model:IsA("Model")
        or not model.Parent then
        return
    end

    if not model:IsDescendantOf(
        RenderedEggs
    ) then
        return
    end


    if not EggEntries[model] then
        createEggEntry(model)
    end


    if not ESPs[model] then
        createESP(model)
    end

end


--==============================================================
-- WAIT FOR NEW SPAWNED EGG
--==============================================================

local function tryRegisterEgg(object)

    if not Running then
        return
    end

    if not object
        or not object:IsA("Model") then
        return
    end

    if not object:IsDescendantOf(
        RenderedEggs
    ) then
        return
    end


    task.defer(function()

        if not Running
            or not object.Parent
            or not object:IsDescendantOf(
                RenderedEggs
            ) then
            return
        end


        local deadline =
            os.clock() + 2


        repeat

            if not Running
                or not object.Parent
                or not object:IsDescendantOf(
                    RenderedEggs
                ) then

                return

            end


            local root =
                getRootPart(object)


            if root then
                break
            end


            task.wait(0.05)

        until os.clock() >= deadline


        if not Running
            or not object.Parent
            or not object:IsDescendantOf(
                RenderedEggs
            ) then

            return

        end


        -- Đăng ký sau khi Egg đã có part
        registerModel(object)

    end)

end


--==============================================================
-- INITIAL SCAN
--==============================================================

for _, object in ipairs(
    RenderedEggs:GetDescendants()
) do

    if object:IsA("Model") then

        registerModel(object)

    end

end


--==============================================================
-- NEW EGG DETECTION
--==============================================================

Connections.DescendantAdded =
    RenderedEggs.DescendantAdded:Connect(
        function(object)

            tryRegisterEgg(object)

        end
    )


--==============================================================
-- TOP SURFACE OF BASEPLATE
--==============================================================

local function getBaseplateTopCFrame(
    baseplate
)

    if not baseplate
        or not baseplate:IsA("BasePart")
        or not baseplate.Parent then

        return nil

    end


    local size =
        baseplate.Size

    local cf =
        baseplate.CFrame


    if not isFiniteNumber(size.Y)
        or size.Y <= 0 then

        return nil

    end


    if not isValidPosition(
        cf.Position
    ) then

        return nil

    end


    local verticalOffset =
        (size.Y * 0.5)
        + HEIGHT_OFFSET


    local target =
        cf * CFrame.new(
            0,
            verticalOffset,
            0
        )


    if not isValidPosition(
        target.Position
    ) then

        return nil

    end


    return target

end


--==============================================================
-- TOP SURFACE OF EGG
--==============================================================

function getEggTopCFrame(egg)

    if not egg
        or not egg:IsA("Model")
        or not egg.Parent then

        return nil

    end


    local cf, size =
        egg:GetBoundingBox()


    if not isValidPosition(
        cf.Position
    ) then

        return nil

    end


    if not isFiniteNumber(size.Y)
        or size.Y <= 0 then

        return nil

    end


    local targetPosition =
        Vector3.new(
            cf.Position.X,
            cf.Position.Y
                + (size.Y * 0.5)
                + HEIGHT_OFFSET,
            cf.Position.Z
        )


    if not isValidPosition(
        targetPosition
    ) then

        return nil

    end


    return CFrame.new(
        targetPosition
    )

end


--==============================================================
-- SAFE TELEPORT
--==============================================================

function safeTeleport(
    character,
    root,
    targetCFrame
)

    if not character
        or not character.Parent then

        return false,
            "Character is invalid"

    end


    if not root
        or not root.Parent then

        return false,
            "RootPart is invalid"

    end


    if not targetCFrame then

        return false,
            "Target is invalid"

    end


    local targetPosition =
        targetCFrame.Position


    if not isValidPosition(
        targetPosition
    ) then

        return false,
            "Target position is invalid"

    end


    local distance =
        (root.Position
            - targetPosition).Magnitude


    if not isFiniteNumber(
        distance
    ) then

        return false,
            "Teleport distance is invalid"

    end


    if distance >
        MAX_TELEPORT_DISTANCE then

        return false,
            "Teleport distance is too far"

    end


    root.AssemblyLinearVelocity =
        Vector3.zero

    root.AssemblyAngularVelocity =
        Vector3.zero


    root.CFrame =
        targetCFrame


    return true

end


--==============================================================
-- FIND PLAYER PLOT
--==============================================================

local function scanMyPlot()

    if not Plots then
        return nil
    end


    if PlotScanCount >=
        MAX_PLOT_SCANS then

        return CachedMyPlot

    end


    PlotScanCount += 1


    CachedMyPlot = nil
    CachedBaseplate = nil


    for _, plot in ipairs(
        Plots:GetChildren()
    ) do

        local data =
            plot:FindFirstChild(
                "Data"
            )


        if data then

            local owner =
                data:FindFirstChild(
                    "Owner"
                )


            if owner
                and owner:IsA(
                    "ObjectValue"
                )
                and owner.Value ==
                    LocalPlayer then


                CachedMyPlot =
                    plot


                local baseplate =
                    plot:FindFirstChild(
                        "Baseplate"
                    )


                if not baseplate then

                    baseplate =
                        plot:FindFirstChild(
                            "Baseplate",
                            true
                        )

                end


                if baseplate
                    and baseplate:IsA(
                        "BasePart"
                    ) then

                    CachedBaseplate =
                        baseplate

                end


                break

            end

        end

    end


    return CachedMyPlot

end


--==============================================================
-- VALIDATE CACHED PLOT
--==============================================================

local function getMyPlot()

    if CachedMyPlot
        and CachedMyPlot.Parent then

        local data =
            CachedMyPlot:FindFirstChild(
                "Data"
            )


        local owner =
            data
            and data:FindFirstChild(
                "Owner"
            )


        if owner
            and owner:IsA(
                "ObjectValue"
            )
            and owner.Value ==
                LocalPlayer then

            return CachedMyPlot

        end

    end


    return scanMyPlot()

end


--==============================================================
-- GET BASEPLATE
--==============================================================

local function getMyPlotBaseplate()

    local plot =
        getMyPlot()


    if not plot then
        return nil
    end


    if CachedBaseplate
        and CachedBaseplate.Parent
        and CachedBaseplate:IsDescendantOf(
            plot
        ) then

        return CachedBaseplate

    end


    local baseplate =
        plot:FindFirstChild(
            "Baseplate"
        )


    if not baseplate then

        baseplate =
            plot:FindFirstChild(
                "Baseplate",
                true
            )

    end


    if baseplate
        and baseplate:IsA(
            "BasePart"
        ) then

        CachedBaseplate =
            baseplate

        return baseplate

    end


    return nil

end


--==============================================================
-- GLOBAL ESP
--==============================================================

GlobalToggle.MouseButton1Click:Connect(
    function()

        GlobalESPEnabled =
            not GlobalESPEnabled


        if GlobalESPEnabled then

            GlobalToggle.Text =
                "ESP: ON"

            GlobalToggle.BackgroundColor3 =
                Color3.fromRGB(
                    50,
                    120,
                    70
                )

        else

            GlobalToggle.Text =
                "ESP: OFF"

            GlobalToggle.BackgroundColor3 =
                Color3.fromRGB(
                    120,
                    55,
                    55
                )

        end


        for model, esp in pairs(
            ESPs
        ) do

            if esp then

                local group =
                    EggGroups[
                        model.Name
                    ]


                local enabled =
                    GlobalESPEnabled
                    and (
                        not group
                        or group.TypeESPEnabled
                    )


                esp.Billboard.Enabled =
                    enabled


                if esp.Highlight then

                    esp.Highlight.Enabled =
                        enabled

                end

            end

        end

    end
)


--==============================================================
-- TP TO MY PLOT
--==============================================================

PlotTP.MouseButton1Click:Connect(
    function()

        if not Running then
            return
        end


        getCharacter()


        if not Character
            or not RootPart then

            Status.Text =
                "Không tìm thấy nhân vật"

            return

        end


        local baseplate =
            getMyPlotBaseplate()


        if not baseplate then

            Status.Text =
                "Không tìm thấy Baseplate plot của bạn"

            return

        end


        local target =
            getBaseplateTopCFrame(
                baseplate
            )


        if not target then

            Status.Text =
                "Baseplate không hợp lệ"

            return

        end


        local success, reason =
            safeTeleport(
                Character,
                RootPart,
                target
            )


        if success then

            Status.Text =
                "Đã TP tới Baseplate plot +5"

        else

            Status.Text =
                "TP thất bại: "
                .. tostring(reason)

        end

    end
)


--==============================================================
-- TP SELECTED EGG
--==============================================================

TeleportEgg.MouseButton1Click:Connect(
    function()

        if not Running then
            return
        end


        if not SelectedEgg
            or not SelectedEgg.Parent then

            Status.Text =
                "Chưa chọn Egg"

            return

        end


        getCharacter()


        if not Character
            or not RootPart then

            Status.Text =
                "Không tìm thấy nhân vật"

            return

        end


        local target =
            getEggTopCFrame(
                SelectedEgg
            )


        if not target then

            Status.Text =
                "Egg chưa sẵn sàng để TP"

            return

        end


        local success, reason =
            safeTeleport(
                Character,
                RootPart,
                target
            )


        if success then

            Status.Text =
                "Đã TP tới "
                .. SelectedEgg.Name
                .. " +5"

        else

            Status.Text =
                "TP thất bại: "
                .. tostring(reason)

        end

    end
)


--==============================================================
-- UPDATE LOOP
--==============================================================

task.spawn(function()

    while Running do

        getCharacter()


        local characterRoot =
            RootPart


        for model, esp in pairs(
            ESPs
        ) do

            if not model
                or not model.Parent
                or not model:IsDescendantOf(
                    RenderedEggs
                ) then


                destroyESP(model)


                local entry =
                    EggEntries[model]


                if entry then

                    if entry.Frame then
                        entry.Frame:Destroy()
                    end

                    EggEntries[model] =
                        nil

                end


            else

                local root =
                    getRootPart(model)


                if root
                    and characterRoot then


                    local distance =
                        (
                            characterRoot.Position
                            - root.Position
                        ).Magnitude


                    local group =
                        EggGroups[
                            model.Name
                        ]


                    local groupEnabled =
                        not group
                        or group.TypeESPEnabled


                    local enabled =
                        GlobalESPEnabled
                        and groupEnabled
                        and distance <=
                            MAX_DISTANCE


                    esp.Billboard.Enabled =
                        enabled


                    if esp.Highlight then

                        esp.Highlight.Enabled =
                            enabled

                    end


                    esp.Label.Text =
                        model.Name
                        .. "\n["
                        .. math.floor(
                            distance
                        )
                        .. " studs]"


                    local entry =
                        EggEntries[model]


                    if entry
                        and entry.Frame then

                        entry.Select.Text =
                            model.Name
                            .. " ["
                            .. math.floor(
                                distance
                            )
                            .. " studs]"


                        local query =
                            string.lower(
                                Search.Text or ""
                            )


                        local name =
                            string.lower(
                                model.Name
                            )


                        entry.Frame.Visible =
                            query == ""
                            or string.find(
                                name,
                                query,
                                1,
                                true
                            ) ~= nil

                    end

                end

            end

        end


        local eggCount = 0


        for _ in pairs(ESPs) do
            eggCount += 1
        end


        Status.Text =
            "Egg: "
            .. eggCount
            .. " | Plot scans: "
            .. PlotScanCount
            .. "/"
            .. MAX_PLOT_SCANS


        task.wait(
            UPDATE_RATE
        )

    end

end)


--==============================================================
-- CLOSE / SHUTDOWN
--==============================================================

local function shutdown()

    if not Running then
        return
    end


    Running = false


    for model in pairs(
        ESPs
    ) do

        destroyESP(model)

    end


    for _, connection in pairs(
        Connections
    ) do

        if connection then

            pcall(function()
                connection:Disconnect()
            end)

        end

    end


    if ScreenGui then
        ScreenGui:Destroy()
    end

end


Close.MouseButton1Click:Connect(
    shutdown
)


--==============================================================
-- DONE
--==============================================================

Status.Text =
    "ESP đã sẵn sàng | Đang theo dõi Egg mới..."

print(
    "[Egg ESP] Loaded successfully."
)
