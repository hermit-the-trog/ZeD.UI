-- ZeD-UI/42/media/lua/client/ZeD/Overrides/CarRadio.lua
-- ============================================================================
-- HOOK_MAP row 4: the vehicle wheel's last vanilla window.
--   * ISVehicleMenu.onSignalDevice (the wheel's Device Options slice, front
--     seats only) brings the fitted radio up close (ZeD_CarRadio.lua) instead
--     of vanilla's ISRadioWindow.
-- Any other device part (a mod's), or a radio the ZeD prop cannot show, opens
-- vanilla's window as before.
-- ============================================================================

require "ZeD/ZeD_CarRadio"

local function apply()
    if ISVehicleMenu and ISVehicleMenu.onSignalDevice and not ISVehicleMenu._zedRadio then
        local vanilla = ISVehicleMenu.onSignalDevice
        ISVehicleMenu._zedRadio = vanilla
        ISVehicleMenu.onSignalDevice = function(playerObj, part)
            local isRadio = part and part.getId and part:getId() == "Radio"
            if not isRadio then return vanilla(playerObj, part) end
            local ok, err = pcall(ZeD.CarRadio.toggle, playerObj, part)
            if not ok then
                print("[ZeD] CarRadio: the radio kept vanilla's window: " .. tostring(err))
                return vanilla(playerObj, part)
            end
        end
    end
    ZeD.EscapeTakers = ZeD.EscapeTakers or {}
    if not ZeD.EscapeTakers.carRadio then
        ZeD.EscapeTakers.carRadio = function() return ZeD.CarRadio.takeEscape() end
    end
    if not _G._zedCarRadioAnnounced then
        _G._zedCarRadioAnnounced = true
        print("[ZeD] Overrides/CarRadio: the car radio routed to ZeD")
    end
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
