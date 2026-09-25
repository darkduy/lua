--[[
╔══════════════════════════════════════════════════════════════════╗
║                 RENDERED EGGS ESP + TELEPORT                     ║
║                                                                  ║
║ • ESP all Models inside workspace.RenderedEggs                   ║
║ • Show name + distance                                           ║
║ • Group Eggs by name                                             ║
║ • Collapse / expand groups                                       ║
║ • Global ESP ON/OFF                                              ║
║ • Per-Egg-type ESP ON/OFF                                        ║
║ • Search Eggs                                                    ║
║ • Select Egg                                                     ║
║ • Direct TP button for each Egg                                  ║
║ • Newly spawned Eggs are detected automatically                  ║
║ • Automatically find the LocalPlayer plot using Data.Owner       ║
║ • workspace.Plots is scanned at most 2 times                     ║
║ • TP 10 studs above the Egg / Baseplate                          ║
║ • No script-side teleport distance limit                         ║
╚══════════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local RenderedEggs = workspace:FindFirstChild("RenderedEggs")
local Plots = workspace:FindFirstChild("Plots")

if not RenderedEggs then
    warn("[Egg ESP] workspace.RenderedEggs was not found")
    return
end

if not Plots then
    warn("[Egg ESP] workspace.Plots was not found")
end


--==============================================================
-- SETTINGS
--==============================================================

local UPDATE_RATE = 0.20
local MAX_DISTANCE = 1000

-- Actual height above the object
local HEIGHT_OFFSET = 10

local DEFAULT_ESP = true
local SHOW_HIGHLIGHT = true

-- MAX_TELEPORT_DISTANCE is no longer used


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

local MAX_PLOT_SCANS = 2


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
        RootPart = nil
        return nil
    end

    RootPart =
        Character:FindFirstChild("HumanoidRootPart")
        or Character:FindFirstChild("UpperTorso")
        or Character:FindFirstChild("Torso")

    return Character
end


getCharacter()


--==============================================================
-- CHARACTER
--==============================================================

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
-- FIND ROOT PART
--==============================================================

local function getRootPart(model)

    if not model
        or not model:IsA("Model") then
        return nil
    end

    if model.PrimaryPart
        and model.PrimaryPart:IsA("BasePart") then

        return model.PrimaryPart
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

    local group =
        EggGroups[model.Name]

    if group then
        return group.TypeESPEnabled
    end

    return true
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


--==============================================================
-- MAIN
--==============================================================

local Main =
    Instance.new("Frame")

Main.Name = "Main"

Main.Size =
    UDim2.new(
        0,
        430,
        0,
        560
    )

Main.Position =
    UDim2.new(
        0.5,
        -172,
        0.5,
        -224
    )

Main.BackgroundColor3 =
    Color3.fromRGB(
        22,
        23,
        30
    )

Main.BorderSizePixel = 0

Main.Parent = ScreenGui

-- UI SCALE
local MainScale = Instance.new("UIScale")
MainScale.Scale = 0.8
MainScale.Parent = Main


local MainCorner =
    Instance.new("UICorner")

MainCorner.CornerRadius =
    UDim.new(0, 14)

MainCorner.Parent = Main


local MainStroke =
    Instance.new("UIStroke")

MainStroke.Color =
    Color3.fromRGB(
        75,
        78,
        100
    )

MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.2

MainStroke.Parent = Main


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
        56
    )

TopBar.BackgroundColor3 =
    Color3.fromRGB(
        35,
        36,
        48
    )

TopBar.BorderSizePixel = 0

TopBar.Parent = Main


local TopCorner =
    Instance.new("UICorner")

TopCorner.CornerRadius =
    UDim.new(0, 14)

TopCorner.Parent = TopBar


local Accent =
    Instance.new("Frame")

Accent.Size =
    UDim2.new(
        0,
        5,
        1,
        -18
    )

Accent.Position =
    UDim2.new(
        0,
        9,
        0,
        9
    )

Accent.BackgroundColor3 =
    Color3.fromRGB(
        110,
        130,
        255
    )

Accent.BorderSizePixel = 0

Accent.Parent = TopBar


local AccentCorner =
    Instance.new("UICorner")

AccentCorner.CornerRadius =
    UDim.new(1, 0)

AccentCorner.Parent = Accent


local Title =
    Instance.new("TextLabel")

Title.BackgroundTransparency = 1

Title.Position =
    UDim2.new(
        0,
        25,
        0,
        7
    )

Title.Size =
    UDim2.new(
        1,
        -90,
        0,
        24
    )

Title.Font =
    Enum.Font.GothamBold

Title.TextSize = 17

Title.TextColor3 =
    Color3.fromRGB(
        245,
        245,
        255
    )

Title.TextXAlignment =
    Enum.TextXAlignment.Left

Title.Text =
    "Rendered Eggs"

Title.Parent = TopBar


local Subtitle =
    Instance.new("TextLabel")

Subtitle.BackgroundTransparency = 1

Subtitle.Position =
    UDim2.new(
        0,
        25,
        0,
        30
    )

Subtitle.Size =
    UDim2.new(
        1,
        -90,
        0,
        17
    )

Subtitle.Font =
    Enum.Font.Gotham

Subtitle.TextSize = 10

Subtitle.TextColor3 =
    Color3.fromRGB(
        155,
        158,
        175
    )

Subtitle.TextXAlignment =
    Enum.TextXAlignment.Left

Subtitle.Text =
    ""

Subtitle.Parent = TopBar
Subtitle.Visible = false


local Close =
    Instance.new("TextButton")

Close.Size =
    UDim2.new(
        0,
        36,
        0,
        36
    )

Close.Position =
    UDim2.new(
        1,
        -45,
        0,
        10
    )

Close.BackgroundColor3 =
    Color3.fromRGB(
        180,
        60,
        70
    )

Close.Text =
    "×"

Close.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

Close.Font =
    Enum.Font.GothamBold

Close.TextSize = 20

Close.Parent = TopBar


local CloseCorner =
    Instance.new("UICorner")

CloseCorner.CornerRadius =
    UDim.new(0, 9)

CloseCorner.Parent = Close


--==============================================================
-- CONTROL BUTTONS
--==============================================================

local GlobalToggle =
    Instance.new("TextButton")

GlobalToggle.Size =
    UDim2.new(
        0,
        125,
        0,
        38
    )

GlobalToggle.Position =
    UDim2.new(
        0,
        12,
        0,
        69
    )

GlobalToggle.BackgroundColor3 =
    Color3.fromRGB(
        60,
        155,
        95
    )

GlobalToggle.Text =
    "ESP  •  ON"

GlobalToggle.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

GlobalToggle.Font =
    Enum.Font.GothamBold

GlobalToggle.TextSize = 12

GlobalToggle.Parent = Main


local GlobalCorner =
    Instance.new("UICorner")

GlobalCorner.CornerRadius =
    UDim.new(0, 9)

GlobalCorner.Parent = GlobalToggle


local PlotTP =
    Instance.new("TextButton")

PlotTP.Size =
    UDim2.new(
        0,
        140,
        0,
        38
    )

PlotTP.Position =
    UDim2.new(
        0,
        145,
        0,
        69
    )

PlotTP.BackgroundColor3 =
    Color3.fromRGB(
        78,
        100,
        185
    )

PlotTP.Text =
    "My Plot"

PlotTP.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

PlotTP.Font =
    Enum.Font.GothamBold

PlotTP.TextSize = 12

PlotTP.Parent = Main


local PlotTPCorner =
    Instance.new("UICorner")

PlotTPCorner.CornerRadius =
    UDim.new(0, 9)

PlotTPCorner.Parent = PlotTP


local CountLabel =
    Instance.new("TextLabel")

CountLabel.Size =
    UDim2.new(
        0,
        125,
        0,
        38
    )

CountLabel.Position =
    UDim2.new(
        1,
        -137,
        0,
        69
    )

CountLabel.BackgroundColor3 =
    Color3.fromRGB(
        35,
        36,
        47
    )

CountLabel.Text =
    "Egg: 0"

CountLabel.TextColor3 =
    Color3.fromRGB(
        220,
        222,
        235
    )

CountLabel.Font =
    Enum.Font.GothamBold

CountLabel.TextSize = 12

CountLabel.Parent = Main


local CountCorner =
    Instance.new("UICorner")

CountCorner.CornerRadius =
    UDim.new(0, 9)

CountCorner.Parent = CountLabel


--==============================================================
-- SEARCH
--==============================================================

local SearchBox =
    Instance.new("Frame")

SearchBox.Size =
    UDim2.new(
        1,
        -24,
        0,
        40
    )

SearchBox.Position =
    UDim2.new(
        0,
        12,
        0,
        117
    )

SearchBox.BackgroundColor3 =
    Color3.fromRGB(
        32,
        33,
        43
    )

SearchBox.BorderSizePixel = 0

SearchBox.Parent = Main


local SearchCorner =
    Instance.new("UICorner")

SearchCorner.CornerRadius =
    UDim.new(0, 9)

SearchCorner.Parent = SearchBox


local SearchIcon =
    Instance.new("TextLabel")

SearchIcon.Size =
    UDim2.new(
        0,
        35,
        1,
        0
    )

SearchIcon.BackgroundTransparency = 1

SearchIcon.Text =
    "⌕"

SearchIcon.TextColor3 =
    Color3.fromRGB(
        155,
        160,
        180
    )

SearchIcon.Font =
    Enum.Font.GothamBold

SearchIcon.TextSize = 20

SearchIcon.Parent = SearchBox


local Search =
    Instance.new("TextBox")

Search.Position =
    UDim2.new(
        0,
        34,
        0,
        0
    )

Search.Size =
    UDim2.new(
        1,
        -40,
        1,
        0
    )

Search.BackgroundTransparency = 1

Search.TextColor3 =
    Color3.fromRGB(
        240,
        240,
        248
    )

Search.PlaceholderColor3 =
    Color3.fromRGB(
        125,
        128,
        145
    )

Search.PlaceholderText =
    "Search egg type..."

Search.Text =
    ""

Search.ClearTextOnFocus = false

Search.Font =
    Enum.Font.Gotham

Search.TextSize = 12

Search.TextXAlignment =
    Enum.TextXAlignment.Left

Search.Parent = SearchBox


--==============================================================
-- SELECTED
--==============================================================

local SelectedBox =
    Instance.new("Frame")

SelectedBox.Size =
    UDim2.new(
        1,
        -24,
        0,
        36
    )

SelectedBox.Position =
    UDim2.new(
        0,
        12,
        0,
        165
    )

SelectedBox.BackgroundColor3 =
    Color3.fromRGB(
        29,
        30,
        39
    )

SelectedBox.BorderSizePixel = 0

SelectedBox.Parent = Main


local SelectedCorner =
    Instance.new("UICorner")

SelectedCorner.CornerRadius =
    UDim.new(0, 8)

SelectedCorner.Parent = SelectedBox


local SelectedLabel =
    Instance.new("TextLabel")

SelectedLabel.Size =
    UDim2.new(
        1,
        -18,
        1,
        0
    )

SelectedLabel.Position =
    UDim2.new(
        0,
        9,
        0,
        0
    )

SelectedLabel.BackgroundTransparency = 1

SelectedLabel.Font =
    Enum.Font.Gotham

SelectedLabel.TextSize = 11

SelectedLabel.TextColor3 =
    Color3.fromRGB(
        170,
        174,
        190
    )

SelectedLabel.TextXAlignment =
    Enum.TextXAlignment.Left

SelectedLabel.Text =
    ""

SelectedLabel.Parent = SelectedBox


--==============================================================
-- LIST TITLE
--==============================================================

local ListTitle =
    Instance.new("TextLabel")

ListTitle.Size =
    UDim2.new(
        1,
        -24,
        0,
        24
    )

ListTitle.Position =
    UDim2.new(
        0,
        12,
        0,
        208
    )

ListTitle.BackgroundTransparency = 1

ListTitle.Font =
    Enum.Font.GothamBold

ListTitle.TextSize = 12

ListTitle.TextColor3 =
    Color3.fromRGB(
        220,
        223,
        238
    )

ListTitle.TextXAlignment =
    Enum.TextXAlignment.Left

ListTitle.Text =
    "EGGS"

ListTitle.Parent = Main


--==============================================================
-- SCROLL LIST
--==============================================================

local List =
    Instance.new("ScrollingFrame")

List.Size =
    UDim2.new(
        1,
        -24,
        0,
        260
    )

List.Position =
    UDim2.new(
        0,
        12,
        0,
        233
    )

List.BackgroundColor3 =
    Color3.fromRGB(
        27,
        28,
        36
    )

List.BorderSizePixel = 0

List.ScrollBarThickness = 4

List.ScrollBarImageTransparency = 0.25

List.CanvasSize =
    UDim2.new(
        0,
        0,
        0,
        0
    )

List.AutomaticCanvasSize =
    Enum.AutomaticSize.None

List.Parent = Main


local ListCorner =
    Instance.new("UICorner")

ListCorner.CornerRadius =
    UDim.new(0, 10)

ListCorner.Parent = List


local ListPadding =
    Instance.new("UIPadding")

ListPadding.PaddingTop =
    UDim.new(0, 5)

ListPadding.PaddingBottom =
    UDim.new(0, 5)

ListPadding.PaddingLeft =
    UDim.new(0, 5)

ListPadding.PaddingRight =
    UDim.new(0, 5)

ListPadding.Parent = List


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
            ListLayout.AbsoluteContentSize.Y + 12
        )

end)


--==============================================================
-- STATUS
--==============================================================

local Status =
    Instance.new("TextLabel")

Status.Size =
    UDim2.new(
        1,
        -24,
        0,
        28
    )

Status.Position =
    UDim2.new(
        0,
        12,
        0,
        500
    )

Status.BackgroundTransparency = 1

Status.Font =
    Enum.Font.Gotham

Status.TextSize = 11

Status.TextColor3 =
    Color3.fromRGB(
        145,
        149,
        165
    )

Status.TextXAlignment =
    Enum.TextXAlignment.Left

Status.Text =
    ""

Status.Parent = Main
Status.Visible = false


--==============================================================
-- DRAG
--==============================================================

local dragging = false
local dragStart = nil
local startPosition = nil


TopBar.InputBegan:Connect(function(input)

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

end)


TopBar.InputEnded:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = false

    end

end)


Connections.InputChanged =
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
                    startPosition.X.Offset
                        + delta.X,

                    startPosition.Y.Scale,
                    startPosition.Y.Offset
                        + delta.Y
                )

        end
    )


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


    local root =
        getRootPart(model)


    if not root then
        return
    end


    local billboard =
        Instance.new("BillboardGui")

    billboard.Name =
        "EggESP"

    billboard.Adornee =
        root

    billboard.AlwaysOnTop = true

    billboard.Size =
        UDim2.new(
            0,
            190,
            0,
            44
        )

    billboard.StudsOffset =
        Vector3.new(
            0,
            2.5,
            0
        )

    billboard.Enabled =
        GlobalESPEnabled
        and getEggTypeEnabled(model)

    billboard.Parent =
        root


    local label =
        Instance.new("TextLabel")

    label.Name =
        "Info"

    label.Size =
        UDim2.fromScale(
            1,
            1
        )

    label.BackgroundTransparency = 1

    label.Font =
        Enum.Font.GothamBold

    label.TextSize = 13

    label.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    label.TextStrokeTransparency =
        0.15

    label.Text =
        model.Name

    label.Parent =
        billboard


    local highlight = nil


    if SHOW_HIGHLIGHT then

        highlight =
            Instance.new("Highlight")

        highlight.Name =
            "EggHighlight"

        highlight.FillTransparency =
            0.78

        highlight.OutlineTransparency =
            0.1

        highlight.Adornee =
            model

        highlight.Enabled =
            GlobalESPEnabled
            and getEggTypeEnabled(model)

        highlight.Parent =
            model

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

    local esp =
        ESPs[model]

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
-- CREATE GROUP
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

        GroupFrame = nil,
        Header = nil,

        Container = nil,

        HeaderTitle = nil,

        TypeESPButton = nil

    }


    -- Each Egg group gets one wrapper so the header and its contents
    -- stay together when UIListLayout sorts the scrolling list.
    local GroupFrame =
        Instance.new("Frame")

    GroupFrame.Name =
        "Group_" .. groupName

    GroupFrame.Size =
        UDim2.new(
            1,
            -2,
            0,
            34
        )

    GroupFrame.BackgroundTransparency = 1

    GroupFrame.AutomaticSize =
        Enum.AutomaticSize.Y

    GroupFrame.Parent = List

    local GroupLayout =
        Instance.new("UIListLayout")

    GroupLayout.Padding =
        UDim.new(0, 2)

    GroupLayout.SortOrder =
        Enum.SortOrder.LayoutOrder

    GroupLayout.Parent = GroupFrame

    local Header =
        Instance.new("Frame")

    Header.Name =
        "Header"

    Header.Size =
        UDim2.new(
            1,
            -2,
            0,
            34
        )

    Header.BackgroundColor3 =
        Color3.fromRGB(
            41,
            42,
            54
        )

    Header.BorderSizePixel = 0

    Header.LayoutOrder = 1
    Header.Parent = GroupFrame


    local HeaderCorner =
        Instance.new("UICorner")

    HeaderCorner.CornerRadius =
        UDim.new(0, 7)

    HeaderCorner.Parent =
        Header


    local Toggle =
        Instance.new("TextButton")

    Toggle.Size =
        UDim2.new(
            1,
            -82,
            1,
            0
        )

    Toggle.BackgroundTransparency = 1

    Toggle.TextXAlignment =
        Enum.TextXAlignment.Left

    Toggle.Font =
        Enum.Font.GothamBold

    Toggle.TextSize = 11

    Toggle.TextColor3 =
        Color3.fromRGB(
            235,
            237,
            248
        )

    Toggle.Text =
        "▼  " .. groupName

    Toggle.Parent =
        Header


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
            -75,
            0,
            4
        )

    TypeESP.BackgroundColor3 =
        Color3.fromRGB(
            60,
            145,
            90
        )

    TypeESP.Text =
        "ESP"

    TypeESP.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    TypeESP.Font =
        Enum.Font.GothamBold

    TypeESP.TextSize = 10

    TypeESP.Parent =
        Header


    local TypeCorner =
        Instance.new("UICorner")

    TypeCorner.CornerRadius =
        UDim.new(0, 6)

    TypeCorner.Parent =
        TypeESP


    local Container =
        Instance.new("Frame")

    Container.Name =
        "Container"

    Container.Size =
        UDim2.new(
            1,
            -2,
            0,
            0
        )

    Container.BackgroundTransparency = 1

    Container.AutomaticSize =
        Enum.AutomaticSize.Y

    Container.Visible = true

    Container.LayoutOrder = 2
    Container.Parent =
        GroupFrame


    local ContainerLayout =
        Instance.new("UIListLayout")

    ContainerLayout.Padding =
        UDim.new(0, 2)

    ContainerLayout.Parent =
        Container


    group.GroupFrame =
        GroupFrame

    group.Header =
        Header

    group.Container =
        Container

    group.HeaderTitle =
        Toggle

    group.TypeESPButton =
        TypeESP


    EggGroups[groupName] =
        group


    Toggle.MouseButton1Click:Connect(
        function()

            group.Expanded =
                not group.Expanded

            Container.Visible =
                group.Expanded

            GroupFrame.AutomaticSize =
                Enum.AutomaticSize.Y

            if group.Expanded then

                Toggle.Text =
                    "▼  " .. groupName

            else

                Toggle.Text =
                    "▶  " .. groupName

            end

        end
    )


    TypeESP.MouseButton1Click:Connect(
        function()

            group.TypeESPEnabled =
                not group.TypeESPEnabled


            if group.TypeESPEnabled then

                TypeESP.Text =
                    "ESP"

                TypeESP.BackgroundColor3 =
                    Color3.fromRGB(
                        60,
                        145,
                        90
                    )

            else

                TypeESP.Text =
                    "OFF"

                TypeESP.BackgroundColor3 =
                    Color3.fromRGB(
                        145,
                        65,
                        75
                    )

            end


            for model in pairs(
                group.Eggs
            ) do

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
            32
        )

    Row.BackgroundColor3 =
        Color3.fromRGB(
            35,
            36,
            46
        )

    Row.BorderSizePixel = 0

    Row.Parent =
        group.Container


    local RowCorner =
        Instance.new("UICorner")

    RowCorner.CornerRadius =
        UDim.new(0, 6)

    RowCorner.Parent =
        Row


    local Select =
        Instance.new("TextButton")

    Select.Size =
        UDim2.new(
            1,
            -72,
            1,
            0
        )

    Select.Position =
        UDim2.new(
            0,
            8,
            0,
            0
        )

    Select.BackgroundTransparency = 1

    Select.Text =
        model.Name

    Select.TextColor3 =
        Color3.fromRGB(
            220,
            222,
            235
        )

    Select.TextXAlignment =
        Enum.TextXAlignment.Left

    Select.Font =
        Enum.Font.Gotham

    Select.TextSize = 11

    Select.Parent =
        Row


    local TP =
        Instance.new("TextButton")

    TP.Size =
        UDim2.new(
            0,
            58,
            0,
            26
        )

    TP.Position =
        UDim2.new(
            1,
            -63,
            0,
            3
        )

    TP.BackgroundColor3 =
        Color3.fromRGB(
            77,
            97,
            175
        )

    TP.Text =
        "TP"

    TP.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    TP.Font =
        Enum.Font.GothamBold

    TP.TextSize = 10

    TP.Parent =
        Row


    local TPCorner =
        Instance.new("UICorner")

    TPCorner.CornerRadius =
        UDim.new(0, 6)

    TPCorner.Parent =
        TP


    local entry = {

        Model = model,

        Frame = Row,

        Select = Select,

        TP = TP

    }


    EggEntries[model] =
        entry


    Select.MouseButton1Click:Connect(
        function()

            if not model
                or not model.Parent then

                return

            end


            SelectedEgg =
                model


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
                    "Egg no longer exists"

                return

            end


            getCharacter()


            if not Character
                or not RootPart then

                Status.Text =
                    "Character not found"

                return

            end


            local target =
                getEggTopCFrame(
                    model
                )


            if not target then

                Status.Text =
                    "Egg is not ready"

                return

            end


            local success, reason =
                safeTeleport(
                    Character,
                    RootPart,
                    target
                )


            if success then

                SelectedEgg =
                    model

                SelectedLabel.Text =
                    "Selected: "
                    .. model.Name

                Status.Text =
                    "Teleported to "
                    .. model.Name

            else

                Status.Text =
                    "Teleport failed: "
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
-- NEW EGG SPAWN HANDLER
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


            if getRootPart(object) then
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
-- NEW DESCENDANTS
--==============================================================

Connections.DescendantAdded =
    RenderedEggs.DescendantAdded:Connect(
        function(object)

            tryRegisterEgg(object)

        end
    )


--==============================================================
-- EGG TOP CFRAME
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


    -- No distance check is performed.
    -- Teleport directly to the target position.

    root.AssemblyLinearVelocity =
        Vector3.zero

    root.AssemblyAngularVelocity =
        Vector3.zero


    character:PivotTo(
        targetCFrame
    )


    root.AssemblyLinearVelocity =
        Vector3.zero

    root.AssemblyAngularVelocity =
        Vector3.zero


    return true

end


--==============================================================
-- FIND MY PLOT
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
-- GET MY PLOT
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
-- BASEPLATE TOP
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
-- GLOBAL ESP BUTTON
--==============================================================

GlobalToggle.MouseButton1Click:Connect(
    function()

        GlobalESPEnabled =
            not GlobalESPEnabled


        if GlobalESPEnabled then

            GlobalToggle.Text =
                "ESP  •  ON"

            GlobalToggle.BackgroundColor3 =
                Color3.fromRGB(
                    60,
                    155,
                    95
                )

        else

            GlobalToggle.Text =
                "ESP  •  OFF"

            GlobalToggle.BackgroundColor3 =
                Color3.fromRGB(
                    145,
                    65,
                    75
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
-- TP MY PLOT
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
                "Character not found"

            return

        end


        local baseplate =
            getMyPlotBaseplate()


        if not baseplate then

            Status.Text =
                "Your Plot was not found"

            return

        end


        local target =
            getBaseplateTopCFrame(
                baseplate
            )


        if not target then

            Status.Text =
                "Invalid Baseplate"

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
                "Teleported to My Plot"

        else

            Status.Text =
                "Teleport failed: "
                .. tostring(reason)

        end

    end
)


--==============================================================
-- SEARCH
--==============================================================

local function updateSearch()

    local query =
        string.lower(
            Search.Text or ""
        )

    local groupHasMatch = {}

    for model, entry in pairs(EggEntries) do
        if entry and entry.Model and entry.Frame and entry.Model.Parent then
            local name =
                string.lower(
                    entry.Model.Name
                )

            local matches =
                query == ""
                or string.find(
                    name,
                    query,
                    1,
                    true
                ) ~= nil

            entry.Frame.Visible = matches

            local group =
                EggGroups[entry.Model.Name]

            if group and matches then
                groupHasMatch[group] = true
            end
        elseif entry and entry.Frame then
            entry.Frame.Visible = false
        end
    end

    for _, group in pairs(EggGroups) do
        if query == "" then
            group.GroupFrame.Visible = true
        else
            group.GroupFrame.Visible = groupHasMatch[group] == true
        end
    end

    for _, entry in pairs(
        EggEntries
    ) do

        if entry
            and entry.Model
            and entry.Frame then


            if not entry.Model.Parent then

                entry.Frame.Visible =
                    false

            else

                local name =
                    string.lower(
                        entry.Model.Name
                    )


                -- Visibility is updated in the group-aware pass above.
                -- Keep this branch intentionally lightweight.
                entry.Frame.Visible =
                    entry.Frame.Visible

            end

        end

    end

end


Search:GetPropertyChangedSignal(
    "Text"
):Connect(
    updateSearch
)


--==============================================================
-- UPDATE LOOP
--==============================================================

task.spawn(function()

    while Running do

        getCharacter()


        local root =
            RootPart


        local totalEggs = 0


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


                local group =
                    EggGroups[
                        model.Name
                    ]


                if group then
                    group.Eggs[model] =
                        nil
                end


            else

                totalEggs += 1


                local eggRoot =
                    getRootPart(model)


                if eggRoot then


                    local distance = 0


                    if root then

                        distance =
                            (
                                root.Position
                                - eggRoot.Position
                            ).Magnitude

                    end


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


                    if root then

                        enabled =
                            enabled
                            and distance <=
                                MAX_DISTANCE

                    end


                    esp.Billboard.Enabled =
                        enabled


                    if esp.Highlight then

                        esp.Highlight.Enabled =
                            enabled

                    end


                    if root then

                        esp.Label.Text =
                            model.Name
                            .. "\n["
                            .. math.floor(
                                distance
                            )
                            .. " studs]"


                    else

                        esp.Label.Text =
                            model.Name

                    end


                    local entry =
                        EggEntries[model]


                    if entry then

                        if root then

                            entry.Select.Text =
                                model.Name
                                .. "  ["
                                .. math.floor(
                                    distance
                                )
                                .. " studs]"

                        else

                            entry.Select.Text =
                                model.Name

                        end


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


        CountLabel.Text =
            "Egg: "
            .. totalEggs


        Status.Text =
            "Online  •  Plot scan "
            .. PlotScanCount
            .. "/"
            .. MAX_PLOT_SCANS


        task.wait(
            UPDATE_RATE
        )

    end

end)


--==============================================================
-- SHUTDOWN
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
-- START
--==============================================================

Status.Text =
    "Online  •  Watching for new Eggs"

print(
    "[Rendered Eggs] ESP + Teleport loaded"
)
