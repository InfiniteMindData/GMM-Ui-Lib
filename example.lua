local GmmUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MermiXO/GMM-Ui-Lib/refs/heads/main/src.lua?t=" .. tick()))()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local Settings = {
    GodMode = false,
    SuperJump = false,
    FastWalk = false,
    Invisible = false,
    FreezeTime = false,
    OriginalWalkSpeed = 16,
    OriginalJumpPower = 50,
    SavedLocations = {},
    CurrentTheme = "Classic",
    Keybinds = {
        GodMode = Enum.KeyCode.G,
        SuperJump = Enum.KeyCode.J,
        FastWalk = Enum.KeyCode.F,
        Invisible = Enum.KeyCode.I
    }
}

local function setGodMode(enabled)
    Settings.GodMode = enabled
    local humanoid = getHumanoid()
    if humanoid then
        if enabled then
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        else
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
    end
end

local function setSuperJump(enabled)
    Settings.SuperJump = enabled
    local humanoid = getHumanoid()
    if humanoid then
        if enabled then
            humanoid.JumpPower = 150
            humanoid.JumpHeight = 50
        else
            humanoid.JumpPower = Settings.OriginalJumpPower
            humanoid.JumpHeight = 7.2
        end
    end
end

local function setFastWalk(enabled, speed)
    Settings.FastWalk = enabled
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = enabled and (speed or 50) or Settings.OriginalWalkSpeed
    end
end

local function setInvisible(enabled)
    Settings.Invisible = enabled
    local char = getCharacter()
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = enabled and 1 or 0
            elseif part:IsA("Decal") then
                part.Transparency = enabled and 1 or 0
            end
        end
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face")
            if face then
                face.Transparency = enabled and 1 or 0
            end
        end
    end
end

local function setTime(hour)
    Lighting.ClockTime = hour
end

local function freezeTime(enabled)
    Settings.FreezeTime = enabled
    if enabled then
        Lighting:SetAttribute("FrozenTime", Lighting.ClockTime)
    end
end

local WeatherTypes = { "Clear", "Foggy", "Rainy", "Dark", "Sunset", "Night" }

local function setWeather(weatherType)
    if weatherType == "Clear" then
        Lighting.Brightness = 2
        Lighting.FogEnd = 100000
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    elseif weatherType == "Foggy" then
        Lighting.FogEnd = 200
        Lighting.FogColor = Color3.fromRGB(200, 200, 200)
    elseif weatherType == "Rainy" then
        Lighting.Brightness = 0.5
        Lighting.FogEnd = 500
        Lighting.Ambient = Color3.fromRGB(80, 80, 100)
    elseif weatherType == "Dark" then
        Lighting.Brightness = 0
        Lighting.Ambient = Color3.fromRGB(20, 20, 20)
    elseif weatherType == "Sunset" then
        Lighting.ClockTime = 18.5
        Lighting.Brightness = 1.5
        Lighting.Ambient = Color3.fromRGB(255, 150, 100)
    elseif weatherType == "Night" then
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.5
        Lighting.Ambient = Color3.fromRGB(50, 50, 80)
    end
end

local function setGravity(value)
    Workspace.Gravity = value
end

local function teleportTo(position)
    local rootPart = getRootPart()
    if rootPart then
        rootPart.CFrame = CFrame.new(position)
    end
end

local function teleportToPlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if targetPlayer and targetPlayer.Character then
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            teleportTo(targetRoot.Position + Vector3.new(3, 0, 0))
        end
    end
end

local function saveLocation(name)
    local rootPart = getRootPart()
    if rootPart then
        Settings.SavedLocations[name] = rootPart.Position
    end
end

local ui = GmmUI.new({ Title = "TEST" })

local homeMenu = ui:NewMenu("HOME")
local playerMenu = ui:NewMenu("PLAYER")
local worldMenu = ui:NewMenu("WORLD")
local teleportMenu = ui:NewMenu("TELEPORT")
local settingsMenu = ui:NewMenu("SETTINGS")

local timeMenu = ui:NewMenu("TIME")
local weatherMenu = ui:NewMenu("WEATHER")
local gravityMenu = ui:NewMenu("GRAVITY")
local disasterMenu = ui:NewMenu("DISASTERS")
local waypointMenu = ui:NewMenu("WAYPOINTS")
local savedLocMenu = ui:NewMenu("SAVED LOCATIONS")
local tpPlayerMenu = ui:NewMenu("TP TO PLAYER")
local keybindMenu = ui:NewMenu("KEYBINDS")
local hotkeyMenu = ui:NewMenu("HOTKEY MGR")
local themeMenu = ui:NewMenu("THEME")

homeMenu:Submenu("Player Options", "Modify your character abilities.", playerMenu)
homeMenu:Submenu("World Options", "Control time, weather, and more.", worldMenu)
homeMenu:Submenu("Teleportation", "Teleport around the map.", teleportMenu)
homeMenu:Submenu("Settings", "Configure keybinds and UI.", settingsMenu)

playerMenu:Toggle("God Mode", "Makes the player invincible.", false, function(enabled)
    setGodMode(enabled)
end)

playerMenu:Toggle("Super Jump", "Increases jump height significantly.", false, function(enabled)
    setSuperJump(enabled)
end)

playerMenu:Toggle("Fast Walk", "Increases movement speed.", false, function(enabled)
    setFastWalk(enabled)
end)

playerMenu:Slider("Walk Speed", "Adjust your walk speed value.", 16, 200, 1, 16, function(speed)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end)

playerMenu:Toggle("Invisible", "Makes your character invisible.", false, function(enabled)
    setInvisible(enabled)
end)

worldMenu:Submenu("Time Settings", "Set or freeze the time of day.", timeMenu)
worldMenu:Submenu("Weather", "Change the weather conditions.", weatherMenu)
worldMenu:Submenu("Gravity", "Control world gravity.", gravityMenu)
worldMenu:Submenu("Special Events", "Trigger disasters and events.", disasterMenu)

timeMenu:Slider("Set Time", "Set the time of day (0-24).", 0, 24, 0.5, 12, function(hour)
    setTime(hour)
end)

timeMenu:Toggle("Freeze Time", "Stops time from progressing.", false, function(enabled)
    freezeTime(enabled)
end)

timeMenu:Button("Dawn (6:00)", "Set time to dawn.", function()
    setTime(6)
end)

timeMenu:Button("Noon (12:00)", "Set time to noon.", function()
    setTime(12)
end)

timeMenu:Button("Dusk (18:00)", "Set time to dusk.", function()
    setTime(18)
end)

timeMenu:Button("Midnight (0:00)", "Set time to midnight.", function()
    setTime(0)
end)

weatherMenu:List("Weather Type", "Select a weather preset.", WeatherTypes, 1, function(weather, index)
    setWeather(weather)
end)

weatherMenu:Button("Clear Weather", "Set to clear skies.", function()
    setWeather("Clear")
end)

weatherMenu:Button("Foggy", "Enable dense fog.", function()
    setWeather("Foggy")
end)

weatherMenu:Button("Rainy", "Enable rain effect.", function()
    setWeather("Rainy")
end)

gravityMenu:Slider("Gravity", "Adjust world gravity.", 0, 500, 5, 196.2, function(value)
    setGravity(value)
end)

gravityMenu:Button("Normal Gravity", "Reset to default gravity.", function()
    setGravity(196.2)
end)

gravityMenu:Button("Moon Gravity", "Low gravity like the moon.", function()
    setGravity(50)
end)

gravityMenu:Button("Zero Gravity", "No gravity at all.", function()
    setGravity(0)
end)

gravityMenu:Button("High Gravity", "Increased gravity.", function()
    setGravity(400)
end)

disasterMenu:Button("Explosion", "Create an explosion at your position.", function()
    local rootPart = getRootPart()
    if rootPart then
        local explosion = Instance.new("Explosion")
        explosion.BlastRadius = 20
        explosion.BlastPressure = 500000
        explosion.Position = rootPart.Position + Vector3.new(10, 0, 10)
        explosion.Parent = Workspace
    end
end)

disasterMenu:Button("Shake Screen", "Shake the camera violently.", function()
    local camera = Workspace.CurrentCamera
    local originalCFrame = camera.CFrame
    for i = 1, 30 do
        camera.CFrame = originalCFrame * CFrame.new(
            math.random(-2, 2),
            math.random(-2, 2),
            math.random(-2, 2)
        )
        task.wait(0.05)
    end
    camera.CFrame = originalCFrame
end)

disasterMenu:Button("Blackout", "Turn off all lights temporarily.", function()
    Lighting.Brightness = 0
    Lighting.Ambient = Color3.fromRGB(0, 0, 0)
    task.wait(5)
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(127, 127, 127)
end)

teleportMenu:Submenu("Waypoints", "Teleport to preset locations.", waypointMenu)
teleportMenu:Submenu("Saved Locations", "Manage your saved spots.", savedLocMenu)
teleportMenu:Submenu("Teleport to Player", "Teleport to another player.", tpPlayerMenu)

teleportMenu:Button("Teleport to Waypoint", "Teleport to your waypoint marker.", function() end)

waypointMenu:Button("Spawn Point", "Teleport to spawn.", function()
    local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
    if spawnLocation then
        teleportTo(spawnLocation.Position + Vector3.new(0, 5, 0))
    end
end)

waypointMenu:Button("Map Center", "Teleport to map center.", function()
    teleportTo(Vector3.new(0, 100, 0))
end)

waypointMenu:Button("Highest Point", "Teleport to the sky.", function()
    local rootPart = getRootPart()
    if rootPart then
        teleportTo(rootPart.Position + Vector3.new(0, 500, 0))
    end
end)

savedLocMenu:Button("Save Current Position", "Save your current location.", function()
    local name = "Location_" .. #Settings.SavedLocations + 1
    saveLocation(name)
end)

savedLocMenu:Button("Clear All Saved", "Remove all saved locations.", function()
    Settings.SavedLocations = {}
end)

local function refreshPlayerList()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            tpPlayerMenu:Button(player.Name, "Teleport to " .. player.Name, function()
                teleportToPlayer(player.Name)
            end)
        end
    end
end

tpPlayerMenu:Button("Refresh Player List", "Update the player list.", function()
    refreshPlayerList()
end)

refreshPlayerList()

settingsMenu:Submenu("Keybinds / Controls", "View and modify keybinds.", keybindMenu)
settingsMenu:Submenu("Hotkey Manager", "Manage quick access hotkeys.", hotkeyMenu)
settingsMenu:Submenu("Menu Theme / UI", "Customize the menu appearance.", themeMenu)

settingsMenu:Button("Save Settings", "Save all current settings.", function() end)

settingsMenu:Button("Load Settings", "Load previously saved settings.", function() end)

settingsMenu:Button("Reset to Default", "Reset all settings to default.", function()
    Settings.GodMode = false
    Settings.SuperJump = false
    Settings.FastWalk = false
    Settings.Invisible = false
    setGodMode(false)
    setSuperJump(false)
    setFastWalk(false)
    setInvisible(false)
end)

keybindMenu:Button("Toggle Menu: F4/Insert", "Opens or closes the menu.", function() end)
keybindMenu:Button("Navigate: Arrow Keys", "Navigate up and down.", function() end)
keybindMenu:Button("Select: Enter/Numpad 5", "Select an option.", function() end)
keybindMenu:Button("Back: Backspace/Numpad 0", "Go back or close.", function() end)
keybindMenu:Button("Change Value: Left/Right", "Adjust sliders and lists.", function() end)

hotkeyMenu:Button("God Mode Hotkey: G", "Toggle God Mode quickly.", function() end)
hotkeyMenu:Button("Super Jump Hotkey: J", "Toggle Super Jump quickly.", function() end)
hotkeyMenu:Button("Fast Walk Hotkey: F", "Toggle Fast Walk quickly.", function() end)
hotkeyMenu:Button("Invisible Hotkey: I", "Toggle Invisibility quickly.", function() end)

local ThemeOptions = { "Default", "Dark", "Light", "Cherry", "Ocean" }

themeMenu:List("Select Theme", "Choose your preferred theme.", ThemeOptions, 1, function(theme, index)
    Settings.CurrentTheme = theme
    ui:SetTheme(theme)
end)

themeMenu:Button("Test Notification", "Show a test notification.", function()
    ui:Notify({Title="Test", Content="This is a test notification!", Duration=3})
end)

themeMenu:Toggle("Show Descriptions", "Toggle option descriptions.", true, function(enabled) end)

themeMenu:Slider("Menu Opacity", "Adjust menu transparency.", 0, 100, 5, 100, function(opacity) end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Settings.Keybinds.GodMode then
        Settings.GodMode = not Settings.GodMode
        setGodMode(Settings.GodMode)
    elseif input.KeyCode == Settings.Keybinds.SuperJump then
        Settings.SuperJump = not Settings.SuperJump
        setSuperJump(Settings.SuperJump)
    elseif input.KeyCode == Settings.Keybinds.FastWalk then
        Settings.FastWalk = not Settings.FastWalk
        setFastWalk(Settings.FastWalk)
    elseif input.KeyCode == Settings.Keybinds.Invisible then
        Settings.Invisible = not Settings.Invisible
        setInvisible(Settings.Invisible)
    end
end)

GmmUI.PromptKey({
    Key = "1234",
    Title = "GMM UI - Enter Key (1234)"
}, function()
    ui:PushMenu(homeMenu)
    ui:Notify({Title="Welcome", Content="Successfully authenticated!", Duration=5})
end)
