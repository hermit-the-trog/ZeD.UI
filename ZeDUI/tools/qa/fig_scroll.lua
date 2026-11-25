-- ZeDUI/tools/qa/fig_scroll.lua  (Nov 25 2026, QA; tag fig_scroll): the figure in a photo frame partly scrolled out
-- of its tab's view. The director, Nov 25 2026: "Why does the avatar get smaller as you scroll down in the paper doll
-- equipment tab? Shouldn't it just scroll away?" Before, ZeD_CharacterWindow fitted the 3D model to the part of its
-- frame left in view (setHeight(bot - top), setZoom(0)), so the figure shrank as the page scrolled; the Identity photo
-- (_placeIdentityModel) did the same. Build's fix (fix/dollscroll, c690207bb): win._fitFigureCut keeps the element only
-- as tall as the part that shows and scales the camera's zoom and y offset so the figure keeps its full-frame size and
-- place, cut at the view's edge; the Equip doll hides only once 6 px or less shows. Run after zedqa_prelude.lua and
-- rt_kit.lua (fig_scroll.txt). grep "ZEDQA fig_scroll". Built the way et_calls.lua and sb_edges.lua are (their helpers
-- copied: each script stands alone). It reads only fields both the old code and Build's have (win._identityModel, the
-- one ISUI3DModel the Identity photo and the Equip doll share; win._equipDollPhoto / _equipDollClip; win._identityPhotoRect
-- / _idView; win._equipScroll / _identityScroll), so it runs on either; on the old code the size checks FAIL by design.
--
-- How it reads the camera: ISUI3DModel has no getZoom, so the model's setZoom and setYOffset are wrapped on the
-- instance (the last value each frame recorded) and unwrapped at the end. The camera model is the one Build's comment
-- states (the game's UI3DModel, not isometric): 2 * (25 - zoom) / sqrt(2048) world units tall, centred in the element,
-- y offset 0 meaning -0.5. So the figure's size on screen is ppu = elementH * sqrt(2048) / (2 * (25 - zoom)) pixels per
-- world unit, and its origin sits (elementY - frameY) + elementH / 2 - yOffset * ppu below the frame's top.
--
-- Cases (Dark theme only, at the text size found; the scroll stepped through 0, 0.1, 0.2, 0.3, 0.45, 0.6, 0.8 and 1,
-- a few frames each; the window made shorter as sb_edges does when the tab does not scroll, put back after):
--   equip     the Equipment tab in Doll view, the outfit as found; pictures fig_equip_<pos*100>_<w>x<h>
--   identity  the Identity tab, the photo as found (bust or full body), then the other (the figure clicked, as the
--             player does); pictures fig_identity_<bust|full>_<pos*100>_<w>x<h>
-- Each step logs one line:
--   FIG <surface> pos=<asked> (read <scrollPos>) | photo x,y wxh | clip x,y wxh | cut ct=<px> cb=<px> shows=<px>
--       | model x,y wxh shown=<lua> java=<java> | zoom=<set> (Build's maths <want>) yoffset=<set> (Build's maths <want>)
--       | fit=<elementH / (fullH - ct - cb)> | ppu=<px per unit> x<vs reference> | origin=<px below frame top> (<vs reference>)
--   (photo, clip and model in the drawer's frame, the one the tab draws in; the model's window x,y is drawer + ox,oy)
-- Checks at each step (PASS / FAIL):
--   shows     the figure shows while more than 6 px (Equip) / 20 px (Identity: its own rule, unchanged by the fix) of
--             its frame shows, hidden at that or less
--   inside    the figure's element stays inside the tab's view (the clip)
--   fit       the element covers exactly the part of the frame that shows (elementH / (fullH - ct - cb) = 1)
--   size      ppu within 2 % of the reference (pos 0, or the first step it shows)
--   place     the figure's origin within max(1.5 px, 1 % of the frame) of the reference
-- Puts back: the Equip view, the tab, both scroll positions, the window's height (and the layout), the Identity photo's
-- state and zoom, the theme, the pointer, the model's own setZoom / setYOffset, the window pair as found.
if not RT then print("ZEDQA fig_scroll ERR rt_kit.lua did not run first"); print("ZEDQA fig_scroll DONE"); return end
local Q = RT.make("fig_scroll")
Q.maxMs = 780000                     -- (the runner gives this script 900 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, shots = {}, shrinks = {}, errs = 0 }
S.POS = { 0, 0.1, 0.2, 0.3, 0.45, 0.6, 0.8, 1 }
S.SQ = math.sqrt(2048)
S.STRIP_W = 36                       -- (ZeD_CharacterWindow's TAB_STRIP_W: the model's x is T.px(36) + the frame's x)
S.SURF = {
    equip = { key = "equip", tab = "equip", scroll = "_equipScroll", frame = "_equipDollPhoto", clip = "_equipDollClip", hideAt = 6 },
    identity = { key = "identity", tab = "identity", scroll = "_identityScroll", frame = "_identityPhotoRect", clip = "_idView", hideAt = 20 },
}

-- ===================================================================== small helpers (et_calls')
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.note(s) Q.say("NOTE " .. tostring(s)) end
function S.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function S.wait(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end
function S.waitIdle(n) Q.step(n, function() end) end
function S.i(v) local x = tonumber(v); if x == nil then return "?" end; return tostring(math.floor(x + 0.5)) end
function S.n2(v) local x = tonumber(v); if x == nil then return "?" end; return string.format("%.2f", x) end
function S.n3(v) local x = tonumber(v); if x == nil then return "?" end; return string.format("%.3f", x) end
function S.n4(v) local x = tonumber(v); if x == nil then return "?" end; return string.format("%.4f", x) end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function S.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function S.px(v) local r = v; pcall(function() r = ZeD.T.px(v) end); return r end
function S.rect(x, y, w, h) return S.i(x) .. "," .. S.i(y) .. " " .. S.i(w) .. "x" .. S.i(h) end
function S.sc(sp) local w = RT.cw(); return w and w[sp.scroll] or nil end

-- ===================================================================== pictures (et_calls'; a name may be a function)
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
function S.shot(name, what, gate)
    local st = {}
    Q.step(1, function()
        if S.dead then return end
        if gate and not gate() then st.off = true; return end
        st.mine = S.parked == nil
        S.park(true)
    end)
    Q.step(4, function()
        if st.off then return end
        if S.dead then if st.mine then S.park(false) end; return end
        local nm = (type(name) == "function") and name() or name
        local file = tostring(nm) .. ".png"
        if type(what) == "function" then what = what() end
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then S.shots[#S.shots + 1] = file; Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. tostring(what))
        else Q.say("NOTE the picture " .. tostring(nm) .. " was not taken: " .. tostring(e)) end
        if st.mine then S.park(false) end
    end)
    Q.waitMs(1500)
end

-- ===================================================================== the theme (et_calls')
function S.theme(key)
    local o = S.zopt("baseTheme")
    local i = nil
    for k, v in ipairs(ZeD.Settings.baseKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.back.theme = true
end
function S.themeBack()
    if not S.back.theme then return end
    S.back.theme = nil
    local o = S.zopt("baseTheme")
    if o and S.found.baseIdx then pcall(function() o:setValue(S.found.baseIdx) end) end
    pcall(ZeD.applyTheme, S.found.base, nil, nil)
end

-- ===================================================================== the window made shorter (sb_edges')
-- frac: the share of the height to keep (nil: the window's minimum)
function S.shrinkOn(win, frac)
    if not win then return false end
    local h = win:getHeight()
    local minH = win.minimumHeight or S.px(220)
    local nh = frac and math.max(minH, math.floor(h * frac)) or minH
    if nh >= h then return false end
    S.shrinks[#S.shrinks + 1] = { win = win, h = h }
    S.layoutTouched = true
    win:setHeight(nh)
    return true
end
function S.shrinkBack()
    for i = #S.shrinks, 1, -1 do
        local s = S.shrinks[i]
        pcall(function() s.win:setHeight(s.h) end)
    end
    S.shrinks = {}
end

-- ===================================================================== the figure
-- the model element: win._identityModel (the Identity photo and the Equip doll share it, old code and Build's); else
-- the first ISUI3DModel the window keeps
function S.model(w)
    if type(w) ~= "table" then return nil end
    local m = w._identityModel
    if type(m) == "table" and m.javaObject ~= nil and type(m.getHeight) == "function" then return m end
    local found = nil
    for k, v in pairs(w) do
        if not found and type(v) == "table" and v.Type == "ISUI3DModel" and v.javaObject ~= nil then found = v; S.modelKey = tostring(k) end
    end
    return found
end
-- setZoom / setYOffset wrapped on the instance (ISUI3DModel has no getter): the last values set are recorded
function S.spyOn(m)
    if S.spy then return true end
    if type(m) ~= "table" then return false end
    local fz, fy = m.setZoom, m.setYOffset
    if type(fz) ~= "function" or type(fy) ~= "function" then return false end
    local sp = { m = m, z0 = rawget(m, "setZoom"), y0 = rawget(m, "setYOffset"), n = 0 }
    S.found.rz, S.found.ry = sp.z0, sp.y0
    m.setZoom = function(self, z) sp.z = z; sp.n = sp.n + 1; return fz(self, z) end
    m.setYOffset = function(self, y) sp.yo = y; return fy(self, y) end
    S.spy = sp
    return true
end
function S.spyOff()
    local sp = S.spy
    if not sp then return end
    S.spy = nil
    sp.m.setZoom = sp.z0
    sp.m.setYOffset = sp.y0
end
function S.shown(m)
    local lv, jv = false, nil
    pcall(function() lv = m:isVisible() and true or false end)
    pcall(function()
        local j = m.javaObject
        if j and instanceof(j, "UI3DModel") then jv = j:isVisible() and true or false end
    end)
    return lv, jv
end
-- the camera Build's code starts from: (zoom, y offset) of the whole frame
function S.z0(sp, w)
    if sp.key == "equip" then return 0, 0 end
    if w and w._identityPhotoExpanded then return tonumber(w._identityCustomZoom) or 0, 0 end
    return 19, -0.875                -- (BUST_ZOOM, BUST_Y_OFFSET in ZeD_CharacterWindow)
end
-- one step's reading: the frame, the clip, the cut, the element, the camera
function S.read(sp)
    local r = { ok = false }
    local w = RT.cw()
    if not w then r.why = "no Character window"; return r end
    local fr, cl = w[sp.frame], w[sp.clip]
    if type(fr) ~= "table" or tonumber(fr.h) == nil then r.why = "no photo frame (win." .. sp.frame .. ")"; return r end
    r.fx, r.fy, r.fw, r.fh = fr.x, fr.y, fr.w, fr.h
    if type(cl) == "table" and tonumber(cl.h) ~= nil then
        r.cx, r.cy, r.cw, r.ch, r.hasClip = cl.x, cl.y, cl.w, cl.h, true
    else
        r.cx, r.cy, r.cw, r.ch = r.fx, 0, r.fw, 100000
        pcall(function() r.cy = ZeD.Molecules.getTabHeaderH() end)
    end
    r.ct = math.max(0, r.cy - r.fy)
    r.cb = math.max(0, (r.fy + r.fh) - (r.cy + r.ch))
    r.shows = r.fh - r.ct - r.cb
    r.ox = S.px(S.STRIP_W)
    r.oy = 0
    pcall(function() r.oy = w:getBodyY() end)
    local m = S.model(w)
    if not m then r.why = "no figure (win._identityModel, nor any ISUI3DModel on the window)"; return r end
    r.mx, r.my = m:getX() - r.ox, m:getY() - r.oy
    r.mw, r.mh = m:getWidth(), m:getHeight()
    r.lv, r.jv = S.shown(m)
    r.ok = true
    r.fit = r.mh / math.max(1, r.shows)
    local spy = S.spy
    if spy and spy.n > 0 then r.z, r.yo = spy.z, spy.yo end
    if r.lv and r.z ~= nil and r.z < 25 then
        r.ppu = r.mh * S.SQ / (2 * (25 - r.z))
        local ye = tonumber(r.yo) or 0
        if ye == 0 then ye = -0.5 end
        r.anchor = (r.my - r.fy) + r.mh / 2 - ye * r.ppu
    end
    -- Build's maths for this cut (to check the camera by hand)
    local z0, yo0 = S.z0(sp, w)
    r.zWant, r.yWant = z0, yo0
    if r.ct > 0 or r.cb > 0 then
        local size = 25 - z0
        local ye0 = (yo0 == 0) and -0.5 or yo0
        r.zWant = 25 - size * r.shows / r.fh
        r.yWant = ye0 + (r.ct - r.cb) * size / (r.fh * S.SQ)
    end
    return r
end
function S.fig(T, r)
    if not r.ok then Q.say("FIG " .. T.key .. " pos=" .. S.n2(r.pos) .. " | " .. tostring(r.why)); return end
    local ref = T.ref
    Q.say("FIG " .. T.key .. " pos=" .. S.n2(r.pos) .. " (read " .. S.n3(r.read) .. ")"
        .. " | photo " .. S.rect(r.fx, r.fy, r.fw, r.fh)
        .. " | clip " .. S.rect(r.cx, r.cy, r.cw, r.ch) .. (r.hasClip and "" or " (no clip published: the tab header's bottom)")
        .. " | cut ct=" .. S.i(r.ct) .. " cb=" .. S.i(r.cb) .. " shows=" .. S.i(r.shows)
        .. " | model " .. S.rect(r.mx, r.my, r.mw, r.mh) .. " shown=" .. tostring(r.lv) .. " java=" .. tostring(r.jv)
        .. " (window +" .. S.i(r.ox) .. ",+" .. S.i(r.oy) .. ")"
        .. " | zoom=" .. (r.z ~= nil and S.n3(r.z) or "not set") .. " (Build's maths " .. S.n3(r.zWant) .. ")"
        .. " yoffset=" .. (r.yo ~= nil and S.n4(r.yo) or "not set") .. " (Build's maths " .. S.n4(r.yWant) .. ")"
        .. " | fit=" .. S.n3(r.fit)
        .. " | ppu=" .. S.n2(r.ppu) .. ((ref and ref.ppu and r.ppu) and (" x" .. S.n3(r.ppu / ref.ppu)) or "")
        .. " | origin=" .. S.n2(r.anchor) .. ((ref and ref.anchor and r.anchor) and (" (" .. S.n2(r.anchor - ref.anchor) .. ")") or ""))
end
function S.judge(T, sp, r)
    local lab = T.lab .. " at " .. S.n2(r.pos)
    if not Q.check(r.ok, lab .. ": the photo frame and the figure can be read", r.why) then return end
    local hideAt = S.px(sp.hideAt)
    local want = r.shows > hideAt
    Q.check(r.lv == want and (r.jv == nil or r.jv == r.lv),
        lab .. ": the figure shows while more than " .. S.i(hideAt) .. " px of its frame shows, hidden at that or less",
        S.i(r.shows) .. " px of " .. S.i(r.fh) .. " show, the figure " .. (r.lv and "shown" or "hidden") .. " (its Java side " .. tostring(r.jv) .. ")")
    if not r.lv then return end
    if r.hasClip then
        local inX = r.mx >= r.cx - 1 and r.mx + r.mw <= r.cx + r.cw + 1
        local inY = r.my >= r.cy - 1 and r.my + r.mh <= r.cy + r.ch + 1
        Q.check(inX and inY, lab .. ": the figure's element stays inside the tab's view",
            "model " .. S.rect(r.mx, r.my, r.mw, r.mh) .. ", view " .. S.rect(r.cx, r.cy, r.cw, r.ch))
    end
    Q.check(math.abs(r.mh - r.shows) <= 1 and math.abs(r.my - (r.fy + r.ct)) <= 1,
        lab .. ": the element covers exactly the part of the frame that shows (element h / (fullH - ct - cb) = 1)",
        "fit " .. S.n3(r.fit) .. ", element y " .. S.i(r.my) .. " (frame top + ct " .. S.i(r.fy + r.ct) .. ")")
    if not T.ref then
        T.ref = r
        S.note(lab .. ": the reference for the figure's size and place (ppu " .. S.n2(r.ppu) .. ", origin " .. S.n2(r.anchor)
            .. " px below the frame's top, cut ct=" .. S.i(r.ct) .. " cb=" .. S.i(r.cb) .. ")")
    end
    local ref = T.ref
    if r.ppu == nil or ref.ppu == nil then
        Q.skip(lab .. ": the figure's size and place", "the camera's zoom was not seen this step (setZoom not called)")
        return
    end
    if math.abs(r.fh - ref.fh) > 1 then S.note(lab .. ": the frame is " .. S.i(r.fh) .. " px tall, " .. S.i(ref.fh) .. " at the reference") end
    local k = r.ppu / ref.ppu
    Q.check(math.abs(k - 1) <= 0.02,
        lab .. ": the figure keeps its size (pixels per world unit as at " .. S.n2(ref.pos) .. ", within 2 %)",
        "x" .. S.n3(k) .. " (ppu " .. S.n2(r.ppu) .. ", reference " .. S.n2(ref.ppu) .. "; zoom " .. S.n3(r.z) .. ", element h " .. S.i(r.mh) .. ")")
    local d = r.anchor - ref.anchor
    local tol = math.max(1.5, r.fh * 0.01)
    Q.check(math.abs(d) <= tol,
        lab .. ": the figure keeps its place in the frame (cut at the view's edge, not moved)",
        S.n2(d) .. " px off (tolerance " .. S.n2(tol) .. "; origin " .. S.n2(r.anchor) .. ", reference " .. S.n2(ref.anchor) .. ")")
end

-- ===================================================================== one surface
function S.ready(sp)
    local w = RT.cw()
    if not (w and w._activeTab == sp.tab and type(w[sp.frame]) == "table") then return false end
    if sp.key == "equip" then return w._equipDollShown == true end
    return true
end
function S.label(T, sp)
    local w = RT.cw()
    if sp.key == "equip" then T.key, T.pic, T.lab = "equip", "equip", "Equip doll"; return end
    local st = (w and w._identityPhotoExpanded) and "full" or "bust"
    T.key, T.pic, T.lab = "identity_" .. st, "identity_" .. st, "Identity photo (" .. ((st == "full") and "full body" or "bust") .. ")"
end
-- the Identity photo switched the player's way: a click on the figure (its onMouseDown / onMouseUp); the photo's own
-- fields when the figure cannot be clicked
function S.idToggle(T)
    local w = RT.cw()
    if not w then T.off = true; return end
    local was = w._identityPhotoExpanded and true or false
    local m = S.model(w)
    local how = "a click on the figure"
    if m and S.shown(m) then
        pcall(function() m:onMouseDown(2, 2) end)
        pcall(function() m:onMouseUp(2, 2) end)
    end
    if (w._identityPhotoExpanded and true or false) == was then
        how = "the photo's own fields (the figure was not there to click)"
        w._identityPhotoExpanded = not was
        w._identityCustomZoom = 0
        if w._identityScroll then pcall(function() w._identityScroll:setScrollPos(0) end) end
    end
    S.back.idExp = true
    Q.check((w._identityPhotoExpanded and true or false) ~= was,
        "identity: the photo switched to " .. ((not was) and "the full body" or "the bust"), how)
end
-- the tab made to scroll: the window made shorter (half, then its minimum) while it does not
function S.ensureScroll(T, sp)
    S.step(1, function()
        if T.off then return end
        local sc = S.sc(sp)
        if sc and sc.visible then return end
        T.shrunk = S.shrinkOn(RT.cw(), 0.5) or T.shrunk
    end)
    S.waitIdle(20)
    S.step(1, function()
        if T.off then return end
        local sc = S.sc(sp)
        if sc and sc.visible then return end
        T.shrunk = S.shrinkOn(RT.cw(), nil) or T.shrunk
    end)
    S.waitIdle(20)
    S.step(1, function()
        if T.off then return end
        local sc = S.sc(sp)
        local w = RT.cw()
        if not (sc and sc.visible) then
            T.off = true
            Q.skip(T.lab .. ": the scroll steps", "the tab does not scroll here, even with the window made shorter ("
                .. S.i(w and w:getHeight()) .. " px tall; win." .. sp.scroll .. " " .. type(sc) .. ")")
            return
        end
        S.note(T.lab .. ": the tab scrolls" .. (T.shrunk and (" with the window made shorter, " .. S.i(w:getHeight()) .. " px tall")
            or (" at the window's own size, " .. S.i(w:getHeight()) .. " px tall")))
    end)
end
function S.atPos(T, sp, pos)
    S.step(1, function()
        if T.off then return end
        local sc = S.sc(sp)
        pcall(function() sc:setScrollPos(pos) end)
        if S.spy then S.spy.n = 0 end
    end)
    S.waitIdle(6)
    S.step(1, function()
        if T.off then return end
        local r = S.read(sp)
        local sc = S.sc(sp)
        r.pos, r.read = pos, sc and sc.scrollPos or nil
        S.fig(T, r)
        S.judge(T, sp, r)
        if r.read ~= nil and math.abs(r.read - pos) > 0.01 then S.note(T.lab .. ": the scroll asked " .. S.n2(pos) .. " reads " .. S.n3(r.read)) end
    end)
    S.shot(function() return "fig_" .. T.pic .. "_" .. S.i(pos * 100) .. "_" .. S.sizeTag() end,
        function() return T.lab .. " at scroll " .. S.n2(pos) end, function() return not T.off end)
end
function S.run(sp, opt)
    local T = { key = sp.key, pic = sp.key, lab = sp.key }
    S.step(2, function()
        local w = RT.cw()
        if not w then T.off = true; return end
        if sp.key == "equip" then
            w._equipSelected = nil
            if ZeD.EquipDoll and ZeD.EquipDoll.view() ~= "doll" then pcall(ZeD.EquipDoll.setView, "doll"); S.back.view = true end
        end
        if w._drawerItem then S.note(sp.key .. ": an item card is open over the drawer (the figure hides under it)") end
        if not RT.charTab(sp.tab) then T.off = true; Q.skip(sp.key, "its tab could not be pressed (" .. table.concat(RT.tabs(RT.charStrip()), ", ") .. ")") end
    end)
    S.wait(4, 300, function() return T.off or S.ready(sp) end, function(ok)
        if T.off then return end
        if not Q.check(ok, sp.key .. ": the tab draws its photo frame (win." .. sp.frame .. ")") then T.off = true end
    end)
    S.waitIdle(10)
    if opt and opt.toggle then
        S.step(1, function()
            if T.off then return end
            local sc = S.sc(sp)
            if sc then pcall(function() sc:setScrollPos(0) end) end
        end)
        S.waitIdle(6)
        S.step(1, function() if not T.off then S.idToggle(T) end end)
        S.waitIdle(12)
    end
    S.step(1, function() S.label(T, sp) end)
    S.ensureScroll(T, sp)
    for _, pos in ipairs(S.POS) do S.atPos(T, sp, pos) end
    S.step(1, function()
        local sc = S.sc(sp)
        if sc then pcall(function() sc:setScrollPos(0) end) end
        if T.shrunk then S.shrinkBack(); T.shrunk = nil end
    end)
    S.waitIdle(10)
end

-- ===================================================================== setup and put-back
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.err0 = S.errN()
        f.pair = RT.isOpen()
        f.base, f.baseIdx = ZeD.currentBase, S.optVal(S.zopt("baseTheme"))
        f.size = ZeD.currentSize
        f.view = ZeD.EquipDoll and ZeD.EquipDoll.view and ZeD.EquipDoll.view() or "list"
        if ZEDQA_LAYOUT_SNAP and f.pair then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        S.back.on = true
        RT.pairOpen()
    end)
    S.wait(10, 300, function() local w = RT.cw(); return w ~= nil and w._tabStripPanel ~= nil end, function(ok)
        local w = RT.cw()
        if not Q.check(ok and w ~= nil, "setup: the Character window is open") then S.dead = true; return end
        local f = S.found
        f.charTab = w._activeTab
        f.h = w:getHeight()
        f.eqPos = w._equipScroll and w._equipScroll.scrollPos or nil
        f.idPos = w._identityScroll and w._identityScroll.scrollPos or nil
        f.idExp = w._identityPhotoExpanded
        f.idZoom = w._identityCustomZoom
        local m = S.model(w)
        local spied = S.spyOn(m)
        f.recorded = true
        if not Q.check(m ~= nil and spied, "setup: the figure (win._identityModel) is there and its setZoom / setYOffset can be watched",
            (m ~= nil) and ("found" .. (S.modelKey and (" as win." .. S.modelKey) or "")) or "no ISUI3DModel on the window") then
            S.dead = true
            return
        end
        if f.base ~= "dark" then S.theme("dark") end
        S.park(true)
        Q.say("found: tab " .. tostring(f.charTab) .. ", Equip view " .. tostring(f.view) .. ", theme " .. tostring(f.base)
            .. ", text " .. tostring(f.size) .. ", window " .. S.i(w:getWidth()) .. "x" .. S.i(f.h) .. ", scrolls equip "
            .. S.n3(f.eqPos) .. " identity " .. S.n3(f.idPos) .. ", Identity photo " .. (f.idExp and "full body" or "bust")
            .. ", screen " .. S.sizeTag())
        S.note("the code: " .. ((type(w._fitFigureCut) == "function") and "Build's fix is in (win._fitFigureCut)"
            or "the old code (no win._fitFigureCut: the figure fitted to the part showing, so the size checks FAIL)"))
    end)
    S.waitIdle(10)
end
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    S.spyOff()
    S.park(false)
    S.shrinkBack()
    S.themeBack()
    if S.back.view and ZeD.EquipDoll and f.view and ZeD.EquipDoll.view() ~= f.view then pcall(ZeD.EquipDoll.setView, f.view) end
    S.back.view = nil
    local w = RT.cw()
    if w and f.recorded then
        w._identityPhotoExpanded = f.idExp
        w._identityCustomZoom = f.idZoom
        S.back.idExp = nil
    end
end
function S.scrollsBack()
    local f, w = S.found, RT.cw()
    if not (w and f.recorded) then return end
    if w._equipScroll and f.eqPos then pcall(function() w._equipScroll:setScrollPos(f.eqPos) end) end
    if w._identityScroll and f.idPos then pcall(function() w._identityScroll:setScrollPos(f.idPos) end) end
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function() S.putBack() end)
    Q.step(10, function()
        local f = S.found
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "fig_scroll") end
        if f.charTab then RT.charTab(f.charTab) end
        S.scrollsBack()
    end)
    Q.step(20, function() S.scrollsBack() end)
    Q.step(10, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        local w = RT.cw()
        local m = S.model(w)
        Q.check(ZeD.currentBase == f.base and (not ZeD.EquipDoll or ZeD.EquipDoll.view() == f.view),
            "put back: the theme and the Equip view as found", tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.EquipDoll and ZeD.EquipDoll.view()))
        if w then
            local eq = w._equipScroll and w._equipScroll.scrollPos or nil
            local id = w._identityScroll and w._identityScroll.scrollPos or nil
            local near = function(a, b) return (a == nil and b == nil) or (a ~= nil and b ~= nil and math.abs(a - b) <= 0.01) end
            Q.check(w._activeTab == f.charTab and math.abs(w:getHeight() - f.h) <= 1 and #S.shrinks == 0,
                "put back: the Character window's tab and height as found",
                "tab " .. tostring(w._activeTab) .. " (found " .. tostring(f.charTab) .. "), height " .. S.i(w:getHeight()) .. " (" .. S.i(f.h) .. ")")
            Q.check(near(eq, f.eqPos) and near(id, f.idPos), "put back: both scroll positions as found",
                "equip " .. S.n3(eq) .. " (" .. S.n3(f.eqPos) .. "), identity " .. S.n3(id) .. " (" .. S.n3(f.idPos) .. ")")
            Q.check(w._identityPhotoExpanded == f.idExp and w._identityCustomZoom == f.idZoom,
                "put back: the Identity photo's state and zoom as found",
                tostring(w._identityPhotoExpanded) .. ", " .. tostring(w._identityCustomZoom))
        end
        Q.check(S.parked == nil and S.spy == nil and (m == nil or (rawget(m, "setZoom") == f.rz and rawget(m, "setYOffset") == f.ry)),
            "put back: the pointer and the figure's setZoom / setYOffset the game's own again")
        local e1 = S.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the run's Lua error count", "the game's Lua error count cannot be read here") end
        Q.say("pictures: " .. #S.shots)
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
    end)
end

-- ===================================================================== the run
S.setup()
S.run(S.SURF.equip, nil)
S.run(S.SURF.identity, nil)
S.run(S.SURF.identity, { toggle = true })
S.buildPutBack()
Q.start()
