--[[
	DailyRewardManager — Daily login reward system
	7-day streak with escalating rewards. Resets if player misses 2 days.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remotes
local DailyRewardInfoRemote = Instance.new("RemoteEvent")
DailyRewardInfoRemote.Name = "DailyRewardInfo"
DailyRewardInfoRemote.Parent = Remotes

local ClaimDailyRemote = Instance.new("RemoteEvent")
ClaimDailyRemote.Name = "ClaimDailyReward"
ClaimDailyRemote.Parent = Remotes

local DAY_SECONDS = 86400

-- Rate limit: one claim per session
local claimedThisSession = {} -- [player] = true

-- Send daily reward info to client
local function sendDailyInfo(player)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	local now = os.time()
	local timeSinceLast = now - (data.lastDaily or 0)
	local canClaim = timeSinceLast >= DAY_SECONDS and not claimedThisSession[player]

	-- Calculate what streak would be if claimed now
	local displayStreak = data.dailyStreak or 0
	if timeSinceLast > DAY_SECONDS * 2 then
		displayStreak = 0 -- streak would reset
	end

	DailyRewardInfoRemote:FireClient(player, {
		canClaim = canClaim,
		streak = displayStreak,
		rewards = GameConfig.DailyRewards,
		timeUntilNext = math.max(0, DAY_SECONDS - timeSinceLast),
	})
end

-- Handle claim request
ClaimDailyRemote.OnServerEvent:Connect(function(player)
	-- Rate limit
	if claimedThisSession[player] then return end

	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	local now = os.time()
	local timeSinceLast = now - (data.lastDaily or 0)

	-- Must be 24h+ since last claim
	if timeSinceLast < DAY_SECONDS then return end

	-- Reset streak if missed more than 48h
	if timeSinceLast > DAY_SECONDS * 2 then
		data.dailyStreak = 0
	end

	-- Increment streak (wraps 1-7)
	data.dailyStreak = (data.dailyStreak % 7) + 1
	data.lastDaily = now

	-- Grant reward
	local reward = GameConfig.DailyRewards[data.dailyStreak] or GameConfig.DailyRewards[1]
	if _G.AddCash then
		_G.AddCash(player, reward)
	end

	claimedThisSession[player] = true

	-- Send updated info
	sendDailyInfo(player)
	print("[DailyReward] " .. player.Name .. " claimed Day " .. data.dailyStreak .. " reward: $" .. reward)
end)

-- Player joined
Players.PlayerAdded:Connect(function(player)
	-- Wait for player data
	local elapsed = 0
	while not (_G.GetPlayerData and _G.GetPlayerData(player)) and elapsed < 15 do
		task.wait(0.5)
		elapsed = elapsed + 0.5
	end
	task.wait(1) -- extra delay so UI is ready
	sendDailyInfo(player)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	claimedThisSession[player] = nil
end)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		local elapsed = 0
		while not (_G.GetPlayerData and _G.GetPlayerData(player)) and elapsed < 15 do
			task.wait(0.5)
			elapsed = elapsed + 0.5
		end
		task.wait(1)
		sendDailyInfo(player)
	end)
end

print("[DailyRewardManager] Initialized")
