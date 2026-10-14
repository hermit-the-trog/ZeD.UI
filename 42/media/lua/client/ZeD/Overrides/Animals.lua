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
-- Vanilla runs only when ZeD declines (no World window, object not found).
-- ============================================================================

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
            if chr and trough and route("trough info", OC.openNear, chr, "trough", trough, trough:getSquare()) then return end
            return orig(trough, chr)
        end
    end

    -- butcher hook (vanilla's window would close any other open on this hook)
    hookPerform(ISOpenButcherHookUI, "butcher hook", "hook", function(a) return a.character, a.hook end)

    -- tracks
    hookPerform(ISInspectAnimalTrackAction, "tracks", "track", function(a) return a.character, a.track end)

    print("[ZeD] Overrides/Animals: hutch, trough, butcher hook and tracks routed to the animal cards")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
