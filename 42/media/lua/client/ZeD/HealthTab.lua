-- ZeD-UI/42/media/lua/client/ZeD/HealthTab.lua
-- ============================================================================
-- HEALTH TAB — client; the Character window's Health tab ("health" in its
-- tab dispatch table). Under a pinned header, whose disclosure folds the
-- figure away, the body scrolls. Zone A: the body figure; beside it the health
-- summary and the picked exercise's description, or the hovered or focused
-- part's detail. Zone B: the injury list, worst first, with condition tags.
-- Under it the fill blocks: the moodles that are on, Fitness and Strength,
-- each exercise's regularity (a row picks it for the band) and muscle strain.
-- The footer band is pinned: the exercise pop-up, the session time, Start.
-- With an injury the tab is a treatment card (the director, Nov 23 2026): the
-- summary's column lists the hurt parts and muscle strain, worst first, and
-- the band picks a part and Treat opens the game's treatment menu for it.
-- What the tab reveals follows vanilla's health panel at the viewer's First
-- Aid level, and a part's treatment menu is vanilla's own. Other mods add
-- wound details through EXTRAS; the medical check of another player
-- (ObjectCardMedic.lua) reuses these pieces.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/ZeD_BodyFigure"
require "XpSystem/ISUI/ISHealthPanel"
require "ZeD/ZeD_TabFill"
require "ZeD/ZeD_Popups"

ZeD = ZeD or {}
ZeD.HealthTab = {}

-- The tab's data refresh runs on the clock, not on frames drawn: 15 frames is 250 ms at 60 FPS
-- but runs 2.4-4 times as often at 144-240 Hz. True once periodMs has
-- passed since owner[key] (or on the first call, or forced: the cache was dropped). The runs keep a
-- beat of periodMs; a forced run, or one after a gap (the tab not drawn), starts the period again,
-- as the frame count went back to 0. A window's first run starts at its own
-- phase (owner._zedPhase, shared by the tabs of one window), so windows opened together don't
-- refresh on the same frame. Only differences of the clock are taken (no %: it is past 2^31).
local function dueMs(owner, key, periodMs, force)
    local now = getTimestampMs()
    local last = owner[key]
    if not force and last and now >= last and now - last < periodMs then return false end
    if last == nil then
        local ph = owner._zedPhase
        if not ph then
            ZeD._throttleN = (ZeD._throttleN or 0) + 1
            local g = ZeD._throttleN * 0.6180339887
            ph = g - math.floor(g)
            owner._zedPhase = ph
        end
        owner[key] = now - math.floor(ph * periodMs)
    elseif force or now < last or now - last >= periodMs * 2 then
        owner[key] = now               -- (forced, or after a gap: the period starts again)
    else
        owner[key] = last + periodMs   -- (on the beat: a late frame doesn't stretch the next period)
    end
    return true
end

-- (the status bars' rule: ZeD.Atoms.statusColor, punch list 143)
local function pctToStatusColor(pct) return ZeD.Atoms.statusColor(pct / 100) end

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
-- ANATOMICAL DISPLAY NAMES (medic-style: "Left Thigh", "Left Shin" where the
-- figure says Upper / Lower Leg)
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

-- The condition tags: each the status square and the word (the library's tag, no
-- box), the square 6u before the word as the part's own square sits before its name.
-- Every tag keeps the square's room, marked or not, so the words of a wrapped
-- line stay in step.
local TAG_SQ, TAG_MARK_GAP, TAG_GAP = 6, 6, 12   -- (design units: the square, square to word, tag to tag)
local _condTagOpts = {}

-- the room before a tag's word: the square and its gap
local function tagHang()
    local T = ZeD.T
    return T.px(TAG_SQ) + T.px(TAG_MARK_GAP)
end

-- The condition tags of one part, wrapped in maxW; draws them when a panel is given
-- and returns the height they take (0 with none). Measuring and drawing share this
-- one wrap. x is where the words start; hang = how far the squares sit out to the
-- left of x (the Health list hangs them under the part's square, so the words start
-- under its name), 0 for a list that starts at x.
local function condTags(panel, conds, x, y, maxW, hang)
    local T = ZeD.T
    local th, gap = T.px(16), T.px(TAG_GAP)
    local slot = tagHang()
    hang = hang or 0
    local left = x - hang
    local room = maxW + hang
    local opts = _condTagOpts
    opts.markGap = T.px(TAG_MARK_GAP)
    local bx, by = 0, 0
    for _, c in ipairs(conds) do
        local col = sevColor(c.severity)
        local bw = slot + ZeD.TM:MeasureStringX(T.fontF1, ZeD.textCase(c.label))
        if bx > 0 and bx + bw > room then bx = 0; by = by + th + T.px(2) end
        if panel then
            if col then ZeD.Molecules.drawTag(panel, left + bx, y + by, c.label, col, opts)
            else ZeD.Molecules.drawTag(panel, left + bx + slot, y + by, c.label, nil, opts) end
        end
        bx = bx + bw + gap
    end
    if #conds == 0 then return 0 end
    return by + th
end
ZeD.HealthTab.tagHang = tagHang
-- (the same tags and marks on the medical check of another player: ObjectCardMedic.lua)
ZeD.HealthTab.condTags = condTags
ZeD.HealthTab.sevColor = sevColor

-- One injury row's band: the name line and its tags sit in the middle, the same
-- pad above and below, the groove on the band's foot. The tags start under the
-- name, past the status square. Measuring and drawing share it.
-- (the words once sat on the band's top with the whole gap below them)
function ZeD.HealthTab.injuryRowLayout(bodyH, tagsH)
    local T = ZeD.T
    local padV = T.px(8)
    local tagGap = T.px(4)
    local contentH = bodyH + ((tagsH or 0) > 0 and (tagGap + tagsH) or 0)
    local indent = T.px(2) + T.px(6) + T.px(6)   -- (the square's inset, the square, the gap to the name)
    return {
        padV = padV,
        nameY = padV,
        tagsY = padV + bodyH + tagGap,
        h = padV + contentH + padV + T.px(1),
        indent = indent,
    }
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
-- What the character knows without looking is marked care = true:
-- pain, stiffness and the care already given (bandage, stitches, splint,
-- poultice). A mod that holds a part's diagnosis back (EXTRAS below: holds) keeps
-- only those for the part.
local function qualify(label, word)
    if word then return ZeD.tr("UI_ZeD_Health_Qualified", label, word) end
    return label
end

-- Each getter the rules read more than once is read once into a
-- local (the same values: nothing changes the part in between); the part's stiffness and pain go
-- back to gatherData, so it does not read them again.
-- What it reads of the wounds and their care it keeps in SEEN as it goes, for the body figure's
-- marks (ZeD_BodyFigure.woundsFrom): one table, filled again for each part, so the figure reads
-- nothing of the part a second time (Design, Nov 22 2026). gatherData adds held.
local SEEN = {}
-- panelWords: the words vanilla's panel writes for a doctor looking at someone else ("Scratched", "Burned"),
-- for the medical check card; the Health tab keeps its own short ones (QA MD2, Nov 26 2026)
local function classifyConditions(bp, doctorLevel, panelWords)
    local conds = {}
    local doc = doctorLevel or 0
    local cheat = ISHealthPanel and ISHealthPanel.cheat
    local bandaged = bp:bandaged()
    local fractureT = bp:getFractureTime()
    local splint = bp:getSplintFactor()
    local word
    local seen = SEEN                       -- what the figure's marks read (SEEN above), filled as the list reads
    seen.bandaged, seen.fracture, seen.splint = bandaged, fractureT > 0, splint > 0

    -- The words are vanilla's own health-panel words where it has them (IGUI_health_*);
    -- the few it lacks are ZeD keys. They are read here, every time the tab re-reads the
    -- body (a few times a second), so a change of language shows within moments.
    seen.bitten = bp:bitten()
    if seen.bitten then
        conds[#conds + 1] = { label = getText("IGUI_health_Bitten"), severity = "critical" }
    end
    seen.bleed = bp:bleeding()
    if seen.bleed then
        conds[#conds + 1] = { label = getText("IGUI_health_Bleeding"), severity = "danger" }
    end
    seen.deep = bp:deepWounded()
    if seen.deep then
        word = nil
        if doc > 4 or cheat then
            local t = bp:getDeepWoundTime()
            if t > 10 then word = getText("IGUI_health_Severe")
            elseif t > 8 then word = getText("IGUI_health_Moderate") end
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_DeepWound"), word), severity = "danger" }
    end
    seen.infected = bp:isInfectedWound() and not bandaged
       and (doc > 8 or bp:getWoundInfectionLevel() * 10 >= (2.5 - doc) or cheat) or false
    if seen.infected then
        conds[#conds + 1] = { label = getText("IGUI_health_Infected"), severity = "danger" }
    end
    if fractureT > 0 and splint == 0 then
        word = nil
        if doc > 6 or cheat then
            if fractureT > 50 then word = getText("IGUI_health_Severe")
            elseif fractureT > 20 then word = getText("IGUI_health_Moderate") end
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_Fracture"), word), severity = "danger" }
    end
    seen.bullet = bp:haveBullet()
    if seen.bullet and not bandaged then
        conds[#conds + 1] = { label = getText("IGUI_health_LodgedBullet"), severity = "danger" }
    end
    seen.glass = bp:haveGlass()
    if seen.glass and not bandaged then
        conds[#conds + 1] = { label = ZeD.tr("UI_ZeD_Health_GlassShards"), severity = "danger" }
    end

    seen.scratch = bp:scratched()
    if seen.scratch then
        word = nil
        if doc > 2 or cheat then
            local t = bp:getScratchTime()
            if t > 17 then word = getText("IGUI_health_Severe")
            elseif t > 14 then word = getText("IGUI_health_Moderate") end
        end
        conds[#conds + 1] = { label = qualify(getText(panelWords and "IGUI_health_Scratched" or "IGUI_health_Scratch"), word), severity = "warning" }
    end
    seen.cut = bp:isCut()
    if seen.cut then
        word = nil
        if doc > 2 or cheat then
            local t = bp:getCutTime()
            if t > 17 then word = getText("IGUI_health_Severe")
            elseif t > 14 then word = getText("IGUI_health_Moderate") end
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_Cut"), word), severity = "warning" }
    end
    seen.burn = bp:getBurnTime() > 0
    if seen.burn and not bandaged then
        word = nil
        if (doc > 4 or cheat) and bp:isNeedBurnWash() then word = ZeD.tr("IGUI_health_NeedCleaning") end
        conds[#conds + 1] = { label = qualify(panelWords and getText("IGUI_health_Burned") or ZeD.tr("UI_ZeD_Health_Burn"), word), severity = "warning" }
    end

    -- Stiffness / muscle strain (exercise soreness); strain = true: the summary counts it apart from
    -- the injuries (Strain, the director, Nov 22 2026)
    local stiffness = bp:getStiffness()
    if stiffness >= 5 then
        if stiffness < 20 then
            conds[#conds + 1] = { label = getText("IGUI_health_MinorStiffness"), severity = "warning", care = true, strain = true }
        else
            conds[#conds + 1] = { label = getText("IGUI_health_Stiffness"), severity = "danger", care = true, strain = true }
        end
    end

    -- Additional pain (from injuries, exercise, etc.)
    local pain = bp:getAdditionalPain()
    if pain > 10 then
        if pain > 50 then
            conds[#conds + 1] = { label = getText("IGUI_health_HeavyPain"), severity = "danger", care = true }
        else
            conds[#conds + 1] = { label = getText("IGUI_health_Pain"), severity = "warning", care = true }
        end
    end

    seen.clean = false
    if bandaged then
        seen.clean = bp:getBandageLife() > 0
        if seen.clean then
            conds[#conds + 1] = { label = getText("IGUI_health_Bandaged"), severity = "positive", care = true }
        else
            conds[#conds + 1] = { label = getText("IGUI_health_DirtyBandage"), severity = "warning", care = true }
        end
    end
    seen.stitched = bp:stitched()
    if seen.stitched then
        word = nil
        if doc > 6 or cheat then
            word = (bp:getStitchTime() > 40) and getText("IGUI_health_Good") or ZeD.tr("IGUI_health_NeedTime")
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_Stitched"), word), severity = "positive", care = true }
    end
    if splint > 0 then
        word = nil
        if doc > 4 or cheat then
            if splint > 4 then word = getText("IGUI_health_Good")
            elseif fractureT > 2 then word = getText("IGUI_health_Moderate") end
        end
        conds[#conds + 1] = { label = qualify(getText("IGUI_health_Splinted"), word), severity = "positive", care = true }
    end
    -- Poultices on the part, as vanilla lists them
    if bp:getPlantainFactor() > 0 then
        conds[#conds + 1] = { label = getText("ContextMenu_PlantainCataplasm"), severity = "positive", care = true }
    end
    if bp:getComfreyFactor() > 0 then
        conds[#conds + 1] = { label = getText("ContextMenu_ComfreyCataplasm"), severity = "positive", care = true }
    end
    if bp:getGarlicFactor() > 0 then
        conds[#conds + 1] = { label = getText("ContextMenu_GarlicCataplasm"), severity = "positive", care = true }
    end

    table.sort(conds, function(a, b)
        return (SEV_ORDER[a.severity] or 99) < (SEV_ORDER[b.severity] or 99)
    end)

    return conds, stiffness, pain
end

-- ============================================================================
-- HEALTH-TO-COLOR MAPPING (for body figure)
-- ============================================================================

-- the red for 20 percent or less, one table (beast W19)
local LOW_HEALTH_RED = { r = 0.95, g = 0.15, b = 0.15, a = 1.0 }
local function getHealthColor(health)
    local T = ZeD.T
    if health > 80  then return T.positive end
    if health > 50  then return T.warning  end
    if health > 20  then return T.danger   end
    return LOW_HEALTH_RED
end
ZeD.HealthTab.healthColor = getHealthColor

-- MUSCLE STRAIN ON THE FIGURE (Strain, the director, Nov 22 2026): a strained part takes a tint of its
-- own (the theme's strainMinor / strainHeavy), at the levels the game's health panel names it: Minor
-- Muscle Strain at 5 or more, Muscle Strain at 20 or more. A wound's colour wins on the same part.
-- The Health tab's figure and the medical check's only: Thermal and Equipment's defense view keep their
-- own colours ("No, Health only.", the director, Nov 22 2026).

--- 1 (minor) or 2 (heavy) for a part's stiffness, nil under 5
function ZeD.HealthTab.strainLevel(stiffness)
    if not stiffness or stiffness < 5 then return nil end
    return (stiffness >= 20) and 2 or 1
end

--- the theme's tint for a strain level (1 or 2); nil for none
function ZeD.HealthTab.strainColor(level)
    if not level then return nil end
    local T = ZeD.T
    if level >= 2 then return T.strainHeavy or T.danger end
    return T.strainMinor or T.warning
end

-- A wound shows on a part: its health tint is not the healthy one (80 or less), another mod names
-- something there, or a condition that is not care (care: pain, strain, bandage, stitches, splint,
-- poultice; classifyConditions marks them) is on it
local function woundShows(conds, health, extra)
    if health <= 80 or extra then return true end
    for _, c in ipairs(conds) do
        if not c.care then return true end
    end
    return false
end
ZeD.HealthTab.woundShows = woundShows

--- The colour a part draws in on the Health figure (and the medical check's): the strain tint where
--- the part is strained and no wound shows, else its health colour. data is gatherData's read.
--- Nil for a healthy part: no tint, so the white skeleton shows bright (the director, Nov 23 2026: "instead of
--- 100% being green, can it just be no color").
function ZeD.HealthTab.figureColor(data, figureName, health)
    local wound = data.partWound and data.partWound[figureName]
    local lv = data.partStrain and data.partStrain[figureName]
    if lv and not wound then
        return ZeD.HealthTab.strainColor(lv)
    end
    if not wound then return nil end
    -- an injured part: the worst injury's severity, the colour of its dot in the list (the director, Nov 23 2026:
    -- "keep the injury severity color"); a part hurt with no condition named falls back to its health colour
    local sev = data.partSev and data.partSev[figureName]
    return (sev and sevColor(sev)) or getHealthColor(health)
end

--- Tint a figure part with figureColor's colour, or clear it for a healthy part (one call for the tab and the card).
function ZeD.HealthTab.tintPart(fig, data, figureName, health)
    local c = ZeD.HealthTab.figureColor(data, figureName, health)
    if c then fig:setPartColor(figureName, c.r, c.g, c.b, 0.65)
    else fig:clearPartColor(figureName) end
end

-- ============================================================================
-- EXTRAS -- the general way for another mod's support file
-- (ModSupport/<mod id>.lua) to add its own wound details to a body part without
-- touching this file. Nothing is added until an extra is registered, so the
-- tab is exactly as built without one. An extra is a table:
--   partLines(playerObj, bodyPart)
--       -> nil, or a list of { text = "...", color = {r,g,b}, severity = "danger" |
--          "warning" | "positive" | nil }: the mod's own words for what is wrong with
--          that part. They show in the part's detail view (a status square in the
--          mod's colour, the words in the default ink) and as tags on the part's row
--          in the injury list (the square follows the severity; "warning" when none
--          is given). A part with such a line counts as injured and is listed.
--   holds(playerObj, bodyPart)
--       -> true while the mod holds that part's diagnosis back (an examination it
--          asks for first): the part keeps only the conditions the character knows
--          without looking (care = true in the classifier), and the mod's own
--          partLines say what it wants said instead.
--   openPart(playerObj, bodyPart, panel, x, y)
--       -> true when the mod opened the part's menu itself (right-click on the
--          figure or an injury row, A on the controller). panel is the stand-in
--          for the game's health panel that the game's menu is built from; x, y are
--          where the menu opens, from its origin. Anything else, or an error, and
--          the tab opens the game's menu as it always has.
-- Every call goes through pcall; ZeD keeps no copy of the mod's data (the lines are
-- read again each time the tab re-reads the body). Users today:
-- ModSupport/WoundExpansion.lua (partLines) and ModSupport/WoundsOverhaul.lua
-- (all three).
-- ============================================================================
ZeD.HealthTab.extras = ZeD.HealthTab.extras or {}

--- Register another mod's extra under id (a second call with the same id
--- replaces it); def holds the fields described in EXTRAS above.
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

-- Does an extra hold this part's diagnosis back? (false with none, or when it errs)
local function heldBack(playerObj, bp)
    for _, e in ipairs(ZeD.HealthTab.extras) do
        if e.holds then
            local ok, yes = pcall(e.holds, playerObj, bp)
            if ok and yes == true then return true end
        end
    end
    return false
end

-- The conditions the character knows without looking (care = true), in their order
local function careOnly(conds)
    local out = {}
    for _, c in ipairs(conds) do
        if c.care then out[#out + 1] = c end
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
-- One read of the body: the injury list, plus the maps the figure draws from
-- (partHealth, condsByFigureName, extraByFigureName, partByFigure).
-- ============================================================================

local _typeToFigure, _typeToFigureFrom = nil, nil   -- BodyPartType -> figure name, per BODY_PART_TYPES

-- The game's words for the overall health, the ones its own health panel shows under
-- "Overall Body Status", at its thresholds: OK only at 100, then each word above its
-- floor. The game works the overall out from the parts' health alone, so a fresh wound
-- or a bleed reads OK until it has cost a part some health; a percent rounded up read
-- 100% where the game already says Slight damage.
local OVERALL_WORDS = {
    { 90, "IGUI_health_Slight_damage" }, { 80, "IGUI_health_Very_Minor_damage" }, { 70, "IGUI_health_Minor_damage" },
    { 60, "IGUI_health_Moderate_damage" }, { 50, "IGUI_health_Severe_damage" }, { 40, "IGUI_health_Very_Severe_damage" },
    { 20, "IGUI_health_Crital_damage" }, { 10, "IGUI_health_Highly_Crital_damage" }, { 0, "IGUI_health_Terminal_damage" },
}

--- The game's word for an overall health of 0..100 (BodyDamage:getOverallBodyHealth).
function ZeD.HealthTab.overallWord(health)
    health = health or 100
    if health >= 100 then return getText("IGUI_health_ok") end
    for _, w in ipairs(OVERALL_WORDS) do
        if health > w[1] then return getText(w[2]) end
    end
    return getText("IGUI_health_Deceased")
end

--- The word for a read of the body (gatherData's table), looked up once per read: the rows
--- draw it every frame, the read comes a few times a second.
function ZeD.HealthTab.overallWordOf(data)
    local w = data.overallWord
    if not w then
        w = ZeD.HealthTab.overallWord(data.overall)
        data.overallWord = w
    end
    return w
end

--- The overall block, the Health tab's and the medical check's: the Overall row with its
--- percent (cut down, never up, so it reads 100% only at 100), the bar under it, then the
--- game's word on a line of its own, wrapped to the column. The row's value slot holds
--- about 11 letters at the 1.5 scale step, and "Highly Critical damage" or a German word
--- in it read "Slight ..." or less. Returns the y under the word.
-- A word with no spaces wider than the column (Thai writes "Highly Critical damage" as one
-- run) breaks between letters, never before a Thai vowel or tone mark, nor inside a UTF-8
-- letter where a string is bytes (the sims).
local function isMark(b)
    return (b >= 128 and b <= 191) or b == 0x0E31 or (b >= 0x0E34 and b <= 0x0E3A) or (b >= 0x0E47 and b <= 0x0E4E)
end
local function breakRun(out, line, font, w)
    local TM = ZeD.TM
    while TM:MeasureStringX(font, line) > w do
        local cut = 0
        for i = 2, #line do
            if not isMark(string.byte(line, i)) then
                if TM:MeasureStringX(font, string.sub(line, 1, i - 1)) > w then break end
                cut = i - 1
            end
        end
        if cut == 0 then break end
        out[#out + 1] = string.sub(line, 1, cut)
        line = string.sub(line, cut + 1)
    end
    out[#out + 1] = line
end
-- the word's lines at a width (no cache)
local function buildOverallLines(data, font, w)
    local out = {}
    for _, line in ipairs(ZeD.Atoms.wrapText(ZeD.HealthTab.overallWordOf(data), font, w)) do
        breakRun(out, line, font, w)
    end
    return out
end
-- the word's lines at a width, kept on the read (a new read every few frames, a new width
-- only while the drawer moves)
local function overallLines(data, font, w)
    if data.overallLines and data.overallLinesW == w and data.overallLinesF == font then return data.overallLines end
    local out = buildOverallLines(data, font, w)
    data.overallLines, data.overallLinesW, data.overallLinesF = out, w, font
    return out
end
ZeD.HealthTab.overallLines = overallLines
-- how many lines the word takes at a width, for the measure: kept on the read apart from the
-- draw's lines (the measure's width is the narrowest the column draws at, the draw's may be wider,
-- and one cache for both would build the lines twice a frame)
function ZeD.HealthTab.overallLineCount(data, font, w)
    w = math.max(1, math.floor(w))
    if data.overallMeasN and data.overallMeasW == w and data.overallMeasF == font then return data.overallMeasN end
    local n
    if data.overallLines and data.overallLinesW == w and data.overallLinesF == font then n = #data.overallLines
    else n = #buildOverallLines(data, font, w) end
    data.overallMeasN, data.overallMeasW, data.overallMeasF = n, w, font
    return n
end

--- Nothing to report: no part in the list, no wound (a read with no counts, as a test's, is never calm)
-- (QA's visual noise audit 15, Nov 20 2026: "Overall 100%", a full bar, "OK" and "No injuries" said healthy four
-- ways. Calm, the bar and "No injuries" say it; the percent and the game's word come back with something to report.)
function ZeD.HealthTab.calm(data)
    return data ~= nil and data.injuredCount == 0 and (data.woundedCount or 0) == 0
end

function ZeD.HealthTab.drawOverall(panel, x, y, w, data)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local frac = (data.overall or 0) / 100
    local label = ZeD.tr("UI_ZeD_Health_Overall")
    if data.hideNumbers then
        -- the game's own reading for a doctor: its label and the damage word, the word's dot in the
        -- health colour as vanilla tints the word red (QA MD2)
        local secH = ZeD.TM:getFontHeight(T.fontF1)
        A.drawSecondary(panel, getText("IGUI_health_Overall_Body_Status"), x, y)
        y = y + secH + T.sp.xs
        local f2 = T.fontF2
        local lh = ZeD.TM:getFontHeight(f2)
        local dotSz, dotGap = T.px(6), T.px(4)
        local lines = overallLines(data, f2, math.max(1, math.floor(w - dotSz - dotGap)))
        A.drawStatusDot(panel, x, y + math.floor((lh - dotSz) / 2), A.statusColor(frac), dotSz)
        for i = 1, #lines do
            A.drawBody(panel, lines[i], x + dotSz + dotGap, y)
            y = y + lh
        end
        return y + T.sp.xs
    end
    if ZeD.HealthTab.calm(data) then
        return y + M.drawFillBar(panel, x, y, w, frac, nil, label) + T.sp.xs
    end
    y = y + M.drawStatRowDot(panel, x, y, w, label, A.pctText(frac), A.statusColor(frac)) + T.sp.rowGap
    y = y + M.drawFillBar(panel, x, y, w, frac, nil, label) + T.sp.xs
    local lines = overallLines(data, T.fontF2, math.max(1, math.floor(w)))
    local lh = ZeD.TM:getFontHeight(T.fontF2)
    for i = 1, #lines do
        A.drawBody(panel, lines[i], x, y)
        y = y + lh
    end
    return y + T.sp.xs
end

-- opts (the medical check of another player; nil for your own Health tab):
--   doctorLevel  the First Aid level of the one looking (the doctor), else the patient's own
--   bodyDamage   the body to read: on a server another player's is their remote copy
--                (getBodyDamageRemote, as vanilla's health panel reads it), else getBodyDamage
function ZeD.HealthTab.gatherData(playerObj, opts)
    ensurePartNames()
    ensureBodyPartTypes()

    local bd = (opts and opts.bodyDamage) or playerObj:getBodyDamage()
    local parts = bd:getBodyParts()
    local nParts = parts:size()
    local overall = bd:getOverallBodyHealth()

    local entries = {}
    local partHealth = {}        -- figureName → health%
    local condsByFigureName = {} -- figureName → conditions array
    local extraByFigureName = {} -- figureName → other mods' lines (see EXTRAS above)
    local woundsByFigure = {}    -- figureName → what the figure draws on the part (ZeD_BodyFigure.woundsFrom)

    -- Build a lookup: BodyPartType → figure name (once per BODY_PART_TYPES table; read only)
    if _typeToFigureFrom ~= BODY_PART_TYPES then
        _typeToFigure = {}
        for _, bp in ipairs(BODY_PART_TYPES) do
            _typeToFigure[bp.type] = bp.figure
        end
        _typeToFigureFrom = BODY_PART_TYPES
    end
    local typeToFigure = _typeToFigure

    -- The viewer is the patient here, so the patient's First Aid is the doctor's (a medical
    -- check of another player passes the doctor's own)
    local doctorLevel = (opts and opts.doctorLevel) or playerObj:getPerkLevel(Perks.Doctor)
    local partByFigure = {}      -- figureName -> the BodyPart (the medical check treats it)
    -- (Strain, the director, Nov 22 2026)
    local partStrain = {}        -- figureName -> 1 (minor) or 2 (heavy) muscle strain
    local partWound  = {}        -- figureName -> true where a wound shows (its colour wins over strain)
    local partSev    = {}        -- figureName -> the worst severity the list's dot shows (the figure's tint, Nov 23 2026)
    local strainedCount, strainWorst = 0, nil

    for i = 1, nParts do
        local bp = parts:get(i - 1)
        local health = bp:getHealth()
        local conds, stiffness, pain = classifyConditions(bp, doctorLevel, opts and opts.panelWords)
        -- a part another mod holds back until it is examined names no wound
        local held = heldBack(playerObj, bp)
        if held then conds = careOnly(conds) end
        -- other mods' wound details for this part (nil without any); the injury list
        -- carries them as tags too, the detail view draws them as lines
        local extra = extraLines(playerObj, bp)
        local listConds = extra and withExtraTags(conds, extra) or conds
        local bpType = bp:getType()
        local figureName = typeToFigure[bpType]

        -- Store health and conditions for ALL parts (figure needs full map)
        -- every strained part counts, the figure's or not (Strain, the director, Nov 22 2026)
        local strainLv = ZeD.HealthTab.strainLevel(stiffness)
        if strainLv then
            strainedCount = strainedCount + 1
            if not strainWorst or strainLv > strainWorst then strainWorst = strainLv end
        end
        if figureName then
            partByFigure[figureName] = bp
            partHealth[figureName] = health
            -- the wounds the figure draws, from what the list just read of the part, by the list's own rules
            -- (a held-back part shows only its care) (Design, Nov 22 2026)
            SEEN.held = held
            woundsByFigure[figureName] = ZeD_BodyFigure.woundsFrom(SEEN)
            partStrain[figureName] = strainLv
            if woundShows(conds, health, extra) then partWound[figureName] = true end
            -- the worst condition that is not strain (strain keeps its own tint; the list is worst first)
            partSev[figureName] = nil
            for _, c in ipairs(listConds) do
                if not c.strain then partSev[figureName] = c.severity; break end
            end
            if #conds > 0 then
                condsByFigureName[figureName] = conds
            end
            if extra then
                extraByFigureName[figureName] = extra
            end
        end

        -- Injury list: parts with conditions, reduced health, stiffness, or pain
        -- (stiffness and pain as classifyConditions read them)
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
                bodyPart   = bp,
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
        totalParts        = nParts,
        injuredCount      = #entries,
        -- "injured" means a wound/condition; reduced health alone (hunger,
        -- sickness, cold) is listed but not called an injury, and muscle strain is counted
        -- apart (strainedCount) (Strain, the director, Nov 22 2026).
        woundedCount      = (function()
            local c = 0
            for _, e in ipairs(entries) do
                for _, cd in ipairs(e.conditions) do
                    if not cd.strain then c = c + 1; break end
                end
            end
            return c
        end)(),
        strainedCount     = strainedCount,
        strainWorst       = strainWorst,
        partStrain        = partStrain,
        partWound         = partWound,
        partSev           = partSev,
        partHealth        = partHealth,
        condsByFigureName = condsByFigureName,
        extraByFigureName = extraByFigureName,
        isFemale         = playerObj:isFemale(),
        partByFigure     = partByFigure,
        woundsByFigure   = woundsByFigure,
        skinTone         = ZeD_BodyFigure.skinToneOf(playerObj),
        -- (QA MD2, Nov 26 2026) a doctor's look at someone else: no health figures, as vanilla's panel gives
        -- them only in cheat mode; drawOverall and the detail view leave the percent and its bar out
        hideNumbers      = (opts and opts.hideNumbers) and true or nil,
    }
end

-- ============================================================================
-- BODY FIGURE HELPERS
-- ============================================================================

function ZeD.HealthTab._ensureBodyFigure(win)
    if not win._healthBodyFigure then
        local fig = ZeD_BodyFigure:new(0, 0, 100, 100)  -- placeholder size: drawAt() is given the real (scaled) rect
        fig:initialise()
        fig:loadTextures()
        fig.boneLift = true   -- the tint keeps the bones light (the director, Nov 23 2026)
        win._healthBodyFigure = fig
    end
    return win._healthBodyFigure
end

function ZeD.HealthTab._drawBodyFigure(panel, win, data, px, py, pw, ph, frame)
    local fig = ZeD.HealthTab._ensureBodyFigure(win)

    if data.isFemale ~= nil then
        fig:setSex(data.isFemale)
    end

    -- the height chart in the frame's margins, under the controller's mark and the figure (Figure frame, Nov 22 2026)
    if frame then fig:drawChart(panel, frame) end

    -- Color a hurt part by its health, a strained part without a wound in the strain tint (Strain, the director,
    -- Nov 22 2026); a healthy part takes no tint (the director, Nov 23 2026)
    -- (no clearColors: gatherData maps every part each time, and the figure reuses its colour tables) (beast W19)
    for figureName, health in pairs(data.partHealth) do
        ZeD.HealthTab.tintPart(fig, data, figureName, health)
    end
    -- the wounds and their care over the parts, on the character's own skin (Design, Nov 22 2026)
    fig:setSkinTone(data.skinTone)
    for figureName in pairs(data.partHealth) do
        fig:setPartWounds(figureName, data.woundsByFigure and data.woundsByFigure[figureName])
    end

    -- Read the _healthActivePart resolved at the top of HealthTab.render (the
    -- controller's focus overrides mouse hover): one source of truth, so the
    -- detail view and the figure always show the same part.
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

--- Open the treatment menu for one part, named as the figure or the injury
--- list names it. The controller's path passes no panel or position.
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
    ZeD.HealthTab.treat(playerObj, nil, bp, anchor, relX or 0, relY or 0, nil)
end

--- The game's treatment menu for one body part, through a thin adapter that stands in for
--- vanilla's ISHealthPanel (ISHealthPanel:doBodyPartContextMenu and its 13 handlers, unchanged):
--- character = the patient, otherPlayer = the doctor when it is someone else (vanilla's
--- setOtherPlayer: a medical check of another player), so every handler's getDoctor and getPatient
--- and the game's own timed actions are vanilla's. blocking = vanilla's blockingMessage (too far
--- away): the menu is built and kept hidden, as vanilla does. The menu opens at (rx, ry) in the
--- anchor panel; with a controller it takes the focus as vanilla's does.
function ZeD.HealthTab.treat(patient, doctor, bp, anchor, rx, ry, blocking)
    if not (patient and bp and anchor) then return end
    -- no menu for the doctor's player (the character died: the game drops its UI data): nothing to open
    local docPl = doctor or patient
    local okN, dnum = pcall(function() return docPl:getPlayerNum() end)
    if okN and getPlayerContextMenu and not getPlayerContextMenu(dnum) then return end
    local adapter = {
        character       = patient,
        otherPlayer     = (doctor ~= nil and doctor ~= patient) and doctor or nil,
        blockingMessage = blocking,
        actions         = {},
    }
    function adapter:getDoctor() return self.otherPlayer or self.character end
    -- (vanilla's ISHealthPanel:getPatient; a mod's treatment entries ask for it, e.g. Wound Expansion's)
    function adapter:getPatient() return self.character end
    function adapter:getAbsoluteX() return anchor:getAbsoluteX() end
    function adapter:getAbsoluteY() return anchor:getAbsoluteY() end
    adapter.checkItems          = ISHealthPanel.checkItems
    adapter.checkContainerItems = ISHealthPanel.checkContainerItems

    -- a mod that opens this part's menu itself (EXTRAS: openPart) has it; only for one's own body (a doctor's
    -- look at another player stays the game's menu)
    if doctor == nil or doctor == patient then
        for _, e in ipairs(ZeD.HealthTab.extras) do
            if e.openPart then
                local ok, done = pcall(e.openPart, patient, bp, adapter, rx or 0, ry or 0)
                if ok and done == true then return adapter end
            end
        end
    end

    ISHealthPanel.doBodyPartContextMenu(adapter, bp, rx or 0, ry or 0)
    -- (KISS #29) the game opens nothing when no treatment fits; for one's own body the character says what is missing
    if doctor == nil or doctor == patient then pcall(ZeD.HealthTab.sayNothingFits, patient, bp, dnum) end
    return adapter
end

--- (KISS #29) A treatment menu that came up empty names what is missing: "Left Forearm needs a bandage." or, with
--- nothing wrong there, "Left Forearm: nothing to treat." Runs after the game built (and hid) the empty menu.
function ZeD.HealthTab.sayNothingFits(patient, bp, playerNum)
    local ctx = getPlayerContextMenu and getPlayerContextMenu(playerNum)
    if not ctx or ctx:getIsVisible() then return end   -- a menu is up: nothing to say
    local name = BodyPartType.getDisplayName(bp:getType())
    local needs = {}
    local bandaged = bp:bandaged()
    local open = bp:scratched() or bp:isCut() or bp:bleeding() or bp:deepWounded() or (bp:getBurnTime() > 0)
    if open and not bandaged then needs[#needs + 1] = ZeD.tr("UI_ZeD_Health_NeedBandage") end
    if bp:deepWounded() and not bp:stitched() then needs[#needs + 1] = ZeD.tr("UI_ZeD_Health_NeedStitch") end
    if bp:getFractureTime() > 0 and bp:getSplintFactor() == 0 then needs[#needs + 1] = ZeD.tr("UI_ZeD_Health_NeedSplint") end
    if bp:haveGlass() or bp:haveBullet() then needs[#needs + 1] = ZeD.tr("UI_ZeD_Health_NeedTweezers") end
    local text
    if #needs > 0 then
        text = ZeD.tr("UI_ZeD_Disclose_Needs", name, table.concat(needs, ", "))
    else
        text = ZeD.tr("UI_ZeD_Health_NothingToTreat", name)
    end
    patient:setHaloNote(text)
end

--- (KISS #29) A left press on a wound or a hurt part (the figure's part, or an injury row) opens that part's
--- treatments, as the right-click does and as the tour says. The press only marks the part; the menu opens on the
--- first frame after the button is up (HealthTab.render), so the release never lands on the menu it just opened.
--- Returns true when a part was hit. Same hit tests as the right-click's (ZeD_CharacterWindow's _healthTreatAt).
function ZeD.HealthTab.pressAt(win, x, y)
    if win._healthBandY and y >= win._healthBandY then return false end
    local fz = win._healthFigureZone
    if fz and y < fz.y + fz.h then return false end
    local sc = win._healthScroll
    if sc and sc.visible and x >= sc.x then return false end
    local part = nil
    if win._healthFigureExpanded and win._healthBodyFigure then part = win._healthBodyFigure:hitTestAt(x, y) end
    if not part then
        for _, z in ipairs(win._healthInjuryZones or {}) do
            if x >= z.x and x <= z.x + z.w and y >= z.y and y <= z.y + z.h then part = z.bodyPartName; break end
        end
    end
    if not part then return false end
    win._healthPress = { part = part, x = x, y = y, at = getTimestampMs() }
    return true
end

--- The pending press opens its menu once the button is up (a press older than two seconds is dropped).
local function openPendingPress(win, panel)
    local pr = win._healthPress
    if not pr then return end
    if getTimestampMs() - pr.at > 2000 then win._healthPress = nil; return end
    if isMouseButtonDown(0) then return end
    win._healthPress = nil
    -- (a press on the band's Treat: the picked part's menu, at the button) (the director, Nov 23 2026)
    if pr.treat then ZeD.HealthTab.treatSelected(win); return end
    ZeD.HealthTab._onPartClicked(win, pr.part, panel, pr.x, pr.y)
end

--- A drop on the Health tab: things dragged from a list and released over a body part of the figure, or over
--- an injury row, go to the game's own ISHealthPanel:dropItemsOnBodyPart (a bandage is put on, a poultice
--- applied, and so on) through the same thin adapter. The same hit tests as the right-click treat menu
--- (ZeD_CharacterWindow's _healthTreatAt). True when it took the drop. (QA K2-7)
function ZeD.HealthTab.takeDrop(pn, items)
    local win = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow(pn)
    if not (win and items and items[1]) then return false end
    if win._drawerMode ~= "tab" or win._activeTab ~= "health" or (win._drawerEffW or 0) <= 0 then return false end
    local panel = win._healthContentPanel
    if not (panel and panel:isVisible()) then return false end
    local x, y = panel:getMouseX(), panel:getMouseY()
    if x < 0 or y < 0 or x >= panel:getWidth() or y >= panel:getHeight() then return false end
    -- (paused, only moves between bags go: a drop on the page treats nothing; KISS #41)
    if ZeD.PausedLook and ZeD.PausedLook.on() == true then return true end
    if win._healthMenuOpen then return false end
    if win._healthBandY and y >= win._healthBandY then return false end
    local fz = win._healthFigureZone
    if fz and y < fz.y + fz.h then return false end
    local sc = win._healthScroll
    if sc and sc.visible and x >= sc.x then return false end
    -- which part: the figure's (while it is open), else an injury row
    local figureName = nil
    if win._healthFigureExpanded and win._healthBodyFigure then
        figureName = win._healthBodyFigure:hitTestAt(x, y)
    end
    if not figureName then
        for _, z in ipairs(win._healthInjuryZones or {}) do
            if x >= z.x and x <= z.x + z.w and y >= z.y and y <= z.y + z.h then figureName = z.bodyPartName; break end
        end
    end
    if not figureName then return false end
    ensureFigureToBPType()
    local bpType = FIGURE_TO_BPTYPE[figureName]
    local playerObj = win._playerObj
    local bp = bpType and playerObj and playerObj:getBodyDamage():getBodyPart(bpType)
    if not bp then return false end
    -- the adapter stands in for vanilla's health panel (as in ZeD.HealthTab.treat); it is the patient's own body
    local adapter = { character = playerObj, otherPlayer = nil, actions = {} }
    function adapter:getDoctor() return self.character end
    function adapter:getPatient() return self.character end
    adapter.checkItems          = ISHealthPanel.checkItems
    adapter.checkContainerItems = ISHealthPanel.checkContainerItems
    ISHealthPanel.dropItemsOnBodyPart(adapter, bp, items)
    return true
end

-- ============================================================================
-- THE SUMMARY LINE (the Health tab's and the medical check's)
-- Count WOUNDS, not low health. A hungry character with every part
-- at 77% is not "17 of 17 injured"; low health shows as a dim note.
-- Muscle strain is counted apart, in the game's words (Strain, the director, Nov 22 2026):
--   strain only:       "No injuries, Muscle Strain: 6" (the dot in the strain tint)
--   wounds and strain: "3 of 17 injured", then "Muscle Strain: 6 of 17" on a line of its own
-- ============================================================================

--- The summary's lines for a read: a list of { text, dot } (dot: a colour, or nil for none)
function ZeD.HealthTab.summaryLines(data)
    local T = ZeD.T
    local wounded = data.woundedCount or data.injuredCount
    local strained = data.strainedCount or 0
    local strainWord = getText("IGUI_health_Stiffness")   -- the game's own "Muscle Strain"
    local out = {}
    if wounded == 0 then
        if strained > 0 then
            out[1] = { text = ZeD.tr("UI_ZeD_Health_NoInjuriesStrain", strainWord, strained),
                       dot = ZeD.HealthTab.strainColor(data.strainWorst or 1) }
        else
            -- (a part listed for low health alone: the yellow dot and the low-health words)
            out[1] = { text = (data.injuredCount > 0) and ZeD.tr("UI_ZeD_Health_NoInjuriesLow") or ZeD.tr("UI_ZeD_Health_NoInjuries"),
                       dot = (data.injuredCount > 0) and T.warning or T.positive }
        end
    else
        out[1] = { text = ZeD.tr("UI_ZeD_Health_InjuredOf", wounded, data.totalParts) }
        if strained > 0 then
            out[2] = { text = ZeD.tr("UI_ZeD_Health_StrainOf", strainWord, strained, data.totalParts),
                       dot = ZeD.HealthTab.strainColor(data.strainWorst or 1) }
        end
    end
    return out
end

--- How many lines the summary takes for a read (the measure's count)
function ZeD.HealthTab.summaryLineCount(data)
    if not data then return 1 end
    local wounded = data.woundedCount or data.injuredCount or 0
    return (wounded > 0 and (data.strainedCount or 0) > 0) and 2 or 1
end

--- Draw the summary's lines at (x, y); returns the y under them
function ZeD.HealthTab.drawSummary(panel, data, x, y)
    local T, A = ZeD.T, ZeD.Atoms
    local secH = ZeD.TM:getFontHeight(T.fontF1)
    local bodyFH = ZeD.TM:getFontHeight(T.fontF2)
    local dotSz, dotGap = T.px(6), T.px(4)
    for _, ln in ipairs(ZeD.HealthTab.summaryLines(data)) do
        if ln.dot then
            A.drawStatusDot(panel, x, y + math.floor((bodyFH - dotSz) / 2), ln.dot, dotSz)
            A.drawBody(panel, ln.text, x + dotSz + dotGap, y)
        else
            A.drawBody(panel, ln.text, x, y)
        end
        y = y + secH + T.sp.sm
    end
    return y
end

-- ============================================================================
-- THE TREATMENT CARD (the director, Nov 23 2026): with an injury, the middle
-- column lists each hurt part, worst first, in place of the exercise's info, and
-- the footer band picks a part and opens the game's treatment menu for it (Treat,
-- where Start is). Muscle strain is listed too, but the game has no treatment for
-- it: strain alone keeps the exercise footer, and a part with strain alone is not
-- in the Treat pop-up. With nothing listed the column and the band are the
-- exercise's, as before.
-- ============================================================================

-- a read of the body as given, or read from a player first
local function asRead(data)
    if data ~= nil and (type(data) ~= "table" or (data.entries == nil and data.getBodyDamage)) then
        return ZeD.HealthTab.gatherData(data)
    end
    return data
end

--- The middle column's rows, from one read of the body (gatherData's table; a player is read first).
--- Each part with a condition: a "wound" row when one of its conditions is not strain (woundedCount's rule, so a
--- part with care alone, a bandage, stitches or pain, is listed and can be treated: the game's menu changes or
--- takes off a bandage), else a "strain" row. Wounds come first, worst first (SEV_ORDER, then lower health: the
--- order of data.entries), then the strained parts, heavy first. A part listed below for low health alone is no
--- row here. Each row: { name, health, conditions, worstSev, bodyPart, treat = true for a wound, strainLv }.
--- Kept on the read (a new read every 250 ms).
function ZeD.HealthTab.injuryList(data)
    data = asRead(data)
    if not data then return {} end
    if data.injuryRows then return data.injuryRows end
    local rows, strained = {}, {}
    for _, e in ipairs(data.entries or {}) do
        local conds = e.conditions or {}
        if #conds > 0 then
            local wound = false
            for _, c in ipairs(conds) do
                if not c.strain then wound = true; break end
            end
            local row = { name = e.name, health = e.health, conditions = conds, worstSev = e.worstSev,
                          bodyPart = e.bodyPart, treat = wound }
            if wound then
                rows[#rows + 1] = row
            else
                -- (strain alone: its worst word is Muscle Strain, "danger", at 20 or more)
                row.strainLv = (e.worstSev == "danger") and 2 or 1
                strained[#strained + 1] = row
            end
        end
    end
    for _, r in ipairs(strained) do rows[#rows + 1] = r end
    data.injuryRows = rows
    return rows
end

--- The Treat pop-up's parts: the wound rows of injuryList, in its order (worst first). Kept on the read.
function ZeD.HealthTab.treatParts(data)
    data = asRead(data)
    if not data then return {} end
    if data.treatRows then return data.treatRows end
    local out = {}
    for _, r in ipairs(ZeD.HealthTab.injuryList(data)) do
        if r.treat then out[#out + 1] = r end
    end
    data.treatRows = out
    return out
end

--- "treat" while a part the game's treatment menu can act on is listed, else "exercise" (strain alone keeps the
--- exercise). Stamped on the window as win._healthFooterMode (the pad's stops and QA read it).
function ZeD.HealthTab.footerMode(win)
    if not win then return "exercise" end
    local data = win._healthCache
    if not data and win._playerObj then
        data = ZeD.HealthTab.gatherData(win._playerObj)
        win._healthCache = data
    end
    local mode = (#ZeD.HealthTab.treatParts(data) > 0) and "treat" or "exercise"
    win._healthFooterMode = mode
    return mode
end

--- The part the Treat pop-up has picked (a row of treatParts), per window: the worst until one is picked; once the
--- picked part heals, the worst again (the pick is dropped). Nil with nothing to treat.
function ZeD.HealthTab.selectedTreatPart(win)
    if not win then return nil end
    local rows = ZeD.HealthTab.treatParts(win._healthCache)
    if #rows == 0 then return nil end
    local sel = win._healthTreatSel
    if sel then
        for _, r in ipairs(rows) do
            if r.name == sel then return r end
        end
        win._healthTreatSel = nil   -- (healed: back to the worst)
    end
    return rows[1]
end

--- Shut the pop-up list; pickName, when given, becomes the picked part (the pad goes back to the box).
function ZeD.HealthTab.pickTreatPart(win, pickName)
    if pickName then win._healthTreatSel = pickName end
    win._healthMenuOpen = false
    win._healthMenuZones = nil
    win._healthReturnToMenu = true
end

--- Treat: the game's treatment menu for the picked part, the same menu a click on that part of the figure opens,
--- anchored at the Treat button. Returns true when it asked for the menu.
function ZeD.HealthTab.treatSelected(win)
    local row = ZeD.HealthTab.selectedTreatPart(win)
    local p = win and win._playerObj
    if not (row and row.bodyPart and p) then return false end
    local anchor = win._healthContentPanel or win
    local b = win._healthBand and win._healthBand.start
    ZeD.HealthTab.treat(p, nil, row.bodyPart, anchor, b and b.x or 0, b and b.y or 0, nil)
    return true
end

-- One row's dot: a strained part's in the strain tint (as the figure and the summary draw it), else the worst
-- condition's status colour
local function injuryDot(r)
    if r.strainLv then return ZeD.HealthTab.strainColor(r.strainLv) end
    return sevColor(r.worstSev)
end

-- Lays the rows out for a column width w (no drawing): the status dot, the part's name wrapped beside it, its
-- condition words under the name (the condition tags, their squares under the dot). Returns { items, h }.
local function layoutInjuryList(rows, w)
    local T, A, TM = ZeD.T, ZeD.Atoms, ZeD.TM
    local f2 = T.fontF2
    local h2 = TM:getFontHeight(f2)
    local lg, sg = T.px(2), T.sp.xs
    local hang = tagHang()                           -- (the words start past the dot, as the tags' words do)
    local textW = math.max(T.px(20), w - hang)
    local items, y = {}, 0
    for _, r in ipairs(rows) do
        local lines = A.wrapText(ZeD.partLabel(r.name), f2, textW)
        local nameH = #lines * (h2 + lg)
        local tagsH = condTags(nil, r.conditions, 0, 0, textW, hang)
        items[#items + 1] = { y = y, lines = lines, tagsY = y + nameH, conds = r.conditions, dot = injuryDot(r) }
        y = y + nameH + ((tagsH > 0) and (tagsH + lg) or 0) + sg
    end
    return { items = items, h = y, fh = h2, lg = lg, hang = hang, textW = textW }
end

-- The layout for a read at a width, kept on the window under slot (the draw's and the measure's apart, as their
-- widths can differ): rebuilt only when the rows' words, the width or the fonts change, checked once per read.
local function injuryLayout(win, slot, data, w)
    local c = win[slot]
    if c and c.data == data and c.w == w then return c.lay end
    local T, TM = ZeD.T, ZeD.TM
    local rows = ZeD.HealthTab.injuryList(data)
    local sig = { tostring(w), tostring(T.scale), TM:getFontHeight(T.fontF1), TM:getFontHeight(T.fontF2) }
    for _, r in ipairs(rows) do
        sig[#sig + 1] = r.name
        sig[#sig + 1] = tostring(r.strainLv or r.worstSev)
        for _, cd in ipairs(r.conditions) do sig[#sig + 1] = cd.label end
    end
    local key = table.concat(sig, "|")
    if not (c and c.key == key) then
        c = { key = key, lay = layoutInjuryList(rows, w) }
        win[slot] = c
    end
    c.data, c.w = data, w
    return c.lay
end

local function drawInjuryList(panel, x, y, lay)
    local T, A = ZeD.T, ZeD.Atoms
    local dotSz = T.px(6)
    for _, it in ipairs(lay.items) do
        local iy = y + it.y
        if it.dot then A.drawStatusDot(panel, x, iy + math.floor((lay.fh - dotSz) / 2), it.dot, dotSz) end
        for i, line in ipairs(it.lines) do
            A.drawBody(panel, line, x + lay.hang, iy + (i - 1) * (lay.fh + lay.lg))
        end
        condTags(panel, it.conds, x + lay.hang, y + it.tagsY, lay.textW, lay.hang)
    end
end

--- Divider, then the injury list (injuryList) in the middle column, where the exercise's info is with no injury.
--- Its room is the measure's (_measureExerciseInfo), so nothing under it overlaps.
function ZeD.HealthTab._renderInjuryInfo(panel, win, data, rx, ry, rw)
    local T, A = ZeD.T, ZeD.Atoms
    local w = math.min(rw, win._healthInfoW or rw)
    A.drawDividerH(panel, rx, ry, rw)
    local y = ry + T.px(1) + T.sp.afterGroove
    local lay = injuryLayout(win, "_healthInjLay", data, w)
    drawInjuryList(panel, rx, y, lay)
    win._healthInfoShown = nil                                  -- (no exercise described this frame)
    win._healthInjuryShown = #ZeD.HealthTab.injuryList(data)   -- how many rows the column listed (QA reads it)
    win._healthInfoUsedH = lay.h
    return y + math.max(win._healthInfoH or 0, lay.h)
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

    -- Overall: the row and its bar, then the game's own word for it (its health panel's
    -- Overall Body Status) on its own line
    curY = ZeD.HealthTab.drawOverall(panel, rx, curY, rw, data)

    -- Summary line(s) (drawSummary above)
    curY = ZeD.HealthTab.drawSummary(panel, data, rx, curY)

    -- With an injury or muscle strain: each hurt part, worst first (the director, Nov 23 2026).
    -- Else what vanilla's fitness window says about the picked exercise: description,
    -- stiffness, regularity, warnings (the exercise itself is picked in the band)
    if #ZeD.HealthTab.injuryList(data) > 0 then
        win._healthMiddle = "injuries"   -- (what the column shows: QA reads it)
        curY = ZeD.HealthTab._renderInjuryInfo(panel, win, data, rx, curY, rw)
    else
        win._healthMiddle = "exercise"
        win._healthInjuryShown = 0
        curY = ZeD.HealthTab._renderExerciseInfo(panel, win, rx, curY, rw)
    end

    return curY
end

-- ============================================================================
-- ZONE A RIGHT COLUMN: HOVER DETAIL VIEW
-- Shows health + conditions for the hovered body part (the medical check of
-- another player, ObjectCardMedic.lua, draws the same view).
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

    -- Health % stat row and its bar (not for a doctor's look at someone else: QA MD2, Nov 26 2026)
    if not data.hideNumbers then
        local pct = math.floor(health + 0.5)
        local pctColor = pctToStatusColor(pct)
        local rowH = M.drawStatRowDot(panel, rx, curY, rw, getText("IGUI_XP_Health"), pct .. "%", pctColor)
        curY = curY + rowH + T.sp.rowGap
        local barH = M.drawFillBar(panel, rx, curY, rw, health / 100, nil, ZeD.tr("IGUI_XP_Health"))
        curY = curY + barH + T.sp.sm
    end

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

-- The exercises, in the order the footer band's pop-up lists them: the bodyweight
-- ones, then the ones that need equipment
local EXERCISES = {
    "squats", "pushups", "situp", "burpees",
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

-- The exercise state the DRAWING reads, kept on the tab's own 250 ms clock (beast W18): the block key, the climbing
-- rule, which of the exercises have their item, and (in exerciseInfo) the picked one's info. Without it every frame
-- searched the inventory with its bags 3 to 5 times and read the moodles about 10 times. Clicks still use the live
-- canStart / exerciseBlockKey.
local function exerciseState(win)
    local p = win and win._playerObj
    if not p then return nil end
    local st = win._healthEx
    if dueMs(win, "_healthExAt", 250, st == nil) then
        st = { blockKey = exerciseBlockKey(p), canEx = canExercise(p), avail = {} }
        for _, id in ipairs(EXERCISES) do st.avail[id] = isExerciseAvailable(p, id) end
        win._healthEx = st
    end
    return st
end
ZeD.HealthTab._exerciseState = exerciseState

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
-- st: the cached exercise state (exerciseState), given by the drawing; nil reads the live values
function ZeD.HealthTab.exerciseInfo(playerObj, exeId, skipReg, st)
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
    local have = true
    if exeData.item then
        if st and st.avail[exeId] ~= nil then have = st.avail[exeId] else have = isExerciseAvailable(playerObj, exeId) end
    end
    if exeData.item and not have then
        local itemName = getItemDisplayName and getItemDisplayName(exeData.item) or exeData.item
        info.warn[#info.warn + 1] = getText("IGUI_FitnessNeedItem", itemName)
    end
    local blockKey
    if st then blockKey = st.blockKey else blockKey = exerciseBlockKey(playerObj) end
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

    -- (QA's visual noise audit 15, Nov 20 2026: the block was headed "Squats" right under the pop-up's "Exercise:
    -- Squats"; the pop-up names it, the block starts at the description)

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
                A.drawFillBar(panel, x, iy + it.fh + it.lg, w, info.regularity, false, T.positive, nil, it.text)
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

--- The exercise the footer band's pop-up has picked (what the info describes and
--- Start does), per window; vanilla's preselected squats until one is picked.
function ZeD.HealthTab.selectedExercise(win)
    return win and win._healthExerciseSel or "squats"
end

-- ----------------------------------------------------------------------------
-- PUTTING GEAR BACK after a session (vanilla ISFitnessUI:update, lines 213-229).
-- The game's fitness window notes what it took off (hands and worn bags) and puts
-- it back once the session ends (getCurrentExe() goes nil). ZeD's Start takes the
-- same things off, so it keeps the same note per player and a watcher puts them
-- back, whether or not the Health tab is still open.
-- ----------------------------------------------------------------------------
ZeD.HealthTab._reequip = ZeD.HealthTab._reequip or {}   -- [playerNum] = { player = IsoPlayer, list = { {kind, item}, ... } }

--- Note what the session takes off, before it is taken off (vanilla equipItems order).
--- Returns the note's list (also used by the sim).
function ZeD.HealthTab._noteGear(playerObj)
    local list = {}
    local prim = playerObj:getPrimaryHandItem()
    if prim and playerObj:isItemInBothHands(prim) then
        list[#list + 1] = { kind = "twohands", item = prim }
    else
        if prim then list[#list + 1] = { kind = "primary", item = prim } end
        local sec = playerObj:getSecondaryHandItem()
        if sec and sec ~= prim then list[#list + 1] = { kind = "secondary", item = sec } end
    end
    local worn = playerObj:getWornItems()
    for i = 0, worn:size() - 1 do
        local item = worn:get(i):getItem()
        if item and instanceof(item, "InventoryContainer") then
            list[#list + 1] = { kind = "worn", item = item }
        end
    end
    ZeD.HealthTab._reequip[playerObj:getPlayerNum()] = { player = playerObj, list = list }
    return list
end

--- Put a player's noted gear back (vanilla's calls); items no longer carried are skipped.
function ZeD.HealthTab._putGearBack(playerObj, note)
    local inv = playerObj:getInventory()
    for _, e in ipairs(note.list) do
        local item = e.item
        if item and inv:contains(item) and not ZeD.HealthTab._gearBack(playerObj, e) then
            if e.kind == "primary" then
                ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), item, true, false)
            elseif e.kind == "secondary" then
                ISWorldObjectContextMenu.equip(playerObj, playerObj:getSecondaryHandItem(), item, false, false)
            elseif e.kind == "twohands" then
                ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), item, true, true)
            elseif not playerObj:isEquipped(item) then
                ISInventoryPaneContextMenu.wearItem(item, playerObj:getPlayerNum())
            end
        end
    end
end

--- true when a noted item is back where it was (or is no longer carried, so there is nothing to put back)
local function gearBack(playerObj, e)
    local item = e.item
    if not item or not playerObj:getInventory():contains(item) then return true end
    if e.kind == "primary" then return playerObj:getPrimaryHandItem() == item end
    if e.kind == "secondary" then return playerObj:getSecondaryHandItem() == item end
    if e.kind == "twohands" then
        return playerObj:getPrimaryHandItem() == item and playerObj:getSecondaryHandItem() == item
    end
    local worn = playerObj:getWornItems()
    for i = 0, worn:size() - 1 do
        if worn:get(i):getItem() == item then return true end
    end
    return false
end
ZeD.HealthTab._gearBack = gearBack

--- true while the character is still busy: an action in the queue, or not yet back to standing idle (the
--- fitness animation's way out). The game's fitness stop clears the whole action queue a moment after the
--- exercise is cleared (ISBaseTimedAction.stop -> resetQueue), so anything queued before then is lost.
local function gearBusy(playerObj)
    local q = ISTimedActionQueue.getTimedActionQueue(playerObj)
    if q and q.queue and q.queue[1] then return true end
    if IdleState and IdleState.instance then
        local ok, idle = pcall(function() return playerObj:isCurrentState(IdleState.instance()) end)
        if ok and not idle then return true end
    end
    return false
end

local GEAR_TRIES  = 2       -- the put-back is queued at most twice (a second time if the first was cut off)
local GEAR_WAITMS = 60000   -- a note still waiting a minute after the session is dropped (the player moved on)

--- The watcher: once a noted player's session is over and the character stands idle with nothing queued,
--- queue the gear back on; keep the note until every item is really back (QA hg5, Nov 23 2026).
function ZeD.HealthTab._reequipTick(playerObj)
    if not playerObj then return end
    local pn = playerObj:getPlayerNum()
    local note = ZeD.HealthTab._reequip[pn]
    if not note then return end
    if note.player ~= playerObj or playerObj:isDead() then      -- a new character in that seat
        ZeD.HealthTab._reequip[pn] = nil
        return
    end
    if playerObj:getFitness():getCurrentExe() then return end   -- still exercising
    local now = getTimestampMs()
    note.endedAt = note.endedAt or now
    if gearBusy(playerObj) then
        if now - note.endedAt > GEAR_WAITMS then ZeD.HealthTab._reequip[pn] = nil end
        return
    end
    local allBack = true
    for _, e in ipairs(note.list) do
        if not gearBack(playerObj, e) then allBack = false; break end
    end
    if allBack or (note.tries or 0) >= GEAR_TRIES then
        ZeD.HealthTab._reequip[pn] = nil
        return
    end
    note.tries = (note.tries or 0) + 1
    ZeD.HealthTab._putGearBack(playerObj, note)
end
if not ZeD.HealthTab._reequipHooked and Events and Events.OnPlayerUpdate then   -- (no Events in some sims)
    ZeD.HealthTab._reequipHooked = true
    Events.OnPlayerUpdate.Add(function(p) ZeD.HealthTab._reequipTick(p) end)
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

    -- Note the hands and bags first, so they go back on when the session ends
    ZeD.HealthTab._noteGear(playerObj)

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

-- ----------------------------------------------------------------------------
-- THE FOOTER BAND: the exercise as a pop-up menu and the session time (- 10 +)
-- at the left, Start at the right (pick, then act, as Craft). Start keeps
-- vanilla's guards (canStart) and runs vanilla's fitness action (_startExercise).
-- ----------------------------------------------------------------------------

-- true while the character is in the middle of a fitness session
local function isExercising(playerObj)
    local q = ISTimedActionQueue.getTimedActionQueue(playerObj)
    return (q ~= nil and q.queue ~= nil and q.queue[1] ~= nil and q.queue[1].Type == "ISFitnessAction")
end

-- Start's guards: the global rules (vanilla ISFitnessUI:updateButtons), no
-- session already running, the picked exercise's item
function ZeD.HealthTab.canStart(win)
    local p = win and win._playerObj
    if not p then return false end
    return canExercise(p) and not isExercising(p)
        and isExerciseAvailable(p, ZeD.HealthTab.selectedExercise(win))
end

--- Start: the picked exercise for the chosen time, through vanilla's fitness action.
--- Returns true when it started one.
function ZeD.HealthTab.startSelected(win)
    if not ZeD.HealthTab.canStart(win) then return false end
    ZeD.HealthTab._startExercise(win._playerObj, ZeD.HealthTab.selectedExercise(win),
        ZeD.HealthTab.getExerciseMinutes(win))
    return true
end

--- The session time's - and +: one step (a multiple of 10 minutes), kept inside 10 to 60.
--- Returns true when the time changed.
function ZeD.HealthTab.stepMinutes(win, step)
    if not win then return false end
    local was = ZeD.HealthTab.getExerciseMinutes(win)
    local m = math.max(MIN_EXERCISE_TIME, math.min(MAX_EXERCISE_TIME, was + step))
    win._healthExerciseMinutes = m
    return m ~= was
end

--- The exercise pop-up list: opened by the box, shut by a pick, a click anywhere else or B;
--- the pad returns to the box it came from (_healthReturnToMenu, read by the tab's focusables)
function ZeD.HealthTab.openMenu(win)
    win._healthMenuOpen = true
    win._healthMenuZones = nil
end

--- True while the exercise or treat list is open (ZeD.Popups lets go of a list its owner shut).
function ZeD.HealthTab.menuIsOpen(win) return win._healthMenuOpen == true end

--- Shut the list; pickId, when given, becomes the picked exercise.
function ZeD.HealthTab.closeMenu(win, pickId)
    if pickId then win._healthExerciseSel = pickId end
    win._healthMenuOpen = false
    win._healthMenuZones = nil
    win._healthReturnToMenu = true
end

local function inRect(r, x, y)
    return r ~= nil and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h
end

--- The mouse path through the band: an open list takes every press (a pick or shut it);
--- else the box opens it, - and + step the time, Start starts. Returns true when the press
--- was the band's (the whole band swallows it).
function ZeD.HealthTab.onClick(win, x, y)
    local treat = win._healthFooterMode == "treat"   -- (the band is the treatment's: the director, Nov 23 2026)
    if win._healthMenuOpen then
        for _, z in ipairs(win._healthMenuZones or {}) do
            if inRect(z, x, y) then
                if treat then ZeD.HealthTab.pickTreatPart(win, z.id) else ZeD.HealthTab.closeMenu(win, z.id) end
                return true
            end
        end
        ZeD.HealthTab.closeMenu(win)
        return true
    end
    local bz = win._healthBand
    -- a fill block's head or row, inside the body's view (not under the header or the band)
    if not (bz and y >= bz.y) and inRect(win._healthView, x, y) and ZeD.TabFill.onClick(win, "health", x, y) then return true end
    if not bz or y < bz.y or y >= bz.y + bz.h then
        -- (KISS #29) not the band: a wound or a hurt part under the press opens its treatments
        return ZeD.HealthTab.pressAt(win, x, y)
    end
    if inRect(bz.box, x, y) then ZeD.HealthTab.openMenu(win)
    elseif treat then
        -- Treat opens the game's menu once the button is up (openPendingPress), so the release never lands on it
        if inRect(bz.start, x, y) and ZeD.HealthTab.selectedTreatPart(win) then
            win._healthPress = { treat = true, x = x, y = y, at = getTimestampMs() }
        end
    elseif inRect(bz.dec, x, y) then ZeD.HealthTab.stepMinutes(win, -EXERCISE_TIME_STEP)
    elseif inRect(bz.inc, x, y) then ZeD.HealthTab.stepMinutes(win, EXERCISE_TIME_STEP)
    elseif inRect(bz.start, x, y) then ZeD.HealthTab.startSelected(win) end
    return true
end

-- Start's help line: why it is greyed (vanilla's own reasons) or what it will do
local function startHelp(playerObj, sel, mins, enabled)
    if not enabled then
        local key = exerciseBlockKey(playerObj)
        if key then return getText(key) end
        local d = FitnessExercises and FitnessExercises.exercisesType and FitnessExercises.exercisesType[sel]
        if d and d.item and not isExerciseAvailable(playerObj, sel) then
            return getText("IGUI_FitnessNeedItem", getItemDisplayName and getItemDisplayName(d.item) or d.item)
        end
    end
    return ZeD.tr("UI_ZeD_Health_HelpExercise", ZeD.HealthTab.exerciseLabel(sel), mins)
end

local _bandBtns = { {} }
local _bandSpec = { buttons = _bandBtns }
local _stepOpts = {}

-- the band's rects for the click and the pad; one table per window, filled each frame
local function bandZones(win)
    local bz = win._healthBand
    if not bz then
        bz = { box = {}, dec = {}, inc = {}, start = {} }
        win._healthBand = bz
    end
    return bz
end

local function setRect(r, x, y, w, h)
    r.x, r.y, r.w, r.h = x, y, w, h
end

-- the - readout + keys of the session time, from x (the rects are stamped)
local function drawTimeStep(panel, win, bz, x, by, readW, mins, open)
    local T, A, M, TM = ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.TM
    local bh, f3 = T.buttonH, T.fontF3
    local o = _stepOpts
    o.win = win
    o.disabled = mins <= MIN_EXERCISE_TIME
    o.hover = (not open) and A.mouseIn(panel, x, by, bh, bh)
    o.focus = focusOf(win, "health:time:dec")
    o.help = ZeD.tr("UI_ZeD_Health_HelpTimeLess")
    M.drawButton(panel, x, by, bh, bh, "-", "default", false, nil, o)
    setRect(bz.dec, x, by, bh, bh)
    local minStr = tostring(mins)
    local tc = T.text
    panel:drawText(minStr, x + bh + math.floor((readW - TM:MeasureStringX(f3, minStr)) / 2),
        by + math.floor((bh - TM:getFontHeight(f3)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f3)
    local incX = x + bh + readW
    o.disabled = mins >= MAX_EXERCISE_TIME
    o.hover = (not open) and A.mouseIn(panel, incX, by, bh, bh)
    o.focus = focusOf(win, "health:time:inc")
    o.help = ZeD.tr("UI_ZeD_Health_HelpTimeMore")
    M.drawButton(panel, incX, by, bh, bh, "+", "default", false, nil, o)
    setRect(bz.inc, incX, by, bh, bh)
end

-- The treatment band (the director, Nov 23 2026): [Injury: Left Hand v]   [Treat]. The pop-up holds the parts
-- the game's treatment menu can act on, worst first; Treat opens that menu for the picked one. No time step.
local function renderTreatBand(panel, win, x, y, w)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local bh, edge, gap = T.buttonH, T.px(8), T.px(8)
    local by = y + T.px(5)
    local row = ZeD.HealthTab.selectedTreatPart(win)
    local partName = row and ZeD.partLabel(row.name) or ""
    local open = win._healthMenuOpen == true
    local bz = bandZones(win)
    bz.y, bz.h = y, M.bandH()
    setRect(bz.dec, 0, 0, 0, 0)   -- (no time step: its rects take no press)
    setRect(bz.inc, 0, 0, 0, 0)

    -- Treat, primary at the right, where Start is (its rect is bz.start)
    local lbl = ZeD.tr("UI_ZeD_Health_Treat")
    local btnW = M.buttonW(lbl)
    local btnX = x + w - edge - btnW
    local sb = _bandBtns[1]
    sb.label, sb.variant, sb.disabled, sb.id, sb.w = lbl, "primary", row == nil, "treat", btnW
    sb.hover = (not open) and A.mouseIn(panel, btnX, by, btnW, bh)
    sb.focus = focusOf(win, "health:treat")
    sb.help = (sb.hover or sb.focus) and row and ZeD.tr("UI_ZeD_Health_HelpTreat", partName) or nil
    _bandSpec.win = win
    M.drawBand(panel, x, y, w, _bandSpec)
    setRect(bz.start, btnX, by, btnW, bh)

    -- the pop-up box: as wide as its widest part, so picking another never moves it (measured once per read)
    local data = win._healthCache
    local nat = data and data.treatNatW
    if data and not nat then
        nat = 0
        for _, r in ipairs(ZeD.HealthTab.treatParts(data)) do
            local nw = M.popupMenuW(ZeD.tr("UI_ZeD_Health_TreatPick", ZeD.partLabel(r.name)))
            if nw > nat then nat = nw end
        end
        data.treatNatW = nat
    end
    local boxX = x + edge
    local boxW = math.max(T.px(40), math.min(nat or 0, btnX - gap - boxX))
    local hov = (not open) and A.mouseIn(panel, boxX, by, boxW, bh)
    if hov and ZeD.Help then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Health_HelpTreatPick")) end
    local boxFo = focusOf(win, "health:treatPart")
    M.drawPopupMenu(panel, boxX, by, boxW, bh, ZeD.tr("UI_ZeD_Health_TreatPick", partName),
        hov or open, boxFo, row == nil, partName)   -- (the part alone when both do not fit)
    setRect(bz.box, boxX, by, boxW, bh)
    if boxFo and not open then A.padHelp(panel, ZeD.tr("UI_ZeD_Health_HelpTreatPick"), bz.box) end
end

-- The band at the card's foot, top-left (x, y): [Exercise: Squats v]  Time (minutes) - 10 +   [Start]
-- (with an injury to treat, the treatment band instead: renderTreatBand)
function ZeD.HealthTab._renderBand(panel, win, x, y, w)
    if win._healthFooterMode == "treat" then return renderTreatBand(panel, win, x, y, w) end
    local T, A, M, TM = ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.TM
    local bh, edge, gap = T.buttonH, T.px(8), T.px(8)
    local by = y + T.px(5)
    local sel = ZeD.HealthTab.selectedExercise(win)
    local mins = ZeD.HealthTab.getExerciseMinutes(win)
    -- (drawing reads the 250 ms state; startSelected still asks the live canStart) (beast W18)
    local exSt = exerciseState(win)
    local enabled = exSt ~= nil and exSt.canEx and exSt.avail[sel] == true and not isExercising(win._playerObj)
    local open = win._healthMenuOpen == true
    local bz = bandZones(win)
    bz.y, bz.h = y, M.bandH()

    -- Start, primary at the right (the band draws it)
    local startLbl = ZeD.tr("UI_ZeD_Health_Start")
    local startW = M.buttonW(startLbl)
    local startX = x + w - edge - startW
    local sb = _bandBtns[1]
    sb.label, sb.variant, sb.disabled, sb.id, sb.w = startLbl, "primary", not enabled, "start", startW
    sb.hover = (not open) and A.mouseIn(panel, startX, by, startW, bh)
    sb.focus = focusOf(win, "health:start")
    -- (Nov 14 2026, punch list 230: the focused Start's words too, beside it once the pad rests on it)
    sb.help = (sb.hover or sb.focus) and startHelp(win._playerObj, sel, mins, enabled) or nil
    _bandSpec.win = win
    M.drawBand(panel, x, y, w, _bandSpec)
    setRect(bz.start, startX, by, startW, bh)

    -- the pop-up box's room: what the time block and Start leave. Its width is the widest
    -- exercise's, so picking another never moves the time keys.
    local boxX = x + edge
    -- the widest label only changes with the language, the scale and the fonts: measured once per those (beast W18)
    local natKey = table.concat({ tostring(T.scale), TM:getFontHeight(T.fontF1),
        ZeD.tr("UI_ZeD_Health_ExercisePick", ZeD.HealthTab.exerciseLabel(EXERCISES[1])) }, "|")
    local nat = win._healthNat
    if not nat or win._healthNatKey ~= natKey then
        nat = 0
        for _, id in ipairs(EXERCISES) do
            local nw = M.popupMenuW(ZeD.tr("UI_ZeD_Health_ExercisePick", ZeD.HealthTab.exerciseLabel(id)))
            if nw > nat then nat = nw end
        end
        win._healthNat, win._healthNatKey = nat, natKey
    end
    local f1 = T.fontF1
    local timeLbl = getText("IGUI_FitnessTime")
    local lblW = TM:MeasureStringX(f1, timeLbl) + T.px(6)
    local readW = TM:MeasureStringX(T.fontF3, "60") + T.px(16)
    local blockW = lblW + bh + readW + bh
    -- the box is never narrower than its choice and its arrow ("Squats" v): short of that,
    -- the time's label goes first, then the spaces close up (the edge, the gaps, the
    -- readout's margin) (at 1280x720, UI scale 2.0 and Large text the box would
    -- otherwise read "S...")
    local exName = ZeD.HealthTab.exerciseLabel(sel)
    local need = M.popupMenuW(exName)
    if startX - gap - blockW - gap - boxX < math.max(need, math.min(nat, T.px(130))) then
        -- narrow: the time's label goes, the keys stay
        lblW = 0
        blockW = bh + readW + bh
    end
    if startX - gap - blockW - gap - boxX < need then
        boxX, gap = x + T.px(4), T.px(2)
        readW = TM:MeasureStringX(T.fontF3, "60") + T.px(8)
        blockW = lblW + bh + readW + bh
    end
    local blockX = startX - gap - blockW
    local boxW = math.max(T.px(40), math.min(nat, blockX - gap - boxX))

    -- the time: its label (vanilla's word), - minutes +
    if lblW > 0 then
        local sc = T.textSec
        panel:drawText(timeLbl, blockX, by + math.floor((bh - TM:getFontHeight(f1)) / 2), sc.r, sc.g, sc.b, sc.a or 1, f1)
    end
    drawTimeStep(panel, win, bz, blockX + lblW, by, readW, mins, open)

    -- the exercise pop-up: the box ("Exercise: Squats"); its list opens upward (_renderMenu)
    local hov = (not open) and A.mouseIn(panel, boxX, by, boxW, bh)
    if hov and ZeD.Help then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Health_HelpPick")) end
    local boxFo = focusOf(win, "health:exercise")
    M.drawPopupMenu(panel, boxX, by, boxW, bh,
        ZeD.tr("UI_ZeD_Health_ExercisePick", exName),
        hov or open, boxFo, false, exName)   -- (the name alone when both do not fit)
    setRect(bz.box, boxX, by, boxW, bh)
    if boxFo and not open then A.padHelp(panel, ZeD.tr("UI_ZeD_Health_HelpPick"), bz.box) end   -- (punch list 230)
end

local _menuModes = {}
local _treatModes = {}   -- (the treatment band's list: the parts to treat)
local _menuOpts = {}

-- The open exercise list, drawn LAST (over the body and the band), hanging up from the
-- box. Its row rects are kept for the click and the pad; the row with the controller's
-- focus carries the mark.
function ZeD.HealthTab._renderMenu(panel, win)
    local bz = win._healthBand
    if not (win._healthMenuOpen and bz) then return end
    local M, A = ZeD.Molecules, ZeD.Atoms
    -- the treatment band's list holds the parts to treat, worst first (the director, Nov 23 2026)
    local treat = win._healthFooterMode == "treat"
    local modes, selId, n = _menuModes, nil, 0
    if treat then
        modes = _treatModes
        local rows = ZeD.HealthTab.treatParts(win._healthCache)
        n = #rows
        for i = 1, n do
            local m = modes[i]
            if not m then m = {}; modes[i] = m end
            m.id, m.label = rows[i].name, ZeD.partLabel(rows[i].name)
        end
        for i = #modes, n + 1, -1 do modes[i] = nil end   -- (fewer parts than last time)
        local sr = ZeD.HealthTab.selectedTreatPart(win)
        selId = sr and sr.name
    else
        n = #EXERCISES
        for i = 1, n do
            local m = _menuModes[i]
            if not m then m = {}; _menuModes[i] = m end
            m.id, m.label = EXERCISES[i], ZeD.HealthTab.exerciseLabel(EXERCISES[i])
        end
        selId = ZeD.HealthTab.selectedExercise(win)
    end
    local hoverId = nil
    for _, z in ipairs(win._healthMenuZones or {}) do
        if A.mouseIn(panel, z.x, z.y, z.w, z.h) then hoverId = z.id; break end
    end
    local o = _menuOpts
    o.win, o.minW, o.focusId = win, bz.box.w, nil
    local F = ZeD.Input and ZeD.Input.Focus
    local el = F and F.liveElement and F.liveElement(win)
    if el and el.menuRowId then o.focusId = el.menuRowId end
    -- (Nov 14 2026, punch list 230: the focused exercise's help words, beside it once the pad rests on it)
    local tipId = hoverId or o.focusId
    local gy = math.max(0, bz.box.y - M.popupListH(n))
    local lw, lh, zs = M.drawSortMenuList(panel, bz.box.x, gy, modes, selId, hoverId, o)
    win._healthMenuZones = zs
    -- the list and its box count as inside; a press elsewhere, the tab hidden, an action or a walk shuts it
    -- (ZeD_Popups.lua, the director, Nov 23 2026)
    if ZeD.Popups then
        local po = ZeD.Popups.opts(win, "health", ZeD.HealthTab.menuIsOpen, win.playerNum or 0)
        ZeD.Popups.shownAt(po.key, panel, ZeD.HealthTab.closeMenu, po,
            bz.box.x, gy, lw, lh, bz.box.x, bz.box.y, bz.box.w, bz.box.h)
    end
    if tipId and ZeD.Help then
        local words
        if treat then words = ZeD.tr("UI_ZeD_Health_HelpTreat", ZeD.partLabel(tipId))
        else
            words = ZeD.tr("UI_ZeD_Health_HelpExercise", ZeD.HealthTab.exerciseLabel(tipId),
                ZeD.HealthTab.getExerciseMinutes(win))
        end
        if hoverId then ZeD.Help.set(win, words)
        else
            for _, z in ipairs(zs or {}) do
                if z.id == tipId then A.padHelp(panel, words, z, "right"); break end
            end
        end
    end
end

-- Divider, then the info block for the picked exercise (selectedExercise).
-- The block's room is reserved for the tallest exercise (_measureExerciseInfo),
-- so picking another exercise never moves what is below.
function ZeD.HealthTab._renderExerciseInfo(panel, win, rx, ry, rw)
    local T, A = ZeD.T, ZeD.Atoms
    -- the picked exercise's info is kept with the 250 ms state and rebuilt when the state or the pick changes (beast W18)
    local exSt = exerciseState(win)
    local selId = ZeD.HealthTab.selectedExercise(win)
    local info
    if exSt and exSt.infoId == selId then
        info = exSt.info
    else
        info = ZeD.HealthTab.exerciseInfo(win._playerObj, selId, false, exSt)
        if exSt then exSt.infoId, exSt.info = selId, info end
    end
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
function ZeD.HealthTab._measureExerciseInfo(win, w, data)
    local T, TM = ZeD.T, ZeD.TM
    -- with an injury the column lists the hurt parts instead: their room, at the same narrowest width (the director,
    -- Nov 23 2026)
    data = data or (win and win._healthCache)
    if win and data and #ZeD.HealthTab.injuryList(data) > 0 then
        local wrapW = math.max(T.px(60), ZeD.Molecules.layoutZoneA(0, 0, w - T.sp.scrollbarW).rightW)
        local lay = injuryLayout(win, "_healthInjMeas", data, wrapW)
        win._healthInfoW = wrapW
        win._healthInfoH = lay.h
        return T.px(1) + T.sp.afterGroove + lay.h
    end
    local playerObj = win and win._playerObj
    if not playerObj or not FitnessExercises or not FitnessExercises.exercisesType then return 0 end
    local wrapW = math.max(T.px(60), ZeD.Molecules.layoutZoneA(0, 0, w - T.sp.scrollbarW).rightW)
    -- (the key reads the 250 ms exercise state, not a live search each frame) (beast W18)
    local exSt = exerciseState(win)
    local sig = { wrapW, tostring(T.scale), TM:getFontHeight(T.fontF1), TM:getFontHeight(T.fontF2),
                  exSt and exSt.blockKey or "-" }
    for _, exeId in ipairs(EXERCISES) do
        sig[#sig + 1] = (exSt and exSt.avail[exeId]) and "1" or "0"
    end
    local key = table.concat(sig, "|")
    local cache = win._healthInfoCache
    if not cache or cache.key ~= key then
        local maxH = 0
        local function consider(exeId)
            local info = ZeD.HealthTab.exerciseInfo(playerObj, exeId, true)
            if info then maxH = math.max(maxH, layoutExerciseInfo(info, wrapW).h) end
        end
        for _, exeId in ipairs(EXERCISES) do consider(exeId) end
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

-- (the figure sits in its frame, the left half of the card, the text the right half; a card too narrow for halves
-- stacks them: Molecules.figureFrame) (Figure frame, the director, Nov 22 2026)

function ZeD.HealthTab._measureZoneA(data, rw, win)
    local T     = ZeD.T
    local secH  = ZeD.TM:getFontHeight(T.fontF1)

    -- Right column: summary section (its heading lives in the disclosure header): Overall's row
    -- and bar, the game's word for it (drawOverall: its wrapped lines, then a gap), the summary line
    local rightH = 0
    -- the layout at the narrowest the body draws (the scroll bar showing): never short of the draw
    local L = ZeD.Molecules.layoutZoneA(0, 0, rw - T.sp.scrollbarW)
    local f2H = ZeD.TM:getFontHeight(T.fontF2)
    local statRowH = math.max(secH, f2H) + T.px(4)
    local calm = ZeD.HealthTab.calm(data)   -- (calm: the bar alone, as drawOverall draws it)
    if not calm then rightH = rightH + statRowH + T.sp.rowGap end
    rightH = rightH + T.fillBarH + T.sp.xs
    -- (counted at the narrowest the column draws, the scroll bar showing: never short of the draw;
    -- left out, the scroll range caught up a frame late, from what the last frame drew)
    if data and not calm then
        rightH = rightH + ZeD.HealthTab.overallLineCount(data, T.fontF2, L.rightW) * f2H + T.sp.xs
    end
    -- (the summary: one line, or two with wounds and muscle strain) (Strain, the director, Nov 22 2026)
    rightH = rightH + (secH + T.sp.sm) * ZeD.HealthTab.summaryLineCount(data)

    -- Right column: the picked exercise's info block (its controls are the footer band's), or with an injury the
    -- injury list (the director, Nov 23 2026)
    rightH = rightH + ZeD.HealthTab._measureExerciseInfo(win, rw, data)

    return ZeD.Molecules.figureZoneH(L, rightH)   -- the frame and the text, beside or stacked (Figure frame, the director, Nov 22 2026)
end

-- ============================================================================
-- UNDER THE INJURIES: Moodles, Fitness, Regularity, Muscle Strain (ZeD_TabFill)
-- The facts the game keeps that vanilla spreads over its moodles, its fitness
-- window and its health panel, read twice a second into win._healthFill and
-- drawn as fold blocks under the injury list (or under the figure with none).
-- ============================================================================

-- the moodles that are on, in vanilla's order: the game's own name, line and level
local function fillMoodles(p, out)
    local Mo = ZeD.Moodles
    if not (Mo and Mo.active) then return end
    local md = p:getMoodles()
    for _, m in ipairs(Mo.active(p)) do
        local okN, name = pcall(md.getMoodleDisplayString, md, m.type)
        local okD, desc = pcall(md.getMoodleDescriptionString, md, m.type)
        out[#out + 1] = { name = okN and name or m.key, desc = okD and desc or nil, level = m.level or 1, gbn = m.gbn or 0 }
    end
end

-- the parts with muscle strain vanilla's health panel shows (5 and up; under 20 is minor)
local function fillStrain(p, out)
    local bd = p:getBodyDamage()
    local parts = bd and bd:getBodyParts()
    if not parts then return end
    for i = 0, parts:size() - 1 do
        local bp = parts:get(i)
        local ok, s = pcall(bp.getStiffness, bp)
        if ok and type(s) == "number" and s >= 5 then
            out[#out + 1] = { name = getPartName(bp), minor = s < 20 }
        end
    end
end

--- What the blocks under the injuries show, read from the game (the tab reads it on a throttle).
function ZeD.HealthTab.gatherFill(p)
    local d = { moodles = {}, strain = {}, exercises = {} }
    if not p then return d end
    pcall(fillMoodles, p, d.moodles)
    pcall(fillStrain, p, d.strain)
    local okF, fit = pcall(p.getPerkLevel, p, Perks.Fitness)
    local okS, str = pcall(p.getPerkLevel, p, Perks.Strength)
    d.fitness = okF and fit or nil
    d.strength = okS and str or nil
    for _, id in ipairs(EXERCISES) do
        local exeData = FitnessExercises and FitnessExercises.exercisesType and FitnessExercises.exercisesType[id]
        if exeData then
            -- "(Requires Barbell)" only while the item is missing, as vanilla's fitness window
            -- and the info block above say it (the row is dimmed with it)
            local have = isExerciseAvailable(p, id)
            local need = nil
            if exeData.item and not have then
                local itemName = getItemDisplayName and getItemDisplayName(exeData.item) or exeData.item
                need = getText("IGUI_FitnessNeedItem", itemName)
            end
            d.exercises[#d.exercises + 1] = { id = id, name = ZeD.HealthTab.exerciseLabel(id), need = need,
                have = have, reg = readRegularity(p, id) or 0 }
        end
    end
    return d
end

-- the rows of the four blocks, built once per read (kept on the data: the words do not change between reads)
local function fillRows(win, d)
    if d.rows then return d.rows end
    local T = ZeD.T
    local rows = { moodles = {}, fitness = {}, regularity = {}, strain = {} }
    for i, m in ipairs(d.moodles) do
        local c = (m.gbn == 1) and T.positive or ((m.gbn == 2) and T.danger or T.textDim)
        rows.moodles[i] = { id = "fill:health:moodle:" .. i, dot = c, label = m.name, sub = m.desc,
                            bar = m.level / 4, barN = 4, barColor = c, read = true }
    end
    local lvl = ZeD.tr("UI_ZeD_Skills_CardMax", d.fitness or 0)
    rows.fitness[1] = { id = "fill:health:fit", label = getText("IGUI_perks_Fitness"), value = lvl, bar = (d.fitness or 0) / 10 }
    lvl = ZeD.tr("UI_ZeD_Skills_CardMax", d.strength or 0)
    rows.fitness[2] = { id = "fill:health:str", label = getText("IGUI_perks_Strength"), value = lvl, bar = (d.strength or 0) / 10 }
    for i, e in ipairs(d.exercises) do
        local eid = e.id
        rows.regularity[i] = { id = "fill:health:exe:" .. eid, exeId = eid, label = e.name, sub = e.need, dim = not e.have,
                               value = math.floor(e.reg * 100 + 0.5) .. "%", bar = e.reg, barColor = T.positive,
                               fn = function() ZeD.HealthTab.closeMenu(win, eid); win._healthReturnToMenu = nil end }
    end
    for i, s in ipairs(d.strain) do
        rows.strain[i] = { id = "fill:health:strain:" .. i, dot = T.warningText or T.warning, label = ZeD.partLabel(s.name),
                           value = getText(s.minor and "IGUI_health_MinorStiffness" or "IGUI_health_Stiffness") }
    end
    d.rows = rows
    return rows
end

--- The four blocks from (x, y), w wide; panel nil only measures. Returns their height.
function ZeD.HealthTab.renderFill(panel, win, x, y, w)
    local d = win._healthFill
    if not d then return 0 end
    local F = ZeD.TabFill
    local rows = fillRows(win, d)
    -- the picked exercise carries the selection (the band's pop-up picks the same)
    local sel = ZeD.HealthTab.selectedExercise(win)
    for _, r in ipairs(rows.regularity) do r.sel = (r.exeId == sel) end
    local o = ZeD.HealthTab._fillOpts
    o.view = win._healthView
    local h = 0
    h = h + F.block(panel, win, "health", "moodles", x, y + h, w, ZeD.tr("UI_ZeD_Health_Moodles"), #rows.moodles, rows.moodles, o)
    h = h + F.block(panel, win, "health", "fitness", x, y + h, w, getText("IGUI_perks_Fitness"), nil, rows.fitness, o)
    h = h + F.block(panel, win, "health", "regularity", x, y + h, w, getText("IGUI_FitnessRegularity"), #rows.regularity, rows.regularity, o)
    h = h + F.block(panel, win, "health", "strain", x, y + h, w, getText("IGUI_health_Stiffness"), #rows.strain, rows.strain, o)
    return h
end
ZeD.HealthTab._fillOpts = {}

-- ============================================================================
-- RENDERER (main entry point)
-- ============================================================================

function ZeD.HealthTab.render(panel, win, x, y, w, h)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules
    local pad  = M.getTabPad()

    -- (the exercise list never shuts itself when a draw comes late, as a hitch or a
    -- screenshot can make one; the window shuts it through closeMenu when the tab is
    -- left, the drawer folds or an item card opens over it)

    -- Throttled data refresh (every 250 ms on the clock: 15 frames at 60 FPS)
    if dueMs(win, "_healthAt", 250, not win._healthCache) then
        win._healthCache = ZeD.HealthTab.gatherData(win._playerObj)
    end
    local data = win._healthCache
    -- the footer band: the treatment's while a part can be treated, else the exercise's; an open list of the other
    -- kind is shut when it changes (the last wound healed, or a new one) (the director, Nov 23 2026)
    local wasMode = win._healthFooterMode
    if ZeD.HealthTab.footerMode(win) ~= wasMode and wasMode and win._healthMenuOpen then ZeD.HealthTab.closeMenu(win) end
    if dueMs(win, "_healthFillAt", 500, not win._healthFill) then
        win._healthFill = ZeD.HealthTab.gatherFill(win._playerObj)
    end
    ZeD.TabFill.begin(win, "health")

    -- Font metrics
    local bodyH  = ZeD.TM:getFontHeight(T.fontF2)

    -- For the controller: stash the content panel so _onPartClicked
    -- (called from injury-row / body-part onActivate) can anchor the vanilla
    -- treatment context menu even though callers don't pass drawerPanel.
    -- Capture LAST frame's injury Y-map before clearing so scroll-follow can
    -- read it; this frame's map is rebuilt during the injury loop below.
    win._healthContentPanel = panel
    openPendingPress(win, panel)   -- (KISS #29)
    local lastInjuryYMap = win._healthInjuryYMap or {}
    win._healthInjuryZones = {}
    win._healthInjuryYMap  = {}

    -- ================================================================
    -- WHOLE-TAB SCROLL SETUP
    -- ================================================================
    local scroll  = win._healthScroll
    local scrollW = T.sp.scrollbarW

    -- Pinned header: the disclosure strip (37 design units)
    local headerH = M.getTabHeaderH()
    local padTop  = M.getTabPadTop()
    local figureExpanded = win._healthFigureExpanded

    -- Resolve the "active" body part: the controller's focus on a body-part
    -- element overrides mouse hover, so the D-pad through the parts live-swaps
    -- the right column's detail view (as the Thermal tab does). Stashed on win
    -- so both the detail-view branch and _drawBodyFigure read the same value.
    -- (the live element: the controller's focus leads only while the controller is
    -- in use, so the mouse's hover leads again once the mouse moves)
    local activePart = win._healthHoveredPart
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local el = Focus and Focus.liveElement and Focus.liveElement(win)
        if el and el.partName then activePart = el.partName end
    end
    win._healthActivePart = activePart

    -- Stamp the disclosure hit-zone EARLY so the first prerender after a tab
    -- switch sees valid bounds and the disclosure focusable builds into
    -- element[1]. A late stamp lags a frame (the SkillsTab trap too): element
    -- 1 would point at another stop instead of the disclosure on entry, so the
    -- figure could not be folded at once.
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
        local tagIndent = ZeD.HealthTab.injuryRowLayout(bodyH, 0).indent
        for _, entry in ipairs(data.entries) do
            -- (the list's own width, less the tags' indent under the name)
            local tagsH = ZeD.HealthTab._measureBadgeRows(entry.conditions, w - scrollW - pad * 2 - tagIndent, tagHang())
            zoneBH = zoneBH + ZeD.HealthTab.injuryRowLayout(bodyH, tagsH).h
        end
    end
    -- the fill blocks under the list (measured with no panel: the same code that draws them)
    zoneBH = zoneBH + T.px(8) + ZeD.HealthTab.renderFill(nil, win, 0, 0, w - scrollW - pad * 2)

    -- The scroll range covers what the last frame really drew too, so the
    -- bottom of the tab is always reachable (the right column's detail view
    -- and wrapped badge rows can run past the measure)
    local totalContentH = math.max(padTop + zoneABodyH + zoneBH, win._healthDrawnH or 0)
    local scrollY = y + headerH
    -- the footer band is pinned at the card's foot: the body scrolls between it and the header
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

    -- Controller scroll-follow for every stop in the body (body parts, injury
    -- rows, the header's disclosure), keyed on the element's id. Reads last
    -- frame's stamped entry-start Y and adjusts scroll.scrollPos BEFORE
    -- scrollOff is computed: one frame of lag, the EquipmentTab pattern.
    -- DELTA GATE: the scroll is pinned only when the focused stop CHANGED.
    -- Gating on the mode (getMode() == "gamepad") is unreliable: the detector
    -- can swing kbm↔gamepad between consecutive frames, so a mouse-wheel scroll
    -- past the focused row would snap back on any frame that briefly read
    -- "gamepad". The delta gate fires exactly once per focus change, whatever
    -- the mode. The lowest stop scrolls as far down as it can while staying in
    -- view, so the text under it (the last injury) can be read on the pad; the
    -- header's disclosure scrolls back to the top. The band's stops are pinned
    -- (bandStop): they never scroll the body and are not counted as "below" a
    -- body stop.
    if needsScroll then
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local el = Focus and Focus.getFocusedWindow and Focus.getFocusedElement
                   and Focus.getFocusedWindow(win.playerNum) == win   -- (the window's own player's focus)
                   and Focus.getFocusedElement(win) or nil
        local focKey = el and (el.injuryKey or el.partName or el.isDisclosure or el.fillStop) and el.id or nil
        if focKey and focKey ~= win._lastPinnedInjuryKey then
            local span    = math.max(1, totalContentH - scrollH)
            local oldOff  = math.floor(scroll.scrollPos * span)
            -- (the stops are clipped to the view, fullY / fullH keep the whole rect; the
            -- lowest stop SHOWN scrolls the body on so the ones under it come into view,
            -- and Up onto the highest one shown scrolls back the same way: ZeD_TabFill's
            -- followStop, the rule the Thermal tab's body follows too)
            local elY, elH = el.fullY or el.y, el.fullH or el.h
            if el.injuryKey and lastInjuryYMap[el.injuryKey] then elY = lastInjuryYMap[el.injuryKey] end
            local target = oldOff
            if el.isDisclosure then
                target = 0
            elseif type(elY) == "number" and type(elH) == "number" then
                target = ZeD.TabFill.followStop(win, el, elY - scrollY + oldOff, elH, scrollH, oldOff, span)
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
    -- (_healthFigureZone is stamped at the TOP of render, not here)

    if figureExpanded then
        local layout = M.layoutZoneA(x, curY, contentW)

        -- the figure in its frame at the layout's whole zoom; the hover, the clicks and the pad stops read where it
        -- drew (drawAt keeps it: hitTestAt, getPartRects) (Figure frame, the director, Nov 22 2026)
        M.drawFigureFrame(panel, layout)
        ZeD.HealthTab._drawBodyFigure(panel, win, data,
            layout.figX, layout.figY, layout.figW, layout.figH, layout)

        -- The detail view reads _healthActivePart (the controller's focus
        -- overrides mouse hover).
        local activePart = win._healthActivePart
        local rightBottom
        if activePart and data.partHealth[activePart] then
            rightBottom = ZeD.HealthTab._renderDetailView(panel, win, data, activePart,
                layout.rightX, layout.rightY, layout.rightW)
        else
            rightBottom = ZeD.HealthTab._renderHeader(panel, win, data,
                layout.rightX, layout.rightY, layout.rightW)
        end

        -- (a right column taller than the measure pushes the injury list
        -- down instead of running under it)
        -- (and never above the frame's foot) (Figure frame, the director, Nov 22 2026)
        curY = math.max(curY + zoneABodyH, (rightBottom or 0) + padTop + pad, layout.frameY + layout.frameH + padTop + pad)
    end

    -- ================================================================
    -- ZONE B: Injury List (full width, scrollable)
    -- ================================================================

    if data.injuredCount > 0 then
        -- Zone divider (full width, no padding)
        A.drawDividerH(panel, x, curY, w, true)
        curY = curY + T.px(1) + T.sp.afterLine
        -- (padded both sides: the list began a pad in from the left but took the whole content width, so its right
        -- edge ran a pad past the stencil and the percent lost its "%": QA's Mac run on test 4 and 6, Nov 11 2026,
        -- punch list 148)
        local listX = x + pad
        local listW = contentW - pad * 2
        local st = T.stripe
        local sq = T.px(6)
        local tagsOpts = nil
        local tagIndent = ZeD.HealthTab.injuryRowLayout(bodyH, 0).indent
        for ei, entry in ipairs(data.entries) do
            local entryStartY = curY
            local tagsH = condTags(nil, entry.conditions, 0, 0, listW - tagIndent, tagHang())
            local row = ZeD.HealthTab.injuryRowLayout(bodyH, tagsH)
            local entryH = row.h

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
            local nameY = curY + row.nameY
            if mark then A.drawStatusDot(panel, listX + T.px(2), nameY + math.floor((bodyH - sq) / 2), mark, sq) end
            A.drawBody(panel, ZeD.partLabel(entry.name), listX + tagIndent, nameY, ink)
            local hpStr = math.floor(entry.health + 0.5) .. "%"
            A.drawTextRight(panel, hpStr, listX + listW - T.px(4), nameY, T.fontF2, ink)

            if tagsH > 0 then
                condTags(panel, entry.conditions, listX + tagIndent, curY + row.tagsY, listW - tagIndent, tagHang())
            end

            curY = curY + entryH - T.px(1)
            A.drawDividerH(panel, listX, curY, listW)
            curY = curY + T.px(1)

            -- Stamp zone + Y map (read next frame by _buildHealthInjuryFocusables
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
    -- the fill blocks: Moodles, Fitness, Regularity, Muscle Strain
    curY = curY + T.px(8)
    curY = curY + ZeD.HealthTab.renderFill(panel, win, x + pad, curY, contentW - pad * 2)
    -- what this frame drew, top to bottom (next frame's scroll range covers it)
    win._healthDrawnH = curY - (scrollY - scrollOff)

    panel:clearStencilRect()

    -- Pinned header, drawn on top of the scroll content: the hover wash and the
    -- controller's mark on the disclosure come with the molecule
    local hdrHover = A.mouseIn(panel, x, y, w, headerH)
    if hdrHover and ZeD.Help then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Health_HelpHeader")) end
    -- (QA's visual noise audit 3 and 38, Nov 20 2026: the header said "Health" under the title bar's "+ Health"; it
    -- folds the body figure, its only job, so it names that. The band stays: it is the figure's one fold.)
    M.drawTabHeader(panel, x, y, w, ZeD.tr("UI_ZeD_Tab_BodyFigure"), figureExpanded, hdrHover, nil,
        { focus = focusOf(win, "health:__disclosure") })

    if needsScroll then
        scroll:draw(panel)
    end

    -- The footer band, pinned at the card's foot; the exercise list (when open) over everything
    win._healthBandY = bandY   -- (a right-click there is not on an injury row scrolled under the band)
    ZeD.HealthTab._renderBand(panel, win, x, bandY, w)
    ZeD.HealthTab._renderMenu(panel, win)
end

-- ============================================================================
-- BADGE ROW HEIGHT MEASUREMENT
-- ============================================================================

function ZeD.HealthTab._measureBadgeRows(conditions, maxW, hang)
    return condTags(nil, conditions, 0, 0, maxW, hang)
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

--- Put the tab's renderer in a window's tab dispatch table (the Character
--- window's, under "health").
function ZeD.HealthTab.register(dispatchTable)
    dispatchTable["health"] = ZeD.HealthTab.render
end
