--[[
	GlobalLeaderboard — Cross-server leaderboard
	Uses OrderedDataStore to track top players by total earned.
	Displays top 10 on a lobby billboard.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local LeaderboardStore = DataStoreService:GetOrderedDataStore("GlobalLeaderboard_v1")

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")

-- Create remote for client leaderboard display
local LeaderboardRemote = Instance.new("RemoteEvent")
LeaderboardRemote.Name = "GlobalLeaderboard"
LeaderboardRemote.Parent = Remotes

local cachedLeaderboard = {} -- {rank, name, value}

-- Update the OrderedDataStore with current player stats
local function updatePlayerScore(player)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	local score = math.floor(data.totalEarned or 0)
	if score <= 0 then return end

	pcall(function()
		LeaderboardStore:SetAsync(tostring(player.UserId), score)
	end)
end

-- Fetch top 10 from OrderedDataStore
local function fetchLeaderboard()
	local success, pages = pcall(function()
		return LeaderboardStore:GetSortedAsync(false, 10)
	end)

	if not success or not pages then return end

	local entries = {}
	local pageData = pages:GetCurrentPage()
	for rank, entry in ipairs(pageData) do
		local userId = tonumber(entry.key)
		local displayName = "Player"

		-- Try to get display name
		if userId then
			local success2, name = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if success2 and name then
				displayName = name
			end
		end

		table.insert(entries, {
			rank = rank,
			name = displayName,
			value = entry.value,
		})
	end

	cachedLeaderboard = entries
end

-- Create the lobby billboard for leaderboard display
local function createLeaderboardSign()
	local lobby = workspace:WaitForChild("Lobby", 30)
	if not lobby then return end

	local signPart = Instance.new("Part")
	signPart.Name = "LeaderboardSign"
	signPart.Size = Vector3.new(20, 14, 2)
	signPart.Position = Vector3.new(-35, 8, -30)
	signPart.Anchored = true
	signPart.Color = Color3.fromRGB(25, 25, 40)
	signPart.Material = Enum.Material.SmoothPlastic
	signPart.Parent = lobby

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardGUI"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = signPart

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.BackgroundTransparency = 1
	title.Text = "TOP COMMANDERS"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = surfaceGui

	-- Entries container
	for i = 1, 10 do
		local entryLabel = Instance.new("TextLabel")
		entryLabel.Name = "Entry_" .. i
		entryLabel.Size = UDim2.new(1, -10, 0.08, 0)
		entryLabel.Position = UDim2.new(0, 5, 0.1 + (i - 1) * 0.085, 0)
		entryLabel.BackgroundTransparency = 1
		entryLabel.Text = "#" .. i .. ". ---"
		entryLabel.TextColor3 = i <= 3 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 200, 200)
		entryLabel.TextScaled = true
		entryLabel.Font = i <= 3 and Enum.Font.GothamBold or Enum.Font.Gotham
		entryLabel.TextXAlignment = Enum.TextXAlignment.Left
		entryLabel.Parent = surfaceGui
	end

	-- Back face
	local backGui = surfaceGui:Clone()
	backGui.Face = Enum.NormalId.Back
	backGui.Parent = signPart

	return signPart
end

-- Update the billboard display
local function updateBillboard()
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then return end

	local sign = lobby:FindFirstChild("LeaderboardSign")
	if not sign then return end

	-- Format cash for display
	local function formatLarge(n)
		if n >= 1e9 then return string.format("%.1fB", n / 1e9)
		elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
		elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
		else return tostring(n) end
	end

	for _, gui in ipairs(sign:GetChildren()) do
		if gui:IsA("SurfaceGui") then
			for i = 1, 10 do
				local label = gui:FindFirstChild("Entry_" .. i)
				if label then
					local entry = cachedLeaderboard[i]
					if entry then
						label.Text = "#" .. entry.rank .. ". " .. entry.name .. " — $" .. formatLarge(entry.value)
					else
						label.Text = "#" .. i .. ". ---"
					end
				end
			end
		end
	end
end

-- Send leaderboard data to all clients
local function broadcastLeaderboard()
	LeaderboardRemote:FireAllClients(cachedLeaderboard)
end

-- Initialize
task.spawn(function()
	task.wait(15) -- Wait for plots and lobby to generate

	createLeaderboardSign()

	while true do
		-- Update player scores
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				updatePlayerScore(player)
			end)
		end

		task.wait(5) -- Brief gap before fetch

		-- Fetch leaderboard
		fetchLeaderboard()
		updateBillboard()
		broadcastLeaderboard()

		task.wait(55) -- Total cycle: ~60 seconds
	end
end)

print("[GlobalLeaderboard] Initialized")
