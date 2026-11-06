-- ZeDUI/tools/qa/perf_spikes.lua  (Nov 5 2026, QA; the lag spikes in MP_CHECK_20261105.md): what runs inside a slow frame.
-- Needs the dev-only mod ZeDPerfProbe before ZeD_UI in the QA save's list (perf_spikes_mods.txt, zedqa_mods_run.ps1).
-- Every event handler (the probe) and every Lua update / prerender / render of the UI tree is timed per frame. A frame
-- over 25 ms prints "SPK" with what took 2 ms or more inside it; "lua" far under the frame means the time went outside Lua
-- (the game's own work or the Java garbage collector). Scenes, 60 s each: shut, open (both windows on Loot), shut again.
-- Everything is put back. grep "ZEDQA pks".
local function say(s) print("ZEDQA pks " .. tostring(s)) end
if not ZPROBE then say("ERR the probe is not loaded"); say("DONE"); return end
local p = getPlayer()
pcall(function() p:setGodMod(true) end)
local CW = ZeD_CharacterWindow
local els, undo, seen, count = {}, {}, {}, 0
local fr = {}
local function nameOf(t) return tostring(rawget(t, "Type") or t.Type or t.title or "?") end
local function wrap(t, depth)
    if type(t) ~= "table" or seen[t] or count > 900 or depth > 7 then return end
    seen[t] = true; count = count + 1
    local nm = nameOf(t)
    for _, f in ipairs({ "update", "prerender", "render" }) do
        local had = rawget(t, f)
        local orig = t[f]
        if type(orig) == "function" then
            local key = nm .. ":" .. f
            t[f] = function(self, ...)
                local s = getTimestampMs()
                local a, b = orig(self, ...)
                fr[key] = (fr[key] or 0) + (getTimestampMs() - s)
                return a, b
            end
            undo[#undo + 1] = function() t[f] = had end
        end
    end
    local kids = rawget(t, "children")
    if type(kids) == "table" then for _, c in pairs(kids) do wrap(c, depth + 1) end end
end
local function wrapAll()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        local t
        pcall(function() t = e:getTable() end)
        if type(t) == "table" then wrap(t, 0) end
    end
end
local scene, last, n, sp, worst, tGap = nil, nil, 0, 0, 0, nil
local spikes = {}
local function clear()
    for k in pairs(fr) do fr[k] = nil end
    for r in pairs(ZPROBE.hot) do r.fr = 0; ZPROBE.hot[r] = nil end
    for i = 1, ZPROBE.n do ZPROBE.h[i].fr = 0 end
end
local function onFrame()
    local now = getTimestampMs()
    if scene and last then
        local dt = now - last
        n = n + 1
        if dt > worst then worst = dt end
        if dt >= 25 then
            sp = sp + 1
            local rows, lua = {}, 0
            for k, v in pairs(fr) do if v >= 1 then rows[#rows + 1] = { k, v }; lua = lua + v end end
            for r in pairs(ZPROBE.hot) do rows[#rows + 1] = { r.ev .. " " .. r.desc, r.fr }; lua = lua + r.fr end
            table.sort(rows, function(a, b) return a[2] > b[2] end)
            local s = {}
            for i = 1, math.min(6, #rows) do s[#s + 1] = rows[i][1] .. "=" .. rows[i][2] end
            say(string.format("SPK %s t=%d frame=%d lua=%d | %s", scene, now % 1000000, dt, lua, table.concat(s, ", ")))
        end
    end
    last = now
    clear()
end
Events.OnRenderTick.Add(onFrame)
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function begin(name) return function()
    wrapAll(); ZPROBE.on = true; scene, n, sp, worst = name, 0, 0, 0
    say("scene " .. name .. ", " .. count .. " elements timed")
end end
local function finish() local nm, c = scene, n; scene = nil; say(string.format("RES %s frames=%d spikes=%d worst=%d", nm, c, sp, worst)) end
add(500, function() if CW.isOpen() then CW.toggleBothPaired(0) end end)
add(4000, begin("shut"))
add(60000, finish)
add(300, function() CW.toggleBothPaired(0) end)
add(4000, begin("open"))
add(60000, finish)
add(300, function() CW.toggleBothPaired(0) end)
add(4000, begin("shut2"))
add(60000, finish)
add(100, function()
    ZPROBE.on = false
    for k = #undo, 1, -1 do pcall(undo[k]) end
    Events.OnRenderTick.Remove(onFrame)
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
