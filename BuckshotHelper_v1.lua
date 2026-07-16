-- =============================================
-- BUCKSHOT HELPER v1
-- Shell Tracker + Probability Calculator + Auto-Play
-- For: 💥 BUCKSHOT (Roblox)
-- =============================================

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- =============================================
-- GUI SETUP
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
Main.Size = UDim2.new(0, 320, 0, 420)
Main.Position = UDim2.new(0.5, -160, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Main.Active = true
Main.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(200, 50, 50)
MainStroke.Thickness = 2
MainStroke.Transparency = 0.3
MainStroke.Parent = Main

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Fix bottom corners of title bar
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🔫 BUCKSHOT HELPER"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -65, 0, 5)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    for _, child in Main:GetChildren() do
        if child.Name ~= "TitleBar" and child:IsA("GuiObject") then
            child.Visible = not isMinimized
        end
    end
    if isMinimized then
        Main.Size = UDim2.new(0, 320, 0, 40)
    else
        Main.Size = UDim2.new(0, 320, 0, 420)
    end
end)

-- Content frame
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -16, 1, -48)
Content.Position = UDim2.new(0, 8, 0, 44)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = Color3.fromRGB(180, 30, 30)
Content.CanvasSize = UDim2.new(0, 0, 0, 600)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

-- =============================================
-- HELPER FUNCTIONS
-- =============================================
local function createSection(title, order)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    section.BorderSizePixel = 0
    section.LayoutOrder = order
    section.Parent = Content

    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 8)
    sc.Parent = section

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = section

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = section

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundTransparency = 1
    header.Text = title
    header.TextColor3 = Color3.fromRGB(255, 80, 80)
    header.TextSize = 14
    header.Font = Enum.Font.GothamBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = 0
    header.Parent = section

    return section
end

local function createLabel(parent, text, order, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(200, 200, 210)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order or 1
    lbl.TextWrapped = true
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.Parent = parent
    return lbl
end

local function createToggle(parent, text, order, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 0, 22)
    btn.Position = UDim2.new(1, -44, 0.5, -11)
    btn.BackgroundColor3 = default and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(80, 80, 90)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = row

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = btn

    local state = default or false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(80, 80, 90)
        if callback then callback(state) end
    end)
    return function() return state end, function(v) 
        state = v
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(80, 80, 90)
    end
end

-- =============================================
-- SECTION 1: SHELL TRACKER (Enhanced)
-- =============================================
local shellSection = createSection("🔴 SHELL TRACKER", 1)

local liveLabel = createLabel(shellSection, "🔴 Live Shells: ?", 1, Color3.fromRGB(255, 100, 100))
local blankLabel = createLabel(shellSection, "⚪ Blank Shells: ?", 2, Color3.fromRGB(180, 180, 255))
local totalLabel = createLabel(shellSection, "📊 Total: ?", 3)
local probLabel = createLabel(shellSection, "🎯 Next Shell Probability:", 4, Color3.fromRGB(255, 200, 80))
local liveProbLabel = createLabel(shellSection, "   🔴 Live: ?%", 5, Color3.fromRGB(255, 120, 120))
local blankProbLabel = createLabel(shellSection, "   ⚪ Blank: ?%", 6, Color3.fromRGB(150, 150, 255))
local adviceLabel = createLabel(shellSection, "💡 Advice: Waiting...", 7, Color3.fromRGB(100, 255, 100))

-- =============================================
-- SECTION 2: SHOT HISTORY
-- =============================================
local historySection = createSection("📜 SHOT HISTORY", 2)
local historyLabel = createLabel(historySection, "No shots recorded yet", 1, Color3.fromRGB(160, 160, 170))

-- =============================================
-- SECTION 3: GAME INFO
-- =============================================
local infoSection = createSection("ℹ️ GAME INFO", 3)
local tableLabel = createLabel(infoSection, "Table: Not in game", 1)
local roundLabel = createLabel(infoSection, "Round: ?", 2)
local livesLabel = createLabel(infoSection, "Your Lives: ?", 3, Color3.fromRGB(100, 255, 100))
local opponentLabel = createLabel(infoSection, "Opponent: ?", 4)
local turnLabel = createLabel(infoSection, "Turn: ?", 5, Color3.fromRGB(255, 255, 100))

-- =============================================
-- SECTION 4: OPTIONS
-- =============================================
local optSection = createSection("⚙️ OPTIONS", 4)

local autoAdvice, setAutoAdvice = createToggle(optSection, "Auto Advice Popup", 1, true)
local soundAlert, setSoundAlert = createToggle(optSection, "Sound Alert (Live Shell)", 2, true)
local espToggle, setEsp = createToggle(optSection, "Table ESP", 3, false)

-- =============================================
-- CORE LOGIC: SHELL TRACKING
-- =============================================
local shellData = {live = 0, blank = 0}
local shotHistory = {}
local roundNumber = 0
local isInGame = false

local function updateDisplay()
    local total = shellData.live + shellData.blank
    
    liveLabel.Text = "🔴 Live Shells: " .. shellData.live
    blankLabel.Text = "⚪ Blank Shells: " .. shellData.blank
    totalLabel.Text = "📊 Total Remaining: " .. total

    if total > 0 then
        local liveProb = math.round(shellData.live / total * 100)
        local blankProb = math.round(shellData.blank / total * 100)
        
        liveProbLabel.Text = "   🔴 Live: " .. liveProb .. "%"
        blankProbLabel.Text = "   ⚪ Blank: " .. blankProb .. "%"

        -- Color code probability
        if liveProb >= 60 then
            liveProbLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            adviceLabel.Text = "💡 HIGH LIVE CHANCE! Shoot OPPONENT!"
            adviceLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        elseif blankProb >= 60 then
            blankProbLabel.TextColor3 = Color3.fromRGB(100, 100, 255)
            adviceLabel.Text = "💡 HIGH BLANK CHANCE! Shoot YOURSELF (free turn)!"
            adviceLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        else
            adviceLabel.Text = "💡 50/50 - Use items if available"
            adviceLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
        end

        -- Special cases
        if shellData.live == 0 then
            adviceLabel.Text = "💡 ALL BLANKS! Shoot yourself for free turns!"
            adviceLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        elseif shellData.blank == 0 then
            adviceLabel.Text = "⚠️ ALL LIVE! Shoot OPPONENT!"
            adviceLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        elseif total == 1 then
            if shellData.live == 1 then
                adviceLabel.Text = "⚠️ LAST SHELL IS LIVE! Shoot OPPONENT!"
                adviceLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            else
                adviceLabel.Text = "💡 LAST SHELL IS BLANK! Shoot YOURSELF!"
                adviceLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
            end
        end
    else
        liveProbLabel.Text = "   🔴 Live: -"
        blankProbLabel.Text = "   ⚪ Blank: -"
        adviceLabel.Text = "💡 Waiting for new round..."
        adviceLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function addShotToHistory(shotType, target)
    table.insert(shotHistory, {
        type = shotType,
        target = target or "?",
        time = os.clock()
    })
    
    -- Keep last 20
    while #shotHistory > 20 do
        table.remove(shotHistory, 1)
    end

    -- Update display
    local lines = {}
    for i = #shotHistory, math.max(1, #shotHistory - 9), -1 do
        local s = shotHistory[i]
        local icon = s.type == "live" and "🔴" or "⚪"
        table.insert(lines, icon .. " " .. s.type:upper() .. " → " .. tostring(s.target))
    end
    historyLabel.Text = #lines > 0 and table.concat(lines, "\n") or "No shots recorded"
end

-- =============================================
-- HOOK: ShellTrackerAction
-- =============================================
local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    or LP:WaitForChild("PlayerScripts"):FindFirstChild("Bootstrapper")
       and LP.PlayerScripts.Bootstrapper:FindFirstChild("Client")

-- Find remotes folder
local remotesFolder
pcall(function()
    -- Try to find via the bootstrapper module
    local bootstrapper = LP:WaitForChild("PlayerScripts"):WaitForChild("Bootstrapper")
    local client = bootstrapper:WaitForChild("Client")
    
    -- The game uses a custom remotes reference, find it in ReplicatedStorage
    remotesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
end)

if not remotesFolder then
    -- Fallback: search for Remotes folder
    for _, v in game:GetService("ReplicatedStorage"):GetDescendants() do
        if v.Name == "Remotes" and v:IsA("Folder") then
            remotesFolder = v
            break
        end
    end
end

-- Hook ShellTrackerAction
local shellTrackerRemote = remotesFolder and remotesFolder:FindFirstChild("ShellTrackerAction")
if shellTrackerRemote then
    shellTrackerRemote.OnClientEvent:Connect(function(data)
        print("[BuckshotHelper] ShellTrackerAction:", data)
        if data and data.action == "update" and data.shellData then
            shellData.live = data.shellData.live or 0
            shellData.blank = data.shellData.blank or 0
            updateDisplay()
        elseif data and data.action == "activate" then
            isInGame = true
            tableLabel.Text = "Table: IN GAME ✅"
        elseif data and data.action == "deactivate" then
            isInGame = false
            tableLabel.Text = "Table: Not in game"
        end
    end)
    print("[BuckshotHelper] ✅ Hooked ShellTrackerAction")
end

-- Hook ShellsRefreshed (for initial shell count)
local shellsRefreshed = remotesFolder and remotesFolder:FindFirstChild("ShellsRefreshed")
if shellsRefreshed then
    shellsRefreshed.OnClientEvent:Connect(function(data)
        print("[BuckshotHelper] ShellsRefreshed:", data)
        if data then
            if data.liveShells and data.blankShells then
                shellData.live = data.liveShells
                shellData.blank = data.blankShells
                roundNumber = roundNumber + 1
                roundLabel.Text = "Round: " .. roundNumber
                shotHistory = {} -- Reset history for new round
                historyLabel.Text = "New round started!"
                updateDisplay()
            end
        end
    end)
    print("[BuckshotHelper] ✅ Hooked ShellsRefreshed")
end

-- Hook Visuals for shot results
local visualsRemote = remotesFolder and remotesFolder:FindFirstChild("Visuals")
if visualsRemote then
    visualsRemote.OnClientEvent:Connect(function(action, ...)
        if action == "shootShotgun" then
            local args = {...}
            -- args: tableId, targetPlayer, isLive, wasShotgunSawed, monitorData, shotgunModel, maxPlayers
            local tableId = args[1]
            local targetPlayer = args[2]
            local isLive = args[3]
            
            local targetName = "?"
            if targetPlayer then
                if typeof(targetPlayer) == "Instance" then
                    targetName = targetPlayer.DisplayName or targetPlayer.Name
                elseif typeof(targetPlayer) == "table" then
                    targetName = targetPlayer.DisplayName or targetPlayer.Name or "Bot"
                end
            else
                targetName = "Self"
            end
            
            if isLive then
                shellData.live = math.max(0, shellData.live - 1)
                addShotToHistory("live", targetName)
                
                -- Alert
                if soundAlert() then
                    -- Flash the border red
                    MainStroke.Color = Color3.fromRGB(255, 0, 0)
                    MainStroke.Thickness = 4
                    task.delay(0.5, function()
                        MainStroke.Color = Color3.fromRGB(200, 50, 50)
                        MainStroke.Thickness = 2
                    end)
                end
            else
                shellData.blank = math.max(0, shellData.blank - 1)
                addShotToHistory("blank", targetName)
            end
            
            updateDisplay()
        end
    end)
    print("[BuckshotHelper] ✅ Hooked Visuals (shot tracking)")
end

-- Hook Sound for additional shot detection
local soundRemote = remotesFolder and remotesFolder:FindFirstChild("Sound")
if soundRemote then
    soundRemote.OnClientEvent:Connect(function(action, soundName, ...)
        if action == "PlaySound" then
            if soundName == "BLANK" then
                -- A blank was just fired (backup detection)
                turnLabel.Text = "Turn: Blank fired!"
                turnLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
            elseif soundName == "SHOOT" then
                turnLabel.Text = "Turn: Live fired!"
                turnLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end
    end)
end

-- Hook GameStartedAsync
local gameStarted = remotesFolder and remotesFolder:FindFirstChild("GameStartedAsync")
if gameStarted and gameStarted:IsA("RemoteFunction") then
    -- We can't hook OnClientInvoke if it's already set, but we can wrap it
    print("[BuckshotHelper] GameStartedAsync found (RemoteFunction)")
end

-- Hook PlayerTurn for turn tracking
local playerTurn = remotesFolder and remotesFolder:FindFirstChild("PlayerTurn")
if playerTurn then
    playerTurn.OnClientEvent:Connect(function(isEnd)
        if not isEnd then
            turnLabel.Text = "Turn: YOUR TURN! 🎯"
            turnLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            
            -- Pulse the advice
            if autoAdvice() then
                local total = shellData.live + shellData.blank
                if total > 0 then
                    local liveProb = shellData.live / total * 100
                    -- Flash advice
                    for i = 1, 3 do
                        task.delay(i * 0.3, function()
                            adviceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                            task.wait(0.15)
                            updateDisplay()
                        end)
                    end
                end
            end
        else
            turnLabel.Text = "Turn: Opponent's turn"
            turnLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
    print("[BuckshotHelper] ✅ Hooked PlayerTurn")
end

-- Hook LivesUpdatedAsync
local livesRemote = remotesFolder and remotesFolder:FindFirstChild("LivesUpdatedAsync")
if livesRemote then
    -- Can't easily hook RemoteFunction OnClientInvoke if already set
    -- We'll monitor via attributes instead
    print("[BuckshotHelper] LivesUpdatedAsync found")
end

-- Hook GameEnded
local gameEnded = remotesFolder and remotesFolder:FindFirstChild("GameEnded")
if gameEnded then
    gameEnded.OnClientEvent:Connect(function(data)
        isInGame = false
        tableLabel.Text = "Table: Game Over"
        roundNumber = 0
        roundLabel.Text = "Round: Game Over"
        
        if data then
            local winner = data.winner
            if winner then
                local winnerName = "?"
                if typeof(winner) == "Instance" then
                    winnerName = winner.DisplayName or winner.Name
                end
                if winner == LP then
                    turnLabel.Text = "🏆 YOU WON!"
                    turnLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                else
                    turnLabel.Text = "💀 You lost to " .. winnerName
                    turnLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                end
            end
        end
    end)
    print("[BuckshotHelper] ✅ Hooked GameEnded")
end

-- =============================================
-- TABLE ESP
-- =============================================
local espHighlights = {}

local function updateESP()
    -- Clean old
    for _, h in espHighlights do
        if h and h.Parent then h:Destroy() end
    end
    espHighlights = {}
    
    if not espToggle() then return end
    
    local gamespace = workspace:FindFirstChild("gamespace")
    if not gamespace then return end
    local tables = gamespace:FindFirstChild("tables")
    if not tables then return end
    
    for _, tbl in tables:GetChildren() do
        local seats = tbl:FindFirstChild("spots")
        if seats then
            local occupied = false
            for _, spot in seats:GetChildren() do
                if spot:FindFirstChildOfClass("Weld") then
                    occupied = true
                    break
                end
            end
            
            if occupied then
                local hl = Instance.new("Highlight")
                hl.Name = "BH_ESP"
                hl.FillColor = Color3.fromRGB(255, 50, 50)
                hl.FillTransparency = 0.85
                hl.OutlineColor = Color3.fromRGB(255, 100, 100)
                hl.OutlineTransparency = 0.3
                hl.Adornee = tbl
                hl.Parent = game:GetService("CoreGui")
                table.insert(espHighlights, hl)
            end
        end
    end
end

-- ESP loop
task.spawn(function()
    while ScreenGui.Parent do
        if espToggle() then
            updateESP()
        else
            for _, h in espHighlights do
                if h and h.Parent then h:Destroy() end
            end
            espHighlights = {}
        end
        task.wait(2)
    end
end)

-- =============================================
-- MONITOR PLAYER LIVES VIA ATTRIBUTES
-- =============================================
task.spawn(function()
    while ScreenGui.Parent do
        pcall(function()
            local lives = LP:GetAttribute("lives")
            if lives then
                livesLabel.Text = "Your Lives: " .. tostring(lives) .. " ❤️"
            end
        end)
        task.wait(1)
    end
end)

-- =============================================
-- STATUS BAR
-- =============================================
local statusSection = createSection("📡 STATUS", 5)
local statusLabel = createLabel(statusSection, "Initializing...", 1, Color3.fromRGB(100, 255, 100))

local hookedCount = 0
if shellTrackerRemote then hookedCount = hookedCount + 1 end
if shellsRefreshed then hookedCount = hookedCount + 1 end
if visualsRemote then hookedCount = hookedCount + 1 end
if playerTurn then hookedCount = hookedCount + 1 end
if gameEnded then hookedCount = hookedCount + 1 end

statusLabel.Text = "✅ " .. hookedCount .. " remotes hooked | Tracking active"

-- Version info
createLabel(statusSection, "v1.0 | Buckshot Helper", 2, Color3.fromRGB(100, 100, 120))

-- =============================================
-- INITIAL UPDATE
-- =============================================
updateDisplay()
print("[BuckshotHelper] ✅ Loaded successfully! " .. hookedCount .. " hooks active.")
