-- ============================================================
--  DARK GLASSMORPHISM UI LIBRARY
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local GlassUI = {}
GlassUI.__index = GlassUI

GlassUI.Settings = {
    ToggleKey        = Enum.KeyCode.RightShift,
    AccentColor      = Color3.fromRGB(59, 130, 246),
    AccentColorHover = Color3.fromRGB(96, 165, 250),
    BackgroundColor  = Color3.fromRGB(15, 15, 25),
    PanelColor       = Color3.fromRGB(20, 20, 35),
    TextColor        = Color3.fromRGB(255, 255, 255),
    TextColorDim     = Color3.fromRGB(150, 150, 170),
    ToggleOnColor    = Color3.fromRGB(59, 130, 246),
    ToggleOffColor   = Color3.fromRGB(60, 60, 80),
    SliderTrackColor = Color3.fromRGB(40, 40, 60),
    SliderFillColor  = Color3.fromRGB(59, 130, 246),
    BorderColor      = Color3.fromRGB(40, 40, 60),
    SuccessColor     = Color3.fromRGB(34, 197, 94),
    DangerColor      = Color3.fromRGB(239, 68, 68),
    WarningColor     = Color3.fromRGB(234, 179, 8),
    Font             = Font.new("rbxasset://fonts/families/GothamSSm.json"),
    FontBold         = Font.new("rbxasset://fonts/families/GothamSSm.json",
                           Enum.FontWeight.Bold, Enum.FontStyle.Normal),
    CornerRadius      = UDim.new(0, 12),
    SmallCornerRadius = UDim.new(0, 8),
    AnimationSpeed    = 0.3,
}

-- ============================================================
--  UTILITY
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
    return self:Create("UICorner", {
        CornerRadius = radius or self.Settings.CornerRadius,
        Parent = parent,
    })
end

function GlassUI:CreateStroke(parent, color, thickness)
    return self:Create("UIStroke", {
        Color       = color or self.Settings.BorderColor,
        Thickness   = thickness or 1,
        Transparency = 0.5,
        Parent      = parent,
    })
end

function GlassUI:Tween(obj, props, duration, style, direction)
    duration  = duration  or self.Settings.AnimationSpeed
    style     = style     or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local tw = TweenService:Create(obj, TweenInfo.new(duration, style, direction), props)
    tw:Play()
    return tw
end

function GlassUI:MakeDraggable(frame, dragBar)
    local dragging, dragStart, startPos = false, nil, nil

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
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
--  INIT — вся «глобальная» разметка создаётся здесь
-- ============================================================

function GlassUI:Init()
    -- ─── ScreenGui ───────────────────────────────────────────
    self.ScreenGui = self:Create("ScreenGui", {
        Name           = "GlassUI",
        Parent         = LocalPlayer:WaitForChild("PlayerGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
    })

    self.MainFrame = self:Create("Frame", {
        Name                 = "MainFrame",
        Parent               = self.ScreenGui,
        BackgroundColor3     = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1,0,1,0),
        ZIndex               = 1,
    })

    -- ─── Watermark ────────────────────────────────────────────
    self:_BuildWatermark()

    -- ─── PlayerList ───────────────────────────────────────────
    self:_BuildPlayerList()

    -- ─── Menu ─────────────────────────────────────────────────
    self:_BuildMenu()

    -- ─── Notifications ────────────────────────────────────────
    self:_BuildNotifications()

    -- ─── Arraylist ────────────────────────────────────────────
    self:_BuildArraylist()

    -- ─── FPS Counter ──────────────────────────────────────────
    self:_BuildFPSCounter()

    -- ─── Cursor ───────────────────────────────────────────────
    self:_BuildCursor()

    -- ─── Tooltip ──────────────────────────────────────────────
    self:_BuildTooltip()

    -- ─── Toggle listener ──────────────────────────────────────
    self:_BindToggleKey()

    -- ─── Defer tab sizing ─────────────────────────────────────
    task.defer(function()
        for name, tab in pairs(self.Tabs) do
            tab.Size = UDim2.new(0, #name * 8 + 48, 1, -12)
        end
        for _, pd in pairs(self.CategoryPanels) do
            pd.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                pd.Container.CanvasSize =
                    UDim2.new(0, 0, 0, pd.Layout.AbsoluteContentSize.Y + 8)
            end)
        end
    end)
end

-- ============================================================
--  WATERMARK
-- ============================================================

function GlassUI:_BuildWatermark()
    local S = self.Settings
    local MF = self.MainFrame

    self.WatermarkFrame = self:Create("Frame", {
        Name                 = "Watermark",
        Parent               = MF,
        BackgroundColor3     = S.PanelColor,
        BackgroundTransparency = 0.3,
        BorderSizePixel      = 0,
        Position             = UDim2.new(0,16,0,16),
        Size                 = UDim2.new(0,0,0,0),
        ZIndex               = 100,
        ClipsDescendants     = true,
    })
    self:CreateCorner(self.WatermarkFrame, UDim.new(0,8))
    self:CreateStroke(self.WatermarkFrame, S.BorderColor, 1)

    self.WatermarkLeft = self:Create("Frame", {
        Name             = "Left",
        Parent           = self.WatermarkFrame,
        BackgroundColor3 = S.AccentColor,
        BackgroundTransparency = 0.2,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0,0,1,0),
        ZIndex           = 101,
    })
    self:CreateCorner(self.WatermarkLeft, UDim.new(0,8))

    self:Create("ImageLabel", {
        Name               = "Icon",
        Parent             = self.WatermarkLeft,
        BackgroundTransparency = 1,
        Image              = "rbxassetid://12877753076",
        ImageColor3        = Color3.fromRGB(255,255,255),
        Size               = UDim2.new(0,14,0,14),
        Position           = UDim2.new(0,8,0.5,0),
        AnchorPoint        = Vector2.new(0,0.5),
        ZIndex             = 102,
    })

    self.WatermarkTitle = self:Create("TextLabel", {
        Name               = "Title",
        Parent             = self.WatermarkLeft,
        BackgroundTransparency = 1,
        Text               = "Alpha",
        TextColor3         = Color3.fromRGB(255,255,255),
        TextSize           = 13,
        FontFace           = S.FontBold,
        TextXAlignment     = Enum.TextXAlignment.Left,
        Position           = UDim2.new(0,26,0.5,0),
        AnchorPoint        = Vector2.new(0,0.5),
        Size               = UDim2.new(0,0,1,0),
        ZIndex             = 102,
    })

    self.WatermarkRight = self:Create("Frame", {
        Name             = "Right",
        Parent           = self.WatermarkFrame,
        BackgroundColor3 = S.PanelColor,
        BackgroundTransparency = 0.3,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0,0,1,0),
        ZIndex           = 101,
    })
    self:CreateCorner(self.WatermarkRight, UDim.new(0,8))

    self.WatermarkNick = self:Create("TextLabel", {
        Name             = "Nick",
        Parent           = self.WatermarkRight,
        BackgroundTransparency = 1,
        Text             = LocalPlayer.Name,
        TextColor3       = S.TextColor,
        TextSize         = 13,
        FontFace         = S.Font,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Position         = UDim2.new(0,10,0.5,0),
        AnchorPoint      = Vector2.new(0,0.5),
        Size             = UDim2.new(0,0,1,0),
        ZIndex           = 102,
    })

    self.TickIndicator = self:Create("Frame", {
        Name             = "TickIndicator",
        Parent           = self.WatermarkFrame,
        BackgroundColor3 = S.PanelColor,
        BackgroundTransparency = 0.4,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0,0,0,0),
        Position         = UDim2.new(0,0,1,4),
        ZIndex           = 100,
    })
    self:CreateCorner(self.TickIndicator, UDim.new(0,6))

    self.TickText = self:Create("TextLabel", {
        Name             = "TickText",
        Parent           = self.TickIndicator,
        BackgroundTransparency = 1,
        Text             = "20 Ticks",
        TextColor3       = S.TextColorDim,
        TextSize         = 11,
        FontFace         = S.Font,
        Size             = UDim2.new(1,0,1,0),
        ZIndex           = 101,
    })
end

function GlassUI:_AnimateWatermarkIn()
    self:Tween(self.WatermarkFrame,{Size=UDim2.new(0,160,0,32),Position=UDim2.new(0,16,0,16)},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    self:Tween(self.WatermarkLeft, {Size=UDim2.new(0,70,1,0)},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    self:Tween(self.WatermarkRight,{Size=UDim2.new(0,86,1,0),Position=UDim2.new(0,74,0,0)},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    self:Tween(self.WatermarkTitle,{Size=UDim2.new(0,40,1,0)},0.4)
    self:Tween(self.WatermarkNick, {Size=UDim2.new(0,76,1,0)},0.4)
    self:Tween(self.TickIndicator, {Size=UDim2.new(0,60,0,20)},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
end

function GlassUI:_AnimateWatermarkOut()
    self:Tween(self.WatermarkFrame,{Size=UDim2.new(0,0,0,0)},0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
end

-- ============================================================
--  PLAYER LIST
-- ============================================================

function GlassUI:_BuildPlayerList()
    local S = self.Settings

    self.PlayerListFrame = self:Create("Frame", {
        Name             = "PlayerList",
        Parent           = self.MainFrame,
        BackgroundColor3 = S.PanelColor,
        BackgroundTransparency = 0.3,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1,-16,0,16),
        AnchorPoint      = Vector2.new(1,0),
        Size             = UDim2.new(0,180,0,0),
        ZIndex           = 100,
        ClipsDescendants = true,
    })
    self:CreateCorner(self.PlayerListFrame, UDim.new(0,10))
    self:CreateStroke(self.PlayerListFrame, S.BorderColor, 1)

    self:Create("UIListLayout",{Parent=self.PlayerListFrame,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)})
    self:Create("UIPadding",{Parent=self.PlayerListFrame,PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})
end

function GlassUI:UpdatePlayerList()
    local S = self.Settings
    for _, child in pairs(self.PlayerListFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name == "PlayerEntry" then child:Destroy() end
    end

    local entries = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(entries, p) end
    end
    table.sort(entries, function(a,b) return a.Name < b.Name end)

    for i, player in ipairs(entries) do
        local entry = self:Create("Frame",{
            Name             = "PlayerEntry",
            Parent           = self.PlayerListFrame,
            BackgroundColor3 = Color3.fromRGB(30,30,50),
            BackgroundTransparency = 0.5,
            BorderSizePixel  = 0,
            Size             = UDim2.new(1,0,0,24),
            LayoutOrder      = i,
            ZIndex           = 101,
        })
        self:CreateCorner(entry, UDim.new(0,6))

        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48)
        end)

        self:Create("ImageLabel",{
            Parent             = entry,
            BackgroundTransparency=1,
            Image              = ok and img or "",
            Size               = UDim2.new(0,20,0,20),
            Position           = UDim2.new(0,4,0.5,0),
            AnchorPoint        = Vector2.new(0,0.5),
            ZIndex             = 102,
        })

        self:Create("TextLabel",{
            Parent             = entry,
            BackgroundTransparency=1,
            Text               = player.Name,
            TextColor3         = S.TextColor,
            TextSize           = 12,
            FontFace           = S.Font,
            TextXAlignment     = Enum.TextXAlignment.Left,
            Position           = UDim2.new(0,30,0.5,0),
            AnchorPoint        = Vector2.new(0,0.5),
            Size               = UDim2.new(0,80,1,0),
            ZIndex             = 102,
        })

        local dotColors = {
            Color3.fromRGB(59,130,246),Color3.fromRGB(34,197,94),
            Color3.fromRGB(234,179,8),Color3.fromRGB(239,68,68),Color3.fromRGB(168,85,247)
        }
        local dot = self:Create("Frame",{
            Parent           = entry,
            BackgroundColor3 = dotColors[(player.UserId % #dotColors)+1],
            BorderSizePixel  = 0,
            Size             = UDim2.new(0,6,0,6),
            Position         = UDim2.new(1,-14,0.5,0),
            AnchorPoint      = Vector2.new(0,0.5),
            ZIndex           = 102,
        })
        self:CreateCorner(dot, UDim.new(0,3))
    end

    self:Tween(self.PlayerListFrame,{Size=UDim2.new(0,180,0,#entries*26+16)},0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end

-- ============================================================
--  MENU (TabBar + Panels)
-- ============================================================

local Categories = {
    {Name="Combat",   Icon="⚔"},
    {Name="Movement", Icon="🏃"},
    {Name="Visuals",  Icon="👁"},
    {Name="Player",   Icon="👤"},
    {Name="Misc",     Icon="⚙"},
}

function GlassUI:_BuildMenu()
    local S = self.Settings

    self.MenuContainer = self:Create("Frame",{
        Name               = "MenuContainer",
        Parent             = self.MainFrame,
        BackgroundTransparency=1,
        Size               = UDim2.new(1,0,1,0),
        ZIndex             = 50,
    })

    self.BackgroundDim = self:Create("Frame",{
        Name               = "BackgroundDim",
        Parent             = self.MenuContainer,
        BackgroundColor3   = Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.5,
        Size               = UDim2.new(1,0,1,0),
        ZIndex             = 51,
        Visible            = false,
    })

    -- TabBar
    self.TabBar = self:Create("Frame",{
        Name               = "TabBar",
        Parent             = self.MenuContainer,
        BackgroundColor3   = S.PanelColor,
        BackgroundTransparency=0.15,
        BorderSizePixel    = 0,
        Position           = UDim2.new(0.5,0,0,60),
        AnchorPoint        = Vector2.new(0.5,0),
        Size               = UDim2.new(0,700,0,44),
        ZIndex             = 60,
        Visible            = false,
    })
    self:CreateCorner(self.TabBar, UDim.new(0,14))
    self:CreateStroke(self.TabBar, S.BorderColor, 1.5)
    self:Create("UIListLayout",{Parent=self.TabBar,FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)})
    self:Create("UIPadding",{Parent=self.TabBar,PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})

    -- Panels container
    self.PanelsContainer = self:Create("Frame",{
        Name               = "PanelsContainer",
        Parent             = self.MenuContainer,
        BackgroundTransparency=1,
        Position           = UDim2.new(0.5,0,0,114),
        AnchorPoint        = Vector2.new(0.5,0),
        Size               = UDim2.new(0,700,0,400),
        ZIndex             = 55,
        Visible            = false,
    })

    -- SearchBar
    self.SearchBar = self:Create("Frame",{
        Name               = "SearchBar",
        Parent             = self.MenuContainer,
        BackgroundColor3   = S.PanelColor,
        BackgroundTransparency=0.2,
        BorderSizePixel    = 0,
        Position           = UDim2.new(0.5,0,1,-50),
        AnchorPoint        = Vector2.new(0.5,1),
        Size               = UDim2.new(0,300,0,36),
        ZIndex             = 70,
        Visible            = false,
    })
    self:CreateCorner(self.SearchBar, UDim.new(0,10))
    self:CreateStroke(self.SearchBar, S.BorderColor, 1)

    self:Create("ImageLabel",{Parent=self.SearchBar,BackgroundTransparency=1,Image="rbxassetid://7072706618",ImageColor3=S.TextColorDim,Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,12,0.5,0),AnchorPoint=Vector2.new(0,0.5),ZIndex=71})

    local searchInput = self:Create("TextBox",{
        Name="Input",Parent=self.SearchBar,BackgroundTransparency=1,
        Text="",PlaceholderText="Поиск модулей...",PlaceholderColor3=S.TextColorDim,
        TextColor3=S.TextColorDim,TextSize=13,FontFace=S.Font,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.new(0,34,0,0),Size=UDim2.new(1,-44,1,0),ZIndex=71,ClearTextOnFocus=false,
    })
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchInput.Text:lower()
        for _, pd in pairs(self.CategoryPanels) do
            for _, m in pairs(pd.Container:GetChildren()) do
                if m:IsA("Frame") then
                    local t = m:FindFirstChild("Text")
                    m.Visible = (q=="" or not t) or (t and t.Text:lower():find(q)~=nil)
                end
            end
        end
    end)
    searchInput.Focused:Connect(function()  self:Tween(self.SearchBar,{BackgroundColor3=Color3.fromRGB(30,30,55)},0.15) end)
    searchInput.FocusLost:Connect(function() self:Tween(self.SearchBar,{BackgroundColor3=S.PanelColor},0.15) end)

    -- Config Manager
    self:_BuildConfigManager()

    -- Tabs + Panels
    self.CategoryPanels = {}
    self.Tabs           = {}
    self.ActiveCategory = nil

    for i, cat in ipairs(Categories) do
        self:_BuildCategoryTab(i, cat)
    end

    -- Tab click events
    for name, tab in pairs(self.Tabs) do
        tab.MouseButton1Click:Connect(function() self:SwitchCategory(name) end)
        tab.MouseEnter:Connect(function()
            if self.ActiveCategory ~= name then self:Tween(tab,{BackgroundTransparency=0.3},0.15) end
        end)
        tab.MouseLeave:Connect(function()
            if self.ActiveCategory ~= name then self:Tween(tab,{BackgroundTransparency=0.5},0.15) end
        end)
    end
end

function GlassUI:_BuildCategoryTab(index, cat)
    local S = self.Settings

    -- Tab button
    local tab = self:Create("TextButton",{
        Name             = cat.Name,
        Parent           = self.TabBar,
        BackgroundColor3 = Color3.fromRGB(30,30,50),
        BackgroundTransparency=0.5,
        BorderSizePixel  = 0,
        Text             = "",
        Size             = UDim2.new(0,0,1,-12),
        ZIndex           = 61,
        LayoutOrder      = index,
        AutoButtonColor  = false,
    })
    self:CreateCorner(tab, UDim.new(0,8))

    self:Create("TextLabel",{Name="Icon",Parent=tab,BackgroundTransparency=1,Text=cat.Icon,TextSize=14,FontFace=S.Font,Position=UDim2.new(0,10,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,20,0,20),ZIndex=62})

    local tabText = self:Create("TextLabel",{
        Name="Text",Parent=tab,BackgroundTransparency=1,
        Text=cat.Name,TextColor3=S.TextColorDim,TextSize=13,FontFace=S.FontBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.new(0,32,0.5,0),AnchorPoint=Vector2.new(0,0.5),
        Size=UDim2.new(0,0,1,0),ZIndex=62,
    })

    local indicator = self:Create("Frame",{
        Name="Indicator",Parent=tab,BackgroundColor3=S.AccentColor,
        BackgroundTransparency=0.3,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,0),ZIndex=63,Visible=false,
    })
    self:CreateCorner(indicator, UDim.new(0,2))

    self.Tabs[cat.Name] = tab

    -- Panel
    local panel = self:Create("Frame",{
        Name             = cat.Name.."Panel",
        Parent           = self.PanelsContainer,
        BackgroundColor3 = S.PanelColor,
        BackgroundTransparency=0.2,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0,0,1,0),
        ZIndex           = 56,
        Visible          = false,
        ClipsDescendants = true,
    })
    self:CreateCorner(panel, UDim.new(0,12))
    self:CreateStroke(panel, S.BorderColor, 1)

    local header = self:Create("Frame",{
        Name="Header",Parent=panel,BackgroundColor3=S.AccentColor,
        BackgroundTransparency=0.85,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,36),ZIndex=57,
    })
    self:CreateCorner(header, UDim.new(0,12))
    self:Create("TextLabel",{Name="Title",Parent=header,BackgroundTransparency=1,Text=cat.Name,TextColor3=S.TextColor,TextSize=14,FontFace=S.FontBold,Size=UDim2.new(1,0,1,0),ZIndex=58})

    self:Create("Frame",{Name="Divider",Parent=panel,BackgroundColor3=S.BorderColor,BackgroundTransparency=0.5,BorderSizePixel=0,Size=UDim2.new(1,-16,0,1),Position=UDim2.new(0,8,0,36),ZIndex=57})

    local moduleContainer = self:Create("ScrollingFrame",{
        Name="ModuleContainer",Parent=panel,BackgroundTransparency=1,BorderSizePixel=0,
        Position=UDim2.new(0,8,0,42),Size=UDim2.new(1,-16,1,-50),ZIndex=58,
        ScrollBarThickness=4,ScrollBarImageColor3=S.AccentColor,ScrollBarImageTransparency=0.5,
        CanvasSize=UDim2.new(0,0,0,0),
        TopImage="rbxasset://textures/ui/Scroll/scroll-middle.png",
        BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",
    })

    local layout = self:Create("UIListLayout",{Parent=moduleContainer,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)})
    self:Create("UIPadding",{Parent=moduleContainer,PaddingBottom=UDim.new(0,8)})

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        moduleContainer.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+8)
    end)

    self.CategoryPanels[cat.Name] = {
        Panel     = panel,
        Container = moduleContainer,
        Layout    = layout,
        Tab       = tab,
        Indicator = indicator,
        TabText   = tabText,
    }
end

-- ============================================================
--  CONFIG MANAGER
-- ============================================================

function GlassUI:_BuildConfigManager()
    local S = self.Settings

    self.ConfigManager = self:Create("Frame",{
        Name             = "ConfigManager",
        Parent           = self.MenuContainer,
        BackgroundColor3 = S.PanelColor,
        BackgroundTransparency=0.2,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1,-16,1,-50),
        AnchorPoint      = Vector2.new(1,1),
        Size             = UDim2.new(0,220,0,180),
        ZIndex           = 70,
        Visible          = false,
        ClipsDescendants = true,
    })
    self:CreateCorner(self.ConfigManager, UDim.new(0,12))
    self:CreateStroke(self.ConfigManager, S.BorderColor, 1.5)

    local header = self:Create("Frame",{Parent=self.ConfigManager,BackgroundColor3=S.AccentColor,BackgroundTransparency=0.85,BorderSizePixel=0,Size=UDim2.new(1,0,0,32),ZIndex=71})
    self:CreateCorner(header, UDim.new(0,12))
    self:Create("TextLabel",{Parent=header,BackgroundTransparency=1,Text="Config Manager",TextColor3=S.TextColor,TextSize=13,FontFace=S.FontBold,Size=UDim2.new(1,0,1,0),ZIndex=72})

    local nameFrame = self:Create("Frame",{Parent=self.ConfigManager,BackgroundColor3=Color3.fromRGB(25,25,45),BackgroundTransparency=0.4,BorderSizePixel=0,Size=UDim2.new(1,-20,0,30),Position=UDim2.new(0,10,0,42),ZIndex=71})
    self:CreateCorner(nameFrame, UDim.new(0,8))
    self:Create("TextLabel",{Parent=nameFrame,BackgroundTransparency=1,Text="Название",TextColor3=S.TextColorDim,TextSize=11,FontFace=S.Font,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.new(0,10,0,0),Size=UDim2.new(0,60,1,0),ZIndex=72})

    local nameInput = self:Create("TextBox",{Parent=nameFrame,BackgroundTransparency=1,Text="",PlaceholderText="my_config",PlaceholderColor3=Color3.fromRGB(80,80,100),TextColor3=S.TextColor,TextSize=12,FontFace=S.Font,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.new(0,74,0,0),Size=UDim2.new(1,-84,1,0),ZIndex=72,ClearTextOnFocus=false})

    local btnsFrame = self:Create("Frame",{Parent=self.ConfigManager,BackgroundTransparency=1,Size=UDim2.new(1,-20,0,0),Position=UDim2.new(0,10,0,80),ZIndex=71})
    local btnsLayout = self:Create("UIListLayout",{Parent=btnsFrame,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)})

    local function cfgBtn(text, color, order, cb)
        local btn = self:Create("TextButton",{
            Name=text,Parent=btnsFrame,BackgroundColor3=color or Color3.fromRGB(30,30,55),
            BackgroundTransparency=0.3,BorderSizePixel=0,Text=text,TextColor3=S.TextColor,
            TextSize=12,FontFace=S.FontBold,Size=UDim2.new(1,0,0,26),LayoutOrder=order,ZIndex=72,AutoButtonColor=false,
        })
        self:CreateCorner(btn, UDim.new(0,6))
        btn.MouseEnter:Connect(function() self:Tween(btn,{BackgroundTransparency=0.1},0.15) end)
        btn.MouseLeave:Connect(function() self:Tween(btn,{BackgroundTransparency=0.3},0.15) end)
        btn.MouseButton1Click:Connect(function()
            self:Tween(btn,{BackgroundColor3=S.AccentColor},0.1)
            task.wait(0.15)
            self:Tween(btn,{BackgroundColor3=color or Color3.fromRGB(30,30,55)},0.2)
            if cb then cb() end
        end)
        return btn
    end

    cfgBtn("Создать",  S.SuccessColor,             1, function() local n=nameInput.Text if n~="" then print("[GlassUI] Config created: "..n) end end)
    cfgBtn("Сохранить",S.AccentColor,              2, function() print("[GlassUI] Config saved")   end)
    cfgBtn("Загрузить",Color3.fromRGB(50,50,80),   3, function() print("[GlassUI] Config loaded")  end)
    cfgBtn("Удалить",  S.DangerColor,              4, function() print("[GlassUI] Config deleted") end)

    task.defer(function()
        btnsFrame.Size = UDim2.new(1,-20,0,btnsLayout.AbsoluteContentSize.Y)
    end)
end

-- ============================================================
--  SWITCH CATEGORY
-- ============================================================

function GlassUI:SwitchCategory(name)
    if self.ActiveCategory == name then return end
    local S = self.Settings

    if self.ActiveCategory and self.CategoryPanels[self.ActiveCategory] then
        local prev = self.CategoryPanels[self.ActiveCategory]
        self:Tween(prev.Panel,{Size=UDim2.new(0,0,1,0)},0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
        self:Tween(prev.Tab, {BackgroundTransparency=0.5},0.2)
        prev.TabText.TextColor3 = S.TextColorDim
        prev.Indicator.Visible = false
        prev.Panel.Visible = false
    end

    local curr = self.CategoryPanels[name]
    if curr then
        curr.Panel.Visible = true
        curr.Panel.Size    = UDim2.new(0,0,1,0)
        self:Tween(curr.Panel,{Size=UDim2.new(1,0,1,0)},0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        self:Tween(curr.Tab, {BackgroundTransparency=0.1},0.2)
        curr.TabText.TextColor3 = S.TextColor
        curr.Indicator.Visible  = true
        self.ActiveCategory     = name
    end
end

-- ============================================================
--  MODULES
-- ============================================================

function GlassUI:CreateToggle(panelName, text, default, callback)
    local pd = self.CategoryPanels[panelName]
    if not pd then return end
    local S = self.Settings

    local frame = self:Create("Frame",{
        Name="Toggle",Parent=pd.Container,
        BackgroundColor3=Color3.fromRGB(25,25,45),BackgroundTransparency=0.6,
        BorderSizePixel=0,Size=UDim2.new(1,0,0,32),
        LayoutOrder=#pd.Container:GetChildren()+1,ZIndex=59,ClipsDescendants=true,
    })
    self:CreateCorner(frame, UDim.new(0,8))

    self:Create("TextLabel",{Name="Text",Parent=frame,BackgroundTransparency=1,Text=text,TextColor3=S.TextColor,TextSize=13,FontFace=S.Font,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.new(0,12,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,140,1,0),ZIndex=60})

    local sw = self:Create("Frame",{Name="Switch",Parent=frame,BackgroundColor3=default and S.ToggleOnColor or S.ToggleOffColor,BorderSizePixel=0,Size=UDim2.new(0,36,0,18),Position=UDim2.new(1,-12,0.5,0),AnchorPoint=Vector2.new(1,0.5),ZIndex=60})
    self:CreateCorner(sw, UDim.new(0,9))

    local knob = self:Create("Frame",{Name="Knob",Parent=sw,BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Size=UDim2.new(0,14,0,14),Position=default and UDim2.new(1,-16,0.5,0) or UDim2.new(0,2,0.5,0),AnchorPoint=Vector2.new(0,0.5),ZIndex=61})
    self:CreateCorner(knob, UDim.new(0,7))

    local isOn = default or false

    local function update()
        if isOn then
            self:Tween(sw,   {BackgroundColor3=S.ToggleOnColor},0.2)
            self:Tween(knob, {Position=UDim2.new(1,-16,0.5,0)},0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
            self:Tween(frame,{BackgroundColor3=Color3.fromRGB(30,30,55)},0.2)
        else
            self:Tween(sw,   {BackgroundColor3=S.ToggleOffColor},0.2)
            self:Tween(knob, {Position=UDim2.new(0,2,0.5,0)},0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
            self:Tween(frame,{BackgroundColor3=Color3.fromRGB(25,25,45)},0.2)
        end
    end

    -- ⚠ Используем InputBegan вместо MouseButton1Click на Frame
    local btn = self:Create("TextButton",{
        Parent=frame,BackgroundTransparency=1,Text="",
        Size=UDim2.new(1,0,1,0),ZIndex=62,AutoButtonColor=false,
    })
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        update()
        if callback then callback(isOn) end
    end)
    frame.MouseEnter:Connect(function() if not isOn then self:Tween(frame,{BackgroundColor3=Color3.fromRGB(30,30,50)},0.15) end end)
    frame.MouseLeave:Connect(function() if not isOn then self:Tween(frame,{BackgroundColor3=Color3.fromRGB(25,25,45)},0.15) end end)

    update()

    return {Frame=frame, IsOn=function() return isOn end, Set=function(v) isOn=v update() if callback then callback(isOn) end end}
end

function GlassUI:CreateSlider(panelName, text, min, max, default, callback)
    local pd = self.CategoryPanels[panelName]
    if not pd then return end
    local S = self.Settings

    local frame = self:Create("Frame",{
        Name="Slider",Parent=pd.Container,
        BackgroundColor3=Color3.fromRGB(25,25,45),BackgroundTransparency=0.6,
        BorderSizePixel=0,Size=UDim2.new(1,0,0,52),
        LayoutOrder=#pd.Container:GetChildren()+1,ZIndex=59,ClipsDescendants=true,
    })
    self:CreateCorner(frame, UDim.new(0,8))

    self:Create("TextLabel",{Name="Text",Parent=frame,BackgroundTransparency=1,Text=text,TextColor3=S.TextColor,TextSize=13,FontFace=S.Font,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.new(0,12,0,6),Size=UDim2.new(0,140,0,20),ZIndex=60})

    local valueLbl = self:Create("TextLabel",{Name="Value",Parent=frame,BackgroundTransparency=1,Text=tostring(self:RoundNumber(default,1)),TextColor3=S.AccentColor,TextSize=12,FontFace=S.FontBold,TextXAlignment=Enum.TextXAlignment.Right,Position=UDim2.new(1,-12,0,6),Size=UDim2.new(0,50,0,20),ZIndex=60})

    local track = self:Create("Frame",{Name="Track",Parent=frame,BackgroundColor3=S.SliderTrackColor,BorderSizePixel=0,Size=UDim2.new(1,-24,0,6),Position=UDim2.new(0,12,1,-16),ZIndex=60})
    self:CreateCorner(track, UDim.new(0,3))

    local fill = self:Create("Frame",{Name="Fill",Parent=track,BackgroundColor3=S.SliderFillColor,BorderSizePixel=0,Size=UDim2.new((default-min)/(max-min),0,1,0),ZIndex=61})
    self:CreateCorner(fill, UDim.new(0,3))

    local knob = self:Create("Frame",{Name="Knob",Parent=track,BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Size=UDim2.new(0,14,0,14),Position=UDim2.new((default-min)/(max-min),0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),ZIndex=62})
    self:CreateCorner(knob, UDim.new(0,7))

    local currentValue = default
    local dragging = false

    local function updateSlider(val)
        val = math.clamp(val, min, max)
        currentValue = val
        local pct = (val-min)/(max-min)
        fill.Size     = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,0,0.5,0)
        valueLbl.Text = tostring(self:RoundNumber(val,1))
        if callback then callback(val) end
    end

    local function handle(input)
        local pct = math.clamp((input.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        updateSlider(min + pct*(max-min))
    end

    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true handle(i) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then handle(i) end end)
    UserInputService.InputEnded:Connect(function(i)  if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

    frame.MouseEnter:Connect(function() self:Tween(frame,{BackgroundColor3=Color3.fromRGB(30,30,50)},0.15) end)
    frame.MouseLeave:Connect(function() self:Tween(frame,{BackgroundColor3=Color3.fromRGB(25,25,45)},0.15) end)

    return {Frame=frame, GetValue=function() return currentValue end, SetValue=updateSlider}
end

function GlassUI:CreateDropdown(panelName, text, options, default, callback)
    local pd = self.CategoryPanels[panelName]
    if not pd then return end
    local S = self.Settings

    local frame = self:Create("Frame",{
        Name="Dropdown",Parent=pd.Container,
        BackgroundColor3=Color3.fromRGB(25,25,45),BackgroundTransparency=0.6,
        BorderSizePixel=0,Size=UDim2.new(1,0,0,32),
        LayoutOrder=#pd.Container:GetChildren()+1,ZIndex=59,ClipsDescendants=true,
    })
    self:CreateCorner(frame, UDim.new(0,8))

    self:Create("TextLabel",{Name="Text",Parent=frame,BackgroundTransparency=1,Text=text,TextColor3=S.TextColor,TextSize=13,FontFace=S.Font,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.new(0,12,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,120,1,0),ZIndex=60})

    local selLbl = self:Create("TextLabel",{Name="Selected",Parent=frame,BackgroundTransparency=1,Text=default or options[1],TextColor3=S.AccentColor,TextSize=12,FontFace=S.FontBold,TextXAlignment=Enum.TextXAlignment.Right,Position=UDim2.new(1,-36,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,60,1,0),ZIndex=60})

    local arrow = self:Create("TextLabel",{Name="Arrow",Parent=frame,BackgroundTransparency=1,Text="▼",TextColor3=S.TextColorDim,TextSize=10,FontFace=S.Font,Position=UDim2.new(1,-14,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,16,1,0),ZIndex=60})

    local list = self:Create("Frame",{Name="List",Parent=frame,BackgroundColor3=Color3.fromRGB(20,20,40),BackgroundTransparency=0.1,BorderSizePixel=0,Position=UDim2.new(0,0,1,2),Size=UDim2.new(1,0,0,0),ZIndex=65,Visible=false,ClipsDescendants=true})
    self:CreateCorner(list, UDim.new(0,8))
    self:CreateStroke(list, S.BorderColor, 1)
    self:Create("UIListLayout",{Parent=list,SortOrder=Enum.SortOrder.LayoutOrder})
    self:Create("UIPadding",{Parent=list,PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)})

    local selectedValue = default or options[1]
    local isOpen = false

    for i, opt in ipairs(options) do
        local ob = self:Create("TextButton",{
            Name="Option",Parent=list,
            BackgroundColor3=opt==selectedValue and S.AccentColor or Color3.fromRGB(25,25,45),
            BackgroundTransparency=opt==selectedValue and 0.3 or 0.6,
            BorderSizePixel=0,Text=opt,TextColor3=S.TextColor,TextSize=12,FontFace=S.Font,
            Size=UDim2.new(1,-8,0,26),Position=UDim2.new(0,4,0,0),LayoutOrder=i,ZIndex=66,AutoButtonColor=false,
        })
        self:CreateCorner(ob, UDim.new(0,6))
        ob.MouseButton1Click:Connect(function()
            selectedValue = opt
            selLbl.Text   = opt
            isOpen = false
            list.Visible  = false
            self:Tween(frame,{Size=UDim2.new(1,0,0,32)},0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
            self:Tween(arrow,{Rotation=0},0.2)
            for _, c in pairs(list:GetChildren()) do
                if c:IsA("TextButton") then c.BackgroundColor3=Color3.fromRGB(25,25,45) c.BackgroundTransparency=0.6 end
            end
            ob.BackgroundColor3=S.AccentColor ob.BackgroundTransparency=0.3
            if callback then callback(opt) end
        end)
        ob.MouseEnter:Connect(function() if opt~=selectedValue then self:Tween(ob,{BackgroundTransparency=0.3},0.1) end end)
        ob.MouseLeave:Connect(function() if opt~=selectedValue then self:Tween(ob,{BackgroundTransparency=0.6},0.1) end end)
    end

    local clickBtn = self:Create("TextButton",{Parent=frame,BackgroundTransparency=1,Text="",Size=UDim2.new(1,0,0,32),ZIndex=67,AutoButtonColor=false})
    clickBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            list.Visible = true
            self:Tween(frame,{Size=UDim2.new(1,0,0,32+#options*26+8)},0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
            self:Tween(arrow,{Rotation=180},0.2)
        else
            self:Tween(frame,{Size=UDim2.new(1,0,0,32)},0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
            self:Tween(arrow,{Rotation=0},0.2)
            task.wait(0.2) list.Visible=false
        end
    end)

    frame.MouseEnter:Connect(function() self:Tween(frame,{BackgroundColor3=Color3.fromRGB(30,30,50)},0.15) end)
    frame.MouseLeave:Connect(function() self:Tween(frame,{BackgroundColor3=Color3.fromRGB(25,25,45)},0.15) end)

    return {Frame=frame, GetValue=function() return selectedValue end, Set=function(v) selectedValue=v selLbl.Text=v if callback then callback(v) end end}
end

function GlassUI:CreateKeybind(panelName, text, defaultKey, callback)
    local pd = self.CategoryPanels[panelName]
    if not pd then return end
    local S = self.Settings

    local frame = self:Create("Frame",{Name="Keybind",Parent=pd.Container,BackgroundColor3=Color3.fromRGB(25,25,45),BackgroundTransparency=0.6,BorderSizePixel=0,Size=UDim2.new(1,0,0,32),LayoutOrder=#pd.Container:GetChildren()+1,ZIndex=59})
    self:CreateCorner(frame, UDim.new(0,8))

    self:Create("TextLabel",{Name="Text",Parent=frame,BackgroundTransparency=1,Text=text,TextColor3=S.TextColor,TextSize=13,FontFace=S.Font,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.new(0,12,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,120,1,0),ZIndex=60})

    local keyBtn = self:Create("TextButton",{Name="KeyBtn",Parent=frame,BackgroundColor3=S.ToggleOffColor,BorderSizePixel=0,Text=defaultKey and defaultKey.Name or "None",TextColor3=S.TextColor,TextSize=12,FontFace=S.FontBold,Size=UDim2.new(0,60,0,22),Position=UDim2.new(1,-12,0.5,0),AnchorPoint=Vector2.new(1,0.5),ZIndex=60,AutoButtonColor=false})
    self:CreateCorner(keyBtn, UDim.new(0,6))

    local currentKey = defaultKey
    local waiting    = false

    keyBtn.MouseButton1Click:Connect(function()
        waiting = true
        keyBtn.Text = "..."
        self:Tween(keyBtn,{BackgroundColor3=S.AccentColor},0.1)
    end)

    UserInputService.InputBegan:Connect(function(input)
        if waiting and input.UserInputType==Enum.UserInputType.Keyboard then
            currentKey     = input.KeyCode
            keyBtn.Text    = input.KeyCode.Name
            waiting        = false
            self:Tween(keyBtn,{BackgroundColor3=S.ToggleOffColor},0.1)
            if callback then callback(input.KeyCode) end
        end
    end)

    frame.MouseEnter:Connect(function() self:Tween(frame,{BackgroundColor3=Color3.fromRGB(30,30,50)},0.15) end)
    frame.MouseLeave:Connect(function() self:Tween(frame,{BackgroundColor3=Color3.fromRGB(25,25,45)},0.15) end)

    return {Frame=frame, GetKey=function() return currentKey end}
end

function GlassUI:CreateColorPicker(panelName, text, defaultColor, callback)
    local pd = self.CategoryPanels[panelName]
    if not pd then return end
    local S = self.Settings

    local frame = self:Create("Frame",{Name="ColorPicker",Parent=pd.Container,BackgroundColor3=Color3.fromRGB(25,25,45),BackgroundTransparency=0.6,BorderSizePixel=0,Size=UDim2.new(1,0,0,32),LayoutOrder=#pd.Container:GetChildren()+1,ZIndex=59})
    self:CreateCorner(frame, UDim.new(0,8))

    self:Create("TextLabel",{Name="Text",Parent=frame,BackgroundTransparency=1,Text=text,TextColor3=S.TextColor,TextSize=13,FontFace=S.Font,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.new(0,12,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,120,1,0),ZIndex=60})

    local preview = self:Create("Frame",{Name="Preview",Parent=frame,BackgroundColor3=defaultColor or Color3.fromRGB(255,255,255),BorderSizePixel=0,Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-14,0.5,0),AnchorPoint=Vector2.new(1,0.5),ZIndex=60})
    self:CreateCorner(preview, UDim.new(0,6))
    self:CreateStroke(preview, S.BorderColor, 1)

    local popup = self:Create("Frame",{Name="Popup",Parent=frame,BackgroundColor3=Color3.fromRGB(20,20,40),BackgroundTransparency=0.1,BorderSizePixel=0,Position=UDim2.new(0,0,1,4),Size=UDim2.new(1,0,0,0),ZIndex=70,Visible=false,ClipsDescendants=true})
    self:CreateCorner(popup, UDim.new(0,8))
    self:CreateStroke(popup, S.BorderColor, 1)
    self:Create("UIPadding",{Parent=popup,PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})
    self:Create("UIListLayout",{Parent=popup,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)})

    local currentColor = defaultColor or Color3.fromRGB(255,255,255)
    local pickerOpen   = false
    local rVal, gVal, bVal = currentColor.R, currentColor.G, currentColor.B

    local function makeRGBSlider(label, color, order)
        local row = self:Create("Frame",{Name=label,Parent=popup,BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),LayoutOrder=order,ZIndex=71})
        self:Create("TextLabel",{Parent=row,BackgroundTransparency=1,Text=label,TextColor3=S.TextColor,TextSize=11,FontFace=S.FontBold,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(0,20,1,0),ZIndex=72})

        local trk = self:Create("Frame",{Parent=row,BackgroundColor3=color,BorderSizePixel=0,Size=UDim2.new(1,-28,0,8),Position=UDim2.new(0,24,0.5,0),AnchorPoint=Vector2.new(0,0.5),ZIndex=72})
        self:CreateCorner(trk, UDim.new(0,4))
        local kn = self:Create("Frame",{Parent=trk,BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Size=UDim2.new(0,12,0,12),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),ZIndex=73})
        self:CreateCorner(kn, UDim.new(0,6))

        local val = 0.5
        local drag = false
        trk.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
                val = math.clamp((i.Position.X-trk.AbsolutePosition.X)/trk.AbsoluteSize.X,0,1)
                kn.Position = UDim2.new(val,0,0.5,0)
            end
        end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
        return function() return val end
    end

    local getR = makeRGBSlider("R", Color3.fromRGB(255,0,0),   1)
    local getG = makeRGBSlider("G", Color3.fromRGB(0,255,0),   2)
    local getB = makeRGBSlider("B", Color3.fromRGB(0,0,255),   3)

    local clickBtn = self:Create("TextButton",{Parent=frame,BackgroundTransparency=1,Text="",Size=UDim2.new(1,0,0,32),ZIndex=75,AutoButtonColor=false})
    clickBtn.MouseButton1Click:Connect(function()
        pickerOpen = not pickerOpen
        if pickerOpen then
            popup.Visible = true
            self:Tween(frame,{Size=UDim2.new(1,0,0,132)},0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        else
            self:Tween(frame,{Size=UDim2.new(1,0,0,32)},0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
            task.wait(0.2) popup.Visible=false
        end
    end)

    RunService.Heartbeat:Connect(function()
        if pickerOpen then
            local nc = Color3.fromRGB(math.floor(getR()*255),math.floor(getG()*255),math.floor(getB()*255))
            if nc ~= currentColor then
                currentColor = nc
                preview.BackgroundColor3 = nc
                if callback then callback(nc) end
            end
        end
    end)

    frame.MouseEnter:Connect(function() self:Tween(frame,{BackgroundColor3=Color3.fromRGB(30,30,50)},0.15) end)
    frame.MouseLeave:Connect(function() self:Tween(frame,{BackgroundColor3=Color3.fromRGB(25,25,45)},0.15) end)

    return {Frame=frame, GetColor=function() return currentColor end}
end

function GlassUI:CreateLabel(panelName, text)
    local pd = self.CategoryPanels[panelName]
    if not pd then return end

    local f = self:Create("Frame",{Name="Label",Parent=pd.Container,BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),LayoutOrder=#pd.Container:GetChildren()+1,ZIndex=59})
    self:Create("TextLabel",{Name="Text",Parent=f,BackgroundTransparency=1,Text=text,TextColor3=self.Settings.TextColorDim,TextSize=11,FontFace=self.Settings.FontBold,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,1,0),ZIndex=60})
    return f
end

function GlassUI:CreateSeparator(panelName)
    local pd = self.CategoryPanels[panelName]
    if not pd then return end
    return self:Create("Frame",{Name="Separator",Parent=pd.Container,BackgroundColor3=self.Settings.BorderColor,BackgroundTransparency=0.5,BorderSizePixel=0,Size=UDim2.new(1,-16,0,1),LayoutOrder=#pd.Container:GetChildren()+1,ZIndex=59})
end

function GlassUI:CreateButton(panelName, text, callback)
    local pd = self.CategoryPanels[panelName]
    if not pd then return end
    local S = self.Settings

    local f = self:Create("Frame",{Name="Button",Parent=pd.Container,BackgroundColor3=Color3.fromRGB(25,25,45),BackgroundTransparency=0.6,BorderSizePixel=0,Size=UDim2.new(1,0,0,32),LayoutOrder=#pd.Container:GetChildren()+1,ZIndex=59})
    self:CreateCorner(f, UDim.new(0,8))

    local lbl = self:Create("TextLabel",{Name="Text",Parent=f,BackgroundTransparency=1,Text=text,TextColor3=S.TextColor,TextSize=13,FontFace=S.FontBold,Size=UDim2.new(1,0,1,0),ZIndex=60})

    local btn = self:Create("TextButton",{Parent=f,BackgroundTransparency=1,Text="",Size=UDim2.new(1,0,1,0),ZIndex=61,AutoButtonColor=false})
    btn.MouseButton1Click:Connect(function()
        self:Tween(f,  {BackgroundColor3=S.AccentColor},0.1)
        self:Tween(lbl,{TextTransparency=0.3},0.1)
        task.wait(0.1)
        self:Tween(f,  {BackgroundColor3=Color3.fromRGB(25,25,45)},0.2)
        self:Tween(lbl,{TextTransparency=0},0.2)
        if callback then callback() end
    end)

    f.MouseEnter:Connect(function() self:Tween(f,{BackgroundColor3=Color3.fromRGB(35,35,60)},0.15) end)
    f.MouseLeave:Connect(function() self:Tween(f,{BackgroundColor3=Color3.fromRGB(25,25,45)},0.15) end)

    return f
end

-- ============================================================
--  NOTIFICATIONS
-- ============================================================

function GlassUI:_BuildNotifications()
    self.NotifContainer = self:Create("Frame",{
        Name="NotifContainer",Parent=self.MainFrame,
        BackgroundTransparency=1,
        Position=UDim2.new(1,-16,0.5,0),AnchorPoint=Vector2.new(1,0.5),
        Size=UDim2.new(0,280,0,400),ZIndex=200,
    })
    self:Create("UIListLayout",{Parent=self.NotifContainer,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8),VerticalAlignment=Enum.VerticalAlignment.Bottom})
end

function GlassUI:Notify(title, message, duration, notifType)
    duration  = duration  or 3
    notifType = notifType or "info"
    local S   = self.Settings

    local accent = S.AccentColor
    if notifType=="success" then accent=S.SuccessColor
    elseif notifType=="error" then accent=S.DangerColor
    elseif notifType=="warning" then accent=S.WarningColor end

    local f = self:Create("Frame",{Name="Notification",Parent=self.NotifContainer,BackgroundColor3=S.PanelColor,BackgroundTransparency=0.15,BorderSizePixel=0,Size=UDim2.new(1,0,0,0),ZIndex=201,ClipsDescendants=true})
    self:CreateCorner(f, UDim.new(0,10))
    self:CreateStroke(f, S.BorderColor, 1)

    local top = self:Create("Frame",{Parent=f,BackgroundColor3=accent,BorderSizePixel=0,Size=UDim2.new(1,0,0,3),ZIndex=202})
    self:CreateCorner(top, UDim.new(0,2))

    self:Create("TextLabel",{Parent=f,BackgroundTransparency=1,Text=title,TextColor3=accent,TextSize=13,FontFace=S.FontBold,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.new(0,12,0,10),Size=UDim2.new(1,-24,0,18),ZIndex=202})
    self:Create("TextLabel",{Parent=f,BackgroundTransparency=1,Text=message,TextColor3=S.TextColorDim,TextSize=12,FontFace=S.Font,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Position=UDim2.new(0,12,0,30),Size=UDim2.new(1,-24,0,24),ZIndex=202})

    local progress = self:Create("Frame",{Parent=f,BackgroundColor3=accent,BackgroundTransparency=0.5,BorderSizePixel=0,Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),ZIndex=202})

    self:Tween(f,{Size=UDim2.new(1,0,0,64)},0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    task.delay(0.3, function() self:Tween(progress,{Size=UDim2.new(0,0,0,2)},duration,Enum.EasingStyle.Linear) end)
    task.delay(duration+0.3, function()
        self:Tween(f,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1},0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
        task.wait(0.35) f:Destroy()
    end)
end

-- ============================================================
--  ARRAYLIST
-- ============================================================

function GlassUI:_BuildArraylist()
    self.ArraylistFrame = self:Create("Frame",{
        Name="Arraylist",Parent=self.MainFrame,
        BackgroundTransparency=1,
        Position=UDim2.new(0,16,1,-16),AnchorPoint=Vector2.new(0,1),
        Size=UDim2.new(0,200,0,300),ZIndex=100,
    })
    self:Create("UIListLayout",{Parent=self.ArraylistFrame,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),VerticalAlignment=Enum.VerticalAlignment.Bottom})
    self.ActiveModules = {}
end

function GlassUI:AddToArraylist(name)
    if self.ActiveModules[name] then return end
    local S = self.Settings

    local e = self:Create("Frame",{Name=name,Parent=self.ArraylistFrame,BackgroundColor3=S.PanelColor,BackgroundTransparency=0.3,BorderSizePixel=0,Size=UDim2.new(0,0,0,22),ZIndex=101,ClipsDescendants=true})
    self:CreateCorner(e, UDim.new(0,6))

    local bar = self:Create("Frame",{Parent=e,BackgroundColor3=S.AccentColor,BorderSizePixel=0,Size=UDim2.new(0,3,1,0),ZIndex=102})
    self:CreateCorner(bar, UDim.new(0,2))

    self:Create("TextLabel",{Parent=e,BackgroundTransparency=1,Text=name,TextColor3=S.TextColor,TextSize=12,FontFace=S.Font,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.new(0,10,0.5,0),AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(1,-16,1,0),ZIndex=102})

    self:Tween(e,{Size=UDim2.new(1,0,0,22)},0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    self.ActiveModules[name] = e
end

function GlassUI:RemoveFromArraylist(name)
    local e = self.ActiveModules[name]
    if not e then return end
    self:Tween(e,{Size=UDim2.new(0,0,0,22)},0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    task.wait(0.2) e:Destroy()
    self.ActiveModules[name] = nil
end

-- ============================================================
--  FPS COUNTER
-- ============================================================

function GlassUI:_BuildFPSCounter()
    local S = self.Settings
    self.FPSCounter = self:Create("Frame",{Name="FPSCounter",Parent=self.MainFrame,BackgroundColor3=S.PanelColor,BackgroundTransparency=0.3,BorderSizePixel=0,Position=UDim2.new(0,16,0,72),Size=UDim2.new(0,100,0,22),ZIndex=100,ClipsDescendants=true,Visible=false})
    self:CreateCorner(self.FPSCounter, UDim.new(0,6))
    self:CreateStroke(self.FPSCounter, S.BorderColor, 1)

    local lbl = self:Create("TextLabel",{Parent=self.FPSCounter,BackgroundTransparency=1,Text="FPS: 60 | MS: 0",TextColor3=S.TextColorDim,TextSize=11,FontFace=S.Font,Size=UDim2.new(1,0,1,0),ZIndex=101})

    local fc, last = 0, tick()
    RunService.Heartbeat:Connect(function()
        fc = fc + 1
        if tick()-last >= 1 then
            lbl.Text  = "FPS: "..math.floor(fc/(tick()-last)).." | MS: "..math.floor(LocalPlayer:GetNetworkPing()*1000)
            fc, last  = 0, tick()
        end
    end)
end

-- ============================================================
--  CURSOR
-- ============================================================

function GlassUI:_BuildCursor()
    local S = self.Settings
    self.CursorDot = self:Create("Frame",{Parent=self.MainFrame,BackgroundColor3=S.AccentColor,BackgroundTransparency=0.3,BorderSizePixel=0,Size=UDim2.new(0,8,0,8),ZIndex=999,Visible=false})
    self:CreateCorner(self.CursorDot, UDim.new(0,4))

    self.CursorRing = self:Create("Frame",{Parent=self.MainFrame,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(0,24,0,24),ZIndex=998,Visible=false})
    self:CreateCorner(self.CursorRing, UDim.new(0,12))
    self:CreateStroke(self.CursorRing, S.AccentColor, 1.5)

    RunService.RenderStepped:Connect(function()
        if self.menuVisible then
            local mp = UserInputService:GetMouseLocation()
            self.CursorDot.Visible  = true
            self.CursorRing.Visible = true
            self.CursorDot.Position  = UDim2.new(0,mp.X-4,0,mp.Y-4)
            local rp = self.CursorRing.Position
            self.CursorRing.Position = UDim2.new(0,self:Lerp(rp.X.Offset,mp.X-12,0.15),0,self:Lerp(rp.Y.Offset,mp.Y-12,0.15))
        else
            self.CursorDot.Visible  = false
            self.CursorRing.Visible = false
        end
    end)
end

-- ============================================================
--  TOOLTIP
-- ============================================================

function GlassUI:_BuildTooltip()
    local S = self.Settings
    self.Tooltip = self:Create("Frame",{Name="Tooltip",Parent=self.MainFrame,BackgroundColor3=Color3.fromRGB(10,10,20),BackgroundTransparency=0.1,BorderSizePixel=0,Size=UDim2.new(0,0,0,0),ZIndex=500,Visible=false,ClipsDescendants=true})
    self:CreateCorner(self.Tooltip, UDim.new(0,6))
    self:CreateStroke(self.Tooltip, S.AccentColor, 1)
    self.TooltipText = self:Create("TextLabel",{Parent=self.Tooltip,BackgroundTransparency=1,Text="",TextColor3=S.TextColor,TextSize=11,FontFace=S.Font,Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,6,0,0),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=501})
end

function GlassUI:ShowTooltip(text, position)
    self.TooltipText.Text   = text
    self.Tooltip.Position   = UDim2.new(0,position.X+16,0,position.Y-10)
    self.Tooltip.Visible    = true
    self:Tween(self.Tooltip,{Size=UDim2.new(0,#text*6+20,0,24)},0.15)
end

function GlassUI:HideTooltip()
    self:Tween(self.Tooltip,{Size=UDim2.new(0,0,0,0)},0.1)
    task.wait(0.1)
    self.Tooltip.Visible = false
end

-- ============================================================
--  MENU TOGGLE
-- ============================================================

function GlassUI:_BindToggleKey()
    self.menuVisible   = false
    self.menuAnimating = false

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self.Settings.ToggleKey then
            if self.menuVisible then self:_HideMenu() else self:_ShowMenu() end
        end
    end)
end

function GlassUI:_ShowMenu()
    if self.menuAnimating then return end
    self.menuAnimating = true
    self.menuVisible   = true
    local S = self.Settings

    self.MenuContainer.Visible  = true
    self.BackgroundDim.Visible  = true
    self.TabBar.Visible         = true
    self.PanelsContainer.Visible= true
    self.SearchBar.Visible      = true
    self.ConfigManager.Visible  = true
    self.FPSCounter.Visible     = true

    self.BackgroundDim.BackgroundTransparency = 1
    self:Tween(self.BackgroundDim,{BackgroundTransparency=0.5},0.4)

    self:_AnimateWatermarkIn()

    self.TabBar.Position = UDim2.new(0.5,0,0,-50)
    self.TabBar.Size     = UDim2.new(0,0,0,44)
    self:Tween(self.TabBar,{Position=UDim2.new(0.5,0,0,60),Size=UDim2.new(0,700,0,44)},0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

    self.PanelsContainer.Size = UDim2.new(0,0,0,400)
    self:Tween(self.PanelsContainer,{Size=UDim2.new(0,700,0,400)},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

    self.SearchBar.Position = UDim2.new(0.5,0,1,50)
    self:Tween(self.SearchBar,{Position=UDim2.new(0.5,0,1,-50)},0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

    self.ConfigManager.Position = UDim2.new(1,50,1,-50)
    self:Tween(self.ConfigManager,{Position=UDim2.new(1,-16,1,-50)},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

    self.FPSCounter.Size = UDim2.new(0,0,0,22)
    self:Tween(self.FPSCounter,{Size=UDim2.new(0,100,0,22)},0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

    self:UpdatePlayerList()

    if not self.ActiveCategory then
        self:SwitchCategory("Combat")
    else
        local curr = self.CategoryPanels[self.ActiveCategory]
        if curr then
            curr.Panel.Visible = true
            curr.Panel.Size    = UDim2.new(0,0,1,0)
            self:Tween(curr.Panel,{Size=UDim2.new(1,0,1,0)},0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        end
    end

    task.delay(0.5, function() self:Notify("Alpha","Меню открыто",2,"info") end)
    task.wait(0.45)
    self.menuAnimating = false
end

function GlassUI:_HideMenu()
    if self.menuAnimating then return end
    self.menuAnimating = true
    self.menuVisible   = false

    self:Tween(self.BackgroundDim,{BackgroundTransparency=1},0.3)
    self:Tween(self.TabBar,{Position=UDim2.new(0.5,0,0,-50),Size=UDim2.new(0,0,0,44)},0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    self:Tween(self.PanelsContainer,{Size=UDim2.new(0,0,0,400)},0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    self:Tween(self.SearchBar,{Position=UDim2.new(0.5,0,1,50)},0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    self:Tween(self.ConfigManager,{Position=UDim2.new(1,50,1,-50)},0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    self:Tween(self.FPSCounter,{Size=UDim2.new(0,0,0,22)},0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    self:Tween(self.PlayerListFrame,{Size=UDim2.new(0,180,0,0)},0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    self:_AnimateWatermarkOut()

    if self.ActiveCategory and self.CategoryPanels[self.ActiveCategory] then
        self:Tween(self.CategoryPanels[self.ActiveCategory].Panel,{Size=UDim2.new(0,0,1,0)},0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    end

    task.wait(0.35)
    self.BackgroundDim.Visible   = false
    self.TabBar.Visible          = false
    self.PanelsContainer.Visible = false
    self.SearchBar.Visible       = false
    self.ConfigManager.Visible   = false
    self.FPSCounter.Visible      = false
    self.MenuContainer.Visible   = false
    self.menuAnimating           = false
end

-- ============================================================
--  ЗАПУСК
-- ============================================================

GlassUI:Init()

return GlassUI
