-- ZeD-UI/42/media/lua/client/ZeD/Overrides/VehicleMechanics.lua
-- ============================================================================
-- VEHICLE MECHANICS HOOK (override, client)
-- Every vanilla way into the mechanics window (right-click Mechanics, the V
-- radial, the mechanics key, using the hood) ends in ISOpenMechanicsUIAction,
-- the walk-over-and-look timed action. Its perform() normally shows
-- ISVehicleMechanics; ZeD instead marks the vehicle inspected and opens the
-- World window's Vehicle tab (ZeD.MechanicsTab). The vanilla window never shows.
--
-- ISVehicleMenu.onMechanic is wrapped too: when the vehicle is already
-- inspected, the tab opens straight away instead of repeating the look.
-- Vanilla runs when ZeD declines (no World window available), and every time
-- while safe mode is on (SafeMode.lua). The hooks sit behind _zed*Hooked
-- flags, so a Lua reload never wraps the wrapper.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/MechanicsTab"

local function apply()
    if ISOpenMechanicsUIAction and not ISOpenMechanicsUIAction._zedHooked then
        ISOpenMechanicsUIAction._zedHooked = true
        local origPerform = ISOpenMechanicsUIAction.perform
        function ISOpenMechanicsUIAction:perform()
            if ZeD.Safe.on() then return origPerform(self) end   -- safe mode: vanilla's mechanics window
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
            if ZeD.Safe.on() then return origOnMechanic(playerObj, vehicle) end
            local MT = ZeD and ZeD.MechanicsTab
            if MT and MT.isInspected and MT.isInspected(vehicle) and not playerObj:getVehicle() then
                -- U with the Vehicle tab up closes it, as the game's U toggles its window; closing the World window ends
                -- the look and shuts the hood (QA K1-9)
                local pn = playerObj:getPlayerNum()
                local W = ZeD_WorldWindow
                local win = W and W.isOpen and W.isOpen(pn) and W.getWindow and W.getWindow(pn)
                if win and win._activeTab == "vehicle" then
                    pcall(W.close, pn)
                    return
                end
                local ok, handled = pcall(MT.openFromAction, playerObj, vehicle, nil)
                if ok and handled then return end
            end
            return origOnMechanic(playerObj, vehicle)
        end
    end
    -- (KISS #60) A car's right-click gets Enter Vehicle and Vehicle Mechanics, running the game's own onEnter and
    -- onMechanic (the same calls E and U make), so a mouse player no longer right-clicks into an empty menu. The words
    -- are the game's own keys. Not in safe mode, and not when the game only asks whether a menu would exist (test).
    if ISVehicleMenu and ISVehicleMenu.FillMenuOutsideVehicle and not ISVehicleMenu._zedCarMenuHooked then
        ISVehicleMenu._zedCarMenuHooked = true
        local origFill = ISVehicleMenu.FillMenuOutsideVehicle
        function ISVehicleMenu.FillMenuOutsideVehicle(player, context, vehicle, test, ...)
            local r = origFill(player, context, vehicle, test, ...)
            if test or ZeD.Safe.on() or not (context and vehicle) then return r end
            pcall(function()
                local playerObj = getSpecificPlayer(player)
                if not playerObj or playerObj:getVehicle() then return end
                -- the seat E would take (the game's best seat from where he stands); none: the first free fitted seat
                local seat = vehicle:getBestSeat(playerObj)
                if seat == nil or seat < 0 then
                    seat = nil
                    for i = 0, vehicle:getMaxPassengers() - 1 do
                        if vehicle:isSeatInstalled(i) and not vehicle:isSeatOccupied(i) then seat = i; break end
                    end
                end
                if seat then context:addOption(getText("IGUI_EnterVehicle"), playerObj, ISVehicleMenu.onEnter, vehicle, seat) end
                context:addOption(getText("ContextMenu_VehicleMechanics"), playerObj, ISVehicleMenu.onMechanic, vehicle)
            end)
            return r
        end
    end
    -- E at the hood: vanilla's Use.EngineDoor looks again on an open hood; on a car already looked at, the hood shuts
    -- instead (QA K1-9). Vehicles loads after the client files, so this is tried again at game start.
    if Vehicles and Vehicles.Use and Vehicles.Use.EngineDoor and not Vehicles.Use._zedHoodHooked then
        Vehicles.Use._zedHoodHooked = true
        local origUse = Vehicles.Use.EngineDoor
        Vehicles.Use.EngineDoor = function(vehicle, part, character)
            if not ZeD.Safe.on() then
                local MT = ZeD and ZeD.MechanicsTab
                local ok, done = pcall(function()
                    return MT and MT.closeHoodLook and MT.closeHoodLook(character, vehicle, part)
                end)
                if ok and done then return end
            end
            return origUse(vehicle, part, character)
        end
    end
    print("[ZeD] Overrides/VehicleMechanics: mechanics window routed to the Vehicle tab")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
if Events and Events.OnGameStart then Events.OnGameStart.Add(apply) end   -- (the hood hook needs Vehicles, loaded later) (QA K1-9)
apply()
