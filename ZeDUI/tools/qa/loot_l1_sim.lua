-- ZeDUI/tools/qa/loot_l1_sim.lua  (Nov 23 2026, QA's loot and inventory sweep, batch L1): the seven fixes, run
-- outside the game on Lua 5.1 stubs. The code is cut from the real files (or the whole file, where it loads alone).
--   L1-1  Move To on a held item: a gate that refuses the destination leaves it in the hand (no unequip queued);
--         a move that goes through takes it off just before its own transfer (CT.moveItems, unequip = true)
--   L1-2  the world menu's lock rule (ItemMenu.lua lockedTo): a padlocked crate opens for the key holder, stays shut
--         without the key; a combination lock stays shut; anything not built (not an IsoThumpable) is never shut
--   L1-3  Put things back (ZeD_PutBack.lua, whole file): a pickup the player asked for (marked _zedApart) in the
--         same tick as eating from crate A is not sent back into crate A; without the mark it was (the old race)
--   L1-4  the World band's To floor refuses while seated with the window shut (source: its run asks carWindowShut)
--   L1-5  Shift + double-click (InventoryRenderer quickUse / doubleClick): a garment from a crate is taken and worn;
--         a broken one is not worn; no Shift, no wear; one thing of an opened stack is taken but not worn (the game)
--   L1-6  Ctrl+A (ZeD_BoxSelect.lua, whole file): picks every row of the hovered ZeD list once per press; not while
--         typing; not with the pointer off the window; Ctrl alone or A alone does nothing
--   L1-7  a container renamed the game's way (getCustomName) goes by that name: the world menu's title, Restock's
--         contName, and (source) the World window, the Cooking and Mechanics tabs
-- What it can't show: the game's timed actions really running. Run from the repo root:
--   lua51 ZeDUI/tools/qa/loot_l1_sim.lua
-- It prints FAIL lines and a last line "loot_l1_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]loot_l1_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function noop() end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end
-- the text from `from` to the first `to` after it (a function: to = "\nend\n", the first unindented end)
local function cut(src, from, to)
    local a = src and string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    return string.sub(src, a, b + #to - 1) .. "\n"
end
local function run(name, code)
    if not code then check(name .. ": the code was found", false); return false end
    local f, err = loadstring(code, name)
    if not f then check(name .. ": the code loads", false, err); return false end
    local ok, e = pcall(f)
    if not ok then check(name .. ": the code runs", false, e); return false end
    return true
end

-- ---------------------------------------------------------------------------
-- STUBS (shared)
-- ---------------------------------------------------------------------------
local hooks = {}
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = function(fn) hooks[k] = hooks[k] or {}; table.insert(hooks[k], fn) end, Remove = noop }
    rawset(t, k, e)
    return e
end })
require = noop
local realPrint = print
print = function(s) if type(s) == "string" and s:sub(1, 5) == "[ZeD]" then return end realPrint(s) end
ZeD = { Safe = { on = function() return false end } }
local queue = {}
ISTimedActionQueue = { add = function(a) queue[#queue + 1] = a; return a end, onCompleted = noop, resetQueue = noop }
local function clearQueue() for i = #queue, 1, -1 do queue[i] = nil end end
local function act(t) return function(_, chr, item, a, b) return { Type = t, character = chr, item = item, srcContainer = a, destContainer = b } end end
ISUnequipAction = { new = act("ISUnequipAction") }
ISInventoryTransferAction = { new = act("ISInventoryTransferAction") }
ISWearClothing = { new = act("ISWearClothing") }
ISInventoryTransferUtil = { newInventoryTransferAction = function(chr, item, a, b) return ISInventoryTransferAction:new(chr, item, a, b) end }
instanceof = function(o, cls) return type(o) == "table" and o._cls ~= nil and o._cls[cls] == true end

-- a container: a list of things that know where they are
local function mkInv(ty)
    local inv = { _items = {}, _ty = ty }
    function inv:getType() return self._ty end
    function inv:getItems()
        local list = self._items
        return { size = function() return #list end, get = function(_, i) return list[i + 1] end }
    end
    function inv:isItemAllowed() return true end
    function inv:add(it) self._items[#self._items + 1] = it; it._in = self end
    function inv:remove(it)
        for i, x in ipairs(self._items) do if x == it then table.remove(self._items, i); break end end
        it._in = nil
    end
    function inv:getCustomName() return self._custom end
    return inv
end
local function mkItem(name, cls)
    local it = { _name = name, _cls = cls or {} }
    function it:getContainer() return self._in end
    function it:getFullType() return "Base." .. self._name end
    function it:isFavorite() return false end
    function it:isBroken() return self._broken == true end
    function it:isHumanCorpse() return false end
    return it
end

-- ===========================================================================
-- L1-1  Move To on a held item (CT.moveItems, unequip)
-- ===========================================================================
local CCsrc = readFile(Z .. "ContainerControls.lua")
local IMsrc = readFile(Z .. "Overrides/ItemMenu.lua")
CT = {}
isFloor = function(inv) return inv ~= nil and inv:getType() == "floor" end
zedFloor = function() return nil end
sortForTransfer = noop
local refuse = false
ZeD.ContainerGates = { refuses = function() return refuse end }
ZeD.ItemRules = { filter = function(items) return items end }
ZeD.InventoryRenderer = { carWindowShut = function() return false end }
corpseStorageCheck = nil
local main, crateB = mkInv("none"), mkInv("crate")
local held = mkItem("Hammer")
main:add(held)
local P = { _eq = { [held] = true } }
function P:getPlayerNum() return 0 end
function P:isEquipped(it) return self._eq[it] == true end
function P:getInventory() return main end
function P:getVehicle() return nil end
if run("L1-1 CT.moveItems", cut(CCsrc, "function CT.moveItems(", "\nend\n")) then
    refuse = true
    clearQueue()
    CT.moveItems(P, { held }, crateB, true)
    check("L1-1 a refusing gate: nothing queued, the held thing is not taken off", #queue == 0, #queue .. " queued")
    refuse = false
    clearQueue()
    CT.moveItems(P, { held }, crateB, true)
    check("L1-1 an open crate: the unequip then the transfer", #queue == 2 and queue[1].Type == "ISUnequipAction"
        and queue[2].Type == "ISInventoryTransferAction" and queue[2].destContainer == crateB,
        #queue .. " queued, first " .. tostring(queue[1] and queue[1].Type))
    check("L1-1 both are the player's own moves (_zedApart, Put things back leaves them)", queue[1] and queue[1]._zedApart == true
        and queue[2] and queue[2]._zedApart == true)
    clearQueue()
    CT.moveItems(P, { held }, crateB)
    check("L1-1 without unequip (every other move) the held thing is not taken off", #queue == 1 and queue[1].Type == "ISInventoryTransferAction",
        #queue .. " queued")
end
local onMove = cut(IMsrc, "local function onMove(", "\nend\n") or ""
check("L1-1 ItemMenu onMove queues no unequip of its own and asks moveItems to", not onMove:find("ISUnequipAction", 1, true)
    and onMove:find("CT.moveItems(playerObj, items, dest, true)", 1, true) ~= nil)

-- ===========================================================================
-- L1-2  the world menu's lock rule
-- ===========================================================================
if run("L1-2 lockedTo", (cut(IMsrc, "local function lockedTo(", "\nend\n") or ""):gsub("^local function lockedTo", "function lockedTo")) then
    local function mkThump(padlock, keyId, code)
        local o = { _cls = { IsoThumpable = true } }
        function o:isLockedByPadlock() return padlock end
        function o:getKeyId() return keyId end
        function o:getLockedByCode() return code end
        -- the game's rule as the Java has it: a code locks, a padlock locks without its key
        function o:isLockedToCharacter(chr) return code > 0 or (padlock and not chr._keys[keyId]) end
        return o
    end
    local function mkChr(keys)
        local c = { _keys = keys or {} }
        local inv = { haveThisKeyId = function(_, id) return c._keys[id] and {} or nil end }
        function c:getInventory() return inv end
        return c
    end
    check("L1-2 padlocked, no key: shut", lockedTo(mkThump(true, 7, 0), mkChr()) == true)
    check("L1-2 padlocked, the key carried: open (the game opens it)", lockedTo(mkThump(true, 7, 0), mkChr({ [7] = true })) == false)
    check("L1-2 padlocked, another key: shut", lockedTo(mkThump(true, 7, 0), mkChr({ [8] = true })) == true)
    check("L1-2 a combination lock: shut", lockedTo(mkThump(false, -1, 1234), mkChr()) == true)
    check("L1-2 not locked: open", lockedTo(mkThump(false, -1, 0), mkChr()) == false)
    check("L1-2 not a built object (a shelf): never shut", lockedTo({ _cls = {} }, mkChr()) == false)
end
check("L1-2 onFillWorld asks lockedTo, no padlocked() left", IMsrc:find("not lockedTo(obj, playerObj) then", 1, true) ~= nil
    and not IMsrc:find("padlocked(", 1, true))

-- ===========================================================================
-- L1-3  Put things back: a pickup in the same tick as eating from crate A
-- ===========================================================================
ZeD.Settings = { putBackOn = function() return true end }
local PBsrc = readFile(Z .. "ZeD_PutBack.lua")
local function putBackCase(markPickup)
    clearQueue()
    local mainI, crateA = mkInv("none"), mkInv("crate")
    local apple, other = mkItem("Apple"), mkItem("Pen")
    crateA:add(apple); crateA:add(other)
    local chr = { _cls = { IsoPlayer = true } }
    function chr:isLocalPlayer() return true end
    function chr:getInventory() return mainI end
    function chr:getPrimaryHandItem() return nil end
    function chr:getSecondaryHandItem() return nil end
    function chr:isEquippedClothing() return false end
    function chr:isAttachedItem() return false end
    function chr:getPlayerNum() return 0 end
    -- one tick: the pickup (ZeD's move), then the game's eat (its transfer, then the eat)
    local pick = ISInventoryTransferAction:new(chr, other, crateA, mainI)
    if markPickup then pick._zedApart = true end
    ISTimedActionQueue.add(pick)
    ISTimedActionQueue.add(ISInventoryTransferAction:new(chr, apple, crateA, mainI))
    local eat = { Type = "ISEatFoodAction", character = chr, item = apple }
    ISTimedActionQueue.add(eat)
    -- the actions run: the pen arrives, the apple comes over and is eaten up
    crateA:remove(other); mainI:add(other)
    crateA:remove(apple)
    local n0 = #queue
    ISTimedActionQueue.onCompleted(ISTimedActionQueue, eat)
    local backs = 0
    for i = n0 + 1, #queue do
        if queue[i].Type == "ISInventoryTransferAction" and queue[i].destContainer == crateA then backs = backs + 1 end
    end
    return backs
end
if run("L1-3 ZeD_PutBack.lua", PBsrc) then
    check("L1-3 the old race shown: an unmarked pickup is sent back into crate A", putBackCase(false) == 1)
    check("L1-3 the player's own pickup (_zedApart) stays in the inventory", putBackCase(true) == 0)
end

-- ===========================================================================
-- L1-4  To floor seated with the window shut
-- ===========================================================================
local toFloor = cut(CCsrc, 'id = "floor", label = ZeD.tr("UI_ZeD_Controls_ToFloor")', "onMoveItemsTo(") or ""
check("L1-4 the band's To floor refuses through a shut car window first", toFloor:find("carWindowShut(playerObj) then return end", 1, true) ~= nil)

-- ===========================================================================
-- L1-5  Shift + double-click wears a garment
-- ===========================================================================
local IRsrc = readFile(Z .. "InventoryRenderer.lua")
local now = 1000
getTimestampMs = function() return now end
isForceDropHeavyItem = function() return false end
luautils = { walkToContainer = function() return true end }
local mainW = mkInv("none")
local PW = {}
function PW:getInventory() return mainW end
function PW:getVehicle() return nil end
getSpecificPlayer = function() return PW end
ISInventoryPane = { doContextualDblClick = noop }
local moved = {}
ZeD.ContainerControls = { moveItems = function(_, items) for _, it in ipairs(items) do moved[#moved + 1] = it end end,
    takeDest = function(p) return p:getInventory() end }   -- (the bag on show: the main inventory here; loot KISS, Nov 24 2026)
local stackOf = {}
ZeD.InventoryRenderer.dragItems = function(_, items) return items end
if run("L1-5 quickUse", cut(IRsrc, "function ZeD.InventoryRenderer.quickUse(", "\nend\n"))
   and run("L1-5 doubleClick", "local DBL_MS = 400\n" .. (cut(IRsrc, "function ZeD.InventoryRenderer.doubleClick(", "\nend\n") or "")) then
    local crate = mkInv("crate")
    local shirt = mkItem("Tshirt", { Clothing = true })
    local torn = mkItem("Jacket", { Clothing = true }); torn._broken = true
    local can = mkItem("Beans")
    crate:add(shirt); crate:add(torn); crate:add(can)
    local win = { _stacks = stackOf }
    local function dbl(it, shift)
        clearQueue(); moved = {}
        win._zedLastClick = nil
        ZeD.InventoryRenderer.doubleClick(win, it, 0, nil, shift)
        now = now + 100
        return ZeD.InventoryRenderer.doubleClick(win, it, 0, nil, shift)
    end
    local function wore(it) for _, a in ipairs(queue) do if a.Type == "ISWearClothing" and a.item == it then return true end end return false end
    check("L1-5 Shift + double-click on a garment: taken", dbl(shirt, true) == true and moved[1] == shirt)
    check("L1-5 ... and worn after", wore(shirt))
    dbl(torn, true)
    check("L1-5 a broken garment is taken, not worn", moved[1] == torn and not wore(torn))
    dbl(can, true)
    check("L1-5 a thing that is not a garment is only taken", moved[1] == can and #queue == 0)
    dbl(shirt, false)
    check("L1-5 no Shift: taken, never worn", moved[1] == shirt and not wore(shirt))
    stackOf[shirt] = { count = 2, key = "Tshirt" }   -- an opened stack of two: this row is one thing of it
    dbl(shirt, true)
    check("L1-5 one thing of an opened stack: taken, not worn (the game wears from the stack's own row)", moved[1] == shirt and not wore(shirt))
    stackOf[shirt] = nil
    now = now + 1000
    win._zedLastClick = nil
    check("L1-5 a single Shift click is not a double-click (the window's Shift selection runs)",
        ZeD.InventoryRenderer.doubleClick(win, shirt, 0, nil, true) == false)
end
for _, f in ipairs({ "ZeD_WorldWindow.lua", "ZeD_CharacterWindow.lua" }) do
    local s = readFile(Z .. f) or ""
    check("L1-5 " .. f .. " passes Shift to the double-click instead of skipping it",
        s:find("(getColumnAtX(self, x)), isShiftKeyDown()) then", 1, true) ~= nil
        and not s:find("not isCtrlKeyDown() and not isShiftKeyDown() and self._playerObj", 1, true))
end

-- ===========================================================================
-- L1-6  Ctrl+A
-- ===========================================================================
local ctrl, aDown, typingNow = false, false, false
local mx, my = 50, 50
isCtrlKeyDown = function() return ctrl end
Keyboard = { KEY_A = 30 }
isKeyDown = function(k) return k == 30 and aDown end
getCore = function() return { isDoingTextEntry = function() return typingNow end } end
getMouseX = function() return mx end
getMouseY = function() return my end
local picks = 0
local content = { zedSelectAll = function() picks = picks + 1 end }
function content:isReallyVisible() return true end
function content:getAbsoluteX() return 0 end
function content:getAbsoluteY() return 0 end
function content:getWidth() return 200 end
function content:getHeight() return 200 end
local wwin = { _mainContent = content }
function wwin:isVisible() return true end
ZeD_WorldWindow = { getWindow = function() return wwin end }
ZeD_CharacterWindow = { getWindow = function() return nil end }
-- (the director, Nov 23 2026: "Keep double-click". Ctrl+A stays out, as on Nov 10, punch list 146; these checks
-- would run only if ZeD_BoxSelect ever had BS.ctrlA again)
local bsSrc = readFile(Z .. "ZeD_BoxSelect.lua") or ""
if not bsSrc:find("function BS.ctrlA", 1, true) then print("(L1-6 Ctrl+A: the director keeps the double-click; skipped)") end
if bsSrc:find("function BS.ctrlA", 1, true) and run("L1-6 ZeD_BoxSelect.lua", bsSrc) then
    local frame = hooks.OnPreUIDraw and hooks.OnPreUIDraw[1]
    check("L1-6 hooked on the frame", frame ~= nil)
    frame = frame or noop
    local function frames(n) for _ = 1, n do frame() end end
    ctrl, aDown = true, false; frames(3)
    check("L1-6 Ctrl alone picks nothing", picks == 0)
    ctrl, aDown = false, true; frames(3)
    check("L1-6 A alone picks nothing", picks == 0)
    ctrl, aDown = true, true; frames(8)
    check("L1-6 Ctrl+A held over the list picks every row, once per press", picks == 1, picks .. " picks")
    ctrl, aDown = false, false; frames(1)
    ctrl, aDown = true, true; frames(2)
    check("L1-6 a second press picks again", picks == 2, picks .. " picks")
    ctrl, aDown = false, false; frames(1)
    typingNow = true
    ctrl, aDown = true, true; frames(2)
    check("L1-6 not while a text box takes the keys", picks == 2, picks .. " picks")
    ctrl, aDown = false, false; frames(1)
    typingNow = false
    mx = 500
    ctrl, aDown = true, true; frames(2)
    check("L1-6 not with the pointer off the window", picks == 2, picks .. " picks")
    ctrl, aDown = false, false; frames(1)
end

-- ===========================================================================
-- L1-7  custom container names
-- ===========================================================================
getTextOrNull = function(k) if k == "IGUI_ContainerTitle_crate" then return "Crate" end return nil end
getText = function(k) return getTextOrNull(k) or k end
if run("L1-7 containerTitle", (cut(IMsrc, "local function containerTitle(", "\nend\n") or ""):gsub("^local function containerTitle", "function containerTitle")) then
    local c = mkInv("crate")
    check("L1-7 world menu: a crate is Crate", containerTitle(c) == "Crate")
    c._custom = "Tools"
    check("L1-7 world menu: a renamed crate goes by its name", containerTitle(c) == "Tools")
end
-- (L1-7's Restock check moved with ZeD_Restock.lua to the add-on ZeD-GUI: Loadouts, Nov 23 2026: its tests/source_sim.lua,
-- NAMES)
for _, f in ipairs({ "ZeD_WorldWindow.lua", "CookingTab.lua", "MechanicsTab.lua" }) do
    local s = readFile(Z .. f) or ""
    check("L1-7 " .. f .. " reads the container's custom name", s:find("getCustomName and container:getCustomName()", 1, true) ~= nil
        or s:find("getCustomName and c:getCustomName()", 1, true) ~= nil)
end

realPrint("loot_l1_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
