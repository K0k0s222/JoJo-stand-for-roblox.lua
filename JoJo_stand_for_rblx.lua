-- ============================================
--  JoJo Stand GUI + Fling + AUTOFLING + IDLE выбор
--  - динамический ANGULAR_NOISE от дистанции
--  - автокликер FLING каждые N секунд
--  - переключение idle (Default справа / Killer Queen слева)
-- ============================================

if _G.JoJoStandGui then pcall(function() _G.JoJoStandGui:Destroy() end) end
if _G.JoJoStandConn then pcall(function() _G.JoJoStandConn:Disconnect() end) end
if _G.JoJoAnimTrack then pcall(function() _G.JoJoAnimTrack:Stop() end) end
if _G.JoJoKickGui then pcall(function() _G.JoJoKickGui:Destroy() end) end
if _G.JoJoStunConn then pcall(function() _G.JoJoStunConn:Disconnect() end) end
if _G.JoJoNoclipConn then pcall(function() _G.JoJoNoclipConn:Disconnect() end) end
if _G.JoJoAutoThread then _G.JoJoAutoThread = nil end
if _G.JoJoTimerThread then _G.JoJoTimerThread = nil end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Screen = Camera.ViewportSize
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local function sc(v) return math.floor(v * (Screen.Y / 1080) * (isMobile and 1.9 or 1.2)) end

-- ============================================
--  IDLE СПИСОК
-- ============================================
local IDLE_LIST = {
    { name = "Default",      id = 112910347435348, rightOffset = 2.5  },
    { name = "Killer Queen", id = 71765935408723,  rightOffset = -2.5 },
}
local currentIdleIndex = 1

-- ============================================
--  НАСТРОЙКИ СТЕНДА
-- ============================================
local OFFSET_BACK     = 2.5
local OFFSET_HEIGHT   = 1.5
local FACE_OWNER      = false
local WARN_TIME       = 2

-- ============================================
--  НАСТРОЙКИ ФЛИНГА
-- ============================================
local FLING_RANGE     = 15
local FLING_DURATION  = 0.5
local STUN_DURATION   = 0.2
local RETURN_DISTANCE = 2
local RETURN_TIME     = 1.5

local PULL_STRENGTH   = 10
local MAX_PULL_SPEED  = 250
local LINEAR_NOISE    = 50
local BASE_ANGULAR    = 500

local ANGULAR_NOISE_MIN = 500
local ANGULAR_NOISE_MAX = 1700

local FF_VISIBLE      = true

local AUTOFLING_DEFAULT_INTERVAL = 4

local SAVED_WALK      = 16
local SAVED_JUMP      = 50
local SAVED_JUMP_H    = 7.2

local C = {
    bg      = Color3.fromRGB(12, 12, 18),
    bg2     = Color3.fromRGB(20, 20, 30),
    field   = Color3.fromRGB(30, 30, 45),
    line    = Color3.fromRGB(80, 80, 110),
    accent  = Color3.fromRGB(200, 120, 255),
    text    = Color3.fromRGB(240, 240, 250),
    sub     = Color3.fromRGB(150, 150, 180),
    green   = Color3.fromRGB(70, 200, 120),
    red     = Color3.fromRGB(220, 70, 80),
    gold    = Color3.fromRGB(230, 190, 70),
    blue    = Color3.fromRGB(80, 160, 240),
}

-- ============================================
--  БАЗОВОЕ
-- ============================================
local function getHum()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- ============================================
--  СОСТОЯНИЕ
-- ============================================
local standEnabled = false
local standOwner = nil
local standTrack = nil
_G.JoJoAnimTrack = nil

local flingRunning = false
local followPaused = false

local autoFlingEnabled = false
local autoFlingInterval = AUTOFLING_DEFAULT_INTERVAL
_G.JoJoAutoThread = nil

local nextFlingTime = 0

-- ============================================
--  GUI СТЕНДА
-- ============================================
local StandGui = Instance.new("ScreenGui")
StandGui.Name = "JoJoStandGui"
StandGui.ResetOnSpawn = false
StandGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
StandGui.DisplayOrder = 1005
StandGui.Enabled = true
StandGui.Parent = CoreGui
_G.JoJoStandGui = StandGui

local Panel = Instance.new("Frame", StandGui)
Panel.Size = UDim2.new(0, sc(250), 0, sc(365))
Panel.Position = UDim2.new(0.5, -sc(125), 0.5, -sc(183))
Panel.BackgroundColor3 = C.bg
Panel.BackgroundTransparency = 0.05
Panel.BorderSizePixel = 0
Panel.Active = true
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, sc(12))
local pStroke = Instance.new("UIStroke", Panel)
pStroke.Color = C.accent
pStroke.Thickness = 1.5

local Header = Instance.new("Frame", Panel)
Header.Size = UDim2.new(1, 0, 0, sc(30))
Header.BackgroundColor3 = C.bg2
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, sc(12))
local hFix = Instance.new("Frame", Header)
hFix.Size = UDim2.new(1, 0, 0, sc(12))
hFix.Position = UDim2.new(0, 0, 1, -sc(12))
hFix.BackgroundColor3 = C.bg2
hFix.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -sc(20), 1, 0)
Title.Position = UDim2.new(0, sc(10), 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "JoJo stand gui (2P)"
Title.TextColor3 = C.text
Title.Font = Enum.Font.GothamBold
Title.TextSize = sc(12)
Title.TextXAlignment = Enum.TextXAlignment.Left

local drag, ds, sp
Header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true; ds = i.Position; sp = Panel.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then drag = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - ds
        Panel.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end
end)

-- ===== Владелец стенда =====
local NickLbl = Instance.new("TextLabel", Panel)
NickLbl.Size = UDim2.new(1, -sc(20), 0, sc(14))
NickLbl.Position = UDim2.new(0, sc(10), 0, sc(38))
NickLbl.BackgroundTransparency = 1
NickLbl.Text = "Владелец стенда (ник, можно часть):"
NickLbl.TextColor3 = C.sub
NickLbl.Font = Enum.Font.GothamSemibold
NickLbl.TextSize = sc(10)
NickLbl.TextXAlignment = Enum.TextXAlignment.Left

local NickBox = Instance.new("TextBox", Panel)
NickBox.Size = UDim2.new(1, -sc(20), 0, sc(32))
NickBox.Position = UDim2.new(0, sc(10), 0, sc(56))
NickBox.BackgroundColor3 = C.field
NickBox.Text = ""
NickBox.PlaceholderText = "введи ник или часть..."
NickBox.PlaceholderColor3 = C.sub
NickBox.TextColor3 = C.text
NickBox.Font = Enum.Font.GothamSemibold
NickBox.TextSize = sc(11)
NickBox.TextXAlignment = Enum.TextXAlignment.Left
NickBox.ClearTextOnFocus = false
NickBox.BorderSizePixel = 0
Instance.new("UICorner", NickBox).CornerRadius = UDim.new(0, sc(6))
local nbStroke = Instance.new("UIStroke", NickBox)
nbStroke.Color = C.line
nbStroke.Thickness = 1.5

-- ===== Кнопка стенда =====
local ToggleBtn = Instance.new("TextButton", Panel)
ToggleBtn.Size = UDim2.new(1, -sc(20), 0, sc(36))
ToggleBtn.Position = UDim2.new(0, sc(10), 0, sc(98))
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
ToggleBtn.Text = "ВКЛЮЧИТЬ СТЕНД"
ToggleBtn.TextColor3 = C.text
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = sc(12)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.AutoButtonColor = false
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, sc(6))
local tbStroke = Instance.new("UIStroke", ToggleBtn)
tbStroke.Color = C.green
tbStroke.Thickness = 1.5
tbStroke.Transparency = 0.2

-- ===== Кнопка IDLE =====
local IdleLbl = Instance.new("TextLabel", Panel)
IdleLbl.Size = UDim2.new(1, -sc(20), 0, sc(14))
IdleLbl.Position = UDim2.new(0, sc(10), 0, sc(144))
IdleLbl.BackgroundTransparency = 1
IdleLbl.Text = "Idle (положение стенда):"
IdleLbl.TextColor3 = C.sub
IdleLbl.Font = Enum.Font.GothamSemibold
IdleLbl.TextSize = sc(10)
IdleLbl.TextXAlignment = Enum.TextXAlignment.Left

local IdleBtn = Instance.new("TextButton", Panel)
IdleBtn.Size = UDim2.new(1, -sc(20), 0, sc(32))
IdleBtn.Position = UDim2.new(0, sc(10), 0, sc(160))
IdleBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 100)
IdleBtn.Text = "IDLE: Default"
IdleBtn.TextColor3 = C.text
IdleBtn.Font = Enum.Font.GothamBold
IdleBtn.TextSize = sc(11)
IdleBtn.BorderSizePixel = 0
IdleBtn.AutoButtonColor = false
Instance.new("UICorner", IdleBtn).CornerRadius = UDim.new(0, sc(6))
local idleStroke = Instance.new("UIStroke", IdleBtn)
idleStroke.Color = C.accent
idleStroke.Thickness = 1.5
idleStroke.Transparency = 0.2

-- ===== Разделитель =====
local Sep = Instance.new("Frame", Panel)
Sep.Size = UDim2.new(1, -sc(20), 0, 1)
Sep.Position = UDim2.new(0, sc(10), 0, sc(202))
Sep.BackgroundColor3 = C.line
Sep.BorderSizePixel = 0

-- ===== Интервал =====
local IntLbl = Instance.new("TextLabel", Panel)
IntLbl.Size = UDim2.new(0.6, -sc(10), 0, sc(14))
IntLbl.Position = UDim2.new(0, sc(10), 0, sc(210))
IntLbl.BackgroundTransparency = 1
IntLbl.Text = "Интервал автофлинга (сек):"
IntLbl.TextColor3 = C.sub
IntLbl.Font = Enum.Font.GothamSemibold
IntLbl.TextSize = sc(10)
IntLbl.TextXAlignment = Enum.TextXAlignment.Left

local IntBox = Instance.new("TextBox", Panel)
IntBox.Size = UDim2.new(0.35, 0, 0, sc(26))
IntBox.Position = UDim2.new(0.65, 0, 0, sc(205))
IntBox.BackgroundColor3 = C.field
IntBox.Text = tostring(AUTOFLING_DEFAULT_INTERVAL)
IntBox.PlaceholderText = "4"
IntBox.PlaceholderColor3 = C.sub
IntBox.TextColor3 = C.text
IntBox.Font = Enum.Font.GothamBold
IntBox.TextSize = sc(11)
IntBox.TextXAlignment = Enum.TextXAlignment.Center
IntBox.ClearTextOnFocus = false
IntBox.BorderSizePixel = 0
Instance.new("UICorner", IntBox).CornerRadius = UDim.new(0, sc(6))
local ibStroke = Instance.new("UIStroke", IntBox)
ibStroke.Color = C.line
ibStroke.Thickness = 1.5

-- ===== Кнопка AUTOFLING =====
local AutoBtn = Instance.new("TextButton", Panel)
AutoBtn.Size = UDim2.new(1, -sc(20), 0, sc(36))
AutoBtn.Position = UDim2.new(0, sc(10), 0, sc(238))
AutoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
AutoBtn.Text = "AUTOFLING: ВЫКЛ"
AutoBtn.TextColor3 = C.text
AutoBtn.Font = Enum.Font.GothamBold
AutoBtn.TextSize = sc(12)
AutoBtn.BorderSizePixel = 0
AutoBtn.AutoButtonColor = false
Instance.new("UICorner", AutoBtn).CornerRadius = UDim.new(0, sc(6))
local abStroke = Instance.new("UIStroke", AutoBtn)
abStroke.Color = C.line
abStroke.Thickness = 1.5

-- ===== Таймер =====
local TimerLbl = Instance.new("TextLabel", Panel)
TimerLbl.Size = UDim2.new(1, -sc(20), 0, sc(20))
TimerLbl.Position = UDim2.new(0, sc(10), 0, sc(280))
TimerLbl.BackgroundColor3 = C.bg2
TimerLbl.Text = ""
TimerLbl.TextColor3 = C.gold
TimerLbl.Font = Enum.Font.GothamBold
TimerLbl.TextSize = sc(11)
TimerLbl.BorderSizePixel = 0
Instance.new("UICorner", TimerLbl).CornerRadius = UDim.new(0, sc(6))
local tlStroke = Instance.new("UIStroke", TimerLbl)
tlStroke.Color = C.line
tlStroke.Thickness = 1

-- ===== Статус =====
local WarnLbl = Instance.new("TextLabel", Panel)
WarnLbl.Size = UDim2.new(1, -sc(20), 0, sc(45))
WarnLbl.Position = UDim2.new(0, sc(10), 0, sc(306))
WarnLbl.BackgroundTransparency = 1
WarnLbl.Text = ""
WarnLbl.TextColor3 = C.red
WarnLbl.Font = Enum.Font.GothamBold
WarnLbl.TextSize = sc(10)
WarnLbl.TextWrapped = true
WarnLbl.TextYAlignment = Enum.TextYAlignment.Top
WarnLbl.TextXAlignment = Enum.TextXAlignment.Center

local warnToken = 0
local function showWarn(text)
    warnToken = warnToken + 1
    local myTok = warnToken
    WarnLbl.Text = text
    WarnLbl.TextTransparency = 0
    task.spawn(function()
        task.wait(WARN_TIME)
        if warnToken ~= myTok then return end
        local t0 = tick()
        while tick() - t0 < 0.4 do
            if warnToken ~= myTok then return end
            WarnLbl.TextTransparency = (tick() - t0) / 0.4
            task.wait(0.02)
        end
        if warnToken == myTok then
            WarnLbl.Text = ""
            WarnLbl.TextTransparency = 0
        end
    end)
end

-- ============================================
--  GUI КНОПКИ FLING
-- ============================================
local KickGui = Instance.new("ScreenGui")
KickGui.Name = "JoJoKickGui"
KickGui.ResetOnSpawn = false
KickGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
KickGui.DisplayOrder = 1006
KickGui.Enabled = true
KickGui.Parent = CoreGui
_G.JoJoKickGui = KickGui

local KickBtn = Instance.new("TextButton", KickGui)
KickBtn.Size = UDim2.new(0, sc(64), 0, sc(64))
KickBtn.Position = UDim2.new(1, -sc(300), 1, -sc(220))
KickBtn.BackgroundColor3 = Color3.fromRGB(230, 160, 80)
KickBtn.Text = "🦵"
KickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KickBtn.Font = Enum.Font.GothamBlack
KickBtn.TextSize = sc(28)
KickBtn.BorderSizePixel = 0
KickBtn.AutoButtonColor = false
Instance.new("UICorner", KickBtn).CornerRadius = UDim.new(1, 0)
local kbStroke = Instance.new("UIStroke", KickBtn)
kbStroke.Color = Color3.fromRGB(255, 210, 140)
kbStroke.Thickness = 2
kbStroke.Transparency = 0.2

local KickLbl = Instance.new("TextLabel", KickGui)
KickLbl.Size = UDim2.new(0, sc(64), 0, sc(12))
KickLbl.Position = UDim2.new(1, -sc(300), 1, -sc(152))
KickLbl.BackgroundTransparency = 1
KickLbl.Text = "FLING"
KickLbl.TextColor3 = C.text
KickLbl.Font = Enum.Font.GothamBold
KickLbl.TextSize = sc(9)

-- ============================================
--  АНИМАЦИЯ
-- ============================================
local function playAnimResolved(rawId, opts)
    opts = opts or {}
    local hum = getHum()
    if not hum then return nil end

    local finalId = "rbxassetid://" .. tostring(rawId)
    local ok, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(rawId))
    end)
    if ok and result and #result > 0 then
        local obj = result[1]
        if typeof(obj) == "Instance" and obj:IsA("Animation") and obj.AnimationId and obj.AnimationId ~= "" then
            finalId = obj.AnimationId
        end
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = finalId

    local success, track = pcall(function() return hum:LoadAnimation(anim) end)
    if not success or not track then return nil end

    track.Looped = opts.looped or false
    track.Priority = opts.priority or Enum.Priority.Action
    track:Play(opts.fadeIn or 0.1)
    if opts.speed and opts.speed ~= 1 then
        pcall(function() track:AdjustSpeed(opts.speed) end)
    end
    return track
end

local function startStandAnim()
    local idle = IDLE_LIST[currentIdleIndex]
    local track = playAnimResolved(idle.id, {
        looped = true,
        priority = Enum.AnimationPriority.Movement,
        fadeIn = 0.1,
    })
    if track then
        standTrack = track
        _G.JoJoAnimTrack = track
    end
end

local function stopStandAnim()
    if standTrack then
        pcall(function() standTrack:Stop(0.1) end)
        standTrack = nil
        _G.JoJoAnimTrack = nil
    end
end

local function updateIdleBtnVisual()
    local idle = IDLE_LIST[currentIdleIndex]
    IdleBtn.Text = "IDLE: " .. idle.name
end

-- ============================================
--  ПОИСК ВЛАДЕЛЬЦА
-- ============================================
local function findOwnerByNick(nick)
    if not nick or nick == "" then return nil end
    local lower = string.lower(nick)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            if string.lower(plr.Name) == lower or string.lower(plr.DisplayName) == lower then
                return plr
            end
        end
    end

    local matches = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local n = string.lower(plr.Name)
            local d = string.lower(plr.DisplayName)
            if string.sub(n, 1, #lower) == lower or string.sub(d, 1, #lower) == lower then
                table.insert(matches, plr)
            end
        end
    end

    if #matches == 0 then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local n = string.lower(plr.Name)
                local d = string.lower(plr.DisplayName)
                if string.find(n, lower, 1, true) or string.find(d, lower, 1, true) then
                    table.insert(matches, plr)
                end
            end
        end
    end

    if #matches > 0 then
        table.sort(matches, function(a, b)
            return string.lower(a.Name) < string.lower(b.Name)
        end)
        return matches[1]
    end

    return nil
end

-- ============================================
--  STUN / UNSTUN
-- ============================================
local function applyStun()
    local hum = getHum()
    if not hum then return end
    pcall(function()
        SAVED_WALK   = hum.WalkSpeed
        SAVED_JUMP   = hum.JumpPower
        SAVED_JUMP_H = hum.JumpHeight
    end)
    pcall(function() hum.WalkSpeed = 0 end)
    pcall(function() hum.JumpPower = 0 end)
    pcall(function() hum.JumpHeight = 0 end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false) end)
end

local function removeStun()
    local hum = getHum()
    if not hum then return end
    pcall(function() hum.WalkSpeed = SAVED_WALK end)
    pcall(function() hum.JumpPower = SAVED_JUMP end)
    pcall(function() hum.JumpHeight = SAVED_JUMP_H end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true) end)
end

-- ============================================
--  NOCLIP
-- ============================================
local noclipConn = nil
local function setNoclip(character, enabled)
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
        _G.JoJoNoclipConn = nil
    end
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end

    if not enabled then return end

    noclipConn = RunService.Stepped:Connect(function()
        if not character or not character.Parent then
            if noclipConn then
                noclipConn:Disconnect()
                noclipConn = nil
                _G.JoJoNoclipConn = nil
            end
            return
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    _G.JoJoNoclipConn = noclipConn
end

-- ============================================
--  ФЛИНГ
-- ============================================
local flingBV = nil
local flingBAV = nil
local flingLoopConn = nil
local flingForceField = nil

local function startPhysicsFling(character, targetRoot, dynamicAngularNoise)
    local root = getHRP()
    if not root then return end

    if flingBV then flingBV:Destroy() end
    if flingBAV then flingBAV:Destroy() end
    if flingLoopConn then flingLoopConn:Disconnect() end
    if flingForceField then flingForceField:Destroy() end

    flingForceField = Instance.new("ForceField")
    flingForceField.Name = "FlingForceField"
    flingForceField.Visible = FF_VISIBLE
    flingForceField.Parent = character

    setNoclip(character, true)

    flingBV = Instance.new("BodyVelocity")
    flingBV.Name = "FlingBV"
    flingBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flingBV.P = math.huge
    flingBV.Parent = root

    flingBAV = Instance.new("BodyAngularVelocity")
    flingBAV.Name = "FlingBAV"
    flingBAV.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flingBAV.P = math.huge
    flingBAV.AngularVelocity = Vector3.new(BASE_ANGULAR, BASE_ANGULAR, BASE_ANGULAR)
    flingBAV.Parent = root

    local angularNoise = dynamicAngularNoise or ANGULAR_NOISE_MIN

    flingLoopConn = RunService.RenderStepped:Connect(function()
        if not root or not root.Parent then return end
        if not targetRoot or not targetRoot.Parent then return end

        local offset = targetRoot.Position - root.Position
        local dist = offset.Magnitude

        local pullVel = Vector3.zero
        if dist > 0.01 then
            local speed = math.min(dist * PULL_STRENGTH, MAX_PULL_SPEED)
            pullVel = offset.Unit * speed
        end

        local smallNoise = Vector3.new(
            math.random(-LINEAR_NOISE, LINEAR_NOISE),
            math.random(-LINEAR_NOISE, LINEAR_NOISE),
            math.random(-LINEAR_NOISE, LINEAR_NOISE)
        )

        flingBV.Velocity = pullVel + smallNoise

        flingBAV.AngularVelocity = Vector3.new(
            math.random(-angularNoise, angularNoise),
            math.random(-angularNoise, angularNoise),
            math.random(-angularNoise, angularNoise)
        )
    end)
end

local function stopPhysicsFling(character)
    if flingLoopConn then
        flingLoopConn:Disconnect()
        flingLoopConn = nil
    end
    if flingBV then flingBV:Destroy() flingBV = nil end
    if flingBAV then flingBAV:Destroy() flingBAV = nil end
    if flingForceField then flingForceField:Destroy() flingForceField = nil end

    setNoclip(character, false)
end

-- ============================================
--  СТАН
-- ============================================
local stunConn = nil
local stunActive = false

local function startStun(character, lockCFrame)
    local root = getHRP()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root then return end

    if stunConn then stunConn:Disconnect() end
    stunActive = true

    root.CFrame = lockCFrame
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    if humanoid then
        humanoid.PlatformStand = true
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
    end

    stunConn = RunService.Heartbeat:Connect(function()
        if not stunActive then return end
        if not root or not root.Parent then return end

        root.CFrame = lockCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        if humanoid then
            humanoid.PlatformStand = true
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        end
    end)
end

local function stopStun(character)
    stunActive = false
    if stunConn then
        stunConn:Disconnect()
        stunConn = nil
    end
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.WalkSpeed = SAVED_WALK
            humanoid.JumpPower = SAVED_JUMP
            humanoid.JumpHeight = SAVED_JUMP_H
        end
    end
end

-- ============================================
--  ЛОГИКА СТЕНДА (follow)
-- ============================================
local followConn = nil
_G.JoJoStandConn = nil

local function disableStand(reason)
    standEnabled = false
    standOwner = nil
    stopStandAnim()
    if followConn then
        pcall(function() followConn:Disconnect() end)
        followConn = nil
        _G.JoJoStandConn = nil
    end

    removeStun()

    ToggleBtn.Text = "ВКЛЮЧИТЬ СТЕНД"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
    tbStroke.Color = C.green
    if reason then showWarn(reason) end
end

local function enableStand(owner)
    standEnabled = true
    standOwner = owner

    if not owner.Character or not owner.Character:FindFirstChild("HumanoidRootPart") then
        showWarn("У владельца нет персонажа")
        disableStand()
        return
    end

    startStandAnim()
    applyStun()

    ToggleBtn.Text = "ВЫКЛЮЧИТЬ СТЕНД"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 60)
    tbStroke.Color = C.red

    if autoFlingEnabled then
        nextFlingTime = tick() + autoFlingInterval
    end

    followConn = RunService.Heartbeat:Connect(function()
        if not standEnabled or not standOwner then return end
        if followPaused then return end

        local myHRP = getHRP()
        local myHum = getHum()
        if not myHRP or not myHum then return end

        pcall(function() myHum.WalkSpeed = 0 end)
        pcall(function() myHum.JumpPower = 0 end)
        pcall(function() myHum.JumpHeight = 0 end)

        if not standOwner.Parent then
            disableStand("Владелец вышел из игры")
            return
        end

        local ownerChar = standOwner.Character
        local ownerHRP = ownerChar and ownerChar:FindFirstChild("HumanoidRootPart")
        local ownerHum = ownerChar and ownerChar:FindFirstChildOfClass("Humanoid")

        if not ownerHRP or not ownerHum or ownerHum.Health <= 0 then
            disableStand("Владелец умер или потерял персонажа")
            return
        end

        local idle = IDLE_LIST[currentIdleIndex]
        local curRightOffset = idle.rightOffset

        local ownerCF = ownerHRP.CFrame
        local targetPos = ownerHRP.Position
            + ownerCF.RightVector * curRightOffset
            + (-ownerCF.LookVector) * OFFSET_BACK
            + Vector3.new(0, OFFSET_HEIGHT, 0)

        local finalCF
        if FACE_OWNER then
            finalCF = CFrame.lookAt(targetPos, ownerHRP.Position)
        else
            finalCF = CFrame.new(targetPos) * (ownerCF - ownerCF.Position)
        end

        myHRP.CFrame = finalCF

        pcall(function()
            myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end)
    end)
    _G.JoJoStandConn = followConn
end

-- ============================================
--  ПОИСК ЦЕЛИ ДЛЯ ФЛИНГА
-- ============================================
local function findFlingTarget(range)
    local myHRP = getHRP()
    if not myHRP then return nil end

    local best, bestDist = nil, range
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr ~= standOwner and plr.Character then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            local r = plr.Character:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then
                local d = (r.Position - myHRP.Position).Magnitude
                if d <= bestDist then
                    bestDist = d
                    best = plr
                end
            end
        end
    end
    return best
end

-- ============================================
--  ФЛИНГ-АТАКА
-- ============================================
local function doFlingAttack()
    if flingRunning then return end

    local myChar = LP.Character
    local myRoot = getHRP()
    local myHum = getHum()
    if not myRoot or not myHum then return end

    local target = findFlingTarget(FLING_RANGE)
    if not target then
        showWarn("Нет цели рядом")
        return
    end

    local targetChar = target.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        showWarn("Нет цели рядом")
        return
    end

    local distBeforeTP = (targetRoot.Position - myRoot.Position).Magnitude
    local distFactor = math.clamp(distBeforeTP / FLING_RANGE, 0, 1)
    local dynamicAngularNoise = ANGULAR_NOISE_MIN + (ANGULAR_NOISE_MAX - ANGULAR_NOISE_MIN) * distFactor

    flingRunning = true
    followPaused = true

    local originalVel = myRoot.AssemblyLinearVelocity

    myRoot.CFrame = targetRoot.CFrame
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.02)

    startPhysicsFling(myChar, targetRoot, dynamicAngularNoise)
    task.wait(FLING_DURATION)

    stopPhysicsFling(myChar)

    local returnCFrame
    if targetRoot and targetRoot.Parent then
        local targetPos = targetRoot.Position
        local myPos = myRoot.Position
        local dir = myPos - targetPos
        if dir.Magnitude < 0.01 then
            dir = Vector3.new(1, 0, 0)
        else
            dir = dir.Unit
        end
        returnCFrame = CFrame.new(targetPos + dir * RETURN_DISTANCE)
    else
        returnCFrame = CFrame.new(myRoot.Position)
    end

    startStun(myChar, returnCFrame)
    task.wait(STUN_DURATION)
    stopStun(myChar)

    myRoot.AssemblyLinearVelocity = originalVel
    myRoot.AssemblyAngularVelocity = Vector3.zero

    if standEnabled and standOwner and standOwner.Character then
        local ownerHRP = standOwner.Character:FindFirstChild("HumanoidRootPart")
        if ownerHRP then
            local startCF = myRoot.CFrame
            local returnStart = tick()

            while tick() - returnStart < RETURN_TIME do
                local myR = getHRP()
                if not myR then break end
                if not standEnabled or not standOwner or not standOwner.Character then break end

                local oHRP = standOwner.Character:FindFirstChild("HumanoidRootPart")
                if not oHRP then break end

                local idle = IDLE_LIST[currentIdleIndex]
                local curRightOffset = idle.rightOffset

                local ownerCF = oHRP.CFrame
                local targetPos2 = oHRP.Position
                    + ownerCF.RightVector * curRightOffset
                    + (-ownerCF.LookVector) * OFFSET_BACK
                    + Vector3.new(0, OFFSET_HEIGHT, 0)
                local finalCF = CFrame.new(targetPos2) * (ownerCF - ownerCF.Position)

                local p = (tick() - returnStart) / RETURN_TIME
                local eased = p * p * (3 - 2 * p)

                myR.CFrame = startCF:Lerp(finalCF, eased)
                pcall(function() myR.AssemblyLinearVelocity = Vector3.zero end)
                pcall(function() myR.AssemblyAngularVelocity = Vector3.zero end)

                task.wait()
            end
        end
    end

    flingRunning = false
    followPaused = false
end

-- ============================================
--  АВТОФЛИНГ
-- ============================================
local function stopAutoFlingLoop()
    _G.JoJoAutoThread = nil
end

local function startAutoFlingLoop()
    if _G.JoJoAutoThread then return end
    local threadToken = {}
    _G.JoJoAutoThread = threadToken

    nextFlingTime = tick() + autoFlingInterval

    task.spawn(function()
        while _G.JoJoAutoThread == threadToken do
            local interval = autoFlingInterval
            if interval < 0.2 then interval = 0.2 end

            task.wait(interval)
            if _G.JoJoAutoThread ~= threadToken then break end
            if not autoFlingEnabled then break end

            nextFlingTime = tick() + interval

            if not standEnabled then
                continue
            end
            if flingRunning then
                continue
            end

            task.spawn(function()
                doFlingAttack()
            end)
        end
    end)
end

-- ============================================
--  ТАЙМЕР
-- ============================================
local function startTimerLoop()
    if _G.JoJoTimerThread then return end
    local token = {}
    _G.JoJoTimerThread = token

    task.spawn(function()
        while _G.JoJoTimerThread == token do
            if autoFlingEnabled then
                if not standEnabled then
                    TimerLbl.Text = "Ожидание включения стенда..."
                    TimerLbl.TextColor3 = C.sub
                elseif flingRunning then
                    TimerLbl.Text = "Флинг выполняется..."
                    TimerLbl.TextColor3 = C.gold
                else
                    local remain = nextFlingTime - tick()
                    if remain < 0 then remain = 0 end
                    TimerLbl.Text = string.format("Следующий флинг через: %.1f сек", remain)
                    TimerLbl.TextColor3 = C.gold
                end
            else
                TimerLbl.Text = "AUTOFLING выключен"
                TimerLbl.TextColor3 = C.sub
            end
            task.wait(0.1)
        end
    end)
end

-- ============================================
--  КНОПКА FLING (ручная)
-- ============================================
KickBtn.MouseButton1Click:Connect(function()
    doFlingAttack()
end)

-- ============================================
--  КНОПКА IDLE (переключение)
-- ============================================
IdleBtn.MouseButton1Click:Connect(function()
    currentIdleIndex = currentIdleIndex + 1
    if currentIdleIndex > #IDLE_LIST then
        currentIdleIndex = 1
    end

    updateIdleBtnVisual()

    if standEnabled then
        stopStandAnim()
        startStandAnim()
    end
end)

-- ============================================
--  КНОПКА AUTOFLING
-- ============================================
local function updateAutoBtnVisual()
    if autoFlingEnabled then
        AutoBtn.Text = "AUTOFLING: ВКЛ"
        AutoBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
        abStroke.Color = C.green
        abStroke.Transparency = 0.2
    else
        AutoBtn.Text = "AUTOFLING: ВЫКЛ"
        AutoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        abStroke.Color = C.line
        abStroke.Transparency = 0
    end
end

AutoBtn.MouseButton1Click:Connect(function()
    autoFlingEnabled = not autoFlingEnabled
    updateAutoBtnVisual()

    if autoFlingEnabled then
        startAutoFlingLoop()
    else
        stopAutoFlingLoop()
    end
end)

IntBox.FocusLost:Connect(function()
    local val = tonumber(IntBox.Text)
    if val and val >= 0.2 then
        autoFlingInterval = val
        IntBox.Text = tostring(val)
        if autoFlingEnabled then
            stopAutoFlingLoop()
            startAutoFlingLoop()
        end
    else
        IntBox.Text = tostring(autoFlingInterval)
    end
end)

-- ============================================
--  КНОПКА СТЕНДА
-- ============================================
ToggleBtn.MouseButton1Click:Connect(function()
    if standEnabled then
        disableStand()
        return
    end

    local nick = NickBox.Text
    if not nick or nick == "" then
        showWarn("Впиши ник владельца")
        return
    end

    if string.lower(nick) == string.lower(LP.Name) or string.lower(nick) == string.lower(LP.DisplayName) then
        showWarn("Нельзя вписывать себя")
        return
    end

    local owner = findOwnerByNick(nick)
    if not owner then
        showWarn("Игрок не найден")
        return
    end

    enableStand(owner)
end)

-- ============================================
--  РЕСПАВН
-- ============================================
LP.CharacterAdded:Connect(function()
    if standEnabled then
        task.wait(1)
        if standEnabled then
            applyStun()
            startStandAnim()
        end
    end
end)

-- ============================================
--  СТАРТ
-- ============================================
updateAutoBtnVisual()
updateIdleBtnVisual()
startTimerLoop()

print("[JoJo Stand + Fling + AUTOFLING + IDLE] готово")
