-- ZeDUI/tools/qa/perf_irprof.lua  (Oct 22 2026)
-- Where an item list's frame goes, section by section (the drawing-cost work). Loads a copy
-- of InventoryRenderer.lua with PERF_MARK("<section>") calls at its section boundaries (made
-- by hand into Zomboid/Lua/perf_ir_instr.lua; the module table is kept, so the windows use it),
-- then with both windows on Loot (single column, then multi-column) times each section for
-- 600 frames, and the content panels' whole prerender. After gallery_v3_core / clean / stage.
-- "ZEDQA pir ... DONE".
local TAG = "pir"
local G = GAL
if not (G and G.spot and G.newSeq) then print("ZEDQA " .. TAG .. " ERR run gallery_v3_core/stage first"); print("ZEDQA " .. TAG .. " DONE"); return end
local S = G.newSeq(TAG, 600000)
local say = S.say
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local PM = { on = false, last = 0, acc = {}, n = {}, frames = 0 }
function PERF_MARK(name)
    if not PM.on then return end
    local now = getTimestampMs()
    if name then
        PM.acc[name] = (PM.acc[name] or 0) + (now - PM.last)
        PM.n[name] = (PM.n[name] or 0) + 1
    end
    PM.last = now
end
local function readAll(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local parts = {}
    local l = r:readLine()
    while l do parts[#parts + 1] = l; l = r:readLine() end
    r:close()
    return table.concat(parts, string.char(10))
end
local function frame() if PM.on then PM.frames = PM.frames + 1 end end
local wrapped = {}
local function wrapTotal(tbl, k, label)
    local orig = tbl[k]
    if type(orig) ~= "function" then return end
    wrapped[#wrapped + 1] = { t = tbl, k = k, f = rawget(tbl, k) }
    tbl[k] = function(...)
        if not PM.on then return orig(...) end
        local t0 = getTimestampMs()
        local a, b, c = orig(...)
        PM.acc[label] = (PM.acc[label] or 0) + (getTimestampMs() - t0)
        PM.n[label] = (PM.n[label] or 0) + 1
        return a, b, c
    end
end
local function report(scene)
    local rows = {}
    for k, v in pairs(PM.acc) do rows[#rows + 1] = { k = k, ms = v / math.max(1, PM.frames), n = PM.n[k] / math.max(1, PM.frames) } end
    table.sort(rows, function(a, b) return a.ms > b.ms end)
    say("IRPROF|" .. scene .. "|frames=" .. PM.frames)
    for _, r in ipairs(rows) do say(string.format("IRPROF|%s|%.3f ms/frame|%.2f calls/frame|%s", scene, r.ms, r.n, r.k)) end
    PM.acc, PM.n, PM.frames = {}, {}, 0
end
local Z = {}
function Z.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function Z.mc(on)
    local c, w = CWm.getWindow(), WWm.getWindow()
    if not (c and w) then return false end
    local cl, wl = {}, {}
    for _, k in ipairs({ "back", "webbing" }) do local b = G.bags and G.bags[k]; if b then cl[#cl + 1] = b:getInventory() end end
    if G.trunk then wl[#wl + 1] = G.trunk end
    if G.duffel then wl[#wl + 1] = G.duffel:getInventory() end
    local function colOn(win, inv)
        for i, c2 in ipairs(win._containers or {}) do
            if c2.inventory == inv then for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end; return false end
        end
        return false
    end
    local done = true
    for _, inv in ipairs(cl) do if colOn(c, inv) ~= on then CWm.toggleColumn(inv); done = false end end
    for _, inv in ipairs(wl) do if colOn(w, inv) ~= on then WWm.toggleColumn(inv); done = false end end
    return done
end
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook(); G.stand()
    local src = readAll("perf_ir_instr.lua")
    if not src then S.err("load", "no perf_ir_instr.lua"); return end
    local fn, err = loadstring(src, "InventoryRenderer")
    if not fn then S.err("compile", err); return end
    local ok, e = pcall(fn)
    say("instrumented InventoryRenderer loaded: " .. tostring(ok) .. (ok and "" or (" " .. tostring(e))))
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
end)
S.step(30, function()
    Z.goTab(CWm.getWindow(), CWm.getWindow()._tabStripPanel, "loot"); Z.goTab(WWm.getWindow(), WWm.getWindow()._actionTabStrip, "loot")
    local c, w = CWm.getWindow()._mainContent, WWm.getWindow()._mainContent
    wrapTotal(c, "prerender", "content prerender (char, all)")
    wrapTotal(w, "prerender", "content prerender (world, all)")
    wrapTotal(ZeD.InventoryRenderer, "renderMultiColumnContent", "renderMultiColumnContent (all)")
    wrapTotal(ZeD.InventoryRenderer, "renderItemList", "renderItemList called directly (all)")
    Events.OnRenderTick.Add(frame)
end)
S.poll(5, 300, function() return Z.mc(false) end)
S.step(60, function() PM.on = true end)
S.step(600, function() PM.on = false; report("pair_loot") end)
S.poll(5, 300, function() return Z.mc(true) end)
S.step(60, function() PM.on = true end)
S.step(600, function() PM.on = false; report("pair_multicolumn") end)
S.step(2, function()
    for i = #wrapped, 1, -1 do local w = wrapped[i]; w.t[w.k] = w.f end
    Events.OnRenderTick.Remove(frame)
    Z.mc(false)
end)
S.start()
