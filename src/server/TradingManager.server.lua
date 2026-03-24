--[[
	TradingManager — Player-to-player cash gifting
	Allows sending cash to other players with a 10% tax.
	Server-authoritative with rate limiting and validation.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remotes
local SendGiftRemote = Instance.new("RemoteEvent")
SendGiftRemote.Name = "SendGift"
SendGiftRemote.Parent = Remotes

local GiftResultRemote = Instance.new("RemoteEvent")
GiftResultRemote.Name = "GiftResult"
GiftResultRemote.Parent = Remotes

local GiftReceivedRemote = Instance.new("RemoteEvent")
GiftReceivedRemote.Name = "GiftReceived"
GiftReceivedRemote.Parent = Remotes

-- Rate limiting
local TAX_RATE = 0.10 -- 10% tax
local MIN_GIFT = 100
local MAX_GIFT = 1000000
local COOLDOWN = 5 -- seconds between gifts
local lastGiftTime = {} -- [player] = tick()

SendGiftRemote.OnServerEvent:Connect(function(sender, recipientName, amount)
	-- Validate types
	if type(recipientName) ~= "string" or type(amount) ~= "number" then return end

	-- Rate limit
	local now = tick()
	if lastGiftTime[sender] and (now - lastGiftTime[sender]) < COOLDOWN then
		GiftResultRemote:FireClient(sender, false, "Please wait before sending another gift.")
		return
	end

	-- Validate amount
	amount = math.floor(amount)
	if amount < MIN_GIFT then
		GiftResultRemote:FireClient(sender, false, "Minimum gift is $" .. MIN_GIFT)
		return
	end
	if amount > MAX_GIFT then
		GiftResultRemote:FireClient(sender, false, "Maximum gift is $1M")
		return
	end

	-- Find recipient
	local recipient = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == recipientName and p ~= sender then
			recipient = p
			break
		end
	end

	if not recipient then
		GiftResultRemote:FireClient(sender, false, "Player not found.")
		return
	end

	-- Validate sender has enough cash
	local senderData = _G.GetPlayerData and _G.GetPlayerData(sender)
	if not senderData or senderData.cash < amount then
		GiftResultRemote:FireClient(sender, false, "Not enough cash!")
		return
	end

	-- Validate recipient exists in data
	local recipientData = _G.GetPlayerData and _G.GetPlayerData(recipient)
	if not recipientData then
		GiftResultRemote:FireClient(sender, false, "Recipient data not loaded.")
		return
	end

	-- Process gift with tax
	local tax = math.floor(amount * TAX_RATE)
	local received = amount - tax

	-- Deduct from sender (use negative AddCash)
	if _G.AddCash then
		_G.AddCash(sender, -amount)
		_G.AddCash(recipient, received)
	end

	lastGiftTime[sender] = now

	-- Notify both players
	GiftResultRemote:FireClient(sender, true, "Sent $" .. received .. " to " .. recipient.Name .. " (10% tax: $" .. tax .. ")")
	GiftReceivedRemote:FireClient(recipient, sender.Name, received)

	print("[TradingManager] " .. sender.Name .. " sent $" .. received .. " to " .. recipient.Name)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	lastGiftTime[player] = nil
end)

print("[TradingManager] Initialized")
