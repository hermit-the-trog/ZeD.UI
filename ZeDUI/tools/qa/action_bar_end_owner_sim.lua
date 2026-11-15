-- ZeDUI/tools/qa/action_bar_end_owner_sim.lua  (Nov 15 2026, Build; punch list 247, the stale action bubble)
-- The director: after smoking, walking about 20 tiles and hopping a short fence, the bubble said "Done smoking a
-- cigarette", and again climbing through a window. The last state drawn stayed kept, and any later action's end
-- (an instant one that never drew) flashed it as DONE. With no game running, AB.state and AB.onEnded (cut out of
-- the real ZeD_ActionBar.lua) run on stub actions and a stub queue. It checks:
--   the action that drew ends with DONE; a later action that never drew ends with nothing (no stale flash);
--   a quick next step of the same job still ends the job with DONE; the fence hop and the window climb are on
--   the no-bubble list.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/action_bar_end_owner_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]action_bar_end_owner_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_ActionBar.lua", "rb"); local src = f:read("*a"):gsub("\r\n", "\n"); f:close()
local qa = src:find("local QUIET = ", 1, true)
local qb = src:find("\nAB.NO_BUBBLE = NO_BUBBLE\n", qa, true)
local sa = src:find("AB._jobs = AB._jobs or {}", 1, true)
local sb0 = src:find("function AB.onEnded(action, kind)", 1, true)
local sb = sb0 and src:find("\nend\n", sb0, true)
check("the pieces are found", qa and qb and sa and sb)
if not (qa and qb and sa and sb) then print("action_bar_end_owner_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end

local clock = 1000
getTimestampMs = function() return clock end
instanceof = function(o, cls) return type(o) == "table" and o._player == true and cls == "IsoPlayer" end
local chr = { _player = true, isLocalPlayer = function() return true end, getPlayerNum = function() return 0 end }
ISTimedActionQueue = { queues = {} }
local q = { queue = {} }
ISTimedActionQueue.queues[chr] = q

local AB = { label = function(a) return a.Type end, itemName = function() return "" end }
local chunk = "local AB = ...\n" .. src:sub(qa, qb + #"\nAB.NO_BUBBLE = NO_BUBBLE\n") .. src:sub(sa, sb + 4)
local fn = assert(loadstring(chunk))
fn(AB)

local function act(typ, maxTime)
    return { Type = typ, maxTime = maxTime or 100, character = chr, action = {}, _zedBar = not AB.NO_BUBBLE[typ],
             getJobDelta = function() return 0.5 end, isStarted = function() return true end }
end
-- one frame of the layer: what prerender keeps
local function frame()
    local st = AB.state(chr, 0)
    if st then AB._last[0] = st; AB._ends[0] = nil end
    return st
end

-- smoking: drawn, then done
local smoke = act("ISEatFoodAction", 400)
q.queue = { smoke }
frame()
q.queue = {}
AB.onEnded(smoke, "done")
check("the smoke that drew ends with DONE", AB._ends[0] and AB._ends[0].st.phase == "done")
AB._ends[0] = nil
frame()   -- nothing on: the queue is empty

-- much later: an instant action that never drew ends
clock = clock + 60000
local instant = act("ISOpenCloseWindow", 0)
q.queue = { instant }
frame()
q.queue = {}
AB.onEnded(instant, "done")
check("an instant action's end brings back no stale DONE", AB._ends[0] == nil, AB._ends[0] and AB._ends[0].st.label)

-- a hop: no bubble while it runs or when it ends, even if it were given a time
local hop = act("ISClimbOverFence", 50)
q.queue = { hop }
check("the fence hop draws nothing", frame() == nil)
q.queue = {}
AB.onEnded(hop, "done")
check("the fence hop ends with nothing", AB._ends[0] == nil)
check("the window climb is on the no-bubble list", AB.NO_BUBBLE.ISClimbThroughWindow == true)

-- a job of two of a kind, the second too quick to be drawn: the job still ends with DONE
local a1, a2 = act("ISInventoryTransferAction", 50), act("ISInventoryTransferAction", 50)
q.queue = { a1, a2 }
frame()
q.queue = { a2 }
AB.onEnded(a1, "done")
check("the first of a job is not the job's end", AB._ends[0] == nil)
q.queue = {}
AB.onEnded(a2, "done")
check("the job's quick last step ends it with DONE", AB._ends[0] and AB._ends[0].st.phase == "done")

-- stopped by hand: the drawn action greys out
AB._ends[0] = nil
local read = act("ISReadABook", 1000)
q.queue = { read }
frame()
q.queue = {}
AB.onEnded(read, "stopped")
check("a drawn action stopped shows STOPPED", AB._ends[0] and AB._ends[0].st.phase == "stopped")

print("action_bar_end_owner_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
