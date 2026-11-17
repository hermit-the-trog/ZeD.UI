-- ZeDUI/tools/qa/zedqa_b19_old_a.lua  (Nov 16 2026, QA): punch list items built in beta 14 but never checked in game,
-- run on the real code in the running game. Same rig as zedqa_b19_pad.lua: no controller is plugged into the QA PC,
-- so a stand-in pad record goes into JoypadState.players for the length of one call only (withPad) and comes out
-- before the next frame. Pad buttons the per-frame poll reads go through Focus.qaButton; where a press and its
-- release must happen inside one stand-in call, the poll is run by hand there (Focus.tick). The input mode is locked
-- to the controller only for 214, 196 and 188, and unlocked again.
--   197  the World wheel has a Search slice; its first choice turns search mode on, then (rebuilt) off again.
--   220  the icon strip on an item stays up while the player stands still; once the player is more than 2 tiles from
--        where it opened (its open point is moved, not the character) it closes itself; B on a fresh strip closes it.
--        (The half where a pad menu left with no pad takes it back: not run, the strip opens in a draw, outside the
--        stand-in's one call.)
--   231  Rename from the strip on an item: the option gives the box the pad and it remembers the Character window;
--        B closes it and the pad goes back to the window; the item keeps its name. (The box taking the pad back on
--        its next ticks after the strip's close: not run, needs a pad across ticks.)
--   221  the keyboard opened on a field (pad on the Character window), its opener naming the keyboard as prevFocus (as
--        the desk note did): WOW typed reaches the field; B puts the keyboard away, the text stays, the pad goes back to
--        the window, not to the hidden keyboard; a B on the hidden keyboard sends the pad back and leaves the text.
--        (The desk note itself is at the main menu: not run.)
--   214  the Character and World windows: the window box is a pad stop (padElements), Up from a stop below reaches it
--        (found by previewing Up from each stop; the walk from the list is logged), its focus mark
--        draws, A opens the window menu (press, then the poll's release), B closes it and the pad stays on the window.
--   196  the Safe mode question (a ZeD_Prompt) holding the pad, a frame after it opens: Focus.held is true, a Y tap (through the poll) leaves the pad on the
--        question and the windows as they were; B answers No, the pad goes back to the Character window, safe mode off.
--   187  Start with the Character window holding the pad: the window hands Start to the game's pause (the real
--        onPauseButtonPressed on a stand-in controller); the pause menu comes up and takes the pad.
--   188  with the pause menu up: a ZeD window cannot claim the pad, the D-pad opens no wheel, a Y tap (per-frame poll)
--        does nothing; Y held while the menu closes is no new press after it.
--   194  not run: needs the character to die (the death screen).
--   213  not run: the main menu desk is outside a save (the pause window has no desk).
-- Pictures: Screenshots/zqa_b19a_*.png. Puts back: safe mode, the right-click style, search mode, the input-mode lock,
-- game speed, the pause menu closed, menus and boxes closed, the apple taken back, the pair open or shut as found,
-- the pad record out, the held buttons let go, focus released. grep "ZEDQA b19a".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA b19a " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b19a_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local Focus = ZeD.Input and ZeD.Input.Focus
local Det = ZeD.Input and ZeD.Input.Detector
local CW, WWn = ZeD_CharacterWindow, ZeD_WorldWindow
local S = {}
local function desc(o) if o == nil then return "nothing" end return tostring(o.Type or o._zedLabel or o) end

-- the stand-in pad (and a stand-in controller for Start): in JoypadState only for the call
local fake = { player = pn, focus = nil }
local ctl = { joypad = fake }
function ctl.onPauseButtonPressed(self)
    S.pauseRan = (S.pauseRan or 0) + 1
    return JoypadControllerData.onPauseButtonPressed(self)
end
fake.controller = ctl
local function withPad(fn, ...)
    local real = JoypadState.players[pn + 1]
    if real then say("note: a real pad is bound; the stand-in is not used") return fn(...) end
    JoypadState.players[pn + 1] = fake
    local ok, r = pcall(fn, ...)
    JoypadState.players[pn + 1] = nil
    pcall(setPlayerButtonsActive, pn, true)
    pcall(setJoypadIgnoreAim, pn, false)
    if not ok then say("ERR " .. tostring(r)) end
    return r
end
local function cwin() return CW.getWindow and CW.getWindow(pn) end
local function wwin() return WWn and WWn.getWindow and WWn.getWindow(pn) end
local function pairOpen()
    if not (CW.isOpen and CW.isOpen(pn)) then pcall(CW.toggleBothPaired, pn) end
end
local function vis(o) local ok, v = pcall(function() return o:isReallyVisible() end); return ok and v == true end
local function zedMenus()
    local out = {}
    pcall(function()
        local ui = UIManager.getUI()
        for i = ui:size() - 1, 0, -1 do
            local t = ui:get(i):getTable()
            if t and (t.Type == "ZeD_ContextMenu" or t.Type == "ZeD_ContextList") and t._ctx and t._ctx.open then out[#out + 1] = t end
        end
    end)
    return out
end
local function closeMenus()
    for _, t in ipairs(zedMenus()) do pcall(function() t:close() end) end
    local v = S.vctx
    if v then
        pcall(function() if v.hideAndChildren then v:hideAndChildren() else v:setVisible(false) end end)
        S.vctx = nil
    end
end
local function lockPad()
    if Det and Det.setLockedMode then Det.setLockedMode(Det.MODE_GAMEPAD or "gamepad") end
end
local function unlockPad()
    if not (Det and Det.setLockedMode) then return end
    Det.setLockedMode(nil)
    pcall(function()
        local md = p:getModData().ZeD_Gamepad
        local k = md and md.inputModeLock
        if k == "kbm" or k == "gamepad" then Det.setLockedMode(k) end
    end)
end
local function itemMenu()
    local x, y = math.floor(getCore():getScreenWidth() * 0.45), math.floor(getCore():getScreenHeight() * 0.45)
    S.vctx = ISInventoryPaneContextMenu.createMenu(pn, true, { S.apple }, x, y)
end
S.findDef = function(list, name, depth)
    for _, d in ipairs(list or {}) do
        if d.name == name then return d end
        if depth < 4 and d.children then
            local r = S.findDef(d.children, name, depth + 1)
            if r then return r end
        end
    end
    return nil
end

-- ===================================================================== start
step(20, function()
    say("start: pad bound " .. tostring(JoypadState.players[pn + 1] ~= nil) .. ", mode " .. tostring(Det and Det.getMode and Det.getMode()))
    S.pairWas = CW.isOpen and CW.isOpen(pn) or false
    S.safeWas = ZeD.Settings.safeModeOption:getValue()
    S.ctxWas = ZeD.Settings.contextStyleOption and ZeD.Settings.contextStyleOption:getValue() or nil
    S.speedWas = getGameSpeed and getGameSpeed() or 1
    local mm = ISSearchManager and ISSearchManager.getManager(p)
    S.searchWas = mm and mm.isSearchMode or false
    S.apple = p:getInventory():AddItem("Base.Apple")
    S.appleName = S.apple and S.apple:getName() or nil
    pairOpen()
end)

-- ===================================================================== 197: search mode from the D-pad wheels
step(20, function()
    local D = ZeD.DpadWheels
    if not (D and D.B and D.B.world and D.Wd and D.Wd.search) then say("not run: 197 (the wheels' builders are not loaded)"); return end
    local slice
    for _, e in ipairs(D.B.world(p, pn) or {}) do if e.sub == D.Wd.search then slice = e end end
    check(slice ~= nil, "197: the World wheel has a Search slice (" .. tostring(slice and slice.name) .. ")")
    local list = D.Wd.search(p, pn) or {}
    local first = list[1]
    local mm = ISSearchManager and ISSearchManager.getManager(p)
    if not (first and mm) then say("not run: 197 toggles (no search manager for the player)"); return end
    S.searchKey0 = mm.isSearchMode and "UI_disable_search_mode" or "UI_enable_search_mode"
    check(first.name == getText(S.searchKey0), "197: its first choice reads " .. tostring(first.name))
    S.searchBefore = mm.isSearchMode and true or false
    first.run(p, pn)
end)
step(15, function()
    local mm = ISSearchManager and ISSearchManager.getManager(p)
    if not mm or S.searchBefore == nil then return end
    check((mm.isSearchMode and true or false) ~= S.searchBefore, "197: the choice toggled search mode (now " .. tostring(mm.isSearchMode) .. ")")
    shot("197_search_toggled")
    local list = ZeD.DpadWheels.Wd.search(p, pn) or {}
    local first = list[1]
    local want = mm.isSearchMode and "UI_disable_search_mode" or "UI_enable_search_mode"
    check(first and first.name == getText(want), "197: rebuilt, the choice offers the way back (" .. tostring(first and first.name) .. ")")
    if first then first.run(p, pn) end
end)
step(15, function()
    local mm = ISSearchManager and ISSearchManager.getManager(p)
    if not mm or S.searchBefore == nil then return end
    check((mm.isSearchMode and true or false) == S.searchBefore, "197: the second choice put search mode back (" .. tostring(mm.isSearchMode) .. ")")
end)

-- ===================================================================== 220: the strip closes when the player walks off
step(10, function()
    if not S.apple then say("not run: 220 / 231 (no apple to open a menu on)"); return end
    if ZeD.Settings.contextStyleOption then ZeD.Settings.contextStyleOption:setValue(1) end
    closeMenus()
    itemMenu()
end)
step(15, function()
    local m = zedMenus()[1]
    S.m220 = (m and m.Type == "ZeD_ContextMenu") and m or nil
    if not S.m220 then say("not run: 220 (no icon strip came up: " .. desc(m) .. ")"); return end
    check(S.m220._openAt ~= nil, "220: the strip notes where the player stood when it opened")
    shot("220_strip_open")
end)
step(30, function()
    local m = S.m220; if not (m and m._openAt) then S.m220 = nil; return end
    check(m._ctx.open == true, "220: standing still, the strip stays up")
    -- the player "walks" 3 tiles: the open point moves instead of the character (no walking into walls)
    m._openAt.x = m._openAt.x + 3
end)
step(10, function()
    local m = S.m220; if not m then return end
    check(m._ctx.open == false and not vis(m), "220: more than 2 tiles from where it opened, the strip closed itself")
    closeMenus()
    itemMenu()
end)
step(15, function()
    local m = zedMenus()[1]
    if not (m and m.Type == "ZeD_ContextMenu") then say("not run: 220 B (no second strip)"); return end
    withPad(function() m:onJoypadDown(Joypad.BButton) end)
    check(m._ctx.open == false, "220: B on the strip closes it")
    say("not run: 220 a pad strip with no pad focus taking the pad back (the strip opens in a draw, outside the stand-in's one call)")
    closeMenus()
end)

-- ===================================================================== 231: Rename from the strip takes the pad
step(10, function()
    if not S.apple then return end
    pairOpen()
    closeMenus()
    itemMenu()
end)
step(15, function()
    local m = zedMenus()[1]
    if not (m and m.Type == "ZeD_ContextMenu") then say("not run: 231 (no icon strip came up: " .. desc(m) .. ")"); return end
    local name = getText("ContextMenu_RenameBag")
    local def = S.findDef(m._ctx.actions, name, 0)
    local cw = cwin()
    withPad(function() Focus.claimFocus(cw); fake.focus = cw end)
    if not def or not def.onFire then
        -- (the strip groups some choices: the game's own option then)
        local o = m.vanillaMenu and m.vanillaMenu.getOptionFromName and m.vanillaMenu:getOptionFromName(name)
        if not o then say("not run: 231 (no Rename on the apple's menu)"); closeMenus(); return end
        def = { onFire = function() o.onSelect(o.target, o.param1, o.param2, o.param3, o.param4) end }
        say("231: Rename fired through the game's option (not found in the strip's tree)")
    end
    -- as the strip's A does: the menu holds the pad, the option fires, the menu closes
    withPad(function()
        fake.focus = m
        def.onFire(m._ctx.target)
        S.boxAtFire = fake.focus
        m:close()
    end)
    -- (round 2: the box is the one the option opened. The strip's close in the same call hands the pad back to the
    -- window, because a box added this very call is not yet shown (Focus.menuClosed); the box takes it back on its
    -- next ticks (ItemMenu.lua's hold), which needs a pad present across ticks: not run here.)
    S.rbox = S.boxAtFire
    say("231: after the strip closed in the same call the pad was on " .. desc(fake.focus))
    check(S.rbox ~= nil and S.rbox ~= m and S.rbox ~= cw, "231: the Rename option gives the box the pad (" .. desc(S.rbox) .. ")")
    check(S.rbox and S.rbox.prevFocus == cw, "231: it remembers the Character window (" .. desc(S.rbox and S.rbox.prevFocus) .. ")")
    say("not run: 231 the box taking the pad back on its next ticks after the strip closes (needs a pad across ticks)")
    if S.rbox == cw then S.rbox = nil end
    closeMenus()
end)
step(10, function()
    local b = S.rbox; if not b then return end
    check(vis(b), "231: a few frames on, the box is still up")
    shot("231_rename_box")
    withPad(function() fake.focus = b; b:onJoypadDown(Joypad.BButton, fake) end)
    check(not vis(b), "231: B closes the box")
    check(fake.focus == cwin(), "231: the pad goes back to the Character window (" .. desc(fake.focus) .. ")")
    check(S.apple:getName() == S.appleName, "231: the item keeps its name (" .. tostring(S.apple:getName()) .. ")")
end)

-- ===================================================================== 221: the keyboard gives the pad back
step(10, function()
    if ZeD.Settings.contextStyleOption and S.ctxWas then ZeD.Settings.contextStyleOption:setValue(S.ctxWas) end
    if not (OnScreenKeyboard and OnScreenKeyboard.Show and ZeD.Keyboard) then say("not run: 221 (no keyboard)"); return end
    local box = ISTextEntryBox:new("", 200, 200, 300, 24)
    box:initialise(); box:instantiate(); box:addToUIManager()
    S.tbox = box
    local cw = cwin()
    withPad(function()
        Focus.claimFocus(cw); fake.focus = cw
        S.kb = OnScreenKeyboard.Show(pn, box, fake)
        local k = S.kb
        S.kbTook = (k ~= nil and fake.focus == k)
        -- the desk note's opener: prevFocus = jd.focus, which is the keyboard itself now
        if k then k.prevFocus = fake.focus end
    end)
    local k = S.kb
    check(S.kbTook, "221: the keyboard takes the pad as it opens (" .. desc(fake.focus) .. ")")
    check(k and k._zedPrev == cw, "221: it remembers what held the pad before (" .. desc(k and k._zedPrev) .. ")")
    if k then k:typeChar("W"); k:typeChar("O"); k:typeChar("W") end
end)
step(15, function()
    local k = S.kb; if not k then return end
    shot("221_keyboard_wow")
    check(S.tbox:getText() == "WOW", "221: what was typed reached the field (" .. tostring(S.tbox:getText()) .. ")")
    withPad(function() fake.focus = k; k.joyfocus = fake; k:onJoypadDown(Joypad.BButton, fake) end)
    check(not k:isVisible(), "221: B puts the keyboard away")
    check(fake.focus == cwin(), "221: the pad goes back to the Character window, not the hidden keyboard (" .. desc(fake.focus) .. ")")
    check(S.tbox:getText() == "WOW", "221: B keeps the text (" .. tostring(S.tbox:getText()) .. ")")
end)
step(5, function()
    local k = S.kb; if not k then return end
    withPad(function() fake.focus = k; k:onJoypadDown(Joypad.BButton, fake) end)
    check(fake.focus == cwin(), "221: a press on the hidden keyboard sends the pad back (" .. desc(fake.focus) .. ")")
    check(S.tbox:getText() == "WOW", "221: and leaves the field's text alone (" .. tostring(S.tbox:getText()) .. ")")
    pcall(function() S.tbox:unfocus() end)
    pcall(function() S.tbox:setVisible(false); S.tbox:removeFromUIManager() end)
    pcall(function() p:setBlockMovement(false) end)
    say("not run: 221 the desk's Pasties note itself (the main menu desk, outside a save)")
end)

-- ===================================================================== 214: the window box is a pad stop
local function boxTest(tag, getw)
    step(10, function()
        lockPad()
        local w = getw()
        if not w then say("not run: 214 " .. tag .. " (no window)"); return end
        S.bw = w
        local found = false
        for _, e in ipairs(ZeD.Halves.padElements(w)) do if e.id == "windowbox" then found = true end end
        check(found, "214 " .. tag .. ": the window box is one of the title bar's pad stops")
        withPad(function() Focus.claimFocus(w); fake.focus = w end)
        local function at() local e = Focus.getFocusedElement(w); return e and e.id end
        withPad(function()
            for _ = 1, 40 do if at() == "windowbox" then break end; w:onJoypadDirUp(fake) end
        end)
        -- (round 2: Up from wherever the window's focus starts is not the promise; a walk up the inventory side stops
        -- on its column heading. The promise is that some stop below the title bar has the box as its Up.)
        local flat = Focus.flatElements(w) or {}
        local box = w:windowBoxRect()
        say("214 " .. tag .. ": the Up walk from the list ended on " .. tostring(at()) .. "; box at " .. box.x .. "," .. box.y .. " " .. box.w .. "x" .. box.h)
        for _, t in ipairs(flat) do
            if t.id == at() then say("214 " .. tag .. ":   that stop is " .. tostring(t.zone) .. " at " .. t.x .. "," .. t.y .. " " .. t.w .. "x" .. t.h) end
        end
        if at() ~= "windowbox" then
            local from = nil
            local zi0 = w._focusIdx
            local z0 = w._focusRing and w._focusRing[zi0 or 1]
            local ei0 = z0 and z0.focusedElementIdx
            -- (each stop tried in place, no onFocus: the focus is set by hand and the move only previewed)
            for _, t in ipairs(flat) do
                local z = w._focusRing and w._focusRing[t.zi]
                if not from and z and t.id ~= "windowbox" and type(t.zone) == "string" and t.zone:sub(-9) ~= "TitlePins" then
                    local keep = z.focusedElementIdx
                    w._focusIdx = t.zi; z.focusedElementIdx = t.ei
                    local r = Focus.previewMove(w, "up")
                    if r and r.id == "windowbox" then from = t end
                    z.focusedElementIdx = keep
                end
            end
            w._focusIdx = zi0
            if z0 then z0.focusedElementIdx = ei0 end
            if from then
                Focus.focusWhere(w, from.zone, function(e) return e.id == from.id end)
                say("214 " .. tag .. ": Up from " .. tostring(from.id) .. " (" .. tostring(from.zone) .. " at " .. from.x .. "," .. from.y .. ") leads to the box")
                withPad(function() w:onJoypadDirUp(fake) end)
            end
        end
        check(at() == "windowbox", "214 " .. tag .. ": Up from a stop below reaches the window box (on " .. tostring(at()) .. ")")
        if at() ~= "windowbox" then Focus.focusWhere(w, w._halves and w._halves.zone, function(e) return e.id == "windowbox" end) end
        -- watch the title bar's draw for the box's focus mark
        S.marked = false
        S.markOrig = ZeD.Focus.mark
        ZeD.Focus.mark = function(pp, x, y, ww, hh, o)
            local r = S.bw and S.bw._wboxRect
            if pp == S.bw and r and x == r.x and y == r.y then S.marked = true end
            return S.markOrig(pp, x, y, ww, hh, o)
        end
    end)
    step(5, function()
        local w = S.bw; if not w then return end
        if S.markOrig then ZeD.Focus.mark = S.markOrig; S.markOrig = nil end
        check(S.marked, "214 " .. tag .. ": the window box draws its focus mark")
        shot("214_" .. tag .. "_box_mark")
        -- A: the press, then the poll sees it come up (a tap)
        withPad(function()
            fake.focus = w
            w:onJoypadDown(Joypad.AButton, fake)
            Focus.qaButton("A", false, pn)
            Focus.tick()
            Focus.qaButton("A", nil, pn)
        end)
        local WM = ZeD.WindowMenu
        check(WM.current ~= nil and WM.current.win == w, "214 " .. tag .. ": A on the window box opens the window menu")
    end)
    step(10, function()
        local w = S.bw; if not w then return end
        shot("214_" .. tag .. "_menu")
        local WM = ZeD.WindowMenu
        local m = WM.current
        if not m then return end
        withPad(function() fake.focus = m; m:onJoypadDown(Joypad.BButton) end)
        check(WM.current == nil, "214 " .. tag .. ": B closes the window menu")
        check(fake.focus == w, "214 " .. tag .. ": the pad is back on the window (" .. desc(fake.focus) .. ")")
        if WM.current then WM.current:close() end
    end)
end
boxTest("char", cwin)
boxTest("world", wwin)

-- ===================================================================== 196: Y does not leave a ZeD dialog
step(10, function()
    local cw = cwin()
    withPad(function()
        Focus.claimFocus(cw); fake.focus = cw
        ZeD.DpadWheels.Z.safeMode(p, pn)
        S.q = fake.focus
        S.heldQ = Focus.held(pn)
    end)
    local q = S.q
    -- (round 2: a prompt added this call is not yet shown (isReallyVisible false until the UI manager takes it in),
    -- so the hold and the Y tap are checked on a later frame, as the director's Y came)
    check(q ~= nil and q ~= cw and q.Type == "ZeD_Prompt", "196: the Safe mode question (ZeD's prompt) takes the pad (" .. desc(q) .. ")")
    say("196: in the call that opened it, Focus.held " .. tostring(S.heldQ) .. ", shown " .. tostring(vis(q)))
end)
step(5, function()
    local q, cw = S.q, cwin()
    if not q then return end
    withPad(function() S.heldQ = Focus.held(pn) end)
    check(vis(q) and S.heldQ == true, "196: a frame on, it is up and Focus.held says it holds the pad")
    S.rolledQ = Focus.isRolled(cw)
    -- a Y tap, through the poll: press and release
    withPad(function()
        Focus.qaButton("Y", true, pn); Focus.tick()
        Focus.qaButton("Y", false, pn); Focus.tick()
        Focus.qaButton("Y", nil, pn)
    end)
    check(fake.focus == q and vis(q), "196: after a Y tap the question still holds the pad and is up (" .. desc(fake.focus) .. ")")
    check(Focus.getFocusedWindow(pn) == cw and Focus.isRolled(cw) == S.rolledQ, "196: and the windows are as they were")
end)
step(10, function()
    local q = S.q; if not q then return end
    shot("196_safe_ask_after_y")
    withPad(function() fake.focus = q; q:onJoypadDown(Joypad.BButton, fake) end)
    check(not vis(q), "196: B answers the question (it closes)")
    check(fake.focus == cwin(), "196: the pad goes back to the Character window (" .. desc(fake.focus) .. ")")
    check(ZeD.Settings.safeModeOption:getValue() == S.safeWas, "196: B is No: safe mode stays as it was")
end)

-- ===================================================================== 187: Start with a ZeD window holding the pad
step(10, function()
    pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(1) end)
    pcall(setGameSpeed, 1)
end)
step(10, function()
    local cw = cwin()
    if Focus.pauseMenuUp() then say("not run: 187 (the pause menu is already up)"); return end
    S.pauseRan = 0
    withPad(function()
        Focus.claimFocus(cw); fake.focus = cw
        cw:onJoypadDown(Joypad.Start, fake)
    end)
    check(S.pauseRan == 1, "187: Start on the Character window ran the game's pause (" .. tostring(S.pauseRan) .. "x)")
    check(Focus.pauseMenuUp(), "187: the pause menu is up")
    local ms = MainScreen and MainScreen.instance
    check(ms ~= nil and fake.focus == ms, "187: the pause menu took the pad (" .. desc(fake.focus) .. ")")
    S.paused = Focus.pauseMenuUp()
end)
step(20, function()
    if not S.paused then return end
    shot("187_pause_menu")
    -- 188: no claim, no wheel
    local cw, ww = cwin(), wwin()
    S.fw = Focus.getFocusedWindow(pn)
    local other = (S.fw == cw) and ww or cw
    withPad(function() Focus.claimFocus(other) end)
    check(Focus.getFocusedWindow(pn) == S.fw and fake.focus == MainScreen.instance, "188: a ZeD window cannot take the pad from the pause menu (" .. desc(Focus.getFocusedWindow(pn)) .. ", pad on " .. desc(fake.focus) .. ")")
    local D = ZeD.DpadWheels
    if D.gameWheels and D.gameWheels() then say("not run: 188 wheels (the game's own wheels are on here)") else
        withPad(function() ISDPadWheels.onDisplayDown(fake); ISDPadWheels.onDisplayRight(fake) end)
        local rm = false
        pcall(function() rm = getPlayerRadialMenu(pn):isReallyVisible() end)
        check(D.state[pn] == nil and not rm, "188: the D-pad opens no wheel behind the pause menu")
    end
    lockPad()
    S.rolled188 = Focus.isRolled(cw)
    Focus.qaButton("Y", true, pn)
end)
step(10, function() if S.paused then Focus.qaButton("Y", false, pn) end end)
step(4, function() if S.paused then Focus.qaButton("Y", nil, pn) end end)
step(15, function()
    if not S.paused then return end
    local cw = cwin()
    check(Focus.pauseMenuUp(), "188: after a Y tap the pause menu is still up")
    check(Focus.getFocusedWindow(pn) == S.fw and Focus.isRolled(cw) == S.rolled188, "188: Y did nothing to the windows (rolled " .. tostring(Focus.isRolled(cw)) .. ")")
    shot("188_pause_after_y")
    -- Y held down while the menu closes
    Focus.qaButton("Y", true, pn)
end)
step(10, function()
    if not S.paused then return end
    withPad(function() fake.focus = MainScreen.instance; ctl:onPauseButtonPressed() end)
    check(not Focus.pauseMenuUp(), "188: Start again closes the pause menu")
    S.rolledAfter = Focus.isRolled(cwin())
    S.fwAfter = Focus.getFocusedWindow(pn)
end)
step(10, function() if S.paused then Focus.qaButton("Y", false, pn) end end)
step(4, function() if S.paused then Focus.qaButton("Y", nil, pn) end end)
step(15, function()
    if not S.paused then return end
    check(Focus.isRolled(cwin()) == S.rolledAfter and Focus.getFocusedWindow(pn) == S.fwAfter, "188: a Y held through the menu closing is no new press")
end)

step(5, function()
    say("not run: 194 the death screen (needs the character to die)")
    say("not run: 213 the main menu desk (outside a save; the pause window has no desk)")
end)

-- ===================================================================== put back
step(20, function()
    JoypadState.players[pn + 1] = nil
    Focus.qaButton("Y", nil, pn); Focus.qaButton("A", nil, pn)
    if S.markOrig then ZeD.Focus.mark = S.markOrig; S.markOrig = nil end
    if Focus.pauseMenuUp() then withPad(function() fake.focus = MainScreen.instance; ctl:onPauseButtonPressed() end) end
    unlockPad()
    pcall(function() if ZeD.WindowMenu.current then ZeD.WindowMenu.current:close() end end)
    closeMenus()
    pcall(function() if S.q and vis(S.q) then S.q:close() end end)
    pcall(function() if S.rbox and vis(S.rbox) then S.rbox:close() end end)
    pcall(function() if S.kb and S.kb:isVisible() then S.kb:hide() end end)
    pcall(function() if S.tbox then S.tbox:unfocus(); S.tbox:setVisible(false); S.tbox:removeFromUIManager() end end)
    pcall(function() ZeD.Settings.safeModeOption:setValue(S.safeWas or 1) end)
    pcall(function() if S.ctxWas then ZeD.Settings.contextStyleOption:setValue(S.ctxWas) end end)
    pcall(function()
        local mm = ISSearchManager.getManager(p)
        if mm and (mm.isSearchMode and true or false) ~= (S.searchWas and true or false) then mm:toggleSearchMode() end
    end)
    pcall(function() if S.apple then p:getInventory():Remove(S.apple) end end)
    pcall(function() p:setBlockMovement(false) end)
    pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(S.speedWas or 1) end)
    pcall(function() if (CW.isOpen(pn) and true or false) ~= (S.pairWas and true or false) then CW.toggleBothPaired(pn) end end)
    pcall(Focus.releaseFocus, pn)
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
