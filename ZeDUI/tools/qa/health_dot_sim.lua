-- ZeDUI/tools/qa/health_dot_sim.lua  (Nov 11 2026, Build; the director's health status pixel in the Character title)
-- The Character window's title bar with no game running: ZeD's REAL Organisms.lua (the title bar's draw, the hover
-- watch, the status pixel's bands and blink) on Lua 5.1 stubs, and the REAL composeCharHealth cut out of
-- ZeD_CharacterWindow.lua. The status pixel is the same 6-unit square as a title stat's mark.
--   BANDS   80 and over good, 40 to 79 warning, 21 to 39 danger, 20 and under danger and blinking; each boundary
--           value (80, 79, 40, 39, 21, 20, 0, 100) on the side named; the colors are the ZeD.T tokens read each call,
--           so a colorblind set swapped into ZeD.T shows at once
--   BLINK   on 500 ms, off 500 ms on the game's clock: one flash a second (under three); the same at a clock past
--           2^31 ms (Kahlua's % trap: clockStep); a solid pixel never blinks; ZeD_Window.PIXEL_BLINK = false holds
--           the blinking pixel solid (the off switch; ZeD has no reduce-motion option yet)
--   OPTION  the setup option "Blink the low-health pixel" (the real Settings.lua on a stub of ModOptions): in the
--           Look group, On for a new player, Off holds the pixel solid at once (also from an unapplied pick on
--           the open options screen), survives a save and a fresh load, the code switch still wins, and its
--           name and help are in all 28 UI.json files
--   TITLE   no "%" stat in the title stats; the name drawn with three pins showing; the pixel at the title's left,
--           the name after it, nothing over the name
--   SHORT   as the window narrows: pins take their shorter forms first, then the name is cut with "...", then pins
--           drop from the left; the weight stays last; the name never below four letters and the dots
--   DECK    1280x800 at Auto (1x units): the Character window at its 640 half-screen cap with three pins shows the
--           pixel, part of the name and all three pins
--   HOVER   the pointer on the pixel or the name puts "Health: 63%" in the help line; on the stripes, not
--   OTHERS  a window with no pixel draws its title where it always did (the World window, the menus)
-- What it can't show: the real fonts' widths (stand-in: 7 px a letter) and the look on screen (zedqa_health_dot.lua).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/health_dot_sim.lua
-- It prints FAIL lines and a last line "health_dot_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]health_dot_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- ---------------------------------------------------------------------------
-- THE GAME
-- ---------------------------------------------------------------------------
local CLOCK = 100000
function getTimestampMs() return CLOCK end
local MX, MY = -5000, -5000
function getMouseX() return MX end
function getMouseY() return MY end
function isMouseButtonDown() return false end
function getText(k) if k == "IGUI_XP_Health" then return "Health" end return k end
JoypadState = { players = {} }
function getCore() return { getScreenWidth = function() return 1280 end, getScreenHeight = function() return 800 end } end
UIManager = { getMillisSinceLastRender = function() return 16 end }

ISUIElement = {}
ISPanel = {}
ISPanel.__index = ISPanel
function ISPanel:derive(name)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.Type = name
    return o
end
function ISPanel:new(x, y, w, h)
    local o = { x = x, y = y, width = w, height = h, visible = true }
    setmetatable(o, self)
    self.__index = self
    return o
end
function ISPanel:initialise() end
function ISPanel:update() end
function ISPanel:addChild() end
function ISPanel:getX() return self.x end
function ISPanel:getY() return self.y end
function ISPanel:getAbsoluteX() return self.x end
function ISPanel:getAbsoluteY() return self.y end
function ISPanel:getWidth() return self.width end
function ISPanel:getHeight() return self.height end
function ISPanel:setWidth(v) self.width = v end
function ISPanel:isVisible() return self.visible end
function ISPanel:isMouseOver()
    return self.visible and MX >= self.x and MX < self.x + self.width and MY >= self.y and MY < self.y + self.height
end
function ISPanel:drawRect() end
function ISPanel:drawRectBorder() end
function ISPanel:drawText() end

-- ---------------------------------------------------------------------------
-- ZeD's stand-ins
-- ---------------------------------------------------------------------------
ZeD = {}
local function rgb(r) return { r = r or 0.5, g = 0.5, b = 0.5, a = 1 } end
ZeD.T = {
    px = function(v) return v end, line = function(v) return v end, hair = 1, borderW = 1,
    closeBoxSz = 14, titleBarH = 26, minWinH = 200, minWinW = 200,
    sp = { sm = 4, md = 8, titleBoxPad = 4 },
    hover = rgb(), surf2 = rgb(), borderS = rgb(), accent = rgb(), textDim = rgb(), textHead = rgb(), text = rgb(),
    positive = rgb(0.1), warning = rgb(0.2), danger = rgb(0.3), info = rgb(0.4),
    fontF3 = "F3",
}
local LETTER = 7
ZeD.TM = { MeasureStringX = function(_, _, s) return #tostring(s) * LETTER end, getFontHeight = function() return 14 end }
ZeD.tr = function(k, ...)
    local a = { ... }
    if k == "UI_ZeD_Char_HealthHelp" then return tostring(a[1]) .. ": " .. tostring(a[2]) end
    return k
end
ZeD.Help = { set = function() end }
ZeD.Surface = { fill = function() end }
ZeD.Atoms = {
    drawPxIcon = function() end, frame = function() end, drawCloseBox = function() end,
    -- the real cut: letters off the end until the rest and the dots fit
    truncateText = function(s, _, maxW)
        if maxW <= 0 then return "" end
        if #s * LETTER <= maxW then return s end
        for n = #s - 1, 0, -1 do
            local c = s:sub(1, n) .. "..."
            if #c * LETTER <= maxW then return c end
        end
        return ""
    end,
    -- (as Atoms.lua's pctText)
    pctText = function(p) return tostring(math.floor(math.max(0, math.min(1, p)) * 100 + 1e-6)) .. "%" end,
}
ZeD.Molecules = {}
ZeD.Safe = { guard = function(self, fn) return fn(self) end, on = function() return false end }
function require() end

local fn, err = loadfile(CLIENT .. "Organisms.lua")
if not fn then error(err) end
fn()
check("Organisms.lua loads", ZeD_Window and ZeD_Window.healthPixel and ZeD_Window.pixelLit)

-- the real composeCharHealth, cut out of the Character window's file
local f = io.open(CLIENT .. "ZeD_CharacterWindow.lua", "rb")
local CWSRC = f:read("*a")
f:close()
local s0 = CWSRC:find("local function composeCharHealth", 1, true)
local s1 = s0 and CWSRC:find("\nend\n", s0, true) or CWSRC:find("\nend\r\n", s0 or 1, true)
check("composeCharHealth is in ZeD_CharacterWindow.lua", s0 and s1)
local chunk = assert(loadstring(CWSRC:sub(s0, s1 + 4) .. "\nreturn composeCharHealth"))
local composeCharHealth = chunk()

-- ---------------------------------------------------------------------------
-- BANDS
-- ---------------------------------------------------------------------------
local T = ZeD.T
local function band(hp)
    local c, b = ZeD_Window.healthPixel(hp)
    local n = (c == T.positive and "good") or (c == T.warning and "warning") or (c == T.danger and "danger") or "?"
    return n .. (b and "+blink" or "")
end
local WANT = {
    { 100, "good" }, { 80, "good" }, { 79, "warning" }, { 40, "warning" }, { 39, "danger" },
    { 21, "danger" }, { 20, "danger+blink" }, { 1, "danger+blink" }, { 0, "danger+blink" },
}
for _, w in ipairs(WANT) do check("band at " .. w[1], band(w[1]) == w[2], band(w[1])) end
-- a colorblind set swapped into ZeD.T: the new token shows at once
local oldPos = T.positive
T.positive = rgb(0.9)
check("colors read fresh (a swapped token)", (ZeD_Window.healthPixel(90)) == T.positive)
T.positive = oldPos

-- ---------------------------------------------------------------------------
-- BLINK
-- ---------------------------------------------------------------------------
-- the times the pixel lights over ten seconds, sampled every 10 ms, a second's worth
local function flashesPerSecond(t0)
    local ons, last = 0, false   -- (lit at the start counts as one)
    for ms = t0, t0 + 9999, 10 do
        local on = ZeD_Window.pixelLit(true, ms)
        if on and not last then ons = ons + 1 end
        last = on
    end
    return ons / 10
end
check("one flash a second", flashesPerSecond(100000) == 1, flashesPerSecond(100000))
check("under three flashes a second", flashesPerSecond(100000) < 3)
local BIG = 1731000000000   -- (a real clock in ms, far past 2^31)
check("lit 0-499 ms past the clock's step", ZeD_Window.pixelLit(true, BIG) and ZeD_Window.pixelLit(true, BIG + 499))
check("dark 500-999 ms", not ZeD_Window.pixelLit(true, BIG + 500) and not ZeD_Window.pixelLit(true, BIG + 999))
check("lit again at 1000 ms", ZeD_Window.pixelLit(true, BIG + 1000))
check("one flash a second past 2^31", flashesPerSecond(BIG + 3) == 1, flashesPerSecond(BIG + 3))
check("a solid pixel never blinks", ZeD_Window.pixelLit(false, BIG + 600))
ZeD_Window.PIXEL_BLINK = false
check("the off switch holds it solid", ZeD_Window.pixelLit(true, BIG + 600) and ZeD_Window.pixelLit(true, BIG + 700))
ZeD_Window.PIXEL_BLINK = true

-- ---------------------------------------------------------------------------
-- The setup option "Blink the low-health pixel": the REAL Settings.lua on a stub of the game's ModOptions.
-- The stub keeps what a save wrote in STORE, and a second load of Settings.lua gets it back, as the next
-- launch does from ModOptions.ini.
-- ---------------------------------------------------------------------------
local STORE = {}
local OPTS
local function loadSettings()
    local dummy
    dummy = setmetatable({}, {
        __index = function(_, k) if type(k) == "number" then return nil end return dummy end,
        __call = function() return dummy end,
        __concat = function(a, b) return tostring(a == dummy and "" or a) .. tostring(b == dummy and "" or b) end,
    })
    local opts = { dict = {} }
    local function newOption(id)
        local o = { id = id, items = {}, element = false }
        function o:addItem(text, selected)
            self.items[#self.items + 1] = text
            if selected then self.default = #self.items; self.value = STORE[id] or #self.items end
        end
        function o:getValue() return self.value end
        function o:setValue(v) self.value = v end
        return setmetatable(o, { __index = function() return function() return dummy end end })
    end
    setmetatable(opts, { __index = function(_, name)
        return function(self, id)
            local o = newOption(id)
            if type(id) == "string" then self.dict[id] = o end
            return o
        end
    end })
    OPTS = opts
    local env = setmetatable({
        PZAPI = { ModOptions = { create = function() return opts end, save = function()
            for id, o in pairs(opts.dict) do STORE[id] = o.value end
        end } },
        getFileReader = function() return nil end,
        getTextOrNull = function(k) return k end,
    }, { __index = function(_, k) local g = _G[k]; if g ~= nil then return g end return dummy end })
    ZeD.Settings = nil
    local sf, serr = loadfile(CLIENT .. "Settings.lua")
    if not sf then error(serr) end
    setfenv(sf, env)
    local ok, e = pcall(sf)
    if not ok then error("Settings.lua: " .. tostring(e)) end
end

loadSettings()
local S = ZeD.Settings
local hb = OPTS.dict.healthBlink
check("OPTION: Settings.lua registers healthBlink", hb ~= nil)
check("OPTION: Off then On, On the default", hb and #hb.items == 2 and hb.default == 2, hb and hb.default)
check("OPTION: read through ZeD.Settings.healthBlink", S.healthBlink and S.healthBlink() == true)
check("OPTION: ZeD setup names it for the Look group", hb and hb.zedNameKey == "UI_ZeD_Settings_HealthBlink", hb and hb.zedNameKey)
do
    local g = io.open(CLIENT .. "ZeD_MainMenuOptionGroups.lua", "rb"):read("*a")
    local look = g:match('"UI_ZeD_Options_ZedLook",(.-)\n    %-%-')
    check("OPTION: the Look group lists it as a check box", look ~= nil and look:find('{ "healthBlink", "onoff" }', 1, true) ~= nil)
end
check("DEFAULT: a new player's pixel blinks (lit then dark)", ZeD_Window.pixelLit(true, BIG) and not ZeD_Window.pixelLit(true, BIG + 600))
S.setHealthBlink(false)
check("OFF: the pick takes effect at once, solid in both halves of the second",
    ZeD_Window.pixelLit(true, BIG) and ZeD_Window.pixelLit(true, BIG + 600) and ZeD_Window.pixelLit(true, BIG + 1600))
check("OFF: a solid pixel is still drawn lit by the title bar's blink flag", ZeD_Window.pixelLit(true, BIG + 700))
S.setHealthBlink(true)
check("ON again: blinks again at once", ZeD_Window.pixelLit(true, BIG) and not ZeD_Window.pixelLit(true, BIG + 600))
-- while the options screen is open the pick on the control (not yet applied) is what counts
hb.element = { selected = 1 }
check("LIVE: an unapplied pick on the open options screen already holds it solid", ZeD_Window.pixelLit(true, BIG + 600))
hb.element = false
S.setHealthBlink(false)
loadSettings()
S = ZeD.Settings
check("ROUND TRIP: Off saved, then a fresh load of Settings.lua reads Off", S.healthBlink() == false and STORE.healthBlink == 1, STORE.healthBlink)
check("ROUND TRIP: the reloaded pixel holds solid", ZeD_Window.pixelLit(true, BIG + 600))
S.setHealthBlink(true)
loadSettings()
S = ZeD.Settings
check("ROUND TRIP: On saved, reloads On and blinks", S.healthBlink() == true and not ZeD_Window.pixelLit(true, BIG + 600))
-- the code switch still wins over the option
ZeD_Window.PIXEL_BLINK = false
check("SWITCH: the code switch holds it solid with the option On", ZeD_Window.pixelLit(true, BIG + 600))
ZeD_Window.PIXEL_BLINK = true
-- every language has the name and its help
do
    local missing = 0
    local langs = { "AR","CA","CH","CN","CS","DA","DE","EN","ES","ES_CL","ES_MX","FI","FR","HU","ID","IT","JP","KO","NL","NO","PL","PT","PTBR","RO","RU","TH","TR","UA" }
    for _, l in ipairs(langs) do
        local fh = io.open(ROOT .. "42/media/lua/shared/Translate/" .. l .. "/UI.json", "rb")
        local t = fh and fh:read("*a") or ""
        if fh then fh:close() end
        if not (t:find('"UI_ZeD_Settings_HealthBlink": "', 1, true) and t:find('"UI_ZeD_Settings_HealthBlinkTip": "', 1, true)) then missing = missing + 1 end
    end
    check("TEXT: the name and help are in all 28 UI.json files", missing == 0, missing)
end

-- ---------------------------------------------------------------------------
-- The window and its draw
-- ---------------------------------------------------------------------------
local HP = 63
local PLAYER = { getBodyDamage = function() return { getOverallBodyHealth = function() return HP end } end }
local NAME = "Angel Cross  +  Health"

local function makeWin(w)
    local win = ZeD_Window:new(100, 100, w, 420, NAME)
    win:createChildren()
    win.autoCollapse = true
    win._playerObj = PLAYER
    win.title = NAME
    return win
end

local function pins3()
    return {
        { text = "Carpentry Vol. 1 40/220", color = T.accent, alts = { "Carpentr 40/220", "40/220" } },
        { text = "Water Bottle 0.2 L", color = T.warning, alts = { "Water Bo 0.2 L", "0.2 L" } },
        { text = "Lighter 68%", color = T.info, alts = { "Lighter 68%", "68%" } },
        { text = "12.5 / 18", noMark = true },
    }
end

-- one draw of the title bar: what was drawn where
local function draw(win)
    local rec = { texts = {}, rects = {} }
    win.drawText = function(_, s, x) rec.texts[#rec.texts + 1] = { s = s, x = x, w = #s * LETTER } end
    win.drawRect = function(_, x, y, w, h, a, r) rec.rects[#rec.rects + 1] = { x = x, y = y, w = w, h = h, r = r } end
    win:_drawTitleBar(win:getWidth(), win:titleBarHeight())
    return rec
end

-- the name as drawn (the text at the title's x), the stats' texts, the pixel's square
local function read(win, rec)
    local nameX = 26 + 10
    local out = { name = nil, stats = {}, pixel = nil }
    for _, t in ipairs(rec.texts) do
        if t.x == nameX or (not win._titleMark and t.x == 26) then out.name = t
        else out.stats[#out.stats + 1] = t end
    end
    for _, r in ipairs(rec.rects) do
        if r.x == 26 and r.w == 6 and r.h == 6 then out.pixel = r end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- TITLE and HOVER: composeCharHealth on the window, three pins
-- ---------------------------------------------------------------------------
local win = makeWin(900)
win.titleStats = pins3()
composeCharHealth(win)
check("no % stat in the title stats", (function()
    for _, st in ipairs(win.titleStats) do if tostring(st.text):match("^%d+%%$") then return false end end
    return true
end)())
check("the Character window's own stats have no health stat (source)", not CWSRC:find('text = hp .. "%"', 1, true))
check("the name no longer hides for pins (source)", not CWSRC:find("_hideTitle = #pinStats", 1, true))
check("composeCharHealth runs in the window's prerender (source)", CWSRC:find("composeCharHealth(self)", 1, true) ~= nil)
check("63: the warning pixel", win._titleMark == T.warning and not win._titleMarkBlink)
check("the name gives way to the stats", win._titleYields == true and not win._hideTitle)
local r = read(win, draw(win))
check("the name drawn with three pins", r.name and r.name.s == NAME, r.name and r.name.s)
check("the pixel at the title's left, before the name", r.pixel and r.pixel.r == T.warning.r and r.name and r.name.x > r.pixel.x + 6)
check("all four stats drawn", #r.stats == 4, #r.stats)
local statL = 1e9
for _, s in ipairs(r.stats) do statL = math.min(statL, s.x) end
check("nothing over the name", r.name and r.name.x + r.name.w < statL - 6)
check("the roll box goes after the pixel and the name", win._titleShownW == 10 + #NAME * LETTER, win._titleShownW)

-- HOVER: the pixel, the name, the stripes beyond
MX, MY = 100 + 28, 100 + 12
win._updHelp = nil
win:_watchBoxes()
check("hover on the pixel: Health: 63%", win._updHelp == "Health: 63%", win._updHelp)
MX = 100 + 36 + 40
win._updHelp = nil
win:_watchBoxes()
check("hover on the name: Health: 63%", win._updHelp == "Health: 63%", win._updHelp)
MX = 100 + 36 + #NAME * LETTER + 30
win._updHelp = nil
win:_watchBoxes()
check("hover past the name: no health words", win._updHelp == nil, win._updHelp)
MX, MY = -5000, -5000
-- the words follow the health; the same health keeps the same string (no new string a frame)
HP = 19.6
composeCharHealth(win)
check("20 (19.6 rounded) blinks red", win._titleMark == T.danger and win._titleMarkBlink == true)
check("help follows: Health: 20%", win._titleHelp == "Health: 20%", win._titleHelp)
local s1h = win._titleHelp
composeCharHealth(win)
check("the same health keeps its string", rawequal(win._titleHelp, s1h))
-- blink in the draw: dark half draws no pixel, the name stays put
CLOCK = BIG + 600
local rd = read(win, draw(win))
check("dark half: no pixel, the name in place", rd.pixel == nil and rd.name and rd.name.x == 36)
CLOCK = BIG + 100
check("lit half: the pixel", read(win, draw(win)).pixel ~= nil)
HP = 100
composeCharHealth(win)
check("100: good, solid", win._titleMark == T.positive and not win._titleMarkBlink)

-- ---------------------------------------------------------------------------
-- SHORT: what gives way as the window narrows
-- ---------------------------------------------------------------------------
local ALTS = {}
for _, st in ipairs(pins3()) do
    if st.alts then for _, a in ipairs(st.alts) do ALTS[a] = st.text end end
end
local firstShort, firstCut, firstDrop
local okLeast, okWeight, okNoOverlap = true, true, true
local leastW = #"Mmmm..." * LETTER
for w = 900, 260, -2 do
    local wn = makeWin(w)
    wn.titleStats = pins3()
    composeCharHealth(wn)
    local rr = read(wn, draw(wn))
    local short, n = false, #rr.stats
    for _, s in ipairs(rr.stats) do if ALTS[s.s] and ALTS[s.s] ~= s.s then short = true end end
    local cut = not (rr.name and rr.name.s == NAME)
    if short and not firstShort then firstShort = w end
    if cut and not firstCut then firstCut = w end
    if n < 4 and not firstDrop then firstDrop = w end
    -- the name keeps four letters and the dots while any pin drops
    if n < 4 and not (rr.name and rr.name.w >= leastW - LETTER) then okLeast = false end
    -- the weight is the last to go
    if n > 0 then
        local hasW = false
        for _, s in ipairs(rr.stats) do if s.s == "12.5 / 18" then hasW = true end end
        if not hasW then okWeight = false end
    end
    local sl = 1e9
    for _, s in ipairs(rr.stats) do sl = math.min(sl, s.x) end
    if rr.name and rr.name.x + rr.name.w > sl then okNoOverlap = false end
end
check("pins shorten before the name is cut", firstShort and firstCut and firstShort > firstCut, tostring(firstShort) .. " / " .. tostring(firstCut))
check("the name is cut before a pin drops", firstCut and firstDrop and firstCut > firstDrop, tostring(firstCut) .. " / " .. tostring(firstDrop))
check("the name keeps four letters and the dots while pins drop", okLeast)
check("the weight stays while any stat shows", okWeight)
check("no stat over the name at any width", okNoOverlap)
print(string.format("  (stand-in widths: pins shorten under %s, the name is cut under %s, a pin drops under %s)",
    tostring(firstShort), tostring(firstCut), tostring(firstDrop)))

-- DECK: 1280x800 at Auto (1x), the Character window at its 640 half-screen cap, three pins
local dk = makeWin(640)
dk.titleStats = pins3()
HP = 63
composeCharHealth(dk)
local rk = read(dk, draw(dk))
check("Deck: the pixel shows", rk.pixel ~= nil)
check("Deck: the name (or its start) shows", rk.name and #rk.name.s >= 4, rk.name and rk.name.s)
check("Deck: three pins and the weight", #rk.stats == 4, #rk.stats)
print("  (Deck 640: name '" .. tostring(rk.name and rk.name.s) .. "', stats " .. #rk.stats .. ")")

-- OTHERS: a window with no pixel keeps its title where it was
local ow = ZeD_Window:new(100, 100, 600, 300, "Mods")
ow:createChildren()
ow.titleStats = { { text = "3 of 40", color = T.positive } }
local ro = read(ow, draw(ow))
check("a window with no pixel: title at its old x", ro.name and ro.name.x == 26 and ro.pixel == nil)
check("a window with no pixel: its roll-box width is the title's", ow._titleShownW == 4 * LETTER)

print(string.format("health_dot_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
