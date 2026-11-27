-- ZeDUI/tools/qa/oc_foot_verbs_sim.lua  (Nov 26 2026; the object cards' verbs in the band at the foot, Hermit's call)
-- Every object card's verbs left the row under the title for the band at the card's foot, as the Mechanics tab's
-- footer and the trade card already had them: a danger verb leftmost, the rest, the primary one rightmost.
-- This sim cuts inOrder and verbRows out of the real ObjectCards.lua and runs them on stub widths at 1x. It checks:
--   ORDER   danger first, then the rest in the kind's order, the primary last; a greyed primary keeps the last place
--   ROWS    at 480 the generator's five verbs share one row; at 220 they wrap to rows that each fit the room, the
--           primary ending the bottom row; a verb wider than the whole room is cut to it
--   FIDS    each verb keeps its stop name oc:verb:<id>, the one the pad's landing (_mainFid) and QA's scripts use
--   SOURCE  the band draws the verbs as stops pinned with it (foot = true, verb = true); the row under the title
--           draws no push buttons; prerender gives the band its rows' height and a state line's strip
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_foot_verbs_sim.lua
-- It prints FAIL lines and a last line "oc_foot_verbs_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_foot_verbs_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function done()
    print("oc_foot_verbs_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(failed > 0 and 1 or 0)
end

local f = io.open(ROOT .. "42/media/lua/client/ZeD/ObjectCards.lua", "rb")
local src = f:read("*a"):gsub("\r\n", "\n"); f:close()

local fnOrder = src:match("(local function inOrder%(list%).-\nend)\n")
local fnRows = src:match("(local function verbRows%(self, w%).-\nend)\n")
check("inOrder is found in ObjectCards.lua", fnOrder ~= nil)
check("verbRows is found in ObjectCards.lua", fnRows ~= nil)
if not (fnOrder and fnRows) then done() end

-- stubs: 1 design unit = 1 px; a keycap is its words at 7 px a letter plus 24 of padding and rings
local CH, PADX = 7, 12
local M = { buttonW = function(label) return #(label or "") * CH + 2 * PADX end }
local A = { truncateText = function(s, font, w) local n = math.floor(w / CH) - 3; return s:sub(1, math.max(0, n)) .. "..." end }
local ZeD = { T = { px = function(n) return n end, fontF3 = "F3", sp = { buttonPadX = PADX } }, btnCase = function(s) return s end }
local chunk = assert(loadstring("local M, A, ZeD = ...\n" .. fnOrder .. "\n" .. fnRows .. "\nreturn inOrder, verbRows"))
local inOrder, verbRows = chunk(M, A, ZeD)

local function ids(list) local o = {} for i, v in ipairs(list) do o[i] = v.id end return table.concat(o, ",") end

-- ORDER: the fluid card (Pour primary, Switch, Empty danger) and the generator (Add fuel, Turn on primary, Fix,
-- Connect, Take); a greyed primary keeps its place
local fluid = { { id = "pour", primary = true }, { id = "switch" }, { id = "empty", danger = true } }
check("fluid: Empty, Switch, Pour", ids(inOrder(fluid)) == "empty,switch,pour", ids(inOrder(fluid)))
local fluidGrey = { { id = "pour", primary = true, enabled = false }, { id = "switch" }, { id = "empty", danger = true } }
check("fluid, Pour greyed: Pour still rightmost", ids(inOrder(fluidGrey)) == "empty,switch,pour", ids(inOrder(fluidGrey)))
local gen = { { id = "fuel", label = "Add fuel" }, { id = "power", label = "Turn on", primary = true }, { id = "fix", label = "Fix" },
    { id = "plug", label = "Connect" }, { id = "take", label = "Take" } }
local genO = inOrder(gen)
check("generator: the rest in order, Turn on last", ids(genO) == "fuel,fix,plug,take,power", ids(genO))
local fire = { { id = "fuel", label = "Add fuel" }, { id = "out", label = "Put out" }, { id = "light", label = "Light", primary = true },
    { id = "take", label = "Take apart", danger = true } }
check("campfire: Take apart first, Light last", ids(inOrder(fire)) == "take,fuel,out,light", ids(inOrder(fire)))

-- ROWS
local function rowsAt(list, w)
    local self = { _shown = inOrder(list) }
    return verbRows(self, w), self._shown
end
local function rowW(row) local s = 0 for i, b in ipairs(row) do s = s + b.bw + (i > 1 and 8 or 0) end return s end
local function lastOf(rows) local r = rows[#rows]; return r[#r] end

local r480 = rowsAt(gen, 480)
check("480: the generator's five verbs share one row", #r480 == 1, #r480)
check("480: Turn on ends the row", lastOf(r480).v.id == "power")
check("480: the row fits the room", rowW(r480[1]) <= 480 - 16, rowW(r480[1]))

local r220 = rowsAt(gen, 220)
check("220: the generator's verbs wrap to more rows", #r220 >= 2, #r220)
local fits, count = true, 0
for _, row in ipairs(r220) do
    if rowW(row) > 220 - 16 then fits = false end
    count = count + #row
end
check("220: every row fits the room", fits)
check("220: no verb lost or doubled", count == 5, count)
check("220: Turn on ends the bottom row", lastOf(r220).v.id == "power")
local seq = {}
for _, row in ipairs(r220) do for _, b in ipairs(row) do seq[#seq + 1] = b.v.id end end
check("220: the rows read in the band's order", table.concat(seq, ",") == ids(genO), table.concat(seq, ","))

local rFluid = rowsAt(fluid, 220)
check("220: the fluid card's three verbs fit one row", #rFluid == 1, #rFluid)

local long = { { id = "x", label = string.rep("W", 60), primary = true } }
local rLong = rowsAt(long, 220)
check("a verb wider than the room is cut to it", rLong[1][1].bw == 220 - 16 and rLong[1][1].label:sub(-3) == "...", rLong[1][1].bw)
check("no verbs: no band", rowsAt({}, 480) == nil)

-- FIDS
check("stop names stay oc:verb:<id>", r480[1][1].fid == "oc:verb:fuel" and lastOf(r480).fid == "oc:verb:power", r480[1][1].fid)

-- SOURCE
local band = src:match("(function ZeD_ObjectCard:drawVerbBand%(.-\nend)\n")
check("drawVerbBand is found", band ~= nil)
check("the band's verbs are stops pinned with it", band and band:find("foot = true, verb = true", 1, true) ~= nil)
check("the band marks the primary stop where the pad lands", band and band:find("primary = (b.fid == self._mainFid)", 1, true) ~= nil)
check("a verb runs through press (questions and jumps as before)", band and band:find("self:press(vv)", 1, true) ~= nil)
local dv = src:match("(function ZeD_ObjectCard:drawVerbs%(.-\nend)\n")
check("drawVerbs is found", dv ~= nil)
check("the row under the title draws no push buttons", dv and dv:find("UI.button(", 1, true) == nil)
check("drawVerbs still names the pad's landing verb", dv and dv:find("self._mainFid = mainFid", 1, true) ~= nil)
check("prerender sizes the band by its rows", src:find("footH = #vRows * M.bandH()", 1, true) ~= nil)
check("prerender draws the verbs' band", src:find("self:drawVerbBand(vRows, fy, w, status, fLines, win)", 1, true) ~= nil)
check("a question still takes the band first", src:find("if cf then\n        footH = M.bandH()", 1, true) ~= nil)

done()
