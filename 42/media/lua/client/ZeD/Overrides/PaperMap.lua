-- ZeD-UI/42/media/lua/client/ZeD/Overrides/PaperMap.lua
-- ============================================================================
-- PAPER MAP HOOK (Nov 7 2026; vanilla windows list B2; HOOK_MAP "Paper map
-- items"). Read Map on a map item, from the right-click menu or a double-click
-- (ISInventoryPane:doContextualDblClick) in any inventory, ends in
-- ISInventoryPaneContextMenu.onCheckMap, which opens the game's ISMap window.
-- ZeD opens its own map on that paper instead (PaperMap.lua), after the game's
-- own first step: a map not in the main inventory is taken there by vanilla's
-- transfer, whose end calls Read Map again (and so this wrapper).
-- The game's window is reached in safe mode and whenever ZeD's can't open.
-- ============================================================================

require "ISUI/ISInventoryPaneContextMenu"
require "ZeD/SafeMode"
require "ZeD/PaperMap"

if not (ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onCheckMap) then return end

-- the original, kept once (a Lua reload of this file must not wrap the wrapper)
ISInventoryPaneContextMenu._zedOrigCheckMap = ISInventoryPaneContextMenu._zedOrigCheckMap or ISInventoryPaneContextMenu.onCheckMap
local _orig = ISInventoryPaneContextMenu._zedOrigCheckMap

ISInventoryPaneContextMenu.onCheckMap = function(map, player)
    if ZeD.Safe.on() then return _orig(map, player) end   -- safe mode: the game's map window
    local playerObj = getSpecificPlayer(player)
    -- not in the main inventory: vanilla's transfer first (it comes back here when done)
    if not (playerObj and map) or luautils.haveToBeTransfered(playerObj, map) then return _orig(map, player) end
    local ok, shown = pcall(ZeD.PaperMap.open, map, player)
    if ok and shown then return end
    if not ok then print("[ZeD] paper map: " .. tostring(shown)) end
    return _orig(map, player)
end

print("[ZeD] Overrides/PaperMap: Read Map opens ZeD's map on the paper")
