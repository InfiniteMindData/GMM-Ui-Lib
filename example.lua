-- example.lua
-- Default example used by the repo. See examples/ for more.
--
-- GMM UI v2.0 - GTA V style Roblox mod menu UI
-- This script demonstrates the most common item types.

local GmmUI = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/InfiniteMindData/GMM-Ui-Lib/main/src.lua?t=" .. tick()
))()

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")

local LP = Players.LocalPlayer
local function chr()  return LP.Character or LP.CharacterAdded:Wait() end
local function hum()  return chr():FindFirstChildOfClass("Humanoid") end
local function root() return chr():FindFirstChild("HumanoidRootPart") end

----------------------------------------------------------------- UI
local ui = GmmUI.new({
	Title = "MY MENU",
	Theme = "Default",   -- Default | Native | Dark | Light | Cherry | Ocean | Synthwave | Midnight
})

local home    = ui:NewMenu("HOME")
local player  = ui:NewMenu("PLAYER")
local world   = ui:NewMenu("WORLD")
local tpMenu  = ui:NewMenu("TELEPORT")
local config  = ui:NewMenu("CONFIG")

------------------------------- HOME
home:Section("CATEGORIES")
home:Submenu("Player",    "Speed, jump, godmode.",  player)
home:Submenu("World",     "Time / gravity.",        world)
home:Submenu("Teleport",  "Move around the map.",   tpMenu)
home:Submenu("Config",    "Theme / save / load.",   config)

home:Section("ABOUT")
home:Label("GMM UI v2.0", "Press F4 or Insert to toggle.")

------------------------------- PLAYER
local godT = player:Toggle("God Mode", "Become invincible.", false, function(on)
	local h = hum(); if not h then return end
	h.MaxHealth = on and math.huge or 100
	h.Health    = h.MaxHealth
end)

player:Slider("Walk Speed", "Movement speed.", 16, 250, 1, 16, function(v)
	local h = hum(); if h then h.WalkSpeed = v end
end)

player:Slider("Jump Power", "Jump force.", 50, 500, 5, 50, function(v)
	local h = hum(); if h then h.JumpPower = v end
end)

player:Toggle("Invisible", "Hide your character parts.", false, function(on)
	for _, p in ipairs(chr():GetDescendants()) do
		if p:IsA("BasePart") or p:IsA("Decal") then
			p.Transparency = on and 1 or 0
		end
	end
end)

player:KeyBind("God Mode Hotkey", "Press Enter then any key.",
	Enum.KeyCode.G, function(key)
		ui:BindKey(key, function()
			godT:Set(not godT:Get())
		end)
	end)

------------------------------- WORLD
world:Slider("Clock Time", "0-24 hour clock.", 0, 24, 0.25, 12, function(t)
	Lighting.ClockTime = t
end)
world:Slider("Gravity", "World gravity.", 0, 500, 5, 196, function(v)
	Workspace.Gravity = v
end)
world:List("Time Preset", "Quick presets.",
	{"Dawn", "Noon", "Sunset", "Midnight"}, 2, function(p)
		Lighting.ClockTime = ({ Dawn=6, Noon=12, Sunset=18, Midnight=0 })[p]
	end)

------------------------------- TELEPORT
tpMenu:Button("Sky teleport", "Up 500 studs.", function()
	if root() then root().CFrame = root().CFrame + Vector3.new(0, 500, 0) end
end)
tpMenu:Input("Custom Coords", "Format: x,y,z", "", "0,50,0", function(text)
	local x, y, z = text:match("([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+)")
	if x and root() then
		root().CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z))
	end
end)

------------------------------- CONFIG
config:List("Theme", "Live theme switch.",
	{ "Default", "Native", "Dark", "Light", "Cherry", "Ocean", "Synthwave", "Midnight" },
	1, function(t) ui:SetTheme(t) end)

config:Color("Custom Accent", "Pick any color.",
	Color3.fromRGB(168, 26, 26), function(c)
		ui.Opts.Accent = c
		ui:SetTheme(ui._theme)  -- redraw with override
		ui.Header.BackgroundColor3 = c
	end)

config:Button("Save Config", "", function()
	if ui:SaveConfig("gmm_config.json") then
		ui:Notify({ Title="Saved", Content="Config saved!", Type="Success" })
	else
		ui:Notify({ Title="Save failed", Content="writefile unavailable", Type="Error" })
	end
end)

config:Button("Load Config", "", function()
	if ui:LoadConfig("gmm_config.json") then
		ui:Notify({ Title="Loaded", Content="Config loaded!", Type="Success" })
	end
end)

config:Button("Test Notification", "", function()
	ui:Notify({ Title="Hello!", Content="This is a notification.", Type="Info" })
end)

----------------------------------------------------------------- Show
ui:PushMenu(home)
ui:Notify({ Title="GMM UI v2.0", Content="Press F4 to toggle.", Type="Success", Duration=4 })
