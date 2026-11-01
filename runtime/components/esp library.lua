local previous = getgenv().ESP
if type(previous) == 'table' and type(previous._Cleanup) == 'function' then
    pcall(previous._Cleanup)
end
local ESP: { [string]: any } = {
    Backend = 'Unnamed',
    StartupRevision = 23,
    PhowgBarHookRevision = 1,
    SupportsSpatialBarGradient = true,
    NativeBarGradients = true,
    CrewNames = {},
    CrewIds = {},
    CrewIcons = {},
    CrewCounts = {},
}
ESP.PhowgBarHookRevision = 1
ESP.NativeLabelSpacing = true
ESP.SupportsPlayerStats = true
ESP.SupportsFlags = true
ESP.SupportsVisionGlow = true
ESP.SupportsCountryNames = true
ESP.SupportsCountryIPv4 = true
ESP.LazyDrawings = true
ESP.SupportsPerformanceMetrics = true
ESP.SupportsDistanceDetail = true
getgenv().ESP = ESP
local Players, RunService, CoreGui, UserInputService =
    game:GetService('Players'),
    game:GetService('RunService'),
    game:GetService('CoreGui'),
    game:GetService('UserInputService')
local LocalPlayer, Workspace = Players.LocalPlayer, workspace
local SharedConnect = getgenv().PhowgSharedConnect
ESP.SharedConnectProvider = SharedConnect
local utility, connections, cache = { funcs = {} }, {}, {}
local floor, clamp, exp, atan2, clock = math.floor, math.clamp, math.exp, math.atan2, os.clock
local white, black = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local cheaterRed = Color3.fromRGB(255, 55, 55)
local identityCFrame = CFrame.new()
local one2D, two2D = Vector2.new(1, 1), Vector2.new(2, 2)
local lowerOffset, upperOffset = Vector3.new(0, 1, 0), Vector3.new(0, 3, 0)
local defaultHealthTextOffset = Vector2.new(-28, 0)
local emptyBarSpacing = { Top = 0, Bottom = 0, Right = 0 }
local barKinds = { 'Health', 'Armor' }
ESP.BarWhiteColor = white
local gui = Instance.new('ScreenGui')
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder = 'PhowgUnnamedESP', true, false, 9700
local parent = CoreGui
if gethui then
    local ok, hidden = pcall(gethui)
    if ok and typeof(hidden) == 'Instance' then
        parent = hidden
    end
end
gui.Parent = parent
local alive, enabled, revision = true, false, 0
ESP.Settings = {
    Performance = { Profile = false },
    DistanceDetail = { Enabled = false, Distance = 300, HideEffects = true, HideSecondary = true },
    DetectCheaters = { Enabled = false, RedName = true },
    Money = { Enabled = false, Color = Color3.new(1, 1, 1) },
    Device = { Enabled = false, Color = Color3.new(1, 1, 1) },
    Flags = {
        Enabled = false,
        Types = {
            walking = true,
            running = true,
            attacking = true,
            shooting = true,
            masked = true,
            flung = true,
            flying = true,
            macroing = true,
        },
        Color = Color3.new(1, 1, 1),
    },
    Inventory = { Enabled = false, Color = Color3.new(1, 1, 1) },
    Accuracy = { Enabled = false, Mode = 'all time', Color = Color3.new(1, 1, 1) },
    Country = { Enabled = false, Color = Color3.new(1, 1, 1), SimulatedIP = false },
    Target = { Enabled = false, Color = Color3.fromRGB(255, 90, 90) },
    BoxStyle = {
        Gradient = false,
        Animate = false,
        Mode = 'circling box to left',
        Speed = 1,
        Colors = { white, white, white },
        Glow = false,
        GlowColor = white,
        GlowIntensity = 0.2,
    },
    Box = {
        Enabled = false,
        Thickness = 1,
        Animated = true,
        AnimationSpeed = 0,
        Colors = {
            Top = Color3.fromRGB(255, 255, 255),
            Right = Color3.fromRGB(255, 255, 255),
            Bottom = Color3.fromRGB(255, 255, 255),
            Left = Color3.fromRGB(255, 255, 255),
        },
    },
    Name = {
        Enabled = false,
        DisableMasks = false,
        HideNormalNames = false,
        Use_Both_Name = true,
        Use_User_Name = false,
        Use_Display_Name = false,
        Color = Color3.fromRGB(255, 255, 255),
    },
    Character = {
        Hide_Tags = true,
    },
    Self = {
        Enabled = false,
    },
    ForceField = {
        Enabled = false,
        Color = Color3.fromRGB(100, 180, 255),
        Transparency = 0.7,
    },
    Bars = {
        Type = 'Gradient',
        Speed = 0,
        Health = {
            Enabled = false,
            Offset = Vector2.new(6, 1),
            Gradient = true,
            Moving_Gradient = true,
            Colors = {
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 255, 255),
            },
        },
        Armor = {
            Enabled = false,
            Offset = Vector2.new(10, 1),
            Gradient = true,
            Moving_Gradient = true,
            Hide_If_Empty = true,
            Colors = {
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 255, 255),
            },
        },
    },
    Chams = {
        Enabled = false,
        Offset = Vector3.new(0.01, 0.01, 0.01),
        ZIndex = 1,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0,
    },
    Image = {
        Enabled = false,
        Data = 'Gradient',
    },
    Distance = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
    },
    Tracer = {
        Enabled = false,
        Origin = 'Above',
        Outline = true,
        Origin_Position = Vector2.zero,
        Color = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(255, 255, 255),
    },
    Highlight = {
        Enabled = false,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        FillColor = Color3.fromRGB(255, 255, 255),
        FillTransparency = 0.5,
        OutlineColor = Color3.fromRGB(255, 255, 255),
        OutlineTransparency = 0,
    },
    ToolText = {
        HideNone = false,
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
    },
    WeaponIcon = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
    },
    HealthText = {
        Enabled = false,
        NormalOffset = Vector2.new(12, 1),
        Offset = Vector2.new(12, 1),
        HideFullHealth = false,
        Color = Color3.fromRGB(255, 255, 255),
    },
    Wanted = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
    },
    Animation = {
        Mode = 'none',
    },
    Crew = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Count = false,
    },
    DistanceLimit = {
        Enabled = false,
        MaxDistance = 1000,
    },
    Misc = {
        FontName = 'Code',
        LabelGap = 1,
        Glow = false,
        Offset = Vector3.new(0, 0.5, 0),
        BarOffset = Vector2.new(0, 1),
        ZeroSize = Vector2.zero,
        MainFont = (identifyexecutor and identifyexecutor() == 'Wave') and 1 or 2,
        MainSize = 13,
        SmallFont = (identifyexecutor and identifyexecutor() == 'Wave') and 1 or 2,
        SmallSize = (identifyexecutor and identifyexecutor() == 'Wave') and 13 or 11,
    },
}
local timingKeys = { 'ProjectionMs', 'LabelsIconsMs', 'EffectsMs', 'OtherMs', 'TotalMs' }
ESP.Performance = { Enabled = false, Frames = 0, Visible = 0, Tracked = 0, Last = {}, Average = {}, Peak = {} }
function ESP:ResetPerformance()
    local metrics = self.Performance
    metrics.Frames, metrics.Visible, metrics.Tracked = 0, 0, 0
    for _, key in ipairs(timingKeys) do
        metrics.Last[key], metrics.Average[key], metrics.Peak[key] = 0, 0, 0
    end
end
ESP:ResetPerformance()
local function profileStage(frame, key, started)
    if started then
        frame[key] += clock() - started
    end
end
local function connect(signal, fn, owner, label, recordOwned, channel, signalOwner)
    local connection = SharedConnect and SharedConnect(signal, fn, owner, label, 0, channel, signalOwner)
        or signal:Connect(fn)
    if not recordOwned then
        connections[#connections + 1] = connection
    end
    return connection
end
local function widget(class, parent)
    local item = Instance.new(class)
    item.BackgroundTransparency, item.BackgroundColor3, item.BorderSizePixel, item.Visible, item.Parent =
        1, white, 0, false, parent or gui
    return item
end
local function materializedDrawing(kind, owner, record)
    local native
    if (kind == 'Image') and Drawing and Drawing.new then
        local ok, result = pcall(function()
            return Drawing.new('Image')
        end)
        if ok then
            native = result
        end
    end
    local item = native or widget(kind == 'Text' and 'TextLabel' or kind == 'Image' and 'ImageLabel' or 'Frame', owner)
    local stroke
    if kind == 'Text' then
        item.Font, item.TextSize, item.TextColor3, item.TextStrokeColor3, item.TextStrokeTransparency =
            Enum.Font.Code, 13, white, black, 0
        item.Size, item.TextXAlignment, item.TextYAlignment =
            UDim2.fromOffset(200, 18), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
    elseif kind == 'Square' then
        stroke = Instance.new('UIStroke')
        stroke.Color, stroke.Thickness, stroke.Parent = white, 1, item
    end
    local state: { [string]: any } = {
        Visible = false,
        Position = Vector2.zero,
        Size = Vector2.zero,
        From = Vector2.zero,
        To = Vector2.zero,
        Color = white,
        Transparency = 1,
        Filled = kind == 'Bar' or kind == 'Line',
        Thickness = 1,
        Text = '',
        Center = false,
        Native = native,
        Object = item,
        Kind = kind,
    }
    if native then
        native.Visible, native.Transparency, native.Color = false, 1, white
    elseif state.Filled then
        item.BackgroundTransparency = 0
    end
    local glow
    if kind == 'Text' and not native then
        glow = Instance.new('UIStroke')
        glow.Color, glow.Thickness, glow.Transparency, glow.Enabled = Color3.fromRGB(255, 115, 55), 2, 0.7, false
        glow.Parent = item
    end
    local proxy = {}
    local function line()
        local from, to = state.From or Vector2.zero, state.To or Vector2.zero
        local delta = to - from
        item.AnchorPoint, item.Position =
            Vector2.new(0.5, 0.5), UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
        item.Size, item.Rotation =
            UDim2.fromOffset(delta.Magnitude, math.max(1, state.Thickness)), math.deg(atan2(delta.Y, delta.X))
    end
    local function remove()
        if native then
            native:Remove()
        else
            item:Destroy()
        end
    end
    local function endpoints(_, from, to)
        if state.From == from and state.To == to then
            return
        end
        state.From, state.To = from, to
        line()
    end
    return setmetatable(proxy, {
        __index = function(_, key)
            if key == 'Remove' or key == 'Destroy' then
                return remove
            end
            if key == 'SetEndpoints' then
                return endpoints
            end
            if key == 'TextBounds' then
                return kind == 'Text' and item.TextBounds or Vector2.zero
            end
            return state[key]
        end,
        __newindex = function(_, key, value)
            if key == 'Position' and record and not native then
                state.Position = value
                local offset = value - record.DrawOrigin
                local previous = state.GuiPosition
                if
                    not previous
                    or math.abs(previous.X - offset.X) > 0.000001
                    or math.abs(previous.Y - offset.Y) > 0.000001
                then
                    item.Position = UDim2.fromOffset(offset.X, offset.Y)
                    state.GuiPosition = offset
                end
                return
            end
            if state[key] == value then
                return
            end
            state[key] = value
            if native then
                native[key] = value
                return
            end
            if key == 'Position' then
                item.Position = UDim2.fromOffset(value.X, value.Y)
            elseif key == 'Size' then
                if type(value) == 'number' then
                    item.TextSize = value
                else
                    item.Size = UDim2.fromOffset(math.max(0, value.X), math.max(0, value.Y))
                end
            elseif key == 'Visible' then
                item.Visible = value
            elseif key == 'Color' then
                if kind == 'Text' then
                    item.TextColor3 = value
                elseif kind == 'Image' then
                    item.ImageColor3 = value
                else
                    item.BackgroundColor3 = value
                    if stroke then
                        stroke.Color = value
                    end
                end
            elseif key == 'Transparency' then
                if kind == 'Text' then
                    item.TextTransparency, item.TextStrokeTransparency = 1 - value, 1 - value
                elseif kind == 'Image' then
                    item.ImageTransparency = 1 - value
                else
                    item.BackgroundTransparency = state.Filled and 1 - value or 1
                    if stroke then
                        stroke.Transparency = 1 - value
                    end
                end
            elseif key == 'Filled' then
                item.BackgroundTransparency = value and 1 - state.Transparency or 1
                if stroke then
                    stroke.Enabled = not value
                end
            elseif key == 'Thickness' then
                if stroke then
                    stroke.Thickness = value
                elseif kind == 'Line' then
                    line()
                end
            elseif key == 'Font' then
                item.Font = value
            elseif key == 'Glow' then
                if glow then
                    glow.Enabled = value == true
                end
            elseif key == 'Text' then
                item.Text = value
            elseif key == 'Center' then
                item.AnchorPoint = value and Vector2.new(0.5, 0) or Vector2.zero
                item.TextXAlignment = value and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
            elseif key == 'From' or key == 'To' then
                line()
            elseif key == 'ZIndex' then
                item.ZIndex = math.clamp(value, 1, 10000)
            elseif key == 'Data' then
                if type(value) == 'string' and value:sub(1, 13) == 'rbxassetid://' then
                    item.Image = value
                end
            end
        end,
    })
end
local function drawing(kind, owner, record)
    local target, removed
    local pending = {}
    local defaults = {
        Visible = false,
        Position = Vector2.zero,
        Size = Vector2.zero,
        From = Vector2.zero,
        To = Vector2.zero,
        Color = white,
        Transparency = 1,
        Filled = kind == 'Bar' or kind == 'Line',
        Thickness = 1,
        Text = '',
        Center = false,
        Kind = kind,
    }
    local function ensure()
        if target or removed then
            return target
        end
        target = materializedDrawing(kind, owner, record)
        for _, key in ipairs({
            'Center',
            'Filled',
            'Size',
            'Color',
            'Transparency',
            'Thickness',
            'Text',
            'Data',
            'ZIndex',
            'Position',
            'From',
            'To',
            'Visible',
        }) do
            if pending[key] ~= nil then
                target[key] = pending[key]
            end
        end
        table.clear(pending)
        return target
    end
    local function remove()
        removed = true
        if target then
            target:Remove()
            target = nil
        end
        table.clear(pending)
    end
    local function endpoints(_, from, to)
        if target then
            target:SetEndpoints(from, to)
        else
            pending.From, pending.To = from, to
        end
    end
    return setmetatable({}, {
        __index = function(_, key)
            if key == 'Remove' or key == 'Destroy' then
                return remove
            end
            if key == 'SetEndpoints' then
                return endpoints
            end
            if key == 'Object' or key == 'TextBounds' then
                local draw = ensure()
                return draw and draw[key]
            end
            if target then
                return target[key]
            end
            if pending[key] ~= nil then
                return pending[key]
            end
            return defaults[key]
        end,
        __newindex = function(_, key, value)
            if removed then
                return
            end
            if target then
                target[key] = value
            else
                pending[key] = value
                if key == 'Visible' and value == true then
                    ensure()
                end
            end
        end,
    })
end

local function getArmor(character)
    local body = character and character:FindFirstChild('BodyEffects')
    return body and body:FindFirstChild('Armor')
end
local function restoreNormalName(record)
    local state = record.NormalNameState
    if not state then
        return
    end
    record.NormalNameState = nil
    if state.Connection then
        state.Connection:Disconnect()
    end
    if state.Humanoid.Parent and state.Humanoid.NameDisplayDistance == 0 then
        state.Humanoid.NameDisplayDistance = state.Distance
    end
end
local function syncNormalName(record)
    local humanoid = record.Humanoid
    local wanted = ESP.Settings.Name.Enabled
        and ESP.Settings.Name.HideNormalNames
        and record.Player ~= LocalPlayer
        and humanoid
        and humanoid.Parent
    local state = record.NormalNameState
    if state and (not wanted or state.Humanoid ~= humanoid) then
        restoreNormalName(record)
        state = nil
    end
    if not wanted or state then
        return
    end
    state = { Humanoid = humanoid, Distance = humanoid.NameDisplayDistance }
    record.NormalNameState = state
    state.Connection = connect(humanoid:GetPropertyChangedSignal('NameDisplayDistance'), function()
        if record.NormalNameState == state and humanoid.NameDisplayDistance ~= 0 then
            state.Distance = humanoid.NameDisplayDistance
            humanoid.NameDisplayDistance = 0
        end
    end, record.Player, 'esp normal name distance', true)
    humanoid.NameDisplayDistance = 0
end
local function bind(record, character)
    restoreNormalName(record)
    for _, connection in ipairs(record.CharacterConnections or {}) do
        connection:Disconnect()
    end
    record.CharacterConnections = {}
    for _, adornment in pairs(record.Chams or {}) do
        adornment:Destroy()
    end
    record.Chams = {}
    record.ChamStates = {}
    record.ChamsVisible = false
    if record.Highlight then
        record.Highlight:Destroy()
        record.Highlight = nil
    end
    if record.ForceFieldBubble then
        record.ForceFieldBubble:Destroy()
        record.ForceFieldBubble = nil
    end
    record.HighlightState, record.ForceFieldState = nil, nil
    if record.ToolNameConnection then
        record.ToolNameConnection:Disconnect()
        record.ToolNameConnection = nil
    end
    record.EquippedTool, record.ToolName, record.IconToolName, record.IconKey = nil, 'none', nil, nil
    record.FlagState, record.FlagsText = nil, ''
    record.Character, record.Parts, record.LastHealth, record.LastArmor = character, {}, nil, nil
    local function refresh()
        record.Root = character and character:FindFirstChild('HumanoidRootPart')
        record.Anchor = character
            and (character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso') or record.Root)
        record.Humanoid = character and character:FindFirstChildOfClass('Humanoid')
        record.Mask = character and character:FindFirstChild('In-gameMask')
        syncNormalName(record)
        record.ArmorValue = getArmor(character)
        local tool = character and character:FindFirstChildOfClass('Tool')
        if record.EquippedTool ~= tool then
            if record.ToolNameConnection then
                record.ToolNameConnection:Disconnect()
                record.ToolNameConnection = nil
            end
            record.EquippedTool, record.ToolName, record.IconToolName, record.IconKey, record.IconData =
                tool, tool and tool.Name or 'none', nil, nil, nil
            if tool and (ESP.Settings.ToolText.Enabled or ESP.Settings.WeaponIcon.Enabled) then
                record.ToolNameConnection = connect(tool:GetPropertyChangedSignal('Name'), function()
                    record.ToolName, record.IconToolName, record.IconKey = tool.Name, nil, nil
                end, record.Player, 'esp tool name', true)
            end
        end
        record.ForceFieldInstance = character and character:FindFirstChildOfClass('ForceField')
        record.ForceFieldValue = character
            and (character:FindFirstChild('Forcefield') or character:FindFirstChild('ForceField'))
    end
    local function added(part)
        if part:IsA('BasePart') then
            record.Parts[part] = true
        end
        if
            part.Name == 'Armor'
            and part.Parent
            and part.Parent.Name == 'BodyEffects'
            and part.Parent.Parent == character
        then
            record.ArmorValue = part
        end
    end
    local function removed(part)
        record.Parts[part] = nil
        local adornment = record.Chams and record.Chams[part]
        if adornment then
            adornment:Destroy()
            record.Chams[part], record.ChamStates[part] = nil, nil
        end
        if part == record.ArmorValue then
            record.ArmorValue = nil
        end
    end
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA('BasePart') then
                record.Parts[part] = true
            end
        end
        record.CharacterConnections[1] =
            connect(character.DescendantAdded, added, record.Player, 'unnamed character added', true)
        record.CharacterConnections[2] =
            connect(character.DescendantRemoving, removed, record.Player, 'unnamed character removed', true)
        record.CharacterConnections[3] =
            connect(character.ChildRemoved, refresh, record.Player, 'unnamed tool removed', true)
        record.CharacterConnections[4] =
            connect(character.ChildAdded, refresh, record.Player, 'unnamed tool added', true)
    end
    refresh()
end
function utility.funcs.render(player, record)
    if record.Drawings then
        return
    end
    record.Drawings, record.Gradients = {}, {}
    record.DrawOrigin = Vector2.zero
    record.DrawFrame = widget('Frame')
    record.DrawFrame.Size, record.DrawFrame.Visible = UDim2.fromOffset(0, 0), true
    local function draw(kind)
        return drawing(kind, kind == 'Line' and gui or record.DrawFrame, kind ~= 'Line' and record or nil)
    end
    record.Chams, record.ChamStates = record.Chams or {}, record.ChamStates or {}
    local draws = record.Drawings
    for _, name in ipairs({ 'Box', 'BoxOutline', 'BoxInline' }) do
        draws[name] = draw('Square')
        draws[name].ZIndex = 3
    end
    draws.BoxGlow = draw('Square')
    draws.BoxGlow.ZIndex = 2
    for _, name in ipairs({
        'Name',
        'Distance',
        'ToolText',
        'HealthText',
        'WantedText',
        'ForceFieldText',
        'CrewText',
        'CrewCount',
        'AccuracyText',
        'CountryText',
        'MoneyText',
        'DeviceText',
        'InventoryText',
        'FlagsText',
    }) do
        draws[name] = draw('Text')
        draws[name].ZIndex = 5
        draws[name].Center = name == 'Name'
            or name == 'Distance'
            or name == 'ToolText'
            or name == 'CrewText'
            or name == 'CountryText'
            or name == 'MoneyText'
            or name == 'DeviceText'
            or name == 'InventoryText'
    end
    for _, kind in ipairs(barKinds) do
        draws[kind .. 'BarOutline'], draws[kind .. 'Bar'] = draw('Bar'), draw('Bar')
        draws[kind .. 'BarOutline'].ZIndex, draws[kind .. 'Bar'].ZIndex = 3, 4
    end
    draws.Tracer, draws.TracerOutline, draws.Image, draws.WeaponIcon, draws.CrewIcon =
        draw('Line'), draw('Line'), draw('Bar'), draw('Image'), draw('Image')
    draws.Tracer.ZIndex, draws.TracerOutline.ZIndex = 3, 2
    draws.Image.ZIndex, draws.WeaponIcon.ZIndex, draws.CrewIcon.ZIndex = 1, 5, 5
    draws.BoxOutline.Color, draws.BoxInline.Color, draws.HealthBarOutline.Color, draws.ArmorBarOutline.Color =
        black, black, black, black
end
function utility.funcs.clear_esp(player, record)
    record = record or cache[player]
    if not record or not record.Rendering then
        return
    end
    record.Rendering = false
    record.DrawingVisible = false
    for _, object in pairs(record.Drawings or {}) do
        object.Visible = false
    end
    for part, object in pairs(record.Chams or {}) do
        local state = record.ChamStates and record.ChamStates[part]
        if not state or state.Visible then
            object.Visible = false
            if state then
                state.Visible = false
            end
        end
    end
    record.ChamsVisible = false
    if record.Highlight then
        record.Highlight.Enabled = false
        if record.HighlightState then
            record.HighlightState.Enabled = false
        end
    end
    if record.ForceFieldBubble then
        record.ForceFieldBubble.Visible = false
        if record.ForceFieldState then
            record.ForceFieldState.Visible = false
        end
    end
end
local statKeys =
    { 'LockFlagged', 'AimLandAllTime', 'AimShotsAllTime', 'ShotLand', 'ShotTotal', 'Country', 'Device', 'Currency' }
local countryNames = {
    ['AD'] = 'Andorra',
    ['AE'] = 'United Arab Emirates',
    ['AF'] = 'Afghanistan',
    ['AG'] = 'Antigua & Barbuda',
    ['AI'] = 'Anguilla',
    ['AL'] = 'Albania',
    ['AM'] = 'Armenia',
    ['AO'] = 'Angola',
    ['AQ'] = 'Antarctica',
    ['AR'] = 'Argentina',
    ['AS'] = 'American Samoa',
    ['AT'] = 'Austria',
    ['AU'] = 'Australia',
    ['AW'] = 'Aruba',
    ['AX'] = 'Åland Islands',
    ['AZ'] = 'Azerbaijan',
    ['BA'] = 'Bosnia & Herzegovina',
    ['BB'] = 'Barbados',
    ['BD'] = 'Bangladesh',
    ['BE'] = 'Belgium',
    ['BF'] = 'Burkina Faso',
    ['BG'] = 'Bulgaria',
    ['BH'] = 'Bahrain',
    ['BI'] = 'Burundi',
    ['BJ'] = 'Benin',
    ['BL'] = 'St. Barthélemy',
    ['BM'] = 'Bermuda',
    ['BN'] = 'Brunei',
    ['BO'] = 'Bolivia',
    ['BQ'] = 'Bonaire, Sint Eustatius and Saba',
    ['BR'] = 'Brazil',
    ['BS'] = 'Bahamas',
    ['BT'] = 'Bhutan',
    ['BW'] = 'Botswana',
    ['BY'] = 'Belarus',
    ['BZ'] = 'Belize',
    ['CA'] = 'Canada',
    ['CC'] = 'Cocos (Keeling) Islands',
    ['CD'] = 'Congo (DRC)',
    ['CF'] = 'Central African Republic',
    ['CG'] = 'Congo',
    ['CH'] = 'Switzerland',
    ['CI'] = 'Côte d’Ivoire',
    ['CK'] = 'Cook Islands',
    ['CL'] = 'Chile',
    ['CM'] = 'Cameroon',
    ['CN'] = 'China',
    ['CO'] = 'Colombia',
    ['CR'] = 'Costa Rica',
    ['CU'] = 'Cuba',
    ['CV'] = 'Cabo Verde',
    ['CW'] = 'Curaçao',
    ['CX'] = 'Christmas Island',
    ['CY'] = 'Cyprus',
    ['CZ'] = 'Czechia',
    ['DE'] = 'Germany',
    ['DJ'] = 'Djibouti',
    ['DK'] = 'Denmark',
    ['DM'] = 'Dominica',
    ['DO'] = 'Dominican Republic',
    ['DZ'] = 'Algeria',
    ['EC'] = 'Ecuador',
    ['EE'] = 'Estonia',
    ['EG'] = 'Egypt',
    ['ER'] = 'Eritrea',
    ['ES'] = 'Spain',
    ['ET'] = 'Ethiopia',
    ['FI'] = 'Finland',
    ['FJ'] = 'Fiji',
    ['FK'] = 'Falkland Islands',
    ['FM'] = 'Micronesia',
    ['FO'] = 'Faroe Islands',
    ['FR'] = 'France',
    ['GA'] = 'Gabon',
    ['GB'] = 'United Kingdom',
    ['GD'] = 'Grenada',
    ['GE'] = 'Georgia',
    ['GF'] = 'French Guiana',
    ['GG'] = 'Guernsey',
    ['GH'] = 'Ghana',
    ['GI'] = 'Gibraltar',
    ['GL'] = 'Greenland',
    ['GM'] = 'Gambia',
    ['GN'] = 'Guinea',
    ['GP'] = 'Guadeloupe',
    ['GQ'] = 'Equatorial Guinea',
    ['GR'] = 'Greece',
    ['GT'] = 'Guatemala',
    ['GU'] = 'Guam',
    ['GW'] = 'Guinea-Bissau',
    ['GY'] = 'Guyana',
    ['HK'] = 'Hong Kong SAR',
    ['HN'] = 'Honduras',
    ['HR'] = 'Croatia',
    ['HT'] = 'Haiti',
    ['HU'] = 'Hungary',
    ['ID'] = 'Indonesia',
    ['IE'] = 'Ireland',
    ['IL'] = 'Israel',
    ['IM'] = 'Isle of Man',
    ['IN'] = 'India',
    ['IO'] = 'British Indian Ocean Territory',
    ['IQ'] = 'Iraq',
    ['IR'] = 'Iran',
    ['IS'] = 'Iceland',
    ['IT'] = 'Italy',
    ['JE'] = 'Jersey',
    ['JM'] = 'Jamaica',
    ['JO'] = 'Jordan',
    ['JP'] = 'Japan',
    ['KE'] = 'Kenya',
    ['KG'] = 'Kyrgyzstan',
    ['KH'] = 'Cambodia',
    ['KI'] = 'Kiribati',
    ['KM'] = 'Comoros',
    ['KN'] = 'St. Kitts & Nevis',
    ['KP'] = 'North Korea',
    ['KR'] = 'Korea',
    ['KW'] = 'Kuwait',
    ['KY'] = 'Cayman Islands',
    ['KZ'] = 'Kazakhstan',
    ['LA'] = 'Laos',
    ['LB'] = 'Lebanon',
    ['LC'] = 'St. Lucia',
    ['LI'] = 'Liechtenstein',
    ['LK'] = 'Sri Lanka',
    ['LR'] = 'Liberia',
    ['LS'] = 'Lesotho',
    ['LT'] = 'Lithuania',
    ['LU'] = 'Luxembourg',
    ['LV'] = 'Latvia',
    ['LY'] = 'Libya',
    ['MA'] = 'Morocco',
    ['MC'] = 'Monaco',
    ['MD'] = 'Moldova',
    ['ME'] = 'Montenegro',
    ['MF'] = 'St. Martin',
    ['MG'] = 'Madagascar',
    ['MH'] = 'Marshall Islands',
    ['MK'] = 'North Macedonia',
    ['ML'] = 'Mali',
    ['MM'] = 'Myanmar',
    ['MN'] = 'Mongolia',
    ['MO'] = 'Macao SAR',
    ['MP'] = 'Northern Mariana Islands',
    ['MQ'] = 'Martinique',
    ['MR'] = 'Mauritania',
    ['MS'] = 'Montserrat',
    ['MT'] = 'Malta',
    ['MU'] = 'Mauritius',
    ['MV'] = 'Maldives',
    ['MW'] = 'Malawi',
    ['MX'] = 'Mexico',
    ['MY'] = 'Malaysia',
    ['MZ'] = 'Mozambique',
    ['NA'] = 'Namibia',
    ['NC'] = 'New Caledonia',
    ['NE'] = 'Niger',
    ['NF'] = 'Norfolk Island',
    ['NG'] = 'Nigeria',
    ['NI'] = 'Nicaragua',
    ['NL'] = 'Netherlands',
    ['NO'] = 'Norway',
    ['NP'] = 'Nepal',
    ['NR'] = 'Nauru',
    ['NU'] = 'Niue',
    ['NZ'] = 'New Zealand',
    ['OM'] = 'Oman',
    ['PA'] = 'Panama',
    ['PE'] = 'Peru',
    ['PF'] = 'French Polynesia',
    ['PG'] = 'Papua New Guinea',
    ['PH'] = 'Philippines',
    ['PK'] = 'Pakistan',
    ['PL'] = 'Poland',
    ['PM'] = 'St. Pierre & Miquelon',
    ['PN'] = 'Pitcairn Islands',
    ['PR'] = 'Puerto Rico',
    ['PS'] = 'Palestine',
    ['PT'] = 'Portugal',
    ['PW'] = 'Palau',
    ['PY'] = 'Paraguay',
    ['QA'] = 'Qatar',
    ['RE'] = 'Réunion',
    ['RO'] = 'Romania',
    ['RS'] = 'Serbia',
    ['RU'] = 'Russia',
    ['RW'] = 'Rwanda',
    ['SA'] = 'Saudi Arabia',
    ['SB'] = 'Solomon Islands',
    ['SC'] = 'Seychelles',
    ['SD'] = 'Sudan',
    ['SE'] = 'Sweden',
    ['SG'] = 'Singapore',
    ['SH'] = 'St Helena, Ascension, Tristan da Cunha',
    ['SI'] = 'Slovenia',
    ['SJ'] = 'Svalbard & Jan Mayen',
    ['SK'] = 'Slovakia',
    ['SL'] = 'Sierra Leone',
    ['SM'] = 'San Marino',
    ['SN'] = 'Senegal',
    ['SO'] = 'Somalia',
    ['SR'] = 'Suriname',
    ['SS'] = 'South Sudan',
    ['ST'] = 'São Tomé & Príncipe',
    ['SV'] = 'El Salvador',
    ['SX'] = 'Sint Maarten',
    ['SY'] = 'Syria',
    ['SZ'] = 'Eswatini',
    ['TC'] = 'Turks & Caicos Islands',
    ['TD'] = 'Chad',
    ['TG'] = 'Togo',
    ['TH'] = 'Thailand',
    ['TJ'] = 'Tajikistan',
    ['TK'] = 'Tokelau',
    ['TL'] = 'Timor-Leste',
    ['TM'] = 'Turkmenistan',
    ['TN'] = 'Tunisia',
    ['TO'] = 'Tonga',
    ['TR'] = 'Türkiye',
    ['TT'] = 'Trinidad & Tobago',
    ['TV'] = 'Tuvalu',
    ['TW'] = 'Taiwan',
    ['TZ'] = 'Tanzania',
    ['UA'] = 'Ukraine',
    ['UG'] = 'Uganda',
    ['UM'] = 'U.S. Outlying Islands',
    ['US'] = 'United States',
    ['UY'] = 'Uruguay',
    ['UZ'] = 'Uzbekistan',
    ['VA'] = 'Vatican City',
    ['VC'] = 'St. Vincent & Grenadines',
    ['VE'] = 'Venezuela',
    ['VG'] = 'British Virgin Islands',
    ['VI'] = 'U.S. Virgin Islands',
    ['VN'] = 'Vietnam',
    ['VU'] = 'Vanuatu',
    ['WF'] = 'Wallis & Futuna',
    ['WS'] = 'Samoa',
    ['XK'] = 'Kosovo',
    ['YE'] = 'Yemen',
    ['YT'] = 'Mayotte',
    ['ZA'] = 'South Africa',
    ['ZM'] = 'Zambia',
    ['ZW'] = 'Zimbabwe',
}
local countryIPv4Ranges = {
    ['AD'] = { 1426644480, 256 },
    ['AE'] = { 37380864, 256 },
    ['AF'] = { 607261952, 256 },
    ['AG'] = { 394563584, 256 },
    ['AI'] = { 3223223296, 256 },
    ['AL'] = { 522789120, 256 },
    ['AM'] = { 531353856, 256 },
    ['AO'] = { 1347946752, 256 },
    ['AQ'] = { 396009472, 256 },
    ['AR'] = { 412629248, 256 },
    ['AS'] = { 1735763968, 256 },
    ['AT'] = { 37410048, 256 },
    ['AU'] = { 16777216, 256 },
    ['AW'] = { 2857696768, 256 },
    ['AX'] = { 1540528640, 256 },
    ['AZ'] = { 534700288, 256 },
    ['BA'] = { 764705536, 256 },
    ['BB'] = { 3337986048, 256 },
    ['BD'] = { 607261696, 256 },
    ['BE'] = { 3225763840, 256 },
    ['BF'] = { 1715764480, 256 },
    ['BG'] = { 37379072, 256 },
    ['BH'] = { 534378752, 256 },
    ['BI'] = { 1724455936, 256 },
    ['BJ'] = { 1725337344, 256 },
    ['BL'] = { 394782720, 256 },
    ['BM'] = { 2732321024, 256 },
    ['BN'] = { 1737190656, 256 },
    ['BO'] = { 755305728, 256 },
    ['BQ'] = { 3239125760, 256 },
    ['BR'] = { 412637696, 256 },
    ['BS'] = { 394318848, 256 },
    ['BT'] = { 607266048, 256 },
    ['BW'] = { 1724562944, 256 },
    ['BY'] = { 86780928, 256 },
    ['BZ'] = { 769731072, 256 },
    ['CA'] = { 1734462208, 256 },
    ['CD'] = { 1713672192, 256 },
    ['CF'] = { 693008384, 256 },
    ['CG'] = { 1724677120, 256 },
    ['CH'] = { 3390333440, 256 },
    ['CI'] = { 769465088, 256 },
    ['CK'] = { 1959249920, 256 },
    ['CL'] = { 765515264, 256 },
    ['CM'] = { 693952512, 256 },
    ['CN'] = { 16777472, 256 },
    ['CO'] = { 43524352, 256 },
    ['CR'] = { 766913280, 256 },
    ['CU'] = { 3288428544, 256 },
    ['CV'] = { 1715836672, 256 },
    ['CW'] = { 3356515584, 256 },
    ['CY'] = { 3392300544, 256 },
    ['CZ'] = { 87675136, 256 },
    ['DE'] = { 1733658368, 256 },
    ['DJ'] = { 1725323776, 256 },
    ['DK'] = { 1738094080, 256 },
    ['DM'] = { 398127104, 256 },
    ['DO'] = { 43524096, 256 },
    ['DZ'] = { 3224692736, 256 },
    ['EC'] = { 759286528, 256 },
    ['EE'] = { 43535872, 256 },
    ['EG'] = { 1715485184, 256 },
    ['ER'] = { 3301466112, 256 },
    ['ES'] = { 3345434880, 256 },
    ['ET'] = { 1725131008, 256 },
    ['FI'] = { 3427833344, 256 },
    ['FJ'] = { 1732758528, 256 },
    ['FK'] = { 1347017216, 256 },
    ['FM'] = { 737713152, 256 },
    ['FO'] = { 786657280, 256 },
    ['FR'] = { 1736061952, 256 },
    ['GA'] = { 3233647360, 256 },
    ['GB'] = { 1735614464, 256 },
    ['GD'] = { 394265600, 256 },
    ['GE'] = { 100612352, 256 },
    ['GF'] = { 766092288, 256 },
    ['GG'] = { 755570432, 256 },
    ['GH'] = { 769464320, 256 },
    ['GI'] = { 1052809984, 256 },
    ['GL'] = { 787715840, 256 },
    ['GM'] = { 3291545856, 256 },
    ['GN'] = { 1724729856, 256 },
    ['GP'] = { 2718750976, 256 },
    ['GQ'] = { 693055488, 256 },
    ['GR'] = { 1403950592, 256 },
    ['GT'] = { 766756352, 256 },
    ['GU'] = { 830499584, 256 },
    ['GW'] = { 1724489728, 256 },
    ['GY'] = { 3006516480, 256 },
    ['HK'] = { 607279616, 256 },
    ['HN'] = { 759439616, 256 },
    ['HR'] = { 531354368, 256 },
    ['HT'] = { 3006516736, 256 },
    ['HU'] = { 764544512, 256 },
    ['ID'] = { 460344320, 256 },
    ['IE'] = { 1091842560, 256 },
    ['IL'] = { 3325141504, 256 },
    ['IM'] = { 94025216, 256 },
    ['IN'] = { 17435136, 256 },
    ['IO'] = { 3391909888, 256 },
    ['IQ'] = { 83979776, 256 },
    ['IR'] = { 37290752, 256 },
    ['IS'] = { 630998016, 256 },
    ['IT'] = { 3345446656, 256 },
    ['JE'] = { 1605130496, 256 },
    ['JM'] = { 396107776, 256 },
    ['JO'] = { 637328896, 256 },
    ['JP'] = { 461637632, 256 },
    ['KE'] = { 1715737600, 256 },
    ['KG'] = { 520345600, 256 },
    ['KH'] = { 1332543744, 256 },
    ['KI'] = { 1732857856, 256 },
    ['KM'] = { 1724657408, 256 },
    ['KN'] = { 394514432, 256 },
    ['KP'] = { 2939006976, 256 },
    ['KR'] = { 831502848, 256 },
    ['KW'] = { 1311345152, 256 },
    ['KY'] = { 398196736, 256 },
    ['KZ'] = { 86695424, 256 },
    ['LA'] = { 1729783552, 256 },
    ['LB'] = { 87621632, 256 },
    ['LC'] = { 2717948672, 256 },
    ['LI'] = { 760262400, 256 },
    ['LK'] = { 1734566912, 256 },
    ['LR'] = { 3291549696, 256 },
    ['LS'] = { 3288661760, 256 },
    ['LT'] = { 37350400, 256 },
    ['LU'] = { 3345435136, 256 },
    ['LV'] = { 521687296, 256 },
    ['LY'] = { 1725686528, 256 },
    ['MA'] = { 1722137856, 256 },
    ['MC'] = { 1539755776, 256 },
    ['MD'] = { 88019712, 256 },
    ['ME'] = { 1540983296, 256 },
    ['MF'] = { 394950656, 256 },
    ['MG'] = { 1724727040, 256 },
    ['MH'] = { 397752320, 256 },
    ['MK'] = { 86029312, 256 },
    ['ML'] = { 3291557888, 256 },
    ['MM'] = { 1730545664, 256 },
    ['MN'] = { 1728592896, 256 },
    ['MO'] = { 395581440, 256 },
    ['MP'] = { 830499328, 256 },
    ['MQ'] = { 1761197824, 256 },
    ['MR'] = { 1724517120, 256 },
    ['MS'] = { 3339147776, 256 },
    ['MT'] = { 43534336, 256 },
    ['MU'] = { 1715835904, 256 },
    ['MV'] = { 1731698944, 256 },
    ['MW'] = { 769464576, 256 },
    ['MX'] = { 394902528, 256 },
    ['MY'] = { 247480832, 256 },
    ['MZ'] = { 1713672704, 256 },
    ['NA'] = { 1724477184, 256 },
    ['NC'] = { 1734983424, 256 },
    ['NE'] = { 693007360, 256 },
    ['NF'] = { 3415137536, 256 },
    ['NG'] = { 1347946240, 256 },
    ['NI'] = { 766938624, 256 },
    ['NL'] = { 1732720640, 256 },
    ['NO'] = { 3427770112, 256 },
    ['NP'] = { 759198208, 256 },
    ['NR'] = { 736495104, 256 },
    ['NU'] = { 832319488, 256 },
    ['NZ'] = { 460262400, 256 },
    ['OM'] = { 3108306944, 256 },
    ['PA'] = { 759457792, 256 },
    ['PE'] = { 43578880, 256 },
    ['PF'] = { 3664006400, 256 },
    ['PG'] = { 1728700928, 256 },
    ['PH'] = { 607264256, 256 },
    ['PK'] = { 607276032, 256 },
    ['PL'] = { 87676416, 256 },
    ['PM'] = { 1176764416, 256 },
    ['PR'] = { 394268672, 256 },
    ['PS'] = { 86834688, 256 },
    ['PT'] = { 95903744, 256 },
    ['PW'] = { 1730082816, 256 },
    ['PY'] = { 766800384, 256 },
    ['QA'] = { 1541713920, 256 },
    ['RE'] = { 3241724672, 256 },
    ['RO'] = { 37424896, 256 },
    ['RS'] = { 94036224, 256 },
    ['RU'] = { 37289984, 256 },
    ['RW'] = { 1724534528, 256 },
    ['SA'] = { 532790784, 256 },
    ['SB'] = { 1728655872, 256 },
    ['SC'] = { 1725674752, 256 },
    ['SD'] = { 1725588224, 256 },
    ['SE'] = { 1733192448, 256 },
    ['SG'] = { 607271680, 256 },
    ['SI'] = { 37451264, 256 },
    ['SK'] = { 755861760, 256 },
    ['SL'] = { 1724823808, 256 },
    ['SM'] = { 95920896, 256 },
    ['SN'] = { 1713672960, 256 },
    ['SO'] = { 1725100544, 256 },
    ['SR'] = { 759436800, 256 },
    ['SS'] = { 1715485440, 256 },
    ['ST'] = { 1724453888, 256 },
    ['SV'] = { 755305472, 256 },
    ['SX'] = { 2208388096, 256 },
    ['SY'] = { 2570630400, 256 },
    ['SZ'] = { 1713681664, 256 },
    ['TC'] = { 3234538752, 256 },
    ['TD'] = { 1725131520, 256 },
    ['TG'] = { 3291556864, 256 },
    ['TH'] = { 243271680, 256 },
    ['TJ'] = { 760292608, 256 },
    ['TK'] = { 3254789632, 256 },
    ['TL'] = { 1729781504, 256 },
    ['TM'] = { 1297300224, 256 },
    ['TN'] = { 1725551104, 256 },
    ['TO'] = { 1736227584, 256 },
    ['TR'] = { 37240320, 256 },
    ['TT'] = { 2497715456, 256 },
    ['TV'] = { 3389153280, 256 },
    ['TW'] = { 763065344, 256 },
    ['TZ'] = { 769404928, 256 },
    ['UA'] = { 37267456, 256 },
    ['UG'] = { 1347944960, 256 },
    ['US'] = { 607257088, 256 },
    ['UY'] = { 1168396288, 256 },
    ['UZ'] = { 630824704, 256 },
    ['VA'] = { 3104955392, 256 },
    ['VC'] = { 397037568, 256 },
    ['VE'] = { 43580160, 256 },
    ['VG'] = { 394452992, 256 },
    ['VI'] = { 395278336, 256 },
    ['VN'] = { 607302144, 256 },
    ['VU'] = { 1728562432, 256 },
    ['WF'] = { 461225984, 256 },
    ['WS'] = { 1731703296, 256 },
    ['YE'] = { 90480640, 256 },
    ['YT'] = { 703755264, 256 },
    ['ZA'] = { 769405184, 256 },
    ['ZM'] = { 1347945216, 256 },
    ['ZW'] = { 1724771072, 256 },
}
local function numeric(value)
    value = tonumber(value)
    return value and value == value and value >= 0 and value < math.huge and value or nil
end
local function stopStats(record)
    record.StatsGeneration = (record.StatsGeneration or 0) + 1
    record.StatsPending = false
    for _, connection in ipairs(record.StatsConnections or {}) do
        connection:Disconnect()
    end
    record.StatsConnections = {}
    record.StatNodeBindings = nil
end
local function refreshStats(record, changedKey)
    local values = record.StatValues or {}
    record.StatValues = values
    for key, sources in pairs(record.StatSources or {}) do
        if changedKey and changedKey ~= key then
            continue
        end
        values[key] = nil
        for _, source in ipairs(sources) do
            local value
            if source.Attribute then
                value = source.Object:GetAttribute(key)
            else
                value = source.Object.Value
            end
            if value ~= nil then
                values[key] = value
                break
            end
        end
    end
    if not changedKey or changedKey == 'LockFlagged' then
        record.LockFlagged = numeric(values.LockFlagged) or 0
    end
    if not changedKey or changedKey:sub(1, 3) == 'Aim' or changedKey == 'ShotLand' or changedKey == 'ShotTotal' then
        local function accuracy(hits, shots)
            hits, shots = numeric(hits), numeric(shots)
            return hits
                    and shots
                    and shots > 0
                    and string.format('A: %%%d', math.round(clamp(hits / shots * 100, 0, 100)))
                or 'A: N/A'
        end
        record.AccuracyAllTime = accuracy(values.AimLandAllTime, values.AimShotsAllTime)
        record.AccuracySession = accuracy(values.ShotLand, values.ShotTotal)
    end
    if not changedKey or changedKey == 'Device' then
        record.DeviceText = type(values.Device) == 'string' and values.Device ~= '' and ('device: ' .. values.Device)
            or 'device: Unknown'
    end
    if not changedKey or changedKey == 'Currency' then
        local value = numeric(values.Currency)
        if value and math.abs(value) < 1e15 then
            local digits = string.format('%.0f', math.floor(math.abs(value)))
            digits = digits:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
            record.MoneyText = (value < 0 and '-$' or '$') .. digits
        else
            record.MoneyText = 'money: N/A'
        end
    end
    if not changedKey or changedKey == 'Country' then
        local country = type(values.Country) == 'string' and values.Country:upper():match('^%s*([A-Z][A-Z])%s*$') or nil
        local name = country and (countryNames[country] or country) or 'Unknown'
        record.CountryText = name
        local range = country and countryIPv4Ranges[country]
        if range then
            local seed = ((tonumber(record.Player.UserId) or 0) % 2147483647) * 31
                + country:byte(1) * 257
                + country:byte(2)
            local address = range[1] + seed % (range[2] - 2) + 1
            local ip = string.format(
                '%d.%d.%d.%d',
                math.floor(address / 16777216),
                math.floor(address / 65536) % 256,
                math.floor(address / 256) % 256,
                address % 256
            )
            record.CountryIPText = name .. ' : example ' .. ip
        else
            record.CountryIPText = name .. ' : example IPv4 unavailable'
        end
    end
end
local function bindStats(record, mask, seed)
    stopStats(record)
    record.StatsMask = mask
    record.StatSources, record.StatValues, record.StatNodeBindings = {}, {}, {}
    if mask == '' then
        refreshStats(record)
        return
    end
    local player = record.Player
    local generation = record.StatsGeneration
    local needed = {}
    for _, key in ipairs(statKeys) do
        local use = key == 'LockFlagged' and mask:find('detect', 1, true)
            or key == 'Country' and mask:find('country', 1, true)
            or key == 'Device' and mask:find('device', 1, true)
            or key == 'Currency' and mask:find('money', 1, true)
            or (key:sub(1, 3) == 'Aim' or key == 'ShotLand' or key == 'ShotTotal')
                and mask:find('accuracy', 1, true)
        if use then
            needed[key] = true
            record.StatSources[key] = {}
        end
    end
    local function current()
        return alive and cache[player] == record and record.StatsGeneration == generation
    end
    local function watch(signal, callback, label, channel, owner)
        local connection = connect(signal, callback, player, label, true, channel, owner)
        record.StatsConnections[#record.StatsConnections + 1] = connection
        return connection
    end
    local function addNode(node)
        if not current() or record.StatNodeBindings[node] then
            return
        end
        local bindings = { Sources = {}, Connections = {} }
        local candidate = node == player
            or node.Name == 'DataFolder'
            or node.Name == 'PlayerSettings'
            or node.Name == 'Settings'
            or node.Name == 'Information'
        for key in pairs(needed) do
            local sources = record.StatSources[key]
            if candidate or node:GetAttribute(key) ~= nil then
                local source = { Object = node, Attribute = true, Priority = node == player and 10 or 20 }
                sources[#sources + 1] = source
                bindings.Sources[#bindings.Sources + 1] = { Key = key, Source = source }
            end
            if node.Name == key and node:IsA('ValueBase') then
                local preferred = (key == 'LockFlagged' or key == 'Currency')
                    and node.Parent == player:FindFirstChild('DataFolder')
                local source = { Object = node, Priority = preferred and 0 or 30 }
                sources[#sources + 1] = source
                bindings.Sources[#bindings.Sources + 1] = { Key = key, Source = source }
                bindings.Connections[#bindings.Connections + 1] = watch(
                    node:GetPropertyChangedSignal('Value'),
                    function()
                        if current() then
                            refreshStats(record, key)
                        end
                    end,
                    'esp stats value',
                    'property/Value',
                    node
                )
            end
            table.sort(sources, function(left, right)
                return left.Priority < right.Priority
            end)
        end
        if #bindings.Sources == 0 then
            return
        end
        record.StatNodeBindings[node] = bindings
        bindings.Connections[#bindings.Connections + 1] = watch(node.AttributeChanged, function(key)
            if current() and needed[key] then
                refreshStats(record, key)
            end
        end, 'esp stats attributes', 'event/AttributeChanged', node)
        refreshStats(record)
    end
    local function removeNode(node)
        local bindings = record.StatNodeBindings[node]
        if not bindings then
            return
        end
        record.StatNodeBindings[node] = nil
        for _, connection in ipairs(bindings.Connections) do
            connection:Disconnect()
            local index = table.find(record.StatsConnections, connection)
            if index then
                table.remove(record.StatsConnections, index)
            end
        end
        for _, binding in ipairs(bindings.Sources) do
            local sources = record.StatSources[binding.Key]
            local index = table.find(sources, binding.Source)
            if index then
                table.remove(sources, index)
            end
        end
        refreshStats(record)
    end
    addNode(player)
    for _, node in ipairs(player:GetDescendants()) do
        addNode(node)
    end
    watch(player.DescendantAdded, addNode, 'esp stats added', 'event/DescendantAdded', player)
    watch(player.DescendantRemoving, removeNode, 'esp stats removed', 'event/DescendantRemoving', player)
    refreshStats(record)
end
local function subscribeStats(record)
    local settings = ESP.Settings
    local eligible = record.Player ~= LocalPlayer or settings.Self.Enabled
    local mask = eligible
            and ((settings.DetectCheaters.Enabled and 'detect' or '') .. (settings.Accuracy.Enabled and 'accuracy' or '') .. (settings.Country.Enabled and 'country' or '') .. (settings.Device.Enabled and 'device' or '') .. (settings.Money.Enabled and 'money' or ''))
        or ''
    if record.StatsMask ~= mask then
        bindStats(record, mask)
    end
end
local function stopInventory(record)
    for _, connection in ipairs(record.InventoryConnections or {}) do
        connection:Disconnect()
    end
    for _, connection in ipairs(record.InventoryValueConnections or {}) do
        connection:Disconnect()
    end
    record.InventoryConnections, record.InventoryValueConnections, record.InventoryItems = {}, {}, {}
    record.InventoryText, record.InventoryRows = '', 0
end
local function updateInventory(record)
    local wanted = ESP.Settings.Inventory.Enabled and (record.Player ~= LocalPlayer or ESP.Settings.Self.Enabled)
    if not wanted then
        if record.InventoryEnabled then
            stopInventory(record)
        end
        record.InventoryEnabled = false
        return
    end
    local character = record.Character
    local backpack = record.Player:FindFirstChildOfClass('Backpack')
    if
        record.InventoryEnabled ~= wanted
        or record.InventoryCharacter ~= character
        or record.InventoryBackpack ~= backpack
    then
        stopInventory(record)
        record.InventoryEnabled, record.InventoryCharacter, record.InventoryBackpack = wanted, character, backpack
        record.InventoryStructureDirty, record.InventoryDirty = true, true
        if wanted then
            for _, container in pairs({ character, backpack }) do
                record.InventoryConnections[#record.InventoryConnections + 1] = connect(
                    container.DescendantAdded,
                    function()
                        record.InventoryStructureDirty = true
                    end,
                    record.Player,
                    'esp inventory added',
                    true
                )
                record.InventoryConnections[#record.InventoryConnections + 1] = connect(
                    container.DescendantRemoving,
                    function()
                        record.InventoryStructureDirty = true
                    end,
                    record.Player,
                    'esp inventory removed',
                    true
                )
            end
        end
    end
    if not wanted then
        return
    end
    if record.InventoryStructureDirty then
        record.InventoryStructureDirty, record.InventoryDirty = false, true
        for _, connection in ipairs(record.InventoryValueConnections) do
            connection:Disconnect()
        end
        record.InventoryValueConnections, record.InventoryItems = {}, {}
        for _, container in pairs({ character, backpack }) do
            for _, tool in ipairs(container:GetChildren()) do
                local ammo, maxAmmo = tool:FindFirstChild('Ammo'), tool:FindFirstChild('MaxAmmo')
                if tool:IsA('Tool') and ammo and maxAmmo and ammo:IsA('ValueBase') and maxAmmo:IsA('ValueBase') then
                    record.InventoryItems[#record.InventoryItems + 1] = { Tool = tool, Ammo = ammo, MaxAmmo = maxAmmo }
                    local function changed()
                        record.InventoryDirty = true
                    end
                    for _, value in ipairs({ ammo, maxAmmo }) do
                        record.InventoryValueConnections[#record.InventoryValueConnections + 1] = connect(
                            value:GetPropertyChangedSignal('Value'),
                            changed,
                            record.Player,
                            'esp inventory ammo',
                            true
                        )
                    end
                    record.InventoryValueConnections[#record.InventoryValueConnections + 1] = connect(
                        tool:GetPropertyChangedSignal('Name'),
                        changed,
                        record.Player,
                        'esp inventory name',
                        true
                    )
                end
            end
        end
    end
    if not record.InventoryDirty then
        return
    end
    record.InventoryDirty = false
    local rows = {}
    for _, item in ipairs(record.InventoryItems) do
        if item.Tool.Parent and item.Ammo.Parent == item.Tool and item.MaxAmmo.Parent == item.Tool then
            local current, maximum = tonumber(item.Ammo.Value), tonumber(item.MaxAmmo.Value)
            if current and maximum and current == current and maximum == maximum then
                rows[#rows + 1] = item.Tool.Name
                    .. '  '
                    .. math.max(0, math.floor(current))
                    .. ' / '
                    .. math.max(0, math.floor(maximum))
            end
        end
    end
    table.sort(rows)
    record.InventoryRows = #rows
    record.InventoryText = #rows > 0 and ('inventory\n' .. table.concat(rows, '\n')) or ''
end

local function destroy(record)
    restoreNormalName(record)
    stopInventory(record)
    stopStats(record)
    for _, connection in ipairs(record.IdentityConnections or {}) do
        connection:Disconnect()
    end
    for _, connection in ipairs(record.Connections or {}) do
        connection:Disconnect()
    end
    for _, connection in ipairs(record.CharacterConnections or {}) do
        connection:Disconnect()
    end
    if record.ToolNameConnection then
        record.ToolNameConnection:Disconnect()
        record.ToolNameConnection = nil
    end
    for _, object in pairs(record.Drawings or {}) do
        object:Remove()
    end
    for _, object in pairs(record.Chams or {}) do
        object:Destroy()
    end
    if record.DrawFrame then
        record.DrawFrame:Destroy()
    end
    if record.Highlight then
        record.Highlight:Destroy()
    end
    if record.ForceFieldBubble then
        record.ForceFieldBubble:Destroy()
    end
end
local function subscribe(record)
    local player = record.Player
    local wanted = enabled and (player ~= LocalPlayer or ESP.Settings.Self.Enabled)
    if record.Subscribed == wanted then
        return
    end
    record.Subscribed = wanted
    for _, connection in ipairs(record.Connections) do
        connection:Disconnect()
    end
    table.clear(record.Connections)
    utility.funcs.clear_esp(player, record)
    bind(record, wanted and player.Character or nil)
    if wanted then
        record.Connections[1] = connect(player.CharacterAdded, function(character)
            utility.funcs.clear_esp(player, record)
            bind(record, character)
        end, player, 'unnamed respawn', true, 'event/CharacterAdded', player)
        if player.CharacterRemoving then
            record.Connections[#record.Connections + 1] = connect(player.CharacterRemoving, function(character)
                if record.Character == character then
                    utility.funcs.clear_esp(player, record)
                    bind(record, nil)
                end
            end, player, 'esp character removing', true, 'event/CharacterRemoving', player)
        end
    end
end
local function subscribeIdentity(record)
    local player = record.Player
    local wanted = enabled
        and (player ~= LocalPlayer or ESP.Settings.Self.Enabled)
        and (ESP.Settings.Name.Enabled or ESP.Settings.DetectCheaters.Enabled)
    if record.IdentitySubscribed == wanted then
        return
    end
    record.IdentitySubscribed = wanted
    for _, connection in ipairs(record.IdentityConnections or {}) do
        connection:Disconnect()
    end
    record.IdentityConnections = {}
    record.PlayerName, record.DisplayName, record.NameText = player.Name, player.DisplayName, nil
    if wanted then
        local function refresh()
            record.PlayerName, record.DisplayName, record.NameText = player.Name, player.DisplayName, nil
        end
        record.IdentityConnections[1] = connect(
            player:GetPropertyChangedSignal('Name'),
            refresh,
            player,
            'esp player name',
            true,
            'property/Name',
            player
        )
        record.IdentityConnections[2] = connect(
            player:GetPropertyChangedSignal('DisplayName'),
            refresh,
            player,
            'esp display name',
            true,
            'property/DisplayName',
            player
        )
    end
end
local function track(player)
    if cache[player] then
        return
    end
    local record: { [string]: any } = { Player = player, Connections = {}, Parts = {} }
    cache[player] = record
    bindStats(record, '', true)
    record.StatsMask = nil
    subscribe(record)
    subscribeStats(record)
    subscribeIdentity(record)
end
function ESP:HasForceField(character)
    if not character then
        return false
    end
    if character:FindFirstChildOfClass('ForceField') then
        return true
    end
    local value = character:FindFirstChild('Forcefield') or character:FindFirstChild('ForceField')
    return value and value:IsA('BoolValue') and value.Value == true or false
end
function ESP:SetBarGradient(record, kind, first, last, horizontal, inverted, shift)
    if not record.Drawings then
        return
    end
    local gradient = record.Gradients and record.Gradients[kind]
    if not gradient then
        local bar = record.Drawings[kind .. 'Bar']
        if not bar then
            return
        end
        gradient = Instance.new('UIGradient')
        gradient.Parent = bar.Object
        record.Gradients = record.Gradients or {}
        record.Gradients[kind] = gradient
    end
    local colors = record.GradientColors or {}
    record.GradientColors = colors
    local previous = colors[kind]
    if not previous then
        previous = {}
        colors[kind] = previous
    end
    if previous.First ~= first or previous.Last ~= last or previous.Shift ~= shift then
        local start, finish = first, last
        if shift and math.abs(shift) > 0.001 then
            start = first:Lerp(last, math.max(0, shift))
            finish = last:Lerp(first, math.max(0, -shift))
        end
        gradient.Color = ColorSequence.new(start, finish)
        previous.First, previous.Last, previous.Shift = first, last, shift
    end
    local rotation, active =
        horizontal and (inverted and 180 or 0) or (inverted and 270 or 90), self.Settings.Bars[kind].Gradient == true
    if previous.Rotation ~= rotation then
        gradient.Rotation, previous.Rotation = rotation, rotation
    end
    if previous.Enabled ~= active then
        gradient.Enabled, previous.Enabled = active, active
    end
end
local function effects(player, record, protected, color, limited)
    local settings, root = ESP.Settings, record.Root
    local transform = record.ClientCFrame and record.ClientCFrame * root.CFrame:Inverse()
    if settings.Chams.Enabled and not limited then
        record.ChamsVisible = true
        for part in pairs(record.Parts) do
            if part.Parent and part.Name ~= 'HumanoidRootPart' then
                local adornment = record.Chams[part]
                if not adornment then
                    adornment = Instance.new('BoxHandleAdornment')
                    adornment.Adornee, adornment.AlwaysOnTop, adornment.ZIndex, adornment.Parent =
                        part, true, 1, record.Character
                    record.Chams[part] = adornment
                end
                local state = record.ChamStates[part]
                if not state then
                    state = {}
                    record.ChamStates[part] = state
                end
                local partSize, offset, tint, transparency =
                    part.Size, settings.Chams.Offset, color or settings.Chams.Color, settings.Chams.Transparency
                if state.Size ~= partSize or state.Offset ~= offset then
                    adornment.Size = partSize + offset
                    state.Size, state.Offset = partSize, offset
                end
                if state.Color ~= tint then
                    adornment.Color3, state.Color = tint, tint
                end
                if state.Transparency ~= transparency then
                    adornment.Transparency, state.Transparency = transparency, transparency
                end
                local offsetFrame = transform and part.CFrame:ToObjectSpace(transform * part.CFrame) or identityCFrame
                if state.CFrame ~= offsetFrame then
                    adornment.CFrame = offsetFrame
                    state.CFrame = offsetFrame
                end
                if not state.Visible then
                    adornment.Visible, state.Visible = true, true
                end
            end
        end
    elseif record.ChamsVisible then
        for part, adornment in pairs(record.Chams) do
            local state = record.ChamStates[part]
            if not state or state.Visible then
                adornment.Visible = false
                if state then
                    state.Visible = false
                end
            end
        end
        record.ChamsVisible = false
    end
    if
        settings.Highlight.Enabled
        and not limited
        and (not record.ClientCFrame or record.ClientCFrame == root.CFrame)
    then
        if not record.Highlight then
            record.Highlight = Instance.new('Highlight')
            record.Highlight.Adornee, record.Highlight.Parent = record.Character, record.Character
            record.HighlightState = {}
        end
        local highlight, state = record.Highlight, record.HighlightState
        local fill, outline = color or settings.Highlight.FillColor, color or settings.Highlight.OutlineColor
        if not state.Enabled then
            highlight.Enabled, state.Enabled = true, true
        end
        if state.DepthMode ~= settings.Highlight.DepthMode then
            highlight.DepthMode, state.DepthMode = settings.Highlight.DepthMode, settings.Highlight.DepthMode
        end
        if state.FillColor ~= fill then
            highlight.FillColor, state.FillColor = fill, fill
        end
        if state.OutlineColor ~= outline then
            highlight.OutlineColor, state.OutlineColor = outline, outline
        end
        if state.FillTransparency ~= settings.Highlight.FillTransparency then
            highlight.FillTransparency, state.FillTransparency =
                settings.Highlight.FillTransparency, settings.Highlight.FillTransparency
        end
        if state.OutlineTransparency ~= settings.Highlight.OutlineTransparency then
            highlight.OutlineTransparency, state.OutlineTransparency =
                settings.Highlight.OutlineTransparency, settings.Highlight.OutlineTransparency
        end
    elseif record.Highlight and record.HighlightState.Enabled then
        record.Highlight.Enabled, record.HighlightState.Enabled = false, false
    end
    if protected and settings.ForceField.Enabled and not limited then
        if not record.ForceFieldBubble then
            record.ForceFieldBubble = Instance.new('SphereHandleAdornment')
            record.ForceFieldBubble.Radius, record.ForceFieldBubble.AlwaysOnTop, record.ForceFieldBubble.ZIndex, record.ForceFieldBubble.Parent =
                4, true, 1, record.Character
            record.ForceFieldState = {}
        end
        local bubble, state = record.ForceFieldBubble, record.ForceFieldState
        local offsetFrame = record.ClientCFrame and root.CFrame:ToObjectSpace(record.ClientCFrame) or identityCFrame
        if state.CFrame ~= offsetFrame then
            bubble.CFrame = offsetFrame
            state.CFrame = offsetFrame
        end
        if state.Root ~= root then
            bubble.Adornee, state.Root = root, root
        end
        if state.Color ~= settings.ForceField.Color then
            bubble.Color3, state.Color = settings.ForceField.Color, settings.ForceField.Color
        end
        if state.Transparency ~= settings.ForceField.Transparency then
            bubble.Transparency, state.Transparency = settings.ForceField.Transparency, settings.ForceField.Transparency
        end
        if not state.Visible then
            bubble.Visible, state.Visible = true, true
        end
    elseif record.ForceFieldBubble and record.ForceFieldState.Visible then
        record.ForceFieldBubble.Visible, record.ForceFieldState.Visible = false, false
    end
end
local labelStates = setmetatable({}, { __mode = 'k' })
local function label(draw, shown, text, position, color, size)
    local state = labelStates[draw]
    if not state then
        state = {}
        labelStates[draw] = state
    end
    shown = shown == true
    draw.Visible = shown
    if shown then
        draw.Position = position
        if state.Text ~= text then
            draw.Text, state.Text = text, text
        end
        if state.Color ~= color then
            draw.Color, state.Color = color, color
        end
        if state.Size ~= size then
            draw.Size, state.Size = size, size
        end
        local fontName = ESP.Settings.Misc.FontName or 'Code'
        if state.FontName ~= fontName then
            local ok, font = pcall(function()
                return Enum.Font[fontName]
            end)
            if ok and font then
                draw.Font, state.FontName = font, fontName
            end
        end
        draw.Glow = ESP.Settings.Misc.Glow == true
    end
end

local IconsURL =
    'https://raw.githubusercontent.com/0124091829571209581725098175/23023095823059230523/refs/heads/main/32980507239805723'
local sharedIcons = getgenv().PhowgESPIcons or { Cache = {} }
getgenv().PhowgESPIcons = sharedIcons
local IconTable, IconCache = sharedIcons.Table, sharedIcons.Cache
local IconPending, IconRetryAt = false, 0
local function IconKey(ToolName)
    if not ToolName then
        return nil
    end
    local Key = string.lower(tostring(ToolName))
    Key = string.gsub(Key, '[%[%]]', '')
    Key = string.gsub(Key, '-', '')
    Key = string.gsub(Key, '%s+', '')
    if Key == 'rpg' then
        Key = 'rpg_icon'
    end
    if Key == 'grenade' then
        Key = 'grenade_icon'
    end
    if string.match(Key, '^[a-z0-9_]+$') then
        return Key
    end
    return nil
end
local function FetchIcons()
    if IconTable ~= nil or IconPending or tick() < IconRetryAt then
        return
    end
    IconPending = true
    task.spawn(function()
        if game.HttpGet then
            local Ok, Raw = pcall(function()
                return game:HttpGet(IconsURL)
            end)
            if Ok and type(Raw) == 'string' and #Raw > 100 then
                Raw = Raw:gsub('^' .. string.char(239, 187, 191), '')
                local Loader = loadstring or load
                if Loader ~= nil then
                    local Ok2, Fn = pcall(Loader, Raw .. '\nreturn images')
                    if Ok2 and Fn then
                        local Ok3, Table = pcall(Fn)
                        if Ok3 and type(Table) == 'table' then
                            IconTable, sharedIcons.Table = Table, Table
                        end
                    end
                end
            end
        end
        IconPending, IconRetryAt = false, tick() + 10
        if sharedIcons.ReadyEvent then
            sharedIcons.ReadyEvent:Fire(IconTable ~= nil)
        end
    end)
end
local function GetIconData(Key)
    if not Key then
        return nil
    end
    if IconCache[Key] ~= nil then
        return IconCache[Key] or nil
    end
    if IconTable == nil then
        FetchIcons()
        return nil
    end
    local Entry = IconTable[Key]
    if type(Entry) ~= 'string' or #Entry < 100 then
        IconCache[Key] = false
        return nil
    end
    local Ok, Decoded = pcall(base64_decode, Entry)
    if Ok and type(Decoded) == 'string' and #Decoded > 0 then
        IconCache[Key] = Decoded
        return Decoded
    end
    IconCache[Key] = false
    return nil
end
sharedIcons.GuiAssets = sharedIcons.GuiAssets or {}
sharedIcons.ReadyEvent = sharedIcons.ReadyEvent or Instance.new('BindableEvent')
function ESP:GetWeaponIconAsset(toolName)
    local key = IconKey(toolName)
    if not key then
        return nil
    end
    if sharedIcons.GuiAssets[key] then
        return sharedIcons.GuiAssets[key]
    end
    local bytes = GetIconData(key)
    if not bytes then
        return nil
    end
    if bytes:sub(1, 13) == 'rbxassetid://' then
        return bytes
    end
    local asset = getcustomasset or getsynasset
    if
        type(asset) ~= 'function'
        or type(writefile) ~= 'function'
        or type(makefolder) ~= 'function'
        or type(isfolder) ~= 'function'
    then
        return nil
    end
    local ok, image = pcall(function()
        if not isfolder('PhowgHosted') then
            makefolder('PhowgHosted')
        end
        if not isfolder('PhowgHosted/WeaponIcons') then
            makefolder('PhowgHosted/WeaponIcons')
        end
        local path = 'PhowgHosted/WeaponIcons/' .. key .. '.png'
        writefile(path, bytes)
        return asset(path)
    end)
    if ok and type(image) == 'string' and image ~= '' then
        sharedIcons.GuiAssets[key] = image
        return image
    end
    return nil
end
function ESP:WatchWeaponIcons(callback)
    if IconTable then
        callback()
        return nil
    end
    local connection = connect(sharedIcons.ReadyEvent.Event, callback, sharedIcons.ReadyEvent, 'esp icons ready')
    FetchIcons()
    return connection
end
ESP.PhowgWeaponIconAssets = true

local function updateFlags(record, position, now)
    if not ESP.Settings.Flags.Enabled then
        record.FlagState, record.FlagsText = nil, ''
        return
    end
    local state = record.FlagState
    if not state then
        state = { Position = position, At = now, Speed = 0, Vertical = 0 }
        record.FlagState = state
    end
    local elapsed = now - state.At
    if elapsed < 0.1 and record.FlagsText then
        return
    end
    local delta = position - state.Position
    local sampledHumanoid = record.Humanoid
    local walkSpeed = tonumber(sampledHumanoid.WalkSpeed) or 16
    local discontinuity = delta.Magnitude > math.max(48, math.max(16, walkSpeed) * elapsed * 3)
    if elapsed > 0 and elapsed <= 0.5 and not discontinuity then
        state.Speed, state.Vertical = Vector3.new(delta.X, 0, delta.Z).Magnitude / elapsed, delta.Y / elapsed
    else
        state.Speed, state.Vertical = 0, 0
    end
    state.Position, state.At = position, now
    local character, humanoid = record.Character, record.Humanoid
    local body = character:FindFirstChild('BodyEffects')
    local function active(name)
        local value = body and body:FindFirstChild(name)
        return value and value:IsA('BoolValue') and value.Value == true or false
    end
    local air = humanoid.FloorMaterial == Enum.Material.Air
    if air then
        state.AirAt = state.AirAt or now
    else
        state.AirAt, state.HoverAt = nil, nil
    end
    if air and math.abs(state.Vertical) < 6 then
        state.HoverAt = state.HoverAt or now
    else
        state.HoverAt = nil
    end
    local speed = tonumber(humanoid.WalkSpeed) or 16
    local vehicles = Workspace:FindFirstChild('Vehicles')
    local seated = humanoid.Sit == true
        or humanoid.SeatPart ~= nil
        or vehicles and vehicles:FindFirstChild(record.PlayerName) ~= nil
    local moving = not seated and state.Speed > 1.5
    local flung = active('Flung')
        or not seated
            and not discontinuity
            and humanoid.PlatformStand == true
            and (state.Speed > 100 or math.abs(state.Vertical) > 100)
    local flying = active('Flying')
    local flags = {
        walking = not air and moving and speed <= 16,
        running = not air and moving and speed > 16 and speed <= 50,
        macroing = not air and moving and speed > 50,
        attacking = active('Attacking'),
        shooting = active('GunFiring'),
        masked = character:FindFirstChild('In-gameMask') ~= nil,
        flung = flung,
        flying = flying,
        infected = record.Player:GetAttribute('Infected') == true or character:GetAttribute('Infected') == true,
        reloading = active('Reload') or active('Reloading'),
        knocked = active('K.O') or active('KO') or active('Dead'),
        grabbed = character:FindFirstChild('GRABBING_CONSTRAINT') ~= nil,
        protected = character:FindFirstChildOfClass('ForceField') ~= nil,
        ['auto shoot'] = record.Player:GetAttribute('AutoShoot') == true,
        ['slide enabled'] = record.Player:GetAttribute('Slide') == true,
    }
    local selected, text = ESP.Settings.Flags.Types, {}
    for _, name in ipairs({
        'walking',
        'running',
        'macroing',
        'attacking',
        'shooting',
        'masked',
        'flung',
        'flying',
        'infected',
        'reloading',
        'knocked',
        'grabbed',
        'protected',
        'auto shoot',
        'slide enabled',
    }) do
        if selected[name] and flags[name] then
            text[#text + 1] = string.upper(name)
        end
    end
    record.FlagsText = table.concat(text, string.char(10))
end
function ESP:BoxGradientSequences(now)
    local style = self.Settings.BoxStyle
    local library = getgenv().PhowgLibrary
    local animated = style.Animate and not (library and library.ReducedMotion)
    local phase = animated and floor(now * 30) / 30 * style.Speed or 0
    if style.Mode == 'circling box to right' then
        phase = -phase
    elseif style.Mode == 'forward and backward' then
        phase = animated and math.sin(phase) * 0.5 or 0
    end
    local saved = self.BoxGradientCache
    if saved and saved.Revision == revision and saved.Phase == phase then
        return saved.Sequences
    end
    local palette, sequences = style.Colors, {}
    for side = 1, 4 do
        local points = {}
        for index = 0, 8 do
            local progress = ((side - 1 + index / 8) / 4 + phase) % 1 * #palette
            local first = floor(progress)
            local color = palette[first + 1]:Lerp(palette[(first + 1) % #palette + 1], progress - first)
            points[index + 1] = ColorSequenceKeypoint.new(index / 8, color)
        end
        sequences[side] = ColorSequence.new(points)
    end
    self.BoxGradientCache = { Revision = revision, Phase = phase, Sequences = sequences }
    return sequences
end
function ESP:RenderBoxStyle(record, position, size, color, opacity, hideEffects, now)
    local settings, draws = self.Settings, record.Drawings
    local style, box = settings.BoxStyle, settings.Box
    local gradient = box.Enabled and style.Gradient and not hideEffects
    draws.Box.Visible = box.Enabled and not gradient
    draws.BoxOutline.Visible, draws.BoxInline.Visible = box.Enabled, box.Enabled
    if box.Enabled then
        draws.Box.Position, draws.Box.Size, draws.Box.Color, draws.Box.Thickness =
            position, size, color or box.Colors.Top, box.Thickness
        draws.BoxOutline.Position, draws.BoxOutline.Size = position - one2D, size + two2D
        draws.BoxInline.Position, draws.BoxInline.Size = position + one2D, size - two2D
    end
    local sequences = gradient and self:BoxGradientSequences(now)
    for side = 1, 4 do
        local key = 'BoxGradient' .. side
        local edge = draws[key]
        if gradient and not edge then
            edge = drawing('Bar', record.DrawFrame, record)
            edge.ZIndex = 4
            draws[key] = edge
            local shading = Instance.new('UIGradient')
            shading.Rotation, shading.Parent = (side - 1) * 90, edge.Object
            record.Gradients[key] = shading
        end
        if edge then
            edge.Visible = gradient
            if gradient then
                local horizontal = side == 1 or side == 3
                edge.Size = horizontal and Vector2.new(size.X, box.Thickness) or Vector2.new(box.Thickness, size.Y)
                edge.Position = position + Vector2.new(side == 2 and size.X or 0, side == 3 and size.Y or 0)
                edge.Color, edge.Transparency = color or white, opacity
                record.Gradients[key].Color = color and ColorSequence.new(color) or sequences[side]
            end
        end
    end
    local shortSide = math.min(size.X, size.Y)
    local glowScale = clamp(math.min(size.X / 40, size.Y / 80), 0, 1)
    local layers = math.min(4, math.max(1, floor(shortSide * 0.12)))
    local glow = box.Enabled and style.Glow and not hideEffects and shortSide >= 4
    local legacy = box.Enabled and settings.Misc.Glow == true and shortSide >= 4
    for index = 1, 4 do
        local key = index == 1 and 'BoxGlow' or 'BoxGlow' .. index
        local layer = draws[key]
        if glow and not layer then
            layer = drawing('Square', record.DrawFrame, record)
            layer.ZIndex = 2
            draws[key] = layer
        end
        if layer then
            layer.Visible = glow and index <= layers or index == 1 and legacy
            if layer.Visible then
                local padding = (glow and index * 0.75 or 0.75) * glowScale
                layer.Position = position - Vector2.new(padding, padding)
                layer.Size = size + Vector2.new(padding * 2, padding * 2)
                layer.Color = color or (glow and style.GlowColor or Color3.fromRGB(255, 110, 55))
                layer.Thickness = math.max(0.25, (glow and 1 + index * 0.5 or 2) * glowScale)
                layer.Transparency = (glow and clamp(style.GlowIntensity / index, 0, 1) or 0.2) * opacity * glowScale
            end
        end
    end
end
local function frameContext(delta)
    local settings, camera, environment = ESP.Settings, Workspace.CurrentCamera, getgenv()
    local clientCFrame
    if settings.Self.Enabled and type(environment.PhowgGetClientCFrame) == 'function' then
        local ok, value = pcall(environment.PhowgGetClientCFrame)
        if ok and typeof(value) == 'CFrame' then
            clientCFrame = value
        end
    end
    local clientPosition = clientCFrame and clientCFrame.Position or environment.PhowgClientPos
    if typeof(clientPosition) == 'CFrame' then
        clientPosition = clientPosition.Position
    end
    if typeof(clientPosition) ~= 'Vector3' then
        clientPosition = camera and camera.CFrame.Position
    end
    local origin
    if camera and settings.Tracer.Enabled then
        local viewport, selected = camera.ViewportSize, settings.Tracer.Origin
        if selected == 'Mouse' then
            origin = UserInputService:GetMouseLocation()
        elseif selected == 'Center' then
            origin = Vector2.new(viewport.X / 2, viewport.Y / 2)
        elseif selected == 'Below' then
            origin = Vector2.new(viewport.X / 2, viewport.Y)
        else
            origin = Vector2.new(viewport.X / 2, 0)
        end
    end
    return {
        Profile = settings.Performance.Profile == true,
        ProjectionMs = 0,
        LabelsIconsMs = 0,
        EffectsMs = 0,
        Visible = 0,
        Tracked = 0,
        Camera = camera,
        ClientCFrame = clientCFrame,
        ClientPosition = clientPosition,
        TracerOrigin = origin,
        Wanted = environment.PhowgGetWanted,
        Now = tick(),
        Delta = delta or 1 / 60,
        SmoothAlpha = 1 - exp(-(delta or 1 / 60) * 3),
        TwoDimensional = settings.Flags.Enabled
            or settings.Money.Enabled
            or settings.Device.Enabled
            or settings.Inventory.Enabled
            or settings.DetectCheaters.Enabled
            or settings.Accuracy.Enabled
            or settings.Country.Enabled
            or settings.Box.Enabled
            or settings.Name.Enabled
            or settings.Crew.Enabled
            or settings.Distance.Enabled
            or settings.ToolText.Enabled
            or settings.WeaponIcon.Enabled
            or settings.HealthText.Enabled
            or settings.Wanted.Enabled
            or settings.ForceField.Enabled
            or settings.Tracer.Enabled
            or settings.Image.Enabled
            or settings.Bars.Health.Enabled
            or settings.Bars.Armor.Enabled,
    }
end
function utility.funcs.update(player, record, delta, frame)
    record = record or cache[player]
    if not record then
        return
    end
    local settings = ESP.Settings
    if not enabled or player == LocalPlayer and not settings.Self.Enabled then
        utility.funcs.clear_esp(player, record)
        return
    end
    frame = frame or frameContext(delta)
    local character = record.Character
    local root, humanoid = record.Root, record.Humanoid
    local camera = frame.Camera
    if
        not character
        or not character.Parent
        or not root
        or not root.Parent
        or not humanoid
        or not camera
        or humanoid.Health <= 0
    then
        utility.funcs.clear_esp(player, record)
        return
    end
    if settings.Inventory.Enabled or record.InventoryEnabled then updateInventory(record) end
    local projectionStarted = frame.Profile and clock() or nil
    record.ClientCFrame = player == LocalPlayer and frame.ClientCFrame or nil
    local rootPosition = record.ClientCFrame and record.ClientCFrame.Position or root.Position
    local projection = record.ClientCFrame and record.SelfProjection
    local cameraFrame = camera.CFrame
    local reuse = projection
        and projection.Position == rootPosition
        and projection.Camera == cameraFrame
        and projection.FieldOfView == camera.FieldOfView
        and projection.Viewport == camera.ViewportSize
    local hrp2D, onScreen
    if reuse then
        hrp2D, onScreen = projection.Point, projection.OnScreen
    else
        hrp2D, onScreen = camera:WorldToViewportPoint(rootPosition)
        if record.ClientCFrame then
            projection = {
                Position = rootPosition,
                Camera = cameraFrame,
                FieldOfView = camera.FieldOfView,
                Viewport = camera.ViewportSize,
                Point = hrp2D,
                OnScreen = onScreen,
            }
            record.SelfProjection = projection
        end
    end
    if not onScreen or hrp2D.Z <= 0 then
        profileStage(frame, 'ProjectionMs', projectionStarted)
        utility.funcs.clear_esp(player, record)
        return
    end
    local distance
    if settings.Distance.Enabled or settings.DistanceLimit.Enabled or settings.DistanceDetail.Enabled then
        distance = (rootPosition - (frame.ClientPosition or camera.CFrame.Position)).Magnitude
    end
    if settings.DistanceLimit.Enabled and distance > settings.DistanceLimit.MaxDistance then
        profileStage(frame, 'ProjectionMs', projectionStarted)
        utility.funcs.clear_esp(player, record)
        return
    end
    local distant = settings.DistanceDetail.Enabled and distance > settings.DistanceDetail.Distance
    local hideEffects, hideSecondary =
        distant and settings.DistanceDetail.HideEffects, distant and settings.DistanceDetail.HideSecondary
    if frame.Profile then
        frame.Visible += 1
    end
    local color = settings.Target.Enabled and (ESP.ActiveTarget == player) and settings.Target.Color or nil
    local protected = false
    if settings.ForceField.Enabled then
        if record.SourceCharacter and record.SourceCharacter ~= character then
            protected = ESP:HasForceField(record.SourceCharacter)
        else
            local forceField, value = record.ForceFieldInstance, record.ForceFieldValue
            protected = forceField and forceField.Parent == character
                or value and value.Parent == character and value:IsA('BoolValue') and value.Value == true
                or false
        end
    end
    if not frame.TwoDimensional then
        record.Rendering = true
        if record.DrawingVisible then
            for _, draw in pairs(record.Drawings) do
                draw.Visible = false
            end
            record.DrawingVisible = false
        end
        profileStage(frame, 'ProjectionMs', projectionStarted)
        local effectsStarted = frame.Profile and clock() or nil
        effects(player, record, protected, color, hideEffects)
        profileStage(frame, 'EffectsMs', effectsStarted)
        return
    end
    local charSize = reuse and projection.Size
        or (
                camera:WorldToViewportPoint(rootPosition - lowerOffset).Y
                - camera:WorldToViewportPoint(rootPosition + upperOffset).Y
            )
            / 2
    if projection then
        projection.Size = charSize
    end
    if charSize <= 0 or charSize ~= charSize then
        profileStage(frame, 'ProjectionMs', projectionStarted)
        utility.funcs.clear_esp(player, record)
        return
    end
    local size = Vector2.new(charSize * 1.5, charSize * 3.2)
    local position = Vector2.new(hrp2D.X - charSize * 1.5 / 2, hrp2D.Y - charSize * 3 / 2)
    profileStage(frame, 'ProjectionMs', projectionStarted)
    local effectsStarted = frame.Profile and clock() or nil
    local spacing = record.PhowgBarSpacing or emptyBarSpacing
    local topSpace, bottomSpace, rightSpace = spacing.Top or 0, spacing.Bottom or 0, math.max(4, spacing.Right or 0)
    record.PhowgAppliedBarSpacing = spacing
    utility.funcs.render(player, record)
    local draws = record.Drawings
    if record.DrawOrigin ~= position then
        record.DrawOrigin = position
        record.DrawFrame.Position = UDim2.fromOffset(position.X, position.Y)
    end
    record.DrawingVisible = true
    record.LayoutPosition, record.LayoutSize, record.Rendering = position, size, true
    local health, maxHealth = humanoid.Health, humanoid.MaxHealth
    record.Fake_Health, record.Fake_MaxHealth = health, math.max(1, maxHealth)
    record.Fake_Armor = record.ArmorValue and record.ArmorValue.Parent and record.ArmorValue.Value or 0
    local fading = settings.Animation.Mode == 'fading'
    local opacity = fading and math.min(1, (record.Opacity or 0) + frame.Delta * 8) or 1
    record.Opacity = opacity
    if record.DrawingOpacity ~= opacity then
        for name, draw in pairs(draws) do
            if name ~= 'Image' then
                draw.Transparency = opacity
            end
        end
        record.DrawingOpacity = opacity
    end
    ESP:RenderBoxStyle(record, position, size, color, opacity, hideEffects, frame.Now)
    draws.Image.Visible = settings.Image.Enabled and not hideEffects
    if settings.Image.Enabled and not hideEffects then
        if not record.ImageGradient then
            record.ImageGradient = Instance.new('UIGradient')
            record.ImageGradient.Rotation, record.ImageGradient.Parent = 90, draws.Image.Object
            record.ImageGradient.Transparency =
                NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
        end
        draws.Image.Position, draws.Image.Size, draws.Image.Color, draws.Image.Transparency =
            position, size, color or settings.Image.Color or white, 0.15 * opacity
        local gradientEnabled = settings.Image.Data == 'Gradient'
        if record.ImageGradientEnabled ~= gradientEnabled then
            record.ImageGradient.Enabled, record.ImageGradientEnabled = gradientEnabled, gradientEnabled
        end
    end
    profileStage(frame, 'EffectsMs', effectsStarted)
    updateFlags(record, rootPosition, frame.Now)
    local labelsStarted = frame.Profile and clock() or nil
    local flagged = settings.DetectCheaters.Enabled and record.LockFlagged >= 1
    if settings.Name.Enabled or flagged then
        local both, display, username = settings.Name.Use_Both_Name, settings.Name.Use_Display_Name, record.PlayerName
        local masked = record.Mask ~= nil and record.Mask.Parent == character and not settings.Name.DisableMasks
        if
            record.NameBoth ~= both
            or record.NameDisplay ~= display
            or record.NameMasked ~= masked
            or not record.NameText
        then
            record.NameBoth, record.NameDisplay, record.NameMasked = both, display, masked
            record.NameText = masked and 'Masked'
                or both and (record.DisplayName .. ' (@' .. username .. ')')
                or display and record.DisplayName
                or username
        end
        local tag = flagged
                and (record.LockFlagged == 1 and ' [E] (not sure)' or record.LockFlagged == 2 and ' [E] (suspected)' or record.LockFlagged == 3 and ' [E] (flagged)' or ' [E] (bannable)')
            or ''
        if record.TagBase ~= record.NameText or record.NameTag ~= tag then
            record.TagBase, record.NameTag, record.TaggedName = record.NameText, tag, record.NameText .. tag
        end
        local text = record.TaggedName
        local nameColor = flagged and settings.DetectCheaters.RedName and cheaterRed or color or settings.Name.Color
        label(
            draws.Name,
            true,
            text,
            position + Vector2.new(size.X / 2, -settings.Misc.MainSize - 4 - topSpace),
            nameColor,
            settings.Misc.MainSize
        )
    else
        draws.Name.Visible = false
    end
    if settings.Inventory.Enabled and not hideSecondary and record.InventoryRows > 0 then
        local font = settings.Misc.MainSize + 1
        local height = (record.InventoryRows + 1) * (font + 2)
        local crewHeight = settings.Crew.Enabled
                and type(ESP.CrewNames[player]) == 'string'
                and ESP.CrewNames[player] ~= ''
                and settings.Misc.SmallSize + 3
            or 0
        label(
            draws.InventoryText,
            true,
            record.InventoryText,
            position + Vector2.new(size.X / 2, -height - settings.Misc.MainSize - 10 - topSpace - crewHeight),
            settings.Inventory.Color,
            font
        )
    else
        draws.InventoryText.Visible = false
    end
    local below = size.Y + 4 + bottomSpace
    if settings.Distance.Enabled and not hideSecondary then
        local rawMeters = distance * 0.28
        local meters = floor(rawMeters + 0.5)
        if rawMeters % 1 == 0.5 and meters % 2 == 1 then
            meters -= 1
        end
        if record.DistanceValue ~= meters then
            record.DistanceValue, record.DistanceText = meters, string.format('[%.0fm]', rawMeters)
        end
        label(
            draws.Distance,
            true,
            record.DistanceText,
            position + Vector2.new(size.X / 2, below),
            color or settings.Distance.Color,
            settings.Misc.SmallSize
        )
        below = below + math.max(14, settings.Misc.SmallSize + 2)
    else
        draws.Distance.Visible = false
    end
    local lineHeight = math.max(10, settings.Misc.SmallSize + (settings.Misc.LabelGap or 1))
    if settings.Country.Enabled and not hideSecondary then
        label(
            draws.CountryText,
            true,
            (settings.Country.SimulatedIP and record.CountryIPText or record.CountryText) or 'Unknown',
            position + Vector2.new(size.X / 2, below),
            settings.Country.Color,
            settings.Misc.SmallSize
        )
        below += lineHeight
    else
        draws.CountryText.Visible = false
    end
    if settings.Money.Enabled and not hideSecondary then
        label(
            draws.MoneyText,
            true,
            record.MoneyText or 'money: N/A',
            position + Vector2.new(size.X / 2, below),
            settings.Money.Color,
            settings.Misc.SmallSize
        )
        below += lineHeight
    else
        draws.MoneyText.Visible = false
    end
    if settings.Device.Enabled and not hideSecondary then
        label(
            draws.DeviceText,
            true,
            record.DeviceText or 'device: Unknown',
            position + Vector2.new(size.X / 2, below),
            settings.Device.Color,
            settings.Misc.SmallSize
        )
        below += lineHeight
    else
        draws.DeviceText.Visible = false
    end
    local tool = record.EquippedTool
    if settings.ToolText.Enabled and not hideSecondary and (tool or not settings.ToolText.HideNone) then
        label(
            draws.ToolText,
            true,
            record.ToolName,
            position + Vector2.new(size.X / 2, below),
            color or settings.ToolText.Color,
            settings.Misc.SmallSize
        )
        below = below + math.max(14, settings.Misc.SmallSize + 2)
    else
        draws.ToolText.Visible = false
    end
    local weaponVisible = false
    if settings.WeaponIcon.Enabled and tool and not hideSecondary then
        if not IconTable then
            FetchIcons()
        end
        if record.IconToolName ~= record.ToolName or record.IconSourceTable ~= IconTable then
            record.IconToolName, record.IconKey, record.IconSourceTable =
                record.ToolName, IconKey(record.ToolName), IconTable
            record.IconData = GetIconData(record.IconKey)
        end
        local image = record.IconData
        if image then
            draws.WeaponIcon.Data, draws.WeaponIcon.Position, draws.WeaponIcon.Size, draws.WeaponIcon.Color =
                image,
                position + Vector2.new(size.X / 2 - 20, below),
                Vector2.new(40, 20),
                color or settings.WeaponIcon.Color
            weaponVisible = true
        end
    end
    draws.WeaponIcon.Visible = weaponVisible
    local crew = ESP.CrewNames[player]
    local crewOn = settings.Crew.Enabled and not hideSecondary and type(crew) == 'string' and crew ~= ''
    local crewY = -4 - topSpace - settings.Misc.SmallSize
    if settings.Name.Enabled or flagged then
        crewY -= settings.Misc.MainSize + 3
    end
    if crewOn then
        label(
            draws.CrewText,
            true,
            crew,
            position + Vector2.new(size.X / 2, crewY),
            color or settings.Crew.Color,
            settings.Misc.SmallSize
        )
    else
        draws.CrewText.Visible = false
    end
    local crewId = ESP.CrewIds[player]
    if crewOn and settings.Crew.Count then
        local count = ESP.CrewCounts[crewId] or 0
        if record.CrewCountValue ~= count then
            record.CrewCountValue, record.CrewCountText = count, '[' .. tostring(count) .. ']'
        end
        label(
            draws.CrewCount,
            true,
            record.CrewCountText,
            position + Vector2.new(size.X + 4, crewY),
            color or settings.Crew.Color,
            settings.Misc.SmallSize
        )
    else
        draws.CrewCount.Visible = false
    end
    local icon = crewId and ESP.CrewIcons[crewId]
    local crewIconVisible = crewOn and type(icon) == 'string' and icon ~= ''
    if crewIconVisible then
        draws.CrewIcon.Data, draws.CrewIcon.Position, draws.CrewIcon.Size =
            icon, position + Vector2.new(-18, crewY), Vector2.new(14, 14)
    end
    draws.CrewIcon.Visible = crewIconVisible == true
    profileStage(frame, 'LabelsIconsMs', labelsStarted)
    effectsStarted = frame.Profile and clock() or nil
    for index, kind in ipairs(barKinds) do
        local barSettings, value = settings.Bars[kind], kind == 'Health' and record.Fake_Health or record.Fake_Armor
        local bar, outline = draws[kind .. 'Bar'], draws[kind .. 'BarOutline']
        local shown = barSettings.Enabled and (kind ~= 'Armor' or not barSettings.Hide_If_Empty or value > 0)
        bar.Visible, outline.Visible = shown, shown
        if shown and not ESP.PhowgRenderBars then
            local maximum = kind == 'Health' and record.Fake_MaxHealth or 130
            local ratio = clamp(value / maximum, 0, 1)
            local prior = record['Last' .. kind] or ratio
            local smooth = prior + (ratio - prior) * frame.SmoothAlpha
            record['Last' .. kind] = smooth
            local x = position.X - (index == 1 and 7 or 13)
            outline.Position, outline.Size = Vector2.new(x - 1, position.Y - 1), Vector2.new(5, size.Y + 2)
            bar.Position, bar.Size, bar.Color =
                Vector2.new(x, position.Y + (1 - smooth) * size.Y),
                Vector2.new(3, smooth * size.Y),
                barSettings.Gradient and white or color or barSettings.BaseColor or barSettings.Colors[1]
            ESP:SetBarGradient(
                record,
                kind,
                color or barSettings.BaseColor or barSettings.Colors[1],
                color or barSettings.GradientColor or barSettings.Colors[2] or bar.Color,
                false,
                false,
                0
            )
        end
    end
    profileStage(frame, 'EffectsMs', effectsStarted)
    labelsStarted = frame.Profile and clock() or nil
    local healthValue = floor(health)
    if record.HealthTextValue ~= healthValue then
        record.HealthTextValue, record.HealthText = healthValue, tostring(healthValue)
    end
    if settings.HealthText.Enabled and (not settings.HealthText.HideFullHealth or health < maxHealth) then
        label(
            draws.HealthText,
            true,
            record.HealthText,
            position + (spacing.HealthText or defaultHealthTextOffset),
            color or settings.HealthText.Color,
            settings.Misc.SmallSize
        )
    else
        draws.HealthText.Visible = false
    end
    local rightTop, rightLineHeight = 0, math.max(14, lineHeight)
    if settings.Accuracy.Enabled and not hideSecondary then
        local text = (settings.Accuracy.Mode == 'this session' or settings.Accuracy.Mode == 'this server')
                and record.AccuracySession
            or record.AccuracyAllTime
        label(
            draws.AccuracyText,
            true,
            text or 'A: N/A',
            position + Vector2.new(size.X + rightSpace, rightTop),
            settings.Accuracy.Color,
            settings.Misc.SmallSize
        )
        rightTop += rightLineHeight
    else
        draws.AccuracyText.Visible = false
    end
    local wanted = 0
    if settings.Wanted.Enabled and not hideSecondary and frame.Wanted then
        local ok, value = pcall(frame.Wanted, player)
        if ok then
            wanted = tonumber(value) or 0
        end
    end
    local wantedValue = floor(wanted)
    if record.WantedTextValue ~= wantedValue then
        record.WantedTextValue, record.WantedText = wantedValue, 'WANTED / ' .. tostring(wantedValue)
    end
    if settings.Wanted.Enabled and not hideSecondary and wanted > 0 then
        label(
            draws.WantedText,
            true,
            record.WantedText,
            position + Vector2.new(size.X + rightSpace, rightTop),
            color or settings.Wanted.Color,
            settings.Misc.SmallSize
        )
        rightTop += rightLineHeight
    else
        draws.WantedText.Visible = false
    end
    if settings.ForceField.Enabled and not hideSecondary and protected then
        label(
            draws.ForceFieldText,
            true,
            'FORCEFIELD',
            position + Vector2.new(size.X + rightSpace, rightTop),
            settings.ForceField.Color,
            settings.Misc.SmallSize
        )
        rightTop += rightLineHeight
    else
        draws.ForceFieldText.Visible = false
    end
    if settings.Flags.Enabled and not hideSecondary and record.FlagsText ~= '' then
        label(
            draws.FlagsText,
            true,
            record.FlagsText,
            position + Vector2.new(size.X + rightSpace, rightTop),
            settings.Flags.Color,
            settings.Misc.SmallSize
        )
    else
        draws.FlagsText.Visible = false
    end
    profileStage(frame, 'LabelsIconsMs', labelsStarted)
    effectsStarted = frame.Profile and clock() or nil
    local tracerEnabled = settings.Tracer.Enabled and not hideEffects
    local outlineEnabled = tracerEnabled and settings.Tracer.Outline
    draws.Tracer.Visible, draws.TracerOutline.Visible = tracerEnabled, outlineEnabled
    if tracerEnabled then
        local from, to = frame.TracerOrigin, position + Vector2.new(size.X / 2, size.Y / 2)
        draws.Tracer.Color, draws.Tracer.Thickness = color or settings.Tracer.Color, 1
        draws.Tracer:SetEndpoints(from, to)
        if outlineEnabled then
            draws.TracerOutline.Color, draws.TracerOutline.Thickness = black, 3
            draws.TracerOutline:SetEndpoints(from, to)
        end
    end
    effects(player, record, protected, color, hideEffects)
    if ESP.PhowgRenderBars then
        ESP.PhowgRenderBars(ESP, player, record, frame.Now)
    end
    profileStage(frame, 'EffectsMs', effectsStarted)
end
function ESP:Configure(config)
    local function merge(target, source)
        for key, value in pairs(source) do
            if type(value) == 'table' and type(target[key]) == 'table' then
                merge(target[key], value)
            else
                target[key] = value
            end
        end
    end
    local previousProfile = self.Settings.Performance.Profile
    merge(self.Settings, config)
    if config.Flags and type(config.Flags.Types) == 'table' then
        self.Settings.Flags.Types = table.clone(config.Flags.Types)
    end
    self.Settings.DistanceDetail.Distance = math.max(1, tonumber(self.Settings.DistanceDetail.Distance) or 300)
    self.Performance.Enabled = self.Settings.Performance.Profile == true
    if previousProfile ~= self.Settings.Performance.Profile then
        self:ResetPerformance()
    end
    enabled = false
    for _, key in ipairs({
        'Box',
        'Name',
        'Crew',
        'Distance',
        'Chams',
        'Highlight',
        'ToolText',
        'WeaponIcon',
        'HealthText',
        'Wanted',
        'ForceField',
        'Tracer',
        'Image',
        'DetectCheaters',
        'Accuracy',
        'Country',
        'Money',
        'Device',
        'Inventory',
        'Flags',
    }) do
        if self.Settings[key].Enabled then
            enabled = true
            break
        end
    end
    enabled = enabled or self.Settings.Bars.Health.Enabled or self.Settings.Bars.Armor.Enabled
    revision = revision + 1
    for _, record in pairs(cache) do
        subscribe(record)
        subscribeStats(record)
        subscribeIdentity(record)
        updateInventory(record)
        syncNormalName(record)
        local tool = record.EquippedTool
        local needsTool = tool and (self.Settings.ToolText.Enabled or self.Settings.WeaponIcon.Enabled)
        if needsTool and not record.ToolNameConnection then
            record.ToolName = tool.Name
            record.ToolNameConnection = connect(tool:GetPropertyChangedSignal('Name'), function()
                record.ToolName, record.IconToolName, record.IconKey = tool.Name, nil, nil
            end, record.Player, 'esp tool name', true)
        elseif not needsTool and record.ToolNameConnection then
            record.ToolNameConnection:Disconnect()
            record.ToolNameConnection = nil
        end
    end
end
function ESP:Refresh()
    revision = revision + 1
end
function ESP:Update_ESP_Color()
    self:Refresh()
end
function ESP:FadeAll()
    for _, record in pairs(cache) do
        record.Opacity = 0
    end
end
for _, player in ipairs(Players:GetPlayers()) do
    track(player)
end
connect(Players.PlayerAdded, track, Players, 'unnamed player added')
connect(Players.PlayerRemoving, function(player)
    if cache[player] then
        destroy(cache[player])
        cache[player] = nil
    end
    ESP.CrewNames[player], ESP.CrewIds[player] = nil, nil
end, Players, 'unnamed player removed')
local function renderFrame(delta)
    if not alive or not enabled then
        return
    end
    local started = ESP.Settings.Performance.Profile and clock() or nil
    local frame = frameContext(delta)
    for player, record in pairs(cache) do
        if frame.Profile then
            frame.Tracked += 1
        end
        local ok, err = pcall(utility.funcs.update, player, record, delta, frame)
        if not ok then
            utility.funcs.clear_esp(player, record)
            if tick() - (record.ErrorAt or -math.huge) > 5 then
                record.ErrorAt = tick()
                warn('[Phowg] unnamed ESP: ' .. tostring(err))
            end
        end
    end
    if started then
        local metrics = ESP.Performance
        metrics.Frames += 1
        metrics.Visible, metrics.Tracked = frame.Visible, frame.Tracked
        local total = (clock() - started) * 1000
        frame.ProjectionMs *= 1000
        frame.LabelsIconsMs *= 1000
        frame.EffectsMs *= 1000
        frame.OtherMs, frame.TotalMs =
            math.max(0, total - frame.ProjectionMs - frame.LabelsIconsMs - frame.EffectsMs), total
        for _, key in ipairs(timingKeys) do
            local value = frame[key]
            metrics.Last[key] = value
            metrics.Average[key] += (value - metrics.Average[key]) / metrics.Frames
            metrics.Peak[key] = math.max(metrics.Peak[key], value)
        end
    end
end
function ESP:GetDiagnostics()
    local result = {
        Alive = alive,
        Enabled = enabled,
        Tracked = 0,
        Subscribed = 0,
        Connections = 0,
        GlobalConnections = 0,
        CharacterConnections = 0,
        StatsConnections = 0,
        PlayerConnections = 0,
        IdentityConnections = 0,
        ToolConnections = 0,
        RenderBound = self.RenderBound == true,
    }
    local function count(list)
        local total = 0
        for _, connection in ipairs(list or {}) do
            if connection.Connected then
                total += 1
            end
        end
        return total
    end
    result.GlobalConnections = count(connections)
    for _, record in pairs(cache) do
        result.Tracked += 1
        if record.Subscribed then
            result.Subscribed += 1
        end
        result.CharacterConnections += count(record.CharacterConnections)
        result.StatsConnections += count(record.StatsConnections)
        result.PlayerConnections += count(record.Connections)
        result.IdentityConnections += count(record.IdentityConnections)
        if record.ToolNameConnection and record.ToolNameConnection.Connected then
            result.ToolConnections += 1
        end
    end
    result.Connections = result.GlobalConnections
        + result.CharacterConnections
        + result.StatsConnections
        + result.PlayerConnections
        + result.IdentityConnections
        + result.ToolConnections
    return result
end
local environment = getgenv()
environment.PhowgESPRenderSerial = (environment.PhowgESPRenderSerial or 0) + 1
local renderName = 'PhowgESP:' .. tostring(environment.PhowgESPRenderSerial)
local renderBound = false
if RunService.BindToRenderStep then
    renderBound = pcall(function()
        RunService:BindToRenderStep(renderName, Enum.RenderPriority.Camera.Value + 1, renderFrame)
    end)
end
if not renderBound then
    connect(RunService.RenderStepped, renderFrame, RunService, 'unnamed render')
end
ESP.RenderBound, ESP.RenderName = renderBound, renderName
ESP._Cleanup = function()
    if not alive then
        return
    end
    alive, enabled = false, false
    ESP.RenderBound = false
    if renderBound then
        RunService:UnbindFromRenderStep(renderName)
        renderBound = false
    end
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    for _, record in pairs(cache) do
        destroy(record)
    end
    table.clear(cache)
    gui:Destroy()
end
ESP.Cache, ESP.Utility = cache, utility
return ESP
