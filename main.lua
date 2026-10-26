--// Agues 5.0
--// Помести этот LocalScript в StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("Agues5Menu")
if oldGui then
	oldGui:Destroy()
end

local destroyed = false
local expanded = false
local confirmationOpen = false
local mouseInside = false
local connections = {}

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function new(className, properties, parent)
	local object = Instance.new(className)

	for property, value in pairs(properties) do
		object[property] = value
	end

	object.Parent = parent
	return object
end

local function tween(object, info, properties)
	if object and object.Parent then
		return TweenService:Create(object, info, properties)
	end
end

local expandTween = TweenInfo.new(
	0.24,
	Enum.EasingStyle.Quart,
	Enum.EasingDirection.Out
)

local smallTween = TweenInfo.new(
	0.16,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

local collapsedWidth = 58
local expandedWidth = 210
local panelHeight = 370
local leftPosition = 18

local collapsedSize = UDim2.fromOffset(collapsedWidth, panelHeight)
local expandedSize = UDim2.fromOffset(expandedWidth, panelHeight)

-- Главное ScreenGui
local gui = new("ScreenGui", {
	Name = "Agues5Menu",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, playerGui)

-- Тень панели
local shadow = new("Frame", {
	Name = "Shadow",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, leftPosition + 3, 0.5, 4),
	Size = collapsedSize,
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	ZIndex = 1
}, gui)

new("UICorner", {
	CornerRadius = UDim.new(0, 8)
}, shadow)

-- Основная панель слева по центру
local panel = new("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, leftPosition, 0.5, 0),
	Size = collapsedSize,
	BackgroundColor3 = Color3.fromRGB(3, 3, 3),
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true,
	ZIndex = 2
}, gui)

new("UICorner", {
	CornerRadius = UDim.new(0, 8)
}, panel)

new("UIStroke", {
	Color = Color3.fromRGB(225, 225, 225),
	Thickness = 1,
	Transparency = 0.05
}, panel)

-- Верхняя буква A
local logo = new("TextLabel", {
	Name = "Logo",
	Position = UDim2.fromOffset(6, 5),
	Size = UDim2.fromOffset(42, 38),
	BackgroundTransparency = 1,
	Text = "A",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 27,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 5
}, panel)

-- Продолжение названия. Вместе с A получается Agues 5.0
local title = new("TextLabel", {
	Name = "Title",
	Position = UDim2.fromOffset(50, 5),
	Size = UDim2.fromOffset(87, 38),
	BackgroundTransparency = 1,
	Text = "gues 5.0",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextTransparency = 1,
	Visible = false,
	ZIndex = 5
}, panel)

-- Крестик расположен отдельно справа и выровнен по центру кнопки
local closeButton = new("TextButton", {
	Name = "CloseButton",
	Position = UDim2.new(1, -38, 0, 8),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = Color3.fromRGB(5, 5, 5),
	BorderSizePixel = 0,
	Text = "×",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 22,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 7
}, panel)

new("UICorner", {
	CornerRadius = UDim.new(0, 5)
}, closeButton)

new("UIStroke", {
	Color = Color3.fromRGB(210, 210, 210),
	Thickness = 1,
	Transparency = 0.05
}, closeButton)

-- Линия под заголовком
new("Frame", {
	Name = "HeaderLine",
	Position = UDim2.fromOffset(1, 50),
	Size = UDim2.new(1, -2, 0, 1),
	BackgroundColor3 = Color3.fromRGB(220, 220, 220),
	BorderSizePixel = 0,
	ZIndex = 4
}, panel)

-- Список функций
local functionsFrame = new("Frame", {
	Name = "Functions",
	Position = UDim2.fromOffset(6, 61),
	Size = UDim2.new(1, -12, 1, -68),
	BackgroundTransparency = 1,
	ZIndex = 3
}, panel)

new("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder
}, functionsFrame)

local functionNames = {
	"Visual",
	"Combat",
	"Movement",
	"Aim Assist",
	"Player",
	"Render",
	"Utility",
	"Automatic",
	"Misc"
}

local icons = {
	"◉",
	"◆",
	"↕",
	"⊙",
	"●",
	"◐",
	"ϟ",
	"★",
	"☷"
}

local buttons = {}

local function addHover(button, normalColor, hoverColor)
	connect(button.MouseEnter, function()
		if destroyed then
			return
		end

		tween(button, smallTween, {
			BackgroundColor3 = hoverColor
		}):Play()
	end)

	connect(button.MouseLeave, function()
		if destroyed then
			return
		end

		tween(button, smallTween, {
			BackgroundColor3 = normalColor
		}):Play()
	end)
end

for index, name in ipairs(functionNames) do
	local button = new("TextButton", {
		Name = name:gsub("%s+", ""),
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, 27),
		BackgroundColor3 = Color3.fromRGB(5, 5, 5),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 4
	}, functionsFrame)

	new("UICorner", {
		CornerRadius = UDim.new(0, 5)
	}, button)

	new("UIStroke", {
		Color = Color3.fromRGB(205, 205, 205),
		Thickness = 0.8,
		Transparency = 0.08
	}, button)

	local icon = new("TextLabel", {
		Name = "Icon",
		Position = UDim2.new(0.5, -14, 0, 0),
		Size = UDim2.fromOffset(28, 27),
		BackgroundTransparency = 1,
		Text = icons[index],
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 5
	}, button)

	local text = new("TextLabel", {
		Name = "FunctionName",
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -65, 1, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Color3.fromRGB(245, 245, 245),
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTransparency = 1,
		Visible = false,
		ZIndex = 5
	}, button)

	local arrow = new("TextLabel", {
		Name = "Arrow",
		Position = UDim2.new(1, -23, 0, 0),
		Size = UDim2.fromOffset(18, 27),
		BackgroundTransparency = 1,
		Text = "›",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTransparency = 1,
		Visible = false,
		ZIndex = 5
	}, button)

	buttons[index] = {
		Button = button,
		Icon = icon,
		Text = text,
		Arrow = arrow
	}

	addHover(
		button,
		Color3.fromRGB(5, 5, 5),
		Color3.fromRGB(28, 28, 28)
	)

	connect(button.MouseButton1Click, function()
		print("Selected function: " .. name)
	end)
end

-- Отдельное окно подтверждения.
-- Оно находится НЕ внутри панели, поэтому всегда будет по центру экрана.
local confirmationLayer = new("Frame", {
	Name = "ConfirmationLayer",
	Position = UDim2.fromScale(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	Active = true,
	ZIndex = 50
}, gui)

local confirmationCard = new("Frame", {
	Name = "ConfirmationCard",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(310, 174),
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	BorderSizePixel = 0,
	ZIndex = 51
}, confirmationLayer)

new("UICorner", {
	CornerRadius = UDim.new(0, 8)
}, confirmationCard)

new("UIStroke", {
	Color = Color3.fromRGB(230, 230, 230),
	Thickness = 1.1,
	Transparency = 0.02
}, confirmationCard)

local confirmationTitle = new("TextLabel", {
	Name = "ConfirmationTitle",
	Position = UDim2.fromOffset(15, 16),
	Size = UDim2.new(1, -30, 0, 25),
	BackgroundTransparency = 1,
	Text = "Close Agues 5.0?",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 17,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 52
}, confirmationCard)

local confirmationText = new("TextLabel", {
	Name = "ConfirmationText",
	Position = UDim2.fromOffset(15, 49),
	Size = UDim2.new(1, -30, 0, 40),
	BackgroundTransparency = 1,
	Text = "Are you sure you want to close?",
	TextColor3 = Color3.fromRGB(225, 225, 225),
	TextSize = 14,
	Font = Enum.Font.GothamMedium,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 52
}, confirmationCard)

local cancelButton = new("TextButton", {
	Name = "Cancel",
	Position = UDim2.fromOffset(15, 116),
	Size = UDim2.new(0.5, -22, 0, 38),
	BackgroundColor3 = Color3.fromRGB(5, 5, 5),
	BorderSizePixel = 0,
	Text = "Cancel",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	AutoButtonColor = false,
	ZIndex = 52
}, confirmationCard)

new("UICorner", {
	CornerRadius = UDim.new(0, 6)
}, cancelButton)

new("UIStroke", {
	Color = Color3.fromRGB(210, 210, 210),
	Thickness = 1,
	Transparency = 0.05
}, cancelButton)

local yesButton = new("TextButton", {
	Name = "Yes",
	Position = UDim2.new(0.5, 7, 0, 116),
	Size = UDim2.new(0.5, -22, 0, 38),
	BackgroundColor3 = Color3.fromRGB(35, 35, 35),
	BorderSizePixel = 0,
	Text = "Yes",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	AutoButtonColor = false,
	ZIndex = 52
}, confirmationCard)

new("UICorner", {
	CornerRadius = UDim.new(0, 6)
}, yesButton)

new("UIStroke", {
	Color = Color3.fromRGB(230, 230, 230),
	Thickness = 1,
	Transparency = 0.05
}, yesButton)

addHover(cancelButton, Color3.fromRGB(5, 5, 5), Color3.fromRGB(30, 30, 30))
addHover(yesButton, Color3.fromRGB(35, 35, 35), Color3.fromRGB(60, 60, 60))
addHover(closeButton, Color3.fromRGB(5, 5, 5), Color3.fromRGB(30, 30, 30))

local function expandMenu()
	if destroyed or expanded then
		return
	end

	expanded = true

	title.Visible = true
	closeButton.Visible = true

	tween(panel, expandTween, {
		Size = expandedSize
	}):Play()

	tween(shadow, expandTween, {
		Size = expandedSize
	}):Play()

	tween(title, expandTween, {
		TextTransparency = 0
	}):Play()

	for _, data in ipairs(buttons) do
		data.Text.Visible = true
		data.Arrow.Visible = true

		tween(data.Icon, expandTween, {
			Position = UDim2.fromOffset(5, 0)
		}):Play()

		tween(data.Text, expandTween, {
			TextTransparency = 0
		}):Play()

		tween(data.Arrow, expandTween, {
			TextTransparency = 0
		}):Play()
	end
end

local function collapseMenu()
	if destroyed or not expanded or confirmationOpen then
		return
	end

	expanded = false

	tween(panel, expandTween, {
		Size = collapsedSize
	}):Play()

	tween(shadow, expandTween, {
		Size = collapsedSize
	}):Play()

	tween(title, expandTween, {
		TextTransparency = 1
	}):Play()

	tween(closeButton, expandTween, {
		TextTransparency = 1
	}):Play()

	for _, data in ipairs(buttons) do
		tween(data.Icon, expandTween, {
			Position = UDim2.new(0.5, -14, 0, 0)
		}):Play()

		tween(data.Text, expandTween, {
			TextTransparency = 1
		}):Play()

		tween(data.Arrow, expandTween, {
			TextTransparency = 1
		}):Play()
	end

	task.delay(0.25, function()
		if destroyed or expanded then
			return
		end

		title.Visible = false
		closeButton.Visible = false

		for _, data in ipairs(buttons) do
			data.Text.Visible = false
			data.Arrow.Visible = false
		end
	end)
end

local function openConfirmation()
	if destroyed or confirmationOpen then
		return
	end

	confirmationOpen = true

	if not expanded then
		expandMenu()
	end

	confirmationLayer.Visible = true
	confirmationLayer.BackgroundTransparency = 1

	confirmationCard.Position = UDim2.fromScale(0.5, 0.5)

	tween(confirmationLayer, expandTween, {
		BackgroundTransparency = 0.38
	}):Play()

	tween(confirmationCard, expandTween, {
		Position = UDim2.fromScale(0.5, 0.5)
	}):Play()
end

local function closeConfirmation()
	if destroyed or not confirmationOpen then
		return
	end

	confirmationOpen = false

	tween(confirmationLayer, smallTween, {
		BackgroundTransparency = 1
	}):Play()

	task.delay(0.17, function()
		if not destroyed and not confirmationOpen then
			confirmationLayer.Visible = false

			if not mouseInside then
				collapseMenu()
			end
		end
	end)
end

local function destroyEverything()
	if destroyed then
		return
	end

	destroyed = true
	confirmationOpen = false
	mouseInside = false

	-- Отключаем все события меню
	for _, connection in ipairs(connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end

	table.clear(connections)

	-- Удаляем интерфейс и все его функции
	if gui then
		gui:Destroy()
	end

	-- Отключаем сам LocalScript
	task.defer(function()
		pcall(function()
			script.Disabled = true
		end)
	end)
end

-- Наведение раскрывает меню вправо
connect(panel.MouseEnter, function()
	if destroyed then
		return
	end

	mouseInside = true

	if not confirmationOpen then
		expandMenu()
	end
end)

connect(panel.MouseLeave, function()
	if destroyed then
		return
	end

	mouseInside = false

	if not confirmationOpen then
		collapseMenu()
	end
end)

-- Крестик открывает подтверждение строго в центре экрана
connect(closeButton.MouseButton1Click, function()
	openConfirmation()
end)

-- Cancel закрывает только окно подтверждения
connect(cancelButton.MouseButton1Click, function()
	closeConfirmation()
end)

-- Yes полностью уничтожает GUI, соединения и LocalScript
connect(yesButton.MouseButton1Click, function()
	destroyEverything()
end)
