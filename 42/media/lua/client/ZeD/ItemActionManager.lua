-- ZeD-UI/42/media/lua/client/ZeD/ItemActionManager.lua
-- ============================================================================
-- ITEM ACTION MANAGER — client; shared state, no UI of its own.
-- Answers one question fast: does this inventory item have a timed action
-- running, and what does it look like (mode, label, percent, timeStr)?
-- ItemActionHooks.lua pushes state in through notify(); the Card Progress
-- Band molecule polls getActiveAction(item) each frame and draws nothing on
-- nil, so idle items pay zero per-frame cost. No Events.OnTick here — this
-- file never polls; detection lives with the callers.
-- The public shape — registerObserver / unregisterObserver / getActiveAction
-- / notify / clear — is what the card and the hooks build against; change it
-- only with both ends in hand.
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

--- Subscribe to lifecycle events for a single item. callbacks is a table with
--- any subset of onStart, onTick, onComplete, onCancel, onDanger; each fires
--- under pcall so a buggy observer can't crash the engine loop. Nothing in
--- the mod registers one today — the card polls getActiveAction instead.
--- @param item       PZ inventory item
--- @param callbacks  Table of optional onX functions; signature (item, action)
--- @return handle    Opaque value; pass to unregisterObserver to remove
function M.registerObserver(item, callbacks)
    if not item or not callbacks then return nil end
    M._observers[item] = M._observers[item] or {}
    local h = _nextHandle
    _nextHandle = _nextHandle + 1
    M._observers[item][h] = callbacks
    return h
end

--- Remove one observer. Always paired with registerObserver from the same
--- caller. Safe with a stale handle — clears that slot if present.
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

--- The in-progress action for an item, or nil when idle. The Card Progress
--- Band molecule uses this as its render gate.
function M.getActiveAction(item)
    if not item then return nil end
    return M._active[item]
end

--- Push a state change. Updates _active and fires matching observer callbacks.
--- Events drive the active map:
---   "start"    → _active[item] = action
---   "tick"     → _active[item] = action  (caller may pass updated percent/timeStr)
---   "danger"   → _active[item] = action  (mode flipped to "danger" by caller)
---   "complete" → _active[item] = nil
---   "cancel"   → _active[item] = nil
--- @param item   PZ inventory item
--- @param event  One of the strings above
--- @param action Table {mode, label, percent, timeStr} for start/tick/danger; nil for complete/cancel
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

--- Wipe all state — active actions, observers, handle counter. Here for
--- player-swap / save-reload resets; nothing calls it yet.
function M.clear()
    M._active    = {}
    M._observers = {}
    _nextHandle  = 1
end
