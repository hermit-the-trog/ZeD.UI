-- ZeDUI/tools/qa/ctx_reqtip_sim.lua  (Nov 8 2026, redrawn for the beta 10 balloon): the requirement tooltip on a
-- disabled menu option (World menu > Disassemble > Mahogany Drawers, the Mac's beta9-test2 picture) in both menu
-- looks, with no game running. The tooltip string is built the way ISDisassembleMenu.createMenu builds it (<RGB:..>
-- label <SETX:n> <INDENT:n> <RGB:..> value <LINE> <INDENT:0>), the option goes through the real Registry
-- makeActionDef, and the real strip balloon (Molecules drawContextBalloon) and list balloon (ZeD_ContextList's
-- _drawBalloon) draw it through the real Balloon.lua on panels that write down every drawText.
--   ONCE     every requirement drawn once (no second, small grey copy); the Name row left out (the title says it)
--   COLOR    what the player has in positiveText, what is missing in dangerText, the labels in the text color
--   COLUMNS  every value starts at one x, right of the widest label and the mark; each value on its own row
--   PIC      the tooltip's picture first
--   TAIL     the strip's balloon points at the selected cell (the strip's own cell rect), the list's at its row
--   PLAIN    a plain tooltip, live and gated, is still drawn once in the text color (strip and list)
-- Run from the repo root: lua51 ZeDUI/tools/qa/ctx_reqtip_sim.lua
local LUA = "42/media/lua/client/ZeD/"

local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local function cut(src, head)
    local a = assert(src:find(head, 1, true), head)
    local _, b = src:find("\nend\n", a, true)
    return src:sub(a, b)
end
local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end

-- ---- the stubs
local GOOD = { r = 0.25, g = 0.85, b = 0.25 }
local BAD  = { r = 0.9,  g = 0.2,  b = 0.2 }
local NOW = 5000
local function ci(c) return { getR = function() return c.r end, getG = function() return c.g end, getB = function() return c.b end } end
local CORE = {
    getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end,
    getGoodHighlitedColor = function() return ci(GOOD) end, getBadHighlitedColor = function() return ci(BAD) end,
}
function getCore() return CORE end
function getTimestampMs() return NOW end
function getMouseX() return -1 end
function getMouseY() return -1 end
require = function() end
local noop = function() end

ZeD = {}
local function C(r, g, b) return { r = r, g = g, b = b, a = 1 } end
ZeD.T = { px = function(v) return v end, hair = 1, line = function(n) return n or 1 end, scale = 1, borderW = 1,
          fontF1 = { n = 1 }, fontF2 = { n = 2 }, fontF3 = { n = 3 }, fontF4 = { n = 4 }, fontF5 = { n = 5 },
          surf2 = C(0.11, 0.11, 0.11), surf3 = C(0.14, 0.14, 0.14), borderS = C(0.22, 0.22, 0.22),
          text = C(0.85, 0.85, 0.85), textHead = C(0.9, 0.9, 0.9), textSec = C(0.6, 0.6, 0.6), textDim = C(0.6, 0.6, 0.6),
          positiveText = C(0.48, 0.60, 0.20), dangerText = C(0.87, 0.44, 0.27), positive = C(0.48, 0.6, 0.2), danger = C(0.77, 0.35, 0.16) }
-- the measure: a letter 8 px in F4 (9 at Large), 7 in the others; a space 4 px (3 in the others); and, as the game's
-- measure seems to, a trailing space counts for nothing (QA's "Disassemble> Metal Cabinet")
local LARGE = false
ZeD.TM = { MeasureStringX = function(_, f, s)
               s = tostring(s):gsub(" +$", "")
               local sp = select(2, s:gsub(" ", ""))
               local cw = (f.n == 4) and (LARGE and 9 or 8) or 7
               return (#s - sp) * cw + sp * ((f.n == 4) and 4 or 3)
           end,
           getFontHeight = function(_, f) return (f.n == 4) and (LARGE and 21 or 18) or 15 end }
local EPOCH = 1
ZeD.Text = { measureEpoch = function() return EPOCH end }
ZeD.Atoms = setmetatable({ drawHardShadow = noop,
    frame = function(p, x, y, w, h, c, a, t) t = t or 1; p:drawRect(x, y, w, t, 1, c.r, c.g, c.b) end },
    { __index = function() return noop end })

local function recorder(ax, ay)
    local p = { calls = {}, rects = {}, ax = ax or 0, ay = ay or 0 }
    function p:getAbsoluteX() return self.ax end
    function p:getAbsoluteY() return self.ay end
    function p:drawText(s, x, y, r, g, b, a, f) self.calls[#self.calls + 1] = { s = s, x = x, y = y, r = r, g = g, b = b, f = f } end
    function p:drawRect(x, y, w, h, a, r, g, b) self.rects[#self.rects + 1] = { x = x, y = y, w = w, h = h, r = r, g = g, b = b } end
    function p:drawTextureScaledAspect(t, x, y, w, h) self.pic = { x = x, y = y } end
    return p
end
local function find(p, s)
    local hits = {}
    for _, c in ipairs(p.calls) do if c.s == s then hits[#hits + 1] = c end end
    return hits
end

-- ---- the real files
assert(loadstring(slurp(LUA .. "Balloon.lua")))()
assert(loadstring(slurp(LUA .. "RichTip.lua")))()
local reg = slurp(LUA .. "ContextMenuRegistry.lua")
Registry = { categorize = function() return "ACTION" end }
idFromName = function(name) return name end
resolveIconForName = function() return nil end
plainTip = assert(loadstring(cut(reg, "local function plainTip(s)"):gsub("^local function plainTip%(s%)", "return function(s)", 1)))()
makeActionDef = assert(loadstring(cut(reg, "local function makeActionDef(option, index, vanillaMenu, target)")
    :gsub("^local function makeActionDef%(", "return function(", 1)))()
ZeD.Molecules = {}
local mol = slurp(LUA .. "Molecules.lua")
local a0 = assert(mol:find("local _ctxA = {}", 1, true))
assert(loadstring(mol:sub(a0, select(2, mol:find("\nend\n", mol:find("function ZeD.Molecules.drawContextBalloon(", a0, true), true)))))()
ZeD_ContextList = {}
local cl = slurp(LUA .. "ZeD_ContextList.lua")
assert(loadstring(cut(cl, "function ZeD_ContextList:_pathTo(")))()
assert(loadstring(cut(cl, "function ZeD_ContextList:_drawBalloon(")))()
ZeD_ContextMenu = {}
local cm = slurp(LUA .. "ZeD_ContextMenu.lua")
local c0 = assert(cm:find("local _cellR = ", 1, true))
assert(loadstring(cm:sub(c0, select(2, cm:find("\nend\n", cm:find("function ZeD_ContextMenu:_selectedCellRect(", c0, true), true)))))()

-- ---- the game's tooltip, built as ISDisassembleMenu.createMenu builds it
local W, R, G = { 255, 255, 255 }, { BAD.r * 255, BAD.g * 255, BAD.b * 255 }, { GOOD.r * 255, GOOD.g * 255, GOOD.b * 255 }
local function L(a, ca, b, cb)
    local t = { { txt = a, r = ca[1], g = ca[2], b = ca[3] } }
    if b then t[2] = { txt = b, r = cb[1], g = cb[2], b = cb[3] } end
    return t
end
local infoTable = {
    L("Name:", W, "Mahogany Drawers", W), L("Skill:", W, "Carpentry", G),
    L("Tool needed:", W, "Ball-peen Hammer", G), L("", W, "Claw Hammer", G), L("", W, "Smithing Hammer", G), L("", W, "Stone Hammer", G),
    L("Tool needed:", W, "Hacksaw", R), L("", W, "Simple Wood Saw", R), L("", W, "Wood Saw", R),
    L("- Has items in container.", R),
}
local desc = ""
for _, t1 in ipairs(infoTable) do
    desc = string.format("%s <RGB:%.2f,%.2f,%.2f> %s", desc, t1[1].r / 255, t1[1].g / 255, t1[1].b / 255, t1[1].txt)
    if #t1 == 2 then
        desc = string.format("%s <SETX:%d> <INDENT:%d> <RGB:%.2f,%.2f,%.2f> %s", desc, 96, 96, t1[2].r / 255, t1[2].g / 255, t1[2].b / 255, t1[2].txt)
    end
    desc = desc .. " <LINE> <INDENT:0> "
end

-- ---- the two looks
local CELL = { x = 600, y = 500, w = 22, h = 22 }
local function strip(def)
    local p = recorder(0, 0)
    NOW = NOW + 1000
    p._zedBalloonC = nil
    ZeD.Molecules.drawContextBalloon(p, 611, 498, {
        labelText = def.name, parentChain = { "Disassemble" }, bodyText = def.body or "", bodyRich = def.bodyRich,
        pic = def.bodyRich and def.tipTex, stateText = def.state(nil) or "", stateKind = def.stateKind(nil), pointerDir = "down",
        anchor = CELL, below = 524, key = "s" .. NOW }, ZeD.T)
    return p
end
local function list(def)
    local p = setmetatable(recorder(0, 0), { __index = ZeD_ContextList })
    p._levels = { { rows = {} } }
    p._ctx = { target = nil }
    NOW = NOW + 1000
    ZeD_ContextList._drawBalloon(p, { def = def, li = 1, body = def.body or "", st = def.state(nil) or "", key = "1:" .. NOW,
                                      a = { x = 100, y = 200, w = 300, h = 24 } })
    return p
end

local option = { name = "Mahogany Drawers", notAvailable = true, toolTip = { description = desc, texture = { tex = true } } }
local def = makeActionDef(option, 1, nil, nil)
ok(def.bodyRich ~= nil, "the Registry keeps the requirement list")
ok(def.tipTex ~= nil, "the Registry keeps the tooltip's picture")

local HAVE = { "Carpentry", "Ball-peen Hammer", "Claw Hammer", "Smithing Hammer", "Stone Hammer" }
local MISSING = { "Hacksaw", "Simple Wood Saw", "Wood Saw", "Has items in container." }
local VALUES = { "Carpentry", "Ball-peen Hammer", "Claw Hammer", "Smithing Hammer", "Stone Hammer", "Hacksaw", "Simple Wood Saw", "Wood Saw" }
local T = ZeD.T
local function same(c, t) return c and c.r == t.r and c.g == t.g and c.b == t.b end

for _, look in ipairs({ { "strip", strip }, { "list", list } }) do
    local name, draw = look[1], look[2]
    local p = draw(def)
    for _, s in ipairs(VALUES) do ok(#find(p, s) == 1, name .. " ONCE " .. s .. " drawn " .. #find(p, s) .. "x") end
    ok(#find(p, "Has items in container.") == 1, name .. " ONCE the container line, its dash dropped")
    ok(#find(p, "- Has items in container.") == 0, name .. " ONCE no dash")
    ok(#find(p, "Tool needed") == 2, name .. " ONCE the two Tool needed labels")
    ok(#find(p, "Name") == 0 and #find(p, "Mahogany") == 1, name .. " ONCE the Name row left out, the title drawn once")
    for _, s in ipairs(HAVE) do ok(same(find(p, s)[1], T.positiveText), name .. " COLOR have " .. s) end
    for _, s in ipairs(MISSING) do ok(same(find(p, s)[1], T.dangerText), name .. " COLOR missing " .. s) end
    ok(same(find(p, "Skill")[1], T.text), name .. " COLOR the label in the text color")
    local x0 = find(p, "Carpentry")[1]
    x0 = x0 and x0.x
    for _, s in ipairs(VALUES) do
        local c = find(p, s)[1]
        ok(c and x0 and c.x == x0, name .. " COLUMNS " .. s .. " at the value column")
    end
    local tn = find(p, "Tool needed")[1]
    ok(tn and x0 and x0 >= tn.x + ZeD.TM:MeasureStringX(T.fontF2, "Tool needed") + 8 + 7, name .. " COLUMNS values clear the widest label and the mark")
    local hs, ss = find(p, "Hacksaw")[1], find(p, "Simple Wood Saw")[1]
    ok(hs and ss and ss.y > hs.y, name .. " COLUMNS each value on its own row")
    local tn2 = find(p, "Tool needed")[2]
    ok(tn2 and hs and tn2.y == hs.y, name .. " COLUMNS the label and its value on one row")
    ok(p.pic and tn and p.pic.x < tn.x, name .. " PIC the picture first")
    local pl = ZeD.Balloon.lastPlace
    if name == "strip" then
        ok(pl.side == "above" and pl.tipX >= CELL.x and pl.tipX < CELL.x + CELL.w, name .. " TAIL the tip on the selected cell")
    else
        ok(pl.side == "right" and pl.tipY >= 200 and pl.tipY < 224, name .. " TAIL the tip at the row's height, beside it")
    end
    -- the path in textSec, the title in textHead
    ok(same(find(p, "Disassemble")[1] or (name == "list" and { r = T.textSec.r, g = T.textSec.g, b = T.textSec.b }), T.textSec), name .. " the path in textSec")
end

-- DEBUG: with debug on the game adds "SCRIPT NAME:" and the sprite's name in magenta (ISMoveableSpriteProps
-- getInfoPanelDescription). Not a requirement: plain words in the text color, no column, no mark, once.
do
    local M = { 255, 0, 255 }
    local info2 = { infoTable[1], L("SCRIPT NAME:", M, "furniture_storage_02_0", M) }
    for i = 2, #infoTable do info2[#info2 + 1] = infoTable[i] end
    local d2 = ""
    for _, t1 in ipairs(info2) do
        d2 = string.format("%s <RGB:%.2f,%.2f,%.2f> %s", d2, t1[1].r / 255, t1[1].g / 255, t1[1].b / 255, t1[1].txt)
        if #t1 == 2 then
            d2 = string.format("%s <SETX:%d> <INDENT:%d> <RGB:%.2f,%.2f,%.2f> %s", d2, 96, 96, t1[2].r / 255, t1[2].g / 255, t1[2].b / 255, t1[2].txt)
        end
        d2 = d2 .. " <LINE> <INDENT:0> "
    end
    local dd = makeActionDef({ name = "Mahogany Drawers", notAvailable = true, toolTip = { description = d2 } }, 1, nil, nil)
    local m = dd.bodyRich
    local asRow = false
    for _, r in ipairs(m and m.rows or {}) do if r.label:find("SCRIPT", 1, true) then asRow = true end end
    ok(m and not asRow and #m.rows == 3, "DEBUG the script name line is not a requirement row")
    local info
    for _, k in ipairs(m and m.conds or {}) do if k.t:find("SCRIPT NAME", 1, true) then info = k end end
    ok(info and info.st == nil and info.t == "SCRIPT NAME: furniture_storage_02_0", "DEBUG it is a plain line with no mark (" .. tostring(info and info.t) .. ")")
    ok(ZeD.RichTip.state({ r = 1, g = 0, b = 1 }) == nil, "DEBUG magenta is neither met nor missing")
    ok(ZeD.RichTip.state({ r = 1, g = 0, b = 0 }) == "bad" and ZeD.RichTip.state({ r = 0, g = 1, b = 0 }) == "ok", "DEBUG a plain red / green still reads missing / met")
    for _, look in ipairs({ { "strip", strip }, { "list", list } }) do
        local p = look[2](dd)
        local hits = find(p, "SCRIPT NAME: furniture_storage_02_0")
        ok(#hits == 1 and same(hits[1], T.text), "DEBUG " .. look[1] .. ": drawn once, plain, in the text color")
        local markY = hits[1] and hits[1].y
        local marked = false
        for _, r in ipairs(p.rects) do
            if markY and r.y >= markY and r.y < markY + 15 and (same(r, T.dangerText) or same(r, T.positiveText)) then marked = true end
        end
        ok(not marked, "DEBUG " .. look[1] .. ": no check or cross on it")
    end
end

-- PLAIN: a tooltip without tags, live and gated, still drawn once in the text color
for _, gated in ipairs({ false, true }) do
    local o = { name = "Open can", notAvailable = gated, toolTip = { description = "Needs a can opener" } }
    local d = makeActionDef(o, 1, nil, nil)
    ok(d.bodyRich == nil, "PLAIN no rich layout for a plain tooltip")
    for _, look in ipairs({ { "strip", strip }, { "list", list } }) do
        local p = look[2](d)
        local n = 0
        for _, c in ipairs(p.calls) do if c.s:find("opener", 1, true) then n = n + 1 end end
        ok(n == 1, "PLAIN " .. look[1] .. " drawn once (gated " .. tostring(gated) .. ", drawn " .. n .. "x)")
        local hit
        for _, c in ipairs(p.calls) do if c.s:find("opener", 1, true) then hit = c end end
        ok(same(hit, T.text), "PLAIN " .. look[1] .. " in the text color (gated " .. tostring(gated) .. ")")
    end
end

-- GAP: the title "Disassemble > Mahogany Drawers": at least one space between every pair of words, ">" included,
-- in the strip and the list, Small and Large text (the trailing-space measure above dropped them all before)
for _, large in ipairs({ false, true }) do
    LARGE, EPOCH = large, EPOCH + 1
    local spaceW = 4
    for _, look in ipairs({ { "strip", strip }, { "list", list } }) do
        local p
        if look[1] == "list" then
            -- (the list's path is the parent row's name: a level with Disassemble open)
            local lp = setmetatable(recorder(0, 0), { __index = ZeD_ContextList })
            lp._levels = { { rows = { { def = { name = "Disassemble" } } } }, { parentRow = 1, rows = {} } }
            lp._ctx = { target = nil }
            NOW = NOW + 1000
            ZeD_ContextList._drawBalloon(lp, { def = def, li = 2, body = def.body or "", st = def.state(nil) or "", key = "2:" .. NOW,
                                               a = { x = 100, y = 200, w = 300, h = 24 } })
            p = lp
        else
            p = look[2](def)
        end
        local words = {}
        for _, w in ipairs({ "Disassemble", ">", "Mahogany", "Drawers" }) do words[#words + 1] = find(p, w)[1] end
        local good = #words == 4
        for i = 1, 3 do
            local a, b = words[i], words[i + 1]
            if not (a and b) then good = false
            elseif b.y == a.y then
                local g = b.x - (a.x + ZeD.TM:MeasureStringX(T.fontF4, a.s))
                if g < spaceW then good = false; print("  gap " .. a.s .. " | " .. b.s .. " = " .. g) end
            end
        end
        ok(good, "GAP " .. look[1] .. (large and " Large" or " Small") .. ": a space or more around \">\" and between the title's words")
    end
end
LARGE, EPOCH = false, EPOCH + 1

-- TAIL: the strip's selected cell, from this frame's hit zones (a carousel draws a cell up to three times)
do
    local m = { _ctx = { items = { 1, 2, 3, 4, 5 }, selected = 2 }, _hitZones = {} }
    for i = 1, 15 do m._hitZones[#m._hitZones + 1] = { id = "ctxcell_" .. i, x = (i - 6) * 23, y = 10, w = 22, h = 22 } end
    local r = ZeD_ContextMenu._selectedCellRect(m, { stripX = 0, stripW = 115, stripY = 9, innerY = 10 })
    ok(r.x == 23 and r.w == 22 and r.y == 10, "TAIL the strip's selected cell is the copy inside the strip (" .. r.x .. "," .. r.w .. ")")
end

print(string.format("ctx_reqtip_sim: %d pass, %d fail", pass, fail))
if fail > 0 then os.exit(1) end
