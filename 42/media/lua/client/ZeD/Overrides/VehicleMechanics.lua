-- ZeD-UI/42/media/lua/client/ZeD/Overrides/VehicleMechanics.lua
-- ============================================================================
-- VEHICLE MECHANICS HOOK — HOOK_MAP row 3
-- Every vanilla way into the mechanics window (right-click Mechanics, the V
-- radial, the mechanics key, using the hood) ends in ISOpenMechanicsUIAction,
-- the walk-over-and-look timed action. Its perform() normally shows
-- ISVehicleMechanics; ZeD instead marks the vehicle inspected and opens the
-- World window's Vehicle tab (ZeD.MechanicsTab). The vanilla window never shows.
--
-- ISVehicleMenu.onMechanic is wrapped too: when the vehicle is already
-- inspected, the tab opens straight away instead of repeating the look.
-- Vanilla runs when ZeD declines (no World window available).
-- ============================================================================

require "ZeD/MechanicsTab"

local function apply()
    if ISOpenMechanicsUIAction and not ISOpenMechanicsUIAction._zedHooked then
        ISOpenMechanicsUIAction._zedHooked = true
        local origPerform = ISOpenMechanicsUIAction.perform
        function ISOpenMechanicsUIAction:perform()
            local MT = ZeD and ZeD.MechanicsTab
            local ok, handled = pcall(function()
                return MT and MT.openFromAction and MT.openFromAction(self.character, self.vehicle, self.usedHood)
            end)
            if not (ok and handled) then
                if not ok then print("[ZeD] VehicleMechanics: openFromAction failed: " .. tostring(handled)) end
                return origPerform(self)
            end
            ISBaseTimedAction.perform(self)
        end
    end
    if ISVehicleMenu and ISVehicleMenu.onMechanic and not ISVehicleMenu._zedMechHooked then
        ISVehicleMenu._zedMechHooked = true
        local origOnMechanic = ISVehicleMenu.onMechanic
        function ISVehicleMenu.onMechanic(playerObj, vehicle)
            local MT = ZeD and ZeD.MechanicsTab
            if MT and MT.isInspected and MT.isInspected(vehicle) and not playerObj:getVehicle() then
                local ok, handled = pcall(MT.openFromAction, playerObj, vehicle, nil)
                if ok and handled then return end
            end
            return origOnMechanic(playerObj, vehicle)
        end
    end
    print("[ZeD] Overrides/VehicleMechanics: mechanics window routed to the Vehicle tab")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
