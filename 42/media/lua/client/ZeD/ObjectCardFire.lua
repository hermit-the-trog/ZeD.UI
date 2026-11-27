-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardFire.lua
-- ============================================================================
-- OBJECT CARD: FIRES (HOOK_MAP row 12)
-- Client; one card kind for ZeD.ObjectCards (ObjectCards.lua draws the frame,
-- this def fills it).
-- One fire card for campfires, charcoal barbecues and fireplaces: fuel as time
-- left on a strip that ends at the sandbox maximum, Add fuel (what you carry
-- that burns and the time each piece adds), Light with (the methods vanilla
-- offers), what is on the fire with the item card's cooking reading, and
-- smouldering as a third state. Put out, Light and Add fuel are shown only
-- when they make sense and can be done (hidden actions). The propane barbecue
-- gets its own plate: the game's Jorge Foreguy cart grill in pixel art (the
-- shared plate template ZeD_Plate.lua draws it from PhysPx.lua): the burner
-- knobs' pointers, the flames' glow under the hood, the lid thermometer, the
-- tank gauge and the tank in the cart. The centre knob and the red igniter
-- light it or shut it off, the cart takes a tank in or gives it back. Under the
-- plate the hours of gas, then the grill's contents. Its Simple form (ZeD setup's
-- Devices row; ZeD.ObjectCardPlain in ObjectCardPower.lua) draws the same
-- readings and the same controls as plain rows: the gas left in large type,
-- the lid heat, the burner, the igniter and the tank with its gauge, each the
-- face's own zone (bbq:burner, bbq:ignite, bbq:tank).
-- Every action goes through vanilla's camping / barbecue handlers.
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"
require "ZeD/ObjectCardPower"   -- (the plain card's parts: ZeD.ObjectCardPlain)

local OC = ZeD.ObjectCards
local P = ZeD.Px
local PL = ZeD.Plate
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

local PROPANE_FULL_MIN = 1200   -- a full propane tank: 20 hours of gas
local GRILL_SETTLE_MS = 4000    -- the lid thermometer's needle creeps up after lighting, down after

local function campfireSystem() return CCampfireSystem and CCampfireSystem.instance or nil end

local function fuelMax()
    if getCampingFuelMax then
        local ok, v = pcall(getCampingFuelMax)
        if ok and v and v > 0 then return v end
    end
    local h = SandboxVars and SandboxVars.MaximumFireFuelHours or 8
    return h * 60
end

local function fireObjectOn(sq)
    if not sq then return nil end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and call(o, "isFireInteractionObject") then return o end
    end
    return nil
end

local function spriteIcon(iso)
    local tile = iso and call(iso, "getSpriteName")
    local tex = tile and getTexture(tile)
    if not tex then return nil end
    return call(tex, "splitIcon") or tex
end

local def = { id = "fire" }

--- Accepts a campfire (its Lua object or the IsoObject) or a barbecue /
--- fireplace IsoObject.
function def.resolve(player, obj)
    if not obj then return nil end
    local sq = call(obj, "getSquare")
    if not sq then return nil end
    local sys = campfireSystem()
    local lua = sys and sys:getLuaObjectOnSquare(sq)
    if lua then
        return { kind = "campfire", obj = lua, sq = sq, key = OC.keyOf(sq, "campfire") }
    end
    local fo = (call(obj, "isFireInteractionObject") and obj) or fireObjectOn(sq)
    if not fo then return nil end
    local kind = call(fo, "isPropaneBBQ") and "propane" or (instanceof(fo, "IsoFireplace") and "fireplace" or "charcoal")
    return { kind = kind, obj = fo, sq = sq, key = OC.keyOf(sq, "fire") }
end

function def.valid(t)
    if t.kind == "campfire" then
        local sys = campfireSystem()
        local lua = sys and sys:getLuaObjectOnSquare(t.sq)
        if not lua then return false end
        t.obj = lua
        return lua:getIsoObject() ~= nil
    end
    return t.obj ~= nil and t.obj:getObjectIndex() ~= -1
end

function def.nearby(player)
    local list = {}
    local sys = campfireSystem()
    OC.eachSquare(player, OC.LEASH, function(sq)
        local lua = sys and sys:getLuaObjectOnSquare(sq)
        if lua then
            list[#list + 1] = { kind = "campfire", obj = lua, sq = sq, key = OC.keyOf(sq, "campfire") }
        else
            local fo = fireObjectOn(sq)
            if fo then list[#list + 1] = def.resolve(player, fo) end
        end
    end)
    return OC.sortTargets(list)
end

-- ---------------------------------------------------------------------------
-- REFRESH
-- ---------------------------------------------------------------------------
local function iso(t) return t.kind == "campfire" and t.obj:getIsoObject() or t.obj end

local keptTinder   -- (hoisted: the fuel rows ask it before its body below)
local plainFuel

local function fuelRows(info, current, max, player)
    local rows = {}
    local list = {}
    local durOf = {}      -- each item's burn time worked out once, not in every comparison (beast W34)
    local plainOf = {}
    for _, it in ipairs(info.fuelList or {}) do
        list[#list + 1] = it
        durOf[it] = ISCampingMenu.getFuelDurationForItem(it) or 0
        plainOf[it] = plainFuel(it)
    end
    -- (QA FI2, Nov 26 2026) plain fuel first, the longest burn first; what the player keeps comes last
    table.sort(list, function(a, b)
        if plainOf[a] ~= plainOf[b] then return plainOf[a] end
        return durOf[a] > durOf[b]
    end)
    local totalN, totalDur, plainTypes = 0, 0, 0
    for _, it in ipairs(list) do
        local count = info.itemCount[it:getName()] or 1
        local dur = durOf[it]
        -- vanilla's cap loop: as many of this type as the fire still holds
        local fitN = count
        while current + dur * fitN > max and fitN > 1 do fitN = fitN - 1 end
        -- (QA FI2, Nov 26 2026) the all-types total counts plain fuel only, as All fuel takes only that
        if plainOf[it] then
            plainTypes = plainTypes + 1
            totalN = totalN + count
            totalDur = totalDur + dur * count
        end
        rows[#rows + 1] = {
            item = it, fullType = it:getFullType(), name = it:getName() .. (count > 1 and (" (" .. tostring(count) .. ")") or ""),
            baseName = it:getName(),
            tex = it:getTex(), where = OC.whereOf(it, player), dur = dur, count = count,
            fits = current + dur <= max,
            fitN = fitN, allFits = (fitN == count),
            kept = not plainOf[it],
        }
    end
    -- the all-types total (vanilla's "All (N)" across the list, plain fuel only)
    rows.totalN, rows.totalDur, rows.plainTypes = totalN, totalDur, plainTypes
    return rows
end

-- (QA FI3, Nov 26 2026) the game sorts its lists by name; the card does too, so the lighter and the matches
-- come in the same order as in its menu
local function byName(a, b)
    local x, y = tostring(call(a, "getDisplayName") or ""), tostring(call(b, "getDisplayName") or "")
    if string.sort then return not string.sort(x, y) end   -- (Kahlua's, as vanilla sorts)
    return x < y
end

-- (QA FI3, Nov 26 2026) tinder the player would not want burnt: a skill book, anything that teaches a recipe,
-- a map, or a favorite. The game lists them like any paper, so the card puts them last and never picks them
-- when Light is pressed.
keptTinder = function(item)
    if call(item, "isFavorite") == true then return true end
    if call(item, "IsMap") == true or (instanceof and instanceof(item, "MapItem")) then return true end
    local sk = call(item, "getSkillTrained")
    if sk ~= nil and tostring(sk) ~= "" then return true end
    if call(item, "getDisplayCategory") == "SkillBook" then return true end
    local rec = call(item, "getTeachedRecipes")
    if rec ~= nil and call(rec, "isEmpty") == false then return true end
    return false
end

-- (QA FI2, Nov 26 2026) All fuel burnt a skill book out of the crate beside him: the game's fuel list holds
-- anything that burns (books, maps, clothes, bags, tents, bats, plush toys). The bulk adds take only plain
-- fuel: a kind the game names in its fuel or tinder lists (planks, logs, sticks, paper, napkins), or wood and
-- junk by their category (firewood, handles, splinters, broken chair legs). Never anything kept (above), a
-- memento, a thing the player named, reading the game does not name, clothes or bags. Kept things still have
-- their own row and go on one at a time, on purpose.
local PLAIN_FUEL_CATS = { Material = true, MaterialWeapon = true, Junk = true, JunkWeapon = true }
plainFuel = function(item)
    if keptTinder(item) then return false end
    if call(item, "isCustomName") == true then return false end
    if call(item, "getDisplayCategory") == "Memento" then return false end
    if ItemTag and ItemTag.IS_MEMENTO and call(item, "hasTag", ItemTag.IS_MEMENTO) == true then return false end
    local ty = call(item, "getType")
    if ty and ((campingFuelType and campingFuelType[ty]) or (campingLightFireType and campingLightFireType[ty])) then return true end
    if call(item, "IsLiterature") == true or call(item, "IsClothing") == true then return false end
    if instanceof and instanceof(item, "InventoryContainer") then return false end
    return PLAIN_FUEL_CATS[tostring(call(item, "getDisplayCategory") or "")] == true
end

-- (QA FI2, Nov 26 2026) the plain fuel in reach, in the game's container order (the inventory, its bags, then
-- what is around): every one, or only those of one type
local function plainFuelItems(player, fullType)
    local out = {}
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    for i = 0, (containers and containers:size() or 0) - 1 do
        local items = containers:get(i):getItems()
        for j = 0, items:size() - 1 do
            local it = items:get(j)
            if (fullType == nil or it:getFullType() == fullType) and ISCampingMenu.isValidFuel(it) and plainFuel(it) then
                out[#out + 1] = it
            end
        end
    end
    return out
end

-- (QA FI2, Nov 26 2026) the game's bulk add (its addFuel is local to ISCampingMenu): bring the pieces to the
-- inventory, walk to the fire, one add action a piece (a use for each use left). It stops at the sandbox
-- maximum across the whole batch, where the game checks only per piece. single: one action, as the game's
-- one-piece add queues.
local function queueFuel(p, target, items, timedAction, currentFuel, count, single)
    local n = #items
    if count and count < n then n = count end
    if n <= 0 then return end
    local batch = ArrayList.new()
    for i = 1, n do batch:add(items[i]) end
    ISCampingMenu.toPlayerInventory(p, batch)
    if not ISCampingMenu.walkToCampfire(p, target:getSquare()) then return end
    local fuel, cap = currentFuel or 0, fuelMax()
    for i = 1, n do
        local it = items[i]
        if p:isEquipped(it) then ISTimedActionQueue.add(ISUnequipAction:new(p, it, 50)) end
        local amt = ISCampingMenu.getFuelDurationForItem(it)
        for _ = 1, (single and 1 or ISCampingMenu.getFuelItemUses(it)) do
            if fuel + amt > cap then return end
            fuel = fuel + amt
            ISTimedActionQueue.add(timedAction:new(p, target, it, amt))
        end
    end
end

-- (QA FI3, Nov 26 2026) 0: the game's own named tinder (paper, sheets, twigs, napkins); 1: anything else
-- that is not reading; 2: books, magazines and newspapers; 3: what the player keeps
local function tinderRank(item)
    if keptTinder(item) then return 3 end
    local ty = call(item, "getType")
    if (campingLightFireType and ty and campingLightFireType[ty]) or call(item, "hasTag", ItemTag and ItemTag.IS_FIRE_TINDER) == true then return 0 end
    if call(item, "IsLiterature") == true then return 2 end
    return 1
end

-- The lighting methods vanilla offers (one row per tinder, the first starter by name). Petrol first, then paper
-- and plain tinder, the notched plank, books, and last what the player keeps (QA FI3, Nov 26 2026).
local function lightRows(info, hasFuel, player)
    local rows = {}
    local starters = {}
    for _, s in ipairs(info.starters or {}) do starters[#starters + 1] = s end
    table.sort(starters, byName)
    local starter = starters[1]
    if starter and hasFuel and info.petrol then
        rows[#rows + 1] = { method = "petrol", name = info.petrol:getName(), with = starter:getName(),
            tex = info.petrol:getTex(), where = OC.whereOf(info.petrol, player), starter = starter, petrol = info.petrol }
    end
    local tinder, rankOf = {}, {}
    if starter then
        for _, v in ipairs(info.tinder or {}) do
            tinder[#tinder + 1] = v
            rankOf[v] = tinderRank(v)
        end
        table.sort(tinder, function(a, b)
            if rankOf[a] ~= rankOf[b] then return rankOf[a] < rankOf[b] end
            return byName(a, b)
        end)
    end
    local function addTinder(lo, hi)
        for _, v in ipairs(tinder) do
            local rk = rankOf[v]
            if rk >= lo and rk <= hi then
                local count = info.itemCount[v:getName()] or 1
                rows[#rows + 1] = { method = "tinder", name = v:getName() .. (count > 1 and (" (" .. tostring(count) .. ")") or ""), with = starter:getName(),
                    tex = v:getTex(), where = OC.whereOf(v, player), starter = starter, tinderType = v:getFullType(),
                    dur = ISCampingMenu.getFuelDurationForItem(v), kept = (rk == 3) }
            end
        end
    end
    addTinder(0, 1)
    if info.percedWood then
        local stick = info.stick or info.branch
        local endurance = player:getStats():get(CharacterStat.ENDURANCE)
        local ok = stick ~= nil and hasFuel and endurance > 0
        local need = nil
        if not stick then need = ZeD.tr("UI_ZeD_Fire_NeedsStick")
        elseif not hasFuel then need = ZeD.tr("UI_ZeD_Fire_NeedsFuel")
        elseif endurance <= 0 then need = ZeD.tr("UI_ZeD_Fire_TooTired") end
        rows[#rows + 1] = { method = "kindle", name = info.percedWood:getName(), with = stick and stick:getName() or nil,
            tex = info.percedWood:getTex(), where = OC.whereOf(info.percedWood, player), percedWood = info.percedWood, stick = stick,
            enabled = ok, need = need }
    end
    addTinder(2, 3)
    return rows
end

-- (QA FI3, Nov 26 2026) the row Light goes to, so a second A lights with it: the first that can be used and is
-- not kept; nil when only kept tinder is left (each still has its own Light button further down)
local function firstSafeLight(rows)
    for i, r in ipairs(rows) do
        if r.enabled ~= false and not r.kept then return i end
    end
    return nil
end

-- A propane tank's gas, 0 to 1 (a tank on the floor beside the grill is read through its item).
local function tankUses(tank)
    local it = tank
    if instanceof and instanceof(tank, "IsoWorldInventoryObject") then it = call(tank, "getItem") end
    return tonumber(call(it, "getCurrentUsesFloat")) or 0
end

-- (QA FI6, Nov 26 2026) the tank the card would put in: the fullest one in the same places the game looks (the
-- inventory and its bags, the floor on the eight squares round the grill); the game's own pick when that
-- search finds nothing, so the card never offers less than its menu does
local function fullestTank(player, bbq)
    local best = ISBBQMenu.FindPropaneTank(player, bbq)
    local bestU = best and tankUses(best) or 0
    local inv = call(player, "getInventory")
    local list = inv and call(inv, "getAllTypeRecurse", "Base.PropaneTank")
    for i = 0, (list and list:size() or 0) - 1 do
        local it = list:get(i)
        local u = tankUses(it)
        if u > bestU then best, bestU = it, u end
    end
    local cell = getCell and getCell()
    local bsq = call(bbq, "getSquare")
    if cell and bsq then
        for y = bbq:getY() - 1, bbq:getY() + 1 do
            for x = bbq:getX() - 1, bbq:getX() + 1 do
                local sq = cell:getGridSquare(x, y, bbq:getZ())
                if sq and not sq:isSomethingTo(bsq) then
                    local wobs = sq:getWorldObjects()
                    for i = 0, wobs:size() - 1 do
                        local o = wobs:get(i)
                        local it = call(o, "getItem")
                        if it and call(it, "getFullType") == "Base.PropaneTank" then
                            local u = tankUses(it)
                            if u > bestU then best, bestU = o, u end
                        end
                    end
                end
            end
        end
    end
    if best and bestU <= 0 then return nil end
    return best
end

-- Puts the fullest tank in reach in the cart (vanilla's insert; a tank already in comes out onto the ground).
local function insertTank(p, tt)
    local tank = fullestTank(p, tt.obj)
    if tank then ISBBQMenu.onInsertPropaneTank(nil, p:getPlayerNum(), tt.obj, tank) end
end

local function refreshPropane(t, player)
    local o = t.obj
    local d = { propane = true }
    d.lit = o:isLit()
    d.tank = o:hasPropaneTank()
    d.hasFuel = o:hasFuel()
    d.fuel = o:getFuelAmount() or 0
    d.name = call(o, "getTileName") or ZeD.tr("UI_ZeD_Fire_PropaneBBQ")
    d.tex = spriteIcon(o)
    d.container = call(o, "getContainer")
    d.spare = fullestTank(player, o)
    -- (QA FI6, Nov 26 2026) the game's Insert takes the old tank out and leaves it on the ground in the same
    -- action, so with a tank in, a fuller one in reach is a one-step swap
    d.swap = d.tank and d.spare ~= nil and tankUses(d.spare) > math.min(1, d.fuel / PROPANE_FULL_MIN) + 0.01
    t.d = d
    local verbs = {}
    local toggle = function(p, tt) ISBBQMenu.onToggle(nil, p:getPlayerNum(), tt.obj) end
    t.toggle = d.hasFuel and toggle or nil
    verbs[#verbs + 1] = { id = "power", label = d.lit and getText("ContextMenu_Turn_Off") or getText("ContextMenu_Turn_On"), primary = d.hasFuel, enabled = d.hasFuel, run = toggle,
        needs = ZeD.tr("UI_ZeD_Fire_NeedsGas"), hint = ZeD.tr("UI_ZeD_Fire_HintOn"),
        help = ZeD.tr(d.lit and "UI_ZeD_Fire_HelpOff" or "UI_ZeD_Fire_HelpOn") }
    -- no tank in: insert one; a tank in: only a fuller one is worth the swap (the main verb when the one in is empty)
    verbs[#verbs + 1] = { id = "insert", label = ZeD.tr("UI_ZeD_Fire_InsertTank"), enabled = d.spare ~= nil, primary = (not d.hasFuel) and d.spare ~= nil,
        sensible = (not d.tank) or d.swap, needs = ZeD.tr("UI_ZeD_Fire_NeedsSpareTank"), hint = ZeD.tr("UI_ZeD_Fire_HintTank"),
        help = ZeD.tr(d.swap and "UI_ZeD_Fire_HelpSwap" or "UI_ZeD_Fire_HelpInsert"),
        run = function(p, tt) insertTank(p, tt) end }
    verbs[#verbs + 1] = { id = "remove", label = ZeD.tr("UI_ZeD_Fire_RemoveTank"), enabled = d.tank, sensible = d.tank,
        help = ZeD.tr("UI_ZeD_Fire_HelpRemove"),
        run = function(p, tt) ISBBQMenu.onRemovePropaneTank(nil, p:getPlayerNum(), tt.obj) end }
    t.verbs = verbs
end

-- Vanilla's getNearbyFuelInfo walks every item in reach (its own menu runs it once per right-click), so the card keeps
-- the answer on t and rescans only every 1.5 s, when the player's square changes, or after a card action
-- (t._fuelAt = nil) (beast W34)
local function fuelInfo(t, player)
    local now = getTimestampMs()
    local sq = player:getCurrentSquare()
    if not t._fuelInfo or not t._fuelAt or now - t._fuelAt > 1500 or t._fuelSq ~= sq then
        t._fuelInfo = ISCampingMenu.getNearbyFuelInfo(player)
        t._fuelAt, t._fuelSq = now, sq
    end
    return t._fuelInfo
end

-- (QA FI5, Nov 26 2026) the game's take-apart drops what is on the fire to the ground, lit or not, and gives
-- 3 stones, so the question names what will drop (the first three by name, then how many more); with nothing
-- on it, the old question. UI_ZeD_Fire_ConfirmTakeApart ("what is on it drops", never named anything) stays
-- unused in the language files: UI_ZeD_Fire_QTakeApartDrop says it and names the things.
local function takeApartQuestion(container)
    local items = container and call(container, "getItems")
    local n = items and items:size() or 0
    if n <= 0 then return ZeD.tr("UI_ZeD_Fire_QTakeApart") end
    local names = {}
    for i = 0, math.min(n, 3) - 1 do
        local it = items:get(i)
        names[#names + 1] = tostring(call(it, "getDisplayName") or call(it, "getName") or "?")
    end
    local list = table.concat(names, ", ")
    if n > 3 then list = list .. " (+" .. tostring(n - 3) .. ")" end
    return ZeD.tr("UI_ZeD_Fire_QTakeApartDrop", list)
end

function def.refresh(t, player)
    if t.kind == "propane" then return refreshPropane(t, player) end
    local d = {}
    local io = iso(t)
    if t.kind == "campfire" then
        pcall(function() t.obj:updateFromIsoObject() end)
        d.fuel = t.obj.fuelAmt or 0
        d.lit = t.obj.isLit == true
        d.smoulder = false
    else
        d.fuel = t.obj:getFuelAmount() or 0
        d.lit = t.obj:isLit()
        d.smoulder = (not d.lit) and (call(t.obj, "isSmouldering") == true)
    end
    d.max = fuelMax()
    d.name = (io and call(io, "getTileName")) or (t.kind == "campfire" and ZeD.tr("IGUI_Campfire_Campfire") or ZeD.tr("UI_ZeD_Fire_Fire"))
    d.tex = spriteIcon(io)
    d.container = io and call(io, "getContainer")
    local info = fuelInfo(t, player)
    d.fuelRows = fuelRows(info, d.fuel, d.max, player)
    d.lightRows = (not d.lit) and lightRows(info, d.fuel > 0, player) or {}
    t.d = d

    local addAction = (t.kind == "campfire") and ISAddFuelAction or ISBBQAddFuel
    t.addFuel = function(p, row)
        t._fuelAt = nil   -- rescan after an action (beast W34)
        -- (QA FI2, Nov 26 2026) a plain row takes a plain one of its type (a note he named shares its type with
        -- blank ones); a kept row is the player's own pick and goes through the game's add as before
        if not row.kept then
            local one = plainFuelItems(p, row.fullType)[1]
            if one then queueFuel(p, t.obj, { one }, addAction, d.fuel, 1, true) end
            return
        end
        ISCampingMenu.onAddFuel(p, t.obj, row.fullType, addAction, d.fuel)
    end
    -- vanilla's bulk adds: every one of a type that fits (or all that fit),
    -- and everything on the list. The capped count is passed explicitly
    -- because vanilla only checks the cap per item, not across the batch.
    -- (QA FI2, Nov 26 2026) both take plain fuel only (plainFuel), never a kept thing from a crate; a kept
    -- row has no bulk button (fuelBody), so its own Add is the one way it goes on
    t.addFuelMany = function(p, row)
        t._fuelAt = nil
        if row.kept then return end
        queueFuel(p, t.obj, plainFuelItems(p, row.fullType), addAction, d.fuel, (not row.allFits) and row.fitN or nil)
    end
    t.addFuelAll = function(p)
        t._fuelAt = nil
        queueFuel(p, t.obj, plainFuelItems(p, nil), addAction, d.fuel, nil)
    end
    local petrolA = (t.kind == "campfire") and ISLightFromPetrol or ISBBQLightFromPetrol
    local tinderA = (t.kind == "campfire") and ISLightFromLiterature or ISBBQLightFromLiterature
    local kindleA = (t.kind == "campfire") and ISLightFromKindle or ISBBQLightFromKindle
    t.light = function(p, row)
        t._fuelAt = nil
        if row.method == "petrol" then
            ISCampingMenu.onLightFromPetrol(p, row.starter, row.petrol, t.obj, petrolA)
        elseif row.method == "tinder" then
            ISCampingMenu.onLightFromLiterature(p, row.tinderType, row.starter, t.obj, tinderA)
        elseif row.method == "kindle" then
            ISCampingMenu.onLightFromKindle(p, row.percedWood, row.stick, t.obj, kindleA)
        end
    end

    local verbs = {}
    local full = d.fuel >= d.max
    -- (QA FI2, Nov 26 2026) Add fuel goes to the first plain row that fits, never a kept one; with only kept
    -- things in reach it waits and says so (each kept row keeps its own Add button)
    local safeFuel, keptFits = nil, false
    for i, r in ipairs(d.fuelRows) do
        if r.fits and not r.kept and not safeFuel then safeFuel = i end
        if r.fits and r.kept then keptFits = true end
    end
    local anyFits = safeFuel ~= nil
    local safeLight = firstSafeLight(d.lightRows)
    local canLight = safeLight ~= nil
    local onlyKept = false
    for _, r in ipairs(d.lightRows) do if r.enabled ~= false and r.kept then onlyKept = not canLight end end
    local fuelOK = (not full) and anyFits
    -- a full fire takes no more, a burning one is not lit again, a dead one is not put out:
    -- those verbs are gone (sensible = false); the rest wait for what they need
    verbs[#verbs + 1] = { id = "fuel", label = getText("ContextMenu_GeneratorAddFuel"), enabled = fuelOK, primary = fuelOK and (d.lit or not canLight),
        jump = "fire:fuel:" .. tostring(safeFuel or 1),
        sensible = not full, needs = ZeD.tr(keptFits and "UI_ZeD_Fire_NeedsPlainFuel" or "UI_ZeD_Fire_NeedsFuelItems"), hint = ZeD.tr("UI_ZeD_Fire_HintFuel"),
        help = ZeD.tr("UI_ZeD_Fire_HelpFuel") }
    verbs[#verbs + 1] = { id = "out", label = ZeD.tr("UI_ZeD_Fire_PutOut"), enabled = d.lit, sensible = d.lit,
        help = ZeD.tr("UI_ZeD_Fire_HelpOut"),
        run = function(p, tt)
            if tt.kind == "campfire" then ISCampingMenu.onPutOutCampfire(nil, p, tt.obj)
            else ISBBQMenu.onExtinguish(nil, p:getPlayerNum(), tt.obj) end
        end }
    -- (QA FI3, Nov 26 2026) Light goes to the first row that burns nothing the player keeps, not row 1
    -- (QA FI10, Nov 26 2026) the NEEDS line names what is missing: tinder lights a fire with no fuel on it
    -- (ISCampingMenu.doLightFireOption), so with paper and no starter it is the lighter, not fuel; fuel on
    -- the fire is named only when petrol is the one way left
    local hasStarter = info.starters ~= nil and #info.starters > 0
    local lightNeeds = "UI_ZeD_Fire_NeedsTinder"
    if not hasStarter then lightNeeds = "UI_ZeD_Fire_NeedsLighter"
    elseif onlyKept then lightNeeds = "UI_ZeD_Fire_NeedsTinder"
    elseif info.petrol and d.fuel <= 0 then lightNeeds = "UI_ZeD_Fire_NeedsFuelFirst" end
    verbs[#verbs + 1] = { id = "light", label = getText("ContextMenu_Light"), enabled = (not d.lit) and canLight, primary = (not d.lit) and canLight,
        jump = "fire:light:" .. tostring(safeLight or 1),
        sensible = not d.lit, needs = ZeD.tr(lightNeeds),
        hint = ZeD.tr("UI_ZeD_Fire_HintLight"), help = ZeD.tr("UI_ZeD_Fire_HelpLight") }
    if t.kind == "campfire" then
        verbs[#verbs + 1] = { id = "take", label = ZeD.tr("UI_ZeD_Fire_TakeApart"), danger = true,
            confirm = takeApartQuestion(d.container), help = ZeD.tr("UI_ZeD_Fire_HelpTake"),
            run = function(p, tt) ISCampingMenu.onRemoveCampfire(nil, p, tt.obj) end }
    end
    t.verbs = verbs
end

function def.title(t) return t.d and t.d.name or ZeD.tr("UI_ZeD_Fire_Fire") end
function def.icon(t) return t.d and t.d.tex or nil end
--- The state tag: its words, and the colour of the square mark before them (none for a plain tag).
function def.pill(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if d.propane then
        if d.lit then return OC.cap(ZeD.tr("IGUI_Fireplace_Burning")), T.positive end
        if not d.tank then return ZeD.tr("Tooltip_NoTank"), T.textDim end
        return ZeD.tr("UI_Off"), T.textDim
    end
    if d.lit then return OC.cap(ZeD.tr("IGUI_Fireplace_Burning")), T.positive end
    if d.smoulder then return OC.cap(ZeD.tr("IGUI_Fireplace_Smouldering")), T.warning end
    return ZeD.tr("UI_ZeD_Fire_PillOut"), T.textDim
end

-- ---------------------------------------------------------------------------
-- BODY
-- ---------------------------------------------------------------------------
local function drawFuelStrip(card, x, y, w, d)
    local T, tm = ZeD.T, ZeD.TM
    local y0 = y
    local maxH = d.max / 60
    -- big readout: time left + "of fuel | holds 8 h"
    local bigPx = 26
    local bw = UI.big(card, OC.hm(d.fuel), x, y, bigPx, T.text) or 0
    local bigH = math.floor(T.px(bigPx) * 1.0)
    local small = ZeD.textCase(ZeD.tr("UI_ZeD_Fire_OfFuelHolds", math.floor(maxH + 0.5)))
    local f1 = T.fontF1
    card:drawText(small, x + bw + T.px(8), y + bigH - tm:getFontHeight(f1), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f1)
    y = y + bigH + T.px(8)
    -- the fuel as one framed strip to the sandbox maximum: burning amber; smouldering half
    -- amber; out, the fuel waiting, muted amber
    local fillC = d.lit and T.warning or ZeD.colorBlend(T.warning, T.surf2, d.smoulder and 0.35 or 0.6)
    local bh = T.fillBarH
    -- (ten segments; the help line the time left, as the readout says it: "Fuel 2h 30m")
    if ZeD.Atoms.drawFillBar(card, x, y, w, d.fuel / math.max(1, d.max), false, fillC, bh) then
        ZeD.Help.set(card, ZeD.tr("UI_ZeD_Bar_Help", ZeD.tr("IGUI_GlobalObject_Fuel"), OC.hm(d.fuel)))
    end
    y = y + bh + T.px(4)
    -- scale: Now ... Full with even hour marks between
    local f5 = T.fontF5
    local dc = T.textDim
    card:drawText(ZeD.textCase(ZeD.tr("UI_ZeD_Fire_ScaleNow")), x, y, dc.r, dc.g, dc.b, dc.a or 1, f5)
    ZeD.Atoms.drawTextRight(card, ZeD.textCase(ZeD.tr("UI_ZeD_Fire_ScaleFull")), x + w, y, f5, dc)
    local marks = 3
    for k = 1, marks do
        local hrs = maxH * k / (marks + 1)
        local lbl = ZeD.textCase(ZeD.tr("UI_ZeD_Fire_ScaleHours", math.floor(hrs + 0.5)))
        local lw = tm:MeasureStringX(f5, lbl)
        card:drawText(lbl, x + math.floor(w * k / (marks + 1) - lw / 2), y, dc.r, dc.g, dc.b, dc.a or 1, f5)
    end
    y = y + tm:getFontHeight(f5)
    return y - y0
end

local function fireBody(card, x, y, w, t, player)
    local T = ZeD.T
    local d = t.d
    local y0 = y
    local gap = T.px(8)
    y = y + drawFuelStrip(card, x, y, w, d) + gap

    if not d.lit and #d.lightRows > 0 then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Fire_LightWith"), "")
        for i, r in ipairs(d.lightRows) do
            local rr = r
            y = y + UI.pick(card, x, y, w, {
                tex = r.tex, name = r.name,
                gain = r.dur and ("+" .. OC.hm(r.dur)) or nil,
                tag = r.need or r.with,
                button = getText("ContextMenu_Light"), fid = "fire:light:" .. i, enabled = r.enabled ~= false,
                help = ZeD.tr("UI_ZeD_Fire_HelpLightWith", r.name),
                run = function(c, p) t.light(p, rr) end,
            })
        end
        y = y + gap
    end

    if #d.fuelRows > 0 then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Fire_AddFromBags"), ZeD.tr("UI_ZeD_Fire_Adds"))
        local rows = d.fuelRows
        -- one button for all the plain fuel, when more than one kind and more than one piece
        -- are in reach and the whole lot fits (vanilla's "All", without what the player keeps: QA FI2, Nov 26 2026;
        -- UI_ZeD_Fire_HelpAddEvery, "everything on the list", stays unused in the language files)
        if (rows.plainTypes or 0) > 1 and (rows.totalN or 0) > 1 then
            local lotFits = d.fuel + rows.totalDur <= d.max
            y = y + UI.pick(card, x, y, w, {
                tex = rows[1].tex, name = ZeD.tr("UI_ZeD_Fire_AllFuel", rows.totalN),
                gain = "+" .. OC.hm(rows.totalDur),
                tag = (not lotFits) and ZeD.tr("UI_ZeD_Fire_TagFull") or nil,
                button = ZeD.tr("ContextMenu_AddAll"), fid = "fire:fuelall", enabled = lotFits,
                help = ZeD.tr("UI_ZeD_Fire_HelpAddPlain"),
                run = function(c, p) t.addFuelAll(p) end,
            })
        end
        for i, r in ipairs(rows) do
            local rr = r
            local gain = r.count > 1 and ZeD.tr("UI_ZeD_Fire_GainEach", OC.hm(r.dur)) or ("+" .. OC.hm(r.dur))
            y = y + UI.pick(card, x, y, w, {
                tex = r.tex, name = r.name, where = r.where, gain = gain,
                tag = (not r.fits) and ZeD.tr("UI_ZeD_Fire_TagFull") or nil,
                button = getText("UI_btn_add"), fid = "fire:fuel:" .. i, enabled = r.fits,
                help = ZeD.tr("UI_ZeD_Fire_HelpAdd", r.baseName),
                run = function(c, p) t.addFuel(p, rr) end,
            })
            -- several of this type: add all of them, or all that fit (plain fuel only: a kept thing goes on
            -- one at a time, QA FI2, Nov 26 2026)
            if r.fitN > 1 and not r.kept then
                y = y + UI.pick(card, x, y, w, {
                    tex = r.tex,
                    name = ZeD.tr(r.allFits and "UI_ZeD_Fire_NameAll" or "UI_ZeD_Fire_NameAllThatFit", r.baseName, r.fitN),
                    gain = "+" .. OC.hm(r.dur * r.fitN),
                    button = ZeD.tr("ContextMenu_AddAll"), fid = "fire:fuelmany:" .. i, enabled = r.fits,
                    help = ZeD.tr("UI_ZeD_Fire_HelpAddMany", r.baseName),
                    run = function(c, p) t.addFuelMany(p, rr) end,
                })
            end
        end
        y = y + gap
    end

    local items = d.container and call(d.container, "getItems")
    local n = items and items:size() or 0
    if n > 0 then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Fire_OnTheFire"), tostring(n))
        y = y + UI.cookRows(card, x, y, w, d.container, d.lit)
    end
    return y - y0
end

-- the grill's plate: what its live parts read (the thermometer settles, it has weight)
local function grillState(t, d)
    local st = { lit = d.lit, tank = d.tank, tankF = d.tank and math.max(0, math.min(1, d.fuel / PROPANE_FULL_MIN)) or 0 }
    local target = d.lit and 0.74 or 0.04
    local now = getTimestampMs()
    local cur = t._grillT
    if cur == nil then cur = target end
    local dt = t._grillMs and math.max(0, math.min(250, now - t._grillMs)) or 0
    cur = cur + (target - cur) * (dt / (GRILL_SETTLE_MS + dt))
    t._grillT, t._grillMs = cur, now
    st.grillTemp = cur
    return st
end
local function plateTex(name) return P.tex(ZeD.PhysPx.texdir .. name .. ".png") end

-- the grill's controls (the face's and the plain card's): the cart takes a tank or gives it back; the igniter
-- lights the burner (t.toggle: vanilla's toggle, nil without gas)
-- (QA FI6, Nov 26 2026: an empty tank in and a full one in reach, the key swaps them in one step, as the card's
-- main verb does, rather than taking the empty one out first)
local function tankSwaps(tt)
    return tt.obj:hasPropaneTank() and call(tt.obj, "hasFuel") ~= true and tt.d ~= nil and tt.d.spare ~= nil
end
local function tankFn(p, tt)
    if tt.obj:hasPropaneTank() and not tankSwaps(tt) then ISBBQMenu.onRemovePropaneTank(nil, p:getPlayerNum(), tt.obj)
    else insertTank(p, tt) end
end
-- (Nov 15 2026, QA's beta 16 pass, p336: the burner and the igniter ask the grill itself for gas when pressed, not
-- the card's last read of it, so a tank that just went in lights at once rather than after the next refresh)
local function liveToggle(p, tt)
    if call(tt.obj, "hasFuel") == true then ISBBQMenu.onToggle(nil, p:getPlayerNum(), tt.obj) end
end
local function ignite(p, tt) if not tt.obj:isLit() then liveToggle(p, tt) end end

-- the gas left as hours and minutes ("12:30"; "0:00" with no tank)
local function gasText(d)
    if not d.tank then return "0:00" end
    local gm = math.floor(d.fuel % 60)
    return tostring(math.floor(d.fuel / 60)) .. ":" .. (gm < 10 and "0" or "") .. tostring(gm)
end

ZeD.trDefaults({
    UI_ZeD_PlainCard_Burner = "Burner",
    UI_ZeD_PlainCard_Igniter = "Igniter",
    UI_ZeD_PlainCard_LidHeat = "Lid heat",
})

-- The Simple form: the gas left in large type; then the face top to bottom: the lid thermometer, the burner knob, the
-- igniter, the tank in the cart with its gauge. The controls are the face's zones (same fids, runs and help).
local function propanePlain(card, x, y, w, t)
    local T = ZeD.T
    local d = t.d
    local OP = ZeD.ObjectCardPlain
    local y0 = y
    local st = grillState(t, d)
    y = y + OP.readout(card, x, y, w, { cols = {
        { label = ZeD.tr("UI_ZeD_Fire_GasLeft"), big = gasText(d), unit = ZeD.tr("UI_ZeD_PlainCard_HrsUnit"), live = d.tank },
    } })
    y = y + OP.row(card, x, y, w, { label = ZeD.tr("UI_ZeD_PlainCard_LidHeat"), share = st.grillTemp,
        shareC = d.lit and T.warning or nil })
    y = y + OP.row(card, x, y, w, {
        label = ZeD.tr("UI_ZeD_PlainCard_Burner"),
        value = d.lit and OC.cap(ZeD.tr("IGUI_Fireplace_Burning")) or ZeD.tr("UI_Off"), dot = d.lit and T.positive or nil,
        ctl = { kind = "switch", fid = "bbq:burner", on = d.lit, help = ZeD.tr("UI_ZeD_Fire_HelpBurner"),
                run = t.toggle and function(cc, p) t.toggle(p, t) end or nil },
    })
    y = y + OP.row(card, x, y, w, {
        label = ZeD.tr("UI_ZeD_PlainCard_Igniter"),
        ctl = { kind = "button", fid = "bbq:ignite", word = getText("ContextMenu_Light"), help = ZeD.tr("UI_ZeD_Fire_HelpIgnite"),
                run = (not d.lit and t.toggle) and function(cc, p) ignite(p, t) end or nil },
    })
    y = y + OP.row(card, x, y, w, {
        label = ZeD.tr("UI_ZeD_Fire_Tank"),
        value = d.tank and ZeD.tr("UI_ZeD_Fire_TankIn") or ZeD.tr("IGUI_None"),
        share = st.tankF, shareLabel = ZeD.tr("UI_ZeD_Fire_Tank"),
        ctl = { kind = "button", fid = "bbq:tank", word = ZeD.tr((d.tank and not (d.spare and not d.hasFuel)) and "UI_ZeD_Fire_RemoveTank" or "UI_ZeD_Fire_InsertTank"),
                help = ZeD.tr("UI_ZeD_Fire_HelpTankPart"), run = (d.tank or d.spare) and function(cc, p) tankFn(p, t) end or nil },
    })
    return y - y0
end

--- The propane grill's face on its own at (px0, y), zoom k (des: the plate picked), its controls stamped as the
--- card's zones. The card draws it (propaneBody below) and so does the face's pop-out, standing in for the card
--- (FacePop.lua; Nov 15 2026, pop-outs).
ZeD.ObjectCardFire = ZeD.ObjectCardFire or {}
local GRILL_HELP = { burner = "UI_ZeD_Fire_HelpBurner", ignite = "UI_ZeD_Fire_HelpIgnite", tank = "UI_ZeD_Fire_HelpTankPart" }
function ZeD.ObjectCardFire.grillFace(card, px0, y, k, des, t)
    local T = ZeD.T
    local d = t.d
    local cv = P.canvas(card, px0, y, k)
    local st = grillState(t, d)
    PL.draw(cv, des, st, { tex = plateTex, now = getTimestampMs() })
    -- (Nov 15 2026, QA's beta 16 pass, p336: the grill's gas read live, one cheap Java call a frame; when it differs
    -- from the card's last read, the card reads everything again on its next frame)
    local gas = call(t.obj, "hasFuel") == true
    if gas ~= (d.hasFuel == true) then t._refreshT = OC.REFRESH end
    -- the centre knob turns it on or off; the igniter lights it; the cart takes a tank or gives it back
    for _, c in ipairs(PL.controls(des, st)) do
        local fid = "bbq:" .. c.id
        local fn = nil
        if c.id == "burner" then fn = gas and liveToggle or nil
        elseif c.id == "ignite" then fn = (gas and not d.lit) and ignite or nil
        elseif c.id == "tank" then fn = (d.tank or d.spare) and tankFn or nil end
        -- a key (the igniter, the cart) takes the pointer's wash and the controller's mark; the
        -- burner knob keeps its own lit ring
        if c.kind == "turn" then
            if card._fid == fid then PL.cue(cv, c, T.accent, 0.55) end
        else
            if UI.hovered(card, fid) then PL.hoverKey(cv, c) end
            local fm = card:focusOf(fid)
            if fm then PL.markKey(card, c, px0, y, k, fm) end
        end
        card:zone({ fid = fid, x = px0 + c.x * k, y = y + c.y * k, w = c.w * k, h = c.h * k, body = true,
            help = GRILL_HELP[c.id] and ZeD.tr(GRILL_HELP[c.id]) or nil,
            run = fn and function(cc, p) fn(p, t) end or nil })
    end
end

local function propaneBody(card, x, y, w, t, player)
    local T = ZeD.T
    local d = t.d
    local y0 = y
    local gap = T.px(8)
    -- the face, or its simple form (ZeD setup's Devices row: read as it draws, so a change applies at once)
    if ZeD.ObjectCardPlain.on() then
        y = y + propanePlain(card, x, y, w, t) + gap
    else
        local X = ZeD.PhysPx
        -- the width that fills the card, else the narrow face where the main face at the whole zoom does not fit it
        -- (the card's plate room, the same with or without its scrollbar)
        local room = card._plateRoom or w
        local des = X and P.pick(X.fallback.propane, room)
        if des then
            local Sc = ZeD.Scale
            local k = P.kFit((Sc and Sc.root and Sc.root()) or 1, des.w, room)   -- whole zoom, inside the card
            local px0 = x + PL.centre(w, des.w, k)
            OC.faceZone(card, px0, y, des.w * k, des.h * k, t.obj)   -- (a click away from the controls pops the face out)
            ZeD.ObjectCardFire.grillFace(card, px0, y, k, des, t)
            y = y + des.h * k + T.px(6)
        end
        y = y + UI.pair(card, x, y, w, ZeD.tr("UI_ZeD_Fire_GasLeft"), ZeD.tr("UI_ZeD_Fire_Hrs", gasText(d)), ZeD.tr("UI_ZeD_Fire_Tank"), d.tank and ZeD.tr("UI_ZeD_Fire_TankIn") or ZeD.tr("IGUI_None")) + gap
    end
    local items = d.container and call(d.container, "getItems")
    local n = items and items:size() or 0
    if n > 0 then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Fire_OnTheGrill"), tostring(n))
        y = y + UI.cookRows(card, x, y, w, d.container, d.lit)
    end
    return y - y0
end

--- The header's pop-out button: on the propane grill while its face is drawn (Nov 15 2026, pop-outs; not on the
--- plain card, nor a campfire, a charcoal barbecue or a fireplace, which have no face).
function def.popOut(t) return t.kind == "propane" and not ZeD.ObjectCardPlain.on() end
ZeD.ObjectCardFire.def = def   -- (FacePop.lua opens the pop-out on the same target the card works on)

function def.body(card, x, y, w, t, player)
    if not t.d then return 0 end
    if t.d.propane then return propaneBody(card, x, y, w, t, player) end
    return fireBody(card, x, y, w, t, player)
end

OC.register(def)
