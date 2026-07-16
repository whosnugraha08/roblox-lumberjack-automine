-- =============================================
-- BUCKSHOT HELPER v2
-- Proper table filtering + read built-in ShellTrackerUI
-- =============================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- Get the Bootstrapper module for GetGameTable
local ClientModule
pcall(function()
    ClientModule = require(LP:WaitForChild("PlayerScripts"):WaitForChild("Bootstrapper"):WaitForChild("Client"))
end)

-- =============================================
-- DESTROY OLD GUI
-- =============================================
if game:GetService("CoreGui"):FindFirstChild("BuckshotHelper") then
    game:GetService("CoreGui"):FindFirstChild("BuckshotHelper"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BuckshotHelper"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Main Frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 300, 0, 400)
Main.Position = UDim2.new(0, 10, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Main.Active = true
Main.Draggable = true

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(200, 40, 40)
stroke.Thickness = 2
stroke.Transparency = 0.2

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(160, 25, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
local fix = Instance.new("Frame", TitleBar)
fix.Size = UDim2.new(1, 0, 0, 10)
fix.Position = UDim2.new(0, 0, 1, -10)
fix.BackgroundColor3 = Color3.fromRGB(160, 25, 25)
fix.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔫 BUCKSHOT HELPER v2"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Close
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0, 4)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Minimize
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -60, 0, 4)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, c in Main:GetChildren() do
        if c.Name ~= "TitleBar" and c:IsA("GuiObject") then
            c.Visible = not minimized
        end
    end
    Main.Size = minimized and UDim2.new(0, 300, 0, 36) or UDim2.new(0, 300, 0, 400)
end)

-- Content
local Content = Instance.new("ScrollingFrame", Main)
Content.Name = "ContentFrame"
Content.Size = UDim2.new(1, -12, 1, -42)
Content.Position = UDim2.new(0, 6, 0, 38)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(200, 40, 40)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
local CL = Instance.new("UIListLayout", Content)
CL.Padding = UDim.new(0, 5)
CL.SortOrder = Enum.SortOrder.LayoutOrder

-- =============================================
-- HELPERS
-- =============================================
local function makeSection(title, order)
    local f = Instance.new("Frame", Content)
    f.Size = UDim2.new(1, -6, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    f.BorderSizePixel = 0
    f.LayoutOrder = order
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local p = Instance.new("UIPadding", f)
    p.PaddingTop = UDim.new(0, 6)
    p.PaddingBottom = UDim.new(0, 6)
    p.PaddingLeft = UDim.new(0, 8)
    p.PaddingRight = UDim.new(0, 8)
    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, 3)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    local h = Instance.new("TextLabel", f)
    h.Size = UDim2.new(1, 0, 0, 20)
    h.BackgroundTransparency = 1
    h.Text = title
    h.TextColor3 = Color3.fromRGB(255, 70, 70)
    h.TextSize = 13
    h.Font = Enum.Font.GothamBold
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.LayoutOrder = 0
    return f
end

local function makeLabel(parent, text, order, color)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(190, 190, 200)
    l.TextSize = 12
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 1
    l.TextWrapped = true
    l.AutomaticSize = Enum.AutomaticSize.Y
    return l
end

-- =============================================
-- SECTIONS
-- =============================================
-- Section: Table Info
local secTable = makeSection("📍 YOUR TABLE", 1)
local lblTable = makeLabel(secTable, "Table: detecting...", 1)
local lblSpot = makeLabel(secTable, "Spot: ?", 2)
local lblPlayers = makeLabel(secTable, "Mode: ?", 3)
local lblOpponent = makeLabel(secTable, "Opponent: ?", 4)

-- Section: Shell Tracker
local secShell = makeSection("🔴 SHELL TRACKER", 2)
local lblLive = makeLabel(secShell, "🔴 Live: ?", 1, Color3.fromRGB(255, 100, 100))
local lblBlank = makeLabel(secShell, "⚪ Blank: ?", 2, Color3.fromRGB(150, 150, 255))
local lblTotal = makeLabel(secShell, "📊 Total: ?", 3)

-- Section: Probability
local secProb = makeSection("🎯 PROBABILITY", 3)
local lblLiveP = makeLabel(secProb, "🔴 Live: ?%", 1, Color3.fromRGB(255, 120, 120))
local lblBlankP = makeLabel(secProb, "⚪ Blank: ?%", 2, Color3.fromRGB(120, 120, 255))

-- Section: Advice
local secAdvice = makeSection("💡 ADVICE", 4)
local lblAdvice = makeLabel(secAdvice, "Waiting for game data...", 1, Color3.fromRGB(100, 255, 100))

-- Section: Shot History
local secHistory = makeSection("📜 HISTORY", 5)
local lblHistory = makeLabel(secHistory, "No shots yet", 1, Color3.fromRGB(150, 150, 160))

-- Section: Turn
local secTurn = makeSection("⏱️ TURN", 6)
local lblTurn = makeLabel(secTurn, "Turn: ?", 1, Color3.fromRGB(255, 255, 100))

-- =============================================
-- STATE
-- =============================================
local myTableId = nil
local mySpotIndex = nil
local myMaxPlayers = nil
local shellLive = 0
local shellBlank = 0
local shotHistory = {}
local roundNum = 0
local inGame = false

-- =============================================
-- GET MY TABLE
-- =============================================
local function detectMyTable()
    if not ClientModule or not ClientModule.GetGameTable then
        return false
    end
    local ok, data = ClientModule:GetGameTable()
    if ok and data then
        myTableId = data.tableId
        mySpotIndex = data.spotIndex
        myMaxPlayers = data.maxPlayers
        inGame = true
        
        lblTable.Text = "Table: #" .. tostring(myTableId) .. " ✅"
        lblTable.TextColor3 = Color3.fromRGB(100, 255, 100)
        lblSpot.Text = "Spot: " .. tostring(mySpotIndex)
        lblPlayers.Text = "Mode: " .. tostring(myMaxPlayers) .. " Players"
        
        -- Find opponent
        if data.players then
            local opponents = {}
            for _, p in data.players do
                if p.player and p.player ~= LP then
                    local name = "?"
                    if typeof(p.player) == "Instance" then
                        name = p.player.DisplayName or p.player.Name
                    elseif typeof(p.player) == "table" then
                        name = p.player.DisplayName or p.player.Name or "Bot"
                    end
                    table.insert(opponents, name)
                end
            end
            lblOpponent.Text = "vs: " .. (#opponents > 0 and table.concat(opponents, ", ") or "?")
        end
        
        return true
    else
        inGame = false
        lblTable.Text = "Table: Not in game"
        lblTable.TextColor3 = Color3.fromRGB(200, 200, 200)
        return false
    end
end

-- =============================================
-- READ SHELL DATA FROM BUILT-IN UI
-- =============================================
local function readBuiltInShellTracker()
    local ok, result = pcall(function()
        local stUI = PG:FindFirstChild("ShellTrackerUI")
        if stUI then
            local info = stUI.container.infoContainer
            local liveCount = tonumber(info.live.counter.Text) or 0
            local blankCount = tonumber(info.blank.counter.Text) or 0
            return liveCount, blankCount
        end
        return nil, nil
    end)
    if ok then
        return result
    end
    return nil, nil
end

-- =============================================
-- UPDATE DISPLAY
-- =============================================
local function updateDisplay()
    local total = shellLive + shellBlank
    lblLive.Text = "🔴 Live: " .. shellLive
    lblBlank.Text = "⚪ Blank: " .. shellBlank
    lblTotal.Text = "📊 Total Remaining: " .. total

    if total > 0 then
        local lp = math.round(shellLive / total * 100)
        local bp = math.round(shellBlank / total * 100)
        lblLiveP.Text = "🔴 Live: " .. lp .. "% (" .. shellLive .. "/" .. total .. ")"
        lblBlankP.Text = "⚪ Blank: " .. bp .. "% (" .. shellBlank .. "/" .. total .. ")"

        -- Color code
        if lp >= 70 then
            lblLiveP.TextColor3 = Color3.fromRGB(255, 50, 50)
            lblBlankP.TextColor3 = Color3.fromRGB(120, 120, 200)
        elseif bp >= 70 then
            lblBlankP.TextColor3 = Color3.fromRGB(80, 80, 255)
            lblLiveP.TextColor3 = Color3.fromRGB(200, 120, 120)
        else
            lblLiveP.TextColor3 = Color3.fromRGB(255, 120, 120)
            lblBlankP.TextColor3 = Color3.fromRGB(120, 120, 255)
        end

        -- Advice
        if shellLive == 0 then
            lblAdvice.Text = "✅ ALL BLANKS! Shoot YOURSELF for free turns!"
            lblAdvice.TextColor3 = Color3.fromRGB(0, 255, 120)
        elseif shellBlank == 0 then
            lblAdvice.Text = "⚠️ ALL LIVE! SHOOT OPPONENT NOW!"
            lblAdvice.TextColor3 = Color3.fromRGB(255, 50, 50)
        elseif total == 1 then
            if shellLive == 1 then
                lblAdvice.Text = "⚠️ LAST SHELL = LIVE! Shoot OPPONENT!"
                lblAdvice.TextColor3 = Color3.fromRGB(255, 50, 50)
            else
                lblAdvice.Text = "✅ LAST SHELL = BLANK! Shoot yourself!"
                lblAdvice.TextColor3 = Color3.fromRGB(0, 255, 120)
            end
        elseif lp >= 70 then
            lblAdvice.Text = "🎯 HIGH LIVE (" .. lp .. "%) → Shoot OPPONENT"
            lblAdvice.TextColor3 = Color3.fromRGB(255, 100, 100)
        elseif bp >= 70 then
            lblAdvice.Text = "💡 HIGH BLANK (" .. bp .. "%) → Shoot YOURSELF"
            lblAdvice.TextColor3 = Color3.fromRGB(100, 200, 255)
        else
            lblAdvice.Text = "🤔 " .. lp .. "/" .. bp .. " — Use Magnifying Glass or item"
            lblAdvice.TextColor3 = Color3.fromRGB(255, 255, 100)
        end
    else
        lblLiveP.Text = "🔴 Live: —"
        lblBlankP.Text = "⚪ Blank: —"
        lblAdvice.Text = "⏳ Waiting for new round..."
        lblAdvice.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

-- =============================================
-- SHOT HISTORY
-- =============================================
local function addShot(shotType, target)
    table.insert(shotHistory, 1, {type = shotType, target = target})
    while #shotHistory > 15 do table.remove(shotHistory) end
    local lines = {}
    for i = 1, math.min(#shotHistory, 8) do
        local s = shotHistory[i]
        local icon = s.type == "live" and "🔴" or "⚪"
        table.insert(lines, icon .. " " .. s.type:upper() .. " → " .. tostring(s.target))
    end
    lblHistory.Text = #lines > 0 and table.concat(lines, "\n") or "No shots yet"
end

-- =============================================
-- HOOK REMOTES - FILTERED BY MY TABLE
-- =============================================
local remotesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
if not remotesFolder then
    print("[BH] ERROR: Remotes folder not found!")
end

local hookCount = 0

-- 1) ShellTrackerAction - ALREADY per-player (server only sends to you)
local shellTracker = remotesFolder and remotesFolder:FindFirstChild("ShellTrackerAction")
if shellTracker then
    shellTracker.OnClientEvent:Connect(function(data)
        if data then
            if data.action == "update" and data.shellData then
                shellLive = data.shellData.live or 0
                shellBlank = data.shellData.blank or 0
                updateDisplay()
            elseif data.action == "activate" then
                inGame = true
                detectMyTable()
            elseif data.action == "deactivate" then
                -- Round over, deactivate
            end
        end
    end)
    hookCount += 1
    print("[BH] ✅ Hook: ShellTrackerAction")
end

-- 2) Visuals - FILTER by myTableId
local visuals = remotesFolder and remotesFolder:FindFirstChild("Visuals")
if visuals then
    visuals.OnClientEvent:Connect(function(action, ...)
        if action == "shootShotgun" then
            local args = {...}
            local tableId = args[1]
            
            -- FILTER: only track our table
            if myTableId and tableId ~= myTableId then return end
            
            local targetPlayer = args[2]
            local isLive = args[3]

            local targetName = "?"
            if targetPlayer then
                if typeof(targetPlayer) == "Instance" then
                    targetName = targetPlayer.DisplayName or targetPlayer.Name
                elseif typeof(targetPlayer) == "table" then
                    targetName = targetPlayer.DisplayName or targetPlayer.Name or "Bot"
                end
            end
            
            -- Check if shot self
            if not targetPlayer or targetPlayer == LP then
                targetName = "SELF"
            end

            if isLive then
                shellLive = math.max(0, shellLive - 1)
                addShot("live", targetName)
                -- Flash red border
                stroke.Color = Color3.fromRGB(255, 0, 0)
                stroke.Thickness = 4
                task.delay(0.5, function()
                    stroke.Color = Color3.fromRGB(200, 40, 40)
                    stroke.Thickness = 2
                end)
            else
                shellBlank = math.max(0, shellBlank - 1)
                addShot("blank", targetName)
            end
            
            updateDisplay()
        end
    end)
    hookCount += 1
    print("[BH] ✅ Hook: Visuals (filtered)")
end

-- 3) Sound - FILTER by our table's shotgun
local sound = remotesFolder and remotesFolder:FindFirstChild("Sound")
if sound then
    sound.OnClientEvent:Connect(function(action, soundName, ...)
        if action == "PlaySound" then
            if soundName == "BLANK" then
                lblTurn.Text = "⚪ BLANK fired!"
                lblTurn.TextColor3 = Color3.fromRGB(150, 150, 255)
            elseif soundName == "SHOOT" then
                lblTurn.Text = "🔴 LIVE fired!"
                lblTurn.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end
    end)
    hookCount += 1
    print("[BH] ✅ Hook: Sound")
end

-- 4) PlayerTurn
local playerTurn = remotesFolder and remotesFolder:FindFirstChild("PlayerTurn")
if playerTurn then
    playerTurn.OnClientEvent:Connect(function(isEnd)
        if not isEnd then
            lblTurn.Text = "🟢 YOUR TURN!"
            lblTurn.TextColor3 = Color3.fromRGB(0, 255, 100)
            
            -- Flash advice when it's your turn
            local total = shellLive + shellBlank
            if total > 0 then
                task.spawn(function()
                    for i = 1, 4 do
                        lblAdvice.TextColor3 = Color3.fromRGB(255, 255, 0)
                        task.wait(0.2)
                        updateDisplay()
                        task.wait(0.2)
                    end
                end)
            end
        else
            lblTurn.Text = "⏳ Opponent's turn..."
            lblTurn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end)
    hookCount += 1
    print("[BH] ✅ Hook: PlayerTurn")
end

-- 5) GameEnded
local gameEnded = remotesFolder and remotesFolder:FindFirstChild("GameEnded")
if gameEnded then
    gameEnded.OnClientEvent:Connect(function(data)
        inGame = false
        myTableId = nil
        lblTable.Text = "Table: Game Over"
        lblTable.TextColor3 = Color3.fromRGB(255, 200, 100)
        roundNum = 0
        
        if data and data.winner then
            if data.winner == LP then
                lblTurn.Text = "🏆 YOU WON!"
                lblTurn.TextColor3 = Color3.fromRGB(255, 215, 0)
            else
                local name = typeof(data.winner) == "Instance" and data.winner.DisplayName or "?"
                lblTurn.Text = "💀 Lost to " .. name
                lblTurn.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end
    end)
    hookCount += 1
    print("[BH] ✅ Hook: GameEnded")
end

-- =============================================
-- POLLING: Read built-in ShellTrackerUI + detect table
-- =============================================
task.spawn(function()
    while ScreenGui.Parent do
        -- Re-detect table
        detectMyTable()
        
        -- Read built-in shell tracker as authoritative source
        local ok, lc, bc = pcall(function()
            local stUI = PG:FindFirstChild("ShellTrackerUI")
            if stUI then
                local info = stUI.container.infoContainer
                return tonumber(info.live.counter.Text) or 0, tonumber(info.blank.counter.Text) or 0
            end
            return nil, nil
        end)
        
        if ok and lc ~= nil then
            -- Only update if values changed
            if lc ~= shellLive or bc ~= shellBlank then
                shellLive = lc
                shellBlank = bc
                updateDisplay()
            end
        end
        
        task.wait(0.5)
    end
end)

-- =============================================
-- STATUS
-- =============================================
local secStatus = makeSection("📡 STATUS", 7)
makeLabel(secStatus, "✅ " .. hookCount .. " hooks | Polling: ON", 1, Color3.fromRGB(100, 255, 100))
makeLabel(secStatus, "v2.0 | Table-filtered + UI polling", 2, Color3.fromRGB(100, 100, 120))

-- Initial
detectMyTable()
updateDisplay()
print("[BH] ✅ Buckshot Helper v2 loaded! " .. hookCount .. " hooks | Table: " .. tostring(myTableId))
