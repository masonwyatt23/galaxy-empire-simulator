--[[
	ExplorationManager — 8x8 Galaxy Grid Exploration System
	Seed-based deterministic sector generation with adjacency-gated exploration.
	Rewards include instant credits, permanent income boosts, temp boosts, and trade routes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create RemoteEvents
local ExploreSectorRemote = Instance.new("RemoteEvent")
ExploreSectorRemote.Name = "ExploreSector"
ExploreSectorRemote.Parent = Remotes

local ExplorationResultRemote = Instance.new("RemoteEvent")
ExplorationResultRemote.Name = "ExplorationResult"
ExplorationResultRemote.Parent = Remotes

local ExplorationInfoRemote = Instance.new("RemoteEvent")
ExplorationInfoRemote.Name = "ExplorationInfo"
ExplorationInfoRemote.Parent = Remotes

-- Config
local GRID_SIZE = 8
local EXPLORATION_COOLDOWN = 10 -- seconds
local BASE_COST = GameConfig.Exploration and GameConfig.Exploration.baseCost or 2000
local CENTER_X, CENTER_Y = 4, 4

-- Sector type definitions with cumulative weights for weighted random
local SECTOR_TYPES = {
	{type = "resource_cache", weight = 30},
	{type = "alien_artifact", weight = 15},
	{type = "anomaly",        weight = 20},
	{type = "trade_route",    weight = 10},
	{type = "hostile",        weight = 15},
	{type = "empty",          weight = 10},
}

-- Pre-compute cumulative weights
local CUMULATIVE_WEIGHTS = {}
local totalWeight = 0
for i, sector in ipairs(SECTOR_TYPES) do
	totalWeight = totalWeight + sector.weight
	CUMULATIVE_WEIGHTS[i] = totalWeight
end

-- Rate limiting
local lastExploreTime = {} -- [player] = tick()

-- Poll-wait helper
local function waitForGlobal(name, timeout)
	local elapsed = 0
	while not _G[name] and elapsed < (timeout or 30) do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end
	return _G[name] ~= nil
end

-- Deterministic seed-based sector type generation
local function getSectorType(userId, x, y)
	local seed = (userId * 1000 + x * 100 + y) % 99991

	-- Simple LCG-style deterministic random from seed
	-- Use multiple rounds for better distribution
	local rng = seed
	rng = (rng * 16807 + 0) % 2147483647
	local roll = (rng % totalWeight) + 1

	for i, cumWeight in ipairs(CUMULATIVE_WEIGHTS) do
		if roll <= cumWeight then
			return SECTOR_TYPES[i].type
		end
	end
	return "empty" -- fallback
end

-- Get distance from center for a sector
local function distanceFromCenter(x, y)
	return math.sqrt((x - CENTER_X) ^ 2 + (y - CENTER_Y) ^ 2)
end

-- Get exploration cost for a sector
local function getExploreCost(x, y)
	local dist = distanceFromCenter(x, y)
	return math.floor(BASE_COST * (1 + dist * 0.5))
end

-- Check if a sector is adjacent (including diagonal) to any explored sector
local function isAdjacentToExplored(exploredSectors, x, y)
	for dx = -1, 1 do
		for dy = -1, 1 do
			if dx ~= 0 or dy ~= 0 then
				local key = (x + dx) .. "_" .. (y + dy)
				if exploredSectors[key] then
					return true
				end
			end
		end
	end
	return false
end

-- Validate sector coordinates
local function isValidSector(x, y)
	return x >= 1 and x <= GRID_SIZE and y >= 1 and y <= GRID_SIZE
end

-- Count explored sectors
local function countExplored(exploredSectors)
	local count = 0
	for _ in pairs(exploredSectors) do
		count = count + 1
	end
	return count
end

-- Get the tier index a trade route applies to (deterministic from seed)
local function getTradeRouteTier(userId, x, y)
	local seed = (userId * 1000 + x * 100 + y) % 99991
	local rng = (seed * 48271) % 2147483647
	-- 5 tiers (non-VIP)
	return (rng % 5) + 1
end

-- Process sector exploration rewards
local function processExploration(player, data, sectorType, x, y)
	local result = {
		sectorType = sectorType,
		x = x,
		y = y,
		reward = 0,
		message = "",
	}

	if sectorType == "resource_cache" then
		-- Instant credits: 5K-50K scaled by rebirth
		local seed = (player.UserId * 1000 + x * 100 + y) % 99991
		local rng = (seed * 48271) % 2147483647
		local baseReward = 5000 + (rng % 45001) -- 5K to 50K
		local rebirthScale = 1 + (data.rebirthCount or 0) * 0.5
		local reward = math.floor(baseReward * rebirthScale)
		_G.AddCash(player, reward)
		result.reward = reward
		result.message = "Resource Cache! +" .. Utils.formatCash(reward) .. " credits"

	elseif sectorType == "alien_artifact" then
		-- Permanent +2% income, max 10 artifacts
		if (data.artifactCount or 0) < 10 then
			data.artifactCount = (data.artifactCount or 0) + 1
			result.reward = data.artifactCount * 2
			result.message = "Alien Artifact! Permanent +" .. (data.artifactCount * 2) .. "% income (" .. data.artifactCount .. "/10)"
		else
			-- Already at max, give consolation credits
			local consolation = 10000
			_G.AddCash(player, consolation)
			result.reward = consolation
			result.message = "Artifact Echo! Max artifacts reached. +" .. Utils.formatCash(consolation) .. " credits"
		end

	elseif sectorType == "anomaly" then
		-- Temp 3x boost for 60 seconds
		data.tempBoostExpiry = os.time() + 60
		result.message = "Anomaly! 3x income boost for 60 seconds!"
		result.reward = 0

	elseif sectorType == "trade_route" then
		-- Permanent +5% income from specific tier
		local tier = getTradeRouteTier(player.UserId, x, y)
		local tierKey = "tier_" .. tier
		if not data.tradeRoutes then data.tradeRoutes = {} end
		if not data.tradeRoutes[tierKey] then
			data.tradeRoutes[tierKey] = 0.05
		else
			data.tradeRoutes[tierKey] = data.tradeRoutes[tierKey] + 0.05
		end
		result.message = "Trade Route! Permanent +5% income from Tier " .. tier .. " structures"
		result.reward = 0

	elseif sectorType == "hostile" then
		-- Lose 10% current credits (min 0)
		local loss = math.floor(data.cash * 0.1)
		if loss > 0 then
			_G.AddCash(player, -loss)
		end
		result.reward = -loss
		result.message = "Hostile Territory! Lost " .. Utils.formatCash(loss) .. " credits"

	elseif sectorType == "empty" then
		-- Small consolation: 1K credits
		_G.AddCash(player, 1000)
		result.reward = 1000
		result.message = "Empty Sector. Salvaged 1K credits."
	end

	return result
end

-- Calculate exploration bonus multiplier for income
function _G.GetExplorationBonus(player)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return 1 end

	local bonus = 1 + ((data.artifactCount or 0) * 0.02)

	-- Sum trade route bonuses
	if data.tradeRoutes then
		for _, routeBonus in pairs(data.tradeRoutes) do
			bonus = bonus + routeBonus
		end
	end

	return bonus
end

-- Send full exploration state to client
local function sendExplorationInfo(player)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	-- Ensure exploration data exists
	if not data.exploredSectors then
		data.exploredSectors = {["4_4"] = "start"}
	end
	if not data.artifactCount then
		data.artifactCount = 0
	end
	if not data.tradeRoutes then
		data.tradeRoutes = {}
	end

	-- Build sector type map for explored sectors
	local sectorMap = {}
	for key, sType in pairs(data.exploredSectors) do
		sectorMap[key] = sType
	end

	-- Build cost map for unexplored but adjacent sectors
	local costMap = {}
	for x = 1, GRID_SIZE do
		for y = 1, GRID_SIZE do
			local key = x .. "_" .. y
			if not data.exploredSectors[key] and isAdjacentToExplored(data.exploredSectors, x, y) then
				costMap[key] = getExploreCost(x, y)
			end
		end
	end

	ExplorationInfoRemote:FireClient(player, {
		exploredSectors = sectorMap,
		artifactCount = data.artifactCount,
		tradeRoutes = data.tradeRoutes,
		costMap = costMap,
		totalSectors = GRID_SIZE * GRID_SIZE,
		exploredCount = countExplored(data.exploredSectors),
	})
end

-- Handle exploration request from client
local function onExploreSector(player, x, y)
	-- Validate input types
	if type(x) ~= "number" or type(y) ~= "number" then return end

	-- Validate integers
	x = math.floor(x)
	y = math.floor(y)

	-- Validate sector bounds
	if not isValidSector(x, y) then return end

	-- Get player data
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	-- Ensure exploration data exists
	if not data.exploredSectors then
		data.exploredSectors = {["4_4"] = "start"}
	end
	if not data.artifactCount then data.artifactCount = 0 end
	if not data.tradeRoutes then data.tradeRoutes = {} end

	local key = x .. "_" .. y

	-- Validate: not already explored
	if data.exploredSectors[key] then return end

	-- Validate: adjacent to an explored sector
	if not isAdjacentToExplored(data.exploredSectors, x, y) then return end

	-- Rate limit (cooldown)
	local now = tick()
	if lastExploreTime[player] and (now - lastExploreTime[player]) < EXPLORATION_COOLDOWN then return end

	-- Check cost
	local cost = getExploreCost(x, y)
	if data.cash < cost then return end

	-- Deduct cost
	_G.AddCash(player, -cost)
	lastExploreTime[player] = now

	-- Determine sector type
	local sectorType = getSectorType(player.UserId, x, y)

	-- Mark as explored
	data.exploredSectors[key] = sectorType

	-- Process rewards
	local result = processExploration(player, data, sectorType, x, y)

	-- Send result to client
	ExplorationResultRemote:FireClient(player, result)

	-- Send updated exploration info
	sendExplorationInfo(player)

	print("[Exploration] " .. player.Name .. " explored sector " .. key .. " (" .. sectorType .. ")")
end

-- Connect events
ExploreSectorRemote.OnServerEvent:Connect(onExploreSector)

-- Wait for dependencies before initializing
task.spawn(function()
	waitForGlobal("GetPlayerData", 30)
	waitForGlobal("AddCash", 30)

	-- Send exploration info to players when they join (after data loads)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			-- Wait for player data to load
			local elapsed = 0
			while not (_G.GetPlayerData and _G.GetPlayerData(player)) and elapsed < 15 do
				task.wait(0.5)
				elapsed = elapsed + 0.5
			end
			sendExplorationInfo(player)
		end)
	end)

	-- Handle players already in game (Studio testing)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			local elapsed = 0
			while not (_G.GetPlayerData and _G.GetPlayerData(player)) and elapsed < 15 do
				task.wait(0.5)
				elapsed = elapsed + 0.5
			end
			sendExplorationInfo(player)
		end)
	end
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	lastExploreTime[player] = nil
end)

print("[ExplorationManager] Initialized")
