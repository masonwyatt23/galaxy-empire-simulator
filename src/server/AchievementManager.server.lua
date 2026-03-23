--[[
	AchievementManager — Milestone achievement system
	Checks achievement triggers and grants rewards + notifications.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remote
local AchievementUnlockedRemote = Instance.new("RemoteEvent")
AchievementUnlockedRemote.Name = "AchievementUnlocked"
AchievementUnlockedRemote.Parent = Remotes

-- Check achievements for a player
local function checkAchievements(player)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	if not data.achievements then
		data.achievements = {}
	end

	for _, achievement in ipairs(GameConfig.Achievements) do
		-- Skip already earned
		if data.achievements[achievement.id] then continue end

		local earned = false

		if achievement.trigger == "items" then
			earned = #data.ownedItems >= achievement.threshold
		elseif achievement.trigger == "rebirths" then
			earned = data.rebirthCount >= achievement.threshold
		elseif achievement.trigger == "totalEarned" then
			earned = data.totalEarned >= achievement.threshold
		end

		if earned then
			data.achievements[achievement.id] = true

			-- Grant reward
			if _G.AddCash and achievement.reward then
				_G.AddCash(player, achievement.reward)
			end

			-- Notify client
			AchievementUnlockedRemote:FireClient(player, {
				name = achievement.name,
				reward = achievement.reward,
			})

			print("[Achievement] " .. player.Name .. " unlocked: " .. achievement.name)
		end
	end
end

-- Check periodically (catches totalEarned milestones)
-- Initial delay prevents achievement spam on first load
task.spawn(function()
	task.wait(20) -- let players settle in before first check
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			checkAchievements(player)
		end
		task.wait(10)
	end
end)

-- Also check on item purchase and rebirth via events
-- These are already hooked by QuestManager which wraps _G functions
-- The periodic check catches everything

print("[AchievementManager] Initialized")
