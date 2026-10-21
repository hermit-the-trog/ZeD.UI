-- ZeD-UI/42/media/lua/client/ZeD/SkillsTab.lua
-- ============================================================================
-- SKILLS TAB — 2-column skill grid with XP progress bars.
-- Category-grouped skills, color-coded XP rows, boost pills.
--
-- Design reference: CharInfoOverhaul XP screen (CharInfoPanel.lua 1060-1257).
-- Drawer widens to 480px via per-tab drawer width system.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.SkillsTab = {}

-- ============================================================================
-- XP HELPERS (ported from vanilla ISSkillProgressBar)
-- ============================================================================

local function getPreviousXpLvl(perk, level)
    if level == 0 then return 0 end
    level = level - 1
    local prev = perk:getXp1()
    if level >= 1 then prev = prev + perk:getXp2() end
    if level >= 2 then prev = prev + perk:getXp3() end
    if level >= 3 then prev = prev + perk:getXp4() end
    if level >= 4 then prev = prev + perk:getXp5() end
    if level >= 5 then prev = prev + perk:getXp6() end
    if level >= 6 then prev = prev + perk:getXp7() end
    if level >= 7 then prev = prev + perk:getXp8() end
    if level >= 8 then prev = prev + perk:getXp9() end
    if level >= 9 then prev = prev + perk:getXp10() end
    return prev
end

-- ============================================================================
-- PROGRESS BAR COLORS (matches CharInfoOverhaul color progression)
-- ghost → green → yellow → red → gold
-- Uses ZeD.T tokens where possible, with alpha-scaled bg variants.
-- ============================================================================

local function getProgressColors(T, level, xpPct)
    if level <= 0 then
        -- Ghost: faint positive for unskilled
        return ZeD.colorAlpha(T.positive, 0.5),
               ZeD.colorAlpha(T.positive, 0.0)
    end
    if level >= 10 then
        -- Gold: maxed skill
        return ZeD.colorAlpha(T.warning, 1.0),
               ZeD.colorAlpha(T.warning, 0.55)
    end
    if xpPct >= 0.75 then
        -- Red: approaching level-up
        return T.danger,
               { r = T.danger.r, g = T.danger.g, b = T.danger.b, a = 0.45 }
    end
    if xpPct >= 0.40 then
        -- Yellow: mid-level
        return T.warning,
               { r = T.warning.r, g = T.warning.g, b = T.warning.b, a = 0.45 }
    end
    -- Green: early in level
    return T.positive,
           { r = T.positive.r, g = T.positive.g, b = T.positive.b, a = 0.45 }
end

-- ============================================================================
-- LEVEL BADGE DRAW HELPER
-- 20px rect with centered level number, matching CIO design.
-- ============================================================================

local BADGE_W = 20

local function drawLevelBadge(panel, x, y, h, level, font)
    local T = ZeD.T
    local bgA = level > 0 and 0.25 or 0.12
    local bg = T.surf3
    panel:drawRect(x, y, T.px(BADGE_W), h, bgA, bg.r, bg.g, bg.b)

    local lvStr = tostring(level)
    local lvW = ZeD.TM:MeasureStringX(font, lvStr)
    local lvX = x + math.floor((T.px(BADGE_W) - lvW) / 2)
    local lvY = y + math.floor((h - ZeD.TM:getFontHeight(font)) / 2)

    if level <= 0 then
        local c = T.textDim
        panel:drawText(lvStr, lvX, lvY, c.r, c.g, c.b, c.a * 0.7, font)
    else
        local c = T.text
        panel:drawText(lvStr, lvX, lvY, c.r, c.g, c.b, c.a, font)
    end
end

-- ============================================================================
-- BOOST PILL DRAW HELPER
-- Right-aligned green pill showing "+75% XP" etc.
-- ============================================================================

local function drawBoostPill(panel, x, y, rowH, boost, font)
    local T = ZeD.T
    local A = ZeD.Atoms
    local pctStr = "75%"
    if boost == 2 then pctStr = "100%"
    elseif boost >= 3 then pctStr = "125%"
    end
    local boostStr = ZeD.tr("UI_ZeD_Skills_Boost", pctStr)
    -- Pre-measure badge width for right-alignment
    local tm = ZeD.TM
    local tw = tm:MeasureStringX(T.fontF5, ZeD.upper(boostStr))
    local badgeW = tw + T.sp.badgePadX * 2
    local badgeH = tm:getFontHeight(T.fontF5) + T.sp.badgePadY * 2
    local pillX = x - badgeW - T.sp.xs
    local pillY = y + math.floor((rowH - badgeH) / 2)

    A.drawBadge(panel, boostStr, pillX, pillY, "positive", false, T.fontF5)
end

-- ============================================================================
-- PERK LOOKUP CACHE — maps display name → PerkFactory.Perk for pin data
-- ============================================================================

local _perkByName = nil

local function getPerkByName(name)
    if not _perkByName then
        _perkByName = {}
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            _perkByName[perk:getName()] = perk
        end
    end
    return _perkByName[name]
end

--- Returns live XP data for a pinned skill (called every frame from title bar).
function ZeD.SkillsTab.getPinData(playerObj, perkName)
    local perk = getPerkByName(perkName)
    if not perk then return nil end
    local perkType = perk:getType()
    if perkType == Perks.None then return nil end
    local level = playerObj:getPerkLevel(perkType)
    if level >= 10 then
        return { name = perkName, level = 10, xpInLevel = 0, xpForLevel = 0, xpPct = 1.0 }
    end
    local totalXp = playerObj:getXp() and playerObj:getXp():getXP(perkType) or 0
    local prevXp = getPreviousXpLvl(perk, level)
    local xpInLevel = math.floor(totalXp - prevXp)
    local xpForLevel = math.floor(perk:getXpForLevel(level + 1))
    if xpForLevel <= 0 then xpForLevel = 1 end
    if xpInLevel < 0 then xpInLevel = 0 end
    return {
        name = perkName,
        level = level,
        xpInLevel = xpInLevel,
        xpForLevel = xpForLevel,
        xpPct = xpInLevel / xpForLevel,
    }
end

-- ============================================================================
-- DATA AGGREGATION
-- Iterates all perks, groups by parent category, computes XP progress.
-- ============================================================================

function ZeD.SkillsTab.gatherData(playerObj)
    local groupMap = {}
    local parentOrder = {}

    for i = 0, PerkFactory.PerkList:size() - 1 do
        local perk = PerkFactory.PerkList:get(i)
        if perk:getParent() ~= Perks.None then
            local parentType = perk:getParent()
            if not groupMap[parentType] then
                local parentPerk = PerkFactory.getPerk(parentType)
                groupMap[parentType] = {
                    name     = ZeD.upper(parentPerk:getName()),
                    isPassive = parentPerk:isPassiv(),
                    skills   = {},
                }
                parentOrder[#parentOrder + 1] = parentType
            end

            local perkType = perk:getType()
            local level = playerObj:getPerkLevel(perkType)
            local xpProgress = 0

            if level >= 10 then
                xpProgress = 1.0
            elseif playerObj:getXp() then
                local totalXp = playerObj:getXp():getXP(perkType)
                local prevXp = getPreviousXpLvl(perk, level)
                local xpInLevel = totalXp - prevXp
                local xpForLevel = perk:getXpForLevel(level + 1)
                if xpForLevel <= 0 then xpForLevel = 1 end
                if xpInLevel < 0 then xpInLevel = 0 end
                if xpInLevel > xpForLevel then xpInLevel = xpForLevel end
                xpProgress = xpInLevel / xpForLevel
            end

            local boost = 0
            if playerObj:getXp() then
                boost = playerObj:getXp():getPerkBoost(perkType)
            end

            groupMap[parentType].skills[#groupMap[parentType].skills + 1] = {
                name       = perk:getName(),
                level      = level,
                xpProgress = xpProgress,
                boost      = boost,
            }
        end
    end

    -- Sort: passive groups first, then alphabetical
    table.sort(parentOrder, function(a, b)
        local ga, gb = groupMap[a], groupMap[b]
        if ga.isPassive and not gb.isPassive then return true end
        if gb.isPassive and not ga.isPassive then return false end
        return ga.name < gb.name
    end)

    -- Sort skills within each group alphabetically
    for _, pt in ipairs(parentOrder) do
        table.sort(groupMap[pt].skills, function(a, b) return a.name < b.name end)
    end

    -- Build ordered category list + totals
    local categories = {}
    local totalSkills = 0
    local totalLevels = 0
    for _, pt in ipairs(parentOrder) do
        local grp = groupMap[pt]
        categories[#categories + 1] = grp
        for _, sk in ipairs(grp.skills) do
            totalSkills = totalSkills + 1
            totalLevels = totalLevels + sk.level
        end
    end

    return {
        categories  = categories,
        totalSkills = totalSkills,
        totalLevels = totalLevels,
    }
end

-- ============================================================================
-- TRAINING MATERIALS — CIO-style skill book catalog
-- Groups ALL literature by trained skill. Four statuses: read/reading/collected/missing.
-- Static catalog cached at module level (script items never change mid-game).
-- ============================================================================

local _tmCatalog = nil  -- built once from getScriptManager():getAllItems()

local function buildTMCatalog()
    if _tmCatalog then return _tmCatalog end
    _tmCatalog = {}

    local allItems = getScriptManager():getAllItems()
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item:isItemType(ItemType.LITERATURE) then
            local skillTrained = item:getSkillTrained()
            if skillTrained and skillTrained ~= "" and SkillBook[skillTrained] then
                if not _tmCatalog[skillTrained] then
                    _tmCatalog[skillTrained] = { label = skillTrained, items = {} }
                end
                _tmCatalog[skillTrained].items[#_tmCatalog[skillTrained].items + 1] = {
                    title    = item:getDisplayName(),
                    fullName = item:getFullName(),
                    numPages = item:getNumberOfPages() or 0,
                }
            end
        end
    end

    -- Convert to sorted list, assign volume numbers, strip redundant skill prefix
    local volNumerals = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }
    local list = {}
    for _, v in pairs(_tmCatalog) do
        table.sort(v.items, function(a, b) return a.title < b.title end)
        for i, entry in ipairs(v.items) do
            entry.volume = volNumerals[i] or tostring(i)
            -- Strip skill name prefix + any roman numeral/number + colon/dash
            -- e.g. "Trapping III: Expert Trapping" → "Expert Trapping"
            -- e.g. "Cooking for Beginners" with skill "Cooking" → "for Beginners"
            local clean = entry.title
            local label = v.label
            -- Try stripping "SkillName I:" / "SkillName II:" etc pattern first
            local stripped = clean:match("^" .. label .. "%s+[IVXLC]+[:%s%-]+%s*(.*)")
            if not stripped then
                -- Try "SkillName:" pattern
                stripped = clean:match("^" .. label .. "[:%s%-]+%s*(.*)")
            end
            if not stripped then
                -- Try just removing skill name prefix
                stripped = clean:match("^" .. label .. "%s+(.*)")
            end
            if stripped and stripped ~= "" then
                -- Capitalize first letter
                entry.shortTitle = ZeD.upper(stripped:sub(1, 1)) .. stripped:sub(2)
            else
                entry.shortTitle = clean
            end
        end
        list[#list + 1] = v
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    _tmCatalog = list
    return _tmCatalog
end

-- a skill id from the skill-book catalog ("Cooking") as the game names it in the
-- player's language; the id itself when the game has no perk for it
function ZeD.SkillsTab.perkName(skillId)
    local ok, name = pcall(function()
        return PerkFactory.getPerk(SkillBook[skillId].perk):getName()
    end)
    if ok and name and name ~= "" then return name end
    return skillId
end

function ZeD.SkillsTab.gatherTrainingData(playerObj)
    local catalog = buildTMCatalog()

    -- Build inventory lookup for "collected" status
    local inventoryHas = {}
    local inv = playerObj:getInventory()
    if inv then
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            inventoryHas[items:get(i):getFullType()] = true
        end
    end

    -- Evaluate status per book
    local groups = {}
    for _, catGroup in ipairs(catalog) do
        local books = {}
        for _, entry in ipairs(catGroup.items) do
            local status = "missing"
            local numPages = entry.numPages
            local readPages = playerObj:getAlreadyReadPages(entry.fullName) or 0

            if numPages > 0 and readPages >= numPages then
                status = "read"
            elseif playerObj:getAlreadyReadBook():contains(entry.fullName) then
                status = "read"
            elseif readPages > 0 then
                status = "reading"
            elseif inventoryHas[entry.fullName] then
                status = "collected"
            end

            books[#books + 1] = {
                title      = entry.shortTitle or entry.title,
                volume     = entry.volume or nil,
                status     = status,
            }
        end
        groups[#groups + 1] = {
            label = catGroup.label,                                   -- the skill id: expand keys, sorting
            disp  = ZeD.SkillsTab.perkName(catGroup.label),           -- what the row shows
            items = books,
        }
    end

    return groups
end

-- ============================================================================
-- COLUMN HEIGHT MEASUREMENT
-- Measures the total pixel height a column of groups would consume.
-- ============================================================================

local function measureColumnHeight(colGroups, rowH, headerH, groupGap, rowGap)
    local totalH = 0
    for _, group in ipairs(colGroups) do
        totalH = totalH + headerH  -- header + rule
        totalH = totalH + #group.skills * (rowH + rowGap)
        totalH = totalH + groupGap
    end
    return totalH
end

-- ============================================================================
-- TRAINING MATERIALS — CIO-STYLE MEASUREMENT & RENDERING
-- Collapsed row: [chevron] [skill label] [status dots...]
-- Expanded row:  [badge pill] [book title]
-- Four statuses: read (green), reading (yellow), collected (red), missing (ghost)
-- ============================================================================

-- Status → token mapping (resolved at render time from ZeD.T)
-- Dot colors come from theme tokens; badge uses A.drawBadge variants.
local TM_STATUS_MAP = {
    read      = { token = "positive", variant = "positive", key = "UI_ZeD_Skills_StatusRead" },
    reading   = { token = "warning",  variant = "warning",  key = "UI_ZeD_Skills_StatusReading" },
    collected = { token = "danger",   variant = "danger",   key = "UI_ZeD_Skills_StatusCollected" },
    missing   = { token = "textDim",  variant = "neutral",  key = "UI_ZeD_Skills_StatusMissing", ghost = true },
}

local TM_DOT_GAP   = 4
local TM_DETAIL_PAD = 26

-- Truncate text to fit within maxW, appending "..." if clipped.
local function truncText(str, font, maxW)
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

-- Measure training section height for scroll content.
-- Must match the draw layout: half-split into col1/col2 with prefixed expand keys.
local function measureTrainingHeight(training, headH, secH, bodyH, rowH, rowGap, headerH, groupGap, expandedMap)
    local T = ZeD.T
    if not training or #training == 0 then return 0 end

    local collapsedRowH = math.max(secH + T.px(10), T.px(26))
    local detailRowH    = secH + T.px(12)

    -- Header area: gap + heading + groove + legend row
    local headerArea = T.px(12) + headH + T.px(ZeD.Spacing.headGap) + T.px(2) + T.px(2) + secH + T.px(4) + T.px(2)

    -- Split groups same way as draw: first half col1, second half col2
    local half = math.ceil(#training / 2)

    local function measureColumn(startIdx, endIdx, colKey)
        local colH = 0
        for i = startIdx, endIdx do
            local group = training[i]
            colH = colH + collapsedRowH + T.px(1)
            local expandKey = colKey .. "_" .. group.label
            if expandedMap and expandedMap[expandKey] then
                colH = colH + #group.items * (detailRowH + T.px(1))
            end
        end
        return colH
    end

    local col1H = measureColumn(1, half, "col1")
    local col2H = measureColumn(half + 1, #training, "col2")

    return headerArea + math.max(col1H, col2H)
end

-- Draw training section. Returns click zones array.
local function drawTrainingSection(panel, startY, x, w, col1X, col2X, colW, colGap,
                                    training, expandedMap, secH, bodyH, rowH, rowGap,
                                    headerH, groupGap, font)
    local T = ZeD.T
    local A = ZeD.Atoms
    local zones = {}

    if not training or #training == 0 then return zones end

    local collapsedRowH = math.max(secH + T.px(10), T.px(26))
    local detailRowH    = secH + T.px(12)
    local cy = startY + T.px(12)

    -- ── Header: "TRAINING MATERIALS" ──
    local tm = ZeD.TM
    local headingH = tm:getFontHeight(T.fontF4)
    local hnc = T.toneNorm
    panel:drawText(ZeD.tr("UI_ZeD_Skills_TrainingMaterials"), x, cy, hnc.r, hnc.g, hnc.b, hnc.a or 1, T.fontF4)
    cy = cy + headingH + T.sp.headGap

    A.drawGroove(panel, x, cy, w)
    cy = cy + T.px(2) + T.sp.afterGroove

    -- Legend row (left-aligned below heading)
    local legendDefs = {
        TM_STATUS_MAP.read,
        TM_STATUS_MAP.reading,
        TM_STATUS_MAP.collected,
        TM_STATUS_MAP.missing,
    }
    local legRowH = secH + T.px(4)
    local legX = x
    local legDotY = cy + math.floor((legRowH - T.px(A.SWATCH_H)) / 2)

    for _, def in ipairs(legendDefs) do
        local dotColor = T[def.token]
        A.drawLegendSwatch(panel, legX, legDotY, dotColor, def.ghost)
        legX = legX + T.px(A.SWATCH_W) + T.sp.xs
        local lc = T.toneLo
        local defLabel = ZeD.tr(def.key)
        panel:drawText(defLabel, legX, cy + math.floor((legRowH - secH) / 2),
            lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
        legX = legX + tm:MeasureStringX(T.fontF1, defLabel) + T.px(TM_DOT_GAP) + T.sp.sm
    end

    cy = cy + legRowH + T.px(2)

    -- ── Split groups into 2 columns (simple half-split like CIO) ──
    local half = math.ceil(#training / 2)
    local col1 = {}
    local col2 = {}
    for i, group in ipairs(training) do
        if i <= half then
            col1[#col1 + 1] = group
        else
            col2[#col2 + 1] = group
        end
    end

    local colStartY = cy

    -- ── Draw a training materials column ──
    local function drawTMColumn(startX, colWidth, dataList, columnKey)
        local dy = colStartY

        for si, skillGroup in ipairs(dataList) do
            local expandKey = columnKey .. "_" .. skillGroup.label
            local isExpanded = expandedMap and expandedMap[expandKey]

            -- Chevron icon (scaled smaller than font height for visual balance)
            local chevSz = math.max(T.px(8), math.floor(secH * 0.7))
            local chevX = startX + T.px(8)
            local chevY = dy + math.floor((collapsedRowH - chevSz) / 2)
            if isExpanded then
                A.drawTriangleDown(panel, chevX, chevY, chevSz, T.arrow)
            else
                A.drawTriangleRight(panel, chevX, chevY, chevSz, T.arrow)
            end

            -- Skill label (truncated to ~35% of column width)
            local labelX = startX + T.px(8) + chevSz + T.px(8)
            local labelMaxW = math.floor(colWidth * 0.35)
            local labelStr = truncText(skillGroup.disp or skillGroup.label, font, labelMaxW)
            local labelC = T.toneNorm
            panel:drawText(labelStr, labelX, dy + math.floor((collapsedRowH - secH) / 2),
                labelC.r, labelC.g, labelC.b, labelC.a or 1, font)

            -- Status dots (one per book, after label region) — theme tokens
            local dotsX = labelX + labelMaxW + T.px(8)
            local dotsY = dy + math.floor((collapsedRowH - T.px(A.SWATCH_H)) / 2)

            for _, bookItem in ipairs(skillGroup.items) do
                local def = TM_STATUS_MAP[bookItem.status] or TM_STATUS_MAP.missing
                local dotColor = T[def.token]
                A.drawLegendSwatch(panel, dotsX, dotsY, dotColor, def.ghost)
                dotsX = dotsX + T.px(A.SWATCH_W) + T.px(TM_DOT_GAP)
            end

            -- Row separator
            local bd = T.border
            panel:drawRect(startX, dy + collapsedRowH, colWidth, T.px(1), bd.a * 0.15, bd.r, bd.g, bd.b)

            -- Click zone
            zones[#zones + 1] = {
                id = expandKey,
                x  = startX,
                y  = dy,
                w  = colWidth,
                h  = collapsedRowH,
            }

            dy = dy + collapsedRowH + T.px(1)

            -- ── Expanded detail rows ──
            if isExpanded then
                local detailPad = startX + T.px(TM_DETAIL_PAD)

                for _, bookItem in ipairs(skillGroup.items) do
                    local def = TM_STATUS_MAP[bookItem.status] or TM_STATUS_MAP.missing

                    -- Color chip (same dot as collapsed row)
                    local chipX = detailPad
                    local chipY = dy + math.floor((detailRowH - T.px(A.SWATCH_H)) / 2)
                    local dotColor = T[def.token]
                    A.drawLegendSwatch(panel, chipX, chipY, dotColor, def.ghost)

                    -- Book title + volume (truncated)
                    local titleX = chipX + T.px(A.SWATCH_W) + T.px(6)
                    local titleMaxW = (startX + colWidth - T.px(8)) - titleX
                    local displayStr = bookItem.title
                    if bookItem.volume then
                        displayStr = ZeD.tr("UI_ZeD_Skills_Volume", displayStr, bookItem.volume)
                    end
                    local titleStr = truncText(displayStr, font, titleMaxW)
                    local titleC = T.toneNorm
                    panel:drawText(titleStr, titleX, dy + math.floor((detailRowH - secH) / 2),
                        titleC.r, titleC.g, titleC.b, titleC.a or 1, T.fontF1)

                    -- Detail row separator
                    local bd = T.border
                    panel:drawRect(startX, dy + detailRowH, colWidth, T.px(1), bd.a * 0.1, bd.r, bd.g, bd.b)
                    dy = dy + detailRowH + T.px(1)
                end
            end
        end

        return dy
    end

    local y1 = drawTMColumn(col1X, colW, col1, "col1")
    local y2 = drawTMColumn(col2X, colW, col2, "col2")

    return zones, math.max(y1, y2) - startY
end

-- ============================================================================
-- RENDERER
-- Draws 2-column skill grid in the wide drawer panel.
-- Called by the tab dispatch in ZeD_CharacterWindow.
-- ============================================================================

function ZeD.SkillsTab.render(panel, win, x, y, w, h)
    local T    = ZeD.T
    local M    = ZeD.Molecules
    local pad    = M.getTabPad()      -- 8px outer pad
    local padTop = M.getTabPadTop()   -- 8px top pad below pinned header

    -- Throttled data refresh
    win._skillsTimer = (win._skillsTimer or 0) + 1
    if win._skillsTimer >= 15 or not win._skillsCache then
        win._skillsTimer = 0
        win._skillsCache = ZeD.SkillsTab.gatherData(win._playerObj)
    end
    local data = win._skillsCache

    -- S103 — cache last frame's row/chevron zones BEFORE we clear/overwrite
    -- them mid-render. Scroll-follow (below) reads these to find the focused
    -- element's absolute y for scroll-to-viewport math. One-frame lag is
    -- imperceptible (same trick HealthTab uses for injury scroll-follow).
    local lastSkillRowZones = win._skillRowZones or {}
    local lastTrainingZones = win._trainingGroupZones or {}

    -- S103 — resolve the live focused element once per frame so paint cues
    -- for skill rows and training chevrons gate on element identity, not on
    -- persistent state fields (avoids cross-element leak inside charTabContent).
    local focusedSkillName = nil
    local focusedTrainingId = nil
    local focusedIsDisclosure = false
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if Focus and Focus.getFocusedWindow and Focus.getFocusedElement
           and Focus.getFocusedWindow() == win then
            local el = Focus.getFocusedElement(win)
            if el then
                focusedSkillName   = el.skillName
                focusedTrainingId  = el.trainingId
                focusedIsDisclosure = el.isDisclosure == true
            end
        end
    end

    -- Font metrics
    local headH = ZeD.TM:getFontHeight(T.fontF4)
    local secH  = ZeD.TM:getFontHeight(T.fontF1)
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)

    -- Skill row dimensions (matching CIO: F.hgtSmall + 8)
    local rowH = secH + T.px(8)
    local rowGap = T.sp.rowGap
    local headerH = secH + T.px(14)      -- skill group header height (not tab header)
    local groupGap = T.sp.sm

    -- Pinned tab header (37px, not in scroll content)
    local tabHeaderH = M.getTabHeaderH()

    -- S103: stamp the disclosure hit-zone EARLY (was at end of render) so the
    -- very first prerender after a tab-switch sees valid bounds and the
    -- disclosure focusable builds into element[1]. Without this, the first
    -- frame of Skills returns [skill rows, chevrons] only, idx=1 lands on
    -- the first skill row, and the disclosure-first entry point is missed.
    win._skillsGridZone = { x = x, y = y, w = w, h = tabHeaderH }

    -- ================================================================
    -- SCROLL SETUP (area starts below pinned tab header)
    -- ================================================================
    local scroll  = win._skillsScroll
    local scrollW = T.sp.scrollbarW

    -- Column layout (colW computed after scroll setup, see below)
    local colGap = T.sp.sm

    -- Distribute groups across 2 columns (load-balanced by skill count)
    local columns = { {}, {} }
    local colCounts = { 0, 0 }

    for _, group in ipairs(data.categories) do
        local minCol = 1
        if colCounts[2] < colCounts[1] then minCol = 2 end
        columns[minCol][#columns[minCol] + 1] = group
        colCounts[minCol] = colCounts[minCol] + #group.skills + 1
    end

    -- Training data (separate throttle — literature changes less often)
    win._trainingTimer = (win._trainingTimer or 0) + 1
    if win._trainingTimer >= 30 or not win._trainingCache then
        win._trainingTimer = 0
        win._trainingCache = ZeD.SkillsTab.gatherTrainingData(win._playerObj)
    end
    local training = win._trainingCache
    win._trainingExpanded = win._trainingExpanded or {}

    -- Measure content height (max of both columns + training section)
    local col1H = measureColumnHeight(columns[1], rowH, headerH, groupGap, rowGap)
    local col2H = measureColumnHeight(columns[2], rowH, headerH, groupGap, rowGap)
    local xpGridH = math.max(col1H, col2H)
    local trainingH = measureTrainingHeight(training, headH, secH, bodyH, rowH, rowGap, headerH, groupGap, win._trainingExpanded)
    local gridExpanded = win._skillsGridExpanded
    local totalContentH = padTop + (gridExpanded and xpGridH or 0) + trainingH

    -- Scroll area starts below pinned tab header
    local scrollY = y + tabHeaderH
    local scrollH = h - tabHeaderH
    local needsScroll = totalContentH > scrollH
    scroll.visible = needsScroll
    local contentW = w
    if needsScroll then
        scroll.x = x + w - scrollW
        scroll.y = scrollY
        scroll.height = scrollH
        scroll:setBarSize(scrollH / math.max(1, totalContentH))
        contentW = w - scrollW
    else
        scroll:setScrollPos(0)
    end

    -- cw = inner width between outer pads (passed to drawTrainingSection for groove/separator widths)
    local cw   = contentW - pad * 2
    -- colW accounts for outer pad on both sides within contentW
    local colW = math.floor((cw - colGap) / 2)

    -- S103 gamepad scroll-follow. When the focused ring element is a skill
    -- row or training chevron, adjust scroll.scrollPos BEFORE scrollOff is
    -- computed so the focused element stays in the viewport. Reads last
    -- frame's stamped zone geometry (cached at render top).
    -- DELTA GATE: only pin scroll when the focused id actually CHANGED this
    -- render. A mode gate (getMode() == "gamepad") is unreliable because
    -- the input detector oscillates kbm↔gamepad within consecutive frames;
    -- the delta gate fires exactly once per focus change regardless of mode,
    -- so a KBM mousewheel past the focused row doesn't snap it back.
    local _focKey = focusedSkillName or focusedTrainingId
    if needsScroll and _focKey and _focKey ~= win._lastPinnedSkillsFoc then
        local focAbsY, focH = nil, nil
        if focusedSkillName then
            for i = 1, #lastSkillRowZones do
                local z = lastSkillRowZones[i]
                if z.name == focusedSkillName then
                    focAbsY = z.y; focH = z.h; break
                end
            end
        elseif focusedTrainingId then
            for i = 1, #lastTrainingZones do
                local z = lastTrainingZones[i]
                if z.id == focusedTrainingId then
                    focAbsY = z.y; focH = z.h; break
                end
            end
        end
        if focAbsY and focH then
            local span    = math.max(1, totalContentH - scrollH)
            local oldOff  = math.floor(scroll.scrollPos * span)
            local logicalY = focAbsY - scrollY + oldOff
            if logicalY < oldOff then
                scroll:setScrollPos(logicalY / span)
            elseif logicalY + focH > oldOff + scrollH then
                scroll:setScrollPos((logicalY + focH - scrollH) / span)
            end
        end
        win._lastPinnedSkillsFoc = _focKey
    end

    panel:setStencilRect(x, scrollY, contentW, scrollH)

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * math.max(0, totalContentH - scrollH))
    end

    local drawY = scrollY - scrollOff + padTop
    local curY = drawY

    -- ----------------------------------------------------------------
    -- ZONE B: 2-Column Skill Grid (collapsible)
    -- ----------------------------------------------------------------
    local zoneABottom = curY

    local font = T.fontF2
    local col1X = x + pad
    local col2X = x + pad + colW + colGap

    -- Skill row hit zones for click-to-pin (rebuilt each frame)
    win._skillRowZones = {}
    local pins = win._pinnedSkills or {}

    if gridExpanded then

    local function drawColumn(startX, colWidth, colGroups)
        local cy = zoneABottom
        local skillRowIdx = 0

        for _, group in ipairs(colGroups) do
            -- Group header: category name
            local hdrColor = T.toneLo
            panel:drawText(group.name, startX, cy,
                hdrColor.r, hdrColor.g, hdrColor.b, hdrColor.a or 1, font)
            cy = cy + secH + T.px(4)

            -- Rule line under header
            local ruleC = T.border
            panel:drawRect(startX, cy, colWidth, T.px(1), ruleC.a, ruleC.r, ruleC.g, ruleC.b)
            cy = cy + T.px(1) + T.sp.afterGroove

            for _, skill in ipairs(group.skills) do
                local _, bgColor = getProgressColors(T, skill.level, skill.xpProgress)

                -- Alternating row stripe
                if skillRowIdx % 2 == 1 then
                    local st = T.stripe
                    panel:drawRect(startX, cy, colWidth, rowH, st.a, st.r, st.g, st.b)
                end

                -- Pinned skill accent highlight
                local isPinned = false
                for _, p in ipairs(pins) do
                    if p == skill.name then isPinned = true; break end
                end
                if isPinned then
                    local ac = T.accent
                    panel:drawRect(startX, cy, colWidth, rowH, 0.12, ac.r, ac.g, ac.b)
                end

                -- XP progress background fill
                if skill.level >= 10 then
                    panel:drawRect(startX, cy, colWidth, rowH,
                        bgColor.a, bgColor.r, bgColor.g, bgColor.b)
                elseif skill.level > 0 and skill.xpProgress > 0 then
                    local fillW = math.floor(colWidth * skill.xpProgress)
                    if fillW > 0 then
                        panel:drawRect(startX, cy, fillW, rowH,
                            bgColor.a, bgColor.r, bgColor.g, bgColor.b)
                    end
                end

                -- Level badge
                drawLevelBadge(panel, startX, cy, rowH, skill.level, font)

                -- Skill name
                local nameX = startX + T.px(BADGE_W) + T.px(6)
                local nameY = cy + math.floor((rowH - ZeD.TM:getFontHeight(font)) / 2)
                local nc = T.toneNorm
                panel:drawText(skill.name, nameX, nameY, nc.r, nc.g, nc.b, nc.a or 1, font)

                -- Boost pill (right-aligned)
                if skill.boost and skill.boost > 0 then
                    drawBoostPill(panel, startX + colWidth, cy, rowH, skill.boost, font)
                end

                -- Register hit zone for click-to-pin
                win._skillRowZones[#win._skillRowZones + 1] = {
                    x = startX, y = cy, w = colWidth, h = rowH,
                    name = skill.name,
                }

                -- S103: paint-gate on LIVE focused element (not win._gpFocusedSkill).
                -- charTabContent now hosts three element types (disclosure / skill
                -- rows / training chevrons); persistent state fields would paint
                -- stale cues when focus moves to a different element type inside
                -- the zone. The state field is still written by onFocus for
                -- scroll-follow keying, but paint reads the live element.
                if focusedSkillName == skill.name
                   and ZeD.Atoms and ZeD.Atoms.drawAccentRing then
                    ZeD.Atoms.drawAccentRing(panel, startX, cy, colWidth, rowH, T.px(2), T.accent)
                end

                cy = cy + rowH + rowGap
                skillRowIdx = skillRowIdx + 1
            end

            cy = cy + groupGap
        end
    end

    drawColumn(col1X, colW, columns[1])
    drawColumn(col2X, colW, columns[2])

    -- Column separator (XP grid only)
    local sepX = x + pad + colW + math.floor(colGap / 2)
    local sepTop = zoneABottom
    local sepBot = sepTop + xpGridH
    local sepC = T.border
    panel:drawRect(sepX, sepTop, T.px(1), sepBot - sepTop, sepC.a, sepC.r, sepC.g, sepC.b)

    end -- gridExpanded

    -- Training materials section (below XP grid when expanded, or directly below header when collapsed)
    local trainingStartY = zoneABottom + (gridExpanded and xpGridH or 0)
    local tmZones, tmActualH = drawTrainingSection(
        panel, trainingStartY, col1X, cw, col1X, col2X, colW, colGap,
        training, win._trainingExpanded, secH, bodyH, rowH, rowGap,
        headerH, groupGap, font
    )
    win._trainingGroupZones = tmZones

    -- S103 gamepad focus cue for training chevron rows. Painted after the
    -- section draw so it overlays the row background but under the stencil
    -- clear. Gated on live focused element (focusedTrainingId), not a
    -- persistent state field, so the cue clears when focus moves to a
    -- skill row or the disclosure within charTabContent.
    if focusedTrainingId and tmZones then
        for i = 1, #tmZones do
            local z = tmZones[i]
            if z.id == focusedTrainingId then
                local ac = T.accent
                panel:drawRect(z.x, z.y, z.w, z.h, 0.55, ac.r, ac.g, ac.b)
                break
            end
        end
    end

    -- Training column separator
    if trainingH > 0 then
        local tmSepX = x + pad + colW + math.floor(colGap / 2)
        local tmHeaderH = T.px(12) + T.sp.beforeHead + headH + T.sp.headGap + T.px(2) + T.px(2) + secH + T.px(4) + T.px(2)
        local tSepTop = trainingStartY + tmHeaderH
        local tSepBot = trainingStartY + trainingH
        if tSepBot > tSepTop then
            panel:drawRect(tmSepX, tSepTop, T.px(1), tSepBot - tSepTop, 0.04, 1.0, 1.0, 1.0)
        end
    end

    panel:clearStencilRect()

    -- S103 gamepad focus cue on the tab-header disclosure — 0.55α T.accent
    -- over the header rect, drawn BEFORE drawTabHeader so the chevron + text
    -- render on top. Mirrors ThermalTab.lua:284-294 exactly.
    if focusedIsDisclosure then
        local ac = T.accent
        panel:drawRect(x, y, w, tabHeaderH, 0.55, ac.r, ac.g, ac.b)
    end

    -- Pinned tab header — drawn on top of scroll content
    -- (_skillsGridZone is stamped at the TOP of render now, not here)
    M.drawTabHeader(panel, x, y, w, getText("IGUI_XP_Skills"), gridExpanded)

    -- Draw scrollbar on top (outside stencil)
    if needsScroll then
        scroll:draw(panel)
    end
end

-- ============================================================================
-- REGISTRATION — called by ZeD_CharacterWindow to wire into tab dispatch
-- ============================================================================

function ZeD.SkillsTab.register(dispatchTable)
    dispatchTable["skills"] = ZeD.SkillsTab.render
end
