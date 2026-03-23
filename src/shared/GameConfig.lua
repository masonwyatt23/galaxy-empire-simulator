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

	-- Tier 6: VIP Exclusive (requires VIP game pass)
	{name = "VIP Mothership",     cost = 8000000,  income = 50000,  description = "Command the fleet", vip = true},
	{name = "VIP Dimension Rift", cost = 15000000, income = 80000,  description = "Multiverse profits", vip = true},
	{name = "VIP Cosmic Throne",  cost = 30000000, income = 150000, description = "Rule the cosmos", vip = true},
}

-- Rebirth system (called "Warp" in Space Tycoon)
GameConfig.Rebirth = {
	baseCost = 500000,
	costMultiplier = 2.5,
	incomeMultiplier = 1.5,
	maxRebirths = 25,
}

-- Number of standard (non-VIP) items
GameConfig.StandardItemCount = 15

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
	Color3.fromRGB(255, 215, 0),    -- Tier 6: Gold (VIP)
}
GameConfig.BuildingHeights = {5, 8, 12, 16, 22, 28}
GameConfig.BuildingMaterials = {"Metal", "DiamondPlate", "Neon", "ForceField", "Neon", "ForceField"}

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

-- Quest definitions
GameConfig.QuestPool = {
	{type = "earn_cash",   description = "Earn %s credits",       baseTarget = 50000,  rewardMult = 2},
	{type = "buy_items",   description = "Build %s structures",   baseTarget = 3,      rewardMult = 3},
	{type = "rebirth",     description = "Warp %s time(s)",       baseTarget = 1,      rewardMult = 5},
	{type = "play_time",   description = "Explore for %s minutes", baseTarget = 10,     rewardMult = 2},
	{type = "reach_item",  description = "Reach structure #%s",   baseTarget = 10,     rewardMult = 3},
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
}

return GameConfig
