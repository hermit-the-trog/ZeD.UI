-- ZeD-UI/42/media/lua/client/ZeD/Overrides/CarRadio.lua
-- ============================================================================
-- HOOK_MAP row 4: the vehicle wheel's last vanilla window.
--   * ISVehicleMenu.onSignalDevice (the wheel's Device Options slice, front
--     seats only) brings the fitted radio up close (ZeD_CarRadio.lua) instead
--     of vanilla's ISRadioWindow.
-- Any other device part (a mod's), or a radio the ZeD prop cannot show, opens
-- vanilla's window as before. While safe mode is on (SafeMode.lua) every
-- device opens vanilla's window, and turning it on puts away a radio already
-- up close.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ZeD_CarRadio"

-- safe mode turning on: the radio goes away (Escape no longer reaches it, the
-- prompts' key hook passes it to vanilla)
local function putAway()
    local props = ZeD.CarRadio and ZeD.CarRadio.props or {}
    for _, p in pairs(props) do
        if p and p:isReallyVisible() then pcall(p.close, p) end
    end
end

local function apply()
    if ISVehicleMenu and ISVehicleMenu.onSignalDevice and not ISVehicleMenu._zedRadio then
        local vanilla = ISVehicleMenu.onSignalDevice
        ISVehicleMenu._zedRadio = vanilla
        ISVehicleMenu.onSignalDevice = function(playerObj, part)
            if ZeD.Safe.on() then return vanilla(playerObj, part) end   -- safe mode: ISRadioWindow
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

-- nothing of vanilla's is parked here; the wrapper above asks at call time
ZeD.Safe.register("car radio", { leave = putAway, enter = function() end })
