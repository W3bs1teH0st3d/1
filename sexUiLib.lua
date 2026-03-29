-- ============================================================
--  GLASS UI v3
--  5 колонок, центр экрана, ПКМ = настройки,
--  перетаскиваемый HUD, динамические настройки
-- ============================================================

local Players        = game:GetService("Players")
local UIS            = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local LP             = Players.LocalPlayer

-- ================================================================
--  КОНСТАНТЫ
-- ================================================================
local C = {
    -- Цвета
    BG          = Color3.fromRGB(10,  8,  16),
    PANEL       = Color3.fromRGB(16, 13, 24),
    MODULE_OFF  = Color3.fromRGB(22, 18, 32),
    MODULE_ON   = Color3.fromRGB(38, 28, 58),
    ACCENT      = Color3.fromRGB(99, 102, 241),
    ACCENT2     = Color3.fromRGB(139, 92, 246),
    TEXT        = Color3.fromRGB(230, 230, 240),
    TEXT_DIM    = Color3.fromRGB(130, 125, 150),
    TEXT_DARK   = Color3.fromRGB(80,  75, 100),
    BORDER      = Color3.fromRGB(45,  40, 65),
    BORDER_LIT  = Color3.fromRGB(80,  75, 110),
    SUCCESS     = Color3.fromRGB(34,  197, 94),
    DANGER      = Color3.fromRGB(239, 68,  68),
    WARNING     = Color3.fromRGB(234, 179,  8),
    SLIDER_TRK  = Color3.fromRGB(30,  26, 44),
    -- Шрифты
    FONT        = Font.new("rbxasset://fonts/families/GothamSSm.json"),
    FONT_BOLD   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
    FONT_SEMI   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
    -- Размеры
    COL_W       = 158,
    COL_GAP     = 6,
    COL_H       = 380,
    MOD_H       = 24,
    MOD_GAP     = 3,
    CORNER      = UDim.new(0, 8),
    CORNER_SM   = UDim.new(0, 5),
    CORNER_XS   = UDim.new(0, 4),
    ANIM        = 0.18,
}

local CATS = {
    { Name = "Combat",        Short = "CMB" },
    { Name = "Movement",      Short = "MOV" },
    { Name = "Visuals",       Short = "VIS" },
    { Name = "Player",        Short = "PLR" },
    { Name = "Miscellaneous", Short = "MSC" },
}

-- ================================================================
--  LIBRARY
-- ================================================================
local UI = {}
UI.__index = UI

UI.Visible      = false
UI.Animating    = false
UI.CatData      = {}   -- { [catName] = { Scroll, Layout, Modules=[] } }
UI.ModData      = {}   -- { [modName] = moduleObj }
UI.ActiveMods   = {}   -- { [modName] = arraylistEntry }
UI.ToggleKey    = Enum.KeyCode.RightShift

-- ================================================================
--  HELPERS
-- ================================================================
local function New(t, p)
    local o = Instance.new(t)
    for k, v in pairs(p) do
        if k ~= "Parent" then o[k] = v end
    end
    if p.Parent then o.Parent = p.Parent end
    return o
end

local function Corner(obj, r)
    New("UICorner", { CornerRadius = r or C.CORNER, Parent = obj })
    return obj
end

local function Stroke(obj, col, th, tr)
    New("UIStroke", {
        Color        = col or C.BORDER,
        Thickness    = th  or 1,
        Transparency = tr  or 0.0,
        Parent       = obj,
    })
    return obj
end

local function Tween(obj, props, dur, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(
            dur   or C.ANIM,
            style or Enum.EasingStyle.Quart,
            dir   or Enum.EasingDirection.Out
        ),
        props
    )
    t:Play()
    return t
end

local function RoundN(n, d)
    local m = 10^(d or 2)
    return math.floor(n * m + 0.5) / m
end

local function Lerp(a, b, t)
    return a + (b-a)*t
end

-- Перетаскивание произвольного фрейма
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local drag, dx, dy = false, 0, 0
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            dx = inp.Position.X - frame.AbsolutePosition.X
            dy = inp.Position.Y - frame.AbsolutePosition.Y
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            frame.Position = UDim2.new(0, inp.Position.X - dx, 0, inp.Position.Y - dy)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

-- ================================================================
--  INIT
-- ================================================================
function UI:Init()
    self.Gui = New("ScreenGui", {
        Name           = "GlassUI_v3",
        Parent         = LP:WaitForChild("PlayerGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
    })

    self.Root = New("Frame", {
        Parent                 = self.Gui,
        BackgroundColor3       = Color3.new(0,0,0),
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1,0,1,0),
        ZIndex                 = 1,
    })

    -- Затемнение
    self.Dim = New("Frame", {
        Parent                 = self.Root,
        BackgroundColor3       = Color3.new(0,0,0),
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1,0,1,0),
        ZIndex                 = 2,
        Visible                = false,
    })

    self.Menu = New("Frame", {
        Parent                 = self.Root,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(0,0,0,0),
        ZIndex                 = 3,
        Visible                = false,
    })

    self:_MakeColumns()
    self:_MakeWatermark()
    self:_MakeKeyBindHUD()
    self:_MakeSearchBar()
    self:_MakeConfigMgr()
    self:_MakeArraylist()
    self:_MakeNotifications()
    self:_SetupInput()

    task.delay(0.8, function()
        self:Notify("Alpha", "RShift — открыть меню", 3, "info")
    end)

    return self
end

-- ================================================================
--  COLUMNS
-- ================================================================
function UI:_MakeColumns()
    local totalW = #CATS * C.COL_W + (#CATS-1) * C.COL_GAP
    local totalH = C.COL_H

    -- Центрируем Menu
    self.Menu.Size     = UDim2.new(0, totalW, 0, totalH)
    self.Menu.Position = UDim2.new(0.5, -totalW/2, 0.5, -totalH/2)

    self.ColHolder = New("Frame", {
        Parent                 = self.Menu,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1,0,1,0),
        ZIndex                 = 4,
    })

    for i, cat in ipairs(CATS) do
        local x = (i-1)*(C.COL_W + C.COL_GAP)

        -- Панель
        local panel = New("Frame", {
            Parent                 = self.ColHolder,
            Name                   = cat.Name,
            BackgroundColor3       = C.PANEL,
            BackgroundTransparency = 0.08,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0, x, 0, 0),
            Size                   = UDim2.new(0, C.COL_W, 0, C.COL_H),
            ZIndex                 = 5,
            ClipsDescendants       = true,
        })
        Corner(panel)
        Stroke(panel, C.BORDER, 1, 0.55)

        -- Шапка
        local hdr = New("Frame", {
            Parent                 = panel,
            BackgroundColor3       = C.ACCENT,
            BackgroundTransparency = 0.82,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1, 0, 0, 32),
            ZIndex                 = 6,
        })
        Corner(hdr, UDim.new(0, 8))

        -- Линия под шапкой
        New("Frame", {
            Parent                 = panel,
            BackgroundColor3       = C.BORDER,
            BackgroundTransparency = 0.5,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0, 0, 0, 32),
            Size                   = UDim2.new(1, 0, 0, 1),
            ZIndex                 = 6,
        })

        New("TextLabel", {
            Parent                 = hdr,
            BackgroundTransparency = 1,
            Text                   = cat.Name,
            TextColor3             = C.TEXT,
            TextSize               = 12,
            FontFace               = C.FONT_BOLD,
            Size                   = UDim2.new(1,0,1,0),
            ZIndex                 = 7,
        })

        -- Scrolling frame
        local scroll = New("ScrollingFrame", {
            Parent                     = panel,
            BackgroundTransparency     = 1,
            BorderSizePixel            = 0,
            Position                   = UDim2.new(0, 0, 0, 33),
            Size                       = UDim2.new(1, 0, 1, -33),
            ZIndex                     = 6,
            ScrollBarThickness         = 2,
            ScrollBarImageColor3       = C.ACCENT,
            ScrollBarImageTransparency = 0.5,
            CanvasSize                 = UDim2.new(0,0,0,0),
            ScrollingDirection         = Enum.ScrollingDirection.Y,
            ElasticBehavior            = Enum.ElasticBehavior.Never,
            TopImage                   = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage                = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        })

        local layout = New("UIListLayout", {
            Parent        = scroll,
            SortOrder     = Enum.SortOrder.LayoutOrder,
            Padding       = UDim.new(0, C.MOD_GAP),
        })
        New("UIPadding", {
            Parent        = scroll,
            PaddingTop    = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft   = UDim.new(0, 4),
            PaddingRight  = UDim.new(0, 4),
        })

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 10)
        end)

        self.CatData[cat.Name] = {
            Panel   = panel,
            Scroll  = scroll,
            Layout  = layout,
            Modules = {},
        }
    end
end

-- ================================================================
--  MODULE
-- ================================================================
function UI:AddModule(catName, modName, opts)
    opts = opts or {}
    local cat = self.CatData[catName]
    if not cat then warn("[UI] Cat not found: "..catName) return end

    local S        = opts.settings or {}
    local toggled  = opts.default  or false
    local onToggle = opts.onToggle

    local order = #cat.Modules + 1

    -- ── Внешний контейнер (меняет высоту при раскрытии) ──
    local container = New("Frame", {
        Parent                 = cat.Scroll,
        Name                   = "Mod_"..modName,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, C.MOD_H),
        LayoutOrder            = order,
        ZIndex                 = 7,
        ClipsDescendants       = false,
    })

    -- ── Строка модуля ──
    local row = New("Frame", {
        Parent                 = container,
        BackgroundColor3       = toggled and C.MODULE_ON or C.MODULE_OFF,
        BackgroundTransparency = 0.15,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, C.MOD_H),
        ZIndex                 = 8,
    })
    Corner(row, C.CORNER_SM)
    Stroke(row, C.BORDER, 1, 0.65)

    -- Акцент-полоса слева
    local accent = New("Frame", {
        Parent                 = row,
        BackgroundColor3       = C.ACCENT,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0, 4),
        Size                   = UDim2.new(0, 2, 1, -8),
        ZIndex                 = 9,
        Visible                = toggled,
    })
    Corner(accent, UDim.new(0, 2))

    -- Название
    local lbl = New("TextLabel", {
        Parent                 = row,
        BackgroundTransparency = 1,
        Text                   = modName,
        TextColor3             = toggled and C.TEXT or C.TEXT_DIM,
        TextSize               = 12,
        FontFace               = toggled and C.FONT_SEMI or C.FONT,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        Position               = UDim2.new(0, 9, 0, 0),
        Size                   = UDim2.new(1, -28, 1, 0),
        ZIndex                 = 9,
    })

    -- Три точки (если есть настройки)
    local dots
    if #S > 0 then
        dots = New("TextLabel", {
            Parent                 = row,
            BackgroundTransparency = 1,
            Text                   = "···",
            TextColor3             = C.TEXT_DARK,
            TextSize               = 14,
            FontFace               = C.FONT_BOLD,
            Position               = UDim2.new(1, -20, 0, 0),
            Size                   = UDim2.new(0, 18, 1, 0),
            ZIndex                 = 9,
        })
    end

    -- ── Панель настроек ──
    local settPanel, settHeight = nil, 0
    local settComponents        = {}
    local expanded              = false

    if #S > 0 then
        settPanel = New("Frame", {
            Parent                 = container,
            Name                   = "Settings",
            BackgroundColor3       = Color3.fromRGB(14, 11, 21),
            BackgroundTransparency = 0.12,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0, 2, 0, C.MOD_H + 2),
            Size                   = UDim2.new(1, -4, 0, 0),
            ZIndex                 = 7,
            ClipsDescendants       = true,
        })
        Corner(settPanel, C.CORNER_XS)
        Stroke(settPanel, C.BORDER, 1, 0.7)

        local sLayout = New("UIListLayout", {
            Parent    = settPanel,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 2),
        })
        New("UIPadding", {
            Parent        = settPanel,
            PaddingTop    = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft   = UDim.new(0, 5),
            PaddingRight  = UDim.new(0, 5),
        })

        -- Строим компоненты
        for si, sett in ipairs(S) do
            local comp = self:_MakeSetting(settPanel, sett, si)
            table.insert(settComponents, comp)
        end

        -- Функция пересчёта высоты настроек
        local function recalcHeight()
            local h = 8
            for _, comp in ipairs(settComponents) do
                h = h + comp:GetHeight() + 2
            end
            return h
        end

        -- Подписываем компоненты на изменение высоты
        for _, comp in ipairs(settComponents) do
            if comp.OnHeightChanged then
                comp.OnHeightChanged(function()
                    if expanded then
                        local nh = recalcHeight()
                        settHeight = nh
                        Tween(settPanel,   { Size = UDim2.new(1,-4,0,nh) },       0.2, Enum.EasingStyle.Quart)
                        Tween(container,   { Size = UDim2.new(1,0,0,C.MOD_H+2+nh) }, 0.2, Enum.EasingStyle.Quart)
                    end
                end)
            end
        end

        settHeight = recalcHeight()
    end

    -- ── TOGGLE ──
    local function applyToggle(val, silent)
        toggled = val
        Tween(row, { BackgroundColor3 = toggled and C.MODULE_ON or C.MODULE_OFF }, 0.15)
        lbl.TextColor3 = toggled and C.TEXT or C.TEXT_DIM
        lbl.FontFace   = toggled and C.FONT_SEMI or C.FONT
        accent.Visible = toggled
        if toggled then
            self:AddToArraylist(modName)
        else
            self:RemoveFromArraylist(modName)
        end
        if not silent and onToggle then onToggle(toggled) end
    end

    -- ── EXPAND / COLLAPSE ──
    local function setExpanded(val)
        if not settPanel then return end
        expanded = val
        if expanded then
            Tween(settPanel, { Size = UDim2.new(1,-4,0,settHeight) },           0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Tween(container, { Size = UDim2.new(1,0,0,C.MOD_H+2+settHeight) },  0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            if dots then Tween(dots, { TextColor3 = C.ACCENT }, 0.12) end
        else
            Tween(settPanel, { Size = UDim2.new(1,-4,0,0) },           0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            Tween(container, { Size = UDim2.new(1,0,0,C.MOD_H) },      0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            if dots then Tween(dots, { TextColor3 = C.TEXT_DARK }, 0.12) end
        end
    end

    -- ── Клик-зона ──
    local zone = New("TextButton", {
        Parent                 = row,
        BackgroundTransparency = 1,
        Text                   = "",
        Size                   = UDim2.new(1, 0, 1, 0),
        ZIndex                 = 11,
        AutoButtonColor        = false,
    })

    zone.MouseButton1Click:Connect(function()
        applyToggle(not toggled)
    end)

    zone.MouseButton2Click:Connect(function()
        if #S > 0 then setExpanded(not expanded) end
    end)

    zone.MouseEnter:Connect(function()
        if not toggled then
            Tween(row, { BackgroundColor3 = Color3.fromRGB(28,23,42) }, 0.1)
        end
    end)
    zone.MouseLeave:Connect(function()
        if not toggled then
            Tween(row, { BackgroundColor3 = C.MODULE_OFF }, 0.1)
        end
    end)

    -- Применяем дефолт
    if toggled then
        accent.Visible = true
        lbl.TextColor3 = C.TEXT
        lbl.FontFace   = C.FONT_SEMI
        self:AddToArraylist(modName)
    end

    local obj = {
        Name      = modName,
        Category  = catName,
        Container = container,
        Row       = row,
        Expanded  = function() return expanded end,
        Toggle    = function(v)
            if v ~= nil then applyToggle(v)
            else applyToggle(not toggled) end
        end,
        IsOn = function() return toggled end,
    }

    self.ModData[modName] = obj
    table.insert(cat.Modules, obj)
    return obj
end

-- ================================================================
--  SETTING COMPONENTS
-- ================================================================
function UI:_MakeSetting(parent, s, order)
    local sType = s.type or "toggle"

    -- Возвращает объект с GetHeight(), OnHeightChanged(fn)
    if sType == "toggle"      then return self:_MakeToggle(parent, s, order) end
    if sType == "slider"      then return self:_MakeSlider(parent, s, order) end
    if sType == "dropdown"    then return self:_MakeDropdown(parent, s, order) end
    if sType == "colorpicker" then return self:_MakeColorPicker(parent, s, order) end
    if sType == "keybind"     then return self:_MakeKeybind(parent, s, order) end

    -- Заглушка
    local f = New("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,20), LayoutOrder = order, ZIndex = 9,
    })
    return { GetHeight = function() return 20 end, OnHeightChanged = function() end, Frame = f }
end

-- ── СТРОКА-ШАБЛОН ──
local function MakeRow(parent, order, h)
    h = h or 22
    local f = New("Frame", {
        Parent                 = parent,
        BackgroundColor3       = Color3.fromRGB(18, 14, 28),
        BackgroundTransparency = 0.3,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, h),
        LayoutOrder            = order,
        ZIndex                 = 9,
    })
    Corner(f, UDim.new(0, 4))
    return f
end

local function MakeLbl(parent, text, x, align, dim)
    return New("TextLabel", {
        Parent                 = parent,
        BackgroundTransparency = 1,
        Text                   = text,
        TextColor3             = dim and C.TEXT_DIM or C.TEXT,
        TextSize               = 11,
        FontFace               = C.FONT,
        TextXAlignment         = align or Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        Position               = UDim2.new(0, x or 6, 0, 0),
        Size                   = UDim2.new(0.55, -(x or 6), 1, 0),
        ZIndex                 = 10,
    })
end

-- ── TOGGLE ──
function UI:_MakeToggle(parent, s, order)
    local val  = s.default or false
    local H    = 22
    local f    = MakeRow(parent, order, H)

    MakeLbl(f, s.name or "Toggle", 6, nil, true)

    local sw = New("Frame", {
        Parent                 = f,
        BackgroundColor3       = val and C.ACCENT or C.SLIDER_TRK,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 28, 0, 14),
        Position               = UDim2.new(1, -34, 0.5, 0),
        AnchorPoint            = Vector2.new(0, 0.5),
        ZIndex                 = 10,
    })
    Corner(sw, UDim.new(0, 7))

    local kn = New("Frame", {
        Parent                 = sw,
        BackgroundColor3       = Color3.fromRGB(255,255,255),
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 10, 0, 10),
        Position               = val and UDim2.new(1,-12,0.5,0) or UDim2.new(0,2,0.5,0),
        AnchorPoint            = Vector2.new(0, 0.5),
        ZIndex                 = 11,
    })
    Corner(kn, UDim.new(0, 5))

    local function update()
        Tween(sw, { BackgroundColor3 = val and C.ACCENT or C.SLIDER_TRK }, 0.15)
        Tween(kn, { Position = val and UDim2.new(1,-12,0.5,0) or UDim2.new(0,2,0.5,0) }, 0.15, Enum.EasingStyle.Back)
    end

    local btn = New("TextButton", {
        Parent = f, BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1,0,1,0), ZIndex = 12, AutoButtonColor = false,
    })
    btn.MouseButton1Click:Connect(function()
        val = not val
        update()
        if s.callback then s.callback(val) end
    end)

    return { GetHeight = function() return H end, OnHeightChanged = function() end, Frame = f }
end

-- ── SLIDER ──
function UI:_MakeSlider(parent, s, order)
    local min = s.min or 0
    local max = s.max or 100
    local val = s.default or min
    local dec = s.decimals or 2
    local H   = 34
    local f   = MakeRow(parent, order, H)

    -- Название слева
    New("TextLabel", {
        Parent = f, BackgroundTransparency = 1,
        Text = s.name or "Slider",
        TextColor3 = C.TEXT_DIM, TextSize = 11, FontFace = C.FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 6, 0, 0),
        Size     = UDim2.new(0.5, -6, 0, 16),
        ZIndex   = 10,
    })

    -- Значение справа (рядом с текстом, по правому краю)
    local valLbl = New("TextLabel", {
        Parent = f, BackgroundTransparency = 1,
        Text = string.format("%."..dec.."f", val),
        TextColor3 = C.ACCENT, TextSize = 11, FontFace = C.FONT_SEMI,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size     = UDim2.new(0.5, -6, 0, 16),
        ZIndex   = 10,
    })

    -- Трек
    local track = New("Frame", {
        Parent                 = f,
        BackgroundColor3       = C.SLIDER_TRK,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 6, 0, 20),
        Size                   = UDim2.new(1, -12, 0, 8),
        ZIndex                 = 10,
    })
    Corner(track, UDim.new(0, 4))

    local pct0 = (val - min) / (max - min)

    -- Заливка с градиентом
    local fill = New("Frame", {
        Parent           = track,
        BackgroundColor3 = C.ACCENT,
        BorderSizePixel  = 0,
        Size             = UDim2.new(pct0, 0, 1, 0),
        ZIndex           = 11,
    })
    Corner(fill, UDim.new(0, 4))

    New("UIGradient", {
        Parent      = fill,
        Color       = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.ACCENT),
            ColorSequenceKeypoint.new(1, C.ACCENT2),
        }),
        Rotation    = 90,
    })

    -- Ползунок
    local knob = New("Frame", {
        Parent                 = track,
        BackgroundColor3       = Color3.fromRGB(255,255,255),
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 12, 0, 12),
        Position               = UDim2.new(pct0, 0, 0.5, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        ZIndex                 = 12,
    })
    Corner(knob, UDim.new(0, 6))
    Stroke(knob, C.BORDER, 1, 0.4)

    -- Тень под ползунком
    New("UIStroke", {
        Parent = knob, Color = C.ACCENT,
        Thickness = 2, Transparency = 0.6,
    })

    local dragging = false

    local function apply(inputX)
        local abs = track.AbsolutePosition
        local sz  = track.AbsoluteSize
        local p   = math.clamp((inputX - abs.X) / sz.X, 0, 1)
        val = RoundN(min + p*(max-min), dec)
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        valLbl.Text = string.format("%."..dec.."f", val)
        if s.callback then s.callback(val) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; apply(inp.Position.X)
            Tween(knob, { Size = UDim2.new(0,14,0,14) }, 0.1)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            apply(inp.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            Tween(knob, { Size = UDim2.new(0,12,0,12) }, 0.1)
        end
    end)

    return {
        GetHeight      = function() return H end,
        OnHeightChanged = function() end,
        GetValue       = function() return val end,
        Frame          = f,
    }
end

-- ── DROPDOWN ──
function UI:_MakeDropdown(parent, s, order)
    local opts    = s.options or {}
    local sel     = s.default or (opts[1] or "—")
    local isOpen  = false
    local BASE_H  = 22
    local optH    = #opts * 20 + 6
    local OPEN_H  = BASE_H + optH + 2
    local hChanged = nil

    local f = MakeRow(parent, order, BASE_H)

    MakeLbl(f, s.name or "Dropdown", 6, nil, true)

    local selLbl = New("TextLabel", {
        Parent = f, BackgroundTransparency = 1,
        Text = sel, TextColor3 = C.ACCENT,
        TextSize = 11, FontFace = C.FONT_SEMI,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size     = UDim2.new(0.5, -20, 1, 0),
        ZIndex   = 10,
    })

    local arrow = New("TextLabel", {
        Parent = f, BackgroundTransparency = 1,
        Text = "▾", TextColor3 = C.TEXT_DIM,
        TextSize = 13, FontFace = C.FONT_BOLD,
        Position = UDim2.new(1,-16,0,0),
        Size     = UDim2.new(0,14,1,0),
        ZIndex   = 10,
    })

    -- Список
    local list = New("Frame", {
        Parent                 = f,
        BackgroundColor3       = Color3.fromRGB(12, 9, 20),
        BackgroundTransparency = 0.08,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 1, 2),
        Size                   = UDim2.new(1, 0, 0, 0),
        ZIndex                 = 15,
        ClipsDescendants       = true,
        Visible                = false,
    })
    Corner(list, UDim.new(0, 4))
    Stroke(list, C.BORDER_LIT, 1, 0.6)

    New("UIListLayout", {
        Parent = list, SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,1),
    })
    New("UIPadding", {
        Parent = list,
        PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,3),
        PaddingLeft = UDim.new(0,3), PaddingRight = UDim.new(0,3),
    })

    for oi, opt in ipairs(opts) do
        local ob = New("TextButton", {
            Parent = list,
            BackgroundColor3 = opt==sel and C.ACCENT or Color3.fromRGB(20,16,30),
            BackgroundTransparency = opt==sel and 0.4 or 0.6,
            BorderSizePixel = 0,
            Text = opt, TextColor3 = opt==sel and C.TEXT or C.TEXT_DIM,
            TextSize = 11, FontFace = opt==sel and C.FONT_SEMI or C.FONT,
            Size = UDim2.new(1,0,0,19),
            LayoutOrder = oi, ZIndex = 16, AutoButtonColor = false,
        })
        Corner(ob, UDim.new(0,3))

        ob.MouseEnter:Connect(function()
            if opt ~= sel then Tween(ob, { BackgroundTransparency=0.25 }, 0.08) end
        end)
        ob.MouseLeave:Connect(function()
            if opt ~= sel then Tween(ob, { BackgroundTransparency=0.6 }, 0.08) end
        end)
        ob.MouseButton1Click:Connect(function()
            -- Сброс
            for _, c in pairs(list:GetChildren()) do
                if c:IsA("TextButton") then
                    Tween(c, { BackgroundColor3=Color3.fromRGB(20,16,30), BackgroundTransparency=0.6 }, 0.1)
                    c.TextColor3 = C.TEXT_DIM; c.FontFace = C.FONT
                end
            end
            Tween(ob, { BackgroundColor3=C.ACCENT, BackgroundTransparency=0.4 }, 0.1)
            ob.TextColor3 = C.TEXT; ob.FontFace = C.FONT_SEMI
            sel = opt
            selLbl.Text = opt
            -- Закрыть
            isOpen = false
            Tween(arrow, { Rotation=0 }, 0.12)
            Tween(f,    { Size = UDim2.new(1,0,0,BASE_H) }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            Tween(list, { Size = UDim2.new(1,0,0,0) },      0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.15, function() list.Visible = false end)
            if hChanged then hChanged() end
            if s.callback then s.callback(opt) end
        end)
    end

    local zone = New("TextButton", {
        Parent = f, BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1,0,0,BASE_H), ZIndex = 14, AutoButtonColor = false,
    })
    zone.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            list.Visible = true
            Tween(arrow, { Rotation=180 }, 0.12)
            Tween(f,    { Size = UDim2.new(1,0,0,OPEN_H) }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Tween(list, { Size = UDim2.new(1,0,0,optH) },   0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            Tween(arrow, { Rotation=0 }, 0.12)
            Tween(f,    { Size = UDim2.new(1,0,0,BASE_H) }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            Tween(list, { Size = UDim2.new(1,0,0,0) },      0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.13, function() list.Visible = false end)
        end
        if hChanged then hChanged() end
    end)

    return {
        GetHeight = function()
            return isOpen and OPEN_H or BASE_H
        end,
        OnHeightChanged = function(fn) hChanged = fn end,
        GetValue = function() return sel end,
        Frame = f,
    }
end

-- ── COLOR PICKER ──
function UI:_MakeColorPicker(parent, s, order)
    local col     = s.default or Color3.fromRGB(99, 102, 241)
    local r,g,b   = col.R, col.G, col.B
    local BASE_H  = 22
    local POP_H   = 72
    local OPEN_H  = BASE_H + POP_H + 2
    local isOpen  = false
    local hChanged = nil

    local f = MakeRow(parent, order, BASE_H)
    MakeLbl(f, s.name or "Color", 6, nil, true)

    -- Превью
    local prev = New("Frame", {
        Parent = f, BackgroundColor3 = col,
        BorderSizePixel = 0,
        Size = UDim2.new(0,16,0,16),
        Position = UDim2.new(1,-22,0.5,0), AnchorPoint = Vector2.new(0,0.5),
        ZIndex = 10,
    })
    Corner(prev, UDim.new(0,4))
    Stroke(prev, C.BORDER_LIT, 1, 0.3)

    local arw = New("TextLabel", {
        Parent = f, BackgroundTransparency = 1,
        Text = "▾", TextColor3 = C.TEXT_DARK,
        TextSize = 12, FontFace = C.FONT_BOLD,
        Position = UDim2.new(1,-36,0,0), Size = UDim2.new(0,12,1,0), ZIndex = 10,
    })

    -- Popup с RGB слайдерами
    local popup = New("Frame", {
        Parent = f,
        BackgroundColor3 = Color3.fromRGB(12,9,19),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.new(0,0,1,2),
        Size = UDim2.new(1,0,0,0),
        ZIndex = 15, Visible = false, ClipsDescendants = true,
    })
    Corner(popup, UDim.new(0,4))
    Stroke(popup, C.BORDER_LIT, 1, 0.5)

    New("UIPadding", {
        Parent = popup,
        PaddingTop=UDim.new(0,5), PaddingBottom=UDim.new(0,5),
        PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,5),
    })
    local popLayout = New("UIListLayout", {
        Parent = popup, SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,4),
    })

    local function upd()
        local c = Color3.new(r,g,b)
        prev.BackgroundColor3 = c
        col = c
        if s.callback then s.callback(c) end
    end

    -- RGB бар
    local function mkBar(lbl, initV, setter, barCol, ord)
        local rw = New("Frame", {
            Parent = popup, BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,16), LayoutOrder = ord, ZIndex = 16,
        })
        New("TextLabel", {
            Parent = rw, BackgroundTransparency = 1,
            Text = lbl, TextColor3 = C.TEXT_DIM, TextSize = 10, FontFace = C.FONT_BOLD,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0,10,1,0), ZIndex = 17,
        })
        local tr = New("Frame", {
            Parent = rw, BackgroundColor3 = barCol,
            BackgroundTransparency = 0.65,
            BorderSizePixel = 0,
            Position = UDim2.new(0,14,0.5,0), AnchorPoint = Vector2.new(0,0.5),
            Size = UDim2.new(1,-14,0,6), ZIndex = 16,
        })
        Corner(tr, UDim.new(0,3))
        -- Заливка
        local fl = New("Frame", {
            Parent = tr, BackgroundColor3 = barCol,
            BorderSizePixel = 0,
            Size = UDim2.new(initV,0,1,0), ZIndex = 17,
        })
        Corner(fl, UDim.new(0,3))
        local kn = New("Frame", {
            Parent = tr, BackgroundColor3 = Color3.fromRGB(255,255,255),
            BorderSizePixel = 0,
            Size = UDim2.new(0,10,0,10),
            Position = UDim2.new(initV,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5),
            ZIndex = 18,
        })
        Corner(kn, UDim.new(0,5))
        local drag = false
        local function set(x)
            local p = math.clamp((x - tr.AbsolutePosition.X)/tr.AbsoluteSize.X, 0, 1)
            fl.Size = UDim2.new(p,0,1,0)
            kn.Position = UDim2.new(p,0,0.5,0)
            setter(p)
            upd()
        end
        tr.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = true; set(inp.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then set(inp.Position.X) end
        end)
        UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
    end

    mkBar("R", r, function(v) r=v end, Color3.fromRGB(220,60,60),  1)
    mkBar("G", g, function(v) g=v end, Color3.fromRGB(60,200,80),  2)
    mkBar("B", b, function(v) b=v end, Color3.fromRGB(60,100,220), 3)

    local zone = New("TextButton", {
        Parent = f, BackgroundTransparency=1, Text="",
        Size = UDim2.new(1,0,0,BASE_H), ZIndex=14, AutoButtonColor=false,
    })
    zone.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            popup.Visible = true
            Tween(arw,   { Rotation=180 }, 0.12)
            Tween(f,     { Size=UDim2.new(1,0,0,OPEN_H) }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Tween(popup, { Size=UDim2.new(1,0,0,POP_H)  }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            Tween(arw,   { Rotation=0 }, 0.12)
            Tween(f,     { Size=UDim2.new(1,0,0,BASE_H) }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            Tween(popup, { Size=UDim2.new(1,0,0,0) },      0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.13, function() popup.Visible = false end)
        end
        if hChanged then hChanged() end
    end)

    return {
        GetHeight       = function() return isOpen and OPEN_H or BASE_H end,
        OnHeightChanged = function(fn) hChanged = fn end,
        GetValue        = function() return col end,
        Frame           = f,
    }
end

-- ── KEYBIND ──
function UI:_MakeKeybind(parent, s, order)
    local key     = s.default or Enum.KeyCode.Unknown
    local waiting = false
    local H       = 22
    local f       = MakeRow(parent, order, H)

    MakeLbl(f, s.name or "Keybind", 6, nil, true)

    local keyBtn = New("TextButton", {
        Parent = f, BackgroundColor3 = C.SLIDER_TRK,
        BackgroundTransparency = 0.3, BorderSizePixel = 0,
        Text = key ~= Enum.KeyCode.Unknown and key.Name or "None",
        TextColor3 = C.ACCENT, TextSize = 10, FontFace = C.FONT_SEMI,
        Size = UDim2.new(0,48,0,16),
        Position = UDim2.new(1,-54,0.5,0), AnchorPoint = Vector2.new(0,0.5),
        ZIndex = 10, AutoButtonColor = false,
    })
    Corner(keyBtn, UDim.new(0,4))

    keyBtn.MouseButton1Click:Connect(function()
        waiting = true
        keyBtn.Text = "..."
        Tween(keyBtn, { BackgroundColor3 = C.ACCENT }, 0.1)
    end)

    UIS.InputBegan:Connect(function(inp)
        if waiting and inp.UserInputType == Enum.UserInputType.Keyboard then
            key = inp.KeyCode
            keyBtn.Text = inp.KeyCode.Name
            Tween(keyBtn, { BackgroundColor3 = C.SLIDER_TRK }, 0.1)
            waiting = false
            if s.callback then s.callback(inp.KeyCode) end
        end
    end)

    return {
        GetHeight       = function() return H end,
        OnHeightChanged = function() end,
        GetValue        = function() return key end,
        Frame           = f,
    }
end

-- ================================================================
--  WATERMARK  (перетаскиваемый)
-- ================================================================
function UI:_MakeWatermark()
    -- Фрейм ватермарки
    local wm = New("Frame", {
        Parent                 = self.Root,
        Name                   = "Watermark",
        BackgroundColor3       = C.PANEL,
        BackgroundTransparency = 0.1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 14, 0, 14),
        Size                   = UDim2.new(0, 182, 0, 32),
        ZIndex                 = 60,
        ClipsDescendants       = false,
    })
    Corner(wm)
    Stroke(wm, C.BORDER, 1, 0.5)

    -- Левый акцент-блок (название + иконка)
    local left = New("Frame", {
        Parent                 = wm,
        BackgroundColor3       = C.ACCENT,
        BackgroundTransparency = 0.2,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 74, 1, 0),
        ZIndex                 = 61,
    })
    Corner(left)

    -- Иконка (корона, заменимо)
    New("TextLabel", {
        Parent = left, BackgroundTransparency = 1,
        Text = "✦", TextColor3 = Color3.fromRGB(255,255,255),
        TextSize = 13, FontFace = C.FONT_BOLD,
        Position = UDim2.new(0, 7, 0, 0), Size = UDim2.new(0,16,1,0),
        ZIndex = 62,
    })

    -- «Alpha»
    New("TextLabel", {
        Parent = left, BackgroundTransparency = 1,
        Text = "Alpha", TextColor3 = Color3.fromRGB(255,255,255),
        TextSize = 12, FontFace = C.FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0,25,0,0), Size = UDim2.new(1,-28,1,0),
        ZIndex = 62,
    })

    -- Разделитель
    New("Frame", {
        Parent = wm, BackgroundColor3 = C.BORDER,
        BackgroundTransparency = 0.4, BorderSizePixel = 0,
        Position = UDim2.new(0,74,0,6), Size = UDim2.new(0,1,1,-12), ZIndex = 61,
    })

    -- Никнейм
    New("TextLabel", {
        Parent = wm, BackgroundTransparency = 1,
        Text = LP.Name,
        TextColor3 = C.TEXT, TextSize = 11, FontFace = C.FONT_SEMI,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0,80,0,0), Size = UDim2.new(1,-84,1,0),
        ZIndex = 62,
    })

    -- «20 Ticks» — отдельная плашка под ватермаркой
    local ticks = New("Frame", {
        Parent = self.Root, Name = "Ticks",
        BackgroundColor3 = C.PANEL, BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Position = UDim2.new(0,14,0,50),
        Size = UDim2.new(0,68,0,20), ZIndex = 60,
    })
    Corner(ticks, UDim.new(0,6))
    Stroke(ticks, C.BORDER, 1, 0.55)

    self.TicksText = New("TextLabel", {
        Parent = ticks, BackgroundTransparency = 1,
        Text = "20 Ticks",
        TextColor3 = C.TEXT_DIM, TextSize = 10, FontFace = C.FONT,
        Size = UDim2.new(1,0,1,0), ZIndex = 61,
    })

    -- Делаем перетаскиваемой — ватермарка тащит саму себя + тики
    local wdrag, wdx, wdy = false, 0, 0
    wm.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            wdrag = true
            wdx = inp.Position.X - wm.AbsolutePosition.X
            wdy = inp.Position.Y - wm.AbsolutePosition.Y
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if wdrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local nx = inp.Position.X - wdx
            local ny = inp.Position.Y - wdy
            wm.Position    = UDim2.new(0, nx, 0, ny)
            ticks.Position = UDim2.new(0, nx, 0, ny + 36)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then wdrag = false end
    end)

    self.WM    = wm
    self.Ticks = ticks

    -- Обновление тиков (FPS approximation)
    local fc, lt = 0, tick()
    RunService.Heartbeat:Connect(function()
        fc = fc + 1
        if tick()-lt >= 1 then
            local fps = math.floor(fc/(tick()-lt))
            local ping = math.floor(LP:GetNetworkPing()*1000)
            self.TicksText.Text = fps.." FPS  "..ping.."ms"
            ticks.Size = UDim2.new(0, 86, 0, 20)
            fc, lt = 0, tick()
        end
    end)
end

-- ================================================================
--  KEYBIND HUD  (перетаскиваемый, показывает активные модули)
-- ================================================================
function UI:_MakeKeyBindHUD()
    local hub = New("Frame", {
        Parent = self.Root, Name = "KeyBindHUD",
        BackgroundTransparency = 1,
        Position = UDim2.new(1,-160,0,14),
        Size = UDim2.new(0,148,0,26),
        ZIndex = 60,
    })

    -- Заголовок «KeyBinds»
    local hdr = New("Frame", {
        Parent = hub,
        BackgroundColor3 = C.PANEL, BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,24), ZIndex = 61,
    })
    Corner(hdr)
    Stroke(hdr, C.BORDER, 1, 0.5)

    -- Иконка
    New("TextLabel", {
        Parent = hdr, BackgroundTransparency = 1,
        Text = "⌨", TextColor3 = C.ACCENT, TextSize = 12, FontFace = C.FONT_BOLD,
        Position = UDim2.new(0,6,0,0), Size = UDim2.new(0,16,1,0), ZIndex = 62,
    })
    New("TextLabel", {
        Parent = hdr, BackgroundTransparency = 1,
        Text = "KeyBinds", TextColor3 = C.TEXT, TextSize = 11, FontFace = C.FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0,24,0,0), Size = UDim2.new(1,-26,1,0), ZIndex = 62,
    })

    -- Контейнер строк
    local rows = New("Frame", {
        Parent = hub, BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,27),
        Size = UDim2.new(1,0,0,0), ZIndex = 61,
    })
    New("UIListLayout", {
        Parent = rows, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,2),
    })

    self.KBHub      = hub
    self.KBRows     = rows
    self.KBRowCache = {}

    -- Перетаскивание
    MakeDraggable(hub, hdr)

    -- Обновляем строки каждые 0.5 сек
    RunService.Heartbeat:Connect(function()
        -- Очищаем
        for _, c in pairs(rows:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        local y = 0
        local idx = 0
        for modName, _ in pairs(self.ActiveModules) do
            local mdata = self.ModData[modName]
            local bind  = (mdata and mdata.Bind) or "—"

            local row = New("Frame", {
                Parent = rows,
                BackgroundColor3 = C.PANEL, BackgroundTransparency = 0.12,
                BorderSizePixel = 0,
                Size = UDim2.new(1,0,0,20),
                LayoutOrder = idx, ZIndex = 62,
            })
            Corner(row, UDim.new(0,5))

            -- Разделитель
            New("Frame", {
                Parent = row, BackgroundColor3 = C.BORDER,
                BackgroundTransparency = 0.4, BorderSizePixel = 0,
                Position = UDim2.new(0,0,0.5,0), AnchorPoint = Vector2.new(0,0.5),
                Size = UDim2.new(0,2,0.7,0), ZIndex = 63,
            })

            New("TextLabel", {
                Parent = row, BackgroundTransparency = 1,
                Text = modName, TextColor3 = C.TEXT, TextSize = 10, FontFace = C.FONT,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0,6,0,0), Size = UDim2.new(0.7,-6,1,0),
                ZIndex = 63,
            })

            New("TextLabel", {
                Parent = row, BackgroundTransparency = 1,
                Text = bind, TextColor3 = Color3.fromRGB(235,85,105),
                TextSize = 10, FontFace = C.FONT_SEMI,
                TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2.new(0.7,0,0,0), Size = UDim2.new(0.3,-4,1,0),
                ZIndex = 63,
            })

            idx = idx + 1
            y = y + 22
        end

        hub.Size = UDim2.new(0,148, 0, 26 + y)
    end)
end

-- ================================================================
--  ПОИСК
-- ================================================================
function UI:_MakeSearchBar()
    local sb = New("Frame", {
        Parent = self.Root, Name = "Search",
        BackgroundColor3 = C.PANEL, BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5,0,1,-48), AnchorPoint = Vector2.new(0.5,1),
        Size = UDim2.new(0,260,0,30),
        ZIndex = 60, Visible = false,
    })
    Corner(sb)
    Stroke(sb, C.BORDER, 1, 0.5)

    New("TextLabel", {
        Parent = sb, BackgroundTransparency = 1,
        Text = "🔍", TextSize = 12, FontFace = C.FONT,
        Position = UDim2.new(0,8,0,0), Size = UDim2.new(0,18,1,0), ZIndex = 61,
    })

    self.SearchInput = New("TextBox", {
        Parent = sb, BackgroundTransparency = 1,
        Text = "", PlaceholderText = "Поиск...",
        PlaceholderColor3 = C.TEXT_DARK,
        TextColor3 = C.TEXT, TextSize = 12, FontFace = C.FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0,28,0,0), Size = UDim2.new(1,-34,1,0),
        ZIndex = 61, ClearTextOnFocus = false,
    })

    self.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local q = self.SearchInput.Text:lower()
        for _, cat in pairs(self.CatData) do
            for _, m in pairs(cat.Modules) do
                m.Container.Visible = q == "" or m.Name:lower():find(q, 1, true) ~= nil
            end
        end
    end)

    self.SearchBar = sb
    MakeDraggable(sb)
end

-- ================================================================
--  CONFIG MANAGER
-- ================================================================
function UI:_MakeConfigMgr()
    local cfg = New("Frame", {
        Parent = self.Root, Name = "Config",
        BackgroundColor3 = C.PANEL, BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.new(1,-14,1,-14), AnchorPoint = Vector2.new(1,1),
        Size = UDim2.new(0,172,0,172),
        ZIndex = 60, Visible = false, ClipsDescendants = true,
    })
    Corner(cfg)
    Stroke(cfg, C.BORDER, 1, 0.45)

    -- Шапка
    local hdr = New("Frame", {
        Parent = cfg, BackgroundColor3 = C.ACCENT,
        BackgroundTransparency = 0.8, BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,28), ZIndex = 61,
    })
    Corner(hdr)
    New("TextLabel", {
        Parent = hdr, BackgroundTransparency = 1,
        Text = "Config Manager", TextColor3 = C.TEXT,
        TextSize = 11, FontFace = C.FONT_BOLD,
        Size = UDim2.new(1,0,1,0), ZIndex = 62,
    })

    -- Поле ввода
    local inp = New("Frame", {
        Parent = cfg, BackgroundColor3 = Color3.fromRGB(18,14,28),
        BackgroundTransparency = 0.3, BorderSizePixel = 0,
        Position = UDim2.new(0,6,0,34), Size = UDim2.new(1,-12,0,24), ZIndex = 61,
    })
    Corner(inp, C.CORNER_SM)
    New("TextLabel", {
        Parent = inp, BackgroundTransparency = 1,
        Text = "Name", TextColor3 = C.TEXT_DIM, TextSize = 10, FontFace = C.FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0,6,0,0), Size = UDim2.new(0,38,1,0), ZIndex = 62,
    })
    New("Frame", {
        Parent = inp, BackgroundColor3 = C.BORDER,
        BackgroundTransparency = 0.4, BorderSizePixel = 0,
        Position = UDim2.new(0,44,0.15,0), Size = UDim2.new(0,1,0.7,0), ZIndex = 62,
    })
    local cfgIn = New("TextBox", {
        Parent = inp, BackgroundTransparency = 1,
        Text = "", PlaceholderText = "my_config",
        PlaceholderColor3 = C.TEXT_DARK,
        TextColor3 = C.TEXT, TextSize = 11, FontFace = C.FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0,48,0,0), Size = UDim2.new(1,-52,1,0),
        ZIndex = 62, ClearTextOnFocus = false,
    })

    -- Кнопки
    local function mkBtn(txt, col, y, cb)
        local b = New("TextButton", {
            Parent = cfg, BackgroundColor3 = col,
            BackgroundTransparency = 0.4, BorderSizePixel = 0,
            Text = txt, TextColor3 = C.TEXT, TextSize = 11, FontFace = C.FONT_SEMI,
            Position = UDim2.new(0,6,0,y), Size = UDim2.new(1,-12,0,20),
            ZIndex = 61, AutoButtonColor = false,
        })
        Corner(b, C.CORNER_SM)
        b.MouseEnter:Connect(function() Tween(b,{BackgroundTransparency=0.15},0.08) end)
        b.MouseLeave:Connect(function() Tween(b,{BackgroundTransparency=0.4},0.08) end)
        b.MouseButton1Click:Connect(function()
            local oc = b.BackgroundColor3
            Tween(b,{BackgroundColor3=C.ACCENT},0.07)
            task.delay(0.14,function() Tween(b,{BackgroundColor3=oc},0.12) end)
            if cb then cb(cfgIn.Text) end
        end)
    end
    mkBtn("Создать",   C.SUCCESS, 64,  function(n) if n~="" then print("[Cfg] +",n) end end)
    mkBtn("Сохранить", C.ACCENT,  88,  function() print("[Cfg] Save") end)
    mkBtn("Загрузить", Color3.fromRGB(50,45,80), 112, function() print("[Cfg] Load") end)
    mkBtn("Удалить",   C.DANGER,  136, function() print("[Cfg] Del") end)

    self.CfgFrame = cfg
    MakeDraggable(cfg, hdr)
end

-- ================================================================
--  ARRAYLIST
-- ================================================================
function UI:_MakeArraylist()
    self.AL = New("Frame", {
        Parent = self.Root, Name = "Arraylist",
        BackgroundTransparency = 1,
        Position = UDim2.new(0,14,1,-14), AnchorPoint = Vector2.new(0,1),
        Size = UDim2.new(0,160,0,400), ZIndex = 60,
    })
    New("UIListLayout", {
        Parent = self.AL, SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,2),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    })
    MakeDraggable(self.AL)
end

function UI:AddToArraylist(name)
    if self.ActiveModules[name] then return end
    local e = New("Frame", {
        Parent = self.AL, Name = name,
        BackgroundColor3 = C.PANEL, BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Size = UDim2.new(0,0,0,18), ZIndex = 61, ClipsDescendants = true,
    })
    Corner(e, UDim.new(0,5))

    New("Frame", {
        Parent = e, BackgroundColor3 = C.ACCENT,
        BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,3), Size = UDim2.new(0,2,1,-6), ZIndex = 62,
    })
    New("TextLabel", {
        Parent = e, BackgroundTransparency = 1,
        Text = name, TextColor3 = C.TEXT, TextSize = 10, FontFace = C.FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0,7,0,0), Size = UDim2.new(1,-9,1,0), ZIndex = 62,
    })
    Tween(e, { Size = UDim2.new(0,120,0,18) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    self.ActiveModules[name] = e
end

function UI:RemoveFromArraylist(name)
    local e = self.ActiveModules[name]
    if not e then return end
    Tween(e, { Size=UDim2.new(0,0,0,18) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.delay(0.13, function() e:Destroy(); self.ActiveModules[name]=nil end)
end

-- ================================================================
--  УВЕДОМЛЕНИЯ
-- ================================================================
function UI:_MakeNotifications()
    self.NC = New("Frame", {
        Parent = self.Root, Name = "Notifs",
        BackgroundTransparency = 1,
        Position = UDim2.new(1,-14,0.5,0), AnchorPoint = Vector2.new(1,0.5),
        Size = UDim2.new(0,240,0,500), ZIndex = 200,
    })
    New("UIListLayout", {
        Parent = self.NC, SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,5),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    })
end

function UI:Notify(title, msg, dur, nt)
    dur = dur or 3
    local ac = C.ACCENT
    if nt=="success" then ac=C.SUCCESS elseif nt=="error" then ac=C.DANGER elseif nt=="warning" then ac=C.WARNING end

    local nf = New("Frame", {
        Parent = self.NC, Name="N",
        BackgroundColor3=C.PANEL, BackgroundTransparency=0.1,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,0), ZIndex=201, ClipsDescendants=true,
    })
    Corner(nf)
    Stroke(nf, C.BORDER, 1, 0.5)

    local tl = New("Frame", {
        Parent=nf, BackgroundColor3=ac, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,2), ZIndex=202,
    })
    Corner(tl, UDim.new(0,2))

    New("TextLabel", {
        Parent=nf, BackgroundTransparency=1,
        Text=title, TextColor3=ac, TextSize=11, FontFace=C.FONT_BOLD,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.new(0,8,0,6), Size=UDim2.new(1,-16,0,14), ZIndex=202,
    })
    New("TextLabel", {
        Parent=nf, BackgroundTransparency=1,
        Text=msg, TextColor3=C.TEXT_DIM, TextSize=10, FontFace=C.FONT,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        Position=UDim2.new(0,8,0,22), Size=UDim2.new(1,-16,0,18), ZIndex=202,
    })

    local pb = New("Frame", {
        Parent=nf, BackgroundColor3=ac, BackgroundTransparency=0.5,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,2),
        Position=UDim2.new(0,0,1,-2), ZIndex=202,
    })

    Tween(nf, { Size=UDim2.new(1,0,0,52) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(0.2, function() Tween(pb, { Size=UDim2.new(0,0,0,2) }, dur, Enum.EasingStyle.Linear) end)
    task.delay(dur+0.2, function()
        Tween(nf, { Size=UDim2.new(1,0,0,0), BackgroundTransparency=1 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.2, function() nf:Destroy() end)
    end)
end

-- ================================================================
--  ОТКРЫТИЕ / ЗАКРЫТИЕ
-- ================================================================
function UI:_ShowAll()
    if self.Animating then return end
    self.Animating = true
    self.Visible   = true

    self.Dim.Visible = true
    self.Dim.BackgroundTransparency = 1
    Tween(self.Dim, { BackgroundTransparency=0.6 }, 0.22)

    self.Menu.Visible = true
    self.Menu.Position = UDim2.new(
        0.5, -(#CATS*C.COL_W+(#CATS-1)*C.COL_GAP)/2,
        0.5, -(C.COL_H)/2
    )

    -- Панели появляются по очереди
    for i, cat in ipairs(CATS) do
        local d = self.CatData[cat.Name]
        if d then
            d.Panel.BackgroundTransparency = 1
            task.delay((i-1)*0.035, function()
                Tween(d.Panel, { BackgroundTransparency=0.08 }, 0.22)
            end)
        end
    end

    self.SearchBar.Visible  = true
    self.CfgFrame.Visible   = true
    self.SearchBar.Position = UDim2.new(0.5,0,1,60)
    Tween(self.SearchBar, { Position=UDim2.new(0.5,0,1,-48) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    self.CfgFrame.Size = UDim2.new(0,0,0,0)
    Tween(self.CfgFrame, { Size=UDim2.new(0,172,0,172) }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    self:UpdatePlayerList()
    task.delay(0.3, function() self.Animating=false end)
    task.delay(0.5, function() self:Notify("Alpha","Меню открыто",2,"info") end)
end

function UI:UpdatePlayerList()
    -- Используем KeyBindHUD позицию как правый верхний
    -- (ничего нового не создаём — уже есть KBHub)
end

function UI:_HideAll()
    if self.Animating then return end
    self.Animating = true
    self.Visible   = false

    Tween(self.Dim, { BackgroundTransparency=1 }, 0.18)
    for _, cat in ipairs(CATS) do
        local d = self.CatData[cat.Name]
        if d then Tween(d.Panel, { BackgroundTransparency=1 }, 0.14) end
    end
    Tween(self.SearchBar, { Position=UDim2.new(0.5,0,1,60) }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    Tween(self.CfgFrame,  { Size=UDim2.new(0,0,0,0) },         0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    task.delay(0.22, function()
        self.Dim.Visible        = false
        self.Menu.Visible       = false
        self.SearchBar.Visible  = false
        self.CfgFrame.Visible   = false
        self.Animating          = false
    end)
end

-- ================================================================
--  INPUT
-- ================================================================
function UI:_SetupInput()
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == self.ToggleKey then
            if self.Visible then self:_HideAll() else self:_ShowAll() end
        end
    end)
end

-- ================================================================
return UI
