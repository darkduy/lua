local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local cameraControlLocked = false
local speed = 60

local bodyVelocity, bodyGyro
local noclipConnection = nil
local renderConnection = nil
local characterConnection = nil

local MIN_SPEED = 30
local MAX_SPEED = 200
local DEFAULT_WALK_SPEED = 16
local ACTIVE_BUTTON_COLOR = Color3.fromRGB(0, 200, 255)
local INACTIVE_BUTTON_COLOR = Color3.fromRGB(0, 120, 255)

local originalWalkSpeed = DEFAULT_WALK_SPEED
local originalCameraType = nil
local originalCameraSubject = nil
local originalCanCollide = {}

local playerScripts = player:WaitForChild("PlayerScripts")
local playerModule = playerScripts:WaitForChild("PlayerModule")
local controlModule = require(playerModule:WaitForChild("ControlModule"))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlyNoclipGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 258)
mainFrame.Position = UDim2.new(0, 20, 0.5, -129)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Fly, Noclip & Camera"
title.TextColor3 = Color3.fromRGB(0, 255, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = titleBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 28, 0, 28)
minimizeButton.Position = UDim2.new(1, -60, 0, 4)
minimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
minimizeButton.Text = "—"
minimizeButton.TextColor3 = Color3.new(1,1,1)
minimizeButton.TextScaled = true
minimizeButton.Parent = titleBar
Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(0, 6)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -28, 0, 4)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.TextScaled = true
closeButton.Parent = titleBar
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -35)
contentFrame.Position = UDim2.new(0, 0, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local flyNoclipButton = Instance.new("TextButton")
flyNoclipButton.Size = UDim2.new(0.9, 0, 0, 50)
flyNoclipButton.Position = UDim2.new(0.05, 0, 0, 8)
flyNoclipButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
flyNoclipButton.Text = "FLY & NOCLIP: OFF"
flyNoclipButton.TextColor3 = Color3.new(1,1,1)
flyNoclipButton.TextScaled = true
flyNoclipButton.Font = Enum.Font.GothamBold
flyNoclipButton.Parent = contentFrame
Instance.new("UICorner", flyNoclipButton).CornerRadius = UDim.new(0, 8)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.9, 0, 0, 28)
speedLabel.Position = UDim2.new(0.05, 0, 0, 68)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: " .. speed
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.Gotham
speedLabel.Parent = contentFrame

local speedSlider = Instance.new("TextButton")
speedSlider.Size = UDim2.new(0.9, 0, 0, 18)
speedSlider.Position = UDim2.new(0.05, 0, 0, 100)
speedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedSlider.Text = ""
speedSlider.Parent = contentFrame
Instance.new("UICorner", speedSlider)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new((speed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED), 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = speedSlider
Instance.new("UICorner", sliderFill)


local cameraLockButton = Instance.new("TextButton")
cameraLockButton.Size = UDim2.new(0.9, 0, 0, 38)
cameraLockButton.Position = UDim2.new(0.05, 0, 0, 128)
cameraLockButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
cameraLockButton.Text = "CAMERA LOCK: OFF"
cameraLockButton.TextColor3 = Color3.new(1,1,1)
cameraLockButton.TextScaled = true
cameraLockButton.Font = Enum.Font.GothamBold
cameraLockButton.Parent = contentFrame
Instance.new("UICorner", cameraLockButton).CornerRadius = UDim.new(0, 8)

local cameraHelpLabel = Instance.new("TextLabel")
cameraHelpLabel.Size = UDim2.new(0.9, 0, 0, 28)
cameraHelpLabel.Position = UDim2.new(0.05, 0, 0, 170)
cameraHelpLabel.BackgroundTransparency = 1
cameraHelpLabel.Text = "Camera: game cannot force Scriptable; you rotate normally"
cameraHelpLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
cameraHelpLabel.TextScaled = true
cameraHelpLabel.Font = Enum.Font.Gotham
cameraHelpLabel.Parent = contentFrame

local upButton = Instance.new("TextButton")
upButton.Size = UDim2.new(0.4, 0, 0, 40)
upButton.Position = UDim2.new(0.05, 0, 0, 205)
upButton.BackgroundColor3 = INACTIVE_BUTTON_COLOR
upButton.Text = "↑ UP"
upButton.TextColor3 = Color3.new(1,1,1)
upButton.TextScaled = true
upButton.Parent = contentFrame
Instance.new("UICorner", upButton).CornerRadius = UDim.new(0, 8)

local downButton = Instance.new("TextButton")
downButton.Size = UDim2.new(0.4, 0, 0, 40)
downButton.Position = UDim2.new(0.55, 0, 0, 205)
downButton.BackgroundColor3 = INACTIVE_BUTTON_COLOR
downButton.Text = "↓ DOWN"
downButton.TextColor3 = Color3.new(1,1,1)
downButton.TextScaled = true
downButton.Parent = contentFrame
Instance.new("UICorner", downButton).CornerRadius = UDim.new(0, 8)

local reopenButton = Instance.new("TextButton")
reopenButton.Size = UDim2.new(0, 44, 0, 44)
reopenButton.Position = UDim2.new(1, -54, 1, -54)
reopenButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
reopenButton.Text = "F"
reopenButton.TextColor3 = Color3.new(1,1,1)
reopenButton.TextScaled = true
reopenButton.Font = Enum.Font.GothamBold
reopenButton.Visible = false
reopenButton.Parent = screenGui
Instance.new("UICorner", reopenButton).CornerRadius = UDim.new(0, 22)

local humanoidCache = nil
local upHeld = false
local downHeld = false

local function rememberCollisionState(part)
	if originalCanCollide[part] == nil then
		originalCanCollide[part] = part.CanCollide
	end
end

local function restoreCollisionState(character)
	for part, canCollide in pairs(originalCanCollide) do
		if part and part.Parent and (not character or part:IsDescendantOf(character)) then
			part.CanCollide = canCollide
		end
		originalCanCollide[part] = nil
	end
end

local function setVerticalButtonState(button, isHeld)
	button.BackgroundColor3 = isHeld and ACTIVE_BUTTON_COLOR or INACTIVE_BUTTON_COLOR
end

local function bindHoldButton(button, setHeld)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			setHeld(true)
		end
	end)

	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			setHeld(false)
		end
	end)

	button.MouseLeave:Connect(function()
		setHeld(false)
	end)
end


local function setCameraLockEnabled(enabled)
	if cameraControlLocked == enabled then return end
	cameraControlLocked = enabled
	camera = workspace.CurrentCamera

	if enabled then
		originalCameraType = camera.CameraType
		originalCameraSubject = camera.CameraSubject
		camera.CameraType = Enum.CameraType.Custom
		if humanoidCache then
			camera.CameraSubject = humanoidCache
		elseif player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end
		cameraLockButton.Text = "CAMERA LOCK: ON"
		cameraLockButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	else
		camera.CameraType = originalCameraType or Enum.CameraType.Custom
		if originalCameraSubject then
			camera.CameraSubject = originalCameraSubject
		end
		cameraLockButton.Text = "CAMERA LOCK: OFF"
		cameraLockButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	end
end

local function toggleCameraLock()
	setCameraLockEnabled(not cameraControlLocked)
end

local function startNoclipLoop()
	if noclipConnection then return end
	noclipConnection = RunService.Stepped:Connect(function()
		local char = player.Character
		if not char then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				rememberCollisionState(part)
				part.CanCollide = false
			end
		end
	end)
end

local function stopNoclipLoop()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
		restoreCollisionState(player.Character)
	end
end

local function startFlyNoclip()
	if flying then return end
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")
	local humanoid = char:WaitForChild("Humanoid")

	flying = true
	humanoidCache = humanoid
	originalWalkSpeed = humanoid.WalkSpeed

	humanoid.AutoRotate = false
	humanoid.PlatformStand = false
	humanoid.WalkSpeed = speed

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = root

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 12500
	bodyGyro.Parent = root

	startNoclipLoop()

	flyNoclipButton.Text = "FLY & NOCLIP: ON"
	flyNoclipButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
end

local function stopFlyNoclip()
	if not flying then return end
	flying = false

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end

	if humanoidCache then
		humanoidCache.AutoRotate = true
		humanoidCache.PlatformStand = false
		humanoidCache.WalkSpeed = originalWalkSpeed
		humanoidCache:Move(Vector3.new(0, 0, 0), false)
		humanoidCache = nil
	end

	stopNoclipLoop()

	flyNoclipButton.Text = "FLY & NOCLIP: OFF"
	flyNoclipButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
end

renderConnection = RunService.RenderStepped:Connect(function()
	if cameraControlLocked then
		camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Custom
		local char = player.Character
		local humanoid = char and char:FindFirstChild("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end

	if not flying or not bodyVelocity or not bodyGyro then return end

	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end

	local dir = controlModule:GetMoveVector()

	local moveVector = Vector3.new(0, 0, 0)
	moveVector += camera.CFrame.LookVector * (-dir.Z)
	moveVector += camera.CFrame.RightVector * dir.X

	if upHeld then
		moveVector += Vector3.new(0, 1, 0)
	end
	if downHeld then
		moveVector -= Vector3.new(0, 1, 0)
	end

	if moveVector.Magnitude > 0 then
		moveVector = moveVector.Unit * speed
	end

	bodyVelocity.Velocity = moveVector
	bodyGyro.CFrame = camera.CFrame

	local horizontalDir = moveVector * Vector3.new(1, 0, 1)
	if horizontalDir.Magnitude > 0 then
		humanoid:Move(horizontalDir.Unit, false)
	else
		humanoid:Move(Vector3.new(0, 0, 0), false)
	end
end)

local function toggleFlyNoclip()
	if flying then
		stopFlyNoclip()
	else
		startFlyNoclip()
	end
end

flyNoclipButton.MouseButton1Click:Connect(toggleFlyNoclip)
cameraLockButton.MouseButton1Click:Connect(toggleCameraLock)

local function updateSpeedFromScreenX(screenX)
	local sliderPos = speedSlider.AbsolutePosition.X
	local sliderWidth = speedSlider.AbsoluteSize.X
	if sliderWidth <= 0 then return end
	local percent = math.clamp((screenX - sliderPos) / sliderWidth, 0, 1)
	speed = math.floor(MIN_SPEED + percent * (MAX_SPEED - MIN_SPEED))
	sliderFill.Size = UDim2.new(percent, 0, 1, 0)
	speedLabel.Text = "Speed: " .. speed
	if flying and humanoidCache then
		humanoidCache.WalkSpeed = speed
	end
end

speedSlider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		updateSpeedFromScreenX(input.Position.X)
		local moveConn
		moveConn = UserInputService.InputChanged:Connect(function(moveInput)
			if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
				updateSpeedFromScreenX(moveInput.Position.X)
			end
		end)
		local endConn
		endConn = UserInputService.InputEnded:Connect(function(endInput)
			if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
				moveConn:Disconnect()
				endConn:Disconnect()
			end
		end)
	end
end)

bindHoldButton(upButton, function(isHeld)
	upHeld = isHeld
	setVerticalButtonState(upButton, isHeld)
end)

bindHoldButton(downButton, function(isHeld)
	downHeld = isHeld
	setVerticalButtonState(downButton, isHeld)
end)

local isMinimized = false
minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		contentFrame.Visible = false
		mainFrame.Size = UDim2.new(0, 280, 0, 35)
		minimizeButton.Text = "+"
	else
		contentFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 280, 0, 258)
		minimizeButton.Text = "—"
	end
end)

closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	reopenButton.Visible = true
end)

reopenButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	reopenButton.Visible = false
	if isMinimized then
		isMinimized = false
		contentFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 280, 0, 258)
		minimizeButton.Text = "—"
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		toggleFlyNoclip()
	elseif input.KeyCode == Enum.KeyCode.C then
		toggleCameraLock()
	end
end)

characterConnection = player.CharacterAdded:Connect(function()
	if flying then
		stopFlyNoclip()
	end
end)

screenGui.Destroying:Connect(function()
	stopFlyNoclip()
	setCameraLockEnabled(false)
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end
end)

print("Fly, Noclip & Camera Lock loaded! Press F for fly or C to keep camera under your control.")
