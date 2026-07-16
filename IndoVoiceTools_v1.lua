-- =============================================
-- INDO VOICE MEGA GUI v1
-- Auto Fish (Safe) + Auto Gacha + Rewards + Extras
-- =============================================
if game:GetService('CoreGui'):FindFirstChild('MegaGui') then
    game:GetService('CoreGui'):FindFirstChild('MegaGui'):Destroy()
end
if game:GetService('CoreGui'):FindFirstChild('AutoFishingGui') then
    game:GetService('CoreGui'):FindFirstChild('AutoFishingGui'):Destroy()
end
if game:GetService('CoreGui'):FindFirstChild('AutoGachaProGui') then
    game:GetService('CoreGui'):FindFirstChild('AutoGachaProGui'):Destroy()
end

local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local player = Players.LocalPlayer
local GRF = RS:FindFirstChild('GameRemoteFunctions')

-- ============ STATE ============
local State = {
    autoFish = false, fishThread = nil, fishCount = 0,
    autoGachaAura = false, gachaAuraThread = nil, auraCount = 0,
    autoGachaBlind = false, gachaBlindThread = nil, blindCount = 0,
    autoGachaEgg = false, gachaEggThread = nil, eggCount = 0,
    autoReward = false, rewardThread = nil,
    flyEnabled = false, flyThread = nil,
    noclip = false, noclipConn = nil,
    speedMod = false,
    espEnabled = false, espFolder = nil,
}

-- ============ GUI FRAMEWORK ============
local gui = Instance.new('ScreenGui')
gui.Name = 'MegaGui'
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game:GetService('CoreGui')

local main = Instance.new('Frame')
main.Size = UDim2.new(0, 340, 0, 420)
main.Position = UDim2.new(0.5, -170, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
main.BackgroundTransparency = 0.02
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new('UICorner', main).CornerRadius = UDim.new(0, 16)
local mainStroke = Instance.new('UIStroke', main)
mainStroke.Color = Color3.fromRGB(80, 160, 255)
mainStroke.Thickness = 2

-- Title bar
local titleBar = Instance.new('Frame')
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
local titleLbl = Instance.new('TextLabel')
titleLbl.Size = UDim2.new(1, -40, 1, 0)
titleLbl.Position = UDim2.new(0, 10, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = 'Indo Voice Tools v1'
titleLbl.TextColor3 = Color3.fromRGB(80, 180, 255)
titleLbl.TextSize = 16
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

local closeBtn = Instance.new('TextButton')
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -33, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = 'X'
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new('UICorner', closeBtn).CornerRadius = UDim.new(0, 8)

local minimized = false
local minBtn = Instance.new('TextButton')
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -66, 0, 3)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
minBtn.Text = '-'
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.TextSize = 18
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar
Instance.new('UICorner', minBtn).CornerRadius = UDim.new(0, 8)

-- Tab bar
local tabBar = Instance.new('Frame')
tabBar.Size = UDim2.new(1, 0, 0, 30)
tabBar.Position = UDim2.new(0, 0, 0, 36)
tabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
tabBar.BorderSizePixel = 0
tabBar.Parent = main

local contentFrame = Instance.new('ScrollingFrame')
contentFrame.Size = UDim2.new(1, 0, 1, -66)
contentFrame.Position = UDim2.new(0, 0, 0, 66)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 160, 255)
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
contentFrame.Parent = main

local tabs = {'Fish', 'Gacha', 'Rewards', 'Extras'}
local tabBtns = {}
local tabPages = {}
local activeTab = 'Fish'

for i, tabName in ipairs(tabs) do
    local btn = Instance.new('TextButton')
    btn.Size = UDim2.new(1/#tabs, 0, 1, 0)
    btn.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    btn.BackgroundTransparency = 0.3
    btn.Text = tabName
    btn.TextColor3 = Color3.fromRGB(150, 150, 180)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    tabBtns[tabName] = btn
    
    local page = Instance.new('Frame')
    page.Size = UDim2.new(1, 0, 0, 800)
    page.BackgroundTransparency = 1
    page.Visible = (tabName == activeTab)
    page.Parent = contentFrame
    tabPages[tabName] = page
end

local function switchTab(name)
    activeTab = name
    for n, btn in pairs(tabBtns) do
        if n == name then
            btn.BackgroundColor3 = Color3.fromRGB(40, 80, 160)
            btn.TextColor3 = Color3.new(1,1,1)
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            btn.TextColor3 = Color3.fromRGB(150, 150, 180)
        end
        tabPages[n].Visible = (n == name)
    end
end

for name, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end
switchTab('Fish')

-- UI helpers
local function makeToggle(parent, yPos, label, color, callback)
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, -16, 0, 36)
    frame.Position = UDim2.new(0, 8, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new('UICorner', frame).CornerRadius = UDim.new(0, 10)
    
    local lbl = Instance.new('TextLabel')
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    
    local btn = Instance.new('TextButton')
    btn.Size = UDim2.new(0, 60, 0, 26)
    btn.Position = UDim2.new(1, -68, 0.5, -13)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    btn.Text = 'OFF'
    btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = frame
    Instance.new('UICorner', btn).CornerRadius = UDim.new(0, 8)
    
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        if on then
            btn.Text = 'ON'
            btn.TextColor3 = Color3.fromRGB(100, 255, 100)
            btn.BackgroundColor3 = Color3.fromRGB(30, 100, 50)
        else
            btn.Text = 'OFF'
            btn.TextColor3 = Color3.fromRGB(255, 100, 100)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        end
        callback(on)
    end)
    return btn, lbl
end

local function makeLabel(parent, yPos, text, color, bold)
    local lbl = Instance.new('TextLabel')
    lbl.Size = UDim2.new(1, -16, 0, 18)
    lbl.Position = UDim2.new(0, 8, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(140, 140, 170)
    lbl.TextSize = 11
    lbl.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = parent
    return lbl
end

-- ============================================
-- TAB 1: AUTO FISH (SAFE)
-- ============================================
local fishPage = tabPages['Fish']
local fishStatusLbl = makeLabel(fishPage, 4, 'Status: OFF', Color3.fromRGB(255, 100, 100), true)
local fishCountLbl = makeLabel(fishPage, 24, 'Fish: 0 | Minigames Won: 0', Color3.fromRGB(160, 180, 200))
local fishLogLbl = makeLabel(fishPage, 44, 'Log: idle', Color3.fromRGB(120, 130, 150))

local fishY = 68

-- Auto-Fish Safe Logic
local function autoPlayMinigame(fishingUI)
    -- Phase 1: Auto-tap pre-fishing buttons
    local preFishing = fishingUI:FindFirstChild('PreFishingHolder')
    
    if preFishing and preFishing.Visible then
        fishLogLbl.Text = 'Log: Tapping buttons...'
        for attempt = 1, 10 do
            if not State.autoFish then return false end
            local found = false
            for _, child in preFishing:GetChildren() do
                if child:IsA('ImageButton') or child:IsA('TextButton') then
                    if child.Visible and child.Name ~= 'TapButton' then
                        pcall(function() firesignal(child.Activated) end)
                        pcall(function() fireclick(child) end)
                        found = true
                        task.wait(0.15 + math.random() * 0.15)
                    end
                end
            end
            if not found then break end
            task.wait(0.2)
        end
    end
    
    -- Phase 2: Auto-play bar minigame
    local fishHolder = fishingUI:FindFirstChild('FishingHolder')
    if not fishHolder then
        task.wait(1)
        fishHolder = fishingUI:FindFirstChild('FishingHolder')
    end
    
    local waitStart = tick()
    while State.autoFish and fishingUI.Parent and (tick() - waitStart) < 8 do
        if fishHolder and fishHolder.Visible then break end
        task.wait(0.1)
    end
    
    if not fishHolder or not fishHolder.Visible then
        return true
    end
    
    fishLogLbl.Text = 'Log: Playing minigame...'
    
    local infoLabel = fishingUI:FindFirstChild('InfoLabel', true)
    local fishIcon = fishingUI:FindFirstChild('FishIcon', true)
    
    -- Auto-play: click when green, stop when red
    local startTime = tick()
    while State.autoFish and fishingUI.Parent and (tick() - startTime) < 30 do
        local isGreen = false
        
        if infoLabel then
            isGreen = infoLabel.Text:find('raise') ~= nil
        elseif fishIcon then
            local c = fishIcon.ImageColor3
            isGreen = c.G > c.R
        end
        
        if isGreen then
            mouse1click()
            task.wait(0.05 + math.random() * 0.03)
        else
            task.wait(0.05)
        end
    end
    
    return true
end

local function startAutoFish()
    State.autoFish = true
    State.fishCount = 0
    fishStatusLbl.Text = 'Status: ON'
    fishStatusLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
    
    State.fishThread = task.spawn(function()
        while State.autoFish do
            local char = player.Character
            if not char then task.wait(1) continue end
            local rod = nil
            for _, t in char:GetChildren() do
                if t:IsA('Tool') and t:FindFirstChild('Catch') then rod = t break end
            end
            if not rod then
                fishLogLbl.Text = 'Log: Equip rod!'
                task.wait(1)
                continue
            end
            
            -- Step 1: Cast (hold click)
            fishLogLbl.Text = 'Log: Casting...'
            fishStatusLbl.Text = 'Status: Casting'
            local holdTime = 0.3 + math.random() * 0.5
            mouse1press()
            task.wait(holdTime)
            mouse1release()
            
            -- Step 2: Wait for FishingUI (fish bite)
            fishLogLbl.Text = 'Log: Waiting for bite...'
            fishStatusLbl.Text = 'Status: Waiting'
            
            local fishingUI = nil
            local waitStart = tick()
            while State.autoFish and (tick() - waitStart) < 30 do
                fishingUI = player.PlayerGui:FindFirstChild('FishingUI')
                if fishingUI then break end
                task.wait(0.1)
            end
            
            if not fishingUI then
                fishLogLbl.Text = 'Log: No bite, recast...'
                task.wait(0.5)
                continue
            end
            
            if not State.autoFish then break end
            
            -- Step 3: Auto-play minigame
            fishStatusLbl.Text = 'Status: Playing minigame!'
            task.wait(0.3)
            autoPlayMinigame(fishingUI)
            
            State.fishCount = State.fishCount + 1
            fishCountLbl.Text = 'Fish: ' .. State.fishCount
            fishLogLbl.Text = 'Log: Done #' .. State.fishCount
            fishStatusLbl.Text = 'Status: Caught #' .. State.fishCount
            
            task.wait(2)
        end
    end)
end

local function stopAutoFish()
    State.autoFish = false
    if State.fishThread then pcall(task.cancel, State.fishThread) State.fishThread = nil end
    fishStatusLbl.Text = 'Status: OFF'
    fishStatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
    fishLogLbl.Text = 'Log: Stopped'
end

makeToggle(fishPage, fishY, 'Auto Fish (Safe)', Color3.fromRGB(50, 150, 220), function(on)
    if on then startAutoFish() else stopAutoFish() end
end)

-- ============================================
-- TAB 2: AUTO GACHA
-- ============================================
local gachaPage = tabPages['Gacha']
local gachaStatusLbl = makeLabel(gachaPage, 4, 'Gacha System - ForceEnd bypass', Color3.fromRGB(180, 140, 255), true)

local function makeGachaToggle(yPos, label, prefix, startFn, stopFn)
    local countLbl = makeLabel(gachaPage, yPos, prefix .. ': 0 rolls', Color3.fromRGB(160, 180, 200))
    makeToggle(gachaPage, yPos + 20, label, nil, function(on)
        if on then startFn(countLbl, prefix) else stopFn() end
    end)
    return countLbl
end

local function findForceEnd(keyword)
    for _, v in getgc(true) do
        if type(v) == 'table' then
            for key, val in pairs(v) do
                if type(key) == 'string' and key == 'ForceEnd' and type(val) == 'function' then
                    local env = getfenv(val)
                    if env and env.script then
                        local sname = env.script.Name:lower() or ''
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

local function genericGachaStart(stateKey, threadKey, countKey, keyword, interactKey, countLbl, prefix)
    State[stateKey] = true
    State[countKey] = 0
    State[threadKey] = task.spawn(function()
        while State[stateKey] do
            local prompt = nil
            for _, desc in workspace:GetDescendants() do
                if desc:IsA('ProximityPrompt') and desc.ObjectText:lower():find(keyword:lower()) then
                    prompt = desc
                    break
                end
            end
            if not prompt then
                for _, desc in workspace:GetDescendants() do
                    if desc:IsA('ProximityPrompt') then
                        local parent = desc.Parent
                        if parent and parent.Name:lower():find(keyword:lower()) then
                            prompt = desc
                            break
                        end
                    end
                end
            end
            
            if prompt then
                fireproximityprompt(prompt)
                task.wait(0.3)
                local fe = findForceEnd(keyword == 'blind' and 'blind' or keyword == 'egg' and 'egg' or 'aura')
                if fe then
                    pcall(fe)
                end
                State[countKey] = State[countKey] + 1
                countLbl.Text = prefix .. ': ' .. State[countKey] .. ' rolls'
            end
            task.wait(0.15)
        end
    end)
end

-- Aura
makeGachaToggle(26, 'Auto Roll Aura', 'Aura', function(lbl, pf)
    genericGachaStart('autoGachaAura', 'gachaAuraThread', 'auraCount', 'aura', 'e', lbl, pf)
end, function()
    State.autoGachaAura = false
    if State.gachaAuraThread then pcall(task.cancel, State.gachaAuraThread) end
end)

-- BlindBox
makeGachaToggle(100, 'Auto BlindBox', 'BlindBox', function(lbl, pf)
    genericGachaStart('autoGachaBlind', 'gachaBlindThread', 'blindCount', 'blind', 'e', lbl, pf)
end, function()
    State.autoGachaBlind = false
    if State.gachaBlindThread then pcall(task.cancel, State.gachaBlindThread) end
end)

-- Egg/Pet
makeGachaToggle(174, 'Auto Egg/Pet', 'Egg', function(lbl, pf)
    genericGachaStart('autoGachaEgg', 'gachaEggThread', 'eggCount', 'egg', 'e', lbl, pf)
end, function()
    State.autoGachaEgg = false
    if State.gachaEggThread then pcall(task.cancel, State.gachaEggThread) end
end)

-- ============================================
-- TAB 3: AUTO REWARDS
-- ============================================
local rewardPage = tabPages['Rewards']
local rewardStatusLbl = makeLabel(rewardPage, 4, 'Auto-claim session & daily rewards', Color3.fromRGB(255, 200, 80), true)
local rewardLogLbl = makeLabel(rewardPage, 24, 'Log: idle', Color3.fromRGB(140, 140, 160))

makeToggle(rewardPage, 48, 'Auto Claim Rewards', nil, function(on)
    State.autoReward = on
    if on then
        State.rewardThread = task.spawn(function()
            while State.autoReward do
                local ok1, res1 = pcall(function()
                    return GRF.CollectSessionRewardFunction:InvokeServer()
                end)
                if ok1 and res1 then
                    rewardLogLbl.Text = 'Log: Session reward claimed!'
                end
                local ok2, res2 = pcall(function()
                    return GRF.CollectDailyRewardFunction:InvokeServer()
                end)
                if ok2 and res2 then
                    rewardLogLbl.Text = 'Log: Daily reward claimed!'
                end
                task.wait(30)
            end
        end)
    else
        if State.rewardThread then pcall(task.cancel, State.rewardThread) end
        rewardLogLbl.Text = 'Log: Stopped'
    end
end)

-- NameTag Changer
makeLabel(rewardPage, 100, '── NameTag Changer ──', Color3.fromRGB(180, 140, 255), true)
local nameInput = Instance.new('TextBox')
nameInput.Size = UDim2.new(1, -16, 0, 30)
nameInput.Position = UDim2.new(0, 8, 0, 122)
nameInput.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
nameInput.Text = ''
nameInput.PlaceholderText = 'Enter new name...'
nameInput.TextColor3 = Color3.new(1,1,1)
nameInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 130)
nameInput.TextSize = 13
nameInput.Font = Enum.Font.Gotham
nameInput.BorderSizePixel = 0
nameInput.ClearTextOnFocus = false
nameInput.Parent = rewardPage
Instance.new('UICorner', nameInput).CornerRadius = UDim.new(0, 8)

local nameBtn = Instance.new('TextButton')
nameBtn.Size = UDim2.new(1, -16, 0, 30)
nameBtn.Position = UDim2.new(0, 8, 0, 156)
nameBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 160)
nameBtn.Text = 'Change Name (Server-Side!)'
nameBtn.TextColor3 = Color3.new(1,1,1)
nameBtn.TextSize = 13
nameBtn.Font = Enum.Font.GothamBold
nameBtn.BorderSizePixel = 0
nameBtn.Parent = rewardPage
Instance.new('UICorner', nameBtn).CornerRadius = UDim.new(0, 8)
nameBtn.MouseButton1Click:Connect(function()
    if nameInput.Text ~= '' then
        local ok, res = pcall(function()
            return GRF.ChangeNameTagFunction:InvokeServer(nameInput.Text)
        end)
        rewardLogLbl.Text = ok and res and 'Name changed!' or 'Failed (cooldown 3 days)'
    end
end)

-- ============================================
-- TAB 4: EXTRAS (Client-Side)
-- ============================================
local extPage = tabPages['Extras']
makeLabel(extPage, 4, '── Client-Side Mods ──', Color3.fromRGB(255, 180, 80), true)

-- Speed
local speedLbl = makeLabel(extPage, 26, 'WalkSpeed: 16 (default)', Color3.fromRGB(160, 180, 200))
makeToggle(extPage, 46, 'Speed Boost (x2)', nil, function(on)
    State.speedMod = on
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum then
            hum.WalkSpeed = on and 32 or 16
            speedLbl.Text = 'WalkSpeed: ' .. hum.WalkSpeed
        end
    end
end)

-- Jump Power
makeToggle(extPage, 88, 'High Jump (x2)', nil, function(on)
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = on and 100 or 50
        end
    end
end)

-- Noclip
makeToggle(extPage, 130, 'Noclip (Walk thru walls)', nil, function(on)
    State.noclip = on
    if on then
        State.noclipConn = RunService.Stepped:Connect(function()
            local char = player.Character
            if char then
                for _, part in char:GetDescendants() do
                    if part:IsA('BasePart') then
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
makeToggle(extPage, 172, 'Fly (WASD + Space/Shift)', nil, function(on)
    State.flyEnabled = on
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    
    if on then
        local bg = Instance.new('BodyGyro')
        bg.Name = 'FlyGyro'
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.Parent = hrp
        
        local bv = Instance.new('BodyVelocity')
        bv.Name = 'FlyVelocity'
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
        local bg = hrp:FindFirstChild('FlyGyro')
        local bv = hrp:FindFirstChild('FlyVelocity')
        if bg then bg:Destroy() end
        if bv then bv:Destroy() end
    end
end)

-- ESP
makeToggle(extPage, 214, 'ESP (See players thru walls)', nil, function(on)
    State.espEnabled = on
    if on then
        State.espFolder = Instance.new('Folder')
        State.espFolder.Name = 'ESP'
        State.espFolder.Parent = game:GetService('CoreGui')
        
        local function addESP(p)
            if p == player then return end
            task.spawn(function()
                while State.espEnabled and p.Parent do
                    local char = p.Character
                    if char then
                        local head = char:FindFirstChild('Head')
                        if head then
                            local existing = State.espFolder:FindFirstChild(p.Name)
                            if not existing then
                                local bb = Instance.new('BillboardGui')
                                bb.Name = p.Name
                                bb.Adornee = head
                                bb.Size = UDim2.new(0, 100, 0, 30)
                                bb.StudsOffset = Vector3.new(0, 3, 0)
                                bb.AlwaysOnTop = true
                                bb.Parent = State.espFolder
                                local tl = Instance.new('TextLabel')
                                tl.Size = UDim2.new(1,0,1,0)
                                tl.BackgroundTransparency = 1
                                tl.Text = p.Name
                                tl.TextColor3 = Color3.fromRGB(255, 255, 100)
                                tl.TextStrokeTransparency = 0
                                tl.TextSize = 14
                                tl.Font = Enum.Font.GothamBold
                                tl.Parent = bb
                                
                                local hl = Instance.new('Highlight')
                                hl.Name = 'ESP_HL'
                                hl.FillColor = Color3.fromRGB(255, 0, 100)
                                hl.FillTransparency = 0.7
                                hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                                hl.Adornee = char
                                hl.Parent = char
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
        for _, p in Players:GetPlayers() do addESP(p) end
        Players.PlayerAdded:Connect(addESP)
    else
        if State.espFolder then State.espFolder:Destroy() State.espFolder = nil end
        for _, p in Players:GetPlayers() do
            if p.Character then
                local hl = p.Character:FindFirstChild('ESP_HL')
                if hl then hl:Destroy() end
            end
        end
    end
end)

-- Infinite Jump
makeToggle(extPage, 256, 'Infinite Jump', nil, function(on)
    State.infJump = on
end)
UIS.JumpRequest:Connect(function()
    if State.infJump then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- Minimize/Close
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    contentFrame.Visible = not minimized
    tabBar.Visible = not minimized
    main.Size = minimized and UDim2.new(0, 340, 0, 36) or UDim2.new(0, 340, 0, 420)
    minBtn.Text = minimized and '+' or '-'
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
    if State.noclipConn then State.noclipConn:Disconnect() end
    if State.flyThread then pcall(function() State.flyThread:Disconnect() end) end
    if State.espFolder then State.espFolder:Destroy() end
    gui:Destroy()
end)

print('[Indo Voice Tools v1] Loaded! Tabs: Fish, Gacha, Rewards, Extras')
