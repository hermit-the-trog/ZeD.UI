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
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"

ZeD = ZeD or {}
ZeD.CraftingCore = ZeD.CraftingCore or {}

local CC = ZeD.CraftingCore
local M  = ZeD.Molecules

-- ============================================================================
-- CONSTANTS (from CRAFTING_SPEC.md §8 — frozen)
-- ============================================================================

CC.DRAWER_W        = 480
CC.PANE_W_SOLO     = 480
CC.PANE_W_SPLIT    = 240
CC.ROW_H           = 24
CC.ACT_STRIP_H     = 42
CC.HEADER_H         = (ZeD.Spacing and ZeD.Spacing.tabHeaderH) or 37  -- standard ZeD drawer-header strip
CC.STRIP_H          = 20    -- sort strip doubles as column header row
CC.MAX_PINS        = 8
CC.ANIM_DURATION   = 0.28  -- pane split animation in seconds

-- Throttle intervals (frames)
local CONTAINER_INTERVAL = 90

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
        category = string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2)
    else
        category = "Miscellaneous"
    end

    return category
end

-- ============================================================================
-- FILTERING + SORTING — parameterized by filter modes
-- ============================================================================

-- SHOW: "ready" | "known" | "all" (older state kept only showAll: on = all, off = known;
-- the Journal's read-only list has no Ready)
local SHOW_LABEL = { ready = "Ready", known = "Known", all = "All" }
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
        reqCollapsed     = false,      -- REQUIRED section collapsed
        outCollapsed     = false,      -- OUTPUTS section collapsed
        catDropdownOpen  = false,      -- category dropdown expanded
        catDropdownScroll = 0,        -- dropdown scroll offset (rows)
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
    state.qty = 1
    state.splitTarget = 1
    -- Exit alt mode if active
    if state.altSlotName then CC.exitAltMode(state) end
    -- Reset card scroll
    state.cardScroll:setScrollPos(0)
end

function CC.closeCraft(state)
    state.selected = nil
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
-- RENDERING — Static Header (category dropdown + search)
-- ============================================================================

function CC.renderStaticHeader(panel, x, y, w, state, config, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local zones = state.zones
    local pfx = (config and config.prefix) or "jrecipe"
    local ST = config and config.stations and ZeD.Stations or nil
    local headerH = T.px(CC.HEADER_H)  -- 37px single row

    local pad = T.px(6)
    local gap = T.px(6)
    local ddH = T.inputH  -- match search field height
    local ddX, ddY, ddW, searchX, searchY, searchW

    if ST then
        -- Crafting: two rows. STATION and CATEGORY selects side by side, the
        -- search field full width under them.
        local selW = math.floor((w - pad * 2 - gap) / 2)
        local stX, rowY = x + pad, y + pad
        ddX, ddY = stX + selW + gap, rowY
        ddW = w - pad * 2 - gap - selW
        searchX, searchY, searchW = x + pad, rowY + ddH + gap, w - pad * 2
        headerH = pad + ddH + gap + ddH + pad

        local player = win and win._playerObj
        local cur = player and ST.current(player) or nil
        local mx, my = panel:getMouseX(), panel:getMouseY()
        local hov = (not state.catDropdownOpen) and (not state.stDropdownOpen)
            and mx >= stX and mx < stX + selW and my >= rowY and my < rowY + ddH
        ST.drawSelect(panel, stX, rowY, selW, ddH, "STATION", cur and cur.name or "Hand",
            cur ~= nil, state._gpFocusedId == (pfx .. ":stDrop"), hov)
        zones[#zones + 1] = { type = "stationDropdown", x = stX, y = rowY, w = selW, h = ddH }
        state._stGeo = { x = stX, y = rowY + ddH, w = selW }
    else
        -- Row 1: 37px — Dropdown LEFT (~45%), Search RIGHT, 6px gap between
        ddW = math.floor((w - pad * 2 - gap) * 0.45)
        ddX = x + pad
        ddY = y + math.floor((headerH - ddH) / 2)      -- vertically centered in 37px
        searchX, searchY = ddX + ddW + gap, ddY
        searchW = w - pad * 2 - gap - ddW
    end

    -- Position the actual ZeD_SearchField ISPanel child
    local searchKey = "_" .. config.prefix .. "Search"
    local searchField = win[searchKey]
    if searchField then
        searchField:setX(searchX)
        searchField:setY(searchY)
        searchField:setWidth(searchW)
        searchField:setHeight(ddH)
        -- Update placeholder based on mode
        searchField.placeholder = state.altSlotName and "Filter alternatives..." or "Search recipes..."
        -- The field is a child panel and paints after the tab: with a dropdown
        -- open over the search row, hide it for the frame (the window's
        -- prerender shows it again).
        if ST and (state.catDropdownOpen or state.stDropdownOpen) then
            searchField:setVisible(false)
        end
    end

    -- Category dropdown (drawn manually — ZeD_Dropdown as child panel is future work)
    if state.altSlotName then
        -- Alt mode: frozen dropdown showing "Compatible"
        local ac = T.accent
        panel:drawRect(ddX, ddY, ddW, ddH, 0.08, ac.r, ac.g, ac.b)
        panel:drawRectBorder(ddX, ddY, ddW, ddH, ac.a * 0.3, ac.r, ac.g, ac.b)
        local frozenLabel = "Compatible"
        panel:drawText(frozenLabel, ddX + T.px(6), ddY + math.floor((ddH - tm:getFontHeight(T.fontF2)) / 2),
            ac.r, ac.g, ac.b, 0.8, T.fontF2)
    else
        local activeCatLabel = state.activeCat == "all" and "-- All --" or state.activeCat
        if #activeCatLabel > 0 then
            activeCatLabel = string.upper(string.sub(activeCatLabel, 1, 1)) .. string.sub(activeCatLabel, 2)
        end
        if ST then
            local mx, my = panel:getMouseX(), panel:getMouseY()
            local hov = (not state.catDropdownOpen) and (not state.stDropdownOpen)
                and mx >= ddX and mx < ddX + ddW and my >= ddY and my < ddY + ddH
            ST.drawSelect(panel, ddX, ddY, ddW, ddH, "CATEGORY", activeCatLabel, false,
                state._gpFocusedId == (pfx .. ":catDrop"), hov)
        else
            -- Normal dropdown: show active category with arrow
            local bg = T.surf2
            panel:drawRect(ddX, ddY, ddW, ddH, bg.a, bg.r, bg.g, bg.b)
            panel:drawRectBorder(ddX, ddY, ddW, ddH, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)

            local catTextY = ddY + math.floor((ddH - tm:getFontHeight(T.fontF2)) / 2)
            panel:drawText(activeCatLabel, ddX + T.px(6), catTextY, T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)

            -- Down arrow
            local arrowSz = T.px(5)
            local arrowX = ddX + ddW - arrowSz - T.px(8)
            local arrowY = ddY + math.floor((ddH - arrowSz) / 2)
            A.drawTriangleDown(panel, arrowX, arrowY, arrowSz, T.textSec)

            -- S105 gamepad: inline cue paint for focused category dropdown button.
            if state._gpFocusedId == (pfx .. ":catDrop") then
                local ac = T.accent
                panel:drawRect(ddX, ddY, ddW, ddH, 0.55, ac.r, ac.g, ac.b)
            end
        end

        zones[#zones + 1] = { type = "catDropdown", x = ddX, y = ddY, w = ddW, h = ddH }

        -- Store geometry for deferred dropdown overlay render
        state._ddGeo = { x = ddX, y = ddY + ddH, w = ddW }
    end

    -- Bottom rule on header row
    A.drawDividerH(panel, x, y + headerH - T.px(1), w, true)

    return headerH  -- 37px (62px with the station row); sort strip renders below
end

-- ============================================================================
-- RENDERING — Contextual Strip (sort vs alt-back, 24px)
-- ============================================================================

function CC.renderStrip(panel, x, y, w, state, config)
    local T = ZeD.T
    local zones = state.zones
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if state.catDropdownOpen or state.stDropdownOpen then mx, my = -1, -1 end  -- suppress hover when a dropdown is open

    -- Detect hover zone from previous frame's zones (strip zones persist between frames)
    local stripH = T.px(CC.STRIP_H)
    local hoverZone = nil
    if my >= y and my < y + stripH and mx >= x and mx < x + w then
        for _, z in ipairs(zones) do
            if z.y == y and mx >= z.x and mx < z.x + z.w then
                -- Extract the zone id (strip zones are prefixed)
                if z.type and z.type:find("altStrip_") then
                    hoverZone = z.type:sub(10)  -- strip "altStrip_" prefix
                elseif z.type == "sortMode" then
                    hoverZone = z.id
                elseif z.type == "showAllToggle" then
                    hoverZone = "toggle"
                end
                break
            end
        end
    end

    if state.altSlotName then
        -- Alt mode strip
        local altData = state.altItems or { totalOwned = 0, totalAll = 0 }
        local h, stripZones = M.drawAltBackStrip(panel, x, y, w,
            state.altSlotName, altData.totalOwned, altData.totalAll,
            state.ownedOnly, hoverZone)
        for _, z in ipairs(stripZones) do
            z.type = "altStrip_" .. z.id
            zones[#zones + 1] = z
        end
        return h
    else
        -- Sort strip (readOnly hides freq/recent — no craft counts)
        local modes
        if config.readOnly then
            modes = {
                { id = "craftable", label = "Craftable" },
                { id = "known",     label = "Known" },
                { id = "name",      label = "Name" },
            }
        else
            modes = {
                { id = "craftable", label = "Craftable" },
                { id = "known",     label = "Known" },
                { id = "name",      label = "Name" },
                { id = "freq",      label = "Freq" },
                { id = "recent",    label = "Recent" },
            }
        end
        local show = CC.showMode(state, config)
        local toggle = { label = "Show: " .. SHOW_LABEL[show], active = show ~= "known" }
        local h, stripZones = M.drawSortStrip(panel, x, y, w,
            modes, state.sort, toggle, hoverZone)
        -- S105 gamepad: inline cue paint for focused sort/showAll button.
        local pfx = (config and config.prefix) or "jrecipe"
        local fid = state._gpFocusedId
        for _, z in ipairs(stripZones) do
            if z.type == "sort" then
                z.type = "sortMode"
            elseif z.type == "toggle" then
                z.type = "showAllToggle"
            end
            if fid then
                local zid = nil
                if     z.type == "sortMode"      then zid = pfx .. ":sort:" .. tostring(z.id)
                elseif z.type == "showAllToggle" then zid = pfx .. ":showAll"
                end
                if zid and zid == fid then
                    local ac = ZeD.T.accent
                    panel:drawRect(z.x, z.y, z.w, z.h, 0.55, ac.r, ac.g, ac.b)
                end
            end
            zones[#zones + 1] = z
        end
        return h
    end
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
                    id = "pinned", label = "Pinned", color = T.accent,
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
                    id = "freq", label = "Frequently Used", color = T.warning,
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
        local allLabel = (#(state.search or "") > 0) and "Results" or "All Recipes"
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
    if state.catDropdownOpen or state.stDropdownOpen then mx, my = -1, -1 end
    local rowIdx = 0

    -- Reusable row data table (zero alloc per row per frame)
    local rowData = { name = "", displayName = "", iconTex = nil, status = "can" }

    -- Visible area bounds for culling (stencil clips pixels but draw calls are expensive)
    local visTop = y
    local visBot = y + h

    for _, sec in ipairs(sections) do
        -- Section header — always stamp zone (gamepad cone-nav targets off-
        -- screen disclosures; scroll-follow brings them into view). Draw only
        -- when within visible rect.
        local hdrVisible = curY + catHdrH > visTop and curY < visBot
        if hdrVisible then
            local headerHover = mx >= x and mx < x + contentW and my >= curY and my < curY + catHdrH
            M.drawSectionHeader(panel, x + T.px(6), curY, contentW - T.px(6), sec.label,
                #sec.items, not sec.collapsed, headerHover, T.fontF1, true, T.px(6), catHdrH)
            -- S105 gamepad: inline cue paint — accent overlay when focused.
            local pfx = (config and config.prefix) or "jrecipe"
            if state._gpFocusedId == (pfx .. ":section:" .. tostring(sec.id)) then
                local ac = T.accent
                panel:drawRect(x, curY, contentW, catHdrH, 0.55, ac.r, ac.g, ac.b)
            end
        end
        zones[#zones + 1] = {
            type = "sectionHeader", id = sec.id,
            x = x, y = curY, w = contentW, h = catHdrH,
            _scrolled = true,
        }
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

                    M.drawRecipeRow(panel, x, curY, contentW, rowData,
                        isSelected, rowHover, isPinned, fc, rowIdx)

                    -- S105 gamepad: inline cue paint — accent overlay when
                    -- this row is the focused ring element. Off-screen rows
                    -- skip cue paint (zone is stamped but no draw); next
                    -- frame's scroll-follow brings the row into view and the
                    -- cue paints normally.
                    local pfx = (config and config.prefix) or "jrecipe"
                    if state._gpFocusedId == (pfx .. ":row:" .. tostring(name)) then
                        local ac = T.accent
                        panel:drawRect(x, curY, contentW, ROW_H, 0.55, ac.r, ac.g, ac.b)
                    end
                end

                -- Click zones (readOnly: full row, no star) — stamped UNCONDITIONALLY.
                if config.readOnly then
                    zones[#zones + 1] = {
                        type = "recipeRow", id = name,
                        x = x, y = curY, w = contentW, h = ROW_H,
                        _scrolled = true,
                    }
                else
                    zones[#zones + 1] = {
                        type = "recipeRow", id = name,
                        x = x, y = curY, w = contentW - T.px(18), h = ROW_H,
                        _scrolled = true,
                    }
                    zones[#zones + 1] = {
                        type = "recipeStar", id = name,
                        x = x + contentW - T.px(18), y = curY, w = T.px(18), h = ROW_H,
                        _scrolled = true,
                    }
                end
                curY = curY + ROW_H
            end
        end
    end

    panel:clearStencilRect()

    -- Draw scrollbar
    if needsScroll then
        scroll:draw(panel)
    end

    return h
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

    -- Owned section
    if #owned > 0 then
        local headerStr = "OWNED"
        M.drawSectionHeader(panel, x + T.px(6), curY, contentW - T.px(6), headerStr, #owned, true, false, T.fontF1, true, T.px(6), catHdrH)
        curY = curY + catHdrH

        for _, alt in ipairs(owned) do
            rowIdx = rowIdx + 1
            M.drawAltRow(panel, x, curY, contentW, alt, true, rowIdx)
            curY = curY + ROW_H
        end
    end

    -- Other section
    if #other > 0 then
        local headerStr = "OTHER COMPATIBLE"
        M.drawSectionHeader(panel, x + T.px(6), curY, contentW - T.px(6), headerStr, #other, true, false, T.fontF1, true, T.px(6), catHdrH)
        curY = curY + catHdrH

        for _, alt in ipairs(other) do
            rowIdx = rowIdx + 1
            M.drawAltRow(panel, x, curY, contentW, alt, false, rowIdx)
            curY = curY + ROW_H
        end
    end

    -- Empty state
    if #owned == 0 and #other == 0 then
        local msg = "No alternatives found"
        local msgW = tm:MeasureStringX(T.fontF1, msg)
        local dc = T.textDim
        panel:drawText(msg, x + math.floor((contentW - msgW) / 2), curY + T.px(6),
            dc.r, dc.g, dc.b, 0.5, T.fontF1)
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
    local actionH = config.readOnly and 0 or T.px(CC.ACT_STRIP_H)
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
    local needH = 0
    if stNeed then
        needH = T.px(8) + T.fontF2H + T.px(2) + T.fontF2H + T.px(8)
        if stNear then needH = needH + T.px(6) + T.px(22) end
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
        panel:drawTextureScaledAspect(entry.iconTex, iconX + T.px(2), iconY + T.px(2), iconSz - T.px(4), iconSz - T.px(4), 1, 1, 1, 1)
    end

    -- Name (F2 13px, accent)
    local nameX = iconX + iconSz + T.px(6)
    local nameFont = T.fontF2
    local nameStr = CC.truncText(entry.displayName, nameFont, contentW - (nameX - x) - T.px(6))
    panel:drawText(nameStr, nameX, curY + T.px(6), T.accent.r, T.accent.g, T.accent.b, 1, nameFont)

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
    local learnedStr = isAccessible and "KNOWN" or "UNKNOWN"
    local learnedV = isAccessible and "positive" or "danger"
    local bw = A.drawBadge(panel, learnedStr, chipX, curY, learnedV)
    chipX = chipX + bw + T.px(4)

    -- Surface requirement (pre-baked during catalog build)
    local needsSurface = entry.needSurface or false
    if needsSurface then
        bw = A.drawBadge(panel, "SURFACE", chipX, curY, "warning")
        chipX = chipX + bw + T.px(4)
    end

    -- Craft time (getTime returns seconds)
    if rd.craftTime and rd.craftTime > 0 then
        local t = rd.craftTime
        local timeStr
        if t >= 60 then
            timeStr = string.format("%dm%ds", math.floor(t / 60), math.floor(t % 60))
        else
            timeStr = string.format("%ds", math.floor(t))
        end
        bw = A.drawBadge(panel, timeStr, chipX, curY, "accent", nil, nil, true)
        chipX = chipX + bw + T.px(4)
    end

    -- Station chip: what this recipe needs (Hand mode) or where it is made
    if stNeed then
        A.drawBadge(panel, "NEEDS " .. (stNeed.short or "STATION"), chipX, curY, "danger")
    elseif rd.boundShort then
        A.drawBadge(panel, rd.boundShort, chipX, curY, nil)
    end

    curY = curY + chipH + T.px(4)

    if stNeed then
        local bx, bw2 = x + T.px(10), contentW - T.px(20)
        local bh = needH - T.px(8)
        local ac = T.accent
        panel:drawRect(bx, curY, bw2, bh, 0.12, ac.r, ac.g, ac.b)
        panel:drawRectBorder(bx, curY, bw2, bh, ac.a or 1, ac.r, ac.g, ac.b)
        local ty = curY + T.px(8)
        local line1 = "Needs " .. ZeD.Stations.withArticle(stNeed.label) .. "."
        panel:drawText(CC.truncText(line1, T.fontF2, bw2 - T.px(16)), bx + T.px(8), ty,
            T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
        ty = ty + T.fontF2H + T.px(2)
        local line2 = stNear and ("The nearest is " .. string.lower(ZeD.Stations.tilesText(stNear.dist)) .. " away.")
            or ("None within " .. tostring(ZeD.Stations.REACH) .. " tiles.")
        panel:drawText(CC.truncText(line2, T.fontF2, bw2 - T.px(16)), bx + T.px(8), ty,
            T.textSec.r, T.textSec.g, T.textSec.b, T.textSec.a, T.fontF2)
        ty = ty + T.fontF2H
        if stNear then
            ty = ty + T.px(6)
            local label = "Use " .. string.lower(stNear.name or "station")   -- a button: sentence case
            local btnH = T.px(22)
            local btnW = math.min(bw2 - T.px(16), ZeD.TM:MeasureStringX(T.fontF3, label) + T.px(24))
            M.drawButton(panel, bx + T.px(8), ty, btnW, btnH, label, "primary")
            local pfx = (config and config.prefix) or "jrecipe"
            if state._gpFocusedId == (pfx .. ":stUse") then
                panel:drawRect(bx + T.px(8), ty, btnW, btnH, 0.55, ac.r, ac.g, ac.b)
            end
            zones[#zones + 1] = { type = "stationUse", station = stNear,
                x = bx + T.px(8), y = ty, w = btnW, h = btnH, _scrolled = true }
        end
        curY = curY + needH
    end

    local catHdrH = T.sp.catHdrH  -- 15px, same as inventory category separators
    local mx, my = panel:getMouseX(), panel:getMouseY()   -- hoisted: the HOW TO LEARN hover test below used these before they were declared (nil globals)

    -- Learn info section (readOnly + not accessible — renders ABOVE required)
    if showLearnSection then
        local learnLabel = "HOW TO LEARN"
        local learnHdrHover = mx >= x and mx < x + contentW and my >= curY and my < curY + catHdrH
        M.drawSectionHeader(panel, x + T.px(6), curY, contentW - T.px(6), learnLabel,
            nil, true, learnHdrHover, T.fontF1, false, T.px(6), catHdrH)
        curY = curY + catHdrH

        -- Skill requirements
        if rd.skills and #rd.skills > 0 then
            for _, sk in ipairs(rd.skills) do
                local skColor = sk.met and T.positive or T.danger
                local dotSz = T.px(6)
                A.drawStatusDot(panel, x + T.px(6), curY + math.floor((ROW_H - dotSz) / 2), skColor, dotSz)
                local skStr = sk.name .. " Level " .. tostring(sk.required)
                panel:drawText(skStr, x + T.px(6) + dotSz + T.px(4),
                    curY + math.floor((ROW_H - tm:getFontHeight(T.fontF2)) / 2),
                    T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
                -- Player level right-aligned
                local lvlStr = tostring(sk.playerLevel) .. "/" .. tostring(sk.required)
                local lvlColor = sk.met and T.positive or T.danger
                A.drawTextRight(panel, lvlStr, x + contentW - T.px(6),
                    curY + math.floor((ROW_H - tm:getFontHeight(T.fontF3)) / 2),
                    T.fontF3, lvlColor)
                curY = curY + ROW_H
            end
        end

        -- needToBeLearn hint
        if entry.needLearn then
            local hintStr = "Find recipe magazine or schematic"
            panel:drawText(hintStr, x + T.px(6),
                curY + math.floor((ROW_H - tm:getFontHeight(T.fontF5)) / 2),
                T.textSec.r, T.textSec.g, T.textSec.b, 0.7, T.fontF5)
            curY = curY + ROW_H
        end

        curY = curY + T.px(4)
    end

    -- Required Items section (collapsible disclosure, matches inventory catHdrH)
    local reqCount = #(rd.ingredients or {})
    local haveCount = reqCount - (rd.missingCount or 0)
    local secLabel = "REQUIRED"
    local reqHdrHover = mx >= x and mx < x + contentW and my >= curY and my < curY + catHdrH
    M.drawSectionHeader(panel, x + T.px(6), curY, contentW - T.px(6), secLabel,
        haveCount .. "/" .. reqCount, not state.reqCollapsed, reqHdrHover, T.fontF1, true, T.px(6), catHdrH)
    -- S105 gamepad: inline cue paint for focused card section header (REQUIRED).
    do
        local pfx = (config and config.prefix) or "jrecipe"
        if state._gpFocusedId == (pfx .. ":card:req") then
            local ac = T.accent
            panel:drawRect(x, curY, contentW, catHdrH, 0.55, ac.r, ac.g, ac.b)
        end
    end
    zones[#zones + 1] = {
        type = "cardSection", id = "req",
        x = x, y = curY, w = contentW, h = catHdrH, _scrolled = true,
    }
    curY = curY + catHdrH

    -- Slot rows (hidden when collapsed)
    if not state.reqCollapsed then
        for idx, ing in ipairs(rd.ingredients or {}) do
            local slotData = {
                name = ing.name,
                displayName = ing.name,
                iconTex = ing.iconTex,
                have = ing.have,
                need = ing.need,
                altCount = ing.altCount,
                tag = ing.tag,
                isTool = ing.isTool,
                isKeep = ing.isKeep,
            }
            local isSlotSelected = (state.altSlotName == ing.name and state.altSlotIdx == idx)
            local slotHover = mx >= x and mx < x + contentW and my >= curY and my < curY + ROW_H

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
        M.drawSectionHeader(panel, x + T.px(6), curY, contentW - T.px(6), "OUTPUTS",
            outCount, not state.outCollapsed, outHdrHover, T.fontF1, true, T.px(6), catHdrH)
        -- S105 gamepad: inline cue paint for focused card section header (OUTPUTS).
        do
            local pfx = (config and config.prefix) or "jrecipe"
            if state._gpFocusedId == (pfx .. ":card:out") then
                local ac = T.accent
                panel:drawRect(x, curY, contentW, catHdrH, 0.55, ac.r, ac.g, ac.b)
            end
        end
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

    -- Action strip (pinned to bottom, hidden in readOnly)
    if not config.readOnly then
        local actionY = y + h - actionH
        local maxQty = rd.maxBatchQty or 1
        if maxQty < 0 then maxQty = 0 end
        state._maxQty = maxQty  -- cache for click handler
        -- Clamp qty to maxQty (may have changed since last frame)
        if state.qty > maxQty and maxQty > 0 then state.qty = maxQty end
        if state.qty < 1 then state.qty = 1 end
        local canCraft = rd.status == "craftable" and rd.learned ~= false and maxQty > 0
        local label = config.buildLabel or "CRAFT"
        local _, actionZones = M.drawCraftActionStrip(panel, x, actionY, w,
            state.qty, maxQty, canCraft, nil, label)
        for _, z in ipairs(actionZones) do
            z.type = "action_" .. z.id
            zones[#zones + 1] = z
        end
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

    -- S105 gamepad: resolve the currently-focused ring element id once per
    -- frame and stash on state so each render function paints its cue inline
    -- at zone-stamp time. Post-render cue pass was unreliable (stencil state
    -- at end-of-render can obscure the accent overlay). Inline paint
    -- guarantees cue sits in the correct paint-order position.
    state._gpFocusedId = nil
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if Focus and Focus.getFocusedZone and Focus.getFocusedElement then
            local fz = Focus.getFocusedZone(win)
            -- S107: accept either window's tab-content zone. Craft + Build
            -- render in BOTH the Character and World windows; cue paint must
            -- pick up the focused element id regardless of which one owns it.
            if fz and (fz.zone == "charTabContent" or fz.zone == "worldTabContent") then
                local fe = Focus.getFocusedElement(win)
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

    -- Static header (cat dropdown + search; crafting adds the station select)
    local headerH = CC.renderStaticHeader(panel, x, curY, w, state, config, win)
    curY = curY + headerH

    -- Station band (Craft tab bound to a bench)
    if config.stations and ZeD.Stations and win._playerObj then
        local cur = ZeD.Stations.current(win._playerObj)
        if cur then
            curY = curY + ZeD.Stations.drawBand(panel, x, curY, w, cur, win._playerObj)
        end
    end

    -- Contextual strip
    local stripH = CC.renderStrip(panel, x, curY, w, state, config)
    curY = curY + stripH

    -- Remaining height for panes
    local panesH = h - (curY - y)

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
    if cardW > 0 and state.selected then
        local cardX = x + listW
        -- Find selected recipe data
        local selRd = nil
        for _, rd in ipairs(data.recipes) do
            if rd.entry.name == state.selected then
                selRd = rd
                break
            end
        end
        if selRd then
            -- Vertical divider between panes
            panel:drawRect(cardX, curY, T.px(1), panesH, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
            CC.renderCraftCard(panel, cardX + T.px(1), curY, cardW - T.px(1), panesH, state, config, selRd, win._playerObj)
        end
    end

    -- Category dropdown overlay (drawn LAST — on top of everything)
    if state.catDropdownOpen and state._ddGeo then
        CC.renderCatDropdownOverlay(panel, state, data)
    end

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

local DD_ROW_H   = 20
local DD_MAX_VIS = 14  -- max visible rows before scroll kicks in

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

    -- Override any active stencil with the dropdown's own region
    panel:setStencilRect(ddX, ddY, ddW, listH)

    -- Backdrop (opaque surface)
    local bg = T.surf1
    panel:drawRect(ddX, ddY, ddW, listH, 1, bg.r, bg.g, bg.b)

    local mx, my = panel:getMouseX(), panel:getMouseY()

    -- S105 gamepad: use stashed focused id for dropdown row cue.
    local gpFocusedId = state._gpFocusedId

    -- Draw visible rows (offset by scroll)
    for vi = 0, visibleCount - 1 do
        local catIdx = scrollOff + vi + 1
        if catIdx > totalRows then break end
        local cat = cats[catIdx]
        local ry = ddY + vi * rowH
        local isActive = (cat.id == state.activeCat)
        local isHover = mx >= ddX and mx < ddX + ddW and my >= ry and my < ry + rowH
        local isGpFocused = gpFocusedId and gpFocusedId == ("jrecipe:cat:" .. tostring(cat.id))

        if isActive then
            panel:drawRect(ddX, ry, ddW, rowH, 0.15, T.accent.r, T.accent.g, T.accent.b)
        elseif isHover then
            local hv = T.hover
            panel:drawRect(ddX, ry, ddW, rowH, hv.a, hv.r, hv.g, hv.b)
        end
        if isGpFocused then
            local ac = T.accent
            panel:drawRect(ddX, ry, ddW, rowH, 0.55, ac.r, ac.g, ac.b)
        end

        local label = cat.full or cat.label or cat.id
        local tc = isActive and T.accent or T.text
        local textY = ry + math.floor((rowH - tm:getFontHeight(font)) / 2)
        panel:drawText(label, ddX + T.px(6), textY, tc.r, tc.g, tc.b, tc.a or 1, font)

        if cat.count then
            local countStr = tostring(cat.count)
            A.drawTextRight(panel, countStr, ddX + ddW - T.px(6), textY, T.fontF1, T.textDim)
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
                return true
            end
        end

        -- Click outside dropdown — close it, consume the click
        state.catDropdownOpen = false
        state.catDropdownScroll = 0
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

            elseif zone.type == "sortMode" then
                state.sort = zone.id
                state.filterDirty = true
                return true

            elseif zone.type == "showAllToggle" then
                CC.cycleShow(state, config)
                return true

            elseif zone.type == "catDropdown" then
                state.catDropdownOpen = not state.catDropdownOpen
                state.stDropdownOpen = false
                return true

            elseif zone.type == "stationDropdown" then
                state.stDropdownOpen = not state.stDropdownOpen
                state.stDropdownScroll = 0
                state.catDropdownOpen = false
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

            elseif zone.type == "action_dec" then
                state.qty = math.max(1, state.qty - 1)
                return true

            elseif zone.type == "action_inc" then
                local maxQ = state._maxQty or 99
                state.qty = math.min(maxQ, state.qty + 1)
                return true

            elseif zone.type == "action_build" then
                -- Delegate to tab-specific startAction
                if config.startAction then
                    config.startAction(win, state)
                end
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
-- branching is implicit: alt mode emits altStrip_* in place of sortMode/
-- showAllToggle/catDropdown; readOnly mode (Journal) omits recipeStar/
-- slotAlt/altStrip_*/action_* zones entirely so those branches never fire.
-- Dropdown-open is the one explicit focus-lock case (matches CC.onClick
-- which consumes ALL clicks while the dropdown overlay is up).
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

    -- Dropdown open: focus locked to dropdown rows. DD_ROW_H = 20 / DD_MAX_VIS
    -- = 14 mirror the constants at the top of this file (kept literal here so
    -- the function can be moved or extracted without an internal-constant dep).
    if state.catDropdownOpen and state._ddGeo then
        local geo = state._ddGeo
        local cats = state.categoryList or {}
        local rowH = T.px(20)
        local scrollOff = state.catDropdownScroll or 0
        local elements = {}
        local visCount = math.min(#cats - scrollOff, 14)
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
                        state.catDropdownOpen = false
                        state.catDropdownScroll = 0
                        state.filterDirty = true
                        if state.scroll and state.scroll.setScrollPos then
                            state.scroll:setScrollPos(0)
                        end
                    end,
                }
            end
        end
        return elements
    end

    local zones = state.zones or {}
    local elements = {}
    for _, z in ipairs(zones) do
        if z.type == "recipeRow" then
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
        elseif z.type == "sectionHeader" then
            elements[#elements + 1] = {
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
        elseif z.type == "sortMode" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":sort:" .. tostring(z.id),
                craftKind = "sort",
                journalKind = (prefix == "jrecipe") and "jrecipeSort" or nil,
                sortId = z.id,
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    state.sort = el.sortId
                    state.filterDirty = true
                end,
            }
        elseif z.type == "showAllToggle" then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = prefix .. ":showAll",
                craftKind = "showAll",
                journalKind = (prefix == "jrecipe") and "jrecipeShowAll" or nil,
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    CC.cycleShow(state, config)
                end,
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
                    if startAction then startAction(w, state) end
                end,
            }
        end
    end
    if ZeD.Stations then ZeD.Stations.addLeaveCancel(elements, win, prefix) end
    return elements
end
