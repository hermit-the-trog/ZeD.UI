-- ZeD-UI/42/media/lua/client/ZeD/ThermalTab.lua
-- ============================================================================
-- THERMAL TAB — per-body-part thermoregulation data with 7 switchable views.
-- Layout: body figure (top-left) + Core / Air / Wind readings (top-right) + grid
-- (below); the View pop-up is the footer band (Oct 30 2026, punch list 21).
-- Uses vanilla thermoregulator node iterator + *UI getters.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/ZeD_BodyFigure"

ZeD = ZeD or {}
ZeD.ThermalTab = {}

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

-- ============================================================================
-- VIEW DEFINITIONS
-- Each view maps to a thermal node getter (+ "UI" suffix for display value).
-- The card grid and figure colors switch based on the active view.
-- ============================================================================

local VIEWS = {
    { id = "skinTemp",  key = "IGUI_Temp_SkinTemperature",   getter = "getSkinCelcius",    format = "temp" },
    { id = "response",  key = "IGUI_Temp_BodyResponse",   getter = "getBodyResponse",   format = "pct"  },
    { id = "vessels",   key = "IGUI_Temp_BloodVessels",    getter = "getPrimaryDelta",   format = "pct"  },
    { id = "shiver",    key = "UI_ZeD_Thermal_ViewShiver",     getter = "getSecondaryDelta", format = "pct"  },
    { id = "insul",     vkey = "IGUI_Temp_Insulation",         getter = "getInsulation",     format = "pct"  },
    { id = "wind",      key = "IGUI_Temp_WindResistance",       getter = "getWindresist",     format = "pct"  },
    { id = "wetness",   key = "UI_ZeD_Thermal_ViewWetness",    getter = "getBodyWetness",    format = "pct"  },
}

-- Detail view: all metrics shown when hovering a body part
local DETAIL_ROWS = {
    { getter = "getSkinCelcius",    getterUI = "getSkinCelciusUI",    vkey = "IGUI_Temp_SkinTemperature" },
    { getter = "getBodyResponse",   getterUI = "getBodyResponseUI",   vkey = "IGUI_Temp_BodyResponse" },
    { getter = "getPrimaryDelta",   getterUI = "getPrimaryDeltaUI",   vkey = "IGUI_Temp_BloodVessels" },
    { getter = "getSecondaryDelta", getterUI = "getSecondaryDeltaUI", key = "UI_ZeD_Thermal_RowShiver" },
    { getter = "getInsulation",     getterUI = "getInsulationUI",     vkey = "IGUI_Temp_Insulation" },
    { getter = "getWindresist",     getterUI = "getWindresistUI",     vkey = "IGUI_Temp_WindResistance" },
    { getter = "getBodyWetness",    getterUI = "getBodyWetnessUI",    vkey = "IGUI_Temp_BodyWetness" },
    { getter = "getClothingWetness",getterUI = "getClothingWetnessUI",vkey = "IGUI_Temp_ClothingWetness" },
}

-- The words for a view or a detail row: vanilla's own text when it has the same
-- words (vkey), else ZeD's (key). Looked up where drawn, so the language applies.
function ZeD.ThermalTab.labelOf(def)
    if def.vkey then return getText(def.vkey) end
    return ZeD.tr(def.key)
end

-- true when the player's temperature unit is Celsius: the game's own option
-- (Options > Display), the one the oven reads too
function ZeD.ThermalTab.useCelsius()
    local core = getCore()
    if not core then return true end
    local ok, v = pcall(core.getOptionDisplayAsCelsius, core)
    if ok and v ~= nil then return v and true or false end
    ok, v = pcall(core.isCelsius, core)
    if ok and v ~= nil then return v and true or false end
    return true
end

-- a temperature the thermoregulator reports in degrees C, as the player's unit
-- shows it: one decimal, the unit after it ("37.0 C", "98.6 F")
function ZeD.ThermalTab.tempText(c)
    c = c or 0
    if ZeD.ThermalTab.useCelsius() then
        return ZeD.tr("UI_ZeD_Thermal_TempC", string.format("%.1f", c))
    end
    return ZeD.tr("UI_ZeD_Thermal_TempF", string.format("%.1f", c * 9 / 5 + 32))
end

-- BodyPartType → display name mapping (used by getNodeForType)
-- BodyPartType enum names verified against vanilla ISHealthPanel.lua
local BODY_PART_TYPES = {
    { type = BodyPartType.Head,        name = "Head" },
    { type = BodyPartType.Neck,        name = "Neck" },
    { type = BodyPartType.Torso_Upper, name = "Upper Torso" },
    { type = BodyPartType.Torso_Lower, name = "Lower Torso" },
    { type = BodyPartType.Groin,       name = "Groin" },
    { type = BodyPartType.UpperArm_L,  name = "Left Upper Arm" },
    { type = BodyPartType.UpperArm_R,  name = "Right Upper Arm" },
    { type = BodyPartType.ForeArm_L,   name = "Left Forearm" },
    { type = BodyPartType.ForeArm_R,   name = "Right Forearm" },
    { type = BodyPartType.Hand_L,      name = "Left Hand" },
    { type = BodyPartType.Hand_R,      name = "Right Hand" },
    { type = BodyPartType.UpperLeg_L,  name = "Left Upper Leg" },
    { type = BodyPartType.UpperLeg_R,  name = "Right Upper Leg" },
    { type = BodyPartType.LowerLeg_L,  name = "Left Lower Leg" },
    { type = BodyPartType.LowerLeg_R,  name = "Right Lower Leg" },
    { type = BodyPartType.Foot_L,      name = "Left Foot" },
    { type = BodyPartType.Foot_R,      name = "Right Foot" },
}

-- Canonical part order for display (must match BODY_PART_TYPES order)
local PART_ORDER = {}
for _, bp in ipairs(BODY_PART_TYPES) do
    PART_ORDER[#PART_ORDER + 1] = bp.name
end

-- Figure top padding (Zone A height driven by right column content)

-- ============================================================================
-- COLOR HELPERS
-- ============================================================================

-- Map a 0-1 value to the thermal spectrum color
local function getThermalColor(pct)
    local T = ZeD.T
    pct = math.max(0, math.min(1, pct or 0))
    if pct < 0.2  then return T.tempCold end
    if pct < 0.4  then return T.tempCool end
    if pct < 0.6  then return T.tempNorm end
    if pct < 0.8  then return T.tempWarm end
    return T.tempHot
end

-- ============================================================================
-- DATA GATHERING (uses getNodeForType — proven vanilla pattern)
-- ============================================================================

function ZeD.ThermalTab.gatherData(playerObj)
    local bodyDamage = playerObj:getBodyDamage()
    if not bodyDamage then
        return { coreTemp = 37.0, airTemp = 0, windTemp = 0, nodes = {}, partOrder = PART_ORDER }
    end

    local thermoregulator = bodyDamage:getThermoregulator()
    if not thermoregulator then
        return { coreTemp = 37.0, airTemp = 0, windTemp = 0, nodes = {}, partOrder = PART_ORDER }
    end

    -- Global readouts
    local coreTemp = thermoregulator:getCoreCelcius() or 37.0
    local airTemp  = thermoregulator:getTemperatureAir() or 0
    local windTemp = thermoregulator:getTemperatureAirAndWind() or 0

    -- Per-node data via getNodeForType (vanilla pattern from ISClothingInsPanel)
    local nodes = {}

    for _, bp in ipairs(BODY_PART_TYPES) do
        local node = thermoregulator:getNodeForType(bp.type)
        if node then
            local nodeData = {}
            -- Read all view getters (raw + UI)
            for _, view in ipairs(VIEWS) do
                local fn = node[view.getter]
                local fnUI = node[view.getter .. "UI"]
                nodeData[view.id] = fn and fn(node) or 0
                nodeData[view.id .. "_ui"] = fnUI and fnUI(node) or 0
            end
            -- Also read detail-only getters (clothing wetness)
            for _, row in ipairs(DETAIL_ROWS) do
                if not nodeData[row.getter] then
                    local fn = node[row.getter]
                    local fnUI = node[row.getterUI]
                    nodeData[row.getter] = fn and fn(node) or 0
                    nodeData[row.getterUI] = fnUI and fnUI(node) or 0
                end
            end
            nodes[bp.name] = nodeData
        end
    end

    return {
        coreTemp  = coreTemp,
        airTemp   = airTemp,
        windTemp  = windTemp,
        nodes     = nodes,
        partOrder = PART_ORDER,
        isFemale  = playerObj:isFemale(),
    }
end

-- ============================================================================
-- RENDERER (main entry point)
-- ============================================================================

function ZeD.ThermalTab.render(panel, win, x, y, w, h)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules
    local pad  = M.getTabPad()      -- 8px outer pad
    local padTop = M.getTabPadTop() -- 8px top pad below pinned header

    -- Init view state
    if not win._thermalView then win._thermalView = 1 end

    -- (Oct 30 2026, punch list 21 a-f: the View list no longer shuts when a draw comes 300 ms
    -- late, as a hitch or a screenshot made it; the window shuts it through closeMenu when the
    -- tab is left, the drawer folds or an item card opens over it)

    -- Throttled data refresh
    win._thermalTimer = (win._thermalTimer or 0) + 1
    if win._thermalTimer >= 15 or not win._thermalCache then
        win._thermalTimer = 0
        win._thermalCache = ZeD.ThermalTab.gatherData(win._playerObj)
    end
    local data = win._thermalCache

    -- S102 — Resolve "active" body part: gamepad focus on a thermal body-part
    -- element overrides mouse hover so D-pad through parts live-swaps the
    -- right-column detail view. Stashed on win so _drawBodyFigure reads the
    -- same authoritative value for fig.selectedPart (white highlight).
    -- (the live element: the controller leads only while it is in use)
    local activePart = win._thermalHoveredPart
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local el = Focus and Focus.liveElement and Focus.liveElement(win)
        if el and el.partName then activePart = el.partName end
    end
    win._thermalActivePart = activePart

    -- Fixed figure size
    local figW = T.sp.figureW
    local figH = T.sp.figureH

    -- Right column height (for zone A height measurement): the Core / Air / Wind readings and the gauge
    local rightColH = ZeD.ThermalTab._measureReadings()

    -- Pinned header height (not in scroll content)
    local headerH = M.getTabHeaderH()
    local figureExpanded = win._thermalFigureExpanded

    -- Zone A scrollable body height (figure + padding, no section header — it's pinned)
    local figureContentH = math.max(figH, rightColH) + pad
    -- (with the figure folded away the readings stay, full width, above the grid)
    local zoneAH = figureExpanded and figureContentH or (rightColH + pad)

    -- Measure total scrollable content: zone A body + zone B grid
    local scroll  = win._thermalScroll
    local scrollW = T.sp.scrollbarW
    local gridContentH = ZeD.ThermalTab._measureGridContent(data, w - pad * 2, scrollW)
    local totalContentH = padTop + zoneAH + T.sp.afterLine + gridContentH

    -- Scroll area runs from the pinned header to the footer band (Oct 30 2026: the View pop-up's band)
    local scrollY = y + headerH
    local bandH = M.bandH()
    local bandY = y + h - bandH
    local scrollH = h - headerH - bandH
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

    -- Oct 30 2026, punch list 21 a-f: what the body shows between the header and the band (the
    -- figure's parts outside it are no stops: the window's _inBodyView), and a part the
    -- controller focuses kept whole in view, by the least scroll (once per focus change)
    win._thermalBodyRect = { x = x, y = scrollY, w = contentW, h = scrollH }   -- (its own name: _thermalView is the chosen view, 1..7; punch list 21 g)
    if needsScroll then
        local Focus = ZeD.Input and ZeD.Input.Focus
        local el = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == win
                   and Focus.getFocusedElement(win) or nil
        local key = el and el.partName and el.id or nil
        if key and key ~= win._thermalPinned and type(el.y) == "number" then
            local span = math.max(1, totalContentH - scrollH)
            local oldOff = math.floor(scroll.scrollPos * span)
            local ly, lh = (el.fullY or el.y) - scrollY + oldOff, el.fullH or el.h or 0
            local target = oldOff
            if ly < oldOff then target = ly elseif ly + lh > oldOff + scrollH then target = ly + lh - scrollH end
            target = math.max(0, math.min(span, target))
            if target ~= oldOff then scroll:setScrollPos(target / span) end
        end
        win._thermalPinned = key
    end

    panel:setStencilRect(x, scrollY, contentW, scrollH)

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * math.max(0, totalContentH - scrollH))
    end

    local drawY = scrollY - scrollOff + padTop

    -- ── Zone A: figure (left, layoutZoneA) + info panel (right) ──
    local curY = drawY
    if figureExpanded then
        -- layoutZoneA receives contentW (post-scroll) so rightW is correct with/without scrollbar
        local layout = M.layoutZoneA(x, curY, contentW, figW, figH)
        ZeD.ThermalTab._drawBodyFigure(panel, win, data,
            layout.figX, layout.figY, figW, figH)

        if activePart and data.nodes[activePart] then
            ZeD.ThermalTab._renderDetailView(panel, win, data, activePart,
                layout.rightX, layout.rightY, layout.rightW, figH)
        else
            ZeD.ThermalTab._renderHeader(panel, win, data,
                layout.rightX, layout.rightY, layout.rightW)
        end

    else
        ZeD.ThermalTab._renderHeader(panel, win, data, x + pad, curY, contentW - pad * 2)
    end
    curY = drawY + zoneAH

    -- ── Zone B: Body part grid ──
    local gridY = curY + T.sp.afterLine
    ZeD.ThermalTab._renderCardGrid(panel, win, data,
        x + pad, gridY, contentW - pad * 2, gridContentH)

    -- S102 — stamp the grid as a gamepad pseudo-zone (grid rows aren't
    -- focusable per stats-not-focusable rule, so the whole grid becomes
    -- one scroll surface). D-pad up/down scrolls the viewport while focused;
    -- cone nav from pills/body parts lands here spatially.
    --
    -- S105 fix: stamp the zone whenever there's scrollable content, positioned
    -- within the viewport even when grid content is scrolled off-screen. User
    -- reported "cannot virtual scroll while top zone is open" — with figure
    -- expanded, Zone A occupies the viewport and the grid was below it, so
    -- the old logic (intersect gridY..gridBot with scrollY..scrollBot) yielded
    -- a zero-height zone → nil → unreachable focusable. Fix: when scrollable
    -- content exists, always pin the zone to the bottom 25% of the viewport
    -- so cone-nav from above can reach it, which then allows D-pad DOWN to
    -- scroll the grid into view.
    if needsScroll then
        local intTop = math.max(gridY, scrollY)
        local intBot = math.min(gridY + gridContentH, scrollY + scrollH)
        if intBot > intTop then
            -- Grid partially/fully visible — use actual intersection.
            win._thermalGridScrollZone = {
                x = x + pad, y = intTop,
                w = contentW - pad * 2, h = intBot - intTop,
            }
        else
            -- Grid off-viewport — pin to bottom 25% of viewport as a virtual
            -- scroll handle. Has no visual, only a focus target.
            local gzH = math.max(T.px(24), math.floor(scrollH * 0.25))
            local gzY = scrollY + scrollH - gzH
            win._thermalGridScrollZone = {
                x = x + pad, y = gzY,
                w = contentW - pad * 2, h = gzH,
            }
        end
    else
        win._thermalGridScrollZone = nil
    end

    panel:clearStencilRect()

    -- Pinned header, drawn on top of the scroll content: the hover wash and the
    -- controller's mark on the disclosure come with the molecule
    local hdrHover = A.mouseIn(panel, x, y, w, headerH)
    if hdrHover and ZeD.Help then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Thermal_HelpHeader")) end
    M.drawTabHeader(panel, x, y, w, ZeD.tr("UI_ZeD_Char_TabThermal"), figureExpanded, hdrHover, nil,
        { focus = focusOf(win, "thermal:__disclosure") })
    win._thermalFigureZone = { x = x, y = y, w = w, h = headerH }

    -- Scrollbar (outside stencil)
    if needsScroll then
        scroll:draw(panel)
    end

    -- The footer band, pinned at the card's foot; the View list (when open) over everything
    ZeD.ThermalTab._renderBand(panel, win, x, bandY, w)
    ZeD.ThermalTab._renderMenu(panel, win)
end

-- ============================================================================
-- READINGS (Zone A right side — default, no hover)
-- Core / Air / Wind and the core gauge, beside the figure (Oct 30 2026: they
-- moved up from the top of the grid when the view buttons became the footer
-- band's pop-up). A part under the pointer or the pad swaps them for its details.
-- ============================================================================

-- one reading row's height (what ZeD.Molecules.drawStatRow takes)
local function readingRowH()
    local T, TM = ZeD.T, ZeD.TM
    local m = math.max(TM:getFontHeight(T.fontF1), TM:getFontHeight(T.fontF3))
    return m + math.max(T.px(2), math.floor(m * 0.15))
end

-- the readings' height: three rows and the gauge
function ZeD.ThermalTab._measureReadings()
    local T = ZeD.T
    return 3 * (readingRowH() + T.sp.rowGap) + T.fillBarH
end

function ZeD.ThermalTab._renderHeader(panel, win, data, rx, ry, rw)
    local T = ZeD.T
    local M = ZeD.Molecules
    local curY = ry
    -- the readings are degrees C from the thermoregulator; shown in the player's unit
    curY = curY + M.drawStatRow(panel, rx, curY, rw, ZeD.tr("UI_ZeD_Thermal_Core"),
        ZeD.ThermalTab.tempText(data.coreTemp), T.toneNorm) + T.sp.rowGap
    curY = curY + M.drawStatRow(panel, rx, curY, rw, ZeD.tr("UI_ZeD_Thermal_Air"),
        ZeD.ThermalTab.tempText(data.airTemp), T.toneNorm) + T.sp.rowGap
    curY = curY + M.drawStatRow(panel, rx, curY, rw, ZeD.tr("IGUI_Fishing_Wind"),
        ZeD.ThermalTab.tempText(data.windTemp), T.toneNorm) + T.sp.rowGap
    -- Core temperature gauge: the chunky framed strip (the standard bar height), not a thin line
    ZeD.Atoms.drawGradientBar(panel, rx, curY, rw, T.fillBarH, (data.coreTemp - 30) / 12)
end

-- ============================================================================
-- FOOTER BAND: the View pop-up (Oct 30 2026, punch list 21)
-- "View: Skin temperature" at the left, nothing at the right. The seven views were
-- radio buttons; the list opens upward from the box. The same pattern as Craft's
-- sort pop-up: the open list takes every press; the pad's stops become its rows.
-- ============================================================================

local function inRect(r, x, y)
    return r ~= nil and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h
end

-- the pop-up list: opened by the box, shut by a pick, a click anywhere else or B; the pad
-- returns to the box it came from (_thermalReturnToMenu, read by the tab's focusables)
function ZeD.ThermalTab.openMenu(win)
    win._thermalMenuOpen = true
    win._thermalMenuZones = nil
end

function ZeD.ThermalTab.closeMenu(win, pickIdx)
    if pickIdx then win._thermalView = pickIdx end
    win._thermalMenuOpen = false
    win._thermalMenuZones = nil
    win._thermalReturnToMenu = true
end

-- The mouse path through the band: an open list takes every press (a pick or shut it);
-- else the box opens it. Returns true when the press was the band's.
function ZeD.ThermalTab.onClick(win, x, y)
    if win._thermalMenuOpen then
        for _, z in ipairs(win._thermalMenuZones or {}) do
            if inRect(z, x, y) then
                ZeD.ThermalTab.closeMenu(win, z.id)
                return true
            end
        end
        ZeD.ThermalTab.closeMenu(win)
        return true
    end
    local bz = win._thermalBand
    if not bz or y < bz.y or y >= bz.y + bz.h then return false end
    if inRect(bz.box, x, y) then ZeD.ThermalTab.openMenu(win) end
    return true
end

local _bandSpec = {}

-- The band at the card's foot, top-left (x, y): [View: Skin temperature v]
function ZeD.ThermalTab._renderBand(panel, win, x, y, w)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local bh, edge = T.buttonH, T.px(8)
    local by = y + T.px(5)
    local open = win._thermalMenuOpen == true
    local bz = win._thermalBand
    if not bz then bz = { box = {} }; win._thermalBand = bz end
    bz.y, bz.h = y, M.bandH()

    _bandSpec.win = win
    M.drawBand(panel, x, y, w, _bandSpec)

    -- the box is as wide as the longest view's words, so picking another never changes it
    local nat = 0
    for _, view in ipairs(VIEWS) do
        local nw = M.popupMenuW(ZeD.tr("UI_ZeD_Thermal_ViewPick", ZeD.ThermalTab.labelOf(view)))
        if nw > nat then nat = nw end
    end
    local boxX = x + edge
    local boxW = math.max(T.px(40), math.min(nat, w - edge * 2))
    local hov = (not open) and A.mouseIn(panel, boxX, by, boxW, bh)
    if hov and ZeD.Help then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Thermal_HelpViewMenu")) end
    local view = VIEWS[win._thermalView or 1] or VIEWS[1]
    M.drawPopupMenu(panel, boxX, by, boxW, bh, ZeD.tr("UI_ZeD_Thermal_ViewPick", ZeD.ThermalTab.labelOf(view)),
        hov or open, focusOf(win, "thermal:view"), false)
    bz.box.x, bz.box.y, bz.box.w, bz.box.h = boxX, by, boxW, bh
end

local _menuModes = {}
local _menuOpts = {}

-- The open View list, drawn LAST (over the body and the band), hanging up from the box.
-- Its row rects are kept for the click and the pad; the row with the controller's focus
-- carries the mark. The rows' ids are the view numbers.
function ZeD.ThermalTab._renderMenu(panel, win)
    local bz = win._thermalBand
    if not (win._thermalMenuOpen and bz) then return end
    local M, A = ZeD.Molecules, ZeD.Atoms
    local n = #VIEWS
    for i = 1, n do
        local m = _menuModes[i]
        if not m then m = {}; _menuModes[i] = m end
        m.id, m.label = i, ZeD.ThermalTab.labelOf(VIEWS[i])
    end
    local hoverId = nil
    for _, z in ipairs(win._thermalMenuZones or {}) do
        if A.mouseIn(panel, z.x, z.y, z.w, z.h) then hoverId = z.id; break end
    end
    local o = _menuOpts
    o.win, o.minW, o.focusId = win, bz.box.w, nil
    local F = ZeD.Input and ZeD.Input.Focus
    local el = F and F.liveElement and F.liveElement(win)
    if el and el.menuRowId then o.focusId = el.menuRowId end
    local gy = math.max(0, bz.box.y - M.popupListH(n))
    local _, _, zs = M.drawSortMenuList(panel, bz.box.x, gy, _menuModes, win._thermalView or 1, hoverId, o)
    win._thermalMenuZones = zs
    if hoverId and ZeD.Help then
        ZeD.Help.set(win, ZeD.tr("UI_ZeD_Thermal_HelpView", _menuModes[hoverId].label))
    end
end

-- ============================================================================
-- BODY FIGURE UPDATE (colors driven by active view)
-- ============================================================================

function ZeD.ThermalTab._ensureBodyFigure(win)
    if not win._thermalBodyFigure then
        -- Create as a standalone object — NOT a child panel
        local fig = ZeD_BodyFigure:new(0, 0, 100, 100)  -- S124 scale: placeholder size, drawAt() is given the real (scaled) rect
        fig:initialise()
        fig:loadTextures()
        win._thermalBodyFigure = fig
    end
    return win._thermalBodyFigure
end

function ZeD.ThermalTab._drawBodyFigure(panel, win, data, px, py, pw, ph)
    local fig = ZeD.ThermalTab._ensureBodyFigure(win)

    if data.isFemale ~= nil then
        fig:setSex(data.isFemale)
    end

    -- Color by active view metric
    local viewIdx = win._thermalView or 1
    local view = VIEWS[viewIdx]
    local uiKey = view.id .. "_ui"

    for partName, nodeData in pairs(data.nodes) do
        local uiVal = nodeData[uiKey] or 0
        local color = getThermalColor(uiVal, viewIdx)
        fig:setPartColor(partName, color.r, color.g, color.b, 0.65)
    end

    -- Wire highlight state for white figure overlay. Reads the resolved
    -- active part (gamepad focus overrides mouse hover — see render()).
    fig.selectedPart = win._thermalActivePart or nil

    -- the controller's mark on a focused part: its washes go under the figure (the
    -- rects are the last frame's, which the figure keeps), the hand beside it
    local el = ZeD.Input and ZeD.Input.Focus and ZeD.Input.Focus.liveElement and ZeD.Input.Focus.liveElement(win)
    if el and el.partName and fig.getPartRects then
        for _, r in ipairs(fig:getPartRects()) do
            if r.name == el.partName then
                _focusOpts.win = win
                ZeD.Focus.mark(panel, r.x, r.y, r.w, r.h, _focusOpts)
                break
            end
        end
    end

    -- Draw onto the parent panel (inside stencil — clips properly)
    fig:drawAt(panel, px, py, pw, ph)
end

-- ============================================================================
-- CARD GRID VIEW (Zone B — scrollable, full width)
-- Displays the active view's metric per body part.
-- ============================================================================

function ZeD.ThermalTab._renderCardGrid(panel, win, data, rx, ry, rw, rh)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules

    local listX   = rx
    local listW   = rw

    -- Active view
    local viewIdx = win._thermalView or 1
    local view = VIEWS[viewIdx]
    local uiKey = view.id .. "_ui"
    local rawKey = view.id

    local drawY = ry

    -- (the Core / Air / Wind readings and the core gauge sit beside the figure now: _renderHeader)

    -- Section head (the content line under it comes with the molecule)
    drawY = drawY + M.drawSectionHeader(panel, listX, drawY, listW,
        ZeD.tr("UI_ZeD_Thermal_ByRegion", ZeD.ThermalTab.labelOf(view)), nil, true, false, nil, nil, nil, nil, true)
    drawY = drawY + T.sp.xs

    -- Two-column body part grid
    local colGap = T.sp.sm
    local colW = math.floor((listW - colGap) / 2)
    local leftY  = drawY
    local rightY = drawY
    local rowGap = T.sp.xs

    for i, partName in ipairs(data.partOrder) do
        local nodeData = data.nodes[partName]

        local isLeft = ((i - 1) % 2 == 0)
        local cx = isLeft and listX or (listX + colW + colGap)
        local cy = isLeft and leftY or rightY

        -- Get values for this view
        local uiVal = nodeData and nodeData[uiKey] or 0
        local rawVal = nodeData and nodeData[rawKey] or 0
        local fillPct = math.max(0, math.min(1, uiVal))
        local fc = getThermalColor(fillPct)

        -- Format value based on view type
        local valStr
        if view.format == "temp" then
            valStr = ZeD.ThermalTab.tempText(rawVal)
        else
            valStr = string.format("%.2f", uiVal)
        end

        local rowH = M.drawStatBarRow(panel, cx, cy, colW, valStr, ZeD.partLabel(partName), fillPct, fc, T.toneNorm)

        if isLeft then leftY = cy + rowH + rowGap
        else rightY = cy + rowH + rowGap end
    end
end

-- ============================================================================
-- DETAIL VIEW (hover — shows all metrics for the hovered body part)
-- ============================================================================

function ZeD.ThermalTab._renderDetailView(panel, win, data, partName, rx, ry, rw, rh)
    local T    = ZeD.T
    local M    = ZeD.Molecules

    local nodeData = data.nodes[partName]
    if not nodeData then return end

    local curY = ry

    -- All metric rows
    local rowGap = T.sp.xs

    for ri, row in ipairs(DETAIL_ROWS) do
        -- Alternating row stripe
        if ri % 2 == 0 then
            local st = T.stripe
            local estH = math.max(ZeD.TM:getFontHeight(T.fontF1), ZeD.TM:getFontHeight(T.fontF2)) + T.px(4)
            panel:drawRect(rx, curY, rw, estH, st.a, st.r, st.g, st.b)
        end
        local uiVal = nodeData[row.getterUI] or 0
        local rawVal = nodeData[row.getter] or 0
        local fillPct = math.max(0, math.min(1, uiVal))
        local fc = getThermalColor(fillPct)

        -- Format: skin temp shows raw celsius, others show UI value
        local valStr
        if row.getter == "getSkinCelcius" then
            valStr = ZeD.ThermalTab.tempText(rawVal)
        else
            valStr = string.format("%.2f", uiVal)
        end

        local rowH = M.drawStatBarRow(panel, rx, curY, rw, valStr, ZeD.ThermalTab.labelOf(row), fillPct, fc)
        curY = curY + rowH + rowGap
    end
end

-- ============================================================================
-- CONTENT HEIGHT MEASUREMENT
-- ============================================================================

function ZeD.ThermalTab._measureGridContent(data, listW, scrollW)
    local T    = ZeD.T

    local total = 0

    -- Grid header: the section head (the readings and the gauge are beside the figure)
    total = total + T.px(20) + T.sp.xs      -- section head (20u)

    -- Body part rows (2 columns). rowH must match Molecules.drawStatBarRow:
    --   rowH = max(valFont=F3, lblFont=F2) + 8
    -- Previously used secH (F1) + 8, which under-measured by ~4px per row →
    -- with 9 rows the bottom row was clipped by ~36px ("halfway visible").
    local valH = ZeD.TM:getFontHeight(T.fontF3)
    local lblH = ZeD.TM:getFontHeight(T.fontF2)
    local rowH = math.max(valH, lblH) + T.px(8)
    local rowGap = T.sp.xs
    local numRows = math.ceil(#PART_ORDER / 2)
    total = total + numRows * (rowH + rowGap)

    return total
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.ThermalTab.register(dispatchTable)
    dispatchTable["thermal"] = ZeD.ThermalTab.render
end
