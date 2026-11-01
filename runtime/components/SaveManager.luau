local httpService = game:GetService('HttpService')

local SaveManager = {}
do
    SaveManager.Folder = 'LinoriaLibSettings'
    SaveManager.Ignore = {}
    SaveManager.AutoloadLabel = nil
    SaveManager.Library = nil
    SaveManager.PhowgRevision = 9
    SaveManager.RuntimeRevision = 1
    SaveManager.FrameBatchedLoading = false
    SaveManager.AtomicConfigLoading = true
    SaveManager.SchemaVersion = 1
    SaveManager.IndexAliases = {}
    SaveManager.States = {}
    SaveManager.Baseline = { Controls = {}, States = {} }
    SaveManager.DirtyControls, SaveManager.DirtyStates, SaveManager.DirtyReasons = {}, {}, {}
    SaveManager.ObservedControls, SaveManager.StatusListeners = {}, {}
    SaveManager.TrackingReady = false
    function SaveManager:RegisterState(idx, capture, apply, category)
        assert(
            type(idx) == 'string' and type(capture) == 'function' and type(apply) == 'function',
            'invalid persistent state'
        )
        self.States[idx] = { Capture = capture, Apply = apply, Category = category or self:GetCategory(idx) }
        if self.ObserveState then
            self:ObserveState(idx)
        end
    end
    SaveManager.Migrations = {
        [0] = function(data)
            data.schemaVersion = 1
            return data
        end,
    }
    function SaveManager:SetIndexAliases(aliases)
        for oldIndex, newIndex in pairs(aliases) do
            if type(oldIndex) == 'string' and type(newIndex) == 'string' then
                self.IndexAliases[oldIndex] = newIndex
            end
        end
    end
    function SaveManager:Migrate(data)
        if type(data) ~= 'table' or type(data.objects) ~= 'table' then
            return nil, 'invalid config data'
        end
        local version = data.schemaVersion
        if version == nil then
            version = 0
        end
        if type(version) ~= 'number' or version < 0 or version % 1 ~= 0 then
            return nil, 'invalid schema version'
        end
        if version > self.SchemaVersion then
            return nil, 'config requires a newer script version'
        end
        data = table.clone(data)
        while version < self.SchemaVersion do
            local migration = self.Migrations[version]
            if not migration then
                return nil, 'missing config migration'
            end
            local ok, result = pcall(migration, data)
            if
                not ok
                or type(result) ~= 'table'
                or result.schemaVersion ~= version + 1
                or type(result.objects) ~= 'table'
            then
                return nil, 'config migration failed'
            end
            data = result
            version += 1
        end
        local objects = {}
        for _, object in pairs(data.objects) do
            if type(object) == 'table' then
                local copy = table.clone(object)
                if type(copy.idx) == 'string' then
                    copy.idx = self.IndexAliases[copy.idx] or copy.idx
                end
                table.insert(objects, copy)
            end
        end
        data.objects = objects
        return data
    end

    local function NormalizeConfigName(name)
        if type(name) ~= 'string' then
            return nil
        end
        local clean = name:gsub('%s+', '')
        if clean:sub(-5):lower() == '.json' then
            clean = clean:sub(1, -6)
        end
        if
            clean == ''
            or #clean > 96
            or (clean:find('/', 1, true) or clean:find('\\', 1, true) or clean:find('[:%c]'))
            or clean:find('..', 1, true)
        then
            return nil
        end
        return clean
    end

    local function split(str, delim)
        if str.split then
            local ok, res = pcall(function()
                return str:split(delim)
            end)
            if ok and type(res) == 'table' then
                return res
            end
        end
        local out = {}
        for part in string.gmatch(str, '[^' .. delim .. ']+') do
            table.insert(out, part)
        end
        return out
    end

    local function getToggles()
        if SaveManager.Library and SaveManager.Library.Toggles then
            return SaveManager.Library.Toggles
        end
        if getgenv then
            local ok, t = pcall(getgenv)
            if ok and type(t) == 'table' and t.Toggles then
                return t.Toggles
            end
        end
        if getgenv and getgenv().Toggles then
            return getgenv().Toggles
        end
        if _G and _G.Toggles then
            return _G.Toggles
        end
        return (SaveManager.Library and SaveManager.Library.Toggles) or Toggles
    end

    local function getOptions()
        if SaveManager.Library and SaveManager.Library.Options then
            return SaveManager.Library.Options
        end
        if getgenv then
            local ok, t = pcall(getgenv)
            if ok and type(t) == 'table' and t.Options then
                return t.Options
            end
        end
        if getgenv and getgenv().Options then
            return getgenv().Options
        end
        if _G and _G.Options then
            return _G.Options
        end
        return (SaveManager.Library and SaveManager.Library.Options) or Options
    end

    local function getControls()
        local controls = {}
        for _, source in ipairs({ getToggles() or {}, getOptions() or {} }) do
            for idx, control in pairs(source) do
                if type(idx) == 'string' and type(control) == 'table' then
                    controls[idx] = control
                end
            end
        end
        local registry = SaveManager.Library and SaveManager.Library.ControlRegistry
        for idx, entry in pairs(registry or {}) do
            if type(idx) == 'string' and type(entry.Control) == 'table' then
                controls[idx] = entry.Control
            end
        end
        return controls
    end
    local function findControl(idx)
        local registry = SaveManager.Library and SaveManager.Library.ControlRegistry
        local entry = registry and registry[idx]
        return (entry and entry.Control) or (getToggles() or {})[idx] or (getOptions() or {})[idx]
    end
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                local v = object.Value
                if type(v) ~= 'boolean' then
                    v = not not v
                end
                return { type = 'Toggle', idx = idx, value = v }
            end,
            Load = function(idx, data)
                local function findToggle(key)
                    local cands = {}
                    local lib = SaveManager.Library
                    if lib and lib.Toggles then
                        table.insert(cands, lib.Toggles)
                    end
                    local t = getToggles()
                    if t and t ~= (lib and lib.Toggles) then
                        table.insert(cands, t)
                    end
                    local o = getOptions()
                    if o and o ~= t then
                        table.insert(cands, o)
                    end
                    if Toggles and Toggles ~= t then
                        table.insert(cands, Toggles)
                    end
                    if Options and Options ~= o then
                        table.insert(cands, Options)
                    end

                    for _, tbl in ipairs(cands) do
                        if tbl[key] then
                            return tbl[key]
                        end
                    end

                    local low = key:lower()
                    for _, tbl in ipairs(cands) do
                        for k, v in pairs(tbl) do
                            if
                                type(k) == 'string'
                                and k:lower() == low
                                and v
                                and (v.Type == 'Toggle' or v.SetValue)
                            then
                                return v
                            end
                        end
                    end
                    return nil
                end

                local obj = findToggle(idx)
                obj = findControl(idx) or obj
                if obj then
                    local v = data.value
                    if type(v) == 'string' then
                        local low = v:lower()
                        if low == 'true' or low == '1' then
                            v = true
                        elseif low == 'false' or low == '0' then
                            v = false
                        else
                            v = not not v
                        end
                    elseif type(v) == 'number' then
                        v = v ~= 0
                    elseif type(v) ~= 'boolean' then
                        v = not not v
                    end

                    if obj.SetValue then
                        obj:SetValue(v, idx == 'void_hide' or idx == 'underground' or idx == 'desync_rotation')
                    else
                        obj.Value = v
                        if obj.Display then
                            pcall(function()
                                obj:Display()
                            end)
                        end
                    end

                    if obj.Value ~= v then
                        obj.Value = v
                        if obj.Display then
                            pcall(function()
                                obj:Display()
                            end)
                        end
                    end
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = 'Slider', idx = idx, value = tostring(object.Value) }
            end,
            Load = function(idx, data)
                local obj = findControl(idx)
                if obj and obj.SetValue then
                    local v = tonumber(data.value) or data.value
                    if v ~= nil then
                        obj:SetValue(v)
                    end
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return {
                    type = 'Dropdown',
                    idx = idx,
                    value = type(object.Value) == 'table' and table.clone(object.Value) or object.Value,
                    multi = object.Multi,
                }
            end,
            Load = function(idx, data)
                local obj = findControl(idx)
                if obj and obj.SetValue then
                    obj:SetValue(data.value)
                end
            end,
        },
        ColorPicker = {
            Save = function(idx, object)
                local color = object.RgbEnabled and object.OriginalValue or object.Value
                return {
                    type = 'ColorPicker',
                    idx = idx,
                    value = color:ToHex(),
                    transparency = object.RgbEnabled and object.OriginalTransparency or object.Transparency,
                    rgb = object.RgbEnabled == true,
                    chromaSpeed = object.ChromaSpeed or 1,
                }
            end,
            Load = function(idx, data)
                local obj = findControl(idx)
                if obj and type(data.value) == 'string' then
                    local ok, col = pcall(Color3.fromHex, data.value)
                    if ok and typeof(col) == 'Color3' then
                        local library = SaveManager.Library
                        if library and library.SetChromaEnabled then
                            library:SetChromaEnabled(obj, false)
                        end
                        obj:SetValueRGB(col, tonumber(data.transparency) or 0)
                        obj.ChromaSpeed = math.clamp(tonumber(data.chromaSpeed) or 1, 1, 5)
                        if obj.UpdateChromaSpeed then
                            obj.UpdateChromaSpeed()
                        end
                        if library and library.SetChromaEnabled then
                            library:SetChromaEnabled(obj, data.rgb == true)
                        end
                    end
                end
            end,
        },
        KeyPicker = {
            Save = function(idx, object)
                local mode = object.Mode
                if type(mode) ~= 'string' then
                    mode = 'Toggle'
                end
                local key = object.Value
                if type(key) ~= 'string' or key == '' then
                    key = 'None'
                end
                return { type = 'KeyPicker', idx = idx, mode = mode, key = key }
            end,
            Load = function(idx, data)
                local obj = findControl(idx)
                if obj and type(data) == 'table' and type(data.key) == 'string' then
                    local mode = data.mode
                    if type(mode) ~= 'string' then
                        mode = 'Toggle'
                    end
                    obj:SetValue({ data.key, mode })
                end
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type = 'Input', idx = idx, text = object.Value }
            end,
            Load = function(idx, data)
                local obj = findControl(idx)
                if obj and type(data.text) == 'string' then
                    obj:SetValue(data.text)
                end
            end,
        },
    }

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do
            self.Ignore[key] = true
            self.DirtyControls[key], self.DirtyStates[key] = nil, nil
        end
        if self.TrackingReady then
            self:RefreshDirtyFlag()
        end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    local function copyValue(value, seen)
        if type(value) ~= 'table' then
            return value
        end
        seen = seen or {}
        if seen[value] then
            return seen[value]
        end
        local result = {}
        seen[value] = result
        for key, item in pairs(value) do
            result[key] = copyValue(item, seen)
        end
        return result
    end
    function SaveManager:CaptureCurrent()
        local data, failures = { schemaVersion = self.SchemaVersion, objects = {}, states = {} }, {}
        for idx, control in pairs(getControls()) do
            local parser = type(control) == 'table' and self.Parser[control.Type]
            if not self.Ignore[idx] then
                if not parser then
                    failures[#failures + 1] = idx .. ': unsupported control type'
                    continue
                end
                local ok, object = pcall(parser.Save, idx, control)
                if ok and type(object) == 'table' then
                    local entry = self.Library and self.Library.ControlRegistry and self.Library.ControlRegistry[idx]
                    object.category = entry and entry.Category or self:GetCategory(idx)
                    data.objects[#data.objects + 1] = object
                else
                    failures[#failures + 1] = idx .. ': ' .. tostring(object)
                end
            end
        end
        for idx, state in pairs(self.States) do
            if not self.Ignore[idx] then
                local ok, value = pcall(state.Capture)
                if ok and value ~= nil then
                    data.states[idx] = copyValue(value)
                else
                    failures[#failures + 1] = idx .. ': ' .. tostring(value or 'state capture returned nil')
                end
            end
        end
        table.sort(data.objects, function(a, b)
            return a.idx < b.idx
        end)
        self.LastSaveFailures = failures
        return data, failures
    end
    function SaveManager:GetCategory(idx)
        local registry = self.Library and self.Library.ControlRegistry
        if registry and registry[idx] and registry[idx].Category then
            return registry[idx].Category
        end
        if idx:find('^shield_') then
            return 'protection'
        end
        if
            idx:find('^SaveManager_')
            or idx:find('^ui_')
            or idx:find('^hud_')
            or idx:find('^settings_')
            or idx:find('^performance_')
            or idx:find('^cosmetic_')
        then
            return 'interface'
        end
        for _, word in ipairs({
            'esp',
            'crosshair',
            'tracer',
            'afterimage',
            'target_hud',
            'china_hat',
            'hit_',
            'ambient',
            'lighting',
            'radar',
            'offscreen',
            'indicator',
            'visual',
        }) do
            if idx:find(word, 1, true) then
                return 'visuals'
            end
        end
        for _, word in ipairs({
            'desync',
            'strafe',
            'fly',
            'void',
            'underground',
            'speed',
            'jump',
            'walk',
            'noclip',
            'flashback',
        }) do
            if idx:find(word, 1, true) then
                return 'movement'
            end
        end
        return 'other'
    end
    function SaveManager:ReadConfig(name, backup)
        local clean = NormalizeConfigName(name)
        if not clean then
            return nil, 'select a valid config name'
        end
        local file = self.Folder .. '/settings/' .. clean .. '.json' .. (backup and '.bak' or '')
        local ok, raw = pcall(readfile, file)
        if not ok then
            return nil, 'could not read config'
        end
        local decoded, data = pcall(httpService.JSONDecode, httpService, raw)
        if not decoded then
            return nil, 'invalid JSON'
        end
        return self:Migrate(data)
    end
    local function equal(a, b)
        if type(a) ~= type(b) then
            return false
        end
        if type(a) ~= 'table' then
            return a == b
        end
        for k, v in pairs(a) do
            if not equal(v, b[k]) then
                return false
            end
        end
        for k in pairs(b) do
            if a[k] == nil then
                return false
            end
        end
        return true
    end

    local function persistenceObject(idx, control)
        local parser = type(control) == 'table' and SaveManager.Parser[control.Type]
        if not parser then
            return nil, 'unsupported control type'
        end
        local ok, object = pcall(parser.Save, idx, control)
        if not ok or type(object) ~= 'table' then
            return nil, tostring(object)
        end
        object.category = nil
        return object
    end
    function SaveManager:RefreshDirtyFlag()
        local dirty = next(self.DirtyControls) ~= nil or next(self.DirtyStates) ~= nil or next(self.DirtyReasons) ~= nil
        self.Dirty = dirty
        if self.Library then
            self.Library.ConfigDirty = dirty
        end
        self:UpdateStatus()
        return dirty
    end
    function SaveManager:ObserveState(idx)
        local state = self.States[idx]
        if not state or self.Ignore[idx] or self.Baseline.States[idx] ~= nil then
            return
        end
        local ok, value = pcall(state.Capture)
        if ok and value ~= nil then
            self.Baseline.States[idx] = copyValue(value)
        end
    end
    function SaveManager:MarkStateChanged(idx)
        local lib = self.Library
        if self.Loading or (lib and (lib.SuppressSave or lib.ConfigLoading or lib.Unloaded)) then
            return
        end
        local state = self.States[idx]
        if not state or self.Ignore[idx] then
            return
        end
        local ok, value = pcall(state.Capture)
        if not ok or value == nil then
            self.DirtyStates[idx] = true
        else
            self.DirtyStates[idx] = not equal(value, self.Baseline.States[idx]) or nil
        end
        self:RefreshDirtyFlag()
    end
    function SaveManager:ObserveControl(idx, control)
        if type(idx) ~= 'string' or type(control) ~= 'table' or not self.Parser[control.Type] then
            return
        end
        if self.ObservedControls[control] then
            return
        end
        self.ObservedControls[control] = idx
        local snapshot = persistenceObject(idx, control)
        if snapshot and not self.Ignore[idx] and self.Baseline.Controls[idx] == nil then
            self.Baseline.Controls[idx] = copyValue(snapshot)
        end
        for _, method in ipairs({ 'SetValue', 'SetValueRGB' }) do
            local original = control[method]
            if type(original) == 'function' then
                control[method] = function(object, ...)
                    local results = table.pack(original(object, ...))
                    if self.Library and not self.Library.Unloaded then
                        self:OnControlChanged(idx, object)
                    end
                    return table.unpack(results, 1, results.n)
                end
            end
        end
    end
    function SaveManager:SetBaseline(data)
        local failures
        if not data then
            data, failures = self:CaptureCurrent()
        end
        if failures and #failures > 0 then
            self.DirtyReasons.capture = true
            self:RefreshDirtyFlag()
            return false, table.concat(failures, '; ')
        end
        local baseline = { Controls = {}, States = {} }
        for _, object in ipairs(data.objects or {}) do
            if not self.Ignore[object.idx] then
                local value = copyValue(object)
                value.category = nil
                baseline.Controls[object.idx] = value
            end
        end
        for idx, value in pairs(data.states or {}) do
            if not self.Ignore[idx] then
                baseline.States[idx] = copyValue(value)
            end
        end
        self.Baseline = baseline
        table.clear(self.DirtyControls)
        table.clear(self.DirtyStates)
        table.clear(self.DirtyReasons)
        self.TrackingReady = true
        self:RefreshDirtyFlag()
        return true
    end
    function SaveManager:RefreshDirtyState()
        if not self.TrackingReady then
            return self:SetBaseline()
        end
        table.clear(self.DirtyControls)
        table.clear(self.DirtyStates)
        for idx, control in pairs(getControls()) do
            if not self.Ignore[idx] then
                local snapshot = persistenceObject(idx, control)
                if not snapshot or not equal(snapshot, self.Baseline.Controls[idx]) then
                    self.DirtyControls[idx] = true
                end
            end
        end
        for idx, state in pairs(self.States) do
            if not self.Ignore[idx] then
                local ok, value = pcall(state.Capture)
                if not ok or value == nil or not equal(value, self.Baseline.States[idx]) then
                    self.DirtyStates[idx] = true
                end
            end
        end
        return self:RefreshDirtyFlag()
    end
    function SaveManager:OnControlChanged(idx, control)
        local lib = self.Library
        if self.Loading or (lib and (lib.SuppressSave or lib.ConfigLoading or lib.Unloaded)) then
            return
        end
        if lib and lib.ControlsReady == false then
            return
        end
        if type(idx) == 'string' then
            if not self.Ignore[idx] then
                control = control or findControl(idx)
                if control then
                    local snapshot = persistenceObject(idx, control)
                    if not snapshot or not equal(snapshot, self.Baseline.Controls[idx]) then
                        self.DirtyControls[idx] = true
                    else
                        self.DirtyControls[idx] = nil
                    end
                end
            end
            for stateIndex in pairs(self.States) do
                self:MarkStateChanged(stateIndex)
            end
            self:RefreshDirtyFlag()
            return
        end
        if self.DirtyCheckPending then
            return
        end
        self.DirtyCheckPending = true
        task.defer(function()
            self.DirtyCheckPending = false
            if
                self.Loading
                or (lib and (lib.SuppressSave or lib.ConfigLoading or lib.Unloaded or lib.ControlsReady == false))
            then
                return
            end
            self:RefreshDirtyState()
        end)
    end
    function SaveManager:GetFilteredConfigList(query)
        query = tostring(query or ''):lower():match('^%s*(.-)%s*$')
        local values = {}
        for _, name in ipairs(self:RefreshConfigList()) do
            if query == '' or name:lower():find(query, 1, true) then
                values[#values + 1] = name
            end
        end
        return values
    end
    function SaveManager:RegisterStatusListener(callback)
        assert(type(callback) == 'function', 'invalid status listener')
        local token = {}
        self.StatusListeners[token] = callback
        pcall(callback, self:GetStatusText(true), self.Dirty == true, self)
        return function()
            self.StatusListeners[token] = nil
        end
    end
    function SaveManager:GetStatusText(compact)
        local state = self.Dirty and 'unsaved changes' or (self.CurrentConfig and 'saved' or 'unchanged')
        local text = tostring(self.CurrentConfig or 'default settings') .. ' | ' .. state
        local action = self.LastAction
        if compact then
            if action and not action.Success then
                text ..= ' | ' .. action.Kind .. ' failed'
            end
            return text
        end
        if action then
            text ..= '\nlast action: ' .. action.Kind .. (action.Success and ' complete' or (' failed: ' .. tostring(
                action.Message
            )))
        end
        text ..= '\nlast save: ' .. (self.LastSavedAt and os.date('%H:%M:%S', self.LastSavedAt) or 'never')
        local report = self.LastLoadReport
        if report then
            text ..= string.format(
                '\nloaded %d | missing %d | ignored %d | skipped %d | failed %d',
                report.Loaded,
                report.Missing,
                report.Ignored,
                report.Skipped,
                report.Failed
            )
        end
        return text
    end
    function SaveManager:Compare(name)
        local data, err = self:ReadConfig(name)
        if not data then
            return nil, err
        end
        local current, changes = {}, {}
        local captured = self:CaptureCurrent()
        for _, object in ipairs(captured.objects) do
            current[object.idx] = object
        end
        for idx, value in pairs(type(data.states) == 'table' and data.states or {}) do
            if not equal(captured.states[idx], value) then
                changes[#changes + 1] = idx .. ': saved state differs'
            end
        end
        for _, object in ipairs(data.objects) do
            local old = current[object.idx]
            if not old then
                changes[#changes + 1] = object.idx .. ': missing or ignored'
            else
                local a, b = table.clone(old), table.clone(object)
                a.category, b.category = nil, nil
                if not equal(a, b) then
                    local function value(o)
                        local v = o.key and (o.key .. ' (' .. tostring(o.mode) .. ')') or o.text or o.value
                        if type(v) == 'table' then
                            return httpService:JSONEncode(v)
                        end
                        return tostring(v)
                    end
                    changes[#changes + 1] = object.idx .. ': ' .. value(old) .. ' -> ' .. value(object)
                end
            end
        end
        table.sort(changes)
        return changes
    end
    function SaveManager:Export(name)
        local data, err
        if name then
            data, err = self:ReadConfig(name)
        else
            local failures
            data, failures = self:CaptureCurrent()
            if #failures > 0 then
                return nil, 'failed to capture settings: ' .. table.concat(failures, '; ')
            end
        end
        if not data then
            return nil, err
        end
        local ok, raw = pcall(httpService.JSONEncode, httpService, data)
        if not ok then
            return nil, 'could not encode config'
        end
        return raw
    end
    function SaveManager:Import(name, raw)
        local clean = NormalizeConfigName(name)
        if not clean then
            return false, 'invalid config name'
        end
        local existsOk, exists = pcall(isfile, self.Folder .. '/settings/' .. clean .. '.json')
        if not existsOk or exists then
            return false, 'choose a new config name'
        end
        local ok, data = pcall(httpService.JSONDecode, httpService, raw)
        if not ok then
            return false, 'invalid JSON'
        end
        local migrated, err = self:Migrate(data)
        if not migrated then
            return false, err
        end
        local encodedOk, encoded = pcall(httpService.JSONEncode, httpService, migrated)
        if not encodedOk then
            return false, 'could not encode config'
        end
        local wrote, problem = pcall(writefile, self.Folder .. '/settings/' .. clean .. '.json', encoded)
        if wrote then
            return true, nil
        end
        return false, tostring(problem)
    end
    function SaveManager:Rename(oldName, newName)
        local old, new = NormalizeConfigName(oldName), NormalizeConfigName(newName)
        if not old or not new or old == new then
            return false, 'choose two different valid names'
        end
        local raw, err = self:Export(old)
        if not raw then
            return false, err
        end
        local ok, problem = self:Import(new, raw)
        if not ok then
            return false, problem
        end
        local removed, removeError = pcall(delfile, self.Folder .. '/settings/' .. old .. '.json')
        if not removed then
            return false, 'new copy saved; old config could not be removed: ' .. tostring(removeError)
        end
        local path = self.Folder .. '/settings/autoload.txt'
        local got, autoload = pcall(readfile, path)
        if got and NormalizeConfigName(autoload) == old then
            local updated, updateError = pcall(writefile, path, new)
            if not updated then
                return false, 'renamed; update autoload: ' .. tostring(updateError)
            end
            if self.AutoloadLabel then
                self.AutoloadLabel:SetText('Current autoload config: ' .. new)
            end
        end
        if self.CurrentConfig == old then
            self.CurrentConfig = new
        end
        self:UpdateStatus()
        return true
    end
    function SaveManager:UpdateStatus()
        local text = self:GetStatusText(false)
        if self.StatusLabel and self.StatusText ~= text then
            self.StatusLabel:SetText(text)
            self.StatusText = text
        end
        local compact = self:GetStatusText(true)
        if self.CompactStatusText ~= compact then
            self.CompactStatusText = compact
            for _, callback in pairs(self.StatusListeners) do
                pcall(callback, compact, self.Dirty == true, self)
            end
        end
    end
    function SaveManager:CheckPersistence()
        local encoded, failures = self:CaptureCurrent()
        local count = 0
        for idx in pairs(self.States) do
            if not self.Ignore[idx] then
                count += 1
            end
        end
        local seen = {}
        for _, object in ipairs(encoded.objects) do
            seen[object.idx] = object
        end
        for idx, control in pairs(getControls()) do
            if type(control) == 'table' and not self.Ignore[idx] then
                count += 1
                if not self.Parser[control.Type] then
                    failures[#failures + 1] = idx .. ': unsupported type'
                elseif not seen[idx] then
                    failures[#failures + 1] = idx .. ': serialization failed'
                elseif
                    control.Type == 'KeyPicker'
                    and (
                        type(seen[idx].key) ~= 'string'
                        or seen[idx].mode ~= control.Mode
                        or not table.find({ 'Always', 'Hold', 'Toggle' }, seen[idx].mode)
                    )
                then
                    failures[#failures + 1] = idx .. ': keybind mismatch'
                elseif control.Type == 'Slider' then
                    local value = tonumber(seen[idx].value)
                    if not value or value ~= value or math.abs(value) == math.huge then
                        failures[#failures + 1] = idx .. ': invalid number'
                    end
                elseif control.Type == 'ColorPicker' then
                    local object = seen[idx]
                    if type(object.value) ~= 'string' or not object.value:match('^%x%x%x%x%x%x$') then
                        failures[#failures + 1] = idx .. ': invalid color'
                    end
                    local alpha = object.transparency
                    if alpha ~= nil and (type(alpha) ~= 'number' or alpha ~= alpha or alpha < 0 or alpha > 1) then
                        failures[#failures + 1] = idx .. ': invalid transparency'
                    end
                elseif control.Type == 'Input' and type(seen[idx].text) ~= 'string' then
                    failures[#failures + 1] = idx .. ': invalid text'
                end
            end
        end
        local ok, raw = pcall(httpService.JSONEncode, httpService, encoded)
        local decodedOk, decoded = false, nil
        if ok then
            decodedOk, decoded = pcall(httpService.JSONDecode, httpService, raw)
        end
        if not decodedOk or not equal(encoded, decoded) then
            failures[#failures + 1] = 'JSON round trip changed settings'
        end
        return #failures == 0, count, failures
    end

    function SaveManager:Save(name)
        local clean = NormalizeConfigName(name)
        if not clean then
            return false, 'no config file is selected'
        end

        local fullPath = self.Folder .. '/settings/' .. clean .. '.json'

        local data, failures = self:CaptureCurrent()
        if #failures > 0 then
            return false, 'failed to capture settings: ' .. table.concat(failures, '; ')
        end

        local success, encoded = pcall(httpService.JSONEncode, httpService, data)
        if not success then
            return false, 'failed to encode data'
        end

        local folderOk, folderError = pcall(function()
            self:BuildFolderTree()
        end)
        if not folderOk then
            return false, 'folder creation failed: ' .. tostring(folderError)
        end
        local existsOk, exists = pcall(isfile, fullPath)
        if not existsOk then
            return false, 'failed to check existing config'
        end
        local previous
        if exists then
            local readOk, raw = pcall(readfile, fullPath)
            if not readOk then
                return false, 'failed to read existing config'
            end
            previous = raw
            local decodeOk, oldData = pcall(httpService.JSONDecode, httpService, raw)
            if decodeOk and type(oldData) == 'table' and type(oldData.objects) == 'table' then
                local backupOk, backupError = pcall(writefile, fullPath .. '.bak', raw)
                if not backupOk then
                    return false, 'backup failed: ' .. tostring(backupError)
                end
            end
        end

        local ok, err = pcall(writefile, fullPath, encoded)
        if not ok then
            if previous then
                local restored = pcall(writefile, fullPath, previous)
                if not restored then
                    return false, 'write failed; restore the .json.bak file before saving again'
                end
            end
            return false, 'writefile failed: ' .. tostring(err)
        end
        self.LastSavedAt, self.CurrentConfig = os.time(), clean
        self:SetBaseline(data)
        self:RefreshDirtyState()
        self:UpdateStatus()
        return true
    end

    function SaveManager:Load(name, fromBackup, categories)
        local clean = NormalizeConfigName(name)
        if not clean then
            return false, 'no config file is selected'
        end

        local file = self.Folder .. '/settings/' .. clean .. '.json'
        if fromBackup then
            file ..= '.bak'
        end
        local existsOk, exists = pcall(isfile, file)
        if not existsOk or not exists then
            return false, 'invalid file'
        end

        local readOk, raw = pcall(readfile, file)
        if not readOk then
            return false, 'read error'
        end
        local success, decoded = pcall(httpService.JSONDecode, httpService, raw)
        if not success then
            return false, 'decode error'
        end
        if type(decoded) ~= 'table' or type(decoded.objects) ~= 'table' then
            return false, 'decode error'
        end
        local migrated, migrationError = self:Migrate(decoded)
        if not migrated then
            return false, migrationError
        end
        decoded = migrated

        local applied, problem = self:ApplyConfig(decoded, clean, categories)
        if applied and fromBackup then
            self.DirtyReasons.backup = true
            self:RefreshDirtyFlag()
        end
        return applied, problem
    end
    function SaveManager:ApplyConfig(decoded, name, categories)
        if self.Loading then
            return false, 'a config is already loading'
        end
        if type(decoded) ~= 'table' or type(decoded.objects) ~= 'table' then
            return false, 'invalid config data'
        end
        if categories ~= nil and type(categories) ~= 'table' then
            return false, 'invalid config categories'
        end
        local prepared = table.clone(decoded)
        prepared.objects = {}
        for _, option in pairs(decoded.objects) do
            if type(option) ~= 'table' then
                return false, 'invalid config entry'
            end
            prepared.objects[#prepared.objects + 1] = table.clone(option)
        end
        local lib = self.Library or (getgenv and getgenv().Library) or Library
        local saved = lib
            and {
                SafeCallback = lib.SafeCallback,
                UpdateDependencyBoxes = lib.UpdateDependencyBoxes,
                SuppressSave = lib.SuppressSave,
                ConfigLoading = lib.ConfigLoading,
                CallbackErrorSink = lib.CallbackErrorSink,
            }
        if lib then
            lib.CallbackErrorSink = function(problem)
                local report = self.LastLoadReport
                if report then
                    report.Failed += 1
                    report.Details[#report.Details + 1] = 'callback: ' .. tostring(problem)
                end
            end
        end
        local result = table.pack(pcall(self.ApplyConfigValues, self, prepared, name, categories))
        if lib then
            lib.SafeCallback = saved.SafeCallback
            lib.UpdateDependencyBoxes = saved.UpdateDependencyBoxes
            lib.SuppressSave = saved.SuppressSave
            lib.ConfigLoading = saved.ConfigLoading
            if not result[1] and lib.AfterConfigLoad then
                pcall(lib.AfterConfigLoad, true)
            end
            lib.CallbackErrorSink = saved.CallbackErrorSink
        end
        self.Loading = false
        if not result[1] then
            local report = self.LastLoadReport
            if report then
                report.Failed += 1
                report.Details[#report.Details + 1] = tostring(result[2])
            end
            return false, tostring(result[2])
        end
        return table.unpack(result, 2, result.n)
    end
    function SaveManager:ApplyConfigValues(decoded, name, categories)
        if self.Loading then
            return false, 'a config is already loading'
        end
        local lib = self.Library or (getgenv and getgenv().Library) or Library
        if lib and lib.Unloaded then
            return false, 'the library is unloaded'
        end
        self.Loading = true
        local prevSuppress = lib and lib.SuppressSave
        local prevLoading = lib and lib.ConfigLoading
        local safeCallback = lib and lib.SafeCallback
        local updateDependencies = lib and lib.UpdateDependencyBoxes
        local callbacks, errors, callbackEntries = {}, {}, {}
        local report = { Loaded = 0, Missing = 0, Ignored = 0, Skipped = 0, Failed = 0, Details = {} }
        self.LastLoadReport = report
        local function runHook(label, callback, ...)
            if not callback then
                return true
            end
            local ok, problem = pcall(callback, ...)
            if not ok then
                report.Failed += 1
                report.Details[#report.Details + 1] = label .. ': ' .. tostring(problem)
                errors[#errors + 1] = label .. ': ' .. tostring(problem)
            end
            return ok
        end
        if lib then
            lib.SuppressSave = true
            lib.ConfigLoading = true
            if safeCallback then
                lib.SafeCallback = function(_, callback, ...)
                    if callback then
                        local entry = callbackEntries[callback]
                        if entry then
                            entry.Arguments = table.pack(...)
                        else
                            entry = { Callback = callback, Arguments = table.pack(...) }
                            callbackEntries[callback] = entry
                            callbacks[#callbacks + 1] = entry
                        end
                    end
                end
            end
            if updateDependencies then
                lib.UpdateDependencyBoxes = function() end
            end
        end
        if lib and not runHook('before config', lib.BeforeConfigLoad, decoded, categories) then
            error('before config hook failed', 0)
        end
        local controls, applied = getControls(), {}
        local function reject(kind, idx, reason)
            report[kind] += 1
            report.Details[#report.Details + 1] = tostring(idx) .. ': ' .. reason
        end
        if decoded.states ~= nil and type(decoded.states) ~= 'table' then
            reject('Failed', 'states', 'invalid persistent states')
        else
            for idx, value in pairs(decoded.states or {}) do
                local state = self.States[idx]
                if type(idx) ~= 'string' or not state then
                    reject('Missing', idx, 'persistent state does not exist')
                elseif self.Ignore[idx] then
                    reject('Ignored', idx, 'excluded from persistence')
                elseif
                    categories
                    and next(categories)
                    and not categories[state.Category]
                    and not table.find(categories, state.Category)
                then
                    reject('Skipped', idx, 'category not selected')
                else
                    local ok, result, problem = pcall(state.Apply, value)
                    if ok and result ~= false then
                        report.Loaded += 1
                    else
                        reject('Failed', idx, tostring(ok and problem or result))
                    end
                end
            end
        end
        local function allowed(option)
            local idx = option.idx
            if type(idx) ~= 'string' or not self.Parser[option.type] then
                reject('Failed', idx, 'unsupported or invalid entry')
                return false
            end
            if self.Ignore[idx] then
                reject('Ignored', idx, 'excluded from persistence')
                return false
            end
            local control = controls[idx]
            if not control then
                reject('Missing', idx, 'control does not exist')
                return false
            end
            if control.Type and control.Type ~= option.type then
                reject('Failed', idx, 'control type mismatch')
                return false
            end
            local category = self:GetCategory(idx)
            if
                categories
                and next(categories)
                and not categories[category]
                and not table.find(categories, category)
            then
                reject('Skipped', idx, 'category not selected')
                return false
            end
            if
                option.type == 'Slider'
                and (
                    not tonumber(option.value)
                    or tonumber(option.value) ~= tonumber(option.value)
                    or math.abs(tonumber(option.value)) == math.huge
                )
            then
                reject('Failed', idx, 'invalid numeric value')
                return false
            end
            if
                option.type == 'ColorPicker'
                and (type(option.value) ~= 'string' or not option.value:match('^%x%x%x%x%x%x$'))
            then
                reject('Failed', idx, 'invalid color')
                return false
            end
            if option.type == 'ColorPicker' then
                local alpha, speed = option.transparency, option.chromaSpeed
                if alpha ~= nil and (type(alpha) ~= 'number' or alpha ~= alpha or alpha < 0 or alpha > 1) then
                    reject('Failed', idx, 'invalid transparency')
                    return false
                end
                if speed ~= nil and (type(speed) ~= 'number' or speed ~= speed or speed < 1 or speed > 5) then
                    reject('Failed', idx, 'invalid chroma speed')
                    return false
                end
                if option.rgb ~= nil and type(option.rgb) ~= 'boolean' then
                    reject('Failed', idx, 'invalid chroma state')
                    return false
                end
            end
            if
                option.type == 'KeyPicker'
                and (
                    type(option.key) ~= 'string'
                    or not table.find({ 'Always', 'Toggle', 'Hold' }, option.mode or 'Toggle')
                )
            then
                reject('Failed', idx, 'invalid keybind')
                return false
            end
            if option.type == 'Input' and type(option.text) ~= 'string' then
                reject('Failed', idx, 'invalid text')
                return false
            end
            if applied[idx] then
                reject('Skipped', idx, 'duplicate control entry')
                return false
            end
            applied[idx] = true
            return true
        end
        local toggles, keypickers, others, protection = {}, {}, {}, {}
        local protectionMaster = nil
        for _, option in next, decoded.objects do
            if type(option) == 'table' and allowed(option) then
                if option.idx == 'shield_enable' then
                    protectionMaster = option
                elseif option.idx:sub(1, 7) == 'shield_' then
                    table.insert(protection, option)
                elseif option.type == 'Toggle' then
                    table.insert(toggles, option)
                elseif option.type == 'KeyPicker' then
                    table.insert(keypickers, option)
                else
                    table.insert(others, option)
                end
            end
        end
        local function apply(option)
            if lib and lib.Unloaded then
                return
            end
            local ok, err = pcall(self.Parser[option.type].Load, option.idx, option)
            if not ok then
                errors[#errors + 1] = option.idx .. ': ' .. tostring(err)
                reject('Failed', option.idx, tostring(err))
            else
                report.Loaded += 1
            end
        end
        for _, option in ipairs(protection) do
            apply(option)
        end
        if protectionMaster then
            apply(protectionMaster)
        end
        local protectionCallbacks = #callbacks
        for _, group in ipairs({ others, keypickers, toggles }) do
            for _, option in ipairs(group) do
                apply(option)
            end
        end
        if lib then
            lib.SafeCallback = safeCallback
            lib.UpdateDependencyBoxes = updateDependencies
        end
        if lib and lib.Unloaded then
            lib.SuppressSave, lib.ConfigLoading = prevSuppress or false, prevLoading or false
            self.Loading = false
            return false, 'config loading cancelled'
        end
        local function dispatch(entry)
            if lib and lib.Unloaded then
                return
            end
            local ok, err = pcall(entry.Callback, table.unpack(entry.Arguments, 1, entry.Arguments.n))
            if not ok then
                report.Failed += 1
                report.Details[#report.Details + 1] = 'callback: ' .. tostring(err)
                errors[#errors + 1] = tostring(err)
                warn('[phowg] config callback: ' .. tostring(err))
            end
        end
        for index = 1, protectionCallbacks do
            dispatch(callbacks[index])
        end
        if lib then
            runHook('protection config', lib.AfterProtectionConfigLoad)
        end
        for index = protectionCallbacks + 1, #callbacks do
            dispatch(callbacks[index])
        end
        if updateDependencies then
            runHook('dependencies', updateDependencies, lib)
        end
        if lib then
            lib.SuppressSave = prevSuppress or false
            lib.ConfigLoading = prevLoading or false
            runHook('after config', lib.AfterConfigLoad)
            if lib.FlushDeferredLayouts then
                lib:FlushDeferredLayouts(true)
            end
            if lib.RefreshVisiblePlayerDropdowns then
                lib:RefreshVisiblePlayerDropdowns()
            end
        end
        self.Loading = false
        if report.Failed == 0 then
            self.CurrentConfig = name or self.CurrentConfig
        end
        if not (categories and next(categories)) and report.Failed == 0 and report.Missing == 0 then
            self:SetBaseline()
        else
            self.DirtyReasons.load = report.Failed > 0
                or report.Missing > 0
                or (categories and next(categories) ~= nil)
                or nil
            self:RefreshDirtyState()
        end
        self:UpdateStatus()
        if #errors > 0 then
            return false, 'failed to load ' .. table.concat(errors, '; ')
        end
        if report.Failed > 0 then
            return false, tostring(report.Failed) .. ' invalid config entries; see load report'
        end

        return true
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            'BackgroundColor',
            'MainColor',
            'AccentColor',
            'OutlineColor',
            'FontColor',
            'ThemeManager_ThemeList',
            'ThemeManager_CustomThemeList',
            'ThemeManager_CustomThemeName',
        })
    end

    function SaveManager:BuildFolderTree()
        local parts = split(self.Folder, '/')
        local paths = {}
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, '/', 1, idx)
        end
        table.insert(paths, self.Folder .. '/themes')
        table.insert(paths, self.Folder .. '/settings')

        for i = 1, #paths do
            local str = paths[i]
            local ok, isDir = pcall(isfolder, str)
            if ok and not isDir then
                pcall(makefolder, str)
            elseif not ok then
                pcall(makefolder, str)
            end
        end
    end

    function SaveManager:RefreshConfigList()
        local ok, list = pcall(listfiles, self.Folder .. '/settings')
        if not ok or type(list) ~= 'table' then
            return {}
        end
        local values, seen = {}, {}
        for _, file in ipairs(list) do
            if type(file) == 'string' and file:sub(-5):lower() == '.json' then
                local basename = file:gsub('\\', '/'):match('([^/]+)$')
                local name = basename and NormalizeConfigName(basename:sub(1, -6))
                if name and not seen[name] then
                    seen[name] = true
                    values[#values + 1] = name
                end
            end
        end
        table.sort(values, function(a, b)
            return a:lower() == b:lower() and a < b or a:lower() < b:lower()
        end)
        return values
    end

    function SaveManager:SetLibrary(library)
        self.Library = library
        library.SaveManager = self
        for idx, control in pairs(getControls()) do
            self:ObserveControl(idx, control)
        end
        for idx in pairs(self.States) do
            self:ObserveState(idx)
        end
        self:SetBaseline()
        if getgenv then
            pcall(function()
                getgenv().SaveManager = self
            end)
        end
        if _G then
            pcall(function()
                _G.SaveManager = self
            end)
        end
    end

    function SaveManager:RemoveAutoload()
        local path = self.Folder .. '/settings/autoload.txt'
        local exists, present = pcall(isfile, path)
        if not exists then
            return false, tostring(present)
        end
        if present then
            local removed = false
            if type(delfile) == 'function' then
                local ok = pcall(delfile, path)
                local checked, remains = pcall(isfile, path)
                removed = ok and checked and not remains
            end
            if not removed then
                local ok, err = pcall(writefile, path, '')
                if not ok then
                    return false, tostring(err)
                end
            end
        end
        if self.AutoloadLabel then
            self.AutoloadLabel:SetText('Current autoload config: none')
        end
        return true
    end

    function SaveManager:LoadAutoloadConfig(blocking)
        local function load()
            local okFile, isFile = pcall(isfile, self.Folder .. '/settings/autoload.txt')
            if not okFile or not isFile then
                return
            end
            local okRead, name = pcall(readfile, self.Folder .. '/settings/autoload.txt')
            if not okRead then
                return
            end
            local clean = NormalizeConfigName(name)
            if not clean then
                return
            end

            for _ = 1, 50 do
                local t = getToggles()
                local o = getOptions()
                if (t and next(t) ~= nil) or (o and next(o) ~= nil) then
                    break
                end
                task.wait(0.1)
            end

            local success, err = self:Load(clean)
            if not success then
                if self.Library then
                    self.Library:Notify('Failed to load autoload config: ' .. tostring(err))
                end
                return
            end
            if self.Library then
                self.Library:Notify(string.format('Auto loaded config %q', clean))
            end
        end
        if blocking then
            return load()
        end
        return task.spawn(load)
    end

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, 'Must set SaveManager.Library')

        local section = tab:AddLeftGroupbox('configs')

        section:AddSearchDropdown(
            'SaveManager_ConfigList',
            { Text = 'configs', Values = self:RefreshConfigList(), AllowNull = true }
        )
        section:AddInput('SaveManager_ConfigName', { Text = 'config name' })

        section:AddDivider()

        section
            :AddButton('create', function()
                local opts = getOptions()
                local name = (opts.SaveManager_ConfigName and opts.SaveManager_ConfigName.Value)
                    or (Options and Options.SaveManager_ConfigName and Options.SaveManager_ConfigName.Value)
                local clean = NormalizeConfigName(name)

                if not clean then
                    return self.Library:Notify('Invalid config name (empty)', 2)
                end

                local success, err = self:Save(clean)
                if not success then
                    return self.Library:Notify('Failed to save config: ' .. tostring(err))
                end

                self.Library:Notify(string.format('Created config %q', clean))

                if opts.SaveManager_ConfigList then
                    opts.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                    opts.SaveManager_ConfigList:SetValue(nil)
                elseif Options and Options.SaveManager_ConfigList then
                    Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                    Options.SaveManager_ConfigList:SetValue(nil)
                end
                return nil
            end)
            :AddButton('load', function()
                local opts = getOptions()
                local name = (opts.SaveManager_ConfigList and opts.SaveManager_ConfigList.Value)
                    or (Options and Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value)

                local selected = opts.SaveManager_Categories and opts.SaveManager_Categories.Value
                local success, err = self:Load(name, false, selected)
                if not success then
                    return self.Library:Notify('Failed to load config: ' .. tostring(err))
                end

                self.Library:Notify(string.format('Loaded config %q', tostring(name)))
                return nil
            end)

        section
            :AddButton('save', function()
                local opts = getOptions()
                local name = (opts.SaveManager_ConfigList and opts.SaveManager_ConfigList.Value)
                    or (Options and Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value)

                local success, err = self:Save(name)
                if not success then
                    return self.Library:Notify('Failed to overwrite config: ' .. tostring(err))
                end

                self.Library:Notify(string.format('Overwrote config %q', tostring(name)))
                return nil
            end)
            :AddButton('refresh', function()
                local opts = getOptions()
                local target = (opts and opts.SaveManager_ConfigList) or (Options and Options.SaveManager_ConfigList)
                if target then
                    target:SetValues(self:RefreshConfigList())
                    target:SetValue(nil)
                end
            end)
        section:AddButton('restore previous save', function()
            local opts = getOptions()
            local name = (opts.SaveManager_ConfigList and opts.SaveManager_ConfigList.Value)
                or (Options and Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value)
            local success, err = self:Load(name, true)
            if not success then
                self.Library:Notify('Failed to load backup: ' .. tostring(err))
                return
            end
            self.Library:Notify('Loaded previous save. Use Overwrite config to keep it.')
        end)

        section
            :AddButton('set autoload', function()
                local opts = getOptions()
                local name = (opts.SaveManager_ConfigList and opts.SaveManager_ConfigList.Value)
                    or (Options and Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value)
                local clean = NormalizeConfigName(name)
                if not clean then
                    return self.Library:Notify('Select a config first', 2)
                end
                local wrote, problem = pcall(writefile, self.Folder .. '/settings/autoload.txt', clean)
                if not wrote then
                    return self.Library:Notify('Failed to set autoload: ' .. tostring(problem))
                end
                if SaveManager.AutoloadLabel then
                    SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. clean)
                end
                self.Library:Notify(string.format('Set %q to auto load', clean))
                return nil
            end)
            :AddButton('clear autoload', function()
                local ok, err = self:RemoveAutoload()
                self.Library:Notify(ok and 'Autoload removed' or 'Failed to remove autoload: ' .. tostring(err), 3)
            end)

        self.StatusLabel = section:AddLabel(self:GetStatusText(false), true)
        self.StatusText = nil
        section:AddToggle('SaveManager_Advanced', { Text = 'advanced options', Default = false })
        local tools = section:AddSettingsBox(self.Library.Toggles.SaveManager_Advanced)
        tools:AddDropdown('SaveManager_Categories', {
            Text = 'load categories (empty = all)',
            Values = { 'visuals', 'movement', 'protection', 'interface', 'other' },
            Multi = true,
            AllowNull = true,
        })
        tools:AddInput('SaveManager_ImportText', { Text = 'import json', Finished = true })
        self.DetailLabel = tools:AddLabel('', true)
        tools
            :AddButton('compare', function()
                local opts = getOptions()
                local changes, err = self:Compare(opts.SaveManager_ConfigList.Value)
                self.DetailLabel:SetText(
                    changes and (#changes .. ' differences\n' .. table.concat(changes, '\n')) or tostring(err)
                )
            end)
            :AddButton('load report', function()
                self.DetailLabel:SetText(
                    self.LastLoadReport and table.concat(self.LastLoadReport.Details, '\n') or 'No config loaded yet'
                )
            end)
        tools
            :AddButton('export', function()
                local raw, err = self:Export(getOptions().SaveManager_ConfigList.Value)
                if raw and setclipboard then
                    local ok = pcall(setclipboard, raw)
                    self.Library:Notify(ok and 'Config copied' or 'Clipboard unavailable')
                else
                    self.Library:Notify(err or 'Clipboard unavailable')
                end
            end)
            :AddButton('import', function()
                local opts = getOptions()
                local ok, err = self:Import(opts.SaveManager_ConfigName.Value, opts.SaveManager_ImportText.Value)
                self.Library:Notify(ok and 'Config imported' or tostring(err))
                if ok then
                    opts.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                end
            end)
        tools
            :AddButton('rename', function()
                local opts = getOptions()
                local ok, err = self:Rename(opts.SaveManager_ConfigList.Value, opts.SaveManager_ConfigName.Value)
                self.Library:Notify(ok and 'Config renamed' or tostring(err))
                if ok then
                    opts.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                    opts.SaveManager_ConfigList:SetValue(nil)
                end
            end)
            :AddButton('check persistence', function()
                local ok, count, failures = self:CheckPersistence()
                self.DetailLabel:SetText(
                    ok and (count .. ' controls serialize correctly') or table.concat(failures, '\n')
                )
            end)
        self:SetIgnoreIndexes({ 'SaveManager_Categories', 'SaveManager_ImportText' })
        self:UpdateStatus()

        SaveManager.AutoloadLabel = section:AddLabel('current autoload config: none', true)

        local okFile, isFile = pcall(isfile, self.Folder .. '/settings/autoload.txt')
        if okFile and isFile then
            local okRead, name = pcall(readfile, self.Folder .. '/settings/autoload.txt')
            if okRead then
                local clean = NormalizeConfigName(name)
                if clean then
                    SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. clean)
                end
            end
        end

        SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
    end

    for _, kind in ipairs({ 'Save', 'Load', 'Import', 'Rename', 'RemoveAutoload' }) do
        local original = SaveManager[kind]
        SaveManager[kind] = function(self, ...)
            local results = table.pack(original(self, ...))
            self.LastAction =
                { Kind = kind:lower(), Success = results[1] == true, Message = results[2], At = os.time() }
            self:UpdateStatus()
            return table.unpack(results, 1, results.n)
        end
    end

    SaveManager:BuildFolderTree()
end

return SaveManager
