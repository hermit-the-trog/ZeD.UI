-- ZeDUI/tools/qa/print_page_fit_sim.lua  (Nov 12 2026, QA b12 round 2): ZeD's own setting of a printed page
-- (ZeD_PrintPage.lua P.page, what the Journal's thumbnails and the reader's fallback draw) with no game running. The
-- real file on Lua 5.1 stubs of the text manager (a letter is half its size wide, a line its size tall) and of the
-- game's layout strings. It checks:
--   NARROW  something beside a story's column narrows it; something that would leave less than half of it (or under
--           40 units) is above or below it, not beside it, and leaves it whole (Knox Knews July 1: story 2 cut to 3
--           units at x 519 by a headline measured taller than the game sets it, the whole page's body at 0.46)
--   FLOOR   the body steps down to 11.5 and that floor is tried (National Dispatch July 6 stopped at 11.58 untried);
--           a story still too long there with only the page foot under it runs to the page's edge (GAP), and every
--           story's lines end inside its room
-- Run from the repo root:  lua51 ZeDUI/tools/qa/print_page_fit_sim.lua
-- It prints FAIL lines and a last line "print_page_fit_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]print_page_fit_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- the game's string helpers (PZ adds them to string)
function string.split(s, sep)
    local out, i = {}, 1
    while true do
        local a, b = string.find(s, sep, i, true)
        if not a then out[#out + 1] = string.sub(s, i); break end
        out[#out + 1] = string.sub(s, i, a - 1)
        i = b + 1
    end
    return out
end
function string.trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
UIFont = { SdfOldRegular = "R", SdfOldBold = "B", SdfOldItalic = "I" }
function getTextManager()
    return { MeasureStringX = function(_, f, s) return #tostring(s) * 16 end, getFontHeight = function() return 32 end }
end
local LAYOUT = {}
function getTextOrNull(k) return LAYOUT[k] end
function getText(k) return k end
ZeD = { paperTone = function(c) return c end, tr = function(k) return k end }

local okL, errL = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/ZeD_PrintPage.lua")
check("ZeD_PrintPage.lua loads", okL, errL)
local P = ZeD.Print

local function words(n) local t = {} for i = 1, n do t[i] = "abcd" end return table.concat(t, " ") end
local function body(x, y, w, n) return "<type:text,x:" .. x .. ",y:" .. y .. ",autoWidth:" .. w .. ",font:SdfOldRegular>" .. words(n) end
local function box(x, y, w, h) return "<type:texture,x:" .. x .. ",y:" .. y .. ",width:" .. w .. ",height:" .. h .. ">" end
local function page(id, s) LAYOUT[id] = "<type:parent,width:805,height:910>" .. s; return P.page({ id = id, info = id }) end
-- the lowest line the page sets for a story (its lines lie between its top and the next story's)
local function inRoom(pg)
    for _, st in ipairs(pg.stories) do
        for _, l in ipairs(pg.lines) do
            if l.x == st.x and l.y >= st.top and l.y + l.size > st.bottom + 0.01 then return false, l.y + l.size end
        end
    end
    return true
end

-- NARROW: Knox Knews July 1's shape: story 2's column x 305 w 217; a box from x 22 to 509 on its rows (the story 1
-- headline as measured) would cut it to x 519, w 3
local pg = page("July1", box(22, 600, 487, 160) .. body(305, 700, 217, 60))
local st = pg and pg.stories[1]
check("NARROW: the story found", st ~= nil)
check("NARROW: a box that would leave 3 units is not beside the column: kept whole", st and st.x == 305 and st.w == 217,
    st and (st.x .. " w " .. st.w))
check("NARROW: the body at 11.5 or more, not 0.46", pg and pg.body >= 11.5, pg and pg.body)
-- a picture really beside the column (a third of it): the column narrows to the gap
pg = page("Beside", box(455, 680, 100, 120) .. body(305, 700, 217, 60))
st = pg and pg.stories[1]
check("NARROW: a picture beside it narrows it", st and st.x == 305 and st.w == 140, st and st.w)
pg = page("BesideL", box(250, 680, 120, 120) .. body(305, 700, 217, 60))
st = pg and pg.stories[1]
check("NARROW: a picture over its left side moves its left edge", st and st.x == 380 and st.w == 142, st and (st.x .. " w " .. st.w))

-- FLOOR: a story at y 430 with nothing under it: 280 words, 7 to a line at 11.5 (40 lines, 460 units): its room to
-- the foot is 456, to the page's edge 470
pg = page("July6", body(305, 430, 217, 280))
st = pg and pg.stories[1]
check("FLOOR: the floor itself tried: body 11.5", pg and pg.body == 11.5, pg and pg.body)
check("FLOOR: too long for the foot: runs to the page's edge", st and st.bottom == 910 - 10, st and st.bottom)
local okR, at = inRoom(pg)
check("FLOOR: every line inside its room", okR, at)
-- a story that fits keeps the foot
pg = page("Short", body(305, 430, 217, 140))
st = pg and pg.stories[1]
check("FLOOR: a story that fits keeps its room to the foot", st and st.bottom == 910 - 24 and pg.body > 11.5, st and st.bottom)
-- a story with something set under it keeps that bottom even at the floor
pg = page("Under", body(305, 430, 217, 280) .. box(300, 870, 230, 20))
st = pg and pg.stories[1]
check("FLOOR: a story with something under it keeps that bottom", st and st.bottom == 860 and pg.body == 11.5, st and st.bottom)

print("print_page_fit_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
