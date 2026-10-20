-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Seats.lua
-- ============================================================================
-- HOOK_MAP row 4: the vehicle wheel's two remaining vanilla windows.
--   * ISVehicleMenu.onShowSeatUI (Switch Seat and Enter Vehicle on the wheel,
--     the seat key) opens the ZeD seat chooser (ZeD_SeatChooser.lua) instead
--     of ISVehicleSeatUI.
--   * ISLightbarUITimedAction:perform (the wheel's Lightbar slice) brings up the
--     siren controller prop (ZeD_SirenController.lua) instead of ISLightbarUI.
-- Both keep vanilla's flow around them (the paused check, the timed action).
-- If either ZeD surface fails to open, vanilla's window opens instead. While
-- safe mode is on (SafeMode.lua) vanilla's windows open every time, and
-- turning it on puts away a chooser or a controller already on screen.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ZeD_SeatChooser"
require "ZeD/ZeD_SirenController"

-- safe mode turning on: the chooser and the controller go away (Escape no
-- longer reaches them, the prompts' key hook passes it to vanilla)
local function putAway()
    local seats = ZeD.Seats and ZeD.Seats.windows or {}
    for _, w in pairs(seats) do
        if w and w:isReallyVisible() then pcall(w.close, w) end
    end
    local props = ZeD.Siren and ZeD.Siren.props or {}
    for _, p in pairs(props) do
        if p and p:isReallyVisible() then pcall(p.close, p) end
    end
end

local function apply()
    if ISVehicleMenu and ISVehicleMenu.onShowSeatUI and not ISVehicleMenu._zedSeats then
        local vanilla = ISVehicleMenu.onShowSeatUI
        ISVehicleMenu._zedSeats = vanilla
        ISVehicleMenu.onShowSeatUI = function(playerObj, vehicle)
            if ZeD.Safe.on() then return vanilla(playerObj, vehicle) end   -- safe mode: ISVehicleSeatUI
            local ok, err = pcall(ZeD.Seats.toggle, playerObj, vehicle)
            if not ok then
                print("[ZeD] Seats: the seat chooser kept vanilla's: " .. tostring(err))
                return vanilla(playerObj, vehicle)
            end
        end
    end
    if ISLightbarUITimedAction and not ISLightbarUITimedAction._zedSiren then
        local vanilla = ISLightbarUITimedAction.perform
        ISLightbarUITimedAction._zedSiren = vanilla
        function ISLightbarUITimedAction:perform()
            if ZeD.Safe.on() then return vanilla(self) end   -- safe mode: ISLightbarUI
            local ok, err = pcall(ZeD.Siren.toggle, self.character)
            if not ok then
                print("[ZeD] Seats: the lightbar kept vanilla's: " .. tostring(err))
                return vanilla(self)
            end
            ISBaseTimedAction.perform(self)
        end
    end
    -- Escape closes either one (asked by the prompts' key hook before the pause menu)
    ZeD.EscapeTakers = ZeD.EscapeTakers or {}
    if not ZeD.EscapeTakers.seats then
        ZeD.EscapeTakers.seats = function() return ZeD.Seats.takeEscape() end
        ZeD.EscapeTakers.siren = function() return ZeD.Siren.takeEscape() end
    end
    if not _G._zedSeatsAnnounced then
        _G._zedSeatsAnnounced = true
        print("[ZeD] Overrides/Seats: the seat chooser and the lightbar routed to ZeD")
    end
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()

-- nothing of vanilla's is parked here; the wrappers above ask at call time
ZeD.Safe.register("seats and lightbar", { leave = putAway, enter = function() end })
