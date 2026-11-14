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
--            animal go, ends with the reason when the food runs out; the game's gates: hungry is its world menu's 0.1
--            (the trailer's too, the hands' any hunger), milk only past 0.1 hunger or thirst (single precision)
--   PERF     the feed tests read each item and each animal once (eat lists, item reads counted)
--   ZONES    the poller counts a zone's animals as the game's zone window does (getAnimalsConnected, getDZone the
--            fallback, none twice); zone rows, totals, the bulk selection's list and an animal's zone name agree
--   MILKRULE the game's milk rule: any container that is empty or holds this milk (a water bottle too), main
--            inventory only; the greyed reason says so; an animal with no square is out of reach
--   FAR      an animal not drawn near (no body points): the walk up first, the game's handler after it; still not
--            drawn, out of reach and nothing handed over
--   AWAY     the run gives up cleanly (queue cleared, animal let go) when the player is moved well off, the queue
--            is stuck, or one animal takes too long; walking up from afar is no walk-off, nor is a walk's detour
--            round a wall; a pause (no ticks) does not count toward too long
--   WANDER   the walk up holds the animal still; a walk that reached its square hands the act over wherever the
--            animal stands; one cut short far off is a stop; every way out lets the animal go
--   REPLACE  a press during a run halts it (queue cleared, animal let go) before the new act is handed over
--   FULL     a bucket full of this milk is passed over; the last container filling mid-run ends it "Bucket full:
--            milked n of m"; with another container carried the run goes on with it, one of another kind too (the
--            same animal handed over again)
--   SWITCH   the game's milking moves on by itself from a full bucket to the next of its kind: a cancel or an alert's
--            Walk to after that, or just as the bucket filled, is a stop with no second hand-over (nobody walked
--            back); the bucket it moved on to kicked away is a stop with a pot carried too; only a milking out of room
--            hands the animal over again (its search starts at the first container for this milk); an alert's Walk
--            to during the walk up to a far animal is a stop
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
ZeD.AnimalsData = { getHunger = function(a) return a._hunger or 0 end, getThirst = function(a) return a._thirst or 0 end }
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
-- the game's actions as the queue holds them: tables with their Type; the walks take setOnComplete, as the game's do
local function action(t)
    local o = { Type = t }
    if t == "ISWalkToTimedAction" or t == "ISWalkToTimedActionF" then
        o.setOnComplete = function(self, f, a1) self._onDone, self._arg = f, a1 end
    end
    return o
end
AnimalContextMenu = {
    onMilkAnimal = function(animal, chr, bucket, all)
        rec("milk:" .. animal._name .. ":" .. tostring(bucket and bucket._name) .. ":" .. tostring(all))
        animal._blocked = true
        local q = Q(chr).queue
        -- (the game's milking keeps its animal and the container it is filling, as ISMilkAnimal does)
        local m = action("ISMilkAnimal")
        m.animal, m.bucket = animal, bucket
        q[#q + 1] = action("ISWalkToTimedActionF"); q[#q + 1] = m
    end,
    onShearAnimal = function(animal, chr, shear)
        rec("shear:" .. animal._name .. ":" .. tostring(shear and shear._name))
        animal._blocked = true
        local q = Q(chr).queue
        q[#q + 1] = action("ISWalkToTimedActionF"); q[#q + 1] = action("ISShearAnimal")
    end,
    onFeedAnimalFood = function(chr, animal, food)
        rec("feed:" .. animal._name .. ":" .. tostring(food and food._name) .. "#" .. tostring(food and food._id))
        animal._blocked = true
        local q = Q(chr).queue
        q[#q + 1] = action("ISWalkToTimedAction"); q[#q + 1] = action("ISWalkToTimedActionF"); q[#q + 1] = action("ISFeedAnimalFromHand")
    end,
}
-- the game's fluids: Fluid.Get by the milk's name, and any animal milk
Fluid = { Get = function(name) return { _fluid = name } end, AnimalMilk = { _fluid = "AnimalMilk" } }
local WALK_OK = true
luautils = { walkAdj = function(p, sq) rec("walk:" .. tostring(sq and sq.id)); if WALK_OK then local q = Q(p).queue; q[#q + 1] = action("ISWalkToTimedAction") end return WALK_OK end }
-- the walks at the head of the queue reach their point: the game calls each one's onComplete, the next action starts
local function walkDone(p)
    local q = Q(p).queue
    while q[1] and (q[1].Type == "ISWalkToTimedAction" or q[1].Type == "ISWalkToTimedActionF") do
        local w = table.remove(q, 1)
        if w._onDone then w._onDone(w._arg) end
    end
end

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
        local l = L(a._eats)
        l.contains = function(_, k) for _, e in ipairs(a._eats) do if e == k then return true end end return false end
        return l
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
        -- the game's milking's own search when a container fills: the first that takes this milk (full or not),
        -- then every carried item of that one's full type
        getFirstAvailableFluidContainer = function(_, mt)
            for _, b in ipairs(p._buckets) do
                if not p._dropped[b] and (b._mt == nil or b._mt == mt) then return b end
            end
            return nil
        end,
        getItemsFromFullType = function(_, ft)
            local out = {}
            for _, b in ipairs(p._buckets) do
                if not p._dropped[b] and b._ft == ft then out[#out + 1] = b end
            end
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
-- a carried container: the milk it takes (nil: any), its full type (its kind: "Base." .. name unless given)
local function bucket(name, mt, ft)
    local b = { _name = name, _mt = mt, _ft = ft or ("Base." .. name) }
    b.getFullType = function() return b._ft end
    return b
end
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
check("SELECT band: Feed counts the four hungry to the game's menu (10 and up), greyed: nothing carried", v[1] and v[1].n == 4 and v[1].ok == false
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

-- SPEED (Nov 12 2026): the game drops every walk above speed 2 (WalkToTimedAction:isValid), so a run cut then says why
do
    ISTimedActionQueue.queues = {}
    local keepSpeed = getGameSpeed
    getGameSpeed = function() return 3 end
    local s1 = animal("S1", { milk = 4, milkable = true })
    local s2 = animal("S2", { milk = 4, milkable = true })
    CALLS = {}
    AQ.start(p, "milk", { s1, s2 })
    AQ.tick(); finishAction(p)   -- the game's walk was dropped at once: the queue is empty, S1 still has its milk
    for _ = 1, 10 do AQ.tick() end
    check("SPEED a run cut at speed 3 says why: RunFast 0 of 2", AQ.run == nil and AQ.last and AQ.last.why == "UI_ZeD_Animals_RunFast(0,2)",
        AQ.last and AQ.last.why)
    check("SPEED S1 let go", s1._blocked == false)
    ISTimedActionQueue.queues = {}
    AQ.start(p, "milk", { s2 })
    AQ.stop()
    check("SPEED a Stop the player asked for is a plain stop", AQ.last and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,1)", AQ.last and AQ.last.why)
    getGameSpeed = function() return 2 end
    ISTimedActionQueue.queues = {}
    AQ.start(p, "milk", { s2 })
    AQ.tick(); finishAction(p); for _ = 1, 10 do AQ.tick() end
    check("SPEED at speed 2 a cut is a plain stop", AQ.last and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,1)", AQ.last and AQ.last.why)
    getGameSpeed = keepSpeed
    ISTimedActionQueue.queues = {}
end

-- ERROR (Nov 12 2026): a step that throws ends the run in the tick hook's pcall; the animal under way is let go
do
    ISTimedActionQueue.queues = {}
    local x1 = animal("X1", { milk = 4, milkable = true })
    CALLS = {}
    AQ.start(p, "milk", { x1 })
    check("ERROR X1 is held for its milking", x1._blocked == true, x1._blocked)
    local keepDead = p.isDead
    p.isDead = function() error("boom") end
    local hook = next(hooks)
    local keepPrint = print
    print = function() end
    if hook then hook() end
    print = keepPrint
    p.isDead = keepDead
    check("ERROR the run is over and the hook off", AQ.run == nil and hookCount() == 0)
    check("ERROR X1 let go", x1._blocked == false, x1._blocked)
    check("ERROR the band says it stopped", AQ.last and AQ.last.cause == "error" and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,1)",
        AQ.last and AQ.last.why)
    ISTimedActionQueue.queues = {}
end

-- the bucket runs out (the only one fills on E1, milk left in it)
ISTimedActionQueue.queues = {}
local e1 = animal("E1", { milk = 9, milkable = true })
local e2 = animal("E2", { milk = 9, milkable = true })
local eb = bucket("EB")
eb._full = false
eb.getFluidContainer = function() return { isFull = function() return eb._full end } end
eb.getDisplayName = function() return "Bucket" end
p._buckets = { eb }
CALLS = {}
AQ.start(p, "milk", { e1, e2 })
AQ.tick(); eb._full = true; finishAction(p); AQ.tick()   -- the bucket filled: E1 keeps some milk, no room left
check("RUN the bucket full: E2 not handed over, Bucket full: milked 0 of 2",
    AQ.run == nil and #CALLS == 1 and AQ.last.why == "UI_ZeD_Animals_RunFull(Bucket,0,2)", AQ.last.why .. " " .. #CALLS)
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

-- the game's gates: its world menu offers Feed at 0.1 hunger (10 here), the trailer's menu too, the hands' at any
-- hunger; milk is drunk only past 0.1 hunger or thirst, compared in single precision (AnimalData.eatItem)
do
    local low = animal("Low", { hunger = 5, eats = { "Vegetables" } })
    check("FEED a cow at 5 hunger is not hungry to the game's world menu (its 0.1); at 10 it is",
        not AQ.wantsFood(low) and AQ.wantsFood(animal("Ten", { hunger = 10 })))
    local held = animal("Held", { hunger = 5 }); held.isExistInTheWorld = function() return false end
    local trailer = animal("Trailer", { hunger = 5 }); trailer.isExistInTheWorld = function() return false end
    trailer.getVehicle = function() return {} end
    check("FEED held in the hands: any hunger (the inventory menu); in a trailer: the trailer menu's 0.1",
        AQ.wantsFood(held) and not AQ.wantsFood(trailer))
    local fpG = player()
    fpG._food = { carrot(), carrot() }
    AQ.forgetChecks()
    local fvG = AQ.selectionVerbs(fpG, { low, animal("Mid", { hunger = 30, eats = { "Vegetables" } }) })
    check("FEED band: Feed (1), the cow at 5 not counted", fvG[1] and fvG[1].id == "feed" and fvG[1].n == 1, fvG[1] and fvG[1].n)
    -- milk: a calf held in the hands at 5 hunger and 5 thirst drinks none; thirsty, it drinks
    local jug = item("Milk bottle", "Base.WaterBottle", { fluid = "CowMilk", fluidName = "Cow Milk" })
    local calfH = animal("CalfH", { hunger = 5, eats = { "CowMilk" } }); calfH.isExistInTheWorld = function() return false end
    calfH._thirst = 5
    local noDrink = AQ.eats(calfH, jug)
    calfH._thirst = 20
    check("FEED milk: a calf at 5 hunger and 5 thirst drinks none; at 20 thirst it drinks", not noDrink and AQ.eats(calfH, jug))
    -- exactly the game's 0.1 in single precision (0.1000000015): Feed offered, the milk not drunk, a carrot eaten
    local edge = animal("Edge", { hunger = 0.100000001490116119384765625 * 100, eats = { "CowMilk", "Vegetables" } })
    check("FEED at exactly 0.1 hunger: hungry to the menu, no milk (drunk only past 0.1), a carrot still",
        AQ.wantsFood(edge) and not AQ.eats(edge, jug) and AQ.eats(edge, carrot()))
    -- the run: milk goes only to a calf that will drink it; the one at 5 is no part of it
    local calfLow = animal("CalfLow", { hunger = 5, eats = { "CowMilk" } })
    local calfHi = animal("CalfHi", { hunger = 60, eats = { "CowMilk" } })
    fpG._food = { item("Milk bottle", "Base.WaterBottle", { fluid = "CowMilk", fluidName = "Cow Milk" }) }
    ISTimedActionQueue.queues = {}
    CALLS = {}
    local okG = AQ.start(fpG, "feed", { calfLow, calfHi }, "Cow Milk")
    check("FEED run: milk only for the calf that will drink it (CalfHi first, one to do)",
        okG and AQ.run ~= nil and #AQ.run.list == 1 and CALLS[1] ~= nil and CALLS[1]:find("feed:CalfHi:", 1, true) == 1,
        table.concat(CALLS, " "))
    AQ.stop()
    ISTimedActionQueue.queues = {}
end

-- PERF ------------------------------------------------------------------------
-- The feed tests read each carried item and each animal once and match them in Lua: 20 carried things and 10 hungry
-- cows cost 10 eat lists and a handful of reads per item, not a round of Java calls per item per cow (the band asks
-- every half second).
do
    local fpP = player()
    local reads, lists = 0, 0
    local function counted(it)
        for k, f in pairs(it) do
            if type(f) == "function" then it[k] = function(...) reads = reads + 1; return f(...) end end
        end
        return it
    end
    for _ = 1, 10 do fpP._food[#fpP._food + 1] = counted(carrot()) end
    for _ = 1, 10 do fpP._food[#fpP._food + 1] = counted(item("Hay", "Base.HayTuft", { feed = "Hay" })) end
    local cows = {}
    for i = 1, 10 do
        local c = animal("PCow" .. i, { hunger = 60, eats = { "Vegetables", "Hay" } })
        local get = c.getEatTypePossibleFromHand
        c.getEatTypePossibleFromHand = function(...) lists = lists + 1; return get(...) end
        cows[i] = c
    end
    AQ.forgetChecks()
    local foodsP, _, nP = AQ.feedChoices(fpP, cows)
    check("PERF feed choices: each cow's eat list read once (10), not once per item", lists == 10, lists)
    check("PERF feed choices: 20 items read at most 12 times each, not once per cow", reads <= 20 * 12, reads)
    check("PERF the same answer: Carrot and Hay, each for all 10, 10 carried each",
        #foodsP == 2 and foodsP[1].suits == 10 and foodsP[2].suits == 10 and foodsP[1].have == 10 and nP == 10)
end

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
    walkDone(pa); AQ.tick()   -- (the walk to the cow's side is over: the milking is under way)
    pa._x, pa._y = 16, 16
    AQ.tick()
    check("AWAY moved 16 squares off mid-milking: the run stops, Stopped after 0 of 2",
        AQ.run == nil and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,2)", AQ.last and AQ.last.why)
    check("AWAY nothing left queued, G1 let go", #ISTimedActionQueue.queues[pa].queue == 0 and g1._blocked == false
        and table.concat(CALLS, " "):find("clear", 1, true) ~= nil, table.concat(CALLS, " "))
    check("AWAY the tick hook is off", hookCount() == 0)

    -- walking up from afar is no walk-off: the distance counts from where the walk ends
    pa._x, pa._y = 20, 0
    g1._milk = 5
    ISTimedActionQueue.queues = {}
    AQ.start(pa, "milk", { g1 })
    for x = 19, 2, -1 do pa._x = x; AQ.tick() end
    check("AWAY walking up 20 squares: the run goes on", AQ.run ~= nil)
    walkDone(pa); AQ.tick()
    pa._x = 9
    AQ.tick()
    check("AWAY 8 squares off after the walk ended 1 off: still within the margin", AQ.run ~= nil)
    pa._x = 11
    AQ.tick()
    check("AWAY 10 squares off after the walk ended 1 off: stopped", AQ.run == nil)

    -- the walk to the cow's side goes round a wall to the door: 10 squares and more off on the way is no walk-off
    -- (the walk ends itself on a stick move or a failed path); the milking after it is measured from where it ended
    pa._x, pa._y = 0, 0
    g2._milk = 5
    ISTimedActionQueue.queues = {}
    AQ.start(pa, "milk", { g2 })
    for _, xy in ipairs({ { -3, 0 }, { -6, 0 }, { -8, 0 }, { -8, 6 }, { -2, 6 }, { 3, 4 }, { 3, 1 } }) do
        pa._x, pa._y = xy[1], xy[2]; AQ.tick()
    end
    check("AWAY the walk detours round a wall, 10 to 12 squares off on the way: the run goes on", AQ.run ~= nil,
        AQ.last and AQ.last.cause)
    walkDone(pa); pa._x, pa._y = 3, 0; AQ.tick()
    pa._x, pa._y = 16, 16
    AQ.tick()
    check("AWAY then moved 16 squares off mid-milking: stopped", AQ.run == nil and AQ.last.cause == "away", AQ.last and AQ.last.cause)

    -- a stuck queue: actions in it, none running
    pa._x, pa._y = 0, 0
    g1._milk = 5
    ISTimedActionQueue.queues = {}
    AQ.start(pa, "milk", { g1 })
    STUCK = true
    for _ = 1, AQ.STALL_TICKS do AQ.tick() end
    check("AWAY a stuck queue is given STALL_TICKS ticks", AQ.run ~= nil)
    AQ.tick()
    check("AWAY then the run stops and clears it", AQ.run == nil and #ISTimedActionQueue.queues[pa].queue == 0 and g1._blocked == false)
    STUCK = false

    -- too long: WAIT_MS of the game running on one animal. No tick fires while the game is paused, so a gap in the
    -- ticks is the pause and does not count.
    g1._milk = 5
    ISTimedActionQueue.queues = {}
    AQ.start(pa, "milk", { g1 })
    AQ.tick()
    NOW = NOW + AQ.WAIT_MS + 1
    AQ.tick()
    check("AWAY the game paused past WAIT_MS mid-milking: the run goes on", AQ.run ~= nil, AQ.last and AQ.last.cause)
    local nT = 0
    while AQ.run and nT < 5000 do NOW = NOW + 100; AQ.tick(); nT = nT + 1 end
    check("AWAY one animal past WAIT_MS of the game running: stopped, cleared", AQ.run == nil and AQ.last.cause == "slow"
        and nT >= AQ.WAIT_MS / 100 and #ISTimedActionQueue.queues[pa].queue == 0, nT)
    ISTimedActionQueue.queues = {}
end

-- WANDER ----------------------------------------------------------------------
-- An animal off screen is walked up to first. It is held still from the press, as the game's own menu holds the
-- animal it picks; a walk that reached its square hands the act over wherever the animal stands now (the game's
-- handler walks to its side); only a walk cut short far off is a stop. Every way out lets the animal go.
do
    local pw = player()
    pw._x, pw._y = 0, 0
    pw.getX = function() return pw._x end
    pw.getY = function() return pw._y end
    pw._buckets = { bucket("BW") }
    local function placed(name)
        local a = animal(name, { milk = 5, milkable = true })
        a._x, a._y, a._far = 20, 0, true
        a.getX = function() return a._x end
        a.getY = function() return a._y end
        return a
    end
    local cowW = placed("CowW")
    ISTimedActionQueue.queues = {}
    CALLS = {}
    AQ.start(pw, "milk", { cowW })
    check("WANDER the walk up holds the animal still from the press", CALLS[1] == "walk:CowW@sq" and cowW._blocked == true,
        tostring(cowW._blocked))
    -- the walk reaches its square beside where the cow stood; the cow is 6 squares on by then
    AQ.tick(); pw._x = 19; cowW._x = 25; cowW._far = false; walkDone(pw); AQ.tick()
    check("WANDER a walk that reached its square hands the act over with the animal 6 squares off, not cut",
        AQ.run ~= nil and CALLS[2] == "milk:CowW:BW:true", table.concat(CALLS, " ") .. " " .. tostring(AQ.last and AQ.last.cause))
    AQ.stop()
    -- the walk cut short 12 squares off (a stick move): a stop, the animal let go
    local cowX = placed("CowX")
    pw._x = 0
    ISTimedActionQueue.queues = {}
    AQ.start(pw, "milk", { cowX })
    AQ.tick(); pw._x = 8; finishAction(pw); AQ.tick()
    check("WANDER a walk cut short far off: Stopped, the animal let go", AQ.run == nil and AQ.last.cause == "cut"
        and cowX._blocked == false, AQ.last and AQ.last.cause)
    -- reached, and still not drawn: out of reach, the animal let go
    local cowY = placed("CowY")
    pw._x = 0
    ISTimedActionQueue.queues = {}
    AQ.start(pw, "milk", { cowY })
    AQ.tick(); pw._x = 19; walkDone(pw); AQ.tick()
    check("WANDER reached but still not drawn: Out of reach, the queue cleared, the animal let go", AQ.run == nil
        and AQ.last.cause == "reach" and cowY._blocked == false and #ISTimedActionQueue.queues[pw].queue == 0,
        AQ.last and tostring(AQ.last.cause) .. " " .. tostring(cowY._blocked))
    ISTimedActionQueue.queues = {}
end

-- REPLACE ---------------------------------------------------------------------
-- An alert's Milk pressed while a bulk run is milking: the run under way gives way (the game's queue cleared, its
-- animal let go) and the new act starts on an empty queue, not behind a milking that empties the queue as it ends.
do
    local pr = player()
    pr._buckets = { bucket("BR") }
    local rp1 = animal("Rp1", { milk = 6, milkable = true })
    local rp2 = animal("Rp2", { milk = 6, milkable = true })
    local rp3 = animal("Rp3", { milk = 6, milkable = true })
    ISTimedActionQueue.queues = {}
    AQ.forgetChecks()
    CALLS = {}
    AQ.start(pr, "milk", { rp1, rp2, rp3 })
    AQ.tick(); walkDone(pr); AQ.tick()   -- (Rp1's milking under way)
    local okR = AQ.start(pr, "milk", { rp3 })
    local qR = ISTimedActionQueue.queues[pr].queue
    check("REPLACE a press mid-run clears the game's queue before the new act and lets the old animal go",
        okR and CALLS[2] == "clear" and CALLS[3] == "milk:Rp3:BR:true" and rp1._blocked == false, table.concat(CALLS, " "))
    check("REPLACE the queue holds only the new act (its walk, its milking); the run is the new one",
        #qR == 2 and qR[2].Type == "ISMilkAnimal" and AQ.run ~= nil and #AQ.run.list == 1 and AQ.run.list[1] == rp3, #qR)
    AQ.stop()
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
    check("CAUSE the container gone from the list but not full (milk left): a stop",
        AQ.run == nil and AQ.last.done == 0 and AQ.last.cause == "undone", AQ.last and tostring(AQ.last.cause))
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
-- ones. The last container filling partway through a run is no Done: the run ends "Bucket full: milked 1 of 2". With
-- another container carried the run goes on with it.
do
    local function fluidBucket(name, full)
        local b = bucket(name)
        b._full = full
        b.getFluidContainer = function() return { isFull = function() return b._full end } end
        b.getDisplayName = function() return name end
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
    check("FULL the only bucket full on the second (milk left): Bucket full: milked 1 of 2, not Done",
        AQ.run == nil and AQ.last.done == 1 and AQ.last.cause == "full" and AQ.last.why == "UI_ZeD_Animals_RunFull(B10,1,2)",
        AQ.last and tostring(AQ.last.cause) .. " " .. tostring(AQ.last.why))
    check("FULL K2 let go", k2._blocked == false)
    -- the bucket fills exactly as the first cow runs dry: the second is not handed over, the same words
    local m1 = animal("M1", { milk = 8, milkable = true })
    local m2 = animal("M2", { milk = 8, milkable = true })
    local bA = fluidBucket("BA", false)
    pf._buckets = { bA }
    ISTimedActionQueue.queues = {}
    CALLS = {}
    AQ.start(pf, "milk", { m1, m2 })
    AQ.tick(); m1._milk = 0; bA._full = true; finishAction(pf); AQ.tick()
    check("FULL the bucket full as the first runs dry: milked 1 of 2, the second never handed over",
        AQ.run == nil and #CALLS == 1 and AQ.last.cause == "full" and AQ.last.why == "UI_ZeD_Animals_RunFull(BA,1,2)",
        AQ.last and tostring(AQ.last.why))
    -- a second container carried: the run moves on to it and milks both
    local n1 = animal("N1", { milk = 8, milkable = true })
    local n2 = animal("N2", { milk = 8, milkable = true })
    local bB, bC = fluidBucket("BB", false), fluidBucket("BC", false)
    pf._buckets = { bB, bC }
    ISTimedActionQueue.queues = {}
    CALLS = {}
    AQ.start(pf, "milk", { n1, n2 })
    AQ.tick(); n1._milk = 0; bB._full = true; finishAction(pf); AQ.tick()
    check("FULL another container carried: the second cow is milked into it", CALLS[2] == "milk:N2:BC:true", table.concat(CALLS, " "))
    AQ.tick(); n2._milk = 0; finishAction(pf); AQ.tick()
    check("FULL then Done 2 of 2", AQ.run == nil and AQ.last.cause == "done" and AQ.last.done == 2, AQ.last and AQ.last.cause)
    -- the bucket fills with milk left in the cow and a pot is carried: the game's milking moves on only to another of
    -- the same kind (its getFirstAvailableFluidContainer hands back the full bucket), so it stops; the run hands the
    -- cow over again with the pot and goes on, and the pot full in its turn ends it "Pot full"
    local o1 = animal("O1", { milk = 20, milkable = true })
    local o2 = animal("O2", { milk = 20, milkable = true })
    local bO, potO = fluidBucket("Bucket", false), fluidBucket("Pot", false)
    pf._buckets = { bO, potO }
    ISTimedActionQueue.queues = {}
    CALLS = {}
    AQ.start(pf, "milk", { o1, o2 })
    AQ.tick(); o1._milk = 10; bO._full = true; finishAction(pf); AQ.tick()
    check("FULL the bucket full with milk left and a pot carried: the cow handed over again with the pot, not Stopped",
        AQ.run ~= nil and CALLS[2] == "milk:O1:Pot:true" and AQ.run.done == 0,
        table.concat(CALLS, " ") .. " " .. tostring(AQ.last and AQ.last.why))
    AQ.tick(); o1._milk = 0; finishAction(pf); AQ.tick()
    check("FULL then the next cow, into the pot", CALLS[3] == "milk:O2:Pot:true", table.concat(CALLS, " "))
    AQ.tick(); potO._full = true; finishAction(pf); AQ.tick()
    check("FULL the pot full in its turn, nothing left with room: Pot full: milked 1 of 2",
        AQ.run == nil and AQ.last.cause == "full" and AQ.last.why == "UI_ZeD_Animals_RunFull(Pot,1,2)", AQ.last and tostring(AQ.last.why))
    ISTimedActionQueue.queues = {}
end

-- SWITCH ----------------------------------------------------------------------
-- The game's milking with "all" moves on by itself when a container fills (ISMilkAnimal.milk): the first carried
-- container for this milk, full or not, then the first of that one's kind with room. A milking cut short after it
-- moved on (a movement key, a cancel, an alert's Walk to) leaves the bucket handed over full, but the game had room to
-- go on: a stop, never a second hand-over that walks the player back. Only a milking that ran out of room refills.
do
    local function kind(name, ft)
        local b = bucket(name, nil, ft)
        b._full = false
        b.getFluidContainer = function() return { isFull = function() return b._full end } end
        b.getDisplayName = function() return name end
        return b
    end
    -- the game's milking (at the head of the queue once the walk is over) moves on to another container
    local function movesOn(pl, b)
        local m = ISTimedActionQueue.queues[pl].queue[1]
        if m and m.Type == "ISMilkAnimal" then m.bucket = b end
    end
    local function placedAt(a, x, y) a.getX = function() return x end; a.getY = function() return y end; return a end
    -- (each case starts with no run left from the one before, an empty queue and no calls)
    local function fresh()
        if AQ.run then AQ.stop() end
        ISTimedActionQueue.queues = {}
        AQ.forgetChecks()
        CALLS = {}
    end
    local other = animal("Other", { hunger = 60 })

    -- a movement key after the game moved on from bucket A (full) to bucket B, 10 L still in the cow
    local ps = player()
    local sA, sB = kind("Bucket A", "Base.Bucket"), kind("Bucket B", "Base.Bucket")
    ps._buckets = { sA, sB }
    local sw1 = animal("Sw1", { milk = 25, milkable = true })
    local sw2 = animal("Sw2", { milk = 25, milkable = true })
    fresh()
    AQ.start(ps, "milk", { sw1, sw2 })
    AQ.tick(); walkDone(ps); AQ.tick()
    sA._full = true; movesOn(ps, sB); sw1._milk = 10
    finishAction(ps)   -- (the game's own cancel empties the queue)
    AQ.tick()
    check("SWITCH cancel after the switch: Stopped after 0 of 2, no second hand-over",
        AQ.run == nil and #CALLS == 1 and AQ.last.cause == "undone" and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,2)",
        table.concat(CALLS, " ") .. " " .. tostring(AQ.last and AQ.last.why))
    check("SWITCH cancel after the switch: the cow let go", sw1._blocked == false)

    -- the cancel lands just as bucket A filled, before the game's next pull moved on to B
    sA._full, sw1._milk = false, 25
    fresh()
    AQ.start(ps, "milk", { sw1 })
    AQ.tick(); walkDone(ps); AQ.tick()
    sA._full = true; sw1._milk = 15
    finishAction(ps)
    AQ.tick()
    check("SWITCH cancel just as bucket A filled, the game not yet moved on: Stopped, no second hand-over",
        AQ.run == nil and #CALLS == 1 and AQ.last.cause == "undone", table.concat(CALLS, " "))

    -- an alert's Walk to after the switch: the game's walkAdj empties the queue (the milking stops) and walks off
    local pw = player()
    pw._x, pw._y = 1, 0
    pw.getX = function() return pw._x end
    pw.getY = function() return pw._y end
    local wA, wB = kind("Bucket A", "Base.Bucket"), kind("Bucket B", "Base.Bucket")
    pw._buckets = { wA, wB }
    local cowT = placedAt(animal("WalkCow", { milk = 25, milkable = true }), 0, 0)
    fresh()
    AQ.start(pw, "milk", { cowT })
    AQ.tick(); walkDone(pw); AQ.tick()
    wA._full = true; movesOn(pw, wB); cowT._milk = 10
    ISTimedActionQueue.queues[pw].queue = {}
    AQ.act("goto", pw, other)
    for x = 2, 15 do pw._x = x; AQ.tick() end
    check("SWITCH the alert's walk under way: the run waits for it", AQ.run ~= nil)
    walkDone(pw); AQ.tick()
    local joinedW = table.concat(CALLS, " ")
    check("SWITCH Walk to after the switch: Stopped after 0 of 1 where the walk ended, the cow not handed over again",
        AQ.run == nil and AQ.last.cause == "undone" and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,1)"
        and joinedW == "milk:WalkCow:Bucket A:true walk:Other@sq" and #ISTimedActionQueue.queues[pw].queue == 0,
        joinedW .. " " .. tostring(AQ.last and AQ.last.cause))

    -- the stressed cow kicks bucket B, the one the game moved on to, out of the hands; a pot is still carried
    local pk = player()
    local kA, kB, kPot = kind("Bucket A", "Base.Bucket"), kind("Bucket B", "Base.Bucket"), kind("Pot", "Base.Pot")
    pk._buckets = { kA, kB, kPot }
    local cowK = animal("KickCow", { milk = 25, milkable = true })
    fresh()
    AQ.start(pk, "milk", { cowK })
    AQ.tick(); walkDone(pk); AQ.tick()
    kA._full = true; movesOn(pk, kB); cowK._milk = 12
    pk._dropped[kB] = true; pk._buckets = { kA, kPot }
    finishAction(pk); AQ.tick()
    check("SWITCH the bucket the game moved on to kicked away, a pot carried: Stopped, not handed over again with the pot",
        AQ.run == nil and #CALLS == 1 and AQ.last.cause == "undone", table.concat(CALLS, " "))

    -- out of room: both buckets full (the game's last search names bucket A and stops), a pot carried
    local pd = player()
    local dA, dB, dPot = kind("Bucket A", "Base.Bucket"), kind("Bucket B", "Base.Bucket"), kind("Pot", "Base.Pot")
    pd._buckets = { dA, dB, dPot }
    local cowD = animal("DoneCow", { milk = 25, milkable = true })
    fresh()
    AQ.start(pd, "milk", { cowD })
    AQ.tick(); walkDone(pd); AQ.tick()
    dA._full, dB._full, cowD._milk = true, true, 5
    finishAction(pd); AQ.tick()
    check("SWITCH both buckets of the kind full, the game out of room, a pot carried: the cow handed over again with the pot",
        AQ.run ~= nil and CALLS[2] == "milk:DoneCow:Pot:true" and AQ.run.done == 0, table.concat(CALLS, " "))

    -- the game's search starts at the first container for this milk: a full pot carried ahead of the buckets stops it
    -- when bucket A fills though bucket B has room, and the run hands the cow over again with bucket B
    local po = player()
    local oPot, oA, oB = kind("Pot", "Base.Pot"), kind("Bucket A", "Base.Bucket"), kind("Bucket B", "Base.Bucket")
    oPot._full = true
    po._buckets = { oPot, oA, oB }
    local cowO = animal("OrderCow", { milk = 25, milkable = true })
    fresh()
    AQ.start(po, "milk", { cowO })
    AQ.tick(); walkDone(po); AQ.tick()
    oA._full = true; movesOn(po, oPot); cowO._milk = 15
    finishAction(po); AQ.tick()
    check("SWITCH a full pot ahead of the buckets: the game stops when bucket A fills, the cow handed over again with bucket B",
        CALLS[1] == "milk:OrderCow:Bucket A:true" and CALLS[2] == "milk:OrderCow:Bucket B:true" and AQ.run ~= nil,
        table.concat(CALLS, " "))

    -- an alert's Walk to during the walk up to a far cow: the walk up stops short, far off
    local pu = player()
    pu._x, pu._y = 0, 0
    pu.getX = function() return pu._x end
    pu.getY = function() return pu._y end
    pu._buckets = { kind("Bucket U", "Base.Bucket") }
    local farU = placedAt(animal("FarU", { milk = 8, milkable = true }), 20, 0)
    farU._far = true
    fresh()
    AQ.start(pu, "milk", { farU })
    AQ.tick()
    ISTimedActionQueue.queues[pu].queue = {}
    AQ.act("goto", pu, other)
    pu._x = -5; walkDone(pu); AQ.tick()
    local joinedU = table.concat(CALLS, " ")
    check("SWITCH Walk to during the walk up to a far cow: Stopped after 0 of 1 (cut), nothing handed over, the cow let go",
        AQ.run == nil and AQ.last.cause == "cut" and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,1)"
        and joinedU == "walk:FarU@sq walk:Other@sq" and farU._blocked == false, joinedU .. " " .. tostring(AQ.last and AQ.last.cause))
    fresh()
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

    -- (from zedqa_animals_list.lua) the cell's list against the old walk of the squares: 75 squares around the
    -- player on the player's floor (stairs give a fractional z), the wild left out; no zones; a refresh in 8 ms
    local seed, herd = 7, {}
    local function rnd(n) seed = (seed * 1103515245 + 12345) % 2147483648; return seed % n end
    for k = 1, 600 do
        local a = placed("H" .. k, 1000 + rnd(241) - 120, 2000 + rnd(241) - 120)
        local z = ({ 0, 0, 0, 1, 0.5, 2 })[rnd(6) + 1]
        a.getZ = function() return z end
        a._wild = rnd(9) == 0
        herd[k] = a
    end
    local walk = 0
    for x = 1000 - 75, 1000 + 75 do for y = 2000 - 75, 2000 + 75 do
        for _, a in ipairs(herd) do
            if a._x == x and a._y == y and math.floor(a.getZ()) == 0 and not a._wild then walk = walk + 1 end
        end
    end end
    cellList = herd
    me.getCurrentSquare = function() return { getX = function() return 1000 end, getY = function() return 2000 end,
                                              getZ = function() return 0 end } end
    DesignationZoneAnimal = { getAllZones = function() return L({}) end }
    local c0 = os.clock()
    AP.refreshCache()
    local ms = (os.clock() - c0) * 1000
    check("ZONES the poller's count matches a 75-square walk of the player's floor (" .. walk .. ")",
        walk > 50 and #AP.getAllAnimals() == walk and AP.getTotals().totalAnimals == walk, #AP.getAllAnimals())
    check("ZONES one refresh over 600 animals stays under 8 ms", ms < 8, string.format("%.2f ms", ms))
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

-- LEAD (Nov 13 2026, QA 169 on a farm: Shear and Feed "Stopped after 0 of 1", the wool and the hunger unchanged).
-- The game's handlers queue lead actions before the act itself: the walk beside it, then the shears or the food to
-- hand (ISEquipWeaponAction). The run waits through every one of them, longer than its start grace and its stall
-- count, and decides only once the queue is empty. When the queue empties with the act never begun (the game dropped
-- it on the way), the run is a stop that keeps which lead step was last (AQ.last.began false, AQ.last.lead) and says
-- so on the console; one whose act ran keeps began true.
do
    local keepShear, keepFeed = AnimalContextMenu.onShearAnimal, AnimalContextMenu.onFeedAnimalFood
    AnimalContextMenu.onShearAnimal = function(an, chr, sh)
        rec("shear:" .. an._name)
        local q = Q(chr).queue
        local s = action("ISShearAnimal"); s.animal = an
        q[#q + 1] = action("ISWalkToTimedActionF"); q[#q + 1] = action("ISEquipWeaponAction"); q[#q + 1] = s
    end
    AnimalContextMenu.onFeedAnimalFood = function(chr, an, food)
        rec("feed:" .. an._name)
        local q = Q(chr).queue
        local f = action("ISFeedAnimalFromHand"); f.animal = an
        q[#q + 1] = action("ISWalkToTimedAction"); q[#q + 1] = action("ISWalkToTimedActionF")
        q[#q + 1] = action("ISEquipWeaponAction"); q[#q + 1] = f
    end
    local pl = player()
    pl._shears = { shears("Manual") }
    local ram = animal("RamL", { wool = 5, shearable = true })
    ISTimedActionQueue.queues = {}
    AQ.forgetChecks()
    CALLS = {}
    AQ.start(pl, "shear", { ram })
    for _ = 1, 5 do AQ.tick() end
    walkDone(pl)
    for _ = 1, AQ.START_GRACE + AQ.STALL_TICKS + 10 do AQ.tick() end
    check("LEAD shear: the run waits through the walk and the shears to hand", AQ.run ~= nil and #CALLS == 1,
        AQ.last and AQ.last.cause)
    table.remove(Q(pl).queue, 1)
    AQ.tick()
    ram._wool = 0.5; Q(pl).queue = {}; AQ.tick()
    check("LEAD shear: the shearing ran and took the wool: Done 1 of 1, the act began",
        AQ.run == nil and AQ.last.cause == "done" and AQ.last.began == true, AQ.last and tostring(AQ.last.cause) .. " " .. tostring(AQ.last.began))

    ram._wool = 5
    ISTimedActionQueue.queues = {}
    CALLS = {}
    AQ.start(pl, "shear", { ram })
    AQ.tick(); walkDone(pl); AQ.tick()
    Q(pl).queue = {}
    AQ.tick()
    check("LEAD shear: dropped while the shears went to hand: a stop that keeps the act never began and the last step",
        AQ.run == nil and AQ.last.why == "UI_ZeD_Animals_RunStopped(0,1)" and AQ.last.began == false
        and AQ.last.lead == "ISEquipWeaponAction" and ram._blocked == false,
        AQ.last and tostring(AQ.last.began) .. " " .. tostring(AQ.last.lead))

    local fl = player()
    fl._food = { carrot() }
    local cowL = animal("CowL", { hunger = 90, eats = { "Vegetables" } })
    ISTimedActionQueue.queues = {}
    AQ.forgetChecks()
    CALLS = {}
    AQ.start(fl, "feed", { cowL }, "Carrot")
    AQ.tick(); walkDone(fl)
    for _ = 1, AQ.START_GRACE + AQ.STALL_TICKS + 10 do AQ.tick() end
    check("LEAD feed: the run waits through both walks and the food to hand", AQ.run ~= nil and #CALLS == 1, AQ.last and AQ.last.cause)
    table.remove(Q(fl).queue, 1)
    AQ.tick()
    cowL._hunger = 50; Q(fl).queue = {}; AQ.tick()
    check("LEAD feed: the feeding ran: Done 1 of 1, the act began", AQ.run == nil and AQ.last.cause == "done" and AQ.last.began == true,
        AQ.last and tostring(AQ.last.cause))

    cowL._hunger = 90
    fl._food = { carrot() }
    ISTimedActionQueue.queues = {}
    AQ.forgetChecks()
    AQ.start(fl, "feed", { cowL }, "Carrot")
    AQ.tick()
    Q(fl).queue = {}
    AQ.tick()
    check("LEAD feed: dropped on the first walk: a stop, the act never began, the walk the last step",
        AQ.run == nil and AQ.last.began == false and AQ.last.lead == "ISWalkToTimedAction",
        AQ.last and tostring(AQ.last.began) .. " " .. tostring(AQ.last.lead))
    AnimalContextMenu.onShearAnimal, AnimalContextMenu.onFeedAnimalFood = keepShear, keepFeed
    ISTimedActionQueue.queues = {}
end

-- SQUARE (Nov 13 2026, QA 169: an alert's Walk to queued nothing): the walk goes to the square the animal stands on
-- now, read from its position. Its getSquare() is the square its own last update left it on, so one just moved names
-- the old one (there, beside the player, the game does no walk at all). An animal whose position has no loaded square
-- falls back to getSquare().
do
    local keepCell = getCell
    getCell = function()
        return { getGridSquare = function(_, x, y, z) return { id = "pos:" .. x .. "," .. y .. "," .. z } end }
    end
    local pw = player()
    local moved = animal("Moved", { hunger = 90 })
    moved._sq = { id = "Moved@old" }
    moved.getX = function() return 1571.5 end
    moved.getY = function() return 14334.5 end
    moved.getZ = function() return 0 end
    ISTimedActionQueue.queues = {}
    CALLS = {}
    ok = AQ.act("goto", pw, moved)
    check("SQUARE Walk to goes to the square at the animal's position, not the one its last update left",
        ok and CALLS[1] == "walk:pos:1571,14334,0", CALLS[1])
    getCell = function() return { getGridSquare = function() return nil end } end
    CALLS = {}
    AQ.act("goto", pw, moved)
    check("SQUARE no loaded square at its position: its own square", CALLS[1] == "walk:Moved@old", CALLS[1])
    getCell = keepCell
    ISTimedActionQueue.queues = {}
end

-- PADWHY (Nov 13 2026, QA 169 aq2 b): a greyed band button's reason shows at once for the controller's focus, which
-- shows only after a pad press reaches the window (FocusManager _showCues). The QA script's focusOn moved the focus
-- with no press (claimFocus does nothing to a window that already holds the claim), so the balloon was never asked;
-- it presses a button bound to nothing after the move, as zedqa_cohesion_walk.lua's padTouch does.
do
    local AQ2 = readFile(ROOT .. "ZeDUI/tools/qa/zedqa_animals_quick_more.lua")
    check("PADWHY the aq2 script's focusOn presses the pad after the move",
        AQ2:find('if z then Focus.focusWhere(W(), z.zone, function(e) return e.id == id end) end\n    pcall(Focus.dispatchJoypadDown, W(), "QA")', 1, true) ~= nil)
    local TABW = readFile(Z .. "AnimalsTab.lua")
    check("PADWHY the band asks the reason balloon at once while its button has the focus",
        TABW:find("whyBalloon(panel, win, bulkId(spec.id), spec.label, spec.why, rect, on)", 1, true) ~= nil
        and TABW:find("ZeD.Atoms.requestDetailCard(win, key, c, panel, rect, focused and _nowOpts or nil)", 1, true) ~= nil)
end

-- ZONEPAGE (Nov 13 2026, the director's eye, QA at 4K 1.75x): a zone with 8 feeding troughs drew its fifth trough
-- straight over the tab band's "Milking 1 of 2" and Stop. The hutches and troughs were pinned under the info band and
-- not clipped. Now everything under the info band (the structures, the Animals head with Sort and Help, the animal
-- rows) scrolls as one region from under the info band to the bottom of the content area. This cuts the zone page's
-- real functions out of AnimalsTab.lua, draws it over a fake panel that notes every part drawn and the clip it was
-- drawn under, and checks no part shows outside the region. (Run on the old file, the troughs fail.)
do
    local SRC = readFile(Z .. "AnimalsTab.lua")
    local function cutOpt(from)
        local a = SRC:find(from, 1, true)
        if not a then return "" end
        local _, b = SRC:find("\nend\n", a, true)
        return SRC:sub(a, b)
    end
    local parts = {
        SRC:match("\n(local AROW_H%s*= %d+)") or "", SRC:match("\n(local STRUCT_H = %d+)") or "",
        SRC:match("\n(local ZCAT_H = %d+)") or "",
        cutOpt("local function zoneClipHas("), cutOpt("local function zoneStructGroups("),
        cutOpt("local function zoneStructsLayout("), cutOpt("local function drawZoneStructs("),
        cutOpt("local function zoneBodyFocusSpan("), cutOpt("local function drawZoneRosterHead("),
        cutOpt("local function drawZoneBody("), cutOpt("local function renderRanchZone("),
    }
    local chunk = assert(loadstring(table.concat(parts, "\n") .. "\nreturn renderRanchZone"))

    local function px(u) return math.floor(u * 1.75 + 0.5) end
    local STRUCT = px(tonumber(SRC:match("\nlocal STRUCT_H = (%d+)")))
    local AROW = px(tonumber(SRC:match("\nlocal AROW_H%s*= (%d+)")))
    local BAND = 150            -- the zone info band's height
    local drawn, bar, LIVE = {}, nil, nil
    local SUMMARY, ANIMALS = nil, nil
    local panel = { clip = nil }
    function panel:setStencilRect(x, y, w, h) self.clip = { y = y, h = h } end
    function panel:clearStencilRect() self.clip = nil end
    function panel:getMouseX() return -9999 end
    function panel:getMouseY() return -9999 end
    function panel:drawRect() end
    local function rec(kind, y, h) drawn[#drawn + 1] = { kind = kind, y = y, h = h, clip = panel.clip } end
    local Z2 = {
        T = { px = px, sp = { scrollbarW = 14 }, buttonH = 40, hover = { r = 1, g = 1, b = 1, a = 0.1 } },
        Atoms = { mouseIn = function() return false end },
        Molecules = {
            getTabPad = function() return 10 end,
            drawCategoryRow = function(p, x, y, w, t, n, e, o) local h = (o and o.h) or px(15); rec("head", y, h); return h end,
            buttonW = function() return 120 end,
            drawButton = function(p, x, y, w, h) rec("sort", y, h); return x, y, w, h end,
            drawIconButton = function(p, x, y, s) rec("help", y, s); return x, y, s, s end,
            scrollBar = function(p, win, key, x, y, w, h, scroll, total) bar = { key = key, y = y, h = h, total = total } end,
        },
        tr = function(k) return k end, TM = {}, Focus = { mark = function() return false end },
        WorldRoutes = { zoneHelp = function() end },
    }
    local env = setmetatable({
        ZeD = Z2, getText = function(k) return k end,
        getState = function(win) return win._st end,
        getZoneViewState = function(win) return win._zs end,
        AD = function() return {} end,
        AP = function() return { isReady = function() return true end, refreshCache = function() end,
            getZoneSummary = function() return SUMMARY end, getAnimalsInZone = function() return ANIMALS end } end,
        WPN = function() return 0 end, getSpecificPlayer = function() return {} end,
        highlightZone = function() end, navigateBack = function() end,
        drawZoneInfoBand = function(p, win, x, y) rec("info", y, BAND); return BAND end,
        sortedRoster = function(zs, a) return a end,
        focusFor = function() return nil end, isOn = function() return false end, liveEl = function() return LIVE end,
        focusOpts = function() return nil end, help = function() end,
        drawAnimalRow = function(p, x, y) rec("animal", y, AROW); return AROW, { hover = false } end,
        animalRowModel = function() return {} end,
        QK = function() return { isSelected = function() return false end } end,
        zoneSelection = function() return {} end, SORT_LABELS = {},
        catRow = function(p, win, x, y) rec("cat", y, px(15)); return px(15) end,
        drawStructRow = function(p, win, x, y, w, kind, o, idx)
            rec("struct", y, STRUCT)
            win._animalsStructZones[#win._animalsStructZones + 1] = { x = x, y = y, w = w, h = STRUCT, kind = kind, idx = idx }
            return STRUCT
        end,
    }, { __index = _G })
    setfenv(chunk, env)
    local render = chunk()

    -- a short zone page: content from y 100, 500 tall; the info band takes 150, so the region is 350 (8 troughs need 506)
    local Y, H = 100, 500
    local TOP, BOT = Y + BAND, Y + H
    local function zone(nTroughs, nAnimals)
        local tr, an = {}, {}
        for i = 1, nTroughs do tr[i] = { name = "T" .. i } end
        for i = 1, nAnimals do an[i] = { name = "A" .. i } end
        SUMMARY, ANIMALS = { hutches = {}, troughs = tr }, an
    end
    local win = { _st = { zoneName = "QA Quick2" }, _zs = { sortMode = "name", scrollY = 0 } }
    local function draw()
        drawn, bar = {}, nil
        render(panel, win, 0, Y, 1617, H)
    end
    -- every part's shown piece (the part cut to its clip) lies inside the region; a part drawn with no clip must
    -- lie inside it whole
    local function allInside()
        for _, d in ipairs(drawn) do
            if d.kind ~= "info" then
                local a, b = d.y, d.y + d.h
                if d.clip then a, b = math.max(a, d.clip.y), math.min(b, d.clip.y + d.clip.h) end
                if b > a and (a < TOP or b > BOT) then return false, d.kind .. " " .. a .. ".." .. b end
            end
        end
        return true
    end
    local function zonesShown()
        local zs = {}
        for _, z in ipairs(win._animalsStructZones or {}) do zs[#zs + 1] = z end
        for _, z in ipairs(win._animalsRosterZones or {}) do zs[#zs + 1] = z end
        zs[#zs + 1] = win._animalsSortZone
        zs[#zs + 1] = win._animalsZoneHelpZone
        for _, z in ipairs(zs) do
            if z.y + z.h <= TOP or z.y >= BOT then return false, z.y end
        end
        return true
    end

    zone(8, 4)
    draw()
    local ok, why = allInside()
    check("ZONEPAGE 8 troughs, 4 animals: no trough, head or animal row shows over the tab band", ok, why)
    ok, why = zonesShown()
    check("ZONEPAGE only parts shown in the region take a press or the controller", ok, why)
    check("ZONEPAGE one bar for the region, from under the info band to the content's bottom",
        bar ~= nil and bar.key == "an:roster" and bar.y == TOP and bar.h == BOT - TOP,
        bar and (bar.y .. " " .. bar.h) or "no bar")
    check("ZONEPAGE the hidden troughs leave no zone", #(win._animalsStructZones or {}) < 8, #(win._animalsStructZones or {}))
    check("ZONEPAGE the wheel scrolls the region", win._animalsRosterScroll ~= nil and win._animalsRosterScroll.needsScroll
        and win._animalsRosterScroll.top == TOP and win._animalsRosterScroll.h == BOT - TOP)

    -- scrolled to the end: the last animal row sits on the region's bottom, the first trough is gone
    win._zs.scrollY = 100000
    draw()
    ok, why = allInside()
    local rz = win._animalsRosterZones or {}
    local last = rz[#rz]
    check("ZONEPAGE scrolled to the end: still inside, the last animal on the region's bottom",
        ok and last ~= nil and last.y + last.h == BOT, why or (last and (last.y + last.h)))
    local firstGone = true
    for _, z in ipairs(win._animalsStructZones or {}) do if z.idx == 1 then firstGone = false end end
    check("ZONEPAGE scrolled to the end: the first trough takes no press", firstGone)

    -- the controller on trough 8 from the top: the page follows it
    win._zs.scrollY = 0
    LIVE = { id = "animals:struct:trough:8", isStruct = true, structIdx = 8, kind = "trough" }
    draw()
    local t8 = nil
    for _, z in ipairs(win._animalsStructZones or {}) do if z.idx == 8 then t8 = z end end
    check("ZONEPAGE the controller on trough 8 brings it into view", t8 ~= nil and t8.y >= TOP and t8.y + t8.h <= BOT,
        t8 and t8.y)
    -- and on the last animal
    LIVE = { id = "animals:roster:1", isRoster = true, animal = ANIMALS[4] }
    draw()
    rz = win._animalsRosterZones or {}
    check("ZONEPAGE the controller on the last animal brings it into view",
        rz[#rz] ~= nil and rz[#rz].animal == ANIMALS[4] and rz[#rz].y + rz[#rz].h <= BOT)
    LIVE = nil

    -- a short zone that fits: no bar, and every part where the pinned page put it
    zone(1, 2)
    win._zs.scrollY = 0
    draw()
    ok = allInside()
    local s1 = (win._animalsStructZones or {})[1]
    local hy = TOP + px(15) + STRUCT
    check("ZONEPAGE a page that fits: no bar, the trough under its head, the Animals head and rows under it",
        ok and bar == nil and s1 ~= nil and s1.y == TOP + px(15) and win._animalsSortZone ~= nil
        and win._animalsSortZone.y == hy and #(win._animalsRosterZones or {}) == 2
        and win._animalsRosterZones[1].y == hy + 40)

    -- the clicks: a press is taken only inside the region
    check("ZONEPAGE presses on structures, Sort and Help are gated to the region",
        SRC:find("if win._animalsStructZones and inZoneBody then", 1, true) ~= nil
        and SRC:find("if inZoneBody and hitZone(win._animalsSortZone, x, y) then", 1, true) ~= nil
        and SRC:find("if inZoneBody and hitZone(win._animalsZoneHelpZone, x, y) then", 1, true) ~= nil)
end

-- SOURCE ----------------------------------------------------------------------
local TAB = readFile(Z .. "AnimalsTab.lua")
local WW = readFile(Z .. "ZeD_WorldWindow.lua")

-- RING (Nov 12 2026): the roster scrolls by whole rows, so its stops keep their count, ids and places while the
-- animals on them change; the ring is rebuilt then too (a pad X after a mouse scroll ticked the row's old animal)
do
    local a1 = WW:find("function ZeD_WorldWindow._tabSnapAnimals(", 1, true)
    local b1 = nil
    if a1 then _, b1 = WW:find("\nend\n", WW:find("function ZeD_WorldWindow._tabSnapDirty(", 1, true) or a1, true) end
    check("RING the snapshot keys on the animals (ZeD_WorldWindow._tabSnapAnimals / _tabSnapDirty)", a1 ~= nil and b1 ~= nil)
    if a1 and b1 then
        local env = setmetatable({ ZeD_WorldWindow = {} }, { __index = _G })
        local chunk = assert(loadstring(WW:sub(a1, b1)))
        setfenv(chunk, env)
        chunk()
        local WWs = env.ZeD_WorldWindow
        local A1, A2, A3, A4 = {}, {}, {}, {}
        local function els(x, y, z)
            return { { id = "animals:sort", y = 0, h = 10 },
                     { id = "animals:roster:1", y = 20, h = 30, isRoster = true, animal = x },
                     { id = "animals:roster:2", y = 50, h = 30, isRoster = true, animal = y },
                     { id = "animals:roster:3", y = 80, h = 30, isRoster = true, animal = z },
                     { id = "animals:bulk:hungry", y = 200, h = 20 } }
        end
        local function snapOf(e)
            return { tab = "animals", n = #e, firstId = e[1].id, lastId = e[#e].id, lastY = e[#e].y, lastH = e[#e].h,
                     animals = WWs._tabSnapAnimals(e) }
        end
        local s = snapOf(els(A1, A2, A3))
        check("RING the same rows: no rebuild", WWs._tabSnapDirty(s, "animals", els(A1, A2, A3)) == false)
        check("RING a whole-row scroll (A2 A3 A4 on the same stops): rebuilt",
            WWs._tabSnapDirty(s, "animals", els(A2, A3, A4)) == true)
        check("RING another tab, another count: rebuilt", WWs._tabSnapDirty(s, "craft", els(A1, A2, A3)) == true
            and WWs._tabSnapDirty(s, "animals", { els(A1, A2, A3)[1] }) == true)
        check("RING no snapshot yet: rebuilt", WWs._tabSnapDirty(nil, "animals", {}) == true)
        check("RING an empty tab stays empty: no rebuild", WWs._tabSnapDirty({ tab = "x", n = 0 }, "x", {}) == false)
        -- the stop the pad is on after the rebuild names the animal now drawn there: X ticks that one
        local after = els(A2, A3, A4)
        check("RING X on the rebuilt second row ticks the animal it shows", after[3].animal == A3)
    end
    check("RING the frame's refresh asks it and keeps the animals in the snapshot",
        WW:find("local dirty  = ZeD_WorldWindow._tabSnapDirty(snap, win._activeTab, newEls)", 1, true) ~= nil
        and WW:find("animals = ZeD_WorldWindow._tabSnapAnimals(newEls),", 1, true) ~= nil)
end

-- C1 + D6 (Nov 12 2026): the Animals tab opens with its title in row 1, the sub-tab strip under it with a gap (the
-- "Zones (1)" heading touched the strip), and its section heads are the one small mono line (no section-header band)
check("TITLE the tab opens with its title (the tab's own name, row 1)",
    TAB:find('local titleH = M.drawTabHeader(panel, x, y, w, ZeD.tr("UI_ZeD_World_TabAnimals"), false, false, true)', 1, true) ~= nil)
check("TITLE a gap under the sub-tab strip, both ways in",
    select(2, TAB:gsub("drawSubmodeStrip%(panel, win, x, y, w%) %+ T%.px%(STRIP_GAP_U%)", "")) == 2
    and TAB:find("\nlocal STRIP_GAP_U = %d") ~= nil)
check("D6 no section-header band left in the Animals tab", TAB:find("drawSectionHeader", 1, true) == nil)
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
    TAB:find("ZeD_ContextList:new(WPN(win), \"cursor\", sx, sy, nil, rows, nil)", 1, true) ~= nil
    and TAB:find('m.headText = getText("ContextMenu_Feed")', 1, true) ~= nil
    and TAB:find("ISScrollingListBox", 1, true) == nil)
check("SOURCE a food line: how many it suits, of how many hungry, how many carried",
    TAB:find('ZeD.tr("UI_ZeD_Animals_FeedNote", c.suits, hungry, c.have)', 1, true) ~= nil)
check("SOURCE the food picker keeps its answer, so the band's next frame does not read the pack again",
    TAB:find("local foods, _, hungry = Q.checkFeed(getSpecificPlayer(WPN(win)), selected)", 1, true) ~= nil
    and TAB:find("Q.feedChoices(", 1, true) == nil)
check("SOURCE a pick starts the feeding run with the food's name",
    TAB:find('Q.start(getSpecificPlayer(WPN(win)), "feed", Q.prune(sel, AP().getAnimalsInZone(zoneName, WPN(win))), name)', 1, true) ~= nil)
local CL = readFile(Z .. "ZeD_ContextList.lua")
check("SOURCE the list: A confirms, B cancels",
    CL:find("if button == Joypad.AButton then self:confirm()", 1, true) ~= nil
    and CL:find("elseif button == Joypad.BButton then self:cancel() end", 1, true) ~= nil)
local AQS = readFile(Z .. "AnimalsQuick.lua")
check("SOURCE the act is the game's onFeedAnimalFood", AQS:find("AnimalContextMenu.onFeedAnimalFood(player, animal, tool)", 1, true) ~= nil)

print(string.format("animals_quick_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
