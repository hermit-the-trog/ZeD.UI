-- ZeD-UI/42/media/lua/client/ZeD/CraftingTab.lua
-- ============================================================================
-- CRAFTING TAB — Thin wrapper over CraftingCore.
-- Owns: catalog building (eager, game start), gatherData (skill+learn checks),
-- gatherDetail (batch qty via HandcraftLogic), startCraft (HandcraftLogic exec).
-- All rendering, filtering, pin management, state machine → CraftingCore.
--
-- Stations (HOOK_MAP rows 1, 14): the tab works by hand or at a station. In
-- Hand mode, recipes that need a station keep their place with the station
-- as a tag and are not craftable; bound to a bench, the list is the bench's
-- recipes and CRAFT works at it (vanilla's lock and walk-to); bound to a
-- drying rack or an oven the tab shows that machine's own view instead.
-- ============================================================================

require "ZeD/CraftingCore"
require "ZeD/Stations"

ZeD = ZeD or {}
ZeD.CraftingTab = {}

local CC = ZeD.CraftingCore

-- ============================================================================
-- STATIC RECIPE CATALOG — built ONCE at game load via OnGameStart event.
-- Pre-bakes all expensive Java bridge calls so per-frame work is pure Lua.
-- ============================================================================

local _catalog       = nil   -- grouped by category
local _flatRecipes   = nil   -- ordered flat list
local _categories    = nil   -- category bar entries
local _recipeByName  = nil   -- name → entry lookup

local function buildCatalog()
    if _catalog then return end

    local allRecipes = ScriptManager.instance:getAllCraftRecipes()
    if not allRecipes then
        _catalog = {}
        _flatRecipes = {}
        _categories = { { id = "all", label = "All", full = "All", count = 0 } }
        _recipeByName = {}
        return
    end

    local byCat = {}
    local flat = {}
    local byName = {}

    for i = 0, allRecipes:size() - 1 do
        local recipe = allRecipes:get(i)

        -- Resolve category (getCategory > skill > Miscellaneous)
        local skillName = nil
        local requiredLevel = 0
        if recipe:getRequiredSkillCount() > 0 then
            local ok, rs = pcall(function() return recipe:getRequiredSkill(0) end)
            if ok and rs then
                skillName = tostring(rs:getPerk():getName())
                requiredLevel = rs:getLevel()
            end
        end

        local category = CC.resolveCategory(recipe, skillName)
        local catKey = string.lower(category)

        if not byCat[catKey] then
            byCat[catKey] = { label = category, recipes = {} }
        end

        -- Pre-bake using CraftingCore helpers
        local inputDefs  = CC.prebakeInputs(recipe)
        local outputDefs = CC.prebakeOutputs(recipe)
        local skillDefs  = CC.prebakeSkills(recipe)

        -- Pre-bake batch flag
        local allowBatch = false
        pcall(function() allowBatch = recipe:isAllowBatchCraft() end)

        -- Pre-bake needToBeLearn flag (force Lua boolean)
        local needLearn = false
        pcall(function() if recipe:needToBeLearn() then needLearn = true end end)

        -- Pre-bake icon texture
        local iconTex = nil
        pcall(function() iconTex = recipe:getIconTexture() end)

        -- Pre-bake description (check method exists before calling — Kahlua logs
        -- Java exceptions from pcall even when caught, spamming the console)
        local description = nil
        if recipe.getDescription then
            pcall(function()
                local d = recipe:getDescription()
                if d and d ~= "" then description = tostring(d) end
            end)
        end

        -- Pre-bake surface requirement (same guard)
        local needSurface = false
        if recipe.isNeedSurface then
            pcall(function() if recipe:isNeedSurface() then needSurface = true end end)
        end

        -- Station this recipe needs (nil for hand recipes)
        local stationInfo = ZeD.Stations and ZeD.Stations.recipeStation(recipe) or nil

        local entry = {
            stationInfo   = stationInfo,
            heatStation   = stationInfo and stationInfo.heat or false,
            recipe        = recipe,
            displayName   = recipe:getTranslationName() or recipe:getName(),
            name          = recipe:getName(),
            category      = category,
            requiredLevel = requiredLevel,
            skillName     = skillName,
            inputDefs     = inputDefs,
            outputDefs    = outputDefs,
            skillDefs     = skillDefs,
            allowBatch    = allowBatch,
            needLearn     = needLearn,
            iconTex       = iconTex,
            description   = description,
            needSurface   = needSurface,
        }

        local list = byCat[catKey].recipes
        list[#list + 1] = entry
        flat[#flat + 1] = entry
        byName[entry.name] = entry
    end

    -- Sort groups
    _catalog = {}
    for _, group in pairs(byCat) do
        table.sort(group.recipes, function(a, b)
            if a.requiredLevel ~= b.requiredLevel then return a.requiredLevel < b.requiredLevel end
            return a.displayName < b.displayName
        end)
        _catalog[#_catalog + 1] = group
    end
    table.sort(_catalog, function(a, b) return a.label < b.label end)

    -- Build category list
    _categories = { { id = "all", label = "All", full = "All", count = #flat } }
    for _, group in ipairs(_catalog) do
        _categories[#_categories + 1] = {
            id    = string.lower(group.label),
            label = group.label,
            full  = group.label,
            count = #group.recipes,
        }
    end

    -- Sort flat list alphabetically
    table.sort(flat, function(a, b) return a.displayName < b.displayName end)
    _flatRecipes = flat
    _recipeByName = byName
end

-- Hook: build catalog once at game start
local function onGameStart()
    buildCatalog()
end
Events.OnGameStart.Add(onGameStart)

-- ============================================================================
-- DATA GATHERING — cheap per-frame: skill/learn checks only
-- ============================================================================

-- The recipe list and categories for a bench: the catalog entries the bench
-- makes, in catalog order. Cached per station.
local _benchSource = {}
local function benchSource(bench)
    local c = _benchSource[bench.key]
    if c then return c.list, c.cats end
    local set = ZeD.Stations.recipeSet(bench)
    local list, counts, order = {}, {}, {}
    for _, entry in ipairs(_flatRecipes or {}) do
        if set[entry.name] then
            list[#list + 1] = entry
            local id = string.lower(entry.category)
            if not counts[id] then
                counts[id] = 0
                order[#order + 1] = { id = id, label = entry.category }
            end
            counts[id] = counts[id] + 1
        end
    end
    table.sort(order, function(a, b) return a.label < b.label end)
    local cats = { { id = "all", label = "All", full = "All", count = #list } }
    for _, o in ipairs(order) do
        cats[#cats + 1] = { id = o.id, label = o.label, full = o.label, count = counts[o.id] }
    end
    _benchSource[bench.key] = { list = list, cats = cats }
    return list, cats
end

local function boundBench(playerObj)
    local st = ZeD.Stations and playerObj and ZeD.Stations.current(playerObj)
    if st and st.kind == "bench" then return st end
    return nil
end

function ZeD.CraftingTab.gatherData(playerObj, win)
    buildCatalog()
    if not _flatRecipes then return { recipes = {}, categories = _categories, flatRecipes = _flatRecipes } end

    local bench = boundBench(playerObj)
    local srcKey = bench and bench.key or "hand"
    if win._craftCacheKey ~= srcKey then
        win._craftCache = nil
        win._craftCacheKey = srcKey
    end

    -- Throttled (every 30 frames)
    win._craftTimer = (win._craftTimer or 0) + 1
    if win._craftTimer < 30 and win._craftCache then
        return win._craftCache
    end
    win._craftTimer = 0

    local recipes = {}
    local source, categories = _flatRecipes, _categories
    if bench then source, categories = benchSource(bench) end
    local boundShort = nil
    if bench then
        for _, e in ipairs(source) do
            if e.stationInfo then boundShort = e.stationInfo.short; break end
        end
    end

    for _, entry in ipairs(source) do
        -- Skill check
        local hasSkill = true
        local playerLevel = 0
        if entry.skillName then
            local perkType = CC.getPerkType(entry.skillName)
            if perkType and perkType ~= Perks.None then
                playerLevel = playerObj:getPerkLevel(perkType)
            end
            hasSkill = playerLevel >= entry.requiredLevel
        end

        -- Learned check (force Lua boolean)
        local learned = true
        if entry.needLearn then
            learned = false
            pcall(function() if playerObj:isRecipeKnown(entry.recipe) then learned = true end end)
        end

        local status
        if not learned or not hasSkill then
            status = "locked"
        else
            status = "unlocked"
        end

        -- Hand mode: a recipe that needs a station cannot be made by hand
        local needs = (not bench) and entry.stationInfo or nil
        if needs and status == "unlocked" then status = "station" end

        recipes[#recipes + 1] = {
            stationNeed = needs,
            stationTag  = needs and needs.short or nil,
            boundShort  = bench and (entry.stationInfo and entry.stationInfo.short or boundShort) or nil,
            entry       = entry,
            status      = status,
            hasSkill    = hasSkill,
            learned     = learned,
            playerLevel = playerLevel,
            ingredients  = nil,
            missingCount = 0,
        }
    end

    local data = { recipes = recipes, categories = categories, flatRecipes = source }
    CC.carryStatus(win._craftCache, data)
    win._craftCache = data
    return data
end

-- ============================================================================
-- DETAIL GATHERING — container scan + batch qty via HandcraftLogic
-- ============================================================================

local function gatherDetail(rd, playerObj, win)
    local containers = CC.gatherDetail(rd, playerObj, win, "craft")

    -- Max batch qty (crafting-specific — uses HandcraftLogic)
    rd.maxBatchQty = 1
    local entry = rd.entry
    if entry.allowBatch and entry.recipe and rd.status == "craftable" then
        local bench = boundBench(playerObj)
        pcall(function()
            local l = HandcraftLogic.new(playerObj, bench and bench.comp or nil, bench and bench.obj or nil)
            l:setRecipe(entry.recipe)
            l:setContainers(containers)
            rd.maxBatchQty = l:getPossibleCraftCount(true)
        end)
    end
end

-- ============================================================================
-- CRAFT EXECUTION — HandcraftLogic + batch
-- ============================================================================

function ZeD.CraftingTab.startCraft(win, state)
    local playerObj = win._playerObj
    if not playerObj then return end

    local recipeName = state.selected
    if not recipeName then return end

    local entry = _recipeByName and _recipeByName[recipeName]
    if not entry then return end

    local recipe = entry.recipe
    local qty = state.qty or 1

    -- At a bench: still bound and in reach, walk over if needed (vanilla's
    -- HandcraftStartMultiple does the same), and the action carries the bench
    -- so it keeps vanilla's one-player check (ISHandcraftAction:isValid).
    local bench = nil
    if ZeD.Stations then
        local st = ZeD.Stations.validate(playerObj)
        if st and st.kind == "bench" then bench = st end
    end
    if entry.stationInfo and not bench then return end
    if bench then
        if not ZeD.Stations.recipeSet(bench)[recipe:getName()] then return end
        if ISEntityUI and ISEntityUI.WalkToEntity and not ISEntityUI.WalkToEntity(playerObj, bench.obj) then return end
    end

    -- Build containers
    local containers = CC.buildContainers(playerObj)

    -- Build actions directly — ISHandcraftAction:new calls
    -- convertToPZNetTable(manualInputs) which crashes on nil AND false.
    -- But :start() needs manualInputs to be falsy so it auto-resolves
    -- inputs from the recipe.  Fix: construct via ISBaseTimedAction:new
    -- and set fields manually, skipping convertToPZNetTable entirely.
    local craftOk = pcall(function()
        for i = 1, qty do
            local action = ISBaseTimedAction.new(ISHandcraftAction, playerObj)
            action.stopOnAim    = false
            action.character    = playerObj
            action.isoObject    = bench and bench.obj or nil
            action.craftBench   = bench and bench.comp or nil
            action.containers   = containers
            action.manualInputs = nil  -- falsy → :start() auto-resolves inputs
            action.craftRecipe  = recipe
            action.actionScript = recipe:getTimedActionScript()
            action.stopOnWalk   = not recipe:isCanWalk()
            action.stopOnRun    = true
            action.variableInputRatio = 1
            action.eatPercentage = 0
            action.maxTime      = recipe:getTime(playerObj) * 5
            if playerObj:hasTrait(CharacterTrait.ALL_THUMBS) or playerObj:isWearingAwkwardGloves() then
                action.stopOnWalk = true
            end
            ISTimedActionQueue.add(action)
        end
    end)

    -- Increment craft count only if execution succeeded
    if craftOk then
        CC.incrementCraftCount(playerObj, recipeName, "ZeD_CraftCounts")
    end

    -- Reset state
    state.qty = 1
    state.filterDirty = true
    win._craftCache = nil
    win["_craftContainerTimer"] = 90  -- force container rescan
    win["_craftTypeCache"] = nil      -- invalidate type cache
end

-- ============================================================================
-- CONFIG TABLE
-- ============================================================================

local craftConfig = {
    stations    = true,   -- STATION select, band, station recipes (Stations.lua)
    prefix      = "craft",
    pinKey      = "ZeD_CraftPins",
    countKey    = "ZeD_CraftCounts",
    buildLabel  = "IGUI_CraftingWindow_Craft",   -- a key (CraftingCore translates it where it draws)
    startAction = function(win, state)
        ZeD.CraftingTab.startCraft(win, state)
    end,
}

-- ============================================================================
-- TAB STATE — per-window, stored on win object
-- ============================================================================

local function getState(win)
    if not win._craftState then
        win._craftState = CC.createState()
    end
    return win._craftState
end

-- ============================================================================
-- MAIN RENDERER
-- ============================================================================

-- A bind or unbind elsewhere (dropdown, USE button, vanilla hook, walking
-- away) resets what depends on the recipe source.
local function syncStation(win, state)
    local ST = ZeD.Stations
    if not ST or state._stGen == ST.gen then return end
    state._stGen = ST.gen
    state.filterDirty = true
    state.activeCat = "all"
    state.catDropdownOpen = false
    state.stDropdownOpen = false
    state.stDropdownScroll = 0
    if state.altSlotName then CC.exitAltMode(state) end
    local bench = boundBench(win._playerObj)
    if state.selected and bench and not ST.recipeSet(bench)[state.selected] then
        CC.closeCraft(state)
    end
    if state.scroll then state.scroll:setScrollPos(0) end
    win._craftCache = nil
    win._craftTimer = 30
end

-- The view that replaces the recipe list for a machine or an appliance.
local function stationView(win)
    local ST = ZeD.Stations
    local st = ST and win._playerObj and ST.current(win._playerObj)
    if not st then return nil, nil end
    if st.kind == "machine" and ZeD.StationMachine then return ZeD.StationMachine, st end
    if (st.kind == "oven" or st.kind == "micro") and ZeD.StationAppliance then return ZeD.StationAppliance, st end
    return nil, st
end

function ZeD.CraftingTab.render(panel, win, x, y, w, h)
    local state = getState(win)
    if ZeD.Stations and win._playerObj then ZeD.Stations.validate(win._playerObj) end
    syncStation(win, state)

    local view, st = stationView(win)
    if view then
        view.render(panel, win, x, y, w, h, state, st)
        return
    end

    -- Throttled data refresh
    local data = ZeD.CraftingTab.gatherData(win._playerObj, win)

    -- Can each recipe be made now? Vanilla's crafting logic answers for every
    -- recipe at once (CC.logicScan); the old quick scan only covers recipes it
    -- could not answer. A changed answer re-filters the list.
    local bench = boundBench(win._playerObj)
    local benchKey = bench and tostring(bench.obj) or "hand"
    if win._craftLogicBench ~= benchKey then win._craftLogic = nil; win._craftLogicBench = benchKey end
    if CC.logicScan(data, win, "craft", function()
        return HandcraftLogic.new(win._playerObj, bench and bench.comp or nil, bench and bench.obj or nil)
    end) then state.filterDirty = true end
    win._craftScanTimer = (win._craftScanTimer or 300) + 1
    if win._craftScanTimer >= 300 then
        win._craftScanTimer = 0
        CC.backgroundIngredientScan(data, win, "craft")
    end

    -- Gather detail for selected recipe (expensive — full container scan)
    if state.selected then
        local selRd = nil
        for _, rd in ipairs(data.recipes) do
            if rd.entry.name == state.selected then
                selRd = rd
                break
            end
        end
        if selRd then
            gatherDetail(selRd, win._playerObj, win)
        end
    end

    -- Delegate to CraftingCore
    CC.render(panel, win, x, y, w, h, state, craftConfig, data)
end

-- ============================================================================
-- CLICK HANDLER
-- ============================================================================

function ZeD.CraftingTab.onClick(win, x, y)
    local state = getState(win)
    local view, st = stationView(win)
    if view then return view.onClick(win, state, st, x, y) end
    return CC.onClick(state, craftConfig, win, x, y, win._playerObj)
end

-- ============================================================================
-- RIGHT-CLICK HANDLER
-- ============================================================================

function ZeD.CraftingTab.onRightClick(win, x, y)
    local state = getState(win)
    if stationView(win) then return true end
    return CC.onRightClick(state, craftConfig, win, x, y)
end

-- ============================================================================
-- MOUSE WHEEL HANDLER
-- ============================================================================

function ZeD.CraftingTab.onMouseWheel(win, del, x, y)
    local T = ZeD.T
    local state = getState(win)
    local view, st = stationView(win)
    if view then return view.onMouseWheel(win, state, st, del, x, y) end
    return CC.onMouseWheel(state, del, x, y, 0, T.px(CC.DRAWER_W))
end

-- Gamepad focusables for the World window (recipe view or station view).
function ZeD.CraftingTab.buildFocusables(win)
    local state = win and win._craftState
    if not state then return {} end
    local view, st = stationView(win)
    if view then return view.buildFocusables(win, state, st) end
    return CC.buildFocusables(win, state, "craft", "ZeD_CraftPins", ZeD.CraftingTab.startCraft)
end

-- Focus-refresh key: changes whenever the station view's controls move.
function ZeD.CraftingTab.focusKey(win)
    local state = win and win._craftState
    if not state then return nil end
    local view, st = stationView(win)
    local k = tostring(ZeD.Stations and ZeD.Stations.gen or 0) .. ":" .. tostring(state.stDropdownOpen) .. ":" .. tostring(state.stDropdownScroll or 0)
    if view and view.focusKey then k = k .. ":" .. tostring(view.focusKey(win, state, st)) end
    return k
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.CraftingTab.register(dispatchTable)
    dispatchTable["craft"] = ZeD.CraftingTab.render
end
