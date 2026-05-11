-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
	MaxTargetDistance = math.huge,
	RespectTeams = false,
	CheckForceField = true,
	UpdateInterval = 0.15,
	DragSmoothness = 0.25,
	ToggleKey = nil, -- Optional: Enum.KeyCode.Q
	Colors = {
		On = Color3.fromRGB(46, 204, 113),
		Off = Color3.fromRGB(44, 62, 80),
		Stroke = Color3.fromRGB(255, 255, 255)
	}
}

-- State
local State = {
	Enabled = false,
	Connections = {},
	Drag = {
		Active = false,
		Input = nil,
		StartPosition = nil,
		DragStart = nil
	},
	Character = nil,
	Humanoid = nil,
	RootPart = nil
}

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NearestPlayerSkill"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 150, 0, 50)
MainFrame.Position = UDim2.new(0.5, -75, 0.7, 0)
MainFrame.BackgroundColor3 = CONFIG.Colors.Off
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = CONFIG.Colors.Stroke
Stroke.Thickness = 2
Stroke.Transparency = 0.8
Stroke.Parent = MainFrame

local Button = Instance.new("TextButton")
Button.Name = "ToggleButton"
Button.Size = UDim2.fromScale(1, 1)
Button.BackgroundTransparency = 1
Button.Text = "SKILL: OFF"
Button.TextColor3 = Color3.new(1, 1, 1)
Button.TextScaled = true
Button.Font = Enum.Font.GothamBold
Button.Parent = MainFrame

-- Connection Manager
local function Connect(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(State.Connections, conn)
	return conn
end

-- Visuals
local ActiveTween

local function UpdateToggleVisuals()
	local isEnabled = State.Enabled
	local targetColor = isEnabled and CONFIG.Colors.On or CONFIG.Colors.Off
	local targetText = isEnabled and "SKILL: ON" or "SKILL: OFF"

	if ActiveTween then
		ActiveTween:Cancel()
	end

	ActiveTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		BackgroundColor3 = targetColor
	})
	ActiveTween:Play()

	Button.Text = targetText
end

-- Character Handler
local function OnCharacterRemoving()
	State.Character = nil
	State.Humanoid = nil
	State.RootPart = nil
end

local function OnCharacterAdded(character)
	State.Character = character
	State.RootPart = character:WaitForChild("HumanoidRootPart", 5)
	State.Humanoid = character:FindFirstChildOfClass("Humanoid")

	if State.Humanoid then
		Connect(State.Humanoid.Died, function()
			if not State.Enabled then return end
			State.Enabled = false
			UpdateToggleVisuals()
		end)
	end
end

-- Draggable
local function InitializeDraggable()
	local dragEndConn

	Connect(MainFrame.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		State.Drag.Active = true
		State.Drag.Input = input
		State.Drag.StartPosition = MainFrame.Position
		State.Drag.DragStart = input.Position

		if dragEndConn then
			dragEndConn:Disconnect()
		end

		dragEndConn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				State.Drag.Active = false
				State.Drag.Input = nil
				dragEndConn:Disconnect()
				dragEndConn = nil
			end
		end)
	end)

	Connect(RunService.Heartbeat, function()
		if not State.Drag.Active or not State.Drag.Input then return end

		local delta = State.Drag.Input.Position - State.Drag.DragStart
		local target = UDim2.new(
			State.Drag.StartPosition.X.Scale,
			State.Drag.StartPosition.X.Offset + delta.X,
			State.Drag.StartPosition.Y.Scale,
			State.Drag.StartPosition.Y.Offset + delta.Y
		)

		MainFrame.Position = MainFrame.Position:Lerp(target, CONFIG.DragSmoothness)
	end)
end

-- Targeting
local function IsValidTarget(player)
	if player == LocalPlayer then return false end
	if CONFIG.RespectTeams and player.Team == LocalPlayer.Team then return false end

	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	if CONFIG.CheckForceField and character:FindFirstChildOfClass("ForceField") then
		return false
	end

	return true, rootPart
end

local function GetNearestPlayer()
	if not State.RootPart then return nil end

	local nearest, shortest = nil, CONFIG.MaxDistance
	local localPos = State.RootPart.Position

	for _, player in ipairs(Players:GetPlayers()) do
		local valid, hrp = IsValidTarget(player)
		if valid then
			local distance = (localPos - hrp.Position).Magnitude
			if distance < shortest then
				shortest = distance
				nearest = player
			end
		end
	end

	return nearest
end

-- Toggle
local SkillEvent = ReplicatedStorage:WaitForChild("SkillEvent", 10)

local function Toggle()
	State.Enabled = not State.Enabled
	UpdateToggleVisuals()
end

local lastClick = 0
Connect(Button.MouseButton1Click, function()
	local now = tick()
	if now - lastClick < 0.15 then return end
	lastClick = now
	Toggle()
end)

if CONFIG.ToggleKey then
	Connect(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == CONFIG.ToggleKey then
			Toggle()
		end
	end)
end

-- Execution Loop
local accumulator = 0

Connect(RunService.Heartbeat, function(deltaTime)
	accumulator += deltaTime
	if accumulator < CONFIG.UpdateInterval then return end
	accumulator = 0

	if not State.Enabled then return end
	if not SkillEvent then return end
	if not State.RootPart or not State.Humanoid or State.Humanoid.Health <= 0 then return end

	local target = GetNearestPlayer()
	if target then
		SkillEvent:FireServer("Makima", target)
	end
end)

-- Initialization
if LocalPlayer.Character then
	task.defer(OnCharacterAdded, LocalPlayer.Character)
end

Connect(LocalPlayer.CharacterAdded, OnCharacterAdded)
Connect(LocalPlayer.CharacterRemoving, OnCharacterRemoving)

InitializeDraggable()
UpdateToggleVisuals()

-- Cleanup
Connect(ScreenGui.Destroying, function()
	for _, conn in ipairs(State.Connections) do
		if conn then conn:Disconnect() end
	end
	table.clear(State.Connections)
end)
