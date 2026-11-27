-- ZeD-UI/42/media/lua/client/ZeD/Overrides/PaperMap.lua
-- ============================================================================
-- PAPER MAP HOOK (override, client)
-- Read Map on a map item, from the right-click menu or a double-click
-- (ISInventoryPane:doContextualDblClick) in any inventory, ends in
-- ISInventoryPaneContextMenu.onCheckMap. The game's own Read Map runs whole:
-- a map not in the main inventory is taken there by its transfer, then its
-- read action (ISReadMapItem: 30 ticks, the read pose, the stash and the read
-- done in complete, on the server in multiplayer). Only the window at the
-- action's end is ZeD's: ISReadMapItem:showUI opens ZeD's map on that paper
-- (PaperMap.lua) in place of the game's ISMap window. (QA B1, Nov 27 2026: ZeD
-- used to open at once, with no action, and do the stash and the read itself.)
-- A game without ISReadMapItem keeps the older route: onCheckMap opens ZeD's
-- window after the transfer, and ZeD does the stash and the read.
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
    -- the game's read action is there: its Read Map, whole (the window at its end is ZeD's, below)
    -- (the move it queues is the player's own ask, not part of a run: ZeD's Put things back took the floor-to-him
    -- move as the read's and queued the map back to the floor, so the paper never showed; the read keeps the map on
    -- him, as the game does without Put back. Same as the Journal's notebook, J29. QA MP53, Nov 27 2026)
    if ISReadMapItem and ISReadMapItem.showUI then
        local PB = ZeD.PutBack
        local was = PB and PB.queuing
        if PB then PB.queuing = true end
        local ok, err = pcall(_orig, map, player)
        if PB then PB.queuing = was end
        if not ok then print("[ZeD] paper map: Read Map failed: " .. tostring(err)) end
        return
    end
    local playerObj = getSpecificPlayer(player)
    -- not in the main inventory: vanilla's transfer first (it comes back here when done)
    if not (playerObj and map) or luautils.haveToBeTransfered(playerObj, map) then return _orig(map, player) end
    local ok, shown = pcall(ZeD.PaperMap.open, map, player)
    if ok and shown then return end
    if not ok then print("[ZeD] paper map: " .. tostring(shown)) end
    return _orig(map, player)
end

-- The read action's end: ZeD's window on the paper. The action's complete has done the stash and the
-- read (and perform the client's read in multiplayer), so ZeD's open does neither (readDone).
if ISReadMapItem and ISReadMapItem.showUI then
    ISReadMapItem._zedOrigShowUI = ISReadMapItem._zedOrigShowUI or ISReadMapItem.showUI
    local _origShowUI = ISReadMapItem._zedOrigShowUI
    function ISReadMapItem:showUI()
        if ZeD.Safe.on() then return _origShowUI(self) end
        local ok, shown = pcall(ZeD.PaperMap.open, self.item, self.playerNum, true)
        if ok and shown then return end
        if not ok then print("[ZeD] paper map: " .. tostring(shown)) end
        return _origShowUI(self)
    end
end

print("[ZeD] Overrides/PaperMap: Read Map opens ZeD's map on the paper")
