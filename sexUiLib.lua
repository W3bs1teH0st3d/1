-- ============================================================
--  DARK GLASSMORPHISM UI LIBRARY
--  Toggle: Right Shift (RShift)
--  Автор: Custom
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  MAIN LIBRARY TABLE
-- ============================================================
local GlassUI = {}
GlassUI.__index = GlassUI

-- Настройки библиотеки
GlassUI.Settings = {
    ToggleKey = Enum.KeyCode.RightShift,
    AccentColor = Color3.fromRGB(59, 130, 246),      -- синий акцент
    AccentColorHover = Color3.fromRGB(96, 165, 250),
    BackgroundColor = Color3.fromRGB(15, 15, 25),
    PanelColor = Color3.fromRGB(20, 20, 35),
    TextColor = Color3.fromRGB(255, 255, 255),
    TextColorDim = Color3.fromRGB(150, 150, 170),
    ToggleOnColor = Color3.fromRGB(59, 130, 246),
    ToggleOffColor = Color3.fromRGB(60, 60, 80),
    SliderTrackColor = Color3.fromRGB(40, 40, 60),
    SliderFillColor = Color3.fromRGB(59, 130, 246),
    BorderColor = Color3.fromRGB(40, 40, 60),
    SuccessColor = Color3.fromRGB(34, 197, 94),
    DangerColor = Color3.fromRGB(239, 68, 68),
    WarningColor = Color3.fromRGB(234, 179, 8),
    Font = Font.new("rbxasset://fonts/families/GothamSSm.json"),
    FontBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
    CornerRadius = UDim.new(0, 12),
    SmallCornerRadius = UDim.new(0, 8),
    AnimationSpeed = 0.3,
}

-- ============================================================
--  UTILITY FUNCTIONS
-- ============================================================

function GlassUI:RoundNumber(num, places)
    local mult = 10^(places or 1)
    return math.floor(num * mult + 0.5) / mult
end

function GlassUI:Lerp(a, b, t)
    return a + (b - a) * t
end

function GlassUI:Create(instanceType, properties)
    local obj = Instance.new(instanceType)
    for prop, val in pairs(properties) do
        if prop ~= "Parent" then
            obj[prop] = val
        end
    end
    if properties.Parent then
        obj.Parent = properties.Parent
    end
    return obj
end

function GlassUI:CreateCorner(parent, radius)
    local corner = self:Create("UICorner", {
        CornerRadius = radius or self.Settings.CornerRadius,
        Parent = parent,
    })
    return corner
end

function GlassUI:CreateStroke(parent, color, thickness)
    local stroke = self:Create("UIStroke", {
        Color = color or self.Settings.BorderColor,
        Thickness = thickness or 1,
        Transparency = 0.5,
        Parent = parent,
    })
    return stroke
end

function GlassUI:Tween(obj, props, duration, style, direction)
    duration = duration or self.Settings.AnimationSpeed
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local tween = TweenService:Create(obj, TweenInfo.new(duration, style, direction), props)
    tween:Play()
    return tween
end

function GlassUI:MakeDraggable(frame, dragBar)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
end

-- ============================================================
--  SCREEN SETUP
-- ============================================================

local ScreenGui = self:Create("ScreenGui", {
    Name = "GlassUI",
    Parent = LocalPlayer:WaitForChild("PlayerGui"),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
})

local MainFrame = self:Create("Frame", {
    Name = "MainFrame",
    Parent = ScreenGui,
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 1,
})

-- ============================================================
--  WATERMARK
-- ============================================================

local WatermarkFrame = self:Create("Frame", {
    Name = "Watermark",
    Parent = MainFrame,
    BackgroundColor3 = self.Settings.PanelColor,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 16, 0, 16),
    Size = UDim2.new(0, 0, 0, 0),
    ZIndex = 100,
    ClipsDescendants = true,
})

self:CreateCorner(WatermarkFrame, UDim.new(0, 8))
self:CreateStroke(WatermarkFrame, self.Settings.BorderColor, 1)

-- Ватермарка: левая часть (название + корона)
local WatermarkLeft = self:Create("Frame", {
    Name = "Left",
    Parent = WatermarkFrame,
    BackgroundColor3 = self.Settings.AccentColor,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(0, 0, 1, 0),
    ZIndex = 101,
})

self:CreateCorner(WatermarkLeft, UDim.new(0, 8))

local WatermarkIcon = self:Create("ImageLabel", {
    Name = "Icon",
    Parent = WatermarkLeft,
    BackgroundTransparency = 1,
    Image = "rbxassetid://12877753076", -- корона
    ImageColor3 = Color3.fromRGB(255, 255, 255),
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(0, 8, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    ZIndex = 102,
})

local WatermarkTitle = self:Create("TextLabel", {
    Name = "Title",
    Parent = WatermarkLeft,
    BackgroundTransparency = 1,
    Text = "Alpha",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 13,
    FontFace = self.Settings.FontBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 26, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    Size = UDim2.new(0, 0, 1, 0),
    ZIndex = 102,
})

-- Ватермарка: правая часть (никнейм)
local WatermarkRight = self:Create("Frame", {
    Name = "Right",
    Parent = WatermarkFrame,
    BackgroundColor3 = self.Settings.PanelColor,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 0, 1, 0),
    ZIndex = 101,
})

self:CreateCorner(WatermarkRight, UDim.new(0, 8))

local WatermarkNick = self:Create("TextLabel", {
    Name = "Nick",
    Parent = WatermarkRight,
    BackgroundTransparency = 1,
    Text = LocalPlayer.Name,
    TextColor3 = self.Settings.TextColor,
    TextSize = 13,
    FontFace = self.Settings.Font,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 10, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    Size = UDim2.new(0, 0, 1, 0),
    ZIndex = 102,
})

-- Индикатор тиков
local TickIndicator = self:Create("Frame", {
    Name = "TickIndicator",
    Parent = WatermarkFrame,
    BackgroundColor3 = self.Settings.PanelColor,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 0, 0, 0),
    Position = UDim2.new(0, 0, 1, 4),
    ZIndex = 100,
})

self:CreateCorner(TickIndicator, UDim.new(0, 6))

local TickText = self:Create("TextLabel", {
    Name = "TickText",
    Parent = TickIndicator,
    BackgroundTransparency = 1,
    Text = "20 Ticks",
    TextColor3 = self.Settings.TextColorDim,
    TextSize = 11,
    FontFace = self.Settings.Font,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 101,
})

-- Анимация ватермарки
local function AnimateWatermarkIn()
    self:Tween(WatermarkFrame, {
        Size = UDim2.new(0, 160, 0, 32),
        Position = UDim2.new(0, 16, 0, 16),
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    self:Tween(WatermarkLeft, {
        Size = UDim2.new(0, 70, 1, 0),
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    self:Tween(WatermarkRight, {
        Size = UDim2.new(0, 86, 1, 0),
        Position = UDim2.new(0, 74, 0, 0),
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    self:Tween(WatermarkTitle, {
        Size = UDim2.new(0, 40, 1, 0),
    }, 0.4)

    self:Tween(WatermarkNick, {
        Size = UDim2.new(0, 76, 1, 0),
    }, 0.4)

    self:Tween(TickIndicator, {
        Size = UDim2.new(0, 60, 0, 20),
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function AnimateWatermarkOut()
    self:Tween(WatermarkFrame, {
        Size = UDim2.new(0, 0, 0, 0),
    }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

-- ============================================================
--  PLAYER LIST (верхний правый угол)
-- ============================================================

local PlayerListFrame = self:Create("Frame", {
    Name = "PlayerList",
    Parent = MainFrame,
    BackgroundColor3 = self.Settings.PanelColor,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -16, 0, 16),
    AnchorPoint = Vector2.new(1, 0),
    Size = UDim2.new(0, 180, 0, 0),
    ZIndex = 100,
    ClipsDescendants = true,
})

self:CreateCorner(PlayerListFrame, UDim.new(0, 10))
self:CreateStroke(PlayerListFrame, self.Settings.BorderColor, 1)

local PlayerListLayout = self:Create("UIListLayout", {
    Parent = PlayerListFrame,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
})

local PlayerListPadding = self:Create("UIPadding", {
    Parent = PlayerListFrame,
    PaddingTop = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
})

-- Функция обновления списка игроков
function GlassUI:UpdatePlayerList()
    -- Удаляем старые
    for _, child in pairs(PlayerListFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name == "PlayerEntry" then
            child:Destroy()
        end
    end

    local entries = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(entries, player)
        end
    end
    table.sort(entries, function(a, b) return a.Name < b.Name end)

    for i, player in ipairs(entries) do
        local entry = self:Create("Frame", {
            Name = "PlayerEntry",
            Parent = PlayerListFrame,
            BackgroundColor3 = Color3.fromRGB(30, 30, 50),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 24),
            LayoutOrder = i,
            ZIndex = 101,
        })

        self:CreateCorner(entry, UDim.new(0, 6))

        -- Аватар
        local avatar = self:Create("ImageLabel", {
            Name = "Avatar",
            Parent = entry,
            BackgroundTransparency = 1,
            Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48),
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 4, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            ZIndex = 102,
        })
        self:CreateCorner(avatar, UDim.new(0, 4))

        -- Имя
        local nameLbl = self:Create("TextLabel", {
            Name = "Name",
            Parent = entry,
            BackgroundTransparency = 1,
            Text = player.Name,
            TextColor3 = self.Settings.TextColor,
            TextSize = 12,
            FontFace = self.Settings.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 30, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 80, 1, 0),
            ZIndex = 102,
        })

        -- Префикс (рандомный цвет для примера)
        local prefixColors = {
            Color3.fromRGB(59, 130, 246),
            Color3.fromRGB(34, 197, 94),
            Color3.fromRGB(234, 179, 8),
            Color3.fromRGB(239, 68, 68),
            Color3.fromRGB(168, 85, 247),
        }
        local prefixColor = prefixColors[(player.UserId % #prefixColors) + 1]

        local prefixDot = self:Create("Frame", {
            Name = "PrefixDot",
            Parent = entry,
            BackgroundColor3 = prefixColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 6, 0, 6),
            Position = UDim2.new(1, -14, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            ZIndex = 102,
        })
        self:CreateCorner(prefixDot, UDim.new(0, 3))
    end

    -- Анимация высоты
    local totalHeight = #entries * 26 + 16
    self:Tween(PlayerListFrame, {
        Size = UDim2.new(0, 180, 0, totalHeight),
    }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

-- ============================================================
--  MAIN MENU CONTAINER
-- ============================================================

local MenuContainer = self:Create("Frame", {
    Name = "MenuContainer",
    Parent = MainFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 50,
})

-- Затемнение фона
local BackgroundDim = self:Create("Frame", {
    Name = "BackgroundDim",
    Parent = MenuContainer,
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.5,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 51,
    Visible = false,
})

-- ============================================================
--  TAB BAR (верхняя панель вкладок)
-- ============================================================

local TabBar = self:Create("Frame", {
    Name = "TabBar",
    Parent = MenuContainer,
    BackgroundColor3 = self.Settings.PanelColor,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 0, 0, 60),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0, 700, 0, 44),
    ZIndex = 60,
    Visible = false,
})

self:CreateCorner(TabBar, UDim.new(0, 14))
self:CreateStroke(TabBar, self.Settings.BorderColor, 1.5)

local TabBarLayout = self:Create("UIListLayout", {
    Parent = TabBar,
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
})

local TabBarPadding = self:Create("UIPadding", {
    Parent = TabBar,
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
})

-- ============================================================
--  MODULE PANELS (5 колонок)
-- ============================================================

local PanelsContainer = self:Create("Frame", {
    Name = "PanelsContainer",
    Parent = MenuContainer,
    BackgroundTransparency = 1,
    Position = UDim2.new(0.5, 0, 0, 114),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0, 700, 0, 400),
    ZIndex = 55,
    Visible = false,
})

-- Категории
local Categories = {
    { Name = "Combat", Icon = "⚔" },
    { Name = "Movement", Icon = "🏃" },
    { Name = "Visuals", Icon = "👁" },
    { Name = "Player", Icon = "👤" },
    { Name = "Misc", Icon = "⚙" },
}

local CategoryPanels = {}
local ActiveCategory = nil
local Tabs = {}

-- Создаём вкладки и панели
for i, cat in ipairs(Categories) do
    -- Вкладка
    local tab = self:Create("TextButton", {
        Name = cat.Name,
        Parent = TabBar,
        BackgroundColor3 = Color3.fromRGB(30, 30, 50),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(0, 0, 1, -12),
        ZIndex = 61,
        LayoutOrder = i,
        AutoButtonColor = false,
    })

    self:CreateCorner(tab, UDim.new(0, 8))

    local tabIcon = self:Create("TextLabel", {
        Name = "Icon",
        Parent = tab,
        BackgroundTransparency = 1,
        Text = cat.Icon,
        TextSize = 14,
        FontFace = self.Settings.Font,
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 20, 0, 20),
        ZIndex = 62,
    })

    local tabText = self:Create("TextLabel", {
        Name = "Text",
        Parent = tab,
        BackgroundTransparency = 1,
        Text = cat.Name,
        TextColor3 = self.Settings.TextColorDim,
        TextSize = 13,
        FontFace = self.Settings.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 32, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 62,
    })

    -- Индикатор активной вкладки
    local tabIndicator = self:Create("Frame", {
        Name = "Indicator",
        Parent = tab,
        BackgroundColor3 = self.Settings.AccentColor,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        ZIndex = 63,
        Visible = false,
    })
    self:CreateCorner(tabIndicator, UDim.new(0, 2))

    Tabs[cat.Name] = tab

    -- Панель модулей
    local panel = self:Create("Frame", {
        Name = cat.Name .. "Panel",
        Parent = PanelsContainer,
        BackgroundColor3 = self.Settings.PanelColor,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 56,
        Visible = false,
        ClipsDescendants = true,
    })

    self:CreateCorner(panel, UDim.new(0, 12))
    self:CreateStroke(panel, self.Settings.BorderColor, 1)

    -- Заголовок панели
    local panelHeader = self:Create("Frame", {
        Name = "Header",
        Parent = panel,
        BackgroundColor3 = self.Settings.AccentColor,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 57,
    })

    self:CreateCorner(panelHeader, UDim.new(0, 12))

    local headerText = self:Create("TextLabel", {
        Name = "Title",
        Parent = panelHeader,
        BackgroundTransparency = 1,
        Text = cat.Name,
        TextColor3 = self.Settings.TextColor,
        TextSize = 14,
        FontFace = self.Settings.FontBold,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 58,
    })

    -- Разделитель
    local divider = self:Create("Frame", {
        Name = "Divider",
        Parent = panel,
        BackgroundColor3 = self.Settings.BorderColor,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -16, 0, 1),
        Position = UDim2.new(0, 8, 0, 36),
        ZIndex = 57,
    })

    -- Контейнер модулей
    local moduleContainer = self:Create("ScrollingFrame", {
        Name = "ModuleContainer",
        Parent = panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 42),
        Size = UDim2.new(1, -16, 1, -50),
        ZIndex = 58,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Settings.AccentColor,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
    })

    local moduleLayout = self:Create("UIListLayout", {
        Parent = moduleContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    local modulePadding = self:Create("UIPadding", {
        Parent = moduleContainer,
        PaddingBottom = UDim.new(0, 8),
    })

    moduleContainer:GetPropertyChangedSignal("CanvasSize"):Connect(function()
        moduleContainer.CanvasSize = UDim2.new(0, 0, 0, moduleLayout.AbsoluteContentSize.Y + 8)
    end)

    CategoryPanels[cat.Name] = {
        Panel = panel,
        Container = moduleContainer,
        Layout = moduleLayout,
        Tab = tab,
        Indicator = tabIndicator,
        TabText = tabText,
    }
end

-- ============================================================
--  ФУНКЦИЯ ПЕРЕКЛЮЧЕНИЯ ВКЛАДОК
-- ============================================================

function GlassUI:SwitchCategory(categoryName)
    if ActiveCategory == categoryName then return end

    -- Скрыть текущую
    if ActiveCategory and CategoryPanels[ActiveCategory] then
        local prev = CategoryPanels[ActiveCategory]
        self:Tween(prev.Panel, { Size = UDim2.new(0, 0, 1, 0) }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        self:Tween(prev.Tab, { BackgroundTransparency = 0.5 }, 0.2)
        prev.TabText.TextColor3 = self.Settings.TextColorDim
        prev.Indicator.Visible = false
        prev.Panel.Visible = false
    end

    -- Показать новую
    local curr = CategoryPanels[categoryName]
    if curr then
        curr.Panel.Visible = true
        curr.Panel.Size = UDim2.new(0, 0, 1, 0)
        self:Tween(curr.Panel, { Size = UDim2.new(1, 0, 1, 0) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        self:Tween(curr.Tab, { BackgroundTransparency = 0.1 }, 0.2)
        curr.TabText.TextColor3 = self.Settings.TextColor
        curr.Indicator.Visible = true
        ActiveCategory = categoryName
    end
end

-- Клики по вкладкам
for name, tabData in pairs(Tabs) do
    tabData.MouseButton1Click:Connect(function()
        self:SwitchCategory(name)
    end)

    -- Hover эффекты
    tabData.MouseEnter:Connect(function()
        if ActiveCategory ~= name then
            self:Tween(tabData, { BackgroundTransparency = 0.3 }, 0.15)
        end
    end)
    tabData.MouseLeave:Connect(function()
        if ActiveCategory ~= name then
            self:Tween(tabData, { BackgroundTransparency = 0.5 }, 0.15)
        end
    end)
end

-- ============================================================
--  MODULE CREATION FUNCTIONS
-- ============================================================

-- Toggle модуль
function GlassUI:CreateToggle(panelName, text, default, callback)
    local panelData = CategoryPanels[panelName]
    if not panelData then return end

    local container = panelData.Container
    local layoutOrder = #container:GetChildren() + 1

    local toggleFrame = self:Create("Frame", {
        Name = "Toggle",
        Parent = container,
        BackgroundColor3 = Color3.fromRGB(25, 25, 45),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = layoutOrder,
        ZIndex = 59,
        ClipsDescendants = true,
    })

    self:CreateCorner(toggleFrame, UDim.new(0, 8))

    -- Текст
    local toggleText = self:Create("TextLabel", {
        Name = "Text",
        Parent = toggleFrame,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Settings.TextColor,
        TextSize = 13,
        FontFace = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 140, 1, 0),
        ZIndex = 60,
    })

    -- Кнопка настроек (...)
    local settingsBtn = self:Create("TextButton", {
        Name = "SettingsBtn",
        Parent = toggleFrame,
        BackgroundTransparency = 1,
        Text = "•••",
        TextColor3 = self.Settings.TextColorDim,
        TextSize = 16,
        FontFace = self.Settings.Font,
        Position = UDim2.new(1, -40, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 30, 0, 24),
        ZIndex = 60,
        AutoButtonColor = false,
    })

    -- Toggle переключатель
    local toggleSwitch = self:Create("Frame", {
        Name = "Switch",
        Parent = toggleFrame,
        BackgroundColor3 = default and self.Settings.ToggleOnColor or self.Settings.ToggleOffColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 36, 0, 18),
        Position = UDim2.new(1, -12, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ZIndex = 60,
    })

    self:CreateCorner(toggleSwitch, UDim.new(0, 9))

    local toggleKnob = self:Create("Frame", {
        Name = "Knob",
        Parent = toggleSwitch,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 14, 0, 14),
        Position = default and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 61,
    })

    self:CreateCorner(toggleKnob, UDim.new(0, 7))

    local isOn = default or false

    local function updateToggle()
        if isOn then
            self:Tween(toggleSwitch, { BackgroundColor3 = self.Settings.ToggleOnColor }, 0.2)
            self:Tween(toggleKnob, { Position = UDim2.new(1, -16, 0.5, 0) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            self:Tween(toggleFrame, { BackgroundColor3 = Color3.fromRGB(30, 30, 55) }, 0.2)
        else
            self:Tween(toggleSwitch, { BackgroundColor3 = self.Settings.ToggleOffColor }, 0.2)
            self:Tween(toggleKnob, { Position = UDim2.new(0, 2, 0.5, 0) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            self:Tween(toggleFrame, { BackgroundColor3 = Color3.fromRGB(25, 25, 45) }, 0.2)
        end
    end

    toggleFrame.MouseButton1Click:Connect(function()
        isOn = not isOn
        updateToggle()
        if callback then callback(isOn) end
    end)

    -- Hover
    toggleFrame.MouseEnter:Connect(function()
        if not isOn then
            self:Tween(toggleFrame, { BackgroundColor3 = Color3.fromRGB(30, 30, 50) }, 0.15)
        end
    end)
    toggleFrame.MouseLeave:Connect(function()
        if not isOn then
            self:Tween(toggleFrame, { BackgroundColor3 = Color3.fromRGB(25, 25, 45) }, 0.15)
        end
    end)

    updateToggle()

    return {
        Frame = toggleFrame,
        IsOn = function() return isOn end,
        Set = function(val)
            isOn = val
            updateToggle()
            if callback then callback(isOn) end
        end,
        SettingsBtn = settingsBtn,
    }
end

-- Slider модуль
function GlassUI:CreateSlider(panelName, text, min, max, default, callback)
    local panelData = CategoryPanels[panelName]
    if not panelData then return end

    local container = panelData.Container
    local layoutOrder = #container:GetChildren() + 1

    local sliderFrame = self:Create("Frame", {
        Name = "Slider",
        Parent = container,
        BackgroundColor3 = Color3.fromRGB(25, 25, 45),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52),
        LayoutOrder = layoutOrder,
        ZIndex = 59,
        ClipsDescendants = true,
    })

    self:CreateCorner(sliderFrame, UDim.new(0, 8))

    -- Текст
    local sliderText = self:Create("TextLabel", {
        Name = "Text",
        Parent = sliderFrame,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Settings.TextColor,
        TextSize = 13,
        FontFace = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(0, 140, 0, 20),
        ZIndex = 60,
    })

    -- Значение
    local valueText = self:Create("TextLabel", {
        Name = "Value",
        Parent = sliderFrame,
        BackgroundTransparency = 1,
        Text = tostring(self:RoundNumber(default, 1)),
        TextColor3 = self.Settings.AccentColor,
        TextSize = 12,
        FontFace = self.Settings.FontBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -12, 0, 6),
        Size = UDim2.new(0, 50, 0, 20),
        ZIndex = 60,
    })

    -- Трек слайдера
    local sliderTrack = self:Create("Frame", {
        Name = "Track",
        Parent = sliderFrame,
        BackgroundColor3 = self.Settings.SliderTrackColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 1, -16),
        ZIndex = 60,
    })

    self:CreateCorner(sliderTrack, UDim.new(0, 3))

    -- Заполнение
    local sliderFill = self:Create("Frame", {
        Name = "Fill",
        Parent = sliderTrack,
        BackgroundColor3 = self.Settings.SliderFillColor,
        BorderSizePixel = 0,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        ZIndex = 61,
    })

    self:CreateCorner(sliderFill, UDim.new(0, 3))

    -- Ползунок
    local sliderKnob = self:Create("Frame", {
        Name = "Knob",
        Parent = sliderTrack,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 62,
    })

    self:CreateCorner(sliderKnob, UDim.new(0, 7))

    local currentValue = default

    local function updateSlider(val)
        val = math.clamp(val, min, max)
        currentValue = val
        local pct = (val - min) / (max - min)
        sliderFill.Size = UDim2.new(pct, 0, 1, 0)
        sliderKnob.Position = UDim2.new(pct, 0, 0.5, 0)
        valueText.Text = tostring(self:RoundNumber(val, 1))
        if callback then callback(val) end
    end

    -- Drag логика
    local dragging = false

    local function handleInput(input)
        local trackAbs = sliderTrack.AbsolutePosition
        local trackSize = sliderTrack.AbsoluteSize
        local mousePos = input.Position.X
        local pct = math.clamp((mousePos - trackAbs.X) / trackSize.X, 0, 1)
        local val = min + pct * (max - min)
        updateSlider(val)
    end

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            handleInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            handleInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Hover
    sliderFrame.MouseEnter:Connect(function()
        self:Tween(sliderFrame, { BackgroundColor3 = Color3.fromRGB(30, 30, 50) }, 0.15)
    end)
    sliderFrame.MouseLeave:Connect(function()
        self:Tween(sliderFrame, { BackgroundColor3 = Color3.fromRGB(25, 25, 45) }, 0.15)
    end)

    return {
        Frame = sliderFrame,
        GetValue = function() return currentValue end,
        SetValue = updateSlider,
    }
end

-- Dropdown модуль
function GlassUI:CreateDropdown(panelName, text, options, default, callback)
    local panelData = CategoryPanels[panelName]
    if not panelData then return end

    local container = panelData.Container
    local layoutOrder = #container:GetChildren() + 1

    local dropdownFrame = self:Create("Frame", {
        Name = "Dropdown",
        Parent = container,
        BackgroundColor3 = Color3.fromRGB(25, 25, 45),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = layoutOrder,
        ZIndex = 59,
        ClipsDescendants = true,
    })

    self:CreateCorner(dropdownFrame, UDim.new(0, 8))

    -- Текст
    local dropdownText = self:Create("TextLabel", {
        Name = "Text",
        Parent = dropdownFrame,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Settings.TextColor,
        TextSize = 13,
        FontFace = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 120, 1, 0),
        ZIndex = 60,
    })

    -- Выбранное значение
    local selectedText = self:Create("TextLabel", {
        Name = "Selected",
        Parent = dropdownFrame,
        BackgroundTransparency = 1,
        Text = default or options[1],
        TextColor3 = self.Settings.AccentColor,
        TextSize = 12,
        FontFace = self.Settings.FontBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -36, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 60, 1, 0),
        ZIndex = 60,
    })

    -- Стрелка
    local arrowText = self:Create("TextLabel", {
        Name = "Arrow",
        Parent = dropdownFrame,
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = self.Settings.TextColorDim,
        TextSize = 10,
        FontFace = self.Settings.Font,
        Position = UDim2.new(1, -14, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 16, 1, 0),
        ZIndex = 60,
    })

    -- Список опций (скрыт по умолчанию)
    local optionsList = self:Create("Frame", {
        Name = "OptionsList",
        Parent = dropdownFrame,
        BackgroundColor3 = Color3.fromRGB(20, 20, 40),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 2),
        Size = UDim2.new(1, 0, 0, 0),
        ZIndex = 65,
        Visible = false,
        ClipsDescendants = true,
    })

    self:CreateCorner(optionsList, UDim.new(0, 8))
    self:CreateStroke(optionsList, self.Settings.BorderColor, 1)

    local optionsLayout = self:Create("UIListLayout", {
        Parent = optionsList,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local optionsPadding = self:Create("UIPadding", {
        Parent = optionsList,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
    })

    local isOpen = false
    local selectedValue = default or options[1]

    -- Создаём опции
    for i, opt in ipairs(options) do
        local optBtn = self:Create("TextButton", {
            Name = "Option",
            Parent = optionsList,
            BackgroundColor3 = opt == selectedValue and self.Settings.AccentColor or Color3.fromRGB(25, 25, 45),
            BackgroundTransparency = opt == selectedValue and 0.3 or 0.6,
            BorderSizePixel = 0,
            Text = opt,
            TextColor3 = self.Settings.TextColor,
            TextSize = 12,
            FontFace = self.Settings.Font,
            Size = UDim2.new(1, -8, 0, 26),
            Position = UDim2.new(0, 4, 0, 0),
            LayoutOrder = i,
            ZIndex = 66,
            AutoButtonColor = false,
        })

        self:CreateCorner(optBtn, UDim.new(0, 6))

        optBtn.MouseButton1Click:Connect(function()
            selectedValue = opt
            selectedText.Text = opt
            isOpen = false
            optionsList.Visible = false
            self:Tween(dropdownFrame, { Size = UDim2.new(1, 0, 0, 32) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            self:Tween(arrowText, { Rotation = 0 }, 0.2)

            -- Обновить цвета
            for _, child in pairs(optionsList:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
                    child.BackgroundTransparency = 0.6
                end
            end
            optBtn.BackgroundColor3 = self.Settings.AccentColor
            optBtn.BackgroundTransparency = 0.3

            if callback then callback(opt) end
        end)

        optBtn.MouseEnter:Connect(function()
            if opt ~= selectedValue then
                self:Tween(optBtn, { BackgroundTransparency = 0.3 }, 0.1)
            end
        end)
        optBtn.MouseLeave:Connect(function()
            if opt ~= selectedValue then
                self:Tween(optBtn, { BackgroundTransparency = 0.6 }, 0.1)
            end
        end)
    end

    dropdownFrame.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            optionsList.Visible = true
            local optHeight = #options * 26 + 8
            self:Tween(dropdownFrame, { Size = UDim2.new(1, 0, 0, 32 + optHeight) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            self:Tween(arrowText, { Rotation = 180 }, 0.2)
        else
            self:Tween(dropdownFrame, { Size = UDim2.new(1, 0, 0, 32) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            self:Tween(arrowText, { Rotation = 0 }, 0.2)
            task.wait(0.2)
            optionsList.Visible = false
        end
    end)

    -- Hover
    dropdownFrame.MouseEnter:Connect(function()
        self:Tween(dropdownFrame, { BackgroundColor3 = Color3.fromRGB(30, 30, 50) }, 0.15)
    end)
    dropdownFrame.MouseLeave:Connect(function()
        self:Tween(dropdownFrame, { BackgroundColor3 = Color3.fromRGB(25, 25, 45) }, 0.15)
    end)

    return {
        Frame = dropdownFrame,
        GetValue = function() return selectedValue end,
        Set = function(val)
            selectedValue = val
            selectedText.Text = val
            if callback then callback(val) end
        end,
    }
end

-- Keybind модуль
function GlassUI:CreateKeybind(panelName, text, defaultKey, callback)
    local panelData = CategoryPanels[panelName]
    if not panelData then return end

    local container = panelData.Container
    local layoutOrder = #container:GetChildren() + 1

    local keybindFrame = self:Create("Frame", {
        Name = "Keybind",
        Parent = container,
        BackgroundColor3 = Color3.fromRGB(25, 25, 45),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = layoutOrder,
        ZIndex = 59,
    })

    self:CreateCorner(keybindFrame, UDim.new(0, 8))

    local keybindText = self:Create("TextLabel", {
        Name = "Text",
        Parent = keybindFrame,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Settings.TextColor,
        TextSize = 13,
        FontFace = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 120, 1, 0),
        ZIndex = 60,
    })

    local keybindBtn = self:Create("TextButton", {
        Name = "KeyBtn",
        Parent = keybindFrame,
        BackgroundColor3 = self.Settings.ToggleOffColor,
        BorderSizePixel = 0,
        Text = defaultKey and defaultKey.Name or "None",
        TextColor3 = self.Settings.TextColor,
        TextSize = 12,
        FontFace = self.Settings.FontBold,
        Size = UDim2.new(0, 60, 0, 22),
        Position = UDim2.new(1, -12, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ZIndex = 60,
        AutoButtonColor = false,
    })

    self:CreateCorner(keybindBtn, UDim.new(0, 6))

    local currentKey = defaultKey
    local waiting = false

    keybindBtn.MouseButton1Click:Connect(function()
        waiting = true
        keybindBtn.Text = "..."
        keybindBtn.BackgroundColor3 = self.Settings.AccentColor
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if waiting and input.UserInputType == Enum.UserInputType.Keyboard then
            currentKey = input.KeyCode
            keybindBtn.Text = input.KeyCode.Name
            keybindBtn.BackgroundColor3 = self.Settings.ToggleOffColor
            waiting = false
            if callback then callback(input.KeyCode) end
        end
    end)

    keybindFrame.MouseEnter:Connect(function()
        self:Tween(keybindFrame, { BackgroundColor3 = Color3.fromRGB(30, 30, 50) }, 0.15)
    end)
    keybindFrame.MouseLeave:Connect(function()
        self:Tween(keybindFrame, { BackgroundColor3 = Color3.fromRGB(25, 25, 45) }, 0.15)
    end)

    return {
        Frame = keybindFrame,
        GetKey = function() return currentKey end,
    }
end

-- Color Picker модуль
function GlassUI:CreateColorPicker(panelName, text, defaultColor, callback)
    local panelData = CategoryPanels[panelName]
    if not panelData then return end

    local container = panelData.Container
    local layoutOrder = #container:GetChildren() + 1

    local cpFrame = self:Create("Frame", {
        Name = "ColorPicker",
        Parent = container,
        BackgroundColor3 = Color3.fromRGB(25, 25, 45),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = layoutOrder,
        ZIndex = 59,
    })

    self:CreateCorner(cpFrame, UDim.new(0, 8))

    local cpText = self:Create("TextLabel", {
        Name = "Text",
        Parent = cpFrame,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Settings.TextColor,
        TextSize = 13,
        FontFace = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 120, 1, 0),
        ZIndex = 60,
    })

    local colorPreview = self:Create("Frame", {
        Name = "Preview",
        Parent = cpFrame,
        BackgroundColor3 = defaultColor or Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -14, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ZIndex = 60,
    })

    self:CreateCorner(colorPreview, UDim.new(0, 6))
    self:CreateStroke(colorPreview, self.Settings.BorderColor, 1)

    local currentColor = defaultColor or Color3.fromRGB(255, 255, 255)

    -- Простой color picker через RGB слайдеры (появляется при клике)
    local pickerPopup = self:Create("Frame", {
        Name = "PickerPopup",
        Parent = cpFrame,
        BackgroundColor3 = Color3.fromRGB(20, 20, 40),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 4),
        Size = UDim2.new(1, 0, 0, 0),
        ZIndex = 70,
        Visible = false,
        ClipsDescendants = true,
    })

    self:CreateCorner(pickerPopup, UDim.new(0, 8))
    self:CreateStroke(pickerPopup, self.Settings.BorderColor, 1)

    local pickerPadding = self:Create("UIPadding", {
        Parent = pickerPopup,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    })

    local pickerLayout = self:Create("UIListLayout", {
        Parent = pickerPopup,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })

    local pickerOpen = false

    -- RGB слайдеры
    local function createRGBSlider(label, color, parent)
        local row = self:Create("Frame", {
            Name = label .. "Row",
            Parent = parent,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            LayoutOrder = #parent:GetChildren(),
            ZIndex = 71,
        })

        local lbl = self:Create("TextLabel", {
            Name = "Label",
            Parent = row,
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = self.Settings.TextColor,
            TextSize = 11,
            FontFace = self.Settings.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0, 20, 1, 0),
            ZIndex = 72,
        })

        local track = self:Create("Frame", {
            Name = "Track",
            Parent = row,
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -28, 0, 8),
            Position = UDim2.new(0, 24, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            ZIndex = 72,
        })
        self:CreateCorner(track, UDim.new(0, 4))

        local knob = self:Create("Frame", {
            Name = "Knob",
            Parent = track,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 73,
        })
        self:CreateCorner(knob, UDim.new(0, 6))

        local val = 0.5

        local dragging = false
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                val = pct
                knob.Position = UDim2.new(pct, 0, 0.5, 0)
                return val
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        return function() return val end
    end

    local rSlider = createRGBSlider("R", Color3.fromRGB(255, 0, 0), pickerPopup)
    local gSlider = createRGBSlider("G", Color3.fromRGB(0, 255, 0), pickerPopup)
    local bSlider = createRGBSlider("B", Color3.fromRGB(0, 0, 255), pickerPopup)

    cpFrame.MouseButton1Click:Connect(function()
        pickerOpen = not pickerOpen
        if pickerOpen then
            pickerPopup.Visible = true
            self:Tween(cpFrame, { Size = UDim2.new(1, 0, 0, 32 + 100) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            self:Tween(cpFrame, { Size = UDim2.new(1, 0, 0, 32) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            task.wait(0.2)
            pickerPopup.Visible = false
        end
    end)

    -- Обновление цвета
    RunService.Heartbeat:Connect(function()
        if pickerOpen then
            local r = rSlider()
            local g = gSlider()
            local b = bSlider()
            local newColor = Color3.fromRGB(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
            if newColor ~= currentColor then
                currentColor = newColor
                colorPreview.BackgroundColor3 = currentColor
                if callback then callback(currentColor) end
            end
        end
    end)

    cpFrame.MouseEnter:Connect(function()
        self:Tween(cpFrame, { BackgroundColor3 = Color3.fromRGB(30, 30, 50) }, 0.15)
    end)
    cpFrame.MouseLeave:Connect(function()
        self:Tween(cpFrame, { BackgroundColor3 = Color3.fromRGB(25, 25, 45) }, 0.15)
    end)

    return {
        Frame = cpFrame,
        GetColor = function() return currentColor end,
    }
end

-- Label (разделитель / заголовок секции)
function GlassUI:CreateLabel(panelName, text)
    local panelData = CategoryPanels[panelName]
    if not panelData then return end

    local container = panelData.Container
    local layoutOrder = #container:GetChildren() + 1

    local labelFrame = self:Create("Frame", {
        Name = "Label",
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        LayoutOrder = layoutOrder,
        ZIndex = 59,
    })

    local labelText = self:Create("TextLabel", {
        Name = "Text",
        Parent = labelFrame,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Settings.TextColorDim,
        TextSize = 11,
        FontFace = self.Settings.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 60,
    })

    return labelFrame
end

-- Separator
function GlassUI:CreateSeparator(panelName)
    local panelData = CategoryPanels[panelName]
    if not panelData then return end

    local container = panelData.Container
    local layoutOrder = #container:GetChildren() + 1

    local sep = self:Create("Frame", {
        Name = "Separator",
        Parent = container,
        BackgroundColor3 = self.Settings.BorderColor,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -16, 0, 1),
        LayoutOrder = layoutOrder,
        ZIndex = 59,
    })

    return sep
end

-- Button
function GlassUI:CreateButton(panelName, text, callback)
    local panelData = CategoryPanels[panelName]
    if not panelData then return end

    local container = panelData.Container
    local layoutOrder = #container:GetChildren() + 1

    local btnFrame = self:Create("Frame", {
        Name = "Button",
        Parent = container,
        BackgroundColor3 = Color3.fromRGB(25, 25, 45),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = layoutOrder,
        ZIndex = 59,
    })

    self:CreateCorner(btnFrame, UDim.new(0, 8))

    local btnText = self:Create("TextLabel", {
        Name = "Text",
        Parent = btnFrame,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Settings.TextColor,
        TextSize = 13,
        FontFace = self.Settings.FontBold,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 60,
    })

    btnFrame.MouseButton1Click:Connect(function()
        -- Анимация нажатия
        self:Tween(btnFrame, { BackgroundColor3 = self.Settings.AccentColor }, 0.1)
        self:Tween(btnText, { TextTransparency = 0.3 }, 0.1)
        task.wait(0.1)
        self:Tween(btnFrame, { BackgroundColor3 = Color3.fromRGB(25, 25, 45) }, 0.2)
        self:Tween(btnText, { TextTransparency = 0 }, 0.2)
        if callback then callback() end
    end)

    btnFrame.MouseEnter:Connect(function()
        self:Tween(btnFrame, { BackgroundColor3 = Color3.fromRGB(35, 35, 60) }, 0.15)
    end)
    btnFrame.MouseLeave:Connect(function()
        self:Tween(btnFrame, { BackgroundColor3 = Color3.fromRGB(25, 25, 45) }, 0.15)
    end)

    return btnFrame
end

-- ============================================================
--  SEARCH BAR (нижний центр)
-- ============================================================

local SearchBar = self:Create("Frame", {
    Name = "SearchBar",
    Parent = MenuContainer,
    BackgroundColor3 = self.Settings.PanelColor,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 0, 1, -50),
    AnchorPoint = Vector2.new(0.5, 1),
    Size = UDim2.new(0, 300, 0, 36),
    ZIndex = 70,
    Visible = false,
})

self:CreateCorner(SearchBar, UDim.new(0, 10))
self:CreateStroke(SearchBar, self.Settings.BorderColor, 1)

local SearchIcon = self:Create("ImageLabel", {
    Name = "Icon",
    Parent = SearchBar,
    BackgroundTransparency = 1,
    Image = "rbxassetid://7072706618", -- лупа
    ImageColor3 = self.Settings.TextColorDim,
    Size = UDim2.new(0, 16, 0, 16),
    Position = UDim2.new(0, 12, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    ZIndex = 71,
})

local SearchInput = self:Create("TextBox", {
    Name = "Input",
    Parent = SearchBar,
    BackgroundTransparency = 1,
    Text = "Поиск...",
    TextColor3 = self.Settings.TextColorDim,
    PlaceholderText = "Поиск модулей...",
    PlaceholderColor3 = self.Settings.TextColorDim,
    TextSize = 13,
    FontFace = self.Settings.Font,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 34, 0, 0),
    Size = UDim2.new(1, -44, 1, 0),
    ZIndex = 71,
    ClearTextOnFocus = false,
})

-- Функция поиска
SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    local query = SearchInput.Text:lower()
    for _, panelData in pairs(CategoryPanels) do
        for _, module in pairs(panelData.Container:GetChildren()) do
            if module:IsA("Frame") then
                local textLabel = module:FindFirstChild("Text")
                if textLabel then
                    if query == "" or query == "поиск..." or query == "поиск модулей..." then
                        module.Visible = true
                    else
                        module.Visible = textLabel.Text:lower():find(query) ~= nil
                    end
                end
            end
        end
    end
end)

SearchInput.Focused:Connect(function()
    if SearchInput.Text == "Поиск..." then
        SearchInput.Text = ""
    end
    self:Tween(SearchBar, { BackgroundColor3 = Color3.fromRGB(30, 30, 55) }, 0.15)
end)

SearchInput.FocusLost:Connect(function()
    if SearchInput.Text == "" then
        SearchInput.Text = "Поиск..."
    end
    self:Tween(SearchBar, { BackgroundColor3 = self.Settings.PanelColor }, 0.15)
end)

-- ============================================================
--  CONFIG MANAGER (правый нижний угол)
-- ============================================================

local ConfigManager = self:Create("Frame", {
    Name = "ConfigManager",
    Parent = MenuContainer,
    BackgroundColor3 = self.Settings.PanelColor,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -16, 1, -50),
    AnchorPoint = Vector2.new(1, 1),
    Size = UDim2.new(0, 220, 0, 180),
    ZIndex = 70,
    Visible = false,
    ClipsDescendants = true,
})

self:CreateCorner(ConfigManager, UDim.new(0, 12))
self:CreateStroke(ConfigManager, self.Settings.BorderColor, 1.5)

-- Заголовок Config Manager
local ConfigHeader = self:Create("Frame", {
    Name = "Header",
    Parent = ConfigManager,
    BackgroundColor3 = self.Settings.AccentColor,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 32),
    ZIndex = 71,
})

self:CreateCorner(ConfigHeader, UDim.new(0, 12))

local ConfigTitle = self:Create("TextLabel", {
    Name = "Title",
    Parent = ConfigHeader,
    BackgroundTransparency = 1,
    Text = "Config Manager",
    TextColor3 = self.Settings.TextColor,
    TextSize = 13,
    FontFace = self.Settings.FontBold,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 72,
})

-- Поле ввода названия конфига
local ConfigNameFrame = self:Create("Frame", {
    Name = "NameFrame",
    Parent = ConfigManager,
    BackgroundColor3 = Color3.fromRGB(25, 25, 45),
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 42),
    ZIndex = 71,
})

self:CreateCorner(ConfigNameFrame, UDim.new(0, 8))

local ConfigNameLabel = self:Create("TextLabel", {
    Name = "Label",
    Parent = ConfigNameFrame,
    BackgroundTransparency = 1,
    Text = "Название",
    TextColor3 = self.Settings.TextColorDim,
    TextSize = 11,
    FontFace = self.Settings.Font,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 10, 0, 0),
    Size = UDim2.new(0, 60, 1, 0),
    ZIndex = 72,
})

local ConfigNameInput = self:Create("TextBox", {
    Name = "Input",
    Parent = ConfigNameFrame,
    BackgroundTransparency = 1,
    Text = "",
    PlaceholderText = "my_config",
    PlaceholderColor3 = Color3.fromRGB(80, 80, 100),
    TextColor3 = self.Settings.TextColor,
    TextSize = 12,
    FontFace = self.Settings.Font,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 74, 0, 0),
    Size = UDim2.new(1, -84, 1, 0),
    ZIndex = 72,
    ClearTextOnFocus = false,
})

-- Кнопки действий Config Manager
local ConfigButtonsFrame = self:Create("Frame", {
    Name = "Buttons",
    Parent = ConfigManager,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 0),
    Position = UDim2.new(0, 10, 0, 80),
    ZIndex = 71,
})

local ConfigButtonsLayout = self:Create("UIListLayout", {
    Parent = ConfigButtonsFrame,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
})

-- Функция создания кнопки конфига
local function CreateConfigButton(text, color, layoutOrder, callback)
    local btn = GlassUI:Create("TextButton", {
        Name = text,
        Parent = ConfigButtonsFrame,
        BackgroundColor3 = color or Color3.fromRGB(30, 30, 55),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = GlassUI.Settings.TextColor,
        TextSize = 12,
        FontFace = GlassUI.Settings.FontBold,
        Size = UDim2.new(1, 0, 0, 26),
        LayoutOrder = layoutOrder,
        ZIndex = 72,
        AutoButtonColor = false,
    })

    GlassUI:CreateCorner(btn, UDim.new(0, 6))

    btn.MouseEnter:Connect(function()
        GlassUI:Tween(btn, { BackgroundTransparency = 0.1 }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        GlassUI:Tween(btn, { BackgroundTransparency = 0.3 }, 0.15)
    end)

    btn.MouseButton1Click:Connect(function()
        -- Анимация клика
        GlassUI:Tween(btn, { BackgroundColor3 = GlassUI.Settings.AccentColor }, 0.1)
        task.wait(0.15)
        GlassUI:Tween(btn, { BackgroundColor3 = color or Color3.fromRGB(30, 30, 55) }, 0.2)
        if callback then callback() end
    end)

    return btn
end

CreateConfigButton("Создать", GlassUI.Settings.SuccessColor, 1, function()
    local name = ConfigNameInput.Text
    if name ~= "" then
        print("[GlassUI] Config created: " .. name)
    end
end)

CreateConfigButton("Сохранить", GlassUI.Settings.AccentColor, 2, function()
    print("[GlassUI] Config saved")
end)

CreateConfigButton("Загрузить", Color3.fromRGB(50, 50, 80), 3, function()
    print("[GlassUI] Config loaded")
end)

CreateConfigButton("Удалить", GlassUI.Settings.DangerColor, 4, function()
    print("[GlassUI] Config deleted")
end)

-- Обновить размер ConfigButtonsFrame
task.defer(function()
    ConfigButtonsFrame.Size = UDim2.new(1, -20, 0, ConfigButtonsLayout.AbsoluteContentSize.Y)
end)

-- ============================================================
--  ACTIVE MODULES LIST (левый нижний угол - Arraylist)
-- ============================================================

local ArraylistFrame = self:Create("Frame", {
    Name = "Arraylist",
    Parent = MainFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 1, -16),
    AnchorPoint = Vector2.new(0, 1),
    Size = UDim2.new(0, 200, 0, 300),
    ZIndex = 100,
    Visible = true,
})

local ArraylistLayout = self:Create("UIListLayout", {
    Parent = ArraylistFrame,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
})

local ActiveModules = {}

function GlassUI:AddToArraylist(moduleName)
    if ActiveModules[moduleName] then return end

    local entry = self:Create("Frame", {
        Name = moduleName,
        Parent = ArraylistFrame,
        BackgroundColor3 = self.Settings.PanelColor,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 22),
        ZIndex = 101,
        ClipsDescendants = true,
    })

    self:CreateCorner(entry, UDim.new(0, 6))

    -- Акцентная полоска слева
    local accentBar = self:Create("Frame", {
        Name = "AccentBar",
        Parent = entry,
        BackgroundColor3 = self.Settings.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        ZIndex = 102,
    })

    self:CreateCorner(accentBar, UDim.new(0, 2))

    local nameLabel = self:Create("TextLabel", {
        Name = "Name",
        Parent = entry,
        BackgroundTransparency = 1,
        Text = moduleName,
        TextColor3 = self.Settings.TextColor,
        TextSize = 12,
        FontFace = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, -16, 1, 0),
        ZIndex = 102,
    })

    -- Анимация появления
    self:Tween(entry, {
        Size = UDim2.new(1, 0, 0, 22),
    }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    ActiveModules[moduleName] = entry
end

function GlassUI:RemoveFromArraylist(moduleName)
    local entry = ActiveModules[moduleName]
    if not entry then return end

    self:Tween(entry, {
        Size = UDim2.new(0, 0, 0, 22),
    }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    task.wait(0.2)
    entry:Destroy()
    ActiveModules[moduleName] = nil
end

-- ============================================================
--  NOTIFICATION SYSTEM
-- ============================================================

local NotificationContainer = self:Create("Frame", {
    Name = "NotificationContainer",
    Parent = MainFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -16, 0.5, 0),
    AnchorPoint = Vector2.new(1, 0.5),
    Size = UDim2.new(0, 280, 0, 400),
    ZIndex = 200,
})

local NotificationLayout = self:Create("UIListLayout", {
    Parent = NotificationContainer,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
})

function GlassUI:Notify(title, message, duration, notifType)
    duration = duration or 3
    notifType = notifType or "info"

    local accentColor = self.Settings.AccentColor
    if notifType == "success" then
        accentColor = self.Settings.SuccessColor
    elseif notifType == "error" then
        accentColor = self.Settings.DangerColor
    elseif notifType == "warning" then
        accentColor = self.Settings.WarningColor
    end

    local notifFrame = self:Create("Frame", {
        Name = "Notification",
        Parent = NotificationContainer,
        BackgroundColor3 = self.Settings.PanelColor,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        ZIndex = 201,
        ClipsDescendants = true,
    })

    self:CreateCorner(notifFrame, UDim.new(0, 10))
    self:CreateStroke(notifFrame, self.Settings.BorderColor, 1)

    -- Акцентная линия сверху
    local topAccent = self:Create("Frame", {
        Name = "TopAccent",
        Parent = notifFrame,
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 3),
        ZIndex = 202,
    })

    self:CreateCorner(topAccent, UDim.new(0, 2))

    -- Заголовок
    local notifTitle = self:Create("TextLabel", {
        Name = "Title",
        Parent = notifFrame,
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = accentColor,
        TextSize = 13,
        FontFace = self.Settings.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 12, 0, 10),
        Size = UDim2.new(1, -24, 0, 18),
        ZIndex = 202,
    })

    -- Сообщение
    local notifMessage = self:Create("TextLabel", {
        Name = "Message",
        Parent = notifFrame,
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = self.Settings.TextColorDim,
        TextSize = 12,
        FontFace = self.Settings.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Position = UDim2.new(0, 12, 0, 30),
        Size = UDim2.new(1, -24, 0, 24),
        ZIndex = 202,
    })

    -- Прогресс бар
    local progressBar = self:Create("Frame", {
        Name = "Progress",
        Parent = notifFrame,
        BackgroundColor3 = accentColor,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        ZIndex = 202,
    })

    -- Анимация появления
    self:Tween(notifFrame, {
        Size = UDim2.new(1, 0, 0, 64),
    }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Прогресс
    task.delay(0.3, function()
        self:Tween(progressBar, {
            Size = UDim2.new(0, 0, 0, 2),
        }, duration, Enum.EasingStyle.Linear)
    end)

    -- Убрать через duration
    task.delay(duration + 0.3, function()
        self:Tween(notifFrame, {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.wait(0.35)
        notifFrame:Destroy()
    end)
end

-- ============================================================
--  FPS / PING COUNTER (у ватермарки)
-- ============================================================

local FPSCounter = self:Create("Frame", {
    Name = "FPSCounter",
    Parent = MainFrame,
    BackgroundColor3 = self.Settings.PanelColor,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 16, 0, 72),
    Size = UDim2.new(0, 100, 0, 22),
    ZIndex = 100,
    ClipsDescendants = true,
    Visible = false,
})

self:CreateCorner(FPSCounter, UDim.new(0, 6))
self:CreateStroke(FPSCounter, self.Settings.BorderColor, 1)

local FPSLabel = self:Create("TextLabel", {
    Name = "FPS",
    Parent = FPSCounter,
    BackgroundTransparency = 1,
    Text = "FPS: 60 | MS: 0",
    TextColor3 = self.Settings.TextColorDim,
    TextSize = 11,
    FontFace = self.Settings.Font,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 101,
})

-- Обновление FPS
local frameCount = 0
local lastFPSUpdate = tick()

RunService.Heartbeat:Connect(function()
    frameCount = frameCount + 1
    if tick() - lastFPSUpdate >= 1 then
        local fps = math.floor(frameCount / (tick() - lastFPSUpdate))
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        FPSLabel.Text = "FPS: " .. fps .. " | MS: " .. ping
        frameCount = 0
        lastFPSUpdate = tick()
    end
end)

-- ============================================================
--  MENU TOGGLE SYSTEM (Right Shift)
-- ============================================================

local menuVisible = false
local menuAnimating = false

local function ShowMenu()
    if menuAnimating then return end
    menuAnimating = true
    menuVisible = true

    -- Показать все элементы
    MenuContainer.Visible = true
    BackgroundDim.Visible = true
    TabBar.Visible = true
    PanelsContainer.Visible = true
    SearchBar.Visible = true
    ConfigManager.Visible = true
    FPSCounter.Visible = true

    -- Анимация затемнения фона
    BackgroundDim.BackgroundTransparency = 1
    GlassUI:Tween(BackgroundDim, { BackgroundTransparency = 0.5 }, 0.4)

    -- Анимация ватермарки
    AnimateWatermarkIn()

    -- Анимация TabBar
    TabBar.Position = UDim2.new(0.5, 0, 0, -50)
    TabBar.Size = UDim2.new(0, 0, 0, 44)
    GlassUI:Tween(TabBar, {
        Position = UDim2.new(0.5, 0, 0, 60),
        Size = UDim2.new(0, 700, 0, 44),
    }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Анимация панелей
    PanelsContainer.Position = UDim2.new(0.5, 0, 0, 114)
    PanelsContainer.Size = UDim2.new(0, 0, 0, 400)
    GlassUI:Tween(PanelsContainer, {
        Size = UDim2.new(0, 700, 0, 400),
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Анимация SearchBar
    SearchBar.Position = UDim2.new(0.5, 0, 1, 50)
    GlassUI:Tween(SearchBar, {
        Position = UDim2.new(0.5, 0, 1, -50),
    }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Анимация Config Manager
    ConfigManager.Position = UDim2.new(1, 50, 1, -50)
    GlassUI:Tween(ConfigManager, {
        Position = UDim2.new(1, -16, 1, -50),
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Анимация FPS Counter
    FPSCounter.Size = UDim2.new(0, 0, 0, 22)
    GlassUI:Tween(FPSCounter, {
        Size = UDim2.new(0, 100, 0, 22),
    }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Показать список игроков
    GlassUI:UpdatePlayerList()

    -- Переключить первую категорию если нет активной
    if not ActiveCategory then
        GlassUI:SwitchCategory("Combat")
    else
        -- Перезапустить анимацию текущей панели
        local curr = CategoryPanels[ActiveCategory]
        if curr then
            curr.Panel.Visible = true
            curr.Panel.Size = UDim2.new(0, 0, 1, 0)
            GlassUI:Tween(curr.Panel, { Size = UDim2.new(1, 0, 1, 0) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    end

    -- Уведомление
    task.delay(0.5, function()
        GlassUI:Notify("Alpha", "Меню открыто", 2, "info")
    end)

    task.wait(0.45)
    menuAnimating = false
end

local function HideMenu()
    if menuAnimating then return end
    menuAnimating = true
    menuVisible = false

    -- Анимация скрытия
    GlassUI:Tween(BackgroundDim, { BackgroundTransparency = 1 }, 0.3)

    GlassUI:Tween(TabBar, {
        Position = UDim2.new(0.5, 0, 0, -50),
        Size = UDim2.new(0, 0, 0, 44),
    }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    GlassUI:Tween(PanelsContainer, {
        Size = UDim2.new(0, 0, 0, 400),
    }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    GlassUI:Tween(SearchBar, {
        Position = UDim2.new(0.5, 0, 1, 50),
    }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    GlassUI:Tween(ConfigManager, {
        Position = UDim2.new(1, 50, 1, -50),
    }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    AnimateWatermarkOut()

    GlassUI:Tween(FPSCounter, {
        Size = UDim2.new(0, 0, 0, 22),
    }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    GlassUI:Tween(PlayerListFrame, {
        Size = UDim2.new(0, 180, 0, 0),
    }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    -- Скрыть текущую панель
    if ActiveCategory and CategoryPanels[ActiveCategory] then
        local curr = CategoryPanels[ActiveCategory]
        GlassUI:Tween(curr.Panel, { Size = UDim2.new(0, 0, 1, 0) }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    end

    task.wait(0.35)

    BackgroundDim.Visible = false
    TabBar.Visible = false
    PanelsContainer.Visible = false
    SearchBar.Visible = false
    ConfigManager.Visible = false
    FPSCounter.Visible = false
    MenuContainer.Visible = false

    menuAnimating = false
end

-- Обработка нажатия RShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == GlassUI.Settings.ToggleKey then
        if menuVisible then
            HideMenu()
        else
            ShowMenu()
        end
    end
end)

-- ============================================================
--  CURSOR EFFECTS (кастомный курсор при открытом меню)
-- ============================================================

local CursorDot = self:Create("Frame", {
    Name = "CursorDot",
    Parent = MainFrame,
    BackgroundColor3 = self.Settings.AccentColor,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 8, 0, 8),
    ZIndex = 999,
    Visible = false,
})

self:CreateCorner(CursorDot, UDim.new(0, 4))

local CursorRing = self:Create("Frame", {
    Name = "CursorRing",
    Parent = MainFrame,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 24, 0, 24),
    ZIndex = 998,
    Visible = false,
})

self:CreateCorner(CursorRing, UDim.new(0, 12))
self:CreateStroke(CursorRing, self.Settings.AccentColor, 1.5)

RunService.RenderStepped:Connect(function()
    if menuVisible then
        local mousePos = UserInputService:GetMouseLocation()
        CursorDot.Visible = true
        CursorRing.Visible = true
        CursorDot.Position = UDim2.new(0, mousePos.X - 4, 0, mousePos.Y - 4)
        -- Плавное следование кольца
        local ringPos = CursorRing.Position
        local targetX = mousePos.X - 12
        local targetY = mousePos.Y - 12
        local lerpedX = GlassUI:Lerp(ringPos.X.Offset, targetX, 0.15)
        local lerpedY = GlassUI:Lerp(ringPos.Y.Offset, targetY, 0.15)
        CursorRing.Position = UDim2.new(0, lerpedX, 0, lerpedY)
    else
        CursorDot.Visible = false
        CursorRing.Visible = false
    end
end)

-- ============================================================
--  TOOLTIP SYSTEM
-- ============================================================

local Tooltip = self:Create("Frame", {
    Name = "Tooltip",
    Parent = MainFrame,
    BackgroundColor3 = Color3.fromRGB(10, 10, 20),
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 0, 0, 0),
    ZIndex = 500,
    Visible = false,
    ClipsDescendants = true,
})

self:CreateCorner(Tooltip, UDim.new(0, 6))
self:CreateStroke(Tooltip, self.Settings.AccentColor, 1)

local TooltipText = self:Create("TextLabel", {
    Name = "Text",
    Parent = Tooltip,
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = self.Settings.TextColor,
    TextSize = 11,
    FontFace = self.Settings.Font,
    Size = UDim2.new(1, -12, 1, 0),
    Position = UDim2.new(0, 6, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 501,
})

function GlassUI:ShowTooltip(text, position)
    TooltipText.Text = text
    local textWidth = #text * 6 + 20
    Tooltip.Position = UDim2.new(0, position.X + 16, 0, position.Y - 10)
    Tooltip.Visible = true
    self:Tween(Tooltip, {
        Size = UDim2.new(0, textWidth, 0, 24),
    }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function GlassUI:HideTooltip()
    self:Tween(Tooltip, {
        Size = UDim2.new(0, 0, 0, 0),
    }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.wait(0.1)
    Tooltip.Visible = false
end

-- ============================================================
--  AUTO-UPDATE TAB SIZES
-- ============================================================

task.defer(function()
    -- Автоматически задаём ширину вкладок
    local tabCount = #Categories
    for name, tab in pairs(Tabs) do
        local textWidth = #name * 8 + 48
        tab.Size = UDim2.new(0, textWidth, 1, -12)
    end

    -- Обновить CanvasSize для всех панелей
    for _, panelData in pairs(CategoryPanels) do
        panelData.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            panelData.Container.CanvasSize = UDim2.new(0, 0, 0, panelData.Layout.AbsoluteContentSize.Y + 8)
        end)
    end
end)


return GlassUI
