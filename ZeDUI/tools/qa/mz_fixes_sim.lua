-- ZeDUI/tools/qa/mz_fixes_sim.lua  (Nov 27 2026, Build): the Maps tab's QA bugs from the mz_tab audit
-- (ZeDUI/qa/audits/2026-11-27_map_maps.md), each checked with no game running. Each section fails on the code
-- before the fix:
--   B11  the Map key folds ZeD's unfolded map while the game is paused (Overrides/WorldMap.lua wraps checkKey)
--   B3   the note box is a pad stop, and its A opens the pad keyboard on it (MapsTab.buildFocusables, noteKeyboard)
--   B9   the drawer's wheel while unfolded zooms nothing (ZeD_WorldWindow's drawer.onMouseWheel)
--   B1   Read Map runs the game's read action; ZeD's window opens at its end (ISReadMapItem:showUI), the read not
--        done twice (PaperMap.open's readDone)
--   B6   the side list's delete buttons stay out of the pad's ring (MapsTabExt: the delete zone carries its row)
--   B12  an open map stays open into the dark; the light is looked at on opening and unfolding (MapsTab _mapBlocked)
--   B13  a world map that failed to build is tried again (MapsTab.render's lazy build)
-- The real files run where they load on their own (the two overrides, PaperMap.lua); the big ones (MapsTab,
-- MapsTabExt, ZeD_WorldWindow) give up the one function or block under test, run against stubs.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mz_fixes_sim.lua
-- It prints FAIL lines and a last line "mz_fixes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]mz_fixes_sim%.lua$", "")
local CL = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local function slurp(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a")
    f:close()
    return s
end
local function plain(s, needle) return string.find(s, needle, 1, true) end

-- a piece of a big file, from one plain marker to (not including) another
local function cut(src, from, to)
    local a = plain(src, from)
    if not a then return nil end
    local b = plain(src, to, a + #from)
    if not b then return nil end
    return string.sub(src, a, b - 1)
end

-- ---------------------------------------------------------------------------
-- the game, as much as these pieces ask of it
-- ---------------------------------------------------------------------------
local NOW = 100000
function getTimestampMs() return NOW end
local SPEED = 1
function getGameSpeed() return SPEED end
local LOG = {}
local function log(s) LOG[#LOG + 1] = s end
local function logHas(s) for _, x in ipairs(LOG) do if x == s then return true end end return false end
local function logCount(s) local n = 0 for _, x in ipairs(LOG) do if x == s then n = n + 1 end end return n end

Events = setmetatable({}, { __index = function(self, k)
    local ev = { Add = function() end, Remove = function() end }
    rawset(self, k, ev)
    return ev
end })
KeybindId = { MAP = "MAP" }
local MAPKEY = 50
local CORE = {
    isKey = function(_, id, key) return id == "MAP" and key == MAPKEY end,
    isTutorial = function() return false end,
    getDebug = function() return false end,
    getScreenWidth = function() return 1920 end,
    getScreenHeight = function() return 1080 end,
}
function getCore() return CORE end
MainScreen = { instance = { inGame = true } }
local PLAYER = { isDead = function() return false end, getPlayerNum = function() return 0 end }
function getSpecificPlayer(pn) if pn == 0 then return PLAYER end return nil end
function getText(k) return k end
function isClient() return false end
JoypadState = { players = {} }
luautils = { haveToBeTransfered = function() return false end }

local LOADED = {}
function require(name) LOADED[name] = true end

ZeD = { Safe = { on = function() return ZeD._safe == true end }, windowsFor = function() return true end }
ZeD.tr = function(k) return k end
ZeD.trBare = function(k) return k end

-- ===========================================================================
section("B11 the Map key while paused")
-- ===========================================================================
-- the game's ISWorldMap, as 42.22 writes it (ISWorldMap.lua 1580-1720): Toggle hides its own map or reads the
-- world map; checkKey refuses a paused key unless its own map is up; the release toggles
local GAME_MAP_UP = false
ISWorldMap = {}
function ISWorldMap.IsAllowed() return true end
function ISWorldMap.ShowWorldMap() log("game:show") end
function ISWorldMap.HideWorldMap() log("game:hide") end
function ISWorldMap.ToggleWorldMap() log("game:toggle") end
function ISWorldMap.checkKey(key)
    if not getCore():isKey(KeybindId.MAP, key) then return false end
    if not ISWorldMap.IsAllowed() then return false end
    if getGameSpeed() == 0 and not GAME_MAP_UP then return false end
    return true
end
function ISWorldMap.onKeyReleased(key)
    if not ISWorldMap.checkKey(key) then return end
    ISWorldMap.ToggleWorldMap(0)
end

local WIN = { _playerObj = PLAYER, playerNum = 0 }
ZeD_WorldWindow = {
    getWindow = function() return WIN end,
    isOpen = function() return true end,
    open = function() end,
}
ZeD.MapsTab = {
    openPopout = function(w) w._mapPopout = {}; log("zed:unfold") end,
    closePopout = function(w) w._mapPopout = nil; w._mapPaperItem = nil; log("zed:fold") end,
}
assert(loadfile(CL .. "Overrides/WorldMap.lua"))()

-- unfolded, paused: M folds it
WIN._mapPopout = {}
SPEED, LOG = 0, {}
ISWorldMap.onKeyReleased(MAPKEY)
check("paused, ZeD's map unfolded: M folds it", WIN._mapPopout == nil and logHas("zed:fold"), table.concat(LOG, ","))
-- another key, paused: nothing
WIN._mapPopout = {}
LOG = {}
ISWorldMap.onKeyReleased(MAPKEY + 1)
check("paused: another key does nothing", WIN._mapPopout ~= nil and #LOG == 0, table.concat(LOG, ","))
-- paused, nothing unfolded: the game's refusal stands (no map opens while paused)
WIN._mapPopout = nil
LOG = {}
ISWorldMap.onKeyReleased(MAPKEY)
check("paused, no map up: the game's refusal stands", #LOG == 0, table.concat(LOG, ","))
-- paused, a paper map up: the game's answer (no world map read while paused)
WIN._mapPopout, WIN._mapPaperItem = {}, { name = "paper" }
LOG = {}
ISWorldMap.onKeyReleased(MAPKEY)
check("paused, a paper map up: the game's refusal stands", #LOG == 0 and WIN._mapPopout ~= nil, table.concat(LOG, ","))
WIN._mapPaperItem = nil
-- paused, the game's own map up: the game's answer, unchanged
WIN._mapPopout, GAME_MAP_UP = nil, true
LOG = {}
check("paused, the game's own map up: the key passes as the game's", ISWorldMap.checkKey(MAPKEY) == true)
GAME_MAP_UP = false
-- safe mode: the game's answer
WIN._mapPopout, ZeD._safe = {}, true
check("safe mode, paused: the game's refusal stands", ISWorldMap.checkKey(MAPKEY) == false)
ZeD._safe = nil
-- running: unfolded, M folds it as before
SPEED, LOG = 1, {}
ISWorldMap.onKeyReleased(MAPKEY)
check("running: M folds it as before", WIN._mapPopout == nil and logHas("zed:fold"), table.concat(LOG, ","))
-- the player dead: refused
SPEED = 0
WIN._mapPopout = {}
PLAYER.isDead = function() return true end
check("paused, the player dead: refused", ISWorldMap.checkKey(MAPKEY) == false)
PLAYER.isDead = function() return false end
SPEED = 1

-- ===========================================================================
section("B1 Read Map takes the game's read action")
-- ===========================================================================
local function newItem(name)
    return { _name = name, getName = function() return name end,
             doBuildingStash = function() log("stash:" .. name) end }
end
PLAYER.addReadMap = function(_, it) log("read:" .. it:getName()) end
PLAYER.getInventory = function() return { contains = function() return true end } end
-- the game's Read Map and its action (ISInventoryPaneContextMenu 2661-2670, ISReadMapItem)
ISInventoryPaneContextMenu = {}
local QUEUE = {}
ISTimedActionQueue = { add = function(a) QUEUE[#QUEUE + 1] = a end }
ISReadMapItem = {}
ISReadMapItem.__index = ISReadMapItem
function ISReadMapItem:new(character, item) return setmetatable({ character = character, item = item, playerNum = 0, Type = "ISReadMapItem" }, ISReadMapItem) end
function ISReadMapItem:complete() self.item:doBuildingStash(); self.character:addReadMap(self.item); return true end
function ISReadMapItem:showUI() log("game:window:" .. self.item:getName()) end
function ISReadMapItem:perform() self:showUI() end
local PB_SEEN = nil   -- (Put things back's queuing flag while the game's Read Map queues its moves: MP53)
ISInventoryPaneContextMenu.onCheckMap = function(map, player)
    PB_SEEN = ZeD.PutBack and ZeD.PutBack.queuing
    ISTimedActionQueue.add(ISReadMapItem:new(getSpecificPlayer(player), map))
end
-- ZeD's paper window: the real PaperMap.lua over a stub World window and map tab
ZeD.Input = nil
ZeD.MapsTab.openPopout = function(w, item) w._mapPopout = {}; w._mapPaperItem = item; log("zed:open:" .. (item and item:getName() or "world")) end
ZeD.MapsTab.closePopout = function(w) w._mapPopout = nil; w._mapPaperItem = nil end
ZeD.MapsTab.addExtension = function() end
WIN._mapPopout, WIN._mapPaperItem = nil, nil
assert(loadfile(CL .. "PaperMap.lua"))()
assert(loadfile(CL .. "Overrides/PaperMap.lua"))()

-- Read Map: the action is queued, no window yet, no read yet
LOG, QUEUE = {}, {}
local map = newItem("MuldraughMap")
ISInventoryPaneContextMenu.onCheckMap(map, 0)
check("Read Map queues the game's read action", #QUEUE == 1 and QUEUE[1].Type == "ISReadMapItem", #QUEUE)
check("and opens nothing at once", not logHas("zed:open:MuldraughMap") and not logHas("game:window:MuldraughMap"), table.concat(LOG, ","))
check("and reads nothing at once", logCount("stash:MuldraughMap") == 0 and logCount("read:MuldraughMap") == 0, table.concat(LOG, ","))
-- the action ends: complete (the stash, the read), then perform (the window)
if QUEUE[1] then QUEUE[1]:complete(); QUEUE[1]:perform() end
check("the action's end opens ZeD's window on the paper, not the game's",
    logHas("zed:open:MuldraughMap") and not logHas("game:window:MuldraughMap") and WIN._mapPaperItem == map, table.concat(LOG, ","))
check("the stash and the read done once (by the action)", logCount("stash:MuldraughMap") == 1 and logCount("read:MuldraughMap") == 1, table.concat(LOG, ","))
-- MP53 (the director's call, Nov 27 2026): with Put things back on, a read map goes back where it came from once
-- the paper is put away. The game's Read Map moves are noted as the read's run (not hidden from Put back), and the
-- read is marked at its end so Put back holds the move back until the fold (ZeD_PutBack.lua PB.release)
do
    ZeD.PutBack = { queuing = false }
    LOG, QUEUE = {}, {}
    WIN._mapPopout, WIN._mapPaperItem = nil, nil
    local fm = newItem("FloorMap")
    ISInventoryPaneContextMenu.onCheckMap(fm, 0)
    check("MP53: the Read Map's moves are not hidden from Put things back (no queuing flag)", PB_SEEN == false, tostring(PB_SEEN))
    check("MP53: ... and Put back's flag is untouched", ZeD.PutBack.queuing == false)
    local act = QUEUE[1]
    if act then act:complete(); act:perform() end
    check("MP53: the read with the paper up is marked to hold its move back until the paper is put away",
        act ~= nil and act._zedBackLater == true and WIN._mapPaperItem == fm, tostring(act and act._zedBackLater))
    ZeD.PutBack = nil
    LOG, QUEUE = {}, {}
    WIN._mapPopout, WIN._mapPaperItem = nil, nil
end
-- safe mode: the game's window
WIN._mapPopout, WIN._mapPaperItem = nil, nil
LOG, QUEUE = {}, {}
ZeD._safe = true
local m2 = newItem("RiversideMap")
ISInventoryPaneContextMenu.onCheckMap(m2, 0)
if QUEUE[1] then QUEUE[1]:complete(); QUEUE[1]:perform() end
check("safe mode: the game's window", logHas("game:window:RiversideMap") and not logHas("zed:open:RiversideMap"), table.concat(LOG, ","))
ZeD._safe = nil
-- ZeD's window cannot open: the game's window, the read still once
WIN._mapPopout, WIN._mapPaperItem = nil, nil
LOG, QUEUE = {}, {}
local openReal = ZeD.MapsTab.openPopout
ZeD.MapsTab.openPopout = function() error("no window here") end
local m3 = newItem("WestpointMap")
ISInventoryPaneContextMenu.onCheckMap(m3, 0)
if QUEUE[1] then QUEUE[1]:complete(); QUEUE[1]:perform() end
ZeD.MapsTab.openPopout = openReal
check("ZeD's window can't open: the game's window", logHas("game:window:WestpointMap"), table.concat(LOG, ","))
check("and the read is done once", logCount("stash:WestpointMap") == 1 and logCount("read:WestpointMap") == 1, table.concat(LOG, ","))
-- the open with the read done: no second read; without it (a game with no read action), the read is ZeD's
WIN._mapPopout, WIN._mapPaperItem = nil, nil
LOG = {}
local m4 = newItem("LouisvilleMap1")
ZeD.PaperMap.open(m4, 0, true)
check("PaperMap.open after the action: no second stash or read", logHas("zed:open:LouisvilleMap1") and logCount("stash:LouisvilleMap1") == 0 and logCount("read:LouisvilleMap1") == 0, table.concat(LOG, ","))
WIN._mapPopout, WIN._mapPaperItem = nil, nil
LOG = {}
ZeD.PaperMap.open(m4, 0)
check("PaperMap.open on its own: the stash and the read", logCount("stash:LouisvilleMap1") == 1 and logCount("read:LouisvilleMap1") == 1, table.concat(LOG, ","))
WIN._mapPopout, WIN._mapPaperItem = nil, nil

-- ===========================================================================
section("B3 the note box is a pad stop")
-- ===========================================================================
local MT = slurp(CL .. "MapsTab.lua")
local bf = cut(MT, "function ZeD.MapsTab.buildFocusables(win)", "-- ============================================================================\r\n-- GAMEPAD HELPERS")
    or cut(MT, "function ZeD.MapsTab.buildFocusables(win)", "-- ============================================================================\n-- GAMEPAD HELPERS")
check("buildFocusables found", bf ~= nil)
local EXT = { addFocusables = function() end }
local pre = "local Ext, _addToolEls, _addStyleEls, _closeStyleMenu = ... "
local OSK = {}
OnScreenKeyboard = { Show = function(pn, box, jd) OSK[#OSK + 1] = { pn = pn, box = box, jd = jd }; return {} end }
if bf then
    local fn, err = loadstring(pre .. bf)
    check("buildFocusables loads", fn ~= nil, err)
    if fn then
        fn(EXT, function() end, function() end, function() end)
        local box = { visible = true, x = 10, y = 40, w = 300, h = 20,
            isVisible = function(s) return s.visible end, getX = function(s) return s.x end, getY = function(s) return s.y end,
            getWidth = function(s) return s.w end, getHeight = function(s) return s.h end,
            focus = function() log("box:focus") end }
        local w = { _mapTextEntry = box, _mapActiveTool = "text", playerNum = 0 }
        local els = ZeD.MapsTab.buildFocusables(w)
        local note = nil
        for _, el in ipairs(els) do if el.id == "map:note" then note = el end end
        check("the note in hand: a stop on the note box", note ~= nil and note.x == 10 and note.y == 40 and note.w == 300)
        JoypadState.players[1] = { focus = "win" }
        OSK, LOG = {}, {}
        if note and note.onActivate then note.onActivate(w, note) end
        check("its A opens the pad keyboard on the box", #OSK == 1 and OSK[1].box == box and OSK[1].pn == 0)
        JoypadState.players[1] = nil
        OSK, LOG = {}, {}
        if note and note.onActivate then note.onActivate(w, note) end
        check("no pad: the box takes the keys", #OSK == 0 and logHas("box:focus"))
        w._mapActiveTool = "star"
        els = ZeD.MapsTab.buildFocusables(w)
        note = nil
        for _, el in ipairs(els) do if el.id == "map:note" then note = el end end
        check("another tool in hand: no note stop", note == nil)
    end
end
local editAt = plain(MT, "IGUI_Map_EditNote")
local editTail = editAt and string.sub(MT, editAt, editAt + 1400) or ""
check("Edit note by the pad opens the keyboard on the note's words", plain(editTail, "if fromPad then ZeD.MapsTab.noteKeyboard(pwin) end") ~= nil)

-- ===========================================================================
section("B9 the drawer's wheel while unfolded")
-- ===========================================================================
local WW = slurp(CL .. "ZeD_WorldWindow.lua")
local wheel = cut(WW, "drawer.onMouseWheel = function(self, del)", "-- Crafting/Building tabs")
check("the drawer's wheel found", wheel ~= nil)
if wheel then
    local fn, err = loadstring("local win = ...; local f = function(self, del)" .. string.sub(wheel, #"drawer.onMouseWheel = function(self, del)" + 1) .. " return false end; return f")
    check("the drawer's wheel loads", fn ~= nil, err)
    if fn then
        local zoomed = 0
        local w = { _drawerMode = "tab", _activeTab = "maps", _worldMapPanel = { onMouseWheel = function() zoomed = zoomed + 1 end } }
        ZeD.RadioTab = { onWheel = function() return false end }
        local f = fn(w)
        local self = { getMouseX = function() return 5 end, getMouseY = function() return 5 end }
        w._mapPopout = {}
        local took = f(self, -1)
        check("unfolded: the wheel over the placeholder zooms nothing (and is taken)", zoomed == 0 and took == true, zoomed)
        w._mapPopout = nil
        f(self, -1)
        check("folded: the wheel zooms the drawer's map as before", zoomed == 1, zoomed)
    end
end

-- ===========================================================================
section("B6 the side list's delete buttons are not pad stops")
-- ===========================================================================
local MX = slurp(CL .. "MapsTabExt.lua")
check("the delete button's zone carries its row", plain(MX, "local xz = { id = rid .. \":x\", x = dx + ox, y = dy + oy, w = ds, h = ds, row = r,") ~= nil)
local af = cut(MX, "local function addFocusable(z, elements)", "function E.addFocusables(win, elements, band)")
check("addFocusable found", af ~= nil)
if af then
    local fn, err = loadstring("local stepSlider = function() end; " .. af .. " return addFocusable")
    check("addFocusable loads", fn ~= nil, err)
    if fn then
        local add = fn()
        local r = { key = "p1", del = { ask = "Delete?", onYes = function() end } }
        local els = {}
        add({ id = "map:side:players:p1", x = 0, y = 0, w = 100, h = 20, row = r, activate = function() end }, els)
        add({ id = "map:side:players:p1:x", x = 80, y = 2, w = 16, h = 16, row = r, activate = function() end }, els)
        check("the row is a stop, its delete button is not", #els == 1 and els[1].id == "map:side:players:p1", #els)
        check("and X on the row asks to delete", els[1] and els[1].onContextMenu ~= nil)
    end
end

-- ===========================================================================
section("B12 an open map stays open into the dark")
-- ===========================================================================
local mb = cut(MT, "local function _centredLine(panel, text, x, y, w, c)", "function ZeD.MapsTab.render(panel, win, x, y, w, h)")
check("_mapBlocked found", mb ~= nil)
local DARK = false
ZeD.MapsTab.isAllowed = function() return true end
ZeD.MapsTab.tooDark = function() return DARK end
ZeD.T = { fontF2 = 1, textDim = { r = 1, g = 1, b = 1 } }
ZeD.TM = { MeasureStringX = function() return 10 end, getFontHeight = function() return 10 end }
ZeD.Atoms = { surfaceFill = function() end }
if mb then
    local fn, err = loadstring(mb .. " return _mapBlocked")
    check("_mapBlocked loads", fn ~= nil, err)
    if fn then
        local blocked = fn()
        local panel = { drawText = function() end }
        local w = { _playerObj = PLAYER }
        local function frames(n, ms) local r; for _ = 1, n do NOW = NOW + ms; r = blocked(panel, w, 0, 0, 100, 100) end; return r end
        DARK = false
        check("opened in the light: the map is read", frames(1, 16) == false)
        DARK = true
        check("the dark comes while it is open: it stays open (2 s of frames)", frames(120, 16) == false and w._mapBlocked == false)
        -- the tab put away and shown again (a gap in its drawing): looked at again
        NOW = NOW + 2000
        check("shown again in the dark: refused", frames(1, 16) == true)
        DARK = false
        check("refused, the light back: the map within half a second", frames(40, 16) == false)
        -- unfolding opens the map: openPopout clears the seen mark (its source)
        DARK = true
        if w._mapLight then w._mapLight.seen = nil end
        check("unfolded in the dark: refused", frames(1, 16) == true)
    end
end
local op = cut(MT, "function ZeD.MapsTab.openPopout(win, paperItem)", "local sw = getCore():getScreenWidth()")
check("unfolding looks at the light again (openPopout clears win._mapLight.seen)", op ~= nil and plain(op, "win._mapLight.seen = nil") ~= nil)

-- ===========================================================================
section("B13 a failed world map build is tried again")
-- ===========================================================================
local lb = cut(MT, "-- Lazy-create the world map panel", "if win._worldMapPanel then\r\n        local mp = win._worldMapPanel")
    or cut(MT, "-- Lazy-create the world map panel", "if win._worldMapPanel then\n        local mp = win._worldMapPanel")
check("the lazy build found", lb ~= nil)
if lb then
    local MR = string.match(MT, "local MAP_RETRY_MS = (%d+)") or "1000"
    local fn, err = loadstring("local MAP_RETRY_MS = " .. MR .. "; local Ext = { isPopout = function() return false end, mapMade = function() end }; "
        .. "return function(win, panel, x, mapY, w, mapH) " .. lb .. " end")
    check("the lazy build loads", fn ~= nil, err)
    if fn then
        local build = fn()
        local FAIL = true
        local made = 0
        ZeD_WorldMap = { new = function(_, ...)
            if FAIL then error("staged") end
            made = made + 1
            return { initialise = function() end, instantiate = function() end }
        end }
        local panel = { addChild = function() end }
        local w = { _playerObj = PLAYER, _worldMapFailed = false }
        local oldPrint = print
        print = function() end
        build(w, panel, 0, 0, 100, 100)
        check("the first build fails: marked failed", w._worldMapFailed == true and w._worldMapPanel == nil)
        FAIL = false
        NOW = NOW + 100
        build(w, panel, 0, 0, 100, 100)
        check("at once after: not tried again yet (no build every frame)", w._worldMapPanel == nil)
        NOW = NOW + 1200
        build(w, panel, 0, 0, 100, 100)
        print = oldPrint
        check("a second later: built, the failed mark cleared", w._worldMapPanel ~= nil and w._worldMapFailed == false and made == 1, tostring(w._worldMapFailed))
    end
end

print("mz_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
