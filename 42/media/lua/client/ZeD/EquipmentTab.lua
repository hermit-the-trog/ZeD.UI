-- ZeD-UI/42/media/lua/client/ZeD/EquipmentTab.lua
-- ============================================================================
-- EQUIPMENT TAB — Grouped slot list with click-to-inspect item cards.
-- Zone A: collapsible group headers with slot rows (list mode)
-- Zone B: item card with body figure coverage overlay (card mode)
-- First implementation.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/ZeD_BodyFigure"
require "ZeD/ProtectionTab"

ZeD = ZeD or {}
ZeD.EquipmentTab = {}

-- ============================================================================
-- SLOT DEFINITIONS
-- Each group has an ordered list of slots. Each slot has a 3-letter type code,
-- a display label, and the PZ body location strings it maps to.
-- First worn item matching any location in the array fills the slot.
-- ============================================================================

local EQUIP_GROUPS = {
    { id = "head", label = "HEAD + FACE", slots = {
        { type = "HAT", label = "Hat",     locs = {"hat", "fullhat", "sweaterhat", "jackethat", "jackethatbulky", "fullsuithead", "fullsuitheadscba"} },
        { type = "EYE", label = "Eyewear", locs = {"eyes", "lefteye", "righteye"} },
        { type = "MSK", label = "Mask",    locs = {"mask", "maskeyes", "maskfull"} },
        { type = "EAR", label = "Ears",    locs = {"ears", "eartop"} },
        { type = "SCF", label = "Scarf",   locs = {"scarf", "necktexture"} },
    }},
    { id = "torso", label = "TORSO", slots = {
        { type = "OUT", label = "Outer",     locs = {"jacket", "jacketdown", "jacketbulky", "jacketsuit", "boilersuit", "fullsuit", "fulltop", "bathrobe", "fullrobe", "bodycostume", "sweater", "jersey"} },
        { type = "INR", label = "Inner",     locs = {"tshirt", "tanktop", "shirt", "shortsleeveshirt", "torso1", "torso1legs1", "torsoextra"} },
        { type = "VST", label = "Vest",      locs = {"torsoextravest", "torsoextravestbullet", "cuirass", "gorget", "vesttexture", "shoulderholster"} },
        { type = "UND", label = "Underwear",  locs = {"underwear", "underweartop", "underwearbottom", "underwearextra1", "underwearextra2"} },
        { type = "NKL", label = "Neck",      locs = {"necklace", "necklacelong", "neck"} },
    }},
    { id = "arms", label = "ARMS + HANDS", slots = {
        { type = "GLV", label = "Gloves",   locs = {"hands", "handsleft", "handsright"} },
        { type = "WCH", label = "Wrist",    locs = {"leftwrist", "rightwrist"} },
        { type = "RNG", label = "Ring",     locs = {"leftmiddlefinger", "rightmiddlefinger", "leftringfinger", "rightringfinger"} },
        { type = "ARM", label = "Arms",     locs = {"leftarm", "rightarm", "forearmleft", "forearmright", "elbowleft", "elbowright"} },
        { type = "SHD", label = "Shoulder", locs = {"shoulderpadleft", "shoulderpadright", "sportshoulderpad", "sportshoulderpaddontop"} },
    }},
    { id = "legs", label = "LEGS + FEET", slots = {
        { type = "PNT", label = "Pants",   locs = {"pants", "pantsskinny", "pantsextra", "shortpants", "shortsshort", "legs1", "skirt", "longskirt", "dress", "longdress"} },
        { type = "SOC", label = "Socks",   locs = {"socks"} },
        { type = "BOT", label = "Shoes",   locs = {"shoes"} },
        { type = "KNE", label = "Knee/Leg",locs = {"kneeleft", "kneeright", "calfleft", "calfright", "calflefttexture", "calfrighttexture", "thighleft", "thighright", "gaiterleft", "gaiterright"} },
    }},
    { id = "held", label = "HELD + BELT", slots = {
        { type = "PRI", label = "Primary",  locs = {"__primary"} },
        { type = "SEC", label = "Secondary", locs = {"__secondary"} },
        { type = "BAG", label = "Back/Bag", locs = {"back", "satchel"} },
        { type = "BLT", label = "Belt",     locs = {"belt", "beltextra", "fannypackfront", "fannypackback", "webbing", "ankleholster", "ammostrap"} },
    }},
}

-- Build reverse lookup: PZ body location string → {groupIdx, slotIdx}
-- All keys stored lowercase for case-insensitive matching.
local LOCATION_TO_SLOT = {}
for gi, group in ipairs(EQUIP_GROUPS) do
    for si, slot in ipairs(group.slots) do
        for _, loc in ipairs(slot.locs) do
            if loc:sub(1, 2) ~= "__" then
                LOCATION_TO_SLOT[string.lower(loc)] = { gi = gi, si = si }
            end
        end
    end
end

-- ============================================================================
-- SLOT → BODY FIGURE REGION MAPPING
-- Maps slot type to ZeD_BodyFigure display names for coverage highlighting.
-- ============================================================================

local SLOT_REGIONS = {
    HAT = {"Head"},
    EYE = {"Head"},
    MSK = {"Head", "Neck"},
    EAR = {"Head"},
    SCF = {"Neck"},
    OUT = {"Upper Torso", "Lower Torso", "Left Upper Arm", "Right Upper Arm", "Left Forearm", "Right Forearm"},
    INR = {"Upper Torso", "Lower Torso", "Left Upper Arm", "Right Upper Arm"},
    VST = {"Upper Torso", "Lower Torso"},
    UND = {"Upper Torso", "Lower Torso", "Groin"},
    NKL = {"Neck"},
    GLV = {"Left Hand", "Right Hand", "Left Forearm", "Right Forearm"},
    WCH = {"Left Forearm", "Right Forearm"},
    RNG = {"Left Hand", "Right Hand"},
    ARM = {"Left Upper Arm", "Right Upper Arm", "Left Forearm", "Right Forearm"},
    SHD = {"Left Upper Arm", "Right Upper Arm"},
    PNT = {"Left Upper Leg", "Right Upper Leg", "Groin"},
    SOC = {"Left Lower Leg", "Right Lower Leg"},
    BOT = {"Left Foot", "Right Foot"},
    KNE = {"Left Upper Leg", "Right Upper Leg", "Left Lower Leg", "Right Lower Leg"},
    PRI = {"Right Hand", "Left Hand"},
    SEC = {"Left Hand"},
    BAG = {},
    BLT = {"Groin"},
}

-- ============================================================================
-- LAYOUT CONSTANTS
-- ============================================================================

local GROUP_H    = 15  -- group header height (matches T.sp.catHdrH)
local function getBackH() return 4 + ZeD.T.buttonH + 2 end  -- back bar: 4px above button + 2px below
local COND_BAR_W = 80  -- condition bar width
local PROT_COL_W = 32  -- protection stat column width
local SWATCH_SZ  = 18  -- item swatch square size
local TRI_SZ     = 7   -- disclosure triangle size
local BADGE_SZ   = 13  -- attachment count badge size

-- Pre-computed label column width (widest label across all slots, measured lazily)
local _labelColW = nil
local function getLabelColW()
    if _labelColW then return _labelColW end
    local tm = getTextManager()
    local T = ZeD.T
    local maxW = 0
    for _, group in ipairs(EQUIP_GROUPS) do
        for _, slot in ipairs(group.slots) do
            local w = tm:MeasureStringX(T.fontF5, slot.label or slot.type)
            if w > maxW then maxW = w end
        end
    end
    _labelColW = maxW
    return _labelColW
end

-- Default resizable column widths (matches inventory renderer pattern)
local DIV_W = 6  -- divider hit zone width
local function getDefaultColWidths(scale)
    return {
        slot = getLabelColW() + 4,
        cond = COND_BAR_W + 4,
        wt   = math.floor(40 * scale),
    }
end

-- Shared column layout: NAME SLOT COND BITE SCR BUL WT
-- Returns table of column X positions and widths
local function calcEquipColumns(w, win)
    local T     = ZeD.T
    local sp    = T.sp
    local scale = T.scale or 1
    local padX  = sp.sm
    local rowH  = T.rowH
    local iconW = rowH - 8
    local iconGap = sp.iconGap or 6

    -- Resizable column widths from win state
    local cw = win and win._equipColWidths
    if not cw then cw = getDefaultColWidths(scale) end
    local slotColW = cw.slot
    local condColW = cw.cond
    local wtColW   = cw.wt

    -- Fixed-width protection columns
    local protColW = math.floor(PROT_COL_W * scale)

    -- Name fills remaining space
    local rightCols = slotColW + condColW + protColW * 3 + wtColW + padX
    local nameX = padX + iconW + iconGap
    local nameW = w - nameX - rightCols
    if nameW < 40 then nameW = 40 end

    -- Column order: NAME SLOT COND BITE SCR BUL WT
    local slotX = nameX + nameW
    local condX = slotX + slotColW
    local biteX = condX + condColW
    local scrX  = biteX + protColW
    local bulX  = scrX + protColW
    local wtX   = bulX + protColW

    return {
        padX = padX, iconW = iconW, iconGap = iconGap,
        nameX = nameX, nameW = nameW,
        slotX = slotX, slotColW = slotColW,
        condX = condX, condColW = condColW,
        biteX = biteX, scrX = scrX, bulX = bulX, protColW = protColW,
        wtX = wtX, wtColW = wtColW,
    }
end

-- ============================================================================
-- HELPERS
-- ============================================================================

local safeGet = ZeD.Atoms.safeGet

-- Condition ratio for an item (0..1)
local function condRatio(item)
    if not item then return 0 end
    local c = safeGet(item, "getCondition") or 0
    local m = safeGet(item, "getConditionMax") or 1
    if m <= 0 then m = 1 end
    return math.max(0, math.min(1, c / m))
end

-- Condition color: green > 60%, amber 30-60%, red < 30%
local function condColor(ratio)
    local T = ZeD.T
    if ratio > 0.6  then return T.positive end
    if ratio > 0.3  then return T.warning  end
    return T.danger
end

-- Protection stats for an item
local function getProtection(item)
    if not item then return { bite = 0, scratch = 0, bullet = 0 } end
    local bite = safeGet(item, "getBiteDefense") or 0
    local scratch = safeGet(item, "getScratchDefense") or 0
    local bullet = 0
    local parts = safeGet(item, "getCoveredParts")
    if parts and parts:size() > 0 then
        local part = parts:get(0)
        bullet = safeGet(item, "getDefForPart", part, false, true) or 0
    end
    return { bite = bite, scratch = scratch, bullet = bullet }
end

-- Get item texture for swatch
local function getItemTexture(item)
    if not item then return nil end
    local tex = safeGet(item, "getTexture")
    if tex then return tex end
    local icon = safeGet(item, "getIcon")
    if icon then return getTexture("Item_" .. icon .. ".png") end
    return nil
end

-- Count attachments on clothing
local function getAttachCount(item)
    if not item then return 0 end
    local patches = safeGet(item, "getPatchesNumber")
    return patches or 0
end

-- ============================================================================
-- DATA GATHERING (throttled)
-- ============================================================================

function ZeD.EquipmentTab.gatherData(playerObj)
    local character = playerObj

    -- Build empty slot grid from definitions
    local groups = {}
    for gi, gDef in ipairs(EQUIP_GROUPS) do
        local g = { id = gDef.id, label = gDef.label, slots = {} }
        for si, sDef in ipairs(gDef.slots) do
            g.slots[si] = {
                type   = sDef.type,
                label  = sDef.label,
                item   = nil,
                cond   = 0,
                tex    = nil,
                attach = 0,
            }
        end
        groups[gi] = g
    end

    -- Fill slots from worn items — vanilla pattern: getWornItems(), 1-based,
    -- wornItem:getLocation() for the body location string (not getBodyLocation()).
    local wornItems = character:getWornItems()
    if wornItems then
        for i = 1, wornItems:size() do
            local wornItem = wornItems:get(i - 1)
            if wornItem then
                local item = wornItem:getItem()
                local loc  = wornItem:getLocation()
                if item and loc then
                    -- PZ returns "base:tshirt", "base:pants" etc. — strip group prefix
                    local locStr = string.lower(tostring(loc))
                    local colon  = locStr:find(":")
                    if colon then locStr = locStr:sub(colon + 1) end
                    local mapping = LOCATION_TO_SLOT[locStr]
                    if mapping then
                        local slot = groups[mapping.gi].slots[mapping.si]
                        -- Only fill if empty (first item wins — outermost layer)
                        if not slot.item then
                            slot.item   = item
                            slot.cond   = condRatio(item)
                            slot.tex    = getItemTexture(item)
                            slot.attach = getAttachCount(item)
                            slot.prot   = getProtection(item)
                        end
                    end
                end
            end
        end
    end

    -- Special: primary/secondary hand items
    local pri = character:getPrimaryHandItem()
    local sec = character:getSecondaryHandItem()
    for si, sDef in ipairs(EQUIP_GROUPS[5].slots) do
        if sDef.type == "PRI" and pri then
            groups[5].slots[si].item   = pri
            groups[5].slots[si].cond   = condRatio(pri)
            groups[5].slots[si].tex    = getItemTexture(pri)
            groups[5].slots[si].attach = 0
            groups[5].slots[si].prot   = getProtection(pri)
        elseif sDef.type == "SEC" and sec then
            if sec ~= pri then
                groups[5].slots[si].item   = sec
                groups[5].slots[si].cond   = condRatio(sec)
                groups[5].slots[si].tex    = getItemTexture(sec)
                groups[5].slots[si].attach = 0
                groups[5].slots[si].prot   = getProtection(sec)
            end
        end
    end

    return {
        groups   = groups,
        player   = playerObj,
        isFemale = playerObj:isFemale(),
    }
end

-- ============================================================================
-- BODY FIGURE HELPERS
-- ============================================================================

local function _ensureBodyFigure(win)
    if not win._equipBodyFigure then
        local fig = ZeD_BodyFigure:new(0, 0, 100, 100)
        fig:initialise()
        fig:loadTextures()
        win._equipBodyFigure = fig
    end
    return win._equipBodyFigure
end

local function _drawCoverageFigure(panel, win, data, slotType, px, py, pw, ph)
    local fig = _ensureBodyFigure(win)
    if data.isFemale ~= nil then
        fig:setSex(data.isFemale)
    end
    fig:clearColors()
    local T      = ZeD.T
    local active = SLOT_REGIONS[slotType] or {}
    for _, regionName in ipairs(active) do
        fig:setPartColor(regionName, T.accent.r, T.accent.g, T.accent.b, 0.65)
    end
    fig.selectedPart = nil
    fig:drawAt(panel, px, py, pw, ph)
end

-- ============================================================================
-- DEFENSE DASHBOARD — aggregate protection overview (replaces Protection tab)
-- ============================================================================

-- Uses T.rowH via M.drawSectionHeader (shared molecule across all tabs)

local function _ensureDefBodyFigure(win)
    if not win._equipDefBodyFigure then
        local fig = ZeD_BodyFigure:new(0, 0, 100, 100)
        fig:initialise()
        fig:loadTextures()
        win._equipDefBodyFigure = fig
    end
    return win._equipDefBodyFigure
end

local function _drawDefenseFigure(panel, win, protData, px, py, pw, ph)
    local fig = _ensureDefBodyFigure(win)
    if protData.isFemale ~= nil then
        fig:setSex(protData.isFemale)
    end
    fig:clearColors()
    local ALL_PARTS    = ZeD.ProtectionTab.ALL_PARTS
    local PART_TO_FIG  = ZeD.ProtectionTab.PART_TO_FIGURE
    local colorForDef  = ZeD.ProtectionTab.protectionColorForDef
    for _, partStr in ipairs(ALL_PARTS) do
        local def       = protData.partDefense[partStr] or -1
        local color     = colorForDef(def)
        local figureName = PART_TO_FIG[partStr]
        if figureName then
            fig:setPartColor(figureName, color.r, color.g, color.b, 0.65)
        end
    end
    fig.selectedPart = win._equipDefHoveredPart or nil
    fig:drawAt(panel, px, py, pw, ph)
end

local function _measureDefenseDashboard(win, protData, w)
    local T    = ZeD.T
    local headerH = ZeD.Molecules.getTabHeaderH()
    -- Defense body is always shown now (no separate disclosure for it); the
    -- pinned header toggles the equipped INVENTORY list instead.
    local pad    = ZeD.Molecules.getTabPad()
    local figH = T.sp.figureH
    local rightColH = ZeD.ProtectionTab._measureRightColumn(protData)
    -- padTop not included — render's drawY already starts at scrollY + padTop
    local contentH = math.max(figH, rightColH) + pad
    return headerH + contentH
end

-- Hover detail view: shows per-part defense stats (like Thermal tab rollover)
local function _drawDefenseDetailView(panel, win, protData, partName, rx, ry, rw)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules
    local tierColor = ZeD.ProtectionTab.tierColor

    -- Resolve figure display name → PZ part key
    local FIGURE_TO_PART = ZeD.ProtectionTab.FIGURE_TO_PART
    local PART_NAMES     = ZeD.ProtectionTab.PART_NAMES
    local partStr = FIGURE_TO_PART[partName]
    if not partStr then return end

    local ps = protData.partStats[partStr]
    if not ps then return end

    local curY = ry

    -- Defense stat rows with fill bars
    local rowGap = T.sp.sm
    local rows = {
        { label = "Bite",    val = ps.bite },
        { label = "Scratch", val = ps.scratch },
        { label = "Bullet",  val = ps.bullet },
    }

    for _, row in ipairs(rows) do
        local val = math.max(0, row.val)
        local pct = val / 100
        local fc  = tierColor(val)
        local valStr = val .. "%"
        local rowH = M.drawStatBarRow(panel, rx, curY, rw, valStr, row.label, pct, fc)
        curY = curY + rowH + rowGap
    end

    -- Layers count
    curY = curY + T.sp.sm
    local layerStr = ps.layers .. (ps.layers == 1 and " layer" or " layers")
    A.drawSecondary(panel, layerStr, rx, curY)
end

-- Stacked stat helper with status dot: label (secondary) on line 1, dot + value (body, neutral) on line 2
local function _drawStackedStatDot(panel, x, y, label, value, dotColor, dotSz, dotGap)
    local T = ZeD.T
    local A = ZeD.Atoms
    local secH  = getTextManager():getFontHeight(T.fontF1)
    local bodyH = getTextManager():getFontHeight(T.fontF2)
    local labelValueGap = T.sp.xs
    local afterGap      = T.sp.sm

    panel:drawText(string.upper(label), x, y, T.toneLo.r, T.toneLo.g, T.toneLo.b, T.toneLo.a, T.fontF1)
    local valY = y + secH + labelValueGap
    A.drawStatusDot(panel, x, valY + math.floor((bodyH - dotSz) / 2), dotColor, dotSz)
    A.drawBody(panel, value, x + dotSz + dotGap, valY)

    return secH + labelValueGap + bodyH + afterGap
end

-- Stacked stat helper: label (secondary) on line 1, value (body) on line 2
local function _drawStackedStat(panel, x, y, label, value, valueColor)
    local T = ZeD.T
    local A = ZeD.Atoms
    local secH  = getTextManager():getFontHeight(T.fontF1)
    local bodyH = getTextManager():getFontHeight(T.fontF2)
    local labelValueGap = T.sp.xs
    local afterGap      = T.sp.sm

    A.drawSecondary(panel, string.upper(label), x, y)
    A.drawBody(panel, value, x, y + secH + labelValueGap, valueColor)

    return secH + labelValueGap + bodyH + afterGap
end

local function _drawDefenseDashboard(panel, win, protData, x, y, w, bodyOnly)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local M  = ZeD.Molecules
    local tierColor  = ZeD.ProtectionTab.tierColor
    local gradeColor = ZeD.ProtectionTab.gradeColor

    -- Defense body is always shown now (no separate disclosure for it).
    -- The legacy bodyOnly=false call path is unused after the layout switch
    -- but kept defensive in case external callers still hit it.
    local headerH = ZeD.Molecules.getTabHeaderH()

    local pad = ZeD.Molecules.getTabPad()
    if not bodyOnly then
        M.drawSectionHeader(panel, x, y, w, "Defense", nil, true, false, T.fontF4, nil, pad, headerH)
    end

    -- (was: gated on expanded; defense body is always rendered now)

    -- --- Dashboard content ---
    local headH = getTextManager():getFontHeight(T.fontF1)
    local bodyH = getTextManager():getFontHeight(T.fontF2)
    local secH  = getTextManager():getFontHeight(T.fontF1)

    local cw   = w
    local halfW = math.floor(cw / 2)
    local figW = T.sp.figureW
    local figH = T.sp.figureH
    local contentY = y + headerH
    local layout = ZeD.Molecules.layoutZoneA(x, contentY, w, figW, figH)

    -- Left column: body figure
    _drawDefenseFigure(panel, win, protData, layout.figX, layout.figY, figW, figH)

    -- Right column: hover detail OR default stats
    local rightX = layout.rightX
    local rightW = layout.rightW
    local hoveredPart = win._equipDefHoveredPart
    if hoveredPart and ZeD.ProtectionTab.FIGURE_TO_PART[hoveredPart] then
        _drawDefenseDetailView(panel, win, protData, hoveredPart,
            layout.rightX, layout.rightY, layout.rightW)
    else
        local statY = layout.rightY

        -- Letter grade box
        local gradeBoxColor = gradeColor(protData.grade)
        local titleFH = T.fontF4H or getTextManager():getFontHeight(T.fontF4)
        local gradeLetterW = getTextManager():MeasureStringX(T.fontF4, protData.grade)
        local boxH = secH * 2 + T.sp.xs + 8
        local boxW = math.max(gradeLetterW + 12, boxH)
        local boxX = rightX
        local boxY = statY

        A.fillRounded(panel, boxX, boxY, boxW, boxH, gradeBoxColor.r, gradeBoxColor.g, gradeBoxColor.b, 0.15)
        A.borderRounded(panel, boxX, boxY, boxW, boxH, gradeBoxColor.r, gradeBoxColor.g, gradeBoxColor.b, gradeBoxColor.a or 1)

        local gx = boxX + math.floor((boxW - gradeLetterW) / 2)
        local gy = boxY + math.floor((boxH - titleFH) / 2)  -- fontF5 centered in box (tune in-game if needed)
        panel:drawText(protData.grade, gx, gy, T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a, T.fontF4)

        local lblX = boxX + boxW + T.sp.sm
        panel:drawText("OVERALL GRADE", lblX, boxY + 4, T.toneLo.r, T.toneLo.g, T.toneLo.b, T.toneLo.a, T.fontF1)
        local avgStr = protData.avgBiteDef .. "% avg bite defense"
        local avgY = boxY + 4 + secH + T.sp.xs
        local dotSz = 6
        local dotGap = 4
        A.drawStatusDot(panel, lblX, avgY + math.floor((secH - dotSz) / 2), tierColor(protData.avgBiteDef), dotSz)
        panel:drawText(avgStr, lblX + dotSz + dotGap, avgY, T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a, T.fontF3)

        statY = statY + boxH + T.sp.sm

        -- Divider below grade
        A.drawDividerH(panel, rightX, statY, rightW, false)
        statY = statY + 1 + T.sp.afterLine

        -- Stacked stat rows (label on line 1, dot + value on line 2)
        local dotSz = 6
        local dotGap = 4
        local worstValue
        if protData.worstPart.biteDef < 0 then
            worstValue = protData.worstPart.name .. " (uncovered)"
        else
            worstValue = protData.worstPart.name .. " (" .. protData.worstPart.biteDef .. "%)"
        end
        local h1 = _drawStackedStatDot(panel, rightX, statY, "Worst Zone", worstValue, T.danger, dotSz, dotGap)
        statY = statY + h1

        if protData.bestPart.biteDef >= 0 then
            local bestStr = protData.bestPart.name .. " (" .. protData.bestPart.biteDef .. "%)"
            local h2 = _drawStackedStatDot(panel, rightX, statY, "Best Zone", bestStr, tierColor(protData.bestPart.biteDef), dotSz, dotGap)
            statY = statY + h2
        end

        local h3 = _drawStackedStatDot(panel, rightX, statY, "Garments", protData.totalGarments .. " equipped", T.positive, dotSz, dotGap)
        statY = statY + h3
    end

    local rightColH = ZeD.ProtectionTab._measureRightColumn(protData)
    local totalH = math.max(figH, rightColH) + pad * 2
    return headerH + totalH
end

-- ============================================================================
-- LIST MODE: draw group headers + slot rows
-- ============================================================================

local function _drawGroupHeader(panel, win, group, expanded, x, y, w)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = getTextManager()
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local h = GROUP_H
    local hovered = mx >= x and mx < x + w and my >= y and my < y + h
    local padX = T.sp.sm
    local secFH = tm:getFontHeight(T.fontF1)

    -- Count equipped items
    local count = 0
    for _, s in ipairs(group.slots) do
        if s.item then count = count + 1 end
    end

    -- Background (matches inventory catHdrH style)
    local bg = hovered and T.hover or T.surf2
    panel:drawRect(x, y, w, h, hovered and 0.06 or bg.a, bg.r, bg.g, bg.b)

    -- Gamepad focus fill — 0.55 alpha accent over the header when this
    -- group element is the focused ring element in charTabContent.
    if win and win._gpFocusedEquipSlot == ("__group_" .. tostring(group.id)) then
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
        if focWin == win and Focus.getFocusedZone then
            local zone = Focus.getFocusedZone(win)
            if zone and zone.zone == "charTabContent" then
                local ac = T.accent
                panel:drawRect(x, y, w, h, 0.55, ac.r, ac.g, ac.b)
            end
        end
    end

    -- Text: "v CATEGORY (count)" — single draw, inventory dialect
    local labelY = y + math.floor((h - secFH) / 2)
    local tri = expanded and "v " or "> "
    local label = tri .. group.label .. " (" .. count .. ")"
    panel:drawText(label, x + padX + 2, labelY, T.toneLo.r, T.toneLo.g, T.toneLo.b, T.toneLo.a, T.fontF1)

    -- Weak divider (not strong — matches inventory)
    A.drawDividerH(panel, x, y + h - 1, w, false)
end

local function _drawSlotRow(panel, slot, selected, x, y, w, rowIdx, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = getTextManager()
    local empty = not slot.item
    local rowH = T.rowH

    -- Alternating row stripe
    if rowIdx and rowIdx % 2 == 1 then
        local st = T.stripe
        panel:drawRect(x, y, w, rowH, st.a, st.r, st.g, st.b)
    end

    -- Selection highlight (mouse-clicked card-mode)
    if selected then
        local ac = T.accent
        panel:drawRect(x, y, w, rowH, T.selectionA or 0.25, ac.r, ac.g, ac.b)
    end

    -- Gamepad focus fill — 0.55 alpha accent across the row. Gated on live
    -- ring focus being on charTabContent so the cue clears the instant LB/RB
    -- bumpers away (per user design rule: only the currently-focused zone
    -- shows its active item).
    if win and slot.type and win._gpFocusedEquipSlot == slot.type then
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
        if focWin == win and Focus.getFocusedZone then
            local zone = Focus.getFocusedZone(win)
            if zone and zone.zone == "charTabContent" then
                local ac = T.accent
                panel:drawRect(x, y, w, rowH, 0.55, ac.r, ac.g, ac.b)
            end
        end
    end

    -- Column layout: NAME SLOT COND BITE SCR BUL WT
    local c = calcEquipColumns(w, win)

    local bodyFH = tm:getFontHeight(T.fontF2)
    local secFH = tm:getFontHeight(T.fontF1)
    local secTextY = y + math.floor((rowH - secFH) / 2)

    -- Icon
    local iconX = x + c.padX
    local iconY = y + math.floor((rowH - c.iconW) / 2)
    if slot.tex then
        panel:drawTextureScaledAspect(slot.tex, iconX, iconY, c.iconW, c.iconW, 1, 1, 1, 1)
    end

    -- Name
    local textY = y + math.floor((rowH - bodyFH) / 2)
    if empty then
        local dc = selected and T.textOnAccent or (T.textDim or T.textSec)
        panel:drawText("---", x + c.nameX, textY, dc.r, dc.g, dc.b, dc.a or 0.28, T.fontF2)
    else
        local name = safeGet(slot.item, "getDisplayName") or safeGet(slot.item, "getName") or "?"
        local nameColor = selected and T.accent or T.text
        name = A.truncateText(name, T.fontF2, c.nameW)
        panel:drawText(name, x + c.nameX, textY,
            nameColor.r, nameColor.g, nameColor.b, nameColor.a or 1, T.fontF2)
    end

    -- Slot label (truncated to fit column)
    local typeStr = slot.label or slot.type
    local typeColor = selected and T.textOnAccent or T.toneHi
    typeStr = A.truncateText(typeStr, T.fontF1, c.slotColW - c.padX * 2)
    panel:drawText(typeStr, x + c.slotX + c.padX, secTextY,
        typeColor.r, typeColor.g, typeColor.b, typeColor.a or 0.9, T.fontF1)

    -- Condition bar (thin 3px — matches inventory list style)
    if slot.item then
        local condMax = safeGet(slot.item, "getConditionMax") or 0
        if condMax and condMax > 0 then
            local barX = x + c.condX + 2
            local barY = y + math.floor(rowH / 2) - 1
            local barW = c.condColW - 4
            local barH = 3
            local bg = T.surf3
            panel:drawRect(barX, barY, barW, barH, bg.a, bg.r, bg.g, bg.b)
            local fillW = math.max(0, math.floor(barW * slot.cond))
            if fillW > 0 then
                local fc
                if slot.cond > 0.6 then fc = T.positive
                elseif slot.cond > 0.3 then fc = T.warning
                else fc = T.danger end
                panel:drawRect(barX, barY, fillW, barH, fc.a, fc.r, fc.g, fc.b)
            end
        end
    end

    -- Protection columns (bite / scratch / bullet) — colored status dots
    if slot.item and slot.prot then
        local p = slot.prot
        local tierColor = ZeD.ProtectionTab.tierColor
        local dotSz = 6
        local dotY = y + math.floor((rowH - dotSz) / 2)
        local function drawProtDot(val, colX)
            if val > 0 then
                A.drawStatusDot(panel, x + colX + math.floor((c.protColW - dotSz) / 2), dotY, tierColor(val), dotSz)
            end
        end
        drawProtDot(p.bite, c.biteX)
        drawProtDot(p.scratch, c.scrX)
        drawProtDot(p.bullet, c.bulX)
    end

    -- Weight
    if slot.item then
        local wt = safeGet(slot.item, "getUnequippedWeight") or 0
        local wtStr = string.format("%.1f", wt)
        A.drawTextRight(panel, wtStr, x + c.wtX + c.wtColW - c.padX, secTextY)
    end

    -- Bottom divider
    A.drawDividerH(panel, x, y + rowH - 1, w, false)
end

-- ============================================================================
-- COLUMN HEADER BAR — labels above the slot list
-- ============================================================================

local EQUIP_HDR_H = ZeD.T.sp.colHdrH

local function _drawEquipHeader(panel, x, y, w, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = getTextManager()

    -- Background
    local surf2 = T.surf2
    panel:drawRect(x, y, w, EQUIP_HDR_H, surf2.a, surf2.r, surf2.g, surf2.b)

    -- Column layout (shared with _drawSlotRow)
    local cl = calcEquipColumns(w, win)

    local secFH = tm:getFontHeight(T.fontF5)
    local textY = y + math.floor((EQUIP_HDR_H - secFH) / 2)
    local c = T.toneNorm

    -- Center helper
    local function drawCentered(label, colStart, colW)
        local tw = tm:MeasureStringX(T.fontF5, label)
        local tx = x + colStart + math.floor((colW - tw) / 2)
        panel:drawText(label, tx, textY, c.r, c.g, c.b, c.a or 0.92, T.fontF5)
    end

    -- Column order: NAME SLOT COND BITE SCR BUL WT
    panel:drawText("NAME", x + cl.nameX, textY, c.r, c.g, c.b, c.a or 0.92, T.fontF5)
    drawCentered("SLOT", cl.slotX, cl.slotColW)
    drawCentered("COND", cl.condX, cl.condColW)
    drawCentered("BITE", cl.biteX, cl.protColW)
    drawCentered("SCR",  cl.scrX,  cl.protColW)
    drawCentered("BUL",  cl.bulX,  cl.protColW)
    A.drawTextRight(panel, "WT", x + cl.wtX + cl.wtColW - cl.padX, textY, T.fontF5, c)

    -- Divider hit zones for column resize (6px wide, centered on column edge)
    local divZones = {}
    divZones[#divZones + 1] = { col = "slot", x = x + cl.slotX - DIV_W / 2, y = y, w = DIV_W, h = EQUIP_HDR_H }
    divZones[#divZones + 1] = { col = "cond", x = x + cl.condX - DIV_W / 2, y = y, w = DIV_W, h = EQUIP_HDR_H }
    divZones[#divZones + 1] = { col = "wt",   x = x + cl.wtX   - DIV_W / 2, y = y, w = DIV_W, h = EQUIP_HDR_H }
    if win then win._equipDivZones = divZones end

    -- Divider hover feedback (2px accent line)
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local colDrag = win and win._equipColDrag
    if not colDrag then
        for _, dz in ipairs(divZones) do
            if mx >= dz.x and mx < dz.x + dz.w and my >= dz.y and my < dz.y + dz.h then
                local ac = T.accent
                panel:drawRect(dz.x + DIV_W / 2 - 1, y, 2, EQUIP_HDR_H, ac.a, ac.r, ac.g, ac.b)
                break
            end
        end
    end

    -- Active drag feedback (full-height accent line)
    if colDrag then
        local divX
        if colDrag.col == "slot" then divX = x + cl.slotX
        elseif colDrag.col == "cond" then divX = x + cl.condX
        else divX = x + cl.wtX end
        local ac = T.accent
        panel:drawRect(divX - 1, y, 2, panel:getHeight() - y, ac.a, ac.r, ac.g, ac.b)
    end

    A.drawDividerH(panel, x, y + EQUIP_HDR_H - 1, w, true)
end

-- ============================================================================
-- CARD MODE: item inspection with body figure coverage
-- ============================================================================

local function _drawBackBar(panel, win, slot, x, y, w)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local sp = T.sp

    -- Slot layer label (left-aligned, secondary)
    local layerX = x + sp.sm
    local backH = getBackH()
    local layerY = y + 4 + math.floor((T.buttonH - getTextManager():getFontHeight(T.fontF1)) / 2)
    if slot then
        local typeStr = slot.label or slot.type
        A.drawSecondary(panel, typeStr, layerX, layerY, T.textDim)
    end

    -- Back button (outline style, right-aligned): "< ITEM NAME"
    local name = ""
    if slot and slot.item then
        name = safeGet(slot.item, "getDisplayName") or safeGet(slot.item, "getName") or "?"
    end
    local btnLabel = "< " .. string.upper(name)
    -- Truncate to available width (leave room for layer label)
    local layerW = slot and getTextManager():MeasureStringX(T.fontF1, slot.label or slot.type) or 0
    local maxBtnW = w - sp.sm * 3 - layerW
    btnLabel = A.truncateText(btnLabel, T.fontF3, maxBtnW - sp.buttonPadX * 2)
    local btnW = getTextManager():MeasureStringX(T.fontF3, btnLabel) + sp.buttonPadX * 2
    btnW = math.max(btnW, 60)
    local btnX = x + w - sp.sm - btnW
    local btnY = y + 4  -- 4px padding above

    -- Stamp tight button-shaped bounds for the gamepad ring (so cone-nav
    -- centers align with the visible button, not the full header). The
    -- full-width _equipBackZone is kept for mouse hit-testing — clicking
    -- anywhere in the header exits card mode.
    win._equipBackBtnZone = { x = btnX, y = btnY, w = btnW, h = T.buttonH }

    -- Gamepad focus fill — 0.55 alpha accent beneath the back button when
    -- the card back element is the focused ring element. Gated on live ring
    -- focus being on charTabContent.
    if win and win._gpFocusedEquipSlot == "__back" then
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
        if focWin == win and Focus.getFocusedZone then
            local zone = Focus.getFocusedZone(win)
            if zone and zone.zone == "charTabContent" then
                local ac = T.accent
                panel:drawRect(btnX, btnY, btnW, T.buttonH, 0.55, ac.r, ac.g, ac.b)
            end
        end
    end

    M.drawButton(panel, btnX, btnY, btnW, T.buttonH, btnLabel, "default")
end

local function _drawCardContent(panel, win, data, slot, x, y, w, h)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local item = slot.item
    if not item then return y end

    local pad  = T.sp.sm
    local secH = getTextManager():getFontHeight(T.fontF1)
    local cx = x + pad
    local cw = w - pad * 2
    local cy = y + pad

    -- Icon (atom)
    local iconSz = 48
    local iconY  = cy
    if slot.tex then
        A.drawIcon(panel, slot.tex, cx, iconY, iconSz)
    end

    -- Stat rows (right of icon, using M.drawStatRow molecule)
    local statX = cx + iconSz + pad * 2
    local statW = cw - iconSz - pad * 2
    local sy = iconY

    -- Category / kind
    local cat = "Item"
    if instanceof(item, "Clothing") then cat = safeGet(item, "getBodyLocation") or "Clothing"
    elseif instanceof(item, "HandWeapon") then cat = safeGet(item, "getAmmoType") and "Firearm" or "Weapon"
    elseif safeGet(item, "getFluidContainer") then cat = "Fluid"
    else cat = safeGet(item, "getCategory") or "Item" end
    sy = sy + M.drawStatRow(panel, statX, sy, statW, "Kind", tostring(cat))

    -- Weight
    local wt = safeGet(item, "getActualWeight") or safeGet(item, "getWeight") or 0
    sy = sy + M.drawStatRow(panel, statX, sy, statW, "Weight", string.format("%.1f kg", wt))

    -- Fabric type (clothing only)
    if instanceof(item, "Clothing") then
        local fab = safeGet(item, "getFabricType")
        if fab and tostring(fab) ~= "" then
            sy = sy + M.drawStatRow(panel, statX, sy, statW, "Fabric", tostring(fab))
        end
    end

    -- Condition
    local ratio = slot.cond
    local condPct = math.floor(ratio * 100)
    sy = sy + M.drawStatRowDot(panel, statX, sy, statW, "Cond.", condPct .. "%", condColor(ratio))

    cy = math.max(sy, iconY + iconSz) + pad

    -- Full-width condition bar (atom)
    A.drawFillBar(panel, cx, cy, cw, ratio, true)
    cy = cy + T.fillBarH + pad

    -- ================================================================
    -- PROTECTION COVERAGE SECTION
    -- ================================================================
    local regions = SLOT_REGIONS[slot.type] or {}
    if #regions > 0 and instanceof(item, "Clothing") then
        -- Section divider + heading (atoms)
        A.drawDividerH(panel, cx, cy, cw, true)
        cy = cy + 1 + pad
        A.drawSecondary(panel, "PROTECTION", cx, cy)
        cy = cy + secH + pad

        -- Body figure (left, large)
        local figW = 100
        local figH = 140
        local figX = cx
        local figY = cy
        _drawCoverageFigure(panel, win, data, slot.type, figX, figY, figW, figH)

        -- Defense stats (right of figure, using stat row molecule)
        local defX = cx + figW + pad * 2
        local defW = cw - figW - pad * 2
        local defY = figY + pad

        -- Get defense values
        local biteDef    = safeGet(item, "getBiteDefense") or 0
        local scratchDef = safeGet(item, "getScratchDefense") or 0
        local bulletDef  = 0
        local parts = safeGet(item, "getCoveredParts")
        if parts and parts:size() > 0 then
            local part = parts:get(0)
            bulletDef = safeGet(item, "getDefForPart", part, false, true) or 0
        end

        defY = defY + M.drawStatRow(panel, defX, defY, defW, "Bite", math.floor(biteDef) .. "%")
        defY = defY + M.drawStatRow(panel, defX, defY, defW, "Scratch", math.floor(scratchDef) .. "%")
        defY = defY + M.drawStatRow(panel, defX, defY, defW, "Bullet", math.floor(bulletDef) .. "%")

        cy = math.max(figY + figH, defY) + pad
    end

    -- ================================================================
    -- ATTACHMENTS SECTION
    -- ================================================================
    if slot.attach > 0 and instanceof(item, "Clothing") then
        -- Section divider + heading (atoms)
        A.drawDividerH(panel, cx, cy, cw, true)
        cy = cy + 1 + pad
        A.drawSecondary(panel, "ATTACHMENTS", cx, cy)
        cy = cy + secH + pad

        -- List patches
        local patchCount = safeGet(item, "getPatchesNumber") or 0
        if patchCount > 0 then
            local coveredParts = safeGet(item, "getCoveredParts")
            if coveredParts then
                for pi = 0, coveredParts:size() - 1 do
                    local part = coveredParts:get(pi)
                    local patchType = safeGet(item, "getPatchType", part)
                    if patchType and tostring(patchType) ~= "" then
                        local pName = tostring(patchType) .. " patch"
                        A.drawBody(panel, pName, cx + pad, cy)
                        cy = cy + secH + 2
                    end
                end
            end
        end

        cy = cy + pad
    end

    return cy
end

-- ============================================================================
-- ACTION BUTTONS: Drop / Inspect / Unequip
-- ============================================================================

local ACTION_BTNS = {
    { id = "drop",    label = "Drop" },
    { id = "inspect", label = "Inspect" },
    { id = "unequip", label = "Unequip" },
}

local function _drawActionButtons(panel, win, slot, x, y, w)
    local T = ZeD.T
    local pad = T.sp.sm
    local btnH = T.buttonH
    local btnGap = T.sp.xs

    -- Right-align buttons (measure with fontF3 — matches drawButton rendering)
    local totalW = 0
    local widths = {}
    for _, btn in ipairs(ACTION_BTNS) do
        local tw = getTextManager():MeasureStringX(T.fontF3, btn.label) + T.sp.buttonPadX * 2
        tw = math.max(tw, 60)
        widths[#widths + 1] = tw
        totalW = totalW + tw + btnGap
    end
    totalW = totalW - btnGap

    local bx = x + w - pad - totalW
    local by = y

    -- Reset action zones
    win._equipActionZones = win._equipActionZones or {}
    local zi = 0

    local M = ZeD.Molecules
    -- Resolve gp focus state once per draw (not per button)
    local gpFocusedId = nil
    if win._gpFocusedEquipSlot and win._gpFocusedEquipSlot:sub(1, 6) == "__btn_" then
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
        if focWin == win and Focus.getFocusedZone then
            local zone = Focus.getFocusedZone(win)
            if zone and zone.zone == "charTabContent" then
                gpFocusedId = win._gpFocusedEquipSlot:sub(7)  -- strip "__btn_"
            end
        end
    end

    for bi, btn in ipairs(ACTION_BTNS) do
        zi = zi + 1
        local bw = widths[bi]
        local variant = btn.id == "unequip" and "primary" or "default"

        -- Gamepad focus fill beneath this button
        if gpFocusedId == btn.id then
            local ac = T.accent
            panel:drawRect(bx, by, bw, btnH, 0.55, ac.r, ac.g, ac.b)
        end

        M.drawButton(panel, bx, by, bw, btnH, btn.label, variant)

        -- Store zone
        win._equipActionZones[zi] = { x = bx, y = by, w = bw, h = btnH, id = btn.id }
        bx = bx + bw + btnGap
    end

    -- Trim excess zones
    for i = zi + 1, #(win._equipActionZones or {}) do
        win._equipActionZones[i] = nil
    end

    return by + btnH
end

-- ============================================================================
-- ACTION HANDLER
-- ============================================================================

function ZeD.EquipmentTab._handleAction(win, actionId, slot)
    if not slot or not slot.item then return end
    local player = win._playerObj
    if not player then return end

    if actionId == "unequip" then
        if instanceof(slot.item, "Clothing") then
            ISTimedActionQueue.add(ISUnequipAction:new(player, slot.item, 50))
        else
            -- Hand items: just remove from hand
            if player:getPrimaryHandItem() == slot.item then
                player:setPrimaryHandItem(nil)
            end
            if player:getSecondaryHandItem() == slot.item then
                player:setSecondaryHandItem(nil)
            end
        end
        win._equipSelected = nil
        win._equipCache = nil

    elseif actionId == "drop" then
        -- Vanilla drop handles unequip + transfer to ground
        -- dropItem expects playerNum (integer), not playerObj
        local pNum = player:getPlayerNum()
        ISInventoryPaneContextMenu.dropItem(slot.item, pNum)
        win._equipSelected = nil
        win._equipCache = nil

    elseif actionId == "inspect" then
        -- Open standalone inspect window via existing hook
        local card = win._drawerPanel and win._drawerPanel:getChildren()
        -- Switch to item-mode drawer with this item
        win._drawerItem = slot.item
        win._tabUnder = "equip"
        win._drawerMode = "item"
        -- Set the card's item
        if win._drawerPanel then
            local children = win._drawerPanel:getChildren()
            if children then
                for _, child in pairs(children) do
                    if child.setItem and child.mode == "drawer" then
                        child:setItem(slot.item)
                        break
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- RENDERER
-- ============================================================================

function ZeD.EquipmentTab.render(panel, win, x, y, w, h)
    local T   = ZeD.T
    local A   = ZeD.Atoms
    local M   = ZeD.Molecules
    local pad = M.getTabPad()

    -- Throttled data refresh
    win._equipTimer = (win._equipTimer or 0) + 1
    if win._equipTimer >= 15 or not win._equipCache then
        win._equipTimer = 0
        win._equipCache = ZeD.EquipmentTab.gatherData(win._playerObj)
    end
    local data = win._equipCache

    -- Ensure state tables
    win._equipExpanded   = win._equipExpanded or {head = false, torso = false, arms = false, legs = false, held = false}
    win._equipGroupZones = win._equipGroupZones or {}
    win._equipSlotZones  = win._equipSlotZones or {}

    -- ================================================================
    -- CARD MODE — selected slot inspection
    -- ================================================================
    if win._equipSelected then
        -- Find the selected slot data
        local selSlot = nil
        for _, g in ipairs(data.groups) do
            for _, s in ipairs(g.slots) do
                if s.type == win._equipSelected then
                    selSlot = s
                    break
                end
            end
            if selSlot then break end
        end

        -- If selected item was unequipped externally, revert to list mode
        if not selSlot or not selSlot.item then
            win._equipSelected = nil
        else
            -- Back bar
            local backH = getBackH()
            win._equipBackZone = { x = x, y = y, w = w, h = backH }
            _drawBackBar(panel, win, selSlot, x, y, w)
            local contentY = y + backH

            -- Scrollable card content
            local scroll = win._equipScroll
            local availH = h - backH

            -- Measure card content height (approximate — draw to measure)
            -- We draw inside stencil with scroll offset
            local btnAreaH = T.buttonH + pad * 2  -- action buttons + padding

            -- Scroll setup
            panel:setStencilRect(x, contentY, w, availH)

            local scrollOff = 0
            if scroll.visible then
                scrollOff = math.floor(scroll.scrollPos * math.max(0, win._equipCardH - availH))
            end
            local drawY = contentY - scrollOff

            -- Draw card content
            local endY = _drawCardContent(panel, win, data, selSlot, x, drawY, w, availH)

            -- Action buttons
            endY = endY + pad
            local btnEndY = _drawActionButtons(panel, win, selSlot, x, endY, w)
            endY = btnEndY + pad

            -- Total content height
            local totalH = endY - drawY
            win._equipCardH = totalH

            -- Update scroll
            local needsScroll = totalH > availH
            scroll.visible = needsScroll
            if needsScroll then
                local scrollW = T.sp.scrollbarW
                scroll.x = x + w - scrollW
                scroll.y = contentY
                scroll.height = availH
                scroll:setBarSize(availH / totalH)
            else
                scroll:setScrollPos(0)
            end

            panel:clearStencilRect()

            if scroll.visible then
                scroll:draw(panel)
            end

            return  -- card mode rendered, done
        end
    end

    -- ================================================================
    -- LIST MODE — grouped slot list
    -- ================================================================
    local scroll = win._equipScroll

    -- Throttled protection data refresh
    win._equipProtTimer = (win._equipProtTimer or 0) + 1
    if win._equipProtTimer >= 15 or not win._equipProtCache then
        win._equipProtTimer = 0
        win._equipProtCache = ZeD.ProtectionTab.gatherData(win._playerObj)
    end
    local protData = win._equipProtCache

    -- Ensure list-expanded state — pinned "Equipped" header toggles slot
    -- list visibility; defense body is always shown at the bottom.
    if win._equipListExpanded == nil then win._equipListExpanded = true end

    -- Pinned header: standard ZeD drawer-header strip (T.sp.tabHeaderH).
    -- Column headers (20px) always in scroll area
    local headerH = T.sp.tabHeaderH or 37
    local listExpanded = win._equipListExpanded

    -- Measure scrollable content
    local defDashH = _measureDefenseDashboard(win, protData, w)
    -- Defense body always visible; subtract the molecule's headerH that
    -- _measureDefenseDashboard reserves for its own pinned header (we're
    -- not using a pinned header for defense any more).
    local defBodyH = math.max(0, defDashH - headerH)
    local slotRowH = T.rowH
    local groupHeaderH_pre = GROUP_H
    local padTop = ZeD.Molecules.getTabPadTop()
    local hasDefBody = defBodyH > 0
    -- Layout: equipped inventory list first (collapsible), defense body below
    -- (always visible). T.sp.figurePadTop is the canonical gap above body
    -- figures across Health/Protection/Thermal — using it here keeps spacing
    -- consistent with the rest of the mod.
    local figureGap = T.sp.figurePadTop or 12
    local totalH = 0
    if listExpanded then
        totalH = totalH + EQUIP_HDR_H
        for gi, g in ipairs(data.groups) do
            totalH = totalH + groupHeaderH_pre
            if win._equipExpanded[g.id] then
                totalH = totalH + #g.slots * slotRowH
            else
                for _, s in ipairs(g.slots) do
                    if s.item then totalH = totalH + slotRowH end
                end
            end
        end
    end
    if hasDefBody then
        if listExpanded then totalH = totalH + figureGap end
        totalH = totalH + defBodyH
    end

    -- Scroll setup — scrollbar starts below pinned header
    local scrollY = y + headerH
    local scrollH = h - headerH
    local needsScroll = totalH > scrollH
    scroll.visible = needsScroll
    local scrollW = T.sp.scrollbarW
    local contentW = needsScroll and (w - scrollW) or w
    if needsScroll then
        scroll.x = x + w - scrollW
        scroll.y = scrollY
        scroll.height = scrollH
        scroll:setBarSize(scrollH / math.max(1, totalH))
    else
        scroll:setScrollPos(0)
    end

    -- S100: gamepad scroll-follow — ensure the currently focused equip slot
    -- is within the viewport before computing scrollOff. Reads last frame's
    -- stamped absolute Y from _equipSlotYMap (populated inside the slot loop
    -- below). One-frame lag is imperceptible; matches InventoryRenderer's
    -- pattern. Disclosure is in the pinned header (always visible), so skip.
    if needsScroll
       and win._gpFocusedEquipSlot
       and win._gpFocusedEquipSlot ~= "__disclosure" then
        local yMap = win._equipSlotYMap
        local focAbsY = yMap and yMap[win._gpFocusedEquipSlot]
        if focAbsY then
            local span   = math.max(1, totalH - scrollH)
            local oldOff = math.floor(scroll.scrollPos * span)
            local logicalY = focAbsY - scrollY + oldOff
            if logicalY < oldOff then
                scroll:setScrollPos(logicalY / span)
            elseif logicalY + T.rowH > oldOff + scrollH then
                scroll:setScrollPos((logicalY + T.rowH - scrollH) / span)
            end
        end
    end
    -- Fresh map for this frame's stamps (cleared each frame so stale rows don't linger)
    win._equipSlotYMap = {}

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * math.max(0, totalH - scrollH))
    end

    -- Scrollable content (stencil below pinned header)
    panel:setStencilRect(x, scrollY, contentW, scrollH)
    local drawY = scrollY - scrollOff

    -- Zone arrays — reset indices
    local gzi = 0
    local szi = 0

    if listExpanded then
        -- Column headers FIRST — equipped inventory list is the most-accessed
        -- region of this drawer.
        _drawEquipHeader(panel, x, drawY, contentW, win)
        drawY = drawY + EQUIP_HDR_H

        for gi, g in ipairs(data.groups) do
            local expanded = win._equipExpanded[g.id]
            -- Group header
            _drawGroupHeader(panel, win, g, expanded, x, drawY, contentW)

            -- Store group zone + stamp Y for scroll-follow (keyed by group focus id)
            gzi = gzi + 1
            win._equipGroupZones[gzi] = { x = x, y = drawY, w = contentW, h = GROUP_H, id = g.id }
            win._equipSlotYMap["__group_" .. tostring(g.id)] = drawY
            drawY = drawY + GROUP_H

            -- Slot rows:
            -- Expanded: show all slots
            -- Collapsed: show only slots with equipped items (hide empty)
            for si, s in ipairs(g.slots) do
                local showSlot = expanded or (s.item ~= nil)
                if showSlot then
                    local isSelected = win._equipSelected == s.type
                    _drawSlotRow(panel, s, isSelected, x, drawY, contentW, si, win)

                    -- Store slot zone + stamp Y for gamepad scroll-follow (only if item present)
                    if s.item then
                        szi = szi + 1
                        win._equipSlotZones[szi] = { x = x, y = drawY, w = contentW, h = T.rowH, type = s.type, item = s.item }
                        win._equipSlotYMap[s.type] = drawY
                    end
                    drawY = drawY + T.rowH
                end
            end
        end
    end

    -- Defense body (figure + stats) — always shown at the bottom of the tab,
    -- regardless of inventory list expansion. figureGap (T.sp.figurePadTop,
    -- the canonical figure-top padding) sits between the list and the body.
    if hasDefBody then
        if listExpanded then drawY = drawY + figureGap end
        _drawDefenseDashboard(panel, win, protData, x, drawY - headerH, contentW, true)
        -- S105 gamepad: stamp body figure part Y values into yMap so scroll-
        -- follow can bring focused parts into viewport. drawAt sets the
        -- figure's internal drawAtS/X/Y, so getPartRects returns correct
        -- screen-relative coords here.
        local fig = win._equipDefBodyFigure
        if fig and fig.getPartRects then
            for _, r in ipairs(fig:getPartRects()) do
                win._equipSlotYMap["__part_" .. tostring(r.name)] = r.y
            end
        end
        drawY = drawY + defBodyH
    end

    -- Trim excess zones
    for i = gzi + 1, #win._equipGroupZones do win._equipGroupZones[i] = nil end
    for i = szi + 1, #win._equipSlotZones  do win._equipSlotZones[i]  = nil end

    panel:clearStencilRect()

    -- Gamepad focus fill — 0.55 alpha accent across the header. Gated on
    -- live ring focus so the cue clears when LB/RB bumpers away.
    if win._gpFocusedEquipSlot == "__disclosure" then
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
        if focWin == win and Focus.getFocusedZone then
            local zone = Focus.getFocusedZone(win)
            if zone and zone.zone == "charTabContent" then
                local ac = T.accent
                panel:drawRect(x, y, w, headerH, 0.55, ac.r, ac.g, ac.b)
            end
        end
    end

    -- Pinned header — labeled "Equipped" since it now toggles the inventory
    -- list visibility. Defense body is always shown at the bottom of the tab.
    ZeD.Molecules.drawTabHeader(panel, x, y, w, "Equipped", listExpanded)
    -- Zone field name kept (_equipDefenseZone) for backward compat with the
    -- existing CharacterWindow click + gamepad routing; the field now points
    -- at the "Equipped" disclosure but the zone semantics are unchanged.
    win._equipDefenseZone = { x = x, y = y, w = w, h = headerH }

    if scroll.visible then
        scroll:draw(panel)
    end
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

-- Expose helpers for ZeD_CharacterWindow column drag
ZeD.EquipmentTab.getDefaultColWidths = getDefaultColWidths
ZeD.EquipmentTab.getLabelColW = getLabelColW

function ZeD.EquipmentTab.register(dispatchTable)
    dispatchTable["equip"] = ZeD.EquipmentTab.render
end
