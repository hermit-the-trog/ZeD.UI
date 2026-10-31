-- ZeD-UI/42/media/lua/client/ZeD/CraftingCore.lua
-- ============================================================================
-- SHARED MODULE for CraftingTab + BuildingTab + JournalTab (data utilities).
-- Contains: catalog helpers, container scanning, material counting,
-- pin management, craft count tracking, filtering/sorting, text truncation,
-- state machine, rendering, and alt-mode enumeration.
--
-- Each consumer passes a `config` table to distinguish Craft vs Build behavior.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Tr"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"

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
-- CONSTANTS (from CRAFTING_SPEC.md §8 — frozen)
-- ============================================================================

CC.DRAWER_W        = 480
CC.PANE_W_SOLO     = 480
CC.PANE_W_SPLIT    = 240
CC.ROW_H           = 24
CC.HEADER_H        = (ZeD.Spacing and ZeD.Spacing.tabHeaderH) or 37  -- standard ZeD drawer-header strip
CC.STRIP_H          = 20    -- sort strip doubles as column header row
CC.MAX_PINS        = 8
CC.ANIM_DURATION   = 0.28  -- pane split animation in seconds

-- Throttle intervals (frames)
local CONTAINER_INTERVAL = 90

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
    local entry = rd.entry
    for _, inp in ipairs(entry.inputDefs) do
        if not CC.hasAnyWithTypes(inp.validTypes, containers, typeCache) then
            return "missing"
        end
    end
    return "craftable"
end

-- ============================================================================
-- BACKGROUND SCANNER — checks ingredient availability in batches per frame.
-- Call from tab render(). Scans BATCH_SIZE recipes per frame, round-robin.
-- Updates rd.status in-place so dots reflect real craftability.
-- ============================================================================

local BG_BATCH_SIZE = 15  -- recipes checked per frame (tunable)

function CC.backgroundIngredientScan(data, win, prefix)
    local recipes = data.recipes
    if not recipes or #recipes == 0 then return end

    -- Build/reuse containers (shared with gatherDetail)
    local contKey = "_" .. prefix .. "Containers"
    local containers = win[contKey]
    if not containers then
        containers = CC.buildContainers(win._playerObj)
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
-- VANILLA'S ANSWER (Oct 15 2026, director: "I should only see what I can
-- immediately craft cause all the materials, station and skill passes the
-- check that all is green to craft"). Vanilla's crafting logic (HandcraftLogic
-- / BuildLogic, a BaseCraftingLogic) holds every recipe and caches, per recipe,
-- whether the character could make it now from the containers in reach:
-- getCachedRecipeInfo(recipe):isValid() (known, skills) and :isCanPerform()
-- (materials in the right amounts, tools, the bench). The same check greys
-- vanilla's own list. Refreshed every LOGIC_EVERY_MS while the tab shows; a
-- changed status re-filters the list. Recipes it answered are marked
-- rd.fromLogic, and the quick scan below leaves them alone.
-- ============================================================================
local LOGIC_EVERY_MS = 1200

function CC.logicScan(data, win, prefix, makeLogic)
    local recipes = data and data.recipes
    if not recipes or #recipes == 0 or not makeLogic then return false end
    local now = getTimestampMs()
    local atKey = "_" .. prefix .. "LogicAt"
    if win[atKey] and now - win[atKey] < LOGIC_EVERY_MS then return false end
    win[atKey] = now
    local lKey, dKey = "_" .. prefix .. "Logic", "_" .. prefix .. "LogicData"
    local logic = win[lKey]
    if not logic then
        local ok, l = pcall(makeLogic)
        if not ok or not l then return false end
        logic = l
        win[lKey], win[dKey] = logic, nil
    end
    local ok = pcall(function()
        -- the containers as they are now (and the quick scan's cache follows them),
        -- then the recipes: setting them fills the per-recipe cache from those containers
        local containers = CC.buildContainers(win._playerObj)
        win["_" .. prefix .. "Containers"] = containers
        win["_" .. prefix .. "TypeCache"] = nil
        logic:setContainers(containers)
        local lk = "_" .. prefix .. "LogicList"
        if win[dKey] ~= data or not win[lk] then
            local list = ArrayList.new()
            for _, rd in ipairs(recipes) do if rd.entry.recipe then list:add(rd.entry.recipe) end end
            win[lk] = list
            win[dKey] = data
        end
        logic:setRecipes(win[lk])
    end)
    if not ok then win[lKey] = nil; return false end
    local changed = false
    for _, rd in ipairs(recipes) do
        local r = rd.entry.recipe
        if r and rd.status ~= "station" then
            local info = nil
            pcall(function() info = logic:getCachedRecipeInfo(r) end)
            if info then
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

-- The tabs rebuild their recipe rows every 30 frames (learned recipes, skills,
-- the bench): the last craftable / missing answer carries over to the new rows
-- until the next scan, so the list does not empty and refill between scans.
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
-- UTILITY — truncText (binary search ellipsis truncation)
-- ============================================================================

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
            win[stateKey] = pins
            win[dirtyKey] = true
            CC.savePins(win, pinKey, stateKey)
            return
        end
    end

    -- Add pin (FIFO eviction if at max)
    if #pins >= CC.MAX_PINS then
        table.remove(pins, 1)
    end
    pins[#pins + 1] = recipeName
    win[stateKey] = pins
    win[dirtyKey] = true
    CC.savePins(win, pinKey, stateKey)
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
-- Returns ordered list of {name, count} tables.
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
-- Returns list of {name, isTool, isKeep, validTypes, altCount} tables.
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

                -- Tag for display: TOOL, 1 USE, KEEP, or nil
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
                outputDefs[#outputDefs + 1] = {
                    name       = CC.getOutputName(output),
                    validTypes = outTypes,
                }
            end
        end
    end
    return outputDefs
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
    local cap = ZeD.upper(string.sub(raw, 1, 1)) .. string.sub(raw, 2)
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

-- SHOW: "ready" | "known" | "all" (older state kept only showAll: on = all, off = known;
-- the Journal's read-only list has no Ready)
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

-- Show one of the choices (the band's Show pop-up; Oct 30 2026, punch list 21: the
-- choices CC.cycleShow steps through, picked from a list)
function CC.setShow(state, id)
    state.show = id
    state.showAll = (id == "all")
    state.filterDirty = true
end

-- The band's pop-up choices, {id, key, label}: made once, the labels refreshed where
-- they are drawn (CC.popModes). The read-only list (the Journal) has no craft counts
-- (no Freq / Recent) and no Ready.
local SORT_FULL = {
    { id = "craftable", key = "UI_ZeD_Craft_SortCraftable" },
    { id = "known",     key = "UI_ZeD_Craft_Known" },
    { id = "name",      key = "UI_ZeD_Craft_SortName" },
    { id = "freq",      key = "UI_ZeD_Craft_SortFreq" },
    { id = "recent",    key = "UI_ZeD_Craft_SortRecent" },
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

-- The label of a choice in a mode list (the box names the current one)
local function modeLabel(modes, id)
    for i = 1, #modes do
        if modes[i].id == id then return modes[i].label end
    end
    return modes[1] and modes[1].label or ""
end

function CC.filterAndSort(data, state, config)
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
                    if string.find(string.lower(inp.name), searchLower, 1, true) then
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
        -- looks through everything.
        local modeOut = false
        local show = CC.showMode(state, config)
        if not searchOut and not searching and show ~= "all" then
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
    local playerObj = nil
    if sortMode == "freq" or sortMode == "recent" then
        playerObj = getSpecificPlayer(0)
    end
    local countKey = config and config.countKey or "ZeD_CraftCount"

    for _, rd in ipairs(filtered) do
        local pin = pinSet[rd.entry.name] and 0 or 1
        local sk

        if sortMode == "craftable" then
            -- Craftable first, then missing, then locked; within tier, alphabetical
            local st = STATUS_RANK[rd.status] or 3
            local mc = rd.missingCount or 0
            sk = pin * 10000 + st * 1000 + mc * 10

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

        elseif sortMode == "recent" then
            -- Most recently crafted first (higher timestamp = lower key)
            local count = 0
            if playerObj then count = CC.getCraftCount(playerObj, rd.entry.name, countKey) end
            sk = pin * 10000 + (count > 0 and 0 or 1) * 1000 + (9999 - math.min(9999, count))

        else
            sk = pin * 10000
        end

        rd._sortKey = sk
    end

    -- Insertion sort — Kahlua-safe (no recursion)
    for i = 2, #filtered do
        local val = filtered[i]
        local vk  = val._sortKey
        local vn  = val.entry.displayName
        local j = i - 1
        while j >= 1 do
            local other = filtered[j]
            if other._sortKey < vk then break end
            if other._sortKey == vk and other.entry.displayName <= vn then break end
            filtered[j + 1] = other
            j = j - 1
        end
        filtered[j + 1] = val
    end

    return filtered, catCounts
end

-- ============================================================================
-- DETAIL GATHERING — container scan for ONE selected recipe
-- ============================================================================

function CC.gatherDetail(rd, playerObj, win, prefix)
    local entry = rd.entry

    -- Build containers if needed (lazy, throttled)
    local timerKey = "_" .. prefix .. "ContainerTimer"
    local contKey  = "_" .. prefix .. "Containers"
    local cacheKey = "_" .. prefix .. "TypeCache"
    win[timerKey] = (win[timerKey] or 0) + 1
    if win[timerKey] >= CONTAINER_INTERVAL or not win[contKey] then
        win[timerKey] = 0
        win[contKey] = CC.buildContainers(playerObj)
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
        local need = 1
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
            iconTex    = nil,  -- individual ingredient icons deferred
            validTypes = inp.validTypes,  -- needed for alt enumeration
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
    if rd.status ~= "station" and not rd.fromLogic then   -- (vanilla's answer counts amounts; this only counts one of each)
        rd.status   = missingCount > 0 and "missing" or "craftable"
    end

    return containers
end

-- ============================================================================
-- ALT ENUMERATION — iterate player inventory for alternative items
-- Only shows items you HAVE (user decision: inventory-only, not all scripts).
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
                                need = 1,
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
                need = 1,
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

function CC.createState()
    return {
        activeCat        = "all",
        search           = "",
        altSearch         = "",
        sort             = "craftable", -- "craftable" | "known" | "name" | "freq" | "recent"
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
        -- Toggle off: close craft card
        CC.closeCraft(state)
    else
        -- Select new recipe: open or swap craft card
        CC.openCraft(state, recipeId)
    end
end

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

function CC.closeCraft(state)
    state.selected = nil
    state.picks = {}
    state.qty = 1
    state.splitTarget = 0
    if state.altSlotName then CC.exitAltMode(state) end
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

--- Attempt to approximate cubic-bezier(0.4, 0, 0.2, 1) via ease-out cubic.
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
-- RENDERING — Header strip (Oct 30 2026, punch list 21: one row, the standard
-- height). Craft: the STATION and CATEGORY selects and the search side by side;
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
    if up then
        g.y = y - math.min(#(state.categoryList or {}), DD_MAX_VIS) * ZeD.T.px(DD_ROW_H)
    else
        g.y = y + h
    end
end

-- The tab's search field (a ZeD_SearchField, a child panel of the drawer, made by the
-- window): placed where the caller says; in alt mode it filters the alternatives.
function CC.placeSearch(win, config, state, x, y, w, h)
    local f = win and config and win["_" .. tostring(config.prefix) .. "Search"]
    if not f then return end
    if f:getX() ~= x or f:getY() ~= y then f:setX(x); f:setY(y) end
    if f:getWidth() ~= w or f:getHeight() ~= h then f:setWidth(w); f:setHeight(h) end
    if f._zedBaseHint == nil then f._zedBaseHint = f.placeholder or false end   -- (the field's own words: Build's names structures)
    if state.altSlotName then f.placeholder = ZeD.tr("UI_ZeD_Craft_FilterAlts")
    else f.placeholder = f._zedBaseHint or getText("IGUI_CraftingWindow_SearchRecipes") end
end

function CC.renderStaticHeader(panel, x, y, w, state, config, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local zones = state.zones
    local pfx = (config and config.prefix) or "jrecipe"
    local ST = config and config.stations and ZeD.Stations or nil
    local headerH = T.px(CC.HEADER_H)  -- the standard 37u strip
    local pad, gap = T.px(6), T.px(6)
    local ddH = T.inputH  -- the selects match the search field
    local rowY = y + math.floor((headerH - ddH) / 2)
    local ddX, ddW, searchX, searchW

    if ST then
        -- Crafting: STATION, CATEGORY and the search in thirds; a select is never narrower
        -- than its value and its arrow ("-- All --" v): the search gives it the room, down
        -- to half its own third (Oct 31 2026, break-it B2: at 1280x720, UI scale 2.0, Large
        -- text the Category read "-- A...")
        local selW = math.floor((w - pad * 2 - gap * 2) / 3)
        local player = win and win._playerObj
        local cur = player and ST.current(player) or nil
        local stVal = cur and cur.name or ZeD.tr("UI_ZeD_Station_Hand")
        local chrome = T.sp.inputPadX * 2 + T.px(5) + T.px(4) + T.px(1)   -- (ST.drawSelect's pads and arrow)
        local stW = math.max(selW, ZeD.TM:MeasureStringX(T.fontF2, stVal) + chrome)
        local cW = math.max(selW, ZeD.TM:MeasureStringX(T.fontF2, CC.activeCategoryLabel(state)) + chrome)
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
        -- Building: the Category select LEFT (~45%), the search RIGHT
        ddW = math.floor((w - pad * 2 - gap) * 0.45)
        ddX = x + pad
        searchX = ddX + ddW + gap
        searchW = w - pad * 2 - gap - ddW
    end

    CC.placeSearch(win, config, state, searchX, rowY, searchW, ddH)
    drawCatSelect(panel, state, pfx, ddX, rowY, ddW, ddH, ST and ZeD.tr("IGUI_invpanel_Category") or nil, false)

    -- Bottom rule on header row
    A.drawDividerH(panel, x, y + headerH - T.px(1), w, true)

    return headerH
end

-- ============================================================================
-- RENDERING — Alternatives strip (alt mode, 20u): the alternatives list's own
-- strip (back, the owned count, Owned only), a fold of the card. The sort strip
-- that sat here went to the band's Sort and Show (Oct 30 2026); out of alt mode
-- there is nothing here.
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
-- RENDERING — The band (Oct 30 2026, punch list 21): at the card's foot, the full
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
    if c and c.scale == T.scale and c.font == T.fontF1 and c.lang == lang and c.ro == ro then return c.sort, c.show end
    local sw, hw = 0, 0
    for _, m in ipairs(sortModes) do sw = math.max(sw, M.popupMenuW(ZeD.tr("UI_ZeD_Craft_SortPick", m.label))) end
    for _, m in ipairs(showModes) do hw = math.max(hw, M.popupMenuW(ZeD.tr("UI_ZeD_Craft_ShowToggle", m.label))) end
    state._popW = { scale = T.scale, font = T.fontF1, lang = lang, ro = ro, sort = sw, show = hw }
    return sw, hw
end

-- One of the band's pop-up boxes: its zone, and the open list's geometry (it opens
-- upward from the box: the band is at the card's foot). frozen: greyed, no press.
-- (short: the choice alone, shown when "Sort: Craftable" does not fit, break-it B2)
local function drawPopBox(panel, state, kind, x, y, w, h, label, modes, frozen, focused, mx, my, short)
    local P = POP[kind]
    local hov = (not frozen) and mx >= x and mx < x + w and my >= y and my < y + h
    M.drawPopupMenu(panel, x, y, w, h, label, hov or state[P.open] == true, (focused and not frozen) and NO_FOCUS_OPTS or nil, frozen, short)
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
end

-- The amount and Craft / Build at the band's right; returns the x the left part ends at,
-- and true when the band is short of room. leftNeed: the room the left part's boxes need
-- from x at the usual spacing; short of it, the amount closes up (its gap to Craft / Build,
-- its readout only as wide as its digits) (Oct 31 2026, break-it B2).
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
        canCraft = rd.status == "craftable" and rd.learned ~= false and maxQty > 0
    end
    -- the band: surface 2, the structure line, Craft / Build (primary) at the right
    local b = _bandBtns[1]
    b.label = ZeD.tr(config.buildLabel or "IGUI_CraftingWindow_Craft")
    b.variant, b.disabled, b.id = "primary", not canCraft, "build"
    if mx < 0 then b.hover = false else b.hover = nil end
    b.focus = (rd and fid == pfx .. ":actBuild") and NO_FOCUS_OPTS or nil
    _bandSpec.win = state._focusWin
    local _, out = M.drawBand(panel, x, y, w, _bandSpec)
    local r = out.buttons[1]
    -- the amount (- n +) left of it; the readout is as wide as the stepper makes it
    local qtyTW = ZeD.TM:MeasureStringX(T.fontF3, tostring(qty))
    local qtyW = math.max(bh, qtyTW + T.px(8))
    local stepW = bh * 2 + qtyW + 2 * T.px(4)
    local rx = r and r.x or (x + w - T.px(8))
    local sx = rx - gap - stepW
    local narrow = (sx - gap - x) < (leftNeed or 0)
    if narrow then
        gap = T.px(4)
        stepW = bh * 2 + qtyTW + T.px(8) + 2 * T.px(4)
        sx = rx - gap - stepW
    end
    local so = _bandStep
    so.focusId = nil
    so.narrow = narrow
    if rd and fid then
        if fid == pfx .. ":actDec" then so.focusId = "dec"
        elseif fid == pfx .. ":actInc" then so.focusId = "inc" end
    end
    local _, stepZones = M.drawQtyStepper(panel, sx, y + T.px(5), qty, maxQty, bh, (mx < 0) and "" or nil, so)
    if rd then
        for _, z in ipairs(stepZones) do
            z.type = "action_" .. z.id
            zones[#zones + 1] = z
        end
        if r then zones[#zones + 1] = { type = "action_build", x = r.x, y = r.y, w = r.w, h = r.h } end
    end
    return sx - gap, narrow
end

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
    -- choice and its arrow ("Craftable" v), and at worst its first letter and the arrow
    -- (Oct 31 2026, break-it B2: narrowed by one share, Sort and Show came out too
    -- narrow for any words at 1280x720, UI scale 2.0, Large text)
    local sortModes = CC.popModes("sort", config)
    local showModes = CC.popModes("show", config)
    local sortName = modeLabel(sortModes, state.sort or "craftable")
    local showName = modeLabel(showModes, CC.showMode(state, config))
    local sortW, showW = popWidths(state, config, sortModes, showModes)
    local catName = ro and CC.activeCategoryLabel(state) or nil
    local catW = ro and T.px(CAT_BAND_W) or 0
    local sortMin, showMin = math.min(sortW, M.popupMenuW(sortName)), math.min(showW, M.popupMenuW(showName))
    local catMin = ro and math.min(catW, M.popupMenuW(catName)) or 0
    local nGaps = ro and 2 or 1

    -- the right: the amount and Craft / Build (the read-only list has none)
    local leftEnd, narrow
    if ro then
        _bandSpecRO.win = state._focusWin
        M.drawBand(panel, x, y, w, _bandSpecRO)
        leftEnd = x + w - edge
        narrow = (leftEnd - x - edge - gap * nGaps) < catMin + sortMin + showMin
    else
        leftEnd, narrow = drawBandActions(panel, x, y, w, state, config, rd, pfx, fid, mx,
            edge + gap * nGaps + catMin + sortMin + showMin)
    end
    -- short of room the spaces close up first
    if narrow then edge, gap = T.px(4), T.px(4) end

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
            -- the rest is shared by what each choice needs over that (a punch list question)
            local catF = ro and math.min(catMin, M.popupMenuW(string.sub(catName or "", 1, 1))) or 0
            local sortF = math.min(sortMin, M.popupMenuW(string.sub(sortName, 1, 1)))
            local showF = math.min(showMin, M.popupMenuW(string.sub(showName, 1, 1)))
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
        drawCatSelect(panel, state, pfx, lx, by, catW, bh, ZeD.tr("IGUI_invpanel_Category"), true)
        lx = lx + catW + gap
    end
    drawPopBox(panel, state, "sort", lx, by, sortW, bh, ZeD.tr("UI_ZeD_Craft_SortPick", sortName),
        sortModes, frozen, fid == pfx .. ":sortMenu", mx, my, sortName)
    lx = lx + sortW + gap
    drawPopBox(panel, state, "show", lx, by, showW, bh, ZeD.tr("UI_ZeD_Craft_ShowToggle", showName),
        showModes, frozen, fid == pfx .. ":showMenu", mx, my, showName)
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
    local active = (kind == "show") and CC.showMode(state, config) or state.sort
    local _, _, zs = M.drawSortMenuList(panel, geo.x, geo.y, geo.modes, active, hoverId, mo)
    state[P.zones] = zs
end

function CC.renderSortMenu(panel, state, config) CC.renderPopMenu(panel, state, config, "sort") end

-- Open one of the band's pop-up lists (the other lists and the selects shut).
function CC.openPopMenu(state, kind)
    state.sortMenuOpen = (kind == "sort")
    state.showMenuOpen = (kind == "show")
    state.catDropdownOpen = false
    state.stDropdownOpen = false
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

    if not sections or state._sectionsStale or state._sectionsScale ~= T.scale then  -- S124 scale: totalH is screen px, rebuild when T.scale changes
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
        local allLabel = (#(state.search or "") > 0) and "UI_ZeD_Craft_Results" or "UI_ZeD_Craft_AllRecipes"   -- keys, translated where drawn
        sections[#sections + 1] = {
            id = "all", label = allLabel, color = nil,
            items = allItems, collapsed = state.allCollapsed,
        }

        -- Measure total content height
        totalH = 0
        for _, sec in ipairs(sections) do
            totalH = totalH + catHdrH
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

    -- S105 gamepad: expose list geometry for the render-level scroll-follow
    -- pass (needs viewport bounds + totalH to translate screen-space zone
    -- positions to content-space).
    state._listGeo = { viewY = y, viewH = h, totalH = totalH }

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

        -- Rows: always stamp zones for cone-nav (S107 QA — scroll past
        -- viewport requires off-screen rows be focusable so D-pad cone has a
        -- target below the visible area; scroll-follow then brings it into
        -- view next frame). Draw only when within visible rect. Zone-only
        -- iteration cost: ~24 bytes/row table × ~500 rows ≈ 12KB/frame for
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

-- The craft action for a recipe whose ingredients were chosen. The chosen
-- types are offered to a handcraft logic in manual-select mode (as vanilla's
-- crafting window does when the player picks items) and the action is built
-- from it, so the game uses what was chosen. Returns nil when nothing was
-- chosen or the choice no longer covers the recipe (an item used up, moved
-- out of reach): the caller then starts the usual automatic craft.
--
-- The slots the player did not choose for keep the items the game fills them
-- with (autoPopulateInputs, as vanilla's panel does), so the recipe stays
-- complete. Each chosen slot is filtered to its own input before its items
-- are offered, so a chosen type lands in that slot and nowhere else.
-- `used` (optional) is a set of items already promised to an earlier craft
-- of the same batch: they are skipped, and the items this craft takes are
-- added to it. Tools and kept items are not consumed, so they are never skipped.

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

function CC.pickedCraftAction(playerObj, state, entry, bench, containers, used)
    local picks = state.picks and entry and state.picks[entry.name]
    if not (picks and hasAny(picks) and entry.recipe and entry.inputDefs and containers) then return nil end
    local action = nil
    local ok = pcall(function()
        local logic = HandcraftLogic.new(playerObj, bench and bench.comp or nil, bench and bench.obj or nil)
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
        if logic:canPerformCurrentRecipe() then
            action = ISHandcraftAction.FromLogic(logic, 0)
            if used then
                for idx = 1, #defs do
                    local def = defs[idx]
                    local script = def.inputRef
                    if script and not (def.isTool or def.isKeep) and script:getResourceType() == ResourceType.Item then
                        local list = logic:getManualInputsFor(script, ArrayList.new())
                        for i = 0, list:size() - 1 do used[list:get(i)] = true end
                    end
                end
            end
        end
    end)
    return ok and action or nil
end

-- Queue the crafts for the selected recipe when the player chose ingredients,
-- one action per craft of the batch. Returns true when it handled the click
-- (even if a bench check declined it, as the usual start does) and false when
-- the usual automatic start should run instead: nothing chosen, or the choice
-- cannot be met right now.
function CC.startPickedCraft(win, state)
    local playerObj = win._playerObj
    local name = state.selected
    local entry = state._selEntry
    local picks = state.picks and name and state.picks[name]
    if not (playerObj and entry and entry.name == name and entry.recipe and picks and hasAny(picks)) then return false end

    -- at a bench: still bound and carrying this recipe, as the usual start checks
    local bench = nil
    if ZeD.Stations then
        local st = ZeD.Stations.validate(playerObj)
        if st and st.kind == "bench" then bench = st end
    end
    if entry.stationInfo and not bench then return false end
    if bench and not ZeD.Stations.recipeSet(bench)[entry.recipe:getName()] then return false end

    local containers = CC.buildContainers(playerObj)
    local actions = {}
    local used = {}
    for i = 1, (state.qty or 1) do
        local a = CC.pickedCraftAction(playerObj, state, entry, bench, containers, used)
        if not a then return false end
        actions[i] = a
    end

    if bench and ISEntityUI and ISEntityUI.WalkToEntity and not ISEntityUI.WalkToEntity(playerObj, bench.obj) then return true end
    local queued = pcall(function()
        for i = 1, #actions do ISTimedActionQueue.add(actions[i]) end
    end)
    if queued then
        CC.incrementCraftCount(playerObj, name, state._countKey or "ZeD_CraftCounts")
    end

    state.qty = 1
    state.filterDirty = true
    win._craftCache = nil
    win["_craftContainerTimer"] = 90
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
-- RENDERING — Craft Card (240px right pane)
-- ============================================================================

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
    local outputsH = ROW_H + #(entry.outputDefs or {}) * ROW_H
    local actionH = 0   -- (Oct 30 2026: the amount and Craft / Build moved to the card's band, CC.renderBand)
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
    local totalH = headerH + chipH + T.px(4) + needH + inputsH + T.px(4) + outputsH + learnH + actionH

    -- Scrollbar (for very long ingredient lists)
    local scrollW = T.sp.scrollbarW
    local availH = h - actionH  -- action strip pinned to bottom
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

    -- Stencil for scrollable area (above action strip)
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

    -- Name (F2 13px, heading ink)
    local nameX = iconX + iconSz + T.px(6)
    local nameFont = T.fontF2
    local nameStr = CC.truncText(entry.displayName, nameFont, contentW - (nameX - x) - T.px(6))
    local hc = T.textHead
    panel:drawText(nameStr, nameX, curY + T.px(6), hc.r, hc.g, hc.b, hc.a or 1, nameFont)

    -- Description (pre-baked during catalog build)
    if entry.description then
        local descStr = CC.truncText(entry.description, T.fontF5, contentW - (nameX - x) - T.px(6))
        local descY = curY + T.px(6) + tm:getFontHeight(nameFont) + T.px(2)
        panel:drawText(descStr, nameX, descY, T.textSec.r, T.textSec.g, T.textSec.b, T.textSec.a, T.fontF5)
    end

    curY = curY + headerH

    -- Chip row: KNOWN/UNKNOWN, SURFACE, LIGHT, time
    local chipX = x + T.px(6)
    -- In readOnly (Journal), show accessibility: learned AND has skill
    local isAccessible = rd.learned and (rd.hasSkill ~= false)
    local learnedStr = ZeD.tr(isAccessible and "UI_ZeD_Craft_BadgeKnown" or "UI_ZeD_Craft_BadgeUnknown")
    local learnedV = isAccessible and "positive" or "danger"
    local bw = A.drawBadge(panel, learnedStr, chipX, curY, learnedV)
    chipX = chipX + bw + T.px(4)

    -- Surface requirement (pre-baked during catalog build)
    local needsSurface = entry.needSurface or false
    if needsSurface then
        bw = A.drawBadge(panel, ZeD.tr("IGUI_CraftingWindow_Surface"), chipX, curY, "warning")
        chipX = chipX + bw + T.px(4)
    end

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

    -- NEEDS (cohesion spec 9): a hollow square and "Needs a Primitive Kiln." in F2,
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
    local mx, my = panel:getMouseX(), panel:getMouseY()   -- hoisted: the HOW TO LEARN hover test below used these before they were declared (nil globals)
    if cuesOn() then mx, my = -1, -1 end
    local pfx = (config and config.prefix) or "jrecipe"

    -- Learn info section (readOnly + not accessible — renders ABOVE required; it does not fold)
    if showLearnSection then
        local learnLabel = ZeD.tr("UI_ZeD_Craft_HowToLearn")
        M.drawSectionHeader(panel, x + T.px(6), curY, contentW - T.px(6), learnLabel,
            nil, true, false, nil, false, T.px(6), catHdrH, true)
        curY = curY + catHdrH

        -- Skill requirements: the status square carries met / not met, the words stay default
        if rd.skills and #rd.skills > 0 then
            for _, sk in ipairs(rd.skills) do
                local skColor = sk.met and T.positive or T.danger
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
            local hintStr = ZeD.tr("UI_ZeD_Craft_FindRecipe")
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
    secOpts.focus = (state._gpFocusedId == (pfx .. ":card:req")) and NO_FOCUS_OPTS or nil
    M.drawSectionHeader(panel, x + T.px(6), curY, contentW - T.px(6), secLabel,
        haveCount .. "/" .. reqCount, not state.reqCollapsed, reqHdrHover, nil, true, T.px(6), catHdrH, nil, secOpts)
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
                have = ing.have,
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

    -- Outputs section (collapsible disclosure, matches inventory catHdrH)
    curY = curY + T.px(4)
    local outCount = #(entry.outputDefs or {})
    if outCount > 0 then
        local outHdrHover = mx >= x and mx < x + contentW and my >= curY and my < curY + catHdrH
        secOpts.focus = (state._gpFocusedId == (pfx .. ":card:out")) and NO_FOCUS_OPTS or nil
        M.drawSectionHeader(panel, x + T.px(6), curY, contentW - T.px(6), ZeD.tr("IGUI_CraftingWindow_Creates"),
            outCount, not state.outCollapsed, outHdrHover, nil, true, T.px(6), catHdrH, nil, secOpts)
        zones[#zones + 1] = {
            type = "cardSection", id = "out",
            x = x, y = curY, w = contentW, h = catHdrH, _scrolled = true,
        }
        curY = curY + catHdrH

        if not state.outCollapsed then
            for _, outDef in ipairs(entry.outputDefs) do
                local outData = {
                    name = outDef.name,
                    displayName = outDef.name,
                    iconTex = nil,
                    have = 1,
                    need = 1,
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
-- MAIN ORCHESTRATOR — renders the full 480px drawer layout
-- Called by CraftingTab.render() and BuildingTab.render().
-- ============================================================================

function CC.render(panel, win, x, y, w, h, state, config, data)
    local T = ZeD.T

    -- Load pins on first render (skip in readOnly — no pin system)
    if not config.readOnly then
        if not state.pinsLoaded then
            state.pinsLoaded = true
            CC.loadPins(win, config.pinKey, "_" .. config.prefix .. "Pins")
            state.pins = win["_" .. config.prefix .. "Pins"] or {}
        end
        -- Sync pins from win state
        state.pins = win["_" .. config.prefix .. "Pins"] or {}
    else
        state.pins = {}
    end

    -- Store category list for dropdown cycling
    state.categoryList = data.categories or {}

    -- S105 gamepad: cache last frame's zones BEFORE clearing, for scroll-follow.
    -- Delta gate keys on focused id; lookup against last-frame positions since
    -- this-frame positions aren't stamped yet.
    local lastZones = state.zones

    -- S105 gamepad: stash win ref on state so helpers (dropdown overlay) can
    -- resolve the live focused ring element without a signature change.
    state._focusWin = win
    -- choosing ingredients is offered only where the craft is built from the
    -- choice: the Craft tab (handcraft logic), unless a config says otherwise
    -- with pickIngredients
    local pickOn = config.pickIngredients
    if pickOn == nil then pickOn = (config.prefix == "craft") end
    state._pickOn = (pickOn and not config.readOnly) and true or false
    state._pickPrefix = config.prefix
    state._countKey = config.countKey

    -- S105 gamepad: resolve the currently-focused ring element id once per
    -- frame and stash on state so each render function paints its cue inline
    -- at zone-stamp time. Post-render cue pass was unreliable (stencil state
    -- at end-of-render can obscure the accent overlay). Inline paint
    -- guarantees cue sits in the correct paint-order position.
    -- Only while the mark may show (Focus.liveZone: this window has the focus and
    -- the controller is in use), so the other window or the mouse never keeps a
    -- row lit.
    state._gpFocusedId = nil
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if Focus and Focus.liveZone and Focus.liveElement then
            local fz = Focus.liveZone(win)
            -- S107: accept either window's tab-content zone. Craft + Build
            -- render in BOTH the Character and World windows; cue paint must
            -- pick up the focused element id regardless of which one owns it.
            if fz and (fz.zone == "charTabContent" or fz.zone == "worldTabContent") then
                local fe = Focus.liveElement(win)
                state._gpFocusedId = fe and fe.id or nil
            end
        end
    end

    -- Reset click zones each frame
    state.zones = {}

    -- Filter + sort (cached — only rebuild when dirty)
    if state.filterDirty then
        state.filteredCache, state.filteredCounts = CC.filterAndSort(data, state, config)
        state.filterDirty = false
        state._sectionsStale = true  -- sections depend on filteredCache
    end

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

    -- The band at the card's foot (Oct 30 2026, punch list 21); the panes take the
    -- height between
    local bandH = M.bandH()
    local panesH = h - (curY - y) - bandH

    -- The picked recipe: the card shows it, the band's amount and Craft / Build act on it
    local selRd = nil
    if state.selected then
        for _, rd in ipairs(data.recipes) do
            if rd.entry.name == state.selected then
                selRd = rd
                break
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

    -- The band, full card width under both panes
    CC.renderBand(panel, x, y + h - bandH, w, state, config, selRd)

    -- Category dropdown overlay (drawn LAST — on top of everything)
    if state.catDropdownOpen and state._ddGeo then
        CC.renderCatDropdownOverlay(panel, state, data)
    end

    -- The band's Sort and Show pop-up lists (they open upward from their boxes)
    if state.sortMenuOpen then CC.renderPopMenu(panel, state, config, "sort") end
    if state.showMenuOpen then CC.renderPopMenu(panel, state, config, "show") end

    -- Station dropdown overlay (crafting)
    if config.stations and ZeD.Stations then
        ZeD.Stations.drawDropdownFor(panel, state, win._playerObj, state._gpFocusedId, config.prefix)
    end

    -- S105 gamepad: scroll-follow with delta gate (Q99). Uses last-frame
    -- zones so positions are stable against this-frame scroll adjustment.
    -- Only fires for recipeRow (the scrollable element type). Section
    -- headers and card sections are at fixed content-Y so scroll-follow
    -- on them would be noisy without benefit.
    --
    -- S107: zone gate accepts char OR world tab content (Craft/Build live
    -- in both windows). Delta-gate field is prefix-namespaced so journal,
    -- craft, and build don't fight over the same `_lastPinned*` pin.
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
                                state.scroll:setScrollPos(newOff / span)
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

    -- S105 gamepad: use stashed focused id for dropdown row cue (the element ids
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

        if cat.count then
            local countStr = tostring(cat.count)
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

    panel:clearStencilRect()
end

-- ============================================================================
-- CLICK DISPATCHER — called from tab wrapper's onClick
-- ============================================================================

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
    for _, zone in ipairs(zones) do
        if x >= zone.x and x < zone.x + zone.w and y >= zone.y and y < zone.y + zone.h then

            if zone.type == "recipeRow" then
                CC.handleRecipeClick(state, zone.id)
                -- NOTE: no filterDirty here — selection doesn't change filter/
                -- sort criteria.  Re-sorting would move the selected recipe
                -- (Q43) and break toggle-off.
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

function CC.onMouseWheel(state, del, x, y, panelX, panelW)
    local T = ZeD.T
    if state.stDropdownOpen and ZeD.Stations then
        ZeD.Stations.dropdownWheel(state, del)
        return true
    end
    if state.sortMenuOpen or state.showMenuOpen then return true end
    -- Dropdown scroll takes priority when open
    if state.catDropdownOpen then
        local totalRows = #(state.categoryList or {})
        local maxScroll = math.max(0, totalRows - DD_MAX_VIS)
        -- PZ: positive del = scroll down (Q5)
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

-- The config buildFocusables passes on (it has none: the read-only list is the Journal's)
local RO_CFG, FULL_CFG = { readOnly = true }, {}

-- The open category list's rows as the controller's stops. B shuts the list; a choice or
-- B brings the focus back to the select (Oct 30 2026).
local function catRowFocusables(state, prefix)
    local T = ZeD.T
    local geo = state._ddGeo
    local cats = state.categoryList or {}
    local rowH = T.px(DD_ROW_H)
    local scrollOff = state.catDropdownScroll or 0
    local elements = {}
    local visCount = math.min(#cats - scrollOff, DD_MAX_VIS)
    local function shut()
        state.catDropdownOpen = false
        state.catDropdownScroll = 0
        state._gpReturnTo = "catDrop"
    end
    for vi = 1, visCount do
        local catIdx = scrollOff + vi
        local cat = cats[catIdx]
        if cat then
            elements[#elements + 1] = {
                x = geo.x, y = geo.y + (vi - 1) * rowH, w = geo.w, h = rowH,
                id = prefix .. ":cat:" .. tostring(cat.id),
                craftKind = "catRow",
                journalKind = (prefix == "jrecipe") and "jrecipeCat" or nil,
                catId = cat.id,
                onFocus = function(w, el) end,
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
    local cur = (kind == "show") and CC.showMode(state, cfg) or state.sort
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
    elements._menuRows = true   -- (Oct 30 2026, punch list 21 a-f: modal, FocusManager's _menuNav)
    return elements
end

-- ============================================================================
-- GAMEPAD FOCUSABLES BUILDER (S107)
-- ============================================================================
-- Shared focusable-list builder for ALL CraftingCore-driven tabs:
--   • Journal Recipes sub-tab on Character (readOnly, prefix="jrecipe")
--   • Crafting tab on World (full, prefix="craft")
--   • Building tab on World (full, prefix="build")
--
-- Synthesized from `state.zones`, the hit-zone list stamped each render by
-- the CC drawing pipeline. One focusable per interactive zone type. Mode
-- branching is implicit: alt mode adds altStrip_* and drops the band's
-- sortMenu / showMenu and the catDropdown (greyed there); readOnly mode
-- (Journal) has no recipeStar / action_* zones, so those branches never fire.
-- An open list (category, station, the band's Sort / Show) is the explicit
-- focus-lock case (matches CC.onClick, which hands it every click). Order:
-- the header strip, the body (list, card), the band (Oct 30 2026).
--
-- Args:
--   win        — the parent window (Char or World)
--   state      — CC state table (_jrecipeState / _craftState / _buildState)
--   prefix     — id namespace ("jrecipe" / "craft" / "build")
--   pinKey     — modData pin key ("ZeD_CraftPins" etc.) or nil for readOnly
--                (controls whether X on a recipeRow toggles its pin)
--   startAction — function(win, state) executed by A on the BUILD/CRAFT
--                button. nil for readOnly (no action_build zones emitted).
--
-- All onActivate closures capture `state` directly — the state-table identity
-- is stable across frames (created once via CC.createState() per tab), so
-- closures rebuilt each frame still target the same data.
--
-- recipeStar zones intentionally NOT emitted as focusables — pin handled via
-- X (onContextMenu) on the recipeRow itself per S107 design ruling.
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
                -- journalKind preserved on jrecipe path so legacy L/R / cue
                -- paint code that branches on it stays untouched. New craft/
                -- build paths read craftKind only.
                journalKind = (prefix == "jrecipe") and "jrecipeRow" or nil,
                recipeId = z.id,
                onFocus = function(w, el)
                    -- S107 QA: stash for L-from-card jump. Window-level
                    -- dispatch reads this to restore the recipe-row focus
                    -- when LEFT is pressed in the card pane (cone-nav alone
                    -- can't reliably hop back across the wide y delta + 2x
                    -- off-axis weight).
                    state._gpLastRecipeRowId = el.id
                end,
                onActivate = function(w, el)
                    CC.handleRecipeClick(state, el.recipeId)
                    -- S107 QA: signal pending card-jump. The window's
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
            -- X = pin/unpin (S107 design ruling). Skipped for readOnly journal.
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
                -- S113: A toggles expand/collapse (= LMB on header, mouse parity).
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
        elseif z.type == "sortMenu" or z.type == "showMenu" then
            -- the band's Sort / Show pop-up boxes (Oct 30 2026): A opens the list
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
                -- S113: A toggles expand/collapse (= LMB on header, mouse parity).
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
    -- a list or a select has just shut: the controller comes back to the box that opened it
    if state._gpReturnTo then
        local want = prefix .. ":" .. state._gpReturnTo
        for i, e in ipairs(elements) do
            if e.id == want then elements._focusIdx = i; break end
        end
        state._gpReturnTo = nil
    end
    if ZeD.Stations then ZeD.Stations.addLeaveCancel(elements, win, prefix) end
    return elements
end
