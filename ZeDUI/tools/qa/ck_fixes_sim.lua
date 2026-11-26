-- ZeDUI/tools/qa/ck_fixes_sim.lua  (Nov 25 2026, Build): the Cooking tab's faults QA proved in game
-- (ZeDUI/qa/audits/2026-11-25_map_cooking.md, K1 K3 K7 K8 K9 K11), fixed in CookingTab.lua, checked with no game
-- running on the real CookingTab.lua over a stub world.
--   K1   one row per state: fresh, stale and rotten tomatoes are three rows, the type's best row is the fresh one,
--        and Make takes only the pressed row's items (the old row per type took a stale one first)
--   K3   rows go by the shown name: a Herbalist sees Poisonous Berry and Berry as two rows, without the trait one
--        Unknown Berry row (ZeD.herbalName stubbed as ZeD_HerbalName.lua names them)
--   K7   a plan over the base's limit (5 in a saucepan that takes 4) does not fit, and Make queues nothing
--   K9   Make stays busy while its adds are in the player's queue; a second Make queues nothing
--   K8   seasoning is offered once the plan has its first ingredient (from the recipe's own list), and Make
--        puts the ingredients in before the seasoning; the seasoning's start check waits on the ingredient
--   K11  the half card (220u): no pane gets a negative width at 1.75 px a unit (385 px tab) or Large text (443)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/ck_fixes_sim.lua
-- It prints FAIL lines and a last line "ck_fixes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]ck_fixes_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
             contains = function(_, x) for _, v in ipairs(t) do if v == x then return true end end; return false end }
end

require = function() return nil end
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = noop, Remove = noop }
    rawset(t, k, e)
    return e
end })
getTimestampMs = function() return 100000 end

local SCALE = 1
local T = { px = function(n) return math.floor(n * SCALE + 0.5) end, sp = { scrollbarW = 10 } }
ZeD = {
    T = T,
    tr = function(k) return k end,
    textCase = function(s) return s end,
    logOnce = noop,
    CraftingCore = { PANE_W_SPLIT = 240 },
}
local TEXT = { Tooltip_food_Stale = "Stale", Tooltip_food_Rotten = "Rotten", Tooltip_food_Cooked = "Cooked",
               Tooltip_food_Burnt = "Burnt", Tooltip_food_Frozen = "Frozen" }
getText = function(k) return TEXT[k] or k end
getTextOrNull = function() return nil end
isClient = function() return false end
Perks = { Cooking = "Cooking" }
instanceof = function(o, cls) return cls == "Food" and type(o) == "table" and o._food == true end
ZeD_CharacterWindow = { addTab = noop }

-- the timed actions: the game's classes as far as CookingTab uses them
local function derive(base)
    local c = {}
    c.__index = c
    setmetatable(c, { __index = base })
    c.derive = function(self) return derive(self) end
    return c
end
ISBaseTimedAction = { new = function(cls, chr) local o = setmetatable({}, cls); o.character = chr; return o end }
ISBaseTimedAction.derive = function(self) return derive(self) end
ISAddItemInRecipe = ISBaseTimedAction:derive("ISAddItemInRecipe")
ISAddItemInRecipe.new = function(cls, chr, recipe, base, used)
    local o = setmetatable({}, cls)
    o.character, o.recipe, o.baseItem, o.usedItem = chr, recipe, base, used
    return o
end
-- (the game's start check, ISAddItemInRecipe.lua:16: the base carried and the item in the recipe's list for it)
ISAddItemInRecipe.isValidStart = function(self)
    return self.character:getInventory():contains(self.baseItem)
        and self.recipe:getItemsCanBeUse(self.character, self.baseItem, nil):contains(self.usedItem)
end
local Q = { queue = {} }
function Q:indexOf(a) for i, v in ipairs(self.queue) do if v == a then return i end end; return -1 end
ISTimedActionQueue = {
    add = function(a) Q.queue[#Q.queue + 1] = a end,
    addAfter = function(_, a) Q.queue[#Q.queue + 1] = a end,
    getTimedActionQueue = function() return Q end,
}

-- the world: the player's inventory, the only container
local ITEMS = {}
local INV = { getType = function() return "none" end, getContainingItem = function() return nil end }
INV.getItems = function() return list(ITEMS) end
INV.getItemsFromFullType = function(_, ft)
    local o = {}
    for _, it in ipairs(ITEMS) do if it._ft == ft then o[#o + 1] = it end end
    return list(o)
end
INV.contains = function(_, x) for _, v in ipairs(ITEMS) do if v == x then return true end end; return false end
local nextId = 1
local function Item(ft, name, o)
    o = o or {}
    o._ft, o._name, o._cont, o._food = ft, name, INV, o._food ~= false
    o._id = nextId; nextId = nextId + 1
    o.getFullType = function(self) return self._ft end
    o.getDisplayName = function(self) return self._name end
    o.getContainer = function(self) return self._cont end
    o.getID = function(self) return self._id end
    o.isRotten = function(self) return self._rotten == true end
    o.isFresh = function(self) return not self._stale and not self._rotten end
    o.isCooked = function() return false end
    o.isBurnt = function() return false end
    o.isFrozen = function() return false end
    o.isSpice = function(self) return self._spice == true end
    o.getFoodType = function(self) return self._kind or "Vegetables" end
    o.getTex = function() return nil end
    o.isNoRecipes = function() return false end
    o.setChef = noop
    return o
end
local CHR = { getPlayerNum = function() return 0 end, getInventory = function() return INV end,
              getPerkLevel = function() return 7 end, getUsername = function() return "sim" end }

-- a Stew in a saucepan that takes 4; the game's list leaves seasoning out until the base is the dish (K8)
local STEW = {
    getUntranslatedName = function() return "Stew" end, getName = function() return "Stew" end,
    isHidden = function() return false end, getBaseItem = function() return "Base.Saucepan" end,
    getFullResultItem = function() return "Base.SaucepanStew" end, getMinimumWater = function() return 0 end,
    hasMinimumWater = function() return true end, getMaxItems = function() return 4 end,
    isAllowFrozenItem = function() return false end, needToBeCooked = function() return true end,
    isCookable = function() return true end,
    isResultItem = function(_, it) return it._ft == "Base.SaucepanStew" end,
}
local TAKES = { ["Base.Tomato"] = true, ["Base.BerryGeneric1"] = true, ["Base.Salt"] = true }
STEW.getItemsCanBeUse = function(self, chr, base, conts)
    local out = {}
    local dish = self:isResultItem(base)
    for _, it in ipairs(ITEMS) do
        if TAKES[it._ft] and (dish or not it._spice) then out[#out + 1] = it end
    end
    return list(out)
end
STEW.getPossibleItems = function()
    local o = {}
    for ft in pairs(TAKES) do o[#o + 1] = { getFullType = function() return ft end } end
    table.sort(o, function(a, b) return a.getFullType() < b.getFullType() end)
    return list(o)
end
getEvolvedRecipes = function() return list({ STEW }) end
getPlayerInventory = function() return {} end
getPlayerLoot = function() return {} end
ISInventoryPaneContextMenu = {
    getContainers = function() return list({ INV }) end,
    getRealEvolvedItemUse = function(it) return it._rotten and 1 or 10 end,
}

local PAN = Item("Base.Saucepan", "Saucepan", { _food = false })
local STALE = Item("Base.Tomato", "Tomato", { _stale = true })
local ROT = Item("Base.Tomato", "Tomato", { _rotten = true })
local FRESH1 = Item("Base.Tomato", "Tomato")
local FRESH2 = Item("Base.Tomato", "Tomato")
-- the stale one first in the inventory: the old row per type took it first (QA's K1)
ITEMS = { PAN, STALE, ROT, FRESH1, FRESH2 }

local okCK, errCK = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/CookingTab.lua")
check("CookingTab.lua loads on the stubs", okCK, errCK)
local CK = ZeD.CookingTab
local X = CK and CK._test
if not (okCK and X) then
    print("ck_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(1)
end

local win = { _playerObj = CHR }
check("the tab shows (a saucepan and tomatoes)", CK.visible(win) == true)
local s = win._cook
s.dish = "Stew"
local function fresh()
    s.scanAt, s.visAt, s.ingCache, s._ingGroups = -1, nil, nil, nil
    CK.visible(win)
    s.dish = "Stew"
    X.ingredients(s, CHR)
end
local function rowsOf(ft)
    local o = {}
    for _, g in ipairs(X.ingredients(s, CHR)) do if g.ft == ft then o[#o + 1] = g end end
    return o
end
local function adds()
    local o = {}
    for _, a in ipairs(Q.queue) do if a.usedItem then o[#o + 1] = a end end
    return o
end

-- ---------------------------------------------------------------------------
section("K1: one row per state, Make takes the pressed row")
do
    local rows = rowsOf("Base.Tomato")
    check("three tomato rows: fresh, stale, rotten", #rows == 3, #rows)
    local by = {}
    for _, g in ipairs(rows) do by[g.rank] = g end
    check("the fresh row holds both fresh tomatoes", by[1] and by[1].n == 2, by[1] and by[1].n)
    check("the stale row is named so", by[2] and by[2].name == "Tomato (Stale)", by[2] and by[2].name)
    check("the rotten row is named so", by[3] and by[3].name == "Tomato (Rotten)", by[3] and by[3].name)
    check("the type's best row is the fresh one", s.ingCache.byFt["Base.Tomato"] == by[1])
    check("the best row keeps the plain id (QA's ck_tab presses cook:ing:<type>)", by[1] and by[1].id == "cook:ing:Base.Tomato")
    check("the other rows have their own ids", by[2] and by[3] and by[2].id ~= by[1].id and by[3].id ~= by[1].id and by[2].id ~= by[3].id)
    -- the fresh row pressed twice: Make takes the two fresh tomatoes, never the stale one listed first
    s.plan = { { ft = "Base.Tomato", key = by[1].key, name = by[1].name, base = "Tomato" },
               { ft = "Base.Tomato", key = by[1].key, name = by[1].name, base = "Tomato" } }
    Q.queue, s.queued = {}, nil
    X.make(s, CHR, 1)
    local a = adds()
    check("two adds queued", #a == 2, #a)
    local used = {}
    for _, x in ipairs(a) do used[x.usedItem] = true end
    check("Make put in the two fresh tomatoes", used[FRESH1] and used[FRESH2])
    check("TEETH: not the stale one listed first", not used[STALE] and not used[ROT])
    -- a saved dish (type and name only, no row) takes the freshest row of its type
    local k = X.entryKey(s, { ft = "Base.Tomato", base = "Tomato" })
    check("a saved tomato resolves to the fresh row", k == by[1].key, k)
    -- the stale row pressed: its own item, the player's choice
    s.plan = { { ft = "Base.Tomato", key = by[2].key, name = by[2].name, base = "Tomato" } }
    Q.queue, s.queued = {}, nil
    X.make(s, CHR, 1)
    a = adds()
    check("the stale row's Make puts in the stale one", #a == 1 and a[1].usedItem == STALE)
    Q.queue, s.queued, s.plan = {}, nil, {}
end

-- ---------------------------------------------------------------------------
section("K3: berries by the name the player sees")
do
    local BP = Item("Base.BerryGeneric1", "Berries", { _poison = true, _kind = "Fruits" })
    local BC = Item("Base.BerryGeneric1", "Berries", { _kind = "Fruits" })
    ITEMS = { PAN, FRESH1, FRESH2, BP, BC }
    local herbalist = true
    -- (as the real one: it renames the item, setName, and the tab reads getDisplayName)
    ZeD.herbalName = function(item)
        if item._ft ~= "Base.BerryGeneric1" then return nil end
        if not herbalist then item._name = "Unknown Berry"
        else item._name = item._poison and "Poisonous Berry" or "Berry" end
        return item._name
    end
    fresh()
    local rows = rowsOf("Base.BerryGeneric1")
    check("a Herbalist sees two berry rows", #rows == 2, #rows)
    local names = {}
    for _, g in ipairs(rows) do names[g.name] = g end
    check("one Poisonous Berry, one Berry", names["Poisonous Berry"] and names["Berry"])
    check("the Berry row holds only the safe one",
        names["Berry"] and names["Berry"].n == 1 and names["Berry"].items[1] == BC)
    herbalist = false
    fresh()
    rows = rowsOf("Base.BerryGeneric1")
    check("without the trait one Unknown Berry row", #rows == 1 and rows[1].name == "Unknown Berry" and rows[1].n == 2,
        #rows == 1 and rows[1].name)
    check("the tomato keeps its own name (herbalName nil for it)", rowsOf("Base.Tomato")[1].name == "Tomato")
    ZeD.herbalName = nil
    ITEMS = { PAN, STALE, ROT, FRESH1, FRESH2 }
    fresh()
end

-- ---------------------------------------------------------------------------
section("K7: the plan against the base's limit")
do
    local T5 = {}
    for i = 1, 5 do T5[i] = Item("Base.Tomato", "Tomato") end
    ITEMS = { PAN, T5[1], T5[2], T5[3], T5[4], T5[5] }
    fresh()
    local g = s.ingCache.byFt["Base.Tomato"]
    s.plan = {}
    for i = 1, 5 do s.plan[i] = { ft = "Base.Tomato", key = g.key, name = "Tomato", base = "Tomato" } end
    check("five in a saucepan that takes four: does not fit", CK.planFits(s) == false)
    Q.queue, s.queued = {}, nil
    X.make(s, CHR, 1)
    check("Make queues nothing for it", #Q.queue == 0, #Q.queue)
    table.remove(s.plan)
    check("four fits", CK.planFits(s) == true)
    X.make(s, CHR, 1)
    check("four: four adds", #adds() == 4, #adds())
    local src = io.open(ROOT .. "42/media/lua/client/ZeD/CookingTab.lua", "rb"):read("*a")
    check("the band grays Make past the limit",
        string.find(src, "#s.plan > 0 and fits and not CK.cookBusy(s, chr)", 1, true) ~= nil)
    check("the add asks the limit again at the press",
        string.find(src, "if not spice and planN(s) >= maxItems(s) then return end", 1, true) ~= nil)
    Q.queue, s.queued, s.plan = {}, nil, {}
    ITEMS = { PAN, STALE, ROT, FRESH1, FRESH2 }
    fresh()
end

-- ---------------------------------------------------------------------------
section("K9: Make busy while its adds are queued")
do
    local g = s.ingCache.byFt["Base.Tomato"]
    s.plan = { { ft = "Base.Tomato", key = g.key, name = "Tomato", base = "Tomato" } }
    Q.queue, s.queued = {}, nil
    check("not busy before Make", CK.cookBusy(s, CHR) == false)
    X.make(s, CHR, 1)
    local n1 = #Q.queue
    check("Make queued one add", n1 == 1, n1)
    check("busy while it is queued", CK.cookBusy(s, CHR) == true)
    X.make(s, CHR, 1)
    check("a second Make queues nothing", #Q.queue == n1, #Q.queue)
    -- running: the queue's first is the add (q.current); still busy
    check("busy while it runs", CK.cookBusy(s, CHR) == true)
    Q.queue = {}
    check("not busy once the queue has none of them", CK.cookBusy(s, CHR) == false)
    check("the kept list empties itself", s.queued == nil)
    X.make(s, CHR, 1)
    check("Make works again after", #Q.queue == 1, #Q.queue)
    Q.queue, s.queued, s.plan = {}, nil, {}
end

-- ---------------------------------------------------------------------------
section("K8: seasoning once the dish has its first ingredient")
do
    local SALT = Item("Base.Salt", "Salt", { _spice = true, _kind = "Spice" })
    ITEMS = { PAN, FRESH1, FRESH2, SALT }
    fresh()
    s.plan = {}
    check("TEETH: the empty saucepan's list (the game's) has no salt", #rowsOf("Base.Salt") == 0)
    local g = s.ingCache.byFt["Base.Tomato"]
    s.plan = { { ft = "Base.Tomato", key = g.key, name = "Tomato", base = "Tomato" } }
    local salt = rowsOf("Base.Salt")
    check("with a tomato planned, Salt is offered", #salt == 1 and salt[1].spice == true, #salt)
    check("as seasoning", salt[1] and salt[1].kind == "_spice")
    -- planned salt first, tomato second: Make puts the tomato in first
    s.plan = { { ft = "Base.Salt", key = salt[1].key, name = "Salt", base = "Salt", spice = true },
               { ft = "Base.Tomato", key = g.key, name = "Tomato", base = "Tomato" } }
    Q.queue, s.queued = {}, nil
    X.make(s, CHR, 1)
    local a = adds()
    check("two adds", #a == 2, #a)
    check("the tomato goes in first, the salt after", a[1] and a[1].usedItem ~= SALT and a[2] and a[2].usedItem == SALT)
    -- the salt's start check, before the tomato's complete (42.22's order): it waits on the tomato
    local sa = a[2]
    check("the salt's start passes while the tomato is still to complete", sa and sa.spice and sa:isValidStart() == true)
    sa.chain.pending = 0
    check("TEETH: on the plain saucepan with nothing pending, the game's check refuses the salt", sa:isValidStart() == false)
    Q.queue, s.queued, s.plan = {}, nil, {}
    -- QA's second pass: the game's own action put the first ingredient in, so the saucepan is now the dish
    -- (Base.SaucepanStew). The tab lists that dish as a base and offers its salt with nothing planned.
    local DISH = Item("Base.SaucepanStew", "Stew", { _food = false })
    DISH.getExtraItems = function() return list({ "Base.Carrots" }) end
    ITEMS = { DISH, FRESH1, SALT }
    fresh()
    local b = s.bases and s.bases.Stew
    check("the started stew is a base of the Stew", b and #b == 1 and b[1].item == DISH, b and #b)
    check("it needs no water (it has had its own)", b and b[1] and b[1].ok == true)
    s.baseIdx, s.plan = 1, {}
    local salt2 = rowsOf("Base.Salt")
    check("the started stew is offered salt with nothing planned yet", #salt2 == 1, #salt2)
    local tg = s.ingCache.byFt["Base.Tomato"]
    s.plan = {}
    for i = 1, 4 do s.plan[i] = { ft = "Base.Tomato", key = tg and tg.key, name = "Tomato", base = "Tomato" } end
    check("its room is the limit less what it holds: 4 more do not fit a 4-item saucepan holding 1", CK.planFits(s) == false)
    s.plan = { s.plan[1], s.plan[2], s.plan[3] }
    check("3 more fit", CK.planFits(s) == true)
    Q.queue, s.queued, s.plan = {}, nil, {}
    ITEMS = { PAN, STALE, ROT, FRESH1, FRESH2 }
    fresh()
end

-- ---------------------------------------------------------------------------
section("K11: the half card's panes")
do
    local function ok(L, w, h)
        local P, D = L.list, L.dish
        return P.w >= 0 and P.h >= 0 and D.w >= 0 and D.h >= 0 and P.x + P.w <= w and D.x + D.w <= w
            and P.y + P.h <= h and D.y + D.h <= h
    end
    for _, c in ipairs({ { 1.75, 385, "normal" }, { 483 / 240, 443, "Large text" } }) do
        SCALE = c[1]
        local w, bodyH = c[2], 300
        local L = CK.layout(0, 0, w, bodyH)
        check("half card, " .. c[3] .. ": stacked", L.stacked == true)
        check("half card, " .. c[3] .. ": no negative width, inside the tab", ok(L, w, bodyH),
            L.list.w .. "," .. L.dish.w)
        check("half card, " .. c[3] .. ": both panes the full width", L.list.w == w and L.dish.w == w)
        check("half card, " .. c[3] .. ": the dish under the list", L.dish.y > L.list.y + L.list.h - 1 and L.dish.h > 0)
        check("TEETH: the old fixed list left the dish " .. (w - T.px(240) - T.px(1)) .. " px", w - T.px(240) - T.px(1) < 0)
        local F = CK.layout(0, 0, math.floor(480 * c[1]), bodyH)
        check("full card, " .. c[3] .. ": side by side, the list 240u", F.stacked == false and F.list.w == T.px(240) and F.dish.w > 0)
    end
    SCALE = 1
end

print("ck_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
