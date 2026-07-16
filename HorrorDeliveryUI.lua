local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- === 1. BUAT TAMPILAN UI (GUI) SUPER BERSIH ===
local guiName = "HorrorDeliveryHelper"
if CoreGui:FindFirstChild(guiName) then
    CoreGui[guiName]:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 150)
mainFrame.Position = UDim2.new(1, -320, 0, 20) -- Pojok kanan atas agar tidak menutupi tengah
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 100, 100)
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "📌 ATURAN HARI INI:"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = mainFrame

local ruleText = Instance.new("TextLabel")
ruleText.Size = UDim2.new(1, -20, 1, -40)
ruleText.Position = UDim2.new(0, 10, 0, 35)
ruleText.BackgroundTransparency = 1
ruleText.TextWrapped = true
ruleText.Text = "(Buka kertas peringatan 1x untuk memindai aturan hari ini...)"
ruleText.TextColor3 = Color3.fromRGB(255, 255, 150)
ruleText.TextXAlignment = Enum.TextXAlignment.Left
ruleText.TextYAlignment = Enum.TextYAlignment.Top
ruleText.Font = Enum.Font.GothamSemibold
ruleText.TextSize = 14
ruleText.Parent = mainFrame

-- Fungsi agar UI bisa digeser
local dragging, dragInput, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- === 2. AUTO-SCAN KERTAS (KUMULATIF) ===
local allActiveRules = {}
local lastScannedRulesText = ""

task.spawn(function()
    while task.wait(1) do
        local paperGuiFound = false
        
        -- Cari tulisan judul kertas di seluruh PlayerGui
        for _, obj in ipairs(player.PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local t = obj.Text
                if t:match("Each run will have different") or t:match("Forgot something") then
                    paperGuiFound = true
                    
                    local cleanText = t:gsub("<[^>]+>", "")
                    local lines = string.split(cleanText, "\n")
                    
                    for _, line in ipairs(lines) do
                        line = line:match("^%s*(.-)%s*$")
                        if line ~= "" and not line:match("Each run will have") and not line:match("Forgot something") and not line:match("Check here") and not line:match("Click anywhere") then
                            if not line:match("Voice Actor") and not line:match("Modeler") and not line:match("Programmer") then
                                -- Masukkan ke daftar jika belum ada (Kumulatif)
                                local ruleString = "• " .. line
                                local exists = false
                                for _, existingRule in ipairs(allActiveRules) do
                                    if existingRule == ruleString then exists = true break end
                                end
                                
                                if not exists then
                                    table.insert(allActiveRules, ruleString)
                                end
                            end
                        end
                    end
                    break 
                end
            end
        end
        
        -- Perbarui UI jika ada aturan
        if #allActiveRules > 0 then
            local newText = table.concat(allActiveRules, "\n\n")
            if newText ~= lastScannedRulesText then
                lastScannedRulesText = newText
                ruleText.Text = newText
                
                -- Sesuaikan ukuran UI otomatis agar rapi
                local linesCount = #allActiveRules
                mainFrame.Size = UDim2.new(0, 300, 0, 40 + (linesCount * 50))
            end
        end
    end
end)


-- === 3. ESP WALLHACK FLEKSIBEL ===
local activeOrders = {}
local orderBoard = workspace:FindFirstChild("OrderBoard", true)

local function createESP(obj, text, color)
    if obj:FindFirstChild("HelperESP") then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "HelperESP"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 1 -- Hanya outline sesuai permintaan
    highlight.Parent = obj
    
    local bg = Instance.new("BillboardGui")
    bg.Name = "HelperESPText"
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0, 100, 0, 20)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.Parent = obj
    
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.Text = text
    txt.TextColor3 = color
    txt.BackgroundTransparency = 1
    txt.TextStrokeTransparency = 0
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 14
    txt.Parent = bg
end

RunService.RenderStepped:Connect(function()
    -- 1. Scan Order Board & Aturan Kertas
    local newOrders = {}
    if orderBoard and orderBoard:FindFirstChild("SurfaceGui") then
        for _, guiObj in ipairs(orderBoard.SurfaceGui:GetDescendants()) do
            if guiObj:IsA("TextLabel") and guiObj.Name ~= "OrdersLeft" then
                local txt = guiObj.Text
                if txt:match("^%d+$") then
                    newOrders[txt] = true
                end
            end
        end
    end
    
    -- Ekstrak nomor alamat (4-5 digit) dari kertas petunjuk (rules)
    for numberStr in lastScannedRulesText:gmatch("%d%d%d%d+") do
        newOrders[numberStr] = true
    end
    
    activeOrders = newOrders
    
    -- 2. Ekstrak Kata Kunci Bahaya dari Aturan Aktif
    local dangerKeywords = {}
    local lowerRules = lastScannedRulesText:lower()
    if lowerRules:match("meat") then dangerKeywords["meat"] = true end
    if lowerRules:match("duck") then dangerKeywords["duck"] = true end
    if lowerRules:match("teddy") then dangerKeywords["teddy"] = true end
    if lowerRules:match("mailbox") then dangerKeywords["mailbox"] = true end
    -- (Bisa mendeteksi objek lain yang mungkin disebut di aturan)

    -- 3. ESP Loop
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
            local n = obj.Name:lower()
            
            -- Cari Monster Utama
            if n == "snatcher" or n == "slammer" or n == "ringer" or n == "crooked man" then
                if not obj:FindFirstChild("HelperESP") and obj:FindFirstChild("HumanoidRootPart") then
                    createESP(obj, "⚠️ " .. obj.Name, Color3.fromRGB(255, 0, 0))
                end
            end
            
            -- Auto-Deteksi Bahaya Berdasarkan Aturan (Kata Kunci Lainnya)
            for keyword, _ in pairs(dangerKeywords) do
                if keyword ~= "meat" and n:match(keyword) then
                    if not obj:FindFirstChild("HelperESP") then
                        createESP(obj, "⚠️ BAHAYA: " .. obj.Name, Color3.fromRGB(255, 50, 50))
                    end
                end
            end
            
            -- Pengecualian Khusus: Deteksi Daging (Meat) Berdasarkan Model Asli (Tenticle / Bloodz)
            -- Game menggunakan MeshId '101576586861436' (Tenticle) dan '108039783932312' (Bloodz)
            -- KITA BUAT PERMANEN (Tidak peduli kertas sudah discan atau belum, jika ada daging = ESP)
            local isMeat = false
            if n:match("tenticle") or n:match("bloodz") then
                isMeat = true
            elseif obj:IsA("MeshPart") then
                if obj.MeshId:match("101576586861436") or obj.MeshId:match("108039783932312") then
                    isMeat = true
                end
            elseif obj:IsA("Part") then
                local mesh = obj:FindFirstChildOfClass("MeshPart") or obj:FindFirstChildOfClass("SpecialMesh")
                if mesh and (mesh.MeshId:match("101576586861436") or mesh.MeshId:match("108039783932312")) then
                    isMeat = true
                end
            end
            
            if isMeat then
                local targetObj = obj.Parent == workspace and obj or obj.Parent
                if not targetObj:FindFirstChild("HelperESP") then
                    createESP(targetObj, "🥩 BAHAYA: Daging", Color3.fromRGB(255, 0, 0))
                end
            end
            
            -- Cari Rumah Target (Berdasarkan OrderBoard)
            if n:match("house") and obj:FindFirstChild("AddressHolder") then
                local addressGui = obj.AddressHolder:FindFirstChild("SurfaceGui")
                if addressGui then
                    local addressLabel = addressGui:FindFirstChildOfClass("TextLabel")
                    if addressLabel then
                        local addrNum = addressLabel.Text:match("%d+")
                        if addrNum and activeOrders[addrNum] then
                            if not obj:FindFirstChild("TargetESP") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "TargetESP"
                                hl.FillColor = Color3.fromRGB(255, 255, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 100, 0)
                                hl.FillTransparency = 1 -- Hanya outline sesuai permintaan
                                hl.Parent = obj
                                
                                local bg = Instance.new("BillboardGui")
                                bg.Name = "TargetESPText"
                                bg.AlwaysOnTop = true
                                bg.Size = UDim2.new(0, 200, 0, 50)
                                bg.StudsOffset = Vector3.new(0, 5, 0)
                                bg.Parent = obj.AddressHolder -- Tempelkan langsung ke papan alamat agar tidak hilang
                                
                                local txt = Instance.new("TextLabel")
                                txt.Size = UDim2.new(1, 0, 1, 0)
                                txt.Text = "⭐ KIRIM KESINI (" .. addrNum .. ") ⭐"
                                txt.TextColor3 = Color3.fromRGB(255, 255, 0)
                                txt.BackgroundTransparency = 1
                                txt.TextStrokeTransparency = 0
                                txt.Font = Enum.Font.GothamBlack
                                txt.TextSize = 20
                                txt.Parent = bg
                            end
                        end
                    else
                        if obj:FindFirstChild("TargetESP") then
                            obj.TargetESP:Destroy()
                        end
                        if obj:FindFirstChild("TargetESPText") then
                            obj.TargetESPText:Destroy()
                        end
                    end
                end
            end
        end
    end
end)

print("Horror Delivery Helper (Clean Version) Loaded!")
