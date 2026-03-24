local GameConfig = {}

-- Currency
GameConfig.CurrencyName = "Credits"
GameConfig.StartingCash = 100
GameConfig.AutoPurchaseFirstItem = true

-- Income tick rate (seconds between income ticks)
GameConfig.IncomeInterval = 1

-- Tycoon items — Space-themed ordered unlock chain
-- Items 1-6 in ~1 min, all 15 in ~6 min, first rebirth at ~7 min
GameConfig.TycoonItems = {
	-- Tier 1: Space Startup (instant to ~20s)
	{name = "Antenna Array",      cost = 0,      income = 5,    description = "Your first signal receiver!"},
	{name = "Solar Panel",        cost = 25,     income = 8,    description = "Harness the power of stars"},
	{name = "Oxygen Generator",   cost = 75,     income = 15,   description = "Breathe easy, profit hard"},

	-- Tier 2: Orbital Station (20s-60s each)
	{name = "Research Lab",       cost = 200,    income = 30,   description = "Science means credits"},
	{name = "Mining Drone",       cost = 500,    income = 50,   description = "Automated asteroid mining"},
	{name = "Cargo Bay",          cost = 1200,   income = 80,   description = "Store and ship resources"},

	-- Tier 3: Space Colony (15s-25s each)
	{name = "Habitat Module",     cost = 3000,   income = 150,  description = "Home among the stars"},
	{name = "Hydroponics Farm",   cost = 7500,   income = 300,  description = "Space-grown profits"},
	{name = "Gravity Generator",  cost = 18000,  income = 500,  description = "Defy physics, earn credits"},

	-- Tier 4: Interstellar Corp (30s-45s each)
	{name = "Warp Gate",          cost = 40000,  income = 900,  description = "Connect galaxies for trade"},
	{name = "Plasma Refinery",    cost = 100000, income = 2000, description = "Refine stardust to credits"},
	{name = "Battlecruiser Dock", cost = 250000, income = 4000, description = "Fleet command center"},

	-- Tier 5: Galactic Empire (42s-66s each)
	{name = "Dyson Sphere",       cost = 500000,  income = 8000,  description = "Harness a star's energy!"},
	{name = "Quantum Computer",   cost = 1200000, income = 15000, description = "Calculate infinite wealth"},
	{name = "Galaxy Core",        cost = 3500000, income = 35000, description = "The ultimate space empire"},

	-- Tier 6: Deep Space
	{name = "Nebula Harvester",   cost = 5000000,   income = 75000,   description = "Mine the cosmos"},
	{name = "Antimatter Plant",   cost = 12000000,  income = 120000,  description = "Pure energy profit"},
	{name = "Wormhole Gateway",   cost = 25000000,  income = 200000,  description = "Shortcut to wealth"},

	-- Tier 7: Intergalactic
	{name = "Dark Matter Lab",    cost = 50000000,  income = 350000,  description = "Unseen fortunes"},
	{name = "Time Distortion",    cost = 100000000, income = 600000,  description = "Bend time for credits"},
	{name = "Void Forge",         cost = 200000000, income = 1000000, description = "Forge from nothing"},

	-- Tier 8: Universal
	{name = "Parallel Dimension", cost = 500000000,  income = 1800000, description = "Double everything"},
	{name = "Big Bang Reactor",   cost = 1000000000, income = 3000000, description = "Create universes"},
	{name = "Infinity Engine",    cost = 2000000000, income = 5000000, description = "Unlimited power"},

	-- Tier 9: Omniversal
	{name = "Reality Weaver",     cost = 5000000000,  income = 10000000,  description = "Shape existence"},
	{name = "Cosmic Nexus",       cost = 10000000000, income = 18000000,  description = "Center of everything"},

	-- Tier 10: Secret
	{name = "The Singularity",    cost = 25000000000, income = 50000000,  description = "Beyond comprehension", secret = true},

	-- VIP Exclusive
	{name = "VIP Mothership",     cost = 50000000000,  income = 80000000,  description = "Command the fleet", vip = true},
	{name = "VIP Dimension Rift", cost = 100000000000, income = 150000000, description = "Multiverse profits", vip = true},
	{name = "VIP Cosmic Throne",  cost = 250000000000, income = 300000000, description = "Rule the cosmos", vip = true},
}

-- Rebirth system (called "Warp" in Space Tycoon)
GameConfig.Rebirth = {
	baseCost = 500000,
	costMultiplier = 2.5,
	incomeMultiplier = 1.5,
	maxRebirths = 25,
}

-- Number of standard (non-VIP) items
GameConfig.StandardItemCount = 28

-- Plot settings
GameConfig.MaxPlots = 8
GameConfig.PlotSpacing = 100
GameConfig.PlotSize = 80

-- Building appearance per tier
GameConfig.BuildingColors = {
	Color3.fromRGB(100, 200, 255),  -- Tier 1: Cyan (tech)
	Color3.fromRGB(150, 100, 255),  -- Tier 2: Purple (alien)
	Color3.fromRGB(50, 255, 150),   -- Tier 3: Green (bio)
	Color3.fromRGB(255, 150, 50),   -- Tier 4: Orange (energy)
	Color3.fromRGB(255, 50, 100),   -- Tier 5: Red (power)
	Color3.fromRGB(200, 50, 255),   -- Tier 6: Deep Space Purple
	Color3.fromRGB(50, 255, 255),   -- Tier 7: Intergalactic Cyan
	Color3.fromRGB(255, 100, 200),  -- Tier 8: Universal Pink
	Color3.fromRGB(255, 255, 255),  -- Tier 9: Omniversal White
	Color3.fromRGB(255, 215, 0),    -- Tier 10: Secret Gold
	Color3.fromRGB(255, 215, 0),    -- VIP Gold
}
GameConfig.BuildingHeights = {5, 8, 12, 16, 22, 28, 33, 38, 43, 48, 52}
GameConfig.BuildingMaterials = {"Metal", "DiamondPlate", "Neon", "ForceField", "Neon", "ForceField", "Glass", "Neon", "ForceField", "ForceField", "ForceField"}

-- Plot base colors (space-themed: dark metallics)
GameConfig.PlotColors = {
	Color3.fromRGB(40, 50, 70),
	Color3.fromRGB(50, 40, 70),
	Color3.fromRGB(40, 60, 60),
	Color3.fromRGB(60, 40, 50),
	Color3.fromRGB(50, 50, 60),
	Color3.fromRGB(45, 55, 65),
	Color3.fromRGB(55, 45, 55),
	Color3.fromRGB(50, 50, 50),
}

-- Promo codes
GameConfig.Codes = {
	LAUNCH   = 5000,
	SPACE    = 1000,
	GALAXY   = 10000,
	WARP     = 50000,
	COSMIC   = 25000,
	CASHFLOW = 25000,  -- Cross-promo: play CashFlow Empire
	FOODIE   = 25000,  -- Cross-promo: play Food Factory
	TOWER    = 25000,  -- Cross-promo: play Tower of Chaos
}

-- Daily reward amounts
GameConfig.DailyRewards = {
	500,
	1500,
	5000,
	15000,
	50000,
	150000,
	500000,
}

-- Exploration config
GameConfig.Exploration = {
	baseCost = 2000,
	gridSize = 8,
	cooldown = 10,
	maxArtifacts = 10,
	artifactBonusPercent = 2,
	tradeRouteBonusPercent = 5,
	anomalyDuration = 60,
	anomalyMultiplier = 3,
	hostileLossPercent = 0.1,
	emptyReward = 1000,
	resourceMin = 5000,
	resourceMax = 50000,
	sectorWeights = {
		resource_cache = 30,
		alien_artifact = 15,
		anomaly = 20,
		trade_route = 10,
		hostile = 15,
		empty = 10,
	},
}

-- Quest definitions
GameConfig.QuestPool = {
	{type = "earn_cash",   description = "Earn %s credits",       baseTarget = 50000,  rewardMult = 2},
	{type = "buy_items",   description = "Build %s structures",   baseTarget = 3,      rewardMult = 3},
	{type = "rebirth",     description = "Warp %s time(s)",       baseTarget = 1,      rewardMult = 5},
	{type = "play_time",   description = "Explore for %s minutes", baseTarget = 10,     rewardMult = 2},
	{type = "reach_item",       description = "Reach structure #%s",   baseTarget = 10,     rewardMult = 3},
	{type = "explore_sectors",  description = "Explore %s sectors",   baseTarget = 5,      rewardMult = 4},
}

-- Achievements
GameConfig.Achievements = {
	{id = "first_station",   name = "First Station",    trigger = "items",      threshold = 1,       reward = 500},
	{id = "space_engineer",  name = "Space Engineer",   trigger = "items",      threshold = 5,       reward = 5000},
	{id = "colony_builder",  name = "Colony Builder",   trigger = "items",      threshold = 15,      reward = 50000},
	{id = "first_warp",      name = "First Warp",       trigger = "rebirths",   threshold = 1,       reward = 10000},
	{id = "warp_veteran",    name = "Warp Veteran",     trigger = "rebirths",   threshold = 5,       reward = 100000},
	{id = "millionaire",     name = "Space Mogul",      trigger = "totalEarned", threshold = 1000000, reward = 50000},
	{id = "ten_million",     name = "Galactic Tycoon",  trigger = "totalEarned", threshold = 10000000, reward = 500000},
	{id = "first_contact",   name = "First Contact",    trigger = "sectors",     threshold = 1,        reward = 2000},
	{id = "star_mapper",     name = "Star Cartographer", trigger = "sectors",    threshold = 32,       reward = 100000},
	{id = "galactic_emperor", name = "Galactic Emperor", trigger = "sectors",    threshold = 64,       reward = 1000000},
	-- Building milestones (expanded)
	{id = "deep_space",    name = "Deep Space Explorer", trigger = "items",      threshold = 20,       reward = 200000},
	{id = "intergalactic", name = "Intergalactic",       trigger = "items",      threshold = 25,       reward = 500000},
	{id = "universal",     name = "Universal Emperor",   trigger = "items",      threshold = 28,       reward = 1000000},
	-- Rebirth milestones (expanded)
	{id = "warp_10",       name = "Warp Master",         trigger = "rebirths",   threshold = 10,       reward = 500000},
	{id = "warp_25",       name = "Warp Legend",          trigger = "rebirths",   threshold = 25,       reward = 5000000},
	-- Wealth milestones (expanded)
	{id = "hundred_mil",   name = "100M Credits Club",    trigger = "totalEarned", threshold = 100000000,  reward = 5000000},
	{id = "billionaire",   name = "Credit Billionaire",   trigger = "totalEarned", threshold = 1000000000, reward = 50000000},
}

return GameConfig
