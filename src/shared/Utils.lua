local Utils = {}

-- Format large numbers with abbreviations (1000 -> 1K, 1000000 -> 1M)
function Utils.formatCash(amount)
	if amount >= 1e12 then
		return string.format("%.1fT", amount / 1e12)
	elseif amount >= 1e9 then
		return string.format("%.1fB", amount / 1e9)
	elseif amount >= 1e6 then
		return string.format("%.1fM", amount / 1e6)
	elseif amount >= 1e3 then
		return string.format("%.1fK", amount / 1e3)
	else
		return tostring(math.floor(amount))
	end
end

-- Calculate rebirth cost for a given rebirth count
function Utils.getRebirthCost(rebirthCount, config)
	return math.floor(config.Rebirth.baseCost * (config.Rebirth.costMultiplier ^ rebirthCount))
end

-- Calculate total income multiplier from rebirths + passes
function Utils.getIncomeMultiplier(rebirthCount, hasDoubleIncome, hasTempBoost, config)
	local mult = config.Rebirth.incomeMultiplier ^ rebirthCount
	if hasDoubleIncome then
		mult = mult * 2
	end
	if hasTempBoost then
		mult = mult * 2
	end
	return mult
end

-- Calculate total income per second for owned items
function Utils.getTotalIncome(ownedItems, multiplier, config)
	local total = 0
	for _, index in ipairs(ownedItems) do
		local item = config.TycoonItems[index]
		if item then
			total = total + item.income
		end
	end
	return total * multiplier
end

-- Deep copy a table
function Utils.deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = Utils.deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

return Utils
