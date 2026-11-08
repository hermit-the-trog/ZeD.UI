-- ZeDUI/tools/qa/menus_b7_sim.lua  (Nov 7 2026, Build): three menu findings from the outside review of beta 7, with no
-- game running. The real ZeD_MainMenuSandbox.lua, ZeD_MainMenuTraits.lua, ZeD_MainMenuLooks.lua, ZeD_Keyboard.lua and
-- ZeD_MainMenuOptionGroups.lua run on Lua 5.1 against stubs of the game's sandbox screen, text fields and options.
--   * #4 deleting the active custom sandbox preset: the header's base is the preset the values sit closest to
--     (Apocalypse + 1 change saved and deleted read "Six Months Later, 36 changed": vanilla's reload lands on the last)
--   * #5 a name question opens with its default selected, so typing replaces it (Sandbox Save as preset, Traits Save
--     build, Looks Save preset), and the controller's keyboard selects it again when it opens on the untouched default
--   * #6 Options > Find shows ZeD's own options from ZeD setup (ZeD's controls), not the Mods page's drop-downs
-- What it can't show: the selection drawn in the field, the radio rows on screen (in the game).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/menus_b7_sim.lua
-- It prints FAIL lines and a last line "menus_b7_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]menus_b7_sim%.lua$", "")
local ZDIR = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function load(name)
    local f, err = loadfile(ZDIR .. name)
    if not f then print("menus_b7_sim: " .. tostring(err)); os.exit(1) end
    f()
end

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
require = noop
getText = function(k) return k end
getTextOrNull = function(k) return k end
Keyboard = { KEY_RETURN = 28, KEY_TAB = 15, KEY_ESCAPE = 1, KEY_BACK = 14, KEY_LEFT = 203, KEY_RIGHT = 205,
             KEY_UP = 200, KEY_DOWN = 208, isKeyDown = function() return false end }
local function derive(base)
    return function(self, name)
        local c = setmetatable({}, { __index = self })
        c.__index = c
        c.Type = name
        return c
    end
end
ZeD_MMOptions = { derive = derive() }
ZeD_MMWindow = { derive = derive(), new = function(cls) return setmetatable({}, cls) end }
ZeD_Window = { derive = derive(), new = function(cls) return setmetatable({}, cls) end }
local MM = { U = {}, ui = { plain = function(s) return s end }, ctx = {}, now = function() return 0 end,
             clickSound = noop, addView = noop, gamepad = function() return false end }
ZeD = {
    MainMenu = MM,
    tr = function(k, ...) local p = { k } for _, v in ipairs({ ... }) do p[#p + 1] = tostring(v) end return table.concat(p, "|") end,
    btnCase = function(s) return s end,
    T = { px = function(v) return v end },
}

-- a text field as the game's ISTextEntryBox behaves here: setText puts the caret at the end with nothing selected;
-- selectAll selects the whole text
local function newField(text)
    local f = { text = text or "", sel = false, focused = false, visible = false, javaObject = {} }
    function f:setText(t) self.text = tostring(t or ""); self.sel = false end
    function f:getText() return self.text end
    function f:getInternalText() return self.text end
    function f:selectAll() self.sel = true end
    function f:focus() self.focused = true end
    function f:unfocus() self.focused = false end
    function f:isFocused() return self.focused end
    function f:setVisible(v) self.visible = v end
    function f:isMasked() return false end
    function f:isMultipleLine() return false end
    -- a key typed: replaces the selection, or goes on at the caret (the end)
    function f:type(s) if self.sel then self.text = s else self.text = self.text .. s end; self.sel = false end
    return f
end

-- SandboxOptions: a set of named options with string values
local function newOpts(vals)
    local o = { names = {}, vals = {} }
    for _, kv in ipairs(vals or {}) do o.names[#o.names + 1] = kv[1]; o.vals[kv[1]] = kv[2] end
    function o:getNumOptions() return #self.names end
    function o:getOptionByIndex(i)
        local n = self.names[i + 1]
        local me = self
        return { getName = function() return n end, getValueAsString = function() return me.vals[n] end }
    end
    function o:getOptionByName(n)
        if self.vals[n] == nil then return nil end
        local me = self
        return { getName = function() return n end, getValueAsString = function() return me.vals[n] end }
    end
    return o
end
local NAMES = {}
for i = 1, 40 do NAMES[i] = "Opt" .. i end
-- the five built-in presets: Apocalypse is all "a"; each other one differs from it in more and more options
local function builtIn(diffs, mark)
    local t = {}
    for i, n in ipairs(NAMES) do t[#t + 1] = { n, (i <= diffs) and mark or "a" } end
    return newOpts(t)
end
local BUILTIN = { { "Apocalypse", builtIn(0, "a") }, { "Outbreak", builtIn(5, "o") }, { "Extinction", builtIn(10, "e") },
                  { "Rising", builtIn(20, "r") }, { "SixMonthsLater", builtIn(36, "s") } }
local userFiles = {}   -- name -> options

SandboxOptions = { new = function() return newOpts() end, isValidPresetName = function(n) return n ~= nil and n ~= "" end }
deleteSandboxPreset = function(name) userFiles[name] = nil end

-- vanilla's SandboxOptionsScreen, as far as ZeD uses it (loadPresets / onPresetChange as in SandboxOptions.lua)
local screen = { controls = {}, presetList = { selected = 1, options = {} }, presets = {}, ui = newOpts() }
for _, n in ipairs(NAMES) do screen.controls[n] = true end
local function copyOpts(src)
    local t = {}
    for _, n in ipairs(src.names) do t[#t + 1] = { n, src.vals[n] } end
    return newOpts(t)
end
function screen:settingsFromUI(o) local c = copyOpts(self.ui); o.names, o.vals = c.names, c.vals end
function screen:settingsToUI(o) self.ui = copyOpts(o) end
function screen:onPresetChange() local p = self.presets[self.presetList.selected]; if p then self:settingsToUI(p.options) end end
function screen:loadPresets()
    self.presetList.options, self.presets = {}, {}
    for _, b in ipairs(BUILTIN) do
        self.presetList.options[#self.presetList.options + 1] = b[1]
        self.presets[#self.presets + 1] = { name = b[1], options = b[2], userDefined = false }
    end
    local names = {}
    for n in pairs(userFiles) do names[#names + 1] = n end
    table.sort(names)
    for _, n in ipairs(names) do
        self.presetList.options[#self.presetList.options + 1] = n
        self.presets[#self.presets + 1] = { name = n, options = userFiles[n], userDefined = true }
    end
    if self.presetList.selected > #self.presetList.options then self.presetList.selected = #self.presetList.options end
    self:onPresetChange()
end
screen.presetList.getOptionText = function(_, i) return screen.presetList.options[i] end
SandboxOptions.new = function()
    local o = newOpts()
    function o:savePresetFile(name) userFiles[name] = copyOpts(self) end
    return o
end

local function newCharScreen(buildName)
    return { savedBuilds = { options = { buildName }, selected = 1 }, getSelectedProf = function() return { getUIName = function() return "Unemployed" end } end,
             saveBuildValidate = function() return true end }
end
MainScreen = { instance = { sandOptions = screen, charCreationProfession = newCharScreen("Lumberjack build"),
                            charCreationMain = newCharScreen("Kate Bloom") } }

load("ZeD_Keyboard.lua")
load("ZeD_MainMenuSandbox.lua")
load("ZeD_MainMenuTraits.lua")
load("ZeD_MainMenuLooks.lua")

-- ---------------------------------------------------------------------------
section("#4 deleting the active custom preset: the base the values sit closest to")
-- ---------------------------------------------------------------------------
local sw = setmetatable({ field = newField(), confirm = false, diff = {}, nDiff = 0 }, ZeD_MMSandbox)
sw.commitCell, sw.endCell = noop, noop
screen:loadPresets()
screen.presetList.selected = 1
screen:onPresetChange()                  -- Apocalypse
screen.ui.vals.Opt40 = "changed"         -- one change
sw:refreshDiff(true)
check("Apocalypse + 1 change reads 1 changed", sw.nDiff == 1, sw.nDiff)
-- save it as a preset (vanilla's path: the file, the list reloaded, the new one chosen)
sw.confirm = "save"
sw.field:setText("Mine")
sw:savePreset()
local _, pname = sw:preset()
check("the saved preset is chosen", pname == "Mine", pname)
check("the saved preset reads 0 changed", sw.nDiff == 0, sw.nDiff)
-- delete it
sw.confirm = "delete"
sw:deletePreset()
local _, after = sw:preset()
check("after the delete the base is Apocalypse (not Six Months Later)", after == "Apocalypse", after)
check("after the delete it reads 1 changed (not 36)", sw.nDiff == 1, sw.nDiff)
check("the values on screen are kept", screen.ui.vals.Opt40 == "changed" and screen.ui.vals.Opt1 == "a")
-- a set closest to Rising lands on Rising
screen.presetList.selected = 4
screen:onPresetChange()
screen.ui.vals.Opt39 = "x"
sw.confirm = "save"; sw.field:setText("Mine2"); sw:savePreset()
sw.confirm = "delete"; sw:deletePreset()
local _, after2 = sw:preset()
check("Rising + 1 change saved and deleted: the base is Rising", after2 == "Rising", after2)
check("Rising + 1 change saved and deleted: 1 changed", sw.nDiff == 1, sw.nDiff)

-- ---------------------------------------------------------------------------
section("#5 a name question selects its default: typing replaces it")
-- ---------------------------------------------------------------------------
-- Sandbox: Save as preset (a built-in preset chosen: the new-preset name)
screen.presetList.selected = 1; screen:onPresetChange()
sw.confirm = false
sw:setConfirm("save")
check("Sandbox: the field is open on the default", sw.field.visible and sw.field.text ~= "", sw.field.text)
check("Sandbox: the default is selected", sw.field.sel == true)
sw.field:type("Z")
check("Sandbox: a key typed replaces the default", sw.field.text == "Z", sw.field.text)

-- Traits: Save build
local tw = setmetatable({ field = newField(), confirm = false }, ZeD_MMTraits)
tw:setConfirm("save")
check("Traits: the field is open on the build's name", tw.field.text == "Lumberjack build", tw.field.text)
check("Traits: the default is selected", tw.field.sel == true)
tw.field:type("Q")
check("Traits: a key typed replaces the default", tw.field.text == "Q", tw.field.text)

-- Looks: Save preset
local lw = setmetatable({ field = newField(), confirm = false, fore = newField("Kate"), sur = newField("Bloom") }, ZeD_MMLooks)
lw:setConfirm("save")
check("Looks: the field is open on the preset's name", lw.field.text == "Kate Bloom", lw.field.text)
check("Looks: the default is selected", lw.field.sel == true)

-- the controller's keyboard on the untouched default (the selection lost in between, a click): selected again
local kb = setmetatable({ setVisible = noop, addToUIManager = noop, setAlwaysOnTop = noop, layout = noop }, ZeD_Keyboard)
lw.field.sel = false
kb:show(0, lw.field, nil)
check("Keyboard: opened on the untouched default, it is selected again", lw.field.sel == true)
lw.field:type("J")
check("Keyboard: the first key replaces the default", lw.field.text == "J", lw.field.text)
-- a field the player has typed into keeps its caret
lw.field.sel = false
kb:show(0, lw.field, nil)
check("Keyboard: a field already typed into is not selected", lw.field.sel == false)
-- a field no question offered a default for keeps its caret
local plain = newField("note text")
kb:show(0, plain, nil)
check("Keyboard: an ordinary field is not selected", plain.sel == false)

-- ---------------------------------------------------------------------------
section("#6 Options > Find: ZeD's own options with ZeD's controls")
-- ---------------------------------------------------------------------------
load("ZeD_MainMenuOptionGroups.lua")
local G = MM.optionGroups
local ctlTheme, ctlFont = { name = "theme combo" }, { name = "font combo" }
PZAPI = { ModOptions = { getOptions = function(_, id)
    if id ~= "ZeD_UI" then return nil end
    return { data = { { id = "baseTheme", element = ctlTheme, zedNameKey = "UI_ZeD_Settings_BaseTheme", zedDefault = 1 } } }
end } }
local vpages = { { raw = "UI_mainscreen_mods" }, { raw = "UI_optionscreen_UI" } }
local vrows = {
    UI_mainscreen_mods = { { kind = "combo", control = ctlTheme, label = "Base theme" } },
    UI_optionscreen_UI = { { kind = "combo", control = ctlFont, label = "Font size", opt = { name = "fontSize" } } },
}
local built = G.build(vpages, function(p) return vrows[p.raw] end)
local pages = {}
for _, g in ipairs(G.GROUPS) do pages[#pages + 1] = { title = g.id, raw = g.id, setup = g.setup } end
local function rowsFor(p) return built[p.raw] or {} end
local function hay(r)
    return string.lower(tostring(r.label or "") .. " " .. (r.labelKey and ZeD.tr(r.labelKey) or ""))
end
check("G.findRows is there", type(G.findRows) == "function")
if type(G.findRows) == "function" then
    local found = G.findRows(pages, rowsFor, "theme", hay)
    local zedHit, modsHit, header = nil, nil, nil
    for _, r in ipairs(found) do
        if r.kind == "header" then header = r.text
        elseif r.control == ctlTheme then
            if r.zedStyle then zedHit = { r = r, under = header } else modsHit = r end
        end
    end
    check("Find 'theme': ZeD's option is found with ZeD's control (radio)", zedHit and zedHit.r.zedStyle == "radio",
        zedHit and zedHit.r.zedStyle)
    check("Find 'theme': it is under ZeD setup", zedHit and zedHit.under == "zed", zedHit and zedHit.under)
    check("Find 'theme': the Mods page's drop-down is left out", modsHit == nil)
    local found2 = G.findRows(pages, rowsFor, "font", hay)
    local inGroup, inSetup = 0, 0
    local h2 = nil
    for _, r in ipairs(found2) do
        if r.kind == "header" then h2 = r.text
        elseif r.control == ctlFont then if h2 == "zed" then inSetup = inSetup + 1 else inGroup = inGroup + 1 end end
    end
    check("Find 'font': the game's setting is found once, in its own group", inGroup == 1 and inSetup == 0, inGroup .. "/" .. inSetup)
    check("Find 'nothing here': no rows", #G.findRows(pages, rowsFor, "nothing here", hay) == 0)
end

print("menus_b7_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
