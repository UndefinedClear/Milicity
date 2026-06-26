-- =======================================================
-- БЕЗОПАСНОЕ ПОДКЛЮЧЕНИЕ ИНТЕРФЕЙСА (Milicity UI)
-- =======================================================
local success, milicityCode = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/UndefinedClear/Milicity/refs/heads/main/milicity.lua")
end)

if not success or not milicityCode or milicityCode == "" then
    error("[Ошибка] Не удалось скачать интерфейс Milicity. Проверь ссылку или интернет!")
end

local milicityFunc, compileError = loadstring(milicityCode)
if not milicityFunc then
    error("[Ошибка компиляции UI]: " .. tostring(compileError))
end

local milicity = milicityFunc() -- Успешно запускаем библиотеку
-- after loading

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hum = character.Humanoid
local root = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- НАСТРОЙКИ УПРАВЛЕНИЯ И AFK
local speed = 50          -- Скорость ручного полета
local flying = false       -- Полет выключен на старте
local isNoclip = false     -- Ноуклип выключен на старте
local isRunning = false    -- Статус AFK-цикла (выключен)


local isSpeedEnabled = false    -- Статус Speed-цикла (выключен)


local COOLDOWN = 3         -- Задержка на каждой точке в AFK (в секундах)

-- Ссылки на UI-элементы для синхронизации кнопок и хоткеев
local flyToggleUi = nil
local noclipToggleUi = nil
local afkToggleUi = nil
local coordsLabelUi = nil

-- ТАБЛИЦА ДЛЯ ВАШИХ КООРДИНАТ
local points = {
    Vector3.new(45.44, -11.91, -556.59),
    Vector3.new(54.60, -12.48, -457.42),
    Vector3.new(-200.52, 103.80, 1386.79)
}

-- Автоматическое обновление ссылок при ресете или спавне
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    root = character:WaitForChild("HumanoidRootPart")
end)

-- ОЧИСТКА ПРЕДЫДУЩИХ ЗАПУСКОВ
if _G.DebugInputConnection then
    _G.DebugInputConnection:Disconnect()
    _G.DebugInputConnection = nil
    print("[Система] Предыдущие привязки клавиш очищены.")
end

-- Создаем физическую силу для удержания в воздухе
local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.Velocity = Vector3.new(0, 0, 0)
bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
bodyVelocity.Parent = root

-- Основной цикл обработки физики и движения (Stepped)
local connection
connection = RunService.Stepped:Connect(function()
    if not character or not character.Parent then
        bodyVelocity:Destroy()
        connection:Disconnect()
        return
    end

    -- Ноуклип: отключаем коллизию каждый кадр
    if isNoclip == true then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- Управление силой полета
    if not flying then
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
        return 
    else
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    end

    -- Расчет направления ручного полета относительно камеры
    local moveDirection = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

    if moveDirection.Magnitude > 0 then
        bodyVelocity.Velocity = moveDirection.Unit * speed
    else
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
end)

-- Функция автоматического AFK-цикла
local function startAfkCycle()
    while isRunning do
        for i, targetPos in ipairs(points) do
            if not isRunning then break end
            
            if root and root.Parent then
                root.CFrame = CFrame.new(targetPos)
                print(string.format("[AFK] Телепорт на точку %d: %s", i, tostring(targetPos)))
            end
            task.wait(COOLDOWN)
        end
        
        if isRunning and character and character:FindFirstChildOfClass("Humanoid") then
            print("[AFK] Круг пройден. Перезагрузка персонажа...")
            character:FindFirstChildOfClass("Humanoid").Health = 0
            
            player.CharacterAdded:Wait()
            task.wait(1.5)
        end
    end
end

-- Функция фиксации координат (вынесена отдельно для вызова из UI и клавиатуры)
local function recordCoordinates()
    local currentRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if currentRoot then
        local pos = currentRoot.Position
        -- Печать в консоль формата для вставки в скрипт
        print(string.format("Vector3.new(%.2f, %.2f, %.2f),", pos.X, pos.Y, pos.Z))
        
        -- Обновление UI лейбла, если он существует
        if coordsLabelUi then
            local formatted = string.format("X: %.2f\nY: %.2f | Z: %.2f", pos.X, pos.Y, pos.Z)
            coordsLabelUi:SetText("Последняя точка:\n" .. formatted)
        end
    end
end

-- Единый обработчик кнопок (Клавиатура)
_G.DebugInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    
    -- [E] Сбор координат
    if input.KeyCode == Enum.KeyCode.E then
        recordCoordinates()
    
    -- [L] Переключение Ноуклипа
    elseif input.KeyCode == Enum.KeyCode.L then
        isNoclip = not isNoclip
        if noclipToggleUi then noclipToggleUi:SetValue(isNoclip) end -- Синхронизируем тумблер в GUI
        print("[Дебаг] Ноуклип:", isNoclip and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН")
        
    -- [P] Переключение Полета
    elseif input.KeyCode == Enum.KeyCode.P then
        flying = not flying
        if flyToggleUi then flyToggleUi:SetValue(flying) end -- Синхронизируем тумблер в GUI
        print("[Дебаг] Полет:", flying and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН")

    -- [J] Включение / Выключение AFK-цикла
    elseif input.KeyCode == Enum.KeyCode.J then
        isRunning = not isRunning
        if isRunning then flying = false end
        
        -- Синхронизируем GUI
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
-- ИНИЦИАЛИЗАЦИЯ И НАСТРОЙКА ИНТЕРФЕЙСА (Milicity UI)
-- =======================================================

local neonTheme = {
    CornerRadius = 10,
    WindowBackground = Color3.fromRGB(15, 15, 20),
    TitleText = Color3.fromRGB(0, 255, 150), -- Зеленый неон
    ButtonBackground = Color3.fromRGB(30, 30, 35),
    ButtonHover = Color3.fromRGB(0, 255, 150),
    ButtonText = Color3.fromRGB(255, 255, 255),
    TriggerBackground = Color3.fromRGB(0, 255, 150)
}

local menu = milicity.new("МЕНЮ РАЗРАБОТЧИКА", neonTheme)

-- Информационные лейблы
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

-- Использование iOS-Toggle элементов из фреймворка
-- state возвращает true/false при клике на свитч

-- 1. Тумблер полета
flyToggleUi = menu:AddToggle("Режим полета [P]", flying, function(state)
    flying = state
    print("[UI] Полет изменен на:", flying)
end)

-- 2. Тумблер ноуклипа
noclipToggleUi = menu:AddToggle("Ноуклип (Сквозь стены) [L]", isNoclip, function(state)
    isNoclip = state
    print("[UI] Ноуклип изменен на:", isNoclip)
end)

-- 3. Тумблер AFK-фарма
afkToggleUi = menu:AddToggle("Авто AFK-цикл [J]", isRunning, function(state)
    isRunning = state
    if isRunning then
        flying = false
        if flyToggleUi then flyToggleUi:SetValue(false) end -- Отключаем полет в UI, чтобы не конфликтовал
        print("[UI] AFK запущен.")
        task.spawn(startAfkCycle)
    else
        print("[UI] AFK остановлен.")
    end
end)

-- Кнопки действий
menu:AddButton("Зафиксировать точку [E]", function()
    recordCoordinates()
end)

-- Поле изменения скорости (Используем TextBox фреймворка)
local speedInput = menu:AddTextBox("Скорость полета (дефолт: 50)...", function(text, enterPressed)
    local targetSpeed = tonumber(text)
    if targetSpeed then
        speed = targetSpeed
        print("[Система] Скорость полета изменена на: " .. speed)
    else
        print("[Ошибка] Введите корректное число!")
    end
end)

-- Кнопка полной выгрузки скрипта и UI из памяти игры
menu:AddDestroyButton("Закрыть и очистить память", Color3.fromRGB(200, 50, 50))

print("=======================================================")
print(" СУПЕР-ИНТЕРФЕЙС УСПЕШНО ИНИЦИАЛИЗИРОВАН")
print(" Переключение меню на клавишу [H] (задано в фреймворке)")
print("=======================================================")