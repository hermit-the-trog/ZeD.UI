-- ZeDUI/tools/qa/ck_calls_sim.lua  (Nov 25 2026, Build): the director's calls 1-6 on QA's Cooking KISS test
-- (ZeDUI/qa/audits/2026-11-25_kiss_cooking.md), built in CookingTab.lua and checked with no game running on the
-- real CookingTab.lua over a stub world (the stubs as ck_fixes_sim.lua's, with a crate beside the player).
--   1  the Hunger line is the made dish's whole total: a sandwich of one cooked steak 15 (bread 10 + steak 5, the
--      old line 5), a stew of one tomato 12 (the old line 11, the game's Lua "(n)"), a dish already made keeps its
--      own and is read through its own state (a cooked omelette x1.3); the item card's words
--   2  a grey row's reason goes in the help line on a controller while the focus is on the row (beside the
--      prompts, A's Select hidden); a lit row adds nothing
--   3  a row whose items are all in a crate says "Crate"; a carried row says nothing
--   4  dishes already made are listed (base == result: an omelette, a second round of soup), folded into the dish
--      of the same name, each base once
--   5  the tab shows for a pot in a crate (none carried), and Make brings the pot to the player before the add and
--      sends the dish it ends with (a new item: the pot became a pot of stew) back to the crate after
--   6  the tab opens on the last dish made; with that dish not in reach, on the first rule's dish
-- Run from the repo root:  lua51 ZeDUI/tools/qa/ck_calls_sim.lua
-- It prints FAIL lines and a last line "ck_calls_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]ck_calls_sim%.lua$", "")

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

local T = { px = function(n) return n end, sp = { scrollbarW = 10 } }
ZeD = {
    T = T,
    tr = function(k) return k end,
    textCase = function(s) return s end,
    logOnce = noop,
    CraftingCore = { PANE_W_SPLIT = 240 },
}
getText = function(k) return k end
local LABELS = { Soup = "Soup", Soup2 = "Soup", Stew = "Stew", Sandwich = "Sandwich", Omelette = "Omelette" }
getTextOrNull = function(k)
    local un = string.match(k, "^ContextMenu_EvolvedRecipe_(.+)$")
    if un then return LABELS[un] end
    if k == "IGUI_ContainerTitle_crate" then return "Crate" end
    return nil
end
isClient = function() return false end
Perks = { Cooking = "Cooking" }
instanceof = function(o, cls) return cls == "Food" and type(o) == "table" and o._food == true end
ZeD_CharacterWindow = { addTab = noop }

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
ISAddItemInRecipe.isValidStart = function() return true end
local Q = { queue = {} }
function Q:indexOf(a) for i, v in ipairs(self.queue) do if v == a then return i end end; return -1 end
ISTimedActionQueue = {
    add = function(a) Q.queue[#Q.queue + 1] = a end,
    addAfter = function(_, a) Q.queue[#Q.queue + 1] = a end,
    getTimedActionQueue = function() return Q end,
}
ISInventoryTransferUtil = { newInventoryTransferAction = function(chr, item, src, dst)
    return { transfer = true, item = item, src = src, dst = dst }
end }
local RETURNED = {}
ISCraftingUI = { ReturnItemsToOriginalContainer = function(chr, items)
    for _, it in ipairs(items) do RETURNED[#RETURNED + 1] = it end
end }

-- the world: the player's inventory and a crate in reach
local function Container(kind)
    local c = { items = {} }
    c.getType = function() return kind end
    c.getContainingItem = function() return nil end
    c.getItems = function(self) return list(self.items) end
    c.getItemsFromFullType = function(self, ft)
        local o = {}
        for _, it in ipairs(self.items) do if it._ft == ft then o[#o + 1] = it end end
        return list(o)
    end
    c.contains = function(self, x) for _, v in ipairs(self.items) do if v == x then return true end end; return false end
    return c
end
local INV, CRATE = Container("none"), Container("crate")
local function put(inv, crate)
    INV.items, CRATE.items = inv or {}, crate or {}
    for _, it in ipairs(INV.items) do it._cont = INV end
    for _, it in ipairs(CRATE.items) do it._cont = CRATE end
end
local nextId = 1
-- hung: the item's own hunger (getHungChange); shown: what its card reads (getHungerChange, by its state)
local function Item(ft, name, o)
    o = o or {}
    o._ft, o._name, o._food = ft, name, o._food ~= false
    o._id = nextId; nextId = nextId + 1
    o.getFullType = function(self) return self._ft end
    o.getDisplayName = function(self) return self._name end
    o.getContainer = function(self) return self._cont end
    o.getID = function(self) return self._id end
    o.isRotten = function() return false end
    o.isFresh = function() return true end
    o.isCooked = function(self) return self._cooked == true end
    o.isBurnt = function() return false end
    o.isFrozen = function() return false end
    o.isSpice = function() return false end
    o.getFoodType = function() return "Vegetables" end
    o.getTex = function() return nil end
    o.isNoRecipes = function() return false end
    o.setChef = noop
    o.getHungChange = function(self) return self._hung or 0 end
    o.getHungerChange = function(self) return (self._hung or 0) * (self._cooked and 1.3 or 1) end
    o.getBaseHunger = function(self) return self._hung or 0 end
    o.getExtraItems = function() return nil end
    return o
end
local MD = {}
local CHR = { getPlayerNum = function() return 0 end, getInventory = function() return INV end,
              getPerkLevel = function() return 5 end, getUsername = function() return "sim" end,
              getModData = function() return MD end }

-- the recipes: takes = { [full type] = use }
local function Recipe(un, base, result, takes)
    local r = { _un = un, _base = base, _result = result, _takes = takes }
    r.getUntranslatedName = function() return un end
    r.getName = function() return LABELS[un] end
    r.isHidden = function() return false end
    r.getBaseItem = function() return base end
    r.getFullResultItem = function() return result end
    r.getMinimumWater = function() return 0 end
    r.hasMinimumWater = function() return true end
    r.getMaxItems = function() return 6 end
    r.isAllowFrozenItem = function() return false end
    r.needToBeCooked = function() return true end
    r.isCookable = function() return true end
    r.isResultItem = function(_, it) return it._ft == result end
    r.getPossibleItems = function() return list({}) end
    r.getItemRecipe = function(_, it)
        local u = takes[it._ft]
        return u and { getUse = function() return u end } or nil
    end
    r.getItemsCanBeUse = function(self, chr, b, conts)
        local out = {}
        for _, c in ipairs({ INV, CRATE }) do
            for _, it in ipairs(c.items) do if takes[it._ft] then out[#out + 1] = it end end
        end
        return list(out)
    end
    return r
end
local TOM_USE = { ["Base.Tomato"] = 12 }
local RECIPES = {
    Recipe("Soup", "Base.Pot", "Base.PotOfSoupRecipe", TOM_USE),
    Recipe("Soup2", "Base.PotOfSoup", "Base.PotOfSoup", TOM_USE),
    Recipe("Stew", "Base.Pot", "Base.PotOfStew", TOM_USE),
    Recipe("Sandwich", "Base.BreadSlices", "Base.Sandwich", { ["Base.Steak"] = 5, ["Base.Tomato"] = 6 }),
    Recipe("Omelette", "Base.OmeletteRecipe", "Base.OmeletteRecipe", { ["Base.Tomato"] = 6 }),
}
getEvolvedRecipes = function() return list(RECIPES) end
getPlayerInventory = function() return {} end
getPlayerLoot = function() return {} end
ISInventoryPaneContextMenu = {
    getContainers = function() return list({ INV, CRATE }) end,
    -- the game's own (ISInventoryPaneContextMenu.lua:4085), word for word but the rotten branch
    getRealEvolvedItemUse = function(evoItem, evorecipe2, cookingLvl)
        if not evoItem or not evorecipe2 or not evorecipe2:getItemRecipe(evoItem) then return end
        local use = evorecipe2:getItemRecipe(evoItem):getUse()
        if use > math.abs(evoItem:getHungerChange() * 100) then
            use = math.floor(math.abs(evoItem:getHungerChange() * 100))
        end
        return use
    end,
}

-- the items, their hunger as the game's floats read in Lua's doubles (0.12f is 0.11999999731779099)
local F012, F010, F020, F030 = -0.11999999731779099, -0.10000000149011612, -0.20000000298023224, -0.30000001192092896
local POT = Item("Base.Pot", "Water (Pot)", { _food = false })
local TOM = Item("Base.Tomato", "Tomato", { _hung = F012 })
local STEAK = Item("Base.Steak", "Steak", { _hung = F030, _cooked = true })
local BREAD = Item("Base.BreadSlices", "Bread Slices", { _hung = F010 })
local OMEL = Item("Base.OmeletteRecipe", "Omelette", { _hung = F020 })
local SOUP = Item("Base.PotOfSoup", "Soup", { _hung = -0.4 })

put({ POT, TOM }, {})
local okCK, errCK = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/CookingTab.lua")
check("CookingTab.lua loads on the stubs", okCK, errCK)
local CK = ZeD.CookingTab
local X = CK and CK._test
if not (okCK and X) then
    print("ck_calls_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(1)
end
local SRC = io.open(ROOT .. "42/media/lua/client/ZeD/CookingTab.lua", "rb"):read("*a")

local win = { _playerObj = CHR }
CK.visible(win)
local s = win._cook
local function rescan(dish)
    s.scanAt, s.visAt, s.ingCache, s._ingGroups = -1, nil, nil, nil
    CK.visible(win)
    s.dish, s.baseIdx, s.plan, s.qty = dish, 1, {}, 1
    if dish then X.ingredients(s, CHR) end
end
local function row(ft)
    for _, g in ipairs(X.ingredients(s, CHR)) do if g.ft == ft and not g.why then return g end end
    return nil
end
local function plan(g, n)
    s.plan = {}
    if not g then return end
    for i = 1, n or 1 do s.plan[i] = { ft = g.ft, key = g.key, name = g.name, base = g.base } end
end
local function baseIdxOf(dish, item)
    for i, o in ipairs((s.bases and s.bases[dish]) or {}) do if o.item == item then return i end end
    return nil
end
local hunger = CK.dishHunger or function() return -1 end
local function shown(v) return math.floor(v + 0.5) end

-- ---------------------------------------------------------------------------
section("call 1: the Hunger line is the made dish's whole total")
do
    put({ BREAD, STEAK }, {})
    rescan("Sandwich")
    local st = row("Base.Steak")
    check("the steak row is there", st ~= nil)
    plan(st, 1)
    local h = hunger(s, CHR)
    check("a sandwich of one cooked steak: 15, as the made sandwich (bread 10 + steak 5)", shown(h) == 15, h)
    check("TEETH: the old line, the ingredients alone, read 5", st and tonumber(st.use) == 5, st and st.use)

    put({ POT, TOM }, {})
    rescan("Stew")
    local tg = row("Base.Tomato")
    plan(tg, 1)
    h = hunger(s, CHR)
    check("a stew of one tomato: 12, as the made stew (the game's float test)", shown(h) == 12, h)
    check("TEETH: the game's Lua \"(n)\", the old line, reads 11", tg and tonumber(tg.use) == 11, tg and tg.use)
    plan(tg, 1)
    s.plan[1].spice = true
    check("a seasoning adds nothing", shown(hunger(s, CHR)) == 0, hunger(s, CHR))

    put({ OMEL, TOM }, {})
    rescan("Omelette")
    plan(row("Base.Tomato"), 1)
    h = hunger(s, CHR)
    check("an omelette already made keeps its own 20 and the tomato adds 6: 26", shown(h) == 26, h)
    OMEL._cooked = true
    h = hunger(s, CHR)
    check("a cooked omelette is read as its card reads it (x1.3): 34", shown(h) == 34, h)
    OMEL._cooked = false
    check("the line uses the item card's words",
        string.find(SRC, 'ZeD.tr("UI_ZeD_Card_HungerReduction")', 1, true) ~= nil)
    check("in the card's figure (+15)", string.find(SRC, 'string.format("%+d", math.floor(fill + 0.5))', 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("call 2: a grey row's reason on a controller")
do
    put({ POT, TOM }, {})
    rescan("Stew")
    -- the row as the render stamps it: a grey row carries its reason (stamp opts), a lit one none
    s.zones, s.byId = {}, {}
    local function zone(id, disabled, why)
        local z = { id = id, x = 0, y = 0, w = 10, h = 10, fn = noop, pane = "list", disabled = disabled, why = why }
        s.zones[#s.zones + 1] = z
        s.byId[id] = z
    end
    zone("cook:ing:Base.Steak", true, "ContextMenu_NeedCooked")
    zone("cook:ing:Base.Tomato", false, nil)
    local els = CK.buildFocusables(win)
    local grey, lit = nil, nil
    for _, el in ipairs(els) do
        if el.id == "cook:ing:Base.Steak" then grey = el elseif el.id == "cook:ing:Base.Tomato" then lit = el end
    end
    local function call(f) if type(f) == "function" then return f(win, nil) end return f end
    local ex = grey and call(grey.extraPrompts)
    check("the grey row's reason is beside the prompts", type(ex) == "table" and ex[1] == "ContextMenu_NeedCooked",
        type(ex) == "table" and ex[1] or tostring(ex))
    check("A's Select is hidden on it (A does nothing there)", grey and call(grey.promptA) == false)
    check("a lit row adds no words", lit and call(lit.extraPrompts) == nil)
    check("a lit row keeps A's Select", lit and call(lit.promptA) == nil)
    -- the row turns grey later (the dish fills up): read each frame, not when the stops were built
    s.byId["cook:ing:Base.Tomato"].disabled, s.byId["cook:ing:Base.Tomato"].why = true, "UI_ZeD_Cook_Full"
    ex = lit and call(lit.extraPrompts)
    check("a row grey since the stops were built says why", type(ex) == "table" and ex[1] == "UI_ZeD_Cook_Full")
    check("the render stamps the reason on a grey row",
        string.find(SRC, "disabled = not can, why = (not can) and why or nil", 1, true) ~= nil)
    check("the full dish is a reason", string.find(SRC, '(not can and full and not g.spice) and ZeD.tr("UI_ZeD_Cook_Full")', 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("call 3: where an ingredient is")
do
    put({ POT }, { TOM })
    rescan("Stew")
    local tg = row("Base.Tomato")
    check("a tomato in the crate says Crate", tg and tg.where == "Crate", tg and tostring(tg.where))
    put({ POT, TOM }, {})
    rescan("Stew")
    tg = row("Base.Tomato")
    check("a carried tomato says nothing", tg and tg.where == nil, tg and tostring(tg.where))
    local T2 = Item("Base.Tomato", "Tomato", { _hung = F012 })
    put({ POT, TOM }, { T2 })
    rescan("Stew")
    tg = row("Base.Tomato")
    check("one carried, one in the crate: the row says nothing (Make takes the carried one first)",
        tg and tg.n == 2 and tg.where == nil, tg and tostring(tg.where))
end

-- ---------------------------------------------------------------------------
section("call 4: dishes already made")
do
    put({ OMEL, SOUP, POT, TOM }, {})
    rescan(nil)
    local has = {}
    for _, k in ipairs(s.dishList or {}) do has[k] = (has[k] or 0) + 1 end
    check("the omelette (base == result) is listed", has.Omelette == 1)
    check("its base is the omelette itself", s.bases.Omelette and #s.bases.Omelette == 1 and s.bases.Omelette[1].item == OMEL)
    check("Soup2 folds into Soup: one Soup in the list", has.Soup == 1 and has.Soup2 == nil)
    check("the soup already made is a base of Soup, once", baseIdxOf("Soup", SOUP) ~= nil and #s.bases.Soup == 2,
        s.bases.Soup and #s.bases.Soup)
    local oi = baseIdxOf("Soup", SOUP)
    check("it is the dish already made (ready, its room the limit less what it holds)",
        oi and s.bases.Soup[oi].ok == true and s.bases.Soup[oi].recipe:getUntranslatedName() == "Soup2")
    s.dish, s.baseIdx = "Omelette", 1
    s.ingCache = nil
    check("the omelette takes the tomato", row("Base.Tomato") ~= nil)
end

-- ---------------------------------------------------------------------------
section("call 5: a pot not on him")
do
    put({ TOM }, { POT })
    s.scanAt, s.visAt = -1, nil
    check("the tab shows for a pot in the crate", CK.visible(win) == true)
    local mine = false
    for _, l in pairs(s.bases or {}) do for _, o in ipairs(l) do if o.mine then mine = true end end end
    check("TEETH: no base on the player (the old rule hid the tab)", not mine)
    s.dish, s.baseIdx, s.ingCache = "Stew", 1, nil
    plan(row("Base.Tomato"), 1)
    Q.queue, s.queued, RETURNED = {}, nil, {}
    X.make(s, CHR, 1)
    local firstTransfer, firstAdd = nil, nil
    for i, a in ipairs(Q.queue) do
        if a.transfer and a.item == POT and not firstTransfer then firstTransfer = i end
        if a.usedItem and not firstAdd then firstAdd = i end
    end
    check("Make brings the pot to the player", firstTransfer ~= nil and Q.queue[firstTransfer].dst == INV)
    check("before the add", firstTransfer and firstAdd and firstTransfer < firstAdd)
    -- the dish goes back, not the pot: the first add turns the pot into a new item, a pot of stew, so a move
    -- back queued for the pot moved nothing and the stew stayed in his bags (QA's second read of call 5)
    local potBack = false
    for _, it in ipairs(RETURNED) do if it == POT then potBack = true end end
    check("TEETH: the pot is not sent back with the ingredients (it becomes the stew)", not potBack)
    local ret, retAt, lastAdd = nil, nil, nil
    for i, a in ipairs(Q.queue) do
        if a.usedItem then lastAdd = i end
        if ZeD_CookReturn and getmetatable(a) == ZeD_CookReturn then ret, retAt = a, i end
    end
    check("a return is queued after the last add, for the crate", ret ~= nil and retAt > (lastAdd or 99) and ret.cont == CRATE)
    if ret then
        -- the chain ends with a new item, the stew, on the player
        local STEWD = Item(ret.recipe:getFullResultItem(), "Stew", { _food = false })
        INV.items[#INV.items + 1] = STEWD; STEWD._cont = INV
        ret.chain.base = STEWD
        CharacterTrait = CharacterTrait or { DISORGANIZED = "Disorganized" }
        CHR.hasTrait = function() return false end
        local before = #Q.queue
        ret:start(); ret.forceComplete = noop; ret.forceStop = noop
        ret:update()
        check("it waits a frame (the last add completes after it starts)", #Q.queue == before)
        ret:update()
        local mv = Q.queue[#Q.queue]
        check("then the stew goes back to the crate", #Q.queue == before + 1 and mv.transfer and mv.item == STEWD
            and mv.src == INV and mv.dst == CRATE)
        CHR.hasTrait = function() return true end
        before = #Q.queue
        ret.ticks = 1
        ret:update()
        check("not for a Disorganized character (as the game's ReturnItemToContainer)", #Q.queue == before)
        CHR.hasTrait = nil
    end
    Q.queue, s.queued = {}, nil
end

-- ---------------------------------------------------------------------------
section("call 6: the opening dish")
do
    for k in pairs(MD) do MD[k] = nil end
    put({ TOM }, { POT })
    rescan(nil)
    check("nothing made yet: the first rule's dish, Soup", CK.firstDish(s, CHR) == "Soup", CK.firstDish(s, CHR))
    s.dish, s.baseIdx, s.ingCache = "Stew", 1, nil
    plan(row("Base.Tomato"), 1)
    Q.queue, s.queued = {}, nil
    X.make(s, CHR, 1)
    check("Make remembers the dish", MD.ZeD_CookLast == "Stew", MD.ZeD_CookLast)
    Q.queue, s.queued = {}, nil
    rescan(nil)
    check("the tab opens on the last dish made, Stew", CK.firstDish(s, CHR) == "Stew", CK.firstDish(s, CHR))
    MD.ZeD_CookLast = "Sandwich"   -- (no bread in reach)
    check("the last dish not in reach: the first rule's dish", CK.firstDish(s, CHR) == "Soup", CK.firstDish(s, CHR))
    MD.ZeD_CookLast = nil
end

print("ck_calls_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
