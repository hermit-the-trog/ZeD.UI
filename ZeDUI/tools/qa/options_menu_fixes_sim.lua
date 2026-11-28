-- ZeDUI/tools/qa/options_menu_fixes_sim.lua  (Nov 27 2026, QA's menus sweep: the Options window and the welcome)
-- The real client/ZeD/ZeD_MainMenuOptionGroups.lua, ZeD_MainMenuOptions.lua, ZeD_MainMenuOptionsSub.lua and
-- ZeD_MainMenuWelcome.lua run on Lua 5.1 against stubs of the game and of ZeD's window parts. It checks:
--   OP43  under a question only the band's answers take the pointer, and the D-pad and A stay on the answers
--         (the windows built on Options keep their hit boxes)
--   OP44  a question raised on the button map page is drawn there (the Options band, asking it)
--   OP46  Back with the game's flag up and no row changed leaves without asking; with changes it asks; the
--         footer's Discard asks only with changes
--   OP61  the key band's question lands on Cancel (confirm:no), an answer it has
--   OP33  a stored color off the 84 swatches puts the pad and the frame on the nearest swatch
--   OP31  the help band's line count is the longest help on the rows, worked out once per list
--   OP5   the Advanced sound button's row has a name and a help line; the debug Reload a name
--   OP74  the welcome's Tutorial starts on the stored answer
--   OP75  Load a setup applies everything stored at once (reapplyFromOptions)
--   OP76  a setup file with nothing ZeD can take says so and the welcome stays
-- Run from the repo root:  lua51 ZeDUI/tools/qa/options_menu_fixes_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]options_menu_fixes_sim%.lua$", "")
local CDIR = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        io.write("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "") .. "\n")
    end
end

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
local WORDS = { GameSound_ButtonAdvanced = "Advanced", GameSound_ButtonReload = "Reload" }
getText = function(k) return WORDS[k] or k end
getTextOrNull = function(k) return WORDS[k] end
local FILES = {}
getFileReader = function(name)
    local t = FILES[name]
    if t == nil then return nil end
    local done = false
    return { readLine = function() if done then return nil end; done = true; return t end, close = function() end }
end
getFileWriter = function(name)
    return { write = function(_, s) FILES[name] = s end, close = function() end }
end
require = function() end
GameKeyboard = { setDoLuaKeyPressed = function() end }
Keyboard = { KEY_RETURN = 28, KEY_ESCAPE = 1 }
JoypadState = {}
MainOptions = {}
local gameOptions = { changed = false }
MainScreen = { onMenuItemMouseDownMainMenu = function() end, instance = { inGame = false, mainOptions = { gameOptions = gameOptions } } }

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
-- the window's D-pad walk: moves to whatever the test says is next
function ZeD_MMWindow.joyDir(self) if self._nextFocus then self.focusId = self._nextFocus end end
function ZeD_MMWindow.joyA(self) self._aOn = self.focusId end
ZeD_Window = { render = function() end, prerender = function() end }

local WRAPS = 0
ZeD = {}
ZeD.tr = function(k, ...)
    local a = { ... }
    if k == "UI_ZeD_Sim_Long" then return "one two three four five six seven eight nine ten eleven twelve" end
    return k .. (#a > 0 and (":" .. table.concat(a, ",")) or "")
end
ZeD.btnCase = function(s) return s end
ZeD.textCase = function(s) return s end
ZeD.T = { px = function(v) return v end, fontF2 = "f2", titleBarH = 20 }
ZeD.Atoms = {
    -- two words to a line, whatever the width (enough to count lines)
    wrapText = function(t)
        WRAPS = WRAPS + 1
        local words, lines = {}, {}
        for w in string.gmatch(t, "%S+") do words[#words + 1] = w end
        for i = 1, #words, 2 do lines[#lines + 1] = words[i] .. (words[i + 1] and (" " .. words[i + 1]) or "") end
        return lines
    end,
    truncateText = function(t) return t end,
}
ZeD.QuickChords = { defaultName = function() return nil end }
local MM = { U = { STACK_PAD = 8 }, ctx = {}, now = function() return 0 end, wheel = function() end }
MM.ui = { drawStripAndButtons = function() end, plain = function(s) return s end }
MM.clickSound = function() end
MM.hoverSound = function() end
MM.fontH = function() return 10 end
MM.textW = function(_, s) return #tostring(s) * 5 end
MM.bandH = function() return 30 end
local views = {}
MM.addView = function() end
MM.showView = function(v) views[#views + 1] = v end
ZeD.MainMenu = MM

local function load(name)
    local f, err = loadfile(CDIR .. name)
    if not f then io.write("options_menu_fixes_sim: " .. tostring(err) .. "\n"); os.exit(1) end
    local ok, e = pcall(f)
    if not ok then io.write("options_menu_fixes_sim: " .. name .. ": " .. tostring(e) .. "\n"); os.exit(1) end
    return e
end
load("ZeD_MainMenuOptionGroups.lua")
load("ZeD_MainMenuOptions.lua")
local O = ZeD_MMOptions

local function newWin(kind)
    local w = O:new(kind == "options_ig")
    w.kind = kind or "options"
    w.field = { setVisible = function() end, isFocused = function() return false end, unfocus = function() end }
    w.find = { getInternalText = function() return "" end, setText = function() end, isFocused = function() return false end }
    return w
end

-- ---------------------------------------------------------------------------
-- OP61: the key band lands on an answer it has
-- ---------------------------------------------------------------------------
do
    local w = newWin()
    w.focusId = "orow:4"
    w:setConfirm("key")
    check("OP61 key band lands on Cancel", w.focusId == "confirm:no", w.focusId)
    w:setConfirm(false)
    check("OP61 back to the row after", w.focusId == "orow:4", w.focusId)
end

-- ---------------------------------------------------------------------------
-- OP46: Back and Discard count real changes only
-- ---------------------------------------------------------------------------
do
    local w = newWin()
    local discarded, stayed, finished = 0, 0, 0
    w.discard = function() discarded = discarded + 1 end
    w.discardStay = function() stayed = stayed + 1 end
    w.finish = function() finished = finished + 1 end
    local n = 0
    w.changedCount = function() return n end
    gameOptions.changed = true
    w:back()
    check("OP46 flag up, nothing changed: Back does not ask", w.confirm == false, w.confirm)
    check("OP46 flag up, nothing changed: Back discards (flag cleared) and leaves", discarded == 1, discarded)
    n = 2
    w:back()
    check("OP46 two changes: Back asks", w.confirm == "back", w.confirm)
    w:setConfirm(false)
    n = 0
    w:askDiscard()
    check("OP46 footer Discard with nothing changed: no question", w.confirm == false and stayed == 1, tostring(w.confirm) .. " " .. stayed)
    n = 1
    w:askDiscard()
    check("OP46 footer Discard with a change: asks", w.confirm == "discard", w.confirm)
    gameOptions.changed = false
    w:setConfirm(false)
    w:back()
    check("OP46 nothing changed and no flag: Back leaves", finished == 1, finished)
end

-- ---------------------------------------------------------------------------
-- OP43: input below a question
-- ---------------------------------------------------------------------------
do
    local function hits()
        return { { id = "options:r3:box" }, { id = "options:page:2" }, { id = "options:find" }, { id = "options:track" },
                 { id = "options:confirm:yes" }, { id = "options:confirm:no" } }
    end
    local w = newWin()
    w._hits = hits()
    w:render()
    check("OP43 no question: every hit box stays", #w._hits == 6, #w._hits)
    w:setConfirm("back")
    w._hits = hits()
    w:render()
    local onlyAnswers = #w._hits == 2
    for _, h in ipairs(w._hits) do if not h.id:find(":confirm:") then onlyAnswers = false end end
    check("OP43 under Back's question only the answers take the pointer", onlyAnswers, #w._hits)
    -- the D-pad stays on the answers
    w.focusId = "confirm:no"
    w._nextFocus = "orow:2"
    w:joyDir("up")
    check("OP43 D-pad up from an answer stays on it", w.focusId == "confirm:no", w.focusId)
    w._nextFocus = "confirm:yes"
    w:joyDir("right")
    check("OP43 D-pad right walks the answers", w.focusId == "confirm:yes", w.focusId)
    w.focusId = "orow:2"
    w:joyA()
    check("OP43 A off an answer lands on the safe one", w.focusId == "confirm:apply" and w._aOn == nil, w.focusId)
    w.focusId = "confirm:yes"
    w:joyA()
    check("OP43 A on an answer answers", w._aOn == "confirm:yes", w._aOn)
    -- a window built on Options keeps its own
    local s = newWin("sandbox")
    s.confirm = "save"
    s._hits = hits()
    s:render()
    check("OP43 a window built on Options keeps its hit boxes", #s._hits == 6, #s._hits)
end

-- ---------------------------------------------------------------------------
-- OP33: the palette starts on the nearest swatch
-- ---------------------------------------------------------------------------
do
    local w = newWin()
    w:openPalette({ control = { backgroundColor = { r = 1, g = 1, b = 1 } } }, {})
    check("OP33 a swatch's color: that swatch", w._palette.at == 1 and w._palette.near == 1, w._palette.at)
    -- 300 is the 16th swatch: 0.6, 0, 0; a stored 0.63, 0.02, 0.01 is off every swatch
    w:openPalette({ control = { backgroundColor = { r = 0.63, g = 0.02, b = 0.01 } } }, {})
    check("OP33 off the swatches: the nearest", w._palette.at == 16 and w._palette.near == 16, w._palette.at)
end

-- ---------------------------------------------------------------------------
-- OP31: the help band's lines
-- ---------------------------------------------------------------------------
do
    local w = newWin()
    MM.optionGroups.text = MM.optionGroups.text or function(s) return s end
    local rows = { { kind = "header", text = "Look" },
                   { kind = "button", control = {}, zedTipKey = "UI_ZeD_Sim_Long" },   -- (12 words: 6 lines)
                   { kind = "button", control = {}, zedTipKey = "UI_ZeD_Short" } }
    local n = w:helpLinesFor(rows, 600)
    check("OP31 the longest help's lines", n == 6, n)
    local before = WRAPS
    w:helpLinesFor(rows, 600)
    check("OP31 worked out once per list", WRAPS == before, WRAPS - before)
    w:helpLinesFor(rows, 500)
    check("OP31 again when the width changes", WRAPS > before, WRAPS - before)
end

-- ---------------------------------------------------------------------------
-- OP5: the sound button's row
-- ---------------------------------------------------------------------------
do
    PZAPI = { ModOptions = { getOptions = function() return nil end } }
    local G = MM.optionGroups
    local function build(title)
        local btn = { kind = "button", control = { title = title } }
        local ok, out = pcall(G.build, { { raw = "UI_optionscreen_audio" } }, function() return { btn } end)
        return btn, ok, out
    end
    local b, ok, out = build("Advanced")
    check("OP5 build ran", ok, out)
    check("OP5 Advanced has a name", b.label == "UI_ZeD_Options_GameSounds", b.label)
    check("OP5 Advanced has a help line", b.zedTipKey == "UI_ZeD_Options_GameSoundsTip", b.zedTipKey)
    local placed = false
    for _, r in ipairs(ok and out.audio or {}) do if r == b then placed = true end end
    check("OP5 under Audio", placed)
    local r2 = build("Reload")
    check("OP5 Reload has a name (the game's tooltip is its help)", r2.label == "UI_ZeD_Options_ReloadSounds" and r2.zedTipKey == nil, r2.label)
end

-- ---------------------------------------------------------------------------
-- OP44: the button map page draws the question
-- ---------------------------------------------------------------------------
do
    MM.layout = function() return { tx = 0, ty = 0, tw = 1000, th = 800 } end
    load("ZeD_MainMenuOptionsSub.lua")
    local w = newWin()
    w.place = function() return 900, 600 end
    w.footerHeight = function() return 20 end
    w.drawPadPage = function() end
    local asked, plain = 0, 0
    w.buildStrip = function() asked = asked + 1 end
    local stripSpecs = MM.ui.stripSpecs
    MM.ui.stripSpecs = function() plain = plain + 1 end
    w.sub = "pad"
    w:prerender()
    check("OP44 no question: the page's own band", plain == 1 and asked == 0, plain .. " " .. asked)
    w:setConfirm("restart")
    w:prerender()
    check("OP44 a question on the button map is drawn there", asked == 1 and plain == 1, plain .. " " .. asked)
    check("OP44 the hand stays on the answer", w.focusId == "confirm:yes", w.focusId)
    MM.ui.stripSpecs = stripSpecs
end

-- ---------------------------------------------------------------------------
-- The welcome: OP74, OP75, OP76
-- ---------------------------------------------------------------------------
do
    local reapplied, loadN = 0, 0
    MM.gamepad = function() return false end
    ZeD.Settings = { opts = { data = {}, dict = {} }, SETUP_FILE = "ZeD_setup.txt",
                     loadSetup = function() return loadN end, saveNow = function() end,
                     reapplyFromOptions = function() reapplied = reapplied + 1 end }
    load("ZeD_MainMenuWelcome.lua")
    local w = ZeD_MMWelcome:new()
    FILES["ZeD_setup_seen.txt"] = "1"
    FILES["ZeD_tutorial.txt"] = "0"
    w:onShow()
    check("OP74 a refused or finished tour starts on No thanks", w.tutorial == 2, w.tutorial)
    FILES["ZeD_tutorial.txt"] = "1"
    w:onShow()
    check("OP74 a tour still wanted starts on Show me around", w.tutorial == 1, w.tutorial)
    FILES["ZeD_tutorial.txt"] = nil
    w:onShow()
    check("OP74 answered before the tour file existed: No thanks", w.tutorial == 2, w.tutorial)
    FILES["ZeD_setup_seen.txt"] = nil
    w:onShow()
    check("OP74 never answered: Show me around", w.tutorial == 1, w.tutorial)
    -- Load a setup with nothing in it
    w.way = 2
    views = {}
    FILES["ZeD_setup_seen.txt"] = nil
    loadN = 0
    w:done()
    check("OP76 nothing loaded: the welcome stays", #views == 0 and FILES["ZeD_setup_seen.txt"] == nil, #views)
    check("OP76 nothing loaded: it says so", tostring(w.note):find("UI_ZeD_Welcome_LoadEmpty", 1, true) ~= nil, w.note)
    check("OP76 nothing loaded: nothing applied", reapplied == 0, reapplied)
    loadN = 4
    w:done()
    check("OP75 a load applies what it set at once", reapplied == 1, reapplied)
    check("OP75 then the welcome closes", views[#views] == "main" and FILES["ZeD_setup_seen.txt"] == "1", views[#views])
end

io.write(string.format("options_menu_fixes_sim: %d checks, %d failed\n", checks, failed))
if failed > 0 then os.exit(1) end
