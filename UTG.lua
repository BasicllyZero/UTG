--[[
    UTG CLIENT v2
    Mobile-first Roblox client utility UI for experiences you own.

    Highlights
      • Small draggable floating launcher button (touch + mouse)
      • Responsive mobile / tablet / desktop layout
      • Animated open/close panel
      • Home / Player / Visuals / Settings tabs
      • Speed, sprint, jump and local noclip testing controls
      • Fullbright and FPS/ping monitor
      • Theme/accent presets and UI scale
      • Notification system
      • RightShift keyboard shortcut on desktop
      • Respawn-safe character handling
      • No external UI dependency or loadstring required

    This is intended for your own Roblox experience. It does not
    bypass security, modify other players, or evade anti-cheat systems.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("UTG")
if old then old:Destroy() end

--==================================================
-- Configuration / state
--==================================================
local Config = {
    WalkSpeed = 32,
    SprintSpeed = 50,
    JumpPower = 70,
    DefaultWalkSpeed = 16,
    DefaultJumpPower = 50,
    UIScale = 1,
    Accent = Color3.fromRGB(110, 90, 255),
    AccentName = "Violet",
    CompactMobile = true,
}

local State = {
    Open = true,
    Speed = false,
    Sprint = false,
    HighJump = false,
    Noclip = false,
    Fullbright = false,
    FPS = 0,
    Ping = 0,
}

local Character, Humanoid, RootPart
local function setupCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
    task.defer(function()
        if State.Speed or State.Sprint then
            Humanoid.WalkSpeed = State.Sprint and Config.SprintSpeed or Config.WalkSpeed
        else
            Humanoid.WalkSpeed = Config.DefaultWalkSpeed
        end
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = State.HighJump and Config.JumpPower or Config.DefaultJumpPower
    end)
end

setupCharacter(Player.Character or Player.CharacterAdded:Wait())

--==================================================
-- UI helpers
--==================================================
local function New(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local function Corner(parent, radius)
    return New("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end

local function Stroke(parent, color, transparency, thickness)
    return New("UIStroke", {
        Color = color or Color3.fromRGB(65, 65, 80),
        Transparency = transparency == nil and 0.35 or transparency,
        Thickness = thickness or 1,
    }, parent)
end

local function Tween(obj, time, properties)
    TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties):Play()
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

--==================================================
-- ScreenGui
--==================================================
local Gui = New("ScreenGui", {
    Name = "UTG",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 50,
}, PlayerGui)

local Scale = New("UIScale", {Scale = Config.UIScale}, Gui)

--==================================================
-- Notifications
--==================================================
local NoticeHolder = New("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -14, 1, -14),
    Size = UDim2.fromOffset(320, 260),
    BackgroundTransparency = 1,
}, Gui)
New("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 8),
}, NoticeHolder)

local function Notify(text, duration)
    duration = duration or 2.5
    local card = New("Frame", {
        Size = UDim2.fromOffset(300, 46),
        BackgroundColor3 = Color3.fromRGB(27, 27, 36),
        BackgroundTransparency = 0.04,
    }, NoticeHolder)
    Corner(card, 10)
    Stroke(card, Config.Accent, 0.45)

    local bar = New("Frame", {
        Size = UDim2.fromOffset(4, 46),
        BackgroundColor3 = Config.Accent,
        BorderSizePixel = 0,
    }, card)
    Corner(bar, 4)

    New("TextLabel", {
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1,
        Text = tostring(text),
        TextColor3 = Color3.fromRGB(240, 240, 245),
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    card.BackgroundTransparency = 1
    Tween(card, 0.18, {BackgroundTransparency = 0.04})
    task.delay(duration, function()
        if card.Parent then
            Tween(card, 0.18, {BackgroundTransparency = 1})
            task.wait(0.2)
            card:Destroy()
        end
    end)
end

--==================================================
-- Main window
--==================================================
local Main = New("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(520, 410),
    BackgroundColor3 = Color3.fromRGB(16, 16, 22),
    BorderSizePixel = 0,
}, Gui)
Corner(Main, 16)
Stroke(Main, Config.Accent, 0.25, 1)

local Shadow = New("ImageLabel", {
    Name = "Shadow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, 36, 1, 36),
    BackgroundTransparency = 1,
    Image = "rbxassetid://1316045217",
    ImageTransparency = 0.55,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(10, 10, 118, 118),
    ZIndex = -1,
}, Main)

local Top = New("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = Color3.fromRGB(22, 22, 30),
    BorderSizePixel = 0,
}, Main)
Corner(Top, 16)

local Title = New("TextLabel", {
    Size = UDim2.new(1, -120, 0, 28),
    Position = UDim2.fromOffset(18, 8),
    BackgroundTransparency = 1,
    Text = "UTG",
    TextColor3 = Color3.fromRGB(248, 248, 252),
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Top)

local Subtitle = New("TextLabel", {
    Size = UDim2.new(1, -120, 0, 18),
    Position = UDim2.fromOffset(18, 33),
    BackgroundTransparency = 1,
    Text = "CLIENT  •  MOBILE READY",
    TextColor3 = Color3.fromRGB(145, 145, 160),
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Top)

local CloseButton = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(38, 38),
    BackgroundColor3 = Color3.fromRGB(35, 35, 45),
    BorderSizePixel = 0,
    Text = "×",
    TextColor3 = Color3.fromRGB(225, 225, 232),
    TextSize = 22,
    Font = Enum.Font.GothamBold,
}, Top)
Corner(CloseButton, 10)

local Body = New("Frame", {
    Position = UDim2.fromOffset(12, 68),
    Size = UDim2.new(1, -24, 1, -80),
    BackgroundTransparency = 1,
}, Main)

--==================================================
-- Sidebar / tabs
--==================================================
local Sidebar = New("Frame", {
    Size = UDim2.fromOffset(116, 1),
    BackgroundTransparency = 1,
}, Body)
New("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Sidebar)

local Pages = New("Frame", {
    Position = UDim2.fromOffset(128, 0),
    Size = UDim2.new(1, -128, 1, 0),
    BackgroundTransparency = 1,
}, Body)

local TabButtons = {}
local PageObjects = {}
local ActiveTab

local function CreatePage(name)
    local page = New("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Config.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, Pages)
    New("UIPadding", {
        PaddingRight = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 8),
    }, page)
    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    PageObjects[name] = page
    return page
end

local function SelectTab(name)
    ActiveTab = name
    for tabName, btn in pairs(TabButtons) do
        btn.BackgroundColor3 = tabName == name and Config.Accent or Color3.fromRGB(27, 27, 36)
        btn.TextColor3 = tabName == name and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(175, 175, 188)
    end
    for pageName, page in pairs(PageObjects) do
        page.Visible = pageName == name
    end
end

local function AddTab(name, icon)
    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Color3.fromRGB(27, 27, 36),
        BorderSizePixel = 0,
        Text = icon .. "  " .. name,
        TextColor3 = Color3.fromRGB(175, 175, 188),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Sidebar)
    Corner(btn, 9)
    btn.Activated:Connect(function() SelectTab(name) end)
    TabButtons[name] = btn
    return CreatePage(name)
end

local Home = AddTab("Home", "⌂")
local PlayerPage = AddTab("Player", "●")
local Visuals = AddTab("Visuals", "◐")
local Settings = AddTab("Settings", "⚙")

--==================================================
-- Components
--==================================================
local function Section(parent, title, description)
    local box = New("Frame", {
        Size = UDim2.new(1, 0, 0, description and 64 or 42),
        BackgroundColor3 = Color3.fromRGB(22, 22, 30),
        BorderSizePixel = 0,
    }, parent)
    Corner(box, 10)
    Stroke(box, Color3.fromRGB(55, 55, 70), 0.6)
    New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.fromOffset(10, 7),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.fromRGB(235, 235, 242),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, box)
    if description then
        New("TextLabel", {
            Size = UDim2.new(1, -20, 0, 28),
            Position = UDim2.fromOffset(10, 30),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = Color3.fromRGB(145, 145, 160),
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, box)
    end
    return box
end

local function Action(parent, text, callback)
    local b = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(29, 29, 39),
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Color3.fromRGB(232, 232, 240),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    Corner(b, 9)
    Stroke(b, Color3.fromRGB(60, 60, 76), 0.7)
    New("UIPadding", {PaddingLeft = UDim.new(0, 12)}, b)
    b.Activated:Connect(callback)
    return b
end

local function Toggle(parent, label, initial, callback)
    local enabled = initial or false
    local b = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(29, 29, 39),
        BorderSizePixel = 0,
        Text = "",
    }, parent)
    Corner(b, 9)
    Stroke(b, Color3.fromRGB(60, 60, 76), 0.7)
    New("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Color3.fromRGB(232, 232, 240),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, b)
    local pill = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(42, 22),
        BackgroundColor3 = Color3.fromRGB(45, 45, 55),
        BorderSizePixel = 0,
    }, b)
    Corner(pill, 11)
    local knob = New("Frame", {
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.fromRGB(225, 225, 232),
        BorderSizePixel = 0,
    }, pill)
    Corner(knob, 8)

    local function Render()
        pill.BackgroundColor3 = enabled and Config.Accent or Color3.fromRGB(45, 45, 55)
        Tween(knob, 0.15, {Position = enabled and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)})
    end
    b.Activated:Connect(function()
        enabled = not enabled
        Render()
        callback(enabled)
    end)
    Render()
    return b
end

local function Slider(parent, label, min, max, default, callback)
    local value = default
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Color3.fromRGB(29, 29, 39),
        BorderSizePixel = 0,
    }, parent)
    Corner(holder, 9)
    Stroke(holder, Color3.fromRGB(60, 60, 76), 0.7)

    local text = New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.fromOffset(10, 5),
        BackgroundTransparency = 1,
        Text = label .. ": " .. tostring(value),
        TextColor3 = Color3.fromRGB(232, 232, 240),
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)

    local track = New("Frame", {
        Position = UDim2.new(0, 10, 0, 37),
        Size = UDim2.new(1, -20, 0, 6),
        BackgroundColor3 = Color3.fromRGB(47, 47, 58),
        BorderSizePixel = 0,
    }, holder)
    Corner(track, 4)
    local fill = New("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Config.Accent,
        BorderSizePixel = 0,
    }, track)
    Corner(fill, 4)

    local dragging = false
    local function setFromX(x)
        local ratio = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * ratio + 0.5)
        text.Text = label .. ": " .. tostring(value)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        callback(value)
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return holder
end

--==================================================
-- Home page
--==================================================
Section(Home, "Welcome to UTG", "A compact client utility built to feel good on both phone and desktop.")

local StatsCard = New("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = Color3.fromRGB(22, 22, 30),
    BorderSizePixel = 0,
}, Home)
Corner(StatsCard, 10)
Stroke(StatsCard, Config.Accent, 0.5)
local StatsText = New("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1,
    Text = "FPS  --   •   Ping  -- ms\nUTG ready",
    TextColor3 = Color3.fromRGB(200, 220, 255),
    TextSize = 12,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
}, StatsCard)

Section(Home, "Quick actions")
Action(Home, "☀  Fullbright", function()
    State.Fullbright = not State.Fullbright
    if State.Fullbright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
    Notify("Fullbright: " .. (State.Fullbright and "ON" or "OFF"))
end)
Action(Home, "↻  Reset character", function()
    if Humanoid then Humanoid.Health = 0 end
end)
Action(Home, "⌕  Toggle menu", function()
    State.Open = false
    Main.Visible = false
end)

--==================================================
-- Player page
--==================================================
Section(PlayerPage, "Movement", "These controls affect your local character in your own experience.")

Toggle(PlayerPage, "⚡ Speed boost", false, function(value)
    State.Speed = value
    if Humanoid then
        Humanoid.WalkSpeed = value and Config.WalkSpeed or Config.DefaultWalkSpeed
        if State.Sprint then Humanoid.WalkSpeed = Config.SprintSpeed end
    end
    Notify("Speed: " .. (value and "ON" or "OFF"))
end)

Slider(PlayerPage, "Speed", 16, 100, Config.WalkSpeed, function(value)
    Config.WalkSpeed = value
    if State.Speed and not State.Sprint and Humanoid then Humanoid.WalkSpeed = value end
end)

Toggle(PlayerPage, "🏃 Sprint", false, function(value)
    State.Sprint = value
    if Humanoid then
        if value then
            Humanoid.WalkSpeed = Config.SprintSpeed
        elseif State.Speed then
            Humanoid.WalkSpeed = Config.WalkSpeed
        else
            Humanoid.WalkSpeed = Config.DefaultWalkSpeed
        end
    end
    Notify("Sprint: " .. (value and "ON" or "OFF"))
end)

Slider(PlayerPage, "Sprint speed", 16, 120, Config.SprintSpeed, function(value)
    Config.SprintSpeed = value
    if State.Sprint and Humanoid then Humanoid.WalkSpeed = value end
end)

Toggle(PlayerPage, "🦘 High jump", false, function(value)
    State.HighJump = value
    if Humanoid then
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = value and Config.JumpPower or Config.DefaultJumpPower
    end
    Notify("High jump: " .. (value and "ON" or "OFF"))
end)

Slider(PlayerPage, "Jump power", 50, 150, Config.JumpPower, function(value)
    Config.JumpPower = value
    if State.HighJump and Humanoid then Humanoid.JumpPower = value end
end)

Toggle(PlayerPage, "👻 Noclip testing", false, function(value)
    State.Noclip = value
    Notify("Noclip: " .. (value and "ON" or "OFF"))
end)

--==================================================
-- Visuals page
--==================================================
Section(Visuals, "Display", "Local visual settings. Other players are never modified.")
Toggle(Visuals, "☀ Fullbright", State.Fullbright, function(value)
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
end)

Toggle(Visuals, "▣ FPS / ping monitor", true, function(value)
    StatsCard.Visible = value
end)

--==================================================
-- Settings page
--==================================================
Section(Settings, "Appearance", "Make UTG fit your screen and your style.")

local AccentPresets = {
    {Name = "Violet", Color = Color3.fromRGB(110, 90, 255)},
    {Name = "Blue", Color = Color3.fromRGB(70, 145, 255)},
    {Name = "Cyan", Color = Color3.fromRGB(55, 205, 205)},
    {Name = "Green", Color = Color3.fromRGB(75, 205, 125)},
    {Name = "Orange", Color = Color3.fromRGB(245, 145, 65)},
    {Name = "Pink", Color = Color3.fromRGB(240, 85, 170)},
}

local AccentIndex = 1
Action(Settings, "🎨 Accent: Violet", function()
    AccentIndex = AccentIndex % #AccentPresets + 1
    local preset = AccentPresets[AccentIndex]
    Config.Accent = preset.Color
    Config.AccentName = preset.Name
    Subtitle.Text = "CLIENT  •  " .. string.upper(preset.Name) .. " THEME"
    Notify("Accent: " .. preset.Name)
    Stroke(Main, Config.Accent, 0.25, 1)
    for _, obj in ipairs(Gui:GetDescendants()) do
        if obj:IsA("Frame") and obj.BackgroundColor3 == AccentPresets[(AccentIndex - 2) % #AccentPresets + 1].Color then
            obj.BackgroundColor3 = Config.Accent
        end
    end
    for _, btn in pairs(TabButtons) do
        if btn.BackgroundColor3 ~= Color3.fromRGB(27, 27, 36) then btn.BackgroundColor3 = Config.Accent end
    end
end)

Slider(Settings, "UI scale", 80, 120, 100, function(value)
    Config.UIScale = value / 100
    Scale.Scale = Config.UIScale
end)

Toggle(Settings, "📱 Compact mobile layout", Config.CompactMobile, function(value)
    Config.CompactMobile = value
    Notify("Compact mobile: " .. (value and "ON" or "OFF"))
end)

Action(Settings, "↺ Reset UI position", function()
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Notify("Window position reset")
end)

Action(Settings, "× Close UTG", function()
    Gui:Destroy()
end)

--==================================================
-- Floating launcher button
--==================================================
local Launcher = New("TextButton", {
    Name = "FloatingLauncher",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = IsMobile() and UDim2.new(1, -48, 0.5, 0) or UDim2.new(1, -42, 1, -110),
    Size = IsMobile() and UDim2.fromOffset(52, 52) or UDim2.fromOffset(46, 46),
    BackgroundColor3 = Config.Accent,
    BorderSizePixel = 0,
    Text = "U",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = IsMobile() and 21 or 18,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, Gui)
Corner(Launcher, IsMobile() and 16 or 14)
Stroke(Launcher, Color3.fromRGB(255, 255, 255), 0.75, 1)

local LauncherScale = New("UIScale", {Scale = 1}, Launcher)

local launcherDragging = false
local launcherMoved = false
local launcherStartInput
local launcherStartPos

local function BeginLauncher(input)
    launcherDragging = true
    launcherMoved = false
    launcherStartInput = input.Position
    launcherStartPos = Launcher.Position
end

local function UpdateLauncher(input)
    if not launcherDragging then return end
    local delta = input.Position - launcherStartInput
    if math.abs(delta.X) + math.abs(delta.Y) > 8 then launcherMoved = true end
    Launcher.Position = UDim2.new(
        launcherStartPos.X.Scale, launcherStartPos.X.Offset + delta.X,
        launcherStartPos.Y.Scale, launcherStartPos.Y.Offset + delta.Y
    )
end

Launcher.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        BeginLauncher(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if launcherDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateLauncher(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        launcherDragging = false
    end
end)

Launcher.Activated:Connect(function()
    if launcherMoved then return end
    State.Open = not State.Open
    Main.Visible = State.Open
    if State.Open then
        Main.Size = UDim2.fromOffset(500, 395)
        Tween(Main, 0.2, {Size = UDim2.fromOffset(520, 410)})
    end
end)

--==================================================
-- Main window dragging
--==================================================
local dragging = false
local dragStart
local startPos

Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

CloseButton.Activated:Connect(function()
    State.Open = false
    Main.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        State.Open = not State.Open
        Main.Visible = State.Open
    end
end)

--==================================================
-- Runtime loops
--==================================================
Player.CharacterAdded:Connect(function(char)
    setupCharacter(char)
end)

local frames, elapsed = 0, 0
RunService.RenderStepped:Connect(function(dt)
    frames += 1
    elapsed += dt
    if elapsed >= 0.5 then
        State.FPS = math.floor(frames / elapsed + 0.5)
        frames, elapsed = 0, 0
        local ping = 0
        pcall(function() ping = math.floor(Player:GetNetworkPing() * 1000 + 0.5) end)
        State.Ping = ping
        StatsText.Text = string.format("FPS  %d   •   Ping  %d ms\nUTG ready", State.FPS, State.Ping)
    end
end)

RunService.Stepped:Connect(function()
    if State.Noclip and Character then
        for _, obj in ipairs(Character:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.CanCollide = false
            end
        end
    end
end)

--==================================================
-- Responsive sizing
--==================================================
local function ApplyResponsive()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    if IsMobile() or viewport.X < 700 then
        Main.Size = UDim2.new(1, -24, 0, math.min(500, math.max(360, viewport.Y - 90)))
        Main.Position = UDim2.new(0.5, 0, 0.5, 0)
        Sidebar.Size = UDim2.fromOffset(92, 1)
        Pages.Position = UDim2.fromOffset(100, 0)
        Pages.Size = UDim2.new(1, -100, 1, 0)
        Title.TextSize = 18
    else
        Main.Size = UDim2.fromOffset(520, 410)
        Sidebar.Size = UDim2.fromOffset(116, 1)
        Pages.Position = UDim2.fromOffset(128, 0)
        Pages.Size = UDim2.new(1, -128, 1, 0)
        Title.TextSize = 20
    end
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(ApplyResponsive)
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyResponsive)
end
ApplyResponsive()
SelectTab("Home")
Notify("UTG v2 loaded • mobile launcher ready")
print("[UTG] v2 client loaded successfully.")
