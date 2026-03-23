--[[
	QuestManager — Daily quest system
	3 daily quests randomly selected from pool, reset every 24h.
	Hooks into _G.AddCash, _G.OnItemPurchased, _G.DoRebirth for progress tracking.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remotes
local QuestInfoRemote = Instance.new("RemoteEvent")
QuestInfoRemote.Name = "QuestInfo"
QuestInfoRemote.Parent = Remotes

local QuestCompletedRemote = Instance.new("RemoteEvent")
QuestCompletedRemote.Name = "QuestCompleted"
QuestCompletedRemote.Parent = Remotes

local ClaimQuestRemote = Instance.new("RemoteEvent")
ClaimQuestRemote.Name = "ClaimQuestReward"
ClaimQuestRemote.Parent = Remotes

local DAY_SECONDS = 86400

-- Generate 3 random quests for a player
local function generateQuests(rebirthCount)
	local pool = GameConfig.QuestPool
	if not pool or #pool == 0 then return {} end

	-- Shuffle and pick 3
	local indices = {}
	for i = 1, #pool do table.insert(indices, i) end

	-- Fisher-Yates shuffle
	for i = #indices, 2, -1 do
		local j = math.random(1, i)
		indices[i], indices[j] = indices[j], indices[i]
	end

	local quests = {}
	for i = 1, math.min(3, #indices) do
		local template = pool[indices[i]]
		local scaleFactor = 1 + (rebirthCount or 0) * 0.5
		local target = math.floor(template.baseTarget * scaleFactor)
		-- Cap reach_item at max items to prevent impossible quests
		if template.type == "reach_item" then
			target = math.min(target, #GameConfig.TycoonItems)
		end
		local reward = math.floor(target * template.rewardMult)

		table.insert(quests, {
			type = template.type,
			description = string.format(template.description, Utils.formatCash(target)),
			target = target,
			progress = 0,
			reward = reward,
			claimed = false,
		})
	end

	return quests
end

-- Check if quests need reset
local function checkQuestReset(data)
	if not data then return end
	local now = os.time()
	if now - (data.lastQuestReset or 0) >= DAY_SECONDS or not data.dailyQuests or #data.dailyQuests == 0 then
		data.dailyQuests = generateQuests(data.rebirthCount)
		data.lastQuestReset = now
		return true
	end
	return false
end

-- Send quest info to client
local function sendQuestInfo(player)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	checkQuestReset(data)

	local timeUntilReset = math.max(0, DAY_SECONDS - (os.time() - (data.lastQuestReset or 0)))
	QuestInfoRemote:FireClient(player, {
		quests = data.dailyQuests,
		timeUntilReset = timeUntilReset,
	})
end

-- Update quest progress for a player
local function updateQuestProgress(player, questType, amount)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data or not data.dailyQuests then return end

	for i, quest in ipairs(data.dailyQuests) do
		if quest.type == questType and not quest.claimed then
			quest.progress = quest.progress + amount
			if quest.progress >= quest.target and quest.progress - amount < quest.target then
				-- Just completed
				QuestCompletedRemote:FireClient(player, quest.description, quest.reward)
			end
		end
	end

	sendQuestInfo(player)
end

-- Claim quest reward
ClaimQuestRemote.OnServerEvent:Connect(function(player, questIndex)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data or not data.dailyQuests then return end

	if type(questIndex) ~= "number" then return end
	local quest = data.dailyQuests[questIndex]
	if not quest then return end
	if quest.claimed then return end
	if quest.progress < quest.target then return end

	quest.claimed = true
	if _G.AddCash then
		_G.AddCash(player, quest.reward)
	end

	sendQuestInfo(player)
end)

-- Hook into game events for progress tracking
-- Wait for _G functions to be registered by other scripts before wrapping
task.spawn(function()
	-- Wait for TycoonManager to register _G.AddCash
	local elapsed = 0
	while not _G.AddCash and elapsed < 30 do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end

	if not _G.AddCash then
		warn("[QuestManager] _G.AddCash never registered, quest tracking disabled")
		return
	end

	-- Cash earned tracking
	local originalAddCash = _G.AddCash
	_G.AddCash = function(player, amount)
		originalAddCash(player, amount)
		if amount > 0 then
			updateQuestProgress(player, "earn_cash", amount)
		end
	end

	-- Wait for PlotManager to register OnItemPurchased before wrapping
	elapsed = 0
	while not _G.OnItemPurchased and elapsed < 30 do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end

	-- Item purchased tracking
	local originalOnItemPurchased = _G.OnItemPurchased
	_G.OnItemPurchased = function(player, itemIndex)
		if originalOnItemPurchased then
			originalOnItemPurchased(player, itemIndex)
		end
		updateQuestProgress(player, "buy_items", 1)
		-- Update reach_item progress directly (uses item count, not delta)
		local data = _G.GetPlayerData and _G.GetPlayerData(player)
		if data and data.dailyQuests then
			for _, quest in ipairs(data.dailyQuests) do
				if quest.type == "reach_item" and not quest.claimed then
					local prev = quest.progress
					quest.progress = #data.ownedItems
					if quest.progress >= quest.target and prev < quest.target then
						QuestCompletedRemote:FireClient(player, quest.description, quest.reward)
					end
				end
			end
			sendQuestInfo(player)
		end
	end

	-- Rebirth tracking
	elapsed = 0
	while not _G.DoRebirth and elapsed < 30 do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end

	if _G.DoRebirth then
		local originalDoRebirth = _G.DoRebirth
		_G.DoRebirth = function(player, skipCostCheck)
			local result = originalDoRebirth(player, skipCostCheck)
			if result then
				updateQuestProgress(player, "rebirth", 1)
			end
			return result
		end
	end

	print("[QuestManager] Event hooks registered")
end)

-- Player join
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		local elapsed = 0
		while not (_G.GetPlayerData and _G.GetPlayerData(player)) and elapsed < 15 do
			task.wait(0.5)
			elapsed = elapsed + 0.5
		end
		task.wait(2)
		sendQuestInfo(player)
	end)
end)

-- Play time tracking (every 60 seconds)
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			updateQuestProgress(player, "play_time", 1)
		end
	end
end)

-- Periodic refresh
task.spawn(function()
	while true do
		task.wait(30)
		for _, player in ipairs(Players:GetPlayers()) do
			sendQuestInfo(player)
		end
	end
end)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		local elapsed = 0
		while not (_G.GetPlayerData and _G.GetPlayerData(player)) and elapsed < 15 do
			task.wait(0.5)
			elapsed = elapsed + 0.5
		end
		task.wait(2)
		sendQuestInfo(player)
	end)
end

print("[QuestManager] Initialized")
