--[[
	DailyRewardUI — Daily reward popup
	Shows 7-day streak calendar with claim button.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DailyRewardInfo = Remotes:WaitForChild("DailyRewardInfo", 15)
local ClaimDailyReward = Remotes:WaitForChild("ClaimDailyReward", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- State
local currentInfo = nil

-- Build UI
local function createDailyUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DailyRewardGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Parent = screenGui

	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "DailyFrame"
	frame.Size = UDim2.new(0, 420, 0, 280)
	frame.Position = UDim2.new(0.5, -210, 0.5, -140)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "DAILY REWARD"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		frame.Visible = false
		overlay.Visible = false
	end)

	-- Day boxes container
	local daysFrame = Instance.new("Frame")
	daysFrame.Name = "Days"
	daysFrame.Size = UDim2.new(1, -30, 0, 140)
	daysFrame.Position = UDim2.new(0, 15, 0, 45)
	daysFrame.BackgroundTransparency = 1
	daysFrame.Parent = frame

	local dayLayout = Instance.new("UIListLayout")
	dayLayout.FillDirection = Enum.FillDirection.Horizontal
	dayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dayLayout.Padding = UDim.new(0, 6)
	dayLayout.Parent = daysFrame

	-- Create 7 day boxes
	local dayBoxes = {}
	local defaultRewards = {500, 1500, 5000, 15000, 50000, 150000, 500000}

	for i = 1, 7 do
		local box = Instance.new("Frame")
		box.Name = "Day" .. i
		box.Size = UDim2.new(0, 50, 1, 0)
		box.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		box.BorderSizePixel = 0
		box.LayoutOrder = i
		box.Parent = daysFrame

		local boxCorner = Instance.new("UICorner")
		boxCorner.CornerRadius = UDim.new(0, 8)
		boxCorner.Parent = box

		local dayLabel = Instance.new("TextLabel")
		dayLabel.Name = "DayLabel"
		dayLabel.Size = UDim2.new(1, 0, 0, 25)
		dayLabel.Position = UDim2.new(0, 0, 0, 5)
		dayLabel.BackgroundTransparency = 1
		dayLabel.Text = "Day " .. i
		dayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		dayLabel.TextSize = 11
		dayLabel.Font = Enum.Font.GothamBold
		dayLabel.Parent = box

		local rewardLabel = Instance.new("TextLabel")
		rewardLabel.Name = "RewardLabel"
		rewardLabel.Size = UDim2.new(1, 0, 0, 30)
		rewardLabel.Position = UDim2.new(0, 0, 0, 35)
		rewardLabel.BackgroundTransparency = 1
		rewardLabel.Text = "$" .. Utils.formatCash(defaultRewards[i])
		rewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		rewardLabel.TextSize = 13
		rewardLabel.Font = Enum.Font.GothamBold
		rewardLabel.Parent = box

		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "StatusLabel"
		statusLabel.Size = UDim2.new(1, 0, 0, 25)
		statusLabel.Position = UDim2.new(0, 0, 1, -30)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Text = ""
		statusLabel.TextSize = 18
		statusLabel.Font = Enum.Font.GothamBold
		statusLabel.Parent = box

		dayBoxes[i] = box
	end

	-- Claim button
	local claimBtn = Instance.new("TextButton")
	claimBtn.Name = "ClaimButton"
	claimBtn.Size = UDim2.new(0, 200, 0, 45)
	claimBtn.Position = UDim2.new(0.5, -100, 1, -55)
	claimBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
	claimBtn.BorderSizePixel = 0
	claimBtn.Text = "CLAIM REWARD"
	claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimBtn.TextSize = 18
	claimBtn.Font = Enum.Font.GothamBold
	claimBtn.Parent = frame

	local claimCorner = Instance.new("UICorner")
	claimCorner.CornerRadius = UDim.new(0, 8)
	claimCorner.Parent = claimBtn

	claimBtn.MouseButton1Click:Connect(function()
		ClaimDailyReward:FireServer()
	end)

	return screenGui, frame, overlay, dayBoxes, claimBtn
end

local gui, frame, overlay, dayBoxes, claimBtn = createDailyUI()

-- Update UI based on server info
local function updateDailyUI(info)
	currentInfo = info
	if not info then return end

	local streak = info.streak or 0
	local rewards = info.rewards or {}

	for i = 1, 7 do
		local box = dayBoxes[i]
		if not box then continue end

		local statusLabel = box:FindFirstChild("StatusLabel")
		local rewardLabel = box:FindFirstChild("RewardLabel")

		if rewards[i] then
			rewardLabel.Text = "$" .. Utils.formatCash(rewards[i])
		end

		if i <= streak then
			-- Already claimed
			box.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
			if statusLabel then
				statusLabel.Text = "✓"
				statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			end
		elseif i == streak + 1 and info.canClaim then
			-- Current day — claimable
			box.BackgroundColor3 = Color3.fromRGB(80, 60, 20)
			if statusLabel then
				statusLabel.Text = "!"
				statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			end
		else
			-- Future
			box.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
			if statusLabel then
				statusLabel.Text = ""
			end
		end
	end

	if info.canClaim then
		claimBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		claimBtn.Text = "CLAIM REWARD"
	else
		claimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		claimBtn.Text = "ALREADY CLAIMED"
	end
end

-- Show/hide functions (called by TycoonUI)
_G.ShowDailyReward = function()
	frame.Visible = true
	overlay.Visible = true
end

_G.HideDailyReward = function()
	frame.Visible = false
	overlay.Visible = false
end

-- Server events
DailyRewardInfo.OnClientEvent:Connect(function(info)
	updateDailyUI(info)

	-- Auto-show if claimable (delayed to avoid popup clutter on load)
	if info.canClaim then
		task.wait(10) -- let player explore first
		if not (_G.TutorialActive) then
			frame.Visible = true
			overlay.Visible = true
		end
	end
end)

print("[DailyRewardUI] Initialized")
