-- ZeD-UI/42/media/lua/client/ZeD/JournalTab.lua
-- ============================================================================
-- JOURNAL TAB — 4 sub-tabs inside the drawer.
--   [Journal | Notebooks | Papers | Recipes]
--   Journal:   survival logbook + BBS-style diary (full width); Save can also
--              write the entry into a carried notebook (Into)
--   Notebooks: carried notebooks, the page small, a quick note (ZeD_JournalReaders)
--   Papers:    carried newspapers, flyers, brochures; quick look (ZeD_JournalReaders)
--   Recipes:   all learnable recipes grouped by skill, status dots, expandable
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/CraftingCore"
require "ZeD/ZeD_JournalReaders"

ZeD = ZeD or {}
ZeD.JournalTab = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- Month names are translation keys, translated where they are drawn: the short ones are
-- ZeD's, the full ones the game's own (the sandbox start-month names).
local MONTHS = {
    "UI_ZeD_Journal_MonthJan", "UI_ZeD_Journal_MonthFeb", "UI_ZeD_Journal_MonthMar", "UI_ZeD_Journal_MonthApr",
    "UI_ZeD_Journal_MonthMay", "UI_ZeD_Journal_MonthJun", "UI_ZeD_Journal_MonthJul", "UI_ZeD_Journal_MonthAug",
    "UI_ZeD_Journal_MonthSep", "UI_ZeD_Journal_MonthOct", "UI_ZeD_Journal_MonthNov", "UI_ZeD_Journal_MonthDec",
}
local MONTHS_FULL = {
    "Sandbox_StartMonth_option1", "Sandbox_StartMonth_option2", "Sandbox_StartMonth_option3", "Sandbox_StartMonth_option4",
    "Sandbox_StartMonth_option5", "Sandbox_StartMonth_option6", "Sandbox_StartMonth_option7", "Sandbox_StartMonth_option8",
    "Sandbox_StartMonth_option9", "Sandbox_StartMonth_option10", "Sandbox_StartMonth_option11", "Sandbox_StartMonth_option12",
}

-- (tr: the translation key of the label; the game's own weapon skill names where it has them)
local WEAPON_CAT_ORDER = {
    { key = "Blunt",      tr = "IGUI_perks_Blunt" },
    { key = "SmallBlunt", tr = "IGUI_perks_SmallBlunt" },
    { key = "LongBlade",  tr = "IGUI_perks_LongBlade" },
    { key = "SmallBlade", tr = "IGUI_perks_SmallBlade" },
    { key = "Axe",        tr = "IGUI_perks_Axe" },
    { key = "Spear",      tr = "IGUI_perks_Spear" },
    { key = "Firearm",    tr = "IGUI_perks_Firearm" },
    { key = "Unarmed",    tr = "UI_ZeD_Journal_WeaponUnarmed" },
    { key = "Other",      tr = "UI_ZeD_Journal_WeaponOther" },
}

local ENTRY_INPUT_H = 48  -- 3-line text entry height
local TAB_TOP_PAD   = 13  -- aligns tab strip bottom with inventory column header

local wrapText = ZeD.Atoms.wrapText

-- Recipe icon grid constants (matches CraftingTab)
local RCELL_SZ   = 43
local RCELL_GAP  = 3

local truncText = ZeD.Atoms.truncateText

-- Sub-tab definitions
-- (Oct 16 2026, mockup zed_reader_v2: Flyers became Papers, Notebooks added; the
-- Character window reads these by index: 1 Journal, 2 Notebooks, 3 Papers, 4 Recipes)
local SUB_TABS = {
    { id = "journal",   key = "UI_ZeD_Journal_TabJournal" },
    { id = "notebooks", key = "UI_ZeD_Journal_TabNotebooks" },
    { id = "papers",    key = "UI_ZeD_Journal_TabPapers" },
    { id = "recipes",   key = "IGUI_LiteratureUI_Recipes" },   -- (the game's own "Recipes")
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
    -- one pass over the original array, so a filtered list finds each
    -- entry's stable index without rescanning it per entry
    local origIndex = nil
    if originalArray and originalArray ~= entries then
        origIndex = {}
        for oi, oe in ipairs(originalArray) do
            if origIndex[oe] == nil then origIndex[oe] = oi end
        end
    end
    for i, entry in ipairs(entries) do
        local m = entry.month or 0
        local yr = entry.year or 0
        local key = m .. "_" .. yr
        if not byKey[key] then
            byKey[key] = {
                key     = key,
                month   = m,
                year    = yr,
                label   = ZeD.tr("UI_ZeD_Journal_GroupLabel", MONTHS_FULL[m + 1] and ZeD.tr(MONTHS_FULL[m + 1]) or "???", yr),
                entries = {},
            }
            keyOrder[#keyOrder + 1] = key
        end
        -- Find stable index in original array (for delete even when filtered)
        local origIdx = (origIndex and origIndex[entry]) or i
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

-- Wrapped lines for one entry's text, remembered per width and font. Wrapping
-- measures every word, so doing it for every entry twice a frame was the
-- journal's main cost. The memory is dropped when the font or text scale
-- changes, and when it has grown past a few thousand entries (window resizes
-- leave old widths behind).
local _wrapFontKey = nil
local _wrapByWidth = {}
local _wrapCount = 0
local function wrappedLines(entry, font, width)
    local fk = tostring(font) .. "|" .. tostring(ZeD.T.scale)
    if fk ~= _wrapFontKey or _wrapCount > 4000 then
        _wrapFontKey, _wrapByWidth, _wrapCount = fk, {}, 0
    end
    local byEntry = _wrapByWidth[width]
    if not byEntry then
        byEntry = {}
        _wrapByWidth[width] = byEntry
    end
    local text = entry.text
    local hit = byEntry[entry]
    if hit and hit.text == text then return hit.lines end
    local lines = wrapText(text, font, width)
    byEntry[entry] = { text = text, lines = lines }
    _wrapCount = _wrapCount + 1
    return lines
end

-- The month groups for the entries the search leaves, rebuilt only when the
-- entry list or the search text changes (the first and last entries and the
-- count catch an add or a delete, as the list is the player's live data).
local function journalGroups(win, entries, searchQ)
    local n = #entries
    local c = win._journalGroupCache
    local lang = ZeD.trTestOn() and 1 or 0   -- (the group names are translated; the test language changes them)
    if c and c.src == entries and c.n == n and c.first == entries[1]
            and c.last == entries[n] and c.q == searchQ and c.lang == lang then
        return c.groups
    end
    local filtered = entries
    if searchQ ~= "" then
        local q = string.lower(searchQ)
        filtered = {}
        for _, entry in ipairs(entries) do
            if string.lower(entry.text or ""):find(q, 1, true) then
                filtered[#filtered + 1] = entry
            end
        end
    end
    local groups = groupEntriesByMonth(filtered, entries)
    win._journalGroupCache = { src = entries, n = n, first = entries[1], last = entries[n], q = searchQ, lang = lang, groups = groups }
    return groups
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
                weaponCats[#weaponCats + 1] = { label = ZeD.tr(def.tr), count = zk.weapon[def.key] or 0 }
            end
        else
            for _, def in ipairs(WEAPON_CAT_ORDER) do
                weaponCats[#weaponCats + 1] = { label = ZeD.tr(def.tr), count = 0 }
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

-- groups: the month groups the draw pass will show (search applied); the
-- scrollbar is sized from the same list.
function ZeD.JournalTab._measureJournalContent(data, contentW, collapsedMap, groups)
    local T = ZeD.T
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)
    local secH  = ZeD.TM:getFontHeight(T.fontF1)
    local groupHeaderH = math.max(secH + T.px(10), T.px(26))

    groups = groups or groupEntriesByMonth(data.journalEntries)
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
                    local lines = wrappedLines(entry, T.fontF2, contentW)
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
        local tabLabel = ZeD.tr(tab.key)
        local tw = tm:MeasureStringX(T.fontF1, tabLabel) + padH * 2
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
            panel:drawText(tabLabel, tabX + padH, textY,
                T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a or 1, T.fontF1)
        else
            local textY = y + math.floor((tH - tm:getFontHeight(T.fontF1)) / 2)
            panel:drawText(tabLabel, tabX + padH, textY,
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
    elseif activeIdx == 2 or activeIdx == 3 then
        -- Notebooks and Papers share one search box (cleared on a sub-tab switch)
        if ZeD.JournalReaders.searchVisible(win, activeIdx) and win._flyerSearch then
            searchField = win._flyerSearch
            searchField.placeholder = ZeD.JournalReaders.searchHint(activeIdx)
        end
    end
    if searchField and searchField:isVisible() then
        local searchGap = T.sp.sm
        local searchX = tabX + searchGap
        local searchW = x + w - searchX - T.sp.sm
        local searchH = T.inputH  -- matches crafting tab search height
        if searchW > T.px(60) then
            -- Center in the full 37px header (TAB_TOP_PAD + tH), not just tH
            local fullHeaderH = T.px(TAB_TOP_PAD) + tH
            local headerTopY = y - T.px(TAB_TOP_PAD)
            searchField:setX(searchX)
            searchField:setY(headerTopY + math.floor((fullHeaderH - searchH) / 2))
            searchField:setWidth(searchW)
            searchField:setHeight(searchH)
        else
            -- The tabs leave no room (long words): the search gets its own row under
            -- the strip, full width, and the content below moves down by that row.
            local rowPad = T.sp.sm
            local rowW = w - rowPad * 2
            if rowW < T.px(60) then rowW = T.px(60) end
            searchField:setX(x + rowPad)
            searchField:setY(y + tH + rowPad)
            searchField:setWidth(rowW)
            searchField:setHeight(searchH)
            tH = tH + searchH + rowPad * 2
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
    zoneAEstH = zoneAEstH + T.sp.xs + T.grooveH + T.sp.afterGroove
        + T.px(ENTRY_INPUT_H) + T.sp.xs + T.buttonH + T.sp.sm + T.px(1) + T.sp.afterLine

    local entryGroups = journalGroups(win, data.journalEntries, win._journalSearchText or "")
    local entryContentH = ZeD.JournalTab._measureJournalContent(data, contentW - scrollW - T.px(2), win._journalGroupCollapsed, entryGroups)
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
    local rowH = M.drawStatRow(panel, x + chevronW, curY, drawW - chevronW, getText("IGUI_char_Zombies_Killed"), tostring(data.totalKills), T.toneHi, T.fontF2)
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

        rowH = M.drawStatRowDot(panel, x + indent, curY, innerW, ZeD.tr("UI_ZeD_Journal_KillFire"), tostring(data.fireKills), T.warning)
        curY = curY + rowH + T.sp.rowGap
        rowH = M.drawStatRowDot(panel, x + indent, curY, innerW, ZeD.tr("UI_ZeD_Journal_KillVehicle"), tostring(data.carKills), T.info)
        curY = curY + rowH + T.sp.rowGap
        rowH = M.drawStatRowDot(panel, x + indent, curY, innerW, ZeD.tr("UI_ZeD_Journal_KillExplosion"), tostring(data.explosionKills), T.danger)
        curY = curY + rowH + T.sp.rowGap

        for _, cat in ipairs(data.weaponCats) do
            rowH = M.drawStatRow(panel, x + indent, curY, innerW, cat.label, tostring(cat.count))
            curY = curY + rowH + T.sp.rowGap
        end
    end

    curY = curY + T.sp.xs
    A.drawGroove(panel, x, curY, drawW)
    curY = curY + T.grooveH + T.sp.afterGroove

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
        -- Into: the log only, or a carried notebook the character writes it in too
        ZeD.JournalReaders.drawLogInto(panel, win, x, curY, drawW - btnW - T.sp.sm, T.buttonH)
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
    -- (the grouped list is cached; it is rebuilt only when the entries or
    -- the search text change)
    local groups = journalGroups(win, data.journalEntries, win._journalSearchText or "")

    -- Journal entries — grouped by month, newest first
    local groupHeaderH = math.max(secH + T.px(10), T.px(26))
    local groupZones = {}
    local deleteZones = {}
    local chevSzG = math.max(T.px(6), math.floor(secH * 0.6))
    local deleteBtnW = secH + T.px(8)  -- hit area for X button

    if #groups == 0 then
        A.drawSecondary(panel, ZeD.tr("UI_ZeD_Journal_NoEntries"), x, curY, T.textDim)
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
                    -- The stamp is built once per entry and language state (the loop draws every
                    -- entry each frame, and a translated phrase costs more than a concatenation).
                    local stampKey = ZeD.trTestOn() and "t" or "n"
                    local dateStr = wrapped.stamp
                    if dateStr == nil or wrapped.stampKey ~= stampKey then
                        local monthStr = MONTHS[(entry.month or 0) + 1] and ZeD.tr(MONTHS[(entry.month or 0) + 1]) or "???"
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

                        dateStr = ZeD.tr("UI_ZeD_Journal_EntryStamp", survDay, monthStr, dayStr, yearStr)
                            .. " - " .. hourStr
                        -- written into a notebook too: which, and the page
                        if entry.source and entry.source.name then
                            dateStr = dateStr .. " | " .. ZeD.tr("UI_ZeD_Journal_EntrySource", tostring(entry.source.name), tostring(entry.source.page))
                        end
                        wrapped.stamp, wrapped.stampKey = dateStr, stampKey
                    end

                    dateStr = truncText(dateStr, T.fontF3, drawW - deleteBtnW - T.px(4))
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

                    local lines = wrappedLines(entry, T.fontF2, drawW)
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

    -- the Papers / Notebooks / Into hit zones start empty each frame
    ZeD.JournalReaders.beginFrame(win)

    -- Draw sub-tab strip at top
    local tabStripH = drawSubTabStrip(panel, win, x, y, w)

    -- Content area below the strip
    local contentY = y + tabStripH
    local contentH = h - tabStripH

    -- Route to active sub-tab renderer (1 Journal, 2 Notebooks, 3 Papers, 4 Recipes)
    local activeIdx = win._journalSubTab
    if activeIdx == 1 then
        renderJournal(panel, win, x, contentY, w, contentH)
    elseif activeIdx == 2 then
        ZeD.JournalReaders.renderNotebooks(panel, win, x, contentY, w, contentH)
    elseif activeIdx == 3 then
        ZeD.JournalReaders.renderPapers(panel, win, x, contentY, w, contentH)
    elseif activeIdx == 4 then
        renderRecipes(panel, win, x, contentY, w, contentH)
    end
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.JournalTab.register(dispatchTable)
    dispatchTable["journal"] = ZeD.JournalTab.render
end
