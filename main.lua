if _G.MaceConfig and _G.MaceConfig.ScreenGui then
    _G.MaceConfig.ScreenGui:Destroy()
end

_G.MaceConfig = {
    KillAura = { Enabled = false, Range = 15 },
    AutoBlock = { Enabled = false },
    Speed = { Enabled = false, Value = 22 },
    ActiveTab = "None",
    ScreenGui = nil,
    MainPanel = nil,
    AllUiElements = {},
    TextLabels = {},
    TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("[Mace PVP]: Часть 1 (Core) успешно запущена!")

task.spawn(function()
    while task.wait(0.1) do
        local config = _G.MaceConfig
        if config and config.KillAura.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHrp = LocalPlayer.Character.HumanoidRootPart
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHrp = player.Character.HumanoidRootPart
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    
                    if humanoid and humanoid.Health > 0 then
                        local distance = (myHrp.Position - targetHrp.Position).Magnitude
                        if distance <= config.KillAura.Range then
                            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                            if tool then tool:Activate() end
                        end
                    end
                end
            end
        end
    end
end)
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local config = _G.MaceConfig

if not config then 
    warn("[Mace PVP Error]: Сначала запусти Часть 1!") 
    return 
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MacePvp_UniversalSuite"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true 
ScreenGui.Parent = CoreGui
config.ScreenGui = ScreenGui

local CLOSED_WIDTH = 55
local OPEN_WIDTH = 160
local PANEL_HEIGHT = 520

local MainPanel = Instance.new("Frame")
MainPanel.Name = "SidebarContainer"
MainPanel.Position = UDim2.new(0, 10, 0.5, 0) 
MainPanel.Size = UDim2.new(0, CLOSED_WIDTH, 0, PANEL_HEIGHT)
MainPanel.AnchorPoint = Vector2.new(0, 0.5)
MainPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainPanel.BorderSizePixel = 1
MainPanel.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainPanel.ClipsDescendants = true 
MainPanel.Active = true
MainPanel.BackgroundTransparency = 1 
MainPanel.Parent = ScreenGui
config.MainPanel = MainPanel

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainPanel

-- Анимация поршня + динамическое переключение текста шапки
MainPanel.MouseEnter:Connect(function()
    TweenService:Create(MainPanel, config.TWEEN_INFO, {Size = UDim2.new(0, OPEN_WIDTH, 0, PANEL_HEIGHT)}):Play()
    
    local LogoButton = MainPanel:FindFirstChild("Logo")
    local LogoLabel = LogoButton and LogoButton:FindFirstChild("CustomIcon")
    if LogoButton and LogoLabel then 
        LogoButton.Size = UDim2.new(0, OPEN_WIDTH, 0, 45)
        LogoLabel.Size = UDim2.new(0, OPEN_WIDTH, 1, 0)
        LogoLabel.Text = "Agues 5.0" 
        LogoLabel.TextSize = 18 
    end
    
    for _, label in ipairs(config.TextLabels) do 
        TweenService:Create(label, config.TWEEN_INFO, {TextTransparency = 0}):Play() 
    end
end)

MainPanel.MouseLeave:Connect(function()
    TweenService:Create(MainPanel, config.TWEEN_INFO, {Size = UDim2.new(0, CLOSED_WIDTH, 0, PANEL_HEIGHT)}):Play()
    
    local LogoButton = MainPanel:FindFirstChild("Logo")
    local LogoLabel = LogoButton and LogoButton:FindFirstChild("CustomIcon")
    if LogoButton and LogoLabel then 
        LogoButton.Size = UDim2.new(0, CLOSED_WIDTH, 0, 45)
        LogoLabel.Size = UDim2.new(0, CLOSED_WIDTH, 1, 0)
        LogoLabel.Text = "A" 
        LogoLabel.TextSize = 28 
    end
    
    for _, label in ipairs(config.TextLabels) do 
        TweenService:Create(label, config.TWEEN_INFO, {TextTransparency = 1}):Play() 
    end
end)

print("[Mace PVP]: Часть 2 (Sidebar с фиксом логотипа) успешно создана!")
local config = _G.MaceConfig

if not config or not config.MainPanel then 
    warn("[Mace PVP Error]: Сначала запусти Части 1 и 2!") 
    return 
end

local tabs = {
    {"A", "Logo"}, {"×", "Close"}, {"👁", "Visual"}, {"⚔", "Combat"}, 
    {"⚙", "Movement"}, {"🎯", "Aim Assist"}, {"📦", "Player"}, 
    {"🛡", "Render"}, {"⚡", "Utility"}, {"⭐", "Automatic"}, {"⌥", "Misc"}        
}

for i, tabData in ipairs(tabs) do
    local iconSymbol = tabData[1]
    local funcName = tabData[2]
    local isHeader = (i == 1 or i == 2)
    
    local TabButton = Instance.new("TextButton")
    TabButton.Name = funcName
    -- Изначально ставим логотип в размер закрытой панели, чтобы буква А была строго по центру
    TabButton.Size = (i == 1) and UDim2.new(0, 55, 0, 45) or (isHeader and UDim2.new(1, 0, 0, 45) or UDim2.new(0.9, 0, 0, 38))
    TabButton.Position = isHeader and UDim2.new(0, 0, 0, (i-1)*45) or UDim2.new(0.05, 0, 0, 95 + (i-3)*43)
    TabButton.BackgroundColor3 = isHeader and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(15, 15, 15)
    TabButton.BorderSizePixel = isHeader and 0 or 1
    TabButton.BorderColor3 = Color3.fromRGB(60, 60, 60)
    TabButton.Text = ""
    TabButton.AutoButtonColor = false
    TabButton.BackgroundTransparency = 1
    TabButton.Parent = config.MainPanel
    table.insert(config.AllUiElements, {instance = TabButton, defaultTrans = 0})
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = TabButton

    if i == 2 then
        local Line = Instance.new("Frame")
        Line.Size = UDim2.new(1, 0, 0, 1)
        Line.Position = UDim2.new(0, 0, 0, 44)
        Line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Line.BorderSizePixel = 0
        Line.BackgroundTransparency = 1
        Line.Parent = TabButton
        table.insert(config.AllUiElements, {instance = Line, defaultTrans = 0})
    end

    local CustomIcon = Instance.new("TextLabel")
    CustomIcon.Name = "CustomIcon"
    CustomIcon.BackgroundTransparency = 1
    CustomIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    CustomIcon.Text = iconSymbol
    CustomIcon.TextTransparency = 1
    CustomIcon.Parent = TabButton
    table.insert(config.AllUiElements, {instance = CustomIcon, defaultTrans = 0})
    
    if i == 1 then
        CustomIcon.Size = UDim2.new(0, 55, 1, 0)
        CustomIcon.Position = UDim2.new(0, 0, 0, 0)
        CustomIcon.Font = Enum.Font.FredokaOne
        CustomIcon.TextSize = 28
        CustomIcon.TextXAlignment = Enum.TextXAlignment.Center
    elseif i == 2 then
        CustomIcon.Size = UDim2.new(1, 0, 1, 0)
        CustomIcon.Font = Enum.Font.GothamBold
        CustomIcon.TextSize = 20
    else
        CustomIcon.Size = UDim2.new(0, 24, 0, 24)
        CustomIcon.Position = UDim2.new(0, 15, 0.5, 0)
        CustomIcon.AnchorPoint = Vector2.new(0, 0.5)
        CustomIcon.Font = Enum.Font.GothamMedium
        CustomIcon.TextSize = 16
    end
    
    if not isHeader then
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0, 80, 1, 0)
        Label.Position = UDim2.new(0, 48, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = funcName
        Label.TextColor3 = Color3.fromRGB(230, 230, 230)
        Label.TextSize = 13
        Label.Font = Enum.Font.GothamMedium
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextTransparency = 1 
        Label.Parent = TabButton
        
        local Arrow = Instance.new("TextLabel")
        Arrow.Size = UDim2.new(0, 15, 1, 0)
        Arrow.Position = UDim2.new(1, -20, 0, 0)
        Arrow.BackgroundTransparency = 1
        Arrow.Text = ">"
        Arrow.TextColor3 = Color3.fromRGB(150, 150, 150)
        Arrow.TextSize = 12
        Arrow.Font = Enum.Font.GothamBold
        Arrow.TextXAlignment = Enum.TextXAlignment.Right
        Arrow.TextTransparency = 1 
        Arrow.Parent = TabButton

        table.insert(config.TextLabels, Label)
        table.insert(config.TextLabels, Arrow)
    end
end

print("[Mace PVP]: Часть 3 (Tabs с фиксом логотипа) успешно сгенерирована!")
local config = _G.MaceConfig

if not config or not config.ScreenGui then 
    warn("[Mace PVP Error]: Сначала запусти Часть 1!") 
    return 
end

local PromptFrame = Instance.new("Frame")
PromptFrame.Name = "ClosePrompt"
PromptFrame.Size = UDim2.new(0, 260, 0, 130)
PromptFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
PromptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
PromptFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
PromptFrame.BorderSizePixel = 1
PromptFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
PromptFrame.Visible = false
PromptFrame.BackgroundTransparency = 1
PromptFrame.Parent = config.ScreenGui

-- Сильное закругление окна подтверждения
Instance.new("UICorner", PromptFrame).CornerRadius = UDim.new(0, 16)

local PromptText = Instance.new("TextLabel")
PromptText.Size = UDim2.new(1, 0, 0, 50)
PromptText.Position = UDim2.new(0, 0, 0, 15)
PromptText.BackgroundTransparency = 1
PromptText.Text = "Are you sure you want to close?"
PromptText.TextColor3 = Color3.fromRGB(255, 255, 255)
PromptText.TextSize = 14
PromptText.Font = Enum.Font.GothamMedium
PromptText.TextTransparency = 1
PromptText.Parent = PromptFrame

local YesBtn = Instance.new("TextButton")
YesBtn.Name = "Yes"
YesBtn.Size = UDim2.new(0, 100, 0, 35)
YesBtn.Position = UDim2.new(0, 20, 1, -50)
YesBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
YesBtn.BorderSizePixel = 1
YesBtn.BorderColor3 = Color3.fromRGB(80, 80, 80)
YesBtn.Text = "Yes"
YesBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
YesBtn.Font = Enum.Font.GothamBold
YesBtn.TextSize = 13
YesBtn.BackgroundTransparency = 1
YesBtn.TextTransparency = 1
YesBtn.Parent = PromptFrame
Instance.new("UICorner", YesBtn).CornerRadius = UDim.new(0, 10)

local CancelBtn = Instance.new("TextButton")
CancelBtn.Name = "Cancel"
CancelBtn.Size = UDim2.new(0, 100, 0, 35)
CancelBtn.Position = UDim2.new(1, -120, 1, -50)
CancelBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CancelBtn.BorderSizePixel = 1
CancelBtn.BorderColor3 = Color3.fromRGB(80, 80, 80)
CancelBtn.Text = "Cancel"
CancelBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CancelBtn.Font = Enum.Font.GothamMedium
CancelBtn.TextSize = 13
CancelBtn.BackgroundTransparency = 1
CancelBtn.TextTransparency = 1
CancelBtn.Parent = PromptFrame
Instance.new("UICorner", CancelBtn).CornerRadius = UDim.new(0, 10)

print("[Mace PVP]: Часть 4 (Prompt Frame) успешно создана!")
local TweenService = game:GetService("TweenService")
local config = _G.MaceConfig

if not config or not config.MainPanel then 
    warn("[Mace PVP Error]: Ошибка инициализации финального контроллера!") 
    return 
end

local MainPanel = config.MainPanel
local PromptFrame = MainPanel.Parent:FindFirstChild("ClosePrompt")
local PromptText = PromptFrame and PromptFrame:FindFirstChild("TextLabel")
local YesBtn = PromptFrame and PromptFrame:FindFirstChild("Yes")
local CancelBtn = PromptFrame and PromptFrame:FindFirstChild("Cancel")

local function fadeUI(mode)
    local target = (mode == "open") and 0 or 1
    TweenService:Create(MainPanel, config.TWEEN_INFO, {BackgroundTransparency = target}):Play()
    for _, item in ipairs(config.AllUiElements) do
        if item.instance:IsA("TextButton") or item.instance:IsA("Frame") then
            TweenService:Create(item.instance, config.TWEEN_INFO, {BackgroundTransparency = target == 1 and 1 or item.defaultTrans}):Play()
        end
        if item.instance:IsA("TextLabel") then
            TweenService:Create(item.instance, config.TWEEN_INFO, {TextTransparency = target == 1 and 1 or item.defaultTrans}):Play()
        end
    end
end

local function togglePrompt(open)
    if not PromptFrame then return end
    if open then
        PromptFrame.Visible = true
        TweenService:Create(PromptFrame, config.TWEEN_INFO, {BackgroundTransparency = 0}):Play()
        TweenService:Create(PromptText, config.TWEEN_INFO, {TextTransparency = 0}):Play()
        TweenService:Create(YesBtn, config.TWEEN_INFO, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        TweenService:Create(CancelBtn, config.TWEEN_INFO, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
    else
        local tween = TweenService:Create(PromptFrame, config.TWEEN_INFO, {BackgroundTransparency = 1})
        TweenService:Create(PromptText, config.TWEEN_INFO, {TextTransparency = 1}):Play()
        TweenService:Create(YesBtn, config.TWEEN_INFO, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        TweenService:Create(CancelBtn, config.TWEEN_INFO, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        tween:Play()
        tween.Completed:Connect(function() PromptFrame.Visible = false end)
    end
end

for _, button in ipairs(MainPanel:GetChildren()) do
    if button:IsA("TextButton") then
        button.MouseButton1Click:Connect(function()
            if button.Name == "Close" then
                togglePrompt(true)
            elseif button.Name ~= "Logo" then
                config.ActiveTab = button.Name
                print("[Mace PVP]: Выбрана вкладка:", button.Name)
                
                if button.Name == "Combat" then
                    config.KillAura.Enabled = not config.KillAura.Enabled
                    print("[Mace Status] KillAura теперь:", config.KillAura.Enabled)
                end
            end
        end)
    end
end

if CancelBtn then CancelBtn.MouseButton1Click:Connect(function() togglePrompt(false) end) end

if YesBtn then
    YesBtn.MouseButton1Click:Connect(function()
        togglePrompt(false)
        fadeUI("close")
        task.wait(0.3)
        if config.ScreenGui then config.ScreenGui:Destroy() end
        _G.MaceConfig = nil
    end)
end

fadeUI("open")
print("[Mace PVP]: Финальный контроллер загружен. Название Agues 5.0 интегрировано!")
-- ПЕРЕМЕННАЯ ДЛЯ ПРОВЕРКИ СКАЧИВАНИЯ МОДУЛЯ VISUAL
local visualMenuLoaded = false

for _, button in ipairs(MainPanel:GetChildren()) do
    if button:IsA("TextButton") then
        button.MouseButton1Click:Connect(function()
            if button.Name == "Close" then
                togglePrompt(true)
            elseif button.Name == "Visual" then
                config.ActiveTab = button.Name
                print("[Mace PVP]: Активация вкладки Visual...")
                
                -- Если меню еще не скачано — загружаем через твой loadstring
                if not visualMenuLoaded then
                    visualMenuLoaded = true
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/Zigzagchik/Agues5.0-test/refs/heads/main/visual.lua"))()
                else
                    -- Если файл уже скачан, просто вызываем его глобальную функцию открытия
                    if _G.ToggleAguesVisualMenu then
                        _G.ToggleAguesVisualMenu(true)
                    end
                end
            elseif button.Name ~= "Logo" then
                config.ActiveTab = button.Name
                print("[Mace PVP]: Выбрана вкладка:", button.Name)
                if button.Name == "Combat" then
                    config.KillAura.Enabled = not config.KillAura.Enabled
                    print("[Mace Status] KillAura теперь:", config.KillAura.Enabled)
                end
            end
        end)
    end
end
