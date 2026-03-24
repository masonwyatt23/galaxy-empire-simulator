--[[
	TycoonManager — Core game loop
	Handles plot assignment, income generation, purchases, and progression.
	All game state lives server-side for security.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create RemoteEvents
local function createRemote(name, className)
	local remote = Instance.new(className or "RemoteEvent")
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

local PurchaseItemRemote = createRemote("PurchaseItem")
local UpdateCashRemote = createRemote("UpdateCash")
local UpdateItemsRemote = createRemote("UpdateItems")
local RequestDataRemote = createRemote("RequestData")
local ItemPurchasedRemote = createRemote("ItemPurchased")

-- Player tycoon state (server-authoritative)
local PlayerData = {} -- [player] = {cash, ownedItems, rebirthCount, ...}
local PlayerPlots = {} -- [player] = plotNumber

-- Track available plots
local AvailablePlots = {}
for i = 1, GameConfig.MaxPlots do
	table.insert(AvailablePlots, i)
end

-- Rate limiting
local lastPurchaseTime = {} -- [player] = tick()

-- Expose PlayerData for other server scripts
_G.TycoonPlayerData = PlayerData
_G.TycoonPlayerPlots = PlayerPlots

-- Initialize player data (called by DataManager after loading)
function _G.InitializePlayerData(player, savedData)
	PlayerData[player] = savedData or {
		cash = GameConfig.StartingCash,
		ownedItems = {},
		rebirthCount = 0,
		totalEarned = 0,
		lastDaily = 0,
		dailyStreak = 0,
		tempBoostExpiry = 0,
	}

	-- Assign a plot
	if #AvailablePlots > 0 then
		local plotNum = table.remove(AvailablePlots, 1)
		PlayerPlots[player] = plotNum
	end

	-- Send initial state to client
	UpdateCashRemote:FireClient(player, PlayerData[player].cash)
	UpdateItemsRemote:FireClient(player, PlayerData[player].ownedItems)
end

-- Get player data (used by other managers)
function _G.GetPlayerData(player)
	return PlayerData[player]
end

-- Add cash to player (used by monetization, rebirth, etc.)
function _G.AddCash(player, amount)
	local data = PlayerData[player]
	if not data then return end
	data.cash = data.cash + amount
	data.totalEarned = data.totalEarned + math.max(0, amount)
	UpdateCashRemote:FireClient(player, data.cash)

	-- Update leaderboard
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cashStat = leaderstats:FindFirstChild("Cash")
		if cashStat then
			cashStat.Value = data.cash
		end
	end
end

-- Get next available item index for player
local function getNextItemIndex(player)
	local data = PlayerData[player]
	if not data then return nil end
	return #data.ownedItems + 1
end

-- Handle item purchase (from client UI button)
local function onPurchaseItem(player, itemIndex)
	local data = PlayerData[player]
	if not data then return end

	-- Rate limit (0.5s cooldown)
	local now = tick()
	if lastPurchaseTime[player] and (now - lastPurchaseTime[player]) < 0.5 then return end
	lastPurchaseTime[player] = now

	-- Validate: must be the next item in sequence
	local nextIndex = getNextItemIndex(player)
	if itemIndex ~= nextIndex then return end

	-- Validate: item exists
	local item = GameConfig.TycoonItems[itemIndex]
	if not item then return end

	-- Validate: player has enough cash
	if data.cash < item.cost then return end

	-- Validate: VIP items require VIP pass
	if item.vip and not (_G.HasGamePass and _G.HasGamePass(player, "VIP")) then return end

	-- Deduct cash and add item
	data.cash = data.cash - item.cost
	table.insert(data.ownedItems, itemIndex)

	-- Notify client
	UpdateCashRemote:FireClient(player, data.cash)
	UpdateItemsRemote:FireClient(player, data.ownedItems)
	ItemPurchasedRemote:FireClient(player, itemIndex, item.name)

	-- Update leaderboard
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cashStat = leaderstats:FindFirstChild("Cash")
		if cashStat then cashStat.Value = data.cash end
	end

	-- Notify PlotManager to show building
	if _G.OnItemPurchased then
		_G.OnItemPurchased(player, itemIndex)
	end
end

-- Handle client data request
local function onRequestData(player)
	local data = PlayerData[player]
	if not data then return end
	UpdateCashRemote:FireClient(player, data.cash)
	UpdateItemsRemote:FireClient(player, data.ownedItems)
end

-- Income tick — runs every IncomeInterval seconds
local incomeAccumulator = 0

RunService.Heartbeat:Connect(function(dt)
	incomeAccumulator = incomeAccumulator + dt

	if incomeAccumulator >= GameConfig.IncomeInterval then
		incomeAccumulator = incomeAccumulator - GameConfig.IncomeInterval

		for player, data in pairs(PlayerData) do
			if player.Parent then -- still in game
				-- Calculate multiplier
				local hasDoubleIncome = false
				local hasTempBoost = false

				-- Check game pass (via _G set by MonetizationManager)
				if _G.HasGamePass and _G.HasGamePass(player, "DoubleIncome") then
					hasDoubleIncome = true
				end

				-- Check temp boost
				if data.tempBoostExpiry and os.time() < data.tempBoostExpiry then
					hasTempBoost = true
				end

				local multiplier = Utils.getIncomeMultiplier(
					data.rebirthCount,
					hasDoubleIncome,
					hasTempBoost,
					GameConfig
				)

				local income = Utils.getTotalIncome(data.ownedItems, multiplier, GameConfig)

				-- Apply exploration bonus (artifacts + trade routes)
				if _G.GetExplorationBonus then
					income = income * _G.GetExplorationBonus(player)
				end

				if income > 0 then
					_G.AddCash(player, math.floor(income))
				end
			end
		end
	end
end)

-- Expose purchase function for PlotManager to call directly
_G.PurchaseTycoonItem = onPurchaseItem

-- Connect events
PurchaseItemRemote.OnServerEvent:Connect(onPurchaseItem)
RequestDataRemote.OnServerEvent:Connect(onRequestData)

-- Auto-purchase first item for new players
local function autoPurchaseFirstItem(player)
	if not GameConfig.AutoPurchaseFirstItem then return end
	local data = PlayerData[player]
	if not data then return end
	if #data.ownedItems == 0 then
		local item = GameConfig.TycoonItems[1]
		if item and item.cost == 0 then
			table.insert(data.ownedItems, 1)
			UpdateItemsRemote:FireClient(player, data.ownedItems)
			ItemPurchasedRemote:FireClient(player, 1, item.name)
			if _G.OnItemPurchased then
				_G.OnItemPurchased(player, 1)
			end
		end
	end
end

-- Auto-buy system (AutoCollect pass = auto-purchases next affordable item)
task.spawn(function()
	while true do
		task.wait(2) -- check every 2 seconds
		for player, data in pairs(PlayerData) do
			if player.Parent and _G.HasGamePass and _G.HasGamePass(player, "AutoCollect") then
				local nextIndex = #data.ownedItems + 1
				local item = GameConfig.TycoonItems[nextIndex]
				if item and data.cash >= item.cost then
					-- VIP check
					if item.vip and not (_G.HasGamePass and _G.HasGamePass(player, "VIP")) then
						continue
					end
					-- Auto-purchase
					data.cash = data.cash - item.cost
					table.insert(data.ownedItems, nextIndex)
					UpdateCashRemote:FireClient(player, data.cash)
					UpdateItemsRemote:FireClient(player, data.ownedItems)
					ItemPurchasedRemote:FireClient(player, nextIndex, item.name)
					-- Update leaderboard
					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats then
						local cashStat = leaderstats:FindFirstChild("Cash")
						if cashStat then cashStat.Value = data.cash end
					end
					if _G.OnItemPurchased then
						_G.OnItemPurchased(player, nextIndex)
					end
				end
			end
		end
	end
end)

-- Auto-purchase first item after player data AND PlotManager are ready
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		-- Wait for data to load
		local elapsed = 0
		while not PlayerData[player] and elapsed < 15 do
			task.wait(0.5)
			elapsed = elapsed + 0.5
		end
		-- Wait for PlotManager to register its callback (not a fixed timer)
		elapsed = 0
		while not _G.OnItemPurchased and elapsed < 10 do
			task.wait(0.5)
			elapsed = elapsed + 0.5
		end
		task.wait(0.5) -- small buffer for plot to finish building
		autoPurchaseFirstItem(player)
	end)
end)

-- Player leaving — free up plot
Players.PlayerRemoving:Connect(function(player)
	local plotNum = PlayerPlots[player]
	if plotNum then
		table.insert(AvailablePlots, plotNum)
		table.sort(AvailablePlots)
	end
	PlayerPlots[player] = nil
	lastPurchaseTime[player] = nil
	-- PlayerData cleanup happens after DataManager saves
	task.delay(5, function()
		PlayerData[player] = nil
	end)
end)

print("[TycoonManager] Initialized")
