-- ZeDUI/tools/qa/perf_motion.lua  (Nov 5 2026, QA): frame rate and lag spikes, standing and walking, with the
-- windows shut and open. Runs the same with ZeD on or with the game's own windows (ZeD off, the ZeDQAShim run), solo
-- or on the multiplayer client (zedqa_run.ps1 -Mp), so the four can be compared.
-- The place: the Valley Station mall. The script reads the rooms around 13950,5760 and picks the straight indoor
-- stretch of 24 squares with the most containers within reach (shelves, counters, racks), then walks it there and back
-- with the game's own walk action (ISWalkToTimedAction), so the World window refreshes its containers as a player's would.
-- Scenes, each after a 4 s settle:
--   hud_still   windows shut, standing (20 s)       win_still   both windows open on Loot, standing (20 s)
--   hud_walk    windows shut, walking (30 s)        win_walk    both windows open, walking (30 s)
-- Two passes. Per scene: frames, fps, the frame-time average, median, 95th and 99th percentile, the worst frame, and
-- the count of spikes over 33 ms (a dropped frame at 30 fps), 50 ms and 100 ms (a hitch a player feels).
-- Prints "ZEDQA pmo RES|<ui>|<session>|<pass>|<scene>|frames|fps|avg|p50|p95|p99|worst|over33|over50|over100".
-- God mode on (put back at the end); zombies are left as the world has them. grep "ZEDQA pmo".
local TAG = "pmo"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local pn = p:getPlayerNum()
local ZED = (ZeD_CharacterWindow ~= nil and ZeD_WorldWindow ~= nil)
local UI = ZED and "zed" or "vanilla"
local SESSION = (isClient and isClient()) and "mp" or "solo"
local was = { god = p:isGodMod() }
pcall(function() p:setGodMod(true) end)

local function moveTo(x, y, z)
    p:setX(x + 0.5); p:setY(y + 0.5); p:setZ(z or 0)
    p:setLastX(x + 0.5); p:setLastY(y + 0.5); p:setLastZ(z or 0)
end

-- windows: open (both, on Loot) or shut
local function windows(open)
    if ZED then
        local cw = ZeD_CharacterWindow.getWindow()
        if open then
            if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
            cw = ZeD_CharacterWindow.getWindow()
            local ww = ZeD_WorldWindow.getWindow()
            for _, w in ipairs({ cw or false, ww or false }) do
                if w then
                    if w.setPinned then w:setPinned(true) end
                    if w.windowShaded then w:setWindowShaded(false) end
                    w._activeTab = "loot"; w._drawerMode = "tab"; w._drawerOpen = true
                end
            end
        else
            local ww = ZeD_WorldWindow.getWindow()
            if cw then cw:setVisible(false) end
            if ww then ww:setVisible(false) end
        end
    else
        local inv, loot = getPlayerInventory(pn), getPlayerLoot(pn)
        for _, w in ipairs({ inv or false, loot or false }) do
            if w then
                w:setVisible(open)
                if open and w.isCollapsed then w.isCollapsed = false; if w.clearMaxDrawHeight then w:clearMaxDrawHeight() end end
                if open then w.pin = true end
            end
        end
    end
end

-- the walking line: the indoor stretch (24 squares, along x or y) with the most containers within one square
local LINE
local function countContainers(sq)
    local n = 0
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o:getContainerCount() and o:getContainerCount() > 0 then n = n + 1 end
    end
    return n
end
local function findLine()
    local cell = getCell()
    local cx, cy = 13950, 5760
    local best, bestN = nil, -1
    local L = 24
    local near = {}
    local function nearN(x, y)
        local k = x * 100000 + y
        if near[k] then return near[k] end
        local n = 0
        for dx = -1, 1 do for dy = -1, 1 do
            local s = cell:getGridSquare(x + dx, y + dy, 0)
            if s then n = n + countContainers(s) end
        end end
        near[k] = n
        return n
    end
    local function walkable(x, y)
        local s = cell:getGridSquare(x, y, 0)
        return s and s:getRoom() and s:isFree(false)
    end
    for oy = -60, 60, 2 do for ox = -60, 60 - L, 4 do
        for _, axis in ipairs({ "x", "y" }) do
            local ok, n = true, 0
            for i = 0, L - 1 do
                local x = (axis == "x") and (cx + ox + i) or (cx + oy)
                local y = (axis == "x") and (cy + oy) or (cy + ox + i)
                if not walkable(x, y) then ok = false; break end
                if i % 2 == 0 then n = n + nearN(x, y) end
            end
            if ok and n > bestN then
                bestN = n
                if axis == "x" then best = { cx + ox, cy + oy, cx + ox + L - 1, cy + oy } else best = { cx + oy, cy + ox, cx + oy, cy + ox + L - 1 } end
            end
        end
    end end
    return best, bestN
end

-- the recorder
local rec = nil
local function onRender()
    if not rec then return end
    local now = getTimestampMs()
    if rec.last then rec.d[#rec.d + 1] = now - rec.last end
    rec.last = now
end
Events.OnRenderTick.Add(onRender)
local function pct(t, q) if #t == 0 then return 0 end; return t[math.max(1, math.min(#t, math.floor(q * #t + 0.5)))] end
local function report(pass, scene, ms)
    local d = rec.d
    rec = nil
    local s, over33, over50, over100 = 0, 0, 0, 0
    for _, v in ipairs(d) do s = s + v; if v > 33 then over33 = over33 + 1 end; if v > 50 then over50 = over50 + 1 end; if v > 100 then over100 = over100 + 1 end end
    table.sort(d)
    local n = #d
    local avg = (n > 0) and (s / n) or 0
    say(string.format("RES|%s|%s|%d|%s|%d|%.1f|%.2f|%d|%d|%d|%d|%d|%d|%d", UI, SESSION, pass, scene, n, n * 1000 / ms, avg,
        pct(d, 0.5), pct(d, 0.95), pct(d, 0.99), d[n] or 0, over33, over50, over100))
end

-- the walk: queue walks end to end while a scene runs
local walking, toB = false, true
local function walkTick()
    if not walking or not LINE then return end
    if ISTimedActionQueue.hasAction and ISTimedActionQueue.hasAction(p) then return end
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    if q and q.queue and #q.queue > 0 then return end
    local x, y = (toB and LINE[3] or LINE[1]), (toB and LINE[4] or LINE[2])
    toB = not toB
    local sq = getCell():getGridSquare(x, y, 0)
    if sq then ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq)) end
end
Events.OnTick.Add(walkTick)

-- the sequence (by real time, so the frame rate does not stretch it)
local SCENES = { { "hud_still", false, false, 20000 }, { "win_still", true, false, 20000 }, { "hud_walk", false, true, 30000 }, { "win_walk", true, true, 30000 } }
local plan = {}
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(500, function() moveTo(13935, 5729, 0); say("ui " .. UI .. ", session " .. SESSION .. "; to the mall") end)
add(8000, function()
    local n
    LINE, n = findLine()
    if not LINE then say("ERR no indoor line found near the mall"); return end
    say(string.format("line %d,%d to %d,%d (%d containers along it)", LINE[1], LINE[2], LINE[3], LINE[4], n))
    moveTo(LINE[1], LINE[2], 0)
end)
add(4000, function() end)
for pass = 1, 2 do
    for _, sc in ipairs(SCENES) do
        add(500, function() walking = false; ISTimedActionQueue.clear(p); moveTo(LINE[1], LINE[2], 0); toB = true; windows(sc[2]) end)
        add(4000, function() walking = sc[3]; end)
        add(1000, function() rec = { d = {} } end)
        add(sc[4], function() report(pass, sc[1], sc[4]) end)
    end
end
add(500, function()
    walking = false
    pcall(function() ISTimedActionQueue.clear(p) end)
    windows(true)
    if SESSION == "solo" then pcall(function() p:setGodMod(was.god) end) end   -- (on the test server the admin stays protected: it lingers in the world after the client quits)
    Events.OnRenderTick.Remove(onRender)
    Events.OnTick.Remove(walkTick)
    say("DONE")
end)

local i, t0 = 1, getTimestampMs()
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs()
    i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
    if not LINE and i > 3 then say("DONE"); Events.OnTick.Remove(drive); Events.OnRenderTick.Remove(onRender); Events.OnTick.Remove(walkTick) end
end
Events.OnTick.Add(drive)
say("start")
