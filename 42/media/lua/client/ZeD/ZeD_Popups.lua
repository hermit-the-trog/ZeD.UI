-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Popups.lua
-- ============================================================================
-- POP-UP LISTS SHUT WHEN NOT IN USE (client; no UI of its own)
-- (the director, Nov 23 2026: "Drop-down list selection boxes should disappear if they aren't used. Too often they
-- get stuck on the screen when something else is clicked on, another action is started.")
--
-- Every open pop-up list (a sort or show menu, a picker, a palette) calls ZeD.Popups.shown on each frame it draws,
-- naming itself (a stable key), the screen rects that count as inside it (the open list and its box) and its own
-- close function. This module then shuts it, through that function, when:
--   (a) a mouse press (left or right) lands outside its rects. The press is only watched, never taken: the click
--       still does whatever it was going to do (a world click, another window).
--   (b) it was not drawn: its owner hid, folded, changed tab or mode, or went away. A list missing from MISS frames
--       in a row is shut and forgotten.
--   (c) the player starts doing something else (lists with a player only): a timed action queued, the player
--       starting to move (keys or the stick), or a keyboard key the list does not use (a key meant for the game or
--       another window). The pad's buttons are the list's own while it is open (its rows are modal for the
--       FocusManager, _menuRows): B shuts it as before.
-- A pick, Esc and B still work as they did; this only adds the shutting the owners missed.
--
-- QA: ZeD.Popups.openCount() and ZeD.Popups.openKeys() (the pp_close checks: openCount() == 0 after each trigger).
-- ============================================================================

require "ZeD/ZeD_MouseTick"

ZeD = ZeD or {}
ZeD.Popups = ZeD.Popups or {}
local P = ZeD.Popups

-- a list missing from this many UI frames in a row is shut (2: one frame drawn late or skipped never shuts it)
P.MISS = 2

P._list = P._list or {}      -- key -> entry (see P.shown)
P._frame = P._frame or 0     -- the UI frame count (one per OnPreUIDraw)
P._moving = P._moving or {}  -- player number -> was moving at its last update
P._hold = P._hold or 0       -- > 0 while a list fires its own row (a queued action then does not shut it)
P._noOpts = {}               -- (shown without opts: every option off)

-- ----------------------------------------------------------------------------
-- keys a list keeps (rule c): its own navigation, and the modifiers alone
-- ----------------------------------------------------------------------------
P._keep = {}
P._typing = {}   -- printable keys and Backspace, kept too for a list that types ahead (opts.typing)
function P._fillKeys()
    if not Keyboard then return end
    local K = Keyboard
    local keep = { "KEY_UP", "KEY_DOWN", "KEY_LEFT", "KEY_RIGHT", "KEY_RETURN", "KEY_NUMPADENTER", "KEY_PRIOR",
        "KEY_NEXT", "KEY_HOME", "KEY_END", "KEY_ESCAPE", "KEY_BACK", "KEY_LSHIFT", "KEY_RSHIFT", "KEY_LCONTROL",
        "KEY_RCONTROL", "KEY_LMENU", "KEY_RMENU", "KEY_LMETA", "KEY_RMETA", "KEY_CAPITAL" }
    for _, name in ipairs(keep) do
        local code = K[name]
        if code then P._keep[code] = true end
    end
    -- printable: the LWJGL codes of the digit, letter, punctuation and space keys, and the number pad's
    local ranges = { { 2, 13 }, { 16, 27 }, { 30, 41 }, { 43, 53 }, { 55, 55 }, { 57, 57 }, { 71, 83 }, { 181, 181 } }
    for _, r in ipairs(ranges) do
        for c = r[1], r[2] do P._typing[c] = true end
    end
end
P._fillKeys()

-- ----------------------------------------------------------------------------
-- registering
-- ----------------------------------------------------------------------------

-- true when the entry's list is still open by its owner's own state (no isOpen given: it is)
function P._isOpen(e)
    if not e.isOpen then return true end
    local ok, open = pcall(e.isOpen, e.arg)
    return ok and open == true
end

-- shut one list through its owner and forget it (rule a, b or c). Only a list still open is closed, so a closer
-- that also moves the pad's focus back to the box never runs for a list its owner already shut.
function P._close(key, e, why)
    P._list[key] = nil
    if P._isOpen(e) and e.closer then
        local ok, err = pcall(e.closer, e.arg)
        if not ok then print("[ZeD] Popups: close " .. tostring(key) .. " (" .. tostring(why) .. "): " .. tostring(err)) end
        -- (for QA: what shut last and why; only a list this shut, not one its owner had already shut)
        P.lastClosed, P.lastWhy = key, why
    end
end

--- An open list calls this on every frame it draws.
--- key: a stable string ("health:0", "craft:sort"). rects: a list of absolute screen rects {x, y, w, h} that
--- count as inside (the open list and its box: a press there is the list's own), or nil.
--- closer: the list's close function, called as closer(opts.arg).
--- opts (optional; its fields are copied, so one table can serve every frame):
---   arg        what closer and isOpen get
---   isOpen     function(arg): true while the owner still has the list open (a list its owner shut is let go)
---   player     the player number the list belongs to (rule c for that player only; nil: any player)
---   noPlayer   true: a list with no player (the main menu): rule c off
---   noPress    true: the owner already shuts it on a press outside (rule a off here)
---   selfClosing true: a list that shuts itself on presses and when hidden (ZeD_ContextList): rule c only;
---              not drawn, it is forgotten without its closer
---   noMove     true: the player moving does not shut it
---   typing     true: printable keys and Backspace are the list's (type-ahead)
function P.shown(key, rects, closer, opts)
    if not key then return end
    local e = P._list[key]
    if not e then
        e = { rects = {}, n = 0 }
        P._list[key] = e
        e.movedAtOpen = nil
    end
    local o = opts or P._noOpts
    if e.frame == nil or e.frame < P._frame - 1 then
        -- (newly shown: a player already walking when it opened does not shut it until they stop and go again)
        local pn = opts and opts.player
        e.movedAtOpen = pn ~= nil and P._moving[pn] == true
    end
    e.frame, e.miss = P._frame, 0
    e.closer = closer
    e.arg, e.isOpen, e.player = o.arg, o.isOpen, o.player
    e.noPlayer, e.noPress, e.selfClosing = o.noPlayer, o.noPress, o.selfClosing
    e.noMove, e.typing = o.noMove, o.typing
    local n = 0
    if rects then
        for i = 1, #rects do
            local r = rects[i]
            if r then
                n = n + 1
                local d = e.rects[n]
                if not d then d = {}; e.rects[n] = d end
                d.x, d.y, d.w, d.h = r.x, r.y, r.w, r.h
            end
        end
    end
    e.n = n
end

-- the scratch rects shownAt fills (no table made per frame)
P._r1, P._r2, P._r3 = {}, {}, {}
P._rs = {}

-- put one panel-local rect, moved by (ax, ay), as the list's n-th scratch rect; returns the new count
function P._put(n, r, ax, ay, x, y, w, h)
    if x == nil or w == nil then return n end
    r.x, r.y, r.w, r.h = ax + x, ay + y, w, h
    P._rs[n + 1] = r
    return n + 1
end

--- shown with up to three rects given in the drawing panel's own coordinates (x, y, w, h each; nil to skip).
function P.shownAt(key, panel, closer, opts, x1, y1, w1, h1, x2, y2, w2, h2, x3, y3, w3, h3)
    local ax, ay = 0, 0
    if panel and panel.getAbsoluteX then ax, ay = panel:getAbsoluteX(), panel:getAbsoluteY() end
    local n = P._put(0, P._r1, ax, ay, x1, y1, w1, h1)
    n = P._put(n, P._r2, ax, ay, x2, y2, w2, h2)
    n = P._put(n, P._r3, ax, ay, x3, y3, w3, h3)
    local rs = P._rs
    for i = #rs, n + 1, -1 do rs[i] = nil end
    P.shown(key, rs, closer, opts)
end

--- The opts table for one owner's list, kept on the owner (owner._zedPopOpts[slot]) so no table is made per frame.
--- Its key is "<slot>:<player>" (o.key); arg is the owner; isOpen(owner) reads the owner's own open flag.
function P.opts(owner, slot, isOpen, player)
    local all = owner._zedPopOpts
    if not all then all = {}; owner._zedPopOpts = all end
    local o = all[slot]
    if not o or o.player ~= player then
        o = { arg = owner, isOpen = isOpen, player = player, key = (player ~= nil) and (slot .. ":" .. tostring(player)) or slot }
        all[slot] = o
    end
    return o
end

--- A list fires its own row: while fn runs, a timed action it queues does not shut lists (a row that keeps its
--- list open, ZeD_ContextList's keepOpen). Returns what fn returns (first two values).
function P.firing(fn, a, b)
    P._hold = P._hold + 1
    local ok, r1, r2 = pcall(fn, a, b)
    P._hold = P._hold - 1
    if not ok then error(r1) end
    return r1, r2
end

-- ----------------------------------------------------------------------------
-- QA
-- ----------------------------------------------------------------------------

--- How many lists are open now (registered and still open by their owners' state).
function P.openCount()
    local n = 0
    for _, e in pairs(P._list) do
        if P._isOpen(e) then n = n + 1 end
    end
    return n
end

--- The keys of the open lists, sorted.
function P.openKeys()
    local out = {}
    for k, e in pairs(P._list) do
        if P._isOpen(e) then out[#out + 1] = k end
    end
    table.sort(out)
    return out
end

--- Shut every open list (QA, and a hard reset such as the game ending).
function P.closeAll(why)
    local keys = {}
    for k in pairs(P._list) do keys[#keys + 1] = k end
    for _, k in ipairs(keys) do
        local e = P._list[k]
        if e then P._close(k, e, why or "all") end
    end
end

-- ----------------------------------------------------------------------------
-- the rules
-- ----------------------------------------------------------------------------

local function inside(e, x, y)
    for i = 1, e.n do
        local r = e.rects[i]
        if x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h then return true end
    end
    return false
end

-- (a) a press at screen (x, y): every list it is outside of shuts. Collected first, closed after (a closer may
-- register or drop other lists).
function P.onPress(button, x, y)
    local hit = nil
    for k, e in pairs(P._list) do
        if not (e.noPress or e.selfClosing) and not inside(e, x, y) then
            hit = hit or {}
            hit[#hit + 1] = k
        end
    end
    if not hit then return end
    for _, k in ipairs(hit) do
        local e = P._list[k]
        if e then P._close(k, e, "press") end
    end
end

-- (b) after the UI drew: a list not drawn this frame misses one; MISS misses in a row shut it
function P.afterDraw()
    local hit = nil
    for k, e in pairs(P._list) do
        if e.frame ~= P._frame then
            e.miss = (e.miss or 0) + 1
            if e.miss >= P.MISS then
                hit = hit or {}
                hit[#hit + 1] = k
            end
        end
    end
    if not hit then return end
    for _, k in ipairs(hit) do
        local e = P._list[k]
        if e then
            if e.selfClosing then P._list[k] = nil   -- (it shuts itself when hidden: just forgotten)
            else P._close(k, e, "hidden") end
        end
    end
end

-- (c) shut the lists of player pn (nil: every player's) that rule c covers; test(e) may skip some
function P._closePlayer(pn, why, test)
    local hit = nil
    for k, e in pairs(P._list) do
        if not e.noPlayer and (pn == nil or e.player == nil or e.player == pn) and (not test or test(e)) then
            hit = hit or {}
            hit[#hit + 1] = k
        end
    end
    if not hit then return end
    for _, k in ipairs(hit) do
        local e = P._list[k]
        if e then P._close(k, e, why) end
    end
end

-- (c) a timed action queued for a character
function P.onAction(action)
    if P._hold > 0 then return end
    local chr = action and action.character
    local pn = nil
    if chr and chr.getPlayerNum then
        local ok, n = pcall(chr.getPlayerNum, chr)
        if ok then pn = n end
    end
    -- an action of no player we can name (an NPC, an animal, a script) shuts nobody's list: in split screen it
    -- must not shut another player's (QA, Nov 23 2026)
    if pn == nil then return end
    P._closePlayer(pn, "action")
end

local function keyShuts(e, key)
    if P._keep[key] then return false end
    if e.typing and P._typing[key] then return false end
    return true
end

-- true when player pn plays with a controller (the keyboard is not theirs: split screen)
function P._padPlayer(pn)
    return pn ~= nil and JoypadState ~= nil and JoypadState.players ~= nil and JoypadState.players[pn + 1] ~= nil
end

-- (c) a keyboard key: lists that do not use it shut (a controller player's lists are not the keyboard's)
function P.onKey(key)
    local any = false
    for _ in pairs(P._list) do any = true; break end
    if not any then return end
    P._closePlayer(nil, "key", function(e) return keyShuts(e, key) and not P._padPlayer(e.player) end)
end

-- (c) the player started moving (keys, the stick, a walk-to)
local function notMovedAtOpen(e) return not e.noMove and not e.movedAtOpen end
function P.onPlayerUpdate(player)
    if not player then return end
    local okN, pn = pcall(player.getPlayerNum, player)
    if not okN or pn == nil then return end
    local okM, moving = pcall(player.isPlayerMoving, player)
    moving = okM and moving == true
    local was = P._moving[pn]
    P._moving[pn] = moving
    local any = false
    for _ in pairs(P._list) do any = true; break end
    if not any then return end
    if not moving then
        -- stopped: a list opened while walking now shuts on the next start
        for _, e in pairs(P._list) do
            if e.player == pn and e.movedAtOpen then e.movedAtOpen = false end
        end
        return
    end
    if was then return end   -- (still walking: only the start of a walk shuts lists)
    P._closePlayer(pn, "move", notMovedAtOpen)
end

-- ----------------------------------------------------------------------------
-- hooks (each once: the file may be loaded again by a Lua reload)
-- ----------------------------------------------------------------------------

function P._wrapQueue()
    if not ISTimedActionQueue or ISTimedActionQueue._zedPopups then return end
    ISTimedActionQueue._zedPopups = true
    local origAdd = ISTimedActionQueue.add
    ISTimedActionQueue.add = function(action, ...)
        local a, b = origAdd(action, ...)   -- (after the call; its return kept)
        local ok, err = pcall(P.onAction, action)
        if not ok then print("[ZeD] Popups: " .. tostring(err)) end
        return a, b
    end
end

if not P._hooked and Events then
    P._hooked = true
    if Events.OnPreUIDraw then Events.OnPreUIDraw.Add(function() P._frame = P._frame + 1 end) end
    if Events.OnPostUIDraw then Events.OnPostUIDraw.Add(function() P.afterDraw() end) end
    -- the mouse: ZeD_MouseTick's per-frame sample tells of each press (left and right)
    if ZeD.MouseTick and ZeD.MouseTick.listen then
        ZeD.MouseTick.listen(function(button, x, y) P.onPress(button, x, y) end)
    end
    -- (the key going down: OnKeyPressed comes on the release, which would shut a list its own key-down just opened)
    if Events.OnKeyStartPressed then Events.OnKeyStartPressed.Add(function(key) P.onKey(key) end)
    elseif Events.OnKeyPressed then Events.OnKeyPressed.Add(function(key) P.onKey(key) end) end
    if Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(function(pl) P.onPlayerUpdate(pl) end) end
    P._wrapQueue()
    if Events.OnGameBoot then Events.OnGameBoot.Add(P._wrapQueue) end
    if Events.OnGameStart then Events.OnGameStart.Add(P._wrapQueue) end
end

return P
