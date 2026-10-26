-- ============================================================================
-- ВНЕШНИЙ СКРИПТ: ОКНО ФУНКЦИЙ VISUAL (VISUAL.LUA)
-- ============================================================================
local TweenService = game:GetService("TweenService")
local config = _G.MaceConfig

if not config then return end

config.Visuals = {
    ChamsEnabled = false,
    NamesEnabled = false,
    ChamsColor = Color3.fromRGB(255, 0, 75)
}

local menuFadeElements = {}

local VisualMenu = Instance.new("Frame")
VisualMenu.Name = "VisualMenuWindow"
VisualMenu.Size = UDim2.new(0, 300, 0, 200)
VisualMenu.Position = UDim2.new(0.5, 0, 0.5, 0)
VisualMenu.AnchorPoint = Vector2.new(0.5, 0.5)
VisualMenu.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
VisualMenu.BorderSizePixel = 1
VisualMenu.BorderColor3 = Color3.fromRGB(255, 255, 255)
VisualMenu.ClipsDescendants = true
VisualMenu.Parent = config.ScreenGui

Instance.new("UICorner", VisualMenu).CornerRadius = UDim.new(0, 16)

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 40)
MenuTitle.Position = UDim2.new(0, 0, 0, 10)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "Agues Visual"
MenuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuTitle.TextSize = 16
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextXAlignment = Enum.TextXAlignment.Center
MenuTitle.Parent = VisualMenu
table.insert(menuFadeElements, {instance = MenuTitle, type = "Text"})

local MenuCloseBtn = Instance.new("TextButton")
MenuCloseBtn.Size = UDim2.new(0, 24, 0, 24)
MenuCloseBtn.Position = UDim2.new(1, -34, 0, 14)
MenuCloseBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MenuCloseBtn.BorderSizePixel = 1
MenuCloseBtn.BorderColor3 = Color3.fromRGB(60, 60, 60)
MenuCloseBtn.Text = "×"
MenuCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuCloseBtn.Font = Enum.Font.GothamBold
MenuCloseBtn.Parent = VisualMenu
table.insert(menuFadeElements, {instance = MenuCloseBtn, type = "Button"})
Instance.new("UICorner", MenuCloseBtn).CornerRadius = UDim.new(0, 6)

local ButtonsContainer = Instance.new("Frame")
ButtonsContainer.Size = UDim2.new(1, -40, 1, -70)
ButtonsContainer.Position = UDim2.new(0, 20, 0, 60)
ButtonsContainer.BackgroundTransparency = 1
ButtonsContainer.Parent = VisualMenu

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = ButtonsContainer

local function toggleVisualMenu(open)
    if open then
        VisualMenu.Visible = true
        TweenService:Create(VisualMenu, config.TWEEN_INFO, {BackgroundTransparency = 0}):Play()
        for _, el in ipairs(menuFadeElements) do
            if el.type == "Text" then TweenService:Create(el.instance, config.TWEEN_INFO, {TextTransparency = 0}):Play()
            elseif el.type == "Button" then TweenService:Create(el.instance, config.TWEEN_INFO, {BackgroundTransparency = 0, TextTransparency = 0}):Play() end
        end
    else
        local tween = TweenService:Create(VisualMenu, config.TWEEN_INFO, {BackgroundTransparency = 1})
        for _, el in ipairs(menuFadeElements) do
            if el.type == "Text" then TweenService:Create(el.instance, config.TWEEN_INFO, {TextTransparency = 1}):Play()
            elseif el.type == "Button" then TweenService:Create(el.instance, config.TWEEN_INFO, {BackgroundTransparency = 1, TextTransparency = 1}):Play() end
        end
        tween:Play()
        tween.Completed:Connect(function() VisualMenu.Visible = false end)
    end
end

_G.ToggleAguesVisualMenu = toggleVisualMenu

local function CreateVisualToggle(name, layoutOrder, callback)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, 0, 0, 36)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ToggleBtn.BorderSizePixel = 1
    ToggleBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
    ToggleBtn.Text = "  " .. name
    ToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    ToggleBtn.TextSize = 13
    ToggleBtn.Font = Enum.Font.GothamMedium
    ToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    ToggleBtn.LayoutOrder = layoutOrder
    ToggleBtn.Parent = ButtonsContainer
    table.insert(menuFadeElements, {instance = ToggleBtn, type = "Button"})
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

    local StatusIndicator = Instance.new("Frame")
    StatusIndicator.Size = UDim2.new(0, 10, 0, 10)
    StatusIndicator.Position = UDim2.new(1, -20, 0.5, 0)
    StatusIndicator.AnchorPoint = Vector2.new(0, 0.5)
    StatusIndicator.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    StatusIndicator.Parent = ToggleBtn
    table.insert(menuFadeElements, {instance = StatusIndicator, type = "Button"})
    Instance.new("UICorner", StatusIndicator).CornerRadius = UDim.new(0, 4)

    local state = false
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        StatusIndicator.BackgroundColor3 = state and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(40, 40, 40)
        ToggleBtn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
        callback(state)
    end)
end

CreateVisualToggle("Player Chams (Wallhack)", 1, function(enabled) config.Visuals.ChamsEnabled = enabled end)
CreateVisualToggle("Name & Distance ESP", 2, function(enabled) config.Visuals.NamesEnabled = enabled end)

MenuCloseBtn.MouseButton1Click:Connect(function() toggleVisualMenu(false) end)

local function applyESP(player)
    if player == game.Players.LocalPlayer then return end
    local function setupChar(char)
        if char:FindFirstChild("Agues_Chams") then char.Agues_Chams:Destroy() end
        local highlight = Instance.new("Highlight", char)
        highlight.Name = "Agues_Chams"
        highlight.FillColor = config.Visuals.ChamsColor
        highlight.FillTransparency = 0.4
        highlight.Enabled = false
        
        local head = char:WaitForChild("Head", 5)
        if head and not head:FindFirstChild("Agues_NameESP") then
            local bbGui = Instance.new("BillboardGui", head)
            bbGui.Name = "Agues_NameESP"
            bbGui.AlwaysOnTop = true
            bbGui.Size = UDim2.new(0, 200, 0, 50)
            bbGui.StudsOffset = Vector3.new(0, 2, 0)
            local textLabel = Instance.new("TextLabel", bbGui)
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.Font = Enum.Font.GothamBold
            textLabel.TextSize = 12
        end
    end
    if player.Character then setupChar(player.Character) end
    player.CharacterAdded:Connect(setupChar)
end

for _, p in ipairs(game.Players:GetPlayers()) do applyESP(p) end
game.Players.PlayerAdded:Connect(applyESP)

task.spawn(function()
    while task.wait(0.1) do
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character then
                local char = player.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local chams = char:FindFirstChild("Agues_Chams")
                if chams then chams.Enabled = config.Visuals.ChamsEnabled end

                local head = char:FindFirstChild("Head")
                local bbGui = head and head:FindFirstChild("Agues_NameESP")
                local label = bbGui and bbGui:FindFirstChild("TextLabel")
                if bbGui and label and hrp and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    bbGui.Enabled = config.Visuals.NamesEnabled
                    if config.Visuals.NamesEnabled then
                        local distance = math.floor((game.Players.LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                        label.Text = player.Name .. " [" .. distance .. " studs]"
                    end
                end
            end
        end
    end
end)

toggleVisualMenu(true)
