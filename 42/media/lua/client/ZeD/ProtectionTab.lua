-- ZeD-UI/42/media/lua/client/ZeD/ProtectionTab.lua
-- ============================================================================
-- PROTECTION DATA MODULE (client) — gathers the worn clothing's defense
-- numbers and the grading helpers around them. No drawing here: the
-- EquipmentTab's defense dashboard section renders what gatherData returns.
-- Part keys are vanilla's BloodBodyPartType strings; three tables translate
-- them (medic-style display names, BodyFigure tile names, and abbreviations
-- for the danger pills).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/ZeD_BodyFigure"

ZeD = ZeD or {}
ZeD.ProtectionTab = {}

-- ============================================================================
-- BODY PART TABLES
-- ============================================================================

-- Full medic-style display names (BloodBodyPartType string keys)
local PART_NAMES = {
    Torso_Upper  = "Upper Torso",
    Torso_Lower  = "Lower Torso",
    Back         = "Back",
    UpperArm_L   = "Left Upper Arm",
    UpperArm_R   = "Right Upper Arm",
    ForeArm_L    = "Left Forearm",
    ForeArm_R    = "Right Forearm",
    Head         = "Head",
    Neck         = "Neck",
    Groin        = "Groin",
    UpperLeg_L   = "Left Thigh",
    UpperLeg_R   = "Right Thigh",
    LowerLeg_L   = "Left Shin",
    LowerLeg_R   = "Right Shin",
    Foot_L       = "Left Foot",
    Foot_R       = "Right Foot",
    Hand_L       = "Left Hand",
    Hand_R       = "Right Hand",
}

-- Canonical body part order (head-to-toe for tiebreaker)
local ALL_PARTS = {
    "Head", "Neck",
    "Torso_Upper", "Torso_Lower", "Back", "Groin",
    "UpperArm_L", "UpperArm_R", "ForeArm_L", "ForeArm_R", "Hand_L", "Hand_R",
    "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R",
}

ZeD.ProtectionTab.ALL_PARTS = ALL_PARTS

-- Maps PZ part keys → BodyFigure display names (SUFFIX_TO_DISPLAY values).
-- Resolves naming mismatch: "Left Thigh" in PART_NAMES vs "Left Upper Leg" in BodyFigure.
-- "Back" has no figure tile — setPartColor is a harmless no-op.
local PART_TO_FIGURE = {
    Head         = "Head",
    Neck         = "Neck",
    Torso_Upper  = "Upper Torso",
    Torso_Lower  = "Lower Torso",
    Back         = "Back",
    Groin        = "Groin",
    UpperArm_L   = "Left Upper Arm",
    UpperArm_R   = "Right Upper Arm",
    ForeArm_L    = "Left Forearm",
    ForeArm_R    = "Right Forearm",
    Hand_L       = "Left Hand",
    Hand_R       = "Right Hand",
    UpperLeg_L   = "Left Upper Leg",
    UpperLeg_R   = "Right Upper Leg",
    LowerLeg_L   = "Left Lower Leg",
    LowerLeg_R   = "Right Lower Leg",
    Foot_L       = "Left Foot",
    Foot_R       = "Right Foot",
}

ZeD.ProtectionTab.PART_TO_FIGURE = PART_TO_FIGURE

-- Reverse lookup: BodyFigure display name → PZ part key
local FIGURE_TO_PART = {}
for partStr, figName in pairs(PART_TO_FIGURE) do
    FIGURE_TO_PART[figName] = partStr
end
ZeD.ProtectionTab.FIGURE_TO_PART = FIGURE_TO_PART

-- Medic-style display names exposed for hover headings
ZeD.ProtectionTab.PART_NAMES = PART_NAMES

-- Abbreviated names for danger pills (tight flex-wrap)
local PART_ABBREV = {
    Head         = "HEAD",
    Neck         = "NECK",
    Torso_Upper  = "U. TORSO",
    Torso_Lower  = "L. TORSO",
    Back         = "BACK",
    Groin        = "GROIN",
    UpperArm_L   = "L. UARM",
    UpperArm_R   = "R. UARM",
    ForeArm_L    = "L. FOREARM",
    ForeArm_R    = "R. FOREARM",
    Hand_L       = "L. HAND",
    Hand_R       = "R. HAND",
    UpperLeg_L   = "L. THIGH",
    UpperLeg_R   = "R. THIGH",
    LowerLeg_L   = "L. SHIN",
    LowerLeg_R   = "R. SHIN",
    Foot_L       = "L. FOOT",
    Foot_R       = "R. FOOT",
}

-- ============================================================================
-- DEFENSE TIER COLOR + GRADE
-- ============================================================================

--- the colour for one part's bite defense (red under 5, up to green at 50+)
local function tierColor(biteDef)
    local T = ZeD.T
    if biteDef < 5  then return T.danger   end
    if biteDef < 20 then return T.warningText end
    if biteDef < 50 then return T.info     end
    return T.positive
end
ZeD.ProtectionTab.tierColor = tierColor

--- the letter grade for the average bite defense (A at 60+, F below 1)
local function gradeForAvg(avg)
    if avg >= 60 then return "A" end
    if avg >= 35 then return "B" end
    if avg >= 15 then return "C" end
    if avg >= 1  then return "D" end
    return "F"
end
ZeD.ProtectionTab.gradeForAvg = gradeForAvg

--- the colour a letter grade is drawn in
local function gradeColor(grade)
    local T = ZeD.T
    if grade == "A" then return T.positive end
    if grade == "B" then return T.info     end
    if grade == "C" then return T.warning  end
    return T.danger
end
ZeD.ProtectionTab.gradeColor = gradeColor

--- the colour for a part's best defense; below zero means uncovered
local function protectionColorForDef(def)
    local T = ZeD.T
    if def < 0  then return T.danger   end  -- uncovered
    if def < 5  then return T.danger   end  -- 0-4%
    if def < 20 then return T.warning  end  -- 5-19%
    if def < 50 then return T.info     end  -- 20-49%
    return T.positive                        -- 50%+
end
ZeD.ProtectionTab.protectionColorForDef = protectionColorForDef

-- ============================================================================
-- DATA GATHERING
-- ============================================================================

--- Everything the defense dashboard shows for one player, in one table:
--- each worn garment's per-part defenses (worst first), per-part totals
--- across layers (the game's rule, IsoGameCharacter.getBodyPartClothingDefense:
--- every worn layer over a part with no hole there adds its defense, the
--- total floored and at most 100), the overall average and grade, best and
--- worst parts, and the uncovered parts as abbreviated pill names.
--- Only worn garments count: a garment held in the hand is equipped, not worn.
function ZeD.ProtectionTab.gatherData(playerObj)
    local worn = playerObj:getWornItems()

    local garments  = {}
    local coveredSet = {}  -- partStr -> true

    for i = 0, (worn and worn:size() or 0) - 1 do
        local wi = worn:get(i)
        local item = wi and wi:getItem()
        if item and instanceof(item, "Clothing") then
            local parts = item:getCoveredParts()
            if parts and parts:size() > 0 then
                local zones   = {}
                local biteSum = 0
                local seen    = {}

                for j = 0, parts:size() - 1 do
                    local part    = parts:get(j)
                    local partStr = tostring(part)
                    local name    = PART_NAMES[partStr] or partStr:gsub("_", " ")

                    -- (a garment counts once per part, as in the game's loop)
                    if not seen[partStr] then
                        seen[partStr] = true
                        coveredSet[partStr] = true

                        local rawBite    = item:getDefForPart(part, true,  false) or 0
                        local rawScratch = item:getDefForPart(part, false, false) or 0
                        local rawBullet  = item:getDefForPart(part, false, true)  or 0
                        -- the game skips a layer with a hole over the part
                        local okH, hole = pcall(function() return item:getVisual():getHole(part) end)
                        local holed = okH and type(hole) == "number" and hole > 0

                        local biteDef = math.floor(rawBite)
                        biteSum = biteSum + biteDef

                        zones[#zones + 1] = {
                            name       = name,
                            partStr    = partStr,
                            biteDef    = biteDef,
                            scratchDef = math.floor(rawScratch),
                            bulletDef  = math.floor(rawBullet),
                            -- (what the layer adds to the part's total: nothing through a hole)
                            addBite    = holed and 0 or rawBite,
                            addScratch = holed and 0 or rawScratch,
                            addBullet  = holed and 0 or rawBullet,
                        }
                    end
                end

                garments[#garments + 1] = {
                    name       = item:getName() or "?",
                    tex        = item:getTex(),
                    avgBiteDef = #zones > 0 and math.floor(biteSum / #zones) or 0,
                    parts      = zones,
                }
            end
        end
    end

    -- Sort by avgBiteDef ascending (worst first), tiebreak by name
    table.sort(garments, function(a, b)
        if a.avgBiteDef ~= b.avgBiteDef then return a.avgBiteDef < b.avgBiteDef end
        return a.name < b.name
    end)

    -- Build per-part defense maps: the layers' bite/scratch/bullet defenses added (the game's rule: no layer through
    -- a hole, the total floored and at most 100); -1 for a part nothing covers
    local partDefense = {}
    local partStats   = {}
    for _, partStr in ipairs(ALL_PARTS) do
        partDefense[partStr] = -1
        partStats[partStr] = { bite = -1, scratch = -1, bullet = -1, layers = 0 }
    end
    local sums = {}
    for _, garment in ipairs(garments) do
        for _, zone in ipairs(garment.parts) do
            local s = sums[zone.partStr]
            if not s then s = { 0, 0, 0 }; sums[zone.partStr] = s end
            s[1], s[2], s[3] = s[1] + zone.addBite, s[2] + zone.addScratch, s[3] + zone.addBullet
            local ps = partStats[zone.partStr]
            if not ps then ps = { bite = -1, scratch = -1, bullet = -1, layers = 0 }; partStats[zone.partStr] = ps end
            ps.layers  = ps.layers + 1
        end
    end
    for partStr, s in pairs(sums) do
        local ps = partStats[partStr]
        ps.bite    = math.floor(math.min(100, s[1]))
        ps.scratch = math.floor(math.min(100, s[2]))
        ps.bullet  = math.floor(math.min(100, s[3]))
        partDefense[partStr] = ps.bite
    end

    -- Global average bite defense across all 18 parts
    local defSum = 0
    for _, partStr in ipairs(ALL_PARTS) do
        defSum = defSum + math.max(0, partDefense[partStr])
    end
    local avgBiteDef = math.floor(defSum / #ALL_PARTS)

    -- Best and worst parts (head-to-toe tiebreaker via ALL_PARTS order)
    local bestPart  = { name = "-", biteDef = -1 }
    local worstPart = { name = "-", biteDef = 999 }
    for _, partStr in ipairs(ALL_PARTS) do
        local def  = partDefense[partStr]
        local name = PART_NAMES[partStr] or partStr
        if def > bestPart.biteDef then
            bestPart = { name = name, biteDef = def }
        end
        if def < worstPart.biteDef then
            worstPart = { name = name, biteDef = def }
        end
    end

    -- Uncovered parts (abbreviated names)
    local uncoveredParts = {}
    for _, partStr in ipairs(ALL_PARTS) do
        if not coveredSet[partStr] then
            uncoveredParts[#uncoveredParts + 1] = ZeD.partAbbrev(PART_ABBREV[partStr] or partStr)
        end
    end

    local grade = gradeForAvg(avgBiteDef)

    return {
        garments       = garments,
        uncoveredParts = uncoveredParts,
        partDefense    = partDefense,
        partStats      = partStats,
        avgBiteDef     = avgBiteDef,
        grade          = grade,
        bestPart       = bestPart,
        worstPart      = worstPart,
        totalGarments  = #garments,
        totalParts     = #ALL_PARTS,
        isFemale       = playerObj:isFemale(),
    }
end

-- ============================================================================
-- ZONE A RIGHT COLUMN HEIGHT MEASUREMENT
-- Computes the vertical extent of the right-column content so Zone A
-- height can accommodate both the figure and the stats/pills.
-- ============================================================================

function ZeD.ProtectionTab._measureRightColumn(data)
    local T     = ZeD.T
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)
    local secH  = ZeD.TM:getFontHeight(T.fontF1)
    -- Stacked stat: label + labelValueGap + value + afterGap
    local stackedH = secH + T.sp.xs + bodyH + T.sp.sm

    local h = 0

    -- Grade box (2 label rows + padding)
    local boxH = secH * 2 + T.sp.xs + T.px(8)
    h = h + T.sp.sm + boxH + T.sp.sm

    -- Divider below grade
    h = h + T.px(1) + T.sp.afterLine

    -- Stacked stat rows (worst, best, garments)
    local numStats = 2  -- worst + garments always
    if data.bestPart.biteDef >= 0 then numStats = numStats + 1 end
    h = h + numStats * stackedH

    return h
end

