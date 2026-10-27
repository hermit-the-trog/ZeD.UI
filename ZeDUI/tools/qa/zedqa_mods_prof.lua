-- ZeDUI/tools/qa/zedqa_mods_prof.lua  (Oct 27 2026)
-- MAIN MENU ONLY (zedqa_menu_mods_run.ps1 -Tag mprof): how long a frame takes with ZeD's Mods window
-- open, with every mod installed on this machine in the list (1300+), and which of its functions cost it.
-- Scenes: the main menu alone; Mods on All, still; All while scrolling; Find with text in it; the
-- Problems tab. Each scene: frame time (OnFETick to OnFETick) and every ZeD_MMMods / ZeD.ModScan
-- function, plus the game's checkMapConflicts and ActiveMods.requiresResetLua, timed inclusively
-- (ms per frame). grep "ZEDQA mprof".
local MM = ZeD.MainMenu
local TAG = "mprof"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local now = getTimestampMs

local W = { acc = {}, n = {}, list = {}, on = false }
local function wrapTable(label, tbl, skip)
    if type(tbl) ~= "table" then return end
    local names = {}
    for k, v in pairs(tbl) do if type(v) == "function" and type(k) == "string" and not (skip and skip[k]) then names[#names + 1] = k end end
    for _, k in ipairs(names) do
        local orig = rawget(tbl, k)
        if type(orig) == "function" then
            local key = label .. "." .. k
            W.list[#W.list + 1] = { t = tbl, k = k, f = orig }
            tbl[k] = function(...)
                if not W.on then return orig(...) end
                local t0 = now()
                local a, b, c, d, e, f, g = orig(...)
                W.acc[key] = (W.acc[key] or 0) + (now() - t0)
                W.n[key] = (W.n[key] or 0) + 1
                return a, b, c, d, e, f, g
            end
        end
    end
end
local function unwrapAll() for i = #W.list, 1, -1 do local w = W.list[i]; w.t[w.k] = w.f end; W.list = {} end

-- frame times
local F = { last = nil, sum = 0, n = 0, max = 0, on = false, over50 = 0 }
local function tick()
    local t = now()
    if F.on and F.last then
        local d = t - F.last
        F.sum, F.n = F.sum + d, F.n + 1
        if d > F.max then F.max = d end
        if d > 50 then F.over50 = F.over50 + 1 end
    end
    F.last = t
end
Events.OnFETick.Add(tick)

local function report(scene)
    say(string.format("FRAME|%s|frames=%d|avg %.1f ms|max %d ms|over 50 ms: %d", scene, F.n, F.sum / math.max(1, F.n), F.max, F.over50))
    local rows = {}
    for k, v in pairs(W.acc) do rows[#rows + 1] = { k = k, ms = v / math.max(1, F.n), n = W.n[k] / math.max(1, F.n) } end
    table.sort(rows, function(a, b) return a.ms > b.ms end)
    for i = 1, math.min(#rows, 25) do local r = rows[i]; say(string.format("FPROF|%s|%.2f ms/frame|%.1f calls/frame|%s", scene, r.ms, r.n, r.k)) end
    W.acc, W.n = {}, {}
    F.sum, F.n, F.max, F.over50 = 0, 0, 0, 0
end

local win
local function measure(scene, frames, each)
    return { scene = scene, frames = frames, each = each }
end
local Q = {}
local function step(fn, wait) Q[#Q + 1] = { fn = fn, wait = wait or 30 } end

step(function()
    local m = ModSelector and ModSelector.instance and ModSelector.instance.model
    say("start")
end, 60)
-- the main menu alone
step(function() F.on = true end, 240)
step(function() F.on = false; report("menu") end, 5)
-- open Mods
step(function()
    MM.openMods()
    win = MM.root and (MM.root.mods or MM.root.modsWin)
    if not win then for k, v in pairs(MM.root or {}) do if type(v) == "table" and v.Type == "ZeD_MMMods" then win = v end end end
    local m = ModSelector and ModSelector.instance and ModSelector.instance.model
    local n = 0
    for _ in ipairs(m and m.sortedMods or {}) do n = n + 1 end
    say("mods window " .. tostring(win ~= nil) .. ", mods listed " .. n)
end, 300)   -- let the conflict scan and Steam poll settle
step(function()
    wrapTable("Mods", ZeD_MMMods)
    wrapTable("MS", ZeD.ModScan)
    wrapTable("UI", MM.ui)
    local m = ModSelector and ModSelector.instance and ModSelector.instance.model
    if m then
        local mt = getmetatable(m)
        local cls = mt and mt.__index
        if type(cls) == "table" then wrapTable("Model", cls, nil) end
    end
    if ActiveMods then wrapTable("ActiveMods", ActiveMods) end
    W.on = true; F.on = true
    say("scan done " .. tostring(ZeD.ModScan.res and ZeD.ModScan.res.done))
end, 300)
step(function() F.on = false; report("mods_all_still") end, 5)
-- scrolling
local scrollTick
step(function()
    F.on = true
    local d = 1
    scrollTick = function() if win then win.scroll = (win.scroll or 0) + d * 20; if win.scroll > 40000 then d = -1 elseif win.scroll <= 0 then d = 1 end end end
    Events.OnFETick.Add(scrollTick)
end, 300)
step(function() Events.OnFETick.Remove(scrollTick); F.on = false; report("mods_all_scrolling") end, 5)
-- Find with text
step(function() if win and win.find then win.find:setText("map") end; win.scroll = 0; F.on = true end, 300)
step(function() F.on = false; report("mods_find_map") end, 5)
-- Problems tab
step(function() if win then win.find:setText(""); win.filter = "problems" end; F.on = true end, 300)
step(function() F.on = false; report("mods_problems") end, 5)
step(function()
    if win then win.filter = "all" end
    W.on = false; unwrapAll()
    pcall(function() win:back() end)
    say("DONE")
end, 5)

local i, wait = 1, 30
local function run()
    if wait > 0 then wait = wait - 1; return end
    local s = Q[i]
    if not s then Events.OnFETick.Remove(run); Events.OnFETick.Remove(tick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. i .. ": " .. tostring(e)) end
    wait = s.wait
    i = i + 1
end
Events.OnFETick.Add(run)
