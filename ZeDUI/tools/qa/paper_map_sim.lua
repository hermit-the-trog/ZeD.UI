-- ZeDUI/tools/qa/paper_map_sim.lua  (Nov 7 2026, Build): paper map items (vanilla windows list B2), with no game running.
-- Read Map on a map item opens ZeD's map window on that paper (PaperMap.lua, hooked by Overrides/PaperMap.lua), and the
-- game's read must stay the game's: the transfer first, doBuildingStash, addReadMap, the paper's Init, the reveal of its
-- area (and the server's copy of it), the whole paper in view, closed when the map leaves the main inventory. The real
-- files run against Lua 5.1 stubs of the game, each written from its javap listing (42.22):
--   InventoryItem.doBuildingStash(), getStashMap(), getName(); IsoGameCharacter.addReadMap(InventoryItem), isDead(),
--   getInventory(); ItemContainer.contains(InventoryItem, boolean); UIWorldMapV1.setMapItem(MapItem), setBoolean(String,
--   boolean), getMin/MaxX/YInSquares(), getZoomF(), resetView(); LuaManager.GlobalObject.setJoypadIgnoreAimUntilCentered(int,
--   boolean). A stub has only those methods, so a call the game does not have fails here too.
-- Also: MapNotes writes a paper's marks to the paper (not the world store), MapsTabExt keeps the world map's extensions off a
-- paper map, and Overrides/WorldMap.lua puts the paper away for the world map without the Map key closing it.
-- And (Nov 7 evening): a World window Read Map opened only to show the paper closes with the paper; one already open
-- stays, as does the World window when the paper gives way to the world map (Find on map, M) or to another paper.
-- 42.21 (Stable) has the same onCheckMap, ISMap:update / initMapData / revealOnWorldMap and ISReadWorldMap:perform.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/paper_map_sim.lua
-- It prints FAIL lines and a last line "paper_map_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]paper_map_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        io.write("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "") .. string.char(10))   -- (print is muted below)
    end
end
local function section(s) print("-- " .. s) end

-- a Java object: only the listed methods; any other call errors as the game's would
local function jobj(kind, methods)
    return setmetatable(methods, { __index = function(_, k) error("no method " .. kind .. "." .. tostring(k)) end })
end

-- ---------------------------------------------------------------------------
-- THE GAME
-- ---------------------------------------------------------------------------
local LOG
local function log(s) LOG[#LOG + 1] = s end
local function logHas(s) for _, x in ipairs(LOG) do if x == s then return true end end return false end
local function logIndex(s) for i, x in ipairs(LOG) do if x == s then return i end end return nil end
local function logCount(s) local n = 0 for _, x in ipairs(LOG) do if x == s then n = n + 1 end end return n end

local function events()
    return setmetatable({}, { __index = function(self, name)
        local ev = { list = {} }
        function ev.Add(fn) ev.list[#ev.list + 1] = fn end
        function ev.Remove(fn)
            for i = #ev.list, 1, -1 do if ev.list[i] == fn then table.remove(ev.list, i) end end
        end
        function ev.fire(...) for _, fn in ipairs(ev.list) do fn(...) end end
        rawset(self, name, ev)
        return ev
    end })
end
Events = events()

local function newItem(name, stash)
    local it
    it = jobj("MapItem", {
        getName = function() return name end,
        getStashMap = function() return stash end,
        getMapID = function() return name end,
        IsMap = function() return true end,
        doBuildingStash = function() log("doBuildingStash:" .. name) end,
    })
    return it
end

local function newPlayer(num)
    local inv = { items = {} }
    local p
    p = jobj("IsoPlayer", {
        getPlayerNum = function() return num end,
        isDead = function() return rawget(p, "_dead") == true end,
        getInventory = function()
            return jobj("ItemContainer", { contains = function(_, item, recurse)
                if recurse ~= true then error("contains: the read's check is recursive") end
                for _, x in ipairs(inv.items) do if x == item then return true end end
                return false
            end })
        end,
        addReadMap = function(_, item) log("addReadMap:" .. item:getName()) end,
        playSoundLocal = function(_, s) log("sound:" .. s) end,
        getModData = function() return {} end,
    })
    rawset(p, "_inv", inv)
    return p
end

local PLAYERS
function getSpecificPlayer(n) return PLAYERS[n] end
function getNumActivePlayers() return #PLAYERS + 1 end

local CLIENT = false
function isClient() return CLIENT end
local SENT = {}
function sendClientCommand(pl, mod, cmd, args) SENT[#SENT + 1] = { pl = pl, mod = mod, cmd = cmd, args = args } end
function getText(k) return k end
function getTexture(t) return { tex = t } end
function getTimestampMs() return 0 end
function print(...) end   -- (the files' log lines)
local realPrint = _G.print
print = function(...) end
local function say(s) io.write(s .. "\n") end

local HAVE_TO_TRANSFER = false
luautils = { haveToBeTransfered = function(p, item) return HAVE_TO_TRANSFER end }

-- the game's Read Map (the original the hook keeps)
ISInventoryPaneContextMenu = {}
ISInventoryPaneContextMenu.onCheckMap = function(map, player) log("vanilla:onCheckMap:" .. map:getName() .. ":" .. tostring(player)) end

-- the game's window (P.openVanilla)
ISCollapsableWindow = { TitleBarHeight = function() return 20 end }
function getPlayerScreenLeft() return 0 end
function getPlayerScreenTop() return 0 end
function getPlayerScreenWidth() return 1280 end
function getPlayerScreenHeight() return 800 end
ISMapWrapper = {}
ISMap = { SCALE = 0.666 }
function ISMap:new(x, y, w, h, item, player)
    log("vanilla:ISMap:" .. item:getName())
    local m = {}
    function m:initialise() end
    function m:wrapInCollapsableWindow(title, _, cls)
        log("vanilla:wrap:" .. title)
        return { setInfo = function() end, setWantKeyEvents = function() end, setVisible = function() end,
                 addToUIManager = function() log("vanilla:shown") end }
    end
    return m
end
JoypadState = { players = {} }
function setJoypadFocus() end

-- the paper's Init and the reveal (ISMapDefinitions)
LootMaps = { callLua = function(fn, mapUI)
    local item = mapUI.mapItem or mapUI.mapObj
    log("LootMaps:" .. fn .. ":" .. (item and item:getName() or "nil"))
    mapUI.mapAPI._bounds = { 10540, 9550, 10789, 9789 }   -- (MulStashMap1's)
end }
MapUtils = { revealKnownArea = function(mapUI)
    local b = mapUI.mapAPI._bounds
    log("reveal:" .. (b and table.concat(b, ",") or "nil"))
end }

-- the world map, the Map key's path (Overrides/WorldMap.lua)
local WORLD_ALLOWED = true
ISWorldMap = {
    IsAllowed = function() return WORLD_ALLOWED end,
    ShowWorldMap = function() log("vanilla:ShowWorldMap") end,
    HideWorldMap = function() log("vanilla:HideWorldMap") end,
    ToggleWorldMap = function() log("vanilla:ToggleWorldMap") end,
}
local QUEUE = {}
ISTimedActionQueue = { clear = function(p) QUEUE = {} end, add = function(a) QUEUE[#QUEUE + 1] = a end }
ISReadWorldMap = { new = function(_, p, cx, cy, z) return { kind = "ISReadWorldMap", p = p, cx = cx, cy = cy, zoom = z } end }
local IGNORE_AIM = {}
function setJoypadIgnoreAimUntilCentered(pn, b)
    if type(pn) ~= "number" or type(b) ~= "boolean" then error("setJoypadIgnoreAimUntilCentered(int, boolean)") end
    IGNORE_AIM[#IGNORE_AIM + 1] = pn
end

-- the map's Java side (a paper map panel)
local function newMapAPI()
    local api
    api = jobj("UIWorldMapV3", {
        setBoolean = function(_, k, v) api._bools[k] = v end,
        setMapItem = function(_, item) api._item = item; log("setMapItem:" .. item:getName()) end,
        getMinXInSquares = function() return api._bounds[1] end,
        getMinYInSquares = function() return api._bounds[2] end,
        getMaxXInSquares = function() return api._bounds[3] end,
        getMaxYInSquares = function() return api._bounds[4] end,
        getZoomF = function() return 17.5 end,
        resetView = function() api._resets = api._resets + 1 end,
        getStyleAPI = function() return jobj("WorldMapStyleV1", { getLayerByName = function() return nil end }) end,
        getSymbolsAPIv2 = function() return api._symbols end,
    })
    rawset(api, "_bools", {})
    rawset(api, "_resets", 0)
    rawset(api, "_symbols", { name = "paper symbols" })
    return api
end
local function newJava()
    return jobj("UIWorldMap", {
        setX = function() end, setY = function() end, setWidth = function() end, setHeight = function() end,
        setAnchorLeft = function() end, setAnchorRight = function() end, setAnchorTop = function() end,
        setAnchorBottom = function() end,
    })
end

-- ---------------------------------------------------------------------------
-- ZeD AROUND THE PIECE
-- ---------------------------------------------------------------------------
local LOADED = {}
local STUBBED = { ["ZeD/MapsTab"] = true, ["ZeD/Tokens"] = true, ["ZeD/Atoms"] = true, ["ZeD/AtomExtensions"] = true,
                  ["ZeD/Molecules"] = true, ["ZeD/Tr"] = true }
local function loadZeD(rel)
    local fn, err = loadfile(ROOT .. "42/media/lua/client/" .. rel)
    if not fn then error(err) end
    fn()
end
function require(name)
    if LOADED[name] then return end
    LOADED[name] = true
    if STUBBED[name] or not string.find(name, "^ZeD/") then return end
    loadZeD(name .. ".lua")
end

ZeD = {}
ZeD.tr = function(k, ...) return k end
ZeD.T = { px = function(n) return n end, hair = 1 }
ZeD.Molecules = { buttonW = function(text) return 10 * #text end }
local SAFE = false
ZeD.Safe = { on = function() return SAFE end }
ZeD.windowsFor = function(pn) return pn == nil or pn == 0 end   -- (Atoms.lua: split-screen, the first player's windows)
LOADED["ZeD/SafeMode"] = true

-- ZeD's map window (MapsTab.lua's openPopout / closePopout, as far as the piece leans on them)
local POPOUT_FAIL = false
ZeD.MapsTab = {}
function ZeD.MapsTab.openPopout(win, paperItem)
    if POPOUT_FAIL then error("no window") end
    if win._mapPopout then return end
    win._mapPopout = { _contentPanel = { name = "content" }, _isMapPopout = true }
    if ZeD.Input and ZeD.Input.Focus then ZeD.Input.Focus.register(win._mapPopout); ZeD.Input.Focus.claimFocus(win._mapPopout) end
    win._mapPaperItem = paperItem
    log(paperItem and ("zed:open:" .. paperItem:getName()) or "zed:open:world")
end
function ZeD.MapsTab.closePopout(win, keepWorld)
    if not win._mapPopout then return end
    log(win._mapPaperItem and ("zed:close:" .. win._mapPaperItem:getName()) or "zed:close:world")
    local pop, paper = win._mapPopout, win._mapPaperItem ~= nil
    win._mapPopout, win._mapPaperItem = nil, nil
    win._worldMapPanel = nil
    if ZeD.Input and ZeD.Input.Focus then ZeD.Input.Focus.unregisterWindow(pop) end
    if paper then pcall(ZeD.PaperMap.closed, win, pop, keepWorld) end   -- (as the real closePopout)
end

local WIN
ZeD_WorldWindow = {
    getWindow = function() return WIN end,
    isOpen = function() return WIN ~= nil end,
    open = function(pn)
        log("zed:worldWindow:" .. pn)
        WIN = { _playerObj = getSpecificPlayer(pn), _activeTab = "maps",
                _actionTabStrip = { _hitZones = { { id = "tab:maps", x = 0, y = 0 } }, onMouseDown = function() end } }
    end,
    -- (as the real close: the map pop-out folds with the window, then the window goes)
    close = function()
        if not WIN then return end
        local w = WIN
        ZeD.MapsTab.closePopout(w, true)
        if WIN ~= w then error("the World window closed twice") end
        log("zed:worldWindow:close")
        WIN = nil
    end,
}

loadZeD("ZeD/MapNotes.lua")
loadZeD("ZeD/MapsTabExt.lua")
loadZeD("ZeD/PaperMap.lua")
loadZeD("ZeD/Overrides/PaperMap.lua")
loadZeD("ZeD/Overrides/WorldMap.lua")
local P, Ext, N = ZeD.PaperMap, ZeD.MapsTabExt, ZeD.MapNotes
check("the real files load", P ~= nil and P.open ~= nil and Ext ~= nil and N ~= nil)
check("Read Map is wrapped, the original kept", ISInventoryPaneContextMenu.onCheckMap ~= ISInventoryPaneContextMenu._zedOrigCheckMap
    and ISInventoryPaneContextMenu._zedOrigCheckMap ~= nil)

local function fresh()
    LOG, SENT, QUEUE, IGNORE_AIM = {}, {}, {}, {}
    PLAYERS = { [0] = newPlayer(0), [1] = newPlayer(1) }
    WIN = nil
    SAFE, HAVE_TO_TRANSFER, POPOUT_FAIL, CLIENT, WORLD_ALLOWED = false, false, false, false, true
end
local function tick() for _, fn in ipairs(Events.OnTick.list) do fn() end end

-- a paper map panel as MapsTab makes it in the window (ZeD_WorldMap:new, then instantiate's paper branch)
local function makePanel(win)
    local mp = { x = 0, y = 0, width = 800, height = 600, playerObj = win._playerObj, _parentWin = win,
                 _paperItem = win._mapPaperItem }
    mp.javaObject = newJava()
    mp.mapAPI = newMapAPI()
    P.instantiate(mp, { { id = "x", tex = "media/ui/x.png" } })
    win._worldMapPanel = mp
    return mp
end

-- ---------------------------------------------------------------------------
section("Read Map opens ZeD's map on the paper, the game's read kept")
fresh()
local map = newItem("MulStashMap1", "MulStashMap1")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
check("ZeD's window opens on that paper", logHas("zed:open:MulStashMap1") and WIN ~= nil and WIN._mapPaperItem == map)
check("the World window is opened for that player", logHas("zed:worldWindow:0"))
check("the game's window is not", not logHas("vanilla:onCheckMap:MulStashMap1:0"))
check("the stash's building is made once", logCount("doBuildingStash:MulStashMap1") == 1)
check("the map counts as read once", logCount("addReadMap:MulStashMap1") == 1)
check("the game's order: the window, then read", (logIndex("zed:open:MulStashMap1") or 99) < (logIndex("addReadMap:MulStashMap1") or 0))

local mp = makePanel(WIN)
check("the panel is bound to the paper (its own marks: a stash's crosses)", mp.mapAPI._item == map and logHas("setMapItem:MulStashMap1"))
check("top-down, as vanilla's ISMap", mp.mapAPI._bools.Isometric == false)
check("none of the world map's settings (no fog, no players)", mp.mapAPI._bools.HideUnvisited == nil and mp.mapAPI._bools.Players == nil)
check("the paper's own Init (its area and look)", logHas("LootMaps:Init:MulStashMap1") and mp.mapObj == map)
check("its area is revealed on the world map", logHas("reveal:10540,9550,10789,9789"))
check("Init before the reveal", logIndex("LootMaps:Init:MulStashMap1") < logIndex("reveal:10540,9550,10789,9789"))
check("single player: nothing sent", #SENT == 0)
check("marks use this map's symbols", mp._zedNotesBound == true and N.panelAPI(mp) == mp.mapAPI._symbols)
P.frame(mp)
P.frame(mp)
check("the whole paper in view, once", mp.mapAPI._resets == 1)

section("multiplayer: the server learns the area, as vanilla's initMapData")
fresh()
CLIENT = true
map = newItem("RosewoodMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
mp = makePanel(WIN)
local s = SENT[1]
check("setKnownInSquares sent with the paper's bounds", s ~= nil and s.mod == "map" and s.cmd == "setKnownInSquares"
    and s.args.x1 == 10540 and s.args.y1 == 9550 and s.args.x2 == 10789 and s.args.y2 == 9789 and s.pl == PLAYERS[0])

section("the game's window where ZeD's should not open")
fresh()
SAFE = true
map = newItem("MuldraughMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
check("safe mode: the game's Read Map, untouched", logHas("vanilla:onCheckMap:MuldraughMap:0") and not logHas("zed:open:MuldraughMap")
    and not logHas("doBuildingStash:MuldraughMap"))

fresh()
HAVE_TO_TRANSFER = true
map = newItem("MuldraughMap")
ISInventoryPaneContextMenu.onCheckMap(map, 0)
check("a map in a bag: the game's transfer first", logHas("vanilla:onCheckMap:MuldraughMap:0") and not logHas("zed:open:MuldraughMap"))
HAVE_TO_TRANSFER = false
LOG = {}
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)   -- (the transfer's end calls Read Map again)
check("the transfer's end: ZeD's window", logHas("zed:open:MuldraughMap") and not logHas("vanilla:onCheckMap:MuldraughMap:0"))

fresh()
ZeD_WorldWindow.open(0)
LOG = {}
map = newItem("RiversideMap")
PLAYERS[1]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 1)
check("split screen: player 2 reads in the game's window (the World window is player 1's)",
    logHas("vanilla:onCheckMap:RiversideMap:1") and not logHas("zed:open:RiversideMap") and WIN._mapPopout == nil)

fresh()
POPOUT_FAIL = true
map = newItem("WestpointMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
check("ZeD's window cannot open: the game's Read Map, whole", logHas("vanilla:onCheckMap:WestpointMap:0"))
check("and the read is not done twice", logCount("doBuildingStash:WestpointMap") == 0 and logCount("addReadMap:WestpointMap") == 0)
check("and the World window opened for it goes again", WIN == nil and logHas("zed:worldWindow:close"))

section("an open world map gives way to the paper")
fresh()
ZeD_WorldWindow.open(0)
ZeD.MapsTab.openPopout(WIN)
LOG = {}
map = newItem("MarchRidgeMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
check("the world map folds, the paper opens", logHas("zed:close:world") and logHas("zed:open:MarchRidgeMap"))

section("put away when the map leaves the main inventory (ISMap:update)")
tick()
check("still held: still open", WIN._mapPopout ~= nil)
PLAYERS[0]._inv.items = {}
tick()
check("dropped: the window closes", WIN._mapPopout == nil and logHas("zed:close:MarchRidgeMap"))
fresh()
map = newItem("MarchRidgeMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
rawset(PLAYERS[0], "_dead", true)
tick()
check("the reader dies: the window closes", WIN == nil or WIN._mapPopout == nil)

section("a paper ZeD cannot draw goes to the game's window")
fresh()
map = newItem("LouisvilleMap1")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
LOG = {}
P.failed(WIN, "boom")
tick()
check("ZeD's window closes and the game's opens on the same map",
    logHas("zed:close:LouisvilleMap1") and logHas("vanilla:ISMap:LouisvilleMap1") and logHas("vanilla:shown"))
check("the read is not done again", not logHas("doBuildingStash:LouisvilleMap1") and not logHas("addReadMap:LouisvilleMap1"))
tick()
check("only once", logCount("vanilla:ISMap:LouisvilleMap1") == 1)

section("a stash map's reveal button (ISMap REVEAL)")
local R = P.ext
fresh()
map = newItem("RosewoodMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
check("not a stash map: no button", R.button(WIN) == nil)
fresh()
map = newItem("MulStashMap1", "MulStashMap1")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
mp = makePanel(WIN)
local b = R.button(WIN)
check("a stash map: the button, in ZeD's words", b ~= nil and b.text == "UI_ZeD_Map_PaperFind" and b.help == "UI_ZeD_Map_HelpPaperFind" and not b.dim)
b.activate(WIN)
local a = QUEUE[1]
check("the game's map-reading action on the paper's middle at its zoom",
    a ~= nil and a.kind == "ISReadWorldMap" and a.cx == (10540 + 10789) / 2 and a.cy == (9550 + 9789) / 2 and a.zoom == 17.5 and a.p == PLAYERS[0])
check("the stick's aim waits for center, as vanilla's", IGNORE_AIM[1] == 0)
WORLD_ALLOWED = false
b = R.button(WIN)
check("no world map on this server: greyed, with the reason", b.dim == true and b.hint == "UI_ZeD_Map_Unavailable")
QUEUE = {}
b.activate(WIN)
check("and it does nothing", #QUEUE == 0)
WORLD_ALLOWED = true
check("the world map's window: no button", R.button({ _mapPopout = {} }) == nil)

section("the band: the world map's extensions stay off a paper map")
Ext.list = {}
ZeD.MapsTab.addExtension("worldtool", { order = 1, button = function() return { id = "tp", glyph = function() end } end,
    armed = function() return true end })
ZeD.MapsTab.addExtension("paperfind", R)
local panel = WIN._mapPopout._contentPanel
check("on the paper: only the paper's button", Ext.buttonsW(WIN, panel, 20, true) == 10 * #"UI_ZeD_Map_PaperFind")
check("a world tool is never armed on the paper", Ext.anyArmed(WIN) == nil)
local worldWin = { _mapPopout = { _contentPanel = panel } }
check("on the world map: the world tool, no paper button", Ext.buttonsW(worldWin, panel, 20, true) == 20)
check("and it arms there", Ext.anyArmed(worldWin) ~= nil)
check("the paper map's own panel counts as paper", Ext.onPaper(mp, WIN) and Ext.onPaper({ _paperItem = map }) and not Ext.onPaper(worldWin))

section("marks go on the paper, not the world store")
local store = { name = "store" }
N._store = nil
MapItem = { getSingleton = function() return {} end }
UIWorldMap = { new = function() return { getAPIv3 = function() return { setMapItem = function() end, getSymbolsAPIv2 = function() return store end } end } end }
local added = {}
local function symApi(tag)
    return { addTexture = function(_, id, x, y) added[#added + 1] = tag .. ":" .. id
                 return { setRGBA = function() end, setAnchor = function() end, setScale = function() end } end,
             addTranslatedText = function(_, t, layer, x, y) added[#added + 1] = tag .. ":" .. t
                 return { setRGBA = function() end, setAnchor = function() end, setScale = function() end, setRotation = function() end,
                          setMatchPerspective = function() end, setMinZoom = function() end, setMaxZoom = function() end } end,
             getDefaultTextLayerID = function() return "text-note" end }
end
local paperApi, storeApi = symApi("paper"), symApi("store")
store = storeApi
MapSymbolDefinitions = nil
N.addSymbol("X", 1, 2, 1, paperApi)
N.addNote("cache here", 1, 2, 1, paperApi)
check("a mark and a note on the paper's symbols", added[1] == "paper:X" and added[2] == "paper:cache here")
N.addSymbol("X", 1, 2, 1)
check("without an api: the world map's store, as before", added[3] == "store:X")

section("the Map key and the world map with a paper open (Overrides/WorldMap.lua)")
fresh()
map = newItem("MuldraughMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
LOG = {}
ISWorldMap.HideWorldMap(0)
check("Hide (the world map's) leaves the paper open", WIN._mapPopout ~= nil and WIN._mapPaperItem == map and logHas("vanilla:HideWorldMap"))
LOG = {}
ISWorldMap.ToggleWorldMap(0)
check("the Map key reads the world map (the game's toggle), the paper stays till it opens",
    logHas("vanilla:ToggleWorldMap") and WIN._mapPaperItem == map)
LOG = {}
ISWorldMap.ShowWorldMap(0, 100, 200, 15)
check("the world map opens: the paper is put away first", logHas("zed:close:MuldraughMap") and logHas("zed:open:world")
    and logIndex("zed:close:MuldraughMap") < logIndex("zed:open:world"))
LOG = {}
ISWorldMap.ToggleWorldMap(0)
check("with the world map open the Map key still folds it", logHas("zed:close:world") and not logHas("vanilla:ToggleWorldMap"))

section("a World window opened only for the paper closes with it")
fresh()
map = newItem("MuldraughMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
check("Read Map opened the World window", logHas("zed:worldWindow:0") and WIN._mapPaperOwnsWindow == true)
local w0 = WIN
ZeD.MapsTab.closePopout(WIN)   -- (the close box, or B)
check("closing the paper closes that World window", WIN == nil and logCount("zed:worldWindow:close") == 1)
check("the paper is put away first", (logIndex("zed:close:MuldraughMap") or 99) < (logIndex("zed:worldWindow:close") or 0))
check("nothing left on the old window", w0._mapPaperOwnsWindow == nil and w0._mapPopout == nil)

fresh()
ZeD_WorldWindow.open(0)
map = newItem("MuldraughMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
check("a World window already open is not the paper's", WIN._mapPaperOwnsWindow == nil)
ZeD.MapsTab.closePopout(WIN)
check("closing the paper leaves it open", WIN ~= nil and not logHas("zed:worldWindow:close"))

fresh()
local mA, mB = newItem("MuldraughMap"), newItem("RosewoodMap")
PLAYERS[0]._inv.items = { mA, mB }
ISInventoryPaneContextMenu.onCheckMap(mA, 0)
ISInventoryPaneContextMenu.onCheckMap(mB, 0)
check("a second paper: the World window stays meanwhile", WIN ~= nil and WIN._mapPaperItem == mB and not logHas("zed:worldWindow:close"))
check("and the second paper owns it", WIN ~= nil and WIN._mapPaperOwnsWindow == true)
if WIN then ZeD.MapsTab.closePopout(WIN) end
check("closing the second paper closes it", WIN == nil and logCount("zed:worldWindow:close") == 1)

fresh()
map = newItem("MuldraughMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
PLAYERS[0]._inv.items = {}
tick()
check("the map leaves the inventory: paper and World window close", WIN == nil and logCount("zed:worldWindow:close") == 1)

fresh()
map = newItem("MulStashMap1", "MulStashMap1")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
makePanel(WIN)
P.ext.button(WIN).activate(WIN)
ISWorldMap.ShowWorldMap(0, 100, 200, 15)   -- (ISReadWorldMap:perform, the reading bar's end)
check("Find on map: the World window stays, the world map open in it",
    WIN ~= nil and WIN._mapPopout ~= nil and WIN._mapPaperItem == nil and not logHas("zed:worldWindow:close"))
if WIN then ZeD.MapsTab.closePopout(WIN) end
check("folding that world map leaves the World window (the player's now)", WIN ~= nil and not logHas("zed:worldWindow:close"))

fresh()
map = newItem("MuldraughMap")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
local okc, errc = pcall(ZeD_WorldWindow.close)   -- (the World window's own close box with the paper up)
check("the World window's own close: once, no second close from the paper", okc and WIN == nil
    and logCount("zed:worldWindow:close") == 1 and logHas("zed:close:MuldraughMap"), errc)

fresh()
map = newItem("LouisvilleMap1")
PLAYERS[0]._inv.items = { map }
ISInventoryPaneContextMenu.onCheckMap(map, 0)
P.failed(WIN, "boom")
tick()
check("a paper ZeD cannot draw: the World window opened for it goes, the game's window opens",
    WIN == nil and logHas("zed:worldWindow:close") and logHas("vanilla:shown"))

-- the real files: folds from inside the World window keep it (keepWorld)
local function src(rel)
    local f = io.open(ROOT .. "42/media/lua/client/" .. rel, "rb")
    local t = f:read("*a"); f:close(); return t
end
local mt, ww = src("ZeD/MapsTab.lua"), src("ZeD/ZeD_WorldWindow.lua")
local function count(t, pat) local n = 0 for _ in string.gmatch(t, pat) do n = n + 1 end return n end
check("MapsTab: closePopout takes keepWorld and hands it to PaperMap.closed",
    string.find(mt, "function ZeD.MapsTab.closePopout(win, keepWorld)", 1, true) ~= nil
    and string.find(mt, "pcall(ZeD.PaperMap.closed, win, pop, keepWorld)", 1, true) ~= nil)
check("MapsTab: the drawer's fold zone (mouse and pad) and unfold button keep the World window",
    count(mt, "ZeD%.MapsTab%.closePopout%(win, true%)") == 2 and count(mt, "ZeD%.MapsTab%.closePopout%(w, true%)") == 3)
check("ZeD_WorldWindow: every fold it makes is keepWorld (no second close from the paper)",
    count(ww, "closePopout%(") == count(ww, "closePopout%([%w_]+, true%)") and count(ww, "closePopout%(") >= 2)

section("the controller goes back to the window Read Map was chosen in")
local REG, FOCUSED = {}, nil
ZeD.Input = { Focus = {
    register = function(w) REG[#REG + 1] = w end,
    isRegistered = function(w) for _, x in ipairs(REG) do if x == w then return true end end return false end,
    getFocusedWindow = function() return FOCUSED end,
    claimFocus = function(w) FOCUSED = w end,
    unregisterWindow = function(w)
        for i = #REG, 1, -1 do if REG[i] == w then table.remove(REG, i) end end
        if FOCUSED == w then FOCUSED = REG[#REG] end
    end,
} }
local F = ZeD.Input.Focus
fresh()
local charWin = { name = "Character window" }
F.register(charWin)
FOCUSED = charWin
ZeD_WorldWindow.open(0)
F.register(WIN)          -- (the World window registers after; the manager's own hand-back would land there)
local m1, m2 = newItem("MuldraughMap"), newItem("RosewoodMap")
PLAYERS[0]._inv.items = { m1, m2 }
ISInventoryPaneContextMenu.onCheckMap(m1, 0)
check("the paper map takes the controller", FOCUSED == WIN._mapPopout)
ZeD.MapsTab.closePopout(WIN)
check("closed: back on the Character window, not the World window", FOCUSED == charWin)
FOCUSED = charWin
ISInventoryPaneContextMenu.onCheckMap(m1, 0)
ISInventoryPaneContextMenu.onCheckMap(m2, 0)   -- (a second paper read from the first's window)
check("a second paper over the first", WIN._mapPaperItem == m2 and FOCUSED == WIN._mapPopout)
ZeD.MapsTab.closePopout(WIN)
check("closed: back where the first was read, not a closed paper window", FOCUSED == charWin)
ISInventoryPaneContextMenu.onCheckMap(m1, 0)
for i = #REG, 1, -1 do if REG[i] == charWin then table.remove(REG, i) end end   -- (the Character window closes meanwhile)
ZeD.MapsTab.closePopout(WIN)
check("the reading window has closed: the manager's own hand-back", FOCUSED == WIN)
ZeD.Input = nil

-- ---------------------------------------------------------------------------
section("every close of the World window puts the paper away (the real closes, ZeD_WorldWindow.lua)")
-- The World window's own closes run from the real file: the win.close override (the close box, Organisms; the curtain
-- rod's close, WindowCurtain; the controller's close-all, FocusManager: each calls win:close()), toggle, close and
-- forceClose, with the helper they share when there is one. Each must leave no paper open and nothing for P.tick.
local function block(t, startPat, endPat)
    local s = string.find(t, startPat)
    if not s then return "" end
    local _, e = string.find(t, endPat, s)
    if not e then return "" end
    return string.sub(t, s, e)
end
local NL = "\r?\n"
local helperSrc   = block(ww, "local function _closeWorldWindow%(", NL .. "end" .. NL)
local overrideSrc = block(ww, "    win%.close = function%(self%)", NL .. "    end" .. NL)
local toggleSrc   = block(ww, "function ZeD_WorldWindow%.toggle%(", NL .. "end" .. NL)
local closeSrc    = block(ww, "function ZeD_WorldWindow%.close%(", NL .. "end" .. NL)
local forceSrc    = block(ww, "function ZeD_WorldWindow%.forceClose%(", NL .. "end" .. NL)
check("the World window's closes are found in the file", overrideSrc ~= "" and toggleSrc ~= "" and closeSrc ~= "" and forceSrc ~= "")
-- (the open windows are kept one a player, _worldWins[pn]; the first player's is the one here)
local chunk, cerr = loadstring("local ZeD_WorldWindow, SAVE = ...\nlocal _worldWins, _floorContainer = {}\n"
    .. "local function saveWorldState(w) SAVE(w) end\n" .. helperSrc .. toggleSrc .. closeSrc .. forceSrc
    .. "\nlocal function arm(win)\n" .. overrideSrc .. "\nend\n"
    .. "return { set = function(w) _worldWins[0] = w end, get = function() return _worldWins[0] end, arm = arm }")
check("and they compile", chunk ~= nil, cerr)

local REG2 = {}
local function regHas(w) for _, x in ipairs(REG2) do if x == w then return true end end return false end
local stubWW = ZeD_WorldWindow
local RW
if chunk then
    ZeD_WorldWindow = { _endZoneDraw = function() end }
    RW = chunk(ZeD_WorldWindow, function() end)
    ZeD_WorldWindow.getWindow = RW.get
    ZeD_WorldWindow.isOpen = function() return RW.get() ~= nil end
    ZeD_WorldWindow.open = function(pn)
        log("zed:worldWindow:" .. pn)
        local w = { _playerObj = getSpecificPlayer(pn), _shown = true }
        function w:removeFromUIManager() if self._shown then log("zed:worldWindow:close") end; self._shown = false end
        RW.arm(w)
        REG2[#REG2 + 1] = w
        RW.set(w)
    end
end
ZeD.Input = { Focus = {
    register = function(w) REG2[#REG2 + 1] = w end,
    registerWindow = function(w) REG2[#REG2 + 1] = w end,
    isRegistered = regHas,
    getFocusedWindow = function() return nil end,
    claimFocus = function() end,
    unregisterWindow = function(w) for i = #REG2, 1, -1 do if REG2[i] == w then table.remove(REG2, i) end end end,
} }
-- the pop-out closes itself as the real one (MapsTab.openPopout: pop.close folds it, without keepWorld)
local stubOpen = ZeD.MapsTab.openPopout
ZeD.MapsTab.openPopout = function(win, item)
    stubOpen(win, item)
    local pop = win._mapPopout
    if pop then pop.close = function() ZeD.MapsTab.closePopout(win) end end
end

local PATHS = {
    { "the close box (Organisms: self:close())", function(w) w:close() end },
    { "the curtain rod's close (WindowCurtain: self.win:close())", function(w) w:close() end },
    { "the controller's close-all (FocusManager: w:close() on each registered window)", function(w)
        local all = {}
        for _, x in ipairs(REG2) do all[#all + 1] = x end
        for _, x in ipairs(all) do if x.close then pcall(function() x:close() end) end end
    end },
    { "toggle", function(w) ZeD_WorldWindow.toggle(0) end },
    { "close", function(w) ZeD_WorldWindow.close() end },
    { "forceClose", function(w) ZeD_WorldWindow.forceClose() end },
}
for _, before in ipairs({ false, true }) do
    for _, path in ipairs(PATHS) do
        if not RW then break end
        fresh()
        REG2 = {}
        RW.set(nil)
        if before then ZeD_WorldWindow.open(0) end
        map = newItem("MuldraughMap")
        PLAYERS[0]._inv.items = { map }
        ISInventoryPaneContextMenu.onCheckMap(map, 0)
        local w, pop = RW.get(), RW.get() and RW.get()._mapPopout
        local tag = path[1] .. (before and ", World window open before" or ", World window opened by Read Map")
        check(tag .. ": the paper is up first", w ~= nil and pop ~= nil and w._mapPaperItem == map)
        if w and pop then
            local okp, errp = pcall(path[2], w)
            check(tag .. ": the World window closes", okp and RW.get() == nil and not w._shown and not regHas(w), errp)
            check(tag .. ": the paper goes with it, in the same close (not left for a tick)", w._mapPopout == nil
                and w._mapPaperItem == nil and not regHas(pop) and logHas("zed:close:MuldraughMap"))
            tick()
            check(tag .. ": once, nothing left for P.tick", logCount("zed:worldWindow:close") == 1
                and logCount("zed:close:MuldraughMap") == 1 and RW.get() == nil and #REG2 == 0)
        end
    end
end

section("P.tick: a World window gone with its paper still up does not leave the paper behind")
if RW then
    fresh()
    REG2 = {}
    RW.set(nil)
    map = newItem("MuldraughMap")
    PLAYERS[0]._inv.items = { map }
    ISInventoryPaneContextMenu.onCheckMap(map, 0)
    local w = RW.get()
    local pop = w and w._mapPopout
    RW.set(nil)   -- (the window dropped by a path that did not fold: a later close nobody wired)
    tick()
    check("the next tick puts the paper away", w ~= nil and w._mapPopout == nil and pop ~= nil and not regHas(pop)
        and logHas("zed:close:MuldraughMap"))
end

section("the controller on the World window's map placeholder folds as the mouse does (MapsTab map:fold)")
local foldSrc = block(mt, 'id = "map:fold",', "onCancel[^\n]*\n")
local actSrc = string.match(foldSrc, "onActivate%s*=%s*(function%b().-end),")
local canSrc = string.match(foldSrc, "onCancel%s*=%s*(function%b().-end),")
check("the placeholder's A and B are found", actSrc ~= nil and canSrc ~= nil)
for _, pair in ipairs({ { "A", actSrc }, { "B", canSrc } }) do
    local fn = pair[2] and loadstring("return " .. pair[2])
    fn = fn and fn()
    if fn and RW then
        fresh()
        REG2 = {}
        RW.set(nil)
        map = newItem("MuldraughMap")
        PLAYERS[0]._inv.items = { map }
        ISInventoryPaneContextMenu.onCheckMap(map, 0)
        local w = RW.get()
        local okf, errf = pcall(fn, w, {})
        check("pad " .. pair[1] .. " on the placeholder: the paper folds, the World window Read Map opened stays",
            okf and w ~= nil and w._mapPopout == nil and RW.get() == w and not logHas("zed:worldWindow:close"), errf)
    end
end
ZeD.MapsTab.openPopout = stubOpen
ZeD_WorldWindow = stubWW
ZeD.Input = nil

print = realPrint
say("paper_map_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
