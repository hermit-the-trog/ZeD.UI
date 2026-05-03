-- ZeD-UI/42/media/lua/client/ZeD/ItemActionManager.lua
-- ============================================================================
-- ITEM ACTION MANAGER (S120 — T2.3)
-- Tracks active timed actions per inventory item via a registered-observer
-- pattern. The Card Progress Band molecule queries getActiveAction(item) to
-- decide whether to render and in what mode.
--
-- Observer-driven, NOT Events.OnTick. Active actions push state changes
-- via notify(item, event, action). Inactive items pay zero per-frame cost —
-- the molecule short-circuits to height = 0 when getActiveAction returns nil.
--
-- This module is the scaffold for Phase 5 (S121) organism integration. The
-- PZ TimedAction wiring (subscribe ISRepairClothing / ISCookFood / ISReadABook
-- etc. to push start/tick/complete/cancel/danger events) lives in S121.
-- The contract — registerObserver / unregisterObserver / getActiveAction /
-- notify / clear — is what S121 will integrate against. Don't change shape
-- without updating Card Progress Band molecule + S121 organism in lockstep.
-- ============================================================================

ZeD = ZeD or {}
ZeD.ItemActionManager = ZeD.ItemActionManager or {}

local M = ZeD.ItemActionManager

-- Active-action map. _active[item] = {mode, label, percent, timeStr} or nil.
-- Item is the table identity (Java userdata bridged via Kahlua) — works as a
-- weak-ish key, though Kahlua tables don't support weak keys natively, so
-- callers must call notify(item, "complete"/"cancel", ...) to free the entry.
M._active = M._active or {}

-- Observer map. _observers[item] = {[handle] = callbacks, ...}
M._observers = M._observers or {}

local _nextHandle = 1

-- ---------------------------------------------------------------------------
-- registerObserver(item, callbacks) → handle
-- ---------------------------------------------------------------------------
-- Subscribe to lifecycle events for a single item. Callbacks is a table with
-- any subset of: onStart, onTick, onComplete, onCancel, onDanger. Each is
-- invoked under pcall so a buggy observer can't crash the engine loop.
--
-- @param item       PZ inventory item
-- @param callbacks  Table of optional onX functions; signature (item, action)
-- @return handle    Opaque value; pass to unregisterObserver to remove
function M.registerObserver(item, callbacks)
    if not item or not callbacks then return nil end
    M._observers[item] = M._observers[item] or {}
    local h = _nextHandle
    _nextHandle = _nextHandle + 1
    M._observers[item][h] = callbacks
    return h
end

-- ---------------------------------------------------------------------------
-- unregisterObserver(item, handle)
-- ---------------------------------------------------------------------------
-- Cleanup. Always paired with registerObserver from the same caller. Safe to
-- call with stale handle — just clears that slot if present.
function M.unregisterObserver(item, handle)
    if not item or not handle then return end
    local obs = M._observers[item]
    if obs then
        obs[handle] = nil
        -- Drop the per-item table when empty so we don't leak forever
        local empty = true
        for _ in pairs(obs) do empty = false; break end
        if empty then M._observers[item] = nil end
    end
end

-- ---------------------------------------------------------------------------
-- getActiveAction(item) → action | nil
-- ---------------------------------------------------------------------------
-- Returns the in-progress action for an item, or nil if idle. The Card
-- Progress Band molecule uses this as its render gate.
function M.getActiveAction(item)
    if not item then return nil end
    return M._active[item]
end

-- ---------------------------------------------------------------------------
-- notify(item, event, action)
-- ---------------------------------------------------------------------------
-- Push a state change. Updates _active and fires matching observer callbacks.
--
-- Events drive the active map:
--   "start"    → _active[item] = action
--   "tick"     → _active[item] = action  (caller may pass updated percent/timeStr)
--   "danger"   → _active[item] = action  (mode flipped to "danger" by caller)
--   "complete" → _active[item] = nil
--   "cancel"   → _active[item] = nil
--
-- @param item   PZ inventory item
-- @param event  One of the strings above
-- @param action Table {mode, label, percent, timeStr} for start/tick/danger; nil for complete/cancel
function M.notify(item, event, action)
    if not item or not event then return end
    if event == "complete" or event == "cancel" then
        M._active[item] = nil
    else
        M._active[item] = action
    end
    local obs = M._observers[item]
    if obs then
        -- "start" → "onStart", etc. Capitalize first letter, prefix "on".
        local key = "on" .. event:sub(1, 1):upper() .. event:sub(2)
        for _, cb in pairs(obs) do
            local fn = cb[key]
            if fn then pcall(fn, item, action) end
        end
    end
end

-- ---------------------------------------------------------------------------
-- clear()
-- ---------------------------------------------------------------------------
-- Wipe all state. Called on player swap, save load, or test reset.
function M.clear()
    M._active    = {}
    M._observers = {}
    _nextHandle  = 1
end
