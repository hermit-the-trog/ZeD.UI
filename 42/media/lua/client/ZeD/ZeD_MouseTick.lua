-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MouseTick.lua
-- ============================================================================
-- THE LEFT BUTTON FOR CODE THAT POLLS IT IN update() (Oct 30 2026)
--
-- The engine runs the UI's update() only every 100 ms (42.22: UIManager.update
-- gates the elements' updates on doTick) and draws every frame. A poller that
-- reads isMouseButtonDown(0) in update() and acts on "was down, now up" missed a
-- click whose press and release both fell between two updates (the director's
-- mouse pass). ZeD.MouseTick.down() is what such a poller should read: the button
-- as it is, except that a press seen on any frame since the last update counts as
-- down for one update, so the next one sees the release. Every caller in the same
-- update gets the same answer. Code that polls on every frame drawn reads
-- isMouseButtonDown(0) itself.
-- ============================================================================

ZeD = ZeD or {}
ZeD.MouseTick = ZeD.MouseTick or {}
local M = ZeD.MouseTick

local prev, pressed = false, false
local tickAt, tickDown = -1000, false

-- every frame drawn: note a press
function M.sample()
    local d = isMouseButtonDown(0)
    if d and not prev then pressed = true end
    prev = d
end
Events.OnPreUIDraw.Add(M.sample)

function M.down()
    local now = getTimestampMs()
    if now - tickAt > 30 then   -- a new update (100 ms apart); the callers in one update share the answer
        tickAt = now
        tickDown = isMouseButtonDown(0) or (pressed and not tickDown)
        pressed = false
    end
    return tickDown
end
