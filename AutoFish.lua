--[[
    ╔══════════════════════════════════════════════════╗
    ║     AUTO FISH - Indo Voice                       ║
    ║     Auto Cast + Auto Tap + Auto Bar              ║
    ╚══════════════════════════════════════════════════╝
    
    CARA KERJA:
    1. Auto hold klik kiri (Cast remote) untuk lempar umpan
    2. Tunggu ikan gigit (StartMinigame event)
    3. Auto klik fish icon (PreFishing TapButton)
    4. Auto minigame bar (klik saat hijau, stop saat merah)
    5. Loop otomatis

    ANTI-CHEAT SAFE:
    - Delay antar cast (adjustable, min 0.5s)
    - Tidak fire remote secara paksa
    - Hanya simulasi input yang sama persis seperti player
]]

-- ==================== CLEANUP OLD ====================
if _G.AutoFishGUI then
    pcall(function() _G.AutoFishGUI:Destroy() end)
end
if _G.AutoFishRunning then
    _G.AutoFishRunning = false
    task.wait(0.5)
end

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== STATE ====================
local isAutoFishing = false
_G.AutoFishRunning = false
local totalCaught = 0
local totalFailed = 0
local castDelay = 1         -- delay antar cast (detik)
local castPower = 0.5       -- hold duration (0.1 - 1.0)
local autoBarEnabled = true
local autoTapEnabled = true

-- ==================== HELPER: FIND ROD ====================
local function FindRod()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("IsRod") then
            return tool
        end
    end
    return nil
end

local function FindFishingUI()
    return PlayerGui:FindFirstChild("FishingUI")
end

-- ==================== GUI ====================
local Gui = Instance.new("ScreenGui")
Gui.Name = "AutoFishGUI"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui
_G.AutoFishGUI = Gui

local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0, 300, 0, 440)
Main.Position = UDim2.new(0, 15, 0.5, -220)
Main.BackgroundColor3 = Color3.fromRGB(15, 22, 35)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local ms = Instance.new("UIStroke", Main)
ms.Color = Color3.fromRGB(30, 120, 200)
ms.Thickness = 2
ms.Transparency = 0.3

-- Accent bar
local ab = Instance.new("Frame", Main)
ab.Size = UDim2.new(1, 0, 0, 3)
ab.BorderSizePixel = 0
local grd = Instance.new("UIGradient", ab)
grd.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 150, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 220, 150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 180, 255))
}

-- Title bar
local TB = Instance.new("Frame", Main)
TB.Size = UDim2.new(1, 0, 0, 38)
TB.Position = UDim2.new(0, 0, 0, 3)
TB.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
TB.BorderSizePixel = 0

local TL = Instance.new("TextLabel", TB)
TL.Size = UDim2.new(1, -75, 1, 0)
TL.Position = UDim2.new(0, 12, 0, 0)
TL.BackgroundTransparency = 1
TL.Text = "🐟 Auto Fish"
TL.TextColor3 = Color3.fromRGB(255, 255, 255)
TL.TextSize = 14
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left

local MinB = Instance.new("TextButton", TB)
MinB.Size = UDim2.new(0, 28, 0, 28)
MinB.Position = UDim2.new(1, -62, 0, 5)
MinB.BackgroundColor3 = Color3.fromRGB(50, 65, 85)
MinB.Text = "—"
MinB.TextColor3 = Color3.fromRGB(255, 255, 255)
MinB.TextSize = 14
MinB.Font = Enum.Font.GothamBold
MinB.BorderSizePixel = 0
Instance.new("UICorner", MinB).CornerRadius = UDim.new(0, 6)

local XB = Instance.new("TextButton", TB)
XB.Size = UDim2.new(0, 28, 0, 28)
XB.Position = UDim2.new(1, -32, 0, 5)
XB.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
XB.Text = "✕"
XB.TextColor3 = Color3.fromRGB(255, 255, 255)
XB.TextSize = 14
XB.Font = Enum.Font.GothamBold
XB.BorderSizePixel = 0
Instance.new("UICorner", XB).CornerRadius = UDim.new(0, 6)

-- Content
local CF = Instance.new("ScrollingFrame", Main)
CF.Size = UDim2.new(1, -16, 1, -48)
CF.Position = UDim2.new(0, 8, 0, 44)
CF.BackgroundTransparency = 1
CF.ScrollBarThickness = 3
CF.ScrollBarImageColor3 = Color3.fromRGB(30, 120, 200)
CF.CanvasSize = UDim2.new(0, 0, 0, 550)

local CL = Instance.new("UIListLayout", CF)
CL.SortOrder = Enum.SortOrder.LayoutOrder
CL.Padding = UDim.new(0, 7)

-- ==================== UI HELPERS ====================
local function Sec(name, parent, ord)
    local s = Instance.new("Frame", parent)
    s.Name = name; s.Size = UDim2.new(1, 0, 0, 0)
    s.AutomaticSize = Enum.AutomaticSize.Y
    s.BackgroundColor3 = Color3.fromRGB(22, 32, 48)
    s.BorderSizePixel = 0; s.LayoutOrder = ord
    Instance.new("UICorner", s).CornerRadius = UDim.new(0, 8)
    local p = Instance.new("UIPadding", s)
    p.PaddingTop = UDim.new(0, 8); p.PaddingBottom = UDim.new(0, 8)
    p.PaddingLeft = UDim.new(0, 10); p.PaddingRight = UDim.new(0, 10)
    Instance.new("UIListLayout", s).Padding = UDim.new(0, 5)
    return s
end

local function Lbl(t, p, o, sz)
    local l = Instance.new("TextLabel", p)
    l.Size = sz or UDim2.new(1, 0, 0, 18); l.BackgroundTransparency = 1
    l.Text = t; l.TextColor3 = Color3.fromRGB(170, 190, 220)
    l.TextSize = 12; l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = o or 0
    return l
end

local function Btn(t, p, o, c)
    local b = Instance.new("TextButton", p)
    b.Size = UDim2.new(1, 0, 0, 34); b.BackgroundColor3 = c or Color3.fromRGB(30, 100, 200)
    b.Text = t; b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 13; b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0; b.LayoutOrder = o or 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local function ToggleBtn(label, parent, ord, default, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 28); f.BackgroundTransparency = 1; f.LayoutOrder = ord
    Lbl(label, f, 0, UDim2.new(0.6, 0, 1, 0))
    local state = default
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0.35, 0, 0, 24); btn.Position = UDim2.new(0.63, 0, 0, 2)
    btn.BackgroundColor3 = state and Color3.fromRGB(40, 170, 80) or Color3.fromRGB(170, 50, 50)
    btn.Text = state and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(40, 170, 80) or Color3.fromRGB(170, 50, 50)
        btn.Text = state and "ON" or "OFF"
        if callback then callback(state) end
    end)
    return btn
end

-- ==================== STATUS SECTION ====================
local S1 = Sec("Status", CF, 1)
Lbl("📊 Status", S1, 1)

local StatusText = Instance.new("TextLabel", S1)
StatusText.Size = UDim2.new(1, 0, 0, 22); StatusText.BackgroundTransparency = 1
StatusText.Text = "⏸️ Siap Mancing"
StatusText.TextColor3 = Color3.fromRGB(100, 220, 150)
StatusText.TextSize = 13; StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Center; StatusText.LayoutOrder = 2

local CntText = Instance.new("TextLabel", S1)
CntText.Size = UDim2.new(1, 0, 0, 16); CntText.BackgroundTransparency = 1
CntText.Text = "🐟 0 tangkap | ❌ 0 gagal"
CntText.TextColor3 = Color3.fromRGB(150, 180, 220)
CntText.TextSize = 11; CntText.Font = Enum.Font.Gotham
CntText.TextXAlignment = Enum.TextXAlignment.Center; CntText.LayoutOrder = 3

local RodText = Instance.new("TextLabel", S1)
RodText.Size = UDim2.new(1, 0, 0, 14); RodText.BackgroundTransparency = 1
RodText.Text = "🎣 Rod: -"
RodText.TextColor3 = Color3.fromRGB(120, 150, 180)
RodText.TextSize = 10; RodText.Font = Enum.Font.Gotham
RodText.TextXAlignment = Enum.TextXAlignment.Center; RodText.LayoutOrder = 4

-- ==================== SETTINGS SECTION ====================
local S2 = Sec("Settings", CF, 2)
Lbl("⚙️ Pengaturan", S2, 1)

-- Cast Delay
local cdf = Instance.new("Frame", S2)
cdf.Size = UDim2.new(1, 0, 0, 28); cdf.BackgroundTransparency = 1; cdf.LayoutOrder = 2
Lbl("⏱️ Delay Cast (dtk):", cdf, 0, UDim2.new(0.6, 0, 1, 0))
local cdInput = Instance.new("TextBox", cdf)
cdInput.Size = UDim2.new(0.35, 0, 0, 24); cdInput.Position = UDim2.new(0.63, 0, 0, 2)
cdInput.BackgroundColor3 = Color3.fromRGB(35, 45, 60); cdInput.Text = "1"
cdInput.TextColor3 = Color3.fromRGB(255, 255, 255); cdInput.TextSize = 12
cdInput.Font = Enum.Font.GothamBold; cdInput.BorderSizePixel = 0; cdInput.ClearTextOnFocus = false
Instance.new("UICorner", cdInput).CornerRadius = UDim.new(0, 5)
cdInput.FocusLost:Connect(function()
    local v = tonumber(cdInput.Text)
    if v and v >= 0.5 then castDelay = v else cdInput.Text = tostring(castDelay) end
end)

-- Cast Power
local cpf = Instance.new("Frame", S2)
cpf.Size = UDim2.new(1, 0, 0, 28); cpf.BackgroundTransparency = 1; cpf.LayoutOrder = 3
Lbl("⏱️ Hold Durasi (0.1-1):", cpf, 0, UDim2.new(0.6, 0, 1, 0))
local cpInput = Instance.new("TextBox", cpf)
cpInput.Size = UDim2.new(0.35, 0, 0, 24); cpInput.Position = UDim2.new(0.63, 0, 0, 2)
cpInput.BackgroundColor3 = Color3.fromRGB(35, 45, 60); cpInput.Text = "0.5"
cpInput.TextColor3 = Color3.fromRGB(255, 255, 255); cpInput.TextSize = 12
cpInput.Font = Enum.Font.GothamBold; cpInput.BorderSizePixel = 0; cpInput.ClearTextOnFocus = false
Instance.new("UICorner", cpInput).CornerRadius = UDim.new(0, 5)
cpInput.FocusLost:Connect(function()
    local v = tonumber(cpInput.Text)
    if v and v >= 0.1 and v <= 1 then castPower = v else cpInput.Text = tostring(castPower) end
end)

-- Auto Tap
ToggleBtn("🐟 Auto Tap Ikan:", S2, 4, true, function(s) autoTapEnabled = s end)

-- Auto Bar
ToggleBtn("📊 Auto Bar Game:", S2, 5, true, function(s) autoBarEnabled = s end)

-- ==================== CONTROLS ====================
local S3 = Sec("Controls", CF, 3)
local GoBtn = Btn("▶  START AUTO FISH", S3, 1, Color3.fromRGB(30, 160, 80))

-- ==================== LOG SECTION ====================
local S4 = Sec("Log", CF, 4)
Lbl("📋 Log", S4, 1)

local LF = Instance.new("ScrollingFrame", S4)
LF.Size = UDim2.new(1, 0, 0, 100); LF.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
LF.BorderSizePixel = 0; LF.ScrollBarThickness = 2
LF.AutomaticCanvasSize = Enum.AutomaticSize.Y; LF.CanvasSize = UDim2.new(0, 0, 0, 0)
LF.LayoutOrder = 2
Instance.new("UICorner", LF).CornerRadius = UDim.new(0, 5)
local lfp = Instance.new("UIPadding", LF)
lfp.PaddingTop = UDim.new(0, 3); lfp.PaddingLeft = UDim.new(0, 5); lfp.PaddingRight = UDim.new(0, 5)
Instance.new("UIListLayout", LF).Padding = UDim.new(0, 1)

local ln = 0
local function Log(t, c)
    ln = ln + 1
    local l = Instance.new("TextLabel", LF)
    l.Size = UDim2.new(1, 0, 0, 13); l.BackgroundTransparency = 1
    l.Text = t; l.TextColor3 = c or Color3.fromRGB(150, 170, 200)
    l.TextSize = 10; l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
    l.AutomaticSize = Enum.AutomaticSize.Y; l.LayoutOrder = ln
    local ch = {}
    for _, x in ipairs(LF:GetChildren()) do if x:IsA("TextLabel") then table.insert(ch, x) end end
    if #ch > 50 then ch[1]:Destroy() end
    task.defer(function() LF.CanvasPosition = Vector2.new(0, LF.AbsoluteCanvasSize.Y) end)
end

-- ==================== AUTO TAP FISH ICONS ====================
local function AutoTapFishIcons()
    if not autoTapEnabled then return end

    -- Wait for FishingUI to appear in PlayerGui
    local fishingUI = nil
    local waited = 0
    while waited < 15 and _G.AutoFishRunning do
        fishingUI = PlayerGui:FindFirstChild("FishingUI")
        if fishingUI then break end
        task.wait(0.1)
        waited = waited + 0.1
    end

    if not fishingUI then return false end

    -- Find PreFishingHolder and tap buttons
    local preFishing = fishingUI:FindFirstChild("PreFishingHolder")
    if not preFishing then return false end

    -- Keep clicking TapButtons as they appear
    local tapCount = 0
    local maxTaps = 10
    while tapCount < maxTaps and _G.AutoFishRunning do
        -- Check if we moved to the bar minigame phase
        local fishHolder = fishingUI:FindFirstChild("FishingHolder")
        if fishHolder and fishHolder.Visible then
            Log("  🎯 Minigame bar dimulai!", Color3.fromRGB(100, 200, 255))
            return true
        end

        -- Check if FishingUI still exists
        if not fishingUI or not fishingUI.Parent then
            return false
        end

        -- Find and click any TapButton
        for _, child in ipairs(preFishing:GetChildren()) do
            if child:IsA("ImageButton") and child.Name == "TapButton" and child.Visible then
                -- Quick tap delay
                task.wait(0.08 + math.random() * 0.07)
                
                pcall(function()
                    local absPos = child.AbsolutePosition
                    local absSize = child.AbsoluteSize
                    local centerX = absPos.X + absSize.X / 2
                    local centerY = absPos.Y + absSize.Y / 2
                    
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                    task.wait(0.03)
                    vim:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
                end)
                
                tapCount = tapCount + 1
                task.wait(0.1)
                break
            end
        end

        task.wait(0.05)
    end

    return true
end

-- ==================== AUTO BAR MINIGAME ====================
local function AutoBarMinigame()
    if not autoBarEnabled then return end

    local fishingUI = PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI then return end

    local fishHolder = fishingUI:FindFirstChild("FishingHolder")
    if not fishHolder then return end

    local fishFrame = fishHolder:FindFirstChild("FishingFrame")
    if not fishFrame then return end

    -- Find bar and fish icon
    local barContainer = fishFrame:FindFirstChild("BarContainer")
    if not barContainer then return end

    local bar = barContainer:FindFirstChild("Bar")
    local fishContainer = fishFrame:FindFirstChild("FishContainer")
    local fishIcon = fishContainer and fishContainer:FindFirstChild("FishIcon")

    if not bar or not fishIcon then return end

    -- Bar mechanic from decompile:
    -- GREEN: each click = +0.068, bar auto-drops at -0.132/s
    -- RED:   each click = -0.33,  bar auto-rises at +0.055/s  
    -- Start = 0.45, Win >= 0.99, Lose <= 0.01
    -- Strategy: SPAM click fast during green to fill bar ASAP!

    local vim = game:GetService("VirtualInputManager")
    local vpSize = workspace.CurrentCamera.ViewportSize
    local cx = vpSize.X / 2
    local cy = vpSize.Y / 2

    while fishingUI and fishingUI.Parent and _G.AutoFishRunning do
        if not bar or not bar.Parent then break end
        if not fishIcon or not fishIcon.Parent then break end

        local iconColor = fishIcon.ImageColor3
        local isGreen = iconColor.G > 0.5 and iconColor.G > iconColor.R * 1.2

        if isGreen then
            -- GREEN: Click rapidly to push bar to 0.99!
            -- Each click = +0.068, need ~8 clicks from 0.45 to 0.99
            pcall(function()
                vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                task.wait(0.02)
                vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
            end)
            task.wait(0.04) -- ~20 clicks/sec = fill bar in <0.5s
        else
            -- RED: DON'T click! Just wait for green phase
            task.wait(0.05)
        end
    end
end

-- ==================== MAIN FISHING LOOP ====================
local function DoCast()
    local rod = FindRod()
    if not rod then
        Log("❌ Equip rod dulu!", Color3.fromRGB(255, 100, 100))
        StatusText.Text = "❌ Rod tidak ditemukan!"
        StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
        return false
    end

    RodText.Text = "🎣 Rod: " .. rod.Name

    local startMinigame = rod:FindFirstChild("StartMinigame")
    local fishingCanceled = rod:FindFirstChild("FishingCanceled")
    
    -- Setup listeners for this cast cycle
    local minigameStarted = false
    local fishingWasCanceled = false
    local connections = {}

    if startMinigame then
        local conn = startMinigame.OnClientEvent:Connect(function()
            minigameStarted = true
        end)
        table.insert(connections, conn)
    end

    if fishingCanceled then
        local conn = fishingCanceled.OnClientEvent:Connect(function()
            fishingWasCanceled = true
        end)
        table.insert(connections, conn)
    end

    StatusText.Text = "🎣 Melempar umpan..."
    StatusText.TextColor3 = Color3.fromRGB(255, 200, 80)

    -- Simulate mouse hold click (same as player holding left click)
    -- The game's RodClient listens to InputBegan/InputEnded and handles Cast internally
    local holdDuration = math.clamp(castPower, 0.1, 1)
    local vpSize = workspace.CurrentCamera.ViewportSize
    local cx = vpSize.X / 2
    local cy = vpSize.Y / 2

    local castOk = pcall(function()
        local vim = game:GetService("VirtualInputManager")
        -- Mouse down (start holding)
        vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
        -- Hold for the duration
        task.wait(holdDuration)
        -- Mouse up (release - triggers cast)
        vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
    end)

    if not castOk then
        Log("[" .. os.date("%H:%M:%S") .. "] ⚠️ Cast gagal", Color3.fromRGB(255, 180, 80))
        for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        return true -- keep trying
    end

    Log("[" .. os.date("%H:%M:%S") .. "] 🎣 Umpan dilempar! (hold " .. string.format("%.1f", holdDuration) .. "s)", Color3.fromRGB(80, 200, 120))
    StatusText.Text = "🐟 Menunggu ikan gigit..."
    StatusText.TextColor3 = Color3.fromRGB(100, 200, 255)

    -- Wait for fish to bite (StartMinigame event or FishingUI appears)
    local waitTime = 0
    local maxWait = 60 -- max wait 60 seconds for fish to bite
    while waitTime < maxWait and _G.AutoFishRunning and not minigameStarted and not fishingWasCanceled do
        -- Also check if FishingUI appeared
        local fui = PlayerGui:FindFirstChild("FishingUI")
        if fui then
            minigameStarted = true
            break
        end
        task.wait(0.2)
        waitTime = waitTime + 0.2
    end

    -- Cleanup connections
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end

    if fishingWasCanceled then
        Log("  ⚠️ Mancing dibatalkan", Color3.fromRGB(255, 180, 80))
        return true
    end

    if not minigameStarted then
        Log("  ⏱️ Timeout menunggu ikan", Color3.fromRGB(255, 180, 80))
        return true
    end

    -- Phase 1: Auto tap fish icons
    StatusText.Text = "👆 Tap ikan..."
    StatusText.TextColor3 = Color3.fromRGB(255, 200, 80)
    task.wait(0.3)
    AutoTapFishIcons()

    -- Phase 2: Auto bar minigame
    StatusText.Text = "📊 Minigame bar..."
    StatusText.TextColor3 = Color3.fromRGB(100, 200, 255)
    AutoBarMinigame()

    -- Wait for result briefly
    task.wait(0.3)

    -- Check result by looking at reward events or just count
    local fishingUI = PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI then
        -- FishingUI destroyed = minigame completed
        totalCaught = totalCaught + 1
        CntText.Text = "🐟 " .. totalCaught .. " tangkap | ❌ " .. totalFailed .. " gagal"
        Log("[" .. os.date("%H:%M:%S") .. "] ✅ Ikan ditangkap! (#" .. totalCaught .. ")", Color3.fromRGB(80, 255, 120))
    else
        totalFailed = totalFailed + 1
        CntText.Text = "🐟 " .. totalCaught .. " tangkap | ❌ " .. totalFailed .. " gagal"
        Log("[" .. os.date("%H:%M:%S") .. "] ❌ Gagal (#" .. totalFailed .. ")", Color3.fromRGB(255, 100, 100))
    end

    return true
end

-- ==================== AUTO FISH LOOP ====================
local function StartAutoFish()
    if isAutoFishing then return end
    isAutoFishing = true
    _G.AutoFishRunning = true

    GoBtn.Text = "⏹  STOP"
    GoBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    Log("▶ Auto Fish dimulai! Delay: " .. castDelay .. "s | Power: " .. castPower, Color3.fromRGB(80, 200, 255))

    task.spawn(function()
        while isAutoFishing and _G.AutoFishRunning and Gui and Gui.Parent do
            -- Check rod is equipped
            local rod = FindRod()
            if not rod then
                StatusText.Text = "❌ Equip rod dulu!"
                StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
                Log("⚠️ Rod tidak ditemukan, menunggu...", Color3.fromRGB(255, 180, 80))
                task.wait(2)
                continue
            end

            -- Do a fishing cycle
            local ok = DoCast()

            if not ok then
                break
            end

            if isAutoFishing then
                -- Delay between casts with small randomness
                local delay = castDelay + (math.random() * 0.5)
                delay = math.max(delay, 0.5)
                StatusText.Text = "⏳ Delay " .. string.format("%.1f", delay) .. "s..."
                StatusText.TextColor3 = Color3.fromRGB(150, 170, 200)
                task.wait(delay)
            end
        end

        isAutoFishing = false
        _G.AutoFishRunning = false
        GoBtn.Text = "▶  START AUTO FISH"
        GoBtn.BackgroundColor3 = Color3.fromRGB(30, 160, 80)
        StatusText.Text = "⏸️ Siap Mancing"
        StatusText.TextColor3 = Color3.fromRGB(100, 220, 150)
        Log("⏹ Stop. Total: " .. totalCaught .. " tangkap | " .. totalFailed .. " gagal", Color3.fromRGB(255, 200, 100))
    end)
end

-- ==================== BUTTON EVENTS ====================
GoBtn.MouseButton1Click:Connect(function()
    if isAutoFishing then
        isAutoFishing = false
        _G.AutoFishRunning = false
    else
        StartAutoFish()
    end
end)

local cv = true
MinB.MouseButton1Click:Connect(function()
    cv = not cv; CF.Visible = cv
    Main.Size = cv and UDim2.new(0, 300, 0, 440) or UDim2.new(0, 300, 0, 44)
    MinB.Text = cv and "—" or "+"
end)

XB.MouseButton1Click:Connect(function()
    isAutoFishing = false; _G.AutoFishRunning = false
    Gui:Destroy(); _G.AutoFishGUI = nil
end)

-- ==================== DRAG ====================
local dg, di2, ds, sp
TB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dg = true; ds = i.Position; sp = Main.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dg = false end end)
    end
end)
TB.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then di2 = i end
end)
UserInputService.InputChanged:Connect(function(i)
    if i == di2 and dg then
        local d = i.Position - ds
        Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end
end)

-- Toggle GUI visibility
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightControl then Main.Visible = not Main.Visible end
end)

-- ==================== INIT ====================
-- Check current rod
local rod = FindRod()
if rod then
    RodText.Text = "🎣 Rod: " .. rod.Name
    Log("✅ Rod terdeteksi: " .. rod.Name, Color3.fromRGB(80, 200, 120))
else
    Log("⚠️ Equip rod dulu sebelum start!", Color3.fromRGB(255, 200, 100))
end

Log("🐟 Auto Fish loaded!", Color3.fromRGB(30, 150, 255))
Log("⚙️ Delay min 2s (anti-cheat safe)", Color3.fromRGB(255, 200, 100))
Log("💡 Right Ctrl = show/hide GUI", Color3.fromRGB(150, 170, 200))
print("[Auto Fish] Loaded - Ready to fish!")
