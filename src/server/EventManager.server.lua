--[[
	EventManager — Scheduled admin events for tycoon games
	Drives player spikes at predictable times. Free giveaways create FOMO + habit.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EventInfoRemote = Instance.new("RemoteEvent")
EventInfoRemote.Name = "EventInfo"
EventInfoRemote.Parent = Remotes

-- Event schedule (UTC times)
-- dayOfWeek: 1=Sunday, 7=Saturday
local EVENTS = {
	{name = "Free 2x Boost",   dayOfWeek = 7, hour = 20, duration = 7200, reward = "2x_income"},
	{name = "Double Rewards",   dayOfWeek = 4, hour = 0,  duration = 3600, reward = "2x_rewards"},
	{name = "Free Rebirth",     dayOfWeek = 1, hour = 17, duration = 1800, reward = "free_rebirth"},
	{name = "Mystery Gift",     dayOfWeek = 6, hour = 1,  duration = 900,  reward = "mystery"},
}

local activeEvent = nil
local activeEventEndTime = 0

-- Global check function for other scripts
function _G.EventActive(rewardType)
	if activeEvent and os.time() < activeEventEndTime then
		return activeEvent.reward == rewardType
	end
	return false
end

local function getUTCTimeInfo()
	local utcTime = os.time()
	local utcDate = os.date("!*t", utcTime)
	return utcDate.wday, utcDate.hour, utcTime
end

local function getNextEvent()
	local wday, hour, now = getUTCTimeInfo()
	local bestEvent = nil
	local bestTimeUntil = math.huge

	for _, event in ipairs(EVENTS) do
		local daysUntil = (event.dayOfWeek - wday) % 7
		if daysUntil == 0 and hour >= event.hour then
			local eventStart = now - (hour - event.hour) * 3600 - (os.date("!*t", now).min * 60) - os.date("!*t", now).sec
			if now < eventStart + event.duration then
				return event, 0, eventStart + event.duration - now
			end
			daysUntil = 7
		end
		local secondsUntil = (daysUntil * 24 + (event.hour - hour)) * 3600
		if secondsUntil < 0 then secondsUntil = secondsUntil + 604800 end
		if secondsUntil < bestTimeUntil then
			bestTimeUntil = secondsUntil
			bestEvent = event
		end
	end
	return bestEvent, bestTimeUntil, 0
end

local function broadcastEventInfo()
	local event, timeUntil, timeRemaining = getNextEvent()
	if timeUntil == 0 and event then
		activeEvent = event
		activeEventEndTime = os.time() + timeRemaining

		-- Apply event effects
		if event.reward == "free_rebirth" then
			for _, player in ipairs(Players:GetPlayers()) do
				if _G.DoRebirth then
					_G.DoRebirth(player, true)
				end
			end
		elseif event.reward == "mystery" then
			for _, player in ipairs(Players:GetPlayers()) do
				local gift = math.random(1, 3)
				if gift == 1 and _G.AddCash then
					_G.AddCash(player, 25000)
				elseif gift == 2 then
					local data = _G.GetPlayerData and _G.GetPlayerData(player)
					if data then data.tempBoostExpiry = os.time() + 600 end
				elseif gift == 3 and _G.AddCash then
					_G.AddCash(player, 50000)
				end
			end
		end

		EventInfoRemote:FireAllClients({
			active = true,
			name = event.name,
			reward = event.reward,
			timeRemaining = timeRemaining,
		})
	else
		activeEvent = nil
		EventInfoRemote:FireAllClients({
			active = false,
			nextEventName = event and event.name or "None",
			timeUntilNext = timeUntil,
		})
	end
end

task.spawn(function()
	while true do
		broadcastEventInfo()
		task.wait(30)
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.wait(5)
	local event, timeUntil, timeRemaining = getNextEvent()
	if timeUntil == 0 and event then
		EventInfoRemote:FireClient(player, {active = true, name = event.name, reward = event.reward, timeRemaining = timeRemaining})
	else
		EventInfoRemote:FireClient(player, {active = false, nextEventName = event and event.name or "None", timeUntilNext = timeUntil})
	end
end)

print("[EventManager] Initialized — scheduled events active")
