-- =============================================
-- INDOPOLY CHEAT SUITE v4.1
-- by Antigravity AI
-- =============================================
-- FIXES v4.1:
--   - Quiz UI sekarang auto-tutup setelah jawab
--   - Option jawaban berubah hijau sebelum tutup
--   - Auto-buy beli level tertinggi yang MAMPU
-- =============================================
-- PENTING: Coins ≠ Money
--   Coins = mata uang GLOBAL (tetap antar game)
--   Money = uang DALAM GAME monopoly (reset tiap round)
--   Script ini membantu kamu menang lebih sering
--   = lebih banyak Coins dari misi/quest
-- =============================================

-- Cleanup previous instance
if _G.IndopolyCheat then
    if _G.IndopolyCheat.Connections then
        for _, conn in pairs(_G.IndopolyCheat.Connections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    if _G.IndopolyCheat.GUI then
        pcall(function() _G.IndopolyCheat.GUI:Destroy() end)
    end
    _G.IndopolyCheat.Active = false
    task.wait(0.3)
end

-- Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RE = RS:WaitForChild("RemoteEvents")
local LP = Players.LocalPlayer

-- State
_G.IndopolyCheat = {
    Active = true,
    Connections = {},
    QuizAutoAnswer = true,
    AutoBuyEnabled = true,
    AutoClaimQuest = true,
    DiceTracker = true,
    MoneyTracker = true,
    QuizCount = 0,
    QuizCorrect = 0,
    MoneyGained = 0,
    MoneyLost = 0,
    PropertiesBought = 0,
    GUI = nil,
}
local C = _G.IndopolyCheat
local conns = C.Connections

-- =============================================
-- GUI CREATION
-- =============================================
local function createGUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "IndopolyCheatGUI"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    sg.Parent = LP:WaitForChild("PlayerGui")
    C.GUI = sg

    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 220, 0, 330)
    main.Position = UDim2.new(1, -230, 0, 10)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = sg

    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", main)
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Transparency = 0.3

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 10)
    titleFix.Position = UDim2.new(0, 0, 1, -10)
    titleFix.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -30, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎮 INDOPOLY CHEAT v4.1"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Minimize Button
    local minimized = false
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 24, 0, 24)
    minBtn.Position = UDim2.new(1, -28, 0, 4)
    minBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.new(1, 1, 1)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.Parent = titleBar
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

    -- Content Frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 1, -42)
    content.Position = UDim2.new(0, 8, 0, 36)
    content.BackgroundTransparency = 1
    content.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    -- Toggle Button Factory
    local function createToggle(name, text, default, order)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(120, 30, 30)
        btn.Text = (default and "✅ " or "❌ ") .. text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.LayoutOrder = order
        btn.Parent = content
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            C[name] = state
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(120, 30, 30)
            btn.Text = (state and "✅ " or "❌ ") .. text
        end)
        return btn
    end

    createToggle("QuizAutoAnswer", "Quiz Auto-Answer", true, 1)
    createToggle("AutoBuyEnabled", "Auto-Buy Property", true, 2)
    createToggle("DiceTracker", "Dice Tracker", true, 3)
    createToggle("MoneyTracker", "Money Tracker", true, 4)
    createToggle("AutoClaimQuest", "Auto-Claim Quest", true, 5)

    -- Stats Label
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "Stats"
    statsLabel.Size = UDim2.new(1, 0, 0, 90)
    statsLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statsLabel.Font = Enum.Font.GothamMedium
    statsLabel.TextSize = 11
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.TextYAlignment = Enum.TextYAlignment.Top
    statsLabel.LayoutOrder = 6
    statsLabel.Parent = content
    Instance.new("UICorner", statsLabel).CornerRadius = UDim.new(0, 6)
    local pad = Instance.new("UIPadding", statsLabel)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 5)

    -- Update stats loop
    task.spawn(function()
        while C.Active and sg.Parent do
            local ls = LP:FindFirstChild("leaderstats")
            local coins = ls and ls:FindFirstChild("Coins") and ls.Coins.Value or 0
            local wins = ls and ls:FindFirstChild("Wins") and ls.Wins.Value or 0
            local stats = LP:FindFirstChild("InternalStats")
            local gameMoney = stats and stats:FindFirstChild("Money") and stats.Money.Value or 0
            statsLabel.Text = string.format(
                "🪙 Coins: %s  |  🏆 Wins: %d\n💵 Game Money: Rp %s\n🧠 Quiz: %d/%d benar\n🏠 Properties: %d dibeli\n📈 +%s  📉 -%s",
                tostring(coins), wins,
                tostring(gameMoney),
                C.QuizCorrect, C.QuizCount,
                C.PropertiesBought,
                tostring(C.MoneyGained),
                tostring(C.MoneyLost)
            )
            task.wait(1)
        end
    end)

    -- Minimize toggle
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        content.Visible = not minimized
        if minimized then
            main.Size = UDim2.new(0, 220, 0, 36)
            minBtn.Text = "+"
        else
            main.Size = UDim2.new(0, 220, 0, 330)
            minBtn.Text = "—"
        end
    end)

    return sg
end

-- =============================================
-- HELPER: Find quiz panel and close it
-- =============================================
local function closeQuizPanel(answerIndex)
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    local boardHUD = pg:FindFirstChild("BoardHUD")
    if not boardHUD then return end
    local panel = boardHUD:FindFirstChild("NewSpecialPanel")
    if not panel then return end

    -- Highlight correct answer green
    local optGrid = panel:FindFirstChild("OptionGrid")
    if optGrid and answerIndex then
        local optBtn = optGrid:FindFirstChild("Option" .. tostring(answerIndex))
        if optBtn and optBtn:IsA("TextButton") then
            optBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
            optBtn.TextColor3 = Color3.new(1, 1, 1)
        end
    end

    -- Wait a moment for the green highlight to show, then close
    task.delay(1.2, function()
        -- Try clicking OkBtn if visible
        local okBtn = panel:FindFirstChild("OkBtn")
        if okBtn and okBtn.Visible then
            -- Simulate the click behavior
            pcall(function() panel.Visible = false end)
        else
            pcall(function() panel.Visible = false end)
        end
        print("[QUIZ] Panel ditutup")
    end)
end

-- =============================================
-- 1. QUIZ AUTO-ANSWER (FIXED - closes UI)
-- =============================================
local TriggerSpecialEvent = RE:WaitForChild("TriggerSpecialEvent")
local QuizAnswered = RE:WaitForChild("QuizAnswered")

table.insert(conns, TriggerSpecialEvent.OnClientEvent:Connect(function(data)
    if not C.Active then return end
    if data and data.Type == "Quiz" and data.Answer then
        C.QuizCount = C.QuizCount + 1
        local answer = data.Answer
        local question = data.Question or "?"
        local option = data.Options and data.Options[answer] or "?"

        print("[QUIZ] " .. question)
        print("[QUIZ] Jawaban: " .. tostring(answer) .. " = " .. option)

        if C.QuizAutoAnswer then
            task.delay(0.8, function()
                -- Fire answer to server
                QuizAnswered:FireServer(answer)
                C.QuizCorrect = C.QuizCorrect + 1
                print("[QUIZ] ✅ Auto-jawab benar! +bonus uang")

                -- Close the quiz UI panel
                closeQuizPanel(answer)
            end)
        end
    end
end))

-- =============================================
-- 2. AUTO-BUY BEST AFFORDABLE LEVEL
-- =============================================
local PromptBuyProperty = RE:WaitForChild("PromptBuyProperty")
local PropertyBuyResponse = RE:WaitForChild("PropertyBuyResponse")

table.insert(conns, PromptBuyProperty.OnClientEvent:Connect(function(propName, options, ...)
    if not C.Active or not C.AutoBuyEnabled then return end
    if type(options) ~= "table" then return end

    local stats = LP:FindFirstChild("InternalStats")
    local money = stats and stats:FindFirstChild("Money") and stats.Money.Value or 0

    -- Find best AFFORDABLE option
    local bestIdx, bestLevel, bestCost = nil, 0, 0
    for i, opt in ipairs(options) do
        if opt.level and opt.cost and opt.cost <= money and opt.level > bestLevel then
            bestIdx = i
            bestLevel = opt.level
            bestCost = opt.cost
        end
    end

    if bestIdx then
        task.delay(0.5, function()
            PropertyBuyResponse:FireServer(options[bestIdx].level)
            C.PropertiesBought = C.PropertiesBought + 1
            print("[AUTO-BUY] ✅ " .. propName .. " Lvl " .. bestLevel .. " | Rp " .. bestCost)
        end)
    else
        -- Can't afford anything, skip
        local cheapest = options[1] and options[1].cost or 0
        print("[AUTO-BUY] ⏭️ Skip " .. propName .. " (perlu Rp " .. tostring(cheapest) .. ", punya Rp " .. money .. ")")
        task.delay(0.5, function()
            PropertyBuyResponse:FireServer(false) -- Skip/decline
        end)
    end
end))

-- =============================================
-- 3. DICE TRACKER
-- =============================================
local PlayDiceAnimation = RE:WaitForChild("PlayDiceAnimation")

table.insert(conns, PlayDiceAnimation.OnClientEvent:Connect(function(board, d1, d2, player)
    if not C.Active or not C.DiceTracker then return end
    local name = player and player.Name or "?"
    local total = (d1 or 0) + (d2 or 0)
    local double = d1 == d2
    local isMe = player == LP
    local tag = isMe and " <<< KAMU" or ""
    print("[DADU] " .. name .. ": " .. d1 .. "+" .. d2 .. "=" .. total .. (double and " DOUBLE!" or "") .. tag)
end))

-- =============================================
-- 4. MONEY TRACKER
-- =============================================
local ShowFloatyText = RE:WaitForChild("ShowFloatyText")

table.insert(conns, ShowFloatyText.OnClientEvent:Connect(function(player, amount, mtype)
    if not C.Active or not C.MoneyTracker then return end
    if player == LP then
        if amount >= 0 then
            C.MoneyGained = C.MoneyGained + amount
            print("[UANG] +" .. tostring(amount))
        else
            C.MoneyLost = C.MoneyLost + math.abs(amount)
            print("[UANG] " .. tostring(amount))
        end
    end
end))

-- =============================================
-- 5. AUTO-CLAIM QUEST (every 30s)
-- =============================================
local ClaimQuestReward = RE:FindFirstChild("ClaimQuestReward")
local questIds = {"Daily_Win", "Daily_Play", "Daily_Buy", "Daily_Roll"}

task.spawn(function()
    while C.Active do
        if C.AutoClaimQuest and ClaimQuestReward then
            for _, qid in ipairs(questIds) do
                ClaimQuestReward:FireServer(qid)
            end
        end
        task.wait(30)
    end
end)

-- =============================================
-- 6. UTILITY FUNCTIONS (manual use)
-- =============================================
-- _G.IndopolyCheat.forceBuy(level) - Force buy property at specific level
-- _G.IndopolyCheat.moveToTile(tileIndex) - Move during Free Parking

C.forceBuy = function(level)
    PropertyBuyResponse:FireServer(level or 1)
    print("[HACK] Force buy level " .. tostring(level))
end

C.moveToTile = function(tileIndex)
    local FPM = RE:FindFirstChild("FreeParkingMoveRequest")
    if FPM then
        FPM:FireServer(tileIndex)
        print("[HACK] Move to tile " .. tostring(tileIndex))
    end
end

-- =============================================
-- LAUNCH GUI + PRINT STATUS
-- =============================================
createGUI()

print("=============================================")
print("   INDOPOLY CHEAT SUITE v4.1 LOADED")
print("=============================================")
print("   Player: " .. LP.Name)
print("   GUI: Kanan atas (bisa di-drag)")
print("")
print("   [ON] Quiz Auto-Answer + UI Auto-Close")
print("   [ON] Auto-Buy (level tertinggi yg mampu)")
print("   [ON] Dice & Money Tracker")
print("   [ON] Auto-Claim Quest")
print("")
print("   🪙 Coins = global, tetap antar game")
print("   💵 Money = uang di round ini saja")
print("=============================================")
