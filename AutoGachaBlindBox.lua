--[[
    ╔══════════════════════════════════════════════════╗
    ║     AUTO GACHA BLIND BOX - Indo Voice v5         ║
    ║     Auto-Click Box + Speed Up Animation          ║
    ╚══════════════════════════════════════════════════╝
    
    CARA KERJA:
    - Panggil InvokeServer sama persis kayak game
    - Auto-klik box tengah begitu muncul (simulasi mouse click)
    - Speed up animasi gacha biar cepet
    - Gak hook/disable event apapun = AMAN
]]

-- ==================== CLEANUP OLD ====================
if _G.AutoGachaGUI then
    pcall(function() _G.AutoGachaGUI:Destroy() end)
end
if _G.AutoGachaRunning then
    _G.AutoGachaRunning = false
    task.wait(0.5)
end

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

-- ==================== REMOTE ====================
local BlindBoxRollFunction = ReplicatedStorage
    :WaitForChild("GameRemoteFunctions")
    :WaitForChild("BlindBoxRollFunction")

-- ==================== GACHA SEQUENCE MODULE ====================
local GachaSequence = require(
    ReplicatedFirst:WaitForChild("Source")
    :WaitForChild("BlindBox")
    :WaitForChild("GachaSequence")
)

-- ==================== AVAILABLE BOXES ====================
local AvailableBoxes = {}
pcall(function()
    local content = require(ReplicatedStorage:WaitForChild("Content"):WaitForChild("BlindBox"))
    for name, data in pairs(content) do
        if data.Reward then table.insert(AvailableBoxes, name) end
    end
end)
if #AvailableBoxes == 0 then
    AvailableBoxes = {"Dino2026","EidAdha2026","Spring2026","Christmas2025","Halloween2025","Ocean2025","Ramadhan2026","Valentine2026"}
end
table.sort(AvailableBoxes)

-- ==================== STATE ====================
local isAutoRolling = false
_G.AutoGachaRunning = false
local selectedBox = "Dino2026"
local rollMode = 10
local rollDelay = 1
local totalRolled = 0
local gachaSpeed = 8  -- animation speed multiplier (default game = 1)
local autoClickEnabled = true

-- ==================== AUTO-CLICK BOX SYSTEM ====================
-- The GachaSequence creates boxes in workspace.GachaScene
-- We need to auto-click the middle box when state u19==0 and u20==1
-- We do this by finding the Packs folder and simulating mouse.Button1Down

local autoClickLoop = nil

local function FindGachaScene()
    return workspace:FindFirstChild("GachaScene")
end

local function FindPacksInScene()
    local scene = FindGachaScene()
    if not scene then return nil end
    for _, child in ipairs(scene:GetChildren()) do
        if child:IsA("Model") then
            local packs = child:FindFirstChild("Packs")
            if packs then return packs end
        end
    end
    return nil
end

local function AutoClickMiddleBox()
    local packs = FindPacksInScene()
    if not packs then return false end
    
    local boxes = packs:GetChildren()
    if #boxes == 0 then return false end
    
    -- Find the middle box (typically named "5" in a 3x3 grid, or pick center)
    local middleBox = nil
    
    -- Try to find box named "5" (center of 3x3 grid)
    middleBox = packs:FindFirstChild("5")
    
    -- If not found, try box named "2" (center of top row)
    if not middleBox then
        middleBox = packs:FindFirstChild("2")
    end
    
    -- Fallback to first available box
    if not middleBox then
        for _, box in ipairs(boxes) do
            if box:IsA("Model") and box.PrimaryPart then
                middleBox = box
                break
            end
        end
    end
    
    if not middleBox or not middleBox.PrimaryPart then return false end
    
    -- Get screen position of the box and move mouse there, then fire click
    local camera = workspace.CurrentCamera
    local screenPos, onScreen = camera:WorldToScreenPoint(middleBox.PrimaryPart.Position)
    
    if onScreen then
        -- Fire the mouse click at the box position
        -- This simulates what happens at line 898-908 in GachaSequence
        -- The game listens to Mouse.Button1Down and checks if u7 (hovered box) exists
        -- So we just need the mouse to be near the box and click
        
        -- Move mouse target to the box
        pcall(function()
            -- Use VirtualInputManager if available for clean click
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 1)
            task.wait(0.05)
            vim:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 1)
        end)
        
        return true
    end
    
    return false
end

local function StartAutoClickLoop()
    if autoClickLoop then return end
    autoClickLoop = true
    
    task.spawn(function()
        while autoClickLoop and _G.AutoGachaRunning do
            if autoClickEnabled then
                -- Speed up the gacha animation
                pcall(function()
                    GachaSequence:ChangeSpeed(gachaSpeed)
                end)
                
                -- Try to auto-click a box
                AutoClickMiddleBox()
            end
            task.wait(0.2) -- check every 200ms
        end
        autoClickLoop = nil
    end)
end

local function StopAutoClickLoop()
    autoClickLoop = nil
end

-- ==================== GUI ====================
local Gui = Instance.new("ScreenGui")
Gui.Name = "AutoGachaBlindBox"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui
_G.AutoGachaGUI = Gui

local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0, 310, 0, 490)
Main.Position = UDim2.new(0.5, -155, 0.5, -245)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local ms = Instance.new("UIStroke", Main)
ms.Color = Color3.fromRGB(100, 60, 200)
ms.Thickness = 2
ms.Transparency = 0.3

-- Accent
local ab = Instance.new("Frame", Main)
ab.Size = UDim2.new(1, 0, 0, 3)
ab.BorderSizePixel = 0
local g = Instance.new("UIGradient", ab)
g.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 50, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 180)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 200, 255))
}

-- Title
local TB = Instance.new("Frame", Main)
TB.Size = UDim2.new(1, 0, 0, 38)
TB.Position = UDim2.new(0, 0, 0, 3)
TB.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TB.BorderSizePixel = 0

local TL = Instance.new("TextLabel", TB)
TL.Size = UDim2.new(1, -75, 1, 0)
TL.Position = UDim2.new(0, 12, 0, 0)
TL.BackgroundTransparency = 1
TL.Text = "🎰 Auto Gacha v5"
TL.TextColor3 = Color3.fromRGB(255, 255, 255)
TL.TextSize = 14
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left

local MinB = Instance.new("TextButton", TB)
MinB.Size = UDim2.new(0, 28, 0, 28)
MinB.Position = UDim2.new(1, -62, 0, 5)
MinB.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
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
CF.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 200)
CF.CanvasSize = UDim2.new(0, 0, 0, 620)

local CL = Instance.new("UIListLayout", CF)
CL.SortOrder = Enum.SortOrder.LayoutOrder
CL.Padding = UDim.new(0, 7)

-- ==================== HELPERS ====================
local function Sec(name, parent, ord)
    local s = Instance.new("Frame", parent)
    s.Name = name; s.Size = UDim2.new(1, 0, 0, 0)
    s.AutomaticSize = Enum.AutomaticSize.Y
    s.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
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
    l.Text = t; l.TextColor3 = Color3.fromRGB(180, 180, 200)
    l.TextSize = 12; l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = o or 0
    return l
end

local function Btn(t, p, o, c)
    local b = Instance.new("TextButton", p)
    b.Size = UDim2.new(1, 0, 0, 32); b.BackgroundColor3 = c or Color3.fromRGB(80, 40, 180)
    b.Text = t; b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 13; b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0; b.LayoutOrder = o or 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

-- ==================== BOX SELECT ====================
local S1 = Sec("Box", CF, 1)
Lbl("📦 Pilih Blind Box", S1, 1)

local BG = Instance.new("Frame", S1)
BG.Size = UDim2.new(1, 0, 0, 0); BG.AutomaticSize = Enum.AutomaticSize.Y
BG.BackgroundTransparency = 1; BG.LayoutOrder = 2
local gl = Instance.new("UIGridLayout", BG)
gl.CellSize = UDim2.new(0.48, 0, 0, 26)
gl.CellPadding = UDim2.new(0.04, 0, 0, 4)

local bbs = {}
for i, n in ipairs(AvailableBoxes) do
    local sel = n == selectedBox
    local b = Instance.new("TextButton", BG)
    b.Name = n; b.BackgroundColor3 = sel and Color3.fromRGB(100, 50, 220) or Color3.fromRGB(40, 40, 55)
    b.Text = n; b.TextColor3 = sel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)
    b.TextSize = 9; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0; b.LayoutOrder = i
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    bbs[n] = b
    b.MouseButton1Click:Connect(function()
        selectedBox = n
        for k, v in pairs(bbs) do
            v.BackgroundColor3 = (k == n) and Color3.fromRGB(100, 50, 220) or Color3.fromRGB(40, 40, 55)
            v.TextColor3 = (k == n) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)
        end
    end)
end

-- ==================== SETTINGS ====================
local S2 = Sec("Set", CF, 2)
Lbl("⚙️ Pengaturan", S2, 1)

-- Roll Mode
local rmf = Instance.new("Frame", S2)
rmf.Size = UDim2.new(1, 0, 0, 28); rmf.BackgroundTransparency = 1; rmf.LayoutOrder = 2
Lbl("Roll:", rmf, 0, UDim2.new(0.35, 0, 1, 0))

local r1 = Instance.new("TextButton", rmf)
r1.Size = UDim2.new(0.3, 0, 0, 24); r1.Position = UDim2.new(0.37, 0, 0, 2)
r1.BackgroundColor3 = Color3.fromRGB(40, 40, 55); r1.Text = "1x"
r1.TextColor3 = Color3.fromRGB(150, 150, 170); r1.TextSize = 12
r1.Font = Enum.Font.GothamBold; r1.BorderSizePixel = 0
Instance.new("UICorner", r1).CornerRadius = UDim.new(0, 5)

local r10 = Instance.new("TextButton", rmf)
r10.Size = UDim2.new(0.3, 0, 0, 24); r10.Position = UDim2.new(0.69, 0, 0, 2)
r10.BackgroundColor3 = Color3.fromRGB(100, 50, 220); r10.Text = "10x"
r10.TextColor3 = Color3.fromRGB(255, 255, 255); r10.TextSize = 12
r10.Font = Enum.Font.GothamBold; r10.BorderSizePixel = 0
Instance.new("UICorner", r10).CornerRadius = UDim.new(0, 5)

local function SM(m)
    rollMode = m
    r1.BackgroundColor3 = m == 1 and Color3.fromRGB(100, 50, 220) or Color3.fromRGB(40, 40, 55)
    r1.TextColor3 = m == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)
    r10.BackgroundColor3 = m == 10 and Color3.fromRGB(100, 50, 220) or Color3.fromRGB(40, 40, 55)
    r10.TextColor3 = m == 10 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)
end
r1.MouseButton1Click:Connect(function() SM(1) end)
r10.MouseButton1Click:Connect(function() SM(10) end)

-- Gacha Speed
local spf = Instance.new("Frame", S2)
spf.Size = UDim2.new(1, 0, 0, 28); spf.BackgroundTransparency = 1; spf.LayoutOrder = 3
Lbl("⚡ Kecepatan Animasi:", spf, 0, UDim2.new(0.6, 0, 1, 0))

local spi = Instance.new("TextBox", spf)
spi.Size = UDim2.new(0.35, 0, 0, 24); spi.Position = UDim2.new(0.63, 0, 0, 2)
spi.BackgroundColor3 = Color3.fromRGB(40, 40, 55); spi.Text = "8"
spi.TextColor3 = Color3.fromRGB(255, 255, 255); spi.TextSize = 12
spi.Font = Enum.Font.GothamBold; spi.BorderSizePixel = 0; spi.ClearTextOnFocus = false
Instance.new("UICorner", spi).CornerRadius = UDim.new(0, 5)

spi.FocusLost:Connect(function()
    local v = tonumber(spi.Text)
    if v and v >= 1 and v <= 20 then gachaSpeed = v
    else spi.Text = tostring(gachaSpeed) end
end)

-- Auto Click
local acf = Instance.new("Frame", S2)
acf.Size = UDim2.new(1, 0, 0, 28); acf.BackgroundTransparency = 1; acf.LayoutOrder = 4
Lbl("🖱️ Auto Klik Box:", acf, 0, UDim2.new(0.6, 0, 1, 0))

local acb = Instance.new("TextButton", acf)
acb.Size = UDim2.new(0.35, 0, 0, 24); acb.Position = UDim2.new(0.63, 0, 0, 2)
acb.BackgroundColor3 = Color3.fromRGB(50, 180, 80); acb.Text = "ON"
acb.TextColor3 = Color3.fromRGB(255, 255, 255); acb.TextSize = 12
acb.Font = Enum.Font.GothamBold; acb.BorderSizePixel = 0
Instance.new("UICorner", acb).CornerRadius = UDim.new(0, 5)

acb.MouseButton1Click:Connect(function()
    autoClickEnabled = not autoClickEnabled
    acb.BackgroundColor3 = autoClickEnabled and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(180, 50, 50)
    acb.Text = autoClickEnabled and "ON" or "OFF"
end)

-- Delay
local df = Instance.new("Frame", S2)
df.Size = UDim2.new(1, 0, 0, 28); df.BackgroundTransparency = 1; df.LayoutOrder = 5
Lbl("⏱️ Delay antar roll:", df, 0, UDim2.new(0.6, 0, 1, 0))

local di = Instance.new("TextBox", df)
di.Size = UDim2.new(0.35, 0, 0, 24); di.Position = UDim2.new(0.63, 0, 0, 2)
di.BackgroundColor3 = Color3.fromRGB(40, 40, 55); di.Text = "1"
di.TextColor3 = Color3.fromRGB(255, 255, 255); di.TextSize = 12
di.Font = Enum.Font.GothamBold; di.BorderSizePixel = 0; di.ClearTextOnFocus = false
Instance.new("UICorner", di).CornerRadius = UDim.new(0, 5)

di.FocusLost:Connect(function()
    local v = tonumber(di.Text)
    if v and v >= 0.5 then rollDelay = v
    else di.Text = tostring(rollDelay) end
end)

-- ==================== CONTROLS ====================
local S3 = Sec("Ctrl", CF, 3)

local Status = Instance.new("TextLabel", S3)
Status.Size = UDim2.new(1, 0, 0, 22); Status.BackgroundTransparency = 1
Status.Text = "⏸️ Siap Roll"; Status.TextColor3 = Color3.fromRGB(150, 220, 150)
Status.TextSize = 13; Status.Font = Enum.Font.GothamBold
Status.TextXAlignment = Enum.TextXAlignment.Center; Status.LayoutOrder = 1

local Cnt = Instance.new("TextLabel", S3)
Cnt.Size = UDim2.new(1, 0, 0, 16); Cnt.BackgroundTransparency = 1
Cnt.Text = "Total: 0"; Cnt.TextColor3 = Color3.fromRGB(200, 180, 255)
Cnt.TextSize = 11; Cnt.Font = Enum.Font.Gotham
Cnt.TextXAlignment = Enum.TextXAlignment.Center; Cnt.LayoutOrder = 2

local GoBtn = Btn("▶  START AUTO GACHA", S3, 3, Color3.fromRGB(50, 180, 80))
local OneBtn = Btn("🎲  ROLL SEKALI", S3, 4, Color3.fromRGB(60, 100, 200))
local ForceEndBtn = Btn("⏭️  FORCE SKIP ANIMASI", S3, 5, Color3.fromRGB(180, 120, 30))

-- ==================== LOG ====================
local S4 = Sec("Log", CF, 4)
Lbl("📋 Log Hasil", S4, 1)

local LF = Instance.new("ScrollingFrame", S4)
LF.Size = UDim2.new(1, 0, 0, 100); LF.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
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
    l.Text = t; l.TextColor3 = c or Color3.fromRGB(180, 180, 200)
    l.TextSize = 10; l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
    l.AutomaticSize = Enum.AutomaticSize.Y; l.LayoutOrder = ln
    local ch = {}
    for _, x in ipairs(LF:GetChildren()) do
        if x:IsA("TextLabel") then table.insert(ch, x) end
    end
    if #ch > 40 then ch[1]:Destroy() end
    task.defer(function() LF.CanvasPosition = Vector2.new(0, LF.AbsoluteCanvasSize.Y) end)
end

-- ==================== ROLL FUNCTION ====================
local function WaitForGachaComplete(timeout)
    -- Wait until no more GachaScene children (animation done)
    local elapsed = 0
    while elapsed < timeout do
        local scene = FindGachaScene()
        if not scene or #scene:GetChildren() == 0 then
            return true
        end
        task.wait(0.1)
        elapsed = elapsed + 0.1
    end
    return false
end

local function DoRoll()
    local box = selectedBox
    local amt = rollMode
    
    Status.Text = "🎰 Rolling " .. amt .. "x " .. box .. "..."
    Status.TextColor3 = Color3.fromRGB(255, 200, 80)
    
    -- Speed up animation before rolling
    pcall(function() GachaSequence:ChangeSpeed(gachaSpeed) end)
    
    local ok, result, extra = pcall(function()
        if amt == 10 then
            return BlindBoxRollFunction:InvokeServer("Pet", box, 10)
        else
            return BlindBoxRollFunction:InvokeServer("Pet", box)
        end
    end)
    
    if ok then
        if result then
            totalRolled = totalRolled + amt
            Cnt.Text = "Total: " .. totalRolled
            Log("[" .. os.date("%H:%M:%S") .. "] ✅ " .. amt .. "x " .. box, Color3.fromRGB(100, 255, 100))
            
            -- Wait for all animations to complete
            -- The auto-click loop + speed will handle the boxes
            Status.Text = "🎬 Animasi berjalan (speed " .. gachaSpeed .. "x)..."
            Status.TextColor3 = Color3.fromRGB(180, 150, 255)
            
            -- Wait max 30 seconds for all animations to finish
            WaitForGachaComplete(30)
            
            return true
        else
            local msg = (typeof(extra) == "string" and extra) or "Gagal"
            Log("❌ " .. msg, Color3.fromRGB(255, 100, 100))
            local lo = msg:lower()
            if lo:find("enough") or lo:find("money") or lo:find("ropiah") 
               or lo:find("cukup") or lo:find("insufficient") or lo:find("afford") then
                Status.Text = "💸 RP habis!"
                Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                return false
            end
            return true
        end
    else
        Log("❌ " .. tostring(result), Color3.fromRGB(255, 100, 100))
        return true
    end
end

-- ==================== AUTO ROLL ====================
local function StartAuto()
    if isAutoRolling then return end
    isAutoRolling = true
    _G.AutoGachaRunning = true
    
    GoBtn.Text = "⏹  STOP"
    GoBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    Log("▶ Auto mulai: " .. selectedBox .. " " .. rollMode .. "x | speed " .. gachaSpeed .. "x", Color3.fromRGB(100, 200, 255))
    
    StartAutoClickLoop()
    
    task.spawn(function()
        while isAutoRolling and _G.AutoGachaRunning and Gui and Gui.Parent do
            if not DoRoll() then
                isAutoRolling = false
                break
            end
            if isAutoRolling then
                Status.Text = "⏳ Delay " .. rollDelay .. "s"
                Status.TextColor3 = Color3.fromRGB(150, 150, 200)
                task.wait(rollDelay)
            end
        end
        
        isAutoRolling = false
        _G.AutoGachaRunning = false
        StopAutoClickLoop()
        -- Restore normal speed
        pcall(function() GachaSequence:ChangeSpeed(1) end)
        GoBtn.Text = "▶  START AUTO GACHA"
        GoBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        Status.Text = "⏸️ Siap Roll"
        Status.TextColor3 = Color3.fromRGB(150, 220, 150)
        Log("⏹ Stop. Total: " .. totalRolled, Color3.fromRGB(255, 200, 100))
    end)
end

-- ==================== BUTTONS ====================
GoBtn.MouseButton1Click:Connect(function()
    if isAutoRolling then
        isAutoRolling = false
        _G.AutoGachaRunning = false
    else
        StartAuto()
    end
end)

OneBtn.MouseButton1Click:Connect(function()
    if isAutoRolling then return end
    task.spawn(function()
        _G.AutoGachaRunning = true
        StartAutoClickLoop()
        DoRoll()
        task.wait(1)
        _G.AutoGachaRunning = false
        StopAutoClickLoop()
        pcall(function() GachaSequence:ChangeSpeed(1) end)
        Status.Text = "⏸️ Siap Roll"
        Status.TextColor3 = Color3.fromRGB(150, 220, 150)
    end)
end)

ForceEndBtn.MouseButton1Click:Connect(function()
    pcall(function() GachaSequence:ForceEnd() end)
    Log("⏭️ Force skip animasi!", Color3.fromRGB(255, 200, 50))
end)

local cv = true
MinB.MouseButton1Click:Connect(function()
    cv = not cv; CF.Visible = cv
    Main.Size = cv and UDim2.new(0, 310, 0, 490) or UDim2.new(0, 310, 0, 44)
    MinB.Text = cv and "—" or "+"
end)

XB.MouseButton1Click:Connect(function()
    isAutoRolling = false; _G.AutoGachaRunning = false
    StopAutoClickLoop()
    pcall(function() GachaSequence:ChangeSpeed(1) end)
    Gui:Destroy(); _G.AutoGachaGUI = nil
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

UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightControl then Main.Visible = not Main.Visible end
end)

-- ==================== INIT ====================
Log("🎰 Auto Gacha v5 Loaded!", Color3.fromRGB(130, 50, 255))
Log("🖱️ Auto-klik box tengah: ON", Color3.fromRGB(50, 180, 80))
Log("⚡ Speed animasi: " .. gachaSpeed .. "x", Color3.fromRGB(255, 200, 100))
Log("📦 " .. table.concat(AvailableBoxes, ", "), Color3.fromRGB(150, 150, 170))
Log("💡 Right Ctrl = show/hide", Color3.fromRGB(150, 150, 170))
print("[Auto Gacha v5] Loaded - Auto click + Speed up")
