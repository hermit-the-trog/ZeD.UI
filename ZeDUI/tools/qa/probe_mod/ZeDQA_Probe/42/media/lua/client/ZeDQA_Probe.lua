-- ZeDUI/tools/qa/probe_mod/ZeDQA_Probe/42/media/lua/client/ZeDQA_Probe.lua  (Oct 24 2026)
-- ============================================================================
-- A stand-in for ZeD's QA bridge, for tests that switch ZeD-UI off (does a
-- save made with ZeD load without it?). Copied to Zomboid/mods/ZeDQA_Probe for
-- the test and removed after; never shipped. The same protocol as QABridge.lua:
--   Zomboid/Lua/zedqa.lua (the script), zedqa.go (a new line runs it),
--   zedqa.autoload "1" (the main menu continues the latest save, once).
-- Only with -debug.
-- ============================================================================
if not (isDebugEnabled and isDebugEnabled()) then return end

local POLL_TICKS = 30
local tick, lastGo, runs = 0, nil, 0
local installed, feHooked, tickHooked = false, false, false

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

local function runScript()
    local src = readAll("zedqa.lua")
    if not src then print("[ZeDQA.Probe] zedqa.lua missing") return end
    local fn, err = loadstring(src, "zedqa.lua")
    if not fn then print("[ZeDQA.Probe] compile error: " .. tostring(err)) return end
    runs = runs + 1
    local ok, rerr = pcall(fn)
    print("[ZeDQA.Probe] run #" .. runs .. " ok=" .. tostring(ok) .. (ok and "" or (" err=" .. tostring(rerr))))
end

local function poll()
    tick = tick + 1
    if tick < POLL_TICKS then return end
    tick = 0
    local go = readAll("zedqa.go")
    if go and go ~= lastGo then
        lastGo = go
        runScript()
    end
end

local function install(frontEnd)
    if not installed then
        installed = true
        lastGo = readAll("zedqa.go")   -- (a stale go from an earlier session does not fire)
    end
    if UIManager.setShowLuaDebuggerOnError then UIManager.setShowLuaDebuggerOnError(false) end
    if frontEnd then
        if feHooked then return end
        feHooked = true
        Events.OnFETick.Add(poll)
    else
        if tickHooked then return end
        tickHooked = true
        Events.OnRenderTick.Add(poll)
    end
    print("[ZeDQA.Probe] bridge armed (" .. (frontEnd and "main menu" or "in game") .. ")")
end

local autoTicks = 0
local function autoload()
    autoTicks = autoTicks + 1
    if autoTicks < 90 then return end
    Events.OnFETick.Remove(autoload)
    local ms = MainScreen and MainScreen.instance
    local item = ms and ms.latestSaveOption
    if not (item and item.internal == "LATESTSAVE") then print("[ZeDQA.Probe] autoload: no Continue on the main menu") return end
    print("[ZeDQA.Probe] autoload: continuing the latest save")
    MainScreen.onMenuItemMouseDownMainMenu(item, 0, 0)
end

Events.OnGameStart.Add(function() install(false) end)
Events.OnMainMenuEnter.Add(function()
    install(true)
    local flag = readAll("zedqa.autoload")
    if not flag or flag:sub(1, 1) ~= "1" then return end
    local w = getFileWriter("zedqa.autoload", true, false)
    if w then w:write("0"); w:close() end
    autoTicks = 0
    Events.OnFETick.Add(autoload)
end)
