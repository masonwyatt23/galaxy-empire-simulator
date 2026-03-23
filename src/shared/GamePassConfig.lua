local GamePassConfig = {}

-- Game Passes — IDs set to 0, create in Creator Dashboard after publishing
GamePassConfig.Passes = {
	DoubleIncome = {
		id = 0,
		name = "2x Credits",
		price = 199,
		description = "Permanently double all credit income!",
		multiplier = 2,
	},
	AutoCollect = {
		id = 0,
		name = "Auto-Build",
		price = 149,
		description = "Automatically build structures when you can afford them!",
	},
	VIP = {
		id = 0,
		name = "VIP Commander",
		price = 399,
		description = "Unlock 3 exclusive VIP structures with massive output!",
	},
	SpeedBoost = {
		id = 0,
		name = "Jetpack",
		price = 99,
		description = "Move 1.5x faster!",
		speedMultiplier = 1.5,
	},
}

-- Developer Products — IDs set to 0, create in Creator Dashboard after publishing
GamePassConfig.Products = {
	SmallCashPack = {
		id = 0,
		name = "Small Credit Pack",
		price = 49,
		cashAmount = 10000,
		description = "+10,000 Credits",
	},
	LargeCashPack = {
		id = 0,
		name = "Large Credit Pack",
		price = 199,
		cashAmount = 50000,
		description = "+50,000 Credits",
	},
	InstantRebirth = {
		id = 0,
		name = "Instant Warp",
		price = 99,
		description = "Warp without meeting the credit requirement!",
	},
	TemporaryBoost = {
		id = 0,
		name = "5min 2x Boost",
		price = 29,
		duration = 300,
		multiplier = 2,
		description = "2x credits for 5 minutes!",
	},
}

return GamePassConfig
