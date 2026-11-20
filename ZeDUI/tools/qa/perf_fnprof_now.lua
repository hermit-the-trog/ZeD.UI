-- ZeDUI/tools/qa/perf_fnprof_now.lua  (Nov 20 2026, QA; tag pfn): perf_fnprof.lua's function profile on WHATEVER
-- scene is loaded (the ZeD-QA save after zedqa_prelude.lua and zedqa_pin_windows.lua; no gallery staging).
-- Every function of the ZeD module tables below is wrapped with a getTimestampMs timer (inclusive: callees count
-- in their callers too) and a call counter, 600 frames per scene: pair_loot (both windows on Loot), card (an item
-- card open), maps (World on Maps), craft (World on Craft). The 40 costliest per scene as ms per frame and calls per
-- frame; then every wrapper is taken off. The timers themselves cost time: read the numbers as shares, and the call
-- counts as exact. grep "ZEDQA pfn". Ends "ZEDQA pfn DONE".
local TAG = "pfn"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
if not (ZeD and CWm and WWm) then say("ERR ZeD is not loaded"); say("DONE"); return end
local W = { acc = {}, n = {}, list = {}, on = false, frames = 0 }
local MODS = {
    { "IR", ZeD.InventoryRenderer }, { "CT", ZeD.ContainerControls }, { "A", ZeD.Atoms }, { "M", ZeD.Molecules },
    { "TP", ZeD.TabPx }, { "Focus", ZeD.Input and ZeD.Input.Focus }, { "Det", ZeD.Input and ZeD.Input.Detector },
    { "Safe", ZeD.Safe }, { "Text", ZeD.Text }, { "Scale", ZeD.Scale }, { "Belt", ZeD.Belt }, { "Curtain", ZeD.Curtain },
    { "Px", ZeD.Px }, { "ZeD", ZeD }, { "CW", CWm }, { "WW", WWm }, { "Panel", ZeD_Panel }, { "Window", ZeD_Window },
    { "TM", ZeD.TM }, { "Watch", ZeD.Watch }, { "BeltHUD", ZeD_BeltHUD }, { "Lean", ZeD.LeanDraw }, { "Surface", ZeD.Surface },
    { "Balloon", ZeD.Balloon }, { "MapsTab", ZeD.MapsTab }, { "MapsSurvey", ZeD.MapsSurvey }, { "Stations", ZeD.Stations },
    { "ItemCard", ZeD_ItemCard }, { "Overlay", ZeD_WindowOverlay }, { "Settings", ZeD.Settings }, { "Grid", ZeD.GridLayout },
    { "Craft", ZeD.CraftingCore }, { "Messages", ZeD.Messages }, { "Moodles", ZeD.Moodles }, { "ActionBar", ZeD.ActionBar },
    { "T", ZeD.T },
}
local SKIP = { getWindow = true, isOpen = true }
local function wrapAll()
    local seen = {}
    for _, m in ipairs(MODS) do
        local label, tbl = m[1], m[2]
        if type(tbl) == "table" and not seen[tbl] then
            seen[tbl] = true
            local names = {}
            for k, v in pairs(tbl) do if type(v) == "function" and type(k) == "string" and not SKIP[k] then names[#names + 1] = k end end
            for _, k in ipairs(names) do
                local orig = rawget(tbl, k)
                if type(orig) == "function" then
                    local key = label .. "." .. k
                    W.list[#W.list + 1] = { t = tbl, k = k, f = orig }
                    tbl[k] = function(...)
                        if not W.on then return orig(...) end
                        local t0 = getTimestampMs()
                        local a, b, c, d, e, f2, g, h = orig(...)
                        W.acc[key] = (W.acc[key] or 0) + (getTimestampMs() - t0)
                        W.n[key] = (W.n[key] or 0) + 1
                        return a, b, c, d, e, f2, g, h
                    end
                end
            end
        end
    end
    say("wrapped " .. #W.list .. " functions")
end
local function unwrapAll()
    for i = #W.list, 1, -1 do local w = W.list[i]; w.t[w.k] = w.f end
    W.list = {}
end
local function report(scene)
    local rows = {}
    for k, v in pairs(W.n) do rows[#rows + 1] = { k = k, ms = (W.acc[k] or 0) / math.max(1, W.frames), n = v / math.max(1, W.frames) } end
    table.sort(rows, function(a, b) return a.ms > b.ms end)
    say("FPROF|" .. scene .. "|frames=" .. W.frames)
    for i = 1, math.min(#rows, 40) do local r = rows[i]; say(string.format("FPROF|%s|%.3f ms/frame|%.1f calls/frame|%s", scene, r.ms, r.n, r.k)) end
    table.sort(rows, function(a, b) return a.n > b.n end)
    for i = 1, math.min(#rows, 25) do local r = rows[i]; say(string.format("FCALLS|%s|%.1f calls/frame|%.3f ms/frame|%s", scene, r.n, r.ms, r.k)) end
    W.acc, W.n, W.frames = {}, {}, 0
end
local function goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function charTab(t) local w = CWm.getWindow(); return w and goTab(w, w._tabStripPanel, t) end
local function worldTab(t) local w = WWm.getWindow(); return w and goTab(w, w._actionTabStrip, t) end
-- the first item row of the Character list clicked (its card opens), as rt_lite.lua clicks a row
local function openCard()
    local w = CWm.getWindow()
    local c = w and w._mainContent
    for _, z in ipairs((c and c._hitZones) or {}) do
        if type(z.id) == "userdata" or (type(z.id) == "table" and z.id.getFullType) then
            c._zedLastClick = nil
            c:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
            c:onMouseUp(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
            return true
        end
    end
    return false
end
local steps, qi, wait = {}, 1, nil
local function step(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function scene(name, setup, teardown)
    step(10, setup)
    step(90, function() W.on = true end)
    step(600, function() W.on = false; report(name); if teardown then teardown() end end)
end
step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
    pcall(function() Mouse.setXY(20, 20) end)
end)
step(30, function() charTab("loot"); worldTab("loot"); wrapAll() end)
scene("pair_loot", function() charTab("loot"); worldTab("loot") end)
scene("card", function() say("card opened " .. tostring(openCard())) end, function() openCard() end)
scene("maps", function() worldTab("maps") end)
scene("craft", function() worldTab("craft") end)
step(10, function() unwrapAll(); worldTab("loot"); charTab("loot") end)
step(30, function() say("DONE") end)
local function tick()
    if W.on then W.frames = W.frames + 1 end
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
