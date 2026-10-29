-- ZeD-UI/42/media/lua/client/ZeD/HealthTab.lua
-- ============================================================================
-- HEALTH TAB — body figure + dashboard layout.
-- Zone A (fixed): body figure (left) + health summary or hover detail (right).
-- Zone B (scrollable): severity-sorted injury list with condition badges.
-- Adds BodyFigure, replaces flat list with figure+dashboard.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/ZeD_BodyFigure"
require "XpSystem/ISUI/ISHealthPanel"

ZeD = ZeD or {}
ZeD.HealthTab = {}

local function pctToStatusColor(pct)
    local T = ZeD.T
    if pct > 60 then return T.positive
    elseif pct > 30 then return T.warning
    else return T.danger end
end

-- The controller's mark options for the element with this id: set only when the
-- window is the focused one, the controller is in use and that element has the
-- focus (ZeD.Input.Focus.isFocused). Passed to the library's buttons and headers
-- (opts.focus) or to ZeD.Focus.mark.
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
-- ANATOMICAL DISPLAY NAMES (medic-style per feedback rule)
-- Lazy-initialized on first use to ensure BodyPartType Java enum is available.
-- ============================================================================

local PART_NAMES = nil

local function ensurePartNames()
    if PART_NAMES then return end
    PART_NAMES = {
        [BodyPartType.Head]         = "Head",
        [BodyPartType.Neck]         = "Neck",
        [BodyPartType.Torso_Upper]  = "Upper Torso",
        [BodyPartType.Torso_Lower]  = "Lower Torso",
        [BodyPartType.Groin]        = "Groin",
        [BodyPartType.UpperArm_L]   = "Left Upper Arm",
        [BodyPartType.UpperArm_R]   = "Right Upper Arm",
        [BodyPartType.ForeArm_L]    = "Left Forearm",
        [BodyPartType.ForeArm_R]    = "Right Forearm",
        [BodyPartType.Hand_L]       = "Left Hand",
        [BodyPartType.Hand_R]       = "Right Hand",
        [BodyPartType.UpperLeg_L]   = "Left Thigh",
        [BodyPartType.UpperLeg_R]   = "Right Thigh",
        [BodyPartType.LowerLeg_L]   = "Left Shin",
        [BodyPartType.LowerLeg_R]   = "Right Shin",
        [BodyPartType.Foot_L]       = "Left Foot",
        [BodyPartType.Foot_R]       = "Right Foot",
    }
end

local function getPartName(bp)
    ensurePartNames()
    return PART_NAMES[bp:getType()] or BodyPartType.getDisplayName(bp:getType())
end

-- ============================================================================
-- BODY PART TYPE → BODY FIGURE DISPLAY NAME MAPPING
-- BodyFigure uses its own SUFFIX_TO_DISPLAY names; some differ from PART_NAMES.
-- Lazy-initialized alongside PART_NAMES.
-- ============================================================================

local BODY_PART_TYPES = nil

local function ensureBodyPartTypes()
    if BODY_PART_TYPES then return end
    BODY_PART_TYPES = {
        { type = BodyPartType.Head,        figure = "Head" },
        { type = BodyPartType.Neck,        figure = "Neck" },
        { type = BodyPartType.Torso_Upper, figure = "Upper Torso" },
        { type = BodyPartType.Torso_Lower, figure = "Lower Torso" },
        { type = BodyPartType.Groin,       figure = "Groin" },
        { type = BodyPartType.UpperArm_L,  figure = "Left Upper Arm" },
        { type = BodyPartType.UpperArm_R,  figure = "Right Upper Arm" },
        { type = BodyPartType.ForeArm_L,   figure = "Left Forearm" },
        { type = BodyPartType.ForeArm_R,   figure = "Right Forearm" },
        { type = BodyPartType.Hand_L,      figure = "Left Hand" },
        { type = BodyPartType.Hand_R,      figure = "Right Hand" },
        { type = BodyPartType.UpperLeg_L,  figure = "Left Upper Leg" },
        { type = BodyPartType.UpperLeg_R,  figure = "Right Upper Leg" },
        { type = BodyPartType.LowerLeg_L,  figure = "Left Lower Leg" },
        { type = BodyPartType.LowerLeg_R,  figure = "Right Lower Leg" },
        { type = BodyPartType.Foot_L,      figure = "Left Foot" },
        { type = BodyPartType.Foot_R,      figure = "Right Foot" },
    }
end

-- ============================================================================
-- REVERSE LOOKUP: figure display name → BodyPartType enum
-- ============================================================================

local FIGURE_TO_BPTYPE = nil

local function ensureFigureToBPType()
    if FIGURE_TO_BPTYPE then return end
    ensureBodyPartTypes()
    FIGURE_TO_BPTYPE = {}
    for _, entry in ipairs(BODY_PART_TYPES) do
        FIGURE_TO_BPTYPE[entry.figure] = entry.type
    end
    -- Injury rows carry the list name ("Left Thigh", "Left Shin"), which can
    -- differ from the figure's name for the same part: map those too.
    ensurePartNames()
    for bpType, name in pairs(PART_NAMES) do
        if FIGURE_TO_BPTYPE[name] == nil then FIGURE_TO_BPTYPE[name] = bpType end
    end
end

-- ============================================================================
-- SEVERITY ORDERING
-- ============================================================================

local SEV_ORDER = { critical = 1, danger = 2, warning = 3, positive = 4, ok = 5 }

-- a severity's status colour (the square mark carries it; the words stay default); "ok" has none
local SEV_TOKEN = {
    critical = "danger",
    danger   = "danger",
    warning  = "warning",
    positive = "positive",
}
local function sevColor(sev)
    local k = SEV_TOKEN[sev]
    return k and ZeD.T[k] or nil
end

-- A condition tag's width: its words in sentence case plus the tag's side padding
-- and, with a status, its square mark (the same box ZeD.Molecules.drawTag draws).
local function tagW(label, hasMark)
    local T = ZeD.T
    local w = ZeD.TM:MeasureStringX(T.fontF1, ZeD.textCase(label)) + T.px(10)
    if hasMark then w = w + T.px(10) end
    return w
end

-- The condition tags of one part, wrapped in maxW from (x, y); draws them when a
-- panel is given and returns the height they take (0 with none). Measuring and
-- drawing share this one wrap.
local function condTags(panel, conds, x, y, maxW)
    local T = ZeD.T
    local th, gap = T.px(16), T.sp.badgeGap
    local bx, by = 0, 0
    for _, c in ipairs(conds) do
        local col = sevColor(c.severity)
        local bw = tagW(c.label, col ~= nil)
        if bx > 0 and bx + bw > maxW then bx = 0; by = by + th + T.px(2) end
        if panel then ZeD.Molecules.drawTag(panel, x + bx, y + by, c.label, col) end
        bx = bx + bw + gap
    end
    if #conds == 0 then return 0 end
    return by + th
end

-- ============================================================================
-- CONDITION CLASSIFIER
-- ============================================================================

-- What the tab reveals follows vanilla's health panel exactly: a bandage hides
-- infection, a lodged bullet, glass and burns from view; infection shows only
-- to a First Aid 9+ doctor or once it has grown past what the doctor's level
-- can miss; severity words ("Severe", "Moderate", "Good") appear only at the
-- First Aid levels where vanilla's doctor can judge them. doctorLevel is the
-- viewing character's First Aid level.
local function qualify(label, word)
    if word then return ZeD.tr("UI_ZeD_Health_Qualified", label, word) end
    return label
end

local function classifyConditions(bp, doctorLevel)
    local conds = {}
    local doc = doctorLevel or 0
    local cheat = ISHealthPanel and ISHealthPanel.cheat
    local bandaged = bp:bandaged()
    local word

    -- The words are vanilla's own health-panel words where it has them (IGUI_health_*);
    -- the few it lacks are ZeD keys. They are read here, every time the tab re-reads the
    -- body (a few times a second), so a change of language shows within moments.
    if bp:bitten() then
        conds[#conds + 1] = { label = getText("IGUI_health_Bitten"), severity = "critical" }
    end
    if bp:bleeding() then
        conds[#conds + 1] = { label = getText("IGUI_health_Bleeding"), severity = "danger" }
    end
    if bp:deepWounded() then
        word = nil
        if doc > 4 or cheat then
            if bp:getDeepWoundTime() > 10 then word = getText("IGUI_health_Severe")
            elseif bp:getDeepWoundTime() > 8 then word = getText("IGUI_health_Moderate") end
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_DeepWound"), word), severity = "danger" }
    end
    if bp:isInfectedWound() and not bandaged
       and (doc > 8 or bp:getWoundInfectionLevel() * 10 >= (2.5 - doc) or cheat) then
        conds[#conds + 1] = { label = getText("IGUI_health_Infected"), severity = "danger" }
    end
    if bp:getFractureTime() > 0 and bp:getSplintFactor() == 0 then
        word = nil
        if doc > 6 or cheat then
            if bp:getFractureTime() > 50 then word = getText("IGUI_health_Severe")
            elseif bp:getFractureTime() > 20 then word = getText("IGUI_health_Moderate") end
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_Fracture"), word), severity = "danger" }
    end
    if bp:haveBullet() and not bandaged then
        conds[#conds + 1] = { label = getText("IGUI_health_LodgedBullet"), severity = "danger" }
    end
    if bp:haveGlass() and not bandaged then
        conds[#conds + 1] = { label = ZeD.tr("UI_ZeD_Health_GlassShards"), severity = "danger" }
    end

    if bp:scratched() then
        word = nil
        if doc > 2 or cheat then
            if bp:getScratchTime() > 17 then word = getText("IGUI_health_Severe")
            elseif bp:getScratchTime() > 14 then word = getText("IGUI_health_Moderate") end
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_Scratch"), word), severity = "warning" }
    end
    if bp:isCut() then
        word = nil
        if doc > 2 or cheat then
            if bp:getCutTime() > 17 then word = getText("IGUI_health_Severe")
            elseif bp:getCutTime() > 14 then word = getText("IGUI_health_Moderate") end
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_Cut"), word), severity = "warning" }
    end
    if bp:getBurnTime() > 0 and not bandaged then
        word = nil
        if (doc > 4 or cheat) and bp:isNeedBurnWash() then word = ZeD.tr("IGUI_health_NeedCleaning") end
        conds[#conds + 1] = { label = qualify(ZeD.tr("UI_ZeD_Health_Burn"), word), severity = "warning" }
    end

    -- Stiffness / muscle strain (exercise soreness)
    local stiffness = bp:getStiffness()
    if stiffness >= 5 then
        if stiffness < 20 then
            conds[#conds + 1] = { label = getText("IGUI_health_MinorStiffness"), severity = "warning" }
        else
            conds[#conds + 1] = { label = getText("IGUI_health_Stiffness"), severity = "danger" }
        end
    end

    -- Additional pain (from injuries, exercise, etc.)
    local pain = bp:getAdditionalPain()
    if pain > 10 then
        if pain > 50 then
            conds[#conds + 1] = { label = getText("IGUI_health_HeavyPain"), severity = "danger" }
        else
            conds[#conds + 1] = { label = getText("IGUI_health_Pain"), severity = "warning" }
        end
    end

    if bp:bandaged() then
        if bp:getBandageLife() > 0 then
            conds[#conds + 1] = { label = getText("IGUI_health_Bandaged"), severity = "positive" }
        else
            conds[#conds + 1] = { label = getText("IGUI_health_DirtyBandage"), severity = "warning" }
        end
    end
    if bp:stitched() then
        word = nil
        if doc > 6 or cheat then
            word = (bp:getStitchTime() > 40) and getText("IGUI_health_Good") or ZeD.tr("IGUI_health_NeedTime")
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_Stitched"), word), severity = "positive" }
    end
    if bp:getSplintFactor() > 0 then
        word = nil
        if doc > 4 or cheat then
            if bp:getSplintFactor() > 4 then word = getText("IGUI_health_Good")
            elseif bp:getFractureTime() > 2 then word = getText("IGUI_health_Moderate") end
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_Splinted"), word), severity = "positive" }
    end
    -- Poultices on the part, as vanilla lists them
    if bp:getPlantainFactor() > 0 then
        conds[#conds + 1] = { label = getText("ContextMenu_PlantainCataplasm"), severity = "positive" }
    end
    if bp:getComfreyFactor() > 0 then
        conds[#conds + 1] = { label = getText("ContextMenu_ComfreyCataplasm"), severity = "positive" }
    end
    if bp:getGarlicFactor() > 0 then
        conds[#conds + 1] = { label = getText("ContextMenu_GarlicCataplasm"), severity = "positive" }
    end

    table.sort(conds, function(a, b)
        return (SEV_ORDER[a.severity] or 99) < (SEV_ORDER[b.severity] or 99)
    end)

    return conds
end

-- ============================================================================
-- HEALTH-TO-COLOR MAPPING (for body figure)
-- ============================================================================

local function getHealthColor(health)
    local T = ZeD.T
    if health > 80  then return T.positive end
    if health > 50  then return T.warning  end
    if health > 20  then return T.danger   end
    return { r = 0.95, g = 0.15, b = 0.15, a = 1.0 }
end

-- ============================================================================
-- EXTRAS (Oct 29 2026) -- the general way for another mod's support file
-- (ModSupport/<mod id>.lua) to add its own wound details to a body part without
-- touching this file again. Nothing is added until an extra is registered, so the
-- tab is exactly as built without one. An extra is a table:
--   partLines(playerObj, bodyPart)
--       -> nil, or a list of { text = "...", color = {r,g,b}, severity = "danger" |
--          "warning" | "positive" | nil }: the mod's own words for what is wrong with
--          that part. They show in the part's detail view (a status square in the
--          mod's colour, the words in the default ink) and as tags on the part's row
--          in the injury list (the square follows the severity; "warning" when none
--          is given). A part with such a line counts as injured and is listed.
-- Every call goes through pcall; ZeD keeps no copy of the mod's data (the lines are
-- read again each time the tab re-reads the body). First used by
-- ModSupport/WoundExpansion.lua.
-- ============================================================================
ZeD.HealthTab.extras = ZeD.HealthTab.extras or {}

function ZeD.HealthTab.addExtras(id, def)
    for i, e in ipairs(ZeD.HealthTab.extras) do
        if e.id == id then ZeD.HealthTab.extras[i] = def; def.id = id; return end
    end
    def.id = id
    ZeD.HealthTab.extras[#ZeD.HealthTab.extras + 1] = def
end

-- Every extra's lines for one body part, in one list (nil when there are none).
-- A mod that errors, or answers with something odd, is skipped; the tab goes on.
local function extraLines(playerObj, bp)
    local out = nil
    for _, e in ipairs(ZeD.HealthTab.extras) do
        if e.partLines then
            local ok, lines = pcall(e.partLines, playerObj, bp)
            if ok and type(lines) == "table" then
                for _, ln in ipairs(lines) do
                    if type(ln) == "table" and type(ln.text) == "string" and ln.text ~= "" then
                        out = out or {}
                        out[#out + 1] = ln
                    end
                end
            end
        end
    end
    return out
end

-- A copy of a part's conditions with the extras' lines added as tags, each placed
-- after the conditions of equal or higher severity (so vanilla's order is kept).
local function withExtraTags(conds, extra)
    local out = {}
    for _, c in ipairs(conds) do out[#out + 1] = c end
    for _, ln in ipairs(extra) do
        local tag = { label = ln.text, severity = ln.severity or "warning" }
        local rank = SEV_ORDER[tag.severity] or 99
        local at = #out + 1
        for i, c in ipairs(out) do
            if (SEV_ORDER[c.severity] or 99) > rank then at = i; break end
        end
        table.insert(out, at, tag)
    end
    return out
end

-- ============================================================================
-- DATA AGGREGATION
-- Extended for body figure: partHealth + condsByFigureName.
-- ============================================================================

function ZeD.HealthTab.gatherData(playerObj)
    ensurePartNames()
    ensureBodyPartTypes()

    local bd = playerObj:getBodyDamage()
    local parts = bd:getBodyParts()
    local overall = bd:getOverallBodyHealth()

    local entries = {}
    local partHealth = {}        -- figureName → health%
    local condsByFigureName = {} -- figureName → conditions array
    local extraByFigureName = {} -- figureName → other mods' lines (see EXTRAS above)

    -- Build a lookup: BodyPartType → figure name
    local typeToFigure = {}
    for _, bp in ipairs(BODY_PART_TYPES) do
        typeToFigure[bp.type] = bp.figure
    end

    -- The viewer is the patient here, so the patient's First Aid is the doctor's
    local doctorLevel = playerObj:getPerkLevel(Perks.Doctor)

    for i = 1, parts:size() do
        local bp = parts:get(i - 1)
        local health = bp:getHealth()
        local conds = classifyConditions(bp, doctorLevel)
        -- other mods' wound details for this part (nil without any); the injury list
        -- carries them as tags too, the detail view draws them as lines
        local extra = extraLines(playerObj, bp)
        local listConds = extra and withExtraTags(conds, extra) or conds
        local bpType = bp:getType()
        local figureName = typeToFigure[bpType]

        -- Store health and conditions for ALL parts (figure needs full map)
        if figureName then
            partHealth[figureName] = health
            if #conds > 0 then
                condsByFigureName[figureName] = conds
            end
            if extra then
                extraByFigureName[figureName] = extra
            end
        end

        -- Injury list: parts with conditions, reduced health, stiffness, or pain
        local stiffness = bp:getStiffness()
        local pain = bp:getAdditionalPain()
        if #listConds > 0 or health < 95 or stiffness >= 5 or pain > 10 then
            local worstSev = "ok"
            if #listConds > 0 then
                worstSev = listConds[1].severity
            end
            entries[#entries + 1] = {
                name       = getPartName(bp),
                health     = health,
                conditions = listConds,
                worstSev   = worstSev,
            }
        end
    end

    table.sort(entries, function(a, b)
        local sa = SEV_ORDER[a.worstSev] or 99
        local sb = SEV_ORDER[b.worstSev] or 99
        if sa ~= sb then return sa < sb end
        return a.health < b.health
    end)

    return {
        overall           = overall,
        entries           = entries,
        totalParts        = parts:size(),
        injuredCount      = #entries,
        -- S123: "injured" means a wound/condition; reduced health alone (hunger,
        -- sickness, cold) is listed but not called an injury.
        woundedCount      = (function() local c = 0; for _, e in ipairs(entries) do if #e.conditions > 0 then c = c + 1 end end; return c end)(),
        partHealth        = partHealth,
        condsByFigureName = condsByFigureName,
        extraByFigureName = extraByFigureName,
        isFemale         = playerObj:isFemale(),
    }
end

-- ============================================================================
-- BODY FIGURE HELPERS
-- ============================================================================

function ZeD.HealthTab._ensureBodyFigure(win)
    if not win._healthBodyFigure then
        local fig = ZeD_BodyFigure:new(0, 0, 100, 100)  -- S124 scale: placeholder size, drawAt() is given the real (scaled) rect
        fig:initialise()
        fig:loadTextures()
        win._healthBodyFigure = fig
    end
    return win._healthBodyFigure
end

function ZeD.HealthTab._drawBodyFigure(panel, win, data, px, py, pw, ph)
    local fig = ZeD.HealthTab._ensureBodyFigure(win)

    if data.isFemale ~= nil then
        fig:setSex(data.isFemale)
    end

    -- Color every part by health percentage (always visible, green when healthy)
    fig:clearColors()
    for figureName, health in pairs(data.partHealth) do
        local color = getHealthColor(health)
        fig:setPartColor(figureName, color.r, color.g, color.b, 0.65)
    end

    -- S103: read the authoritative _healthActivePart resolved at the top of
    -- HealthTab.render (gp focus overrides mouse hover). Replaces the inline
    -- Focus lookup that S101 used — single source of truth now that the
    -- detail-view branch and the figure both consume the same value.
    fig.selectedPart = win._healthActivePart or nil

    -- the controller's mark on a focused part: its washes go under the figure (this
    -- frame's rects are the last frame's, which the figure keeps), the hand beside it
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

    fig:drawAt(panel, px, py, pw, ph)
end

-- ============================================================================
-- CLICK-TO-TREAT: open vanilla treatment context menu for clicked body part
-- Uses a thin adapter to call ISHealthPanel:doBodyPartContextMenu, reusing
-- all 13 treatment handlers without duplication.
-- ============================================================================

function ZeD.HealthTab._onPartClicked(win, figureName, drawerPanel, relX, relY)
    ensureFigureToBPType()
    local bpType = FIGURE_TO_BPTYPE[figureName]
    if not bpType then return end

    local playerObj = win._playerObj
    if not playerObj then return end

    local bp = playerObj:getBodyDamage():getBodyPart(bpType)
    if not bp then return end

    -- Gamepad path may pass nil drawerPanel/relX/relY — fall back to the
    -- health content panel stashed during render, else the window itself.
    local anchor = drawerPanel or win._healthContentPanel or win
    local rX = relX or 0
    local rY = relY or 0

    -- Adapter mimicking ISHealthPanel for doBodyPartContextMenu
    local adapter = {
        character       = playerObj,
        otherPlayer     = nil,
        blockingMessage = nil,
        actions         = {},
    }
    function adapter:getDoctor() return self.otherPlayer or self.character end
    -- (vanilla's ISHealthPanel:getPatient; a mod's treatment entries ask for it, e.g. Wound Expansion's)
    function adapter:getPatient() return self.character end
    function adapter:getAbsoluteX() return anchor:getAbsoluteX() end
    function adapter:getAbsoluteY() return anchor:getAbsoluteY() end
    adapter.checkItems          = ISHealthPanel.checkItems
    adapter.checkContainerItems = ISHealthPanel.checkContainerItems

    ISHealthPanel.doBodyPartContextMenu(adapter, bp, rX, rY)
end

-- ============================================================================
-- ZONE A RIGHT COLUMN: DEFAULT HEADER (summary dashboard)
-- Returns curY (bottom of Zone A header content).
-- ============================================================================

function ZeD.HealthTab._renderHeader(panel, win, data, rx, ry, rw)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules

    local secH  = ZeD.TM:getFontHeight(T.fontF1)

    local curY = ry

    -- Overall stat row: the status is the square mark, the figure stays default text
    local pct = math.floor(data.overall + 0.5)
    local pctColor = pctToStatusColor(pct)
    local rowH = M.drawStatRowDot(panel, rx, curY, rw, ZeD.tr("UI_ZeD_Health_Overall"), pct .. "%", pctColor)
    curY = curY + rowH + T.sp.rowGap

    -- Fill bar
    local barH = M.drawFillBar(panel, rx, curY, rw, data.overall / 100)
    curY = curY + barH + T.sp.xs

    -- Summary line
    -- S123: count WOUNDS, not low health. A hungry character with every part
    -- at 77% is not "17 of 17 injured"; low health shows as a dim note.
    local wounded = data.woundedCount or data.injuredCount
    if wounded == 0 then
        local dotSz = T.px(6)
        local dotGap = T.px(4)
        local bodyFH = ZeD.TM:getFontHeight(T.fontF2)
        local dotC = (data.injuredCount > 0) and T.warning or T.positive
        A.drawStatusDot(panel, rx, curY + math.floor((bodyFH - dotSz) / 2), dotC, dotSz)
        A.drawBody(panel, (data.injuredCount > 0) and ZeD.tr("UI_ZeD_Health_NoInjuriesLow") or ZeD.tr("UI_ZeD_Health_NoInjuries"), rx + dotSz + dotGap, curY)
    else
        A.drawBody(panel, ZeD.tr("UI_ZeD_Health_InjuredOf", wounded, data.totalParts), rx, curY)
    end
    curY = curY + secH + T.sp.sm

    -- Exercise buttons
    curY = ZeD.HealthTab._renderExerciseButtons(panel, win, rx, curY, rw)

    return curY
end

-- ============================================================================
-- ZONE A RIGHT COLUMN: HOVER DETAIL VIEW
-- Shows health + conditions for the hovered body part.
-- Returns curY (bottom of detail content).
-- ============================================================================

function ZeD.HealthTab._renderDetailView(panel, win, data, figureName, rx, ry, rw)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules

    local secH  = ZeD.TM:getFontHeight(T.fontF1)

    local health = data.partHealth[figureName] or 100
    local conds = data.condsByFigureName[figureName]

    local curY = ry

    -- Health % stat row
    local pct = math.floor(health + 0.5)
    local pctColor = pctToStatusColor(pct)
    local rowH = M.drawStatRowDot(panel, rx, curY, rw, getText("IGUI_XP_Health"), pct .. "%", pctColor)
    curY = curY + rowH + T.sp.rowGap

    -- Health fill bar
    local barH = M.drawFillBar(panel, rx, curY, rw, health / 100)
    curY = curY + barH + T.sp.sm

    -- Other mods' wound details for this part (HealthTab.addExtras)
    local extra = data.extraByFigureName and data.extraByFigureName[figureName]
    win._healthExtraShown = extra and #extra or 0   -- (what the QA scripts read)

    -- Condition tags (or "Healthy")
    if conds and #conds > 0 then
        curY = curY + condTags(panel, conds, rx, curY, rw) + T.sp.xs
    elseif not extra then
        local dotSz = T.px(6)
        local dotGap = T.px(4)
        A.drawStatusDot(panel, rx, curY + math.floor((secH - dotSz) / 2), T.positive, dotSz)
        A.drawSecondary(panel, ZeD.tr("UI_ZeD_Health_Healthy"), rx + dotSz + dotGap, curY)
        curY = curY + secH + T.sp.xs
    end

    -- The extras' lines, one status square each in the mod's own colour, the mod's
    -- own words beside it in the default ink (wrapped to the column)
    if extra then
        local f2 = T.fontF2
        local fh = ZeD.TM:getFontHeight(f2)
        local dotSz, dotGap = T.px(6), T.px(4)
        local textW = math.max(T.px(20), rw - dotSz - dotGap)
        for _, ln in ipairs(extra) do
            local wrapped = A.wrapText(ln.text, f2, textW)
            A.drawStatusDot(panel, rx, curY + math.floor((fh - dotSz) / 2), ln.color or T.warning, dotSz)
            for _, piece in ipairs(wrapped) do
                A.drawBody(panel, piece, rx + dotSz + dotGap, curY)
                curY = curY + fh + T.px(2)
            end
        end
        curY = curY + T.sp.xs
    end

    return curY
end

-- ============================================================================
-- EXERCISE SYSTEM
-- ============================================================================

-- Bodyweight exercises (two-column grid)
local EXERCISE_BODYWEIGHT = {
    "squats", "pushups", "situp", "burpees",
}

-- Equipment exercises (full-width rows below bodyweight)
local EXERCISE_EQUIPMENT = {
    "barbellcurl", "dumbbellpress", "bicepscurl",
}

-- vkey = vanilla's own word for the exercise (key = a ZeD phrase, none left today)
local EXERCISE_LABELS = {
    squats        = { vkey = "IGUI_Squats" },
    pushups       = { vkey = "IGUI_PushUps" },
    situp         = { vkey = "IGUI_SitUps" },
    burpees       = { vkey = "IGUI_Burpees" },
    barbellcurl   = { vkey = "IGUI_BarbellCurl" },
    dumbbellpress = { vkey = "IGUI_DumbbellPress" },
    bicepscurl    = { vkey = "IGUI_BicepsCurl" },
}

-- the exercise's name in the player's language (an unknown exercise id shows as is)
function ZeD.HealthTab.exerciseLabel(exeId)
    local d = EXERCISE_LABELS[exeId]
    if not d then return exeId end
    if d.vkey then return getText(d.vkey) end
    return ZeD.tr(d.key)
end

-- Session length, as vanilla's fitness window sets it: 10 to 60 minutes in
-- steps of 10, starting at 10. The choice lives on the window.
local DEFAULT_EXERCISE_TIME = 10  -- minutes
local MIN_EXERCISE_TIME     = 10
local MAX_EXERCISE_TIME     = 60
local EXERCISE_TIME_STEP    = 10

function ZeD.HealthTab.getExerciseMinutes(win)
    local m = win and win._healthExerciseMinutes or DEFAULT_EXERCISE_TIME
    return math.max(MIN_EXERCISE_TIME, math.min(MAX_EXERCISE_TIME, m))
end

-- Why vanilla's fitness window greys its OK button, as the translation key of
-- the tooltip it shows (vanilla ISFitnessUI:updateButtons: later rules
-- overwrite earlier ones, so the last that applies is the one shown). Nil when
-- none of the five apply. Climbing greys the button with no tooltip.
local function exerciseBlockKey(playerObj)
    local moodles = playerObj:getMoodles()
    local key = nil
    if moodles:getMoodleLevel(MoodleType.ENDURANCE) > 2 then key = "Tooltip_TooExhaustedFitness" end
    if moodles:getMoodleLevel(MoodleType.HEAVY_LOAD) > 2 then key = "Tooltip_TooHeavyFitness" end
    if playerObj:getVariableBoolean("sitonground") or playerObj:isSittingOnFurniture() then
        key = "Tooltip_StandStillFitness"
    end
    if playerObj:getVehicle() then key = "Tooltip_CantDriveAndFitness" end
    if moodles:getMoodleLevel(MoodleType.PAIN) > 3 then key = "Tooltip_TooMuchPainFitness" end
    return key
end

-- Global condition check (same rules as vanilla ISFitnessUI:updateButtons)
local function canExercise(playerObj)
    if exerciseBlockKey(playerObj) then return false end
    if playerObj:isClimbing() then return false end
    return true
end

-- Per-exercise item check
local function isExerciseAvailable(playerObj, exerciseId)
    if not FitnessExercises or not FitnessExercises.exercisesType then return false end
    local exeData = FitnessExercises.exercisesType[exerciseId]
    if not exeData then return false end
    if exeData.item then
        return playerObj:getInventory():contains(exeData.item, true)
    end
    return true
end

-- ----------------------------------------------------------------------------
-- EXERCISE INFO: what vanilla's fitness window says about the chosen exercise.
-- Same sources as vanilla ISFitnessUI: the exercise's tooltip from
-- FitnessExercises, one stiffness line per legs / arms / abs entry of its
-- stiffness list (chest has no line in vanilla), the Regularity bar from the
-- player's Fitness, the "(Requires X)" note for a missing item, and the reason
-- vanilla gives for greying OK. Vanilla's own words throughout.
-- ----------------------------------------------------------------------------

local STIFFNESS_KEYS = {
    legs = "IGUI_Fitness_LegsStiffness",
    arms = "IGUI_Fitness_ArmsStiffness",
    abs  = "IGUI_Fitness_AbsStiffness",
}

local _fitnessInitTried = {}  -- player number -> true once Fitness:init was tried for a missing regularity

-- The player's regularity for one exercise, 0 to 1 (vanilla bar = regularity / 100). Nil if unreadable.
local function readRegularity(playerObj, exeId)
    local fitness = playerObj:getFitness()
    if not fitness then return nil end
    local ok, v = pcall(function() return fitness:getRegularity(exeId) end)
    if (not ok or type(v) ~= "number") and not _fitnessInitTried[playerObj:getPlayerNum()] then
        -- vanilla's window calls init() when it opens; do the same once if the map was never filled
        _fitnessInitTried[playerObj:getPlayerNum()] = true
        pcall(function() fitness:init() end)
        ok, v = pcall(function() return fitness:getRegularity(exeId) end)
    end
    if not ok or type(v) ~= "number" then return nil end
    return math.max(0, math.min(1, v / 100))
end

-- Everything vanilla shows for one exercise, as data:
--   { id, name, desc, stiff = { text... }, warn = { text... }, regularity = 0..1 or nil }
-- skipReg: leave the regularity out (the layout reserve does not need it).
function ZeD.HealthTab.exerciseInfo(playerObj, exeId, skipReg)
    if not playerObj or not FitnessExercises or not FitnessExercises.exercisesType then return nil end
    local exeData = FitnessExercises.exercisesType[exeId]
    if not exeData then return nil end
    local info = {
        id    = exeId,
        name  = ZeD.HealthTab.exerciseLabel(exeId),
        desc  = exeData.tooltip,
        stiff = {},
        warn  = {},
    }
    if exeData.stiffness then
        for part in string.gmatch(exeData.stiffness, "[^,]+") do
            local key = STIFFNESS_KEYS[part]
            if key then info.stiff[#info.stiff + 1] = getText(key) end
        end
    end
    if exeData.item and not isExerciseAvailable(playerObj, exeId) then
        local itemName = getItemDisplayName and getItemDisplayName(exeData.item) or exeData.item
        info.warn[#info.warn + 1] = getText("IGUI_FitnessNeedItem", itemName)
    end
    local blockKey = exerciseBlockKey(playerObj)
    if blockKey then info.warn[#info.warn + 1] = getText(blockKey) end
    if not skipReg then info.regularity = readRegularity(playerObj, exeId) end
    return info
end

-- Lays the info out for a column width w (no drawing): returns { items, h }.
-- Items carry their y inside the block; drawExerciseInfo paints them.
local function layoutExerciseInfo(info, w)
    local T, A, TM = ZeD.T, ZeD.Atoms, ZeD.TM
    local f1, f2 = T.fontF1, T.fontF2
    local h1, h2 = TM:getFontHeight(f1), TM:getFontHeight(f2)
    local lg, sg = T.px(2), T.sp.xs
    local dotSz, dotGap = T.px(6), T.px(4)
    local items, y = {}, 0

    items[#items + 1] = { kind = "name", y = y, text = A.truncateText(info.name, f2, w) }
    y = y + h2 + sg

    -- (the game's description is prose: F2, in the secondary ink)
    if info.desc and info.desc ~= "" then
        local lines = A.wrapText(info.desc, f2, w)
        items[#items + 1] = { kind = "lines", y = y, lines = lines, sec = true, fh = h2, lg = lg }
        y = y + #lines * (h2 + lg) + sg
    end

    for _, s in ipairs(info.stiff) do
        local lines = A.wrapText(s, f2, w)
        items[#items + 1] = { kind = "lines", y = y, lines = lines, sec = false, fh = h2, lg = lg }
        y = y + #lines * (h2 + lg) + sg
    end

    -- Regularity: vanilla's word over its bar (the bar's room is always reserved)
    items[#items + 1] = { kind = "bar", y = y, text = getText("IGUI_FitnessRegularity"), fh = h1, lg = lg }
    y = y + h1 + lg + T.fillBarH + sg

    for _, s in ipairs(info.warn) do
        local lines = A.wrapText(s, f2, math.max(T.px(20), w - dotSz - dotGap))
        items[#items + 1] = { kind = "warn", y = y, lines = lines, fh = h2, lg = lg,
                              dotSz = dotSz, dotGap = dotGap }
        y = y + #lines * (h2 + lg) + sg
    end

    return { items = items, h = y }
end

local function drawExerciseInfo(panel, x, y, w, lay, info)
    local T, A = ZeD.T, ZeD.Atoms
    for _, it in ipairs(lay.items) do
        local iy = y + it.y
        if it.kind == "name" then
            A.drawBody(panel, it.text, x, iy, T.textHead)
        elseif it.kind == "lines" then
            for i, line in ipairs(it.lines) do
                local ly = iy + (i - 1) * (it.fh + it.lg)
                if it.sec then A.drawBody(panel, line, x, ly, T.textSec)
                else A.drawBody(panel, line, x, ly) end
            end
        elseif it.kind == "bar" then
            if info.regularity then
                A.drawSecondary(panel, it.text, x, iy)
                A.drawFillBar(panel, x, iy + it.fh + it.lg, w, info.regularity, false, T.positive)
            end
        elseif it.kind == "warn" then
            -- status dot + default text (warning colour lives on the dot only)
            A.drawStatusDot(panel, x, iy + math.floor((it.fh - it.dotSz) / 2), T.warningText, it.dotSz)
            for i, line in ipairs(it.lines) do
                A.drawBody(panel, line, x + it.dotSz + it.dotGap, iy + (i - 1) * (it.fh + it.lg))
            end
        end
    end
end

-- Which exercise the info describes: the pad's focused pill or the mouse's
-- hovered pill (the pad leads unless the mouse is the active device), else the
-- last one started, else vanilla's preselected squats.
local function pickInfoExercise(win, hoverId)
    local focusId = nil
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if Focus and Focus.getFocusedWindow and Focus.getFocusedElement
       and Focus.getFocusedWindow() == win then
        local el = Focus.getFocusedElement(win)
        local id = el and el.exerciseId
        if id and not string.find(tostring(id), "^time:") then focusId = id end
    end
    local det = ZeD and ZeD.Input and ZeD.Input.Detector
    local kbm = det and det.getMode and det.getMode() == "kbm"
    local id
    if kbm then id = hoverId or focusId else id = focusId or hoverId end
    return id or win._healthExerciseSel or "squats"
end

-- Start exercise (replicates vanilla ISFitnessUI:equipItems + onClick OK)
function ZeD.HealthTab._startExercise(playerObj, exerciseId, minutes)
    if not FitnessExercises or not FitnessExercises.exercisesType then return end
    local exeData = FitnessExercises.exercisesType[exerciseId]
    if not exeData then return end

    -- Check item requirement
    if exeData.item and not playerObj:getInventory():contains(exeData.item, true) then
        return
    end

    -- Equip/unequip (replicate vanilla ISFitnessUI:equipItems)
    if not exeData.prop then
        ISInventoryPaneContextMenu.unequipItem(playerObj:getPrimaryHandItem(), playerObj:getPlayerNum())
        if not playerObj:isItemInBothHands(playerObj:getPrimaryHandItem()) then
            ISInventoryPaneContextMenu.unequipItem(playerObj:getSecondaryHandItem(), playerObj:getPlayerNum())
        end
    end
    if exeData.prop == "twohands" then
        ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), exeData.item, true, true)
    end
    if exeData.prop == "primary" or exeData.prop == "switch" then
        ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), exeData.item, true, false)
        playerObj:setSecondaryHandItem(nil)
    end

    -- Remove worn containers (bags) — vanilla pattern
    local wornItems = playerObj:getWornItems()
    for i = 0, wornItems:size() - 1 do
        local item = wornItems:get(i):getItem()
        if item and instanceof(item, "InventoryContainer") then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, item, 50))
        end
    end

    -- Initialize fitness system and start exercise action for the chosen time
    local fitness = playerObj:getFitness()
    fitness:init()
    fitness:setCurrentExercise(exeData.type)

    local action = ISFitnessAction:new(playerObj, exerciseId, minutes or DEFAULT_EXERCISE_TIME, exeData, exeData.type)
    ISTimedActionQueue.addGetUpAndThen(playerObj, action)
end

-- Runs one zone of the exercise area, for the mouse and the pad alike: a pill
-- starts its exercise for the chosen time; the - and + buttons step the time.
-- Returns true when the zone did something.
function ZeD.HealthTab.activateExerciseZone(win, zone)
    if not win or not zone or not zone.enabled then return false end
    if zone.timeStep then
        local m = ZeD.HealthTab.getExerciseMinutes(win) + zone.timeStep
        win._healthExerciseMinutes = math.max(MIN_EXERCISE_TIME, math.min(MAX_EXERCISE_TIME, m))
        return true
    end
    win._healthExerciseSel = zone.id   -- the info below keeps describing the exercise just started
    ZeD.HealthTab._startExercise(win._playerObj, zone.id, ZeD.HealthTab.getExerciseMinutes(win))
    return true
end

-- Render exercise buttons:
-- Bodyweight = two-column grid, Equipment = full-width rows below. Each is a push
-- button (the hover wash, the controller's mark and the footer's help come with it).
function ZeD.HealthTab._renderExerciseButtons(panel, win, rx, ry, rw)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules
    local font = T.fontF3
    local secH = ZeD.TM:getFontHeight(font)
    local btnH = T.buttonH
    local gap  = T.sp.xs
    local colGap = T.sp.sm
    local colW = math.floor((rw - colGap) / 2)

    local playerObj = win._playerObj
    local globalEnabled = canExercise(playerObj)

    -- Check if already exercising
    local isExercising = false
    local actionQueue = ISTimedActionQueue.getTimedActionQueue(playerObj)
    if actionQueue and actionQueue.queue and actionQueue.queue[1] then
        isExercising = actionQueue.queue[1].Type == "ISFitnessAction"
    end

    local curY = ry

    win._healthExerciseZones = {}
    local zoneIdx = 0

    -- Bodyweight exercises: two-column grid
    local leftY  = curY
    local rightY = curY

    -- The pointer over a button picks which exercise the info below describes (a
    -- disabled one too); the hover wash itself comes from the push button.
    local hoverId = nil
    local mouseX, mouseY = panel:getMouseX(), panel:getMouseY()
    local view = win._healthView
    local mouseIn = mouseX >= 0 and mouseY >= 0
        and mouseX < panel:getWidth() and mouseY < panel:getHeight()
        and (not view or (mouseX >= view.x and mouseX < view.x + view.w and mouseY >= view.y and mouseY < view.y + view.h))
    local function overBtn(exeId, bx, by, bw, bh)
        if not mouseIn then return false end
        if mouseX < bx or mouseX >= bx + bw or mouseY < by or mouseY >= by + bh then return false end
        if not string.find(tostring(exeId), "^time:") then hoverId = exeId end
        return true
    end

    local mins = ZeD.HealthTab.getExerciseMinutes(win)
    local btnOpts = {}
    local function exerciseBtn(exeId, label, bx, by, bw, enabled)
        local hover = overBtn(exeId, bx, by, bw, btnH) and A.mouseIn(panel, bx, by, bw, btnH)
        btnOpts.hover, btnOpts.disabled = hover, not enabled
        btnOpts.focus = focusOf(win, "exercise:" .. exeId)
        btnOpts.win = win
        btnOpts.help = ZeD.tr("UI_ZeD_Health_HelpExercise", label, mins)
        M.drawButton(panel, bx, by, bw, btnH, A.truncateText(label, font, bw - T.px(12)), "default", false, nil, btnOpts)
    end

    for idx, exeId in ipairs(EXERCISE_BODYWEIGHT) do
        local label = ZeD.HealthTab.exerciseLabel(exeId)
        local enabled = globalEnabled and not isExercising and isExerciseAvailable(playerObj, exeId)

        local isLeft = ((idx - 1) % 2 == 0)
        local bx = isLeft and rx or (rx + colW + colGap)
        local by = isLeft and leftY or rightY

        exerciseBtn(exeId, label, bx, by, colW, enabled)

        zoneIdx = zoneIdx + 1
        win._healthExerciseZones[zoneIdx] = {
            id = exeId,
            x = bx, y = by, w = colW, h = btnH,
            enabled = enabled,
        }

        if isLeft then leftY = by + btnH + gap
        else rightY = by + btnH + gap end
    end

    curY = math.max(leftY, rightY)

    -- Equipment exercises: full-width rows
    for _, exeId in ipairs(EXERCISE_EQUIPMENT) do
        local label = ZeD.HealthTab.exerciseLabel(exeId)
        local enabled = globalEnabled and not isExercising and isExerciseAvailable(playerObj, exeId)

        exerciseBtn(exeId, label, rx, curY, rw, enabled)

        zoneIdx = zoneIdx + 1
        win._healthExerciseZones[zoneIdx] = {
            id = exeId,
            x = rx, y = curY, w = rw, h = btnH,
            enabled = enabled,
        }

        curY = curY + btnH + gap
    end

    -- Session time: label on the left, [-] minutes [+] on the right: two push
    -- buttons around a readout. The time can be changed while exercising; it
    -- applies to the next start.
    local f3H    = ZeD.TM:getFontHeight(font)
    local readW  = ZeD.TM:MeasureStringX(font, "60") + T.px(16)
    local incX   = rx + rw - btnH
    local readX  = incX - readW
    local decX   = readX - btnH
    local canDec = mins > MIN_EXERCISE_TIME
    local canInc = mins < MAX_EXERCISE_TIME
    A.drawSecondary(panel, A.truncateText(getText("IGUI_FitnessTime"), T.fontF1, math.max(0, decX - rx - T.sp.sm)),
        rx, curY + math.floor((btnH - ZeD.TM:getFontHeight(T.fontF1)) / 2))
    btnOpts.win = win
    btnOpts.hover, btnOpts.disabled = overBtn("time:dec", decX, curY, btnH, btnH) and A.mouseIn(panel, decX, curY, btnH, btnH), not canDec
    btnOpts.focus = focusOf(win, "exercise:time:dec")
    btnOpts.help = ZeD.tr("UI_ZeD_Health_HelpTimeLess")
    M.drawButton(panel, decX, curY, btnH, btnH, "-", "default", false, nil, btnOpts)
    local minStr = tostring(mins)
    local tc = T.text
    panel:drawText(minStr, readX + math.floor((readW - ZeD.TM:MeasureStringX(font, minStr)) / 2),
        curY + math.floor((btnH - f3H) / 2), tc.r, tc.g, tc.b, tc.a or 1, font)
    btnOpts.hover, btnOpts.disabled = overBtn("time:inc", incX, curY, btnH, btnH) and A.mouseIn(panel, incX, curY, btnH, btnH), not canInc
    btnOpts.focus = focusOf(win, "exercise:time:inc")
    btnOpts.help = ZeD.tr("UI_ZeD_Health_HelpTimeMore")
    M.drawButton(panel, incX, curY, btnH, btnH, "+", "default", false, nil, btnOpts)
    win._healthExerciseZones[zoneIdx + 1] = {
        id = "time:dec", timeStep = -EXERCISE_TIME_STEP,
        x = decX, y = curY, w = btnH, h = btnH, enabled = canDec,
    }
    win._healthExerciseZones[zoneIdx + 2] = {
        id = "time:inc", timeStep = EXERCISE_TIME_STEP,
        x = incX, y = curY, w = btnH, h = btnH, enabled = canInc,
    }
    curY = curY + btnH + gap

    -- What vanilla's fitness window says about the exercise: description,
    -- stiffness, regularity, warnings
    curY = ZeD.HealthTab._renderExerciseInfo(panel, win, rx, curY, rw, hoverId)

    return curY
end

-- Divider, then the info block for the chosen exercise (see pickInfoExercise).
-- The block's room is reserved for the tallest exercise (_measureExerciseInfo),
-- so hovering from one pill to the next never moves what is below.
function ZeD.HealthTab._renderExerciseInfo(panel, win, rx, ry, rw, hoverId)
    local T, A = ZeD.T, ZeD.Atoms
    local info = ZeD.HealthTab.exerciseInfo(win._playerObj, pickInfoExercise(win, hoverId))
    if not info then return ry end
    local w = math.min(rw, win._healthInfoW or rw)
    A.drawDividerH(panel, rx, ry, rw)
    local y = ry + T.px(1) + T.sp.afterGroove
    -- the wrapped lines only change with the exercise, the width, the fonts or the warnings:
    -- measured once, not every frame
    local TM = ZeD.TM
    local sig = table.concat({ info.id, tostring(w), tostring(T.scale), TM:getFontHeight(T.fontF1),
                               TM:getFontHeight(T.fontF2), info.name, tostring(info.desc), #info.stiff,
                               table.concat(info.warn, "|") }, "|")
    local cached = win._healthInfoLay
    local lay
    if cached and cached.sig == sig then
        lay = cached.lay
    else
        lay = layoutExerciseInfo(info, w)
        win._healthInfoLay = { sig = sig, lay = lay }
    end
    drawExerciseInfo(panel, rx, y, w, lay, info)
    win._healthInfoShown = info.id   -- which exercise the block described this frame (QA reads it)
    win._healthInfoUsedH = lay.h
    return y + math.max(win._healthInfoH or 0, lay.h)
end

-- Room the info block takes in the right column: divider + gap + the tallest
-- exercise's block at the narrowest column width (scrollbar present). Stamps
-- _healthInfoW / _healthInfoH on the window for the renderer. Cached on what
-- changes the layout (width, fonts, which warnings apply).
function ZeD.HealthTab._measureExerciseInfo(win, w)
    local T, TM = ZeD.T, ZeD.TM
    local playerObj = win and win._playerObj
    if not playerObj or not FitnessExercises or not FitnessExercises.exercisesType then return 0 end
    local wrapW = math.max(T.px(60), ZeD.Molecules.layoutZoneA(0, 0, w - T.sp.scrollbarW, 0, 0).rightW)
    local sig = { wrapW, tostring(T.scale), TM:getFontHeight(T.fontF1), TM:getFontHeight(T.fontF2),
                  exerciseBlockKey(playerObj) or "-" }
    for _, exeId in ipairs(EXERCISE_EQUIPMENT) do
        sig[#sig + 1] = isExerciseAvailable(playerObj, exeId) and "1" or "0"
    end
    local key = table.concat(sig, "|")
    local cache = win._healthInfoCache
    if not cache or cache.key ~= key then
        local maxH = 0
        local function consider(exeId)
            local info = ZeD.HealthTab.exerciseInfo(playerObj, exeId, true)
            if info then maxH = math.max(maxH, layoutExerciseInfo(info, wrapW).h) end
        end
        for _, exeId in ipairs(EXERCISE_BODYWEIGHT) do consider(exeId) end
        for _, exeId in ipairs(EXERCISE_EQUIPMENT) do consider(exeId) end
        cache = { key = key, h = maxH }
        win._healthInfoCache = cache
    end
    win._healthInfoW = wrapW
    win._healthInfoH = cache.h
    return T.px(1) + T.sp.afterGroove + cache.h
end

-- ============================================================================
-- ZONE A HEIGHT MEASUREMENT (for scroll math)
-- ============================================================================

-- (the figure's box is T.sp.figureW / figureH: the canvas at the whole zoom it draws at)

function ZeD.HealthTab._measureZoneA(data, rw, win)
    local T     = ZeD.T
    local secH  = ZeD.TM:getFontHeight(T.fontF1)
    local btnH  = T.buttonH
    local gap   = T.sp.xs

    -- Right column: summary section (heading moved to disclosure header)
    local rightH = 0
    local statRowH = math.max(secH, ZeD.TM:getFontHeight(T.fontF2)) + T.px(4)
    rightH = rightH + statRowH + T.sp.rowGap
    rightH = rightH + T.fillBarH + T.sp.xs + secH + T.sp.sm

    -- Right column: exercise section (bodyweight 2-col + equipment full-width)
    local bwRows = math.ceil(#EXERCISE_BODYWEIGHT / 2)
    rightH = rightH + bwRows * (btnH + gap)
    rightH = rightH + #EXERCISE_EQUIPMENT * (btnH + gap)
    rightH = rightH + btnH + gap  -- session time row
    rightH = rightH + ZeD.HealthTab._measureExerciseInfo(win, rw)  -- exercise info block

    return math.max(T.sp.figureH, rightH)   -- the figure at the whole zoom it draws at (Oct 21 2026)
end

-- ============================================================================
-- RENDERER (main entry point)
-- ============================================================================

function ZeD.HealthTab.render(panel, win, x, y, w, h)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules
    local pad  = M.getTabPad()

    -- Throttled data refresh
    win._healthTimer = (win._healthTimer or 0) + 1
    if win._healthTimer >= 15 or not win._healthCache then
        win._healthTimer = 0
        win._healthCache = ZeD.HealthTab.gatherData(win._playerObj)
    end
    local data = win._healthCache

    -- Font metrics
    local bodyH  = ZeD.TM:getFontHeight(T.fontF2)

    -- S101 gamepad integration. Stash the content panel so _onPartClicked
    -- (called from injury-row / body-part onActivate) can anchor the vanilla
    -- treatment context menu even though callers don't pass drawerPanel.
    -- Capture LAST frame's injury Y-map before clearing so scroll-follow can
    -- read it; this frame's map is rebuilt during the injury loop below.
    win._healthContentPanel = panel
    local lastInjuryYMap = win._healthInjuryYMap or {}
    win._healthInjuryZones = {}
    win._healthInjuryYMap  = {}

    -- ================================================================
    -- WHOLE-TAB SCROLL SETUP
    -- ================================================================
    local scroll  = win._healthScroll
    local scrollW = T.sp.scrollbarW

    -- Pinned header: 37px disclosure strip
    local headerH = M.getTabHeaderH()
    local padTop  = M.getTabPadTop()
    local figureExpanded = win._healthFigureExpanded

    -- S103 — resolve "active" body part: gamepad focus on a body-part element
    -- overrides mouse hover so D-pad through parts live-swaps the right-column
    -- detail view (Thermal parity; S101 deferred this, S103 ships it). Stashed
    -- on win so both the detail-view branch and _drawBodyFigure read the same
    -- authoritative value.
    -- (the live element: the controller's focus leads only while the controller is
    -- in use, so the mouse's hover leads again once the mouse moves)
    local activePart = win._healthHoveredPart
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local el = Focus and Focus.liveElement and Focus.liveElement(win)
        if el and el.partName then activePart = el.partName end
    end
    win._healthActivePart = activePart

    -- S103: stamp disclosure hit-zone EARLY so the first prerender after a
    -- tab-switch sees valid bounds and the disclosure focusable builds into
    -- element[1]. Same one-frame-lag problem that SkillsTab had: late-stamped
    -- zones leave idx=1 pointing at the first exercise pill instead of the
    -- disclosure on entry, so users can't L-collapse the figure immediately.
    win._healthFigureZone = { x = x, y = y, w = w, h = headerH }

    -- Zone A body: figure + dashboard (only when expanded)
    local zoneABodyH = 0
    if figureExpanded then
        zoneABodyH = ZeD.HealthTab._measureZoneA(data, w, win) + padTop + pad
    end

    -- Zone B height (injury list)
    local zoneBH = 0
    if data.injuredCount > 0 then
        zoneBH = zoneBH + T.px(1) + T.sp.afterLine
        for _, entry in ipairs(data.entries) do
            zoneBH = zoneBH + bodyH + T.px(2)
            local tagsH = ZeD.HealthTab._measureBadgeRows(entry.conditions, w - scrollW - T.px(4))
            if tagsH > 0 then zoneBH = zoneBH + tagsH + T.sp.xs end
            zoneBH = zoneBH + T.px(1) + T.sp.afterGroove
        end
    end

    -- Oct 23 2026 (director: "cannot see the bottom of the health tab"): the
    -- scroll range covers what the last frame really drew too (the right
    -- column's detail view and wrapped badge rows can run past the measure)
    local totalContentH = math.max(padTop + zoneABodyH + zoneBH, win._healthDrawnH or 0)
    local scrollY = y + headerH
    local scrollH = h - headerH
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

    -- S101 gamepad scroll-follow for injury list. Runs only when the live
    -- focused ring element is an injury row (Focus.getFocusedElement returns
    -- the zone's current element; el.injuryKey is unique to injury elements).
    -- Reads last frame's stamped entry-start Y and adjusts scroll.scrollPos
    -- BEFORE scrollOff is computed. One-frame lag, mirrors EquipmentTab pattern.
    -- S103 DELTA GATE: only pin scroll when the focused injuryKey actually
    -- CHANGED. Mode-gate approach (getMode() == "gamepad") was unreliable
    -- because the detector oscillates kbm↔gamepad within consecutive frames,
    -- so a KBM mousewheel past the focused row could snap back on any
    -- frame that briefly reported "gamepad". Delta gate fires exactly once
    -- per focus change regardless of mode.
    -- Oct 23 2026: the same for every stop in the tab (exercise pills, the
    -- time buttons, body parts, injuries), keyed on the element's id. The
    -- lowest stop scrolls as far down as it can while staying in view, so the
    -- text under it (the exercise info, the last injury) can be read on the
    -- pad; the header's disclosure scrolls back to the top.
    if needsScroll then
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local el = Focus and Focus.getFocusedWindow and Focus.getFocusedElement
                   and Focus.getFocusedWindow() == win
                   and Focus.getFocusedElement(win) or nil
        local focKey = el and (el.injuryKey or el.exerciseId or el.partName or el.isDisclosure) and el.id or nil
        if focKey and focKey ~= win._lastPinnedInjuryKey then
            local span    = math.max(1, totalContentH - scrollH)
            local oldOff  = math.floor(scroll.scrollPos * span)
            local elY, elH = el.y, el.h
            if el.injuryKey and lastInjuryYMap[el.injuryKey] then elY = lastInjuryYMap[el.injuryKey] end
            local target = oldOff
            if el.isDisclosure then
                target = 0
            elseif type(elY) == "number" and type(elH) == "number" then
                local logicalY = elY - scrollY + oldOff
                local lowest = true
                local z = Focus.getFocusedZone(win)
                for _, o in ipairs(z and z.elements or {}) do
                    if o ~= el and type(o.y) == "number" and o.y + (o.h or 0) > elY + elH + 1 then lowest = false; break end
                end
                if lowest then
                    target = math.min(span, logicalY)
                elseif logicalY < oldOff then
                    target = logicalY
                elseif logicalY + elH > oldOff + scrollH then
                    target = logicalY + elH - scrollH
                end
            end
            target = math.max(0, math.min(span, target))
            if target ~= oldOff then scroll:setScrollPos(target / span) end
            win._lastPinnedInjuryKey = focKey
        end
    end

    panel:setStencilRect(x, scrollY, contentW, scrollH)
    win._healthView = { x = x, y = scrollY, w = contentW, h = scrollH }   -- (what the pointer may hover)

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * math.max(0, totalContentH - scrollH))
    end

    local curY = scrollY - scrollOff + padTop

    -- ================================================================
    -- ZONE A BODY: figure (left) + dashboard (right) — scrolls
    -- ================================================================
    -- (_healthFigureZone is stamped at the TOP of render now, not here)

    if figureExpanded then
        local layout = M.layoutZoneA(x, curY, contentW, T.sp.figureW, T.sp.figureH)

        ZeD.HealthTab._drawBodyFigure(panel, win, data,
            layout.figX, layout.figY, T.sp.figureW, T.sp.figureH)

        -- S103: detail-view now reads _healthActivePart (gp focus overrides
        -- mouse hover); previously only _healthHoveredPart drove the swap.
        local activePart = win._healthActivePart
        local rightBottom
        if activePart and data.partHealth[activePart] then
            rightBottom = ZeD.HealthTab._renderDetailView(panel, win, data, activePart,
                layout.rightX, layout.rightY, layout.rightW)
        else
            rightBottom = ZeD.HealthTab._renderHeader(panel, win, data,
                layout.rightX, layout.rightY, layout.rightW)
        end

        -- (Oct 23 2026: a right column taller than the measure pushes the
        -- injury list down instead of running under it)
        curY = math.max(curY + zoneABodyH, (rightBottom or 0) + padTop + pad)
    end

    -- ================================================================
    -- ZONE B: Injury List (full width, scrollable)
    -- ================================================================

    if data.injuredCount > 0 then
        -- Zone divider (full width, no padding)
        A.drawDividerH(panel, x, curY, w, true)
        curY = curY + T.px(1) + T.sp.afterLine
        local listX = x + pad
        local listW = contentW
        local st = T.stripe
        local sq = T.px(6)
        local tagsOpts = nil
        for ei, entry in ipairs(data.entries) do
            local entryStartY = curY
            local tagsH = condTags(nil, entry.conditions, 0, 0, listW)
            local entryH = bodyH + T.px(2) + (tagsH > 0 and (tagsH + T.sp.xs) or 0) + T.px(1) + T.sp.afterGroove

            -- Alternating row stripe (drawn before content)
            if ei % 2 == 0 then
                panel:drawRect(listX, curY, listW, entryH, st.a, st.r, st.g, st.b)
            end

            -- The controller's mark on the focused injury (under the words)
            local onFocus = false
            local fo = focusOf(win, "injury:" .. tostring(entry.name))
            if fo then
                onFocus = ZeD.Focus.mark(panel, listX, curY, listW, entryH, fo)
            end

            -- Default text with the status square: the colour is the mark's
            local ink = onFocus and T.textOnFocus or T.text
            local mark = sevColor(entry.worstSev)
            if mark then A.drawStatusDot(panel, listX + T.px(2), curY + math.floor((bodyH - sq) / 2), mark, sq) end
            A.drawBody(panel, ZeD.partLabel(entry.name), listX + T.px(2) + sq + T.px(6), curY, ink)
            local hpStr = math.floor(entry.health + 0.5) .. "%"
            A.drawTextRight(panel, hpStr, listX + listW, curY, T.fontF2, ink)
            curY = curY + bodyH + T.px(2)

            if tagsH > 0 then
                condTags(panel, entry.conditions, listX, curY, listW)
                curY = curY + tagsH + T.sp.xs
            end

            A.drawDividerH(panel, listX, curY, listW)
            curY = curY + T.px(1) + T.sp.afterGroove

            -- S101 stamp zone + Y map (read next frame by _buildHealthInjuryFocusables
            -- and scroll-follow above). Height = actual drawn extent including wrapped
            -- tag rows + divider gap.
            win._healthInjuryYMap[entry.name] = entryStartY
            win._healthInjuryZones[#win._healthInjuryZones + 1] = {
                x = listX, y = entryStartY, w = listW, h = curY - entryStartY,
                bodyPartName = entry.name,
                entryRef = entry,
            }
        end
    end
    -- what this frame drew, top to bottom (next frame's scroll range covers it)
    win._healthDrawnH = curY - (scrollY - scrollOff)

    panel:clearStencilRect()

    -- Pinned header, drawn on top of the scroll content: the hover wash and the
    -- controller's mark on the disclosure come with the molecule
    local hdrHover = A.mouseIn(panel, x, y, w, headerH)
    if hdrHover and ZeD.Help then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Health_HelpHeader")) end
    M.drawTabHeader(panel, x, y, w, getText("IGUI_XP_Health"), figureExpanded, hdrHover, nil,
        { focus = focusOf(win, "health:__disclosure") })

    if needsScroll then
        scroll:draw(panel)
    end
end

-- ============================================================================
-- BADGE ROW HEIGHT MEASUREMENT
-- ============================================================================

function ZeD.HealthTab._measureBadgeRows(conditions, maxW)
    return condTags(nil, conditions, 0, 0, maxW)
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.HealthTab.register(dispatchTable)
    dispatchTable["health"] = ZeD.HealthTab.render
end
