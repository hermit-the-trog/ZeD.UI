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
-- The game's handlers read points on the animal's body (its sides, its head) that
-- are only known while it is drawn near the player; for an animal further off they
-- are nil and the handler throws. So ZeD walks up first, holding the animal still as
-- the game's menu does, and hands the act over when the walk is done.
-- ============================================================================

require "ZeD/AnimalsData"

ZeD = ZeD or {}
ZeD.AnimalsQuick = ZeD.AnimalsQuick or {}

local AQ = ZeD.AnimalsQuick
local function AD() return ZeD.AnimalsData end

-- A hunger the detail view words as Hungry or Starving (0-100, higher is hungrier)
AQ.HUNGRY = 50
-- The hunger the game's world menu offers Feed at, on the same scale (its 0.1; the trailer's
-- menu too: only an animal held in the hands is offered Feed at any hunger at all)
AQ.FEED_AT = 10
-- Milk is drunk only past the game's 0.1 hunger or thirst (AnimalData.eatItem), compared in
-- single precision, where 0.1 is 0.1000000015: on this scale a hair over 10, so an animal at
-- exactly 10 drinks none
AQ.MILK_PAST = 10.0000005
-- How long the tool checks are kept (they look through the inventory)
AQ.CHECK_MS = 500
-- Ticks to wait for a handed-over action to show up in the queue before the run moves on
AQ.START_GRACE = 30
-- How much further than the nearest they came the player may be from the animal under way
-- (in squares) before the run takes it they walked off, or were moved, and stops
AQ.AWAY = 6
-- Ticks the queue may hold actions with none of them running before the run calls it stuck
AQ.STALL_TICKS = 60
-- The longest one animal may take, walk and act together (ms of the game running)
AQ.WAIT_MS = 180000
-- A gap between two ticks longer than this (ms) is the game paused, not time taken: no tick
-- fires while a single-player game is paused, and the clock is the wall clock
AQ.PAUSE_MS = 1000

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

--- True when the game's menu would offer Milk for this animal (more than 0.1 L in it). The test lives in
-- AnimalsData, shared with the alerts, so All milkable and "Ready to milk" cannot disagree.
function AQ.hasMilk(animal)
    return AD().hasMilk(animal) == true
end

--- True when the game's menu would offer Shear for this animal (more than one unit of wool).
function AQ.hasWool(animal)
    return AD().hasWool(animal) == true
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
-- radial menu takes the first, and milking with "all" moves on by itself to more of one kind
-- when one fills (roomToGoOn, below, has its exact search); a run hands the animal over again
-- for a container of another kind.
-- The game's rule (InventoryItem.isAvailableFluidContainer): any carried thing with a fluid
-- container that is empty, or whose main fluid is this milk, a water bottle as much as a
-- bucket; only the main inventory counts, not the bags in it. The rule does not ask for room:
-- a bucket full of this milk passes it, and the game's milking with it stops on its first
-- pull (ISMilkAnimal.milk finds it full and no other). ZeD skips the full ones, so a full
-- bucket greys Milk, and a run whose last container fills ends saying so ("Bucket full").
local function milkBucket(player, animal)
    local inv = ocall(player, "getInventory")
    local d = ocall(animal, "getData")
    local breed = d and ocall(d, "getBreed")
    local mt = breed and ocall(breed, "getMilkType")
    if not (inv and mt) then return nil end
    local list = ocall(inv, "getAvailableFluidContainer", mt)
    if not list then return nil end
    for i = 0, list:size() - 1 do
        local it = list:get(i)
        local fc = ocall(it, "getFluidContainer")
        if not (fc and ocall(fc, "isFull") == true) then return it end
    end
    return nil
end

-- True when the game's own milking would go on past a full container. This is the search its
-- milking with "all" runs (ISMilkAnimal.milk): the first carried container for this milk, full
-- or not, then the first of that one's kind that is not full, whatever fluid is in it; a full
-- inventory stops it. A milking that ended while this finds room was cut short (a move, a
-- cancel, a Walk to), not out of room. (A container whose fullness cannot be read counts as
-- room: a run that cannot tell stops, and never walks the player back.)
local function roomToGoOn(player, animal)
    if ocall(player, "hasFullInventory") == true then return false end
    local inv = ocall(player, "getInventory")
    local d = ocall(animal, "getData")
    local breed = d and ocall(d, "getBreed")
    local mt = breed and ocall(breed, "getMilkType")
    local first = inv and mt and ocall(inv, "getFirstAvailableFluidContainer", mt)
    local ft = first and ocall(first, "getFullType")
    local list = ft and ocall(inv, "getItemsFromFullType", ft)
    if not list then return false end
    for i = 0, list:size() - 1 do
        local fc = ocall(list:get(i), "getFluidContainer")
        if fc and ocall(fc, "isFull") ~= true then return true end
    end
    return false
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
-- The game's world menu offers Feed to an animal at AQ.FEED_AT hunger or more,
-- and lists the carried things that pass its test and whose kind is on the
-- animal's getEatTypePossibleFromHand list. Its menu shows one line per name (a
-- fluid by the fluid's name), so ZeD groups the food by that name too. Milk is
-- drunk only past AQ.MILK_PAST hunger or thirst: any less and the game's feeding
-- takes none of it, so ZeD offers milk only to an animal that will drink it.
-- Each carried item and each animal is read once (itemFacts, animalFacts) and the
-- two are matched in Lua: the band asks every half second, and Java calls for
-- every item with every animal stall a frame with a big herd and a full pack.
-- ============================================================================

-- True when an animal at this hunger (0-100) is hungry enough for the game's menu: its world
-- menu's AQ.FEED_AT, or any hunger at all for one held in the hands (the inventory menu)
local function feedGate(animal, hunger)
    if ocall(animal, "isExistInTheWorld") == false and not ocall(animal, "getVehicle") then return hunger > 0 end
    return hunger >= AQ.FEED_AT
end

--- True when the game's menu would offer Feed for this animal (see AQ.FEED_AT).
function AQ.wantsFood(animal)
    return feedGate(animal, AD().getHunger(animal) or 0)
end

-- (the game's walk over the inventory and its bags takes a test; one function, made once)
local function maybeFood(it)
    return it:getFluidContainer() ~= nil or it:isAnimalFeed() or instanceof(it, "Food")
end

-- Everything carried that might be food (the inventory and the bags in it); the
-- game's own test per animal comes after.
local function carried(player)
    local inv = ocall(player, "getInventory")
    if not inv then return {} end
    local list = ocall(inv, "getAllEvalRecurse", maybeFood)
    local out = {}
    if not list then return out end
    for i = 0, list:size() - 1 do out[#out + 1] = list:get(i) end
    return out
end

-- What the feed tests need of one carried item, read once: its fluid container and whether that
-- holds only animal milk, animal feed and its kind, a food and its type, fresh produce or milk food
-- that fills (not rotten, not a spice), its full type. own[milk name] fills in as animals ask.
local function itemFacts(item)
    local fc = ocall(item, "getFluidContainer")
    local f = { item = item, fc = fc, own = {}, fullType = ocall(item, "getFullType") }
    f.animalMilk = fc ~= nil and Fluid ~= nil and Fluid.AnimalMilk ~= nil and ocall(fc, "isPureFluid", Fluid.AnimalMilk) == true
    f.isFeed = ocall(item, "isAnimalFeed") == true
    if f.isFeed then f.feedType = ocall(item, "getAnimalFeedType") end
    f.food = instanceof(item, "Food") == true
    if f.food then
        local ft = ocall(item, "getFoodType")
        f.foodType = ft
        f.fresh = (ft == "Fruits" or ft == "Vegetables" or ocall(item, "getMilkType") ~= nil)
            and (ocall(item, "getHungerChange") or 0) < 0 and not ocall(item, "isRotten") and not ocall(item, "isSpice")
    end
    return f
end

-- What the feed tests need of one animal, read once: its own milk (the name and the game's
-- fluid), the kinds it takes from the hand (a set), its hunger and thirst (0-100)
local function animalFacts(animal, hunger)
    local breed = ocall(animal, "getBreed")
    local mt = breed and ocall(breed, "getMilkType")
    local an = { mt = mt, eats = {}, hunger = hunger or AD().getHunger(animal) or 0, thirst = AD().getThirst(animal) or 0 }
    if mt and Fluid and Fluid.Get then
        local ok, mf = pcall(Fluid.Get, mt)
        if ok then an.mf = mf end
    end
    local list = ocall(animal, "getEatTypePossibleFromHand")
    if list then
        for i = 0, list:size() - 1 do an.eats[list:get(i)] = true end
    end
    return an
end

-- True when the animal takes this item from the hand: the game's first test (milk of its own kind
-- or any animal milk, animal feed, or fresh produce), a kind on its list, and a container of milk
-- only while the animal is hungry or thirsty enough to drink
local function takes(f, an)
    local milk = nil
    if f.fc then
        if an.mf then
            local own = f.own[an.mt]
            if own == nil then
                own = ocall(f.fc, "isPureFluid", an.mf) == true
                f.own[an.mt] = own
            end
            if own then milk = an.mt end
        end
        if f.animalMilk then milk = "AnimalMilk" end
    end
    if not (milk or f.isFeed or f.fresh) then return false end
    -- the kinds the game looks up on the animal's list, in its order: the full type, a milk's
    -- name over it, an animal feed's own kind over all, the food type as a second
    local k1 = milk or f.fullType
    if f.isFeed then k1 = f.feedType end
    if not ((k1 ~= nil and an.eats[k1]) or (f.foodType ~= nil and an.eats[f.foodType])) then return false end
    if milk and not f.food and not f.isFeed then return an.hunger > AQ.MILK_PAST or an.thirst > AQ.MILK_PAST end
    return true
end

--- True when the game would feed this item to this animal from the hand: its Feed menu lists it,
-- and milk only while the animal is hungry or thirsty enough to drink (AQ.MILK_PAST).
function AQ.eats(animal, item)
    return takes(itemFacts(item), animalFacts(animal))
end

--- The name the game's Feed menu gives the item (a fluid by the fluid's name): the food's key.
function AQ.foodName(item)
    local fc = ocall(item, "getFluidContainer")
    local s = fc and ocall(fc, "getUiName")
    return s or ocall(item, "getDisplayName") or "?"
end

-- The carried items of the named food, each read once (the run's start, each hand-over)
local function foodItems(player, food)
    local out = {}
    for _, it in ipairs(carried(player)) do
        if AQ.foodName(it) == food then out[#out + 1] = itemFacts(it) end
    end
    return out
end

-- The first of those items the animal takes (the one the game's menu would hand over), or nil
local function firstTaken(items, animal)
    if #items == 0 then return nil end
    local an = animalFacts(animal)
    for _, f in ipairs(items) do
        if takes(f, an) then return f.item end
    end
    return nil
end

--- The first carried item of that food the animal takes (the one the game's menu would hand over), or nil.
function AQ.findFood(player, animal, food)
    return firstTaken(foodItems(player, food), animal)
end

local function byName(x, y) return x.name < y.name end

--- The picker's foods for these animals: only the hungry ones count, and only a food
-- at least one of them takes is offered. Returns the list, sorted by name, each
-- { name, tex, have (how many carried), suits (how many of the hungry take it) },
-- then the reason when the list is empty, then how many are hungry.
function AQ.feedChoices(player, animals)
    local hungry, facts = {}, {}
    for _, a in ipairs(animals) do
        local h = AD().getHunger(a) or 0
        if feedGate(a, h) then
            hungry[#hungry + 1] = a
            facts[#facts + 1] = animalFacts(a, h)
        end
    end
    if #hungry == 0 then return {}, ZeD.tr("UI_ZeD_Animals_NotHungry"), 0 end
    local named, out = {}, {}
    for _, it in ipairs(carried(player)) do
        local f, c = itemFacts(it), nil
        for i, a in ipairs(hungry) do
            if takes(f, facts[i]) then
                if not c then
                    local name = AQ.foodName(it)
                    c = named[name]
                    if not c then
                        c = { name = name, tex = ocall(it, "getTex"), have = 0, suits = 0, _who = {} }
                        named[name] = c
                        out[#out + 1] = c
                    end
                    c.have = c.have + 1
                end
                if not c._who[a] then c._who[a] = true; c.suits = c.suits + 1 end
            end
        end
    end
    table.sort(out, byName)
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
    if not ocall(animal, "getSquare") then return false, ZeD.tr("UI_ZeD_Animals_OutOfReach") end
    if ocall(player, "hasFullInventory") then return false, getText("ContextMenu_FullInventory") end
    local bucket = milkBucket(player, animal)
    if not bucket then return false, ZeD.tr("UI_ZeD_Animals_NeedMilkContainer") end
    return true, nil, bucket
end

function AQ.canShear(player, animal)
    if not AQ.hasWool(animal) then return false, ZeD.tr("UI_ZeD_Animals_NoWoolYet") end
    if not ocall(animal, "getSquare") then return false, ZeD.tr("UI_ZeD_Animals_OutOfReach") end
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

--- Feed one animal the named food: it must be hungry enough for the game's menu, and the player must
-- carry an item of that food it takes.
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

-- The points on the animal each handler walks the player to: its milking sides, its shearing
-- sides, its head. The game knows them only while the animal is drawn near the player.
local BODY_POINTS = { milk = { "rightmilk", "leftmilk" }, shear = { "rightshear", "leftshear" }, feed = { "head" } }

-- True when the game knows every point the verb's handler reads on this animal
local function pointsKnown(verb, animal)
    local names = BODY_POINTS[verb]
    if not names then return true end
    -- (an animal in a trailer or in the hands is fed without its head point)
    if verb == "feed" and ocall(animal, "isExistInTheWorld") == false then return true end
    for _, n in ipairs(names) do
        if ocall(animal, "getAttachmentWorldPos", n) == nil then return false end
    end
    return true
end

-- How far the player stands from the animal, in squares (nil when either has no place)
local function distTo(player, animal)
    local px, py = ocall(player, "getX"), ocall(player, "getY")
    local ax, ay = ocall(animal, "getX"), ocall(animal, "getY")
    if not (px and py and ax and ay) then return nil end
    return math.sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay))
end

-- The square the animal stands on now, read from its position. Its getSquare() is the square its own last
-- update left it on, so an animal moved by other means (set down, carried off, a script) names the old one
-- until it next updates. A walk aimed there goes where it was, or nowhere at all when that was beside the
-- player (the game does no walk to a square within 1.6 of you). The getSquare() answer when the position
-- has no loaded square.
local function squareOf(animal)
    local x, y, z = ocall(animal, "getX"), ocall(animal, "getY"), ocall(animal, "getZ")
    local cell = x and y and getCell and getCell()
    local sq = cell and ocall(cell, "getGridSquare", math.floor(x), math.floor(y), math.floor(z or 0))
    return sq or ocall(animal, "getSquare")
end

-- Hold the animal still (true) or let it go (false). The game's menu holds it from the moment
-- it is picked and its actions let go when they end; one that never started never lets go, so
-- the run does. (A hold nobody lets go of wears off by itself after a while: the game counts
-- 8000 of its time units, a few minutes at normal speed.)
local function hold(a, still)
    local b = a and ocall(a, "getBehavior")
    if b then pcall(b.setBlockMovement, b, still) end
end

local function letGo(a)
    hold(a, false)
end

--- Hand one verb for one animal to the game. Returns true, or false and the reason. A third
-- return of "approach" says only the walk up was handed over: the animal is too far off for
-- the game's handler, and the run hands the act over when the walk is done. The fourth is the
-- tool handed over (the bucket, the shears, the food).
function AQ.act(verb, player, animal, food)
    local ok, why, tool = AQ.can(verb, player, animal, food)
    if not ok then return false, why end
    AQ.forgetChecks()
    if not pointsKnown(verb, animal) then
        if not luautils.walkAdj(player, squareOf(animal)) then
            return false, ZeD.tr("UI_ZeD_Animals_OutOfReach")
        end
        -- (held from the press, as the game's own menu does: an animal left to graze while the
        -- player walks up is squares off by the time they get there)
        hold(animal, true)
        return true, nil, "approach", tool
    end
    if verb == "feed" then
        -- the game's own: hold the animal, walk beside it, the food to hand, ISFeedAnimalFromHand
        AnimalContextMenu.onFeedAnimalFood(player, animal, tool)
    elseif verb == "milk" then
        -- (all = true: when the bucket fills, the game moves on to another of the same kind with room)
        AnimalContextMenu.onMilkAnimal(animal, player, tool, true)
    elseif verb == "shear" then
        AnimalContextMenu.onShearAnimal(animal, player, tool)
    elseif verb == "goto" then
        -- the game's walk to the nearest free square beside the one it stands on now; false when none is free
        if not luautils.walkAdj(player, squareOf(animal)) then
            return false, ZeD.tr("UI_ZeD_Animals_OutOfReach")
        end
    end
    return true, nil, nil, tool
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
--            before (feed: the hunger of the animal under way at the hand-over),
--            approach (only the walk up was handed over), walked (that walk reached its square),
--            near (the closest the player came to the animal under way since the last walk ended),
--            stall (ticks the queue sat stuck), spent (ms the game ran since the hand-over),
--            lastT (the last tick's ms), tool (the bucket, shears or food handed over),
--            milking (milk: the game's ISMilkAnimal handed over; its bucket is the container it
--            is filling, which it changes by itself when one fills),
--            began (the act itself, not just the walk and the tool to hand before it, was the game's
--            current action), lead (the last of those lead actions seen current, by its Type) }
-- AQ.last = { verb, done, total, why, cause, began, lead } when a run has ended (the band says how it went)
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

-- True when the milk container handed over is full
local function toolFull(r)
    local fc = r.verb == "milk" and r.tool and ocall(r.tool, "getFluidContainer")
    return fc ~= nil and fc ~= false and ocall(fc, "isFull") == true
end

-- "Bucket full: milked 1 of 2": the run ends because the last container that takes this milk
-- filled (the game's milking moves on by itself to another of the same kind, and the run to one
-- of another kind, so it stopped only when none was left). The container by its own name in the
-- game's words.
local function fullWords(r)
    local name = ocall(r.tool, "getDisplayName") or getText("ContextMenu_Milk")
    return ZeD.tr("UI_ZeD_Animals_RunFull", name, r.done, #r.list)
end

-- Whether the action handed over for this animal was left undone: false (it was done), true
-- (stopped), "refill" (the game's milking stopped for want of room with milk left in the
-- animal, and another container carried has room) or "full" (milk left in it, and no room left
-- in anything carried).
-- Milk and shear: undone while the animal still has something to give. Feed: its hunger did
-- not go down (an animal fed by hand may stay a little hungry, so "still hungry" is no test).
local function leftUndone(r, a)
    if r.verb == "feed" then return (AD().getHunger(a) or 0) >= (r.before or 0) end
    if not HAS[r.verb](a) then return false end
    -- something left to give, and the tool left the inventory: a stressed animal kicks the
    -- bucket out of the hands. After the game moved on, the one kicked is the one it was
    -- filling, not the one handed over.
    local inv = ocall(r.player, "getInventory")
    local filling = r.milking and r.milking.bucket
    if inv and r.tool and ocall(inv, "contains", r.tool) == false then return true end
    if inv and filling and filling ~= r.tool and ocall(inv, "contains", filling) == false then return true end
    -- the container handed over has room, or the game's own search still finds some: the milking
    -- was cut short (a move, a cancel, a Walk to), even after the game moved on by itself from a
    -- full bucket to the next of its kind
    if not toolFull(r) or roomToGoOn(r.player, a) then return true end
    -- the game ran out of room: its milking moves on only to more of one kind (its
    -- getFirstAvailableFluidContainer hands back a full container, and it looks for that type),
    -- so with a pot left after the bucket the animal goes over again with the pot
    if AQ.can(r.verb, r.player, a) == true then return "refill" end
    return "full"
end

local function doingAction(player)
    return ISTimedActionQueue ~= nil and ISTimedActionQueue.isPlayerDoingAction ~= nil
        and ISTimedActionQueue.isPlayerDoingAction(player) == true
end

local function queued(player)
    local q = ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[player]
    return q ~= nil and q.queue ~= nil and #q.queue > 0
end

local function queueBusy(player)
    return doingAction(player) or queued(player)
end

-- The game's walks: to a square (luautils.walkAdj, the walk up) and to a point on the
-- animal's body (the game's handlers)
local WALKS = { ISWalkToTimedAction = true, ISWalkToTimedActionF = true }

-- True while the player's current action is one of the game's walks
local function walking(player)
    local q = ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[player]
    local cur = q and q.queue and q.queue[1]
    return type(cur) == "table" and WALKS[cur.Type] == true
end

-- The game's own action for each verb, the one its handler queues last (after the walk to the animal's side and,
-- for shears and food, the move to the hands)
local ACT_TYPE = { milk = "ISMilkAnimal", shear = "ISShearAnimal", feed = "ISFeedAnimalFromHand" }

-- Notes what the game is doing for the animal under way: whether its act itself got under way, and the last lead
-- action seen before it. When the queue empties with the act never begun, the game dropped it on the way (a walk
-- with no path, a tool that left the inventory, a stick move): the band says "Stopped" as for any cut, and the
-- console says which step it was, for a bug report.
local function noteCurrent(r, a)
    local q = ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[r.player]
    local cur = q and q.queue and q.queue[1]
    if type(cur) ~= "table" then return end
    if cur.Type == ACT_TYPE[r.verb] and (cur.animal == nil or cur.animal == a) then
        r.began = true
    elseif not r.began then
        r.lead = cur.Type
    end
end

-- The game calls this when the walk up reaches its square (not when a stick move, a cancel
-- or a missing path ends it first)
local function arrived(r)
    r.walked = true
end

-- Ask the game to say when the walk up just handed over reaches its square
local function onArrival(r)
    local q = ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[r.player]
    local w = q and q.queue and q.queue[#q.queue]
    if type(w) == "table" and WALKS[w.Type] and w.setOnComplete then w:setOnComplete(arrived, r) end
end

-- The game's milking just handed over for this animal (its ISMilkAnimal, queued last), or nil.
-- Read once at the hand-over, so nothing is looked up while it runs. (In multiplayer the
-- server does the filling, so the client's copy keeps naming the container handed over.)
local function milkingOf(player, a)
    local q = ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[player]
    local list = q and q.queue
    if not list then return nil end
    for k = #list, 1, -1 do
        local act = list[k]
        if type(act) == "table" and act.Type == "ISMilkAnimal" and act.animal == a then return act end
    end
    return nil
end

-- (the hoisted slot: the tick hook and AQ.start both reach it)
local onTick

-- why: the words the band shows; cause: what ended it, for QA's logs ("done", "stop", "undone",
-- "away", "stuck", "slow", "cut", "reach", "refused", "full", "dead", "replaced")
local function finish(why, cause)
    local r = AQ.run
    if not r then return end
    AQ.last = { verb = r.verb, done = r.done, total = #r.list, why = why, cause = cause, t = now(),
                began = r.began == true, lead = r.lead }
    AQ.run = nil
    if Events and Events.OnTick then Events.OnTick.Remove(onTick) end
end

--- True while the game runs faster than its walks allow (WalkToTimedAction:isValid wants getGameSpeed() <= 2):
--- every walk the run hands over is dropped at once, so a run cut then says why.
function AQ.tooFast()
    if type(getGameSpeed) ~= "function" then return false end
    local ok, sp = pcall(getGameSpeed)
    return ok and type(sp) == "number" and sp > 2
end

-- "Stopped after n of m", or, when the game's speed is what cut it, the same with the reason (a stop the
-- player asked for, or a new press, is no cut)
local ASKED = { stop = true, replaced = true }
local function stoppedWords(r, cause)
    if not ASKED[cause] and AQ.tooFast() then return ZeD.tr("UI_ZeD_Animals_RunFast", r.done, #r.list) end
    return ZeD.tr("UI_ZeD_Animals_RunStopped", r.done, #r.list)
end

-- Stop the run where it stands: the game's queue cleared (its own cancel, so nothing the run
-- handed over is left waiting), the animal under way let go, "Stopped after n of m".
local function halt(r, cause)
    if ISTimedActionQueue and ISTimedActionQueue.clear then pcall(ISTimedActionQueue.clear, r.player) end
    letGo(r.list[r.i])
    finish(stoppedWords(r, cause), cause)
end

-- Hand the run's verb for animal i to the game and wait for it
local function handOver(r, i)
    local a = r.list[i]
    r.i = i
    r.before = AD().getHunger(a) or 0
    -- (feed: when the food has run out the act says so, and the run ends with that reason)
    local ok, why, how, tool = AQ.act(r.verb, r.player, a, r.food)
    -- (the act's hand-over after the walk up failing: let go of the animal the walk held)
    if not ok and r.approach then letGo(a) end
    -- (the container the last animal filled was the last with room: say so, not the bare reason)
    if not ok and toolFull(r) then finish(fullWords(r), "full") return end
    if not ok then finish(why, "refused") return end
    r.phase, r.seen, r.ticks, r.stall, r.tool = "wait", false, 0, 0, tool
    r.approach, r.walked, r.milking, r.began, r.lead = how == "approach", false, nil, false, nil
    if r.approach then onArrival(r) elseif r.verb == "milk" then r.milking = milkingOf(r.player, a) end
    r.near, r.spent, r.lastT = distTo(r.player, a), 0, now()
end

-- Why the run should give up on the animal under way, or nil: the player got well away from it
-- (walked off with the stick cancels the queue on its own; a move by other means does not),
-- the queue holds actions with none running, or it has all taken too long
local function gaveUp(r, a)
    if walking(r.player) then
        -- (a walk ends itself on a stick move or when no path is left, and its route may swing
        -- wide of the animal, round a wall to the door: the distance counts from where it ends)
        r.near = nil
    else
        local d = distTo(r.player, a)
        if d then
            if not r.near or d < r.near then r.near = d end
            if d > math.max(r.near, 3) + AQ.AWAY then return "away" end
        end
    end
    local t = now()
    local dt = t - (r.lastT or t)
    r.lastT = t
    if dt > 0 and dt <= AQ.PAUSE_MS then r.spent = (r.spent or 0) + dt end
    if (r.spent or 0) > AQ.WAIT_MS then return "slow" end
    if queued(r.player) and not doingAction(r.player) then
        r.stall = (r.stall or 0) + 1
        if r.stall > AQ.STALL_TICKS then return "stuck" end
    else
        r.stall = 0
    end
    return nil
end

--- Start a run of "milk", "shear" or "feed" over the animals (the ones with nothing to give,
-- or not hungry, are skipped). food: for feed, the picked food's name (AQ.feedChoices).
-- Returns true, or false and the reason when no animal can be done.
function AQ.start(player, verb, animals, food)
    if not (player and (HAS[verb] or verb == "feed")) then return false, nil end
    if verb == "feed" and not food then return false, nil end
    local r = { player = player, verb = verb, food = food, suits = {}, i = 0, done = 0, phase = "next", seen = false, ticks = 0 }
    if verb == "feed" then
        local items = foodItems(player, food)
        for _, a in ipairs(animals) do
            if AQ.wantsFood(a) and firstTaken(items, a) then r.suits[a] = true end
        end
    end
    local list = {}
    for _, a in ipairs(animals) do
        if wants(r, a) then list[#list + 1] = a end
    end
    if #list == 0 then return false, (verb == "feed") and ZeD.tr("UI_ZeD_Animals_NeedFood") or nil end
    local ok, why = AQ.can(verb, player, list[1], food)
    if not ok then return false, why end
    -- (a run under way gives way to the new press: stopped where it stands, the game's queue
    -- cleared and its animal let go, or the new act would queue behind a milking that empties
    -- the whole queue when it ends)
    if AQ.run then halt(AQ.run, "replaced") end
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
    halt(r, "stop")
end

--- One step of the run (every tick while one is going).
function AQ.tick()
    local r = AQ.run
    if not r then return end
    local p = r.player
    if not p or (p.isDead and p:isDead()) then letGo(r.list[r.i]); finish(nil, "dead") return end
    if r.phase == "wait" then
        local a = r.list[r.i]
        local cause = gaveUp(r, a)
        if cause then halt(r, cause) return end
        local busy = queueBusy(p)
        if busy then
            r.seen = true
            if not r.approach then noteCurrent(r, a) end
            return
        end
        if not r.seen then
            r.ticks = r.ticks + 1
            if r.ticks < AQ.START_GRACE then return end
        end
        if r.approach then
            -- the walk up is over: hand the act itself over (once). A walk that reached its square
            -- hands it over wherever the animal stands now (the game's handler walks to its side
            -- from there); one that ended far off before it got there was cut short
            local d = distTo(p, a)
            if not r.walked and d and d > 4 then letGo(a); finish(stoppedWords(r, "cut"), "cut") return end
            handOver(r, r.i)
            if AQ.run == r and r.approach then
                ISTimedActionQueue.clear(p)
                letGo(a)
                finish(ZeD.tr("UI_ZeD_Animals_OutOfReach"), "reach")
            end
            return
        end
        -- the action is over (or never showed up). One left undone means the run was
        -- stopped: the player walked off, the animal ran, or the game turned it down
        local undone = leftUndone(r, a)
        if undone == "refill" then handOver(r, r.i) return end
        if undone == "full" then
            letGo(a)
            finish(fullWords(r), "full")
            return
        end
        if undone then
            letGo(a)
            if not r.began then
                print("[ZeD] Animals: the game dropped the " .. tostring(ACT_TYPE[r.verb]) .. " before it began; the last step was "
                    .. tostring(r.lead or "none"))
            end
            finish(stoppedWords(r, "undone"), "undone")
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
        finish(ZeD.tr("UI_ZeD_Animals_RunDone", r.done, #r.list), "done")
        return
    end
    handOver(r, i)
end

onTick = function()
    local ok, err = pcall(AQ.tick)
    if not ok then
        print("[ZeD] Animals: the run stopped on an error: " .. tostring(err))
        -- (the animal under way is let go and the run ends as a stop: one dropped here stayed held)
        local r = AQ.run
        if r then
            pcall(letGo, r.list and r.list[r.i])
            AQ.last = { verb = r.verb, done = r.done, total = r.list and #r.list or 0,
                why = ZeD.tr("UI_ZeD_Animals_RunStopped", r.done, r.list and #r.list or 0), cause = "error", t = now() }
        end
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
