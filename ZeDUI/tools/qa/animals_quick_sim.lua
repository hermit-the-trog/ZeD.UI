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
--   FEED     the food picker: the game's hand-feeding test per species (its eat list, milk of the animal's own kind,
--            animal feed by its feed kind, fresh fruit and vegetables; rotten, spice, other fluids left out), only the
--            hungry count, one line per name with how many it suits and how many are carried, sorted; Feed in the
--            band first, greyed with the reason when nothing carried suits; kept 500 ms; the act is the game's
--            onFeedAnimalFood with the first item of that food the animal eats; the run feeds one at a time, skips the
--            animals not hungry, ends Done, stops when the player walks off (hunger did not go down) and lets the
--            animal go, ends with the reason when the food runs out
--   ZONES    the poller counts a zone's animals as the game's zone window does (getAnimalsConnected, getDZone the
--            fallback, none twice); zone rows, totals, the bulk selection's list and an animal's zone name agree
--   MILKRULE the game's milk rule: any container that is empty or holds this milk (a water bottle too), main
--            inventory only; the greyed reason says so; an animal with no square is out of reach
--   FAR      an animal not drawn near (no body points): the walk up first, the game's handler after it; still not
--            drawn, out of reach and nothing handed over
--   AWAY     the run gives up cleanly (queue cleared, animal let go) when the player is moved well off, the queue
--            is stuck, or one animal takes too long; walking up from afar is no walk-off
--   FULL     a bucket full of this milk is passed over; a bucket that fills mid-run counts that animal as done
--   CAUSE    what ended a run is kept (AQ.last.cause); a bucket kicked away is a stop, a full one counts
--   LAND     a press's landing waits for its stop to be drawn (A on All milkable lands on Clear), then 1.5 s at most
--   BAND     the zone band's fit as drawBand lays it out; short of room the margins close up before Rename leaves
--   SOURCE   AnimalsTab and the World window's ring wire it up (alert A, roster X, the band's buttons, Feed's picker)
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
-- The game's milk and wool tests are AnimalsData's (the alerts and All milkable share them): the real ones, loaded
-- into a table of their own so the rest of the fake stays as it is.
local REAL
do
    local keep = ZeD.AnimalsData
    ZeD.AnimalsData = {}
    dofile(Z .. "AnimalsData.lua")
    REAL = ZeD.AnimalsData
    ZeD.AnimalsData = keep
    for _, k in ipairs({ "hasMilk", "hasWool", "canBeMilked", "canBeSheared", "getMilkQuantity", "getWoolQuantity",
                         "getMaxMilk", "isUdderUrgent" }) do keep[k] = REAL[k] end
end

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
    -- (an action is running while the queue holds any, unless the sim says the queue is stuck)
    isPlayerDoingAction = function(p) local q = ISTimedActionQueue.queues[p]; return not STUCK and q ~= nil and #q.queue > 0 end,
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
    onFeedAnimalFood = function(chr, animal, food)
        rec("feed:" .. animal._name .. ":" .. tostring(food and food._name) .. "#" .. tostring(food and food._id))
        animal._blocked = true
        local q = Q(chr).queue
        q[#q + 1] = "walk"; q[#q + 1] = "walkF"; q[#q + 1] = "ISFeedAnimalFromHand"
    end,
}
-- the game's fluids: Fluid.Get by the milk's name, and any animal milk
Fluid = { Get = function(name) return { _fluid = name } end, AnimalMilk = { _fluid = "AnimalMilk" } }
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
    -- what it eats from the hand (the game's getEatTypePossibleFromHand), and its breed's milk
    a._eats = o.eats
    a.getEatTypePossibleFromHand = function()
        if not a._eats then return nil end
        return { contains = function(_, k) for _, e in ipairs(a._eats) do if e == k then return true end end return false end }
    end
    a.getBreed = function() return { getMilkType = function() return a._mt end } end
    -- the points on its body the game's handlers read: known only while it is drawn near (a._far: not)
    a.getAttachmentWorldPos = function(_, n) if a._far then return nil end return { _point = n } end
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
        -- the game's own walk over the inventory and its bags, with ZeD's broad first test
        getAllEvalRecurse = function(_, fn)
            invCalls = invCalls + 1
            local out = {}
            for _, it in ipairs(p._food) do if fn(it) then out[#out + 1] = it end end
            return L(out)
        end,
    }
    p._food = {}
    -- (p._dropped[item]: the item left the inventory, as a bucket a stressed animal kicks out of the hands)
    p._dropped = {}
    inv.contains = function(_, it) return not p._dropped[it] end
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
check("GREY milk: no bucket", not ok and why == "UI_ZeD_Animals_NeedMilkContainer", why)
p._buckets = { bucket("GoatPail", "GoatMilk") }
ok, why = AQ.canMilk(p, bessie)
check("GREY milk: a bucket that takes only another milk", not ok and why == "UI_ZeD_Animals_NeedMilkContainer", why)
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
check("CACHE forgotten: the fresh answer", ok3 == false and why3 == "UI_ZeD_Animals_NeedMilkContainer", why3)
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
check("SELECT band: Feed, Shear then Milk", #v == 3 and v[1].id == "feed" and v[2].id == "shear" and v[3].id == "milk", #v)
check("SELECT band: Feed counts the four with any hunger, greyed: nothing carried", v[1] and v[1].n == 4 and v[1].ok == false
    and v[1].why == "UI_ZeD_Animals_NeedFood", v[1] and v[1].why)
check("SELECT band: Milk counts the two with milk (CowB has none)", v[3] and v[3].n == 2, v[3] and v[3].n)
check("SELECT band: Milk can (a bucket for cow milk)", v[3] and v[3].ok == true and v[3].why == nil)
check("SELECT band: Shear greyed, no shears", v[2] and v[2].ok == false and v[2].why == "UI_ZeD_Animals_NeedShears", v[2] and v[2].why)
local fed = animal("Fed", { milk = 0, milkable = true, hunger = 0 })
v = AQ.selectionVerbs(p, { fed })
check("SELECT band: nothing applies (not hungry, nothing to give), no verbs", #v == 0, #v)
p._buckets = { bucket("CowPail", "CowMilk") }
AQ.forgetChecks()
v = AQ.selectionVerbs(p, { goat })
v = v[#v]
check("SELECT band: a goat with only a cow-milk bucket greys Milk", v.id == "milk" and v.ok == false and v.why == "UI_ZeD_Animals_NeedMilkContainer",
    v.why)
AQ.forgetChecks()
v = AQ.selectionVerbs(p, { goat, cowA })
v = v[#v]
check("SELECT band: one animal the bucket takes is enough to offer Milk", v.id == "milk" and v.ok == true and v.n == 2)

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
    AQ.run == nil and #CALLS == 1 and AQ.last.why == "UI_ZeD_Animals_NeedMilkContainer", AQ.last.why .. " " .. #CALLS)
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

-- FEED ------------------------------------------------------------------------
-- carried things: o.food (a Food: food type, hunger change, rotten, spice), o.feed (animal feed of a kind), o.fluid
local nextId = 0
local function item(name, full, o)
    o = o or {}
    nextId = nextId + 1
    local it = { _name = name, _id = nextId, _class = o.food and "Food" or "Item" }
    local fc = o.fluid and { _fluid = o.fluid,
        isPureFluid = function(_, f) return f ~= nil and f._fluid == o.fluid end,
        getUiName = function() return o.fluidName or name end } or nil
    it.getFluidContainer = function() return fc end
    it.isAnimalFeed = function() return o.feed ~= nil end
    it.getAnimalFeedType = function() return o.feed end
    it.getFullType = function() return full end
    it.getFoodType = function() return o.food end
    it.getMilkType = function() return o.milkType end
    it.getHungerChange = function() return o.hunger or -10 end
    it.isRotten = function() return o.rotten == true end
    it.isSpice = function() return o.spice == true end
    it.getDisplayName = function() return name end
    it.getTex = function() return "tex:" .. name end
    return it
end
local function carrot() return item("Carrot", "Base.Carrots", { food = "Vegetables" }) end

ISTimedActionQueue.queues = {}
AQ.forgetChecks()
local fp = player()
local cow = animal("Cow", { hunger = 60, eats = { "Vegetables", "Fruits", "Hay" } })
local chick = animal("Chick", { hunger = 30, eats = { "Grain" } })
local goatF = animal("GoatF", { hunger = 0, eats = { "Vegetables" } })
local calf = animal("Calf", { hunger = 80, eats = { "CowMilk" }, mt = "CowMilk" })
local herd = { cow, chick, goatF, calf }

local fv = AQ.selectionVerbs(fp, herd)
check("FEED greyed: nothing carried, the reason", fv[1] and fv[1].id == "feed" and fv[1].ok == false
    and fv[1].why == "UI_ZeD_Animals_NeedFood" and fv[1].n == 3, fv[1] and tostring(fv[1].why) .. " n=" .. tostring(fv[1].n))
fp._food = { item("Salt", "Base.Salt", { food = "Vegetables", spice = true }),
             item("Rotten Carrot", "Base.Carrots", { food = "Vegetables", rotten = true }),
             item("Beer", "Base.BeerBottle", { fluid = "Beer" }),
             item("Steak", "Base.Steak", { food = "Meat" }) }
AQ.forgetChecks()
fv = AQ.selectionVerbs(fp, herd)
check("FEED greyed: a spice, a rotten carrot, beer and meat are no food for them", fv[1] and fv[1].ok == false
    and fv[1].why == "UI_ZeD_Animals_NeedFood", fv[1] and fv[1].why)

local c1, c2 = carrot(), carrot()
fp._food = { c1, item("Hay", "Base.HayTuft", { feed = "Hay" }), c2,
             item("Bird Seed", "Base.BirdSeed", { feed = "Grain" }),
             item("Milk bottle", "Base.WaterBottle", { fluid = "CowMilk", fluidName = "Cow Milk" }),
             item("Rotten Carrot", "Base.Carrots", { food = "Vegetables", rotten = true }),
             item("Salt", "Base.Salt", { food = "Vegetables", spice = true }),
             item("Bird Seed", "Base.BirdSeed", { feed = "Grain" }) }
AQ.forgetChecks()
local foods, fwhy, nh = AQ.feedChoices(fp, herd)
local names = {}
for _, f in ipairs(foods) do names[#names + 1] = f.name .. "=" .. f.suits .. "/" .. f.have end
local got = table.concat(names, " ")
check("FEED picker: one line per name, sorted, the fluid by its name, rotten and spice left out",
    got == "Bird Seed=1/2 Carrot=1/2 Cow Milk=1/1 Hay=1/1", got)
check("FEED picker: three hungry (GoatF is not, though it eats carrots)", nh == 3 and fwhy == nil, nh)
check("FEED picker: a food line carries the item's picture", foods[1] and foods[1].tex == "tex:Bird Seed")
fv = AQ.selectionVerbs(fp, herd)
check("FEED band: Feed (3), live", fv[1] and fv[1].id == "feed" and fv[1].ok and fv[1].n == 3)
-- a calf drinks its own breed's milk and any animal milk; a goat-milk jug is not for a cow calf
local gm = item("Goat jug", "Base.Jug", { fluid = "GoatMilk", fluidName = "Goat Milk" })
local am = item("Animal jug", "Base.Jug", { fluid = "AnimalMilk", fluidName = "Animal Milk" })
calf._eats = { "CowMilk", "AnimalMilk" }
check("FEED species: a calf drinks cow milk, not goat milk; any animal milk is AnimalMilk",
    not AQ.eats(calf, gm) and AQ.eats(calf, am) and not AQ.eats(chick, am))
calf._eats = { "CowMilk" }
-- the cache: a second ask within 500 ms does not look through the inventory
AQ.forgetChecks()
invCalls = 0
AQ.checkFeed(fp, herd); AQ.checkFeed(fp, herd)
check("FEED kept 500 ms: one look through the inventory", invCalls == 1, invCalls)
AQ.checkFeed(fp, { cow, chick })
check("FEED other animals: asked again", invCalls == 2, invCalls)
fp._food = {}
foods = AQ.checkFeed(fp, { cow, chick })
check("FEED kept: still the old answer within 500 ms", #foods > 0)
NOW = NOW + 500
foods, fwhy = AQ.checkFeed(fp, { cow, chick })
check("FEED kept: asked again at 500 ms, nothing carried now", #foods == 0 and fwhy == "UI_ZeD_Animals_NeedFood", fwhy)
foods, fwhy, nh = AQ.feedChoices(fp, { goatF })
check("FEED no hungry animal: no lines, n = 0", #foods == 0 and nh == 0)

-- can, act
fp._food = { c1, c2, item("Bird Seed", "Base.BirdSeed", { feed = "Grain" }) }
ok, why = AQ.canFeed(fp, goatF, "Carrot")
check("FEED can: not hungry", not ok and why == "UI_ZeD_Animals_NotHungry", why)
ok, why = AQ.canFeed(fp, cow, "Bird Seed")
check("FEED can: a cow does not eat bird seed", not ok and why == "UI_ZeD_Animals_NeedFood", why)
CALLS = {}
ok = AQ.act("feed", fp, cow, "Carrot")
check("FEED act: the game's onFeedAnimalFood with the first carrot", ok and CALLS[1] == "feed:Cow:Carrot#" .. c1._id, CALLS[1])
ok = AQ.start(fp, "feed", { cow })
check("FEED run needs a food", not ok)

-- the run: two hungry cows and a goat that is not, two carrots
local function feedDone(pl, a)
    a._hunger = math.max(0, a._hunger - 40)
    local it = nil
    for k, f in ipairs(pl._food) do if f._name == "Carrot" then it = k; break end end
    if it then table.remove(pl._food, it) end
    finishAction(pl)
end
ISTimedActionQueue.queues = {}
AQ.forgetChecks()
local k1 = animal("K1", { hunger = 70, eats = { "Vegetables" } })
local k2 = animal("K2", { hunger = 50, eats = { "Vegetables" } })
local k3 = animal("K3", { hunger = 0, eats = { "Vegetables" } })
fp._food = { carrot(), carrot() }
CALLS = {}
ok = AQ.start(fp, "feed", { k1, k3, k2 }, "Carrot")
check("FEED run starts: K1 handed over at once, the goat that is not hungry left out",
    ok and #CALLS == 1 and CALLS[1]:find("feed:K1:Carrot", 1, true) == 1 and #AQ.run.list == 2, table.concat(CALLS, " "))
check("FEED run status: Feeding 1 of 2", AQ.runStatus() == "UI_ZeD_Animals_RunFeeding(1,2)", AQ.runStatus())
for _ = 1, 40 do AQ.tick() end
check("FEED run waits while K1's actions are queued", #CALLS == 1)
feedDone(fp, k1); AQ.tick()
check("FEED run: K1 fed, K2 handed over", #CALLS == 2 and CALLS[2]:find("feed:K2:Carrot", 1, true) == 1, table.concat(CALLS, " "))
AQ.tick(); feedDone(fp, k2); AQ.tick()
check("FEED run ends Done 2 of 2, the hook off", AQ.run == nil and AQ.last.why == "UI_ZeD_Animals_RunDone(2,2)" and hookCount() == 0,
    AQ.last and AQ.last.why)

-- the player walks off: the queue empties, the hunger did not go down
ISTimedActionQueue.queues = {}
local w1 = animal("W1", { hunger = 70, eats = { "Vegetables" } })
local w2 = animal("W2", { hunger = 70, eats = { "Vegetables" } })
fp._food = { carrot(), carrot() }
CALLS = {}
AQ.start(fp, "feed", { w1, w2 }, "Carrot")
AQ.tick(); w1._hunger = 70.01; finishAction(fp); AQ.tick()
check("FEED walk away: Stopped after 0 of 2, W2 never handed over", AQ.run == nil and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,2)"
    and #CALLS == 1, AQ.last and AQ.last.why)
check("FEED walk away: W1 lets go", w1._blocked == false)

-- the food runs out: three hungry, one carrot
ISTimedActionQueue.queues = {}
local r1 = animal("R1", { hunger = 70, eats = { "Vegetables" } })
local r2 = animal("R2", { hunger = 70, eats = { "Vegetables" } })
local r3 = animal("R3", { hunger = 70, eats = { "Vegetables" } })
fp._food = { carrot() }
CALLS = {}
AQ.start(fp, "feed", { r1, r2, r3 }, "Carrot")
AQ.tick(); feedDone(fp, r1); AQ.tick()
check("FEED food runs out: R1 counts, the run ends with the reason", AQ.run == nil and #CALLS == 1
    and AQ.last.why == "UI_ZeD_Animals_NeedFood" and AQ.last.done == 1, AQ.last and AQ.last.why)
fp._food = {}
ok, why = AQ.start(fp, "feed", { r2 }, "Carrot")
check("FEED nothing of that food: no run, the reason", not ok and why == "UI_ZeD_Animals_NeedFood", why)

-- MILKRULE --------------------------------------------------------------------
-- The game's milk rule (InventoryItem.isAvailableFluidContainer, through getAvailableFluidContainer on the main
-- inventory): any container that is empty or holds this milk, a water bottle as much as a bucket; the bags in the
-- inventory are not looked in. The greyed reason says so.
ISTimedActionQueue.queues = {}
AQ.forgetChecks()
do
    local pm = player()
    local cowM = animal("CowM", { milk = 4, milkable = true })
    pm._buckets = { bucket("WaterBottle") }
    local okM, whyM, toolM = AQ.canMilk(pm, cowM)
    check("MILKRULE an empty water bottle is a milk container to the game: Milk is offered with it",
        okM and toolM and toolM._name == "WaterBottle", whyM)
    pm._buckets = {}
    okM, whyM = AQ.canMilk(pm, cowM)
    check("MILKRULE the reason names the game's rule, not a bucket", not okM and whyM == "UI_ZeD_Animals_NeedMilkContainer", whyM)
    local AQsrc = readFile(Z .. "AnimalsQuick.lua")
    check("MILKRULE the offer is the game's own list (main inventory, no bag walk)",
        AQsrc:find('ocall(inv, "getAvailableFluidContainer", mt)', 1, true) ~= nil
        and AQsrc:find("getAvailableFluidContainerRecurse", 1, true) == nil)
    local EN = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json")
    check("MILKRULE the old bucket wording is gone, the new key is there",
        EN:find("UI_ZeD_Animals_NeedBucket", 1, true) == nil and EN:find('"UI_ZeD_Animals_NeedMilkContainer"', 1, true) ~= nil)
    local noSq = animal("NoSq", { milk = 4, milkable = true, sq = false })
    pm._buckets = { bucket("Bucket1") }
    okM, whyM = AQ.canMilk(pm, noSq)
    check("MILKRULE an animal with no square is out of reach (the game's milking reads its square)",
        not okM and whyM == "UI_ZeD_Animals_OutOfReach", whyM)
end

-- FAR -------------------------------------------------------------------------
-- An animal not drawn near the player has no body points; the game's handlers read them (vanilla throws "attempted
-- index: x of non-table" in onMilkAnimal). ZeD walks up first and hands the act over when the walk is done.
ISTimedActionQueue.queues = {}
AQ.forgetChecks()
WALK_OK = true
do
    p._buckets = { bucket("Bucket1") }
    local far1 = animal("Far1", { milk = 5, milkable = true }); far1._far = true
    CALLS = {}
    local okF = AQ.start(p, "milk", { far1 })
    check("FAR not drawn near: only the walk up is handed over, not the game's milk handler",
        okF and #CALLS == 1 and CALLS[1] == "walk:Far1@sq" and AQ.run and AQ.run.approach == true, table.concat(CALLS, " "))
    AQ.tick(); far1._far = false; finishAction(p); AQ.tick()
    check("FAR the walk done, the animal drawn: the milk handed over", CALLS[2] == "milk:Far1:Bucket1:true"
        and AQ.run ~= nil and not AQ.run.approach, table.concat(CALLS, " "))
    AQ.tick(); far1._milk = 0; finishAction(p); AQ.tick()
    check("FAR then Done 1 of 1", AQ.run == nil and AQ.last.why == "UI_ZeD_Animals_RunDone(1,1)", AQ.last and AQ.last.why)

    local far2 = animal("Far2", { milk = 5, milkable = true }); far2._far = true
    CALLS = {}
    AQ.start(p, "milk", { far2 })
    AQ.tick(); finishAction(p); AQ.tick()
    local joined = table.concat(CALLS, " ")
    check("FAR still not drawn after the walk: ends Out of reach, the handler never called, the queue cleared",
        AQ.run == nil and AQ.last.why == "UI_ZeD_Animals_OutOfReach" and joined:find("milk:", 1, true) == nil
        and #ISTimedActionQueue.queues[p].queue == 0, joined)

    local farSheep = animal("FarSheep", { wool = 5, shearable = true }); farSheep._far = true
    p._shears = { shears("Manual") }
    CALLS = {}
    local okS, _, howS = AQ.act("shear", p, farSheep)
    check("FAR shear: the walk up only", okS and howS == "approach" and CALLS[1] == "walk:FarSheep@sq" and #CALLS == 1, table.concat(CALLS, " "))
    local farCow = animal("FarCow", { hunger = 70, eats = { "Vegetables" } }); farCow._far = true
    local fpF = player(); fpF._food = { carrot() }
    CALLS = {}
    local okD, _, howD = AQ.act("feed", fpF, farCow, "Carrot")
    check("FAR feed: the walk up only (the game's feed reads the head point)", okD and howD == "approach" and #CALLS == 1, table.concat(CALLS, " "))
    WALK_OK = false
    CALLS = {}
    local okW, whyW = AQ.act("milk", p, animal("Far3", { milk = 5, milkable = true, }))
    check("FAR drawn: no walk needed, the handler at once", okW and CALLS[1] == "milk:Far3:Bucket1:true", table.concat(CALLS, " "))
    local far4 = animal("Far4", { milk = 5, milkable = true }); far4._far = true
    CALLS = {}
    okW, whyW = AQ.act("milk", p, far4)
    check("FAR no free square beside it: out of reach, nothing handed over", not okW and whyW == "UI_ZeD_Animals_OutOfReach" and #CALLS == 1, whyW)
    WALK_OK = true
    ISTimedActionQueue.queues = {}
end

-- AWAY ------------------------------------------------------------------------
-- The run gives up cleanly: the player moved well away (by other means than the stick, which cancels on its own),
-- a queue holding actions with none running, or one animal taking too long. Each clears the game's queue (nothing
-- of the run's left waiting) and lets the animal go.
do
    local pa = player()
    pa._x, pa._y = 0, 0
    pa.getX = function() return pa._x end
    pa.getY = function() return pa._y end
    pa._buckets = { bucket("B") }
    local function at(a, x, y) a.getX = function() return x end; a.getY = function() return y end; return a end
    local g1 = at(animal("G1", { milk = 5, milkable = true }), 1, 0)
    local g2 = at(animal("G2", { milk = 5, milkable = true }), 2, 0)
    ISTimedActionQueue.queues = {}
    CALLS = {}
    AQ.start(pa, "milk", { g1, g2 })
    for _ = 1, 10 do AQ.tick() end
    check("AWAY the run waits while the player stands by", AQ.run ~= nil)
    pa._x, pa._y = 16, 16
    AQ.tick()
    check("AWAY moved 16 squares off mid-milking: the run stops, Stopped after 0 of 2",
        AQ.run == nil and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,2)", AQ.last and AQ.last.why)
    check("AWAY nothing left queued, G1 let go", #ISTimedActionQueue.queues[pa].queue == 0 and g1._blocked == false
        and table.concat(CALLS, " "):find("clear", 1, true) ~= nil, table.concat(CALLS, " "))
    check("AWAY the tick hook is off", hookCount() == 0)

    -- walking up from afar is no walk-off: the distance only shrinks
    pa._x, pa._y = 20, 0
    g1._milk = 5
    ISTimedActionQueue.queues = {}
    AQ.start(pa, "milk", { g1 })
    for x = 19, 2, -1 do pa._x = x; AQ.tick() end
    check("AWAY walking up 20 squares: the run goes on", AQ.run ~= nil)
    pa._x = 9
    AQ.tick()
    check("AWAY 8 squares off after coming within 1: still within the margin", AQ.run ~= nil)
    pa._x = 11
    AQ.tick()
    check("AWAY 10 squares off after coming within 1: stopped", AQ.run == nil)

    -- a stuck queue: actions in it, none running
    pa._x = 0
    g1._milk = 5
    ISTimedActionQueue.queues = {}
    AQ.start(pa, "milk", { g1 })
    STUCK = true
    for _ = 1, AQ.STALL_TICKS do AQ.tick() end
    check("AWAY a stuck queue is given STALL_TICKS ticks", AQ.run ~= nil)
    AQ.tick()
    check("AWAY then the run stops and clears it", AQ.run == nil and #ISTimedActionQueue.queues[pa].queue == 0 and g1._blocked == false)
    STUCK = false

    -- too long
    g1._milk = 5
    ISTimedActionQueue.queues = {}
    AQ.start(pa, "milk", { g1 })
    AQ.tick()
    NOW = NOW + AQ.WAIT_MS + 1
    AQ.tick()
    check("AWAY one animal past WAIT_MS: stopped, cleared", AQ.run == nil and #ISTimedActionQueue.queues[pa].queue == 0)
    ISTimedActionQueue.queues = {}
end

-- CAUSE -----------------------------------------------------------------------
-- What ended a run is kept for QA's logs (AQ.last.cause), and a milking that stopped with milk left counts as done
-- only when the bucket is still carried and has no room; a bucket kicked out of the hands is a stop.
do
    local pc = player()
    local bk = bucket("BK")
    pc._buckets = { bk }
    local h1 = animal("H1", { milk = 6, milkable = true })
    local h2 = animal("H2", { milk = 6, milkable = true })
    ISTimedActionQueue.queues = {}
    AQ.forgetChecks()
    CALLS = {}
    AQ.start(pc, "milk", { h1, h2 })
    AQ.tick(); pc._dropped[bk] = true; pc._buckets = {}; finishAction(pc); AQ.tick()
    check("CAUSE the bucket kicked away mid-milking (milk left): a stop, not a done, H2 never handed over",
        AQ.run == nil and AQ.last.done == 0 and AQ.last.cause == "undone" and #CALLS == 1, AQ.last and tostring(AQ.last.cause) .. " " .. AQ.last.done)
    local bk2 = bucket("BK2")
    pc._buckets = { bk2 }; pc._dropped = {}
    ISTimedActionQueue.queues = {}
    CALLS = {}
    AQ.start(pc, "milk", { h1, h2 })
    AQ.tick(); pc._buckets = {}; finishAction(pc); AQ.tick()
    check("CAUSE the bucket carried and full (milk left): H1 counts, the run ends with the container reason",
        AQ.run == nil and AQ.last.done == 1 and AQ.last.cause == "refused" and AQ.last.why == "UI_ZeD_Animals_NeedMilkContainer",
        AQ.last and tostring(AQ.last.cause) .. " " .. tostring(AQ.last.why))
    pc._buckets = { bk2 }
    ISTimedActionQueue.queues = {}
    AQ.start(pc, "milk", { h1 })
    AQ.tick(); h1._milk = 0; finishAction(pc); AQ.tick()
    check("CAUSE done", AQ.last.cause == "done", AQ.last.cause)
    h1._milk = 6
    ISTimedActionQueue.queues = {}
    AQ.start(pc, "milk", { h1 })
    AQ.stop()
    check("CAUSE Stop", AQ.last.cause == "stop", AQ.last.cause)
    ISTimedActionQueue.queues = {}
end

-- FULL ------------------------------------------------------------------------
-- The game's rule passes a bucket full of this milk, and its milking then stops on the first pull: ZeD skips full
-- ones. Two cows and a 10 L bucket that fills on the second: the first counts, the second counts (the bucket full,
-- not undone), the run ends Done 2 of 2.
do
    local function fluidBucket(name, full)
        local b = bucket(name)
        b._full = full
        b.getFluidContainer = function() return { isFull = function() return b._full end } end
        return b
    end
    local pf = player()
    local fullB, roomB = fluidBucket("Full", true), fluidBucket("Room", false)
    pf._buckets = { fullB, roomB }
    local cowF = animal("CowF", { milk = 4, milkable = true })
    AQ.forgetChecks()
    local okF, _, toolF = AQ.canMilk(pf, cowF)
    check("FULL a full bucket is passed over for one with room", okF and toolF == roomB, toolF and toolF._name)
    pf._buckets = { fullB }
    local okN, whyN = AQ.canMilk(pf, cowF)
    check("FULL only a full bucket: Milk greyed with the container reason", not okN and whyN == "UI_ZeD_Animals_NeedMilkContainer", whyN)
    local k1 = animal("K1F", { milk = 8, milkable = true })
    local k2 = animal("K2F", { milk = 8, milkable = true })
    local b10 = fluidBucket("B10", false)
    pf._buckets = { b10 }
    ISTimedActionQueue.queues = {}
    CALLS = {}
    AQ.start(pf, "milk", { k1, k2 })
    AQ.tick(); k1._milk = 0; finishAction(pf); AQ.tick()
    check("FULL the first cow milked dry, the second handed over", #CALLS == 2, table.concat(CALLS, " "))
    AQ.tick(); k2._milk = 6; b10._full = true; finishAction(pf); AQ.tick()
    check("FULL the bucket full on the second (milk left): Done 2 of 2, not Stopped",
        AQ.run == nil and AQ.last.done == 2 and AQ.last.cause == "done", AQ.last and tostring(AQ.last.cause) .. " " .. AQ.last.done)
    ISTimedActionQueue.queues = {}
end

-- LAND and BAND ---------------------------------------------------------------
-- Cut AT.navFocusIndex and AT.bandFits out of AnimalsTab.lua and run them as they are.
do
    local TABSRC = readFile(Z .. "AnimalsTab.lua")
    local function cutTab(from)
        local a = TABSRC:find(from, 1, true)
        assert(a, "not in AnimalsTab.lua: " .. from)
        local _, b = TABSRC:find("\nend\n", a, true)
        return TABSRC:sub(a, b)
    end
    local navMs = TABSRC:match("\n(local NAV_FOCUS_MS = %d+)")
    local env = setmetatable({ AT = {} }, { __index = _G })
    local chunk = assert(loadstring(navMs .. "\n" .. cutTab("function AT.navFocusIndex(") .. cutTab("function AT.bandFits(")))
    setfenv(chunk, env)
    chunk()
    local ATs = env.AT

    -- LAND: A on All milkable names Clear; the ring is built once from the band as it was, then from the new one
    local win = { _animalsNavFocusTarget = "animals:bulk:clear" }
    local before = { { id = "animals:roster:1" }, { id = "animals:bulk:hungry" }, { id = "animals:bulk:milkable" } }
    local after = { { id = "animals:roster:1" }, { id = "animals:bulk:clear" }, { id = "animals:bulk:feed" }, { id = "animals:bulk:milk" } }
    check("LAND the band not redrawn yet: no landing, the target kept", ATs.navFocusIndex(win, before, 1000) == nil
        and win._animalsNavFocusTarget == "animals:bulk:clear")
    check("LAND the band redrawn: lands on Clear (not Milk or Feed), the target spent",
        ATs.navFocusIndex(win, after, 1016) == 2 and win._animalsNavFocusTarget == nil and win._animalsNavFocusSince == nil)
    win._animalsNavFocusTarget = "animals:bulk:gone"
    ATs.navFocusIndex(win, before, 5000)
    ATs.navFocusIndex(win, before, 6400)
    check("LAND a target never drawn is kept 1.5 s", win._animalsNavFocusTarget == "animals:bulk:gone")
    ATs.navFocusIndex(win, before, 6501)
    check("LAND then dropped", win._animalsNavFocusTarget == nil)
    win._animalsNavFocusTarget = "breadcrumb"
    check("LAND the breadcrumb", ATs.navFocusIndex(win, { { id = "x" }, { id = "y", isBreadcrumb = true } }, 1) == 2)

    -- BAND: the German band at 4K 1.75x as QA's second run drew it (zqa_aq2 band log: hungry 14 207x46, milkable 235
    -- 207x46, remove 618 207x46, so the band is 839 px), Umbenennen 162 px (Fira Mono 11.36 px a letter, 24 px pad)
    local W = { ["Alle hungrigen"] = 207, ["Alle melkbaren"] = 207, ["Umbenennen"] = 162, ["Zone entfernen"] = 207,
                ["All hungry"] = 150, ["All milkable"] = 180, ["Rename"] = 115, ["Remove zone"] = 170 }
    ZeD.T = { px = function(u) return math.floor(u * 1.75 + 0.5) end }
    ZeD.Molecules = { buttonW = function(l) return W[l] end }
    local leadDE = { { label = "Alle hungrigen" }, { label = "Alle melkbaren" } }
    local shownDE = { { label = "Umbenennen", id = "rename" }, { label = "Zone entfernen", id = "remove" } }
    local fits, edge, gap = ATs.bandFits(839, leadDE, shownDE)
    check("BAND German, 839 px: Rename stays, margins and spaces close up to 4u", fits == true and edge == 7 and gap == 7,
        tostring(fits) .. " " .. tostring(edge) .. " " .. tostring(gap))
    -- (4u margins with 8u spaces need 14 + 783 + 42 = 839: a rounding off losing Rename, as QA saw)
    check("BAND 4u margins alone are no room to spare", 14 + 783 + 42 >= 839)
    fits, edge, gap = ATs.bandFits(839, { { label = "All hungry" }, { label = "All milkable" } },
        { { label = "Rename" }, { label = "Remove zone" } })
    check("BAND English: fits at the usual margins and spaces", fits == true and edge == nil and gap == nil)
    fits = ATs.bandFits(810, leadDE, shownDE)
    check("BAND German at 810 px: Rename leaves", fits == false)
    ZeD.T, ZeD.Molecules = nil, nil
end

-- ZONES -----------------------------------------------------------------------
-- The poller's zone counts: the game's zone:getAnimalsConnected() first (a spawned hen can sit with no getDZone()
-- for a long while), getDZone() the fallback, no animal counted twice; the zone rows, the totals, the bulk
-- selection's list (getAnimalsInZone) and an animal's zone name all agree.
do
    local ADs = ZeD.AnimalsData
    local function no() return false end
    local function zero() return 0 end
    ADs.isWild = function(a) return a._wild == true end
    ADs.getAnimalType = function(a) return a._type or "cow" end
    ADs.isUdderUrgent, ADs.canBeMilked, ADs.canBeSheared, ADs.needsMother, ADs.attacksOtherMales, ADs.isBaby = no, no, no, no, no, no
    ADs.isFemale = function() return true end
    ADs.getThirst, ADs.getStress, ADs.getEggsPerDay, ADs.getMaxMilk = zero, zero, zero, zero
    Events.EveryOneMinute = { Add = function() end, Remove = function() end }
    Events.OnGameStart = { Add = function() end }

    local function placed(name, x, y, o)
        local a = animal(name, o)
        a._x, a._y = x, y
        a.getX = function() return a._x end
        a.getY = function() return a._y end
        a.getZ = function() return 0 end
        a.getDZone = function() return a._dz end
        return a
    end
    local function zoneOf(name, connected)
        local z = { _name = name, _conn = connected }
        z.isStillStreamed = function() return true end
        z.getName = function() return z._name end
        if connected then z.getAnimalsConnected = function() return L(z._conn) end end
        return z
    end
    local hen = placed("Hen", 10, 10, { type = "hen" })      -- spawned: no getDZone yet, connected to the pen
    local cowP = placed("CowP", 12, 10)                       -- both: getDZone and connected (counted once)
    local stray = placed("Stray", 15, 10)                     -- getDZone only (an older game, or not yet connected)
    local wild = placed("Wild", 11, 11); wild._wild = true
    local far = placed("Far", 500, 500)                       -- connected but past the scan's reach
    hen._type = "hen"
    local pen = zoneOf("QA Pen", { hen, cowP, far })
    local field = zoneOf("Field", {})
    local old = zoneOf("Old", nil)                            -- a zone with no getAnimalsConnected (guarded)
    cowP._dz = pen
    stray._dz = old
    local cellList = { hen, cowP, stray, wild, far }
    getCell = function()
        return { getAnimals = function()
            local i = 0
            return { iterator = function() return {
                hasNext = function() return i < #cellList end,
                next = function() i = i + 1; return cellList[i] end } end }
        end }
    end
    local me = { getCurrentSquare = function() return { getX = function() return 10 end, getY = function() return 10 end,
                                                        getZ = function() return 0 end } end }
    getSpecificPlayer = function() return me end
    DesignationZoneAnimal = { getAllZones = function() return L({ pen, field, old }) end }
    dofile(Z .. "AnimalsAlertPoller.lua")
    local AP = ZeD.AnimalsAlertPoller
    AP.refreshCache()
    local function sumOf(n) local s = AP.getZoneSummary(n); return s and s.count or -1 end
    check("ZONES the pen counts the spawned hen (connected, no getDZone), the cow once, the far one: 3",
        sumOf("QA Pen") == 3, sumOf("QA Pen"))
    check("ZONES an empty zone is listed with 0", sumOf("Field") == 0, sumOf("Field"))
    check("ZONES getDZone is the fallback (a zone with no connected list)", sumOf("Old") == 1, sumOf("Old"))
    local t = AP.getTotals()
    check("ZONES the totals agree: 4 animals, 1 hen (the wild one left out)", t.totalAnimals == 4 and t.speciesCounts.hen == 1,
        t.totalAnimals)
    local penList = AP.getAnimalsInZone("QA Pen")
    local hasHen = false
    for _, a in ipairs(penList) do if a == hen then hasHen = true end end
    check("ZONES the bulk selection's list holds the hen", #penList == 3 and hasHen, #penList)
    local selP = AQ.newSelection()
    hen._hunger = 60
    check("ZONES All hungry in the pen finds the hen", AQ.selectWhere(selP, penList, "hungry") == 1 and AQ.isSelected(selP, hen))
    check("ZONES the hen's zone name is the pen's (getDZone still empty)", AP.getZoneNameOf(hen) == "QA Pen", AP.getZoneNameOf(hen))
    local ADsrc = readFile(Z .. "AnimalsData.lua")
    check("ZONES AnimalsData.getZoneName asks the poller first, getDZone after",
        ADsrc:find("AP.getZoneNameOf(animal)", 1, true) ~= nil and ADsrc:find("if kept then return kept end", 1, true) ~= nil)
    -- the zone rows add up to the animals in zones; no animal in two zones
    local inZones, twice = 0, false
    local seenZ = {}
    for _, z in ipairs(AP.getZoneList()) do
        local s = AP.getZoneSummary(z._name)
        for _, a in ipairs(s and s.animals or {}) do
            if seenZ[a] then twice = true end
            seenZ[a] = true
            inZones = inZones + 1
        end
    end
    check("ZONES no animal counted twice; the zone rows hold all 4", not twice and inZones == 4, inZones)
end

-- ALERTS ----------------------------------------------------------------------
-- "Ready to milk", "Udder" and "Ready to shear" are raised by the game's menu tests and no looser: milk above 0.1 L
-- on a breed that can be milked; wool above 1 on a breed that can be sheared. All milkable and the roster tags agree.
do
    local ADs = ZeD.AnimalsData
    for _, k in ipairs({ "canBeMilked", "canBeSheared", "getMaxMilk", "isUdderUrgent" }) do ADs[k] = REAL[k] end
    local function mk(name, milkable, shearable, milk, wool, max)
        local a = animal(name, { milk = milk, wool = wool, milkable = milkable, shearable = shearable })
        a._x = 10
        a.getX = function() return 10 end
        a.getY = function() return 10 end
        a.getZ = function() return 0 end
        a.getDZone = function() return nil end
        a.getData().getMaxMilk = function() return max or 10 end
        return a
    end
    local cases = {
        mk("CowDry", true, false, 0, 0),            -- cow, no milk
        mk("CowTrace", true, false, 0.1, 0),        -- exactly 0.1: the game offers nothing
        mk("CowMilk", true, false, 4, 0),           -- cow with milk
        mk("CowFull", true, false, 12, 0),          -- past its udder's limit: the urgent alert, not both
        mk("EweDry", true, true, 0, 0.5),           -- ewe: no milk, wool under one
        mk("EweWool1", true, true, 0, 1),           -- exactly 1 wool: nothing
        mk("EweWool", true, true, 0, 3),            -- ewe with wool and no milk: shear only
        mk("EweBoth", true, true, 2, 4),            -- milk and wool: both
        mk("GoatMilk", true, false, 0.5, 0),        -- goat with a little milk
        mk("GoatDry", true, false, 0.05, 0),        -- goat with a trace of milk
        mk("PigMilk", false, false, 5, 0),          -- a breed that cannot be milked, whatever it holds
        mk("RamWool", false, true, 0, 6),           -- ram: shear, never milk
    }
    local list = L(cases)
    local ctxCell = { getAnimals = function()
        local i = 0
        return { iterator = function() return {
            hasNext = function() return i < #cases end,
            next = function() i = i + 1; return cases[i] end } end }
    end }
    getCell = function() return ctxCell end
    getSpecificPlayer = function() return { getCurrentSquare = function() return { getX = function() return 10 end,
        getY = function() return 10 end, getZ = function() return 0 end } end } end
    DesignationZoneAnimal = { getAllZones = function() return L({}) end }
    ZeD.AnimalsAlertPoller = nil
    dofile(Z .. "AnimalsAlertPoller.lua")
    local AP2 = ZeD.AnimalsAlertPoller
    AP2.refreshCache()
    local by = {}
    for _, al in ipairs(AP2.getAlerts()) do
        local nm = al.animal._name
        by[nm] = by[nm] or {}
        by[nm][al.alertType] = true
    end
    local function has(nm, t) return by[nm] ~= nil and by[nm][t] == true end
    local function none(nm) return by[nm] == nil end
    check("ALERTS cow with no milk: no alert", none("CowDry"))
    check("ALERTS cow at exactly 0.1 L: no alert", none("CowTrace"))
    check("ALERTS cow with 4 L: Ready to milk", has("CowMilk", "ready_milk") and not has("CowMilk", "udder_urgent"))
    check("ALERTS cow past its udder's limit: urgent only", has("CowFull", "udder_urgent") and not has("CowFull", "ready_milk"))
    check("ALERTS ewe with wool under one: no alert", none("EweDry"))
    check("ALERTS ewe with exactly 1 wool: no alert", none("EweWool1"))
    check("ALERTS ewe with 3 wool and no milk: Ready to shear, no milk alert",
        has("EweWool", "ready_shear") and not has("EweWool", "ready_milk"))
    check("ALERTS ewe with both: milk and shear", has("EweBoth", "ready_milk") and has("EweBoth", "ready_shear"))
    check("ALERTS goat with 0.5 L: Ready to milk", has("GoatMilk", "ready_milk"))
    check("ALERTS goat with 0.05 L: no alert", none("GoatDry"))
    check("ALERTS a breed that cannot be milked: no milk alert", none("PigMilk"))
    check("ALERTS ram: shear only", has("RamWool", "ready_shear") and not has("RamWool", "ready_milk"))
    -- All milkable and All shearable agree with the alerts, animal by animal
    local agree, nMilk, nWool = true, 0, 0
    for _, a in ipairs(cases) do
        local alertMilk = has(a._name, "ready_milk") or has(a._name, "udder_urgent")
        if alertMilk ~= AQ.hasMilk(a) then agree = false end
        if has(a._name, "ready_shear") ~= AQ.hasWool(a) then agree = false end
        if alertMilk then nMilk = nMilk + 1 end
        if has(a._name, "ready_shear") then nWool = nWool + 1 end
    end
    check("ALERTS All milkable and the shear test say what the alerts say, animal by animal", agree)
    check("ALERTS All milkable counts the alerts' milk animals: 4 (cow, full cow, ewe with both, goat)",
        AQ.countWhere(cases, "milkable") == nMilk and nMilk == 4, nMilk)
    check("ALERTS wool alerts: 3 (ewe, ewe with both, ram)", nWool == 3, nWool)
    local sel = AQ.newSelection()
    check("ALERTS All milkable picks 4", AQ.selectWhere(sel, cases, "milkable") == 4)
    -- milk the cow dry: the alert clears and the pick drops her
    cases[3]._milk = 0
    AP2.refreshCache()
    local still = false
    for _, al in ipairs(AP2.getAlerts()) do if al.animal == cases[3] then still = true end end
    check("ALERTS milked dry: the cow's alert clears and All milkable skips her",
        not still and AQ.countWhere(cases, "milkable") == 3)
    -- the roster tags use the same tests
    ADs.getConditionTags = REAL.getConditionTags
    check("ALERTS source: the tags use hasMilk and hasWool",
        readFile(Z .. "AnimalsData.lua"):find("if AD.hasMilk(animal) then", 1, true) ~= nil
        and readFile(Z .. "AnimalsData.lua"):find("if AD.hasWool(animal) then", 1, true) ~= nil)
end

-- SOURCE ----------------------------------------------------------------------
local TAB = readFile(Z .. "AnimalsTab.lua")
local WW = readFile(Z .. "ZeD_WorldWindow.lua")
check("SOURCE the tab requires AnimalsQuick", TAB:find('require "ZeD/AnimalsQuick"', 1, true) ~= nil)
check("SOURCE the alert row's verb button", TAB:find("QK().alertVerb(alert.alertType)", 1, true) ~= nil)
check("SOURCE the verbs are the game's words", TAB:find('milk = "ContextMenu_Milk", shear = "ContextMenu_Shear", ["goto"] = "ContextMenu_Walk_to"', 1, true) ~= nil)
check("SOURCE alert A calls AT.alertAct", WW:find("AT.alertAct(w, el.animal, el.verb)", 1, true) ~= nil)
check("SOURCE roster X toggles", WW:find("AT.toggleSelected(w, el.animal)", 1, true) ~= nil)
check("SOURCE band buttons are stops", WW:find('id = "animals:bulk:" .. tostring(b.id)', 1, true) ~= nil)
check("SOURCE a focus target may be an id", TAB:find('(target == "breadcrumb" and e.isBreadcrumb) or e.id == target', 1, true) ~= nil)
check("SOURCE the ring asks AT.navFocusIndex and applies a found landing even when the stops did not change",
    WW:find("navIdx = ZeD.AnimalsTab.navFocusIndex(win, newEls, getTimestampMs())", 1, true) ~= nil
    and WW:find("if dirty or alwaysRebuild or cardJumpIdx or navIdx then", 1, true) ~= nil
    and WW:find("win._animalsNavFocusTarget = nil", 1, true) == nil)
check("SOURCE alert Milk and Shear go as a run of one", TAB:find('if verb == "milk" or verb == "shear" then return QK().start(player, verb, { animal }) == true end', 1, true) ~= nil)
check("SOURCE the zone band asks AT.bandFits and draws with its margin and space",
    TAB:find("local keepRename, closeEdge, closeGap = AT.bandFits(w, lead, shown)", 1, true) ~= nil
    and readFile(Z .. "Molecules.lua"):find("spec.gap or T.px(8)", 1, true) ~= nil
    and TAB:find("status = status and { text = status } or nil, edge = edge, gap = gap })", 1, true) ~= nil)
check("SOURCE right-click on a row toggles", TAB:find("return AT.toggleSelected(win, rz.animal)", 1, true) ~= nil)
check("SOURCE Feed is the game's word", TAB:find('feed = "ContextMenu_Feed"', 1, true) ~= nil)
check("SOURCE Feed in the band opens the picker", TAB:find("return AT.openFeedPicker(win, state.zoneName, sx, sy)", 1, true) ~= nil)
check("SOURCE the picker is ZeD's pull-down list (A picks, B cancels there), headed Feed",
    TAB:find("ZeD_ContextList:new(0, \"cursor\", sx, sy, nil, rows, nil)", 1, true) ~= nil
    and TAB:find('m.headText = getText("ContextMenu_Feed")', 1, true) ~= nil
    and TAB:find("ISScrollingListBox", 1, true) == nil)
check("SOURCE a food line: how many it suits, of how many hungry, how many carried",
    TAB:find('ZeD.tr("UI_ZeD_Animals_FeedNote", c.suits, hungry, c.have)', 1, true) ~= nil)
check("SOURCE a pick starts the feeding run with the food's name",
    TAB:find('Q.start(getSpecificPlayer(0), "feed", Q.prune(sel, AP().getAnimalsInZone(zoneName)), name)', 1, true) ~= nil)
local CL = readFile(Z .. "ZeD_ContextList.lua")
check("SOURCE the list: A confirms, B cancels",
    CL:find("if button == Joypad.AButton then self:confirm()", 1, true) ~= nil
    and CL:find("elseif button == Joypad.BButton then self:cancel() end", 1, true) ~= nil)
local AQS = readFile(Z .. "AnimalsQuick.lua")
check("SOURCE the act is the game's onFeedAnimalFood", AQS:find("AnimalContextMenu.onFeedAnimalFood(player, animal, tool)", 1, true) ~= nil)

print(string.format("animals_quick_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
