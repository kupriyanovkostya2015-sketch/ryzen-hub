--[[
    RYZEN UNIVERSAL HUB v7.2 — ПОЛНЫЙ РАБОЧИЙ СКРИПТ
    Все функции на месте, интерфейс с улучшенной читаемостью.
--]]

-- Удаление старого GUI
pcall(function()
    if game.CoreGui:FindFirstChild("RyzenHub") then game.CoreGui.RyzenHub:Destroy() end
    if game.Players.LocalPlayer.PlayerGui:FindFirstChild("RyzenHub") then game.Players.LocalPlayer.PlayerGui.RyzenHub:Destroy() end
end)

-- Сервисы
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")
local TeleportService = game:GetService("TeleportService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Char, Hum, Root

-- Таблицы состояний
local Fly = { On = false, Key = Enum.KeyCode.F, Speed = 50 }
local Noclip = { On = false, Key = Enum.KeyCode.N }
local InfJump = { On = false, Key = Enum.KeyCode.H }
local Fullbright = { On = false, Key = Enum.KeyCode.L }
local Teleport = { On = false, Key = Enum.KeyCode.T }
local NoRagdoll = { On = false, Key = Enum.KeyCode.R }
local ESP = { On = false, Boxes = true, Names = true, Health = true, Tracers = true }
local Chams = { On = false }
local Aimbot = { On = false, Key = Enum.KeyCode.E, FOV = 120, Smooth = 0.5, Part = "Head" }
local KillAura = { On = false, Range = 15 }
local SpinBot = { On = false, Speed = 10 }
local AutoFarm = { On = false, Radius = 40 }
local Spammer = { On = false, Msg = "Ryzen 2026", Delay = 3 }
local Freecam = { On = false }
local Godmode = { On = false }
local Invis = { On = false }

local flyGyro, flyVel, flyConn
local infJumpConn, aimConn, killConn, spinConn, farmConn, spamConn
local freecamConn, freecamSub
local selectedPlayer = nil
_G.RyzenRebinding = false

-- Функция обновления персонажа
local function onChar(char)
    Char = char; Hum = char:WaitForChild("Humanoid"); Root = char:WaitForChild("HumanoidRootPart")
    if Fly.On then startFly() end
    if Noclip.On then setNoclip(true) end
    if NoRagdoll.On then setNoRagdoll(true) end
    if Godmode.On then applyGodmode() end
    if Invis.On then applyInvis() end
    pcall(function() Hum.WalkSpeed = 16 end)
end
LocalPlayer.CharacterAdded:Connect(onChar)
if LocalPlayer.Character then onChar(LocalPlayer.Character) end

-- ======================= ВСЕ ФУНКЦИИ =======================
function startFly()
    if not Root then return end
    stopFly()
    flyGyro = Instance.new("BodyGyro"); flyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9); flyGyro.CFrame = Root.CFrame; flyGyro.Parent = Root
    flyVel = Instance.new("BodyVelocity"); flyVel.MaxForce = Vector3.new(1e9,1e9,1e9); flyVel.Velocity = Vector3.zero; flyVel.Parent = Root
    flyConn = RunService.RenderStepped:Connect(function()
        if not Fly.On or not Root then return end
        local dir = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        flyGyro.CFrame = Camera.CFrame; flyVel.Velocity = dir * Fly.Speed
    end)
end
function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    if flyVel then flyVel:Destroy(); flyVel = nil end
end

function setNoclip(state)
    if not Char then return end
    for _, v in ipairs(Char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = not state end end
end

function toggleInfJump(state)
    InfJump.On = state
    if state then
        infJumpConn = UIS.JumpRequest:Connect(function()
            if Hum and Hum:GetState() == Enum.HumanoidStateType.Landed then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    end
end

function setFullbright(state)
    Lighting.Ambient = state and Color3.new(1,1,1) or Color3.new(0,0,0)
    Lighting.Brightness = state and 2 or 1
    Lighting.GlobalShadows = not state
end

function teleportToMouse()
    if not Root then return end
    local hit = Mouse.Hit
    if hit then Root.CFrame = CFrame.new(hit.Position) end
end

function setNoRagdoll(state)
    if Hum then Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not state) end
end

function applyGodmode()
    if not Hum then return end
    Hum.MaxHealth = 1e9; Hum.Health = 1e9
    Hum.HealthChanged:Connect(function() if Godmode.On and Hum.Health < Hum.MaxHealth then Hum.Health = Hum.MaxHealth end end)
end

function applyInvis()
    if not Char then return end
    for _, v in ipairs(Char:GetDescendants()) do if v:IsA("BasePart") then v.Transparency = 1; v.CanCollide = false end end
end
function removeInvis()
    if not Char then return end
    for _, v in ipairs(Char:GetDescendants()) do if v:IsA("BasePart") then v.Transparency = 0; v.CanCollide = true end end
end

-- ESP
local espObjs = {}
local function updateESP()
    if not ESP.On then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char or not char:FindFirstChild("Head") or not char:FindFirstChild("HumanoidRootPart") then
            if espObjs[plr] then espObjs[plr].Box:Remove(); espObjs[plr].Name:Remove(); espObjs[plr].Tracer:Remove(); espObjs[plr] = nil end
            continue
        end
        if not espObjs[plr] then
            espObjs[plr] = { Box = Drawing.new("Square"), Name = Drawing.new("Text"), Tracer = Drawing.new("Line") }
        end
        local head, root = char.Head, char.HumanoidRootPart
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
        local obj = espObjs[plr]
        if onScreen then
            local fp = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
            local hp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,2,0))
            local h = math.abs(hp.Y - fp.Y); local w = h/2
            obj.Box.Visible = ESP.Boxes; obj.Box.Size = Vector2.new(w, h); obj.Box.Position = Vector2.new(pos.X - w/2, pos.Y); obj.Box.Color = Color3.new(1,1,1)
            obj.Name.Visible = ESP.Names; obj.Name.Text = plr.Name; obj.Name.Position = Vector2.new(pos.X, pos.Y - 20); obj.Name.Size = 14; obj.Name.Color = Color3.new(1,1,1); obj.Name.Center = true; obj.Name.Outline = true
            obj.Tracer.Visible = ESP.Tracers; obj.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); obj.Tracer.To = Vector2.new(pos.X, pos.Y); obj.Tracer.Color = Color3.new(1,1,1)
        else
            obj.Box.Visible = false; obj.Name.Visible = false; obj.Tracer.Visible = false
        end
    end
end

-- Chams
local function updateChams()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end
        local hl = char:FindFirstChild("ChamHL")
        if Chams.On then
            if not hl then hl = Instance.new("Highlight"); hl.Name = "ChamHL"; hl.FillColor = Color3.new(1,0,0); hl.FillTransparency = 0.5; hl.Parent = char end
        else if hl then hl:Destroy() end end
    end
end

function startAimbot()
    if aimConn then aimConn:Disconnect() end
    aimConn = RunService.RenderStepped:Connect(function()
        if not Aimbot.On or not Root then return end
        local closest, minDist = nil, Aimbot.FOV
        local mousePos = UIS:GetMouseLocation()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local char = plr.Character
            if char and char:FindFirstChild(Aimbot.Part) then
                local part = char[Aimbot.Part]
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < minDist then minDist = dist; closest = part end
                end
            end
        end
        if closest then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closest.Position), Aimbot.Smooth) end
    end)
end

function startKillAura()
    if killConn then killConn:Disconnect() end
    killConn = RunService.RenderStepped:Connect(function()
        if not KillAura.On or not Root then return end
        local myPos = Root.Position
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local char = plr.Character
            if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                if (root.Position - myPos).Magnitude <= KillAura.Range then
                    char.Humanoid.Health -= char.Humanoid.MaxHealth * 0.01
                end
            end
        end
    end)
end

function startSpinBot()
    if spinConn then spinConn:Disconnect() end
    spinConn = RunService.RenderStepped:Connect(function()
        if not SpinBot.On or not Root then return end
        Root.CFrame = Root.CFrame * CFrame.Angles(0, math.rad(SpinBot.Speed), 0)
    end)
end

function startAutoFarm()
    if farmConn then farmConn:Disconnect() end
    farmConn = RunService.Heartbeat:Connect(function()
        if not AutoFarm.On or not Root then return end
        local nearest, minDist = nil, AutoFarm.Radius
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name == "Cash" or obj.Name == "Gem") then
                local d = (obj.Position - Root.Position).Magnitude
                if d < minDist then nearest = obj; minDist = d end
            end
        end
        if nearest then nearest.CFrame = Root.CFrame + Vector3.new(0,5,0) end
    end)
end

function startSpammer()
    if spamConn then spamConn:Disconnect() end
    spamConn = RunService.Heartbeat:Connect(function()
        if not Spammer.On then return end
        local TextChatService = game:GetService("TextChatService")
        if TextChatService then
            TextChatService:Chat(LocalPlayer, Spammer.Msg, "All")
        else
            local rep = game:GetService("ReplicatedStorage")
            local default = rep:FindFirstChild("DefaultChatSystemChatEvents")
            if default and default:FindFirstChild("SayMessageRequest") then
                default.SayMessageRequest:FireServer(Spammer.Msg, "All")
            end
        end
        task.wait(Spammer.Delay)
    end)
end

function startFreecam()
    if not Root or not Char then return end
    stopFreecam()
    applyInvis()
    freecamSub = Instance.new("Part"); freecamSub.Size = Vector3.new(1,1,1); freecamSub.Transparency = 1; freecamSub.Anchored = false; freecamSub.CanCollide = false
    freecamSub.Position = Camera.CFrame.Position; freecamSub.Parent = workspace
    Camera.CameraSubject = freecamSub
    freecamConn = RunService.RenderStepped:Connect(function()
        if not Freecam.On or not freecamSub then return end
        freecamSub.CFrame = Camera.CFrame
    end)
end
function stopFreecam()
    if freecamConn then freecamConn:Disconnect(); freecamConn = nil end
    if freecamSub then freecamSub:Destroy(); freecamSub = nil end
    Camera.CameraSubject = Char
    removeInvis()
end

function flingPlayer(player)
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = player.Character.HumanoidRootPart
    local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Velocity = Vector3.new(math.random(-5000,5000), math.random(2000,5000), math.random(-5000,5000))
    bv.Parent = root; Debris:AddItem(bv, 0.5)
end

function freezePlayer(player)
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = player.Character.HumanoidRootPart
    local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(1e9,1e9,1e9); bv.Velocity = Vector3.zero
    bv.Parent = root; Debris:AddItem(bv, 9999)
end

function teleportToPlayer(player)
    if not player or not player.Character or not Root then return end
    local target = player.Character:FindFirstChild("HumanoidRootPart")
    if target then Root.CFrame = target.CFrame + Vector3.new(0,3,0) end
end

function bringAll()
    if not Root then return end
    local myCF = Root.CFrame
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = myCF + Vector3.new(math.random(-2,2), 0, math.random(-2,2))
        end
    end
end

function respawnCharacter()
    if Char then Char:BreakJoints() end
end

function suicide()
    if Hum then Hum.Health = 0 end
end

-- Глобальный обработчик клавиш
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.LeftAlt or key == Enum.KeyCode.RightShift or key == Enum.KeyCode.Insert then
        if _G.Main then _G.Main.Visible = not _G.Main.Visible end
        return
    end
    if _G.RyzenRebinding then return end

    if key == Fly.Key then Fly.On = not Fly.On; if Fly.On then startFly() else stopFly() end
    elseif key == Noclip.Key then Noclip.On = not Noclip.On; setNoclip(Noclip.On)
    elseif key == InfJump.Key then toggleInfJump(not InfJump.On)
    elseif key == Fullbright.Key then Fullbright.On = not Fullbright.On; setFullbright(Fullbright.On)
    elseif key == Teleport.Key then teleportToMouse()
    elseif key == NoRagdoll.Key then NoRagdoll.On = not NoRagdoll.On; setNoRagdoll(NoRagdoll.On)
    elseif key == Aimbot.Key then Aimbot.On = not Aimbot.On; if Aimbot.On then startAimbot() else if aimConn then aimConn:Disconnect() end end
    elseif key == KillAura.Key then KillAura.On = not KillAura.On; if KillAura.On then startKillAura() else if killConn then killConn:Disconnect() end end
    elseif key == SpinBot.Key then SpinBot.On = not SpinBot.On; if SpinBot.On then startSpinBot() else if spinConn then spinConn:Disconnect() end end
    elseif key == AutoFarm.Key then AutoFarm.On = not AutoFarm.On; if AutoFarm.On then startAutoFarm() else if farmConn then farmConn:Disconnect() end end
    elseif key == Spammer.Key then Spammer.On = not Spammer.On; if Spammer.On then startSpammer() else if spamConn then spamConn:Disconnect() end end
    elseif key == Freecam.Key then Freecam.On = not Freecam.On; if Freecam.On then startFreecam() else stopFreecam() end
    elseif key == Godmode.Key then Godmode.On = not Godmode.On; if Godmode.On then applyGodmode() end
    elseif key == Invis.Key then Invis.On = not Invis.On; if Invis.On then applyInvis() else removeInvis() end
    end
end)

RunService.RenderStepped:Connect(function()
    updateESP()
    updateChams()
end)

-- ======================= ГРАФИЧЕСКИЙ ИНТЕРФЕЙС (улучшенный) =======================
local Gui = Instance.new("ScreenGui")
Gui.Name = "RyzenHub"
Gui.ResetOnSpawn = false
pcall(function() Gui.Parent = CoreGui end)
if not Gui.Parent then
    pcall(function() Gui.Parent = LocalPlayer.PlayerGui end)
end
if not Gui.Parent then return end

local function applyStyle(obj)
    if obj:IsA("TextButton") or obj:IsA("Frame") or obj:IsA("TextBox") then
        obj.BackgroundColor3 = Color3.fromRGB(35,35,35)
        obj.BorderSizePixel = 0
        if obj:IsA("TextButton") then
            obj.TextColor3 = Color3.new(1,1,1)
            obj.Font = Enum.Font.Gotham
            obj.TextSize = 14
            obj.AutoButtonColor = false
        elseif obj:IsA("TextBox") then
            obj.TextColor3 = Color3.new(1,1,1)
            obj.Font = Enum.Font.Gotham
            obj.TextSize = 14
        end
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0,6)
        corner.Parent = obj
    end
    if obj:IsA("ScrollingFrame") then
        obj.BackgroundColor3 = Color3.fromRGB(45,45,45)
        obj.BorderSizePixel = 0
        obj.ScrollBarThickness = 4
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0,6)
        corner.Parent = obj
    end
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 600, 0, 440)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
MainFrame.Active = true
MainFrame.Draggable = true
applyStyle(MainFrame)
MainFrame.Parent = Gui
_G.Main = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,32)
Title.BackgroundColor3 = Color3.fromRGB(20,20,20)
Title.Text = "Ryzen Universal Hub v7.2"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
applyStyle(Title)
Title.Parent = MainFrame

local Hint = Instance.new("TextLabel")
Hint.Size = UDim2.new(1,0,0,20)
Hint.Position = UDim2.new(0,0,0,32)
Hint.BackgroundColor3 = Color3.fromRGB(30,30,30)
Hint.Text = "Alt / RightShift / Insert — скрыть меню"
Hint.TextColor3 = Color3.new(0.7,0.7,0.7)
Hint.Font = Enum.Font.Gotham
Hint.TextSize = 12
applyStyle(Hint)
Hint.Parent = MainFrame

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 140, 1, -52)
TabContainer.Position = UDim2.new(0,0,0,52)
TabContainer.BackgroundColor3 = Color3.fromRGB(30,30,30)
applyStyle(TabContainer)
TabContainer.Parent = MainFrame

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -140, 1, -52)
ContentArea.Position = UDim2.new(0,140,0,52)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local Tabs = {}
local function addTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,35)
    btn.Text = name
    applyStyle(btn)
    btn.Parent = TabContainer

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundColor3 = Color3.fromRGB(35,35,35)
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.Visible = false
    page.Parent = ContentArea

    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(Tabs) do
            t.Page.Visible = false
            t.Btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    end)
    table.insert(Tabs, {Btn = btn, Page = page})
    return page
end

-- Улучшенная строка с переключателем и привязкой клавиши
local ROW_HEIGHT = 44
local PADDING = 8
local function addBindItem(parent, name, moduleTable, mode)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -PADDING*2, 0, ROW_HEIGHT)
    frame.Position = UDim2.new(0, PADDING, 0, parent.CanvasSize.Y.Offset + PADDING)
    frame.BackgroundColor3 = Color3.fromRGB(45,45,45)
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,6); corner.Parent = frame
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 140, 1, -4)
    label.Position = UDim2.new(0, PADDING, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0, 52, 0, 26)
    bindBtn.Position = UDim2.new(1, -60 - PADDING, 0.5, -13)
    bindBtn.Text = moduleTable.Key.Name
    bindBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
    bindBtn.TextColor3 = Color3.new(1,1,1)
    bindBtn.Font = Enum.Font.Gotham
    bindBtn.TextSize = 12
    bindBtn.AutoButtonColor = false
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = bindBtn
    bindBtn.Parent = frame

    local stateBtn
    if mode == "toggle" then
        stateBtn = Instance.new("TextButton")
        stateBtn.Size = UDim2.new(0, 30, 0, 30)
        stateBtn.Position = UDim2.new(0, label.Size.X.Offset + 20, 0.5, -15)
        stateBtn.BackgroundColor3 = moduleTable.On and Color3.fromRGB(0,170,0) or Color3.fromRGB(110,110,110)
        stateBtn.Text = ""
        local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0,6); sc.Parent = stateBtn
        stateBtn.Parent = frame
    end

    local waiting = false
    bindBtn.MouseButton1Click:Connect(function()
        waiting = true
        _G.RyzenRebinding = true
        bindBtn.Text = "..."
    end)

    UIS.InputBegan:Connect(function(input, gameProcessed)
        if not waiting or gameProcessed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local newKey = input.KeyCode
        bindBtn.Text = newKey.Name
        moduleTable.Key = newKey
        waiting = false
        _G.RyzenRebinding = false
    end)

    if stateBtn then
        stateBtn.MouseButton1Click:Connect(function()
            moduleTable.On = not moduleTable.On
            stateBtn.BackgroundColor3 = moduleTable.On and Color3.fromRGB(0,170,0) or Color3.fromRGB(110,110,110)
            if moduleTable == Fly then
                if moduleTable.On then startFly() else stopFly() end
            elseif moduleTable == Noclip then
                setNoclip(moduleTable.On)
            elseif moduleTable == InfJump then
                toggleInfJump(moduleTable.On)
            elseif moduleTable == Fullbright then
                setFullbright(moduleTable.On)
            elseif moduleTable == Teleport then
                teleportToMouse()
            elseif moduleTable == NoRagdoll then
                setNoRagdoll(moduleTable.On)
            elseif moduleTable == Aimbot then
                if moduleTable.On then startAimbot() else if aimConn then aimConn:Disconnect() end end
            elseif moduleTable == KillAura then
                if moduleTable.On then startKillAura() else if killConn then killConn:Disconnect() end end
            elseif moduleTable == SpinBot then
                if moduleTable.On then startSpinBot() else if spinConn then spinConn:Disconnect() end end
            elseif moduleTable == AutoFarm then
                if moduleTable.On then startAutoFarm() else if farmConn then farmConn:Disconnect() end end
            elseif moduleTable == Spammer then
                if moduleTable.On then startSpammer() else if spamConn then spamConn:Disconnect() end end
            elseif moduleTable == Freecam then
                if moduleTable.On then startFreecam() else stopFreecam() end
            elseif moduleTable == Godmode then
                if moduleTable.On then applyGodmode() end
            elseif moduleTable == Invis then
                if moduleTable.On then applyInvis() else removeInvis() end
            end
        end)
    end

    parent.CanvasSize = UDim2.new(0, 0, 0, parent.CanvasSize.Y.Offset + ROW_HEIGHT + PADDING)
end

-- Улучшенный слайдер
local function addSlider(parent, name, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -PADDING*2, 0, ROW_HEIGHT + 30)
    frame.Position = UDim2.new(0, PADDING, 0, parent.CanvasSize.Y.Offset + PADDING)
    frame.BackgroundColor3 = Color3.fromRGB(45,45,45)
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,6); corner.Parent = frame
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -PADDING*2, 0, 20)
    label.Position = UDim2.new(0, PADDING, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -PADDING*2, 0, 10)
    sliderBg.Position = UDim2.new(0, PADDING, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(80,80,80)
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0,4); sc.Parent = sliderBg
    sliderBg.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0,170,255)
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0,4); fc.Parent = fill
    fill.Parent = sliderBg

    local dragging = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((Mouse.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel * (max - min))
            fill.Size = UDim2.new(rel, 0, 1, 0)
            label.Text = name .. ": " .. val
            callback(val)
        end
    end)

    parent.CanvasSize = UDim2.new(0, 0, 0, parent.CanvasSize.Y.Offset + frame.Size.Y.Offset + PADDING)
end

local function addButton(parent, name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-10,0,32)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.Text = name
    applyStyle(btn)
    btn.Parent = parent
    btn.MouseButton1Click:Connect(callback)
    parent.CanvasSize += UDim2.new(0,0,0,36)
end

local function addInput(parent, name, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,-10,0,30)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    parent.CanvasSize += UDim2.new(0,0,0,35)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0,100,1,0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Parent = frame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1,-110,1,0)
    textBox.Position = UDim2.new(0,110,0,0)
    textBox.Text = default
    textBox.PlaceholderText = default
    applyStyle(textBox)
    textBox.Parent = frame
    textBox.FocusLost:Connect(function() callback(textBox.Text) end)
    return textBox
end

-- Вкладки с элементами
local MovementTab = addTab("Movement")
addBindItem(MovementTab, "Fly", Fly, "toggle")
addSlider(MovementTab, "Fly Speed", 10, 500, Fly.Speed, function(v) Fly.Speed = v end)
addBindItem(MovementTab, "Noclip", Noclip, "toggle")
addBindItem(MovementTab, "Infinite Jump", InfJump, "toggle")
addBindItem(MovementTab, "Fullbright", Fullbright, "toggle")
addBindItem(MovementTab, "Teleport Tool", Teleport, "once")
addBindItem(MovementTab, "No-Ragdoll", NoRagdoll, "toggle")
addBindItem(MovementTab, "Freecam", Freecam, "toggle")

local VisualsTab = addTab("Visuals")
-- ESP
local espFrame = Instance.new("Frame")
espFrame.Size = UDim2.new(1,-10,0,30)
espFrame.BackgroundTransparency = 1
espFrame.Parent = VisualsTab
VisualsTab.CanvasSize += UDim2.new(0,0,0,35)
local espLabel = Instance.new("TextLabel")
espLabel.Size = UDim2.new(0,100,1,0)
espLabel.BackgroundTransparency = 1
espLabel.Text = "ESP"
espLabel.TextColor3 = Color3.new(1,1,1)
espLabel.Font = Enum.Font.Gotham
espLabel.TextSize = 14
espLabel.Parent = espFrame
local espToggle = Instance.new("TextButton")
espToggle.Size = UDim2.new(0,30,0,20)
espToggle.Position = UDim2.new(0,105,0,5)
espToggle.BackgroundColor3 = ESP.On and Color3.fromRGB(0,170,0) or Color3.fromRGB(80,80,80)
espToggle.Text = ""
applyStyle(espToggle)
espToggle.Parent = espFrame
espToggle.MouseButton1Click:Connect(function()
    ESP.On = not ESP.On
    espToggle.BackgroundColor3 = ESP.On and Color3.fromRGB(0,170,0) or Color3.fromRGB(80,80,80)
end)

-- Chams
local chamsFrame = Instance.new("Frame")
chamsFrame.Size = UDim2.new(1,-10,0,30)
chamsFrame.BackgroundTransparency = 1
chamsFrame.Parent = VisualsTab
VisualsTab.CanvasSize += UDim2.new(0,0,0,35)
local chamsLabel = Instance.new("TextLabel")
chamsLabel.Size = UDim2.new(0,100,1,0)
chamsLabel.BackgroundTransparency = 1
chamsLabel.Text = "Chams"
chamsLabel.TextColor3 = Color3.new(1,1,1)
chamsLabel.Font = Enum.Font.Gotham
chamsLabel.TextSize = 14
chamsLabel.Parent = chamsFrame
local chamsToggle = Instance.new("TextButton")
chamsToggle.Size = UDim2.new(0,30,0,20)
chamsToggle.Position = UDim2.new(0,105,0,5)
chamsToggle.BackgroundColor3 = Chams.On and Color3.fromRGB(0,170,0) or Color3.fromRGB(80,80,80)
chamsToggle.Text = ""
applyStyle(chamsToggle)
chamsToggle.Parent = chamsFrame
chamsToggle.MouseButton1Click:Connect(function()
    Chams.On = not Chams.On
    chamsToggle.BackgroundColor3 = Chams.On and Color3.fromRGB(0,170,0) or Color3.fromRGB(80,80,80)
end)

addBindItem(VisualsTab, "Aimbot", Aimbot, "toggle")
addSlider(VisualsTab, "Aimbot FOV", 10, 300, Aimbot.FOV, function(v) Aimbot.FOV = v end)
addSlider(VisualsTab, "Smoothness", 0.1, 1, Aimbot.Smooth, function(v) Aimbot.Smooth = v end)

local CombatTab = addTab("Combat")
addBindItem(CombatTab, "Kill Aura", KillAura, "toggle")
addSlider(CombatTab, "Aura Range", 5, 50, KillAura.Range, function(v) KillAura.Range = v end)
addBindItem(CombatTab, "SpinBot", SpinBot, "toggle")
addSlider(CombatTab, "Spin Speed", 1, 50, SpinBot.Speed, function(v) SpinBot.Speed = v end)

local AutomationTab = addTab("Automation")
addBindItem(AutomationTab, "AutoFarm", AutoFarm, "toggle")
addSlider(AutomationTab, "Farm Radius", 5, 100, AutoFarm.Radius, function(v) AutoFarm.Radius = v end)
addBindItem(AutomationTab, "Chat Spammer", Spammer, "toggle")
addInput(AutomationTab, "Message", Spammer.Msg, function(v) Spammer.Msg = v end)
addSlider(AutomationTab, "Delay", 1, 10, Spammer.Delay, function(v) Spammer.Delay = v end)

local TrollingTab = addTab("Trolling")
-- Выбор игрока
local dropFrame = Instance.new("Frame")
dropFrame.Size = UDim2.new(1,-10,0,30)
dropFrame.BackgroundTransparency = 1
dropFrame.Parent = TrollingTab
TrollingTab.CanvasSize += UDim2.new(0,0,0,35)
local dropLabel = Instance.new("TextLabel")
dropLabel.Size = UDim2.new(0,100,1,0)
dropLabel.BackgroundTransparency = 1
dropLabel.Text = "Target"
dropLabel.TextColor3 = Color3.new(1,1,1)
dropLabel.Font = Enum.Font.Gotham
dropLabel.TextSize = 14
dropLabel.Parent = dropFrame
local dropBtn = Instance.new("TextButton")
dropBtn.Size = UDim2.new(1,-110,1,0)
dropBtn.Position = UDim2.new(0,110,0,0)
dropBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
dropBtn.Text = "None"
applyStyle(dropBtn)
dropBtn.Parent = dropFrame
local dropList = Instance.new("Frame")
dropList.Size = UDim2.new(1,-110,0,0)
dropList.Position = UDim2.new(0,110,1,0)
dropList.BackgroundColor3 = Color3.fromRGB(40,40,40)
dropList.BorderSizePixel = 0
dropList.ClipsDescendants = true
dropList.Visible = false
dropList.Parent = dropFrame

local function refreshDropList()
    for _, c in ipairs(dropList:GetChildren()) do c:Destroy() end
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(names, p.Name) end end
    if #names == 0 then table.insert(names, "None") end
    local y = 0
    for _, name in ipairs(names) do
        local opt = Instance.new("TextButton")
        opt.Size = UDim2.new(1,0,0,26)
        opt.Position = UDim2.new(0,0,0,y)
        opt.BackgroundColor3 = Color3.fromRGB(50,50,50)
        opt.Text = name
        opt.TextColor3 = Color3.new(1,1,1)
        opt.Font = Enum.Font.Gotham
        opt.TextSize = 13
        applyStyle(opt)
        opt.Parent = dropList
        opt.MouseButton1Click:Connect(function()
            dropBtn.Text = name
            dropList.Visible = false
            selectedPlayer = (name ~= "None") and Players:FindFirstChild(name) or nil
        end)
        y += 26
    end
    dropList.Size = UDim2.new(1,-110,0,y)
end
refreshDropList()
dropBtn.MouseButton1Click:Connect(function() refreshDropList(); dropList.Visible = not dropList.Visible end)

addButton(TrollingTab, "Teleport", function() if selectedPlayer then teleportToPlayer(selectedPlayer) end end)
addButton(TrollingTab, "Fling", function() if selectedPlayer then flingPlayer(selectedPlayer) end end)
addButton(TrollingTab, "Freeze", function() if selectedPlayer then freezePlayer(selectedPlayer) end end)
addButton(TrollingTab, "Bring All", bringAll)
addButton(TrollingTab, "Respawn", respawnCharacter)
addButton(TrollingTab, "Suicide", suicide)

local SettingsTab = addTab("Settings")
addBindItem(SettingsTab, "Godmode", Godmode, "toggle")
addBindItem(SettingsTab, "Invisibility", Invis, "toggle")

local MiscTab = addTab("Misc")
addButton(MiscTab, "Rejoin", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
addButton(MiscTab, "Server Hop", function() TeleportService:Teleport(game.PlaceId) end)

-- Активация первой вкладки
if Tabs[1] then
    Tabs[1].Page.Visible = true
    Tabs[1].Btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
end