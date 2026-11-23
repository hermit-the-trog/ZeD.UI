-- ZeDUI/tools/qa/fitness_gear_sim.lua  (QA's health sweep, Nov 23 2026): after a session started from the Health
-- tab, the hands and worn bags go back on, as the game's own fitness window does (ISFitnessUI:equipItems notes
-- itemsToReequip; ISFitnessUI:update puts them back once getCurrentExe() is nil, lines 213-229).
-- The REAL HealthTab.lua runs on Lua 5.1 stubs. It checks:
--   NOTE     Start notes a weapon and an off-hand item, or a two-handed weapon once, and each worn bag
--   HOLD     while the session runs nothing goes back
--   BACK     once getCurrentExe() is nil: the weapon to the primary hand, the off-hand item, the bag worn again,
--            with the game's own calls; the note is gone, so nothing goes back twice
--   SKIP     an item dropped during the session is skipped; a new character in the seat drops the note
--   HOOK     the watcher rides OnPlayerUpdate, added once
-- What it can't show: the animation and the items in hand on screen (QA's hg_fit "gear").
-- Run from the repo root:  lua51 ZeDUI/tools/qa/fitness_gear_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]fitness_gear_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end

-- the game, as stubs
require = function() end
local HOOKS = {}
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = function(f) HOOKS[k] = (HOOKS[k] or 0) + 1; rawset(t, "_" .. k, f) end, Remove = function() end }
    rawset(t, k, e)
    return e
end })
getText = function(k) return k end
getTextOrNull = function() return nil end
ZeD = { T = { px = function(n) return n end, sp = {} }, Atoms = {}, logOnce = function() end }
ZeD.tr = function(k) return k end
instanceof = function(o, c) return o and o.cls == c end

local CALLS = {}
ISWorldObjectContextMenu = { equip = function(p, cur, item, primary, two)
    CALLS[#CALLS + 1] = { "equip", item.name, primary, two } end }
ISInventoryPaneContextMenu = {
    unequipItem = function(item) if item then CALLS[#CALLS + 1] = { "unequip", item.name } end end,
    wearItem = function(item) CALLS[#CALLS + 1] = { "wear", item.name } end,
}
ISUnequipAction = { new = function(_, p, item) return { off = item } end }
ISTimedActionQueue = { add = function(a) CALLS[#CALLS + 1] = { "queue", a.off and a.off.name or "?" } end,
    addGetUpAndThen = function(p, a) CALLS[#CALLS + 1] = { "start", a.ex } end }
ISFitnessAction = { new = function(_, p, ex) return { ex = ex } end }
FitnessExercises = { exercisesType = { squats = { type = "squats" }, curls = { type = "curls", item = "Base.DumbBell", prop = "primary" } } }

local function item(name, cls) return { name = name, cls = cls } end
local function player(num, prim, sec, worn)
    local inv = {}
    for _, i in ipairs({ prim, sec }) do if i then inv[i] = true end end
    for _, i in ipairs(worn) do inv[i] = true end
    local p = { num = num, prim = prim, sec = sec, worn = worn, dead = false, exe = nil, inv = inv }
    function p:getPrimaryHandItem() return self.prim end
    function p:getSecondaryHandItem() return self.sec end
    function p:isItemInBothHands(i) return i ~= nil and i == self.prim and i == self.sec end
    function p:getPlayerNum() return self.num end
    function p:isDead() return self.dead end
    function p:isEquipped(i) return false end
    function p:setSecondaryHandItem(i) self.sec = i end
    function p:getWornItems()
        local w = self.worn
        return { size = function() return #w end, get = function(_, k) return { getItem = function() return w[k + 1] end } end }
    end
    function p:getInventory()
        local inv = self.inv
        return { contains = function(_, i) return type(i) == "table" and inv[i] == true end }
    end
    function p:getFitness()
        local me = self
        return { init = function() end, setCurrentExercise = function(_, e) me.exe = e end,
                 getCurrentExe = function() return me.exe end }
    end
    return p
end

local src = readFile(Z .. "HealthTab.lua")
check("HealthTab.lua is read", src ~= nil)
local fn, err = loadstring(src or "", "=HealthTab.lua")
check("HealthTab.lua loads", fn ~= nil, err)
if fn then fn() end
local H = ZeD.HealthTab or {}
check("HOOK the watcher is on OnPlayerUpdate once", HOOKS.OnPlayerUpdate == 1, HOOKS.OnPlayerUpdate)
local tick = rawget(Events, "_OnPlayerUpdate")
check("HOOK the watcher is a function", type(tick) == "function")
if not (H._startExercise and tick) then
    print("fitness_gear_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1)
end

local function find(kind, name)
    for _, c in ipairs(CALLS) do if c[1] == kind and c[2] == name then return c end end
end

-- 1: a bat and a flashlight, a backpack worn
local bat, light, pack = item("Bat"), item("Flashlight"), item("Backpack", "InventoryContainer")
local p = player(0, bat, light, { pack })
H._startExercise(p, "squats", 10)
check("NOTE start ran the session", find("start", nil) ~= nil or #CALLS > 0)
check("NOTE the bat came off", find("unequip", "Bat") ~= nil)
check("NOTE the bag came off", find("queue", "Backpack") ~= nil)
local note = H._reequip[0]
check("NOTE a note for player 0 with 3 items", note and #note.list == 3, note and #note.list)
CALLS = {}
p.prim, p.sec = nil, nil
tick(p)
check("HOLD nothing goes back while exercising", #CALLS == 0, #CALLS)
p.exe = nil
tick(p)
local e1 = find("equip", "Bat")
check("BACK the bat to the primary hand", e1 and e1[3] == true and e1[4] == false)
local e2 = find("equip", "Flashlight")
check("BACK the flashlight to the off hand", e2 and e2[3] == false and e2[4] == false)
check("BACK the backpack worn again", find("wear", "Backpack") ~= nil)
check("BACK the note is gone", H._reequip[0] == nil)
CALLS = {}
tick(p)
check("BACK nothing goes back twice", #CALLS == 0)

-- 2: a two-handed axe, once
local axe = item("Axe")
local q = player(1, axe, axe, {})
H._startExercise(q, "squats", 10)
check("NOTE a two-handed axe is noted once", H._reequip[1] and #H._reequip[1].list == 1 and H._reequip[1].list[1].kind == "twohands")
CALLS = {}
q.exe = nil
tick(q)
local e3 = find("equip", "Axe")
check("BACK the axe in both hands", e3 and e3[3] == true and e3[4] == true)

-- 3: the bat dropped during the session is skipped
local p3 = player(2, bat, nil, {})
H._startExercise(p3, "squats", 10)
p3.inv[bat] = nil
CALLS = {}
p3.exe = nil
tick(p3)
check("SKIP a dropped item is not equipped", #CALLS == 0, #CALLS)

-- 4: a new character in the same seat drops the note
local p4 = player(3, bat, nil, {})
H._startExercise(p4, "squats", 10)
local p4b = player(3, nil, nil, {})
CALLS = {}
tick(p4b)
check("SKIP a new character drops the note", H._reequip[3] == nil and #CALLS == 0)

print("fitness_gear_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
