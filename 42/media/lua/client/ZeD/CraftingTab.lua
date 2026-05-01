-- ZeD-UI/42/media/lua/client/ZeD/CraftingTab.lua
-- ============================================================================
-- CRAFTING TAB — Thin wrapper over CraftingCore.
-- Owns: catalog building (eager, game start), gatherData (skill+learn checks),
-- gatherDetail (batch qty via HandcraftLogic), startCraft (HandcraftLogic exec).
-- All rendering, filtering, pin management, state machine → CraftingCore.
-- ============================================================================

require "ZeD/CraftingCore"

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

        local entry = {
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

function ZeD.CraftingTab.gatherData(playerObj, win)
    buildCatalog()
    if not _flatRecipes then return { recipes = {}, categories = _categories, flatRecipes = _flatRecipes } end

    -- Throttled (every 30 frames)
    win._craftTimer = (win._craftTimer or 0) + 1
    if win._craftTimer < 30 and win._craftCache then
        return win._craftCache
    end
    win._craftTimer = 0

    local recipes = {}

    for _, entry in ipairs(_flatRecipes) do
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

        recipes[#recipes + 1] = {
            entry       = entry,
            status      = status,
            hasSkill    = hasSkill,
            learned     = learned,
            playerLevel = playerLevel,
            ingredients  = nil,
            missingCount = 0,
        }
    end

    local data = { recipes = recipes, categories = _categories, flatRecipes = _flatRecipes }
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
        pcall(function()
            local l = HandcraftLogic.new(playerObj, nil, nil)
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
            action.isoObject    = nil
            action.craftBench   = nil
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
    prefix      = "craft",
    pinKey      = "ZeD_CraftPins",
    countKey    = "ZeD_CraftCounts",
    buildLabel  = "CRAFT",
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

function ZeD.CraftingTab.render(panel, win, x, y, w, h)
    local state = getState(win)

    -- Throttled data refresh
    local data = ZeD.CraftingTab.gatherData(win._playerObj, win)

    -- Throttled background ingredient scan (every 300 frames ~5s)
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
    return CC.onClick(state, craftConfig, win, x, y, win._playerObj)
end

-- ============================================================================
-- RIGHT-CLICK HANDLER
-- ============================================================================

function ZeD.CraftingTab.onRightClick(win, x, y)
    local state = getState(win)
    return CC.onRightClick(state, craftConfig, win, x, y)
end

-- ============================================================================
-- MOUSE WHEEL HANDLER
-- ============================================================================

function ZeD.CraftingTab.onMouseWheel(win, del, x, y)
    local state = getState(win)
    return CC.onMouseWheel(state, del, x, y, 0, CC.DRAWER_W)
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.CraftingTab.register(dispatchTable)
    dispatchTable["craft"] = ZeD.CraftingTab.render
end
