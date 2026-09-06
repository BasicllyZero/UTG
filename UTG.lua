--[[
    UTG - Ultimate Trolling GUI
    Starlight Edition

    UI library: Nebula Softworks Starlight Interface Suite.
    UTG is designed for an experience you control and uses normal client-side
    Roblox APIs plus your game's own admin/trolling systems.

    Current build intentionally focuses on fun, non-destructive utilities.
    Owner/destructive controls are planned as a separate future build.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Starlight + Nebula icon loader.
local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()

local Config = {
    WalkSpeed = 32,
    JumpPower = 70,
    FOV = 70,
    ESPRange = 1000,
}

local State = {
    Speed = false,
    HighJump = false,
    Noclip = false,
    Fullbright = false,
    ESP = false,
    Names = true,
    Tracers = false,
    Health = true,
}

local Character
local Humanoid
local ESPObjects = {}
local Connections = {}

local function icon(name, set)
    local ok, result = pcall(function()
        return NebulaIcons:GetIcon(name, set or "Material")
    end)
    return ok and result or nil
end

local function notify(title, content)
    pcall(function()
        Starlight:Notification({
            Title = title,
            Icon = icon("sparkles", "Lucide"),
            Content = content,
        }, "UTG_" .. tostring(os.clock()))
    end)
end

local function setupCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")

    if State.Speed then
        Humanoid.WalkSpeed = Config.WalkSpeed
    else
        Humanoid.WalkSpeed = 16
    end

    Humanoid.UseJumpPower = true
    Humanoid.JumpPower = State.HighJump and Config.JumpPower or 50
end

setupCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(setupCharacter))

--==================================================
-- Player ESP
--==================================================
local function destroyESP(player)
    local entry = ESPObjects[player]
    if not entry then return end

    if entry.Highlight then entry.Highlight:Destroy() end
    if entry.Billboard then entry.Billboard:Destroy() end
    if entry.Tracer then entry.Tracer:Destroy() end
    ESPObjects[player] = nil
end

local function makeBillboard(player, character)
    if not State.Names and not State.Health then return nil end

    local head = character:FindFirstChild("Head")
    if not head then return nil end

    local gui = Instance.new("BillboardGui")
    gui.Name = "UTG_ESP_Name"
    gui.Adornee = head
    gui.Size = UDim2.fromOffset(180, 48)
    gui.StudsOffset = Vector3.new(0, 2.8, 0)
    gui.AlwaysOnTop = true
    gui.Parent = PlayerGui

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextStrokeTransparency = 0.35
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Parent = gui

    task.spawn(function()
        while gui.Parent and character.Parent and State.ESP do
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local root = Character and Character:FindFirstChild("HumanoidRootPart")
            local targetRoot = character:FindFirstChild("HumanoidRootPart")
            local distance = root and targetRoot and math.floor((root.Position - targetRoot.Position).Magnitude) or 0

            local text = State.Names and player.DisplayName or ""
            if State.Health and humanoid then
                text = text .. (text ~= "" and "\n" or "") .. string.format("HP %d  •  %dm", humanoid.Health, distance)
            end
            label.Text = text
            task.wait(0.15)
        end
        if gui then gui:Destroy() end
    end)

    return gui
end

local function createESP(player)
    if player == LocalPlayer or not State.ESP then return end
    destroyESP(player)

    local character = player.Character
    if not character then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "UTG_ESP_Highlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(108, 86, 235)
    highlight.FillTransparency = 0.78
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.OutlineTransparency = 0.15
    highlight.Adornee = character
    highlight.Parent = character

    ESPObjects[player] = {
        Highlight = highlight,
        Billboard = makeBillboard(player, character),
    }
end

local function refreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if State.ESP then
                createESP(player)
            else
                destroyESP(player)
            end
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        table.insert(Connections, player.CharacterAdded:Connect(function()
            task.wait(0.4)
            if State.ESP then createESP(player) end
        end))
    end
end

table.insert(Connections, Players.PlayerAdded:Connect(function(player)
    table.insert(Connections, player.CharacterAdded:Connect(function()
        task.wait(0.4)
        if State.ESP then createESP(player) end
    end))
end))

table.insert(Connections, Players.PlayerRemoving:Connect(destroyESP))

--==================================================
-- Starlight Window
--==================================================
local Window = Starlight:CreateWindow({
    Name = "UTG",
    Subtitle = "Ultimate Trolling GUI",
    Icon = 0,
    LoadingSettings = {
        Title = "UTG",
        Subtitle = "Ultimate Trolling GUI",
    },
    FileSettings = {
        ConfigFolder = "UTG",
    },
})

local TabSection = Window:CreateTabSection("UTG")

local Home = TabSection:CreateTab({
    Name = "Home",
    Icon = icon("house", "Lucide"),
    Columns = 2,
}, "Home")

local PlayerTab = TabSection:CreateTab({
    Name = "Player",
    Icon = icon("user", "Lucide"),
    Columns = 2,
}, "Player")

local Visuals = TabSection:CreateTab({
    Name = "Visuals",
    Icon = icon("eye", "Lucide"),
    Columns = 2,
}, "Visuals")

local Troll = TabSection:CreateTab({
    Name = "Troll",
    Icon = icon("wand-sparkles", "Lucide"),
    Columns = 2,
}, "Troll")

local Settings = TabSection:CreateTab({
    Name = "Settings",
    Icon = icon("settings", "Lucide"),
    Columns = 2,
}, "Settings")

--==================================================
-- Home
--==================================================
local Welcome = Home:CreateGroupbox({Name = "UTG", Column = 1}, "Welcome")
Welcome:CreateParagraph({
    Name = "Ultimate Trolling GUI",
    Content = "A clean, mobile-friendly admin client for your experience. More troll modules are coming.",
}, "WelcomeText")

local Stats = Home:CreateGroupbox({Name = "Session", Column = 2}, "Stats")
local statsLabel = Stats:CreateParagraph({
    Name = "Status",
    Content = "Loading...",
}, "StatsText")

local function updateStats()
    local fps = math.floor(1 / math.max(RunService.RenderStepped:Wait(), 1 / 240))
    local ping = 0
    pcall(function()
        ping = math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5)
    end)
    pcall(function()
        statsLabel:SetContent(string.format("FPS: %d\nPing: %d ms\nPlayers: %d", fps, ping, #Players:GetPlayers()))
    end)
end

task.spawn(function()
    while Window do
        task.wait(1)
        updateStats()
    end
end)

Welcome:CreateButton({
    Name = "Refresh ESP",
    Icon = icon("refresh-cw", "Lucide"),
    Callback = refreshESP,
}, "RefreshESP")

Welcome:CreateButton({
    Name = "Reset Character",
    Icon = icon("rotate-ccw", "Lucide"),
    Callback = function()
        if Humanoid then Humanoid.Health = 0 end
    end,
}, "ResetCharacter")

--==================================================
-- Player
--==================================================
local Movement = PlayerTab:CreateGroupbox({Name = "Movement", Column = 1}, "Movement")
Movement:CreateSlider({
    Name = "Walk Speed",
    Icon = icon("gauge", "Lucide"),
    Range = {16, 100},
    Increment = 1,
    CurrentValue = Config.WalkSpeed,
    Callback = function(value)
        Config.WalkSpeed = value
        if State.Speed and Humanoid then Humanoid.WalkSpeed = value end
    end,
}, "WalkSpeed")

Movement:CreateToggle({
    Name = "Speed",
    CurrentValue = false,
    Callback = function(value)
        State.Speed = value
        if Humanoid then Humanoid.WalkSpeed = value and Config.WalkSpeed or 16 end
    end,
}, "Speed")

Movement:CreateSlider({
    Name = "Jump Power",
    Icon = icon("arrow-up", "Lucide"),
    Range = {50, 150},
    Increment = 1,
    CurrentValue = Config.JumpPower,
    Callback = function(value)
        Config.JumpPower = value
        if State.HighJump and Humanoid then Humanoid.JumpPower = value end
    end,
}, "JumpPower")

Movement:CreateToggle({
    Name = "High Jump",
    CurrentValue = false,
    Callback = function(value)
        State.HighJump = value
        if Humanoid then Humanoid.JumpPower = value and Config.JumpPower or 50 end
    end,
}, "HighJump")

Movement:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(value)
        State.Noclip = value
    end,
}, "Noclip")

local CharacterBox = PlayerTab:CreateGroupbox({Name = "Character", Column = 2}, "Character")
CharacterBox:CreateButton({
    Name = "Force Reapply Movement",
    Icon = icon("rotate-cw", "Lucide"),
    Callback = function()
        if Character then setupCharacter(Character) end
    end,
}, "Reapply")

CharacterBox:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(value)
        State.Fullbright = value
        if value then
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
        end
    end,
}, "Fullbright")

--==================================================
-- Visuals / ESP
--==================================================
local ESPBox = Visuals:CreateGroupbox({Name = "Player ESP", Column = 1}, "ESP")
ESPBox:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(value)
        State.ESP = value
        refreshESP()
    end,
}, "ESP")

ESPBox:CreateToggle({
    Name = "Names",
    CurrentValue = true,
    Callback = function(value)
        State.Names = value
        if State.ESP then refreshESP() end
    end,
}, "ESPNames")

ESPBox:CreateToggle({
    Name = "Health + Distance",
    CurrentValue = true,
    Callback = function(value)
        State.Health = value
        if State.ESP then refreshESP() end
    end,
}, "ESPHealth")

ESPBox:CreateSlider({
    Name = "ESP Range",
    Icon = icon("radar", "Lucide"),
    Range = {50, 3000},
    Increment = 25,
    CurrentValue = Config.ESPRange,
    Callback = function(value)
        Config.ESPRange = value
    end,
}, "ESPRange")

local Display = Visuals:CreateGroupbox({Name = "Display", Column = 2}, "Display")
Display:CreateSlider({
    Name = "Camera FOV",
    Icon = icon("scan", "Lucide"),
    Range = {50, 120},
    Increment = 1,
    CurrentValue = Config.FOV,
    Callback = function(value)
        Config.FOV = value
        local camera = workspace.CurrentCamera
        if camera then camera.FieldOfView = value end
    end,
}, "FOV")

Display:CreateButton({
    Name = "Reset FOV",
    Icon = icon("undo-2", "Lucide"),
    Callback = function()
        Config.FOV = 70
        if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 70 end
    end,
}, "ResetFOV")

--==================================================
-- Troll starter tab
--==================================================
local TrollBox = Troll:CreateGroupbox({Name = "Troll Toolkit", Column = 1}, "TrollTools")
TrollBox:CreateParagraph({
    Name = "Ready for commands",
    Content = "This tab is reserved for UTG's original admin/trolling commands. The next build can connect these controls to your game's server-side admin system.",
}, "TrollInfo")

TrollBox:CreateButton({
    Name = "Random Troll (coming soon)",
    Icon = icon("dices", "Lucide"),
    Callback = function()
        notify("UTG", "Random Troll is ready for the next command module.")
    end,
}, "RandomTroll")

TrollBox:CreateButton({
    Name = "Target Picker (coming soon)",
    Icon = icon("crosshair", "Lucide"),
    Callback = function()
        notify("UTG", "Target picker is reserved for the server command module.")
    end,
}, "TargetPicker")

--==================================================
-- Settings
--==================================================
local UIBox = Settings:CreateGroupbox({Name = "Interface", Column = 1}, "Interface")
UIBox:CreateButton({
    Name = "Unload UTG",
    Icon = icon("power", "Lucide"),
    Callback = function()
        for _, connection in ipairs(Connections) do
            pcall(function() connection:Disconnect() end)
        end
        for player in pairs(ESPObjects) do
            destroyESP(player)
        end
        pcall(function() Starlight:Destroy() end)
    end,
}, "Unload")

UIBox:CreateToggle({
    Name = "Mobile-friendly layout",
    CurrentValue = true,
    Callback = function(value)
        notify("UTG", value and "Mobile layout enabled" or "Mobile layout option disabled")
    end,
}, "MobileLayout")

local Info = Settings:CreateGroupbox({Name = "About", Column = 2}, "About")
Info:CreateParagraph({
    Name = "UTG",
    Content = "Ultimate Trolling GUI\nStarlight Interface Suite\nBuild: 0.2.0",
}, "Version")

--==================================================
-- Runtime
--==================================================
table.insert(Connections, RunService.Stepped:Connect(function()
    if not Character then return end
    if State.Noclip then
        for _, obj in ipairs(Character:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.CanCollide = false
            end
        end
    end
end))

-- Keep ESP distance meaningful by hiding entries beyond the selected range.
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not State.ESP or not Character then return end
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for player, entry in pairs(ESPObjects) do
        local target = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if target and entry.Highlight then
            entry.Highlight.Enabled = (root.Position - target.Position).Magnitude <= Config.ESPRange
        end
        if entry.Billboard then
            local head = player.Character and player.Character:FindFirstChild("Head")
            entry.Billboard.Enabled = head ~= nil and target ~= nil and (root.Position - target.Position).Magnitude <= Config.ESPRange
        end
    end
end))

notify("UTG Loaded", "Starlight interface is ready.")
