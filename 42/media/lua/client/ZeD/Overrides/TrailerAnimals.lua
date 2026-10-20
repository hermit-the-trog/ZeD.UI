-- ZeD-UI/42/media/lua/client/ZeD/Overrides/TrailerAnimals.lua
-- ============================================================================
-- ANIMAL TRAILER HOOK — HOOK_MAP row 23
-- Vanilla's "Check Animal(s) in Trailer" (the world menu and the vehicle
-- wheel) walks to the back of the trailer, then ISCheckAnimalInsideTrailer
-- opens ISVehicleAnimalUI. ZeD opens the Vehicle tab on the trailer instead,
-- scrolled to its animals (ZeD.MechTrailer), and skips the walk when the
-- trailer is already in the tab's reach. Vanilla runs when ZeD declines.
--
-- Two vanilla bugs are fixed on the way:
--   * the world menu's "Remove Animal from Trailer" queued the action without
--     the animal, so it did nothing; it now removes the one you picked;
--   * "Put Animal in Trailer" vanished when a carcass in your hands was the
--     only thing to load (doAnimalSubMenu never counted it); it now stays.
--
-- While safe mode is on (SafeMode.lua) all of it is vanilla's again, the two
-- bugs included.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/MechanicsTab"

-- a carcass in the hands that vanilla's Add Animal lists (not a skeleton)
local function heldCarcass(playerObj)
    local h = playerObj and playerObj:getPrimaryHandItem()
    if not (h and h:getType() == "CorpseAnimal") then return false end
    local ok, yes = pcall(function()
        local b = h:getDeadBodyObject()
        return b ~= nil and b:isAnimal() and not b:isAnimalSkeleton()
    end)
    return ok and yes
end

local function apply()
    if ISCheckAnimalInsideTrailer and not ISCheckAnimalInsideTrailer._zedHooked then
        ISCheckAnimalInsideTrailer._zedHooked = true
        local origPerform = ISCheckAnimalInsideTrailer.perform
        function ISCheckAnimalInsideTrailer:perform()
            if ZeD.Safe.on() then return origPerform(self) end   -- safe mode: vanilla's window
            local MT = ZeD and ZeD.MechanicsTab
            local ok, handled = pcall(function()
                return MT and MT.openTrailer and MT.openTrailer(self.character, self.vehicle)
            end)
            if not (ok and handled) then
                if not ok then print("[ZeD] TrailerAnimals: openTrailer failed: " .. tostring(handled)) end
                return origPerform(self)
            end
            ISBaseTimedAction.perform(self)
        end
    end

    if ISVehicleMenu and not ISVehicleMenu._zedTrailerHooked then
        ISVehicleMenu._zedTrailerHooked = true

        local origCheck = ISVehicleMenu.onCheckAnimalInside
        function ISVehicleMenu.onCheckAnimalInside(vehicle, playerObj)
            if ZeD.Safe.on() then return origCheck(vehicle, playerObj) end
            local MT = ZeD and ZeD.MechanicsTab
            if MT and MT.inReach and MT.inReach(playerObj, vehicle) and not playerObj:getVehicle() then
                local ok, handled = pcall(MT.openTrailer, playerObj, vehicle)
                if ok and handled then return end
            end
            return origCheck(vehicle, playerObj)
        end

        -- vanilla: ISRemoveAnimalFromTrailer:new(playerObj, vehicle) — no animal
        local origRemove = ISVehicleMenu.onRemoveAnimalFromTrailer
        function ISVehicleMenu.onRemoveAnimalFromTrailer(playerObj, animal, vehicle)
            if ZeD.Safe.on() and origRemove then return origRemove(playerObj, animal, vehicle) end
            local vec = vehicle:getAreaCenter("AnimalEntry")
            local sq = getSquare(vec:getX(), vec:getY(), vehicle:getZ())
            if luautils.walkAdj(playerObj, sq) then
                ISTimedActionQueue.add(ISRemoveAnimalFromTrailer:new(playerObj, vehicle, animal, false))
            end
        end

        -- vanilla's held-carcass branch adds its option but never sets added
        local origSub = ISVehicleMenu.doAnimalSubMenu
        function ISVehicleMenu.doAnimalSubMenu(subMenu, playerObj, vehicle)
            if ZeD.Safe.on() then return origSub(subMenu, playerObj, vehicle) end
            local added = origSub(subMenu, playerObj, vehicle)
            if not added and heldCarcass(playerObj) then added = true end
            return added
        end
    end
    print("[ZeD] Overrides/TrailerAnimals: Check Animals routed to the Vehicle tab")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
