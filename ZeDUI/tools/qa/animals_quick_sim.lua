-- ZeDUI/tools/qa/animals_quick_sim.lua  (Nov 11 2026, Build): the Animals tab's quick actions and the roster's bulk
-- select, with no game running. It loads the real ZeD/AnimalsQuick.lua over a faked game (animals, a player with an
-- inventory, the game's animal menu handlers, its walk and its action queue) and checks:
--   VERB     which alert offers which verb (udder / ready to milk: Milk; ready to shear: Shear; the rest: Walk to)
--   GREY     when each verb is greyed and the reason it gives (no milk yet, full inventory, no bucket for this milk,
--            not enough wool, no shears, shears with a flat battery, out of reach)
--   ACT      a press hands the game exactly its own handler with the tool its menu would pick (the first bucket for the
--            breed's milk with all = true; the first shears with power; walkAdj to the animal's square)
--   CACHE    the tool checks are kept 500 ms, then asked again; an act forgets them
--   SELECT   All hungry / All milkable tick the right rows and replace the ticks; counts; a toggle; prune drops animals
--            that left the zone; the band's verbs (Shear then Milk, only the ones that apply, greyed with the reason)
--   RUN      a run goes one animal at a time, only after the last one's actions are over; skips animals with nothing
--            to give; ends Done; stops when an animal is left undone (a move cancels) and lets that animal move again;
--            stops with the reason when the bucket runs out; Stop clears the game's queue; the tick hook comes off
--   SOURCE   AnimalsTab and the World window's ring wire it up (alert A, roster X, the band's buttons)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/animals_quick_sim.lua
-- It prints FAIL lines and a last line "animals_quick_sim: N checks, M failed"; exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]animals_quick_sim%.lua$", "")
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

-- ---------------------------------------------------------------------------
-- THE GAME, FAKED
-- ---------------------------------------------------------------------------
local NOW = 100000
function getTimestampMs() return NOW end
function getText(k) return "T:" .. k end
require = function() end

local function jlist(t)
    t = t or {}
    return {
        size = function() return #t end,
        get = function(_, i) return t[i + 1] end,
        isEmpty = function() return #t == 0 end,
        add = function(_, v) t[#t + 1] = v end,
        _t = t,
    }
end
-- (the methods are called with a colon in the module: give them the self slot)
local function L(t)
    local l = jlist(t)
    return { size = function(self) return l.size() end, get = function(self, i) return l.get(nil, i) end,
             isEmpty = function(self) return l.isEmpty() end, add = function(self, v) l.add(nil, v) end, _t = l._t }
end
ArrayList = { new = function() return L({}) end }
ItemTag = { SHEAR = "SHEAR" }
function instanceof(o, cls) return type(o) == "table" and o._class == cls end

ZeD = {}
ZeD.tr = function(k, ...)
    local a = { ... }
    for i = 1, #a do a[i] = tostring(a[i]) end
    return (#a > 0) and (k .. "(" .. table.concat(a, ",") .. ")") or k
end
ZeD.AnimalsData = { getHunger = function(a) return a._hunger or 0 end }

-- the tick hook
local hooks = {}
Events = { OnTick = {
    Add = function(f) hooks[f] = true end,
    Remove = function(f) hooks[f] = nil end,
} }
local function hookCount() local n = 0 for _ in pairs(hooks) do n = n + 1 end return n end

-- the game's action queue and the calls into the game
local CALLS
local function rec(s) CALLS[#CALLS + 1] = s end
ISTimedActionQueue = {
    queues = {},
    isPlayerDoingAction = function() return false end,
    clear = function(p) rec("clear"); local q = ISTimedActionQueue.queues[p]; if q then q.queue = {} end end,
}
local function Q(p)
    local q = ISTimedActionQueue.queues[p]
    if not q then q = { queue = {} }; ISTimedActionQueue.queues[p] = q end
    return q
end
AnimalContextMenu = {
    onMilkAnimal = function(animal, chr, bucket, all)
        rec("milk:" .. animal._name .. ":" .. tostring(bucket and bucket._name) .. ":" .. tostring(all))
        animal._blocked = true
        local q = Q(chr).queue
        q[#q + 1] = "walkF"; q[#q + 1] = "ISMilkAnimal"
    end,
    onShearAnimal = function(animal, chr, shear)
        rec("shear:" .. animal._name .. ":" .. tostring(shear and shear._name))
        animal._blocked = true
        local q = Q(chr).queue
        q[#q + 1] = "walkF"; q[#q + 1] = "ISShearAnimal"
    end,
}
local WALK_OK = true
luautils = { walkAdj = function(p, sq) rec("walk:" .. tostring(sq and sq.id)); if WALK_OK then local q = Q(p).queue; q[#q + 1] = "walk" end return WALK_OK end }

-- animals
local function animal(name, o)
    o = o or {}
    local a = { _name = name, _milk = o.milk or 0, _wool = o.wool or 0, _milkable = o.milkable, _shearable = o.shearable,
                _hunger = o.hunger or 0, _mt = o.mt or "CowMilk", _sq = { id = name .. "@sq" } }
    if o.sq == false then a._sq = nil end
    local data = {
        getMilkQuantity = function() return a._milk end,
        getWoolQuantity = function() return a._wool end,
        getBreed = function() return { getMilkType = function() return a._mt end } end,
    }
    a.getData = function() return data end
    a.canBeMilked = function() return a._milkable == true end
    a.canBeSheared = function() return a._shearable == true end
    a.getSquare = function() return a._sq end
    a.getBehavior = function() return { setBlockMovement = function(_, v) a._blocked = v end } end
    return a
end

-- the player and the inventory
local invCalls = 0
local function player()
    local p = { _full = false, _buckets = {}, _shears = {} }
    local inv = {
        getAvailableFluidContainer = function(_, mt)
            invCalls = invCalls + 1
            local out = {}
            for _, b in ipairs(p._buckets) do if b._mt == nil or b._mt == mt then out[#out + 1] = b end end
            return L(out)
        end,
        getAllTagRecurse = function(_, tag, list)
            invCalls = invCalls + 1
            for _, s in ipairs(p._shears) do list:add(s) end
            return list
        end,
    }
    p.getInventory = function() return inv end
    p.hasFullInventory = function() return p._full end
    p.isDead = function() return false end
    return p
end
local function bucket(name, mt) return { _name = name, _mt = mt } end
local function shears(name, flat)
    if flat ~= nil then
        return { _name = name, _class = "DrainableComboItem", getCurrentUsesFloat = function() return flat and 0 or 0.5 end }
    end
    return { _name = name }
end

-- ---------------------------------------------------------------------------
-- THE MODULE
-- ---------------------------------------------------------------------------
dofile(Z .. "AnimalsQuick.lua")
local AQ = ZeD.AnimalsQuick
check("module loads", AQ ~= nil and AQ.act ~= nil)

-- VERB ------------------------------------------------------------------------
local VERBS = { udder_urgent = "milk", ready_milk = "milk", ready_shear = "shear", thirsty = "goto", hungry = "goto",
                stressed = "goto", lost_mother = "goto", somethingNew = "goto" }
for at, v in pairs(VERBS) do check("VERB " .. at .. " offers " .. v, AQ.alertVerb(at) == v, AQ.alertVerb(at)) end

-- GREY ------------------------------------------------------------------------
local p = player()
local bessie = animal("Bessie", { milk = 8.4, milkable = true })
local dry = animal("Dry", { milk = 0.05, milkable = true })
local bull = animal("Bull", { milk = 5, milkable = false })
local daisy = animal("Daisy", { wool = 6, shearable = true })
local shorn = animal("Shorn", { wool = 1, shearable = true })
local gone = animal("Gone", { sq = false })

local ok, why = AQ.canMilk(p, dry)
check("GREY milk: 0.05 L is nothing to milk (the game's > 0.1)", not ok and why == "UI_ZeD_Animals_NoMilkYet", why)
ok, why = AQ.canMilk(p, bull)
check("GREY milk: an animal the game says cannot be milked", not ok and why == "UI_ZeD_Animals_NoMilkYet", why)
ok, why = AQ.canMilk(p, bessie)
check("GREY milk: no bucket", not ok and why == "UI_ZeD_Animals_NeedBucket", why)
p._buckets = { bucket("GoatPail", "GoatMilk") }
ok, why = AQ.canMilk(p, bessie)
check("GREY milk: a bucket that takes only another milk", not ok and why == "UI_ZeD_Animals_NeedBucket", why)
p._buckets = { bucket("Bucket1"), bucket("Bucket2") }
p._full = true
ok, why = AQ.canMilk(p, bessie)
check("GREY milk: a full inventory, in the game's words", not ok and why == "T:ContextMenu_FullInventory", why)
p._full = false
local tool
ok, why, tool = AQ.canMilk(p, bessie)
check("GREY milk: a bucket, room, milk: can", ok and why == nil and tool and tool._name == "Bucket1", tool and tool._name)

ok, why = AQ.canShear(p, shorn)
check("GREY shear: one unit of wool is not enough (the game's > 1)", not ok and why == "UI_ZeD_Animals_NoWoolYet", why)
ok, why = AQ.canShear(p, daisy)
check("GREY shear: no shears", not ok and why == "UI_ZeD_Animals_NeedShears", why)
p._shears = { shears("Electric", true) }
ok, why = AQ.canShear(p, daisy)
check("GREY shear: electric shears, flat battery, in the game's words", not ok and why == "T:Tooltip_Animal_ShearNoBattery", why)
p._shears = { shears("Electric", true), shears("Manual") }
ok, why, tool = AQ.canShear(p, daisy)
check("GREY shear: the first shears with power are picked", ok and tool and tool._name == "Manual", tool and tool._name)

ok, why = AQ.canGoTo(p, gone)
check("GREY walk: an animal with no square", not ok and why == "UI_ZeD_Animals_OutOfReach", why)
ok = AQ.canGoTo(p, daisy)
check("GREY walk: an animal on a square", ok)
ok, why = AQ.can("goto", nil, daisy)
check("GREY walk: no player", not ok)

-- ACT -------------------------------------------------------------------------
CALLS = {}
ok = AQ.act("milk", p, bessie)
check("ACT milk hands the game onMilkAnimal with the first bucket and all = true", ok and CALLS[1] == "milk:Bessie:Bucket1:true", CALLS[1])
CALLS = {}
ok = AQ.act("shear", p, daisy)
check("ACT shear hands the game onShearAnimal with the shears it picked", ok and CALLS[1] == "shear:Daisy:Manual", CALLS[1])
CALLS = {}
ok = AQ.act("goto", p, daisy)
check("ACT walk is the game's walkAdj to the animal's square", ok and CALLS[1] == "walk:Daisy@sq", CALLS[1])
WALK_OK = false
CALLS = {}
ok, why = AQ.act("goto", p, daisy)
check("ACT walk with no free square beside it says out of reach", not ok and why == "UI_ZeD_Animals_OutOfReach", why)
WALK_OK = true
CALLS = {}
ok, why = AQ.act("milk", p, dry)
check("ACT a greyed verb calls nothing in the game", not ok and #CALLS == 0, #CALLS)
ISTimedActionQueue.queues = {}

-- CACHE -----------------------------------------------------------------------
AQ.forgetChecks()
invCalls = 0
AQ.check("milk", p, bessie)
AQ.check("milk", p, bessie)
check("CACHE a second ask within 500 ms does not look through the inventory", invCalls == 1, invCalls)
NOW = NOW + 499
AQ.check("milk", p, bessie)
check("CACHE still kept at 499 ms", invCalls == 1, invCalls)
NOW = NOW + 1
AQ.check("milk", p, bessie)
check("CACHE asked again at 500 ms", invCalls == 2, invCalls)
p._buckets = {}
local ok2 = AQ.check("milk", p, bessie)
check("CACHE a kept answer can be stale for up to 500 ms (the press checks again)", ok2 == true)
ok2 = AQ.act("milk", p, bessie)
check("CACHE the press itself checks again: no bucket, no act", ok2 == false)
AQ.forgetChecks()
local ok3, why3 = AQ.check("milk", p, bessie)
check("CACHE forgotten: the fresh answer", ok3 == false and why3 == "UI_ZeD_Animals_NeedBucket", why3)
p._buckets = { bucket("Bucket1") }
AQ.forgetChecks()

-- SELECT ----------------------------------------------------------------------
local cowA = animal("CowA", { milk = 3, milkable = true, hunger = 20 })
local cowB = animal("CowB", { milk = 0, milkable = true, hunger = 55 })
local goat = animal("Goat", { milk = 2, milkable = true, hunger = 90, mt = "GoatMilk" })
local sheep = animal("Sheep", { wool = 4, shearable = true, hunger = 49.9 })
local zone = { cowA, cowB, goat, sheep }
check("SELECT 50 is hungry, 49.9 is not (the detail view's Hungry)", AQ.isHungry(cowB) and not AQ.isHungry(sheep))
check("SELECT counts: 2 hungry, 2 milkable", AQ.countWhere(zone, "hungry") == 2 and AQ.countWhere(zone, "milkable") == 2,
    AQ.countWhere(zone, "hungry") .. "/" .. AQ.countWhere(zone, "milkable"))
local sel = AQ.newSelection()
local n = AQ.selectWhere(sel, zone, "hungry")
check("SELECT All hungry ticks CowB and Goat", n == 2 and AQ.isSelected(sel, cowB) and AQ.isSelected(sel, goat)
    and not AQ.isSelected(sel, cowA) and not AQ.isSelected(sel, sheep))
n = AQ.selectWhere(sel, zone, "milkable")
check("SELECT All milkable replaces the ticks: CowA and Goat", n == 2 and AQ.isSelected(sel, cowA) and AQ.isSelected(sel, goat)
    and not AQ.isSelected(sel, cowB))
AQ.toggle(sel, sheep)
check("SELECT a toggle ticks", AQ.isSelected(sel, sheep))
AQ.toggle(sel, sheep)
check("SELECT a second toggle clears", not AQ.isSelected(sel, sheep))
AQ.toggle(sel, sheep)
local list = AQ.prune(sel, { goat, sheep, cowB })
check("SELECT prune keeps the zone's order and drops the animal that left (CowA)",
    #list == 2 and list[1] == goat and list[2] == sheep and not AQ.isSelected(sel, cowA))
check("SELECT an unknown pick ticks nothing", AQ.selectWhere(sel, zone, "thirsty") == 0 and #AQ.prune(sel, zone) == 0)
AQ.toggle(sel, cowA); AQ.clear(sel)
check("SELECT Clear", #AQ.prune(sel, zone) == 0)

-- the band's verbs
p._shears = {}
AQ.forgetChecks()
local v = AQ.selectionVerbs(p, { cowA, goat, sheep, cowB })
check("SELECT band: Shear then Milk", #v == 2 and v[1].id == "shear" and v[2].id == "milk", #v)
check("SELECT band: Milk counts the two with milk (CowB has none)", v[2] and v[2].n == 2, v[2] and v[2].n)
check("SELECT band: Milk can (a bucket for cow milk)", v[2] and v[2].ok == true and v[2].why == nil)
check("SELECT band: Shear greyed, no shears", v[1] and v[1].ok == false and v[1].why == "UI_ZeD_Animals_NeedShears", v[1] and v[1].why)
v = AQ.selectionVerbs(p, { cowB })
check("SELECT band: nothing applies, no verbs", #v == 0, #v)
p._buckets = { bucket("CowPail", "CowMilk") }
AQ.forgetChecks()
v = AQ.selectionVerbs(p, { goat })
check("SELECT band: a goat with only a cow-milk bucket greys Milk", #v == 1 and v[1].ok == false and v[1].why == "UI_ZeD_Animals_NeedBucket",
    v[1] and v[1].why)
AQ.forgetChecks()
v = AQ.selectionVerbs(p, { goat, cowA })
check("SELECT band: one animal the bucket takes is enough to offer Milk", #v == 1 and v[1].ok == true and v[1].n == 2)

-- RUN -------------------------------------------------------------------------
local function busy(pl) local q = ISTimedActionQueue.queues[pl]; return q and #q.queue > 0 end
local function finishAction(pl) ISTimedActionQueue.queues[pl].queue = {} end
ISTimedActionQueue.queues = {}
AQ.forgetChecks()
local c1 = animal("C1", { milk = 4, milkable = true })
local c2 = animal("C2", { milk = 0, milkable = true })
local c3 = animal("C3", { milk = 6, milkable = true })
p._buckets = { bucket("Bucket1") }
CALLS = {}
ok = AQ.start(p, "milk", { c1, c2, c3 })
check("RUN starts: C1 handed to the game at once", ok and CALLS[1] == "milk:C1:Bucket1:true" and #CALLS == 1, table.concat(CALLS, " "))
check("RUN the tick hook is on", hookCount() == 1)
check("RUN skipped C2 from the start (no milk): 2 to do", AQ.run and #AQ.run.list == 2)
check("RUN status says 1 of 2", AQ.runStatus() == "UI_ZeD_Animals_RunMilking(1,2)", AQ.runStatus())
for _ = 1, 50 do AQ.tick() end
check("RUN waits while C1's actions are in the queue", #CALLS == 1 and busy(p))
AQ.tick(); c1._milk = 0.05; finishAction(p)
AQ.tick()
check("RUN C1 done, C3 handed over (one at a time)", CALLS[2] == "milk:C3:Bucket1:true" and #CALLS == 2, table.concat(CALLS, " "))
check("RUN status says 2 of 2", AQ.runStatus() == "UI_ZeD_Animals_RunMilking(2,2)", AQ.runStatus())
AQ.tick(); c3._milk = 0; finishAction(p)
AQ.tick()
check("RUN ends Done 2 of 2", AQ.run == nil and AQ.last and AQ.last.why == "UI_ZeD_Animals_RunDone(2,2)", AQ.last and AQ.last.why)
check("RUN the tick hook is off", hookCount() == 0)

-- a move cancels: the animal under way still has milk
ISTimedActionQueue.queues = {}
local d1 = animal("D1", { milk = 4, milkable = true })
local d2 = animal("D2", { milk = 4, milkable = true })
local d3 = animal("D3", { milk = 4, milkable = true })
CALLS = {}
AQ.start(p, "milk", { d1, d2, d3 })
AQ.tick(); d1._milk = 0; finishAction(p); AQ.tick()
check("RUN D2 handed over", CALLS[2] == "milk:D2:Bucket1:true", CALLS[2])
AQ.tick(); finishAction(p)   -- the player walked off: the queue is empty, D2 still has its milk
AQ.tick()
check("RUN a cancelled step stops the run: Stopped after 1 of 3", AQ.run == nil and AQ.last.why == "UI_ZeD_Animals_RunStopped(1,3)", AQ.last.why)
check("RUN D3 was never handed over", #CALLS == 2)
check("RUN D2 lets go (it was held still for the milking)", d2._blocked == false)

-- the bucket runs out
ISTimedActionQueue.queues = {}
local e1 = animal("E1", { milk = 9, milkable = true })
local e2 = animal("E2", { milk = 9, milkable = true })
CALLS = {}
AQ.start(p, "milk", { e1, e2 })
AQ.tick(); p._buckets = {}; finishAction(p); AQ.tick()   -- the bucket filled: E1 keeps some milk, no bucket left
check("RUN the bucket full: E1 counts, E2 not handed over, the reason shown",
    AQ.run == nil and #CALLS == 1 and AQ.last.why == "UI_ZeD_Animals_NeedBucket", AQ.last.why .. " " .. #CALLS)
p._buckets = { bucket("Bucket1") }

-- the game never takes the action up (it shows no action in the queue)
ISTimedActionQueue.queues = {}
local f1 = animal("F1", { milk = 9, milkable = true })
AnimalContextMenu.onMilkAnimal, AnimalContextMenu._real = function(a) rec("milk-refused:" .. a._name) end, AnimalContextMenu.onMilkAnimal
CALLS = {}
AQ.start(p, "milk", { f1 })
for _ = 1, AQ.START_GRACE - 2 do AQ.tick() end
check("RUN waits START_GRACE ticks for the action to show up", AQ.run ~= nil)
for _ = 1, 3 do AQ.tick() end
check("RUN an action that never showed up stops the run", AQ.run == nil and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,1)", AQ.last and AQ.last.why)
AnimalContextMenu.onMilkAnimal = AnimalContextMenu._real

-- Stop
ISTimedActionQueue.queues = {}
local s1 = animal("S1", { wool = 5, shearable = true })
local s2 = animal("S2", { wool = 5, shearable = true })
p._shears = { shears("Manual") }
CALLS = {}
ok = AQ.start(p, "shear", { s1, s2 })
check("RUN shear starts with the shears", ok and CALLS[1] == "shear:S1:Manual", CALLS[1])
AQ.stop()
check("RUN Stop clears the game's queue and lets S1 go", CALLS[2] == "clear" and s1._blocked == false and AQ.run == nil, table.concat(CALLS, " "))
check("RUN Stop: Stopped after 0 of 2, the hook off", AQ.last.why == "UI_ZeD_Animals_RunStopped(0,2)" and hookCount() == 0, AQ.last.why)

-- nothing to do / no tool
ok, why = AQ.start(p, "milk", { cowB })
check("RUN nothing to give: no run", not ok and AQ.run == nil)
p._shears = {}
ok, why = AQ.start(p, "shear", { s1 })
check("RUN no shears: no run, the reason", not ok and why == "UI_ZeD_Animals_NeedShears", why)
ok = AQ.start(p, "goto", { s1 })
check("RUN only milk and shear run", not ok)

-- SOURCE ----------------------------------------------------------------------
local TAB = readFile(Z .. "AnimalsTab.lua")
local WW = readFile(Z .. "ZeD_WorldWindow.lua")
check("SOURCE the tab requires AnimalsQuick", TAB:find('require "ZeD/AnimalsQuick"', 1, true) ~= nil)
check("SOURCE the alert row's verb button", TAB:find("QK().alertVerb(alert.alertType)", 1, true) ~= nil)
check("SOURCE the verbs are the game's words", TAB:find('milk = "ContextMenu_Milk", shear = "ContextMenu_Shear", ["goto"] = "ContextMenu_Walk_to"', 1, true) ~= nil)
check("SOURCE alert A calls AT.alertAct", WW:find("AT.alertAct(w, el.animal, el.verb)", 1, true) ~= nil)
check("SOURCE roster X toggles", WW:find("AT.toggleSelected(w, el.animal)", 1, true) ~= nil)
check("SOURCE band buttons are stops", WW:find('id = "animals:bulk:" .. tostring(b.id)', 1, true) ~= nil)
check("SOURCE a focus target may be an id", WW:find('(target == "breadcrumb" and e.isBreadcrumb) or e.id == target', 1, true) ~= nil)
check("SOURCE right-click on a row toggles", TAB:find("return AT.toggleSelected(win, rz.animal)", 1, true) ~= nil)

print(string.format("animals_quick_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
