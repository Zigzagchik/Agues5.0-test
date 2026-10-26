--// Agues 5.0 - Visual Menu
--// LocalScript: StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("Agues5Menu")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "Agues5Menu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local connections = {}
local playerData = {}

local visualState = {
	names = false,
	health = false,
	distance = false,
	highlight = false,
	fovMode = "Standard"
}

local camera = workspace.CurrentCamera
local standardFOV = camera and camera.FieldOfView or 70

local expanded = false
local visualMenuOpen = false

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function create(className, properties, parent)
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

local fastTween = TweenInfo.new(
	0.16,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

local smoothTween = TweenInfo.new(
	0.24,
	Enum.EasingStyle.Quart,
	Enum.EasingDirection.Out
)

local function addCorner(object, radius)
	create("UICorner", {
		CornerRadius = UDim.new(0, radius)
	}, object)
end

local function addStroke(object, transparency)
	create("UIStroke", {
		Color = Color3.fromRGB(225, 225, 225),
		Thickness = 1,
		Transparency = transparency or 0.05
	}, object)
end

local function styleButton(button, normalColor, hoverColor)
	button.AutoButtonColor = false

	connect(button.MouseEnter, function()
		tween(button, fastTween, {
			BackgroundColor3 = hoverColor
		}):Play()
	end)

	connect(button.MouseLeave, function()
		tween(button, fastTween, {
			BackgroundColor3 = normalColor
		}):Play()
	end)
end

----------------------------------------------------------------
-- VISUAL FUNCTIONS
----------------------------------------------------------------

local function destroyTag(data)
	if data.tag then
		data.tag:Destroy()
		data.tag = nil
	end

	if data.healthConnection then
		data.healthConnection:Disconnect()
		data.healthConnection = nil
	end
end

local function destroyHighlight(data)
	if data.highlight then
		data.highlight:Destroy()
		data.highlight = nil
	end
end

local function updateHealth(data, humanoid)
	if not data.tag or not humanoid or not humanoid.Parent then
		return
	end

	local healthBack = data.tag:FindFirstChild("HealthBack")
	if not healthBack then
		return
	end

	local healthFill = healthBack:FindFirstChild("HealthFill")
	if not healthFill then
		return
	end

	local maxHealth = math.max(humanoid.MaxHealth, 1)
	local percent = math.clamp(humanoid.Health / maxHealth, 0, 1)

	healthFill.Size = UDim2.new(percent, 0, 1, 0)

	if percent > 0.6 then
		healthFill.BackgroundColor3 = Color3.fromRGB(90, 220, 125)
	elseif percent > 0.3 then
		healthFill.BackgroundColor3 = Color3.fromRGB(235, 190, 70)
	else
		healthFill.BackgroundColor3 = Color3.fromRGB(235, 75, 75)
	end
end

local function createVisualTag(player, character, head, humanoid, data)
	destroyTag(data)

	local tag = create("BillboardGui", {
		Name = "AguesVisualTag",
		Adornee = head,
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(220, 65),
		StudsOffset = Vector3.new(0, 3.2, 0),
		MaxDistance = 1000,
		Enabled = true
	}, head)

	local nameLabel = create("TextLabel", {
		Name = "NameLabel",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 21),
		BackgroundTransparency = 1,
		Text = player.DisplayName,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextStrokeTransparency = 0.35,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center
	}, tag)

	local distanceLabel = create("TextLabel", {
		Name = "DistanceLabel",
		Position = UDim2.fromOffset(0, 21),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color3.fromRGB(220, 220, 220),
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextStrokeTransparency = 0.45,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center
	}, tag)

	local healthBack = create("Frame", {
		Name = "HealthBack",
		Position = UDim2.fromOffset(24, 46),
		Size = UDim2.new(1, -48, 0, 7),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0
	}, tag)

	addCorner(healthBack, 3)

	local healthFill = create("Frame", {
		Name = "HealthFill",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(90, 220, 125),
		BorderSizePixel = 0
	}, healthBack)

	addCorner(healthFill, 3)

	data.tag = tag

	data.healthConnection = humanoid.HealthChanged:Connect(function()
		updateHealth(data, humanoid)
	end)

	nameLabel.Visible = visualState.names
	distanceLabel.Visible = visualState.distance
	healthBack.Visible = visualState.health

	updateHealth(data, humanoid)
end

local function createHighlight(character, data)
	destroyHighlight(data)

	local highlight = create("Highlight", {
		Name = "AguesVisualHighlight",
		Adornee = character,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		FillColor = Color3.fromRGB(255, 255, 255),
		OutlineColor = Color3.fromRGB(255, 255, 255),
		FillTransparency = 0.78,
		OutlineTransparency = 0.05
	}, character)

	data.highlight = highlight
end

local function refreshPlayerVisuals(player)
	if player == localPlayer then
		return
	end

	local data = playerData[player]

	if not data then
		data = {}
		playerData[player] = data
	end

	local character = player.Character

	if not character then
		destroyTag(data)
		destroyHighlight(data)
		return
	end

	local head = character:FindFirstChild("Head")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	local needTag = visualState.names or visualState.health or visualState.distance

	if needTag and head and humanoid then
		createVisualTag(player, character, head, humanoid, data)
	else
		destroyTag(data)
	end

	if visualState.highlight then
		createHighlight(character, data)
	else
		destroyHighlight(data)
	end
end

local function refreshAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			refreshPlayerVisuals(player)
		end
	end
end

local function updateTagVisibility()
	for _, data in pairs(playerData) do
		if data.tag then
			local nameLabel = data.tag:FindFirstChild("NameLabel")
			local distanceLabel = data.tag:FindFirstChild("DistanceLabel")
			local healthBack = data.tag:FindFirstChild("HealthBack")

			if nameLabel then
				nameLabel.Visible = visualState.names
			end

			if distanceLabel then
				distanceLabel.Visible = visualState.distance
			end

			if healthBack then
				healthBack.Visible = visualState.health
			end
		end
	end
end

connect(Players.PlayerAdded, function(player)
	playerData[player] = {}

	connect(player.CharacterAdded, function()
		task.wait(0.25)
		refreshPlayerVisuals(player)
	end)
end)

connect(Players.PlayerRemoving, function(player)
	local data = playerData[player]

	if data then
		destroyTag(data)
		destroyHighlight(data)
	end

	playerData[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		playerData[player] = {}

		connect(player.CharacterAdded, function()
			task.wait(0.25)
			refreshPlayerVisuals(player)
		end)

		if player.Character then
			task.defer(function()
				refreshPlayerVisuals(player)
			end)
		end
	end
end

connect(RunService.RenderStepped, function()
	if not visualState.distance then
		return
	end

	local localCharacter = localPlayer.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

	if not localRoot then
		return
	end

	for player, data in pairs(playerData) do
		if data.tag and player.Character then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			local distanceLabel = data.tag:FindFirstChild("DistanceLabel")

			if root and distanceLabel then
				local distance = math.floor((localRoot.Position - root.Position).Magnitude)
				distanceLabel.Text = tostring(distance) .. " studs"
			end
		end
	end
end)

local function setFOV(mode)
	visualState.fovMode = mode

	camera = workspace.CurrentCamera

	if not camera then
		return
	end

	if mode == "120" then
		camera.FieldOfView = 120
	else
		camera.FieldOfView = standardFOV
	end
end

connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
	camera = workspace.CurrentCamera

	if camera then
		if visualState.fovMode == "120" then
			camera.FieldOfView = 120
		else
			camera.FieldOfView = standardFOV
		end
	end
end)

----------------------------------------------------------------
-- MAIN AGUES MENU
----------------------------------------------------------------

local mainPanel = create("Frame", {
	Name = "MainPanel",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 18, 0.5, 0),
	Size = UDim2.fromOffset(58, 370),
	BackgroundColor3 = Color3.fromRGB(3, 3, 3),
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true,
	ZIndex = 5
}, gui)

addCorner(mainPanel, 8)
addStroke(mainPanel, 0.05)

local mainTitleA = create("TextLabel", {
	Name = "Logo",
	Position = UDim2.fromOffset(7, 5),
	Size = UDim2.fromOffset(40, 38),
	BackgroundTransparency = 1,
	Text = "A",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 27,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 7
}, mainPanel)

local mainTitle = create("TextLabel", {
	Name = "Title",
	Position = UDim2.fromOffset(50, 5),
	Size = UDim2.fromOffset(100, 38),
	BackgroundTransparency = 1,
	Text = "gues 5.0",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextTransparency = 1,
	Visible = false,
	ZIndex = 7
}, mainPanel)

create("Frame", {
	Name = "HeaderLine",
	Position = UDim2.fromOffset(1, 50),
	Size = UDim2.new(1, -2, 0, 1),
	BackgroundColor3 = Color3.fromRGB(220, 220, 220),
	BorderSizePixel = 0,
	ZIndex = 6
}, mainPanel)

local mainFunctions = create("Frame", {
	Name = "Functions",
	Position = UDim2.fromOffset(6, 61),
	Size = UDim2.new(1, -12, 1, -68),
	BackgroundTransparency = 1,
	ZIndex = 6
}, mainPanel)

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder
}, mainFunctions)

local menuItems = {
	{"Visual", "◉"},
	{"Combat", "◆"},
	{"Movement", "↕"},
	{"Aim Assist", "⊙"},
	{"Player", "●"},
	{"Render", "◐"},
	{"Utility", "ϟ"},
	{"Automatic", "★"},
	{"Misc", "☷"}
}

local menuButtons = {}

for index, item in ipairs(menuItems) do
	local name = item[1]
	local iconText = item[2]

	local button = create("TextButton", {
		Name = name:gsub("%s+", ""),
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, 27),
		BackgroundColor3 = Color3.fromRGB(5, 5, 5),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 7
	}, mainFunctions)

	addCorner(button, 5)
	addStroke(button, 0.08)

	local icon = create("TextLabel", {
		Name = "Icon",
		Position = UDim2.new(0.5, -14, 0, 0),
		Size = UDim2.fromOffset(28, 27),
		BackgroundTransparency = 1,
		Text = iconText,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 8
	}, button)

	local label = create("TextLabel", {
		Name = "Label",
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
		ZIndex = 8
	}, button)

	local arrow = create("TextLabel", {
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
		ZIndex = 8
	}, button)

	menuButtons[index] = {
		button = button,
		icon = icon,
		label = label,
		arrow = arrow
	}

	styleButton(
		button,
		Color3.fromRGB(5, 5, 5),
		Color3.fromRGB(28, 28, 28)
	)

	connect(button.MouseButton1Click, function()
		if name == "Visual" then
			visualMenuOpen = true
		end
	end)
end

local function expandMainMenu()
	if expanded then
		return
	end

	expanded = true

	tween(mainPanel, smoothTween, {
		Size = UDim2.fromOffset(210, 370)
	}):Play()

	mainTitle.Visible = true

	tween(mainTitle, smoothTween, {
		TextTransparency = 0
	}):Play()

	for _, data in ipairs(menuButtons) do
		data.label.Visible = true
		data.arrow.Visible = true

		tween(data.icon, smoothTween, {
			Position = UDim2.fromOffset(5, 0)
		}):Play()

		tween(data.label, smoothTween, {
			TextTransparency = 0
		}):Play()

		tween(data.arrow, smoothTween, {
			TextTransparency = 0
		}):Play()
	end
end

local function collapseMainMenu()
	if not expanded or visualMenuOpen then
		return
	end

	expanded = false

	tween(mainPanel, smoothTween, {
		Size = UDim2.fromOffset(58, 370)
	}):Play()

	tween(mainTitle, smoothTween, {
		TextTransparency = 1
	}):Play()

	for _, data in ipairs(menuButtons) do
		tween(data.icon, smoothTween, {
			Position = UDim2.new(0.5, -14, 0, 0)
		}):Play()

		tween(data.label, smoothTween, {
			TextTransparency = 1
		}):Play()

		tween(data.arrow, smoothTween, {
			TextTransparency = 1
		}):Play()
	end

	task.delay(0.25, function()
		if expanded or visualMenuOpen then
			return
		end

		mainTitle.Visible = false

		for _, data in ipairs(menuButtons) do
			data.label.Visible = false
			data.arrow.Visible = false
		end
	end)
end

connect(mainPanel.MouseEnter, function()
	expandMainMenu()
end)

connect(mainPanel.MouseLeave, function()
	collapseMainMenu()
end)

----------------------------------------------------------------
-- CENTERED AGUES VISUAL MENU
----------------------------------------------------------------

local visualLayer = create("Frame", {
	Name = "VisualLayer",
	Position = UDim2.fromScale(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	Active = true,
	ZIndex = 40
}, gui)

local visualCard = create("Frame", {
	Name = "VisualCard",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(390, 330),
	BackgroundColor3 = Color3.fromRGB(7, 7, 7),
	BorderSizePixel = 0,
	ZIndex = 41
}, visualLayer)

addCorner(visualCard, 8)
addStroke(visualCard, 0.02)

local visualTitle = create("TextLabel", {
	Name = "Title",
	Position = UDim2.fromOffset(50, 10),
	Size = UDim2.new(1, -100, 0, 31),
	BackgroundTransparency = 1,
	Text = "Agues Visual",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 43
}, visualCard)

local visualClose = create("TextButton", {
	Name = "Close",
	Position = UDim2.new(1, -41, 0, 10),
	Size = UDim2.fromOffset(29, 29),
	BackgroundColor3 = Color3.fromRGB(5, 5, 5),
	BorderSizePixel = 0,
	Text = "×",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 22,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	AutoButtonColor = false,
	ZIndex = 44
}, visualCard)

addCorner(visualClose, 5)
addStroke(visualClose, 0.05)
styleButton(
	visualClose,
	Color3.fromRGB(5, 5, 5),
	Color3.fromRGB(32, 32, 32)
)

create("Frame", {
	Name = "Line",
	Position = UDim2.fromOffset(1, 52),
	Size = UDim2.new(1, -2, 0, 1),
	BackgroundColor3 = Color3.fromRGB(220, 220, 220),
	BorderSizePixel = 0,
	ZIndex = 42
}, visualCard)

local visualBody = create("Frame", {
	Name = "Body",
	Position = UDim2.fromOffset(18, 69),
	Size = UDim2.new(1, -36, 1, -84),
	BackgroundTransparency = 1,
	ZIndex = 42
}, visualCard)

local function createVisualToggle(text, y, stateKey)
	local label = create("TextLabel", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, -105, 0, 34),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 43
	}, visualBody)

	local button = create("TextButton", {
		Position = UDim2.new(1, -86, 0, y),
		Size = UDim2.fromOffset(86, 34),
		BackgroundColor3 = Color3.fromRGB(5, 5, 5),
		BorderSizePixel = 0,
		Text = "OFF",
		TextColor3 = Color3.fromRGB(220, 220, 220),
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutoButtonColor = false,
		ZIndex = 43
	}, visualBody)

	addCorner(button, 5)
	addStroke(button, 0.08)

	local function updateButton()
		if visualState[stateKey] then
			button.Text = "ON"
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
		else
			button.Text = "OFF"
			button.TextColor3 = Color3.fromRGB(190, 190, 190)
			button.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
		end
	end

	connect(button.MouseEnter, function()
		tween(button, fastTween, {
			BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		}):Play()
	end)

	connect(button.MouseLeave, function()
		updateButton()
	end)

	connect(button.MouseButton1Click, function()
		visualState[stateKey] = not visualState[stateKey]

		updateButton()

		if stateKey == "highlight" then
			refreshAllPlayers()
		else
			updateTagVisibility()
			refreshAllPlayers()
		end
	end)

	updateButton()
	return button
end

createVisualToggle("Player Names", 0, "names")
createVisualToggle("Health Bars", 43, "health")
createVisualToggle("Distance", 86, "distance")
createVisualToggle("Highlight", 129, "highlight")

local fovLabel = create("TextLabel", {
	Position = UDim2.fromOffset(0, 183),
	Size = UDim2.fromOffset(100, 34),
	BackgroundTransparency = 1,
	Text = "FOV",
	TextColor3 = Color3.fromRGB(240, 240, 240),
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 43
}, visualBody)

local standardButton = create("TextButton", {
	Position = UDim2.new(1, -176, 0, 183),
	Size = UDim2.fromOffset(82, 34),
	BackgroundColor3 = Color3.fromRGB(5, 5, 5),
	BorderSizePixel = 0,
	Text = "Standard",
	TextColor3 = Color3.fromRGB(220, 220, 220),
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	AutoButtonColor = false,
	ZIndex = 43
}, visualBody)

addCorner(standardButton, 5)
addStroke(standardButton, 0.08)

local fov120Button = create("TextButton", {
	Position = UDim2.new(1, -86, 0, 183),
	Size = UDim2.fromOffset(86, 34),
	BackgroundColor3 = Color3.fromRGB(5, 5, 5),
	BorderSizePixel = 0,
	Text = "120 FOV",
	TextColor3 = Color3.fromRGB(220, 220, 220),
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	AutoButtonColor = false,
	ZIndex = 43
}, visualBody)

addCorner(fov120Button, 5)
addStroke(fov120Button, 0.08)

local function updateFOVButtons()
	if visualState.fovMode == "Standard" then
		standardButton.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
		standardButton.TextColor3 = Color3.fromRGB(255, 255, 255)

		fov120Button.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
		fov120Button.TextColor3 = Color3.fromRGB(220, 220, 220)
	else
		standardButton.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
		standardButton.TextColor3 = Color3.fromRGB(220, 220, 220)

		fov120Button.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
		fov120Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

connect(standardButton.MouseEnter, function()
	tween(standardButton, fastTween, {
		BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	}):Play()
end)

connect(standardButton.MouseLeave, function()
	updateFOVButtons()
end)

connect(fov120Button.MouseEnter, function()
	tween(fov120Button, fastTween, {
		BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	}):Play()
end)

connect(fov120Button.MouseLeave, function()
	updateFOVButtons()
end)

connect(standardButton.MouseButton1Click, function()
	setFOV("Standard")
	updateFOVButtons()
end)

connect(fov120Button.MouseButton1Click, function()
	setFOV("120")
	updateFOVButtons()
end)

updateFOVButtons()

local infoText = create("TextLabel", {
	Position = UDim2.fromOffset(0, 239),
	Size = UDim2.new(1, 0, 0, 25),
	BackgroundTransparency = 1,
	Text = "Visual settings stay active after closing",
	TextColor3 = Color3.fromRGB(165, 165, 165),
	TextSize = 10,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 43
}, visualBody)

----------------------------------------------------------------
-- OPEN / CLOSE VISUAL MENU
----------------------------------------------------------------

local visualScale = create("UIScale", {
	Scale = 0.92
}, visualCard)

local function openVisualMenu()
	if visualMenuOpen then
		return
	end

	visualMenuOpen = true
	visualLayer.Visible = true
	visualLayer.BackgroundTransparency = 1
	visualScale.Scale = 0.92

	tween(visualLayer, smoothTween, {
		BackgroundTransparency = 0.38
	}):Play()

	tween(visualScale, smoothTween, {
		Scale = 1
	}):Play()
end

local function closeVisualMenu()
	if not visualMenuOpen then
		return
	end

	visualMenuOpen = false

	-- Здесь ничего не отключается и не сбрасывается.
	-- Закрывается только само окно.
	tween(visualLayer, fastTween, {
		BackgroundTransparency = 1
	}):Play()

	tween(visualScale, fastTween, {
		Scale = 0.92
	}):Play()

	task.delay(0.17, function()
		if not visualMenuOpen then
			visualLayer.Visible = false
		end
	end)
end

connect(visualClose.MouseButton1Click, function()
	closeVisualMenu()
end)

-- Открытие Visual по кнопке Visual в главном меню
for _, data in ipairs(menuButtons) do
	local label = data.label.Text

	if label == "Visual" then
		connect(data.button.MouseButton1Click, function()
			openVisualMenu()
		end)
	end
end
