-- ZeDUI/tools/qa/perf_dashprof.lua  (Oct 22 2026)
-- Where the dashboard's frame goes (the drawing-cost work). After gallery_v3_core / clean /
-- stage, with ZeD on: in the station wagon at night, engine and lights on, wraps the dash's
-- prerender and the module functions it calls (the plate, the parts, the radio's reading,
-- the derived values, the pixel text and needles, the focus ring) with getTimestampMs timers
-- for 900 frames and prints ms per frame (inclusive). Unwrapped after; out of the car.
-- "ZEDQA pdp ... DONE".
local TAG = "pdp"
local G = GAL
if not (G and G.spot and G.car and G.newSeq) then print("ZEDQA " .. TAG .. " ERR run gallery_v3_core/stage first"); print("ZEDQA " .. TAG .. " DONE"); return end
local S = G.newSeq(TAG, 600000)
local say = S.say
local p = G.p
local W = { acc = {}, n = {}, list = {}, on = false, frames = 0 }
local function wrapFn(tbl, name, label)
    local orig = tbl and tbl[name]
    if type(orig) ~= "function" then return end
    W.list[#W.list + 1] = { t = tbl, k = name, f = rawget(tbl, name) }
    tbl[name] = function(...)
        if not W.on then return orig(...) end
        local t0 = getTimestampMs()
        local a, b, c = orig(...)
        W.acc[label] = (W.acc[label] or 0) + (getTimestampMs() - t0)
        W.n[label] = (W.n[label] or 0) + 1
        return a, b, c
    end
end
local function frame() if W.on then W.frames = W.frames + 1 end end
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook(); G.stand()
    pcall(function() G.car:enter(0, p) end)
    if p:getVehicle() then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
end)
S.step(30, function() pcall(function() G.car:setKeysInIgnition(true) end) end)
S.poll(10, 1500, function()
    local run = false
    pcall(function() run = G.car:isEngineRunning() end)
    if run or not p:getVehicle() then return true end
    if S.tick % 150 == 0 then pcall(function() ISVehicleMenu.onStartEngine(p) end) end
    return false
end)
S.step(60, function()
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if d and d._st and not d._st.lights then d:_fire("lights", false) end
    G.night()
end)
S.step(200, function()
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if not d then say("ERR no dash"); return end
    wrapFn(d, "prerender", "dash prerender (all)")
    wrapFn(ZeD.Plate, "draw", "Plate.draw (plate + parts)")
    wrapFn(ZeD.Plate, "drawParts", "Plate.drawParts")
    wrapFn(ZeD.RadioOps, "read", "RadioOps.read")
    wrapFn(ZeD.Dashboard, "derive", "Dashboard.derive")
    wrapFn(ZeD.Px, "text", "Px.text")
    wrapFn(ZeD.Px, "needle", "Px.needle")
    wrapFn(ZeD.Px, "pointer", "Px.pointer")
    wrapFn(ZeD.Px, "rects", "Px.rects")
    wrapFn(ZeD.Px, "digits", "Px.digits")
    wrapFn(ZeD.Px, "image", "Px.image")
    wrapFn(ZeD.Px, "imageTint", "Px.imageTint")
    local F = ZeD.Input and ZeD.Input.Focus
    wrapFn(F, "setRingZoneElements", "Focus.setRingZoneElements")
    wrapFn(F, "setZoneFocusable", "Focus.setZoneFocusable")
    Events.OnRenderTick.Add(frame)
    W.on = true
end)
S.step(900, function()
    W.on = false
    Events.OnRenderTick.Remove(frame)
    local rows = {}
    for k, v in pairs(W.acc) do rows[#rows + 1] = { k = k, ms = v / math.max(1, W.frames), n = W.n[k] / math.max(1, W.frames) } end
    table.sort(rows, function(a, b) return a.ms > b.ms end)
    say("DPROF|frames=" .. W.frames)
    for _, r in ipairs(rows) do say(string.format("DPROF|%.3f ms/frame|%.2f calls/frame|%s", r.ms, r.n, r.k)) end
    for i = #W.list, 1, -1 do local w = W.list[i]; w.t[w.k] = w.f end
end)
S.step(2, function()
    G.dayAgain()
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
end)
S.step(40, function() G.stand(); G.openTrunk(G.car); G.faceFront() end)
S.start()
