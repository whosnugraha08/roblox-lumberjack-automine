-- =============================================
-- BUCKSHOT HELPER v5
-- ULTIMATE: Direct Overwrite Hooks + Error Logger
-- =============================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- Get Bootstrapper module & handlers
local ClientModule, VisualsHandler, TurnHandler, GameHandler, CaptionHandler
pcall(function()
    local boot = LP:WaitForChild("PlayerScripts"):WaitForChild("Bootstrapper"):WaitForChild("Client")
    ClientModule = require(boot)
    VisualsHandler = require(boot:WaitForChild("VisualsHandler"))
    TurnHandler = require(boot:WaitForChild("TurnHandler"))
    GameHandler = require(boot:WaitForChild("GameHandler"))
    CaptionHandler = require(boot:WaitForChild("CaptionHandler"))
end)

-- DESTROY OLD GUI
for _, name in {"BuckshotHelper"} do
    local old = game:GetService("CoreGui"):FindFirstChild(name)
    if old then old:Destroy() end
end

local SG = Instance.new("ScreenGui")
SG.Name = "BuckshotHelper"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = game:GetService("CoreGui")

-- Main Frame (Visual Excellence: HSL Sleek Dark theme)
local Main = Instance.new("Frame", SG)
Main.Name = "Main"
Main.Size = UDim2.new(0, 280, 0, 390)
Main.Position = UDim2.new(0, 10, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = Color3.fromRGB(220, 50, 50)
mainStroke.Thickness = 2

-- Header Banner
local TB = Instance.new("Frame", Main)
TB.Size = UDim2.new(1, 0, 0, 36)
TB.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
TB.BorderSizePixel = 0
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 10)
local tbFix = Instance.new("Frame", TB)
tbFix.Size = UDim2.new(1, 0, 0, 10)
tbFix.Position = UDim2.new(0, 0, 1, -10)
tbFix.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
tbFix.BorderSizePixel = 0

local TitleText = Instance.new("TextLabel", TB)
TitleText.Size = UDim2.new(1, -60, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🔫 BUCKSHOT HELPER v5"
TitleText.TextColor3 = Color3.new(1, 1, 1)
TitleText.TextSize = 13
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local cBtn = Instance.new("TextButton", TB)
cBtn.Size = UDim2.new(0, 26, 0, 26)
cBtn.Position = UDim2.new(1, -30, 0, 5)
cBtn.BackgroundTransparency = 1
cBtn.Text = "✕"
cBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
cBtn.TextSize = 15
cBtn.Font = Enum.Font.GothamBold
cBtn.MouseButton1Click:Connect(function() SG:Destroy() end)

local mBtn = Instance.new("TextButton", TB)
mBtn.Size = UDim2.new(0, 26, 0, 26)
mBtn.Position = UDim2.new(1, -56, 0, 5)
mBtn.BackgroundTransparency = 1
mBtn.Text = "—"
mBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
mBtn.TextSize = 14
mBtn.Font = Enum.Font.GothamBold
local mini = false
mBtn.MouseButton1Click:Connect(function()
    mini = not mini
    for _, c in Main:GetChildren() do
        if c:IsA("GuiObject") and c ~= TB then c.Visible = not mini end
    end
    Main.Size = mini and UDim2.new(0, 280, 0, 36) or UDim2.new(0, 280, 0, 390)
end)

-- Content Scroll Frame
local C = Instance.new("ScrollingFrame", Main)
C.Name = "C"
C.Size = UDim2.new(1, -10, 1, -42)
C.Position = UDim2.new(0, 5, 0, 38)
C.BackgroundTransparency = 1
C.BorderSizePixel = 0
C.ScrollBarThickness = 3
C.ScrollBarImageColor3 = Color3.fromRGB(220, 50, 50)
C.AutomaticCanvasSize = Enum.AutomaticSize.Y
local layout = Instance.new("UIListLayout", C)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Section Creator
local function sec(title, order)
    local f = Instance.new("Frame", C)
    f.Size = UDim2.new(1, -4, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    f.BorderSizePixel = 0
    f.LayoutOrder = order
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local p = Instance.new("UIPadding", f)
    p.PaddingTop = UDim.new(0, 6)
    p.PaddingBottom = UDim.new(0, 6)
    p.PaddingLeft = UDim.new(0, 8)
    p.PaddingRight = UDim.new(0, 8)
    
    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, 2)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    
    local h = Instance.new("TextLabel", f)
    h.Size = UDim2.new(1, 0, 0, 18)
    h.BackgroundTransparency = 1
    h.Text = title
    h.TextColor3 = Color3.fromRGB(255, 80, 80)
    h.TextSize = 11
    h.Font = Enum.Font.GothamBold
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.LayoutOrder = 0
    return f
end

-- Label Creator
local function lbl(parent, text, order, color)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(190, 190, 200)
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 1
    l.TextWrapped = true
    l.AutomaticSize = Enum.AutomaticSize.Y
    return l
end

-- =============================================
-- UI SECTIONS
-- =============================================
local sT = sec("📍 YOUR TABLE", 1)
local lTable = lbl(sT, "⏳ Waiting to join a table...", 1, Color3.fromRGB(255, 200, 100))
local lSpot = lbl(sT, "", 2)
local lOpp = lbl(sT, "", 3)

local sS = sec("🔴 SHELLS IN GUN", 2)
local lLive = lbl(sS, "—", 1, Color3.fromRGB(255, 100, 100))
local lBlank = lbl(sS, "—", 2, Color3.fromRGB(140, 140, 255))
local lTotal = lbl(sS, "—", 3)

local sP = sec("🎯 PROBABILITY", 3)
local lLP = lbl(sP, "—", 1, Color3.fromRGB(255, 120, 120))
local lBP = lbl(sP, "—", 2, Color3.fromRGB(120, 120, 255))

local sA = sec("💡 ADVICE", 4)
local lAdv = lbl(sA, "Sit at a table to start tracking", 1, Color3.fromRGB(150, 150, 150))

local sTn = sec("⏱️ TURN STATUS", 5)
local lTurn = lbl(sTn, "—", 1, Color3.fromRGB(200, 200, 200))

local sH = sec("📜 ROUND HISTORY & ITEMS", 6)
local lHist = lbl(sH, "—", 1, Color3.fromRGB(150, 150, 160))

-- =============================================
-- HELPER STATE
-- =============================================
local STATE = {
    tableId = nil,     -- nil = NOT sitting at a table
    spotIndex = nil,
    maxPlayers = nil,
    live = 0,
    blank = 0,
    history = {},
    round = 0,         -- 0 = in lobby/sitting waiting, > 0 = active match
}

-- =============================================
-- DISPLAY UPDATE
-- =============================================
local function clearDisplay()
    lTable.Text = "⏳ Waiting to join a table..."
    lTable.TextColor3 = Color3.fromRGB(255, 200, 100)
    lSpot.Text = ""
    lOpp.Text = ""
    lLive.Text = "🔴 Live: —"
    lBlank.Text = "⚪ Blank: —"
    lTotal.Text = "📊 Total: —"
    lLP.Text = "🔴 Live: —"
    lBP.Text = "⚪ Blank: —"
    lAdv.Text = "Sit at a table to start tracking"
    lAdv.TextColor3 = Color3.fromRGB(150, 150, 150)
    lTurn.Text = "—"
    lTurn.TextColor3 = Color3.fromRGB(200, 200, 200)
    lHist.Text = "—"
end

local function updateShells()
    -- GUARD 1: Not sitting at any table
    if not STATE.tableId then
        clearDisplay()
        return
    end

    -- GUARD 2: Sitting at a table but match hasn't started yet
    if STATE.round == 0 then
        lLive.Text = "🔴 Live: —"
        lBlank.Text = "⚪ Blank: —"
        lTotal.Text = "📊 Total: —"
        lLP.Text = "🔴 Live: —"
        lBP.Text = "⚪ Blank: —"
        lAdv.Text = "⏳ Waiting for match to start..."
        lAdv.TextColor3 = Color3.fromRGB(255, 200, 100)
        lTurn.Text = "—"
        lTurn.TextColor3 = Color3.fromRGB(200, 200, 200)
        return
    end

    local total = STATE.live + STATE.blank
    lLive.Text = "🔴 Live: " .. STATE.live
    lBlank.Text = "⚪ Blank: " .. STATE.blank
    lTotal.Text = "📊 Total: " .. total

    if total > 0 then
        local lp = math.round(STATE.live / total * 100)
        local bp = math.round(STATE.blank / total * 100)
        lLP.Text = "🔴 Live: " .. lp .. "% (" .. STATE.live .. "/" .. total .. ")"
        lBP.Text = "⚪ Blank: " .. bp .. "% (" .. STATE.blank .. "/" .. total .. ")"

        -- Harmonious Styling
        lLP.TextColor3 = lp >= 60 and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 120, 120)
        lBP.TextColor3 = bp >= 60 and Color3.fromRGB(80, 80, 255) or Color3.fromRGB(120, 120, 255)

        -- Smart Play Advice
        if STATE.live == 0 then
            lAdv.Text = "✅ ALL BLANKS → Shoot YOURSELF!"
            lAdv.TextColor3 = Color3.fromRGB(0, 255, 120)
        elseif STATE.blank == 0 then
            lAdv.Text = "⚠️ ALL LIVE → Shoot OPPONENT!"
            lAdv.TextColor3 = Color3.fromRGB(255, 50, 50)
        elseif total == 1 and STATE.live == 1 then
            lAdv.Text = "⚠️ LAST = LIVE → Shoot OPPONENT!"
            lAdv.TextColor3 = Color3.fromRGB(255, 50, 50)
        elseif total == 1 and STATE.blank == 1 then
            lAdv.Text = "✅ LAST = BLANK → Shoot YOURSELF!"
            lAdv.TextColor3 = Color3.fromRGB(0, 255, 120)
        elseif lp >= 70 then
            lAdv.Text = "🎯 HIGH LIVE (" .. lp .. "%) → Shoot OPPONENT"
            lAdv.TextColor3 = Color3.fromRGB(255, 80, 80)
        elseif bp >= 70 then
            lAdv.Text = "💡 HIGH BLANK (" .. bp .. "%) → Shoot YOURSELF"
            lAdv.TextColor3 = Color3.fromRGB(100, 200, 255)
        else
            lAdv.Text = "🤔 " .. lp .. "/" .. bp .. " → Use items if possible"
            lAdv.TextColor3 = Color3.fromRGB(255, 220, 100)
        end
    else
        lLP.Text = "🔴 Live: —"
        lBP.Text = "⚪ Blank: —"
        lAdv.Text = "⏳ Waiting for shells to be loaded..."
        lAdv.TextColor3 = Color3.fromRGB(160, 160, 160)
    end
end

local function updateHistoryDisplay()
    local lines = {}
    for i = 1, math.min(#STATE.history, 5) do
        local s = STATE.history[i]
        if s.type == "live" then
            table.insert(lines, "🔴 LIVE → " .. tostring(s.target))
        elseif s.type == "blank" then
            table.insert(lines, "⚪ BLANK → " .. tostring(s.target))
        elseif s.type == "inspect" then
            table.insert(lines, s.text)
        end
    end
    lHist.Text = #lines > 0 and table.concat(lines, "\n") or "—"
end

local function addShot(t, target)
    if not STATE.tableId then return end
    table.insert(STATE.history, 1, {type = t, target = target})
    while #STATE.history > 12 do table.remove(STATE.history) end
    updateHistoryDisplay()
end

-- =============================================
-- DETECT TABLE
-- =============================================
local function detectTable()
    if not ClientModule or not ClientModule.GetGameTable then return false end
    local ok, data = ClientModule:GetGameTable()
    if ok and data and data.tableId then
        local wasNil = STATE.tableId == nil
        STATE.tableId = data.tableId
        STATE.spotIndex = data.spotIndex
        STATE.maxPlayers = data.maxPlayers

        lTable.Text = "✅ Table #" .. tostring(data.tableId) .. " (Spot " .. tostring(data.spotIndex) .. ")"
        lTable.TextColor3 = Color3.fromRGB(100, 255, 100)
        lSpot.Text = "Mode: " .. tostring(data.maxPlayers) .. "P"

        -- Opponent Finder
        if data.players then
            local opps = {}
            for _, p in data.players do
                if p.player and p.player ~= LP then
                    local n = "?"
                    if typeof(p.player) == "Instance" then
                        n = p.player.DisplayName or p.player.Name
                    elseif typeof(p.player) == "table" then
                        n = p.player.DisplayName or p.player.Name or "Bot"
                    end
                    table.insert(opps, n)
                end
            end
            lOpp.Text = "vs " .. (#opps > 0 and table.concat(opps, ", ") or "?")
        end

        -- Check if mid-game join/reload
        if STATE.round == 0 then
            local turnUI = PG:FindFirstChild("TurnUI")
            if turnUI and turnUI.Enabled then
                STATE.round = 1
            end
        end

        -- Reset history if just joined table
        if wasNil then
            STATE.history = {}
            STATE.live = 0
            STATE.blank = 0
            lHist.Text = "—"
        end

        updateShells()
        return true
    else
        -- Left table
        if STATE.tableId ~= nil then
            STATE.tableId = nil
            STATE.spotIndex = nil
            STATE.maxPlayers = nil
            STATE.live = 0
            STATE.blank = 0
            STATE.round = 0
            clearDisplay()
        end
        return false
    end
end

-- =============================================
-- ROBUST RE-ENTRANT DIRECT OVERWRITE HOOKS
-- =============================================
_G.BH_Originals = _G.BH_Originals or {}

-- 1) CaptionHandler:DisplayCaption (Syncs round start & magnifying glass inspections!)
_G.BH_Originals["DisplayCaption"] = _G.BH_Originals["DisplayCaption"] or CaptionHandler.DisplayCaption
local origCaption = _G.BH_Originals["DisplayCaption"]
CaptionHandler.DisplayCaption = function(self, data, ...)
    local ok, err = pcall(function()
        if typeof(data) == "table" and data.text then
            local text = data.text:upper()
            
            -- Synced round start shells count (e.g. "3 LIVE ROUNDS. 4 BLANKS.")
            local live = tonumber(string.match(text, "(%d+)%s*LIVE%s*ROUND"))
            local blank = tonumber(string.match(text, "(%d+)%s*BLANK"))
            if live and blank then
                detectTable()
                if STATE.tableId then
                    STATE.live = live
                    STATE.blank = blank
                    STATE.round = 1
                    STATE.history = {}
                    lHist.Text = "—"
                    updateShells()
                    print(string.format("[BH CAPTION] Synced round start: %d live, %d blank", live, blank))
                end
            end
            
            -- Inspected Shell Logger (Magnifying Glass / Burner Phone)
            if string.find(text, "SHELL") and (string.find(text, "LIVE") or string.find(text, "BLANK")) then
                detectTable()
                if STATE.tableId then
                    local cleaned = data.text:upper():gsub("%.", ""):gsub("%s+", " ")
                    table.insert(STATE.history, 1, {type = "inspect", text = "🔍 " .. cleaned})
                    while #STATE.history > 12 do table.remove(STATE.history) end
                    updateHistoryDisplay()
                    print("[BH CAPTION] Synced inspect details: " .. cleaned)
                end
            end
        end
    end)
    if not ok then
        warn("[BH ERROR] DisplayCaption hook failed: " .. tostring(err))
    end
    return origCaption(self, data, ...)
end

-- 2) VisualsHandler:DisplayNewShells (Fallback loads detector)
_G.BH_Originals["DisplayNewShells"] = _G.BH_Originals["DisplayNewShells"] or VisualsHandler.DisplayNewShells
local origDisplay = _G.BH_Originals["DisplayNewShells"]
VisualsHandler.DisplayNewShells = function(self, data, ...)
    local ok, err = pcall(function()
        if typeof(data) == "table" and data.tableId then
            detectTable()
            if STATE.tableId and data.tableId == STATE.tableId then
                if data.action == "revealShells" then
                    STATE.live = data.liveShells or 0
                    STATE.blank = data.blankShells or 0
                    STATE.round = 1
                    STATE.history = {}
                    lHist.Text = "—"
                    updateShells()
                    print(string.format("[BH VISUALS] Synced display shells: %d live, %d blank", STATE.live, STATE.blank))
                end
            end
        end
    end)
    if not ok then
        warn("[BH ERROR] DisplayNewShells hook failed: " .. tostring(err))
    end
    return origDisplay(self, data, ...)
end

-- 3) VisualsHandler:ShootShotgun (Subtracts live/blank counts on shots)
_G.BH_Originals["ShootShotgun"] = _G.BH_Originals["ShootShotgun"] or VisualsHandler.ShootShotgun
local origShoot = _G.BH_Originals["ShootShotgun"]
VisualsHandler.ShootShotgun = function(self, tblId, targetPlayer, isLive, isDead, ...)
    local ok, err = pcall(function()
        detectTable()
        if STATE.tableId and tblId == STATE.tableId then
            local tName = "?"
            if targetPlayer then
                if typeof(targetPlayer) == "Instance" then
                    tName = targetPlayer == LP and "SELF" or (targetPlayer.DisplayName or targetPlayer.Name)
                elseif typeof(targetPlayer) == "table" then
                    tName = targetPlayer.DisplayName or targetPlayer.Name or "Bot"
                end
            else
                tName = "SELF"
            end

            if isLive then
                STATE.live = math.max(0, STATE.live - 1)
                addShot("live", tName)
                
                -- Premium flash feedback
                mainStroke.Color = Color3.fromRGB(255, 0, 0)
                mainStroke.Thickness = 4
                task.delay(0.5, function()
                    mainStroke.Color = Color3.fromRGB(220, 50, 50)
                    mainStroke.Thickness = 2
                end)
            else
                STATE.blank = math.max(0, STATE.blank - 1)
                addShot("blank", tName)
            end
            updateShells()
            print(string.format("[BH VISUALS] Synced shot: isLive=%s, target=%s", tostring(isLive), tName))
        end
    end)
    if not ok then
        warn("[BH ERROR] ShootShotgun hook failed: " .. tostring(err))
    end
    return origShoot(self, tblId, targetPlayer, isLive, isDead, ...)
end

-- 4) TurnHandler:StartTurn
_G.BH_Originals["StartTurn"] = _G.BH_Originals["StartTurn"] or TurnHandler.StartTurn
local origStartTurn = _G.BH_Originals["StartTurn"]
TurnHandler.StartTurn = function(self, ...)
    pcall(function()
        lTurn.Text = "🟢 YOUR TURN!"
        lTurn.TextColor3 = Color3.fromRGB(0, 255, 100)
        
        if STATE.live + STATE.blank > 0 then
            task.spawn(function()
                for i = 1, 3 do
                    lAdv.TextColor3 = Color3.fromRGB(255, 220, 0)
                    task.wait(0.15)
                    updateShells()
                    task.wait(0.15)
                end
            end)
        end
    end)
    return origStartTurn(self, ...)
end

-- 5) TurnHandler:EndTurn
_G.BH_Originals["EndTurn"] = _G.BH_Originals["EndTurn"] or TurnHandler.EndTurn
local origEndTurn = _G.BH_Originals["EndTurn"]
TurnHandler.EndTurn = function(self, ...)
    pcall(function()
        lTurn.Text = "⏳ Opponent's turn"
        lTurn.TextColor3 = Color3.fromRGB(180, 180, 180)
    end)
    return origEndTurn(self, ...)
end

-- 6) TurnHandler:SetTurnText
_G.BH_Originals["SetTurnText"] = _G.BH_Originals["SetTurnText"] or TurnHandler.SetTurnText
local origSetTurnText = _G.BH_Originals["SetTurnText"]
TurnHandler.SetTurnText = function(self, enabled, player, ...)
    pcall(function()
        if enabled then
            if player == LP then
                lTurn.Text = "🟢 YOUR TURN!"
                lTurn.TextColor3 = Color3.fromRGB(0, 255, 100)
            else
                local name = "Opponent"
                if player then
                    if typeof(player) == "Instance" then
                        name = player.DisplayName or player.Name
                    elseif typeof(player) == "table" then
                        name = player.DisplayName or player.Name or "Bot"
                    end
                end
                lTurn.Text = "⏳ " .. name .. "'s turn"
                lTurn.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
        else
            lTurn.Text = "—"
            lTurn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
    return origSetTurnText(self, enabled, player, ...)
end

-- 7) GameHandler:StartGame
_G.BH_Originals["StartGame"] = _G.BH_Originals["StartGame"] or GameHandler.StartGame
local origStartGame = _G.BH_Originals["StartGame"]
GameHandler.StartGame = function(self, ...)
    pcall(function()
        STATE.history = {}
        STATE.live = 0
        STATE.blank = 0
        STATE.round = 1
        lHist.Text = "—"
        detectTable()
        updateShells()
    end)
    return origStartGame(self, ...)
end

-- 8) GameHandler:EndGame
_G.BH_Originals["EndGame"] = _G.BH_Originals["EndGame"] or GameHandler.EndGame
local origEndGame = _G.BH_Originals["EndGame"]
GameHandler.EndGame = function(self, ...)
    pcall(function()
        STATE.tableId = nil
        STATE.spotIndex = nil
        STATE.maxPlayers = nil
        STATE.live = 0
        STATE.blank = 0
        STATE.round = 0
        clearDisplay()
    end)
    return origEndGame(self, ...)
end

-- =============================================
-- FALLBACK AND POLLING
-- =============================================
task.spawn(function()
    while SG.Parent do
        detectTable()
        
        -- Read 4P Tracker if active
        if STATE.tableId and STATE.round > 0 then
            pcall(function()
                local ui = PG:FindFirstChild("ShellTrackerUI")
                if ui and ui.Enabled == true then
                    local info = ui.container.infoContainer
                    local lc = tonumber(info.live.counter.Text) or 0
                    local bc = tonumber(info.blank.counter.Text) or 0
                    if lc ~= STATE.live or bc ~= STATE.blank then
                        STATE.live = lc
                        STATE.blank = bc
                        updateShells()
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- Initial Detection
clearDisplay()
detectTable()

local count = 0
for _ in pairs(_G.BH_Originals) do count += 1 end
print("[BH] v5 loaded successfully | Overwrote " .. count .. " functions! Active Table: " .. tostring(STATE.tableId))
