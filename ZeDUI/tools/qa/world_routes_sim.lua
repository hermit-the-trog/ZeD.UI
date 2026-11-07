-- ZeDUI/tools/qa/world_routes_sim.lua  (Nov 7 2026, Build): the routes that used to open the game's radio, animal info
-- and livestock zone windows, with no game running (VANILLA_WINDOWS_20261107.md rows B1, B4, B5). It loads the real
-- ZeD/WorldRoutes.lua, Overrides/RadioWindow.lua and Overrides/Animals.lua, and cuts the Radio tab's list builders and
-- browse keys out of RadioTab.lua, over fake windows, players, devices and a fake cell.
--   ITEM     a radio in the hands goes to the Character window's Radio tab, on that radio; one in a bag does not
--   NEAR     a TV in the 3 x 3 goes to the World window's Radio tab, on that TV, listed once
--   FAR      a TV across the room is pinned into the list (Floor) while within 10 tiles; past 10 the game's window;
--            walking out drops the pin, walking back does not bring it again
--   PART     a car's device part from outside goes to the World window (Vehicle); a part whose radio is gone drops out
--   CAR      the car's radio from a front seat comes up close; when it can't, the World window
--   CARD     an object card over the tab is closed first
--   SPLIT    another player's window: the game's window
--   PAD      the pair opens for a pad player and the pad goes to the window three ticks later
--   HOOK     ISRadioWindow.activate: safe mode, a ZeD failure and a throw open the game's window; a handled one does not
--   FOLLOW   the browse keys move the follow mark with the radio
--   ANIMAL   onAnimalInfo and ISOpenAnimalInfo:perform show the animal in the Animals tab (the action still finishes)
--   ZONE     onCheckZone opens the zone's view (ranch, no animal, the cache read for a new zone)
--   NOTE     the first-time zone note: skipped under ZeD's window, shown when asked for or with no window
-- Run from the repo root:  lua51 ZeDUI/tools/qa/world_routes_sim.lua
-- It prints FAIL lines and a last line "world_routes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]world_routes_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

local function readFile(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r", ""))
end
local function cut(src, from)
    local a = string.find(src, from, 1, true)
    if not a then return nil end
    local _, b = string.find(src, "\nend\n", a, true)
    return string.sub(src, a, b)
end

-- ---------------------------------------------------------------------------
-- THE GAME, FAKED
-- ---------------------------------------------------------------------------
local CLASSES = {
    Radio = { Radio = true, InventoryItem = true },
    Item = { InventoryItem = true },
    Tv = { IsoWaveSignal = true, IsoObject = true },
    Part = { VehiclePart = true },
}
function instanceof(o, cls)
    local c = type(o) == "table" and o._cls and CLASSES[o._cls]
    return c ~= nil and c[cls] == true
end

local ticks = {}
local function event() local e = {}; e.Add = function(f) ticks[#ticks + 1] = f end
    e.Remove = function(f) for i = #ticks, 1, -1 do if ticks[i] == f then table.remove(ticks, i) end end end; return e end
Events = { OnTick = event(), OnGameBoot = { Add = function() end }, OnEquipPrimary = { Add = function() end, Remove = function() end },
    OnEquipSecondary = { Add = function() end, Remove = function() end } }
local function runTicks(n) for _ = 1, n do local list = {}; for i, f in ipairs(ticks) do list[i] = f end; for _, f in ipairs(list) do f() end end end

JoypadState = { players = {} }
function getText(k) return "[" .. k .. "]" end
function isClient() return false end
function require() end
print = (function(p) return function(s) if not tostring(s):find("^%[ZeD%]") then p(s) end end end)(print)

local players = {}
local function newPlayer(n, x, y)
    local p = { n = n, x = x, y = y, z = 0, hands = {} }
    function p:getPlayerNum() return self.n end
    function p:getX() return self.x end
    function p:getY() return self.y end
    function p:getZ() return self.z end
    function p:getPrimaryHandItem() return self.hands.primary end
    function p:getSecondaryHandItem() return self.hands.secondary end
    function p:getClothingItem_Back() return self.hands.back end
    function p:getCurrentSquare() return SQ(math.floor(self.x), math.floor(self.y), 0) end
    function p:getVehicle() return self.vehicle end
    players[n] = p
    return p
end
function getSpecificPlayer(n) return players[n] end

-- the cell: squares on demand, every square reaches every other, objects placed by hand
local squares = {}
function SQ(x, y, z)
    local k = x .. "," .. y .. "," .. z
    if not squares[k] then
        local s = { x = x, y = y, z = z, objs = {} }
        function s:getObjects() local o = self.objs; return { size = function() return #o end, get = function(_, i) return o[i + 1] end } end
        function s:canReachTo() return true end
        function s:getX() return self.x end
        function s:getY() return self.y end
        function s:getZ() return self.z end
        squares[k] = s
    end
    return squares[k]
end
function getCell() return { getGridSquare = function(_, x, y, z) return SQ(x, y, z) end } end

local function dd() return { getDeviceName = function() return "Set" end } end
local function newTv(x, y)
    local t = { _cls = "Tv", x = x, y = y, z = 0, dd = dd() }
    function t:getDeviceData() return self.dd end
    function t:getSquare() if self.gone then return nil end; return SQ(self.x, self.y, 0) end
    function t:getX() return self.x end
    function t:getY() return self.y end
    function t:getZ() return self.z end
    table.insert(SQ(x, y, 0).objs, t)
    return t
end
local function newRadio() local r = { _cls = "Radio", dd = dd() }; function r:getDeviceData() return self.dd end; return r end
local function newPart(id, x, y)
    local veh = { getId = function() return 7 end }
    local p = { _cls = "Part", id = id, x = x, y = y, dd = dd(), item = {}, veh = veh }
    function p:getId() return self.id end
    function p:getVehicle() return self.veh end
    function p:getItemType() local t = { "Base.Radio" }; return { isEmpty = function() return #t == 0 end } end
    function p:getInventoryItem() return self.item end
    function p:getDeviceData() return self.dd end
    function p:getX() return self.x end
    function p:getY() return self.y end
    return p
end

-- ZeD's pieces the routes use
ZeD = { Safe = { on = function() return ZeD._safe == true end, register = function() end } }
ZeD.Input = { Focus = { claimFocus = function(w) ZeD._claimed = w end } }

local log
local function windowModule(name, kind)
    local M = { win = nil }
    function M.getWindow() return M.win end
    function M.openTab(pn, tab)
        log[#log + 1] = name .. ":" .. tab
        if M.refuse then return false end
        if not M.win then
            M.win = { _playerObj = getSpecificPlayer(pn), _kind = kind }
            if kind == "world" then M.win._radios = ZeD.RadioTab.buildWorldRadios(M.win._playerObj) end
        end
        M.win._activeTab = tab
        return true
    end
    function M.ensureBothOpenForGamepad(pn) log[#log + 1] = "pair:" .. pn end
    return M
end
local function resetWindows()
    log = {}
    ZeD_WorldWindow = windowModule("world", "world")
    ZeD_CharacterWindow = windowModule("char", "char")
    ZeD_CharacterWindow.getInstance = ZeD_CharacterWindow.getWindow
    ZeD_WorldWindow.card = nil
    ZeD_WorldWindow.getObjectCard = function() return ZeD_WorldWindow.card end
    ZeD_WorldWindow.closeObjectCard = function() log[#log + 1] = "closeCard"; ZeD_WorldWindow.card = nil end
    JoypadState.players = {}
    ZeD._claimed = nil
    ZeD._safe = false
    ticks = {}
end

-- ---------------------------------------------------------------------------
-- THE REAL PIECES
-- ---------------------------------------------------------------------------
ZeD.RadioTab = {}
do
    local src = readFile(Z .. "RadioTab.lua")
    local parts = {
        (cut(src, "local function _hasDeviceData(") or ""):gsub("^local function", "function", 1),
        cut(src, "function ZeD.RadioTab.locationName(") or "",
        cut(src, "function ZeD.RadioTab.indexOf(") or "",
        cut(src, "function ZeD.RadioTab.buildEquippedRadios(") or "",
        cut(src, "function ZeD.RadioTab.buildWorldRadios(") or "",
        (cut(src, "local function _browsePrev(") or ""):gsub("^local function _browsePrev", "function _browsePrev", 1),
        ((cut(src, "local function _browseNext(") or ""):gsub("^local function _browseNext", "function _browseNext", 1)),
    }
    for i, p in ipairs(parts) do check("RadioTab piece " .. i .. " found", p ~= "") end
    assert(loadstring(table.concat(parts, "\n")))()
    check("RadioTab render follows the radio", src:find("if win._radioFollow then", 1, true) ~= nil)
end
assert(loadfile(Z .. "WorldRoutes.lua"))()
local WR = ZeD.WorldRoutes
check("WorldRoutes loads", WR and WR.radio and WR.animal and WR.zone)

-- ---------------------------------------------------------------------------
-- RADIO ROUTES
-- ---------------------------------------------------------------------------
local p0 = newPlayer(0, 100.5, 100.5)
local p1 = newPlayer(1, 300.5, 300.5)

-- ITEM
resetWindows()
local r = newRadio()
p0.hands.primary = r
check("ITEM handled", WR.radio(p0, r) == true)
local cw = ZeD_CharacterWindow.win
check("ITEM Character window Radio tab", cw and cw._activeTab == "radio")
check("ITEM on that radio", cw and cw._radios[cw._radioIdx] and cw._radios[cw._radioIdx].radioInstance == r)
check("ITEM follow", cw and cw._radioFollow == r)
check("ITEM no World window", ZeD_WorldWindow.win == nil)
p0.hands.primary = nil
resetWindows()
check("ITEM in a bag: the game's window", WR.radio(p0, r) == false)

-- NEAR
resetWindows()
local tvNear = newTv(101, 101)
check("NEAR handled", WR.radio(p0, tvNear) == true)
local ww = ZeD_WorldWindow.win
check("NEAR World window Radio tab", ww and ww._activeTab == "radio")
check("NEAR on that TV", ww and ww._radios[ww._radioIdx].radioInstance == tvNear)
local n = 0
for _, e in ipairs(ww._radios) do if e.radioInstance == tvNear then n = n + 1 end end
check("NEAR listed once", n == 1, n)

-- FAR
resetWindows()
local tvFar = newTv(106, 103)
check("FAR handled", WR.radio(p0, tvFar) == true)
ww = ZeD_WorldWindow.win
local cur = ww and ww._radios[ww._radioIdx]
check("FAR on that TV", cur and cur.radioInstance == tvFar)
check("FAR pinned, Floor", cur and cur.pinned == true and cur.locationTag == "Floor")
check("FAR the near TV still first", ww._radios[1].radioInstance == tvNear)
check("FAR rebuilt list keeps it", ZeD.RadioTab.indexOf(ZeD.RadioTab.buildWorldRadios(p0), tvFar) ~= nil)
p0.x = 120.5
check("FAR walked out: gone", ZeD.RadioTab.indexOf(ZeD.RadioTab.buildWorldRadios(p0), tvFar) == nil)
p0.x = 100.5
check("FAR walked back: not again", ZeD.RadioTab.indexOf(ZeD.RadioTab.buildWorldRadios(p0), tvFar) == nil)
resetWindows()
local tvGone = newTv(112, 100)
check("FAR past 10 tiles: the game's window", WR.radio(p0, tvGone) == false)
check("FAR past 10: no pin left", WR.pins[0] == nil)
resetWindows()
tvFar.gone = true
check("FAR a set picked up: the game's window", WR.radio(p0, tvFar) == false)
tvFar.gone = nil

-- PART
resetWindows()
local part = newPart("Radio", 104, 100)
check("PART handled", WR.radio(p0, part) == true)
ww = ZeD_WorldWindow.win
cur = ww and ww._radios[ww._radioIdx]
check("PART on that part", cur and cur.radioInstance == part)
check("PART Vehicle tag", cur and cur.locationTag == "Vehicle")
check("PART tag in words", ZeD.RadioTab.locationName("Vehicle") == "[UI_optionscreen_binding_Vehicle]")
check("PART cache key", cur and cur.cacheKey == "v:7:Radio", cur and cur.cacheKey)
part.item = nil
check("PART radio taken out: gone", ZeD.RadioTab.indexOf(ZeD.RadioTab.buildWorldRadios(p0), part) == nil)
local heater = newPart("SomeModDevice", 103, 100)
resetWindows()
check("PART a mod's device part handled", WR.radio(p0, heater) == true and ZeD_WorldWindow.win ~= nil)

-- CAR
resetWindows()
local carPart = newPart("Radio", 100, 100)
local toggled
ZeD.RadioOps = { reachable = function(chr) return chr.seated and carPart or nil end }
ZeD.CarRadio = { toggle = function(chr, prt) toggled = prt end }
p0.seated = true
check("CAR front seat handled", WR.radio(p0, carPart) == true)
check("CAR up close", toggled == carPart)
check("CAR no window", ZeD_WorldWindow.win == nil and ZeD_CharacterWindow.win == nil)
resetWindows()
ZeD.CarRadio.toggle = function() error("no face for this radio") end
check("CAR no face: handled", WR.radio(p0, carPart) == true)
check("CAR no face: World window", ZeD_WorldWindow.win ~= nil and ZeD_WorldWindow.win._activeTab == "radio")
p0.seated = nil
ZeD.RadioOps, ZeD.CarRadio = nil, nil

-- CARD
resetWindows()
ZeD_WorldWindow.win = { _playerObj = p0 }
ZeD_WorldWindow.card = {}
WR.radio(p0, tvNear)
check("CARD closed before the tab", log[1] == "closeCard" and log[2] == "world:radio", table.concat(log, " "))

-- SPLIT
resetWindows()
ZeD_WorldWindow.win = { _playerObj = p0 }
local tvP1 = newTv(301, 301)
check("SPLIT player 1, player 0's window: the game's window", WR.radio(p1, tvP1) == false)
check("SPLIT no tab pressed", #log == 0)
check("SPLIT no pin left for player 1", WR.pins[1] == nil)
ZeD_WorldWindow.win = nil
check("SPLIT player 1 with no window: handled", WR.radio(p1, tvP1) == true and ZeD_WorldWindow.win._playerObj == p1)

-- refused tab
resetWindows()
ZeD_WorldWindow.refuse = true
check("refused tab: the game's window", WR.radio(p0, tvFar) == false)
check("refused tab: no pin left", WR.pins[0] == nil)

-- PAD
resetWindows()
JoypadState.players[1] = {}
WR.radio(p0, tvNear)
check("PAD the pair opens first", log[1] == "pair:0", log[1])
runTicks(2)
check("PAD not yet", ZeD._claimed == nil)
runTicks(1)
check("PAD the pad goes to the World window", ZeD._claimed == ZeD_WorldWindow.win)
check("PAD the tick is gone", #ticks == 0)
resetWindows()
WR.radio(p0, tvNear)
runTicks(5)
check("PAD a mouse player: no pair, no claim", log[1] == "world:radio" and ZeD._claimed == nil)

-- FOLLOW
do
    local win = { _radios = { { radioInstance = "a" }, { radioInstance = "b" }, { radioInstance = "c" } }, _radioIdx = 1 }
    _browseNext(win)
    check("FOLLOW next", win._radioFollow == "b")
    _browsePrev(win); _browsePrev(win)
    check("FOLLOW prev wraps", win._radioFollow == "c")
end

-- HOOK: Overrides/RadioWindow.lua over a fake ISRadioWindow
local vanillaCalls = 0
ISRadioWindow = { onEquip = function() end, activate = function() vanillaCalls = vanillaCalls + 1; return "window" end }
assert(loadfile(Z .. "Overrides/RadioWindow.lua"))()
check("HOOK wrapped", ISRadioWindow._zedRoute ~= nil)
resetWindows()
check("HOOK handled: nothing back", ISRadioWindow.activate(p0, tvNear) == nil and vanillaCalls == 0)
resetWindows()
ZeD._safe = true
check("HOOK safe mode: the game's window", ISRadioWindow.activate(p0, tvNear) == "window" and vanillaCalls == 1)
check("HOOK safe mode: no ZeD window", ZeD_WorldWindow.win == nil)
resetWindows()
check("HOOK declined: the game's window", ISRadioWindow.activate(p0, tvGone) == "window" and vanillaCalls == 2)
local realRadio = WR.radio
WR.radio = function() error("boom") end
check("HOOK a throw: the game's window", ISRadioWindow.activate(p0, tvNear) == "window" and vanillaCalls == 3)
WR.radio = realRadio
assert(loadfile(Z .. "Overrides/RadioWindow.lua"))()
resetWindows()
ISRadioWindow.activate(p0, tvNear)
check("HOOK loaded twice wraps once", vanillaCalls == 3)

-- ---------------------------------------------------------------------------
-- ANIMALS
-- ---------------------------------------------------------------------------
local shown, navs, refreshed
local function resetAnimals()
    resetWindows()
    shown, navs, refreshed = nil, {}, 0
    local state = {}
    ZeD.AnimalsTab = {
        showAnimal = function(win, a) shown = { win = win, a = a } end,
        getState = function(win) win._st = win._st or state; return win._st end,
        navigate = function(win, view, zn, ar) navs[#navs + 1] = { view = view, zn = zn }; local s = win._st; s.view = view; if zn then s.zoneName = zn end end,
    }
    ZeD.AnimalsAlertPoller = { summaries = {}, getZoneSummary = function(n) return ZeD.AnimalsAlertPoller.summaries[n] end,
        refreshCache = function() refreshed = refreshed + 1 end }
end
ZeD.ObjectCards = {}
local origInfo, origPerform, origZone, origNote = 0, 0, 0, 0
local finished = 0
AnimalContextMenu = {
    onAnimalInfo = function() origInfo = origInfo + 1 end,
    onCheckZone = function() origZone = origZone + 1 end,
}
ISBaseTimedAction = { perform = function() finished = finished + 1 end }
ISOpenAnimalInfo = { perform = function() origPerform = origPerform + 1 end }
ISAnimalZoneFirstInfo = { showUI = function() origNote = origNote + 1 end }
assert(loadfile(Z .. "Overrides/Animals.lua"))()
check("ANIMAL hooks in", AnimalContextMenu._zedInfoHooked and AnimalContextMenu._zedZoneHooked and ISOpenAnimalInfo._zedCardHooked
    and ISAnimalZoneFirstInfo._zedHooked)

-- ANIMAL
resetAnimals()
local cow = { name = "cow" }
AnimalContextMenu.onAnimalInfo(cow, p0)
check("ANIMAL Animals tab", ZeD_WorldWindow.win and ZeD_WorldWindow.win._activeTab == "animals")
check("ANIMAL on that animal", shown and shown.a == cow and shown.win == ZeD_WorldWindow.win)
check("ANIMAL no game window", origInfo == 0)
resetAnimals()
ZeD._safe = true
AnimalContextMenu.onAnimalInfo(cow, p0)
check("ANIMAL safe mode: the game's window", origInfo == 1 and shown == nil)
resetAnimals()
ZeD_WorldWindow.refuse = true
AnimalContextMenu.onAnimalInfo(cow, p0)
check("ANIMAL no window: the game's window", origInfo == 2)
resetAnimals()
ZeD_WorldWindow.win = { _playerObj = p0 }
AnimalContextMenu.onAnimalInfo(cow, p1)
check("ANIMAL another player's window: the game's window", origInfo == 3 and shown == nil)
resetAnimals()
ZeD_WorldWindow.win = { _playerObj = p0 }
ZeD_WorldWindow.card = {}
AnimalContextMenu.onAnimalInfo(cow, p0)
check("ANIMAL a card over the tab closes", log[1] == "closeCard")
resetAnimals()
ISOpenAnimalInfo.perform({ character = p0, animal = cow })
check("ANIMAL the action shows it", shown and shown.a == cow)
check("ANIMAL the action finishes", finished == 1 and origPerform == 0)
resetAnimals()
ZeD._safe = true
ISOpenAnimalInfo.perform({ character = p0, animal = cow })
check("ANIMAL the action in safe mode: the game's", origPerform == 1 and finished == 1)
resetAnimals()
JoypadState.players[1] = {}
AnimalContextMenu.onAnimalInfo(cow, p0)
runTicks(3)
check("ANIMAL pad: pair and claim", log[1] == "pair:0" and ZeD._claimed == ZeD_WorldWindow.win)

-- ZONE
local zone = { getName = function() return "Pasture" end }
resetAnimals()
AnimalContextMenu.onCheckZone(zone, p0)
local st = ZeD_WorldWindow.win and ZeD_WorldWindow.win._st
check("ZONE Animals tab", ZeD_WorldWindow.win and ZeD_WorldWindow.win._activeTab == "animals")
check("ZONE that zone's view", navs[1] and navs[1].view == "zone" and navs[1].zn == "Pasture")
check("ZONE ranch, no animal", st and st.submode == "ranch" and st.animalRef == nil)
check("ZONE a new zone: cache read", refreshed == 1)
check("ZONE no game window", origZone == 0)
resetAnimals()
ZeD.AnimalsAlertPoller.summaries.Pasture = {}
AnimalContextMenu.onCheckZone(zone, p0)
check("ZONE a known zone: no read", refreshed == 0)
resetAnimals()
JoypadState.players[1] = {}
AnimalContextMenu.onCheckZone(zone, p0)
check("ZONE pad lands on the breadcrumb", ZeD_WorldWindow.win._animalsNavFocusTarget == "breadcrumb")
resetAnimals()
ZeD._safe = true
AnimalContextMenu.onCheckZone(zone, p0)
check("ZONE safe mode: the game's window", origZone == 1)
resetAnimals()
AnimalContextMenu.onCheckZone({ getName = function() error("gone") end }, p0)
check("ZONE a zone with no name: the game's window", origZone == 2)

-- NOTE
resetAnimals()
ISAnimalZoneFirstInfo.showUI(0, false)
check("NOTE no window: shown", origNote == 1)
ZeD_WorldWindow.win = { _playerObj = p0 }
ISAnimalZoneFirstInfo.showUI(0, false)
check("NOTE under ZeD's window: skipped", origNote == 1)
ISAnimalZoneFirstInfo.showUI(0, true)
check("NOTE asked for: shown", origNote == 2)
ISAnimalZoneFirstInfo.showUI(1, false)
check("NOTE player 1 under player 0's window: shown", origNote == 3)
ZeD._safe = true
ISAnimalZoneFirstInfo.showUI(0, false)
check("NOTE safe mode: shown", origNote == 4)

print("world_routes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
