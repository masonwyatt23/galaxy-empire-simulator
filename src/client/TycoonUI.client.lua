--[[
	TycoonUI — Main HUD
	Displays cash, income rate, rebirth info, and next purchase.
	Purely cosmetic — all game state is server-authoritative.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local UpdateCash = Remotes:WaitForChild("UpdateCash", 15)
local UpdateItems = Remotes:WaitForChild("UpdateItems", 15)
local RequestData = Remotes:WaitForChild("RequestData", 15)
local PurchaseItem = Remotes:WaitForChild("PurchaseItem", 15)
local ItemPurchased = Remotes:WaitForChild("ItemPurchased", 15)
local RequestRebirth = Remotes:WaitForChild("RequestRebirth", 15)
local RebirthInfo = Remotes:WaitForChild("RebirthInfo", 15)
local RebirthSuccess = Remotes:WaitForChild("RebirthSuccess", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- State
local currentCash = 0
local ownedItems = {}
local rebirthData = {count = 0, cost = 0, currentMultiplier = 1, nextMultiplier = 1.5}

-- Build the UI
local function createHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TycoonHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Main frame (top center)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainPanel"
	mainFrame.Size = UDim2.new(0, 320, 0, 140)
	mainFrame.Position = UDim2.new(0.5, -160, 0, 10)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	mainFrame.BackgroundTransparency = 0.15
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = mainFrame

	-- Cash display
	local cashLabel = Instance.new("TextLabel")
	cashLabel.Name = "CashLabel"
	cashLabel.Size = UDim2.new(1, -20, 0, 40)
	cashLabel.Position = UDim2.new(0, 10, 0, 8)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Text = "$0"
	cashLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	cashLabel.TextSize = 32
	cashLabel.Font = Enum.Font.GothamBold
	cashLabel.TextXAlignment = Enum.TextXAlignment.Center
	cashLabel.Parent = mainFrame

	-- Income rate display
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.new(1, -20, 0, 20)
	incomeLabel.Position = UDim2.new(0, 10, 0, 48)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "$0/sec"
	incomeLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
	incomeLabel.TextSize = 16
	incomeLabel.Font = Enum.Font.Gotham
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Center
	incomeLabel.Parent = mainFrame

	-- Multiplier display
	local multLabel = Instance.new("TextLabel")
	multLabel.Name = "MultLabel"
	multLabel.Size = UDim2.new(0.5, -10, 0, 20)
	multLabel.Position = UDim2.new(0, 10, 0, 70)
	multLabel.BackgroundTransparency = 1
	multLabel.Text = "1.0x Multiplier"
	multLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
	multLabel.TextSize = 14
	multLabel.Font = Enum.Font.Gotham
	multLabel.TextXAlignment = Enum.TextXAlignment.Left
	multLabel.Parent = mainFrame

	-- Rebirth count
	local rebirthLabel = Instance.new("TextLabel")
	rebirthLabel.Name = "RebirthLabel"
	rebirthLabel.Size = UDim2.new(0.5, -10, 0, 20)
	rebirthLabel.Position = UDim2.new(0.5, 0, 0, 70)
	rebirthLabel.BackgroundTransparency = 1
	rebirthLabel.Text = "Rebirths: 0"
	rebirthLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
	rebirthLabel.TextSize = 14
	rebirthLabel.Font = Enum.Font.Gotham
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right
	rebirthLabel.Parent = mainFrame

	-- Items counter
	local itemsLabel = Instance.new("TextLabel")
	itemsLabel.Name = "ItemsLabel"
	itemsLabel.Size = UDim2.new(1, -20, 0, 20)
	itemsLabel.Position = UDim2.new(0, 10, 0, 92)
	itemsLabel.BackgroundTransparency = 1
	itemsLabel.Text = "Items: 0/18"
	itemsLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
	itemsLabel.TextSize = 13
	itemsLabel.Font = Enum.Font.Gotham
	itemsLabel.TextXAlignment = Enum.TextXAlignment.Center
	itemsLabel.Parent = mainFrame

	-- Next item info (bottom center)
	local nextFrame = Instance.new("Frame")
	nextFrame.Name = "NextItemPanel"
	nextFrame.Size = UDim2.new(0, 300, 0, 50)
	nextFrame.Position = UDim2.new(0.5, -150, 0, 140)
	nextFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	nextFrame.BackgroundTransparency = 0.15
	nextFrame.BorderSizePixel = 0
	nextFrame.Parent = screenGui

	local nextCorner = Instance.new("UICorner")
	nextCorner.CornerRadius = UDim.new(0, 10)
	nextCorner.Parent = nextFrame

	local nextLabel = Instance.new("TextLabel")
	nextLabel.Name = "NextItemLabel"
	nextLabel.Size = UDim2.new(1, -20, 1, 0)
	nextLabel.Position = UDim2.new(0, 10, 0, 0)
	nextLabel.BackgroundTransparency = 1
	nextLabel.Text = "Next: Lemonade Stand — FREE"
	nextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nextLabel.TextSize = 16
	nextLabel.Font = Enum.Font.Gotham
	nextLabel.TextXAlignment = Enum.TextXAlignment.Center
	nextLabel.Parent = nextFrame

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0, 120, 0, 40)
	buyButton.Position = UDim2.new(0.5, -60, 0, 195)
	buyButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
	buyButton.BorderSizePixel = 0
	buyButton.Text = "BUY"
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 20
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = screenGui

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton

	-- Rebirth button (bottom right)
	local rebirthButton = Instance.new("TextButton")
	rebirthButton.Name = "RebirthButton"
	rebirthButton.Size = UDim2.new(0, 160, 0, 45)
	rebirthButton.Position = UDim2.new(1, -170, 1, -55)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	rebirthButton.BorderSizePixel = 0
	rebirthButton.Text = "REBIRTH\n$1M"
	rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthButton.TextSize = 14
	rebirthButton.Font = Enum.Font.GothamBold
	rebirthButton.Parent = screenGui

	local rebirthCorner = Instance.new("UICorner")
	rebirthCorner.CornerRadius = UDim.new(0, 8)
	rebirthCorner.Parent = rebirthButton

	-- Shop button (bottom left)
	local shopButton = Instance.new("TextButton")
	shopButton.Name = "ShopButton"
	shopButton.Size = UDim2.new(0, 120, 0, 45)
	shopButton.Position = UDim2.new(0, 10, 1, -55)
	shopButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
	shopButton.BorderSizePixel = 0
	shopButton.Text = "SHOP"
	shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopButton.TextSize = 18
	shopButton.Font = Enum.Font.GothamBold
	shopButton.Parent = screenGui

	local shopCorner = Instance.new("UICorner")
	shopCorner.CornerRadius = UDim.new(0, 8)
	shopCorner.Parent = shopButton

	-- Codes button (next to shop)
	local codesButton = Instance.new("TextButton")
	codesButton.Name = "CodesButton"
	codesButton.Size = UDim2.new(0, 100, 0, 45)
	codesButton.Position = UDim2.new(0, 140, 1, -55)
	codesButton.BackgroundColor3 = Color3.fromRGB(150, 80, 200)
	codesButton.BorderSizePixel = 0
	codesButton.Text = "CODES"
	codesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	codesButton.TextSize = 16
	codesButton.Font = Enum.Font.GothamBold
	codesButton.Parent = screenGui

	local codesCorner = Instance.new("UICorner")
	codesCorner.CornerRadius = UDim.new(0, 8)
	codesCorner.Parent = codesButton

	-- Daily reward button (next to codes)
	local dailyButton = Instance.new("TextButton")
	dailyButton.Name = "DailyButton"
	dailyButton.Size = UDim2.new(0, 100, 0, 45)
	dailyButton.Position = UDim2.new(0, 250, 1, -55)
	dailyButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
	dailyButton.BorderSizePixel = 0
	dailyButton.Text = "DAILY"
	dailyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	dailyButton.TextSize = 16
	dailyButton.Font = Enum.Font.GothamBold
	dailyButton.Parent = screenGui

	local dailyCorner = Instance.new("UICorner")
	dailyCorner.CornerRadius = UDim.new(0, 8)
	dailyCorner.Parent = dailyButton

	-- Quests button
	local questsButton = Instance.new("TextButton")
	questsButton.Name = "QuestsButton"
	questsButton.Size = UDim2.new(0, 100, 0, 45)
	questsButton.Position = UDim2.new(0, 360, 1, -55)
	questsButton.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
	questsButton.BorderSizePixel = 0
	questsButton.Text = "QUESTS"
	questsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	questsButton.TextSize = 16
	questsButton.Font = Enum.Font.GothamBold
	questsButton.Parent = screenGui

	local questsCorner = Instance.new("UICorner")
	questsCorner.CornerRadius = UDim.new(0, 8)
	questsCorner.Parent = questsButton

	-- Explore button (next to quests)
	local exploreButton = Instance.new("TextButton")
	exploreButton.Name = "ExploreButton"
	exploreButton.Size = UDim2.new(0, 100, 0, 45)
	exploreButton.Position = UDim2.new(0, 470, 1, -55)
	exploreButton.BackgroundColor3 = Color3.fromRGB(80, 50, 180)
	exploreButton.BorderSizePixel = 0
	exploreButton.Text = "EXPLORE"
	exploreButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	exploreButton.TextSize = 16
	exploreButton.Font = Enum.Font.GothamBold
	exploreButton.Parent = screenGui

	local exploreCorner = Instance.new("UICorner")
	exploreCorner.CornerRadius = UDim.new(0, 8)
	exploreCorner.Parent = exploreButton

	-- Trade button (next to explore)
	local tradeButton = Instance.new("TextButton")
	tradeButton.Name = "TradeButton"
	tradeButton.Size = UDim2.new(0, 100, 0, 45)
	tradeButton.Position = UDim2.new(0, 580, 1, -55)
	tradeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
	tradeButton.BorderSizePixel = 0
	tradeButton.Text = "TRADE"
	tradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	tradeButton.TextSize = 16
	tradeButton.Font = Enum.Font.GothamBold
	tradeButton.Parent = screenGui

	local tradeCorner = Instance.new("UICorner")
	tradeCorner.CornerRadius = UDim.new(0, 8)
	tradeCorner.Parent = tradeButton

	-- Progress bar (below Next Item panel)
	local progressFrame = Instance.new("Frame")
	progressFrame.Name = "ProgressBar"
	progressFrame.Size = UDim2.new(0, 300, 0, 18)
	progressFrame.Position = UDim2.new(0.5, -150, 0, 245)
	progressFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	progressFrame.BorderSizePixel = 0
	progressFrame.Parent = screenGui

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 6)
	progressCorner.Parent = progressFrame

	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressFrame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = progressFill

	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Size = UDim2.new(1, 0, 1, 0)
	progressText.BackgroundTransparency = 1
	progressText.Text = ""
	progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressText.TextSize = 11
	progressText.Font = Enum.Font.GothamBold
	progressText.ZIndex = 2
	progressText.Parent = progressFrame

	return screenGui
end

local hud = createHUD()

-- Update functions
local function updateCashDisplay()
	local cashLabel = hud.MainPanel.CashLabel
	cashLabel.Text = "$" .. Utils.formatCash(currentCash)
end

local function updateIncomeDisplay()
	-- Estimate income (client-side approximation for display only)
	local totalIncome = 0
	for _, index in ipairs(ownedItems) do
		local item = GameConfig.TycoonItems[index]
		if item then
			totalIncome = totalIncome + item.income
		end
	end
	totalIncome = totalIncome * (rebirthData.currentMultiplier or 1)
	hud.MainPanel.IncomeLabel.Text = "$" .. Utils.formatCash(totalIncome) .. "/sec"
end

local function updateNextItem()
	local nextIndex = #ownedItems + 1
	local nextItem = GameConfig.TycoonItems[nextIndex]
	local nextLabel = hud.NextItemPanel.NextItemLabel
	local buyButton = hud.BuyButton

	if nextItem then
		local costText = nextItem.cost == 0 and "FREE" or ("$" .. Utils.formatCash(nextItem.cost))
		nextLabel.Text = "Next: " .. nextItem.name .. " — " .. costText
		buyButton.Visible = true

		if currentCash >= nextItem.cost then
			buyButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
			buyButton.Text = "BUY"
		else
			buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			buyButton.Text = "BUY"
		end
	else
		nextLabel.Text = "All items purchased! Time to rebirth?"
		buyButton.Visible = false
	end
end

local function updateRebirthDisplay()
	local rebirthLabel = hud.MainPanel.RebirthLabel
	rebirthLabel.Text = "Rebirths: " .. rebirthData.count

	local multLabel = hud.MainPanel.MultLabel
	multLabel.Text = string.format("%.1fx Multiplier", rebirthData.currentMultiplier)

	local rebirthButton = hud.RebirthButton
	rebirthButton.Text = "REBIRTH\n$" .. Utils.formatCash(rebirthData.cost)

	if currentCash >= rebirthData.cost then
		rebirthButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	else
		rebirthButton.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
	end
end

local function updateAll()
	updateCashDisplay()
	updateIncomeDisplay()
	updateNextItem()
	updateRebirthDisplay()
end

-- Event handlers (cash handler is below with progress bar)

UpdateItems.OnClientEvent:Connect(function(items)
	ownedItems = items
	updateIncomeDisplay()
	updateNextItem()
	-- Update items counter
	local itemsLabel = hud.MainPanel:FindFirstChild("ItemsLabel")
	if itemsLabel then
		itemsLabel.Text = "Items: " .. #ownedItems .. "/" .. #GameConfig.TycoonItems
	end
end)

RebirthInfo.OnClientEvent:Connect(function(info)
	rebirthData = info
	updateRebirthDisplay()
	updateIncomeDisplay()
end)

ItemPurchased.OnClientEvent:Connect(function(itemIndex, itemName)
	-- Flash effect could go here
end)

RebirthSuccess.OnClientEvent:Connect(function(newCount)
	rebirthData.count = newCount
	updateAll()
end)

-- Button clicks
hud.BuyButton.MouseButton1Click:Connect(function()
	local nextIndex = #ownedItems + 1
	PurchaseItem:FireServer(nextIndex)
end)

hud.RebirthButton.MouseButton1Click:Connect(function()
	RequestRebirth:FireServer()
end)

hud.ShopButton.MouseButton1Click:Connect(function()
	-- Toggle shop visibility (ShopUI handles this)
	local shopGui = PlayerGui:FindFirstChild("ShopGUI")
	if shopGui then
		local frame = shopGui:FindFirstChild("ShopFrame")
		if frame then
			frame.Visible = not frame.Visible
		end
	end
end)

-- Codes button
hud.CodesButton.MouseButton1Click:Connect(function()
	local codeGui = PlayerGui:FindFirstChild("CodeGUI")
	if codeGui then
		local frame = codeGui:FindFirstChild("CodeFrame")
		if frame then
			frame.Visible = not frame.Visible
		end
	elseif _G.ShowCodeUI then
		_G.ShowCodeUI()
	end
end)

-- Daily reward button
hud.DailyButton.MouseButton1Click:Connect(function()
	if _G.PlayButtonClick then _G.PlayButtonClick() end
	if _G.ShowDailyReward then
		_G.ShowDailyReward()
	end
end)

-- Quests button
hud.QuestsButton.MouseButton1Click:Connect(function()
	if _G.PlayButtonClick then _G.PlayButtonClick() end
	local questGui = PlayerGui:FindFirstChild("QuestGUI")
	if questGui then
		local frame = questGui:FindFirstChild("QuestFrame")
		if frame then
			frame.Visible = not frame.Visible
		end
	elseif _G.ShowQuestUI then
		_G.ShowQuestUI()
	end
end)

-- Explore button
hud.ExploreButton.MouseButton1Click:Connect(function()
	if _G.PlayButtonClick then _G.PlayButtonClick() end
	if _G.ShowExploreUI then
		_G.ShowExploreUI()
	end
end)

-- Trade button
hud.TradeButton.MouseButton1Click:Connect(function()
	if _G.PlayButtonClick then _G.PlayButtonClick() end
	if _G.ShowTradeUI then
		_G.ShowTradeUI()
	end
end)

-- Progress bar update
local function updateProgressBar()
	local nextIndex = #ownedItems + 1
	local nextItem = GameConfig.TycoonItems[nextIndex]
	local progressBar = hud.ProgressBar
	local fill = progressBar and progressBar:FindFirstChild("Fill")
	local text = progressBar and progressBar:FindFirstChild("ProgressText")

	if not progressBar or not fill or not text then return end

	if nextItem then
		local pct = nextItem.cost > 0 and math.clamp(currentCash / nextItem.cost, 0, 1) or 1
		fill.Size = UDim2.new(pct, 0, 1, 0)

		-- Time estimate
		local totalIncome = 0
		for _, index in ipairs(ownedItems) do
			local item = GameConfig.TycoonItems[index]
			if item then totalIncome = totalIncome + item.income end
		end
		totalIncome = totalIncome * (rebirthData.currentMultiplier or 1)

		local remaining = nextItem.cost - currentCash
		if totalIncome > 0 and remaining > 0 then
			local seconds = math.ceil(remaining / totalIncome)
			if seconds < 60 then
				text.Text = math.floor(pct * 100) .. "% — ~" .. seconds .. "s"
			else
				text.Text = math.floor(pct * 100) .. "% — ~" .. math.ceil(seconds / 60) .. "m"
			end
		elseif remaining <= 0 then
			text.Text = "100% — Ready to buy!"
		else
			text.Text = math.floor(pct * 100) .. "%"
		end
	else
		fill.Size = UDim2.new(1, 0, 1, 0)
		text.Text = "All items purchased!"
		fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	end
end

-- Hook progress bar into cash updates
UpdateCash.OnClientEvent:Connect(function(cash)
	currentCash = cash
	updateCashDisplay()
	updateNextItem()
	updateRebirthDisplay()
	updateProgressBar()
end)

-- Request initial data
task.wait(1)
RequestData:FireServer()

print("[TycoonUI] Initialized")
