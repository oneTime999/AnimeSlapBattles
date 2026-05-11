local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local SkillEvent = ReplicatedStorage:WaitForChild("SkillEvent")

local CONFIG = {
	SKILL_NAME = "Makima",
	LOOP_INTERVAL = 0.2,
	TWEEN_TIME = 0.25,
	DRAG_THRESHOLD = 6,
	COLORS = {
		ON = Color3.fromRGB(46, 204, 113),
		OFF = Color3.fromRGB(30, 39, 46),
		STROKE_ON = Color3.fromRGB(46, 204, 113),
		STROKE_OFF = Color3.fromRGB(255, 255, 255),
		TEXT = Color3.new(1, 1, 1),
	},
}

local function createInstance(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local ScreenGui = createInstance("ScreenGui", {
	Name = "SlowHubSkill",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
}, PlayerGui)

local Main = createInstance("Frame", {
	Name = "MainFrame",
	Size = UDim2.new(0, 160, 0, 52),
	Position = UDim2.new(0.5, -80, 0.7, 0),
	BackgroundColor3 = CONFIG.COLORS.OFF,
	BorderSizePixel = 0,
	Active = true,
}, ScreenGui)

createInstance("UICorner", { CornerRadius = UDim.new(0, 14) }, Main)

local Stroke = createInstance("UIStroke", {
	Color = CONFIG.COLORS.STROKE_OFF,
	Thickness = 1.5,
	Transparency = 0.6,
}, Main)

local Button = createInstance("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "SKILL: OFF",
	TextColor3 = CONFIG.COLORS.TEXT,
	TextScaled = true,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
}, Main)

local enabled = false
local wasDragged = false

local function tweenProps(target, props)
	TweenService:Create(target, TweenInfo.new(CONFIG.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function setEnabled(state)
	enabled = state
	Button.Text = state and "SKILL: ON" or "SKILL: OFF"
	tweenProps(Main, { BackgroundColor3 = state and CONFIG.COLORS.ON or CONFIG.COLORS.OFF })
	tweenProps(Stroke, {
		Color = state and CONFIG.COLORS.STROKE_ON or CONFIG.COLORS.STROKE_OFF,
		Transparency = state and 0.2 or 0.6,
	})
end

local function getNearestPlayer()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local nearest, shortest = nil, math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		local pChar = player.Character
		if not pChar then continue end

		local hrp = pChar:FindFirstChild("HumanoidRootPart")
		local hum = pChar:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then continue end

		local dist = (root.Position - hrp.Position).Magnitude
		if dist < shortest then
			shortest = dist
			nearest = player
		end
	end

	return nearest
end

local function makeDraggable(frame, handle)
	local dragging = false
	local dragStart, startPos

	local DRAG_INPUTS = {
		[Enum.UserInputType.MouseButton1] = true,
		[Enum.UserInputType.Touch] = true,
	}

	local MOVE_INPUTS = {
		[Enum.UserInputType.MouseMovement] = true,
		[Enum.UserInputType.Touch] = true,
	}

	handle.InputBegan:Connect(function(input)
		if not DRAG_INPUTS[input.UserInputType] then return end
		dragging = true
		wasDragged = false
		dragStart = input.Position
		startPos = frame.Position
	end)

	handle.InputEnded:Connect(function(input)
		if DRAG_INPUTS[input.UserInputType] then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging or not MOVE_INPUTS[input.UserInputType] then return end

		local delta = input.Position - dragStart
		if not wasDragged and delta.Magnitude < CONFIG.DRAG_THRESHOLD then return end

		wasDragged = true
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end)
end

makeDraggable(Main, Button)

Button.MouseButton1Click:Connect(function()
	if wasDragged then return end
	setEnabled(not enabled)
end)

task.spawn(function()
	while true do
		task.wait(CONFIG.LOOP_INTERVAL)
		if not enabled then continue end

		local target = getNearestPlayer()
		if target then
			SkillEvent:FireServer(CONFIG.SKILL_NAME, target)
		end
	end
end)
