-- [[ GAME SPECIFIC ANTI-AFK (ID: 8356562067) ]] --
-- Script ini HANYA akan jalan di game dengan ID 8356562067.
-- Jika di game lain, script ini akan otomatis mati.

local TargetID = 8356562067 -- ID Game Target

if game.PlaceId ~= TargetID then
    print("[AUTO-EXEC] Skipped: This is not the target game.")
    return -- STOP DISINI JIKA BUKAN GAME YANG DITUJU
end

-- ==============================================================================
-- JIKA ID COCOK, LANJUT KE BAWAH:
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

print(" [SYSTEM] Target Game Detected! Loading Anti-AFK...")

-- ==============================================================================
-- LOGIC: ANTI-AFK & REJOIN
-- ==============================================================================
local function StartLogic()
    -- 1. Anti-AFK
    Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new()) 
        print(" [SYSTEM] Anti-AFK Triggered")
    end)

    -- 2. Auto-Rejoin
    CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == 'ErrorPrompt' then
            task.wait(2)
            while true do
                pcall(function() TeleportService:Teleport(game.PlaceId, Player) end)
                task.wait(5)
            end
        end
    end)
end
StartLogic()

-- ==============================================================================
-- LOGIC: AUTO CLAIM REWARDS
-- ==============================================================================
local sessionTimes = {120, 300, 600, 900, 1800, 3600, 7200, 14400, 21600, 28800, 36000, 43200}
local dailyRemote = ReplicatedStorage.GameRemoteFunctions:FindFirstChild("CollectDailyRewardFunction")
local sessionRemote = ReplicatedStorage.GameRemoteFunctions:FindFirstChild("CollectSessionRewardFunction")

task.spawn(function()
    while task.wait(10) do
        local playTime = 0
        pcall(function()
            playTime = Player.Leaderstats.SessionPlayTime.Value
        end)

        -- Auto claim daily
        if dailyRemote then
            pcall(function()
                local res = dailyRemote:InvokeServer()
                if res then print(" [SYSTEM] Daily Reward Claimed!") end
            end)
        end

        -- Auto claim session rewards based on total play time
        if sessionRemote then
            for i = 1, 12 do
                if playTime >= sessionTimes[i] then
                    pcall(function()
                        local res = sessionRemote:InvokeServer(i)
                        if res then print(" [SYSTEM] Session Reward " .. i .. " Claimed!") end
                    end)
                end
            end
        end
    end
end)

-- ==============================================================================
-- MODERN GUI SETUP
-- ==============================================================================
if CoreGui:FindFirstChild("ModernAntiAFK") then CoreGui.ModernAntiAFK:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernAntiAFK"
ScreenGui.Parent = CoreGui

-- MAIN CONTAINER
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 85)
MainFrame.Position = UDim2.new(0, 25, 1, -115) -- Posisi Kiri Bawah (Aman)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25) 
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui

-- ROUNDED CORNER
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- STROKE
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 70)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- INDIKATOR HIJAU
local StatusLine = Instance.new("Frame")
StatusLine.Size = UDim2.new(0, 4, 0, 30)
StatusLine.Position = UDim2.new(0, 15, 0, 12)
StatusLine.BackgroundColor3 = Color3.fromRGB(0, 255, 120) 
StatusLine.BorderSizePixel = 0
StatusLine.Parent = MainFrame

local LineCorner = Instance.new("UICorner")
LineCorner.CornerRadius = UDim.new(1, 0)
LineCorner.Parent = StatusLine

-- JUDUL
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "SYSTEM ACTIVE"
TitleLabel.Size = UDim2.new(1, -50, 0, 20)
TitleLabel.Position = UDim2.new(0, 30, 0, 12)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

-- DESKRIPSI
local DescLabel = Instance.new("TextLabel")
DescLabel.Text = "Anti-AFK & Auto Rejoin & Auto Claim"
DescLabel.Size = UDim2.new(1, -50, 0, 20)
DescLabel.Position = UDim2.new(0, 30, 0, 30)
DescLabel.BackgroundTransparency = 1
DescLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
DescLabel.Font = Enum.Font.GothamMedium
DescLabel.TextSize = 11
DescLabel.TextXAlignment = Enum.TextXAlignment.Left
DescLabel.Parent = MainFrame

-- CLAIM INFO LABEL
local ClaimInfoLabel = Instance.new("TextLabel")
ClaimInfoLabel.Name = "ClaimInfo"
ClaimInfoLabel.Text = "⏳ Next claim: calculating..."
ClaimInfoLabel.Size = UDim2.new(1, -50, 0, 20)
ClaimInfoLabel.Position = UDim2.new(0, 30, 0, 50)
ClaimInfoLabel.BackgroundTransparency = 1
ClaimInfoLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
ClaimInfoLabel.Font = Enum.Font.GothamMedium
ClaimInfoLabel.TextSize = 10
ClaimInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
ClaimInfoLabel.Parent = MainFrame

-- Update claim info label
task.spawn(function()
    while MainFrame.Parent do
        pcall(function()
            local playTime = Player.Leaderstats.SessionPlayTime.Value
            local playH = math.floor(playTime / 3600)
            local playM = math.floor((playTime % 3600) / 60)

            local nextClaimTime = nil
            for _, t in ipairs(sessionTimes) do
                if playTime < t then
                    nextClaimTime = t
                    break
                end
            end

            if nextClaimTime then
                local rem = nextClaimTime - playTime
                local rH = math.floor(rem / 3600)
                local rM = math.floor((rem % 3600) / 60)
                local rS = math.floor(rem % 60)
                if rH > 0 then
                    ClaimInfoLabel.Text = string.format("🕐 %dh%dm played | Next: %dh %dm %ds", playH, playM, rH, rM, rS)
                else
                    ClaimInfoLabel.Text = string.format("🕐 %dh%dm played | Next: %dm %ds", playH, playM, rM, rS)
                end
            else
                ClaimInfoLabel.Text = string.format("✅ %dh%dm played | All claimed!", playH, playM)
            end
        end)
        task.wait(1)
    end
end)

-- TOMBOL CLOSE
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "×"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -5, 0, 5)
CloseBtn.AnchorPoint = Vector2.new(1, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextColor3 = Color3.fromRGB(100, 100, 110)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.Parent = MainFrame

-- EFEK TOMBOL CLOSE
CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 80, 80)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(100, 100, 110)}):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 60),
        BackgroundTransparency = 1
    })
    for _, child in pairs(MainFrame:GetChildren()) do
        if child:IsA("GuiObject") then child.Visible = false end
    end
    tween:Play()
    tween.Completed:Connect(function() ScreenGui:Destroy() end)
end)

-- ANIMASI KEDIP
task.spawn(function()
    while MainFrame.Parent do
        TweenService:Create(StatusLine, TweenInfo.new(1.5), {BackgroundTransparency = 0.6}):Play()
        task.wait(1.5)
        TweenService:Create(StatusLine, TweenInfo.new(1.5), {BackgroundTransparency = 0}):Play()
        task.wait(1.5)
    end
end)
