-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/WoundExpansion.lua
-- ============================================================================
-- SUPPORT FOR WOUND EXPANSION (mod id WoundExpansion, Workshop 3819438691; the
-- base mod only, not its ZombieBuddy add-on). Written Oct 29 2026 from the mod's
-- own code; Compatibility round 3 found its wound details missing from ZeD's
-- Health tab.
--
-- What the mod does: it keeps its own record of nine wound kinds (abrasion,
-- puncture, avulsion, frostbite, sprain, dislocation, concussion, joint damage,
-- nerve damage) and about fourteen conditions on top of them (swollen, inflamed,
-- necrotic, maggots, bruised, numb, torn bandage and so on) per body part, in the
-- character's modData ("WoundExp"). The game's health panel is where the player
-- reads them: the mod's "WE_HealthPanel.lua" draws one coloured line under each
-- body part ("- Sprain", "- Bruised", ...) and, through
-- WoundExpansion.buildHealthPanelLines, builds those lines in one place: its own
-- words (the game's translation files), its own colours, what a doctor of the
-- viewer's First Aid level may see, bandage and splint rules, and the "beyond
-- saving" note for a limb that cannot be saved.
--
-- ZeD's Health tab replaces the game's panel, so those lines never showed. This
-- file hands the tab that same list for the part in its detail view, through the
-- tab's general hook (ZeD.HealthTab.addExtras): a status square in the mod's colour
-- and the mod's own words beside it. The injury list carries them as tags too, and
-- a part that has only a Wound Expansion wound is listed (as the mod does on the
-- game's panel). ZeD stores nothing: the lines are asked of the mod every time the
-- tab re-reads the body, inside pcall so a change in the mod cannot break the tab.
--
-- Treatments: the mod adds its entries (reset a joint, remove debris or maggots,
-- splint a sprain, cast, poultices, bandage...) by wrapping the game's
-- ISHealthPanel.doBodyPartContextMenu. ZeD opens that same menu for a part
-- (HealthTab._onPartClicked) through a small stand-in for the panel; the stand-in
-- gained getPatient() so the mod's wrapper can run. Nothing else is needed here.
--
-- The mod also paints swollen / bruised / necrotic overlays on the game's body
-- figure; ZeD's figure is its own, so those stay in the words.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "WoundExpansion"

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
require "ZeD/HealthTab"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.WoundExpansion = S

-- The mod's main table (a global it makes as its shared files load), or nil while it
-- is not there yet, failed to load, or lacks the function we use. Asked every time:
-- the global may not exist yet when this file loads, and nothing is kept.
local function WE()
    local m = WoundExpansion                    -- (an unset global reads as nil, not an error)
    if type(m) == "table" and type(m.buildHealthPanelLines) == "function"
        and type(m.Config) == "table" and type(m.covered) == "function" then
        return m
    end
    return nil
end

-- The square's ZeD severity for one of the mod's line colours. The mod gives no
-- severity of its own, only a colour (its PALETTE in WE_HealthPanel.lua): green is a
-- treatment in place, a deep red or pink is its "severe" and "alarm" colours, any other
-- is an ordinary wound or condition. The tag in the injury list follows this.
local function severityOf(c)
    if type(c) ~= "table" then return "warning" end
    local r, g = c.r or 0, c.g or 0
    if g >= 0.8 and r <= 0.4 then return "positive" end   -- treatment (0.28, 0.89, 0.28)
    if g <= 0.2 and r >= 0.7 then return "danger" end     -- severe (0.80, 0.16, 0.20), alarm (1.0, 0.16, 0.62)
    return "warning"
end

-- Everything the mod would write under this body part on the game's health panel, as
-- ZeD's lines: { { text, color = {r,g,b}, severity }, ... }; nil when there is nothing
-- (or the mod is off in its options, or does not track this character).
-- The mod hands back its own cached list; this copies it so nothing of the mod's is held.
function S.partLines(playerObj, bodyPart)
    local mod = WE()
    if not (mod and playerObj and bodyPart) then return nil end
    if mod.Config.ENABLED ~= true then return nil end     -- the mod's own on/off option
    if not mod.covered(playerObj) then return nil end     -- the mod tracks the local player only
    -- (character, part index, part, who is looking): the patient is the viewer here, so
    -- the viewer's First Aid decides which hidden conditions show, as on the game's panel
    local lines = mod.buildHealthPanelLines(playerObj, bodyPart:getIndex(), bodyPart, playerObj)
    if type(lines) ~= "table" then return nil end
    local out = nil
    for _, ln in ipairs(lines) do
        -- (a line with no text is the mod's debug-only detail row; ZeD leaves it out)
        if type(ln) == "table" and type(ln.text) == "string" and ln.text ~= "" then
            local c = ln.colour or {}
            out = out or {}
            out[#out + 1] = {
                text     = ln.text,
                color    = { r = c.r or 1, g = c.g or 1, b = c.b or 1, a = 1 },
                severity = severityOf(c),
            }
        end
    end
    return out
end

ZeD.HealthTab.addExtras(MOD_ID, S)
