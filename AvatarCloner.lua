--[[
    🎭 AVATAR CLONER v4.0
    Local Overlay Technique | Game Compatible
    Original char stays intact → death/respawn work
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer
local overlay = nil
local renderConn = nil
local lastDesc = nil
local hiddenParts = {}
local targetUserId = nil
local dragging, dragStart, startPos = false, nil, nil

local C = {
    bg=Color3.fromRGB(15,15,22), top=Color3.fromRGB(22,22,32),
    accent=Color3.fromRGB(110,75,255), green=Color3.fromRGB(45,200,120),
    red=Color3.fromRGB(240,60,70), orange=Color3.fromRGB(255,160,40),
    input=Color3.fromRGB(30,30,45), text=Color3.fromRGB(230,230,240),
    sub=Color3.fromRGB(140,140,170), preview=Color3.fromRGB(25,25,38),
    stroke=Color3.fromRGB(60,50,120),
}

-- Cleanup old
if CoreGui:FindFirstChild("AvatarClonerPro") then CoreGui:FindFirstChild("AvatarClonerPro"):Destroy() end

--// ═══ CORE: OVERLAY FUNCTIONS ═══

local function destroyOverlay()
    if renderConn then renderConn:Disconnect(); renderConn = nil end
    if overlay then pcall(function() overlay:Destroy() end); overlay = nil end
end

local function unhideCharacter()
    local char = LP.Character
    if not char then return end
    for part, data in pairs(hiddenParts) do
        pcall(function()
            if part:IsA("BasePart") then part.Transparency = data end
            if part:IsA("Decal") then part.Transparency = data end
        end)
    end
    hiddenParts = {}
end

local function hideCharacter(char)
    hiddenParts = {}
    for _,v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            hiddenParts[v] = v.Transparency
            v.Transparency = 1
        elseif v:IsA("Decal") then
            hiddenParts[v] = v.Transparency
            v.Transparency = 1
        end
    end
end

local function applyOverlay(desc)
    local char = LP.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local charHRP = char:FindFirstChild("HumanoidRootPart")
    if not charHRP then return false end

    -- Cleanup previous
    destroyOverlay()
    unhideCharacter()

    -- Create overlay model from description
    local rigType = hum.RigType
    local newModel
    local ok1 = pcall(function()
        newModel = Players:CreateHumanoidModelFromDescription(desc, rigType, Enum.AssetTypeVerification.ClientOnly)
    end)
    if not ok1 or not newModel then
        local ok2 = pcall(function()
            newModel = Players:CreateHumanoidModelFromDescription(desc, rigType)
        end)
        if not ok2 or not newModel then return false end
    end

    -- Setup overlay parts: no collision, massless
    for _,v in pairs(newModel:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.CanQuery = false
            v.CanTouch = false
            v.Massless = true
            v.Anchored = false
        end
    end

    -- Neuter overlay's Humanoid (keep alive for Motor6D, but disable behavior)
    local overlayHum = newModel:FindFirstChildOfClass("Humanoid")
    if overlayHum then
        overlayHum.PlatformStand = true
        overlayHum.AutoRotate = false
        pcall(function() overlayHum.BreakJointsOnDeath = false end)
        pcall(function() overlayHum.RequiresNeck = false end)
        overlayHum.MaxHealth = math.huge
        overlayHum.Health = math.huge
    end

    -- Remove scripts from overlay
    for _,v in pairs(newModel:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end
    end

    -- Make overlay HRP transparent
    local overlayHRP = newModel:FindFirstChild("HumanoidRootPart")
    if not overlayHRP then return false end
    overlayHRP.Transparency = 1

    -- Position overlay at character BEFORE parenting
    newModel:PivotTo(charHRP.CFrame)

    -- Parent overlay
    newModel.Name = "_AvatarOverlay"
    newModel.Parent = workspace

    -- Weld overlay HRP to character HRP
    local weld = Instance.new("Weld")
    weld.Part0 = charHRP
    weld.Part1 = overlayHRP
    weld.C0 = CFrame.new()
    weld.C1 = CFrame.new()
    weld.Parent = overlayHRP

    -- Hide original character
    hideCharacter(char)

    -- Build Motor6D lookup for overlay
    local overlayJoints = {}
    for _,v in pairs(newModel:GetDescendants()) do
        if v:IsA("Motor6D") then
            overlayJoints[v.Name] = v
        end
    end

    -- Mirror animations every frame
    renderConn = RunService.RenderStepped:Connect(function()
        if not char or not char.Parent then return end
        if not newModel or not newModel.Parent then return end
        for _,joint in pairs(char:GetDescendants()) do
            if joint:IsA("Motor6D") then
                local oj = overlayJoints[joint.Name]
                if oj then
                    oj.Transform = joint.Transform
                end
            end
        end
    end)

    overlay = newModel
    lastDesc = desc
    return true
end

-- Auto-reapply after death/respawn
LP.CharacterAdded:Connect(function(newChar)
    if lastDesc then
        task.wait(3)
        if lastDesc then
            applyOverlay(lastDesc)
        end
    end
end)

-- Also re-hide if character parts become visible
-- (some games reset transparency)

--// ═══ GUI ═══
local Gui = Instance.new("ScreenGui")
Gui.Name = "AvatarClonerPro"
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.ResetOnSpawn = false
pcall(function() Gui.Parent = CoreGui end)
if not Gui.Parent then Gui.Parent = LP:WaitForChild("PlayerGui") end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,320,0,500)
Main.Position = UDim2.new(0.5,-160,0.5,-250)
Main.BackgroundColor3 = C.bg; Main.BorderSizePixel = 0
Main.ClipsDescendants = true; Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,14)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = C.stroke; mainStroke.Thickness = 1.5; mainStroke.Transparency = 0.3

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,44); TitleBar.BackgroundColor3 = C.top
TitleBar.BorderSizePixel = 0; TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,14)
local tbFix = Instance.new("Frame", TitleBar)
tbFix.Size = UDim2.new(1,0,0,14); tbFix.Position = UDim2.new(0,0,1,-14)
tbFix.BackgroundColor3 = C.top; tbFix.BorderSizePixel = 0

local AL = Instance.new("Frame", Main)
AL.Size = UDim2.new(1,0,0,2); AL.Position = UDim2.new(0,0,0,44)
AL.BorderSizePixel = 0; AL.BackgroundColor3 = C.accent
local ag = Instance.new("UIGradient", AL)
ag.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(110,75,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(180,100,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(60,130,255))
}

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1,-80,1,0); Title.Position = UDim2.new(0,16,0,0)
Title.BackgroundTransparency = 1; Title.Text = "🎭 Avatar Cloner"
Title.TextColor3 = C.text; Title.TextSize = 16; Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0,30,0,30); CloseBtn.Position = UDim2.new(1,-38,0.5,-15)
CloseBtn.BackgroundColor3 = C.red; CloseBtn.BackgroundTransparency = 0.8
CloseBtn.Text = "✕"; CloseBtn.TextColor3 = C.red; CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,8)

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1,-28,1,-60); Content.Position = UDim2.new(0,14,0,54)
Content.BackgroundTransparency = 1

local SLabel = Instance.new("TextLabel", Content)
SLabel.Size = UDim2.new(1,0,0,18); SLabel.BackgroundTransparency = 1
SLabel.Text = "TARGET USERNAME"; SLabel.TextColor3 = C.sub; SLabel.TextSize = 11
SLabel.Font = Enum.Font.GothamBold; SLabel.TextXAlignment = Enum.TextXAlignment.Left

local SearchBox = Instance.new("TextBox", Content)
SearchBox.Size = UDim2.new(1,-90,0,38); SearchBox.Position = UDim2.new(0,0,0,22)
SearchBox.BackgroundColor3 = C.input; SearchBox.Text = ""
SearchBox.PlaceholderText = "Ketik username..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(80,80,110)
SearchBox.TextColor3 = C.text; SearchBox.TextSize = 14; SearchBox.Font = Enum.Font.Gotham
SearchBox.BorderSizePixel = 0; SearchBox.ClearTextOnFocus = false
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0,8)
Instance.new("UIPadding", SearchBox).PaddingLeft = UDim.new(0,12)
local sst = Instance.new("UIStroke", SearchBox); sst.Color = C.stroke; sst.Transparency = 0.5

local SearchBtn = Instance.new("TextButton", Content)
SearchBtn.Size = UDim2.new(0,80,0,38); SearchBtn.Position = UDim2.new(1,-80,0,22)
SearchBtn.BackgroundColor3 = C.accent; SearchBtn.Text = "🔍 Cari"
SearchBtn.TextColor3 = Color3.new(1,1,1); SearchBtn.TextSize = 13
SearchBtn.Font = Enum.Font.GothamBold; SearchBtn.BorderSizePixel = 0
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0,8)

local PFrame = Instance.new("Frame", Content)
PFrame.Size = UDim2.new(1,0,0,200); PFrame.Position = UDim2.new(0,0,0,72)
PFrame.BackgroundColor3 = C.preview; PFrame.BorderSizePixel = 0
Instance.new("UICorner", PFrame).CornerRadius = UDim.new(0,10)
local pst = Instance.new("UIStroke", PFrame); pst.Color = C.stroke; pst.Transparency = 0.6

local PImage = Instance.new("ImageLabel", PFrame)
PImage.Size = UDim2.new(0,150,0,150); PImage.Position = UDim2.new(0.5,-75,0,10)
PImage.BackgroundTransparency = 1; PImage.Image = ""; PImage.ScaleType = Enum.ScaleType.Fit

local PHolder = Instance.new("TextLabel", PFrame)
PHolder.Size = UDim2.new(1,0,1,-24); PHolder.BackgroundTransparency = 1
PHolder.Text = "👤\n\nCari username untuk\nmelihat preview avatar"
PHolder.TextColor3 = C.sub; PHolder.TextSize = 13; PHolder.Font = Enum.Font.Gotham

local PName = Instance.new("TextLabel", PFrame)
PName.Size = UDim2.new(1,0,0,24); PName.Position = UDim2.new(0,0,1,-28)
PName.BackgroundTransparency = 1; PName.Text = ""; PName.TextColor3 = C.accent
PName.TextSize = 13; PName.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", Content)
Status.Size = UDim2.new(1,0,0,22); Status.Position = UDim2.new(0,0,0,280)
Status.BackgroundTransparency = 1; Status.Text = ""; Status.TextColor3 = C.sub
Status.TextSize = 12; Status.Font = Enum.Font.Gotham

local function makeBtn(txt, col, y)
    local b = Instance.new("TextButton", Content)
    b.Size = UDim2.new(1,0,0,42); b.Position = UDim2.new(0,0,0,y)
    b.BackgroundColor3 = col; b.Text = txt; b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 14; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0
    b.AutoButtonColor = false; Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    return b
end
local CloneBtn = makeBtn("⚡ CLONE AVATAR", C.accent, 310)
local ResetBtn = makeBtn("🔄 RESET KE ASLI", C.green, 360)

local Cred = Instance.new("TextLabel", Content)
Cred.Size = UDim2.new(1,0,0,20); Cred.Position = UDim2.new(0,0,0,420)
Cred.BackgroundTransparency = 1; Cred.Text = "Avatar Cloner v4.0 • Overlay Mode"
Cred.TextColor3 = Color3.fromRGB(70,70,100); Cred.TextSize = 10; Cred.Font = Enum.Font.Gotham

local function setStatus(msg, col) Status.Text = msg; Status.TextColor3 = col or C.sub end

--// ═══ DRAG ═══
TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = inp.Position; startPos = Main.Position
        inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

--// ═══ HOVER FX ═══
local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
for _,info in pairs({{SearchBtn,Color3.fromRGB(140,105,255),C.accent},{CloneBtn,Color3.fromRGB(140,105,255),C.accent},{ResetBtn,Color3.fromRGB(60,230,140),C.green}}) do
    local b,hc,nc = info[1],info[2],info[3]
    b.MouseEnter:Connect(function() TweenService:Create(b,ti,{BackgroundColor3=hc}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,ti,{BackgroundColor3=nc}):Play() end)
end

task.spawn(function()
    local h = 0
    while Gui.Parent do h=(h+0.003)%1; mainStroke.Color=Color3.fromHSV(h,0.5,0.55); task.wait(0.03) end
end)

Main.Size = UDim2.new(0,320,0,0); Main.BackgroundTransparency = 1
TweenService:Create(Main, TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
    {Size=UDim2.new(0,320,0,500), BackgroundTransparency=0}):Play()

--// ═══ SEARCH ═══
local function doSearch()
    local username = SearchBox.Text
    if username == "" then setStatus("⚠ Ketik username dulu!", C.orange) return end
    setStatus("🔍 Mencari...", C.sub)
    PImage.Image = ""; PName.Text = ""; PHolder.Visible = true; targetUserId = nil
    local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
    if ok and uid then
        targetUserId = uid; PHolder.Visible = false
        PImage.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=420&h=420", uid)
        PName.Text = username.." (ID: "..tostring(uid)..")"
        setStatus("✅ User ditemukan!", C.green)
    else
        setStatus("❌ User tidak ditemukan!", C.red)
        PHolder.Text = "❌\n\nUser tidak ditemukan."; PHolder.Visible = true
    end
end
SearchBtn.MouseButton1Click:Connect(doSearch)
SearchBox.FocusLost:Connect(function(enter) if enter then doSearch() end end)

--// ═══ CLONE ═══
CloneBtn.MouseButton1Click:Connect(function()
    if not targetUserId then setStatus("⚠ Cari user dulu!", C.orange) return end
    if not LP.Character then setStatus("❌ Karakter tidak ada!", C.red) return end
    setStatus("⏳ Mengclone avatar...", C.orange)

    local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(targetUserId) end)
    if not ok or not desc then setStatus("❌ Gagal ambil data!", C.red) return end

    local success = applyOverlay(desc)
    if success then
        setStatus("✅ Avatar diclone! (Overlay)", C.green)
        task.spawn(function()
            for i=1,3 do mainStroke.Thickness=3; task.wait(0.15); mainStroke.Thickness=1.5; task.wait(0.15) end
        end)
    else
        setStatus("❌ Gagal membuat overlay!", C.red)
    end
end)

--// ═══ RESET ═══
ResetBtn.MouseButton1Click:Connect(function()
    destroyOverlay()
    unhideCharacter()
    lastDesc = nil
    setStatus("✅ Avatar direset!", C.green)
    task.spawn(function()
        for i=1,3 do mainStroke.Thickness=3; task.wait(0.15); mainStroke.Thickness=1.5; task.wait(0.15) end
    end)
end)

--// ═══ CLOSE ═══
CloseBtn.MouseButton1Click:Connect(function()
    destroyOverlay(); unhideCharacter(); lastDesc = nil
    local tw = TweenService:Create(Main, TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),
        {Size=UDim2.new(0,320,0,0), BackgroundTransparency=1})
    tw:Play(); tw.Completed:Connect(function() Gui:Destroy() end)
end)

setStatus("Siap digunakan! 🚀", C.sub)
