--[[
	EffectsManager — Visual feedback
	Cash popup numbers, purchase effects, rebirth flash.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ItemPurchased = Remotes:WaitForChild("ItemPurchased", 15)
local RebirthSuccess = Remotes:WaitForChild("RebirthSuccess", 15)
local BuildingAppeared = Remotes:WaitForChild("BuildingAppeared", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Create effects ScreenGui
local effectsGui = Instance.new("ScreenGui")
effectsGui.Name = "EffectsGUI"
effectsGui.ResetOnSpawn = false
effectsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
effectsGui.Parent = PlayerGui

-- Floating text effect (purchase notification)
local function showFloatingText(text, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 300, 0, 50)
	label.Position = UDim2.new(0.5, -150, 0.4, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 215, 0)
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = effectsGui

	-- Animate: float up and fade out
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(label, tweenInfo, {
		Position = UDim2.new(0.5, -150, 0.3, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

-- Screen flash effect (rebirth)
local function showRebirthEffect()
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 0.3
	flash.BorderSizePixel = 0
	flash.ZIndex = 100
	flash.Parent = effectsGui

	-- Show rebirth text
	local rebirthText = Instance.new("TextLabel")
	rebirthText.Size = UDim2.new(1, 0, 0, 80)
	rebirthText.Position = UDim2.new(0, 0, 0.35, 0)
	rebirthText.BackgroundTransparency = 1
	rebirthText.Text = "REBIRTH!"
	rebirthText.TextColor3 = Color3.fromRGB(255, 50, 50)
	rebirthText.TextSize = 60
	rebirthText.Font = Enum.Font.GothamBold
	rebirthText.TextStrokeTransparency = 0
	rebirthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rebirthText.ZIndex = 101
	rebirthText.Parent = effectsGui

	-- Fade out flash
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(flash, tweenInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(rebirthText, tweenInfo, {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Position = UDim2.new(0, 0, 0.25, 0),
	}):Play()

	task.delay(2.5, function()
		flash:Destroy()
		rebirthText:Destroy()
	end)
end

-- 3D sparkle effect at a world position (building appeared)
local function showBuildingSparkle(position)
	-- Create temporary part with particle emitter
	local effectPart = Instance.new("Part")
	effectPart.Size = Vector3.new(1, 1, 1)
	effectPart.Position = position + Vector3.new(0, 5, 0)
	effectPart.Anchored = true
	effectPart.Transparency = 1
	effectPart.CanCollide = false
	effectPart.Parent = workspace

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 200))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 50
	particles.Speed = NumberRange.new(5, 15)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = effectPart

	-- Emit burst then cleanup
	particles:Emit(30)
	particles.Enabled = false

	task.delay(2, function()
		effectPart:Destroy()
	end)
end

-- Income popup tracking (throttled, suppressed for first 8 seconds)
local lastIncomePopupTime = 0
local accumulatedIncome = 0
local lastKnownCash = 0
local gameStartTime = tick()
local UpdateCash = Remotes:WaitForChild("UpdateCash", 15)

-- Color-coded income popup based on amount
local function getIncomeColor(amount)
	if amount >= 100000 then
		return Color3.fromRGB(255, 215, 0) -- Gold
	elseif amount >= 10000 then
		return Color3.fromRGB(180, 100, 255) -- Purple
	elseif amount >= 1000 then
		return Color3.fromRGB(100, 180, 255) -- Blue
	elseif amount >= 100 then
		return Color3.fromRGB(100, 255, 100) -- Green
	else
		return Color3.fromRGB(220, 220, 220) -- White
	end
end

local function getIncomeSize(amount)
	if amount >= 100000 then return 28
	elseif amount >= 10000 then return 24
	elseif amount >= 1000 then return 22
	else return 20 end
end

-- Floating income indicator
local function showIncomePopup(amount)
	local color = getIncomeColor(amount)
	local textSize = getIncomeSize(amount)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 200, 0, 30)
	label.Position = UDim2.new(0.5, -100 + math.random(-30, 30), 0.15, 0)
	label.BackgroundTransparency = 1
	label.Text = "+$" .. Utils.formatCash(amount)
	label.TextColor3 = color
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = effectsGui

	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, tweenInfo, {
		Position = label.Position + UDim2.new(0, 0, -0.03, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	task.delay(1, function() label:Destroy() end)
end

-- Confetti burst effect (for purchases, milestones)
local function showConfettiBurst()
	for i = 1, 15 do
		local confetti = Instance.new("Frame")
		confetti.Size = UDim2.new(0, math.random(4, 8), 0, math.random(8, 16))
		confetti.Position = UDim2.new(0.5, math.random(-200, 200), 0.5, math.random(-100, 100))
		confetti.BackgroundColor3 = Color3.fromHSV(math.random() * 360 / 360, 0.8, 1)
		confetti.BorderSizePixel = 0
		confetti.Rotation = math.random(0, 360)
		confetti.Parent = effectsGui

		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(confetti, tweenInfo, {
			Position = confetti.Position + UDim2.new(0, math.random(-50, 50), 0, math.random(100, 300)),
			BackgroundTransparency = 1,
			Rotation = confetti.Rotation + math.random(-180, 180),
		}):Play()

		task.delay(1.5, function() confetti:Destroy() end)
	end
end

-- Expose confetti for other scripts
_G.ShowConfetti = showConfettiBurst

-- Achievement banner
local function showAchievementBanner(name, reward)
	local banner = Instance.new("Frame")
	banner.Size = UDim2.new(0, 400, 0, 60)
	banner.Position = UDim2.new(0.5, -200, 0, -60)
	banner.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	banner.BorderSizePixel = 0
	banner.ZIndex = 50
	banner.Parent = effectsGui

	local bannerCorner = Instance.new("UICorner")
	bannerCorner.CornerRadius = UDim.new(0, 10)
	bannerCorner.Parent = banner

	local bannerStroke = Instance.new("UIStroke")
	bannerStroke.Color = Color3.fromRGB(255, 215, 0)
	bannerStroke.Thickness = 2
	bannerStroke.Parent = banner

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, -20, 0, 25)
	titleText.Position = UDim2.new(0, 10, 0, 5)
	titleText.BackgroundTransparency = 1
	titleText.Text = "ACHIEVEMENT UNLOCKED"
	titleText.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleText.TextSize = 14
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.ZIndex = 51
	titleText.Parent = banner

	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.new(0.6, 0, 0, 25)
	nameText.Position = UDim2.new(0, 10, 0, 30)
	nameText.BackgroundTransparency = 1
	nameText.Text = name
	nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameText.TextSize = 18
	nameText.Font = Enum.Font.GothamBold
	nameText.TextXAlignment = Enum.TextXAlignment.Left
	nameText.ZIndex = 51
	nameText.Parent = banner

	local rewardText = Instance.new("TextLabel")
	rewardText.Size = UDim2.new(0.35, 0, 0, 25)
	rewardText.Position = UDim2.new(0.6, 0, 0, 30)
	rewardText.BackgroundTransparency = 1
	rewardText.Text = "+$" .. Utils.formatCash(reward)
	rewardText.TextColor3 = Color3.fromRGB(100, 255, 100)
	rewardText.TextSize = 16
	rewardText.Font = Enum.Font.GothamBold
	rewardText.TextXAlignment = Enum.TextXAlignment.Right
	rewardText.ZIndex = 51
	rewardText.Parent = banner

	-- Slide in from top
	local slideIn = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(banner, slideIn, {Position = UDim2.new(0.5, -200, 0, 10)}):Play()

	-- Slide out after 4 seconds
	task.delay(4, function()
		local slideOut = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tween = TweenService:Create(banner, slideOut, {Position = UDim2.new(0.5, -200, 0, -70)})
		tween:Play()
		tween.Completed:Connect(function() banner:Destroy() end)
	end)
end

-- Event handlers
ItemPurchased.OnClientEvent:Connect(function(itemIndex, itemName)
	showFloatingText("Purchased: " .. itemName, Color3.fromRGB(100, 255, 100))
end)

BuildingAppeared.OnClientEvent:Connect(function(position)
	if position then
		showBuildingSparkle(position)
	end
end)

RebirthSuccess.OnClientEvent:Connect(function(newCount)
	showRebirthEffect()
	showConfettiBurst()
	task.wait(0.5)
	showFloatingText("Rebirth #" .. newCount .. "!", Color3.fromRGB(255, 100, 100))
end)

-- Income popup (throttled to 1/sec)
UpdateCash.OnClientEvent:Connect(function(newCash)
	local diff = newCash - lastKnownCash
	lastKnownCash = newCash

	if diff > 0 then
		accumulatedIncome = accumulatedIncome + diff
		local now = tick()
		-- Suppress popups for first 8 seconds (avoid clutter on load)
		if now - gameStartTime > 8 and now - lastIncomePopupTime >= 1 then
			showIncomePopup(accumulatedIncome)
			accumulatedIncome = 0
			lastIncomePopupTime = now
		end
	end
end)

-- Achievement banner
task.spawn(function()
	local AchievementUnlocked = Remotes:WaitForChild("AchievementUnlocked", 10)
	if AchievementUnlocked then
		AchievementUnlocked.OnClientEvent:Connect(function(info)
			if info then
				showAchievementBanner(info.name, info.reward)
			end
		end)
	end
end)

-- Quest completed notification
task.spawn(function()
	local QuestCompleted = Remotes:WaitForChild("QuestCompleted", 10)
	if QuestCompleted then
		QuestCompleted.OnClientEvent:Connect(function(description, reward)
			showFloatingText("Quest Complete! +$" .. Utils.formatCash(reward), Color3.fromRGB(255, 180, 50))
		end)
	end
end)

print("[EffectsManager] Initialized")
