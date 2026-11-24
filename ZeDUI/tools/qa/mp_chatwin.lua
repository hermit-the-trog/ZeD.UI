-- ZeDUI/tools/qa/mp_chatwin.lua  (Nov 23 2026, QA; tag mp_chatwin): the chat window's new place, roll, pin and ghost, on
-- the multiplayer client. Build's branch fix/chatwin (5068465a7, from fix/hudgaps). The director, Nov 23 2026: the chat
-- window first opens at the screen's bottom, right of the belt's chat key; it is narrower (360 units, MIN_W 260); a
-- title-bar control rolls it down into the screen's bottom and back up; a pin keeps it open and, with the pointer off it,
-- ghosts it (surfaces faint, words full).
-- Needs the test server: zedqa_run.ps1 -Mp (mp_server.ps1 -Start first). Run with mp_chatwin.txt. grep "ZEDQA mp_chatwin".
--
-- How it presses: the window's own handlers with its own rects (onMouseDown / onMouseUp on win._rollRect, the title bar,
-- a tab), the belt's own press on its chat key (ZeD_BeltHUD:onMouseDown on the "chat" box), T as the engine fires it
-- (triggerEvent OnKeyPressed with the Toggle chat key), the pin box and the close box through the window's own release
-- path (win._boxDo "pin" / "close", which _watchBoxes sets on a release over the box and update() acts on: the read
-- pointer cannot be moved in this game, so the box's hit test itself is not driven). The pointer on or off the window is
-- the window's own isMouseOver, overridden on the instance for the run (it is what _ghostNow, _idle and pointerOn read).
-- A new line is sent with the game's own /all send (processGeneralMessage); if none arrives in 6 s, the server's
-- /servermsg as the admin.
--
-- Checks:
--   1 default place   Lua/ZeD_chatwin.txt moved aside (kept in memory, the file emptied: it reads as no place), the
--                     window opened by the belt's chat key: its bottom on the screen's bottom (1 px), its left edge the
--                     chat key's right edge (past the PvP marker when the server shows one) + B.ICON_GAP in px, on the
--                     screen; 360 units wide (MIN_W 260); it overlaps none of the belt row's boxes
--   2 roll            down by the roll box, a double press on the title bar and pad X (the window's own X handler; with
--                     a pad bound, after the pad's focus is on the window, else the focused press is SKIPPED): windowShaded,
--                     the title bar where the foot was; up by the roll box, a press on the rolled bar, T (the line
--                     focused) and the belt's chat key: the height back in place
--   3 new line        rolled down, a line arrives: C.unread() (the chat key's count) goes up, the window stays down;
--                     back up, the count goes
--   4 pin             pinned through the pin box's path; Esc while typing leaves the line only, a second Esc does nothing
--                     (the window stays); the chat key rolls it down instead of closing it, then up again; the close box
--                     closes it and unpins it (the saved line's pinned field 1, then 0)
--   5 ghost           pinned, the pointer off it, not typing: _ghost true, _surfaceAlpha(ZeD.T) == C.GHOST_A == 0.15 and
--                     the edged words drawn (C.inkText) in Dark, Light and High contrast; the pointer on it: _ghost false
--                     on the next frame; a press on a tab of the ghosted window only lifts the ghost (the tab stays:
--                     nothing invisible can be hit, Build 504ac8ebd on QA's note), a second press changes the tab
--   6 saved line      the file starts "v2 " with x y w h tab rolled pinned; an old line (no v2) reads as no place
--                     (C._readPlace nil), the chat key then opens it at the default place, and the line it writes reads
--                     as a place again (once)
--   7 pictures        mp_chatwin_open_<w>x<h>, mp_chatwin_rolled_<w>x<h> (the count on the chat key),
--                     mp_chatwin_ghost_<dark|light|hc>_<w>x<h>, the pointer hidden
--   errors            no new Lua error over the run
-- Not covered: a window pinned at quit reopening on the next join (needs a rejoin; printed as a TODO line).
--
-- Puts back: Lua/ZeD_chatwin.txt as found (ZeD writes it as one line with no newline; it is written back that way, and
-- a hand-made file with a trailing newline would come back without it; no file before the run leaves an empty file,
-- which reads as no place, and a NOTE says so). The QA chain's Lua file guards (zedqa_run.ps1: ModOptions.ini and
-- ZeD_tutorial.txt; the report runs: ModOptions.ini, ZeD_setup.txt, ZeD_tutorial.txt, ZeD_setup_seen.txt) do not list
-- ZeD_chatwin.txt, so this script puts it back itself. Also: the theme (base, accent, size), the chat's tab, the window
-- shut or open as found (and where, rolled and pinned as found: pin off on a QA character), the window's isMouseOver and
-- C.inkText unwrapped, the pointer the game's, the text line unfocused. No Lua error. Nothing is given.
if not RT then print("ZEDQA mp_chatwin ERR rt_kit.lua did not run first"); print("ZEDQA mp_chatwin DONE"); return end
local Q = RT.make("mp_chatwin")
Q.maxMs = 780000                     -- (the runner gives this script 900 s: the put-back runs before that)
local S = { found = {}, back = {}, over = false, hooked = {}, inkN = 0 }
local C = ZeD and ZeD.Chat

S.FILE = "ZeD_chatwin.txt"
S.OLD = "120 400 440 260 general"   -- a line as ZeD wrote it before Nov 23 2026: x y w h tab, no "v2"
S.THEMES = {
    { key = "dark", tag = "dark", say = "Dark" },
    { key = "light", tag = "light", say = "Light" },
    { key = "hicon", tag = "hc", say = "High contrast" },
}

-- ===================================================================== small helpers
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.px(n) return ZeD.T.px(n) end
function S.near(a, b, tol) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (tol or 1) end
function S.until1(n, max, cond, fn)
    Q.waitFor(n, max, function() return S.dead or cond() end, function(ok) if not S.dead then fn(ok) end end)
end

-- the file, through the game's Lua file API (Zomboid/Lua)
function S.readFile()
    local r = getFileReader(S.FILE, false)
    if not r then return nil end
    local out = {}
    local l = r:readLine()
    while l do
        out[#out + 1] = l
        l = r:readLine()
    end
    r:close()
    return out
end
function S.writeFile(lines)
    local f = getFileWriter(S.FILE, true, false)
    if not f then return false end
    f:write(table.concat(lines or {}, "\n"))
    f:close()
    return true
end
function S.firstLine()
    local t = S.readFile()
    if not t then return nil end
    return t[1]
end
function S.sameLines(a, b)
    if a == nil or b == nil then return a == b end
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end
-- the saved line's fields: "v2 x y w h tab rolled pinned"
function S.fields(l)
    local t = {}
    for s in string.gmatch(l or "", "%S+") do t[#t + 1] = s end
    return t
end

-- the window, with the pointer on or off it as the run says (S.over): its own isMouseOver, on the instance
function S.fakeOver() return S.over end
-- (Nov 24: the window can already carry an isMouseOver of its own on the instance (two runs: the stand-in was never
-- put on, the pointer-on check failed): the stand-in goes on over it, and the one it covered is put back)
function S.w()
    local w = C.win
    if w and rawget(w, "isMouseOver") ~= S.fakeOver then
        S.hooked[#S.hooked + 1] = { w = w, was = rawget(w, "isMouseOver") }
        w.isMouseOver = S.fakeOver
    end
    return w
end
function S.unhook()
    for i = #S.hooked, 1, -1 do
        local h = S.hooked[i]
        if rawget(h.w, "isMouseOver") == S.fakeOver then h.w.isMouseOver = h.was end
    end
    S.hooked = {}
end
function S.vis(w) return w ~= nil and w:getIsVisible() and true or false end
function S.geo(w)
    return { x = math.floor(w:getX() + 0.5), y = math.floor(w:getY() + 0.5), w = math.floor(w:getWidth() + 0.5),
             h = math.floor(w:getHeight() + 0.5) }
end
function S.gText(g) return g and string.format("%d,%d %dx%d", g.x, g.y, g.w, g.h) or "none" end

-- the belt: its HUD, the chat key's box and the box the window's place is measured from (the PvP marker right after
-- the key when the server shows one, as C.defaultPlace reads it)
function S.chatKey()
    local B = ZeD.Belt
    local hud = B and B.getHUD and B.getHUD(0)
    if not (hud and hud._boxes and hud:getIsVisible()) then return hud, nil, nil end
    local key, anchor = nil, nil
    for _, b in ipairs(hud._boxes) do
        if b.kind == "chat" then key = b; anchor = b
        elseif key and b.kind == "pvp" then anchor = b end
    end
    return hud, key, anchor
end
-- the belt's own press on its chat key (B.tailAct("chat") if the belt did not take it)
function S.pressKey()
    local hud, key = S.chatKey()
    if not key then error("no chat key on the belt") end
    local took = hud:onMouseDown(key.x + math.floor(key.w / 2), key.y + math.floor(key.h / 2))
    if not took then
        Q.say("NOTE the belt did not take the press on its chat key (not drawn yet?): B.tailAct(\"chat\") instead")
        ZeD.Belt.tailAct("chat")
    end
end
-- where the window's default place is, by Build's rule: x, y, words
function S.expectPlace(w)
    local sw, sh = S.screen()
    local hud, key, anchor = S.chatKey()
    if not (hud and key) then return nil, nil, "no chat key on the belt" end
    local gap = S.px(ZeD.Belt.ICON_GAP or 38)
    local right = math.floor(hud:getAbsoluteX() + anchor.x + anchor.w + 0.5)
    local want = right + gap
    local ex = math.max(0, math.min(want, sw - w:getWidth()))
    local ey = math.max(0, sh - w:getHeight())
    local why = string.format("anchor %s right edge %d + ICON_GAP %d px = %d%s", tostring(anchor.kind), right, gap, want,
        (ex ~= want) and (", held on the screen at " .. ex .. " (the screen is too narrow for the window there)") or "")
    return ex, ey, why
end
-- the belt row's boxes the window covers (screen px)
function S.overlaps(w)
    local hud = S.chatKey()
    local out = {}
    if not (hud and hud._boxes) then return out end
    local g = S.geo(w)
    local hx, hy = hud:getAbsoluteX(), hud:getAbsoluteY()
    for _, b in ipairs(hud._boxes) do
        local bx, by = hx + b.x, hy + b.y
        if g.x < bx + b.w and bx < g.x + g.w and g.y < by + b.h and by < g.y + g.h then
            out[#out + 1] = string.format("%s at %d,%d %dx%d", tostring(b.kind), math.floor(bx), math.floor(by), b.w, b.h)
        end
    end
    return out
end

-- presses on the window, in its own coordinates, through its own handlers
function S.tap(w, x, y)
    w:onMouseDown(x, y)
    w:onMouseUp(x, y)
end
function S.pressRoll(w)
    local r = w._rollRect
    if not r then error("no roll box drawn") end
    S.tap(w, r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2))
end
-- a spot on the title bar clear of its boxes: between the roll box and the pin box
function S.titleSpot(w)
    local r = w._rollRect
    if not r then error("no roll box drawn") end
    local pr = w:pinRect()
    local right = pr and pr.x or (w:getWidth() - 3 * r.w)
    return math.floor((r.x + r.w + right) / 2), math.floor(w:titleBarHeight() / 2)
end
function S.doublePress(w)
    local x, y = S.titleSpot(w)
    S.tap(w, x, y)
    S.tap(w, x, y)
end
function S.barPress(w)
    local x, y = S.titleSpot(w)
    S.tap(w, x, y)
end
-- the game's Toggle chat key (T by default): its code, as the game's own handler tests it
function S.tKey()
    local k = nil
    pcall(function() k = getCore():getKey("Toggle chat") end)
    local hit = false
    if type(k) == "number" and k > 0 then pcall(function() hit = getCore():isKey(KeybindId.TOGGLE_CHAT, k) end) end
    if hit then return k end
    for c = 1, 255 do
        pcall(function() hit = getCore():isKey(KeybindId.TOGGLE_CHAT, c) end)
        if hit then return c end
    end
    return nil
end
function S.pressT()
    local k = S.tKey()
    if not k then error("no key reads as Toggle chat") end
    S.tCode = k
    triggerEvent("OnKeyPressed", k)
end
function S.unfocus()
    local w = C.win
    if w and w.input and w.input:isFocused() then w.input:unfocus() end
end
-- the window's own X: the pad's when one is bound and its focus is on the window, else a stand-in pad's
function S.padX(w)
    local jd = S.jd
    if jd and w.joyfocus then
        S.padStandIn = false
        w:onJoypadDown(Joypad.XButton, jd)
    else
        S.padStandIn = true
        w:onJoypadDown(Joypad.XButton, { player = 0 })
    end
end
function S.padHow()
    if S.padStandIn then return "pad X (the window's own X handler, a stand-in pad: no pad holds its focus here)" end
    return "pad X (the pad's focus on the window)"
end

-- ===================================================================== pictures (hg_injury.lua's S.shot)
function S.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return -9000 end
            getMouseY = function() return -9000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function S.shot(name, what)
    Q.step(1, function() if not S.dead then S.park(true) end end)
    Q.step(4, function()
        if S.dead then S.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
        S.park(false)
    end)
    Q.waitMs(1500)
end

-- ===================================================================== the theme (hg_tint.lua's switch)
function S.theme(base)
    if ZeD.currentBase == base then return end
    pcall(ZeD.applyTheme, base, ZeD.currentAccent, ZeD.currentSize)
    Q.say("theme " .. tostring(ZeD.currentBase) .. " (" .. tostring(ZeD.currentAccent) .. ", " .. tostring(ZeD.currentSize) .. ")")
end

-- ===================================================================== one roll, down or up, and its check
-- n: the check's number and name; how: the way (words, or a function for them); act(w); down: rolls down (else up);
-- after(w, ok): more checks once it rolled
function S.rollCase(n, how, act, down, after)
    Q.step(4, function()
        if S.dead then return end
        local w = S.w()
        if not w then S.acted = "no window"; return end
        if down then S.full = S.geo(w) end
        local ok, e = pcall(act, w)
        S.acted = ok and "pressed" or ("error: " .. tostring(e))
    end)
    S.until1(2, 90, function()
        local w = C.win
        return w ~= nil and (w.windowShaded and true or false) == down
    end, function(ok)
        local name = (type(how) == "function") and how() or how
        local w = C.win
        if not w then
            Q.check(false, n .. ": " .. name .. " rolls it " .. (down and "down" or "up"), "no window; " .. tostring(S.acted))
            return
        end
        local g, f, tbH = S.geo(w), S.full, w:titleBarHeight()
        if not f then
            Q.check(false, n .. ": " .. name .. ": the run knew the window's full place first", S.gText(g))
            return
        end
        if down then
            local foot = f.y + f.h
            Q.check(ok and w.windowShaded == true and S.vis(w) and S.near(g.h, tbH) and S.near(g.y + g.h, foot),
                n .. ": " .. name .. " rolls it down: the title bar alone, sitting where the window's foot was",
                string.format("windowShaded %s; bar %s (title bar %d px), its foot %d, the window's foot was %d (full %s); %s",
                    tostring(w.windowShaded), S.gText(g), tbH, g.y + g.h, foot, S.gText(f), tostring(S.acted)))
        else
            Q.check(ok and not w.windowShaded and S.vis(w) and S.near(g.x, f.x) and S.near(g.y, f.y) and S.near(g.h, f.h)
                and S.near(g.w, f.w),
                n .. ": " .. name .. " brings it back up: the height back, in place",
                string.format("windowShaded %s; now %s, was %s; %s", tostring(w.windowShaded), S.gText(g), S.gText(f), tostring(S.acted)))
        end
        if after then after(w, ok) end
    end)
end

-- ===================================================================== start: what is found, the file moved aside
function S.start()
    S.err0 = S.errN()
    local ready = C ~= nil and C.active ~= nil and C.active() and C.defaultPlace ~= nil and C._readPlace ~= nil
        and C.unread ~= nil and C.toggle ~= nil and C.inkText ~= nil and C.GHOST_A ~= nil and ZeD_ChatWindow ~= nil
        and ZeD_ChatWindow.pinRect ~= nil and ZeD.Belt ~= nil and ZeD.Belt.getHUD ~= nil and ZeD.applyTheme ~= nil
    if not Q.check(ready, "the chat window of fix/chatwin is loaded and active (a server, not safe mode)",
        "isClient " .. tostring(isClient()) .. ", C.defaultPlace " .. tostring(C ~= nil and C.defaultPlace ~= nil)
        .. ", C.GHOST_A " .. tostring(C and C.GHOST_A)) then
        S.dead = true
        return
    end
    local f = S.found
    f.file = S.readFile()
    f.had = f.file ~= nil
    f.tab = C.tab
    f.base, f.accent, f.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    local w = C.win
    f.open = S.vis(w)
    if w then
        f.shaded = w.windowShaded and true or false
        f.pinned = w.pinned and true or false
        local g = S.geo(w)
        if f.shaded and w.preShadeHeight then
            g.y = g.y + w:titleBarHeight() - math.floor(w.preShadeHeight + 0.5)
            g.h = math.floor(w.preShadeHeight + 0.5)
        end
        f.g = g
    end
    f.recorded = true
    S.back.on = true
    Q.say("found: Lua/ZeD_chatwin.txt " .. (f.had and ("\"" .. table.concat(f.file, "\\n") .. "\"") or "none")
        .. "; window " .. (f.open and ("open at " .. S.gText(f.g) .. ", rolled " .. tostring(f.shaded) .. ", pinned " .. tostring(f.pinned)) or "shut")
        .. "; tab " .. tostring(f.tab) .. "; theme " .. tostring(f.base) .. " / " .. tostring(f.accent) .. " / " .. tostring(f.size)
        .. "; screen " .. S.sizeTag() .. ", UI scale " .. tostring(ZeD.T and ZeD.T.scale) .. "; unread " .. tostring(C.unread()))
    if w then w:close() end
    S.writeFile({})
    C._savedPlace = nil
end

-- ===================================================================== 1 the default place
function S.build1()
    Q.step(6, function()
        if S.dead then return end
        local okR, x = pcall(C._readPlace)
        Q.check(okR and x == nil and C.win == nil, "1 default place: Lua/ZeD_chatwin.txt moved aside (it reads as no place), the window shut",
            "first line " .. tostring(S.firstLine()) .. ", C.win " .. tostring(C.win ~= nil))
        local hud, key = S.chatKey()
        if not Q.check(key ~= nil, "1 default place: the belt shows the chat key", "HUD " .. tostring(hud ~= nil)) then return end
        local ok, e = pcall(S.pressKey)
        if not ok then Q.say("NOTE the chat key press: " .. tostring(e)) end
    end)
    S.until1(5, 300, function() local w = C.win; return S.vis(w) and w._rollRect ~= nil end, function(ok)
        local w = S.w()
        if not Q.check(ok and w ~= nil, "1 default place: the belt's chat key opens the chat window") then return end
        local sw, sh = S.screen()
        local g = S.geo(w)
        local ex, ey, why = S.expectPlace(w)
        Q.check(ey ~= nil and S.near(g.y + g.h, sh),
            "1 default place: the window's bottom on the screen's bottom (1 px)",
            string.format("window %s, its bottom %d, screen height %d", S.gText(g), g.y + g.h, sh))
        Q.check(ex ~= nil and S.near(g.x, ex),
            "1 default place: its left edge one icon's gap (B.ICON_GAP) right of the chat key (past the PvP marker if any)",
            string.format("left edge %d, expected %s; %s", g.x, tostring(ex), tostring(why)))
        if ex ~= nil and g.x ~= ex then Q.say("NOTE left edge off by " .. (g.x - ex) .. " px") end
        local W, MW = S.px(360), S.px(260)
        Q.check(S.near(g.w, W) and S.near(w.minimumWidth, MW),
            "1 default place: 360 units wide, its narrowest 260 units",
            string.format("width %d px, 360 units = %d px; minimumWidth %s, 260 units = %d px (scale %s)", g.w, W,
                tostring(w.minimumWidth), MW, tostring(ZeD.T.scale)))
        local ov = S.overlaps(w)
        Q.check(#ov == 0, "1 default place: it covers none of the belt row's boxes",
            (#ov == 0) and ("window " .. S.gText(g)) or ("window " .. S.gText(g) .. " covers " .. table.concat(ov, "; ")))
        S.place1 = g
    end)
    S.shot("mp_chatwin_open_" .. S.sizeTag(), "the chat window at its default place, by the belt's chat key")
end

-- ===================================================================== 2 roll down, back up
function S.build2()
    S.rollCase("2 roll", "the roll box", S.pressRoll, true)
    S.rollCase("2 roll", "the roll box", S.pressRoll, false)
    S.rollCase("2 roll", "a double press on the title bar", S.doublePress, true)
    S.rollCase("2 roll", "a press on the rolled bar", S.barPress, false)
    -- pad X: with a pad bound, its focus on the window first
    Q.step(4, function()
        if S.dead then return end
        S.jd = JoypadState and JoypadState.players and JoypadState.players[1] or nil
        if S.jd then pcall(C.open, false, true) end
    end)
    S.until1(2, 60, function() return S.jd == nil or (C.win ~= nil and C.win.joyfocus ~= nil) end, function(ok)
        if not S.jd then
            Q.skip("2 roll: pad X with the pad's focus on the window",
                "no pad is bound on this rig (JoypadState.players[1] is nil), so the window cannot hold pad focus; the window's own X handler is pressed with a stand-in pad instead")
        elseif not ok then
            Q.skip("2 roll: pad X with the pad's focus on the window", "the window did not take the pad's focus in 60 frames")
        end
    end)
    S.rollCase("2 roll", S.padHow, S.padX, true, function(w)
        if S.jd and not S.padStandIn then
            Q.check(S.jd.focus ~= w, "2 roll: pad X gives the pad back to the game", "jd.focus is the window " .. tostring(S.jd.focus == w))
        end
    end)
    S.rollCase("2 roll", "T (the game's Toggle chat key)", function() S.pressT() end, false, function(w)
        local foc = w.input ~= nil and w.input:isFocused()
        Q.check(foc, "2 roll: T also puts the typing line in focus", "key code " .. tostring(S.tCode) .. ", focused " .. tostring(foc))
        S.unfocus()
    end)
    S.rollCase("2 roll", "the roll box", S.pressRoll, true)
    S.rollCase("2 roll", "the belt's chat key", function() S.pressKey() end, false)
end

-- ===================================================================== 3 a new line while rolled down
function S.lineIn()
    local L = C.lines or {}
    for i = #L, math.max(1, #L - 20), -1 do
        local t = L[i] and L[i].text
        if t and S.stamp and string.find(t, S.stamp, 1, true) then return true end
    end
    return false
end
function S.build3()
    S.rollCase("3 new line", "the roll box (before the line)", S.pressRoll, true)
    Q.step(4, function()
        if S.dead then return end
        S.u0 = C.unread()
        S.stamp = "zedqa chatwin " .. tostring(getTimestampMs() % 1000000)
        S.sentHow = "the game's /all send (processGeneralMessage)"
        local ok, e = pcall(processGeneralMessage, S.stamp)
        if not ok then S.sentHow = S.sentHow .. " failed: " .. tostring(e) end
    end)
    S.until1(2, 360, S.lineIn, function(ok)
        if ok then return end
        S.sentHow = S.sentHow .. ", no line in 6 s; then the server's /servermsg as the admin"
        pcall(SendCommandToServer, "/servermsg \"" .. S.stamp .. "\"")
    end)
    S.until1(2, 600, S.lineIn, function(ok)
        local w = C.win
        local u1 = C.unread()
        local _, key = S.chatKey()
        Q.check(ok, "3 new line: a line sent while rolled down reaches the chat", tostring(S.sentHow) .. "; \"" .. tostring(S.stamp) .. "\"")
        Q.check(ok and type(u1) == "number" and type(S.u0) == "number" and u1 > S.u0 and key ~= nil,
            "3 new line: the chat key's count (C.unread) goes up while the window is down",
            "C.unread " .. tostring(S.u0) .. " to " .. tostring(u1) .. "; the chat key on the belt " .. tostring(key ~= nil))
        Q.check(w ~= nil and S.vis(w) and w.windowShaded == true, "3 new line: the window stays rolled down",
            "visible " .. tostring(S.vis(w)) .. ", windowShaded " .. tostring(w and w.windowShaded))
    end)
    S.shot("mp_chatwin_rolled_" .. S.sizeTag(), "the chat window rolled down to its title bar, a new line counted on the chat key")
    S.rollCase("3 new line", "the belt's chat key (after the line)", function() S.pressKey() end, false, function()
        Q.check(C.unread() == 0, "3 new line: back up, the chat key's count goes", "C.unread " .. tostring(C.unread()))
    end)
end

-- ===================================================================== 4 the pin
function S.pinBy(n, on)
    Q.step(4, function()
        if S.dead then return end
        local w = S.w()
        if w then w._boxDo = "pin" end
    end)
    S.until1(2, 120, function() local w = C.win; return w ~= nil and (w.pinned and true or false) == on end, function(ok)
        local l = S.firstLine()
        local t = S.fields(l)
        Q.check(ok, n .. ": the pin box " .. (on and "pins" or "unpins") .. " it (pinned " .. tostring(on) .. ")",
            "pinned " .. tostring(C.win and C.win.pinned))
        Q.check(t[1] == "v2" and t[8] == (on and "1" or "0"), n .. ": the saved line's pinned field follows (" .. (on and "1" or "0") .. ")",
            tostring(l))
    end)
end
function S.build4()
    S.pinBy("4 pin", true)
    Q.step(4, function()
        if S.dead then return end
        local w = S.w()
        if w then S.escW = w; w:focusInput() end
    end)
    Q.step(3, function()
        if S.dead then return end
        local w = S.escW
        if not w then return end
        local E = Keyboard.KEY_ESCAPE
        S.esc = { focused = w.input:isFocused() }
        pcall(w.input.onOtherKey, w.input, E)       -- (the text box's own Escape: it leaves the line)
        S.esc.consumed = w:isKeyConsumed(E)
        local ok, e = pcall(w.onKeyPress, w, E)       -- (then the window's, as the game hands it on)
        S.esc.ok, S.esc.err = ok, e
    end)
    Q.step(3, function()
        if S.dead then return end
        local w, e = S.escW, S.esc or {}
        if not w then Q.check(false, "4 pin: Esc while typing", "no window"); return end
        Q.check(e.focused == true and not w.input:isFocused() and e.consumed == true and e.ok == true and S.vis(w) and C.win == w and w.pinned == true,
            "4 pin: pinned, Esc while typing leaves the line only (the window stays open and pinned)",
            string.format("line focused before %s, after %s; Esc consumed %s; onKeyPress ran %s%s; visible %s, the same window %s, pinned %s",
                tostring(e.focused), tostring(w.input:isFocused()), tostring(e.consumed), tostring(e.ok),
                e.ok and "" or (" (" .. tostring(e.err) .. ")"), tostring(S.vis(w)), tostring(C.win == w), tostring(w.pinned)))
    end)
    Q.waitMs(400)
    Q.step(2, function()
        if S.dead then return end
        local w = S.escW
        if not w then return end
        local E = Keyboard.KEY_ESCAPE
        local consumed = w:isKeyConsumed(E)
        local ok, e = pcall(w.onKeyPress, w, E)
        Q.check(not consumed and ok and S.vis(w) and C.win == w and w.pinned == true,
            "4 pin: pinned, a second Esc with no line to leave does nothing to the window (the game's)",
            string.format("consumed %s; onKeyPress ran %s%s; visible %s, pinned %s", tostring(consumed), tostring(ok),
                ok and "" or (" (" .. tostring(e) .. ")"), tostring(S.vis(w)), tostring(w.pinned)))
    end)
    S.rollCase("4 pin", "the belt's chat key (pinned)", function() S.pressKey() end, true, function(w)
        Q.check(S.vis(w) and w.pinned == true and C.win == S.escW, "4 pin: pinned, the chat key rolls it down instead of closing it",
            "visible " .. tostring(S.vis(w)) .. ", pinned " .. tostring(w.pinned) .. ", the same window " .. tostring(C.win == S.escW))
    end)
    S.rollCase("4 pin", "the belt's chat key (pinned, rolled)", function() S.pressKey() end, false)
    Q.step(4, function()
        if S.dead then return end
        local w = S.w()
        S.closeW = w
        if w then w._boxDo = "close" end
    end)
    S.until1(2, 120, function() return S.closeW ~= nil and not S.vis(S.closeW) end, function(ok)
        local w = S.closeW
        local t = S.fields(S.firstLine())
        Q.check(ok and w ~= nil and w.pinned == false and C.win == nil and t[8] == "0",
            "4 pin: the close box closes it and unpins it",
            "visible " .. tostring(S.vis(w)) .. ", pinned " .. tostring(w and w.pinned) .. ", C.win " .. tostring(C.win ~= nil)
            .. ", saved line " .. tostring(S.firstLine()))
    end)
end

-- ===================================================================== 5 the ghost
function S.ghostTheme(TH)
    Q.step(4, function()
        if S.dead then return end
        S.theme(TH.key)
        S.over = false
        S.unfocus()
    end)
    Q.step(10, function() S.inkN = 0 end)
    S.until1(3, 120, function() local w = C.win; return w ~= nil and w._ghost == true and S.inkN > 0 end, function(ok)
        local w = S.w()
        if not w then Q.check(false, "5 ghost (" .. TH.say .. "): the window is open", "no window"); return end
        local a = nil
        pcall(function() a = w:_surfaceAlpha(ZeD.T) end)
        Q.check(ok and w._ghost == true and S.near(a, 0.15, 0.001) and S.near(C.GHOST_A, 0.15, 0.001),
            "5 ghost (" .. TH.say .. "): pinned, the pointer off it, not typing: ghosted, its surfaces at 0.15",
            string.format("theme %s; _ghost %s; _surfaceAlpha %s; C.GHOST_A %s; pinned %s, typing %s, pad focus %s, moving %s",
                tostring(ZeD.currentBase), tostring(w._ghost), tostring(a), tostring(C.GHOST_A), tostring(w.pinned),
                tostring(w.input and w.input:isFocused()), tostring(w.joyfocus ~= nil), tostring(w.moving)))
        Q.check(ok and S.inkN > 0, "5 ghost (" .. TH.say .. "): its words drawn whole with the 1-unit edge (C.inkText)",
            "C.inkText calls since the theme settled: " .. tostring(S.inkN))
    end)
    S.shot("mp_chatwin_ghost_" .. TH.tag .. "_" .. S.sizeTag(), "the pinned chat window ghosted, the pointer off it (" .. TH.say .. ")")
end
function S.build5()
    Q.step(4, function()
        if S.dead then return end
        S.over = false
        local ok, e = pcall(S.pressKey)
        if not ok then Q.say("NOTE the chat key press: " .. tostring(e)) end
    end)
    S.until1(3, 300, function() local w = C.win; return S.vis(w) and w._rollRect ~= nil end, function(ok)
        Q.check(ok and S.w() ~= nil, "5 ghost: the chat key opens the window again")
        S.inkOrig = C.inkText
        C.inkText = function(...)
            S.inkN = S.inkN + 1
            return S.inkOrig(...)
        end
    end)
    S.pinBy("5 ghost", true)
    for _, TH in ipairs(S.THEMES) do S.ghostTheme(TH) end
    -- the pointer on it: back to full on the next frame
    Q.step(2, function()
        if S.dead then return end
        S.w()   -- (the window may be a new one since the chat key opened it again: its pointer hooked before the frame)
        S.over = true
    end)
    Q.step(1, function() S.inkN = 0 end)
    Q.step(1, function()
        if S.dead then return end
        local w = S.w()
        local a = nil
        if w then pcall(function() a = w:_surfaceAlpha(ZeD.T) end) end
        -- (Nov 24: still ghosted on two runs: the detail says whether the pointer stand-in is on this window)
        local hooked = w ~= nil and rawget(w, "isMouseOver") == S.fakeOver
        local over, now = nil, nil
        if w then pcall(function() over = w:isMouseOver() end); pcall(function() now = w:_ghostNow() end) end
        Q.check(w ~= nil and w._ghost == false and S.inkN == 0, "5 ghost: the pointer on it brings it back at once (the next frame)",
            "_ghost " .. tostring(w and w._ghost) .. ", _surfaceAlpha " .. tostring(a) .. ", C.inkText calls " .. tostring(S.inkN)
            .. "; stand-in on it " .. tostring(hooked) .. ", isMouseOver " .. tostring(over) .. ", _ghostNow " .. tostring(now)
            .. ", same window " .. tostring(w == C.win))
        S.over = false
    end)
    -- a press on a tab of the ghosted window lands
    S.until1(2, 60, function() local w = C.win; return w ~= nil and w._ghost == true end, function(ok)
        local w = S.w()
        if not (ok and w) then Q.check(false, "5 ghost: ghosted again before the press", "_ghost " .. tostring(w and w._ghost)); return end
        local hit = nil
        for _, t in ipairs(w._tabHits or {}) do
            if t.id ~= C.tab and not hit then hit = t end
        end
        if not hit then Q.skip("5 ghost: a press on a tab of the ghosted window", "only one tab shows"); return end
        S.tab0, S.tabTo = C.tab, hit.id
        local px, py = hit.x + math.floor(hit.w / 2), hit.y + math.floor(hit.h / 2)
        w:onMouseDown(px, py)
        w:onMouseUp(px, py)
        Q.check(C.tab == S.tab0 and w._ghost == false, "5 ghost: a press on a tab of the ghosted window only lifts the ghost (the tab stays)",
            "tab " .. tostring(S.tab0) .. " to " .. tostring(C.tab) .. " (pressed " .. tostring(hit.id) .. "); ghosted " .. tostring(w._ghost))
        -- (the second press, the window whole now: it lands)
        w:onMouseDown(px, py)
        w:onMouseUp(px, py)
        Q.check(C.tab == hit.id, "5 ghost: a second press on the tab lands (the tab changes)",
            "tab " .. tostring(S.tab0) .. " to " .. tostring(C.tab) .. " (pressed " .. tostring(hit.id) .. ")")
        if C.tab ~= S.tab0 then C.tab = S.tab0 end   -- (the tab as found)
    end)
end

-- ===================================================================== 6 the saved line
function S.build6()
    Q.step(4, function()
        if S.dead then return end
        local l = S.firstLine()
        local t = S.fields(l)
        Q.check(t[1] == "v2" and #t == 8 and tonumber(t[2]) ~= nil and tonumber(t[5]) ~= nil and (t[7] == "0" or t[7] == "1"),
            "6 saved line: after the run's moves Lua/ZeD_chatwin.txt starts with \"v2 \" and holds x y w h tab rolled pinned",
            tostring(l))
        if C.win then C.win:close() end
    end)
    Q.step(4, function()
        if S.dead then return end
        S.writeFile({ S.OLD })
        C._savedPlace = nil
        local okR, x = pcall(C._readPlace)
        Q.check(okR and x == nil, "6 saved line: an old line without \"v2\" reads as no place (C._readPlace returns nil)",
            "the file: \"" .. tostring(S.firstLine()) .. "\"")
        local ok, e = pcall(S.pressKey)
        if not ok then Q.say("NOTE the chat key press: " .. tostring(e)) end
    end)
    S.until1(3, 300, function() local w = C.win; return S.vis(w) and w._rollRect ~= nil end, function(ok)
        local w = S.w()
        if not Q.check(ok and w ~= nil, "6 saved line: the chat key opens the window after the old line") then return end
        local g = S.geo(w)
        local ex, ey, why = S.expectPlace(w)
        Q.check(ex ~= nil and S.near(g.x, ex) and S.near(g.y, ey) and S.near(g.w, S.px(360)),
            "6 saved line: so the window opens at the default place (not the old line's 120,400 440 wide)",
            string.format("window %s, expected %s,%s %d wide; %s", S.gText(g), tostring(ex), tostring(ey), S.px(360), tostring(why)))
    end)
    S.until1(3, 300, function() local l = S.firstLine(); return l ~= nil and l:sub(1, 3) == "v2 " end, function(ok)
        local okR, x = pcall(C._readPlace)
        Q.check(ok and okR and x ~= nil, "6 saved line: no place only once: the open window writes a v2 line, which reads as a place",
            "the file: \"" .. tostring(S.firstLine()) .. "\", C._readPlace x " .. tostring(x))
    end)
    Q.step(2, function() Q.say("TODO a window pinned at quit reopens once on the next join, rolled as it was: needs a rejoin (zedqa_run.ps1 -Mp twice)") end)
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    S.park(false)
    S.over = false
    if S.inkOrig then C.inkText = S.inkOrig end
    local f = S.found
    if f.base and (ZeD.currentBase ~= f.base or ZeD.currentAccent ~= f.accent or ZeD.currentSize ~= f.size) then
        pcall(ZeD.applyTheme, f.base, f.accent, f.size)
    end
    S.unfocus()
    if S.jd and C.win and S.jd.focus == C.win then pcall(setJoypadFocus, 0, nil) end
    if C.win then C.win:close() end
    S.unhook()
    if f.tab then C.tab = f.tab end
    if f.open then
        local w = C.open(false)
        if w and f.g then
            w:setX(f.g.x); w:setY(f.g.y); w:setWidth(f.g.w); w:setHeight(f.g.h)
            if f.shaded then w:setWindowShaded(true) end
            w.pinned = f.pinned and true or false
            C.savePlace(w)   -- (so its next save sees nothing new and leaves the file as found)
        end
    end
    if f.had then S.writeFile(f.file)
    else
        S.writeFile({})
        Q.say("NOTE there was no Lua/ZeD_chatwin.txt before the run: an empty one is left (it reads as no place, the same as none); delete it by hand for byte for byte")
    end
end
function S.buildPutBack()
    Q.mark()
    Q.step(5, function() S.putBack() end)
    Q.waitMs(2500)   -- (a window left open saves its place every 2 s: the file must still be as found after that)
    Q.step(2, function()
        local f = S.found
        if not f.recorded then
            Q.skip("put back", "nothing was changed (the chat window was not loaded)")
            return
        end
        local now = S.readFile()
        Q.check(S.sameLines(now, f.had and f.file or {}),
            "put back: Lua/ZeD_chatwin.txt as found",
            "now \"" .. table.concat(now or {}, "\\n") .. "\", found " .. (f.had and ("\"" .. table.concat(f.file, "\\n") .. "\"") or "none"))
        local w = C.win
        Q.check(S.vis(w) == (f.open == true), "put back: the chat window " .. (f.open and "open" or "shut") .. " as found",
            "visible " .. tostring(S.vis(w)))
        Q.check((w == nil or (w.pinned and true or false) == (f.pinned == true)) and (w == nil or (w.windowShaded and true or false) == (f.shaded == true)),
            "put back: pinned and rolled as found (pin off on a QA character)",
            "pinned " .. tostring(w and w.pinned) .. ", rolled " .. tostring(w and w.windowShaded))
        Q.check(C.tab == f.tab, "put back: the chat's tab as found", tostring(C.tab))
        Q.check(ZeD.currentBase == f.base and ZeD.currentAccent == f.accent and ZeD.currentSize == f.size,
            "put back: the theme as found", tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize))
        Q.check(#S.hooked == 0 and (S.inkOrig == nil or C.inkText == S.inkOrig) and S.parked == nil
            and not (w and w.input and w.input:isFocused()),
            "put back: the window's own isMouseOver and C.inkText, the pointer the game's, the typing line unfocused")
        local e1 = S.errN()
        if S.err0 and e1 then
            Q.check(e1 == S.err0, "the chat window run ran with no Lua error", (e1 - S.err0) .. " new")
        else
            Q.skip("the chat window run's Lua error count", "the game's Lua error count cannot be read here")
        end
    end)
end

-- ===================================================================== the run
Q.step(10, function() S.start() end)
S.build1()
S.build2()
S.build3()
S.build4()
S.build5()
S.build6()
S.buildPutBack()
Q.start()
