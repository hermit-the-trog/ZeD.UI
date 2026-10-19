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
require "ZeD/EquipDoll"

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
-- LAYOUT CONSTANTS
-- ============================================================================

local GROUP_H    = 15  -- group header height (matches T.sp.catHdrH)
local COND_BAR_W = 80  -- condition bar width
local PROT_COL_W = 32  -- protection stat column width

-- Pre-computed label column width (widest label across all slots, measured lazily)
local _labelColW = nil
local _labelColWScale = nil  -- S124 scale: re-measure when T.scale (root x text size) changes
local function getLabelColW()
    if _labelColW and _labelColWScale == ZeD.T.scale then return _labelColW end
    local tm = ZeD.TM
    local T = ZeD.T
    local maxW = 0
    for _, group in ipairs(EQUIP_GROUPS) do
        for _, slot in ipairs(group.slots) do
            -- measured in F1, the font the SLOT column draws in (it was measured
            -- in the narrower F5, so every label cut to "I..." even at Small)
            local w = tm:MeasureStringX(T.fontF1, slot.label or slot.type)
            if w > maxW then maxW = w end
        end
    end
    _labelColW = math.ceil(maxW + T.sp.sm * 2)   -- the row draws it inset by padX either side
    _labelColWScale = T.scale
    return _labelColW
end

-- Default resizable column widths (matches inventory renderer pattern)
local DIV_W = 6  -- divider hit zone width
local function getDefaultColWidths(scale)
    local T = ZeD.T
    return {
        slot = getLabelColW() + T.px(4),
        cond = T.px(COND_BAR_W) + T.px(4),
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
    local iconW = rowH - T.px(8)
    local iconGap = sp.iconGap or T.px(6)

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
    if nameW < T.px(40) then nameW = T.px(40) end

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
-- DEFENSE DASHBOARD — aggregate protection overview (replaces Protection tab)
-- ============================================================================

-- Uses T.rowH via M.drawSectionHeader (shared molecule across all tabs)

local function _ensureDefBodyFigure(win)
    local T = ZeD.T
    if not win._equipDefBodyFigure then
        local fig = ZeD_BodyFigure:new(0, 0, T.px(100), T.px(100))
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
    local secH  = ZeD.TM:getFontHeight(T.fontF1)
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)
    local labelValueGap = T.sp.xs
    local afterGap      = T.sp.sm

    panel:drawText(string.upper(label), x, y, T.toneLo.r, T.toneLo.g, T.toneLo.b, T.toneLo.a, T.fontF1)
    local valY = y + secH + labelValueGap
    A.drawStatusDot(panel, x, valY + math.floor((bodyH - dotSz) / 2), dotColor, dotSz)
    A.drawBody(panel, value, x + dotSz + dotGap, valY)

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
    local secH  = ZeD.TM:getFontHeight(T.fontF1)

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
        local titleFH = T.fontF4H or ZeD.TM:getFontHeight(T.fontF4)
        local gradeLetterW = ZeD.TM:MeasureStringX(T.fontF4, protData.grade)
        local boxH = secH * 2 + T.sp.xs + T.px(8)
        local boxW = math.max(gradeLetterW + T.px(12), boxH)
        local boxX = rightX
        local boxY = statY

        A.fillRounded(panel, boxX, boxY, boxW, boxH, gradeBoxColor.r, gradeBoxColor.g, gradeBoxColor.b, 0.15)
        A.borderRounded(panel, boxX, boxY, boxW, boxH, gradeBoxColor.r, gradeBoxColor.g, gradeBoxColor.b, gradeBoxColor.a or 1)

        local gx = boxX + math.floor((boxW - gradeLetterW) / 2)
        local gy = boxY + math.floor((boxH - titleFH) / 2)  -- fontF5 centered in box (tune in-game if needed)
        panel:drawText(protData.grade, gx, gy, T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a, T.fontF4)

        local lblX = boxX + boxW + T.sp.sm
        panel:drawText("OVERALL GRADE", lblX, boxY + T.px(4), T.toneLo.r, T.toneLo.g, T.toneLo.b, T.toneLo.a, T.fontF1)
        local avgStr = protData.avgBiteDef .. "% avg bite defense"
        local avgY = boxY + T.px(4) + secH + T.sp.xs
        local dotSz = T.px(6)
        local dotGap = T.px(4)
        A.drawStatusDot(panel, lblX, avgY + math.floor((secH - dotSz) / 2), tierColor(protData.avgBiteDef), dotSz)
        panel:drawText(avgStr, lblX + dotSz + dotGap, avgY, T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a, T.fontF3)

        statY = statY + boxH + T.sp.sm

        -- Divider below grade
        A.drawDividerH(panel, rightX, statY, rightW, false)
        statY = statY + T.px(1) + T.sp.afterLine

        -- Stacked stat rows (label on line 1, dot + value on line 2)
        local dotSz = T.px(6)
        local dotGap = T.px(4)
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
    local tm = ZeD.TM
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local h = T.px(GROUP_H)
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
    panel:drawText(label, x + padX + T.px(2), labelY, T.toneLo.r, T.toneLo.g, T.toneLo.b, T.toneLo.a, T.fontF1)

    -- Weak divider (not strong — matches inventory)
    A.drawDividerH(panel, x, y + h - T.px(1), w, false)
end

local function _drawSlotRow(panel, slot, selected, x, y, w, rowIdx, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
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
            local barX = x + c.condX + T.px(2)
            local barY = y + math.floor(rowH / 2) - T.px(1)
            local barW = c.condColW - T.px(4)
            local barH = T.px(3)
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
        local dotSz = T.px(6)
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
    A.drawDividerH(panel, x, y + rowH - T.px(1), w, false)
end

-- ============================================================================
-- THE BELT (HOOK_MAP rows 5 + 6) — the hotbar's slots under HELD + BELT
-- A sub-header ("THE BELT | KEYS", "SLOT | WHAT GIVES IT"), then one row per
-- slot in key order: the key in an accent badge, the item's icon, its name
-- (or "Empty") over the slot's name and the worn item that gives the slot,
-- the condition bar in the COND column, then IN HAND and the verb (DETACH,
-- PUT BACK or ATTACH) at the right edge. Zones in win._equipBeltZones
-- (CharacterWindow routes clicks; ATTACH opens the slot's list, as holding
-- the slot's key does).
-- ============================================================================
-- the slots shown: all of them while HELD + BELT is open, the filled ones
-- while it is folded (as the group's own rows do)
local function _beltSlots(win, expanded)
    local B = ZeD.Belt
    if not (B and B.slots) then return {} end
    local ok, slots = pcall(B.slots, win.playerNum or 0)
    if not ok or not slots then return {} end
    if expanded then return slots end
    local out = {}
    for _, s in ipairs(slots) do if s.item then out[#out + 1] = s end end
    return out
end

-- two lines: the item over the slot
local function _beltRowH()
    local T, tm = ZeD.T, ZeD.TM
    return math.floor(math.max(T.rowH, tm:getFontHeight(T.fontF2) + tm:getFontHeight(T.fontF1) + T.px(8)))
end

-- an accent outlined tag (IN HAND), as the inventory lists' BELT n
local function _beltTag(panel, text, x, y)
    local T, tm = ZeD.T, ZeD.TM
    local tf = T.fontF1
    local tw = tm:MeasureStringX(tf, text) + T.px(8)
    local th = tm:getFontHeight(tf) + T.px(2)
    local ac = T.accent
    panel:drawRectBorder(x, y, tw, th, ac.a or 1, ac.r, ac.g, ac.b)
    panel:drawText(text, x + T.px(4), y + T.px(1), ac.r, ac.g, ac.b, ac.a or 1, tf)
    return tw, th
end

local function _drawBeltRows(panel, win, slots, x, y, w, zones)
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    local B = ZeD.Belt
    local c = calcEquipColumns(w, win)
    local DOT = " | "   -- the separator: ZeD OS's pipe (director, Oct 16 2026: no middle dots)
    local f1, f2 = T.fontF1, T.fontF2
    local f1h, f2h = tm:getFontHeight(f1), tm:getFontHeight(f2)
    -- sub-header, in the group headers' strip and type
    local hh = T.px(GROUP_H)
    local s2 = T.surf2
    panel:drawRect(x, y, w, hh, s2.a or 1, s2.r, s2.g, s2.b)
    local lo = T.toneLo
    local hy = y + math.floor((hh - f1h) / 2)
    panel:drawText("THE BELT" .. DOT .. "KEYS", x + c.padX + T.px(2), hy, lo.r, lo.g, lo.b, lo.a or 1, f1)
    local cap = "SLOT" .. DOT .. "WHAT GIVES IT"
    panel:drawText(cap, x + w - c.padX - tm:MeasureStringX(f1, cap), hy, lo.r, lo.g, lo.b, lo.a or 1, f1)
    A.drawDividerH(panel, x, y + hh - T.px(1), w, false)
    y = y + hh

    local rowH = _beltRowH()
    local player = win._playerObj
    local keyW = math.max(tm:MeasureStringX(f1, "0") + T.px(8), f1h + T.px(4))
    local keyH = f1h + T.px(4)
    for ri, s in ipairs(slots) do
        if ri % 2 == 1 then local st = T.stripe; panel:drawRect(x, y, w, rowH, st.a, st.r, st.g, st.b) end
        local fid = "belt:" .. tostring(s.i)
        if win._gpFocusedEquipSlot == fid then
            local Focus = ZeD.Input and ZeD.Input.Focus
            local focWin = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
            local zone = focWin == win and Focus.getFocusedZone and Focus.getFocusedZone(win)
            if zone and zone.zone == "charTabContent" then
                local ac = T.accent
                panel:drawRect(x, y, w, rowH, 0.55, ac.r, ac.g, ac.b)
            end
        end
        -- the key (an outlined "-" past the eighth slot, which has none)
        local kx = x + c.padX
        local ky = y + math.floor((rowH - keyH) / 2)
        local kt = s.key or "-"
        local ktx = kx + math.floor((keyW - tm:MeasureStringX(f1, kt)) / 2)
        if s.key then
            local ac = T.accent
            panel:drawRect(kx, ky, keyW, keyH, ac.a or 1, ac.r, ac.g, ac.b)
            local tc = T.textOnAccent
            panel:drawText(kt, ktx, ky + T.px(2), tc.r, tc.g, tc.b, 1, f1)
        else
            local dc = T.textDim
            panel:drawRectBorder(kx, ky, keyW, keyH, dc.a or 1, dc.r, dc.g, dc.b)
            panel:drawText(kt, ktx, ky + T.px(2), dc.r, dc.g, dc.b, dc.a or 1, f1)
        end
        -- the icon
        local iconX = kx + keyW + T.px(6)
        local iconY = y + math.floor((rowH - c.iconW) / 2)
        if s.item then
            local tex = safeGet(s.item, "getTex")
            if tex then panel:drawTextureScaledAspect(tex, iconX, iconY, c.iconW, c.iconW, 1, 1, 1, 1) end
        end
        -- the verb at the right edge, IN HAND before it
        local action, label
        if s.item and s.inHand then action, label = "putback", "PUT BACK"
        elseif s.item then action, label = "detach", "DETACH"
        else action, label = "attach", "ATTACH" end
        local bh = math.min(rowH - T.px(6), T.buttonH or T.px(20))
        local bw = tm:MeasureStringX(T.fontF3, label) + T.px(16)
        local bx = x + w - c.padX - bw
        local by = y + math.floor((rowH - bh) / 2)
        local rightEdge = bx
        if s.inHand then rightEdge = bx - T.px(6) - (tm:MeasureStringX(f1, "IN HAND") + T.px(8)) end
        -- the item over the slot and what gives it: the name stops at the
        -- COND column (its bar sits beside it), the slot line runs under both
        local tx = iconX + c.iconW + c.iconGap
        local textW = x + c.condX - T.px(6) - tx
        local subW = rightEdge - T.px(8) - tx
        local ty = y + math.floor((rowH - f2h - f1h - T.px(2)) / 2)
        if s.item then
            local tc = T.text
            panel:drawText(A.truncateText(safeGet(s.item, "getDisplayName") or "?", f2, textW), tx, ty, tc.r, tc.g, tc.b, tc.a or 1, f2)
        else
            local dc = T.textDim
            panel:drawText("Empty", tx, ty, dc.r, dc.g, dc.b, dc.a or 1, f2)
        end
        local prov = B.provider(player, s.slot.slotType)
        local from = prov and ("FROM THE " .. string.upper(safeGet(prov, "getDisplayName") or "")) or "ALWAYS THERE"
        local sub = string.upper(B.slotName(s.slot)) .. DOT .. from
        local th = T.toneHi
        panel:drawText(A.truncateText(sub, f1, subW), tx, ty + f2h + T.px(2), th.r, th.g, th.b, th.a or 0.9, f1)
        -- condition, in the COND column level with the name
        local f = s.item and B.cond(s.item)
        if f then
            local barX, barY, barW, barH = x + c.condX + T.px(2), ty + math.floor(f2h / 2) - T.px(1), c.condColW - T.px(4), T.px(3)
            local bg = T.surf3
            panel:drawRect(barX, barY, barW, barH, bg.a, bg.r, bg.g, bg.b)
            local fw = math.floor(barW * f)
            if fw > 0 then
                local fc = (f > 0.6 and T.positive) or (f > 0.3 and T.warning) or T.danger
                panel:drawRect(barX, barY, fw, barH, fc.a or 1, fc.r, fc.g, fc.b)
            end
        end
        ZeD.Molecules.drawButton(panel, bx, by, bw, bh, label, action == "attach" and "primary" or "default")
        if s.inHand then
            local tagW = tm:MeasureStringX(f1, "IN HAND") + T.px(8)
            _beltTag(panel, "IN HAND", bx - T.px(6) - tagW, y + math.floor((rowH - f1h - T.px(2)) / 2))
        end
        zones[#zones + 1] = { x = x, y = y, w = w, h = rowH, i = s.i, item = s.item, action = action,
                              btn = { x = bx, y = by, w = bw, h = bh }, fid = fid }
        win._equipSlotYMap[fid] = y
        A.drawDividerH(panel, x, y + rowH - T.px(1), w, false)
        y = y + rowH
    end
    return y
end

-- Run a belt row's verb (mouse and controller)
function ZeD.EquipmentTab.beltAction(win, zone, absX, absY)
    local B = ZeD.Belt
    if not (B and zone) then return end
    local pn = win.playerNum or 0
    if zone.action == "detach" and zone.item then B.detach(pn, zone.item)
    elseif zone.action == "putback" then B.activate(pn, zone.i)
    elseif zone.action == "attach" then B.slotMenu(pn, zone.i, absX or getMouseX(), absY or getMouseY()) end
end

-- ============================================================================
-- COLUMN HEADER BAR — labels above the slot list
-- ============================================================================

local EQUIP_HDR_H = (ZeD.Spacing and ZeD.Spacing.colHdrH) or 20  -- S124 scale: design units (was ZeD.T.sp.colHdrH cached at load); uses go through T.px

local function _drawEquipHeader(panel, x, y, w, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM

    -- Background
    local surf2 = T.surf2
    panel:drawRect(x, y, w, T.px(EQUIP_HDR_H), surf2.a, surf2.r, surf2.g, surf2.b)

    -- Column layout (shared with _drawSlotRow)
    local cl = calcEquipColumns(w, win)

    local secFH = tm:getFontHeight(T.fontF5)
    local textY = y + math.floor((T.px(EQUIP_HDR_H) - secFH) / 2)
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
    divZones[#divZones + 1] = { col = "slot", x = x + cl.slotX - T.px(DIV_W) / 2, y = y, w = T.px(DIV_W), h = T.px(EQUIP_HDR_H) }
    divZones[#divZones + 1] = { col = "cond", x = x + cl.condX - T.px(DIV_W) / 2, y = y, w = T.px(DIV_W), h = T.px(EQUIP_HDR_H) }
    divZones[#divZones + 1] = { col = "wt",   x = x + cl.wtX   - T.px(DIV_W) / 2, y = y, w = T.px(DIV_W), h = T.px(EQUIP_HDR_H) }
    if win then win._equipDivZones = divZones end

    -- Divider hover feedback (2px accent line)
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local colDrag = win and win._equipColDrag
    if not colDrag then
        for _, dz in ipairs(divZones) do
            if mx >= dz.x and mx < dz.x + dz.w and my >= dz.y and my < dz.y + dz.h then
                local ac = T.accent
                panel:drawRect(dz.x + T.px(DIV_W) / 2 - T.px(1), y, T.px(2), T.px(EQUIP_HDR_H), ac.a, ac.r, ac.g, ac.b)
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
        panel:drawRect(divX - T.px(1), y, T.px(2), panel:getHeight() - y, ac.a, ac.r, ac.g, ac.b)
    end

    A.drawDividerH(panel, x, y + T.px(EQUIP_HDR_H) - T.px(1), w, true)
end

-- ============================================================================
-- ACTION HANDLER
-- Action buttons (Drop / Unequip) are rendered inline in the back-bar header
-- by _drawBackBar — no separate action strip below the card content.
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

    end
end

-- ============================================================================
-- RENDERER
-- ============================================================================

function ZeD.EquipmentTab.render(panel, win, x, y, w, h)
    local T   = ZeD.T

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
    -- a new selection starts at its outermost layer
    if win._equipSelected ~= win._equipSelPrev then
        win._equipSelPrev = win._equipSelected
        win._equipLayer = 1
    end
    win._equipLayerZones = nil
    win._equipDollEmpty = nil
    win._equipDollShown = false   -- the doll's model + line layer follow this (CharacterWindow)
    win._equipViewZones = nil
    if win._equipSelected then
        -- Find the selected slot data: a doll slot (its layers), or a list row
        local selSlot = nil
        local layerIdx, layerN = 1, 1
        local Doll = ZeD.EquipDoll
        if Doll.isDollKey(win._equipSelected) then
            local item
            item, layerIdx, layerN = Doll.selection(win)
            if item then selSlot = { item = item } end
        else
            for _, g in ipairs(data.groups) do
                for _, s in ipairs(g.slots) do
                    if s.type == win._equipSelected then
                        selSlot = s
                        break
                    end
                end
                if selSlot then break end
            end
        end

        -- If selected item was unequipped externally, revert to list mode
        if not selSlot or not selSlot.item then
            win._equipSelected = nil
        else
            -- S121 (Phase C1): card mode now delegates to a ZeD_ItemCard child
            -- — the same organism the inv drawer uses. Equipment tab keeps an
            -- own card instance separate from win._itemCard since they render
            -- at different surfaces. Back-arrow click clears _equipSelected.
            local card = panel._equipCard
            if not card then
                card = ZeD_ItemCard:new(x, y, w, h, "drawer", win.playerNum or 0)
                card:initialise()
                panel:addChild(card)
                panel._equipCard = card
                card.onBackClick = function(self)
                    win._equipSelected = nil
                end
                card._gpZone = "charTabContent"   -- its controller cue shows when the tab's zone has focus
            end
            -- A doll slot with layers: the layer strip under the card
            local cardH = h
            if (layerN or 1) > 1 then
                cardH = h - Doll.layerStripH()
                Doll.drawLayerStrip(panel, win, x, y + cardH, w, layerIdx, layerN, panel:getMouseX(), panel:getMouseY())
            end
            -- Per-frame sync: bounds, item, source context
            card:setX(x)
            card:setY(y)
            card:setWidth(w)
            card:setHeight(cardH)
            card._fillH = (cardH ~= h) and cardH or nil
            if card.item ~= selSlot.item then card:setItem(selSlot.item) end
            card.sourceContext = "equipped"
            card:setVisible(true)
            -- Card draws via natural ISPanel child render lifecycle (after
            -- this function returns). Skip the legacy _drawBackBar +
            -- _drawCardContent + scrollbar — the card handles all of that.
            return
        end
    end

    -- Hide the equip card when not in card mode (so it doesn't ghost-render
    -- over list mode). Lazy hide — instance lives across mode swaps.
    if panel._equipCard then panel._equipCard:setVisible(false) end

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
    local headerH = T.sp.tabHeaderH or T.px(37)
    local listExpanded = win._equipListExpanded

    -- Measure scrollable content
    local defDashH = _measureDefenseDashboard(win, protData, w)
    -- Defense body always visible; subtract the molecule's headerH that
    -- _measureDefenseDashboard reserves for its own pinned header (we're
    -- not using a pinned header for defense any more).
    local defBodyH = math.max(0, defDashH - headerH)
    local slotRowH = T.rowH
    local groupHeaderH_pre = T.px(GROUP_H)
    local hasDefBody = defBodyH > 0
    -- Layout: equipped inventory list first (collapsible), defense body below
    -- (always visible). T.sp.figurePadTop is the canonical gap above body
    -- figures across Health/Protection/Thermal — using it here keeps spacing
    -- consistent with the rest of the mod.
    local figureGap = T.sp.figurePadTop or T.px(12)
    local totalH = 0
    local Doll = ZeD.EquipDoll
    local dollView = listExpanded and Doll.view() == "doll"
    -- the doll fits the viewport before any scrollbar; measured from last frame's data
    local dollH = 0
    if dollView then
        if not win._equipDollData then win._equipDollData = Doll.gather(win._playerObj, win.playerNum or 0) end
        dollH = Doll.measure(win, w - T.sp.scrollbarW, h - headerH)
        totalH = totalH + dollH
    elseif listExpanded then
        totalH = totalH + T.px(EQUIP_HDR_H)
        for gi, g in ipairs(data.groups) do
            totalH = totalH + groupHeaderH_pre
            if g.id == "held" then totalH = totalH + groupHeaderH_pre + #_beltSlots(win, win._equipExpanded[g.id]) * _beltRowH() end
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
    local beltZones = {}

    if dollView then
        -- the doll in place of the list (EquipDoll.lua); it stamps the slot,
        -- belt and photo zones itself
        win._equipGroupZones = {}
        local dh = Doll.draw(panel, win, x, drawY, w - T.sp.scrollbarW, h - headerH, panel:getMouseX(), panel:getMouseY())
        szi = #win._equipSlotZones
        beltZones = win._equipBeltZones or {}
        win._equipDollShown = true
        win._equipDollClip = { x = x, y = scrollY, w = contentW, h = scrollH }
        win._equipDollPanel = panel
        drawY = drawY + dh
    elseif listExpanded then
        -- Column headers FIRST — equipped inventory list is the most-accessed
        -- region of this drawer.
        _drawEquipHeader(panel, x, drawY, contentW, win)
        drawY = drawY + T.px(EQUIP_HDR_H)

        for gi, g in ipairs(data.groups) do
            local expanded = win._equipExpanded[g.id]
            -- Group header
            _drawGroupHeader(panel, win, g, expanded, x, drawY, contentW)

            -- Store group zone + stamp Y for scroll-follow (keyed by group focus id)
            gzi = gzi + 1
            win._equipGroupZones[gzi] = { x = x, y = drawY, w = contentW, h = T.px(GROUP_H), id = g.id }
            win._equipSlotYMap["__group_" .. tostring(g.id)] = drawY
            drawY = drawY + T.px(GROUP_H)

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
            if g.id == "held" then
                drawY = _drawBeltRows(panel, win, _beltSlots(win, expanded), x, drawY, contentW, beltZones)
            end
        end
    end
    win._equipBeltZones = beltZones

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
    -- List | Doll, at the heading's right edge
    Doll.drawToggle(panel, win, x, y, w, headerH, panel:getMouseX(), panel:getMouseY())
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
    -- looked up at draw time, so a hot reload of this file takes effect
    dispatchTable["equip"] = function(...) return ZeD.EquipmentTab.render(...) end
end
