--[[
	TutorialManager — First-time player onboarding
	5-step guided tutorial that only shows once.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateItems = Remotes:WaitForChild("UpdateItems")
local ItemPurchased = Remotes:WaitForChild("ItemPurchased")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Tutorial state
local tutorialStep = 0
local tutorialActive = false
_G.TutorialActive = false

-- Create tutorial UI elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TutorialGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Popup frame
local popup = Instance.new("Frame")
popup.Name = "TutorialPopup"
popup.Size = UDim2.new(0, 400, 0, 120)
popup.Position = UDim2.new(0.5, -200, 0.65, 0)
popup.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
popup.BackgroundTransparency = 0.1
popup.BorderSizePixel = 0
popup.Visible = false
popup.Parent = screenGui

local popupCorner = Instance.new("UICorner")
popupCorner.CornerRadius = UDim.new(0, 12)
popupCorner.Parent = popup

local popupStroke = Instance.new("UIStroke")
popupStroke.Color = Color3.fromRGB(100, 200, 255)
popupStroke.Thickness = 2
popupStroke.Parent = popup

local popupText = Instance.new("TextLabel")
popupText.Name = "Text"
popupText.Size = UDim2.new(1, -20, 0.6, 0)
popupText.Position = UDim2.new(0, 10, 0, 10)
popupText.BackgroundTransparency = 1
popupText.Text = ""
popupText.TextColor3 = Color3.fromRGB(255, 255, 255)
popupText.TextSize = 18
popupText.Font = Enum.Font.Gotham
popupText.TextWrapped = true
popupText.TextXAlignment = Enum.TextXAlignment.Center
popupText.Parent = popup

local dismissBtn = Instance.new("TextButton")
dismissBtn.Name = "Dismiss"
dismissBtn.Size = UDim2.new(0, 100, 0, 30)
dismissBtn.Position = UDim2.new(0.5, -50, 1, -40)
dismissBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
dismissBtn.BorderSizePixel = 0
dismissBtn.Text = "GOT IT"
dismissBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dismissBtn.TextSize = 14
dismissBtn.Font = Enum.Font.GothamBold
dismissBtn.Parent = popup

local dismissCorner = Instance.new("UICorner")
dismissCorner.CornerRadius = UDim.new(0, 6)
dismissCorner.Parent = dismissBtn

-- Show a tutorial popup
local function showPopup(text, autoDismissTime)
	popupText.Text = text
	popup.Visible = true
	popup.BackgroundTransparency = 0.1

	-- Slide in animation
	popup.Position = UDim2.new(0.5, -200, 0.7, 0)
	TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -200, 0.65, 0),
	}):Play()

	if autoDismissTime then
		task.delay(autoDismissTime, function()
			if popup.Visible then
				popup.Visible = false
			end
		end)
	end
end

local function hidePopup()
	popup.Visible = false
end

-- Tutorial steps
local steps = {
	{text = "Welcome to Galaxy Empire Simulator! Conquer the cosmos!", delay = 0},
	{text = "Step on the green pads to buy businesses! Your Lemonade Stand was purchased automatically.", delay = 2},
	{text = "Watch your credits grow! Build the next structure when you can afford it.", waitForPurchase = true},
	{text = "Great job! Keep buying businesses to increase your income. Check out the SHOP for boosts!", delay = 5},
	{text = "When you've earned enough, hit REBIRTH to reset and earn even faster!", delay = 6},
}

local function advanceTutorial()
	tutorialStep = tutorialStep + 1

	if tutorialStep > #steps then
		tutorialActive = false
		_G.TutorialActive = false
		hidePopup()
		-- Mark tutorial complete
		local TutorialComplete = Remotes:FindFirstChild("TutorialComplete")
		if TutorialComplete then
			TutorialComplete:FireServer()
		end
		return
	end

	local step = steps[tutorialStep]
	showPopup(step.text, step.delay)
end

-- Dismiss button
dismissBtn.MouseButton1Click:Connect(function()
	if _G.PlayButtonClick then _G.PlayButtonClick() end
	hidePopup()
	if tutorialActive then
		advanceTutorial()
	end
end)

-- Listen for first purchase to advance tutorial
ItemPurchased.OnClientEvent:Connect(function(itemIndex)
	if tutorialActive and tutorialStep == 3 then
		-- Player just bought something during the "buy next business" step
		task.wait(0.5)
		advanceTutorial()
	end
end)

-- Check if tutorial should run (wait for server data)
task.spawn(function()
	-- Wait for TutorialInfo from server
	local TutorialInfo = Remotes:WaitForChild("TutorialInfo", 10)
	if not TutorialInfo then
		-- Create the remote listener in case it arrives later
		return
	end

	TutorialInfo.OnClientEvent:Connect(function(shouldShow)
		if shouldShow then
			tutorialActive = true
			_G.TutorialActive = true
			task.wait(2) -- let player land on plot first
			advanceTutorial()
		end
	end)
end)

print("[TutorialManager] Initialized")
