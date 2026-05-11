local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local SkillEvent = ReplicatedStorage:WaitForChild("SkillEvent")

local enabled = false

-- ============================================
-- GUI MODERNA - CANTO SUPERIOR ESQUERDO
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Cu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Sombra sutil atrás
local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(0, 168, 0, 42)
Shadow.Position = UDim2.new(0, 17, 0, 17) -- leve offset
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.6
Shadow.BorderSizePixel = 0
Shadow.Active = false
Shadow.Parent = ScreenGui

Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 10)

-- Frame principal
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 168, 0, 42)
Main.Position = UDim2.new(0, 15, 0, 15) -- CANTO SUPERIOR ESQUERDO
Main.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(60, 60, 70)
Stroke.Thickness = 1.2
Stroke.Transparency = 0.3
Stroke.Parent = Main

-- Ícone/Indicador (bolinha de status)
local Dot = Instance.new("Frame")
Dot.Name = "Dot"
Dot.Size = UDim2.new(0, 8, 0, 8)
Dot.Position = UDim2.new(0, 14, 0.5, -4)
Dot.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
Dot.BorderSizePixel = 0
Dot.Parent = Main

Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

-- Label do nome
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0, 80, 1, 0)
Title.Position = UDim2.new(0, 30, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MAKIMA"
Title.TextColor3 = Color3.fromRGB(180, 180, 190)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Main

-- Botão invisível que cobre tudo (drag + clique)
local Button = Instance.new("TextButton")
Button.Name = "Hitbox"
Button.Size = UDim2.fromScale(1, 1)
Button.BackgroundTransparency = 1
Button.Text = ""
Button.Parent = Main

-- Status "OFF" à direita
local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(0, 40, 0, 20)
Status.Position = UDim2.new(1, -50, 0.5, -10)
Status.BackgroundTransparency = 1
Status.Text = "OFF"
Status.TextColor3 = Color3.fromRGB(120, 120, 130)
Status.TextXAlignment = Enum.TextXAlignment.Right
Status.Font = Enum.Font.GothamBold
Status.TextSize = 13
Status.Parent = Main

-- ============================================
-- ANIMAÇÕES
-- ============================================
local function tween(obj, props, time)
	TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function setVisual(state)
	enabled = state
	if state then
		tween(Main, { BackgroundColor3 = Color3.fromRGB(25, 45, 35) })
		tween(Stroke, { Color = Color3.fromRGB(60, 220, 120), Transparency = 0.1 })
		tween(Dot, { BackgroundColor3 = Color3.fromRGB(60, 220, 120) })
		tween(Title, { TextColor3 = Color3.fromRGB(255, 255, 255) })
		Status.Text = "ON"
		tween(Status, { TextColor3 = Color3.fromRGB(60, 220, 120) })
	else
		tween(Main, { BackgroundColor3 = Color3.fromRGB(32, 32, 38) })
		tween(Stroke, { Color = Color3.fromRGB(60, 60, 70), Transparency = 0.3 })
		tween(Dot, { BackgroundColor3 = Color3.fromRGB(100, 100, 110) })
		tween(Title, { TextColor3 = Color3.fromRGB(180, 180, 190) })
		Status.Text = "OFF"
		tween(Status, { TextColor3 = Color3.fromRGB(120, 120, 130) })
	end
end

-- ============================================
-- DRAG (Mobile + PC) — 100% funcional
-- ============================================
local dragging = false
local wasDragged = false
local dragStart = nil
local startPos = nil
local activeInput = nil
local DRAG_THRESHOLD = 6

Button.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 
	and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	
	dragging = true
	wasDragged = false
	dragStart = input.Position
	startPos = Main.Position
	activeInput = input
end)

UserInputService.InputEnded:Connect(function(input)
	if not dragging then return end
	if input == activeInput then
		dragging = false
		activeInput = nil
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input ~= activeInput then return end
	
	local delta = input.Position - dragStart
	
	if not wasDragged and delta.Magnitude >= DRAG_THRESHOLD then
		wasDragged = true
	end
	
	if wasDragged then
		local newPos = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
		Main.Position = newPos
		Shadow.Position = UDim2.new(
			newPos.X.Scale, newPos.X.Offset + 2,
			newPos.Y.Scale, newPos.Y.Offset + 2
		)
	end
end)

-- ============================================
-- TOGGLE
-- ============================================
local function toggle()
	if wasDragged then return end
	setVisual(not enabled)
end

Button.Activated:Connect(toggle)

-- ============================================
-- SKILL LOOP
-- ============================================
local function getNearestPlayer()
	local character = LocalPlayer.Character
	if not character then return nil end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local nearest, shortest = nil, math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		
		local char = player.Character
		if not char then continue end
		
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then continue end

		local distance = (root.Position - hrp.Position).Magnitude
		if distance < shortest then
			shortest = distance
			nearest = player
		end
	end

	return nearest
end

task.spawn(function()
	while true do
		task.wait(0.1)
		
		if not enabled then continue end

		local nearestPlayer = getNearestPlayer()
		if nearestPlayer then
			SkillEvent:FireServer("Makima", nearestPlayer)
		end
	end
end)
