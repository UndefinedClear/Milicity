local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- НАСТРОЙКИ УПРАВЛЕНИЯ И AFK
local speed = 50          -- Скорость ручного полета
local flying = false       -- Полет выключен на старте
local isNoclip = false     -- Ноуклип выключен на старте
local isRunning = false    -- Статус AFK-цикла (выключен)
local COOLDOWN = 3         -- Задержка на каждой точке в AFK (в секундах)

-- ТАБЛИЦА ДЛЯ ВАШИХ КООРДИНАТ (вставьте сюда свои точки, когда соберете)
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

-- ОЧИСТКА ПРЕДЫДУЩИХ ЗАПУСКОВ (чтобы координаты не дублировались)
if _G.DebugInputConnection then
    _G.DebugInputConnection:Disconnect()
    _G.DebugInputConnection = nil
    print("[Система] Предыдущие привязки клавиш очищены.")
end

-- Создаем физическую силу для удержания в воздухе (ручной полет)
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

    -- Ноуклип: отключаем коллизию каждый кадр, если он включен
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

    -- Расчет направления ручного полета относительно камеры (W,A,S,D, Space, Shift)
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
        
        -- Логика ресета после прохождения всех точек
        if isRunning and character and character:FindFirstChildOfClass("Humanoid") then
            print("[AFK] Круг пройден. Перезагрузка персонажа...")
            character:FindFirstChildOfClass("Humanoid").Health = 0
            
            player.CharacterAdded:Wait() -- Ждем появления нового тела
            task.wait(1.5) -- Небольшая пауза для прогрузки физики
        end
    end
end

-- Единый обработчик кнопок (сохраняется в глобальную переменную)
_G.DebugInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    
    -- [E] Сбор координат
    if input.KeyCode == Enum.KeyCode.E then
        local currentRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if currentRoot then
            print(string.format("Vector3.new(%.2f, %.2f, %.2f),", currentRoot.Position.X, currentRoot.Position.Y, currentRoot.Position.Z))
        end
    
    -- [L] Переключение Ноуклипа
    elseif input.KeyCode == Enum.KeyCode.L then
        isNoclip = not isNoclip
        print("[Дебаг] Ноуклип:", isNoclip and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН")
        
    -- [P] Переключение Полета
    elseif input.KeyCode == Enum.KeyCode.P then
        flying = not flying
        print("[Дебаг] Полет:", flying and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН")

    -- [J] Включение / Выключение AFK-цикла
    elseif input.KeyCode == Enum.KeyCode.J then
        isRunning = not isRunning
        if isRunning then
            -- При запуске AFK автоматически отключаем ручной полет, чтобы физика не конфликтовала
            flying = false 
            print("[AFK] Авто-цикл ЗАПУЩЕН.")
            task.spawn(startAfkCycle)
        else
            print("[AFK] Авто-цикл ОСТАНОВЛЕН. Завершение текущего круга...")
        end
    end
end)

print("=======================================================")
print(" ПОЛНЫЙ СКРИПТ ОТЛАДКИ УСПЕШНО ЗАПУЩЕН")
print(" [P] - Вкл/Выкл полет | [L] - Вкл/Выкл ноуклип")
print(" [E] - Скопировать текущую точку в лог")
print(" [J] - Стартовать/Остановить автоматический AFK-цикл")
print("=======================================================")




local milicity = loadstring(game:HttpGet("https://raw.githubusercontent.com/UndefinedClear/Milicity/refs/heads/main/milicity.lua"))()


-- Создаем кастомную тему (например, неоновую)
local neonTheme = {
    CornerRadius = 10,
    WindowBackground = Color3.fromRGB(15, 15, 20),
    TitleText = Color3.fromRGB(0, 255, 150), -- Зеленый неон
    ButtonBackground = Color3.fromRGB(30, 30, 35),
    ButtonHover = Color3.fromRGB(0, 255, 150),
    ButtonText = Color3.fromRGB(255, 255, 255),
    TriggerBackground = Color3.fromRGB(0, 255, 150)
}

-- Инициализируем меню через нашу же либу, которая объявлена выше
local menu = milicity.new("МЕНЮ МОНИТОРИНГА", neonTheme)

-- 2. Добавляем текстовый лейбл для отображения статуса (сохраняем в переменную statusLabel)
local statusLabel = menu:AddLabel("Статус: Ожидание действий", {
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor = Color3.fromRGB(255, 230, 0) -- Сделаем его изначально желтым
})

-- 3. Добавляем второй лейбл для вывода координат (выровняем его по левому краю)
local coordsLabel = menu:AddLabel("Координаты: не зафиксированы", {
    TextXAlignment = Enum.TextXAlignment.Left,
    Height = 40 -- Дадим больше высоты для двух строк
})

-- Переменная для демонстрации изменения статуса полета
local isFlying = false

-- 4. Кнопка переключения полета
menu:AddButton("Переключить Полет", function()
    isFlying = not isFlying
    
    -- Динамически меняем текст и цвет лейбла в зависимости от состояния!
    if isFlying then
        statusLabel:SetText("Статус: ПОЛЕТ АКТИВИРОВАН")
        statusLabel:SetColor(Color3.fromRGB(0, 255, 100)) -- Зеленый
    else
        statusLabel:SetText("Статус: ПОЛЕТ ОТКЛЮЧЕН")
        statusLabel:SetColor(Color3.fromRGB(255, 50, 50)) -- Красный
    end
end)

-- 5. Кнопка сбора координат
menu:AddButton("Зафиксировать точку [E]", function()
    local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local currentPos = root.Position
        local formattedCoords = string.format("X: %.2f\nY: %.2f | Z: %.2f", currentPos.X, currentPos.Y, currentPos.Z)
        
        -- Выводим координаты прямо на экран в наше меню!
        coordsLabel:SetText("Координаты:\n" .. formattedCoords)
        coordsLabel:SetColor(Color3.fromRGB(255, 255, 255))
        coordsLabel:SetFont(Enum.Font.Code) -- Изменим шрифт на "программистский моноширинный"
    end
end)
