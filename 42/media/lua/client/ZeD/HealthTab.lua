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

local SEV_VARIANT = {
    critical = "danger",
    danger   = "danger",
    warning  = "warning",
    positive = "positive",
    ok       = "neutral",
}

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
    if word then return label .. " (" .. word .. ")" end
    return label
end

local function classifyConditions(bp, doctorLevel)
    local conds = {}
    local doc = doctorLevel or 0
    local cheat = ISHealthPanel and ISHealthPanel.cheat
    local bandaged = bp:bandaged()
    local word

    if bp:bitten() then
        conds[#conds + 1] = { label = "Bitten", severity = "critical" }
    end
    if bp:bleeding() then
        conds[#conds + 1] = { label = "Bleeding", severity = "danger" }
    end
    if bp:deepWounded() then
        word = nil
        if doc > 4 or cheat then
            if bp:getDeepWoundTime() > 10 then word = "Severe"
            elseif bp:getDeepWoundTime() > 8 then word = "Moderate" end
        end
        conds[#conds + 1] = { label = qualify("Deep Wound", word), severity = "danger" }
    end
    if bp:isInfectedWound() and not bandaged
       and (doc > 8 or bp:getWoundInfectionLevel() * 10 >= (2.5 - doc) or cheat) then
        conds[#conds + 1] = { label = "Infected", severity = "danger" }
    end
    if bp:getFractureTime() > 0 and bp:getSplintFactor() == 0 then
        word = nil
        if doc > 6 or cheat then
            if bp:getFractureTime() > 50 then word = "Severe"
            elseif bp:getFractureTime() > 20 then word = "Moderate" end
        end
        conds[#conds + 1] = { label = qualify("Fracture", word), severity = "danger" }
    end
    if bp:haveBullet() and not bandaged then
        conds[#conds + 1] = { label = "Lodged Bullet", severity = "danger" }
    end
    if bp:haveGlass() and not bandaged then
        conds[#conds + 1] = { label = "Glass Shards", severity = "danger" }
    end

    if bp:scratched() then
        word = nil
        if doc > 2 or cheat then
            if bp:getScratchTime() > 17 then word = "Severe"
            elseif bp:getScratchTime() > 14 then word = "Moderate" end
        end
        conds[#conds + 1] = { label = qualify("Scratch", word), severity = "warning" }
    end
    if bp:isCut() then
        word = nil
        if doc > 2 or cheat then
            if bp:getCutTime() > 17 then word = "Severe"
            elseif bp:getCutTime() > 14 then word = "Moderate" end
        end
        conds[#conds + 1] = { label = qualify("Laceration", word), severity = "warning" }
    end
    if bp:getBurnTime() > 0 and not bandaged then
        word = nil
        if (doc > 4 or cheat) and bp:isNeedBurnWash() then word = "Needs Cleaning" end
        conds[#conds + 1] = { label = qualify("Burn", word), severity = "warning" }
    end

    -- Stiffness / muscle strain (exercise soreness)
    local stiffness = bp:getStiffness()
    if stiffness >= 5 then
        if stiffness < 20 then
            conds[#conds + 1] = { label = "Minor Muscle Strain", severity = "warning" }
        else
            conds[#conds + 1] = { label = "Muscle Strain", severity = "danger" }
        end
    end

    -- Additional pain (from injuries, exercise, etc.)
    local pain = bp:getAdditionalPain()
    if pain > 10 then
        if pain > 50 then
            conds[#conds + 1] = { label = "Heavy Pain", severity = "danger" }
        else
            conds[#conds + 1] = { label = "Pain", severity = "warning" }
        end
    end

    if bp:bandaged() then
        if bp:getBandageLife() > 0 then
            conds[#conds + 1] = { label = "Bandaged", severity = "positive" }
        else
            conds[#conds + 1] = { label = "Dirty Bandage", severity = "warning" }
        end
    end
    if bp:stitched() then
        word = nil
        if doc > 6 or cheat then
            word = (bp:getStitchTime() > 40) and "Good" or "Needs Time"
        end
        conds[#conds + 1] = { label = qualify("Stitched", word), severity = "positive" }
    end
    if bp:getSplintFactor() > 0 then
        word = nil
        if doc > 4 or cheat then
            if bp:getSplintFactor() > 4 then word = "Good"
            elseif bp:getFractureTime() > 2 then word = "Moderate" end
        end
        conds[#conds + 1] = { label = qualify("Splinted", word), severity = "positive" }
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
        local bpType = bp:getType()
        local figureName = typeToFigure[bpType]

        -- Store health and conditions for ALL parts (figure needs full map)
        if figureName then
            partHealth[figureName] = health
            if #conds > 0 then
                condsByFigureName[figureName] = conds
            end
        end

        -- Injury list: parts with conditions, reduced health, stiffness, or pain
        local stiffness = bp:getStiffness()
        local pain = bp:getAdditionalPain()
        if #conds > 0 or health < 95 or stiffness >= 5 or pain > 10 then
            local worstSev = "ok"
            if #conds > 0 then
                worstSev = conds[1].severity
            end
            entries[#entries + 1] = {
                name       = getPartName(bp),
                health     = health,
                conditions = conds,
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
        isFemale          = playerObj:isFemale(),
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

    -- Overall stat row
    local pct = math.floor(data.overall + 0.5)
    local pctColor = pctToStatusColor(pct)
    local rowH = M.drawStatRow(panel, rx, curY, rw, "Overall", pct .. "%", pctColor)
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
        A.drawBody(panel, (data.injuredCount > 0) and "No injuries, low body health" or "No injuries", rx + dotSz + dotGap, curY)
    else
        A.drawBody(panel, wounded .. " of " .. data.totalParts .. " injured", rx, curY)
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
    local badgeH = secH + T.sp.badgePadY * 2

    local health = data.partHealth[figureName] or 100
    local conds = data.condsByFigureName[figureName]

    local curY = ry

    -- Health % stat row
    local pct = math.floor(health + 0.5)
    local pctColor = pctToStatusColor(pct)
    local rowH = M.drawStatRowDot(panel, rx, curY, rw, "Health", pct .. "%", pctColor)
    curY = curY + rowH + T.sp.rowGap

    -- Health fill bar
    local barH = M.drawFillBar(panel, rx, curY, rw, health / 100)
    curY = curY + barH + T.sp.sm

    -- Condition badges (or "Healthy")
    if conds and #conds > 0 then
        local bx = rx
        for _, cond in ipairs(conds) do
            local variant = SEV_VARIANT[cond.severity] or "neutral"
            local bw = A.drawBadge(panel, cond.label, bx, curY, variant)
            bx = bx + bw + T.sp.badgeGap
            if bx + T.px(40) > rx + rw then
                bx = rx
                curY = curY + badgeH + T.px(2)
            end
        end
        curY = curY + badgeH + T.sp.xs
    else
        local dotSz = T.px(6)
        local dotGap = T.px(4)
        A.drawStatusDot(panel, rx, curY + math.floor((secH - dotSz) / 2), T.positive, dotSz)
        A.drawSecondary(panel, "Healthy", rx + dotSz + dotGap, curY)
        curY = curY + secH + T.sp.xs
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

local EXERCISE_LABELS = {
    squats        = "Squats",
    pushups       = "Push-ups",
    situp         = "Sit-ups",
    burpees       = "Burpees",
    barbellcurl   = "Barbell curl",
    dumbbellpress = "Dumbbell press",
    bicepscurl    = "Biceps curl",
}

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

-- Global condition check (same rules as vanilla ISFitnessUI:updateButtons)
local function canExercise(playerObj)
    local moodles = playerObj:getMoodles()
    if moodles:getMoodleLevel(MoodleType.ENDURANCE) > 2 then return false end
    if moodles:getMoodleLevel(MoodleType.HEAVY_LOAD) > 2 then return false end
    if moodles:getMoodleLevel(MoodleType.PAIN) > 3 then return false end
    if playerObj:getVariableBoolean("sitonground") or playerObj:isSittingOnFurniture() then return false end
    if playerObj:getVehicle() then return false end
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
    ZeD.HealthTab._startExercise(win._playerObj, zone.id, ZeD.HealthTab.getExerciseMinutes(win))
    return true
end

-- Render exercise buttons:
-- Bodyweight = two-column grid, Equipment = full-width rows below.
function ZeD.HealthTab._renderExerciseButtons(panel, win, rx, ry, rw)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local font = T.fontF1
    local secH = ZeD.TM:getFontHeight(font)
    local btnH = secH + T.sp.pillBtnPadV
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

    -- Gamepad focus cue painter — 0.55 alpha T.accent over the pill bounds.
    -- Gated on the CURRENTLY focused ring element matching THIS exercise id
    -- (not the persistent _gpFocusedExercise state field) — otherwise all
    -- three Health focus cues (exercise/injury/body part) would paint at
    -- once since they share the charTabContent zone. Focus.getFocusedElement
    -- returns the single live element across the whole zone.
    local function _paintExerciseFocusCue(exeId, bx, by, bw, bh)
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if not Focus or not Focus.getFocusedWindow then return end
        if Focus.getFocusedWindow() ~= win then return end
        if not Focus.getFocusedElement then return end
        local el = Focus.getFocusedElement(win)
        if not el or el.exerciseId ~= exeId then return end
        local ac = T.accent
        panel:drawRect(bx, by, bw, bh, 0.55, ac.r, ac.g, ac.b)
    end

    for idx, exeId in ipairs(EXERCISE_BODYWEIGHT) do
        local label = EXERCISE_LABELS[exeId] or exeId
        local enabled = globalEnabled and not isExercising and isExerciseAvailable(playerObj, exeId)

        local isLeft = ((idx - 1) % 2 == 0)
        local bx = isLeft and rx or (rx + colW + colGap)
        local by = isLeft and leftY or rightY

        _paintExerciseFocusCue(exeId, bx, by, colW, btnH)
        A.drawPillButton(panel, bx, by, colW, btnH, label, false, enabled, font)

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
        local label = EXERCISE_LABELS[exeId] or exeId
        local enabled = globalEnabled and not isExercising and isExerciseAvailable(playerObj, exeId)

        _paintExerciseFocusCue(exeId, rx, curY, rw, btnH)
        A.drawPillButton(panel, rx, curY, rw, btnH, label, false, enabled, font)

        zoneIdx = zoneIdx + 1
        win._healthExerciseZones[zoneIdx] = {
            id = exeId,
            x = rx, y = curY, w = rw, h = btnH,
            enabled = enabled,
        }

        curY = curY + btnH + gap
    end

    -- Session time: label on the left, [-] minutes [+] on the right. The time
    -- can be changed while exercising; it applies to the next start.
    local mins   = ZeD.HealthTab.getExerciseMinutes(win)
    local readW  = ZeD.TM:MeasureStringX(font, "60") + T.px(16)
    local incX   = rx + rw - btnH
    local readX  = incX - readW
    local decX   = readX - btnH
    local canDec = mins > MIN_EXERCISE_TIME
    local canInc = mins < MAX_EXERCISE_TIME
    A.drawSecondary(panel, A.truncateText(getText("IGUI_FitnessTime"), font, math.max(0, decX - rx - T.sp.sm)),
        rx, curY + math.floor((btnH - secH) / 2))
    _paintExerciseFocusCue("time:dec", decX, curY, btnH, btnH)
    A.drawPillButton(panel, decX, curY, btnH, btnH, "-", false, canDec, font)
    local minStr = tostring(mins)
    local tc = T.text
    panel:drawText(minStr, readX + math.floor((readW - ZeD.TM:MeasureStringX(font, minStr)) / 2),
        curY + math.floor((btnH - secH) / 2), tc.r, tc.g, tc.b, tc.a or 1, font)
    _paintExerciseFocusCue("time:inc", incX, curY, btnH, btnH)
    A.drawPillButton(panel, incX, curY, btnH, btnH, "+", false, canInc, font)
    win._healthExerciseZones[zoneIdx + 1] = {
        id = "time:dec", timeStep = -EXERCISE_TIME_STEP,
        x = decX, y = curY, w = btnH, h = btnH, enabled = canDec,
    }
    win._healthExerciseZones[zoneIdx + 2] = {
        id = "time:inc", timeStep = EXERCISE_TIME_STEP,
        x = incX, y = curY, w = btnH, h = btnH, enabled = canInc,
    }
    curY = curY + btnH + gap

    return curY
end

-- ============================================================================
-- ZONE A HEIGHT MEASUREMENT (for scroll math)
-- ============================================================================

local FIGURE_W   = ZeD.Spacing.figureW
local FIGURE_H   = ZeD.Spacing.figureH

function ZeD.HealthTab._measureZoneA(data, rw)
    local T     = ZeD.T
    local secH  = ZeD.TM:getFontHeight(T.fontF1)
    local btnH  = secH + T.sp.pillBtnPadV
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

    return math.max(T.px(FIGURE_H), rightH)
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
    local secH   = ZeD.TM:getFontHeight(T.fontF1)
    local badgeH = secH + T.sp.badgePadY * 2

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
    local activePart = win._healthHoveredPart
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if Focus and Focus.getFocusedWindow and Focus.getFocusedElement
           and Focus.getFocusedWindow() == win then
            local el = Focus.getFocusedElement(win)
            if el and el.partName then activePart = el.partName end
        end
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
        zoneABodyH = ZeD.HealthTab._measureZoneA(data, w) + padTop + pad
    end

    -- Zone B height (injury list)
    local zoneBH = 0
    if data.injuredCount > 0 then
        zoneBH = zoneBH + T.px(1) + T.sp.afterLine
        for _, entry in ipairs(data.entries) do
            zoneBH = zoneBH + bodyH + T.px(2)
            local badgeRowH2 = ZeD.HealthTab._measureBadgeRows(entry.conditions, w - scrollW - T.px(4))
            zoneBH = zoneBH + badgeRowH2 + T.sp.xs
            zoneBH = zoneBH + T.px(1) + T.sp.afterGroove
        end
    end

    local totalContentH = padTop + zoneABodyH + zoneBH
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
    if needsScroll then
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local el = Focus and Focus.getFocusedWindow and Focus.getFocusedElement
                   and Focus.getFocusedWindow() == win
                   and Focus.getFocusedElement(win) or nil
        local injKey = el and el.injuryKey or nil
        if injKey and injKey ~= win._lastPinnedInjuryKey then
            local focAbsY = lastInjuryYMap[injKey]
            if focAbsY then
                local rowEstH = bodyH + T.px(2) + badgeH + T.sp.xs + T.px(1) + T.sp.afterGroove
                local span    = math.max(1, totalContentH - scrollH)
                local oldOff  = math.floor(scroll.scrollPos * span)
                local logicalY = focAbsY - scrollY + oldOff
                if logicalY < oldOff then
                    scroll:setScrollPos(logicalY / span)
                elseif logicalY + rowEstH > oldOff + scrollH then
                    scroll:setScrollPos((logicalY + rowEstH - scrollH) / span)
                end
            end
            win._lastPinnedInjuryKey = injKey
        end
    end

    panel:setStencilRect(x, scrollY, contentW, scrollH)

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
        local layout = M.layoutZoneA(x, curY, contentW, T.px(FIGURE_W), T.px(FIGURE_H))

        ZeD.HealthTab._drawBodyFigure(panel, win, data,
            layout.figX, layout.figY, T.px(FIGURE_W), T.px(FIGURE_H))

        -- S103: detail-view now reads _healthActivePart (gp focus overrides
        -- mouse hover); previously only _healthHoveredPart drove the swap.
        local activePart = win._healthActivePart
        if activePart and data.partHealth[activePart] then
            ZeD.HealthTab._renderDetailView(panel, win, data, activePart,
                layout.rightX, layout.rightY, layout.rightW)
        else
            ZeD.HealthTab._renderHeader(panel, win, data,
                layout.rightX, layout.rightY, layout.rightW)
        end

        curY = curY + zoneABodyH
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
        for ei, entry in ipairs(data.entries) do
            local entryStartY = curY

            -- Alternating row stripe (drawn before content, full entry height estimated)
            if ei % 2 == 0 then
                local entryH = bodyH + T.px(2) + badgeH + T.sp.xs + T.px(1) + T.sp.afterGroove
                panel:drawRect(listX, curY, listW, entryH, st.a, st.r, st.g, st.b)
            end

            -- S101 gamepad focus cue: 0.55 alpha T.accent over the row. Gated
            -- on the live focused element having this injuryKey so the cue
            -- clears on bumper-away or when focus moves to another element
            -- type inside charTabContent (exercise/body part).
            do
                local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
                if Focus and Focus.getFocusedWindow and Focus.getFocusedElement
                   and Focus.getFocusedWindow() == win then
                    local el = Focus.getFocusedElement(win)
                    if el and el.injuryKey == entry.name then
                        local entryH = bodyH + T.px(2) + badgeH + T.sp.xs + T.px(1) + T.sp.afterGroove
                        local ac = T.accent
                        panel:drawRect(listX, curY, listW, entryH, 0.55, ac.r, ac.g, ac.b)
                    end
                end
            end

            local nameColor = T[SEV_VARIANT[entry.worstSev]] or T.text
            A.drawBody(panel, entry.name, listX, curY, nameColor)
            local hpStr = math.floor(entry.health + 0.5) .. "%"
            A.drawTextRight(panel, hpStr, listX + listW, curY, T.fontF2, nameColor)
            curY = curY + bodyH + T.px(2)

            local bx = listX
            for _, cond in ipairs(entry.conditions) do
                local variant = SEV_VARIANT[cond.severity] or "neutral"
                local bw = A.drawBadge(panel, cond.label, bx, curY, variant)
                bx = bx + bw + T.sp.badgeGap
                if bx + T.px(40) > listX + listW then
                    bx = listX
                    curY = curY + badgeH + T.px(2)
                end
            end
            curY = curY + badgeH + T.sp.xs

            A.drawDividerH(panel, listX, curY, listW)
            curY = curY + T.px(1) + T.sp.afterGroove

            -- S101 stamp zone + Y map (read next frame by _buildHealthInjuryFocusables
            -- and scroll-follow above). Height = actual drawn extent including wrapped
            -- badge rows + divider gap.
            win._healthInjuryYMap[entry.name] = entryStartY
            win._healthInjuryZones[#win._healthInjuryZones + 1] = {
                x = listX, y = entryStartY, w = listW, h = curY - entryStartY,
                bodyPartName = entry.name,
                entryRef = entry,
            }
        end
    end

    panel:clearStencilRect()

    -- S103 gamepad focus cue on the tab-header disclosure. 0.55α T.accent
    -- over the header rect, drawn BEFORE drawTabHeader so the chevron + text
    -- render on top. Gated on live focused element shape (isDisclosure) so
    -- the cue clears the moment LB/RB bumpers away. Mirrors Thermal exactly.
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == win
           and Focus.getFocusedElement then
            local el = Focus.getFocusedElement(win)
            if el and el.isDisclosure then
                local ac = T.accent
                panel:drawRect(x, y, w, headerH, 0.55, ac.r, ac.g, ac.b)
            end
        end
    end

    -- Pinned header — drawn on top of scroll content
    M.drawTabHeader(panel, x, y, w, "Health", figureExpanded)

    if needsScroll then
        scroll:draw(panel)
    end
end

-- ============================================================================
-- BADGE ROW HEIGHT MEASUREMENT
-- ============================================================================

function ZeD.HealthTab._measureBadgeRows(conditions, maxW)
    local T = ZeD.T
    local secH   = ZeD.TM:getFontHeight(T.fontF1)
    local badgeH  = secH + T.sp.badgePadY * 2
    local padX = T.sp.badgePadX

    if #conditions == 0 then return 0 end

    local rows = 1
    local bx = 0
    for _, cond in ipairs(conditions) do
        local tw = ZeD.TM:MeasureStringX(T.fontF1, string.upper(cond.label))
        local bw = tw + padX * 2
        bx = bx + bw + T.sp.badgeGap
        if bx + T.px(40) > maxW and bx > bw + T.sp.badgeGap then
            rows = rows + 1
            bx = bw + T.sp.badgeGap
        end
    end

    return rows * (badgeH + T.px(2))
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.HealthTab.register(dispatchTable)
    dispatchTable["health"] = ZeD.HealthTab.render
end
