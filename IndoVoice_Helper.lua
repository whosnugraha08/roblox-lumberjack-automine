-- IndoVoice Anti-AFK + Auto Claim + Auto Reconnect
-- Auto-executes on join

local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PLACE_ID = game.PlaceId
local JOB_ID = game.JobId -- Save current server JobId for reconnect

-- ============ GUI ============
if game.CoreGui:FindFirstChild("IndoVoiceHelper") then
    game.CoreGui:FindFirstChild("IndoVoiceHelper"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IndoVoiceHelper"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 150)
Frame.Position = UDim2.new(0, 20, 0, 150)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 200, 255)
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "🎤 IndoVoice Helper"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Frame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
StatusLabel.Position = UDim2.new(0.05, 0, 0, 32)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Anti-AFK: ✅ Active"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 13
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

local ClaimStatus = Instance.new("TextLabel")
ClaimStatus.Size = UDim2.new(0.9, 0, 0, 20)
ClaimStatus.Position = UDim2.new(0.05, 0, 0, 54)
ClaimStatus.BackgroundTransparency = 1
ClaimStatus.Text = "Auto Claim: ⏳ Waiting..."
ClaimStatus.TextColor3 = Color3.fromRGB(255, 255, 100)
ClaimStatus.Font = Enum.Font.Gotham
ClaimStatus.TextSize = 13
ClaimStatus.TextXAlignment = Enum.TextXAlignment.Left
ClaimStatus.Parent = Frame

local ReconnectStatus = Instance.new("TextLabel")
ReconnectStatus.Size = UDim2.new(0.9, 0, 0, 20)
ReconnectStatus.Position = UDim2.new(0.05, 0, 0, 76)
ReconnectStatus.BackgroundTransparency = 1
ReconnectStatus.Text = "Auto Reconnect: ✅ Ready"
ReconnectStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
ReconnectStatus.Font = Enum.Font.Gotham
ReconnectStatus.TextSize = 13
ReconnectStatus.TextXAlignment = Enum.TextXAlignment.Left
ReconnectStatus.Parent = Frame

local SessionInfo = Instance.new("TextLabel")
SessionInfo.Size = UDim2.new(0.9, 0, 0, 30)
SessionInfo.Position = UDim2.new(0.05, 0, 0, 100)
SessionInfo.BackgroundTransparency = 1
SessionInfo.Text = "Session: 0m | Next claim: --"
SessionInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
SessionInfo.Font = Enum.Font.Gotham
SessionInfo.TextSize = 12
SessionInfo.TextXAlignment = Enum.TextXAlignment.Left
SessionInfo.TextWrapped = true
SessionInfo.Parent = Frame

-- ============ ANTI-AFK ============
task.spawn(function()
    while task.wait(60) do
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
end)

-- ============ AUTO CLAIM ============
local sessionTimes = {120, 300, 600, 900, 1800, 3600, 7200, 14400, 21600, 28800, 36000, 43200}
local dailyRemote = ReplicatedStorage.GameRemoteFunctions:FindFirstChild("CollectDailyRewardFunction")
local sessionRemote = ReplicatedStorage.GameRemoteFunctions:FindFirstChild("CollectSessionRewardFunction")

task.spawn(function()
    while task.wait(10) do
        local playTime = 0
        pcall(function()
            playTime = LocalPlayer.Leaderstats.SessionPlayTime.Value
        end)
        
        -- Update UI
        local playHours = math.floor(playTime / 3600)
        local playMin = math.floor((playTime % 3600) / 60)
        local nextClaimTime = nil
        for i, t in ipairs(sessionTimes) do
            if playTime < t then
                nextClaimTime = t
                break
            end
        end
        
        if nextClaimTime then
            local remaining = nextClaimTime - playTime
            local remH = math.floor(remaining / 3600)
            local remMin = math.floor((remaining % 3600) / 60)
            local remSec = math.floor(remaining % 60)
            if remH > 0 then
                SessionInfo.Text = string.format("Play: %dh%dm | Next: %dh %dm %ds", playHours, playMin, remH, remMin, remSec)
            else
                SessionInfo.Text = string.format("Play: %dh%dm | Next: %dm %ds", playHours, playMin, remMin, remSec)
            end
        else
            SessionInfo.Text = string.format("Play: %dh%dm | All claimed! ✅", playHours, playMin)
        end
        
        -- Try to claim daily
        if dailyRemote then
            pcall(function()
                local res = dailyRemote:InvokeServer()
                if res then
                    ClaimStatus.Text = "Auto Claim: ✅ Daily claimed!"
                    ClaimStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
                end
            end)
        end
        
        -- Try to claim all session rewards based on total play time
        if sessionRemote then
            for i = 1, 12 do
                if playTime >= sessionTimes[i] then
                    pcall(function()
                        local res = sessionRemote:InvokeServer(i)
                        if res then
                            ClaimStatus.Text = "Auto Claim: ✅ Session " .. i .. " claimed!"
                            ClaimStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
                        end
                    end)
                end
            end
        end
    end
end)

-- ============ AUTO RECONNECT ============
-- When disconnected, try to rejoin the same private server
game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    -- Disconnected! Try to rejoin
    pcall(function()
        ReconnectStatus.Text = "Auto Reconnect: 🔄 Reconnecting..."
        ReconnectStatus.TextColor3 = Color3.fromRGB(255, 200, 0)
    end)
    
    task.wait(3)
    
    pcall(function()
        TeleportService:Teleport(PLACE_ID, LocalPlayer)
    end)
end)

-- Also handle CoreGui kick screen
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local errorMsg = game:GetService("GuiService"):GetErrorMessage()
            if errorMsg and errorMsg ~= "" then
                task.wait(3)
                TeleportService:Teleport(PLACE_ID, LocalPlayer)
            end
        end)
    end
end)

print("🎤 IndoVoice Helper Loaded! Anti-AFK + Auto Claim + Auto Reconnect")
