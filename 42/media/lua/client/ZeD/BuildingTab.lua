-- ZeD-UI/42/media/lua/client/ZeD/BuildingTab.lua
-- ============================================================================
-- BUILDING TAB — Thin wrapper over CraftingCore.
-- Owns: catalog building (lazy, needs player), gatherData (skill checks only),
-- gatherDetail (tool availability), startBuild (BuildLogic + placement cursor).
-- All rendering, filtering, pin management, state machine → CraftingCore.
-- ============================================================================

require "ZeD/CraftingCore"

ZeD = ZeD or {}
ZeD.BuildingTab = {}

local CC = ZeD.CraftingCore

-- ============================================================================
-- STATIC RECIPE CATALOG — built LAZILY on first render (needs player object).
-- ============================================================================

local _catalog        = nil
local _flatRecipes    = nil
local _categories     = nil
local _recipeByName   = nil
local _catalogBuilt   = false

local function buildBuildCatalog(playerObj)
    if _catalogBuilt then return end
    _catalogBuilt = true  -- set FIRST to prevent re-entry on slow frames

    -- BuildLogic requires a player object
    local ok, logic = pcall(function()
        return BuildLogic.new(playerObj, nil, nil)
    end)
    if not ok or not logic then
        _catalog = {}
        _flatRecipes = {}
        _categories = { { id = "all", label = "All", full = "All", count = 0 } }
        _recipeByName = {}
        return
    end

    local ok2, allElements = pcall(function()
        return logic:getAllBuildableRecipes()
    end)
    if not ok2 or not allElements then
        _catalog = {}
        _flatRecipes = {}
        _categories = { { id = "all", label = "All", full = "All", count = 0 } }
        _recipeByName = {}
        return
    end

    local byTag = {}
    local flat = {}
    local byName = {}

    for i = 0, allElements:size() - 1 do
        local okEl, _ = pcall(function()
            local element = allElements:get(i)
            local recipe = element
            if not recipe then return end

            -- Resolve category (getCategory > getBuildCategory > skill > Miscellaneous)
            local category = nil
            pcall(function()
                local c = recipe:getCategory()
                if c and c ~= "" then category = tostring(c) end
            end)
            if not category then
                pcall(function()
                    local c = recipe:getBuildCategory()
                    if c and c ~= "" then category = tostring(c) end
                end)
            end

            local skillName = nil
            local requiredLevel = 0
            if recipe:getRequiredSkillCount() > 0 then
                local okS, rs = pcall(function() return recipe:getRequiredSkill(0) end)
                if okS and rs then
                    skillName = tostring(rs:getPerk():getName())
                    requiredLevel = rs:getLevel()
                end
            end

            if not category and skillName then
                category = skillName
            end

            local categoryDisplay
            if category and category ~= "" then
                categoryDisplay = string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2)
            else
                category = "miscellaneous"
                categoryDisplay = "Miscellaneous"
            end

            if not byTag[category] then
                byTag[category] = { label = categoryDisplay, tag = category, recipes = {} }
            end

            -- Pre-bake using CraftingCore helpers
            local inputDefs  = CC.prebakeInputs(recipe)
            local outputDefs = CC.prebakeOutputs(recipe)
            local skillDefs  = CC.prebakeSkills(recipe)

            -- Pre-bake tool slot refs (building-specific)
            local toolRight = nil
            pcall(function() toolRight = recipe:getToolRight() end)
            local toolLeft = nil
            pcall(function() toolLeft = recipe:getToolLeft() end)
            local toolBoth = nil
            pcall(function() toolBoth = recipe:getToolBoth() end)

            local toolRightName = toolRight and CC.getInputName(toolRight) or nil
            local toolLeftName  = toolLeft and CC.getInputName(toolLeft) or nil
            local toolBothName  = toolBoth and CC.getInputName(toolBoth) or nil

            -- Pre-bake icon texture
            local iconTex = nil
            pcall(function() iconTex = recipe:getIconTexture() end)

            -- Pre-bake description (check method exists — Kahlua logs Java
            -- exceptions from pcall even when caught, spamming console)
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
                recipe          = recipe,
                element         = element,
                displayName     = recipe:getTranslationName() or recipe:getName(),
                name            = recipe:getName(),
                requiredLevel   = requiredLevel,
                skillName       = skillName,
                category        = categoryDisplay,
                inputDefs       = inputDefs,
                outputDefs      = outputDefs,
                skillDefs       = skillDefs,
                toolRight       = toolRight,
                toolLeft        = toolLeft,
                toolBoth        = toolBoth,
                toolRightName   = toolRightName,
                toolLeftName    = toolLeftName,
                toolBothName    = toolBothName,
                iconTex         = iconTex,
                description     = description,
                needSurface     = needSurface,
            }

            local list = byTag[category].recipes
            list[#list + 1] = entry
            flat[#flat + 1] = entry
            byName[entry.name] = entry
        end)
        -- If pcall failed, skip silently
    end

    -- Sort groups
    _catalog = {}
    for _, group in pairs(byTag) do
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
            id    = string.lower(group.tag),
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

-- ============================================================================
-- DATA GATHERING — cheap per-frame: skill checks only (no learned checks)
-- ============================================================================

function ZeD.BuildingTab.gatherData(playerObj, win)
    buildBuildCatalog(playerObj)
    if not _flatRecipes then return { recipes = {}, categories = _categories, flatRecipes = _flatRecipes } end

    -- Throttled (every 30 frames)
    win._buildTimer = (win._buildTimer or 0) + 1
    if win._buildTimer < 30 and win._buildCache then
        return win._buildCache
    end
    win._buildTimer = 0

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

        local status = hasSkill and "unlocked" or "locked"

        recipes[#recipes + 1] = {
            entry       = entry,
            status      = status,
            hasSkill    = hasSkill,
            learned     = true,  -- building recipes don't need to be learned
            playerLevel = playerLevel,
            ingredients  = nil,
            missingCount = 0,
        }
    end

    local data = { recipes = recipes, categories = _categories, flatRecipes = _flatRecipes }
    CC.carryStatus(win._buildCache, data)
    win._buildCache = data
    return data
end

-- ============================================================================
-- DETAIL GATHERING — container scan + tool availability
-- ============================================================================

local function gatherDetail(rd, playerObj, win)
    local containers = CC.gatherDetail(rd, playerObj, win, "build")

    -- Building doesn't have batch qty — always 1
    rd.maxBatchQty = 1
end

-- ============================================================================
-- TOOL RETRIEVAL — find a tool item in inventory by InputScript
-- ============================================================================

local function getTool(toolSlot, inventory)
    if not toolSlot then return nil end
    local ok, possible = pcall(function() return toolSlot:getPossibleInputItems() end)
    if not ok or not possible then return nil end

    for i = 0, possible:size() - 1 do
        local item = possible:get(i)
        if item and item.getFullType then
            local ft = item:getFullType()
            if ft then
                local found = inventory:getFirstTypeRecurse(ft)
                if found then return found end
            end
        end
    end
    return nil
end

-- ============================================================================
-- BUILD EXECUTION — BuildLogic + placement cursor
-- ============================================================================

function ZeD.BuildingTab.startBuild(win, state)
    local playerObj = win._playerObj
    if not playerObj then return end

    local recipeName = state.selected
    if not recipeName then return end

    local entry = _recipeByName and _recipeByName[recipeName]
    if not entry then return end

    local recipe = entry.recipe
    local containers = CC.buildContainers(playerObj)

    -- Create BuildLogic and set recipe
    local ok, logic = pcall(function()
        local l = BuildLogic.new(playerObj, nil, nil)
        l:setRecipe(recipe)
        l:setContainers(containers)
        return l
    end)
    if not ok or not logic then return end

    -- Validate
    local canPerform = false
    pcall(function() canPerform = logic:canPerformCurrentRecipe() end)
    if not canPerform and not playerObj:isBuildCheat() then return end

    -- Get build object info
    local okInfo, objectInfo = pcall(function() return logic:getSelectedBuildObject() end)

    -- Check for wall covering params
    local okWC, wallCoveringParams = pcall(function() return logic:getWallCoveringParams() end)

    local buildStarted = false

    if okInfo and objectInfo then
        -- Standard build: ISBuildIsoEntity placement cursor
        local buildEntity = ISBuildIsoEntity:new(playerObj, objectInfo, 1, containers, logic)
        buildEntity.dragNilAfterPlace = false
        buildEntity.blockAfterPlace = true

        -- Set tool items
        local inventory = playerObj:getInventory()
        buildEntity.equipBothHandItem = getTool(recipe:getToolBoth(), inventory)
        buildEntity.firstItem = getTool(recipe:getToolRight(), inventory)
        buildEntity.secondItem = getTool(recipe:getToolLeft(), inventory)

        getCell():setDrag(buildEntity, playerObj:getPlayerNum())
        buildStarted = true

    elseif okWC and wallCoveringParams then
        -- Wall covering: paint or wallpaper cursor
        if wallCoveringParams.actionType == WallCoveringType.WALLPAPER then
            local cursor = ISPaperCursor:new(playerObj, wallCoveringParams.wallpaperType,
                WallPaper["wall"][wallCoveringParams.wallpaperType])
            getCell():setDrag(cursor, playerObj:getPlayerNum())
        else
            local cursor = ISPaintCursor:new(playerObj, wallCoveringParams.actionType:toString(),
                wallCoveringParams)
            getCell():setDrag(cursor, playerObj:getPlayerNum())
        end
        buildStarted = true
    end

    -- Increment build count only if a cursor was created
    if buildStarted then
        CC.incrementCraftCount(playerObj, recipeName, "ZeD_BuildCounts")
    end

    -- Reset state
    state.qty = 1
    state.filterDirty = true
    win._buildCache = nil
    win["_buildContainerTimer"] = 90
    win["_buildTypeCache"] = nil      -- invalidate type cache
end

-- ============================================================================
-- CONFIG TABLE
-- ============================================================================

local buildConfig = {
    prefix      = "build",
    pinKey      = "ZeD_BuildPins",
    countKey    = "ZeD_BuildCounts",
    buildLabel  = "BUILD",
    startAction = function(win, state)
        ZeD.BuildingTab.startBuild(win, state)
    end,
}

-- ============================================================================
-- TAB STATE — per-window, stored on win object
-- ============================================================================

local function getState(win)
    if not win._buildState then
        win._buildState = CC.createState()
    end
    return win._buildState
end

-- ============================================================================
-- MAIN RENDERER
-- ============================================================================

function ZeD.BuildingTab.render(panel, win, x, y, w, h)
    local state = getState(win)

    -- Throttled data refresh
    local data = ZeD.BuildingTab.gatherData(win._playerObj, win)

    -- Can each be built now? Vanilla's build logic answers for every recipe
    -- (CC.logicScan); the quick round-robin scan covers the rest.
    if CC.logicScan(data, win, "build", function() return BuildLogic.new(win._playerObj, nil, nil) end) then
        state.filterDirty = true
    end
    CC.backgroundIngredientScan(data, win, "build")

    -- Gather detail for selected recipe
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
    CC.render(panel, win, x, y, w, h, state, buildConfig, data)
end

-- ============================================================================
-- CLICK HANDLER
-- ============================================================================

function ZeD.BuildingTab.onClick(win, x, y)
    local state = getState(win)
    return CC.onClick(state, buildConfig, win, x, y, win._playerObj)
end

-- ============================================================================
-- RIGHT-CLICK HANDLER
-- ============================================================================

function ZeD.BuildingTab.onRightClick(win, x, y)
    local state = getState(win)
    return CC.onRightClick(state, buildConfig, win, x, y)
end

-- ============================================================================
-- MOUSE WHEEL HANDLER
-- ============================================================================

function ZeD.BuildingTab.onMouseWheel(win, del, x, y)
    local T = ZeD.T
    local state = getState(win)
    return CC.onMouseWheel(state, del, x, y, 0, T.px(CC.DRAWER_W))
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.BuildingTab.register(dispatchTable)
    dispatchTable["build"] = ZeD.BuildingTab.render
end
