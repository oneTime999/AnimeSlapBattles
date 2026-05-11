local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local SkillEvent = ReplicatedStorage:WaitForChild("SkillEvent")

local enabled = false

-- ============================================
-- GUI
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NearestPlayerSkill"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 190, 0, 55)
Main.Position = UDim2.new(0.5, -95, 0.8, 0)
Main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(55, 55, 55)
Stroke.Thickness = 1
Stroke.Parent = Main

local Button = Instance.new("TextButton")
Button.Name = "ToggleBtn"
Button.Size = UDim2.fromScale(1, 1)
Button.BackgroundTransparency = 1
Button.Text = "OFF"
Button.TextColor3 = Color3.new(1, 1, 1)
Button.TextScaled = true
Button.Font = Enum.Font.GothamBold
Button.Parent = Main

-- ============================================
-- DRAG (Mobile + PC) — separado do clique
-- ============================================
local dragging = false
local dragStart = nil
local startPos = nil
local wasDragged = false
local DRAG_THRESHOLD = 6

-- Usamos o Frame (Main) como área de drag, não o botão
Main.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 
	and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	
	dragging = true
	wasDragged = false
	dragStart = input.Position
	startPos = Main.Position
end)

Main.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement 
	and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = input.Position - dragStart
	
	-- Se ainda não confirmou drag e o mouse não se moveu o suficiente, ignora
	if not wasDragged and delta.Magnitude < DRAG_THRESHOLD then
		return
	end
	
	wasDragged = true
	Main.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end)

-- ============================================
-- TOGGLE (só ativa se NÃO foi drag)
-- ============================================
local function toggle()
	-- Se o frame foi arrastado, não alterna o estado
	if wasDragged then return end
	
	enabled = not enabled

	if enabled then
		Button.Text = "ON"
		Main.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		Stroke.Color = Color3.fromRGB(0, 220, 0)
	else
		Button.Text = "OFF"
		Main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		Stroke.Color = Color3.fromRGB(55, 55, 55)
	end
end

Button.MouseButton1Click:Connect(toggle)

-- ============================================
-- SKILL LOOP (igual ao antigo que funcionava)
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
