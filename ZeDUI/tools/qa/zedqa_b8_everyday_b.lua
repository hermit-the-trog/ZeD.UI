-- ZeDUI/tools/qa/zedqa_b8_everyday_b.lua  (Nov 7 2026, QA; CHECK_everyday_leftovers_20261107.md B12/B13 notices and B14 paused look)
--   NOTICES: a controller unplugged is filed as a note in Messages and pops a balloon even with the notice pop-ups Off (the
--      default); plugged back in it replaces the note, one per player; the balloons are at most three; the balloon is anchored
--      on the belt's Messages note (tail down to it) / player two's notices are not player one's
--   B14 PAUSED: with the game paused (speed 0) the inventory key's own call (toggleBothPaired) opens the Character window alone,
--      the game's Character Info window stays shut, the veil is up over its tab and list; the World window opened too gets its
--      own veil; unpausing takes both veils away within a couple of frames. The paused part runs on drawn frames (a paused game
--      has no ticks) and ends by unpausing.
-- Puts back: the notes cleared, game speed 1, windows as the prelude left them. Manual: a real plug and unplug (B12, B13 needs a
-- real controller), A and X doing nothing while paused with the pad, the Skills/Health keys, the clicks and wheel under the veil,
-- how the veil and its line look, Deck size, split screen, safe mode.  grep "ZEDQA b8eb"; shots zqa_b8eb_*.png.
local TAG = "b8eb"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
local p = getPlayer()
local pn = p and p:getPlayerNum() or 0
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local M, PJ, PL, MW = ZeD and ZeD.Messages, ZeD and ZeD.PadJoin, ZeD and ZeD.PausedLook, ZeD and ZeD.MessagesWindow
if not (p and CW and WW and M and PJ and PL and MW) then say("ERR ZeD's pieces are not loaded"); say("DONE"); return end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8eb_" .. n .. ".png") end) end
local function cw() return CW.getWindow() end
local function ww() return WW.getWindow() end
local function keepDown(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
local function holdBoth() keepDown(cw()); keepDown(ww()) end

-- the step list: step(waitTicks, fn) runs fn that many ticks after the step before; waitFor(max, cond, fn) runs fn when cond holds (fn(timedOut))
local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end
local function waitFor(max, cond, fn) Q[#Q + 1] = { max = max, cond = cond, fn = fn } end
local cleanups = {}
local function onCleanup(fn) cleanups[#cleanups + 1] = fn end
local ticker
local function finish()
    for i = #cleanups, 1, -1 do local ok, e = pcall(cleanups[i]); if not ok then say("ERR cleanup " .. i .. ": " .. tostring(e)) end end
    cleanups = {}
    say("checks: passes=" .. passes .. " misses=" .. misses)
    say("DONE")
end
local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(ticker); finish(); return end
    qc = qc + 1
    local go, timedOut = false, false
    if s.cond then
        local ok, v = pcall(s.cond)
        if ok and v then go = true elseif qc >= s.max then go, timedOut = true, true end
    else
        go = qc >= s.wait
    end
    if go then
        qi = qi + 1; qc = 0
        local ok, e = pcall(s.fn, timedOut)
        if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(e)) end
    end
end


-- ---- helpers
local wasOpen = { cw = CW.isOpen(), ww = WW.isOpen() }
local padSource = ZeD.tr("UI_ZeD_Pad_Source")
local function padItems()
    local s = M.sources[padSource]
    return s and s.items or {}
end
local function padCount(id)
    local n = 0
    for _, it in ipairs(padItems()) do if it.k == "pad" and (id == nil or it.pad == id) then n = n + 1 end end
    return n
end
local function toastHeads()
    local out = {}
    for _, t in ipairs(M.toasts) do out[#out + 1] = tostring(t.head) end
    return table.concat(out, " | ")
end
local function bothShut()
    if CW.isOpen() then pcall(CW.toggle, pn) end
    if WW.isOpen() then pcall(WW.close) end
end
local seg = { f = 0, done = false, handler = nil }
onCleanup(function()
    if seg.handler then Events.OnRenderTick.Remove(seg.handler); seg.handler = nil end
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    pcall(function() M.clear(padSource) end)
    pcall(function() M.clear("B8 QA notice") end)
    M.toasts = {}
    if wasOpen.cw and not CW.isOpen() then pcall(CW.toggle, pn) end
    if wasOpen.ww and not WW.isOpen() then pcall(WW.open, pn) end
end)

-- ===== NOTICES
step(1, function()
    p:setGodMod(true)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    pcall(function() M.clear(padSource) end)
    M.toasts = {}
    local on = ZeD.Settings and ZeD.Settings.messagesToastOn and ZeD.Settings.messagesToastOn()
    say("NOTE the notice pop-up setting (messagesToastOn) reads: " .. tostring(on))
    if not CW.isOpen() then pcall(CW.toggle, pn) end
    if not WW.isOpen() then pcall(WW.open, pn) end
end)
step(30, function()
    holdBoth()
    PJ.unplugged(0)
    check(padCount("p0") == 1, "B13.5: player one's controller unplugged files one note in Messages")
    local note = padItems()[1]
    check(note ~= nil and note.head == ZeD.tr("UI_ZeD_Pad_Unplugged"), "B13.5: the note's head is Controller unplugged (" .. tostring(note and note.head) .. ")")
    check(#M.toasts >= 1 and M.toasts[#M.toasts].head == ZeD.tr("UI_ZeD_Pad_Unplugged"), "B13.5: a balloon pops (" .. toastHeads() .. ")")
    check(#MW.toastsFor(pn, M.toasts) >= 1, "B13.5: it is player one's balloon")
    check(#MW.toastsFor(1, M.toasts) == 0, "B13.7: and not player two's")
    local nx, ny, tail = MW.noticeAnchor(pn)
    check(nx ~= nil, "B13.5: the balloon has an anchor on the screen (" .. tostring(nx) .. "," .. tostring(ny) .. ")")
    local B = ZeD.Belt
    local hud = B and B._huds and B._huds[pn]
    say("B13.1 diag at the first look: tail " .. tostring(tail) .. "; belt hud " .. tostring(hud ~= nil) .. " drawn " .. tostring(hud and hud._drawn) .. " visible " .. tostring(hud and hud:getIsVisible()) .. " boxes " .. tostring(hud and hud._boxes and #hud._boxes))
    S_tail1 = tail   -- (Nov 8 QA: the belt draws its Messages note a little after the notice; the check is made 20 ticks later)
end)
step(20, function() shot("balloon_unplugged") end)
step(5, function()
    local nx, ny, tail = MW.noticeAnchor(pn)
    say("B13.1 diag, 20 ticks later: anchor " .. tostring(nx) .. "," .. tostring(ny) .. " tail " .. tostring(tail) .. " (at the first look: " .. tostring(S_tail1) .. ")")
    check(tail == true, "B13.1: the tail runs down to the belt's Messages note (tail " .. tostring(tail) .. ", at the first look " .. tostring(S_tail1) .. ")")
end)
step(5, function()
    local n0 = M.count()
    PJ.replugged(0)
    check(padCount("p0") == 1, "B13.6: plugged back in the note is replaced, not added to")
    check(M.count() == n0, "B13.6: the count of notes is the same (" .. n0 .. " then " .. M.count() .. ")")
    local note = padItems()[1]
    check(note ~= nil and note.head == ZeD.tr("UI_ZeD_Pad_PluggedIn"), "B13.6: now it reads Controller plugged in (" .. tostring(note and note.head) .. ")")
end)
step(10, function()
    -- the cap of three balloons
    M.toasts = {}
    for i = 1, 5 do M.pad("b8x" .. i, "B8 balloon " .. i, "A QA balloon, number " .. i .. ".", nil, pn) end
    check(#M.toasts == 3, "B13.8: never more than three balloons (" .. #M.toasts .. ")")
    check(M.toasts[#M.toasts].head == "B8 balloon 5", "B13.8: the newest is the lowest (last in the list)")
end)
step(15, function() shot("balloons_three") end)
step(5, function()
    -- ZeD's own notice: follows the setting; reported, not judged
    M.toasts = {}
    M.notice("B8 QA notice", "A QA notice.")
    say("NOTE B13.8: a ZeD notice made " .. #M.toasts .. " balloon(s) with the setting at " .. tostring(ZeD.Settings.messagesToastOn and ZeD.Settings.messagesToastOn()))
    pcall(function() M.clear(padSource) end)
    pcall(function() M.clear("B8 QA notice") end)
    M.toasts = {}
    check(padCount(nil) == 0, "B13: the QA notes are cleared")
end)

-- ===== B14 paused
local function segStep(f)
    if f == 1 then
        bothShut()
    elseif f == 6 then
        setGameSpeed(0)
    elseif f == 14 then
        check(getGameSpeed() <= 0, "B14: the game is paused")
        CW.toggleBothPaired(pn)
    elseif f == 60 then
        keepDown(cw())
        check(CW.isOpen() and not WW.isOpen(), "B14.1: the inventory key's call opens the Character window alone while paused")
        local okI, ci = pcall(getPlayerInfoPanel, pn)
        check(not (okI and ci and ci:getIsVisible()), "B14.1: the game's Character Info window is not up")
        local g = PL._glass
        check(g ~= nil and g:isVisible(), "B14.2: the veil is up over the tab and the list")
    elseif f == 80 then
        shot("paused_char")
    elseif f == 90 then
        pcall(WW.open, pn)
    elseif f == 150 then
        keepDown(cw()); keepDown(ww())
        check(WW.isOpen(), "B14.4b: the World window opens while paused")
        local g = PL._wglass
        check(g ~= nil and g:isVisible(), "B14.4b: the World window has its own veil")
    elseif f == 170 then
        shot("paused_both")
    elseif f == 180 then
        setGameSpeed(1)
    elseif f == 184 then
        local g, wg = PL._glass, PL._wglass
        check(getGameSpeed() > 0, "B14.3: playing again")
        check(g == nil or not g:isVisible(), "B14.3: the Character window's veil is gone")
        check(wg == nil or not wg:isVisible(), "B14.3: the World window's veil is gone")
        seg.done = true
    end
end
local function segFrame()
    seg.f = seg.f + 1
    if seg.f > 700 and not seg.done then
        if getGameSpeed() <= 0 then setGameSpeed(1) end
        say("ERR the paused part ran out of frames; game speed put back")
        seg.done = true
    end
    if seg.done then Events.OnRenderTick.Remove(segFrame); seg.handler = nil; return end
    local ok, e = pcall(segStep, seg.f)
    if not ok then say("ERR paused step at frame " .. seg.f .. ": " .. tostring(e)) end
end
step(10, function()
    seg.handler = segFrame
    Events.OnRenderTick.Add(segFrame)
end)
waitFor(900, function() return seg.done end, function(t)
    check(not t, "B14: the paused part finished")
end)
step(10, function() end)

ticker = onTick
Events.OnTick.Add(ticker)
say("start")
