-- UTG - Roblox Client Utility
-- Place as a LocalScript in StarterPlayerScripts or StarterGui.
-- Game-safe: local UI/utilities only; no exploit, bypass, or anti-cheat evasion.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("UTG")
if existing then existing:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "UTG"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function round(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
end

local function outline(parent)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(75, 75, 95)
    s.Transparency = 0.35
    s.Thickness = 1
    s.Parent = parent
end

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(430, 330)
main.Position = UDim2.new(0.5, -215, 0.5, -165)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Parent = gui
round(main, 12)
outline(main)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
header.BorderSizePixel = 0
header.Parent = main
round(header, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 1, 0)
title.Position = UDim2.fromOffset(15, 0)
title.BackgroundTransparency = 1
title.Text = "UTG  •  Roblox Client Utility"
title.TextColor3 = Color3.fromRGB(245, 245, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 1, -62)
content.Position = UDim2.fromOffset(12, 56)
content.BackgroundTransparency = 1
content.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

local stats = Instance.new("TextLabel")
stats.Size = UDim2.new(1, 0, 0, 40)
stats.BackgroundColor3 = Color3.fromRGB(26, 26, 35)
stats.BorderSizePixel = 0
stats.TextColor3 = Color3.fromRGB(190, 220, 255)
stats.Font = Enum.Font.Code
stats.TextSize = 13
stats.Text = "FPS: --   |   Ping: -- ms   |   --:--:--"
stats.Parent = content
round(stats, 8)

local function button(text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 40)
    b.BackgroundColor3 = Color3.fromRGB(31, 31, 41)
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Text = text
    b.TextColor3 = Color3.fromRGB(235, 235, 242)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 14
    b.Parent = content
    round(b, 8)
    outline(b)
    b.Activated:Connect(callback)
    return b
end

local fullbright = false
local saved = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
}

local function setFullbright(value)
    fullbright = value
    if value then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = saved.Brightness
        Lighting.ClockTime = saved.ClockTime
        Lighting.FogEnd = saved.FogEnd
        Lighting.GlobalShadows = saved.GlobalShadows
    end
end

local brightButton
brightButton = button("☀  Fullbright: OFF", function()
    setFullbright(not fullbright)
    brightButton.Text = "☀  Fullbright: " .. (fullbright and "ON" or "OFF")
end)

button("↻  Reset Character", function()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Health = 0 end
end)

local visible = true
local function toggleUI()
    visible = not visible
    main.Visible = visible
end

button("⌨  Toggle UI: RightShift", toggleUI)

-- Desktop + touch dragging.
local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragStart
    main.Position = UDim2.new(
        startPosition.X.Scale, startPosition.X.Offset + delta.X,
        startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
    )
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        toggleUI()
    end
end)

local frames, elapsed, fps = 0, 0, 0
RunService.RenderStepped:Connect(function(dt)
    frames += 1
    elapsed += dt
    if elapsed >= 0.5 then
        fps = math.floor(frames / elapsed + 0.5)
        frames = 0
        elapsed = 0
    end

    local ping = 0
    pcall(function()
        ping = math.floor(player:GetNetworkPing() * 1000 + 0.5)
    end)

    stats.Text = string.format("FPS: %d   |   Ping: %d ms   |   %s", fps, ping, os.date("%H:%M:%S"))
end)

player.CharacterAdded:Connect(function()
    task.wait(0.25)
    if fullbright then setFullbright(true) end
end)

print("[UTG] Client Utility loaded successfully.")
