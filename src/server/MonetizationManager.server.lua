--[[
	MonetizationManager — Game Passes & Developer Products
	Handles purchases, receipt processing, and benefit application.
	All validation server-side.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GamePassConfig = require(Shared:WaitForChild("GamePassConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remotes for shop
local PromptGamePassRemote = Instance.new("RemoteEvent")
PromptGamePassRemote.Name = "PromptGamePass"
PromptGamePassRemote.Parent = Remotes

local PromptProductRemote = Instance.new("RemoteEvent")
PromptProductRemote.Name = "PromptProduct"
PromptProductRemote.Parent = Remotes

local GamePassStatusRemote = Instance.new("RemoteEvent")
GamePassStatusRemote.Name = "GamePassStatus"
GamePassStatusRemote.Parent = Remotes

-- Cache of owned game passes per player
local GamePassCache = {} -- [player] = {passKey = true/false}

-- Check if player owns a game pass
function _G.HasGamePass(player, passKey)
	local cache = GamePassCache[player]
	if cache then
		return cache[passKey] == true
	end
	return false
end

-- Check all game passes for a player
local function checkGamePasses(player)
	GamePassCache[player] = {}

	for passKey, passInfo in pairs(GamePassConfig.Passes) do
		if passInfo.id > 0 then
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passInfo.id)
			end)
			if success and owns then
				GamePassCache[player][passKey] = true
			end
		end
	end

	-- Apply speed boost if owned
	if GamePassCache[player].SpeedBoost then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16 * GamePassConfig.Passes.SpeedBoost.speedMultiplier
			end
		end
	end

	-- Send status to client
	GamePassStatusRemote:FireClient(player, GamePassCache[player])
end

-- Handle game pass purchase prompt from client
PromptGamePassRemote.OnServerEvent:Connect(function(player, passKey)
	local passInfo = GamePassConfig.Passes[passKey]
	if not passInfo or passInfo.id == 0 then return end

	MarketplaceService:PromptGamePassPurchase(player, passInfo.id)
end)

-- Handle developer product purchase prompt from client
PromptProductRemote.OnServerEvent:Connect(function(player, productKey)
	local productInfo = GamePassConfig.Products[productKey]
	if not productInfo or productInfo.id == 0 then return end

	MarketplaceService:PromptProductPurchase(player, productInfo.id)
end)

-- Game pass purchased callback
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if not purchased then return end

	-- Update cache
	for passKey, passInfo in pairs(GamePassConfig.Passes) do
		if passInfo.id == gamePassId then
			GamePassCache[player] = GamePassCache[player] or {}
			GamePassCache[player][passKey] = true

			-- Apply speed boost immediately
			if passKey == "SpeedBoost" then
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.WalkSpeed = 16 * passInfo.speedMultiplier
					end
				end
			end

			-- Update client
			GamePassStatusRemote:FireClient(player, GamePassCache[player])
			break
		end
	end
end)

-- Developer product receipt processing
local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Find which product was purchased
	for productKey, productInfo in pairs(GamePassConfig.Products) do
		if productInfo.id == receiptInfo.ProductId then

			if productKey == "SmallCashPack" or productKey == "LargeCashPack" then
				if _G.AddCash then
					_G.AddCash(player, productInfo.cashAmount)
				else
					return Enum.ProductPurchaseDecision.NotProcessedYet
				end

			elseif productKey == "InstantRebirth" then
				if _G.DoRebirth then
					_G.DoRebirth(player, true) -- true = skip cost check
				end

			elseif productKey == "TemporaryBoost" then
				data.tempBoostExpiry = os.time() + productInfo.duration
			end

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.ProcessReceipt = processReceipt

-- Poll-wait for player data with timeout
local function waitForPlayerData(player, timeout)
	local elapsed = 0
	while not _G.GetPlayerData(player) and elapsed < (timeout or 15) do
		task.wait(0.5)
		elapsed = elapsed + 0.5
	end
	return _G.GetPlayerData(player) ~= nil
end

-- Player joined — check passes
Players.PlayerAdded:Connect(function(player)
	-- Wait for data to actually be ready (not a fixed timer)
	if not waitForPlayerData(player, 15) then
		warn("[MonetizationManager] Timed out waiting for player data: " .. player.Name)
		return
	end
	checkGamePasses(player)

	-- Re-apply speed boost on respawn
	player.CharacterAdded:Connect(function(character)
		if _G.HasGamePass(player, "SpeedBoost") then
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.WalkSpeed = 16 * GamePassConfig.Passes.SpeedBoost.speedMultiplier
		end
	end)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	GamePassCache[player] = nil
end)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		if not waitForPlayerData(player, 15) then return end
		checkGamePasses(player)
	end)
end

print("[MonetizationManager] Initialized")
