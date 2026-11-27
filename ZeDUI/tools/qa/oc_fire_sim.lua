-- ZeDUI/tools/qa/oc_fire_sim.lua  (Nov 26 2026, QA's fire card map, FI3 / FI5 / FI6): the fire card with no game
-- running. It loads the real ZeD/ObjectCardFire.lua over a fake card host, fake items, a fake campfire and a fake
-- propane grill, runs def.refresh and reads the rows and verbs it makes.
--   FI3   Light's rows: petrol, then paper and plain tinder, then books, and last what the player keeps (a skill
--         book, a recipe magazine, a map); the starter by name, as the game sorts; Light jumps to the first row
--         that burns nothing kept, and with only kept tinder Light waits (each row keeps its own button)
--   FI5   Take apart's question names what is on the fire (three, then how many more); empty, the plain question
--   FI6   the grill: an empty tank in and a full one in reach offers Insert as the main verb (the game's one-step
--         swap); a fuller tank is the one picked; a worse one is not offered over a tank with gas
--   FI2   All fuel and a kind's "all" take plain fuel only (planks, logs, blank notes, firewood), never the skill
--         book or the map in the crate beside him, a note he named, clothes or a memento; never the game's own
--         bulk adds (they burn the whole list); a kept row has no bulk press but its own Add; Add fuel jumps to
--         a plain row, and with only kept things it waits and names plain fuel
--   FI10  Light's NEEDS line: paper and no lighter names the lighter (tinder lights a fire with no fuel on it);
--         petrol with no fuel names fuel on the fire; a lighter with nothing to light names tinder
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_fire_sim.lua
-- It prints FAIL lines and a last line "oc_fire_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_fire_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- ---------------------------------------------------------------------------
-- THE GAME, FAKED
-- ---------------------------------------------------------------------------
local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
             isEmpty = function() return #t == 0 end }
end

local INV = { name = "inv" }
local BAG = { name = "bag", getContainingItem = function() return { getDisplayName = function() return "Duffel Bag" end } end }

-- an item: f.name, f.type, and what kind (lit, skill, recipes, map, fav, clothing, uses)
local function item(f)
    local it = { _cls = f.map and "MapItem" or "InventoryItem" }
    it.getName = function() return f.name end
    it.getDisplayName = function() return f.name end
    it.getType = function() return f.type end
    it.getFullType = function() return "Base." .. f.type end
    it.getTex = function() return nil end
    it.getContainer = function() return f.where or INV end
    it.isFavorite = function() return f.fav == true end
    it.IsMap = function() return f.map == true end
    it.getSkillTrained = function() return f.skill end
    it.getDisplayCategory = function() return f.skill and "SkillBook" or (f.lit and "Literature" or "Item") end
    it.getTeachedRecipes = function() return f.recipes and jlist({ "Make Stew" }) or nil end
    it.IsLiterature = function() return f.lit == true end
    it.hasTag = function() return false end
    it.getCurrentUsesFloat = function() return f.uses or 0 end
    return it
end

campingLightFireType = { SheetPaper2 = 5 / 60, PaperNapkins = 5 / 60, RecipeClipping = 5 / 60 }
ItemTag = { IS_FIRE_TINDER = "tinder" }
CharacterStat = { ENDURANCE = "endurance" }
SandboxVars = { MaximumFireFuelHours = 8 }
getTimestampMs = function() return 1000 end
getText = function(k) return k end
getCell = function() return nil end
instanceof = function(o, cls) return type(o) == "table" and o._cls == cls end
require = function() end

local CALLS = {}
ISCampingMenu = {
    getNearbyFuelInfo = function() return CURRENT_INFO end,
    getFuelDurationForItem = function() return 15 end,
    onLightFromLiterature = function(p, ty) CALLS[#CALLS + 1] = "tinder:" .. ty end,
}
ISBBQMenu = {
    FindPropaneTank = function() return GAME_TANK end,
    onInsertPropaneTank = function(_, _, _, tank) CALLS[#CALLS + 1] = tank end,
    onRemovePropaneTank = function() CALLS[#CALLS + 1] = "remove" end,
    onToggle = function() end,
}

local function call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
local DEF
local OC = { ui = {}, call = call, DOT = "", REFRESH = 1, LEASH = 6,
    keyOf = function(_, k) return k end,
    register = function(d) DEF = d end,
    whereOf = function(it) return it:getContainer() == INV and "inv" or "bag" end,
}
local function trf(k, ...)
    local a = { ... }
    local s = k
    for i = 1, #a do s = s .. "|" .. tostring(a[i]) end
    return s
end
ZeD = { ObjectCards = OC, Px = {}, Plate = {}, PhysPx = {}, ObjectCardPlain = {}, T = {},
    tr = trf, trDefaults = function() end }

local fn, err = loadfile(Z .. "ObjectCardFire.lua")
check("LOAD ObjectCardFire.lua", fn ~= nil, err)
if fn then
    local ok, e = pcall(fn)
    check("RUN ObjectCardFire.lua", ok, e)
end
check("LOAD the card registers its def", DEF ~= nil and DEF.id == "fire")
if not DEF then
    print("oc_fire_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(1)
end

local PLAYER = {
    getStats = function() return { get = function() return 1 end } end,
    getCurrentSquare = function() return "sq" end,
    getInventory = function() return PLAYER_INV end,
    getPlayerNum = function() return 0 end,
}

local function campfire(fuel, onIt)
    local cont = { getItems = function() return jlist(onIt or {}) end }
    local isoObj = { getTileName = function() return "Campfire" end, getContainer = function() return cont end }
    local lua = { fuelAmt = fuel, isLit = false, updateFromIsoObject = function() end, getIsoObject = function() return isoObj end }
    return { kind = "campfire", obj = lua, sq = "sq", key = "k" }
end
local function info(tinder, starters, petrol)
    local counts = {}
    for _, v in ipairs(tinder) do counts[v:getName()] = 1 end
    return { tinder = tinder, starters = starters, fuelList = {}, itemCount = counts, petrol = petrol }
end
local function verb(t, id)
    for _, v in ipairs(t.verbs or {}) do if v.id == id then return v end end
    return nil
end
local function rowIndexOfJump(t)
    local v = verb(t, "light")
    local n = v and v.jump and tonumber(string.match(v.jump, "fire:light:(%d+)$"))
    return n and t.d.lightRows[n] or nil, v
end

local matchbook = item({ name = "Matchbook", type = "Matchbook" })
local lighter = item({ name = "Lighter", type = "Lighter" })

-- ---------------------------------------------------------------------------
-- FI3  the tinder Light picks
-- ---------------------------------------------------------------------------
do
    -- QA's case: Carpentry I in the main inventory, paper in a bag (the game's scan finds the book first)
    local book = item({ name = "Carpentry I", type = "BookCarpentry1", lit = true, skill = "Carpentry" })
    local paper = item({ name = "Sheet of Paper", type = "SheetPaper2", lit = true, where = BAG })
    CURRENT_INFO = info({ book, paper }, { matchbook })
    local t = campfire(30)
    DEF.refresh(t, PLAYER)
    local rows = t.d.lightRows
    check("FI3 two light rows", #rows == 2, #rows)
    check("FI3 paper leads the list", rows[1] and rows[1].tinderType == "Base.SheetPaper2", rows[1] and rows[1].name)
    check("FI3 the skill book goes last", rows[#rows] and rows[#rows].tinderType == "Base.BookCarpentry1", rows[#rows] and rows[#rows].name)
    local r, v = rowIndexOfJump(t)
    check("FI3 Light jumps to the paper, not the skill book", r and r.tinderType == "Base.SheetPaper2", v and v.jump)
    check("FI3 Light is the main verb", v and v.primary == true and v.enabled == true)
    CALLS = {}
    if r then t.light(PLAYER, r) end
    check("FI3 A A burns the paper", CALLS[1] == "tinder:Base.SheetPaper2", CALLS[1])
end

do
    -- the game's order within a kind (by name), and the kinds: named tinder, plain things, books, kept
    local rag = item({ name = "Ripped Sheets", type = "RippedSheetsX" })
    local napkins = item({ name = "Paper Napkins", type = "PaperNapkins" })
    local novel = item({ name = "Book", type = "Book", lit = true })
    local mag = item({ name = "Cooking Magazine Vol. 1", type = "CookingMag1", lit = true, recipes = true })
    local clip = item({ name = "Recipe Clipping", type = "RecipeClipping", lit = true, recipes = true })
    local map = item({ name = "Louisville Map", type = "LouisvilleMap1", lit = true, map = true })
    CURRENT_INFO = info({ map, novel, mag, rag, clip, napkins }, { matchbook, lighter })
    local t = campfire(30)
    DEF.refresh(t, PLAYER)
    local names = {}
    for _, r in ipairs(t.d.lightRows) do names[#names + 1] = r.name end
    local got = table.concat(names, ", ")
    check("FI3 order: named tinder, plain things, books, then kept (by name in each)",
        got == "Paper Napkins, Ripped Sheets, Book, Cooking Magazine Vol. 1, Louisville Map, Recipe Clipping", got)
    check("FI3 the starter by name, as the game sorts (Lighter before Matchbook)", t.d.lightRows[1] and t.d.lightRows[1].with == "Lighter",
        t.d.lightRows[1] and t.d.lightRows[1].with)
    local kept = 0
    for _, r in ipairs(t.d.lightRows) do if r.kept then kept = kept + 1 end end
    check("FI3 the recipe magazine, the clipping and the map are kept", kept == 3, kept)
end

do
    -- only kept tinder: Light waits; each row keeps its own Light button
    local mag = item({ name = "Cooking Magazine Vol. 1", type = "CookingMag1", lit = true, recipes = true })
    local map = item({ name = "Louisville Map", type = "LouisvilleMap1", lit = true, map = true })
    CURRENT_INFO = info({ map, mag }, { matchbook })
    local t = campfire(30)
    DEF.refresh(t, PLAYER)
    local v = verb(t, "light")
    check("FI3 only kept tinder: Light is not pressable", v and v.enabled == false, v and tostring(v.enabled))
    check("FI3 only kept tinder: Light says what it needs", v and v.needs == "UI_ZeD_Fire_NeedsTinder", v and v.needs)
    check("FI3 only kept tinder: the rows stay, each with its own button", #t.d.lightRows == 2 and t.d.lightRows[1].enabled ~= false)
end

do
    -- petrol still comes first (the game's first method, nothing kept)
    local petrol = item({ name = "Gas Can", type = "PetrolCan" })
    local book = item({ name = "Carpentry I", type = "BookCarpentry1", lit = true, skill = "Carpentry" })
    CURRENT_INFO = info({ book }, { matchbook }, petrol)
    local t = campfire(30)
    DEF.refresh(t, PLAYER)
    check("FI3 petrol first", t.d.lightRows[1] and t.d.lightRows[1].method == "petrol")
    local r = rowIndexOfJump(t)
    check("FI3 Light goes to petrol over a skill book", r and r.method == "petrol")
end

-- ---------------------------------------------------------------------------
-- FI5  Take apart's question
-- ---------------------------------------------------------------------------
do
    CURRENT_INFO = info({}, {})
    local stew = item({ name = "Pot of Stew", type = "PotOfStew" })
    local steak = item({ name = "Steak", type = "Steak" })
    local t = campfire(30, { stew, steak })
    DEF.refresh(t, PLAYER)
    local v = verb(t, "take")
    local q = v and v.confirm or ""
    check("FI5 the question names the stew", string.find(q, "Pot of Stew", 1, true) ~= nil, q)
    check("FI5 the question names the steak", string.find(q, "Steak", 1, true) ~= nil, q)
    check("FI5 the question says it drops", string.find(q, "UI_ZeD_Fire_QTakeApartDrop", 1, true) == 1, q)

    local many = {}
    for i = 1, 5 do many[i] = item({ name = "Bread " .. i, type = "Bread" }) end
    t = campfire(30, many)
    DEF.refresh(t, PLAYER)
    q = verb(t, "take").confirm
    check("FI5 five things: three named and +2", string.find(q, "Bread 1, Bread 2, Bread 3 (+2)", 1, true) ~= nil, q)

    t = campfire(30, {})
    DEF.refresh(t, PLAYER)
    q = verb(t, "take").confirm
    check("FI5 nothing on it: the plain question", q == "UI_ZeD_Fire_QTakeApart", q)
end

-- ---------------------------------------------------------------------------
-- FI6  the propane grill's tank
-- ---------------------------------------------------------------------------
local function grill(hasTank, fuelMin)
    local o = { _cls = "IsoBarbecue" }
    o.isPropaneBBQ = function() return true end
    o.isLit = function() return false end
    o.hasPropaneTank = function() return hasTank end
    o.hasFuel = function() return hasTank and fuelMin > 0 end
    o.getFuelAmount = function() return fuelMin end
    o.getTileName = function() return "Propane Barbecue" end
    o.getSquare = function() return "gsq" end
    o.getX = function() return 10 end
    o.getY = function() return 10 end
    o.getZ = function() return 0 end
    return { kind = "propane", obj = o, sq = "gsq", key = "g" }
end

do
    local full = item({ name = "Propane Tank", type = "PropaneTank", uses = 1.0 })
    GAME_TANK = full
    PLAYER_INV = { getAllTypeRecurse = function() return jlist({ full }) end }
    local t = grill(true, 0)
    DEF.refresh(t, PLAYER)
    local ins, rem = verb(t, "insert"), verb(t, "remove")
    check("FI6 empty tank in, full one carried: Insert is offered", ins and ins.sensible ~= false, ins and tostring(ins.sensible))
    check("FI6 ... and is the main verb", ins and ins.primary == true and ins.enabled == true)
    check("FI6 ... Remove is still there, not the main verb", rem and rem.sensible == true and not rem.primary)
    check("FI6 ... its help says the old tank goes on the ground", ins and ins.help == "UI_ZeD_Fire_HelpSwap", ins and ins.help)
    CALLS = {}
    if ins then ins.run(PLAYER, t) end
    check("FI6 ... pressing it inserts (one step, no Remove first)", CALLS[1] == full, tostring(CALLS[1]))
end

do
    -- the fullest tank in reach, not the first the game finds
    local low = item({ name = "Propane Tank", type = "PropaneTank", uses = 0.4 })
    local high = item({ name = "Propane Tank", type = "PropaneTank", uses = 0.9 })
    GAME_TANK = low
    PLAYER_INV = { getAllTypeRecurse = function() return jlist({ low, high }) end }
    local t = grill(true, 0)
    DEF.refresh(t, PLAYER)
    check("FI6 the fullest tank is the spare", t.d.spare == high)
    CALLS = {}
    verb(t, "insert").run(PLAYER, t)
    check("FI6 the fullest tank goes in", CALLS[1] == high)

    -- a tank with gas in (half) and a worse one carried: no swap offered
    local worse = item({ name = "Propane Tank", type = "PropaneTank", uses = 0.3 })
    GAME_TANK = worse
    PLAYER_INV = { getAllTypeRecurse = function() return jlist({ worse }) end }
    t = grill(true, 600)
    DEF.refresh(t, PLAYER)
    local ins = verb(t, "insert")
    check("FI6 half tank in, a worse one carried: no Insert", ins and ins.sensible == false, ins and tostring(ins.sensible))

    -- a half tank in and a full one carried: Insert offered, not the main verb (the grill has gas)
    local full = item({ name = "Propane Tank", type = "PropaneTank", uses = 1.0 })
    GAME_TANK = full
    PLAYER_INV = { getAllTypeRecurse = function() return jlist({ full }) end }
    t = grill(true, 600)
    DEF.refresh(t, PLAYER)
    ins = verb(t, "insert")
    check("FI6 half tank in, a full one carried: Insert offered", ins and ins.sensible == true)
    check("FI6 ... not the main verb while it has gas", ins and not ins.primary)

    -- no tank in: Insert as before
    t = grill(false, 0)
    DEF.refresh(t, PLAYER)
    ins = verb(t, "insert")
    check("FI6 no tank in: Insert is the main verb", ins and ins.sensible ~= false and ins.primary == true)
end

-- ---------------------------------------------------------------------------
-- FI2  All fuel and the many-of-a-kind rows take plain fuel only
-- ---------------------------------------------------------------------------
-- the game's fuel side, as ISCampingMenu has it: what is in reach (the inventory, the bags, a crate beside
-- him), its add, its bulk adds (recorded: the old card called them, and they burn everything on the list)
local CRATE = { name = "crate" }
local REACH = {}
local QUEUED = {}
local GAME_BULK = {}
local function jlistOf(t) return jlist(t) end
ISInventoryPaneContextMenu = { getContainers = function()
    local cs = {}
    for _, c in ipairs({ INV, BAG, CRATE }) do
        local items = {}
        for _, it in ipairs(REACH) do if it:getContainer() == c then items[#items + 1] = it end end
        cs[#cs + 1] = { getItems = function() return jlistOf(items) end }
    end
    return jlistOf(cs)
end }
ISCampingMenu.isValidFuel = function(it) return not it:isFavorite() end
ISCampingMenu.getFuelItemUses = function() return 1 end
ISCampingMenu.toPlayerInventory = function() end
ISCampingMenu.walkToCampfire = function() return true end
ISCampingMenu.onAddAllFuel = function() GAME_BULK[#GAME_BULK + 1] = "all" end
ISCampingMenu.onAddMultipleFuel = function(_, _, ty) GAME_BULK[#GAME_BULK + 1] = "many:" .. tostring(ty) end
ISCampingMenu.onAddFuel = function(_, _, ty) GAME_BULK[#GAME_BULK + 1] = "one:" .. tostring(ty) end
ISTimedActionQueue = { add = function(a) QUEUED[#QUEUED + 1] = a end }
ISAddFuelAction = { new = function(_, p, target, it, amt) return { item = it, amt = amt } end }
ArrayList = { new = function() local l = {}; return { add = function(_, v) l[#l + 1] = v end, size = function() return #l end } end }
PLAYER.isEquipped = function() return false end
campingFuelType = { Plank = 2.0, Log = 6.0, Note = 5 / 60, SheetPaper2 = 5 / 60 }

local function fuelItem(f)
    local it = item(f)
    it.getDisplayCategory = function() return f.cat or (f.skill and "SkillBook") or (f.lit and "Literature") or "Item" end
    it.isCustomName = function() return f.named == true end
    it.IsClothing = function() return f.clothing == true end
    REACH[#REACH + 1] = it
    return it
end
local function fuelInfo(list)
    local counts, reps, order = {}, {}, {}
    for _, it in ipairs(list) do
        local n = it:getName()
        if not counts[n] then counts[n] = 0; reps[#reps + 1] = it end
        counts[n] = counts[n] + 1
    end
    return { tinder = {}, starters = {}, fuelList = reps, itemCount = counts }
end
local function fireWith(fuel)
    local t = campfire(fuel)
    t.obj.getSquare = function() return "sq" end
    return t
end
local function queuedNames()
    local out = {}
    for _, a in ipairs(QUEUED) do out[#out + 1] = a.item:getName() end
    return table.concat(out, ", ")
end
local function rowNamed(t, base)
    for i, r in ipairs(t.d.fuelRows) do if r.baseName == base then return r, i end end
    return nil
end

do
    -- QA's case: a skill book and a plank in the crate beside him, a plank in his bags, a map, and a log
    REACH, QUEUED, GAME_BULK = {}, {}, {}
    local book = fuelItem({ name = "Carpentry I", type = "BookCarpentry1", lit = true, skill = "Carpentry", where = CRATE })
    local plankC = fuelItem({ name = "Plank", type = "Plank", where = CRATE })
    local plankB = fuelItem({ name = "Plank", type = "Plank", where = BAG })
    local map = fuelItem({ name = "Louisville Map", type = "LouisvilleMap1", map = true, cat = "Cartography", where = CRATE })
    local log = fuelItem({ name = "Log", type = "Log" })
    CURRENT_INFO = fuelInfo({ book, plankC, plankB, map, log })
    local t = fireWith(0)
    DEF.refresh(t, PLAYER)
    local rows = t.d.fuelRows
    check("FI2 four fuel rows (plank, log, book, map)", #rows == 4, #rows)
    check("FI2 the skill book and the map are kept, last", rows[3] and rows[3].kept and rows[4] and rows[4].kept,
        rows[3] and rows[3].baseName)
    check("FI2 the plank and the log are plain, first", rows[1] and not rows[1].kept and rows[2] and not rows[2].kept)
    check("FI2 All fuel counts the plain fuel only (2 planks and a log)", rows.totalN == 3, rows.totalN)
    t.addFuelAll(PLAYER)
    local got = queuedNames()
    check("FI2 All fuel never asks the game's All (it burns the whole list)", #GAME_BULK == 0, table.concat(GAME_BULK, ","))
    check("FI2 All fuel takes the planks and the log", #QUEUED == 3 and select(2, got:gsub("Plank", "")) == 2 and got:find("Log", 1, true) ~= nil, got)
    check("FI2 All fuel leaves the skill book in the crate", got:find("Carpentry", 1, true) == nil, got)
    check("FI2 All fuel leaves the map", got:find("Map", 1, true) == nil, got)

    -- the kept rows have no bulk press; their own Add still works, on purpose
    QUEUED, GAME_BULK = {}, {}
    local br = rowNamed(t, "Carpentry I")
    if br then t.addFuelMany(PLAYER, br) end
    check("FI2 a kept row's bulk add does nothing", #QUEUED == 0 and #GAME_BULK == 0, queuedNames() .. table.concat(GAME_BULK, ","))
    if br then t.addFuel(PLAYER, br) end
    check("FI2 a kept row's own Add puts it on (the player's pick)", GAME_BULK[1] == "one:Base.BookCarpentry1", GAME_BULK[1])

    -- the planks' "all (2)" takes the two planks, nothing else
    QUEUED, GAME_BULK = {}, {}
    local pr = rowNamed(t, "Plank")
    if pr then t.addFuelMany(PLAYER, pr) end
    check("FI2 Plank: all takes the two planks", queuedNames() == "Plank, Plank" and #GAME_BULK == 0, queuedNames())

    -- Add fuel's jump lands on a plain row
    local v = verb(t, "fuel")
    local n = v and tonumber(string.match(v.jump or "", "fire:fuel:(%d+)$"))
    check("FI2 Add fuel jumps to a plain row", n and rows[n] and not rows[n].kept, v and v.jump)
end

do
    -- only a skill book in reach: Add fuel waits and says what it needs; the row keeps its button
    REACH, QUEUED, GAME_BULK = {}, {}, {}
    local book = fuelItem({ name = "Carpentry I", type = "BookCarpentry1", lit = true, skill = "Carpentry", where = CRATE })
    CURRENT_INFO = fuelInfo({ book })
    local t = fireWith(0)
    DEF.refresh(t, PLAYER)
    local v = verb(t, "fuel")
    check("FI2 only a skill book: Add fuel is not pressable", v and v.enabled == false, v and tostring(v.enabled))
    check("FI2 only a skill book: it names plain fuel", v and v.needs == "UI_ZeD_Fire_NeedsPlainFuel", v and v.needs)
    check("FI2 only a skill book: its row stays", #t.d.fuelRows == 1 and t.d.fuelRows[1].fits)
end

do
    -- what else stays out of the bulk adds: a note he named, a jacket, a memento; firewood goes in
    REACH, QUEUED, GAME_BULK = {}, {}, {}
    local note = fuelItem({ name = "Directions home", type = "Note", named = true })
    local blank = fuelItem({ name = "Note", type = "Note" })
    local jacket = fuelItem({ name = "Jacket", type = "Jacket_Shellsuit_Black", clothing = true, cat = "Clothing" })
    local bear = fuelItem({ name = "Spiffo", type = "Spiffo", cat = "Memento" })
    local wood = fuelItem({ name = "Firewood", type = "Firewood", cat = "MaterialWeapon" })
    CURRENT_INFO = fuelInfo({ note, blank, jacket, bear, wood })
    local t = fireWith(0)
    DEF.refresh(t, PLAYER)
    t.addFuelAll(PLAYER)
    local got = queuedNames()
    check("FI2 All fuel: the blank note and the firewood", got == "Note, Firewood", got)
    QUEUED = {}
    local nr = rowNamed(t, "Note")
    if nr then t.addFuel(PLAYER, nr) end
    check("FI2 the blank Note row's Add takes a blank note, not the named one", queuedNames() == "Note", queuedNames())
end

-- ---------------------------------------------------------------------------
-- FI10  Light's NEEDS line names what is missing
-- ---------------------------------------------------------------------------
do
    REACH = {}
    -- paper, no fuel on the fire, no lighter: tinder lights it without fuel, so the lighter is what is missing
    local paper = item({ name = "Sheet of Paper", type = "SheetPaper2", lit = true })
    CURRENT_INFO = info({ paper }, {})
    local t = campfire(0)
    DEF.refresh(t, PLAYER)
    local v = verb(t, "light")
    check("FI10 paper, no fuel, no lighter: Light waits", v and v.enabled == false)
    check("FI10 ... and names the lighter, not fuel", v and v.needs == "UI_ZeD_Fire_NeedsLighter", v and v.needs)

    -- a lighter and petrol, no tinder, no fuel: petrol needs fuel on the fire
    local petrol = item({ name = "Gas Can", type = "PetrolCan" })
    CURRENT_INFO = info({}, { lighter }, petrol)
    t = campfire(0)
    DEF.refresh(t, PLAYER)
    v = verb(t, "light")
    check("FI10 petrol, no fuel: fuel on the fire", v and v.needs == "UI_ZeD_Fire_NeedsFuelFirst", v and v.needs)

    -- a lighter, nothing to light: tinder
    CURRENT_INFO = info({}, { lighter })
    t = campfire(0)
    DEF.refresh(t, PLAYER)
    v = verb(t, "light")
    check("FI10 a lighter, nothing to light: tinder", v and v.needs == "UI_ZeD_Fire_NeedsTinder", v and v.needs)
end

-- ---------------------------------------------------------------------------
-- FI1  (the director's call, Nov 26 2026) an indoor campfire beside a floor the game can set alight: the warning
--      in the body while lit or while Light is offered, and over his head as he lights it; the game's own test
--      (SCampfireSystem.lowerFirelvl): not outside, a neighbour's floor floors_interior_tilesandwood from tile 40,
--      floors_interior_carpet or carpet, on the squares ZombRand(-1, 1) can pick (west, north, north-west)
-- ---------------------------------------------------------------------------
do
    local function floorSq(x, y, name, n, outside)
        local spr = name and { getName = function() return name end, getSheetGridIdFromName = function() return n or 0 end } or nil
        return { getX = function() return x end, getY = function() return y end, getZ = function() return 0 end,
            isOutside = function() return outside == true end,
            getFloor = function() return spr and { getSprite = function() return spr end } or nil end }
    end
    local GRID = {}
    local function grid(x, y, name, n, outside) GRID[x .. "," .. y] = floorSq(x, y, name, n, outside); return GRID[x .. "," .. y] end
    local oldCell = getCell
    getCell = function() return { getGridSquare = function(_, x, y) return GRID[x .. "," .. y] end } end
    local halo = {}
    HaloTextHelper = { addBadText = function(_, s) halo[#halo + 1] = s end }
    local function fireOn(sq, lit)
        local t = campfire(30)
        t.sq = sq
        t.obj.isLit = lit == true
        return t
    end
    local paper = item({ name = "Sheet of Paper", type = "SheetPaper2", lit = true })
    CURRENT_INFO = info({ paper }, { matchbook })

    -- the fire on stone, a wood floor (tile 40) west of it
    local here = grid(10, 10, "floors_interior_tilesandwood_01", 2)
    grid(9, 10, "floors_interior_tilesandwood_01", 40)
    local t = fireOn(here)
    DEF.refresh(t, PLAYER)
    check("FI1 indoors, wood floor west: the card knows", t.d.floorCatches == true)
    -- the body draws the warning first (UI.warn), then stops (the sim has no strip to draw)
    local warned = nil
    OC.ui.warn = function(_, _, _, _, s) warned = s; error("stop") end
    ZeD.T.px = function(n) return n end
    pcall(DEF.body, {}, 0, 0, 400, t, PLAYER)
    check("FI1 ... the body's warning box, Light offered", warned == "UI_ZeD_Fire_FloorCatches", warned)
    halo = {}
    t.light(PLAYER, t.d.lightRows[1])
    check("FI1 ... lighting it says it over his head", halo[1] == "UI_ZeD_Fire_FloorCatches", halo[1])
    check("FI1 ... and still lights it (warn, don't block)", CALLS[#CALLS] == "tinder:Base.SheetPaper2", CALLS[#CALLS])
    -- lit: the box stays
    t = fireOn(here, true)
    DEF.refresh(t, PLAYER)
    warned = nil
    pcall(DEF.body, {}, 0, 0, 400, t, PLAYER)
    check("FI1 lit on that floor: the box stays", warned == "UI_ZeD_Fire_FloorCatches", warned)

    -- the game's tile rule: tilesandwood below 40 is tile, not wood
    GRID = {}
    here = grid(10, 10, "floors_interior_tilesandwood_01", 2)
    grid(9, 10, "floors_interior_tilesandwood_01", 39)
    grid(10, 9, "floors_exterior_street_01", 50)
    t = fireOn(here)
    DEF.refresh(t, PLAYER)
    check("FI1 tile 39 of tilesandwood and a street floor: no warning", t.d.floorCatches == false)
    warned = nil
    pcall(DEF.body, {}, 0, 0, 400, t, PLAYER)
    check("FI1 ... no box", warned == nil, warned)
    halo = {}
    t.light(PLAYER, t.d.lightRows[1])
    check("FI1 ... no word over his head", #halo == 0, halo[1])

    -- a carpet north-west: yes; a carpet only east or south (squares the game never picks): no
    GRID = {}
    here = grid(10, 10, nil)
    grid(9, 9, "carpet_01", 3)
    t = fireOn(here)
    DEF.refresh(t, PLAYER)
    check("FI1 a carpet north-west: warns", t.d.floorCatches == true)
    GRID = {}
    here = grid(10, 10, nil)
    grid(11, 10, "floors_interior_carpet_01", 3)
    grid(10, 11, "floors_interior_carpet_01", 3)
    t = fireOn(here)
    DEF.refresh(t, PLAYER)
    check("FI1 carpet only east and south (the game never picks them): no warning", t.d.floorCatches == false)

    -- outside, on wood (a deck): the game never spreads an outdoor campfire
    GRID = {}
    here = grid(10, 10, nil, 0, true)
    grid(9, 10, "floors_interior_tilesandwood_01", 40, true)
    t = fireOn(here)
    DEF.refresh(t, PLAYER)
    check("FI1 outside: no warning", t.d.floorCatches == false)

    -- out and nothing to light it with: no box (it is neither lit nor about to be)
    GRID = {}
    here = grid(10, 10, nil)
    grid(9, 10, "floors_interior_tilesandwood_01", 40)
    CURRENT_INFO = info({}, {})
    t = fireOn(here)
    DEF.refresh(t, PLAYER)
    warned = nil
    pcall(DEF.body, {}, 0, 0, 400, t, PLAYER)
    check("FI1 out with no way to light it: no box", warned == nil, warned)

    OC.ui.warn, ZeD.T.px, HaloTextHelper = nil, nil, nil
    getCell = oldCell
end

print("oc_fire_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
