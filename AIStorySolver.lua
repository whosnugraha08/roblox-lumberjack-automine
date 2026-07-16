--[[
    ========================================================================
    AI STORY SOLVER AGENT (ROBLOX HORROR/STORY GAMES)
    Core Architecture: Perception, Map Intel, Threat System, Puzzle Solver
    ========================================================================
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = gethui and gethui() or Players.LocalPlayer:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local AI = {
    Config = {
        ScanInterval = 1.5,
        MaxDistance = 5000,
        Colors = {
            bg = Color3.fromRGB(15, 15, 20),
            card = Color3.fromRGB(25, 25, 32),
            text = Color3.fromRGB(240, 240, 245),
            sub = Color3.fromRGB(150, 150, 160),
            quest = Color3.fromRGB(50, 255, 120),
            danger = Color3.fromRGB(255, 50, 50),
            warn = Color3.fromRGB(255, 180, 50),
            safe = Color3.fromRGB(100, 200, 255)
        }
    },
    Data = {
        Objective = "Scanning...",
        DangerLevel = 1,
        NearestMonsterDist = 999,
        NearestHideDist = 999,
        Interactables = {}, -- {obj, type, name, dist, isQuest}
        Highlights = {},
        Connections = {},
        QuestKeys = {}
    }
}

-- Cleanup Old
if CoreGui:FindFirstChild("AIStorySolver") then
    CoreGui.AIStorySolver:Destroy()
end

-- ==========================================
-- HUD OVERLAY MODULE
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AIStorySolver"
gui.Parent = CoreGui
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 300, 0, 420)
main.Position = UDim2.new(1, -320, 0.5, -210)
main.BackgroundColor3 = AI.Config.Colors.bg
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
local corner = Instance.new("UICorner", main); corner.CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", main); stroke.Color = Color3.fromRGB(50, 50, 60)

local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1
local title = Instance.new("TextLabel", header)
title.Text = "🧠 AI STORY SOLVER"; title.Font = Enum.Font.GothamBlack; title.TextSize = 14
title.TextColor3 = AI.Config.Colors.text; title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -40, 1, 0); title.Position = UDim2.new(0, 12, 0, 0)
title.TextXAlignment = Enum.TextXAlignment.Left

local div = Instance.new("Frame", main)
div.Size = UDim2.new(1, 0, 0, 1); div.Position = UDim2.new(0, 0, 0, 40)
div.BackgroundColor3 = stroke.Color; div.BorderSizePixel = 0

local content = Instance.new("ScrollingFrame", main)
content.Size = UDim2.new(1, -16, 1, -50)
content.Position = UDim2.new(0, 8, 0, 45)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 2
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
local layout = Instance.new("UIListLayout", content)
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function createPanel(name, order)
    local p = Instance.new("Frame", content)
    p.Size = UDim2.new(1, 0, 0, 80)
    p.BackgroundColor3 = AI.Config.Colors.card
    p.BorderSizePixel = 0
    p.LayoutOrder = order
    local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, 6)
    
    local t = Instance.new("TextLabel", p)
    t.Text = name; t.Font = Enum.Font.GothamBold; t.TextSize = 11
    t.TextColor3 = AI.Config.Colors.sub; t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, -16, 0, 20); t.Position = UDim2.new(0, 8, 0, 4)
    t.TextXAlignment = Enum.TextXAlignment.Left
    
    local body = Instance.new("TextLabel", p)
    body.Text = "-"; body.Font = Enum.Font.GothamMedium; body.TextSize = 13
    body.TextColor3 = AI.Config.Colors.text; body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, -16, 1, -28); body.Position = UDim2.new(0, 8, 0, 24)
    body.TextXAlignment = Enum.TextXAlignment.Left; body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
    body.RichText = true
    
    return p, body
end

local pnlQuest, txtQuest = createPanel("🎯 CURRENT OBJECTIVE", 1)
local pnlThreat, txtThreat = createPanel("⚠️ THREAT RADAR", 2)
local pnlMap, txtMap = createPanel("🗺️ MAP INTEL", 3)

local closeBtn = Instance.new("TextButton", header)
closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 12
closeBtn.TextColor3 = AI.Config.Colors.sub; closeBtn.BackgroundTransparency = 1
closeBtn.Size = UDim2.new(0, 30, 1, 0); closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- ==========================================
-- ESP SYSTEM (NAVIGATOR)
-- ==========================================
local function clearESP()
    for _, data in pairs(AI.Data.Highlights) do
        pcall(function() data.hl:Destroy(); data.bg:Destroy() end)
    end
    table.clear(AI.Data.Highlights)
end

local function applyESP(obj, text, color, isQuest)
    if AI.Data.Highlights[obj] then return end
    if not obj or not obj.Parent then return end
    
    local hl = Instance.new("Highlight")
    hl.FillColor = color; hl.OutlineColor = isQuest and Color3.new(1,1,1) or color
    hl.FillTransparency = 0.6; hl.OutlineTransparency = 0
    pcall(function() hl.Parent = CoreGui end)
    hl.Adornee = obj
    
    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 200, 0, 50); bg.AlwaysOnTop = true
    pcall(function() bg.Parent = CoreGui end)
    bg.Adornee = obj
    
    local txt = Instance.new("TextLabel", bg)
    txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1
    txt.Text = text; txt.TextColor3 = color; txt.TextStrokeTransparency = 0
    txt.Font = Enum.Font.GothamBold; txt.TextSize = isQuest and 14 or 10
    
    AI.Data.Highlights[obj] = {hl = hl, bg = bg, txt = txt, rawText = text}
end

-- ==========================================
-- PERCEPTION & MAP INTEL
-- ==========================================
local function getHRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function scanObjective()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    
    local bestMatch = nil
    local bestPriority = 0
    
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible and d.TextTransparency < 0.95 then
            local t = d.Text:lower()
            local pName = (d.Parent and d.Parent.Name:lower()) or ""
            local dName = d.Name:lower()
            
            local cleanText = d.Text:upper():gsub(":", ""):gsub(" ", "")
            if d.Text ~= "" and cleanText ~= "OBJECTIVE" and cleanText ~= "MISI" and cleanText ~= "TUGAS" and cleanText ~= "CURRENT" and cleanText ~= "MISSION" then
                
                local isNameMatch = pName:find("objective") or pName:find("tugas") or pName:find("misi") or pName:find("mission") or
                                    dName:find("objective") or dName:find("tugas") or dName:find("misi") or dName:find("mission")
                                    
                local isTextMatch = t:find("find ") or t:find("escape ") or t:find("survive ") or t:find("bring ") or t:find("approach ") or t:find("exit ") or t:find("put ") or
                                    t:find("cari ") or t:find("kabur ") or t:find("bertahan ") or t:find("bawa ") or t:find("dekati ") or t:find("ambil ") or t:find("temukan ") or t:find("pergi ")
                
                -- Skip ActionText, Interaction prompts, Template UI, or System Hints from matching
                if dName:find("actiontext") or pName:find("action") or dName:find("template") or pName:find("template") or dName:find("unlock") or dName:find("cursor") or t:find("tekan tombol") or t:find("press ") then
                    isTextMatch = false
                    isNameMatch = false
                end
                
                if isNameMatch then
                    bestMatch = d.Text
                    bestPriority = 2
                    -- Do not break, allow newer active entries to overwrite older ones
                elseif isTextMatch and bestPriority < 1 then
                    bestMatch = d.Text
                    bestPriority = 1
                end
            end
        end
    end
    
    AI.Data.Objective = bestMatch or "No active objective detected..."
end

local function isHidingSpot(name)
    local n = name:lower()
    return n:find("locker") or n:find("closet") or n:find("bed") or n:find("cabinet") or n:find("lemari") or n:find("kasur")
end

local function isCriticalModel(name)
    local n = name:lower()
    -- Only check against dynamic quest keys so we don't permanently highlight doors
    for _, key in ipairs(AI.Data.QuestKeys) do
        if n:find(key) then return true end
    end
    return false
end

local function scanEnvironment()
    table.clear(AI.Data.Interactables)
    local hrp = getHRP()
    local rootPos = hrp and hrp.Position or Vector3.zero
    
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
            local obj = d.Parent
            local act = d:IsA("ProximityPrompt") and d.ActionText or "Click"
            if act == "" then act = "Interact" end
            
            local pos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position) or obj.Position
            local dist = hrp and (rootPos - pos).Magnitude or 999
            
            if dist < AI.Config.MaxDistance then
                table.insert(AI.Data.Interactables, {
                    inst = obj,
                    action = act,
                    name = obj.Name,
                    dist = dist,
                    type = isHidingSpot(obj.Name) and "Hide" or "Item",
                    isQuest = false
                })
            end
        elseif d:IsA("Model") or d:IsA("BasePart") or d:IsA("Folder") then
            -- Fallback for objective models/parts without prompts
            local matches = isCriticalModel(d.Name)
            
            -- If it's a Part, check if its parent matches (like Folder 'PictureFrames')
            -- BUT only if the parent is a small model/folder, to avoid highlighting giant map structures like 'Labirin'
            if not matches and d:IsA("BasePart") and d.Parent then
                if #d.Parent:GetChildren() < 15 then
                    matches = isCriticalModel(d.Parent.Name)
                end
            end
            
            -- Also completely ignore map geometry if they somehow match
            if matches and (d.Name:lower():find("tembok") or d.Name:lower():find("wall") or d.Name:lower():find("floor") or d.Name:lower():find("lantai") or d.Name:lower():find("pilar")) then
                matches = false
            end
            
            if matches then
                local pos
                if d:IsA("Model") then pos = d.PrimaryPart and d.PrimaryPart.Position or d:GetModelCFrame().Position
                elseif d:IsA("BasePart") then pos = d.Position
                elseif d:IsA("Folder") then pos = rootPos end
                
                if pos then
                    local dist = hrp and (rootPos - pos).Magnitude or 999
                    if dist < AI.Config.MaxDistance then
                        table.insert(AI.Data.Interactables, {
                            inst = d,
                            action = "Objective: " .. d.Name,
                            name = d.Name,
                            dist = dist,
                            type = "Item",
                            isQuest = true
                        })
                    end
                end
            end
        elseif d:IsA("ParticleEmitter") then
            local n = d.Name:lower()
            if n:find("fire") or n:find("flame") or n:find("smoke") or n:find("burn") then
                -- Check if we are actually looking for fire
                local lookingForFire = false
                for _, key in ipairs(AI.Data.QuestKeys) do
                    if key:find("fire") or key:find("burn") or key:find("extinguish") or key:find("api") or key:find("padam") then
                        lookingForFire = true
                        break
                    end
                end
                
                if lookingForFire and d.Parent and d.Parent:IsA("BasePart") then
                    local dist = hrp and (rootPos - d.Parent.Position).Magnitude or 999
                    if dist < AI.Config.MaxDistance then
                        table.insert(AI.Data.Interactables, {
                            inst = d.Parent,
                            action = "🔥 Fire Target",
                            name = d.Name,
                            dist = dist,
                            type = "Item",
                            isQuest = true
                        })
                    end
                end
            end
        end
    end
end

-- ==========================================
-- THREAT SYSTEM
-- ==========================================
local function scanThreats()
    local hrp = getHRP()
    if not hrp then return end
    
    local nearestDist = 999
    local monsters = {}
    
    for _, d in ipairs(workspace:GetChildren()) do
        if d:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(d) then
            -- Simple alive check
            if d.Humanoid.Health > 0 then
                local epos = d.PrimaryPart and d.PrimaryPart.Position or d:GetModelCFrame().Position
                local dist = (hrp.Position - epos).Magnitude
                if dist < nearestDist then nearestDist = dist end
                table.insert(monsters, {inst = d, dist = dist})
            end
        end
    end
    
    AI.Data.NearestMonsterDist = nearestDist
    
    if nearestDist < 25 then AI.Data.DangerLevel = 5
    elseif nearestDist < 50 then AI.Data.DangerLevel = 4
    elseif nearestDist < 80 then AI.Data.DangerLevel = 3
    elseif nearestDist < 120 then AI.Data.DangerLevel = 2
    else AI.Data.DangerLevel = 1 end
    
    return monsters
end

-- ==========================================
-- PUZZLE SOLVER & LOGIC
-- ==========================================
local function runLogic()
    local objLow = AI.Data.Objective:lower()
    
    -- Keyword Extraction (Dynamic + Hardcoded)
    local keys = {}
    
    -- 1. Dynamic Extraction (Extract significant words directly from the objective text)
    local stopWords = {
        ["the"]=true, ["and"]=true, ["for"]=true, ["with"]=true, ["this"]=true, ["that"]=true, 
        ["put"]=true, ["out"]=true, ["from"]=true, ["into"]=true, ["find"]=true, ["cari"]=true, 
        ["get"]=true, ["are"]=true, ["you"]=true, ["your"]=true, ["have"]=true, ["has"]=true,
        ["can"]=true, ["will"]=true, ["all"]=true, ["any"]=true, ["some"]=true, ["more"]=true,
        ["di"]=true, ["ke"]=true, ["dari"]=true, ["dan"]=true, ["yang"]=true, ["untuk"]=true,
        ["ambil"]=true, ["take"]=true, ["pick"]=true, ["place"]=true, ["taruh"]=true, ["letak"]=true,
        ["approach"]=true, ["talk"]=true, ["dekati"]=true, ["bicara"]=true, ["bawa"]=true, ["bring"]=true,
        ["pergi"]=true, ["menuju"]=true, ["escape"]=true, ["kabur"]=true, ["survive"]=true, ["bertahan"]=true,
        ["masuk"]=true, ["keluar"]=true, ["dalam"]=true, ["luar"]=true, ["buka"]=true, ["tutup"]=true,
        ["lalu"]=true, ["segel"]=true, ["labirin"]=true, ["maze"]=true, ["room"]=true, ["ruangan"]=true,
        ["house"]=true, ["rumah"]=true, ["area"]=true, ["zone"]=true, ["tempat"]=true, ["atas"]=true, ["bawah"]=true
    }
    
    for word in objLow:gmatch("%a+") do
        if #word >= 3 and not stopWords[word] then
            table.insert(keys, word)
            -- Also add singular form if plural (e.g., "fires" -> "fire")
            if word:sub(-1) == "s" then
                table.insert(keys, word:sub(1, -2))
            end
            -- Add synonyms for common words
            if word:find("photo") or word:find("foto") then
                table.insert(keys, "picture")
                table.insert(keys, "gambar")
            end
            if word:find("picture") then
                table.insert(keys, "photo")
            end
        end
    end
    
    -- 2. Hardcoded / Synonyms mapping (ONLY NOUNS)
    if objLow:find("key") or objLow:find("kunci") then table.insert(keys, "key"); table.insert(keys, "kunci") end
    if objLow:find("door") or objLow:find("escape") or objLow:find("pintu") or objLow:find("keluar") then table.insert(keys, "door"); table.insert(keys, "exit"); table.insert(keys, "pintu"); table.insert(keys, "keluar") end
    if objLow:find("water") or objLow:find("fill") or objLow:find("air") or objLow:find("isi") then table.insert(keys, "water"); table.insert(keys, "air"); end
    if objLow:find("rope") or objLow:find("tali") then table.insert(keys, "rope"); table.insert(keys, "tali") end
    
    -- Save quest keys globally so the environment scanner can use them for models
    AI.Data.QuestKeys = keys
    
    -- Fallback: if no specific keys, make everything slightly important
    local fallback = #keys == 0
    
    -- Process Interactables
    clearESP()
    local qCount, hCount, iCount = 0, 0, 0
    local nearHide = 999
    
    for _, item in ipairs(AI.Data.Interactables) do
        local actLow = item.action:lower()
        local nameLow = item.name:lower()
        item.isQuest = false
        
        if item.type == "Hide" then
            hCount = hCount + 1
            if item.dist < nearHide then nearHide = item.dist end
            -- Only ESP hiding spots if in danger
            if AI.Data.DangerLevel >= 3 and item.dist < 100 then
                applyESP(item.inst, "Hide ["..math.floor(item.dist).."s]", AI.Config.Colors.safe, false)
            end
        else
            iCount = iCount + 1
            -- Match keywords
            if not fallback then
                for _, k in ipairs(keys) do
                    if actLow:find(k) or nameLow:find(k) then
                        item.isQuest = true; break
                    end
                end
            end
            
            if item.isQuest then
                qCount = qCount + 1
                applyESP(item.inst, "⭐ " .. item.action, AI.Config.Colors.quest, true)
            else
                -- Secondary ESP
                if item.dist < 80 then
                    applyESP(item.inst, item.action, AI.Config.Colors.sub, false)
                end
            end
        end
    end
    
    AI.Data.NearestHideDist = nearHide
    
    -- Threats ESP
    local monsters = scanThreats()
    for _, m in ipairs(monsters or {}) do
        applyESP(m.inst, "⚠️ MONSTER", AI.Config.Colors.danger, true)
    end
    
    -- Update UI
    txtQuest.Text = "<font color='rgb(255,255,255)'>" .. AI.Data.Objective .. "</font>\n"
    if qCount > 0 then
        txtQuest.Text = txtQuest.Text .. "\n<font color='rgb(50,255,120)'>→ Found " .. qCount .. " Quest targets nearby!</font>"
    else
        txtQuest.Text = txtQuest.Text .. "\n<font color='rgb(150,150,160)'>→ Scanning for clues...</font>"
    end
    
    -- Threat UI
    local dColor = AI.Config.Colors.safe
    local dText = "SAFE"
    if AI.Data.DangerLevel == 2 then dColor = AI.Config.Colors.warn; dText = "CAUTION"
    elseif AI.Data.DangerLevel == 3 then dColor = AI.Config.Colors.warn; dText = "DANGER"
    elseif AI.Data.DangerLevel >= 4 then dColor = AI.Config.Colors.danger; dText = "CRITICAL (RUN/HIDE!)" end
    
    local cHex = string.format("#%02X%02X%02X", dColor.R*255, dColor.G*255, dColor.B*255)
    
    txtThreat.Text = "Status: <font color='"..cHex.."'><b>" .. dText .. "</b></font>\n"
    if AI.Data.NearestMonsterDist < 900 then
        txtThreat.Text = txtThreat.Text .. "Monster Dist: " .. math.floor(AI.Data.NearestMonsterDist) .. " studs\n"
    else
        txtThreat.Text = txtThreat.Text .. "Monster Dist: Clear\n"
    end
    
    if AI.Data.DangerLevel >= 3 then
        if nearHide < 900 then
            txtThreat.Text = txtThreat.Text .. "Nearest Hide: <font color='#64C8FF'>" .. math.floor(nearHide) .. " studs</font>"
        else
            txtThreat.Text = txtThreat.Text .. "Nearest Hide: <font color='#FF3232'>NONE NEARBY</font>"
        end
    end
    
    -- Map UI
    txtMap.Text = "Mapped Items: " .. iCount .. "\n"
    txtMap.Text = txtMap.Text .. "Hiding Spots: " .. hCount
end

-- ==========================================
-- MAIN LOOP
-- ==========================================
local c = RunService.RenderStepped:Connect(function()
    -- Update ESP distances every frame
    local hrp = getHRP()
    if hrp then
        for obj, data in pairs(AI.Data.Highlights) do
            if obj and obj.Parent then
                local pos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position) or obj.Position
                local dist = (hrp.Position - pos).Magnitude
                data.txt.Text = data.rawText .. " [" .. math.floor(dist) .. "s]"
            end
        end
    end
end)
table.insert(AI.Data.Connections, c)

task.spawn(function()
    while gui.Parent do
        pcall(scanObjective)
        pcall(scanEnvironment)
        pcall(runLogic)
        task.wait(AI.Config.ScanInterval)
    end
end)

gui.Destroying:Connect(function()
    for _, conn in ipairs(AI.Data.Connections) do pcall(function() conn:Disconnect() end) end
    clearESP()
end)
