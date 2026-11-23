-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MouseTick.lua
-- ============================================================================
-- THE LEFT BUTTON FOR CODE THAT POLLS IT IN update(). Client; a small helper
-- with no UI, read by the main menu's screens.
--
-- The engine runs the UI's update() only every 100 ms (42.22: UIManager.update
-- gates the elements' updates on doTick) and draws every frame. A poller that
-- reads isMouseButtonDown(0) in update() and acts on "was down, now up" misses
-- a click whose press and release both fall between two updates.
-- ZeD.MouseTick.down() is what such a poller should read: the button as it is,
-- except that a press seen on any frame since the last update counts as down
-- for one update, so the next one sees the release. Every caller in the same
-- update gets the same answer. Code that polls on every frame drawn reads
-- isMouseButtonDown(0) itself.
-- ============================================================================

ZeD = ZeD or {}
ZeD.MouseTick = ZeD.MouseTick or {}
local M = ZeD.MouseTick

local prev, pressed = false, false
local tickAt, tickDown = -1000, false
local prevR = false   -- the right button at the last frame (for the press listeners)

-- functions told of every press, left or right, as fn(button, x, y) (ZeD_Popups.lua: a press outside a pop-up
-- list shuts it). Only told: the press goes on to whatever it was for.
M._listeners = M._listeners or {}

--- Be told of each mouse press seen by the per-frame sample: fn(button 0 or 1, screen x, screen y).
function M.listen(fn)
    for _, f in ipairs(M._listeners) do if f == fn then return end end
    M._listeners[#M._listeners + 1] = fn
end

-- tell the listeners of one press
local function tell(button)
    local n = #M._listeners
    if n == 0 then return end
    local x, y = getMouseX(), getMouseY()
    for i = 1, n do
        local ok, err = pcall(M._listeners[i], button, x, y)
        if not ok then print("[ZeD] MouseTick listener: " .. tostring(err)) end
    end
end

--- Note a press. Runs on every frame drawn (OnPreUIDraw); the kicked or
--- disconnected screen (ZeD_LeftScreen), whose game state clears every Lua
--- event, calls it from its own prerender instead.
function M.sample()
    local d = isMouseButtonDown(0)
    if d and not prev then pressed = true; tell(0) end
    prev = d
    local r = isMouseButtonDown(1)
    if r and not prevR then tell(1) end
    prevR = r
end
Events.OnPreUIDraw.Add(M.sample)

--- The left button as an update() poller should see it: true while it is down,
--- and for one update after a press seen on any frame since the last one.
function M.down()
    local now = getTimestampMs()
    if now - tickAt > 30 then   -- a new update (100 ms apart); the callers in one update share the answer
        tickAt = now
        tickDown = isMouseButtonDown(0) or (pressed and not tickDown)
        pressed = false
    end
    return tickDown
end
