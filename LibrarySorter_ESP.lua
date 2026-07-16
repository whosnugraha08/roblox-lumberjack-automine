local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BookNetworkEvent = ReplicatedStorage:WaitForChild("BookNetworkEvent")

_G.LibraryStopAll = false

-- Cleanup existing GUI
if _G.LibraryESPGUI then
    _G.LibraryESPGUI:Destroy()
end
if _G.LibraryKeybinds then
    _G.LibraryKeybinds:Disconnect()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LibrarySorterESP"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")
_G.LibraryESPGUI = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 500)
MainFrame.Position = UDim2.new(0, 20, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(200, 150, 50)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "📚 Bot Sorter & ESP"
Title.TextColor3 = Color3.fromRGB(255, 200, 50)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

-- Buttons Container
local TopButtons = Instance.new("Frame")
TopButtons.Size = UDim2.new(1, 0, 0, 80)
TopButtons.Position = UDim2.new(0, 0, 0, 40)
TopButtons.BackgroundTransparency = 1
TopButtons.Parent = MainFrame

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0.3, 0, 0, 35)
StopBtn.Position = UDim2.new(0.025, 0, 0, 0)
StopBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
StopBtn.Text = "🛑 STOP [C]"
StopBtn.TextColor3 = Color3.new(1, 1, 1)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 13
StopBtn.Parent = TopButtons

local MagnetBtn = Instance.new("TextButton")
MagnetBtn.Size = UDim2.new(0.3, 0, 0, 35)
MagnetBtn.Position = UDim2.new(0.35, 0, 0, 0)
MagnetBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
MagnetBtn.Text = "🤖 Loot [Z]"
MagnetBtn.TextColor3 = Color3.new(1, 1, 1)
MagnetBtn.Font = Enum.Font.GothamBold
MagnetBtn.TextSize = 13
MagnetBtn.Parent = TopButtons

local SortBtn = Instance.new("TextButton")
SortBtn.Size = UDim2.new(0.3, 0, 0, 35)
SortBtn.Position = UDim2.new(0.675, 0, 0, 0)
SortBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
SortBtn.Text = "🤖 Sort [X]"
SortBtn.TextColor3 = Color3.new(1, 1, 1)
SortBtn.Font = Enum.Font.GothamBold
SortBtn.TextSize = 13
SortBtn.Parent = TopButtons

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
StatusLabel.Position = UDim2.new(0.05, 0, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Pilih kategori di bawah dulu!"
StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextSize = 12
StatusLabel.Parent = TopButtons

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(0.9, 0, 1, -130)
ScrollingFrame.Position = UDim2.new(0.05, 0, 0, 120)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 8
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.Name
UIListLayout.Parent = ScrollingFrame

local currentTargetCategory = nil
local isProcessing = false

local function togglePopup(state)
    local popupScript = LocalPlayer.PlayerScripts:FindFirstChild("PopupController")
    if popupScript and popupScript:IsA("LocalScript") then
        popupScript.Disabled = not state
    end
end

-- Force hide any existing popups to stop the noise immediately
local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
if hud then
    for _, child in ipairs(hud:GetDescendants()) do
        if child:IsA("TextLabel") and (child.Text:match("Move closer") or child.Text:match("cooldown")) then
            child.Visible = false
            child:Destroy()
        end
    end
end

local function executeStop()
    _G.LibraryStopAll = true
    isProcessing = false
    currentTargetCategory = nil
    StatusLabel.Text = "Pilih kategori di bawah dulu!"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    togglePopup(true)
    
    local spawned = workspace:FindFirstChild("SpawnedBooks")
    if spawned then
        for _, book in ipairs(spawned:GetChildren()) do
            if book:IsA("Part") then
                local hl = book:FindFirstChild("BookHighlight")
                if hl then hl:Destroy() end
            end
        end
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name == "Shelf" or obj.Name:lower():match("bookcase")) then
            local hl = obj:FindFirstChild("BookHighlight")
            if hl then hl:Destroy() end
        end
    end
end

local function executeMagnet()
    if isProcessing then return end
    if not currentTargetCategory then
        StatusLabel.Text = "⚠ Klik ESP kategori dulu!"
        return
    end
    
    isProcessing = true
    _G.LibraryStopAll = false
    StatusLabel.Text = "Menyedot " .. currentTargetCategory .. "..."
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    
    local spawned = workspace:FindFirstChild("SpawnedBooks")
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if spawned and hrp then
        local originalCFrame = hrp.CFrame
        togglePopup(false)
        
        local count = 0
        for _, book in ipairs(spawned:GetChildren()) do
            if _G.LibraryStopAll then break end
            
            -- HANYA AMBIL SESUAI KATEGORI ESP
            if book:IsA("Part") and book:GetAttribute("Category") == currentTargetCategory then
                hrp.CFrame = book.CFrame * CFrame.new(0, 2, 0)
                task.wait(0.2) 
                
                BookNetworkEvent:FireServer(book, "pickup")
                task.wait(0.1) 
                
                count = count + 1
                if count >= 5 then break end 
            end
        end
        
        task.wait(0.2)
        if not _G.LibraryStopAll then
            hrp.CFrame = originalCFrame
        end
        togglePopup(true)
        if not _G.LibraryStopAll then
            StatusLabel.Text = "Target: " .. currentTargetCategory
        end
    end
    isProcessing = false
end

local function executeSort()
    if isProcessing then return end
    if not currentTargetCategory then
        StatusLabel.Text = "⚠ Klik ESP kategori dulu!"
        return
    end
    
    isProcessing = true
    _G.LibraryStopAll = false
    StatusLabel.Text = "Menyortir " .. currentTargetCategory .. "..."
    StatusLabel.TextColor3 = Color3.fromRGB(150, 100, 255)
    
    local spawned = workspace:FindFirstChild("SpawnedBooks")
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not (spawned and hrp) then
        isProcessing = false
        return
    end
    
    local originalCFrame = hrp.CFrame
    local usedSlots = {}
    
    togglePopup(false)
    
    local count = 0
    for _, book in ipairs(spawned:GetChildren()) do
        if _G.LibraryStopAll then break end
        
        -- HANYA SORTIR SESUAI KATEGORI ESP
        if book:IsA("Part") and book:GetAttribute("Category") == currentTargetCategory then
            local targetSlot = nil
            
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj.Name == "Shelf" or obj.Name:lower():match("bookcase")) then
                    if obj:GetAttribute("Category") == currentTargetCategory then
                        for _, slot in ipairs(obj:GetDescendants()) do
                            if slot.Name:match("Slot") and slot:GetAttribute("Occupied") == false and not usedSlots[slot] then
                                targetSlot = slot
                                break
                            end
                        end
                    end
                end
                if targetSlot then break end
            end
            
            if targetSlot then
                usedSlots[targetSlot] = true
                
                hrp.CFrame = book.CFrame * CFrame.new(0, 2, 0)
                task.wait(0.2)
                BookNetworkEvent:FireServer(book, "pickup")
                task.wait(0.1)
                
                hrp.CFrame = targetSlot.CFrame * CFrame.new(0, 0, -3)
                task.wait(0.2)
                BookNetworkEvent:FireServer(book, "place", targetSlot)
                task.wait(0.1)
                
                count = count + 1
                if count >= 5 then break end 
            end
        end
    end
    
    task.wait(0.2)
    if not _G.LibraryStopAll then
        hrp.CFrame = originalCFrame
    end
    togglePopup(true)
    if not _G.LibraryStopAll then
        StatusLabel.Text = "Target: " .. currentTargetCategory
    end
    isProcessing = false
end

StopBtn.MouseButton1Click:Connect(executeStop)
MagnetBtn.MouseButton1Click:Connect(executeMagnet)
SortBtn.MouseButton1Click:Connect(executeSort)

-- KEYBINDS
_G.LibraryKeybinds = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Z then
        executeMagnet()
    elseif input.KeyCode == Enum.KeyCode.X then
        executeSort()
    elseif input.KeyCode == Enum.KeyCode.C then
        executeStop()
    end
end)

-- Populate Categories for ESP
local categories = {}
local spawned = workspace:FindFirstChild("SpawnedBooks")

if spawned then
    local count = 0
    for _, book in ipairs(spawned:GetChildren()) do
        if book:IsA("Part") then
            local category = book:GetAttribute("Category")
            local mesh = book:FindFirstChildOfClass("SpecialMesh")
            
            if category and mesh and mesh.TextureId ~= "" then
                if not categories[category] then
                    categories[category] = mesh.TextureId
                    count = count + 1
                    
                    local Row = Instance.new("Frame")
                    Row.Name = category
                    Row.Size = UDim2.new(1, -10, 0, 60)
                    Row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                    Row.BorderSizePixel = 0
                    Row.Parent = ScrollingFrame
                    
                    local BookIcon = Instance.new("ImageLabel")
                    BookIcon.Size = UDim2.new(0, 50, 0, 50)
                    BookIcon.Position = UDim2.new(0, 5, 0, 5)
                    BookIcon.Image = mesh.TextureId
                    BookIcon.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    BookIcon.Parent = Row
                    
                    local NameLabel = Instance.new("TextLabel")
                    NameLabel.Size = UDim2.new(0, 140, 0, 30)
                    NameLabel.Position = UDim2.new(0, 65, 0, 15)
                    NameLabel.BackgroundTransparency = 1
                    NameLabel.Text = category
                    NameLabel.TextColor3 = Color3.new(1, 1, 1)
                    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    NameLabel.Font = Enum.Font.GothamBold
                    NameLabel.TextSize = 16
                    NameLabel.Parent = Row
                    
                    local ESPBtn = Instance.new("TextButton")
                    ESPBtn.Size = UDim2.new(0, 60, 0, 30)
                    ESPBtn.Position = UDim2.new(1, -65, 0, 15)
                    ESPBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                    ESPBtn.Text = "ESP"
                    ESPBtn.TextColor3 = Color3.new(1, 1, 1)
                    ESPBtn.Font = Enum.Font.GothamBold
                    ESPBtn.Parent = Row
                    
                    ESPBtn.MouseButton1Click:Connect(function()
                        currentTargetCategory = category
                        StatusLabel.Text = "Target: " .. category
                        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        
                        -- Clear old
                        for _, b in ipairs(spawned:GetChildren()) do
                            if b:IsA("Part") then
                                local hl = b:FindFirstChild("BookHighlight")
                                if hl then hl:Destroy() end
                            end
                        end
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("Model") and (obj.Name == "Shelf" or obj.Name:lower():match("bookcase")) then
                                local hl = obj:FindFirstChild("BookHighlight")
                                if hl then hl:Destroy() end
                            end
                        end
                        
                        -- Apply new highlight to books
                        for _, b in ipairs(spawned:GetChildren()) do
                            if b:IsA("Part") and b:GetAttribute("Category") == currentTargetCategory then
                                local hl = Instance.new("Highlight")
                                hl.Name = "BookHighlight"
                                hl.FillColor = Color3.fromRGB(0, 255, 100) 
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.5
                                hl.Parent = b
                            end
                        end
                        
                        -- Apply highlight to matching shelves
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("Model") and (obj.Name == "Shelf" or obj.Name:lower():match("bookcase")) then
                                if obj:GetAttribute("Category") == currentTargetCategory then
                                    local hl = Instance.new("Highlight")
                                    hl.Name = "BookHighlight"
                                    hl.FillColor = Color3.fromRGB(255, 150, 0)
                                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                    hl.FillTransparency = 0.5
                                    hl.Parent = obj
                                end
                            end
                        end
                    end)
                end
            end
        end
    end
    
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, count * 65)
end

if _G.LibraryESPLoop then
    _G.LibraryESPLoop:Disconnect()
end
_G.LibraryESPLoop = RunService.RenderStepped:Connect(function()
    if currentTargetCategory and spawned then
        for _, b in ipairs(spawned:GetChildren()) do
            if b:IsA("Part") then
                local cat = b:GetAttribute("Category")
                if cat == currentTargetCategory then
                    if not b:FindFirstChild("BookHighlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "BookHighlight"
                        hl.FillColor = Color3.fromRGB(0, 255, 100)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.Parent = b
                    end
                elseif cat and cat ~= currentTargetCategory then
                    local hl = b:FindFirstChild("BookHighlight")
                    if hl then hl:Destroy() end
                end
            end
        end
    end
end)

print("Bot Sorter loaded with Shortcuts!")
