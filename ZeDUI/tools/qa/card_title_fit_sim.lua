-- ZeDUI/tools/qa/card_title_fit_sim.lua  (Nov 23 2026, Build; QA: the laundry's half card read "Wh... 2/3")
-- An object card's header row: the close X, the kind's icon, the name, and on the right the browse arrows with the
-- "n / m" count between them and the full-view key. On the half card (220) the name was cut to two letters.
-- The director's rule (as the inventory headings' headFit, "name wins"): the buttons give way before the name does,
-- the least used first: 1 the full-view key (the face still pops out from a click on it, a click on the machine,
-- A at the machine, its info row), 2 the count (the arrows stay), and the arrows only when even three letters and
-- the dots would not fit.
-- This sim cuts ZeD_ObjectCard:headFit and :drawHeader out of the real ObjectCards.lua (and CraftingCore's
-- truncText) and runs them on a stub card, at Small and Large text, with fonts measured at a fixed width per
-- letter (Fira Sans Condensed SemiBold 15 / 17 px: about 7 / 8 per letter; Fira Mono 11 / 13 px: 7 / 8). It checks:
--   HALF   a 220 card with "White Washing Machine", three of a kind and a full-view key: the key and the count are
--          gone, with no zone (no click, no pad stop); the arrows stay with their zones; the name shows at least
--          MIN_LETTERS letters
--   FULL   a 480 card shows everything and the whole name
--   NARROW a card too narrow for three letters beside the arrows drops the arrows too (no zones), and the name keeps
--          three letters
--   SHORT  a short name on a 300 card keeps every button
--   ALONE  one of a kind with no key: nothing gives way (level 0)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/card_title_fit_sim.lua
-- It prints FAIL lines and a last line "card_title_fit_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]card_title_fit_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function done()
    print("card_title_fit_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(failed > 0 and 1 or 0)
end

-- the fewest letters a long name keeps on the half card once the full-view key and the count gave way
-- (Small text: 7 "White W...", Large text: 4 "Whit...", at the letter widths above)
local MIN_LETTERS = 4

local function slurp(p)
    local f = io.open(ROOT .. p, "rb")
    if not f then return nil end
    local s = f:read("*a"):gsub("\r\n", "\n"); f:close()
    return s
end
local oc = slurp("42/media/lua/client/ZeD/ObjectCards.lua")
local cc = slurp("42/media/lua/client/ZeD/CraftingCore.lua")
check("ObjectCards.lua and CraftingCore.lua read", oc ~= nil and cc ~= nil)
if not (oc and cc) then done() end
local a = oc:find("function ZeD_ObjectCard:headFit(", 1, true)
local b = a and oc:find("\n    return nil\nend\n", a, true)
check("headFit and drawHeader are found", a ~= nil and b ~= nil)
local trunc = cc:match("(function CC%.truncText%(str, font, maxW%).-\nend)\n")
check("truncText is found", trunc ~= nil)
if not (a and b and trunc) then done() end
local cut = oc:sub(a, b + #"\n    return nil\nend")
check("drawHeader is cut whole", cut:find("function ZeD_ObjectCard:drawHeader(e, hh, win)", 1, true) ~= nil)

-- the fonts: a width per letter
local FONT = {}
local function setSize(large)
    FONT.f3 = { w = large and 8 or 7, h = large and 15 or 13 }
    FONT.f4 = { w = large and 8 or 7, h = large and 19 or 17 }
    ZeD.T.fontF3, ZeD.T.fontF4, ZeD.T.fontF1 = FONT.f3, FONT.f4, FONT.f3
    ZeD.T.buttonH = large and 30 or 26
end

ZeD = {
    T = { px = function(v) return v end, hair = 1, borderS = {}, textDim = { r = 1, g = 1, b = 1 }, textHead = { r = 1, g = 1, b = 1 } },
    TM = {
        MeasureStringX = function(_, font, s) return #tostring(s) * font.w end,
        getFontHeight = function(_, font) return font.h end,
    },
    tr = function(k) return k end,
    CraftingCore = {},
}
CC = ZeD.CraftingCore
assert(loadstring(trunc, "truncText"))()
ZeD_ObjectCard = {}
local noop = function() end
local M = { drawCloseKey = noop, drawIconButton = noop, drawTag = noop }
local A = { frame = noop, drawPxIcon = noop, drawDividerH = noop }
local UI = { tagW = function(s) return #s * 7 + 12 end }
local function kindCall(e, f, ...) if f then return f(...) end return nil end
local function tagMark(c) return c end
local OC = { browse = noop }
assert(loadstring("local M, A, UI, kindCall, tagMark, GLYPH_PREV, GLYPH_NEXT, OC = ...\n" .. cut, "drawHeader"))(
    M, A, UI, kindCall, tagMark, noop, noop, OC)

-- a stub card: records its zones and its texts
local function card(w)
    local c = { zones = {}, texts = {}, playerNum = 0, scroll = { setScrollPos = noop } }
    function c:getWidth() return w end
    function c:zone(z) self.zones[z.fid] = z end
    function c:drawText(s, x) self.texts[#self.texts + 1] = { s = s, x = x } end
    function c:drawTextureScaledAspect() end
    function c:focusOf() return false end
    function c:close() end
    return setmetatable(c, { __index = ZeD_ObjectCard })
end
local function entry(name, n, pop)
    local list = {}
    for i = 1, n do list[i] = {} end
    return { idx = 2, list = list, t = { obj = {} }, def = {
        title = function() return name end, icon = function() return nil end,
        popOut = pop and function() return true end or nil } }
end
-- the name is the text drawn at the name's x (right of the close X and the icon)
local function drawn(c)
    local cx = 8 + ZeD.T.buttonH + 6 + 22 + 8
    local name, count
    for _, t in ipairs(c.texts) do
        if t.x == cx then name = t.s elseif t.s:find(" / ", 1, true) then count = t.s end
    end
    return name, count
end
local function letters(s) return #(string.gsub(s or "", "%.%.%.$", "")) end

local LONG = "White Washing Machine"
for _, large in ipairs({ false, true }) do
    setSize(large)
    local sz = large and "Large" or "Small"
    -- HALF
    local c = card(220)
    c:drawHeader(entry(LONG, 3, true), 37, nil)
    local name, count = drawn(c)
    check(sz .. " HALF: the full-view key has no zone", c.zones["oc:pop"] == nil)
    check(sz .. " HALF: the count is not drawn", count == nil, count)
    check(sz .. " HALF: the arrows keep their zones", c.zones["oc:prev"] ~= nil and c.zones["oc:next"] ~= nil)
    check(sz .. " HALF: the close X keeps its zone", c.zones["oc:back"] ~= nil)
    check(sz .. " HALF: the name shows at least " .. MIN_LETTERS .. " letters", letters(name) >= MIN_LETTERS, name)
    check(sz .. " HALF: the level is 2", c._headFit == 2, c._headFit)
    local nameEnd = 8 + ZeD.T.buttonH + 6 + 22 + 8 + #(name or "") * FONT.f4.w
    check(sz .. " HALF: the name ends left of the arrows", c.zones["oc:prev"] and nameEnd <= c.zones["oc:prev"].x, nameEnd)
    print(sz .. " HALF 220: \"" .. tostring(name) .. "\"")
    -- FULL
    c = card(480)
    c:drawHeader(entry(LONG, 3, true), 37, nil)
    name, count = drawn(c)
    check(sz .. " FULL: every button has its zone", c.zones["oc:pop"] and c.zones["oc:prev"] and c.zones["oc:next"])
    check(sz .. " FULL: the count shows", count == "2 / 3", count)
    check(sz .. " FULL: the whole name shows", name == LONG, name)
    -- NARROW: not even three letters beside the arrows
    c = card(large and 150 or 140)
    c:drawHeader(entry(LONG, 3, true), 37, nil)
    name = drawn(c)
    check(sz .. " NARROW: the arrows give way too", c.zones["oc:prev"] == nil and c.zones["oc:next"] == nil and c._headFit == 3, c._headFit)
    check(sz .. " NARROW: the name keeps three letters", letters(name) >= 3, name)
    -- SHORT: a short name keeps every button on a card with room for it (300; on 220 the buttons alone leave a
    -- name no room, so any name there takes the key's and the count's room)
    c = card(300)
    c:drawHeader(entry("Dryer", 3, true), 37, nil)
    name, count = drawn(c)
    check(sz .. " SHORT: every button stays", c.zones["oc:pop"] and c.zones["oc:prev"] and count == "2 / 3" and c._headFit == 0, c._headFit)
    check(sz .. " SHORT: the whole name shows", name == "Dryer", name)
    -- one of a kind, no key: nothing to give way, the name is cut as before
    c = card(220)
    c:drawHeader(entry(LONG, 1, false), 37, nil)
    check(sz .. " ALONE: no buttons, level 0", c._headFit == 0 and c.zones["oc:prev"] == nil, c._headFit)
end

done()
