--[[
	RebirthManager — Prestige system
	Players reset progress for permanent income multipliers.
	Key retention mechanic that extends game lifespan.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Forward declarations
local sendRebirthInfo

-- Rate limiting
local lastRebirthTime = {} -- [player] = tick()

-- Create remotes
local RebirthRemote = Instance.new("RemoteEvent")
RebirthRemote.Name = "RequestRebirth"
RebirthRemote.Parent = Remotes

local RebirthInfoRemote = Instance.new("RemoteEvent")
RebirthInfoRemote.Name = "RebirthInfo"
RebirthInfoRemote.Parent = Remotes

local RebirthSuccessRemote = Instance.new("RemoteEvent")
RebirthSuccessRemote.Name = "RebirthSuccess"
RebirthSuccessRemote.Parent = Remotes

-- Perform rebirth
function _G.DoRebirth(player, skipCostCheck)
	local data = _G.GetPlayerData(player)
	if not data then return false end

	-- Check max rebirths
	if data.rebirthCount >= GameConfig.Rebirth.maxRebirths then return false end

	-- Check cost (unless purchased via dev product)
	local cost = Utils.getRebirthCost(data.rebirthCount, GameConfig)
	if not skipCostCheck and data.cash < cost then return false end

	-- Reset progress
	if not skipCostCheck then
		data.cash = 0
	end
	data.ownedItems = {}
	data.rebirthCount = data.rebirthCount + 1

	-- Update client
	local UpdateCashRemote = Remotes:FindFirstChild("UpdateCash")
	local UpdateItemsRemote = Remotes:FindFirstChild("UpdateItems")

	if UpdateCashRemote then
		UpdateCashRemote:FireClient(player, data.cash)
	end
	if UpdateItemsRemote then
		UpdateItemsRemote:FireClient(player, data.ownedItems)
	end

	-- Send rebirth info
	RebirthSuccessRemote:FireClient(player, data.rebirthCount)
	sendRebirthInfo(player)

	-- Update leaderboard
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cashStat = leaderstats:FindFirstChild("Cash")
		if cashStat then cashStat.Value = data.cash end
		local rebirthStat = leaderstats:FindFirstChild("Rebirths")
		if rebirthStat then rebirthStat.Value = data.rebirthCount end
	end

	-- Notify PlotManager to reset buildings
	if _G.OnRebirth then
		_G.OnRebirth(player)
	end

	print("[RebirthManager] " .. player.Name .. " rebirthed! Count: " .. data.rebirthCount)
	return true
end

-- Send rebirth info to client (cost, current count, multiplier)
sendRebirthInfo = function(player)
	local data = _G.GetPlayerData(player)
	if not data then return end

	local cost = Utils.getRebirthCost(data.rebirthCount, GameConfig)
	local multiplier = GameConfig.Rebirth.incomeMultiplier ^ data.rebirthCount
	local nextMultiplier = GameConfig.Rebirth.incomeMultiplier ^ (data.rebirthCount + 1)

	RebirthInfoRemote:FireClient(player, {
		count = data.rebirthCount,
		cost = cost,
		currentMultiplier = multiplier,
		nextMultiplier = nextMultiplier,
		maxRebirths = GameConfig.Rebirth.maxRebirths,
	})
end

-- Handle rebirth request (with rate limiting)
RebirthRemote.OnServerEvent:Connect(function(player)
	local now = tick()
	if lastRebirthTime[player] and (now - lastRebirthTime[player]) < 2 then return end
	lastRebirthTime[player] = now
	_G.DoRebirth(player, false)
end)

-- Cleanup rate limit on leave
Players.PlayerRemoving:Connect(function(player)
	lastRebirthTime[player] = nil
end)

-- Send rebirth info when requested and periodically
Players.PlayerAdded:Connect(function(player)
	task.wait(3) -- wait for data to load
	sendRebirthInfo(player)
end)

-- Update rebirth info when cash changes (so UI can show affordability)
task.spawn(function()
	while true do
		task.wait(5)
		for _, player in ipairs(Players:GetPlayers()) do
			sendRebirthInfo(player)
		end
	end
end)

print("[RebirthManager] Initialized")
