-- ZeDUI/tools/qa/oc_fire_sim.lua  (Nov 26 2026, QA's fire card map, FI3 / FI5 / FI6): the fire card with no game
-- running. It loads the real ZeD/ObjectCardFire.lua over a fake card host, fake items, a fake campfire and a fake
-- propane grill, runs def.refresh and reads the rows and verbs it makes.
--   FI3   Light's rows: petrol, then paper and plain tinder, then books, and last what the player keeps (a skill
--         book, a recipe magazine, a map); the starter by name, as the game sorts; Light jumps to the first row
--         that burns nothing kept, and with only kept tinder Light waits (each row keeps its own button)
--   FI5   Take apart's question names what is on the fire (three, then how many more); empty, the plain question
--   FI6   the grill: an empty tank in and a full one in reach offers Insert as the main verb (the game's one-step
--         swap); a fuller tank is the one picked; a worse one is not offered over a tank with gas
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

print("oc_fire_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
