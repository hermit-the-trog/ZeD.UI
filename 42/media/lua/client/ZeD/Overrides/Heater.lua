-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Heater.lua
-- ============================================================================
-- HOOK_MAP row 4: the heater and air conditioning (the director, Nov 7 2026,
-- vanilla windows B6: "the key and the wheel slice go to the dash's own
-- climate controls").
--   * ISVehicleMenu.onToggleHeater (the Heater key, KeybindId.VEHICLE_HEATER in
--     ISVehicleMenu.onKeyPressed; the vehicle wheel's Heater On / Heater Off
--     slice, from the V wheel and ZeD's D-pad World wheel > Vehicle) turns the
--     heater on or off and shows ZeD's dash with its climate controls
--     (ZeD.Dashboard.heater) instead of the game's ISVehicleACUI.
-- The game's window opens as before when ZeD's dash is not the one showing:
-- its ZeD screens switch (Dashboard: the game's own), safe mode, or a dash
-- that cannot take it. The wrapper asks at call time, so nothing is parked.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ZeD_Dashboard"

local function apply()
    if not (ISVehicleMenu and ISVehicleMenu.onToggleHeater) or ISVehicleMenu._zedHeater then return end
    local vanilla = ISVehicleMenu.onToggleHeater
    ISVehicleMenu._zedHeater = vanilla
    ISVehicleMenu.onToggleHeater = function(playerObj, ...)
        if ZeD.Safe.on("dashboard") then return vanilla(playerObj, ...) end   -- the game's dash and its window
        local ok, handled = pcall(function() return ZeD.Dashboard.heater(playerObj) end)
        if ok and handled then return end
        if not ok then print("[ZeD] Heater: the heater kept the game's window: " .. tostring(handled)) end
        return vanilla(playerObj, ...)
    end
    print("[ZeD] Overrides/Heater: the heater key and slice go to the dash's climate controls")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
