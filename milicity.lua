local SimpleUI = {}
SimpleUI.__index = SimpleUI

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- ТЕМА ПО УМОЛЧАНИЮ (Дефолтные настройки цветов и скруглений)
local DefaultTheme = {
	-- Скругления углов (в пикселях)
	CornerRadius = 8,
	ButtonCornerRadius = 5,
	
	-- Цвета главного окна
	WindowBackground = Color3.fromRGB(30, 30, 30),
	TitleText = Color3.fromRGB(255, 255, 255),
	CloseButtonBackground = Color3.fromRGB(45, 45, 45),
	CloseButtonText = Color3.fromRGB(200, 200, 200),
	
	-- Цвета кнопок в меню
	ButtonBackground = Color3.fromRGB(45, 45, 45),
	ButtonHover = Color3.fromRGB(60, 60, 60),
	ButtonClick = Color3.fromRGB(0, 120, 215),
	ButtonText = Color3.fromRGB(230, 230, 230),
	
	-- Цвета плавающей кнопки "UI"
	TriggerBackground = Color3.fromRGB(0, 120, 215),
	TriggerText = Color3.fromRGB(255, 255, 255)
}

-- КОНСТРУКТОР: Создание главного контейнера
-- customTheme — необязательная таблица с вашими цветами
function SimpleUI.new(titleText, customTheme)
	local self = setmetatable({}, SimpleUI)
	
	-- Сливаем кастомную тему с дефолтной (если каких-то полей нет, берутся дефолтные)
	self.Theme = DefaultTheme
	if customTheme and type(customTheme) == "table" then
		for key, value in pairs(customTheme) do
			self.Theme[key] = value
		end
	end
	
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SimpleUI_Debugger"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	self.ScreenGui = screenGui
	
	self.IsVisible = true
	
	-- ==========================================
	-- ГЛАВНОЕ ОКНО
	-- ==========================================
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 250, 0, 350)
	mainFrame.Position = UDim2.new(0, 50, 0.5, -175)
	mainFrame.BackgroundColor3 = self.Theme.WindowBackground -- Настройка цвета окна
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	self.MainFrame = mainFrame
	
	-- Настройка скругления окна
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, self.Theme.CornerRadius)
	uiCorner.Parent = mainFrame
	
	-- Заголовок окна
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText or "DEBUG MENU"
	title.TextColor3 = self.Theme.TitleText -- Настройка цвета текста заголовка
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = mainFrame
	
	-- Кнопка закрытия (крестик)
	local closeMenuBtn = Instance.new("TextButton")
	closeMenuBtn.Size = UDim2.new(0, 30, 0, 30)
	closeMenuBtn.Position = UDim2.new(1, -35, 0, 5)
	closeMenuBtn.BackgroundColor3 = self.Theme.CloseButtonBackground -- Настройка цвета кнопки закрытия
	closeMenuBtn.Text = "X"
	closeMenuBtn.TextColor3 = self.Theme.CloseButtonText
	closeMenuBtn.Font = Enum.Font.GothamBold
	closeMenuBtn.TextSize = 12
	closeMenuBtn.BorderSizePixel = 0
	closeMenuBtn.Parent = mainFrame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, self.Theme.ButtonCornerRadius) -- Скругление крестика
	closeCorner.Parent = closeMenuBtn
	
	-- Контейнер для кнопок
	local contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(1, 0, 1, -45)
	contentFrame.Position = UDim2.new(0, 0, 0, 45)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainFrame
	self.ContentFrame = contentFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = contentFrame
	
	-- ==========================================
	-- ПЛАВАЮЩАЯ КНОПКА ОТКРЫТИЯ (ТРИГГЕР)
	-- ==========================================
	local openButton = Instance.new("TextButton")
	openButton.Size = UDim2.new(0, 50, 0, 50)
	openButton.Position = UDim2.new(0, 50, 0, 50)
	openButton.BackgroundColor3 = self.Theme.TriggerBackground -- Настройка цвета иконки UI
	openButton.Text = "UI"
	openButton.TextColor3 = self.Theme.TriggerText
	openButton.Font = Enum.Font.GothamBold
	openButton.TextSize = 14
	openButton.BorderSizePixel = 0
	openButton.Visible = false
	openButton.ZIndex = 10
	openButton.Parent = screenGui
	self.OpenButton = openButton
	
	local openCorner = Instance.new("UICorner")
	openCorner.CornerRadius = UDim.new(1, 0) -- Триггер всегда круглый
	openCorner.Parent = openButton
	
	-- Инициализация драга
	self:_makeDraggable(self.MainFrame)
	self:_makeDraggable(self.OpenButton)
	
	closeMenuBtn.MouseButton1Click:Connect(function() self:ToggleVisibility(false) end)
	openButton.MouseButton1Click:Connect(function() self:ToggleVisibility(true) end)
	
	self.InputConnection = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.H then
			self:ToggleVisibility(not self.IsVisible)
		end
	end)
	
	return self
end

-- Внутренний метод драга
function SimpleUI:_makeDraggable(uiElement)
	local dragging, dragStart, startPos
	uiElement.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = uiElement.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			uiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ПУБЛИЧНЫЙ МЕТОД: Показ/Скрытие
function SimpleUI:ToggleVisibility(state)
	self.IsVisible = state
	if state == true then
		self.MainFrame.Visible = true
		self.OpenButton.Visible = false
	else
		self.MainFrame.Visible = false
		self.OpenButton.Visible = true
	end
end

-- ПУБЛИЧНЫЙ МЕТОД: Добавление кастомной кнопки
function SimpleUI:AddButton(text, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 230, 0, 35)
	button.BackgroundColor3 = self.Theme.ButtonBackground -- Применяем цвет темы
	button.Text = text
	button.TextColor3 = self.Theme.ButtonText
	button.Font = Enum.Font.Gotham
	button.TextSize = 12
	button.BorderSizePixel = 0
	button.Parent = self.ContentFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.ButtonCornerRadius) -- Применяем скругление темы
	corner.Parent = button
	
	-- Анимация наведения с использованием настроек темы
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.ButtonHover}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.ButtonBackground}):Play()
	end)
	
	button.MouseButton1Click:Connect(function()
		button.BackgroundColor3 = self.Theme.ButtonClick -- Цвет клика из темы
		task.wait(0.1)
		button.BackgroundColor3 = self.Theme.ButtonHover
		if callback then task.spawn(callback) end
	end)
end

function SimpleUI:Destroy()
	if self.InputConnection then self.InputConnection:Disconnect() end
	if self.ScreenGui then self.ScreenGui:Destroy() end
end

return SimpleUI
