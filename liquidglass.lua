--!strict
-- Liquid Glass UI — single-file edition inspired by Entity's LiquidGlass
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local Players             = game:GetService("Players")
local Lighting            = game:GetService("Lighting")
local RunService          = game:GetService("RunService")
local GuiService          = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Library = {}
Library.__index = Library

-- ============================================================
-- METRICS (single source of truth, 4px grid)
-- ============================================================
local S = {
    LargeTitle = 24, Title = 17, Body = 15, Subhead = 13, Caption = 11,
    WindowRadius = 26, WindowInset = 8, Gutter = 16, Header = 56,
    Sidebar = 208, SidebarMini = 60, TabRow = 36, TabGap = 2, IconAxis = 30, TextAxis = 52,
    CardRadius = 18, RowInset = 16, RowPadY = 12, RowMin = 48, RowGap = 3,
    Badge = 28, BadgeRadius = 7, RowIcon = 20, IconGap = 12,
    HighlightInset = 4, SectionGap = 20, HeaderGap = 6,
    Control = 30, Field = 170,
    SwitchW = 62, SwitchH = 28, KnobW = 38, KnobH = 24,
    Button = 36, IconButton = 30,
    PopoverRadius = 20, MenuInset = 6, MenuItem = 38,
    Notify = 340, NotifyRadius = 22, NotifyPad = 14, NotifyBadge = 36,
    DialogW = 300, DialogRadius = 26, DialogPad = 20,
}
S.SidebarRadius = S.WindowRadius - S.WindowInset
S.HighlightRadius = S.CardRadius - S.HighlightInset
S.TextX = S.RowInset + S.Badge + S.IconGap
Library.Metrics = S

-- ============================================================
-- THEME
-- ============================================================
local WHITE, BLACK = Color3.new(1,1,1), Color3.new(0,0,0)
local THEMES = {
    Dark = {
        Name = "Dark", Text = WHITE, Text2T = 0.4, Text3T = 0.62,
        Glass = WHITE, GlassT = 0.9, Dim = BLACK, DimT = 0.55, StackDimT = 0.16,
        Card = WHITE, CardT = 0.94, CardRim = 0.5,
        Control = WHITE, ControlT = 0.87, ControlRim = 0.85,
        Track = WHITE, TrackT = 0.8, Separator = WHITE, SeparatorT = 0.9,
        Highlight = WHITE, HighlightT = 0.93, PressT = 0.88,
        Knob = WHITE, Shadow = 0.36, Rim = 1,
        Overlay = BLACK, OverlayT = 0.55, Field = BLACK, FieldT = 0.82,
        Accent = Color3.fromRGB(10, 132, 255), Switch = Color3.fromRGB(48, 209, 88),
        Danger = Color3.fromRGB(255, 69, 58), Warning = Color3.fromRGB(255, 159, 10),
        Success = Color3.fromRGB(48, 209, 88), OnAccent = WHITE,
    },
    Light = {
        Name = "Light", Text = Color3.fromRGB(18,18,22), Text2T = 0.45, Text3T = 0.65,
        Glass = WHITE, GlassT = 0.62, Dim = WHITE, DimT = 0.78, StackDimT = 0.18,
        Card = WHITE, CardT = 0.55, CardRim = 0.85,
        Control = WHITE, ControlT = 0.45, ControlRim = 0.9,
        Track = Color3.fromRGB(120,120,128), TrackT = 0.78, Separator = BLACK, SeparatorT = 0.9,
        Highlight = BLACK, HighlightT = 0.95, PressT = 0.9,
        Knob = WHITE, Shadow = 0.22, Rim = 1,
        Overlay = BLACK, OverlayT = 0.75, Field = BLACK, FieldT = 0.94,
        Accent = Color3.fromRGB(0, 122, 255), Switch = Color3.fromRGB(52, 199, 89),
        Danger = Color3.fromRGB(255, 59, 48), Warning = Color3.fromRGB(255, 149, 0),
        Success = Color3.fromRGB(52, 199, 89), OnAccent = WHITE,
    },
}
Library.Themes = THEMES
local T = THEMES.Dark
local accentOverride = nil

local binds = setmetatable({}, {__mode = "k"})
local function themeValue(token)
    if type(token) == "function" then return token(T) end
    if token == "Accent" and accentOverride then return accentOverride end
    return T[token]
end
local function bind(inst, map)
    binds[inst] = binds[inst] or {}
    for k, v in pairs(map) do binds[inst][k] = v end
    for prop, tok in pairs(map) do
        local v = themeValue(tok)
        if v ~= nil then inst[prop] = v end
    end
end
local function refreshTheme(t)
    for inst, map in pairs(binds) do
        if inst.Parent then
            for prop, tok in pairs(map) do
                local v = themeValue(tok)
                if v ~= nil then
                    TweenService:Create(inst, TweenInfo.new(t or 0.3), {[prop] = v}):Play()
                end
            end
        end
    end
end
function Library:SetTheme(name)
    T = THEMES[name] or (type(name) == "table" and name) or THEMES.Dark
    Library.Settings.Theme = T.Name or "Custom"
    refreshTheme(0.35)
end
function Library:SetAccent(color)
    if type(color) == "string" then
        color = Color3.fromHex(color)
    end
    accentOverride = color
    refreshTheme(0.25)
end

-- ============================================================
-- INSTANCE HELPERS
-- ============================================================
local function new(class, props, children)
    local i = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else i[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = i end
    if parent then i.Parent = parent end
    return i
end
local function corner(r) return new("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function stroke(color, transparency, thickness)
    return new("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or WHITE, Transparency = transparency or 0.6,
        Thickness = thickness or 1,
    })
end
local function pad(t, r, b, l)
    return new("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or t or 0),
        PaddingBottom = UDim.new(0, b or t or 0), PaddingLeft = UDim.new(0, l or r or t or 0),
    })
end
local function list(gap, direction, alignment)
    return new("UIListLayout", {
        Padding = UDim.new(0, gap or 0),
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = alignment or Enum.VerticalAlignment.Center,
    })
end
local function tween(obj, time, props, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
local function fire(cb, ...)
    if type(cb) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(cb, table.unpack(args, 1, args.n))
        if not ok then warn("[LiquidGlass] " .. tostring(err)) end
    end)
end

-- ============================================================
-- POINTER + SPRINGS
-- ============================================================
local GUI = new("ScreenGui", {
    Name = "LiquidGlass", IgnoreGuiInset = true,
    ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 10000, AutoLocalize = false,
})
pcall(function() GUI.ScreenInsets = Enum.ScreenInsets.None end)
GUI.Parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
Library.Gui = GUI
Library.ScaleObject = new("UIScale", {Parent = GUI})

local POSITIONAL = {
    [Enum.UserInputType.MouseButton1] = true, [Enum.UserInputType.MouseMovement] = true,
    [Enum.UserInputType.Touch] = true, [Enum.UserInputType.MouseWheel] = true,
}
local lastPointer
local function pointer(input)
    if input and POSITIONAL[input.UserInputType] then
        return Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
    end
    return lastPointer or UserInputService:GetMouseLocation()
end
UserInputService.InputChanged:Connect(function(input)
    if POSITIONAL[input.UserInputType] then lastPointer = pointer(input) end
end)
UserInputService.InputBegan:Connect(function(input)
    if POSITIONAL[input.UserInputType] then lastPointer = pointer(input) end
end)

local function screenPos(obj)
    return obj.AbsolutePosition - GUI.AbsolutePosition
end
local function inside(obj, p)
    p = p or pointer()
    local pos, size = screenPos(obj), obj.AbsoluteSize
    return p.X >= pos.X and p.Y >= pos.Y and p.X <= pos.X + size.X and p.Y <= pos.Y + size.Y
end
local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- Sprung offset driver: springs[pos]=inst stores `vel` and `target`; positions are
-- applied every render step as (scale, offset) preserving the scale parts
local springs = setmetatable({}, {__mode = "k"})
local function springTo(inst, target, speed, damping)
    local s = springs[inst]
    if not s then
        s = {pos = Vector2.new(inst.Position.X.Offset, inst.Position.Y.Offset), vel = Vector2.zero}
        springs[inst] = s
    end
    s.target, s.speed, s.damping = target, speed or 30, damping or 1
end
local function springTarget(inst)
    local s = springs[inst]
    return s and s.target or Vector2.new(inst.Position.X.Offset, inst.Position.Y.Offset)
end
local function springStop(inst) springs[inst] = nil end

RunService.RenderStepped:Connect(function(dt)
    local steps = math.clamp(math.ceil(dt * 240), 1, 16)
    local h = dt / steps
    for inst, s in pairs(springs) do
        if not inst.Parent then springs[inst] = nil; continue end
        local w, z = s.speed, s.damping
        for _ = 1, steps do
            s.vel += ((s.target - s.pos) * (w*w) - s.vel * (2*z*w)) * h
            s.pos += s.vel * h
        end
        if (s.target - s.pos).Magnitude < 0.02 and s.vel.Magnitude < 0.5 then
            s.pos, s.vel = s.target, Vector2.zero
            springs[inst] = nil
        end
        local p = inst.Position
        inst.Position = UDim2.new(p.X.Scale, s.pos.X, p.Y.Scale, s.pos.Y)
    end
end)

local function drag(hit, cb)
    local active, start, moved, touch, last = false, nil, false, nil, nil
    local function finish(input)
        active = false
        local p = input and pointer(input) or last
        if p and last and p ~= last and cb.moved then
            moved = moved or (p - start).Magnitude > 4
            last = p
            cb.moved(p, p - start, moved)
        end
        if cb.ended then cb.ended(p or start, moved, input) end
    end
    hit.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        if cb.allow and not cb.allow() then return end
        if active then finish(nil) end
        active, moved = true, false
        start = pointer(input); last = start
        touch = input.UserInputType == Enum.UserInputType.Touch and input or nil
        if cb.began then cb.began(start) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not active then return end
        local mouseMove = input.UserInputType == Enum.UserInputType.MouseMovement and not touch
        if mouseMove or (touch and input == touch) then
            local p = pointer(input)
            if p == last then return end
            last = p
            moved = moved or (p - start).Magnitude > 4
            if cb.moved then cb.moved(p, p - start, moved) end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if active and isPress(input) and (not touch or input == touch) then
            finish(input)
        end
    end)
end

-- ============================================================
-- BLUR: DepthOfField + camera-parented glass part tracking the whole UI
-- ============================================================
local camera = workspace.CurrentCamera
local blurFolder, dof, glassPart
local PART_DISTANCE = 0.02
local PAD = 8

local function initBlur()
    camera = workspace.CurrentCamera
    if not camera then return end
    if not blurFolder then
        blurFolder = new("Folder", {Name = "LiquidGlassBlur"})
    end
    blurFolder.Parent = camera
    if not dof or not dof.Parent then
        dof = new("DepthOfFieldEffect", {
            Name = "LiquidGlassDOF",
            FocusDistance = 0.05,
            InFocusRadius = 0.02,
            NearIntensity = 1,
            FarIntensity = 0,
            Enabled = false,
        })
    end
    dof.Parent = camera
    if not glassPart or not glassPart.Parent then
        glassPart = new("Part", {
            Name = "Glass", Material = Enum.Material.Glass,
            Transparency = 1, Color = WHITE,
            Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
            CastShadow = false, Size = Vector3.new(1, 1, 0.01),
            Parent = blurFolder,
        })
    end
end
initBlur()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(initBlur)

local function updateBlur()
    if not camera or not camera.Parent then initBlur(); if not camera then return end end
    if not Library.Settings.Blur or Library.Unloaded or not Library.Root then
        if glassPart then glassPart.Transparency = 1 end
        if dof then dof.Enabled = false end
        return
    end
    local ap = Library.Root.AbsolutePosition
    local as = Library.Root.AbsoluteSize
    if as.X < 2 or as.Y < 2 or not Library.Root.Visible then
        if glassPart then glassPart.Transparency = 1 end
        if dof then dof.Enabled = false end
        return
    end
    local c = camera
    local function toWorld(x, y)
        local ray = c:ScreenPointToRay(x, y)
        return ray.Origin + ray.Direction * PART_DISTANCE
    end
    local tl = toWorld(ap.X - PAD, ap.Y - PAD)
    local tr = toWorld(ap.X + as.X + PAD, ap.Y - PAD)
    local br = toWorld(ap.X + as.X + PAD, ap.Y + as.Y + PAD)
    local w = (tr - tl).Magnitude
    local h = (tr - br).Magnitude
    glassPart.CFrame = CFrame.fromMatrix((tl + br) / 2, c.CFrame.XVector, c.CFrame.YVector, c.CFrame.ZVector)
    glassPart.Size = Vector3.new(w, h, 0.01)
    glassPart.Transparency = 0.98
    dof.Enabled = true
end
RunService:BindToRenderStep("LiquidGlassBlur", Enum.RenderPriority.Camera.Value + 1, updateBlur)

-- ============================================================
-- GLASS PRIMITIVE — the building block every surface uses
-- ============================================================
local RIM_MIN, RIM_MAX = 4, 40

local function glassSurface(o)
    local kind = o.Kind or "Card"
    local r = o.Radius or 16
    local root = new("Frame", {
        Name = o.Name or kind,
        BackgroundTransparency = 1,
        Position = o.Position or UDim2.new(),
        Size = o.Size or UDim2.fromScale(1, 1),
        AnchorPoint = o.AnchorPoint or Vector2.zero,
        ZIndex = o.ZIndex or 1,
        LayoutOrder = o.LayoutOrder or 0,
        Parent = o.Parent,
    })
    local g = {Root = root, Radius = r, Kind = kind}
    g.Scale = new("UIScale", {Parent = root})

    -- dim overlay (dark layer under the tint — the main "frosted" body)
    if kind == "Surface" then
        g.Dim = new("Frame", {
            Name = "Dim", BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = root,
        }, {corner(r)})
        bind(g.Dim, {BackgroundColor3 = "Dim", BackgroundTransparency = o.Dense and "StackDimT" or "DimT"})
    end

    -- fill + optional tint gradient
    g.Fill = new("Frame", {
        Name = "Fill", BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = root,
    }, {corner(r)})
    local fillToken = ({Surface = "Glass", Card = "Card", Control = "Control",
        Tinted = o.Tint or "Accent", Solid = "Knob"})[kind] or "Card"
    local fillT = ({
        Surface = "GlassT", Card = "CardT", Control = "ControlT",
        Tinted = o.TintTransparency or 0.06, Solid = 0,
    })[kind]
    if typeof(fillToken) == "Color3" then
        g.Fill.BackgroundColor3 = fillToken
        g.Fill.BackgroundTransparency = type(fillT) == "number" and fillT or 0.06
    else
        bind(g.Fill, {BackgroundColor3 = fillToken, BackgroundTransparency = fillT or 0})
    end
    if kind == "Surface" or kind == "Tinted" then
        new("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.45, 0.35),
                NumberSequenceKeypoint.new(1, 0.15),
            }),
            Parent = g.Fill,
        })
    end

    -- rim (gradient border)
    local rimT = ({Surface = "Rim", Card = "CardRim", Control = "ControlRim",
        Tinted = 0.65, Solid = 0})[kind] or "CardRim"
    local rim = new("ImageLabel", {
        Name = "Rim", BackgroundTransparency = 1, Image = "", -- no texture, use stroke
        Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = root,
    })
    rim:Destroy() -- placeholder, we'll use UIStroke
    local rimStroke = stroke(WHITE, 1, 1)
    rimStroke.Parent = g.Fill
    bind(rimStroke, {Color = rimT == "Tinted" and "Accent" or "Border", Transparency = function(t)
        local v = type(rimT) == "number" and rimT or t[rimT]
        return 1 - (v or 1)
    end})
    g.Rim = rimStroke

    -- content wrapper (children go here, ZIndex 5 keeps them above fill/rim)
    local auto = o.AutomaticSize
    if auto == Enum.AutomaticSize.None then auto = nil end
    g.Content = new("Frame", {
        Name = "Content", BackgroundTransparency = 1,
        Size = (auto == Enum.AutomaticSize.XY and UDim2.new())
            or (auto == Enum.AutomaticSize.X and UDim2.fromScale(0, 1))
            or (auto and UDim2.fromScale(1, 0))
            or UDim2.fromScale(1, 1),
        AutomaticSize = auto or Enum.AutomaticSize.None,
        ZIndex = 5, Parent = root,
    })

    function g.SetTint(color, transparency, time)
        if transparency then
            binds[g.Fill] = binds[g.Fill] or {}
            binds[g.Fill].BackgroundColor3 = nil
            binds[g.Fill].BackgroundTransparency = nil
            if time then
                tween(g.Fill, time, {BackgroundColor3 = color, BackgroundTransparency = transparency})
            else
                g.Fill.BackgroundColor3 = color
                g.Fill.BackgroundTransparency = transparency
            end
        else
            if time then
                tween(g.Fill, time, {BackgroundColor3 = color})
            else
                g.Fill.BackgroundColor3 = color
            end
        end
    end

    return g
end

local function text(o)
    local l = new("TextLabel", {
        Name = o.Name or "Text",
        BackgroundTransparency = 1,
        Text = o.Text or "",
        FontFace = o.Font or Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular),
        TextSize = o.TextSize or S.Body,
        TextXAlignment = o.XAlign or Enum.TextXAlignment.Left,
        TextYAlignment = o.YAlign or Enum.TextYAlignment.Center,
        TextWrapped = o.Wrap or false,
        TextTruncate = o.Truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
        Position = o.Position or UDim2.new(),
        Size = o.Size or UDim2.new(1, 0, 0, (o.TextSize or S.Body) + 4),
        AnchorPoint = o.AnchorPoint or Vector2.zero,
        ZIndex = o.ZIndex or 6,
        LayoutOrder = o.LayoutOrder or 0,
        Parent = o.Parent,
    })
    local level = o.Level or 1
    bind(l, {
        TextColor3 = o.Color or "Text",
        TextTransparency = function(t)
            return level == 1 and 0 or level == 2 and t.Text2T or t.Text3T
        end,
    })
    return l
end

local function icon(o)
    local img = new("ImageLabel", {
        Name = o.Name or "Icon",
        BackgroundTransparency = 1,
        Image = o.Image or "",
        Size = UDim2.fromOffset(o.Size or 18, o.Size or 18),
        Position = o.Position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = o.AnchorPoint or Vector2.new(0.5, 0.5),
        ImageColor3 = WHITE,
        ZIndex = o.ZIndex or 6,
        Parent = o.Parent,
    })
    local level = o.Level or 1
    bind(img, {
        ImageColor3 = o.Color or "Text",
        ImageTransparency = function(t)
            return level == 1 and 0 or level == 2 and t.Text2T or t.Text3T
        end,
    })
    return img
end

-- ============================================================
-- WINDOW
-- ============================================================
local Window = {}
Window.__index = Window
Library._classes = {Window = Window}

function Library:CreateWindow(o)
    o = o or {}
    if o.Theme then Library:SetTheme(o.Theme) end
    if o.Accent then Library:SetAccent(o.Accent) end

    local self = setmetatable({
        Tabs = {}, Title = o.Title or "LiquidGlass", Subtitle = o.Subtitle,
        Visible = true, Minimized = false, Collapsed = false,
        MinSize = Vector2.new(480, 340), Opts = o,
    }, Window)
    Library.Windows = Library.Windows or {}
    table.insert(Library.Windows, self)
    if o.Scale then Library:SetScale(o.Scale) end

    local scale = Library.ScaleObject.Scale or 1
    local vs = (camera and camera.ViewportSize or Vector2.new(1280, 720)) / scale
    local size = o.Size or Vector2.new(700, 480)
    size = Vector2.new(math.clamp(size.X, 480, vs.X - 40), math.clamp(size.Y, 340, vs.Y - 80))
    local pos = (vs - size) / 2

    local g = glassSurface({
        Kind = "Surface", Name = "Window", Parent = GUI,
        Radius = S.WindowRadius,
        Position = UDim2.fromOffset(math.floor(pos.X), math.floor(pos.Y)),
        Size = UDim2.fromOffset(size.X, size.Y),
        ZIndex = 10,
    })
    self.Glass, self.Root = g, g.Root
    Library.Root = g.Root -- blur tracks this
    self.Body = new("Frame", {
        Name = "Body", BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = g.Content,
    })

    g.Root.InputBegan:Connect(function(input)
        if isPress(input) then self:Focus() end
    end)

    self:_buildSidebar(o)
    self:_buildMain(o)
    self:_layout(true)

    -- open animation
    g.Scale.Scale = 0.9
    g.Dim.BackgroundTransparency = 1
    tween(g.Dim, 0.4, {BackgroundTransparency = themeValue("DimT")})
    tween(g.Fill, 0.4, {BackgroundTransparency = themeValue("GlassT")})
    tween(g.Scale, 0.55, {Scale = 1}, Enum.EasingStyle.Back)

    -- drag handle
    local handle = new("TextButton", {
        Name = "DragHandle", BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1, 0, 0, S.Header), ZIndex = 4, Parent = g.Content,
    })
    local startPos
    drag(handle, {
        began = function() startPos = springTarget(g.Root) end,
        moved = function(_, delta, moved)
            if moved then
                local s = Library.ScaleObject.Scale
                springTo(g.Root, startPos + delta / s, 26, 1)
            end
        end,
    })

    -- toggle key
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if (Library.ToggleKey or Enum.KeyCode.RightControl) == input.KeyCode then
            self:Toggle()
        end
    end)

    return self
end

function Window:Focus()
    if self.Root.ZIndex < 50 then
        for _, w in ipairs(Library.Windows or {}) do
            if w.Root.ZIndex >= 50 then w.Root.ZIndex -= 10 end
        end
        self.Root.ZIndex = 50
    end
end

function Window:_buildSidebar(o)
    local sb = glassSurface({
        Kind = "Card", Name = "Sidebar", Parent = self.Body,
        Radius = S.SidebarRadius,
        Position = UDim2.fromOffset(S.WindowInset, S.WindowInset),
        Size = UDim2.new(0, S.Sidebar, 1, -2 * S.WindowInset),
        ZIndex = 2,
    })
    self.Sidebar = sb
    local c = sb.Content
    c.ClipsDescendants = true

    -- brand (height = header, text baseline shared)
    local brand = new("Frame", {Name = "Brand", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, S.Header), ZIndex = 6, Parent = c})
    local badge = glassSurface({
        Kind = "Tinted", Parent = brand, Radius = S.BadgeRadius,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(S.IconAxis, S.Header / 2),
        Size = UDim2.fromOffset(S.Badge, S.Badge), ZIndex = 6,
    })
    icon({Parent = badge.Content, Image = "", Size = 16, Level = 1, Color = "OnAccent"})
    self.TitleLabel = text({Parent = brand, Text = self.Title, Level = 1,
        TextSize = S.Body, Truncate = true,
        Position = UDim2.fromOffset(S.TextAxis, S.Header / 2 - 10),
        Size = UDim2.new(1, -S.TextAxis - 8, 0, 19)})
    self.SubtitleLabel = text({Parent = brand, Text = self.Subtitle or "", Level = 2,
        TextSize = S.Caption,
        Position = UDim2.fromOffset(S.TextAxis, S.Header / 2 + 1),
        Size = UDim2.new(1, -S.TextAxis - 8, 0, 15)})
    self.SubtitleLabel.Visible = (self.Subtitle or "") ~= ""

    -- search
    local top = S.Header
    local searchH = S.Control + 2
    local search = glassSurface({
        Kind = "Control", Name = "Search", Parent = c, Radius = searchH / 2,
        Position = UDim2.fromOffset(S.WindowInset, top),
        Size = UDim2.new(1, -2 * S.WindowInset, 0, searchH), ZIndex = 6,
    })
    icon({Parent = search.Content, Image = "", Size = 14, Level = 3,
        Position = UDim2.fromOffset(S.IconAxis - S.WindowInset, searchH / 2)})
    self.SearchBox = new("TextBox", {
        BackgroundTransparency = 1, Text = "", PlaceholderText = "Search",
        ClearTextOnFocus = false, TextSize = S.Subhead,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(S.TextAxis - S.WindowInset, 0),
        Size = UDim2.new(1, -(S.TextAxis - S.WindowInset) - 12, 1, 0),
        ZIndex = 7, Parent = search.Content,
    })
    bind(self.SearchBox, {TextColor3 = "Text", PlaceholderColor3 = "Text", TextTransparency = function() return 0 end})
    self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if self.ActiveTab then self.ActiveTab:_filter(self.SearchBox.Text) end
    end)
    self.Search = search
    top += searchH + S.WindowInset
    self.TabTop = top

    -- tab list
    self.TabList = new("ScrollingFrame", {
        Name = "Tabs", BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, top),
        Size = UDim2.new(1, 0, 1, -top - S.Header),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 6, Parent = c,
    })
    self.TabItems = new("Frame", {Name = "Items", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 8, Parent = self.TabList}, {
        list(S.TabGap),
        pad(0, S.WindowInset, S.WindowInset, S.WindowInset),
    })

    -- selection pill (under items, above sidebar)
    self.TabPill = glassSurface({
        Kind = "Control", Name = "Selection", Parent = self.TabList,
        Radius = S.CardRadius - 4,
        Size = UDim2.new(1, -2 * S.WindowInset, 0, S.TabRow),
        Position = UDim2.fromOffset(S.WindowInset, 0),
        ZIndex = 7,
    })
    self.TabPill.Root.Visible = false
endfunction Window:_buildMain(o)
    local main = new("Frame", {Name = "Main", BackgroundTransparency = 1, ZIndex = 3, Parent = self.Body})
    self.Main = main
    self.Header = new("Frame", {Name = "Header", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, S.WindowInset),
        Size = UDim2.new(1, 0, 0, S.Header), ZIndex = 4, Parent = main})
    local g = S.Gutter
    self.TitleX = g + 4
    self.PageTitle = text({
        Parent = self.Header, Text = "", Level = 1,
        Font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
        TextSize = S.LargeTitle, Truncate = true,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, self.TitleX, 0.5, 0),
        Size = UDim2.new(1, -self.TitleX - g - 2 * S.IconButton - 16, 0, S.LargeTitle + 6),
    })

    self.CloseButton = self:_iconButton("X", function() self:Destroy() end,
        UDim2.new(1, -g, 0.5, 0), Vector2.new(1, 0.5))
    self.MinimizeButton = self:_iconButton("_", function() self:Minimize() end,
        UDim2.new(1, -g - S.IconButton - 8, 0.5, 0), Vector2.new(1, 0.5))

    self.Pages = new("Frame", {
        Name = "Pages", BackgroundTransparency = 1, ClipsDescendants = true,
        Position = UDim2.fromOffset(g - 4, S.WindowInset + S.Header),
        Size = UDim2.new(1, -2 * (g - 4), 1, -(S.WindowInset + S.Header) - S.WindowInset),
        ZIndex = 4, Parent = main,
    })
end

function Window:_iconButton(glyph, cb, pos, anchor)
    local b = glassSurface({
        Kind = "Control", Parent = self.Header, Radius = S.IconButton / 2,
        Size = UDim2.fromOffset(S.IconButton, S.IconButton),
        AnchorPoint = anchor, Position = pos, ZIndex = 8,
    })
    local lbl = text({Parent = b.Content, Text = glyph, Level = 2, TextSize = 14,
        XAlign = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 9})
    local hit = new("TextButton", {BackgroundTransparency = 1, Text = "",
        Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = b.Content})
    hit.MouseEnter:Connect(function() tween(lbl, 0.15, {TextColor3 = themeValue("Accent")}) end)
    hit.MouseLeave:Connect(function() tween(lbl, 0.15, {TextColor3 = themeValue("Text")}) end)
    hit.Activated:Connect(cb)
    return b
end

function Window:_layout(instant)
    local w = self.Root.Size.X.Offset
    local collapsed = w < 600
    local sw = collapsed and S.SidebarMini or S.Sidebar
    if collapsed ~= self.Collapsed or instant then
        self.Collapsed = collapsed
        local t = instant and 0 or 0.35
        if t == 0 then
            self.Sidebar.Root.Size = UDim2.new(0, sw, 1, -2 * S.WindowInset)
            self.Main.Position = UDim2.fromOffset(S.WindowInset + sw, 0)
            self.Main.Size = UDim2.new(1, -(S.WindowInset + sw), 1, 0)
        else
            tween(self.Sidebar.Root, t, {Size = UDim2.new(0, sw, 1, -2 * S.WindowInset)})
            tween(self.Main, t, {Position = UDim2.fromOffset(S.WindowInset + sw, 0)})
            tween(self.Main, t, {Size = UDim2.new(1, -(S.WindowInset + sw), 1, 0)})
        end
        self.TitleLabel.Visible = not collapsed
        self.Search.Root.Visible = not collapsed
        for _, tab in ipairs(self.Tabs) do
            tab.Label.Visible = not collapsed
        end
        local top = (not collapsed) and self.TabTop or S.Header
        if t == 0 then
            self.TabList.Position = UDim2.fromOffset(0, top)
            self.TabList.Size = UDim2.new(1, 0, 1, -top - S.Header)
        else
            tween(self.TabList, t, {Position = UDim2.fromOffset(0, top)})
            tween(self.TabList, t, {Size = UDim2.new(1, 0, 1, -top - S.Header)})
        end
    end
end

function Window:Toggle()
    if self.Minimized then self:Restore() else self:SetVisible(not self.Visible) end
end

function Window:SetVisible(on, silent)
    on = on and true or false
    if on == self.Visible and not self.Minimized then return end
    self.Visible = on
    local g = self.Glass
    if on then
        g.Root.Visible = true
        self:Focus()
        g.Scale.Scale = 0.94
        tween(g.Scale, 0.55, {Scale = 1}, Enum.EasingStyle.Back)
        tween(g.Dim, 0.3, {BackgroundTransparency = themeValue("DimT")})
        tween(g.Fill, 0.3, {BackgroundTransparency = themeValue("GlassT")})
    else
        tween(g.Scale, 0.25, {Scale = 0.94})
        tween(g.Dim, 0.22, {BackgroundTransparency = 1})
        tween(g.Fill, 0.22, {BackgroundTransparency = 1})
        task.delay(0.25, function()
            if not self.Visible then g.Root.Visible = false end
        end)
    end
end

function Window:Minimize()
    if self.Minimized then return end
    self:SetVisible(false, true)
    self.Minimized = true
end
function Window:Restore()
    if not self.Minimized then return end
    self.Minimized = false
    self.Visible = false
    self:SetVisible(true)
end

function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    self:SetVisible(false)
    task.delay(0.3, function() self.Root:Destroy() end)
    local i = table.find(Library.Windows, self)
    if i then table.remove(Library.Windows, i) end
end

-- ============================================================
-- TAB
-- ============================================================
local Tab = {}
Tab.__index = Tab

function Window:AddTab(o)
    if type(o) == "string" then o = {Title = o} end
    o = o or {}
    local tab = setmetatable({
        Window = self, Title = o.Title or "Tab", Icon = o.Icon,
        Sections = {}, Index = #self.Tabs + 1, Elements = {},
    }, Tab)
    table.insert(self.Tabs, tab)

    -- sidebar button
    local b = new("Frame", {Name = "Tab_" .. tab.Title, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, S.TabRow), LayoutOrder = tab.Index,
        ZIndex = 9, Parent = self.TabItems})
    tab.Button = b
    tab.IconImage = icon({Parent = b, Image = o.Icon or "",
        Size = 18, Position = UDim2.fromOffset(S.IconAxis - S.WindowInset, S.TabRow / 2)})
    tab.Label = text({Parent = b, Text = tab.Title, Level = 2,
        TextSize = S.Body, Truncate = true,
        Position = UDim2.fromOffset(S.TextAxis - S.WindowInset, 0),
        Size = UDim2.new(1, -(S.TextAxis - S.WindowInset) - 8, 1, 0), ZIndex = 9})
    local hit = new("TextButton", {BackgroundTransparency = 1, Text = "",
        Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = b})
    hit.Activated:Connect(function() self:SelectTab(tab) end)
    hit.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(b, 0.15, {BackgroundTransparency = 0.7})
        end
    end)
    hit.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(b, 0.15, {BackgroundTransparency = 1})
        end
    end)

    -- page
    tab.Page = new("ScrollingFrame", {
        Name = "Page_" .. tab.Title, BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false, ZIndex = 4, Parent = self.Pages,
    }, {
        list(S.SectionGap), pad(4, 4, S.Gutter, 4),
    })

    self.TabPill.Root.Visible = true
    if not self.ActiveTab then self:SelectTab(tab, true) end
    return tab
end

function Window:SelectTab(tab, instant)
    if not tab or tab == self.ActiveTab then return end
    local old = self.ActiveTab
    self.ActiveTab = tab
    if old then old.Page.Visible = false end
    tab.Page.Visible = true
    self.PageTitle.Text = tab.Title

    -- animate pill to slot
    local slot = UDim2.fromOffset(S.WindowInset, (tab.Index - 1) * (S.TabRow + S.TabGap))
    if instant then
        springStop(self.TabPill.Root)
        self.TabPill.Root.Position = slot
    else
        springTo(self.TabPill.Root, Vector2.new(slot.X.Offset, slot.Y.Offset), 24, 0.55)
    end

    -- paint
    for _, t in ipairs(self.Tabs) do
        local selected = t == tab
        bind(t.IconImage, {ImageColor3 = selected and "Accent" or "Text",
            ImageTransparency = function(tt) return selected and 0 or tt.Text2T end})
        bind(t.Label, {TextTransparency = function(tt) return selected and 0 or tt.Text2T end})
        t.Label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json",
            selected and Enum.FontWeight.SemiBold or Enum.FontWeight.Regular)
    end

    if not instant then
        tab.Page.Position = UDim2.fromOffset(0, 14)
        tween(tab.Page, 0.45, {Position = UDim2.new()})
    end
    fire(self.Opts.OnTabChanged, tab)
end

function Tab:_filter(query)
    query = (query or ""):lower()
    for _, section in ipairs(self.Sections) do
        local any = false
        for _, el in ipairs(section.Elements) do
            local hay = ((el.TitleText or "") .. " " .. (el.DescText or "")):lower()
            local match = query == "" or hay:find(query, 1, true) ~= nil
            el._filtered = not match
            if el.Row then el.Row.Frame.Visible = not el._hidden and match end
            any = any or (match and not el._hidden)
        end
        section.Frame.Visible = (query == "" or any) and not section._hidden
    end
    self.Window.PageTitle.Text = query == "" and self.Title or ("Results for “" .. query .. "”")
end

-- ============================================================
-- SECTION
-- ============================================================
local Section = {}
Section.__index = Section

function Tab:AddSection(o)
    if type(o) ~= "table" then o = {Title = o} end
    local section = setmetatable({Tab = self, Title = o.Title, Elements = {}, Order = 0}, Section)
    section.Frame = new("Frame", {Name = "Section", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #self.Sections + 1, ZIndex = 4, Parent = self.Page}, {
        list(S.HeaderGap),
    })
    if o.Title then
        section.Header = text({Parent = section.Frame, Text = o.Title:upper(),
            Level = 2, TextSize = S.Caption,
            Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 0})
        pad(S.RowInset, S.RowInset, 0, 0).Parent = section.Header
    end
    section.Card = glassSurface({
        Kind = "Card", Name = "Card", Parent = section.Frame, Radius = S.CardRadius,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1, ZIndex = 4,
    })
    section.Rows = section.Card.Content
    list(0).Parent = section.Rows
    table.insert(self.Sections, section)
    self.CurrentSection = section
    return section
end
Tab.CreateSection = Tab.AddSection

function Tab:_section()
    return self.CurrentSection or self:AddSection({})
end

function Section:_order()
    self.Order += 1
    return self.Order
end

-- list row
function Section:_row(o)
    local row = {Section = self}
    local minH = o.MinHeight or S.RowMin
    local padY = o.PadY or S.RowPadY
    row.Frame = new("Frame", {Name = "Row", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = self:_order(), ZIndex = 5, Parent = self.Rows})
    row.Highlight = new("Frame", {Name = "Highlight", BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(S.HighlightInset, 2),
        Size = UDim2.new(1, -2 * S.HighlightInset, 1, -4),
        ZIndex = 5, Parent = row.Frame}, {corner(S.HighlightRadius)})
    bind(row.Highlight, {BackgroundColor3 = "Highlight"})

    local left = S.RowInset
    if o.Icon then
        row.IconImage = icon({Parent = row.Frame, Image = o.Icon,
            Size = S.RowIcon, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, S.RowInset + S.Badge / 2, 0.5, 0), Level = 1, ZIndex = 6})
        left = S.TextX
    end
    local rightW = o.Right or 0
    row.Line = new("Frame", {Name = "Line", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(left, 0),
        Size = UDim2.new(1, -(left + S.RowInset + (rightW > 0 and rightW + S.IconGap or 0)), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 6, Parent = row.Frame}, {
        list(0, Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center),
    })
    row.Strut = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.fromOffset(0, minH), LayoutOrder = 0, Parent = row.Line})
    row.Body = new("Frame", {Name = "Body", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1, ZIndex = 6, Parent = row.Line}, {
        pad(padY, 0, padY, 0), list(S.RowGap),
    })
    row.Title = text({Parent = row.Body, Text = o.Title or "", Level = 1,
        Font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
        TextSize = S.Body, Wrap = true, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1})
    row.Title.Visible = (o.Title or "") ~= ""
    row.Desc = text({Parent = row.Body, Text = o.Description or "", Level = 2,
        TextSize = S.Subhead, Wrap = true, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2})
    row.Desc.Visible = (o.Description or "") ~= ""
    row.Right = new("Frame", {Name = "Right", BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -S.RowInset, 0.5, 0),
        Size = UDim2.fromOffset(rightW, S.Control), ZIndex = 8, Parent = row.Frame})
    row.Separator = new("Frame", {Name = "Separator", BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, left, 1, 0),
        Size = UDim2.new(1, -left, 0, 1), ZIndex = 5, Parent = row.Frame})
    bind(row.Separator, {BackgroundColor3 = "Separator", BackgroundTransparency = "SeparatorT"})

    function row.Interactive(onClick)
        local hit = new("TextButton", {BackgroundTransparency = 1, Text = "",
            Size = UDim2.fromScale(1, 1), ZIndex = 7, Parent = row.Frame})
        local hovered = false
        hit.MouseEnter:Connect(function()
            hovered = true
            tween(row.Highlight, 0.2, {BackgroundTransparency = themeValue("HighlightT")})
        end)
        hit.MouseLeave:Connect(function()
            hovered = false
            tween(row.Highlight, 0.2, {BackgroundTransparency = 1})
        end)
        hit.MouseButton1Down:Connect(function()
            tween(row.Highlight, 0.08, {BackgroundTransparency = themeValue("PressT")})
        end)
        UserInputService.InputEnded:Connect(function(input)
            if hovered and isPress(input) then
                tween(row.Highlight, 0.2, {BackgroundTransparency = themeValue("HighlightT")})
            end
        end)
        hit.Activated:Connect(function()
            if onClick then onClick() end
        end)
        row.Hit = hit
        return hit
    end

    return row
end

-- every element gets stored on Section and forwarded to Tab
local function defineElement(name, fn)
    Section[name] = fn
    Tab[name] = function(self, ...)
        return fn(self:_section(), ...)
    end
end

-- ============================================================
-- ELEMENTS
-- ============================================================
local Element = {}
Element.__index = Element
Library._classes.Element = Element

local function normalize(a, b)
    if type(a) == "string" and type(b) == "table" then
        b.Flag = b.Flag or a
        return b
    elseif type(a) == "string" then
        return {Title = a, Callback = type(b) == "function" and b or nil}
    end
    return a or {}
end

function Section:_element(o, kind, rowOpts)
    local el = setmetatable({
        Section = self, Type = kind, Opts = o,
        TitleText = o.Title or "", DescText = o.Description,
        Callback = o.Callback, Flag = o.Flag, Listeners = {},
    }, Element)
    if rowOpts ~= false then
        rowOpts = rowOpts or {}
        rowOpts.Title = rowOpts.Title or el.TitleText
        rowOpts.Description = rowOpts.Description or el.DescText
        rowOpts.Icon = rowOpts.Icon == nil and o.Icon or rowOpts.Icon
        el.Row = self:_row(rowOpts)
    end
    table.insert(self.Elements, el)
    table.insert(self.Tab.Elements, el)
    if el.Flag then
        Library.Options[el.Flag] = el
        Library.Flags[el.Flag] = el
    end
    return el
end

function Element:_emit(...)
    fire(self.Callback, ...)
    for _, fn in ipairs(self.Listeners) do fire(fn, ...) end
end

function Element:_store(v)
    self.Value = v
end
function Element:Get()
    return self.Value
end
function Element:SetVisible(on)
    self._hidden = not on
    if self.Row then self.Row.Frame.Visible = on end
end
function Element:SetDisabled(on)
    self.Disabled = on
end
function Element:OnChanged(fn)
    table.insert(self.Listeners, fn)
    return {Disconnect = function()
        local i = table.find(self.Listeners, fn)
        if i then table.remove(self.Listeners, i) end
    end}
end

-- Toggle
defineElement("AddToggle", function(section, a, b)
    local o = normalize(a, b)
    local el = section:_element(o, "Toggle", {Right = S.SwitchW})
    local row = el.Row
    local on = o.Default and true or false
    el:_store(on)

    local track = new("Frame", {Name = "Switch", BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(S.SwitchW, S.SwitchH), ZIndex = 8, Parent = row.Right},
        {corner(S.SwitchH / 2)})
    local inset = (S.SwitchH - S.KnobH) / 2
    local OFF_X, ON_X = inset, S.SwitchW - S.KnobW - inset
    local knob = glassSurface({
        Kind = "Solid", Name = "Knob", Parent = track, Radius = S.KnobH / 2,
        Size = UDim2.fromOffset(S.KnobW, S.KnobH),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, on and ON_X or OFF_X, 0.5, 0), ZIndex = 9,
    })
    local function paint(state, time)
        local f = state and 1 or 0
        local col = themeValue("Track"):Lerp(themeValue("Switch"), f)
        local tr = themeValue("TrackT") * (1 - f)
        if time then tween(track, time, {BackgroundColor3 = col, BackgroundTransparency = tr})
        else track.BackgroundColor3, track.BackgroundTransparency = col, tr end
    end
    paint(on)
    bind(track, {BackgroundColor3 = function() return themeValue(on and "Switch" or "Track") end})

    local function set(v, silent)
        v = v and true or false
        local changed = v ~= on
        on = v
        el:_store(v)
        local target = Vector2.new(v and ON_X or OFF_X, 0)
        springStop(knob.Root)
        springTo(knob.Root, target, 26, 0.55)
        paint(v, 0.35)
        if changed and not silent then el:_emit(v) end
    end

    local hit = new("TextButton", {BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1, 16, 1, 16), Position = UDim2.fromOffset(-8, -8),
        ZIndex = 12, Parent = track})
    local startX
    drag(hit, {
        began = function()
            startX = springTarget(knob.Root).X
            tween(knob.Scale, 0.3, {Scale = 1.3}, Enum.EasingStyle.Quint)
        end,
        moved = function(_, delta, moved)
            if moved then
                local x = startX + delta.X / Library.ScaleObject.Scale
                springTo(knob.Root, Vector2.new(x, 0), 45, 1)
                local f = math.clamp((x - OFF_X) / (ON_X - OFF_X), 0, 1)
                paint(f >= 0.5, 0.05)
            end
        end,
        ended = function(_, moved)
            tween(knob.Scale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
            set(moved and springTarget(knob.Root).X > (OFF_X + ON_X) / 2 or not on)
        end,
    })

    function el:Set(v, silent) set(v, silent) end
    function el:Toggle() set(not on) end
    return el
end)
Section.AddCheckbox = Section.AddToggle
Section.AddSwitch = Section.AddToggle

-- Slider
defineElement("AddSlider", function(section, a, b)
    local o = normalize(a, b)
    local min, max = o.Min or 0, o.Max or 100
    local step = o.Step or (max - min <= 1 and 0.01 or 1)
    local decimals = math.max(0, math.floor(-math.log10(step) + 0.5))
    local suffix = o.Suffix or ""
    local el = section:_element(o, "Slider", {PadY = S.RowPadY + 2})
    local row = el.Row
    local valueBox = new("TextBox", {Name = "Value", BackgroundTransparency = 1,
        ClearTextOnFocus = false, TextEditable = true, TextSize = S.Body,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Top,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -S.RowInset, 0, S.RowPadY + 2),
        Size = UDim2.fromOffset(80, 19), ZIndex = 9, Parent = row.Frame})
    bind(valueBox, {TextColor3 = "Text", TextTransparency = "Text2T"})
    pad(S.RowInset, 0, 0, 0).Parent = row.Title

    local holder = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, S.KnobH + 8), LayoutOrder = 3, ZIndex = 7, Parent = row.Body})
    local track = new("Frame", {Name = "Track", BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 6), ZIndex = 7, Parent = holder}, {corner(3)})
    bind(track, {BackgroundColor3 = "Track", BackgroundTransparency = "TrackT"})
    local fill = new("Frame", {Name = "Fill", BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1), ZIndex = 8, Parent = track}, {corner(3)})
    bind(fill, {BackgroundColor3 = "Accent"})
    local knob = glassSurface({
        Kind = "Solid", Name = "Knob", Parent = holder, Radius = S.KnobH / 2,
        Size = UDim2.fromOffset(S.KnobW, S.KnobH),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5), ZIndex = 9,
    })
    local value = o.Default or min
    local function show(v)
        local f = (v - min) / (max - min)
        local off = S.KnobW * (0.5 - f)
        fill.Size = UDim2.new(f, off, 1, 0)
        knob.Root.Position = UDim2.new(f, off, 0.5, 0)
        if not valueBox:IsFocused() then
            valueBox.Text = string.format("%." .. decimals .. "f", v) .. suffix
        end
    end
    local function set(v, silent, fromDrag)
        v = math.clamp(min + math.floor((v - min) / step + 0.5) * step, min, max)
        v = tonumber(string.format("%." .. decimals .. "f", v)) or v
        local changed = v ~= value
        value = v
        el:_store(v)
        show(v)
        if changed and not silent then el:_emit(v) end
    end
    set(value, true)

    local hit = new("TextButton", {BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1, 12, 1, 12), Position = UDim2.fromOffset(-6, -6),
        ZIndex = 12, Parent = holder})
    local function fromPointer(p)
        local sc = Library.ScaleObject.Scale
        local half = S.KnobW / 2 * sc
        local left = screenPos(track).X + half
        local w = track.AbsoluteSize.X - 2 * half
        return min + math.clamp((p.X - left) / math.max(w, 1), 0, 1) * (max - min)
    end
    drag(hit, {
        began = function(p)
            set(fromPointer(p))
            tween(knob.Scale, 0.3, {Scale = 1.35})
        end,
        moved = function(p) set(fromPointer(p), false, true) end,
        ended = function()
            tween(knob.Scale, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
        end,
    })
    function el:Set(v, silent) set(tonumber(v) or value, silent) end
    return el
end)

-- Button
defineElement("AddButton", function(section, a, b)
    local o = normalize(a, b)
    local el = section:_element(o, "Button", {Right = 14})
    local row = el.Row
    icon({Parent = row.Right, Image = "", Size = 10, Level = 3,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0)})
    row.Interactive(function() el:_emit() end)
    function el:Fire() self:_emit() end
    return el
end)

-- Label
defineElement("AddLabel", function(section, a, b)
    local o = type(a) == "table" and a or {Title = a}
    local el = section:_element(o, "Label", {})
    el.Row.Title.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular)
    local color = o.Color
    if color then bind(el.Row.Title, {TextColor3 = color}) end
    el:_store(o.Title or "")
    function el:Set(t) self:SetTitle(t) end
    return el
end)
function Element:SetTitle(t)
    self.TitleText = t or ""
    if self.Row then
        self.Row.Title.Text = self.TitleText
        self.Row.Title.Visible = self.TitleText ~= ""
    end
end

-- Paragraph
defineElement("AddParagraph", function(section, a, b)
    local o = type(a) == "table" and a or {Title = a, Description = b}
    local el = section:_element(o, "Paragraph", {PadY = S.RowPadY + 2})
    el.Row.Title.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)
    el:_store(o.Title or "")
    function el:Set(t)
        if type(t) == "table" then
            if t.Title then self:SetTitle(t.Title) end
            self:SetDescription(t.Content or t.Description)
        else
            self:SetDescription(t)
        end
    end
    return el
end)
function Element:SetDescription(d)
    self.DescText = d
    if self.Row then
        self.Row.Desc.Text = d or ""
        self.Row.Desc.Visible = (d or "") ~= ""
    end
end

-- Divider
defineElement("AddDivider", function(section, _, _)
    local el = section:_element({Title = ""}, "Divider", {MinHeight = 16, PadY = 0, Title = ""})
    el.Row.Body.Visible = false
    el.Row.Separator.AnchorPoint = Vector2.new(0, 0.5)
    el.Row.Separator.Position = UDim2.new(0, S.RowInset, 0.5, 0)
    el.Row.Separator.Size = UDim2.new(1, -2 * S.RowInset, 0, 1)
    el.Row.Separator.Visible = true
    return el
end)

-- Dropdown
defineElement("AddDropdown", function(section, a, b)
    local o = normalize(a, b)
    local options = table.clone(o.Options or {})
    local el = section:_element(o, "Dropdown", {Right = 160})
    local row = el.Row
    local valueLabel = text({Parent = row.Right, Text = "Select", Level = 2,
        TextSize = S.Body, XAlign = Enum.TextXAlignment.Right, Truncate = true,
        Size = UDim2.new(1, -20, 1, 0), ZIndex = 8})
    icon({Parent = row.Right, Image = "", Size = 10, Level = 3,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0)})

    local selected = o.Default or options[1]
    local function show()
        valueLabel.Text = tostring(selected)
        el:_store(selected)
    end
    show()

    local menu
    row.Interactive(function()
        if menu then menu:Close(); menu = nil; return end
        -- simple dropdown menu: a glass card anchored to the row
        local anchor = row.Frame
        local aPos, aSize = screenPos(anchor) / Library.ScaleObject.Scale, anchor.AbsoluteSize / Library.ScaleObject.Scale
        local vs = camera.ViewportSize / Library.ScaleObject.Scale
        local width = math.max(180, aSize.X * 0.5)
        local height = math.min(#options * S.MenuItem + 8, 320)
        local x = aPos.X + aSize.X - width
        local y = aPos.Y + aSize.Y + 4
        if y + height > vs.Y - 10 then y = aPos.Y - height - 4 end

        local g = glassSurface({
            Kind = "Surface", Dense = true, Name = "Menu", Parent = GUI,
            Radius = S.PopoverRadius, Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(width, height), ZIndex = 500,
        })
        local listFrame = new("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 4),
            Size = UDim2.new(1, 0, 1, -8),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 6, Parent = g.Content,
        }, {list(0), pad(0, S.MenuInset, 0, S.MenuInset)})
        for i, opt in ipairs(options) do
            local b = new("TextButton", {BackgroundTransparency = 1, Text = "",
                Size = UDim2.new(1, 0, 0, S.MenuItem), LayoutOrder = i,
                ZIndex = 7, Parent = listFrame})
            local check = icon({Parent = b, Image = "", Size = 12,
                Position = UDim2.fromOffset(20, S.MenuItem / 2), Level = 1,
                Color = "Accent", ZIndex = 8})
            check.Visible = (opt == selected)
            text({Parent = b, Text = tostring(opt), Level = 1, TextSize = S.Body,
                Truncate = true, Position = UDim2.fromOffset(38, 0),
                Size = UDim2.new(1, -52, 1, 0), ZIndex = 8})
            b.MouseEnter:Connect(function()
                tween(b, 0.15, {BackgroundTransparency = themeValue("HighlightT")})
            end)
            b.MouseLeave:Connect(function()
                tween(b, 0.15, {BackgroundTransparency = 1})
            end)
            b.Activated:Connect(function()
                selected = opt
                show()
                el:_emit(selected)
                g.Root:Destroy()
                catcher:Destroy()
                menu = nil
            end)
        end
        local catcher = new("TextButton", {BackgroundTransparency = 1, Text = "",
            Size = UDim2.fromScale(1, 1), ZIndex = 499, Parent = GUI})
        catcher.Activated:Connect(function()
            g.Root:Destroy()
            catcher:Destroy()
            menu = nil
        end)
        menu = {Close = function()
            g.Root:Destroy()
            catcher:Destroy()
        end}
    end)
    function el:Set(v, silent)
        selected = v
        show()
        if not silent then self:_emit(v) end
    end
    function el:Refresh(newOpts)
        options = table.clone(newOpts or {})
        if not table.find(options, selected) then selected = options[1] end
        show()
    end
    return el
end)

-- Input
defineElement("AddInput", function(section, a, b)
    local o = normalize(a, b)
    local el = section:_element(o, "Input", {Right = S.Field})
    local box = new("TextBox", {
        BackgroundTransparency = 0.82, BackgroundColor3 = themeValue("Field"),
        Text = o.Default or "", PlaceholderText = o.Placeholder or "",
        ClearTextOnFocus = false, TextSize = S.Body,
        TextXAlignment = Enum.TextXAlignment.Left,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(S.Field, S.Control), ZIndex = 9,
        Parent = el.Row.Right,
    }, {corner(S.Control / 2)})
    bind(box, {TextColor3 = "Text", PlaceholderColor3 = "Text", TextTransparency = function() return 0 end})
    pad(S.Control / 2 - 2, S.Control / 2 - 2, 0, 0).Parent = box
    el:_store(box.Text)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        el:_store(box.Text)
    end)
    box.FocusLost:Connect(function(enter)
        el:_emit(box.Text, enter)
    end)
    function el:Set(v, silent)
        box.Text = tostring(v or "")
        el:_store(box.Text)
        if not silent then el:_emit(box.Text) end
    end
    function el:Focus() box:CaptureFocus() end
    return el
end)
Section.AddTextbox = Section.AddInput

-- Keybind
defineElement("AddKeybind", function(section, a, b)
    local o = normalize(a, b)
    local el = section:_element(o, "Keybind", {Right = 120})
    local key = o.Default or Enum.KeyCode.F
    local listening = false
    local pill = glassSurface({
        Kind = "Control", Name = "Key", Parent = el.Row.Right, Radius = S.Control / 2,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(60, S.Control), ZIndex = 8,
    })
    local keyLabel = text({Parent = pill.Content, Text = key.Name, Level = 1,
        TextSize = S.Subhead, XAlign = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1), ZIndex = 9})
    el.Row.Interactive(function()
        listening = true
        keyLabel.Text = "..."
    end)
    UserInputService.InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode
            listening = false
            keyLabel.Text = key.Name
            el:_store(key)
            el:_emit(key)
        end
    end)
    el:_store(key)
    function el:Set(k) key = k; keyLabel.Text = k.Name; self:_store(k) end
    return el
end)

-- Color Picker
defineElement("AddColorPicker", function(section, a, b)
    local o = normalize(a, b)
    local color = o.Default or Color3.fromRGB(10, 132, 255)
    local el = section:_element(o, "ColorPicker", {Right = 100})
    local row = el.Row
    text({Parent = row.Right, Text = "#" .. color:ToHex(), Level = 2,
        TextSize = S.Subhead, XAlign = Enum.TextXAlignment.Right,
        Size = UDim2.new(1, -(S.Badge + 10), 1, 0), ZIndex = 8})
    local swatch = new("Frame", {BackgroundColor3 = color,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(S.Badge, S.Badge),
        ZIndex = 8, Parent = row.Right}, {corner(S.Badge / 2)})
    local rim = stroke(WHITE, 0.3, 1.5)
    rim.Parent = swatch
    el:_store(color)
    row.Interactive(function()
        el:_emit(color)
    end)
    function el:Set(c, silent)
        color = c
        swatch.BackgroundColor3 = c
        self:_store(c)
        if not silent then self:_emit(c) end
    end
    function el:GetColor() return color end
    return el
end)

-- Image
defineElement("AddImage", function(section, a, b)
    local o = type(a) == "table" and a or {Image = a}
    local el = section:_element(o, "Image", {Icon = false, PadY = 8, MinHeight = 0})
    local row = el.Row
    row.Title.Visible = false
    local frame = new("Frame", {BackgroundColor3 = WHITE, BackgroundTransparency = 0.9,
        Size = UDim2.new(1, 0, 0, o.Height or 170), LayoutOrder = 1,
        ZIndex = 7, Parent = row.Body}, {corner(S.CardRadius - 8)})
    local img = new("ImageLabel", {BackgroundTransparency = 1, Image = o.Image or "",
        Size = UDim2.fromScale(1, 1), ZIndex = 8, Parent = frame}, {corner(S.CardRadius - 8)})
    function el:Set(src)
        img.Image = src or ""
    end
    return el
end)

-- Segmented control
defineElement("AddSegmented", function(section, a, b)
    local o = normalize(a, b)
    local options = o.Options or {"One", "Two"}
    local el = section:_element(o, "Segmented", {PadY = S.RowPadY + 2, MinHeight = 0})
    local holder = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, S.Control), LayoutOrder = 3, ZIndex = 7, Parent = el.Row.Body})
    local track = glassSurface({
        Kind = "Control", Parent = holder, Radius = S.Control / 2,
        Size = UDim2.new(1, 0, 0, S.Control), ZIndex = 7,
    })
    local count = #options
    local PILL = 3
    local pill = glassSurface({
        Kind = "Control", Name = "Selection", Parent = track.Content,
        Radius = S.Control / 2 - PILL,
        Size = UDim2.new(1 / count, -2 * PILL, 1, -2 * PILL),
        Position = UDim2.fromOffset(PILL, PILL), ZIndex = 8,
    })
    pill.SetTint(WHITE, 0.72)
    local labels = {}
    for i, name in ipairs(options) do
        labels[i] = text({Parent = track.Content, Text = tostring(name), Level = 1,
            TextSize = S.Body, XAlign = Enum.TextXAlignment.Center, Truncate = true,
            Position = UDim2.fromScale((i - 1) / count, 0),
            Size = UDim2.fromScale(1 / count, 1), ZIndex = 10})
        bind(labels[i], {TextTransparency = function(t)
            return (i - 1) == (el.Value and table.find(options, el.Value) or 1) - 1 and 0 or t.Text2T
        end})
    end
    local function setIndex(i, silent)
        local slot = UDim2.new((i - 1) / count, PILL, 0, PILL)
        springTo(pill.Root, Vector2.new(0, 0), 20, 0.6)
        pill.Root.Position = slot
        for j, l in ipairs(labels) do
            bind(l, {TextTransparency = function(t) return j == i and 0 or t.Text2T end})
        end
        el:_store(options[i])
        if not silent then el:_emit(options[i]) end
    end
    local initialIndex = table.find(options, o.Default) or 1
    setIndex(initialIndex, true)
    local hit = new("TextButton", {BackgroundTransparency = 1, Text = "",
        Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = track.Content})
    local startSlot
    drag(hit, {
        began = function(p)
            local rel = (p - screenPos(track.Root)) / Library.ScaleObject.Scale
            local i = math.clamp(math.ceil(rel.X / (track.Root.AbsoluteSize.X / count / Library.ScaleObject.Scale)), 1, count)
            startSlot = i
            pill.Root.Position = UDim2.new((i - 1) / count, PILL, 0, PILL)
            for j, l in ipairs(labels) do
                bind(l, {TextTransparency = function(t) return j == i and 0 or t.Text2T end})
            end
        end,
        moved = function(p)
            local rel = (p - screenPos(track.Root)) / Library.ScaleObject.Scale
            local i = math.clamp(math.ceil(rel.X / (track.Root.AbsoluteSize.X / count / Library.ScaleObject.Scale)), 1, count)
            pill.Root.Position = UDim2.new((i - 1) / count, PILL, 0, PILL)
            for j, l in ipairs(labels) do
                bind(l, {TextTransparency = function(t) return j == i and 0 or t.Text2T end})
            end
        end,
        ended = function()
            local pos = pill.Root.Position
            local i = math.clamp(math.floor(pos.X.Scale * count + 0.5) + 1, 1, count)
            setIndex(i)
        end,
    })
    function el:Set(v, silent)
        local i = type(v) == "number" and v or table.find(options, v)
        if i then setIndex(i, silent) end
    end
    return el
end)

-- Progress
defineElement("AddProgress", function(section, a, b)
    local o = type(a) == "table" and a or {Title = a, Default = b}
    local max = o.Max or 1
    local el = section:_element(o, "Progress", {PadY = S.RowPadY + 2})
    local pct = text({Parent = el.Row.Frame, Text = "", Level = 2,
        TextSize = S.Body, XAlign = Enum.TextXAlignment.Right,
        YAlign = Enum.TextYAlignment.Top,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -S.RowInset, 0, S.RowPadY + 2),
        Size = UDim2.fromOffset(80, 19), ZIndex = 8})
    local holder = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 3, ZIndex = 7, Parent = el.Row.Body})
    local bar = new("Frame", {BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 6), ZIndex = 7, Parent = holder}, {corner(3)})
    bind(bar, {BackgroundColor3 = "Track", BackgroundTransparency = "TrackT"})
    local fill = new("Frame", {BorderSizePixel = 0, Size = UDim2.fromScale(0, 1),
        ZIndex = 8, Parent = bar}, {corner(3)})
    bind(fill, {BackgroundColor3 = "Accent"})
    local function set(v)
        v = math.clamp(v or 0, 0, max)
        el:_store(v)
        tween(fill, 0.45, {Size = UDim2.fromScale(v / max, 1)})
        pct.Text = math.floor(v / max * 100 + 0.5) .. "%"
    end
    set(o.Default or 0)
    function el:Set(v) set(v) end
    return el
end)

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local notifications = {}
local notifyHolder = new("Frame", {Name = "Notifications", BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = GUI})

function Library:Notify(o)
    if type(o) == "string" then o = {Title = o} end
    o = o or {}
    local duration = o.Duration or 4
    local n = {}
    local g = glassSurface({
        Kind = "Surface", Name = "Notification", Parent = notifyHolder,
        Radius = S.NotifyRadius, Size = UDim2.fromOffset(S.Notify, 0),
        AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 400,
    })
    local body = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 6, Parent = g.Content}, {
        pad(S.NotifyPad, S.NotifyPad, S.NotifyPad, S.NotifyPad),
    })
    local strut = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.fromOffset(0, S.NotifyBadge), Parent = body})
    local badge = glassSurface({
        Kind = "Tinted", Parent = body, Radius = S.NotifyRadius - S.NotifyPad,
        Size = UDim2.fromOffset(S.NotifyBadge, S.NotifyBadge),
        Tint = o.IconColor or "Accent", ZIndex = 7,
    })
    local TX = S.NotifyBadge + 12
    local textStack = new("Frame", {BackgroundTransparency = 1,
        Position = UDim2.fromOffset(TX, 0), Size = UDim2.new(1, -TX, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 7, Parent = body}, {list(4)})
    new("UISizeConstraint", {MinSize = Vector2.new(0, S.NotifyBadge), Parent = textStack})
    local titleRow = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 19), LayoutOrder = 1, ZIndex = 7, Parent = textStack})
    text({Parent = titleRow, Text = o.Title or "Notification", Level = 1,
        TextSize = S.Body, Truncate = true, Size = UDim2.new(1, -40, 1, 0)})
    if o.Content then
        text({Parent = textStack, Text = tostring(o.Content), Level = 2,
            TextSize = S.Subhead, Wrap = true,
            AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
            LayoutOrder = 2})
    end
    local bar = new("Frame", {BackgroundColor3 = themeValue("Accent"),
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, S.NotifyRadius, 1, -1),
        Size = UDim2.new(1, -2 * S.NotifyRadius, 0, 2),
        BackgroundTransparency = 0.5, ZIndex = 8, Parent = g.Content}, {corner(1)})

    table.insert(notifications, 1, n)
    function n.Close()
        if n.Closed then return end
        n.Closed = true
        local i = table.find(notifications, n)
        if i then table.remove(notifications, i) end
        local vs = camera.ViewportSize / Library.ScaleObject.Scale
        springTo(g.Root, Vector2.new(vs.X + 20, g.Root.Position.Y.Offset), 16, 1)
        tween(g.Dim, 0.3, {BackgroundTransparency = 1})
        tween(g.Fill, 0.3, {BackgroundTransparency = 1})
        task.delay(0.5, function() g.Root:Destroy() end)
        Library:_layoutNotifications()
    end
    n.Dismiss = n.Close

    -- layout notifications vertically from top-right
    task.defer(function()
        Library:_layoutNotifications(true)
        tween(g.Dim, 0.3, {BackgroundTransparency = themeValue("DimT")})
        tween(g.Fill, 0.3, {BackgroundTransparency = themeValue("GlassT")})
    end)
    if duration and duration > 0 then
        local t0 = os.clock()
        task.delay(duration, function()
            if not n.Closed then n.Close() end
        end)
        RunService.RenderStepped:Connect(function()
            if n.Closed then return end
            local rem = math.max(0, 1 - (os.clock() - t0) / duration)
            bar.Size = UDim2.new(rem, -2 * S.NotifyRadius * rem, 0, 2)
        end)
    end
    return n
end

function Library:_layoutNotifications(fromAdd)
    local s = Library.ScaleObject.Scale
    local vs = camera.ViewportSize / s
    local y = (GuiService:GetGuiInset().Y / s) + 12
    for _, n in ipairs(notifications) do
        if not n.Placed or not fromAdd then
            local target = Vector2.new(vs.X - S.Notify - 16, y)
            if not n.Placed then
                n.Glass.Root.Position = UDim2.fromOffset(vs.X + 60, target.Y)
                n.Placed = true
            end
            springTo(n.Glass.Root, target, 20, 0.75)
            y += (n.Glass.Root.AbsoluteSize.Y / s) + 10
        else
            y += (n.Glass.Root.AbsoluteSize.Y / s) + 10
        end
    end
end

-- ============================================================
-- DIALOG
-- ============================================================
function Library:Dialog(o)
    o = o or {}
    local shade = new("TextButton", {BackgroundTransparency = 1, Text = "",
        Size = UDim2.fromScale(1, 1), ZIndex = 700, Parent = GUI})
    bind(shade, {BackgroundColor3 = "Overlay"})
    tween(shade, 0.3, {BackgroundTransparency = themeValue("OverlayT")})
    local s = Library.ScaleObject.Scale
    local vs = camera.ViewportSize / s
    local g = glassSurface({
        Kind = "Surface", Dense = true, Name = "Dialog", Parent = GUI,
        Radius = S.DialogRadius,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(vs.X / 2, vs.Y / 2),
        Size = UDim2.fromOffset(o.Width or S.DialogW, 0),
        AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 800,
    })
    local body = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 6, Parent = g.Content}, {
        pad(S.DialogPad, S.DialogPad, S.DialogPad, S.DialogPad),
        list(8),
    })
    text({Parent = body, Text = o.Title or "Confirm", Level = 1,
        TextSize = S.Title, XAlign = Enum.TextXAlignment.Center, Wrap = true,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1, Font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)})
    if o.Content then
        text({Parent = body, Text = tostring(o.Content), Level = 2,
            TextSize = S.Subhead, XAlign = Enum.TextXAlignment.Center, Wrap = true,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2})
    end
    local btnRow = new("Frame", {BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, S.Button), LayoutOrder = 3, ZIndex = 7, Parent = body}, {
        list(8, Enum.FillDirection.Horizontal),
    })
    local d = {}
    local buttons = o.Buttons or {{Title = "OK", Style = "Primary"}}
    local function mkbtn(b, i)
        local bg = glassSurface({
            Kind = b.Style == "Primary" and "Tinted" or "Control", Parent = btnRow,
            Radius = S.Button / 2, Size = UDim2.new(1 / #buttons, -4, 0, S.Button),
            LayoutOrder = i, ZIndex = 8,
            Tint = b.Style == "Destructive" and "Danger" or "Accent",
        })
        text({Parent = bg.Content, Text = b.Title or "OK", Level = 1,
            TextSize = S.Body, XAlign = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1), ZIndex = 9,
            Font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)})
        local hit = new("TextButton", {BackgroundTransparency = 1, Text = "",
            Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = bg.Content})
        hit.Activated:Connect(function()
            fire(b.Callback)
            d.Close()
        end)
    end
    for i, b in ipairs(buttons) do mkbtn(b, i) end
    g.Scale.Scale = 1.12
    tween(g.Scale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
    function d.Close()
        if d.Closed then return end
        d.Closed = true
        tween(shade, 0.25, {BackgroundTransparency = 1})
        tween(g.Scale, 0.2, {Scale = 0.92})
        tween(g.Dim, 0.2, {BackgroundTransparency = 1})
        tween(g.Fill, 0.2, {BackgroundTransparency = 1})
        task.delay(0.3, function() g.Root:Destroy(); shade:Destroy() end)
    end
    shade.Activated:Connect(function() d.Close() end)
    return d
end

-- ============================================================
-- SETTINGS / SCALE / DESTROY
-- ============================================================
Library.Settings = {Theme = "Dark", Blur = true, Scale = 1}
Library.ToggleKey = Enum.KeyCode.RightControl
Library.Flags = {}
Library.Options = {}

function Library:SetBlur(on)
    Library.Settings.Blur = on and true or false
end

function Library:SetScale(s)
    s = math.clamp(tonumber(s) or 1, 0.4, 2)
    Library.Settings.Scale = s
    Library.ScaleObject.Scale = s
end

function Library:Destroy()
    if Library.Unloaded then return end
    Library.Unloaded = true
    for _, w in ipairs(Library.Windows or {}) do w:Destroy() end
    task.delay(0.4, function()
        if blurFolder then blurFolder:Destroy() end
        if dof then dof:Destroy() end
        GUI:Destroy()
    end)
end
Library.Unload = Library.Destroy

return Library
