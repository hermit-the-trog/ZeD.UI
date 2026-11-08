-- ZeD-UI/42/media/lua/client/ZeD/Overrides/MiniMap.lua
-- ============================================================================
-- THE GAME'S MINI-MAP (override, client). There is no mini-map in ZeD: the
-- World window's map is the map, and a save that left the game's mini-map
-- showing gets it hidden. ZeD's wheels no longer offer it
-- (ZeD_DpadWheels, ZeD.Wheel.isMiniMapCommand); here, a mini-map the game
-- shows (MiniMap.StartVisible kept from an older game, a mod's toggle) is
-- hidden, checked before the frames draw (the first frame too, so it never
-- flashes up at load), twice a second after that. Hidden, not removed: safe
-- mode, or ZeD screens > Wheels given back to the game, shows the ones it hid
-- again. The game's setting is left as it is.
-- ============================================================================

require "ZeD/SafeMode"

ZeD = ZeD or {}
ZeD.MiniMapOff = ZeD.MiniMapOff or {}
local MO = ZeD.MiniMapOff
MO._hidden = MO._hidden or {}   -- playerNum -> the mini-map this hid
local EVERY_MS = 500
local nextAt = 0

-- each player's mini-map hidden (true when one was hidden now); ZeD stepping aside shows the ones it hid
function MO.hide()
    if not getPlayerMiniMap then return false end
    if ZeD.Safe.on("wheels") then MO.restore(); return false end
    local took = false
    for pn = 0, 3 do
        local mm = getPlayerMiniMap(pn)
        if mm and mm:isReallyVisible() then
            pcall(function() mm:setVisible(false) end)
            MO._hidden[pn] = mm
            took = true
        end
    end
    return took
end

function MO.restore()
    for pn, mm in pairs(MO._hidden) do
        if getPlayerMiniMap and getPlayerMiniMap(pn) == mm then pcall(function() mm:setVisible(true) end) end
        MO._hidden[pn] = nil
    end
end

local function tick()
    local t = getTimestampMs()
    if t < nextAt then return end
    nextAt = t + EVERY_MS
    pcall(MO.hide)
end

if Events and not MO._hooked then
    MO._hooked = true
    if Events.OnPreUIDraw then Events.OnPreUIDraw.Add(tick) elseif Events.OnRenderTick then Events.OnRenderTick.Add(tick) end
    if Events.OnGameStart then Events.OnGameStart.Add(function() MO._hidden = {}; nextAt = 0; pcall(MO.hide) end) end
end
if ZeD.Safe.register then
    ZeD.Safe.register("mini-map", { leave = function() MO.restore() end, enter = function() pcall(MO.hide) end })
end
