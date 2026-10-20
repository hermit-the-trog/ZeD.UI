-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Padlocks.lua
-- ============================================================================
-- PADLOCK CODES — HOOK_MAP row 25
-- Vanilla's world menu (built in Java, ISWorldObjectContextMenuLogic) offers
-- Use Combination Padlock and Remove Combination Padlock on objects that take
-- a padlock; both clear the queue, walk next to the object and open
-- ISDigitalCode. ZeD opens the lock card (ObjectCardLock.lua) instead, with
-- the walk only when the object is out of the card's reach. The after-walk
-- functions are routed too, for anything else that calls them. Vanilla runs
-- when ZeD declines (no World window), and every time while safe mode is on
-- (SafeMode.lua).
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ObjectCardLock"

local function open(playerNum, thump, set)
    if ZeD.Safe.on() then return false end   -- safe mode: vanilla's ISDigitalCode
    local LK = ZeD and ZeD.ObjectCardLock
    local p = getSpecificPlayer(playerNum)
    if not (LK and LK.openFor and p and thump) then return false end
    local ok, handled = pcall(LK.openFor, p, thump, set)
    if not ok then print("[ZeD] Padlocks: lock card failed: " .. tostring(handled)) end
    return ok and handled
end

local function apply()
    local M = ISWorldObjectContextMenu
    if not M or M._zedPadlockHooked then return end
    M._zedPadlockHooked = true

    local origPut = M.onPutDigitalPadlock
    M.onPutDigitalPadlock = function(worldobjects, player, thump, padlock)
        if open(player, thump, true) then return end
        return origPut(worldobjects, player, thump, padlock)
    end
    local origRemove = M.onRemoveDigitalPadlock
    M.onRemoveDigitalPadlock = function(worldobjects, player, thump)
        if open(player, thump, false) then return end
        return origRemove(worldobjects, player, thump)
    end
    local origPutDone = M.onPutDigitalPadlockWalkToComplete
    M.onPutDigitalPadlockWalkToComplete = function(player, thump, padlock)
        if open(player, thump, true) then return end
        return origPutDone(player, thump, padlock)
    end
    local origRemoveDone = M.onRemoveDigitalPadlockWalkToComplete
    M.onRemoveDigitalPadlockWalkToComplete = function(player, thump)
        if open(player, thump, false) then return end
        return origRemoveDone(player, thump)
    end
    print("[ZeD] Overrides/Padlocks: combination padlocks routed to the lock card")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
