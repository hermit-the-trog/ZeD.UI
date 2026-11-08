-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/BetterItemTransfer.lua
-- ============================================================================
-- SUPPORT FOR BETTER ITEM TRANSFER (mod id BetterItemTransfer, Workshop
-- 3830103302). Client.
--
-- The mod rearranges the item right-click menu (where to take or move items,
-- exact amounts, its own icons) and its options are in Options > Mods. Its menu
-- shows in full in both of ZeD's menu styles; nothing here changes it.
--
-- What this file fixes: with the mod on, the first right-click after ZeD's
-- "Context menu" option was switched to the list came up as the icon strip.
-- The cause is not the menu. The mod reads its options through
-- BetterItemTransferOptions.get, which on its first call ever runs
-- PZAPI.ModOptions:load(): every mod's options are read back from
-- ModOptions.ini, ZeD's among them. That first call is the first right-click on
-- an item, so a ZeD option changed in game and not yet in the file (anything
-- that sets a value and saves later) went back to the file's value just before
-- ZeD's menu read its style.
--
-- ZeD's side: at game start, once the game has read the options itself, ZeD
-- writes the options as they stand (PZAPI.ModOptions:save, as ZeD's own settings
-- do after every change) and makes the mod's one-time read then. The mod reads
-- back exactly what is set, and from then on no right-click reloads anything,
-- so a style switch counts from the very next menu. The mod's options and
-- behavior are untouched.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "BetterItemTransfer"

-- Is the mod switched on? getActivatedMods() is a Java list of mod ids; a
-- workshop id can carry a leading backslash, which is cut off before comparing.
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

require "PZAPI/ModOptions"
pcall(require, "BetterItemTransferOptions")   -- (the mod's file; its global is read when used, whatever the load order)

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.BetterItemTransfer = S

S.primed = false

-- The mod's one-time options read, made now with the options as they stand written first. True when it ran.
function S.prime()
    local O = BetterItemTransferOptions
    if type(O) ~= "table" or type(O.get) ~= "function" then return false end
    if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.save then
        local ok, err = pcall(PZAPI.ModOptions.save, PZAPI.ModOptions)
        if not ok then
            -- (nothing written: the read would put back the file's values, so it waits for the mod's own first use)
            if ZeD.logOnce then ZeD.logOnce("BetterItemTransfer: the options could not be written first", err) end
            return false
        end
    end
    local ok, err = pcall(O.get, "showIcons")   -- (any of its options: the first get reads the file, once)
    if not ok then
        if ZeD.logOnce then ZeD.logOnce("BetterItemTransfer: the mod's options read failed", err) end
        return false
    end
    S.primed = true
    return true
end

Events.OnGameStart.Add(function() S.prime() end)

print("[ZeD] ModSupport: Better Item Transfer (its options read at game start, so the menu style holds)")
