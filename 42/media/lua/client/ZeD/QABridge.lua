-- ZeD-UI/42/media/lua/client/ZeD/QABridge.lua
-- ============================================================================
-- QA BRIDGE (S123) — dev-only. Lets an outside process run Lua inside the
-- game without a restart and without typing in the debug console.
--
--   1. Write   <Zomboid>/Lua/zedqa.lua   (the script to run)
--   2. Write   <Zomboid>/Lua/zedqa.go    (any new text, e.g. a counter)
--   3. Read    <Zomboid>/console.txt     (everything the script print()s)
--
-- Every POLL_TICKS the bridge reads zedqa.go; when its first line differs
-- from the last run, it loads zedqa.lua with loadstring and pcall-runs it.
-- Only active when the game was launched with -debug (isDebugEnabled), so
-- it is inert for players. Safe to leave in Workshop builds; remove if you
-- would rather not ship it.
-- ============================================================================

ZeD = ZeD or {}
ZeD.QABridge = ZeD.QABridge or {}
local B = ZeD.QABridge

B.POLL_TICKS = 30
B._tick      = 0
B._lastGo    = nil
B._runs      = 0

-- Reads a whole file from <Zomboid>/Lua/ (getFileReader is rooted there).
-- Returns nil when the file does not exist.
local function readAll(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local s, l = "", r:readLine()
    while l do
        s = s .. l .. string.char(10)
        l = r:readLine()
    end
    r:close()
    return s
end

function B.runScript()
    local src = readAll("zedqa.lua")
    if not src then print("[ZeD.QA] zedqa.lua missing") return end
    local fn, err = loadstring(src, "zedqa.lua")
    if not fn then print("[ZeD.QA] compile error: " .. tostring(err)) return end
    B._runs = B._runs + 1
    local ok, rerr = pcall(fn)
    print("[ZeD.QA] run #" .. B._runs .. " ok=" .. tostring(ok) .. (ok and "" or (" err=" .. tostring(rerr))))
end

local function poll()
    B._tick = B._tick + 1
    if B._tick < B.POLL_TICKS then return end
    B._tick = 0
    local go = readAll("zedqa.go")
    if not go then return end
    if go ~= B._lastGo then
        B._lastGo = go
        B.runScript()
    end
end

function B.install()
    if B._installed then return end
    B._installed = true
    -- Prime _lastGo so a stale zedqa.go from a previous session does not
    -- fire on boot; only a NEW write triggers a run.
    B._lastGo = readAll("zedqa.go")
    Events.OnTick.Add(poll)
    print("[ZeD.QA] bridge armed (poll every " .. B.POLL_TICKS .. " ticks)")
end

Events.OnGameStart.Add(function()
    if isDebugEnabled and isDebugEnabled() then B.install() end
end)
