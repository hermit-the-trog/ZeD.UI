-- ZeDUI/tools/qa/perf_fnprof.lua  (Oct 22 2026)
-- Function profile of the window pair (the drawing-cost work). After gallery_v3_core / clean /
-- stage, with ZeD on: both windows open on Loot (single column, then multi-column); every
-- function in the ZeD module tables below is wrapped with a getTimestampMs timer (inclusive:
-- a function's callees count in it too) for 600 frames per scene, and the costliest are
-- printed as ms per frame. Unwrapped after. "ZEDQA pfp ... DONE".
local TAG = "pfp"
local G = GAL
if not (G and G.spot and G.newSeq) then print("ZEDQA " .. TAG .. " ERR run gallery_v3_core/stage first"); print("ZEDQA " .. TAG .. " DONE"); return end
local S = G.newSeq(TAG, 600000)
local say = S.say
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local W = { acc = {}, n = {}, list = {}, on = false, frames = 0 }
local MODS = {
    { "IR", ZeD.InventoryRenderer }, { "CT", ZeD.ContainerControls }, { "A", ZeD.Atoms }, { "M", ZeD.Molecules },
    { "TP", ZeD.TabPx }, { "Focus", ZeD.Input and ZeD.Input.Focus }, { "Det", ZeD.Input and ZeD.Input.Detector },
    { "Safe", ZeD.Safe }, { "Text", ZeD.Text }, { "Scale", ZeD.Scale }, { "Belt", ZeD.Belt }, { "Curtain", ZeD.Curtain },
    { "SkillsTab", ZeD.SkillsTab }, { "RadioTab", ZeD.RadioTab }, { "MechanicsTab", ZeD.MechanicsTab }, { "Px", ZeD.Px },
    { "ZeD", ZeD }, { "CW", CWm }, { "WW", WWm }, { "Panel", ZeD_Panel }, { "Window", ZeD_Window }, { "TM", ZeD.TM },
    { "Watch", ZeD.Watch }, { "WatchMini", ZeD.WatchMini }, { "BeltHUD", ZeD_BeltHUD }, { "Lean", nil },
}
local SKIP = { getWindow = true, isOpen = true }
local function wrapAll()
    for _, m in ipairs(MODS) do
        local label, tbl = m[1], m[2]
        if type(tbl) == "table" then
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
                        local a, b, c, d = orig(...)
                        W.acc[key] = (W.acc[key] or 0) + (getTimestampMs() - t0)
                        W.n[key] = (W.n[key] or 0) + 1
                        return a, b, c, d
                    end
                end
            end
        end
    end
end
local function unwrapAll()
    for i = #W.list, 1, -1 do local w = W.list[i]; w.t[w.k] = w.f end
    W.list = {}
end
local function frame() if W.on then W.frames = W.frames + 1 end end
local function report(scene)
    local rows = {}
    for k, v in pairs(W.acc) do rows[#rows + 1] = { k = k, ms = v / math.max(1, W.frames), n = W.n[k] / math.max(1, W.frames) } end
    table.sort(rows, function(a, b) return a.ms > b.ms end)
    say("FPROF|" .. scene .. "|frames=" .. W.frames)
    for i = 1, math.min(#rows, 45) do local r = rows[i]; say(string.format("FPROF|%s|%.3f ms/frame|%.1f calls/frame|%s", scene, r.ms, r.n, r.k)) end
    W.acc, W.n, W.frames = {}, {}, 0
end
local Z = {}
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end
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
    local c, w = Z.CW(), Z.WW()
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
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
end)
S.step(30, function() Z.goTab(Z.CW(), Z.CW()._tabStripPanel, "loot"); Z.goTab(Z.WW(), Z.WW()._actionTabStrip, "loot") end)
S.poll(5, 300, function() return Z.mc(false) end)
S.step(10, function() CWm.toggleBothPaired(0) end)
S.step(60, function() wrapAll(); Events.OnRenderTick.Add(frame); W.on = true end)
S.step(600, function() W.on = false; report("hud") end)
S.step(2, function() if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end end)
S.step(60, function() Z.goTab(Z.CW(), Z.CW()._tabStripPanel, "loot"); Z.goTab(Z.WW(), Z.WW()._actionTabStrip, "loot"); W.on = true end)
S.step(600, function() W.on = false; report("pair_loot") end)
S.poll(5, 300, function() return Z.mc(true) end)
S.step(60, function() W.on = true end)
S.step(600, function() W.on = false; report("pair_multicolumn") end)
S.step(2, function() unwrapAll(); Events.OnRenderTick.Remove(frame); Z.mc(false) end)
S.start()
