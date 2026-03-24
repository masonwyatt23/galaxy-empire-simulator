--[[
	AntiAFK — Prevents Roblox auto-kick for idle players
	Keeps the connection alive so AFK income keeps flowing.
]]

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

-- Simulate activity every 60 seconds to prevent idle kick
player.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

print("[AntiAFK] Initialized")
