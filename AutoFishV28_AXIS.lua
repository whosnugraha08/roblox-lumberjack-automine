--[[ 
    AUTO FISH V28 — AXIS EDITION
    Redesigned UI: Clean, modern, minimal.
]]

local CoreGui = gethui and gethui() or Players.LocalPlayer:WaitForChild("PlayerGui")
local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- ── CONFIG ──
local CFG = {
    SafetyOn = true, SafetyDist = 50, SafetyCD = 30,
    StuckOn = true, StuckTimeout = 25,
    SellOn = false, SellInterval = 300,
    MoveOn = false, MoveLimit = 5, MoveCur = 0,
    PosA = nil, PosB = nil, CurTarget = "A"
}

local CLK = {
    HoldMin = 0.1, HoldMax = 0.35,
    WaitMin = 0.35, WaitMax = 0.55,
    MiniHold = 0.07, MiniDelay = 0.1
}

-- ── PALETTE ──
local C = {
    bg      = Color3.fromRGB(18, 18, 22),
    card    = Color3.fromRGB(26, 26, 32),
    surface = Color3.fromRGB(34, 34, 42),
    border  = Color3.fromRGB(48, 48, 58),
    text    = Color3.fromRGB(230, 230, 235),
    sub     = Color3.fromRGB(120, 120, 135),
    accent  = Color3.fromRGB(90, 200, 160),
    red     = Color3.fromRGB(220, 75, 75),
    amber   = Color3.fromRGB(230, 180, 60),
    gold    = Color3.fromRGB(240, 195, 60),
    blue    = Color3.fromRGB(80, 140, 240),
}

if CoreGui:FindFirstChild("AF28") then CoreGui.AF28:Destroy() end

-- ── STATE ──
local fishing, resetting, paused = false, false, false
local freezeOn = false
local safetyStart, lastCast, lastSell = 0, 0, tick()
local state = "IDLE"

-- AXIS
local AXIS = { swordfish = 0, total = 0, start = tick(), conns = {}, _lastDet = 0 }

local gui, statusLbl, axisCountLbl, globalLog, exchLbls

-- ── ANTI AFK ──
LP.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ── UTILS ──
local rng = function(a,b) return math.random(a*1000,b*1000)/1000 end

local function tween(obj, props, dur, style)
    TweenService:Create(obj, TweenInfo.new(dur or 0.25, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local function equipRod()
    local c, bp = LP.Character, LP:FindFirstChild("Backpack")
    if not c or not bp then return end
    local h = c:FindFirstChild("Humanoid"); if not h then return end
    h:UnequipTools(); task.wait(rng(0.3,0.5))
    local rod
    for _,t in pairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("rod") then rod=t break end end
    if not rod then local ts=bp:GetChildren(); if #ts>0 then rod=ts[1] end end
    if rod then h:EquipTool(rod) end
end

local function equipSlot2()
    VIM:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
    task.wait(rng(0.1,0.2))
    VIM:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
end

local function teleportTo(cf)
    local c = LP.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        c.HumanoidRootPart.CFrame = cf
        c.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    end
end

-- ── UI BUILDER HELPERS ──
local function corner(p, r) local c = Instance.new("UICorner",p); c.CornerRadius = UDim.new(0, r or 8); return c end
local function pad(p, t, b, l, r)
    local u = Instance.new("UIPadding",p)
    u.PaddingTop = UDim.new(0,t or 0); u.PaddingBottom = UDim.new(0,b or 0)
    u.PaddingLeft = UDim.new(0,l or 0); u.PaddingRight = UDim.new(0,r or 0)
    return u
end

local function makeLabel(parent, text, size, color, font, xAlign)
    local l = Instance.new("TextLabel", parent)
    l.Text = text; l.TextSize = size or 12; l.TextColor3 = color or C.text
    l.Font = font or Enum.Font.GothamMedium; l.BackgroundTransparency = 1
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.Size = UDim2.new(1, 0, 0, 18); l.TextWrapped = true
    return l
end

-- ── NOTIFICATION ──
local function notify(text, col, duration)
    if not gui or not gui.Parent then return end
    local n = Instance.new("Frame", gui)
    n.Size = UDim2.new(0, 280, 0, 36); n.Position = UDim2.new(0.5, -140, 0, -40)
    n.BackgroundColor3 = C.card; n.BorderSizePixel = 0; n.ZIndex = 50; corner(n, 10)
    local s = Instance.new("UIStroke", n); s.Color = col or C.accent; s.Thickness = 1.5; s.Transparency = 0.3
    local t = makeLabel(n, text, 12, col or C.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    t.Size = UDim2.new(1,0,1,0); t.ZIndex = 51
    -- slide in
    tween(n, {Position = UDim2.new(0.5, -140, 0, 10)}, 0.35)
    task.delay(duration or 3, function()
        tween(n, {Position = UDim2.new(0.5, -140, 0, -40), BackgroundTransparency = 1}, 0.3)
        tween(t, {TextTransparency = 1}, 0.3)
        task.wait(0.35); pcall(function() n:Destroy() end)
    end)
end

-- ── GLOBAL LOG ──
local function addLog(text, col)
    if not globalLog then return end
    local e = makeLabel(globalLog, os.date("[%H:%M] ")..text, 10, col or C.sub, Enum.Font.RobotoMono)
    e.Size = UDim2.new(1, -8, 0, 16)
    task.defer(function()
        local ly = globalLog:FindFirstChildOfClass("UIListLayout")
        if ly then
            globalLog.CanvasSize = UDim2.new(0,0,0, ly.AbsoluteContentSize.Y + 8)
            globalLog.CanvasPosition = Vector2.new(0, math.max(0, ly.AbsoluteContentSize.Y - globalLog.AbsoluteSize.Y))
        end
    end)
end

local function updateExchange()
    if not exchLbls then return end
    local items = {{n="Buas Aura",c=1},{n="Summer Kite",c=2},{n="Surfboard",c=3}}
    for i, item in ipairs(items) do
        if exchLbls[i] then
            local ok = AXIS.swordfish >= item.c
            exchLbls[i].Text = (ok and "● " or "○ ")..item.n.." — "..item.c.." ikan"..(ok and "  ✓" or "")
            exchLbls[i].TextColor3 = ok and C.accent or C.sub
        end
    end
end

-- ── AXIS MONITOR ──
local function setupAxisMonitor()
    local gre = RS:FindFirstChild("GameRemoteEvents")
    if gre then
        for _, evt in ipairs(gre:GetChildren()) do
            if evt:IsA("RemoteEvent") and evt.Name:lower():find("reward") then
                table.insert(AXIS.conns, evt.OnClientEvent:Connect(function(...)
                    for _, arg in ipairs({...}) do
                        if type(arg)=="table" and arg.Name and type(arg.Name)=="string" and arg.Name:find("AXIS") then
                            AXIS.swordfish += 1
                            addLog("AXIS Swordfish #"..AXIS.swordfish.."!", C.gold)
                            notify("AXIS Swordfish #"..AXIS.swordfish.." caught!", C.gold, 5)
                            if axisCountLbl then axisCountLbl.Text = tostring(AXIS.swordfish) end
                            updateExchange()
                        end
                    end
                end))
            end
        end
    end
    
    table.insert(AXIS.conns, LP:WaitForChild("PlayerGui").ChildAdded:Connect(function(child)
        task.wait(0.3)
        pcall(function()
            for _, d in ipairs(child:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text:find("AXIS") and d.Text:find("Swordfish") then
                    local tk = math.floor(tick())
                    if AXIS._lastDet ~= tk then
                        AXIS._lastDet = tk; AXIS.swordfish += 1
                        addLog("AXIS Swordfish #"..AXIS.swordfish.." detected!", C.gold)
                        notify("AXIS Swordfish #"..AXIS.swordfish.."!", C.gold, 5)
                        if axisCountLbl then axisCountLbl.Text = tostring(AXIS.swordfish) end
                        updateExchange()
                    end
                end
            end
        end)
    end))
    addLog("Monitor aktif — AXIS Summer Rod", C.accent)
    addLog("Target: Swordfish (1/2000 + 2% bonus)", C.sub)
end

-- ── CORE LOGIC ──
local function doSell()
    if statusLbl then statusLbl.Text = "selling..." end
    addLog("Selling all fish to shop...", C.gold)
    task.spawn(function()
        pcall(function()
            local r = RS:WaitForChild("GameRemoteFunctions",2)
            if r then local s = r:WaitForChild("SellAllFishFunction",2); if s then s:InvokeServer() end end
        end)
    end)
    lastSell = tick()
end

local function doMove()
    if not CFG.MoveOn or not CFG.PosA or not CFG.PosB then return end
    CFG.MoveCur += 1
    if CFG.MoveCur >= CFG.MoveLimit then
        resetting = true
        statusLbl.Text = "moving..."
        equipSlot2(); task.wait(1)
        if CFG.CurTarget=="A" then teleportTo(CFG.PosB); CFG.CurTarget="B"
        else teleportTo(CFG.PosA); CFG.CurTarget="A" end
        addLog("Moved to Position "..CFG.CurTarget, C.accent)
        CFG.MoveCur = 0; task.wait(1); equipRod(); task.wait(1)
        resetting = false; lastCast = tick()
    end
end

local function doReset()
    resetting = true; statusLbl.Text = "resetting..."
    addLog("Anti-stuck: Resetting tool...", C.amber)
    equipSlot2(); task.wait(2); equipRod(); task.wait(1.5)
    lastCast = tick(); state = "IDLE"; statusLbl.Text = "ready"
    task.wait(0.5); resetting = false
end

local function humanClick(ui)
    local x, y
    if not ui then local vp = workspace.CurrentCamera.ViewportSize; x,y = vp.X/2, vp.Y/2
    else local a,s,i = ui.AbsolutePosition, ui.AbsoluteSize, GuiService:GetGuiInset(); x=a.X+s.X/2; y=a.Y+s.Y/2+i.Y end
    VIM:SendMouseMoveEvent(x,y,game); task.wait(rng(0.04,0.05))
    VIM:SendMouseButtonEvent(x,y,0,true,game,1); task.wait(rng(CLK.HoldMin,CLK.HoldMax))
    VIM:SendMouseButtonEvent(x,y,0,false,game,1)
end

local function turboClick()
    local vp = workspace.CurrentCamera.ViewportSize; local x,y = vp.X/2, vp.Y/2
    VIM:SendMouseButtonEvent(x,y,0,true,game,1); task.wait(CLK.MiniHold)
    VIM:SendMouseButtonEvent(x,y,0,false,game,1)
end

-- ── MAIN FISH LOOP ──
local function fishLoop()
    while fishing do
        task.wait()
        if resetting or paused then task.wait(0.5); continue end
        
        local char = LP.Character
        local rod = char and char:FindFirstChildOfClass("Tool")
        if not rod or not rod.Name:lower():find("rod") then
            equipRod(); task.wait(0.5); state="IDLE"
        end

        local pGui = LP:FindFirstChild("PlayerGui")
        local ui = pGui and pGui:FindFirstChild("FishingUI")
        
        if ui and ui.Enabled then
            if ui:FindFirstChild("PreFishingHolder") and ui.PreFishingHolder.Visible then
                state="AIMING"; lastCast = tick()
                local btn
                for _,c in pairs(ui.PreFishingHolder:GetChildren()) do if c.Name=="TapButton" and c.Visible then btn=c break end end
                if btn then
                    statusLbl.Text = "aiming"; humanClick(btn)
                    task.wait(rng(CLK.WaitMin, CLK.WaitMax))
                end
            elseif ui:FindFirstChild("FishingHolder") and ui.FishingHolder.Visible then
                state="PULLING"; lastCast = tick()
                local bar = ui.FishingHolder:FindFirstChild("FishingFrame")
                bar = bar and bar:FindFirstChild("BarContainer")
                bar = bar and bar:FindFirstChild("Bar")
                if bar then
                    local bc = bar.BackgroundColor3
                    if bc.G>0.5 and bc.R<0.5 then
                        statusLbl.Text = "pulling"; turboClick(); task.wait(CLK.MiniDelay)
                    else
                        statusLbl.Text = "waiting"; task.wait(0.05)
                    end
                end
            end
        else
            if state=="PULLING" then state="IDLE"; AXIS.total += 1 end
            if state ~= "CASTING" then
                if CFG.MoveOn then doMove(); if resetting then continue end end
                statusLbl.Text = "casting"
                local vp = workspace.CurrentCamera.ViewportSize
                VIM:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,true,game,1)
                task.wait(rng(0.4,0.7))
                VIM:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,false,game,1)
                state="CASTING"; lastCast = tick(); task.wait(1.5)
            end
        end
    end
end

-- ── BACKGROUND ──
local function bgLoops()
    -- Safety
    task.spawn(function()
        while gui.Parent do
            task.wait(CFG.SafetyOn and 0.5 or 2)
            if fishing and CFG.SafetyOn and not resetting then
                local mr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if mr then
                    local danger = false
                    for _,p in pairs(Players:GetPlayers()) do
                        if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            if (p.Character.HumanoidRootPart.Position-mr.Position).Magnitude < CFG.SafetyDist then danger=true break end
                        end
                    end
                    if danger then
                        if not paused then 
                            paused=true; equipSlot2(); state="SAFETY"
                            addLog("Safety: Player nearby, paused", C.red)
                        end
                        safetyStart=tick(); statusLbl.Text = "player nearby"
                    elseif paused then
                        local left = math.ceil(CFG.SafetyCD-(tick()-safetyStart))
                        if left>0 then statusLbl.Text = "cooldown "..left.."s"
                        else 
                            paused=false; equipRod(); statusLbl.Text = "resuming"; lastCast=tick()
                            addLog("Safety: Resuming...", C.accent)
                        end
                    end
                end
            end
        end
    end)
    -- Freeze
    task.spawn(function()
        while gui.Parent do task.wait(0.5)
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if r then r.Anchored = freezeOn end
        end
    end)
    -- Watchdog
    task.spawn(function()
        while gui.Parent do task.wait(1)
            if fishing and CFG.StuckOn and not paused and not resetting and state=="CASTING" then
                if tick()-lastCast > CFG.StuckTimeout then doReset() end
            end
        end
    end)
    -- Auto sell
    task.spawn(function()
        while gui.Parent do task.wait(1)
            if CFG.SellOn and fishing and not resetting and not paused then
                if tick()-lastSell >= CFG.SellInterval then doSell() end
            end
        end
    end)
    -- Timer
    task.spawn(function()
        while gui.Parent do task.wait(3)
            local el = tick()-AXIS.start; local m = math.floor(el/60); local h = math.floor(m/60); m=m%60
            if axisCountLbl then
                -- update handled in main counter
            end
        end
    end)
end

-- ══════════════════════════════════════════
-- ██  GUI  ██
-- ══════════════════════════════════════════
local function buildGUI()
    gui = Instance.new("ScreenGui"); gui.Name = "AF28"; gui.Parent = CoreGui; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- ── SETTINGS PANEL ──
    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0, 300, 0, 360)
    main.Position = UDim2.new(0.5, -310, 0.5, -180)
    main.BackgroundColor3 = C.bg; main.BorderSizePixel = 0
    main.Active = true; main.Draggable = true
    main.ClipsDescendants = true
    corner(main, 12)
    Instance.new("UIStroke", main).Color = C.border; main.UIStroke.Thickness = 1

    local header = Instance.new("Frame", main)
    header.Size = UDim2.new(1, 0, 0, 44); header.BackgroundTransparency = 1
    pad(header, 12, 0, 16, 12)
    
    local title = Instance.new("TextLabel", header)
    title.Text = "autofish"; title.Font = Enum.Font.GothamBlack; title.TextSize = 16
    title.TextColor3 = C.text; title.BackgroundTransparency = 1
    title.Size = UDim2.new(0, 100, 1, 0); title.Position = UDim2.new(0, 0, 0, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left

    statusLbl = Instance.new("TextLabel", header)
    statusLbl.Text = "idle"; statusLbl.Font = Enum.Font.RobotoMono; statusLbl.TextSize = 11
    statusLbl.TextColor3 = C.sub; statusLbl.BackgroundTransparency = 1
    statusLbl.Size = UDim2.new(0, 100, 1, 0); statusLbl.Position = UDim2.new(1, -130, 0, 0)
    statusLbl.TextXAlignment = Enum.TextXAlignment.Right

    local minBtn = Instance.new("TextButton", header)
    minBtn.Text = "—"; minBtn.Font = Enum.Font.GothamBold; minBtn.TextSize = 14
    minBtn.TextColor3 = C.sub; minBtn.BackgroundTransparency = 1
    minBtn.Size = UDim2.new(0, 24, 0, 24); minBtn.Position = UDim2.new(1, -48, 0.5, -12)
    local mainMin = false
    minBtn.MouseButton1Click:Connect(function()
        mainMin = not mainMin
        tween(main, {Size = mainMin and UDim2.new(0, 300, 0, 44) or UDim2.new(0, 300, 0, 360)}, 0.3)
    end)

    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14
    closeBtn.TextColor3 = C.sub; closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.new(0, 24, 0, 24); closeBtn.Position = UDim2.new(1, -24, 0.5, -12)
    closeBtn.MouseButton1Click:Connect(function()
        fishing = false; freezeOn = false
        for _,cn in ipairs(AXIS.conns) do pcall(function() cn:Disconnect() end) end
        gui:Destroy()
    end)

    local div1 = Instance.new("Frame", main)
    div1.Size = UDim2.new(1, -32, 0, 1); div1.Position = UDim2.new(0, 16, 0, 44)
    div1.BackgroundColor3 = C.border; div1.BorderSizePixel = 0

    local tabBar = Instance.new("Frame", main)
    tabBar.Size = UDim2.new(1, -32, 0, 30); tabBar.Position = UDim2.new(0, 16, 0, 50)
    tabBar.BackgroundTransparency = 1
    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal

    local indicator = Instance.new("Frame", main)
    indicator.Size = UDim2.new(0, 50, 0, 2); indicator.Position = UDim2.new(0, 16, 0, 80)
    indicator.BackgroundColor3 = C.accent; indicator.BorderSizePixel = 0
    corner(indicator, 1)

    local pages = Instance.new("Frame", main)
    pages.Size = UDim2.new(1, -24, 1, -92); pages.Position = UDim2.new(0, 12, 0, 86)
    pages.BackgroundTransparency = 1; pages.ClipsDescendants = true

    local function makePage(name)
        local p = Instance.new("ScrollingFrame", pages)
        p.Name = name; p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1
        p.ScrollBarThickness = 0; p.Visible = false; p.BorderSizePixel = 0
        p.ScrollingDirection = Enum.ScrollingDirection.Y; p.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local l = Instance.new("UIListLayout", p); l.Padding = UDim.new(0, 8)
        pad(p, 4, 8, 4, 4)
        return p
    end

    local pHome = makePage("Home"); pHome.Visible = true
    local pMove = makePage("Move")
    local pConf = makePage("Config")
    
    local tabs = {"Home","Move","Config"}
    local tabBtns = {}
    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton", tabBar)
        btn.Text = name:lower(); btn.Size = UDim2.new(1/#tabs, 0, 1, 0)
        btn.BackgroundTransparency = 1; btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
        btn.TextColor3 = (i==1) and C.accent or C.sub
        tabBtns[i] = btn
        btn.MouseButton1Click:Connect(function()
            for j, b in ipairs(tabBtns) do b.TextColor3 = (j==i) and C.accent or C.sub end
            for _, p in pairs(pages:GetChildren()) do if p:IsA("ScrollingFrame") then p.Visible = false end end
            pages:FindFirstChild(name).Visible = true
            local xPos = 16 + (i-1) * (tabBar.AbsoluteSize.X / #tabs) + (tabBar.AbsoluteSize.X / #tabs / 2) - 25
            tween(indicator, {Position = UDim2.new(0, xPos, 0, 80)}, 0.3)
        end)
    end

    -- Builders
    local function makeCard(parent)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 0); f.AutomaticSize = Enum.AutomaticSize.Y
        f.BackgroundColor3 = C.card; f.BorderSizePixel = 0; corner(f, 8); pad(f, 10, 10, 12, 12)
        local l = Instance.new("UIListLayout", f); l.Padding = UDim.new(0, 8)
        return f
    end

    local function makeToggle(parent, label, default, cb)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, 0, 0, 24); row.BackgroundTransparency = 1
        makeLabel(row, label, 11, C.text, Enum.Font.GothamMedium).Size = UDim2.new(1, -50, 1, 0)
        local pill = Instance.new("TextButton", row)
        pill.Text = ""; pill.Size = UDim2.new(0, 38, 0, 20); pill.Position = UDim2.new(1, -38, 0.5, -10)
        pill.BackgroundColor3 = default and C.accent or C.surface; pill.BorderSizePixel = 0; corner(pill, 10)
        local dot = Instance.new("Frame", pill)
        dot.Size = UDim2.new(0, 14, 0, 14); dot.BackgroundColor3 = Color3.new(1,1,1); dot.BorderSizePixel = 0; corner(dot, 7)
        dot.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local on = default
        pill.MouseButton1Click:Connect(function()
            on = not on; tween(pill, {BackgroundColor3 = on and C.accent or C.surface}, 0.2)
            tween(dot, {Position = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}, 0.2); cb(on)
        end)
    end

    local function makeInput(parent, label, val, cb)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, 0, 0, 24); row.BackgroundTransparency = 1
        makeLabel(row, label, 11, C.text, Enum.Font.GothamMedium).Size = UDim2.new(1, -60, 1, 0)
        local box = Instance.new("TextBox", row)
        box.Text = tostring(val); box.Size = UDim2.new(0, 50, 0, 22); box.Position = UDim2.new(1, -50, 0.5, -11)
        box.BackgroundColor3 = C.surface; box.BorderSizePixel = 0; box.TextColor3 = C.accent
        box.Font = Enum.Font.GothamBold; box.TextSize = 11; corner(box, 6)
        box.FocusLost:Connect(function() cb(tonumber(box.Text) or val) end)
    end

    local function makeButton(parent, label, col, cb)
        local btn = Instance.new("TextButton", parent)
        btn.Text = label; btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = col or C.surface; btn.BorderSizePixel = 0
        btn.TextColor3 = C.text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; corner(btn, 8)
        btn.MouseButton1Click:Connect(function() cb(btn) end)
        btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = C.border}, 0.15) end)
        btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = col or C.surface}, 0.15) end)
    end

    -- Home Page
    local homeCard = makeCard(pHome)
    local startBtn = Instance.new("TextButton", pHome)
    startBtn.Text = "Start Fishing"; startBtn.Size = UDim2.new(1, 0, 0, 40)
    startBtn.BackgroundColor3 = C.accent; startBtn.BorderSizePixel = 0
    startBtn.TextColor3 = C.bg; startBtn.Font = Enum.Font.GothamBlack; startBtn.TextSize = 13; corner(startBtn, 10)
    startBtn.MouseButton1Click:Connect(function()
        fishing = not fishing
        if fishing then
            startBtn.Text = "Stop Fishing"; tween(startBtn, {BackgroundColor3 = C.red}, 0.2)
            state="IDLE"; lastCast=tick(); resetting=false; AXIS.start=tick(); AXIS.total=0
            addLog("Session started", C.accent); task.spawn(fishLoop)
        else
            startBtn.Text = "Start Fishing"; tween(startBtn, {BackgroundColor3 = C.accent}, 0.2)
            statusLbl.Text = "idle"; paused = false; addLog("Session stopped", C.red)
        end
    end)
    makeToggle(homeCard, "Auto Sell", CFG.SellOn, function(v) CFG.SellOn=v; if v then lastSell=tick() end end)
    makeToggle(homeCard, "Safety Mode", CFG.SafetyOn, function(v) CFG.SafetyOn=v end)
    makeToggle(homeCard, "Freeze Position", freezeOn, function(v) freezeOn=v end)
    makeToggle(homeCard, "Anti-Stuck", CFG.StuckOn, function(v) CFG.StuckOn=v end)

    -- Move Page
    local moveCard = makeCard(pMove)
    makeButton(pMove, "Set Position A", C.surface, function(b)
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then CFG.PosA = LP.Character.HumanoidRootPart.CFrame; b.Text = "Position A  ✓"; task.wait(1.2); b.Text = "Set Position A" end
    end)
    makeButton(pMove, "Set Position B", C.surface, function(b)
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then CFG.PosB = LP.Character.HumanoidRootPart.CFrame; b.Text = "Position B  ✓"; task.wait(1.2); b.Text = "Set Position B" end
    end)
    makeInput(moveCard, "Move every (casts)", CFG.MoveLimit, function(v) CFG.MoveLimit=v end)
    makeToggle(moveCard, "Auto Move", CFG.MoveOn, function(v)
        if v and (not CFG.PosA or not CFG.PosB) then notify("Set both positions first", C.amber); return end
        CFG.MoveOn = v
    end)

    -- Config Page
    local confCard = makeCard(pConf)
    makeInput(confCard, "Safety distance", CFG.SafetyDist, function(v) CFG.SafetyDist=v end)
    makeInput(confCard, "Safety cooldown (s)", CFG.SafetyCD, function(v) CFG.SafetyCD=v end)
    makeInput(confCard, "Sell interval (s)", CFG.SellInterval, function(v) CFG.SellInterval=v end)
    makeInput(confCard, "Stuck timeout (s)", CFG.StuckTimeout, function(v) CFG.StuckTimeout=v end)

    -- ── TRACKER PANEL ──
    local tracker = Instance.new("Frame", gui)
    tracker.Size = UDim2.new(0, 260, 0, 360)
    tracker.Position = UDim2.new(0.5, 10, 0.5, -180)
    tracker.BackgroundColor3 = C.bg; tracker.BorderSizePixel = 0
    tracker.Active = true; tracker.Draggable = true
    tracker.ClipsDescendants = true
    corner(tracker, 12)
    Instance.new("UIStroke", tracker).Color = C.border; tracker.UIStroke.Thickness = 1

    local tHeader = Instance.new("Frame", tracker)
    tHeader.Size = UDim2.new(1, 0, 0, 34); tHeader.BackgroundTransparency = 1; pad(tHeader, 10, 0, 16, 12)
    local tTitle = makeLabel(tHeader, "AXIS EVENT TRACKER", 11, C.gold, Enum.Font.GothamBlack)
    tTitle.Size = UDim2.new(1, -30, 1, 0)
    
    local tMinBtn = Instance.new("TextButton", tHeader)
    tMinBtn.Text = "—"; tMinBtn.Font = Enum.Font.GothamBold; tMinBtn.TextSize = 14
    tMinBtn.TextColor3 = C.sub; tMinBtn.BackgroundTransparency = 1
    tMinBtn.Size = UDim2.new(0, 24, 0, 24); tMinBtn.Position = UDim2.new(1, -24, 0.5, -12)
    local trackMin = false
    tMinBtn.MouseButton1Click:Connect(function()
        trackMin = not trackMin
        tween(tracker, {Size = trackMin and UDim2.new(0, 260, 0, 34) or UDim2.new(0, 260, 0, 360)}, 0.3)
    end)
    local tDiv = Instance.new("Frame", tracker)
    tDiv.Size = UDim2.new(1, -32, 0, 1); tDiv.Position = UDim2.new(0, 16, 0, 34)
    tDiv.BackgroundColor3 = C.border; tDiv.BorderSizePixel = 0

    local tScroll = Instance.new("ScrollingFrame", tracker)
    tScroll.Size = UDim2.new(1, -24, 1, -50); tScroll.Position = UDim2.new(0, 12, 0, 42)
    tScroll.BackgroundTransparency = 1; tScroll.ScrollBarThickness = 0; tScroll.BorderSizePixel = 0
    tScroll.ScrollingDirection = Enum.ScrollingDirection.Y; tScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local tl = Instance.new("UIListLayout", tScroll); tl.Padding = UDim.new(0, 10); pad(tScroll, 4, 8, 4, 4)

    -- Tracker: Big Counter
    local axisTop = Instance.new("Frame", tScroll)
    axisTop.Size = UDim2.new(1, 0, 0, 60); axisTop.BackgroundColor3 = C.card; axisTop.BorderSizePixel = 0; corner(axisTop, 8)
    local axisTopStroke = Instance.new("UIStroke", axisTop); axisTopStroke.Color = C.gold; axisTopStroke.Thickness = 1; axisTopStroke.Transparency = 0.6
    local countTitle = makeLabel(axisTop, "AXIS Swordfish", 10, C.gold, Enum.Font.GothamBold)
    countTitle.Size = UDim2.new(1, 0, 0, 14); countTitle.Position = UDim2.new(0, 14, 0, 8)

    axisCountLbl = Instance.new("TextLabel", axisTop)
    axisCountLbl.Text = "0"; axisCountLbl.Font = Enum.Font.GothamBlack; axisCountLbl.TextSize = 28
    axisCountLbl.TextColor3 = C.text; axisCountLbl.BackgroundTransparency = 1
    axisCountLbl.Size = UDim2.new(0, 60, 0, 32); axisCountLbl.Position = UDim2.new(0, 14, 0, 24)
    axisCountLbl.TextXAlignment = Enum.TextXAlignment.Left

    local fishTotal = Instance.new("TextLabel", axisTop)
    fishTotal.Text = "total caught: 0"; fishTotal.Font = Enum.Font.RobotoMono; fishTotal.TextSize = 10
    fishTotal.TextColor3 = C.sub; fishTotal.BackgroundTransparency = 1
    fishTotal.Size = UDim2.new(0.5, 0, 0, 14); fishTotal.Position = UDim2.new(0.45, 0, 0, 10)
    fishTotal.TextXAlignment = Enum.TextXAlignment.Right

    local fishTimer = Instance.new("TextLabel", axisTop)
    fishTimer.Text = "session: 0m"; fishTimer.Font = Enum.Font.RobotoMono; fishTimer.TextSize = 10
    fishTimer.TextColor3 = C.sub; fishTimer.BackgroundTransparency = 1
    fishTimer.Size = UDim2.new(0.5, 0, 0, 14); fishTimer.Position = UDim2.new(0.45, 0, 0, 26)
    fishTimer.TextXAlignment = Enum.TextXAlignment.Right
    
    task.spawn(function()
        while gui.Parent do task.wait(5)
            local el = tick()-AXIS.start; local m = math.floor(el/60); local h = math.floor(m/60); m=m%60
            fishTotal.Text = "total caught: "..AXIS.total
            fishTimer.Text = "session: "..(h>0 and h.."h " or "")..m.."m"
        end
    end)

    -- Tracker: Exchange
    local exchCard = makeCard(tScroll)
    makeLabel(exchCard, "Exchange Status", 10, C.sub, Enum.Font.GothamBold).Size = UDim2.new(1, 0, 0, 14)
    exchLbls = {}
    local items = {{n="Buas Aura",c=1},{n="Summer Kite",c=2},{n="Surfboard",c=3}}
    for i, item in ipairs(items) do
        exchLbls[i] = makeLabel(exchCard, "○ "..item.n.." — "..item.c.." ikan", 10, C.sub, Enum.Font.GothamMedium)
        exchLbls[i].Size = UDim2.new(1, 0, 0, 16)
    end
    updateExchange()

    -- Tracker: Event Log
    local logCard = Instance.new("Frame", tScroll)
    logCard.Size = UDim2.new(1, 0, 0, 110); logCard.BackgroundColor3 = C.card; logCard.BorderSizePixel = 0; corner(logCard, 8); pad(logCard, 8, 8, 8, 8)
    makeLabel(logCard, "Event & System Log", 10, C.sub, Enum.Font.GothamBold).Size = UDim2.new(1, 0, 0, 14)
    local ld = Instance.new("Frame", logCard); ld.Size = UDim2.new(1, 0, 0, 1); ld.Position = UDim2.new(0, 0, 0, 18); ld.BackgroundColor3 = C.border; ld.BorderSizePixel = 0
    
    globalLog = Instance.new("ScrollingFrame", logCard)
    globalLog.Size = UDim2.new(1, 0, 1, -22); globalLog.Position = UDim2.new(0, 0, 0, 22)
    globalLog.BackgroundTransparency = 1; globalLog.BorderSizePixel = 0; globalLog.ScrollBarThickness = 2; globalLog.ScrollBarImageColor3 = C.border
    local logLay = Instance.new("UIListLayout", globalLog); logLay.Padding = UDim.new(0, 2)

    -- ── START SYSTEMS ──
    task.spawn(bgLoops)
    task.spawn(setupAxisMonitor)
end

buildGUI()
