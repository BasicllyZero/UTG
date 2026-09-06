--[[
    UTG CLIENT - NeverLose Edition

    Put this LocalScript beside a ModuleScript named "NeverLose".
    Copy the official 4lpaca-pin/NeverLose source.luau into that
    ModuleScript. The upstream project explicitly documents requiring
    its library as a ModuleScript for Roblox games.

    UTG only wires the library to local utilities for an experience you own.
    No remote-event abuse, anti-cheat bypasses, or other-player manipulation.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- NeverLose is supplied as a sibling ModuleScript.
local NeverLose = require(script:WaitForChild("NeverLose"))

local NotifyAPI = NeverLose:CreateNotification()
local Logger = NeverLose:CreateLogger()

local Config = {
    WalkSpeed = 32,
    SprintSpeed = 50,
    JumpPower = 70,
    Accent = "Violet",
}

local State = {
    Speed = false,
    Sprint = false,
    HighJump = false,
    Noclip = false,
    Fullbright = false,
    FPS = 0,
    Ping = 0,
}

local Character, Humanoid
local function setupCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")

    if State.Sprint then
        Humanoid.WalkSpeed = Config.SprintSpeed
    elseif State.Speed then
        Humanoid.WalkSpeed = Config.WalkSpeed
    else
        Humanoid.WalkSpeed = 16
    end

    Humanoid.UseJumpPower = true
    Humanoid.JumpPower = State.HighJump and Config.JumpPower or 50
end

setupCharacter(Player.Character or Player.CharacterAdded:Wait())
Player.CharacterAdded:Connect(setupCharacter)

local function toast(message)
    pcall(function()
        Logger.new("bell", tostring(message), 3)
    end)
    pcall(function()
        NotifyAPI:Notify(tostring(message), 3)
    end)
    print("[UTG] " .. tostring(message))
end

--==================================================
-- Window
--==================================================
local Window = NeverLose:CreateWindow({
    Logo = NeverLose.GlobalLogo,
    Name = "UTG",
    Content = "Mobile Client",
    Size = NeverLose.Scales.Mobile or NeverLose.Scales.Default,
    ConfigFolder = "UTGConfigs",
    Enable3DRenderer = false,
    Keybind = "RightShift",
})

--==================================================
-- Mobile-friendly floating launcher
--==================================================
local LauncherGui = Instance.new("ScreenGui")
LauncherGui.Name = "UTG_Launcher"
LauncherGui.ResetOnSpawn = false
LauncherGui.IgnoreGuiInset = true
LauncherGui.DisplayOrder = 1000
LauncherGui.Parent = PlayerGui

local Launcher = Instance.new("TextButton")
Launcher.Name = "UTGButton"
Launcher.AnchorPoint = Vector2.new(0.5, 0.5)
Launcher.Position = UDim2.new(1, -46, 0.55, 0)
Launcher.Size = UDim2.fromOffset(52, 52)
Launcher.BackgroundColor3 = Color3.fromRGB(108, 86, 235)
Launcher.BorderSizePixel = 0
Launcher.Text = "U"
Launcher.TextColor3 = Color3.new(1, 1, 1)
Launcher.TextSize = 20
Launcher.Font = Enum.Font.GothamBold
Launcher.AutoButtonColor = true
Launcher.Parent = LauncherGui

local launcherCorner = Instance.new("UICorner")
launcherCorner.CornerRadius = UDim.new(0, 16)
launcherCorner.Parent = Launcher

local launcherStroke = Instance.new("UIStroke")
launcherStroke.Color = Color3.new(1, 1, 1)
launcherStroke.Transparency = 0.72
launcherStroke.Parent = Launcher

local dragging = false
local moved = false
local dragStart
local startPosition

Launcher.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        moved = false
        dragStart = input.Position
        startPosition = Launcher.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    local delta = input.Position - dragStart
    if math.abs(delta.X) + math.abs(delta.Y) > 8 then
        moved = true
    end

    Launcher.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

Launcher.Activated:Connect(function()
    if moved then return end
    Window:ToggleInterface()
end)

--==================================================
-- Watermark / quick status
--==================================================
local Watermark = Window:Watermark()
local FPSBlock = Watermark:AddBlock("chart-four-vertical-bars", "-- FPS")
local PingBlock = Watermark:AddBlock("chart-four-vertical-bars", "-- MS")
local ToggleBlock = Watermark:AddBlock("cube-vertexes", "UTG")
ToggleBlock:Input(function()
    Window:ToggleInterface()
end)

--==================================================
-- Home
--==================================================
Window:AddTabLabel("UTG")

local Home = Window:AddTab({
    Icon = "home",
    Name = "Home",
})

local Overview = Home:AddSection({Name = "OVERVIEW", Position = "left"})
local Quick = Home:AddSection({Name = "QUICK ACTIONS", Position = "right"})

Overview:AddLabel("UTG CLIENT", true)
Overview:AddLabel("NeverLose interface • mobile ready")
Overview:AddLabel("Use the floating U button to hide/show the menu.", true)

local status = Overview:AddLabel("Status")
status:AddToggle({
    Default = true,
    Callback = function(v)
        toast(v and "UTG is active" or "UTG utilities paused")
    end,
})

Quick:AddLabel("Fullbright"):AddToggle({
    Default = false,
    Flag = "fullbright",
    Callback = function(v)
        State.Fullbright = v
        if v then
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
        end
        toast("Fullbright: " .. (v and "ON" or "OFF"))
    end,
})

Quick:AddLabel("Reset Character"):AddButton({
    Callback = function()
        if Humanoid then Humanoid.Health = 0 end
        toast("Character reset")
    end,
})

--==================================================
-- Player
--==================================================
local PlayerTab = Window:AddTab({
    Icon = "person",
    Name = "Player",
})

local Movement = PlayerTab:AddSection({Name = "MOVEMENT", Position = "left"})
local Advanced = PlayerTab:AddSection({Name = "ADVANCED", Position = "right"})

Movement:AddLabel("Speed"):AddToggle({
    Default = false,
    Flag = "speed",
    Callback = function(v)
        State.Speed = v
        if Humanoid then
            Humanoid.WalkSpeed = State.Sprint and Config.SprintSpeed or (v and Config.WalkSpeed or 16)
        end
        toast("Speed: " .. (v and "ON" or "OFF"))
    end,
})

Movement:AddLabel("Speed Amount"):AddSlider({
    Min = 16,
    Max = 100,
    Default = Config.WalkSpeed,
    Rounding = 1,
    Flag = "speed_amount",
    Callback = function(v)
        Config.WalkSpeed = v
        if State.Speed and not State.Sprint and Humanoid then Humanoid.WalkSpeed = v end
    end,
})

Movement:AddLabel("Sprint"):AddToggle({
    Default = false,
    Flag = "sprint",
    Callback = function(v)
        State.Sprint = v
        if Humanoid then
            Humanoid.WalkSpeed = v and Config.SprintSpeed or (State.Speed and Config.WalkSpeed or 16)
        end
        toast("Sprint: " .. (v and "ON" or "OFF"))
    end,
})

Movement:AddLabel("Sprint Speed"):AddSlider({
    Min = 16,
    Max = 120,
    Default = Config.SprintSpeed,
    Rounding = 1,
    Flag = "sprint_amount",
    Callback = function(v)
        Config.SprintSpeed = v
        if State.Sprint and Humanoid then Humanoid.WalkSpeed = v end
    end,
})

Advanced:AddLabel("High Jump"):AddToggle({
    Default = false,
    Flag = "high_jump",
    Callback = function(v)
        State.HighJump = v
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = v and Config.JumpPower or 50
        end
        toast("High jump: " .. (v and "ON" or "OFF"))
    end,
})

Advanced:AddLabel("Jump Power"):AddSlider({
    Min = 50,
    Max = 150,
    Default = Config.JumpPower,
    Rounding = 1,
    Flag = "jump_power",
    Callback = function(v)
        Config.JumpPower = v
        if State.HighJump and Humanoid then Humanoid.JumpPower = v end
    end,
})

Advanced:AddLabel("Noclip Testing"):AddToggle({
    Default = false,
    Flag = "noclip",
    Callback = function(v)
        State.Noclip = v
        toast("Noclip testing: " .. (v and "ON" or "OFF"))
    end,
})

--==================================================
-- Visuals
--==================================================
local Visuals = Window:AddTab({
    Icon = "eye",
    Name = "Visuals",
})

local Display = Visuals:AddSection({Name = "DISPLAY", Position = "left"})
local Theme = Visuals:AddSection({Name = "THEME", Position = "right"})

Display:AddLabel("FPS / Ping Monitor"):AddToggle({
    Default = true,
    Flag = "monitor",
    Callback = function(v)
        toast("Monitor: " .. (v and "ON" or "OFF"))
    end,
})

Display:AddLabel("Menu Scale"):AddDropdown({
    Default = "Mobile",
    Values = {"Default", "Large", "Mobile", "Small"},
    Flag = "menu_scale",
    Callback = function(v)
        pcall(function() Window:SetSize(NeverLose.Scales[v]) end)
        toast("Menu scale: " .. tostring(v))
    end,
})

Theme:AddLabel("Accent"):AddDropdown({
    Default = "Violet",
    Values = {"Violet", "Blue", "Cyan", "Green", "Orange", "Pink"},
    Flag = "accent",
    Callback = function(v)
        Config.Accent = v
        toast("Accent selected: " .. tostring(v))
    end,
})

Theme:AddLabel("3D Menu"):AddToggle({
    Default = false,
    Flag = "3d",
    Callback = function(v)
        pcall(function() Window:Set3DRender(v) end)
    end,
})

--==================================================
-- Settings
--==================================================
Window.UserSettings:AddLabel("Menu Keybind"):AddKeybind({
    Default = "RightShift",
    Callback = function(v)
        Window.Keybind = v
        toast("Menu keybind changed")
    end,
})

Window.UserSettings:AddLabel("Menu Scale"):AddDropdown({
    Default = "Mobile",
    Values = {"Default", "Large", "Mobile", "Small"},
    Callback = function(v)
        pcall(function() Window:SetSize(NeverLose.Scales[v]) end)
    end,
})

Window.UserSettings:AddLabel("3D Menu"):AddToggle({
    Default = false,
    Callback = function(v)
        pcall(function() Window:Set3DRender(v) end)
    end,
})

--==================================================
-- Runtime stats / noclip
--==================================================
local frames = 0
local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
    frames += 1
    elapsed += dt
    if elapsed >= 0.5 then
        State.FPS = math.floor(frames / elapsed + 0.5)
        frames = 0
        elapsed = 0

        local ping = 0
        pcall(function()
            ping = math.floor(Player:GetNetworkPing() * 1000 + 0.5)
        end)
        State.Ping = ping

        pcall(function() FPSBlock:SetText(tostring(State.FPS) .. " FPS") end)
        pcall(function() PingBlock:SetText(tostring(State.Ping) .. " MS") end)
    end
end)

RunService.Stepped:Connect(function()
    if not State.Noclip or not Character then return end
    for _, obj in ipairs(Character:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = false
        end
    end
end)

Player.CharacterAdded:Connect(function(char)
    setupCharacter(char)
end)

toast("UTG loaded • NeverLose UI ready")
