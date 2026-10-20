-- ZeD-UI/42/media/lua/client/ZeD/Overrides/PrintMedia.lua
-- ============================================================================
-- PRINT MEDIA HOOK (HOOK_MAP row 13) — when vanilla's Read action finishes on
-- a newspaper, flyer or brochure, ISReadABook:displayPrintMedia opens vanilla's
-- PZAPI PrintMedia window. ZeD opens its reader there instead (ZeD_Reader),
-- and keeps vanilla's own rule after it: with the game's "auto reveal print
-- media map locations" option on, the piece's places are marked on the map.
-- Vanilla's window is reached only if the reader cannot open, or while ZeD's
-- safe mode is on.
-- ============================================================================

require "TimedActions/ISReadABook"
require "ZeD/ZeD_Reader"
require "ZeD/SafeMode"

if not ISReadABook or not ISReadABook.displayPrintMedia then return end

local _orig = ISReadABook._zedOrigDisplayPrintMedia or ISReadABook.displayPrintMedia
ISReadABook._zedOrigDisplayPrintMedia = _orig

function ISReadABook:displayPrintMedia()
    if ZeD.Safe.on() then return _orig(self) end   -- safe mode: vanilla's window
    local opened = false
    if ZeD and ZeD.Reader and ZeD.Reader.openPrint then
        local ok, r = pcall(ZeD.Reader.openPrint, self.character, self.item)
        opened = ok and r
        if not ok then print("[ZeD] reader: " .. tostring(r)) end
    end
    if not opened then return _orig(self) end
    local val = self.item:getModData().printMedia
    if val and getCore():getOptionAutoRevealPrintMediaMapLocations() then
        self:revealPrintMediaLocationsOnMap(val.id)
    end
end
