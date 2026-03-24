--[[
	SoundManager — Audio feedback system
	Plays sounds for purchases, rebirths, milestones, and ambient music.
	Uses Roblox built-in sound assets.
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local ItemPurchased = Remotes:WaitForChild("ItemPurchased", 15)
local RebirthSuccess = Remotes:WaitForChild("RebirthSuccess", 15)
local BuildingAppeared = Remotes:WaitForChild("BuildingAppeared", 15)
local UpdateCash = Remotes:WaitForChild("UpdateCash", 15)

local player = Players.LocalPlayer

-- Sound library (Roblox built-in asset IDs)
local Sounds = {}

local function createSound(name, assetId, volume, looped)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. assetId
	sound.Volume = volume or 0.5
	sound.Looped = looped or false
	sound.Parent = SoundService
	Sounds[name] = sound
	return sound
end

-- Create all sounds with varied Roblox library audio
createSound("Purchase",      9125402735, 0.4)     -- Cash register cha-ching
createSound("BuildingPop",   9125786610, 0.3)     -- Pop/whoosh
createSound("Rebirth",       9125836726, 0.6)     -- Epic fanfare
createSound("Milestone",     9125402735, 0.5)     -- Cash celebration
createSound("ButtonClick",   6895079853, 0.15)    -- UI click
createSound("DailyReward",   9125836726, 0.5)     -- Reward jingle
createSound("CodeSuccess",   9125402735, 0.4)     -- Success ding
createSound("Achievement",   9125836726, 0.6)     -- Achievement fanfare
createSound("TradeReceived", 9125402735, 0.5)     -- Gift received
createSound("StockBuy",      6895079853, 0.3)     -- Stock trade click

-- Background music (ambient upbeat loop)
local bgMusic = createSound("BackgroundMusic", 1837849285, 0.12, true)

-- Start background music after delay
task.spawn(function()
	task.wait(3)
	bgMusic:Play()
end)

-- Volume control exposed globally
_G.SetMusicVolume = function(vol)
	bgMusic.Volume = math.clamp(vol, 0, 1)
end

-- Play a sound by name
local function playSound(name)
	local sound = Sounds[name]
	if sound then
		-- Clone to allow overlapping sounds
		if sound.Looped then
			sound:Play()
		else
			local clone = sound:Clone()
			clone.Parent = SoundService
			clone:Play()
			clone.Ended:Connect(function()
				clone:Destroy()
			end)
		end
	end
end

-- Cash milestone tracking
local lastCash = 0
local milestones = {1000, 5000, 10000, 50000, 100000, 500000, 1000000, 5000000, 10000000}
local reachedMilestones = {}

local function checkMilestone(newCash)
	for _, threshold in ipairs(milestones) do
		if newCash >= threshold and not reachedMilestones[threshold] and lastCash < threshold then
			reachedMilestones[threshold] = true
			playSound("Milestone")
		end
	end
	lastCash = newCash
end

-- Event listeners
ItemPurchased.OnClientEvent:Connect(function()
	playSound("Purchase")
end)

BuildingAppeared.OnClientEvent:Connect(function()
	playSound("BuildingPop")
end)

RebirthSuccess.OnClientEvent:Connect(function()
	playSound("Rebirth")
	-- Reset milestones on rebirth
	reachedMilestones = {}
	lastCash = 0
end)

UpdateCash.OnClientEvent:Connect(function(cash)
	checkMilestone(cash)
end)

-- Listen for achievement unlock
task.spawn(function()
	local AchievementUnlocked = Remotes:WaitForChild("AchievementUnlocked", 10)
	if AchievementUnlocked then
		AchievementUnlocked.OnClientEvent:Connect(function()
			playSound("Achievement")
		end)
	end
end)

-- Listen for daily reward claim
task.spawn(function()
	local DailyRewardInfo = Remotes:WaitForChild("DailyRewardInfo", 10)
	if DailyRewardInfo then
		DailyRewardInfo.OnClientEvent:Connect(function(info)
			if info and not info.canClaim then
				-- Just claimed
				playSound("DailyReward")
			end
		end)
	end
end)

-- Listen for code result
task.spawn(function()
	local CodeResult = Remotes:WaitForChild("CodeResult", 10)
	if CodeResult then
		CodeResult.OnClientEvent:Connect(function(success)
			if success then
				playSound("CodeSuccess")
			end
		end)
	end
end)

-- Hook into button clicks (global function for other UIs to call)
_G.PlayButtonClick = function()
	playSound("ButtonClick")
end

print("[SoundManager] Initialized")
