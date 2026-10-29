-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/ExpRecovery.lua
-- ============================================================================
-- SUPPORT FOR EXP RECOVERY FOR SKILL BOOKS (mod id ExpRecovery, Workshop
-- 2923554542). Written Oct 29 2026 from the mod's own code; Compatibility round 3
-- found its marks missing on ZeD's Skills tab.
--
-- What the mod does: a skill book trains faster (a multiplier on the XP you earn),
-- so XP earned before you read the book is "missed" -- the book would have given
-- more. The mod counts that missed XP per skill and per book stage (five stages;
-- stage 1 is the book for levels 1-2, stage 2 levels 3-4, and so on up to 9-10)
-- and keeps it in the character's modData under "ExpRecovery". Reading the book
-- of that stage pays the saved XP out. On the game's skill page it paints the
-- saved XP in blue on the level squares (its "exp_recovery_skill_progress_bar.lua":
-- the saved XP is laid on top of the skill's bar, starting where the skill stands
-- now, a square at a time), and adds "Saved XP: n" for the hovered level to the
-- bar's tooltip. It has no key line, so this file has no block at the top.
--
-- ZeD's Skills tab draws its own rows, so this file shows the same through the
-- tab's general hook (ZeD.SkillsTab.addExtras):
--   * a strip in its own lane under each row (the row grows by 10 units): the
--     standard framed bar, as long as the skill would reach with its saved XP
--     (levels, of ten), grey for how far the skill has come (the mod's grey) and
--     blue (the mod's blue) for the part the saved XP adds. No saved XP: no strip.
--     The length is worked out the way the mod lays its squares (the rest of the
--     current level first, then each higher level in turn).
--   * the numbers in the row's hover card: the saved XP per book stage, and the
--     total. The mod's own tooltip only shows one stage, the hovered one.
-- ZeD keeps no copy: every frame it reads what the mod keeps in modData (the same
-- place the mod's own bar reads, inside pcall so a change in the mod cannot break
-- the tab). Pinned skills in the title bar stay text.
--
-- Skill Recovery Journal draws a strip too. The hook draws one strip per row and
-- shows one card, so when that mod's support is also here this file steps aside
-- on the strip (the journal's wins) and adds its stage lines to the journal's card.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "ExpRecovery"

-- Is the mod switched on in this game? getActivatedMods() is a Java list of mod ids;
-- a leading backslash (a mod loaded by its folder id) is cut off before comparing.
local function modOn()
    local list = getActivatedMods and getActivatedMods()   -- "a and b": b only when a exists
    if not list then return false end
    for i = 0, list:size() - 1 do                           -- Java lists count from 0
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end   -- a file's top level can "return": the rest never runs

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/SkillsTab"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}                                  -- this file's public table
ZeD.ModSupport.ExpRecovery = S

-- the mod's own colours: grey is what its bar paints over the current square
-- (0.4, 0.4, 0.4), blue is its saved-XP colour (0.274, 0.51, 1; it draws it half
-- see-through, the strip draws solid so it is read on the dark well)
local GREY = { r = 0.4, g = 0.4, b = 0.4 }
local BLUE = { r = 0.274, g = 0.51, b = 1.0 }

local STAGES = 5   -- the mod keeps five numbers per skill, one per skill book stage

-- round to two decimals as the mod's tooltip does ("Saved XP: 12.35")
local function round2(n) return math.floor((n or 0) * 100 + 0.5) / 100 end

-- ---------------------------------------------------------------------------
-- THE MOD'S NUMBERS
-- ---------------------------------------------------------------------------

-- The five saved-XP numbers of a skill, and their sum: { d1..d5 }, total.
-- nil when the mod has nothing for the skill. The mod stores them at
-- character:getModData()["ExpRecovery"][perk id][stage] (its getExpData).
function S.saved(char, perk)
    if not (char and perk) then return nil end
    local out, total = nil, 0
    local ok = pcall(function()                   -- pcall: run it, and swallow any error
        local all = char:getModData()["ExpRecovery"]
        local d = all and all[perk:getId()]
        if not d then return end                  -- (this "return" leaves the inner function only)
        out = {}
        for i = 1, STAGES do
            local v = tonumber(d[i]) or 0          -- tonumber: a missing number reads as 0
            out[i] = v
            total = total + v
        end
    end)
    if not ok or not out or total <= 0 then return nil end
    return out, total
end

-- How far (in levels, 0 to 10) the skill would reach if the saved XP were paid
-- out, laid the way the mod lays its blue squares: first what is left of the
-- current level, then each higher level in turn. level is the whole level,
-- progress (0..1) how far into the next one. Returns the start (where the skill
-- stands now, in levels) and the end, or nil when there is nothing to show.
function S.reach(perk, level, progress, total)
    if not (perk and level and level < 10 and total and total > 0) then return nil end
    local cur = perk:getXpForLevel(level + 1)      -- XP the current level needs in all
    if not cur or cur <= 0 then return nil end
    local have = (progress or 0) * cur              -- XP already into the current level
    local startPos = level + (progress or 0)
    local gain = math.min(cur - have, total)       -- the part that fits in the current level
    local endPos = level + (have + gain) / cur
    local rest = total - gain                      -- XP still to place on higher levels
    for lv = level + 2, 10 do
        if rest <= 0 then break end                -- nothing left to place
        local need = perk:getXpForLevel(lv)        -- XP that level needs in all
        if not need or need <= 0 then break end
        endPos = (lv - 1) + math.min(1, rest / need)   -- the square is filled this far
        rest = rest - need
    end
    if endPos <= startPos then return nil end
    return startPos, endPos
end

-- ---------------------------------------------------------------------------
-- THE ROW EXTRA
-- ---------------------------------------------------------------------------
local X = { laneH = 10 }   -- the row grows by 10 design units for the strip's lane

-- Does the Skill Recovery Journal's support also hold a strip? Then it keeps the lane.
local function journalHasLane()
    for _, e in ipairs(ZeD.SkillsTab.extras) do   -- ipairs walks a list in order
        if e.id == "SkillRecoveryJournal" then return true end
    end
    return false
end

-- The strip: as long as the skill would reach with its saved XP, grey up to where it
-- stands and blue for the rest. The tab calls this for every row, every frame.
function X.lane(char, perk, level, progress)
    if journalHasLane() then return nil end
    local d, total = S.saved(char, perk)
    if not d then return nil end
    local a, b = S.reach(perk, level, progress, total)   -- a function may hand back two values
    if not a then return nil end
    local segs = {}
    if a > 0 then segs[#segs + 1] = { share = a / b, color = GREY } end        -- have
    segs[#segs + 1] = { share = (b - a) / b, color = BLUE }                   -- saved XP
    return { span = math.min(1, b / 10), segs = segs }                        -- of ten levels
end

-- the mod's name as the game lists it, for the card's heading
local function modName()
    local name = nil
    pcall(function() name = getModInfoByID(MOD_ID):getName() end)
    return name or "Exp Recovery"
end

-- the stage lines of the card: one per stage that holds XP
local function stageLines(d)
    local lines = {}
    for i = 1, STAGES do
        if d[i] > 0 then
            -- stage i is the book for levels 2i-1 to 2i
            lines[#lines + 1] = { color = BLUE, text = ZeD.tr("UI_ZeD_XR_Stage", 2 * i - 1, 2 * i), value = tostring(round2(d[i])) }
        end
    end
    return lines
end

-- The hover card: the saved XP per book stage, and in all.
function X.card(char, perk, skill)
    if not skill or skill.level >= 10 then return nil end
    local d, total = S.saved(char, perk)
    if not d then return nil end
    local lines = stageLines(d)
    -- with the journal's support also here, add to its card rather than replace it
    local srj = ZeD.ModSupport.SkillRecoveryJournal
    if srj and srj.X and srj.X.card then
        local ok, c = pcall(srj.X.card, char, perk, skill)
        if ok and c then
            for _, ln in ipairs(lines) do c.lines[#c.lines + 1] = ln end
            c.note = (c.note and (c.note .. " ") or "") .. ZeD.tr("UI_ZeD_XR_Note")
            return c
        end
    end
    lines[#lines + 1] = { total = true, text = ZeD.tr("UI_ZeD_XR_SavedXP"), value = tostring(round2(total)) }
    return { label = modName(), lines = lines, note = ZeD.tr("UI_ZeD_XR_Note") }
end

S.X = X   -- (the QA scripts drive it)
ZeD.SkillsTab.addExtras(MOD_ID, X)
