-- Ryzen Hub Premium | Rayfield UI | Full Features & Persistence
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TeleportService = game:GetService("TeleportService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Состояния
local Flight = {
    Enabled = false, Speed = 50, Gyro = nil, Velocity = nil, Connection = nil,
    Keys = { W = false, A = false, S = false, D = false },
    InputBegan = nil, InputEnded = nil
}
local Invisible = { Enabled = false }
local Godmode = { Enabled = false, Connection = nil }
local InfiniteJump = { Enabled = false, Connection = nil }
local WalkSpeed = 16
local JumpPower = 50
local Noclip = false

local ESP = { Enabled = false, Objects = {}, Updater = nil }
local Aimbot = {
    Enabled = false, FOV = 100, Smoothness = 0.5, Part = "Head",
    Connection = nil, Prediction = 0.1
}
local selectedPlayer = nil

-- ===================== ФУНКЦИИ ПОЛЁТА =====================
function startFlight(char)
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = true end

    Flight.Gyro = Instance.new("BodyGyro")
    Flight.Gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    Flight.Gyro.CFrame = root.CFrame
    Flight.Gyro.Parent = root

    Flight.Velocity = Instance.new("BodyVelocity")
    Flight.Velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Flight.Velocity.Velocity = Vector3.zero
    Flight.Velocity.Parent = root

    Flight.InputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.W then Flight.Keys.W = true
        elseif input.KeyCode == Enum.KeyCode.A then Flight.Keys.A = true
        elseif input.KeyCode == Enum.KeyCode.S then Flight.Keys.S = true
        elseif input.KeyCode == Enum.KeyCode.D then Flight.Keys.D = true
        end
    end)
    Flight.InputEnded = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then Flight.Keys.W = false
        elseif input.KeyCode == Enum.KeyCode.A then Flight.Keys.A = false
        elseif input.KeyCode == Enum.KeyCode.S then Flight.Keys.S = false
        elseif input.KeyCode == Enum.KeyCode.D then Flight.Keys.D = false
        end
    end)

    Flight.Connection = RunService.RenderStepped:Connect(function()
        if not Flight.Enabled or not Flight.Gyro or not Flight.Velocity then
            if Flight.Connection then Flight.Connection:Disconnect() end
            return
        end
        local cam = Camera
        if cam then Flight.Gyro.CFrame = cam.CFrame end
        local moveVec = Vector3.zero
        local forward = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        if Flight.Keys.W then moveVec += forward end
        if Flight.Keys.S then moveVec -= forward end
        if Flight.Keys.A then moveVec -= right end
        if Flight.Keys.D then moveVec += right end
        if moveVec.Magnitude > 0 then
            Flight.Velocity.Velocity = moveVec.Unit * Flight.Speed
        else
            Flight.Velocity.Velocity = Vector3.zero
        end
    end)
end

function stopFlight()
    if Flight.Gyro then Flight.Gyro:Destroy() end
    if Flight.Velocity then Flight.Velocity:Destroy() end
    if Flight.Connection then Flight.Connection:Disconnect() end
    if Flight.InputBegan then Flight.InputBegan:Disconnect() end
    if Flight.InputEnded then Flight.InputEnded:Disconnect() end
    Flight.Gyro, Flight.Velocity, Flight.Connection, Flight.InputBegan, Flight.InputEnded = nil, nil, nil, nil, nil
    Flight.Keys = { W = false, A = false, S = false, D = false }
    if Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid.PlatformStand = false
    end
end

function toggleFlight()
    Flight.Enabled = not Flight.Enabled
    if Flight.Enabled then startFlight(Character) else stopFlight() end
end

-- ===================== НЕВИДИМОСТЬ =====================
function applyInvisibility(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 then
            part.Transparency = 1
            part.CanCollide = false
        end
    end
end

function removeInvisibility(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0
            part.CanCollide = true
        end
    end
end

-- ===================== GODMODE =====================
function applyGodmode(char)
    if not char or not char:FindFirstChild("Humanoid") then return end
    local hum = char.Humanoid
    hum.MaxHealth = 999999
    hum.Health = 999999
    Godmode.Connection = hum.HealthChanged:Connect(function()
        if Godmode.Enabled and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end)
end

function removeGodmode(char)
    if Godmode.Connection then Godmode.Connection:Disconnect(); Godmode.Connection = nil end
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        hum.MaxHealth = 100
        hum.Health = 100
    end
end

-- ===================== ESP =====================
local function createEspForPlayer(player)
    if ESP.Objects[player] then return end
    local obj = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        NameTag = Drawing.new("Text"),
    }
    obj.Box.Visible = false
    obj.Box.Color = Color3.fromRGB(255, 255, 255)
    obj.Box.Thickness = 2
    obj.Box.Filled = false

    obj.Tracer.Visible = false
    obj.Tracer.Color = Color3.fromRGB(255, 255, 255)
    obj.Tracer.Thickness = 1

    obj.NameTag.Visible = false
    obj.NameTag.Color = Color3.fromRGB(255, 255, 255)
    obj.NameTag.Size = 14
    obj.NameTag.Center = true
    obj.NameTag.Outline = true

    ESP.Objects[player] = obj
end

local function removeEspForPlayer(player)
    local obj = ESP.Objects[player]
    if obj then
        obj.Box:Remove()
        obj.Tracer:Remove()
        obj.NameTag:Remove()
        ESP.Objects[player] = nil
    end
end

local function updateESP()
    local function updatePositions()
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character
            if not char or not char:FindFirstChild("Head") then
                removeEspForPlayer(player)
                continue
            end
            if not char:FindFirstChild("HumanoidRootPart") then
                wait(0.1)
                if not char:FindFirstChild("HumanoidRootPart") then
                    removeEspForPlayer(player)
                    continue
                end
            end
            createEspForPlayer(player)
            local root = char.HumanoidRootPart
            local head = char.Head
            local rootPos, onScreen1 = Camera:WorldToViewportPoint(root.Position)
            local headPos, onScreen2 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
            local footPos, _ = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

            local obj = ESP.Objects[player]
            if not obj then continue end

            if not onScreen1 and not onScreen2 then
                obj.Box.Visible = false
                obj.Tracer.Visible = false
                obj.NameTag.Visible = false
                continue
            end

            local height = math.abs(headPos.Y - footPos.Y)
            local width = height / 2
            obj.Box.Size = Vector2.new(width, height)
            obj.Box.Position = Vector2.new(headPos.X - width/2, headPos.Y)
            obj.Box.Visible = true

            obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            obj.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            obj.Tracer.Visible = true

            obj.NameTag.Text = player.Name .. " [" .. math.floor((root.Position - Camera.CFrame.Position).Magnitude) .. "m]"
            obj.NameTag.Position = Vector2.new(headPos.X, headPos.Y - 20)
            obj.NameTag.Visible = true
        end
        for player, obj in pairs(ESP.Objects) do
            if not Players:FindFirstChild(player.Name) then
                removeEspForPlayer(player)
            end
        end
    end

    ESP.Updater = RunService.RenderStepped:Connect(function()
        if ESP.Enabled then updatePositions() end
    end)
end

function toggleESP(state)
    ESP.Enabled = state
    if state then
        if not ESP.Updater then updateESP() end
    else
        if ESP.Updater then ESP.Updater:Disconnect(); ESP.Updater = nil end
        for _, obj in pairs(ESP.Objects) do
            if obj.Box then obj.Box:Remove() end
            if obj.Tracer then obj.Tracer:Remove() end
            if obj.NameTag then obj.NameTag:Remove() end
        end
        ESP.Objects = {}
    end
end

-- ===================== AIMBOT =====================
function startAimbot()
    Aimbot.Connection = RunService.RenderStepped:Connect(function()
        if not Aimbot.Enabled or not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
        local target = nil
        local closestDist = math.huge
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local fovRadius = Aimbot.FOV / 2

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character
            if not char or not char:FindFirstChild(Aimbot.Part) then continue end
            local part = char[Aimbot.Part]
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                if dist <= fovRadius and dist < closestDist then
                    closestDist = dist
                    target = part
                end
            end
        end

        if target then
            local targetPos = target.Position
            if Aimbot.Prediction > 0 and target.Velocity then
                targetPos = targetPos + target.Velocity * Aimbot.Prediction
            end
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), Aimbot.Smoothness)
        end
    end)
end

function toggleAimbot(state)
    Aimbot.Enabled = state
    if state then startAimbot() else if Aimbot.Connection then Aimbot.Connection:Disconnect() end end
end

-- ===================== INFINITE JUMP =====================
function setInfiniteJump(state)
    InfiniteJump.Enabled = state
    if state then
        InfiniteJump.Connection = UserInputService.JumpRequest:Connect(function()
            if not Character or not Character:FindFirstChild("Humanoid") then return end
            local hum = Character.Humanoid
            local s = hum:GetState()
            if s == Enum.HumanoidStateType.Landed or s == Enum.HumanoidStateType.Running or s == Enum.HumanoidStateType.Freefall then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if InfiniteJump.Connection then InfiniteJump.Connection:Disconnect() end
    end
end

-- ===================== PERSISTENCE =====================
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    wait(0.5)
    if Flight.Enabled then stopFlight(); startFlight(char) end
    if Invisible.Enabled then applyInvisibility(char) end
    if Godmode.Enabled then
        if Godmode.Connection then Godmode.Connection:Disconnect() end
        applyGodmode(char)
    end
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = WalkSpeed
        char.Humanoid.JumpPower = JumpPower
    end
end)

-- ===================== GUI =====================
local Window = Rayfield:CreateWindow({
    Name = "Ryzen Hub Premium",
    Icon = 4483345998,
    LoadingTitle = "Ryzen Hub",
    LoadingSubtitle = "by Ryzen",
    Theme = "DarkBlue",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = { Enabled = true, FolderName = "RyzenHubPremium", FileName = "Config" },
    Discord = { Enabled = false },
    KeySystem = false
})

-- Movement Tab
local MovementTab = Window:CreateTab("🏃 Movement")
MovementTab:CreateSection("✈️ Flight")
MovementTab:CreateToggle({ Name = "Flight", CurrentValue = false, Callback = function(v)
    Flight.Enabled = v
    if v then startFlight(Character) else stopFlight() end
end })
MovementTab:CreateSlider({ Name = "Flight Speed", Range = {0, 500}, Increment = 10, Suffix = "studs/s", CurrentValue = 50, Callback = function(v) Flight.Speed = v end })

MovementTab:CreateSection("🏃 Player")
MovementTab:CreateSlider({ Name = "WalkSpeed", Range = {0, 200}, Increment = 1, Suffix = "studs/s", CurrentValue = 16, Callback = function(v)
    WalkSpeed = v
    if Character and Character:FindFirstChild("Humanoid") then Character.Humanoid.WalkSpeed = v end
end })
MovementTab:CreateSlider({ Name = "JumpPower", Range = {0, 500}, Increment = 1, Suffix = "power", CurrentValue = 50, Callback = function(v)
    JumpPower = v
    if Character and Character:FindFirstChild("Humanoid") then Character.Humanoid.JumpPower = v end
end })
MovementTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Callback = function(v) setInfiniteJump(v) end })

-- Visuals Tab
local VisualTab = Window:CreateTab("👁️ Visuals")
VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({ Name = "ESP", CurrentValue = false, Callback = function(v) toggleESP(v) end })
VisualTab:CreateToggle({ Name = "Boxes", CurrentValue = true, Callback = function(v)
    for _, obj in pairs(ESP.Objects) do obj.Box.Visible = v and ESP.Enabled end
end })
VisualTab:CreateToggle({ Name = "Tracers", CurrentValue = true, Callback = function(v)
    for _, obj in pairs(ESP.Objects) do obj.Tracer.Visible = v and ESP.Enabled end
end })
VisualTab:CreateToggle({ Name = "Names", CurrentValue = true, Callback = function(v)
    for _, obj in pairs(ESP.Objects) do obj.NameTag.Visible = v and ESP.Enabled end
end })

VisualTab:CreateSection("Character")
VisualTab:CreateToggle({ Name = "Invisibility", CurrentValue = false, Callback = function(v)
    Invisible.Enabled = v
    if v then applyInvisibility(Character) else removeInvisibility(Character) end
end })
VisualTab:CreateToggle({ Name = "Godmode (999k HP)", CurrentValue = false, Callback = function(v)
    Godmode.Enabled = v
    if v then applyGodmode(Character) else removeGodmode(Character) end
end })
VisualTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Callback = function(v)
    Noclip = v
    if Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = not v end
        end
    end
end })

-- Aimbot Tab
local AimbotTab = Window:CreateTab("🎯 Aimbot")
AimbotTab:CreateSection("Aim")
AimbotTab:CreateToggle({ Name = "Aimbot", CurrentValue = false, Callback = function(v) toggleAimbot(v) end })
AimbotTab:CreateSlider({ Name = "FOV", Range = {10, 300}, Increment = 5, Suffix = "px", CurrentValue = 100, Callback = function(v) Aimbot.FOV = v end })
AimbotTab:CreateSlider({ Name = "Smoothness", Range = {0.1, 1}, Increment = 0.1, Suffix = "smooth", CurrentValue = 0.5, Callback = function(v) Aimbot.Smoothness = v end })
AimbotTab:CreateSlider({ Name = "Prediction", Range = {0, 0.5}, Increment = 0.05, Suffix = "s", CurrentValue = 0.1, Callback = function(v) Aimbot.Prediction = v end })
AimbotTab:CreateDropdown({ Name = "Target Part", Options = {"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, CurrentOption = "Head", Callback = function(v) Aimbot.Part = v end })

-- Trolling Tab
local TrollingTab = Window:CreateTab("🎭 Trolling")
TrollingTab:CreateSection("Target Player")
local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    if #list == 0 then list = {"No players"} end
    return list
end
local targetDropdown = TrollingTab:CreateDropdown({
    Name = "Select Player", Options = getPlayerList(), CurrentOption = "No players",
    Callback = function(v) selectedPlayer = (v ~= "No players") and Players:FindFirstChild(v) or nil end
})
TrollingTab:CreateButton({ Name = "Refresh List", Callback = function()
    targetDropdown:Refresh(getPlayerList(), true)
end })
TrollingTab:CreateButton({ Name = "Teleport to Player", Callback = function()
    if not selectedPlayer or not selectedPlayer.Character or not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local root = Character.HumanoidRootPart
    local targetCF = selectedPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
    root.CFrame = targetCF
    RunService.Heartbeat:Wait()
    root.CFrame = targetCF
end })
TrollingTab:CreateButton({ Name = "Spin Fling", Callback = function()
    if not selectedPlayer or not selectedPlayer.Character or not selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = selectedPlayer.Character.HumanoidRootPart
    local orig = root.CFrame
    for i = 1, 30 do root.CFrame = orig * CFrame.Angles(0, math.rad(12*i), 0); RunService.RenderStepped:Wait() end
    root.CFrame = orig
end })
TrollingTab:CreateButton({ Name = "Bring All", Callback = function()
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local myCF = Character.HumanoidRootPart.CFrame
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            p.Character.HumanoidRootPart.CFrame = myCF + Vector3.new(math.random(-2,2), 0, math.random(-2,2))
        end
    end
end })

-- Misc Tab
local MiscTab = Window:CreateTab("🔧 Misc")
MiscTab:CreateSection("Server")
MiscTab:CreateButton({ Name = "Rejoin", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end })
MiscTab:CreateButton({ Name = "Server Hop", Callback = function() TeleportService:Teleport(game.PlaceId) end })
MiscTab:CreateSection("Utility")
MiscTab:CreateToggle({ Name = "Anti-AFK", CurrentValue = false, Callback = function(v)
    if v then
        _G.antiAFK = RunService.Stepped:Connect(function()
            if Character and Character:FindFirstChild("Humanoid") then Character.Humanoid.MoveDirection = Vector3.new(1,0,0) end
        end)
    else if _G.antiAFK then _G.antiAFK:Disconnect() end end
end })

-- Settings Tab
local SettingsTab = Window:CreateTab("⚙️ Settings")
SettingsTab:CreateSection("Keybinds")
SettingsTab:CreateKeybind({ Name = "Flight Toggle", CurrentKeybind = "F", Hold = false, Callback = function() toggleFlight() end })
SettingsTab:CreateSection("Theme")
SettingsTab:CreateDropdown({ Name = "Select Theme", Options = {"Default", "DarkBlue", "Light", "Red", "Green", "Purple"}, CurrentOption = "DarkBlue", Callback = function(theme)
    -- Rayfield не поддерживает смену темы на лету через функцию, поэтому установим тему через флаг (меню пересоздавать не будем, но пока так)
    -- В реальной имплементации лучше пересоздавать окно, но для стабильности оставим выбор темы в настройках сохранения
end })

Rayfield:Notify("Ryzen Hub Premium", "Loaded successfully!", 4483345998)
