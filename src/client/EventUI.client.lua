--[[
	EventUI — Shows event countdown and active event banner
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EventGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Event banner (top center, below HUD)
local banner = Instance.new("Frame")
banner.Name = "EventBanner"
banner.Size = UDim2.new(0.5, 0, 0, 30)
banner.Position = UDim2.new(0.25, 0, 0, 270)
banner.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = screenGui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 8)

local bannerText = Instance.new("TextLabel")
bannerText.Size = UDim2.new(1, 0, 1, 0)
bannerText.BackgroundTransparency = 1
bannerText.Text = ""
bannerText.TextColor3 = Color3.fromRGB(30, 30, 30)
bannerText.TextSize = 14
bannerText.Font = Enum.Font.GothamBold
bannerText.Parent = banner

-- State
local eventInfo = nil

local function formatTime(seconds)
	if seconds > 3600 then
		return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
	elseif seconds > 60 then
		return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
	else
		return seconds .. "s"
	end
end

-- Listen for events
task.spawn(function()
	local EventInfoRemote = Remotes:WaitForChild("EventInfo", 15)
	if not EventInfoRemote then return end

	EventInfoRemote.OnClientEvent:Connect(function(info)
		eventInfo = info
		if info.active then
			banner.Visible = true
			banner.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
			bannerText.TextColor3 = Color3.fromRGB(30, 30, 30)
			bannerText.Text = "EVENT: " .. info.name .. " — " .. formatTime(info.timeRemaining) .. " remaining!"
		elseif info.timeUntilNext and info.timeUntilNext < 7200 then
			banner.Visible = true
			banner.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
			bannerText.TextColor3 = Color3.fromRGB(255, 255, 255)
			bannerText.Text = "Next: " .. (info.nextEventName or "") .. " in " .. formatTime(info.timeUntilNext)
		else
			banner.Visible = false
		end
	end)
end)

print("[EventUI] Initialized")
