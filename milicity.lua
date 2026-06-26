local SimpleUI = {}
SimpleUI.__index = SimpleUI

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- ДЕФОЛТНАЯ ТЕМА
local DefaultTheme = {
	CornerRadius = 8,
	ButtonCornerRadius = 5,
	WindowBackground = Color3.fromRGB(30, 30, 30),
	TitleText = Color3.fromRGB(255, 255, 255),
	CloseButtonBackground = Color3.fromRGB(45, 45, 45),
	CloseButtonText = Color3.fromRGB(200, 200, 200),
	ButtonBackground = Color3.fromRGB(45, 45, 45),
	ButtonHover = Color3.fromRGB(60, 60, 60),
	ButtonClick = Color3.fromRGB(0, 120, 215),
	ButtonText = Color3.fromRGB(230, 230, 230),
	TriggerBackground = Color3.fromRGB(0, 120, 215),
	TriggerText = Color3.fromRGB(255, 255, 255)
}

function SimpleUI.new(titleText, customTheme)
	local self = setmetatable({}, SimpleUI)
	
	self.Theme = DefaultTheme
	if customTheme and type(customTheme) == "table" then
		for key, value in pairs(customTheme) do self.Theme[key] = value end
	end
	
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SimpleUI_Debugger"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	self.ScreenGui = screenGui
	
	self.IsVisible = true
	
	-- ГЛАВНОЕ ОКНО
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 250, 0, 350)
	mainFrame.Position = UDim2.new(0, 50, 0.5, -175)
	mainFrame.BackgroundColor3 = self.Theme.WindowBackground
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	self.MainFrame = mainFrame
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, self.Theme.CornerRadius)
	uiCorner.Parent = mainFrame
	
	-- Заголовок
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText or "DEBUG MENU"
	title.TextColor3 = self.Theme.TitleText
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = mainFrame
	
	-- Крестик закрытия
	local closeMenuBtn = Instance.new("TextButton")
	closeMenuBtn.Size = UDim2.new(0, 30, 0, 30)
	closeMenuBtn.Position = UDim2.new(1, -35, 0, 5)
	closeMenuBtn.BackgroundColor3 = self.Theme.CloseButtonBackground
	closeMenuBtn.Text = "X"
	closeMenuBtn.TextColor3 = self.Theme.CloseButtonText
	closeMenuBtn.Font = Enum.Font.GothamBold
	closeMenuBtn.TextSize = 12
	closeMenuBtn.BorderSizePixel = 0
	closeMenuBtn.Parent = mainFrame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, self.Theme.ButtonCornerRadius)
	closeCorner.Parent = closeMenuBtn
	
	-- Контейнер для элементов
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
	
	-- КНОПКА UI
	local openButton = Instance.new("TextButton")
	openButton.Size = UDim2.new(0, 50, 0, 50)
	openButton.Position = UDim2.new(0, 50, 0, 50)
	openButton.BackgroundColor3 = self.Theme.TriggerBackground
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
	openCorner.CornerRadius = UDim.new(1, 0)
	openCorner.Parent = openButton
	
	self:_makeDraggable(self.MainFrame)
	self:_makeDraggable(self.OpenButton)
	
	closeMenuBtn.MouseButton1Click:Connect(function() self:ToggleVisibility(false) end)
	openButton.MouseButton1Click:Connect(function() self:ToggleVisibility(true) end)
	
	self.InputConnection = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.H then self:ToggleVisibility(not self.IsVisible) end
	end)
	
	return self
end

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

function SimpleUI:ToggleVisibility(state)
	self.IsVisible = state
	self.MainFrame.Visible = state
	self.OpenButton.Visible = not state
end

-- МЕТОД: Добавление стандартной кнопки
function SimpleUI:AddButton(text, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 230, 0, 35)
	button.BackgroundColor3 = self.Theme.ButtonBackground
	button.Text = text
	button.TextColor3 = self.Theme.ButtonText
	button.Font = Enum.Font.Gotham
	button.TextSize = 12
	button.BorderSizePixel = 0
	button.Parent = self.ContentFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.ButtonCornerRadius)
	corner.Parent = button
	
	button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.ButtonHover}):Play() end)
	button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.ButtonBackground}):Play() end)
	button.MouseButton1Click:Connect(function()
		button.BackgroundColor3 = self.Theme.ButtonClick
		task.wait(0.1)
		button.BackgroundColor3 = self.Theme.ButtonHover
		if callback then task.spawn(callback) end
	end)
end

-- МЕТОД: Добавление лейбла
function SimpleUI:AddLabel(defaultText, options)
	local cfg = {
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor = Color3.fromRGB(200, 200, 200),
		Height = 25,
		TextXAlignment = Enum.TextXAlignment.Center
	}
	if options and type(options) == "table" then
		for k, v in pairs(options) do cfg[k] = v end
	end
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 230, 0, cfg.Height)
	label.BackgroundTransparency = 1
	label.Text = defaultText or ""
	label.TextColor3 = cfg.TextColor
	label.Font = cfg.Font
	label.TextSize = cfg.TextSize
	label.TextXAlignment = cfg.TextXAlignment
	label.TextWrapped = true
	label.Parent = self.ContentFrame

	local LabelObject = {}
	function LabelObject:SetText(newText) label.Text = tostring(newText) end
	function LabelObject:SetColor(newColor) label.TextColor3 = newColor end
	function LabelObject:SetSize(newSize) label.TextSize = newSize end
	function LabelObject:SetFont(newFont) label.Font = newFont end
	function LabelObject:Destroy() label:Destroy() end
	return LabelObject
end

-- ========================================================
-- НОВЫЙ МЕТОД: ДОБАВЛЕНИЕ КНОПКИ ДЕСТРУКТОРА (УДАЛЕНИЯ МЕНЮ)
-- ========================================================
-- customText — кастомный текст кнопки (дефолт: "Уничтожить меню")
-- customColor — цвет кнопки, например, красный (дефолт: цвет клика из темы)
function SimpleUI:AddDestroyButton(customText, customColor)
	local destroyColor = customColor or Color3.fromRGB(180, 40, 40) -- По умолчанию опасный красный цвет
	
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 230, 0, 35)
	button.BackgroundColor3 = destroyColor
	button.Text = customText or "Уничтожить меню"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.BorderSizePixel = 0
	button.Parent = self.ContentFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.ButtonCornerRadius)
	corner.Parent = button
	
	-- Анимация наведения для кнопки удаления
	button.MouseEnter:Connect(function() 
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = destroyColor:Darken(0.2) or Color3.fromRGB(140, 30, 30)}):Play() 
	end)
	button.MouseLeave:Connect(function() 
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = destroyColor}):Play() 
	end)
	
	-- При клике вызываем внутренний деструктор всего объекта
	button.MouseButton1Click:Connect(function()
		print("[SimpleUI] Запущен процесс полной выгрузки интерфейса...")
		self:Destroy()
	end)
end

-- МЕТОД: Полная очистка
function SimpleUI:Destroy()
	if self.InputConnection then self.InputConnection:Disconnect() end
	if self.ScreenGui then self.ScreenGui:Destroy() end
	print("[SimpleUI] Интерфейс полностью удален из памяти.")
end

return SimpleUI
