-- ZeD-UI/42/media/lua/client/ZeD/Overrides/MiniMap.lua
-- ============================================================================
-- THE GAME'S MINI-MAP (vanilla windows B7; the director, Nov 7 2026: no
-- mini-map in ZeD, "the World window's map is the map"; a save that left the
-- game's mini-map showing: hide it). ZeD's wheels no longer offer it
-- (ZeD_DpadWheels, ZeD.Wheel.isMiniMapCommand); here, a mini-map the game
-- shows (MiniMap.StartVisible kept from an older game, a mod's toggle) is taken
-- off the screen, checked twice a second. The game's setting is left as it
-- is, so safe mode, which keeps the game's own wheels, shows it again.
-- ============================================================================

require "ZeD/SafeMode"

ZeD = ZeD or {}
ZeD.MiniMapOff = ZeD.MiniMapOff or {}
local MO = ZeD.MiniMapOff
local EVERY_MS = 500
local nextAt = 0

-- each player's mini-map off the screen (true when one was taken off)
function MO.hide()
    if ZeD.Safe.on("wheels") or not getPlayerMiniMap then return false end
    local took = false
    for pn = 0, 3 do
        local mm = getPlayerMiniMap(pn)
        if mm and mm:isReallyVisible() then
            pcall(function() mm:removeFromUIManager() end)
            took = true
        end
    end
    return took
end

local function tick()
    local t = getTimestampMs()
    if t < nextAt then return end
    nextAt = t + EVERY_MS
    pcall(MO.hide)
end

if Events and Events.OnRenderTick and not MO._hooked then
    MO._hooked = true
    Events.OnRenderTick.Add(tick)
end
