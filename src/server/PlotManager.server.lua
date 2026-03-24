--[[
	PlotManager — 3D World Generation
	Programmatically creates the lobby, tycoon plots, purchase pads, and buildings.
	No manual Studio work needed — everything is generated from GameConfig.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remote for building effects
local BuildingAppearedRemote = Instance.new("RemoteEvent")
BuildingAppearedRemote.Name = "BuildingAppeared"
BuildingAppearedRemote.Parent = Remotes

-- State
local PlotModels = {}     -- [plotNum] = { base, pads = {}, buildings = {}, ownerSign }
local PlayerPlotRef = {}  -- [player] = plotNum
local touchDebounce = {}  -- [key] = true

-- Helper: get tier (1-5) for item index (1-15)
local function getTier(itemIndex)
	return math.ceil(itemIndex / 3)
end

-- Helper: get grid position within a plot for item index
-- 3 rows x 11 columns layout (supports up to 33 items)
local function getItemPosition(itemIndex, plotCenter)
	local col = math.ceil(itemIndex / 3)   -- 1-11
	local row = ((itemIndex - 1) % 3) + 1  -- 1-3
	local xOffset = (col - 6) * 7           -- tighter spacing for more columns
	local zOffset = (row - 2) * 12          -- -12, 0, 12
	return Vector3.new(
		plotCenter.X + xOffset,
		plotCenter.Y + 1,
		plotCenter.Z + zOffset
	)
end

-- Helper: calculate plot center position from plot number
local function getPlotCenter(plotNum)
	local col = ((plotNum - 1) % 4) + 1
	local row = math.ceil(plotNum / 4)
	local x = (col - 2.5) * GameConfig.PlotSpacing
	local z = row * GameConfig.PlotSpacing + 20
	return Vector3.new(x, 0, z)
end

------------------------------------------------------------------------
-- LOBBY CREATION
------------------------------------------------------------------------
local function createLobby()
	local lobbyFolder = Instance.new("Folder")
	lobbyFolder.Name = "Lobby"
	lobbyFolder.Parent = workspace

	-- Baseplate
	local base = Instance.new("Part")
	base.Name = "LobbyBase"
	base.Size = Vector3.new(200, 1, 120)
	base.Position = Vector3.new(0, -0.5, 0)
	base.Anchored = true
	base.Color = Color3.fromRGB(30, 30, 50)
	base.Material = Enum.Material.Metal
	base.Parent = lobbyFolder

	-- Title sign
	local signPart = Instance.new("Part")
	signPart.Name = "TitleSign"
	signPart.Size = Vector3.new(40, 12, 2)
	signPart.Position = Vector3.new(0, 7, -30)
	signPart.Anchored = true
	signPart.Color = Color3.fromRGB(30, 30, 50)
	signPart.Material = Enum.Material.SmoothPlastic
	signPart.Parent = lobbyFolder

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = signPart

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.05, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "GALAXY EMPIRE SIMULATOR"
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = surfaceGui

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	subtitleLabel.Position = UDim2.new(0, 0, 0.65, 0)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Build Your Galactic Empire!"
	subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitleLabel.TextScaled = true
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.Parent = surfaceGui

	-- Back face
	local backGui = Instance.new("SurfaceGui")
	backGui.Face = Enum.NormalId.Back
	backGui.Parent = signPart

	local backLabel = titleLabel:Clone()
	backLabel.Parent = backGui
	local backSub = subtitleLabel:Clone()
	backSub.Parent = backGui

	-- Spawn location
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Anchored = true
	spawn.Color = Color3.fromRGB(80, 180, 80)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Parent = lobbyFolder

	-- Remove default baseplate if it exists
	local defaultBase = workspace:FindFirstChild("Baseplate")
	if defaultBase then
		defaultBase:Destroy()
	end

	-- === ATMOSPHERE ===

	-- Lighting
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 0
	Lighting.Ambient = Color3.fromRGB(30, 30, 50)
	Lighting.OutdoorAmbient = Color3.fromRGB(40, 40, 80)
	Lighting.Brightness = 0.5
	Lighting.ColorShift_Top = Color3.fromRGB(255, 245, 230)

	-- Sky
	local sky = Instance.new("Sky")
	sky.SkyboxBk = "rbxassetid://6444884337"
	sky.SkyboxDn = "rbxassetid://6444884337"
	sky.SkyboxFt = "rbxassetid://6444884337"
	sky.SkyboxLf = "rbxassetid://6444884337"
	sky.SkyboxRt = "rbxassetid://6444884337"
	sky.SkyboxUp = "rbxassetid://6444884337"
	sky.StarCount = 3000
	sky.Parent = Lighting

	-- Atmosphere (depth haze)
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(10, 10, 30)
	atmosphere.Decay = Color3.fromRGB(20, 20, 50)
	atmosphere.Glare = 0
	atmosphere.Haze = 1
	atmosphere.Parent = Lighting

	-- Bloom effect
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.3
	bloom.Size = 20
	bloom.Threshold = 1.2
	bloom.Parent = Lighting

	-- Lobby lamp posts
	for _, pos in ipairs({
		Vector3.new(-40, 0, -20), Vector3.new(40, 0, -20),
		Vector3.new(-40, 0, 40), Vector3.new(40, 0, 40),
	}) do
		local pole = Instance.new("Part")
		pole.Size = Vector3.new(1, 12, 1)
		pole.Position = pos + Vector3.new(0, 6, 0)
		pole.Anchored = true
		pole.Color = Color3.fromRGB(60, 60, 60)
		pole.Material = Enum.Material.Metal
		pole.Parent = lobbyFolder

		local lamp = Instance.new("Part")
		lamp.Size = Vector3.new(3, 1, 3)
		lamp.Position = pos + Vector3.new(0, 12.5, 0)
		lamp.Anchored = true
		lamp.Color = Color3.fromRGB(100, 150, 255)
		lamp.Material = Enum.Material.Neon
		lamp.Shape = Enum.PartType.Ball
		lamp.Parent = lobbyFolder

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(100, 150, 255)
		light.Brightness = 1
		light.Range = 30
		light.Parent = lamp
	end

	-- Fountain centerpiece (basin + water column)
	local basin = Instance.new("Part")
	basin.Name = "ReactorBase"
	basin.Size = Vector3.new(12, 2, 12)
	basin.Position = Vector3.new(0, 1, 15)
	basin.Anchored = true
	basin.Color = Color3.fromRGB(40, 40, 60)
	basin.Material = Enum.Material.DiamondPlate
	basin.Parent = lobbyFolder

	local column = Instance.new("Part")
	column.Name = "ReactorCore"
	column.Size = Vector3.new(2, 6, 2)
	column.Position = Vector3.new(0, 5, 15)
	column.Anchored = true
	column.Color = Color3.fromRGB(100, 50, 255)
	column.Material = Enum.Material.DiamondPlate
	column.Parent = lobbyFolder

	local waterEffect = Instance.new("ParticleEmitter")
	waterEffect.Color = ColorSequence.new(Color3.fromRGB(150, 50, 255))
	waterEffect.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	waterEffect.Lifetime = NumberRange.new(0.8, 1.5)
	waterEffect.Rate = 40
	waterEffect.Speed = NumberRange.new(3, 8)
	waterEffect.SpreadAngle = Vector2.new(45, 45)
	waterEffect.Drag = 2
	waterEffect.Parent = column

	return lobbyFolder
end

------------------------------------------------------------------------
-- PURCHASE PAD CREATION
------------------------------------------------------------------------
local function createPurchasePad(plotNum, itemIndex, position)
	local item = GameConfig.TycoonItems[itemIndex]
	if not item then return nil end

	local tier = getTier(itemIndex)

	local pad = Instance.new("Part")
	pad.Name = "Pad_" .. itemIndex
	pad.Size = Vector3.new(10, 0.5, 10)
	pad.Position = position
	pad.Anchored = true
	pad.Material = Enum.Material.SmoothPlastic
	pad.CanCollide = true

	-- Color based on status (will be updated dynamically)
	if item.cost == 0 then
		pad.Color = Color3.fromRGB(50, 200, 50) -- Free = bright green
	else
		pad.Color = Color3.fromRGB(200, 50, 50) -- Locked = red
	end

	-- BillboardGui with item info
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PadInfo"
	billboard.Size = UDim2.new(0, 200, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = pad

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = billboard

	local costText = item.cost == 0 and "FREE" or ("$" .. Utils.formatCash(item.cost))
	if item.vip then costText = "VIP - " .. costText end
	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "Cost"
	costLabel.Size = UDim2.new(1, 0, 0.35, 0)
	costLabel.Position = UDim2.new(0, 0, 0.4, 0)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = costText
	costLabel.TextColor3 = item.vip and Color3.fromRGB(255, 100, 100) or (item.cost == 0 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0))
	costLabel.TextScaled = true
	costLabel.Font = Enum.Font.GothamBold
	costLabel.TextStrokeTransparency = 0.5
	costLabel.Parent = billboard

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.Size = UDim2.new(1, 0, 0.25, 0)
	hintLabel.Position = UDim2.new(0, 0, 0.75, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "Step on to buy!"
	hintLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	hintLabel.TextScaled = true
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.TextStrokeTransparency = 0.5
	hintLabel.Parent = billboard

	-- Touch handler — delegates to TycoonManager (single source of truth)
	pad.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Verify this is the player's plot
		if _G.TycoonPlayerPlots and _G.TycoonPlayerPlots[player] ~= plotNum then return end

		-- Debounce
		local key = player.UserId .. "_" .. itemIndex
		if touchDebounce[key] then return end
		touchDebounce[key] = true
		task.delay(0.5, function() touchDebounce[key] = nil end)

		-- Visual feedback — flash pad white briefly
		local originalColor = pad.Color
		pad.Color = Color3.fromRGB(255, 255, 255)
		task.delay(0.15, function()
			if pad and pad.Parent then
				pad.Color = originalColor
			end
		end)

		-- Delegate to TycoonManager's purchase handler (validates everything)
		if _G.PurchaseTycoonItem then
			_G.PurchaseTycoonItem(player, itemIndex)
		end
	end)

	return pad
end

------------------------------------------------------------------------
-- BUILDING CREATION (appears when item is purchased)
------------------------------------------------------------------------
local function createBuilding(plotNum, itemIndex, position)
	local item = GameConfig.TycoonItems[itemIndex]
	if not item then return nil end

	local tier = getTier(itemIndex)
	local height = GameConfig.BuildingHeights[tier] or 6
	local color = GameConfig.BuildingColors[tier] or Color3.fromRGB(200, 200, 200)
	local matName = GameConfig.BuildingMaterials[tier] or "SmoothPlastic"
	local material = Enum.Material[matName] or Enum.Material.SmoothPlastic

	local plotFolder = workspace:FindFirstChild("Plot_" .. plotNum) or workspace

	-- Multi-part building: base + tower + roof
	local model = Instance.new("Model")
	model.Name = "Building_" .. itemIndex
	model.Parent = plotFolder

	-- Base (wider)
	local basePart = Instance.new("Part")
	basePart.Name = "Base"
	basePart.Size = Vector3.new(10, 2, 10)
	basePart.Position = Vector3.new(position.X, position.Y + 1, position.Z)
	basePart.Anchored = true
	basePart.Color = color
	basePart.Material = material
	basePart.Parent = model

	-- Tower (main body)
	local tower = Instance.new("Part")
	tower.Name = "Tower"
	tower.Size = Vector3.new(8, height - 3, 8)
	tower.Position = Vector3.new(position.X, position.Y + 2 + (height - 3) / 2, position.Z)
	tower.Anchored = true
	tower.Color = color
	tower.Material = material
	tower.Parent = model

	-- Roof (flat top or pyramid for small buildings)
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	if tier <= 2 then
		-- Small buildings: pyramid roof (wedge approximation)
		roof.Size = Vector3.new(9, 2, 9)
		roof.Position = Vector3.new(position.X, position.Y + height - 0.5, position.Z)
		roof.Color = Color3.fromRGB(math.min(255, color.R * 255 * 0.7), math.min(255, color.G * 255 * 0.7), math.min(255, color.B * 255 * 0.7))
	else
		-- Big buildings: flat roof with overhang
		roof.Size = Vector3.new(10, 0.5, 10)
		roof.Position = Vector3.new(position.X, position.Y + height - 0.75, position.Z)
		roof.Color = Color3.fromRGB(50, 50, 60)
	end
	roof.Anchored = true
	roof.Material = material
	roof.Parent = model

	-- Interior glow
	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Brightness = 0.5
	glow.Range = 15
	glow.Parent = tower

	-- Building name label (on top)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BuildingInfo"
	billboard.Size = UDim2.new(0, 180, 0, 40)
	billboard.StudsOffset = Vector3.new(0, height / 2 + 4, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = tower

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Parent = billboard

	-- Pop-in animation on the tower (most visible part)
	tower.Size = Vector3.new(0.5, 0.5, 0.5)
	tower.Position = Vector3.new(position.X, position.Y + 2, position.Z)
	basePart.Size = Vector3.new(0.5, 0.5, 0.5)
	basePart.Position = Vector3.new(position.X, position.Y + 0.25, position.Z)
	roof.Transparency = 1

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(basePart, tweenInfo, {
		Size = Vector3.new(10, 2, 10),
		Position = Vector3.new(position.X, position.Y + 1, position.Z),
	}):Play()
	TweenService:Create(tower, tweenInfo, {
		Size = Vector3.new(8, height - 3, 8),
		Position = Vector3.new(position.X, position.Y + 2 + (height - 3) / 2, position.Z),
	}):Play()

	task.delay(0.4, function()
		if tier <= 2 then
			roof.Size = Vector3.new(9, 2, 9)
			roof.Position = Vector3.new(position.X, position.Y + height - 0.5, position.Z)
		else
			roof.Size = Vector3.new(10, 0.5, 10)
			roof.Position = Vector3.new(position.X, position.Y + height - 0.75, position.Z)
		end
		roof.Transparency = 0
	end)

	return model
end

------------------------------------------------------------------------
-- PLOT CREATION
------------------------------------------------------------------------
local function createPlot(plotNum)
	local center = getPlotCenter(plotNum)
	local plotSize = GameConfig.PlotSize
	local plotColor = GameConfig.PlotColors[plotNum] or Color3.fromRGB(200, 200, 200)

	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plot_" .. plotNum
	plotFolder.Parent = workspace

	-- Base platform
	local base = Instance.new("Part")
	base.Name = "PlotBase"
	base.Size = Vector3.new(plotSize, 1, plotSize)
	base.Position = Vector3.new(center.X, -0.5, center.Z)
	base.Anchored = true
	base.Color = plotColor
	base.Material = Enum.Material.Metal
	base.Parent = plotFolder

	-- Plot border (thin raised edge)
	for _, side in ipairs({"Front", "Back", "Left", "Right"}) do
		local border = Instance.new("Part")
		border.Name = "Border_" .. side
		border.Anchored = true
		border.Color = Color3.fromRGB(80, 80, 80)
		border.Material = Enum.Material.SmoothPlastic
		border.Parent = plotFolder

		local half = plotSize / 2
		if side == "Front" then
			border.Size = Vector3.new(plotSize, 1.5, 0.5)
			border.Position = Vector3.new(center.X, 0.25, center.Z - half)
		elseif side == "Back" then
			border.Size = Vector3.new(plotSize, 1.5, 0.5)
			border.Position = Vector3.new(center.X, 0.25, center.Z + half)
		elseif side == "Left" then
			border.Size = Vector3.new(0.5, 1.5, plotSize)
			border.Position = Vector3.new(center.X - half, 0.25, center.Z)
		elseif side == "Right" then
			border.Size = Vector3.new(0.5, 1.5, plotSize)
			border.Position = Vector3.new(center.X + half, 0.25, center.Z)
		end
	end

	-- Ownership sign
	local signPart = Instance.new("Part")
	signPart.Name = "OwnerSign"
	signPart.Size = Vector3.new(12, 6, 1)
	signPart.Position = Vector3.new(center.X, 4, center.Z - plotSize / 2 - 1)
	signPart.Anchored = true
	signPart.Color = Color3.fromRGB(40, 40, 60)
	signPart.Material = Enum.Material.SmoothPlastic
	signPart.Parent = plotFolder

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signPart

	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Name = "OwnerName"
	ownerLabel.Size = UDim2.new(1, 0, 0.5, 0)
	ownerLabel.Position = UDim2.new(0, 0, 0, 0)
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.Text = "Plot " .. plotNum
	ownerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	ownerLabel.TextScaled = true
	ownerLabel.Font = Enum.Font.GothamBold
	ownerLabel.Parent = signGui

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.Size = UDim2.new(1, 0, 0.4, 0)
	statusLabel.Position = UDim2.new(0, 0, 0.5, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Available"
	statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = signGui

	-- Create purchase pads for all 15 items
	local pads = {}
	for i = 1, #GameConfig.TycoonItems do
		local padPos = getItemPosition(i, center)
		local pad = createPurchasePad(plotNum, i, padPos)
		if pad then
			pad.Parent = plotFolder
			pads[i] = pad
		end
	end

	-- Decorative trees (2 per plot, in corners)
	local half = plotSize / 2
	for _, treePos in ipairs({
		Vector3.new(center.X - half + 5, 0, center.Z + half - 5),
		Vector3.new(center.X + half - 5, 0, center.Z + half - 5),
	}) do
		local trunk = Instance.new("Part")
		trunk.Size = Vector3.new(1.5, 8, 1.5)
		trunk.Position = treePos + Vector3.new(0, 4, 0)
		trunk.Anchored = true
		trunk.Color = Color3.fromRGB(80, 80, 100)
		trunk.Material = Enum.Material.Wood
		trunk.Parent = plotFolder

		local canopy = Instance.new("Part")
		canopy.Shape = Enum.PartType.Ball
		canopy.Size = Vector3.new(8, 8, 8)
		canopy.Position = treePos + Vector3.new(0, 10, 0)
		canopy.Anchored = true
		canopy.Color = Color3.fromRGB(100, 200, 255)
		canopy.Material = Enum.Material.Metal
		canopy.Parent = plotFolder
	end

	-- Lamp posts (2 per plot, front corners)
	for _, lampPos in ipairs({
		Vector3.new(center.X - half + 3, 0, center.Z - half + 3),
		Vector3.new(center.X + half - 3, 0, center.Z - half + 3),
	}) do
		local pole = Instance.new("Part")
		pole.Size = Vector3.new(0.8, 10, 0.8)
		pole.Position = lampPos + Vector3.new(0, 5, 0)
		pole.Anchored = true
		pole.Color = Color3.fromRGB(60, 60, 60)
		pole.Material = Enum.Material.Metal
		pole.Parent = plotFolder

		local bulb = Instance.new("Part")
		bulb.Shape = Enum.PartType.Ball
		bulb.Size = Vector3.new(2, 2, 2)
		bulb.Position = lampPos + Vector3.new(0, 10.5, 0)
		bulb.Anchored = true
		bulb.Color = Color3.fromRGB(100, 150, 255)
		bulb.Material = Enum.Material.Neon
		bulb.Parent = plotFolder

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(100, 150, 255)
		light.Brightness = 0.8
		light.Range = 25
		light.Parent = bulb
	end

	PlotModels[plotNum] = {
		base = base,
		pads = pads,
		buildings = {},
		ownerSign = signPart,
		center = center,
		folder = plotFolder,
	}

	return plotFolder
end

------------------------------------------------------------------------
-- PAD STATE UPDATES (color based on affordability)
------------------------------------------------------------------------
local function updatePadStates(player)
	local plotNum = PlayerPlotRef[player]
	if not plotNum or not PlotModels[plotNum] then return end

	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	local plotData = PlotModels[plotNum]
	local nextIndex = #data.ownedItems + 1

	for i, pad in pairs(plotData.pads) do
		if pad and pad.Parent then
			if i < nextIndex then
				-- Already purchased — hide pad
				pad.Transparency = 1
				pad.CanCollide = false
				local info = pad:FindFirstChild("PadInfo")
				if info then info.Enabled = false end
			elseif i == nextIndex then
				-- Next to buy
				pad.Transparency = 0
				pad.CanCollide = true
				local info = pad:FindFirstChild("PadInfo")
				if info then info.Enabled = true end
				local item = GameConfig.TycoonItems[i]
				if item and data.cash >= item.cost then
					pad.Color = Color3.fromRGB(50, 200, 50)   -- Affordable = green
				else
					pad.Color = Color3.fromRGB(255, 180, 50)  -- Next but can't afford = orange
				end
			else
				-- Future items — dimmed
				pad.Transparency = 0.6
				pad.CanCollide = false
				pad.Color = Color3.fromRGB(100, 100, 100)
				local info = pad:FindFirstChild("PadInfo")
				if info then info.Enabled = true end
			end
		end
	end
end

------------------------------------------------------------------------
-- ITEM PURCHASED CALLBACK
------------------------------------------------------------------------
_G.OnItemPurchased = function(player, itemIndex)
	local plotNum = PlayerPlotRef[player]
	if not plotNum or not PlotModels[plotNum] then return end

	local plotData = PlotModels[plotNum]
	local position = getItemPosition(itemIndex, plotData.center)

	-- Create building
	local building = createBuilding(plotNum, itemIndex, position)
	if building then
		plotData.buildings[itemIndex] = building
	end

	-- Update pad states
	updatePadStates(player)

	-- Notify client for effects
	BuildingAppearedRemote:FireClient(player, position)
end

------------------------------------------------------------------------
-- PRESTIGE TIERS — visual upgrades based on rebirth count
------------------------------------------------------------------------
local PRESTIGE_TIERS = {
	{rebirths = 3,  color = Color3.fromRGB(205, 127, 50),  name = "Bronze",  material = Enum.Material.Metal},
	{rebirths = 5,  color = Color3.fromRGB(192, 192, 192), name = "Silver",  material = Enum.Material.Metal},
	{rebirths = 10, color = Color3.fromRGB(255, 215, 0),   name = "Gold",    material = Enum.Material.Neon},
	{rebirths = 15, color = Color3.fromRGB(185, 242, 255), name = "Diamond", material = Enum.Material.Glass},
	{rebirths = 25, color = Color3.fromRGB(255, 100, 255), name = "Rainbow", material = Enum.Material.ForceField},
}

local function getPrestigeTier(rebirthCount)
	local bestTier = nil
	for _, tier in ipairs(PRESTIGE_TIERS) do
		if rebirthCount >= tier.rebirths then
			bestTier = tier
		end
	end
	return bestTier
end

local function applyPrestigeVisuals(plotNum, rebirthCount)
	local plotFolder = workspace:FindFirstChild("Plot_" .. plotNum)
	if not plotFolder then return end

	local tier = getPrestigeTier(rebirthCount)
	if not tier then return end

	-- Update border colors and material
	for _, child in ipairs(plotFolder:GetChildren()) do
		if child.Name:find("Border_") then
			child.Color = tier.color
			child.Material = tier.material
		end
	end

	-- Add glow effect for Gold+ tiers
	if rebirthCount >= 10 then
		local base = plotFolder:FindFirstChild("PlotBase")
		if base and not base:FindFirstChild("PrestigeGlow") then
			local glow = Instance.new("PointLight")
			glow.Name = "PrestigeGlow"
			glow.Color = tier.color
			glow.Brightness = 0.8
			glow.Range = 40
			glow.Parent = base
		elseif base then
			local glow = base:FindFirstChild("PrestigeGlow")
			if glow then glow.Color = tier.color end
		end
	end

	-- Add particle effects for Diamond+ tiers
	if rebirthCount >= 15 then
		local base = plotFolder:FindFirstChild("PlotBase")
		if base and not base:FindFirstChild("PrestigeParticles") then
			local particles = Instance.new("ParticleEmitter")
			particles.Name = "PrestigeParticles"
			particles.Color = ColorSequence.new(tier.color)
			particles.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0),
			})
			particles.Lifetime = NumberRange.new(1, 2)
			particles.Rate = 8
			particles.Speed = NumberRange.new(1, 3)
			particles.SpreadAngle = Vector2.new(180, 180)
			particles.Parent = base
		elseif base then
			local p = base:FindFirstChild("PrestigeParticles")
			if p then p.Color = ColorSequence.new(tier.color) end
		end
	end

	-- Update ownership sign with prestige badge
	local sign = plotFolder:FindFirstChild("OwnerSign")
	if sign then
		local gui = sign:FindFirstChildOfClass("SurfaceGui")
		if gui then
			local status = gui:FindFirstChild("Status")
			if status then
				status.Text = tier.name .. " Prestige"
				status.TextColor3 = tier.color
			end
		end
	end
end

------------------------------------------------------------------------
-- REBIRTH CALLBACK — reset plot buildings
------------------------------------------------------------------------
_G.OnRebirth = function(player)
	local plotNum = PlayerPlotRef[player]
	if not plotNum or not PlotModels[plotNum] then return end

	local plotData = PlotModels[plotNum]

	-- Destroy all buildings
	for i, building in pairs(plotData.buildings) do
		if building and building.Parent then
			building:Destroy()
		end
	end
	plotData.buildings = {}

	-- Re-show all pads
	for i, pad in pairs(plotData.pads) do
		if pad then
			pad.Transparency = 0
			pad.CanCollide = true
			local info = pad:FindFirstChild("PadInfo")
			if info then info.Enabled = true end
		end
	end

	-- Update pad colors
	updatePadStates(player)

	-- Apply prestige visuals after rebirth
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if data then
		applyPrestigeVisuals(plotNum, data.rebirthCount)
	end
end

------------------------------------------------------------------------
-- REBUILD OWNED BUILDINGS (for returning players)
------------------------------------------------------------------------
local function rebuildOwnedBuildings(player, plotNum)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data or not PlotModels[plotNum] then return end

	local plotData = PlotModels[plotNum]

	for _, itemIndex in ipairs(data.ownedItems) do
		local position = getItemPosition(itemIndex, plotData.center)
		local building = createBuilding(plotNum, itemIndex, position)
		if building then
			plotData.buildings[itemIndex] = building
		end
	end

	updatePadStates(player)
end

------------------------------------------------------------------------
-- PLAYER JOIN — assign plot and teleport
------------------------------------------------------------------------
local function onPlayerAdded(player)
	-- Wait for TycoonManager to assign a plot
	local elapsed = 0
	while not (_G.TycoonPlayerPlots and _G.TycoonPlayerPlots[player]) and elapsed < 15 do
		task.wait(0.5)
		elapsed = elapsed + 0.5
	end

	local plotNum = _G.TycoonPlayerPlots and _G.TycoonPlayerPlots[player]
	if not plotNum or not PlotModels[plotNum] then
		warn("[PlotManager] No plot assigned for " .. player.Name)
		return
	end

	PlayerPlotRef[player] = plotNum

	-- Update ownership sign
	local plotData = PlotModels[plotNum]
	if plotData.ownerSign then
		local gui = plotData.ownerSign:FindFirstChildOfClass("SurfaceGui")
		if gui then
			local ownerLabel = gui:FindFirstChild("OwnerName")
			if ownerLabel then ownerLabel.Text = player.Name .. "'s Tycoon" end
			local statusLabel = gui:FindFirstChild("Status")
			if statusLabel then
				statusLabel.Text = "Owned"
				statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			end
		end
	end

	-- Apply prestige visuals if player has rebirths
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if data and data.rebirthCount and data.rebirthCount > 0 then
		applyPrestigeVisuals(plotNum, data.rebirthCount)
	end

	-- Rebuild any owned buildings (returning player)
	rebuildOwnedBuildings(player, plotNum)

	-- Teleport to plot on first spawn
	local function teleportToPlot(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if hrp then
			local center = plotData.center
			hrp.CFrame = CFrame.new(center.X, 5, center.Z)
		end
	end

	-- Teleport on first character spawn
	if player.Character then
		teleportToPlot(player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		teleportToPlot(character)
	end)
end

------------------------------------------------------------------------
-- PLAYER LEAVE — free plot visually
------------------------------------------------------------------------
local function onPlayerRemoving(player)
	local plotNum = PlayerPlotRef[player]
	if not plotNum or not PlotModels[plotNum] then
		PlayerPlotRef[player] = nil
		return
	end

	local plotData = PlotModels[plotNum]

	-- Destroy buildings
	for _, building in pairs(plotData.buildings) do
		if building and building.Parent then
			building:Destroy()
		end
	end
	plotData.buildings = {}

	-- Reset pads
	for itemIndex, pad in pairs(plotData.pads) do
		if pad then
			pad.Transparency = 0
			pad.CanCollide = true
			local item = GameConfig.TycoonItems[itemIndex]
			if item and item.cost == 0 then
				pad.Color = Color3.fromRGB(50, 200, 50)
			else
				pad.Color = Color3.fromRGB(200, 50, 50)
			end
			local info = pad:FindFirstChild("PadInfo")
			if info then info.Enabled = true end
		end
	end

	-- Reset ownership sign
	if plotData.ownerSign then
		local gui = plotData.ownerSign:FindFirstChildOfClass("SurfaceGui")
		if gui then
			local ownerLabel = gui:FindFirstChild("OwnerName")
			if ownerLabel then ownerLabel.Text = "Plot " .. plotNum end
			local statusLabel = gui:FindFirstChild("Status")
			if statusLabel then
				statusLabel.Text = "Available"
				statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			end
		end
	end

	-- Clean up debounce entries
	for key, _ in pairs(touchDebounce) do
		if string.find(key, tostring(player.UserId)) then
			touchDebounce[key] = nil
		end
	end

	PlayerPlotRef[player] = nil
end

------------------------------------------------------------------------
-- PAD COLOR UPDATE LOOP (updates affordability colors periodically)
------------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(2)
		for player, plotNum in pairs(PlayerPlotRef) do
			if player.Parent then
				updatePadStates(player)
			end
		end
	end
end)

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

-- Create the lobby
createLobby()

-- Create all plots
for i = 1, GameConfig.MaxPlots do
	createPlot(i)
end

-- Connect player events
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		onPlayerAdded(player)
	end)
end)

Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game (Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		onPlayerAdded(player)
	end)
end

print("[PlotManager] Initialized — Lobby + " .. GameConfig.MaxPlots .. " plots created")
