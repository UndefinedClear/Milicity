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
