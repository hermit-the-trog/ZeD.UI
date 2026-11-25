-- ZeD-UI/42/media/lua/client/ZeD/BuildingTab.lua
-- ============================================================================
-- BUILDING TAB — client; an organism: a thin wrapper over CraftingCore.
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
                categoryDisplay = ZeD.upper(string.sub(category, 1, 1)) .. string.sub(category, 2)
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

            -- Pre-bake description: the recipe's Tooltip (a translation key on 135 of the game's 189 build
            -- recipes, e.g. Tooltip_craft_BigMetalFenceDesc; vanilla's info box reads it the same way).
            -- Not getDescription: the game's build recipes do not have it, and asking for it left the
            -- header's description slot empty.
            local description = nil
            if recipe.getTooltip then
                pcall(function()
                    local k = recipe:getTooltip()
                    if k and k ~= "" then
                        local d = getText(k)
                        if d and d ~= "" and d ~= k then description = tostring(d):gsub("<br>", " ") end
                    end
                end)
            end

            -- Pre-bake surface requirement (same guard)
            local needSurface = false
            if recipe.isAnySurfaceCraft then
                pcall(function() if recipe:isAnySurfaceCraft() then needSurface = true end end)
            end

            -- (QA B13-1) whether it must be learned (metal and welding), so Show: Known leaves the unlearned ones out
            local needLearn = false
            pcall(function() if recipe:needToBeLearn() then needLearn = true end end)
            local entry = {
                recipe          = recipe,
                needLearn       = needLearn,
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

local ROWS_MS = 1000   -- the rows' refresh (once a second on the clock, not per frame)

function ZeD.BuildingTab.gatherData(playerObj, win)
    buildBuildCatalog(playerObj)
    if not _flatRecipes then return { recipes = {}, categories = _categories, flatRecipes = _flatRecipes } end

    -- Throttled: every ROWS_MS, at once when the cache was dropped
    local prev = win._buildCache
    if not CC.due(win, "_buildRowsAt", ROWS_MS, not prev) then
        return prev
    end

    -- The rows are rewritten in place (CC.refreshRow), as the Craft tab's are; a dropped cache
    -- starts a new data table and nothing carries into it.
    local data = prev
    if not data then
        data = { recipes = {} }
    end
    data.categories, data.flatRecipes = _categories, _flatRecipes
    local recipes = data.recipes
    local pool, gen = CC.rowsBegin(win, "build")
    local prevGen = prev and prev.gen or nil
    local levels = {}   -- (each skill's level asked once per refresh)
    local n, changed = 0, prev == nil

    for _, entry in ipairs(_flatRecipes) do
        -- Skill check
        local hasSkill = true
        local playerLevel = 0
        if entry.skillName then
            playerLevel = CC.perkLevelOf(levels, playerObj, entry.skillName)
            hasSkill = playerLevel >= entry.requiredLevel
            -- (the game's rule for every required skill, not the first only: a recipe whose second skill is short
            -- is locked; playerLevel stays the first skill's, for the row)
            if entry.recipe then
                local okS, has = pcall(entry.recipe.characterHasRequiredSkills, entry.recipe, playerObj)
                if okS then hasSkill = has and true or false end
            end
        end

        -- (QA B11-2) some build recipes do need learning (metal and welding): ask whether the player really knows it
        -- (the second argument), as the game's build window does; a recipe that needs none reads learned
        local learned = true
        if entry.needLearn then
            pcall(function()
                if not playerObj:isRecipeKnown(entry.recipe, true) then learned = false end
            end)
        end
        -- (QA B13-1) the status weighs learned too, as the Craft tab's does: decided before it, the row read unlocked here
        -- and locked in the scan, and flipped every refresh
        local status = (hasSkill and learned) and "unlocked" or "locked"
        local rd = CC.refreshRow(pool, entry, gen, prevGen, status, hasSkill, learned, playerLevel)
        n = n + 1
        if recipes[n] ~= rd then recipes[n] = rd; changed = true end
    end

    CC.rowsEnd(data, n, changed)
    data.gen = gen
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
-- THE CURSOR'S UPKEEP: what the game's build panel does for its cursor while it is up
-- (QA cb sweep, Nov 25 2026). The game keeps one BuildLogic and one cursor per build
-- window (ISBuildPanel); ZeD has no panel, so each player's last build is kept here:
--   _active[pn] = { cursor, logic, player, sq = { x, y, z } }
-- ============================================================================

local _active = {}

-- (B2, B7) The game's ISBuildPanel:createBuildIsoEntity(true): the cursor may build when the logic can
-- perform the recipe (or BuildCheat is on) and no build of it is under way; else it is blocked (drawn red).
local function rearm(a)
    if not (a and a.cursor and a.logic) then return end
    local canBuild = false
    pcall(function() canBuild = a.logic:canPerformCurrentRecipe() and true or false end)
    pcall(function() if a.player:isBuildCheat() then canBuild = true end end)
    pcall(function() if a.logic:isCraftActionInProgress() then canBuild = false end end)
    a.cursor.blockBuild = not canBuild
end

-- whether the cursor of a is still player pn's drag
local function cursorUp(a, pn)
    local cell = getCell and getCell()
    return cell ~= nil and a ~= nil and a.cursor ~= nil and cell:getDrag(pn) == a.cursor
end

-- (B7) The game's ISBuildPanel:update: when the player has moved a square, the containers are read again and
-- set on the logic, so a build placed away from where Build was pressed takes from what is in reach where it
-- is built. The list frozen at the press ran the build action there for nothing (QA: the cross 8 tiles away, 1
-- action, 0 objects, nothing used). Kept while the cursor is up or a build of it is still under way.
local function refreshContainers(player)
    if not player or not player.getPlayerNum then return end
    local pn = player:getPlayerNum()
    local a = _active[pn]
    if not a then return end
    if not a.logic then   -- (a paint or wallpaper cursor: nothing to keep but whether it is up)
        if not cursorUp(a, pn) then _active[pn] = nil end
        return
    end
    local busy = false
    pcall(function() busy = a.logic:isCraftActionInProgress() and true or false end)
    if not busy and not cursorUp(a, pn) then _active[pn] = nil; return end
    local sq = player:getCurrentSquare()
    if not sq then return end   -- (a teleport, as the game's hasPlayerMoved)
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local last = a.sq
    if last and last.x == x and last.y == y and last.z == z then return end
    a.sq = { x = x, y = y, z = z }
    local containers = CC.craftContainers(player)
    local changed = false
    pcall(function() changed = a.logic:setContainers(containers) and true or false end)
    if changed then
        a.cursor.containers = containers
        if cursorUp(a, pn) then rearm(a) end
    end
end

-- (one handler: a reload of this file swaps it for its own, which reads the new _active)
if Events and Events.OnPlayerUpdate then
    local ev = Events.OnPlayerUpdate
    if ZeD._buildCursorUpkeep and ev.Remove then ev.Remove(ZeD._buildCursorUpkeep) end
    ZeD._buildCursorUpkeep = function(player) pcall(refreshContainers, player) end
    ev.Add(ZeD._buildCursorUpkeep)
end

--- (B5) The World window closed: the build cursor the Build tab started for player pn goes with it, as the
--- game's build window's close clears its cursor (ISBuildPanel:OnCloseWindow). A cursor started elsewhere
--- (Furniture, Place item, the game's own windows) is left alone.
function ZeD.BuildingTab.dropCursor(pn)
    pn = pn or 0
    local a = _active[pn]
    if not a then return false end
    if not cursorUp(a, pn) then return false end
    getCell():setDrag(nil, pn)
    return true
end

--- (B3) A build of player pn's is queued or running (the walk counts: the game's tryBuild starts the craft
--- action before the walk). The game holds its Build button while one is (ISWidgetBuildControl:prerender).
function ZeD.BuildingTab.buildInProgress(pn)
    local a = _active[pn or 0]
    if not (a and a.logic) then return false end
    local busy = false
    pcall(function() busy = a.logic:isCraftActionInProgress() and true or false end)
    return busy
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

    -- (B3, QA cb sweep, Nov 25 2026) no second cursor while a build is queued or running: Build pressed during
    -- the walk started a new usable cursor; the game's Build is held then (ISWidgetBuildControl.lua:163-172)
    local pn = playerObj:getPlayerNum()
    if ZeD.BuildingTab.buildInProgress(pn) then return end

    local recipe = entry.recipe
    local containers = CC.craftContainers(playerObj)  -- (the game's list, the floor too, as ISBuildPanel: beast W25)

    -- Create BuildLogic and set recipe
    local ok, logic = pcall(function()
        local l = BuildLogic.new(playerObj, nil, nil)
        -- (as the game's ISBuildPanel: fill the recipe lookup first, or getSelectedBuildObject and
        -- getWallCoveringParams throw a NullPointerException and no cursor starts) (QA B5-8)
        local list = l:getAllBuildableRecipes()
        l:setRecipes(list)
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
        -- Standard build: ISBuildIsoEntity placement cursor.
        -- (B6, QA cb sweep, Nov 25 2026) It starts on the facing the preview card showed for this recipe
        -- (ObjectCardPreview leaves it on the state as nSprite, the cursor's own 1 W, 2 N, 3 E, 4 S); it
        -- started on W whatever the preview showed. No preview seen: W, as the game's panel starts it.
        local nSprite = 1
        local bf = state._buildFace
        if bf and bf.name == recipeName and type(bf.nSprite) == "number" and bf.nSprite >= 1 and bf.nSprite <= 4 then
            nSprite = bf.nSprite
        end
        local buildEntity = ISBuildIsoEntity:new(playerObj, objectInfo, nSprite, containers, logic)
        buildEntity.dragNilAfterPlace = false
        buildEntity.blockAfterPlace = true

        -- Set tool items
        local inventory = playerObj:getInventory()
        buildEntity.equipBothHandItem = getTool(recipe:getToolBoth(), inventory)
        buildEntity.firstItem = getTool(recipe:getToolRight(), inventory)
        buildEntity.secondItem = getTool(recipe:getToolLeft(), inventory)

        local a = { cursor = buildEntity, logic = logic, player = playerObj }
        local sq0 = playerObj:getCurrentSquare()
        if sq0 then a.sq = { x = sq0:getX(), y = sq0:getY(), z = sq0:getZ() } end
        -- (B2, QA cb sweep, Nov 25 2026) After one placement blockAfterPlace leaves the cursor blocked, and
        -- every clear tile read red. The game's panel listens to its logic and re-arms the cursor when the
        -- build ends (onStopCraft, ISBuildPanel.lua:414-422) and when the containers change (onUpdateContainers);
        -- tryBuild and the build action's end call the logic's startCraftAction and stopCraftAction, which fire
        -- them. The same listeners here, on this cursor while it is still up (a cancelled one is not brought back).
        local function onStop()
            if _active[pn] ~= a then return end
            -- (the containers read afresh first, as the game's onStopCraft does: the build just used some)
            local cs = CC.craftContainers(playerObj)
            pcall(function() a.logic:setContainers(cs) end)
            a.cursor.containers = cs
            if cursorUp(a, pn) then rearm(a) end
        end
        local function onContainers()
            if _active[pn] == a and cursorUp(a, pn) then rearm(a) end
        end
        pcall(function() logic:addEventListener("onStopCraft", onStop, a) end)
        pcall(function() logic:addEventListener("onUpdateContainers", onContainers, a) end)
        _active[pn] = a

        getCell():setDrag(buildEntity, pn)
        buildStarted = true

    elseif okWC and wallCoveringParams then
        -- Wall covering: paint or wallpaper cursor
        local cursor
        if wallCoveringParams.actionType == WallCoveringType.WALLPAPER then
            cursor = ISPaperCursor:new(playerObj, wallCoveringParams.wallpaperType,
                WallPaper["wall"][wallCoveringParams.wallpaperType])
        else
            cursor = ISPaintCursor:new(playerObj, wallCoveringParams.actionType:toString(),
                wallCoveringParams)
        end
        _active[pn] = { cursor = cursor, player = playerObj }   -- (B5: the window's close drops it too)
        getCell():setDrag(cursor, pn)
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
    win["_buildContainerAt"] = nil
    win["_buildTypeCache"] = nil      -- invalidate type cache
end

-- ============================================================================
-- CONFIG TABLE
-- ============================================================================

local buildConfig = {
    prefix      = "build",
    titleKey    = "UI_ZeD_World_TabBuilding",    -- the tab's title, the World window's word for it
    pinKey      = "ZeD_BuildPins",
    countKey    = "ZeD_BuildCounts",
    buildLabel  = "IGUI_CraftingWindow_Build",   -- a key (CraftingCore translates it where it draws)
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
        win._buildState.show = "known"   -- Build opens on Known: Ready is empty until he carries the materials (KISS #17)
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
        local selRd = data.byName and data.byName[state.selected] or nil
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
-- PAD B ON THE CARD (QA cb sweep, Nov 25 2026, B11)
-- ============================================================================

-- The card's stops (its sections, an input's alternatives, the header icon, Build) had no B: with no onCancel the
-- focus manager's B stopped the running action instead, perhaps the build itself, and the card stayed. B now
-- closes the card, as Escape does with the mouse (CC.takeEscape), and the focus goes back to its row. With no
-- card open the press falls through as before. Stops that already have a B (open lists) keep theirs.
local CARD_KINDS = { cardSection = true, slotAlt = true, icon = true, actBuild = true }

function ZeD.BuildingTab.cardCancels(win, elements)
    local state = win and win._buildState
    if not (state and elements) then return end
    for _, el in ipairs(elements) do
        if type(el) == "table" and CARD_KINDS[el.craftKind] and not el.onCancel then
            el.onCancel = function(w, e)
                local name = state.selected
                if not name then return false end
                CC.closeCraft(state)
                local Fo = ZeD.Input and ZeD.Input.Focus
                if Fo and Fo.focusByIdSoon then Fo.focusByIdSoon(w, "worldTabContent", "build:row:" .. tostring(name)) end
                return true
            end
        end
    end
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
