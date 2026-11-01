-- ZeDUI/tools/qa/gallery_nov1_t3.lua  (Nov 1 2026, QA)
-- The Workshop gallery retake (workshop/gallery/REVIEW_20261101.md, "Retakes" 9), zedqa_gallery_t3.lua's pictures
-- for pages 43 and 44, with its screenshot names (zqa_g3_*), so the gallery's shots.json keeps working:
--   page 43  zqa_g3_wheel_use_smoke   Character > Use, Smoke pointed and unavailable: everything the Use wheel would
--                                     smoke is set aside first, so its reason line ("Nothing to smoke") shows
--   page 44  zqa_g3_setup_chords      ZeD setup on the pause screen, the Quick actions rows in view, LB + X marked
--            zqa_g3_setup_list        that row's action list dropped from its own box (the action in use marked)
--            zqa_g3_setup_putback     ZeD setup scrolled so the Put things back row sits mid-list, marked; the help
--                                     band explains it
-- Runs anywhere in game (the QA save's home is fine): after the story's teardown in gallery_nov1_manifest.txt. The
-- controller's mode is held for the run (the pad's pictures and marks), the look is GAL_LOOK (Dark + Orange).
-- Each setup picture logs "rect <name> options x y w h list y h" and the marked row's place in the list.
-- Puts back: the things set aside (to the bag they came from), the pause screen shut, the input mode, the windows.
-- "ZEDQA n1t ..." ending "ZEDQA n1t DONE".
local p = getPlayer()
if not (p and ZeD and ZeD.DpadWheels and ZeD.Wheel and ZeD.QuickWheel and ZeD.MainMenu) then
    print("ZEDQA n1t ERR no player, or ZeD is not loaded"); print("ZEDQA n1t DONE"); return
end
local T3 = { pn = p:getPlayerNum(), D = ZeD.DpadWheels, W = ZeD.Wheel, Det = ZeD.Input.Detector, MM = ZeD.MainMenu, Q = {},
             stash = {}, nOk = 0, nErr = 0 }
T3.look = { base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize }
function T3.say(s) print("ZEDQA n1t " .. tostring(s)) end
function T3.shot(n)
    local ok, e = pcall(function() getCore():TakeFullScreenshot("zqa_g3_" .. n .. ".png") end)
    if ok then T3.nOk = T3.nOk + 1; T3.say("shot zqa_g3_" .. n .. " ok") else T3.nErr = T3.nErr + 1; T3.say("ERR shot " .. n .. ": " .. tostring(e)) end
end
function T3.err(s) T3.nErr = T3.nErr + 1; T3.say("ERR " .. tostring(s)) end
function T3.step(n, fn) T3.Q[#T3.Q + 1] = { n = n, fn = fn } end
local say, step = T3.say, T3.step

function T3.closeWheel()
    local D, W, pn = T3.D, T3.W, T3.pn
    local st = D.state[pn]
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    D.state[pn] = nil
    local m = getPlayerRadialMenu(pn)
    if m and m:isReallyVisible() then pcall(m.undisplay, m) end
    W.qaPoint = nil
end
function T3.noWindows()
    pcall(ZeD.Input.Focus.releaseFocus)
    if ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(T3.pn) end
    pcall(ZeD.Input.Focus.releaseFocus)
    pcall(function() Mouse.setXY(20, 20) end)
end
-- everything the Use wheel's Smoke would list, set aside (ZeD.QuickWheel's own "smoke" group), kept to put back
function T3.stashSmokes()
    local Qw = ZeD.QuickWheel
    local g = Qw.group and Qw.group("smoke")
    if not g then return 0 end
    for _ = 1, 40 do
        local ks = Qw.collect(p, g) or {}
        if #ks == 0 then break end
        for _, k in ipairs(ks) do
            local it = k.item
            local c = it and it:getContainer()
            if c then
                c:Remove(it)
                T3.stash[#T3.stash + 1] = { item = it, container = c }
            end
        end
    end
    pcall(function() ISInventoryPage.dirtyUI() end)
    return #T3.stash
end
function T3.unstash()
    for i = #T3.stash, 1, -1 do
        local s = T3.stash[i]
        pcall(function() s.container:AddItem(s.item) end)
    end
    local n = #T3.stash
    T3.stash = {}
    pcall(function() ISInventoryPage.dirtyUI() end)
    return n
end
-- ZeD setup's rows: the one pred picks, its place in the list (the drawn heights, r._h), its controller id
function T3.find(pred)
    local o = T3.opts
    local rows = o:rowsFor(o:pages()[o.pageIdx or 1])
    local idx, y = 0, 0
    for i, r in ipairs(rows) do
        if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then idx = idx + 1 end
        if pred(r) then return { r = r, i = i, idx = idx, y = y, h = r._h or ZeD.T.px(30) } end
        y = y + (r._h or ZeD.T.px(30))
    end
    return nil
end
function T3.mark(f)
    local o = T3.opts
    o.focusId = "orow:" .. f.idx
    o._cellRow = f.r   -- (the help band reads this row, as for a row the controller is on)
end
function T3.rect(name, f)
    local o = T3.opts
    local L = o._list or {}
    say(string.format("rect %s options %d %d %d %d list %d %d | row %s idx %d at %d (scroll %d)", name,
        math.floor(o:getAbsoluteX()), math.floor(o:getAbsoluteY()), math.floor(o:getWidth()), math.floor(o:getHeight()),
        math.floor((L.y or 0) + o:getAbsoluteY()), math.floor(L.h or 0), tostring(f and (f.r.labelKey or f.r.chord or f.r.label)),
        f and f.idx or -1, f and math.floor(f.y) or -1, math.floor(o.scroll or 0)))
end

-- ---- the look, the pad's mode, no windows -------------------------------------------------------
step(20, function()
    T3.Det.setLockedMode("gamepad")
    local b, a = (GAL_LOOK and GAL_LOOK[1]) or "dark", (GAL_LOOK and GAL_LOOK[2]) or "orange"
    T3.D.Z.theme(b, a, T3.look.size)
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    say("set: " .. tostring(ZeD.PadGlyphs and ZeD.PadGlyphs.set()) .. ", look " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent))
end)
step(30, T3.noWindows)
step(10, function()
    local n = T3.stashSmokes()
    local left = #(T3.D.H.quick(p, "smoke") or {})
    say("smoke: " .. n .. " things set aside | the Use wheel's Smoke now lists " .. left)
end)

-- ---- page 43: Character > Use, Smoke pointed, unavailable ----------------------------------------
step(10, function()
    local D, pn = T3.D, T3.pn
    ISDPadWheels.onDisplayLeft({ player = pn, id = nil })
    local st = D.state[pn]
    local useName = ZeD.tr("UI_ZeD_Wheel_Use")
    local e = nil
    for _, x in ipairs(st and st.path and st.path[1] and st.path[1].entries or {}) do
        if x.name == useName then e = x end
    end
    e = e or (st and st.path[1].entries[8])
    if e then D.enter(pn, e) else T3.err("wheel_use_smoke: no Use slice on the Character wheel") end
    T3.W.qaPoint = 1
end)
step(30, function()
    local st = T3.D.state[T3.pn]
    local m = st and st.menu
    local s1 = m and m.slices and m.slices[1]
    say("wheel: " .. tostring(s1 and s1.text) .. " | " .. ZeD.tr("UI_ZeD_Wheel_NothingToSmoke"))
    T3.shot("wheel_use_smoke")
end)
step(5, function() T3.closeWheel() end)
step(10, function() say("smoke: " .. T3.unstash() .. " things put back") end)

-- ---- page 44: ZeD setup on the pause screen ----------------------------------------------------
step(20, function()
    -- (the menus' own controller look: the marked row and the pad's prompts; MM.gamepad reads this, not the detector)
    T3.padWas = T3.MM.forceGamepad
    T3.MM.forceGamepad = true
    T3.D.H.openSetup(p, T3.pn)
end)
step(40, function()
    T3.opts = T3.MM.pauseOpts
    if not T3.opts then T3.err("no ZeD setup") end
    pcall(function() Mouse.setXY(20, 20) end)
end)
-- (the rows' heights are known once the list has drawn: wait for them)
step(10, function() end)
step(2, function()
    if not T3.opts then return end
    local first = T3.find(function(r) return r.kind == "chord" end)
    local f = T3.find(function(r) return r.kind == "chord" and r.chord == "LB+X" end)
    T3.chord = f
    if not (first and f) then T3.err("setup_chords: no Quick actions rows"); return end
    T3.opts.scroll = math.max(0, first.y - ZeD.T.px(40))
    T3.mark(f)
end)
step(30, function()
    if not (T3.opts and T3.chord) then return end
    local Qc = ZeD.QuickChords
    say("setup: LB + X runs " .. tostring(Qc and Qc.get and Qc.get("LB+X")))
    T3.shot("setup_chords")
    T3.rect("zqa_g3_setup_chords", T3.chord)
end)
-- the row's own box, as a click on it (its list drops from the box); the row's activate when the box is not drawn
step(5, function()
    local o, f = T3.opts, T3.chord
    if not (o and f) then return end
    local want = tostring(o.kind) .. ":r" .. f.i .. ":box"
    local hit = nil
    for _, h in ipairs(o._hits or {}) do if h.id == want then hit = h end end
    if hit and hit.fn then hit.fn() ; say("setup: the LB + X box clicked")
    else o:activateRow(f.r); say("setup: no box hit (" .. want .. "): the row activated") end
end)
step(30, function()
    if not (T3.opts and T3.chord) then return end
    local pop = T3.MM.popup
    local marked = nil
    for _, it in ipairs(pop and pop.items or {}) do
        if type(it) == "table" and it.text and tostring(it.text):find(string.char(171), 1, true) then marked = it.text end
    end
    say("setup list: open " .. tostring(T3.MM.ctx and T3.MM.ctx.open) .. " | marked " .. tostring(marked))
    T3.shot("setup_list")
    T3.rect("zqa_g3_setup_list", T3.chord)
end)
step(5, function()
    local MM = T3.MM
    if MM.ctx then MM.ctx.open = nil end
    MM.popup = nil
    if not T3.opts then return end
    local f = T3.find(function(r) return r.labelKey == "UI_ZeD_Settings_PutBack" end)
    T3.putback = f
    if not f then T3.err("setup_putback: no Put things back row"); return end
    local vh = (T3.opts._list and T3.opts._list.h) or ZeD.T.px(400)
    T3.opts.scroll = math.max(0, f.y - math.floor((vh - f.h) / 2))
    T3.mark(f)
end)
step(30, function()
    if not (T3.opts and T3.putback) then return end
    T3.shot("setup_putback")
    T3.rect("zqa_g3_setup_putback", T3.putback)
end)
step(5, function()
    local o = T3.opts
    T3.MM.forceGamepad = T3.padWas
    if o then o._cellRow = nil; o.focusId = nil; o.scroll = 0; pcall(function() o:finish() end) end
    if MainScreen and MainScreen.instance and MainScreen.instance:isVisible() then ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
end)

-- ---- put back -------------------------------------------------------------------------------------
step(20, function()
    if #T3.stash > 0 then say("smoke: " .. T3.unstash() .. " things put back") end
    T3.MM.forceGamepad = T3.padWas
    pcall(ZeD.Input.Focus.releaseFocus)
    T3.D.Z.theme(T3.look.base, T3.look.accent, T3.look.size)
    T3.Det.setLockedMode(nil)
    say("look back to " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent))
    say(string.format("end: %d shots ok, %d errors", T3.nOk, T3.nErr))
end)
step(10, function() say("DONE") end)

-- (stepped on each drawn frame: the pause screen stops the game's tick)
T3.qi, T3.wait = 1, nil
function T3.tick()
    local s = T3.Q[T3.qi]
    if not s then Events.OnPreUIDraw.Remove(T3.tick); return end
    T3.wait = (T3.wait or s.n) - 1
    if T3.wait > 0 then return end
    T3.wait = nil
    T3.qi = T3.qi + 1
    local ok, err = pcall(s.fn)
    if not ok then T3.err("step " .. (T3.qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(T3.tick)
say("start (" .. #T3.Q .. " steps)")
