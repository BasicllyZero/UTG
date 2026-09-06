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

local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()

local Config = {
    WalkSpeed = 32,
    JumpPower = 70,
    FOV = 70,
    ESPRange = 1000,
    AimFOV = 180,
    AimSpeed = 0.85,
    AimRange = 1000,
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
    NPCAim = false,
    AimCircle = true,
}

local Character
local Humanoid
local ESPObjects = {}
local Connections = {}
local AimConnection
local AimCircle

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
-- NPC-only Aim Assist
--==================================================
local function getNPCRoot()
    return workspace:FindFirstChild("NPC")
end

local function getAimPart(model)
    if not model or not model:IsA("Model") then return nil end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then return nil end

    return model:FindFirstChild("Head")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
end

local function getClosestNPCToCrosshair()
    local camera = workspace.CurrentCamera
    local npcRoot = getNPCRoot()
    local localRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if not camera or not npcRoot or not localRoot then return nil end

    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local bestPart
    local bestScreenDistance = Config.AimFOV

    for _, npc in ipairs(npcRoot:GetChildren()) do
        local part = getAimPart(npc)
        if part then
            local worldDistance = (localRoot.Position - part.Position).Magnitude
            if worldDistance <= Config.AimRange then
                local screenPoint, visible = camera:WorldToViewportPoint(part.Position)
                if visible and screenPoint.Z > 0 then
                    local screenDistance = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                    if screenDistance <= bestScreenDistance then
                        bestScreenDistance = screenDistance
                        bestPart = part
                    end
                end
            end
        end
    end

    return bestPart
end

local function createAimCircle()
    if AimCircle then AimCircle:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "UTG_NPCAimFOV"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = PlayerGui

    local circle = Instance.new("Frame")
    circle.Name = "FOV"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.fromScale(0.5, 0.5)
    circle.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Transparency = 0.15
    stroke.Parent = circle

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    AimCircle = gui
end

local function updateAimCircle()
    if not AimCircle then return end
    local circle = AimCircle:FindFirstChild("FOV")
    if circle then
        circle.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
        circle.Visible = State.NPCAim and State.AimCircle
    end
end

local function stopNPCAim()
    if AimConnection then
        RunService:UnbindFromRenderStep("UTG_NPCAimAssist")
        AimConnection = nil
    end
    updateAimCircle()
end

local function startNPCAim()
    stopNPCAim()
    if not State.NPCAim then return end

    createAimCircle()
    updateAimCircle()

    RunService:BindToRenderStep("UTG_NPCAimAssist", Enum.RenderPriority.Camera.Value + 1, function()
        if not State.NPCAim then return end

        local camera = workspace.CurrentCamera
        local target = getClosestNPCToCrosshair()
        if not camera or not target then return end

        local desired = CFrame.lookAt(camera.CFrame.Position, target.Position)
        camera.CFrame = camera.CFrame:Lerp(desired, math.clamp(Config.AimSpeed, 0.01, 1))
    end)

    AimConnection = true
end

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

local Home = TabSection:CreateTab({Name = "Home", Icon = icon("house", "Lucide"), Columns = 2}, "Home")
local PlayerTab = TabSection:CreateTab({Name = "Player", Icon = icon("user", "Lucide"), Columns = 2}, "Player")
local Visuals = TabSection:CreateTab({Name = "Visuals", Icon = icon("eye", "Lucide"), Columns = 2}, "Visuals")
local Troll = TabSection:CreateTab({Name = "Troll", Icon = icon("wand-sparkles", "Lucide"), Columns = 2}, "Troll")
local Settings = TabSection:CreateTab({Name = "Settings", Icon = icon("settings", "Lucide"), Columns = 2}, "Settings")

--==================================================
-- Home
--==================================================
local Welcome = Home:CreateGroupbox({Name = "UTG", Column = 1}, "Welcome")
Welcome:CreateParagraph({
    Name = "Ultimate Trolling GUI",
    Content = "A clean, mobile-friendly admin client for your experience. More troll modules are coming.",
}, "WelcomeText")

local Stats = Home:CreateGroupbox({Name = "Session", Column = 2}, "Stats")
local statsLabel = Stats:CreateParagraph({Name = "Status", Content = "Loading..."}, "StatsText")

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

Welcome:CreateButton({Name = "Refresh ESP", Icon = icon("refresh-cw", "Lucide"), Callback = refreshESP}, "RefreshESP")
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
    Name = "Walk Speed", Icon = icon("gauge", "Lucide"), Range = {16, 100}, Increment = 1,
    CurrentValue = Config.WalkSpeed,
    Callback = function(value)
        Config.WalkSpeed = value
        if State.Speed and Humanoid then Humanoid.WalkSpeed = value end
    end,
}, "WalkSpeed")
Movement:CreateToggle({
    Name = "Speed", CurrentValue = false,
    Callback = function(value)
        State.Speed = value
        if Humanoid then Humanoid.WalkSpeed = value and Config.WalkSpeed or 16 end
    end,
}, "Speed")
Movement:CreateSlider({
    Name = "Jump Power", Icon = icon("arrow-up", "Lucide"), Range = {50, 150}, Increment = 1,
    CurrentValue = Config.JumpPower,
    Callback = function(value)
        Config.JumpPower = value
        if State.HighJump and Humanoid then Humanoid.JumpPower = value end
    end,
}, "JumpPower")
Movement:CreateToggle({
    Name = "High Jump", CurrentValue = false,
    Callback = function(value)
        State.HighJump = value
        if Humanoid then Humanoid.JumpPower = value and Config.JumpPower or 50 end
    end,
}, "HighJump")
Movement:CreateToggle({Name = "Noclip", CurrentValue = false, Callback = function(value) State.Noclip = value end}, "Noclip")

local CharacterBox = PlayerTab:CreateGroupbox({Name = "Character", Column = 2}, "Character")
CharacterBox:CreateButton({
    Name = "Force Reapply Movement", Icon = icon("rotate-cw", "Lucide"),
    Callback = function() if Character then setupCharacter(Character) end end,
}, "Reapply")
CharacterBox:CreateToggle({
    Name = "Fullbright", CurrentValue = false,
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
-- Visuals / ESP + Aim
--==================================================
local ESPBox = Visuals:CreateGroupbox({Name = "Player ESP", Column = 1}, "ESP")
ESPBox:CreateToggle({Name = "Enable ESP", CurrentValue = false, Callback = function(value) State.ESP = value; refreshESP() end}, "ESP")
ESPBox:CreateToggle({Name = "Names", CurrentValue = true, Callback = function(value) State.Names = value; if State.ESP then refreshESP() end end}, "ESPNames")
ESPBox:CreateToggle({Name = "Health + Distance", CurrentValue = true, Callback = function(value) State.Health = value; if State.ESP then refreshESP() end end}, "ESPHealth")
ESPBox:CreateSlider({
    Name = "ESP Range", Icon = icon("radar", "Lucide"), Range = {50, 3000}, Increment = 25,
    CurrentValue = Config.ESPRange, Callback = function(value) Config.ESPRange = value end,
}, "ESPRange")

local AimBox = Visuals:CreateGroupbox({Name = "NPC Aim Assist", Column = 2}, "NPCAim")
AimBox:CreateParagraph({
    Name = "NPC-only targeting",
    Content = "Targets models inside Workspace.NPC and smoothly aims at their Head when they are inside the FOV circle.",
}, "AimInfo")
AimBox:CreateToggle({
    Name = "Enable NPC Aim", CurrentValue = false,
    Callback = function(value)
        State.NPCAim = value
        if value then startNPCAim() else stopNPCAim() end
    end,
}, "NPCAim")
AimBox:CreateToggle({
    Name = "Show FOV Circle", CurrentValue = true,
    Callback = function(value)
        State.AimCircle = value
        updateAimCircle()
    end,
}, "AimCircle")
AimBox:CreateSlider({
    Name = "FOV Radius", Icon = icon("circle-dot", "Lucide"), Range = {50, 500}, Increment = 5,
    CurrentValue = Config.AimFOV,
    Callback = function(value)
        Config.AimFOV = value
        updateAimCircle()
    end,
}, "AimFOV")
AimBox:CreateSlider({
    Name = "Aim Speed", Icon = icon("move-3d", "Lucide"), Range = {5, 100}, Increment = 5,
    CurrentValue = 85,
    Callback = function(value) Config.AimSpeed = value / 100 end,
}, "AimSpeed")
AimBox:CreateSlider({
    Name = "Max Distance", Icon = icon("scan", "Lucide"), Range = {100, 3000}, Increment = 50,
    CurrentValue = Config.AimRange,
    Callback = function(value) Config.AimRange = value end,
}, "AimRange")
AimBox:CreateButton({
    Name = "Aim Assist: Q Toggle",
    Icon = icon("keyboard", "Lucide"),
    Callback = function() notify("NPC Aim", State.NPCAim and "Currently ON — press Q to toggle." or "Currently OFF — press Q to toggle.") end,
}, "AimKeyInfo")

local Display = Visuals:CreateGroupbox({Name = "Display", Column = 1}, "Display")
Display:CreateSlider({
    Name = "Camera FOV", Icon = icon("scan", "Lucide"), Range = {50, 120}, Increment = 1,
    CurrentValue = Config.FOV,
    Callback = function(value)
        Config.FOV = value
        local camera = workspace.CurrentCamera
        if camera then camera.FieldOfView = value end
    end,
}, "FOV")
Display:CreateButton({
    Name = "Reset FOV", Icon = icon("undo-2", "Lucide"),
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
    Name = "Random Troll (coming soon)", Icon = icon("dices", "Lucide"),
    Callback = function() notify("UTG", "Random Troll is ready for the next command module.") end,
}, "RandomTroll")
TrollBox:CreateButton({
    Name = "Target Picker (coming soon)", Icon = icon("crosshair", "Lucide"),
    Callback = function() notify("UTG", "Target picker is reserved for the server command module.") end,
}, "TargetPicker")

--==================================================
-- Settings
--==================================================
local UIBox = Settings:CreateGroupbox({Name = "Interface", Column = 1}, "Interface")
UIBox:CreateButton({
    Name = "Unload UTG", Icon = icon("power", "Lucide"),
    Callback = function()
        for _, connection in ipairs(Connections) do pcall(function() connection:Disconnect() end) end
        for player in pairs(ESPObjects) do destroyESP(player) end
        stopNPCAim()
        if AimCircle then AimCircle:Destroy(); AimCircle = nil end
        pcall(function() Starlight:Destroy() end)
    end,
}, "Unload")
UIBox:CreateToggle({
    Name = "Mobile-friendly layout", CurrentValue = true,
    Callback = function(value) notify("UTG", value and "Mobile layout enabled" or "Mobile layout option disabled") end,
}, "MobileLayout")

local Info = Settings:CreateGroupbox({Name = "About", Column = 2}, "About")
Info:CreateParagraph({
    Name = "UTG",
    Content = "Ultimate Trolling GUI\nStarlight Interface Suite\nBuild: 0.3.0",
}, "Version")

--==================================================
-- Runtime
--==================================================
table.insert(Connections, RunService.Stepped:Connect(function()
    if not Character then return end
    if State.Noclip then
        for _, obj in ipairs(Character:GetDescendants()) do
            if obj:IsA("BasePart") then obj.CanCollide = false end
        end
    end
end))

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

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        State.NPCAim = not State.NPCAim
        if State.NPCAim then
            startNPCAim()
            notify("NPC Aim", "Enabled")
        else
            stopNPCAim()
            notify("NPC Aim", "Disabled")
        end
    end
end))

notify("UTG Loaded", "Starlight interface is ready.")
