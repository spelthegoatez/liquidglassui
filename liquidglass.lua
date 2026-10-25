--!strict
-- LiquidGlass UI Library (fixed)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Library = {}
Library.__index = Library

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    Glass         = Color3.fromRGB(255, 255, 255),
    GlassDark     = Color3.fromRGB(180, 200, 255),
    Background    = Color3.fromRGB(20, 22, 34),
    Background2   = Color3.fromRGB(30, 34, 56),
    Border        = Color3.fromRGB(255, 255, 255),
    Text          = Color3.fromRGB(245, 248, 255),
    TextDim       = Color3.fromRGB(160, 170, 200),
    Accent        = Color3.fromRGB(120, 180, 255),
    Accent2       = Color3.fromRGB(180, 120, 255),
    Success       = Color3.fromRGB(110, 240, 180),
    Danger        = Color3.fromRGB(255, 110, 130),
}

local Fonts = {
    Reg  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
    Bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
}

local Sizes = {
    Width = 640, Height = 440,
    Row = 42, TabW = 150, TabH = 36,
    ToggleW = 40, ToggleH = 22, Knob = 16,
}

local Anim = { Fast = 0.12, Normal = 0.18, Slow = 0.28 }

-- ============================================================
-- HELPERS
-- ============================================================
local function new(class, props)
    local i = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then i[k] = v end
    end
    if props.Parent then i.Parent = props.Parent end
    return i
end

local function tw(o, p, d, s, dir)
    local t = TweenService:Create(o, TweenInfo.new(d or Anim.Normal, s or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), p)
    t:Play(); return t
end

local function corner(p, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 10), Parent = p}) end
local function stroke(p, col, trans, thick)
    return new("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = col or Theme.Border,
        Transparency = trans or 0.6,
        Thickness = thick or 1,
        Parent = p,
    })
end
local function padding(p, a, b, c, d)
    return new("UIPadding", {
        PaddingTop = UDim.new(0, a or 0), PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, c or 0), PaddingRight = UDim.new(0, d or 0), Parent = p,
    })
end
local function listLayout(p, pad, dir)
    return new("UIListLayout", {
        Padding = UDim.new(0, pad or 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = dir or Enum.FillDirection.Vertical,
        Parent = p,
    })
end
local function grad(p, from, to, rot, transFrom, transTo)
    return new("UIGradient", {
        Color = ColorSequence.new(from, to),
        Rotation = rot or 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, transFrom or 0),
            NumberSequenceKeypoint.new(1, transTo or 0),
        }),
        Parent = p,
    })
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
-- BLUR CONTROLLER
-- ============================================================
local Blur = {}
Blur.__index = Blur

function Blur.new(frame)
    local self = setmetatable({ frame = frame, enabled = true }, Blur)
    self:_init()
    return self
end

function Blur:_init()
    local old = Lighting:FindFirstChild("LG_DoF")
    if old then old:Destroy() end

    self.dof = new("DepthOfFieldEffect", {
        Name = "LG_DoF",
        FarIntensity = 0,
        FocusDistance = 0.05,
        InFocusRadius = 0.12,
        NearIntensity = 0.65,
        Parent = Lighting,
    })

    local cam = workspace.CurrentCamera
    local existing = cam:FindFirstChild("LG_Glass")
    if existing then existing:Destroy() end
    self.folder = new("Folder", { Name = "LG_Glass", Parent = cam })

    local part = new("Part", {
        Name = "Root",
        Color = Color3.new(1,1,1),
        Material = Enum.Material.Glass,
        Size = Vector3.new(1,1,0.01),
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        CastShadow = false,
        Transparency = 0.97,
        Parent = self.folder,
    })
    new("SpecialMesh", { MeshType = Enum.MeshType.Brick, Parent = part })
    self.part = part

    self._update = function()
        if not self.enabled or not part.Parent then return end
        local c = workspace.CurrentCamera
        local ap = self.frame.AbsolutePosition
        local as = self.frame.AbsoluteSize
        if as.X <= 0 or as.Y <= 0 then return end
        local function toWorld(x, y)
            local ray = c:ScreenPointToRay(x, y)
            return ray.Origin + ray.Direction * 0.05
        end
        local tl = toWorld(ap.X, ap.Y)
        local tr = toWorld(ap.X + as.X, ap.Y)
        local br = toWorld(ap.X + as.X, ap.Y + as.Y)
        local w = (tr - tl).Magnitude
        local h = (tr - br).Magnitude
        part.CFrame = CFrame.fromMatrix((tl + br) / 2, c.CFrame.XVector, c.CFrame.YVector, c.CFrame.ZVector)
        local mesh = part:FindFirstChildOfClass("SpecialMesh")
        if mesh then mesh.Scale = Vector3.new(w, h, 0.01) end
    end

    self._conns = {
        RunService.RenderStepped:Connect(self._update),
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(self._update),
    }
    task.spawn(self._update)
end

function Blur:SetEnabled(on)
    self.enabled = on
    if self.dof then self.dof.Enabled = on end
    if self.part then self.part.Transparency = on and 0.97 or 1 end
end

function Blur:Destroy()
    for _, c in pairs(self._conns or {}) do c:Disconnect() end
    if self.dof then self.dof:Destroy() end
    if self.folder then self.folder:Destroy() end
end

-- ============================================================
-- LIBRARY CONSTRUCTOR
-- ============================================================
function Library.new(title)
    local self = setmetatable({}, Library)
    self.title = title or "LiquidGlass"
    self.tabs = {}
    self.elements = {}
    self._keybinds = {}
    self._visible = true
    self._toggleKey = Enum.KeyCode.RightControl
    self:_build()
    return self
end

function Library:_build()
    self.gui = new("ScreenGui", {
        Name = "LG_" .. self.title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    self.root = new("Frame", {
        Name = "Root",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.55,
        Position = UDim2.new(0.5, -Sizes.Width/2, 0.5, -Sizes.Height/2),
        Size = UDim2.new(0, Sizes.Width, 0, Sizes.Height),
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = self.gui,
    })
    corner(self.root, 14)

    -- Main glass gradient overlay
    local rootGrad = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Glass),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 220, 255)),
            ColorSequenceKeypoint.new(1, Theme.GlassDark),
        }),
        Rotation = 135,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.92),
            NumberSequenceKeypoint.new(1, 0.96),
        }),
        Parent = self.root,
    })

    -- Glowing gradient border
    local rootStroke = stroke(self.root, Theme.Border, 0.5, 1.5)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1, Theme.Accent2),
        }),
        Rotation = 45,
        Parent = rootStroke,
    })

    -- Top specular highlight
    local sheen = new("Frame", {
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -2, 0, 70),
        Position = UDim2.new(0, 1, 0, 1),
        BorderSizePixel = 0,
        Parent = self.root,
    })
    corner(sheen, 13)
    new("UIGradient", {
        Color = ColorSequence.new(Color3.new(1,1,1)),
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = sheen,
    })

    -- Top bar
    self.topBar = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 46),
        Parent = self.root,
    })

    new("TextLabel", {
        FontFace = Fonts.Bold,
        TextColor3 = Theme.Text,
        Text = self.title,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 16,
        Position = UDim2.new(0, 18, 0, 14),
        Size = UDim2.new(0, 200, 0, 20),
        Parent = self.topBar,
    })

    -- Divider with gradient
    local divider = new("Frame", {
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.85,
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.new(0, 10, 0, 46),
        BorderSizePixel = 0,
        Parent = self.root,
    })
    new("UIGradient", {
        Color = ColorSequence.new(Color3.new(1,1,1)),
        Rotation = 0,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.7),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = divider,
    })

    -- Close button
    local close = new("TextButton", {
        Text = "X",
        FontFace = Fonts.Bold,
        TextColor3 = Theme.TextDim,
        TextSize = 15,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.new(0, 20, 0, 20),
        Parent = self.topBar,
    })
    close.MouseEnter:Connect(function() tw(close, {TextColor3 = Theme.Danger}, Anim.Fast) end)
    close.MouseLeave:Connect(function() tw(close, {TextColor3 = Theme.TextDim}, Anim.Fast) end)
    close.MouseButton1Click:Connect(function() self:Destroy() end)

    -- Tab bar
    self.tabBar = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        Position = UDim2.new(0, 10, 0, 58),
        Size = UDim2.new(0, Sizes.TabW, 1, -70),
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = self.root,
    })
    listLayout(self.tabBar, 4)
    padding(self.tabBar, 4, 4, 0, 0)

    -- Separator
    local sep = new("Frame", {
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.88,
        Position = UDim2.new(0, Sizes.TabW + 12, 0, 58),
        Size = UDim2.new(0, 1, 1, -70),
        BorderSizePixel = 0,
        Parent = self.root,
    })
    new("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.8),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = sep,
    })

    -- Content
    self.content = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        Position = UDim2.new(0, Sizes.TabW + 22, 0, 58),
        Size = UDim2.new(1, -(Sizes.TabW + 32), 1, -70),
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = self.root,
    })
    listLayout(self.content, 8)
    padding(self.content, 4, 8, 4, 8)

    -- Keybind listener
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == self._toggleKey then self:Toggle() end
        for _, kb in pairs(self._keybinds) do
            if input.KeyCode == kb.key then task.spawn(kb.cb) end
        end
    end)

    makeDraggable(self.root, self.topBar)

    self.gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.blur = Blur.new(self.root)
end

function Library:Toggle()
    self._visible = not self._visible
    self.root.Visible = self._visible
    self.blur:SetEnabled(self._visible)
end

function Library:SetToggleKey(k) self._toggleKey = k end

function Library:Destroy()
    if self.blur then self.blur:Destroy() end
    if self.gui then self.gui:Destroy() end
end

function Library:Notify(cfg)
    local title = cfg.Title or "Notice"
    local desc  = cfg.Description or ""
    local dur   = cfg.Duration or 3

    if not self._notifHolder then
        self._notifHolder = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -260, 0, 20),
            Size = UDim2.new(0, 240, 1, -40),
            Parent = self.gui,
        })
        listLayout(self._notifHolder, 8)
    end

    local n = new("Frame", {
        BackgroundColor3 = Theme.Background2,
        BackgroundTransparency = 0.35,
        Position = UDim2.new(1, 40, 0, 0),
        Size = UDim2.new(1, 0, 0, 64),
        ClipsDescendants = true,
        Parent = self._notifHolder,
    })
    corner(n, 10)
    stroke(n, Theme.Border, 0.7, 1)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Glass),
            ColorSequenceKeypoint.new(1, Theme.GlassDark),
        }),
        Rotation = 135,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.95),
            NumberSequenceKeypoint.new(1, 0.99),
        }),
        Parent = n,
    })

    new("TextLabel", {
        FontFace = Fonts.Bold, TextColor3 = Theme.Text, Text = title,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -20, 0, 20), TextSize = 14,
        Parent = n,
    })
    new("TextLabel", {
        FontFace = Fonts.Reg, TextColor3 = Theme.TextDim, Text = desc,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 32),
        Size = UDim2.new(1, -20, 0, 18), TextSize = 12, Parent = n,
    })

    local bar = new("Frame", {
        BackgroundColor3 = Theme.Accent, Position = UDim2.new(0,0,1,-3),
        Size = UDim2.new(1,0,0,2), BorderSizePixel = 0, Parent = n,
    })
    corner(bar, 100)
    tw(n, {Position = UDim2.new(0,0,0,0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tw(bar, {Size = UDim2.new(0,0,0,2)}, dur, Enum.EasingStyle.Linear)
    task.delay(dur, function()
        tw(n, {Position = UDim2.new(1,40,0,0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.3); n:Destroy()
    end)
end

-- ============================================================
-- TAB
-- ============================================================
function Library:CreateTab(name, icon)
    local tab = { name = name, elements = {}, _lib = self }

    local btn = new("TextButton", {
        Name = name, Text = "", AutoButtonColor = false,
        BackgroundColor3 = Theme.Glass, BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, Sizes.TabH),
        Parent = self.tabBar,
    })
    corner(btn, 10)
    local btnStroke = stroke(btn, Theme.Border, 1, 1)

    local iconLbl = new("ImageLabel", {
        BackgroundTransparency = 1,
        Image = icon or "rbxassetid://112235310154264",
        ImageColor3 = Theme.TextDim,
        Position = UDim2.new(0, 12, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
        Parent = btn,
    })
    local txt = new("TextLabel", {
        FontFace = Fonts.Reg, TextColor3 = Theme.TextDim, Text = name,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Position = UDim2.new(0, 36, 0, 0), Size = UDim2.new(1, -44, 1, 0),
        TextSize = 13, Parent = btn,
    })

    tab.button = btn; tab.stroke = btnStroke; tab.icon = iconLbl; tab.text = txt

    local content = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y, Visible = false,
        Parent = self.content,
    })
    listLayout(content, 8)
    tab.content = content

    btn.MouseButton1Click:Connect(function() self:_selectTab(tab) end)
    btn.MouseEnter:Connect(function()
        if self.currentTab ~= tab then tw(btn, {BackgroundTransparency = 0.88}, Anim.Fast) end
    end)
    btn.MouseLeave:Connect(function()
        if self.currentTab ~= tab then tw(btn, {BackgroundTransparency = 1}, Anim.Fast) end
    end)

    table.insert(self.tabs, tab)
    if not self.currentTab then self:_selectTab(tab) end

    function tab:Slider(cfg) return Library._slider(self, cfg) end
    function tab:Toggle(cfg) return Library._toggle(self, cfg) end
    function tab:Button(cfg) return Library._button(self, cfg) end
    function tab:Dropdown(cfg) return Library._dropdown(self, cfg) end
    function tab:Keybind(cfg) return Library._keybind(self, cfg) end
    function tab:TextBox(cfg) return Library._textbox(self, cfg) end
    function tab:ColorPicker(cfg) return Library._colorpicker(self, cfg) end
    function tab:Label(cfg) return Library._label(self, cfg) end
    function tab:Divider(text) return Library._divider(self, text) end

    return tab
end

function Library:_selectTab(tab)
    if self.currentTab then
        local old = self.currentTab
        old.content.Visible = false
        tw(old.button, {BackgroundTransparency = 1}, Anim.Fast)
        tw(old.icon, {ImageColor3 = Theme.TextDim}, Anim.Fast)
        tw(old.text, {TextColor3 = Theme.TextDim}, Anim.Fast)
        old.stroke.Transparency = 1
    end
    self.currentTab = tab
    tab.content.Visible = true
    tw(tab.button, {BackgroundTransparency = 0.82}, Anim.Fast)
    tw(tab.icon, {ImageColor3 = Theme.Text}, Anim.Fast)
    tw(tab.text, {TextColor3 = Theme.Text}, Anim.Fast)
    tab.stroke.Transparency = 0.55
end

-- ============================================================
-- GLASS ROW BASE
-- ============================================================
local function glassRow(parent, height)
    local row = new("Frame", {
        BackgroundColor3 = Theme.Background2,
        BackgroundTransparency = 0.45,
        Size = UDim2.new(1, 0, 0, height),
        BorderSizePixel = 0,
        Parent = parent,
    })
    corner(row, 10)
    stroke(row, Theme.Border, 0.82, 1)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Glass),
            ColorSequenceKeypoint.new(1, Theme.GlassDark),
        }),
        Rotation = 135,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.94),
            NumberSequenceKeypoint.new(1, 0.99),
        }),
        Parent = row,
    })
    local sheen = new("Frame", {
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -4, 0, 10),
        Position = UDim2.new(0, 2, 0, 2),
        BorderSizePixel = 0, Parent = row,
    })
    corner(sheen, 8)
    new("UIGradient", {
        Color = ColorSequence.new(Color3.new(1,1,1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.85),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = sheen,
    })
    return row
end

local function rowLabel(row, text)
    return new("TextLabel", {
        FontFace = Fonts.Reg, TextColor3 = Theme.Text, Text = text,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.55, 0, 1, 0),
        TextSize = 13, Parent = row,
    })
end

-- ============================================================
-- TOGGLE
-- ============================================================
function Library._toggle(tab, cfg)
    local name = cfg.Name or "Toggle"
    local state = cfg.Default or false
    local cb = cfg.Callback or function() end

    local row = glassRow(tab.content, Sizes.Row)
    rowLabel(row, name)

    local sw = new("Frame", {
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.2,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, Sizes.ToggleW, 0, Sizes.ToggleH),
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(sw, 100)
    stroke(sw, Theme.Border, 0.6, 1)

    local swGrad = new("UIGradient", {
        Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
        Rotation = 0,
        Enabled = state,
        Parent = sw,
    })

    local knob = new("Frame", {
        BackgroundColor3 = Color3.new(1,1,1),
        Position = state and UDim2.new(0, Sizes.ToggleW - Sizes.Knob - 3, 0.5, -Sizes.Knob/2)
                       or UDim2.new(0, 3, 0.5, -Sizes.Knob/2),
        Size = UDim2.new(0, Sizes.Knob, 0, Sizes.Knob),
        BorderSizePixel = 0,
        Parent = sw,
    })
    corner(knob, 100)
    new("UIStroke", {Color = Color3.new(0,0,0), Transparency = 0.85, Thickness = 1, Parent = knob})

    local btn = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Parent = row})

    local function apply()
        if state then
            tw(sw, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.15}, Anim.Normal)
            swGrad.Enabled = true
            tw(knob, {Position = UDim2.new(0, Sizes.ToggleW - Sizes.Knob - 3, 0.5, -Sizes.Knob/2)}, Anim.Normal, Enum.EasingStyle.Back)
        else
            tw(sw, {BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.2}, Anim.Normal)
            swGrad.Enabled = false
            tw(knob, {Position = UDim2.new(0, 3, 0.5, -Sizes.Knob/2)}, Anim.Normal, Enum.EasingStyle.Back)
        end
    end
    apply()

    btn.MouseButton1Click:Connect(function()
        state = not state; apply(); cb(state)
    end)

    return {
        Set = function(_, v) state = v; apply(); cb(state) end,
        Get = function() return state end,
    }
end

-- ============================================================
-- SLIDER
-- ============================================================
function Library._slider(tab, cfg)
    local name = cfg.Name or "Slider"
    local min, max = cfg.Min or 0, cfg.Max or 100
    local val = cfg.Default or min
    local cb = cfg.Callback or function() end

    local row = glassRow(tab.content, 56)
    local nameLbl = rowLabel(row, name)
    nameLbl.Position = UDim2.new(0, 14, 0, 8)
    nameLbl.Size = UDim2.new(0.6, 0, 0, 20)

    local valLbl = new("TextLabel", {
        FontFace = Fonts.Bold, TextColor3 = Theme.Accent, Text = tostring(val),
        TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1,
        Position = UDim2.new(1, -14, 0, 8), Size = UDim2.new(0, 80, 0, 20),
        TextSize = 13, Parent = row,
    })

    local track = new("Frame", {
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.25,
        Position = UDim2.new(0, 14, 0, 36),
        Size = UDim2.new(1, -28, 0, 6),
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(track, 100)

    local fill = new("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new((val - min) / (max - min), 0, 1, 0),
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(fill, 100)
    new("UIGradient", {
        Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
        Parent = fill,
    })

    local knob = new("Frame", {
        BackgroundColor3 = Color3.new(1,1,1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((val - min)/(max-min), 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(knob, 100)
    new("UIStroke", {Color = Theme.Accent, Transparency = 0.2, Thickness = 2, Parent = knob})

    local dragging = false
    local function setFromX(x)
        local ap, as = track.AbsolutePosition, track.AbsoluteSize
        local t = math.clamp((x - ap.X) / as.X, 0, 1)
        val = math.floor(min + (max - min) * t + 0.5)
        valLbl.Text = tostring(val)
        tw(fill, {Size = UDim2.new(t, 0, 1, 0)}, 0.05)
        tw(knob, {Position = UDim2.new(t, 0, 0.5, 0)}, 0.05)
        cb(val)
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        Set = function(_, v)
            val = math.clamp(v, min, max)
            local t = (val - min) / (max - min)
            valLbl.Text = tostring(val)
            fill.Size = UDim2.new(t, 0, 1, 0)
            knob.Position = UDim2.new(t, 0, 0.5, 0)
            cb(val)
        end,
        Get = function() return val end,
    }
end

-- ============================================================
-- BUTTON
-- ============================================================
function Library._button(tab, cfg)
    local name = cfg.Name or "Button"
    local cb = cfg.Callback or function() end
    local row = glassRow(tab.content, Sizes.Row)
    rowLabel(row, name)
    local btn = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Parent = row})
    btn.MouseEnter:Connect(function() tw(row, {BackgroundTransparency = 0.25}, Anim.Fast) end)
    btn.MouseLeave:Connect(function() tw(row, {BackgroundTransparency = 0.45}, Anim.Fast) end)
    btn.MouseButton1Click:Connect(function()
        tw(row, {BackgroundTransparency = 0.15}, 0.08)
        task.wait(0.1)
        tw(row, {BackgroundTransparency = 0.45}, Anim.Fast)
        cb()
    end)
    return {}
end

-- ============================================================
-- DROPDOWN
-- ============================================================
function Library._dropdown(tab, cfg)
    local name = cfg.Name or "Dropdown"
    local opts = cfg.Options or {"Option 1","Option 2"}
    local selected = cfg.Default or opts[1]
    local cb = cfg.Callback or function() end
    local open = false

    local row = glassRow(tab.content, Sizes.Row)
    row.ClipsDescendants = false
    row.ZIndex = 2
    rowLabel(row, name)

    local display = new("TextButton", {
        Text = tostring(selected), FontFace = Fonts.Reg,
        TextColor3 = Theme.Text, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.35,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 180, 0, 28),
        ZIndex = 3,
        Parent = row,
    })
    corner(display, 8)
    stroke(display, Theme.Border, 0.7, 1)
    padding(display, 0, 0, 10, 22)

    local arrow = new("TextLabel", {
        Text = "v", FontFace = Fonts.Bold, TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 14, 0, 14),
        TextSize = 12, Parent = display, ZIndex = 3,
    })

    local list = new("ScrollingFrame", {
        BackgroundColor3 = Theme.Background2,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 4),
        Size = UDim2.new(1, 0, 0, math.min(#opts * 28, 140)),
        CanvasSize = UDim2.new(0,0,0,#opts*28),
        Visible = false,
        ZIndex = 100,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        Parent = row,
    })
    corner(list, 8)
    stroke(list, Theme.Border, 0.6, 1)
    listLayout(list, 0)

    local function addOption(opt)
        local o = new("TextButton", {
            Text = opt, FontFace = Fonts.Reg, TextColor3 = Theme.Text, TextSize = 12,
            BackgroundColor3 = Theme.Glass, BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1,0,0,28), ZIndex = 100, Parent = list,
        })
        padding(o, 0,0,12,0)
        o.MouseEnter:Connect(function() tw(o, {BackgroundTransparency = 0.7}, Anim.Fast) end)
        o.MouseLeave:Connect(function() tw(o, {BackgroundTransparency = 1}, Anim.Fast) end)
        o.MouseButton1Click:Connect(function()
            selected = opt
            display.Text = tostring(opt)
            cb(opt)
            open = false
            list.Visible = false
            tw(arrow, {Rotation = 0}, Anim.Fast)
        end)
    end
    for _, o in ipairs(opts) do addOption(o) end

    display.MouseButton1Click:Connect(function()
        open = not open
        list.Visible = open
        tw(arrow, {Rotation = open and 180 or 0}, Anim.Fast)
    end)

    return {
        Set = function(_, v) selected = v; display.Text = tostring(v); cb(v) end,
        Get = function() return selected end,
        Refresh = function(_, newOpts)
            opts = newOpts
            for _, ch in ipairs(list:GetChildren()) do
                if ch:IsA("TextButton") then ch:Destroy() end
            end
            for _, o in ipairs(opts) do addOption(o) end
            list.CanvasSize = UDim2.new(0,0,0,#opts*28)
            list.Size = UDim2.new(1,0,0, math.min(#opts * 28, 140))
        end,
    }
end

-- ============================================================
-- TEXTBOX
-- ============================================================
function Library._textbox(tab, cfg)
    local name = cfg.Name or "TextBox"
    local val = cfg.Default or ""
    local ph = cfg.Placeholder or "Type..."
    local cb = cfg.Callback or function() end

    local row = glassRow(tab.content, Sizes.Row)
    rowLabel(row, name)

    local box = new("TextBox", {
        Text = val, PlaceholderText = ph, PlaceholderColor3 = Theme.TextDim,
        FontFace = Fonts.Reg, TextColor3 = Theme.Text, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.35,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 180, 0, 28),
        ClearTextOnFocus = false,
        Parent = row,
    })
    corner(box, 8)
    local bs = stroke(box, Theme.Border, 0.7, 1)
    padding(box, 0, 0, 10, 10)

    box.Focused:Connect(function() tw(bs, {Color = Theme.Accent, Transparency = 0.3}, Anim.Fast) end)
    box.FocusLost:Connect(function(enter)
        tw(bs, {Color = Theme.Border, Transparency = 0.7}, Anim.Fast)
        val = box.Text
        cb(val, enter)
    end)

    return {
        SetText = function(_, t) val = tostring(t); box.Text = val end,
        GetText = function() return val end,
    }
end

-- ============================================================
-- KEYBIND
-- ============================================================
function Library._keybind(tab, cfg)
    local name = cfg.Name or "Keybind"
    local key = cfg.Default or Enum.KeyCode.F
    local cb = cfg.Callback or function() end
    local listening = false

    local row = glassRow(tab.content, Sizes.Row)
    rowLabel(row, name)

    local box = new("TextButton", {
        Text = key.Name, FontFace = Fonts.Bold, TextColor3 = Theme.Text, TextSize = 12,
        BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.35,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 70, 0, 26),
        Parent = row,
    })
    corner(box, 8); stroke(box, Theme.Border, 0.7, 1)

    local id = tostring(tick()) .. name
    tab._lib._keybinds[id] = { key = key, cb = cb }

    box.MouseButton1Click:Connect(function()
        listening = true
        box.Text = "..."
    end)
    UserInputService.InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode
            listening = false
            box.Text = key.Name
            tab._lib._keybinds[id].key = key
        end
    end)

    return {
        SetKey = function(_, k) key = k; box.Text = k.Name; tab._lib._keybinds[id].key = k end,
        GetKey = function() return key end,
    }
end

-- ============================================================
-- COLOR PICKER
-- ============================================================
function Library._colorpicker(tab, cfg)
    local name = cfg.Name or "Color"
    local col = cfg.Default or Color3.fromRGB(120, 180, 255)
    local cb = cfg.Callback or function() end
    local h, s, v = col:ToHSV()

    local row = glassRow(tab.content, Sizes.Row)
    rowLabel(row, name)

    local prev = new("Frame", {
        BackgroundColor3 = col,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 20),
        Parent = row,
    })
    corner(prev, 6); stroke(prev, Theme.Border, 0.4, 1)

    local popup = new("Frame", {
        BackgroundColor3 = Theme.Background2, BackgroundTransparency = 0.2,
        Size = UDim2.new(0, 170, 0, 130), Visible = false, ZIndex = 200,
        Parent = tab._lib.root,
    })
    corner(popup, 10); stroke(popup, Theme.Border, 0.5, 1)

    local sv = new("Frame", {
        BackgroundColor3 = Color3.fromHSV(h,1,1),
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 90),
        ZIndex = 201, Parent = popup,
    })
    corner(sv, 6)

    local wl = new("Frame", {BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1,0,1,0), ZIndex = 202, Parent = sv})
    corner(wl, 6)
    new("UIGradient", {
        Color = ColorSequence.new(Color3.new(1,1,1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1),
        }), Parent = wl,
    })

    local bl = new("Frame", {BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1,0,1,0), ZIndex = 203, Parent = sv})
    corner(bl, 6)
    new("UIGradient", {
        Color = ColorSequence.new(Color3.new(0,0,0)),
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0),
        }), Parent = bl,
    })

    local cursor = new("Frame", {
        BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(s, 0, 1-v, 0),
        Size = UDim2.new(0, 10, 0, 10), ZIndex = 205, Parent = sv,
    })
    corner(cursor, 100)
    new("UIStroke", {Color = Color3.new(1,1,1), Thickness = 1.5, Parent = cursor})

    local hueBar = new("Frame", {
        Position = UDim2.new(0, 8, 1, -24),
        Size = UDim2.new(1, -16, 0, 10), ZIndex = 201, Parent = popup,
    })
    corner(hueBar, 100)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1,1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1,1)),
            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1)),
        }),
        Parent = hueBar,
    })
    local hueCur = new("Frame", {
        BackgroundColor3 = Color3.new(1,1,1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(h, 0, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 10), ZIndex = 205, Parent = hueBar,
    })
    corner(hueCur, 100)
    new("UIStroke", {Color = Color3.fromRGB(20,20,20), Thickness = 1, Parent = hueCur})

    local function update()
        col = Color3.fromHSV(h, s, v)
        prev.BackgroundColor3 = col
        sv.BackgroundColor3 = Color3.fromHSV(h,1,1)
        cursor.Position = UDim2.new(s, 0, 1-v, 0)
        hueCur.Position = UDim2.new(h, 0, 0.5, 0)
        cb(col)
    end

    local svDrag, hueDrag = false, false
    sv.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end
    end)
    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if svDrag then
            local ap, as = sv.AbsolutePosition, sv.AbsoluteSize
            s = math.clamp((i.Position.X - ap.X) / as.X, 0, 1)
            v = 1 - math.clamp((i.Position.Y - ap.Y) / as.Y, 0, 1)
            update()
        elseif hueDrag then
            local ap, as = hueBar.AbsolutePosition, hueBar.AbsoluteSize
            h = math.clamp((i.Position.X - ap.X) / as.X, 0, 1)
            update()
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false; hueDrag = false end
    end)

    local btn = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Parent = prev})
    btn.MouseButton1Click:Connect(function()
        local ap = prev.AbsolutePosition
        popup.Position = UDim2.new(0, ap.X - 130, 0, ap.Y + 26)
        popup.Visible = not popup.Visible
    end)

    return {
        SetColor = function(_, c) h,s,v = c:ToHSV(); update() end,
        GetColor = function() return col end,
    }
end

-- ============================================================
-- LABEL & DIVIDER
-- ============================================================
function Library._label(tab, cfg)
    local row = glassRow(tab.content, 38)
    rowLabel(row, cfg.Name or "Label")
    local dot = new("Frame", {
        BackgroundColor3 = cfg.Color or Theme.Success,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 8, 0, 8), Parent = row,
    })
    corner(dot, 100)
    local txt = new("TextLabel", {
        FontFace = Fonts.Reg, TextColor3 = cfg.Color or Theme.Success, Text = cfg.Text or "",
        TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -28, 0.5, 0),
        Size = UDim2.new(0, 150, 0, 20), TextSize = 12, Parent = row,
    })
    return {
        SetText = function(_, t) txt.Text = t end,
        SetColor = function(_, c) txt.TextColor3 = c; dot.BackgroundColor3 = c end,
    }
end

function Library._divider(tab, text)
    local f = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, (text and text ~= "") and 22 or 10),
        Parent = tab.content,
    })
    if text and text ~= "" then
        local function line(anchor, pos, sx)
            return new("Frame", {
                BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.5,
                AnchorPoint = anchor, Position = pos,
                Size = UDim2.new(sx, 0, 0, 1), BorderSizePixel = 0, Parent = f,
            })
        end
        line(Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0), 0.35)
        line(Vector2.new(1, 0.5), UDim2.new(1, 0, 0.5, 0), 0.35)
        new("TextLabel", {
            FontFace = Fonts.Reg, TextColor3 = Theme.TextDim, Text = text,
            BackgroundTransparency = 1, TextSize = 11,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0.3, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, Parent = f,
        })
    else
        new("Frame", {
            BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.5,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -20, 0, 1), BorderSizePixel = 0, Parent = f,
        })
    end
    return {}
end

return Library
