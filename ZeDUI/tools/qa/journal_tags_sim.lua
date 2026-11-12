-- ZeDUI/tools/qa/journal_tags_sim.lua  (Nov 11 2026, Build): the Journal's entry tags with no game running.
-- Loads the real JournalTab.lua, ZeD_JournalReaders.lua, SpatialNav.lua and PostDeath.lua against Lua 5.1 stand-ins
-- (a panel that writes down every draw, a TextManager whose widths add up letter by letter, a player with modData
-- and a notebook in the bag) and the real EN and DE UI.json, and proves:
--   * Save with tags: the entry keeps the ticked tags' keys in the row's order, and the ticks clear; no ticks, no
--     tags field; an empty box saves nothing and keeps the ticks
--   * old entries (no tags field) draw as before: the date runs to the delete cross, no tag zone
--   * the search keeps entries whose words or tags' words hold it, in the player's language (DE words for a DE
--     player), and its cache rebuilds when the search changes
--   * a click on a tag on an entry (and A on the pad) puts its word in the search; a pick's click ticks it
--   * past three tags on one entry, the squares alone, every tag still a stop and named in the help line
--   * Into a notebook: the notebook gets the words only, the log entry keeps the tags, the ticks clear once written
--   * PostDeath reads entries[1] (the newest, tagged) as the last entry
--   * a modData round trip (serialized and read back) keeps the tags, and the page draws them the same
--   * pad stops: the eight picks walk left and right, an entry's tags sit between its date and the delete cross
--     (right walks tags then the cross), X clears the search on every stop and shows only while there is one,
--     the help line's words name the tag
--   * the pick row at the Deck's width, Normal and Large text, every language: at most two lines
-- Run from the repo root:  lua51 ZeDUI/tools/qa/journal_tags_sim.lua
-- It prints FAIL lines and a last line "journal_tags_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]journal_tags_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

-- ---------------------------------------------------------------------------
-- THE WORDS: the real UI.json files, read line by line ("key": "value")
-- ---------------------------------------------------------------------------
local function readJson(lang)
    local f = assert(io.open(ROOT .. "42/media/lua/shared/Translate/" .. lang .. "/UI.json", "rb"))
    local out = {}
    for line in f:lines() do
        local k, v = line:match('^%s*"([^"]+)":%s*"(.*)",?%s*\r?$')
        if k then out[k] = v:gsub('\\"', '"'):gsub("\\\\", "\\") end
    end
    f:close()
    return out
end
local LANGS = { "EN", "AR", "CA", "CH", "CN", "CS", "DA", "DE", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT",
    "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
local WORDS = { EN = readJson("EN") }
local lang = "EN"

ZeD = {}
ZeD.tr = function(k, ...)
    local s = (WORDS[lang] and WORDS[lang][k]) or WORDS.EN[k] or k
    local args = { ... }
    return (s:gsub("%%(%d)", function(n) return tostring(args[tonumber(n)] or "") end))
end
ZeD.trTestOn = function() return false end
function getText(k) return ZeD.tr(k) end

-- ---------------------------------------------------------------------------
-- THE LOOK: tokens, a TextManager, a panel that writes down its draws
-- ---------------------------------------------------------------------------
local SCALE = 1
local CHARW = { F1 = 7, F2 = 7, F3 = 6 }   -- a letter's width per font (Normal text); Large text widens them
local FONTH = { F1 = 14, F2 = 16, F3 = 13 }
local function col(r, g, b) return { r = r, g = g, b = b, a = 1 } end
ZeD.T = {
    scale = SCALE, hair = 1, buttonH = 20, inputH = 20, disabledAlpha = 0.4, checkboxSz = 12,
    fontF1 = "F1", fontF2 = "F2", fontF3 = "F3", fontF5 = "F3",
    sp = { sm = 6, xs = 3, md = 10, rowGap = 2, afterGroove = 4, afterLine = 4, scrollbarW = 8, inputPadX = 4 },
    text = col(0.83, 0.83, 0.85), textSec = col(0.5, 0.5, 0.5), textDim = col(0.4, 0.4, 0.4),
    textOnFocus = col(0, 0, 0), toneNorm = col(0.6, 0.6, 0.6), stripe = col(0.2, 0.2, 0.2), borderS = col(0.3, 0.3, 0.3),
    labels = {}, labelsText = {},
}
ZeD.T.px = function(n) return n * ZeD.T.scale end
for i, k in ipairs({ "red", "orange", "yellow", "green", "blue", "teal", "purple", "pink" }) do
    ZeD.T.labels[k] = col(i / 10, 0.1, 0.1)
    ZeD.T.labelsText[k] = col(i / 10, 0.9, 0.9)
end

-- a string's width: an ASCII letter is one letter, a two-byte one too, a three-byte one (CJK, Thai) 1.6 letters
local function strW(font, s)
    local cw = CHARW[font] or 7
    local n = 0
    for ch in tostring(s):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        n = n + ((#ch >= 3) and 1.6 or 1)
    end
    return math.floor(n * cw * ZeD.T.scale + 0.5)
end
ZeD.TM = {
    getFontHeight = function(_, f) return (FONTH[f] or 14) * ZeD.T.scale end,
    MeasureStringX = function(_, f, s) return strW(f, s) end,
    MeasureStringY = function(_, f) return (FONTH[f] or 14) * ZeD.T.scale end,
}

local MOUSE = { x = -1000, y = -1000 }
local function newPanel()
    local p = { draws = {} }
    function p:drawRect(x, y, w, h, a, r, g, b) self.draws[#self.draws + 1] = { "rect", x, y, w, h, r, g, b } end
    function p:drawRectBorder(x, y, w, h, a, r, g, b) self.draws[#self.draws + 1] = { "border", x, y, w, h, r, g, b } end
    function p:drawText(s, x, y, r, g, b, a, f) self.draws[#self.draws + 1] = { "text", s, x, y, r, g, b, f } end
    function p:setStencilRect() end
    function p:clearStencilRect() end
    function p:getMouseX() return MOUSE.x end
    function p:getMouseY() return MOUSE.y end
    return p
end
local function texts(p)
    local out = {}
    for _, d in ipairs(p.draws) do if d[1] == "text" then out[#out + 1] = d end end
    return out
end
local function findText(p, s)
    for _, d in ipairs(p.draws) do if d[1] == "text" and d[2] == s then return d end end
    return nil
end

-- the library pieces the page calls (none of them under test here): the squares are recorded
local squares = {}
ZeD.Atoms = {
    wrapText = function(text) return { text } end,
    truncateText = function(s, font, w)
        if strW(font, s) <= w then return s end
        local out = s
        while #out > 0 and strW(font, out .. "...") > w do out = out:sub(1, -2) end
        return out .. "..."
    end,
    mouseIn = function(panel, x, y, w, h)
        local mx, my = panel:getMouseX(), panel:getMouseY()
        return mx >= x and mx < x + w and my >= y and my < y + h
    end,
    drawDividerH = function() end,
    drawBody = function(panel, s, x, y) panel:drawText(s, x, y, 1, 1, 1, 1, "F2") end,
    frame = function() end,
    drawStatusDot = function(panel, x, y, c, size) squares[#squares + 1] = { "dot", x, y, c, size } end,
    drawStatusHollow = function(panel, x, y, c, size) squares[#squares + 1] = { "hollow", x, y, c, size } end,
}
local M = {
    bandH = function() return 30 end,
    getTabHeaderH = function() return 32 end,
    popupMenuW = function() return 120 end,
    buttonW = function(s) return strW("F3", s) + 20 end,
    bandRoom = function(panel, x, w) return x, x + w end,
    drawSectionHeader = function() return 20 end,
    drawStatRowDot = function() return 16 end,
    drawStatRow = function() return 16 end,
    drawCategoryRow = function() return 15 end,
    drawEmptyLine = function() return 16 end,
    drawQuestionBand = function(panel, x, y, w) return 30, { x = x, y = y, w = 40, h = 20 }, { x = x + 50, y = y, w = 40, h = 20 } end,
}
ZeD.Molecules = setmetatable(M, { __index = function() return function() return 20 end end })
ZeD.Help = { last = nil, set = function(win, s) ZeD.Help.last = s end }
ZeD.Focus = { mark = function() return false end }
ZeD.CraftingCore = { due = function() return true end }
ZeD.KillTracker = { data = function() return nil end, total = function() return 0 end }
ZeD.paperTone = function(c) return c end
ZeD.Print = { media = function() return nil end }
ZeD.Notes = {}
ZeD_ScrollbarState = { new = function()
    local s = { scrollPos = 0 }
    function s:setScrollPos(v) self.scrollPos = v end
    function s:setBarSize() end
    function s:draw() end
    return s
end }
function instanceof() return false end
ISTimedActionQueue = { hasAction = function() return true end }

-- ---------------------------------------------------------------------------
-- THE PLAYER: modData, the clock, a bag with one notebook
-- ---------------------------------------------------------------------------
local NOTEBOOK = { id = 77 }
function NOTEBOOK:getCategory() return "Literature" end
function NOTEBOOK:canBeWrite() return true end
function NOTEBOOK:getID() return self.id end
function NOTEBOOK:getName() return "Supply runs" end
local bag = {}
local INV = { getItems = function() return { size = function() return #bag end, get = function(_, i) return bag[i + 1] end } end }
local P = { md = {}, hours = 24 * 83 }
function P:getModData() return self.md end
function P:getTimeSurvived() return "83 days" end
function P:getHoursSurvived() return self.hours end
function P:getInventory() return INV end
function P:getPlayerNum() return 0 end
function P:getDescriptor() return { getForename = function() return "Glen" end, getSurname = function() return "Finnegan" end } end
function P:getPerkLevel() return 0 end
local CLOCK = { month = 7, day = 29, year = 1993, hour = 14, tod = 14.2 }
function getGameTime()
    return {
        getMonth = function() return CLOCK.month end, getDay = function() return CLOCK.day end,
        getYear = function() return CLOCK.year end, getHour = function() return CLOCK.hour end,
        getTimeOfDay = function() return CLOCK.tod end,
        getStartYear = function() return 1993 end, getStartMonth = function() return 6 end, getStartDay = function() return 8 end,
        getDeathString = function() return "survived" end, getGameModeText = function() return nil end,
    }
end

-- ---------------------------------------------------------------------------
-- LOAD the real files (their requires are the drawing modules, stood in for above)
-- ---------------------------------------------------------------------------
local realRequire = require
require = function() end
dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_JournalReaders.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/JournalTab.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/Input/SpatialNav.lua")
require = realRequire
local JT, JR, N = ZeD.JournalTab, ZeD.JournalReaders, ZeD.SpatialNav
check("the page loads", JT and JT.render and JT.save and JT.tagFocusables)

-- the Character window's parts the page uses: the write box, the search, Save
local function newWin()
    local win = { _playerObj = P, _journalSubTab = 1, _journalGroupCollapsed = {}, _killsExpanded = false }
    win._journalScroll = ZeD_ScrollbarState:new()
    local box = { text = "" }
    function box:getText() return self.text end
    function box:clear() self.text = "" end
    function box:setX() end; function box:setY() end; function box:setWidth() end; function box:setHeight() end
    win._journalInput = box
    local field = { input = { t = "" }, _lastText = "" }
    function field.input:setText(t) self.t = t end
    function field.input:getText() return self.t end
    function field:getX() return 0 end; function field:getY() return 0 end
    function field:getWidth() return 0 end; function field:getHeight() return 0 end
    function field:setX() end; function field:setY() end; function field:setWidth() end; function field:setHeight() end
    function field:clear() self.input:setText(""); self._lastText = "" end
    win._journalSearch = field
    win._journalSearchText = ""
    local btn = { x = 0, y = 0 }
    function btn:getWidth() return 60 end; function btn:getX() return self.x end; function btn:getY() return self.y end
    function btn:setX(v) self.x = v end; function btn:setY(v) self.y = v end; function btn:setVisible() end
    win._journalSaveBtn = btn
    return win
end

local W, H = 480, 640
local function draw(win)
    squares = {}
    local p = newPanel()
    win._journalCache = nil
    JT.render(p, win, 0, 0, W, H)
    return p
end
local function entries() return P.md.ZeD_Journal and P.md.ZeD_Journal.entries or {} end
local function save(win, text)
    win._journalInput.text = text
    return JT.save(win, text)
end

-- ===========================================================================
section("the tags")
check("eight tags", #JT.TAGS == 8, #JT.TAGS)
local order = {}
for i, t in ipairs(JT.TAGS) do order[i] = t.k .. "=" .. t.lc end
check("tags and colors as approved", table.concat(order, " ") ==
    "danger=red loot=orange news=yellow food=green weather=blue base=teal travel=purple injury=pink", table.concat(order, " "))
for _, t in ipairs(JT.TAGS) do
    check("EN word for " .. t.k, WORDS.EN[t.key] ~= nil)
    check("EN help for " .. t.k .. " names it", WORDS.EN[t.help] and WORDS.EN[t.help]:sub(1, #WORDS.EN[t.key] + 1) == WORDS.EN[t.key] .. ":")
end
-- every language has the 19 keys
for _, l in ipairs(LANGS) do
    WORDS[l] = WORDS[l] or readJson(l)
    local n = 0
    for _, t in ipairs(JT.TAGS) do if WORDS[l][t.key] and WORDS[l][t.help] then n = n + 2 end end
    for _, k in ipairs({ "UI_ZeD_Journal_TagTick", "UI_ZeD_Journal_TagUntick", "UI_ZeD_Journal_TagShow" }) do
        if WORDS[l][k] then n = n + 1 end
    end
    check(l .. ": the 19 tag lines", n == 19, n)
    check(l .. ": Show keeps %1", (WORDS[l].UI_ZeD_Journal_TagShow or ""):find("%%1") ~= nil)
end

-- ===========================================================================
section("old entries draw as before")
P.md = { ZeD_Journal = { entries = {
    { month = 7, day = 25, year = 1993, hour = 15, minute = 5, survivalDay = 80, text = "generator needs fuel every 3 days" },
    { month = 7, day = 12, year = 1993, hour = 0, minute = 44, survivalDay = 67, text = "cleared the house on the corner" },
} } }
local win = newWin()
local p = draw(win)
check("old: no tag zones", #(win._journalTagZones or {}) == 0, #(win._journalTagZones or {}))
check("old: the eight picks drawn hollow", #squares == 8 and squares[1][1] == "hollow", #squares)
local stamp = nil
for _, d in ipairs(texts(p)) do if tostring(d[2]):find("^Day 80") then stamp = d end end
check("old: the date line drawn whole", stamp and not stamp[2]:find("%.%.%.$"), stamp and stamp[2])
check("old: no tags field added", entries()[1].tags == nil and entries()[2].tags == nil)

-- ===========================================================================
section("save with tags, the ticks clear")
check("nothing ticked: no tags", JT.pickedTags(win) == nil)
JT.togglePick(win, "base"); JT.togglePick(win, "loot"); JT.togglePick(win, "travel")
JT.togglePick(win, "travel")   -- (ticked, then unticked)
check("ticks in the row's order", table.concat(JT.pickedTags(win), ",") == "loot,base", table.concat(JT.pickedTags(win) or {}, ","))
p = draw(win)
local dots = 0
for _, s in ipairs(squares) do if s[1] == "dot" then dots = dots + 1 end end
check("two picks filled, six hollow", dots == 2, dots)
check("a ticked pick's word in its label color", (function()
    local d = findText(p, WORDS.EN.UI_ZeD_Journal_Tag_Loot)
    return d and d[5] == ZeD.T.labelsText.orange.r and d[6] == ZeD.T.labelsText.orange.g
end)())
check("an unticked pick's word in textSec", (function()
    local d = findText(p, WORDS.EN.UI_ZeD_Journal_Tag_Danger)
    return d and d[5] == ZeD.T.textSec.r
end)())
check("an empty box saves nothing", save(win, "") == false and #entries() == 2)
check("an empty box keeps the ticks", JT.pickedTags(win) ~= nil)
CLOCK.day, CLOCK.hour = 29, 14
save(win, "found a working generator in the barn past the farm")
local e1 = entries()[1]
check("saved on top", e1.text == "found a working generator in the barn past the farm")
check("saved with its tags, as keys", e1.tags and table.concat(e1.tags, ",") == "loot,base", e1.tags and table.concat(e1.tags, ","))
check("the ticks clear after Save", JT.pickedTags(win) == nil and win._journalPicks == nil)
check("the box clears after Save", win._journalInput.text == "")
check("the old entries are untouched", entries()[2].tags == nil and entries()[3].tags == nil and #entries() == 3)
save(win, "traded nothing with nobody")
check("no ticks: no tags field", entries()[1].tags == nil)
table.remove(entries(), 1)

-- ===========================================================================
section("an entry's tags in its head row")
p = draw(win)
local tz = win._journalTagZones
check("two tag zones on the tagged entry", #tz == 2, #tz)
local del1 = win._journalDeleteZones[1]
check("the tags sit left of the delete cross", tz[2].x + tz[2].w <= del1.x, tostring(tz[2].x + tz[2].w) .. " / " .. del1.x)
check("the tags keep their order", tz[1].k == "loot" and tz[2].k == "base" and tz[1].x < tz[2].x)
check("the tags' words drawn", findText(p, WORDS.EN.UI_ZeD_Journal_Tag_Base) ~= nil)
local dline = nil
for _, d in ipairs(texts(p)) do if tostring(d[2]):find("^Day 84") then dline = d end end
check("the date ends short of the tags", dline and dline[3] + strW("F3", dline[2]) <= tz[1].x, dline and dline[2])

-- ===========================================================================
section("the search: words and tags' words")
local function shown(w, q)
    w._journalGroupCache = nil
    local groups = JT.groups(w, entries(), q)
    local out = {}
    for _, g in ipairs(groups) do for _, wr in ipairs(g.entries) do out[#out + 1] = wr.entry.text end end
    return out
end
check("search by text", #shown(win, "corner") == 1)
check("search by a tag's word", #shown(win, "base") == 1 and shown(win, "base")[1]:find("generator in the barn") ~= nil)
check("search by a tag's word, any case", #shown(win, "LOOT") == 1)
check("a word matching nothing", #shown(win, "helicopter") == 0)
check("the text match still works on an untagged entry", #shown(win, "fuel") == 1)
lang = "DE"
check("DE: the tag's word in the player's language", #shown(win, "beute") == 1)
check("DE: the English word is not a tag there", #shown(win, "loot") == 0)
lang = "EN"
-- the cache: same search, same list -> the same groups; a new search rebuilds
win._journalGroupCache = nil
local g1 = JT.groups(win, entries(), "base")
check("the cache holds for the same search", JT.groups(win, entries(), "base") == g1)
check("a new search rebuilds", JT.groups(win, entries(), "loot") ~= g1)

-- ===========================================================================
section("a click on a tag searches; a click on a pick ticks")
p = draw(win)
local baseZ = nil
for _, z in ipairs(win._journalTagZones) do if z.k == "base" then baseZ = z end end
check("click a tag", JT.onBodyClick(win, baseZ.x + 1, baseZ.y + 1) == true)
check("its word is in the search", win._journalSearchText == "Base" and win._journalSearch.input:getText() == "Base",
    win._journalSearchText)
check("the field's poll will not filter again", win._journalSearch._lastText == "Base")
local pz = win._journalPickZones[1]
check("click a pick", JT.onBodyClick(win, pz.x + 1, pz.y + 1) == true and JT.isPicked(win, pz.k))
JT.onBodyClick(win, pz.x + 1, pz.y + 1)
check("click it again: unticked", not JT.isPicked(win, pz.k))
check("a click outside the view is not a tag's", JT.onBodyClick(win, pz.x + 1, H + 50) == false)
win._journalAsk = { entry = entries()[1] }
check("no tag clicks while the delete question is up", JT.onBodyClick(win, pz.x + 1, pz.y + 1) == false)
win._journalAsk = nil
MOUSE.x, MOUSE.y = baseZ.x + 1, baseZ.y + 1
ZeD.Help.last = nil
JT.setSearch(win, "")
p = draw(win)
check("hover a tag: the help line names it and what it is for", ZeD.Help.last == WORDS.EN.UI_ZeD_Journal_Tag_BaseHelp, ZeD.Help.last)
MOUSE.x, MOUSE.y = -1000, -1000

-- ===========================================================================
section("more than three tags: the squares alone")
JT.togglePick(win, "danger"); JT.togglePick(win, "loot"); JT.togglePick(win, "food"); JT.togglePick(win, "travel")
save(win, "found the gas station empty. took the map and two cans of beans")
check("four tags kept", #entries()[1].tags == 4)
p = draw(win)
local four = {}
for _, z in ipairs(win._journalTagZones) do if z.entryIdx == 1 then four[#four + 1] = z end end
check("four tag stops", #four == 4, #four)
check("squares alone: each zone a square's width", four[1].w == ZeD.T.px(7) and four[4].w == ZeD.T.px(7), four[1].w)
check("no words drawn for the four", (function()
    for _, d in ipairs(texts(p)) do
        if d[2] == "Food" and math.abs(d[4] - four[1].y) < 20 then return false end
    end
    return true
end)())
MOUSE.x, MOUSE.y = four[3].x + 1, four[3].y + 1
ZeD.Help.last = nil
draw(win)
check("the help line names a square", ZeD.Help.last == WORDS.EN.UI_ZeD_Journal_Tag_FoodHelp, ZeD.Help.last)
MOUSE.x, MOUSE.y = -1000, -1000
-- three tags keep their words; three long words in a narrow row go to squares
local lay3 = JT.tagLayout({ entry = { tags = { "danger", "loot", "news" } }, idx = 9 }, 400)
check("three tags: words", lay3.words == true)
local lay3n = JT.tagLayout({ entry = { tags = { "weather", "travel", "injury" } }, idx = 9 }, 200)
check("three tags with no room: the squares", lay3n.words == false)
local layU = JT.tagLayout({ entry = { tags = { "loot", "futurekey" } }, idx = 9 }, 400)
check("a tag this version does not know is left out", #layU.items == 1)

-- ===========================================================================
section("Into a notebook: the tags stay in the log only")
bag = { NOTEBOOK }
JR.refresh(win)         -- (the readers' state on the window, the bag scanned again)
win._jr.logInto = NOTEBOOK.id
local wrote = nil
ZeD.Notes.why = function() return nil end
ZeD.Notes.pageFor = function() return 3 end
ZeD.Notes.write = function(pl, b, page, text, done) wrote = { text = text, done = done, b = b }; return "action" end
local before = #entries()
JT.togglePick(win, "news"); JT.togglePick(win, "food")
win._journalInput.text = "waters off. filled every pot in the house first"
save(win, win._journalInput.text)
check("the notebook gets the words", wrote and wrote.text == "waters off. filled every pot in the house first")
check("the notebook's words carry no tag", wrote and not wrote.text:find("News") and not wrote.text:find("Food"))
check("nothing logged until it is written", #entries() == before)
check("the ticks wait for the write", JT.pickedTags(win) ~= nil)
wrote.done(3)
local en = entries()[1]
check("logged once written", #entries() == before + 1 and en.text == "waters off. filled every pot in the house first")
check("the log entry keeps the tags", en.tags and table.concat(en.tags, ",") == "news,food")
check("the log entry says where it went", en.source and en.source.name == "Supply runs" and en.source.page == 3)
check("the ticks clear once written", JT.pickedTags(win) == nil)
check("the box clears once written", win._journalInput.text == "")
ZeD.Notes.why = function() return "Too dark to write" end
JT.togglePick(win, "danger")
save(win, "smoke to the east")
check("a notebook that cannot be written: the ticks stay", JT.pickedTags(win) ~= nil)
JT.clearPicks(win)
win._jr.logInto = nil
bag = {}

-- ===========================================================================
section("PostDeath reads entries[1]")
Events = setmetatable({}, { __index = function(self, name)
    local ev = { Add = function() end, Remove = function() end }
    rawset(self, name, ev)
    return ev
end })
ISPostDeathUI = {}
ZeD.Safe = { on = function() return false end }
ZeD.KillTracker.settle = function() end
require = function() end
dofile(ROOT .. "42/media/lua/client/ZeD/Overrides/PostDeath.lua")
require = realRequire
ZeD.Death.capture(P)
check("the death record's last entry is the newest", ZeD.Death.records[0].last == entries()[1].text, ZeD.Death.records[0].last)
check("a tagged newest entry reads as its words", type(ZeD.Death.records[0].last) == "string" and entries()[1].tags ~= nil)

-- ===========================================================================
section("a modData round trip")
local function ser(v)
    if type(v) == "table" then
        local parts = {}
        for k, x in pairs(v) do
            parts[#parts + 1] = "[" .. (type(k) == "string" and string.format("%q", k) or tostring(k)) .. "]=" .. ser(x)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif type(v) == "string" then return string.format("%q", v) end
    return tostring(v)
end
p = draw(win)
local beforeTags = {}
for _, z in ipairs(win._journalTagZones) do beforeTags[#beforeTags + 1] = z.id .. "@" .. z.x end
local saved = ser(P.md)
P.md = loadstring("return " .. saved)()
local win2 = newWin()
draw(win2)
local afterTags = {}
for _, z in ipairs(win2._journalTagZones) do afterTags[#afterTags + 1] = z.id .. "@" .. z.x end
check("the tags survive the round trip", entries()[1].tags and table.concat(entries()[1].tags, ",") == "news,food")
check("the page draws the same tags after it", table.concat(beforeTags, " ") == table.concat(afterTags, " "),
    #beforeTags .. " / " .. #afterTags)
check("old entries still have none", entries()[#entries()].tags == nil)
win = win2

-- ===========================================================================
section("the pad's stops")
p = draw(win)
local stops = JT.tagFocusables(win)
local picks, etags = {}, {}
for _, s in ipairs(stops) do
    if s.journalKind == "tagPick" then picks[#picks + 1] = s elseif s.journalKind == "tag" then etags[#etags + 1] = s end
end
check("eight pick stops", #picks == 8, #picks)
-- the delete crosses, as the Character window's builder makes them
local dels = {}
for _, z in ipairs(win._journalDeleteZones) do
    if JT.inPadReach(win, z) then dels[#dels + 1] = { x = z.x, y = z.y, w = z.w, h = z.h, id = "journal:del:" .. z.entryIdx } end
end
local all = {}
for _, s in ipairs(stops) do all[#all + 1] = s end
for _, s in ipairs(dels) do all[#all + 1] = s end
JT.withClear(all)
local function go(from, dir)
    local others = {}
    for _, s in ipairs(all) do if s ~= from then others[#others + 1] = s end end
    return (N.pick(from, others, dir))
end
-- the picks: right walks them in order (wrapping to the next line), left back
local cur, walked = picks[1], { picks[1].tagKey }
for _ = 1, 7 do cur = go(cur, "right") or go(cur, "down"); walked[#walked + 1] = cur and cur.tagKey or "?" end
check("right walks the picks", table.concat(walked, ",") == "danger,loot,news,food,weather,base,travel,injury", table.concat(walked, ","))
check("left from Loot is Danger", go(picks[2], "left") == picks[1])
-- A ticks and unticks; the prompt follows
check("A's word on an unticked pick", picks[3].promptA(win, picks[3]) == "Tag")
picks[3].onActivate(win, picks[3])
check("A ticks", JT.isPicked(win, "news"))
check("A's word on a ticked pick", picks[3].promptA(win, picks[3]) == "Untag")
picks[3].onActivate(win, picks[3])
check("A again unticks", not JT.isPicked(win, "news"))
check("the help line's words beside the prompts name the tag", picks[1].extraPrompts[1] == WORDS.EN.UI_ZeD_Journal_Tag_DangerHelp)
-- an entry's tags: between the date and the delete cross; right walks the tags then the cross
local row = {}
for _, s in ipairs(etags) do if s.entryIdx == 1 then row[#row + 1] = s end end
check("the newest entry's two tag stops", #row == 2, #row)
local r1 = go(row[1], "right")
check("right from the first tag: the second", r1 == row[2])
local r2 = go(row[2], "right")
check("right from the last tag: the delete cross", r2 and r2.id == "journal:del:1", r2 and r2.id)
check("left from the cross: the last tag", go(r2, "left") == row[2])
check("A's word on an entry's tag", row[1].promptA == "Show News", row[1].promptA)
row[1].onActivate(win, row[1])
check("A on an entry's tag searches for it", win._journalSearchText == "News")
-- X: clears the search on any stop; its prompt only while there is one
check("X's prompt while searching", all[1].promptX(win) == "Clear")
r2.onContextMenu(win)
check("X clears the search", win._journalSearchText == "" and win._journalSearch.input:getText() == "")
check("no X prompt with no search", all[1].promptX(win) == false)
-- a long log: only the stops near the view
for i = 1, 120 do
    table.insert(entries(), { month = 5, day = i % 28, year = 1993, hour = 1, minute = 0, survivalDay = 1, text = "old " .. i, tags = { "food" } })
end
p = draw(win)
local nTags = 0
for _, s in ipairs(JT.tagFocusables(win)) do if s.journalKind == "tag" then nTags = nTags + 1 end end
check("a long log: tag stops only near the view", nTags > 0 and nTags < #win._journalTagZones, nTags .. " of " .. #win._journalTagZones)
local k1 = JT.padKey(win)
win._killsExpanded = true
draw(win)
check("the stops' key changes when the kills fold out", JT.padKey(win) ~= k1)

-- ===========================================================================
section("the pick row at the Deck's size (480 wide drawer, Normal and Large text)")
for _, sz in ipairs({ { "Normal", 6 }, { "Large", 8 } }) do
    CHARW.F3 = sz[2]
    for _, l in ipairs(LANGS) do
        lang = l
        local w = newWin()
        local lay = JT.pickLayout(w, W - 2 * 6 - 8 - 2)
        check(l .. " " .. sz[1] .. ": at most two lines", lay.rows <= 2, lay.rows)
    end
end
lang, CHARW.F3 = "EN", 6
local lay = JT.pickLayout(newWin(), W - 22)
check("EN Normal: one line", lay.rows == 1, lay.rows)

-- ===========================================================================
section("the Character window calls the page")
local cw = assert(io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_CharacterWindow.lua", "rb")):read("*a")
check("Save goes through JournalTab.save", cw:find("ZeD.JournalTab.save(win, journalInput:getText())", 1, true) ~= nil)
check("the click reaches the tags", cw:find("ZeD.JournalTab.onBodyClick(win, x, y)", 1, true) ~= nil)
local sub = cw:match("local function _buildJournalSubContent%(win%)(.-)\nend")
check("the stops include the tags", sub and sub:find("JT.tagFocusables(win)", 1, true) ~= nil)
check("the stops include the delete crosses", sub and sub:find("_buildJournalDeleteFocusables(win)", 1, true) ~= nil)
check("the stops get X", sub and sub:find("JT.withClear(elements)", 1, true) ~= nil)
check("the rebuild keys on padKey", cw:find("ZeD.JournalTab.padKey(win)", 1, true) ~= nil)

print(string.format("journal_tags_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
