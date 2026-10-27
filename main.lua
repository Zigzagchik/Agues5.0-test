--// Agues 5.0 — Visual + integrated Combat
--// LocalScript: StarterPlayer > StarterPlayerScripts
--//
--// Uses standard Roblox APIs only.
--// Tool:Activate() requests an attack; damage/stun are server-defined.
--// Observed health loss is NOT proof that this client caused damage.

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

local destroyed = false
local expanded = false
local visualMenuOpen = false
local combatMenuOpen = false
local confirmationOpen = false

local camera = workspace.CurrentCamera
local standardFOV = camera and camera.FieldOfView or 70

local visualState = {
	names = false,
	health = false,
	distance = false,
	highlight = false,
	fovMode = "Standard",
}

local combatState = {
	combo = true,
	sound = false,
	stats = true,
	crosshair = false,
	hitmarker = true,
	numbers = true,
	mace = false,
	swap = true,
	stun = false,
	sword = false,
}

local combatConfig = {
	targetMode = "Training",
	range = 12,
	cooldown = 0.65,
	equipDelay = 0.08,
	swapDelay = 0.28,
	comboWindow = 2,
	stunCooldown = 1.5,
	maceFallSpeed = 12,
	maceName = "Mace",
	axeName = "Axe",
	swordName = "Sword",
	shieldName = "Shield",
	soundId = "",
}

local function newSession()
	return {
		hits = 0,
		damage = 0,
		combo = 0,
		best = 0,
		attempts = 0,
		started = os.clock(),
		lastHit = 0,
		lastModel = nil,
	}
end

local combat = {
	session = newSession(),
	tracked = {},
	effects = {},
	refreshers = {},
	stunTimes = setmetatable({}, { __mode = "k" }),
	action = nil,
	pending = nil,
	nextAttack = 0,
	nextScan = 0,
	markerUntil = 0,
	status = "Ready",
	lastTarget = "-",
}

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

local function animate(object, info, properties)
	if destroyed or not object or not object.Parent then
		return
	end

	local animation = TweenService:Create(object, info, properties)
	animation:Play()
	return animation
end

local function addCorner(object, radius)
	create("UICorner", {
		CornerRadius = UDim.new(0, radius or 5),
	}, object)
end

local function addStroke(object, transparency)
	create("UIStroke", {
		Color = Color3.fromRGB(225, 225, 225),
		Thickness = 1,
		Transparency = transparency or 0.08,
	}, object)
end

local function styleButton(button, normalColor, hoverColor)
	button.AutoButtonColor = false

	connect(button.MouseEnter, function()
		animate(button, fastTween, {
			BackgroundColor3 = hoverColor,
		})
	end)

	connect(button.MouseLeave, function()
		animate(button, fastTween, {
			BackgroundColor3 = normalColor,
		})
	end)
end

local function textLabel(parent, text, position, size, options)
	local properties = {
		BackgroundTransparency = 1,
		Text = text,
		Position = position,
		Size = size,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 43,
	}

	for key, value in pairs(options or {}) do
		properties[key] = value
	end

	return create("TextLabel", properties, parent)
end

local function textButton(parent, text, position, size, zIndex)
	local button = create("TextButton", {
		Position = position,
		Size = size,
		BackgroundColor3 = Color3.fromRGB(5, 5, 5),
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = Color3.fromRGB(230, 230, 230),
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		ZIndex = zIndex or 44,
	}, parent)

	addCorner(button, 5)
	addStroke(button, 0.08)
	return button
end

----------------------------------------------------------------
-- VISUAL FUNCTIONS
----------------------------------------------------------------

local function destroyTag(data)
	if data.healthConnection then
		data.healthConnection:Disconnect()
		data.healthConnection = nil
	end

	if data.tag then
		data.tag:Destroy()
		data.tag = nil
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

	local back = data.tag:FindFirstChild("HealthBack")
	local fill = back and back:FindFirstChild("HealthFill")

	if not fill then
		return
	end

	local percent = math.clamp(
		humanoid.Health / math.max(humanoid.MaxHealth, 1),
		0,
		1
	)

	fill.Size = UDim2.new(percent, 0, 1, 0)

	if percent > 0.6 then
		fill.BackgroundColor3 = Color3.fromRGB(90, 220, 125)
	elseif percent > 0.3 then
		fill.BackgroundColor3 = Color3.fromRGB(235, 190, 70)
	else
		fill.BackgroundColor3 = Color3.fromRGB(235, 75, 75)
	end
end

local function createVisualTag(player, head, humanoid, data)
	destroyTag(data)

	local tag = create("BillboardGui", {
		Name = "AguesVisualTag",
		Adornee = head,
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(220, 65),
		StudsOffset = Vector3.new(0, 3.2, 0),
		MaxDistance = 1000,
		Enabled = true,
	}, head)

	textLabel(tag, player.DisplayName, UDim2.fromOffset(0, 0),
		UDim2.new(1, 0, 0, 21), {
			Name = "NameLabel",
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			TextStrokeTransparency = 0.35,
			TextXAlignment = Enum.TextXAlignment.Center,
			Visible = visualState.names,
			ZIndex = 1,
		})

	textLabel(tag, "", UDim2.fromOffset(0, 21),
		UDim2.new(1, 0, 0, 18), {
			Name = "DistanceLabel",
			TextSize = 11,
			TextStrokeTransparency = 0.45,
			TextXAlignment = Enum.TextXAlignment.Center,
			Visible = visualState.distance,
			ZIndex = 1,
		})

	local healthBack = create("Frame", {
		Name = "HealthBack",
		Position = UDim2.fromOffset(24, 46),
		Size = UDim2.new(1, -48, 0, 7),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0,
		Visible = visualState.health,
	}, tag)

	addCorner(healthBack, 3)

	local healthFill = create("Frame", {
		Name = "HealthFill",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(90, 220, 125),
		BorderSizePixel = 0,
	}, healthBack)

	addCorner(healthFill, 3)
	data.tag = tag

	data.healthConnection = humanoid.HealthChanged:Connect(function()
		updateHealth(data, humanoid)
	end)

	updateHealth(data, humanoid)
end

local function refreshPlayerVisuals(player)
	if destroyed or player == localPlayer then
		return
	end

	local data = playerData[player]

	if not data then
		data = {}
		playerData[player] = data
	end

	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local needTag = visualState.names or visualState.health or visualState.distance

	if needTag and head and humanoid then
		createVisualTag(player, head, humanoid, data)
	else
		destroyTag(data)
	end

	destroyHighlight(data)

	if character and visualState.highlight then
		data.highlight = create("Highlight", {
			Name = "AguesVisualHighlight",
			Adornee = character,
			DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
			FillColor = Color3.fromRGB(255, 255, 255),
			OutlineColor = Color3.fromRGB(255, 255, 255),
			FillTransparency = 0.78,
			OutlineTransparency = 0.05,
		}, character)
	end
end

local function refreshAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		refreshPlayerVisuals(player)
	end
end

local function watchPlayer(player)
	if player == localPlayer then
		return
	end

	playerData[player] = {}

	connect(player.CharacterAdded, function(character)
		task.delay(0.25, function()
			if not destroyed and player.Character == character then
				refreshPlayerVisuals(player)
			end
		end)
	end)

	connect(player.CharacterRemoving, function()
		local data = playerData[player]

		if data then
			destroyTag(data)
			destroyHighlight(data)
		end
	end)

	if player.Character then
		task.defer(function()
			refreshPlayerVisuals(player)
		end)
	end
end

connect(Players.PlayerAdded, watchPlayer)

connect(Players.PlayerRemoving, function(player)
	local data = playerData[player]

	if data then
		destroyTag(data)
		destroyHighlight(data)
	end

	playerData[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	watchPlayer(player)
end

local function setFOV(mode)
	visualState.fovMode = mode
	camera = workspace.CurrentCamera

	if camera then
		camera.FieldOfView = mode == "120" and 120 or standardFOV
	end
end

connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
	camera = workspace.CurrentCamera

	if camera then
		camera.FieldOfView =
			visualState.fovMode == "120" and 120 or standardFOV
	end
end)

connect(RunService.RenderStepped, function()
	if not visualState.distance then
		return
	end

	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	for player, data in pairs(playerData) do
		local targetCharacter = player.Character
		local targetRoot = targetCharacter
			and targetCharacter:FindFirstChild("HumanoidRootPart")

		local distanceLabel = data.tag
			and data.tag:FindFirstChild("DistanceLabel")

		if targetRoot and distanceLabel then
			local distance = math.floor(
				(root.Position - targetRoot.Position).Magnitude
			)
			distanceLabel.Text = tostring(distance) .. " studs"
		end
	end
end)

----------------------------------------------------------------
-- MAIN MENU
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
	ZIndex = 5,
}, gui)

addCorner(mainPanel, 8)
addStroke(mainPanel, 0.05)

local mainClose = textButton(
	mainPanel, "×",
	UDim2.new(1, -35, 0, 10),
	UDim2.fromOffset(25, 25), 10
)
mainClose.Name = "MainClose"
mainClose.TextSize = 20
mainClose.Visible = false

local logo = create("TextButton", {
	Name = "Logo",
	Position = UDim2.fromOffset(7, 5),
	Size = UDim2.fromOffset(40, 38),
	BackgroundTransparency = 1,
	Text = "A",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 27,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	ZIndex = 7,
}, mainPanel)

local mainTitle = textLabel(
	mainPanel, "gues 5.0",
	UDim2.fromOffset(50, 5),
	UDim2.fromOffset(100, 38), {
		Name = "Title",
		TextSize = 16,
		TextTransparency = 1,
		Visible = false,
		ZIndex = 7,
	}
)

create("Frame", {
	Name = "HeaderLine",
	Position = UDim2.fromOffset(1, 50),
	Size = UDim2.new(1, -2, 0, 1),
	BackgroundColor3 = Color3.fromRGB(220, 220, 220),
	BorderSizePixel = 0,
	ZIndex = 6,
}, mainPanel)

local mainFunctions = create("Frame", {
	Name = "Functions",
	Position = UDim2.fromOffset(6, 61),
	Size = UDim2.new(1, -12, 1, -68),
	BackgroundTransparency = 1,
	ZIndex = 6,
}, mainPanel)

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, mainFunctions)

local menuItems = {
	{ "Visual", "◉" },
	{ "Combat", "◆" },
	{ "Movement", "↕" },
	{ "Aim Assist", "⊙" },
	{ "Player", "●" },
	{ "Render", "◐" },
	{ "Utility", "ϟ" },
	{ "Automatic", "★" },
	{ "Misc", "☷" },
}

local menuButtons = {}

for index, item in ipairs(menuItems) do
	local button = textButton(
		mainFunctions, "",
		UDim2.fromOffset(0, 0),
		UDim2.new(1, 0, 0, 27), 7
	)
	button.Name = item[1]:gsub("%s+", "")
	button.LayoutOrder = index

	local icon = textLabel(
		button, item[2],
		UDim2.new(0.5, -14, 0, 0),
		UDim2.fromOffset(28, 27), {
			Name = "Icon",
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 8,
		}
	)

	local label = textLabel(
		button, item[1],
		UDim2.fromOffset(38, 0),
		UDim2.new(1, -65, 1, 0), {
			Name = "Label",
			TextSize = 11,
			TextTransparency = 1,
			Visible = false,
			ZIndex = 8,
		}
	)

	local arrow = textLabel(
		button, "›",
		UDim2.new(1, -23, 0, 0),
		UDim2.fromOffset(18, 27), {
			Name = "Arrow",
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTransparency = 1,
			Visible = false,
			ZIndex = 8,
		}
	)

	menuButtons[item[1]] = {
		button = button,
		icon = icon,
		label = label,
		arrow = arrow,
	}

	styleButton(
		button,
		Color3.fromRGB(5, 5, 5),
		Color3.fromRGB(28, 28, 28)
	)
end

local function expandMainMenu()
	if destroyed or expanded then
		return
	end

	expanded = true
	mainClose.Visible = true
	mainTitle.Visible = true

	animate(mainPanel, smoothTween, {
		Size = UDim2.fromOffset(210, 370),
	})
	animate(mainTitle, smoothTween, { TextTransparency = 0 })

	for _, data in pairs(menuButtons) do
		data.label.Visible = true
		data.arrow.Visible = true
		animate(data.icon, smoothTween, {
			Position = UDim2.fromOffset(5, 0),
		})
		animate(data.label, smoothTween, { TextTransparency = 0 })
		animate(data.arrow, smoothTween, { TextTransparency = 0 })
	end
end

local function collapseMainMenu()
	if destroyed or not expanded
		or visualMenuOpen or combatMenuOpen or confirmationOpen then
		return
	end

	expanded = false
	mainClose.Visible = false

	animate(mainPanel, smoothTween, {
		Size = UDim2.fromOffset(58, 370),
	})
	animate(mainTitle, smoothTween, { TextTransparency = 1 })

	for _, data in pairs(menuButtons) do
		animate(data.icon, smoothTween, {
			Position = UDim2.new(0.5, -14, 0, 0),
		})
		animate(data.label, smoothTween, { TextTransparency = 1 })
		animate(data.arrow, smoothTween, { TextTransparency = 1 })
	end

	task.delay(0.25, function()
		if destroyed or expanded then
			return
		end

		mainTitle.Visible = false

		for _, data in pairs(menuButtons) do
			data.label.Visible = false
			data.arrow.Visible = false
		end
	end)
end

connect(mainPanel.MouseEnter, expandMainMenu)
connect(mainPanel.MouseLeave, collapseMainMenu)
connect(logo.Activated, function()
	if expanded then
		collapseMainMenu()
	else
		expandMainMenu()
	end
end)

----------------------------------------------------------------
-- SHARED CENTERED WINDOW BUILDER
----------------------------------------------------------------

local function createWindow(name, title, width, height)
	local layer = create("Frame", {
		Name = name .. "Layer",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.38,
		BorderSizePixel = 0,
		Visible = false,
		Active = true,
		ZIndex = 40,
	}, gui)

	local card = create("Frame", {
		Name = name .. "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = Color3.fromRGB(7, 7, 7),
		BorderSizePixel = 0,
		ZIndex = 41,
	}, layer)

	addCorner(card, 8)
	addStroke(card, 0.02)

	textLabel(
		card, title,
		UDim2.fromOffset(45, 10),
		UDim2.new(1, -90, 0, 31), {
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center,
		}
	)

	local close = textButton(
		card, "×",
		UDim2.new(1, -41, 0, 10),
		UDim2.fromOffset(29, 29)
	)
	close.TextSize = 22

	styleButton(
		close,
		Color3.fromRGB(5, 5, 5),
		Color3.fromRGB(32, 32, 32)
	)

	create("Frame", {
		Position = UDim2.fromOffset(1, 52),
		Size = UDim2.new(1, -2, 0, 1),
		BackgroundColor3 = Color3.fromRGB(220, 220, 220),
		BorderSizePixel = 0,
		ZIndex = 42,
	}, card)

	local scale = create("UIScale", { Scale = 1 }, card)

	return {
		layer = layer,
		card = card,
		close = close,
		scale = scale,
		width = width,
		height = height,
	}
end

local function fitWindow(window)
	local currentCamera = workspace.CurrentCamera

	if currentCamera then
		local viewport = currentCamera.ViewportSize

		window.scale.Scale = math.max(0.1, math.min(
			1,
			(viewport.X - 24) / window.width,
			(viewport.Y - 24) / window.height
		))
	end
end

----------------------------------------------------------------
-- VISUAL MENU
----------------------------------------------------------------

local visualWindow = createWindow("Visual", "Agues Visual", 390, 350)

local visualBody = create("Frame", {
	Name = "Body",
	Position = UDim2.fromOffset(18, 69),
	Size = UDim2.new(1, -36, 1, -84),
	BackgroundTransparency = 1,
	ZIndex = 42,
}, visualWindow.card)

local function createVisualToggle(text, y, stateKey)
	textLabel(
		visualBody, text,
		UDim2.fromOffset(0, y),
		UDim2.new(1, -105, 0, 34),
		{ TextSize = 13 }
	)

	local button = textButton(
		visualBody, "OFF",
		UDim2.new(1, -86, 0, y),
		UDim2.fromOffset(86, 34)
	)

	local function update()
		local enabled = visualState[stateKey]

		button.Text = enabled and "ON" or "OFF"
		button.BackgroundColor3 = enabled
			and Color3.fromRGB(42, 42, 42)
			or Color3.fromRGB(5, 5, 5)
		button.TextColor3 = enabled
			and Color3.new(1, 1, 1)
			or Color3.fromRGB(190, 190, 190)
	end

	connect(button.Activated, function()
		visualState[stateKey] = not visualState[stateKey]
		update()
		refreshAllPlayers()
	end)

	update()
end

createVisualToggle("Player Names", 0, "names")
createVisualToggle("Health Bars", 43, "health")
createVisualToggle("Distance", 86, "distance")
createVisualToggle("Highlight", 129, "highlight")

textLabel(
	visualBody, "FOV",
	UDim2.fromOffset(0, 183),
	UDim2.fromOffset(100, 34),
	{ TextSize = 13 }
)

local standardButton = textButton(
	visualBody, "Standard",
	UDim2.new(1, -176, 0, 183),
	UDim2.fromOffset(82, 34)
)

local fov120Button = textButton(
	visualBody, "120 FOV",
	UDim2.new(1, -86, 0, 183),
	UDim2.fromOffset(86, 34)
)

local function updateFOVButtons()
	standardButton.BackgroundColor3 =
		visualState.fovMode == "Standard"
		and Color3.fromRGB(42, 42, 42)
		or Color3.fromRGB(5, 5, 5)

	fov120Button.BackgroundColor3 =
		visualState.fovMode == "120"
		and Color3.fromRGB(42, 42, 42)
		or Color3.fromRGB(5, 5, 5)
end

connect(standardButton.Activated, function()
	setFOV("Standard")
	updateFOVButtons()
end)

connect(fov120Button.Activated, function()
	setFOV("120")
	updateFOVButtons()
end)

updateFOVButtons()

textLabel(
	visualBody, "Visual settings stay active after closing",
	UDim2.fromOffset(0, 239),
	UDim2.new(1, 0, 0, 25), {
		TextSize = 10,
		TextColor3 = Color3.fromRGB(165, 165, 165),
		TextXAlignment = Enum.TextXAlignment.Center,
	}
)

----------------------------------------------------------------
-- COMBAT MENU
----------------------------------------------------------------

local combatWindow = createWindow("Combat", "Agues Combat", 440, 590)

local combatBody = create("ScrollingFrame", {
	Name = "Body",
	Position = UDim2.fromOffset(18, 65),
	Size = UDim2.new(1, -36, 1, -80),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Color3.fromRGB(160, 160, 160),
	CanvasSize = UDim2.fromOffset(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 42,
}, combatWindow.card)

create("UIPadding", {
	PaddingRight = UDim.new(0, 9),
	PaddingBottom = UDim.new(0, 10),
}, combatBody)

create("UIListLayout", {
	Padding = UDim.new(0, 7),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, combatBody)

local rowOrder = 0

local function combatRow(height)
	rowOrder = rowOrder + 1

	return create("Frame", {
		Name = "Row" .. rowOrder,
		LayoutOrder = rowOrder,
		Size = UDim2.new(1, 0, 0, height or 34),
		BackgroundTransparency = 1,
		ZIndex = 43,
	}, combatBody)
end

local function combatNote(text, height)
	local row = combatRow(height or 40)

	textLabel(
		row, text,
		UDim2.fromOffset(0, 0),
		UDim2.fromScale(1, 1), {
			TextSize = 10,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(170, 170, 170),
		}
	)
end

local function combatToggle(text, key)
	local row = combatRow()

	textLabel(
		row, text,
		UDim2.fromOffset(0, 0),
		UDim2.new(1, -100, 1, 0)
	)

	local button = textButton(
		row, "",
		UDim2.new(1, -86, 0, 0),
		UDim2.fromOffset(86, 34)
	)

	local function update()
		local enabled = combatState[key]

		button.Text = enabled and "ON" or "OFF"
		button.BackgroundColor3 = enabled
			and Color3.fromRGB(42, 42, 42)
			or Color3.fromRGB(5, 5, 5)
	end

	combat.refreshers[key] = update

	connect(button.Activated, function()
		combatState[key] = not combatState[key]
		update()
	end)

	update()
end

local function combatInput(text, key, minimum, maximum)
	local row = combatRow()

	textLabel(
		row, text,
		UDim2.fromOffset(0, 0),
		UDim2.new(1, -145, 1, 0)
	)

	local box = create("TextBox", {
		Position = UDim2.new(1, -134, 0, 0),
		Size = UDim2.fromOffset(134, 34),
		BackgroundColor3 = Color3.fromRGB(13, 13, 13),
		BorderSizePixel = 0,
		Text = tostring(combatConfig[key]),
		TextColor3 = Color3.fromRGB(235, 235, 235),
		PlaceholderText = key == "soundId" and "Default / asset ID" or "",
		PlaceholderColor3 = Color3.fromRGB(140, 140, 140),
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		ClearTextOnFocus = false,
		ZIndex = 44,
	}, row)

	addCorner(box, 5)
	addStroke(box, 0.2)

	connect(box.FocusLost, function()
		if minimum ~= nil then
			local number = tonumber(box.Text)

			if number and number == number
				and number ~= math.huge and number ~= -math.huge then
				combatConfig[key] = math.clamp(number, minimum, maximum)
			end
		else
			local value = box.Text:match("^%s*(.-)%s*$")

			if key == "soundId" then
				if value == "" then
					combatConfig[key] = ""
				else
					local id = value:match("^rbxassetid://(%d+)$")
						or value:match("^(%d+)$")

					if id then
						combatConfig[key] = id
					end
				end
			elseif value ~= "" then
				combatConfig[key] = value
			end
		end

		box.Text = tostring(combatConfig[key])
	end)
end

combatNote(
	"One weapon scheduler: shield/axe → falling mace → sword. "
	.. "Damage and stun depend on the game's server.",
	44
)

combatToggle("Combo Counter", "combo")
combatToggle("Hit Sound", "sound")
combatToggle("Training Stats", "stats")
combatToggle("Crosshair", "crosshair")
combatToggle("Hitmarker", "hitmarker")
combatToggle("Damage Numbers", "numbers")
combatToggle("Auto Mace — while falling", "mace")
combatToggle("Swap Back", "swap")
combatToggle("Auto Stun — shield / axe", "stun")
combatToggle("Auto S-Attack — sword", "sword")

do
	local row = combatRow()

	textLabel(
		row, "Targets",
		UDim2.fromOffset(0, 0),
		UDim2.new(1, -145, 1, 0)
	)

	local button = textButton(
		row, combatConfig.targetMode,
		UDim2.new(1, -134, 0, 0),
		UDim2.fromOffset(134, 34)
	)

	local modes = { "Training", "Players", "Both" }

	connect(button.Activated, function()
		local index = table.find(modes, combatConfig.targetMode) or 1
		combatConfig.targetMode = modes[index % #modes + 1]
		button.Text = combatConfig.targetMode
		combat.pending = nil
		combat.nextScan = 0
	end)
end

combatInput("Range — studs", "range", 1, 100)
combatInput("Attack interval — seconds", "cooldown", 0.1, 10)
combatInput("Swap delay — seconds", "swapDelay", 0.05, 3)
combatInput("Combo window — seconds", "comboWindow", 0.2, 10)
combatInput("Stun retry — seconds", "stunCooldown", 0.3, 10)
combatInput("Mace fall speed — studs/s", "maceFallSpeed", 0, 250)
combatInput("Mace tool name", "maceName")
combatInput("Axe tool name", "axeName")
combatInput("Sword tool name", "swordName")
combatInput("Shield tool name", "shieldName")
combatInput("Hit sound asset ID", "soundId")

local resetRow = combatRow(38)
local resetButton = textButton(
	resetRow, "Reset Combat",
	UDim2.fromOffset(0, 0),
	UDim2.new(1, 0, 0, 36)
)

combatNote(
	"Training: Workspace.TrainingDummies. Each target needs "
	.. "a Humanoid and HumanoidRootPart.",
	40
)

combatNote(
	"Observed stats are estimates: nearby health loss after an "
	.. "activation can be caused by someone else. "
	.. "An equipped Shield is only a blocking heuristic.",
	54
)

----------------------------------------------------------------
-- COMBAT HUD, CROSSHAIR, HITMARKER AND SOUND
----------------------------------------------------------------

local hud = create("Frame", {
	Name = "CombatHUD",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -24),
	Size = UDim2.fromOffset(300, 150),
	BackgroundColor3 = Color3.fromRGB(7, 7, 7),
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	ZIndex = 20,
}, gui)

addCorner(hud, 7)
addStroke(hud, 0.4)

local comboLabel = textLabel(
	hud, "Combo: 0 | Best: 0",
	UDim2.fromOffset(12, 8),
	UDim2.new(1, -24, 0, 25), {
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		ZIndex = 21,
	}
)

local statsLabel = textLabel(
	hud, "",
	UDim2.fromOffset(12, 35),
	UDim2.new(1, -24, 0, 105), {
		TextSize = 11,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 21,
	}
)

local crosshair = create("Frame", {
	Name = "Crosshair",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(26, 26),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 25,
}, gui)

for _, spec in ipairs({
	{ 0, 12, 8, 2 },
	{ 18, 12, 8, 2 },
	{ 12, 0, 2, 8 },
	{ 12, 18, 2, 8 },
}) do
	create("Frame", {
		Position = UDim2.fromOffset(spec[1], spec[2]),
		Size = UDim2.fromOffset(spec[3], spec[4]),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 26,
	}, crosshair)
end

local hitmarker = create("Frame", {
	Name = "Hitmarker",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(36, 36),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 28,
}, gui)

for _, spec in ipairs({
	{ 7, 7, 45 },
	{ 29, 7, -45 },
	{ 7, 29, -45 },
	{ 29, 29, 45 },
}) do
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(spec[1], spec[2]),
		Size = UDim2.fromOffset(10, 2),
		Rotation = spec[3],
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 29,
	}, hitmarker)
end

local hitSound = create("Sound", {
	Name = "CombatHitSound",
	SoundId = "rbxasset://sounds/electronicpingshort.wav",
	Volume = 0.45,
}, gui)

-- Optional integration point for your game's own confirmed hit events.
-- Set HitReportingMode to "Confirmed" and fire ReportHit from a trusted
-- client handler receiving the actual server-confirmed combat result.
-- This BindableEvent is NOT a substitute for a server damage system.

gui:SetAttribute("HitReportingMode", "Observed")

local reportHitEvent = create("BindableEvent", {
	Name = "ReportHit",
}, gui)

local function damageNumber(model, damage)
	if not combatState.numbers then
		return
	end

	local part = model:FindFirstChild("Head")
		or model:FindFirstChild("HumanoidRootPart")

	if not part or not part:IsA("BasePart") then
		return
	end

	local billboard = create("BillboardGui", {
		Name = "AguesDamageNumber",
		Adornee = part,
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(130, 45),
		StudsOffset = Vector3.new(
			math.random(-8, 8) / 10,
			2.5,
			0
		),
	}, gui)

	combat.effects[billboard] = true

	local label = textLabel(
		billboard,
		"-" .. string.format("%.1f", damage),
		UDim2.fromOffset(0, 0),
		UDim2.fromScale(1, 1), {
			TextSize = 22,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.fromRGB(255, 115, 115),
			TextStrokeTransparency = 0.3,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 1,
		}
	)

	animate(billboard, TweenInfo.new(0.65), {
		StudsOffset = billboard.StudsOffset + Vector3.new(0, 2, 0),
	})

	animate(label, TweenInfo.new(0.65), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})

	task.delay(0.7, function()
		combat.effects[billboard] = nil
		billboard:Destroy()
	end)
end

local function recordHit(model, damage)
	if destroyed or typeof(model) ~= "Instance"
		or not model:IsA("Model") or not model.Parent
		or type(damage) ~= "number"
		or damage ~= damage or damage <= 0 or damage == math.huge then
		return
	end

	local now = os.clock()
	local session = combat.session

	if session.lastModel ~= model
		or now - session.lastHit > combatConfig.comboWindow then
		session.combo = 0
	end

	session.hits = session.hits + 1
	session.damage = session.damage + damage
	session.combo = session.combo + 1
	session.best = math.max(session.best, session.combo)
	session.lastHit = now
	session.lastModel = model

	combat.lastTarget = model.Name
	combat.markerUntil = now + 0.15

	damageNumber(model, damage)

	if combatState.sound then
		local id = combatConfig.soundId

		hitSound.SoundId = id ~= ""
			and ("rbxassetid://" .. id)
			or "rbxasset://sounds/electronicpingshort.wav"

		hitSound:Stop()
		hitSound:Play()
	end
end

connect(reportHitEvent.Event, function(model, damage)
	if gui:GetAttribute("HitReportingMode") == "Confirmed" then
		recordHit(model, damage)
	end
end)

----------------------------------------------------------------
-- TARGET TRACKING
----------------------------------------------------------------

local function getLocalRig()
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not character or not humanoid or humanoid.Health <= 0
		or not root or not root:IsA("BasePart") then
		return
	end

	return character, humanoid, root
end

local function eligibleModel(model)
	if not model or not model:IsA("Model")
		or model == localPlayer.Character
		or not model:IsDescendantOf(workspace) then
		return false
	end

	local player = Players:GetPlayerFromCharacter(model)

	if player then
		return player ~= localPlayer
			and combatConfig.targetMode ~= "Training"
	end

	local folder = workspace:FindFirstChild("TrainingDummies")

	return combatConfig.targetMode ~= "Players"
		and folder ~= nil
		and model:IsDescendantOf(folder)
end

local function targetRig(model)
	if not eligibleModel(model) then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")

	if humanoid and humanoid.Health > 0
		and root and root:IsA("BasePart") then
		return humanoid, root
	end
end

local function trackTarget(model, humanoid)
	local existing = combat.tracked[model]

	if existing and existing.humanoid == humanoid then
		return
	end

	if existing and existing.connection then
		existing.connection:Disconnect()
	end

	local data = {
		humanoid = humanoid,
		lastHealth = humanoid.Health,
	}
	combat.tracked[model] = data

	data.connection = humanoid.HealthChanged:Connect(function(health)
		local lostHealth = data.lastHealth - health
		data.lastHealth = health

		if destroyed or lostHealth <= 0
			or gui:GetAttribute("HitReportingMode") == "Confirmed" then
			return
		end

		local pending = combat.pending

		if pending and pending.model == model
			and os.clock() <= pending.expires then
			recordHit(model, lostHealth)
		end
	end)
end

local function rescanTargets()
	local found = {}

	local function add(model)
		local humanoid = targetRig(model)

		if humanoid then
			found[model] = true
			trackTarget(model, humanoid)
		end
	end

	if combatConfig.targetMode ~= "Players" then
		local folder = workspace:FindFirstChild("TrainingDummies")

		if folder then
			for _, descendant in ipairs(folder:GetDescendants()) do
				if descendant:IsA("Humanoid") then
					add(descendant.Parent)
				end
			end
		end
	end

	if combatConfig.targetMode ~= "Training" then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer and player.Character then
				add(player.Character)
			end
		end
	end

	local remove = {}

	for model in pairs(combat.tracked) do
		if not found[model] then
			table.insert(remove, model)
		end
	end

	for _, model in ipairs(remove) do
		local data = combat.tracked[model]

		if data.connection then
			data.connection:Disconnect()
		end

		combat.tracked[model] = nil
	end
end

local function hasLineOfSight(character, origin, model, targetRoot)
	local direction = targetRoot.Position - origin.Position

	if direction.Magnitude < 0.01 then
		return true
	end

	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = { character }
	parameters.IgnoreWater = true

	local result = workspace:Raycast(origin.Position, direction, parameters)

	return result == nil or result.Instance:IsDescendantOf(model)
end

local function nearestTarget(character, root)
	local nearest = nil
	local bestDistance = combatConfig.range

	for model in pairs(combat.tracked) do
		local humanoid, targetRoot = targetRig(model)

		if humanoid and targetRoot then
			local distance = (root.Position - targetRoot.Position).Magnitude

			if distance <= bestDistance
				and hasLineOfSight(character, root, model, targetRoot) then
				bestDistance = distance
				nearest = model
			end
		end
	end

	return nearest
end

----------------------------------------------------------------
-- TOOLS AND ONE SHARED WEAPON SCHEDULER
----------------------------------------------------------------

local function matchesName(name, query)
	return string.find(
		string.lower(name),
		string.lower(query),
		1,
		true
	) ~= nil
end

local function findTool(query, character)
	local backpack = localPlayer:FindFirstChildOfClass("Backpack")
	local partial = nil
	local lowered = string.lower(query)

	for _, container in ipairs({ character, backpack or character }) do
		for _, object in ipairs(container:GetChildren()) do
			if object:IsA("Tool") then
				if string.lower(object.Name) == lowered then
					return object
				elseif not partial and matchesName(object.Name, query) then
					partial = object
				end
			end
		end
	end

	return partial
end

local function shieldDetected(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if model:GetAttribute("Blocking") == true
		or (humanoid and humanoid:GetAttribute("Blocking") == true) then
		return true
	end

	for _, object in ipairs(model:GetChildren()) do
		if object:IsA("Tool")
			and matchesName(object.Name, combatConfig.shieldName) then
			return true
		end
	end

	return false
end

local function finishAction(restore)
	local action = combat.action

	if not action then
		return
	end

	combat.action = nil

	local character, humanoid = getLocalRig()

	if action.activated and action.tool.Parent == character then
		pcall(function()
			action.tool:Deactivate()
		end)
	end

	if not restore or not character or action.character ~= character
		or action.tool.Parent ~= character then
		return
	end

	local previous = action.previous
	local backpack = localPlayer:FindFirstChildOfClass("Backpack")

	if previous and previous.Parent
		and (previous.Parent == character or previous.Parent == backpack) then
		pcall(function()
			humanoid:EquipTool(previous)
		end)
	elseif previous == nil then
		pcall(function()
			humanoid:UnequipTools()
		end)
	end
end

local function chooseTool(model, character, root, now)
	if combatState.stun and shieldDetected(model) then
		local previousAttempt = combat.stunTimes[model] or -math.huge

		if now - previousAttempt >= combatConfig.stunCooldown then
			local axe = findTool(combatConfig.axeName, character)

			if axe and axe.Enabled then
				return axe, "Auto Stun"
			end
		end
	end

	if combatState.mace
		and root.AssemblyLinearVelocity.Y < -combatConfig.maceFallSpeed then
		local mace = findTool(combatConfig.maceName, character)

		if mace and mace.Enabled then
			return mace, "Auto Mace"
		end
	end

	if combatState.sword then
		local sword = findTool(combatConfig.swordName, character)

		if sword and sword.Enabled then
			return sword, "Auto S-Attack"
		end
	end
end

local function tryAttack(now)
	if combat.action or now < combat.nextAttack then
		return
	end

	if not combatState.mace and not combatState.stun and not combatState.sword then
		return
	end

	local character, humanoid, root = getLocalRig()

	if not character then
		combat.status = "Waiting for character"
		return
	end

	local target = nearestTarget(character, root)

	if not target then
		combat.status = "No target in range / line of sight"
		return
	end

	local tool, kind = chooseTool(target, character, root, now)

	if not tool then
		combat.status = "Waiting for enabled tool / attack condition"
		return
	end

	local previous = character:FindFirstChildOfClass("Tool")

	local action = {
		character = character,
		target = target,
		tool = tool,
		previous = previous,
		kind = kind,
		stage = "equip",
		readyAt = now + combatConfig.equipDelay,
		activated = false,
	}

	combat.action = action
	combat.nextAttack = now + combatConfig.cooldown
	combat.lastTarget = target.Name

	if tool.Parent ~= character then
		local equipped = pcall(function()
			humanoid:EquipTool(tool)
		end)

		if not equipped then
			combat.status = "Could not equip " .. tool.Name
			finishAction(false)
		end
	end
end

local function advanceAction(now)
	local action = combat.action

	if not action then
		return
	end

	local enabled = action.kind == "Auto Stun" and combatState.stun
		or action.kind == "Auto Mace" and combatState.mace
		or action.kind == "Auto S-Attack" and combatState.sword

	local character, _, root = getLocalRig()

	if not enabled or not character
		or character ~= action.character
		or action.tool.Parent ~= character then
		finishAction(combatState.swap)
		return
	end

	if now < action.readyAt then
		return
	end

	if action.stage == "equip" then
		local targetHumanoid, targetRoot = targetRig(action.target)

		if not targetHumanoid or not targetRoot
			or (root.Position - targetRoot.Position).Magnitude > combatConfig.range
			or not hasLineOfSight(character, root, action.target, targetRoot) then
			combat.status = "Target left attack range"
			finishAction(combatState.swap)
			return
		end

		if not action.tool.Enabled then
			finishAction(combatState.swap)
			return
		end

		combat.pending = {
			model = action.target,
			expires = now + math.min(combatConfig.cooldown + 0.3, 1.5),
		}

		local activated = pcall(function()
			action.tool:Activate()
		end)

		if activated then
			action.activated = true
			combat.session.attempts = combat.session.attempts + 1
			combat.status = action.kind .. ": activation requested"

			if action.kind == "Auto Stun" then
				combat.stunTimes[action.target] = now
			end
		else
			combat.pending = nil
			combat.status = "Tool activation failed"
		end

		action.stage = "wait"
		action.readyAt = now + combatConfig.swapDelay
	else
		finishAction(combatState.swap)
	end
end

----------------------------------------------------------------
-- RESET COMBAT
----------------------------------------------------------------

connect(resetButton.Activated, function()
	finishAction(true)

	combat.pending = nil
	combat.nextAttack = 0
	combat.markerUntil = 0
	combat.session = newSession()
	combat.lastTarget = "-"
	combat.status = "Reset: automation OFF; display preferences kept"
	combat.stunTimes = setmetatable({}, { __mode = "k" })

	for _, key in ipairs({ "mace", "stun", "sword" }) do
		combatState[key] = false
		combat.refreshers[key]()
	end

	for effect in pairs(combat.effects) do
		effect:Destroy()
	end

	table.clear(combat.effects)
	hitSound:Stop()
end)

connect(localPlayer.CharacterRemoving, function()
	finishAction(false)
	combat.pending = nil
	combat.markerUntil = 0
	combat.session.combo = 0
end)

connect(localPlayer.CharacterAdded, function()
	combat.action = nil
	combat.pending = nil
	combat.nextAttack = 0
	combat.session.combo = 0
end)

----------------------------------------------------------------
-- WINDOW OPEN / CLOSE: ONE HANDLER PER MENU BUTTON
----------------------------------------------------------------

local function closeVisualMenu()
	visualMenuOpen = false
	visualWindow.layer.Visible = false
end

local function closeCombatMenu()
	combatMenuOpen = false
	combatWindow.layer.Visible = false
end

local function openVisualMenu()
	if destroyed or confirmationOpen then
		return
	end

	closeCombatMenu()
	expandMainMenu()

	visualMenuOpen = true
	visualWindow.layer.Visible = true
	fitWindow(visualWindow)
end

local function openCombatMenu()
	if destroyed or confirmationOpen then
		return
	end

	closeVisualMenu()
	expandMainMenu()

	combatMenuOpen = true
	combatWindow.layer.Visible = true
	fitWindow(combatWindow)
end

connect(menuButtons.Visual.button.Activated, openVisualMenu)
connect(menuButtons.Combat.button.Activated, openCombatMenu)

connect(visualWindow.close.Activated, function()
	closeVisualMenu()
	collapseMainMenu()
end)

connect(combatWindow.close.Activated, function()
	closeCombatMenu()
	collapseMainMenu()
end)

----------------------------------------------------------------
-- MAIN CLOSE CONFIRMATION
----------------------------------------------------------------

local closeLayer = create("Frame", {
	Name = "CloseLayer",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.38,
	BorderSizePixel = 0,
	Visible = false,
	Active = true,
	ZIndex = 80,
}, gui)

local closeCard = create("Frame", {
	Name = "CloseCard",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(360, 185),
	BackgroundColor3 = Color3.fromRGB(7, 7, 7),
	BorderSizePixel = 0,
	ZIndex = 81,
}, closeLayer)

addCorner(closeCard, 8)
addStroke(closeCard, 0.02)

textLabel(
	closeCard, "Close Agues 5.0",
	UDim2.fromOffset(20, 22),
	UDim2.new(1, -40, 0, 28), {
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 82,
	}
)

textLabel(
	closeCard, "Are you sure you want to close?",
	UDim2.fromOffset(20, 58),
	UDim2.new(1, -40, 0, 30), {
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 82,
	}
)

local cancelClose = textButton(
	closeCard, "Cancel",
	UDim2.fromOffset(25, 125),
	UDim2.fromOffset(145, 36), 82
)

local yesClose = textButton(
	closeCard, "Yes",
	UDim2.fromOffset(190, 125),
	UDim2.fromOffset(145, 36), 82
)

local function destroyEverything()
	if destroyed then
		return
	end

	finishAction(true)
	destroyed = true
	confirmationOpen = false
	visualMenuOpen = false
	combatMenuOpen = false
	combat.pending = nil

	for _, data in pairs(playerData) do
		destroyTag(data)
		destroyHighlight(data)
	end

	for _, data in pairs(combat.tracked) do
		if data.connection then
			data.connection:Disconnect()
		end
	end

	table.clear(combat.tracked)

	for effect in pairs(combat.effects) do
		effect:Destroy()
	end

	table.clear(combat.effects)

	for _, connection in ipairs(connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end

	table.clear(connections)

	local currentCamera = workspace.CurrentCamera

	if currentCamera then
		currentCamera.FieldOfView = standardFOV
	end

	if gui.Parent then
		gui:Destroy()
	end
end

connect(mainClose.Activated, function()
	if destroyed or confirmationOpen then
		return
	end

	confirmationOpen = true
	closeLayer.Visible = true
end)

connect(cancelClose.Activated, function()
	confirmationOpen = false
	closeLayer.Visible = false
end)

connect(yesClose.Activated, destroyEverything)

styleButton(
	mainClose,
	Color3.fromRGB(5, 5, 5),
	Color3.fromRGB(32, 32, 32)
)

styleButton(
	cancelClose,
	Color3.fromRGB(5, 5, 5),
	Color3.fromRGB(28, 28, 28)
)

styleButton(
	yesClose,
	Color3.fromRGB(5, 5, 5),
	Color3.fromRGB(28, 28, 28)
)

-- Handles re-running the script: destroying the old GUI also cleans
-- its external tags, highlights, connections and combat scheduler.
connect(gui.Destroying, destroyEverything)

----------------------------------------------------------------
-- COMBAT LOOP AND HUD UPDATE
----------------------------------------------------------------

connect(RunService.Heartbeat, function()
	if destroyed then
		return
	end

	local now = os.clock()

	if now >= combat.nextScan then
		combat.nextScan = now + 0.4
		rescanTargets()
		fitWindow(visualWindow)
		fitWindow(combatWindow)
	end

	advanceAction(now)

	if not confirmationOpen then
		tryAttack(now)
	end

	if combat.pending and now > combat.pending.expires then
		combat.pending = nil
	end

	local session = combat.session

	if now - session.lastHit > combatConfig.comboWindow then
		session.combo = 0
	end

	hud.Visible = combatState.combo or combatState.stats
	comboLabel.Visible = combatState.combo
	statsLabel.Visible = combatState.stats

	comboLabel.Text = string.format(
		"Combo: %d | Best: %d",
		session.combo,
		session.best
	)

	local duration = math.max(now - session.started, 1)
	local reporting = gui:GetAttribute("HitReportingMode") == "Confirmed"
		and "Reported"
		or "Observed estimate*"

	statsLabel.Text = string.format(
		"%s | Hits: %d | Damage: %.1f\n"
			.. "Session DPS: %.1f | Attempts: %d\n"
			.. "Target: %s\n%s",
		reporting,
		session.hits,
		session.damage,
		session.damage / duration,
		session.attempts,
		combat.lastTarget,
		combat.status
	)

	crosshair.Visible = combatState.crosshair
	hitmarker.Visible = combatState.hitmarker and now < combat.markerUntil
end)

fitWindow(visualWindow)
fitWindow(combatWindow)
