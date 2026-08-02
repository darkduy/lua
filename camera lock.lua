local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local cameraLocked = false
local originalCameraType = nil
local originalCameraSubject = nil
local renderConnection = nil
local characterConnection = nil

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CameraLockGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 230, 0, 112)
mainFrame.Position = UDim2.new(0, 20, 0.5, 130)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -36, 0, 30)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.Text = "Camera Lock"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -32, 0, 4)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextScaled = true
closeButton.Parent = mainFrame
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.9, 0, 0, 38)
toggleButton.Position = UDim2.new(0.05, 0, 0, 38)
toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
toggleButton.Text = "CAMERA LOCK: OFF"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = mainFrame
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 8)

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(0.9, 0, 0, 26)
hintLabel.Position = UDim2.new(0.05, 0, 0, 80)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "Press C: only you rotate camera"
hintLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
hintLabel.TextScaled = true
hintLabel.Font = Enum.Font.Gotham
hintLabel.Parent = mainFrame

local function getHumanoid()
	local character = player.Character
	return character and character:FindFirstChild("Humanoid")
end

local function updateButton()
	if cameraLocked then
		toggleButton.Text = "CAMERA LOCK: ON"
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	else
		toggleButton.Text = "CAMERA LOCK: OFF"
		toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	end
end

local function forcePlayerCamera()
	camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom

	local humanoid = getHumanoid()
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function setCameraLocked(enabled)
	if cameraLocked == enabled then return end
	cameraLocked = enabled
	camera = workspace.CurrentCamera

	if enabled then
		originalCameraType = camera.CameraType
		originalCameraSubject = camera.CameraSubject
		forcePlayerCamera()
	else
		camera.CameraType = originalCameraType or Enum.CameraType.Custom
		if originalCameraSubject then
			camera.CameraSubject = originalCameraSubject
		end
	end

	updateButton()
end

local function toggleCameraLocked()
	setCameraLocked(not cameraLocked)
end

renderConnection = RunService.RenderStepped:Connect(function()
	if cameraLocked then
		forcePlayerCamera()
	end
end)

characterConnection = player.CharacterAdded:Connect(function()
	if cameraLocked then
		task.defer(forcePlayerCamera)
	end
end)

toggleButton.MouseButton1Click:Connect(toggleCameraLocked)

closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.C then
		toggleCameraLocked()
	end
end)

screenGui.Destroying:Connect(function()
	setCameraLocked(false)
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end
end)

updateButton()
print("Camera Lock loaded! Press C or use the GUI button.")
