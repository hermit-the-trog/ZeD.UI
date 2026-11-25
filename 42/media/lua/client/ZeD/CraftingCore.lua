-- ZeD-UI/42/media/lua/client/ZeD/CraftingCore.lua
-- ============================================================================
-- CRAFTING CORE — client; the shared engine behind the recipe tabs. The
-- Crafting, Building and Cooking tabs, the Journal's Recipes page and the
-- stations require it; the object cards and other tabs borrow its
-- truncText. Catalog helpers, container scanning, material counting, pins,
-- craft counts, filter and sort, text truncation, the state machine, the
-- drawer's rendering and the alternatives list.
--
-- Each consumer passes a `config` table (prefix, keys, labels, startAction)
-- that tells Craft from Build from the Journal's read-only list; per-window
-- caches live on the window under "_<prefix>..." keys. One thing to know:
-- the renderers reuse shared option and zone tables to avoid per-frame
-- garbage — set every field you use, and use what they hand back at once.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Tr"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/ZeD_Popups"

ZeD = ZeD or {}
ZeD.CraftingCore = ZeD.CraftingCore or {}

local CC = ZeD.CraftingCore
local M  = ZeD.Molecules
local NO_FOCUS_OPTS = {}   -- ZeD.Focus.mark's opts for a focused element (the window is the panel's)

-- the pointer's hover washes stay off while the controller's mark shows
local function cuesOn()
    local F = ZeD.Input and ZeD.Input.Focus
    return F and F.cuesVisible and F.cuesVisible() or false
end

-- ============================================================================
-- CONSTANTS — the drawer's settled layout numbers (design units)
-- ============================================================================

CC.DRAWER_W        = 480
CC.PANE_W_SOLO     = 480
CC.PANE_W_SPLIT    = 240
CC.ROW_H           = 24
CC.HEADER_H        = (ZeD.Spacing and ZeD.Spacing.tabHeaderH) or 37  -- design units, kept for add-ons; the header draws at ZeD.T.stripH (row 1)
CC.STRIP_H          = 20    -- design units, kept for add-ons; the alternatives strip draws at ZeD.T.sortBarH (row 2)
CC.MAX_PINS        = 8
CC.ANIM_DURATION   = 0.28  -- pane split animation in seconds

-- Throttle intervals (ms)
local CONTAINER_MS = 1500

-- Time-based throttles: a frame count runs
-- 2.4-4x as often at 144-240 Hz, and timers made together would fire together. CC.due(win, key, ms, force)
-- is true the first time, when forced, or once ms have passed since it was last true; win[key] holds
-- the next time it is due (nil it to force the next call). The first wait is cut by a phase that steps
-- with each new timer (golden-ratio spread, up to half the interval), so windows and tabs fall out of step.
local _phaseN = 0
function CC.due(win, key, ms, force)
    local now = getTimestampMs()
    local at = win[key]
    if at and not force and now < at then return false end
    if at == nil then
        _phaseN = _phaseN + 1
        win[key] = now + ms - math.floor(ms * 0.5 * ((_phaseN * 0.618034) % 1))
    else
        win[key] = now + ms
    end
    return true
end

-- The category pop-up list (CC.renderCatDropdownOverlay): a row's height and the
-- rows shown before it scrolls (hoisted: the header and the band place it too)
local DD_ROW_H   = 20
local DD_MAX_VIS = 14

-- A pop-up list or a select open over the card (the pointer's hover washes stay off)
local function anyOpen(state)
    return state.catDropdownOpen or state.stDropdownOpen or state.sortMenuOpen or state.showMenuOpen or false
end

-- Sort rank
local STATUS_RANK = { craftable = 0, unlocked = 1, missing = 2, station = 2, locked = 3 }

-- ============================================================================
-- UTILITY — getInputName / getOutputName
-- Extract display name from CraftRecipe input/output script objects.
-- ============================================================================

function CC.getInputName(inputScript)
    local ok, possible = pcall(function() return inputScript:getPossibleInputItems() end)
    if ok and possible and possible:size() > 0 then
        local item = possible:get(0)
        if item and item.getDisplayName then return item:getDisplayName() end
    end
    return "?"
end

function CC.getOutputName(outputScript)
    local ok, possible = pcall(function() return outputScript:getPossibleResultItems() end)
    if ok and possible and possible:size() > 0 then
        local item = possible:get(0)
        if item and item.getDisplayName then return item:getDisplayName() end
    end
    return "?"
end

-- ============================================================================
-- UTILITY — getPerkType (cached perk name → PerkFactory type lookup)
-- ============================================================================

local _perkByName = nil

function CC.getPerkType(name)
    if not _perkByName then
        _perkByName = {}
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            _perkByName[perk:getName()] = perk:getType()
        end
    end
    return _perkByName[name]
end

-- ============================================================================
-- UTILITY — buildContainers (ArrayList for HandcraftLogic/BuildLogic)
-- ============================================================================

--- The containers a craft draws on: the player's inventory, then each bag the
--- player wears or holds and each key ring in it.
function CC.buildContainers(playerObj)
    local containers = ArrayList.new()
    local mainInv = playerObj:getInventory()
    containers:add(mainInv)

    local ok, items = pcall(function() return mainInv:getItems() end)
    if ok and items then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item then
                local isBag = item:getCategory() == "Container" and playerObj:isEquipped(item)
                local isKeyRing = false
                pcall(function()
                    isKeyRing = item:isItemType(ItemType.KEY_RING) or item:hasTag(ItemTag.KEY_RING)
                end)
                if isBag or isKeyRing then
                    local ok2, inv = pcall(function() return item:getInventory() end)
                    if ok2 and inv then containers:add(inv) end
                end
            end
        end
    end

    return containers
end

--- The containers the Craft and Build tabs check and craft from: the game's own list for its
--- craft and build windows (ISInventoryPaneContextMenu.getContainers: the inventory, the bags,
--- the floor and the open loot containers), so dropped planks or a crate beside the bench count
--- as they do in vanilla. Falls back to the carried list (CC.buildContainers) when the game's
--- list cannot be read. The two lists are never merged: the inventory and bags would count twice.
--- (beast W25)
function CC.craftContainers(playerObj)
    -- (the game's list reads the player's inventory pages; at quit they are gone, and the game's
    -- function prints its error even under pcall, so check them first, as CookingTab does)
    local pn = playerObj:getPlayerNum()
    local ok0, ready = pcall(function() return getPlayerInventory(pn) ~= nil and getPlayerLoot(pn) ~= nil end)
    if not (ok0 and ready) then return CC.buildContainers(playerObj) end
    local ok, list = pcall(ISInventoryPaneContextMenu.getContainers, playerObj)
    if ok and list and list:size() > 0 then return list end
    return CC.buildContainers(playerObj)
end

--- Vanilla's craft window (ISWidgetHandCraftControl:startHandcraft) moves a recipe's inputs into
--- the main inventory first when the recipe cannot be made from the floor, and queues the kept
--- ones back to where they were after the craft. logic: a HandcraftLogic that has the recipe's
--- inputs filled (canPerformCurrentRecipe asked). Queues the moves (run before the craft
--- actions are queued) and returns the list of items to put back (for CC.returnCraftInputs).
--- seen (optional): items already moved for an earlier craft of the batch (a tool each craft
--- shares); they are skipped and the ones moved here are added. (beast W25)
--- The second return is every item moved here, kept or not: when the walk to the bench or the
--- table then fails, no craft is queued and all of them go back (QA cb sweep, Nov 25 2026, C9).
function CC.moveCraftInputs(playerObj, logic, seen)
    local back, all = {}, {}
    pcall(function()
        if logic:getRecipe():isCanBeDoneFromFloor() then return end
        local data = logic:getRecipeData()
        if not data then return end
        local items = data:getAllInputItems()
        local itemsToReturn = data:getAllPutBackInputItems()
        -- (the recipe-at-hand item, a book or a magazine, is moved and put back too, as vanilla does)
        if logic:isUsingRecipeAtHandBenefit() then
            local atHand = logic:getUsingRecipeAtHandItem()
            if atHand then
                items:add(atHand)
                itemsToReturn:add(atHand)
            end
        end
        local inv = playerObj:getInventory()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and item:getContainer() ~= inv and not (seen and seen[item]) then
                if seen then seen[item] = true end
                ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
                all[#all + 1] = item
                if itemsToReturn:contains(item) then back[#back + 1] = item end
            end
        end
    end)
    return back, all
end

--- Queues the kept inputs CC.moveCraftInputs moved back to their containers (after the crafts).
--- (beast W25)
function CC.returnCraftInputs(playerObj, back)
    if not (back and #back > 0) then return end
    pcall(ISCraftingUI.ReturnItemsToOriginalContainer, playerObj, back)
end

-- ----------------------------------------------------------------------------
-- A craft in progress (QA cb sweep, Nov 25 2026, C1 and C19). The game's craft window grays Craft
-- while its craft runs and refuses a second press (ISWidgetHandCraftControl:startHandcraft asks
-- isCraftActionInProgress). ZeD queues its own actions, so it keeps them on the window and Craft
-- stays gray while any of them is still in the player's queue (waiting, walking or running): the
-- inputs of a queued craft are not used until it ends, so a second press with materials for one
-- passed the start check and queued a craft that ran its whole time and made nothing.
-- ----------------------------------------------------------------------------

--- Keeps the craft actions just queued on the window (win._craftQueued), for CC.craftBusy.
function CC.trackCraftActions(win, actions)
    if not (win and actions and #actions > 0) then return end
    local list = win._craftQueued or {}
    for i = 1, #actions do list[#list + 1] = actions[i] end
    win._craftQueued = list
end

--- True while a craft ZeD queued is still in the player's action queue. The list empties itself
--- once none is left.
function CC.craftBusy(win, playerObj)
    local list = win and win._craftQueued
    if not list then return false end
    local busy = false
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(playerObj or win._playerObj)
        if not (q and q.queue) then return end
        for i = 1, #list do
            if q:indexOf(list[i]) ~= -1 then busy = true; return end
        end
    end)
    if not busy then win._craftQueued = nil end
    return busy
end

--- Counts a craft in the use counts (Freq, Most used) when it starts, not at the press: a batch of
--- three counts three, a craft the game refuses at its start counts none. (C19)
local function countOnStart(target, action)
    if target and target.player and target.name then
        CC.incrementCraftCount(target.player, target.name, target.key or "ZeD_CraftCounts")
    end
end

--- The start of a craft ZeD built itself (no chosen inputs). The game's own start asks
--- canPerformCurrentRecipe only for chosen inputs (ISHandcraftAction:start), so a craft whose
--- inputs were used up by the one before it ran its whole time and made nothing. Asked here the
--- way the game's start asks it, and stopped the same way (forceStop) when it fails. (C1)
function CC.checkedCraftStart(self)
    if not self.force and not self.manualInputs then
        local ok = true
        pcall(function()
            local l = HandcraftLogic.new(self.character, self.craftBench, self.isoObject)
            l:setContainers(self.containers)
            l:setRecipe(self.craftRecipe)
            ok = l:canPerformCurrentRecipe() and true or false
        end)
        if not ok then
            self:forceStop()
            return
        end
    end
    return ISHandcraftAction.start(self)
end

--- Readies a craft action ZeD queues: its use count goes up when it starts (countKey: the tab's
--- key), and one built without chosen inputs asks the start check at its start.
function CC.prepCraftAction(action, playerObj, recipeName, countKey)
    if not action then return end
    if action.setOnStart then
        action:setOnStart(countOnStart, { player = playerObj, name = recipeName, key = countKey })
    end
    if not action.manualInputs then action.start = CC.checkedCraftStart end
end

--- An any-surface recipe in Hand mode: the table or counter it is made on, found as vanilla's
--- craft window finds it (ISEntityUI.FindCraftSurface, 2 squares). nil when there is none, at a
--- bench (the bench is the surface) or for a recipe that needs no surface. Without a surface the
--- game's start check refuses every any-surface recipe in Hand mode. (beast W23: shared by
--- CraftingTab's start and the chosen-ingredients start)
function CC.craftSurface(playerObj, entry, bench)
    if bench or not (entry and entry.needSurface) then return nil end
    return CC.findHandSurface(playerObj)
end

--- The nearest table or counter within 2 squares (vanilla's hand craft panel radius), for any recipe;
--- the list's ready scan asks it once per scan, the start check per recipe. (QA B6-14)
function CC.findHandSurface(playerObj)
    if not (playerObj and ISEntityUI and ISEntityUI.FindCraftSurface) then return nil end
    local ok, obj = pcall(ISEntityUI.FindCraftSurface, playerObj, 2)
    return ok and obj or nil
end

-- ============================================================================
-- UTILITY — Container Type Cache
-- Builds a fullType → count map from all containers ONCE per refresh.
-- Eliminates per-recipe container scanning (the #1 performance bottleneck).
-- ============================================================================

function CC.buildTypeCache(containers)
    local cache = {}
    if not containers then return cache end
    for ci = 0, containers:size() - 1 do
        local inv = containers:get(ci)
        local ok, items = pcall(function() return inv:getItems() end)
        if ok and items then
            for j = 0, items:size() - 1 do
                local item = items:get(j)
                if item then
                    local ok2, ft = pcall(function() return item:getFullType() end)
                    if ok2 and ft then
                        cache[ft] = (cache[ft] or 0) + 1
                    end
                end
            end
        end
    end
    return cache
end

-- ============================================================================
-- UTILITY — countWithTypes (O(altTypes) lookup against cached type map)
-- ============================================================================

function CC.countWithTypes(validTypes, containers, typeCache)
    if not validTypes then return 0 end
    -- Fast path: use pre-built cache
    if typeCache then
        local count = 0
        for ft, _ in pairs(validTypes) do
            count = count + (typeCache[ft] or 0)
        end
        return count
    end
    -- Fallback: full scan (used when no cache available)
    if not containers then return 0 end
    local count = 0
    for ci = 0, containers:size() - 1 do
        local inv = containers:get(ci)
        local ok, items = pcall(function() return inv:getItems() end)
        if ok and items then
            for j = 0, items:size() - 1 do
                local item = items:get(j)
                if item then
                    local ok2, ft = pcall(function() return item:getFullType() end)
                    if ok2 and ft and validTypes[ft] then
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

-- ============================================================================
-- UTILITY — hasAnyWithTypes (O(altTypes) lookup against cached type map)
-- ============================================================================

function CC.hasAnyWithTypes(validTypes, containers, typeCache)
    if not validTypes then return false end
    -- Fast path: use pre-built cache
    if typeCache then
        for ft, _ in pairs(validTypes) do
            if typeCache[ft] then return true end
        end
        return false
    end
    -- Fallback: full scan
    if not containers then return false end
    for ci = 0, containers:size() - 1 do
        local inv = containers:get(ci)
        local ok, items = pcall(function() return inv:getItems() end)
        if ok and items then
            for j = 0, items:size() - 1 do
                local item = items:get(j)
                if item then
                    local ok2, ft = pcall(function() return item:getFullType() end)
                    if ok2 and ft and validTypes[ft] then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ============================================================================
-- UTILITY — quickCraftCheck (O(inputs * altTypes) via cached type map)
-- ============================================================================

function CC.quickCraftCheck(rd, containers, typeCache)
    -- Already locked (not learned or missing skill) — skip ingredient check
    -- Station recipes in Hand mode keep their status: no hand craft is possible
    if rd.status == "locked" or rd.status == "station" then return rd.status end

    -- Check ALL inputs — tools/kept items are returned after craft but still needed to start
    -- Each in its own amount (4 planks need 4, as the card's rows count), not just one of it. (QA B6-16)
    local entry = rd.entry
    for _, inp in ipairs(entry.inputDefs) do
        if CC.countWithTypes(inp.validTypes, containers, typeCache) < (inp.amount or 1) then
            return "missing"
        end
    end
    return "craftable"
end

-- ============================================================================
-- BACKGROUND SCANNER — checks ingredient availability a batch at a time.
-- Each call checks the next BG_BATCH_SIZE recipes, round-robin, from the tab's
-- render (Build calls it every frame, Craft and the Journal every 5 seconds).
-- Updates rd.status in place so the status dots reflect real craftability.
-- ============================================================================

local BG_BATCH_SIZE = 15  -- recipes checked per call (tunable)

function CC.backgroundIngredientScan(data, win, prefix)
    local recipes = data.recipes
    if not recipes or #recipes == 0 then return end

    -- Build/reuse containers (shared with gatherDetail)
    local contKey = "_" .. prefix .. "Containers"
    local containers = win[contKey]
    if not containers then
        containers = CC.craftContainers(win._playerObj)  -- (the floor and nearby containers too, as vanilla: beast W25)
        win[contKey] = containers
    end

    -- Build/reuse type cache (rebuilt when containers refresh)
    local cacheKey = "_" .. prefix .. "TypeCache"
    if not win[cacheKey] then
        win[cacheKey] = CC.buildTypeCache(containers)
    end
    local typeCache = win[cacheKey]

    -- Round-robin cursor stored on win
    local cursorKey = "_" .. prefix .. "ScanCursor"
    local cursor = win[cursorKey] or 1
    if cursor > #recipes then cursor = 1 end

    local checked = 0
    while checked < BG_BATCH_SIZE and checked < #recipes do
        local rd = recipes[cursor]
        if rd and rd.status ~= "locked" and not rd.fromLogic then
            rd.status = CC.quickCraftCheck(rd, containers, typeCache)
        end
        cursor = cursor + 1
        if cursor > #recipes then cursor = 1 end
        checked = checked + 1
    end

    win[cursorKey] = cursor
end

-- ============================================================================
-- VANILLA'S ANSWER — Ready means the game's own all-green check (materials,
-- station and skill), never ZeD's guess. Vanilla's crafting logic
-- (HandcraftLogic / BuildLogic, a BaseCraftingLogic) holds every recipe and caches, per recipe,
-- whether the character could make it now from the containers in reach:
-- getCachedRecipeInfo(recipe):isValid() (known, skills) and :isCanPerform()
-- (materials in the right amounts, tools, the bench). The same check greys
-- vanilla's own list. Refreshed every LOGIC_EVERY_MS while the tab shows; a
-- changed status re-filters the list. Recipes it answered are marked
-- rd.fromLogic, and the quick scan above leaves them alone.
-- ============================================================================
local LOGIC_EVERY_MS = 1200
local LOGIC_FULL_MS  = 6000

-- What the game's per-recipe answers rest on, read cheaply: each container in reach
-- with its item count and weight, the recipes known, every skill level,
-- the player's square. While it reads the same, setContainers / setRecipes (the game recomputes every
-- recipe) are not called again; they still are every LOGIC_FULL_MS, for what it does not see (an item's
-- condition, freshness or heat).
-- Returns the numbers as one string, and the square (compared as an object, as the containers are:
-- ItemContainer's toString is its type and owner, not which one it is).
local function logicSig(playerObj, containers)
    local parts = {}
    for i = 0, containers:size() - 1 do
        local c = containers:get(i)
        parts[#parts + 1] = tostring(c:getItems():size())
        parts[#parts + 1] = tostring(c:getContentsWeight())
    end
    local kr = playerObj:getKnownRecipes()
    parts[#parts + 1] = tostring(kr and kr:size() or -1)
    local pl = PerkFactory.PerkList
    for i = 0, pl:size() - 1 do parts[#parts + 1] = tostring(playerObj:getPerkLevel(pl:get(i))) end
    return table.concat(parts, "|"), playerObj:getCurrentSquare()
end

-- The same containers, in the same order, as the list the logic was last given.
local function sameContainers(a, b)
    if not a or a:size() ~= b:size() then return false end
    for i = 0, b:size() - 1 do
        if a:get(i) ~= b:get(i) then return false end
    end
    return true
end

-- always: skip the signature and set the recipes in full every scan (the Craft tab at a bench).
-- findSurface (optional): returns the table or counter the hand recipes are made on, asked once per
-- scan (not per recipe); the logic is handed it as vanilla's hand craft panel does, and a new one
-- sets the recipes again. Without it the game refuses every any-surface recipe. (QA B6-14)
function CC.logicScan(data, win, prefix, makeLogic, always, findSurface)
    local recipes = data and data.recipes
    if not recipes or #recipes == 0 or not makeLogic then return false end
    local now = getTimestampMs()
    local atKey = "_" .. prefix .. "LogicAt"
    if win[atKey] and now - win[atKey] < LOGIC_EVERY_MS then return false end
    win[atKey] = now
    local lKey, dKey = "_" .. prefix .. "Logic", "_" .. prefix .. "LogicData"
    local sKey = "_" .. prefix .. "LogicSig"
    local logic = win[lKey]
    if not logic then
        local ok, l = pcall(makeLogic)
        if not ok or not l then
            for _, rd in ipairs(recipes) do rd.fromLogic = nil end   -- (as below: no answer, none held)
            return false
        end
        logic = l
        win[lKey], win[dKey], win[sKey] = logic, nil, nil
        win["_" .. prefix .. "LogicSurface"] = nil   -- (a new logic holds no surface yet) (QA B6-14)
    end
    local ok = pcall(function()
        -- the containers as they are now (and the quick scan's cache and the Craft button's start check
        -- follow them), then the recipes: setting them fills the per-recipe cache from those containers
        local containers = CC.craftContainers(win._playerObj)  -- (beast W25)
        win["_" .. prefix .. "Containers"] = containers
        win["_" .. prefix .. "TypeCache"] = nil
        -- the list is made again only when the rows' recipes change (data.listId: the tabs keep one
        -- data table and its rows and mark a change of membership; a table without it keys on itself)
        local lk = "_" .. prefix .. "LogicList"
        local listId = data.listId or data
        if win[dKey] ~= listId or not win[lk] then
            local list = ArrayList.new()
            for _, rd in ipairs(recipes) do if rd.entry.recipe then list:add(rd.entry.recipe) end end
            win[lk] = list
            win[dKey] = listId
            win[sKey] = nil
        end
        -- (always: a bench bound, whose fuel, heat or fluid the signature cannot see; set every scan)
        local okS, sig, sq = false, nil, nil
        if not always then okS, sig, sq = pcall(logicSig, win._playerObj, containers) end
        if not okS then sig = nil end
        -- the craft surface, looked up once for the whole scan; a different one (or none now) is handed
        -- to the logic and forces the full set below, as vanilla re-checks on a new surface (QA B6-14)
        local surfChanged = false
        if findSurface then
            local surfKey = "_" .. prefix .. "LogicSurface"
            local surf = findSurface()
            local held = win[surfKey]   -- (nil: a new logic, which holds none)
            if surf ~= held then
                logic:setIsoObject(surf)
                win[surfKey] = surf
                surfChanged = true
            end
        end
        local fKey, qKey, ckKey = "_" .. prefix .. "LogicFullAt", "_" .. prefix .. "LogicSq", "_" .. prefix .. "LogicConts"
        if always or surfChanged or sig == nil or win[sKey] ~= sig or win[qKey] ~= sq or not sameContainers(win[ckKey], containers)
           or not win[fKey] or now - win[fKey] >= LOGIC_FULL_MS then
            logic:setContainers(containers)
            logic:setRecipes(win[lk])
            win[sKey], win[qKey], win[ckKey], win[fKey] = sig, sq, containers, now
        end
    end)
    if not ok then
        -- (the game would not answer, so its last answers no longer stand: the quick scan and
        -- the card's count take the recipes back. Kept, a craftable answer would hold until the
        -- game answered again, carried over by the rows rebuilt every 30 frames)
        win[lKey] = nil
        for _, rd in ipairs(recipes) do rd.fromLogic = nil end
        return false
    end
    local changed = false
    local getInfo = logic.getCachedRecipeInfo   -- (pcall'd with its arguments: no closure per recipe)
    for _, rd in ipairs(recipes) do
        local r = rd.entry.recipe
        if r and rd.status ~= "station" then
            local okI, info = pcall(getInfo, logic, r)
            if okI and info then
                local st
                if not info:isValid() then st = "locked"
                elseif info:isCanPerform() then st = "craftable"
                else st = "missing" end
                -- (a recipe not learned or short of skill stays locked whatever the materials say)
                if (rd.learned == false or rd.hasSkill == false) then st = "locked" end
                rd.fromLogic = true
                if st ~= rd.status then rd.status = st; changed = true end
            end
        end
    end
    return changed
end

-- The tabs refresh their recipe rows every second (learned recipes, skills,
-- the bench): the last craftable / missing answer carries over to the new rows
-- until the next scan, so the list does not empty and refill between scans.
-- (Craft and Build refresh their rows in place and carry the answer there,
-- CC.refreshRow; this stays for a caller with two lists.)
function CC.carryStatus(oldData, newData)
    if not (oldData and newData and oldData.recipes and newData.recipes) then return end
    local prev = {}
    for _, rd in ipairs(oldData.recipes) do prev[rd.entry.name] = rd end
    for _, rd in ipairs(newData.recipes) do
        local o = prev[rd.entry.name]
        if o and o.fromLogic and rd.status ~= "locked" and rd.status ~= "station"
           and (o.status == "craftable" or o.status == "missing") then
            rd.status, rd.fromLogic = o.status, true
        end
    end
end

-- ============================================================================
-- RECIPE ROWS IN PLACE
-- A new table per recipe each refresh would cost a closure for isRecipeKnown, a
-- perk lookup and two case conversions each, then a name map to carry the game's
-- answers. So each recipe keeps one row table (a pool per tab, keyed by the
-- catalog entry), rewritten in place with what a new row would hold; the game's
-- craftable / missing answer carries exactly as carryStatus carries it: only
-- from the row as it stood in the last list.
-- ============================================================================

-- The pool and this refresh's generation (rows stamped with the last one were in the last list).
function CC.rowsBegin(win, prefix)
    local pk, gk = "_" .. prefix .. "RowPool", "_" .. prefix .. "RowGen"
    local pool = win[pk]
    if not pool then pool = {}; win[pk] = pool end
    local gen = (win[gk] or 0) + 1
    win[gk] = gen
    return pool, gen
end

-- One recipe's row, rewritten. prevGen: the generation of the list the tab held (nil: none,
-- nothing carries). status: from the skill, learned and station checks.
function CC.refreshRow(pool, entry, gen, prevGen, status, hasSkill, learned, playerLevel)
    local rd = pool[entry]
    if not rd then rd = {}; pool[entry] = rd end
    local carry = prevGen ~= nil and rd._gen == prevGen and rd.fromLogic
        and status ~= "locked" and status ~= "station"
        and (rd.status == "craftable" or rd.status == "missing")
    rd._gen = gen
    rd.entry = entry
    if carry then
        rd.fromLogic = true
    else
        rd.status, rd.fromLogic = status, nil
    end
    rd.hasSkill, rd.learned, rd.playerLevel = hasSkill, learned, playerLevel
    -- (a new row had none of what the selected recipe's detail gather writes)
    rd.ingredients, rd.missingCount, rd.skills, rd.craftTime = nil, 0, nil, nil
    rd.canStart, rd.maxBatchQty = nil, nil
    return rd
end

-- A skill's level, asked of the game once per refresh (levels: that refresh's map).
function CC.perkLevelOf(levels, playerObj, skillName)
    local lv = levels[skillName]
    if lv == nil then
        lv = 0
        local perkType = CC.getPerkType(skillName)
        if perkType and perkType ~= Perks.None then
            lv = playerObj:getPerkLevel(perkType)
        end
        levels[skillName] = lv
    end
    return lv
end

-- The rows written into data.recipes (n of them): a changed membership gets a new data.listId
-- (CC.logicScan makes its recipe list again) and a new name index (first row of each name, as
-- the linear search found it).
function CC.rowsEnd(data, n, changed)
    local recipes = data.recipes
    for i = #recipes, n + 1, -1 do
        recipes[i] = nil
        changed = true
    end
    if changed or not data.byName then
        local byName = {}
        for i = 1, n do
            local rd = recipes[i]
            local nm = rd.entry.name
            if nm ~= nil and byName[nm] == nil then byName[nm] = rd end
        end
        data.byName = byName
        data.listId = {}
    end
end

-- ============================================================================
-- UTILITY — truncText (binary search ellipsis truncation)
-- ============================================================================

--- str cut to fit maxW (screen px) in font, ending in "..."; whole when it fits.
function CC.truncText(str, font, maxW)
    local tm = ZeD.TM
    if tm:MeasureStringX(font, str) <= maxW then return str end
    local ellW = tm:MeasureStringX(font, "...")
    local target = maxW - ellW
    if target <= 0 then return "..." end
    local lo, hi = 1, #str
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if tm:MeasureStringX(font, string.sub(str, 1, mid)) <= target then
            lo = mid
        else
            hi = mid - 1
        end
    end
    return string.sub(str, 1, lo) .. "..."
end

-- A recipe's description on one line: its line breaks (and a "<br>" left in) become spaces, runs of
-- space one. Made once per recipe and kept on the entry.
function CC.oneLine(entry)
    local s = entry._descLine
    if s then return s end
    s = tostring(entry.description or "")
    s = string.gsub(s, "<br>", " ")
    s = string.gsub(s, "[\r\n\t]", " ")
    s = string.gsub(s, "  +", " ")
    s = string.gsub(s, "^ ", "")
    s = string.gsub(s, " $", "")
    entry._descLine = s
    return s
end

-- ============================================================================
-- PIN MANAGEMENT — parameterized by modData key
-- ============================================================================

function CC.loadPins(win, pinKey, stateKey)
    local md = win._playerObj:getModData()
    if md and md[pinKey] then
        win[stateKey] = {}
        for _, name in ipairs(md[pinKey]) do
            win[stateKey][#win[stateKey] + 1] = name
        end
    else
        win[stateKey] = {}
    end
end

function CC.savePins(win, pinKey, stateKey)
    local md = win._playerObj:getModData()
    md[pinKey] = {}
    for _, name in ipairs(win[stateKey] or {}) do
        md[pinKey][#md[pinKey] + 1] = name
    end
end

function CC.togglePin(win, recipeName, pinKey, stateKey, dirtyKey)
    local pins = win[stateKey] or {}

    -- Check if already pinned — remove if so
    for i, name in ipairs(pins) do
        if name == recipeName then
            table.remove(pins, i)
            CC.setGameFavourite(win, recipeName, pinKey, false)   -- (C18)
            win[stateKey] = pins
            win[dirtyKey] = true
            CC.savePins(win, pinKey, stateKey)
            return
        end
    end

    -- Add pin (FIFO eviction if at max)
    if #pins >= CC.MAX_PINS then
        local gone = table.remove(pins, 1)
        CC.setGameFavourite(win, gone, pinKey, false)   -- (else the game's flag pins it again: C18)
    end
    pins[#pins + 1] = recipeName
    CC.setGameFavourite(win, recipeName, pinKey, true)   -- (C18)
    win[stateKey] = pins
    win[dirtyKey] = true
    CC.savePins(win, pinKey, stateKey)
end

-- ----------------------------------------------------------------------------
-- The game's recipe favourites (QA cb sweep, Nov 25 2026, C18). The game keeps a favourite as a
-- flag in the player's mod data, under BaseCraftingLogic.getFavouriteModDataString(recipe), and
-- lists it first (ISRecipeScrollingListBox, the item menu). ZeD's pins were its own: a recipe the
-- game held as a favourite was not in the Pinned group. The Craft tab's pins now take in the
-- game's favourites, and a pin or unpin in ZeD sets the game's flag, as the game's star does.
-- ----------------------------------------------------------------------------

--- Pin keys whose pins are the game's favourites too (the Craft tab's).
CC.GAME_FAV_PINS = { ZeD_CraftPins = true }

--- Sets the game's favourite flag for recipeName, as the game's star does
--- (ISWidgetTitleHeader: modData[favString] = true or false). Only for a key in CC.GAME_FAV_PINS.
function CC.setGameFavourite(win, recipeName, pinKey, on)
    if not (recipeName and pinKey and CC.GAME_FAV_PINS[pinKey] and win and win._playerObj) then return end
    pcall(function()
        local key = BaseCraftingLogic.getFavouriteModDataString(recipeName)
        if key then win._playerObj:getModData()[key] = on and true or false end
    end)
end

--- Adds to the pins every recipe of flatRecipes the game holds as a favourite (its flag true).
--- They are not written to ZeD's own pin list until a pin changes; unpinning one clears the game's
--- flag too. Returns true when a pin was added.
function CC.mergeGameFavourites(win, pinKey, stateKey, flatRecipes)
    if not (CC.GAME_FAV_PINS[pinKey] and win and win._playerObj and flatRecipes) then return false end
    local ok0, md = pcall(function() return win._playerObj:getModData() end)
    if not (ok0 and md) then return false end
    local pins = win[stateKey] or {}
    local have = {}
    for _, n in ipairs(pins) do have[n] = true end
    local added = false
    -- (a pin taken in from the game's flag goes when the game's flag is cleared there; one ZeD
    -- saved is the player's own and stays)
    local merged = win[stateKey .. "Fav"] or {}
    win[stateKey .. "Fav"] = merged
    local saved = {}
    for _, n in ipairs(md[pinKey] or {}) do saved[n] = true end
    for i = #pins, 1, -1 do
        local n = pins[i]
        if merged[n] and not saved[n] then
            local k = false
            pcall(function() k = BaseCraftingLogic.getFavouriteModDataString(n) or false end)
            if k and md[k] ~= true then
                table.remove(pins, i)
                have[n] = nil
                merged[n] = nil
                added = true
            end
        end
    end
    for _, entry in ipairs(flatRecipes) do
        local key = entry._favKey
        if key == nil then
            -- (the game's string, asked once per recipe and kept on the catalog entry)
            key = false
            pcall(function() key = BaseCraftingLogic.getFavouriteModDataString(entry.name) or false end)
            entry._favKey = key
        end
        if key and md[key] == true and not have[entry.name] then
            pins[#pins + 1] = entry.name
            have[entry.name] = true
            merged[entry.name] = true
            added = true
        end
    end
    if added then win[stateKey] = pins end
    return added   -- (true when the pins changed, added or taken away)
end

function CC.isPinned(win, recipeName, stateKey)
    for _, name in ipairs(win[stateKey] or {}) do
        if name == recipeName then return true end
    end
    return false
end

-- ============================================================================
-- CRAFT COUNT TRACKING — modData-based (ZeD_CraftCounts / ZeD_BuildCounts)
-- ============================================================================

--- One more craft of recipeName, kept in the player's mod data under countKey.
function CC.incrementCraftCount(player, recipeName, countKey)
    local md = player:getModData()
    if not md[countKey] then md[countKey] = {} end
    md[countKey][recipeName] = (md[countKey][recipeName] or 0) + 1
end

function CC.getCraftCount(player, recipeName, countKey)
    local md = player:getModData()
    if not md[countKey] then return 0 end
    return md[countKey][recipeName] or 0
end

--- Get top N frequently crafted recipes (excluding pinned).
--- Returns ordered list of {name, count} tables.
function CC.getTopFrequent(player, flatRecipes, n, pinSet, countKey)
    local md = player:getModData()
    local counts = md[countKey]
    if not counts then return {} end

    local freq = {}
    for _, entry in ipairs(flatRecipes) do
        local name = entry.name
        local c = counts[name]
        if c and c > 0 and not pinSet[name] then
            freq[#freq + 1] = { name = name, count = c }
        end
    end

    -- Sort by count descending
    table.sort(freq, function(a, b) return a.count > b.count end)

    -- Trim to N
    local result = {}
    for i = 1, math.min(n, #freq) do
        result[i] = freq[i]
    end
    return result
end

-- ============================================================================
-- CATALOG HELPERS — shared pre-bake logic for recipe input/output/skill defs
-- ============================================================================

--- Pre-bake input definitions from a recipe object.
--- Returns a list of {name, isTool, isKeep, isFuel, validTypes, altCount, tag,
--- inputRef} tables (automation-only inputs are left out).
function CC.prebakeInputs(recipe)
    local inputDefs = {}
    local ok1, inputs = pcall(function() return recipe:getInputs() end)
    if ok1 and inputs then
        for ii = 0, inputs:size() - 1 do
            local input = inputs:get(ii)
            local okAuto, isAuto = pcall(function() return input:isAutomationOnly() end)
            if not (okAuto and isAuto) then
                local isTool = false
                pcall(function() isTool = input:isTool() end)
                local isKeep = false
                pcall(function() isKeep = input:isKeep() end)
                local inputName = CC.getInputName(input)

                -- Pre-build valid item type set for material counting.
                -- getPossibleInputItems() returns script Item objects which
                -- may expose getFullType() OR getFullName() depending on the
                -- PZ build.  Try both, plus manual module.name construction.
                local validTypes = {}
                local altCount = 0
                local okP, possible = pcall(function() return input:getPossibleInputItems() end)
                if okP and possible then
                    for j = 0, possible:size() - 1 do
                        local item = possible:get(j)
                        if item then
                            local ft = nil
                            -- Try getFullType first (InventoryItem-style)
                            if item.getFullType then
                                pcall(function() ft = item:getFullType() end)
                            end
                            -- Fallback: getFullName (script Item style)
                            if not ft and item.getFullName then
                                pcall(function() ft = item:getFullName() end)
                            end
                            -- Fallback: construct from module + name
                            if not ft and item.getModule and item.getName then
                                pcall(function()
                                    local mod = item:getModule()
                                    local modName = mod and mod:getName() or "Base"
                                    ft = modName .. "." .. item:getName()
                                end)
                            end
                            if ft then validTypes[ft] = true end
                        end
                    end
                    altCount = possible:size()
                end

                -- How many items the input takes (4 planks, 5 nails), read as vanilla's input widget
                -- reads it (ISWidgetInput: getIntAmount for an item input). The card's have count is
                -- items, so an input counted in uses (thread, glue, tape: a drainable item, not
                -- isItemCount) keeps 1: one item may hold every use it needs. (beast W24)
                local amount = 1
                local usesBased = false   -- (kept on the def: the card's game count reads it, CC.gameInputCounts)
                pcall(function()
                    if input:getResourceType() ~= ResourceType.Item then return end
                    if not input:isItemCount() and okP and possible then
                        for j = 0, possible:size() - 1 do
                            local item = possible:get(j)
                            if item and item:isItemType(ItemType.DRAINABLE) then usesBased = true; break end
                        end
                    end
                    if not usesBased then amount = math.max(1, input:getIntAmount()) end
                end)

                -- Tag for display: TOOL, KEEP, or nil (FUEL comes later, in CC.gatherDetail:
                -- a fuel input at a heat station)
                local tag = nil
                if isTool then tag = "TOOL"
                elseif isKeep then tag = "KEEP"
                end

                inputDefs[#inputDefs + 1] = {
                    isFuel     = (validTypes["Base.Log"] or validTypes["Base.Charcoal"]) and true or false,
                    name       = inputName,
                    isTool     = isTool,
                    isKeep     = isKeep,
                    validTypes = validTypes,
                    altCount   = altCount > 1 and altCount or 0,  -- 0 or 1 = specific item
                    tag        = tag,
                    amount     = amount,  -- items the input takes (beast W24)
                    usesBased  = usesBased,  -- counted in uses: one item may hold every use it needs
                    inputRef   = input,  -- keep ref for alt enumeration
                }
            end
        end
    end
    return inputDefs
end

--- Pre-bake output definitions from a recipe object.
function CC.prebakeOutputs(recipe)
    local outputDefs = {}
    local ok2, recOutputs = pcall(function() return recipe:getOutputs() end)
    if ok2 and recOutputs then
        for oi = 0, recOutputs:size() - 1 do
            local output = recOutputs:get(oi)
            local okA2, isA2 = pcall(function() return output:isAutomationOnly() end)
            if not (okA2 and isA2) then
                local outTypes = {}
                local okOT, possibleOut = pcall(function() return output:getPossibleResultItems() end)
                if okOT and possibleOut then
                    for oj = 0, possibleOut:size() - 1 do
                        local oi2 = possibleOut:get(oj)
                        if oi2 and oi2.getFullType then
                            local ft = oi2:getFullType()
                            if ft then outTypes[ft] = true end
                        end
                    end
                end
                -- How many one craft makes, read as vanilla does (item outputs only; 1 when unreadable) (QA B10-2)
                local amount = 1
                pcall(function()
                    if output:getResourceType() == ResourceType.Item then
                        amount = math.max(1, output:getIntAmount())
                    end
                end)
                -- An output written through a mapper (Divide Food: the bowl follows the food, the pot given
                -- back follows the pot used) is named on the card from what is in reach (CC.resolveMappedOutputs);
                -- name above is the mapper's first result, kept for when nothing in reach decides it (QA B11-1)
                local okM, mp = pcall(function() return output:getOutputMapper() end)
                outputDefs[#outputDefs + 1] = {
                    name       = CC.getOutputName(output),
                    validTypes = outTypes,
                    amount     = amount,
                    mapped     = (okM and mp ~= nil) or nil,
                    outputRef  = output,   -- keep ref for the mapper (QA B11-1)
                }
            end
        end
    end
    return outputDefs
end

--- True when the recipe makes one thing and its title already names it ("Bucket of Clay Cement" in "Make Bucket of
--- Clay Cement"): the card's Outputs section would only repeat the title. Kept on the entry.
function CC.outputsRepeatTitle(entry)
    if not entry then return false end
    local v = entry._outRepeats
    if v == nil then
        v = false
        local defs = entry.outputDefs
        -- (a yield above 1 keeps the section, or the amount would show nowhere) (QA B10-2)
        if defs and #defs == 1 and defs[1].name and defs[1].name ~= "?" and entry.displayName
           and (defs[1].amount or 1) <= 1 then
            v = string.find(string.lower(tostring(entry.displayName)), string.lower(tostring(defs[1].name)), 1, true) ~= nil
        end
        entry._outRepeats = v
    end
    return v
end

--- Pre-bake skill requirements from a recipe object.
function CC.prebakeSkills(recipe)
    local skillDefs = {}
    for si = 0, recipe:getRequiredSkillCount() - 1 do
        local rs = recipe:getRequiredSkill(si)
        skillDefs[#skillDefs + 1] = {
            name     = tostring(rs:getPerk():getName()),
            required = rs:getLevel(),
        }
    end
    return skillDefs
end

--- Resolve a recipe's category from script definition, with skill fallback.
function CC.resolveCategory(recipe, skillName)
    local category = nil
    pcall(function()
        local c = recipe:getCategory()
        if c and c ~= "" then category = tostring(c) end
    end)

    if not category and skillName then
        category = skillName
    end

    if category and category ~= "" then
        category = ZeD.upper(string.sub(category, 1, 1)) .. string.sub(category, 2)
    else
        category = "Miscellaneous"
    end

    return category
end

-- An ingredient row's tag as shown: the internal TOOL / KEEP / FUEL ids become the player's
-- words. An alternatives row that carries FUEL keeps the id: the row painter compares it
-- (and draws its own Fuel chip).
function CC.tagText(tag, altCount)
    if tag == nil then return nil end
    if tag == "FUEL" and (altCount or 0) > 0 then return tag end
    if tag == "TOOL" then return ZeD.tr("IGUI_ItemCat_Tool") end
    if tag == "KEEP" then return ZeD.trBare("IGUI_CraftUI_SourceKeep") end
    if tag == "FUEL" then return ZeD.tr("UI_ZeD_Craft_TagFuel") end
    return tag
end

-- A category's name as the player reads it: vanilla's translated label when
-- the game has one (its crafting window uses IGUI_CraftingCategories_*), the
-- raw name otherwise. The raw name stays the key everywhere else.
local _catLabelCache = {}
function CC.categoryLabel(raw)
    if raw == nil or raw == "" then return "" end
    raw = tostring(raw)
    local hit = _catLabelCache[raw]
    if hit then return hit end
    -- every category: the game's plain "All", not its crafting window's "-- ALL --", so the
    -- select reads "Category: All" (design review C2)
    if raw == "All" then
        local all = ZeD.tr("UI_All")
        _catLabelCache[raw] = all
        return all
    end
    local cap =ZeD.upper(string.sub(raw, 1, 1)) .. string.sub(raw, 2)
    local label = getTextOrNull and getTextOrNull("IGUI_CraftingCategories_" .. cap)
    _catLabelCache[raw] = label or cap
    return label or cap
end

-- The label for the category the list is currently filtered to.
function CC.activeCategoryLabel(state)
    local id = state.activeCat
    if id == nil or id == "all" then return CC.categoryLabel("All") end
    for _, c in ipairs(state.categoryList or {}) do
        if c.id == id then return CC.categoryLabel(c.full or c.label or id) end
    end
    return CC.categoryLabel(id)
end

-- ============================================================================
-- FILTERING + SORTING — parameterized by filter modes
-- ============================================================================

-- SHOW: "ready" | "known" | "all". A state with no show yet goes by showAll: on = all,
-- off = the default (Ready; Known for the Journal's read-only list, which has no Ready)
local SHOW_LABEL = { ready = "UI_ZeD_Craft_ShowReady", known = "UI_ZeD_Craft_Known", all = "UI_ZeD_Craft_ShowAll" }   -- keys
function CC.showMode(state, config)
    if state.show then return state.show end
    if state.showAll then return "all" end
    return (config and config.readOnly) and "known" or "ready"
end
function CC.cycleShow(state, config)
    local cur = CC.showMode(state, config)
    local nxt
    if config and config.readOnly then nxt = (cur == "all") and "known" or "all"
    else nxt = (cur == "ready" and "known") or (cur == "known" and "all") or "ready" end
    state.show = nxt
    state.showAll = (nxt == "all")
    state.filterDirty = true
end

-- Show one of the choices (the band's Show pop-up): the same choices
-- CC.cycleShow steps through, picked from a list
function CC.setShow(state, id)
    state.show = id
    state.showAll = (id == "all")
    state.filterDirty = true
end

-- The line an empty recipe list shows: what the search found nothing for, else what Show holds back
function CC.emptyListText(state, config)
    local q = state.search or ""
    if #q > 0 then return ZeD.tr("UI_ZeD_TAS_Nothing", q) end
    if CC.showMode(state, config) == "ready" then return ZeD.tr("UI_ZeD_Craft_EmptyReady") end
    return ZeD.tr("UI_ZeD_Craft_EmptyNone")
end

-- The band's pop-up choices, {id, key, label}: made once, the labels refreshed where
-- they are drawn (CC.popModes). The read-only list (the Journal) has no craft counts
-- (no Freq / Recent) and no Ready.
local SORT_FULL = {
    { id = "craftable", key = "UI_ZeD_Craft_SortCraftable" },
    { id = "known",     key = "UI_ZeD_Craft_Known" },
    { id = "name",      key = "UI_ZeD_Craft_SortName" },
    { id = "freq",      key = "UI_ZeD_Craft_SortFreq" },
}
local SORT_RO = { SORT_FULL[1], SORT_FULL[2], SORT_FULL[3] }
local SHOW_FULL = {
    { id = "ready", key = SHOW_LABEL.ready },
    { id = "known", key = SHOW_LABEL.known },
    { id = "all",   key = SHOW_LABEL.all },
}
local SHOW_RO = { SHOW_FULL[2], SHOW_FULL[3] }

-- The choices of the band's "sort" or "show" pop-up for this config, labels current.
function CC.popModes(kind, config)
    local ro = config and config.readOnly
    local modes
    if kind == "show" then modes = ro and SHOW_RO or SHOW_FULL
    else modes = ro and SORT_RO or SORT_FULL end
    for i = 1, #modes do modes[i].label = ZeD.tr(modes[i].key) end
    return modes
end

-- The sort in use: Recent was dropped, so an old saved "recent" is Freq, for the label, the list and the open
-- menu alike (QA K1 review: K1-12)
function CC.sortOf(state)
    local m = state and state.sort or "craftable"
    if m == "recent" then m = "freq" end
    return m
end

-- The label of a choice in a mode list (the box names the current one)
local function modeLabel(modes, id)
    for i = 1, #modes do
        if modes[i].id == id then return modes[i].label end
    end
    return modes[1] and modes[1].label or ""
end

-- Every item name an ingredient slot takes, lowercased and joined (built on first search, then kept on the
-- slot): validTypes holds each full type the slot accepts, where inp.name is only the first one. (QA K1-10)
function CC.inputSearchText(inp)
    if inp._allNames then return inp._allNames end
    local parts = {}
    local sm = getScriptManager and getScriptManager()
    for ft, _ in pairs(inp.validTypes or {}) do
        local nm = nil
        pcall(function()
            local sc = sm and sm:FindItem(ft)
            if sc then nm = sc:getDisplayName() end
        end)
        if nm then parts[#parts + 1] = string.lower(tostring(nm)) end
    end
    inp._allNames = table.concat(parts, "|")
    return inp._allNames
end

function CC.filterAndSort(data, state, config, win)
    local recipes   = data.recipes
    local category  = state.activeCat or "all"
    local searchText = state.search or ""
    local pins      = state.pins or {}

    -- Build pin lookup
    local pinSet = {}
    for _, name in ipairs(pins) do pinSet[name] = true end

    local filtered = {}
    local catCounts = { all = 0 }
    local searching = #searchText > 0
    local searchLower = searching and string.lower(searchText) or ""

    for _, rd in ipairs(recipes) do
        local entry = rd.entry

        -- Search filter (name, category, ingredient names)
        local searchOut = false
        if searching then
            local nameMatch = string.find(string.lower(entry.displayName), searchLower, 1, true)
            local catMatch = string.find(string.lower(entry.category), searchLower, 1, true)
            local ingMatch = false
            if not nameMatch and not catMatch then
                for _, inp in ipairs(entry.inputDefs) do
                    if string.find(string.lower(inp.name), searchLower, 1, true)
                        or string.find(CC.inputSearchText(inp), searchLower, 1, true) then -- every type the slot takes (QA K1-10)
                        ingMatch = true
                        break
                    end
                end
                if not ingMatch then
                    for _, out in ipairs(entry.outputDefs) do
                        if string.find(string.lower(out.name), searchLower, 1, true) then
                            ingMatch = true
                            break
                        end
                    end
                end
            end
            if not nameMatch and not catMatch and not ingMatch then
                searchOut = true
            end
        end

        -- Filter: SHOW. Ready = only what can be made right now (vanilla's all-green
        -- answer); Known = learned and skilled enough; All = everything. A search
        -- looks through everything. The open card's recipe keeps its row whatever
        -- Show holds back: the card is the list's picked row (a craft that uses the
        -- last ingredients, or a recipe opened from an item's card, stays listed)
        local modeOut = false
        local show = CC.showMode(state, config)
        if not searchOut and not searching and show ~= "all" and entry.name ~= state.selected
            and not pinSet[entry.name] then -- a pinned recipe stays listed under any Show (QA K2-3)
            if entry.needLearn and not rd.learned then modeOut = true
            elseif not rd.hasSkill then modeOut = true
            elseif show == "ready" and rd.status ~= "craftable" then modeOut = true end
        end

        -- Tally category counts (mode+search only, ignoring category selection)
        if not searchOut and not modeOut then
            catCounts.all = catCounts.all + 1
            local catId = string.lower(entry.category)
            catCounts[catId] = (catCounts[catId] or 0) + 1
        end

        -- Category filter
        local catOut = false
        if category ~= "all" then
            if string.lower(entry.category) ~= category then
                catOut = true
            end
        end

        if not searchOut and not modeOut and not catOut then
            filtered[#filtered + 1] = rd
        end
    end

    -- Pre-compute composite sort key based on active sort mode
    local sortMode = state.sort or "craftable"
    -- Recent was dropped (it ordered exactly as Freq); an old saved pick reads as Freq (QA K1-12; CC.sortOf says the same)
    if sortMode == "recent" then sortMode = "freq" end
    local playerObj = nil
    if sortMode == "freq" then
        -- (the counts are the window's character's: split view has a window per player; no window, player 1)
        playerObj = getSpecificPlayer((win and win.playerNum) or 0)
    end
    local countKey = config and config.countKey or "ZeD_CraftCount"

    for _, rd in ipairs(filtered) do
        local pin = pinSet[rd.entry.name] and 0 or 1
        local sk

        if sortMode == "craftable" then
            -- Craftable first, then missing, then locked; within tier, alphabetical
            local st = STATUS_RANK[rd.status] or 3
            -- (no missing-count term: only the open recipe has a count, so it demoted that row on every re-sort) (QA B10-4)
            sk = pin * 10000 + st * 1000

        elseif sortMode == "known" then
            -- Known (learned) first, then unknown; within, alphabetical
            local known = (rd.learned ~= false) and 0 or 1
            sk = pin * 10000 + known * 1000

        elseif sortMode == "name" then
            -- Pure alphabetical (pins still first)
            sk = pin * 10000

        elseif sortMode == "freq" then
            -- Most-crafted first (higher count = lower key = sorts first)
            local count = 0
            if playerObj then count = CC.getCraftCount(playerObj, rd.entry.name, countKey) end
            sk = pin * 10000 + (9999 - math.min(9999, count))

        else
            sk = pin * 10000
        end

        rd._sortKey = sk
    end

    -- Order: by _sortKey, then by name, rows with the same key and name kept in list order (the
    -- order the old insertion sort gave). Kahlua-safe: no recursion, no table.sort (the game's is a
    -- recursive quicksort, quadratic on a list already in name order). (beast W27)
    local n = #filtered
    local inNameOrder = true
    for i = 2, n do
        if filtered[i].entry.displayName < filtered[i - 1].entry.displayName then inNameOrder = false; break end
    end
    if inNameOrder then
        -- The list comes in name order: one pass drops each row in its key's bucket (each bucket
        -- stays in name order), then the buckets join in ascending key order. The few distinct
        -- keys are put in order with the merge sort below.
        local buckets, keys = {}, {}
        for i = 1, n do
            local rd = filtered[i]
            local b = buckets[rd._sortKey]
            if not b then
                b = {}
                buckets[rd._sortKey] = b
                keys[#keys + 1] = rd._sortKey
            end
            b[#b + 1] = rd
        end
        CC.stableSort(keys, function(a, b) return a < b end)
        local out = {}
        for ki = 1, #keys do
            local b = buckets[keys[ki]]
            for i = 1, #b do out[#out + 1] = b[i] end
        end
        filtered = out
    else
        -- (a list not in name order, a station's own list say: the merge sort on key, then name)
        CC.stableSort(filtered, function(a, b)
            if a._sortKey ~= b._sortKey then return a._sortKey < b._sortKey end
            return a.entry.displayName < b.entry.displayName
        end)
    end

    return filtered, catCounts
end

--- Sorts list in place by less(a, b), keeping equal items in their list order (stable). An
--- iterative bottom-up merge sort: no recursion (Kahlua's stack) and n log n on any input.
--- (beast W27)
function CC.stableSort(list, less)
    local n = #list
    if n < 2 then return list end
    local src, dst = list, {}
    local width = 1
    while width < n do
        local lo = 1
        while lo <= n do
            local mid = math.min(lo + width, n + 1)    -- first index of the right run
            local hi = math.min(lo + 2 * width, n + 1) -- one past the right run
            local i, j, k = lo, mid, lo
            while i < mid and j < hi do
                -- take the right item only when it is strictly less: equal items keep their order
                if less(src[j], src[i]) then
                    dst[k] = src[j]; j = j + 1
                else
                    dst[k] = src[i]; i = i + 1
                end
                k = k + 1
            end
            while i < mid do dst[k] = src[i]; i = i + 1; k = k + 1 end
            while j < hi do dst[k] = src[j]; j = j + 1; k = k + 1 end
            lo = lo + 2 * width
        end
        src, dst = dst, src
        width = width * 2
    end
    -- (after an odd number of passes the sorted run is in the spare table: copy it back)
    if src ~= list then
        for i = 1, n do list[i] = src[i] end
    end
    return list
end

-- ============================================================================
-- DETAIL GATHERING — container scan for ONE selected recipe
-- ============================================================================

--- Fills rd from what is in reach: its ingredients (have / need per slot), skills,
--- missing count and craft time. Returns the containers it used, gathered again
--- every CONTAINER_INTERVAL (90) calls.
function CC.gatherDetail(rd, playerObj, win, prefix)
    local entry = rd.entry

    -- Build containers if needed (lazy, throttled)
    -- (win["_<prefix>ContainerAt"] = nil forces the next gather)
    local contKey  = "_" .. prefix .. "Containers"
    local cacheKey = "_" .. prefix .. "TypeCache"
    if CC.due(win, "_" .. prefix .. "ContainerAt", CONTAINER_MS, not win[contKey]) then
        win[contKey] = CC.craftContainers(playerObj)  -- (beast W25)
        win[cacheKey] = nil  -- invalidate type cache on container refresh
    end
    local containers = win[contKey]

    -- Build/reuse type cache
    if not win[cacheKey] then
        win[cacheKey] = CC.buildTypeCache(containers)
    end
    local typeCache = win[cacheKey]

    -- Ingredients from pre-baked inputDefs + cached type counts
    local ingredients = {}
    local missingCount = 0
    for _, inp in ipairs(entry.inputDefs) do
        local have = CC.countWithTypes(inp.validTypes, containers, typeCache)
        local need = inp.amount or 1   -- (the input's own amount: 4 planks need 4; beast W24)
        -- Tools/kept items ARE returned after craft, but you still need them to start
        if have < need then
            missingCount = missingCount + 1
        end
        ingredients[#ingredients + 1] = {
            name       = inp.name,
            need       = need,
            have       = have,
            isTool     = inp.isTool,
            isKeep     = inp.isKeep,
            altCount   = inp.altCount or 0,
            tag        = (inp.isFuel and entry.heatStation) and "FUEL" or inp.tag,
            iconTex    = nil,  -- no per-ingredient icon is looked up here
            validTypes = inp.validTypes,  -- needed for alt enumeration
            amount     = need,  -- (the alternatives list reads the slot's real amount, 2/4 not 2/1: QA B6-16)
        }
    end

    -- Skills from pre-baked skillDefs + live player levels
    local skills = {}
    for _, sd in ipairs(entry.skillDefs) do
        local pt = CC.getPerkType(sd.name)
        local pl = 0
        if pt and pt ~= Perks.None then
            pl = playerObj:getPerkLevel(pt)
        end
        skills[#skills + 1] = {
            name        = sd.name,
            required    = sd.required,
            playerLevel = pl,
            met         = pl >= sd.required,
        }
    end

    -- Craft time (fast Java call)
    local craftTime = 0
    if entry.recipe then
        pcall(function() craftTime = entry.recipe:getTime(playerObj) end)
    end

    -- Update rd in-place
    rd.ingredients  = ingredients
    rd.skills       = skills
    rd.missingCount = missingCount
    rd.craftTime    = craftTime
    -- (QA B13-2) a locked row stays locked: the card overwrote it and the scan wrote it back, every scan
    if rd.status ~= "station" and rd.status ~= "locked" and not rd.fromLogic then   -- (vanilla's answer also weighs uses, fluids and the slot's picked items; this counts whole items)
        rd.status   = missingCount > 0 and "missing" or "craftable"
    end

    -- Outputs named through a mapper: asked of the game again only when the containers were gathered
    -- again (every 1.5 s) or the card's picks changed, not every frame (QA B11-1)
    if entry.outputDefs and entry._hasMapped ~= false then
        if entry._hasMapped == nil then
            -- (worked out once per recipe: most have no mapped output and skip all of this after)
            entry._hasMapped = false
            for _, od in ipairs(entry.outputDefs) do if od.mapped then entry._hasMapped = true; break end end
        end
        if entry._hasMapped then
            local st = win["_" .. prefix .. "State"]
            local p = st and st.picks and st.picks[entry.name] or nil
            local sig = ""
            if p then
                for i = 1, #(entry.inputDefs or {}) do sig = sig .. tostring(p[i]) .. ";" end
            end
            if rd._outCont ~= containers or rd._outSig ~= sig then
                rd._outCont, rd._outSig = containers, sig
                rd.outNames, rd.outItems = CC.resolveMappedOutputs(playerObj, entry, p, containers)
            end
        end
    end

    return containers
end

--- The card's have counts as the game's craft window counts them (QA cb sweep, Nov 25 2026, C4).
--- The game's input widget shows logic:getInputCount(input) of / need (ISWidgetInput:updateValues):
--- the items its logic fills the slot with, which leaves out what the game will not use (a
--- favorite, a worn T-shirt, a dull knife, rotten bread, a No-craft item, a broken tool, each by
--- the recipe's own flags). Counting every item of the type read 1/1 where the game said 0.
--- logic: a HandcraftLogic with the containers and the recipe set (setRecipe fills the slots).
--- Returns { [input index] = have } for item inputs; a slot counted in uses (thread, glue) gives
--- its need when the game says it is covered, else 0. nil when there is no logic.
function CC.gameInputCounts(logic, entry)
    if not (logic and entry and entry.inputDefs) then return nil end
    local counts = {}
    for i, inp in ipairs(entry.inputDefs) do
        local script = inp.inputRef
        if script then
            pcall(function()
                if script:getResourceType() ~= ResourceType.Item then return end
                if inp.usesBased then
                    counts[i] = logic:isInputSatisfied(script) and (inp.amount or 1) or 0
                else
                    counts[i] = logic:getInputCount(script)
                end
            end)
        end
    end
    return counts
end

--- Puts the game's counts (CC.gameInputCounts) on the card's rows and works out again how many
--- slots are short; the row's status follows only where the card set it (not the game's list
--- answer, a station row or a locked one), as CC.gatherDetail does. (C4)
function CC.applyGameCounts(rd, counts)
    if not (rd and counts and rd.ingredients) then return end
    local missing = 0
    for i, ing in ipairs(rd.ingredients) do
        local c = counts[i]
        if type(c) == "number" then ing.have = c end
        if (ing.have or 0) < (ing.need or 1) then missing = missing + 1 end
    end
    rd.missingCount = missing
    if rd.status ~= "station" and rd.status ~= "locked" and not rd.fromLogic then
        rd.status = missing > 0 and "missing" or "craftable"
    end
end

-- ============================================================================
-- ALT ENUMERATION — the alternative items for one ingredient slot: what is in
-- reach, grouped by type, then every other type the slot takes (the Owned
-- only toggle hides those).
-- ============================================================================

function CC.enumerateAlts(playerObj, containers, inputDef)
    local validTypes = inputDef.validTypes
    if not validTypes then return { owned = {}, other = {}, totalOwned = 0, totalAll = 0 } end

    -- Collect all matching items across containers, grouped by fullType
    local byType = {}
    local typeOrder = {}
    for ci = 0, containers:size() - 1 do
        local inv = containers:get(ci)
        local ok, items = pcall(function() return inv:getItems() end)
        if ok and items then
            for j = 0, items:size() - 1 do
                local item = items:get(j)
                if item then
                    local ok2, ft = pcall(function() return item:getFullType() end)
                    if ok2 and ft and validTypes[ft] then
                        if not byType[ft] then
                            byType[ft] = {
                                fullType = ft,
                                displayName = item:getDisplayName() or ft,
                                iconTex = item:getTexture(),
                                have = 0,
                                need = inputDef.amount or 1,  -- (the slot's own amount: beast W24)
                            }
                            typeOrder[#typeOrder + 1] = ft
                        end
                        byType[ft].have = byType[ft].have + 1
                    end
                end
            end
        end
    end

    -- Also include items you DON'T have (from validTypes keys)
    -- so the full alt list is visible (owned-only toggle hides these)
    for ft, _ in pairs(validTypes) do
        if not byType[ft] then
            -- Try to get display name from script. ScriptItem exposes getIcon()
            -- (returns icon path string), NOT getIconTexture() — the latter
            -- only exists on CraftRecipe/RecipeItemTable objects. Build the
            -- texture via getTexture("media/textures/Item_" .. icon) matching
            -- the vanilla pattern (ISFarmingMenu.lua:1042).
            local name = ft
            local tex = nil
            pcall(function()
                local script = ScriptManager.instance:getItem(ft)
                if script then
                    name = script:getDisplayName() or ft
                    local iconPath = script:getIcon()
                    if iconPath then
                        tex = getTexture("media/textures/Item_" .. iconPath)
                    end
                end
            end)
            byType[ft] = {
                fullType = ft,
                displayName = name,
                iconTex = tex,
                have = 0,
                need = inputDef.amount or 1,  -- (beast W24)
            }
            typeOrder[#typeOrder + 1] = ft
        end
    end

    -- Build flat list, sorted: owned first, then alphabetical within each group
    local owned = {}
    local other = {}
    for _, ft in ipairs(typeOrder) do
        local alt = byType[ft]
        if alt.have > 0 then
            owned[#owned + 1] = alt
        else
            other[#other + 1] = alt
        end
    end
    table.sort(owned, function(a, b) return a.displayName < b.displayName end)
    table.sort(other, function(a, b) return a.displayName < b.displayName end)

    return { owned = owned, other = other, totalOwned = #owned, totalAll = #owned + #other }
end

-- ============================================================================
-- STATE MACHINE — create / transition helpers
-- ============================================================================

--- A fresh state table for one tab, made once per tab and window (the
--- controller's closures in CC.buildFocusables rely on it staying the same table).
function CC.createState()
    return {
        activeCat        = "all",
        search           = "",
        altSearch         = "",
        sort             = "craftable", -- "craftable" | "known" | "name" | "freq"
        showAll          = false,
        ownedOnly        = false,
        pinnedCollapsed  = false,
        freqCollapsed    = false,
        allCollapsed     = false,
        selected         = nil,        -- recipe ID when craft card open
        qty              = 1,
        altSlotName      = nil,        -- nil = list mode, slot name = alt mode
        altSlotIdx       = nil,        -- index into ingredients for selected slot
        altItems         = nil,        -- cached alt enumeration result
        picks            = {},         -- chosen ingredient per slot: picks[recipe][slotIdx] = full type
        reqCollapsed     = false,      -- REQUIRED section collapsed
        outCollapsed     = false,      -- OUTPUTS section collapsed
        catDropdownOpen  = false,      -- category dropdown expanded
        catDropdownScroll = 0,        -- dropdown scroll offset (rows)
        sortMenuOpen     = false,      -- the band's Sort pop-up list open
        showMenuOpen     = false,      -- the band's Show pop-up list open
        splitFrac        = 0,          -- 0→1 animation progress for pane split
        splitTarget      = 0,          -- 0 = closed, 1 = open
        zones            = {},         -- click zones for current frame
        pins             = {},         -- list of pinned recipe names
        pinsLoaded       = false,
        filterDirty      = true,
        filteredCache    = nil,
        filteredCounts   = nil,
        scroll           = ZeD_ScrollbarState:new(),
        altScroll        = ZeD_ScrollbarState:new(),
        cardScroll       = ZeD_ScrollbarState:new(),
    }
end

function CC.handleRecipeClick(state, recipeId)
    if state.selected == recipeId then
        -- A second click on the open row leaves its card open, so a double-click does not shut what
        -- the first click opened; another row or Escape closes it (KISS #47)
        return
    else
        -- Select new recipe: open or swap craft card
        CC.openCraft(state, recipeId)
    end
end

-- Escape (the prompts' key hook asks, as for the map pop-out): an open recipe card, drawn within the last
-- half second, closes and the game's pause menu stays shut (KISS #47). Registered under ZeD.EscapeTakers.
CC._cardStates = {}   -- the states that had a card open
-- (a state whose card was last drawn a while ago, its window shut or the card closed, is dropped, so a World window
-- opened again and again does not keep every old state alive: QA's read, Nov 25 2026)
local CARD_STALE_MS = 5000
function CC.pruneCardStates(now)
    local old = nil
    for state in pairs(CC._cardStates) do
        if not state.selected or not state._cardDrawnAt or now - state._cardDrawnAt > CARD_STALE_MS then
            old = old or {}
            old[#old + 1] = state
        end
    end
    if old then for _, s in ipairs(old) do CC._cardStates[s] = nil end end
end
function CC.takeEscape()
    local now = getTimestampMs()
    local hit = nil
    for state in pairs(CC._cardStates) do
        if state.selected and state._cardDrawnAt and (now - state._cardDrawnAt) < 500 then
            hit = state
            break
        end
    end
    if hit then
        CC.closeCraft(hit)
        return true
    end
    return false
end
ZeD.EscapeTakers = ZeD.EscapeTakers or {}
ZeD.EscapeTakers.recipeCard = CC.takeEscape

--- Opens the craft card on recipeId: no picks, amount 1, the split pane opening,
--- the alternatives list left.
function CC.openCraft(state, recipeId)
    state.selected = recipeId
    state.picks = {}   -- a fresh recipe starts on the game's own choice of ingredients
    state.qty = 1
    state.splitTarget = 1
    -- Exit alt mode if active
    if state.altSlotName then CC.exitAltMode(state) end
    -- Reset card scroll
    state.cardScroll:setScrollPos(0)
end

--- Shuts the craft card: nothing selected, no picks, the split pane closing. The list
--- is filtered again (a row Show held back only because its card was open goes with it).
function CC.closeCraft(state)
    state.selected = nil
    state.picks = {}
    state.qty = 1
    state.splitTarget = 0
    state.filterDirty = true
    if state.altSlotName then CC.exitAltMode(state) end
end

--- The list filtered and sorted again for the band's choices (filterAndSort), the card kept
--- to it: the card is the list's picked row, so a recipe the list no longer shows (another
--- category, a search that leaves it out) closes its card. Show never hides the open card's
--- recipe (filterAndSort keeps its row).
function CC.refilter(data, state, config, win)
    state.filteredCache, state.filteredCounts = CC.filterAndSort(data, state, config, win)
    state.filterDirty = false
    state._sectionsStale = true  -- sections depend on filteredCache
    local sel = state.selected
    if not sel then return end
    for _, rd in ipairs(state.filteredCache) do
        if rd.entry.name == sel then return end
    end
    CC.closeCraft(state)
end

function CC.enterAltMode(state, slotName, slotIdx, playerObj, containers, inputDef)
    if state.altSlotName == slotName then
        -- Same slot clicked again — exit alt mode
        CC.exitAltMode(state)
        return
    end
    state.altSlotName = slotName
    state.altSlotIdx  = slotIdx
    state.altSearch   = ""
    state.altItems    = CC.enumerateAlts(playerObj, containers, inputDef)
    state.altScroll:setScrollPos(0)
end

--- Leaves the alternatives list for the recipe list.
function CC.exitAltMode(state)
    state.altSlotName = nil
    state.altSlotIdx  = nil
    state.altItems    = nil
    state.altSearch   = ""
end

-- ============================================================================
-- ANIMATION — split pane ease
-- Cubic-bezier(0.4, 0, 0.2, 1) approximated as ease-out cubic: 1-(1-t)^3.
-- Tracks real elapsed time via getTimestampMs() for frame-rate independence.
-- ============================================================================

-- Approximates cubic-bezier(0.4, 0, 0.2, 1) via ease-out cubic.
-- Maps linear progress t (0→1) to eased output.
local function easeOutCubic(t)
    local inv = 1 - t
    return 1 - inv * inv * inv
end

function CC.updateSplitAnimation(state)
    local target = state.splitTarget
    local current = state.splitFrac
    if current == target then
        state._splitStartMs = nil
        state._splitFrom    = nil
        state._splitDir     = nil
        return
    end

    local now = getTimestampMs()
    local dir = target > current and 1 or -1

    -- First frame of a new animation, or direction reversed mid-flight
    if not state._splitStartMs or state._splitFrom == nil or dir ~= state._splitDir then
        state._splitStartMs = now
        state._splitFrom    = current
        state._splitDir     = dir
    end

    local elapsed = (now - state._splitStartMs) / 1000.0  -- seconds
    local t = math.min(1, elapsed / CC.ANIM_DURATION)
    local eased = easeOutCubic(t)

    -- Lerp from starting value toward target
    state.splitFrac = state._splitFrom + (target - state._splitFrom) * eased

    -- Snap when done
    if t >= 1 then
        state.splitFrac     = target
        state._splitStartMs = nil
        state._splitFrom    = nil
        state._splitDir     = nil
    end
end

-- ============================================================================
-- RENDERING — Header strip: one row, the standard height.
-- Craft: the STATION and CATEGORY selects and the search side by side;
-- Build: CATEGORY and the search. The read-only list (the Journal's Recipes page)
-- draws no header of its own: the Journal's header holds its search, the band
-- its Category select.
-- ============================================================================

-- The Category select (the pop-up menu's look, ZeD_Dropdown, drawn in place:
-- Stations.drawSelect). Its list is the overlay drawn last, from the box's foot or,
-- up = true (in the band at the card's foot), above the box. In alt mode it is
-- frozen on "Compatible", greyed: it cannot be opened there.
local function drawCatSelect(panel, state, pfx, x, y, w, h, label, up)
    local select = ZeD.Stations and ZeD.Stations.drawSelect
    if state.altSlotName then
        if select then select(panel, x, y, w, h, label, ZeD.tr("UI_ZeD_Craft_Compatible"), false, false, false, true) end
        return
    end
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local hov = (not anyOpen(state)) and mx >= x and mx < x + w and my >= y and my < y + h
    if select then
        select(panel, x, y, w, h, label, CC.activeCategoryLabel(state), false,
            state._gpFocusedId == (pfx .. ":catDrop"), hov)
    end
    if hov then ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Craft_CategoryHelp")) end
    local zones = state.zones
    zones[#zones + 1] = { type = "catDropdown", x = x, y = y, w = w, h = h }
    -- the overlay's geometry: its list's top-left and width
    local g = state._ddGeo or {}
    state._ddGeo = g
    g.x, g.w = x, w
    g.bx, g.by, g.bw, g.bh = x, y, w, h   -- (the box itself: inside the list for ZeD.Popups)
    if up then
        g.y = y - math.min(#(state.categoryList or {}), DD_MAX_VIS) * ZeD.T.px(DD_ROW_H)
    else
        g.y = y + h
    end
end

--- The tab's search field (a ZeD_SearchField, a child panel of the drawer, made by the
--- window): placed where the caller says; in alt mode it filters the alternatives.
function CC.placeSearch(win, config, state, x, y, w, h)
    local f = win and config and win["_" .. tostring(config.prefix) .. "Search"]
    if not f then return end
    if f:getX() ~= x or f:getY() ~= y then f:setX(x); f:setY(y) end
    if f:getWidth() ~= w or f:getHeight() ~= h then f:setWidth(w); f:setHeight(h) end
    -- the controller's stop on it (punch list 252; CC.buildFocusables, "<prefix>:search") and its mark
    if state then
        local r = state._searchRect or {}
        state._searchRect = r
        r.x, r.y, r.w, r.h = x, y, w, h
        state._searchField = f
        if state._gpFocusedId == (tostring(config.prefix) .. ":search") and f.parent and ZeD.Focus and ZeD.Focus.mark then
            ZeD.Focus.mark(f.parent, x, y, w, h, { win = win })
        end
    end
    if f._zedBaseHint == nil then f._zedBaseHint = f.placeholder or false end   -- (the field's own words: Build's names structures)
    if state.altSlotName then f.placeholder = ZeD.tr("UI_ZeD_Craft_FilterAlts")
    else f.placeholder = f._zedBaseHint or getText("IGUI_CraftingWindow_SearchRecipes") end
end

--- The tab's title (design review C1, ruled Nov 12 2026: every tab body opens with its title):
--- the library's tab head, no fold, row 1 high. config.titleVKey is the game's word, config.titleKey
--- ZeD's. Returns its height (0 with neither).
function CC.tabTitleText(config)
    if not config then return nil end
    if config.titleVKey then return getText(config.titleVKey) end
    if config.titleKey then return ZeD.tr(config.titleKey) end
    return nil
end

function CC.renderTabTitle(panel, x, y, w, config)
    local title = CC.tabTitleText(config)
    if not title then return 0 end
    return M.drawTabHeader(panel, x, y, w, title, false, false, true)
end

-- The Station box shows only when a station is in reach: one is bound, or one stands within the
-- stations' reach (the dropdown would list it). With none, the box would read "Station: Hand" and
-- take a third of the row for nothing (KISS #48).
function CC.stationShown(win, ST)
    local player = win and win._playerObj
    if not (ST and player) then return false end
    if ST.current(player) then return true end
    local list = ST.nearby(player)
    return list ~= nil and #list > 0
end

function CC.renderStaticHeader(panel, x, y, w, state, config, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local zones = state.zones
    local pfx = (config and config.prefix) or "jrecipe"
    local ST = config and config.stations and ZeD.Stations or nil
    -- no title row: the window's title bar already ends "+ Crafting" (KISS #48); the selects and the
    -- search take the first row
    local titleH = 0
    local showSt = CC.stationShown(win, ST)
    local headerH = T.stripH  -- the selects' row, the shared strip
    local pad, gap = T.px(6), T.px(6)
    local ddH = T.inputH  -- the selects match the search field
    local rowY = y + math.floor((headerH - ddH) / 2)
    local ddX, ddW, searchX, searchW

    if showSt then
        -- Crafting: STATION, CATEGORY and the search in thirds; a select is never narrower
        -- than its label, its value and its arrow ("Category: All" v): the search gives it
        -- the room, down to half its own third (at 1280x720, UI scale 2.0, Large text an
        -- even split read the Category as "-- A...")
        local selW = math.floor((w - pad * 2 - gap * 2) / 3)
        local player = win and win._playerObj
        local cur = player and ST.current(player) or nil
        local stVal = cur and cur.name or ZeD.tr("UI_ZeD_Station_Hand")
        local stW = math.max(selW, ST.selectW(ZeD.tr("UI_ZeD_Station_SelectLabel"), stVal))
        local cW = math.max(selW, ST.selectW(ZeD.tr("IGUI_invpanel_Category"), CC.activeCategoryLabel(state)))
        local grow = (stW - selW) + (cW - selW)
        local spare = (w - pad * 2 - gap * 2) - stW - cW - math.floor(selW / 2)
        if spare < 0 and grow > 0 then
            -- the search at its least: the two give back what they grew, by their growth
            local back = math.min(-spare, grow)
            local sb = math.floor(back * (stW - selW) / grow)
            stW, cW = stW - sb, cW - (back - sb)
        end
        local stX = x + pad
        ddX, ddW = stX + stW + gap, cW
        searchX = ddX + ddW + gap
        searchW = x + w - pad - searchX
        local mx, my = panel:getMouseX(), panel:getMouseY()
        local hov = (not anyOpen(state)) and mx >= stX and mx < stX + stW and my >= rowY and my < rowY + ddH
        ST.drawSelect(panel, stX, rowY, stW, ddH, ZeD.tr("UI_ZeD_Station_SelectLabel"), stVal,
            cur ~= nil, state._gpFocusedId == (pfx .. ":stDrop"), hov)
        zones[#zones + 1] = { type = "stationDropdown", x = stX, y = rowY, w = stW, h = ddH }
        state._stGeo = { x = stX, y = rowY + ddH, w = stW }
    else
        -- Building, or Crafting with no station in reach: the Category select LEFT (~45%), the search RIGHT
        state.stDropdownOpen = false   -- (no Station box now: a list left open for it goes)
        ddW = math.floor((w - pad * 2 - gap) * 0.45)
        ddX = x + pad
        searchX = ddX + ddW + gap
        searchW = w - pad * 2 - gap - ddW
    end

    CC.placeSearch(win, config, state, searchX, rowY, searchW, ddH)
    -- (labeled in Building too: "Category: All", not a bare "-- ALL --")
    drawCatSelect(panel, state, pfx, ddX, rowY, ddW, ddH, ZeD.tr("IGUI_invpanel_Category"), false)

    -- Bottom rule on header row
    A.drawDividerH(panel, x, y + headerH - T.px(1), w, true)

    return titleH + headerH
end

-- ============================================================================
-- RENDERING — Alternatives strip (alt mode, 20u): the alternatives list's own
-- strip (back, the owned count, Owned only), a fold of the card. Sorting lives
-- in the band (Sort and Show), so out of alt mode this draws nothing and is
-- 0 tall.
-- ============================================================================

local EMPTY_ALT = { totalOwned = 0, totalAll = 0 }

function CC.renderStrip(panel, x, y, w, state, config)
    if not state.altSlotName then
        state._altStripLast = nil
        return 0
    end
    local zones = state.zones
    -- the part under the pointer, from last frame's strip
    local hoverZone = nil
    local last = state._altStripLast
    if last and not (anyOpen(state) or cuesOn()) then
        local mx, my = panel:getMouseX(), panel:getMouseY()
        for _, z in ipairs(last) do
            if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h then hoverZone = z.id; break end
        end
    end
    -- the part with the controller's focus; the strip draws the mark itself
    local pfx = (config and config.prefix) or "jrecipe"
    local fid = state._gpFocusedId
    local so = state._stripOpts or {}
    state._stripOpts = so
    so.focusId = nil
    if fid then
        if fid == pfx .. ":altBack" then so.focusId = "back"
        elseif fid == pfx .. ":altOwned" then so.focusId = "ownedOnly" end
    end
    local altData = state.altItems or EMPTY_ALT
    local h, stripZones = M.drawAltBackStrip(panel, x, y, w,
        state.altSlotName, altData.totalOwned, altData.totalAll,
        state.ownedOnly, hoverZone, so)
    state._altStripLast = stripZones
    for _, z in ipairs(stripZones) do
        z.type = "altStrip_" .. z.id
        zones[#zones + 1] = z
    end
    return h
end

-- ============================================================================
-- RENDERING — The band: at the card's foot, the full
-- card's width (the split pane's list and card both sit above it), just above the
-- window's help line. Left: Sort and Show as System 7 pop-up menus (the read-only
-- list: its Category select first). Right: the amount (- 1 +) and Craft / Build,
-- last. Until a recipe is picked the amount and Craft / Build are drawn greyed and
-- take no press, so the band never changes shape; in alt mode the pop-ups are
-- greyed, as the Category select is frozen.
-- ============================================================================

-- The band's two pop-up lists: the state fields each keeps, its box's zone type and
-- focus id ("<prefix>:sortMenu"), its rows' ids ("<prefix>:sortRow:<choice>")
local POP = {
    sort = { open = "sortMenuOpen", geo = "_sortMenuGeo", zones = "_sortMenuZones", opts = "_sortMenuOpts",
             box = "sortMenu", row = ":sortRow:", help = "UI_ZeD_Craft_SortHelp" },
    show = { open = "showMenuOpen", geo = "_showMenuGeo", zones = "_showMenuZones", opts = "_showMenuOpts",
             box = "showMenu", row = ":showRow:", help = "UI_ZeD_Craft_ShowHelp" },
}
CC.POP = POP

local CAT_BAND_W = 170   -- design units: the read-only list's Category select in the band
local _bandBtns = { {} }
local _bandSpec = { buttons = _bandBtns }
local _bandSpecRO = {}
local _bandStep = {}

-- The pop-up boxes' widths: the longest words each can carry ("Sort: Craftable"), so the
-- band keeps its shape whichever choice is current; kept per scale, font and language.
local function popWidths(state, config, sortModes, showModes)
    local T = ZeD.T
    local c = state._popW
    local lang = (ZeD.trTestOn and ZeD.trTestOn()) and 1 or 0
    local ro = config.readOnly and true or false
    if c and c.scale == T.scale and c.font == T.fontF1 and c.lang == lang and c.ro == ro then return c.sort, c.show, c.sortC, c.showC end
    local sw, hw, sc, hc = 0, 0, 0, 0
    for _, m in ipairs(sortModes) do
        sw = math.max(sw, M.popupMenuW(ZeD.tr("UI_ZeD_Craft_SortPick", m.label)))
        sc = math.max(sc, M.popupMenuW(ZeD.tr("UI_ZeD_Craft_SortPick", m.label), true))
    end
    for _, m in ipairs(showModes) do
        hw = math.max(hw, M.popupMenuW(ZeD.tr("UI_ZeD_Craft_ShowToggle", m.label)))
        hc = math.max(hc, M.popupMenuW(ZeD.tr("UI_ZeD_Craft_ShowToggle", m.label), true))
    end
    -- (sortC / showC: the longest words in a tight box, for a band short of room; the label
    -- stays, "Sort: Craftable", design review C2)
    state._popW = { scale = T.scale, font = T.fontF1, lang = lang, ro = ro, sort = sw, show = hw, sortC = sc, showC = hc }
    return sw, hw, sc, hc
end

-- One of the band's pop-up boxes: its zone, and the open list's geometry (it opens
-- upward from the box: the band is at the card's foot). frozen: greyed, no press.
-- (short: the choice alone, shown when the label does not fit; the band passes none, so
-- "Sort: Craftable" keeps its label and is cut instead: design review C2)
local function drawPopBox(panel, state, kind, x, y, w, h, label, modes, frozen, focused, mx, my, short, tight)
    local P = POP[kind]
    local hov = (not frozen) and mx >= x and mx < x + w and my >= y and my < y + h
    M.drawPopupMenu(panel, x, y, w, h, label, hov or state[P.open] == true, (focused and not frozen) and NO_FOCUS_OPTS or nil, frozen, short, tight)
    if frozen then
        state[P.open] = false
        state[P.zones] = nil
        return
    end
    if hov then ZeD.Help.set(panel, ZeD.tr(P.help)) end
    local zones = state.zones
    zones[#zones + 1] = { type = P.box, x = x, y = y, w = w, h = h }
    local g = state[P.geo] or {}
    state[P.geo] = g
    g.x, g.y, g.w, g.modes = x, y - M.popupListH(#modes), w, modes
    g.by, g.bh = y, h   -- (the box itself: inside the list for ZeD.Popups)
end

-- The amount and Craft / Build at the band's right; returns the x the left part ends at,
-- and true when the band is short of room. leftNeed: the room the left part's boxes need
-- from x at the usual spacing; short of it, the amount closes up (its gap to Craft / Build,
-- its readout only as wide as its digits).
local function drawBandActions(panel, x, y, w, state, config, rd, pfx, fid, mx, leftNeed)
    local T = ZeD.T
    local zones = state.zones
    local bh = T.buttonH
    local gap = T.px(8)
    local qty, maxQty, canCraft = 1, 1, false
    if rd then
        maxQty = rd.maxBatchQty or 1
        if maxQty < 0 then maxQty = 0 end
        state._maxQty = maxQty  -- the click handler's cap
        -- Clamp qty to maxQty (may have changed since last frame)
        if state.qty > maxQty and maxQty > 0 then state.qty = maxQty end
        if state.qty < 1 then state.qty = 1 end
        qty = state.qty
        -- (rd.canStart: the craft's own start check, false when it would refuse; the Craft tab sets it)
        -- (rd.busy: a craft ZeD queued is still waiting or running; gray, as the game's Craft is while
        -- its craft runs: QA cb sweep, Nov 25 2026, C1)
        canCraft = rd.status == "craftable" and rd.learned ~= false and maxQty > 0 and rd.canStart ~= false
            and not rd.busy
    end
    -- the band: surface 2, the structure line, Craft / Build (primary) at the right
    local b = _bandBtns[1]
    b.label = ZeD.tr(config.buildLabel or "IGUI_CraftingWindow_Craft")
    b.variant, b.disabled, b.id = "primary", not canCraft, "build"
    if mx < 0 then b.hover = false else b.hover = nil end
    b.focus = (rd and fid == pfx .. ":actBuild") and NO_FOCUS_OPTS or nil
    _bandSpec.win = state._focusWin
    -- the amount (- n +) left of it; the readout is as wide as the stepper makes it. Short
    -- of room is measured at the usual sizes, before the band is drawn
    local qtyTW = ZeD.TM:MeasureStringX(T.fontF3, tostring(qty))
    local qtyW = math.max(bh, qtyTW + T.px(8))
    local stepW = bh * 2 + qtyW + 2 * T.px(4)
    local edge = T.px(8)
    -- (KISS #32) the amount shows only where more than one can be made (Build makes one at a time, so it
    -- shows none), and a Max key follows its + to set the most the band already knows
    local showSteps = rd ~= nil and maxQty > 1
    local maxLabel = ZeD.tr("UI_ZeD_Craft_Max")
    local maxW = M.buttonW(maxLabel)
    -- the room the band's right part takes: Craft / Build, then (when shown) Max and the amount, with their spaces
    local rightW = M.buttonW(b.label) + gap
    if showSteps then rightW = rightW + gap + maxW + gap + stepW end
    local narrow = (x + w - edge - rightW - x) < (leftNeed or 0)
    if narrow then
        -- (short of room the - n + become one amount box, "< 3 >": its halves,
        -- the wheel and the pad's Left / Right step it. The box is as narrow as
        -- its digits, Craft / Build as narrow as its word, the band's margins
        -- and spaces 4u — so Sort and Show keep whole words)
        gap, edge = T.px(4), T.px(4)
        stepW = M.qtySpinW(qty)
        maxW = ZeD.TM:MeasureStringX(T.fontF3, ZeD.btnCase(maxLabel)) + T.px(4) * 2   -- Max closes up as Craft does
        b.w = ZeD.TM:MeasureStringX(T.fontF3, ZeD.btnCase(b.label)) + T.px(4) * 2
        _bandSpec.edge = edge
    else
        b.w, _bandSpec.edge = nil, nil
    end
    -- (the World window's pad stops rebuild when the band changes shape or recipe: stamped here,
    -- the frame its zones are made, not when the recipe is picked)
    state._bandSingle = tostring(narrow) .. (showSteps and "+" or "-")   -- (the amount and Max shown or not change the stops too) (KISS #32)
    state._bandSel = rd and rd.entry and rd.entry.name or nil
    local _, out = M.drawBand(panel, x, y, w, _bandSpec)
    local r = out.buttons[1]
    local rx = r and r.x or (x + w - edge)
    local maxX = rx - gap - maxW
    local sx = showSteps and (maxX - gap - stepW) or rx
    local so = _bandStep
    so.focusId = nil
    so.narrow = narrow
    so.single = narrow
    if rd and fid then
        if fid == pfx .. ":actDec" then so.focusId = "dec"
        elseif fid == pfx .. ":actInc" then so.focusId = "inc"
        elseif fid == pfx .. ":actQty" then so.focusId = "qty" end
    end
    local stepZones = CC._noZones   -- (a shared empty list: nothing drawn, nothing to click)
    if showSteps then
        _, stepZones = M.drawQtyStepper(panel, sx, y + T.px(5), qty, maxQty, bh, (mx < 0) and "" or nil, so)
        -- Max: sets the most the band knows; grayed once the amount is there (KISS #32)
        local mo = CC._maxOpts
        if not mo then mo = {}; CC._maxOpts = mo end
        mo.win = state._focusWin
        mo.disabled = qty >= maxQty
        mo.hover = (mx >= 0) and ZeD.Atoms.mouseIn(panel, maxX, y + T.px(5), maxW, bh) or false
        mo.focus = (fid == pfx .. ":actMax") and NO_FOCUS_OPTS or nil
        M.drawButton(panel, maxX, y + T.px(5), maxW, bh, maxLabel, "default", false, nil, mo)
    end
    if narrow then state._qtyBox = state._qtyBox or {} end
    local qb = state._qtyBox
    if qb then
        qb.on, qb.x, qb.y, qb.w, qb.h = narrow and showSteps, sx, y + T.px(5), stepW, bh
        qb.t = getTimestampMs()   -- (drawn this frame: a band no longer drawn takes no wheel)
    end
    -- the one box with nothing to step (the most is 1: Build, or materials for one): it stays a
    -- pad stop, A and the wheel change nothing, and the help line says why
    if narrow and rd and maxQty <= 1 and (so.focusId == "qty" or (mx >= 0 and ZeD.Atoms.mouseIn(panel, sx, y + T.px(5), stepW, bh))) then
        ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Craft_QtyOne"))
    end
    if rd then
        for _, z in ipairs(stepZones) do
            z.type = "action_" .. z.id
            -- the one box: the pad has one stop for it (buildFocusables)
            if narrow then z.single, z.bx, z.bw = true, sx, stepW end
            zones[#zones + 1] = z
        end
        if showSteps then zones[#zones + 1] = { type = "action_max", x = maxX, y = y + T.px(5), w = maxW, h = bh } end
        if r then zones[#zones + 1] = { type = "action_build", x = r.x, y = r.y, w = r.w, h = r.h } end
    end
    return sx - gap, narrow
end

CC._noZones = {}
function CC.renderBand(panel, x, y, w, state, config, rd)
    local T = ZeD.T
    local pfx = (config and config.prefix) or "jrecipe"
    local fid = state._gpFocusedId
    local ro = config.readOnly
    local frozen = state.altSlotName ~= nil
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if anyOpen(state) or cuesOn() then mx, my = -1, -1 end
    local bh = T.buttonH
    local by = y + T.px(5)
    local edge, gap = T.px(8), T.px(8)

    -- the left's boxes: at most the longest words each can carry, at least the current
    -- words and the arrow ("Sort: Craftable" v), and at worst the first letter and the arrow
    -- (a plain even share leaves Sort and Show too narrow for any words at 1280x720,
    -- UI scale 2.0, Large text)
    local sortModes = CC.popModes("sort", config)
    local showModes = CC.popModes("show", config)
    -- every box keeps its label, "Sort: Craftable" (design review C2): short of room the words
    -- are cut, never swapped for the choice alone
    local sortName = ZeD.tr("UI_ZeD_Craft_SortPick", modeLabel(sortModes, CC.sortOf(state)))
    local showName = ZeD.tr("UI_ZeD_Craft_ShowToggle", modeLabel(showModes, CC.showMode(state, config)))
    local sortW, showW, sortC, showC = popWidths(state, config, sortModes, showModes)
    local catName = ro and CC.activeCategoryLabel(state) or nil
    local catW = ro and T.px(CAT_BAND_W) or 0
    local sortMin, showMin = math.min(sortW, M.popupMenuW(sortName)), math.min(showW, M.popupMenuW(showName))
    local catLbl = ro and ZeD.tr("IGUI_invpanel_Category") or nil
    local catMin = ro and math.min(catW, (ZeD.Stations and ZeD.Stations.selectW) and ZeD.Stations.selectW(catLbl, catName)
        or M.popupMenuW(catName)) or 0
    local nGaps = ro and 2 or 1

    -- the right: the amount and Craft / Build (the read-only list has none)
    local leftEnd, narrow
    if ro then
        -- (KISS #40) the Journal's list has one key at the right once a recipe is picked: Open in Craft / Build
        local openLbl = rd and config.openLabel and config.openLabel(rd) or nil
        if openLbl then
            local b = _bandBtns[1]
            b.label, b.variant, b.disabled, b.id, b.w = openLbl, "primary", false, "open", nil
            b.hover = (mx < 0) and false or nil
            b.focus = (fid == pfx .. ":actOpen") and NO_FOCUS_OPTS or nil
            _bandSpec.win, _bandSpec.edge = state._focusWin, nil
            local _, out = M.drawBand(panel, x, y, w, _bandSpec)
            local r = out.buttons[1]
            leftEnd = r and (r.x - gap) or (x + w - edge)
            if r then state.zones[#state.zones + 1] = { type = "action_open", x = r.x, y = r.y, w = r.w, h = r.h, rd = rd, open = config.openAction } end
        else
            _bandSpecRO.win = state._focusWin
            M.drawBand(panel, x, y, w, _bandSpecRO)
            leftEnd = x + w - edge
        end
        narrow = (leftEnd - x - edge - gap * nGaps) < catMin + sortMin + showMin
    else
        leftEnd, narrow = drawBandActions(panel, x, y, w, state, config, rd, pfx, fid, mx,
            edge + gap * nGaps + catMin + sortMin + showMin)
    end
    -- short of room the spaces close up first, and the boxes keep "Sort: Craftable" at tight
    -- pads, the longest words at most
    if narrow then
        edge, gap = T.px(4), T.px(4)
        sortW, showW = sortC, showC
        sortMin, showMin = M.popupMenuW(sortName, true), M.popupMenuW(showName, true)
    end

    local lx = x + edge
    local avail = math.max(0, leftEnd - lx - gap * nGaps)
    local need = catW + sortW + showW
    if need > avail and need > 0 then
        local minSum = catMin + sortMin + showMin
        if avail >= minSum then
            -- each keeps its choice; the room over that is shared by what each could use
            local k = (need > minSum) and (avail - minSum) / (need - minSum) or 0
            catW = catMin + math.floor((catW - catMin) * k)
            sortW = sortMin + math.floor((sortW - sortMin) * k)
            showW = showMin + math.floor((showW - showMin) * k)
        else
            -- even the choices do not fit: each keeps its first letter and its arrow, and
            -- the rest is shared by what each choice needs over that
            local catF = ro and math.min(catMin, M.popupMenuW(string.sub(catName or "", 1, 1), narrow)) or 0
            local sortF = math.min(sortMin, M.popupMenuW(string.sub(sortName, 1, 1), narrow))
            local showF = math.min(showMin, M.popupMenuW(string.sub(showName, 1, 1), narrow))
            local fSum = catF + sortF + showF
            if avail >= fSum then
                local k = (minSum > fSum) and (avail - fSum) / (minSum - fSum) or 0
                catW = catF + math.floor((catMin - catF) * k)
                sortW = sortF + math.floor((sortMin - sortF) * k)
                showW = showF + math.floor((showMin - showF) * k)
            else
                local k = (fSum > 0) and avail / fSum or 0
                catW, sortW, showW = math.floor(catF * k), math.floor(sortF * k), math.floor(showF * k)
            end
        end
    end
    if ro then
        drawCatSelect(panel, state, pfx, lx, by, catW, bh, catLbl, true)
        lx = lx + catW + gap
    end
    drawPopBox(panel, state, "sort", lx, by, sortW, bh, sortName, sortModes, frozen, fid == pfx .. ":sortMenu", mx, my, nil, narrow)
    lx = lx + sortW + gap
    drawPopBox(panel, state, "show", lx, by, showW, bh, showName, showModes, frozen, fid == pfx .. ":showMenu", mx, my, nil, narrow)
end

-- A band pop-up's list, open: drawn last (over the rows) above its box. Its row zones are
-- kept for the click and the controller; the choice that has the controller's focus
-- carries the mark.
function CC.renderPopMenu(panel, state, config, kind)
    local P = POP[kind]
    local geo = state[P.geo]
    if not (state[P.open] and geo and geo.modes) then return end
    local pfx = (config and config.prefix) or "jrecipe"
    local hoverId = nil
    if not cuesOn() then
        local mx, my = panel:getMouseX(), panel:getMouseY()
        local zs = state[P.zones]
        if zs then
            for _, z in ipairs(zs) do
                if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h then hoverId = z.id; break end
            end
        end
    end
    local mo = state[P.opts] or {}
    state[P.opts] = mo
    mo.focusId, mo.minW = nil, geo.w
    local fid = state._gpFocusedId
    if fid then
        local rp = pfx .. P.row
        if string.sub(fid, 1, #rp) == rp then mo.focusId = string.sub(fid, #rp + 1) end
    end
    local active = (kind == "show") and CC.showMode(state, config) or CC.sortOf(state)
    local lw, lh, zs = M.drawSortMenuList(panel, geo.x, geo.y, geo.modes, active, hoverId, mo)
    state[P.zones] = zs
    geo.lw, geo.lh = lw, lh   -- (the open list's size, for ZeD.Popups: CC.popupsShown)
end

function CC.renderSortMenu(panel, state, config) CC.renderPopMenu(panel, state, config, "sort") end

-- Open one of the band's pop-up lists (the other lists and the selects shut).
function CC.openPopMenu(state, kind)
    state.sortMenuOpen = (kind == "sort")
    state.showMenuOpen = (kind == "show")
    state.catDropdownOpen = false
    state.stDropdownOpen = false
end

-- ZeD.Popups' hooks for the band's lists and the Category select's (ZeD_Popups.lua)
function CC.sortIsOpen(state) return state.sortMenuOpen == true end
function CC.showIsOpen(state) return state.showMenuOpen == true end
function CC.catIsOpen(state) return state.catDropdownOpen == true end
function CC.closeCatDropdown(state)
    state.catDropdownOpen = false
    state.catDropdownScroll = 0
end

--- The open lists of one tab's pipeline (Journal Recipes, Craft, Build) tell ZeD.Popups they were drawn this
--- frame: the list and its box count as inside. Keys "<prefix>:sort|show|cat:<player>".
function CC.popupsShown(panel, win, state, config)
    local Pp = ZeD.Popups
    if not Pp then return end
    local pfx = (config and config.prefix) or "jrecipe"
    local pn = (win and win.playerNum) or 0
    local g = state._sortMenuGeo
    if state.sortMenuOpen and g and g.lw then
        local po = Pp.opts(state, pfx .. ":sort", CC.sortIsOpen, pn)
        Pp.shownAt(po.key, panel, CC.closeSortMenu, po, g.x, g.y, g.lw, g.lh, g.x, g.by, g.w, g.bh)
    end
    g = state._showMenuGeo
    if state.showMenuOpen and g and g.lw then
        local po = Pp.opts(state, pfx .. ":show", CC.showIsOpen, pn)
        Pp.shownAt(po.key, panel, CC.closeShowMenu, po, g.x, g.y, g.lw, g.lh, g.x, g.by, g.w, g.bh)
    end
    g = state._ddGeo
    if state.catDropdownOpen and g and g.lh then
        local po = Pp.opts(state, pfx .. ":cat", CC.catIsOpen, pn)
        Pp.shownAt(po.key, panel, CC.closeCatDropdown, po, g.x, g.y, g.w, g.lh, g.bx, g.by, g.bw, g.bh)
    end
end

-- Shut a pop-up list. The controller returns to the box it came from.
function CC.closePopMenu(state, kind)
    local P = POP[kind]
    state[P.open] = false
    state[P.zones] = nil
    state._gpReturnTo = P.box
end
function CC.closeSortMenu(state) CC.closePopMenu(state, "sort") end
function CC.closeShowMenu(state) CC.closePopMenu(state, "show") end

-- A choice picked in one of the band's lists: applied, the list shut.
function CC.pickPop(state, config, kind, id)
    if kind == "show" then CC.setShow(state, id)
    else
        state.sort = id
        state.filterDirty = true
    end
    CC.closePopMenu(state, kind)
end

-- ============================================================================
-- RENDERING — Recipe List (scrollable, 3 sections: Pinned / Frequent / All)
-- ============================================================================

function CC.renderRecipeList(panel, x, y, w, h, state, config, data, playerObj)
    local T     = ZeD.T
    local zones = state.zones
    local scroll = state.scroll
    local ROW_H = T.px(CC.ROW_H)
    local catHdrH = T.sp.catHdrH

    -- Sections + totalH are cached — only rebuilt when filterDirty was just processed
    -- (state._sectionsStale is set by the filterDirty block in CC.render)
    local sections    = state._sections
    local totalH      = state._sectionsTotalH or 0
    local pinSet      = state._pinSet or {}
    local freqCounts  = state._freqCounts or {}

    if not sections or state._sectionsStale or state._sectionsScale ~= T.scale then  -- totalH is screen px: rebuilt when T.scale changes
        state._sectionsStale = false

        pinSet = {}
        freqCounts = {}
        local freqSet = {}
        if not config.readOnly then
            for _, name in ipairs(state.pins) do pinSet[name] = true end
            local freqList = CC.getTopFrequent(playerObj, data.flatRecipes or {}, 5, pinSet, config.countKey)
            for _, f in ipairs(freqList) do
                freqSet[f.name] = true
                freqCounts[f.name] = f.count
            end
        end

        sections = {}

        if not config.readOnly then
            -- 1. Pinned
            local pinnedItems = {}
            for _, name in ipairs(state.pins) do
                for _, rd in ipairs(state.filteredCache or {}) do
                    if rd.entry.name == name then
                        pinnedItems[#pinnedItems + 1] = rd
                        break
                    end
                end
            end
            if #pinnedItems > 0 then
                sections[#sections + 1] = {
                    id = "pinned", label = "UI_ZeD_Craft_Pinned", color = T.accent,
                    items = pinnedItems, collapsed = state.pinnedCollapsed,
                }
            end

            -- 2. Frequently Used (top 5, excluding pinned)
            local freqItems = {}
            local freqList = CC.getTopFrequent(playerObj, data.flatRecipes or {}, 5, pinSet, config.countKey)
            for _, f in ipairs(freqList) do
                for _, rd in ipairs(state.filteredCache or {}) do
                    if rd.entry.name == f.name then
                        freqItems[#freqItems + 1] = rd
                        break
                    end
                end
            end
            if #freqItems > 0 then
                sections[#sections + 1] = {
                    id = "freq", label = "IGUI_SortType_MostUsed", color = T.warning,
                    items = freqItems, collapsed = state.freqCollapsed,
                }
            end
        end

        -- All Recipes (in readOnly: everything; otherwise: exclude pinned+freq)
        local allItems = {}
        for _, rd in ipairs(state.filteredCache or {}) do
            local name = rd.entry.name
            if config.readOnly or (not pinSet[name] and not freqSet[name]) then
                allItems[#allItems + 1] = rd
            end
        end
        -- (QA's visual noise audit 30: Building's head read "All Recipes" over "Search structures..."; it says structures)
        local allKey = (config.prefix == "build") and "UI_ZeD_Craft_AllStructures" or "UI_ZeD_Craft_AllRecipes"
        local allLabel = (#(state.search or "") > 0) and "UI_ZeD_Craft_Results" or allKey   -- keys, translated where drawn
        sections[#sections + 1] = {
            id = "all", label = allLabel, color = nil,
            items = allItems, collapsed = state.allCollapsed,
        }

        -- (QA's visual noise audit 30, Nov 20 2026: "All Recipes (3)" sat right under "Category: All" with nothing
        -- else in the list. The fold head shows only when the list is split into groups (pinned, most used); a list
        -- of one group has no head and cannot fold.)
        if #sections == 1 then sections[1].solo = true; sections[1].collapsed = false end

        -- Measure total content height
        totalH = 0
        for _, sec in ipairs(sections) do
            if not sec.solo then totalH = totalH + catHdrH end
            if not sec.collapsed then
                totalH = totalH + #sec.items * ROW_H
            end
        end

        state._sections       = sections
        state._sectionsTotalH = totalH
        state._sectionsScale  = T.scale
        state._pinSet         = pinSet
        state._freqCounts     = freqCounts
    end

    -- Scrollbar
    local scrollW = T.sp.scrollbarW
    local needsScroll = totalH > h
    scroll.visible = needsScroll
    local contentW = needsScroll and (w - scrollW) or w
    if needsScroll then
        scroll.x = x + w - scrollW
        scroll.y = y
        scroll.height = h
        scroll:setBarSize(h / totalH)
    else
        scroll:setScrollPos(0)
    end

    -- the controller's render-level scroll-follow pass reads this geometry
    -- (viewport bounds + totalH translate screen-space zone positions to
    -- content space)
    state._listGeo = { viewY = y, viewH = h, totalH = totalH }

    -- (QA B10-4) After a re-sort, scroll so the open recipe's row sits at the same place in the view as before.
    local hold = state._holdRow
    state._holdRow = nil
    if hold and needsScroll then
        local cy, found = 0, false
        for _, sec in ipairs(sections) do
            if not sec.solo then cy = cy + catHdrH end
            if not sec.collapsed then
                for _, rd in ipairs(sec.items) do
                    if rd.entry.name == hold.id then found = true; break end
                    cy = cy + ROW_H
                end
            end
            if found then break end
        end
        if found then
            local span = math.max(1, totalH - h)
            local want = math.max(0, math.min(span, cy - hold.rel))
            scroll:setScrollPos((want + 0.5) / span)   -- (+0.5: the bar draws floor(), so the exact share landed 1 px short) (QA B11-4)
        end
    end
    state._scrollSeen = scroll.scrollPos

    -- Stencil clip
    panel:setStencilRect(x, y, contentW, h)

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * math.max(0, totalH - h))
    end

    local curY = y - scrollOff
    local mx, my = panel:getMouseX(), panel:getMouseY()
    -- Suppress hover when a dropdown overlay is open
    if anyOpen(state) or cuesOn() then mx, my = -1, -1 end
    local rowIdx = 0

    -- Reusable row data table (zero alloc per row per frame)
    local rowData = { name = "", displayName = "", iconTex = nil, status = "can" }
    -- the recipe the controller has (the id after "<prefix>:row:"), else nil
    local rowOpts = { focus = nil }
    local focusedRow = nil
    do
        local fid = state._gpFocusedId
        local rp = ((config and config.prefix) or "jrecipe") .. ":row:"
        if fid and string.sub(fid, 1, #rp) == rp then focusedRow = string.sub(fid, #rp + 1) end
    end

    -- Visible area bounds for culling (stencil clips pixels but draw calls are expensive)
    local visTop = y
    local visBot = y + h

    -- The header and row zones are only a function of the list's layout, so
    -- the same zone tables are handed back frame after frame until the list
    -- scrolls, resizes or changes (a thousand rows would otherwise allocate a
    -- thousand tables a frame). Nothing downstream edits a stamped zone.
    local zc = state._rowZoneCache
    local zreuse = zc and zc.sections == sections and zc.x == x and zc.y0 == curY
        and zc.w == contentW and zc.rowH == ROW_H and zc.hdrH == catHdrH
        and zc.ro == (config.readOnly and true or false) or false
    local zlist = zreuse and zc.list or {}
    local zi = 0

    for _, sec in ipairs(sections) do
        -- Section header — always stamp zone (gamepad cone-nav targets off-
        -- screen disclosures; scroll-follow brings them into view). Draw only
        -- when within visible rect.
        -- (a lone group: no head, no head zone; see the audit note where the sections are built)
        if not sec.solo then
        local hdrVisible = curY + catHdrH > visTop and curY < visBot
        if hdrVisible then
            -- the list's group row ("v Pinned (3)": the library category row, 15u,
            -- sentence case), the controller's mark under its words when focused
            local headerHover = mx >= x and mx < x + contentW and my >= curY and my < curY + catHdrH
            local pfx = (config and config.prefix) or "jrecipe"
            local catOpts = state._catRowOpts or {}
            state._catRowOpts = catOpts
            catOpts.hover, catOpts.h, catOpts.inset = headerHover, catHdrH, T.px(6)
            catOpts.focus = (state._gpFocusedId == (pfx .. ":section:" .. tostring(sec.id))) and NO_FOCUS_OPTS or nil
            M.drawCategoryRow(panel, x, curY, contentW, ZeD.tr(sec.label), #sec.items, not sec.collapsed, catOpts)
        end
        zi = zi + 1
        local hz = zlist[zi]
        if not hz then
            hz = {
                type = "sectionHeader", id = sec.id,
                x = x, y = curY, w = contentW, h = catHdrH,
                _scrolled = true,
            }
            zlist[zi] = hz
        end
        zones[#zones + 1] = hz
        curY = curY + catHdrH
        end

        -- Rows: always stamp zones for cone-nav (scrolling past the viewport
        -- needs off-screen rows focusable so the D-pad cone has a target below
        -- the visible area; scroll-follow then brings it into
        -- view next frame). Draw only when within visible rect. The zone
        -- tables come from the cache above; a frame that makes them fresh (the
        -- list scrolled or changed) costs ~24 bytes/row × ~500 rows ≈ 12KB for
        -- the largest typical section, well within budget.
        if not sec.collapsed then
            for _, rd in ipairs(sec.items) do
                rowIdx = rowIdx + 1
                local name = rd.entry.name
                local visible = curY + ROW_H > visTop and curY < visBot
                if visible then
                    local isSelected = (state.selected == name)
                    local rowHover = mx >= x and mx < x + contentW and my >= curY and my < curY + ROW_H

                    local status = "can"
                    if rd.status == "missing" then status = "miss"
                    elseif rd.status == "locked" then status = "unknown"
                    elseif rd.status == "craftable" then status = "can"
                    elseif rd.status == "station" then status = "station"
                    elseif rd.status == "unlocked" then status = "miss" end

                    rowData.tag = rd.stationTag
                    rowData.name = name
                    rowData.displayName = rd.entry.displayName
                    rowData.iconTex = rd.entry.iconTex
                    rowData.status = status

                    local isPinned = pinSet[name] or false
                    local fc = freqCounts[name]

                    -- The row draws the controller's mark itself (under its words) when it is
                    -- the focused one. Off-screen rows skip it (zone stamped, no draw); next
                    -- frame's scroll-follow brings the row into view.
                    rowOpts.focus = (focusedRow ~= nil and focusedRow == tostring(name)) or nil

                    M.drawRecipeRow(panel, x, curY, contentW, rowData,
                        isSelected, rowHover, isPinned, fc, rowIdx, rowOpts)
                end

                -- Click zones (readOnly: full row, no star) — stamped UNCONDITIONALLY.
                zi = zi + 1
                local rz = zlist[zi]
                if not rz then
                    rz = {
                        type = "recipeRow", id = name,
                        x = x, y = curY, w = config.readOnly and contentW or (contentW - T.px(18)), h = ROW_H,
                        _scrolled = true,
                    }
                    zlist[zi] = rz
                end
                zones[#zones + 1] = rz
                if not config.readOnly then
                    zi = zi + 1
                    local sz = zlist[zi]
                    if not sz then
                        sz = {
                            type = "recipeStar", id = name,
                            x = x + contentW - T.px(18), y = curY, w = T.px(18), h = ROW_H,
                            _scrolled = true,
                        }
                        zlist[zi] = sz
                    end
                    zones[#zones + 1] = sz
                end
                curY = curY + ROW_H
            end
        end
    end

    -- An empty list says why, as the other empty lists do ("Nothing here."), under its "(0)" head:
    -- the search found nothing, or nothing is ready, or nothing to list. The search box and the band
    -- stay, being the way back to a full list.
    if #(state.filteredCache or {}) == 0 and (not state.allCollapsed or (sections[1] and sections[1].solo)) then
        M.drawEmptyLine(panel, x + T.px(6), curY + T.px(8), contentW - T.px(12), CC.emptyListText(state, config))
    end

    if not zreuse then
        state._rowZoneCache = {
            sections = sections, x = x, y0 = y - scrollOff, w = contentW, rowH = ROW_H,
            hdrH = catHdrH, ro = config.readOnly and true or false, list = zlist,
        }
    end

    panel:clearStencilRect()

    -- Draw scrollbar
    if needsScroll then
        scroll:draw(panel)
    end

    return h
end

-- ============================================================================
-- CHOSEN INGREDIENTS - which item type fills a slot (the craft uses it)
-- ============================================================================

-- An item type's display name (cached).
local _typeNames = {}
function CC.typeName(fullType)
    local n = _typeNames[fullType]
    if n then return n end
    n = fullType
    pcall(function()
        local script = ScriptManager.instance:getItem(fullType)
        if script and script:getDisplayName() then n = script:getDisplayName() end
    end)
    _typeNames[fullType] = n
    return n
end

-- The type picked for a slot of the recipe, or nil when the game chooses.
function CC.pickFor(state, recipeName, slotIdx)
    local p = state.picks and state.picks[recipeName]
    return p and p[slotIdx] or nil
end

-- Pick a type for a slot; picking the same type again clears it.
function CC.togglePick(state, recipeName, slotIdx, fullType)
    if not (recipeName and slotIdx and fullType) then return end
    state.picks = state.picks or {}
    local p = state.picks[recipeName]
    if not p then
        p = {}
        state.picks[recipeName] = p
    end
    if p[slotIdx] == fullType then p[slotIdx] = nil else p[slotIdx] = fullType end
end

-- A row of the open alternatives list that can be chosen: marks the chosen
-- one (the selected wash, no side bar), the pointer's hover, the controller's
-- mark when focused, and stamps its click zone. Called before the row draws, so
-- every wash sits under its words.
function CC.stampAltPick(panel, state, alt, x, y, w, rowH, viewY, viewH)
    local T = ZeD.T
    local ac = T.accent
    local picked = CC.pickFor(state, state.selected, state.altSlotIdx) == alt.fullType
    if picked then
        panel:drawRect(x, y, w, rowH, T.selectionA, ac.r, ac.g, ac.b)
    end
    local pmy = panel:getMouseY()
    if not anyOpen(state) and pmy >= viewY and pmy < viewY + viewH
        and ZeD.Atoms.mouseIn(panel, x, y, w, rowH) then
        local hv = T.hover
        panel:drawRect(x, y, w, rowH, hv.a, hv.r, hv.g, hv.b)
    end
    if state._gpFocusedId and state._gpFocusedId == ((state._pickPrefix or "craft") .. ":altPick:" .. tostring(alt.fullType)) then
        ZeD.Focus.mark(panel, x, y, w, rowH)
    end
    if y + rowH > viewY and y < viewY + viewH then
        local zones = state.zones
        zones[#zones + 1] = {
            type = "altPick", id = alt.fullType,
            x = x, y = y, w = w, h = rowH,
            _scrolled = true,
        }
    end
end

-- Kahlua has no next(); whether a table has any entry.
local function hasAny(t) for _ in pairs(t) do return true end return false end

-- Fill one item slot of the logic from the containers: only items of
-- fullType when given (anything the slot accepts otherwise), skipping the
-- items in skip.
local function fillPickSlot(logic, script, containers, fullType, skip)
    logic:setManualSelectInputScriptFilter(script)
    local data = logic:getRecipeData():getDataForInputScript(script)
    logic:clearManualInputsFor(data)
    for ci = 0, containers:size() - 1 do
        local items = containers:get(ci):getItems()
        for j = 0, items:size() - 1 do
            if data:isInputItemsSatisfied() then return end
            local it = items:get(j)
            if it and (not fullType or it:getFullType() == fullType) and not (skip and skip[it]) then
                logic:offerInputItem(it)
            end
        end
    end
end

-- Whether the slot currently holds an item from the set.
local function slotHoldsAny(logic, script, set)
    local list = logic:getManualInputsFor(script, ArrayList.new())
    for i = 0, list:size() - 1 do
        if set[list:get(i)] then return true end
    end
    return false
end

-- The craft action for a recipe whose ingredients were chosen. The chosen
-- types are offered to a handcraft logic in manual-select mode (as vanilla's
-- crafting window does when the player picks items) and the action is built
-- from it, so the game uses what was chosen. Returns nil when nothing was
-- chosen or the choice no longer covers the recipe (an item used up, moved
-- out of reach): the caller then stops the batch there (QA B6-15).
--
-- The slots the player did not choose for keep the items the game fills them
-- with (autoPopulateInputs, as vanilla's panel does), so the recipe stays
-- complete. Each chosen slot is filtered to its own input before its items
-- are offered, so a chosen type lands in that slot and nowhere else.
-- `used` (optional) is a set of items already promised to an earlier craft
-- of the same batch: they are skipped, and the items this craft takes are
-- added to it. Tools and kept items are not consumed, so they are never skipped.
-- `surface` (optional): an any-surface recipe's table in Hand mode (CC.craftSurface);
-- without it the game's check refuses every any-surface recipe. (beast W23)
-- Also returns the logic, for the input moves (CC.moveCraftInputs).
function CC.pickedCraftAction(playerObj, state, entry, bench, containers, used, surface)
    local picks = state.picks and entry and state.picks[entry.name]
    if not (picks and hasAny(picks) and entry.recipe and entry.inputDefs and containers) then return nil end
    local action, theLogic = nil, nil
    local ok = pcall(function()
        local logic = HandcraftLogic.new(playerObj, bench and bench.comp or nil, bench and bench.obj or surface or nil)
        logic:setContainers(containers)
        logic:setRecipe(entry.recipe)
        logic:setManualSelectInputs(true)
        logic:autoPopulateInputs()
        local defs = entry.inputDefs
        for idx = 1, #defs do
            local def = defs[idx]
            local script = def.inputRef
            if script and script:getResourceType() == ResourceType.Item then
                local skip = (used and not (def.isTool or def.isKeep)) and used or nil
                local fullType = picks[idx]
                if fullType then
                    fillPickSlot(logic, script, containers, fullType, skip)
                elseif skip and hasAny(skip) and slotHoldsAny(logic, script, skip) then
                    fillPickSlot(logic, script, containers, nil, skip)
                end
            end
        end
        logic:setManualSelectInputScriptFilter(nil)
        local canDo = logic:canPerformCurrentRecipe()
        -- A bound bench past the check's 3 tiles (ZeD keeps it bound out to its leash): the check
        -- fails on range alone. Judge it as CraftingTab.startCheck does, by what the recipe takes;
        -- the walk is queued before the craft, and the action asks the check again at its start,
        -- by then at the bench. (beast W23)
        local farBench = (not canDo) and bench and not logic:isCharacterInRangeOfWorkbench()
        if canDo or farBench then
            action = ISHandcraftAction.FromLogic(logic, 0)
            if farBench then
                if not (logic:getPossibleCraftCount(true) > 0) then action = nil end
                -- (asked again so the recipe's data holds the chosen items for the input moves)
                logic:canPerformCurrentRecipe()
            end
            if action and used then
                for idx = 1, #defs do
                    local def = defs[idx]
                    local script = def.inputRef
                    if script and not (def.isTool or def.isKeep) and script:getResourceType() == ResourceType.Item then
                        local list = logic:getManualInputsFor(script, ArrayList.new())
                        for i = 0, list:size() - 1 do used[list:get(i)] = true end
                    end
                end
            end
            if action then theLogic = logic end
        end
    end)
    if not (ok and action) then return nil end
    return action, theLogic
end

--- How many crafts the chosen ingredients cover, at most cap: the batch CC.startPickedCraft would
--- queue, worked out the same way (one craft after another, each skipping the items the ones before
--- it take). The game's Max counts only the chosen items (ISWidgetHandCraftControl: Max and the
--- amount box read getPossibleCraftCount with the player's own picks); the band offered the
--- automatic count, 5, then queued 3 with no word said (QA cb sweep, Nov 25 2026, C7).
--- nil when nothing is chosen for the recipe.
function CC.pickedCraftCount(playerObj, state, entry, bench, containers, surface, cap)
    local picks = state and state.picks and entry and state.picks[entry.name]
    if not (picks and hasAny(picks)) then return nil end
    local used, n = {}, 0
    for i = 1, math.max(1, cap or 1) do
        if not CC.pickedCraftAction(playerObj, state, entry, bench, containers, used, surface) then break end
        n = i
    end
    return n
end

-- The names (and the game's item scripts) of a recipe's mapped outputs for what is in reach, as
-- vanilla's craft window names them in manual select (ISWidgetOutput:updateValues): a logic in
-- manual select fills its slots from the containers (autoPopulateInputs, as vanilla's panel does),
-- the card's picked types go in their slots, then each output's mapper is asked for the result of
-- those inputs (getOutputMapper():getOutputItem(the recipe data, true)). A pot of soup gives Bowl
-- of Soup and the Cooking Pot back; a saucepan of rice, Bowl of Rice and the Saucepan.
-- Returns two tables by output index (nil where the game gave nothing: the card keeps the def's
-- first-result name), or nil, nil when the game would not answer. picks: the card's
-- { [slotIdx] = full type } or nil. (QA B11-1)
function CC.resolveMappedOutputs(playerObj, entry, picks, containers)
    if not (playerObj and entry and entry.recipe and entry.outputDefs and containers) then return nil, nil end
    local names, items = {}, {}
    local ok = pcall(function()
        local logic = HandcraftLogic.new(playerObj, nil, nil)
        logic:setContainers(containers)
        logic:setRecipe(entry.recipe)
        logic:setManualSelectInputs(true)
        logic:autoPopulateInputs()
        if picks then
            local defs = entry.inputDefs or {}
            for idx = 1, #defs do
                local script = defs[idx].inputRef
                if picks[idx] and script and script:getResourceType() == ResourceType.Item then
                    fillPickSlot(logic, script, containers, picks[idx], nil)
                end
            end
            logic:setManualSelectInputScriptFilter(nil)
        end
        -- Each mapped output asked of the recipe's data as it now stands
        local function ask()
            local data = logic:getRecipeData()
            local any = false
            for i, od in ipairs(entry.outputDefs) do
                if od.mapped and od.outputRef and not items[i] then
                    local okI, it = pcall(function() return od.outputRef:getOutputMapper():getOutputItem(data, true) end)
                    if okI and it then
                        items[i] = it
                        local okN, nm = pcall(function() return it:getDisplayName() end)
                        if okN and nm then names[i] = nm end
                    end
                end
                if od.mapped and not items[i] then any = true end
            end
            return any
        end
        -- (nothing named from the slots: asked again the way the game fills them for its own check,
        -- canPerformCurrentRecipe out of manual select, as QA's in-game proof asked it)
        if ask() then
            logic:setManualSelectInputs(false)
            logic:canPerformCurrentRecipe()
            ask()
        end
    end)
    if not ok then return nil, nil end
    return names, items
end

-- Queue the crafts for the selected recipe when the player chose ingredients,
-- one action per craft of the batch. Returns true when it handled the click
-- (even if a bench check declined it, as the usual start does) and false when
-- the usual automatic start should run instead: nothing chosen, or not at a
-- bench the recipe needs. Chosen items are never swapped for the game's picks:
-- the batch stops at the crafts they cover (as vanilla's craft window caps its
-- count to the chosen items), and when they cover none nothing is queued and
-- the character says what is missing. (QA B6-15)
function CC.startPickedCraft(win, state)
    local playerObj = win._playerObj
    local name = state.selected
    local entry = state._selEntry
    local picks = state.picks and name and state.picks[name]
    if not (playerObj and entry and entry.name == name and entry.recipe and picks and hasAny(picks)) then return false end
    -- a craft ZeD queued is still waiting or running: the press is taken and nothing is queued, as
    -- the usual start refuses it (QA cb sweep, Nov 25 2026, C1)
    if CC.craftBusy(win, playerObj) then return true end

    -- at a bench: still bound and carrying this recipe, as the usual start checks
    local bench = nil
    if ZeD.Stations then
        local st = ZeD.Stations.validate(playerObj)
        if st and st.kind == "bench" then bench = st end
    end
    if entry.stationInfo and not bench then return false end
    if bench and not ZeD.Stations.recipeSet(bench)[entry.recipe:getName()] then return false end

    local containers = CC.craftContainers(playerObj)  -- (beast W25)
    -- an any-surface recipe in Hand mode is made on a table, as the usual start does (beast W23)
    local surface = CC.craftSurface(playerObj, entry, bench)
    local actions = {}
    local logics = {}
    local used = {}
    for i = 1, (state.qty or 1) do
        local a, l = CC.pickedCraftAction(playerObj, state, entry, bench, containers, used, surface)
        if not a then break end   -- (the chosen items cover no more crafts: the batch stops here)
        actions[i] = a
        logics[i] = l
    end
    if #actions == 0 then
        -- (not even one craft: refuse, with vanilla's own words, rather than craft from other items)
        if HaloTextHelper and HaloTextHelper.addBadText then
            pcall(HaloTextHelper.addBadText, playerObj, getText("IGUI_CraftingWindow_Error_Inputs"))
        end
        return true
    end

    -- inputs off the floor or out of a crate move into the inventory first, as vanilla's craft
    -- window moves them (before its walk); the kept ones go back after the crafts (beast W25)
    local back, moved, all = {}, {}, {}
    for i = 1, #logics do
        if logics[i] then
            local b, a = CC.moveCraftInputs(playerObj, logics[i], moved)
            for _, it in ipairs(b) do back[#back + 1] = it end
            for _, it in ipairs(a) do all[#all + 1] = it end
        end
    end

    -- walk to the bench, or to the any-surface recipe's table (beast W23). No way there: nothing is
    -- queued and every input moved above goes back (QA cb sweep, Nov 25 2026, C9)
    local at = bench and bench.obj or surface
    if at and ISEntityUI and ISEntityUI.WalkToEntity and not ISEntityUI.WalkToEntity(playerObj, at) then
        CC.returnCraftInputs(playerObj, all)
        return true
    end
    local queued = {}
    pcall(function()
        for i = 1, #actions do
            -- (counted when each craft starts, not at the press: C19)
            CC.prepCraftAction(actions[i], playerObj, name, state._countKey or "ZeD_CraftCounts")
            ISTimedActionQueue.add(actions[i])
            queued[#queued + 1] = actions[i]
        end
    end)
    CC.returnCraftInputs(playerObj, back)
    CC.trackCraftActions(win, queued)   -- (Craft stays gray while they are queued: C1)

    state.qty = 1
    state.filterDirty = true
    -- (the Craft tab's caches, as its startCraft clears them: 90 = CONTAINER_INTERVAL,
    -- so the next frame gathers the containers again)
    win._craftCache = nil
    win["_craftContainerAt"] = nil
    win["_craftTypeCache"] = nil
    return true
end

-- Start the craft or build for the selected recipe: the chosen ingredients
-- when there are any, else the tab's own automatic start.
function CC.runStart(win, state, startAction)
    if state._pickOn and CC.startPickedCraft(win, state) then return end
    if startAction then startAction(win, state) end
end

-- ============================================================================
-- RENDERING — Alt List (when a slot with alternatives is selected)
-- ============================================================================

function CC.renderAltList(panel, x, y, w, h, state)
    local T     = ZeD.T
    local tm    = ZeD.TM
    local scroll = state.altScroll
    local ROW_H = T.px(CC.ROW_H)

    local altData = state.altItems
    if not altData then return h end

    -- Filter by alt search
    local searchQ = string.lower(state.altSearch or "")
    local owned = altData.owned or {}
    local other = altData.other or {}

    if #searchQ > 0 then
        local fo, ff = {}, {}
        for _, alt in ipairs(owned) do
            if string.find(string.lower(alt.displayName), searchQ, 1, true) then
                fo[#fo + 1] = alt
            end
        end
        for _, alt in ipairs(other) do
            if string.find(string.lower(alt.displayName), searchQ, 1, true) then
                ff[#ff + 1] = alt
            end
        end
        owned = fo
        other = ff
    end

    -- Hide "Other" section if ownedOnly
    if state.ownedOnly then other = {} end

    -- Measure total content (headers use catHdrH, rows use ROW_H)
    local hdrH = T.sp.catHdrH
    local totalH = 0
    if #owned > 0 then
        totalH = totalH + hdrH + #owned * ROW_H
    end
    if #other > 0 then
        totalH = totalH + hdrH + #other * ROW_H
    end
    if totalH == 0 then
        totalH = ROW_H  -- empty state
    end

    -- Scrollbar
    local scrollW = T.sp.scrollbarW
    local needsScroll = totalH > h
    scroll.visible = needsScroll
    local contentW = needsScroll and (w - scrollW) or w
    if needsScroll then
        scroll.x = x + w - scrollW
        scroll.y = y
        scroll.height = h
        scroll:setBarSize(h / totalH)
    else
        scroll:setScrollPos(0)
    end

    panel:setStencilRect(x, y, contentW, h)

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * math.max(0, totalH - h))
    end

    local curY = y - scrollOff
    local rowIdx = 0

    local catHdrH = T.sp.catHdrH

    -- the two groups are the list's category rows (they do not fold: no triangle)
    local grpOpts = state._altGrpOpts or {}
    state._altGrpOpts = grpOpts
    grpOpts.noArrow, grpOpts.h, grpOpts.inset = true, catHdrH, T.px(6)

    -- Owned section
    if #owned > 0 then
        M.drawCategoryRow(panel, x, curY, contentW, ZeD.tr("UI_ZeD_Craft_AltOwned"), #owned, true, grpOpts)
        curY = curY + catHdrH

        for _, alt in ipairs(owned) do
            rowIdx = rowIdx + 1
            -- the chosen mark and the controller's mark first, under the row's words
            if state._pickOn then CC.stampAltPick(panel, state, alt, x, curY, contentW, ROW_H, y, h) end
            M.drawAltRow(panel, x, curY, contentW, alt, true, rowIdx)
            curY = curY + ROW_H
        end
    end

    -- Other section
    if #other > 0 then
        M.drawCategoryRow(panel, x, curY, contentW, ZeD.tr("UI_ZeD_Craft_AltOther"), #other, true, grpOpts)
        curY = curY + catHdrH

        for _, alt in ipairs(other) do
            rowIdx = rowIdx + 1
            M.drawAltRow(panel, x, curY, contentW, alt, false, rowIdx)
            curY = curY + ROW_H
        end
    end

    -- Empty state: the library's empty line at the list's text inset
    if #owned == 0 and #other == 0 then
        M.drawEmptyLine(panel, x + T.px(6), curY + T.px(8), contentW - T.px(12), ZeD.tr("UI_ZeD_Craft_NoAlts"))
    end

    panel:clearStencilRect()

    if needsScroll then
        scroll:draw(panel)
    end

    return h
end

-- ============================================================================
-- RENDERING — Craft Card (the right pane, PANE_W_SPLIT = 240u when open)
-- ============================================================================

-- Which input the game says is short when every row reads green but the recipe still will not start
-- (a spool with too few uses, a drainable the whole-item count passes): the game's own recipe data is
-- asked per input, as fillPickSlot reads it. Returns the 1-based index into entry.inputDefs, or nil when
-- every input is satisfied (or the game would not answer). Asked at most once a second per recipe. (QA K1-7)
function CC.shortInputIdx(playerObj, entry)
    if not (playerObj and entry and entry.recipe and entry.inputDefs and HandcraftLogic) then return nil end
    local now = getTimestampMs and getTimestampMs() or 0
    if entry._shortAt and now - entry._shortAt < 1000 then return entry._shortIdx end
    entry._shortAt, entry._shortIdx = now, nil
    pcall(function()
        local logic = HandcraftLogic.new(playerObj, nil, nil)
        logic:setContainers(CC.craftContainers(playerObj))
        logic:setRecipe(entry.recipe)
        logic:setManualSelectInputs(true)
        logic:autoPopulateInputs()
        local rdata = logic:getRecipeData()
        for idx, def in ipairs(entry.inputDefs) do
            local script = def.inputRef
            if script and script:getResourceType() == ResourceType.Item then
                local data = rdata:getDataForInputScript(script)
                if data and not data:isInputItemsSatisfied() then
                    entry._shortIdx = idx
                    return
                end
            end
        end
    end)
    return entry._shortIdx
end

function CC.renderCraftCard(panel, x, y, w, h, state, config, rd, playerObj)
    local T     = ZeD.T
    local A     = ZeD.Atoms
    local tm    = ZeD.TM
    local zones = state.zones
    local scroll = state.cardScroll
    local ROW_H = T.px(CC.ROW_H)

    if not rd then return h end

    local entry = rd.entry

    -- Measure total card content height
    local headerH = T.px(60)  -- icon + name + description estimate
    local chipH = T.px(22)
    local inputsH = ROW_H + #(rd.ingredients or {}) * ROW_H  -- header + rows
    local outputsH = CC.outputsRepeatTitle(entry) and 0 or (ROW_H + #(entry.outputDefs or {}) * ROW_H)
    local actionH = 0   -- (the amount and Craft / Build live in the card's band, CC.renderBand)
    -- Learn info section height (readOnly + not accessible)
    local showLearnSection = config.readOnly and (not rd.learned or rd.hasSkill == false)
    local learnH = 0
    if showLearnSection then
        learnH = ROW_H + #(rd.skills or {}) * ROW_H + T.px(8)
    end
    -- Hand mode, station recipe: "Needs a Primitive Kiln" box with a USE button
    local stNeed = (not config.readOnly) and rd.stationNeed or nil
    local stNear = nil
    if stNeed and ZeD.Stations and playerObj then
        stNear = ZeD.Stations.nearestFor(playerObj, entry.name)
    end
    -- the NEEDS line (it may wrap), the nearest one in reach, and Use <station>
    local needH = 0
    local needText = stNeed and ZeD.Stations and ZeD.Stations.needsText(stNeed.label) or nil
    if stNeed then
        local lineW = w - T.sp.scrollbarW - T.px(20) - T.px(12)
        local n = needText and #A.wrapText(needText, T.fontF2, math.max(1, lineW)) or 1
        local step = T.fontF2H + T.px(2)
        needH = T.px(4) + math.max(1, n) * step + T.fontF2H
        if stNear then needH = needH + T.px(6) + T.buttonH end
        needH = needH + T.px(8)
    end
    -- (QA's bug B12, Nov 20 2026: "Required (2/2)" with Craft dimmed was a riddle. Every item is here yet the
    -- recipe cannot start: it wants a workbench or station. One short dim line under the items says so.)
    local stuck = (not config.readOnly) and (not stNeed) and #(rd.ingredients or {}) > 0
        and (rd.missingCount or 0) == 0 and (rd.status == "missing" or rd.status == "station")
    -- (QA K1-7) Every row green yet the game says no: ask the game which input is short and mark that row
    -- red; failing that, word the line by cause: a table for an any-surface recipe, a bench for a bench recipe
    local shortIdx, lineText = nil, nil
    if stuck then
        shortIdx = CC.shortInputIdx(playerObj, entry)
        if not shortIdx then
            local bench = nil
            if ZeD.Stations and playerObj then
                local st = ZeD.Stations.validate(playerObj)
                if st and st.kind == "bench" then bench = st end
            end
            if entry.needSurface and not bench and not CC.craftSurface(playerObj, entry, bench) then
                lineText = ZeD.tr("UI_ZeD_Craft_NeedsSurface")
                -- (until the key is in UI.json the plain words stand in)
                if lineText == "UI_ZeD_Craft_NeedsSurface" then lineText = "Needs a table or counter nearby." end
            elseif rd.status == "station" or entry.stationInfo then
                lineText = ZeD.tr("UI_ZeD_Craft_NeedsBench")
            end
        end
    end
    local benchLine = lineText ~= nil
    local benchH = benchLine and (T.fontF2H + T.px(4)) or 0
    local totalH = headerH + chipH + T.px(4) + needH + inputsH + benchH + T.px(4) + outputsH + learnH + actionH

    -- Scrollbar (for very long ingredient lists)
    local scrollW = T.sp.scrollbarW
    local availH = h - actionH  -- (actionH is 0: the band below the card holds the actions)
    local needsScroll = (totalH - actionH) > availH
    scroll.visible = needsScroll
    local contentW = needsScroll and (w - scrollW) or w
    if needsScroll then
        scroll.x = x + w - scrollW
        scroll.y = y
        scroll.height = availH
        scroll:setBarSize(availH / (totalH - actionH))
    else
        scroll:setScrollPos(0)
    end

    -- Stencil for the scrollable area
    panel:setStencilRect(x, y, contentW, availH)

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * math.max(0, (totalH - actionH) - availH))
    end

    local curY = y - scrollOff

    -- Header block: icon + name + description
    local iconSz = T.px(36)
    local iconX = x + T.px(6)
    local iconY = curY + T.px(6)
    local s3 = T.surf3
    panel:drawRect(iconX, iconY, iconSz, iconSz, s3.a, s3.r, s3.g, s3.b)
    panel:drawRectBorder(iconX, iconY, iconSz, iconSz, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    if entry.iconTex then
        panel:drawTextureScaledAspect(entry.iconTex, iconX + T.px(2), iconY + T.px(2), iconSz - 2 * T.px(2), iconSz - 2 * T.px(2), 1, 1, 1, 1)
    end
    -- the preview: the icon is a click and a controller stop that opens the recipe's card
    state._rdLast = rd
    do
        local fid = tostring(config and config.prefix or "craft") .. ":icon"
        if ZeD.Atoms.mouseIn(panel, iconX, iconY, iconSz, iconSz) then
            local hv = T.hover
            panel:drawRect(iconX, iconY, iconSz, iconSz, hv.a or 1, hv.r, hv.g, hv.b)
            ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Preview_HelpIcon"))
        end
        if state._gpFocusedId == fid and ZeD.Focus and ZeD.Focus.mark then ZeD.Focus.mark(panel, iconX, iconY, iconSz, iconSz) end
        state.zones[#state.zones + 1] = { type = "detailIcon", x = iconX, y = iconY, w = iconSz, h = iconSz }
    end

    -- Name (F2 13px, heading ink)
    local nameX = iconX + iconSz + T.px(6)
    local nameFont = T.fontF2
    local nameStr = CC.truncText(entry.displayName, nameFont, contentW - (nameX - x) - T.px(6))
    local hc = T.textHead
    panel:drawText(nameStr, nameX, curY + T.px(6), hc.r, hc.g, hc.b, hc.a or 1, nameFont)

    -- Description (pre-baked during catalog build), one line: the game's text can break a line (the
    -- Advanced Forge's drew as two, split at its <br>), and the second line ran into the Required rows
    if entry.description then
        local descStr = CC.truncText(CC.oneLine(entry), T.fontF5, contentW - (nameX - x) - T.px(6))
        local descY = curY + T.px(6) + tm:getFontHeight(nameFont) + T.px(2)
        panel:drawText(descStr, nameX, descY, T.textSec.r, T.textSec.g, T.textSec.b, T.textSec.a, T.fontF5)
    end

    curY = curY + headerH

    -- Chip row: KNOWN/UNKNOWN, SURFACE, the craft time, the station chip
    local chipX = x + T.px(6)
    -- In readOnly (Journal), show accessibility: learned AND has skill
    local isAccessible = rd.learned and (rd.hasSkill ~= false)
    -- (QA's visual noise audit 30, Nov 20 2026: "Known" sat on every known recipe; only "not known" is news)
    local bw
    if not isAccessible then
        bw = A.drawBadge(panel, ZeD.tr("UI_ZeD_Craft_BadgeUnknown"), chipX, curY, "danger")
        chipX = chipX + bw + T.px(4)
    end

    -- No amber Surface square: a table's recipe reads like any other, and the line under the rows
    -- ("Needs a table or counter nearby.") speaks only when none is near (KISS #35)

    -- Craft time (getTime returns seconds)
    if rd.craftTime and rd.craftTime > 0 then
        local t = rd.craftTime
        local timeStr
        if t >= 60 then
            timeStr = ZeD.tr("UI_ZeD_Craft_TimeMinSec", math.floor(t / 60), math.floor(t % 60))
        else
            timeStr = ZeD.tr("UI_ZeD_Craft_TimeSec", math.floor(t))
        end
        bw = A.drawBadge(panel, timeStr, chipX, curY, "accent", nil, nil, true)
        chipX = chipX + bw + T.px(4)
    end

    -- Station chip: where it is made (a station recipe in Hand mode says so in its NEEDS line below)
    if (not stNeed) and rd.boundShort then
        A.drawBadge(panel, rd.boundShort, chipX, curY, nil)
    end

    curY = curY + chipH + T.px(4)

    -- NEEDS: a hollow square and "Needs a Primitive Kiln." in F2,
    -- the nearest one in reach under it, then the push button that goes to it
    if stNeed then
        local bx, bw2 = x + T.px(10), contentW - T.px(20)
        local ty = curY + T.px(4)
        ty = ty + M.drawNeedsLine(panel, bx, ty, bw2, needText or "") + T.px(2)
        local tx = bx + T.px(12)   -- the needs line's text inset (the 6u square and its gap)
        local line2 = stNear and ZeD.Stations.nearestText(stNear.dist)
            or ZeD.tr("UI_ZeD_Craft_NoneWithin", ZeD.Stations.REACH)
        local dc = T.textDim
        panel:drawText(CC.truncText(line2, T.fontF2, bw2 - T.px(12)), tx, ty, dc.r, dc.g, dc.b, dc.a or 1, T.fontF2)
        ty = ty + T.fontF2H
        if stNear then
            ty = ty + T.px(6)
            local label = ZeD.tr("UI_ZeD_Craft_UseStation", string.lower(stNear.name or ZeD.tr("UI_ZeD_Station_Fallback")))   -- a button: sentence case
            local btnH = T.buttonH
            local btnW = math.min(bw2 - T.px(12), M.buttonW(label))
            local pfx = (config and config.prefix) or "jrecipe"
            M.drawButton(panel, tx, ty, btnW, btnH, label, "primary", false, nil,
                { hover = A.mouseIn(panel, tx, ty, btnW, btnH), focus = (state._gpFocusedId == (pfx .. ":stUse")) or nil })
            zones[#zones + 1] = { type = "stationUse", station = stNear,
                x = tx, y = ty, w = btnW, h = btnH, _scrolled = true }
        end
        curY = curY + needH
    end

    -- the card's section heads: the library's (20u, sentence case, the count dim)
    local catHdrH = T.px(20)
    local mx, my = panel:getMouseX(), panel:getMouseY()   -- hoisted above the HOW TO LEARN hover test, which reads them (undeclared, they would read as nil globals)
    if cuesOn() then mx, my = -1, -1 end
    local pfx = (config and config.prefix) or "jrecipe"

    -- Learn info section (readOnly + not accessible — renders ABOVE required; it does not fold)
    if showLearnSection then
        local learnLabel = ZeD.tr("UI_ZeD_Craft_HowToLearn")
        local lo = state._cardLearnOpts or {}
        state._cardLearnOpts = lo
        lo.noArrow, lo.bleedLeft, lo.h, lo.inset = true, T.px(6), catHdrH, 0
        M.drawCategoryRow(panel, x + T.px(6), curY, contentW - T.px(6), learnLabel, nil, true, lo)
        curY = curY + catHdrH

        -- Skill requirements: the status square carries met / not met, the words stay default
        if rd.skills and #rd.skills > 0 then
            for _, sk in ipairs(rd.skills) do
                -- (the text-safe status colors, as the balloons' checks and crosses: 4.5 : 1 in every theme)
                local skColor = sk.met and (T.positiveText or T.positive) or (T.dangerText or T.danger)
                local dotSz = T.px(6)
                A.drawStatusDot(panel, x + T.px(6), curY + math.floor((ROW_H - dotSz) / 2), skColor, dotSz)
                local skStr = ZeD.tr("UI_ZeD_Craft_SkillLevel", sk.name, sk.required)
                panel:drawText(skStr, x + T.px(6) + dotSz + T.px(4),
                    curY + math.floor((ROW_H - tm:getFontHeight(T.fontF2)) / 2),
                    T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
                -- Player level right-aligned
                local lvlStr = tostring(sk.playerLevel) .. "/" .. tostring(sk.required)
                A.drawTextRight(panel, lvlStr, x + contentW - T.px(6),
                    curY + math.floor((ROW_H - tm:getFontHeight(T.fontF3)) / 2),
                    T.fontF3, T.text)
                curY = curY + ROW_H
            end
        end

        -- needToBeLearn hint (prose: F2 in the dim ink)
        if entry.needLearn then
            -- (Vanilla Access, or Hidden facts on Always: the magazine that teaches it, by name; ZeD_HiddenFacts)
            local hintStr = (ZeD.Finds and ZeD.Finds.recipeSourceText and ZeD.Finds.recipeSourceText(entry.name))
                or ZeD.tr("UI_ZeD_Craft_FindRecipe")
            local dc = T.textDim
            panel:drawText(CC.truncText(hintStr, T.fontF2, contentW - T.px(12)), x + T.px(6),
                curY + math.floor((ROW_H - tm:getFontHeight(T.fontF2)) / 2),
                dc.r, dc.g, dc.b, dc.a or 1, T.fontF2)
            curY = curY + ROW_H
        end

        curY = curY + T.px(4)
    end

    -- Required Items section (folds; the controller's mark under its words when focused)
    local reqCount = #(rd.ingredients or {})
    local haveCount = reqCount - (rd.missingCount or 0)
    local secLabel = ZeD.tr("UI_ZeD_Craft_Required")
    local reqHdrHover = mx >= x and mx < x + contentW and my >= curY and my < curY + catHdrH
    local secOpts = state._cardSecOpts or {}
    state._cardSecOpts = secOpts
    -- (the one section heading, the small fold-open mono line: design review D6)
    secOpts.focus = (state._gpFocusedId == (pfx .. ":card:req")) and NO_FOCUS_OPTS or nil
    secOpts.hover, secOpts.bleedLeft, secOpts.h, secOpts.inset, secOpts.noArrow = reqHdrHover, T.px(6), catHdrH, 0, nil
    M.drawCategoryRow(panel, x + T.px(6), curY, contentW - T.px(6), secLabel,
        haveCount .. "/" .. reqCount, not state.reqCollapsed, secOpts)
    zones[#zones + 1] = {
        type = "cardSection", id = "req",
        x = x, y = curY, w = contentW, h = catHdrH, _scrolled = true,
    }
    curY = curY + catHdrH

    -- Slot rows (hidden when collapsed)
    if not state.reqCollapsed then
        for idx, ing in ipairs(rd.ingredients or {}) do
            local chosen = state._pickOn and CC.pickFor(state, state.selected, idx) or nil
            local slotData = {
                name = ing.name,
                displayName = chosen and (ing.name .. ": " .. CC.typeName(chosen)) or ing.name,
                iconTex = ing.iconTex,
                have = (shortIdx == idx) and 0 or ing.have, -- the input the game says is short reads red (QA K1-7)
                need = ing.need,
                altCount = ing.altCount,
                tag = CC.tagText(ing.tag, ing.altCount),
                isTool = ing.isTool,
                isKeep = ing.isKeep,
            }
            local isSlotSelected = (state.altSlotName == ing.name and state.altSlotIdx == idx)
            local slotHover = mx >= x and mx < x + contentW and my >= curY and my < curY + ROW_H
            -- the controller's mark on a slot that opens its alternatives, under the row's words
            if (ing.altCount or 0) > 0 and state._gpFocusedId == (pfx .. ":slotAlt:" .. tostring(ing.name)) then
                ZeD.Focus.mark(panel, x, curY, contentW, ROW_H)
            end

            M.drawSlotRow(panel, x, curY, contentW, slotData, isSlotSelected, slotHover)

            -- Click zone for slots with alts
            if (ing.altCount or 0) > 0 then
                zones[#zones + 1] = {
                    type = "slotAlt", id = ing.name, idx = idx,
                    x = x, y = curY, w = contentW, h = ROW_H,
                    _scrolled = true,
                    inputDef = ing,
                }
            end

            curY = curY + ROW_H
        end
    end
    if benchLine then
        local dc = T.textDim
        panel:drawText(CC.truncText(lineText, T.fontF2, contentW - T.px(12)),
            x + T.px(6), curY + T.px(2), dc.r, dc.g, dc.b, dc.a or 1, T.fontF2)
        curY = curY + benchH
    end

    -- Outputs section (folds; the same 20u section head as Required)
    -- (QA's visual noise audit 30, Nov 20 2026: "Outputs (1)" headed one line that repeated the recipe's title;
    -- hidden when the one output is the thing the title names)
    curY = curY + T.px(4)
    local outCount = #(entry.outputDefs or {})
    if outCount > 0 and not CC.outputsRepeatTitle(entry) then
        local outHdrHover = mx >= x and mx < x + contentW and my >= curY and my < curY + catHdrH
        secOpts.focus = (state._gpFocusedId == (pfx .. ":card:out")) and NO_FOCUS_OPTS or nil
        secOpts.hover, secOpts.bleedLeft, secOpts.h, secOpts.inset, secOpts.noArrow = outHdrHover, T.px(6), catHdrH, 0, nil
        M.drawCategoryRow(panel, x + T.px(6), curY, contentW - T.px(6), ZeD.tr("IGUI_CraftingWindow_Creates"),
            outCount, not state.outCollapsed, secOpts)
        zones[#zones + 1] = {
            type = "cardSection", id = "out",
            x = x, y = curY, w = contentW, h = catHdrH, _scrolled = true,
        }
        curY = curY + catHdrH

        if not state.outCollapsed then
            local outNames = rd.outNames   -- (a mapped output's name for what is in reach: QA B11-1)
            for oi, outDef in ipairs(entry.outputDefs) do
                local nm = (outNames and outNames[oi]) or outDef.name
                local outData = {
                    name = nm,
                    displayName = nm,
                    iconTex = nil,
                    have = outDef.amount or 1,  -- the yield of one craft (QA B10-2)
                    need = outDef.amount or 1,
                    altCount = 0,
                    isKeep = true,
                }
                M.drawSlotRow(panel, x, curY, contentW, outData, false, false)
                curY = curY + ROW_H
            end
        end
    end

    panel:clearStencilRect()

    -- Scrollbar
    if needsScroll then
        scroll:draw(panel)
    end

    return h
end

-- ============================================================================
-- MAIN ORCHESTRATOR — renders the full drawer layout (DRAWER_W = 480u)
-- Called by CraftingTab, BuildingTab and JournalTab's render.
-- ============================================================================

--- One frame of a recipe tab. state: the tab's (CC.createState); config: the
--- tab's own (prefix, keys, labels, startAction, readOnly, stations); data: the
--- tab's recipes this frame ({ recipes, categories, flatRecipes }).
function CC.render(panel, win, x, y, w, h, state, config, data)
    state.config = config   -- (the preview card reads the tab's prefix, label and start action from it)
    -- an open card is on screen this frame: Escape may close it (CC.takeEscape) (KISS #47)
    if state.selected then
        state._cardDrawnAt = getTimestampMs()
        if not CC._cardStates[state] then CC.pruneCardStates(state._cardDrawnAt) end   -- (only when one is added)
        CC._cardStates[state] = true
    end
    local T = ZeD.T

    -- Load pins on first render (skip in readOnly — no pin system)
    if not config.readOnly then
        if not state.pinsLoaded then
            state.pinsLoaded = true
            CC.loadPins(win, config.pinKey, "_" .. config.prefix .. "Pins")
            state.pins = win["_" .. config.prefix .. "Pins"] or {}
        end
        -- The game's favourites join the Craft tab's pins: at once, then every 2 s (a star set in the
        -- game's own window, the item menu). (QA cb sweep, Nov 25 2026, C18)
        if CC.GAME_FAV_PINS[config.pinKey or ""] and CC.due(win, "_" .. config.prefix .. "FavAt", 2000) then
            if CC.mergeGameFavourites(win, config.pinKey, "_" .. config.prefix .. "Pins", data and data.flatRecipes) then
                state.filterDirty = true
            end
        end
        -- Sync pins from win state
        state.pins = win["_" .. config.prefix .. "Pins"] or {}
    else
        state.pins = {}
    end

    -- Store category list for dropdown cycling
    state.categoryList = data.categories or {}

    -- the controller's scroll-follow: last frame's zones, kept BEFORE clearing.
    -- The delta gate keys on the focused id; the lookup runs against last-frame
    -- positions since this frame's are not stamped yet.
    local lastZones = state.zones

    -- the win ref on state lets helpers (the dropdown overlay) resolve the
    -- live focused ring element without a signature change
    state._focusWin = win
    -- choosing ingredients is offered only where the craft is built from the
    -- choice: the Craft tab (handcraft logic), unless a config says otherwise
    -- with pickIngredients
    local pickOn = config.pickIngredients
    if pickOn == nil then pickOn = (config.prefix == "craft") end
    state._pickOn = (pickOn and not config.readOnly) and true or false
    state._pickPrefix = config.prefix
    state._countKey = config.countKey

    -- the focused ring element id, resolved once per frame and stashed on
    -- state so each render function paints its cue inline at zone-stamp time.
    -- A post-render cue pass is unreliable (stencil state at end-of-render can
    -- obscure the accent overlay); inline paint puts the cue in the right
    -- paint-order position.
    -- Only while the mark may show (Focus.liveZone: this window has the focus and
    -- the controller is in use), so the other window or the mouse never keeps a
    -- row lit.
    state._gpFocusedId = nil
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if Focus and Focus.liveZone and Focus.liveElement then
            local fz = Focus.liveZone(win)
            -- either window's tab-content zone counts: this same pipeline
            -- serves the World window (Craft, Build) and the Character window
            -- (the Journal's Recipes page), so the cue paint must pick up the
            -- focused element id whichever window owns it
            if fz and (fz.zone == "charTabContent" or fz.zone == "worldTabContent") then
                local fe = Focus.liveElement(win)
                state._gpFocusedId = fe and fe.id or nil
            end
        end
    end

    -- Reset click zones each frame
    state.zones = {}

    -- Filter + sort (cached — only rebuild when dirty); the card follows the list
    -- (QA B10-4) The open recipe's row keeps its place on screen across the re-sort: note its offset from the
    -- list's top (last frame's zone, still holding the old position) and renderRecipeList scrolls to restore it.
    -- Skipped when something else moved the scroll since the last draw (a wheel turn, a filter pick resetting it).
    state._holdRow = nil
    if state.filterDirty and state.selected and lastZones and state._listGeo and state.scroll
       and state._scrollSeen == state.scroll.scrollPos then
        for _, z in ipairs(lastZones) do
            if z.type == "recipeRow" and tostring(z.id) == tostring(state.selected) then
                state._holdRow = { id = state.selected, rel = z.y - state._listGeo.viewY }
                break
            end
        end
    end
    if state.filterDirty then CC.refilter(data, state, config, win) end

    -- Update split animation (real dt via getTimestampMs inside)
    CC.updateSplitAnimation(state)

    local curY = y

    -- The header strip (Category and the search; crafting adds the station select).
    -- The read-only list (the Journal's Recipes page) sits under the Journal's own
    -- header, which holds its search; its Category select is in the band.
    if not config.readOnly then
        curY = curY + CC.renderStaticHeader(panel, x, curY, w, state, config, win)
    end

    -- Station band (Craft tab bound to a bench)
    if config.stations and ZeD.Stations and win._playerObj then
        local cur = ZeD.Stations.current(win._playerObj)
        if cur then
            curY = curY + ZeD.Stations.drawBand(panel, x, curY, w, cur, win._playerObj)
        end
    end

    -- The alternatives list's strip (alt mode only)
    curY = curY + CC.renderStrip(panel, x, curY, w, state, config)

    -- The band at the card's foot; the panes take the height between
    local bandH = M.bandH()
    local panesH = h - (curY - y) - bandH

    -- The picked recipe: the card shows it, the band's amount and Craft / Build act on it
    -- (Craft and Build keep a name index, data.byName; the Journal's list is searched)
    local selRd = nil
    if state.selected then
        if data.byName then
            selRd = data.byName[state.selected]
        else
            for _, rd in ipairs(data.recipes) do
                if rd.entry.name == state.selected then
                    selRd = rd
                    break
                end
            end
        end
    end
    state._selEntry = selRd and selRd.entry or nil

    -- Pane split based on animation fraction
    local splitFrac = state.splitFrac
    local listW, cardW
    if splitFrac <= 0 then
        listW = w
        cardW = 0
    elseif splitFrac >= 1 then
        listW = T.px(CC.PANE_W_SPLIT)
        cardW = T.px(CC.PANE_W_SPLIT)
    else
        -- Interpolate
        listW = math.floor(w - splitFrac * T.px(CC.PANE_W_SPLIT))
        cardW = math.floor(splitFrac * T.px(CC.PANE_W_SPLIT))
    end

    -- Left pane: recipe list or alt list
    if state.altSlotName then
        CC.renderAltList(panel, x, curY, listW, panesH, state)
    else
        CC.renderRecipeList(panel, x, curY, listW, panesH, state, config, data, win._playerObj)
    end

    -- Right pane: craft card (only when split > 0)
    if cardW > 0 and selRd then
        local cardX = x + listW
        -- Vertical divider between panes
        panel:drawRect(cardX, curY, T.px(1), panesH, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
        CC.renderCraftCard(panel, cardX + T.px(1), curY, cardW - T.px(1), panesH, state, config, selRd, win._playerObj)
    end

    -- (Nov 14 2026, punch list 198: the panes' own clips leave their area one stencil level up when they clear
    -- inside the drawer's clip (PZ's clear lowers the test, not the buffer), so the band's pop-up lists and the
    -- Category overlay failed the test over the panes and drew only in the gap between them. Put the panes' area
    -- back to the drawer's level, inside what an item card leaves showing.)
    if panel.repaintStencilRect then
        local rx, rr = x, x + w
        if panel._coverX then rr = math.min(rr, panel._coverX) end   -- (Character: a card on the right)
        if panel._coverL then rx = math.max(rx, panel._coverL) end   -- (World: a card on the left)
        if panel._coverR then rr = math.min(rr, panel._coverR) end
        if rr > rx then pcall(function() panel:repaintStencilRect(rx, curY, rr - rx, panesH) end) end
    end

    -- The band, full card width under both panes
    CC.renderBand(panel, x, y + h - bandH, w, state, config, selRd)

    -- Category dropdown overlay (drawn LAST — on top of everything)
    if state.catDropdownOpen and state._ddGeo then
        CC.renderCatDropdownOverlay(panel, state, data)
    end

    -- The band's Sort and Show pop-up lists (they open upward from their boxes)
    if state.sortMenuOpen then CC.renderPopMenu(panel, state, config, "sort") end
    if state.showMenuOpen then CC.renderPopMenu(panel, state, config, "show") end
    -- the lists drawn this frame tell ZeD.Popups they are open (a press outside, the tab hidden, an action or a
    -- walk shuts them; the director, Nov 23 2026)
    CC.popupsShown(panel, win, state, config)

    -- Station dropdown overlay (crafting)
    if config.stations and ZeD.Stations then
        ZeD.Stations.drawDropdownFor(panel, state, win._playerObj, state._gpFocusedId, config.prefix)
    end

    -- the controller's scroll-follow, with a delta gate. Uses last-frame
    -- zones so positions are stable against this-frame scroll adjustment.
    -- Only fires for recipeRow (the scrollable element type). Section
    -- headers and card sections are at fixed content-Y so scroll-follow
    -- on them would be noisy without benefit.
    --
    -- The zone gate accepts char or world tab content (this pipeline serves
    -- tabs in both windows). The delta-gate field is prefix-namespaced so
    -- journal, craft and build don't fight over the same `_lastPinned*` pin.
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if Focus and Focus.getFocusedZone and Focus.getFocusedElement
       and state.scroll and lastZones then
        local fz = Focus.getFocusedZone(win)
        if fz and (fz.zone == "charTabContent" or fz.zone == "worldTabContent") then
            local fe = Focus.getFocusedElement(win)
            local fid = fe and fe.id or nil
            local pfx = config.prefix or "jrecipe"
            local pinKey = "_lastPinnedRecipeId_" .. pfx
            if fid and fid ~= (win[pinKey] or nil) then
                local rowPfx = pfx .. ":row:"
                if string.sub(fid, 1, #rowPfx) == rowPfx then
                    local recipeId = string.sub(fid, #rowPfx + 1)
                    local zTarget = nil
                    for _, z in ipairs(lastZones) do
                        if z.type == "recipeRow" and tostring(z.id) == recipeId then
                            zTarget = z
                            break
                        end
                    end
                    if zTarget and state.scroll.setScrollPos and state._listGeo then
                        local g = state._listGeo
                        local totalH = g.totalH or 0
                        local viewH  = g.viewH  or 0
                        local viewY  = g.viewY  or 0
                        if totalH > viewH then
                            local span   = math.max(1, totalH - viewH)
                            local oldOff = math.floor(state.scroll.scrollPos * span)
                            local contentTy = zTarget.y - viewY + oldOff
                            local newOff = oldOff
                            if contentTy < oldOff then
                                newOff = contentTy
                            elseif contentTy + zTarget.h > oldOff + viewH then
                                newOff = contentTy + zTarget.h - viewH
                            end
                            newOff = math.max(0, math.min(span, newOff))
                            if newOff ~= oldOff then
                                state.scroll:setScrollPos((newOff + 0.5) / span)   -- (+0.5 against the bar's floor(): QA B11-4)
                            end
                        end
                    end
                end
                win[pinKey] = fid
            end
        end
    end
end

-- ============================================================================
-- RENDERING — Category Dropdown Overlay (absolute positioned, on top)
-- ============================================================================

-- (DD_ROW_H / DD_MAX_VIS: the constants at the top of the file)
function CC.renderCatDropdownOverlay(panel, state, data)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local geo = state._ddGeo
    local cats = data.categories or {}

    local font = T.fontF2
    local rowH = T.px(DD_ROW_H)
    local totalRows = #cats
    local visibleCount = math.min(totalRows, DD_MAX_VIS)
    local listH = visibleCount * rowH
    local ddX, ddY, ddW = geo.x, geo.y, geo.w
    local needsScroll = totalRows > DD_MAX_VIS

    -- Clamp scroll offset
    local scrollOff = state.catDropdownScroll or 0
    local maxScroll = math.max(0, totalRows - DD_MAX_VIS)
    if scrollOff > maxScroll then scrollOff = maxScroll end
    if scrollOff < 0 then scrollOff = 0 end
    state.catDropdownScroll = scrollOff

    -- a pop-up list: System 7's hard shadow outside it (drawn before the clip)
    A.drawHardShadow(panel, ddX, ddY, ddW, listH)

    -- Override any active stencil with the dropdown's own region
    panel:setStencilRect(ddX, ddY, ddW, listH)

    -- Backdrop (opaque surface)
    local bg = T.surf1
    panel:drawRect(ddX, ddY, ddW, listH, 1, bg.r, bg.g, bg.b)

    -- the controller: the focused id stashed on state marks a row (the element ids
    -- carry the tab's own prefix: craft, build or jrecipe)
    local gpFocusedId = state._gpFocusedId
    local catPfx = (state._pickPrefix or "jrecipe") .. ":cat:"

    -- Draw visible rows (offset by scroll): the current one in the selected wash,
    -- the pointer's hover, the controller's mark, then the words
    for vi = 0, visibleCount - 1 do
        local catIdx = scrollOff + vi + 1
        if catIdx > totalRows then break end
        local cat = cats[catIdx]
        local ry = ddY + vi * rowH
        local isActive = (cat.id == state.activeCat)
        local isHover = A.mouseIn(panel, ddX, ry, ddW, rowH)
        local isGpFocused = gpFocusedId and gpFocusedId == (catPfx .. tostring(cat.id))

        if isActive then
            panel:drawRect(ddX, ry, ddW, rowH, T.selectionA, T.accent.r, T.accent.g, T.accent.b)
        end
        if isHover then
            local hv = T.hover
            panel:drawRect(ddX, ry, ddW, rowH, hv.a, hv.r, hv.g, hv.b)
        end
        local onFocus = false
        if isGpFocused then onFocus = ZeD.Focus.mark(panel, ddX, ry, ddW, rowH) end

        local label = CC.categoryLabel(cat.full or cat.label or cat.id)
        local tc = onFocus and T.textOnFocus or T.text
        local textY = ry + math.floor((rowH - tm:getFontHeight(font)) / 2)
        panel:drawText(label, ddX + T.px(6), textY, tc.r, tc.g, tc.b, tc.a or 1, font)

        -- the number is what the list would show for this category (mode + search applied),
        -- not the catalog total; the catalog total stays the fallback before the first filter
        local shown = cat.count
        if state.filteredCounts then shown = state.filteredCounts[cat.id] or 0 end -- (QA K1-12)
        if shown then
            local countStr = tostring(shown)
            A.drawTextRight(panel, countStr, ddX + ddW - T.px(6), textY, T.fontF1, onFocus and T.textOnFocus or T.textDim)
        end
    end

    -- Scroll indicators (arrows at top/bottom when clipped)
    if needsScroll then
        if scrollOff > 0 then
            local arrowC = T.textSec
            A.drawTriangleUp(panel, ddX + math.floor((ddW - T.px(6)) / 2), ddY + T.px(2), T.px(6), arrowC)
        end
        if scrollOff < maxScroll then
            local arrowC = T.textSec
            A.drawTriangleDown(panel, ddX + math.floor((ddW - T.px(6)) / 2), ddY + listH - T.px(8), T.px(6), arrowC)
        end
    end

    -- Border on top of everything
    panel:drawRectBorder(ddX, ddY, ddW, listH, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    geo.lh = listH   -- (the open list's height, for ZeD.Popups: CC.popupsShown)

    panel:clearStencilRect()
end

-- ============================================================================
-- CLICK DISPATCHER — called from tab wrapper's onClick
-- ============================================================================

--- A press at (x, y). An open list or select takes every press; otherwise the
--- zone under it acts. True when something took the press.
function CC.onClick(state, config, win, x, y, playerObj)
    local T = ZeD.T
    -- Station dropdown open: it takes every click (pick a row or close)
    if state.stDropdownOpen and ZeD.Stations then
        ZeD.Stations.dropdownClick(state, playerObj, x, y)
        return true
    end
    -- When dropdown is open, do direct hit-test — consume ALL clicks
    if state.catDropdownOpen and state._ddGeo then
        local geo = state._ddGeo
        local cats = state.categoryList or {}
        local rowH = T.px(DD_ROW_H)
        local ddX, ddY, ddW = geo.x, geo.y, geo.w
        local visCount = math.min(#cats, DD_MAX_VIS)
        local listH = visCount * rowH
        local scrollOff = state.catDropdownScroll or 0

        -- Check if click is inside the dropdown list
        if x >= ddX and x < ddX + ddW and y >= ddY and y < ddY + listH then
            local vi = math.floor((y - ddY) / rowH)
            local catIdx = scrollOff + vi + 1
            if catIdx >= 1 and catIdx <= #cats then
                state.activeCat = cats[catIdx].id
                state.catDropdownOpen = false
                state.catDropdownScroll = 0
                state.filterDirty = true
                state.scroll:setScrollPos(0)
                state._gpReturnTo = "catDrop"
                return true
            end
        end

        -- Click outside dropdown — close it, consume the click
        state.catDropdownOpen = false
        state.catDropdownScroll = 0
        return true
    end

    -- A band pop-up list open (Sort or Show): it takes every click (pick a choice or shut it)
    if state.sortMenuOpen or state.showMenuOpen then
        local kind = state.sortMenuOpen and "sort" or "show"
        for _, z in ipairs(state[POP[kind].zones] or {}) do
            if x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h then
                CC.pickPop(state, config, kind, z.id)
                return true
            end
        end
        CC.closePopMenu(state, kind)
        return true
    end

    local zones = state.zones or {}

    -- Zones already store screen-space positions (scroll offset baked in at
    -- render time).  No additional adjustment needed — compare directly.
    -- the list's rows are stamped for every row, the hidden ones too (the controller walks them): a press only counts
    -- on a row inside the list's view, so a hidden row under the band's Category, Sort or Show does not take it
    -- (QA Nov 13, cov_reading: Category opened a hidden recipe on a long list)
    local lg = state._listGeo
    for _, zone in ipairs(zones) do
        local zt = zone.type
        local hidden = lg and (zt == "recipeRow" or zt == "recipeStar" or zt == "sectionHeader")
            and (y < lg.viewY or y >= lg.viewY + lg.viewH)
        if not hidden and x >= zone.x and x < zone.x + zone.w and y >= zone.y and y < zone.y + zone.h then

            if zone.type == "detailIcon" then
                CC.openPreview(win, state, playerObj)
                return true

            elseif zone.type == "recipeRow" then
                CC.handleRecipeClick(state, zone.id)
                -- no filterDirty here — selection doesn't change filter or
                -- sort criteria, and re-sorting would move the selected recipe
                -- and break toggle-off
                return true

            elseif zone.type == "recipeStar" then
                CC.togglePin(win, zone.id, config.pinKey,
                    "_" .. config.prefix .. "Pins", "filterDirty")
                state.filterDirty = true
                state.pins = win["_" .. config.prefix .. "Pins"] or {}
                return true

            elseif zone.type == "sectionHeader" then
                if zone.id == "pinned" then state.pinnedCollapsed = not state.pinnedCollapsed
                elseif zone.id == "freq" then state.freqCollapsed = not state.freqCollapsed
                elseif zone.id == "all" then state.allCollapsed = not state.allCollapsed end
                state._sectionsStale = true  -- collapse changes totalH
                return true

            elseif zone.type == "sortMenu" then
                CC.openPopMenu(state, "sort")
                return true

            elseif zone.type == "showMenu" then
                CC.openPopMenu(state, "show")
                return true

            elseif zone.type == "catDropdown" then
                state.catDropdownOpen = not state.catDropdownOpen
                state.stDropdownOpen = false
                state.sortMenuOpen, state.showMenuOpen = false, false
                return true

            elseif zone.type == "stationDropdown" then
                state.stDropdownOpen = not state.stDropdownOpen
                state.stDropdownScroll = 0
                state.catDropdownOpen = false
                state.sortMenuOpen, state.showMenuOpen = false, false
                return true

            elseif zone.type == "stationUse" then
                if ZeD.Stations and playerObj and zone.station then
                    ZeD.Stations.bind(playerObj, zone.station)
                end
                return true

            elseif zone.type == "altStrip_back" then
                CC.exitAltMode(state)
                return true

            elseif zone.type == "altStrip_ownedOnly" then
                state.ownedOnly = not state.ownedOnly
                return true

            elseif zone.type == "cardSection" then
                if zone.id == "req" then state.reqCollapsed = not state.reqCollapsed
                elseif zone.id == "out" then state.outCollapsed = not state.outCollapsed end
                return true

            elseif zone.type == "slotAlt" then
                -- Enter alt mode for this slot
                local containers = win["_" .. config.prefix .. "Containers"]
                if containers and zone.inputDef then
                    CC.enterAltMode(state, zone.id, zone.idx,
                        playerObj, containers, zone.inputDef)
                end
                return true

            elseif zone.type == "altPick" then
                -- choose this item type for the open slot (again to clear)
                CC.togglePick(state, state.selected, state.altSlotIdx, zone.id)
                return true

            elseif zone.type == "action_dec" then
                state.qty = math.max(1, state.qty - 1)
                return true

            elseif zone.type == "action_inc" then
                local maxQ = state._maxQty or 99
                state.qty = math.min(maxQ, state.qty + 1)
                return true

            elseif zone.type == "action_open" then
                -- the Journal's Open in Craft / Build: the config's own opener (KISS #40)
                if zone.open then zone.open(win, state, zone.rd) end
                return true

            elseif zone.type == "action_max" then
                state.qty = math.max(1, state._maxQty or state.qty)   -- the most the band knows (KISS #32)
                return true

            elseif zone.type == "action_build" then
                -- Delegate to tab-specific startAction
                CC.runStart(win, state, config.startAction)
                return true
            end
        end
    end

    return false
end

-- ============================================================================
-- RIGHT-CLICK DISPATCHER — pin toggle on recipe rows
-- ============================================================================

--- True when the right-click pinned or unpinned a recipe row.
function CC.onRightClick(state, config, win, x, y)
    local zones = state.zones or {}

    for _, zone in ipairs(zones) do
        if zone.type == "recipeRow" then
            if x >= zone.x and x < zone.x + zone.w and y >= zone.y and y < zone.y + zone.h then
                CC.togglePin(win, zone.id, config.pinKey,
                    "_" .. config.prefix .. "Pins", "filterDirty")
                state.filterDirty = true
                state.pins = win["_" .. config.prefix .. "Pins"] or {}
                return true
            end
        end
    end
    return false
end

-- ============================================================================
-- MOUSE WHEEL DISPATCHER
-- ============================================================================

--- The wheel: an open station or Sort / Show list, the one amount box, the open
--- category list, else the pane under the pointer (panelX: the drawer's left
--- edge). Always true: the drawer takes the wheel.
function CC.onMouseWheel(state, del, x, y, panelX, panelW)
    local T = ZeD.T
    if state.stDropdownOpen and ZeD.Stations then
        ZeD.Stations.dropdownWheel(state, del)
        return true
    end
    if state.sortMenuOpen or state.showMenuOpen then return true end
    -- the one amount box (a band short of room): the wheel steps it, up for more; only
    -- while the band drew it in the last 250 ms
    local qb = state._qtyBox
    if qb and qb.on and (getTimestampMs() - (qb.t or 0)) < 250 and x >= qb.x and x < qb.x + qb.w and y >= qb.y and y < qb.y + qb.h then
        if del < 0 then state.qty = math.min(state._maxQty or 99, (state.qty or 1) + 1)
        else state.qty = math.max(1, (state.qty or 1) - 1) end
        return true
    end
    -- Dropdown scroll takes priority when open
    if state.catDropdownOpen then
        local totalRows = #(state.categoryList or {})
        local maxScroll = math.max(0, totalRows - DD_MAX_VIS)
        -- PZ: positive del = scroll down
        state.catDropdownScroll = math.max(0, math.min(maxScroll,
            (state.catDropdownScroll or 0) + (del > 0 and 1 or -1)))
        return true
    end

    -- Determine which scroll area the mouse is over
    -- Left half = recipe/alt list, right half = card
    local midX = panelX + T.px(CC.PANE_W_SPLIT)
    if state.splitFrac > 0 and x >= midX then
        state.cardScroll:handleMouseWheel(del)
    elseif state.altSlotName then
        state.altScroll:handleMouseWheel(del)
    else
        state.scroll:handleMouseWheel(del)
    end
    return true
end

-- ============================================================================
-- GAMEPAD FOCUSABLES BUILDER
-- ============================================================================

-- buildFocusables is handed no config, so these stand in for one (the read-only
-- list is the Journal's, prefix "jrecipe")
local RO_CFG, FULL_CFG = { readOnly = true }, {}

--- Scrolls the open category list just enough that its catIdx-th row is in view (C12).
function CC.catScrollTo(state, catIdx)
    local total = #(state.categoryList or {})
    local off = state.catDropdownScroll or 0
    if not catIdx then return end
    if catIdx - 1 < off then off = catIdx - 1
    elseif catIdx > off + DD_MAX_VIS then off = catIdx - DD_MAX_VIS end
    off = math.max(0, math.min(math.max(0, total - DD_MAX_VIS), off))
    state.catDropdownScroll = off
end

-- The open category list's rows as the controller's stops. B shuts the list; a choice or
-- B brings the focus back to the select.
local function catRowFocusables(state, prefix)
    local T = ZeD.T
    local geo = state._ddGeo
    local cats = state.categoryList or {}
    local rowH = T.px(DD_ROW_H)
    local scrollOff = state.catDropdownScroll or 0
    local elements = {}
    local function shut()
        state.catDropdownOpen = false
        state.catDropdownScroll = 0
        state._gpReturnTo = "catDrop"
    end
    -- Every category is a stop, not only the 14 rows in view: one out of view sits where it would
    -- be drawn, above or below the list, and landing on it scrolls the list to it. The stops were
    -- the rows in view and only the wheel scrolled, so the pad never reached past the 14th of
    -- B42's 24 categories (QA cb sweep, Nov 25 2026, C12). The list is the only zone while it is
    -- open, so the rows out of view take no other zone's moves. A scroll changes the stops' key
    -- (the World window's scrollKey reads catDropdownScroll) and they are laid out again, each in
    -- its own place in the list, so the focus stays on the same category.
    for catIdx = 1, #cats do
        local cat = cats[catIdx]
        if cat then
            local vi = catIdx - scrollOff
            elements[#elements + 1] = {
                x = geo.x, y = geo.y + (vi - 1) * rowH, w = geo.w, h = rowH,
                id = prefix .. ":cat:" .. tostring(cat.id),
                craftKind = "catRow",
                journalKind = (prefix == "jrecipe") and "jrecipeCat" or nil,
                catId = cat.id,
                catIdx = catIdx,
                offscreen = (vi < 1 or vi > DD_MAX_VIS) or nil,   -- (never a stop for another zone's move)
                onFocus = function(w, el) CC.catScrollTo(state, el.catIdx) end,
                onActivate = function(w, el)
                    state.activeCat = el.catId
                    state.filterDirty = true
                    if state.scroll and state.scroll.setScrollPos then
                        state.scroll:setScrollPos(0)
                    end
                    shut()
                end,
                onCancel = function(w, el) shut() end,
            }
        end
    end
    return elements
end

-- A band pop-up list's rows (kind "sort" / "show") as the controller's stops: the current
-- choice has the focus first; A picks, B shuts; either way back to the box.
local function popRowFocusables(state, prefix, kind)
    local P = POP[kind]
    local cfg = (prefix == "jrecipe") and RO_CFG or FULL_CFG
    local cur = (kind == "show") and CC.showMode(state, cfg) or CC.sortOf(state)
    local rowKind = (kind == "show") and "showRow" or "sortRow"
    local elements = {}
    for i, z in ipairs(state[P.zones]) do
        elements[#elements + 1] = {
            x = z.x, y = z.y, w = z.w, h = z.h,
            id = prefix .. P.row .. tostring(z.id),
            craftKind = rowKind,
            sortId = z.id,
            onFocus = function(w, el) end,
            onActivate = function(w, el) CC.pickPop(state, cfg, kind, el.sortId) end,
            onCancel = function(w, el) CC.closePopMenu(state, kind) end,
        }
        if z.id == cur then elements._focusIdx = i end
    end
    elements._menuRows = true   -- (modal: FocusManager's _menuNav walks these rows)
    return elements
end

-- The recipe preview (ObjectCardPreview.lua): the picked recipe's card in the World window's
-- card drawer, opened from the icon at the top of the craft card (a press or A). The Journal's
-- recipes (the Character window) have no card drawer of their own, so they open none.
function CC.openPreview(win, state, playerObj)
    local rd = state and state._rdLast
    local OC = ZeD.ObjectCards
    if not (rd and rd.entry and OC and OC.open and state.config) then return false end
    if state.config.prefix == "jrecipe" then return false end
    local player = playerObj or (win and win._playerObj)
    if not player then return false end
    local ok, opened = pcall(OC.open, player, "preview", { entry = rd.entry, rd = rd, state = state, win = win, config = state.config })
    if not ok then ZeD.logOnce("CraftingCore preview", opened); return false end
    return opened and true or false
end

--- Shared focusable-list builder for ALL CraftingCore-driven tabs:
---   • Journal Recipes sub-tab on Character (readOnly, prefix="jrecipe")
---   • Crafting tab on World (full, prefix="craft")
---   • Building tab on World (full, prefix="build")
---
--- Synthesized from `state.zones`, the hit-zone list stamped each render by
--- the CC drawing pipeline: one focusable per interactive zone. Mode
--- branching is implicit: alt mode adds altStrip_* and drops the band's
--- sortMenu / showMenu and the catDropdown (greyed there); readOnly mode
--- (Journal) has no recipeStar / action_* zones, so those branches never fire.
--- An open list (category, station, the band's Sort / Show) is the explicit
--- focus-lock case (matches CC.onClick, which hands it every click). Order:
--- the header strip, the body (list, card), the band.
---
--- Args:
---   win        — the parent window (Char or World)
---   state      — CC state table (_jrecipeState / _craftState / _buildState)
---   prefix     — id namespace ("jrecipe" / "craft" / "build")
---   pinKey     — modData pin key ("ZeD_CraftPins" etc.) or nil for readOnly
---                (controls whether X on a recipeRow toggles its pin)
---   startAction — function(win, state) executed by A on the BUILD/CRAFT
---                button. nil for readOnly (no action_build zones emitted).
---
--- All onActivate closures capture `state` directly — the state-table identity
--- is stable across frames (created once via CC.createState() per tab), so
--- closures rebuilt each frame still target the same data.
---
--- recipeStar zones are deliberately NOT emitted as focusables — the pin is
--- X (onContextMenu) on the recipeRow itself.
function CC.buildFocusables(win, state, prefix, pinKey, startAction)
    local T = ZeD.T
    if not (win and state) then return {} end

    -- Station dropdown open: focus is locked to its rows
    if state.stDropdownOpen and ZeD.Stations then
        return ZeD.Stations.dropdownFocusables(state, win._playerObj, prefix)
    end

    -- Category list open: focus locked to its rows; B shuts it, and a choice or B
    -- brings the focus back to the select
    if state.catDropdownOpen and state._ddGeo then
        return catRowFocusables(state, prefix)
    end

    -- A band pop-up list open (Sort or Show): focus locked to its rows (the current choice
    -- has it first; B shuts the list; the focus goes back to the box)
    if state.sortMenuOpen and state._sortMenuZones then
        return popRowFocusables(state, prefix, "sort")
    end
    if state.showMenuOpen and state._showMenuZones then
        return popRowFocusables(state, prefix, "show")
    end

    local zones = state.zones or {}
    local elements = {}
    -- The recipe rows and section headers are rebuilt from the zones every
    -- frame, and there can be a thousand rows: each element (with its id
    -- string and closures) is made once and only its box is updated after.
    local fc = state._focusCache
    if not fc or fc.prefix ~= prefix or fc.pinKey ~= pinKey or fc.made > 4000 then
        fc = { prefix = prefix, pinKey = pinKey, rows = {}, sections = {}, made = 0 }
        state._focusCache = fc
    end
    -- a recipe can sit in two sections (pinned and all), so the cache is
    -- per id and per occurrence within the frame
    local occRow, occSec = {}, {}
    for _, z in ipairs(zones) do
        local n, slot = 0, nil
        if z.type == "recipeRow" then
            n = (occRow[z.id] or 0) + 1
            occRow[z.id] = n
            slot = fc.rows
        elseif z.type == "sectionHeader" then
            n = (occSec[z.id] or 0) + 1
            occSec[z.id] = n
            slot = fc.sections
        end
        local cached = slot and slot[z.id] and slot[z.id][n]
        if cached then
            cached.x, cached.y, cached.w, cached.h = z.x, z.y, z.w, z.h
            elements[#elements + 1] = cached
        elseif z.type == "recipeRow" then
            local el = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":row:" .. tostring(z.id),
                craftKind = "recipeRow",
                -- journalKind: a second kind name, set on the Journal's
                -- (jrecipe) elements only; the World window's jump to the
                -- card after a pick goes by craftKind.
                journalKind = (prefix == "jrecipe") and "jrecipeRow" or nil,
                recipeId = z.id,
                onFocus = function(w, el)
                    -- stashed for the L-from-card jump: window-level dispatch
                    -- reads this to restore the recipe-row focus when LEFT is
                    -- pressed in the card pane (cone-nav alone can't reliably
                    -- hop back across the wide y delta + 2x off-axis weight)
                    state._gpLastRecipeRowId = el.id
                end,
                onActivate = function(w, el)
                    CC.handleRecipeClick(state, el.recipeId)
                    -- signal a pending card-jump. The window's
                    -- per-frame ring-zone refresh sees this flag and seeds
                    -- focusedElementIdx to the first card-area element
                    -- (cardSection or action_build) once card zones are
                    -- stamped. Mirrors mouse UX where clicking a recipe makes
                    -- the card immediately the active surface. Skipped on
                    -- de-select (state.selected becomes nil after toggle off).
                    if state.selected then
                        state._gpPendingCardJump = true
                    end
                end,
            }
            -- X = pin/unpin; skipped for the read-only journal.
            -- Mirrors the right-click mouse path in CC.onRightClick.
            if pinKey then
                el.onContextMenu = function(w, el)
                    local stateKey = "_" .. prefix .. "Pins"
                    CC.togglePin(w, el.recipeId, pinKey, stateKey, "filterDirty")
                    state.filterDirty = true
                    state.pins = w[stateKey] or {}
                end
            end
            elements[#elements + 1] = el
            local lst = fc.rows[z.id]
            if not lst then lst = {}; fc.rows[z.id] = lst end
            lst[n] = el
            fc.made = fc.made + 1
        elseif z.type == "sectionHeader" then
            local sel = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":section:" .. tostring(z.id),
                isDisclosure = true,
                craftKind = "section",
                journalKind = (prefix == "jrecipe") and "jrecipeSection" or nil,
                sectionId = z.id,
                onFocus = function(w, el) end,
                -- A toggles expand/collapse, as the mouse click on the header does
                onActivate = function(w, el)
                    if el.sectionId == "pinned" then state.pinnedCollapsed = not state.pinnedCollapsed
                    elseif el.sectionId == "freq" then state.freqCollapsed  = not state.freqCollapsed
                    elseif el.sectionId == "all"  then state.allCollapsed   = not state.allCollapsed
                    end
                    state._sectionsStale = true
                end,
            }
            elements[#elements + 1] = sel
            local slst = fc.sections[z.id]
            if not slst then slst = {}; fc.sections[z.id] = slst end
            slst[n] = sel
            fc.made = fc.made + 1
        elseif z.type == "detailIcon" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":icon",
                craftKind = "icon",
                onFocus = function(w, el) end,
                onActivate = function(w, el) CC.openPreview(w, state, w._playerObj) end,
            }
        elseif z.type == "sortMenu" or z.type == "showMenu" then
            -- the band's Sort / Show pop-up boxes: A opens the list
            local kind = (z.type == "showMenu") and "show" or "sort"
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":" .. z.type,
                craftKind = z.type,
                journalKind = (prefix == "jrecipe") and "jrecipeSort" or nil,
                onFocus = function(w, el) end,
                onActivate = function(w, el) CC.openPopMenu(state, kind) end,
            }
        elseif z.type == "stationDropdown" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":stDrop",
                craftKind = "stDrop",
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    state.stDropdownOpen = not state.stDropdownOpen
                    state.stDropdownScroll = 0
                    state.catDropdownOpen = false
                    state.sortMenuOpen, state.showMenuOpen = false, false
                end,
            }
        elseif z.type == "stationUse" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":stUse",
                craftKind = "stUse",
                station = z.station,
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    if ZeD.Stations and w._playerObj and el.station then
                        ZeD.Stations.bind(w._playerObj, el.station)
                    end
                end,
            }
        elseif z.type == "catDropdown" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":catDrop",
                craftKind = "catDrop",
                journalKind = (prefix == "jrecipe") and "jrecipeCatDrop" or nil,
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    state.catDropdownOpen = not state.catDropdownOpen
                    state.sortMenuOpen, state.showMenuOpen = false, false
                end,
            }
        elseif z.type == "cardSection" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":card:" .. tostring(z.id),
                isDisclosure = true,
                craftKind = "cardSection",
                journalKind = (prefix == "jrecipe") and "jrecipeCardSection" or nil,
                cardSectionId = z.id,
                onFocus = function(w, el) end,
                -- A toggles expand/collapse, as the mouse click on the header does
                onActivate = function(w, el)
                    if el.cardSectionId == "req" then state.reqCollapsed = not state.reqCollapsed
                    elseif el.cardSectionId == "out" then state.outCollapsed = not state.outCollapsed
                    end
                end,
            }
        elseif z.type == "slotAlt" then
            -- A = enter alt mode for this ingredient slot. Container list
            -- lives at win._<prefix>Containers, set up by CC.gatherDetail.
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":slotAlt:" .. tostring(z.id),
                craftKind = "slotAlt",
                slotName = z.id,
                slotIdx = z.idx,
                inputDef = z.inputDef,
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    local containers = w["_" .. prefix .. "Containers"]
                    if containers and el.inputDef then
                        CC.enterAltMode(state, el.slotName, el.slotIdx,
                            w._playerObj, containers, el.inputDef)
                    end
                end,
            }
        elseif z.type == "altPick" then
            -- A = choose this item type for the open slot (again to clear)
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":altPick:" .. tostring(z.id),
                craftKind = "altPick",
                fullType = z.id,
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    CC.togglePick(state, state.selected, state.altSlotIdx, el.fullType)
                end,
            }
        elseif z.type == "altStrip_back" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":altBack",
                craftKind = "altBack",
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    CC.exitAltMode(state)
                end,
            }
        elseif z.type == "altStrip_ownedOnly" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":altOwned",
                craftKind = "altOwned",
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    state.ownedOnly = not state.ownedOnly
                end,
            }
        elseif z.type == "action_dec" and z.single then
            -- the one amount box (a band short of room): one stop; Left /
            -- Right step it and move on past its ends; A steps up, from the most back to 1
            elements[#elements + 1] = {
                x = z.bx, y = z.y, w = z.bw, h = z.h,
                id = prefix .. ":actQty",
                craftKind = "actQty",
                -- the most is 1: the help line says so as the focus lands (the band's draw
                -- keeps it there while the focus stays)
                onFocus = function(w, el)
                    if (state._maxQty or 99) <= 1 and ZeD.Help and ZeD.Help.set then
                        ZeD.Help.set(w, ZeD.tr("UI_ZeD_Craft_QtyOne"))
                    end
                end,
                onActivate = function(w, el)
                    -- (the most is 1: nothing to step, the help line says so)
                    local maxQ = state._maxQty or 99
                    if maxQ <= 1 then return end
                    local q = state.qty or 1
                    state.qty = (q < maxQ) and (q + 1) or 1
                end,
                -- Left / Right step it; at its ends (and when the most is 1) they move on
                onDpadDir = function(w, el, dir)
                    local q = state.qty or 1
                    if dir == "left" and q > 1 then state.qty = q - 1; return true end
                    if dir == "right" and q < (state._maxQty or 99) then state.qty = q + 1; return true end
                    return false
                end,
            }
        elseif z.type == "action_inc" and z.single then
            -- (the box's right half: the same stop)
        elseif z.type == "action_dec" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":actDec",
                craftKind = "actDec",
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    state.qty = math.max(1, (state.qty or 1) - 1)
                end,
            }
        elseif z.type == "action_inc" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":actInc",
                craftKind = "actInc",
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    local maxQ = state._maxQty or 99
                    state.qty = math.min(maxQ, (state.qty or 1) + 1)
                end,
            }
        elseif z.type == "action_open" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":actOpen",
                craftKind = "actOpen",
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    if z.open then z.open(w, state, z.rd) end   -- (KISS #40)
                end,
            }
        elseif z.type == "action_max" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":actMax",
                craftKind = "actMax",
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    state.qty = math.max(1, state._maxQty or state.qty or 1)   -- (KISS #32)
                end,
            }
        elseif z.type == "action_build" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":actBuild",
                craftKind = "actBuild",
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    CC.runStart(w, state, startAction)
                end,
            }
        end
    end
    -- the search box (punch list 252): A opens the pad keyboard on it (in alt mode it filters the
    -- alternatives); the keyboard's RT or B gives the pad back to the box. It goes after the header's
    -- selects, so landing on the tab is unchanged.
    local sf, sr = state._searchField, state._searchRect
    if sf and sr and sf:isVisible() and (sr.w or 0) > 0 then
        local at = 1
        for i, e in ipairs(elements) do
            if e.craftKind == "stDrop" or e.craftKind == "catDrop" then at = i + 1 end
        end
        if at > 1 and elements[at - 1] and elements[at - 1].y ~= nil and elements[at - 1].y > sr.y + sr.h then at = 1 end
        table.insert(elements, at, {
            x = sr.x, y = sr.y, w = sr.w, h = sr.h,
            id = prefix .. ":search",
            craftKind = "search",
            promptA = ZeD.tr("UI_ZeD_Inv_PromptType"),
            onFocus = function(w, el) end,
            onActivate = function(w, el)
                local KB = ZeD.Keyboard
                local pn = (w._playerObj and w._playerObj:getPlayerNum()) or w.playerNum or 0
                if KB and KB.edit then KB.edit(state._searchField, pn) end
            end,
        })
    end
    -- a list or a select has just shut: the controller comes back to the box that opened it
    if state._gpReturnTo then
        local want = prefix .. ":" .. state._gpReturnTo
        for i, e in ipairs(elements) do
            if e.id == want then elements._focusIdx = i; break end
        end
        state._gpReturnTo = nil
    end
    -- B with a recipe card open shuts the card (in the alternatives, leaves them first) and the
    -- focus goes back to its row. With nothing to back out of, B fell to the controller's default,
    -- stop the running action: B on the card cancelled the craft. The game's B shuts its craft
    -- window and the craft goes on (QA cb sweep, Nov 25 2026, C13). Escape shuts the card for the
    -- mouse and keys (CC.takeEscape). Only stops with no B of their own; a bound station's leave
    -- (below) takes B once the card is shut.
    if prefix == "craft" and state.selected then
        for _, el in ipairs(elements) do
            if not el.onCancel then
                el.onCancel = function(w, _el) return CC.padBack(state) end
                el.promptB = getText("UI_Close")
            end
        end
    end
    if ZeD.Stations then ZeD.Stations.addLeaveCancel(elements, win, prefix) end
    return elements
end

--- The pad's B on the Craft tab while a card is open (C13): leaves the alternatives, else shuts
--- the card and brings the focus back to the recipe's row. Never touches the action queue.
function CC.padBack(state)
    if state.altSlotName then
        CC.exitAltMode(state)
        return true
    end
    local name = state.selected
    if not name then return true end   -- (stops a frame old: the card already shut; still never the craft)
    CC.closeCraft(state)
    state._gpReturnTo = "row:" .. tostring(name)
    return true
end
