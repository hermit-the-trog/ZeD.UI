-- ZeDUI/tools/qa/mods_menu_fixes_sim.lua  (Nov 27 2026, Build): the Mods screen's fixes from QA's menus sweep, with no
-- game running. The real ZeD_MainMenuMods.lua runs on Lua 5.1 against the game's own ModSelectorModel.lua (stubs as
-- mods_order_sim.lua).
--   * MM53: Paste over a profile's name asks first ("preplace"), replaces on Replace and says so; a name no profile may
--     take is refused
--   * MM57: "\ModId" ids keep their place in the pasted order and in the share text (presetIds)
--   * MM4: the close box (back) on Profiles closes a Rename question with the page
--   * MM64: Discard changes puts the load order back, as Undo changes does
-- What it can't show: the band on screen.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mods_menu_fixes_sim.lua [path to the game's ModSelectorModel.lua]

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\]tools[/\]qa[/\]mods_menu_fixes_sim%.lua$", "")
local VANILLA = arg and arg[1] or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/client/OptionScreens/ModSelector/ModSelectorModel.lua"

-- ZeD.ModOrder: the profile file's entries in memory
local STORE = {}
O_STUB = {
    entries = function() return STORE end,
    entry = function(name) return STORE[name] end,
    save = function() end,
    sort = function(t) table.sort(t) end,
    putLo = function() end, getLo = function() return nil end, listKey = function() return "@list" end,
}
SandboxOptions = { isValidPresetName = function(n) return n ~= "" and not n:find("[/\:]") end }
getFileWriter = function() return { write = function() end, close = function() end } end
local CLIP
Clipboard = { setClipboard = function(t) CLIP = t end }
luautils = { split = function(inputstr, sep)
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do t[#t + 1] = str end
    return t
end }

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

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
-- a Java ArrayList as the game hands it to Lua (0-based get)
local function jarr(t)
    t = t or {}
    return {
        size = function() return #t end,
        get = function(_, i) return t[i + 1] end,
        clear = function() for i = #t, 1, -1 do t[i] = nil end end,
        add = function(_, v) t[#t + 1] = v end,
        _t = t,
    }
end

-- ActiveMods: the list of mod ids that are on, in load order
local function newActive(ids)
    local a = { list = jarr(ids) }
    function a:getMods() return self.list end
    function a:isModActive(id) for _, x in ipairs(self.list._t) do if x == id then return true end end return false end
    function a:setModActive(id, on)
        local t = self.list._t
        if on then if not self:isModActive(id) then t[#t + 1] = id end
        else for i = #t, 1, -1 do if t[i] == id then table.remove(t, i) end end end
    end
    return a
end
local active
ActiveMods = { getById = function() return active end, requiresResetLua = function() return false end }
MapGroups = { new = function() return {} end }
getActivatedMods = function() return jarr({ "ZeD_UI", "Gone_Mod", "ZeD_Picks" }) end
getText = function(k) return k end
require = noop
Events = setmetatable({}, { __index = function() return { Add = noop, Remove = noop } end })

ModSelector = {}
local vf = io.open(VANILLA, "rb")
if not vf then print("mods_order_sim: the game's ModSelectorModel.lua is not at " .. VANILLA); os.exit(1) end
local vsrc = vf:read("*a"); vf:close()
assert(loadstring(vsrc, "@ModSelectorModel.lua"))()

local said = {}
ZeD = {
    MainMenu = { U = {}, ui = {}, clickSound = noop, hoverSound = noop, now = function() return 0 end },
    ModScan = { modName = function(id) return id end, dirtyCounts = noop, updatedLoaded = function() return {} end },
    ModOrder = O_STUB,
    ModPicks = { HELPER = "ZeD_Picks", reset = noop, sync = function() return 0 end },
    ModSettings = { reset = noop }, ModSafety = { reset = noop }, ModFolders = nil,
    tr = function(k, ...) local p = { k } for _, v in ipairs({ ... }) do p[#p + 1] = tostring(v) end return table.concat(p, "|") end,
    T = { px = function(v) return v end },
}
ZeD_MMWindow = { derive = function(self, name) local c = {}; c.__index = c; return setmetatable(c, { __index = self }) end }

assert(loadfile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuMods.lua"))()

-- mod records as vanilla builds them; "Gone_Mod" is listed as on but not installed (no record)
local function modInfo(id, req)
    return {
        getId = function() return id end, getName = function() return id end,
        getRequire = function() return req and jarr(req) or nil end,
        getIncompatible = function() return nil end, isAvailable = function() return true end,
        getLoadAfter = function() return nil end, getLoadBefore = function() return nil end,
    }
end
local function setup(onIds)
    active = newActive(onIds)
    local m = ModSelector.Model:new({ updateView = noop })
    for _, spec in ipairs({ { "ZeD_UI" }, { "ZeD_Picks", { "ZeD_UI" } }, { "Other" }, { "Needs_Other", { "Other" } }, { "Needs_ZeD", { "ZeD_UI" } } }) do
        local id = spec[1]
        local d = { modId = id, modInfo = modInfo(id, spec[2]), name = id }
        d.defaultActive = active:isModActive(id)
        m.mods[id] = d
        m.sortedMods[#m.sortedMods + 1] = d
    end
    m:refreshMods()
    ModSelector.instance = { model = m }
    local s = setmetatable({}, { __index = ZeD_MMMods })
    s.problem = function() return nil end
    s.problemRun = function() return nil end
    s.dirty = noop
    s.say = function(_, t) said[#said + 1] = t end
    s.find = { getInternalText = function() return "" end, setText = noop, isFocused = function() return false end }
    s.field = { setVisible = noop }
    return m, s
end

local function onList() return table.concat(active:getMods()._t, ",") end
local function lastSaid() return tostring(said[#said]) end
local function withBand(s)
    local fieldText = ""
    s.field = { setVisible = noop, setText = function(_, t) fieldText = t end, getText = function() return fieldText end,
                focus = noop, unfocus = noop, isFocused = function() return false end }
    s.confirm = false
    return s
end
ZeD.MainMenu.ctx = {}

section("MM53: Paste over an existing profile asks, then replaces")
do
    local m, s = setup({ "ZeD_UI", "Other" })
    withBand(s)
    m.presets = { ["QA P"] = { Other = "" } }
    s.page = "profiles"
    s:setConfirm("paste")
    s.field:setText("QA P:ZeD_UI;Needs_ZeD;")
    s:pastePreset()
    check("an existing name opens the Replace question", s.confirm == "preplace", s.confirm)
    check("the question lands on Cancel", s.focusId == "confirm:no", s.focusId)
    check("nothing replaced yet", m.presets["QA P"].Other ~= nil and m.presets["QA P"].ZeD_UI == nil)
    check("the pasted text is held for the answer", s._pasteText == "QA P:ZeD_UI;Needs_ZeD;", s._pasteText)
    s:pastePreset(true)
    check("Replace writes the pasted mods", m.presets["QA P"].ZeD_UI ~= nil and m.presets["QA P"].Other == nil)
    check("its order is the pasted one", table.concat(STORE["QA P"].order, ",") == "ZeD_UI,Needs_ZeD", table.concat(STORE["QA P"].order, ","))
    check("it says replaced, not nothing to add", lastSaid() == "UI_ZeD_Mods_SayPasteReplaced|QA P", lastSaid())
    check("the question closed and dropped the text", s.confirm == false and s._pasteText == nil)
    -- Cancel leaves it as it was
    s:setConfirm("paste")
    s.field:setText("QA P:Other;")
    s:pastePreset()
    s:setConfirm(false)
    check("Cancel on the question keeps the profile", m.presets["QA P"].Other == nil and m.presets["QA P"].ZeD_UI ~= nil)
    check("Cancel drops the held text", s._pasteText == nil)
    -- a new name still adds at once
    s:setConfirm("paste")
    s.field:setText("QA New:Other;")
    s:pastePreset()
    check("a new name is added", m.presets["QA New"] ~= nil and s.confirm == false)
    check("it says added", lastSaid() == "UI_ZeD_Mods_SayAdded|QA New", lastSaid())
    -- names no profile may take
    for _, bad in ipairs({ "No mods", "@list" }) do
        s:setConfirm("paste")
        s.field:setText(bad .. ":Other;")
        s:pastePreset()
        check("refused: " .. bad, m.presets[bad] == nil and lastSaid() == "UI_ZeD_Mods_SayPasteBadName|" .. bad, lastSaid())
    end
    s:setConfirm("paste")
    s.field:setText(":Other;")
    s:pastePreset()
    check("no name: nothing to add", lastSaid() == "UI_ZeD_Mods_SayNothingToAdd", lastSaid())
end

section("MM57: backslash ids keep their order")
do
    local m, s = setup({ "ZeD_UI", "Other" })
    withBand(s)
    m.presets = {}
    s:setConfirm("paste")
    s.field:setText("QA Slash:\Other;\ZeD_UI;")
    s:pastePreset()
    check("the profile has both mods", m.presets["QA Slash"] ~= nil and m.presets["QA Slash"]["\Other"] == "Other")
    check("its order is not empty", table.concat(STORE["QA Slash"].order, ",") == "Other,ZeD_UI", table.concat(STORE["QA Slash"].order, ","))
    -- presetIds reads a "\id" key with a Workshop number for its value
    m.presets["QA Slash2"] = { ["\Other"] = "123456" }
    STORE["QA Slash2"] = { order = {} }
    s.psel = "QA Slash2"
    s:copyPreset()
    check("the share text names \Other's id", CLIP == "QA Slash2:Other;", CLIP)
end

section("MM4: the close box on Profiles closes its question")
do
    local m, s = setup({ "ZeD_UI" })
    withBand(s)
    m.presets = { ["QA P"] = {} }
    s.page = "profiles"
    s.psel = "QA P"
    s:setConfirm("rename")
    s:close()
    check("back on the list page", s.page == "list", s.page)
    check("the Rename question closed", s.confirm == false, s.confirm)
end

section("MM64: Discard changes puts the load order back")
do
    getActivatedMods = function() return jarr({ "ZeD_UI", "Other" }) end
    local m, s = setup({ "ZeD_UI", "Other" })
    withBand(s)
    local accepted = false
    s.accept = function() accepted = true end
    s:saveOrder({ "Other", "ZeD_UI" })
    check("the order was changed", onList() == "Other,ZeD_UI", onList())
    s:discard()
    check("Discard put it back", onList() == "ZeD_UI,Other", onList())
    check("Discard still accepts", accepted)
    -- Undo changes still does the same
    s:saveOrder({ "Other", "ZeD_UI" })
    s:revert()
    check("Undo changes put it back", onList() == "ZeD_UI,Other", onList())
end

print("mods_menu_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
