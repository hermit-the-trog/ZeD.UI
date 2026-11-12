-- ZeDUI/tools/qa/zedqa_wsp_unpause.lua  (Nov 11 2026, QA): zedqa_window_saved_pos.lua opens the survival guide's window, and the game pauses under it; the run's OnTick steps then never run (the first try timed out
-- at step 1, speed 0). This keeps the game running (a render-tick hook: speed 1 whenever it reads 0) for the rest of the launch. grep "ZEDQA wspu".
local function say(s) print("ZEDQA wspu " .. s) end
WSPU_N = 0
if not WSPU_HOOK then
    WSPU_HOOK = function()
        if getGameSpeed() == 0 then WSPU_N = WSPU_N + 1; setGameSpeed(1) end
    end
    Events.OnRenderTick.Add(WSPU_HOOK)
end
local n = 0
local function later() n = n + 1; if n > 20 then Events.OnTick.Remove(later); say("DONE (hook on)") end end
Events.OnTick.Add(later)
say("start")
