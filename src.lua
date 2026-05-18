-- ==== src\01_header.lua ====
--[[
================================================================================
  GMM UI Library v2.0  -  A Roblox UI library styled after GTA V mod menus
  (Menyoo / NativeUI inspired)

  Repo:    https://github.com/InfiniteMindData/GMM-Ui-Lib
  License: MIT

  This file is auto-generated from src/*.lua. To regenerate after editing
  modules, run:  lua build.lua
================================================================================
]]

local Players              = game:GetService("Players")
local UserInputService     = game:GetService("UserInputService")
local TweenService         = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local RunService           = game:GetService("RunService")
local SoundService         = game:GetService("SoundService")
local HttpService          = game:GetService("HttpService")
local Debris               = game:GetService("Debris")

local GmmUI = {}
GmmUI.__index   = GmmUI
GmmUI._VERSION  = "2.0.0"

-- ==== src\02_util.lua ====
--==[ Util ]==----------------------------------------------------------------

local function mk(className, props)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	return inst
end

local function tween(obj, ti, props)
	local t = TweenService:Create(obj, ti, props)
	t:Play()
	return t
end

local function clampColor(c)
	return Color3.new(
		math.clamp(c.R, 0, 1),
		math.clamp(c.G, 0, 1),
		math.clamp(c.B, 0, 1)
	)
end

local function lighten(c, amt)
	amt = amt or 0.15
	return clampColor(Color3.new(c.R + amt, c.G + amt, c.B + amt))
end

local function darken(c, amt)
	return lighten(c, -(amt or 0.15))
end

-- Tries multiple parents so the GUI survives across exploit + studio environments
local function safeParentGui()
	-- Exploit "gethui" -- a hidden CoreGui-like container that survives resets
	local ok, hui = pcall(function()
		return (gethui and gethui()) or nil
	end)
	if ok and hui then
		return hui
	end

	-- LocalPlayer:PlayerGui (normal games / studio)
	local lp = Players.LocalPlayer
	if lp then
		local pg = lp:FindFirstChildOfClass("PlayerGui")
		if pg then
			return pg
		end
	end

	-- CoreGui fallback (works in many executors)
	local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and cg then
		return cg
	end

	return game:GetService("StarterGui")
end

-- Fire-and-forget hook for protecting a GUI from CoreGui detection (executors)
local function protectGui(gui)
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
		if protect_gui then protect_gui(gui) end
	end)
end

local function isAlive(inst)
	return typeof(inst) == "Instance" and inst.Parent ~= nil
end

local function shallowCopy(t)
	local r = {}
	for k, v in pairs(t or {}) do r[k] = v end
	return r
end

-- ==== src\03_sounds.lua ====
--==[ Sounds ]==--------------------------------------------------------------

GmmUI.Sounds = {
	Hover   = "rbxassetid://10066931761", -- soft tick
	Select  = "rbxassetid://6895079853",  -- confirm
	Toggle  = "rbxassetid://6042053626",  -- switch
	Back    = "rbxassetid://6895079733",
	Error   = "rbxassetid://550209561",
	Notify  = "rbxassetid://6518811702",
	Success = "rbxassetid://6518811702",
}

GmmUI.SoundEnabled = true
GmmUI.SoundVolume  = 0.45

local function playSound(name)
	if not GmmUI.SoundEnabled then return end
	local id = GmmUI.Sounds[name]
	if not id then return end
	local snd = Instance.new("Sound")
	snd.SoundId = id
	snd.Volume  = GmmUI.SoundVolume
	snd.Parent  = SoundService
	snd:Play()
	Debris:AddItem(snd, 3)
end

-- ==== src\04_themes.lua ====
--==[ Themes ]==--------------------------------------------------------------
--
-- GTA V mod-menu inspired palettes. Selected row is bright with dark text
-- (just like Menyoo / NativeUI). Banner uses the Accent color.
--
-- Custom themes can be added at runtime:
--   GmmUI.Themes.MyTheme = { Accent = ..., Select = ..., ... }
--   ui:SetTheme("MyTheme")
--

local BASE_LAYOUT = {
	Title              = "GMM",
	Tab                = "HOME",
	Size               = UDim2.fromOffset(340, 470),
	Position           = UDim2.new(0.03, 0, 0.06, 0),
	DisplayOrder       = 2147483647,
	ScrollBarThickness = 4,
	ScrollSmoothness   = 4,
	HeaderHeight       = 78,
	SubHeight          = 26,
	FooterHeight       = 40,
	RowHeight          = 32,
	MaxVisibleRows     = 11, -- how many rows fit before scrolling
	BannerImage        = "", -- optional rbxassetid for banner background
	Draggable          = true,
	ShowHints          = true,
}

local function theme(t)
	local out = {}
	for k, v in pairs(BASE_LAYOUT) do out[k] = v end
	for k, v in pairs(t) do out[k] = v end
	return out
end

GmmUI.Themes = {
	-- Classic GTA V mod-menu (Menyoo) look
	Default = theme({
		Accent       = Color3.fromRGB(168, 26, 26),  -- header / banner
		Select       = Color3.fromRGB(245, 245, 245),-- selected row (white)
		Bg           = Color3.fromRGB(15, 15, 15),
		Text         = Color3.fromRGB(235, 235, 235),
		TitleText    = Color3.fromRGB(245, 245, 245),
		SelectedText = Color3.fromRGB(15, 15, 15),
		Scroller     = Color3.fromRGB(168, 26, 26),
		Disabled     = Color3.fromRGB(110, 110, 110),
	}),

	-- Classic NativeUI yellow on black
	Native = theme({
		Accent       = Color3.fromRGB(0, 0, 0),
		Select       = Color3.fromRGB(255, 220, 0),
		Bg           = Color3.fromRGB(0, 0, 0),
		Text         = Color3.fromRGB(245, 245, 245),
		TitleText    = Color3.fromRGB(255, 220, 0),
		SelectedText = Color3.fromRGB(0, 0, 0),
		Scroller     = Color3.fromRGB(255, 220, 0),
		Disabled     = Color3.fromRGB(120, 120, 120),
	}),

	Dark = theme({
		Accent       = Color3.fromRGB(40, 40, 40),
		Select       = Color3.fromRGB(240, 240, 240),
		Bg           = Color3.fromRGB(18, 18, 18),
		Text         = Color3.fromRGB(220, 220, 220),
		TitleText    = Color3.fromRGB(255, 255, 255),
		SelectedText = Color3.fromRGB(0, 0, 0),
		Scroller     = Color3.fromRGB(150, 150, 150),
		Disabled     = Color3.fromRGB(110, 110, 110),
	}),

	Light = theme({
		Accent       = Color3.fromRGB(60, 60, 60),
		Select       = Color3.fromRGB(40, 40, 40),
		Bg           = Color3.fromRGB(235, 235, 235),
		Text         = Color3.fromRGB(25, 25, 25),
		TitleText    = Color3.fromRGB(245, 245, 245),
		SelectedText = Color3.fromRGB(245, 245, 245),
		Scroller     = Color3.fromRGB(80, 80, 80),
		Disabled     = Color3.fromRGB(150, 150, 150),
	}),

	Cherry = theme({
		Accent       = Color3.fromRGB(200, 50, 80),
		Select       = Color3.fromRGB(255, 230, 235),
		Bg           = Color3.fromRGB(28, 18, 22),
		Text         = Color3.fromRGB(255, 210, 220),
		TitleText    = Color3.fromRGB(255, 230, 235),
		SelectedText = Color3.fromRGB(80, 10, 25),
		Scroller     = Color3.fromRGB(200, 50, 80),
		Disabled     = Color3.fromRGB(140, 100, 110),
	}),

	Ocean = theme({
		Accent       = Color3.fromRGB(20, 90, 170),
		Select       = Color3.fromRGB(220, 240, 255),
		Bg           = Color3.fromRGB(12, 22, 32),
		Text         = Color3.fromRGB(180, 220, 255),
		TitleText    = Color3.fromRGB(230, 245, 255),
		SelectedText = Color3.fromRGB(10, 30, 60),
		Scroller     = Color3.fromRGB(40, 130, 220),
		Disabled     = Color3.fromRGB(90, 120, 150),
	}),

	Synthwave = theme({
		Accent       = Color3.fromRGB(255, 50, 150),
		Select       = Color3.fromRGB(255, 240, 255),
		Bg           = Color3.fromRGB(20, 10, 35),
		Text         = Color3.fromRGB(220, 200, 255),
		TitleText    = Color3.fromRGB(255, 255, 255),
		SelectedText = Color3.fromRGB(40, 0, 60),
		Scroller     = Color3.fromRGB(255, 50, 150),
		Disabled     = Color3.fromRGB(120, 100, 150),
	}),

	Midnight = theme({
		Accent       = Color3.fromRGB(80, 90, 140),
		Select       = Color3.fromRGB(180, 200, 255),
		Bg           = Color3.fromRGB(8, 10, 18),
		Text         = Color3.fromRGB(200, 210, 240),
		TitleText    = Color3.fromRGB(230, 235, 255),
		SelectedText = Color3.fromRGB(10, 15, 30),
		Scroller     = Color3.fromRGB(100, 120, 180),
		Disabled     = Color3.fromRGB(90, 100, 130),
	}),
}

local DEFAULTS = GmmUI.Themes.Default

-- ==== src\05_items.lua ====
--==[ Item Wrapper ]==--------------------------------------------------------
--
-- Every menu item created (Button/Toggle/Slider/etc.) returns a wrapper that
-- exposes a small chainable API:
--
--   item:SetLabel("New name")
--   item:SetDesc("New description")
--   item:SetVisible(false)
--   item:SetDisabled(true)
--   item:Set(value)             -- works for Toggle/Slider/List/KeyBind/Input/Color
--   item:Get()                  -- read current value
--   item:Remove()               -- delete from menu
--   item.OnChange:Connect(fn)   -- BindableEvent-style
--

local Item = {}
Item.__index = Item

local function newSignal()
	local sig = Instance.new("BindableEvent")
	return sig
end

local function wrapItem(rawItem)
	local self = setmetatable({}, Item)
	self._raw         = rawItem
	self._onChange    = newSignal()
	rawItem._wrapper  = self
	rawItem.Visible   = (rawItem.Visible ~= false)
	rawItem.Disabled  = rawItem.Disabled or false
	self.OnChange     = self._onChange.Event
	return self
end

local function fireChange(rawItem, value)
	if rawItem._wrapper and rawItem._wrapper._onChange then
		pcall(function()
			rawItem._wrapper._onChange:Fire(value)
		end)
	end
end

function Item:_refresh()
	if self._raw._menu and self._raw._menu.UI and self._raw._menu.UI.Current == self._raw._menu then
		self._raw._menu.UI:RebuildCurrentRow(self._raw)
	end
end

function Item:SetLabel(text)
	self._raw.Label = tostring(text)
	self:_refresh()
	return self
end

function Item:SetDesc(text)
	self._raw.Desc = tostring(text or "")
	if self._raw._menu and self._raw._menu.UI then
		local ui = self._raw._menu.UI
		if ui:_getSelectedItem() == self._raw and ui.DescLabel then
			ui.DescLabel.Text = self._raw.Desc ~= "" and self._raw.Desc or "Select an option."
		end
	end
	return self
end

function Item:SetVisible(v)
	self._raw.Visible = (v ~= false)
	if self._raw._menu and self._raw._menu.UI then
		self._raw._menu.UI:Refresh()
	end
	return self
end

function Item:SetDisabled(v)
	self._raw.Disabled = (v == true)
	self:_refresh()
	return self
end

function Item:Set(value)
	if self._raw.Set then
		self._raw.Set(value)
	elseif self._raw.SetIndex and type(value) == "number" then
		self._raw.SetIndex(value)
	end
	self:_refresh()
	return self
end

function Item:Get()
	if self._raw.Get then return self._raw.Get() end
	if self._raw.GetIndex then return self._raw.GetIndex() end
	return nil
end

function Item:Remove()
	local menu = self._raw._menu
	if not menu then return end
	for i, it in ipairs(menu.Items) do
		if it == self._raw then
			table.remove(menu.Items, i)
			break
		end
	end
	if menu.UI and menu.UI.Current == menu then
		menu.UI:Refresh()
	end
end

-- ==== src\06_menu.lua ====
--==[ Menu ]==----------------------------------------------------------------

local Menu = {}
Menu.__index = Menu

function Menu.new(ui, name)
	local self = setmetatable({}, Menu)
	self.UI    = ui
	self.Name  = tostring(name or "MENU"):upper()
	self.Items = {}
	return self
end

function Menu:_add(item)
	item._menu = self
	table.insert(self.Items, item)
	return wrapItem(item)
end

----------------------------------------------------------------- Section
function Menu:Section(label)
	return self:_add({
		Type     = "Section",
		Label    = tostring(label or ""):upper(),
		Desc     = "",
		Selectable = false,
	})
end

function Menu:Label(label, desc)
	return self:_add({
		Type     = "Label",
		Label    = tostring(label),
		Desc     = tostring(desc or ""),
		Selectable = false,
	})
end

----------------------------------------------------------------- Button
function Menu:Button(label, desc, callback)
	local raw
	raw = {
		Type  = "Button",
		Label = tostring(label),
		Desc  = tostring(desc or ""),
		Activate = function(item)
			if item.Disabled then return end
			if type(callback) == "function" then
				task.spawn(callback)
			end
			fireChange(raw, true)
		end,
	}
	return self:_add(raw)
end

----------------------------------------------------------------- Toggle
function Menu:Toggle(label, desc, default, callback)
	local state = default == true
	local raw
	raw = {
		Type  = "Toggle",
		Label = tostring(label),
		Desc  = tostring(desc or ""),
		Get   = function() return state end,
		Set   = function(v)
			state = (v and true) or false
			if type(callback) == "function" then
				task.spawn(callback, state)
			end
			fireChange(raw, state)
		end,
		Left  = function(it) it.Set(not it.Get()) end,
		Right = function(it) it.Set(not it.Get()) end,
		Activate = function(it)
			if it.Disabled then return end
			it.Set(not it.Get())
		end,
		ValueText = function(it) return it.Get() and "ON" or "OFF" end,
	}
	return self:_add(raw)
end

----------------------------------------------------------------- Slider
function Menu:Slider(label, desc, min, max, step, default, callback)
	min  = tonumber(min)  or 0
	max  = tonumber(max)  or 100
	step = tonumber(step) or 1
	local value = math.clamp(tonumber(default) or min, min, max)

	local function set(v)
		v = math.clamp(tonumber(v) or min, min, max)
		local snapped = min + (math.floor(((v - min) / step) + 0.5) * step)
		value = math.clamp(snapped, min, max)
		if type(callback) == "function" then
			task.spawn(callback, value)
		end
	end
	local raw
	raw = {
		Type  = "Slider",
		Label = tostring(label),
		Desc  = tostring(desc or ""),
		Min = min, Max = max, Step = step,
		Get   = function() return value end,
		Set   = function(v)
			set(v)
			fireChange(raw, value)
		end,
		Left  = function(it) it.Set(it.Get() - step) end,
		Right = function(it) it.Set(it.Get() + step) end,
		Activate = function() end, -- handled by UI as enter-edit
		ValueText = function(it)
			-- Smart formatting: ints stay int, floats get one decimal
			local v = it.Get()
			if step >= 1 and v == math.floor(v) then
				return tostring(math.floor(v))
			end
			return string.format("%.2f", v):gsub("0+$",""):gsub("%.$",".0")
		end,
	}
	return self:_add(raw)
end

----------------------------------------------------------------- List
function Menu:List(label, desc, values, default, callback)
	values = (type(values) == "table") and values or {}
	if #values == 0 then values = {"N/A"} end
	local idx = math.clamp(tonumber(default) or 1, 1, #values)
	local function setIndex(i)
		idx = ((i - 1) % #values) + 1
		if type(callback) == "function" then
			task.spawn(callback, values[idx], idx)
		end
	end
	local raw
	raw = {
		Type    = "List",
		Label   = tostring(label),
		Desc    = tostring(desc or ""),
		Values  = values,
		GetIndex= function() return idx end,
		SetIndex= function(i)
			setIndex(i)
			fireChange(raw, values[idx])
		end,
		Get     = function() return values[idx] end,
		Set     = function(v)
			-- Accept either index or value
			if type(v) == "number" then
				setIndex(v)
			else
				for i, val in ipairs(values) do
					if val == v then setIndex(i) break end
				end
			end
			fireChange(raw, values[idx])
		end,
		Left  = function(it) it.SetIndex(it.GetIndex() - 1) end,
		Right = function(it) it.SetIndex(it.GetIndex() + 1) end,
		Activate = function(it)
			if it.Disabled then return end
			it.SetIndex(it.GetIndex() + 1)
		end,
		ValueText = function(it)
			return "< " .. tostring(values[it.GetIndex()]) .. " >"
		end,
	}
	return self:_add(raw)
end

----------------------------------------------------------------- KeyBind
function Menu:KeyBind(label, desc, defaultKey, callback)
	local key = defaultKey
	local raw
	raw = {
		Type  = "KeyBind",
		Label = tostring(label),
		Desc  = tostring(desc or ""),
		Get   = function() return key end,
		Set   = function(k)
			key = k
			if type(callback) == "function" then
				task.spawn(callback, key)
			end
			fireChange(raw, key)
		end,
		Activate = function(it)
			if it.Disabled then return end
			-- UI handles entering "bind capture" edit mode
			if it._menu and it._menu.UI then
				it._menu.UI:BeginBindCapture(it)
			end
		end,
		ValueText = function(it)
			local k = it.Get()
			if not k then return "[ NONE ]" end
			if typeof(k) == "EnumItem" then return "[ " .. k.Name .. " ]" end
			return "[ " .. tostring(k) .. " ]"
		end,
	}
	return self:_add(raw)
end

----------------------------------------------------------------- Input (TextBox)
function Menu:Input(label, desc, default, placeholder, callback)
	local value = tostring(default or "")
	local raw
	raw = {
		Type        = "Input",
		Label       = tostring(label),
		Desc        = tostring(desc or ""),
		Placeholder = tostring(placeholder or "..."),
		Get         = function() return value end,
		Set         = function(v)
			value = tostring(v or "")
			if type(callback) == "function" then
				task.spawn(callback, value)
			end
			fireChange(raw, value)
		end,
		Activate = function(it)
			if it.Disabled then return end
			if it._menu and it._menu.UI then
				it._menu.UI:BeginTextEdit(it)
			end
		end,
		ValueText = function(it)
			local v = it.Get()
			if v == "" then return "[ " .. raw.Placeholder .. " ]" end
			if #v > 14 then v = v:sub(1, 12) .. ".." end
			return "[ " .. v .. " ]"
		end,
	}
	return self:_add(raw)
end

----------------------------------------------------------------- Color Picker
function Menu:Color(label, desc, default, callback)
	local color = default or Color3.fromRGB(255, 255, 255)
	local raw
	raw = {
		Type  = "Color",
		Label = tostring(label),
		Desc  = tostring(desc or ""),
		Get   = function() return color end,
		Set   = function(c)
			if typeof(c) == "Color3" then color = c end
			if type(callback) == "function" then
				task.spawn(callback, color)
			end
			fireChange(raw, color)
		end,
		Activate = function(it)
			if it.Disabled then return end
			if it._menu and it._menu.UI then
				it._menu.UI:BeginColorEdit(it)
			end
		end,
		ValueText = function() return "" end, -- swatch drawn instead
	}
	return self:_add(raw)
end

----------------------------------------------------------------- Submenu
function Menu:Submenu(label, desc, submenu)
	assert(getmetatable(submenu) == Menu,
		"Submenu must be a Menu created by UI:NewMenu(...)")
	local raw
	raw = {
		Type     = "Submenu",
		Label    = tostring(label),
		Desc     = tostring(desc or ""),
		HasArrow = true,
		Activate = function(it)
			if it.Disabled then return end
			self.UI:PushMenu(submenu)
		end,
	}
	return self:_add(raw)
end

function Menu:Clear()
	self.Items = {}
	if self.UI and self.UI.Current == self then
		self.UI:Refresh()
	end
end

-- ==== src\07_ui_build.lua ====
--==[ UI Construction ]==-----------------------------------------------------

function GmmUI.new(opts)
	opts = opts or {}
	-- Pull defaults from chosen theme
	local themeName = opts.Theme or "Default"
	local theme = GmmUI.Themes[themeName] or GmmUI.Themes.Default
	for k, v in pairs(theme) do
		if opts[k] == nil then opts[k] = v end
	end

	local self = setmetatable({}, GmmUI)
	self.Opts          = opts
	self.Opened        = true
	self.MenuStack     = {}
	self.Current       = nil
	self.SelectedIndex = 0
	self._rowObjects   = {}
	self._edit         = nil
	self._holdDir      = nil
	self._holdToken    = 0
	self._connections  = {}
	self._allMenus     = {}
	self._theme        = themeName

	------------------------------------------------ Root ScreenGui
	local gui = mk("ScreenGui", {
		Name           = "GmmUI",
		ResetOnSpawn   = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder   = opts.DisplayOrder,
	})
	gui.Parent = safeParentGui()
	protectGui(gui)
	self.Gui = gui

	------------------------------------------------ Main Frame
	local main = mk("Frame", {
		Name = "Main",
		Parent = gui,
		Size = opts.Size,
		Position = opts.Position,
		BackgroundColor3 = opts.Bg,
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Active = true,
	})
	self.Main = main

	-- Subtle shadow under the menu (GTA V drop shadow vibe)
	mk("ImageLabel", {
		Parent = main,
		ZIndex = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 8),
		Size = UDim2.new(1, 32, 1, 32),
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
	})

	------------------------------------------------ Header / Banner
	local header = mk("Frame", {
		Name = "Header",
		Parent = main,
		Size = UDim2.new(1, 0, 0, opts.HeaderHeight),
		BackgroundColor3 = opts.Accent,
		BorderSizePixel = 0,
	})
	self.Header = header

	-- Optional banner background image (GTA V style)
	self.BannerImg = mk("ImageLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Image = opts.BannerImage or "",
		ScaleType = Enum.ScaleType.Crop,
		ImageTransparency = (opts.BannerImage and opts.BannerImage ~= "") and 0.25 or 1,
	})

	self.TitleLabel = mk("TextLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		Font = Enum.Font.GothamBlack,
		Text = tostring(opts.Title):upper(),
		TextColor3 = opts.TitleText,
		TextSize = 42,
		TextScaled = false,
		TextStrokeTransparency = 0.7,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	------------------------------------------------ Tab Bar
	local sub = mk("Frame", {
		Name = "Sub",
		Parent = main,
		Position = UDim2.fromOffset(0, opts.HeaderHeight),
		Size = UDim2.new(1, 0, 0, opts.SubHeight),
		BackgroundColor3 = lighten(opts.Bg, 0.04),
		BorderSizePixel = 0,
	})
	self.Sub = sub

	self.TabLabel = mk("TextLabel", {
		Parent = sub,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.65, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = tostring(opts.Tab):upper(),
		TextColor3 = opts.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	self.CounterLabel = mk("TextLabel", {
		Parent = sub,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.35, 0, 0, 0),
		Size = UDim2.new(0.65, -12, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "0 / 0",
		TextColor3 = opts.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- Accent line below tab bar
	mk("Frame", {
		Parent = sub,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = opts.Accent,
		BorderSizePixel = 0,
	})

	------------------------------------------------ Scroll list
	local listTop    = opts.HeaderHeight + opts.SubHeight
	local listBottom = opts.FooterHeight
	local scroll = mk("ScrollingFrame", {
		Name = "Scroll",
		Parent = main,
		Position = UDim2.fromOffset(0, listTop),
		Size = UDim2.new(1, 0, 1, -(listTop + listBottom)),
		BackgroundColor3 = opts.Bg,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ScrollBarThickness = opts.ScrollBarThickness,
		ScrollBarImageColor3 = opts.Scroller,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollingEnabled = true,
		ClipsDescendants = true,
	})
	self.Scroll = scroll

	mk("UIListLayout", {
		Parent = scroll,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
	})

	------------------------------------------------ Footer (description + hints)
	local footer = mk("Frame", {
		Name = "Footer",
		Parent = main,
		Position = UDim2.new(0, 0, 1, -opts.FooterHeight),
		Size = UDim2.new(1, 0, 0, opts.FooterHeight),
		BackgroundColor3 = lighten(opts.Bg, 0.03),
		BorderSizePixel = 0,
	})
	self.Footer = footer

	mk("Frame", {
		Parent = footer,
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = opts.Accent,
		BorderSizePixel = 0,
	})

	self.DescLabel = mk("TextLabel", {
		Parent = footer,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 4),
		Size = UDim2.new(1, -20, 1, -8),
		Font = Enum.Font.Gotham,
		Text = "Select an option.",
		TextColor3 = opts.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
	})

	------------------------------------------------ Drag support (header)
	if opts.Draggable then
		self:_makeDraggable(header)
		self:_makeDraggable(sub)
	end

	------------------------------------------------ Input bindings
	self:_bindInputs()

	return self
end

----------------------------------------------------------------- Drag
function GmmUI:_makeDraggable(handle)
	local dragging, dragInput, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		   or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = self.Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
		   or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local d = input.Position - dragStart
			self.Main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

----------------------------------------------------------------- NewMenu
function GmmUI:NewMenu(name)
	local m = Menu.new(self, name)
	self._allMenus = self._allMenus or {}
	table.insert(self._allMenus, m)
	return m
end

function GmmUI:SetTitle(text)
	self.TitleLabel.Text = tostring(text):upper()
end

function GmmUI:SetTab(text)
	self.TabLabel.Text = tostring(text):upper()
end

function GmmUI:SetBanner(imageAssetId)
	self.Opts.BannerImage = imageAssetId or ""
	self.BannerImg.Image = self.Opts.BannerImage
	self.BannerImg.ImageTransparency = (imageAssetId and imageAssetId ~= "") and 0.25 or 1
end

-- ==== src\08_ui_rows.lua ====
--==[ Row Rendering ]==-------------------------------------------------------

local function visibleItems(menu)
	local out = {}
	for _, it in ipairs(menu.Items) do
		if it.Visible ~= false then
			table.insert(out, it)
		end
	end
	return out
end

function GmmUI:_clearRows()
	for _, row in ipairs(self._rowObjects) do
		if row and row.Destroy then row:Destroy() end
	end
	self._rowObjects = {}
end

-- Build a single row Frame for an item; returns (row, setSelected, refresh)
function GmmUI:_makeRow(item, index)
	local opts = self.Opts
	local h    = opts.RowHeight

	-- Section/Label rows don't behave like buttons
	local isSelectable = item.Selectable ~= false
		and item.Type ~= "Section"
		and item.Type ~= "Label"

	local row = mk("TextButton", {
		Parent = self.Scroll,
		Size = UDim2.new(1, 0, 0, h),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = index,
	})

	-- Selection background (drawn behind text). Hidden by default.
	local selBg = mk("Frame", {
		Parent = row,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = opts.Select,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	-- Bottom divider line
	mk("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
	})

	------------------------ Section header style
	if item.Type == "Section" then
		row.Size = UDim2.new(1, 0, 0, math.floor(h * 0.85))
		selBg.Visible = false
		mk("Frame", {
			Parent = row,
			BackgroundColor3 = opts.Accent,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
		})
		mk("TextLabel", {
			Parent = row, ZIndex = 2,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = item.Label,
			TextColor3 = opts.TitleText,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		return row, function() end, function() end
	end

	-- Standard layout: [ left label ............... value/arrow ]
	local left = mk("TextLabel", {
		Parent = row, ZIndex = 2,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -150, 1, 0),
		Font = Enum.Font.Gotham,
		Text = item.Label,
		TextColor3 = opts.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	-- For toggles we draw a small checkbox in the right region
	local toggleBox, toggleTick
	if item.Type == "Toggle" then
		toggleBox = mk("Frame", {
			Parent = row, ZIndex = 2,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = opts.Bg,
			BorderSizePixel = 0,
		})
		mk("UIStroke", {
			Parent = toggleBox,
			Color = opts.Text,
			Thickness = 1,
			Transparency = 0.2,
		})
		toggleTick = mk("Frame", {
			Parent = toggleBox,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(10, 10),
			BackgroundColor3 = opts.Accent,
			BorderSizePixel = 0,
			Visible = false,
		})
	end

	-- Slider bar
	local sliderBar, sliderFill
	if item.Type == "Slider" then
		sliderBar = mk("Frame", {
			Parent = row, ZIndex = 2,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(80, 6),
			BackgroundColor3 = opts.Bg,
			BorderSizePixel = 0,
		})
		mk("UIStroke", { Parent = sliderBar, Color = opts.Text, Transparency = 0.5 })
		sliderFill = mk("Frame", {
			Parent = sliderBar,
			Size = UDim2.new(0.5, 0, 1, 0),
			BackgroundColor3 = opts.Accent,
			BorderSizePixel = 0,
		})
	end

	-- Color swatch
	local colorSwatch
	if item.Type == "Color" then
		colorSwatch = mk("Frame", {
			Parent = row, ZIndex = 2,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(28, 16),
			BackgroundColor3 = item.Get and item.Get() or Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		})
		mk("UIStroke", { Parent = colorSwatch, Color = Color3.new(0, 0, 0), Transparency = 0.3 })
	end

	-- Right value label (used by Slider numeric, List < val >, Toggle hidden, Keybind, Input)
	local right = mk("TextLabel", {
		Parent = row, ZIndex = 2,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.fromOffset(130, h),
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = opts.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- For sliders, value is shown to the LEFT of the bar
	if item.Type == "Slider" then
		right.AnchorPoint = Vector2.new(1, 0)
		right.Position = UDim2.new(1, -100, 0, 0)
		right.Size = UDim2.fromOffset(50, h)
	end

	-- Arrow for submenus
	local arrow = mk("TextLabel", {
		Parent = row, ZIndex = 2,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(20, h),
		Font = Enum.Font.GothamBold,
		Text = ">",
		TextColor3 = opts.Text,
		TextSize = 16,
		Visible = (item.HasArrow == true) or (item.Type == "Submenu"),
	})

	-- Disabled tint
	local function applyDisabled()
		local c = item.Disabled and opts.Disabled or opts.Text
		left.TextColor3 = c
		right.TextColor3 = c
		arrow.TextColor3 = c
	end

	local selected = false
	local function setSelected(on)
		selected = on
		if on then
			selBg.BackgroundTransparency = 1
			tween(selBg, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { BackgroundTransparency = 0 })
			left.TextColor3  = opts.SelectedText
			right.TextColor3 = opts.SelectedText
			arrow.TextColor3 = opts.SelectedText
			if toggleBox then
				toggleBox.BackgroundColor3 = opts.SelectedText
				for _, s in ipairs(toggleBox:GetChildren()) do
					if s:IsA("UIStroke") then s.Color = opts.SelectedText end
				end
			end
			if sliderBar then
				for _, s in ipairs(sliderBar:GetChildren()) do
					if s:IsA("UIStroke") then s.Color = opts.SelectedText end
				end
			end
		else
			selBg.BackgroundTransparency = 1
			applyDisabled()
			if toggleBox then
				toggleBox.BackgroundColor3 = opts.Bg
				for _, s in ipairs(toggleBox:GetChildren()) do
					if s:IsA("UIStroke") then s.Color = opts.Text end
				end
			end
			if sliderBar then
				for _, s in ipairs(sliderBar:GetChildren()) do
					if s:IsA("UIStroke") then s.Color = opts.Text end
				end
			end
		end
	end

	local function refreshValue()
		if item.Type == "Toggle" then
			toggleTick.Visible = item.Get and item.Get() == true or false
			right.Text = ""
		elseif item.Type == "Slider" then
			local v   = item.Get()
			local pct = (v - item.Min) / math.max(1, (item.Max - item.Min))
			sliderFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
			-- Highlight bar when editing
			if self._edit and self._edit.Item == item then
				sliderFill.BackgroundColor3 = opts.Select
			else
				sliderFill.BackgroundColor3 = selected and opts.SelectedText or opts.Accent
			end
			right.Text = item.ValueText(item)
		elseif item.Type == "List" then
			right.Text = item.ValueText(item)
		elseif item.Type == "KeyBind" or item.Type == "Input" then
			if self._edit and self._edit.Item == item then
				right.Text = "[ ... ]"
			else
				right.Text = item.ValueText(item)
			end
		elseif item.Type == "Color" then
			colorSwatch.BackgroundColor3 = item.Get()
			right.Text = ""
		elseif item.ValueText then
			right.Text = item.ValueText(item)
		else
			right.Text = ""
		end
	end

	applyDisabled()
	refreshValue()

	------------------------ Mouse interactions
	if isSelectable then
		row.MouseEnter:Connect(function()
			if self._edit then return end
			self:SetSelected(self:_visibleIndexOf(item))
		end)
		row.MouseButton1Click:Connect(function()
			if self._edit then return end
			self:SetSelected(self:_visibleIndexOf(item))
			self:Select()
		end)
	end

	return row, setSelected, refreshValue
end

-- ==== src\09_ui_render.lua ====
--==[ Render / Navigation ]==-------------------------------------------------

function GmmUI:_visibleIndexOf(item)
	if not self.Current then return 0 end
	local v = visibleItems(self.Current)
	for i, it in ipairs(v) do
		if it == item then return i end
	end
	return 0
end

function GmmUI:_updateCounter()
	if not self.Current then return end
	local v = visibleItems(self.Current)
	local total = #v
	local sel   = total > 0 and math.clamp(self.SelectedIndex, 1, total) or 0
	self.CounterLabel.Text = string.format("%d / %d", sel, total)
end

function GmmUI:_saveMenuState()
	local menu = self.Current
	if not menu then return end
	menu._savedIndex = self.SelectedIndex or 0
	if self.Scroll then
		menu._savedCanvasY = self._scrollTargetY or self.Scroll.CanvasPosition.Y
	end
end

function GmmUI:RebuildCurrentRow(item)
	-- Find row for this item and refresh just it
	if not self.Current then return end
	for _, raw in ipairs(self.Current.Items) do
		if raw == item and raw.__refreshValue then
			raw.__refreshValue()
			return
		end
	end
end

function GmmUI:_renderMenu(menu)
	self:_clearRows()
	self.Current = menu
	self:SetTab(menu.Name)

	local vis = visibleItems(menu)
	for i, item in ipairs(vis) do
		local row, setSel, refresh = self:_makeRow(item, i)
		item.__row = row
		item.__setSelected = setSel
		item.__refreshValue = refresh
		table.insert(self._rowObjects, row)
	end

	if #vis > 0 then
		local savedY = tonumber(menu._savedCanvasY) or 0
		if self._scrollTween then
			pcall(function() self._scrollTween:Cancel() end)
			self._scrollTween = nil
		end
		self.Scroll.CanvasPosition = Vector2.new(0, savedY)
		self._scrollTargetY = savedY

		local saved = tonumber(menu._savedIndex)
		if not (saved and saved >= 1 and saved <= #vis) then saved = 1 end
		-- Skip non-selectable items at start
		while saved <= #vis and (vis[saved].Selectable == false
			or vis[saved].Type == "Section"
			or vis[saved].Type == "Label") do
			saved = saved + 1
		end
		if saved > #vis then saved = 1 end
		self:SetSelected(saved, true)
	else
		self.SelectedIndex = 0
		self.DescLabel.Text = "No options."
		self:_updateCounter()
	end
end

-- Force re-render of the current menu
function GmmUI:Refresh()
	if self.Current then
		self:_saveMenuState()
		self:_renderMenu(self.Current)
	end
end

function GmmUI:PushMenu(menu)
	self:_saveMenuState()
	table.insert(self.MenuStack, menu)
	self:_renderMenu(menu)
	playSound("Select")
end

function GmmUI:Back()
	if self._edit then
		self:CancelEdit()
		return
	end
	if #self.MenuStack <= 1 then
		self:Close()
		return
	end
	self:_saveMenuState()
	table.remove(self.MenuStack)
	local top = self.MenuStack[#self.MenuStack]
	self:_renderMenu(top)
	playSound("Back")
end

----------------------------------------------------------------- Scroll
function GmmUI:_scrollTo(targetY)
	local s = self.Scroll
	if not s then return end
	targetY = tonumber(targetY) or 0
	self._scrollTargetY = targetY
	local absCanvas = s.AbsoluteCanvasSize.Y
	local maxY = absCanvas > 0 and math.max(0, absCanvas - s.AbsoluteSize.Y) or math.huge
	targetY = math.clamp(targetY, 0, maxY)

	if self._scrollTween then
		pcall(function() self._scrollTween:Cancel() end)
		self._scrollTween = nil
	end
	local smooth = tonumber(self.Opts.ScrollSmoothness) or 0
	if smooth <= 0 then
		s.CanvasPosition = Vector2.new(0, targetY)
		return
	end
	local dur = math.clamp(0.04 * smooth, 0.05, 0.4)
	self._scrollTween = tween(s,
		TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CanvasPosition = Vector2.new(0, targetY) }
	)
end

----------------------------------------------------------------- Selection
function GmmUI:SetSelected(idx, silent)
	if not self.Current then return end
	local vis = visibleItems(self.Current)
	if #vis == 0 then return end
	idx = ((idx - 1) % #vis) + 1

	-- Skip non-selectable (Section/Label) by walking forward
	local guard = 0
	while (vis[idx].Selectable == false
		or vis[idx].Type == "Section"
		or vis[idx].Type == "Label") and guard < #vis do
		idx = ((idx) % #vis) + 1
		guard = guard + 1
	end

	if not silent and self.SelectedIndex ~= idx then
		playSound("Hover")
	end
	self.SelectedIndex = idx

	for i, it in ipairs(vis) do
		if it.__setSelected then
			it.__setSelected(i == idx)
		end
	end

	local it = vis[idx]
	self.DescLabel.Text = (it and it.Desc and it.Desc ~= "") and it.Desc or "Select an option."
	self:_updateCounter()

	-- Scroll-into-view
	local row = it and it.__row
	if row then
		local y = row.AbsolutePosition.Y
		local h = row.AbsoluteSize.Y
		local topY = self.Scroll.AbsolutePosition.Y
		local botY = topY + self.Scroll.AbsoluteSize.Y
		if y < topY then
			self:_scrollTo(self.Scroll.CanvasPosition.Y - (topY - y))
		elseif (y + h) > botY then
			self:_scrollTo(self.Scroll.CanvasPosition.Y + ((y + h) - botY))
		end
	end
	self:_saveMenuState()
end

function GmmUI:_getSelectedItem()
	if not self.Current then return nil end
	return visibleItems(self.Current)[self.SelectedIndex]
end

----------------------------------------------------------------- Hold-to-repeat (sliders)
function GmmUI:_stopHold(dir)
	if dir == nil or self._holdDir == dir then
		self._holdDir = nil
		self._holdToken = (self._holdToken or 0) + 1
	end
end

function GmmUI:_startHold(dir)
	local it = self._edit and self._edit.Item
	if not (self.Opened and it and it == self:_getSelectedItem() and it.Type == "Slider") then
		return
	end
	self._holdDir = dir
	self._holdToken = (self._holdToken or 0) + 1
	local token = self._holdToken
	task.spawn(function()
		task.wait(0.3)
		while self._holdToken == token and self._holdDir == dir do
			if not self.Opened then break end
			if not (self._edit and self._edit.Item == it) then break end
			if dir < 0 then self:DoLeft() else self:DoRight() end
			task.wait(0.05)
		end
	end)
end

----------------------------------------------------------------- Edit modes
function GmmUI:BeginEdit()
	if self._edit then return end
	local it = self:_getSelectedItem()
	if not it or it.Type ~= "Slider" then return end
	self._edit = { Item = it, Original = it.Get and it.Get() }
	if it.__refreshValue then it.__refreshValue() end
end

function GmmUI:ConfirmEdit()
	if not self._edit then return end
	local it = self._edit.Item
	self._edit = nil
	self:_stopHold()
	if it and it.__refreshValue then it.__refreshValue() end
end

function GmmUI:CancelEdit()
	if not self._edit then return end
	local it       = self._edit.Item
	local original = self._edit.Original
	self._edit = nil
	self:_stopHold()
	if it and original ~= nil and it.Set then it.Set(original) end
	if it and it.__refreshValue then it.__refreshValue() end
end

function GmmUI:BeginBindCapture(item)
	self._edit = { Item = item, Kind = "KeyBind" }
	if item.__refreshValue then item.__refreshValue() end
	self.DescLabel.Text = "Press a key to bind, or Backspace to cancel."
end

function GmmUI:BeginTextEdit(item)
	-- Spawn a temporary TextBox over the row
	local row = item.__row
	if not row then return end
	local opts = self.Opts

	local tb = mk("TextBox", {
		Parent = row, ZIndex = 5,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(160, 22),
		BackgroundColor3 = opts.Bg,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextColor3 = opts.Text,
		TextSize = 14,
		ClearTextOnFocus = false,
		PlaceholderText = item.Placeholder or "",
		Text = item.Get() or "",
	})
	mk("UIStroke", { Parent = tb, Color = opts.Accent, Thickness = 1 })

	self._edit = { Item = item, Kind = "Input", TextBox = tb }
	if item.__refreshValue then item.__refreshValue() end
	task.defer(function() tb:CaptureFocus() end)

	tb.FocusLost:Connect(function(enter)
		if enter then
			item.Set(tb.Text)
			playSound("Toggle")
		end
		tb:Destroy()
		self._edit = nil
		if item.__refreshValue then item.__refreshValue() end
	end)
end

function GmmUI:BeginColorEdit(item)
	-- Simple HSV picker: cycle RGB component edit with Left/Right per channel
	-- For simplicity we just open a small Color3 sliders overlay
	local row = item.__row
	if not row then return end
	local opts = self.Opts

	local frame = mk("Frame", {
		Parent = self.Main, ZIndex = 10,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(260, 140),
		BackgroundColor3 = opts.Bg,
		BorderSizePixel = 0,
	})
	mk("UIStroke", { Parent = frame, Color = opts.Accent, Thickness = 2 })
	mk("TextLabel", {
		Parent = frame, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Font = Enum.Font.GothamBold,
		Text = "  " .. item.Label, TextColor3 = opts.TitleText,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
	})

	local current = item.Get()
	local r, g, b = math.floor(current.R*255), math.floor(current.G*255), math.floor(current.B*255)

	local function rowSlider(yOff, label, getter, setter)
		local lbl = mk("TextLabel", {
			Parent = frame, BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, yOff),
			Size = UDim2.fromOffset(20, 20),
			Font = Enum.Font.GothamBold, Text = label,
			TextColor3 = opts.Text, TextSize = 13,
		})
		local bar = mk("Frame", {
			Parent = frame,
			Position = UDim2.fromOffset(35, yOff + 6),
			Size = UDim2.new(1, -90, 0, 8),
			BackgroundColor3 = darken(opts.Bg, 0.1),
			BorderSizePixel = 0,
		})
		local fill = mk("Frame", {
			Parent = bar,
			Size = UDim2.new(getter()/255, 0, 1, 0),
			BackgroundColor3 = ({ R = Color3.fromRGB(220,40,40), G = Color3.fromRGB(40,200,80), B = Color3.fromRGB(60,120,255)})[label],
			BorderSizePixel = 0,
		})
		local num = mk("TextLabel", {
			Parent = frame, BackgroundTransparency = 1,
			Position = UDim2.new(1, -50, 0, yOff),
			Size = UDim2.fromOffset(40, 20),
			Font = Enum.Font.GothamBold, Text = tostring(getter()),
			TextColor3 = opts.Text, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
		})

		local function update(v)
			v = math.clamp(math.floor(v + 0.5), 0, 255)
			setter(v)
			fill.Size = UDim2.new(v/255, 0, 1, 0)
			num.Text = tostring(v)
			item.Set(Color3.fromRGB(r, g, b))
		end

		local dragging = false
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			   or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
				update(rel * 255)
			end
		end)
		bar.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			   or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			   or input.UserInputType == Enum.UserInputType.Touch) then
				local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
				update(rel * 255)
			end
		end)
	end

	rowSlider(28,  "R", function() return r end, function(v) r = v end)
	rowSlider(58,  "G", function() return g end, function(v) g = v end)
	rowSlider(88,  "B", function() return b end, function(v) b = v end)

	local close = mk("TextButton", {
		Parent = frame, AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -6, 1, -6),
		Size = UDim2.fromOffset(60, 22),
		BackgroundColor3 = opts.Accent, BorderSizePixel = 0,
		Font = Enum.Font.GothamBold, Text = "DONE",
		TextColor3 = opts.TitleText, TextSize = 12,
	})
	self._edit = { Item = item, Kind = "Color", Frame = frame }
	close.MouseButton1Click:Connect(function()
		frame:Destroy()
		self._edit = nil
		playSound("Toggle")
	end)
end

----------------------------------------------------------------- Activate / Adjust
function GmmUI:DoLeft()
	local it = self:_getSelectedItem()
	if not it or it.Disabled then return end
	if it.Type == "Slider" and not (self._edit and self._edit.Item == it) then return end
	if it.Left then
		it.Left(it)
		if it.__refreshValue then it.__refreshValue() end
	end
end

function GmmUI:DoRight()
	local it = self:_getSelectedItem()
	if not it or it.Disabled then return end
	if it.Type == "Slider" and not (self._edit and self._edit.Item == it) then return end
	if it.Right then
		it.Right(it)
		if it.__refreshValue then it.__refreshValue() end
	end
end

function GmmUI:Select()
	local it = self:_getSelectedItem()
	if not it or it.Disabled then return end

	if it.Type == "Slider" then
		if self._edit and self._edit.Item == it then
			playSound("Toggle"); self:ConfirmEdit()
		else
			playSound("Select"); self:BeginEdit()
		end
		return
	end

	if it.Activate then
		it.Activate(it)
		if it.Type ~= "Submenu" then
			playSound("Select")
		end
		if it.__refreshValue then it.__refreshValue() end
	end
end

-- ==== src\10_ui_input.lua ====
--==[ Input Bindings ]==------------------------------------------------------

function GmmUI:_bindInputs()
	self._casActions = {
		"GmmUI_Toggle", "GmmUI_Up", "GmmUI_Down", "GmmUI_Left", "GmmUI_Right",
		"GmmUI_PageUp", "GmmUI_PageDown", "GmmUI_Back", "GmmUI_Select",
	}
	for _, name in ipairs(self._casActions) do
		pcall(function() ContextActionService:UnbindAction(name) end)
	end

	local pri = (self.Opts.InputPriority and tonumber(self.Opts.InputPriority))
		or (Enum.ContextActionPriority.High.Value + 5000)

	local function bind(name, fn, ...)
		ContextActionService:BindActionAtPriority(name, fn, false, pri, ...)
	end

	local Pass = Enum.ContextActionResult.Pass
	local Sink = Enum.ContextActionResult.Sink
	local Begin = Enum.UserInputState.Begin
	local End_  = Enum.UserInputState.End

	bind("GmmUI_Toggle", function(_, state)
		if state ~= Begin then return Pass end
		self:Toggle()
		return Sink
	end, Enum.KeyCode.F4, Enum.KeyCode.Insert)

	bind("GmmUI_Up", function(_, state)
		if state ~= Begin then return Pass end
		if not self.Opened then return Pass end
		if self._edit then return Sink end
		self:SetSelected(self.SelectedIndex - 1)
		return Sink
	end, Enum.KeyCode.Up, Enum.KeyCode.KeypadEight, Enum.KeyCode.I)

	bind("GmmUI_Down", function(_, state)
		if state ~= Begin then return Pass end
		if not self.Opened then return Pass end
		if self._edit then return Sink end
		self:SetSelected(self.SelectedIndex + 1)
		return Sink
	end, Enum.KeyCode.Down, Enum.KeyCode.KeypadTwo, Enum.KeyCode.K)

	bind("GmmUI_Left", function(_, state)
		if not self.Opened then return Pass end
		if state == Begin then
			self:DoLeft(); self:_startHold(-1)
			return Sink
		elseif state == End_ then
			self:_stopHold(-1)
			return Sink
		end
		return Pass
	end, Enum.KeyCode.Left, Enum.KeyCode.KeypadFour, Enum.KeyCode.J)

	bind("GmmUI_Right", function(_, state)
		if not self.Opened then return Pass end
		if state == Begin then
			self:DoRight(); self:_startHold(1)
			return Sink
		elseif state == End_ then
			self:_stopHold(1)
			return Sink
		end
		return Pass
	end, Enum.KeyCode.Right, Enum.KeyCode.KeypadSix, Enum.KeyCode.L)

	bind("GmmUI_PageUp", function(_, state)
		if state ~= Begin then return Pass end
		if not self.Opened or self._edit then return Pass end
		self:SetSelected(self.SelectedIndex - 10)
		return Sink
	end, Enum.KeyCode.PageUp, Enum.KeyCode.KeypadNine)

	bind("GmmUI_PageDown", function(_, state)
		if state ~= Begin then return Pass end
		if not self.Opened or self._edit then return Pass end
		self:SetSelected(self.SelectedIndex + 10)
		return Sink
	end, Enum.KeyCode.PageDown, Enum.KeyCode.KeypadThree)

	bind("GmmUI_Back", function(_, state)
		if state ~= Begin then return Pass end
		if not self.Opened then return Pass end
		if self._edit then
			self:CancelEdit()
		else
			self:Back()
		end
		return Sink
	end, Enum.KeyCode.Backspace, Enum.KeyCode.KeypadZero, Enum.KeyCode.U)

	bind("GmmUI_Select", function(_, state)
		if state ~= Begin then return Pass end
		if not self.Opened then return Pass end
		if self._edit and self._edit.Kind == "Input" then return Pass end
		self:Select()
		return Sink
	end, Enum.KeyCode.Return, Enum.KeyCode.KeypadFive, Enum.KeyCode.O)

	------------------------ Keybind capture (any key) via UserInputService
	local keybindConn = UserInputService.InputBegan:Connect(function(input, gp)
		-- Capture key for KeyBind items
		if self._edit and self._edit.Kind == "KeyBind"
		   and input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Backspace
			   or input.KeyCode == Enum.KeyCode.Escape then
				-- Cancel
				local it = self._edit.Item
				self._edit = nil
				if it.__refreshValue then it.__refreshValue() end
				self.DescLabel.Text = "Cancelled."
				return
			end
			local it = self._edit.Item
			self._edit = nil
			it.Set(input.KeyCode)
			if it.__refreshValue then it.__refreshValue() end
			playSound("Toggle")
		end

		-- Fire any user keybinds that were bound through UI:BindKey() (if used)
		if self._userBindings and not gp then
			local handler = self._userBindings[input.KeyCode]
			if handler then task.spawn(handler) end
		end
	end)
	table.insert(self._connections, keybindConn)
end

----------------------------------------------------------------- Public key bind helper
function GmmUI:BindKey(keyCode, callback)
	self._userBindings = self._userBindings or {}
	self._userBindings[keyCode] = callback
end

function GmmUI:UnbindKey(keyCode)
	if self._userBindings then self._userBindings[keyCode] = nil end
end

-- ==== src\11_ui_state.lua ====
--==[ Open/Close, Theme, Notify, Config, Destroy ]==--------------------------

function GmmUI:Open()
	if self.Opened then return end
	self.Opened = true
	self.Main.Visible = true
	self.Main.BackgroundTransparency = 0.35
	tween(self.Main, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 0.10,
	})
end

function GmmUI:Close()
	if not self.Opened then return end
	if self._edit then
		if self._edit.Kind == "KeyBind" then
			self._edit = nil
		else
			self:ConfirmEdit()
		end
	end
	self:_stopHold()
	self.Opened = false
	local t = tween(self.Main, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 0.35,
	})
	t.Completed:Connect(function()
		if not self.Opened then self.Main.Visible = false end
	end)
end

function GmmUI:Toggle()
	if self.Opened then self:Close() else self:Open() end
end

----------------------------------------------------------------- Theme switching
function GmmUI:SetTheme(themeName)
	local theme = GmmUI.Themes[themeName]
	if not theme then warn("[GmmUI] Unknown theme: " .. tostring(themeName)) return end
	self._theme = themeName
	-- Only copy color/visual fields, not Title/Tab/Size/etc.
	local colorKeys = {
		"Accent","Select","Bg","Text","TitleText","SelectedText","Scroller","Disabled",
	}
	for _, k in ipairs(colorKeys) do
		if theme[k] then self.Opts[k] = theme[k] end
	end

	if self.Main   then self.Main.BackgroundColor3   = self.Opts.Bg end
	if self.Header then self.Header.BackgroundColor3 = self.Opts.Accent end
	if self.Sub then
		self.Sub.BackgroundColor3 = lighten(self.Opts.Bg, 0.04)
		for _, c in ipairs(self.Sub:GetChildren()) do
			if c:IsA("Frame") then c.BackgroundColor3 = self.Opts.Accent end
		end
	end
	if self.Footer then
		self.Footer.BackgroundColor3 = lighten(self.Opts.Bg, 0.03)
		for _, c in ipairs(self.Footer:GetChildren()) do
			if c:IsA("Frame") then c.BackgroundColor3 = self.Opts.Accent end
		end
	end
	if self.Scroll then
		self.Scroll.BackgroundColor3 = self.Opts.Bg
		self.Scroll.ScrollBarImageColor3 = self.Opts.Scroller
	end
	if self.TitleLabel   then self.TitleLabel.TextColor3   = self.Opts.TitleText end
	if self.TabLabel     then self.TabLabel.TextColor3     = self.Opts.Text end
	if self.CounterLabel then self.CounterLabel.TextColor3 = self.Opts.Text end
	if self.DescLabel    then self.DescLabel.TextColor3    = self.Opts.Text end

	-- Re-render rows so they pick up new colors
	if self.Current then self:Refresh() end
end

----------------------------------------------------------------- Notifications
GmmUI.NotifyColors = {
	Info    = Color3.fromRGB(70, 140, 220),
	Success = Color3.fromRGB(60, 180, 90),
	Warning = Color3.fromRGB(230, 170, 40),
	Error   = Color3.fromRGB(220, 60, 60),
}

local function getNotifContainer()
	local parent = safeParentGui()
	local sg = parent:FindFirstChild("GmmNotifications")
	if not sg then
		sg = mk("ScreenGui", {
			Name = "GmmNotifications",
			ResetOnSpawn = false,
			DisplayOrder = 2147483647,
			IgnoreGuiInset = true,
		})
		sg.Parent = parent
		protectGui(sg)

		local list = mk("Frame", {
			Parent = sg,
			Name = "List",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -10, 1, -10),
			Size = UDim2.fromOffset(280, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
		})
		mk("UIListLayout", {
			Parent = list,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 6),
		})
	end
	return sg:FindFirstChild("List")
end

function GmmUI:Notify(opts)
	opts = opts or {}
	local title    = opts.Title    or "Notification"
	local content  = opts.Content  or ""
	local duration = opts.Duration or 3
	local kind     = opts.Type     or "Info"
	local accent   = opts.Accent   or GmmUI.NotifyColors[kind] or GmmUI.NotifyColors.Info

	if kind == "Error" then playSound("Error") else playSound("Notify") end

	local list = getNotifContainer()
	local card = mk("Frame", {
		Parent = list,
		BackgroundColor3 = self.Opts.Bg or Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	mk("Frame", {
		Parent = card,
		Name = "Accent",
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
	})
	mk("UIPadding", {
		Parent = card,
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 10),
	})

	mk("TextLabel", {
		Parent = card,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = self.Opts.TitleText or Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	mk("TextLabel", {
		Parent = card,
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = content,
		TextColor3 = self.Opts.Text or Color3.fromRGB(200, 200, 200),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	})

	-- Fade in
	card.BackgroundTransparency = 1
	for _, c in ipairs(card:GetDescendants()) do
		if c:IsA("TextLabel") then c.TextTransparency = 1 end
	end
	tween(card, TweenInfo.new(0.25), { BackgroundTransparency = 0.05 })
	for _, c in ipairs(card:GetDescendants()) do
		if c:IsA("TextLabel") then
			tween(c, TweenInfo.new(0.25), { TextTransparency = 0 })
		end
	end

	task.delay(duration, function()
		if not card.Parent then return end
		tween(card, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
		for _, c in ipairs(card:GetDescendants()) do
			if c:IsA("TextLabel") then
				tween(c, TweenInfo.new(0.25), { TextTransparency = 1 })
			end
		end
		task.wait(0.28)
		card:Destroy()
	end)
end

----------------------------------------------------------------- Config persistence
local function canWriteFiles()
	return type(writefile) == "function" and type(readfile) == "function"
end

function GmmUI:SaveConfig(name, menus)
	if not canWriteFiles() then
		warn("[GmmUI] SaveConfig requires writefile (executor only)")
		return false
	end
	menus = menus or self._allMenus or { self.Current }
	local data = {}
	for _, m in ipairs(menus) do
		for _, it in ipairs(m.Items) do
			if it.Get then
				local key = (m.Name or "M") .. ":" .. (it.Label or "?")
				local val = it.Get()
				if typeof(val) == "Color3" then
					data[key] = { __t = "Color3", v = { val.R, val.G, val.B } }
				elseif typeof(val) == "EnumItem" then
					data[key] = { __t = "Enum", v = tostring(val) }
				else
					data[key] = val
				end
			end
		end
	end
	local ok, err = pcall(function()
		writefile(name, HttpService:JSONEncode(data))
	end)
	if not ok then warn("[GmmUI] SaveConfig failed: " .. tostring(err)) end
	return ok
end

function GmmUI:LoadConfig(name, menus)
	if not canWriteFiles() then return false end
	menus = menus or self._allMenus or { self.Current }
	local ok, raw = pcall(function() return readfile(name) end)
	if not ok or not raw then return false end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then return false end
	for _, m in ipairs(menus) do
		for _, it in ipairs(m.Items) do
			if it.Set then
				local key = (m.Name or "M") .. ":" .. (it.Label or "?")
				local val = data[key]
				if val ~= nil then
					if type(val) == "table" and val.__t == "Color3" and val.v then
						it.Set(Color3.new(val.v[1], val.v[2], val.v[3]))
					elseif type(val) == "table" and val.__t == "Enum" then
						local enumPart, valuePart = val.v:match("^Enum%.(%w+)%.(%w+)$")
						if enumPart and valuePart then
							local en = Enum[enumPart]
							if en then
								pcall(function() it.Set(en[valuePart]) end)
							end
						end
					else
						it.Set(val)
					end
				end
			end
		end
	end
	if self.Current then self:Refresh() end
	return true
end

----------------------------------------------------------------- Destroy
function GmmUI:Destroy()
	for _, c in ipairs(self._connections) do
		pcall(function() c:Disconnect() end)
	end
	self._connections = {}
	if self._casActions then
		for _, n in ipairs(self._casActions) do
			pcall(function() ContextActionService:UnbindAction(n) end)
		end
		self._casActions = nil
	end
	if self.Gui then self.Gui:Destroy() end
end

-- ==== src\12_prompt.lua ====
--==[ Key Prompt ]==----------------------------------------------------------
--
--   GmmUI.PromptKey({
--       Title = "GMM Hub",
--       Key   = "abc123",            -- string, or table {"k1","k2"}
--       Url   = "https://...",       -- optional: fetched plain-text list of keys
--       Save  = true,                -- if true and writefile available, remember
--   }, function(ok, attemptedKey)
--       -- ok == true if matched
--   end)
--

function GmmUI.PromptKey(opts, callback)
	opts = opts or {}
	local title  = opts.Title or "Key System"
	local keys   = {}
	if type(opts.Key) == "table" then
		for _, k in ipairs(opts.Key) do keys[tostring(k)] = true end
	elseif opts.Key then
		keys[tostring(opts.Key)] = true
	end
	if opts.Url then
		pcall(function()
			local body = game:HttpGet(opts.Url)
			for line in tostring(body):gmatch("[^\r\n]+") do
				local k = line:match("^%s*(.-)%s*$")
				if k ~= "" then keys[k] = true end
			end
		end)
	end

	-- Try cached key
	if opts.Save and type(readfile) == "function" then
		pcall(function()
			local cached = readfile("gmm_key.txt")
			if cached and keys[cached] then
				if callback then task.spawn(callback, true, cached) end
				return
			end
		end)
	end

	local sg = mk("ScreenGui", {
		Name = "GmmKeySystem", ResetOnSpawn = false,
		DisplayOrder = 2147483647, IgnoreGuiInset = true,
	})
	sg.Parent = safeParentGui()
	protectGui(sg)

	local bg = mk("Frame", {
		Parent = sg,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(360, 200),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,
	})
	mk("UIStroke", { Parent = bg, Color = Color3.fromRGB(168, 26, 26), Thickness = 2 })

	mk("Frame", {
		Parent = bg, Name = "Header",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Color3.fromRGB(168, 26, 26),
		BorderSizePixel = 0,
	})
	mk("TextLabel", {
		Parent = bg.Header,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -36, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local closeBtn = mk("TextButton", {
		Parent = bg.Header, AutoButtonColor = false,
		Position = UDim2.new(1, -32, 0, 0),
		Size = UDim2.fromOffset(32, 36),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, Text = "X",
		TextColor3 = Color3.new(1, 1, 1), TextSize = 16,
	})

	local info = mk("TextLabel", {
		Parent = bg,
		Position = UDim2.fromOffset(20, 46),
		Size = UDim2.new(1, -40, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = opts.Subtitle or "Enter your key to continue.",
		TextColor3 = Color3.fromRGB(200, 200, 200), TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local box = mk("TextBox", {
		Parent = bg,
		Position = UDim2.fromOffset(20, 76),
		Size = UDim2.new(1, -40, 0, 38),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		PlaceholderText = "Enter key here...",
		PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
		Text = "",
		TextColor3 = Color3.new(1, 1, 1), TextSize = 14,
		ClearTextOnFocus = false,
	})
	mk("UIStroke", { Parent = box, Color = Color3.fromRGB(80, 80, 80), Thickness = 1 })

	local submit = mk("TextButton", {
		Parent = bg, AutoButtonColor = false,
		Position = UDim2.fromOffset(20, 130),
		Size = UDim2.new(1, -120, 0, 38),
		BackgroundColor3 = Color3.fromRGB(168, 26, 26),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold, Text = "SUBMIT",
		TextColor3 = Color3.new(1, 1, 1), TextSize = 14,
	})
	local cancel = mk("TextButton", {
		Parent = bg, AutoButtonColor = false,
		Position = UDim2.new(1, -90, 0, 130),
		Size = UDim2.fromOffset(70, 38),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold, Text = "CANCEL",
		TextColor3 = Color3.new(1, 1, 1), TextSize = 14,
	})

	local function finish(ok)
		sg:Destroy()
		if callback then task.spawn(callback, ok, box.Text) end
	end

	local function attempt()
		local k = box.Text
		if keys[k] then
			playSound("Success")
			if opts.Save and type(writefile) == "function" then
				pcall(function() writefile("gmm_key.txt", k) end)
			end
			finish(true)
		else
			playSound("Error")
			box.Text = ""
			box.PlaceholderText = "Incorrect Key!"
			tween(bg, TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 4, true),
				{ Position = bg.Position + UDim2.fromOffset(6, 0) })
		end
	end

	submit.MouseButton1Click:Connect(attempt)
	box.FocusLost:Connect(function(enter) if enter then attempt() end end)
	cancel.MouseButton1Click:Connect(function() finish(false) end)
	closeBtn.MouseButton1Click:Connect(function() finish(false) end)
end

-- ==== src\99_footer.lua ====
--==[ Return ]==--------------------------------------------------------------

return GmmUI

