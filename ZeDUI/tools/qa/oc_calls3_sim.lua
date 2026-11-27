-- ZeDUI/tools/qa/oc_calls3_sim.lua (the director's calls TG5, LK5, OC4, Nov 26 2026): three object card calls, with
-- no game running. The real ObjectCardTrough.lua and ObjectCardLock.lua run on stubs; the World window's held-in
-- rule and the object card's drawer width, and the card host's narrow test, are cut from their files.
--   TG5  the trough: one press of Add moves one carrot of ten, Add All beside it moves the ten; Take and Take All
--        the same from the trough; a kind of one has no All button
--   LK5  a wrong padlock code queues nothing (no walk, no 20-tick try) and says so at once; the right one walks and
--        queues the game's action as before
--   OC4  at 1280 wide with the inventory open a full object card is the half card (the tabs' held-in rule); at 4K,
--        with the inventory hidden or with multi-column Loot it stays the full card; the card host treats a full kind
--        drawn at the half card as a half card (its long foot words wrap)
-- (The washer's lamps, the fourth call, are in oc_laundry_sim.lua.)
-- Each check fails on the code before these calls.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_calls3_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_calls3_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb"); if not f then return nil end
    local s = f:read("*a"); f:close(); return (string.gsub(s, "\r\n", "\n"))
end
local function noop() end

-- ---------------------------------------------------------------------------
-- STUBS
-- ---------------------------------------------------------------------------
require = noop
local realPrint = print
print = function(s) if type(s) == "string" and s:sub(1, 5) == "[ZeD]" then return end realPrint(s) end
getText = function(k) return k end
getTextOrNull = function(k) return nil end
getTimestampMs = function() return 1000 end
Events = setmetatable({}, { __index = function(t, k) local e = { Add = noop, Remove = noop }; rawset(t, k, e); return e end })
Keyboard = { KEY_BACK = 14 }
for n = 0, 9 do Keyboard["KEY_" .. n] = 100 + n; Keyboard["KEY_NUMPAD" .. n] = 200 + n end
instanceof = function(o, cls) return type(o) == "table" and o._cls == cls end
local QUEUED = {}
ISTimedActionQueue = { getTimedActionQueue = function() return { queue = {} } end,
                       add = function(a) QUEUED[#QUEUED + 1] = a end }
ISPadlockByCodeAction = { new = function(self, p, thump, pad, lock, code)
    return { Type = "ISPadlockByCodeAction", thump = thump, padlock = pad, lock = lock, code = code, perform = noop } end }
ISInventoryTransferAction = { new = function(self, p, it, src, dst)
    return { Type = "ISInventoryTransferAction", item = it, src = src, dst = dst } end }
local WALKS = 0
luautils = { walkAdj = function() WALKS = WALKS + 1; return true end }
ISWorldObjectContextMenu = { onPutPadlock = noop, onRemovePadlock = noop, onFluidEmpty = noop,
                             getMoveableDisplayName = function() return "Trough" end }
DesignationZoneAnimal = { getZone = function() return { getName = function() return "Pen" end } end }

local color = { r = 1, g = 1, b = 1, a = 1 }
ZeD = {
    tr = function(k, ...)
        local a = { ... }
        if #a == 0 then return k end
        local out = {}
        for i = 1, #a do out[i] = tostring(a[i]) end
        return k .. ":" .. table.concat(out, "|")
    end,
    Atoms = { drawFillBar = noop, drawTextRight = noop },
    Molecules = { drawEmptyLine = function() return 10 end },
    TM = { getFontHeight = function() return 16 end, MeasureStringX = function(self, f, s) return #tostring(s) * 6 end },
    Input = { Detector = { getMode = function() return "mouse" end } },
}
ZeD.T = setmetatable({ px = function(u) return u end, buttonH = 24, fontF1 = 1, fontF2 = 2, fontF3 = 3 },
                     { __index = function() return color end })
local DEFS = {}
local UI = {}
local OC = {
    ui = UI,
    call = function(o, m, ...) if o and type(o[m]) == "function" then return o[m](o, ...) end return nil end,
    DOT = "-", REFRESH = 15, kinds = {}, LEASH = 6,
    keyOf = function(sq, k) return k end, spriteIcon = noop, armKeys = noop, openNear = noop,
    whereOf = function() return "Bag" end, eachSquare = noop, sortTargets = function(l) return l end,
}
OC.register = function(d) DEFS[d.id] = d; OC.kinds[d.id] = d end
ZeD.ObjectCards = OC
-- the library's rows as zones: what the body offers the mouse and the pad
function UI.section() return 10 end
function UI.hex() return { r = 0, g = 0, b = 0 } end
UI.disc, UI.fill = noop, noop
function UI.pair() return 10 end
function UI.warn() return 10 end
function UI.big() return 20 end
function UI.buttonW(l) return #tostring(l) * 6 + 16 end
function UI.pick(card, x, y, w, o) card:zone({ fid = o.fid, run = (o.enabled ~= false) and o.run or nil, label = o.button, w = w }); return 26 end
function UI.button(card, x, y, label, o)
    if o.fid then card:zone({ fid = o.fid, run = (not o.disabled) and o.run or nil, label = label, x = x }) end
    return o.w or UI.buttonW(label)
end

local function newCard(t)
    local c = { zones = {}, playerNum = 0, entry = { t = t } }
    function c:zone(z) self.zones[#self.zones + 1] = z end
    function c:focusOf() return nil end
    function c:drawRect() end
    function c:drawText() end
    return c
end
local function zoneById(card, fid) for _, z in ipairs(card.zones) do if z.fid == fid then return z end end return nil end
local function list(items)
    return { size = function() return #items end, get = function(self, i) return items[i + 1] end }
end

-- ---------------------------------------------------------------------------
-- TG5: the trough
-- ---------------------------------------------------------------------------
local trSrc = readFile(CLIENT .. "ObjectCardTrough.lua")
local tfn, terr = loadstring(trSrc or "", "=ObjectCardTrough.lua")
check("ObjectCardTrough.lua compiles", tfn ~= nil, terr)
local okT, runT = pcall(tfn or noop)
check("ObjectCardTrough.lua runs and registers its card", okT and DEFS.trough ~= nil, runT)
local TG = DEFS.trough

if TG then
    local bag = { name = "bag" }
    local function carrot(where)
        local it = { cont = where }
        function it:getFullType() return "Base.Carrots" end
        function it:getDisplayName() return "Carrots" end
        function it:isEquipped() return false end
        function it:getContainer() return self.cont end
        function it:getFluidContainer() return nil end
        return it
    end
    local function apple(where)
        local it = carrot(where)
        function it:getFullType() return "Base.Apple" end
        function it:getDisplayName() return "Apple" end
        return it
    end
    local carried = {}
    for i = 1, 10 do carried[i] = carrot(bag) end
    carried[11] = apple(bag)
    local inTrough = {}
    local tcont = { getItems = function() return list(inTrough) end }
    local SQ = { getX = function() return 1 end, getY = function() return 1 end, getZ = function() return 0 end }
    local trough = { _cls = "IsoFeedingTrough" }
    function trough:getSquare() return SQ end
    function trough:getObjectIndex() return 1 end
    function trough:getContainer() return tcont end
    function trough:isItemAllowedInContainer() return true end
    function trough:getCurrentFeedAmount() return #inTrough end
    function trough:getWater() return 0 end
    function trough:getMaxWater() return 100 end
    function trough:getFluidContainer() return nil end
    local inv = { getAllEvalRecurse = function(self, fn)
        local o = {}
        for _, it in ipairs(carried) do if fn(it) then o[#o + 1] = it end end
        return list(o)
    end }
    local P = { getInventory = function() return inv end, getPlayerNum = function() return 0 end }

    local t = TG.resolve(P, trough)
    TG.refresh(t, P)
    local card = newCard(t)
    TG.body(card, 0, 0, 460, t, P)
    local add1 = zoneById(card, "trough:feed:1")
    local addAll = zoneById(card, "trough:feedall:1")
    local appleAll = zoneById(card, "trough:feedall:2")
    check("TG5: ten carrots carried give an Add and an Add All", add1 and add1.run and addAll and addAll.run)
    check("TG5: Add All reads the game's Add All", addAll and addAll.label == "ContextMenu_AddAll", addAll and addAll.label)
    check("TG5: a kind of one (the apple) has no Add All", zoneById(card, "trough:feed:2") ~= nil and appleAll == nil)
    QUEUED = {}
    if add1 and add1.run then add1.run(card, P) end
    check("TG5: one press of Add moves one carrot", #QUEUED == 1 and QUEUED[1].dst == tcont, #QUEUED)
    QUEUED = {}
    if addAll and addAll.run then addAll.run(card, P) end
    check("TG5: Add All moves the ten", #QUEUED == 10, #QUEUED)

    -- Take from the trough: four carrots lie in it
    for i = 1, 4 do inTrough[i] = carrot(tcont) end
    TG.refresh(t, P)
    card = newCard(t)
    TG.body(card, 0, 0, 460, t, P)
    local take1 = zoneById(card, "trough:take:1")
    local takeAll = zoneById(card, "trough:takeall:1")
    check("TG5: four in the trough give a Take and a Take All", take1 and take1.run and takeAll and takeAll.run)
    check("TG5: Take All reads the loot window's Take All", takeAll and takeAll.label == "IGUI_invpage_Loot_all", takeAll and takeAll.label)
    QUEUED = {}
    if take1 and take1.run then take1.run(card, P) end
    check("TG5: one press of Take moves one", #QUEUED == 1 and QUEUED[1].src == tcont and QUEUED[1].dst == inv, #QUEUED)
    QUEUED = {}
    if takeAll and takeAll.run then takeAll.run(card, P) end
    check("TG5: Take All moves the four", #QUEUED == 4, #QUEUED)
end

-- ---------------------------------------------------------------------------
-- LK5: a wrong padlock code
-- ---------------------------------------------------------------------------
local lockSrc = readFile(CLIENT .. "ObjectCardLock.lua")
local lfn, lerr = loadstring(lockSrc or "", "=ObjectCardLock.lua")
check("ObjectCardLock.lua compiles", lfn ~= nil, lerr)
local okL, runL = pcall(lfn or noop)
check("ObjectCardLock.lua runs and registers its card", okL and DEFS.lock ~= nil, runL)
local LKdef, LK = DEFS.lock, ZeD.ObjectCardLock

if LKdef and LK then
    local SQ = {}
    local o = { _cls = "IsoThumpable", code = 319 }
    function o:getSquare() return SQ end
    function o:getObjectIndex() return 1 end
    function o:getLockedByCode() return self.code end
    function o:isLockedByPadlock() return false end
    function o:canBeLockByPadlock() return true end
    function o:isLockedToCharacter() return false end
    function o:getName() return "Crate" end
    local inv = { FindAndReturn = function() return nil end, getAllType = function() return list({}) end,
                  haveThisKeyId = function() return nil end }
    local P = { getInventory = function() return inv end, getPlayerNum = function() return 0 end }
    local t = LKdef.resolve(P, o)
    LKdef.refresh(t, P)
    check("LK5: a code-locked crate is in enter mode", t.d and t.d.mode == "enter", t.d and t.d.mode)
    t.digits = { 1, 2, 3 }
    QUEUED, WALKS = {}, 0
    LK.try(P, t)
    check("LK5: a wrong code queues no try", #QUEUED == 0, #QUEUED)
    check("LK5: ... and no walk", WALKS == 0, WALKS)
    check("LK5: ... and says so at once", t.wrong == 123, t.wrong)
    local st = LKdef.status(t)
    check("LK5: the band reads the wrong code", st and st.text == "UI_ZeD_Lock_StatusWrong:1 2 3", st and st.text)
    t.digits = { 3, 1, 9 }
    QUEUED, WALKS = {}, 0
    LK.try(P, t)
    local a = QUEUED[1]
    check("LK5: the right code walks and queues the game's action", WALKS == 1 and #QUEUED == 1 and a
        and a.Type == "ISPadlockByCodeAction" and a.lock == false and a.code == 319, #QUEUED)
    check("LK5: ... and clears the wrong word", t.wrong == nil, t.wrong)
end

-- ---------------------------------------------------------------------------
-- OC4: the held-in rule for object cards
-- ---------------------------------------------------------------------------
local wwSrc = readFile(CLIENT .. "ZeD_WorldWindow.lua") or ""
local function cutFn(src, head)
    local a = src:find(head, 1, true)
    if not a then return nil end
    local _, b = src:find("\nend\n", a, true)
    return b and src:sub(a, b) or nil
end
local fnHeld = cutFn(wwSrc, "function ZeD_WorldWindow.heldIn(")
local fnDraw = cutFn(wwSrc, "function ZeD_WorldWindow.objectDrawerW(")
local function num(name) return tonumber(wwSrc:match("\nlocal " .. name .. "%s*=%s*(%d+)")) end
check("OC4: the held-in rule is one function", fnHeld ~= nil)
check("OC4: objectDrawerW is found", fnDraw ~= nil)
check("OC4: the drawer's width hands the held-in rule to the object card",
    wwSrc:find("ZeD_WorldWindow.objectDrawerW(win._drawerObject.def, base, heldIn)", 1, true) ~= nil)
if fnHeld and fnDraw then
    ZeD_WorldWindow = {}
    ZeD.screenOf = function(w) return w._screen end
    local chunk = "local ITEM_CARD_W, OBJECT_CARD_W, CONTAINER_STRIP_W, ACTION_TAB_STRIP_W, INV_MIN_BESIDE_CARD = ...\n"
        .. fnHeld .. "\n" .. fnDraw
    local lf, le = loadstring(chunk, "=held-in")
    check("OC4: the cut functions load", lf ~= nil, le)
    if lf then
        lf(num("ITEM_CARD_W"), num("OBJECT_CARD_W"), num("CONTAINER_STRIP_W"), num("ACTION_TAB_STRIP_W"), num("INV_MIN_BESIDE_CARD"))
        local W = ZeD_WorldWindow
        local FULL, HALF = { id = "laundry", halfOk = true }, { id = "lock", half = true }
        local WIDE = { id = "hook" }   -- (no half layout yet: keeps the full card held in)
        local w1280 = { _screen = 1280, _invDrawerOpen = true, _mcSelected = {} }
        local h = W.heldIn(w1280, 480)
        check("OC4: 1280 wide, inventory open: held in", h == true, h)
        check("OC4: ... a full object card is the half card", W.objectDrawerW(FULL, 0, h) == 220, W.objectDrawerW(FULL, 0, h))
        check("OC4: ... a kind with no half layout keeps the full card", W.objectDrawerW(WIDE, 0, h) == 480, W.objectDrawerW(WIDE, 0, h))
        check("OC4: ... a half kind stays the half card", W.objectDrawerW(HALF, 0, h) == 220)
        local w4k = { _screen = 3840, _invDrawerOpen = true, _mcSelected = {} }
        h = W.heldIn(w4k, 480)
        check("OC4: 4K: not held in, the full card", h == false and W.objectDrawerW(FULL, 0, h) == 480, h)
        local wHid = { _screen = 1280, _invDrawerOpen = false, _mcSelected = {} }
        check("OC4: inventory hidden: the full card", W.heldIn(wHid, 480) == false)
        local wMC = { _screen = 1280, _invDrawerOpen = true, _mcSelected = { 1 } }
        check("OC4: multi-column Loot: the full card", W.heldIn(wMC, 480) == false)
        check("OC4: no rule given: the full card as before", W.objectDrawerW(FULL, 0) == 480)
    end
end
-- the card host: a full kind at the half card wraps its long foot words as a half card does
local ocSrc = readFile(CLIENT .. "ObjectCards.lua") or ""
local fnNarrow = cutFn(ocSrc, "local function narrowCard(")
check("OC4: the card host has one narrow test", fnNarrow ~= nil)
check("OC4: the question's and the state line's foot use it", select(2, ocSrc:gsub("if narrowCard%(def, w%) then fLines", "")) == 2)
if fnNarrow then
    local nf = loadstring(fnNarrow .. "\nreturn narrowCard")
    local narrowCard = nf and nf()
    check("OC4: a full kind at 220 is narrow", narrowCard and narrowCard({ id = "laundry" }, 220) == true)
    check("OC4: a full kind at 480 is not", narrowCard and not narrowCard({ id = "laundry" }, 480))
    check("OC4: a half kind always is", narrowCard and narrowCard({ half = true }, 480) == true)
end

print(string.format("oc_calls3_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
