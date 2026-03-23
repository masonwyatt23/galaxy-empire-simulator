--[[
	CodeManager — Promo code redemption system
	Players enter codes for cash rewards. Each code can only be redeemed once per player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remotes
local RedeemCodeRemote = Instance.new("RemoteEvent")
RedeemCodeRemote.Name = "RedeemCode"
RedeemCodeRemote.Parent = Remotes

local CodeResultRemote = Instance.new("RemoteEvent")
CodeResultRemote.Name = "CodeResult"
CodeResultRemote.Parent = Remotes

-- Rate limiting
local lastCodeTime = {} -- [player] = tick()

-- Handle code redemption
RedeemCodeRemote.OnServerEvent:Connect(function(player, codeInput)
	-- Validate input type
	if type(codeInput) ~= "string" then return end

	-- Rate limit (1s cooldown)
	local now = tick()
	if lastCodeTime[player] and (now - lastCodeTime[player]) < 1 then
		CodeResultRemote:FireClient(player, false, "Too fast! Wait a moment.")
		return
	end
	lastCodeTime[player] = now

	-- Get player data
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then
		CodeResultRemote:FireClient(player, false, "Error: Player data not loaded.")
		return
	end

	-- Normalize code (uppercase, trim whitespace)
	local code = string.upper(string.gsub(codeInput, "%s+", ""))

	-- Check if code exists
	local reward = GameConfig.Codes[code]
	if not reward then
		CodeResultRemote:FireClient(player, false, "Invalid code!")
		return
	end

	-- Check if already redeemed
	if data.redeemedCodes and data.redeemedCodes[code] then
		CodeResultRemote:FireClient(player, false, "Already redeemed!")
		return
	end

	-- Initialize redeemedCodes if needed
	if not data.redeemedCodes then
		data.redeemedCodes = {}
	end

	-- Grant reward and mark as redeemed
	data.redeemedCodes[code] = true
	if _G.AddCash then
		_G.AddCash(player, reward)
	end

	CodeResultRemote:FireClient(player, true, "Redeemed! +$" .. tostring(reward))
	print("[CodeManager] " .. player.Name .. " redeemed code: " .. code .. " for $" .. reward)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	lastCodeTime[player] = nil
end)

print("[CodeManager] Initialized")
