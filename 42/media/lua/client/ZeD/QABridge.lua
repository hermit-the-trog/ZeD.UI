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

-- QA PROBE (Nov 5 2026, the hair trim's "Cannot assign field callFrame because a is null"): the game's overload
-- dispatcher (Kahlua's MultiLuaJavaInvoker) releases its call record twice when a Lua call matches none of a Java
-- method's overloads, so that record sits in the pool twice and a later nested call of the same size fails, far from
-- the cause. A pcall hides the mismatch itself. With Lua/zedqa_pcallwatch.txt present (and -debug), every pcall is
-- watched and each such failure prints once: grep "[ZeD.QA] pcw". Dev only: this file is never staged.
do
    local flag = isDebugEnabled and isDebugEnabled() and getFileReader("zedqa_pcallwatch.txt", false)
    if flag then
        flag:close()
        local seen, orig = {}, pcall
        local function after(f, ok, ...)
            if not ok then
                local m = tostring((...))
                if m:find("No implementation found", 1, true) and not seen[m] then
                    seen[m] = true
                    print("[ZeD.QA] pcw " .. m .. " | called " .. tostring(f))
                end
            end
            return ok, ...
        end
        pcall = function(f, ...) return after(f, orig(f, ...)) end
        print("[ZeD.QA] pcw watching every pcall for an overload mismatch")
    end
end

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

-- (punch list 47, Nov 2 2026) the state each QA script starts from, one line before it runs: the game's
-- speed and pause, the character's place and car, the chunk grid, and every vehicle the cell still holds with
-- its distance, whether its physics is on and whether this game simulates it. A long run's leftovers (cars
-- not removed, a seat, a speed) show where they first appear. grep "[ZeD.QA] state".
local function stateLine(n)
    -- every call is looked up before it is made: a method or global the game does not expose is named in the
    -- line ("missing=") instead of failing (a failure caught by pcall still logs a Java exception under -debug,
    -- and the runner counts it against the script; Nov 2 2026, the first state run)
    local missing = {}
    local function call(o, m, ...)
        if o == nil then return nil end
        local f = o[m]
        if type(f) ~= "function" then missing[m] = true; return nil end
        return f(o, ...)
    end
    local function glob(name)
        local f = _G[name]
        if type(f) ~= "function" then missing[name] = true; return nil end
        return f()
    end
    local function num(v) return type(v) == "number" and v or 0 end
    local pl, cell = getPlayer(), getCell()
    if not (pl and cell) then print("[ZeD.QA] state #" .. n .. " no player"); return end
    local px, py = num(call(pl, "getX")), num(call(pl, "getY"))
    local cm = call(cell, "getChunkMap", 0)
    local car = call(pl, "getVehicle")
    local out = "speed=" .. tostring(glob("getGameSpeed")) .. " paused=" .. tostring(glob("isGamePaused"))
        .. " player=" .. math.floor(px) .. "," .. math.floor(py)
        .. " grid=" .. math.floor(num(call(cm, "getWidthInTiles")) / 8)
        .. " inCar=" .. tostring(car and call(car, "getScriptName") or false)
    local vs = call(cell, "getVehicles")
    local cnt = num(call(vs, "size"))
    out = out .. " vehicles=" .. cnt
    for i = 0, math.min(cnt, 12) - 1 do
        local v = call(vs, "get", i)
        if v then
            local name = tostring(call(v, "getScriptName"))
            name = string.gsub(name, "^Base%.", "")
            local dx, dy = num(call(v, "getX")) - px, num(call(v, "getY")) - py
            local phys = call(v, "isPhysicsActive")
            local sim = call(v, "isLocalPhysicSim")
            out = out .. " [" .. name .. " " .. math.floor(math.sqrt(dx * dx + dy * dy) + 0.5) .. " "
                .. (phys == true and "on" or (phys == false and "off" or "?")) .. (sim == false and " remote" or "") .. "]"
        end
    end
    local m = {}
    for k in pairs(missing) do m[#m + 1] = k end
    if #m > 0 then table.sort(m); out = out .. " missing=" .. table.concat(m, ",") end
    print("[ZeD.QA] state #" .. n .. " " .. out)
end

function B.runScript()
    stateLine(B._runs + 1)
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

-- frontEnd: true at the main menu, where OnTick does not run (OnFETick does).
-- In game the bridge polls on OnRenderTick: OnTick stops while the pause menu
-- is open, and the pause menu needs QA too. Each event is hooked once.
function B.install(frontEnd)
    if not B._installed then
        B._installed = true
        -- Prime _lastGo so a stale zedqa.go from a previous session does not
        -- fire on boot; only a NEW write triggers a run.
        B._lastGo = readAll("zedqa.go")
    end
    -- a script error (even inside pcall) would otherwise open the Lua debugger
    -- and halt the game with the bridge in it (the debug toolbar's Break On
    -- Error box; -debug ticks it on every launch)
    if UIManager.setShowLuaDebuggerOnError then UIManager.setShowLuaDebuggerOnError(false) end
    if frontEnd then
        if B._feHooked then return end
        B._feHooked = true
        Events.OnFETick.Add(poll)
    else
        if B._tickHooked then return end
        B._tickHooked = true
        Events.OnRenderTick.Add(poll)
    end
    print("[ZeD.QA] bridge armed (" .. (frontEnd and "main menu" or "in game") .. ", poll every " .. B.POLL_TICKS .. " ticks)")
end

Events.OnGameStart.Add(function()
    if isDebugEnabled and isDebugEnabled() then B.install(false) end
end)

-- The QA save's map is all known (Oct 19 2026, director: "activate all map known
-- on start so we can see what the maps look like"), so the Maps tab shows the
-- whole of Kentucky in QA. Only Saves/Sandbox/ZeD-QA with -debug: a real game
-- keeps its fog.
Events.OnGameStart.Add(function()
    if not (isDebugEnabled and isDebugEnabled()) then return end
    local ok, save = pcall(function() return getWorld():getWorld() end)
    if not (ok and save == "ZeD-QA") then return end
    -- Kentucky (the paper map's picture is 19801 x 16086 squares; the meta grid's
    -- bounds run far past the land)
    local x1, y1, x2, y2 = 0, 0, 20000, 17000
    local done = pcall(function() WorldMapVisited.getInstance():setKnownInSquares(x1, y1, x2, y2) end)
    print("[ZeD.QA] ZeD-QA: the whole map known (" .. x1 .. "," .. y1 .. " to " .. x2 .. "," .. y2 .. ") " .. tostring(done))
end)
Events.OnMainMenuEnter.Add(function()
    if isDebugEnabled and isDebugEnabled() then B.install(true) end
end)

-- QA autoload (Oct 14 2026): a windowed QA launch cannot rely on clicking the
-- main menu's Continue at fixed screen spots, so with -debug and a
-- <Zomboid>/Lua/zedqa.autoload file reading "1", the main menu continues the
-- latest save by itself, once (the flag is cleared before it fires).
local autoTicks = 0
local function autoload()
    autoTicks = autoTicks + 1
    if autoTicks < 90 then return end   -- let the main menu settle
    Events.OnFETick.Remove(autoload)
    local ms = MainScreen and MainScreen.instance
    local item = ms and ms.latestSaveOption
    if not (item and item.internal == "LATESTSAVE") then print("[ZeD.QA] autoload: no Continue on the main menu") return end
    print("[ZeD.QA] autoload: continuing the latest save")
    MainScreen.onMenuItemMouseDownMainMenu(item, 0, 0)
    -- a game update that raises the world version asks first whether to convert the save
    -- (42.22, Oct 27 2026); the QA runner has checked the latest save is the QA save
    local m = ms.checkSavefileModal
    if m then
        print("[ZeD.QA] autoload: the game asks to convert the save for this version; yes")
        if m.pressPrimary then m:pressPrimary() elseif m.yes and m.onClick then m:onClick(m.yes) end
    end
end
Events.OnMainMenuEnter.Add(function()
    if not (isDebugEnabled and isDebugEnabled()) then return end
    local flag = readAll("zedqa.autoload")
    if not flag or flag:sub(1, 1) ~= "1" then return end
    local w = getFileWriter("zedqa.autoload", true, false)
    if w then w:write("0"); w:close() end
    autoTicks = 0
    ZeD.QAAutoload = true   -- (ZeD setup's first-run page stays shut for a QA launch)
    Events.OnFETick.Add(autoload)
end)
