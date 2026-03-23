--[[
	CodeUI — Promo code redemption interface
	Text input + redeem button with result feedback.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RedeemCode = Remotes:WaitForChild("RedeemCode", 15)
local CodeResult = Remotes:WaitForChild("CodeResult", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Build UI
local function createCodeUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CodeGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "CodeFrame"
	frame.Size = UDim2.new(0, 300, 0, 150)
	frame.Position = UDim2.new(0.5, -150, 0.5, -75)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 150, 255)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "ENTER CODE"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 25, 0, 25)
	closeBtn.Position = UDim2.new(1, -30, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 14
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	-- Text input
	local textBox = Instance.new("TextBox")
	textBox.Name = "CodeInput"
	textBox.Size = UDim2.new(1, -30, 0, 35)
	textBox.Position = UDim2.new(0, 15, 0, 40)
	textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	textBox.BorderSizePixel = 0
	textBox.Text = ""
	textBox.PlaceholderText = "Enter code here..."
	textBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.TextSize = 16
	textBox.Font = Enum.Font.Gotham
	textBox.ClearTextOnFocus = true
	textBox.Parent = frame

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 6)
	inputCorner.Parent = textBox

	-- Redeem button
	local redeemBtn = Instance.new("TextButton")
	redeemBtn.Name = "RedeemButton"
	redeemBtn.Size = UDim2.new(1, -30, 0, 35)
	redeemBtn.Position = UDim2.new(0, 15, 0, 82)
	redeemBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	redeemBtn.BorderSizePixel = 0
	redeemBtn.Text = "REDEEM"
	redeemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	redeemBtn.TextSize = 16
	redeemBtn.Font = Enum.Font.GothamBold
	redeemBtn.Parent = frame

	local redeemCorner = Instance.new("UICorner")
	redeemCorner.CornerRadius = UDim.new(0, 6)
	redeemCorner.Parent = redeemBtn

	-- Result label
	local resultLabel = Instance.new("TextLabel")
	resultLabel.Name = "ResultLabel"
	resultLabel.Size = UDim2.new(1, -30, 0, 20)
	resultLabel.Position = UDim2.new(0, 15, 0, 122)
	resultLabel.BackgroundTransparency = 1
	resultLabel.Text = ""
	resultLabel.TextSize = 14
	resultLabel.Font = Enum.Font.GothamBold
	resultLabel.Parent = frame

	-- Redeem click
	redeemBtn.MouseButton1Click:Connect(function()
		local code = textBox.Text
		if code == "" then return end
		RedeemCode:FireServer(code)
		redeemBtn.Text = "..."
	end)

	return screenGui, frame, resultLabel, redeemBtn
end

local gui, frame, resultLabel, redeemBtn = createCodeUI()

-- Show/hide (called by TycoonUI)
_G.ShowCodeUI = function()
	frame.Visible = true
end

_G.HideCodeUI = function()
	frame.Visible = false
end

-- Handle server result
CodeResult.OnClientEvent:Connect(function(success, message)
	redeemBtn.Text = "REDEEM"
	resultLabel.Text = message

	if success then
		resultLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		resultLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	-- Clear after 3 seconds
	task.delay(3, function()
		resultLabel.Text = ""
	end)
end)

print("[CodeUI] Initialized")
