local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local AutoClickEnabled = true
local AutoRedeemEnabled = true
local AutoBuyEnabled = false
local AutoUpgradeEnabled = false
local AutoMinigamesEnabled = false
local AutoRebirthEnabled = false
local AutoAlienPowerEnabled = false
local AutoTreeEnabled = false

-- Create GUI
if _G.LemonGUI then
    _G.LemonGUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LemonAutoFarm"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui
_G.LemonGUI = ScreenGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 390)
Frame.Position = UDim2.new(0, 20, 0, 150)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 255, 0)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "🍋 Lemon AutoFarm Pro"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Frame

local BtnClick = Instance.new("TextButton")
BtnClick.Size = UDim2.new(0.8, 0, 0, 30)
BtnClick.Position = UDim2.new(0.1, 0, 0, 45)
BtnClick.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
BtnClick.Text = "Auto Click: ON"
BtnClick.TextColor3 = Color3.new(1, 1, 1)
BtnClick.Font = Enum.Font.GothamBold
BtnClick.Parent = Frame

local BtnRedeem = Instance.new("TextButton")
BtnRedeem.Size = UDim2.new(0.8, 0, 0, 30)
BtnRedeem.Position = UDim2.new(0.1, 0, 0, 85)
BtnRedeem.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
BtnRedeem.Text = "Auto Redeem Drop: ON"
BtnRedeem.TextColor3 = Color3.new(1, 1, 1)
BtnRedeem.Font = Enum.Font.GothamBold
BtnRedeem.Parent = Frame

local BtnBuy = Instance.new("TextButton")
BtnBuy.Size = UDim2.new(0.8, 0, 0, 30)
BtnBuy.Position = UDim2.new(0.1, 0, 0, 125)
BtnBuy.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
BtnBuy.Text = "Auto Buy Tycoon: OFF"
BtnBuy.TextColor3 = Color3.new(1, 1, 1)
BtnBuy.Font = Enum.Font.GothamBold
BtnBuy.Parent = Frame

local BtnUpgrade = Instance.new("TextButton")
BtnUpgrade.Size = UDim2.new(0.8, 0, 0, 30)
BtnUpgrade.Position = UDim2.new(0.1, 0, 0, 165)
BtnUpgrade.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
BtnUpgrade.Text = "Auto Upgrade: OFF"
BtnUpgrade.TextColor3 = Color3.new(1, 1, 1)
BtnUpgrade.Font = Enum.Font.GothamBold
BtnUpgrade.Parent = Frame

local BtnMinigames = Instance.new("TextButton")
BtnMinigames.Size = UDim2.new(0.8, 0, 0, 30)
BtnMinigames.Position = UDim2.new(0.1, 0, 0, 205)
BtnMinigames.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
BtnMinigames.Text = "Auto Win Minigames: OFF"
BtnMinigames.TextColor3 = Color3.new(1, 1, 1)
BtnMinigames.Font = Enum.Font.GothamBold
BtnMinigames.Parent = Frame

local BtnRebirth = Instance.new("TextButton")
BtnRebirth.Size = UDim2.new(0.8, 0, 0, 30)
BtnRebirth.Position = UDim2.new(0.1, 0, 0, 245)
BtnRebirth.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
BtnRebirth.Text = "Auto Rebirth (Alien): OFF"
BtnRebirth.TextColor3 = Color3.new(1, 1, 1)
BtnRebirth.Font = Enum.Font.GothamBold
BtnRebirth.Parent = Frame

local BtnAlienPower = Instance.new("TextButton")
BtnAlienPower.Size = UDim2.new(0.8, 0, 0, 30)
BtnAlienPower.Position = UDim2.new(0.1, 0, 0, 285)
BtnAlienPower.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
BtnAlienPower.Text = "Auto Alien Power: OFF"
BtnAlienPower.TextColor3 = Color3.new(1, 1, 1)
BtnAlienPower.Font = Enum.Font.GothamBold
BtnAlienPower.Parent = Frame

local BtnTree = Instance.new("TextButton")
BtnTree.Size = UDim2.new(0.8, 0, 0, 30)
BtnTree.Position = UDim2.new(0.1, 0, 0, 325)
BtnTree.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
BtnTree.Text = "Auto Tree Fruit: OFF"
BtnTree.TextColor3 = Color3.new(1, 1, 1)
BtnTree.Font = Enum.Font.GothamBold
BtnTree.Parent = Frame

BtnClick.MouseButton1Click:Connect(function()
    AutoClickEnabled = not AutoClickEnabled
    BtnClick.Text = "Auto Click: " .. (AutoClickEnabled and "ON" or "OFF")
    BtnClick.BackgroundColor3 = AutoClickEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

BtnRedeem.MouseButton1Click:Connect(function()
    AutoRedeemEnabled = not AutoRedeemEnabled
    BtnRedeem.Text = "Auto Redeem Drop: " .. (AutoRedeemEnabled and "ON" or "OFF")
    BtnRedeem.BackgroundColor3 = AutoRedeemEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

BtnBuy.MouseButton1Click:Connect(function()
    AutoBuyEnabled = not AutoBuyEnabled
    BtnBuy.Text = "Auto Buy Tycoon: " .. (AutoBuyEnabled and "ON" or "OFF")
    BtnBuy.BackgroundColor3 = AutoBuyEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

BtnUpgrade.MouseButton1Click:Connect(function()
    AutoUpgradeEnabled = not AutoUpgradeEnabled
    BtnUpgrade.Text = "Auto Upgrade: " .. (AutoUpgradeEnabled and "ON" or "OFF")
    BtnUpgrade.BackgroundColor3 = AutoUpgradeEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

BtnMinigames.MouseButton1Click:Connect(function()
    AutoMinigamesEnabled = not AutoMinigamesEnabled
    BtnMinigames.Text = "Auto Win Minigames: " .. (AutoMinigamesEnabled and "ON" or "OFF")
    BtnMinigames.BackgroundColor3 = AutoMinigamesEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

BtnRebirth.MouseButton1Click:Connect(function()
    AutoRebirthEnabled = not AutoRebirthEnabled
    BtnRebirth.Text = "Auto Rebirth (Alien): " .. (AutoRebirthEnabled and "ON" or "OFF")
    BtnRebirth.BackgroundColor3 = AutoRebirthEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    print("UI: Auto Rebirth set to", AutoRebirthEnabled)
end)

BtnAlienPower.MouseButton1Click:Connect(function()
    AutoAlienPowerEnabled = not AutoAlienPowerEnabled
    BtnAlienPower.Text = "Auto Alien Power: " .. (AutoAlienPowerEnabled and "ON" or "OFF")
    BtnAlienPower.BackgroundColor3 = AutoAlienPowerEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    print("UI: Auto Alien Power set to", AutoAlienPowerEnabled)
end)

BtnTree.MouseButton1Click:Connect(function()
    AutoTreeEnabled = not AutoTreeEnabled
    BtnTree.Text = "Auto Tree Fruit: " .. (AutoTreeEnabled and "ON" or "OFF")
    BtnTree.BackgroundColor3 = AutoTreeEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    print("UI: Auto Tree Fruit set to", AutoTreeEnabled)
end)

-- Locate Remotes
local clickRemote
local redeemRemote
for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") and v.Name == "ClickFruitService.Clicked" then
        clickRemote = v
    elseif v:IsA("RemoteFunction") and v.Name == "CashDropService.Redeem" then
        redeemRemote = v
    end
end

if _G.LemonLoop then
    _G.LemonLoop:Disconnect()
end

_G.LemonLoop = RunService.RenderStepped:Connect(function()
    if AutoClickEnabled and clickRemote then
        -- Spam clicks for fruit
        for i = 1, 10 do
            clickRemote:FireServer()
        end
    end
end)

-- Auto Redeem, Buy & Upgrade Loop
task.spawn(function()
    while task.wait(0.5) do
        if AutoRedeemEnabled and redeemRemote then
            task.spawn(function()
                pcall(function()
                    redeemRemote:InvokeServer()
                end)
            end)
        end
        
        local myTycoon = nil
        for _, t in ipairs(workspace:GetChildren()) do
            if t.Name:find("Tycoon") and t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer then
                myTycoon = t
                break
            end
        end
        
        local nowTime = os.time()
        
        if myTycoon then
            -- Throttle WakeIncomeStream (Every 15 seconds)
            if AutoClickEnabled and myTycoon:FindFirstChild("Remotes") and myTycoon.Remotes:FindFirstChild("WakeIncomeStream") then
                if not _G.LastWake or nowTime - _G.LastWake >= 15 then
                    _G.LastWake = nowTime
                    local wakeRemote = myTycoon.Remotes.WakeIncomeStream
                    if myTycoon:FindFirstChild("Purchases") then
                        for _, p in ipairs(myTycoon.Purchases:GetChildren()) do
                            task.spawn(function() pcall(function() wakeRemote:InvokeServer(p.Name) end) end)
                        end
                    end
                end
            end
            
            if AutoBuyEnabled and myTycoon:FindFirstChild("Purchases") then
                if typeof(firetouchinterest) == "function" then
                    for _, v in ipairs(myTycoon.Purchases:GetDescendants()) do
                        if v:IsA("Part") and v.Name == "Button" then
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root then
                                firetouchinterest(root, v, 0)
                                firetouchinterest(root, v, 1)
                            end
                        end
                    end
                end
            end
            
            -- Throttle Upgrades (Every 5 seconds)
            if AutoUpgradeEnabled and myTycoon:FindFirstChild("Purchases") then
                if not _G.LastUpgrade or nowTime - _G.LastUpgrade >= 5 then
                    _G.LastUpgrade = nowTime
                    for _, v in ipairs(myTycoon.Purchases:GetDescendants()) do
                        if v:IsA("RemoteFunction") and v.Name == "Upgrade" then
                            task.spawn(function() pcall(function() v:InvokeServer(1) end) end)
                        end
                    end
                end
            end
            
            if AutoTreeEnabled then
                if myTycoon:FindFirstChild("Constant") and myTycoon.Constant:FindFirstChild("Trees") then
                    for _, tree in ipairs(myTycoon.Constant.Trees:GetChildren()) do
                        for _, obj in ipairs(tree:GetDescendants()) do
                            if obj:IsA("ClickDetector") and obj.Parent.Name == "ClickPart" then
                                fireclickdetector(obj)
                            end
                        end
                    end
                end
            end

            local remotes = myTycoon:FindFirstChild("Remotes")
            if remotes then
                if AutoRebirthEnabled then
                    local rb = remotes:FindFirstChild("Rebirth")
                    if rb then
                        task.spawn(function() 
                            local success, err = pcall(function() rb:InvokeServer() end)
                            if not success then print("Rebirth Error: ", err) end
                        end)
                    end
                end
                if AutoAlienPowerEnabled then
                    local upg = remotes:FindFirstChild("UpgradePowerLevel")
                    if upg then
                        task.spawn(function()
                            local powers = {"ClickFruitValue", "UpgradeStack", "Manage", "BuyNext", "WalkSpeed"}
                            for _, pName in ipairs(powers) do
                                task.spawn(function() 
                                    local success, err = pcall(function() upg:InvokeServer(pName) end) 
                                    if not success then print("Upgrade Power Error ("..pName.."): ", err) end
                                end)
                                task.wait(0.2)
                            end
                        end)
                    end
                end
            end
        end
    end
end)

-- Auto Win Minigames Loop
task.spawn(function()
    local raceStart = ReplicatedStorage.Core.RemoteRequest:FindFirstChild("MinigameRaceService.Start")
    local raceEnd = ReplicatedStorage.Core.RemoteRequest:FindFirstChild("MinigameRaceService.End")
    local tradeStart = ReplicatedStorage.Core.RemoteRequest:FindFirstChild("MinigameTradeService.Start")
    local tradeEnd = ReplicatedStorage.Core.RemoteRequest:FindFirstChild("MinigameTradeService.End")

    while task.wait(2) do
        if AutoMinigamesEnabled then
            local now = workspace:GetServerTimeNow()
            
            -- Check Availability safely
            local raceAvail = 0
            local tradeAvail = 0
            pcall(function()
                local l__Player = require(ReplicatedStorage.Core.Player)
                local l__PlayerValues = require(ReplicatedStorage.Core.PlayerValues)
                local vals = l__Player.getLocal():GetComponent(l__PlayerValues)
                raceAvail = vals:Get("MinigameRaceAvailable") or 0
                tradeAvail = vals:Get("MinigameTradeAvailable") or 0
            end)

            -- Auto Race
            if raceStart and raceEnd and now >= raceAvail then
                pcall(function()
                    local succ, _ = raceStart:InvokeServer()
                    if succ then
                        raceEnd:InvokeServer(1) -- Send 1st Place to server!
                    end
                end)
            end
            
            -- Auto Trade
            if tradeStart and tradeEnd and now >= tradeAvail then
                pcall(function()
                    local config, _ = tradeStart:InvokeServer()
                    if config and config.LineConfig then
                        -- Calculate Maximum Profit
                        local p37 = config.LineConfig
                        local v38 = p37.Values[1]
                        for v39 = 2, #p37.Timings do
                            local v40 = p37.Values[v39 - 1]
                            local v41 = p37.Values[v39]
                            if v40 < v41 then
                                v38 = v38 * (v41 / v40)
                            end
                        end
                        -- Send Maximum Profit to server!
                        tradeEnd:InvokeServer(v38)
                    end
                end)
            end
        end
    end
end)

print("🍋 Lemon AutoFarm Pro Loaded with Auto-Win Minigames!")
