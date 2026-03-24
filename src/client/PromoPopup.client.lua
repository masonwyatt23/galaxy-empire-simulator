--[[
	PromoPopup — Timed game pass promotion
	Shows a non-intrusive popup after 2 minutes suggesting game passes.
	Key monetization driver — catches engaged players at peak interest.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GamePassConfig = require(Shared:WaitForChild("GamePassConfig"))

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Build promo UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PromoGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local promoFrame = Instance.new("Frame")
promoFrame.Name = "PromoFrame"
promoFrame.Size = UDim2.new(0, 350, 0, 200)
promoFrame.Position = UDim2.new(1, 0, 0.5, -100) -- Start offscreen right
promoFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
promoFrame.BackgroundTransparency = 0.05
promoFrame.BorderSizePixel = 0
promoFrame.Visible = false
promoFrame.ZIndex = 80
promoFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = promoFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 2
stroke.Parent = promoFrame

-- Glow effect
local glow = Instance.new("ImageLabel")
glow.Size = UDim2.new(1, 20, 1, 20)
glow.Position = UDim2.new(0, -10, 0, -10)
glow.BackgroundTransparency = 1
glow.ImageTransparency = 0.7
glow.ImageColor3 = Color3.fromRGB(255, 215, 0)
glow.ZIndex = 79
glow.Parent = promoFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 30)
title.Position = UDim2.new(0, 15, 0, 10)
title.BackgroundTransparency = 1
title.Text = "BOOST YOUR GALAXY!"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 81
title.Parent = promoFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 82
closeBtn.Parent = promoFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Pass suggestions (2 rows)
local passes = {
	{key = "DoubleIncome", label = "2x CREDITS", color = Color3.fromRGB(50, 200, 50), desc = "Double all credits forever!"},
	{key = "AutoCollect", label = "AUTO-BUILD", color = Color3.fromRGB(50, 150, 255), desc = "Auto-build structures!"},
	{key = "VIP", label = "VIP COMMANDER", color = Color3.fromRGB(255, 100, 100), desc = "3 exclusive VIP structures!"},
	{key = "SpeedBoost", label = "JETPACK", color = Color3.fromRGB(50, 200, 150), desc = "Move 1.5x faster!"},
}

for i, passInfo in ipairs(passes) do
	local passData = GamePassConfig.Passes[passInfo.key]
	if not passData then continue end

	local row = math.ceil(i / 2)
	local col = ((i - 1) % 2) + 1

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 155, 0, 55)
	btn.Position = UDim2.new(0, 10 + (col - 1) * 165, 0, 40 + (row - 1) * 65)
	btn.BackgroundColor3 = passInfo.color
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.ZIndex = 81
	btn.Parent = promoFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = passInfo.label
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 13
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 82
	nameLabel.Parent = btn

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -10, 0, 16)
	priceLabel.Position = UDim2.new(0, 5, 0, 25)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "R$" .. passData.price .. " — " .. passInfo.desc
	priceLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	priceLabel.TextSize = 10
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.TextWrapped = true
	priceLabel.ZIndex = 82
	priceLabel.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if _G.PlayButtonClick then _G.PlayButtonClick() end
		MarketplaceService:PromptGamePassPurchase(player, passData.id)
	end)
end

-- "Not now" text at bottom
local notNow = Instance.new("TextLabel")
notNow.Size = UDim2.new(1, -20, 0, 20)
notNow.Position = UDim2.new(0, 10, 1, -25)
notNow.BackgroundTransparency = 1
notNow.Text = "Click X to dismiss — these are always in the SHOP"
notNow.TextColor3 = Color3.fromRGB(140, 140, 140)
notNow.TextSize = 10
notNow.Font = Enum.Font.Gotham
notNow.ZIndex = 81
notNow.Parent = promoFrame

-- Show/hide animation
local function showPromo()
	promoFrame.Visible = true
	promoFrame.Position = UDim2.new(1, 0, 0.5, -100)
	TweenService:Create(promoFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -365, 0.5, -100),
	}):Play()
end

local function hidePromo()
	local tween = TweenService:Create(promoFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 0, 0.5, -100),
	})
	tween:Play()
	tween.Completed:Connect(function()
		promoFrame.Visible = false
	end)
end

closeBtn.MouseButton1Click:Connect(function()
	if _G.PlayButtonClick then _G.PlayButtonClick() end
	hidePromo()
end)

-- Show after 2 minutes of play, then again every 10 minutes
task.spawn(function()
	task.wait(120) -- 2 minutes

	-- Don't show if tutorial is still active
	while _G.TutorialActive do
		task.wait(5)
	end

	showPromo()

	-- Auto-dismiss after 15 seconds if not interacted with
	task.delay(15, function()
		if promoFrame.Visible then
			hidePromo()
		end
	end)

	-- Show again every 10 minutes
	while true do
		task.wait(600) -- 10 minutes
		showPromo()
		task.delay(12, function()
			if promoFrame.Visible then
				hidePromo()
			end
		end)
	end
end)

print("[PromoPopup] Initialized")
