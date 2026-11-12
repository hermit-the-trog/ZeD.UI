-- ZeD-UI/42/media/lua/client/ZeD/AnimalsQuick.lua
-- ============================================================================
-- ANIMALS QUICK ACTIONS — client; the logic behind the Animals tab's buttons.
-- An alert row offers one verb (Milk, Shear or Walk to); the zone roster keeps
-- a selection (ticked rows, All hungry, All milkable) and its band runs Milk or
-- Shear over it, or Feed with a food picked from what the player carries. Every act
-- is the game's own: AnimalContextMenu.onMilkAnimal, onShearAnimal and
-- onFeedAnimalFood (they queue the walk to the animal's side, then ISMilkAnimal,
-- ISShearAnimal or ISFeedAnimalFromHand) and luautils.walkAdj. ZeD only picks the
-- bucket, the shears or the food item the game's own menu would offer, and says
-- why a verb is greyed.
-- A run over a selection goes one animal at a time: a milking ends by stopping
-- itself, which empties the whole action queue, so the next animal is handed to
-- the game only once the last one is done (AQ.tick).
-- ============================================================================

require "ZeD/AnimalsData"

ZeD = ZeD or {}
ZeD.AnimalsQuick = ZeD.AnimalsQuick or {}

local AQ = ZeD.AnimalsQuick
local function AD() return ZeD.AnimalsData end

-- A hunger the detail view words as Hungry or Starving (0-100, higher is hungrier)
AQ.HUNGRY = 50
-- How long the tool checks are kept (they look through the inventory)
AQ.CHECK_MS = 500
-- Ticks to wait for a handed-over action to show up in the queue before the run moves on
AQ.START_GRACE = 30

local function ocall(o, m, ...)
    if o == nil or not o[m] then return nil end
    local ok, r = pcall(o[m], o, ...)
    if ok then return r end
    return nil
end

local function now()
    return getTimestampMs and getTimestampMs() or 0
end

-- ============================================================================
-- WHAT AN ANIMAL HAS TO GIVE — the game's own tests (ISAnimalContextMenu)
-- ============================================================================

--- True when the game's menu would offer Milk for this animal (more than 0.1 L in it).
function AQ.hasMilk(animal)
    local d = ocall(animal, "getData")
    return d ~= nil and (ocall(d, "getMilkQuantity") or 0) > 0.1 and ocall(animal, "canBeMilked") == true
end

--- True when the game's menu would offer Shear for this animal (more than one unit of wool).
function AQ.hasWool(animal)
    local d = ocall(animal, "getData")
    return ocall(animal, "canBeSheared") == true and d ~= nil and (ocall(d, "getWoolQuantity") or 0) > 1
end

--- True for an animal the detail view calls Hungry or Starving.
function AQ.isHungry(animal)
    return (AD().getHunger(animal) or 0) >= AQ.HUNGRY
end

-- ============================================================================
-- THE ALERT'S VERB
-- ============================================================================

local ALERT_VERB = { udder_urgent = "milk", ready_milk = "milk", ready_shear = "shear" }

--- The verb an alert row offers: "milk", "shear", or "goto" for the rest (thirsty,
-- hungry, stressed, orphan: nothing ZeD can do in one press, so it walks you there).
function AQ.alertVerb(alertType)
    return ALERT_VERB[alertType] or "goto"
end

-- ============================================================================
-- THE TOOLS — what the game's menu would pick
-- ============================================================================

-- The milk containers the game offers (getAvailableFluidContainer for the breed's milk); the
-- radial menu takes the first, and milking with "all" moves on to the next when one fills.
local function milkBucket(player, animal)
    local inv = ocall(player, "getInventory")
    local d = ocall(animal, "getData")
    local breed = d and ocall(d, "getBreed")
    local mt = breed and ocall(breed, "getMilkType")
    if not (inv and mt) then return nil end
    local list = ocall(inv, "getAvailableFluidContainer", mt)
    if list and not list:isEmpty() then return list:get(0) end
    return nil
end

-- Shears in the inventory, the first with power (electric shears with an empty battery
-- are greyed in the game's menu). Returns the shears, then whether any were found.
local function pickShears(player)
    local inv = ocall(player, "getInventory")
    if not inv or not ItemTag or not ArrayList then return nil, false end
    local list = ocall(inv, "getAllTagRecurse", ItemTag.SHEAR, ArrayList.new())
    if not list or list:isEmpty() then return nil, false end
    for i = 0, list:size() - 1 do
        local s = list:get(i)
        local flat = instanceof(s, "DrainableComboItem") and (ocall(s, "getCurrentUsesFloat") or 0) <= 0
        if not flat then return s, true end
    end
    return nil, true
end

-- ============================================================================
-- THE FOOD — the game's hand-feeding test (AnimalContextMenu.doFeedFromHandMenu)
-- The game offers Feed only to an animal with any hunger at all, and lists the
-- carried things that pass its test and whose kind is on the animal's
-- getEatTypePossibleFromHand list. Its menu shows one line per name (a fluid by
-- the fluid's name), so ZeD groups the food by that name too.
-- ============================================================================

--- True when the game's menu would offer Feed for this animal (any hunger at all).
function AQ.wantsFood(animal)
    return (AD().getHunger(animal) or 0) > 0
end

-- The fluid of the animal's own milk, and the milk's name
local function milkFluid(animal)
    local breed = ocall(animal, "getBreed")
    local mt = breed and ocall(breed, "getMilkType")
    if not (mt and Fluid and Fluid.Get) then return nil, mt end
    local ok, f = pcall(Fluid.Get, mt)
    return ok and f or nil, mt
end

-- (the game's two milk tests: the animal's own milk, or any animal milk)
local function pureMilk(fc, animal)
    local mf, mt = milkFluid(animal)
    if mf and ocall(fc, "isPureFluid", mf) then return mt end
    if Fluid and Fluid.AnimalMilk and ocall(fc, "isPureFluid", Fluid.AnimalMilk) then return "AnimalMilk" end
    return nil
end

-- The game's first test: milk the animal drinks, animal feed, or a fresh fruit,
-- vegetable or milk food that fills (not rotten, not a spice).
local function isFeedFor(item, animal)
    local fc = ocall(item, "getFluidContainer")
    if fc and pureMilk(fc, animal) then return true end
    if ocall(item, "isAnimalFeed") then return true end
    if not instanceof(item, "Food") then return false end
    local ft = ocall(item, "getFoodType")
    return (ft == "Fruits" or ft == "Vegetables" or ocall(item, "getMilkType") ~= nil)
        and (ocall(item, "getHungerChange") or 0) < 0 and not ocall(item, "isRotten") and not ocall(item, "isSpice")
end

-- The kinds the game looks up on the animal's list, in its order: the full type,
-- a milk's name over it, the food type as a second, an animal feed's own kind over all.
local function feedKinds(item, animal)
    local k1, k2 = ocall(item, "getFullType"), nil
    local fc = ocall(item, "getFluidContainer")
    local milk = fc and pureMilk(fc, animal)
    if milk then k1 = milk end
    if instanceof(item, "Food") then k2 = ocall(item, "getFoodType") end
    if ocall(item, "isAnimalFeed") then k1 = ocall(item, "getAnimalFeedType") end
    return k1, k2
end

--- True when the game's Feed menu would list this item for this animal.
function AQ.eats(animal, item)
    if not isFeedFor(item, animal) then return false end
    local list = ocall(animal, "getEatTypePossibleFromHand")
    if not list then return false end
    local k1, k2 = feedKinds(item, animal)
    return (k1 ~= nil and list:contains(k1)) or (k2 ~= nil and list:contains(k2))
end

--- The name the game's Feed menu gives the item (a fluid by the fluid's name): the food's key.
function AQ.foodName(item)
    local fc = ocall(item, "getFluidContainer")
    local s = fc and ocall(fc, "getUiName")
    return s or ocall(item, "getDisplayName") or "?"
end

-- Everything carried that might be food (the inventory and the bags in it); the
-- game's own test per animal comes after.
local function carried(player)
    local inv = ocall(player, "getInventory")
    if not inv then return {} end
    local list = ocall(inv, "getAllEvalRecurse", function(it)
        return it:getFluidContainer() ~= nil or it:isAnimalFeed() or instanceof(it, "Food")
    end)
    local out = {}
    if not list then return out end
    for i = 0, list:size() - 1 do out[#out + 1] = list:get(i) end
    return out
end

--- The first carried item of that food the animal eats (the one the game's menu would hand over), or nil.
function AQ.findFood(player, animal, food)
    for _, it in ipairs(carried(player)) do
        if AQ.foodName(it) == food and AQ.eats(animal, it) then return it end
    end
    return nil
end

--- The picker's foods for these animals: only the hungry ones count, and only a food
-- at least one of them eats is offered. Returns the list, sorted by name, each
-- { name, tex, have (how many carried), suits (how many of the hungry eat it) },
-- then the reason when the list is empty, then how many are hungry.
function AQ.feedChoices(player, animals)
    local hungry = {}
    for _, a in ipairs(animals) do
        if AQ.wantsFood(a) then hungry[#hungry + 1] = a end
    end
    if #hungry == 0 then return {}, ZeD.tr("UI_ZeD_Animals_NotHungry"), 0 end
    local byName, out = {}, {}
    for _, it in ipairs(carried(player)) do
        local fits = nil
        for _, a in ipairs(hungry) do
            if AQ.eats(a, it) then fits = fits or {}; fits[#fits + 1] = a end
        end
        if fits then
            local name = AQ.foodName(it)
            local c = byName[name]
            if not c then
                c = { name = name, tex = ocall(it, "getTex"), have = 0, suits = 0, _who = {} }
                byName[name] = c
                out[#out + 1] = c
            end
            c.have = c.have + 1
            for _, a in ipairs(fits) do
                if not c._who[a] then c._who[a] = true; c.suits = c.suits + 1 end
            end
        end
    end
    table.sort(out, function(x, y) return x.name < y.name end)
    if #out == 0 then return out, ZeD.tr("UI_ZeD_Animals_NeedFood"), #hungry end
    return out, nil, #hungry
end

-- AQ.feedChoices kept for AQ.CHECK_MS (the band asks every frame): { t, player, animals, choices, why, n }
local _feedKept = nil

--- AQ.feedChoices, the answer kept for half a second for the same animals.
function AQ.checkFeed(player, animals)
    local k, t = _feedKept, now()
    if k and k.player == player and t - k.t < AQ.CHECK_MS and #k.animals == #animals then
        local same = true
        for i, a in ipairs(animals) do
            if k.animals[i] ~= a then same = false; break end
        end
        if same then return k.choices, k.why, k.n end
    end
    local choices, why, n = AQ.feedChoices(player, animals)
    local copy = {}
    for i, a in ipairs(animals) do copy[i] = a end
    _feedKept = { t = t, player = player, animals = copy, choices = choices, why = why, n = n }
    return choices, why, n
end

-- ============================================================================
-- CAN IT BE DONE — each returns ok, the reason in plain words when not, and the tool
-- ============================================================================

function AQ.canMilk(player, animal)
    if not AQ.hasMilk(animal) then return false, ZeD.tr("UI_ZeD_Animals_NoMilkYet") end
    if ocall(player, "hasFullInventory") then return false, getText("ContextMenu_FullInventory") end
    local bucket = milkBucket(player, animal)
    if not bucket then return false, ZeD.tr("UI_ZeD_Animals_NeedBucket") end
    return true, nil, bucket
end

function AQ.canShear(player, animal)
    if not AQ.hasWool(animal) then return false, ZeD.tr("UI_ZeD_Animals_NoWoolYet") end
    local shears, any = pickShears(player)
    if not shears then
        return false, any and getText("Tooltip_Animal_ShearNoBattery") or ZeD.tr("UI_ZeD_Animals_NeedShears")
    end
    return true, nil, shears
end

function AQ.canGoTo(player, animal)
    if not player or not ocall(animal, "getSquare") then return false, ZeD.tr("UI_ZeD_Animals_OutOfReach") end
    return true, nil, nil
end

--- Feed one animal the named food: it must be hungry at all, and carry an item of that food it eats.
function AQ.canFeed(player, animal, food)
    if not AQ.wantsFood(animal) then return false, ZeD.tr("UI_ZeD_Animals_NotHungry") end
    local item = food and AQ.findFood(player, animal, food)
    if not item then return false, ZeD.tr("UI_ZeD_Animals_NeedFood") end
    return true, nil, item
end

local CAN = { milk = AQ.canMilk, shear = AQ.canShear, ["goto"] = AQ.canGoTo, feed = AQ.canFeed }

--- canMilk / canShear / canGoTo / canFeed by the verb's name (food: the picked food's name, for feed).
function AQ.can(verb, player, animal, food)
    local f = CAN[verb]
    if not f then return false, nil end
    return f(player, animal, food)
end

-- The checks kept for AQ.CHECK_MS: a page of alerts asks every frame, and each check
-- looks through the inventory. [verb][animal] = { t, ok, why }
local _checks = {}

--- AQ.can, the answer kept for half a second (the tool itself is looked up again on the press).
function AQ.check(verb, player, animal)
    local byVerb = _checks[verb]
    if not byVerb then byVerb = {}; _checks[verb] = byVerb end
    local t = now()
    local c = byVerb[animal]
    if c and c.player == player and t - c.t < AQ.CHECK_MS then return c.ok, c.why end
    local ok, why = AQ.can(verb, player, animal)
    byVerb[animal] = { t = t, player = player, ok = ok, why = why }
    return ok, why
end

--- Forget the kept checks (after an act: the bucket filled, the shears moved hands).
function AQ.forgetChecks()
    _checks = {}
    _feedKept = nil
end

-- ============================================================================
-- THE ACTS — one animal, straight to the game's own handlers
-- ============================================================================

--- Hand one verb for one animal to the game. Returns true, or false and the reason.
function AQ.act(verb, player, animal, food)
    local ok, why, tool = AQ.can(verb, player, animal, food)
    if not ok then return false, why end
    AQ.forgetChecks()
    if verb == "feed" then
        -- the game's own: hold the animal, walk beside it, the food to hand, ISFeedAnimalFromHand
        AnimalContextMenu.onFeedAnimalFood(player, animal, tool)
    elseif verb == "milk" then
        -- (all = true: when the bucket fills, the game moves on to the next container that takes this milk)
        AnimalContextMenu.onMilkAnimal(animal, player, tool, true)
    elseif verb == "shear" then
        AnimalContextMenu.onShearAnimal(animal, player, tool)
    elseif verb == "goto" then
        -- the game's walk to the nearest free square beside it; false when none is free
        if not luautils.walkAdj(player, animal:getSquare()) then
            return false, ZeD.tr("UI_ZeD_Animals_OutOfReach")
        end
    end
    return true
end

-- ============================================================================
-- THE SELECTION — a zone roster's ticked rows
-- A selection is a table keyed by animal. It belongs to one zone: AnimalsTab clears
-- it when the zone changes and drops animals that left the zone every frame.
-- ============================================================================

function AQ.newSelection()
    return { set = {}, zone = nil }
end

function AQ.isSelected(sel, animal)
    return sel ~= nil and sel.set[animal] == true
end

function AQ.toggle(sel, animal)
    if sel.set[animal] then sel.set[animal] = nil else sel.set[animal] = true end
end

function AQ.clear(sel)
    sel.set = {}
end

local PICK = { hungry = AQ.isHungry, milkable = AQ.hasMilk }

--- Replace the selection with the animals of the list that are "hungry" or "milkable".
-- Returns how many it picked.
function AQ.selectWhere(sel, animals, which)
    local f = PICK[which]
    sel.set = {}
    local n = 0
    if not f then return 0 end
    for _, a in ipairs(animals) do
        if f(a) then sel.set[a] = true; n = n + 1 end
    end
    return n
end

--- How many of the list are "hungry" or "milkable" (the band greys a pick that finds none).
function AQ.countWhere(animals, which)
    local f = PICK[which]
    local n = 0
    if not f then return 0 end
    for _, a in ipairs(animals) do
        if f(a) then n = n + 1 end
    end
    return n
end

--- The selected animals still in the list, in the list's order; the others leave the selection.
function AQ.prune(sel, animals)
    local out, keep = {}, {}
    for _, a in ipairs(animals) do
        if sel.set[a] then out[#out + 1] = a; keep[a] = true end
    end
    sel.set = keep
    return out
end

--- The band's verbs for a selection, in band order (Feed, Shear, then Milk: the main one last).
-- Each { id, n = how many selected animals it applies to, ok, why }. A verb that applies
-- to none is left out; one whose tool is missing comes back with ok false and the reason.
-- Feed applies to the hungry ones and is greyed when nothing carried is food for any of them.
function AQ.selectionVerbs(player, selected)
    local out = {}
    local foods, fwhy, fn = AQ.checkFeed(player, selected)
    if fn > 0 then out[#out + 1] = { id = "feed", n = fn, ok = #foods > 0, why = (#foods == 0) and fwhy or nil } end
    for _, v in ipairs({ { id = "shear", has = AQ.hasWool }, { id = "milk", has = AQ.hasMilk } }) do
        local n, ok, why = 0, false, nil
        for _, a in ipairs(selected) do
            if v.has(a) then
                n = n + 1
                if not ok then
                    local o, w = AQ.check(v.id, player, a)
                    if o then ok, why = true, nil elseif why == nil then why = w end
                end
            end
        end
        if n > 0 then out[#out + 1] = { id = v.id, n = n, ok = ok, why = (not ok) and why or nil } end
    end
    return out
end

-- ============================================================================
-- THE RUN — one verb over many animals, one at a time
-- AQ.run = { player, verb, food (feed: the picked food's name), suits (feed: the animals
--            that food was for when the run began), list, i (the animal under way), done,
--            phase = "next" | "wait", seen (the queue was busy since the hand-over), ticks,
--            before (feed: the hunger of the animal under way at the hand-over) }
-- AQ.last = { verb, done, total, why } when a run has ended (the band says how it went)
-- ============================================================================

AQ.run = nil
AQ.last = nil

local HAS = { milk = AQ.hasMilk, shear = AQ.hasWool }

-- True while the run still has this animal to do: milk or wool to take, or, for feed, a
-- hunger and a place among the animals the food was for
local function wants(r, a)
    if r.verb == "feed" then return r.suits[a] == true and AQ.wantsFood(a) end
    local has = HAS[r.verb]
    return has ~= nil and has(a)
end

-- True when the action handed over for this animal did not happen. Milk and shear: it still
-- has something to give while the tool is there. Feed: its hunger did not go down (an
-- animal fed by hand may stay a little hungry, so "still hungry" is no test).
local function leftUndone(r, a)
    if r.verb == "feed" then return (AD().getHunger(a) or 0) >= (r.before or 0) end
    return AQ.can(r.verb, r.player, a) == true
end

local function queueBusy(player)
    if ISTimedActionQueue and ISTimedActionQueue.isPlayerDoingAction and ISTimedActionQueue.isPlayerDoingAction(player) then
        return true
    end
    local q = ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[player]
    return q ~= nil and q.queue ~= nil and #q.queue > 0
end

-- (the hoisted slot: the tick hook and AQ.start both reach it)
local onTick

local function finish(why)
    local r = AQ.run
    if not r then return end
    AQ.last = { verb = r.verb, done = r.done, total = #r.list, why = why, t = now() }
    AQ.run = nil
    if Events and Events.OnTick then Events.OnTick.Remove(onTick) end
end

-- the game's menu holds the animal still from the moment it is picked; an action that
-- never started never lets go, so let go here
local function letGo(a)
    local b = a and ocall(a, "getBehavior")
    if b then pcall(b.setBlockMovement, b, false) end
end

--- Start a run of "milk", "shear" or "feed" over the animals (the ones with nothing to give,
-- or not hungry, are skipped). food: for feed, the picked food's name (AQ.feedChoices).
-- Returns true, or false and the reason when no animal can be done.
function AQ.start(player, verb, animals, food)
    if not (player and (HAS[verb] or verb == "feed")) then return false, nil end
    if verb == "feed" and not food then return false, nil end
    local r = { player = player, verb = verb, food = food, suits = {}, i = 0, done = 0, phase = "next", seen = false, ticks = 0 }
    if verb == "feed" then
        for _, a in ipairs(animals) do
            if AQ.wantsFood(a) and AQ.findFood(player, a, food) then r.suits[a] = true end
        end
    end
    local list = {}
    for _, a in ipairs(animals) do
        if wants(r, a) then list[#list + 1] = a end
    end
    if #list == 0 then return false, (verb == "feed") and ZeD.tr("UI_ZeD_Animals_NeedFood") or nil end
    local ok, why = AQ.can(verb, player, list[1], food)
    if not ok then return false, why end
    if AQ.run then finish(nil) end
    r.list = list
    AQ.run = r
    AQ.last = nil
    if Events and Events.OnTick then
        Events.OnTick.Remove(onTick)
        Events.OnTick.Add(onTick)
    end
    AQ.tick()
    return true
end

--- Stop the run: the action under way ends (the game's own cancel) and the rest are dropped.
function AQ.stop()
    local r = AQ.run
    if not r then return end
    if ISTimedActionQueue and ISTimedActionQueue.clear then ISTimedActionQueue.clear(r.player) end
    letGo(r.list[r.i])
    finish(ZeD.tr("UI_ZeD_Animals_RunStopped", r.done, #r.list))
end

--- One step of the run (every tick while one is going).
function AQ.tick()
    local r = AQ.run
    if not r then return end
    local p = r.player
    if not p or (p.isDead and p:isDead()) then finish(nil) return end
    if r.phase == "wait" then
        local busy = queueBusy(p)
        if busy then r.seen = true; return end
        if not r.seen then
            r.ticks = r.ticks + 1
            if r.ticks < AQ.START_GRACE then return end
        end
        -- the action is over (or never showed up). One left undone means the run was
        -- stopped: the player walked off, the animal ran, or the game turned it down
        local a = r.list[r.i]
        if leftUndone(r, a) then
            letGo(a)
            finish(ZeD.tr("UI_ZeD_Animals_RunStopped", r.done, #r.list))
            return
        end
        r.done = r.done + 1
        r.phase = "next"
    end
    -- the next animal still to do
    local i = r.i + 1
    while r.list[i] and not wants(r, r.list[i]) do i = i + 1 end
    local a = r.list[i]
    if not a then
        finish(ZeD.tr("UI_ZeD_Animals_RunDone", r.done, #r.list))
        return
    end
    r.i = i
    r.before = AD().getHunger(a) or 0
    -- (feed: when the food has run out the act says so, and the run ends with that reason)
    local ok, why = AQ.act(r.verb, p, a, r.food)
    if not ok then finish(why) return end
    r.phase, r.seen, r.ticks = "wait", false, 0
end

onTick = function()
    local ok, err = pcall(AQ.tick)
    if not ok then
        print("[ZeD] Animals: the run stopped on an error: " .. tostring(err))
        AQ.run = nil
        if Events and Events.OnTick then Events.OnTick.Remove(onTick) end
    end
end

local RUN_KEY = { milk = "UI_ZeD_Animals_RunMilking", shear = "UI_ZeD_Animals_RunShearing", feed = "UI_ZeD_Animals_RunFeeding" }

--- The band's words for the run under way ("Milking 2 of 5"), or nil.
function AQ.runStatus()
    local r = AQ.run
    if not r then return nil end
    return ZeD.tr(RUN_KEY[r.verb] or RUN_KEY.milk, math.max(1, math.min(r.done + 1, #r.list)), #r.list)
end
