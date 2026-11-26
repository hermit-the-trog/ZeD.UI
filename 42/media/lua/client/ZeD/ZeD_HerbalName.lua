-- ZeD-UI/42/media/lua/client/ZeD/ZeD_HerbalName.lua
-- ============================================================================
-- WHAT THE GAME LETS THE PLAYER KNOW ABOUT FOOD - client; no drawing.
--
-- ZeD.herbalName(item, playerObj)
--   The game's inventory list names berries and mushrooms as it draws them
--   (ISInventoryPane.lua:2107-2127): a player who knows Herbalist reads
--   "Poisonous Berry" or "Berry" (the same for mushrooms), anyone else
--   "Unknown Berry" or "Unknown Mushroom". It writes that name onto the item
--   with setName, so the item keeps it from then on, and other screens read
--   it too. ZeD's lists replace the game's, so they must do the same, or a
--   player sees plain "Berries" with or without Herbalist (QA K3, Nov 25 2026).
--   Returns the name to show, as vanilla's list reads it after the rename
--   (item:getName(playerObj), its line 2127). Cheap for anything else: one
--   IsFood call and the plain name.
--   Multiplayer: vanilla renames on the client as it draws; this does the same.
--
-- ZeD.seesNutrition(item, playerObj)
--   The game's food tooltip (Food.DoTooltip, Java) lists Calories, Carbs,
--   Proteins and Fat only for a player with the Nutritionist trait
--   (NUTRITIONIST or NUTRITIONIST2) or when the food is packaged and its label
--   can be read: not illiterate, not too dark to read, no "NoLabel" mod data.
--   Packaged but unreadable, it shows one Nutrition line saying why instead.
--   Returns: shown (bool), and when not shown on a packaged food, the game's
--   reason word (ContextMenu_Illiterate / ContextMenu_TooDark) or nil
--   (QA K17, Nov 25 2026).
--
-- Poison is not here on purpose: the game's food tooltip never shows poison
-- power as a stat (only a poison-show item says so through its own name), so
-- no ZeD card shows it either (QA K3, Nov 25 2026).
-- ============================================================================

ZeD = ZeD or {}

local function knowsHerbalist(playerObj)
    local ok, v = pcall(playerObj.isRecipeActuallyKnown, playerObj, "Herbalist")
    return ok and v == true
end

local function plainName(item, playerObj)
    if playerObj then return item:getName(playerObj) end
    return item:getName()
end

function ZeD.herbalName(item, playerObj)
    if not item then return nil end
    if not (item.IsFood and item:IsFood()) then return plainName(item, playerObj) end
    local ht = item.getHerbalistType and item:getHerbalistType()
    if not ht or ht == "" or not playerObj then return plainName(item, playerObj) end
    -- vanilla's own steps, in its order (ISInventoryPane.lua:2107-2127)
    local itemName = item:getName(playerObj)
    if knowsHerbalist(playerObj) then
        local poison = (item:getPoisonPower() or 0) > 0
        if ht == "Berry" then
            itemName = poison and getText("IGUI_PoisonousBerry") or getText("IGUI_Berry")
        end
        if ht == "Mushroom" then
            itemName = poison and getText("IGUI_PoisonousMushroom") or getText("IGUI_Mushroom")
        end
    else
        if ht == "Berry" then itemName = getText("IGUI_UnknownBerry") end
        if ht == "Mushroom" then itemName = getText("IGUI_UnknownMushroom") end
    end
    if itemName ~= item:getDisplayName() then item:setName(itemName) end
    return item:getName(playerObj)
end

local function hasTraitId(playerObj, id)
    if not (CharacterTrait and CharacterTrait[id]) then return false end
    local ok, v = pcall(playerObj.hasTrait, playerObj, CharacterTrait[id])
    return ok and v == true
end

function ZeD.seesNutrition(item, playerObj)
    if not item then return false end
    playerObj = playerObj or (getSpecificPlayer and getSpecificPlayer(0)) or nil
    if not playerObj then return false end
    if hasTraitId(playerObj, "NUTRITIONIST") or hasTraitId(playerObj, "NUTRITIONIST2") then return true end
    local okP, packaged = pcall(item.isPackaged, item)
    if not (okP and packaged) then return false end
    -- a packaged food: its label, if the player can read it (Food.DoTooltip's order: illiterate, then too dark)
    if hasTraitId(playerObj, "ILLITERATE") then return false, "ContextMenu_Illiterate" end
    local okD, dark = pcall(playerObj.tooDarkToRead, playerObj)
    if okD and dark then return false, "ContextMenu_TooDark" end
    local okM, md = pcall(item.getModData, item)
    if okM and md and md.NoLabel then return false end
    return true
end
