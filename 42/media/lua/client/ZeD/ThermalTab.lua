-- ZeD-UI/42/media/lua/client/ZeD/ThermalTab.lua
-- ============================================================================
-- THERMAL TAB (client) — the Character window's per-body-part thermoregulation
-- tab, with 7 switchable views.
-- Layout: body figure (top-left) + Core / Air / Wind readings and Body Heat
-- Generation (top-right) + grid (below) + the picked region's eight rows under
-- the grid (a cell press or A picks it; pointing at a cell or a figure part
-- shows that one there until it is left); the View pop-up lives in the footer band.
-- Reads vanilla's thermoregulator nodes (getNodeForType) and their *UI getters.
-- The readings are gathered every 15 frames into win._thermalCache; the draw
-- functions read only that table, never the thermoregulator.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/ZeD_BodyFigure"
require "ZeD/ZeD_TabFill"
require "ZeD/ZeD_Popups"

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
-- (scale: vanilla's words for the bar's low end, middle and high end, as its
-- clothing panel prints them; false where it has no middle word)
local DETAIL_ROWS = {
    { getter = "getSkinCelcius",    getterUI = "getSkinCelciusUI",    vkey = "IGUI_Temp_SkinTemperature",
      scale = { "IGUI_Temp_Cold", "IGUI_Temp_Normal", "IGUI_Temp_Hot" } },
    { getter = "getBodyResponse",   getterUI = "getBodyResponseUI",   vkey = "IGUI_Temp_BodyResponse",
      scale = { "IGUI_Temp_FightCold", "IGUI_Temp_Normal", "IGUI_Temp_FightHot" } },
    { getter = "getPrimaryDelta",   getterUI = "getPrimaryDeltaUI",   vkey = "IGUI_Temp_BloodVessels",
      scale = { "IGUI_Temp_Vasoconstriction", "IGUI_Temp_Normal", "IGUI_Temp_Vasodilation" } },
    { getter = "getSecondaryDelta", getterUI = "getSecondaryDeltaUI", key = "UI_ZeD_Thermal_RowShiver",
      scale = { "IGUI_Temp_Shivering", "IGUI_Temp_Normal", "IGUI_Temp_Perspiring" } },
    { getter = "getInsulation",     getterUI = "getInsulationUI",     vkey = "IGUI_Temp_Insulation",
      scale = { "IGUI_Temp_Low", "IGUI_Temp_Med", "IGUI_Temp_High" } },
    { getter = "getWindresist",     getterUI = "getWindresistUI",     vkey = "IGUI_Temp_WindResistance",
      scale = { "IGUI_Temp_Low", "IGUI_Temp_Med", "IGUI_Temp_High" } },
    { getter = "getBodyWetness",    getterUI = "getBodyWetnessUI",    vkey = "IGUI_Temp_BodyWetness",
      scale = { "IGUI_Temp_Dry", false, "IGUI_Temp_Soaked" } },
    { getter = "getClothingWetness",getterUI = "getClothingWetnessUI",vkey = "IGUI_Temp_ClothingWetness",
      scale = { "IGUI_Temp_Dry", false, "IGUI_Temp_Soaked" } },
}
ZeD.ThermalTab.DETAIL_ROWS = DETAIL_ROWS
-- the region picked until the player picks another
local DEFAULT_PICK = "Upper Torso"

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
-- shows it: one decimal, the unit after it ("37.0 C", "98.6 F"). celsius, when
-- given, is the unit already read (the tab reads the option once a frame)
function ZeD.ThermalTab.tempText(c, celsius)
    c = c or 0
    if celsius == nil then celsius = ZeD.ThermalTab.useCelsius() end
    if celsius then
        return ZeD.tr("UI_ZeD_Thermal_TempC", string.format("%.1f", c))
    end
    return ZeD.tr("UI_ZeD_Thermal_TempF", string.format("%.1f", c * 9 / 5 + 32))
end

-- The parts the tab reads, each by its BodyPartType (what getNodeForType takes)
-- and its English name, the key the figure and ZeD.partLabel look up (the
-- words shown are the player's language). The enum names are vanilla's, as
-- ISHealthPanel.lua uses them.
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

-- Display order of the parts: BODY_PART_TYPES' order, by name.
local PART_ORDER = {}
for _, bp in ipairs(BODY_PART_TYPES) do
    PART_ORDER[#PART_ORDER + 1] = bp.name
end

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

-- The core temperature's moodle level, the game's own cuts (the director's call 1, Nov 25 2026):
-- Hypothermia below 36.5, 35, 30 and 25 C (-1..-4), Hyperthermia above 37.5, 39, 40 and 41 C (1..4), else 0.
local HYPO_CUTS  = { 36.5, 35, 30, 25 }
local HYPER_CUTS = { 37.5, 39, 40, 41 }
function ZeD.ThermalTab.coreLevel(c)
    c = c or 37
    local lv = 0
    for i, cut in ipairs(HYPO_CUTS) do if c < cut then lv = -i end end
    if lv ~= 0 then return lv end
    for i, cut in ipairs(HYPER_CUTS) do if c > cut then lv = i end end
    return lv
end
-- the core meter by level: each level its own segments and color; green only with no moodle on
-- (lit: Hypothermia 4..1 = 1..4, none = 5, Hyperthermia 1..4 = 7..10)
local CORE_LIT = { [-4] = 1, [-3] = 2, [-2] = 3, [-1] = 4, [0] = 5, [1] = 7, [2] = 8, [3] = 9, [4] = 10 }
--- The moodles' own level, -4..4 (Hypothermia negative), or nil with no player to read: the game holds a
--- moodle back at times (drunk, Hypothermia 1), and the meter follows the moodle (QA's read, Nov 25 2026)
function ZeD.ThermalTab.moodleLevel(playerObj)
    if not (playerObj and MoodleType) then return nil end
    local ok, m = pcall(playerObj.getMoodles, playerObj)
    if not ok or not m then return nil end
    local ok1, hypo = pcall(m.getMoodleLevel, m, MoodleType.HYPOTHERMIA)
    local ok2, hyper = pcall(m.getMoodleLevel, m, MoodleType.HYPERTHERMIA)
    if not (ok1 and ok2) then return nil end
    if (hypo or 0) > 0 then return -math.min(4, hypo) end
    return math.min(4, hyper or 0)
end
function ZeD.ThermalTab.coreLook(c, lvIn)
    local T = ZeD.T
    local lv = lvIn or ZeD.ThermalTab.coreLevel(c)
    local col = T.tempNorm
    if lv == -1 then col = T.tempCool elseif lv < -1 then col = T.tempCold
    elseif lv == 1 then col = T.tempWarm elseif lv > 1 then col = T.tempHot end
    return CORE_LIT[lv], col, lv
end

-- The WET moodle's steps (15, 40, 70 and 90 of 100) and its own words (the director's call 4)
local WET_CUTS = { 0.15, 0.40, 0.70, 0.90 }
function ZeD.ThermalTab.wetLevel(v)
    local lv = 0
    for i, cut in ipairs(WET_CUTS) do if (v or 0) >= cut then lv = i end end
    return lv
end
function ZeD.ThermalTab.wetWordKey(v)
    local lv = ZeD.ThermalTab.wetLevel(v)
    return lv == 0 and "IGUI_Temp_Dry" or ("Moodles_Wet_lvl" .. lv)
end
-- Wetness in the game's own scheme, green when dry to blue when soaked (call 2), one flat color per
-- moodle step: dry the green, then halfway to the teal, the teal, halfway to the blue, the blue
local _wetMix = { {}, {} }
local function mix(out, a, b)
    out.r, out.g, out.b, out.a = (a.r + b.r) / 2, (a.g + b.g) / 2, (a.b + b.b) / 2, 1
    return out
end
function ZeD.ThermalTab.wetColor(v)
    local T = ZeD.T
    local lv = ZeD.ThermalTab.wetLevel(v)
    if lv == 0 then return T.tempNorm end
    if lv == 1 then return mix(_wetMix[1], T.tempNorm, T.tempCool) end
    if lv == 2 then return T.tempCool end
    if lv == 3 then return mix(_wetMix[2], T.tempCool, T.tempCold) end
    return T.tempCold
end
local function isWetGetter(g) return g == "getBodyWetness" or g == "getClothingWetness" end

-- ============================================================================
-- DATA GATHERING (getNodeForType per part, as vanilla's own panels read it)
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

    -- Body Heat Generation, 0..1 (vanilla's clothing panel's second bar)
    local okH, heat = pcall(thermoregulator.getHeatGenerationUI, thermoregulator)

    return {
        coreTemp  = coreTemp,
        airTemp   = airTemp,
        windTemp  = windTemp,
        heatGen   = (okH and type(heat) == "number") and heat or nil,
        nodes     = nodes,
        partOrder = PART_ORDER,
        isFemale  = playerObj:isFemale(),
    }
end

-- ============================================================================
-- RENDERER (main entry point)
-- ============================================================================

--- The tab, every frame: the scrolling body (figure and readings, then the
--- grid), the pinned header over it, the band and, last, the open View list.
function ZeD.ThermalTab.render(panel, win, x, y, w, h)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules
    local pad  = M.getTabPad()      -- 8px outer pad
    local padTop = M.getTabPadTop() -- 8px top pad below pinned header

    -- The chosen view lives on the window, so it survives leaving the tab.
    if not win._thermalView then win._thermalView = 1 end

    -- (the View list never shuts on a slow frame — a hitch or a screenshot once
    -- made it blink shut; the window shuts it through closeMenu when the tab is
    -- left, the drawer folds or an item card opens over it)

    -- Throttled data refresh
    win._thermalTimer = (win._thermalTimer or 0) + 1
    if win._thermalTimer >= 15 or not win._thermalCache then
        win._thermalTimer = 0
        win._thermalCache = ZeD.ThermalTab.gatherData(win._playerObj)
    end
    local data = win._thermalCache
    -- the temperature unit, read once this frame (every reading and row below shows it)
    win._thermalCelsiusNow = ZeD.ThermalTab.useCelsius()
    ZeD.TabFill.begin(win, "thermal")
    if not win._thermalPick then win._thermalPick = DEFAULT_PICK end

    -- Resolve the "active" body part: gamepad focus on a part overrides mouse
    -- hover, so the D-pad through the parts live-swaps the right-column detail
    -- view. Stashed on win so _drawBodyFigure reads the same value for
    -- fig.selectedPart (the white highlight).
    -- (the live element: the controller leads only while it is in use)
    -- (a folded figure has no hovered part: a fold by the pad with the pointer resting on a part left it
    -- stuck there, and the block showed that part instead of the pick, QA T8)
    if not win._thermalFigureExpanded then win._thermalHoveredPart = nil end
    local activePart = win._thermalHoveredPart
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local el = Focus and Focus.liveElement and Focus.liveElement(win)
        if el and el.partName then activePart = el.partName end
    end
    win._thermalActivePart = activePart

    -- Right column height (for zone A height measurement): the Core / Air / Wind readings and the gauge
    local rightColH = ZeD.ThermalTab._measureReadings()

    -- Pinned header height (not in scroll content)
    local headerH = M.getTabHeaderH()
    local figureExpanded = win._thermalFigureExpanded

    -- Zone A scrollable body height (figure + padding, no section header — it's pinned)
    -- (the figure in its frame, the left half, the readings the right half or under it on a narrow card: measured
    -- at the narrowest the body draws, the scroll bar showing) (Figure frame, the director, Nov 22 2026)
    local figureContentH = M.figureZoneH(M.layoutZoneA(0, 0, w - T.sp.scrollbarW), rightColH) + pad
    -- (with the figure folded away the readings stay, full width, above the grid)
    local zoneAH = figureExpanded and figureContentH or (rightColH + pad)

    -- Measure total scrollable content: zone A body + zone B grid
    local scroll  = win._thermalScroll
    local scrollW = T.sp.scrollbarW
    local gridContentH = ZeD.ThermalTab._measureGridContent(data, w - pad * 2, scrollW)
    -- the picked region's block under the grid (measured with no panel: the code that draws it)
    local pickedH = T.px(8) + ZeD.ThermalTab._renderPicked(nil, win, data, 0, 0, w - pad * 2 - scrollW)
    local totalContentH = padTop + zoneAH + T.sp.afterLine + gridContentH + pickedH

    -- Scroll area runs from the pinned header to the footer band (the View pop-up's band)
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

    -- The body area between the header and the band: the window's _inBodyView
    -- reads it (a figure part scrolled out of it is no controller stop). Once per
    -- focus change the body follows the controller's focus by Health's rule
    -- (ZeD_TabFill's followStop): the lowest stop shown scrolls it on, so Down from
    -- the feet reaches the grid even where the open figure fills the view; Up onto
    -- the highest one shown scrolls it back; any other stop is kept whole in view.
    win._thermalBodyRect = { x = x, y = scrollY, w = contentW, h = scrollH }   -- (its own name: _thermalView is the chosen view, 1..7)
    if needsScroll then
        local Focus = ZeD.Input and ZeD.Input.Focus
        local el = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow(win.playerNum) == win
                   and Focus.getFocusedElement(win) or nil
        local key = el and (el.partName or el.fillStop) and el.id or nil
        if key and key ~= win._thermalPinned and type(el.y) == "number" then
            local span = math.max(1, totalContentH - scrollH)
            local oldOff = math.floor(scroll.scrollPos * span)
            local ly, lh = (el.fullY or el.y) - scrollY + oldOff, el.fullH or el.h or 0
            local target = ZeD.TabFill.followStop(win, el, ly, lh, scrollH, oldOff, span)
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
        local layout = M.layoutZoneA(x, curY, contentW)
        -- the figure in its frame at the layout's whole zoom (Figure frame, the director, Nov 22 2026)
        M.drawFigureFrame(panel, layout)
        ZeD.ThermalTab._drawBodyFigure(panel, win, data,
            layout.figX, layout.figY, layout.figW, layout.figH, layout)

        -- (the readings stay: a pointed part shows in the picked region's block under the grid)
        ZeD.ThermalTab._renderHeader(panel, win, data,
            layout.rightX, layout.rightY, layout.rightW)

    else
        ZeD.ThermalTab._renderHeader(panel, win, data, x + pad, curY, contentW - pad * 2)
    end
    curY = drawY + zoneAH

    -- ── Zone B: Body part grid ──
    local gridY = curY + T.sp.afterLine
    ZeD.ThermalTab._renderCardGrid(panel, win, data,
        x + pad, gridY, contentW - pad * 2, gridContentH)

    -- The picked region's eight rows under the grid. The grid's cells and these rows are
    -- the controller's stops (ZeD_TabFill zones): the D-pad walks the cells, A picks one,
    -- the block follows the focused cell; the rows only read.
    ZeD.ThermalTab._renderPicked(panel, win, data, x + pad, gridY + gridContentH + T.px(8), contentW - pad * 2)
    win._thermalGridScrollZone = nil

    panel:clearStencilRect()

    -- Pinned header, drawn on top of the scroll content: the hover wash and the
    -- controller's mark on the disclosure come with the molecule
    local hdrHover = A.mouseIn(panel, x, y, w, headerH)
    if hdrHover and ZeD.Help then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Thermal_HelpHeader")) end
    -- (QA's visual noise audit 3 and 38, Nov 20 2026: the header said "Thermal" under the title bar's "+ Thermal";
    -- it folds the body figure, its only job, so it names that. The band stays: it is the figure's one fold.)
    M.drawTabHeader(panel, x, y, w, ZeD.tr("UI_ZeD_Tab_BodyFigure"), figureExpanded, hdrHover, nil,
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
-- Core / Air / Wind and the core gauge, beside the figure. A part under the
-- pointer or the pad swaps them for its details.
-- ============================================================================

-- one reading row's height (what ZeD.Molecules.drawStatRow takes)
local function readingRowH()
    local T, TM = ZeD.T, ZeD.TM
    local m = math.max(TM:getFontHeight(T.fontF1), TM:getFontHeight(T.fontF3))
    return m + math.max(T.px(2), math.floor(m * 0.15))
end

-- the readings' height: three rows and the core meter, then Body Heat Generation and its meter
function ZeD.ThermalTab._measureReadings()
    local T = ZeD.T
    return 4 * (readingRowH() + T.sp.rowGap) + T.fillBarH + T.px(10)   -- (one meter: audit 41)
end


function ZeD.ThermalTab._renderHeader(panel, win, data, rx, ry, rw)
    local T = ZeD.T
    local M = ZeD.Molecules
    local celsius = win._thermalCelsiusNow
    if celsius == nil then celsius = ZeD.ThermalTab.useCelsius() end
    local curY = ry
    -- the readings are degrees C from the thermoregulator; shown in the player's unit
    -- (QA's visual noise audit 41, Nov 20 2026: the core's meter sat under "Wind" with no label, Body Heat
    -- Generation had a word and a second meter saying the same, and "Wind" over a temperature read as the wind's
    -- speed. The core's meter now sits under Core, body heat is its word alone, and the row is "Wind chill".)
    curY = curY + M.drawStatRow(panel, rx, curY, rw, ZeD.tr("UI_ZeD_Thermal_Core"),
        ZeD.ThermalTab.tempText(data.coreTemp, celsius), T.toneNorm) + T.sp.rowGap
    -- the core temperature's meter: one look per moodle level, green only with no Hypothermia or
    -- Hyperthermia moodle on (the director's call 1, Nov 25 2026)
    do
        local lit, col = ZeD.ThermalTab.coreLook(data.coreTemp, ZeD.ThermalTab.moodleLevel(win._playerObj))
        ZeD.Atoms.drawSegFill(panel, rx, curY, rw, T.fillBarH, ZeD.Atoms.FILL_SEGS, lit, col)
    end
    curY = curY + T.fillBarH + T.px(10)
    curY = curY + M.drawStatRow(panel, rx, curY, rw, ZeD.tr("UI_ZeD_Thermal_Air"),
        ZeD.ThermalTab.tempText(data.airTemp, celsius), T.toneNorm) + T.sp.rowGap
    curY = curY + M.drawStatRow(panel, rx, curY, rw, ZeD.tr("UI_ZeD_Thermal_WindChill"),
        ZeD.ThermalTab.tempText(data.windTemp, celsius), T.toneNorm) + T.sp.rowGap
    -- Body Heat Generation: vanilla's word for where it stands (Low, Normal, High)
    local heat = data.heatGen or 0
    local word = getText(ZeD.TabFill.scaleWord(heat, "IGUI_Temp_Low", "IGUI_Temp_Normal", "IGUI_Temp_High"))
    M.drawStatRow(panel, rx, curY, rw, getText("IGUI_Temp_BodyHeat"), word, T.toneNorm)
end

-- ============================================================================
-- FOOTER BAND: the View pop-up
-- "View: Skin temperature" at the left, nothing at the right; the list opens
-- upward from the box. The same pattern as Craft's sort pop-up: the open list
-- takes every press; the pad's stops become its rows.
-- ============================================================================

local function inRect(r, x, y)
    return r ~= nil and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h
end

--- The pop-up list: opened by the box, shut by a pick, a click anywhere else or B; the pad
--- returns to the box it came from (_thermalReturnToMenu, read by the tab's focusables)
function ZeD.ThermalTab.openMenu(win)
    win._thermalMenuOpen = true
    win._thermalMenuZones = nil
end

--- True while the View list is open (ZeD.Popups lets go of a list its owner shut).
function ZeD.ThermalTab.menuIsOpen(win) return win._thermalMenuOpen == true end

--- Shut the list; pickIdx, when given, becomes the chosen view. The Character
--- window also calls it when the tab is left, the drawer folds or a card opens.
function ZeD.ThermalTab.closeMenu(win, pickIdx)
    if pickIdx then win._thermalView = pickIdx end
    win._thermalMenuOpen = false
    win._thermalMenuZones = nil
    win._thermalReturnToMenu = true
end

--- The mouse path through the band: an open list takes every press (a pick or shut it);
--- else the box opens it. Returns true when the press was the band's.
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
    -- a grid cell (picks it) or the block's head, inside the body's view
    if not (bz and y >= bz.y) and inRect(win._thermalBodyRect, x, y) and ZeD.TabFill.onClick(win, "thermal", x, y) then return true end
    if not bz or y < bz.y or y >= bz.y + bz.h then return false end
    if inRect(bz.box, x, y) then ZeD.ThermalTab.openMenu(win) end
    return true
end

local _bandSpec = {}
local _bandNat = {}   -- the View box's width: the longest view's words

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
    -- (kept while the palette, the language and the measures hold: seven phrases measured every frame otherwise)
    local epoch = ZeD.Text.wordsEpoch()
    local nat = 0
    if epoch and _bandNat.ep == epoch and _bandNat.T == T then
        nat = _bandNat.w
    else
        for _, view in ipairs(VIEWS) do
            local nw = M.popupMenuW(ZeD.tr("UI_ZeD_Thermal_ViewPick", ZeD.ThermalTab.labelOf(view)))
            if nw > nat then nat = nw end
        end
        _bandNat.ep, _bandNat.T, _bandNat.w = epoch, T, nat
    end
    local boxX = x + edge
    local boxW = math.max(T.px(40), math.min(nat, w - edge * 2))
    local hov = (not open) and A.mouseIn(panel, boxX, by, boxW, bh)
    if hov and ZeD.Help then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Thermal_HelpViewMenu")) end
    local view = VIEWS[win._thermalView or 1] or VIEWS[1]
    local viewName = ZeD.ThermalTab.labelOf(view)
    M.drawPopupMenu(panel, boxX, by, boxW, bh, ZeD.tr("UI_ZeD_Thermal_ViewPick", viewName),
        hov or open, focusOf(win, "thermal:view"), false, viewName)   -- (the view alone when both do not fit)
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
    local lw, lh, zs = M.drawSortMenuList(panel, bz.box.x, gy, _menuModes, win._thermalView or 1, hoverId, o)
    win._thermalMenuZones = zs
    -- the list and its box count as inside; a press elsewhere, the tab hidden, an action or a walk shuts it
    -- (ZeD_Popups.lua, the director, Nov 23 2026)
    if ZeD.Popups then
        local po = ZeD.Popups.opts(win, "thermal", ZeD.ThermalTab.menuIsOpen, win.playerNum or 0)
        ZeD.Popups.shownAt(po.key, panel, ZeD.ThermalTab.closeMenu, po,
            bz.box.x, gy, lw, lh, bz.box.x, bz.box.y, bz.box.w, bz.box.h)
    end
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
        local fig = ZeD_BodyFigure:new(0, 0, 100, 100)  -- placeholder size; drawAt() is given the real (scaled) rect
        fig:initialise()
        fig:loadTextures()
        win._thermalBodyFigure = fig
    end
    return win._thermalBodyFigure
end

function ZeD.ThermalTab._drawBodyFigure(panel, win, data, px, py, pw, ph, frame)
    local fig = ZeD.ThermalTab._ensureBodyFigure(win)

    if data.isFemale ~= nil then
        fig:setSex(data.isFemale)
    end

    -- the height chart in the frame's margins, under the controller's mark and the figure (Figure frame, Nov 22 2026)
    if frame then fig:drawChart(panel, frame) end

    -- Color by active view metric
    local viewIdx = win._thermalView or 1
    local view = VIEWS[viewIdx]
    local uiKey = view.id .. "_ui"

    for partName, nodeData in pairs(data.nodes) do
        local uiVal = nodeData[uiKey] or 0
        local color = (view.id == "wetness") and ZeD.ThermalTab.wetColor(uiVal) or getThermalColor(uiVal)
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

--- One grid cell's height (Molecules.drawStatBarRow's row: the larger of F3 / F2 + 8).
function ZeD.ThermalTab.cellH()
    local T, TM = ZeD.T, ZeD.TM
    return math.max(TM:getFontHeight(T.fontF3), TM:getFontHeight(T.fontF2)) + T.px(8)
end

--- The grid's columns at listW wide: 2, or 1 where a half-width cell (Molecules.drawStatBarRow: the value
--- badge, the bar at the right) would leave its part's name under about six letters, as on the 220 card (QA T7).
function ZeD.ThermalTab.gridCols(listW, celsius)
    local T, TM, A = ZeD.T, ZeD.TM, ZeD.Atoms
    if celsius == nil then celsius = ZeD.ThermalTab.useCelsius() end
    local colW = math.floor((listW - T.sp.sm) / 2)
    local barW = math.max(A.fillBarMinW(), math.min(A.rowBarW(), math.floor(colW * 0.4)))
    local valW = math.max(TM:MeasureStringX(T.fontF3, ZeD.ThermalTab.tempText(36.6, celsius)), TM:MeasureStringX(T.fontF3, "100%"))
    local room = colW - T.px(4) - barW - T.px(6) - (valW + T.px(10)) - T.px(6)
    return (room >= TM:MeasureStringX(T.fontF2, "Forear")) and 2 or 1
end

ZeD.ThermalTab._headOpts = {}
function ZeD.ThermalTab._renderCardGrid(panel, win, data, rx, ry, rw, rh)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules

    local listX   = rx
    local listW   = rw

    -- Active view
    local viewIdx = win._thermalView or 1
    local view = VIEWS[viewIdx]
    local celsius = win._thermalCelsiusNow
    if celsius == nil then celsius = ZeD.ThermalTab.useCelsius() end

    local uiKey = view.id .. "_ui"
    local rawKey = view.id

    local drawY = ry

    -- (the Core / Air / Wind readings and the core gauge sit beside the figure: _renderHeader)

    -- Section head: the one section style (design review D6), the tab fill's mono line, 20u with
    -- the content line under it; not folding, so no triangle
    local ho = ZeD.ThermalTab._headOpts
    ho.noArrow, ho.inset, ho.h = true, 0, T.px(20)
    drawY = drawY + M.drawCategoryRow(panel, listX, drawY, listW,
        ZeD.tr("UI_ZeD_Thermal_ByRegion", ZeD.ThermalTab.labelOf(view)), nil, true, ho)
    drawY = drawY + T.sp.xs

    -- Two-column body part grid (one column where two would leave a cell no room for its part's name)
    win._thermalHoverCell = nil
    local colGap = T.sp.sm
    local nCols = ZeD.ThermalTab.gridCols(listW, celsius)
    local colW = (nCols == 2) and math.floor((listW - colGap) / 2) or listW
    local leftY  = drawY
    local rightY = drawY
    local rowGap = T.sp.xs

    for i, partName in ipairs(data.partOrder) do
        local nodeData = data.nodes[partName]

        local isLeft = (nCols == 1) or ((i - 1) % 2 == 0)
        local cx = isLeft and listX or (listX + colW + colGap)
        local cy = isLeft and leftY or rightY

        -- Get values for this view
        local uiVal = nodeData and nodeData[uiKey] or 0
        local rawVal = nodeData and nodeData[rawKey] or 0
        local fillPct = math.max(0, math.min(1, uiVal))
        local fc = (view.id == "wetness") and ZeD.ThermalTab.wetColor(fillPct) or getThermalColor(fillPct)

        -- Format value based on view type
        local valStr
        if view.format == "temp" then
            valStr = ZeD.ThermalTab.tempText(rawVal, celsius)
        else
            valStr = math.floor(fillPct * 100 + 0.5) .. "%"   -- (as the detail box reads it: the director's call 3)
        end

        -- the cell: the picked one in the accent wash, the pointer's hover, the controller's mark; a press
        -- (or A) picks it; pointed at, it shows in the block under the grid
        local cellH = ZeD.ThermalTab.cellH()
        local ids = win._thermalCellIds
        if not ids then ids = {}; win._thermalCellIds = ids end
        local cid = ids[partName]
        if not cid then cid = "fill:thermal:cell:" .. partName; ids[partName] = cid end
        if win._thermalPick == partName then
            local ac = T.accent
            panel:drawRect(cx, cy, colW, cellH, T.selectionA or 0.30, ac.r, ac.g, ac.b)
        end
        if A.mouseIn(panel, cx, cy, colW, cellH, win._thermalBodyRect) then
            local hv = T.hover
            panel:drawRect(cx, cy, colW, cellH, hv.a, hv.r, hv.g, hv.b)
            win._thermalHoverCell = partName
        end
        local fo = ZeD.TabFill.focusOf(win, cid)
        if fo then ZeD.Focus.mark(panel, cx, cy, colW, cellH, fo) end
        local fns = win._thermalPickFns
        if not fns then fns = {}; win._thermalPickFns = fns end
        local fn = fns[partName]
        if not fn then
            local pick = partName
            fn = function() win._thermalPick = pick end
            fns[partName] = fn
        end
        local z = ZeD.TabFill.zone(win, "thermal", cid)
        z.x, z.y, z.w, z.h, z.partName, z.fn, z.read = cx, cy, colW, cellH, partName, fn, false
        local rowH = M.drawStatBarRow(panel, cx, cy, colW, valStr, ZeD.partLabel(partName), fillPct, fc, T.toneNorm, true)

        if nCols == 1 then leftY = cy + rowH + rowGap
        elseif isLeft then leftY = cy + rowH + rowGap
        else rightY = cy + rowH + rowGap end
    end

end

-- ============================================================================
-- THE PICKED REGION (under the grid)
-- The eight readings of one region: the cell or figure part the pointer or the
-- controller is on, else the picked one. Each row: vanilla's name, the value, a
-- stepped bar and vanilla's word for where the bar stands (its clothing panel's
-- scale words). A ZeD_TabFill block, so it folds and its rows are stops.
-- ============================================================================

-- the region the block shows now: a cell or part pointed at, else the pick
local function shownRegion(win, data)
    local p = win._thermalHoverCell or win._thermalActivePart
    if p and data.nodes[p] then return p end
    return win._thermalPick or DEFAULT_PICK
end

local _pickedOpts = {}
local _pickedRows = {}
local _pickedKey = {}   -- what the rows' words were made from (the reading, the region, the unit, the theme)
--- The picked region's block from (x, y), w wide; panel nil only measures. Returns its height.
function ZeD.ThermalTab._renderPicked(panel, win, data, x, y, w)
    local part = shownRegion(win, data)
    local nodeData = data and data.nodes and data.nodes[part]
    if not nodeData then return 0 end
    local F = ZeD.TabFill
    local celsius = win._thermalCelsiusNow
    if celsius == nil then celsius = ZeD.ThermalTab.useCelsius() end
    -- the rows' words are made when the reading, the region, the unit or the theme changes,
    -- not every frame (the measure and the draw of one frame share them)
    local c = _pickedKey
    if c.data == data and c.part == part and c.celsius == celsius and c.T == ZeD.T then
        _pickedOpts.view = win._thermalBodyRect
        return F.block(panel, win, "thermal", "picked", x, y, w, c.title, nil, _pickedRows, _pickedOpts)
    end
    c.data, c.part, c.celsius, c.T, c.title = data, part, celsius, ZeD.T, ZeD.partLabel(part)
    -- the word column as wide as the longest of the words on show
    local wordW = 0
    for i, row in ipairs(DETAIL_ROWS) do
        local uiVal = math.max(0, math.min(1, nodeData[row.getterUI] or 0))
        local r = _pickedRows[i]
        if not r then r = { read = true }; _pickedRows[i] = r end
        if not r.id then r.id = "fill:thermal:row:" .. i end
        r.label = ZeD.ThermalTab.labelOf(row)
        if row.getter == "getSkinCelcius" then r.value = ZeD.ThermalTab.tempText(nodeData[row.getter] or 0, celsius)
        else r.value = math.floor(uiVal * 100 + 0.5) .. "%" end
        local wet = isWetGetter(row.getter)
        r.bar, r.barColor = uiVal, wet and ZeD.ThermalTab.wetColor(uiVal) or getThermalColor(uiVal)
        local sc = row.scale
        r.word = getText(wet and ZeD.ThermalTab.wetWordKey(uiVal) or F.scaleWord(uiVal, sc[1], sc[2], sc[3]))
        wordW = math.max(wordW, ZeD.TM:MeasureStringX(ZeD.T.fontF1, r.word))
    end
    for i = 1, #DETAIL_ROWS do _pickedRows[i].wordW = wordW end
    _pickedOpts.view = win._thermalBodyRect
    return F.block(panel, win, "thermal", "picked", x, y, w, c.title, nil, _pickedRows, _pickedOpts)
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
    -- Measuring with a smaller font under-counts ~4px per row; over nine rows
    -- that clips the bottom row half away.
    local valH = ZeD.TM:getFontHeight(T.fontF3)
    local lblH = ZeD.TM:getFontHeight(T.fontF2)
    local rowH = math.max(valH, lblH) + T.px(8)
    local rowGap = T.sp.xs
    local numRows = math.ceil(#PART_ORDER / ZeD.ThermalTab.gridCols(listW))
    total = total + numRows * (rowH + rowGap)

    return total
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

--- Put the tab's renderer in the Character window's dispatch table, as "thermal".
function ZeD.ThermalTab.register(dispatchTable)
    dispatchTable["thermal"] = ZeD.ThermalTab.render
end
