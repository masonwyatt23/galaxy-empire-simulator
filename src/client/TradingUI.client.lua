--[[
	TradingUI — Player-to-player gifting interface
	Allows selecting a player and amount to send cash.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local SendGift = Remotes:WaitForChild("SendGift", 15)
local GiftResult = Remotes:WaitForChild("GiftResult", 15)
local GiftReceived = Remotes:WaitForChild("GiftReceived", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

-- Build UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TradingGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Trade Frame
local tradeFrame = Instance.new("Frame")
tradeFrame.Name = "TradeFrame"
tradeFrame.Size = UDim2.new(0, 350, 0, 320)
tradeFrame.Position = UDim2.new(0.5, -175, 0.5, -160)
tradeFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
tradeFrame.BackgroundTransparency = 0.1
tradeFrame.BorderSizePixel = 0
tradeFrame.Visible = false
tradeFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = tradeFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 2
stroke.Transparency = 0.3
stroke.Parent = tradeFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 35)
title.Position = UDim2.new(0, 15, 0, 8)
title.BackgroundTransparency = 1
title.Text = "SEND GIFT"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = tradeFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = tradeFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	tradeFrame.Visible = false
end)

-- Player selection label
local selectLabel = Instance.new("TextLabel")
selectLabel.Size = UDim2.new(1, -30, 0, 20)
selectLabel.Position = UDim2.new(0, 15, 0, 50)
selectLabel.BackgroundTransparency = 1
selectLabel.Text = "Select Player:"
selectLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
selectLabel.TextSize = 14
selectLabel.Font = Enum.Font.Gotham
selectLabel.TextXAlignment = Enum.TextXAlignment.Left
selectLabel.Parent = tradeFrame

-- Player list (scrolling)
local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(1, -30, 0, 100)
playerList.Position = UDim2.new(0, 15, 0, 72)
playerList.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 4
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.Parent = tradeFrame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = playerList

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = playerList

local selectedPlayer = nil
local playerButtons = {}

local function refreshPlayerList()
	for _, btn in pairs(playerButtons) do
		btn:Destroy()
	end
	playerButtons = {}

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local btn = Instance.new("TextButton")
			btn.Name = p.Name
			btn.Size = UDim2.new(1, 0, 0, 28)
			btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
			btn.BorderSizePixel = 0
			btn.Text = "  " .. p.Name
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextSize = 14
			btn.Font = Enum.Font.Gotham
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Parent = playerList

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 4)
			btnCorner.Parent = btn

			btn.MouseButton1Click:Connect(function()
				selectedPlayer = p.Name
				for _, b in pairs(playerButtons) do
					b.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
				end
				btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
			end)

			table.insert(playerButtons, btn)
		end
	end
end

-- Amount label
local amountLabel = Instance.new("TextLabel")
amountLabel.Size = UDim2.new(1, -30, 0, 20)
amountLabel.Position = UDim2.new(0, 15, 0, 180)
amountLabel.BackgroundTransparency = 1
amountLabel.Text = "Amount (10% tax applied):"
amountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
amountLabel.TextSize = 14
amountLabel.Font = Enum.Font.Gotham
amountLabel.TextXAlignment = Enum.TextXAlignment.Left
amountLabel.Parent = tradeFrame

-- Amount input
local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.new(1, -30, 0, 35)
amountBox.Position = UDim2.new(0, 15, 0, 202)
amountBox.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
amountBox.BorderSizePixel = 0
amountBox.PlaceholderText = "Enter amount..."
amountBox.Text = ""
amountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
amountBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
amountBox.TextSize = 16
amountBox.Font = Enum.Font.Gotham
amountBox.ClearTextOnFocus = true
amountBox.Parent = tradeFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = amountBox

-- Send button
local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(1, -30, 0, 40)
sendBtn.Position = UDim2.new(0, 15, 0, 245)
sendBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
sendBtn.BorderSizePixel = 0
sendBtn.Text = "SEND GIFT"
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.TextSize = 18
sendBtn.Font = Enum.Font.GothamBold
sendBtn.Parent = tradeFrame

local sendCorner = Instance.new("UICorner")
sendCorner.CornerRadius = UDim.new(0, 8)
sendCorner.Parent = sendBtn

-- Result label
local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(1, -30, 0, 20)
resultLabel.Position = UDim2.new(0, 15, 0, 292)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = ""
resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
resultLabel.TextSize = 12
resultLabel.Font = Enum.Font.Gotham
resultLabel.TextWrapped = true
resultLabel.Parent = tradeFrame

sendBtn.MouseButton1Click:Connect(function()
	if not selectedPlayer then
		resultLabel.Text = "Select a player first!"
		resultLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end

	local amount = tonumber(amountBox.Text)
	if not amount or amount < 100 then
		resultLabel.Text = "Enter a valid amount (min $100)"
		resultLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end

	SendGift:FireServer(selectedPlayer, amount)
	sendBtn.Text = "Sending..."
	sendBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
end)

-- Gift result handler
GiftResult.OnClientEvent:Connect(function(success, message)
	resultLabel.Text = message
	resultLabel.TextColor3 = success and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	sendBtn.Text = "SEND GIFT"
	sendBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)

	task.delay(4, function()
		resultLabel.Text = ""
	end)
end)

-- Gift received notification
GiftReceived.OnClientEvent:Connect(function(senderName, amount)
	resultLabel.Text = senderName .. " sent you $" .. Utils.formatCash(amount) .. "!"
	resultLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	tradeFrame.Visible = true

	task.delay(5, function()
		resultLabel.Text = ""
	end)
end)

-- Global toggle
_G.ShowTradeUI = function()
	tradeFrame.Visible = not tradeFrame.Visible
	if tradeFrame.Visible then
		refreshPlayerList()
	end
end

-- Refresh player list when trade frame is shown
tradeFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if tradeFrame.Visible then
		refreshPlayerList()
	end
end)

print("[TradingUI] Initialized")
