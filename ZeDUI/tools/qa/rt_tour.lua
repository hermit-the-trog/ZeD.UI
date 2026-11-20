-- ZeDUI/tools/qa/rt_tour.lua  (Nov 19 2026, QA; tag rt_tour): the release test's checks for the tour (beta 21,
-- FEATURE_MAP row "The tour"; ZeD_Tutorial.lua, the director, Nov 18 2026: "Tutorial but it is an option up front to
-- skip. Balloons guide through each window."). Built on rt_kit.lua (the global RT); run after it. grep
-- "ZEDQA rt_tour". No pictures.
-- What it checks:
--   0. the start by itself: when Zomboid/Lua/ZeD_tutorial.txt said "1" at launch (tour_run.ps1 sets that up), the tour
--      is running within 30 s of the game and on its first step; when the file asked for nothing (the release test),
--      no tour starts by itself;
--   1. every word the tour shows exists (each step's title and text, the controller's words where it has them, Next,
--      Done, Stop tour, the step count);
--   2. the whole tour with the mouse, Next pressed through the keys panel's own mouse handler: all twelve steps, in
--      order; each step draws its balloon (Balloon.draw watched, pass-through) with the step's title, words and
--      "step n of 7", pointing at the step's thing, on screen, not covering that thing; the keys sit on screen and
--      off the balloon; the Character window step opens the Character window, the World window step the World
--      window; the last step's key reads Done; the layer under the balloon lets the pointer through;
--   3. Done: the tour closes (its layer and keys gone from the screen) and the file says "0", so it never comes back;
--   4. a step with nothing on screen is passed over (the watch step's thing made absent for the check);
--   5. Stop tour (the keys panel's mouse handler) stops it at once and writes "0";
--   6. the controller: "pad" in the file reads as the controller tour; its steps show the controller's words where
--      they exist; A goes on, B stops.
-- What it puts back: the tour stopped; the Character and World windows open or shut as found; Balloon.draw and the
-- watch step as they were; the file's first line as found (zedqa_run.ps1 also puts the file back byte for byte).
if not RT then
    print("ZEDQA rt_tour FAIL the kit (rt_kit.lua) is not loaded")
    print("ZEDQA rt_tour VERDICT FAIL 1")
    print("ZEDQA rt_tour DONE")
    return
end
local Q = RT.make("rt_tour")
Q.maxMs = 300000
local TU = ZeD and ZeD.Tutorial
local S = { pn = RT.pn }
local H = {}

-- ===================================================================== helpers
function H.tr(k, ...) local s = nil; pcall(function(...) s = ZeD.tr(k, ...) end, ...); return s end
function H.has(k) local s = H.tr(k); return s ~= nil and s ~= "" and s ~= k end
function H.readWord()
    local l = nil
    pcall(function()
        local r = getFileReader(TU.FILE, false)
        if r then l = r:readLine(); r:close() end
    end)
    return l
end
function H.writeWord(word)
    return pcall(function()
        local w = getFileWriter(TU.FILE, true, false)
        w:write(word)
        w:close()
    end) and true or false
end
function H.R() return TU and TU._state end
function H.inUI(panel)
    if not (panel and panel.javaObject) then return false end
    local found = false
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            local t = nil
            pcall(function() t = e:getTable() end)
            if e == panel.javaObject or t == panel then found = true end
        end
    end)
    return found
end
function H.vis(w) local v = false; pcall(function() v = w ~= nil and w:isReallyVisible() end); return v end
function H.overlap(a, b)
    if not (a and b) then return 0 end
    local w = math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x)
    local h = math.min(a.y + a.h, b.y + b.h) - math.max(a.y, b.y)
    if w <= 0 or h <= 0 then return 0 end
    return w * h
end
function H.onScreen(r)
    local W, Hh = getCore():getScreenWidth(), getCore():getScreenHeight()
    return r and r.x >= -1 and r.y >= -1 and r.x + r.w <= W + 1 and r.y + r.h <= Hh + 1
end
function H.rs(r) if not r then return "none" end; return string.format("%d,%d %dx%d", math.floor(r.x), math.floor(r.y), math.floor(r.w), math.floor(r.h)) end
function H.stop() if TU and TU.running() then pcall(TU.finish) end end
-- the keys panel's own mouse handler, pressed and let go on one of its two keys
function H.press(id)
    local R = H.R()
    if not (R and R.keys) then return false end
    local n, s = R.keys:keyRects()
    local r = (id == "next") and n or s
    local x, y = r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2)
    R.keys:onMouseDown(x, y)
    R.keys:onMouseUp(x, y)
    return true
end

-- ===================================================================== what the balloon draws (pass-through)
function H.watchStart()
    if S.drawWas then return end
    S.drawWas = ZeD.Balloon.draw
    ZeD.Balloon.draw = function(p, c, a, pref, opts)
        local x, y, w, h = S.drawWas(p, c, a, pref, opts)
        if opts and type(opts.key) == "string" and opts.key:sub(1, 9) == "tutorial:" then
            local ax, ay = 0, 0
            pcall(function() ax, ay = p:getAbsoluteX(), p:getAbsoluteY() end)
            S.last = { key = opts.key, c = c, pref = pref, t = getTimestampMs(),
                       a = { x = a.x, y = a.y, w = a.w, h = a.h },
                       box = x and { x = ax + x, y = ay + y, w = w, h = h } or nil }
        end
        return x, y, w, h
    end
end
function H.watchStop() if S.drawWas then ZeD.Balloon.draw = S.drawWas; S.drawWas = nil end end

-- ===================================================================== the checks
if not TU then
    Q.check(false, "ZeD.Tutorial is loaded (ZeD_Tutorial.lua)")
    Q.start()
    return
end

-- 0. the start by itself
Q.step(2, function()
    S.wordAtStart = H.readWord()
    S.charWas = RT.isOpen()
    S.worldWas = H.vis(RT.ww())
    S.asked = TU.wanted()
    Q.say("the file at the start: " .. tostring(S.wordAtStart) .. "; wanted() " .. tostring(S.asked))
end)
Q.waitFor(1, 2400, function()
    if not S.asked then return (getTimestampMs() - Q.t0) > 9000 end   -- (none asked: give it longer than its 6 s wait)
    return TU.running()
end, function(ok)
    if S.asked then
        Q.check(TU.running(), "start by itself: the file said \"" .. tostring(S.wordAtStart) .. "\" at launch, and the tour is running",
            "after " .. math.floor((getTimestampMs() - Q.t0) / 1000) .. " s")
        Q.check(TU.step() >= 1 and TU.step() <= 2, "start by itself: it opens on its first step with something on screen", "step " .. tostring(TU.step()))
        Q.check(H.R().mode == "mouse", "start by itself: \"1\" gives the mouse's tour", tostring(H.R().mode))
        H.stop()
    else
        Q.check(not TU.running(), "no start by itself: the file asked for nothing, and no tour is running 9 s into the game")
    end
end)

-- 1. the words
Q.step(2, function()
    local miss = {}
    for _, st in ipairs(TU.STEPS) do
        for _, part in ipairs({ "_Title", "_Text" }) do
            local k = "UI_ZeD_Tut_" .. st.key .. part
            if not H.has(k) then miss[#miss + 1] = k end
        end
    end
    for _, k in ipairs({ "UI_ZeD_Tut_Next", "UI_ZeD_Tut_Done", "UI_ZeD_Tut_Stop", "UI_ZeD_Tut_StepOf" }) do
        if not H.has(k) then miss[#miss + 1] = k end
    end
    Q.check(#TU.STEPS == 12, "the tour has twelve steps (belt, watch, Character window, its tabs, Equipment, Health, Identity, Skills, card, World window, menu, guide)", #TU.STEPS)
    Q.check(#miss == 0, "words: every step's title and text, Next, Done, Stop tour and the step count are in the game's words", table.concat(miss, ", "))
    local s = H.tr("UI_ZeD_Tut_StepOf", 3, 7) or ""
    Q.check(s:find("3", 1, true) ~= nil and s:find("7", 1, true) ~= nil, "words: the step count fills in its numbers", s)
end)

-- 2. the whole tour with the mouse, from both windows shut (a first game: the tour must open what each step shows;
-- Nov 19 2026, QA, the beta 21 report run found steps 3 to 6 passed over when the windows had been opened and shut)
Q.step(2, function()
    if RT.isOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, RT.pn) end
    pcall(function() if RT.isOpen() then ZeD_CharacterWindow.toggle(RT.pn) end end)
    pcall(function() if H.vis(RT.ww()) then ZeD_WorldWindow.close(RT.pn) end end)
end)
Q.step(10, function()
    Q.check(not H.vis(RT.cw()) and not H.vis(RT.ww()), "mouse: both windows are shut before the tour starts")
    H.watchStart()
    -- (a Messages note staged, so the belt draws its lamp for step 7; cleared at Done)
    local M = ZeD.Messages
    if M and M.count and M.count() == 0 then pcall(function() M.add("ZeDQA rt_tour", "mods", { head = "QA", text = "a note for the tour's Messages step" }) end); S.msgStaged = true end
    H.writeWord("1")
    S.visited = {}
    TU.start(S.pn, "mouse")
    Q.check(TU.running(), "mouse: TU.start runs the tour")
end)
Q.step(4, function()   -- (the game adds a panel to the screen at its next frame)
    Q.check(H.inUI(H.R().layer) and H.inUI(H.R().keys), "mouse: the balloon's layer and the keys are on the screen")
    local L = H.R().layer
    local okd, dn = pcall(L.onMouseDown, L, 5, 5)
    local consume = nil
    pcall(function() consume = L.javaObject:isConsumeMouseEvents() end)
    Q.check(okd and dn == false and consume ~= true, "mouse: the layer under the balloon lets the pointer through",
        "onMouseDown " .. tostring(dn) .. ", consumes " .. tostring(consume))
end)
for i = 1, #((TU and TU.STEPS) or {}) do
    Q.step(12, function()
        local R = H.R()
        local st = TU.STEPS[TU.step()]
        local idx = TU.step()
        -- (Nov 20 2026: the watch step may be passed over, when no watch box is on screen: a tucked belt watch is a
        -- 0 x 0 panel at 0,0, and the balloon must not point there. Then this turn is the next step's.)
        if not TU.running() then return end   -- (the walk ended a turn early: a step was passed over)
        local last = S.lastIdx or 0
        for k = last + 1, idx - 1 do
            local sk = TU.STEPS[k]
            local okW, wr = pcall(sk.target, S.pn)
            wr = okW and wr or nil
            Q.check(sk.key == "Watch" and (wr == nil or wr.w < 8 or wr.h < 8),
                "mouse step " .. k .. " (" .. sk.key .. "): passed over only because it has nothing on screen (the watch alone may be)", H.rs(wr))
        end
        S.visited[#S.visited + 1] = st and st.key or "?"
        local name = "mouse step " .. idx .. " (" .. tostring(st and st.key) .. ")"
        Q.check(idx > last, name .. ": the tour moved on from step " .. last, "on " .. tostring(idx))
        S.lastIdx = idx
        if not st then return end
        local okT, tgt = pcall(st.target, S.pn)
        tgt = okT and tgt or nil
        Q.check(tgt ~= nil and H.onScreen(tgt) and tgt.w >= 8 and tgt.h >= 8, name .. ": its thing is on screen, a real box (8 px or more each way)", H.rs(tgt))
        local L = S.last
        local fresh = L and L.key == "tutorial:" .. idx and getTimestampMs() - L.t < 1000
        Q.check(fresh and L.box ~= nil, name .. ": its balloon is drawn", L and L.key or "no balloon")
        if not (fresh and L.box) then return end
        Q.check(L.c.title == H.tr("UI_ZeD_Tut_" .. st.key .. "_Title"), name .. ": the balloon has the step's title", L.c.title)
        Q.check(L.c.lines[1] == H.tr("UI_ZeD_Tut_" .. st.key .. "_Text"), name .. ": the balloon has the step's words")
        local cnt = L.c.lines[2] and L.c.lines[2].text
        Q.check(cnt == H.tr("UI_ZeD_Tut_StepOf", idx, #TU.STEPS), name .. ": it counts the step", cnt)
        Q.check(tgt ~= nil and math.abs(L.a.x - tgt.x) < 2 and math.abs(L.a.y - tgt.y) < 2, name .. ": the balloon points at its thing",
            "anchor " .. H.rs(L.a) .. ", thing " .. H.rs(tgt))
        Q.check(H.onScreen(L.box), name .. ": the balloon is on screen", H.rs(L.box))
        local ov = H.overlap(L.box, tgt)
        Q.check(ov <= 0.1 * L.box.w * L.box.h, name .. ": the balloon does not cover its thing", "balloon " .. H.rs(L.box) .. ", thing " .. H.rs(tgt))
        local k = { x = R.keys:getX(), y = R.keys:getY(), w = R.keys:getWidth(), h = R.keys:getHeight() }
        Q.check(R.keys:getIsVisible() and H.onScreen(k), name .. ": the keys are shown, on screen", H.rs(k))
        Q.check(H.overlap(k, L.box) == 0, name .. ": the keys sit off the balloon", "keys " .. H.rs(k) .. ", balloon " .. H.rs(L.box))
        Q.check(H.overlap(k, tgt) == 0, name .. ": the keys do not cover its thing", "keys " .. H.rs(k) .. ", thing " .. H.rs(tgt))
        local want = (idx == #TU.STEPS) and H.tr("UI_ZeD_Tut_Done") or H.tr("UI_ZeD_Tut_Next")
        Q.check(R.keys.nextWord == want, name .. ": its key reads " .. tostring(want), R.keys.nextWord)
        if st.key == "Char" then Q.check(H.vis(RT.cw()), name .. ": the Character window is open") end
        -- (Nov 19 2026, the director's review: the tour goes over the Character window's tabs)
        if st.key == "Tabs" then
            local cw = RT.cw()
            local sp = cw and cw._tabStripPanel
            local ok = false
            pcall(function() ok = sp ~= nil and math.abs(L.a.x - sp:getAbsoluteX()) < 2 and math.abs(L.a.y - sp:getAbsoluteY()) < 2 end)
            Q.check(ok, name .. ": it points at the Character window's tab strip", "anchor " .. H.rs(L.a))
        end
        local tabFor = { Equipment = "equip", Health = "health", Identity = "identity", Skills = "skills", Card = "loot" }
        if tabFor[st.key] then
            local cw = RT.cw()
            Q.check(cw ~= nil and cw._activeTab == tabFor[st.key], name .. ": the Character window is on its " .. tabFor[st.key] .. " tab",
                tostring(cw and cw._activeTab))
        end
        if st.key == "Guide" then
            -- (Nov 19 2026, the director's markup: step 7 points at the belt's Messages note, the HUD's "lamp" box;
            -- the whole belt only when no note is drawn. A note is staged before the walk, so the lamp is drawn.)
            local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD(S.pn)
            local lamp = nil
            for _, b in ipairs((hud and hud._boxes) or {}) do if b.kind == "lamp" then lamp = b end end
            local lr = nil
            if hud and lamp then lr = { x = hud:getAbsoluteX() + lamp.x, y = hud:getAbsoluteY() + lamp.y, w = lamp.w, h = lamp.h } end
            Q.check(lr ~= nil and math.abs(L.a.x - lr.x) < 2 and math.abs(L.a.y - lr.y) < 2 and math.abs(L.a.w - lr.w) < 2,
                name .. ": it points at the belt's Messages note (the lamp box)", "anchor " .. H.rs(L.a) .. ", lamp " .. H.rs(lr))
        end
        if st.key == "Card" then
            -- (Nov 19 2026: the card step opens an item's card, ensureCard; the director's "Yes, fix it first")
            local cw = RT.cw()
            local card = cw and cw._itemCard
            local on = false
            pcall(function() on = card ~= nil and card:isReallyVisible() end)
            Q.check(cw ~= nil and cw._drawerMode == "item" and cw._drawerItem ~= nil and on, name .. ": an item's card is open (the drawer in item mode)",
                "drawer " .. tostring(cw and cw._drawerMode) .. ", item " .. tostring(cw and cw._drawerItem) .. ", card shown " .. tostring(on))
        end
        if st.key == "World" then Q.check(H.vis(RT.ww()), name .. ": the World window is open") end
        RT.bounds(Q, name)
        H.press("next")
    end)
end
-- 3. Done
Q.step(6, function()
    if S.msgStaged then pcall(function() ZeD.Messages.clear("ZeDQA rt_tour") end); S.msgStaged = nil end
    if TU.running() and TU.step() == #TU.STEPS then H.press("next") end   -- (a walk one turn short: not expected)
    Q.check(not TU.running(), "Done: the last step's Done ends the tour", "visited " .. table.concat(S.visited, ", "))
    Q.check(#S.visited >= #TU.STEPS - 1 and S.visited[#S.visited] == "Guide", "Done: the walk saw every step to the last (the watch alone may be passed over)",
        #S.visited .. " of " .. #TU.STEPS)
    Q.check(not H.inUI(H.R().layer) and not H.inUI(H.R().keys), "Done: the balloon's layer and the keys are gone")
    Q.check(H.readWord() == "0", "Done: the file says \"0\", so the tour never comes back by itself", H.readWord())
    Q.check(TU.wanted() == nil, "Done: wanted() is nothing after it")
end)

-- 3b. a worn watch in the Full style sits on the belt: its own panel is tucked away (0 x 0 at 0,0). The watch step
-- must then point at a real box or be passed over, never at the screen's corner. (Nov 20 2026, QA: the bug hunt's
-- find; the walk above runs with no watch worn, so it never saw this.)
Q.step(4, function()
    S.ww = {}
    local it = RT.give("Base.WristWatch_Left_DigitalBlack")
    if not it then Q.skip("worn watch: the watch step", "no watch could be given"); return end
    local loc = it:getBodyLocation()
    pcall(function() S.ww.prev = RT.p:getWornItem(loc) end)
    if pcall(function() RT.p:setWornItem(loc, it) end) then S.ww.given, S.ww.loc = it, loc end
    -- (ZeD setup, Watch: on the belt, the default; this run's own pick put back after)
    pcall(function() local o = ZeD.Settings.watchPlaceOption; S.ww.placeWas = o:getValue(); o:setValue(1) end)
    pcall(function() triggerEvent("OnClothingUpdated", RT.p) end)
end)
-- (the watch tucked: on the belt, not popped up. A watch just put on, or one an earlier script popped, shows its
-- full face in the corner for a while, and the first run of this check passed on that.)
Q.step(20, function() if S.ww.given then pcall(ZeD.Watch.togglePop, false) end end)
Q.step(40, function()
    if not S.ww.given then return end
    local inst = ZeD.Watch._instance
    S.ww.tucked = ZeD.Watch.beltMode() and inst ~= nil and inst:getWidth() == 0
    Q.say("worn watch: belt mode " .. tostring(ZeD.Watch.beltMode()) .. ", its own panel " .. tostring(inst and inst:getWidth()) .. " x " .. tostring(inst and inst:getHeight())
        .. (S.ww.tucked and " (tucked on the belt)" or " (in the corner)"))
    S.last = nil
    TU.start(S.pn, "mouse")
end)
Q.step(10, function() if S.ww.given and TU.running() and TU.step() == 1 then H.press("next") end end)
Q.step(20, function()
    if not S.ww.given then return end
    local idx = TU.step()
    local st = TU.STEPS[idx]
    if st and st.key == "Watch" then
        local L = S.last
        local a = L and L.key == "tutorial:" .. idx and L.a or nil
        Q.check(a ~= nil and a.w >= 8 and a.h >= 8 and not (a.x == 0 and a.y == 0),
            "worn watch (" .. (ZeD.Settings.lite() and "Lite" or "Full") .. (S.ww.tucked and ", tucked on the belt" or ", in the corner") .. "): the watch step points at a real box, not the screen's corner", H.rs(a))
    else
        Q.check(TU.running() and idx > 2, "worn watch (" .. (ZeD.Settings.lite() and "Lite" or "Full") .. "): the watch step is passed over when the watch has no box of its own",
            "on step " .. tostring(idx))
    end
    H.stop()
    pcall(function() RT.p:setWornItem(S.ww.loc, S.ww.prev) end)
    pcall(function() triggerEvent("OnClothingUpdated", RT.p) end)
    S.ww.given = nil
    pcall(function() if S.ww.placeWas ~= nil then ZeD.Settings.watchPlaceOption:setValue(S.ww.placeWas) end end)
end)

-- 3c. the tour holds its window open: an unpinned Character window rolls up about two seconds after the pointer
-- leaves it (WindowHalves.lua); a step that is describing the window must keep it open while the player reads.
-- (Nov 20 2026, QA: the bug hunt's find. The walk above presses Next at once, so it never waited long enough.)
Q.step(10, function()
    local md = RT.p:getModData()
    S.pinWas = md.ZeD_WinPinned
    md.ZeD_WinPinned = { char = false, world = false }
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        if w and w.setPinned then pcall(function() w:setPinned(false) end) end
    end
    -- (the pointer far from both windows: the screen's lower right)
    pcall(function() Mouse.setXY(getCore():getScreenWidth() - 40, getCore():getScreenHeight() - 160) end)
    H.writeWord("1")
    TU.start(S.pn, "mouse")
end)
Q.step(10, function() if TU.running() and TU.step() < 3 then H.press("next") end end)
Q.step(10, function() if TU.running() and TU.step() < 3 then H.press("next") end end)
Q.step(10, function()
    S.holdStep = TU.step()
    S.holdKey = TU.STEPS[S.holdStep] and TU.STEPS[S.holdStep].key
    pcall(function() Mouse.setXY(getCore():getScreenWidth() - 40, getCore():getScreenHeight() - 160) end)
end)
Q.waitMs(4500)
Q.step(2, function()
    local cw = RT.cw()
    local shaded = cw ~= nil and cw.windowShaded == true
    local h = cw and cw:getHeight() or 0
    Q.check(S.holdKey == "Char" and TU.running() and TU.step() == S.holdStep, "window held: the tour is still on the Character window step after 4.5 s",
        tostring(S.holdKey) .. ", step " .. tostring(TU.step()))
    Q.check(cw ~= nil and H.vis(cw) and not shaded and h > 120, "window held: an unpinned Character window stays open while its step shows (the pointer away 4.5 s)",
        "shaded " .. tostring(shaded) .. ", height " .. tostring(h))
    H.stop()
    local md = RT.p:getModData()
    md.ZeD_WinPinned = S.pinWas
    local pc, pw = S.pinWas and S.pinWas.char == true, S.pinWas and S.pinWas.world == true
    pcall(function() local w = RT.cw(); if w and w.setPinned then w:setPinned(pc) end; if w and w.windowShaded then w:setWindowShaded(false) end end)
    pcall(function() local w = RT.ww(); if w and w.setPinned then w:setPinned(pw) end; if w and w.windowShaded then w:setWindowShaded(false) end end)
    pcall(function() Mouse.setXY(20, 20) end)
end)

-- 4. a step with nothing on screen is passed over
Q.step(2, function()
    S.watchWas = TU.STEPS[2].target
    TU.STEPS[2].target = function() return nil end
    TU.start(S.pn, "mouse")
end)
Q.step(6, function()
    Q.check(TU.step() == 1, "passed over: the tour opens on the belt", TU.step())
    H.press("next")
end)
Q.step(6, function()
    Q.check(TU.step() == 3, "passed over: Next from the belt goes past the watch (nothing on screen) to the Character window", TU.step())
    TU.STEPS[2].target = S.watchWas
    S.watchWas = nil
end)
-- 5. Stop tour
Q.step(4, function()
    H.writeWord("1")
    H.press("stop")
end)
Q.step(6, function()
    Q.check(not TU.running(), "Stop tour: the keys' Stop tour ends the tour at once")
    Q.check(not H.inUI(H.R().layer) and not H.inUI(H.R().keys), "Stop tour: the layer and the keys are gone")
    Q.check(H.readWord() == "0", "Stop tour: the file says \"0\"", H.readWord())
end)

-- 6. the controller
Q.step(2, function()
    H.writeWord("pad")
    Q.check(TU.wanted() == "pad", "controller: \"pad\" in the file asks for the controller's tour", tostring(TU.wanted()))
    TU.start(S.pn, "pad")
    local jd = JoypadState and JoypadState.players and JoypadState.players[S.pn + 1]
    if jd then Q.check(jd.focus == H.R().keys, "controller: the keys take the controller")
    else Q.skip("controller: the keys take the controller", "no controller on this machine") end
end)
Q.step(6, function()
    local R = H.R()
    Q.check(TU.running() and TU.step() == 1, "controller: the tour runs, on the belt", TU.step())
    local L = S.last
    Q.check(L and L.c.lines[1] == H.tr("UI_ZeD_Tut_Belt_Text"), "controller: a step with no controller words keeps the mouse's")
    R.keys:onJoypadDown(Joypad.AButton)
end)
Q.step(6, function()
    local R = H.R()
    if TU.step() == 2 then R.keys:onJoypadDown(Joypad.AButton) end   -- (the watch, when one is worn)
end)
Q.step(10, function()
    local R = H.R()
    local st = TU.STEPS[TU.step()]
    Q.check(st and st.key == "Char", "controller: A goes on to the Character window", st and st.key)
    local L = S.last
    Q.check(L and L.key == "tutorial:" .. TU.step() and L.c.lines[1] == H.tr("UI_ZeD_Tut_Char_Pad"),
        "controller: the Character window step shows the controller's words")
    R.keys:onJoypadDown(Joypad.BButton)
end)
Q.step(6, function()
    Q.check(not TU.running(), "controller: B stops the tour")
    Q.check(H.readWord() == "0", "controller: the file says \"0\"", H.readWord())
end)

-- put back
Q.mark()
Q.step(2, function()
    H.stop()
    if S.watchWas then TU.STEPS[2].target = S.watchWas; S.watchWas = nil end
    H.watchStop()
    if S.msgStaged then pcall(function() ZeD.Messages.clear("ZeDQA rt_tour") end); S.msgStaged = nil end
    if S.wordAtStart ~= nil then H.writeWord(S.wordAtStart) end
    if S.charWas then RT.pairOpen() else RT.pairShut() end
    if not S.worldWas then
        local w = RT.ww()
        if H.vis(w) and ZeD_WorldWindow and ZeD_WorldWindow.close then pcall(ZeD_WorldWindow.close, S.pn) end
    end
    Q.say("put back: tour stopped, windows " .. (S.charWas and "open" or "shut") .. " as found, the file's word " .. tostring(S.wordAtStart))
end)
Q.start()
