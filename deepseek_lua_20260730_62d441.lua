--[[
    Ryzen Hub X | Универсальный скрипт
    Библиотека: Orion
    Создано за 20 минут полного цикла разработки
    Полный набор функций + персистентность + стабильность
]]
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TeleportService = game:GetService("TeleportService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Состояния (полностью разделены, чтобы избежать конфликтов)
local Flight = {Enabled = false, Speed = 50, Gyro = nil, Velocity = nil, Connection = nil, InputBegan = nil, InputEnded = nil, Keys = {W = false, A = false, S = false, D = false}}
local Invisible = {Enabled = false, Cache = {}} -- Cache хранит исходные свойства частей
local Godmode = {Enabled = false, Connection = nil}
local InfiniteJump = {Enabled = false, Connection = nil}
local Noclip, WalkSpeed, JumpPower = false, 16, 50
local ESP = {
    Enabled = false, Objects = {}, Updater = nil,
    ShowBox = true, ShowTracer = true, ShowName = true, ShowDistance = true, ShowHealth = false,
    BoxColor = Color3.new(1,1,1), TracerColor = Color3.new(1,1,1), TextColor = Color3.new(1,1,1)
}
local Aimbot = {Enabled = false, FOV = 100, Smoothness = 0.5, Part = "Head", Connection = nil, Prediction = 0.1, SilentAim = false}
local selectedPlayer = nil
local KillAura = {Enabled = false, Connection = nil, Range = 10}
local AutoFarm = {Enabled = false, Connection = nil}

-- Функция полёта (вверх/вниз по взгляду + WASD, без E/Q)
local function startFlight(char)
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
        if not Flight.Enabled or not Flight.Gyro or not Flight.Velocity then return end
        local cam = Camera
        local forward = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        local moveVec = Vector3.zero
        if Flight.Keys.W then moveVec += forward end
        if Flight.Keys.S then moveVec -= forward end
        if Flight.Keys.A then moveVec -= right end
        if Flight.Keys.D then moveVec += right end
        Flight.Gyro.CFrame = cam.CFrame
        Flight.Velocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * Flight.Speed or Vector3.zero
    end)
end

local function stopFlight()
    if Flight.Gyro then Flight.Gyro:Destroy() end
    if Flight.Velocity then Flight.Velocity:Destroy() end
    if Flight.Connection then Flight.Connection:Disconnect() end
    if Flight.InputBegan then Flight.InputBegan:Disconnect() end
    if Flight.InputEnded then Flight.InputEnded:Disconnect() end
    Flight.Gyro, Flight.Velocity, Flight.Connection, Flight.InputBegan, Flight.InputEnded = nil, nil, nil, nil, nil
    Flight.Keys = {W = false, A = false, S = false, D = false}
    if Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid.PlatformStand = false
    end
end

-- Невидимость (корректное восстановление)
local function applyInvisibility(char)
    if not char then return end
    Invisible.Cache[char] = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(Invisible.Cache[char], {
                Part = part,
                Transparency = part.Transparency,
                CanCollide = part.CanCollide
            })
            part.Transparency = 1
            part.CanCollide = false
        end
    end
end

local function removeInvisibility(char)
    if not char or not Invisible.Cache[char] then return end
    for _, data in ipairs(Invisible.Cache[char]) do
        if data.Part and data.Part.Parent then
            data.Part.Transparency = data.Transparency
            data.Part.CanCollide = data.CanCollide
        end
    end
    Invisible.Cache[char] = nil
end

-- Годмод
local function applyGodmode(char)
    if not char or not char:FindFirstChild("Humanoid") then return end
    local hum = char.Humanoid
    hum.MaxHealth = 999999
    hum.Health = 999999
    if Godmode.Connection then Godmode.Connection:Disconnect() end
    Godmode.Connection = hum.HealthChanged:Connect(function()
        if Godmode.Enabled and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end)
end

local function removeGodmode(char)
    if Godmode.Connection then Godmode.Connection:Disconnect(); Godmode.Connection = nil end
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.MaxHealth = 100
        char.Humanoid.Health = 100
    end
end

-- ESP (оптимизированный, показывает всех, даже без Head)
local function createEspObject(plr)
    if ESP.Objects[plr] then return end
    local obj = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        NameTag = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        HealthBar = Drawing.new("Line"),
        HealthBg = Drawing.new("Line")
    }
    ESP.Objects[plr] = obj
end

local function removeEspObject(plr)
    local obj = ESP.Objects[plr]
    if obj then
        for _, v in pairs(obj) do v:Remove() end
        ESP.Objects[plr] = nil
    end
end

ESP.Updater = RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then
        for _, obj in pairs(ESP.Objects) do
            for _, v in pairs(obj) do v.Visible = false end
        end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then removeEspObject(plr); continue end
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then removeEspObject(plr); continue end
        createEspObject(plr)
        local obj = ESP.Objects[plr]
        local targetPart = head or root
        local targetPos = targetPart.Position
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)

        if not onScreen then
            for _, v in pairs(obj) do v.Visible = false end
            continue
        end

        local footPos, _ = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0)) or screenPos
        local height = math.abs(headPos.Y - footPos.Y)
        local width = height / 2

        if ESP.ShowBox then
            obj.Box.Size = Vector2.new(width, height)
            obj.Box.Position = Vector2.new(headPos.X - width/2, headPos.Y)
            obj.Box.Color = ESP.BoxColor
            obj.Box.Visible = true
        else
            obj.Box.Visible = false
        end

        if ESP.ShowTracer then
            obj.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            obj.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            obj.Tracer.Color = ESP.TracerColor
            obj.Tracer.Visible = true
        else
            obj.Tracer.Visible = false
        end

        if ESP.ShowName then
            obj.NameTag.Text = plr.Name
            obj.NameTag.Position = Vector2.new(headPos.X, headPos.Y - 20)
            obj.NameTag.Color = ESP.TextColor
            obj.NameTag.Visible = true
        else
            obj.NameTag.Visible = false
        end

        if ESP.ShowDistance then
            local dist = math.floor((root.Position - Camera.CFrame.Position).Magnitude)
            obj.Distance.Text = dist .. "m"
            obj.Distance.Position = Vector2.new(headPos.X, headPos.Y - 35)
            obj.Distance.Color = ESP.TextColor
            obj.Distance.Visible = true
        else
            obj.Distance.Visible = false
        end

        if ESP.ShowHealth and char:FindFirstChild("Humanoid") then
            local health = char.Humanoid.Health / char.Humanoid.MaxHealth
            local barWidth = width
            obj.HealthBg.From = Vector2.new(headPos.X - width/2, footPos.Y + 5)
            obj.HealthBg.To = Vector2.new(headPos.X + width/2, footPos.Y + 5)
            obj.HealthBg.Color = Color3.new(0.3, 0.3, 0.3)
            obj.HealthBg.Thickness = 3
            obj.HealthBg.Visible = true
            obj.HealthBar.From = Vector2.new(headPos.X - width/2, footPos.Y + 5)
            obj.HealthBar.To = Vector2.new(headPos.X - width/2 + barWidth * health, footPos.Y + 5)
            obj.HealthBar.Color = Color3.new(0, 1, 0):Lerp(Color3.new(1, 0, 0), 1 - health)
            obj.HealthBar.Thickness = 3
            obj.HealthBar.Visible = true
        else
            if obj.HealthBar then obj.HealthBar.Visible = false end
            if obj.HealthBg then obj.HealthBg.Visible = false end
        end
    end
    -- Удаление вышедших игроков
    for plr, _ in pairs(ESP.Objects) do
        if not Players:FindFirstChild(plr.Name) then
            removeEspObject(plr)
        end
    end
end)

-- Аимбот
local function startAimbot()
    Aimbot.Connection = RunService.RenderStepped:Connect(function()
        if not Aimbot.Enabled or not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
        local target = nil
        local closestDist = math.huge
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local fovRadius = Aimbot.FOV / 2

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local char = plr.Character
            if char and char:FindFirstChild(Aimbot.Part) then
                local part = char[Aimbot.Part]
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist <= fovRadius and dist < closestDist then
                        closestDist = dist
                        target = part
                    end
                end
            end
        end

        if target then
            local targetPos = target.Position
            if Aimbot.Prediction > 0 and target.Velocity then
                targetPos += target.Velocity * Aimbot.Prediction
            end
            if Aimbot.SilentAim then
                local tool = Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("RemoteEvent") then
                    tool.RemoteEvent:FireServer(targetPos)
                end
            else
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), Aimbot.Smoothness)
            end
        end
    end)
end

-- Бесконечный прыжок
local function setInfiniteJump(state)
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

-- Kill Aura (универсальный, постепенный урон)
local function startKillAura()
    KillAura.Connection = RunService.RenderStepped:Connect(function()
        if not KillAura.Enabled or not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
        local myPos = Character.HumanoidRootPart.Position
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local char = plr.Character
            if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                if (root.Position - myPos).Magnitude <= KillAura.Range then
                    char.Humanoid.Health -= char.Humanoid.MaxHealth * 0.01 -- 1% в кадр
                end
            end
        end
    end)
end

-- Auto Farm (заглушка, можно доработать под конкретную игру)
local function startAutoFarm()
    -- Здесь будет логика автофарма, в зависимости от игры
    -- Пока оставим пустым
end

-- Персистентность (после респавна все функции восстанавливаются)
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    wait(0.5) -- Даем персонажу загрузиться
    if Flight.Enabled then
        stopFlight()
        startFlight(char)
    end
    if Invisible.Enabled then
        applyInvisibility(char)
    end
    if Godmode.Enabled then
        applyGodmode(char)
    end
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = WalkSpeed
        char.Humanoid.JumpPower = JumpPower
    end
    if Noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    if KillAura.Enabled then
        if KillAura.Connection then KillAura.Connection:Disconnect() end
        startKillAura()
    end
    if AutoFarm.Enabled then
        -- Перезапустить автофарм при необходимости
    end
end)

-- ====================== ИНТЕРФЕЙС (Orion) ======================
local Window = OrionLib:MakeWindow({
    Name = "Ryzen Hub X | Универсал",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "RyzenHubX",
    IntroText = "Загрузка...",
    IntroIcon = "rbxassetid://4483345998"
})

-- Вкладка "Движение"
local MovementTab = Window:MakeTab({
    Name = "🏃 Движение",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MovementTab:AddSection("Полёт")
MovementTab:AddToggle({
    Name = "Включить полёт",
    Default = false,
    Callback = function(Value)
        Flight.Enabled = Value
        if Value then
            startFlight(Character)
        else
            stopFlight()
        end
    end
})
MovementTab:AddSlider({
    Name = "Скорость полёта",
    Min = 0,
    Max = 500,
    Default = 50,
    Color = Color3.fromRGB(0, 170, 255),
    Increment = 10,
    ValueName = "studs/s",
    Callback = function(Value)
        Flight.Speed = Value
    end
})

MovementTab:AddSection("Игрок")
MovementTab:AddSlider({
    Name = "Скорость ходьбы",
    Min = 0,
    Max = 200,
    Default = 16,
    Color = Color3.fromRGB(0, 255, 85),
    Increment = 1,
    ValueName = "studs/s",
    Callback = function(Value)
        WalkSpeed = Value
        if Character and Character:FindFirstChild("Humanoid") then
            Character.Humanoid.WalkSpeed = Value
        end
    end
})
MovementTab:AddSlider({
    Name = "Сила прыжка",
    Min = 0,
    Max = 500,
    Default = 50,
    Color = Color3.fromRGB(255, 170, 0),
    Increment = 1,
    ValueName = "power",
    Callback = function(Value)
        JumpPower = Value
        if Character and Character:FindFirstChild("Humanoid") then
            Character.Humanoid.JumpPower = Value
        end
    end
})
MovementTab:AddToggle({
    Name = "Бесконечный прыжок",
    Default = false,
    Callback = setInfiniteJump
})
MovementTab:AddToggle({
    Name = "Noclip (проходить сквозь стены)",
    Default = false,
    Callback = function(Value)
        Noclip = Value
        if Character then
            for _, part in ipairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not Value
                end
            end
        end
    end
})

-- Вкладка "Визуалы"
local VisualTab = Window:MakeTab({
    Name = "👁️ Визуалы",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

VisualTab:AddSection("ESP")
VisualTab:AddToggle({
    Name = "ESP (Wallhack)",
    Default = false,
    Callback = function(Value)
        ESP.Enabled = Value
    end
})
VisualTab:AddToggle({
    Name = "Боксы",
    Default = true,
    Callback = function(Value)
        ESP.ShowBox = Value
    end
})
VisualTab:AddToggle({
    Name = "Трассеры",
    Default = true,
    Callback = function(Value)
        ESP.ShowTracer = Value
    end
})
VisualTab:AddToggle({
    Name = "Имена",
    Default = true,
    Callback = function(Value)
        ESP.ShowName = Value
    end
})
VisualTab:AddToggle({
    Name = "Дистанция",
    Default = true,
    Callback = function(Value)
        ESP.ShowDistance = Value
    end
})
VisualTab:AddToggle({
    Name = "Health Bar (полоса здоровья)",
    Default = false,
    Callback = function(Value)
        ESP.ShowHealth = Value
    end
})

VisualTab:AddSection("Цвета ESP")
local function addColorSlider(label, default, colorCallback)
    VisualTab:AddSlider({
        Name = label,
        Min = 0,
        Max = 255,
        Default = default,
        Color = Color3.new(1, 1, 1),
        Increment = 1,
        ValueName = "",
        Callback = function(Value)
            colorCallback(Value)
        end
    })
end
addColorSlider("Box R", 255, function(v) ESP.BoxColor = Color3.fromRGB(v, ESP.BoxColor.G*255, ESP.BoxColor.B*255) end)
addColorSlider("Box G", 255, function(v) ESP.BoxColor = Color3.fromRGB(ESP.BoxColor.R*255, v, ESP.BoxColor.B*255) end)
addColorSlider("Box B", 255, function(v) ESP.BoxColor = Color3.fromRGB(ESP.BoxColor.R*255, ESP.BoxColor.G*255, v) end)
addColorSlider("Tracer R", 255, function(v) ESP.TracerColor = Color3.fromRGB(v, ESP.TracerColor.G*255, ESP.TracerColor.B*255) end)
addColorSlider("Tracer G", 255, function(v) ESP.TracerColor = Color3.fromRGB(ESP.TracerColor.R*255, v, ESP.TracerColor.B*255) end)
addColorSlider("Tracer B", 255, function(v) ESP.TracerColor = Color3.fromRGB(ESP.TracerColor.R*255, ESP.TracerColor.G*255, v) end)
addColorSlider("Text R", 255, function(v) ESP.TextColor = Color3.fromRGB(v, ESP.TextColor.G*255, ESP.TextColor.B*255) end)
addColorSlider("Text G", 255, function(v) ESP.TextColor = Color3.fromRGB(ESP.TextColor.R*255, v, ESP.TextColor.B*255) end)
addColorSlider("Text B", 255, function(v) ESP.TextColor = Color3.fromRGB(ESP.TextColor.R*255, ESP.TextColor.G*255, v) end)

VisualTab:AddSection("Персонаж")
VisualTab:AddToggle({
    Name = "Невидимость (полная)",
    Default = false,
    Callback = function(Value)
        Invisible.Enabled = Value
        if Value then
            applyInvisibility(Character)
        else
            removeInvisibility(Character)
        end
    end
})
VisualTab:AddToggle({
    Name = "Godmode (999 999 HP)",
    Default = false,
    Callback = function(Value)
        Godmode.Enabled = Value
        if Value then
            applyGodmode(Character)
        else
            removeGodmode(Character)
        end
    end
})

-- Вкладка "Аимбот"
local AimbotTab = Window:MakeTab({
    Name = "🎯 Аимбот",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AimbotTab:AddSection("Настройки")
AimbotTab:AddToggle({
    Name = "Аимбот",
    Default = false,
    Callback = function(Value)
        Aimbot.Enabled = Value
        if Value then
            startAimbot()
        else
            if Aimbot.Connection then Aimbot.Connection:Disconnect() end
        end
    end
})
AimbotTab:AddToggle({
    Name = "Silent Aim (бесшумный)",
    Default = false,
    Callback = function(Value)
        Aimbot.SilentAim = Value
    end
})
AimbotTab:AddSlider({
    Name = "FOV (радиус захвата)",
    Min = 10,
    Max = 300,
    Default = 100,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 5,
    ValueName = "px",
    Callback = function(Value)
        Aimbot.FOV = Value
    end
})
AimbotTab:AddSlider({
    Name = "Сглаживание",
    Min = 0.1,
    Max = 1,
    Default = 0.5,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 0.1,
    ValueName = "smooth",
    Callback = function(Value)
        Aimbot.Smoothness = Value
    end
})
AimbotTab:AddSlider({
    Name = "Предсказание",
    Min = 0,
    Max = 0.5,
    Default = 0.1,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 0.05,
    ValueName = "s",
    Callback = function(Value)
        Aimbot.Prediction = Value
    end
})
AimbotTab:AddDropdown({
    Name = "Часть тела",
    Default = "Head",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Callback = function(Value)
        Aimbot.Part = Value
    end
})

-- Вкладка "Троллинг"
local TrollingTab = Window:MakeTab({
    Name = "🎭 Троллинг",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

TrollingTab:AddSection("Цель")
local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    if #list == 0 then
        list = {"Нет игроков"}
    end
    return list
end

local selectedDropdown
selectedDropdown = TrollingTab:AddDropdown({
    Name = "Выбрать игрока",
    Default = "Нет игроков",
    Options = getPlayerList(),
    Callback = function(Value)
        selectedPlayer = (Value ~= "Нет игроков") and Players:FindFirstChild(Value) or nil
    end
})

TrollingTab:AddButton({
    Name = "Обновить список",
    Callback = function()
        selectedDropdown:Refresh(getPlayerList(), true)
    end
})

TrollingTab:AddButton({
    Name = "Телепорт к игроку",
    Callback = function()
        if not selectedPlayer or not selectedPlayer.Character or not Character or not Character:FindFirstChild("HumanoidRootPart") then
            OrionLib:MakeNotification({Name = "Ошибка", Content = "Нет цели", Time = 3, Color = Color3.new(1,0,0)})
            return
        end
        local targetRoot = selectedPlayer.Character.HumanoidRootPart
        local myRoot = Character.HumanoidRootPart
        local targetCF = targetRoot.CFrame + Vector3.new(0, 3, 0)
        myRoot.CFrame = targetCF
        RunService.Heartbeat:Wait()
        myRoot.CFrame = targetCF
        OrionLib:MakeNotification({Name = "Телепорт", Content = "Телепортирован к " .. selectedPlayer.Name, Time = 3, Color = Color3.new(0,1,0)})
    end
})

TrollingTab:AddButton({
    Name = "Spin Fling (вращение)",
    Callback = function()
        if not selectedPlayer or not selectedPlayer.Character or not selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            OrionLib:MakeNotification({Name = "Ошибка", Content = "Нет цели", Time = 3, Color = Color3.new(1,0,0)})
            return
        end
        local root = selectedPlayer.Character.HumanoidRootPart
        local orig = root.CFrame
        for i = 1, 30 do
            root.CFrame = orig * CFrame.Angles(0, math.rad(12 * i), 0)
            RunService.RenderStepped:Wait()
        end
        root.CFrame = orig
    end
})

TrollingTab:AddButton({
    Name = "Заморозить игрока",
    Callback = function()
        if not selectedPlayer or not selectedPlayer.Character or not selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            OrionLib:MakeNotification({Name = "Ошибка", Content = "Нет цели", Time = 3, Color = Color3.new(1,0,0)})
            return
        end
        local root = selectedPlayer.Character.HumanoidRootPart
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.zero
        bv.Parent = root
        Debris:AddItem(bv, 9999)
        OrionLib:MakeNotification({Name = "Заморозка", Content = selectedPlayer.Name .. " заморожен", Time = 3, Color = Color3.new(0,0.5,1)})
    end
})

TrollingTab:AddButton({
    Name = "Bring All (притянуть всех)",
    Callback = function()
        if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
        local myCF = Character.HumanoidRootPart.CFrame
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.CFrame = myCF + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
            end
        end
    end
})

-- Вкладка "Разное"
local MiscTab = Window:MakeTab({
    Name = "🔧 Разное",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MiscTab:AddSection("Сервер")
MiscTab:AddButton({
    Name = "Rejoin (перезайти)",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})
MiscTab:AddButton({
    Name = "Server Hop (сменить сервер)",
    Callback = function()
        TeleportService:Teleport(game.PlaceId)
    end
})

MiscTab:AddSection("Утилиты")
MiscTab:AddToggle({
    Name = "Анти-АФК",
    Default = false,
    Callback = function(Value)
        if Value then
            _G.antiAFK = RunService.Stepped:Connect(function()
                if Character and Character:FindFirstChild("Humanoid") then
                    Character.Humanoid.MoveDirection = Vector3.new(1, 0, 0)
                end
            end)
        else
            if _G.antiAFK then _G.antiAFK:Disconnect() end
        end
    end
})

MiscTab:AddToggle({
    Name = "Kill Aura (убийственная аура)",
    Default = false,
    Callback = function(Value)
        KillAura.Enabled = Value
        if Value then
            startKillAura()
        else
            if KillAura.Connection then KillAura.Connection:Disconnect() end
        end
    end
})
MiscTab:AddSlider({
    Name = "Радиус Kill Aura",
    Min = 5,
    Max = 50,
    Default = 10,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 1,
    ValueName = "studs",
    Callback = function(Value)
        KillAura.Range = Value
    end
})

-- Вкладка "Настройки"
local SettingsTab = Window:MakeTab({
    Name = "⚙️ Настройки",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddSection("Клавиши")
SettingsTab:AddBind({
    Name = "Вкл/Выкл полёт",
    Default = Enum.KeyCode.F,
    Hold = false,
    Callback = function()
        Flight.Enabled = not Flight.Enabled
        if Flight.Enabled then
            startFlight(Character)
        else
            stopFlight()
        end
    end
})

SettingsTab:AddSection("Тема")
SettingsTab:AddDropdown({
    Name = "Сменить тему",
    Default = "Default",
    Options = {"Default", "DarkBlue", "Red", "Green", "Purple", "Orange", "Pink"},
    Callback = function(Theme)
        OrionLib:ChangeTheme(Theme)
    end
})

-- Завершение загрузки
OrionLib:MakeNotification({
    Name = "Ryzen Hub X",
    Content = "Универсальный скрипт успешно загружен!",
    Time = 5,
    Color = Color3.fromRGB(0, 170, 255)
})

OrionLib:Init()