-- ZeD-UI/42/media/lua/client/ZeD/AnimalsQuick.lua
-- ============================================================================
-- ANIMALS QUICK ACTIONS — client; the logic behind the Animals tab's buttons.
-- An alert row offers one verb (Milk, Shear or Walk to); the zone roster keeps
-- a selection (ticked rows, All hungry, All milkable) and its band runs Milk or
-- Shear over it. Every act is the game's own: AnimalContextMenu.onMilkAnimal and
-- onShearAnimal (they queue the walk to the animal's side, then ISMilkAnimal or
-- ISShearAnimal) and luautils.walkAdj. ZeD only picks the bucket or the shears
-- the game's own menu would offer, and says why a verb is greyed.
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

local CAN = { milk = AQ.canMilk, shear = AQ.canShear, ["goto"] = AQ.canGoTo }

--- canMilk / canShear / canGoTo by the verb's name.
function AQ.can(verb, player, animal)
    local f = CAN[verb]
    if not f then return false, nil end
    return f(player, animal)
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
end

-- ============================================================================
-- THE ACTS — one animal, straight to the game's own handlers
-- ============================================================================

--- Hand one verb for one animal to the game. Returns true, or false and the reason.
function AQ.act(verb, player, animal)
    local ok, why, tool = AQ.can(verb, player, animal)
    if not ok then return false, why end
    AQ.forgetChecks()
    if verb == "milk" then
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

--- The band's verbs for a selection, in band order (Shear, then Milk: the main one last).
-- Each { id, n = how many selected animals it applies to, ok, why }. A verb that applies
-- to none is left out; one whose tool is missing comes back with ok false and the reason.
function AQ.selectionVerbs(player, selected)
    local out = {}
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
-- AQ.run = { player, verb, list, i (the animal under way), done, phase = "next" | "wait",
--            seen (the queue was busy since the hand-over), ticks }
-- AQ.last = { verb, done, total, why } when a run has ended (the band says how it went)
-- ============================================================================

AQ.run = nil
AQ.last = nil

local HAS = { milk = AQ.hasMilk, shear = AQ.hasWool }

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

--- Start a run of "milk" or "shear" over the animals (the ones with nothing to give are
-- skipped). Returns true, or false and the reason when no animal can be done.
function AQ.start(player, verb, animals)
    local has = HAS[verb]
    if not (player and has) then return false, nil end
    local list = {}
    for _, a in ipairs(animals) do
        if has(a) then list[#list + 1] = a end
    end
    if #list == 0 then return false, nil end
    local ok, why = AQ.can(verb, player, list[1])
    if not ok then return false, why end
    if AQ.run then finish(nil) end
    AQ.run = { player = player, verb = verb, list = list, i = 0, done = 0, phase = "next", seen = false, ticks = 0 }
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
    -- the game's menu holds the animal still from the moment it is picked; an action that
    -- never started never lets go, so let go here
    local a = r.list[r.i]
    local b = a and ocall(a, "getBehavior")
    if b then pcall(b.setBlockMovement, b, false) end
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
        -- the action is over (or never showed up). An animal that still has something to
        -- give, while the tool is still there, was not done: the run was stopped (a move,
        -- the animal ran off, or the game turned the action down)
        local a = r.list[r.i]
        if AQ.can(r.verb, p, a) then
            local b = ocall(a, "getBehavior")
            if b then pcall(b.setBlockMovement, b, false) end
            finish(ZeD.tr("UI_ZeD_Animals_RunStopped", r.done, #r.list))
            return
        end
        r.done = r.done + 1
        r.phase = "next"
    end
    -- the next animal that still has something to give
    local has = HAS[r.verb]
    local i = r.i + 1
    while r.list[i] and not has(r.list[i]) do i = i + 1 end
    local a = r.list[i]
    if not a then
        finish(ZeD.tr("UI_ZeD_Animals_RunDone", r.done, #r.list))
        return
    end
    r.i = i
    local ok, why = AQ.act(r.verb, p, a)
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

--- The band's words for the run under way ("Milking 2 of 5"), or nil.
function AQ.runStatus()
    local r = AQ.run
    if not r then return nil end
    local key = (r.verb == "milk") and "UI_ZeD_Animals_RunMilking" or "UI_ZeD_Animals_RunShearing"
    return ZeD.tr(key, math.max(1, math.min(r.done + 1, #r.list)), #r.list)
end
