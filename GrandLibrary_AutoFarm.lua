local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Player = Players.LocalPlayer

-- ==============================================================================
-- 1. FETCH REPLICA (DATA CONTROLLER)
-- ==============================================================================
local Replica
for _, v in pairs(getgc(true)) do
    if type(v) == "table" and rawget(v, "Data") and rawget(v, "Class") == "Library" then
        Replica = v
        break
    end
end

if not Replica then
    warn("[Auto-Farm] Replica not found! Game data cannot be accessed.")
    return
end

-- ==============================================================================
-- 2. SMART CATEGORY & BOOK INFO PARSER
-- ==============================================================================
local Loader
local EnumMod
pcall(function()
    Loader = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Loader"))
    EnumMod = require(Loader.Shared.Utility.Enum)
end)

local function getBookInfo(bookName)
    local title, volStr = bookName:match("^(.-)_(.+)$")
    local vol = tonumber(volStr)
    if title and EnumMod then
        local titleNoSpace = string.gsub(title, "%s+", "")
        for cat, books in pairs(EnumMod.Genres) do
            if type(books) == "table" and books[titleNoSpace] then
                return {
                    category = cat,
                    series = titleNoSpace,
                    volume = vol,
                    volumeCount = books[titleNoSpace].VolumeCount or 10
                }
            end
        end
    end
    local split = string.split(bookName, "_")
    local fbTitle = split[1] or bookName
    return {
        category = fbTitle,
        series = string.gsub(fbTitle, "%s+", ""),
        volume = vol or 1,
        volumeCount = 10
    }
end

-- ==============================================================================
-- 3. GUI SETUP
-- ==============================================================================
if CoreGui:FindFirstChild("GrandLibraryFarm") then CoreGui.GrandLibraryFarm:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GrandLibraryFarm"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 300)
MainFrame.Position = UDim2.new(0, 25, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(60, 60, 70)
UIStroke.Thickness = 1.5

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "   GRAND LIBRARY FARM V5"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 22
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local TargetText = Instance.new("TextLabel", MainFrame)
TargetText.Size = UDim2.new(1, 0, 0, 20)
TargetText.Position = UDim2.new(0, 0, 0, 35)
TargetText.BackgroundTransparency = 1
TargetText.Text = "🎯 Target: None"
TargetText.TextColor3 = Color3.fromRGB(255, 255, 100)
TargetText.Font = Enum.Font.GothamSemibold
TargetText.TextSize = 11

local Toggles = {GrabAura = false, GrabWalk = false, PlaceAura = false, PlaceWalk = false, SpeedBoost = false, BookESP = true, Freecam = false}
local freecamConn = nil
local camPos = Vector3.new()
local camRot = Vector2.new()
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local function toggleFreecam(enabled)
    local cam = workspace.CurrentCamera
    if enabled then
        camPos = cam.CFrame.Position
        local lv = cam.CFrame.LookVector
        camRot = Vector2.new(math.asin(lv.Y), math.atan2(-lv.X, -lv.Z))
        cam.CameraType = Enum.CameraType.Scriptable
        
        if not freecamConn then
            freecamConn = RS.RenderStepped:Connect(function(dt)
                local move = Vector3.new()
                if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, -1) end
                if UIS:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, 1) end
                if UIS:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0, 1, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.Q) then move = move + Vector3.new(0, -1, 0) end
                
                if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                    UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
                    local delta = UIS:GetMouseDelta()
                    camRot = camRot + Vector2.new(-delta.Y, -delta.X) * 0.005
                    camRot = Vector2.new(math.clamp(camRot.X, -math.rad(89), math.rad(89)), camRot.Y)
                else
                    UIS.MouseBehavior = Enum.MouseBehavior.Default
                end
                
                local cf = CFrame.new(camPos) * CFrame.Angles(0, camRot.Y, 0) * CFrame.Angles(camRot.X, 0, 0)
                if move.Magnitude > 0 then
                    camPos = camPos + (cf:VectorToWorldSpace(move.Unit) * 50 * dt)
                end
                cam.CFrame = CFrame.new(camPos) * CFrame.Angles(0, camRot.Y, 0) * CFrame.Angles(camRot.X, 0, 0)
            end)
        end
    else
        if freecamConn then freecamConn:Disconnect() freecamConn = nil end
        cam.CameraType = Enum.CameraType.Custom
        UIS.MouseBehavior = Enum.MouseBehavior.Default
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            cam.CameraSubject = Player.Character.Humanoid
        end
    end
end

local function createToggle(name, text, yPos)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(1, -30, 0, 25)
    btn.Position = UDim2.new(0, 15, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = text .. (Toggles[name] and " : ON" or " : OFF")
    btn.TextColor3 = Toggles[name] and Color3.fromRGB(50, 255, 120) or Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local str = Instance.new("UIStroke", btn)
    str.Name = "UIStroke"
    str.Color = Toggles[name] and Color3.fromRGB(50, 255, 120) or Color3.fromRGB(50, 50, 60)
    
    btn.MouseButton1Click:Connect(function()
        Toggles[name] = not Toggles[name]
        if name == "GrabAura" and Toggles.GrabAura then Toggles.GrabWalk = false end
        if name == "GrabWalk" and Toggles.GrabWalk then Toggles.GrabAura = false end
        if name == "PlaceAura" and Toggles.PlaceAura then Toggles.PlaceWalk = false end
        if name == "PlaceWalk" and Toggles.PlaceWalk then Toggles.PlaceAura = false end

        -- Fast UI update
        for _, child in pairs(MainFrame:GetChildren()) do
            if child:IsA("TextButton") and child:FindFirstChild("UIStroke") then
                local btnName = string.match(child.Text, "(.*) :")
                local key
                if btnName == "Global Grab (No Range)" then key = "GrabAura"
                elseif btnName == "Smart Grab (Walk)" then key = "GrabWalk"
                elseif btnName == "Global Place (No Range)" then key = "PlaceAura"
                elseif btnName == "Place (Walk)" then key = "PlaceWalk"
                elseif btnName == "Book ESP (Floor)" then key = "BookESP"
                elseif btnName == "Speed Boost (Fast Walk)" then key = "SpeedBoost"
                elseif btnName == "Freecam (Watch Mode)" then key = "Freecam" end
                
                if key then
                    if Toggles[key] then
                        child.Text = btnName .. " : ON"
                        child.TextColor3 = Color3.fromRGB(50, 255, 120)
                        child.UIStroke.Color = Color3.fromRGB(50, 255, 120)
                    else
                        child.Text = btnName .. " : OFF"
                        child.TextColor3 = Color3.fromRGB(150, 150, 150)
                        child.UIStroke.Color = Color3.fromRGB(50, 50, 60)
                    end
                end
            end
        end
        
        -- Apply Logic
        if name == "SpeedBoost" then
            if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                Player.Character.Humanoid.WalkSpeed = Toggles.SpeedBoost and 28 or 16
            end
        elseif name == "Freecam" then
            toggleFreecam(Toggles.Freecam)
        end
    end)
end

createToggle("GrabAura", "Global Grab (No Range)", 60)
createToggle("GrabWalk", "Smart Grab (Walk)", 90)
createToggle("PlaceAura", "Global Place (No Range)", 120)
createToggle("PlaceWalk", "Place (Walk)", 150)
createToggle("BookESP", "Book ESP (Floor)", 180)
createToggle("SpeedBoost", "Speed Boost (Fast Walk)", 210)
createToggle("Freecam", "Freecam (Watch Mode)", 240)

local DropBtn = Instance.new("TextButton", MainFrame)
DropBtn.Size = UDim2.new(1, -30, 0, 20)
DropBtn.Position = UDim2.new(0, 15, 0, 270)
DropBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
DropBtn.Text = "DROP ALL BOOKS (Fix Mix)"
DropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DropBtn.Font = Enum.Font.GothamBold
DropBtn.TextSize = 10
Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 5)
DropBtn.MouseButton1Click:Connect(function()
    Replica:FireServer("Drop")
end)

local Info = Instance.new("TextLabel", MainFrame)
Info.Size = UDim2.new(1, 0, 0, 20)
Info.Position = UDim2.new(0, 0, 1, -20)
Info.BackgroundTransparency = 1
Info.Text = "Status: Idle..."
Info.TextColor3 = Color3.fromRGB(0, 200, 255)
Info.Font = Enum.Font.Gotham
Info.TextSize = 10

-- ==============================================================================
-- 4. ESP / MARKER LOGIC
-- ==============================================================================
local ESPFolder = workspace:FindFirstChild("GrandLibraryESP") or Instance.new("Folder")
ESPFolder.Name = "GrandLibraryESP"
ESPFolder.Parent = workspace

local hl = ESPFolder:FindFirstChild("HL") or Instance.new("Highlight")
hl.Name = "HL"
hl.FillColor = Color3.fromRGB(50, 255, 100)
hl.OutlineColor = Color3.fromRGB(255, 255, 255)
hl.FillTransparency = 0.5
hl.Enabled = false
hl.Parent = ESPFolder

local a0 = ESPFolder:FindFirstChild("A0") or Instance.new("Attachment")
a0.Name = "A0"
local a1 = ESPFolder:FindFirstChild("A1") or Instance.new("Attachment")
a1.Name = "A1"

local beam = ESPFolder:FindFirstChild("Beam") or Instance.new("Beam")
beam.Name = "Beam"
beam.Color = ColorSequence.new(Color3.fromRGB(50, 255, 100))
beam.FaceCamera = true
beam.Width0 = 0.5
beam.Width1 = 0.5
beam.Enabled = false
beam.Parent = ESPFolder

local bg = ESPFolder:FindFirstChild("BG") or Instance.new("BillboardGui")
bg.Name = "BG"
bg.Size = UDim2.new(0, 150, 0, 50)
bg.StudsOffset = Vector3.new(0, 5, 0)
bg.AlwaysOnTop = true
bg.Enabled = false
bg.Parent = ESPFolder

local txt = bg:FindFirstChild("Txt") or Instance.new("TextLabel")
txt.Name = "Txt"
txt.Size = UDim2.new(1, 0, 1, 0)
txt.BackgroundTransparency = 1
txt.TextColor3 = Color3.fromRGB(50, 255, 100)
txt.TextStrokeTransparency = 0
txt.Font = Enum.Font.GothamBold
txt.TextSize = 14
txt.Parent = bg

local blinkDummy = workspace:FindFirstChild("BlinkDummy")
if not blinkDummy then
    blinkDummy = Instance.new("Part")
    blinkDummy.Name = "BlinkDummy"
    blinkDummy.Anchored = true
    blinkDummy.CanCollide = false
    blinkDummy.Transparency = 1
    blinkDummy.Size = Vector3.new(1, 1, 1)
    blinkDummy.Parent = workspace
end

local function blinkAction(targetInstance, actionName, arg1, arg2)
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return false end

    local targetPos = (targetInstance:IsA("Model") and targetInstance.PrimaryPart and targetInstance.PrimaryPart.Position) or (targetInstance:IsA("BasePart") and targetInstance.Position) or nil
    if not targetPos then return false end

    local dist = (root.Position - targetPos).Magnitude
    if dist < 15 then
        Replica:FireServer(actionName, arg1, arg2)
        task.wait(0.2)
        return true
    end

    local originalCF = root.CFrame
    local cam = workspace.CurrentCamera
    
    -- Set dummy to current position and change camera subject
    blinkDummy.CFrame = originalCF
    local oldSubject = cam.CameraSubject
    cam.CameraSubject = blinkDummy
    
    root.Velocity = Vector3.new(0, 0, 0)
    root.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
    task.wait(0.1)
    
    Replica:FireServer(actionName, arg1, arg2)
    task.wait(0.2)
    
    root.CFrame = originalCF
    task.wait(0.05)
    
    cam.CameraSubject = humanoid
    return true
end

local function updateShelfESP(targetPart, categoryName)
    if not targetPart or not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
        hl.Enabled = false
        bg.Enabled = false
        beam.Enabled = false
        return
    end
    
    local root = Player.Character.HumanoidRootPart
    a0.Parent = root
    a1.Parent = targetPart
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Enabled = true

    hl.Adornee = targetPart.Parent
    hl.Enabled = true
    bg.Adornee = targetPart
    txt.Text = "TARGET: " .. categoryName
    bg.Enabled = true
end

-- ==============================================================================
-- 5. MAIN LOGIC & CACHING
-- ==============================================================================
local ShelfCache = {}
for shelfId, shelfData in pairs(Replica.Data.Shelves) do
    local shelfModel = workspace.Library:FindFirstChild(shelfId, true)
    if shelfModel then
        local primary = shelfModel.PrimaryPart or shelfModel:FindFirstChild("Base")
        if primary then
            ShelfCache[shelfId] = {
                model = shelfModel,
                part = primary,
                y = primary.Position.Y
            }
        end
    end
end

local function getDistance(part1, part2)
    if not part1 or not part2 then return math.huge end
    return (part1.Position - part2.Position).Magnitude
end

local isWalking = false
local function walkTo(cframe)
    if isWalking then return end
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        isWalking = true
        local dist = (char.HumanoidRootPart.Position - cframe.Position).Magnitude
        local speed = 28
        local time = dist / speed
        char.HumanoidRootPart.CFrame = CFrame.lookAt(char.HumanoidRootPart.Position, Vector3.new(cframe.Position.X, char.HumanoidRootPart.Position.Y, cframe.Position.Z))
        local tween = TweenService:Create(char.HumanoidRootPart, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = cframe})
        tween:Play()
        tween.Completed:Wait()
        isWalking = false
    end
end

local function isShelfClean(shelfData, targetSeries)
    for k, v in pairs(shelfData.Books) do
        local vTitle = v.Name:match("^(.-)_")
        if vTitle then
            local vTitleNoSpace = string.gsub(vTitle, "%s+", "")
            if vTitleNoSpace ~= targetSeries then
                return false
            end
        end
    end
    return true
end

local function countBooks(shelfData)
    local c = 0
    for k,v in pairs(shelfData.Books) do c = c + 1 end
    return c
end

local function isShelfClean(shelfData, seriesName)
    for k,v in pairs(shelfData.Books) do
        local success, bName = pcall(function() return typeof(v) == "Instance" and v.Name or tostring(v) end)
        if success and not bName:match(seriesName) then return false end
    end
    return true
end

local function getFirstEmptySlot(shelfData)
    for i = 0, shelfData.Width - 1 do
        if not shelfData.Books[tostring(i + 1)] and not shelfData.Books[i + 1] then
            return i
        end
    end
    return nil
end

local CurrentTargetSeries = nil
local CurrentTargetCategory = nil

local function updateTargetLogic(equipped, PlacedBooks, BlacklistedBooks)
    -- If holding books, WE MUST target the book in our hands
    if #equipped > 0 then
        local info = getBookInfo(equipped[1].Name)
        CurrentTargetSeries = info.series
        CurrentTargetCategory = info.category
        return
    end

    -- 1. Count books on floor
    local floorCounts = {}
    local booksFolder = workspace.Library:FindFirstChild("Books")
    if booksFolder then
        for _, book in ipairs(booksFolder:GetChildren()) do
            local isLocked = false
            pcall(function() isLocked = book:GetAttribute("Locked") == true end)
            if PlacedBooks[book] or (BlacklistedBooks and BlacklistedBooks[book]) or isLocked then continue end -- SKIP PLACED/BUGGED BOOKS!
            local success, bName = pcall(function() return book.Name end)
            if not success then continue end
            local info = getBookInfo(bName)
            if info then
                floorCounts[info.series] = (floorCounts[info.series] or 0) + 1
            end
        end
    end

    -- 2. Find lowest shelf that has books available on floor
    local lowestY = math.huge
    local bestSeries = nil
    local bestCat = nil

    for shelfId, shelfData in pairs(Replica.Data.Shelves) do
        local cache = ShelfCache[shelfId]
        if not cache then continue end
        
        local currentBookCount = countBooks(shelfData)
        if currentBookCount < shelfData.Width then
            local claimedSeries = nil
            local isClean = true
            if currentBookCount > 0 then
                for k, v in pairs(shelfData.Books) do
                    local vTitle = v.Name:match("^(.-)_")
                    if vTitle then
                        local vTitleNoSpace = string.gsub(vTitle, "%s+", "")
                        if not claimedSeries then
                            claimedSeries = vTitleNoSpace
                        elseif claimedSeries ~= vTitleNoSpace then
                            isClean = false
                            break
                        end
                    end
                end
            end
            
            if isClean then
                if claimedSeries then
                    if (floorCounts[claimedSeries] or 0) > 0 and cache.y < lowestY then
                        lowestY = cache.y
                        bestSeries = claimedSeries
                        bestCat = shelfData.Category
                    end
                else
                    if EnumMod and EnumMod.Genres[shelfData.Category] then
                        for sName, sData in pairs(EnumMod.Genres[shelfData.Category]) do
                            if type(sData) == "table" and (sData.VolumeCount or 10) == shelfData.Width then
                                if (floorCounts[sName] or 0) > 0 and cache.y < lowestY then
                                    lowestY = cache.y
                                    bestSeries = sName
                                    bestCat = shelfData.Category
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if bestSeries then
        CurrentTargetSeries = bestSeries
        CurrentTargetCategory = bestCat
    else
        CurrentTargetSeries = nil
        CurrentTargetCategory = nil
    end
end

local function updateBookESP(PlacedBooks, BlacklistedBooks)
    local booksFolder = workspace.Library:FindFirstChild("Books")
    if not booksFolder then return end
    
    for _, book in ipairs(booksFolder:GetChildren()) do
        local isLocked = false
        pcall(function() isLocked = book:GetAttribute("Locked") == true end)
        if PlacedBooks[book] or (BlacklistedBooks and BlacklistedBooks[book]) or isLocked then
            pcall(function()
                if book:FindFirstChild("FarmESP") then book.FarmESP:Destroy() end
                if book:FindFirstChild("FarmBG") then book.FarmBG:Destroy() end
            end)
            continue
        end
        
        local success, bName = pcall(function() return book.Name end)
        if not success then continue end
        local info = getBookInfo(bName)
        
        if Toggles.BookESP and CurrentTargetSeries and info.series == CurrentTargetSeries then
            if not book:FindFirstChild("FarmESP") then
                local bhl = Instance.new("Highlight")
                bhl.Name = "FarmESP"
                bhl.FillColor = Color3.fromRGB(0, 255, 255)
                bhl.OutlineColor = Color3.fromRGB(255, 255, 255)
                bhl.FillTransparency = 0.5
                bhl.Parent = book
                
                local bbg = Instance.new("BillboardGui")
                bbg.Name = "FarmBG"
                bbg.Size = UDim2.new(0, 100, 0, 30)
                bbg.StudsOffset = Vector3.new(0, 2, 0)
                bbg.AlwaysOnTop = true
                
                local btxt = Instance.new("TextLabel")
                btxt.Size = UDim2.new(1, 0, 1, 0)
                btxt.BackgroundTransparency = 1
                btxt.Text = info.series .. " " .. info.volume
                btxt.TextColor3 = Color3.fromRGB(0, 255, 255)
                btxt.TextStrokeTransparency = 0
                btxt.Font = Enum.Font.GothamBold
                btxt.TextSize = 10
                btxt.Parent = bbg
                bbg.Parent = book
            end
        else
            if book:FindFirstChild("FarmESP") then book.FarmESP:Destroy() end
            if book:FindFirstChild("FarmBG") then book.FarmBG:Destroy() end
        end
    end
end

task.spawn(function()
    while MainFrame.Parent do
        task.wait(0.05)
        
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not root then continue end
        
        if Toggles.SpeedBoost and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 28
        end
        
        local pData = Replica and Replica.Data.Players[Player.Name]
        if not pData then continue end
        
        local equipped = pData.Equipped or {}
        local maxCarry = pData.MaxCarryAmount or 1
        
        local PlacedBooks = {}
        for shelfId, shelfData in pairs(Replica.Data.Shelves) do
            for slot, bookInst in pairs(shelfData.Books) do
                if typeof(bookInst) == "Instance" then
                    PlacedBooks[bookInst] = true
                end
            end
        end
        
        updateTargetLogic(equipped, PlacedBooks, BlacklistedBooks)
        updateBookESP(PlacedBooks, BlacklistedBooks)
        
        if CurrentTargetSeries then
            TargetText.Text = "🎯 Fokus: " .. CurrentTargetSeries
        else
            TargetText.Text = "🎯 Fokus: Tidak ada target"
        end
        
        local didAction = false
        local espTargetShelf = nil
        local displayCategory = nil

        -- [A] AUTO PLACE LOGIC
        if #equipped > 0 then
            local currentBook = equipped[#equipped]
            local info = getBookInfo(currentBook.Name)
            displayCategory = info.category
            
            local targetShelfId = nil
            local targetSlot = info.volume - 1
            
            for shelfId, shelfData in pairs(Replica.Data.Shelves) do
                if shelfData.Completed ~= true and shelfData.Category == info.category and shelfData.Width == (info and info.volumeCount or 10) then
                    if countBooks(shelfData) > 0 and isShelfClean(shelfData, info.series) then
                        if not shelfData.Books[tostring(info.volume)] and not shelfData.Books[info.volume] then
                            targetShelfId = shelfId
                            break
                        end
                    end
                end
            end
            
            if not targetShelfId then
                for shelfId, shelfData in pairs(Replica.Data.Shelves) do
                    if shelfData.Completed ~= true and shelfData.Category == info.category and shelfData.Width == (info and info.volumeCount or 10) then
                        if countBooks(shelfData) == 0 then
                            targetShelfId = shelfId
                            targetSlot = info.volume - 1
                            break
                        end
                    end
                end
            end
            
            if targetShelfId then
                local cache = ShelfCache[targetShelfId]
                if cache and cache.model and cache.part then
                    espTargetShelf = cache.part
                    -- Shelf ESP is now strictly handled by the Auto Place logic to prevent mismatch.
                    if Toggles.PlaceAura or Toggles.PlaceWalk then
                        local dist = getDistance(root, cache.part)
                        if Toggles.PlaceAura then -- Infinite range
                            Info.Text = "Status: Global Placing " .. currentBook.Name .. "..."
                            blinkAction(cache.part, "Place", cache.model, targetSlot)
                            didAction = true
                        elseif Toggles.PlaceWalk and not isWalking then
                            Info.Text = "Status: Walking to place " .. currentBook.Name .. "..."
                            local targetCF = cache.part.CFrame * CFrame.new(0, 0, 4)
                            walkTo(targetCF)
                            blinkAction(cache.part, "Place", cache.model, targetSlot)
                            didAction = true
                        end
                    end
                end
            else
                -- FAILSAFE: If no shelf can accept this book (e.g. shelves full), drop it so we don't get permanently stuck
                Replica:FireServer("Drop")
                pcall(function() BlacklistedBooks[currentBook] = true end)
                didAction = true
                task.wait(0.2)
            end
        end

        updateShelfESP(espTargetShelf, displayCategory)

        -- [B] AUTO GRAB LOGIC
        if not didAction and not isWalking then
            if (Toggles.GrabAura or Toggles.GrabWalk) and #equipped < maxCarry and CurrentTargetSeries then
                local booksFolder = workspace.Library:FindFirstChild("Books")
                if booksFolder then
                    local nearestBook = nil
                    local minDist = math.huge

                    for _, book in ipairs(booksFolder:GetChildren()) do
                        local isLocked = false
                        pcall(function() isLocked = book:GetAttribute("Locked") == true end)
                        
                        if PlacedBooks[book] or (BlacklistedBooks and BlacklistedBooks[book]) or isLocked then continue end
                        local success, bName = pcall(function() return book.Name end)
                        if not success then continue end
                        local info = getBookInfo(bName)
                        if info and info.series == CurrentTargetSeries then
                            local primary = book:IsA("Model") and book.PrimaryPart or book
                            if root and primary then
                                local dist = getDistance(root, primary)
                                if dist < minDist then
                                    minDist = dist
                                    nearestBook = book
                                end
                            end
                        end
                    end

                    if nearestBook then
                        local primary = nearestBook:IsA("Model") and nearestBook.PrimaryPart or nearestBook
                        if Toggles.GrabAura then -- Infinite range
                            Info.Text = "Status: Global Grabbing..."
                            local success = blinkAction(primary, "Grab", nearestBook)
                            if success then
                                pcall(function()
                                    GrabAttempts[nearestBook] = (GrabAttempts[nearestBook] or 0) + 1
                                    if GrabAttempts[nearestBook] >= 3 then
                                        BlacklistedBooks[nearestBook] = true
                                        if nearestBook:FindFirstChild("FarmESP") then nearestBook.FarmESP:Destroy() end
                                        if nearestBook:FindFirstChild("FarmBG") then nearestBook.FarmBG:Destroy() end
                                    end
                                end)
                            end
                            didAction = true
                        elseif Toggles.GrabWalk and not isWalking then
                            Info.Text = "Status: Walking to grab book..."
                            walkTo(primary.CFrame)
                            local success = blinkAction(primary, "Grab", nearestBook)
                            if success then
                                pcall(function()
                                    GrabAttempts[nearestBook] = (GrabAttempts[nearestBook] or 0) + 1
                                    if GrabAttempts[nearestBook] >= 3 then
                                        BlacklistedBooks[nearestBook] = true
                                    end
                                end)
                            end
                            didAction = true
                            task.wait(0.3)
                        end
                    end
                end
            end
        end
        
        if not isWalking and not didAction then
            Info.Text = string.format("Status: Idle (%d/%d Books)", #equipped, maxCarry)
        end
    end
end)

print("[SYSTEM] Grand Library Auto-Farm V5 Loaded!")
