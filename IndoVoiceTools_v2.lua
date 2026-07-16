--[[
    INDO VOICE MEGA TOOLS v2
    Built from decompiled game source analysis.
    
    FINDINGS FROM DECOMPILATION:
    - FishingUI lives inside Tool (rod), gets cloned to PlayerGui on StartMinigame
    - PreFishing: 2-4 random TapButton clones, need to fire .Activated
    - Minigame: bar starts at 0.45, green=click raises +0.068, red=click punishes -0.33
    - Bar auto-drains -0.132*dt when green, auto-fills +0.055*dt when red
    - Win at >=0.99, Fail at <=0.01
    - Cast uses RemoteFunction: Cast:InvokeServer(holdTime*2, spotId)
    - Result uses RemoteEvent: Catch:FireServer(true/false)
    - FishingBanData exists in profile → be careful with speed
    - Moving during minigame = auto-fail
    
    TABS: Fish | Gacha | Rewards | Extras
]]

-- ============ CLEANUP ============
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("MegaGuiV2") then CoreGui.MegaGuiV2:Destroy() end

-- ============ SERVICES ============
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local GRF = RS:WaitForChild("GameRemoteFunctions")

-- ============ INPUT HELPERS (VIM - proven working) ============
local function vimClick()
    VIM:SendMouseButtonEvent(400, 300, 0, true, game, 1)
    task.wait(0.01) -- Dipercepat jadi 0.01
    VIM:SendMouseButtonEvent(400, 300, 0, false, game, 1)
end

local function vimPress()
    VIM:SendMouseButtonEvent(400, 300, 0, true, game, 1)
end

local function vimRelease()
    VIM:SendMouseButtonEvent(400, 300, 0, false, game, 1)
end

-- ============ CONFIGURATION ============
local CONFIG = {
    -- Fish timing (in seconds) - tuned from decompiled bar math
    CastHold = {0.45, 0.6},        -- hold time for casting (sent as *2 to server)
    CastWaitBite = 35,             -- max wait for fish bite
    ClickInterval = {0.08, 0.16},  -- HUMAN SPEED (to avoid FishingBanData / Suspensions)
    PostCatchDelay = {2.0, 3.5},   -- delay after catch before next cast
    PostFailDelay = {1.0, 2.0},    -- delay after fail before next cast
    
    -- Safety: pause if other player is close
    SafetyEnabled = true,
    SafetyDist = 50,
    SafetyCooldown = 30,
    
    -- Auto Sell
    AutoSellEnabled = false,
    AutoSellInterval = 300,  -- seconds between auto-sells
    
    -- Bar target: aim for 1.0 to win the minigame
    BarTarget = 1.0,
    BarSafe = 0.60,  -- stop clicking above this during green
}

-- ============ STATE ============
local State = {
    autoFish = false, fishThread = nil, fishCount = 0, fishWins = 0,
    autoGachaAura = false, gachaAuraThread = nil, auraCount = 0,
    autoGachaBlind = false, gachaBlindThread = nil, blindCount = 0,
    autoGachaEgg = false, gachaEggThread = nil, eggCount = 0,
    autoReward = false, rewardThread = nil,
    autoSell = false, sellThread = nil,
    flyEnabled = false, flyThread = nil,
    noclip = false, noclipConn = nil,
    espEnabled = false, espFolder = nil,
    infJump = false,
    lastSellTime = 0,
    safetyPaused = false,
}

-- ============ THEME ============
local T = {
    Bg = Color3.fromRGB(18, 18, 28),
    Card = Color3.fromRGB(26, 26, 40),
    CardHover = Color3.fromRGB(34, 34, 52),
    Accent = Color3.fromRGB(0, 220, 160),
    AccentDim = Color3.fromRGB(0, 150, 110),
    Danger = Color3.fromRGB(255, 80, 80),
    Warning = Color3.fromRGB(255, 200, 50),
    Sell = Color3.fromRGB(255, 170, 0),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(140, 140, 160),
    On = Color3.fromRGB(0, 200, 130),
    Off = Color3.fromRGB(200, 60, 60),
    TabActive = Color3.fromRGB(0, 220, 160),
    TabInactive = Color3.fromRGB(40, 40, 55),
    Border = Color3.fromRGB(50, 50, 70),
}

-- ============ GUI FRAMEWORK ============
local gui = Instance.new("ScreenGui")
gui.Name = "MegaGuiV2"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 360, 0, 450)
main.Position = UDim2.new(0.5, -180, 0.5, -225)
main.BackgroundColor3 = T.Bg
main.BackgroundTransparency = 0.02
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = T.Accent
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3

-- Glow effect
local glow = Instance.new("ImageLabel")
glow.Size = UDim2.new(1, 40, 0, 40)
glow.Position = UDim2.new(0, -20, 0, -5)
glow.BackgroundTransparency = 1
glow.ImageColor3 = T.Accent
glow.ImageTransparency = 0.85
glow.Image = "rbxassetid://4996891970"
glow.ScaleType = Enum.ScaleType.Slice
glow.SliceCenter = Rect.new(20, 20, 280, 280)
glow.Parent = main
glow.ZIndex = 0

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -80, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "⚡ Indo Voice Tools v2"
titleLbl.TextColor3 = T.Accent
titleLbl.TextSize = 15
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

local minimized = false

local function makeTitleBtn(text, color, posX)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.Position = UDim2.new(1, posX, 0, 5)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = titleBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    return btn
end

local closeBtn = makeTitleBtn("✕", Color3.fromRGB(180, 40, 40), -33)
local minBtn = makeTitleBtn("─", Color3.fromRGB(60, 60, 90), -64)

-- Tab Bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 30)
tabBar.Position = UDim2.new(0, 0, 0, 38)
tabBar.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
tabBar.BorderSizePixel = 0
tabBar.Parent = main

-- Content
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, 0, 1, -68)
contentFrame.Position = UDim2.new(0, 0, 0, 68)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 3
contentFrame.ScrollBarImageColor3 = T.Accent
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 700)
contentFrame.Parent = main

local tabs = {"Fish", "Gacha", "Rewards", "Extras"}
local tabBtns = {}
local tabPages = {}
local activeTab = "Fish"

for i, tabName in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabs, 0, 1, 0)
    btn.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
    btn.BackgroundColor3 = T.TabInactive
    btn.BackgroundTransparency = 0.3
    btn.Text = tabName
    btn.TextColor3 = T.SubText
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    tabBtns[tabName] = btn

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 0, 900)
    page.BackgroundTransparency = 1
    page.Visible = (tabName == activeTab)
    page.Parent = contentFrame
    tabPages[tabName] = page
end

local function switchTab(name)
    activeTab = name
    for n, btn in pairs(tabBtns) do
        if n == name then
            btn.BackgroundColor3 = T.Accent
            btn.BackgroundTransparency = 0.7
            btn.TextColor3 = T.Text
        else
            btn.BackgroundColor3 = T.TabInactive
            btn.BackgroundTransparency = 0.3
            btn.TextColor3 = T.SubText
        end
        tabPages[n].Visible = (n == name)
    end
end

for name, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end
switchTab("Fish")

-- ============ UI HELPERS ============
local function makeToggle(parent, yPos, label, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -16, 0, 36)
    frame.Position = UDim2.new(0, 8, 0, yPos)
    frame.BackgroundColor3 = T.Card
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = T.Text
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 56, 0, 24)
    btn.Position = UDim2.new(1, -64, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    btn.Text = "OFF"
    btn.TextColor3 = T.Off
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        if on then
            btn.Text = "ON"
            btn.TextColor3 = T.On
            btn.BackgroundColor3 = Color3.fromRGB(20, 80, 50)
        else
            btn.Text = "OFF"
            btn.TextColor3 = T.Off
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        end
        callback(on)
    end)
    return btn, lbl
end

local function makeLabel(parent, yPos, text, color, bold)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 0, 18)
    lbl.Position = UDim2.new(0, 8, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or T.SubText
    lbl.TextSize = 11
    lbl.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = parent
    return lbl
end

local function makeButton(parent, yPos, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 32)
    btn.Position = UDim2.new(0, 8, 0, yPos)
    btn.BackgroundColor3 = color or T.Card
    btn.Text = text
    btn.TextColor3 = T.Text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ============ UTILITY FUNCTIONS ============
local function rng(min, max)
    return min + math.random() * (max - min)
end

local function safeWait(t)
    task.wait(t)
end

local function getNearbyPlayers(dist)
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    for _, p in Players:GetPlayers() do
        if p ~= player and p.Character then
            local otherHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if otherHRP and (hrp.Position - otherHRP.Position).Magnitude < dist then
                return true
            end
        end
    end
    return false
end

-- ============================================
-- TAB 1: AUTO FISH (Decompiled-Accurate)
-- ============================================
local fishPage = tabPages["Fish"]
local fishStatusLbl = makeLabel(fishPage, 4, "⏸ Status: OFF", T.Off, true)
local fishCountLbl = makeLabel(fishPage, 24, "🐟 Caught: 0 | Won: 0 | Failed: 0", T.SubText)
local fishLogLbl = makeLabel(fishPage, 44, "📋 Log: Idle", T.SubText)
local fishBarLbl = makeLabel(fishPage, 62, "📊 Bar: N/A", T.SubText)

--[[ 
    SMART MINIGAME PLAYER (VIM-based)
    Based on decompiled FishingUIController:
    - Bar value = Bar.Size (X or Y scale depending on orientation)
    - Green phase: each click adds +0.068
    - Red phase: each click SUBTRACTS -0.33 (massive penalty!)  
    - Auto-drain during green: -0.132*dt
    - Auto-fill during red: +0.055*dt
    - InfoLabel.Text contains "raise" for green, "Stop" for red
    - Uses VirtualInputManager (proven working via test)
]]
local function playMinigameSmart(fishingUI)
    local fishHolder = fishingUI:FindFirstChild("FishingHolder")
    if not fishHolder then return false end
    
    -- Wait for FishingHolder to become visible
    local waitStart = tick()
    while State.autoFish and (tick() - waitStart) < 10 do
        if fishHolder.Visible then break end
        task.wait(0.05)
    end
    if not fishHolder.Visible then return false end
    
    -- Find key elements
    local fishFrame = fishHolder:FindFirstChild("FishingFrame")
    if not fishFrame then return false end
    
    local barContainer = fishFrame:FindFirstChild("BarContainer")
    if not barContainer then return false end
    
    local bar = barContainer:FindFirstChild("Bar")
    if not bar then return false end
    
    local infoLabel = fishFrame:FindFirstChild("InfoLabel")
    local fishIcon = fishFrame:FindFirstChild("FishContainer")
    fishIcon = fishIcon and fishIcon:FindFirstChild("FishIcon")
    
    fishLogLbl.Text = "📋 Log: Playing minigame..."
    
    local startTime = tick()
    local clickCount = 0
    
    while State.autoFish and fishingUI.Parent and (tick() - startTime) < 35 do
        -- Check if minigame is still active (FishingHolder visible)
        if not fishHolder.Visible then
            break
        end
        
        -- Read bar value - from decompiled code: u16.Size = UDim2.fromScale(u33, 1)
        -- So bar value is stored in Size.X.Scale
        local barValue = bar.Size.X.Scale
        fishBarLbl.Text = string.format("📊 Bar: %.1f%%", barValue * 100)
        
        -- Determine phase from InfoLabel text
        -- Decompiled: green = "Click/tap to raise the bar!", red = "Stop click/tap"
        local isGreen = true  -- default to green (safer)
        if infoLabel and infoLabel:IsA("TextLabel") then
            local txt = infoLabel.Text:lower()
            if txt:find("stop") then
                isGreen = false
            elseif txt:find("raise") or txt:find("click") or txt:find("tap") then
                isGreen = true
            end
        end
        -- Backup: check bar background color
        if not infoLabel or infoLabel.Text == "" then
            local c = bar.BackgroundColor3
            isGreen = c.G > 0.5  -- green bar = green phase
        end
        
        if isGreen then
            -- GREEN PHASE: Click to raise bar
            -- Each click adds +0.068, bar drains -0.132*dt per frame
            if barValue < CONFIG.BarTarget then
                vimClick()  -- VirtualInputManager click!
                clickCount = clickCount + 1
                task.wait(rng(CONFIG.ClickInterval[1], CONFIG.ClickInterval[2]))
            else
                -- Bar is high enough, let it drain naturally
                task.wait(0.05)
            end
        else
            -- RED PHASE: DO NOT CLICK! Each click = -0.33 penalty
            -- Bar auto-fills at +0.055*dt, just wait
            task.wait(0.05)
        end
    end
    
    fishBarLbl.Text = "📊 Bar: Done"
    return true
end

local function autoPlayPreFishing(fishingUI)
    local preFishing = fishingUI:FindFirstChild("PreFishingHolder")
    if not preFishing or not preFishing.Visible then return end
    
    fishLogLbl.Text = "📋 Log: Tapping bubbles..."
    
    -- The game creates 2-4 TapButton clones that need .Activated fired
    for attempt = 1, 8 do
        if not State.autoFish then return end
        if not preFishing.Visible then break end
        
        local found = false
        for _, child in preFishing:GetChildren() do
            if child:IsA("ImageButton") and child.Visible and child.Name == "TapButton" then
                -- Fire the Activated signal (how the game detects taps)
                pcall(function() firesignal(child.Activated) end)
                found = true
                task.wait(rng(0.08, 0.18))
                break  -- only tap one per iteration, game spawns next after
            end
        end
        if not found then
            task.wait(0.1)
        end
    end
end

local function startAutoFish()
    State.autoFish = true
    State.fishCount = 0
    State.fishWins = 0
    local fishFails = 0
    fishStatusLbl.Text = "▶ Status: ACTIVE"
    fishStatusLbl.TextColor3 = T.On
    
    State.fishThread = task.spawn(function()
        while State.autoFish do
            -- Safety check
            if CONFIG.SafetyEnabled and getNearbyPlayers(CONFIG.SafetyDist) then
                if not State.safetyPaused then
                    State.safetyPaused = true
                    fishStatusLbl.Text = "⚠ SAFETY PAUSE"
                    fishStatusLbl.TextColor3 = T.Warning
                    fishLogLbl.Text = "📋 Log: Player nearby, pausing..."
                end
                task.wait(3)
                continue
            end
            if State.safetyPaused then
                State.safetyPaused = false
                fishLogLbl.Text = "📋 Log: Resuming after safety..."
                task.wait(rng(2, 5))
            end
            
            -- Check rod equipped
            local char = player.Character
            if not char then task.wait(1) continue end
            
            local rod = nil
            for _, t in char:GetChildren() do
                if t:IsA("Tool") and t:FindFirstChild("Cast") then
                    rod = t
                    break
                end
            end
            if not rod then
                fishLogLbl.Text = "📋 Log: ⚠ Equip fishing rod!"
                fishStatusLbl.Text = "⚠ No Rod"
                task.wait(2)
                continue
            end
            
            -- Auto Sell check (based on interval)
            if CONFIG.AutoSellEnabled and (tick() - State.lastSellTime) > CONFIG.AutoSellInterval then
                fishLogLbl.Text = "📋 Log: 💰 Auto-selling fish..."
                pcall(function()
                    GRF.SellAllFishFunction:InvokeServer()
                end)
                State.lastSellTime = tick()
                task.wait(1)
            end
            
            -- Step 1: CAST (using VirtualInputManager - proven working)
            fishLogLbl.Text = "📋 Log: 🎣 Casting..."
            fishStatusLbl.Text = "▶ Casting..."
            
            local holdTime = rng(CONFIG.CastHold[1], CONFIG.CastHold[2])
            vimPress()  -- Mouse down
            task.wait(holdTime)
            vimRelease()  -- Mouse up → triggers Cast:InvokeServer()
            
            -- Step 2: WAIT FOR BITE (FishingUI appears in PlayerGui)
            fishLogLbl.Text = "📋 Log: 🎣 Waiting for bite..."
            fishStatusLbl.Text = "▶ Waiting..."
            
            local fishingUI = nil
            local waitStart = tick()
            while State.autoFish and (tick() - waitStart) < CONFIG.CastWaitBite do
                fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
                if fishingUI then break end
                task.wait(0.08)
            end
            
            if not fishingUI then
                fishLogLbl.Text = "📋 Log: No bite, recasting..."
                task.wait(rng(0.5, 1.5))
                continue
            end
            
            if not State.autoFish then break end
            
            -- Step 3: PRE-FISHING (Tap bubbles)
            fishStatusLbl.Text = "▶ Pre-fishing..."
            task.wait(0.2)
            autoPlayPreFishing(fishingUI)
            
            if not State.autoFish then break end
            
            -- Step 4: PLAY MINIGAME (Bar)
            fishStatusLbl.Text = "▶ Minigame!"
            local won = playMinigameSmart(fishingUI)
            
            State.fishCount = State.fishCount + 1
            if won then
                State.fishWins = State.fishWins + 1
            else
                fishFails = fishFails + 1
            end
            
            fishCountLbl.Text = string.format("🐟 Caught: %d | Won: %d | Failed: %d", 
                State.fishCount, State.fishWins, fishFails)
            fishStatusLbl.Text = string.format("▶ Done #%d", State.fishCount)
            fishLogLbl.Text = string.format("📋 Log: %s #%d", won and "✅ Won" or "❌ Failed", State.fishCount)
            
            -- Post-catch delay (randomized to seem human)
            local delay = won and rng(CONFIG.PostCatchDelay[1], CONFIG.PostCatchDelay[2]) 
                              or rng(CONFIG.PostFailDelay[1], CONFIG.PostFailDelay[2])
            task.wait(delay)
        end
    end)
end

local function stopAutoFish()
    State.autoFish = false
    if State.fishThread then pcall(task.cancel, State.fishThread) State.fishThread = nil end
    fishStatusLbl.Text = "⏸ Status: OFF"
    fishStatusLbl.TextColor3 = T.Off
    fishLogLbl.Text = "📋 Log: Stopped"
    fishBarLbl.Text = "📊 Bar: N/A"
end

local fishY = 82
makeToggle(fishPage, fishY, "🎣 Auto Fish (Smart)", function(on)
    if on then startAutoFish() else stopAutoFish() end
end)

makeToggle(fishPage, fishY + 42, "💰 Auto Sell Fish", function(on)
    CONFIG.AutoSellEnabled = on
    if on then State.lastSellTime = tick() - CONFIG.AutoSellInterval + 10 end -- sell in 10s
end)

makeToggle(fishPage, fishY + 84, "🛡️ Safety (Pause Near Players)", function(on)
    CONFIG.SafetyEnabled = on
end)

makeButton(fishPage, fishY + 126, "💰 Sell All Fish Now", T.Sell, function()
    pcall(function()
        local result = GRF.SellAllFishFunction:InvokeServer()
        fishLogLbl.Text = "📋 Log: 💰 Sold! " .. tostring(result or "OK")
    end)
end)

-- Info labels
makeLabel(fishPage, fishY + 166, "── Decompiled Info ──", T.Accent, true)
makeLabel(fishPage, fishY + 184, "• Green: click +0.068 | auto-drain -0.132/s", T.SubText)
makeLabel(fishPage, fishY + 200, "• Red: click -0.33 PENALTY | auto-fill +0.055/s", T.SubText)
makeLabel(fishPage, fishY + 216, "• Win ≥0.99 | Fail ≤0.01 | Moving = fail", T.SubText)
makeLabel(fishPage, fishY + 232, "• FishingBanData exists → don't abuse speed", T.Warning)

-- ============================================
-- TAB 2: AUTO GACHA
-- ============================================
local gachaPage = tabPages["Gacha"]
makeLabel(gachaPage, 4, "── Gacha System (ForceEnd Bypass) ──", Color3.fromRGB(180, 140, 255), true)

local function findForceEnd(keyword)
    for _, v in getgc(true) do
        if type(v) == "table" then
            for key, val in pairs(v) do
                if type(key) == "string" and key == "ForceEnd" and type(val) == "function" then
                    local ok, env = pcall(getfenv, val)
                    if ok and env and env.script then
                        local sname = (env.script.Name or ""):lower()
                        if sname:find(keyword:lower()) then
                            return val, v
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function genericGachaStart(stateKey, threadKey, countKey, keyword, countLbl, prefix)
    State[stateKey] = true
    State[countKey] = 0
    State[threadKey] = task.spawn(function()
        while State[stateKey] do
            local prompt = nil
            for _, desc in workspace:GetDescendants() do
                if desc:IsA("ProximityPrompt") then
                    local txt = desc.ObjectText:lower()
                    local pname = desc.Parent and desc.Parent.Name:lower() or ""
                    if txt:find(keyword:lower()) or pname:find(keyword:lower()) then
                        prompt = desc
                        break
                    end
                end
            end
            if prompt then
                fireproximityprompt(prompt)
                task.wait(0.3)
                local fe = findForceEnd(keyword)
                if fe then pcall(fe) end
                State[countKey] = State[countKey] + 1
                countLbl.Text = prefix .. ": " .. State[countKey] .. " rolls"
            end
            task.wait(0.15)
        end
    end)
end

local function makeGachaSection(yStart, label, stateKey, threadKey, countKey, keyword)
    local countLbl = makeLabel(gachaPage, yStart, label .. ": 0 rolls", T.SubText)
    makeToggle(gachaPage, yStart + 20, "Auto " .. label, function(on)
        if on then
            genericGachaStart(stateKey, threadKey, countKey, keyword, countLbl, label)
        else
            State[stateKey] = false
            if State[threadKey] then pcall(task.cancel, State[threadKey]) end
        end
    end)
end

makeGachaSection(28, "🌀 Aura Roll", "autoGachaAura", "gachaAuraThread", "auraCount", "aura")
makeGachaSection(92, "📦 BlindBox", "autoGachaBlind", "gachaBlindThread", "blindCount", "blind")
makeGachaSection(156, "🥚 Egg/Pet", "autoGachaEgg", "gachaEggThread", "eggCount", "egg")

-- ============================================
-- TAB 3: REWARDS
-- ============================================
local rewardPage = tabPages["Rewards"]
local rewardLogLbl = makeLabel(rewardPage, 4, "── Auto Rewards ──", T.Warning, true)
local rewardStatusLbl = makeLabel(rewardPage, 24, "📋 Log: Idle", T.SubText)

makeToggle(rewardPage, 48, "🎁 Auto Claim Rewards", function(on)
    State.autoReward = on
    if on then
        State.rewardThread = task.spawn(function()
            while State.autoReward do
                local ok1, res1 = pcall(function()
                    return GRF.CollectSessionRewardFunction:InvokeServer()
                end)
                if ok1 and res1 then
                    rewardStatusLbl.Text = "📋 Log: ✅ Session reward claimed!"
                end
                local ok2, res2 = pcall(function()
                    return GRF.CollectDailyRewardFunction:InvokeServer()
                end)
                if ok2 and res2 then
                    rewardStatusLbl.Text = "📋 Log: ✅ Daily reward claimed!"
                end
                task.wait(30)
            end
        end)
    else
        if State.rewardThread then pcall(task.cancel, State.rewardThread) end
        rewardStatusLbl.Text = "📋 Log: Stopped"
    end
end)

-- NameTag Changer
makeLabel(rewardPage, 100, "── NameTag Changer ──", T.Accent, true)
local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(1, -16, 0, 30)
nameInput.Position = UDim2.new(0, 8, 0, 122)
nameInput.BackgroundColor3 = T.Card
nameInput.Text = ""
nameInput.PlaceholderText = "Enter new name..."
nameInput.TextColor3 = T.Text
nameInput.PlaceholderColor3 = T.SubText
nameInput.TextSize = 12
nameInput.Font = Enum.Font.Gotham
nameInput.BorderSizePixel = 0
nameInput.ClearTextOnFocus = false
nameInput.Parent = rewardPage
Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0, 8)

makeButton(rewardPage, 158, "✏️ Change NameTag (Server)", Color3.fromRGB(60, 60, 160), function()
    if nameInput.Text ~= "" then
        local ok, res = pcall(function()
            return GRF.ChangeNameTagFunction:InvokeServer(nameInput.Text)
        end)
        rewardStatusLbl.Text = ok and res and "✅ Name changed!" or "❌ Failed (3-day cooldown)"
    end
end)

-- Code Redeem
makeLabel(rewardPage, 200, "── Code Redeem ──", T.Accent, true)
local codeInput = Instance.new("TextBox")
codeInput.Size = UDim2.new(1, -16, 0, 30)
codeInput.Position = UDim2.new(0, 8, 0, 222)
codeInput.BackgroundColor3 = T.Card
codeInput.Text = ""
codeInput.PlaceholderText = "Enter code..."
codeInput.TextColor3 = T.Text
codeInput.PlaceholderColor3 = T.SubText
codeInput.TextSize = 12
codeInput.Font = Enum.Font.Gotham
codeInput.BorderSizePixel = 0
codeInput.ClearTextOnFocus = false
codeInput.Parent = rewardPage
Instance.new("UICorner", codeInput).CornerRadius = UDim.new(0, 8)

makeButton(rewardPage, 258, "🎟️ Redeem Code", Color3.fromRGB(60, 120, 60), function()
    if codeInput.Text ~= "" then
        local ok, res = pcall(function()
            return GRF.CodeRedeemFunction:InvokeServer(codeInput.Text)
        end)
        rewardStatusLbl.Text = ok and "📋 Log: Code result: " .. tostring(res) or "❌ Failed"
    end
end)

-- ============================================
-- TAB 4: EXTRAS
-- ============================================
local extPage = tabPages["Extras"]
makeLabel(extPage, 4, "── Client-Side Mods ──", T.Warning, true)

-- Speed
local speedLbl = makeLabel(extPage, 26, "WalkSpeed: 16", T.SubText)
makeToggle(extPage, 44, "⚡ Speed Boost (x2)", function(on)
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = on and 32 or 16
            speedLbl.Text = "WalkSpeed: " .. hum.WalkSpeed
        end
    end
end)

-- Jump
makeToggle(extPage, 86, "🦘 High Jump (x2)", function(on)
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = on and 100 or 50
        end
    end
end)

-- Noclip
makeToggle(extPage, 128, "👻 Noclip", function(on)
    State.noclip = on
    if on then
        State.noclipConn = RunService.Stepped:Connect(function()
            local char = player.Character
            if char then
                for _, part in char:GetDescendants() do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if State.noclipConn then State.noclipConn:Disconnect() State.noclipConn = nil end
    end
end)

-- Fly
makeToggle(extPage, 170, "✈️ Fly (WASD+Space/Shift)", function(on)
    State.flyEnabled = on
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if on then
        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyGyro"
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.Parent = hrp

        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp

        local flySpeed = 60
        State.flyThread = RunService.Heartbeat:Connect(function()
            if not State.flyEnabled then return end
            local cam = workspace.CurrentCamera
            bg.CFrame = cam.CFrame
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            bv.Velocity = dir * flySpeed
        end)
    else
        if State.flyThread then State.flyThread:Disconnect() State.flyThread = nil end
        local bg = hrp:FindFirstChild("FlyGyro")
        local bv = hrp:FindFirstChild("FlyVelocity")
        if bg then bg:Destroy() end
        if bv then bv:Destroy() end
    end
end)

-- ESP
makeToggle(extPage, 212, "👁️ ESP (See Players)", function(on)
    State.espEnabled = on
    if on then
        State.espFolder = Instance.new("Folder")
        State.espFolder.Name = "ESP_V2"
        State.espFolder.Parent = CoreGui

        local function addESP(p)
            if p == player then return end
            task.spawn(function()
                while State.espEnabled and p.Parent do
                    local char = p.Character
                    if char then
                        local head = char:FindFirstChild("Head")
                        if head then
                            local existing = State.espFolder:FindFirstChild(p.Name)
                            if not existing then
                                local bb = Instance.new("BillboardGui")
                                bb.Name = p.Name
                                bb.Adornee = head
                                bb.Size = UDim2.new(0, 120, 0, 40)
                                bb.StudsOffset = Vector3.new(0, 3, 0)
                                bb.AlwaysOnTop = true
                                bb.Parent = State.espFolder
                                
                                local tl = Instance.new("TextLabel")
                                tl.Size = UDim2.new(1,0,0.5,0)
                                tl.BackgroundTransparency = 1
                                tl.Text = p.Name
                                tl.TextColor3 = T.Accent
                                tl.TextStrokeTransparency = 0
                                tl.TextSize = 13
                                tl.Font = Enum.Font.GothamBold
                                tl.Parent = bb

                                -- Distance label
                                local dl = Instance.new("TextLabel")
                                dl.Size = UDim2.new(1,0,0.5,0)
                                dl.Position = UDim2.new(0,0,0.5,0)
                                dl.BackgroundTransparency = 1
                                dl.Text = "0m"
                                dl.TextColor3 = T.Warning
                                dl.TextStrokeTransparency = 0
                                dl.TextSize = 11
                                dl.Font = Enum.Font.Gotham
                                dl.Parent = bb

                                local hl = Instance.new("Highlight")
                                hl.Name = "ESP_HL_V2"
                                hl.FillColor = Color3.fromRGB(0, 200, 150)
                                hl.FillTransparency = 0.75
                                hl.OutlineColor = T.Accent
                                hl.Adornee = char
                                hl.Parent = char
                            else
                                -- Update distance
                                local myChar = player.Character
                                if myChar then
                                    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
                                    local otherHRP = char:FindFirstChild("HumanoidRootPart")
                                    if myHRP and otherHRP then
                                        local dist = math.floor((myHRP.Position - otherHRP.Position).Magnitude)
                                        local dl = existing:FindFirstChild("TextLabel")
                                        if dl then
                                            for _, c in existing:GetChildren() do
                                                if c:IsA("TextLabel") and c.TextSize == 11 then
                                                    c.Text = dist .. "m"
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
        for _, p in Players:GetPlayers() do addESP(p) end
        Players.PlayerAdded:Connect(addESP)
    else
        if State.espFolder then State.espFolder:Destroy() State.espFolder = nil end
        for _, p in Players:GetPlayers() do
            if p.Character then
                local hl = p.Character:FindFirstChild("ESP_HL_V2")
                if hl then hl:Destroy() end
            end
        end
    end
end)

-- Infinite Jump
makeToggle(extPage, 254, "🔄 Infinite Jump", function(on)
    State.infJump = on
end)
UIS.JumpRequest:Connect(function()
    if State.infJump then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- ============ MINIMIZE / CLOSE ============
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    contentFrame.Visible = not minimized
    tabBar.Visible = not minimized
    main.Size = minimized and UDim2.new(0, 360, 0, 38) or UDim2.new(0, 360, 0, 450)
    minBtn.Text = minimized and "+" or "─"
end)

closeBtn.MouseButton1Click:Connect(function()
    stopAutoFish()
    State.autoGachaAura = false
    State.autoGachaBlind = false
    State.autoGachaEgg = false
    State.autoReward = false
    State.flyEnabled = false
    State.noclip = false
    State.espEnabled = false
    State.infJump = false
    if State.noclipConn then State.noclipConn:Disconnect() end
    if State.flyThread then pcall(function() State.flyThread:Disconnect() end) end
    if State.espFolder then State.espFolder:Destroy() end
    gui:Destroy()
end)

print("[Indo Voice Tools v2] ⚡ Loaded! Decompiled-accurate fishing + Smart minigame")
