-- ZeDUI/tools/qa/kiss_k3_pad_sim.lua  (Nov 22 2026, Build): the director's KISS K3 picks in the wheels, the hint
-- strip, the quick actions, the belt's Messages count and the moodles' quick list, with no game running. The real
-- ZeD files run on Lua 5.1 in a forgiving world (any global or field nobody set is a stand-in that takes any call).
--   #15  the World wheel's Crafting opens by hand; the nearest station gets a slice of its own, last, named for it
--   #20  seated, D-pad Up opens the car's wheel (the game's vehicle filler) at once; on foot it is Social
--   #21  D-pad Left held past the game's repeat time goes to the Weapons ring; a tap stays on the Character wheel
--   #36  the World wheel's Map slice opens the map; RB + Y's default and an old saved "world:2:1" find that slice
--   #26  the hint strip's first hours' line on a pad: D-pad Wheels, LB or RB + button Quick actions, each half gone
--        after three uses
--   #42  the Messages count: red only for ZeD's own new error, the accent for a note, gray for other mods' errors
--   #49  a click on Hungry, Thirsty or a wound moodle: the wheel's list, the best pick first
-- Run from the repo root:  lua51 ZeDUI/tools/qa/kiss_k3_pad_sim.lua
-- It prints FAIL lines and a last line "kiss_k3_pad_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]kiss_k3_pad_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local autoMT = {}
local function auto() return setmetatable({}, autoMT) end
autoMT.__index = function(t, k) return auto() end
autoMT.__call = function() return auto() end
autoMT.__concat = function(a, b) return "" end
autoMT.__unm = function() return 0 end
for _, m in ipairs({ "__add", "__sub", "__mul", "__div", "__mod", "__pow" }) do autoMT[m] = function() return 0 end end
setmetatable(_G, { __index = function(t, k)
    if k == "arg" then return nil end
    local s = auto(); rawset(t, k, s); return s
end })

local clock = 1000000
function getTimestampMs() return clock end
function getText(k, a, b) if a then return k .. "(" .. tostring(a) .. (b and ("," .. tostring(b)) or "") .. ")" end return k end
function instanceof(o, cls) return type(o) == "table" and o._class == cls end
function require() return true end
function isClient() return false end
function getGameSpeed() return 1 end
function getModInfoByID() return { getName = function() return "ZeD-GUI [BETA]" end } end
function getFileReader() return nil end   -- (no files: the chords and hints start from their defaults)
function getFileWriter() return { write = function() end, close = function() end } end
JoypadState = { players = {} }
Joypad = { AButton = 1, BButton = 2, XButton = 3, YButton = 4, DPadLeft = 10, DPadUp = 11 }
UIManager = { getSpeedControls = function() return { getCurrentGameSpeed = function() return 1 end } end }
local HALO = {}
HaloTextHelper = { addBadText = function(p, t) HALO[#HALO + 1] = t end }

ZeD = setmetatable({}, { __index = function(t, k) return auto() end })
ZeD.Safe = { on = function() return false end, register = function() end }
function ZeD.tr(k, a) if a ~= nil then return k .. "(" .. tostring(a) .. ")" end return k end
function ZeD.logOnce(where, err) print("logOnce " .. tostring(where) .. ": " .. tostring(err)) end
function ZeD.windowsFor() return true end

local function loadZ(path)
    local f, err = loadfile(CLIENT .. path)
    if not f then return false, err end
    return pcall(f)
end

-- a player: in a car or not, the inventory empty
local CAR = nil
local P = { getVehicle = function() return CAR end, isDead = function() return false end, getPlayerNum = function() return 0 end,
            getInventory = function() return { getItems = function() return { size = function() return 0 end } end } end,
            getPrimaryHandItem = function() return nil end, getSecondaryHandItem = function() return nil end,
            setJoypadIgnoreAimUntilCentered = function() end }
function getSpecificPlayer() return P end

ZeD.DpadWheels, ZeD.WheelGesture = {}, {}
ZeD.Wheel = { iconTex = function() return nil end, TAB_ICONS = {}, isBack = function() return false end, isPlace = function() return false end }
ZeD.QuickWheel = {}
check("ZeD_QuickWheel.lua loads", loadZ("ZeD_QuickWheel.lua"))
local okD, errD = loadZ("ZeD_DpadWheels.lua")
check("ZeD_DpadWheels.lua loads", okD, errD)
local D, H = ZeD.DpadWheels, ZeD.DpadWheels.H

-- ===========================================================================
section("#15 Crafting by hand, the bench its own slice")
-- ===========================================================================
do
    local opened = nil
    ZeD.Stations = { open = function(p, obj) opened = obj end, tilesText = function(d) return d .. " tiles" end }
    H.nearestStation = function() return nil end
    local list = D.Wd.craft(P, 0)
    check("no station: three slices", #list == 3, #list)
    local worldTab = nil
    H.worldTab = function(p, n, id) worldTab = id end
    list[1].run(P, 0)
    check("Crafting opens the Craft tab by hand", worldTab == "craft", worldTab)
    local OVEN = {}
    H.nearestStation = function() return { name = "Oven", dist = 2, obj = OVEN } end
    list = D.Wd.craft(P, 0)
    check("a station near: four slices", #list == 4, #list)
    worldTab = nil
    list[1].run(P, 0)
    check("Crafting still opens by hand in a kitchen", worldTab == "craft" and opened == nil, worldTab)
    check("the station's slice last, named for it", list[4].name == "Oven" and list[4].detail == "2 tiles", list[4].name)
    list[4].run(P, 0)
    check("its slice opens that station", opened == OVEN)
    check("Building and Move furniture keep their places", list[2].name == "UI_ZeD_World_TabBuilding" and list[3].name == "IGUI_BackButton_Movable")
end

-- ===========================================================================
section("#36 Map at once, and its chord")
-- ===========================================================================
do
    local world = D.B.world(P, 0)
    check("Map is the World wheel's second slice and runs", world[2] and world[2].name == "UI_ZeD_Wheel_Map"
        and type(world[2].run) == "function" and world[2].sub == nil)
    ZeD.QuickChords = {}
    local okQ, errQ = loadZ("ZeD_QuickChords.lua")
    check("ZeD_QuickChords.lua loads", okQ, errQ)
    local Q = ZeD.QuickChords
    check("RB + Y's default is the Map slice", Q.DEFAULTS["RB+Y"][1] == "world:2", Q.DEFAULTS["RB+Y"][1])
    local e = Q.resolve(P, 0, "world:2")
    check("world:2 resolves to Map", e and e.name == "UI_ZeD_Wheel_Map")
    local old = Q.resolve(P, 0, "world:2:1")
    check("an old saved world:2:1 finds the Map slice too", old and old.name == "UI_ZeD_Wheel_Map")
end

-- ===========================================================================
section("#20 seated, D-pad Up is the car's wheel")
-- ===========================================================================
do
    local filled = 0
    ISVehicleMenu = { showRadialMenu = function() filled = filled + 1 end }
    local G = ZeD.WheelGesture
    G.begin = function(pn, st) st.mode = "tap" end
    G.level = function() end
    G.finish = function(pn, st) if D.state[pn] == st then D.state[pn] = nil end end
    local MENU = { slices = {} }
    function MENU:clear() self.slices = {} end
    function MENU:addSlice(t, tex, fn, a, b) self.slices[#self.slices + 1] = { text = t, command = { fn, a, b } } end
    for _, k in ipairs({ "setX", "setY", "setHideWhenButtonReleased", "addToUIManager", "removeFromUIManager", "setVisible", "undisplay" }) do
        MENU[k] = function() end
    end
    function MENU:getWidth() return 100 end
    function MENU:getHeight() return 100 end
    function getPlayerRadialMenu() return MENU end
    ZeD.Wheel.isBack = function() return false end
    H.dashSlice = function() end
    CAR = { isDriver = function() return true end }
    D.open("up", { player = 0 })
    local st = D.state[0]
    check("seated: the wheel opens on the car's wheel", st and st.path[1].fill == D.vehicleFill and filled == 1, filled)
    check("with no Back slice of its own at the top", #MENU.slices == 0, #MENU.slices)
    D.close(0)
    CAR = nil
    D.open("up", { player = 0 })
    st = D.state[0]
    check("on foot: Social", st and st.path[1].fill == nil and st.path[1].entries and #st.path[1].entries >= 5)
    D.close(0)
end

-- ===========================================================================
section("#21 D-pad Left held: Weapons")
-- ===========================================================================
do
    local entered = nil
    local realEnter = D.enter
    D.enter = function(pn, e) entered = e end
    H.weapons = function() return { { name = "Axe", run = function() end } } end
    D.qaHeld[0] = 50
    D.open("left", { player = 0 })
    D.holdTick(0)
    check("held a moment: still the Character wheel", entered == nil)
    D.qaHeld[0] = D.HOLD_WEAPONS_MS
    D.holdTick(0)
    check("held past the game's repeat time: the Weapons ring", entered ~= nil and entered.sub == D.C.weapons)
    entered = nil
    D.holdTick(0)
    check("once only", entered == nil)
    D.close(0)
    D.qaHeld[0] = 50
    D.open("left", { player = 0 })
    D.holdTick(0)
    D.qaHeld[0] = false   -- (let go: a tap)
    D.holdTick(0)
    D.qaHeld[0] = 400
    D.holdTick(0)
    check("a tap stays on the Character wheel", entered == nil)
    D.close(0)
    D.qaHeld[0] = 400
    D.open("left", { player = 0 })
    D.state[0].mode = "hold"
    D.holdTick(0)
    check("not with the Hold setting", entered == nil)
    D.close(0)
    H.weapons = function() return {} end
    D.qaHeld[0] = 400
    D.open("left", { player = 0 })
    D.holdTick(0)
    check("no weapon: the Character wheel stays", entered == nil)
    D.close(0)
    D.qaHeld[0] = nil
    D.enter = realEnter
end

-- ===========================================================================
section("#26 the pad's first hours' line")
-- ===========================================================================
do
    function getFileReader() return nil end
    function getFileWriter() return { write = function() end, close = function() end } end
    ZeD.Settings = { hintStripMode = function() return "always" end }
    function getFocusForPlayer() return nil end
    P.isAsleep = function() return false end
    ZeD_Panel = { derive = function(self) return setmetatable({}, { __index = self }) end }
    ZeD.HintStrip = {}
    local okH, errH = loadZ("ZeD_HintStrip.lua")
    check("ZeD_HintStrip.lua loads", okH, errH)
    local HS = ZeD.HintStrip
    check("keyboard: no line", HS.teach(0) == nil)
    JoypadState.players[1] = {}
    local t = HS.teach(0)
    check("pad: D-pad Wheels, LB or RB + button Quick actions", t and #t == 3 and t[1].glyph == "D-PAD" and t[2].glyph == "LB"
        and t[3].glyph == "RB", t and #t)
    for _ = 1, 3 do HS.taught("wheels") end
    t = HS.teach(0)
    check("three wheels opened: that half goes", t and #t == 2 and t[1].glyph == "LB", t and #t)
    for _ = 1, 3 do HS.taught("chords") end
    check("three quick actions too: no line", HS.teach(0) == nil)
    JoypadState.players[1] = nil
end

-- ===========================================================================
section("#42 the Messages count's color")
-- ===========================================================================
do
    ZeD.Belt = {}
    ZeD.Settings.lite = function() return false end
    local okB, errB = loadZ("ZeD_Belt.lua")
    check("ZeD_Belt.lua loads", okB, errB)
    local B = ZeD.Belt
    ZeD.Messages = { sources = {} }
    check("nothing new: no tone", B.lampTone() == nil)
    ZeD.Messages.sources["Bandits"] = { kind = "err", items = { { read = false } } }
    check("another mod's error: gray", B.lampTone() == "others", B.lampTone())
    ZeD.Messages.sources["note"] = { kind = "mods", items = { { read = false } } }
    check("and a note: the accent", B.lampTone() == "note", B.lampTone())
    ZeD.Messages.sources["ZeD-GUI [BETA]"] = { kind = "err", items = { { read = false } } }
    check("ZeD's own error: red", B.lampTone() == "ours", B.lampTone())
    ZeD.Messages.sources["ZeD-GUI [BETA]"].items[1].read = true
    check("read: back to the note", B.lampTone() == "note", B.lampTone())
end

-- ===========================================================================
section("#49 the moodles' quick list")
-- ===========================================================================
do
    local Q = ZeD.QuickWheel
    local A, B2 = { name = "Apple", run = function() end }, { name = "Corn", run = function() end }
    H.quick = function(p, gid) if gid == "eat" then return { A, B2 } end return {} end
    local list = Q.moodleList(P, "HUNGRY")
    check("Hungry: the Eat list, the best first", list and list[1] == A and #list == 2)
    local empty, why = Q.moodleList(P, "THIRST")
    check("Thirsty with nothing to drink: the wheel's reason", empty and #empty == 0 and why == "UI_ZeD_Wheel_NothingToDrink", why)
    check("Panic: not one of these", Q.moodleList(P, "PANIC") == nil)
    local w1 = { name = "Bandage", run = function() end }
    local w2 = { name = "Disinfect", run = function() end, pickable = true }
    local pill = { name = "Pills", run = function() end }
    D.C.medicine = function() return { w1, w2, pill } end
    D.C.medicinePick = function() return w2 end
    list = Q.moodleList(P, "BLEEDING")
    check("Bleeding: the pad's quick pick first", list and list[1] == w2 and #list == 3, list and list[1] and list[1].name)
    local opts = {}
    ISContextMenu = { get = function() return { addOption = function(self, n, t, fn) local o = { name = n, fn = fn }; opts[#opts + 1] = o; return o end } end }
    check("a click on Hungry opens the menu", Q.moodleMenu(0, "HUNGRY", 10, 10) == true and #opts == 2 and opts[1].name == "Apple", #opts)
    check("a click on Panic is not taken", Q.moodleMenu(0, "PANIC", 10, 10) == false)
    HALO = {}
    check("Thirsty, nothing to drink: taken, and the character says why", Q.moodleMenu(0, "THIRST", 10, 10) == true
        and HALO[1] == "UI_ZeD_Wheel_NothingToDrink", HALO[1])
end

print("kiss_k3_pad_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
