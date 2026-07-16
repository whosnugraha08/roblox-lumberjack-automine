--[[
    UNIVERSAL QUEST & MONSTER ESP (SMART OBJECTIVE SYNC)
    Auto-syncs with Elmira/Sorrow current objective.
]]
local Players = game:GetService("Players")
local CoreGui = gethui and gethui() or Players.LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local C = {
    bg = Color3.fromRGB(20, 20, 25),
    card = Color3.fromRGB(30, 30, 38),
    text = Color3.fromRGB(240, 240, 245),
    sub = Color3.fromRGB(150, 150, 160),
    quest = Color3.fromRGB(100, 255, 150),
    accent = Color3.fromRGB(100, 180, 255),
    monster = Color3.fromRGB(255, 60, 60)
}

if CoreGui:FindFirstChild("SmartQuestESP") then CoreGui.SmartQuestESP:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SmartQuestESP"; gui.Parent = CoreGui; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 280, 0, 400); main.Position = UDim2.new(1, -300, 0.5, -200)
main.BackgroundColor3 = C.bg; main.BorderSizePixel = 0
main.Active = true; main.Draggable = true
local corner = Instance.new("UICorner", main); corner.CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", main); stroke.Color = Color3.fromRGB(50, 50, 60)

local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 40); header.BackgroundTransparency = 1
local title = Instance.new("TextLabel", header)
title.Text = "SMART QUEST ESP"; title.Font = Enum.Font.GothamBlack; title.TextSize = 14
title.TextColor3 = C.text; title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -40, 1, 0); title.Position = UDim2.new(0, 12, 0, 0)
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 12
closeBtn.TextColor3 = C.sub; closeBtn.BackgroundTransparency = 1
closeBtn.Size = UDim2.new(0, 30, 1, 0); closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local div = Instance.new("Frame", main)
div.Size = UDim2.new(1, 0, 0, 1); div.Position = UDim2.new(0, 0, 0, 40)
div.BackgroundColor3 = stroke.Color; div.BorderSizePixel = 0

-- Objective Display
local objFrame = Instance.new("Frame", main)
objFrame.Size = UDim2.new(1, -16, 0, 60); objFrame.Position = UDim2.new(0, 8, 0, 48)
objFrame.BackgroundColor3 = C.card; objFrame.BorderSizePixel = 0
local objCorner = Instance.new("UICorner", objFrame); objCorner.CornerRadius = UDim.new(0, 6)

local objTitle = Instance.new("TextLabel", objFrame)
objTitle.Text = "CURRENT OBJECTIVE:"; objTitle.Font = Enum.Font.GothamBold; objTitle.TextSize = 10
objTitle.TextColor3 = C.quest; objTitle.BackgroundTransparency = 1
objTitle.Size = UDim2.new(1, -16, 0, 20); objTitle.Position = UDim2.new(0, 8, 0, 4)
objTitle.TextXAlignment = Enum.TextXAlignment.Left

local objDesc = Instance.new("TextLabel", objFrame)
objDesc.Text = "Scanning..."; objDesc.Font = Enum.Font.GothamMedium; objDesc.TextSize = 12
objDesc.TextColor3 = C.text; objDesc.BackgroundTransparency = 1
objDesc.Size = UDim2.new(1, -16, 1, -24); objDesc.Position = UDim2.new(0, 8, 0, 20)
objDesc.TextXAlignment = Enum.TextXAlignment.Left; objDesc.TextYAlignment = Enum.TextYAlignment.Top
objDesc.TextWrapped = true

local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, -16, 1, -120); scroll.Position = UDim2.new(0, 8, 0, 116)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 2
scroll.ScrollingDirection = Enum.ScrollingDirection.Y; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local layout = Instance.new("UIListLayout", scroll); layout.Padding = UDim.new(0, 6)

local Toggles = {}
local Highlights = {}
local Connections = {}

local function createToggle(name, default, color, isQuest)
    if Toggles[name] then return end
    local row = Instance.new("Frame", scroll)
    row.Size = UDim2.new(1, 0, 0, 30); row.BackgroundColor3 = C.card; row.BorderSizePixel = 0
    local c = Instance.new("UICorner", row); c.CornerRadius = UDim.new(0, 6)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Text = name .. (isQuest and " ⭐" or ""); lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 12
    lbl.TextColor3 = color or C.text; lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -50, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", row)
    btn.Text = ""; btn.Size = UDim2.new(0, 36, 0, 18); btn.Position = UDim2.new(1, -44, 0.5, -9)
    btn.BackgroundColor3 = default and C.accent or C.bg; btn.BorderSizePixel = 0
    local bc = Instance.new("UICorner", btn); bc.CornerRadius = UDim.new(1, 0)
    
    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0, 14, 0, 14); dot.BackgroundColor3 = Color3.new(1,1,1)
    dot.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    local dc = Instance.new("UICorner", dot); dc.CornerRadius = UDim.new(1, 0)
    
    local state = default
    Toggles[name] = {state = state, color = color or C.accent}
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        Toggles[name].state = state
        btn.BackgroundColor3 = state and C.accent or C.bg
        dot.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    end)
end

local function applyESP(obj, text, color)
    if Highlights[obj] then return end
    
    local hl = Instance.new("Highlight")
    hl.FillColor = color; hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    pcall(function() hl.Parent = CoreGui end); hl.Adornee = obj
    
    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 200, 0, 50); bg.AlwaysOnTop = true
    pcall(function() bg.Parent = CoreGui end); bg.Adornee = obj
    
    local txt = Instance.new("TextLabel", bg)
    txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1
    txt.Text = text; txt.TextColor3 = color; txt.TextStrokeTransparency = 0
    txt.Font = Enum.Font.GothamBold; txt.TextSize = 12
    
    Highlights[obj] = {hl = hl, bg = bg, txt = txt, category = text}
    
    local conn = RunService.RenderStepped:Connect(function()
        if not obj or not obj.Parent or not Highlights[obj] then return end
        local st = Toggles[Highlights[obj].category]
        local visible = st and st.state
        hl.Enabled = visible; bg.Enabled = visible
        
        if visible and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local pos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position) or obj.Position
            local dist = (LP.Character.HumanoidRootPart.Position - pos).Magnitude
            txt.Text = text .. " [" .. math.floor(dist) .. "s]"
        end
    end)
    table.insert(Connections, conn)
end

local lastObjText = nil
local function syncObjective()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    local objUI = pg:FindFirstChild("Desc", true)
    if objUI and objUI:IsA("TextLabel") and objUI.Parent.Name == "Objective" then
        local txt = objUI.Text
        if txt ~= lastObjText then
            lastObjText = txt
            objDesc.Text = (txt == "") and "No active objective..." or txt
            
            -- clear old ESP elements
            for obj, data in pairs(Highlights) do pcall(function() data.hl:Destroy(); data.bg:Destroy() end) end
            table.clear(Highlights)
            for _, r in ipairs(scroll:GetChildren()) do if r:IsA("Frame") then r:Destroy() end end
            table.clear(Toggles)
            
            -- Re-scan based on new objective
            local lowTxt = txt:lower()
            
            -- Monsters always track
            for _, d in ipairs(workspace:GetChildren()) do
                if d:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(d) then
                    createToggle("Monster", true, C.monster, false)
                    applyESP(d, "Monster", C.monster)
                end
            end
            
            -- Categorize interactables
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    local act = d.ActionText ~= "" and d.ActionText or "Interact"
                    local lowAct = act:lower()
                    
                    -- Determine if quest related
                    local isQuest = false
                    if txt ~= "" then
                        if lowTxt:find("place") and (lowAct:find("place") or lowAct:find("pick")) then isQuest = true end
                        if lowTxt:find("find") and (lowAct:find("pick") or lowAct:find("take") or lowAct:find("search")) then isQuest = true end
                        if lowTxt:find("read") and lowAct:find("read") then isQuest = true end
                        if lowTxt:find("key") and lowAct:find("pick") then isQuest = true end
                    end
                    
                    if isQuest then
                        createToggle(act, true, C.quest, true)
                        applyESP(d.Parent, act, C.quest)
                    else
                        -- Secondary
                        createToggle(act, false, C.sub, false)
                        applyESP(d.Parent, act, C.sub)
                    end
                end
            end
        end
    end
end

gui.Destroying:Connect(function()
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    for obj, data in pairs(Highlights) do pcall(function() data.hl:Destroy(); data.bg:Destroy() end) end
end)

task.spawn(function()
    while gui.Parent do
        pcall(syncObjective)
        task.wait(2)
    end
end)
