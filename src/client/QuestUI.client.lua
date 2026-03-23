--[[
	QuestUI — Daily quest panel
	Shows 3 quest cards with progress bars and claim buttons.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local QuestInfo = Remotes:WaitForChild("QuestInfo", 15)
local QuestCompleted = Remotes:WaitForChild("QuestCompleted", 15)
local ClaimQuestReward = Remotes:WaitForChild("ClaimQuestReward", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Build UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Name = "QuestFrame"
frame.Size = UDim2.new(0, 350, 0, 320)
frame.Position = UDim2.new(0.5, -175, 0.5, -160)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 180, 50)
stroke.Thickness = 2
stroke.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "DAILY QUESTS"
title.TextColor3 = Color3.fromRGB(255, 180, 50)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.Parent = frame

-- Timer
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "Timer"
timerLabel.Size = UDim2.new(1, -20, 0, 20)
timerLabel.Position = UDim2.new(0, 10, 0, 32)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "Resets in: --:--:--"
timerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
timerLabel.TextSize = 12
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
timerLabel.Parent = frame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = frame

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
	if _G.PlayButtonClick then _G.PlayButtonClick() end
end)

-- Quest cards container
local questCards = {}

local function createQuestCard(index, yOffset)
	local card = Instance.new("Frame")
	card.Name = "Quest" .. index
	card.Size = UDim2.new(1, -20, 0, 75)
	card.Position = UDim2.new(0, 10, 0, 55 + yOffset)
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
	card.BorderSizePixel = 0
	card.Parent = frame

	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local desc = Instance.new("TextLabel")
	desc.Name = "Description"
	desc.Size = UDim2.new(0.65, 0, 0, 25)
	desc.Position = UDim2.new(0, 10, 0, 5)
	desc.BackgroundTransparency = 1
	desc.Text = "Quest description"
	desc.TextColor3 = Color3.fromRGB(255, 255, 255)
	desc.TextSize = 13
	desc.Font = Enum.Font.GothamBold
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.Parent = card

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Name = "Reward"
	rewardLabel.Size = UDim2.new(0.3, 0, 0, 25)
	rewardLabel.Position = UDim2.new(0.65, 0, 0, 5)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = "+$0"
	rewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	rewardLabel.TextSize = 13
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.TextXAlignment = Enum.TextXAlignment.Right
	rewardLabel.Parent = card

	-- Progress bar background
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, -20, 0, 12)
	barBg.Position = UDim2.new(0, 10, 0, 33)
	barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	barBg.BorderSizePixel = 0
	barBg.Parent = card
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)

	-- Claim button
	local claimBtn = Instance.new("TextButton")
	claimBtn.Name = "ClaimBtn"
	claimBtn.Size = UDim2.new(1, -20, 0, 22)
	claimBtn.Position = UDim2.new(0, 10, 0, 48)
	claimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	claimBtn.BorderSizePixel = 0
	claimBtn.Text = "0/0"
	claimBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
	claimBtn.TextSize = 12
	claimBtn.Font = Enum.Font.GothamBold
	claimBtn.Parent = card
	Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 4)

	claimBtn.MouseButton1Click:Connect(function()
		if _G.PlayButtonClick then _G.PlayButtonClick() end
		ClaimQuestReward:FireServer(index)
	end)

	return {card = card, desc = desc, reward = rewardLabel, barFill = barFill, claimBtn = claimBtn}
end

for i = 1, 3 do
	questCards[i] = createQuestCard(i, (i - 1) * 82)
end

-- Update UI
local currentResetTime = 0

local function updateQuestUI(info)
	if not info or not info.quests then return end

	currentResetTime = info.timeUntilReset or 0

	for i = 1, 3 do
		local quest = info.quests[i]
		local card = questCards[i]
		if not quest or not card then continue end

		card.desc.Text = quest.description
		card.reward.Text = "+$" .. Utils.formatCash(quest.reward)

		local pct = math.clamp((quest.progress or 0) / math.max(1, quest.target), 0, 1)
		card.barFill.Size = UDim2.new(pct, 0, 1, 0)

		if quest.claimed then
			card.claimBtn.Text = "CLAIMED"
			card.claimBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			card.barFill.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		elseif quest.progress >= quest.target then
			card.claimBtn.Text = "CLAIM REWARD"
			card.claimBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
			card.barFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		else
			card.claimBtn.Text = Utils.formatCash(quest.progress) .. " / " .. Utils.formatCash(quest.target)
			card.claimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			card.barFill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		end
	end
end

-- Timer update
task.spawn(function()
	while true do
		task.wait(1)
		if currentResetTime > 0 then
			currentResetTime = currentResetTime - 1
			local h = math.floor(currentResetTime / 3600)
			local m = math.floor((currentResetTime % 3600) / 60)
			local s = currentResetTime % 60
			timerLabel.Text = string.format("Resets in: %02d:%02d:%02d", h, m, s)
		end
	end
end)

-- Show/hide
_G.ShowQuestUI = function()
	frame.Visible = true
end

QuestInfo.OnClientEvent:Connect(function(info)
	updateQuestUI(info)
end)

QuestCompleted.OnClientEvent:Connect(function(description, reward)
	-- Notification handled by EffectsManager
end)

print("[QuestUI] Initialized")
