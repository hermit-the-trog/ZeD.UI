-- ZeD-UI/42/media/lua/client/ZeD/JournalTab.lua
-- ============================================================================
-- JOURNAL TAB — five pages inside the drawer, picked from the header's Page
-- pop-up ("Page: Journal"; the search at its right). Each page's own controls
-- sit in a band at its foot (Oct 30 2026, punch list 21); Notebooks has none.
--   Journal:   survival logbook + BBS-style diary (full width); Save (the band)
--              can also write the entry into a carried notebook (Into)
--   Notebooks: carried notebooks, the page small, a quick note (ZeD_JournalReaders)
--   Papers:    carried newspapers, flyers, brochures; quick look (ZeD_JournalReaders)
--   Recipes:   all learnable recipes grouped by skill, status dots, expandable
--   Loadouts:  the saved loadouts and outfits and their lines (ZeD_JournalLists)
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/CraftingCore"
require "ZeD/ZeD_JournalReaders"
require "ZeD/ZeD_JournalLists"

ZeD = ZeD or {}
ZeD.JournalTab = {}

-- The controller's mark options for the element with this id: set only when the
-- window is the focused one, the controller is in use and that element has the focus.
local _focusOpts = {}
local function focusOf(win, id)
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.isFocused and F.isFocused(win, nil, id) then
        _focusOpts.win = win
        return _focusOpts
    end
    return nil
end

-- the footer help line's words for what the pointer is over
local function help(win, text)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, text) end
end

-- the pointer over (x, y, w, h) with the mouse in use, and inside the view (vy0 .. vy1)
local function hoverIn(panel, x, y, w, h, vy0, vy1)
    local my = panel:getMouseY()
    if vy0 and (my < vy0 or my >= vy1) then return false end
    return ZeD.Atoms.mouseIn(panel, x, y, w, h)
end

-- the cross of the delete icon button
local function drawCross(p, x, y, s, c)
    local u = ZeD.T.hair
    local n = math.floor(s / u)
    for i = 0, n - 1 do
        -- both diagonals, two pixels wide (kept inside the n x n square)
        p:drawRect(x + i * u, y + i * u, (i < n - 1) and u * 2 or u, u, c.a or 1, c.r, c.g, c.b)
        local j = n - 1 - i
        p:drawRect(x + j * u - ((j > 0) and u or 0), y + i * u, (j > 0) and u * 2 or u, u, c.a or 1, c.r, c.g, c.b)
    end
end

-- an entry's head row: its date and the delete button
local function entryHeadH()
    local T = ZeD.T
    return math.max(ZeD.TM:getFontHeight(T.fontF1), T.buttonH - T.px(4))
end

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
local _saveBandSpec = {}  -- the Journal page's band (its Save is the window's button, placed over it)

local wrapText = ZeD.Atoms.wrapText

-- Recipe icon grid constants (matches CraftingTab)
local RCELL_SZ   = 43
local RCELL_GAP  = 3

local truncText = ZeD.Atoms.truncateText

-- The pages (sub-tabs until Oct 30 2026; now the header's Page pop-up)
-- (Oct 16 2026, mockup zed_reader_v2: Flyers became Papers, Notebooks added; the
-- Character window reads these by index (win._journalSubTab): 1 Journal, 2 Notebooks, 3 Papers, 4 Recipes)
local SUB_TABS = {
    { id = "journal",   key = "UI_ZeD_Journal_TabJournal" },
    { id = "notebooks", key = "UI_ZeD_Journal_TabNotebooks" },
    { id = "papers",    key = "UI_ZeD_Journal_TabPapers" },
    { id = "recipes",   key = "IGUI_LiteratureUI_Recipes" },   -- (the game's own "Recipes")
    -- Oct 29 2026 (loadouts B2): on the end, so 1 to 4 keep their numbers
    { id = "loadouts",  key = "UI_ZeD_Journal_TabLoadouts" },
}
-- Loadouts is in the Page list only while Loadouts and outfits is on (Settings.lua; director, Oct 30 2026)
local function subTabShown(tab)
    return tab.id ~= "loadouts" or (ZeD.Lists ~= nil and ZeD.Lists.on())
end

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
    local groupHeaderH = T.px(15)   -- the category row (its line is inside it)

    groups = groups or groupEntriesByMonth(data.journalEntries)
    local totalH = 0

    if #groups == 0 then
        totalH = totalH + secH + T.sp.sm
    else
        for _, group in ipairs(groups) do
            totalH = totalH + groupHeaderH
            if not (collapsedMap and collapsedMap[group.key]) then
                for _, wrapped in ipairs(group.entries) do
                    local entry = wrapped.entry
                    totalH = totalH + entryHeadH() + T.sp.rowGap
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
-- RENDERER — JOURNAL SUB-TAB (full-width diary)
-- ============================================================================

local function renderJournal(panel, win, x, y, w, h)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules

    -- Search field positioned by the Journal's header (drawHeader, right of the Page pop-up).
    -- The page's band at its foot (Save; the delete question takes its place, Oct 30 2026):
    -- the log scrolls above it.
    local bandH = M.bandH()
    h = h - bandH

    -- S105 gamepad: resolve the currently-focused element id for cue paints
    -- (all element types on this sub-tab share charTabContent; live element
    -- check is the authoritative paint gate — S101 pattern).
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    -- (for the scroll-follow below; the marks are asked of the library per element: focusOf)
    local gpFocusedId = nil
    if Focus and Focus.liveZone and Focus.liveElement then
        local fz = Focus.liveZone(win)
        if fz and fz.zone == "charTabContent" then
            local fe = Focus.liveElement(win)
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
    local zoneAEstH = T.sp.sm + T.px(20) + T.sp.rowGap   -- the kills section head is 20u
    if win._killsExpanded then
        -- 3 fixed rows (fire, vehicle, explosion) + all weapon categories
        local killRows = 3 + #data.weaponCats
        zoneAEstH = zoneAEstH + killRows * (statRowEstH + T.sp.rowGap)
    end
    -- the write box, then Into (a carried notebook) on its own row when there is one
    local intoShown = ZeD.JournalReaders.intoShown(win)
    zoneAEstH = zoneAEstH + T.sp.xs + T.px(1) + T.sp.afterGroove
        + T.px(ENTRY_INPUT_H) + T.sp.xs + (intoShown and (T.buttonH + T.sp.sm) or 0) + T.px(1) + T.sp.afterLine

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
        -- (Save is in the band, which does not scroll)
        if gpFocusedId == "journal:__kills" and win._journalKillsZone then
            ty, th = win._journalKillsZone.y, win._journalKillsZone.h
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

    -- Kills: a section head that folds (the total is its count); the controller's mark and
    -- the hover wash come with the molecule
    win._killsRowY = curY
    local killsHover = hoverIn(panel, x, curY, drawW, T.px(20), y, y + h)
    if killsHover then
        help(win, ZeD.tr(win._killsExpanded and "UI_ZeD_Journal_HelpKillsHide" or "UI_ZeD_Journal_HelpKillsShow"))
    end
    local rowH = M.drawSectionHeader(panel, x, curY, drawW, getText("IGUI_char_Zombies_Killed"), data.totalKills,
        win._killsExpanded, killsHover, nil, nil, nil, nil, nil, { focus = focusOf(win, "journal:__kills") })
    win._killsRowH = rowH
    -- the kills head's hit zone for the focusable builder (the real height the molecule drew)
    win._journalKillsZone = { x = x, y = curY, w = drawW, h = rowH }
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
    A.drawDividerH(panel, x, curY, drawW)
    curY = curY + T.px(1) + T.sp.afterGroove

    -- Text entry (positioned on the drawer panel — a drawer child); Save is in the band
    local entryBox = win._journalInput
    if entryBox then
        entryBox:setX(x)
        entryBox:setY(curY)
        entryBox:setWidth(drawW)
        entryBox:setHeight(T.px(ENTRY_INPUT_H))
        curY = curY + T.px(ENTRY_INPUT_H) + T.sp.xs
    end
    if intoShown then
        -- Into: the log only, or a carried notebook the character writes it in too (it stays
        -- with the write box)
        ZeD.JournalReaders.drawLogInto(panel, win, x, curY, drawW, T.buttonH)
        curY = curY + T.buttonH + T.sp.sm
    end

    A.drawDividerH(panel, x, curY, drawW, true)
    curY = curY + T.px(1) + T.sp.afterLine

    -- Filter entries by search text (if any), then group by month
    -- (the grouped list is cached; it is rebuilt only when the entries or
    -- the search text change)
    local groups = journalGroups(win, data.journalEntries, win._journalSearchText or "")

    -- Journal entries — grouped by month, newest first
    local groupZones = {}
    local deleteZones = {}
    local delSz = T.buttonH - T.px(4)   -- the delete icon button: a list row's button size
    local headH = entryHeadH()

    if #groups == 0 then
        curY = curY + M.drawEmptyLine(panel, x, curY, drawW, ZeD.tr("UI_ZeD_Journal_NoEntries"))
    else
        for _, group in ipairs(groups) do
            local collapsed = win._journalGroupCollapsed[group.key]

            -- Group header: a category row ("v January, Year 0 (3)")
            local headerY = curY
            local gh = T.px(15)
            local gHover = hoverIn(panel, x, headerY, drawW, gh, y, y + h)
            if gHover then help(win, ZeD.tr(collapsed and "UI_ZeD_Journal_HelpGroupShow" or "UI_ZeD_Journal_HelpGroupHide", group.label)) end
            curY = curY + M.drawCategoryRow(panel, x, curY, drawW, group.label, group.count, not collapsed,
                { hover = gHover, focus = focusOf(win, "journal:group:" .. tostring(group.key)), inset = T.px(2) })
            groupZones[#groupZones + 1] = { id = group.key, x = x, y = headerY, w = drawW, h = gh }

            -- Entries (if not collapsed)
            if not collapsed then
                local entryIdx = 0
                for _, wrapped in ipairs(group.entries) do
                    -- Alternating entry stripe
                    if entryIdx % 2 == 1 then
                        local st = T.stripe
                        panel:drawRect(x, curY, drawW, bodyH + headH + T.sp.xs, st.a, st.r, st.g, st.b)
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

                    dateStr = truncText(dateStr, T.fontF3, drawW - delSz - T.px(8))
                    panel:drawText(dateStr, x, curY + math.floor((headH - ZeD.TM:getFontHeight(T.fontF3)) / 2),
                        T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a or 1, T.fontF3)

                    -- Delete: an icon button that asks first (the question band at the foot)
                    local delX = x + drawW - delSz
                    local delY = curY + math.floor((headH - delSz) / 2)
                    local dHover = hoverIn(panel, delX, delY, delSz, delSz, y, y + h)
                    M.drawIconButton(panel, delX, delY, delSz, drawCross, {
                        hover = dHover, focus = focusOf(win, "journal:del:" .. tostring(wrapped.idx)), win = win,
                        hint = ZeD.tr("UI_ZeD_Journal_Delete"), id = "jdel:" .. tostring(wrapped.idx),
                        help = ZeD.tr("UI_ZeD_Journal_HelpDelete"), iconSize = T.px(8),
                    })
                    deleteZones[#deleteZones + 1] = {
                        entryIdx = wrapped.idx,
                        x = delX, y = delY, w = delSz, h = delSz,
                    }

                    curY = curY + headH + T.sp.rowGap

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

    -- The band at the page's foot, under the log: Save at the right (the window's button, a
    -- drawer child, placed here). The question before a delete takes its place (Cancel and
    -- Delete) and Save hides while it asks.
    local ask = win._journalAsk
    local by = y + h
    local saveBtn = win._journalSaveBtn
    win._journalAskRects = nil
    win._journalSaveBtnZone = nil
    local br = win._journalBandRect or {}
    win._journalBandRect = br
    br.x, br.y, br.w, br.h = outerX, by, outerW, bandH
    if ask then
        if saveBtn then saveBtn:setVisible(false) end
        local _, cancel, verb = M.drawQuestionBand(panel, outerX, by, outerW, ZeD.tr("UI_ZeD_Journal_AskDelete"),
            ZeD.tr("UI_ZeD_Journal_Delete"), { danger = true, win = win,
                cancelFocus = focusOf(win, "journal:ask:cancel"), verbFocus = focusOf(win, "journal:ask:verb") })
        win._journalAskRects = { cancel = cancel, verb = verb, band = { x = outerX, y = by, w = outerW, h = bandH } }
    else
        _saveBandSpec.win = win
        M.drawBand(panel, outerX, by, outerW, _saveBandSpec)
        if saveBtn then
            local btnW, btnH = saveBtn:getWidth(), T.buttonH
            local btnX, btnY = outerX + outerW - T.px(8) - btnW, by + T.px(5)
            if saveBtn:getX() ~= btnX or saveBtn:getY() ~= btnY then saveBtn:setX(btnX); saveBtn:setY(btnY) end
            -- S105 gamepad: stamp the save button's hit zone and mark it BEHIND the button's
            -- own render (the button is a drawer child, drawn after this panel, and
            -- transparent, so the mark shows through).
            win._journalSaveBtnZone = { x = btnX, y = btnY, w = btnW, h = btnH }
            local saveFocus = focusOf(win, "journal:__save")
            if saveFocus then ZeD.Focus.mark(panel, btnX, btnY, btnW, btnH, saveFocus) end
        end
    end
end

-- ============================================================================
-- DELETING AN ENTRY — asked first, as a band at the foot of the log
-- ============================================================================

-- the entries array on the player (nil when the character has none)
local function journalEntries(win)
    local md = win and win._playerObj and win._playerObj:getModData()
    return md and md.ZeD_Journal and md.ZeD_Journal.entries or nil
end

--- Ask whether to delete a log entry: shows the question band ("Delete the entry? It
-- can't be brought back." with Cancel and Delete) and deletes only on Delete.
-- @param win    the Character window
-- @param entry  the entry table (an element of the player's ZeD_Journal.entries); a number
--               (an index into them) or a delete zone carrying entryIdx also works
-- @param index  optional: the entry's index in the player's entries, when entry is nil
function ZeD.JournalTab.askDelete(win, entry, index)
    local entries = journalEntries(win)
    if not entries then return end
    local tbl = entry
    if tbl == nil then tbl = index end
    if type(tbl) == "number" then tbl = entries[tbl]
    elseif type(tbl) == "table" and tbl.entryIdx then tbl = entries[tbl.entryIdx] end
    if type(tbl) ~= "table" then return end
    win._journalAsk = { entry = tbl }
end

--- Delete the entry the question is about (the Delete answer); does nothing without one.
function ZeD.JournalTab.confirmDelete(win)
    local ask = win and win._journalAsk
    win._journalAsk, win._journalAskRects = nil, nil
    local entries = journalEntries(win)
    if not (ask and entries) then return end
    for i, e in ipairs(entries) do
        if e == ask.entry then
            table.remove(entries, i)
            break
        end
    end
    win._journalCache = nil
    win._journalGroupCache = nil
end

--- Drop the question (the Cancel answer).
function ZeD.JournalTab.cancelDelete(win)
    if win then win._journalAsk, win._journalAskRects = nil, nil end
end

--- A click on the question band's buttons (the Character window's click path reaches it
-- through ZeD.JournalReaders.onClick); true when it took the click.
function ZeD.JournalTab.onAskClick(win, x, y)
    local r = win and win._journalAsk and win._journalAskRects
    if not r then return false end
    local function inside(b) return b and x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h end
    if inside(r.verb) then ZeD.JournalTab.confirmDelete(win); return true end
    if inside(r.cancel) then ZeD.JournalTab.cancelDelete(win); return true end
    return inside(r.band)   -- (the band takes the click: nothing under it)
end

--- The controller's stops while a question is up: Cancel (first, where the focus lands)
-- and Delete. The window's builder returns these alone while win._journalAsk is set.
function ZeD.JournalTab.askFocusables(win)
    local r = win and win._journalAsk and win._journalAskRects
    if not r then return {} end
    local out = {}
    if r.cancel then
        out[#out + 1] = { x = r.cancel.x, y = r.cancel.y, w = r.cancel.w, h = r.cancel.h, id = "journal:ask:cancel",
            onFocus = function() end,
            onActivate = function(w) ZeD.JournalTab.cancelDelete(w) end,
            onCancel = function(w) ZeD.JournalTab.cancelDelete(w) end }
    end
    if r.verb then
        out[#out + 1] = { x = r.verb.x, y = r.verb.y, w = r.verb.w, h = r.verb.h, id = "journal:ask:verb",
            onFocus = function() end,
            onActivate = function(w) ZeD.JournalTab.confirmDelete(w) end,
            onCancel = function(w) ZeD.JournalTab.cancelDelete(w) end }
    end
    return out
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
-- THE HEADER STRIP (Oct 30 2026, punch list 21: one row, the standard height):
-- the page as a System 7 pop-up menu at the left ("Page: Journal"), the page's
-- search at the right. The pages were sub-tabs in a strip; the Page list opens
-- under the box, drawn last over the page.
-- ============================================================================

local PAGE_MODES = {}   -- the Page list's choices {id = page index, label}: reused, labels refreshed
local _pageMenuOpts = {}

-- the pages the list offers (Loadouts only while Loadouts and outfits is on)
local function pageModes()
    local n = 0
    for i, tab in ipairs(SUB_TABS) do
        if subTabShown(tab) then
            n = n + 1
            local m = PAGE_MODES[n] or {}
            PAGE_MODES[n] = m
            m.id, m.label = i, ZeD.tr(tab.key)
        end
    end
    for i = #PAGE_MODES, n + 1, -1 do PAGE_MODES[i] = nil end
    return PAGE_MODES
end

-- the Page box's width: the longest page name it can carry (the header keeps its shape
-- whichever page is open); kept per scale, font and language
local function pageBoxW(win)
    local T = ZeD.T
    local c = win._journalPageW
    local lang = ZeD.trTestOn() and 1 or 0
    if c and c.scale == T.scale and c.font == T.fontF1 and c.lang == lang then return c.w end
    local w = 0
    for _, tab in ipairs(SUB_TABS) do
        w = math.max(w, ZeD.Molecules.popupMenuW(ZeD.tr("UI_ZeD_Journal_PagePick", ZeD.tr(tab.key))))
    end
    win._journalPageW = { scale = T.scale, font = T.fontF1, lang = lang, w = w }
    return w
end

-- the controller's cues on: the pointer's hover washes stay off
local function cuesOn()
    local F = ZeD.Input and ZeD.Input.Focus
    return F and F.cuesVisible and F.cuesVisible() or false
end

-- A page's own list open (Recipes: Category, Sort, Show; Papers: Show; Loadouts: the
-- filter): its rows alone are the controller's stops.
function ZeD.JournalTab.pageListOpen(win)
    local sub = win and win._journalSubTab or 1
    if sub == 4 then
        -- (as CraftingCore's builder: a list once it has drawn its rows)
        local s = win._jrecipeState
        return s and ((s.catDropdownOpen and s._ddGeo) or (s.sortMenuOpen and s._sortMenuZones)
            or (s.showMenuOpen and s._showMenuZones)) and true or false
    elseif sub == 3 then
        return ZeD.JournalReaders.listOpen(win)
    elseif sub == 5 and ZeD.JournalLists then
        return ZeD.JournalLists.listOpen(win)
    end
    return false
end

-- shut every page's own list (the Page list opening over them)
local function shutPageLists(win)
    local s = win._jrecipeState
    if s then s.catDropdownOpen, s.sortMenuOpen, s.showMenuOpen = false, false, false end
    ZeD.JournalReaders.shutList(win)
    if ZeD.JournalLists then ZeD.JournalLists.shutList(win) end
end

--- Open a page of the Journal (1 Journal, 2 Notebooks, 3 Papers, 4 Recipes, 5 Loadouts):
-- the search fields clear, so a stale filter does not follow to another page.
function ZeD.JournalTab.setPage(win, idx)
    if not (win and SUB_TABS[idx]) or win._journalSubTab == idx then return end
    win._journalSubTab = idx
    if win._journalSearch then win._journalSearch:clear() end
    if win._jrecipeSearch then win._jrecipeSearch:clear() end
    if win._flyerSearch   then win._flyerSearch:clear() end
    win._journalSearchText = ""
    win._flyerSearchText   = ""
    if win._jrecipeState then
        win._jrecipeState.search = ""
        win._jrecipeState.filterDirty = true
    end
end

local function openPageMenu(win)
    shutPageLists(win)
    win._journalPageOpen = true
end

-- shut the Page list; the controller goes back to the box
local function closePageMenu(win)
    win._journalPageOpen = nil
    win._journalPageZones = nil
    win._journalPageReturn = true
end

-- The page's search field at (x, y, w, h); a page whose list has no search right now
-- (a paper's quick look) shows the box greyed.
local function placeSearch(panel, win, page, x, y, w, h)
    local f = nil
    if page == 1 then f = win._journalSearch
    elseif page == 2 or page == 3 then
        if ZeD.JournalReaders.searchVisible(win, page) then
            f = win._flyerSearch
            if f then f.placeholder = ZeD.JournalReaders.searchHint(page) end
        end
    elseif page == 4 then
        ZeD.CraftingCore.placeSearch(win, _jrecipeConfig, getJRecipeState(win), x, y, w, h)
        return
    elseif page == 5 and ZeD.JournalLists then
        ZeD.JournalLists.placeSearch(win, x, y, w, h)
        return
    end
    if f then
        if f:getX() ~= x or f:getY() ~= y then f:setX(x); f:setY(y) end
        if f:getWidth() ~= w or f:getHeight() ~= h then f:setWidth(w); f:setHeight(h) end
        return
    end
    -- greyed: the frame and the page's search words, dim
    local T, A = ZeD.T, ZeD.Atoms
    local da = T.disabledAlpha
    A.frame(panel, x, y, w, h, T.borderS, da)
    local font = T.fontF2
    local tc = T.textDim
    local s = truncText(ZeD.JournalReaders.searchHint(page), font, math.max(0, w - T.sp.inputPadX * 2))
    panel:drawText(s, x + T.sp.inputPadX, y + math.floor((h - ZeD.TM:getFontHeight(font)) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * da, font)
end

-- The header strip; returns its height.
local function drawHeader(panel, win, x, y, w)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local headerH = M.getTabHeaderH()
    local pad, gap = T.px(6), T.px(6)
    local ih = T.inputH
    local rowY = y + math.floor((headerH - ih) / 2)
    local cur = win._journalSubTab or 1
    local open = win._journalPageOpen == true
    -- Page: the pop-up box at the left
    local bw = math.min(pageBoxW(win), math.floor((w - pad * 2 - gap) * 0.5))
    local bx = x + pad
    local hov = (not open) and (not cuesOn()) and A.mouseIn(panel, bx, rowY, bw, ih)
    if hov then help(win, ZeD.tr("UI_ZeD_Journal_HelpPage")) end
    M.drawPopupMenu(panel, bx, rowY, bw, ih, ZeD.tr("UI_ZeD_Journal_PagePick", ZeD.tr(SUB_TABS[cur].key)),
        hov or open, focusOf(win, "jpage"), false)
    local box = win._journalPageBox or {}
    win._journalPageBox = box
    box.x, box.y, box.w, box.h = bx, rowY, bw, ih
    local hr = win._journalHeaderRect or {}
    win._journalHeaderRect = hr
    hr.x, hr.y, hr.w, hr.h = x, y, w, headerH
    -- the page's search at the right
    local sx = bx + bw + gap
    placeSearch(panel, win, cur, sx, rowY, x + w - pad - sx, ih)
    -- Bottom rule on header row
    A.drawDividerH(panel, x, y + headerH - T.px(1), w, true)
    return headerH
end

-- the drawer's children a rect covers (the Page list over the page) hide for the frame:
-- a child panel paints after the drawer, over the list
local function hideUnder(win, rx, ry, rw, rh)
    for _, c in ipairs({ win._journalInput, win._jrNote, win._journalSaveBtn }) do
        if c and c:isVisible() and c:getX() < rx + rw and c:getX() + c:getWidth() > rx
           and c:getY() < ry + rh and c:getY() + c:getHeight() > ry then
            c:setVisible(false)
        end
    end
end

-- The Page list, open: drawn last, under its box. The page the controller is on carries the
-- mark; its row zones take the click and make the controller's stops.
local function drawPageMenu(panel, win)
    local box = win._journalPageBox
    if not (win._journalPageOpen and box) then return end
    local M = ZeD.Molecules
    local modes = pageModes()
    local hoverId = nil
    if not cuesOn() then
        local mx, my = panel:getMouseX(), panel:getMouseY()
        for _, z in ipairs(win._journalPageZones or {}) do
            if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h then hoverId = z.id; break end
        end
    end
    local mo = _pageMenuOpts
    mo.minW, mo.focusId, mo.focus = box.w, nil, nil
    for _, m in ipairs(modes) do
        local f = focusOf(win, "jpage:" .. tostring(m.id))
        if f then mo.focusId, mo.focus = m.id, f; break end
    end
    local lw, lh, zs = M.drawSortMenuList(panel, box.x, box.y + box.h, modes, win._journalSubTab or 1, hoverId, mo)
    win._journalPageZones = zs
    hideUnder(win, box.x, box.y + box.h, lw, lh)
end

local function inside(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

--- A click on the header: the Page box opens its list; the open list takes every click
-- (a page, or shut). The rest of the strip takes its clicks too (nothing under it), and
-- so does the Journal page's band: its question's answers, else nothing (Save is the
-- window's own button; the log's rows scrolled out of view lie under the band).
-- True when it took the click.
function ZeD.JournalTab.onHeaderClick(win, x, y)
    if not win then return false end
    if win._journalPageOpen then
        for _, z in ipairs(win._journalPageZones or {}) do
            if inside(z, x, y) then
                ZeD.JournalTab.setPage(win, z.id)
                break
            end
        end
        closePageMenu(win)
        return true
    end
    -- a page's own list open (it may hang over the header): the page takes the click
    local s = win._jrecipeState
    local sub = win._journalSubTab or 1
    if (sub == 4 and s and (s.catDropdownOpen or s.sortMenuOpen or s.showMenuOpen))
       or (sub ~= 4 and ZeD.JournalTab.pageListOpen(win)) then
        return false
    end
    if inside(win._journalPageBox, x, y) then
        openPageMenu(win)
        return true
    end
    if inside(win._journalHeaderRect, x, y) then return true end
    if (win._journalSubTab or 1) == 1 and inside(win._journalBandRect, x, y) then
        ZeD.JournalTab.onAskClick(win, x, y)
        return true
    end
    return false
end

--- The header's controller stops: the Page box (id "jpage"); while its list is open, the
-- list's rows alone ("jpage:<index>", the open page first; B shuts it). Back from the
-- list, the focus lands on the box (_focusIdx).
function ZeD.JournalTab.headerFocusables(win)
    local out = {}
    if not win then return out end
    -- (the list's rows once it has drawn them; the box until then)
    if win._journalPageOpen and win._journalPageZones then
        for i, z in ipairs(win._journalPageZones) do
            out[#out + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "jpage:" .. tostring(z.id),
                journalKind = "pageRow",
                page = z.id,
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    ZeD.JournalTab.setPage(w, el.page)
                    closePageMenu(w)
                end,
                onCancel = function(w, el) closePageMenu(w) end,
            }
            if z.id == (win._journalSubTab or 1) then out._focusIdx = i end
        end
        -- (Oct 30 2026, punch list 21 a-f: modal; Down from Loadouts, the last row, stays on it)
        out._menuRows = true
        return out
    end
    local b = win._journalPageBox
    if b then
        out[1] = {
            x = b.x, y = b.y, w = b.w, h = b.h,
            id = "jpage",
            journalKind = "page",
            onFocus = function(w, el) end,
            onActivate = function(w, el) openPageMenu(w) end,
        }
        if win._journalPageReturn then
            out._focusIdx = 1
            win._journalPageReturn = nil
        end
    end
    return out
end

--- Shut the Page list and every page's own list (Oct 30 2026, punch list 21 a-f: the window
-- calls it when the tab is left, its drawer folds or an item card opens over it).
function ZeD.JournalTab.shutLists(win)
    if not win then return end
    if win._journalPageOpen then closePageMenu(win) end
    shutPageLists(win)
end

--- Any of the Journal's pop-up lists open (the Page list, or a page's own).
function ZeD.JournalTab.listsOpen(win)
    if not win then return false end
    if win._journalPageOpen then return true end
    local s = win._jrecipeState
    if s and (s.catDropdownOpen or s.sortMenuOpen or s.showMenuOpen) then return true end
    local sub = win._journalSubTab or 1
    return (sub == 3 or sub == 5) and ZeD.JournalTab.pageListOpen(win) or false
end

--- The Page list open (its rows alone hold the controller).
function ZeD.JournalTab.pageMenuOpen(win)
    return (win and win._journalPageOpen == true and win._journalPageZones ~= nil) or false
end
-- ============================================================================
-- MAIN RENDERER — the header strip, then the open page
-- ============================================================================

function ZeD.JournalTab.render(panel, win, x, y, w, h)
    -- Initialize the page if needed
    if not (win._journalSubTab and SUB_TABS[win._journalSubTab]) then
        win._journalSubTab = 1
    end
    -- a page switched off while it was open (Loadouts): back to the log
    if not subTabShown(SUB_TABS[win._journalSubTab]) then
        win._journalSubTab = 1
    end
    -- a delete question belongs to the log: it goes when the player leaves it
    if win._journalSubTab ~= 1 then win._journalAsk = nil; win._journalAskRects = nil end

    -- the Papers / Notebooks / Into hit zones start empty each frame
    ZeD.JournalReaders.beginFrame(win)
    if win._journalSubTab ~= 1 then win._journalBandRect = nil end

    -- The header strip (Page, the search); the page under it, its band at its foot
    local headerH = drawHeader(panel, win, x, y, w)
    local contentY = y + headerH
    local contentH = h - headerH

    -- Route to the open page (1 Journal, 2 Notebooks, 3 Papers, 4 Recipes, 5 Loadouts)
    local activeIdx = win._journalSubTab
    if activeIdx == 1 then
        renderJournal(panel, win, x, contentY, w, contentH)
    elseif activeIdx == 2 then
        ZeD.JournalReaders.renderNotebooks(panel, win, x, contentY, w, contentH)
    elseif activeIdx == 3 then
        ZeD.JournalReaders.renderPapers(panel, win, x, contentY, w, contentH)
    elseif activeIdx == 4 then
        renderRecipes(panel, win, x, contentY, w, contentH)
    elseif activeIdx == 5 and ZeD.JournalLists then
        ZeD.JournalLists.render(panel, win, x, contentY, w, contentH)
    end

    -- the Page list, open: last, over the page
    drawPageMenu(panel, win)
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.JournalTab.register(dispatchTable)
    dispatchTable["journal"] = ZeD.JournalTab.render
end
