-- ZeD-UI/42/media/lua/client/ZeD/JournalTab.lua
-- ============================================================================
-- JOURNAL TAB — 4 sub-tabs inside the drawer.
--   [Journal | Recipes | Maps | Flyers]
--   Journal:  survival logbook + BBS-style diary (full width)
--   Recipes:  all learnable recipes grouped by skill, status dots, expandable
--   Maps:     embedded UIWorldMap with accumulated stash map + flyer markers
--   Flyers:   collected print media gallery with thumbnails from FlyerPics/
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/CraftingCore"

ZeD = ZeD or {}
ZeD.JournalTab = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local MONTHS = { "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec" }
local MONTHS_FULL = { "January","February","March","April","May","June","July","August","September","October","November","December" }

local WEAPON_CAT_ORDER = {
    { key = "Blunt",      label = "Blunt" },
    { key = "SmallBlunt", label = "Small Blunt" },
    { key = "LongBlade",  label = "Long Blade" },
    { key = "SmallBlade", label = "Small Blade" },
    { key = "Axe",        label = "Axe" },
    { key = "Spear",      label = "Spear" },
    { key = "Firearm",    label = "Firearm" },
    { key = "Unarmed",    label = "Unarmed" },
    { key = "Other",      label = "Other" },
}

local ENTRY_INPUT_H = 48  -- 3-line text entry height
local TAB_TOP_PAD   = 13  -- aligns tab strip bottom with inventory column header

local wrapText = ZeD.Atoms.wrapText

-- Recipe status map (2 states)
local RECIPE_STATUS = {
    known   = { token = "positive", label = "KNOWN" },
    unknown = { token = "textDim",  label = "UNKNOWN", ghost = true },
}

local RCP_DOT_GAP   = 4
local RCP_DETAIL_PAD = 26

-- Recipe icon grid constants (matches CraftingTab)
local RCELL_SZ   = 43
local RCELL_GAP  = 3
local RCELL_STEP = RCELL_SZ + RCELL_GAP

local truncText = ZeD.Atoms.truncateText

-- Sub-tab definitions
local SUB_TABS = {
    { id = "journal", label = "Journal" },
    { id = "recipes", label = "Recipes" },
    -- { id = "maps",    label = "Maps" },  -- S67: moved to World Window MapsTab
    { id = "flyers",  label = "Flyers" },
}

-- ============================================================================
-- JOURNAL ENTRY GROUPING — group entries by month_year, newest month first
-- ============================================================================

--- Groups journal entries by month_year key and returns sorted group array.
-- Each group: { key = "0_0", label = "January, Year 0", entries = {...}, count = N }
-- Groups sorted newest first (by year desc, then month desc).
-- Entries within each group keep their existing order (newest first from insert).
-- @param entries       array of entry tables
-- @param originalArray optional: the original (unfiltered) modData array for stable delete indices
local function groupEntriesByMonth(entries, originalArray)
    local byKey = {}
    local keyOrder = {}
    for i, entry in ipairs(entries) do
        local m = entry.month or 0
        local yr = entry.year or 0
        local key = m .. "_" .. yr
        if not byKey[key] then
            byKey[key] = {
                key     = key,
                month   = m,
                year    = yr,
                label   = (MONTHS_FULL[m + 1] or "???") .. ", Year " .. yr,
                entries = {},
            }
            keyOrder[#keyOrder + 1] = key
        end
        -- Find stable index in original array (for delete even when filtered)
        local origIdx = i
        if originalArray and originalArray ~= entries then
            for oi, oe in ipairs(originalArray) do
                if oe == entry then origIdx = oi; break end
            end
        end
        byKey[key].entries[#byKey[key].entries + 1] = { idx = origIdx, entry = entry }
    end
    -- Sort groups newest first
    table.sort(keyOrder, function(a, b)
        local ga, gb = byKey[a], byKey[b]
        if ga.year ~= gb.year then return ga.year > gb.year end
        return ga.month > gb.month
    end)
    local result = {}
    for _, key in ipairs(keyOrder) do
        local g = byKey[key]
        g.count = #g.entries
        result[#result + 1] = g
    end
    return result
end

-- ============================================================================
-- RECIPE CATALOG — combined craft + build, built once (module-level cache)
-- ============================================================================

local _jRecipeCatalog   = nil   -- grouped by category
local _jFlatRecipes     = nil   -- ordered flat list
local _jCategories      = nil   -- category bar entries
local _jRecipeByName    = nil   -- name → entry lookup

local function buildJournalRecipeCatalog(playerObj)
    if _jRecipeCatalog then return end

    local CC = ZeD.CraftingCore
    local byCat = {}
    local flat = {}
    local byName = {}

    -- Helper: process one recipe into the catalog
    local function addRecipe(recipe, source)
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

        local inputDefs  = CC.prebakeInputs(recipe)
        local outputDefs = CC.prebakeOutputs(recipe)
        local skillDefs  = CC.prebakeSkills(recipe)

        local needLearn = false
        pcall(function() if recipe:needToBeLearn() then needLearn = true end end)

        local iconTex = nil
        pcall(function() iconTex = recipe:getIconTexture() end)

        local description = nil
        if recipe.getDescription then
            pcall(function()
                local d = recipe:getDescription()
                if d and d ~= "" then description = tostring(d) end
            end)
        end

        local name = recipe:getName()
        if byName[name] then return end  -- dedup (recipe in both craft+build)

        local entry = {
            recipe        = recipe,
            displayName   = recipe:getTranslationName() or name,
            name          = name,
            category      = category,
            requiredLevel = requiredLevel,
            skillName     = skillName,
            inputDefs     = inputDefs,
            outputDefs    = outputDefs,
            skillDefs     = skillDefs,
            needLearn     = needLearn,
            iconTex       = iconTex,
            description   = description,
            source        = source,  -- "craft" or "build"
        }

        local list = byCat[catKey].recipes
        list[#list + 1] = entry
        flat[#flat + 1] = entry
        byName[name] = entry
    end

    -- 1. Craft recipes
    local allCraft = ScriptManager.instance:getAllCraftRecipes()
    if allCraft then
        for i = 0, allCraft:size() - 1 do
            pcall(function() addRecipe(allCraft:get(i), "craft") end)
        end
    end

    -- 2. Build recipes (needs player for BuildLogic)
    if playerObj then
        pcall(function()
            local logic = BuildLogic.new(playerObj, nil, nil)
            local allBuild = logic:getAllBuildableRecipes()
            if allBuild then
                for i = 0, allBuild:size() - 1 do
                    pcall(function() addRecipe(allBuild:get(i), "build") end)
                end
            end
        end)
    end

    -- Sort groups
    _jRecipeCatalog = {}
    for _, group in pairs(byCat) do
        table.sort(group.recipes, function(a, b)
            if a.requiredLevel ~= b.requiredLevel then return a.requiredLevel < b.requiredLevel end
            return a.displayName < b.displayName
        end)
        _jRecipeCatalog[#_jRecipeCatalog + 1] = group
    end
    table.sort(_jRecipeCatalog, function(a, b) return a.label < b.label end)

    -- Build category list
    _jCategories = { { id = "all", label = "All", full = "All", count = #flat } }
    for _, group in ipairs(_jRecipeCatalog) do
        _jCategories[#_jCategories + 1] = {
            id    = string.lower(group.label),
            label = group.label,
            full  = group.label,
            count = #group.recipes,
        }
    end

    table.sort(flat, function(a, b) return a.displayName < b.displayName end)
    _jFlatRecipes = flat
    _jRecipeByName = byName
end

-- ============================================================================
-- DATA GATHERING — Journal
-- ============================================================================

function ZeD.JournalTab.gatherData(playerObj)
    local survived = playerObj:getTimeSurvived() or "Unknown"
    local zombieKills = playerObj:getZombieKills() or 0

    local md = playerObj:getModData()
    local fireKills = 0
    local carKills = 0
    local explosionKills = 0
    local weaponCats = {}

    if md and md.ZeD_Kills then
        local zk = md.ZeD_Kills
        fireKills = zk.fire or 0
        carKills = zk.vehicle or 0
        explosionKills = zk.explosion or 0

        if zk.weapon then
            for _, def in ipairs(WEAPON_CAT_ORDER) do
                weaponCats[#weaponCats + 1] = { label = def.label, count = zk.weapon[def.key] or 0 }
            end
        else
            for _, def in ipairs(WEAPON_CAT_ORDER) do
                weaponCats[#weaponCats + 1] = { label = def.label, count = 0 }
            end
        end
    end

    local totalKills = zombieKills + fireKills + carKills + explosionKills

    local journalEntries = {}
    if md and md.ZeD_Journal and md.ZeD_Journal.entries then
        journalEntries = md.ZeD_Journal.entries
    end

    return {
        survived       = survived,
        totalKills     = totalKills,
        fireKills      = fireKills,
        carKills       = carKills,
        explosionKills = explosionKills,
        weaponCats     = weaponCats,
        journalEntries = journalEntries,
    }
end

-- ============================================================================
-- DATA GATHERING — Recipes
-- ============================================================================

--- Gather recipe data in CraftingCore format (for CC.render).
-- Returns { recipes = [...], categories = [...], flatRecipes = [...] }
function ZeD.JournalTab.gatherRecipeData(playerObj, win)
    buildJournalRecipeCatalog(playerObj)
    if not _jFlatRecipes then
        return { recipes = {}, categories = _jCategories or {}, flatRecipes = {} }
    end

    -- Throttled (every 30 frames)
    win._jrecipeTimer = (win._jrecipeTimer or 0) + 1
    if win._jrecipeTimer < 30 and win._jrecipeCache then
        return win._jrecipeCache
    end
    win._jrecipeTimer = 0

    local CC = ZeD.CraftingCore

    -- Reuse existing recipe array — mutate in-place instead of 800+ new tables
    local recipes = win._jrecipeRecipes
    if not recipes then
        recipes = {}
        win._jrecipeRecipes = recipes
    end

    local idx = 0
    for _, entry in ipairs(_jFlatRecipes) do
        idx = idx + 1

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

        -- Learned check
        local learned = true
        if entry.needLearn then
            learned = false
            pcall(function() if playerObj:isRecipeKnown(entry.recipe) then learned = true end end)
        end

        -- Status: known recipes show as craftable-style, unknown as locked
        local status
        if not learned then
            status = "locked"
        elseif not hasSkill then
            status = "locked"
        else
            status = "unlocked"
        end

        local rd = recipes[idx]
        if not rd then
            rd = {}
            recipes[idx] = rd
        end
        rd.entry       = entry
        rd.status      = status
        rd.hasSkill    = hasSkill
        rd.learned     = learned
        rd.playerLevel = playerLevel
        rd.ingredients  = rd.ingredients  -- preserve from detail gather
        rd.missingCount = rd.missingCount or 0
        rd.skills       = rd.skills       -- preserve from detail gather
    end
    -- Trim excess (if catalog shrank — unlikely but safe)
    for i = idx + 1, #recipes do recipes[i] = nil end

    local data = win._jrecipeCache
    if not data then
        data = {}
        win._jrecipeCache = data
    end
    data.recipes = recipes
    data.categories = _jCategories
    data.flatRecipes = _jFlatRecipes
    return data
end

-- ============================================================================
-- HEIGHT MEASUREMENT — Journal
-- ============================================================================

function ZeD.JournalTab._measureJournalContent(data, contentW, collapsedMap)
    local T = ZeD.T
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)
    local secH  = ZeD.TM:getFontHeight(T.fontF1)
    local groupHeaderH = math.max(secH + T.px(10), T.px(26))

    local groups = groupEntriesByMonth(data.journalEntries)
    local totalH = 0

    if #groups == 0 then
        totalH = totalH + secH + T.sp.sm
    else
        for _, group in ipairs(groups) do
            totalH = totalH + groupHeaderH + T.px(1)  -- header + separator
            if not (collapsedMap and collapsedMap[group.key]) then
                for _, wrapped in ipairs(group.entries) do
                    local entry = wrapped.entry
                    totalH = totalH + secH + T.sp.rowGap
                    local lines = wrapText(entry.text, T.fontF2, contentW)
                    totalH = totalH + #lines * (bodyH + T.px(2))
                    totalH = totalH + T.sp.xs + T.px(1) + T.sp.afterGroove
                end
            end
        end
    end

    return totalH
end

-- ============================================================================
-- HEIGHT MEASUREMENT — Recipes
-- ============================================================================

function ZeD.JournalTab._measureRecipeContent(recipeData, expandedMap, contentW)
    -- Grid-based measurement (expandedMap unused, kept for signature compat)
    local T = ZeD.T
    local secH = ZeD.TM:getFontHeight(T.fontF1)
    local pillH = secH + T.px(8)
    local catBarH = pillH + T.sp.xs
    local footerH = secH + T.sp.sm
    local pad = T.sp.sm

    local itemCount = 0
    if recipeData and recipeData.groups then
        for _, group in ipairs(recipeData.groups) do
            itemCount = itemCount + #group.items
        end
    end

    local cols = math.max(1, math.floor((contentW or T.px(200)) / (T.px(RCELL_SZ) + T.px(RCELL_GAP))))
    local rows = math.ceil(itemCount / cols)
    return catBarH + rows * (T.px(RCELL_SZ) + T.px(RCELL_GAP)) + pad + footerH
end

-- ============================================================================
-- SUB-TAB STRIP — System 6 style top tabs (matches ZeD_TabPanel visual)
-- ============================================================================

--- Draw the sub-tab strip at the top of the journal drawer.
-- Stores hit zones on win._journalSubTabZones for click detection.
-- Positions the active search field (if any) to the right of the tabs.
-- @return tabStripH  Total height of the strip (T.tabH)
local function drawSubTabStrip(panel, win, x, y, w)
    local T    = ZeD.T
    local tH   = T.tabH
    local padH = T.sp.md
    local gap  = T.sp.tabGap
    local bc   = T.borderS
    local tm   = ZeD.TM
    local activeIdx = win._journalSubTab or 1

    -- Bottom border (separates strip from content below)
    panel:drawRect(x, y + tH - T.px(1), w, T.px(1), bc.a, bc.r, bc.g, bc.b)

    -- S105 gamepad: resolve currently-focused element for pill focus cue paint.
    -- Cue paints only when charTabContent is the focused zone AND the live
    -- focused element id matches this pill — persisted-state-free (S101 pattern).
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local focusedId = nil
    if Focus and Focus.getFocusedZone and Focus.getFocusedElement then
        local fz = Focus.getFocusedZone(win)
        if fz and fz.zone == "charTabContent" then
            local fe = Focus.getFocusedElement(win)
            focusedId = fe and fe.id or nil
        end
    end

    local tabX = x + T.sp.sm
    local zones = {}

    for i, tab in ipairs(SUB_TABS) do
        local tw = tm:MeasureStringX(T.fontF1, tab.label) + padH * 2
        local isActive = (i == activeIdx)

        if isActive then
            -- Active tab: surf1 fill, top+left+right border, open bottom
            panel:drawRect(tabX, y, tw, tH, T.surf1.a, T.surf1.r, T.surf1.g, T.surf1.b)
            panel:drawRect(tabX, y, tw, T.px(1), bc.a, bc.r, bc.g, bc.b)           -- top
            panel:drawRect(tabX, y, T.px(1), tH, bc.a, bc.r, bc.g, bc.b)           -- left
            panel:drawRect(tabX + tw - T.px(1), y, T.px(1), tH, bc.a, bc.r, bc.g, bc.b)  -- right
            -- Erase bottom border behind active tab (open bottom connects to content)
            panel:drawRect(tabX + T.px(1), y + tH - T.px(1), tw - T.px(2), T.px(1),
                T.surf1.a, T.surf1.r, T.surf1.g, T.surf1.b)

            local textY = y + math.floor((tH - tm:getFontHeight(T.fontF1)) / 2)
            panel:drawText(tab.label, tabX + padH, textY,
                T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a or 1, T.fontF1)
        else
            local textY = y + math.floor((tH - tm:getFontHeight(T.fontF1)) / 2)
            panel:drawText(tab.label, tabX + padH, textY,
                T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a or 1, T.fontF1)
        end

        -- S105 gamepad: focus cue overlay — painted over both active and
        -- inactive pills (covers both branches above). Sits above the pill's
        -- fill but below the label since we've already drawn the label; the
        -- 0.55α accent still reads against the text.
        if focusedId == ("jsub:" .. tostring(i)) then
            local ac = T.accent
            panel:drawRect(tabX, y, tw, tH, 0.55, ac.r, ac.g, ac.b)
        end

        zones[#zones + 1] = { idx = i, x = tabX, y = y, w = tw, h = tH }
        tabX = tabX + tw + gap
    end

    -- Position active search field to the right of the tabs
    local searchField = nil
    if activeIdx == 1 then searchField = win._journalSearch
    elseif activeIdx == 3 then
        if not win._flyerOpenIdx then searchField = win._flyerSearch end
    end
    if searchField and searchField:isVisible() then
        local searchGap = T.sp.sm
        local searchX = tabX + searchGap
        local searchW = x + w - searchX - T.sp.sm
        if searchW > T.px(60) then
            local searchH = T.inputH  -- matches crafting tab search height
            -- Center in the full 37px header (TAB_TOP_PAD + tH), not just tH
            local fullHeaderH = T.px(TAB_TOP_PAD) + tH
            local headerTopY = y - T.px(TAB_TOP_PAD)
            searchField:setX(searchX)
            searchField:setY(headerTopY + math.floor((fullHeaderH - searchH) / 2))
            searchField:setWidth(searchW)
            searchField:setHeight(searchH)
        end
    end

    win._journalSubTabZones = zones
    return tH
end

-- ============================================================================
-- RENDERER — JOURNAL SUB-TAB (full-width diary)
-- ============================================================================

local function renderJournal(panel, win, x, y, w, h)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules

    -- Search field positioned by drawSubTabStrip (in header, right of tabs)

    -- S105 gamepad: resolve the currently-focused element id for cue paints
    -- (all element types on this sub-tab share charTabContent; live element
    -- check is the authoritative paint gate — S101 pattern).
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local gpFocusedId = nil
    if Focus and Focus.getFocusedZone and Focus.getFocusedElement then
        local fz = Focus.getFocusedZone(win)
        if fz and fz.zone == "charTabContent" then
            local fe = Focus.getFocusedElement(win)
            gpFocusedId = fe and fe.id or nil
        end
    end

    -- Throttled data refresh
    win._journalTimer = (win._journalTimer or 0) + 1
    if win._journalTimer >= 15 or not win._journalCache then
        win._journalTimer = 0
        win._journalCache = ZeD.JournalTab.gatherData(win._playerObj)
    end
    local data = win._journalCache

    local bodyH = ZeD.TM:getFontHeight(T.fontF2)
    local secH  = ZeD.TM:getFontHeight(T.fontF1)

    -- Scroll setup
    local scroll  = win._journalScroll
    local scrollW = T.sp.scrollbarW
    local pad = T.sp.sm

    -- Inset content area by pad on each side (keep originals for stencil/scroll)
    local outerX = x
    local outerW = w
    x = x + pad
    w = w - pad * 2
    local contentW = w

    -- Measure Zone A (kills disclosure + entry box)
    local statRowEstH = math.max(secH, bodyH) + T.px(4)
    local zoneAEstH = T.sp.sm + statRowEstH + T.sp.rowGap
    if win._killsExpanded then
        -- 3 fixed rows (fire, vehicle, explosion) + all weapon categories
        local killRows = 3 + #data.weaponCats
        zoneAEstH = zoneAEstH + killRows * (statRowEstH + T.sp.rowGap)
    end
    zoneAEstH = zoneAEstH + T.sp.xs + T.px(2) + T.sp.afterGroove
        + T.px(ENTRY_INPUT_H) + T.sp.xs + T.buttonH + T.sp.sm + T.px(1) + T.sp.afterLine

    local entryContentH = ZeD.JournalTab._measureJournalContent(data, contentW - scrollW - T.px(2), win._journalGroupCollapsed)
    local totalContentH = zoneAEstH + entryContentH

    local needsScroll = totalContentH > h
    scroll.visible = needsScroll
    local drawW = contentW
    if needsScroll then
        scroll.x = outerX + outerW - scrollW
        scroll.y = y
        scroll.height = h
        scroll:setBarSize(h / totalContentH)
        drawW = contentW - scrollW - T.px(2)
    else
        scroll:setScrollPos(0)
    end

    -- S105 gamepad: scroll-follow with delta gate (Q99). Pin only when the
    -- focused id CHANGED — continuous pinning would fight input-mode
    -- oscillation. Uses LAST frame's zones (captured before clear) since
    -- this frame's zones aren't stamped yet. One-frame lag: imperceptible.
    if needsScroll and gpFocusedId and gpFocusedId ~= win._lastPinnedJournalId then
        local ty, th = nil, nil
        if gpFocusedId == "journal:__kills" and win._journalKillsZone then
            ty, th = win._journalKillsZone.y, win._journalKillsZone.h
        elseif gpFocusedId == "journal:__save" and win._journalSaveBtnZone then
            ty, th = win._journalSaveBtnZone.y, win._journalSaveBtnZone.h
        elseif win._journalGroupZones then
            for _, z in ipairs(win._journalGroupZones) do
                if ("journal:group:" .. tostring(z.id)) == gpFocusedId then
                    ty, th = z.y, z.h
                    break
                end
            end
        end
        if not ty and win._journalDeleteZones then
            for _, z in ipairs(win._journalDeleteZones) do
                if ("journal:del:" .. tostring(z.entryIdx)) == gpFocusedId then
                    ty, th = z.y, z.h
                    break
                end
            end
        end
        if ty and th then
            local prevScrollOff = math.floor(scroll.scrollPos * (totalContentH - h))
            local contentTy = ty - (y - prevScrollOff)  -- convert screen-space Y to content-space
            local margin = T.px(8)
            local viewTop = 0
            local viewBot = h
            local screenTop = contentTy - prevScrollOff
            local screenBot = screenTop + th
            local newOff = prevScrollOff
            if screenTop < viewTop + margin then
                newOff = math.max(0, contentTy - margin)
            elseif screenBot > viewBot - margin then
                newOff = math.min(totalContentH - h, contentTy + th - h + margin)
            end
            if newOff ~= prevScrollOff and totalContentH > h then
                scroll:setScrollPos(newOff / (totalContentH - h))
            end
        end
        win._lastPinnedJournalId = gpFocusedId
    end

    local stencilW = needsScroll and (outerW - scrollW) or outerW
    panel:setStencilRect(outerX, y, stencilW, h)

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * (totalContentH - h))
    end

    local curY = y - scrollOff + T.sp.sm

    -- Kills stat (expandable disclosure)
    local killColor = data.totalKills > 0 and T.danger or T.textDim
    local chevSz = math.max(T.px(6), math.floor(ZeD.TM:getFontHeight(T.fontF1) * 0.6))
    local chevronW = chevSz + T.px(8)
    win._killsRowY = curY
    local killsRowTop = curY
    -- S105 gamepad: focus cue painted UNDER the stat row so label/value read
    -- on top. 0.55α T.accent rect over the full drawW — matches tab header
    -- disclosure cue on Thermal/Health/Skills/Identity.
    if gpFocusedId == "journal:__kills" then
        local ac = T.accent
        -- Use conservative est height (will be ~rowH); overdraw is clipped
        -- by the content stencil so spilling by a pixel is harmless.
        local estH = math.max(bodyH, secH) + T.px(4)
        panel:drawRect(x, killsRowTop, drawW, estH, 0.55, ac.r, ac.g, ac.b)
    end
    local rowH = M.drawStatRow(panel, x + chevronW, curY, drawW - chevronW, "Zombies Killed", tostring(data.totalKills), T.toneHi, T.fontF2)
    win._killsRowH = rowH
    -- S105 gamepad: stamp the kills-row hit zone for focusable builder.
    -- Reads the real rowH returned by drawStatRow so the zone matches pixels.
    win._journalKillsZone = { x = x, y = killsRowTop, w = drawW, h = rowH }

    local chevX = x + T.px(2)
    local chevY = curY + math.floor((rowH - chevSz) / 2)
    if win._killsExpanded then
        A.drawTriangleDown(panel, chevX, chevY, chevSz, T.arrow)
    else
        A.drawTriangleRight(panel, chevX, chevY, chevSz, T.arrow)
    end
    curY = curY + rowH + T.sp.rowGap

    if win._killsExpanded then
        local indent = T.sp.md
        local innerW = drawW - indent

        rowH = M.drawStatRowDot(panel, x + indent, curY, innerW, "Fire", tostring(data.fireKills), T.warning)
        curY = curY + rowH + T.sp.rowGap
        rowH = M.drawStatRowDot(panel, x + indent, curY, innerW, "Vehicle", tostring(data.carKills), T.info)
        curY = curY + rowH + T.sp.rowGap
        rowH = M.drawStatRowDot(panel, x + indent, curY, innerW, "Explosion", tostring(data.explosionKills), T.danger)
        curY = curY + rowH + T.sp.rowGap

        for _, cat in ipairs(data.weaponCats) do
            rowH = M.drawStatRow(panel, x + indent, curY, innerW, cat.label, tostring(cat.count))
            curY = curY + rowH + T.sp.rowGap
        end
    end

    curY = curY + T.sp.xs
    A.drawGroove(panel, x, curY, drawW)
    curY = curY + T.px(2) + T.sp.afterGroove

    -- Text entry + save button (positioned on the drawer panel — they are drawer children)
    local entryBox = win._journalInput
    local saveBtn  = win._journalSaveBtn
    if entryBox then
        entryBox:setX(x)
        entryBox:setY(curY)
        entryBox:setWidth(drawW)
        entryBox:setHeight(T.px(ENTRY_INPUT_H))
        curY = curY + T.px(ENTRY_INPUT_H) + T.sp.xs
    end
    if saveBtn then
        local btnW = saveBtn:getWidth()
        local btnX = x + drawW - btnW
        saveBtn:setX(btnX)
        saveBtn:setY(curY)
        -- S105 gamepad: stamp save button hit zone + paint focus cue BEHIND
        -- the button's own render (button is a drawer child, so its prerender
        -- fires after this panel's prerender — cue ends up visually under it,
        -- but the ISButton bg is transparent so accent bleeds through on the
        -- edges as expected).
        win._journalSaveBtnZone = { x = btnX, y = curY, w = btnW, h = T.buttonH }
        if gpFocusedId == "journal:__save" then
            local ac = T.accent
            panel:drawRect(btnX, curY, btnW, T.buttonH, 0.55, ac.r, ac.g, ac.b)
        end
        curY = curY + T.buttonH + T.sp.sm
    end

    A.drawDividerH(panel, x, curY, drawW, true)
    curY = curY + T.px(1) + T.sp.afterLine

    -- Filter entries by search text (if any), then group by month
    local filteredEntries = data.journalEntries
    local searchQ = win._journalSearchText or ""
    if searchQ ~= "" then
        local q = string.lower(searchQ)
        filteredEntries = {}
        for i, entry in ipairs(data.journalEntries) do
            if string.lower(entry.text or ""):find(q, 1, true) then
                filteredEntries[#filteredEntries + 1] = entry
            end
        end
    end

    -- Journal entries — grouped by month, newest first
    local groups = groupEntriesByMonth(filteredEntries, data.journalEntries)
    local groupHeaderH = math.max(secH + T.px(10), T.px(26))
    local groupZones = {}
    local deleteZones = {}
    local chevSzG = math.max(T.px(6), math.floor(secH * 0.6))
    local deleteBtnW = secH + T.px(8)  -- hit area for X button

    if #groups == 0 then
        A.drawSecondary(panel, "No entries yet", x, curY, T.textDim)
    else
        for _, group in ipairs(groups) do
            local collapsed = win._journalGroupCollapsed[group.key]

            -- Group header row
            local headerY = curY
            -- S105 gamepad: focus cue behind the group header (chevron + label
            -- + count all read on top). Paints only when this exact group key
            -- is the focused element — discrimination by id suffix.
            if gpFocusedId == ("journal:group:" .. tostring(group.key)) then
                local ac = T.accent
                panel:drawRect(x, headerY, drawW, groupHeaderH, 0.55, ac.r, ac.g, ac.b)
            end
            local chevX2 = x + T.px(2)
            local chevY2 = curY + math.floor((groupHeaderH - chevSzG) / 2)
            if collapsed then
                A.drawTriangleRight(panel, chevX2, chevY2, chevSzG, T.arrow)
            else
                A.drawTriangleDown(panel, chevX2, chevY2, chevSzG, T.arrow)
            end
            local labelX = x + chevSzG + T.px(8)
            local labelY = curY + math.floor((groupHeaderH - secH) / 2)
            panel:drawText(group.label, labelX, labelY, T.toneLo.r, T.toneLo.g, T.toneLo.b, T.toneLo.a or 1, T.fontF1)
            -- Entry count
            local countStr = "(" .. group.count .. ")"
            local countW = ZeD.TM:MeasureStringX(T.fontF3, countStr)
            A.drawStat(panel, countStr, x + drawW - countW, labelY, T.textCat)

            groupZones[#groupZones + 1] = { id = group.key, x = x, y = headerY, w = drawW, h = groupHeaderH }
            curY = curY + groupHeaderH
            -- Thin separator below header
            A.drawDividerH(panel, x, curY, drawW)
            curY = curY + T.px(1)

            -- Entries (if not collapsed)
            if not collapsed then
                local entryIdx = 0
                for _, wrapped in ipairs(group.entries) do
                    -- Alternating entry stripe
                    if entryIdx % 2 == 1 then
                        local st = T.stripe
                        panel:drawRect(x, curY, drawW, bodyH + secH + T.sp.xs, st.a, st.r, st.g, st.b)
                    end
                    entryIdx = entryIdx + 1
                    local entry = wrapped.entry
                    local monthStr = MONTHS[(entry.month or 0) + 1] or "???"
                    local dayStr   = tostring((entry.day or 0) + 1)
                    local yearStr  = tostring(entry.year or 0)
                    local hourStr  = string.format("%02d:%02d", entry.hour or 0, entry.minute or 0)

                    -- Compute survival day (stored on new entries; derive for old ones)
                    local survDay = entry.survivalDay
                    if not survDay then
                        local gt = getGameTime()
                        local entryEpoch = (entry.year or 0) * 360 + (entry.month or 0) * 30 + (entry.day or 0)
                        local startEpoch = gt:getStartYear() * 360 + gt:getStartMonth() * 30 + gt:getStartDay()
                        survDay = math.max(1, entryEpoch - startEpoch + 1)
                    end

                    local dateStr  = "Day " .. tostring(survDay) .. "  "
                        .. monthStr .. " " .. dayStr .. ", " .. yearStr
                        .. " - " .. hourStr

                    local entryTopY = curY
                    panel:drawText(dateStr, x, curY, T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a or 1, T.fontF3)

                    -- Delete X button (right-aligned on date row)
                    local delX = x + drawW - deleteBtnW
                    local delY = curY
                    -- S105 gamepad: focus cue behind the X glyph. Entry idx
                    -- identifies the focusable uniquely — different entries
                    -- get different cues as D-pad moves through.
                    if gpFocusedId == ("journal:del:" .. tostring(wrapped.idx)) then
                        local ac = T.accent
                        panel:drawRect(delX, delY, deleteBtnW, secH, 0.55, ac.r, ac.g, ac.b)
                    end
                    A.drawSecondary(panel, "x", delX + math.floor((deleteBtnW - ZeD.TM:MeasureStringX(T.fontF1, "x")) / 2), delY, T.textDim)
                    deleteZones[#deleteZones + 1] = {
                        entryIdx = wrapped.idx,
                        x = delX, y = delY, w = deleteBtnW, h = secH,
                    }

                    curY = curY + secH + T.sp.rowGap

                    local lines = wrapText(entry.text, T.fontF2, drawW)
                    for _, line in ipairs(lines) do
                        A.drawBody(panel, line, x, curY)
                        curY = curY + bodyH + T.px(2)
                    end
                    curY = curY + T.sp.xs

                    A.drawDividerH(panel, x, curY, drawW)
                    curY = curY + T.px(1) + T.sp.afterGroove
                end
            end
        end
    end
    win._journalGroupZones  = groupZones
    win._journalDeleteZones = deleteZones

    panel:clearStencilRect()

    if needsScroll then
        scroll:draw(panel)
    end
end

-- ============================================================================
-- RECIPE DETAIL — helpers for ingredient checking (matches CraftingTab pattern)
-- ============================================================================

local DETAIL_CONTAINER_INTERVAL = 60

--- Gather detail (ingredients + skills) for one selected recipe item.
-- Uses CraftingCore shared utilities for container building, counting, and perk lookup.
--- Gather detail for selected recipe — delegates to CraftingCore.gatherDetail
local function _gatherJRecipeDetail(rd, playerObj, win)
    local CC = ZeD.CraftingCore
    CC.gatherDetail(rd, playerObj, win, "jrecipe")
    rd.maxBatchQty = 0  -- readOnly, no batch
end

-- ============================================================================
-- RENDERER — RECIPES SUB-TAB (CraftingCore layout, read-only)
-- ============================================================================

-- Config table for journal recipe viewer (read-only — no craft/build/pin)
local _jrecipeConfig = {
    prefix      = "jrecipe",
    pinKey      = nil,
    countKey    = nil,
    buildLabel  = nil,
    readOnly    = true,
    startAction = nil,
}

local function getJRecipeState(win)
    if not win._jrecipeState then
        win._jrecipeState = ZeD.CraftingCore.createState()
        win._jrecipeState.showAll = true  -- journal shows all recipes by default
    end
    return win._jrecipeState
end

local function renderRecipes(panel, win, x, y, w, h)
    local CC = ZeD.CraftingCore
    local state = getJRecipeState(win)

    -- Gather combined craft+build data in CC format
    local data = ZeD.JournalTab.gatherRecipeData(win._playerObj, win)

    -- Throttled background scan — Journal is read-only, no need for per-frame updates.
    -- Scan once on open, then every 300 frames (~5s at 60fps).
    win._jrecipeScanTimer = (win._jrecipeScanTimer or 300) + 1
    if win._jrecipeScanTimer >= 300 then
        win._jrecipeScanTimer = 0
        CC.backgroundIngredientScan(data, win, "jrecipe")
    end

    -- Gather detail for selected recipe
    if state.selected then
        for _, rd in ipairs(data.recipes) do
            if rd.entry.name == state.selected then
                _gatherJRecipeDetail(rd, win._playerObj, win)
                break
            end
        end
    end

    -- Delegate to CraftingCore (readOnly config suppresses action strip, pins, stars)
    CC.render(panel, win, x, y, w, h, state, _jrecipeConfig, data)
end

--- Click handler for journal recipes sub-tab
function ZeD.JournalTab.onRecipeClick(win, x, y)
    local state = getJRecipeState(win)
    return ZeD.CraftingCore.onClick(state, _jrecipeConfig, win, x, y, win._playerObj)
end

--- Mouse wheel handler for journal recipes sub-tab
function ZeD.JournalTab.onRecipeMouseWheel(win, del, x, y)
    local T = ZeD.T
    local state = getJRecipeState(win)
    return ZeD.CraftingCore.onMouseWheel(state, del, x, y, 0, T.px(ZeD.CraftingCore.DRAWER_W))
end

-- ============================================================================
-- MAP ANNOTATIONS — icon set, colors, data model
-- ============================================================================

-- Curated icon definitions (texture path + display label)
local MAP_ICONS = {
    { id = "house",       tex = "media/ui/LootableMaps/map_house.png",       label = "House" },
    { id = "target",      tex = "media/ui/LootableMaps/map_target.png",      label = "Target" },
    { id = "skull",       tex = "media/ui/LootableMaps/map_skull.png",       label = "Skull" },
    { id = "star",        tex = "media/ui/LootableMaps/map_star.png",        label = "Star" },
    { id = "cross",       tex = "media/ui/LootableMaps/map_cross.png",       label = "Cross" },
    { id = "heart",       tex = "media/ui/LootableMaps/map_heart.png",       label = "Heart" },
    { id = "exclamation", tex = "media/ui/LootableMaps/map_exclamation.png", label = "Alert" },
    { id = "question",    tex = "media/ui/LootableMaps/map_question.png",    label = "Question" },
    { id = "fire",        tex = "media/ui/LootableMaps/map_firet.png",       label = "Fire" },
    { id = "gun",         tex = "media/ui/LootableMaps/map_gun.png",         label = "Gun" },
    { id = "burger",      tex = "media/ui/LootableMaps/map_burger.png",      label = "Food" },
    { id = "axe",         tex = "media/ui/LootableMaps/map_axe.png",         label = "Axe" },
    { id = "gears",       tex = "media/ui/LootableMaps/map_gears.png",       label = "Gears" },
    { id = "x",           tex = "media/ui/LootableMaps/map_x.png",          label = "X" },
    { id = "checkmark",   tex = "media/ui/LootableMaps/map_checkmark.png",   label = "Check" },
}

-- Annotation color palette (matches in-game writing tools: pencil, black/blue/red/green ink)
local MAP_COLORS = {
    { r = 0.6, g = 0.6, b = 0.6, a = 0.9, label = "Pencil" },   -- grey
    { r = 0.1, g = 0.1, b = 0.1, a = 0.9, label = "Black" },     -- black ink
    { r = 0.2, g = 0.4, b = 0.9, a = 0.9, label = "Blue" },      -- blue ink
    { r = 0.9, g = 0.2, b = 0.2, a = 0.9, label = "Red" },       -- red ink
    { r = 0.2, g = 0.8, b = 0.3, a = 0.9, label = "Green" },     -- green ink
}

local MAP_ICON_BTN_SZ = 20
local MAP_ICON_BTN_GAP = 4
local MAP_COLOR_SZ = 14
local MAP_TOOLBAR_ROW_H = 28   -- single row height
local MAP_ANNOT_DRAW_SZ = 22   -- on-screen icon size
local MAP_TEXT_INPUT_H = 24     -- inline text entry height

-- Default pinned icon IDs (shown in first row without disclosure)
local MAP_DEFAULT_PINS = { "house", "target", "skull", "star", "cross", "checkmark" }

-- Lookup table for icon index by id
local MAP_ICON_BY_ID = {}
for i, icon in ipairs(MAP_ICONS) do
    MAP_ICON_BY_ID[icon.id] = icon
end

--- Get or init pinned icon list from modData (persists across saves)
local function _getMapPins(playerObj)
    local md = playerObj:getModData()
    if not md.ZeD_MapPinnedIcons then
        md.ZeD_MapPinnedIcons = {}
        for _, id in ipairs(MAP_DEFAULT_PINS) do
            md.ZeD_MapPinnedIcons[#md.ZeD_MapPinnedIcons + 1] = id
        end
    end
    return md.ZeD_MapPinnedIcons
end

--- Check if icon id is pinned
local function _isIconPinned(pins, id)
    for _, pid in ipairs(pins) do
        if pid == id then return true end
    end
    return false
end

--- Toggle pin state for an icon id
local function _togglePin(pins, id)
    for i, pid in ipairs(pins) do
        if pid == id then
            table.remove(pins, i)
            return  -- unpinned
        end
    end
    pins[#pins + 1] = id  -- pinned
end

-- ============================================================================
-- MAP PANEL — ISUIElement wrapping a Java UIWorldMap for the Maps sub-tab
-- ============================================================================

require "ISUI/Maps/ISMapDefinitions"

local ZeD_JournalMap = ISUIElement:derive("ZeD_JournalMap")

function ZeD_JournalMap:new(x, y, w, h, playerObj)
    local o = ISUIElement:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.anchorLeft   = true
    o.anchorRight  = false
    o.anchorTop    = true
    o.anchorBottom = true
    o.playerObj    = playerObj
    o.dragging     = false
    o.dragMoved    = false
    return o
end

function ZeD_JournalMap:instantiate()
    self.javaObject = UIWorldMap.new(self)
    self.mapAPI = self.javaObject:getAPIv3()

    -- Configure for journal embed (top-down, no debug, paper overlay)
    self.mapAPI:setBoolean("Isometric", false)
    self.mapAPI:setBoolean("DebugInfo", false)
    self.mapAPI:setBoolean("HideUnvisitedAreas", true)

    -- Pre-load annotation icon textures
    self._annotTextures = {}
    for _, icon in ipairs(MAP_ICONS) do
        self._annotTextures[icon.id] = getTexture(icon.tex)
    end

    self.javaObject:setX(self.x)
    self.javaObject:setY(self.y)
    self.javaObject:setWidth(self.width)
    self.javaObject:setHeight(self.height)
    self.javaObject:setAnchorLeft(true)
    self.javaObject:setAnchorRight(false)
    self.javaObject:setAnchorTop(true)
    self.javaObject:setAnchorBottom(true)

    self:createChildren()
end

function ZeD_JournalMap:createChildren()
    -- Load full world map data
    if MapUtils and MapUtils.initDefaultMapData then
        MapUtils.initDefaultMapData(self)
        self.mapAPI:setBoundsFromWorld()
        if MapUtils.initDefaultStreetData then
            MapUtils.initDefaultStreetData(self)
        end
        MapUtils.initDefaultStyleV3(self)
        if MapUtils.overlayPaper then
            MapUtils.overlayPaper(self)
        end
        -- NOTE: getSymbolsAPIv2() crashes on embedded UIWorldMaps (Java uiSymbols is null).
        -- Default annotations are skipped; we render our own overlays in render() instead.
    end

    -- Center on player position
    if self.playerObj then
        self.mapAPI:centerOn(self.playerObj:getX(), self.playerObj:getY())
        self.mapAPI:setZoom(18.0)
    end

    self._annotationsLoaded = false
end

-- Mouse drag for panning (or annotation placement when tool is active)
function ZeD_JournalMap:onMouseDown(x, y)
    local win = self._parentWin
    if win and win._mapActiveTool then
        -- Place annotation instead of panning
        local worldX = self.mapAPI:uiToWorldX(x, y)
        local worldY = self.mapAPI:uiToWorldY(x, y)
        local toolId = win._mapActiveTool
        local colorIdx = win._mapActiveColor or 1

        local md = self.playerObj:getModData()
        if not md.ZeD_MapAnnotations then md.ZeD_MapAnnotations = {} end

        if toolId == "text" then
            local noteText = "Note"
            if win._mapTextEntry then
                local t = win._mapTextEntry:getText()
                if t and t ~= "" then noteText = t end
            end

            -- If editing an existing annotation, update its text instead of creating new
            if win._mapEditAnnotIdx then
                local annots = md.ZeD_MapAnnotations
                local a = annots and annots[win._mapEditAnnotIdx]
                if a then
                    a.text = noteText
                end
                win._mapEditAnnotIdx = nil
                win._mapActiveTool = nil  -- exit edit mode
            else
                -- Place new text annotation
                local annots = md.ZeD_MapAnnotations
                annots[#annots + 1] = {
                    worldX   = worldX,
                    worldY   = worldY,
                    iconId   = "text",
                    colorIdx = colorIdx,
                    text     = noteText,
                }
            end
        else
            -- Place icon annotation immediately (persistent mode — tool stays active)
            local annots = md.ZeD_MapAnnotations
            annots[#annots + 1] = {
                worldX   = worldX,
                worldY   = worldY,
                iconId   = toolId,
                colorIdx = colorIdx,
                text     = "",
            }
        end
        return true
    end

    self.dragging = true
    self.dragMoved = false
    self.dragStartX = x
    self.dragStartY = y
    self.dragStartCX = self.mapAPI:getCenterWorldX()
    self.dragStartCY = self.mapAPI:getCenterWorldY()
    self.dragStartZoomF = self.mapAPI:getZoomF()
    self.dragStartWorldX = self.mapAPI:uiToWorldX(x, y)
    self.dragStartWorldY = self.mapAPI:uiToWorldY(x, y)
    return true
end


function ZeD_JournalMap:onMouseMove(dx, dy)
    local T = ZeD.T
    if self.dragging then
        local mouseX = self:getMouseX()
        local mouseY = self:getMouseY()
        if not self.dragMoved
           and math.abs(mouseX - self.dragStartX) <= T.px(4)
           and math.abs(mouseY - self.dragStartY) <= T.px(4) then
            return
        end
        self.dragMoved = true
        local worldX = self.mapAPI:uiToWorldX(mouseX, mouseY,
            self.dragStartZoomF, self.dragStartCX, self.dragStartCY)
        local worldY = self.mapAPI:uiToWorldY(mouseX, mouseY,
            self.dragStartZoomF, self.dragStartCX, self.dragStartCY)
        self.mapAPI:centerOn(
            self.dragStartCX + self.dragStartWorldX - worldX,
            self.dragStartCY + self.dragStartWorldY - worldY)
    end
    return true
end

function ZeD_JournalMap:onMouseUp(x, y)
    self.dragging = false
    return true
end

-- Right-click: context menu for annotation edit/delete
function ZeD_JournalMap:onRightMouseDown(x, y)
    local T = ZeD.T
    if not self._annotationHits then return false end

    -- Hit-test against rendered annotations (16px radius)
    local hitRadius = T.px(16)
    for _, hit in ipairs(self._annotationHits) do
        local cx = hit.x + hit.w / 2
        local cy = hit.y + hit.h / 2
        local dx = x - cx
        local dy = y - cy
        if dx * dx + dy * dy <= hitRadius * hitRadius then
            -- Found hit — show context menu
            local md = self.playerObj:getModData()
            local annots = md and md.ZeD_MapAnnotations
            if not annots then return true end

            local ann = annots[hit.idx]
            if not ann then return true end

            local ctx = ISContextMenu.get(0, self:getAbsoluteX() + x, self:getAbsoluteY() + y)

            -- Delete option
            ctx:addOption("Delete", self, function(self2)
                local md2 = self2.playerObj:getModData()
                if md2.ZeD_MapAnnotations then
                    table.remove(md2.ZeD_MapAnnotations, hit.idx)
                end
            end)

            -- Cycle color option
            ctx:addOption("Change Color", self, function(self2)
                local md2 = self2.playerObj:getModData()
                local a = md2.ZeD_MapAnnotations and md2.ZeD_MapAnnotations[hit.idx]
                if a then
                    a.colorIdx = ((a.colorIdx or 1) % #MAP_COLORS) + 1
                end
            end)

            -- Edit note — activate text tool with pre-filled text, set edit index
            ctx:addOption("Edit Note", self, function(self2)
                local win = self2._parentWin
                if not win then return end
                local md2 = self2.playerObj:getModData()
                local a = md2.ZeD_MapAnnotations and md2.ZeD_MapAnnotations[hit.idx]
                if a then
                    win._mapActiveTool = "text"
                    win._mapEditAnnotIdx = hit.idx
                    if win._mapTextEntry then
                        win._mapTextEntry:setText(a.text or "")
                        win._mapTextEntry:setVisible(true)
                    end
                end
            end)

            return true
        end
    end
    return false
end

-- Mouse wheel for zoom
function ZeD_JournalMap:onMouseWheel(del)
    self.mapAPI:zoomAt(self:getMouseX(), self:getMouseY(), del)
    return true
end

-- Get bounds of a stash map by name (cached, uses temporary UIWorldMap)
function ZeD_JournalMap:getStashMapBounds(stashName)
    self._stashBounds = self._stashBounds or {}
    if self._stashBounds[stashName] then
        return self._stashBounds[stashName]
    end
    -- Create temp UIWorldMap for bounds calculation (same pattern as ISWorldMap)
    if not self._boundsUI then
        local ui = {}
        ui.javaObject = UIWorldMap.new(ui)
        ui.mapAPI = ui.javaObject:getAPIv3()
        self._boundsUI = ui
    end
    local bounds = {}
    local f = LootMaps and LootMaps.Init and LootMaps.Init[stashName]
    if f then
        self._boundsUI.mapAPI:clearData()
        self._boundsUI.mapAPI:getStyleAPI():clear()
        f(self._boundsUI)
        bounds.x1 = self._boundsUI.mapAPI:getMinXInSquares()
        bounds.y1 = self._boundsUI.mapAPI:getMinYInSquares()
        bounds.x2 = self._boundsUI.mapAPI:getMaxXInSquares() + 1
        bounds.y2 = self._boundsUI.mapAPI:getMaxYInSquares() + 1
    end
    self._stashBounds[stashName] = bounds
    return bounds
end

-- Render stash map icons on top of the world map (called from render())
function ZeD_JournalMap:renderStashMaps()
    local T = ZeD.T
    if not StashSystem then return end
    local stashNameList = StashSystem.getAlreadyReadMap()
    if not stashNameList then return end

    local iconTex = getTexture("Item_Map")
    if not iconTex then return end
    local iconSize = T.px(24)
    local pw, ph = self:getWidth(), self:getHeight()

    for i = 1, stashNameList:size() do
        local stashName = stashNameList:get(i - 1)
        local bounds = self:getStashMapBounds(stashName)
        if bounds and bounds.x1 then
            local cx = bounds.x1 / 2 + bounds.x2 / 2
            local cy = bounds.y1 / 2 + bounds.y2 / 2
            local sx = self.mapAPI:worldToUIX(cx, cy) - iconSize / 2
            local sy = self.mapAPI:worldToUIY(cx, cy) - iconSize / 2
            -- Only draw if on-screen
            if sx > -iconSize and sy > -iconSize and sx < pw and sy < ph then
                self:drawTextureScaledAspect(iconTex, sx, sy, iconSize, iconSize, 1.0, 1.0, 1.0, 1.0)
            end
        end
    end
end

-- Render flyer location markers from PrintMediaDefinitions
function ZeD_JournalMap:renderFlyerMarkers()
    if not PrintMediaDefinitions or not PrintMediaDefinitions.MiscDetails then return end

    local T = ZeD.T
    local dotSz = T.px(8)
    local ac = T.accent
    local pw, ph = self:getWidth(), self:getHeight()

    for _, detail in pairs(PrintMediaDefinitions.MiscDetails) do
        if detail.location1 then
            for _, loc in ipairs(detail.location1) do
                local cx = (loc.x1 + loc.x2) / 2
                local cy = (loc.y1 + loc.y2) / 2
                local sx = self.mapAPI:worldToUIX(cx, cy) - dotSz / 2
                local sy = self.mapAPI:worldToUIY(cx, cy) - dotSz / 2
                -- Only draw if on-screen
                if sx > -dotSz and sy > -dotSz and sx < pw and sy < ph then
                    self:drawRect(sx, sy, dotSz, dotSz, 0.8, ac.r, ac.g, ac.b)
                end
            end
        end
    end
end

-- Render user-placed annotations from modData
function ZeD_JournalMap:renderAnnotations()
    local md = self.playerObj:getModData()
    local annots = md and md.ZeD_MapAnnotations
    if not annots or #annots == 0 then return end

    local T = ZeD.T
    local tm = ZeD.TM
    local pw, ph = self:getWidth(), self:getHeight()
    local sz = T.px(MAP_ANNOT_DRAW_SZ)
    local halfSz = sz / 2

    -- Build hit-test list for right-click detection
    self._annotationHits = {}

    for i, ann in ipairs(annots) do
        local sx = self.mapAPI:worldToUIX(ann.worldX, ann.worldY) - halfSz
        local sy = self.mapAPI:worldToUIY(ann.worldX, ann.worldY) - halfSz

        -- Cull off-screen
        if sx > -sz and sy > -sz and sx < pw and sy < ph then
            -- Get color from palette
            local colorDef = MAP_COLORS[ann.colorIdx or 1] or MAP_COLORS[1]
            local c = colorDef

            -- Draw icon texture with color tint, or dot for text annotations
            if ann.iconId == "text" then
                -- Text note marker: small filled dot (6px)
                local dotSz = T.px(6)
                local dotX = sx + halfSz - dotSz / 2
                local dotY = sy + halfSz - dotSz / 2
                -- Dot body (approximate circle: 3 rows)
                self:drawRect(dotX + T.px(1), dotY,     dotSz - T.px(2), T.px(1),        0.9, c.r, c.g, c.b)
                self:drawRect(dotX,     dotY + T.px(1), dotSz,     dotSz - T.px(2), 0.9, c.r, c.g, c.b)
                self:drawRect(dotX + T.px(1), dotY + dotSz - T.px(1), dotSz - T.px(2), T.px(1), 0.9, c.r, c.g, c.b)
            else
                local tex = self._annotTextures and self._annotTextures[ann.iconId]
                if tex then
                    self:drawTextureScaledAspect(tex, sx, sy, sz, sz, 0.9, c.r, c.g, c.b)
                else
                    -- Fallback: X mark (two diagonals)
                    local m = T.px(4)
                    for di = 0, sz - m * 2 - 1 do
                        self:drawRect(sx + m + di, sy + m + di, T.px(1), T.px(1), 0.7, c.r, c.g, c.b)
                        self:drawRect(sx + m + di, sy + sz - m - T.px(1) - di, T.px(1), T.px(1), 0.7, c.r, c.g, c.b)
                    end
                end
            end

            -- Text label (if any) — drawn above the icon
            if ann.text and ann.text ~= "" then
                local tw = tm:MeasureStringX(T.fontF1, ann.text)
                local tx = sx + halfSz - tw / 2
                local ty = sy - tm:getFontHeight(T.fontF1) - T.px(2)
                -- Drop shadow for readability
                self:drawText(ann.text, tx + T.px(1), ty + T.px(1), 0, 0, 0, 0.6, T.fontF1)
                self:drawText(ann.text, tx, ty, c.r, c.g, c.b, 1, T.fontF1)
            end

            -- Store hit area for right-click detection
            self._annotationHits[#self._annotationHits + 1] = {
                idx = i,
                x = sx, y = sy, w = sz, h = sz,
            }
        end
    end
end

-- Render cursor preview when a tool is active (ghost icon follows mouse)
function ZeD_JournalMap:renderToolCursor()
    local win = self._parentWin
    if not win or not win._mapActiveTool then return end

    local mx, my = self:getMouseX(), self:getMouseY()
    if mx < 0 or my < 0 or mx > self:getWidth() or my > self:getHeight() then return end

    local T = ZeD.T
    local sz = T.px(MAP_ANNOT_DRAW_SZ)
    local colorDef = MAP_COLORS[win._mapActiveColor or 1] or MAP_COLORS[1]
    local c = colorDef

    if win._mapActiveTool == "text" then
        -- Ghost dot for text note placement
        local dotSz = T.px(6)
        local dotX = mx - dotSz / 2
        local dotY = my - dotSz / 2
        self:drawRect(dotX + T.px(1), dotY,     dotSz - T.px(2), T.px(1),        0.4, c.r, c.g, c.b)
        self:drawRect(dotX,     dotY + T.px(1), dotSz,     dotSz - T.px(2), 0.4, c.r, c.g, c.b)
        self:drawRect(dotX + T.px(1), dotY + dotSz - T.px(1), dotSz - T.px(2), T.px(1), 0.4, c.r, c.g, c.b)
        -- Preview the text that will be placed
        local previewText = (win._mapTextEntry and win._mapTextEntry:getText()) or "Note"
        if previewText ~= "" then
            self:drawText(previewText, mx + T.px(6), my - T.px(10), c.r, c.g, c.b, 0.4, T.fontF1)
        end
    else
        local tex = self._annotTextures and self._annotTextures[win._mapActiveTool]
        if tex then
            self:drawTextureScaledAspect(tex, mx - sz / 2, my - sz / 2, sz, sz, 0.5, c.r, c.g, c.b)
        end
    end
end

-- ISUIElement render — draw overlays on top of the Java map.
-- NOTE: Do NOT call ISUIElement.render(self) — Java UIWorldMap handles its own rendering.
-- NOTE: getSymbolsAPIv2() crashes on embedded UIWorldMaps; we render our own overlays.
function ZeD_JournalMap:render()
    self:renderStashMaps()
    self:renderFlyerMarkers()
    self:renderAnnotations()
    self:renderToolCursor()
end

-- ============================================================================
-- RENDERER — MAPS SUB-TAB
-- ============================================================================

--- Draw a single icon tool button at (bx, by). Returns next X.
local function _drawIconBtn(panel, win, icon, bx, by, btnSz, isActive, isPinned)
    local T = ZeD.T

    -- Button background
    if isActive then
        local ac = T.accent
        panel:drawRect(bx, by, btnSz, btnSz, 0.2, ac.r, ac.g, ac.b)
        panel:drawRectBorder(bx, by, btnSz, btnSz, 0.6, ac.r, ac.g, ac.b)
    else
        local bd = T.border
        panel:drawRectBorder(bx, by, btnSz, btnSz, bd.a * 0.3, bd.r, bd.g, bd.b)
    end

    -- Icon texture — drawn in T.text (white/black), NOT ink color
    local mapPanel = win._worldMapPanel
    local tex = mapPanel and mapPanel._annotTextures and mapPanel._annotTextures[icon.id]
    if tex then
        local tc = isActive and T.accent or T.text
        local alpha = isActive and 0.9 or 0.6
        panel:drawTextureScaledAspect(tex, bx + T.px(2), by + T.px(2), btnSz - T.px(4), btnSz - T.px(4),
            alpha, tc.r, tc.g, tc.b)
    else
        local lbl = string.sub(icon.label, 1, 1)
        local dc = isActive and T.accent or T.textDim
        panel:drawText(lbl, bx + T.px(5), by + T.px(2), dc.r, dc.g, dc.b, 0.6, T.fontF1)
    end

    -- Pin dot (small accent dot top-left if pinned, in expanded view)
    if isPinned then
        local ac = T.accent
        panel:drawRect(bx + T.px(1), by + T.px(1), T.px(3), T.px(3), 0.7, ac.r, ac.g, ac.b)
    end

    -- Click zone
    win._mapToolZones[#win._mapToolZones + 1] = {
        id = icon.id,
        x = bx, y = by, w = btnSz, h = btnSz,
    }
end

local function renderMapToolbar(panel, win, x, y, w)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local secH = tm:getFontHeight(T.fontF1)
    local btnSz  = T.px(MAP_ICON_BTN_SZ)
    local btnGap = T.px(MAP_ICON_BTN_GAP)
    local colSz  = T.px(MAP_COLOR_SZ)

    -- Clear toolbar zones
    win._mapToolZones  = {}
    win._mapColorZones = {}
    win._mapToolRMBZones = {}  -- for RMB pin toggling

    local activeTool  = win._mapActiveTool
    local activeColor = win._mapActiveColor or 1
    local expanded    = win._mapToolsExpanded or false
    local pins        = _getMapPins(win._playerObj)

    local rowH = T.px(MAP_TOOLBAR_ROW_H)
    local btnY = y + math.floor((rowH - btnSz) / 2)

    -- ---- Row 1: disclosure chevron + pinned icons + Aa + separator + color swatches ----
    local curX = x + T.px(4)

    -- Disclosure chevron
    local chevSz = math.max(T.px(8), math.floor(secH * 0.7))
    local chevY  = y + math.floor((rowH - chevSz) / 2)
    if expanded then
        A.drawTriangleDown(panel, curX, chevY, chevSz, T.arrow)
    else
        A.drawTriangleRight(panel, curX, chevY, chevSz, T.arrow)
    end
    win._mapDisclosureZone = { x = curX, y = y, w = chevSz + T.px(4), h = rowH }
    curX = curX + chevSz + T.px(6)

    -- Pinned icon buttons (first row)
    for _, pid in ipairs(pins) do
        local icon = MAP_ICON_BY_ID[pid]
        if icon then
            local isActive = (activeTool == icon.id)
            _drawIconBtn(panel, win, icon, curX, btnY, btnSz, isActive, false)
            curX = curX + btnSz + btnGap
        end
    end

    -- "Aa" text note button
    curX = curX + btnGap
    local textActive = (activeTool == "text")
    if textActive then
        local ac = T.accent
        panel:drawRect(curX, btnY, btnSz, btnSz, 0.2, ac.r, ac.g, ac.b)
        panel:drawRectBorder(curX, btnY, btnSz, btnSz, 0.6, ac.r, ac.g, ac.b)
    else
        local bd = T.border
        panel:drawRectBorder(curX, btnY, btnSz, btnSz, bd.a * 0.3, bd.r, bd.g, bd.b)
    end
    local tC = textActive and T.accent or T.textDim
    panel:drawText("Aa", curX + T.px(2), btnY + T.px(2), tC.r, tC.g, tC.b, 0.7, T.fontF1)
    win._mapToolZones[#win._mapToolZones + 1] = {
        id = "text",
        x = curX, y = btnY, w = btnSz, h = btnSz,
    }
    curX = curX + btnSz + btnGap * 2

    -- Separator
    local sepC = T.border
    panel:drawRect(curX, btnY, T.px(1), btnSz, sepC.a * 0.4, sepC.r, sepC.g, sepC.b)
    curX = curX + T.px(1) + btnGap * 2

    -- Color swatches
    local colY = y + math.floor((rowH - colSz) / 2)
    for ci, colorDef in ipairs(MAP_COLORS) do
        local c = colorDef
        local isActiveCol = (ci == activeColor)

        panel:drawRect(curX, colY, colSz, colSz, 0.85, c.r, c.g, c.b)
        if isActiveCol then
            local bd = T.text
            panel:drawRectBorder(curX - T.px(1), colY - T.px(1), colSz + T.px(2), colSz + T.px(2),
                bd.a, bd.r, bd.g, bd.b)
        end

        win._mapColorZones[#win._mapColorZones + 1] = {
            idx = ci,
            x = curX, y = colY, w = colSz, h = colSz,
        }

        curX = curX + colSz + btnGap
    end

    local totalH = rowH

    -- ---- Expanded rows: ALL icons in a wrapping grid ----
    if expanded then
        local gridX = x + T.px(4)
        local gridY = y + rowH
        local gridW = w - T.px(8)
        local maxCols = math.max(1, math.floor(gridW / (btnSz + btnGap)))
        local col = 0
        local rowIdx = 0
        local gx, gy

        -- Bottom border for first row
        local bd = T.border
        panel:drawRect(x, gridY - T.px(1), w, T.px(1), bd.a * 0.2, bd.r, bd.g, bd.b)

        -- Background for expanded area
        local s1 = T.surf1
        local expandedRowCount = math.ceil(#MAP_ICONS / maxCols)
        local expandedH = expandedRowCount * (btnSz + btnGap) + btnGap
        panel:drawRect(x, gridY, w, expandedH, s1.a, s1.r, s1.g, s1.b)

        for _, icon in ipairs(MAP_ICONS) do
            gx = gridX + col * (btnSz + btnGap)
            gy = gridY + btnGap + rowIdx * (btnSz + btnGap)
            local isActive = (activeTool == icon.id)
            local isPinned = _isIconPinned(pins, icon.id)
            _drawIconBtn(panel, win, icon, gx, gy, btnSz, isActive, isPinned)

            -- RMB zone for pin toggling
            win._mapToolRMBZones[#win._mapToolRMBZones + 1] = {
                id = icon.id,
                x = gx, y = gy, w = btnSz, h = btnSz,
            }

            col = col + 1
            if col >= maxCols then
                col = 0
                rowIdx = rowIdx + 1
            end
        end

        totalH = totalH + expandedH
    end

    -- ---- Inline text input (visible when text tool is active) ----
    if textActive then
        local inputY = y + totalH
        local inputX = x + T.px(4)
        local inputW = w - T.px(8)
        local inputBg = T.surf2
        panel:drawRect(x, inputY, w, T.px(MAP_TEXT_INPUT_H), inputBg.a, inputBg.r, inputBg.g, inputBg.b)
        local bds = T.borderS
        panel:drawRect(x, inputY + T.px(MAP_TEXT_INPUT_H) - T.px(1), w, T.px(1), bds.a * 0.3, bds.r, bds.g, bds.b)

        -- Position the text entry child (created lazily in renderMaps)
        if win._mapTextEntry then
            win._mapTextEntry:setX(inputX)
            win._mapTextEntry:setY(inputY + T.px(2))
            win._mapTextEntry:setWidth(inputW)
            win._mapTextEntry:setHeight(T.px(MAP_TEXT_INPUT_H) - T.px(4))
            win._mapTextEntry:setVisible(true)
        end

        totalH = totalH + T.px(MAP_TEXT_INPUT_H)
    else
        if win._mapTextEntry then
            win._mapTextEntry:setVisible(false)
        end
    end

    return totalH
end

local function renderMaps(panel, win, x, y, w, h)
    -- Draw toolbar strip at top (dynamic height due to disclosure + text input)
    local T = ZeD.T
    local toolbarBg = T.surf1
    -- Draw base row background first (renderMapToolbar handles expanded bg)
    panel:drawRect(x, y, w, T.px(MAP_TOOLBAR_ROW_H), toolbarBg.a, toolbarBg.r, toolbarBg.g, toolbarBg.b)

    -- Lazy-create inline text entry for map annotations
    if not win._mapTextEntry then
        local te = ISTextEntryBox:new("Note", 0, 0, T.px(100), T.px(MAP_TEXT_INPUT_H) - T.px(4))
        te:initialise()
        te.zedEntry = true   -- typed text follows the UI scale (ZeD.Text.fitEntry)
        te:setVisible(false)
        panel:addChild(te)
        win._mapTextEntry = te
    end

    local toolbarH = renderMapToolbar(panel, win, x, y, w)
    local bd = T.border
    panel:drawRect(x, y + toolbarH - T.px(1), w, T.px(1), bd.a * 0.3, bd.r, bd.g, bd.b)

    -- Map area below toolbar
    local mapY = y + toolbarH
    local mapH = h - toolbarH

    -- Lazy-create the world map panel on first Maps sub-tab activation
    if not win._worldMapPanel and not win._worldMapFailed then
        local ok, err = pcall(function()
            local mp = ZeD_JournalMap:new(x, mapY, w, mapH, win._playerObj)
            mp._parentWin = win  -- back-reference for tool state access
            mp:initialise()
            mp:instantiate()
            panel:addChild(mp)
            win._worldMapPanel = mp
        end)
        if not ok then
            win._worldMapFailed = true
            -- Map init failure logged silently; panel won't render
        end
    end

    if win._worldMapPanel then
        -- Reposition/resize to match current drawer geometry (below toolbar)
        local mp = win._worldMapPanel
        mp:setX(x)
        mp:setY(mapY)
        mp:setWidth(w)
        mp:setHeight(mapH)
        mp:setVisible(true)
    else
        -- Fallback: show error state
        local secH = ZeD.TM:getFontHeight(T.fontF1)
        local centerX = x + math.floor(w / 2)
        local centerY = mapY + math.floor(mapH / 2) - secH
        local label = "MAP UNAVAILABLE"
        local labelW = ZeD.TM:MeasureStringX(T.fontF1, label)
        ZeD.Atoms.drawSecondary(panel, label, centerX - math.floor(labelW / 2), centerY, T.textDim)
    end
end

-- ============================================================================
-- FLYER CATALOG (built once, module-level cache)
-- ============================================================================

local _flyerCatalog = nil

--- Build flyer catalog from PrintMediaDefinitions.MiscDetails.
-- Attempts to load textures from FlyerPics/ using capitalized key names.
local function buildFlyerCatalog()
    if _flyerCatalog then return _flyerCatalog end
    _flyerCatalog = {}

    if not PrintMediaDefinitions or not PrintMediaDefinitions.MiscDetails then
        return _flyerCatalog
    end

    -- Collect and sort keys for stable ordering
    local keys = {}
    for key, _ in pairs(PrintMediaDefinitions.MiscDetails) do
        keys[#keys + 1] = key
    end
    table.sort(keys)

    for _, key in ipairs(keys) do
        -- Capitalize first letter for texture lookup
        local texName = key:sub(1, 1):upper() .. key:sub(2)
        local texPath = "media/textures/printMedia/FlyerPics/" .. texName .. ".png"
        local tex = getTexture(texPath)

        -- Build display name: insert spaces before uppercase runs in the key
        local displayName = texName:gsub("(%l)(%u)", "%1 %2")
                                   :gsub("(%u+)(%u%l)", "%1 %2")
                                   :gsub("(%a)(%d)", "%1 %2")

        _flyerCatalog[#_flyerCatalog + 1] = {
            key         = key,
            displayName = displayName,
            texture     = tex,
            hasLocation = PrintMediaDefinitions.MiscDetails[key].location1 ~= nil,
        }
    end

    return _flyerCatalog
end

-- ============================================================================
-- FLYER COLLECTION DATA — tracks read/unread state via getReadPrintMedia()
-- ============================================================================

local function gatherFlyerCollectionData(win)
    win._flyerCollectTimer = (win._flyerCollectTimer or 60) + 1
    if win._flyerCollectTimer < 60 and win._flyerCollected then return end
    win._flyerCollectTimer = 0

    local collected = {}
    local count = 0
    local ok, readSet = pcall(function() return win._playerObj:getReadPrintMedia() end)
    if ok and readSet then
        local iter = readSet:iterator()
        while iter:hasNext() do
            local id = iter:next()
            collected[id] = true
            count = count + 1
        end
    end
    win._flyerCollected   = collected
    win._flyerCollectedCt = count
end

-- ============================================================================
-- RENDERER — FLYERS SUB-TAB (collected print media gallery)
-- ============================================================================

local FLYER_MIN_THUMB_W = 60  -- minimum thumbnail width
local FLYER_TARGET_COLS = 5   -- preferred column count
local FLYER_COL_GAP = 6      -- gap between columns
local FLYER_ROW_GAP = 6      -- gap between rows

-- Flyer filter/sort modes — single cycle button advances through these
local FLYER_MODES = {
    { id = "all_az",  label = "All A-Z" },
    { id = "all_za",  label = "All Z-A" },
    { id = "read",    label = "Read" },
    { id = "unread",  label = "Unread" },
    { id = "on_map",  label = "On Map" },
}

--- Render detail view: flyer fills drawer width, scrollable vertically
local function renderFlyerDetail(panel, win, x, y, w, h)
    local T   = ZeD.T
    local A   = ZeD.Atoms
    local tm  = ZeD.TM
    local secH  = tm:getFontHeight(T.fontF1)
    local pad = T.sp.sm

    -- S105 gamepad: live focused element id for back-button cue.
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local gpFocusedId = nil
    if Focus and Focus.getFocusedZone and Focus.getFocusedElement then
        local fz = Focus.getFocusedZone(win)
        if fz and fz.zone == "charTabContent" then
            local fe = Focus.getFocusedElement(win)
            gpFocusedId = fe and fe.id or nil
        end
    end

    local catalog = buildFlyerCatalog()
    local idx = win._flyerOpenIdx
    local flyer = catalog[idx]
    if not flyer then
        win._flyerOpenIdx = nil
        return
    end

    -- Scroll setup (reuse flyers scroll for detail view)
    local scroll  = win._flyersScroll
    local scrollW = T.sp.scrollbarW

    -- Image fills width, height from aspect ratio
    local imgW = w - pad * 2 - scrollW - T.px(2)
    local imgH = imgW  -- default square if no texture
    if flyer.texture then
        local texW = flyer.texture:getWidth()
        local texH = flyer.texture:getHeight()
        imgH = math.floor(imgW * (texH / texW))
    end

    -- Total content: back button + image
    local backH = T.buttonH
    local totalContentH = pad + backH + pad + imgH + pad

    local needsScroll = totalContentH > h
    scroll.visible = needsScroll
    local drawW = w
    if needsScroll then
        scroll.x = x + w - scrollW
        scroll.y = y
        scroll.height = h
        scroll:setBarSize(h / totalContentH)
        drawW = w - scrollW - T.px(2)
        imgW = drawW - pad * 2
        if flyer.texture then
            local texW = flyer.texture:getWidth()
            local texH = flyer.texture:getHeight()
            imgH = math.floor(imgW * (texH / texW))
        end
        totalContentH = pad + backH + pad + imgH + pad
        scroll:setBarSize(h / totalContentH)
    else
        scroll:setScrollPos(0)
    end

    -- S105 gamepad: grid-scroll pseudo-zone for flyer detail. Covers the
    -- image region below the back button; D-pad up/down on this pseudo-zone
    -- scrolls the flyer image. Only stamped when scrolling is actually
    -- needed (tall flyer doesn't fit viewport).
    if needsScroll then
        win._flyerDetailScrollZone = { x = x, y = y, w = drawW, h = h }
    else
        win._flyerDetailScrollZone = nil
    end

    local stencilW = needsScroll and (w - scrollW) or w
    panel:setStencilRect(x, y, stencilW, h)

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * (totalContentH - h))
    end

    local curY = y - scrollOff + pad

    -- Back button (top-left)
    local backLabel = "< BACK"
    local backW = tm:MeasureStringX(T.fontF1, backLabel) + T.sp.md * 2
    local backX = x + pad

    local bc = T.borderS
    panel:drawRect(backX, curY, backW, backH, T.surf2.a, T.surf2.r, T.surf2.g, T.surf2.b)
    panel:drawRectBorder(backX, curY, backW, backH, bc.a, bc.r, bc.g, bc.b)
    -- S105 gamepad: focus cue over the back button. Paints on top of the
    -- surf2 fill; label renders after so it's readable over accent.
    if gpFocusedId == "flyer:__back" then
        local ac = T.accent
        panel:drawRect(backX, curY, backW, backH, 0.55, ac.r, ac.g, ac.b)
    end
    local btY = curY + math.floor((backH - secH) / 2)
    local tc = T.toneNorm
    panel:drawText(backLabel, backX + T.sp.md, btY, tc.r, tc.g, tc.b, tc.a or 1, T.fontF1)

    -- Store back button zone for click detection
    win._flyerBackZone = { x = backX, y = curY, w = backW, h = backH }
    curY = curY + backH + pad

    -- Flyer image: fills width, natural aspect ratio, scrollable
    local imgX = x + pad
    if flyer.texture then
        panel:drawTextureScaledAspect(flyer.texture, imgX, curY,
            imgW, imgH, 1.0, 1, 1, 1)
        local bd = T.border
        panel:drawRectBorder(imgX, curY, imgW, imgH, bd.a * 0.3, bd.r, bd.g, bd.b)
    else
        local bg = T.surf2
        panel:drawRect(imgX, curY, imgW, imgH, bg.a * 0.5, bg.r, bg.g, bg.b)
        local msg = "No preview available"
        local msgW = tm:MeasureStringX(T.fontF1, msg)
        local dc = T.textDim
        panel:drawText(msg, imgX + math.floor((imgW - msgW) / 2),
            curY + math.floor(imgH / 2), dc.r, dc.g, dc.b, 0.5, T.fontF1)
    end

    panel:clearStencilRect()

    if needsScroll then
        scroll:draw(panel)
    end
end

local function renderFlyers(panel, win, x, y, w, h)
    -- Detail view: single flyer fills the drawer
    if win._flyerOpenIdx then
        renderFlyerDetail(panel, win, x, y, w, h)
        return
    end

    local T    = ZeD.T
    local A    = ZeD.Atoms
    local tm   = ZeD.TM
    local secH = tm:getFontHeight(T.fontF1)

    -- S105 gamepad: live focused element id for cue paints (mode pill + thumbs).
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    local gpFocusedId = nil
    if Focus and Focus.getFocusedZone and Focus.getFocusedElement then
        local fz = Focus.getFocusedZone(win)
        if fz and fz.zone == "charTabContent" then
            local fe = Focus.getFocusedElement(win)
            gpFocusedId = fe and fe.id or nil
        end
    end

    -- Search field positioned by drawSubTabStrip (in header, right of tabs)

    local catalog = buildFlyerCatalog()

    -- Refresh read/unread collection data (throttled)
    gatherFlyerCollectionData(win)
    local collected = win._flyerCollected or {}
    local collectedCt = win._flyerCollectedCt or 0

    -- Filter by search text
    local searchQ = win._flyerSearchText or ""
    if searchQ ~= "" then
        local q = string.lower(searchQ)
        local filtered = {}
        for _, flyer in ipairs(catalog) do
            if string.lower(flyer.displayName):find(q, 1, true) then
                filtered[#filtered + 1] = flyer
            end
        end
        catalog = filtered
    end

    -- Apply mode filter/sort (cycle button)
    local modeIdx = win._flyerModeIdx or 1
    local mode = FLYER_MODES[modeIdx]
    if mode then
        if mode.id == "all_za" then
            -- Reverse alphabetical (catalog is already A-Z from buildFlyerCatalog)
            local reversed = {}
            for i = #catalog, 1, -1 do reversed[#reversed + 1] = catalog[i] end
            catalog = reversed
        elseif mode.id == "read" then
            local f = {}
            for _, flyer in ipairs(catalog) do
                if collected[flyer.key] then f[#f + 1] = flyer end
            end
            catalog = f
        elseif mode.id == "unread" then
            local f = {}
            for _, flyer in ipairs(catalog) do
                if not collected[flyer.key] then f[#f + 1] = flyer end
            end
            catalog = f
        elseif mode.id == "on_map" then
            local f = {}
            for _, flyer in ipairs(catalog) do
                if flyer.hasLocation then f[#f + 1] = flyer end
            end
            catalog = f
        end
        -- "all_az" is the default order — no transform needed
    end

    -- S105 gamepad: cache last frame's zones BEFORE clearing for scroll-follow.
    local lastFlyerClickZones = win._flyerClickZones
    local lastFlyerModeZone   = win._flyerModeZone

    -- Clear click zones
    win._flyerClickZones = nil
    win._flyerBackZone = nil
    win._flyerModeZone = nil

    -- Scroll setup
    local scroll  = win._flyersScroll
    local scrollW = T.sp.scrollbarW
    local tabPadG = ZeD.Molecules.getTabPad()  -- template padding for grid

    -- Responsive grid: fill available width, maintain 2:3 aspect ratio
    local progRowH = secH + T.px(8) + T.sp.xs
    local headerH = T.sp.sm + progRowH

    -- Compute responsive thumb size from available width
    local function computeGrid(availW)
        local gridW = availW - tabPadG * 2
        -- How many columns fit at minimum thumb width?
        local minCellW = T.px(FLYER_MIN_THUMB_W) + T.px(FLYER_COL_GAP)
        local cols = math.max(1, math.floor((gridW + T.px(FLYER_COL_GAP)) / minCellW))
        -- Expand thumb width to fill the available space
        local thumbW = math.floor((gridW - (cols - 1) * T.px(FLYER_COL_GAP)) / cols)
        local thumbH = math.floor(thumbW * 1.5)  -- 2:3 ratio
        local cellW = thumbW + T.px(FLYER_COL_GAP)
        local cellH = thumbH + secH + T.px(4) + T.px(FLYER_ROW_GAP)
        local rows = math.ceil(#catalog / cols)
        local totalH = headerH + rows * cellH
        return cols, rows, thumbW, thumbH, cellW, cellH, totalH
    end

    -- First pass: assume no scrollbar
    local cols, rows, FLYER_THUMB_W, FLYER_THUMB_H, cellW, cellH, totalContentH = computeGrid(w)

    local needsScroll = totalContentH > h
    local drawW = w
    if needsScroll then
        drawW = w - scrollW - T.px(2)
        cols, rows, FLYER_THUMB_W, FLYER_THUMB_H, cellW, cellH, totalContentH = computeGrid(drawW)

        scroll.x = x + w - scrollW
        scroll.y = y
        scroll.height = h
        scroll:setBarSize(h / totalContentH)
    else
        scroll:setScrollPos(0)
    end
    scroll.visible = needsScroll

    -- S105 gamepad: scroll-follow with delta gate (Q99). Uses last frame's
    -- cached thumbnail zones; one-frame lag is imperceptible. Only pins
    -- when focused id changed — input-mode oscillation doesn't re-pin.
    if needsScroll and gpFocusedId and gpFocusedId ~= win._lastPinnedJournalId then
        local ty, th = nil, nil
        if gpFocusedId == "flyer:__mode" and lastFlyerModeZone then
            ty, th = lastFlyerModeZone.y, lastFlyerModeZone.h
        elseif lastFlyerClickZones then
            for _, z in ipairs(lastFlyerClickZones) do
                if ("flyer:thumb:" .. tostring(z.idx)) == gpFocusedId then
                    ty, th = z.y, z.h
                    break
                end
            end
        end
        if ty and th then
            local prevScrollOff = math.floor(scroll.scrollPos * (totalContentH - h))
            local contentTy = ty + prevScrollOff
            local margin = T.px(8)
            local screenTop = ty
            local screenBot = ty + th
            local newOff = prevScrollOff
            if screenTop < y + margin then
                newOff = math.max(0, contentTy - y - margin)
            elseif screenBot > y + h - margin then
                newOff = math.min(totalContentH - h, contentTy + th - (y + h) + margin)
            end
            if newOff ~= prevScrollOff and totalContentH > h then
                scroll:setScrollPos(newOff / (totalContentH - h))
            end
        end
        win._lastPinnedJournalId = gpFocusedId
    end

    local stencilW = needsScroll and (w - scrollW) or w
    panel:setStencilRect(x, y, stencilW, h)

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * (totalContentH - h))
    end

    local tabPad = ZeD.Molecules.getTabPad()  -- 6px template padding
    local curY = y - scrollOff + T.sp.sm

    -- Progress counter (left) + cycle button (right) on same row
    local fullCatalog = buildFlyerCatalog()
    local totalFlyers = #fullCatalog
    local progNumStr = tostring(collectedCt)
    local progRestStr = " / " .. tostring(totalFlyers) .. " Read"
    local dc = T.textDim  -- used below for thumbnail placeholder "?"
    local progF3H = tm:getFontHeight(T.fontF3)
    local pillRowH = progF3H + T.px(8)
    local progTextY = curY + math.floor((pillRowH - progF3H) / 2)
    local nc = T.toneNorm
    panel:drawText(progNumStr, x + tabPad, progTextY, nc.r, nc.g, nc.b, nc.a or 1, T.fontF3)
    local progNumW = tm:MeasureStringX(T.fontF3, progNumStr)
    panel:drawText(progRestStr, x + tabPad + progNumW, progTextY, nc.r, nc.g, nc.b, nc.a or 1, T.fontF3)

    -- Cycle button (right-aligned pill showing current mode)
    local curMode = FLYER_MODES[modeIdx] or FLYER_MODES[1]
    local modePillW = tm:MeasureStringX(T.fontF1, curMode.label) + T.sp.sm * 2
    local modePillX = x + drawW - tabPad - modePillW
    A.drawPillButton(panel, modePillX, curY, modePillW, pillRowH, curMode.label, true, false, T.fontF1)
    -- S105 gamepad: focus cue overlay on the mode pill. Pill renders first,
    -- cue sits on top; label text rendered inside drawPillButton reads
    -- through at 0.55α.
    if gpFocusedId == "flyer:__mode" then
        local ac = T.accent
        panel:drawRect(modePillX, curY, modePillW, pillRowH, 0.55, ac.r, ac.g, ac.b)
    end
    win._flyerModeZone = { x = modePillX, y = curY, w = modePillW, h = pillRowH }
    curY = curY + pillRowH + T.sp.xs

    local zones = {}

    if #catalog == 0 then
        A.drawSecondary(panel, "No flyers in database", x + tabPad, curY, T.textDim)
    else
        -- Left-align grid with template padding — no centering
        local startX = x + tabPad
        local gridOffX = 0

        for i, flyer in ipairs(catalog) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)

            local fx = startX + gridOffX + col * cellW
            local fy = curY + row * cellH

            local isRead = collected[flyer.key] or false
            local thumbAlpha = isRead and 1.0 or 0.5

            -- Thumbnail
            if flyer.texture then
                panel:drawTextureScaledAspect(flyer.texture, fx, fy,
                    FLYER_THUMB_W, FLYER_THUMB_H, thumbAlpha, 1, 1, 1)
            else
                local bg = T.surf2
                panel:drawRect(fx, fy, FLYER_THUMB_W, FLYER_THUMB_H,
                    bg.a * 0.5, bg.r, bg.g, bg.b)
                local qm = "?"
                local qmW = tm:MeasureStringX(T.fontF2, qm)
                local qmX = fx + math.floor((FLYER_THUMB_W - qmW) / 2)
                local qmY = fy + math.floor((FLYER_THUMB_H - tm:getFontHeight(T.fontF2)) / 2)
                panel:drawText(qm, qmX, qmY, dc.r, dc.g, dc.b, 0.3 * thumbAlpha, T.fontF2)
            end

            -- Unread: surf2 wash overlay
            if not isRead then
                local s2 = T.surf2
                panel:drawRect(fx, fy, FLYER_THUMB_W, FLYER_THUMB_H,
                    s2.a * 0.4, s2.r, s2.g, s2.b)
            end

            -- Border
            local bd = T.border
            panel:drawRectBorder(fx, fy, FLYER_THUMB_W, FLYER_THUMB_H,
                bd.a * 0.3, bd.r, bd.g, bd.b)

            -- S105 gamepad: focus cue overlay on focused thumbnail. Border is
            -- preserved (already drawn); accent overlay signals focus.
            if gpFocusedId == ("flyer:thumb:" .. tostring(i)) then
                local ac = T.accent
                panel:drawRect(fx, fy, FLYER_THUMB_W, FLYER_THUMB_H, 0.55, ac.r, ac.g, ac.b)
            end

            -- Status dot (top-right corner) — matches book status dot pattern
            local dotSz = T.px(6)
            local dotX = fx + FLYER_THUMB_W - dotSz - T.px(2)
            local dotY = fy + T.px(2)
            if isRead then
                A.drawStatusDot(panel, dotX, dotY, T.positive, dotSz)
            else
                A.drawStatusDot(panel, dotX, dotY, T.textDim, dotSz)
            end

            -- Name below thumbnail (truncated)
            local nameStr = truncText(flyer.displayName, T.fontF2, FLYER_THUMB_W)
            local nameY = fy + FLYER_THUMB_H + T.px(2)
            local nc = T.toneNorm
            panel:drawText(nameStr, fx, nameY, nc.r, nc.g, nc.b, isRead and (nc.a or 1) or 0.4, T.fontF2)

            -- Click zone
            zones[#zones + 1] = { idx = i, x = fx, y = fy, w = FLYER_THUMB_W, h = FLYER_THUMB_H }
        end
    end

    win._flyerClickZones = zones

    panel:clearStencilRect()

    if needsScroll then
        scroll:draw(panel)
    end
end

-- ============================================================================
-- MAIN RENDERER — sub-tab dispatch
-- ============================================================================

function ZeD.JournalTab.render(panel, win, x, y, w, h)
    local T = ZeD.T
    -- Initialize sub-tab state if needed
    if not win._journalSubTab then
        win._journalSubTab = 1
    end

    -- Top padding: intentional 13px override (aligns sub-tab strip bottom with inventory column header)
    -- TAB_TOP_PAD = 13 kept — M.getTabPadTop() = 8 is too small for this alignment
    y = y + T.px(TAB_TOP_PAD)
    h = h - T.px(TAB_TOP_PAD)

    -- Draw sub-tab strip at top
    local tabStripH = drawSubTabStrip(panel, win, x, y, w)

    -- Content area below the strip
    local contentY = y + tabStripH
    local contentH = h - tabStripH

    -- Route to active sub-tab renderer
    local activeIdx = win._journalSubTab
    if activeIdx == 1 then
        renderJournal(panel, win, x, contentY, w, contentH)
    elseif activeIdx == 2 then
        renderRecipes(panel, win, x, contentY, w, contentH)
    -- elseif activeIdx == X then  -- S67: Maps moved to World Window MapsTab
    --     renderMaps(panel, win, x, contentY, w, contentH)
    elseif activeIdx == 3 then
        renderFlyers(panel, win, x, contentY, w, contentH)
    end
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.JournalTab.register(dispatchTable)
    dispatchTable["journal"] = ZeD.JournalTab.render
end
