--[[
	ShopUI — Game Pass & Developer Product shop
	Displays purchasable items and handles purchase prompts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GamePassConfig = require(Shared:WaitForChild("GamePassConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PromptGamePass = Remotes:WaitForChild("PromptGamePass", 15)
local PromptProduct = Remotes:WaitForChild("PromptProduct", 15)
local GamePassStatus = Remotes:WaitForChild("GamePassStatus", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Owned passes cache
local ownedPasses = {}

-- Build shop UI
local function createShop()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Main frame (centered, hidden by default)
	local shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.Size = UDim2.new(0, 450, 0, 500)
	shopFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
	shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	shopFrame.BackgroundTransparency = 0.05
	shopFrame.BorderSizePixel = 0
	shopFrame.Visible = false
	shopFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = shopFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 150, 255)
	stroke.Thickness = 2
	stroke.Parent = shopFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 45)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "SHOP"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.Parent = shopFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 35, 0, 35)
	closeBtn.Position = UDim2.new(1, -40, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 18
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = shopFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		shopFrame.Visible = false
	end)

	-- Scroll frame for items
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ItemList"
	scrollFrame.Size = UDim2.new(1, -20, 1, -55)
	scrollFrame.Position = UDim2.new(0, 10, 0, 50)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = shopFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Section header helper
	local function addSection(text, order)
		local header = Instance.new("TextLabel")
		header.Name = "Header_" .. text
		header.Size = UDim2.new(1, 0, 0, 30)
		header.BackgroundTransparency = 1
		header.Text = text
		header.TextColor3 = Color3.fromRGB(255, 215, 0)
		header.TextSize = 18
		header.Font = Enum.Font.GothamBold
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.LayoutOrder = order
		header.Parent = scrollFrame
	end

	-- Item card helper
	local function addItem(name, description, priceText, buttonText, buttonColor, onClick, order, isOwned)
		local card = Instance.new("Frame")
		card.Name = "Item_" .. name
		card.Size = UDim2.new(1, 0, 0, 65)
		card.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		card.BorderSizePixel = 0
		card.LayoutOrder = order
		card.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = card

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.6, -10, 0, 25)
		nameLabel.Position = UDim2.new(0, 10, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 16
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.6, -10, 0, 20)
		descLabel.Position = UDim2.new(0, 10, 0, 30)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = description
		descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		descLabel.TextSize = 12
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = card

		-- Buy button
		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 110, 0, 35)
		buyBtn.Position = UDim2.new(1, -120, 0.5, -17)
		buyBtn.BorderSizePixel = 0
		buyBtn.TextSize = 14
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Parent = card

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = buyBtn

		if isOwned then
			buyBtn.Text = "OWNED"
			buyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		else
			buyBtn.Text = priceText
			buyBtn.BackgroundColor3 = buttonColor
			buyBtn.MouseButton1Click:Connect(onClick)
		end

		return card, buyBtn
	end

	-- Game Passes section
	addSection("Game Passes", 0)

	local order = 1
	for passKey, passInfo in pairs(GamePassConfig.Passes) do
		local isOwned = ownedPasses[passKey] == true
		addItem(
			passInfo.name,
			passInfo.description,
			"R$ " .. passInfo.price,
			"BUY",
			Color3.fromRGB(50, 150, 50),
			function()
				PromptGamePass:FireServer(passKey)
			end,
			order,
			isOwned
		)
		order = order + 1
	end

	-- Developer Products section
	addSection("Boosts & Packs", order)
	order = order + 1

	for productKey, productInfo in pairs(GamePassConfig.Products) do
		addItem(
			productInfo.name,
			productInfo.description,
			"R$ " .. productInfo.price,
			"BUY",
			Color3.fromRGB(50, 100, 200),
			function()
				PromptProduct:FireServer(productKey)
			end,
			order,
			false
		)
		order = order + 1
	end

	-- Update canvas size
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)

	return screenGui
end

local shopGui = createShop()

-- Update owned status when server sends game pass info
local function refreshShop()
	-- Destroy and recreate (simple approach for small shop)
	shopGui:Destroy()
	shopGui = createShop()
end

GamePassStatus.OnClientEvent:Connect(function(passes)
	ownedPasses = passes or {}
	refreshShop()
end)

print("[ShopUI] Initialized")
