--[[
    Indo Voice Auto Farm Hub v4.2
    
    v4.2:
    - Detect "fully occupied" notification → auto move to next stone
    - Auto re-equip board when knocked off during travel
    - Sprint (Shift hold) while moving
    - Continuous movement: no stops, more jumps, zigzag
    - PathfindingService with obstacle avoidance
    - ESP hotspot clearly labeled
    
    Toggle UI: K | Stop: _G.AutoFarmEnabled_v3 = false
]]

if _G.AutoFarmEnabled_v3 then
    _G.AutoFarmEnabled_v3 = false
    task.wait(0.2)
end

_G.AutoFarmEnabled_v3 = true
_G.AutoFarmRunID = tick()
local myRunID = _G.AutoFarmRunID

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local LP = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")

local RarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legend = 5, Mythic = 6, Ancient = 7 }
local RarityNames = { "Common", "Uncommon", "Rare", "Epic", "Legend", "Mythic", "Ancient" }
local Cfg = {
    AutoMine = true,
    FullAuto = false,
    MineDelay = 0.8,
    LoopDelay = 1.0,
    StoneESP = false,
    ShowTrail = true,
    AutoReroll = false,
    MinRarity = "Rare", -- skip anything below this rarity
    MinHitsPerPhase = 6, -- legacy fallback
    MaxDist = 250,
    PreferBuddy = true,
    PreferHotspot = true,
    ZoneOnly = false,
    ZoneRadius = 100,
    ZoneCenter = nil, -- Vector3, set by "Set Home" button
    
    -- Gacha Settings
    AutoGacha = false,
    GachaBox = "Summer2026",
    GachaMode = 10,
    GachaSpeed = 8,
    GachaAutoClick = true,
    GachaDelay = 1.0,
}
local Stats = { mined = 0, phase = "Idle" }
local _skipCurrentStone = false -- flag when "fully occupied"

-- ═══════════════════════════════════════════════
-- REMOTE EVENT LISTENER
-- ═══════════════════════════════════════════════
_G.LatestRarityFromRemote = nil

local function getLocalStartMinigame()
    local c = LP.Character
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and (t.Name:lower():find("pickaxe") or t.Name:lower():find("pick")) then
                local rm = t:FindFirstChild("StartMinigame", true)
                if rm and rm:IsA("RemoteEvent") then return rm end
            end
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and (t.Name:lower():find("pickaxe") or t.Name:lower():find("pick")) then
                local rm = t:FindFirstChild("StartMinigame", true)
                if rm and rm:IsA("RemoteEvent") then return rm end
            end
        end
    end
    return nil
end

task.spawn(function()
    while _G.AutoFarmEnabled_v3 and _G.AutoFarmRunID == myRunID do
        local remote = getLocalStartMinigame()
        if remote and _G.CurrentStartMinigameRemote ~= remote then
            if _G.StartMinigameConn then _G.StartMinigameConn:Disconnect() end
            _G.CurrentStartMinigameRemote = remote
            _G.StartMinigameConn = remote.OnClientEvent:Connect(function(rarity, data)
                if type(rarity) == "string" then
                    _G.LatestRarityFromRemote = rarity
                    pcall(function()
                        game.StarterGui:SetCore("SendNotification", {
                            Title = "RemoteSpy Hit!",
                            Text = "Rarity: " .. rarity,
                            Duration = 3,
                        })
                    end)
                end
            end)
            warn("[AUTO-MINE] Hooked to Pickaxe Remote: " .. remote:GetFullName())
        end
        task.wait(0.5) -- Faster polling to catch quick equips
    end
end)


-- ═══════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════

local function vimClick(x, y)
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait()
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

local function getChar() return LP.Character end
local function getHRP()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local hrp = getHRP()
    if hrp and hrp.Parent then
        return hrp.Parent:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function doJump()
    local hum = getHum()
    if hum then hum.Jump = true end
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

-- ═══ SPRINT (hold Shift) ═══
local _sprinting = false

local function startSprint()
    if _sprinting then return end
    _sprinting = true
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
    end)
end

local function stopSprint()
    if not _sprinting then return end
    _sprinting = false
    pcall(function()
        VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end)
end

-- ═══ TOOL MANAGEMENT ═══

local function findBoard()
    local c = getChar()
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("SpeedIncrease") then return t, true end
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("SpeedIncrease") then return t, false end
        end
    end
    return nil, false
end

local function isPickEquipped()
    local c = getChar()
    if not c then return false end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("IsPickaxe") then return true end
    end
    return false
end

local function equipPick()
    if isPickEquipped() then return true end
    local hum = getHum()
    if not hum then return false end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("IsPickaxe") then
                hum:EquipTool(t); task.wait(0.4); return true
            end
        end
    end
    return false
end

local function unequipPick()
    local hum = getHum()
    if hum then
        hum:UnequipTools()
        task.wait(0.2)
    end
end

local function isBoardEquipped()
    local c = getChar()
    if not c then return false end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("SpeedIncrease") then return true end
    end
    return false
end

local function equipBoard()
    if isBoardEquipped() then return true end
    local hum = getHum()
    if not hum then return false end
    local board = findBoard()
    if board then hum:EquipTool(board); task.wait(0.4) end
    return isBoardEquipped()
end

-- ═══ "FULLY OCCUPIED" DETECTION ═══

local function isFullyOccupiedMsg()
    local msg = PGui:FindFirstChild("Message")
    if not msg then return false end
    local holder = msg:FindFirstChild("MessageHolder")
    if not holder then return false end
    local label = holder:FindFirstChild("MessageLabel")
    if not label then return false end
    return label.Visible and label.Text:lower():find("fully occupied") ~= nil
end

-- Watch for the notification and set skip flag
task.spawn(function()
    while _G.AutoFarmEnabled_v3 and _G.AutoFarmRunID == myRunID do
        if isFullyOccupiedMsg() then
            _skipCurrentStone = true
        end
        task.wait(0.3)
    end
end)

-- ═══ STONE DETECTION ═══

local function getStoneFolder()
    local main = workspace:FindFirstChild("Main")
    return main and main:FindFirstChild("ActiveMiningStones")
end

local function countPlayersNear(pos, radius)
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local ohrp = p.Character:FindFirstChild("HumanoidRootPart")
            if ohrp and (ohrp.Position - pos).Magnitude <= radius then
                count = count + 1
            end
        end
    end
    return count
end

local _lastStoneName = "" -- track current stone to skip it
local _ignoredStones = {}

local function blacklistCurrentStone()
    local c = getChar()
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local folder = getStoneFolder()
    if not folder then return end
    local closest, closestDist = nil, math.huge
    for _, stone in ipairs(folder:GetChildren()) do
        local cf = stone:GetBoundingBox()
        local d = (cf.Position - hrp.Position).Magnitude
        if d < closestDist then
            closest = stone
            closestDist = d
        end
    end
    if closest then
        _ignoredStones[closest] = true
        task.delay(120, function() _ignoredStones[closest] = nil end)
    end
end

local function scoreStone(stone, myPos)
    local cf = stone:GetBoundingBox()
    local dist = (cf.Position - myPos).Magnitude
    local available = stone:GetAttribute("AvailableSlot") or 0
    local isHotspot = stone:GetAttribute("IsHotspot") or false
    local playersNear = countPlayersNear(cf.Position, 25)

    if available <= 0 then return -9999 end
    if dist > Cfg.MaxDist then return -9999 end -- Too far, skip
    if _skipCurrentStone and stone.Name == _lastStoneName then return -9999 end
    if _ignoredStones[stone] then return -9999 end

    -- Zone filter: only mine stones within ZoneRadius of ZoneCenter
    if Cfg.ZoneOnly and Cfg.ZoneCenter then
        local distFromHome = (cf.Position - Cfg.ZoneCenter).Magnitude
        if distFromHome > Cfg.ZoneRadius then return -9999 end
    end

    local score = 1000
    score = score - dist * 1
    if Cfg.PreferBuddy then
        if playersNear >= 2 then
            score = score + 800 -- 2+ players gives +25% luck buff!
        elseif playersNear == 1 then
            score = score + 400 -- 1 player removes solo penalty
        end
    end
    if Cfg.PreferHotspot and isHotspot then score = score + 1200 end
    score = score + available * 10
    return score
end

local function getBestStone()
    local hrp = getHRP()
    if not hrp then return nil, 9999 end
    local folder = getStoneFolder()
    if not folder then return nil, 9999 end
    local best, bestScore, bestDist = nil, -9999, 9999
    for _, s in ipairs(folder:GetChildren()) do
        if not s:IsA("Model") then continue end
        pcall(function()
            local cf = s:GetBoundingBox()
            local d = (cf.Position - hrp.Position).Magnitude
            local sc = scoreStone(s, hrp.Position)
            if sc > bestScore then bestScore = sc; best = s; bestDist = d end
        end)
    end
    return best, bestScore, bestDist
end

local function getNearestStone()
    local hrp = getHRP()
    if not hrp then return nil, 9999 end
    local folder = getStoneFolder()
    if not folder then return nil, 9999 end
    local best, bestD = nil, 9999
    for _, s in ipairs(folder:GetChildren()) do
        if s:IsA("Model") then
            pcall(function()
                local avail = s:GetAttribute("AvailableSlot") or 0
                if avail <= 0 then return end -- Skip depleted stones
                local d = (s:GetBoundingBox().Position - hrp.Position).Magnitude
                if d < bestD then bestD = d; best = s end
            end)
        end
    end
    return best, bestD
end

local function isNearStone() return select(2, getNearestStone()) <= 14 end

-- ═══════════════════════════════════════════════
-- STONE ESP
-- ═══════════════════════════════════════════════

local oldEsp = workspace.CurrentCamera:FindFirstChild("StoneESP_Folder")
if oldEsp then oldEsp:Destroy() end
local espFolder = Instance.new("Folder")
espFolder.Name = "StoneESP_Folder"
espFolder.Parent = workspace.CurrentCamera

local function clearESP()
    for _, c in ipairs(espFolder:GetChildren()) do c:Destroy() end
    local folder = getStoneFolder()
    if folder then
        for _, s in ipairs(folder:GetChildren()) do
            local h = s:FindFirstChild("StoneESP_HL")
            if h then h:Destroy() end
        end
    end
end

local function updateESP()
    if not Cfg.StoneESP then clearESP(); return end
    local folder = getStoneFolder()
    if not folder then return end
    local hrp = getHRP()

    for _, bb in ipairs(espFolder:GetChildren()) do
        if not bb:GetAttribute("StoneRef") or not folder:FindFirstChild(bb:GetAttribute("StoneRef")) then
            bb:Destroy()
        end
    end

    for _, stone in ipairs(folder:GetChildren()) do
        if not stone:IsA("Model") then continue end

        local isHotspot = stone:GetAttribute("IsHotspot") or false
        local avail = stone:GetAttribute("AvailableSlot") or 0
        local maxSlot = stone:GetAttribute("MaxSlot") or 10

        -- Zone check
        local ok2, cf2 = pcall(function() return stone:GetBoundingBox() end)
        local inZone = true
        if ok2 and Cfg.ZoneOnly and Cfg.ZoneCenter then
            local distFromHome = (cf2.Position - Cfg.ZoneCenter).Magnitude
            inZone = distFromHome <= Cfg.ZoneRadius
        end

        local hl = stone:FindFirstChild("StoneESP_HL")
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "StoneESP_HL"
            hl.FillTransparency = 0.4
            hl.OutlineTransparency = 0
            hl.Adornee = stone
            hl.Parent = stone
        end

        if not inZone then
            -- Outside zone: dark red
            hl.FillColor = Color3.fromRGB(100, 20, 20)
            hl.OutlineColor = Color3.fromRGB(150, 30, 30)
            hl.FillTransparency = 0.7
        elseif isHotspot then
            hl.FillColor = Color3.fromRGB(255, 50, 50)
            hl.OutlineColor = Color3.fromRGB(255, 100, 50)
            hl.FillTransparency = 0.15
        elseif avail <= 0 then
            hl.FillColor = Color3.fromRGB(80, 80, 80)
            hl.OutlineColor = Color3.fromRGB(120, 120, 120)
            hl.FillTransparency = 0.75
        else
            hl.FillColor = Color3.fromRGB(50, 255, 50)
            hl.OutlineColor = Color3.fromRGB(100, 255, 100)
            hl.FillTransparency = 0.4
        end

        local bbName = "ESP_BB_" .. stone.Name
        local bb = espFolder:FindFirstChild(bbName)
        if not bb then
            bb = Instance.new("BillboardGui")
            bb.Name = bbName
            bb:SetAttribute("StoneRef", stone.Name)
            bb.Size = UDim2.new(0, 150, 0, 50)
            bb.StudsOffset = Vector3.new(0, 6, 0)
            bb.AlwaysOnTop = true
            bb.Parent = espFolder

            local label = Instance.new("TextLabel")
            label.Name = "Info"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Font = Enum.Font.GothamBold
            label.TextScaled = true
            label.Parent = bb
        end

        bb.Adornee = stone
        local ok, cf = pcall(function() return stone:GetBoundingBox() end)
        if not ok then continue end
        local dist = hrp and (cf.Position - hrp.Position).Magnitude or 0
        local players = countPlayersNear(cf.Position, 25)
        local lbl = bb:FindFirstChild("Info")
        if lbl then
            local zoneTag = ""
            if Cfg.ZoneOnly and Cfg.ZoneCenter then
                zoneTag = inZone and "\u{2705} " or "\u{274c} "
            end
            local line1 = ""
            if isHotspot then line1 = "\u{1f525} HOTSPOT \u{1f525}\n" end
            local line2 = zoneTag .. "\u{26cf}" .. avail .. "/" .. maxSlot
            if players > 0 then line2 = line2 .. " \u{1f465}" .. players end
            line2 = line2 .. " | " .. math.floor(dist) .. "m"
            lbl.Text = line1 .. line2

            if not inZone then
                lbl.TextColor3 = Color3.fromRGB(150, 50, 50)
            elseif isHotspot then
                lbl.TextColor3 = Color3.fromRGB(255, 100, 50)
            elseif dist <= 14 then
                lbl.TextColor3 = Color3.fromRGB(100, 255, 100)
            elseif avail <= 0 then
                lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                lbl.TextColor3 = Color3.fromRGB(255, 255, 100)
            end
        end
    end

    -- Zone circle visualization
    local zoneCircle = espFolder:FindFirstChild("ZoneCircle")
    if Cfg.ZoneOnly and Cfg.ZoneCenter then
        if not zoneCircle then
            zoneCircle = Instance.new("Part")
            zoneCircle.Name = "ZoneCircle"
            zoneCircle.Shape = Enum.PartType.Cylinder
            zoneCircle.Anchored = true
            zoneCircle.CanCollide = false
            zoneCircle.Material = Enum.Material.ForceField
            zoneCircle.Color = Color3.fromRGB(0, 150, 255)
            zoneCircle.Transparency = 0.85
            zoneCircle.Parent = espFolder
        end
        local r = Cfg.ZoneRadius
        zoneCircle.Size = Vector3.new(1, r * 2, r * 2)
        zoneCircle.CFrame = CFrame.new(Cfg.ZoneCenter) * CFrame.Angles(0, 0, math.rad(90))
    else
        if zoneCircle then zoneCircle:Destroy() end
    end
end

-- ═══ PATH TRAIL VISUALIZATION ═══
local trailFolder = Instance.new("Folder")
trailFolder.Name = "PathTrail"
trailFolder.Parent = workspace

local function clearTrail()
    for _, c in ipairs(trailFolder:GetChildren()) do c:Destroy() end
end

local function showTrail(waypoints)
    clearTrail()
    if not Cfg.ShowTrail or not waypoints then return end
    for i = 2, #waypoints do
        local wp = waypoints[i]
        local dot = Instance.new("Part")
        dot.Name = "TrailDot_" .. i
        dot.Shape = Enum.PartType.Ball
        dot.Size = Vector3.new(1.2, 1.2, 1.2)
        dot.Position = wp.Position + Vector3.new(0, 1.5, 0)
        dot.Anchored = true
        dot.CanCollide = false
        dot.Material = Enum.Material.Neon
        dot.Transparency = 0.3
        dot.CastShadow = false
        -- Color: green for normal, yellow for jump
        if wp.Action == Enum.PathWaypointAction.Jump then
            dot.Color = Color3.fromRGB(255, 255, 80)
        else
            dot.Color = Color3.fromRGB(80, 255, 120)
        end
        dot.Parent = trailFolder
    end
end

local function removePassedDots(pos, radius)
    for _, dot in ipairs(trailFolder:GetChildren()) do
        local d = dot.Position - pos
        local dist2D = Vector3.new(d.X, 0, d.Z).Magnitude
        if dist2D < radius then
            dot:Destroy()
        end
    end
end

-- ═══ WATER OBSTACLE INJECTOR ═══
task.spawn(function()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local isWater = false
            if obj.Material == Enum.Material.Water then isWater = true end
            if string.find(string.lower(obj.Name), "water") then isWater = true end
            if string.find(string.lower(obj.Name), "puddle") then isWater = true end
            
            if isWater and not obj:FindFirstChild("WaterBlocker") then
                local mod = Instance.new("PathfindingModifier")
                mod.Name = "WaterBlocker"
                mod.Label = "WaterObstacle"
                mod.PassThrough = false -- Completely block pathfinding
                mod.Parent = obj
            end
        end
    end
end)

local dynamicObstacles = workspace:FindFirstChild("DynamicObstacles")
if not dynamicObstacles then
    dynamicObstacles = Instance.new("Folder")
    dynamicObstacles.Name = "DynamicObstacles"
    dynamicObstacles.Parent = workspace
end

local function addDynamicObstacle(pos)
    local p = Instance.new("Part")
    p.Name = "StuckBlocker"
    p.Size = Vector3.new(15, 15, 15)
    p.Position = pos
    p.Anchored = true
    p.CanCollide = false
    p.Transparency = 1
    
    local mod = Instance.new("PathfindingModifier")
    mod.Label = "StuckObstacle"
    mod.PassThrough = false
    mod.Parent = p
    
    p.Parent = dynamicObstacles
    
    task.delay(60, function()
        if p and p.Parent then p:Destroy() end
    end)
end

local function computePath(startPos, endPos)
    local path = PathfindingService:CreatePath({
        AgentRadius = 3,
        AgentHeight = 6,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 8,
        Costs = {
            Water = math.huge,
            WaterObstacle = math.huge,
            StuckObstacle = math.huge
        }
    })
    local ok = pcall(function() path:ComputeAsync(startPos, endPos) end)
    if ok and path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    end
    return nil
end

local function humanizedWalkTo(targetStone)
    local hum = getHum()
    local hrp = getHRP()
    if not hum or not hrp or not targetStone then return false end

    local startPos = hrp.Position
    local targetPos = targetStone:GetBoundingBox().Position
    local totalDist = (targetPos - startPos).Magnitude

    -- Board for travel
    if totalDist > 25 then
        equipBoard()
        task.wait(0.2)
    end

    startSprint()

    -- Background random jumper: fires every 1-3 seconds
    local jumping = true
    task.spawn(function()
        while jumping and _G.AutoFarmEnabled_v3 and _G.AutoFarmRunID == myRunID and Cfg.FullAuto do
            task.wait(math.random(10, 30) / 10) -- 1-3 sec random
            if jumping then
                doJump()
            end
        end
    end)

    -- Background board checker
    task.spawn(function()
        while jumping and _G.AutoFarmEnabled_v3 and _G.AutoFarmRunID == myRunID and Cfg.FullAuto do
            task.wait(1)
            if jumping and totalDist > 25 and not isBoardEquipped() then
                equipBoard()
            end
        end
    end)

    -- Direction for zigzag perpendicular
    local fwd = (targetPos - startPos)
    fwd = Vector3.new(fwd.X, 0, fwd.Z)
    if fwd.Magnitude < 0.5 then fwd = Vector3.new(1, 0, 0) end
    fwd = fwd.Unit
    local perpX, perpZ = -fwd.Z, fwd.X

    -- Try PathfindingService
    local waypoints = computePath(startPos, targetPos)

    if waypoints and #waypoints > 1 then
        Stats.phase = Stats.phase .. " 🗺️"
        showTrail(waypoints)

        local lastPos = hrp.Position
        local stuckTime = 0

        for i = 2, #waypoints do
            if not _G.AutoFarmEnabled_v3 or _G.AutoFarmRunID ~= myRunID or not Cfg.FullAuto or _skipCurrentStone then break end
            
            -- Check if stone got depleted while walking
            local currentAvail = targetStone:GetAttribute("AvailableSlot") or 0
            if currentAvail <= 0 then 
                Stats.phase = "Stone depleted mid-walk! Aborting..."
                break 
            end

            local wp = waypoints[i]
            local goal = wp.Position

            -- Random zigzag: only 30% of waypoints, skip last 2
            if i < #waypoints - 1 and math.random() < 0.3 then
                local amt = math.random(-6, 6)
                goal = Vector3.new(goal.X + perpX * amt, goal.Y, goal.Z + perpZ * amt)
            end

            if wp.Action == Enum.PathWaypointAction.Jump then
                doJump()
            end

            hum:MoveTo(goal)

            -- Continuous wait, much shorter and faster checks
            local elapsed = 0
            while elapsed < 3 and _G.AutoFarmEnabled_v3 and _G.AutoFarmRunID == myRunID do
                if (hrp.Position - targetPos).Magnitude <= 14 then 
                    -- Arrived (or user moved manually)
                    jumping = false; clearTrail(); stopSprint(); return true 
                end
                if (targetStone:GetAttribute("AvailableSlot") or 0) <= 0 then break end
                
                local d = hrp.Position - goal
                if Vector3.new(d.X, 0, d.Z).Magnitude < 6 then break end

                -- Remove trail dots we've passed (radius 12 to handle stairs better)
                removePassedDots(hrp.Position, 12)

                -- Stuck check every 0.5s
                if elapsed > 0 and elapsed % 0.5 < 0.11 then
                    if (hrp.Position - lastPos).Magnitude < 0.5 then
                        stuckTime = stuckTime + 0.5
                        if stuckTime > 2 then
                            doJump()
                            task.wait(0.2)
                            addDynamicObstacle(hrp.Position)
                            local newWP = computePath(hrp.Position, targetPos)
                            if newWP and #newWP > 1 then
                                -- Restart with new path
                                jumping = false
                                stopSprint()
                                return humanizedWalkTo(targetStone)
                            end
                            stuckTime = 0
                        end
                    else
                        stuckTime = 0
                    end
                    lastPos = hrp.Position
                end

                task.wait(0.1)
                elapsed = elapsed + 0.1
            end
        end
    else
        -- FALLBACK: direct run
        Stats.phase = Stats.phase .. " 🏃"

        local numWP = math.clamp(math.floor(totalDist / 35), 2, 8)
        for i = 1, numWP do
            if not _G.AutoFarmEnabled_v3 or _G.AutoFarmRunID ~= myRunID or not Cfg.FullAuto or _skipCurrentStone then break end

            -- Check if stone got depleted while walking
            local currentAvail = targetStone:GetAttribute("AvailableSlot") or 0
            if currentAvail <= 0 then 
                Stats.phase = "Stone depleted mid-walk! Aborting..."
                break 
            end

            local t = i / numWP
            local base = startPos:Lerp(targetPos, t)

            -- Random: 35% zigzag, 65% straight
            local goal
            if math.random() < 0.35 then
                local amt = math.random(-6, 6)
                goal = Vector3.new(base.X + perpX * amt, hrp.Position.Y, base.Z + perpZ * amt)
            else
                goal = Vector3.new(base.X, hrp.Position.Y, base.Z)
            end

            hum:MoveTo(goal)

            -- Faster check, no stopping
            for _ = 1, 10 do
                if not _G.AutoFarmEnabled_v3 or _G.AutoFarmRunID ~= myRunID then break end
                if (hrp.Position - targetPos).Magnitude <= 14 then 
                    jumping = false; clearTrail(); stopSprint(); return true 
                end
                if (targetStone:GetAttribute("AvailableSlot") or 0) <= 0 then break end
                
                local d = hrp.Position - goal
                if Vector3.new(d.X, 0, d.Z).Magnitude < 6.5 then break end
                
                task.wait(0.1)
            end
        end

        -- Final approach
        hum:MoveTo(Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
        while _G.AutoFarmEnabled_v3 and _G.AutoFarmRunID == myRunID do
            task.wait(0.01)
            if not _G.AutoFarmEnabled_v3 or _G.AutoFarmRunID ~= myRunID then break end
            if (hrp.Position - targetPos).Magnitude < 14 then break end
            task.wait(0.15)
        end
    end

    jumping = false
    clearTrail()
    stopSprint()
    return isNearStone()
end

local function getMiningUI() return PGui:FindFirstChild("MiningUI") end

local function stopTimingWatcher()
    if _G.TimingConn then _G.TimingConn:Disconnect(); _G.TimingConn = nil end
end

local function resetMinigameState()
    stopTimingWatcher()
    local hum = getHum()
    if hum then pcall(function() hum:UnequipTools() end) end

    -- Fallback: If custom hotbar blocks unequip, simulate pressing hotbar keys 1-9
    task.spawn(function()
        task.wait(0.5)
        if getMiningUI() then
            pcall(function()
                for i = 1, 9 do
                    if not getMiningUI() then break end
                    local key = Enum.KeyCode["Number" .. i]
                    VIM:SendKeyEvent(true, key, false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, key, false, game)
                    task.wait(0.1)
                end
            end)
        end
    end)

    local timeout = tick() + 3
    while getMiningUI() and tick() < timeout do task.wait(0.1) end
    task.wait(0.2)
    _G.TestedCurrentStone = false
    _G.PhaseCount = 0
    _G.HitsThisPhase = 0
end

-- ═══════════════════════════════════════════════
-- DRAG PHASE — getconnections
-- ═══════════════════════════════════════════════

local function handleDrag(ui)
    local pre = ui:FindFirstChild("PreMiningHolder")
    if not pre or not pre.Visible then return false end
    local dragBtn = pre:FindFirstChild("DragButton")
    local target = pre:FindFirstChild("TargetFrame")
    if not dragBtn or not target then return false end
    local det = dragBtn:FindFirstChild("UIDragDetector")
    if not det then return false end

    -- Rarity-based reroll check
    if Cfg.AutoReroll and not _G.TestedCurrentStone and not _skipCurrentStone then
        local oreRarity = _G.LatestRarityFromRemote or ui:GetAttribute("Rarity")
        if not oreRarity then 
            -- Give it a quick chance to load in drag phase
            for _ = 1, 5 do
                task.wait(0.1)
                oreRarity = _G.LatestRarityFromRemote or ui:GetAttribute("Rarity")
                if oreRarity then break end
            end
            if not oreRarity then oreRarity = "Common" end
        end

        local oreLevel = RarityOrder[oreRarity] or 1
        -- Rayfield passes array from dropdown, ensure we get string
        local minRarityStr = type(Cfg.MinRarity) == "table" and Cfg.MinRarity[1] or Cfg.MinRarity
        local minLevel = RarityOrder[minRarityStr] or 3

        if oreLevel < minLevel then
            Stats.phase = "Ampas! [" .. oreRarity .. "] Rerolling! 💎"
            blacklistCurrentStone()
            resetMinigameState()
            return "reroll"
        elseif not _G.TestedCurrentStone then
            Stats.phase = "Ore: [" .. oreRarity .. "] 🚀 Mining!"
            _G.TestedCurrentStone = true
        end
    end

    Stats.phase = "Dragging..."
    for attempt = 1, 5 do
        if not pre.Visible or (holder and holder.Visible) then return true end
        if not _G.AutoFarmEnabled_v3 then return false end
        pcall(function()
            dragBtn.Position = target.Position
            RunService.RenderStepped:Wait()
            RunService.RenderStepped:Wait()
            for _, c in pairs(getconnections(det.DragContinue)) do c:Fire() end
        end)
        task.wait(0.35)
    end
    return not pre.Visible
end

-- ═══════════════════════════════════════════════
-- TIMING BAR
-- ═══════════════════════════════════════════════

local function startTimingWatcher()
    if _G.TimingConn then _G.TimingConn:Disconnect() end
    _G.TimingConn = RunService.RenderStepped:Connect(function()
        if not _G.AutoFarmEnabled_v3 or not Cfg.AutoMine then return end
        local ui = getMiningUI()
        if not ui then return end
        local holder = ui:FindFirstChild("MiningHolder")
        if not holder or not holder.Visible then return end
        local mf = holder:FindFirstChild("MiningFrame")
        if not mf then return end
        local bc = mf:FindFirstChild("BarContainer")
        if not bc then return end
        local bar = bc:FindFirstChild("Bar")
        local point = bc:FindFirstChild("Point")
        if not bar or not point then return end

        local barCenter = bar.AbsolutePosition.X + (bar.AbsoluteSize.X / 2)
        local pointCenter = point.AbsolutePosition.X + (point.AbsoluteSize.X / 2)
        
        -- Tolerance is 15% of the yellow bar's width from the exact center
        local tolerance = bar.AbsoluteSize.X * 0.15
        
        if Cfg.AutoReroll and not _G.TestedCurrentStone then return end

        if math.abs(pointCenter - barCenter) <= tolerance then
            if not _G.WaitingForPointToLeave then
                _G.HitsThisPhase = (_G.HitsThisPhase or 0) + 1
                Stats.phase = "HIT! (#" .. _G.HitsThisPhase .. ")"
                _G.WaitingForPointToLeave = true
                
                local cx = bc.AbsolutePosition.X + bc.AbsoluteSize.X / 2
                local cy = bc.AbsolutePosition.Y + bc.AbsoluteSize.Y / 2
                task.spawn(function() pcall(function() vimClick(cx, cy) end) end)
            end
        else
            _G.WaitingForPointToLeave = false
        end
    end)
end

-- ═══════════════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Indo Voice Auto Farm",
    Icon = "pickaxe",
    LoadingTitle = "Indo Voice Hub",
    LoadingSubtitle = "v4.2",
    Theme = "Default",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "IndoVoiceHub",
        FileName = "Config_v42"
    },
    KeySystem = false,
})

local MT = Window:CreateTab("Mining", "pickaxe")
MT:CreateSection("Status")
local StatusP = MT:CreateParagraph({ Title = "Status", Content = "Idle" })

MT:CreateDivider()
MT:CreateSection("Auto Mine")

local AMToggle = MT:CreateToggle({
    Name = "Auto Mine (Stay in Place)",
    CurrentValue = false,
    Flag = "AM",
    Callback = function(v) Cfg.AutoMine = v; Stats.phase = v and "Starting..." or "Idle" end,
})

MT:CreateDivider()
MT:CreateSection("Full Auto Mode 🛹")

local FAToggle = MT:CreateToggle({
    Name = "Full Auto (Board + Sprint + Mine)",
    CurrentValue = false,
    Flag = "FA",
    Callback = function(v)
        Cfg.FullAuto = v
        if v then Cfg.AutoMine = true; AMToggle:Set(true) end
        Stats.phase = v and "Full Auto..." or "Idle"
    end,
})

MT:CreateToggle({
    Name = "Prefer Buddy Stones 👥",
    CurrentValue = true,
    Flag = "PB",
    Callback = function(v) Cfg.PreferBuddy = v end,
})

MT:CreateDivider()
MT:CreateSection("Auto Reroll 💎")

MT:CreateToggle({
    Name = "Auto Reroll (Skip Bad Ores)",
    CurrentValue = false,
    Flag = "RER",
    Callback = function(v) Cfg.AutoReroll = v end,
})

MT:CreateDropdown({
    Name = "Minimum Rarity (Skip Below This)",
    Options = {"Common", "Uncommon", "Rare", "Epic", "Legend", "Mythic", "Ancient"},
    CurrentOption = {"Rare"},
    Flag = "MINRAR",
    Callback = function(v)
        Cfg.MinRarity = v[1] or v
    end
})

MT:CreateToggle({
    Name = "Prefer Hotspot Stones 🔥",
    CurrentValue = true,
    Flag = "PH",
    Callback = function(v) Cfg.PreferHotspot = v end,
})

MT:CreateSlider({
    Name = "Max Stone Distance",
    Range = {50, 500},
    Increment = 25,
    Suffix = "m",
    CurrentValue = 250,
    Flag = "MAXD",
    Callback = function(v) Cfg.MaxDist = v end,
})

MT:CreateDivider()
MT:CreateSection("Zone Mining 📍")

local ZoneStatusP = MT:CreateParagraph({ Title = "Zone Status", Content = "No home set. Stand where you want and press 'Set Home'." })

MT:CreateButton({
    Name = "🏠 Set Home Position (Current Pos)",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            Cfg.ZoneCenter = hrp.Position
            ZoneStatusP:Set({ Title = "Zone Status", Content = "Home set at: " .. math.floor(hrp.Position.X) .. ", " .. math.floor(hrp.Position.Y) .. ", " .. math.floor(hrp.Position.Z) .. "\nRadius: " .. Cfg.ZoneRadius .. "m" })
            Rayfield:Notify({ Title = "Home Set! 🏠", Content = "Zone center saved at your current position.", Duration = 3 })
        end
    end,
})

MT:CreateToggle({
    Name = "Zone Only (Stay in Area)",
    CurrentValue = false,
    Flag = "ZO",
    Callback = function(v)
        Cfg.ZoneOnly = v
        if v and not Cfg.ZoneCenter then
            local hrp = getHRP()
            if hrp then
                Cfg.ZoneCenter = hrp.Position
                ZoneStatusP:Set({ Title = "Zone Status", Content = "Auto-set home at: " .. math.floor(hrp.Position.X) .. ", " .. math.floor(hrp.Position.Y) .. ", " .. math.floor(hrp.Position.Z) .. "\nRadius: " .. Cfg.ZoneRadius .. "m" })
            end
            Rayfield:Notify({ Title = "Zone Auto-Set", Content = "Home auto-set to current pos since none was set.", Duration = 3 })
        end
    end,
})

MT:CreateSlider({
    Name = "Zone Radius",
    Range = {25, 300},
    Increment = 25,
    Suffix = "m",
    CurrentValue = 100,
    Flag = "ZR",
    Callback = function(v)
        Cfg.ZoneRadius = v
        if Cfg.ZoneCenter then
            ZoneStatusP:Set({ Title = "Zone Status", Content = "Home: " .. math.floor(Cfg.ZoneCenter.X) .. ", " .. math.floor(Cfg.ZoneCenter.Y) .. ", " .. math.floor(Cfg.ZoneCenter.Z) .. "\nRadius: " .. v .. "m" })
        end
    end,
})

MT:CreateDivider()
MT:CreateSection("Visuals")

MT:CreateToggle({
    Name = "Stone ESP (Highlight + Info)",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v) Cfg.StoneESP = v; if not v then clearESP() end end,
})

MT:CreateToggle({
    Name = "GPS Trail (Path Dots)",
    CurrentValue = true,
    Flag = "TRAIL",
    Callback = function(v) Cfg.ShowTrail = v; if not v then clearTrail() end end,
})

MT:CreateDivider()
MT:CreateSection("Timing")

MT:CreateSlider({
    Name = "Mine Click Delay",
    Range = {3, 30},
    Increment = 1,
    Suffix = "×100ms",
    CurrentValue = 8,
    Flag = "MD",
    Callback = function(v) Cfg.MineDelay = v / 10 end,
})

MT:CreateSlider({
    Name = "Loop Delay",
    Range = {5, 40},
    Increment = 1,
    Suffix = "×100ms",
    CurrentValue = 10,
    Flag = "LD",
    Callback = function(v) Cfg.LoopDelay = v / 10 end,
})

-- Auto Gacha
local GT = Window:CreateTab("Auto Gacha", "gift")
GT:CreateSection("Blind Box Selection")

local AvailableBoxes = {}
pcall(function()
    local content = require(game:GetService("ReplicatedStorage"):WaitForChild("Content"):WaitForChild("BlindBox"))
    for name, data in pairs(content) do
        if data.Reward then table.insert(AvailableBoxes, name) end
    end
end)
if #AvailableBoxes == 0 then
    AvailableBoxes = {"Dino2026","EidAdha2026","Spring2026","Christmas2025","Halloween2025","Ocean2025","Ramadhan2026","Summer2026","Valentine2026"}
end
table.sort(AvailableBoxes, function(a, b) return a > b end)
Cfg.GachaBox = AvailableBoxes[1]

GT:CreateDropdown({
    Name = "Pilih Blind Box (Auto Update Terbaru)",
    Options = AvailableBoxes,
    CurrentOption = {Cfg.GachaBox},
    Flag = "GBOX",
    Callback = function(v) Cfg.GachaBox = v[1] or v end
})

GT:CreateDropdown({
    Name = "Jumlah Roll",
    Options = {"1x", "10x"},
    CurrentOption = {"10x"},
    Flag = "GMODE",
    Callback = function(v) Cfg.GachaMode = tonumber((v[1] or v):sub(1, -2)) or 10 end
})

GT:CreateDivider()
GT:CreateSection("Auto Settings")

local GachaToggle = GT:CreateToggle({
    Name = "Enable Auto Gacha 🎁",
    CurrentValue = false,
    Flag = "GAUTO",
    Callback = function(v) 
        Cfg.AutoGacha = v
        if v and Cfg.AutoMine then
            Cfg.AutoMine = false
            pcall(function() AMToggle:Set(false) end)
            pcall(function() FAToggle:Set(false) end)
            Rayfield:Notify({Title="Mining Stopped", Content="Auto Mine dimatikan otomatis karena Auto Gacha nyala.", Duration=4})
        end
    end
})

GT:CreateToggle({
    Name = "Auto Klik Box Tengah",
    CurrentValue = true,
    Flag = "GCLICK",
    Callback = function(v) Cfg.GachaAutoClick = v end
})

GT:CreateSlider({
    Name = "Kecepatan Animasi (x)",
    Range = {1, 20},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 8,
    Flag = "GSPEED",
    Callback = function(v) Cfg.GachaSpeed = v end
})

GT:CreateSlider({
    Name = "Delay Antar Roll",
    Range = {5, 50},
    Increment = 5,
    Suffix = "×100ms",
    CurrentValue = 10,
    Flag = "GDELAY",
    Callback = function(v) Cfg.GachaDelay = v / 10 end
})

GT:CreateDivider()
GT:CreateSection("Manual Actions")

GT:CreateButton({
    Name = "🎲 Roll Sekali",
    Callback = function()
        if Cfg.AutoGacha then return Rayfield:Notify({Title="Error", Content="Matikan Auto Gacha dulu!", Duration=3}) end
        task.spawn(function()
            local BlindBoxRollFunction = ReplicatedStorage:WaitForChild("GameRemoteFunctions"):WaitForChild("BlindBoxRollFunction")
            local GachaSequence = require(ReplicatedFirst:WaitForChild("Source"):WaitForChild("BlindBox"):WaitForChild("GachaSequence"))
            
            local ok, result
            if Cfg.GachaMode == 10 then ok, result = pcall(function() return BlindBoxRollFunction:InvokeServer("Pet", Cfg.GachaBox, 10) end)
            else ok, result = pcall(function() return BlindBoxRollFunction:InvokeServer("Pet", Cfg.GachaBox) end) end
            
            if ok and result then
                local elapsed = 0
                while elapsed < 30 do
                    local scene = workspace:FindFirstChild("GachaScene")
                    if not scene or #scene:GetChildren() == 0 then break end
                    pcall(function() GachaSequence:ChangeSpeed(Cfg.GachaSpeed) end)
                    if Cfg.GachaAutoClick then AutoClickGachaBox() end -- also autoclick for manual
                    task.wait(0.2)
                    elapsed = elapsed + 0.2
                end
            end
            pcall(function() GachaSequence:ChangeSpeed(1) end)
        end)
    end
})

GT:CreateButton({
    Name = "⏭️ Force Skip Animasi",
    Callback = function()
        pcall(function() 
            local GachaSequence = require(ReplicatedFirst:WaitForChild("Source"):WaitForChild("BlindBox"):WaitForChild("GachaSequence"))
            GachaSequence:ForceEnd() 
        end)
    end
})

-- Fishing
local FT = Window:CreateTab("Fishing", "fish")
FT:CreateSection("Coming Soon")
FT:CreateParagraph({ Title = "Auto Fish", Content = "Next update!" })

-- Settings
local ST = Window:CreateTab("Settings", "settings")
ST:CreateSection("Actions")
ST:CreateButton({
    Name = "Stop All",
    Callback = function()
        Cfg.AutoMine = false; Cfg.FullAuto = false
        AMToggle:Set(false); FAToggle:Set(false)
        stopSprint()
        Rayfield:Notify({ Title = "Stopped", Content = "All stopped.", Duration = 3, Image = "square" })
    end,
})
ST:CreateButton({
    Name = "Reset Stats",
    Callback = function()
        Stats.mined = 0
        Rayfield:Notify({ Title = "Reset", Content = "Done.", Duration = 2, Image = "refresh-cw" })
    end,
})
ST:CreateDivider()
ST:CreateSection("Info")
ST:CreateParagraph({
    Title = "v4.2",
    Content = "• PathfindingService + stuck detection\n• Sprint (Shift) + continuous zigzag + jumps\n• Auto re-equip board on knockoff\n• 'Fully occupied' → auto skip to next\n• Mining Buddy & Hotspot priority\n• ESP: 🔥Hotspot / 👥Players / slots\n\nPress K to toggle UI."
})

-- ═══════════════════════════════════════════════
-- STATUS
-- ═══════════════════════════════════════════════

local function updateStatus()
    local _, d = getNearestStone()
    local bestStone, bestDist = getBestStone()
    local t = "Phase: " .. Stats.phase
        .. "\nMined: " .. Stats.mined
        .. " | Hits: " .. (_G.HitsThisPhase or 0)
        .. " | PhaseCnt: " .. (_G.PhaseCount or 0)
        .. "\nPick: " .. (isPickEquipped() and "✅" or "❌")
        .. " Board: " .. (isBoardEquipped() and "🛹" or "—")
        .. " Sprint: " .. (_sprinting and "🏃" or "—")
        .. "\nStone: " .. (d < 9999 and (math.floor(d) .. "m") or "None")
        .. " Range: " .. (d <= 14 and "✅" or "❌")
    if bestStone then
        local hs = (bestStone:GetAttribute("IsHotspot") or false) and " 🔥" or ""
        local pn = countPlayersNear(bestStone:GetBoundingBox().Position, 25)
        local av = bestStone:GetAttribute("AvailableSlot") or 0
        t = t .. "\nTarget: " .. bestStone.Name .. hs
            .. (pn > 0 and (" 👥" .. pn) or "")
            .. " [" .. av .. " slots] " .. math.floor(bestDist) .. "m"
    end
    pcall(function() StatusP:Set({ Title = "Status", Content = t }) end)
end

-- ═══════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════

local _testedCurrentStone = false
local _lastMinigame = "None"

local function mainLoop()
    startTimingWatcher()

    while _G.AutoFarmEnabled_v3 and _G.AutoFarmRunID == myRunID do
        updateStatus()

        if not Cfg.AutoMine then
            Stats.phase = "Idle"
            task.wait(0.5)
            continue
        end



        -- Check "fully occupied" → skip
        if _skipCurrentStone then
            Stats.phase = "Stone occupied! Moving to next..."
            _skipCurrentStone = false
            _lastStoneName = "" -- reset after one cycle
            task.wait(0.5)
            -- Continue to find next best stone
        end

        -- Active minigame?
        local ui = getMiningUI()
        if ui then
            local pre = ui:FindFirstChild("PreMiningHolder")
            local holder = ui:FindFirstChild("MiningHolder")
            
            equipPick()

            -- Early rarity check: reroll immediately on first detection
            if Cfg.AutoReroll and not _G.TestedCurrentStone and not _skipCurrentStone then
                local oreRarity = _G.LatestRarityFromRemote or ui:GetAttribute("Rarity")
                if not oreRarity then 
                    -- Wait up to 1 second for the attribute to load from server
                    for _ = 1, 10 do
                        task.wait(0.1)
                        oreRarity = _G.LatestRarityFromRemote or ui:GetAttribute("Rarity")
                        if oreRarity then break end
                    end
                    -- If still nil after 1 second, it's definitely Common (server omitted default value)
                    if not oreRarity then oreRarity = "Common" end
                end
                
                local oreLevel = RarityOrder[oreRarity] or 1
                
                -- Rayfield passes array from dropdown, ensure we get string
                local minRarityStr = type(Cfg.MinRarity) == "table" and Cfg.MinRarity[1] or Cfg.MinRarity
                local minLevel = RarityOrder[minRarityStr] or 3
                
                warn("[RARITY CHECK] Detected Rarity: " .. tostring(oreRarity) .. " (Level " .. tostring(oreLevel) .. "), Target Min: " .. tostring(minRarityStr) .. " (Level " .. tostring(minLevel) .. ")")

                if oreLevel < minLevel then
                    warn("[RARITY CHECK] Skipping! " .. oreLevel .. " < " .. minLevel)
                    Stats.phase = "Ampas! [" .. oreRarity .. "] Rerolling! 💎"
                    blacklistCurrentStone()
                    resetMinigameState()
                    _lastMinigame = "None"
                    continue
                elseif not _G.TestedCurrentStone then
                    warn("[RARITY CHECK] Passed! " .. oreLevel .. " >= " .. minLevel)
                    Stats.phase = "Ore: [" .. oreRarity .. "] 🚀 Mining!"
                    _G.TestedCurrentStone = true
                end
            end
            local currentMinigame = "None"
            if holder and holder.Visible then currentMinigame = "Timing"
            elseif pre and pre.Visible then currentMinigame = "Drag" end
            
            if currentMinigame == "None" and _lastMinigame ~= "None" then
                _G.HitsThisPhase = 0
                _G.PhaseCount = 0
                _G.TestedCurrentStone = false
                _G.LatestRarityFromRemote = nil
            end

            if currentMinigame == "Timing" and _lastMinigame ~= "Timing" then
                _G.PhaseCount = (_G.PhaseCount or 0) + 1
                _G.HitsThisPhase = 0
                _G.WaitingForPointToLeave = false
            elseif currentMinigame == "Timing" and (_G.PhaseCount or 0) == 0 then
                _G.PhaseCount = 1
                _G.HitsThisPhase = 0
                _G.WaitingForPointToLeave = false
            elseif currentMinigame == "Drag" and _lastMinigame == "Timing" then
                _G.HitsThisPhase = 0
            end
            _lastMinigame = currentMinigame

            if currentMinigame == "Drag" then
                local dragResult = handleDrag(ui)
                if dragResult == "reroll" then
                    _lastMinigame = "None"
                    _G.PhaseCount = 0
                    _G.HitsThisPhase = 0
                    continue
                elseif not dragResult then
                    _G.DragStuckCount = (_G.DragStuckCount or 0) + 1
                    if _G.DragStuckCount > 3 then
                        Stats.phase = "UI Stuck! Force Resetting..."
                        unequipPick()
                        ui:Destroy()
                        _G.DragStuckCount = 0
                        task.wait(1)
                    end
                else
                    _G.DragStuckCount = 0
                end
            elseif currentMinigame == "Timing" then
                local mf = holder:FindFirstChild("MiningFrame")
                
                local wPct = 0
                local bc = mf and mf:FindFirstChild("BarContainer")
                local bar = bc and bc:FindFirstChild("Bar")
                if bar then wPct = bar.Size.X.Scale * 100 end

                Stats.phase = "Timing: " .. string.format("%.1f", wPct) .. "%"
            end
            task.wait(0.1)
            continue
        else
            if _lastMinigame ~= "None" then
                _lastMinigame = "None"
                _G.HitsThisPhase = 0
                _G.PhaseCount = 0
                _G.TestedCurrentStone = false
            end
        end

        -- Evaluate targets between ores
        if Cfg.FullAuto then
            local best, bestScore, bestDist = getBestStone()
            if best then
                local currentNearest, currentDist = getNearestStone()
                local isAtValidStone = currentNearest and currentDist <= 14
                local currentScore = currentNearest and scoreStone(currentNearest, getHRP().Position) or -9999
                
                -- Switch if not at any valid stone, OR if the best stone is significantly better (>150 pts difference)
                if not isAtValidStone or (best ~= currentNearest and bestScore > currentScore + 150) then
                    if bestDist > 14 then
                        local cf = best:GetBoundingBox()
                        local hs = (best:GetAttribute("IsHotspot") or false) and "🔥" or ""
                        local pn = countPlayersNear(cf.Position, 25)
                        _lastStoneName = best.Name
                        _G.PhaseCount = 0
                        _G.HitsThisPhase = 0
                        _G.TestedCurrentStone = false
                        _lastMinigame = "None"
                        Stats.phase = "🛹 → " .. best.Name .. hs .. (pn > 0 and (" 👥" .. pn) or "")

                        local hrp = getHRP()
                        if hrp then humanizedWalkTo(best) end

                        if not isNearStone() then
                            Stats.phase = "Retrying..."
                            task.wait(0.5)
                        end
                        continue
                    end
                end
            else
                Stats.phase = "All stones depleted, waiting..."
                _lastStoneName = ""
                _skipCurrentStone = false
                task.wait(1.5)
                continue
            end
        else
            if not isNearStone() then
                Stats.phase = "Get closer!"
                task.wait(1)
                continue
            end
        end

        -- Safety check: absolutely do not mine if we aren't near a valid stone
        if not isNearStone() then
            task.wait(0.5)
            continue
        end

        -- Near stone — mine
        Stats.phase = "⛏ Mining..."
        equipPick()
        task.wait(0.3)

        local cam = workspace.CurrentCamera
        if cam then
            pcall(function() vimClick(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) end)
        end

        task.wait(Cfg.MineDelay)

        -- Handle minigame + check occupied
        local timeout = 0
        while _G.AutoFarmEnabled_v3 and Cfg.AutoMine and timeout < 60 do
            -- Check fully occupied during mining
            if _skipCurrentStone then
                Stats.phase = "Occupied! Leaving..."
                break
            end

            ui = getMiningUI()
            if not ui then
                if timeout > 1.5 then Stats.mined = Stats.mined + 1 end
                break
            end
            local pre = ui:FindFirstChild("PreMiningHolder")
            if pre and pre.Visible then handleDrag(ui) end
            task.wait(0.1)
            timeout = timeout + 0.1
        end

        if Cfg.FullAuto and (not isNearStone() or _skipCurrentStone) then
            Stats.phase = "Finding next stone..."
            _skipCurrentStone = false
            task.wait(0.3)
            continue
        end

        task.wait(Cfg.LoopDelay)
    end

    stopTimingWatcher()
    stopSprint()
    clearESP()
    clearTrail()
    Stats.phase = "Stopped"
    updateStatus()
end

-- ═══════════════════════════════════════════════
-- GACHA LOOP
-- ═══════════════════════════════════════════════

local function AutoClickGachaBox()
    local scene = workspace:FindFirstChild("GachaScene")
    if not scene then return false end
    for _, child in ipairs(scene:GetChildren()) do
        if child:IsA("Model") then
            local packs = child:FindFirstChild("Packs")
            if packs then
                local middleBox = packs:FindFirstChild("5") or packs:FindFirstChild("2")
                if not middleBox then
                    for _, b in ipairs(packs:GetChildren()) do
                        if b:IsA("Model") and b.PrimaryPart then middleBox = b; break end
                    end
                end
                if middleBox and middleBox.PrimaryPart then
                    local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(middleBox.PrimaryPart.Position)
                    if onScreen then
                        pcall(function()
                            VIM:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 1)
                            task.wait(0.05)
                            VIM:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 1)
                        end)
                        return true
                    end
                end
            end
        end
    end
    return false
end

task.spawn(function()
    local BlindBoxRollFunction = nil
    local GachaSequence = nil
    
    while _G.AutoFarmEnabled_v3 and _G.AutoFarmRunID == myRunID do
        if Cfg.AutoGacha then
            if not BlindBoxRollFunction then
                pcall(function() BlindBoxRollFunction = ReplicatedStorage:WaitForChild("GameRemoteFunctions"):WaitForChild("BlindBoxRollFunction", 3) end)
            end
            if not GachaSequence then
                pcall(function() GachaSequence = require(ReplicatedFirst:WaitForChild("Source"):WaitForChild("BlindBox"):WaitForChild("GachaSequence")) end)
            end
            
            if BlindBoxRollFunction and GachaSequence then
                pcall(function() GachaSequence:ChangeSpeed(Cfg.GachaSpeed) end)
                
                local ok, result, extra = pcall(function()
                    if Cfg.GachaMode == 10 then
                        return BlindBoxRollFunction:InvokeServer("Pet", Cfg.GachaBox, 10)
                    else
                        return BlindBoxRollFunction:InvokeServer("Pet", Cfg.GachaBox)
                    end
                end)
                
                if ok and result then
                    -- Wait for animation
                    local elapsed = 0
                    while elapsed < 30 and Cfg.AutoGacha and _G.AutoFarmEnabled_v3 do
                        local scene = workspace:FindFirstChild("GachaScene")
                        if not scene or #scene:GetChildren() == 0 then break end
                        pcall(function() GachaSequence:ChangeSpeed(Cfg.GachaSpeed) end)
                        if Cfg.GachaAutoClick then AutoClickGachaBox() end
                        task.wait(0.2)
                        elapsed = elapsed + 0.2
                    end
                else
                    local msg = (typeof(extra) == "string" and extra) or "Gagal"
                    local lo = msg:lower()
                    if lo:find("enough") or lo:find("money") or lo:find("ropiah") or lo:find("cukup") or lo:find("insufficient") or lo:find("afford") then
                        Cfg.AutoGacha = false
                        pcall(function() GachaToggle:Set(false) end)
                        Rayfield:Notify({ Title = "Gacha Stopped", Content = "RP habis! Auto Gacha dimatikan otomatis.", Duration = 5 })
                    end
                end
                
                if Cfg.AutoGacha then task.wait(Cfg.GachaDelay) end
            else
                task.wait(1)
            end
        else
            -- if not autogacha, make sure speed is normal
            if GachaSequence then pcall(function() GachaSequence:ChangeSpeed(1) end) end
            task.wait(1)
        end
    end
end)

-- ═══ Background ═══
task.spawn(function()
    while _G.AutoFarmEnabled_v3 do
        updateStatus()
        pcall(updateESP)
        task.wait(2)
    end
    clearESP()
end)

task.spawn(mainLoop)

Rayfield:Notify({
    Title = "Indo Voice Hub v4.2",
    Content = "Sprint + Pathfinding + Board re-equip!\nFully occupied → auto skip. 🛹⛏",
    Duration = 5,
    Image = "check-circle",
})

Rayfield:LoadConfiguration()
