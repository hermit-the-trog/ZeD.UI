-- ZeD-UI/42/media/lua/client/ZeD/CookingTab.lua
-- ============================================================================
-- COOKING TAB — client; a Character window tab that only shows in context.
--
-- The second way to make the game's pot-and-pan dishes (its evolved recipes: stews,
-- soups, stir-fries, salads, sandwiches, pies, drinks...), which are otherwise
-- right-click only. Built like the Crafting tab: the header picks the dish and what
-- it is made in; the left column lists the ingredients in reach that fit it (sorted by
-- ingredient or by kind), a press adds one; the right column is the dish as it grows
-- (a press takes an ingredient back out), its seasoning and what it will fill; the
-- band holds Sort, Save / Forget, the count when there is enough for more than one,
-- and Make. Make runs the game's own add-an-ingredient action for each ingredient in
-- turn, dish after dish (ZeD_CookAdd follows the dish as the first ingredient turns a
-- pot of water into a pot of stew), so the limits, the amounts by Cooking level and
-- the results are the game's. On a server ZeD_CookAdd cannot run (the server knows
-- no action from a client file), so Make there chains the game's own action with a
-- short wait of ZeD's between adds (ZeD_CookWait; "Make on a server" below).
--
-- Shown while a dish's base (a pot, a pan, a bowl, bread, a cup...) is on the player
-- and something in reach goes into it. Saved dishes live in the player's mod data.
-- Every layout number is a DESIGN UNIT and goes through T.px at use.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/CraftingCore"
require "ZeD/ZeD_TabPx"
require "ZeD/ZeD_CharacterWindow"
require "TimedActions/ISAddItemInRecipe"

ZeD = ZeD or {}
ZeD.CookingTab = ZeD.CookingTab or {}
local CK = ZeD.CookingTab

local TAB_ID     = "cooking"
local PAD        = 10
local ROW_H      = 24
local CAT_H      = 15
local SEC_H      = 20
local SCAN_MS    = 1000   -- what is in reach, looked at again this often
local SCROLL_STEP = 48
local MD_KEY     = "ZeD_CookDishes"
local MAX_SAVED  = 20     -- saved dishes kept; past it the oldest goes (FIFO)

local function now() return (getTimestampMs and getTimestampMs()) or 0 end
local function hit(z, x, y) return z ~= nil and x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h end
local function cased(s) return ZeD.textCase(tostring(s or "")) end
-- win: the tab's window; its player's mode (players 2-4 are always on a controller, and the pointer is player 1's)
local function isGamepad(win)
    local D = ZeD and ZeD.Input and ZeD.Input.Detector
    return (D and D.getMode and D.getMode(win and win.playerNum) == "gamepad") or false
end
local function help(panel, key, ...)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(panel, ZeD.tr(key, ...)) end
end
local function fullType(s)
    s = tostring(s or "")
    if not string.find(s, ".", 1, true) then s = "Base." .. s end
    return s
end

-- ----------------------------------------------------------------------------
-- The game's dishes, read once: grouped by dish (its untranslated name), with the
-- recipes each base starts
-- ----------------------------------------------------------------------------
local CAT = nil
local function catalog()
    if CAT then return CAT end
    CAT = { dishes = {}, order = {}, byBase = {}, keyOfLabel = {}, keyOf = {} }
    local ok, list = pcall(getEvolvedRecipes)
    if not ok or not list then return CAT end
    -- each dish is keyed by the plainest of its recipes' names (Stew, not StewForged), so a saved
    -- dish and a test read the same key whichever recipe the game lists first
    local function labelOf(r)
        local un = r:getUntranslatedName()
        return (getTextOrNull and getTextOrNull("ContextMenu_EvolvedRecipe_" .. un)) or r:getName() or un
    end
    for i = 0, list:size() - 1 do
        local r = list:get(i)
        local un, label = r:getUntranslatedName(), labelOf(r)
        local k = CAT.keyOfLabel[label]
        if not k or string.len(un) < string.len(k) or (string.len(un) == string.len(k) and un < k) then
            CAT.keyOfLabel[label] = un
        end
    end
    for i = 0, list:size() - 1 do
        local r = list:get(i)
        local hidden = false
        pcall(function() hidden = r:isHidden() end)
        local base = fullType(r:getBaseItem())
        local result = fullType(r:getFullResultItem())
        -- from scratch only: a recipe that adds to a dish already made (base == its result) is left to the game
        if not hidden and base ~= result then
            -- one dish per name: the game's Stir fry, Stir fry Griddle Pan and Stir fry Forged are one
            -- Stir-fry, made in whichever of them is at hand
            local label = labelOf(r)
            local key = CAT.keyOfLabel[label]
            CAT.keyOf[r] = key
            local d = CAT.dishes[key]
            if not d then
                d = { key = key, label = label, recipes = {} }
                CAT.dishes[key] = d
                CAT.order[#CAT.order + 1] = key
            end
            d.recipes[#d.recipes + 1] = r
            local b = CAT.byBase[base]
            if not b then b = {}; CAT.byBase[base] = b end
            b[#b + 1] = r
        end
    end
    table.sort(CAT.order, function(a, b) return CAT.dishes[a].label < CAT.dishes[b].label end)
    return CAT
end

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
local function st(win)
    local s = win._cook
    if not s then
        s = { dish = nil, baseIdx = 1, plan = {}, sort = "name", qty = 1, listScroll = 0, dishScroll = 0,
              zones = {}, byId = {}, scanAt = -1, popup = nil, loaded = nil }
        -- what the window's scroll hook gets (addTab, below): visible, so the window hands
        -- it the wheel, but off screen and deaf to the mouse; the wheel scrolls the column
        -- under the pointer (CK.onWheel)
        s.shim = { visible = true, x = -9999, y = -9999, dragging = false,
                   handleMouseDown = function() return false end, handleMouseMove = function() end,
                   handleMouseUp = function() end, setScrollPos = function() end,
                   handleMouseWheel = function(_, del) CK.onWheel(win, del) end }
        win._cook = s
    end
    return s
end

local function containersFor(chr)
    -- (the game's list reads the player's inventory pages; at quit the window draws once after they
    -- are gone, and the game's function prints its error even under pcall)
    local pn = chr:getPlayerNum()
    local ok0, ready = pcall(function() return getPlayerInventory(pn) ~= nil and getPlayerLoot(pn) ~= nil end)
    if not (ok0 and ready) then return ZeD.CraftingCore.buildContainers(chr) end
    local ok, list = pcall(ISInventoryPaneContextMenu.getContainers, chr)
    if ok and list and list:size() > 0 then return list end
    return ZeD.CraftingCore.buildContainers(chr)
end

-- where an item is, in a word (on you, a bag, the floor, a container)
local function whereOf(item, chr)
    local c = item:getContainer()
    if not c then return "" end
    if c == chr:getInventory() then return getText("IGUI_Controller_Inventory") end
    if c:getType() == "floor" then return getText("ContextMenu_Floor") end
    local ci = c:getContainingItem()
    if ci then return ci:getName() end
    local t = getTextOrNull and getTextOrNull("IGUI_ContainerTitle_" .. tostring(c:getType())) or nil
    return t or tostring(c:getType())
end

local function onPlayer(item, chr)
    local c = item:getContainer()
    if not c then return false end
    if c == chr:getInventory() then return true end
    local ci = c:getContainingItem()
    return ci ~= nil and ci:getContainer() == chr:getInventory()
end

-- the water a pot needs before it takes ingredients (soups and stews)
local function waterOk(r, item)
    local need = 0
    pcall(function() need = r:getMinimumWater() or 0 end)
    if need <= 0 then return true end
    local ok, has = pcall(function() return r:hasMinimumWater(item) end)
    return ok and has and true or false
end

-- What is in reach, about once a second: the bases (by dish) and the containers.
-- s.bases[dishKey] = { { item, recipe, name, where, ok, mine }, ... }
local function scan(s, chr, force)
    local t = now()
    if not force and s.scanAt >= 0 and t - s.scanAt < SCAN_MS then return end
    s.scanAt = t
    local C = catalog()
    local containers = containersFor(chr)
    s.containers = containers
    local bases, dishes = {}, {}
    for ci = 0, containers:size() - 1 do
        local items = containers:get(ci):getItems()
        for ii = 0, items:size() - 1 do
            local item = items:get(ii)
            local rs = C.byBase[item:getFullType()]
            if rs then
                for _, r in ipairs(rs) do
                    local key = C.keyOf[r] or r:getUntranslatedName()
                    local list = bases[key]
                    if not list then list = {}; bases[key] = list; dishes[#dishes + 1] = key end
                    list[#list + 1] = { item = item, recipe = r, name = item:getDisplayName(), where = whereOf(item, chr),
                                        ok = waterOk(r, item), mine = onPlayer(item, chr) }
                end
            end
        end
    end
    -- the bases on the player first (Make takes those), ready ones before ones that need water
    for _, list in pairs(bases) do
        table.sort(list, function(a, b)
            if a.mine ~= b.mine then return a.mine end
            if a.ok ~= b.ok then return a.ok end
            return a.name < b.name
        end)
    end
    table.sort(dishes, function(a, b) return (C.dishes[a].label or a) < (C.dishes[b].label or b) end)
    s.bases, s.dishList = bases, dishes
    s.ingCache = nil
end

local function curBase(s)
    local list = s.dish and s.bases and s.bases[s.dish]
    if not list or #list == 0 then return nil end
    if s.baseIdx > #list then s.baseIdx = 1 end
    return list[s.baseIdx]
end

-- The ingredients in reach for the chosen base, grouped by kind of item:
-- { ft, name, kind, kindLabel, spice, use, tex, items = {...}, n, why } (why: the game's reason it cannot go in)
local function ingredients(s, chr)
    local b = curBase(s)
    if not b then return {} end
    local c = s.ingCache
    if c and c.item == b.item and c.at == s.scanAt then return c.list end
    local r = b.recipe
    local ok, items = pcall(function() return r:getItemsCanBeUse(chr, b.item, s.containers) end)
    local groups, byFt = {}, {}
    local lvl = chr:getPerkLevel(Perks.Cooking)
    if ok and items then
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it ~= b.item then
                local ft = it:getFullType()
                local g = byFt[ft]
                if not g then
                    local spice = false
                    -- as the game's own menu reads it: a food's own isSpice, the script's only for a non-food
                    -- (the script says spice for many vegetables; read that way a stir-fry took five)
                    pcall(function()
                        if instanceof(it, "Food") then spice = it:isSpice() else spice = it:getScriptItem():isSpice() end
                    end)
                    local kind = "Other"
                    pcall(function() if instanceof(it, "Food") and it:getFoodType() then kind = it:getFoodType() end end)
                    if spice then kind = "_spice" end
                    local kindLabel
                    if spice then kindLabel = ZeD.tr("UI_ZeD_Cook_Seasoning")
                    else
                        local kt = getTextOrNull and getTextOrNull("ContextMenu_FoodType_" .. kind) or nil
                        kindLabel = kt or getText("IGUI_ItemCat_Food")
                    end
                    local use = nil
                    pcall(function() use = ISInventoryPaneContextMenu.getRealEvolvedItemUse(it, r, lvl) end)
                    g = { ft = ft, name = it:getDisplayName(), kind = kind, kindLabel = kindLabel, spice = spice,
                          use = use, items = {}, tex = it:getTex() }
                    byFt[ft] = g
                    groups[#groups + 1] = g
                end
                -- the game's own refusals: frozen food (most dishes), food that must be cooked first
                local why = nil
                if instanceof(it, "Food") and it:isFrozen() and not r:isAllowFrozenItem() then
                    why = getText("ContextMenu_CantAddFrozenFood")
                elseif not r:needToBeCooked(it) then
                    why = getText("ContextMenu_NeedCooked")
                end
                if why then g.why = g.why or why else g.items[#g.items + 1] = it end
            end
        end
    end
    -- every item of each kind in reach, in the same state as the one the game offers (the game's list
    -- may hold one of each kind; the count and Make need them all)
    local function same(a, b)
        if not instanceof(a, "Food") then return true end
        return a:isRotten() == b:isRotten() and a:isFrozen() == b:isFrozen() and a:isBurnt() == b:isBurnt()
            and a:isCooked() == b:isCooked()
    end
    for _, g in ipairs(groups) do
        local rep = g.items[1]
        if rep then
            local have = {}
            for _, it in ipairs(g.items) do have[it] = true end
            for ci = 0, s.containers:size() - 1 do
                local list = s.containers:get(ci):getItemsFromFullType(g.ft)
                if list then
                    for ii = 0, list:size() - 1 do
                        local it = list:get(ii)
                        if not have[it] and it ~= b.item and same(it, rep) then have[it] = true; g.items[#g.items + 1] = it end
                    end
                end
            end
        end
        g.n = #g.items
    end
    s.ingCache = { item = b.item, at = s.scanAt, list = groups, byFt = byFt }
    return groups
end

-- the plan's counts: how many of each kind of item, the ingredients that count toward the limit
local function planCounts(s)
    local need, n = {}, 0
    for _, e in ipairs(s.plan) do
        need[e.ft] = (need[e.ft] or 0) + 1
        if not e.spice then n = n + 1 end
    end
    return need, n
end

local function maxItems(s)
    local b = curBase(s)
    return b and b.recipe:getMaxItems() or 0
end

-- How many of this dish what is in reach makes (bases of the same kind, each ingredient's count)
local function howMany(s, chr)
    local b = curBase(s)
    if not b or #s.plan == 0 then return 0 end
    local ing = ingredients(s, chr)
    local byFt = s.ingCache and s.ingCache.byFt or {}
    local nb = 0
    for _, o in ipairs(s.bases[s.dish] or {}) do
        if o.ok and o.item:getFullType() == b.item:getFullType() and o.recipe == b.recipe then nb = nb + 1 end
    end
    if not b.ok then return 0 end
    local n = nb
    local need = planCounts(s)
    for ft, k in pairs(need) do
        local g = byFt[ft]
        local have = g and g.n or 0
        n = math.min(n, math.floor(have / k))
    end
    return math.max(0, n)
end

-- ----------------------------------------------------------------------------
-- Make: the game's add-an-ingredient action, one ingredient after another. The first
-- ingredient turns the base into the dish (a pot of water becomes a pot of stew), so
-- each action takes the dish the one before it left (chain.base).
-- ----------------------------------------------------------------------------
ZeD_CookAdd = ISAddItemInRecipe:derive("ZeD_CookAdd")
function ZeD_CookAdd:new(character, recipe, chain, usedItem)
    local o = ISAddItemInRecipe.new(self, character, recipe, chain.base, usedItem)
    o.chain = chain
    return o
end
function ZeD_CookAdd:isValidStart()
    self.baseItem = self.chain.base
    return ISAddItemInRecipe.isValidStart(self)
end
function ZeD_CookAdd:start()
    self.baseItem = self.chain.base
    ISAddItemInRecipe.start(self)
end
function ZeD_CookAdd:complete()
    -- the dish as it is now: in 42.22 an action's complete() runs after the next one's isValidStart()
    -- and start(), so the next add would begin on the plain pot and make a second stew; the
    -- completes run in queue order, so the chain is right here
    self.baseItem = self.chain.base
    local ok = ISAddItemInRecipe.complete(self)
    self.chain.base = self.baseItem
    return ok
end

-- ----------------------------------------------------------------------------
-- Make on a server. The server builds an action's own half from its Lua type and runs its complete() there;
-- ZeD_CookAdd lives in this client file, so the server does not know it and the add stops at once (no stew,
-- the ingredients untouched). The game's own ISAddItemInRecipe works there. So on a server each ingredient
-- is the game's own action, and before each one after the first a short wait of ZeD's own (client only, no
-- complete(), like ZeDOpenCardAction in ObjectCards.lua) finds the dish the last add left and queues the
-- next add onto it: the first add turns the base into another item (a pot of water becomes a pot of stew,
-- with a new id), made on the server and sent back.
-- ----------------------------------------------------------------------------
-- the dish this chain cooks into, once the server has made it (nil: not yet)
local function findDish(chr, recipe, chain)
    local inv = chr:getInventory()
    local cur = chain.baseId and inv:getItemById(chain.baseId)
    if cur then
        -- the base still here: the dish when the last add has turned it, else the add is not done yet
        if recipe:isResultItem(cur) then return cur end
        return nil
    end
    -- the base gone: the new dish is a result item that was not here before and no other chain has taken, the
    -- newest first (a new item goes at the end: with two dishes made at once, this chain's is the last one made)
    local items = inv:getItems()
    for i = items:size() - 1, 0, -1 do
        local it = items:get(i)
        local id = it:getID()
        if not chain.seen[id] and recipe:isResultItem(it) then return it end
    end
    return nil
end

ZeD_CookWait = ZeD_CookWait or ISBaseTimedAction:derive("ZeD_CookWait")
function ZeD_CookWait:new(character, recipe, chain, usedItem)
    local o = ISBaseTimedAction.new(self, character)
    o.recipe, o.chain, o.usedItem = recipe, chain, usedItem
    o.maxTime = -1   -- (no set length: update() ends it)
    o.useProgressBar = false
    o.stopOnWalk, o.stopOnRun = true, true
    return o
end
function ZeD_CookWait:isValid() return true end
function ZeD_CookWait:isValidStart() return true end
function ZeD_CookWait:start() self.t0 = getTimestampMs() end
function ZeD_CookWait:stop() ISBaseTimedAction.stop(self) end
function ZeD_CookWait:perform() ISBaseTimedAction.perform(self) end
function ZeD_CookWait:update()
    local ok, dish = pcall(findDish, self.character, self.recipe, self.chain)
    if ok and dish then
        local ch = self.chain
        ch.base, ch.baseId = dish, dish:getID()
        ch.seen[ch.baseId] = true
        ISTimedActionQueue.addAfter(self, ISAddItemInRecipe:new(self.character, self.recipe, dish, self.usedItem))
        self:forceComplete()
    elseif not ok or getTimestampMs() - (self.t0 or 0) > 10000 then
        -- (no dish from the server within 10 s: the rest of this dish's adds go no further)
        if not ok then ZeD.logOnce("cook wait", dish) end
        self:forceStop()
    end
end

local function make(s, chr, n)
    local b = curBase(s)
    if not b or n < 1 then return end
    ingredients(s, chr)
    local byFt = s.ingCache and s.ingCache.byFt or {}
    local inv = chr:getInventory()
    -- the bases: the chosen one first, then others like it
    local bases = { b }
    for _, o in ipairs(s.bases[s.dish] or {}) do
        if #bases >= n then break end
        if o ~= b and o.ok and o.item:getFullType() == b.item:getFullType() and o.recipe == b.recipe then bases[#bases + 1] = o end
    end
    local taken, back = {}, {}
    local function pick(ft)
        local g = byFt[ft]
        if not g then return nil end
        -- what the player carries first
        for pass = 1, 2 do
            for _, it in ipairs(g.items) do
                if not taken[it] and ((pass == 1) == (it:getContainer() == inv)) then taken[it] = true; return it end
            end
        end
        return nil
    end
    local function bring(item)
        if item:getContainer() ~= inv then
            ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(chr, item, item:getContainer(), inv, nil))
            back[#back + 1] = item
            return true
        end
        return false
    end
    -- (on a server: the result items already here are not a new dish, for any of the chains)
    local server = isClient()
    local seen = {}
    if server then
        local items = inv:getItems()
        for i = 0, items:size() - 1 do seen[items:get(i):getID()] = true end
    end
    for k = 1, math.min(n, #bases) do
        local bk = bases[k]
        bring(bk.item)
        local chain = { base = bk.item, baseId = bk.item:getID(), seen = seen }
        local first = true
        for _, e in ipairs(s.plan) do
            local it = pick(e.ft)
            if it then
                bring(it)
                if instanceof(it, "Food") then it:setChef(chr:getUsername()) end
                if not server then
                    ISTimedActionQueue.add(ZeD_CookAdd:new(chr, bk.recipe, chain, it))
                elseif first then
                    ISTimedActionQueue.add(ISAddItemInRecipe:new(chr, bk.recipe, bk.item, it))
                else
                    ISTimedActionQueue.add(ZeD_CookWait:new(chr, bk.recipe, chain, it))
                end
                first = false
            end
        end
    end
    -- what came from elsewhere goes back where it was (as the game's own menu does)
    if #back > 0 and ISCraftingUI and ISCraftingUI.ReturnItemsToOriginalContainer then
        pcall(ISCraftingUI.ReturnItemsToOriginalContainer, chr, back)
    end
    s.scanAt = -1
end

-- ----------------------------------------------------------------------------
-- Saved dishes: { dish, base (full type), items = { { ft, spice, name } } } in the player's mod data
-- ----------------------------------------------------------------------------
local function savedList(chr)
    local md = chr:getModData()
    local l = md[MD_KEY]
    if type(l) ~= "table" then l = {}; md[MD_KEY] = l end
    return l
end
local function samePlan(a, s)
    if not a or a.dish ~= s.dish or #a.items ~= #s.plan then return false end
    for i, e in ipairs(a.items) do if e.ft ~= s.plan[i].ft then return false end end
    return true
end
local function savedIndex(s, chr)
    for i, d in ipairs(savedList(chr)) do if samePlan(d, s) then return i end end
    return nil
end
local function saveDish(s, chr)
    if #s.plan == 0 or savedIndex(s, chr) then return end
    local b = curBase(s)
    local d = { dish = s.dish, base = b and b.item:getFullType() or nil, items = {} }
    for i, e in ipairs(s.plan) do d.items[i] = { ft = e.ft, spice = e.spice, name = e.name } end
    local l = savedList(chr)
    l[#l + 1] = d
    while #l > MAX_SAVED do table.remove(l, 1) end
end
local function forgetDish(s, chr)
    local i = savedIndex(s, chr)
    if i then table.remove(savedList(chr), i) end
end
local function savedLabel(d)
    local C = catalog()
    local dl = C.dishes[d.dish] and C.dishes[d.dish].label or d.dish
    local names = {}
    for i, e in ipairs(d.items) do if i <= 4 then names[#names + 1] = e.name end end
    local s = dl .. ": " .. table.concat(names, ", ")
    if #d.items > 4 then s = s .. ", ..." end
    return s
end
local function loadSaved(s, chr, d)
    s.dish, s.baseIdx, s.plan = d.dish, 1, {}
    for i, o in ipairs((s.bases and s.bases[d.dish]) or {}) do
        if o.item:getFullType() == d.base and o.ok then s.baseIdx = i; break end
    end
    for i, e in ipairs(d.items) do s.plan[i] = { ft = e.ft, spice = e.spice, name = e.name } end
    s.qty, s.dishScroll = 1, 0
end

-- ----------------------------------------------------------------------------
-- Focus (the controller's mark): one id for each stamped zone; the mark is drawn by
-- each control from ZeD.Focus.mark while it draws
-- ----------------------------------------------------------------------------
local function gpFocusedId(win)
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not (Focus and Focus.liveZone) then return nil end
    local zone = Focus.liveZone(win)
    if not zone or zone.zone ~= "charTabContent" then return nil end
    local el = Focus.getFocusedElement and Focus.getFocusedElement(win)
    local id = el and el.id
    if id and id:sub(1, 5) == "cook:" then return id end
    return nil
end
local _mfo = { zone = "charTabContent" }
local function focusFor(s, id)
    if id ~= nil and s.gpId == id then _mfo.win, _mfo.solid = s.win, false; return _mfo end
    return nil
end
local function markAt(s, panel, id, x, y, w, h)
    if id == nil or s.gpId ~= id then return false end
    _mfo.win, _mfo.solid = s.win, false
    return ZeD.Focus.mark(panel, x, y, w, h, _mfo) and true or false
end
local function stamp(s, id, x, y, w, h, fn, opts)
    local z = { id = id, x = x, y = y, w = w, h = h, fn = fn }
    if opts then for k, v in pairs(opts) do z[k] = v end end
    s.zones[#s.zones + 1] = z
    s.byId[id] = z
    return z
end

local function drawScrollbar(panel, win, key, x, top, h, total, scrollY, set)
    if total <= h then return end
    ZeD.Molecules.scrollBar(panel, win, key, x, top, ZeD.T.sp.scrollbarW, h, scrollY, total, set)
end

-- ----------------------------------------------------------------------------
-- The header: Dish and the base it is made in, as pop-up boxes (the band's look)
-- ----------------------------------------------------------------------------
local function renderHeader(panel, s, x, y, w, chr)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local CC = ZeD.CraftingCore
    -- the tab's title on row 1 (design review C1: every tab body opens with its title), the
    -- boxes on the shared strip under it
    local titleH = M.drawTabHeader(panel, x, y, w, getText("IGUI_perks_Cooking"), false, false, true)
    y = y + titleH
    local h = T.stripH   -- the boxes' row, the shared strip
    A.surfaceFill(panel, x, y, w, h, "surf2")
    A.drawDividerH(panel, x, y + h - T.line(T.borderW), w, true)
    local C = catalog()
    local bh = T.buttonH
    local by = y + math.floor((h - bh) / 2)
    local gap, edge = T.px(8), T.px(PAD)
    local dishW = math.floor((w - edge * 2 - gap) * 0.5)
    local baseW = w - edge * 2 - gap - dishW
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local dl = s.dish and C.dishes[s.dish] and C.dishes[s.dish].label or "-"
    local dx = x + edge
    local hovD = not isGamepad(s.win) and mx >= dx and mx < dx + dishW and my >= by and my < by + bh
    M.drawPopupMenu(panel, dx, by, dishW, bh, ZeD.tr("UI_ZeD_Cook_DishPick", dl), hovD or s.popup == "dish", focusFor(s, "cook:dish"), false, nil, false)
    stamp(s, "cook:dish", dx, by, dishW, bh, function() s.popup = (s.popup ~= "dish") and "dish" or nil end, { box = true })
    -- the dish list: your saved dishes first ("saved"), then every dish a base in reach makes
    local modes = {}
    for i, d in ipairs(savedList(chr)) do
        if s.bases and s.bases[d.dish] then
            modes[#modes + 1] = { id = "saved:" .. i, label = savedLabel(d), aside = ZeD.tr("UI_ZeD_Cook_Saved") }
        end
    end
    for _, key in ipairs(s.dishList or {}) do
        modes[#modes + 1] = { id = "dish:" .. key, label = C.dishes[key] and C.dishes[key].label or key }
    end
    s.dishGeo = { x = dx, y = by + bh, w = dishW, modes = modes, cur = s.dish and ("dish:" .. s.dish) or nil }

    local b = curBase(s)
    local bx = dx + dishW + gap
    local bl = b and b.name or "-"
    local hovB = not isGamepad(s.win) and mx >= bx and mx < bx + baseW and my >= by and my < by + bh
    M.drawPopupMenu(panel, bx, by, baseW, bh, ZeD.tr("UI_ZeD_Cook_BasePick", bl), hovB or s.popup == "base", focusFor(s, "cook:base"), false, nil, false)
    stamp(s, "cook:base", bx, by, baseW, bh, function() s.popup = (s.popup ~= "base") and "base" or nil end, { box = true })
    local bmodes = {}
    for i, o in ipairs((s.dish and s.bases and s.bases[s.dish]) or {}) do
        bmodes[#bmodes + 1] = { id = "base:" .. i, label = o.name,
                                aside = o.ok and o.where or ZeD.tr("UI_ZeD_Cook_NeedsWater"), disabled = not o.ok }
    end
    s.baseGeo = { x = bx, y = by + bh, w = baseW, modes = bmodes, cur = "base:" .. tostring(s.baseIdx) }
    return titleH + h
end

-- ----------------------------------------------------------------------------
-- Left: the ingredients in reach that fit
-- ----------------------------------------------------------------------------
local function renderIngredients(panel, win, s, x, top, w, bodyH, chr, mouse)
    local T, A, M, TM = ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.TM
    local scrollW = T.sp.scrollbarW
    local cw = w - scrollW
    local pad = T.px(PAD)
    local clip = { x = x, y = top, w = w, h = bodyH }
    local mx, my = mouse and mouse.x or -1, mouse and mouse.y or -1
    local ing = ingredients(s, chr)
    local need, n = planCounts(s)
    local full = n >= maxItems(s)
    panel:setStencilRect(x, top, w, bodyH)
    local cy = top - s.listScroll
    if #ing == 0 then
        cy = cy + T.px(8)
        cy = cy + M.drawEmptyLine(panel, x + pad, cy, cw - pad * 2, ZeD.tr("UI_ZeD_Cook_NoIngredients")) + T.px(8)
    end
    -- the groups: one, A to Z (By ingredient), or one per kind, seasoning last (By kind).
    -- grouped and sorted once per ingredient list (ingCache) and sort,
    -- not every frame: the same rows in the same order while neither changes
    local gc = s._ingGroups
    local groups
    if gc and gc.src == ing and gc.sort == s.sort then
        groups = gc.groups
        if groups[1] and groups[1].kind == "_all" then groups[1].label = getText("IGUI_perks_Cooking") end
    else
    groups = {}
    if s.sort == "kind" then
        local byK = {}
        for _, g in ipairs(ing) do
            local k = byK[g.kind]
            if not k then k = { label = g.kindLabel, kind = g.kind, rows = {} }; byK[g.kind] = k; groups[#groups + 1] = k end
            k.rows[#k.rows + 1] = g
        end
        table.sort(groups, function(a, b)
            if (a.kind == "_spice") ~= (b.kind == "_spice") then return b.kind == "_spice" end
            return a.label < b.label
        end)
    else
        local rows = {}
        for _, g in ipairs(ing) do rows[#rows + 1] = g end
        groups[1] = { label = getText("IGUI_perks_Cooking"), rows = rows, kind = "_all" }
    end
    for _, grp in ipairs(groups) do
        table.sort(grp.rows, function(a, b) return a.name < b.name end)
    end
    s._ingGroups = { src = ing, sort = s.sort, groups = groups }
    end
    s.collapsed = s.collapsed or {}
    for _, grp in ipairs(groups) do
        if s.sort == "kind" then
            local ch = T.px(CAT_H)
            local key = grp.kind
            local hov = mouse ~= nil and my >= cy and my < cy + ch
            M.drawCategoryRow(panel, x, cy, cw, grp.label, #grp.rows, not s.collapsed[key],
                { hover = hov, focus = focusFor(s, "cook:cat:" .. key), inset = pad })
            stamp(s, "cook:cat:" .. key, x, cy, cw, ch, function() s.collapsed[key] = not s.collapsed[key] end,
                  { clip = clip, isDisclosure = true, pane = "list" })
            cy = cy + ch
        end
        if not (s.sort == "kind" and s.collapsed[grp.kind]) then
            for ri, g in ipairs(grp.rows) do
                local rh = T.px(ROW_H)
                -- can it go in: the game's reasons first, then the dish's room, then what is left in reach
                local left = g.n - (need[g.ft] or 0)
                local can = g.n > 0 and left > 0 and not g.why
                if can and g.spice and need[g.ft] then can = false end           -- a seasoning goes in once
                if can and not g.spice and full then can = false end
                if ri % 2 == 0 then local sp = T.stripe; panel:drawRect(x, cy, cw, rh, sp.a, sp.r, sp.g, sp.b) end
                local hov = can and mouse ~= nil and my >= cy and my < cy + rh and mx >= x and mx < x + cw
                if hov then local hv = T.hover; panel:drawRect(x, cy, cw, rh, hv.a, hv.r, hv.g, hv.b) end
                local id = "cook:ing:" .. g.ft
                local onFocus = markAt(s, panel, id, x, cy, cw, rh)
                local ink = onFocus and T.textOnFocus or T.text
                local dim = onFocus and T.textOnFocus or T.textDim
                local a = can and 1 or T.disabledAlpha
                local isz = T.px(16)
                if g.tex then A.drawIcon(panel, g.tex, x + pad, cy + math.floor((rh - isz) / 2), isz, a, T.iconWhite) end
                local tx = x + pad + isz + T.px(6)
                -- the right end: how many are in reach, and what one gives at your level (the game's "(1/4)")
                local right = x + cw - pad
                local cnt = "x" .. tostring(math.max(0, left))
                A.drawTextRight(panel, cnt, right, cy + math.floor((rh - T.fontF3H) / 2), T.fontF3, ink)
                local rx = right - TM:MeasureStringX(T.fontF3, cnt) - T.px(6)
                if g.use and not g.spice then
                    local u = tostring(g.use)
                    A.drawTextRight(panel, u, rx, cy + math.floor((rh - T.fontF1H) / 2), T.fontF1, dim)
                    rx = rx - TM:MeasureStringX(T.fontF1, u) - T.px(6)
                end
                local nm = A.truncateText(g.name, T.fontF2, math.max(0, rx - tx))
                panel:drawText(nm, tx, cy + math.floor((rh - T.fontF2H) / 2), ink.r, ink.g, ink.b, (ink.a or 1) * a, T.fontF2)
                if mouse ~= nil and my >= cy and my < cy + rh and mx >= x and mx < x + cw then
                    if g.why then ZeD.Help.set(panel, g.why)
                    elseif not can and full and not g.spice then help(panel, "UI_ZeD_Cook_Full")
                    else help(panel, "UI_ZeD_Cook_HelpAdd") end
                end
                local ft, nmFull, spice = g.ft, g.name, g.spice
                stamp(s, id, x, cy, cw, rh, function()
                    if not can then return end
                    s.plan[#s.plan + 1] = { ft = ft, name = nmFull, spice = spice }
                end, { clip = clip, pane = "list", disabled = not can })
                cy = cy + rh
            end
        end
    end
    panel:clearStencilRect()
    local total = (cy + s.listScroll) - top
    s.maxList = math.max(0, total - bodyH)
    if s.listScroll > s.maxList then s.listScroll = s.maxList end
    drawScrollbar(panel, win, "cook:list", x + w - scrollW, top, bodyH, total, s.listScroll, function(v) s.listScroll = v end)
end

-- ----------------------------------------------------------------------------
-- Right: the dish as it grows
-- ----------------------------------------------------------------------------
local _secOpts = {}   -- the section heading's opts (drawCategoryRow)
local function renderDish(panel, win, s, x, top, w, bodyH, chr, mouse)
    local T, A, M, TM = ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.TM
    local scrollW = T.sp.scrollbarW
    local cw = w - scrollW
    local pad = T.px(PAD)
    local iw = cw - pad * 2
    local clip = { x = x, y = top, w = w, h = bodyH }
    local mx, my = mouse and mouse.x or -1, mouse and mouse.y or -1
    local C = catalog()
    local b = curBase(s)
    local ing = ingredients(s, chr)
    local byFt = s.ingCache and s.ingCache.byFt or {}
    local need, n = planCounts(s)
    panel:setStencilRect(x, top, w, bodyH)
    local cy = top - s.dishScroll + pad
    -- the dish, and what it is made in
    local hc, dc = T.text, T.textDim
    local dl = s.dish and C.dishes[s.dish] and C.dishes[s.dish].label or ""
    panel:drawText(A.truncateText(dl, T.fontF4, iw), x + pad, cy, hc.r, hc.g, hc.b, hc.a or 1, T.fontF4)
    cy = cy + T.fontF4H
    if b then
        local line = b.name .. (b.ok and "" or ("  |  " .. ZeD.tr("UI_ZeD_Cook_NeedsWater")))
        panel:drawText(A.truncateText(line, T.fontF1, iw), x + pad, cy, dc.r, dc.g, dc.b, dc.a or 1, T.fontF1)
        cy = cy + T.fontF1H
    end
    cy = cy + T.px(10)

    local function section(text)
        -- (the one section heading, the small mono line: design review D6)
        _secOpts.noArrow, _secOpts.bleedLeft, _secOpts.h, _secOpts.inset = true, pad, T.px(SEC_H), 0
        local sh = M.drawCategoryRow(panel, x + pad, cy, cw - pad, text, nil, true, _secOpts)
        cy = cy + sh + T.px(4)
    end
    -- one ingredient's row; a press takes it back out. A saved dish's ingredient not in reach reads so,
    -- with a key that takes one of the same kind instead (it never swaps by itself)
    local seen = {}
    local function row(i, e)
        local rh = T.px(ROW_H)
        seen[e.ft] = (seen[e.ft] or 0) + 1
        local g = byFt[e.ft]
        local missing = (not g) or (g.n < seen[e.ft])
        local hov = mouse ~= nil and my >= cy and my < cy + rh and mx >= x and mx < x + cw
        if hov then local hv = T.hover; panel:drawRect(x, cy, cw, rh, hv.a, hv.r, hv.g, hv.b) end
        local id = "cook:plan:" .. i
        local onFocus = markAt(s, panel, id, x, cy, cw, rh)
        local ink = onFocus and T.textOnFocus or T.text
        local d = T.px(7)
        A.drawStatusDot(panel, x + pad, cy + math.floor((rh - d) / 2), missing and T.danger or T.positive, d)
        local tx = x + pad + d + T.px(8)
        local right = x + cw - pad
        if missing then
            -- the same kind in reach, not already in the dish: offered, never taken by itself
            local alt = nil
            local kind = nil
            for _, o in ipairs(ing) do if o.ft == e.ft then kind = o.kind end end
            for _, o in ipairs(ing) do
                if not alt and o.ft ~= e.ft and o.spice == e.spice and o.n > (need[o.ft] or 0) and not o.why
                   and (kind == nil or o.kind == kind) then alt = o end
            end
            if alt then
                local label = ZeD.tr("UI_ZeD_Cook_UseInstead", alt.name)
                local bw = math.min(math.floor(iw * 0.55), M.buttonW(label))
                local bh = rh - T.px(4)
                M.drawButton(panel, right - bw, cy + T.px(2), bw, bh, label, "default", false, nil,
                    { focus = focusFor(s, "cook:alt:" .. i), win = win, compact = true })
                local idx, aft, aname = i, alt.ft, alt.name
                stamp(s, "cook:alt:" .. i, right - bw, cy + T.px(2), bw, bh, function()
                    s.plan[idx] = { ft = aft, name = aname, spice = e.spice }
                end, { clip = clip, pane = "dish" })
                right = right - bw - T.px(6)
            else
                local nt = cased(ZeD.tr("UI_ZeD_Cook_NotInReach"))
                A.drawTextRight(panel, nt, right, cy + math.floor((rh - T.fontF1H) / 2), T.fontF1, T.danger)
                right = right - TM:MeasureStringX(T.fontF1, nt) - T.px(6)
            end
        end
        panel:drawText(A.truncateText(e.name, T.fontF2, math.max(0, right - tx)), tx, cy + math.floor((rh - T.fontF2H) / 2), ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
        if hov then help(panel, "UI_ZeD_Cook_HelpRemove") end
        local idx = i
        stamp(s, id, x, cy, missing and math.max(0, right - x) or cw, rh, function()
            table.remove(s.plan, idx)
            if s.qty > 1 then s.qty = 1 end
        end, { clip = clip, pane = "dish", planRow = true })
        A.drawDividerH(panel, x + pad, cy + rh - T.px(1), iw, false)
        cy = cy + rh
        return missing
    end
    local anyMissing = false
    section(ZeD.tr("UI_ZeD_Cook_Ingredients", n, maxItems(s)))
    if n == 0 then
        cy = cy + M.drawEmptyLine(panel, x + pad, cy, iw, ZeD.tr("UI_ZeD_Cook_EmptyDish")) + T.px(6)
    end
    for i, e in ipairs(s.plan) do if not e.spice then anyMissing = row(i, e) or anyMissing end end
    local hasSpice = false
    for _, e in ipairs(s.plan) do if e.spice then hasSpice = true end end
    if hasSpice then
        cy = cy + T.px(6)
        section(ZeD.tr("UI_ZeD_Cook_Seasoning"))
        for i, e in ipairs(s.plan) do if e.spice then anyMissing = row(i, e) or anyMissing end end
    end
    s.anyMissing = anyMissing
    -- what it will fill: the hunger the ingredients bring, as the game reckons each at your level
    local fill = 0
    for _, e in ipairs(s.plan) do
        local g = byFt[e.ft]
        if g and g.use and not e.spice then fill = fill + (tonumber(g.use) or 0) end
    end
    if fill > 0 then
        cy = cy + T.px(10)
        cy = cy + M.drawStatRow(panel, x + pad, cy, iw, getText("Tooltip_food_Hunger"), tostring(math.floor(fill + 0.5)))
    end
    if b and b.recipe:isCookable() then
        cy = cy + T.px(6)
        local dcc = T.textDim
        for _, ln in ipairs(A.wrapText(ZeD.tr("UI_ZeD_Cook_CookAfter"), T.fontF2, iw)) do
            panel:drawText(ln, x + pad, cy, dcc.r, dcc.g, dcc.b, dcc.a or 1, T.fontF2)
            cy = cy + T.fontF2H
        end
    end
    panel:clearStencilRect()
    local total = (cy + pad + s.dishScroll) - top
    s.maxDish = math.max(0, total - bodyH)
    if s.dishScroll > s.maxDish then s.dishScroll = s.maxDish end
    drawScrollbar(panel, win, "cook:dish", x + w - scrollW, top, bodyH, total, s.dishScroll, function(v) s.dishScroll = v end)
end

-- ----------------------------------------------------------------------------
-- The band: Sort at the left; Save or Forget, the count (only when there is enough for
-- more than one) and Make at the right
-- ----------------------------------------------------------------------------
local _bandBtns, _bandSpec = {}, {}
_bandSpec.buttons = _bandBtns
local _stepOpts = {}

-- By ingredient (A to Z) and By kind (the game's food types): the game's own words
local function sortModes()
    return { { id = "name", label = getText("IGUI_Name") },
             { id = "kind", label = getText("IGUI_invpanel_Category") } }
end

local function renderBand(panel, win, s, x, y, w, chr)
    local T, M = ZeD.T, ZeD.Molecules
    local bh = T.buttonH
    local gap, edge = T.px(8), T.px(8)
    local maxN = howMany(s, chr)
    if s.qty > math.max(1, maxN) then s.qty = math.max(1, maxN) end
    local canMake = maxN >= 1 and not s.anyMissing and #s.plan > 0
    for i = #_bandBtns, 1, -1 do _bandBtns[i] = nil end
    local isSaved = savedIndex(s, chr) ~= nil
    if #s.plan > 0 then
        _bandBtns[#_bandBtns + 1] = { label = ZeD.tr(isSaved and "UI_ZeD_Cook_Forget" or "UI_ZeD_Cook_Save"), id = isSaved and "forget" or "save",
                                       focus = focusFor(s, isSaved and "cook:forget" or "cook:save") }
    end
    _bandBtns[#_bandBtns + 1] = { label = ZeD.tr("UI_ZeD_Cook_Make"), id = "make", variant = "primary", disabled = not canMake,
                                   focus = focusFor(s, "cook:make"), help = ZeD.tr("UI_ZeD_Cook_HelpBuild") }
    _bandSpec.win = win
    local _, out = M.drawBand(panel, x, y, w, _bandSpec)
    for i, bb in ipairs(_bandBtns) do
        local r = out.buttons[i]
        if r then
            if bb.id == "make" then
                stamp(s, "cook:make", r.x, r.y, r.w, r.h, function()
                    if not canMake then return end
                    make(s, chr, s.qty)
                    s.qty = 1
                end, { footer = true, disabled = not canMake })
            elseif bb.id == "save" then
                stamp(s, "cook:save", r.x, r.y, r.w, r.h, function() saveDish(s, chr) end, { footer = true })
            else
                stamp(s, "cook:forget", r.x, r.y, r.w, r.h, function() forgetDish(s, chr) end, { footer = true })
            end
        end
    end
    -- the count, left of the buttons, only when what is in reach makes more than one
    local leftEnd = (out.buttons[1] and out.buttons[1].x or (x + w - edge)) - gap
    if maxN > 1 and canMake then
        local qtyTW = ZeD.TM:MeasureStringX(T.fontF3, tostring(s.qty))
        local qtyW = math.max(bh, qtyTW + T.px(8))
        local stepW = bh * 2 + qtyW + 2 * T.px(4)
        local sx = leftEnd - stepW
        local so = _stepOpts
        so.focusId, so.focus, so.win = nil, nil, win
        local g = s.gpId
        if g == "cook:dec" then so.focusId, so.focus = "dec", focusFor(s, g)
        elseif g == "cook:inc" then so.focusId, so.focus = "inc", focusFor(s, g) end
        local _, zs = M.drawQtyStepper(panel, sx, y + T.px(5), s.qty, maxN, bh, nil, so)
        for _, z in ipairs(zs) do
            if z.id == "dec" then
                stamp(s, "cook:dec", z.x, z.y, z.w, z.h, function() s.qty = math.max(1, s.qty - 1) end, { footer = true })
            elseif z.id == "inc" then
                stamp(s, "cook:inc", z.x, z.y, z.w, z.h, function() s.qty = math.min(maxN, s.qty + 1) end, { footer = true })
            end
        end
        leftEnd = sx - gap
    end
    -- Sort at the left: "Sort: Name", its label kept when short of room (design review C2): the
    -- pads close up, then the words are cut
    local modes = sortModes()
    local cur = (s.sort == "kind") and 2 or 1
    local full = ZeD.tr("UI_ZeD_Craft_SortPick", modes[cur].label)
    local sw = 0
    for _, m in ipairs(modes) do sw = math.max(sw, M.popupMenuW(ZeD.tr("UI_ZeD_Craft_SortPick", m.label))) end
    local label, tight = full, false
    if x + edge + sw > leftEnd then
        tight, sw = true, 0
        for _, m in ipairs(modes) do sw = math.max(sw, M.popupMenuW(ZeD.tr("UI_ZeD_Craft_SortPick", m.label), true)) end
        sw = math.min(sw, math.max(M.popupMenuW("", true), leftEnd - x - edge))
    end
    local sx = x + edge
    local by = y + T.px(5)
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local hov = not isGamepad(win) and mx >= sx and mx < sx + sw and my >= by and my < by + bh
    M.drawPopupMenu(panel, sx, by, sw, bh, label, hov or s.popup == "sort", focusFor(s, "cook:sort"), false, nil, tight)
    if hov then help(panel, "UI_ZeD_Craft_SortHelp") end
    stamp(s, "cook:sort", sx, by, sw, bh, function() s.popup = (s.popup ~= "sort") and "sort" or nil end, { footer = true, box = true })
    s.sortGeo = { x = sx, y = by - M.popupListH(#modes), w = sw, modes = modes, cur = s.sort }
end

-- The open pop-up list (Dish, the base, Sort), drawn last over the columns
local _popOpts = {}
local function renderPopup(panel, s, chr)
    local which = s.popup
    if not which then return end
    local g = (which == "dish" and s.dishGeo) or (which == "base" and s.baseGeo) or (which == "sort" and s.sortGeo) or nil
    if not g or #g.modes == 0 then s.popup = nil; return end
    local M = ZeD.Molecules
    local hoverId = nil
    if not isGamepad(s.win) and s.popZones then
        local mx, my = panel:getMouseX(), panel:getMouseY()
        for _, z in ipairs(s.popZones) do if hit(z, mx, my) then hoverId = z.id end end
    end
    _popOpts.minW, _popOpts.focusId, _popOpts.focus = g.w, nil, nil
    local gp = s.gpId
    if gp and gp:sub(1, 9) == "cook:pop:" then _popOpts.focusId, _popOpts.focus = gp:sub(10), focusFor(s, gp) end
    local _, _, zs = M.drawSortMenuList(panel, g.x, g.y, g.modes, g.cur, hoverId, _popOpts)
    s.popZones = zs
    for _, z in ipairs(zs) do
        local id = z.id
        stamp(s, "cook:pop:" .. id, z.x, z.y, z.w, z.h, function()
            if z.disabled then return end
            if which == "sort" then s.sort = id; s.listScroll = 0
            elseif which == "base" then s.baseIdx = tonumber(string.sub(id, 6)) or 1; s.ingCache = nil
            elseif string.sub(id, 1, 6) == "saved:" then
                local d = savedList(chr)[tonumber(string.sub(id, 7)) or 0]
                if d then loadSaved(s, chr, d) end
            else
                local key = string.sub(id, 6)
                if key ~= s.dish then s.dish, s.baseIdx, s.plan, s.qty, s.ingCache = key, 1, {}, 1, nil end
            end
            s.popup = nil

        end, { popRow = true, disabled = z.disabled })
    end
end

-- ----------------------------------------------------------------------------
-- The tab
-- ----------------------------------------------------------------------------
--- The tab's frame, as the Character window calls it (addTab, below): the header, the two
--- columns, the band, and an open pop-up list over them.
function CK.render(panel, win, x, y, w, h)
    local T = ZeD.T
    if not T then return end
    local s = st(win)
    s.zones, s.byId = {}, {}
    s.panel, s.win, s.gpId = panel, win, gpFocusedId(win)
    local chr = win._playerObj or getSpecificPlayer(win.playerNum or 0)   -- (the window's own player)
    if not chr then return end
    scan(s, chr, false)
    -- the dish: kept while a base for it is in reach, else the first one something in reach goes into
    -- (the one that put the tab up), else the first there is
    if not (s.dish and s.bases and s.bases[s.dish]) then
        s.dish, s.baseIdx, s.plan, s.qty = CK.firstDish(s, chr), 1, {}, 1
    end
    local CC = ZeD.CraftingCore
    local headH = renderHeader(panel, s, x, y, w, chr)
    local bandH = ZeD.Molecules.bandH()
    local top = y + headH
    local bodyH = h - headH - bandH
    local listW = T.px(CC.PANE_W_SPLIT or 240)
    local rx = x + listW + T.px(1)
    local rw = x + w - rx
    s.splitX = x + listW
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local inL = (not isGamepad(win)) and not s.popup and mx >= x and mx < x + listW and my >= top and my < top + bodyH
    local inR = (not isGamepad(win)) and not s.popup and mx >= rx and mx < x + w and my >= top and my < top + bodyH
    -- The Character window clips its drawer with a stencil, and PZ stencils do not nest: a column's own
    -- clip, once cleared, leaves its rect marked apart from the drawer's, so what draws over it later
    -- (the open Dish and Sort lists) would be hidden there. After each column the drawer's clip is laid
    -- again over the whole tab.
    local function relayClip()
        panel:clearStencilRect()
        panel:setStencilRect(x, y, w, h)
    end
    renderIngredients(panel, win, s, x, top, listW, bodyH, chr, inL and { x = mx, y = my } or nil)
    relayClip()
    local bd = T.borderS
    panel:drawRect(x + listW, top, T.px(1), bodyH, bd.a or 1, bd.r, bd.g, bd.b)
    renderDish(panel, win, s, rx, top, rw, bodyH, chr, inR and { x = mx, y = my } or nil)
    relayClip()
    -- the controller's scroll-follow, in the column the focused element is in
    local gp = s.gpId
    if gp then
        local z = s.byId[gp]
        if z and z.clip then
            local c = z.clip
            local key, maxKey = (z.pane == "dish") and "dishScroll" or "listScroll", (z.pane == "dish") and "maxDish" or "maxList"
            if z.y < c.y then s[key] = math.max(0, s[key] - (c.y - z.y))
            elseif z.y + z.h > c.y + c.h then s[key] = math.min(s[maxKey] or 0, s[key] + (z.y + z.h - (c.y + c.h))) end
        end
    end
    renderBand(panel, win, s, x, y + h - bandH, w, chr)
    renderPopup(panel, s, chr)
end

-- the wheel scrolls the column under the pointer (the scroll stand-in, s.shim, calls this)
function CK.onWheel(win, del)
    local s = st(win)
    local step = ZeD.T.px(SCROLL_STEP) * del
    local mx = s.panel and s.panel:getMouseX() or 0
    if s.splitX and mx > s.splitX then
        s.dishScroll = math.max(0, math.min(s.maxDish or 0, s.dishScroll + step))
    else
        s.listScroll = math.max(0, math.min(s.maxList or 0, s.listScroll + step))
    end
end

-- a press: with a pop-up list open only its rows and its box answer, and a press anywhere
-- else shuts it; otherwise the topmost zone under the pointer, inside its clip
function CK.onClick(win, x, y)
    local s = st(win)
    if s.popup then
        for i = #s.zones, 1, -1 do
            local z = s.zones[i]
            if (z.popRow or z.box) and hit(z, x, y) then
                pcall(function() getSoundManager():playUISound("UIActivateButton") end)
                z.fn()
                return
            end
        end
        s.popup = nil
        return
    end
    for i = #s.zones, 1, -1 do
        local z = s.zones[i]
        if hit(z, x, y) and (not z.clip or hit(z.clip, x, y)) then
            if not z.disabled then pcall(function() getSoundManager():playUISound("UIActivateButton") end) end
            z.fn()
            return
        end
    end
end

-- the controller: every stamped zone a stop; with a list open, its choices and its box only.
-- B shuts an open list; else it leaves the tab as every tab does
function CK.buildFocusables(win)
    local s = win and win._cook
    if not s then return {} end
    local els = {}
    for _, z in ipairs(s.zones) do
        local zz = z
        if not s.popup or zz.popRow or zz.box then
            local el = { x = zz.x, y = zz.y, w = zz.w, h = zz.h, id = zz.id, isDisclosure = zz.isDisclosure,
                         onActivate = function() zz.fn() end }
            if s.popup then
                el.onCancel = function() s.popup = nil; return true end
            end
            els[#els + 1] = el
        end
    end
    return els
end

-- the controller's stops are rebuilt whenever this key changes: the dish, the base, the plan,
-- the open list, both scrolls, the zones, the sort and the count
function CK.scrollKey(win)
    local s = win and win._cook
    if not s then return nil end
    return tostring(s.dish) .. ":" .. tostring(s.baseIdx) .. ":" .. tostring(#s.plan) .. ":" .. tostring(s.popup) .. ":"
        .. tostring(math.floor(s.listScroll or 0)) .. ":" .. tostring(math.floor(s.dishScroll or 0)) .. ":" .. tostring(#s.zones)
        .. ":" .. tostring(s.sort) .. ":" .. tostring(s.qty)
end

-- The dish the tab opens on: the first (by name) with a base on the player that something in reach
-- goes into, as CK.visible asks it. The first by name alone was often one nothing goes into (a
-- Beverage in an empty cup beside a pot of water and vegetables), and the tab then read "Nothing in
-- reach goes into this dish". With none such, the first there is.
function CK.firstDish(s, chr)
    local list = s.dishList or {}
    for _, key in ipairs(list) do
        for _, o in ipairs(s.bases[key] or {}) do
            if o.mine then
                local ok, items = pcall(function() return o.recipe:getItemsCanBeUse(chr, o.item, s.containers) end)
                if ok and items then
                    for i = 0, items:size() - 1 do
                        if items:get(i) ~= o.item then return key end   -- (the base itself is no ingredient)
                    end
                end
            end
        end
    end
    return list[1]
end

-- Shown while a base is on the player and something in reach goes into it (looked at
-- about once a second)
function CK.visible(win)
    local chr = win and win._playerObj
    if not chr then return false end
    local s = st(win)
    local t = now()
    if s.visAt and t - s.visAt < SCAN_MS then return s.vis end
    s.visAt = t
    local vis = false
    local ok = pcall(function()
        scan(s, chr, false)
        for _, key in ipairs(s.dishList or {}) do
            for _, o in ipairs(s.bases[key]) do
                if o.mine then
                    local items = o.recipe:getItemsCanBeUse(chr, o.item, s.containers)
                    if items and items:size() > 0 then vis = true; return end
                end
            end
        end
    end)
    s.vis = ok and vis or false
    return s.vis
end

-- its lit pixel-art icon, as every other tab's (ZeDUI/tools/tabpx/icons.py "cooking", drawn by ZeD_TabPx.lua)
if ZeD.TabPx and ZeD.TabPx.ICONS then ZeD.TabPx.ICONS[TAB_ID] = true end

ZeD_CharacterWindow.addTab({
    id = TAB_ID, after = "thermal", group = 1, glyph = "K",
    iconName = "cooking-tab-white",
    label = function() return getText("IGUI_perks_Cooking") end,
    visible = function(win) return CK.visible(win) end,
    render = function(...) return ZeD.CookingTab.render(...) end,
    scroll = function(win) return st(win).shim end,
    onClick = function(...) return ZeD.CookingTab.onClick(...) end,
    buildFocusables = function(...) return ZeD.CookingTab.buildFocusables(...) end,
    scrollKey = function(...) return ZeD.CookingTab.scrollKey(...) end,
})

print("[ZeD] CookingTab: Cooking tab loaded")
