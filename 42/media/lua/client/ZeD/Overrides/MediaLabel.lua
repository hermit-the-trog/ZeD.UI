-- ZeD-UI/42/media/lua/client/ZeD/Overrides/MediaLabel.lua
-- ============================================================================
-- HOOK_MAP row 13: a CD's or a video tape's label (vanilla windows B8).
-- The game's Read label (ISInventoryPaneContextMenu.onMediaText, and the item
-- menu's media element, InvContextMedia.openMediaInfo) opens ISMediaInfo with
-- the label's words through ISMediaInfo.openPanel. ZeD's reader shows the
-- label there instead (ZeD_Reader.openLabel: the words view, the recording's
-- name at its head). The game's window opens only if the reader cannot, and
-- always while safe mode is on. The game's own rules for the option (too dark
-- to read, illiterate) stay with its menu, which ZeD's context menu draws.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ZeD_Reader"

local function apply()
    if not (ISMediaInfo and ISMediaInfo.openPanel) or ISMediaInfo._zedLabel then return end
    local vanilla = ISMediaInfo.openPanel
    ISMediaInfo._zedLabel = vanilla
    ISMediaInfo.openPanel = function(playerNum, text, ...)
        if ZeD.Safe.on() then return vanilla(playerNum, text, ...) end   -- safe mode: the game's window
        local ok, opened = pcall(function()
            local p = getSpecificPlayer(playerNum or 0)
            return ZeD.Reader.openLabel(p, text)
        end)
        if ok and opened then return ZeD.Reader.get(playerNum or 0) end
        if not ok then print("[ZeD] MediaLabel: the label kept the game's window: " .. tostring(opened)) end
        return vanilla(playerNum, text, ...)
    end
    print("[ZeD] Overrides/MediaLabel: Read label opens ZeD's reader")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
