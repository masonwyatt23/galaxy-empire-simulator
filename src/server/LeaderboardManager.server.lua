--[[
	LeaderboardManager — In-game leaderboard
	Uses Roblox's built-in leaderstats system.
	Shows Cash and Rebirth count for social proof.
]]

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	-- Wait for player data to actually be ready (not a fixed timer)
	local elapsed = 0
	while not (_G.GetPlayerData and _G.GetPlayerData(player)) and elapsed < 15 do
		task.wait(0.5)
		elapsed = elapsed + 0.5
	end

	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Cash display
	local cashStat = Instance.new("IntValue")
	cashStat.Name = "Cash"
	cashStat.Parent = leaderstats

	-- Rebirth count display
	local rebirthStat = Instance.new("IntValue")
	rebirthStat.Name = "Rebirths"
	rebirthStat.Parent = leaderstats

	-- Set initial values from player data
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if data then
		cashStat.Value = data.cash
		rebirthStat.Value = data.rebirthCount
	end
end)

print("[LeaderboardManager] Initialized")
