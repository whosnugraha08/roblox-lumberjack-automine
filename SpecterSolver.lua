local Specter = _G.SpecterState or {}
Specter.Highlights = Specter.Highlights or {}
Specter.EvidenceFound = Specter.EvidenceFound or {}
Specter.CurrentGhostName = Specter.CurrentGhostName or "Unknown"
Specter.UI = Specter.UI or nil
_G.SpecterState = Specter

-- Require Knit Controllers for Auto-Clicking Journal
local Knit, JournalController, EvidencesData
pcall(function()
    Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
    JournalController = Knit.GetController("JournalController")
    EvidencesData = require(game:GetService("ReplicatedStorage").Shared.Evidences)
end)

local function createHighlight(inst, text, color)
    if Specter.Highlights[inst] then return end
    
    local hl = Instance.new("Highlight")
    hl.Adornee = inst
    hl.FillColor = color
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.Parent = game.CoreGui
    
    local bg = Instance.new("BillboardGui")
    bg.Adornee = inst
    bg.Size = UDim2.new(0, 200, 0, 50)
    bg.AlwaysOnTop = true
    
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = color
    txt.TextStrokeTransparency = 0
    txt.TextSize = 14
    txt.Font = Enum.Font.Code
    txt.Parent = bg
    bg.Parent = game.CoreGui
    
    Specter.Highlights[inst] = {hl = hl, bg = bg}
end

local function isVisible(inst)
    if inst:IsA("BasePart") then return inst.Transparency < 1 end
    if inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart.Transparency < 1 end
    return true
end

local function scanSpecter()
    -- Clear old highlights for items that don't exist or became invisible
    for inst, data in pairs(Specter.Highlights) do
        if not inst or not inst.Parent or not isVisible(inst) then
            data.hl:Destroy()
            data.bg:Destroy()
            Specter.Highlights[inst] = nil
        end
    end
    
    -- 1. Find Ghost (Visible Models)
    for _, v in ipairs(workspace.NPCs:GetChildren()) do
        if v:IsA("Model") and v.Name ~= "GLOBAL" then
            createHighlight(v, "👻 GHOST VISIBLE", Color3.fromRGB(255, 0, 0))
        end
    end
    for _, v in ipairs(workspace.ServerNPCs:GetChildren()) do
        if v:IsA("Model") and v.Name ~= "GLOBAL" then
            createHighlight(v, "👻 GHOST VISIBLE", Color3.fromRGB(255, 0, 0))
        end
    end
    
    -- 1.5 Track Invisible Ghost Location
    if workspace:FindFirstChild("ServerNPCs") and workspace.ServerNPCs:FindFirstChild("GLOBAL") then
        local pos = workspace.ServerNPCs.GLOBAL:GetAttribute("Position")
        if pos and typeof(pos) == "Vector3" then
            if not Specter.GhostMarker then
                local part = Instance.new("Part")
                part.Size = Vector3.new(1, 1, 1)
                part.Anchored = true
                part.CanCollide = false
                part.Transparency = 1
                part.Parent = game.CoreGui
                Specter.GhostMarker = part
            end
            Specter.GhostMarker.Position = pos
            createHighlight(Specter.GhostMarker, "📍 GHOST LOCATION", Color3.fromRGB(255, 0, 0))
        end
    end
    
    -- Function to add evidence without duplicates
    local function addEvidence(name)
        if not table.find(Specter.EvidenceFound, name) then
            table.insert(Specter.EvidenceFound, name)
            
            -- Auto-Click Evidence in Journal
            pcall(function()
                if JournalController then
                    if not table.find(JournalController.SelectedEvidences, name) then
                        JournalController:EvidenceClicked(name, true)
                    end
                end
            end)
        end
    end
    
    -- 2. Find Evidence
    local hasRealEvidence = false
    if workspace.Dynamic:FindFirstChild("Evidence") then
        for _, evidenceFolder in ipairs(workspace.Dynamic.Evidence:GetChildren()) do
            hasRealEvidence = false
            for _, ev in ipairs(evidenceFolder:GetChildren()) do
                if ev:IsA("BasePart") or ev:IsA("Model") then
                    if evidenceFolder.Name == "EMF" then
                        if ev.Name:match("5") then
                            hasRealEvidence = true
                            createHighlight(ev, "🔎 EMF 5", Color3.fromRGB(0, 255, 255))
                        end
                    elseif evidenceFolder.Name == "MotionGrids" then
                        -- Only valid if a grid part turned red (R is significantly higher than G/B)
                        local isRed = false
                        for _, p in ipairs(ev:GetDescendants()) do
                            if p:IsA("BasePart") and p.Color.R > (p.Color.G + 0.2) and p.Color.R > (p.Color.B + 0.2) then
                                isRed = true
                                break
                            end
                        end
                        if isRed then
                            hasRealEvidence = true
                            createHighlight(ev, "🔎 " .. evidenceFolder.Name, Color3.fromRGB(255, 0, 0))
                        end
                    else
                        hasRealEvidence = true
                        createHighlight(ev, "🔎 " .. evidenceFolder.Name, Color3.fromRGB(0, 255, 255))
                    end
                end
            end
            
            if hasRealEvidence then
                if evidenceFolder.Name == "EMF" then
                    addEvidence("EMF 5")
                elseif evidenceFolder.Name == "MotionGrids" then
                    addEvidence("Motion")
                else
                    addEvidence(evidenceFolder.Name)
                end
            end
        end
    end
        
    -- 2.3 Check for Freezing Temperature (Cold Breath & Thermometer Screen)
    local function checkFreezing()
        -- Cold Breath
        if game.Players.LocalPlayer.Character then
            for _, v in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if v:IsA("ParticleEmitter") and (v.Name:lower():find("breath") or v.Name:lower():find("cold")) then
                    return true
                end
            end
        end
        
        -- Thermometer dropped on the floor
        if workspace:FindFirstChild("Equipment") then
            for _, v in ipairs(workspace.Equipment:GetDescendants()) do
                if v:IsA("TextLabel") and v.Text:find("%-") and v.Text:find("°") then
                    return true
                end
            end
        end
        
        -- Thermometer held by any player
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player.Character then
                for _, v in ipairs(player.Character:GetDescendants()) do
                    if v:IsA("TextLabel") and v.Text:find("%-") and v.Text:find("°") then
                        return true
                    end
                end
            end
        end
        
        return false
    end
    
    if checkFreezing() then
        addEvidence("Freezing Temperature")
    end
    
    -- 2.4 Check for Rising Flames (Huge Candle Flame)
    local function checkCandle(parent)
        if not parent then return end
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("Model") and v.Name == "Candle" then
                for _, p in ipairs(v:GetDescendants()) do
                    if p:IsA("ParticleEmitter") then
                        -- Normal size is around 0.04. If it's much larger, it's Rising Flames!
                        if p.Size.Keypoints[1].Value > 0.1 then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end
    
    if checkCandle(workspace.Equipment) or checkCandle(game.Players.LocalPlayer.Character) then
        addEvidence("Rising Flames")
    end
    
    -- 2.5 Check for Ghost Writing
    local function checkGhostWriting(parent)
        if not parent then return end
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("Model") and (v.Name == "Book" or v.Name == "Ghost Writing Book") then
                for _, page in ipairs({"RightPage", "LeftPage"}) do
                    if v:FindFirstChild(page) then
                        for _, c in ipairs(v[page]:GetChildren()) do
                            if c:IsA("Decal") or c:IsA("Texture") then
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end
    
    if checkGhostWriting(workspace.Equipment) or checkGhostWriting(game.Players.LocalPlayer.Character) then
        addEvidence("Writing")
    end
    
    -- 2.6 Find Spirit Box Responses
    local function checkSpiritBox(parent)
        if not parent then return end
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("Model") and (v.Name == "Spirit Box" or v.Name == "SpiritBox") then
                local msg = v:FindFirstChild("Message", true)
                if msg and msg:IsA("TextLabel") and msg.Text ~= "" and msg.Text ~= "..." and not msg.Text:lower():find("search") and not msg.Text:lower():find("nothing") then
                    return true
                end
            end
        end
        return false
    end
    
    if checkSpiritBox(workspace.Equipment) or checkSpiritBox(game.Players.LocalPlayer.Character) then
        addEvidence("Spirit Box")
    end
    
    -- 3. Find Cursed Items & Bone (Ignore invisible spawns)
    if workspace.Map:FindFirstChild("PossessionSpawns") then
        for _, item in ipairs(workspace.Map.PossessionSpawns:GetChildren()) do
            if (item:IsA("Model") or item:IsA("BasePart")) and isVisible(item) then
                createHighlight(item, "💀 Cursed: " .. item.Name, Color3.fromRGB(170, 0, 255))
            end
        end
    end
    if workspace.Map:FindFirstChild("BoneSpawns") then
        for _, bone in ipairs(workspace.Map.BoneSpawns:GetChildren()) do
            if (bone:IsA("BasePart") or bone:IsA("Model")) and isVisible(bone) then
                createHighlight(bone, "🦴 BONE", Color3.fromRGB(255, 255, 0))
            end
        end
    end
    
    -- 4. Find Fusebox
    if workspace.Map:FindFirstChild("Fusebox") then
        createHighlight(workspace.Map.Fusebox, "⚡ BREAKER", Color3.fromRGB(0, 255, 0))
    end
    
    -- 5. Find Equipment (Dropped & Van)
    for _, eq in ipairs(workspace.Equipment:GetChildren()) do
        if eq:IsA("Model") then
            createHighlight(eq, "🔧 " .. eq.Name, Color3.fromRGB(200, 200, 200))
        end
    end
    if workspace:FindFirstChild("Van") and workspace.Van:FindFirstChild("Equipment") then
        for _, eq in ipairs(workspace.Van.Equipment:GetChildren()) do
            if eq:IsA("Model") then
                createHighlight(eq, "🔧 " .. eq.Name, Color3.fromRGB(200, 200, 200))
            end
        end
    end
    
    -- 6. Read Objectives & Ghost Name from Whiteboard
    local objText = "📝 OBJECTIVES:\n"
    local ghostName = "Unknown"
    local whiteboard = workspace:FindFirstChild("Van") and workspace.Van:FindFirstChild("Objectives")
    if whiteboard and whiteboard:FindFirstChild("SurfaceGui") and whiteboard.SurfaceGui:FindFirstChild("Frame") and whiteboard.SurfaceGui.Frame:FindFirstChild("Objectives") then
        local objFolder = whiteboard.SurfaceGui.Frame.Objectives
        
        -- Get Name
        if objFolder:FindFirstChild("GhostInfo") then
            local rawHtml = objFolder.GhostInfo.Text
            -- Strip HTML: The ghost's name is<b> <font color="#aa0000">Austin Silva</font> </b>
            local extractedName = string.match(rawHtml, "\">([^<]+)</font>")
            if extractedName then
                ghostName = extractedName
            end
        end
        
        -- Get Objectives
        for i = 1, 4 do
            local label
            if i == 1 then label = objFolder:FindFirstChild("Identify")
            else label = objFolder:FindFirstChild(tostring(i-1)) end
            
            if label and label:IsA("TextLabel") then
                objText = objText .. label.Text .. "\n"
            end
        end
    end
    
    -- New Round Detection
    if ghostName ~= "Unknown" and ghostName ~= Specter.CurrentGhostName then
        Specter.CurrentGhostName = ghostName
        Specter.EvidenceFound = {} -- Reset evidence on new round
        Specter.AutoSelectedGhost = nil -- Allow auto-select again for new round
    end
    
    -- 7. Ghost Prediction Logic
    local Translations = {
        Jinn = "Bisa bergerak sangat cepat, selalu bergerak secepat mungkin jika saklar listrik mati.",
        Myling = "Hanya mengejar satu orang (tapi lebih cepat) jika lampu mati. Kalau lampu nyala, mengejar siapa saja.",
        Afarit = "Memandangnya saat dia sedang memburu (hunt) akan membuatnya bergerak sangat cepat.",
        Bogey = "Mengincar pemain terlemah. Semakin kuat targetnya, dia semakin cepat.",
        Shade = "Sangat pemalu. Susah dicari petunjuknya dan jarang menyerang jika ada orang berkumpul di dekatnya.",
        Douen = "Suka membanting pintu saat berburu (hunt). Pintu yang dibanting akan macet sebentar.",
        Blair = "Menghindari ruangan yang lampunya menyala. Sangat suka mematikan saklar listrik utama.",
        Demon = "Sangat agresif. Mengabaikan waktu aman, sering menyerang, dan makin cepat saat berburu. Jaga Sanity-mu!",
        Thaye = "Sangat aktif di awal, tapi seiring berjalannya waktu dia semakin lambat dan pasif.",
        Duppy = "Menciptakan kloning palsu di awal perburuan. Jika tersentuh kloningnya, kamu diperlambat permanen.",
        Mare = "Sangat cepat saat memburu di tempat gelap. Pastikan saklar listrik nyala atau bawa sumber cahaya.",
        Wendigo = "Bergerak semakin cepat jika Sanity (Kewarasan) kamu semakin rendah.",
        Poltergeist = "Suka melempar banyak barang sekaligus dan sering berinteraksi dengan benda.",
        Preta = "Akan bergerak semakin lambat jika semakin banyak anggota timmu yang sudah mati.",
        Spirit = "Hantu standar biasa. Tidak punya kekuatan atau sifat spesial.",
        Aswang = "Memilih mangsa yang lemah, akan mengincar pemain dengan Sanity paling rendah.",
        Egui = "Mengincar pemain yang pegang alat bukti (Buku, Spirit Box, Kacamata). Jika tidak ada, dia menyerang acak.",
        Banshee = "Memburu mangsanya satu per satu. Lebih sering mengeluarkan suara bising (menangis).",
        Yokai = "Sensitif terhadap barang elektronik. Semakin banyak alat menyala di dekatnya, dia makin agresif.",
        Wraith = "Bisa teleportasi! Jika terlalu lama mengejar satu orang, dia bisa pindah mengejar orang lain.",
        Revenant = "Jika melihatmu langsung, dia lari super cepat. Jika tidak melihatmu, dia lambat.",
        Bhuta = "Tertarik pada elektronik. Jika dikejar, diam & matikan alat dari jarak aman. Dia akan mencari target lain.",
        Yurei = "Menguras Sanity (Kewarasan) pemain jauh lebih cepat dari hantu lain.",
        Haint = "Jangan palingkan pandanganmu darinya! Jika tidak dilihat, dia melesat sangat cepat.",
        Mimic = "Hantu peniru! Setelah 2 menit, dia meniru sifat dan kekuatan hantu lain secara permanen.",
        Wisp = "Semakin cepat di tempat terang atau terkena senter/lilin. Sering menyalakan lampu untuk menjebak korban.",
        Phantom = "Menatapnya saat memburu akan menguras Sanity-mu drastis. Sering muncul dari Papan Ouija.",
        Oni = "Suka menakut-nakuti. Sering memunculkan kejadian mistis dan melempar barang, terutama saat berburu.",
        Upyr = "Semakin banyak pemain yang dia bunuh, dia akan menjadi semakin cepat dan ganas.",
        ["O Tokata"] = "Mengobrol (Voice Chat) di dekat O Tokata yang sedang berkeliaran bisa membuatnya langsung marah (hunt)."
    }
    
    -- 8. Update UI
    if Specter.UI and Specter.UI:FindFirstChild("Panel") and Specter.UI.Panel:FindFirstChild("BodyText") then
        local finalUIText = "📛 GHOST NAME: " .. ghostName .. "\n\n"
        
        if #Specter.EvidenceFound > 0 then
            finalUIText = finalUIText .. "🔍 EVIDENCE DETECTED:\n" .. table.concat(Specter.EvidenceFound, "\n") .. "\n\n"
        else
            finalUIText = finalUIText .. "🔍 EVIDENCE DETECTED:\nNone yet...\n\n"
        end
        
        -- Generate Possible Ghosts list based on EvidenceFound
        local possibleGhosts = {}
        for gName, gEvidences in pairs(EvidencesData.Ghosts) do
            local isValid = true
            for _, foundEv in ipairs(Specter.EvidenceFound) do
                local foundMatch = false
                for _, reqEv in ipairs(gEvidences) do
                    if string.find(reqEv:lower(), foundEv:lower()) or string.find(foundEv:lower(), reqEv:lower()) or (foundEv == "Freezing" and reqEv:find("Freezing")) then
                        foundMatch = true
                        break
                    end
                end
                if not foundMatch then
                    isValid = false
                    break
                end
            end
            if isValid then
                table.insert(possibleGhosts, gName)
            end
        end
        
        -- Auto-Select Ghost if only 1 is left and JournalController is available
        pcall(function()
            if JournalController and EvidencesData then
                local validGhostsJournal = {}
                for gName, _ in pairs(EvidencesData.Ghosts) do
                    if not table.find(JournalController.InvalidGhosts, gName) then
                        table.insert(validGhostsJournal, gName)
                    end
                end
                
                if #validGhostsJournal == 1 then
                    local targetGhost = validGhostsJournal[1]
                    if Specter.AutoSelectedGhost ~= targetGhost then
                        Specter.AutoSelectedGhost = targetGhost
                        if JournalController.SelectedGhost ~= targetGhost then
                            JournalController:GhostClicked(targetGhost)
                        end
                    end
                end
            end
        end)
        
        finalUIText = finalUIText .. objText .. "\n"
        
        finalUIText = finalUIText .. "👻 POSSIBLE GHOSTS (" .. #possibleGhosts .. "):\n"
        if #possibleGhosts == 0 then
            finalUIText = finalUIText .. "None (Evidence Error?)\n"
        elseif #possibleGhosts <= 3 then
            for _, gName in ipairs(possibleGhosts) do
                local desc = Translations[gName]
                if not desc then
                    if EvidencesData and EvidencesData.GhostDescs and EvidencesData.GhostDescs[gName] then
                        desc = EvidencesData.GhostDescs[gName]
                    else
                        desc = "No info."
                    end
                    desc = desc:gsub("<[^>]+>", "")
                end
                finalUIText = finalUIText .. "- <font color='#aaffaa'><b>" .. gName .. "</b></font>: " .. desc .. "\n"
            end
        else
            finalUIText = finalUIText .. table.concat(possibleGhosts, ", ")
        end
        
        Specter.UI.Panel.BodyText.Text = finalUIText
        Specter.UI.Panel.BodyText.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

if _G.SpecterLoop then
    task.cancel(_G.SpecterLoop)
end

if _G.SpecterGui then
    _G.SpecterGui:Destroy()
end

-- Create UI Panel
local gui = Instance.new("ScreenGui")
gui.Name = "SpecterSolverGUI"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui
_G.SpecterGui = gui
Specter.UI = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 400, 0, 450)
panel.Position = UDim2.new(0, 20, 0, 200) -- Left side of screen
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "👻 SPECTER SOLVER PRO"
title.TextColor3 = Color3.fromRGB(255, 0, 100)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = panel

local text = Instance.new("TextLabel")
text.Name = "BodyText"
text.Size = UDim2.new(1, -20, 1, -40)
text.Position = UDim2.new(0, 10, 0, 35)
text.BackgroundTransparency = 1
text.Text = "Loading..."
text.TextColor3 = Color3.fromRGB(255, 255, 255)
text.TextXAlignment = Enum.TextXAlignment.Left
text.TextYAlignment = Enum.TextYAlignment.Top
text.Font = Enum.Font.Gotham
text.TextSize = 13
text.TextWrapped = true
text.RichText = true
text.Parent = panel

_G.SpecterLoop = task.spawn(function()
    while task.wait(1) do
        pcall(scanSpecter)
    end
end)

print("Specter Solver Loaded with UI!")
