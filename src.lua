local Players = game:GetService("Players");
local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local ContextActionService = game:GetService("ContextActionService");
local GmmUI = {};
GmmUI.__index = GmmUI;
local function mk(className, props)
	local inst = Instance.new(className);
	for k, v in pairs(props or {}) do
		inst[k] = v;
	end
	return inst;
end
local function tween(obj, ti, props)
	local t = TweenService:Create(obj, ti, props);
	t:Play();
	return t;
end
local DEFAULTS = {Title="GMM",Tab="HOME",Size=UDim2.fromOffset(320, 460),Position=UDim2.new(0.02999, 0, 0.02999, 0),DisplayOrder=2147483647,Accent=Color3.fromRGB(138, 3, 3),Select=Color3.fromRGB(138, 3, 3),Bg=Color3.fromRGB(0, 0, 0),Text=Color3.fromRGB(240, 240, 240),TitleText=Color3.fromRGB(240, 240, 240),SelectedText=Color3.fromRGB(240, 240, 240),Scroller=Color3.fromRGB(138, 3, 3),ScrollBarThickness=4,ScrollSmoothness=4,HeaderHeight=78,SubHeight=24,FooterHeight=38,RowHeight=30};

local SoundService = game:GetService("SoundService");
GmmUI.Themes = {
	Default = DEFAULTS,
	Dark = {Accent=Color3.fromRGB(80, 80, 80),Select=Color3.fromRGB(100, 100, 100),Bg=Color3.fromRGB(20, 20, 20),Text=Color3.fromRGB(200, 200, 200),TitleText=Color3.fromRGB(255, 255, 255),SelectedText=Color3.fromRGB(255, 255, 255),Scroller=Color3.fromRGB(100, 100, 100),ScrollBarThickness=4,ScrollSmoothness=4,HeaderHeight=78,SubHeight=24,FooterHeight=38,RowHeight=30},
	Light = {Accent=Color3.fromRGB(200, 200, 200),Select=Color3.fromRGB(180, 180, 180),Bg=Color3.fromRGB(240, 240, 240),Text=Color3.fromRGB(20, 20, 20),TitleText=Color3.fromRGB(0, 0, 0),SelectedText=Color3.fromRGB(0, 0, 0),Scroller=Color3.fromRGB(150, 150, 150),ScrollBarThickness=4,ScrollSmoothness=4,HeaderHeight=78,SubHeight=24,FooterHeight=38,RowHeight=30},
	Cherry = {Accent=Color3.fromRGB(200, 50, 80),Select=Color3.fromRGB(220, 70, 100),Bg=Color3.fromRGB(30, 20, 25),Text=Color3.fromRGB(255, 200, 220),TitleText=Color3.fromRGB(255, 220, 230),SelectedText=Color3.fromRGB(255, 255, 255),Scroller=Color3.fromRGB(200, 50, 80),ScrollBarThickness=4,ScrollSmoothness=4,HeaderHeight=78,SubHeight=24,FooterHeight=38,RowHeight=30},
	Ocean = {Accent=Color3.fromRGB(40, 120, 200),Select=Color3.fromRGB(60, 140, 220),Bg=Color3.fromRGB(15, 25, 35),Text=Color3.fromRGB(180, 220, 255),TitleText=Color3.fromRGB(220, 240, 255),SelectedText=Color3.fromRGB(255, 255, 255),Scroller=Color3.fromRGB(40, 120, 200),ScrollBarThickness=4,ScrollSmoothness=4,HeaderHeight=78,SubHeight=24,FooterHeight=38,RowHeight=30}
};

GmmUI.Sounds = {
	Hover = "rbxassetid://130785368",
	Select = "rbxassetid://68950866",
	Toggle = "rbxassetid://1474945112",
	Error = "rbxassetid://893340578",
	Notify = "rbxassetid://68950866"
};

local function playSound(name)
	local id = GmmUI.Sounds[name]
	if id then
		local snd = Instance.new("Sound")
		snd.SoundId = id
		snd.Volume = 0.5
		snd.Parent = SoundService
		snd:Play()
		game.Debris:AddItem(snd, 2)
	end
end

local function safeParentGui()
	local lp = Players.LocalPlayer;
	local pg = lp and lp:FindFirstChildOfClass("PlayerGui");
	if pg then
		return pg;
	end
	return game:GetService("CoreGui");
end
local Menu = {};
Menu.__index = Menu;
Menu.new = function(ui, name)
	local self = setmetatable({}, Menu);
	self.UI = ui;
	self.Name = tostring(name or "MENU"):upper();
	self.Items = {};
	return self;
end;
Menu._addItem = function(self, item)
	table.insert(self.Items, item);
	return item;
end;
Menu.Button = function(self, label, desc, callback)
	return self:_addItem({Type="Button",Label=tostring(label),Desc=tostring(desc or ""),Activate=function()
		if (typeof(callback) == "function") then
			task.spawn(callback);
		end
	end});
end;
Menu.Toggle = function(self, label, desc, defaultValue, callback)
	local state = defaultValue == true;
	return self:_addItem({Type="Toggle",Label=tostring(label),Desc=tostring(desc or ""),Get=function()
		return state;
	end,Set=function(v)
		state = (v and true) or false;
		if (typeof(callback) == "function") then
			task.spawn(callback, state);
		end
	end,Left=function(it)
		it.Set(not it.Get());
	end,Right=function(it)
		it.Set(not it.Get());
	end,Activate=function(it)
		it.Set(not it.Get());
	end,ValueText=function(it)
		return (it.Get() and "ON") or "OFF";
	end});
end;
Menu.Slider = function(self, label, desc, min, max, step, defaultValue, callback)
	min = tonumber(min) or 0;
	max = tonumber(max) or 100;
	step = tonumber(step) or 1;
	local value = tonumber(defaultValue);
	if (value == nil) then
		value = min;
	end
	value = math.clamp(value, min, max);
	local function set(v)
		v = math.clamp(v, min, max);
		local snapped = min + (math.floor(((v - min) / step) + 0.5) * step);
		value = math.clamp(snapped, min, max);
		if (typeof(callback) == "function") then
			task.spawn(callback, value);
		end
	end
	return self:_addItem({Type="Slider",Label=tostring(label),Desc=tostring(desc or ""),Get=function()
		return value;
	end,Set=set,Left=function(it)
		it.Set(it.Get() - step);
	end,Right=function(it)
		it.Set(it.Get() + step);
	end,Activate=function()
	end,ValueText=function(it)
		return tostring(it.Get());
	end});
end;
Menu.List = function(self, label, desc, values, defaultIndex, callback)
	values = ((typeof(values) == "table") and values) or {};
	local idx = tonumber(defaultIndex) or 1;
	if (#values == 0) then
		values = {"N/A"};
		idx = 1;
	end
	idx = math.clamp(idx, 1, #values);
	local function setIndex(i)
		idx = ((i - 1) % #values) + 1;
		if (typeof(callback) == "function") then
			task.spawn(callback, values[idx], idx);
		end
	end
	return self:_addItem({Type="List",Label=tostring(label),Desc=tostring(desc or ""),GetIndex=function()
		return idx;
	end,SetIndex=setIndex,Left=function(it)
		it.SetIndex(it.GetIndex() - 1);
	end,Right=function(it)
		it.SetIndex(it.GetIndex() + 1);
	end,Activate=function(it)
		it.SetIndex(it.GetIndex() + 1);
	end,ValueText=function(it)
		return tostring(values[idx]);
	end});
end;
Menu.Submenu = function(self, label, desc, submenu)
	assert(getmetatable(submenu) == Menu, "Submenu must be a Menu created by UI:NewMenu(...)");
	return self:_addItem({Type="Submenu",Label=tostring(label),Desc=tostring(desc or ""),HasArrow=true,Activate=function()
		self.UI:PushMenu(submenu);
	end});
end;
GmmUI.new = function(opts)
	opts = opts or {};
	for k, v in pairs(DEFAULTS) do
		if (opts[k] == nil) then
			opts[k] = v;
		end
	end
	local self = setmetatable({}, GmmUI);
	self.Opts = opts;
	self.Opened = true;
	self.MenuStack = {};
	self.Current = nil;
	self.SelectedIndex = 0;
	self._connections = {};
	self._rowObjects = {};
	self._edit = nil;
	self._holdDir = nil;
	self._holdToken = 0;
	local gui = mk("ScreenGui", {Name="GmmUI",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=opts.DisplayOrder,Parent=safeParentGui()});
	self.Gui = gui;
	local main = mk("Frame", {Name="Main",Parent=gui,Size=opts.Size,Position=opts.Position,BackgroundColor3=opts.Bg,BackgroundTransparency=0.12,BorderSizePixel=0,ClipsDescendants=true});
	self.Main = main;
	local header = mk("Frame", {Name="Header",Parent=main,Size=UDim2.new(1, 0, 0, opts.HeaderHeight),BackgroundColor3=opts.Accent,BorderSizePixel=0});
	self.Header = header;
	self.TitleLabel = mk("TextLabel", {Parent=header,BackgroundTransparency=1,Size=UDim2.new(1, 0, 1, 0),Font=Enum.Font.GothamBlack,Text=tostring(opts.Title):upper(),TextColor3=(opts.TitleText or opts.Text),TextSize=44,TextStrokeTransparency=0.78,TextStrokeColor3=Color3.fromRGB(0, 0, 0)});
	local sub = mk("Frame", {Name="Sub",Parent=main,Position=UDim2.fromOffset(0, opts.HeaderHeight),Size=UDim2.new(1, 0, 0, opts.SubHeight),BackgroundColor3=opts.Bg,BackgroundTransparency=0,BorderSizePixel=0});
	self.Sub = sub;
	self.TabLabel = mk("TextLabel", {Parent=sub,BackgroundTransparency=1,Position=UDim2.fromOffset(10, 0),Size=UDim2.new(0.6, 0, 1, 0),Font=Enum.Font.GothamMedium,Text=tostring(opts.Tab):upper(),TextColor3=opts.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
	self.CounterLabel = mk("TextLabel", {Parent=sub,BackgroundTransparency=1,Position=UDim2.new(0.6, 0, 0, 0),Size=UDim2.new(0.4, -10, 1, 0),Font=Enum.Font.GothamMedium,Text="0 / 0",TextColor3=opts.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Right});
	local listTop = opts.HeaderHeight + opts.SubHeight;
	local listBottom = opts.FooterHeight;
	local listHeightOffset = listTop + listBottom;
	local scroll = mk("ScrollingFrame", {Name="Scroll",Parent=main,Position=UDim2.fromOffset(0, listTop),Size=UDim2.new(1, 0, 1, -listHeightOffset),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=(opts.ScrollBarThickness or 4),ScrollBarImageColor3=(opts.Scroller or opts.Accent),CanvasSize=UDim2.new(0, 0, 0, 0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollingEnabled=false});
	self.Scroll = scroll;
	local layout = mk("UIListLayout", {Parent=scroll,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0, 0)});
	self.Layout = layout;
	local footer = mk("Frame", {Name="Footer",Parent=main,Position=UDim2.new(0, 0, 1, -opts.FooterHeight),Size=UDim2.new(1, 0, 0, opts.FooterHeight),BackgroundColor3=opts.Bg,BorderSizePixel=0});
	self.Footer = footer;
	mk("Frame", {Parent=footer,Size=UDim2.new(1, 0, 0, 2),BackgroundColor3=opts.Accent,BorderSizePixel=0});
	self.DescLabel = mk("TextLabel", {Parent=footer,BackgroundTransparency=1,Position=UDim2.fromOffset(8, 2),Size=UDim2.new(1, -16, 1, -4),Font=Enum.Font.Gotham,Text="Select an option.",TextColor3=opts.Text,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true});
	self._casActions = {"GmmUI_Toggle","GmmUI_Up","GmmUI_Down","GmmUI_Left","GmmUI_Right","GmmUI_PageUp","GmmUI_PageDown","GmmUI_Back","GmmUI_Select","GmmUI_MouseWheel"};
	for _, name in ipairs(self._casActions) do
		pcall(function()
			ContextActionService:UnbindAction(name);
		end);
	end
	local actionPriority = ((opts.InputPriority ~= nil) and tonumber(opts.InputPriority)) or (Enum.ContextActionPriority.High.Value + 5000);
	local function bind(actionName, fn, ...)
		ContextActionService:BindActionAtPriority(actionName, fn, false, actionPriority, ...);
	end
	bind("GmmUI_Toggle", function(_, state)
		if (state ~= Enum.UserInputState.Begin) then
			return Enum.ContextActionResult.Pass;
		end
		self:Toggle();
		return Enum.ContextActionResult.Sink;
	end, Enum.KeyCode.F4, Enum.KeyCode.Insert);
	bind("GmmUI_Up", function(_, state)
		if (state ~= Enum.UserInputState.Begin) then
			return Enum.ContextActionResult.Pass;
		end
		if not self.Opened then
			return Enum.ContextActionResult.Pass;
		end
		if self._edit then
			return Enum.ContextActionResult.Sink;
		end
		self:SetSelected(self.SelectedIndex - 1);
		return Enum.ContextActionResult.Sink;
	end, Enum.KeyCode.Up, Enum.KeyCode.KeypadEight, Enum.KeyCode.I);
	bind("GmmUI_Down", function(_, state)
		if (state ~= Enum.UserInputState.Begin) then
			return Enum.ContextActionResult.Pass;
		end
		if not self.Opened then
			return Enum.ContextActionResult.Pass;
		end
		if self._edit then
			return Enum.ContextActionResult.Sink;
		end
		self:SetSelected(self.SelectedIndex + 1);
		return Enum.ContextActionResult.Sink;
	end, Enum.KeyCode.Down, Enum.KeyCode.KeypadTwo, Enum.KeyCode.K);
	bind("GmmUI_Left", function(_, state)
		if not self.Opened then
			return Enum.ContextActionResult.Pass;
		end
		if (state == Enum.UserInputState.Begin) then
			self:DoLeft();
			self:_startHold(-1);
			return Enum.ContextActionResult.Sink;
		elseif (state == Enum.UserInputState.End) then
			self:_stopHold(-1);
			return Enum.ContextActionResult.Sink;
		end
		return Enum.ContextActionResult.Pass;
	end, Enum.KeyCode.Left, Enum.KeyCode.KeypadFour, Enum.KeyCode.J);
	bind("GmmUI_Right", function(_, state)
		if not self.Opened then
			return Enum.ContextActionResult.Pass;
		end
		if (state == Enum.UserInputState.Begin) then
			self:DoRight();
			self:_startHold(1);
			return Enum.ContextActionResult.Sink;
		elseif (state == Enum.UserInputState.End) then
			self:_stopHold(1);
			return Enum.ContextActionResult.Sink;
		end
		return Enum.ContextActionResult.Pass;
	end, Enum.KeyCode.Right, Enum.KeyCode.KeypadSix, Enum.KeyCode.L);
	bind("GmmUI_PageUp", function(_, state)
		if (state ~= Enum.UserInputState.Begin) then
			return Enum.ContextActionResult.Pass;
		end
		if not self.Opened then
			return Enum.ContextActionResult.Pass;
		end
		if self._edit then
			return Enum.ContextActionResult.Sink;
		end
		self:SetSelected(self.SelectedIndex - 10);
		return Enum.ContextActionResult.Sink;
	end, Enum.KeyCode.PageUp, Enum.KeyCode.KeypadNine);
	bind("GmmUI_PageDown", function(_, state)
		if (state ~= Enum.UserInputState.Begin) then
			return Enum.ContextActionResult.Pass;
		end
		if not self.Opened then
			return Enum.ContextActionResult.Pass;
		end
		if self._edit then
			return Enum.ContextActionResult.Sink;
		end
		self:SetSelected(self.SelectedIndex + 10);
		return Enum.ContextActionResult.Sink;
	end, Enum.KeyCode.PageDown, Enum.KeyCode.KeypadThree);
	bind("GmmUI_Back", function(_, state)
		if (state ~= Enum.UserInputState.Begin) then
			return Enum.ContextActionResult.Pass;
		end
		if not self.Opened then
			return Enum.ContextActionResult.Pass;
		end
		if self._edit then
			self:CancelEdit();
		else
			self:Back();
		end
		return Enum.ContextActionResult.Sink;
	end, Enum.KeyCode.Backspace, Enum.KeyCode.KeypadZero, Enum.KeyCode.U);
	
	bind("GmmUI_MouseWheel", function(_, state, input)
		if not self.Opened then return Enum.ContextActionResult.Pass end
		if input.Position.Z > 0 then
			if self._edit then self:DoRight() else self:SetSelected(self.SelectedIndex - 1) end
		elseif input.Position.Z < 0 then
			if self._edit then self:DoLeft() else self:SetSelected(self.SelectedIndex + 1) end
		end
		return Enum.ContextActionResult.Sink
	end, Enum.UserInputType.MouseWheel)
bind("GmmUI_Select","GmmUI_MouseWheel", function(_, state)
		if (state ~= Enum.UserInputState.Begin) then
			return Enum.ContextActionResult.Pass;
		end
		if not self.Opened then
			return Enum.ContextActionResult.Pass;
		end
		self:Select();
		return Enum.ContextActionResult.Sink;
	end, Enum.KeyCode.Return, Enum.KeyCode.KeypadFive, Enum.KeyCode.O);
	return self;
end;
GmmUI.NewMenu = function(self, name)
	return Menu.new(self, name);
end;

GmmUI.SetTheme = function(self, themeName)
	local theme = GmmUI.Themes[themeName]
	if not theme then return end
	self.Opts.Accent = theme.Accent or self.Opts.Accent
	self.Opts.Select = theme.Select or self.Opts.Select
	self.Opts.Bg = theme.Bg or self.Opts.Bg
	self.Opts.Text = theme.Text or self.Opts.Text
	self.Opts.TitleText = theme.TitleText or self.Opts.TitleText
	self.Opts.SelectedText = theme.SelectedText or self.Opts.SelectedText
	self.Opts.Scroller = theme.Scroller or self.Opts.Scroller
	
	if self.Main then self.Main.BackgroundColor3 = self.Opts.Bg end
	if self.Header then self.Header.BackgroundColor3 = self.Opts.Accent end
	if self.Sub then self.Sub.BackgroundColor3 = self.Opts.Bg end
	if self.Footer then 
		self.Footer.BackgroundColor3 = self.Opts.Bg 
		if self.Footer:FindFirstChildOfClass("Frame") then
			self.Footer:FindFirstChildOfClass("Frame").BackgroundColor3 = self.Opts.Accent
		end
	end
	if self.Scroll then self.Scroll.ScrollBarImageColor3 = self.Opts.Scroller end
	if self.TitleLabel then self.TitleLabel.TextColor3 = self.Opts.TitleText end
	if self.TabLabel then self.TabLabel.TextColor3 = self.Opts.Text end
	if self.CounterLabel then self.CounterLabel.TextColor3 = self.Opts.Text end
	if self.DescLabel then self.DescLabel.TextColor3 = self.Opts.Text end
	
	-- Update existing rows
	if self.Current then
		for i, it in ipairs(self.Current.Items) do
			if it.__setSelected then
				it.__setSelected(i == self.SelectedIndex)
			end
		end
	end
end;
GmmUI.SetTitle = function(self, text)
	self.TitleLabel.Text = tostring(text):upper();
end;
GmmUI.SetTab = function(self, text)
	self.TabLabel.Text = tostring(text):upper();
end;
GmmUI._updateCounter = function(self)
	local total = (self.Current and #self.Current.Items) or 0;
	local sel = ((total > 0) and math.clamp(self.SelectedIndex, 1, total)) or 0;
	self.CounterLabel.Text = string.format("%d / %d", sel, total);
end;
GmmUI._saveMenuState = function(self)
	local menu = self.Current;
	if not menu then
		return;
	end
	menu._savedIndex = tonumber(self.SelectedIndex) or 0;
	if self.Scroll then
		local y = (self._scrollTargetY ~= nil and self._scrollTargetY) or self.Scroll.CanvasPosition.Y;
		menu._savedCanvasY = tonumber(y) or 0;
	end
end;
GmmUI._clearRows = function(self)
	for _, row in ipairs(self._rowObjects) do
		if (row and row.Destroy) then
			row:Destroy();
		end
	end
	self._rowObjects = {};
end;
GmmUI._makeRow = function(self, item, index)
	local opts = self.Opts;
	local row = mk("TextButton", {Parent=self.Scroll,Size=UDim2.new(1, 0, 0, opts.RowHeight),BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Text=""});
	local selBg = mk("Frame", {Parent=row,Size=UDim2.new(1, 0, 1, 0),BackgroundColor3=opts.Select,BorderSizePixel=0,Visible=false});
	mk("Frame", {Parent=row,AnchorPoint=Vector2.new(0, 1),Position=UDim2.new(0, 0, 1, 0),Size=UDim2.new(1, 0, 0, 1),BackgroundColor3=Color3.fromRGB(255, 255, 255),BackgroundTransparency=0.92,BorderSizePixel=0});
	local left = mk("TextLabel", {Parent=row,BackgroundTransparency=1,Position=UDim2.fromOffset(10, 0),Size=UDim2.new(1, -110, 1, 0),Font=Enum.Font.Gotham,Text=item.Label,TextColor3=opts.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left});
	local right = mk("TextLabel", {Parent=row,BackgroundTransparency=1,Position=UDim2.new(1, -86, 0, 0),Size=UDim2.fromOffset(62, opts.RowHeight),Font=Enum.Font.GothamBold,Text="",TextColor3=opts.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Right});
	local arrow = mk("TextLabel", {Parent=row,BackgroundTransparency=1,Position=UDim2.new(1, -24, 0, 0),Size=UDim2.fromOffset(24, opts.RowHeight),Font=Enum.Font.GothamBold,Text=">",TextColor3=opts.Text,TextSize=14});
	if (item.HasArrow or (item.Type == "Submenu")) then
		arrow.Visible = true;
	else
		arrow.Visible = false;
	end
	local function setSelected(on)
		selBg.Visible = on;
		local c = (on and (opts.SelectedText or opts.Text)) or opts.Text;
		left.TextColor3 = c;
		right.TextColor3 = c;
		arrow.TextColor3 = c;
		if on then
			selBg.BackgroundTransparency = 0.2;
			tween(selBg, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=0});
		end
	end
	local function refreshValue()
		if item.ValueText then
			local t = item:ValueText();
			if ((item.Type == "Slider") and self._edit and (self._edit.Item == item)) then
				right.Text = "< " .. t .. " >";
			else
				right.Text = t;
			end
		else
			right.Text = "";
		end
	end
	refreshValue();
		row.MouseEnter:Connect(function()
		if self._edit then return end
		self:SetSelected(index)
	end)
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self._edit then return end
			self:SetSelected(index)
			self:Select()
		end
	end)
	-- Disable default click since we use InputBegan
	-- row.MouseButton1Click is left below but won't conflict.


	return row, setSelected, refreshValue;
end;
GmmUI._renderMenu = function(self, menu)
	self:_clearRows();
	self.Current = menu;
	self:SetTab(menu.Name);
	for i, item in ipairs(menu.Items) do
		local row, setSelected, refreshValue = self:_makeRow(item, i);
		item.__row = row;
		item.__setSelected = setSelected;
		item.__refreshValue = refreshValue;
		table.insert(self._rowObjects, row);
	end
	if (#menu.Items > 0) then
		local savedY = tonumber(menu._savedCanvasY) or 0;
		if self._scrollTween then
			pcall(function()
				self._scrollTween:Cancel();
			end);
			self._scrollTween = nil;
		end
		self.Scroll.CanvasPosition = Vector2.new(0, savedY);
		self._scrollTargetY = savedY;
		local savedIdx = tonumber(menu._savedIndex);
		if not (savedIdx and (savedIdx >= 1) and (savedIdx <= #menu.Items)) then
			savedIdx = 1;
		end
		self:SetSelected(savedIdx);
	else
		self.SelectedIndex = 0;
		self.DescLabel.Text = "No options.";
		self:_updateCounter();
	end
end;
GmmUI.PushMenu = function(self, menu)
	self:_saveMenuState();
	table.insert(self.MenuStack, menu);
	self:_renderMenu(menu);
end;
GmmUI.Back = function(self)
	if self._edit then
		self:CancelEdit();
		return;
	end
	if (#self.MenuStack <= 1) then
		self:Close();
		return;
	end
	self:_saveMenuState();
	table.remove(self.MenuStack, #self.MenuStack);
	local top = self.MenuStack[#self.MenuStack];
	self:_renderMenu(top);
end;
GmmUI._scrollTo = function(self, targetY)
	local scroll = self.Scroll;
	if not scroll then
		return;
	end
	targetY = tonumber(targetY) or 0;
	self._scrollTargetY = targetY;
	local absCanvasY = scroll.AbsoluteCanvasSize.Y;
	local maxY = (absCanvasY > 0) and math.max(0, absCanvasY - scroll.AbsoluteSize.Y) or math.huge;
	targetY = math.clamp(targetY, 0, maxY);
	if self._scrollTween then
		pcall(function()
			self._scrollTween:Cancel();
		end);
		self._scrollTween = nil;
	end
	local smoothness = tonumber(self.Opts and self.Opts.ScrollSmoothness) or 0;
	if (smoothness <= 0) then
		scroll.CanvasPosition = Vector2.new(0, targetY);
		self._scrollTargetY = targetY;
		return;
	end
	local duration = math.clamp(0.04 * smoothness, 0.05, 0.4);
	self._scrollTween = tween(scroll, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CanvasPosition=Vector2.new(0, targetY)});
end;
GmmUI.SetSelected = function(self, idx)
	if not self.Current then
		return;
	end
	local items = self.Current.Items;
	if (#items == 0) then
		return;
	end
	idx = ((idx - 1) % #items) + 1;
	if self.SelectedIndex ~= idx then playSound("Hover") end
	self.SelectedIndex = idx;
	for i, it in ipairs(items) do
		if it.__setSelected then
			it.__setSelected(i == idx);
		end
	end
	local it = items[idx];
	self.DescLabel.Text = (it and it.Desc and (it.Desc ~= "") and it.Desc) or "Select an option.";
	self:_updateCounter();
	local row = it and it.__row;
	if row then
		local y = row.AbsolutePosition.Y;
		local h = row.AbsoluteSize.Y;
		local topY = self.Scroll.AbsolutePosition.Y;
		local botY = topY + self.Scroll.AbsoluteSize.Y;
		if (y < topY) then
			self:_scrollTo(self.Scroll.CanvasPosition.Y - (topY - y));
		elseif ((y + h) > botY) then
			self:_scrollTo(self.Scroll.CanvasPosition.Y + ((y + h) - botY));
		end
	end
	self:_saveMenuState();
end;
GmmUI._getSelectedItem = function(self)
	if not self.Current then
		return nil;
	end
	return self.Current.Items[self.SelectedIndex];
end;
GmmUI._stopHold = function(self, dir)
	if ((dir == nil) or (self._holdDir == dir)) then
		self._holdDir = nil;
		self._holdToken = (self._holdToken or 0) + 1;
	end
end;
GmmUI._startHold = function(self, dir)
	local it = self._edit and self._edit.Item;
	if not (self.Opened and it and (it == self:_getSelectedItem()) and (it.Type == "Slider")) then
		return;
	end
	self._holdDir = dir;
	self._holdToken = (self._holdToken or 0) + 1;
	local token = self._holdToken;
	task.spawn(function()
		task.wait(0.35);
		while (self._holdToken == token) and (self._holdDir == dir) do
			if not self.Opened then
				break;
			end
			if (not self._edit or (self._edit.Item ~= it)) then
				break;
			end
			if (dir < 0) then
				self:DoLeft();
			else
				self:DoRight();
			end
			task.wait(0.05);
		end
	end);
end;
GmmUI.BeginEdit = function(self)
	if self._edit then
		return;
	end
	local it = self:_getSelectedItem();
	if (not it or (it.Type ~= "Slider")) then
		return;
	end
	self._edit = {Item=it,Original=((it.Get and it.Get()) or nil)};
	if it.__refreshValue then
		it.__refreshValue();
	end
end;
GmmUI.ConfirmEdit = function(self)
	if not self._edit then
		return;
	end
	local it = self._edit.Item;
	self._edit = nil;
	self:_stopHold();
	if (it and it.__refreshValue) then
		it.__refreshValue();
	end
end;
GmmUI.CancelEdit = function(self)
	if not self._edit then
		return;
	end
	local it = self._edit.Item;
	local original = self._edit.Original;
	self._edit = nil;
	self:_stopHold();
	if (it and (original ~= nil) and it.Set) then
		it.Set(original);
	end
	if (it and it.__refreshValue) then
		it.__refreshValue();
	end
end;
GmmUI.DoLeft = function(self)
	local it = self:_getSelectedItem();
	if not it then
		return;
	end
	if (it.Type == "Slider") then
		if not (self._edit and (self._edit.Item == it)) then
			return;
		end
	end
	if it.Left then
		it:Left();
		if it.__refreshValue then
			it.__refreshValue();
		end
	end
end;
GmmUI.DoRight = function(self)
	local it = self:_getSelectedItem();
	if not it then
		return;
	end
	if (it.Type == "Slider") then
		if not (self._edit and (self._edit.Item == it)) then
			return;
		end
	end
	if it.Right then
		it:Right();
		if it.__refreshValue then
			it.__refreshValue();
		end
	end
end;
GmmUI.Select = function(self)
	local it = self:_getSelectedItem();
	if not it then
		return;
	end
	if (it.Type == "Slider") then
		if (self._edit and (self._edit.Item == it)) then
			playSound("Toggle");
			self:ConfirmEdit();
		else
			playSound("Select");
			self:BeginEdit();
		end
		return;
	end
	if it.Activate then
		it:Activate();
		playSound("Select");
		if it.__refreshValue then
			it.__refreshValue();
		end
	end
end;
GmmUI.Open = function(self)
	if self.Opened then
		return;
	end
	self.Opened = true;
	self.Main.Visible = true;
	self.Main.BackgroundTransparency = 0.35;
	tween(self.Main, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=0.12});
end;
GmmUI.Close = function(self)
	if not self.Opened then
		return;
	end
	if self._edit then
		playSound("Toggle");
			self:ConfirmEdit();
	else
		self:_stopHold();
	end
	self.Opened = false;
	local t = tween(self.Main, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency=0.35});
	t.Completed:Connect(function()
		if not self.Opened then
			self.Main.Visible = false;
		end
	end);
end;
GmmUI.Toggle = function(self)
	if self.Opened then
		self:Close();
	else
		self:Open();
	end
end;
GmmUI.Destroy = function(self)
	for _, c in ipairs(self._connections) do
		pcall(function()
			c:Disconnect();
		end);
	end
	self._connections = {};
	if self._casActions then
		for _, name in ipairs(self._casActions) do
			pcall(function()
				ContextActionService:UnbindAction(name);
			end);
		end
		self._casActions = nil;
	end
	if self.Gui then
		self.Gui:Destroy();
	end
end;

GmmUI.Notify = function(self, opts)
	opts = opts or {}
	local title = opts.Title or "Notification"
	local content = opts.Content or ""
	local duration = opts.Duration or 3
	
	playSound("Notify")
	
	local screenGui = safeParentGui():FindFirstChild("GmmNotifications")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "GmmNotifications"
		screenGui.ResetOnSpawn = false
		screenGui.DisplayOrder = 2147483647
		screenGui.Parent = safeParentGui()
	end
	
	local notifBg = Instance.new("Frame")
	notifBg.Size = UDim2.fromOffset(250, 70)
	notifBg.Position = UDim2.new(1, 10, 1, -80)
	notifBg.BackgroundColor3 = self.Opts.Bg or Color3.fromRGB(20,20,20)
	notifBg.BorderSizePixel = 0
	notifBg.Parent = screenGui
	
	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 4, 1, 0)
	accent.BackgroundColor3 = self.Opts.Accent or Color3.fromRGB(138, 3, 3)
	accent.BorderSizePixel = 0
	accent.Parent = notifBg
	
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -15, 0, 20)
	titleLbl.Position = UDim2.fromOffset(10, 5)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.Text = title
	titleLbl.TextColor3 = self.Opts.TitleText or Color3.fromRGB(255,255,255)
	titleLbl.TextSize = 14
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = notifBg
	
	local contentLbl = Instance.new("TextLabel")
	contentLbl.Size = UDim2.new(1, -15, 1, -30)
	contentLbl.Position = UDim2.fromOffset(10, 25)
	contentLbl.BackgroundTransparency = 1
	contentLbl.Font = Enum.Font.Gotham
	contentLbl.Text = content
	contentLbl.TextColor3 = self.Opts.Text or Color3.fromRGB(200,200,200)
	contentLbl.TextSize = 12
	contentLbl.TextXAlignment = Enum.TextXAlignment.Left
	contentLbl.TextYAlignment = Enum.TextYAlignment.Top
	contentLbl.TextWrapped = true
	contentLbl.Parent = notifBg
	
	-- Shift existing notifications up
	for _, child in ipairs(screenGui:GetChildren()) do
		if child ~= notifBg then
			tween(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = child.Position - UDim2.fromOffset(0, 80)
			})
		end
	end
	
	tween(notifBg, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -260, 1, -80)
	})
	
	task.delay(duration, function()
		local t = tween(notifBg, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 10, notifBg.Position.Y.Scale, notifBg.Position.Y.Offset)
		})
		t.Completed:Connect(function()
			notifBg:Destroy()
		end)
	end)
end

GmmUI.PromptKey = function(opts, callback)
	opts = opts or {}
	local correctKey = opts.Key or "1234"
	local title = opts.Title or "Key System"
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GmmKeySystem"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 2147483647
	screenGui.Parent = safeParentGui()
	
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromOffset(300, 150)
	bg.Position = UDim2.new(0.5, -150, 0.5, -75)
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bg.BorderSizePixel = 0
	bg.Parent = screenGui
	
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundColor3 = Color3.fromRGB(138, 3, 3)
	header.BorderSizePixel = 0
	header.Parent = bg
	
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, 0, 1, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.Text = title
	titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLbl.TextSize = 14
	titleLbl.Parent = header
	
	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(1, -40, 0, 40)
	textBox.Position = UDim2.fromOffset(20, 50)
	textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	textBox.BorderSizePixel = 0
	textBox.Font = Enum.Font.Gotham
	textBox.PlaceholderText = "Enter Key Here..."
	textBox.Text = ""
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.TextSize = 14
	textBox.Parent = bg
	
	local submitBtn = Instance.new("TextButton")
	submitBtn.Size = UDim2.new(1, -40, 0, 30)
	submitBtn.Position = UDim2.fromOffset(20, 100)
	submitBtn.BackgroundColor3 = Color3.fromRGB(138, 3, 3)
	submitBtn.BorderSizePixel = 0
	submitBtn.Font = Enum.Font.GothamBold
	submitBtn.Text = "SUBMIT"
	submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	submitBtn.TextSize = 14
	submitBtn.Parent = bg
	
	submitBtn.MouseButton1Click:Connect(function()
		if textBox.Text == correctKey then
			playSound("Success")
			screenGui:Destroy()
			if type(callback) == "function" then
				callback()
			end
		else
			playSound("Error")
			textBox.Text = ""
			textBox.PlaceholderText = "Incorrect Key!"
		end
	end)
end
return GmmUI;
