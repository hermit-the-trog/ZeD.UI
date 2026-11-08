-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Animals.lua
-- ============================================================================
-- ANIMAL CARD HOOKS — HOOK_MAP rows 20, 21, 22
-- The hutch, the feeding trough, the butcher hook and an inspected track open
-- object cards in the World window's card drawer instead of vanilla's windows:
--   * hutch: ISHutchMenu.onInfo (world menu) opens the card, walking to the
--     hutch first when it is out of reach; ISGetHutchInfo:perform (Shift +
--     interact, the vanilla zone window) opens it too;
--   * trough: ISFeedingTroughMenu.onInfo (Feeding Trough Info);
--   * butcher hook: ISOpenButcherHookUI:perform (world menu, the hook's own
--     menu, interact: every path ends in this action);
--   * tracks: ISInspectAnimalTrackAction:perform (search mode icon, a track on
--     the ground, a track item).
-- Vanilla runs only when ZeD declines (no World window, object not found),
-- and every time while safe mode is on (SafeMode.lua).
--
-- (Nov 7 2026, VANILLA_WINDOWS_20261107.md rows B4, B5) The game's animal info
-- and livestock zone windows go to the Animals tab (ZeD.WorldRoutes):
--   * AnimalContextMenu.onAnimalInfo (right-click an animal > Info, the animal
--     wheel's Info slice, the hutch window's Info) -> the animal's view;
--   * ISOpenAnimalInfo:perform (the walk-then-look action of the game's zone
--     and trailer windows) -> the animal's view;
--   * AnimalContextMenu.onCheckZone (right-click inside a zone > Check zone)
--     -> that zone's view; the game's first-time zone note
--     (ISAnimalZoneFirstInfo.showUI) is not shown while ZeD's World window is
--     the player's, unless it is asked for.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/WorldRoutes"
require "ZeD/ObjectCards"
require "ZeD/ObjectCardHutch"
require "ZeD/ObjectCardTrough"
require "ZeD/ObjectCardHook"
require "ZeD/ObjectCardTrack"

local OC = ZeD.ObjectCards

local function route(label, fn, ...)
    local ok, handled = pcall(fn, ...)
    if not ok then print("[ZeD] Animals: " .. label .. " route failed: " .. tostring(handled)) end
    return ok and handled
end

-- an action's perform: open the card and finish the action
local function hookPerform(cls, label, kind, pick)
    if not cls or cls._zedCardHooked then return end
    cls._zedCardHooked = true
    local orig = cls.perform
    cls.perform = function(self)
        if ZeD.Safe.on() then return orig(self) end   -- safe mode: vanilla's window
        local player, obj = pick(self)
        if player and obj and route(label, OC.open, player, kind, obj) then
            ISBaseTimedAction.perform(self)
            return
        end
        return orig(self)
    end
end

local function apply()
    -- hutch
    if ISHutchMenu and not ISHutchMenu._zedCardHooked then
        ISHutchMenu._zedCardHooked = true
        local orig = ISHutchMenu.onInfo
        ISHutchMenu.onInfo = function(hutch, chr)
            if ZeD.Safe.on() then return orig(hutch, chr) end
            local entry = hutch and hutch.getEntrySq and hutch:getEntrySq()
            if chr and hutch and route("hutch info", OC.openNear, chr, "hutch", hutch, entry) then return end
            return orig(hutch, chr)
        end
    end
    hookPerform(ISGetHutchInfo, "hutch", "hutch", function(a) return a.character, a.hutch end)

    -- feeding trough
    if ISFeedingTroughMenu and not ISFeedingTroughMenu._zedCardHooked then
        ISFeedingTroughMenu._zedCardHooked = true
        local orig = ISFeedingTroughMenu.onInfo
        ISFeedingTroughMenu.onInfo = function(trough, chr)
            if ZeD.Safe.on() then return orig(trough, chr) end
            if chr and trough and route("trough info", OC.openNear, chr, "trough", trough, trough:getSquare()) then return end
            return orig(trough, chr)
        end
    end

    -- butcher hook (vanilla's window would close any other open on this hook)
    hookPerform(ISOpenButcherHookUI, "butcher hook", "hook", function(a) return a.character, a.hook end)

    -- tracks
    hookPerform(ISInspectAnimalTrackAction, "tracks", "track", function(a) return a.character, a.track end)

    -- animal info and Check zone: the Animals tab
    local WR = ZeD.WorldRoutes
    if AnimalContextMenu and AnimalContextMenu.onAnimalInfo and not AnimalContextMenu._zedInfoHooked then
        AnimalContextMenu._zedInfoHooked = true
        local orig = AnimalContextMenu.onAnimalInfo
        AnimalContextMenu.onAnimalInfo = function(animal, chr)
            if ZeD.Safe.on() then return orig(animal, chr) end
            if route("animal info", WR.animal, chr, animal) then return end
            return orig(animal, chr)
        end
    end
    if ISOpenAnimalInfo and not ISOpenAnimalInfo._zedCardHooked then
        ISOpenAnimalInfo._zedCardHooked = true
        local orig = ISOpenAnimalInfo.perform
        ISOpenAnimalInfo.perform = function(self)
            if ZeD.Safe.on() then return orig(self) end
            if route("animal info", WR.animal, self.character, self.animal) then
                ISBaseTimedAction.perform(self)
                return
            end
            return orig(self)
        end
    end
    if AnimalContextMenu and AnimalContextMenu.onCheckZone and not AnimalContextMenu._zedZoneHooked then
        AnimalContextMenu._zedZoneHooked = true
        local orig = AnimalContextMenu.onCheckZone
        AnimalContextMenu.onCheckZone = function(zone, playerObj)
            if ZeD.Safe.on() then return orig(zone, playerObj) end
            if route("check zone", WR.zone, playerObj, zone) then return end
            return orig(zone, playerObj)
        end
    end
    if ISAnimalZoneFirstInfo and ISAnimalZoneFirstInfo.showUI and not ISAnimalZoneFirstInfo._zedHooked then
        ISAnimalZoneFirstInfo._zedHooked = true
        local orig = ISAnimalZoneFirstInfo.showUI
        ISAnimalZoneFirstInfo.showUI = function(playerNum, force)
            if not ZeD.Safe.on() and route("zone note", WR.skipZoneNote, playerNum, force) then return end
            return orig(playerNum, force)
        end
    end

    print("[ZeD] Overrides/Animals: hutch, trough, butcher hook and tracks routed to the animal cards; animal info and Check zone to the Animals tab")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
