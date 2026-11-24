-- ZeDUI/tools/qa/vk6_errbox.lua  (Nov 22 2026, QA; tag vk6_err): the in-game proof of the error box, Build's 2db43d57a
-- (branch errbox), merged in main at 0fb94f8ff. Read with ZeDUI/HANDOFF_errbox_qa_20261122.md (its 11 in-game checks).
-- The director: "If we can hide it, hook it, and make our own, can remove our message icon over there in the bottom
-- right corner." Then: "hide it. Use the trick."
-- Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua. grep "ZEDQA vk6_err". Manifest: vk6.txt.
--
-- THE DELIBERATE ERRORS. Three Lua errors are raised on purpose, each in a one-frame Events.OnTick handler that
-- removes itself (zedqa_messages.lua's way): uncaught, so the game logs each as a Lua error and would draw its red
-- ERROR box. Every one names "qaErrbox" (the handler's name and the field it indexes), and vk6.txt says
-- expect=qaErrbox, so the runner does not count them. The game's ones are filed in Messages under the game (their stack
-- names no mod); the ZeD one is raised inside ZeD's own code (ZeD.Belt.isZeDSource's tostring, handed a table whose
-- __tostring fails), so its stack names ZeD-GUI and it is filed as ZeD's.
--
-- How to read the log: the proofs are the lines that start "EB"; each FAILS on code without the error box (no
-- ZeD.ErrorBox, the note on the belt, the keys left of the bag button) and PASSES on 0fb94f8ff. A part that cannot
-- be staged FAILS with "(staging)" in its words. "NOTE" lines are readings, "SKIP" lines say plainly what a script
-- cannot do here. The pictures (Zomboid/Screenshots/vk6_*.png) are the proof a script cannot read: LOOK AT THEM.
--
-- The checks (the handoff's numbers):
--   EB 1a  Offscreen UI on (the default): the first error is logged (the game's error count rose) and filed under the
--          game. EB 1b  The clip that hides the red box ran on every frame after it (E.postDraw, the last OnPostUIDraw
--          handler, with E.hideWanted() true). EB 1c  The whole UI still draws, every frame: the belt, both ZeD
--          windows, the watch (when shown), the moodles, the hint strip (when shown), the corner notice (each one's
--          prerender counted, pass-through). Picture vk6_err_offscreen: NO red box at the bottom right, ZeD's notice
--          there, every window, the belt, the moodles, the radio on in his hand and his spoken line over his head (the
--          world's text, drawn before the UI, as the radio's and TV's lines are).
--          NOTE: an OnPostUIDraw handler added now (after the game's first tick) runs after the clip: the handoff's
--          known side effect (other mods' late handlers are clipped), read and said.
--   EB 1d  Offscreen UI off (getCore():setOptionUIFBO(false), live, as the Options screen applies it): another error;
--          the clip on every frame; the UI still draws. Picture vk6_err_fbo_off.
--   EB 1e  "Lock cursor to window" on with the offscreen UI off: no clip (E.hideWanted() false, E.postDraw sets
--          nothing), the notice stands left of the game's box. Picture vk6_err_lockcursor: the game's red box shows,
--          the pointer is visible. EB 1f  The same lock with the offscreen UI on: the clip again.
--   EB 2   The main menu: SKIP (a script in game cannot reach it; E.hideWanted() is false outside the in-game state
--          by its first test, read from the code; the main menu run's zedqa_menu_* scripts would need a new one).
--   EB 3   The Display FPS key's Lua side (ISFPS.onKeyPressed with the bound key, the game's own mirror): the clip is
--          off while ISFPS.start, the notice left of the game's box; the key again, the clip back. NOTE: the game's
--          Java graph is not driven by a script (no key event reaches Java); the graph itself is by hand.
--   EB 4a  "Error box" on (ZeD setup, Safe mode's row: screenErrorBox On): the clip off, the notice left of the game's
--          box (ZeD.ErrorBox.GAME_BOX_W). Picture vk6_err_box_back: the game's box AND the notice beside it.
--   EB 4b  Full safe mode (the Safe mode option On, as rt_system does): no notice at all, with something unread.
--   EB 5a  The game's error: the notice shows, its count drawn gray (the theme's textDim, not the danger red).
--   EB 5b  A click on the notice (its own onMouseDown) opens Messages.
--   EB 5c  ZeD's own error: filed under ZeD (B.isZeDSource), the count drawn red (T.danger). Picture vk6_err_zed.
--   EB 5d  A note (a Messages line of a test source): the count in the accent color; Messages' balloons come out of
--          the notice (ZeD.MessagesWindow.noticeAnchor answers ZeD.ErrorBox.anchor's point, pointing).
--   EB 5e  All read: the notice goes by itself about six seconds after the note came (E.SHOW_MS, 4.5 to 8 s), in the
--          corner (Nov 23 2026: the belt away; on the row it stays while the belt draws).
--   EB 6   The pad (Nov 23 2026: the notice is a stop in the belt's walk): on the box before it (the last speed key),
--          Right lands on the notice (its row box, E.padOn, its pad mark drawn, its hint asked), Left back to the same
--          box, Right and A open Messages (the pad leaves the belt), Up leaves, B leaves.
--   EB 7   The belt row: five speed keys (none on a server) after the belt, then the Messages notice's place (Nov 23
--          2026: single player's row ends with it), no old "lamp" box (vk4_belt.lua BELT 1 to 4 read the whole row in
--          Full and Lite; bl_side.lua the groups' gaps).
--   EB 8   Driving (the prelude's pickup, the driver's seat): the belt hides and the five keys keep their x at the
--          same spot (keysOnly), lifted just above the dash where their home is on it (dashkeys, Nov 22: the lowest
--          key's bottom 6 units over the dash's top), clear of the dash; a key pressed there sets the speed. A
--          passenger keeps the whole belt.
--   EB 9   The buckle (Full): a click opens the Character window on Info, a second click closes it; open on another
--          tab, a click goes to Info; the pointer on it asks the hint "Info" (IGUI_XP_Info); Lite has no buckle.
--   EB 10  The tour's Guide step's target is the notice's place (ZeD.ErrorBox.rect()). rt_tour.lua walks it.
--   EB 11  Split screen: a split speed strip on show (a stand-in for ZeD.SplitSpeed._instance: a second player cannot
--          be staged by a script) puts the notice left of it (E.rect()).
--   EB 12  The error marker (Build's errmark branch; the director's Nov 22 marker): on a build without it
--          (no ZeD.ErrorBox.markSize, main) every EB 12 check is a SKIP with that reason and the rest still runs.
--          EB 12a ZeD's own error: the marker rises (ZeD.ErrorBox._marker shown, _mk.kind "ours", the count).
--          EB 12b fully up its y is the screen's height - (markH + T.px(10)) (markH: E.markSize()'s second value),
--          under the notice and its width, and the notice's y is its rest y - markH. Picture vk6_err_marker: the
--          red marker fully up under the lifted notice. EB 12c the hint strip draws over it (before it in the
--          game's UI list). EB 12d a click on the marker opens Messages. EB 12e gone at about 4 s (0.5 up, 3 held,
--          0.5 down), the notice back at rest. EB 12f the game's error: kind "others" (gray). EB 12g two errors 2 s
--          apart: still fully up at 3.6 s. EB 12h an error while it falls: back up from where it is, no jump, never
--          down in between. EB 12i a note: no marker (_mk.phase nil throughout).
--          The EB checks that read the notice's place after an error read the rest place (E.rect) or wait until
--          the marker is down first (EB 5d's anchor).
-- (Nov 23 2026, QA, Build's fix/beltrow2 on main 99d56a202, the director's "Belt, space, time, space, messages, chat":
-- the notice stands on player one's belt row after the speed keys, shown all the time the belt draws, and falls back to
-- the screen's bottom right corner while the belt is away. The corner's checks, EB 1e to 4a, 5e and 11, put the belt
-- away with the game's Toggle UI flag alone (ISUIHandler.allUIVisible false, the belt's own wanted() test; H.away), so
-- the rest of the UI still draws; their words are unchanged. EB 12b: the marker now ends where the notice's bottom
-- rests, on the row or in the corner: fully up its y is the notice's rest y + its size - markH (in the corner that is
-- the screen's height - (markH + T.px(10)) as before), the notice lifted by markH. EB 12c: the belt draws over it too
-- (the marker goes to the back of the UI list at each start). EB 6, EB 7: the notice is the row's box "notice".)
--   Side effects not staged: the sleeping overlay (vanilla draws nothing in OnSleepingTick; sleeping is not staged),
--   ActiveMods.renderUI and the debug overlays (debug options only) are SKIPs with the reason.
--
-- Safety and the put-back (also when a step throws or the time runs out): the spies gone (E.postDraw, the counted
-- prerenders, the notice's badge watch, ZeD.Focus.mark, ZeD.Atoms.requestHint, the late OnPostUIDraw handler); the
-- offscreen UI and the cursor lock as found (live values, never saved); Error box, Safe mode and Style option values
-- as found; ISFPS.start as found; Messages: every error source as found (the run's error entries gone, the error
-- places file written again from them), the test note gone, every read mark as found, the balloons as found, the
-- Messages window open or shut as found; the radio out of his hand and taken back; the car taken away and him back where
-- he was; the windows open or shut as found; the pad's focus; the game speed; the Toggle UI flag. No option is saved; the files written
-- are the pictures (and ZeD's own error places file, rewritten as found).
-- Not run in game yet; parse-checked with the game's Kahlua compiler (KCheck).

if not (RT and RT.make) then
    print("ZEDQA vk6_err ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk6_err VERDICT FAIL 1")
    print("ZEDQA vk6_err DONE")
    return
end

local Q = RT.make("vk6_err")
Q.maxMs = 780000   -- (thirteen minutes, then the put-back; the manifest gives 900 s)
local S = { p = RT.p, pn = RT.pn, was = {}, k = {}, cnt = {}, fr = 0 }
local H = {}
S.Z = ZeD or {}
S.E = S.Z.ErrorBox
S.M = S.Z.Messages
S.MW = S.Z.MessagesWindow
S.B = S.Z.Belt
S.St = S.Z.Settings
S.SRC = "ZeDQA vk6_err"
S.CAR = "Base.PickUpTruck"

-- ===================================================================== small things
function H.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
function H.near(a, b) return a ~= nil and b ~= nil and math.abs(a.r - b.r) < 0.02 and math.abs(a.g - b.g) < 0.02 and math.abs(a.b - b.b) < 0.02 end
function H.rgb(c) if not c then return "none" end; return string.format("%.2f %.2f %.2f", c.r or 0, c.g or 0, c.b or 0) end
function H.core() return getCore() end
function H.sw() return getCore():getScreenWidth() end
function H.sh() return getCore():getScreenHeight() end
function H.hud() local h = nil; pcall(function() h = ZeD.Belt.getHUD(S.pn) end); return h end
function H.note() return S.E and S.E._note or nil end
function H.noteShown() local el = H.note(); return el ~= nil and el:getIsVisible() end
function H.hide() local v = false; pcall(function() v = S.E.hideWanted() end); return v and true or false end
function H.errCount() local n = 0; pcall(function() n = getLuaDebuggerErrorCount() end); return n or 0 end
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.optSet(o, v) if o and v ~= nil then pcall(function() if o:getValue() ~= v then o:setValue(v) end end) end end
function H.errOpt() return S.St and S.St.screenOptions and S.St.screenOptions.errorbox or nil end
function H.safeOpt() return S.St and S.St.safeModeOption or nil end
function H.styleOpt() return S.St and S.St.lookStyleOption or nil end
function H.safeOn() local v = false; pcall(function() v = ZeD.Safe.on() end); return v and true or false end
function H.lite() local v = false; pcall(function() v = ZeD.Settings.lite() end); return v and true or false end
function H.charOpen() local o = false; pcall(function() o = ZeD_CharacterWindow.isOpen(S.pn) end); return o and true or false end
function H.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function H.none() return not H.charOpen() and not H.worldOpen() end
function H.shutAll()
    if H.charOpen() and H.worldOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn); return end
    if H.charOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn) end
    if H.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
end
function H.msgWin() local w = nil; pcall(function() w = ZeD.MessagesWindow.get(S.pn) end); return w end
function H.msgOpen() local w = H.msgWin(); local v = false; if w then pcall(function() v = w:isReallyVisible() end) end; return v and true or false end
function H.msgClose() local w = H.msgWin(); if w then pcall(function() if w:isReallyVisible() then w:close() end end) end end
function H.joy() local jd = nil; pcall(function() jd = JoypadState.players[S.pn + 1] end); return jd end
function H.shot(name)
    local ok, e = pcall(function() getCore():TakeFullScreenshot("vk6_" .. name .. ".png") end)
    if ok then Q.say("NOTE picture Zomboid/Screenshots/vk6_" .. name .. ".png") else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
end
-- the error marker (Build's errmark): its state and element, nil on a build without it
function H.mk() return S.E and S.E._mk or nil end
function H.mkEl() return S.E and S.E._marker or nil end
function H.mkPhase() local k = H.mk(); if k then return k.phase end; return nil end
function H.mkShown() local m = H.mkEl(); return m ~= nil and m:getIsVisible() end
-- down and hidden (always true on a build without the marker)
function H.mkDown() if not S.mkOn then return true end; return H.mkPhase() == nil and not H.mkShown() end
-- where a UI element stands in the game's UI list (the draw order: a later one draws over), or nil
function H.uiIndex(el)
    if not (el and el.javaObject) then return nil end
    local ui = UIManager.getUI()
    if not ui then return nil end
    for i = 0, ui:size() - 1 do if ui:get(i) == el.javaObject then return i end end
    return nil
end
-- waits by the clock: cond() every frame from the start, at most ms; fn(ok)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        st.t = st.t or getTimestampMs()
        local okC, r = pcall(cond)
        if okC and r then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- the global pointer read answering (gx, gy) for fn only
function H.atPointer(gx, gy, fn)
    local ox, oy = getMouseX, getMouseY
    getMouseX = function() return gx end
    getMouseY = function() return gy end
    local ok, err = pcall(fn)
    getMouseX, getMouseY = ox, oy
    return ok, err
end
-- (Nov 23 2026, Build's fix/beltrow2) the belt away (on) or back (off) by the game's Toggle UI flag alone,
-- ISUIHandler.allUIVisible (the belt's own wanted() test): the notice then stands in the corner, the rest of the UI
-- still draws. The flag found is kept once and put back by the put-back too.
function H.away(on)
    if not ISUIHandler then return false end
    if on then
        if not S.k.awaySet then S.was.ui = ISUIHandler.allUIVisible; S.k.awaySet = true end
        ISUIHandler.allUIVisible = false
        return true
    end
    if S.k.awaySet then ISUIHandler.allUIVisible = S.was.ui; S.k.awaySet = nil end
    return true
end
-- true while the notice's place is on the belt row (ZeD.ErrorBox.rect()'s fourth value)
function H.onRow()
    if not (S.E and S.E.rect) then return false end
    local ok, _, _, _, r4 = pcall(S.E.rect)
    return ok and r4 == true
end
-- the notice's box on the belt row: its index in hud._boxes, or nil
function H.noticeIdx(hud)
    for i, b in ipairs((hud and hud._boxes) or {}) do if b.kind == "notice" then return i end end
    return nil
end

-- ===================================================================== Messages: the error sources and the read marks
-- each error source's item count (the run's errors are found by the count's rise)
function H.errCounts()
    local out = {}
    for name, s in pairs((S.M and S.M.sources) or {}) do
        if type(s) == "table" and s.kind == "err" then
            local it = s.items and s.items[1]
            out[name] = (it and it.count) or 0
        end
    end
    return out
end
-- the error sources whose count rose since `before`: "name +n" words, and whether one of them is ZeD's
function H.risen(before)
    local words, ours, others = {}, false, false
    for name, n in pairs(H.errCounts()) do
        local was = before[name] or 0
        if n > was then
            local z = false
            pcall(function() z = ZeD.Belt.isZeDSource(name) end)
            if z then ours = true else others = true end
            words[#words + 1] = tostring(name) .. " +" .. (n - was) .. (z and " (ZeD's)" or "")
        end
    end
    return table.concat(words, ", "), ours, others
end
-- an error source as found, kept by reference: its item's counts and lists (shallow, so the places keep their
-- identity) and each place's own count, put back as they were
function H.errSnap(s)
    local it = s.items and s.items[1]
    local function sh(t) local o = {}; for k, v in pairs(t or {}) do o[k] = v end; return o end
    local snap = { s = s, it = it }
    if type(it) == "table" then
        snap.count, snap.read = it.count, it.read
        snap.texts, snap.firsts, snap.whens = sh(it.texts), sh(it.firsts), sh(it.whens)
        snap.placeOrder, snap.places = sh(it.placeOrder), sh(it.places)
        snap.pv = {}
        for _, p in pairs(it.places or {}) do
            if type(p) == "table" then snap.pv[#snap.pv + 1] = { p = p, count = p.count, last = p.last, text = p.text } end
        end
    end
    return snap
end
function H.errBack(snap)
    local it = snap.it
    if type(it) ~= "table" then return end
    it.count, it.read = snap.count, snap.read
    it.texts, it.firsts, it.whens = snap.texts, snap.firsts, snap.whens
    if it.placeOrder ~= nil or #snap.placeOrder > 0 then it.placeOrder = snap.placeOrder end
    if it.places ~= nil or #snap.pv > 0 then it.places = snap.places end
    for _, v in ipairs(snap.pv) do v.p.count, v.p.last, v.p.text = v.count, v.last, v.text end
end
function H.markAllRead()
    for _, s in pairs((S.M and S.M.sources) or {}) do
        for _, it in ipairs((type(s) == "table" and s.items) or {}) do
            if type(it) == "table" and not it.read then
                it.read = true
                if not S.wasUnreadSeen[it] then S.wasUnreadSeen[it] = true; S.wasUnread[#S.wasUnread + 1] = it end
            end
        end
    end
end
-- a deliberate error, uncaught, in a one-frame OnTick handler that removes itself (marker in its name and message)
function H.raiseGame(which)
    S.k.raised = (S.k.raised or 0) + 1
    if which == "fbo" then
        local function qaErrboxFboOff() Events.OnTick.Remove(qaErrboxFboOff); local t = nil; return t.qaErrboxFboOff end
        Events.OnTick.Add(qaErrboxFboOff)
    else
        local function qaErrboxGame() Events.OnTick.Remove(qaErrboxGame); local t = nil; return t.qaErrboxGame end
        Events.OnTick.Add(qaErrboxGame)
    end
end
-- (EB 12g, 12h, Nov 22 2026: Messages reads the game's errors on its own two-second clock (ZeD_Messages.lua frame,
-- nextErr), so an error raised 2 s into the hold was filed up to 2 s later, after the hold had ended: the qaLog showed
-- every entry read, separator and exception, only late. The marker's checks are about a filed error, so these steps
-- read the errors at once, as that clock's next read would, every frame while they wait; readErrors is a no-op while
-- the game's count has not moved.)
function H.readNow()
    local M = ZeD.Messages
    if M and M.readErrors then pcall(M.readErrors) end
end
-- ZeD's own: raised inside ZeD's code (ZeD.Belt.isZeDSource's tostring), so its stack names ZeD-GUI
function H.raiseZeD()
    S.k.raised = (S.k.raised or 0) + 1
    local function qaErrboxZeDText() local t = nil; return t.qaErrboxZeD end
    local function qaErrboxZeD()
        Events.OnTick.Remove(qaErrboxZeD)
        ZeD.Belt.isZeDSource(setmetatable({}, { __tostring = qaErrboxZeDText }))
    end
    Events.OnTick.Add(qaErrboxZeD)
end

-- ===================================================================== the spies (pass-through)
-- the frame clock: every drawn frame, and where the clip's count stood at the frame's start
function H.frameTick()
    S.fr = S.fr + 1
    if S.post then S.post.atPre = S.post.n end
end
-- E.postDraw counted: each call, and each call that set the clip (E.hideWanted() true)
function H.postSpy(on)
    local E = S.E
    if on then
        if S.post or not E then return end
        S.post = { raw = rawget(E, "postDraw"), n = 0, clip = 0, atPre = 0, late = 0, lateAfter = 0 }
        local base = E.postDraw
        E.postDraw = function(...)
            S.post.n = S.post.n + 1
            local okH, h = pcall(E.hideWanted)
            if okH and h then S.post.clip = S.post.clip + 1 end
            return base(...)
        end
        -- (a handler added now, after the game's first tick: where it runs against the clip)
        S.lateFn = function()
            S.post.late = S.post.late + 1
            if S.post.n > S.post.atPre then S.post.lateAfter = S.post.lateAfter + 1 end
        end
        Events.OnPostUIDraw.Add(S.lateFn)
        return
    end
    if S.lateFn then pcall(function() Events.OnPostUIDraw.Remove(S.lateFn) end); S.lateFn = nil end
    if S.post and E then E.postDraw = S.post.raw end
    S.post = nil
end
-- an element's prerender counted (an instance field over the class's method)
function H.count(name, el)
    if not el or S.cnt[name] then return end
    local base = el.prerender
    if type(base) ~= "function" then return end
    local c = { el = el, raw = rawget(el, "prerender"), n = 0 }
    S.cnt[name] = c
    el.prerender = function(self, ...)
        c.n = c.n + 1
        return base(self, ...)
    end
end
function H.countAll()
    H.count("belt", H.hud())
    H.count("Character window", RT.cw())
    H.count("World window", RT.ww())
    local wi = nil
    pcall(function() wi = ZeD.Watch.getInstance() end)
    H.count("watch", wi)
    local ml = nil
    pcall(function() ml = ZeD.Moodles.getLayer(S.pn) end)
    H.count("moodles", ml)
    local hs = nil
    pcall(function() hs = ZeD.HintStrip._huds[S.pn] end)
    H.count("hint strip", hs)
end
function H.countOff()
    for _, c in pairs(S.cnt) do c.el.prerender = c.raw end
    S.cnt = {}
end
function H.countReset() for _, c in pairs(S.cnt) do c.n = 0 end; S.fr0 = S.fr end
-- every counted element that is on screen drew on (nearly) every frame since the reset; words
function H.drewAll()
    local frames = S.fr - (S.fr0 or 0)
    local words, bad = {}, {}
    for name, c in pairs(S.cnt) do
        local vis = false
        pcall(function() vis = c.el:isReallyVisible() end)
        if vis then
            words[#words + 1] = name .. " " .. c.n
            if c.n < math.floor(frames * 0.8) then bad[#bad + 1] = name .. " drew " .. c.n .. " of " .. frames .. " frames" end
        else
            words[#words + 1] = name .. " (not on screen)"
        end
    end
    local b = S.badge
    if b then
        words[#words + 1] = "notice " .. b.n
        if H.noteShown() and b.n < math.floor(frames * 0.8) then bad[#bad + 1] = "the notice drew " .. b.n .. " of " .. frames .. " frames" end
    end
    return #bad == 0 and frames > 0, frames .. " frames: " .. table.concat(words, ", ") .. ((#bad > 0) and ("; WRONG: " .. table.concat(bad, "; ")) or "")
end
-- the notice's prerender watched: frames drawn, and the count's badge color (the last drawRect before the count's
-- drawText), as vk3_screen.lua K3 #42 read the belt's note
function H.badgeOn()
    local el = H.note()
    if S.badge or not el then return end
    local b = { el = el, pr = rawget(el, "prerender"), dr = rawget(el, "drawRect"), dt = rawget(el, "drawText"), n = 0 }
    S.badge = b
    local bp, br, bt = el.prerender, el.drawRect, el.drawText
    el.prerender = function(self, ...)
        b.n = b.n + 1
        b.inP, b.rect = true, nil
        local ok, e = pcall(bp, self, ...)
        b.inP = false
        if not ok then b.err = tostring(e) end
    end
    el.drawRect = function(self, x, y, w, h, a, r, g, bb, ...)
        if b.inP then b.rect = { r = r, g = g, b = bb } end
        return br(self, x, y, w, h, a, r, g, bb, ...)
    end
    el.drawText = function(self, t, ...)
        if b.inP and b.rect then b.last = { text = tostring(t), c = b.rect, at = getTimestampMs() } end
        return bt(self, t, ...)
    end
end
function H.badgeOff()
    local b = S.badge
    if not b then return end
    S.badge = nil
    b.el.prerender, b.el.drawRect, b.el.drawText = b.pr, b.dr, b.dt
end
function H.badgeSince(t) local b = S.badge; local l = b and b.last; if l and l.at >= t then return l end; return nil end
-- ZeD.Focus.mark and ZeD.Atoms.requestHint watched for the notice and the belt (the pad's mark, the hints)
function H.markSpy(on)
    if on then
        if S.mk then return end
        S.mk = { mark = ZeD.Focus.mark, hint = ZeD.Atoms.requestHint, marks = 0, hints = {} }
        local m0, h0 = S.mk.mark, S.mk.hint
        ZeD.Focus.mark = function(panel, ...)
            if S.mk and panel == H.note() then S.mk.marks = S.mk.marks + 1 end
            return m0(panel, ...)
        end
        ZeD.Atoms.requestHint = function(owner, key, text, ...)
            if S.mk and (owner == H.note() or owner == H.hud()) then S.mk.hints[tostring(key)] = tostring(text) end
            return h0(owner, key, text, ...)
        end
        return
    end
    if not S.mk then return end
    ZeD.Focus.mark, ZeD.Atoms.requestHint = S.mk.mark, S.mk.hint
    S.mk = nil
end

-- ===================================================================== start: what was found
Q.step(3, function()
    local dead = true
    pcall(function() dead = S.p:isDead() end)
    if dead then S.dead = true; Q.check(false, "the character is alive (staging)"); return end
    local E = S.E
    local ready = E ~= nil and E.hideWanted ~= nil and E.postDraw ~= nil and E.rect ~= nil and E.anchor ~= nil and E.press ~= nil
        and S.M ~= nil and S.M.sources ~= nil and S.MW ~= nil and S.B ~= nil and S.B.getHUD ~= nil and S.B.isZeDSource ~= nil
        and H.errOpt() ~= nil and H.safeOpt() ~= nil and H.styleOpt() ~= nil and ZeD.T ~= nil and ZeD.Focus ~= nil and ZeD.Atoms ~= nil
        and getLuaDebuggerErrorCount ~= nil
    if not Q.check(ready, "ZeD.ErrorBox, Messages, the belt, the Error box, Safe mode and Style options and the game's error count are there (staging)",
        "ZeD.ErrorBox " .. tostring(E ~= nil) .. ", Error box option " .. tostring(H.errOpt() ~= nil)) then S.dead = true; return end
    if H.safeOn() then S.dead = true; Q.check(false, "safe mode is off in this game (staging)"); return end
    local c = getCore()
    S.was.off = E.off
    S.was.fbo = c:getOptionUIFBO()
    S.was.lock = c:getOptionLockCursorToWindow()
    S.was.err = H.optVal(H.errOpt())
    S.was.safe = H.optVal(H.safeOpt())
    S.was.style = H.optVal(H.styleOpt())
    S.was.fps = ISFPS and ISFPS.start or false
    S.was.char, S.was.world = H.charOpen(), H.worldOpen()
    S.was.msg = H.msgOpen()
    S.was.speed = getGameSpeed()
    S.was.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.was.sec = S.p:getSecondaryHandItem()
    S.was.joy = nil
    local jd = H.joy()
    if jd then S.was.joy = jd.focus end
    S.was.toasts = S.M.toasts
    S.was.split = ZeD.SplitSpeed and ZeD.SplitSpeed._instance or nil
    S.server = (isClient and isClient()) and true or false
    S.mkOn = E.markSize ~= nil and E._mk ~= nil   -- (Build's errmark: the error marker)
    -- every error source as found (the run's errors are filed into them), and the read marks
    S.was.errs = {}
    for name, s in pairs(S.M.sources) do
        if type(s) == "table" and s.kind == "err" then S.was.errs[name] = H.errSnap(s) end
    end
    S.wasUnread, S.wasUnreadSeen = {}, {}
    H.markAllRead()
    S.M.toasts = {}
    H.msgClose()
    E.off = false
    -- (the clip's own conditions as a new player has them: the FPS graph's flag down, the cursor lock off)
    if ISFPS and ISFPS.start then pcall(ISFPS.onKeyPressed, c:getKey("Display FPS")) end
    if S.was.lock then pcall(function() c:setOptionLockCursorToWindow(false) end) end
    if S.was.speed == 0 then pcall(setGameSpeed, 1) end
    H.optSet(H.styleOpt(), 1)
    RT.pairOpen()
    Events.OnPreUIDraw.Add(H.frameTick)
    S.frameOn = true
    Q.say("start: screen " .. H.sw() .. "x" .. H.sh() .. ", ZeD's scale " .. tostring(ZeD.T.scale) .. "; offscreen UI " .. tostring(S.was.fbo)
        .. ", lock cursor " .. tostring(S.was.lock) .. "; Error box " .. tostring(S.was.err) .. ", Safe mode " .. tostring(S.was.safe)
        .. ", Style " .. tostring(S.was.style) .. "; FPS graph " .. tostring(S.was.fps) .. "; the game's error count " .. H.errCount()
        .. "; unread lines set read " .. #S.wasUnread .. "; on a server " .. tostring(S.server) .. "; a pad " .. tostring(jd ~= nil)
        .. "; the error marker " .. tostring(S.mkOn))
end)
H.wait(4000, function() return S.dead or (H.charOpen() and H.worldOpen()) end, function(ok)
    if S.dead then return end
    if not ok then Q.check(false, "both ZeD windows open for the draw count (staging)", "Character " .. tostring(H.charOpen()) .. ", World " .. tostring(H.worldOpen())) end
    S.ok = true
end)

-- ===================================================================== EB 1a-c, 5a: offscreen UI on, the game's error
Q.step(2, function()
    if not S.ok then return end
    if not getCore():getOptionUIFBO() then Q.say("NOTE the offscreen UI is OFF in this game: EB 1a-c read it off, EB 1d again off") end
    H.postSpy(true)
    H.countAll()
    H.badgeOn()
    -- the radio on in his hand and a line over his head (the world's text, drawn before the UI)
    local r = RT.give("Base.RadioRed")
    if r then
        pcall(function() S.p:setSecondaryHandItem(r) end)
        pcall(function() local dd = r:getDeviceData(); if dd then dd:setIsTurnedOn(true) end end)
        S.radio = r
    end
    pcall(function() S.p:Say("QA vk6_err: a line over his head, the world's text") end)
    S.k.before = H.errCounts()
    S.k.n0 = H.errCount()
    S.k.t1 = getTimestampMs()
    H.raiseGame("game")
end)
H.wait(9000, function()
    if not S.ok then return true end
    local _, _, others = H.risen(S.k.before)
    return others and H.badgeSince(S.k.t1) ~= nil
end, function(ok)
    if not S.ok then return end
    local words, ours, others = H.risen(S.k.before)
    local n1 = H.errCount()
    Q.check(ok and n1 > S.k.n0 and others and not ours, "EB 1a: offscreen UI on: the deliberate error is logged (the game's error count rose) and filed under the game",
        "the count " .. S.k.n0 .. " -> " .. n1 .. "; filed: " .. tostring(words))
    H.countReset()
    if S.post then S.post.n, S.post.clip, S.post.late, S.post.lateAfter = 0, 0, 0, 0 end
end)
Q.step(40, function()
    if not S.ok then return end
    local p = S.post
    local frames = S.fr - (S.fr0 or 0)
    Q.check(p ~= nil and H.hide() and p.n >= frames - 1 and p.clip == p.n and p.n > 0,
        "EB 1b: offscreen UI on: the clip that hides the game's red box ran on every frame after the error (E.postDraw, E.hideWanted() true)",
        "frames " .. frames .. ", E.postDraw " .. tostring(p and p.n) .. ", the clip set " .. tostring(p and p.clip) .. ", hideWanted " .. tostring(H.hide()))
    local okD, words = H.drewAll()
    Q.check(okD, "EB 1c: offscreen UI on: after the error the whole UI still draws every frame (belt, both windows, watch, moodles, hint strip, notice)", words)
    if p and p.late > 0 then
        Q.say("NOTE an OnPostUIDraw handler added after the first tick ran after the clip on " .. p.lateAfter .. " of " .. p.late
            .. " frames (the handoff's known side effect: a mod's late handler is clipped)")
    end
    -- EB 5a: the notice for the game's error, gray
    local T = ZeD.T
    local l = H.badgeSince(S.k.t1)
    local tone = nil
    pcall(function() tone = ZeD.Belt.lampTone() end)
    Q.check(H.noteShown() and l ~= nil and tone == "others" and H.near(l.c, T.textDim) and not H.near(l.c, T.danger),
        "EB 5a: the notice shows for the game's error, its count drawn gray (not ZeD's red)",
        "shown " .. tostring(H.noteShown()) .. ", tone " .. tostring(tone) .. ", the count " .. tostring(l and l.text) .. " on " .. H.rgb(l and l.c)
        .. " (gray " .. H.rgb(T.textDim) .. ", red " .. H.rgb(T.danger) .. ")" .. (S.badge and S.badge.err and ("; ERR " .. S.badge.err) or ""))
    H.shot("err_offscreen")
end)

-- ===================================================================== EB 5b: a click on the notice opens Messages
Q.step(4, function()
    if not S.ok then return end
    local el = H.note()
    if not (el and el:getIsVisible()) then S.k.noClick = true; return end
    local w, h = el:getWidth(), el:getHeight()
    S.k.clickOk = pcall(function() el:onMouseDown(math.floor(w / 2), math.floor(h / 2)); el:onMouseUp(math.floor(w / 2), math.floor(h / 2)) end)
end)
H.wait(3000, function() return not S.ok or S.k.noClick or H.msgOpen() end, function(ok)
    if not S.ok then return end
    Q.check(ok and not S.k.noClick and S.k.clickOk and H.msgOpen(), "EB 5b: a click on the notice opens Messages",
        "the notice shown " .. tostring(not S.k.noClick) .. ", Messages open " .. tostring(H.msgOpen()))
    if H.msgOpen() then RT.bounds(Q, "Messages from the notice") end
    H.msgClose()
end)

-- ===================================================================== EB 5c: ZeD's own error, red
Q.step(4, function()
    if not S.ok then return end
    H.markAllRead()
    S.M.toasts = {}
    S.k.before = H.errCounts()
    S.k.t2 = getTimestampMs()
    H.raiseZeD()
end)
H.wait(9000, function()
    if not S.ok then return true end
    local _, ours = H.risen(S.k.before)
    return ours and H.badgeSince(S.k.t2) ~= nil
end, function(ok)
    if not S.ok then return end
    local words, ours = H.risen(S.k.before)
    local T = ZeD.T
    local l = H.badgeSince(S.k.t2)
    local tone = nil
    pcall(function() tone = ZeD.Belt.lampTone() end)
    Q.check(ok and ours and H.noteShown() and tone == "ours" and l ~= nil and H.near(l.c, T.danger),
        "EB 5c: ZeD's own error is filed under ZeD and the notice's count is drawn red",
        "filed: " .. tostring(words) .. "; shown " .. tostring(H.noteShown()) .. ", tone " .. tostring(tone) .. ", the count " .. tostring(l and l.text)
        .. " on " .. H.rgb(l and l.c) .. " (red " .. H.rgb(T.danger) .. ")")
    H.shot("err_zed")
end)

-- ===================================================================== EB 1d: offscreen UI off
Q.step(4, function()
    if not S.ok then return end
    pcall(function() getCore():setOptionUIFBO(false) end)
    S.k.fboSet = true
end)
Q.step(20, function()
    if not S.ok then return end
    S.k.before = H.errCounts()
    S.k.t3 = getTimestampMs()
    S.k.n3 = H.errCount()
    H.raiseGame("fbo")
end)
H.wait(9000, function()
    if not S.ok then return true end
    local _, _, others = H.risen(S.k.before)
    return others
end, function(ok)
    if not S.ok then return end
    S.k.fboErr = ok and H.errCount() > S.k.n3
    H.countReset()
    if S.post then S.post.n, S.post.clip = 0, 0 end
end)
Q.step(40, function()
    if not S.ok then return end
    local p = S.post
    local frames = S.fr - (S.fr0 or 0)
    local fbo = getCore():getOptionUIFBO()
    local okD, words = H.drewAll()
    Q.check(S.k.fboErr and not fbo and H.hide() and p ~= nil and p.n >= frames - 1 and p.clip == p.n and p.n > 0 and okD,
        "EB 1d: offscreen UI off: another error, the clip on every frame, the whole UI still draws",
        "offscreen UI " .. tostring(fbo) .. "; the error logged " .. tostring(S.k.fboErr) .. "; frames " .. frames .. ", E.postDraw " .. tostring(p and p.n)
        .. ", the clip " .. tostring(p and p.clip) .. "; " .. words)
    H.shot("err_fbo_off")
end)

-- ===================================================================== EB 1e, 1f: Lock cursor to window
Q.step(4, function()
    if not S.ok then return end
    pcall(function() getCore():setOptionLockCursorToWindow(true) end)
    S.k.lockSet = true
    -- (Nov 23 2026: the belt away until EB 4a's end, so the notice stands in the corner beside the game's box)
    H.away(true)
end)
Q.step(10, function()
    if not S.ok then return end
    if S.post then S.post.n, S.post.clip = 0, 0 end
end)
Q.step(20, function()
    if not S.ok then return end
    local p = S.post
    local E = S.E
    local x, _, s = E.rect()
    local want = H.sw() - s - ZeD.T.px(E.EDGE_U) - E.GAME_BOX_W
    local lock, fbo = getCore():getOptionLockCursorToWindow(), getCore():getOptionUIFBO()
    Q.check(lock and not fbo and not H.hide() and p ~= nil and p.n > 0 and p.clip == 0 and math.abs(x - want) <= 1,
        "EB 1e: Lock cursor to window with the offscreen UI off: no clip (the game's box and pointer show), the notice left of the game's box",
        "lock " .. tostring(lock) .. ", offscreen UI " .. tostring(fbo) .. ", hideWanted " .. tostring(H.hide()) .. ", E.postDraw " .. tostring(p and p.n)
        .. ", the clip " .. tostring(p and p.clip) .. "; the notice at x " .. H.num(x) .. " (left of the box: " .. H.num(want) .. "), on the row " .. tostring(H.onRow()))
    H.shot("err_lockcursor")
    pcall(function() getCore():setOptionUIFBO(true) end)
end)
Q.step(10, function()
    if not S.ok then return end
    if S.post then S.post.n, S.post.clip = 0, 0 end
end)
Q.step(20, function()
    if not S.ok then return end
    local p = S.post
    local lock, fbo = getCore():getOptionLockCursorToWindow(), getCore():getOptionUIFBO()
    Q.check(lock and fbo and H.hide() and p ~= nil and p.n > 0 and p.clip == p.n,
        "EB 1f: Lock cursor to window with the offscreen UI on: the clip again",
        "lock " .. tostring(lock) .. ", offscreen UI " .. tostring(fbo) .. ", hideWanted " .. tostring(H.hide()) .. ", E.postDraw " .. tostring(p and p.n)
        .. ", the clip " .. tostring(p and p.clip))
    pcall(function() getCore():setOptionLockCursorToWindow(S.was.lock == true) end)
    pcall(function() getCore():setOptionUIFBO(S.was.fbo == true) end)
    S.k.lockSet, S.k.fboSet = nil, nil
end)

-- ===================================================================== EB 2: the main menu
Q.step(2, function()
    Q.skip("EB 2: the main menu after an error: the game's box as before", "a script in game cannot reach the main menu; E.hideWanted() is false "
        .. "outside the in-game state by its first test (isIngameState); the main menu run has no script for it yet")
end)

-- ===================================================================== EB 3: the Display FPS key (its Lua mirror)
Q.step(4, function()
    if not S.ok then return end
    S.k.fpsKey = getCore():getKey("Display FPS")
    S.k.fps0 = ISFPS and ISFPS.start
    if ISFPS and ISFPS.start then pcall(ISFPS.onKeyPressed, S.k.fpsKey) end   -- (off first, as a player would find it)
end)
Q.step(4, function()
    if not S.ok then return end
    pcall(ISFPS.onKeyPressed, S.k.fpsKey)
end)
Q.step(10, function()
    if not S.ok then return end
    local E = S.E
    local x, _, s = E.rect()
    local want = H.sw() - s - ZeD.T.px(E.EDGE_U) - E.GAME_BOX_W
    S.k.fpsOn = (ISFPS and ISFPS.start) and true or false
    S.k.fpsHide = H.hide()
    S.k.fpsX, S.k.fpsWant = x, want
    pcall(ISFPS.onKeyPressed, S.k.fpsKey)
end)
Q.step(10, function()
    if not S.ok then return end
    local off = not (ISFPS and ISFPS.start)
    Q.check(S.k.fpsOn and not S.k.fpsHide and math.abs(S.k.fpsX - S.k.fpsWant) <= 1 and off and H.hide(),
        "EB 3: the Display FPS key (ISFPS.start, the key's Lua mirror): the clip off while the graph is up, the notice left of the game's box; the key again, the clip back",
        "key " .. tostring(S.k.fpsKey) .. "; up " .. tostring(S.k.fpsOn) .. ", hideWanted " .. tostring(S.k.fpsHide) .. ", the notice at x " .. H.num(S.k.fpsX)
        .. " (" .. H.num(S.k.fpsWant) .. "); down " .. tostring(off) .. ", hideWanted " .. tostring(H.hide()))
    Q.say("NOTE EB 3: the game's FPS graph itself is Java, toggled by the real key only: see it by hand")
    if S.k.fps0 and ISFPS and not ISFPS.start then pcall(ISFPS.onKeyPressed, S.k.fpsKey) end
end)

-- ===================================================================== EB 4a: the Error box setting gives the box back
Q.step(4, function()
    if not S.ok then return end
    H.optSet(H.errOpt(), 2)
    S.k.errSet = true
end)
H.wait(2500, function() return not S.ok or not H.hide() end, function(ok)
    if not S.ok then return end
    S.k.boxBack = ok
end)
Q.step(10, function()
    if not S.ok then return end
    local E = S.E
    local el = H.note()
    local x, _, s = E.rect()
    local want = H.sw() - s - ZeD.T.px(E.EDGE_U) - E.GAME_BOX_W
    local ex = el and el:getX() or -1
    Q.check(S.k.boxBack and H.noteShown() and math.abs(x - want) <= 1 and math.abs(ex - want) <= 1,
        "EB 4a: Error box on (Safe mode's row): no clip, the game's box back and the notice left of it",
        "hideWanted " .. tostring(H.hide()) .. "; the notice shown " .. tostring(H.noteShown()) .. " at x " .. H.num(ex) .. " (left of the box: "
        .. H.num(want) .. "), on the row " .. tostring(H.onRow()))
    H.shot("err_box_back")
    H.optSet(H.errOpt(), S.was.err or 1)
    H.away(false)   -- (the belt back: Nov 23 2026)
end)
H.wait(2500, function() return not S.ok or H.hide() end, function(ok)
    if not S.ok then return end
    S.k.errSet = nil
    if not ok then Q.check(false, "Error box off again: the clip back (staging)") end
end)

-- ===================================================================== EB 4b: full safe mode: no notice
Q.step(4, function()
    if not S.ok then return end
    S.M.add(S.SRC, "mods", { head = "QA", text = "vk6_err: a line so the notice would show" })
    S.k.noteMade = true
end)
H.wait(2000, function() return not S.ok or H.noteShown() end, function(ok)
    if not S.ok then return end
    S.k.shownBefore = ok
    H.optSet(H.safeOpt(), 2)
    S.k.safeSet = true
end)
H.wait(3000, function() return not S.ok or H.safeOn() end, function(ok)
    if not S.ok then return end
    S.k.safeOk = ok
end)
Q.step(15, function()
    if not S.ok then return end
    local un = 0
    pcall(function() un = S.M.unread() end)
    Q.check(S.k.shownBefore and S.k.safeOk and not H.noteShown() and not H.hide() and un > 0,
        "EB 4b: full safe mode: no notice at all (with something unread), the game's box its own",
        "the notice shown before " .. tostring(S.k.shownBefore) .. "; safe mode on " .. tostring(H.safeOn()) .. "; the notice shown " .. tostring(H.noteShown())
        .. ", hideWanted " .. tostring(H.hide()) .. ", unread " .. un)
    H.optSet(H.safeOpt(), S.was.safe or 1)
end)
H.wait(3000, function() return not S.ok or not H.safeOn() end, function(ok)
    if not S.ok then return end
    S.k.safeSet = nil
    if not ok then S.ok = false; Q.check(false, "safe mode off again (staging)") end
end)

-- ===================================================================== EB 5d, 5e: a note, the balloons, and the hide
-- (the notice's place is read through E.anchor: the error marker down first, so the notice stands at rest)
H.wait(8000, function() return not S.ok or H.mkDown() end, function(ok)
    if not S.ok then return end
    if not ok then Q.say("NOTE the error marker was still up before EB 5d (phase " .. tostring(H.mkPhase()) .. "): the notice read lifted") end
end)
Q.step(10, function()
    if not S.ok then return end
    pcall(function() S.M.clear(S.SRC) end)
    H.markAllRead()
    S.M.toasts = {}
    if S.E then S.E._until = 0 end
end)
Q.step(10, function()
    if not S.ok then return end
    S.k.t5 = getTimestampMs()
    S.M.add(S.SRC, "mods", { head = "QA", text = "vk6_err: a note for the notice" })
end)
H.wait(2000, function() return not S.ok or (H.noteShown() and H.badgeSince(S.k.t5) ~= nil) end, function(ok)
    if not S.ok then return end
    local T = ZeD.T
    local l = H.badgeSince(S.k.t5)
    local tone = nil
    pcall(function() tone = ZeD.Belt.lampTone() end)
    local ax, ay = S.E.anchor(S.pn)
    local nx, ny, point = nil, nil, nil
    pcall(function() nx, ny, point = ZeD.MessagesWindow.noticeAnchor(S.pn) end)
    Q.check(ok and tone == "note" and l ~= nil and H.near(l.c, T.accent) and ax ~= nil and nx == ax and ny ~= nil and ny <= ay and point == true,
        "EB 5d: a note: the notice shows, its count in the accent color, and Messages' balloons come out of it",
        "tone " .. tostring(tone) .. ", the count " .. tostring(l and l.text) .. " on " .. H.rgb(l and l.c) .. " (accent " .. H.rgb(T.accent) .. "); the notice's anchor "
        .. tostring(ax) .. "," .. tostring(ay) .. ", the balloons' " .. tostring(nx) .. "," .. tostring(ny) .. " pointing " .. tostring(point))
    -- all read now: the notice goes by itself SHOW_MS after the note came (Nov 23 2026: in the corner, the belt away;
    -- on the row it stays while the belt draws)
    pcall(function() S.M.markRead(S.SRC) end)
    S.M.toasts = {}
    S.k.rowStays = H.onRow()
    H.away(true)
end)
H.wait(10000, function() return not S.ok or not H.noteShown() end, function(ok)
    if not S.ok then return end
    local ms = getTimestampMs() - S.k.t5
    local show = (S.E and S.E.SHOW_MS) or 6000
    local corner = not H.onRow()
    H.away(false)
    Q.check(ok and corner and ms >= show - 1500 and ms <= show + 2000, "EB 5e: all read: the notice goes by itself about six seconds after the note came",
        "gone " .. tostring(ok) .. " after " .. ms .. " ms (SHOW_MS " .. show .. "), in the corner " .. tostring(corner) .. " (on the row before " .. tostring(S.k.rowStays) .. ")")
end)

-- ===================================================================== EB 6: the pad on the notice
-- (Nov 23 2026, Build's fix/beltrow2: the notice is the row's box "notice", walked in row order; the pad starts on the
-- box before it, the last speed key in single player)
function H.padSet()
    local hud = H.hud()
    if not hud then return nil end
    local ni = H.noticeIdx(hud)
    hud._gp = { idx = ni and (ni - 1) or #(hud._boxes or {}), inList = false, row = 1, list = {} }
    S.k.gpSet = true
    local jd = H.joy()
    if jd then pcall(setJoypadFocus, S.pn, hud); S.k.joyTaken = true end
    return hud
end
-- true while the belt's pad walk is on the notice's row box
function H.padOnNotice(hud)
    if not (hud and hud._gp) then return false end
    local b = nil
    pcall(function() b = hud:_gpBox() end)
    return b ~= nil and b.kind == "notice"
end
Q.step(4, function()
    if not S.ok then return end
    S.M.add(S.SRC, "mods", { head = "QA", text = "vk6_err: a note for the pad" })
end)
H.wait(2000, function() return not S.ok or H.noteShown() end, function(ok)
    if not S.ok then return end
    local hud = H.padSet()
    if not (ok and hud and H.noticeIdx(hud)) then S.k.noPad = true; Q.check(false, "EB 6: the notice shows on the row and the belt takes the pad (staging)"); return end
    H.markSpy(true)
    S.k.lastIdx = hud._gp.idx
    pcall(function() hud:onJoypadDirRight() end)
    S.k.onNotice = H.padOnNotice(hud) and S.E.padOn()
end)
Q.step(20, function()
    if not S.ok or S.k.noPad then return end
    local hud = H.hud()
    if not hud then S.k.noPad = true; return end
    local mk = S.mk
    local hint = mk and mk.hints.note
    S.k.marked = mk ~= nil and mk.marks > 0
    S.k.hint = hint
    pcall(function() hud:onJoypadDirLeft() end)
    local g = hud._gp
    S.k.back = g ~= nil and not H.padOnNotice(hud) and g.idx == S.k.lastIdx and not S.E.padOn()
    pcall(function() hud:onJoypadDirRight() end)
    S.k.again = H.padOnNotice(hud)
    pcall(function() hud:onJoypadDown(Joypad.AButton, H.joy()) end)
end)
H.wait(3000, function() return not S.ok or S.k.noPad or H.msgOpen() end, function(ok)
    if not S.ok or S.k.noPad then return end
    local hud = H.hud()
    if not hud then return end
    local left = hud._gp == nil
    H.msgClose()
    -- Up leaves, B leaves
    H.padSet()
    pcall(function() hud:onJoypadDirRight() end)
    local on1 = H.padOnNotice(hud)
    pcall(function() hud:onJoypadDirUp() end)
    local upLeft = hud._gp == nil and not S.E.padOn()
    H.padSet()
    pcall(function() hud:onJoypadDirRight() end)
    local on2 = H.padOnNotice(hud)
    pcall(function() hud:onJoypadDown(Joypad.BButton, H.joy()) end)
    local bLeft = hud._gp == nil and not S.E.padOn()
    Q.check(S.k.onNotice and S.k.marked and S.k.hint ~= nil and S.k.back and S.k.again and ok and left and on1 and upLeft and on2 and bLeft,
        "EB 6: the pad: Right from the last speed key lands on the notice on the row (its pad mark and hint), Left back, A opens Messages, Up and B leave",
        "on the notice " .. tostring(S.k.onNotice) .. ", its mark drawn " .. tostring(S.k.marked) .. ", its hint " .. tostring(S.k.hint) .. "; Left back to box "
        .. tostring(S.k.lastIdx) .. " " .. tostring(S.k.back) .. "; Right again " .. tostring(S.k.again) .. ", A: Messages " .. tostring(ok) .. ", the belt let go "
        .. tostring(left) .. "; Up leaves " .. tostring(on1 and upLeft) .. "; B leaves " .. tostring(on2 and bLeft))
    H.markSpy(false)
    H.msgClose()
    hud._gp = nil
    S.k.gpSet = nil
    pcall(function() S.M.clear(S.SRC) end)
end)

-- ===================================================================== EB 7: the belt row
-- (Nov 23 2026: the Messages notice's place after the speed keys; single player's row ends with it)
Q.step(4, function()
    if not S.ok then return end
    local hud = H.hud()
    local n, lamp, first, bagR, lastSpeed = 0, false, nil, nil, nil
    for i, b in ipairs((hud and hud._boxes) or {}) do
        if b.kind == "speed" then n = n + 1; lastSpeed = i; if not first then first = b end end
        if b.kind == "lamp" then lamp = true end
        if b.kind == "bag" then bagR = b.x + b.w end
    end
    local ni = H.noticeIdx(hud)
    local nb = #((hud and hud._boxes) or {})
    local noticeOk = ni ~= nil and (S.server or (lastSpeed ~= nil and ni == lastSpeed + 1 and ni == nb))
    local st = hud and hud._strap
    local endX = st and (st.x + st.w) or 0
    local want = S.server and 0 or 5
    Q.check(hud ~= nil and n == want and not lamp and noticeOk and (S.server or (first ~= nil and bagR ~= nil and first.x > endX and first.x > bagR)),
        "EB 7: the belt row: five speed keys after the belt (none on a server), then the Messages notice's place, no old note box",
        "keys " .. n .. ", the first at " .. H.num(first and first.x) .. " (the strap's end " .. H.num(endX) .. ", the bag button's right " .. H.num(bagR)
        .. "); the notice box " .. tostring(ni) .. " of " .. nb .. " (the last key " .. tostring(lastSpeed) .. "); an old lamp box " .. tostring(lamp)
        .. "; vk4_belt.lua reads the whole row")
end)

-- ===================================================================== EB 9: the buckle
function H.buckleClick()
    local hud = H.hud()
    local k = hud and hud._buckle
    if not (hud and k) then return false, "no buckle on the belt" end
    local lx, ly = k.x + math.floor(k.w / 2), k.y + math.floor(k.h / 2)
    local ok, err = H.atPointer(hud:getAbsoluteX() + lx, hud:getAbsoluteY() + ly, function()
        hud:onMouseDown(lx, ly)
        hud:onMouseUp(lx, ly)
    end)
    if not ok then return false, "the click threw: " .. tostring(err) end
    return true, "clicked"
end
function H.cwTab() local w = RT.cw(); return w and (w._activeTab or "loot") or nil end
Q.step(4, function()
    if not S.ok then return end
    H.shutAll()
end)
H.wait(4000, function() return not S.ok or H.none() end, function(ok)
    if not S.ok then return end
    S.k.b1, S.k.b1why = H.buckleClick()
end)
H.wait(3000, function() return not S.ok or (H.charOpen() and H.cwTab() == "identity") end, function(ok)
    if not S.ok then return end
    S.k.b1ok = ok and S.k.b1
    S.k.b2, S.k.b2why = H.buckleClick()
end)
H.wait(3000, function() return not S.ok or not H.charOpen() end, function(ok)
    if not S.ok then return end
    S.k.b2ok = ok and S.k.b2
    RT.pairOpen()
end)
-- "another tab": Skills (else Health), never the identity tab: it IS Info (#59 renamed Identity to Info), and the
-- buckle on Info shuts the window (QA, Nov 22: the run sat on identity, so the click toggled it shut). The buckle is
-- clicked only once the window shows that tab.
H.wait(4000, function() return not S.ok or H.charOpen() end, function(ok)
    if not S.ok then return end
    local offered, first = {}, nil
    for _, id in ipairs(RT.tabs(RT.charStrip())) do
        offered[id] = true
        if not first and id ~= "identity" then first = id end
    end
    -- (the strip's hit zones can lag the frame the window opens: Skills, which every character has)
    S.k.other = (offered.skills and "skills") or (offered.health and "health") or first or "skills"
    RT.charTab(S.k.other)
    S.k.otherT = getTimestampMs()
end)
H.wait(4000, function()
    if not S.ok then return true end
    if H.cwTab() == S.k.other then return true end
    -- (pressed again at most every half second until the window shows it)
    if getTimestampMs() - (S.k.otherT or 0) >= 500 then RT.charTab(S.k.other); S.k.otherT = getTimestampMs() end
    return false
end, function(ok)
    if not S.ok then return end
    S.k.otherOn = H.cwTab()
    S.k.otherOk = ok and S.k.otherOn == S.k.other and S.k.otherOn ~= "identity"
    S.k.b3, S.k.b3why = H.buckleClick()
end)
H.wait(3000, function() return not S.ok or (H.charOpen() and H.cwTab() == "identity") end, function(ok)
    if not S.ok then return end
    S.k.b3ok = ok and S.k.b3 and S.k.otherOk == true
    -- the hover hint: the belt's pointer reading on the buckle's middle
    local hud = H.hud()
    local k = hud and hud._buckle
    if hud and k then
        S.k.park = { hud = hud, mx = rawget(hud, "getMouseX"), my = rawget(hud, "getMouseY") }
        local lx, ly = k.x + math.floor(k.w / 2), k.y + math.floor(k.h / 2)
        hud.getMouseX = function() return lx end
        hud.getMouseY = function() return ly end
        H.markSpy(true)
    end
end)
Q.step(30, function()
    if not S.ok then return end
    local hint = S.mk and S.mk.hints.buckle
    H.markSpy(false)
    local pk = S.k.park
    if pk then pk.hud.getMouseX, pk.hud.getMouseY = pk.mx, pk.my; S.k.park = nil end
    local info = getText("IGUI_XP_Info")
    Q.check(S.k.b1ok and S.k.b2ok and S.k.b3ok and hint == info,
        "EB 9: the buckle (Full): a click opens the Character window on Info, a second click closes it, from another tab it goes to Info, its hint says Info",
        "shut -> " .. tostring(S.k.b1ok) .. " (" .. tostring(S.k.b1why) .. "); again -> closed " .. tostring(S.k.b2ok) .. "; on " .. tostring(S.k.otherOn)
        .. " (asked for " .. tostring(S.k.other) .. ", shown " .. tostring(S.k.otherOk) .. ") -> Info " .. tostring(S.k.b3ok) .. "; the hint " .. tostring(hint) .. " (" .. tostring(info) .. ")")
    H.optSet(H.styleOpt(), 2)
end)
H.wait(4000, function() local hud = H.hud(); return not S.ok or (H.lite() and hud ~= nil and hud._drawn == true and hud._buckle == nil) end, function(ok)
    if not S.ok then return end
    Q.check(ok, "EB 9: Lite has no buckle", "Lite " .. tostring(H.lite()))
    H.optSet(H.styleOpt(), 1)
end)
H.wait(4000, function() return not S.ok or not H.lite() end, function() end)

-- ===================================================================== EB 10: the tour's Guide step
Q.step(4, function()
    if not S.ok then return end
    local TU = ZeD.Tutorial
    local st = nil
    for _, s in ipairs((TU and TU.STEPS) or {}) do if s.key == "Guide" then st = s end end
    local r = nil
    if st and st.target then pcall(function() r = st.target(0) end) end
    local x, y, s = S.E.rect()
    Q.check(r ~= nil and math.abs(r.x - x) < 2 and math.abs(r.y - y) < 2 and math.abs(r.w - s) < 2,
        "EB 10: the tour's Guide step points at the notice's place (ZeD.ErrorBox.rect)",
        "the step's target " .. (r and (H.num(r.x) .. "," .. H.num(r.y) .. " " .. H.num(r.w)) or "none") .. "; the notice " .. H.num(x) .. "," .. H.num(y) .. " " .. H.num(s)
        .. "; rt_tour.lua walks the tour")
end)

-- ===================================================================== EB 11: a split speed strip
Q.step(4, function()
    if not S.ok then return end
    ZeD.SplitSpeed = ZeD.SplitSpeed or {}
    local stripX = H.sw() - ZeD.T.px(200)
    ZeD.SplitSpeed._instance = { isVisible = function() return true end, getX = function() return stripX end }
    -- (Nov 23 2026: the strip is the corner's matter: the belt away for this one read, E.rect reads it at once)
    H.away(true)
    local okR, x, _, s = pcall(S.E.rect)
    H.away(false)
    ZeD.SplitSpeed._instance = S.was.split
    local want = okR and (stripX - s - ZeD.T.px(S.E.EDGE_U)) or nil
    Q.check(okR and want ~= nil and x <= want + 1, "EB 11: split screen: the notice stands left of the corner speed strip (a stand-in strip; E.rect)",
        "the strip at x " .. H.num(stripX) .. ", the notice at x " .. H.num(x) .. " (at most " .. H.num(want) .. ")")
end)

-- ===================================================================== EB 12: the error marker (Build's errmark)
function H.mkGone() return not S.ok or S.k.noMk == true end
Q.step(4, function()
    if not S.ok then return end
    if not S.mkOn then
        S.k.noMk = true
        Q.skip("EB 12: the error marker (rise, hold, fall, the lifted notice, colors, click, draw order, notes)",
            "ZeD.ErrorBox.markSize is not there: this build has no error marker (Build's errmark branch adds it)")
        return
    end
    H.msgClose()
    H.markAllRead()
    S.M.toasts = {}
    -- (the marker shows only with the clip on: the cursor lock off, as the start set it; the put-back restores it)
    if not H.hide() then pcall(function() getCore():setOptionLockCursorToWindow(false) end) end
end)
H.wait(8000, function() return H.mkGone() or (H.hide() and H.mkDown()) end, function(ok)
    if H.mkGone() then return end
    if not ok then
        S.k.noMk = true
        Q.check(false, "EB 12: the marker down and the clip on before the marker's run (staging)", "phase " .. tostring(H.mkPhase()) .. ", hideWanted " .. tostring(H.hide()))
        return
    end
    S.k.before = H.errCounts()
    H.raiseZeD()
end)
-- EB 12a, 12b, 12c: ZeD's error, up
H.wait(9000, function() return H.mkGone() or H.mkPhase() ~= nil end, function(ok)
    if H.mkGone() then return end
    if not ok then
        S.k.noMk = true
        Q.check(false, "EB 12a: ZeD's own error starts the marker", "the error filed: " .. tostring((H.risen(S.k.before))) .. "; phase " .. tostring(H.mkPhase()))
        return
    end
    local k = H.mk() or {}
    -- (its start: the hold's end less HOLD_MS, set in the frame the error came; one error so far)
    S.k.mStart = (k.holdEnd or 0) - (S.E.HOLD_MS or 3000)
end)
H.wait(3000, function() return H.mkGone() or H.mkPhase() == "hold" end, function(ok)
    if H.mkGone() then return end
    local E, T = S.E, ZeD.T
    local k = H.mk() or {}
    local m, el = H.mkEl(), H.note()
    local _, mh = E.markSize()
    -- (Nov 23 2026, Build's fix/beltrow2: the marker ends where the notice's bottom rests, on the belt row or in the
    -- corner: its top fully up is the screen's height less (markH + the room under the notice's rest bottom), as
    -- ZeD_ErrorBox.lua E.frame works it; in the corner that room is T.px(10))
    local _, restY, rs, onRow = E.rect()
    local under = math.max(0, H.sh() - (restY + rs))
    local want = H.sh() - (mh + under)
    local my, mx, mw = -1, -1, -1
    if m then my, mx, mw = m:getY(), m:getX(), m:getWidth() end
    local ny, nx = -1, -1
    if el then ny, nx = el:getY(), el:getX() end
    local ms = getTimestampMs() - (S.k.mStart or 0)
    local word = ZeD.tr("UI_ZeD_ErrorBox_Marker")
    Q.check(ok and H.mkShown() and k.kind == "ours" and (k.count or 0) >= 1 and ms >= 400 and ms <= 1500 and word ~= "UI_ZeD_ErrorBox_Marker",
        "EB 12a: ZeD's own error: the marker rises (ZeD.ErrorBox._marker shown, kind ours, red), \"Error\" and the count of new errors",
        "phase " .. tostring(k.phase) .. ", shown " .. tostring(H.mkShown()) .. ", kind " .. tostring(k.kind) .. ", count " .. tostring(k.count) .. ", the word "
        .. tostring(word) .. "; fully up after " .. H.num(ms) .. " ms (RISE_MS " .. tostring(E.RISE_MS) .. ")")
    Q.check(ok and m ~= nil and math.abs(my - want) <= 1 and math.abs(mx - nx) <= 1 and math.abs(mw - T.px(E.NOTE_U)) <= 1 and H.noteShown()
        and math.abs(ny - (restY - mh)) <= 1,
        "EB 12b: fully up the marker's bottom stands where the notice's bottom rests (on the belt row or in the corner), under the notice and its width, the notice lifted by exactly its height",
        "the marker at " .. H.num(mx) .. "," .. H.num(my) .. " (y " .. H.num(want) .. " = " .. H.sh() .. " - (" .. H.num(mh) .. " + " .. H.num(under) .. "), the notice on the row " .. tostring(onRow) .. "), "
        .. H.num(mw) .. " wide (" .. H.num(T.px(E.NOTE_U)) .. "); the notice shown " .. tostring(H.noteShown()) .. " at " .. H.num(nx) .. "," .. H.num(ny)
        .. " (rest y " .. H.num(restY) .. " - " .. H.num(mh) .. " = " .. H.num(restY - mh) .. ")")
    local hs = nil
    if ZeD.HintStrip and ZeD.HintStrip._huds then hs = ZeD.HintStrip._huds[S.pn] end
    if hs == nil then
        Q.skip("EB 12c: the hint strip draws over the marker", "no hint strip element in this game (ZeD.HintStrip._huds)")
    else
        local iM, iH = H.uiIndex(m), H.uiIndex(hs)
        -- (Nov 23 2026: on the row it rises past the belt's place too; the marker goes to the back of the UI list at
        -- each start, so the belt draws over it as well)
        local iB = H.uiIndex(H.hud())
        Q.check(iM ~= nil and iH ~= nil and iM < iH and (iB == nil or iM < iB), "EB 12c: the hint strip draws over the marker (before it in the game's UI list)",
            "the marker at " .. tostring(iM) .. ", the hint strip at " .. tostring(iH) .. ", the belt at " .. tostring(iB))
    end
    H.shot("err_marker")
end)
-- EB 12d: a click on the marker (after the picture)
Q.step(10, function()
    if H.mkGone() then return end
    local m = H.mkEl()
    S.k.mkClick = false
    if m and m:getIsVisible() then
        local w, h = m:getWidth(), m:getHeight()
        S.k.mkClick = pcall(function() m:onMouseDown(math.floor(w / 2), math.floor(h / 2)); m:onMouseUp(math.floor(w / 2), math.floor(h / 2)) end)
    end
end)
H.wait(3000, function() return H.mkGone() or H.msgOpen() end, function(ok)
    if H.mkGone() then return end
    Q.check(ok and S.k.mkClick == true, "EB 12d: a click on the marker opens Messages", "clicked " .. tostring(S.k.mkClick) .. ", Messages open " .. tostring(H.msgOpen()))
    H.msgClose()
end)
-- EB 12e: down by itself at about 4 s, the notice back at rest
H.wait(8000, function() return H.mkGone() or H.mkDown() end, function(ok)
    if H.mkGone() then return end
    local ms = getTimestampMs() - (S.k.mStart or 0)
    local el = H.note()
    local _, restY = S.E.rect()
    local ny = el and el:getY() or -1
    Q.check(ok and ms >= 3700 and ms <= 5000 and H.noteShown() and math.abs(ny - restY) <= 1,
        "EB 12e: the marker is gone at about 4 s (0.5 up, 3 held, 0.5 down) and the notice is back at rest",
        "gone " .. tostring(ok) .. " after " .. H.num(ms) .. " ms; the notice shown " .. tostring(H.noteShown()) .. " at y " .. H.num(ny) .. " (rest " .. H.num(restY) .. ")")
end)
-- EB 12f, 12g: the game's error, gray; a second 2 s later stretches the hold
Q.step(4, function()
    if H.mkGone() then return end
    H.markAllRead()
    S.M.toasts = {}
    S.k.before = H.errCounts()
    -- (QA, Nov 22: Build asked for the Messages read log around the repeats; switched off in the put-back below)
    pcall(function() if ZeD.Messages then ZeD.Messages.qaLog = true end end)
    H.raiseGame("game")
end)
H.wait(9000, function() return H.mkGone() or H.mkPhase() ~= nil end, function(ok)
    if H.mkGone() then return end
    local k = H.mk() or {}
    if not ok then
        S.k.noMk = true
        Q.check(false, "EB 12f: the game's error starts the marker", "the error filed: " .. tostring((H.risen(S.k.before))) .. "; phase " .. tostring(k.phase))
        return
    end
    S.k.m2 = (k.holdEnd or 0) - (S.E.HOLD_MS or 3000)
    S.k.kind2 = k.kind
end)
H.wait(3000, function() return H.mkGone() or getTimestampMs() >= (S.k.m2 or 0) + 2000 end, function()
    if H.mkGone() then return end
    S.k.before2 = H.errCounts()
    H.raiseGame("game")
end)
H.wait(3000, function() H.readNow(); return H.mkGone() or getTimestampMs() >= (S.k.m2 or 0) + 3600 end, function()
    if H.mkGone() then return end
    local k = H.mk() or {}
    local ms = getTimestampMs() - (S.k.m2 or 0)
    local words2, ours2, others2 = H.risen(S.k.before2)
    Q.check(S.k.kind2 == "others" and k.kind == "others", "EB 12f: the game's error: the marker is gray (kind others)",
        "kind at the start " .. tostring(S.k.kind2) .. ", now " .. tostring(k.kind))
    Q.check(others2 and not ours2 and k.phase == "hold" and (k.p or 0) >= 1 and H.mkShown() and (k.count or 0) >= 2 and ms < 5000,
        "EB 12g: two errors 2 s apart: the marker is still fully up at 3.6 s (the second stretches the hold)",
        "the second filed: " .. tostring(words2) .. "; at " .. H.num(ms) .. " ms: phase " .. tostring(k.phase) .. ", up " .. H.num(k.p) .. ", shown " .. tostring(H.mkShown())
        .. ", count " .. tostring(k.count) .. ", the hold ends at " .. H.num((k.holdEnd or 0) - (S.k.m2 or 0)) .. " ms")
end)
-- EB 12h: an error while it falls sends it back up from where it is
H.wait(4000, function() return H.mkGone() or H.mkPhase() == "down" end, function(ok)
    if H.mkGone() then return end
    if not ok then S.k.noFall = true; return end
    S.k.pDown = (H.mk() or {}).p
    S.k.fellOut, S.k.pUp, S.k.phUp = false, nil, nil
    H.raiseGame("game")
end)
H.wait(3000, function()
    if H.mkGone() or S.k.noFall then return true end
    H.readNow()
    local k = H.mk() or {}
    if k.phase == nil then S.k.fellOut = true end
    if k.phase == "down" then S.k.pDown = k.p end
    if k.phase == "up" or k.phase == "hold" then S.k.pUp, S.k.phUp = k.p, k.phase; return true end
    return false
end, function(ok)
    if H.mkGone() then return end
    Q.check(ok and not S.k.noFall and not S.k.fellOut and S.k.phUp == "up" and (S.k.pUp or 0) > 0.05 and (S.k.pUp or 1) < 1 and H.mkShown(),
        "EB 12h: an error while the marker falls sends it back up from where it is (no jump, never down in between)",
        "falling seen " .. tostring(not S.k.noFall) .. ", last up while falling " .. H.num(S.k.pDown) .. "; then " .. tostring(S.k.phUp) .. " at " .. H.num(S.k.pUp)
        .. "; down in between " .. tostring(S.k.fellOut) .. ((S.k.noFall or S.k.fellOut) and " (staging: the error came after the fall ended)" or ""))
end)
Q.step(1, function() pcall(function() if ZeD.Messages then ZeD.Messages.qaLog = nil end end) end)
-- EB 12i: a note gets no marker
H.wait(8000, function() return H.mkGone() or H.mkDown() end, function(ok)
    if H.mkGone() then return end
    if not ok then S.k.noMk = true; Q.check(false, "EB 12i: the marker down before the note (staging)", "phase " .. tostring(H.mkPhase())); return end
    H.markAllRead()
    S.M.toasts = {}
    S.k.noteMk = false
    S.M.add(S.SRC, "mods", { head = "QA", text = "vk6_err: a note, no marker" })
end)
H.wait(1500, function()
    if H.mkGone() then return true end
    if H.mkPhase() ~= nil or H.mkShown() then S.k.noteMk = true end
    return false
end, function()
    if H.mkGone() then return end
    Q.check(H.noteShown() and not S.k.noteMk and H.mkPhase() == nil, "EB 12i: a note: the notice shows and no marker comes (_mk.phase nil throughout)",
        "the notice shown " .. tostring(H.noteShown()) .. ", a marker seen " .. tostring(S.k.noteMk) .. ", phase " .. tostring(H.mkPhase()))
    pcall(function() S.M.clear(S.SRC) end)
end)

-- ===================================================================== side effects that are not staged
Q.step(2, function()
    Q.skip("the sleeping overlay", "sleeping is not staged; the game draws nothing in OnSleepingTick (its clock is a UI element drawn before)")
    Q.skip("ActiveMods.renderUI and the debug overlays", "debug options only; the Error box tick gives them back (EB 4a's picture with them on, by hand)")
end)

-- ===================================================================== EB 8: driving (last: it moves him)
function H.keysAbs()
    local hud = H.hud()
    local out = {}
    if not hud then return out end
    local ax, ay = hud:getAbsoluteX(), hud:getAbsoluteY()
    for _, b in ipairs(hud._boxes or {}) do
        if b.kind == "speed" then out[#out + 1] = { n = b.n, x = ax + b.x, y = ay + b.y, w = b.w, h = b.h, b = b } end
    end
    return out
end
function H.keysText(t)
    local w = {}
    for _, k in ipairs(t or {}) do w[#w + 1] = tostring(k.n) .. "@" .. H.num(k.x) .. "," .. H.num(k.y) end
    return table.concat(w, " ")
end
Q.step(4, function()
    if not S.ok or S.server then
        if S.server then Q.skip("EB 8: driving: the speed keys at the same spot", "on a server there are no speed keys") end
        S.k.noCar = true
        return
    end
    if not ZEDQA_CAR_WAIT then S.k.noCar = true; Q.check(false, "EB 8: the prelude's car helpers are loaded (staging)"); return end
    S.k.carWait = true
    ZEDQA_CAR_WAIT(S.CAR, "vk6_err", function(v)
        S.k.carWait = false
        if S.k.carGaveUp then if ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(v) end; return end
        S.car = { v = v }
    end, function(why)
        S.k.carWait = false
        S.k.carWhy = why
    end, 4000)
end)
H.wait(20000, function() return S.k.noCar or S.car ~= nil or S.k.carWait == false end, function(ok)
    if S.k.noCar then return end
    if not S.car then
        S.k.carGaveUp = true
        S.k.noCar = true
        Q.check(false, "EB 8: a pickup to drive (staging)", tostring(S.k.carWhy))
        return
    end
    S.k.keys0 = H.keysAbs()
    local okE, ok2, why = pcall(ZEDQA_CAR_ENTER, S.car.v, 0)
    S.k.inDriver = okE and ok2 == true
    S.k.enterWhy = why
end)
H.wait(4000, function()
    if S.k.noCar then return true end
    local hud = H.hud()
    if not (S.k.inDriver and hud ~= nil and hud._keysDrawn == true and hud._drawn == false) then S.k.keySig, S.k.keyStill = nil, 0; return false end
    -- (settled: the keys at one spot for 10 frames; the dash places itself in its own first frames, and the keys
    -- follow its top the frame after)
    local sig = H.keysText(H.keysAbs())
    if sig == S.k.keySig then S.k.keyStill = (S.k.keyStill or 0) + 1 else S.k.keySig, S.k.keyStill = sig, 0 end
    return S.k.keyStill >= 10
end, function(ok)
    if S.k.noCar then return end
    local hud = H.hud()
    local keys1 = H.keysAbs()
    -- (dashkeys, the director, Nov 22 2026: the keys keep their spot, but where a dash is up and the spot is on it
    -- they lift so the lowest key's bottom stands T.px(6) above the dash's top (ZeD.Belt.keysClearOfDash); the x
    -- never moves)
    local D = ZeD.Dashboard
    local dash = D and D.getInstance and D.getInstance(S.pn)
    local dx, dy, dw, dh = nil, nil, nil, nil
    local dashText = "no dash on screen"
    if dash and dash:isVisible() then
        dx, dy, dw, dh = dash:getAbsoluteX(), dash:getAbsoluteY(), dash:getWidth(), dash:getHeight()
        dashText = "the dash " .. H.num(dx) .. "," .. H.num(dy) .. " " .. H.num(dw) .. "x" .. H.num(dh)
    end
    local function onDash(t)
        if not dx then return false end
        for _, k in ipairs(t) do
            if k.x < dx + dw and k.x + k.w > dx and k.y < dy + dh and k.y + k.h > dy then return true end
        end
        return false
    end
    local homeOnDash = onDash(S.k.keys0)
    local clear = not onDash(keys1)
    local lift = 0
    if homeOnDash then
        local bot0 = nil
        for _, k in ipairs(S.k.keys0) do if not bot0 or k.y + k.h > bot0 then bot0 = k.y + k.h end end
        lift = (bot0 or 0) - (dy - ZeD.T.px(6))
    end
    local same = #keys1 == 5 and #S.k.keys0 == 5
    for i, k in ipairs(keys1) do
        local k0 = S.k.keys0[i]
        if not (k0 and k0.n == k.n and math.abs(k0.x - k.x) <= 1 and math.abs((k0.y - lift) - k.y) <= 1) then same = false end
    end
    Q.check(ok and same and clear,
        "EB 8: driving: the belt hides and the five speed keys keep their x at the same spot, lifted just above the dash when the dash is up there",
        "in the driver's seat " .. tostring(S.k.inDriver) .. " (" .. tostring(S.k.enterWhy) .. "); settled " .. tostring(ok) .. "; keys only " .. tostring(hud and hud._keysDrawn) .. ", the belt drawn "
        .. tostring(hud and hud._drawn) .. "; before " .. H.keysText(S.k.keys0) .. "; driving " .. H.keysText(keys1) .. "; " .. dashText
        .. "; the home spot on the dash " .. tostring(homeOnDash) .. ", want lifted by " .. H.num(lift) .. ", clear " .. tostring(clear))
    H.shot("err_driving")
    -- a key pressed where it is drawn: x2 (speed 2), read a few frames on, then Play
    local k2 = nil
    for _, k in ipairs(keys1) do if k.n == 2 then k2 = k end end
    S.k.pressed = false
    if hud and k2 then
        local lx, ly = k2.b.x + math.floor(k2.b.w / 2), k2.b.y + math.floor(k2.b.h / 2)
        S.k.pressed = H.atPointer(k2.x + math.floor(k2.w / 2), k2.y + math.floor(k2.h / 2), function() hud:onMouseDown(lx, ly); hud:onMouseUp(lx, ly) end)
    end
end)
Q.step(4, function()
    if S.k.noCar then return end
    local sp = nil
    pcall(function() sp = ZeD.Belt.speedNow() end)
    Q.check(S.k.pressed and sp == 2, "EB 8: driving: the x2 key pressed where it is drawn sets that speed", "pressed " .. tostring(S.k.pressed) .. ", speed " .. tostring(sp))
    pcall(ZeD.Belt.speedKey, 1)
    pcall(function() S.car.v:exit(S.p); triggerEvent("OnExitVehicle", S.p) end)
end)
Q.step(10, function()
    if S.k.noCar then return end
    local okE, ok2 = pcall(ZEDQA_CAR_ENTER, S.car.v, 1)
    S.k.inPass = okE and ok2 == true
end)
H.wait(4000, function()
    if S.k.noCar then return true end
    local hud = H.hud()
    return S.k.inPass and hud ~= nil and hud._drawn == true
end, function(ok)
    if S.k.noCar then return end
    local hud = H.hud()
    local bag, n = false, 0
    for _, b in ipairs((hud and hud._boxes) or {}) do
        if b.kind == "bag" then bag = true end
        if b.kind == "speed" then n = n + 1 end
    end
    local ko = true
    pcall(function() ko = hud:keysOnly() end)
    Q.check(ok and bag and n == 5 and not ko, "EB 8: a passenger keeps the whole belt (the bag button, the belt, the speed keys)",
        "in the passenger seat " .. tostring(S.k.inPass) .. "; the belt drawn " .. tostring(hud and hud._drawn) .. ", the bag button " .. tostring(bag)
        .. ", keys " .. n .. ", keys only " .. tostring(ko))
end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    H.markSpy(false)
    H.badgeOff()
    H.countOff()
    H.postSpy(false)
    if S.frameOn then Events.OnPreUIDraw.Remove(H.frameTick); S.frameOn = nil end
    local pk = S.k.park
    if pk then pk.hud.getMouseX, pk.hud.getMouseY = pk.mx, pk.my; S.k.park = nil end
    local hud = H.hud()
    if hud and S.k.gpSet then hud._gp = nil end
    S.k.gpSet = nil
    if ZeD.SplitSpeed then ZeD.SplitSpeed._instance = S.was.split end
    H.away(false)   -- (the Toggle UI flag as found: Nov 23 2026)
    -- the car away, him back where he was
    if S.car then
        pcall(ZEDQA_CAR_AWAY, S.car.v)
        S.car.going = true
    end
    if S.k.carWait then S.k.carGaveUp = true end
    -- the live options and the stored values as found
    if S.was.fbo ~= nil then pcall(function() if getCore():getOptionUIFBO() ~= S.was.fbo then getCore():setOptionUIFBO(S.was.fbo) end end) end
    if S.was.lock ~= nil then pcall(function() if getCore():getOptionLockCursorToWindow() ~= S.was.lock then getCore():setOptionLockCursorToWindow(S.was.lock) end end) end
    if S.was.err ~= nil then H.optSet(H.errOpt(), S.was.err) end
    if S.was.safe ~= nil then H.optSet(H.safeOpt(), S.was.safe) end
    if S.was.style ~= nil then H.optSet(H.styleOpt(), S.was.style) end
    if ISFPS and S.was.fps ~= nil and ISFPS.start ~= S.was.fps then pcall(ISFPS.onKeyPressed, getCore():getKey("Display FPS")) end
    if S.E and S.was.off ~= nil then S.E.off = S.was.off end
    -- the radio out of his hand (RT.takeBack takes it away)
    if S.radio then
        pcall(function() local dd = S.radio:getDeviceData(); if dd then dd:setIsTurnedOn(false) end end)
        pcall(function() if S.p:getSecondaryHandItem() == S.radio then S.p:setSecondaryHandItem(S.was.sec) end end)
    end
    -- Messages as found
    H.msgClose()
    local M = S.M
    if M and M.sources and S.was.errs then
        pcall(function() M.clear(S.SRC) end)
        M.sources[S.SRC] = nil
        local drop = {}
        for name, s in pairs(M.sources) do
            if type(s) == "table" and s.kind == "err" and S.was.errs[name] == nil then drop[#drop + 1] = name end
        end
        for _, name in ipairs(drop) do M.sources[name] = nil end
        -- (the read marks first: an error source's own read state as found is set after, by H.errBack)
        for _, it in ipairs(S.wasUnread or {}) do it.read = false end
        for name, snap in pairs(S.was.errs) do
            M.sources[name] = snap.s
            H.errBack(snap)
        end
        if S.was.toasts then M.toasts = S.was.toasts end
        if type(M.seq) == "number" then M.seq = M.seq + 1 end
        pcall(M.savePlaces)
        S.k.msgBack = true
    end
end)
H.wait(3000, function() return S.car == nil or S.p:getVehicle() == nil end, function()
    -- (the car helper moves him to the drag strip first, car or no car: back where he was found)
    local at = S.was.pos
    if at and S.p:getVehicle() == nil then
        local dx, dy = S.p:getX() - at.x, S.p:getY() - at.y
        if dx * dx + dy * dy > 2.25 or math.floor(S.p:getZ()) ~= math.floor(at.z) then
            S.k.movedBack = true
            pcall(function() S.p:setX(at.x); S.p:setY(at.y); S.p:setZ(at.z); S.p:setLastX(at.x); S.p:setLastY(at.y); S.p:setLastZ(at.z) end)
        end
    end
    if S.was.speed == 0 then pcall(setGameSpeed, 0) end
    -- the windows as found
    H.shutAll()
end)
H.wait(4000, function() return H.none() end, function()
    if S.was.char and S.was.world then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn)
    elseif S.was.char then pcall(ZeD_CharacterWindow.toggle, S.pn)
    elseif S.was.world then pcall(ZeD_WorldWindow.open, S.pn) end
    if S.was.msg then pcall(function() ZeD.MessagesWindow.open(S.pn) end) end
    local jd = H.joy()
    if jd and S.k.joyTaken then pcall(setJoypadFocus, S.pn, S.was.joy) end
end)
Q.step(10, function()
    if S.was.pos == nil then Q.say("NOTE nothing was recorded or changed: no put-back to read"); return end
    local c = getCore()
    local inCar = S.p:getVehicle() ~= nil
    local dx, dy = S.p:getX() - S.was.pos.x, S.p:getY() - S.was.pos.y
    local home = dx * dx + dy * dy <= 2.25
    Q.check(c:getOptionUIFBO() == S.was.fbo and c:getOptionLockCursorToWindow() == S.was.lock and H.optVal(H.errOpt()) == S.was.err
        and H.optVal(H.safeOpt()) == S.was.safe and H.optVal(H.styleOpt()) == S.was.style and (not ISFPS or ISFPS.start == S.was.fps)
        and (S.E == nil or S.E.off == S.was.off) and S.k.awaySet == nil,
        "put back: the offscreen UI, the cursor lock, Error box, Safe mode, Style and the FPS graph's flag as found",
        "offscreen UI " .. tostring(c:getOptionUIFBO()) .. " (" .. tostring(S.was.fbo) .. "), lock " .. tostring(c:getOptionLockCursorToWindow()) .. " ("
        .. tostring(S.was.lock) .. "), Error box " .. tostring(H.optVal(H.errOpt())) .. " (" .. tostring(S.was.err) .. "), Safe mode "
        .. tostring(H.optVal(H.safeOpt())) .. " (" .. tostring(S.was.safe) .. "), Style " .. tostring(H.optVal(H.styleOpt())) .. " (" .. tostring(S.was.style) .. ")")
    local clean = S.post == nil and S.badge == nil and S.mk == nil and S.frameOn == nil and S.k.park == nil and getMouseX ~= nil
    local nCnt = 0
    for _ in pairs(S.cnt) do nCnt = nCnt + 1 end
    Q.check(clean and nCnt == 0 and (S.E == nil or rawget(S.E, "postDraw") ~= nil), "put back: every spy gone (the clip's counter, the draw counts, the badge, the marks and hints)")
    local runErr = false
    for name, s in pairs((S.M and S.M.sources) or {}) do
        if type(s) == "table" and s.kind == "err" and S.was.errs and S.was.errs[name] == nil then runErr = true end
    end
    Q.check(S.k.msgBack and not runErr and (S.M == nil or S.M.sources[S.SRC] == nil), "put back: Messages as found (the run's errors and note gone, the read marks back)")
    Q.check(not inCar and home and H.charOpen() == (S.was.char == true) and H.worldOpen() == (S.was.world == true),
        "put back: out of the car and where he was, the windows open or shut as found",
        "in a car " .. tostring(inCar) .. ", " .. H.num(math.sqrt(dx * dx + dy * dy)) .. " tiles from where he was; Character " .. tostring(H.charOpen())
        .. " (" .. tostring(S.was.char) .. "), World " .. tostring(H.worldOpen()) .. " (" .. tostring(S.was.world) .. ")")
end)
Q.start()
