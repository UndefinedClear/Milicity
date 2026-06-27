-- =======================================================
-- БЕЗОПАСНОЕ ПОДКЛЮЧЕНИЕ ИНТЕРФЕЙСА (Milicity UI)
-- =======================================================
local success, milicityCode = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/UndefinedClear/Milicity/refs/heads/main/milicity_beta.lua")
end)

if not success or not milicityCode or milicityCode == "" then
    error("[Ошибка] Не удалось скачать интерфейс Milicity. Проверь ссылку или интернет!")
end

local milicityFunc, compileError = loadstring(milicityCode)
if not milicityFunc then
    error("[Ошибка компиляции UI]: " .. tostring(compileError))
end

local milicity = milicityFunc()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- НАСТРОЙКИ
local walksspeedVar = 16
local isWalkSpeed = false
local speed = 50
local flying = false
local isNoclip = false
local isRunning = false
local isInvisible = false
local COOLDOWN = 3

-- Ссылки на UI
local flyToggleUi, noclipToggleUi, afkToggleUi, coordsLabelUi, invisToggleUi, walkspeedToggleUi

-- ТАБЛИЦА КООРДИНАТ АВТО-ФАРМА
local points = {
    Vector3.new(145.55, -2.49, 1049.40),
    Vector3.new(101.13, 49.31, 1391.92),
    Vector3.new(88.01, 66.84, 2189.84),
    Vector3.new(106.06, 88.49, 2936.96),
    Vector3.new(103.36, 64.09, 3700.57),
    Vector3.new(101.43, 61.81, 4505.56),
    Vector3.new(84.62, 40.19, 5280.32),
    Vector3.new(101.02, 35.91, 6397.15),
    Vector3.new(105.98, 113.97, 7323.42),
    Vector3.new(174.08, 52.33, 7699.65),
    Vector3.new(-50.83, -357.62, 9501.02)
}

local teams_spawn_points = {
    white = Vector3.new(-49.85, -9.70, -503.81),  --
    blue = Vector3.new(393.68, -9.70, 299.99),    --
    green = Vector3.new(-488.69, -9.70, 291.89),  --
    red = Vector3.new(395.30, -9.70, -65.12),     --
    black = Vector3.new(-492.44, -9.66, -69.22),  --
    yellow = Vector3.new(-494.97, -9.70, 640.62), --
    magenta = Vector3.new(381.62, -9.70, 647.55), --
}

-- ОЧИСТКА СТАРЫХ ПОДКЛЮЧЕНИЙ
if _G.DebugInputConnection then _G.DebugInputConnection:Disconnect() end
if _G.FlyConnection then _G.FlyConnection:Disconnect() end
if _G.EffectsConnection then _G.EffectsConnection:Disconnect() end

-- =======================================================
-- ФУНКЦИИ ЭФФЕКТОВ
-- =======================================================
local function applyInvisibility(state)
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if state then
                part.Transparency = 0.99
                part.LocalTransparencyModifier = -0.50
            else
                part.Transparency = 0
                part.LocalTransparencyModifier = 0
            end
        end
    end
end

local function applyNoclip(state)
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

-- =======================================================
-- ОСНОВНОЙ ЦИКЛ (ВСЁ В ОДНОМ МЕСТЕ — ПОЛЁТ + ЭФФЕКТЫ)
-- =======================================================
_G.FlyConnection = RunService.Stepped:Connect(function()
    local character = player.Character
    if not character or not character.Parent then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root.Parent then return end
    
    local hum = character:FindFirstChildOfClass("Humanoid")
    
    -- === ПОЛЁТ ===
    local bv = root:FindFirstChildOfClass("BodyVelocity")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(0, 0, 0)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = root
    end
    
    if not flying then
        bv.MaxForce = Vector3.new(0, 0, 0)
        bv.Velocity = Vector3.new(0, 0, 0)
    else
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        
        local moveDirection = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

        if moveDirection.Magnitude > 0 then
            bv.Velocity = moveDirection.Unit * speed
        else
            bv.Velocity = Vector3.new(0, 0, 0)
        end
    end
    
    -- === WALKSPEED ===
    if isWalkSpeed and hum then
        hum.WalkSpeed = walksspeedVar
    end
end)

-- Цикл эффектов (ноуклип + невидимость)
_G.EffectsConnection = RunService.Heartbeat:Connect(function()
    if isNoclip then applyNoclip(true) end
    if isInvisible then applyInvisibility(true) end
end)

local function teleport(_player, vector3)
    local char = _player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if root and root.Parent then
        root.CFrame = CFrame.new(vector3)
        print(string.format("[TP] Телепорт на точку %d: %s", i, tostring(vector3)))
    end
end

-- =======================================================
-- AFK И КООРДИНАТЫ
-- =======================================================
local function startAfkCycle()
    while isRunning do
        for i, targetPos in ipairs(points) do
            if not isRunning then break end
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and root.Parent then
                root.CFrame = CFrame.new(targetPos)
                print(string.format("[AFK] Телепорт на точку %d: %s", i, tostring(targetPos)))
            end
            task.wait(COOLDOWN)
        end
        
        if isRunning then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                print("[AFK] Круг пройден. Перезагрузка персонажа...")
                -- hum.Health = 0
                player.CharacterAdded:Wait()
                task.wait(5)
            end
        end
    end
end

local function recordCoordinates()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local pos = root.Position
        print(string.format("Vector3.new(%.2f, %.2f, %.2f),", pos.X, pos.Y, pos.Z))
        if coordsLabelUi then
            coordsLabelUi:SetText(string.format("Последняя точка:\nX: %.2f\nY: %.2f | Z: %.2f", pos.X, pos.Y, pos.Z))
        end
    end
end

-- =======================================================
-- УПРАВЛЕНИЕ С КЛАВИАТУРЫ
-- =======================================================
_G.DebugInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    
    if input.KeyCode == Enum.KeyCode.E then
        recordCoordinates()

    elseif input.KeyCode == Enum.KeyCode.L then
        isNoclip = not isNoclip
        applyNoclip(isNoclip)
        if noclipToggleUi then noclipToggleUi:SetValue(isNoclip) end
        print("[Дебаг] Ноуклип:", isNoclip and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН")

    elseif input.KeyCode == Enum.KeyCode.P then
        flying = not flying
        if flyToggleUi then flyToggleUi:SetValue(flying) end
        print("[Дебаг] Полет:", flying and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН")

    elseif input.KeyCode == Enum.KeyCode.M then
        isInvisible = not isInvisible
        applyInvisibility(isInvisible)
        if invisToggleUi then invisToggleUi:SetValue(isInvisible) end
        print("[Дебаг] Невидимость:", isInvisible and "ВКЛЮЧЕНА" or "ВЫКЛЮЧЕНА")

    elseif input.KeyCode == Enum.KeyCode.J then
        isRunning = not isRunning
        if isRunning then flying = false end
        if afkToggleUi then afkToggleUi:SetValue(isRunning) end
        if flyToggleUi and not flying then flyToggleUi:SetValue(false) end
        if isRunning then
            print("[AFK] Авто-цикл ЗАПУЩЕН.")
            task.spawn(startAfkCycle)
        else
            print("[AFK] Авто-цикл ОСТАНОВЛЕН.")
        end
    end
end)

-- =======================================================
-- ИНТЕРФЕЙС (Milicity UI)
-- =======================================================
local neonTheme = {
    CornerRadius = 10,
    WindowBackground = Color3.fromRGB(15, 15, 20),
    TitleText = Color3.fromRGB(0, 255, 150),
    ButtonBackground = Color3.fromRGB(30, 30, 35),
    ButtonHover = Color3.fromRGB(0, 255, 150),
    ButtonText = Color3.fromRGB(255, 255, 255),
    TriggerBackground = Color3.fromRGB(0, 255, 150)
}

local config = {
    titleText = "МЕНЮ РАЗРАБОТЧИКА",
	customTheme = neonTheme,
    menuOpenByKey = true,
	menuOpenButtonText = "BABFT"
}


local menu = milicity.new(config)

menu:AddLabel("Управление читом и AFK-ботом", {
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor = Color3.fromRGB(0, 255, 150)
})

coordsLabelUi = menu:AddLabel("Координаты: не зафиксированы", {
    TextXAlignment = Enum.TextXAlignment.Left,
    Height = 40,
    Font = Enum.Font.Code
})

flyToggleUi = menu:AddToggle("Режим полета [P]", flying, function(state)
    flying = state
    print("[UI] Полет:", flying)
end)

noclipToggleUi = menu:AddToggle("Ноуклип (Сквозь стены) [L]", isNoclip, function(state)
    isNoclip = state
    applyNoclip(isNoclip)
    print("[UI] Ноуклип:", isNoclip)
end)

invisToggleUi = menu:AddToggle("Невидимость для других [M]", isInvisible, function(state)
    isInvisible = state
    applyInvisibility(isInvisible)
    print("[UI] Невидимость:", isInvisible)
end)

afkToggleUi = menu:AddToggle("Авто AFK-цикл [J]", isRunning, function(state)
    isRunning = state
    if isRunning then
        print("[UI] AFK запущен.")
        task.spawn(startAfkCycle)
    else
        print("[UI] AFK остановлен.")
    end
end)

menu:AddButton("Зафиксировать точку [E]", recordCoordinates)

menu:AddButton("Востановить здоровье", function()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = humanoid.MaxHealth
    end
end)

menu:AddButton("Бессмертие (God Mode)", function()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
    end
end)

menu:AddTextBox("Скорость полета (дефолт: 50)...", function(text)
    local n = tonumber(text)
    if n then speed = n print("[Система] Скорость полета:", speed)
    else print("[Ошибка] Введите число!") end
end)

menu:AddTextBox("WalkSpeed (дефолт: 16)...", function(text)
    local n = tonumber(text)
    if n then walksspeedVar = n print("[Система] WalkSpeed:", walksspeedVar)
    else print("[Ошибка] Введите число!") end
end)


walkspeedToggleUi = menu:AddToggle("Цикл WalkSpeed", isWalkSpeed, function(state)
    isWalkSpeed = state
    if state == false then
        hum.WalkSpeed = 16        
    end
end)

-- =======================================================
-- TEAM SWITCHER (отдельные кнопки для каждой команды)
-- =======================================================
local teams = game:GetService("Teams")
if #teams:GetChildren() > 0 then
    menu:AddLabel("=== СМЕНА КОМАНДЫ ===", {
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor = Color3.fromRGB(255, 200, 0)
    })
    
    for _, team in ipairs(teams:GetChildren()) do
        menu:AddButton("В команду: " .. team.Name, function()
            player.Team = team
            print("[Team Switcher] Перешёл в:", team.Name)
        end)
    end
end

menu:AddLabel("Телепорт по командам", {
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor = Color3.fromRGB(0, 255, 150)
})

-- ИСПРАВЛЕНО (цикл for):
for k, v in pairs(teams_spawn_points) do  -- добавлено pairs()
    menu:AddButton("Команда: " .. k, function()
        teleport(player, v)
        print("[Team TP] Перешёл в:", k)
    end)
end

-- menu:AddButton("Бессмертие (God Mode)", function()
--     local character = player.Character
--     local humanoid = character and character:FindFirstChildOfClass("Humanoid")
--     if humanoid then
--         humanoid.MaxHealth = math.huge
--         humanoid.Health = math.huge
--     end
-- end)

-- local blockDamage = false

-- menu:AddToggle("Блокировка урона", blockDamage, function(state)
--     blockDamage = state
--     if state then
--         local character = player.Character
--         local humanoid = character and character:FindFirstChildOfClass("Humanoid")
--         if humanoid then
--             humanoid.HealthChanged:Connect(function(health)
--                 if blockDamage and health < humanoid.MaxHealth then
--                     humanoid.Health = humanoid.MaxHealth
--                 end
--             end)
--         end
--     end
-- end)

menu:AddButton("Dexplorer", function()
    milicity.Dexplorer()
end)
menu:AddDestroyButton("Закрыть и очистить память", Color3.fromRGB(200, 50, 50), function() 
    if _G.DebugInputConnection then
        _G.DebugInputConnection:Disconnect()
        _G.DebugInputConnection = nil
    end
end)
-- beforeDestroy
print("=======================================================")
print(" ИНТЕРФЕЙС ИНИЦИАЛИЗИРОВАН")
print(" [H] Меню | [P] Полёт | [M] Невидимость")
print(" [L] Ноуклип | [J] AFK | [E] Координаты")
print("=======================================================")