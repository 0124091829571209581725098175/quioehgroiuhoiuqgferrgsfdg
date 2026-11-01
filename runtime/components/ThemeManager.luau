local httpService = game:GetService('HttpService')
local ThemeManager = {}
do
    ThemeManager.PhowgRevision = 3
    ThemeManager.Folder = 'LinoriaLibSettings'
    ThemeManager.Library = nil
    ThemeManager.BuiltInThemes = {
        ['Default'] = {
            1,
            httpService:JSONDecode(
                '{"FontColor":"d7d7d7","MainColor":"181818","AccentColor":"f2f2f2","BackgroundColor":"0c0c0c","OutlineColor":"393939"}'
            ),
        },
        ['BBot'] = {
            2,
            httpService:JSONDecode(
                '{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}'
            ),
        },
        ['Fatality'] = {
            3,
            httpService:JSONDecode(
                '{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}'
            ),
        },
        ['Jester'] = {
            4,
            httpService:JSONDecode(
                '{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}'
            ),
        },
        ['Mint'] = {
            5,
            httpService:JSONDecode(
                '{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}'
            ),
        },
        ['Tokyo Night'] = {
            6,
            httpService:JSONDecode(
                '{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}'
            ),
        },
        ['Ubuntu'] = {
            7,
            httpService:JSONDecode(
                '{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}'
            ),
        },
        ['Quartz'] = {
            8,
            httpService:JSONDecode(
                '{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}'
            ),
        },
        ['Dracula'] = {
            9,
            httpService:JSONDecode(
                '{"FontColor":"f8f8f2","MainColor":"282a36","AccentColor":"bd93f9","BackgroundColor":"1e1f29","OutlineColor":"44475a"}'
            ),
        },
        ['Nord'] = {
            10,
            httpService:JSONDecode(
                '{"FontColor":"eceff4","MainColor":"2e3440","AccentColor":"88c0d0","BackgroundColor":"242933","OutlineColor":"3b4252"}'
            ),
        },
        ['Obsidian'] = {
            11,
            httpService:JSONDecode(
                '{"FontColor":"e0e0e0","MainColor":"0f0f0f","AccentColor":"ff3b30","BackgroundColor":"0a0a0a","OutlineColor":"2a2a2a"}'
            ),
        },
        ['Cyberpunk'] = {
            12,
            httpService:JSONDecode(
                '{"FontColor":"00ffcc","MainColor":"0a0e1a","AccentColor":"ff006e","BackgroundColor":"050810","OutlineColor":"1a2332"}'
            ),
        },
        ['Rose'] = {
            13,
            httpService:JSONDecode(
                '{"FontColor":"fff0f3","MainColor":"2b1a1e","AccentColor":"ff4d6d","BackgroundColor":"1f1215","OutlineColor":"4a2c32"}'
            ),
        },
        ['Ocean'] = {
            14,
            httpService:JSONDecode(
                '{"FontColor":"caf0f8","MainColor":"0a1628","AccentColor":"00b4d8","BackgroundColor":"061020","OutlineColor":"1e3a5f"}'
            ),
        },
        ['Forest'] = {
            15,
            httpService:JSONDecode(
                '{"FontColor":"d8f3dc","MainColor":"1a2e1a","AccentColor":"52b788","BackgroundColor":"122212","OutlineColor":"2d4a22"}'
            ),
        },
        ['Sunset'] = {
            16,
            httpService:JSONDecode(
                '{"FontColor":"fff3b0","MainColor":"2b1a0e","AccentColor":"ff7b00","BackgroundColor":"1f1208","OutlineColor":"5a2d0c"}'
            ),
        },
        ['Amoled'] = {
            17,
            httpService:JSONDecode(
                '{"FontColor":"ffffff","MainColor":"000000","AccentColor":"ffffff","BackgroundColor":"000000","OutlineColor":"1a1a1a"}'
            ),
        },
        ['Blood'] = {
            18,
            httpService:JSONDecode(
                '{"FontColor":"ffcccc","MainColor":"1a0000","AccentColor":"cc0000","BackgroundColor":"0d0000","OutlineColor":"4d0000"}'
            ),
        },
        ['Grape'] = {
            19,
            httpService:JSONDecode(
                '{"FontColor":"e0aaff","MainColor":"1a0a2e","AccentColor":"9d4edd","BackgroundColor":"12091f","OutlineColor":"3c096c"}'
            ),
        },
        ['Aqua'] = {
            20,
            httpService:JSONDecode(
                '{"FontColor":"e0ffff","MainColor":"0a1f1f","AccentColor":"00ced1","BackgroundColor":"061414","OutlineColor":"1a4a4a"}'
            ),
        },
        ['Crimson'] = {
            21,
            httpService:JSONDecode(
                '{"FontColor":"ffe4e6","MainColor":"1f0a0a","AccentColor":"dc143c","BackgroundColor":"150808","OutlineColor":"4a1a1a"}'
            ),
        },
        ['Midnight'] = {
            22,
            httpService:JSONDecode(
                '{"FontColor":"c9d1d9","MainColor":"0d1117","AccentColor":"58a6ff","BackgroundColor":"010409","OutlineColor":"21262d"}'
            ),
        },
        ['Void'] = {
            23,
            httpService:JSONDecode(
                '{"FontColor":"a0a0b0","MainColor":"0f0f14","AccentColor":"7c3aed","BackgroundColor":"0a0a0f","OutlineColor":"1f1f2e"}'
            ),
        },
        ['Pastel'] = {
            24,
            httpService:JSONDecode(
                '{"FontColor":"2b2d42","MainColor":"edf2f4","AccentColor":"ef476f","BackgroundColor":"e9ecef","OutlineColor":"adb5bd"}'
            ),
        },
    }
    function ThemeManager:ApplyTheme(theme)
        if type(theme) ~= 'string' or theme == '' then
            return false
        end
        local customThemeData = self:GetCustomTheme(theme)
        local data = customThemeData or self.BuiltInThemes[theme]
        if not data then
            return
        end
        local scheme = data[2]
        local source = customThemeData or scheme
        self.ApplyingTheme = true
        local ok, problem = pcall(function()
            for idx, col in next, source do
                local c = Color3.fromHex(col)
                self.Library[idx] = c
                if Options and Options[idx] then
                    Options[idx]:SetValueRGB(c)
                end
            end
        end)
        self.ApplyingTheme = nil
        if not ok then
            error(problem, 0)
        end
        self:ThemeUpdate()
    end
    function ThemeManager:ThemeUpdate()
        if self.ApplyingTheme then
            return
        end
        local scheme, changed = {}, self.LastAppliedScheme == nil
        for _, field in ipairs({ 'FontColor', 'MainColor', 'AccentColor', 'BackgroundColor', 'OutlineColor' }) do
            local value = Options and Options[field] and Options[field].Value or self.Library[field]
            scheme[field] = value
            if self.LastAppliedScheme and self.LastAppliedScheme[field] ~= value then
                changed = true
            end
        end
        if not changed then
            return
        end
        self.LastAppliedScheme = scheme
        local options = { 'FontColor', 'MainColor', 'AccentColor', 'BackgroundColor', 'OutlineColor' }
        for _, field in next, options do
            if Options and Options[field] then
                self.Library[field] = Options[field].Value
            end
        end
        self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
        self.Library:UpdateColorsUsingRegistry()
    end
    function ThemeManager:LoadDefault()
        local theme = 'Default'
        local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')
        if type(content) == 'string' then
            content = content:gsub('%s+', '')
        end
        local isDefault = true
        if content then
            if self.BuiltInThemes[content] then
                theme = content
            elseif self:GetCustomTheme(content) then
                theme = content
                isDefault = false
            end
        elseif self.BuiltInThemes[self.DefaultTheme] then
            theme = self.DefaultTheme
        end
        if isDefault then
            if Options and Options.ThemeManager_ThemeList then
                Options.ThemeManager_ThemeList:SetValue(theme)
            else
                self:ApplyTheme(theme)
            end
        else
            self:ApplyTheme(theme)
        end
    end
    function ThemeManager:SaveDefault(theme)
        if type(theme) ~= 'string' or theme == '' then
            return false
        end
        writefile(self.Folder .. '/themes/default.txt', theme)
        return true
    end
    function ThemeManager:CreateThemeManager(groupbox)
        groupbox
            :AddLabel('background color')
            :AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor, ThemeColor = true })
        groupbox:AddLabel('main color'):AddColorPicker('MainColor', { Default = self.Library.MainColor, ThemeColor = true })
        groupbox:AddLabel('accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor, ThemeColor = true })
        groupbox:AddLabel('outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor, ThemeColor = true })
        groupbox:AddLabel('font color'):AddColorPicker('FontColor', { Default = self.Library.FontColor, ThemeColor = true })
        local ThemesArray = {}
        for Name, _ in next, self.BuiltInThemes do
            table.insert(ThemesArray, Name)
        end
        table.sort(ThemesArray, function(a, b)
            return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1]
        end)
        groupbox:AddDivider()
        groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'theme list', Values = ThemesArray, Default = 1 })
        groupbox:AddButton('Set as default', function()
            local theme = Options.ThemeManager_ThemeList.Value
            if self:SaveDefault(theme) then
                self.Library:Notify(string.format('Set default theme to %q', theme))
            end
        end)
        Options.ThemeManager_ThemeList:OnChanged(function()
            self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
        end)
        groupbox:AddDivider()
        groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'custom theme name' })
        groupbox:AddDropdown(
            'ThemeManager_CustomThemeList',
            { Text = 'custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 }
        )
        groupbox:AddDivider()
        groupbox
            :AddButton('Save theme', function()
                self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)
                Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                Options.ThemeManager_CustomThemeList:SetValue(nil)
            end)
            :AddButton('Load theme', function()
                self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value)
            end)
        groupbox:AddButton('Refresh list', function()
            Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        groupbox:AddButton('Set as default', function()
            if
                Options.ThemeManager_CustomThemeList.Value ~= nil
                and Options.ThemeManager_CustomThemeList.Value ~= ''
            then
                self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
                self.Library:Notify(
                    string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value)
                )
            end
        end)
        ThemeManager:LoadDefault()
        local function UpdateTheme()
            self:ThemeUpdate()
        end
        if Options.BackgroundColor then
            Options.BackgroundColor:OnChanged(UpdateTheme)
        end
        if Options.MainColor then
            Options.MainColor:OnChanged(UpdateTheme)
        end
        if Options.AccentColor then
            Options.AccentColor:OnChanged(UpdateTheme)
        end
        if Options.OutlineColor then
            Options.OutlineColor:OnChanged(UpdateTheme)
        end
        if Options.FontColor then
            Options.FontColor:OnChanged(UpdateTheme)
        end
    end
    function ThemeManager:GetCustomTheme(file)
        if type(file) ~= 'string' or file == '' then
            return nil
        end
        local path = self.Folder .. '/themes/' .. file
        if not isfile(path) then
            return nil
        end
        local data = readfile(path)
        local success, decoded = pcall(httpService.JSONDecode, httpService, data)
        if not success then
            return nil
        end
        if decoded.FontColor and decoded.MainColor then
            return decoded
        end
        if decoded[2] then
            return decoded[2]
        end
        return decoded
    end
    function ThemeManager:SaveCustomTheme(file)
        if file:gsub(' ', '') == '' then
            return self.Library:Notify('Invalid file name for theme (empty)', 3)
        end
        local theme = {}
        local fields = { 'FontColor', 'MainColor', 'AccentColor', 'BackgroundColor', 'OutlineColor' }
        for _, field in next, fields do
            theme[field] = Options[field].Value:ToHex()
        end
        writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
        return true
    end
    function ThemeManager:ReloadCustomThemes()
        local list = listfiles(self.Folder .. '/themes')
        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == '.json' then
                local pos = file:find('.json', 1, true)
                local char = file:sub(pos, pos)
                while char ~= '/' and char ~= '\\' and char ~= '' do
                    pos = pos - 1
                    char = file:sub(pos, pos)
                end
                if char == '/' or char == '\\' then
                    table.insert(out, file:sub(pos + 1))
                end
            end
        end
        return out
    end
    function ThemeManager:SetLibrary(lib)
        self.Library = lib
        lib.ThemeManager = self
    end
    function ThemeManager:BuildFolderTree()
        local paths = {}
        local parts = self.Folder:split('/')
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, '/', 1, idx)
        end
        table.insert(paths, self.Folder .. '/themes')
        table.insert(paths, self.Folder .. '/settings')
        for i = 1, #paths do
            local str = paths[i]
            if not isfolder(str) then
                makefolder(str)
            end
        end
    end
    function ThemeManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end
    function ThemeManager:CreateGroupBox(tab)
        assert(self.Library, 'Must set ThemeManager.Library first!')
        return tab:AddRightGroupbox('Settings')
    end
    function ThemeManager:ApplyToTab(tab)
        assert(self.Library, 'Must set ThemeManager.Library first!')
        local groupbox = self:CreateGroupBox(tab)
        self:CreateThemeManager(groupbox)
    end
    function ThemeManager:ApplyToGroupbox(groupbox)
        assert(self.Library, 'Must set ThemeManager.Library first!')
        self:CreateThemeManager(groupbox)
    end
    ThemeManager:BuildFolderTree()
end
return ThemeManager
