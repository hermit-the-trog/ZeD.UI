-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/Clear_SkillSheet.lua
-- ============================================================================
-- SUPPORT FOR CLEAR SKILL SHEET (mod id Clear_SkillSheet, Workshop 3834856444).
-- Client.
--
-- What the mod does: it redraws the game's skills page (it replaces the
-- methods of ISCharacterInfo, the game's Skills view, at load time) as two
-- columns with a number for each level and a small bar (or, with its "Show
-- values" option, the XP of the level, current / required). Each skill's name
-- is colored by how fast it learns: the rate the game's XP rules give it
-- (profession and trait boost, Fast or Slow Learner, Pacifist on weapons,
-- Crafty on crafting), gray below x1, green from x1, blue from x1.33, orange
-- from x1.66; a skill book's multiplier ("x3") sits after the name. Its tooltip
-- gives the rate as "XP gain: x1.33". Its options (Options > Mods): Enable (on),
-- Show values, Abbreviated numbers.
--
-- ZeD's Skills tab replaces the game's page, so none of that shows with ZeD on.
-- ZeD's tab already has two columns, the level as a number (the badge), a bar
-- (ten segments) and the XP of the level in the help line and the row's card.
-- What it did not show is the rate and the book multiplier, so this file adds
-- them through the tab's general hook (ZeD.SkillsTab.addExtras):
--   * a row tag beside ZeD's boost tag (left of it — beside it, never in its
--     place): "XP x1.33" with the mod's color as the
--     tag's square (a status square, the words in default ink), and ", book x3"
--     while a skill book's multiplier runs. Rows learning below x1 with no
--     boost and no book get no tag. Fitness, Strength and Sprinting never learn
--     slower than x1, so they read "XP x1" even with no boost (the game's rule).
--   * the row's card (mouse over the row, or the controller's focus on it):
--     the mod's own line "XP gain: x1.33" and the game's skill book
--     multiplier line; the card's head already gives the level and its XP
--     (current of required, full numbers), which is what "Show values" shows.
-- Not carried over: the colored names (ZeD's names stay in default ink; the
-- color is the tag's square) and the abbreviated numbers (ZeD shows full ones).
-- The rate is worked out the way the game's XP rules do (the mod does the same,
-- in its own words); the numbers round to two decimals as the mod's tooltip.
-- The mod's Enable option is honored: off, this file adds nothing (ZeD's boost
-- tag stays, as it does with the option on). ZeD stores nothing.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "Clear_SkillSheet"

-- Is the mod on? An id from getActivatedMods() can carry a leading backslash.
local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/Tokens"
require "ZeD/Tr"
require "ZeD/SkillsTab"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.Clear_SkillSheet = S

-- the mod's colors for the rate (its name colors), as status squares
S.GRAY   = { r = 0.70, g = 0.70, b = 0.70, a = 1 }   -- below x1
S.GREEN  = { r = 0.12, g = 1.00, b = 0.00, a = 1 }   -- x1
S.BLUE   = { r = 0.25, g = 0.60, b = 1.00, a = 1 }   -- x1.33
S.ORANGE = { r = 1.00, g = 0.50, b = 0.00, a = 1 }   -- x1.66

-- The mod's Enable option (its ClearSkillSheet.isEnabled); on when it cannot be read.
function S.enabled()
    local api = ClearSkillSheet
    if type(api) == "table" and type(api.isEnabled) == "function" then
        local ok, on = pcall(api.isEnabled)
        if ok then return on ~= false end
    end
    return true
end

-- ---------------------------------------------------------------------------
-- THE RATE (the game's XP rules: XP.AddXP)
-- ---------------------------------------------------------------------------
local WEAPON = { "SmallBlade", "LongBlade", "SmallBlunt", "Spear", "Blunt", "Axe", "Aiming" }

local function isPerk(t, name) return Perks and Perks[name] ~= nil and t == Perks[name] end

local function hasTrait(char, name)
    if not (CharacterTrait and CharacterTrait[name]) then return false end
    local ok, has = pcall(function() return char:hasTrait(CharacterTrait[name]) end)
    return ok and has == true
end

-- How fast a skill learns, before books and sandbox: a number like 1.33.
-- boost 0: x0.25 (not Sprinting, Fitness, Strength); 1: x1 (Sprinting x1.25);
-- 2: x1.33, 3: x1.66 (not Fitness, Strength). Fast Learner x1.3, Slow Learner
-- x0.7 (the same skills left out), Pacifist x0.75 on weapons, Crafty x1.3 on the
-- crafting skills. Rounded to two decimals.
function S.gain(char, perk)
    local t = perk:getType()
    local boost = 0
    pcall(function() boost = char:getXp():getPerkBoost(t) or 0 end)
    local body = isPerk(t, "Fitness") or isPerk(t, "Strength")
    local keepsRate = body or isPerk(t, "Sprinting")       -- never slowed
    local m = 1
    if boost <= 0 then
        if not keepsRate then m = 0.25 end
    elseif boost == 1 then
        if isPerk(t, "Sprinting") then m = 1.25 end
    elseif not body then
        m = (boost == 2) and 1.33 or 1.66
    end
    if not body and hasTrait(char, "FAST_LEARNER") then m = m * 1.3 end
    if not keepsRate and hasTrait(char, "SLOW_LEARNER") then m = m * 0.7 end
    if hasTrait(char, "PACIFIST") then
        for _, w in ipairs(WEAPON) do
            if isPerk(t, w) then m = m * 0.75; break end
        end
    end
    if hasTrait(char, "CRAFTY") then
        local ok, parent = pcall(function() return perk:getParent() end)
        if ok and Perks and Perks.Crafting and parent == Perks.Crafting then m = m * 1.3 end
    end
    return math.floor(m * 100 + 0.5) / 100
end

-- The mod's color for a rate.
function S.color(m)
    local e = 0.0001
    if m + e >= 1.66 then return S.ORANGE end
    if m + e >= 1.33 then return S.BLUE end
    if m + e >= 1 then return S.GREEN end
    return S.GRAY
end

-- A skill book's multiplier running for the skill (0: none).
function S.book(char, perk)
    local v = 0
    pcall(function() v = char:getXp():getMultiplier(perk:getType()) or 0 end)
    return tonumber(v) or 0
end

-- "1.33", "1.5", "3": two decimals at most, trailing zeros dropped, the mod's
-- decimal separator for the language (its own key) when it has one.
function S.num(v, decimals)
    local s = string.format("%." .. tostring(decimals or 2) .. "f", v or 0)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    local sep = getTextOrNull and getTextOrNull("UI_ClearSkillSheet_DecimalSeparator") or nil
    if sep and sep ~= "" and sep ~= "." then
        local dot = s:find(".", 1, true)
        if dot then s = s:sub(1, dot - 1) .. sep .. s:sub(dot + 1) end
    end
    return s
end

-- ---------------------------------------------------------------------------
-- THE ROW EXTRA
-- ---------------------------------------------------------------------------
local X = {}

-- The row's tag (beside the boost tag): the rate in the mod's color, the book's multiplier after it.
function X.tag(char, perk, skill)
    if not (char and perk) or not S.enabled() then return nil end
    local g = S.gain(char, perk)
    local b = S.book(char, perk)
    if g < 1 and b <= 0 and not (skill and skill.boost and skill.boost > 0) then return nil end
    local text
    if b > 0 then
        text = ZeD.tr("UI_ZeD_CSS_TagBook", S.num(g, 2), S.num(b, 1))
    else
        text = ZeD.tr("UI_ZeD_CSS_Tag", S.num(g, 2))
    end
    return { text = text, color = S.color(g) }
end

-- The row's card: the rate in the mod's words, the book in the game's, the XP of the level.
function X.cardLines(char, perk, skill)
    if not (char and perk) or not S.enabled() then return nil end
    local lines = {}
    if not (skill and skill.level and skill.level >= 10) then
        lines[#lines + 1] = { text = getText("UI_ClearSkillSheet_XpGain", "x" .. S.num(S.gain(char, perk), 2)) }
    end
    local b = S.book(char, perk)
    if b > 0 then
        lines[#lines + 1] = { text = getText("IGUI_skills_Multiplier", S.num(b, 2)) }
    end
    return lines
end

S.X = X   -- (exposed so the QA scripts can reach the extras)
ZeD.SkillsTab.addExtras(MOD_ID, X)
