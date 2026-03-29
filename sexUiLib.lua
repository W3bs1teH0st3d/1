-- ============================================================
--  GLASS UI v4
--  ClickGUI: 5 колонок, ПКМ = настройки, СКМ = бинд
--  Toggle: Right Shift
-- ============================================================

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TS           = game:GetService("TweenService")
local RS           = game:GetService("RunService")
local LP           = Players.LocalPlayer

-- ================================================================
--  ПАЛИТРА
-- ================================================================
local P = {
    BG          = Color3.fromRGB(8, 6, 14),
    PANEL       = Color3.fromRGB(14, 11, 22),
    HEADER      = Color3.fromRGB(18, 14, 28),
    MOD_OFF     = Color3.fromRGB(20, 16, 30),
    MOD_HOVER   = Color3.fromRGB(26, 21, 38),
    MOD_ON      = Color3.fromRGB(32, 22, 52),
    ACCENT      = Color3.fromRGB(99, 102, 241),
    ACCENT2     = Color3.fromRGB(139, 92, 246),
    TEXT        = Color3.fromRGB(225, 225, 235),
    TEXT_DIM    = Color3.fromRGB(120, 115, 145),
    TEXT_DARK   = Color3.fromRGB(70, 65, 95),
    BORDER      = Color3.fromRGB(40, 34, 60),
    BORDER_L    = Color3.fromRGB(60, 52, 90),
    SLIDER_TRK  = Color3.fromRGB(28, 22, 42),
    TOGGLE_OFF  = Color3.fromRGB(40, 34, 58),
    FONT        = Font.new("rbxasset://fonts/families/GothamSSm.json"),
    FONT_SEMI   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
    FONT_BOLD   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
}

-- Размеры
local COL_W    = 154
local COL_GAP  = 5
local COL_H    = 420
local MOD_H    = 22
local HDR_H    = 28
local ANIM     = 0.18
local CORNER   = UDim.new(0, 8)
local CORNER_S = UDim.new(0, 5)
local CORNER_XS= UDim.new(0, 4)

local CATS = {"Combat","Movement","Visuals","Player","Misc"}

-- ================================================================
--  LIBRARY TABLE
-- ================================================================
local UI = {}
UI.__index    = UI
UI.Visible    = false
UI.Animating  = false
UI.CatData    = {}
UI.ModData    = {}
UI.ActiveMods = {}
UI.ToggleKey  = Enum.KeyCode.RightShift
UI.BindListeners = {}

-- ================================================================
--  HELPERS
-- ================================================================
local function N(t, p)
    local o = Instance.new(t)
    for k,v in pairs(p) do if k~="Parent" then o[k]=v end end
    if p.Parent then o.Parent=p.Parent end
    return o
end
local function Cn(o,r) N("UICorner",{CornerRadius=r or CORNER,Parent=o}) return o end
local function St(o,c,t,tr) N("UIStroke",{Color=c or P.BORDER,Thickness=t or 1,Transparency=tr or 0,Parent=o}) return o end
local function Tw(o,p,d,s,dr)
    local tw=TS:Create(o,TweenInfo.new(d or ANIM,s or Enum.EasingStyle.Quart,dr or Enum.EasingDirection.Out),p)
    tw:Play() return tw
end
local function Rn(n,d) local m=10^(d or 2) return math.floor(n*m+0.5)/m end

local function Drag(frame, handle)
    handle = handle or frame
    local drag,dx,dy=false,0,0
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; dx=i.Position.X-frame.AbsolutePosition.X; dy=i.Position.Y-frame.AbsolutePosition.Y
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            frame.Position=UDim2.new(0,i.Position.X-dx,0,i.Position.Y-dy)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ================================================================
--  INIT
-- ================================================================
function UI:Init()
    self.Gui = N("ScreenGui",{
        Name="GlassUI4",Parent=LP:WaitForChild("PlayerGui"),
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn=false,IgnoreGuiInset=true,
    })
    self.Root = N("Frame",{
        Parent=self.Gui,BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0),ZIndex=1,
    })
    self.Dim = N("Frame",{
        Parent=self.Root,BackgroundColor3=Color3.new(0,0,0),
        BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
        ZIndex=2,Visible=false,
    })

    local totalW = #CATS*COL_W+(#CATS-1)*COL_GAP
    self.Menu = N("Frame",{
        Parent=self.Root,BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),
        Size=UDim2.new(0,totalW,0,COL_H),
        ZIndex=3,Visible=false,
    })

    self:_Columns()
    self:_Watermark()
    self:_BindHUD()
    self:_Search()
    self:_Arraylist()
    self:_Input()

    return self
end

-- ================================================================
--  COLUMNS
-- ================================================================
function UI:_Columns()
    for i, cat in ipairs(CATS) do
        local x = (i-1)*(COL_W+COL_GAP)

        local col = N("Frame",{
            Parent=self.Menu,Name=cat,
            BackgroundColor3=P.PANEL,BackgroundTransparency=0.06,
            BorderSizePixel=0,
            Position=UDim2.new(0,x,0,0),Size=UDim2.new(0,COL_W,0,COL_H),
            ZIndex=5,ClipsDescendants=true,
        })
        Cn(col); St(col,P.BORDER,1,0.4)

        -- Заголовок = часть списка (не отдельная шапка)
        local hdr = N("Frame",{
            Parent=col,BackgroundColor3=P.HEADER,
            BackgroundTransparency=0.0,BorderSizePixel=0,
            Size=UDim2.new(1,0,0,HDR_H),ZIndex=6,
        })
        Cn(hdr)

        -- Градиент на шапке
        N("UIGradient",{
            Parent=hdr,
            Color=ColorSequence.new({
                ColorSequenceKeypoint.new(0,P.ACCENT),
                ColorSequenceKeypoint.new(1,P.HEADER),
            }),
            Transparency=NumberSequence.new({
                NumberSequenceKeypoint.new(0,0.85),
                NumberSequenceKeypoint.new(1,0.95),
            }),
            Rotation=90,
        })

        N("TextLabel",{
            Parent=hdr,BackgroundTransparency=1,
            Text=cat,TextColor3=P.TEXT,TextSize=12,FontFace=P.FONT_BOLD,
            Size=UDim2.new(1,0,1,0),ZIndex=7,
        })

        -- Scroll
        local scroll = N("ScrollingFrame",{
            Parent=col,BackgroundTransparency=1,
            BorderSizePixel=0,Position=UDim2.new(0,0,0,HDR_H),
            Size=UDim2.new(1,0,1,-HDR_H),ZIndex=6,
            ScrollBarThickness=2,
            ScrollBarImageColor3=P.ACCENT,
            ScrollBarImageTransparency=0.55,
            CanvasSize=UDim2.new(0,0,0,0),
            ScrollingDirection=Enum.ScrollingDirection.Y,
            ElasticBehavior=Enum.ElasticBehavior.Never,
            TopImage="rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",
        })

        local lay = N("UIListLayout",{
            Parent=scroll,SortOrder=Enum.SortOrder.LayoutOrder,
            Padding=UDim.new(0,2),
        })
        N("UIPadding",{
            Parent=scroll,
            PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,4),
            PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),
        })

        lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+8)
        end)

        self.CatData[cat]={Panel=col,Scroll=scroll,Layout=lay,Modules={}}
    end
end

-- ================================================================
--  ADD MODULE
-- ================================================================
function UI:AddModule(catName, modName, opts)
    opts = opts or {}
    local cat = self.CatData[catName]
    if not cat then warn("Cat?",catName) return end

    local S        = opts.settings or {}
    local toggled  = opts.default or false
    local onToggle = opts.onToggle
    local order    = #cat.Modules + 1
    local expanded = false
    local bindKey  = nil
    local bindMode = "toggle"  -- "toggle" | "hold"
    local binding  = false
    local settComps = {}

    -- ── КОНТЕЙНЕР ──
    local box = N("Frame",{
        Parent=cat.Scroll,Name="M_"..modName,
        BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,MOD_H),LayoutOrder=order,
        ZIndex=7,ClipsDescendants=false,
    })

    -- ── СТРОКА ──
    local row = N("Frame",{
        Parent=box,BackgroundColor3=toggled and P.MOD_ON or P.MOD_OFF,
        BackgroundTransparency=0.1,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,MOD_H),ZIndex=8,
    })
    Cn(row,CORNER_S); St(row,P.BORDER,1,0.6)

    -- Название
    local lbl = N("TextLabel",{
        Parent=row,BackgroundTransparency=1,
        Text=modName,
        TextColor3=toggled and P.TEXT or P.TEXT_DIM,
        TextSize=11,FontFace=toggled and P.FONT_SEMI or P.FONT,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Position=UDim2.new(0,7,0,0),
        Size=UDim2.new(1,-26,1,0),ZIndex=9,
    })

    -- Бинд-лейбл (справа, компактный)
    local bindLbl = N("TextLabel",{
        Parent=row,BackgroundTransparency=1,
        Text="",TextColor3=P.ACCENT,
        TextSize=9,FontFace=P.FONT_SEMI,
        TextXAlignment=Enum.TextXAlignment.Right,
        Position=UDim2.new(1,-6,0,0),
        AnchorPoint=Vector2.new(1,0),
        Size=UDim2.new(0,40,1,0),ZIndex=9,
    })

    -- Три точки (если есть настройки)
    local dots
    if #S > 0 then
        dots = N("TextLabel",{
            Parent=row,BackgroundTransparency=1,
            Text="···",TextColor3=P.TEXT_DARK,
            TextSize=13,FontFace=P.FONT_BOLD,
            Position=UDim2.new(1,-18,0,-1),
            Size=UDim2.new(0,14,1,0),ZIndex=9,
        })
    end

    -- Обновить бинд-текст
    local function updBind()
        if bindKey then
            local m = bindMode == "hold" and "H" or "T"
            bindLbl.Text = "["..bindKey.Name.."]"
            if dots then dots.Position = UDim2.new(1,-18-bindLbl.TextBounds.X-4,0,-1) end
        else
            bindLbl.Text = ""
        end
    end

    -- ── НАСТРОЙКИ ──
    local settFrame
    local settHeight = 0

    if #S > 0 then
        settFrame = N("Frame",{
            Parent=box,Name="Sett",
            BackgroundColor3=Color3.fromRGB(12,9,19),
            BackgroundTransparency=0.06,BorderSizePixel=0,
            Position=UDim2.new(0,1,0,MOD_H+1),
            Size=UDim2.new(1,-2,0,0),ZIndex=7,
            ClipsDescendants=true,
        })
        Cn(settFrame,CORNER_XS); St(settFrame,P.BORDER,1,0.55)

        local sLay = N("UIListLayout",{
            Parent=settFrame,SortOrder=Enum.SortOrder.LayoutOrder,
            Padding=UDim.new(0,2),
        })
        N("UIPadding",{
            Parent=settFrame,
            PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),
            PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),
        })

        for si, sett in ipairs(S) do
            local comp = self:_Setting(settFrame, sett, si)
            table.insert(settComps, comp)
        end

        local function recalc()
            local h = 8
            for _,c in ipairs(settComps) do h = h + c:H() + 2 end
            return h
        end
        settHeight = recalc()

        -- Подписка на динамическое изменение
        for _,c in ipairs(settComps) do
            if c.OnH then c.OnH(function()
                if expanded then
                    settHeight = recalc()
                    Tw(settFrame,{Size=UDim2.new(1,-2,0,settHeight)},0.2)
                    Tw(box,{Size=UDim2.new(1,0,0,MOD_H+1+settHeight)},0.2)
                end
            end) end
        end
    end

    -- ── TOGGLE ──
    local function apply(v, silent)
        toggled = v
        Tw(row,{BackgroundColor3=toggled and P.MOD_ON or P.MOD_OFF},0.12)
        lbl.TextColor3 = toggled and P.TEXT or P.TEXT_DIM
        lbl.FontFace   = toggled and P.FONT_SEMI or P.FONT
        if toggled then self:ALAdd(modName) else self:ALRem(modName) end
        if not silent and onToggle then onToggle(toggled) end
    end

    -- ── EXPAND ──
    local function expand(v)
        if not settFrame then return end
        expanded = v
        if expanded then
            Tw(settFrame,{Size=UDim2.new(1,-2,0,settHeight)},0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
            Tw(box,{Size=UDim2.new(1,0,0,MOD_H+1+settHeight)},0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
            if dots then Tw(dots,{TextColor3=P.ACCENT},0.1) end
        else
            Tw(settFrame,{Size=UDim2.new(1,-2,0,0)},0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
            Tw(box,{Size=UDim2.new(1,0,0,MOD_H)},0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
            if dots then Tw(dots,{TextColor3=P.TEXT_DARK},0.1) end
        end
    end

    -- ── BIND OVERLAY ──
    local bindOverlay, bindOText

    local function showBindOverlay()
        if not bindOverlay then
            bindOverlay = N("Frame",{
                Parent=self.Root,Name="BindOverlay",
                BackgroundColor3=Color3.new(0,0,0),
                BackgroundTransparency=0.35,
                Size=UDim2.new(1,0,1,0),ZIndex=500,
            })
            N("Frame",{
                Parent=bindOverlay,
                BackgroundColor3=P.PANEL,BackgroundTransparency=0.08,
                BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(0.5,0,0.5,0),
                Size=UDim2.new(0,260,0,80),ZIndex=501,
            })
            local inner = bindOverlay:GetChildren()[1]
            Cn(inner); St(inner,P.BORDER_L,1.5,0.3)

            bindOText = N("TextLabel",{
                Parent=inner,BackgroundTransparency=1,
                Text="Нажмите клавишу для бинда\n["..modName.."]",
                TextColor3=P.TEXT,TextSize=13,FontFace=P.FONT_SEMI,
                TextWrapped=true,Size=UDim2.new(1,-20,0,44),
                Position=UDim2.new(0,10,0,8),ZIndex=502,
            })

            -- Кнопки режима
            local modeFrame = N("Frame",{
                Parent=inner,BackgroundTransparency=1,
                Position=UDim2.new(0,0,0,52),Size=UDim2.new(1,0,0,24),ZIndex=502,
            })
            N("UIListLayout",{
                Parent=modeFrame,FillDirection=Enum.FillDirection.Horizontal,
                HorizontalAlignment=Enum.HorizontalAlignment.Center,
                Padding=UDim.new(0,6),
            })

            for _,md in ipairs({"Toggle","Hold"}) do
                local mb = N("TextButton",{
                    Parent=modeFrame,
                    BackgroundColor3=(bindMode==md:lower()) and P.ACCENT or P.TOGGLE_OFF,
                    BackgroundTransparency=0.3,BorderSizePixel=0,
                    Text=md,TextColor3=P.TEXT,TextSize=11,FontFace=P.FONT_SEMI,
                    Size=UDim2.new(0,70,0,22),ZIndex=503,AutoButtonColor=false,
                })
                Cn(mb,CORNER_XS)
                mb.MouseButton1Click:Connect(function()
                    bindMode = md:lower()
                    for _,c in pairs(modeFrame:GetChildren()) do
                        if c:IsA("TextButton") then
                            c.BackgroundColor3 = (c.Text:lower()==bindMode) and P.ACCENT or P.TOGGLE_OFF
                        end
                    end
                end)
            end
        end

        binding = true
        bindOverlay.Visible = true
        if bindOText then
            bindOText.Text = "Нажмите клавишу для бинда\n["..modName.."]"
        end
    end

    local function hideBindOverlay()
        binding = false
        if bindOverlay then bindOverlay.Visible = false end
    end

    -- Слушаем бинд
    local bindConn
    bindConn = UIS.InputBegan:Connect(function(inp, gp)
        if not binding then return end
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            if inp.KeyCode == Enum.KeyCode.Escape then
                -- Убрать бинд
                bindKey = nil
                updBind()
                hideBindOverlay()
                return
            end
            bindKey = inp.KeyCode
            updBind()
            hideBindOverlay()
        end
    end)
    table.insert(self.BindListeners, bindConn)

    -- Слушаем нажатие бинда в игре
    UIS.InputBegan:Connect(function(inp, gp)
        if gp or binding then return end
        if bindKey and inp.KeyCode == bindKey then
            if bindMode == "toggle" then
                apply(not toggled)
            elseif bindMode == "hold" then
                apply(true)
            end
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if bindKey and inp.KeyCode == bindKey and bindMode == "hold" then
            apply(false)
        end
    end)

    -- ── CLICK ZONE ──
    local zone = N("TextButton",{
        Parent=row,BackgroundTransparency=1,Text="",
        Size=UDim2.new(1,0,1,0),ZIndex=11,AutoButtonColor=false,
    })

    -- ЛКМ = toggle
    zone.MouseButton1Click:Connect(function() apply(not toggled) end)

    -- ПКМ = expand
    zone.MouseButton2Click:Connect(function()
        if #S > 0 then expand(not expanded) end
    end)

    -- СКМ = бинд
    zone.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton3 then
            showBindOverlay()
        end
    end)

    -- Hover
    zone.MouseEnter:Connect(function()
        if not toggled then Tw(row,{BackgroundColor3=P.MOD_HOVER},0.08) end
        if dots then Tw(dots,{TextColor3=P.TEXT_DIM},0.08) end
    end)
    zone.MouseLeave:Connect(function()
        if not toggled then Tw(row,{BackgroundColor3=P.MOD_OFF},0.08) end
        if dots and not expanded then Tw(dots,{TextColor3=P.TEXT_DARK},0.08) end
    end)

    -- Дефолт
    if toggled then apply(true, true) end

    local obj = {
        Name=modName,Cat=catName,Box=box,Row=row,
        IsOn=function() return toggled end,
        Toggle=function(v) if v~=nil then apply(v) else apply(not toggled) end end,
        Bind=function() return bindKey end,
        BindMode=function() return bindMode end,
    }
    self.ModData[modName] = obj
    table.insert(cat.Modules, obj)
    return obj
end

-- ================================================================
--  SETTING BUILDERS
-- ================================================================
function UI:_Setting(parent, s, order)
    local t = s.type or "toggle"
    if t=="toggle"      then return self:_SToggle(parent,s,order) end
    if t=="slider"      then return self:_SSlider(parent,s,order) end
    if t=="dropdown"    then return self:_SDrop(parent,s,order) end
    if t=="colorpicker" then return self:_SColor(parent,s,order) end

    local f=N("Frame",{Parent=parent,BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),LayoutOrder=order,ZIndex=9})
    return {H=function() return 18 end, OnH=function() end, Frame=f}
end

-- Строка для настройки
local function SRow(parent, order, h)
    h = h or 20
    local f = N("Frame",{
        Parent=parent,BackgroundColor3=Color3.fromRGB(16,12,26),
        BackgroundTransparency=0.25,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,h),LayoutOrder=order,ZIndex=9,
    })
    Cn(f,CORNER_XS)
    return f
end

-- ── TOGGLE ──
function UI:_SToggle(parent, s, order)
    local val = s.default or false
    local H = 20
    local f = SRow(parent, order, H)

    N("TextLabel",{
        Parent=f,BackgroundTransparency=1,
        Text=s.name or "Toggle",TextColor3=P.TEXT_DIM,
        TextSize=10,FontFace=P.FONT,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Position=UDim2.new(0,5,0,0),Size=UDim2.new(0.6,-5,1,0),ZIndex=10,
    })

    local sw = N("Frame",{
        Parent=f,BackgroundColor3=val and P.ACCENT or P.TOGGLE_OFF,
        BorderSizePixel=0,Size=UDim2.new(0,24,0,12),
        Position=UDim2.new(1,-30,0.5,0),AnchorPoint=Vector2.new(0,0.5),ZIndex=10,
    })
    Cn(sw,UDim.new(0,6))

    local kn = N("Frame",{
        Parent=sw,BackgroundColor3=Color3.fromRGB(255,255,255),
        BorderSizePixel=0,Size=UDim2.new(0,8,0,8),
        Position=val and UDim2.new(1,-10,0.5,0) or UDim2.new(0,2,0.5,0),
        AnchorPoint=Vector2.new(0,0.5),ZIndex=11,
    })
    Cn(kn,UDim.new(0,4))

    local function upd()
        Tw(sw,{BackgroundColor3=val and P.ACCENT or P.TOGGLE_OFF},0.12)
        Tw(kn,{Position=val and UDim2.new(1,-10,0.5,0) or UDim2.new(0,2,0.5,0)},0.12,Enum.EasingStyle.Back)
    end

    local btn=N("TextButton",{
        Parent=f,BackgroundTransparency=1,Text="",
        Size=UDim2.new(1,0,1,0),ZIndex=12,AutoButtonColor=false,
    })
    btn.MouseButton1Click:Connect(function()
        val=not val; upd()
        if s.callback then s.callback(val) end
    end)

    return {H=function() return H end, OnH=function() end, Frame=f, Val=function() return val end}
end

-- ── SLIDER ──
function UI:_SSlider(parent, s, order)
    local min  = s.min or 0
    local max  = s.max or 100
    local val  = s.default or min
    local dec  = s.decimals or 2
    local H    = 30
    local f    = SRow(parent, order, H)

    N("TextLabel",{
        Parent=f,BackgroundTransparency=1,
        Text=s.name or "Slider",TextColor3=P.TEXT_DIM,
        TextSize=10,FontFace=P.FONT,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Position=UDim2.new(0,5,0,1),Size=UDim2.new(0.55,-5,0,14),ZIndex=10,
    })

    local vLbl = N("TextLabel",{
        Parent=f,BackgroundTransparency=1,
        Text=string.format("%."..dec.."f",val),
        TextColor3=P.ACCENT,TextSize=10,FontFace=P.FONT_SEMI,
        TextXAlignment=Enum.TextXAlignment.Right,
        Position=UDim2.new(0.55,0,0,1),Size=UDim2.new(0.45,-5,0,14),ZIndex=10,
    })

    local tr = N("Frame",{
        Parent=f,BackgroundColor3=P.SLIDER_TRK,BorderSizePixel=0,
        Position=UDim2.new(0,5,0,18),Size=UDim2.new(1,-10,0,7),ZIndex=10,
    })
    Cn(tr,UDim.new(0,4))

    local p0 = (val-min)/(max-min)

    local fl = N("Frame",{
        Parent=tr,BackgroundColor3=P.ACCENT,BorderSizePixel=0,
        Size=UDim2.new(p0,0,1,0),ZIndex=11,
    })
    Cn(fl,UDim.new(0,4))
    N("UIGradient",{
        Parent=fl,
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,P.ACCENT),
            ColorSequenceKeypoint.new(1,P.ACCENT2),
        }),
    })

    local kn = N("Frame",{
        Parent=tr,BackgroundColor3=Color3.fromRGB(255,255,255),
        BorderSizePixel=0,Size=UDim2.new(0,11,0,11),
        Position=UDim2.new(p0,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),ZIndex=12,
    })
    Cn(kn,UDim.new(0,6))

    -- Glow
    N("UIStroke",{Parent=kn,Color=P.ACCENT,Thickness=1.5,Transparency=0.5})

    local drag=false
    local function app(ix)
        local a=tr.AbsolutePosition; local sz=tr.AbsoluteSize
        local p=math.clamp((ix-a.X)/sz.X,0,1)
        val=Rn(min+p*(max-min),dec)
        fl.Size=UDim2.new(p,0,1,0)
        kn.Position=UDim2.new(p,0,0.5,0)
        vLbl.Text=string.format("%."..dec.."f",val)
        if s.callback then s.callback(val) end
    end

    tr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; app(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then app(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)

    return {H=function() return H end, OnH=function() end, Frame=f, Val=function() return val end}
end

-- ── DROPDOWN ──
function UI:_SDrop(parent, s, order)
    local opts   = s.options or {}
    local sel    = s.default or (opts[1] or "—")
    local isOpen = false
    local BASE   = 20
    local optH   = #opts*19+6
    local OPEN   = BASE+optH+2
    local hCB    = nil

    local f = SRow(parent, order, BASE)

    N("TextLabel",{
        Parent=f,BackgroundTransparency=1,
        Text=s.name or "Mode",TextColor3=P.TEXT_DIM,
        TextSize=10,FontFace=P.FONT,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Position=UDim2.new(0,5,0,0),Size=UDim2.new(0.45,-5,0,BASE),ZIndex=10,
    })

    local selL = N("TextLabel",{
        Parent=f,BackgroundTransparency=1,
        Text=sel,TextColor3=P.ACCENT,TextSize=10,FontFace=P.FONT_SEMI,
        TextXAlignment=Enum.TextXAlignment.Right,
        Position=UDim2.new(0.45,0,0,0),Size=UDim2.new(0.55,-18,0,BASE),ZIndex=10,
    })

    local arw = N("TextLabel",{
        Parent=f,BackgroundTransparency=1,
        Text="▾",TextColor3=P.TEXT_DARK,TextSize=12,FontFace=P.FONT_BOLD,
        Position=UDim2.new(1,-14,0,0),Size=UDim2.new(0,12,0,BASE),ZIndex=10,
    })

    -- Список ВНУТРИ фрейма (не за пределами)
    local list = N("Frame",{
        Parent=f,BackgroundColor3=Color3.fromRGB(10,7,18),
        BackgroundTransparency=0.04,BorderSizePixel=0,
        Position=UDim2.new(0,0,0,BASE+1),
        Size=UDim2.new(1,0,0,0),ZIndex=14,
        Visible=false,ClipsDescendants=true,
    })
    Cn(list,CORNER_XS); St(list,P.BORDER_L,1,0.4)

    N("UIListLayout",{Parent=list,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,1)})
    N("UIPadding",{Parent=list,PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,3),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3)})

    for oi, opt in ipairs(opts) do
        local ob = N("TextButton",{
            Parent=list,
            BackgroundColor3=(opt==sel) and P.ACCENT or Color3.fromRGB(18,14,28),
            BackgroundTransparency=(opt==sel) and 0.35 or 0.55,
            BorderSizePixel=0,Text=opt,
            TextColor3=(opt==sel) and P.TEXT or P.TEXT_DIM,
            TextSize=10,FontFace=(opt==sel) and P.FONT_SEMI or P.FONT,
            Size=UDim2.new(1,0,0,18),LayoutOrder=oi,ZIndex=15,AutoButtonColor=false,
        })
        Cn(ob,UDim.new(0,3))

        ob.MouseEnter:Connect(function()
            if opt~=sel then Tw(ob,{BackgroundTransparency=0.2},0.06) end
        end)
        ob.MouseLeave:Connect(function()
            if opt~=sel then Tw(ob,{BackgroundTransparency=0.55},0.06) end
        end)

        ob.MouseButton1Click:Connect(function()
            for _,c in pairs(list:GetChildren()) do
                if c:IsA("TextButton") then
                    c.BackgroundColor3=Color3.fromRGB(18,14,28)
                    c.BackgroundTransparency=0.55
                    c.TextColor3=P.TEXT_DIM; c.FontFace=P.FONT
                end
            end
            ob.BackgroundColor3=P.ACCENT; ob.BackgroundTransparency=0.35
            ob.TextColor3=P.TEXT; ob.FontFace=P.FONT_SEMI
            sel=opt; selL.Text=opt

            -- Закрыть
            isOpen=false
            Tw(arw,{Rotation=0},0.1)
            Tw(f,{Size=UDim2.new(1,0,0,BASE)},0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
            Tw(list,{Size=UDim2.new(1,0,0,0)},0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
            task.delay(0.14,function() list.Visible=false end)
            if hCB then hCB() end
            if s.callback then s.callback(opt) end
        end)
    end

    local zone = N("TextButton",{
        Parent=f,BackgroundTransparency=1,Text="",
        Size=UDim2.new(1,0,0,BASE),ZIndex=13,AutoButtonColor=false,
    })
    zone.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            list.Visible=true
            Tw(arw,{Rotation=180},0.1)
            Tw(f,{Size=UDim2.new(1,0,0,OPEN)},0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
            Tw(list,{Size=UDim2.new(1,0,0,optH)},0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        else
            Tw(arw,{Rotation=0},0.1)
            Tw(f,{Size=UDim2.new(1,0,0,BASE)},0.13,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
            Tw(list,{Size=UDim2.new(1,0,0,0)},0.13,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
            task.delay(0.13,function() list.Visible=false end)
        end
        if hCB then hCB() end
    end)

    return {
        H=function() return isOpen and OPEN or BASE end,
        OnH=function(fn) hCB=fn end,
        Frame=f,
        Val=function() return sel end,
    }
end

-- ── COLOR PICKER ──
function UI:_SColor(parent, s, order)
    local col = s.default or Color3.fromRGB(99,102,241)
    local rv,gv,bv = col.R,col.G,col.B
    local isOpen = false
    local BASE  = 20
    local POP_H = 66
    local OPEN  = BASE+POP_H+2
    local hCB   = nil

    local f = SRow(parent, order, BASE)

    N("TextLabel",{
        Parent=f,BackgroundTransparency=1,
        Text=s.name or "Color",TextColor3=P.TEXT_DIM,
        TextSize=10,FontFace=P.FONT,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Position=UDim2.new(0,5,0,0),Size=UDim2.new(0.6,-5,0,BASE),ZIndex=10,
    })

    local prev = N("Frame",{
        Parent=f,BackgroundColor3=col,BorderSizePixel=0,
        Size=UDim2.new(0,14,0,14),
        Position=UDim2.new(1,-20,0.5,0),AnchorPoint=Vector2.new(0,0.5),ZIndex=10,
    })
    Cn(prev,UDim.new(0,3)); St(prev,P.BORDER_L,1,0.3)

    local popup = N("Frame",{
        Parent=f,BackgroundColor3=Color3.fromRGB(10,7,18),
        BackgroundTransparency=0.04,BorderSizePixel=0,
        Position=UDim2.new(0,0,0,BASE+1),
        Size=UDim2.new(1,0,0,0),ZIndex=14,
        Visible=false,ClipsDescendants=true,
    })
    Cn(popup,CORNER_XS); St(popup,P.BORDER_L,1,0.4)
    N("UIPadding",{Parent=popup,PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4)})
    N("UIListLayout",{Parent=popup,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3)})

    local function upd()
        local c=Color3.new(rv,gv,bv)
        prev.BackgroundColor3=c; col=c
        if s.callback then s.callback(c) end
    end

    local function bar(lbl,init,setter,bc,ord)
        local rw=N("Frame",{Parent=popup,BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),LayoutOrder=ord,ZIndex=15})
        N("TextLabel",{
            Parent=rw,BackgroundTransparency=1,Text=lbl,
            TextColor3=bc,TextSize=9,FontFace=P.FONT_BOLD,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(0,10,1,0),ZIndex=16,
        })
        local tr=N("Frame",{
            Parent=rw,BackgroundColor3=P.SLIDER_TRK,BorderSizePixel=0,
            Position=UDim2.new(0,14,0.5,0),AnchorPoint=Vector2.new(0,0.5),
            Size=UDim2.new(1,-14,0,5),ZIndex=16,
        })
        Cn(tr,UDim.new(0,3))
        local fl=N("Frame",{
            Parent=tr,BackgroundColor3=bc,BorderSizePixel=0,
            Size=UDim2.new(init,0,1,0),ZIndex=17,
        })
        Cn(fl,UDim.new(0,3))
        local kn=N("Frame",{
            Parent=tr,BackgroundColor3=Color3.fromRGB(255,255,255),
            BorderSizePixel=0,Size=UDim2.new(0,9,0,9),
            Position=UDim2.new(init,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),ZIndex=18,
        })
        Cn(kn,UDim.new(0,5))
        local drag=false
        local function set(x)
            local p=math.clamp((x-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
            fl.Size=UDim2.new(p,0,1,0); kn.Position=UDim2.new(p,0,0.5,0)
            setter(p); upd()
        end
        tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; set(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then set(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    end

    bar("R",rv,function(v)rv=v end,Color3.fromRGB(220,60,60),1)
    bar("G",gv,function(v)gv=v end,Color3.fromRGB(60,200,80),2)
    bar("B",bv,function(v)bv=v end,Color3.fromRGB(60,100,220),3)

    local zone=N("TextButton",{
        Parent=f,BackgroundTransparency=1,Text="",
        Size=UDim2.new(1,0,0,BASE),ZIndex=13,AutoButtonColor=false,
    })
    zone.MouseButton1Click:Connect(function()
        isOpen=not isOpen
        if isOpen then
            popup.Visible=true
            Tw(f,{Size=UDim2.new(1,0,0,OPEN)},0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
            Tw(popup,{Size=UDim2.new(1,0,0,POP_H)},0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        else
            Tw(f,{Size=UDim2.new(1,0,0,BASE)},0.13,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
            Tw(popup,{Size=UDim2.new(1,0,0,0)},0.13,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
            task.delay(0.13,function() popup.Visible=false end)
        end
        if hCB then hCB() end
    end)

    return {
        H=function() return isOpen and OPEN or BASE end,
        OnH=function(fn) hCB=fn end,
        Frame=f,
        Val=function() return col end,
    }
end

-- ================================================================
--  WATERMARK (перетаскиваемая)
-- ================================================================
function UI:_Watermark()
    local wm = N("Frame",{
        Parent=self.Root,Name="WM",
        BackgroundColor3=P.PANEL,BackgroundTransparency=0.06,
        BorderSizePixel=0,Position=UDim2.new(0,12,0,12),
        Size=UDim2.new(0,190,0,30),ZIndex=60,
    })
    Cn(wm); St(wm,P.BORDER,1,0.35)

    -- Акцент-блок
    local left = N("Frame",{
        Parent=wm,BackgroundColor3=P.ACCENT,BackgroundTransparency=0.15,
        BorderSizePixel=0,Size=UDim2.new(0,72,1,0),ZIndex=61,
    })
    Cn(left)
    N("UIGradient",{
        Parent=left,
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,P.ACCENT),
            ColorSequenceKeypoint.new(1,P.ACCENT2),
        }),
        Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,0.15),
            NumberSequenceKeypoint.new(1,0.35),
        }),
    })

    N("TextLabel",{
        Parent=left,BackgroundTransparency=1,
        Text="✦ Alpha",TextColor3=Color3.fromRGB(255,255,255),
        TextSize=12,FontFace=P.FONT_BOLD,
        Size=UDim2.new(1,0,1,0),ZIndex=62,
    })

    -- Разделитель
    N("Frame",{
        Parent=wm,BackgroundColor3=P.BORDER_L,BackgroundTransparency=0.3,
        BorderSizePixel=0,Position=UDim2.new(0,72,0,5),Size=UDim2.new(0,1,1,-10),ZIndex=61,
    })

    -- Никнейм + FPS/Ping
    self.WMInfo = N("TextLabel",{
        Parent=wm,BackgroundTransparency=1,
        Text=LP.Name.."  |  — fps",
        TextColor3=P.TEXT_DIM,TextSize=10,FontFace=P.FONT_SEMI,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.new(0,78,0,0),Size=UDim2.new(1,-82,1,0),ZIndex=62,
    })

    Drag(wm)
    self.WM = wm

    -- FPS/Ping update
    local fc,lt=0,tick()
    RS.Heartbeat:Connect(function()
        fc=fc+1
        if tick()-lt>=1 then
            local fps=math.floor(fc/(tick()-lt))
            local ms=math.floor(LP:GetNetworkPing()*1000)
            self.WMInfo.Text = LP.Name.."  |  "..fps.." fps  "..ms.."ms"
            fc,lt=0,tick()
        end
    end)
end

-- ================================================================
--  KEYBIND HUD (перетаскиваемый)
-- ================================================================
function UI:_BindHUD()
    local hub = N("Frame",{
        Parent=self.Root,Name="BindHUD",
        BackgroundTransparency=1,
        Position=UDim2.new(0,12,0,50),
        Size=UDim2.new(0,130,0,24),ZIndex=60,
    })

    local hdr = N("Frame",{
        Parent=hub,BackgroundColor3=P.PANEL,BackgroundTransparency=0.06,
        BorderSizePixel=0,Size=UDim2.new(1,0,0,22),ZIndex=61,
    })
    Cn(hdr); St(hdr,P.BORDER,1,0.4)

    N("TextLabel",{
        Parent=hdr,BackgroundTransparency=1,
        Text="⌨ KeyBinds",TextColor3=P.TEXT,
        TextSize=10,FontFace=P.FONT_BOLD,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.new(0,6,0,0),Size=UDim2.new(1,-8,1,0),ZIndex=62,
    })

    local rows = N("Frame",{
        Parent=hub,BackgroundTransparency=1,
        Position=UDim2.new(0,0,0,24),Size=UDim2.new(1,0,0,0),ZIndex=61,
    })
    N("UIListLayout",{Parent=rows,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,1)})

    self.BHHub  = hub
    self.BHRows = rows

    Drag(hub, hdr)

    -- Update
    local lastHash = ""
    RS.Heartbeat:Connect(function()
        -- Строим хеш
        local hash = ""
        for name,_ in pairs(self.ActiveMods) do
            local md = self.ModData[name]
            if md and md.Bind and md.Bind() then
                hash = hash..name..md.Bind().Name..md.BindMode()
            end
        end
        if hash == lastHash then return end
        lastHash = hash

        -- Перестраиваем
        for _,c in pairs(rows:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        local idx = 0
        local y = 0
        for name,_ in pairs(self.ActiveMods) do
            local md = self.ModData[name]
            if md and md.Bind and md.Bind() then
                local r = N("Frame",{
                    Parent=rows,BackgroundColor3=P.PANEL,BackgroundTransparency=0.08,
                    BorderSizePixel=0,Size=UDim2.new(1,0,0,18),LayoutOrder=idx,ZIndex=62,
                })
                Cn(r,UDim.new(0,4))

                N("TextLabel",{
                    Parent=r,BackgroundTransparency=1,
                    Text=name,TextColor3=P.TEXT_DIM,TextSize=9,FontFace=P.FONT,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Position=UDim2.new(0,5,0,0),Size=UDim2.new(0.6,-5,1,0),ZIndex=63,
                })

                local mChar = md.BindMode()=="hold" and "H" or "T"
                N("TextLabel",{
                    Parent=r,BackgroundTransparency=1,
                    Text="["..md.Bind().Name.."] "..mChar,
                    TextColor3=Color3.fromRGB(235,85,105),
                    TextSize=9,FontFace=P.FONT_SEMI,
                    TextXAlignment=Enum.TextXAlignment.Right,
                    Position=UDim2.new(0.6,0,0,0),Size=UDim2.new(0.4,-4,1,0),ZIndex=63,
                })

                idx=idx+1; y=y+19
            end
        end

        hub.Size = UDim2.new(0,130,0,24+y)
    end)
end

-- ================================================================
--  SEARCH
-- ================================================================
function UI:_Search()
    local sb = N("Frame",{
        Parent=self.Root,Name="Search",
        BackgroundColor3=P.PANEL,BackgroundTransparency=0.06,
        BorderSizePixel=0,
        Position=UDim2.new(0.5,0,1,-44),AnchorPoint=Vector2.new(0.5,1),
        Size=UDim2.new(0,250,0,28),ZIndex=60,Visible=false,
    })
    Cn(sb); St(sb,P.BORDER,1,0.4)

    N("TextLabel",{
        Parent=sb,BackgroundTransparency=1,
        Text="🔍",TextSize=11,FontFace=P.FONT,
        Position=UDim2.new(0,7,0,0),Size=UDim2.new(0,16,1,0),ZIndex=61,
    })

    self.SInput = N("TextBox",{
        Parent=sb,BackgroundTransparency=1,
        Text="",PlaceholderText="Поиск...",
        PlaceholderColor3=P.TEXT_DARK,
        TextColor3=P.TEXT,TextSize=11,FontFace=P.FONT,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.new(0,26,0,0),Size=UDim2.new(1,-30,1,0),
        ZIndex=61,ClearTextOnFocus=false,
    })

    self.SInput:GetPropertyChangedSignal("Text"):Connect(function()
        local q=self.SInput.Text:lower()
        for _,cat in pairs(self.CatData) do
            for _,m in pairs(cat.Modules) do
                m.Box.Visible = q=="" or m.Name:lower():find(q,1,true)~=nil
            end
        end
    end)

    self.SBar = sb
end

-- ================================================================
--  ARRAYLIST
-- ================================================================
function UI:_Arraylist()
    self.AL = N("Frame",{
        Parent=self.Root,Name="AL",
        BackgroundTransparency=1,
        Position=UDim2.new(1,-12,0,12),AnchorPoint=Vector2.new(1,0),
        Size=UDim2.new(0,130,0,400),ZIndex=60,
    })
    N("UIListLayout",{
        Parent=self.AL,SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,1),
    })
    Drag(self.AL)
end

function UI:ALAdd(name)
    if self.ActiveMods[name] then return end
    local e = N("Frame",{
        Parent=self.AL,Name=name,
        BackgroundColor3=P.PANEL,BackgroundTransparency=0.12,
        BorderSizePixel=0,Size=UDim2.new(0,0,0,16),
        ZIndex=61,ClipsDescendants=true,
    })
    Cn(e,UDim.new(0,4))

    N("UIGradient",{
        Parent=e,
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,P.ACCENT),
            ColorSequenceKeypoint.new(1,P.PANEL),
        }),
        Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,0.7),
            NumberSequenceKeypoint.new(1,0.88),
        }),
    })

    N("TextLabel",{
        Parent=e,BackgroundTransparency=1,
        Text=name,TextColor3=P.TEXT,TextSize=10,FontFace=P.FONT_SEMI,
        TextXAlignment=Enum.TextXAlignment.Right,
        Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,-5,1,0),ZIndex=62,
    })

    Tw(e,{Size=UDim2.new(1,0,0,16)},0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    self.ActiveMods[name] = e
end

function UI:ALRem(name)
    local e=self.ActiveMods[name]
    if not e then return end
    Tw(e,{Size=UDim2.new(0,0,0,16)},0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    task.delay(0.13,function() e:Destroy(); self.ActiveMods[name]=nil end)
end

-- ================================================================
--  SHOW / HIDE
-- ================================================================
function UI:Show()
    if self.Animating then return end
    self.Animating=true; self.Visible=true

    self.Dim.Visible=true; self.Dim.BackgroundTransparency=1
    Tw(self.Dim,{BackgroundTransparency=0.55},0.2)

    self.Menu.Visible=true

    for i,cat in ipairs(CATS) do
        local d=self.CatData[cat]
        if d then
            d.Panel.BackgroundTransparency=1
            task.delay((i-1)*0.03,function()
                Tw(d.Panel,{BackgroundTransparency=0.06},0.2)
            end)
        end
    end

    self.SBar.Visible=true
    self.SBar.Position=UDim2.new(0.5,0,1,40)
    Tw(self.SBar,{Position=UDim2.new(0.5,0,1,-44)},0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

    task.delay(0.25,function() self.Animating=false end)
end

function UI:Hide()
    if self.Animating then return end
    self.Animating=true; self.Visible=false

    Tw(self.Dim,{BackgroundTransparency=1},0.15)
    for _,cat in ipairs(CATS) do
        local d=self.CatData[cat]
        if d then Tw(d.Panel,{BackgroundTransparency=1},0.12) end
    end
    Tw(self.SBar,{Position=UDim2.new(0.5,0,1,40)},0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.In)

    task.delay(0.2,function()
        self.Dim.Visible=false; self.Menu.Visible=false
        self.SBar.Visible=false; self.Animating=false
    end)
end

-- ================================================================
--  INPUT
-- ================================================================
function UI:_Input()
    UIS.InputBegan:Connect(function(inp,gp)
        if gp then return end
        if inp.KeyCode==self.ToggleKey then
            if self.Visible then self:Hide() else self:Show() end
        end
    end)
end

return UI
