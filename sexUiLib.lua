-- ============================================================
--  DARK GLASSMORPHISM UI LIBRARY v2.0
--  Стиль: Minecraft-like ClickGUI с 5 колонками
--  Toggle: Right Shift
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  LIBRARY
-- ============================================================

local GlassUI = {}
GlassUI.__index = GlassUI

GlassUI.Settings = {
    ToggleKey        = Enum.KeyCode.RightShift,
    AccentColor      = Color3.fromRGB(59, 130, 246),
    PanelBg          = Color3.fromRGB(12, 10, 18),
    ModuleBg         = Color3.fromRGB(22, 17, 28),
    ModuleToggled    = Color3.fromRGB(45, 28, 55),
    TextColor        = Color3.fromRGB(220, 220, 220),
    TextColorDim     = Color3.fromRGB(140, 140, 160),
    BorderColor      = Color3.fromRGB(60, 60, 80),
    SliderFill       = Color3.fromRGB(59, 130, 246),
    SliderTrack      = Color3.fromRGB(35, 35, 55),
    SuccessColor     = Color3.fromRGB(34, 197, 94),
    DangerColor      = Color3.fromRGB(239, 68, 68),
    WarningColor     = Color3.fromRGB(234, 179, 8),
    Font             = Font.new("rbxasset://fonts/families/GothamSSm.json"),
    FontBold         = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
    CornerRadius     = UDim.new(0, 10),
    ModuleCorner     = UDim.new(0, 6),
    AnimSpeed        = 0.2,
    ColWidth         = 148,
    ColGap           = 5,
    PanelHeight      = 320,
    ModuleHeight     = 26,
}

-- ============================================================
--  UTILS
-- ============================================================

function GlassUI:Create(t, props)
    local obj = Instance.new(t)
    for k, v in pairs(props) do
        if k ~= "Parent" then obj[k] = v end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

function GlassUI:Corner(parent, r)
    return self:Create("UICorner", { CornerRadius = r or self.Settings.CornerRadius, Parent = parent })
end

function GlassUI:Stroke(parent, color, thick, trans)
    return self:Create("UIStroke", {
        Color = color or self.Settings.BorderColor,
        Thickness = thick or 1,
        Transparency = trans or 0.6,
        Parent = parent,
    })
end

function GlassUI:Tween(obj, props, dur, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(dur or self.Settings.AnimSpeed, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

function GlassUI:Round(n, d)
    local m = 10^(d or 1)
    return math.floor(n * m + 0.5) / m
end

-- ============================================================
--  STATE
-- ============================================================

GlassUI.Visible       = false
GlassUI.Animating     = false
GlassUI.CategoryData  = {}
GlassUI.ActiveModules = {}
GlassUI.Modules       = {}   -- { [name] = moduleData }

local Categories = {
    { Name = "Combat",        Icon = "⚔" },
    { Name = "Movement",      Icon = "🏃" },
    { Name = "Visuals",       Icon = "👁" },
    { Name = "Player",        Icon = "👤" },
    { Name = "Miscellaneous", Icon = "⚙" },
}

-- ============================================================
--  INIT
-- ============================================================

function GlassUI:Init()
    -- ScreenGui
    self.Gui = self:Create("ScreenGui", {
        Name            = "GlassUI_v2",
        Parent          = LocalPlayer:WaitForChild("PlayerGui"),
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn    = false,
        IgnoreGuiInset  = true,
    })

    -- Корневой фрейм
    self.Root = self:Create("Frame", {
        Name                = "Root",
        Parent              = self.Gui,
        BackgroundColor3    = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 1,
        Size                = UDim2.new(1,0,1,0),
        ZIndex              = 1,
    })

    -- Затемнение фона
    self.Dim = self:Create("Frame", {
        Name                = "Dim",
        Parent              = self.Root,
        BackgroundColor3    = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 1,
        Size                = UDim2.new(1,0,1,0),
        ZIndex              = 2,
        Visible             = false,
    })

    -- Главный контейнер меню
    self.MenuHolder = self:Create("Frame", {
        Name                = "MenuHolder",
        Parent              = self.Root,
        BackgroundTransparency = 1,
        AnchorPoint         = Vector2.new(0.5, 0.5),
        Position            = UDim2.new(0.5, 0, 0.5, 0),
        Size                = UDim2.new(0, 0, 0, 0),
        ZIndex              = 3,
        Visible             = false,
        ClipsDescendants    = false,
    })

    -- Инициализация подсистем
    self:_BuildColumns()
    self:_BuildWatermark()
    self:_BuildPlayerList()
    self:_BuildSearchBar()
    self:_BuildConfigManager()
    self:_BuildArraylist()
    self:_BuildNotifications()
    self:_SetupInput()

    task.delay(0.5, function()
        self:Notify("Alpha Client", "RShift — открыть меню", 4, "info")
    end)

    return self
end

-- ============================================================
--  КОЛОНКИ (5 штук, зафиксированы и развёрнуты)
-- ============================================================

function GlassUI:_BuildColumns()
    local S = self.Settings
    local colW   = S.ColWidth
    local colGap = S.ColGap
    local panH   = S.PanelHeight
    local totalW = (#Categories * colW) + ((#Categories - 1) * colGap)

    -- Внешний фрейм колонок
    self.ColumnsFrame = self:Create("Frame", {
        Name                = "Columns",
        Parent              = self.MenuHolder,
        BackgroundTransparency = 1,
        Size                = UDim2.new(0, totalW, 0, panH),
        Position            = UDim2.new(0, 0, 0, 0),
        ZIndex              = 4,
    })

    self.CategoryData = {}

    for i, cat in ipairs(Categories) do
        local colX = (i-1) * (colW + colGap)

        -- Панель колонки
        local panel = self:Create("Frame", {
            Name                = cat.Name .. "Panel",
            Parent              = self.ColumnsFrame,
            BackgroundColor3    = S.PanelBg,
            BackgroundTransparency = 0.15,
            BorderSizePixel     = 0,
            Position            = UDim2.new(0, colX, 0, 0),
            Size                = UDim2.new(0, colW, 0, panH),
            ZIndex              = 5,
            ClipsDescendants    = true,
        })
        self:Corner(panel, UDim.new(0, 10))
        self:Stroke(panel, S.BorderColor, 1, 0.7)

        -- Заголовок категории
        local header = self:Create("Frame", {
            Name                = "Header",
            Parent              = panel,
            BackgroundColor3    = S.AccentColor,
            BackgroundTransparency = 0.88,
            BorderSizePixel     = 0,
            Size                = UDim2.new(1, 0, 0, 30),
            ZIndex              = 6,
        })
        self:Corner(header, UDim.new(0, 10))

        -- Линия-разделитель под заголовком
        self:Create("Frame", {
            Name                = "Divider",
            Parent              = panel,
            BackgroundColor3    = S.BorderColor,
            BackgroundTransparency = 0.6,
            BorderSizePixel     = 0,
            Position            = UDim2.new(0, 0, 0, 30),
            Size                = UDim2.new(1, 0, 0, 1),
            ZIndex              = 6,
        })

        -- Название категории
        self:Create("TextLabel", {
            Name                = "Title",
            Parent              = header,
            BackgroundTransparency = 1,
            Text                = cat.Name,
            TextColor3          = S.TextColor,
            TextSize            = 12,
            FontFace            = S.FontBold,
            Size                = UDim2.new(1, 0, 1, 0),
            ZIndex              = 7,
        })

        -- ScrollingFrame для модулей
        local scrollFrame = self:Create("ScrollingFrame", {
            Name                    = "ModuleScroll",
            Parent                  = panel,
            BackgroundTransparency  = 1,
            BorderSizePixel         = 0,
            Position                = UDim2.new(0, 0, 0, 31),
            Size                    = UDim2.new(1, 0, 1, -31),
            ZIndex                  = 6,
            ScrollBarThickness      = 2,
            ScrollBarImageColor3    = Color3.fromRGB(255,255,255),
            ScrollBarImageTransparency = 0.7,
            CanvasSize              = UDim2.new(0,0,0,0),
            TopImage                = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage             = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            ScrollingDirection      = Enum.ScrollingDirection.Y,
            ElasticBehavior         = Enum.ElasticBehavior.Never,
        })

        local layout = self:Create("UIListLayout", {
            Parent          = scrollFrame,
            SortOrder       = Enum.SortOrder.LayoutOrder,
            Padding         = UDim.new(0, 2),
        })

        local padding = self:Create("UIPadding", {
            Parent          = scrollFrame,
            PaddingTop      = UDim.new(0, 4),
            PaddingBottom   = UDim.new(0, 4),
            PaddingLeft     = UDim.new(0, 5),
            PaddingRight    = UDim.new(0, 5),
        })

        -- Авто-обновление CanvasSize
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)

        self.CategoryData[cat.Name] = {
            Panel   = panel,
            Scroll  = scrollFrame,
            Layout  = layout,
            Modules = {},
        }
    end

    -- Обновляем размер MenuHolder
    local totalW2 = (#Categories * colW) + ((#Categories - 1) * colGap)
    self.MenuHolder.Size = UDim2.new(0, totalW2, 0, panH)
    self.MenuHolder.Position = UDim2.new(0.5, -totalW2/2, 0.5, -panH/2)
end

-- ============================================================
--  ДОБАВЛЕНИЕ МОДУЛЯ В КОЛОНКУ
-- ============================================================

--[[
    Каждый модуль — строка в колонке.
    Левая кнопка мыши  = toggle (вкл/выкл)
    Правая кнопка мыши = раскрыть настройки (анимированный dropdown снизу)
    Средняя            = биндинг клавиши
]]

function GlassUI:AddModule(categoryName, moduleName, options)
    options = options or {}
    local catData = self.CategoryData[categoryName]
    if not catData then
        warn("[GlassUI] Категория не найдена: " .. categoryName)
        return
    end

    local S = self.Settings
    local order = #catData.Modules + 1
    local isToggled  = options.default or false
    local moduleSettings = options.settings or {}   -- массив настроек
    local onToggle   = options.onToggle
    local bindKey    = options.bind or nil

    -- ---- КОНТЕЙНЕР МОДУЛЯ ----
    local moduleContainer = self:Create("Frame", {
        Name                = "Module_" .. moduleName,
        Parent              = catData.Scroll,
        BackgroundTransparency = 1,
        BorderSizePixel     = 0,
        Size                = UDim2.new(1, 0, 0, S.ModuleHeight),
        LayoutOrder         = order,
        ZIndex              = 7,
        ClipsDescendants    = false,
    })

    -- ---- СТРОКА МОДУЛЯ ----
    local moduleRow = self:Create("Frame", {
        Name                = "Row",
        Parent              = moduleContainer,
        BackgroundColor3    = isToggled and S.ModuleToggled or S.ModuleBg,
        BackgroundTransparency = 0.25,
        BorderSizePixel     = 0,
        Size                = UDim2.new(1, 0, 0, S.ModuleHeight),
        ZIndex              = 8,
    })
    self:Corner(moduleRow, UDim.new(0, 6))
    self:Stroke(moduleRow, S.BorderColor, 1, 0.75)

    -- Акцентная полоса слева (видна когда включён)
    local accentBar = self:Create("Frame", {
        Name                = "Accent",
        Parent              = moduleRow,
        BackgroundColor3    = S.AccentColor,
        BorderSizePixel     = 0,
        Size                = UDim2.new(0, 3, 1, -6),
        Position            = UDim2.new(0, 0, 0, 3),
        ZIndex              = 9,
        Visible             = isToggled,
    })
    self:Corner(accentBar, UDim.new(0, 2))

    -- Название модуля
    local nameLabel = self:Create("TextLabel", {
        Name                = "Name",
        Parent              = moduleRow,
        BackgroundTransparency = 1,
        Text                = moduleName,
        TextColor3          = isToggled and S.TextColor or S.TextColorDim,
        TextSize            = 12,
        FontFace            = isToggled and S.FontBold or S.Font,
        TextXAlignment      = Enum.TextXAlignment.Left,
        Position            = UDim2.new(0, 8, 0, 0),
        Size                = UDim2.new(1, -30, 1, 0),
        ZIndex              = 9,
    })

    -- Три точки (если есть настройки)
    local dotsBtn = nil
    if #moduleSettings > 0 then
        dotsBtn = self:Create("TextButton", {
            Name                = "Dots",
            Parent              = moduleRow,
            BackgroundTransparency = 1,
            Text                = "···",
            TextColor3          = S.TextColorDim,
            TextSize            = 14,
            FontFace            = S.Font,
            Position            = UDim2.new(1, -22, 0.5, 0),
            AnchorPoint         = Vector2.new(0, 0.5),
            Size                = UDim2.new(0, 20, 0, 20),
            ZIndex              = 10,
            AutoButtonColor     = false,
        })
    end

    -- ---- ПАНЕЛЬ НАСТРОЕК (раскрывается снизу) ----
    local settingsPanel = nil
    local settingsHeight = 0
    local expanded = false
    local settingsComponents = {}

    if #moduleSettings > 0 then
        -- Считаем высоту всех настроек
        local function calcSettingsHeight()
            local h = 6  -- padding
            for _, s in ipairs(settingsComponents) do
                h = h + (s.Height or 28) + 2
            end
            h = h + 4
            return h
        end

        settingsPanel = self:Create("Frame", {
            Name                = "Settings",
            Parent              = moduleContainer,
            BackgroundColor3    = Color3.fromRGB(16, 12, 22),
            BackgroundTransparency = 0.2,
            BorderSizePixel     = 0,
            Position            = UDim2.new(0, 3, 0, S.ModuleHeight + 1),
            Size                = UDim2.new(1, -6, 0, 0),
            ZIndex              = 7,
            ClipsDescendants    = true,
        })
        self:Corner(settingsPanel, UDim.new(0, 6))
        self:Stroke(settingsPanel, S.BorderColor, 1, 0.8)

        local settingsLayout = self:Create("UIListLayout", {
            Parent          = settingsPanel,
            SortOrder       = Enum.SortOrder.LayoutOrder,
            Padding         = UDim.new(0, 2),
        })

        self:Create("UIPadding", {
            Parent          = settingsPanel,
            PaddingTop      = UDim.new(0, 5),
            PaddingBottom   = UDim.new(0, 5),
            PaddingLeft     = UDim.new(0, 5),
            PaddingRight    = UDim.new(0, 5),
        })

        -- Строим настройки
        for si, setting in ipairs(moduleSettings) do
            local comp = self:_BuildSettingComponent(settingsPanel, setting, si)
            table.insert(settingsComponents, comp)
        end

        settingsHeight = calcSettingsHeight()
    end

    -- ---- ФУНКЦИЯ TOGGLE ----
    local function setToggled(val, silent)
        isToggled = val
        -- Цвет строки
        self:Tween(moduleRow, {
            BackgroundColor3 = isToggled and S.ModuleToggled or S.ModuleBg,
        }, 0.15)
        -- Текст
        nameLabel.TextColor3 = isToggled and S.TextColor or S.TextColorDim
        nameLabel.FontFace   = isToggled and S.FontBold or S.Font
        -- Акцент-полоса
        accentBar.Visible = isToggled
        -- Arraylist
        if isToggled then
            self:AddToArraylist(moduleName)
        else
            self:RemoveFromArraylist(moduleName)
        end
        if not silent and onToggle then onToggle(isToggled) end
    end

    -- ---- ФУНКЦИЯ EXPAND ----
    local function setExpanded(val)
        if not settingsPanel then return end
        expanded = val

        if expanded then
            -- Открываем: увеличиваем контейнер
            self:Tween(settingsPanel, {
                Size = UDim2.new(1, -6, 0, settingsHeight),
            }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            self:Tween(moduleContainer, {
                Size = UDim2.new(1, 0, 0, S.ModuleHeight + 1 + settingsHeight),
            }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            if dotsBtn then
                self:Tween(dotsBtn, { TextColor3 = S.AccentColor }, 0.15)
            end
        else
            -- Закрываем
            self:Tween(settingsPanel, {
                Size = UDim2.new(1, -6, 0, 0),
            }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            self:Tween(moduleContainer, {
                Size = UDim2.new(1, 0, 0, S.ModuleHeight),
            }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            if dotsBtn then
                self:Tween(dotsBtn, { TextColor3 = S.TextColorDim }, 0.15)
            end
        end
    end

    -- ---- КНОПКА-НЕВИДИМКА ПО ВСЕЙ СТРОКЕ ----
    local clickZone = self:Create("TextButton", {
        Name                = "ClickZone",
        Parent              = moduleRow,
        BackgroundTransparency = 1,
        Text                = "",
        Size                = UDim2.new(1, 0, 1, 0),
        ZIndex              = 11,
        AutoButtonColor     = false,
    })

    -- ЛКМ = toggle
    clickZone.MouseButton1Click:Connect(function()
        setToggled(not isToggled)
    end)

    -- ПКМ = expand/collapse настроек
    clickZone.MouseButton2Click:Connect(function()
        if #moduleSettings > 0 then
            setExpanded(not expanded)
        end
    end)

    -- Hover
    clickZone.MouseEnter:Connect(function()
        if not isToggled then
            self:Tween(moduleRow, {
                BackgroundColor3 = Color3.fromRGB(32, 25, 40),
            }, 0.1)
        end
    end)
    clickZone.MouseLeave:Connect(function()
        if not isToggled then
            self:Tween(moduleRow, {
                BackgroundColor3 = S.ModuleBg,
            }, 0.1)
        end
    end)

    -- Точки hover
    if dotsBtn then
        dotsBtn.MouseEnter:Connect(function()
            self:Tween(dotsBtn, { TextColor3 = S.TextColor }, 0.1)
        end)
        dotsBtn.MouseLeave:Connect(function()
            if not expanded then
                self:Tween(dotsBtn, { TextColor3 = S.TextColorDim }, 0.1)
            end
        end)
        dotsBtn.MouseButton1Click:Connect(function()
            setExpanded(not expanded)
        end)
    end

    -- Применяем дефолт
    if isToggled then
        accentBar.Visible = true
        nameLabel.TextColor3 = S.TextColor
        nameLabel.FontFace   = S.FontBold
        self:AddToArraylist(moduleName)
    end

    -- Сохраняем данные
    local moduleData = {
        Name        = moduleName,
        Category    = categoryName,
        Container   = moduleContainer,
        Row         = moduleRow,
        IsOn        = function() return isToggled end,
        Toggle      = function(val)
            if val ~= nil then
                setToggled(val)
            else
                setToggled(not isToggled)
            end
        end,
        Expand      = setExpanded,
        Settings    = settingsComponents,
    }

    self.Modules[moduleName] = moduleData
    table.insert(catData.Modules, moduleData)
    return moduleData
end

-- ============================================================
--  СТРОИТЕЛЬСТВО КОМПОНЕНТОВ НАСТРОЕК
-- ============================================================

function GlassUI:_BuildSettingComponent(parent, setting, order)
    local S = self.Settings
    local sType = setting.type or "toggle"
    local height = 26

    if sType == "slider" then height = 40 end
    if sType == "dropdown" then height = 26 end
    if sType == "colorpicker" then height = 26 end

    local frame = self:Create("Frame", {
        Name                = "Setting_" .. (setting.name or order),
        Parent              = parent,
        BackgroundTransparency = 1,
        BorderSizePixel     = 0,
        Size                = UDim2.new(1, 0, 0, height),
        LayoutOrder         = order,
        ZIndex              = 8,
    })

    -- ---- TOGGLE ----
    if sType == "toggle" then
        local val = setting.default or false

        local row = self:Create("Frame", {
            Parent              = frame,
            BackgroundColor3    = Color3.fromRGB(20, 15, 28),
            BackgroundTransparency = 0.4,
            BorderSizePixel     = 0,
            Size                = UDim2.new(1, 0, 1, 0),
            ZIndex              = 9,
        })
        self:Corner(row, UDim.new(0, 5))

        self:Create("TextLabel", {
            Parent              = row,
            BackgroundTransparency = 1,
            Text                = setting.name or "Toggle",
            TextColor3          = S.TextColorDim,
            TextSize            = 11,
            FontFace            = S.Font,
            TextXAlignment      = Enum.TextXAlignment.Left,
            Position            = UDim2.new(0, 8, 0, 0),
            Size                = UDim2.new(0, 100, 1, 0),
            ZIndex              = 10,
        })

        local sw = self:Create("Frame", {
            Parent              = row,
            BackgroundColor3    = val and S.AccentColor or Color3.fromRGB(50, 50, 70),
            BorderSizePixel     = 0,
            Size                = UDim2.new(0, 28, 0, 14),
            Position            = UDim2.new(1, -36, 0.5, 0),
            AnchorPoint         = Vector2.new(0, 0.5),
            ZIndex              = 10,
        })
        self:Corner(sw, UDim.new(0, 7))

        local knob = self:Create("Frame", {
            Parent              = sw,
            BackgroundColor3    = Color3.fromRGB(255,255,255),
            BorderSizePixel     = 0,
            Size                = UDim2.new(0, 10, 0, 10),
            Position            = val and UDim2.new(1,-12,0.5,0) or UDim2.new(0,2,0.5,0),
            AnchorPoint         = Vector2.new(0, 0.5),
            ZIndex              = 11,
        })
        self:Corner(knob, UDim.new(0, 5))

        local function update()
            self:Tween(sw,   { BackgroundColor3 = val and S.AccentColor or Color3.fromRGB(50,50,70) }, 0.15)
            self:Tween(knob, { Position = val and UDim2.new(1,-12,0.5,0) or UDim2.new(0,2,0.5,0) }, 0.15, Enum.EasingStyle.Back)
        end

        local btn = self:Create("TextButton", {
            Parent              = frame,
            BackgroundTransparency = 1,
            Text                = "",
            Size                = UDim2.new(1, 0, 1, 0),
            ZIndex              = 12,
            AutoButtonColor     = false,
        })
        btn.MouseButton1Click:Connect(function()
            val = not val
            update()
            if setting.callback then setting.callback(val) end
        end)

        return { Frame = frame, Height = height, GetValue = function() return val end }

    -- ---- SLIDER ----
    elseif sType == "slider" then
        local min  = setting.min or 0
        local max  = setting.max or 100
        local val  = setting.default or min
        local dec  = setting.decimals or 1

        local nameLbl = self:Create("TextLabel", {
            Parent              = frame,
            BackgroundTransparency = 1,
            Text                = setting.name or "Slider",
            TextColor3          = S.TextColorDim,
            TextSize            = 11,
            FontFace            = S.Font,
            TextXAlignment      = Enum.TextXAlignment.Left,
            Position            = UDim2.new(0, 8, 0, 2),
            Size                = UDim2.new(0, 90, 0, 16),
            ZIndex              = 9,
        })

        local valLbl = self:Create("TextLabel", {
            Parent              = frame,
            BackgroundTransparency = 1,
            Text                = tostring(self:Round(val, dec)),
            TextColor3          = S.AccentColor,
            TextSize            = 11,
            FontFace            = S.FontBold,
            TextXAlignment      = Enum.TextXAlignment.Right,
            Position            = UDim2.new(1, -8, 0, 2),
            Size                = UDim2.new(0, 40, 0, 16),
            ZIndex              = 9,
        })

        local track = self:Create("Frame", {
            Parent              = frame,
            BackgroundColor3    = S.SliderTrack,
            BorderSizePixel     = 0,
            Position            = UDim2.new(0, 8, 0, 24),
            Size                = UDim2.new(1, -16, 0, 5),
            ZIndex              = 9,
        })
        self:Corner(track, UDim.new(0, 3))

        local pct0 = (val - min) / (max - min)

        local fill = self:Create("Frame", {
            Parent              = track,
            BackgroundColor3    = S.SliderFill,
            BorderSizePixel     = 0,
            Size                = UDim2.new(pct0, 0, 1, 0),
            ZIndex              = 10,
        })
        self:Corner(fill, UDim.new(0, 3))

        local knob = self:Create("Frame", {
            Parent              = track,
            BackgroundColor3    = Color3.fromRGB(255,255,255),
            BorderSizePixel     = 0,
            Size                = UDim2.new(0, 11, 0, 11),
            Position            = UDim2.new(pct0, 0, 0.5, 0),
            AnchorPoint         = Vector2.new(0.5, 0.5),
            ZIndex              = 11,
        })
        self:Corner(knob, UDim.new(0, 6))

        local dragging = false

        local function applyInput(inputX)
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local p   = math.clamp((inputX - abs.X) / sz.X, 0, 1)
            val = self:Round(min + p * (max - min), dec)
            fill.Size = UDim2.new(p, 0, 1, 0)
            knob.Position = UDim2.new(p, 0, 0.5, 0)
            valLbl.Text = tostring(val)
            if setting.callback then setting.callback(val) end
        end

        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; applyInput(inp.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                applyInput(inp.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        return { Frame = frame, Height = height, GetValue = function() return val end }

    -- ---- DROPDOWN ----
    elseif sType == "dropdown" then
        local opts = setting.options or {}
        local sel  = setting.default or (opts[1] or "")
        local isOpen = false

        local row = self:Create("Frame", {
            Parent              = frame,
            BackgroundColor3    = Color3.fromRGB(20, 15, 28),
            BackgroundTransparency = 0.4,
            BorderSizePixel     = 0,
            Size                = UDim2.new(1, 0, 1, 0),
            ZIndex              = 9,
        })
        self:Corner(row, UDim.new(0, 5))

        self:Create("TextLabel", {
            Parent              = row,
            BackgroundTransparency = 1,
            Text                = setting.name or "Dropdown",
            TextColor3          = S.TextColorDim,
            TextSize            = 11,
            FontFace            = S.Font,
            TextXAlignment      = Enum.TextXAlignment.Left,
            Position            = UDim2.new(0, 8, 0, 0),
            Size                = UDim2.new(0, 80, 1, 0),
            ZIndex              = 10,
        })

        local selLbl = self:Create("TextLabel", {
            Parent              = row,
            BackgroundTransparency = 1,
            Text                = sel,
            TextColor3          = S.AccentColor,
            TextSize            = 11,
            FontFace            = S.FontBold,
            TextXAlignment      = Enum.TextXAlignment.Right,
            Position            = UDim2.new(1, -28, 0, 0),
            Size                = UDim2.new(0, 60, 1, 0),
            ZIndex              = 10,
        })

        local arrow = self:Create("TextLabel", {
            Parent              = row,
            BackgroundTransparency = 1,
            Text                = "▼",
            TextColor3          = S.TextColorDim,
            TextSize            = 9,
            FontFace            = S.Font,
            Position            = UDim2.new(1, -14, 0.5, 0),
            AnchorPoint         = Vector2.new(0, 0.5),
            Size                = UDim2.new(0, 12, 0, 12),
            ZIndex              = 10,
        })

        -- Список опций (показывается снизу row)
        local optFrame = self:Create("Frame", {
            Name                = "OptList",
            Parent              = frame,
            BackgroundColor3    = Color3.fromRGB(14, 10, 20),
            BackgroundTransparency = 0.1,
            BorderSizePixel     = 0,
            Position            = UDim2.new(0, 0, 1, 2),
            Size                = UDim2.new(1, 0, 0, 0),
            ZIndex              = 20,
            Visible             = false,
            ClipsDescendants    = true,
        })
        self:Corner(optFrame, UDim.new(0, 5))
        self:Stroke(optFrame, S.BorderColor, 1, 0.7)

        local optLayout = self:Create("UIListLayout", {
            Parent = optFrame,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 1),
        })
        self:Create("UIPadding", {
            Parent = optFrame,
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 3),
        })

        local optH = #opts * 21 + 6

        for oi, opt in ipairs(opts) do
            local ob = self:Create("TextButton", {
                Parent              = optFrame,
                BackgroundColor3    = opt == sel and S.AccentColor or Color3.fromRGB(22, 17, 30),
                BackgroundTransparency = opt == sel and 0.4 or 0.5,
                BorderSizePixel     = 0,
                Text                = opt,
                TextColor3          = S.TextColor,
                TextSize            = 11,
                FontFace            = S.Font,
                Size                = UDim2.new(1, -8, 0, 20),
                Position            = UDim2.new(0, 4, 0, 0),
                LayoutOrder         = oi,
                ZIndex              = 21,
                AutoButtonColor     = false,
            })
            self:Corner(ob, UDim.new(0, 4))

            ob.MouseButton1Click:Connect(function()
                sel = opt
                selLbl.Text = opt
                -- Сброс цветов
                for _, c in pairs(optFrame:GetChildren()) do
                    if c:IsA("TextButton") then
                        c.BackgroundColor3 = Color3.fromRGB(22,17,30)
                        c.BackgroundTransparency = 0.5
                    end
                end
                ob.BackgroundColor3 = S.AccentColor
                ob.BackgroundTransparency = 0.4
                -- Закрыть
                isOpen = false
                self:Tween(arrow, { Rotation = 0 }, 0.15)
                self:Tween(optFrame, { Size = UDim2.new(1,0,0,0) }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                task.delay(0.15, function() optFrame.Visible = false end)
                if setting.callback then setting.callback(opt) end
            end)
            ob.MouseEnter:Connect(function()
                if opt ~= sel then
                    self:Tween(ob, { BackgroundTransparency = 0.2 }, 0.1)
                end
            end)
            ob.MouseLeave:Connect(function()
                if opt ~= sel then
                    self:Tween(ob, { BackgroundTransparency = 0.5 }, 0.1)
                end
            end)
        end

        local btn = self:Create("TextButton", {
            Parent              = frame,
            BackgroundTransparency = 1,
            Text                = "",
            Size                = UDim2.new(1, 0, 0, height),
            ZIndex              = 15,
            AutoButtonColor     = false,
        })
        btn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                optFrame.Visible = true
                self:Tween(arrow,    { Rotation = 180 },                        0.15)
                self:Tween(optFrame, { Size = UDim2.new(1,0,0,optH) },         0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            else
                self:Tween(arrow,    { Rotation = 0 },                          0.15)
                self:Tween(optFrame, { Size = UDim2.new(1,0,0,0) },            0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                task.delay(0.15, function() optFrame.Visible = false end)
            end
        end)

        return { Frame = frame, Height = height, GetValue = function() return sel end }

    -- ---- COLOR PICKER ----
    elseif sType == "colorpicker" then
        local color = setting.default or Color3.fromRGB(255,255,255)
        local rV, gV, bV = color.R, color.G, color.B

        local row = self:Create("Frame", {
            Parent              = frame,
            BackgroundColor3    = Color3.fromRGB(20, 15, 28),
            BackgroundTransparency = 0.4,
            BorderSizePixel     = 0,
            Size                = UDim2.new(1, 0, 1, 0),
            ZIndex              = 9,
        })
        self:Corner(row, UDim.new(0, 5))

        self:Create("TextLabel", {
            Parent              = row,
            BackgroundTransparency = 1,
            Text                = setting.name or "Color",
            TextColor3          = S.TextColorDim,
            TextSize            = 11,
            FontFace            = S.Font,
            TextXAlignment      = Enum.TextXAlignment.Left,
            Position            = UDim2.new(0, 8, 0, 0),
            Size                = UDim2.new(0, 90, 1, 0),
            ZIndex              = 10,
        })

        local preview = self:Create("Frame", {
            Parent              = row,
            BackgroundColor3    = color,
            BorderSizePixel     = 0,
            Size                = UDim2.new(0, 18, 0, 18),
            Position            = UDim2.new(1, -26, 0.5, 0),
            AnchorPoint         = Vector2.new(0, 0.5),
            ZIndex              = 10,
        })
        self:Corner(preview, UDim.new(0, 4))
        self:Stroke(preview, S.BorderColor, 1, 0.5)

        -- Простой click-to-pick popup
        local pickerOpen = false
        local popup = self:Create("Frame", {
            Parent              = frame,
            BackgroundColor3    = Color3.fromRGB(14, 10, 20),
            BackgroundTransparency = 0.1,
            BorderSizePixel     = 0,
            Position            = UDim2.new(0, 0, 1, 2),
            Size                = UDim2.new(1, 0, 0, 0),
            ZIndex              = 20,
            Visible             = false,
            ClipsDescendants    = true,
        })
        self:Corner(popup, UDim.new(0, 5))
        self:Stroke(popup, S.BorderColor, 1, 0.7)
        self:Create("UIPadding", {
            Parent = popup,
            PaddingTop = UDim.new(0,5), PaddingBottom = UDim.new(0,5),
            PaddingLeft = UDim.new(0,5), PaddingRight = UDim.new(0,5),
        })
        local popLayout = self:Create("UIListLayout", {
            Parent = popup, Padding = UDim.new(0,4),
        })

        local function updateColor()
            local c = Color3.new(rV, gV, bV)
            preview.BackgroundColor3 = c
            color = c
            if setting.callback then setting.callback(c) end
        end

        local function makeRGBBar(lbl, initVal, setter, barColor, order)
            local rowF = self:Create("Frame", {
                Parent = popup, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18), LayoutOrder = order, ZIndex = 21,
            })
            self:Create("TextLabel", {
                Parent = rowF, BackgroundTransparency = 1,
                Text = lbl, TextColor3 = S.TextColor, TextSize = 10,
                FontFace = S.FontBold, TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(0, 14, 1, 0), ZIndex = 22,
            })
            local t = self:Create("Frame", {
                Parent = rowF, BackgroundColor3 = barColor, BorderSizePixel = 0,
                Position = UDim2.new(0, 18, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(1, -18, 0, 5), ZIndex = 22,
            })
            self:Corner(t, UDim.new(0,3))
            local k = self:Create("Frame", {
                Parent = t, BackgroundColor3 = Color3.fromRGB(255,255,255),
                BorderSizePixel = 0, Size = UDim2.new(0,10,0,10),
                Position = UDim2.new(initVal, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 23,
            })
            self:Corner(k, UDim.new(0,5))
            local drag = false
            t.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    drag = true
                    local p = math.clamp((inp.Position.X - t.AbsolutePosition.X) / t.AbsoluteSize.X, 0, 1)
                    setter(p); k.Position = UDim2.new(p,0,0.5,0); updateColor()
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local p = math.clamp((inp.Position.X - t.AbsolutePosition.X) / t.AbsoluteSize.X, 0, 1)
                    setter(p); k.Position = UDim2.new(p,0,0.5,0); updateColor()
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
            end)
        end

        makeRGBBar("R", rV, function(v) rV = v end, Color3.fromRGB(220,60,60), 1)
        makeRGBBar("G", gV, function(v) gV = v end, Color3.fromRGB(60,200,60), 2)
        makeRGBBar("B", bV, function(v) bV = v end, Color3.fromRGB(60,100,220), 3)

        local popH = 3 * 18 + 2 * 4 + 10

        local btn = self:Create("TextButton", {
            Parent = frame, BackgroundTransparency = 1, Text = "",
            Size = UDim2.new(1,0,0,height), ZIndex = 15, AutoButtonColor = false,
        })
        btn.MouseButton1Click:Connect(function()
            pickerOpen = not pickerOpen
            if pickerOpen then
                popup.Visible = true
                self:Tween(popup, { Size = UDim2.new(1,0,0,popH) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            else
                self:Tween(popup, { Size = UDim2.new(1,0,0,0) }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                task.delay(0.15, function() popup.Visible = false end)
            end
        end)

        return { Frame = frame, Height = height, GetValue = function() return color end }
    end

    -- Неизвестный тип — заглушка
    return { Frame = frame, Height = height, GetValue = function() return nil end }
end

-- ============================================================
--  ВАТЕРМАРКА
-- ============================================================

function GlassUI:_BuildWatermark()
    local S = self.Settings

    self.WMFrame = self:Create("Frame", {
        Name                = "Watermark",
        Parent              = self.Root,
        BackgroundColor3    = S.PanelBg,
        BackgroundTransparency = 0.2,
        BorderSizePixel     = 0,
        Position            = UDim2.new(0, 12, 0, 12),
        Size                = UDim2.new(0, 0, 0, 0),
        ZIndex              = 50,
        ClipsDescendants    = true,
    })
    self:Corner(self.WMFrame, UDim.new(0, 8))
    self:Stroke(self.WMFrame, S.BorderColor, 1, 0.6)

    -- Левая часть (Alpha + иконка)
    self.WMLeft = self:Create("Frame", {
        Name                = "Left",
        Parent              = self.WMFrame,
        BackgroundColor3    = S.AccentColor,
        BackgroundTransparency = 0.25,
        BorderSizePixel     = 0,
        Size                = UDim2.new(0, 0, 1, 0),
        ZIndex              = 51,
    })
    self:Corner(self.WMLeft, UDim.new(0, 8))

    self:Create("ImageLabel", {
        Parent              = self.WMLeft,
        BackgroundTransparency = 1,
        Image               = "rbxassetid://12877753076",
        Size                = UDim2.new(0, 13, 0, 13),
        Position            = UDim2.new(0, 7, 0.5, 0),
        AnchorPoint         = Vector2.new(0, 0.5),
        ZIndex              = 52,
    })
    self:Create("TextLabel", {
        Name                = "Title",
        Parent              = self.WMLeft,
        BackgroundTransparency = 1,
        Text                = "Alpha",
        TextColor3          = Color3.fromRGB(255,255,255),
        TextSize            = 12,
        FontFace            = S.FontBold,
        TextXAlignment      = Enum.TextXAlignment.Left,
        Position            = UDim2.new(0, 24, 0.5, 0),
        AnchorPoint         = Vector2.new(0, 0.5),
        Size                = UDim2.new(0, 40, 1, 0),
        ZIndex              = 52,
    })

    -- Правая часть (ник)
    self.WMRight = self:Create("Frame", {
        Name                = "Right",
        Parent              = self.WMFrame,
        BackgroundColor3    = Color3.fromRGB(18, 14, 26),
        BackgroundTransparency = 0.35,
        BorderSizePixel     = 0,
        Size                = UDim2.new(0, 0, 1, 0),
        ZIndex              = 51,
    })
    self:Corner(self.WMRight, UDim.new(0, 8))

    self:Create("TextLabel", {
        Name                = "Nick",
        Parent              = self.WMRight,
        BackgroundTransparency = 1,
        Text                = LocalPlayer.Name,
        TextColor3          = S.TextColor,
        TextSize            = 12,
        FontFace            = S.Font,
        TextXAlignment      = Enum.TextXAlignment.Left,
        Position            = UDim2.new(0, 8, 0.5, 0),
        AnchorPoint         = Vector2.new(0, 0.5),
        Size                = UDim2.new(1, -10, 1, 0),
        ZIndex              = 52,
    })

    -- Ticks индикатор
    self.WMTick = self:Create("Frame", {
        Name                = "Ticks",
        Parent              = self.Root,
        BackgroundColor3    = S.PanelBg,
        BackgroundTransparency = 0.3,
        BorderSizePixel     = 0,
        Position            = UDim2.new(0, 12, 0, 52),
        Size                = UDim2.new(0, 0, 0, 18),
        ZIndex              = 50,
        ClipsDescendants    = true,
    })
    self:Corner(self.WMTick, UDim.new(0, 5))
    self:Create("TextLabel", {
        Parent              = self.WMTick,
        BackgroundTransparency = 1,
        Text                = "20 Ticks",
        TextColor3          = S.TextColorDim,
        TextSize            = 10,
        FontFace            = S.Font,
        Size                = UDim2.new(1,0,1,0),
        ZIndex              = 51,
    })
end

function GlassUI:_ShowWatermark()
    local S = self.Settings
    self:Tween(self.WMFrame, { Size = UDim2.new(0, 150, 0, 28) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    self:Tween(self.WMLeft,  { Size = UDim2.new(0, 68, 1, 0)   }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    self:Tween(self.WMRight, {
        Size     = UDim2.new(0, 78, 1, 0),
        Position = UDim2.new(0, 72, 0, 0),
    }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    self:Tween(self.WMTick, { Size = UDim2.new(0, 58, 0, 18) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function GlassUI:_HideWatermark()
    self:Tween(self.WMFrame, { Size = UDim2.new(0, 0, 0, 0)  }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    self:Tween(self.WMTick,  { Size = UDim2.new(0, 0, 0, 18) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

-- ============================================================
--  СПИСОК ИГРОКОВ (правый верхний угол)
-- ============================================================

function GlassUI:_BuildPlayerList()
    local S = self.Settings

    self.PlayerListFrame = self:Create("Frame", {
        Name                = "PlayerList",
        Parent              = self.Root,
        BackgroundColor3    = S.PanelBg,
        BackgroundTransparency = 0.2,
        BorderSizePixel     = 0,
        Position            = UDim2.new(1, -12, 0, 12),
        AnchorPoint         = Vector2.new(1, 0),
        Size                = UDim2.new(0, 160, 0, 0),
        ZIndex              = 50,
        ClipsDescendants    = true,
    })
    self:Corner(self.PlayerListFrame, UDim.new(0, 8))
    self:Stroke(self.PlayerListFrame, S.BorderColor, 1, 0.6)

    self:Create("UIListLayout", {
        Parent = self.PlayerListFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })
    self:Create("UIPadding", {
        Parent = self.PlayerListFrame,
        PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,6),
        PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6),
    })
end

function GlassUI:UpdatePlayerList()
    local S = self.Settings
    for _, c in pairs(self.PlayerListFrame:GetChildren()) do
        if c:IsA("Frame") and c.Name == "Entry" then c:Destroy() end
    end

    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p) end
    end
    table.sort(list, function(a, b) return a.Name < b.Name end)

    local colors = {
        Color3.fromRGB(59,130,246), Color3.fromRGB(34,197,94),
        Color3.fromRGB(234,179,8),  Color3.fromRGB(239,68,68),
        Color3.fromRGB(168,85,247),
    }

    for i, p in ipairs(list) do
        local entry = self:Create("Frame", {
            Name = "Entry", Parent = self.PlayerListFrame,
            BackgroundColor3 = Color3.fromRGB(24,18,34),
            BackgroundTransparency = 0.5, BorderSizePixel = 0,
            Size = UDim2.new(1,0,0,22), LayoutOrder = i, ZIndex = 51,
        })
        self:Corner(entry, UDim.new(0,5))

        local dot = self:Create("Frame", {
            Parent = entry, BackgroundColor3 = colors[(p.UserId % #colors) + 1],
            BorderSizePixel = 0, Size = UDim2.new(0,5,0,5),
            Position = UDim2.new(0,5,0.5,0), AnchorPoint = Vector2.new(0,0.5), ZIndex = 52,
        })
        self:Corner(dot, UDim.new(0,3))

        self:Create("TextLabel", {
            Parent = entry, BackgroundTransparency = 1,
            Text = p.Name, TextColor3 = S.TextColor,
            TextSize = 11, FontFace = S.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0,16,0,0),
            Size = UDim2.new(1,-18,1,0), ZIndex = 52,
        })
    end

    self:Tween(self.PlayerListFrame, {
        Size = UDim2.new(0, 160, 0, math.max(0, #list * 24 + 12)),
    }, 0.2)
end

-- ============================================================
--  ПОИСК (нижний центр)
-- ============================================================

function GlassUI:_BuildSearchBar()
    local S = self.Settings

    self.SearchFrame = self:Create("Frame", {
        Name                = "SearchBar",
        Parent              = self.Root,
        BackgroundColor3    = S.PanelBg,
        BackgroundTransparency = 0.2,
        BorderSizePixel     = 0,
        Position            = UDim2.new(0.5, 0, 1, -50),
        AnchorPoint         = Vector2.new(0.5, 1),
        Size                = UDim2.new(0, 280, 0, 32),
        ZIndex              = 50,
        Visible             = false,
    })
    self:Corner(self.SearchFrame, UDim.new(0, 8))
    self:Stroke(self.SearchFrame, S.BorderColor, 1, 0.6)

    self:Create("ImageLabel", {
        Parent = self.SearchFrame, BackgroundTransparency = 1,
        Image = "rbxassetid://7072706618",
        ImageColor3 = S.TextColorDim,
        Size = UDim2.new(0,14,0,14),
        Position = UDim2.new(0,10,0.5,0), AnchorPoint = Vector2.new(0,0.5),
        ZIndex = 51,
    })

    self.SearchInput = self:Create("TextBox", {
        Name = "Input", Parent = self.SearchFrame,
        BackgroundTransparency = 1,
        Text = "", PlaceholderText = "Поиск...",
        PlaceholderColor3 = S.TextColorDim,
        TextColor3 = S.TextColor,
        TextSize = 12, FontFace = S.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 30, 0, 0),
        Size = UDim2.new(1, -38, 1, 0),
        ZIndex = 51, ClearTextOnFocus = false,
    })

    self.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local q = self.SearchInput.Text:lower()
        for _, catData in pairs(self.CategoryData) do
            for _, mod in pairs(catData.Modules) do
                local vis = (q == "") or mod.Name:lower():find(q, 1, true) ~= nil
                mod.Container.Visible = vis
            end
        end
    end)
end

-- ============================================================
--  CONFIG MANAGER (правый нижний угол)
-- ============================================================

function GlassUI:_BuildConfigManager()
    local S = self.Settings

    self.CfgFrame = self:Create("Frame", {
        Name                = "ConfigManager",
        Parent              = self.Root,
        BackgroundColor3    = S.PanelBg,
        BackgroundTransparency = 0.15,
        BorderSizePixel     = 0,
        Position            = UDim2.new(1, -12, 1, -12),
        AnchorPoint         = Vector2.new(1, 1),
        Size                = UDim2.new(0, 185, 0, 0),
        ZIndex              = 50,
        Visible             = false,
        ClipsDescendants    = true,
    })
    self:Corner(self.CfgFrame, UDim.new(0, 10))
    self:Stroke(self.CfgFrame, S.BorderColor, 1, 0.6)

    -- Заголовок
    local hdr = self:Create("Frame", {
        Parent = self.CfgFrame, BackgroundColor3 = S.AccentColor,
        BackgroundTransparency = 0.85, BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,28), ZIndex = 51,
    })
    self:Corner(hdr, UDim.new(0,10))
    self:Create("TextLabel", {
        Parent = hdr, BackgroundTransparency = 1,
        Text = "Config Manager", TextColor3 = S.TextColor,
        TextSize = 12, FontFace = S.FontBold,
        Size = UDim2.new(1,0,1,0), ZIndex = 52,
    })

    -- Поле названия
    local inputFrame = self:Create("Frame", {
        Parent = self.CfgFrame, BackgroundColor3 = Color3.fromRGB(20,15,30),
        BackgroundTransparency = 0.4, BorderSizePixel = 0,
        Position = UDim2.new(0,8,0,36), Size = UDim2.new(1,-16,0,26),
        ZIndex = 51,
    })
    self:Corner(inputFrame, UDim.new(0,6))
    self:Create("TextLabel", {
        Parent = inputFrame, BackgroundTransparency = 1,
        Text = "Название", TextColor3 = S.TextColorDim,
        TextSize = 10, FontFace = S.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0,7,0,0), Size = UDim2.new(0,55,1,0), ZIndex = 52,
    })
    local cfgInput = self:Create("TextBox", {
        Parent = inputFrame, BackgroundTransparency = 1,
        Text = "", PlaceholderText = "my_config",
        PlaceholderColor3 = Color3.fromRGB(70,70,90),
        TextColor3 = S.TextColor, TextSize = 11, FontFace = S.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0,64,0,0), Size = UDim2.new(1,-72,1,0),
        ZIndex = 52, ClearTextOnFocus = false,
    })

    -- Кнопки
    local function mkBtn(text, color, yPos, cb)
        local b = self:Create("TextButton", {
            Parent = self.CfgFrame, BackgroundColor3 = color,
            BackgroundTransparency = 0.35, BorderSizePixel = 0,
            Text = text, TextColor3 = S.TextColor,
            TextSize = 11, FontFace = S.FontBold,
            Position = UDim2.new(0,8,0,yPos), Size = UDim2.new(1,-16,0,22),
            ZIndex = 51, AutoButtonColor = false,
        })
        self:Corner(b, UDim.new(0,6))
        b.MouseEnter:Connect(function() self:Tween(b,{BackgroundTransparency=0.1},0.1) end)
        b.MouseLeave:Connect(function() self:Tween(b,{BackgroundTransparency=0.35},0.1) end)
        b.MouseButton1Click:Connect(function()
            local orig = b.BackgroundColor3
            self:Tween(b,{BackgroundColor3=S.AccentColor},0.08)
            task.delay(0.15, function() self:Tween(b,{BackgroundColor3=orig},0.15) end)
            if cb then cb(cfgInput.Text) end
        end)
        return b
    end

    mkBtn("Создать",   S.SuccessColor,                    70,  function(n) if n~="" then print("[Cfg] Created: "..n) end end)
    mkBtn("Сохранить", S.AccentColor,                     96,  function()  print("[Cfg] Saved") end)
    mkBtn("Загрузить", Color3.fromRGB(45,45,75),          122, function()  print("[Cfg] Loaded") end)
    mkBtn("Удалить",   S.DangerColor,                     148, function()  print("[Cfg] Deleted") end)

    -- Финальная высота
    self.CfgFrame.Size = UDim2.new(0, 185, 0, 0)
end

-- ============================================================
--  ARRAYLIST (левый нижний угол)
-- ============================================================

function GlassUI:_BuildArraylist()
    self.ALFrame = self:Create("Frame", {
        Name                = "Arraylist",
        Parent              = self.Root,
        BackgroundTransparency = 1,
        Position            = UDim2.new(0, 12, 1, -12),
        AnchorPoint         = Vector2.new(0, 1),
        Size                = UDim2.new(0, 180, 0, 500),
        ZIndex              = 50,
    })
    self:Create("UIListLayout", {
        Parent = self.ALFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    })
end

function GlassUI:AddToArraylist(name)
    if self.ActiveModules[name] then return end
    local S = self.Settings

    local e = self:Create("Frame", {
        Name = name, Parent = self.ALFrame,
        BackgroundColor3 = S.PanelBg,
        BackgroundTransparency = 0.25, BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 20), ZIndex = 51, ClipsDescendants = true,
    })
    self:Corner(e, UDim.new(0, 5))

    local bar = self:Create("Frame", {
        Parent = e, BackgroundColor3 = S.AccentColor,
        BorderSizePixel = 0, Size = UDim2.new(0, 3, 1, -4),
        Position = UDim2.new(0, 0, 0, 2), ZIndex = 52,
    })
    self:Corner(bar, UDim.new(0,2))

    self:Create("TextLabel", {
        Parent = e, BackgroundTransparency = 1,
        Text = name, TextColor3 = S.TextColor,
        TextSize = 11, FontFace = S.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -10, 1, 0), ZIndex = 52,
    })

    self:Tween(e, { Size = UDim2.new(0, 130, 0, 20) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    self.ActiveModules[name] = e
end

function GlassUI:RemoveFromArraylist(name)
    local e = self.ActiveModules[name]
    if not e then return end
    self:Tween(e, { Size = UDim2.new(0, 0, 0, 20) }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.delay(0.15, function() e:Destroy(); self.ActiveModules[name] = nil end)
end

-- ============================================================
--  УВЕДОМЛЕНИЯ
-- ============================================================

function GlassUI:_BuildNotifications()
    local S = self.Settings
    self.NotifContainer = self:Create("Frame", {
        Name = "Notifications", Parent = self.Root,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -12, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.new(0, 260, 0, 500),
        ZIndex = 200,
    })
    self:Create("UIListLayout", {
        Parent = self.NotifContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    })
end

function GlassUI:Notify(title, message, duration, nType)
    duration = duration or 3
    local S = self.Settings
    local ac = S.AccentColor
    if nType == "success" then ac = S.SuccessColor
    elseif nType == "error" then ac = S.DangerColor
    elseif nType == "warning" then ac = S.WarningColor end

    local nf = self:Create("Frame", {
        Name = "Notif", Parent = self.NotifContainer,
        BackgroundColor3 = S.PanelBg,
        BackgroundTransparency = 0.15, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0), ZIndex = 201, ClipsDescendants = true,
    })
    self:Corner(nf, UDim.new(0,8))
    self:Stroke(nf, S.BorderColor, 1, 0.65)

    local topLine = self:Create("Frame", {
        Parent = nf, BackgroundColor3 = ac,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,2), ZIndex = 202,
    })
    self:Corner(topLine, UDim.new(0,2))

    self:Create("TextLabel", {
        Parent = nf, BackgroundTransparency = 1,
        Text = title, TextColor3 = ac,
        TextSize = 12, FontFace = S.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0,10,0,8), Size = UDim2.new(1,-20,0,16), ZIndex = 202,
    })
    self:Create("TextLabel", {
        Parent = nf, BackgroundTransparency = 1,
        Text = message, TextColor3 = S.TextColorDim,
        TextSize = 11, FontFace = S.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Position = UDim2.new(0,10,0,26), Size = UDim2.new(1,-20,0,20), ZIndex = 202,
    })

    local pb = self:Create("Frame", {
        Parent = nf, BackgroundColor3 = ac,
        BackgroundTransparency = 0.5, BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,1,-2), ZIndex = 202,
    })

    self:Tween(nf, { Size = UDim2.new(1,0,0,58) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(0.25, function()
        self:Tween(pb, { Size = UDim2.new(0,0,0,2) }, duration, Enum.EasingStyle.Linear)
    end)
    task.delay(duration + 0.25, function()
        self:Tween(nf, { Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.25, function() nf:Destroy() end)
    end)
end

-- ============================================================
--  ОТКРЫТИЕ / ЗАКРЫТИЕ МЕНЮ
-- ============================================================

function GlassUI:ShowMenu()
    if self.Animating then return end
    self.Animating = true
    self.Visible   = true

    self.Dim.Visible = true
    self.Dim.BackgroundTransparency = 1
    self:Tween(self.Dim, { BackgroundTransparency = 0.55 }, 0.25)

    self.MenuHolder.Visible = true

    -- Анимация появления — масштаб + прозрачность
    self.ColumnsFrame.Position = UDim2.new(0, 0, 0, 20)
    for _, cat in pairs(self.CategoryData) do
        cat.Panel.BackgroundTransparency = 1
        for _, c in pairs(cat.Panel:GetChildren()) do
            pcall(function()
                if c:IsA("Frame") or c:IsA("TextLabel") then
                    c.BackgroundTransparency = 1
                end
            end)
        end
    end

    self:Tween(self.ColumnsFrame, { Position = UDim2.new(0,0,0,0) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Панели по очереди (stagger)
    for i, cat in ipairs(Categories) do
        local data = self.CategoryData[cat.Name]
        if data then
            task.delay((i-1) * 0.04, function()
                self:Tween(data.Panel, { BackgroundTransparency = 0.15 }, 0.25)
            end)
        end
    end

    -- SearchBar
    self.SearchFrame.Visible = true
    self.SearchFrame.Position = UDim2.new(0.5, 0, 1, 60)
    self:Tween(self.SearchFrame, { Position = UDim2.new(0.5, 0, 1, -50) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- ConfigManager
    self.CfgFrame.Visible = true
    self.CfgFrame.Size = UDim2.new(0, 0, 0, 0)
    self:Tween(self.CfgFrame, { Size = UDim2.new(0, 185, 0, 178) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    self:_ShowWatermark()
    self:UpdatePlayerList()

    task.delay(0.35, function()
        self.Animating = false
    end)

    task.delay(0.5, function()
        self:Notify("Alpha", "Меню открыто", 2, "info")
    end)
end

function GlassUI:HideMenu()
    if self.Animating then return end
    self.Animating = true
    self.Visible   = false

    self:Tween(self.Dim, { BackgroundTransparency = 1 }, 0.2)

    -- Панели гаснут
    for i, cat in ipairs(Categories) do
        local data = self.CategoryData[cat.Name]
        if data then
            task.delay((#Categories - i) * 0.03, function()
                self:Tween(data.Panel, { BackgroundTransparency = 1 }, 0.15)
            end)
        end
    end
    self:Tween(self.ColumnsFrame, { Position = UDim2.new(0,0,0,15) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    self:Tween(self.SearchFrame, { Position = UDim2.new(0.5, 0, 1, 60) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    self:Tween(self.CfgFrame, { Size = UDim2.new(0, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    self:_HideWatermark()
    self:Tween(self.PlayerListFrame, { Size = UDim2.new(0, 160, 0, 0) }, 0.2)

    task.delay(0.3, function()
        self.Dim.Visible = false
        self.MenuHolder.Visible = false
        self.SearchFrame.Visible = false
        self.CfgFrame.Visible = false
        self.Animating = false
    end)
end

-- ============================================================
--  ВВОД
-- ============================================================

function GlassUI:_SetupInput()
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == self.Settings.ToggleKey then
            if self.Visible then self:HideMenu() else self:ShowMenu() end
        end
    end)
end

-- ============================================================
--  ВОЗВРАТ
-- ============================================================

return GlassUI
