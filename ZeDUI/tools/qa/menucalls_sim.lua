-- ZeDUI/tools/qa/menucalls_sim.lua  (Nov 27 2026, Build): the director's seven picks on QA's menus sweep design calls,
-- with no game running. Real code on Lua 5.1 against stubs:
--   * DK13: the quit question (ZeD_MMWindow:setConfirm) and the Trash's land the pad on Cancel
--   * LJ37: a new account with an empty password has no problem (ZeD_MMJoin:accountProblems)
--   * OP24: the real ZeD_QuickChords.lua holds chord picks (no file write) until commit; revert brings them back;
--           the real ZeD_MainMenuOptions.lua counts them (anyChanged, changedCount, isChanged), Back asks, Discard
--           reverts, Apply writes ZeD_chords.txt
--   * OP72: the real welcome: B steps back from a choice to the way cards, on the way cards it does what the close
--           box does (keeps the picks); Escape and back() no longer skip; the footer's B word follows
--   * MM25: the Profiles band says No mods turns ZeD-GUI off, only with No mods picked and ZeD-GUI on
--   * MM31: Homepage's question: the game's words, the pad on No, Yes opens the page, No does not
--   * MO40: the load order page after a move asks "Keep the new order?" (Back, B, the menu bar's askLeave), the pad on
--           Cancel; Keep goes through Done and on with the held move; Discard drops it; Cancel stays; no move leaves
-- What it can't show: the bands drawn, a real pad, the browser.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/menucalls_sim.lua [path to the game's ModSelectorModel.lua]
-- It prints FAIL lines and a last line "menucalls_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]menucalls_sim%.lua$", "")
local CDIR = ROOT .. "42/media/lua/client/ZeD/"
local VANILLA = arg and arg[1] or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/client/OptionScreens/ModSelector/ModSelectorModel.lua"

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

local function readSrc(name)
    local f = assert(io.open(CDIR .. name, "rb"))
    local s = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return s
end
-- one top-level function of a file, as its own chunk (from its "function NAME(" line to the first "end" at column 0)
local function extract(name, head)
    local src = readSrc(name)
    local a = src:find("\n" .. head, 1, true)
    assert(a, name .. ": no " .. head)
    local b = src:find("\nend\n", a + 1, true)
    return src:sub(a + 1, b + 4)
end
local function runFn(name, head)
    local chunk, err = loadstring(extract(name, head), "@" .. name)
    assert(chunk, err)
    chunk()
end

-- files in memory, read a line at a time
local FILES = {}
local WRITES = {}
function getFileReader(name)
    local text = FILES[name]
    if not text then return nil end
    local lines = {}
    for l in text:gmatch("([^\n]*)\n") do lines[#lines + 1] = l end
    local tail = text:match("([^\n]+)$")
    if tail then lines[#lines + 1] = tail end
    local i = 0
    return { readLine = function() i = i + 1; return lines[i] end, close = noop }
end
function getFileWriter(name)
    local buf = {}
    return { write = function(_, s) buf[#buf + 1] = s end,
             close = function() FILES[name] = table.concat(buf); WRITES[name] = (WRITES[name] or 0) + 1 end }
end
require = noop
Events = setmetatable({}, { __index = function() return { Add = noop, Remove = noop } end })
local WORDS = {}
getText = function(k) return WORDS[k] or k end
getTextOrNull = function(k) return WORDS[k] end

-- ---------------------------------------------------------------------------
section("DK13: the quit questions land on Cancel")
-- ---------------------------------------------------------------------------
do
    local sounds = 0
    clickSound = function() sounds = sounds + 1 end
    ZeD_MMWindow = {}
    ZeD_MMTrash = setmetatable({}, { __index = ZeD_MMWindow })
    runFn("ZeD_MainMenu.lua", "function ZeD_MMWindow:setConfirm(on)")
    runFn("ZeD_MainMenuDesktop.lua", "function ZeD_MMTrash:setConfirm(on)")
    local w = setmetatable({ kind = "main", confirm = false, focusId = "quit" }, { __index = ZeD_MMWindow })
    w:setConfirm(true)
    check("the power button's question: the pad on Cancel", w.focusId == "confirm:no", w.focusId)
    w:setConfirm(false)
    check("answered Cancel: back on Quit", w.focusId == "quit", w.focusId)
    local p = setmetatable({ kind = "pause", confirm = false, focusId = "quitDesktop" }, { __index = ZeD_MMWindow })
    p:setConfirm(true)
    check("the pause window's quit question: on Cancel too", p.focusId == "confirm:no", p.focusId)
    local t = setmetatable({ kind = "trash", confirm = false, focusId = "empty" }, { __index = ZeD_MMTrash })
    t:setConfirm(true)
    check("the Trash's question: the pad on Cancel", t.focusId == "confirm:no", t.focusId)
    t:setConfirm(false)
    check("the Trash answered Cancel: back on Empty trash", t.focusId == "empty", t.focusId)
    clickSound = nil
end

-- ---------------------------------------------------------------------------
section("LJ37: a new account may have an empty password")
-- ---------------------------------------------------------------------------
do
    ZeD = { tr = function(k) return k end }
    getMinUsernameLength = function() return 1 end
    profanityFilterCheck = function() return false end
    ZeD_MMJoin = {}
    runFn("ZeD_MainMenuJoin.lua", "function ZeD_MMJoin:accountProblems()")
    local function field(t) return { getText = function() return t end, getInternalText = function() return t end } end
    local accs = { size = function() return 0 end }
    local j = setmetatable({ fUser = field("qa_user"), fPwd = field(""),
                             form = { server = { getAccounts = function() return accs end }, account = nil } }, { __index = ZeD_MMJoin })
    local p = j:accountProblems()
    check("an empty password: no problem", p.pwd == nil, p.pwd)
    check("and nothing else in the way", p.user == nil, p.user)
    j.fUser = field("")
    check("a name is still needed", j:accountProblems().user ~= nil)
    check("the refusal key is no longer read", not readSrc("ZeD_MainMenuJoin.lua"):find('ZeD.tr("UI_ZeD_Join_ErrNoPassword")', 1, true))
end

-- ---------------------------------------------------------------------------
section("OP24: the chords wait for Apply (ZeD_QuickChords)")
-- ---------------------------------------------------------------------------
local Qc
do
    ZeD = { tr = function(k) return k end }
    FILES["ZeD_chords.txt"] = "ZeD-UI quick action chords\nLB+A=character:4|Character\tDrink\n"
    WRITES = {}
    assert(loadfile(CDIR .. "ZeD_QuickChords.lua"))()
    Qc = ZeD.QuickChords
    check("loaded", Qc and Qc.hold and Qc.commit and Qc.revert and Qc.release)
    check("the file's chord", Qc.get("LB+A") == "character:4", Qc.get("LB+A"))
    -- without a hold a pick saves at once, as before
    Qc.set("LB+B", "now:1", { "Here", "Sit" })
    check("no hold: saved at once", (WRITES["ZeD_chords.txt"] or 0) == 1 and FILES["ZeD_chords.txt"]:find("LB+B=now:1", 1, true) ~= nil)
    local shown = true
    Qc.hold(function() return shown end)
    WRITES = {}
    check("held, nothing changed: 0 pending", Qc.pendingCount() == 0, Qc.pendingCount())
    Qc.set("LB+A", "world:2", { "World", "Map" })
    Qc.clear("RB+B")
    check("a pick shows at once", Qc.get("LB+A") == "world:2")
    check("two chords pending", Qc.pendingCount() == 2, Qc.pendingCount())
    check("LB+A is pending, LB+X is not", Qc.isPending("LB+A") and not Qc.isPending("LB+X"))
    check("held: nothing written", WRITES["ZeD_chords.txt"] == nil and WRITES["ZeD_chords_spare.txt"] == nil)
    Qc.set("LB+A", "character:4", { "Character", "Drink" })
    check("set back by hand: not pending", not Qc.isPending("LB+A") and Qc.pendingCount() == 1, Qc.pendingCount())
    Qc.revert()
    check("revert: RB+B back to its default", Qc.isDefault("RB+B") and Qc.pendingCount() == 0)
    Qc.reset("LB+B")
    check("Defaults on a chord waits too", Qc.isDefault("LB+B") and Qc.pendingCount() == 1 and WRITES["ZeD_chords.txt"] == nil)
    Qc.commit()
    check("commit writes the file", (WRITES["ZeD_chords.txt"] or 0) == 1 and not FILES["ZeD_chords.txt"]:find("LB+B=", 1, true))
    check("after commit: still held, 0 pending", Qc.held() and Qc.pendingCount() == 0)
    Qc.set("RB+Y", nil, {})
    Qc.revert()
    check("revert after commit: back to the committed list", Qc.isDefault("RB+Y") and Qc.isDefault("LB+B"))
    -- a holder gone without an answer: dropped at the next look, saves at once again
    Qc.set("RB+Y", nil, {})
    shown = false
    WRITES = {}
    check("holder gone: its pick dropped", Qc.isDefault("RB+Y") and not Qc.held())
    Qc.set("RB+X", "now:3", { "Here", "Walk" })
    check("holder gone: a pick saves at once again", (WRITES["ZeD_chords.txt"] or 0) == 1)
    -- release drops what was not applied
    Qc.hold(function() return true end)
    Qc.set("RB+L3", nil, {})
    Qc.release()
    check("release: the pick not applied is dropped", Qc.isDefault("RB+L3") and not Qc.held())
end

-- ---------------------------------------------------------------------------
section("OP24: Options counts the chords (ZeD_MainMenuOptions)")
-- ---------------------------------------------------------------------------
local MM
do
    local QcKeep = Qc
    GameKeyboard = { setDoLuaKeyPressed = noop }
    Keyboard = { KEY_RETURN = 28, KEY_ESCAPE = 1 }
    JoypadState = {}
    MainOptions = {}
    local applied = 0
    local gameOptions = { changed = false }
    local mainOptions = { gameOptions = gameOptions, apply = function() applied = applied + 1 end, toUI = noop }
    MainScreen = { onMenuItemMouseDownMainMenu = noop, instance = { inGame = false, mainOptions = mainOptions } }
    local function derive(base, name)
        local c = {}
        for k, v in pairs(base) do if type(v) == "function" then c[k] = v end end
        setmetatable(c, { __index = base })
        c.__index = c
        c.Type = name
        return c
    end
    ISPanel = { derive = derive }
    ZeD_MMWindow = { derive = derive }
    function ZeD_MMWindow.new(cls, kind) local o = setmetatable({}, cls); o.kind = kind; return o end
    function ZeD_MMWindow.joyDir(self) end
    function ZeD_MMWindow.joyA(self) end
    ZeD_Window = { render = noop, prerender = noop }
    ZeD = { tr = function(k) return k end, btnCase = function(s) return s end, textCase = function(s) return s end,
            T = { px = function(v) return v end, fontF2 = "f2", titleBarH = 20 },
            Atoms = { wrapText = function(t) return { t } end, truncateText = function(t) return t end }, QuickChords = QcKeep }
    MM = { U = { STACK_PAD = 8 }, ctx = {}, now = function() return 0 end, wheel = noop }
    MM.ui = { drawStripAndButtons = noop, plain = function(s) return s end }
    MM.clickSound, MM.hoverSound = noop, noop
    MM.fontH = function() return 10 end
    MM.textW = function(_, s) return #tostring(s) * 5 end
    MM.bandH = function() return 30 end
    MM.addView = noop
    local views = {}
    MM.showView = function(v) views[#views + 1] = v end
    ZeD.MainMenu = MM
    assert(loadfile(CDIR .. "ZeD_MainMenuOptionGroups.lua"))()
    assert(loadfile(CDIR .. "ZeD_MainMenuOptions.lua"))()
    local w = ZeD_MMOptions:new(false)
    w.kind = "options"
    w.field = { setVisible = noop, isFocused = function() return false end, unfocus = noop }
    w.find = { getInternalText = function() return "" end, setText = noop, isFocused = function() return false end, unfocus = noop }
    w.pages = function() return {} end
    w.snapshot = noop
    local visible = false
    w.isVisible = function() return visible end
    w:onShow()
    check("onShow holds the chords", Qc.held())
    check("nothing changed: anyChanged is false", w:anyChanged() == false)
    -- a pick before the desk shows the window (onShow runs first) is not dropped
    Qc.set("LB+A", "world:2", { "World", "Map" })
    check("a pick a frame before the window shows stays held", Qc.held() and Qc.pendingCount() == 1)
    visible = true
    check("a chord pick counts as a change", w:anyChanged() == true)
    check("changedCount counts it", w:changedCount() == 1, w:changedCount())
    check("its row shows changed", w:isChanged({ kind = "chord", chord = "LB+A" }) and not w:isChanged({ kind = "chord", chord = "LB+X" }))
    WRITES = {}
    w:back()
    check("Back asks (OP46's real-changes count includes it)", w.confirm == "back", w.confirm)
    check("nothing written while asking", WRITES["ZeD_chords.txt"] == nil)
    -- Discard (the question's Discard changes): the chord back, the window closes
    w:discard()
    check("Discard brings the old chord back", Qc.get("LB+A") ~= "world:2" and Qc.pendingCount() == 0, Qc.get("LB+A"))
    check("Discard closed the window and the hold", views[#views] == "main" and not Qc.held())
    check("Discard wrote nothing", WRITES["ZeD_chords.txt"] == nil)
    -- Apply writes the file
    visible = false
    w:onShow()
    visible = true
    Qc.clear("RB+A")
    check("X (clear) counts too", w:changedCount() == 1)
    w:apply(false)
    check("Apply writes ZeD_chords.txt", (WRITES["ZeD_chords.txt"] or 0) == 1 and FILES["ZeD_chords.txt"]:find("RB+A=|", 1, true) ~= nil)
    check("Apply ran the game's apply", applied == 1, applied)
    check("after Apply: nothing pending, the window still holds", Qc.pendingCount() == 0 and Qc.held())
    -- the footer's Discard keeps the window open and the hold on
    Qc.set("RB+R3", nil, {})
    w:discardStay()
    check("footer Discard: the chord back, the hold stays", Qc.isDefault("RB+R3") and Qc.held())
    -- Back with nothing changed leaves; the hold ends
    gameOptions.changed = false
    w:back()
    check("Back with nothing changed leaves and the hold ends", w.confirm == false and not Qc.held())
end

-- ---------------------------------------------------------------------------
section("OP72: B in the welcome steps back; Skip only its own button")
-- ---------------------------------------------------------------------------
do
    local setTo = {}
    local opts = { { id = "baseTheme", type = "combo", v = 1 } }
    for _, o in ipairs(opts) do
        o.getValue = function(self) return self.v end
        o.setValue = function(self, v) self.v = v; setTo[#setTo + 1] = v end
    end
    local dict = { baseTheme = opts[1] }
    local saved = 0
    MM.gamepad = function() return true end
    ZeD.Settings = { opts = { data = opts, dict = dict }, SETUP_FILE = "ZeD_setup.txt", baseKeys = { "dark", "light", "hicon" },
                     saveNow = function() saved = saved + 1 end, applyThemeNow = noop }
    local views = {}
    MM.showView = function(v) views[#views + 1] = v end
    assert(loadfile(CDIR .. "ZeD_MainMenuWelcome.lua"))()
    local w = ZeD_MMWelcome:new()
    FILES["ZeD_setup_seen.txt"] = nil
    w:onShow()
    -- a pick: Theme to Light
    opts[1]:setValue(2)
    w.focusId = "opt:theme:2"
    local prompts = w:getFooterPrompts()
    check("on a choice the footer's B says Back", prompts[2].label == "UI_btn_back", prompts[2].label)
    w:joyB()
    check("B from a choice: back to the way cards", w.focusId == "way:1", w.focusId)
    check("B from a choice: the window stays", #views == 0, #views)
    check("B from a choice: the pick stays", opts[1].v == 2, opts[1].v)
    prompts = w:getFooterPrompts()
    check("on the way cards the footer's B says Close", prompts[2].label == "UI_Close", prompts[2].label)
    w.focusId = "done"
    w:joyB()
    check("B from the band: back to the picked way", w.focusId == "way:1", w.focusId)
    w:joyB()
    check("B on the way cards: closes as the close box", views[#views] == "main", views[#views])
    check("the close box keeps the picks", opts[1].v == 2, opts[1].v)
    check("and marks the setup seen", FILES["ZeD_setup_seen.txt"] == "1")
    -- Escape and back() no longer skip
    views = {}
    w:onShow()
    opts[1]:setValue(3)
    w.focusId = "opt:theme:3"
    w:keyEscape()
    check("Escape: as the close box (picks kept)", views[#views] == "main" and opts[1].v == 3, opts[1].v)
    w:onShow()
    opts[1]:setValue(1)
    w:back()
    check("back(): as the close box (picks kept)", opts[1].v == 1, opts[1].v)
    -- Skip, its own button (Skip way, Done) still puts the snapshot back
    w:onShow()
    opts[1]:setValue(2)
    w.way = 3
    w:done()
    check("Skip (its own button) puts the choices back", opts[1].v == 1, opts[1].v)
    -- the Load way on the first step: B does what the close box does there (ends as Skip, nothing picked)
    w:onShow()
    w.way = 2
    w.focusId = "way:2"
    views = {}
    w:joyB()
    check("Load a setup picked, B on the way cards: closes", views[#views] == "main", views[#views])
end

-- ---------------------------------------------------------------------------
-- THE MODS SCREEN (MM25, MM31, MO40): the real ZeD_MainMenuMods.lua and ZeD_MainMenuModsOrder.lua on the game's
-- ModSelectorModel.lua (the harness is mods_menu_fixes_sim.lua's)
-- ---------------------------------------------------------------------------
local STORE = {}
local O_STUB = {
    entries = function() return STORE end, entry = function(name) return STORE[name] end, save = noop,
    sort = function(t, lt) table.sort(t, lt) end, putLo = noop, getLo = function() return nil end, listKey = function() return "@list" end,
    copyLo = function() return { first = {}, last = {}, rules = {}, seps = {}, top = {} } end,
    layout = function(order) local o = {}; for i, v in ipairs(order) do o[i] = v end; return o, {}, {}, {} end,
    check = function() return { st = {}, nBad = 0 } end, isEmpty = function() return true end,
}
SandboxOptions = { isValidPresetName = function(n) return n ~= "" end }
local function jarr(t)
    t = t or {}
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
             clear = function() for i = #t, 1, -1 do t[i] = nil end end, add = function(_, v) t[#t + 1] = v end, _t = t }
end
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
getActivatedMods = function() return jarr({ "ZeD_UI", "Other" }) end
local opened = {}
openUrl = function(u) opened[#opened + 1] = u end
ModSelector = {}
local vf = io.open(VANILLA, "rb")
if not vf then print("menucalls_sim: the game's ModSelectorModel.lua is not at " .. VANILLA); os.exit(1) end
local vsrc = vf:read("*a"); vf:close()
assert(loadstring(vsrc, "@ModSelectorModel.lua"))()

local band = {}
local leaveRan = {}
ZeD = {
    MainMenu = { U = {}, ctx = {}, clickSound = noop, hoverSound = noop, now = function() return 0 end,
                 leaveRun = function(go) leaveRan[#leaveRan + 1] = go; if go then go() end end,
                 ui = { stripSpecs = function(_, _, _, _, lefts, rights, ask, plain) band = { lefts = lefts, rights = rights, ask = ask, plain = plain } end } },
    ModScan = { modName = function(id) return id end, dirtyCounts = noop, updatedLoaded = function() return {} end },
    ModOrder = O_STUB,
    ModPicks = { HELPER = "ZeD_Picks", reset = noop, sync = function() return 0 end },
    ModSettings = { reset = noop }, ModSafety = { reset = noop },
    tr = function(k, ...) local p = { k } for _, v in ipairs({ ... }) do p[#p + 1] = tostring(v) end return table.concat(p, "|") end,
    T = { px = function(v) return v end },
}
ZeD_MMWindow = { derive = function(self, name) local c = {}; c.__index = c; return setmetatable(c, { __index = self }) end }
assert(loadfile(CDIR .. "ZeD_MainMenuMods.lua"))()
assert(loadfile(CDIR .. "ZeD_MainMenuModsOrder.lua"))()

local function modInfo(id)
    return { getId = function() return id end, getName = function() return id end, getRequire = function() return nil end,
             getIncompatible = function() return nil end, isAvailable = function() return true end,
             getLoadAfter = function() return nil end, getLoadBefore = function() return nil end }
end
local said = {}
local function setup(onIds)
    active = newActive(onIds)
    local m = ModSelector.Model:new({ updateView = noop })
    for _, id in ipairs({ "ZeD_UI", "Other", "Third" }) do
        local d = { modId = id, modInfo = modInfo(id), name = id }
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
    s.find = { getInternalText = function() return "" end, setText = noop, isFocused = function() return false end, unfocus = noop }
    s.field = { setVisible = noop, isFocused = function() return false end, unfocus = noop }
    s.confirm = false
    return m, s
end
local function answer(id)
    for _, g in ipairs({ band.lefts or {}, band.rights or {} }) do
        for _, b in ipairs(g) do if b[1] == id then return b end end
    end
    return nil
end

section("MM25: No mods says it turns ZeD-GUI off")
do
    local m, s = setup({ "ZeD_UI", "Other" })
    m.presets = { ["QA P"] = { Other = "" } }
    s.page = "profiles"
    s.psel = nil
    s:buildStrip(0, 30, 600)
    check("No mods picked, ZeD-GUI on: the band's plain line", band.ask == "UI_ZeD_Mods_NoModsZeD" and band.plain == true, band.ask)
    check("the band reads its own key (no game words say it)", readSrc("ZeD_MainMenuMods.lua"):find('"UI_ZeD_Mods_NoModsZeD"', 1, true) ~= nil)
    s.psel = "QA P"
    s:buildStrip(0, 30, 600)
    check("a saved profile picked: no line", band.ask == nil, band.ask)
    active:setModActive("ZeD_UI", false)
    m.mods.ZeD_UI.isActive = false
    s.psel = nil
    s._diffs = nil
    s:buildStrip(0, 30, 600)
    check("ZeD-GUI already off: no line", band.ask == nil, band.ask)
    -- No mods still turns everything off, ZeD-GUI with it (its behavior kept)
    local m2, s2 = setup({ "ZeD_UI", "Other" })
    s2.page = "profiles"
    s2.leaveProfiles = noop
    s2:loadProfile({ name = nil })
    check("No mods still turns ZeD-GUI off", not m2.mods.ZeD_UI.isActive and not m2.mods.Other.isActive)
end

section("MM31: Homepage asks first")
do
    local _, s = setup({ "ZeD_UI" })
    s.focusId = "homepage"
    check("the verb asks, not opens", readSrc("ZeD_MainMenuMods.lua"):find('verb("homepage", ZeD.tr("Homepage"), function() self._homeUrl = url; self:setConfirm("homepage") end)', 1, true) ~= nil)
    s._homeUrl = "https://example.invalid/mod"
    s:setConfirm("homepage")
    check("the pad lands on No", s.focusId == "confirm:no", s.focusId)
    s:buildStrip(0, 30, 600)
    check("the game's question words", band.ask == "UI_mods_openModUrl", band.ask)
    check("No and Yes, the game's words", answer("confirm:no") and answer("confirm:no")[2] == "UI_No" and answer("confirm:yes")[2] == "UI_Yes")
    answer("confirm:no")[3]()
    check("No: nothing opened, the question closed, back on Homepage", #opened == 0 and s.confirm == false and s.focusId == "homepage", s.focusId)
    s._homeUrl = "https://example.invalid/mod"
    s:setConfirm("homepage")
    s:buildStrip(0, 30, 600)
    answer("confirm:yes")[3]()
    check("Yes: the page opens", opened[1] == "https://example.invalid/mod", opened[1])
    check("Yes: the question closed", s.confirm == false)
    s:setConfirm("homepage")
    s:joyDir("down")
    check("the D-pad stays in the band", s.confirm == "homepage" and s.focusId == "confirm:no", s.focusId)
    s:setConfirm(false)
end

section("MO40: leaving the load order page after a move asks")
do
    local function orderPage(s, ids)
        s.page = "order"
        s.order = {}
        for i, v in ipairs(ids) do s.order[i] = v end
        s.oLo = O_STUB.copyLo()
        s.oZone, s.oCarried, s.oSec, s.oInfo = {}, {}, {}, {}
        s._orderStart = table.concat(s.order, ";")
        s._orderStartLo = ZeD_MMMods.orderLoSig(s.oLo)
        s.focusId = "orow:1"
        s.orderChanged = noop
        s.orderCheck = function() return { st = {}, nBad = 0 } end
        s.orderSeq = function(self) return self.order end
    end
    -- no move: Back leaves as before
    local _, s = setup({ "ZeD_UI", "Other" })
    orderPage(s, { "ZeD_UI", "Other" })
    s:back()
    check("no move: Back leaves with no question", s.page == "list" and s.confirm == false, s.page)
    -- a move: Back asks
    orderPage(s, { "ZeD_UI", "Other" })
    s.order = { "Other", "ZeD_UI" }
    check("a move is seen", s:orderMoved())
    s:back()
    check("after a move Back asks", s.confirm == "orderkeep" and s.page == "order", s.confirm)
    check("the pad lands on Cancel", s.focusId == "confirm:no", s.focusId)
    s:buildStrip(0, 30, 600)
    check("the question's words", band.ask == "UI_ZeD_Order_AskKeep", band.ask)
    check("Keep, Discard and Cancel", answer("confirm:yes")[2] == "ContextMenu_Keep" and answer("confirm:discard") ~= nil and answer("confirm:no")[2] == "UI_btn_cancel")
    answer("confirm:no")[3]()
    check("Cancel stays on the page with the move", s.page == "order" and s.confirm == false and s.order[1] == "Other")
    -- B (joyB -> back) and Escape ask too
    s:joyB()
    check("B asks", s.confirm == "orderkeep", s.confirm)
    s:joyB()
    check("B on the question cancels it", s.confirm == false and s.page == "order")
    s:keyEscape()
    check("Escape asks", s.confirm == "orderkeep", s.confirm)
    s:keyEscape()
    -- Discard drops the move
    s:back()
    s:buildStrip(0, 30, 600)
    answer("confirm:discard")[3]()
    check("Discard leaves the page", s.page == "list" and s.confirm == false, s.page)
    check("Discard drops the move", table.concat(active:getMods()._t, ",") == "ZeD_UI,Other", table.concat(active:getMods()._t, ","))
    -- Keep keeps it, as Done
    orderPage(s, { "ZeD_UI", "Other" })
    s.order = { "Other", "ZeD_UI" }
    s:back()
    s:buildStrip(0, 30, 600)
    answer("confirm:yes")[3]()
    check("Keep leaves the page", s.page == "list", s.page)
    check("Keep keeps the move, as Done", table.concat(active:getMods()._t, ",") == "Other,ZeD_UI", table.concat(active:getMods()._t, ","))
    check("Keep says it, as Done", tostring(said[#said]) == "UI_ZeD_Mods_SayOrderSet", said[#said])
    -- a red row: Keep goes through Done, which refuses and stays
    orderPage(s, { "Other", "ZeD_UI" })
    s.order = { "ZeD_UI", "Other" }
    s.orderCheck = function() return { st = {}, nBad = 1, firstBad = 1 } end
    s.orderAutoFixes = function() return false end
    s:back()
    s:buildStrip(0, 30, 600)
    answer("confirm:yes")[3]()
    check("Keep with a red row stays on the page, as Done", s.page == "order" and s.confirm == false, s.page)
    -- the menu bar's way out: askLeave holds the move, the answer goes on with it
    local went = 0
    local go = function() went = went + 1 end
    orderPage(s, { "Other", "ZeD_UI" })
    s.order = { "ZeD_UI", "Other" }
    s._leaveGo = nil
    check("askLeave after a move asks", s:askLeave(go, "main") == true and s.confirm == "orderkeep", s.confirm)
    check("the pad lands on Cancel", s.focusId == "confirm:no", s.focusId)
    s:buildStrip(0, 30, 600)
    answer("confirm:no")[3]()
    check("Cancel: the move held back is dropped", went == 0 and s.page == "order")
    s:askLeave(go, "main")
    s:buildStrip(0, 30, 600)
    answer("confirm:discard")[3]()
    check("Discard: the held move goes on", went == 1 and s.page == "list", went)
    orderPage(s, { "Other", "ZeD_UI" })
    s.order = { "ZeD_UI", "Other" }
    s:askLeave(go, "main")
    s:buildStrip(0, 30, 600)
    answer("confirm:yes")[3]()
    check("Keep: the held move goes on", went == 2 and s.page == "list", went)
    -- with mods turned on or off as well, the Mods page's own question follows
    orderPage(s, { "ZeD_UI", "Other" })
    s.order = { "Other", "ZeD_UI" }
    local m3 = ModSelector.instance.model
    m3.mods.Third.isActive = true
    s:askLeave(go, "main")
    s:buildStrip(0, 30, 600)
    answer("confirm:discard")[3]()
    check("mods changed too: the Mods page's question follows", s.confirm == "back" and s._leaveGo == go and went == 2, s.confirm)
    m3.mods.Third.isActive = false
    s:setConfirm(false)
    -- no move: askLeave leaves the page and lets the move through (nothing else changed)
    orderPage(s, { "ZeD_UI", "Other" })
    check("no move, nothing changed: askLeave lets it go", s:askLeave(go, "main") == false)
    -- a pin or rule changed is a move too
    orderPage(s, { "ZeD_UI", "Other" })
    s.oLo.first[1] = "Other"
    check("a pin changed counts as a move", s:orderMoved())
    s:back()
    check("and Back asks", s.confirm == "orderkeep", s.confirm)
    s:setConfirm(false)
    -- the map order page asks the same
    orderPage(s, { "MapA", "MapB" })
    s.page = "maps"
    s.order = { "MapB", "MapA" }
    s:back()
    check("the map order page asks too", s.confirm == "orderkeep", s.confirm)
    -- a script or caller leaving straight through leaveOrder takes the question with it
    s:leaveOrder(false)
    check("leaveOrder with the question open closes it", s.page == "list" and s.confirm == false, tostring(s.confirm))
end

print("menucalls_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
