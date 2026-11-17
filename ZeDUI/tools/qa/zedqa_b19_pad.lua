-- ZeDUI/tools/qa/zedqa_b19_pad.lua  (Nov 16 2026, QA): beta 19's controller fixes (16f186f3a) in the running game.
-- Build's pad_b19_sim proves the logic offline; this runs each fix's real code on the real windows.
-- No controller is plugged into the QA PC, so a stand-in pad record is put in JoypadState.players for the length of
-- one call only (withPad) and taken out again before the next frame: the code under test sees a pad, the game's own
-- per-frame pad code never does. What needs a real held button is said "not run" and goes on the director's list.
--   218   A at a door / a window: the prompt gets ZeD's action only with a pad (the keyboard's copy keeps the game's
--         nil); the press sets ignoreContextKey (so the game's own A on release cannot toggle it back); the door
--         toggles exactly once; the flag is cleared again a few updates after A is up; a second press puts it back.
--   228e  safe mode from the Select wheel: the question takes the pad, No gives it back to the ZeD window (safe mode
--         stays off). Better Folders' name prompt: takes the pad and gives it back (run on ZeD's support code even
--         though the mod itself is not installed here).
--   228f  Messages and the Reader: closed, the pad goes back where it came from, not to nothing. (Siren and car radio:
--         not run, they need a police car / a seat.)
--   228g  the on-screen keyboard put away with nothing named to go back to: the pad is not left on the bare field.
--   228i  Messages: Up from the top row reaches the window box, A opens its menu, Down comes back. The Reader: Up at
--         the top of the page reaches the box, A opens its menu, Down comes back.
--   228m  Hair | Beard: Left at the first part and Right at the last stay put (true, part unchanged); Up / Down leave.
--   228n  Messages: Up from the cards panel (not grabbed) goes to the window box.
--   228p  the window menu: Controller map with a pad only, Hide interface always; Hide interface hides, and it comes back.
--   217   Y-tap hides of the window pair (QA's button hook, Focus.qaButton): each prints a "[ZeD.LagClose]" line,
--         echoed here as "ZEDQA b19p lag ...".
-- Pictures: Screenshots/zqa_b19p_*.png. Puts back: doors as found, safe mode off, windows closed, the pad records out,
-- the interface shown, the pair open. grep "ZEDQA b19p".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA b19p " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b19p_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local Focus = ZeD.Input and ZeD.Input.Focus
local CW, WWn = ZeD_CharacterWindow, ZeD_WorldWindow
local S = {}
local function desc(o) if o == nil then return "nothing" end return tostring(o.Type or o._zedLabel or o) end

-- the stand-in pad: in JoypadState only for the call
local fake = { player = pn, focus = nil }
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
local function pairOpen()
    if not (CW.isOpen and CW.isOpen(pn)) then pcall(CW.toggleBothPaired, pn) end
end

-- ===================================================================== 218: A at a door and a window
local function findNear(pred, r)
    local cell = getCell()
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local best, bd
    for dx = -r, r do for dy = -r, r do
        local sq = cell:getGridSquare(px + dx, py + dy, pz)
        if sq then
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                if pred(o) then
                    local d = dx * dx + dy * dy
                    if not bd or d < bd then best, bd = o, d end
                end
            end
            local sp = sq:getSpecialObjects()
            for i = 0, sp:size() - 1 do
                local o = sp:get(i)
                if pred(o) then
                    local d = dx * dx + dy * dy
                    if not bd or d < bd then best, bd = o, d end
                end
            end
        end
    end end
    return best
end
local function isOpen(o) local ok, v = pcall(function() return o:IsOpen() end); return ok and v or false end
local PD = ZeD.PadDoor
local function doorTest(tag, pick)
    step(10, function()
        S[tag] = pick()
        if not S[tag] then say("not run: 218 " .. tag .. " (none within 40 tiles)"); return end
        local o = S[tag]
        say("218 " .. tag .. ": " .. tostring(o:getObjectName()) .. " at " .. o:getX() .. "," .. o:getY() .. ", open " .. tostring(isOpen(o)))
        -- stand the character beside it first (a long walk ran past the watch in round 2)
        pcall(function()
            local adj = AdjacentFreeTileFinder.Find(o:getSquare(), p)
            if adj then
                p:setX(adj:getX() + 0.5); p:setY(adj:getY() + 0.5); p:setZ(adj:getZ())
                p:setLastX(adj:getX() + 0.5); p:setLastY(adj:getY() + 0.5)
                say("218 " .. tag .. ": stood beside it at " .. adj:getX() .. "," .. adj:getY())
            end
        end)
    end)
    step(30, function()
        local o = S[tag]; if not o then return end
        -- the prompt: with the stand-in pad ZeD's action; without, the game's nil (the keyboard's copy)
        local bp1 = ISButtonPrompt:new(pn)
        withPad(function() bp1:doInteractButtonDoorOrWindowOrWindowFrame(nil, o) end)
        check(bp1.aFunc == PD.press, "218 " .. tag .. ": with a pad, the A prompt (" .. tostring(bp1.aPrompt) .. ") runs ZeD's open/close")
        local bp2 = ISButtonPrompt:new(pn)
        pcall(function() bp2:doInteractButtonDoorOrWindowOrWindowFrame(nil, o) end)
        check(bp2.aFunc == nil, "218 " .. tag .. ": without a pad, the prompt keeps the game's own (no function: keyboard E stays the game's)")
        S[tag .. "was"] = isOpen(o)
        S[tag .. "flips"] = 0
        S[tag .. "last"] = S[tag .. "was"]
        -- the press (as onAPress calls it: bp:aFunc(obj))
        withPad(function() PD.press(bp1, o) end)
        check(p:isIgnoreContextKey() == true, "218 " .. tag .. ": the press holds ignoreContextKey (the game's own A on release cannot toggle it back)")
    end)
    -- watch the door for 300 frames: it may change once, never twice
    for i = 1, 60 do
        step(10, function()
            local o = S[tag]; if not o then return end
            local now = isOpen(o)
            if now ~= S[tag .. "last"] then S[tag .. "flips"] = S[tag .. "flips"] + 1; S[tag .. "last"] = now end
        end)
    end
    step(5, function()
        local o = S[tag]; if not o then return end
        check(S[tag .. "flips"] == 1, "218 " .. tag .. ": toggled exactly once (" .. S[tag .. "flips"] .. " changes; open " .. tostring(S[tag .. "was"]) .. " -> " .. tostring(isOpen(o)) .. ")")
        check(PD.held[pn] == nil and p:isIgnoreContextKey() == false, "218 " .. tag .. ": A up, the flag is cleared again")
        shot("218_" .. tag)
        -- put it back the same way
        local bp = ISButtonPrompt:new(pn)
        withPad(function() bp:doInteractButtonDoorOrWindowOrWindowFrame(nil, o); PD.press(bp, o) end)
    end)
    step(400, function()
        local o = S[tag]; if not o then return end
        check(isOpen(o) == S[tag .. "was"], "218 " .. tag .. ": a second press puts it back (open " .. tostring(isOpen(o)) .. ")")
        say("not run: 218 " .. tag .. " with A really held down / keyboard E pressed / the keyboard-caret lead (no controller here: the director's hands)")
    end)
end

step(20, function()
    say("start: pad bound " .. tostring(JoypadState.players[pn + 1] ~= nil) .. ", at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()))
    check(PD ~= nil and PD.press ~= nil and ISButtonPrompt._zedPadDoor == true, "218: the door prompt wrap is on")
    S.home = { x = p:getX(), y = p:getY(), z = p:getZ() }
    if CW.isOpen and CW.isOpen(pn) then pcall(CW.toggleBothPaired, pn) end
end)
doorTest("door", function() return findNear(function(o) return (instanceof(o, "IsoDoor") or (instanceof(o, "IsoThumpable") and o:isDoor())) and not o:isLockedByKey() end, 40) end)
doorTest("window", function() return findNear(function(o) return instanceof(o, "IsoWindow") and not o:isInvincible() and not o:isDestroyed() and not o:isSmashed() and not o:isLocked() and not o:isPermaLocked() end, 40) end)
step(10, function()
    pcall(function() p:setX(S.home.x); p:setY(S.home.y); p:setLastX(S.home.x); p:setLastY(S.home.y) end)
end)

-- ===================================================================== 228e: safe mode's question
step(20, function()
    pairOpen()
end)
step(20, function()
    local cw = cwin()
    withPad(function() Focus.claimFocus(cw); fake.focus = cw end)
    S.safeWas = ZeD.Settings.safeModeOption:getValue()
    withPad(function() ZeD.DpadWheels.Z.safeMode(p, pn) end)
    S.modal = fake.focus
    check(S.modal ~= nil and S.modal ~= cw, "228e safe mode: the question (ZeD's prompt box) takes the pad (" .. desc(S.modal) .. ")")
    check(S.modal and S.modal.prevFocus == Focus.getFocusedWindow(pn), "228e safe mode: it remembers the ZeD window (" .. desc(S.modal and S.modal.prevFocus) .. ")")
    shot("228e_safe_ask")
end)
step(10, function()
    local m = S.modal
    if m and m.no then withPad(function() m:onClick(m.no) end) end
    check(fake.focus == cwin(), "228e safe mode: No gives the pad back to the Character window (" .. desc(fake.focus) .. ")")
    check(ZeD.Settings.safeModeOption:getValue() == S.safeWas, "228e safe mode: No leaves safe mode off")
end)
step(10, function()
    local V = ZeD.ModSupport and ZeD.ModSupport.VIF_DualRender_B42
    if not (V and V.askName) then say("not run: 228e Better Folders' name prompt (its support code is not loaded without the mod)"); return end
    local cw = cwin()
    fake.focus = cw
    local box = withPad(function() return V.askName(pn, "QA", "QA folder", function() end) end)
    check(box ~= nil and fake.focus == box, "228e Better Folders: the name prompt takes the pad (" .. desc(fake.focus) .. ")")
    check(box and box.prevFocus == cw, "228e Better Folders: it remembers what held the pad (" .. desc(box and box.prevFocus) .. ")")
    shot("228e_folder_ask")
    if box then withPad(function() if box.destroy then box:destroy() else box:setVisible(false); box:removeFromUIManager(); setJoypadFocus(pn, box.prevFocus) end end) end
    check(fake.focus == cw, "228e Better Folders: closed, the pad is back on the Character window (" .. desc(fake.focus) .. ")")
end)

-- ===================================================================== 228f / 228i / 228n: Messages
step(10, function()
    local cw = cwin()
    withPad(function() Focus.claimFocus(cw); fake.focus = cw end)
    S.msg = withPad(function() return ZeD.MessagesWindow.open(pn) end)
    check(S.msg ~= nil and fake.focus == S.msg, "228f Messages: opened, it holds the pad")
end)
step(20, function()
    local m = S.msg; if not m then return end
    m.zone = "list"
    local order = {}
    pcall(function() for _, n in ipairs(m.sourceOrder and m:sourceOrder() or {}) do order[#order + 1] = n end end)
    -- the top row: Up until the zone leaves the list
    for _ = 1, 30 do if m.zone ~= "list" then break end; withPad(function() m:onJoypadDirUp() end) end
    check(m.zone == "box", "228i Messages: Up from the top row reaches the window box (zone " .. tostring(m.zone) .. ")")
end)
step(10, function()
    local m = S.msg; if not m then return end
    JoypadState.players[pn + 1] = fake   -- (one frame, for the box's mark in the picture)
    S.markFrame = true
end)
step(2, function()
    if S.markFrame then JoypadState.players[pn + 1] = nil; S.markFrame = nil end
    shot("228i_msg_box")
    local m = S.msg; if not m then return end
    withPad(function() m:onJoypadDown(Joypad.AButton, fake) end)
    local WM = ZeD.WindowMenu
    check(WM.current ~= nil and WM.current.win == m, "228i Messages: A on the box opens the window menu")
end)
step(15, function()
    shot("228i_msg_menu")
    local WM = ZeD.WindowMenu
    if WM.current then withPad(function() WM.current:close() end) end
    local m = S.msg; if not m then return end
    withPad(function() m:onJoypadDirDown() end)
    check(m.zone == "cards" or m.zone == "list", "228i Messages: Down from the box goes back into the window (zone " .. tostring(m.zone) .. ")")
    m.zone, m.cardsGrab = "cards", nil
    withPad(function() m:onJoypadDirUp() end)
    check(m.zone == "box", "228n Messages: Up from the cards panel (not grabbed) goes to the window box (zone " .. tostring(m.zone) .. ")")
end)
step(10, function()
    local m = S.msg; if not m then return end
    fake.focus = m
    withPad(function() m:close() end)
    local back = Focus.getFocusedWindow(pn)
    check(fake.focus ~= nil and fake.focus ~= m and fake.focus == back, "228f Messages: closed, the pad goes back to the ZeD window (" .. desc(fake.focus) .. ")")
end)

-- ===================================================================== 228f / 228i: the Reader
step(10, function()
    local cw = cwin()
    withPad(function() Focus.claimFocus(cw); fake.focus = cw end)
    withPad(function() ZeD.Reader.openLabel(p, "QA beta 19 label. Up at the top of the page reaches the window box.") end)
    S.rd = ZeD.Reader.get(pn)
    check(S.rd ~= nil and fake.focus == S.rd, "228f Reader: opened, it holds the pad")
end)
step(20, function()
    local r = S.rd; if not r then return end
    for _ = 1, 40 do if r.padBox then break end; withPad(function() r:onJoypadDirUp() end) end
    check(r.padBox == true, "228i Reader: Up at the top of the page reaches the window box")
    JoypadState.players[pn + 1] = fake; S.markFrame = true
end)
step(2, function()
    if S.markFrame then JoypadState.players[pn + 1] = nil; S.markFrame = nil end
    shot("228i_reader_box")
    local r = S.rd; if not r then return end
    withPad(function() r:onJoypadDown(Joypad.AButton, fake) end)
    local WM = ZeD.WindowMenu
    check(WM.current ~= nil and WM.current.win == r, "228i Reader: A on the box opens the window menu")
end)
step(15, function()
    local WM = ZeD.WindowMenu
    if WM.current then withPad(function() WM.current:close() end) end
    local r = S.rd; if not r then return end
    withPad(function() r:onJoypadDirDown() end)
    check(not r.padBox, "228i Reader: Down comes back to the page")
    fake.focus = r
    withPad(function() r:close() end)
    check(fake.focus ~= nil and fake.focus ~= r and fake.focus == Focus.getFocusedWindow(pn), "228f Reader: closed, the pad goes back to the ZeD window (" .. desc(fake.focus) .. ")")
    say("not run: 228f siren and car radio (need a police car / a seat in a car with a radio: the director's hands)")
end)

-- ===================================================================== 228g: the keyboard with nothing to go back to
step(10, function()
    local box = ISTextEntryBox:new("", 100, 100, 300, 24)
    box:initialise(); box:instantiate(); box:addToUIManager()
    S.tbox = box
    local KB = ZeD.Keyboard
    local k = KB.get()
    withPad(function()
        k:show(pn, box, fake)
        k.prevFocus, k._zedPrev = nil, nil
        fake.focus = k
        k.joyfocus = fake
    end)
    S.kb = k
    shot("228g_keyboard")
end)
step(10, function()
    local k = S.kb; if not k then return end
    withPad(function() k:hide() end)
    local back = Focus.getFocusedWindow(pn)
    check(fake.focus ~= S.tbox and fake.focus ~= k, "228g keyboard: put away with nothing named, the pad is not left on the bare field (" .. desc(fake.focus) .. ")")
    check(fake.focus == back, "228g keyboard: it goes to the focused ZeD window, else the game (" .. desc(fake.focus) .. ", focused " .. desc(back) .. ")")
    pcall(function() S.tbox:setVisible(false); S.tbox:removeFromUIManager() end)
    pcall(function() p:setBlockMovement(false) end)
end)

-- ===================================================================== 228m: Hair | Beard ends
step(10, function()
    local cw = cwin()
    cw._activeTab = "identity"; cw._drawerMode = "tab"; cw._drawerOpen = true
end)
step(30, function()
    local cw = cwin()
    local HB = ZeD.HairBeard
    local el
    for _, e in ipairs(HB.focusables(cw)) do if e.id == "hb:part" then el = e end end
    if not el then say("not run: 228m (the Hair | Beard switch is not on the Identity tab)"); return end
    local st = cw._hb
    local parts = HB.partsOf(st)
    say("228m parts: " .. table.concat(parts, " | "))
    S.partWas = st.part
    HB.setPart(cw, parts[1])
    local r = el.onDpadDir(cw, el, "left")
    check(r == true and st.part == parts[1], "228m: Left at " .. parts[1] .. " stays put")
    HB.setPart(cw, parts[#parts])
    r = el.onDpadDir(cw, el, "right")
    check(r == true and st.part == parts[#parts], "228m: Right at " .. parts[#parts] .. " stays put")
    check(el.onDpadDir(cw, el, "up") == false and el.onDpadDir(cw, el, "down") == false, "228m: Up and Down leave the switch")
    if #parts > 1 then
        HB.setPart(cw, parts[1]); el.onDpadDir(cw, el, "right")
        check(st.part == parts[2], "228m: Right inside the switch still moves (" .. tostring(st.part) .. ")")
    end
    HB.setPart(cw, S.partWas or "hair")
    shot("228m_identity")
end)

-- ===================================================================== 228p: the window menu
step(10, function()
    local cw = cwin()
    local WM = ZeD.WindowMenu
    local function names(list) local o = {} for _, it in ipairs(list or {}) do o[#o + 1] = tostring(it.name) end return o end
    local withP = withPad(function() return WM.build(cw) end) or {}
    local without = WM.build(cw) or {}
    local cm, hi = getText("UI_ZeD_Wheel_ControllerMap"), getText("UI_ZeD_Wheel_HideInterface")
    pcall(function() cm, hi = ZeD.tr("UI_ZeD_Wheel_ControllerMap"), ZeD.tr("UI_ZeD_Wheel_HideInterface") end)
    local function has(list, n) for _, it in ipairs(list) do if it.name == n then return it end end end
    say("228p menu with a pad: " .. table.concat(names(withP), " | "))
    check(has(withP, cm) ~= nil and has(withP, hi) ~= nil, "228p: with a pad the window menu has Controller map and Hide interface")
    check(has(without, cm) == nil and has(without, hi) ~= nil, "228p: without a pad, Hide interface only (no Controller map)")
    S.hideItem = has(without, hi)
    S.mapItem = has(withP, cm)
    -- the order: next to Bug report
    local bi, ci
    for i, it in ipairs(withP) do if it.name == hi then ci = i end; if tostring(it.name):find("ug") and tostring(it.name):lower():find("report") then bi = i end end
    check(bi and ci and ci - bi <= 2 and ci > bi, "228p: they sit after Bug report (" .. tostring(bi) .. ", " .. tostring(ci) .. ")")
    WM.open(cw)
end)
step(15, function()
    shot("228p_window_menu")
    local WM = ZeD.WindowMenu
    if WM.current then WM.current:close() end
    if S.mapItem then withPad(function() S.mapItem.onFire() end) end
end)
step(20, function()
    shot("228p_controller_map")
    local CM = ZeD.ControllerMap
    pcall(function() if CM and CM.close then CM.close(pn) end end)
    pcall(function() if CM and CM.instance and CM.instance.close then CM.instance:close() end end)
    if S.hideItem then S.hideItem.onFire() end
end)
step(20, function()
    S.hidden = not cwin():isReallyVisible()
    shot("228p_hidden")
    check(S.hidden, "228p: Hide interface hides the windows")
    pcall(function() ISUIHandler.toggleUI() end)
end)
step(20, function()
    check(cwin():isReallyVisible(), "228p: the interface comes back (the game's toggle)")
end)

-- ===================================================================== 217: Y-tap hides, timed
local realPrint = print
local lagLines = {}
step(5, function()
    local cw = cwin()
    cw._activeTab = "inventory"
    pcall(Focus.releaseFocus, pn)
    pcall(function() S.lockWas = p:getModData().ZeD_Gamepad and p:getModData().ZeD_Gamepad.inputModeLock end)
    pcall(function() ZeD.Input.Detector.setLockedMode("gamepad") end)
    print = function(s, ...)
        if type(s) == "string" and s:find("[ZeD.LagClose]", 1, true) then lagLines[#lagLines + 1] = s end
        return realPrint(s, ...)
    end
end)
for i = 1, 6 do
    step(10, function() Focus.qaButton("Y", true, pn) end)
    step(4, function() Focus.qaButton("Y", false, pn) end)
    step(4, function() Focus.qaButton("Y", nil, pn) end)
    step(20, function()
        local cw = cwin()
        say("217 tap " .. i .. ": Character rolled " .. tostring(Focus.isRolled(cw)))
    end)
end
step(10, function()
    print = realPrint
    pcall(function() local Dt = ZeD.Input.Detector; Dt.setLockedMode(nil); if S.lockWas == "kbm" or S.lockWas == "gamepad" then Dt.setLockedMode(S.lockWas) end end)
    for _, l in ipairs(lagLines) do say("lag " .. l) end
    check(#lagLines >= 3, "217: each Y-tap hide printed a [ZeD.LagClose] line (" .. #lagLines .. ")")
    local cw = cwin()
    if Focus.isRolled(cw) then Focus.qaButton("Y", true, pn) end
end)
step(4, function() Focus.qaButton("Y", false, pn) end)
step(4, function() Focus.qaButton("Y", nil, pn) end)

-- ===================================================================== put back
step(20, function()
    print = realPrint
    JoypadState.players[pn + 1] = nil
    pcall(function() p:setIgnoreContextKey(false) end)
    pcall(function() p:setBlockMovement(false) end)
    pcall(function() ZeD.Settings.safeModeOption:setValue(S.safeWas or 1) end)
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
