-- ZeDUI/tools/qa/info_calls_sim.lua  (Nov 27 2026, Build): the director's info tab calls, with no game running.
-- The real code of each piece is cut out of its file and run on Lua 5.1 stubs:
--   S3   paused, the Skills, Health, Info and Protection keys reach the game's page toggle (ZeD's window, through
--        the toggleView hook); in play the game's own handler answers and this one stays out; safe mode stays out
--   B3   the reach rule for a radio press (ZeD_RadioOps.lua): a set next to him at once; across the room a walk to
--        it, then the press at the walk's end; a car's radio only from a front seat of that car; from a seat, a
--        set in the room does nothing; a radio in the hands at once
--   J1   the Journal page picked is kept per player for the session; a page gone falls back to the log
--   J32  the pad's B on Read: a read of that piece in the queue stops; none, B goes back
--   MP33 the first ink with no colour chosen: a pen before a pencil (the game's order); a chosen ink stays
-- Run from the repo root: lua51 ZeDUI/tools/qa/info_calls_sim.lua
-- It prints FAIL lines and a last line "info_calls_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]info_calls_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

local function slurp(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
-- the text from the first line holding `from` up to (not including) the first line holding `to` after it
local function cut(src, from, to)
    local a = string.find(src, from, 1, true)
    assert(a, "no " .. from)
    local b = to and string.find(src, to, a + #from, true) or (#src + 1)
    assert(b, "no " .. tostring(to))
    return string.sub(src, a, b - 1)
end
local function run(chunk, name, env)
    local f, err = loadstring(chunk, name)
    if not f then error(name .. ": " .. tostring(err)) end
    if env then setfenv(f, setmetatable(env, { __index = _G })) end
    return f()
end

-- ===================================================================== S3 the page keys while paused
do
    local src = slurp(Z .. "Overrides/CharacterInfo.lua")
    local chunk = cut(src, "local PAUSED_KEYS", "-- ZeD coming back from safe mode")
    local speed, safe, toggled = 0, false, {}
    local listeners = {}
    local keys = { TOGGLE_SKILL_PANEL = 31, TOGGLE_HEALTH_PANEL = 35, TOGGLE_INFO_PANEL = 23, TOGGLE_CLOTHING_PROTECTION_PANEL = 24 }
    local env = {
        ZeD = { Safe = { on = function() return safe end } },
        Route = {},
        getGameSpeed = function() return speed end,
        getSpecificPlayer = function() return { isDead = function() return false end } end,
        getPlayerData = function() return {} end,
        KeybindId = { TOGGLE_SKILL_PANEL = "S", TOGGLE_HEALTH_PANEL = "H", TOGGLE_INFO_PANEL = "I", TOGGLE_CLOTHING_PROTECTION_PANEL = "P" },
        getCore = function() return { isKey = function(_, id, key)
            local map = { S = keys.TOGGLE_SKILL_PANEL, H = keys.TOGGLE_HEALTH_PANEL, I = keys.TOGGLE_INFO_PANEL, P = keys.TOGGLE_CLOTHING_PROTECTION_PANEL }
            return map[id] == key end } end,
        getText = function(k) return k end,
        getPlayerInfoPanel = function() return { toggleView = function(_, v) toggled[#toggled + 1] = v end } end,
        Events = { OnKeyPressed = { Add = function(fn) listeners[#listeners + 1] = fn end } },
    }
    run(chunk, "CharacterInfo paused keys", env)
    check("S3 one key listener added", #listeners == 1, #listeners)
    local Route = env.Route
    run(chunk, "CharacterInfo paused keys (reload)", env)
    check("S3 a reload adds no second listener", #listeners == 1, #listeners)
    listeners[1](keys.TOGGLE_SKILL_PANEL)
    check("S3 paused, the Skills key toggles the Skills page (ZeD's window, through the hook)", toggled[1] == "IGUI_XP_Skills", tostring(toggled[1]))
    listeners[1](keys.TOGGLE_HEALTH_PANEL); listeners[1](keys.TOGGLE_INFO_PANEL); listeners[1](keys.TOGGLE_CLOTHING_PROTECTION_PANEL)
    check("S3 paused, Health, Info and Protection too", toggled[2] == "IGUI_XP_Health" and toggled[3] == "IGUI_XP_Info" and toggled[4] == "IGUI_XP_Protection", table.concat(toggled, ","))
    toggled = {}
    listeners[1](99)
    check("S3 another key does nothing", #toggled == 0)
    speed = 1
    listeners[1](keys.TOGGLE_SKILL_PANEL)
    check("S3 in play this listener stays out (the game's handler answers)", #toggled == 0, #toggled)
    speed, safe = 0, true
    listeners[1](keys.TOGGLE_SKILL_PANEL)
    check("S3 safe mode: stays out", #toggled == 0, #toggled)
    check("S3 the listener calls Route.pausedKey", Route.pausedKey ~= nil)
end

-- ===================================================================== B3 the reach rule
do
    local src = slurp(Z .. "ZeD_RadioOps.lua")
    local chunk = cut(src, "function O.reach(chr, part)", "-- ---------------------------------------------------------------------------\n-- THE DISPLAYS")
    local Q = {}
    local walks = {}
    local function sq(x, y, z) return { getX = function() return x end, getY = function() return y end, getZ = function() return z end,
        canReachTo = function() return true end } end
    local veh = { getSeat = function(_, c) return c.seat end }
    local otherVeh = { getSeat = function() return 0 end }
    local chr = { x = 10.5, y = 10.5, z = 0, seat = 0, inCar = nil }
    function chr.getX() return chr.x end
    function chr.getY() return chr.y end
    function chr.getZ() return chr.z end
    function chr.getVehicle() return chr.inCar end
    function chr.getCurrentSquare() return sq(math.floor(chr.x), math.floor(chr.y), chr.z) end
    local presses = {}
    local O = {}
    for _, n in ipairs({ "power", "volStep", "mute", "tuneStep", "seek", "scanToggle", "recall", "store", "chStep", "memAdd",
        "rename", "mic", "playStop", "insert", "eject", "setChannel" }) do
        O[n] = function(c, part, a) presses[#presses + 1] = { n = n, part = part, a = a }; return true end
    end
    local Base = {}
    Base.__index = Base
    function Base:derive(t) local c = setmetatable({}, { __index = self }); c.__index = c; c.Type = t; return c end
    function Base.new(cls, character) return setmetatable({ character = character }, cls) end
    function Base.perform() end
    function Base.stop() end
    local env = {
        O = O,
        _get = function(o, m, d) local f = o and o[m]; if f then local v = f(o); if v ~= nil then return v end end; return d end,
        _safe = function(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end,
        instanceof = function(o, cls) return type(o) == "table" and o._cls == cls end,
        luautils = { getCorrectSquareForWall = function(_, s) return s end,
            walkAdj = function(c, s, keep) walks[#walks + 1] = { s = s, keep = keep }; Q[#Q + 1] = { Type = "ISWalkToTimedAction" }; return true end },
        ISBaseTimedAction = Base,
        ISTimedActionQueue = { add = function(a) Q[#Q + 1] = a end },
        ZeD_RadioPressAction = nil,
    }
    run(chunk, "RadioOps reach", env)
    local tv = { _cls = "IsoObject", getSquare = function() return sq(16, 10, 0) end }
    local near = { _cls = "IsoObject", getSquare = function() return sq(11, 10, 0) end }
    local carPart = { _cls = "VehiclePart", getVehicle = function() return veh end }
    local walkie = { _cls = "Radio" }
    check("B3 a set next to him: at once", O.reach(chr, near) == "now", O.reach(chr, near))
    check("B3 a TV 6 tiles off: a walk", O.reach(chr, tv) == "walk", O.reach(chr, tv))
    check("B3 a walkie in the hands: at once", O.reach(chr, walkie) == "now")
    check("B3 the car's radio from outside: no", O.reach(chr, carPart) == "no", O.reach(chr, carPart))
    O.power(chr, near)
    check("B3 power on the set next to him presses at once, no walk", #presses == 1 and #walks == 0 and #Q == 0, #presses .. "/" .. #walks)
    presses, Q = {}, {}
    local r = O.power(chr, tv)
    check("B3 power on the TV across the room: a walk queued (kept after what he does), then the press, nothing yet",
        r == true and #presses == 0 and #walks == 1 and walks[1].keep == true and #Q == 2 and Q[2].Type == "ZeD_RadioPressAction", #presses .. " " .. #Q)
    -- the walk ends next to the set
    chr.x, chr.y = 15.5, 10.5
    Q[2]:perform()
    check("B3 at the walk's end the press runs", #presses == 1 and presses[1].n == "power" and presses[1].part == tv, #presses)
    -- a second press with an argument, and the walk ending short (a door): dropped
    presses, Q, walks = {}, {}, {}
    chr.x, chr.y = 10.5, 10.5
    O.volStep(chr, tv, 1)
    Q[2]:perform()
    check("B3 a press whose walk ended out of reach is dropped, not walked again", #presses == 0 and #walks == 1, #presses .. "/" .. #walks)
    chr.x = 15.5
    Q[2]:perform()
    check("B3 ... and its argument rides along", #presses == 1 and presses[1].a == 1, presses[1] and tostring(presses[1].a))
    presses, Q, walks = {}, {}, {}
    chr.x = 10.5
    check("B3 the car's radio from outside: the press does nothing", O.power(chr, carPart) == false and #presses == 0 and #walks == 0)
    chr.inCar, chr.seat = veh, 0
    check("B3 the car's radio from the driver's seat: at once", O.reach(chr, carPart) == "now")
    chr.seat = 1
    check("B3 ... the front passenger's: at once", O.reach(chr, carPart) == "now")
    chr.seat = 2
    check("B3 ... a back seat: no (the game: front seats only)", O.reach(chr, carPart) == "no")
    chr.inCar, chr.seat = otherVeh, 0
    check("B3 ... another car's seat: no", O.reach(chr, carPart) == "no")
    check("B3 in a car, a set across the room: no walk from the seat", O.reach(chr, tv) == "no")
    chr.inCar = nil
    chr.z = 1
    check("B3 a set on another floor: a walk (the game's walk finds the way or says no)", O.reach(chr, near) == "walk")
end

-- ===================================================================== J1 the kept page
do
    local src = slurp(Z .. "JournalTab.lua")
    local env = { ZeD = { JournalTab = {} }, SUB_TABS = { {}, {}, {}, {} } }
    run(cut(src, "ZeD.JournalTab._kept = ZeD.JournalTab._kept or {}", "--- Open a page of the Journal"), "JournalTab kept", env)
    local setp = cut(src, "function ZeD.JournalTab.setPage", "--- Open the Journal page with this id")
    run(setp, "JournalTab setPage", env)
    local JT = env.ZeD.JournalTab
    check("J1 a new window starts on the log", JT.keptPage(0) == 1, JT.keptPage(0))
    local w = { playerNum = 0, _journalSubTab = 1 }
    JT.setPage(w, 2)
    check("J1 the page picked (Notebooks) is kept: the next window starts on it", JT.keptPage(0) == 2, JT.keptPage(0))
    check("J1 ... per player", JT.keptPage(1) == 1, JT.keptPage(1))
    JT._kept[0] = 9
    check("J1 a page gone since falls back to the log", JT.keptPage(0) == 1, JT.keptPage(0))
    local cw = slurp(Z .. "ZeD_CharacterWindow.lua")
    check("J1 the Character window starts on the kept page", string.find(cw, "win._journalSubTab      = (ZeD.JournalTab and ZeD.JournalTab.keptPage and ZeD.JournalTab.keptPage(playerNum)) or 1", 1, true) ~= nil)
end

-- ===================================================================== J32 B on Read
do
    local src = slurp(Z .. "ZeD_JournalReaders.lua")
    local stopped = 0
    local q = {}
    local env = {
        ISTimedActionQueue = { getTimedActionQueue = function() return { queue = q } end },
        stopDoingActionThatCanBeCancelled = function() stopped = stopped + 1; q = {} end,
    }
    run(cut(src, "local function readRunning", "-- a section head, not folding"), "JournalReaders readCancel", env)
    -- (the chunk's locals are out of reach: the Read button's cancel is checked through the text, and the function
    -- through a copy that returns readCancel)
    local f = assert(loadstring(cut(src, "local function readRunning", "-- a section head, not folding") .. "\nreturn readCancel"))
    setfenv(f, setmetatable(env, { __index = _G }))
    local readCancel = f()
    local item = {}
    local backs = 0
    local back = function() backs = backs + 1 end
    local win = { _playerObj = {} }
    q[1] = { Type = "ISReadABook", item = item }
    readCancel(win, { item = item }, back)
    check("J32 B while the read of this piece runs stops it", stopped == 1 and backs == 0, stopped .. "/" .. backs)
    readCancel(win, { item = item }, back)
    check("J32 B with nothing running goes back", stopped == 1 and backs == 1, stopped .. "/" .. backs)
    q = { { Type = "ISReadABook", item = {} } }
    env.ISTimedActionQueue.getTimedActionQueue = function() return { queue = q } end
    readCancel(win, { item = item }, back)
    check("J32 B with another thing's action running goes back (only this read stops)", stopped == 1 and backs == 2, stopped .. "/" .. backs)
    check("J32 the Read button's B is readCancel", string.find(src, "cancel = function() return readCancel(win, e, back) end", 1, true) ~= nil)
end

-- ===================================================================== MP33 the first ink
do
    local src = slurp(Z .. "MapsTab.lua")
    local env = { MAP_COLORS = { {}, {}, {}, {}, {} } }
    local pens = {}
    env._mapInk = function() return { pen = pens } end
    local f = assert(loadstring(cut(src, "local GAME_INK_ORDER", "-- the next colour round from cur") .. "\nreturn _inkColor, _inkShown"))
    setfenv(f, setmetatable(env, { __index = _G }))
    local inkColor, inkShown = f()
    -- MAP_COLORS: 1 Pencil, 2 Pen, 3 Blue, 4 Red, 5 Green
    pens = { true, true, false, false, false }
    local win = {}
    check("MP33 the toolbar shows the pen as the ink in use before a mark", inkShown(win) == 2, inkShown(win))
    check("MP33 a Pen and a Pencil, no ink chosen: the pen", inkColor(win, { pen = pens }) == 2, tostring(win._mapActiveColor))
    win = {}
    pens = { true, false, true, true, false }
    check("MP33 a pencil, red and blue: the pencil (the game: pen, pencil, red, blue, green)", inkColor(win, { pen = pens }) == 1)
    win = {}
    pens = { false, false, true, true, false }
    check("MP33 red and blue: red", inkColor(win, { pen = pens }) == 4)
    win = { _mapActiveColor = 3 }
    check("MP33 a chosen ink at hand stays", inkColor(win, { pen = pens }) == 3)
    win = {}
    pens = { false, false, false, false, false }
    check("MP33 nothing at hand: none", inkColor(win, { pen = pens }) == nil)
end

print("info_calls_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
