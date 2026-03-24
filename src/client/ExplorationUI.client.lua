--[[
	ExplorationUI — Galaxy Map client interface
	8x8 grid showing explored/unexplored sectors with type indicators.
	Handles exploration input and result display.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ExploreSector = Remotes:WaitForChild("ExploreSector", 15)
local ExplorationResult = Remotes:WaitForChild("ExplorationResult", 15)
local ExplorationInfo = Remotes:WaitForChild("ExplorationInfo", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- State
local explorationData = {
	exploredSectors = {},
	artifactCount = 0,
	tradeRoutes = {},
	costMap = {},
	totalSectors = 64,
	exploredCount = 0,
}
local cooldownActive = false
local GRID_SIZE = 8
local CELL_SIZE = 50
local CELL_PADDING = 4

-- Sector type colors and indicators
local SECTOR_COLORS = {
	resource_cache = Color3.fromRGB(50, 180, 80),    -- green
	alien_artifact = Color3.fromRGB(220, 180, 40),    -- gold
	anomaly        = Color3.fromRGB(150, 60, 220),    -- purple
	trade_route    = Color3.fromRGB(60, 140, 220),    -- blue
	hostile        = Color3.fromRGB(200, 50, 50),     -- red
	empty          = Color3.fromRGB(100, 100, 100),   -- gray
	start          = Color3.fromRGB(80, 180, 220),    -- cyan (starting sector)
}

local SECTOR_LETTERS = {
	resource_cache = "R",
	alien_artifact = "A",
	anomaly        = "!",
	trade_route    = "T",
	hostile        = "X",
	empty          = "-",
	start          = "H",
}

-- Build the UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExplorationGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Main frame
local exploreFrame = Instance.new("Frame")
exploreFrame.Name = "ExploreFrame"
exploreFrame.Size = UDim2.new(0, 500, 0, 550)
exploreFrame.Position = UDim2.new(0.5, -250, 0.5, -275)
exploreFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
exploreFrame.BackgroundTransparency = 0.05
exploreFrame.BorderSizePixel = 0
exploreFrame.Visible = false
exploreFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = exploreFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(80, 50, 180)
frameStroke.Thickness = 2
frameStroke.Transparency = 0.2
frameStroke.Parent = exploreFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "GALAXY MAP"
title.TextColor3 = Color3.fromRGB(180, 140, 255)
title.TextSize = 28
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = exploreFrame

-- Stats label
local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsLabel"
statsLabel.Size = UDim2.new(1, -20, 0, 22)
statsLabel.Position = UDim2.new(0, 10, 0, 50)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "Sectors: 1/64 | Artifacts: 0/10 (+0% income)"
statsLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
statsLabel.TextSize = 14
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextXAlignment = Enum.TextXAlignment.Center
statsLabel.Parent = exploreFrame

-- Cooldown label
local cooldownLabel = Instance.new("TextLabel")
cooldownLabel.Name = "CooldownLabel"
cooldownLabel.Size = UDim2.new(1, -20, 0, 20)
cooldownLabel.Position = UDim2.new(0, 10, 0, 72)
cooldownLabel.BackgroundTransparency = 1
cooldownLabel.Text = ""
cooldownLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
cooldownLabel.TextSize = 13
cooldownLabel.Font = Enum.Font.GothamBold
cooldownLabel.TextXAlignment = Enum.TextXAlignment.Center
cooldownLabel.Parent = exploreFrame

-- Grid container
local gridFrame = Instance.new("Frame")
gridFrame.Name = "GridFrame"
local gridWidth = GRID_SIZE * (CELL_SIZE + CELL_PADDING) - CELL_PADDING
local gridHeight = GRID_SIZE * (CELL_SIZE + CELL_PADDING) - CELL_PADDING
gridFrame.Size = UDim2.new(0, gridWidth, 0, gridHeight)
gridFrame.Position = UDim2.new(0.5, -gridWidth / 2, 0, 100)
gridFrame.BackgroundTransparency = 1
gridFrame.Parent = exploreFrame

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.Position = UDim2.new(1, -42, 0, 6)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = exploreFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Result popup frame
local resultFrame = Instance.new("Frame")
resultFrame.Name = "ResultFrame"
resultFrame.Size = UDim2.new(0, 350, 0, 80)
resultFrame.Position = UDim2.new(0.5, -175, 1, -90)
resultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
resultFrame.BackgroundTransparency = 0.1
resultFrame.BorderSizePixel = 0
resultFrame.Visible = false
resultFrame.Parent = exploreFrame

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 10)
resultCorner.Parent = resultFrame

local resultStroke = Instance.new("UIStroke")
resultStroke.Color = Color3.fromRGB(255, 215, 0)
resultStroke.Thickness = 2
resultStroke.Transparency = 0.3
resultStroke.Parent = resultFrame

local resultText = Instance.new("TextLabel")
resultText.Name = "ResultText"
resultText.Size = UDim2.new(1, -20, 1, 0)
resultText.Position = UDim2.new(0, 10, 0, 0)
resultText.BackgroundTransparency = 1
resultText.Text = ""
resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
resultText.TextSize = 16
resultText.Font = Enum.Font.GothamBold
resultText.TextWrapped = true
resultText.TextXAlignment = Enum.TextXAlignment.Center
resultText.Parent = resultFrame

-- Cell references
local gridCells = {} -- [key] = TextButton

-- Create grid cells
for x = 1, GRID_SIZE do
	for y = 1, GRID_SIZE do
		local key = x .. "_" .. y
		local cell = Instance.new("TextButton")
		cell.Name = "Cell_" .. key
		cell.Size = UDim2.new(0, CELL_SIZE, 0, CELL_SIZE)
		cell.Position = UDim2.new(0, (x - 1) * (CELL_SIZE + CELL_PADDING), 0, (y - 1) * (CELL_SIZE + CELL_PADDING))
		cell.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
		cell.BorderSizePixel = 0
		cell.Text = ""
		cell.TextColor3 = Color3.fromRGB(255, 255, 255)
		cell.TextSize = 22
		cell.Font = Enum.Font.GothamBold
		cell.AutoButtonColor = false
		cell.Parent = gridFrame

		local cellCorner = Instance.new("UICorner")
		cellCorner.CornerRadius = UDim.new(0, 6)
		cellCorner.Parent = cell

		local cellStroke = Instance.new("UIStroke")
		cellStroke.Name = "CellStroke"
		cellStroke.Color = Color3.fromRGB(50, 50, 70)
		cellStroke.Thickness = 1
		cellStroke.Transparency = 0.5
		cellStroke.Parent = cell

		-- Cost label (small text at bottom of cell)
		local costLabel = Instance.new("TextLabel")
		costLabel.Name = "CostLabel"
		costLabel.Size = UDim2.new(1, 0, 0, 14)
		costLabel.Position = UDim2.new(0, 0, 1, -14)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = ""
		costLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		costLabel.TextSize = 10
		costLabel.Font = Enum.Font.Gotham
		costLabel.TextXAlignment = Enum.TextXAlignment.Center
		costLabel.Parent = cell

		-- Click handler
		cell.MouseButton1Click:Connect(function()
			if cooldownActive then return end
			-- Only allow clicking unexplored adjacent sectors
			if explorationData.exploredSectors[key] then return end
			if not explorationData.costMap[key] then return end

			ExploreSector:FireServer(x, y)
		end)

		gridCells[key] = cell
	end
end

-- Active pulse tweens for cleanup
local activePulses = {} -- [key] = tween

-- Update grid display
local function updateGrid()
	-- Stop all active pulse tweens
	for key, tween in pairs(activePulses) do
		tween:Cancel()
		activePulses[key] = nil
	end

	for x = 1, GRID_SIZE do
		for y = 1, GRID_SIZE do
			local key = x .. "_" .. y
			local cell = gridCells[key]
			if not cell then continue end

			local costLabel = cell:FindFirstChild("CostLabel")
			local cellStroke = cell:FindFirstChild("CellStroke")

			if explorationData.exploredSectors[key] then
				-- Explored sector — show type color and letter
				local sType = explorationData.exploredSectors[key]
				local color = SECTOR_COLORS[sType] or Color3.fromRGB(100, 100, 100)
				cell.BackgroundColor3 = color
				cell.Text = SECTOR_LETTERS[sType] or "?"
				cell.TextTransparency = 0
				cell.AutoButtonColor = false
				if costLabel then costLabel.Text = "" end
				if cellStroke then
					cellStroke.Color = Color3.fromRGB(255, 255, 255)
					cellStroke.Transparency = 0.5
				end

			elseif explorationData.costMap[key] then
				-- Unexplored but adjacent — clickable, with pulsing effect
				local baseColor = Color3.fromRGB(50, 45, 70)
				cell.BackgroundColor3 = baseColor
				cell.Text = "?"
				cell.TextColor3 = Color3.fromRGB(180, 160, 220)
				cell.TextTransparency = 0
				cell.AutoButtonColor = true
				if costLabel then
					costLabel.Text = Utils.formatCash(explorationData.costMap[key])
				end
				if cellStroke then
					cellStroke.Color = Color3.fromRGB(120, 80, 220)
					cellStroke.Transparency = 0.3
				end

				-- Pulsing animation
				task.spawn(function()
					local pulseTarget = Color3.fromRGB(70, 60, 100)
					while exploreFrame.Visible and not explorationData.exploredSectors[key] and explorationData.costMap[key] do
						local tweenIn = TweenService:Create(cell, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
							BackgroundColor3 = pulseTarget
						})
						activePulses[key] = tweenIn
						tweenIn:Play()
						tweenIn.Completed:Wait()

						local tweenOut = TweenService:Create(cell, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
							BackgroundColor3 = baseColor
						})
						activePulses[key] = tweenOut
						tweenOut:Play()
						tweenOut.Completed:Wait()
					end
				end)

			else
				-- Unexplored and not adjacent — dark, non-interactive
				cell.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
				cell.Text = ""
				cell.TextTransparency = 1
				cell.AutoButtonColor = false
				if costLabel then costLabel.Text = "" end
				if cellStroke then
					cellStroke.Color = Color3.fromRGB(30, 30, 45)
					cellStroke.Transparency = 0.7
				end
			end
		end
	end
end

-- Update stats display
local function updateStats()
	local artifactBonus = explorationData.artifactCount * 2
	statsLabel.Text = string.format(
		"Sectors: %d/%d | Artifacts: %d/10 (+%d%% income)",
		explorationData.exploredCount,
		explorationData.totalSectors,
		explorationData.artifactCount,
		artifactBonus
	)
end

-- Show result popup with auto-dismiss
local function showResult(message, sectorType)
	resultText.Text = message

	-- Color the result based on type
	local color = SECTOR_COLORS[sectorType] or Color3.fromRGB(255, 255, 255)
	resultStroke.Color = color

	resultFrame.Visible = true
	resultFrame.BackgroundTransparency = 0.1

	-- Auto-dismiss after 3 seconds
	task.delay(3, function()
		local fadeOut = TweenService:Create(resultFrame, TweenInfo.new(0.5), {
			BackgroundTransparency = 1
		})
		local textFade = TweenService:Create(resultText, TweenInfo.new(0.5), {
			TextTransparency = 1
		})
		fadeOut:Play()
		textFade:Play()
		fadeOut.Completed:Wait()
		resultFrame.Visible = false
		resultFrame.BackgroundTransparency = 0.1
		resultText.TextTransparency = 0
	end)
end

-- Start cooldown
local function startCooldown()
	cooldownActive = true
	local remaining = 10
	task.spawn(function()
		while remaining > 0 do
			cooldownLabel.Text = "Cooldown: " .. remaining .. "s"
			task.wait(1)
			remaining = remaining - 1
		end
		cooldownLabel.Text = ""
		cooldownActive = false
	end)
end

-- Event handlers
ExplorationInfo.OnClientEvent:Connect(function(info)
	explorationData = info
	updateStats()
	if exploreFrame.Visible then
		updateGrid()
	end
end)

ExplorationResult.OnClientEvent:Connect(function(result)
	showResult(result.message, result.sectorType)
	startCooldown()
end)

-- Close button
closeButton.MouseButton1Click:Connect(function()
	exploreFrame.Visible = false
end)

-- Global toggle function (called by TycoonUI EXPLORE button)
_G.ShowExploreUI = function()
	exploreFrame.Visible = not exploreFrame.Visible
	if exploreFrame.Visible then
		updateGrid()
		updateStats()
	end
end

print("[ExplorationUI] Initialized")
