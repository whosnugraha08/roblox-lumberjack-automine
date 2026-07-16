-- =============================================
-- BUCKSHOT HELPER v3
-- FIXED: Only tracks YOUR table, ignores everything else
-- =============================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- Get Bootstrapper module
local ClientModule
pcall(function()
    ClientModule = require(LP:WaitForChild("PlayerScripts"):WaitForChild("Bootstrapper"):WaitForChild("Client"))
end)

-- DESTROY OLD
for _, name in {"BuckshotHelper"} do
    local old = game:GetService("CoreGui"):FindFirstChild(name)
    if old then old:Destroy() end
end

local SG = Instance.new("ScreenGui")
SG.Name = "BuckshotHelper"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = game:GetService("CoreGui")

-- Main
local Main = Instance.new("Frame", SG)
Main.Name = "Main"
Main.Size = UDim2.new(0, 280, 0, 380)
Main.Position = UDim2.new(0, 10, 0.5, -190)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = Color3.fromRGB(200, 40, 40)
mainStroke.Thickness = 2

-- Title
local TB = Instance.new("Frame", Main)
TB.Size = UDim2.new(1, 0, 0, 34)
TB.BackgroundColor3 = Color3.fromRGB(160, 25, 25)
TB.BorderSizePixel = 0
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 10)
local tbFix = Instance.new("Frame", TB)
tbFix.Size = UDim2.new(1, 0, 0, 10)
tbFix.Position = UDim2.new(0, 0, 1, -10)
tbFix.BackgroundColor3 = Color3.fromRGB(160, 25, 25)
tbFix.BorderSizePixel = 0

Instance.new("TextLabel", TB).Size = UDim2.new(1, -60, 1, 0)
TB:FindFirstChildOfClass("TextLabel").Position = UDim2.new(0, 10, 0, 0)
TB:FindFirstChildOfClass("TextLabel").BackgroundTransparency = 1
TB:FindFirstChildOfClass("TextLabel").Text = "🔫 BUCKSHOT v3"
TB:FindFirstChildOfClass("TextLabel").TextColor3 = Color3.new(1,1,1)
TB:FindFirstChildOfClass("TextLabel").TextSize = 14
TB:FindFirstChildOfClass("TextLabel").Font = Enum.Font.GothamBold
TB:FindFirstChildOfClass("TextLabel").TextXAlignment = Enum.TextXAlignment.Left

local cBtn = Instance.new("TextButton", TB)
cBtn.Size = UDim2.new(0,26,0,26)
cBtn.Position = UDim2.new(1,-30,0,4)
cBtn.BackgroundTransparency = 1
cBtn.Text = "✕"
cBtn.TextColor3 = Color3.fromRGB(255,180,180)
cBtn.TextSize = 16
cBtn.Font = Enum.Font.GothamBold
cBtn.MouseButton1Click:Connect(function() SG:Destroy() end)

local mBtn = Instance.new("TextButton", TB)
mBtn.Size = UDim2.new(0,26,0,26)
mBtn.Position = UDim2.new(1,-56,0,4)
mBtn.BackgroundTransparency = 1
mBtn.Text = "—"
mBtn.TextColor3 = Color3.fromRGB(255,180,180)
mBtn.TextSize = 14
mBtn.Font = Enum.Font.GothamBold
local mini = false
mBtn.MouseButton1Click:Connect(function()
    mini = not mini
    for _,c in Main:GetChildren() do
        if c:IsA("GuiObject") and c ~= TB then c.Visible = not mini end
    end
    Main.Size = mini and UDim2.new(0,280,0,34) or UDim2.new(0,280,0,380)
end)

-- Content
local C = Instance.new("ScrollingFrame", Main)
C.Name = "C"
C.Size = UDim2.new(1,-10,1,-38)
C.Position = UDim2.new(0,5,0,36)
C.BackgroundTransparency = 1
C.BorderSizePixel = 0
C.ScrollBarThickness = 3
C.ScrollBarImageColor3 = Color3.fromRGB(200,40,40)
C.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", C).Padding = UDim.new(0,4)
C:FindFirstChildOfClass("UIListLayout").SortOrder = Enum.SortOrder.LayoutOrder

-- Helpers
local function sec(title, order)
    local f = Instance.new("Frame", C)
    f.Size = UDim2.new(1,-4,0,0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = Color3.fromRGB(22,22,30)
    f.BorderSizePixel = 0
    f.LayoutOrder = order
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,7)
    local p = Instance.new("UIPadding", f)
    p.PaddingTop = UDim.new(0,5)
    p.PaddingBottom = UDim.new(0,5)
    p.PaddingLeft = UDim.new(0,7)
    p.PaddingRight = UDim.new(0,7)
    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0,2)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    local h = Instance.new("TextLabel", f)
    h.Size = UDim2.new(1,0,0,18)
    h.BackgroundTransparency = 1
    h.Text = title
    h.TextColor3 = Color3.fromRGB(255,65,65)
    h.TextSize = 12
    h.Font = Enum.Font.GothamBold
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.LayoutOrder = 0
    return f
end

local function lbl(parent, text, order, color)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1,0,0,16)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(180,180,190)
    l.TextSize = 11
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
local sT = sec("📍 YOUR TABLE", 1)
local lTable = lbl(sT, "⏳ Waiting to join a game...", 1, Color3.fromRGB(255,200,100))
local lSpot = lbl(sT, "", 2)
local lOpp = lbl(sT, "", 3)

local sS = sec("🔴 SHELLS", 2)
local lLive = lbl(sS, "—", 1, Color3.fromRGB(255,100,100))
local lBlank = lbl(sS, "—", 2, Color3.fromRGB(140,140,255))
local lTotal = lbl(sS, "—", 3)

local sP = sec("🎯 PROBABILITY", 3)
local lLP = lbl(sP, "—", 1, Color3.fromRGB(255,120,120))
local lBP = lbl(sP, "—", 2, Color3.fromRGB(120,120,255))

local sA = sec("💡 ADVICE", 4)
local lAdv = lbl(sA, "Join a game to start tracking", 1, Color3.fromRGB(150,150,150))

local sTn = sec("⏱️ TURN", 5)
local lTurn = lbl(sTn, "—", 1, Color3.fromRGB(200,200,200))

local sH = sec("📜 HISTORY", 6)
local lHist = lbl(sH, "—", 1, Color3.fromRGB(150,150,160))

-- =============================================
-- STATE
-- =============================================
local STATE = {
    tableId = nil,     -- nil = NOT in game
    spotIndex = nil,
    maxPlayers = nil,
    live = 0,
    blank = 0,
    history = {},
    round = 0,
}

-- =============================================
-- DISPLAY UPDATE
-- =============================================
local function clearDisplay()
    lTable.Text = "⏳ Waiting to join a game..."
    lTable.TextColor3 = Color3.fromRGB(255, 200, 100)
    lSpot.Text = ""
    lOpp.Text = ""
    lLive.Text = "🔴 Live: —"
    lBlank.Text = "⚪ Blank: —"
    lTotal.Text = "📊 Total: —"
    lLP.Text = "🔴 Live: —"
    lBP.Text = "⚪ Blank: —"
    lAdv.Text = "Join a game to start tracking"
    lAdv.TextColor3 = Color3.fromRGB(150, 150, 150)
    lTurn.Text = "—"
    lTurn.TextColor3 = Color3.fromRGB(200, 200, 200)
    lHist.Text = "—"
end

local function updateShells()
    -- GUARD: Only show data when in game
    if not STATE.tableId then
        clearDisplay()
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

        -- Color
        lLP.TextColor3 = lp >= 60 and Color3.fromRGB(255,50,50) or Color3.fromRGB(255,120,120)
        lBP.TextColor3 = bp >= 60 and Color3.fromRGB(80,80,255) or Color3.fromRGB(120,120,255)

        -- Advice
        if STATE.live == 0 then
            lAdv.Text = "✅ ALL BLANKS → Shoot YOURSELF!"
            lAdv.TextColor3 = Color3.fromRGB(0,255,120)
        elseif STATE.blank == 0 then
            lAdv.Text = "⚠️ ALL LIVE → Shoot OPPONENT!"
            lAdv.TextColor3 = Color3.fromRGB(255,50,50)
        elseif total == 1 and STATE.live == 1 then
            lAdv.Text = "⚠️ LAST = LIVE → Shoot OPPONENT!"
            lAdv.TextColor3 = Color3.fromRGB(255,50,50)
        elseif total == 1 and STATE.blank == 1 then
            lAdv.Text = "✅ LAST = BLANK → Shoot YOURSELF!"
            lAdv.TextColor3 = Color3.fromRGB(0,255,120)
        elseif lp >= 70 then
            lAdv.Text = "🎯 HIGH LIVE ("..lp.."%) → Shoot OPPONENT"
            lAdv.TextColor3 = Color3.fromRGB(255,100,100)
        elseif bp >= 70 then
            lAdv.Text = "💡 HIGH BLANK ("..bp.."%) → Shoot YOURSELF"
            lAdv.TextColor3 = Color3.fromRGB(100,200,255)
        else
            lAdv.Text = "🤔 "..lp.."/"..bp.." → Use item if available"
            lAdv.TextColor3 = Color3.fromRGB(255,255,100)
        end
    else
        lLP.Text = "🔴 Live: —"
        lBP.Text = "⚪ Blank: —"
        lAdv.Text = "⏳ Waiting for shells..."
        lAdv.TextColor3 = Color3.fromRGB(150,150,150)
    end
end

local function addShot(t, target)
    if not STATE.tableId then return end
    table.insert(STATE.history, 1, {type=t, target=target})
    while #STATE.history > 12 do table.remove(STATE.history) end
    local lines = {}
    for i=1, math.min(#STATE.history, 6) do
        local s = STATE.history[i]
        table.insert(lines, (s.type=="live" and "🔴" or "⚪").." "..s.type:upper().." → "..tostring(s.target))
    end
    lHist.Text = #lines > 0 and table.concat(lines, "\n") or "—"
end

-- =============================================
-- DETECT MY TABLE (via Bootstrapper)
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

        -- Opponents
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

        -- Reset history if just joined
        if wasNil then
            STATE.history = {}
            STATE.live = 0
            STATE.blank = 0
            STATE.round = 0
            lHist.Text = "—"
            updateShells()
        end

        return true
    else
        -- NOT in game
        if STATE.tableId ~= nil then
            -- Just left game
            STATE.tableId = nil
            STATE.spotIndex = nil
            STATE.maxPlayers = nil
            STATE.live = 0
            STATE.blank = 0
            clearDisplay()
        end
        return false
    end
end

-- =============================================
-- HOOKS (ALL filtered by STATE.tableId)
-- =============================================
local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
local hookN = 0

-- 1) ShellTrackerAction (server sends only to you — but we guard anyway)
local st = remotes and remotes:FindFirstChild("ShellTrackerAction")
if st then
    st.OnClientEvent:Connect(function(data)
        if not data then return end
        if data.action == "update" and data.shellData then
            if not STATE.tableId then detectTable() end -- try to detect
            if STATE.tableId then
                STATE.live = data.shellData.live or 0
                STATE.blank = data.shellData.blank or 0
                updateShells()
            end
        elseif data.action == "activate" then
            detectTable()
        elseif data.action == "deactivate" then
            -- shell tracker deactivated (between rounds)
        end
    end)
    hookN += 1
end

-- 2) Visuals — STRICTLY filter by tableId
local vis = remotes and remotes:FindFirstChild("Visuals")
if vis then
    vis.OnClientEvent:Connect(function(action, ...)
        if action ~= "shootShotgun" then return end
        if not STATE.tableId then return end -- NOT IN GAME = SKIP
        
        local args = {...}
        local tblId = args[1]
        
        -- STRICT FILTER: must match my table
        if tblId ~= STATE.tableId then return end
        
        local target = args[2]
        local isLive = args[3]

        local tName = "?"
        if target then
            if typeof(target) == "Instance" then
                tName = target == LP and "SELF" or (target.DisplayName or target.Name)
            elseif typeof(target) == "table" then
                tName = target.DisplayName or target.Name or "Bot"
            end
        else
            tName = "SELF"
        end

        if isLive then
            STATE.live = math.max(0, STATE.live - 1)
            addShot("live", tName)
            mainStroke.Color = Color3.fromRGB(255,0,0)
            mainStroke.Thickness = 4
            task.delay(0.5, function()
                mainStroke.Color = Color3.fromRGB(200,40,40)
                mainStroke.Thickness = 2
            end)
        else
            STATE.blank = math.max(0, STATE.blank - 1)
            addShot("blank", tName)
        end
        updateShells()
    end)
    hookN += 1
end

-- 3) PlayerTurn — only when in game
local pt = remotes and remotes:FindFirstChild("PlayerTurn")
if pt then
    pt.OnClientEvent:Connect(function(isEnd)
        if not STATE.tableId then return end -- SKIP if not in game
        if not isEnd then
            lTurn.Text = "🟢 YOUR TURN!"
            lTurn.TextColor3 = Color3.fromRGB(0,255,100)
            -- Flash advice
            if STATE.live + STATE.blank > 0 then
                task.spawn(function()
                    for i=1,3 do
                        lAdv.TextColor3 = Color3.fromRGB(255,255,0)
                        task.wait(0.15)
                        updateShells()
                        task.wait(0.15)
                    end
                end)
            end
        else
            lTurn.Text = "⏳ Opponent's turn"
            lTurn.TextColor3 = Color3.fromRGB(180,180,180)
        end
    end)
    hookN += 1
end

-- 4) GameEnded
local ge = remotes and remotes:FindFirstChild("GameEnded")
if ge then
    ge.OnClientEvent:Connect(function(data)
        if not STATE.tableId then return end
        STATE.tableId = nil
        lTable.Text = "🏁 Game Over"
        lTable.TextColor3 = Color3.fromRGB(255,200,100)
        if data and data.winner then
            if data.winner == LP then
                lTurn.Text = "🏆 YOU WON!"
                lTurn.TextColor3 = Color3.fromRGB(255,215,0)
            else
                local n = typeof(data.winner)=="Instance" and data.winner.DisplayName or "?"
                lTurn.Text = "💀 Lost to " .. n
                lTurn.TextColor3 = Color3.fromRGB(255,80,80)
            end
        end
    end)
    hookN += 1
end

-- =============================================
-- POLLING LOOP: detect table + read built-in UI
-- =============================================
task.spawn(function()
    while SG.Parent do
        -- Detect table
        detectTable()
        
        -- ONLY read ShellTrackerUI if we ARE in a game
        if STATE.tableId then
            pcall(function()
                local ui = PG:FindFirstChild("ShellTrackerUI")
                if ui then
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

-- =============================================
-- STATUS
-- =============================================
local sS2 = sec("📡 STATUS", 7)
lbl(sS2, "✅ "..hookN.." hooks | Polling 0.5s", 1, Color3.fromRGB(100,255,100))
lbl(sS2, "v3.0 | Table-strict filtering", 2, Color3.fromRGB(90,90,110))

-- Initial state
clearDisplay()
detectTable()
print("[BH] v3 loaded | " .. hookN .. " hooks | Table: " .. tostring(STATE.tableId))
