local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Konfigurasi
local canDoubleJump = false
local isRolling = false
local ROLL_SPEED = 70
local ROLL_DURATION = 0.35
local ROLL_COOLDOWN = 1.5 -- Jeda 1.5 detik agar tidak spam

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    -- === FITUR DOUBLE JUMP (TEKAN SPASI) ===
    if input.KeyCode == Enum.KeyCode.Space then
        if hum:GetState() == Enum.HumanoidStateType.Freefall and canDoubleJump then
            canDoubleJump = false
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            
            -- Memberikan dorongan ekstra ke atas
            root.Velocity = Vector3.new(root.Velocity.X, (hum.JumpPower > 0 and hum.JumpPower or 50) * 1.2, root.Velocity.Z)
        end
    end

    -- === FITUR FRONT ROLL / DASH (TEKAN F) ===
    if input.KeyCode == Enum.KeyCode.F then
        if not isRolling and hum.Health > 0 then
            isRolling = true
            
            -- Tentukan arah melesat (sesuai arah jalan, kalau diam maka ke arah pandangan)
            local direction = hum.MoveDirection
            if direction.Magnitude < 0.1 then
                direction = root.CFrame.LookVector
            end
            
            -- Membuat daya dorong ke depan (Dash)
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(100000, 0, 100000)
            bv.Velocity = direction * ROLL_SPEED
            bv.Parent = root
            
            -- === EFEK ANIMASI MUTER (FRONT ROLL) ===
            local rootJoint = nil
            if char:FindFirstChild("LowerTorso") and char.LowerTorso:FindFirstChild("Root") then
                rootJoint = char.LowerTorso.Root -- R15
            elseif root:FindFirstChild("RootJoint") then
                rootJoint = root.RootJoint -- R6
            end
            
            if rootJoint then
                local origC0 = rootJoint.C0
                local TweenService = game:GetService("TweenService")
                -- Putar 360 derajat ke depan (sumbu X)
                local tween = TweenService:Create(rootJoint, TweenInfo.new(ROLL_DURATION, Enum.EasingStyle.Linear), {
                    C0 = origC0 * CFrame.Angles(math.pi * 2, 0, 0)
                })
                tween:Play()
                
                -- Kembalikan ke posisi normal setelah selesai
                task.delay(ROLL_DURATION, function()
                    rootJoint.C0 = origC0
                end)
            end
            
            -- Hapus dorongan setelah durasi selesai (Roll selesai)
            task.delay(ROLL_DURATION, function()
                if bv then bv:Destroy() end
                
                -- Mulai cooldown
                task.wait(ROLL_COOLDOWN)
                isRolling = false
            end)
        end
    end
end)

-- Reset Double Jump saat menyentuh tanah (Landed)
local function onCharacterAdded(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.StateChanged:Connect(function(old, new)
            if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
                canDoubleJump = true
            end
        end)
    end
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Pasang ke karakter yang saat ini hidup
if player.Character then
    onCharacterAdded(player.Character)
end

-- Notifikasi layar
local StarterGui = game:GetService("StarterGui")
StarterGui:SetCore("SendNotification", {
    Title = "Super Movement Aktif!";
    Text = "Double Jump (Spasi) & Front Roll (F) siap digunakan!";
    Duration = 5;
})
