-- ZeDUI/tools/qa/vx_input.lua  (Nov 21 2026, QA beast day): the in-game proof of Build's fixes for the input findings
-- W11 W12 W13 W14 W15 W48 of ZeDUI/qa/audits/2026-11-21_beast_code_sweep.md (Build's commit 2a00af40d, and
-- f22910bc2: the Keyboard map's key box x worked out before the row cull, after 2a00af40d broke its mouse clicks).
-- Run after zedqa_prelude.lua and rt_kit.lua. grep "ZEDQA vx_inp".
--
-- Each check is something the player meets, and each says what the old code showed:
--   W11  the pad keyboard (ZeD.padType on a stand-in text box): a click on q types q (old: nothing), the key under
--        the pointer is drawn lit and pressed (old: never), a click on Back closes it (old: stays up)
--   W48  the Keyboard map open for 3 s: the binds are read about once a second (old: every frame) and only the rows
--        in view are drawn (old: all ~190); the rows still show when scrolled; a click on a row's key box still
--        starts and ends listening (a guard: it worked before 2a00af40d, threw on 2a00af40d, works since f22910bc2;
--        no key is ever set, keysB42.ini is not touched)
--   W13  the icon strip: a click on a cell the pointer has only just reached runs that cell (old: the cell that was
--        selected before, the first one)
--   W14  the icon strip, the pointer resting on a cell: an arrow key, the wheel and the D-pad step the selection and
--        it holds over the game's next updates, and A runs the one stepped to (old: back under the pointer in 100 ms)
--   W15  a strip of 11+ actions stands on its place on the first drawn frame, on opening, into a submenu and back
--        out (old: it slid there over 180 ms)
--   W12  seated in a car pushed to about 25 km/h (BaseVehicle.addImpulse, the engine off), the right-click menu of an
--        item stays open past 3 squares, as a strip and as a list (old: shut past 2 squares); getting out shuts it.
--        A car that will not move: the menu's opening place is moved 5 squares instead, and that is said.
-- The menus are the game's own (ISInventoryPaneContextMenu.createMenu on a given item), with a few rows of the
-- script's own added the way a mod adds them (OnFillInventoryObjectContextMenu), so a click is harmless and tells
-- which row ran; the game's own rows are made harmless before any click.
-- Put back: the keyboard, the map, the menus, the pointer, the Context menu setting, the car, the things given, the
-- place, health; god mode and invincible are on for the whole run.

if not RT then
    print("ZEDQA vx_inp ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx_inp VERDICT FAIL 1")
    print("ZEDQA vx_inp DONE")
    return
end

local Q = RT.make("vx_inp")
Q.maxMs = 290000
local S = { p = RT.p, pn = RT.pn, fired = {}, extras = 0, nest = false, upd = 0, draws = 0, cands = {}, need = {} }
local H = {}
local MINE = "ZeDQA vx "

-- ===================================================================== small helpers
function H.now() return getTimestampMs() end
function H.fl(v) return math.floor(tonumber(v) or 0) end
function H.mod(a, n) return a - math.floor(a / n) * n end
function H.scr() return getCore():getScreenWidth(), getCore():getScreenHeight() end
function H.opt() return ZeD.Settings and ZeD.Settings.contextStyleOption end
function H.vmenu() return getPlayerContextMenu(S.pn) end
function H.menu() local v = H.vmenu(); return v and v._zedMenu or nil end
function H.mine(name) return type(name) == "string" and name:sub(1, #MINE) == MINE end
function H.spot() local w, h = H.scr(); return math.floor(w * 0.5), math.floor(h * 0.45) end
function H.dist(ax, ay, bx, by) local dx, dy = ax - bx, ay - by; return math.sqrt(dx * dx + dy * dy) end

-- the pointer the game reads (Mouse.setXY does not move it)
function H.mouseOn(x, y)
    S.fx, S.fy = x, y
    if S.mouseSwapped then return end
    S.realMX, S.realMY = getMouseX, getMouseY
    S.mouseSwapped = true
    getMouseX = function() return S.fx end
    getMouseY = function() return S.fy end
end
function H.mouseOff()
    if not S.mouseSwapped then return end
    getMouseX, getMouseY = S.realMX, S.realMY
    S.mouseSwapped = false
end

-- ZeD's button drawer, watched for a while (the keyboard's keys and the map's key boxes are drawn with it)
function H.btnWrap()
    if S.btnOrig then return end
    local orig = ZeD.Molecules.drawButton
    S.btnOrig = orig
    ZeD.Molecules.drawButton = function(panel, x, y, w, h, text, variant, pressed, colors, opts)
        local f = S.btnWatch
        if f then pcall(f, panel, x, y, w, h, pressed, opts) end
        return orig(panel, x, y, w, h, text, variant, pressed, colors, opts)
    end
end
function H.btnUnwrap()
    if S.btnOrig then ZeD.Molecules.drawButton = S.btnOrig end
    S.btnOrig, S.btnWatch = nil, nil
end

-- ===================================================================== the menus
-- the script's own rows, added as a mod adds them
function H.fire(target, i) S.fired[#S.fired + 1] = MINE .. tostring(i) end
function H.fill(player, context, items)
    local n = S.extras or 0
    if n <= 0 or not context then return end
    for i = 1, n do context:addOption(MINE .. i, nil, H.fire, i) end
    if S.nest then
        local o = context:addOption(MINE .. "nest", nil, nil)
        local sub = ISContextMenu:getNew(context)
        context:addSubMenu(o, sub)
        for j = 1, 12 do sub:addOption(MINE .. "s" .. j, nil, H.fire, "s" .. j) end
    end
end
-- the game's own rows made harmless: a click only says which row ran
function H.stubList(defs, depth)
    for _, d in ipairs(defs or {}) do
        if type(d) == "table" then
            if not H.mine(d.name) then
                local nm = tostring(d.name)
                d.onFire = function() S.fired[#S.fired + 1] = "the game's '" .. nm .. "'" end
            end
            if d.children and depth < 4 then H.stubList(d.children, depth + 1) end
        end
    end
end
function H.stub(m) if m and m._ctx then H.stubList(m._ctx.actions, 0) end end
function H.sample(m)
    local c = ZeD.T.ctx
    return { o = m._ctx.trackOriginX or 0, want = -(((m._ctx.firstVisible or 1) - 1) * (c.cellW + c.gap)) }
end
function H.off(s) return math.abs(s.o - s.want) > 1 end
-- the carousel at rest and drawn so: no settle waiting, no snap still to draw, the track on its place
function H.settled(m)
    if not (m and m._ctx and m._ctx.open) then return true end
    return m._settleAt == nil and (m._suppressFrames or 0) == 0 and m._ctx.firstVisible ~= nil and not H.off(H.sample(m))
end
-- a menu's own update counted and its drawn frames sampled (the game runs update about every 100 ms)
function H.unwatch()
    local m = S.wm
    if m then m.prerender, m.update = S.wPre, S.wUpd end
    S.wm = nil
end
function H.watch(m)
    if not m or S.wm == m then return end
    H.unwatch()
    S.wm, S.upd, S.draws = m, 0, 0
    S.wPre, S.wUpd = rawget(m, "prerender"), rawget(m, "update")
    local pre, upd = m.prerender, m.update
    m.prerender = function(self)
        pre(self)
        S.draws = S.draws + 1
        if S.tr and self._ctx and self._ctx.firstVisible then S.tr[#S.tr + 1] = H.sample(self) end
    end
    m.update = function(self)
        S.upd = S.upd + 1
        return upd(self)
    end
end
function H.closeMenu()
    local m = H.menu()
    if m then pcall(m.close, m) end
    if S.m and S.m ~= m and S.m._ctx and S.m._ctx.open then pcall(S.m.close, S.m) end
    local v = H.vmenu()
    if v and not v._zedMenu and v.closeAll then pcall(function() if v:isVisible() then v:closeAll() end end) end
    H.unwatch()
    H.mouseOff()
    S.m, S.tr = nil, nil
end
-- a right-click on an item of the bag, as the game makes it; style 1 the strip, 2 the list
function H.open(item, extras, nest, style)
    H.closeMenu()
    S.fired, S.openErr = {}, nil
    local o = H.opt()
    if o then pcall(function() o:setValue(style) end) end
    local x, y = H.spot()
    H.mouseOn(x, y)
    S.extras, S.nest = extras, nest
    local ok, e = pcall(ISInventoryPaneContextMenu.createMenu, S.pn, true, { item }, x, y)
    S.extras, S.nest = 0, false
    if not ok then S.openErr = tostring(e) end
    S.askedAt = H.now()
end
-- ZeD's menu is up, or it is settled that none will come
function H.opened()
    if S.openErr then return true end
    if H.menu() then return true end
    local v = H.vmenu()
    if not v then return true end
    if v._zedFailed then return true end
    return H.now() - (S.askedAt or 0) > 2500
end
function H.zone(m, id)
    for _, z in ipairs(m and m._hitZones or {}) do if z.id == id then return z end end
    return nil
end
function H.idx(m, name)
    for i, d in ipairs(m._ctx.items or {}) do if d.name == name then return i end end
    return nil
end
function H.leaf(m, d)
    if not d or d.isBack or d.subOption or (d.children and #d.children > 0) then return false end
    return not (d.disabled and d.disabled(m._ctx.target))
end
-- the middle of a zone: in the menu's own space, and on screen
function H.mid(m, z)
    local cx, cy = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    return cx, cy, math.floor(m:getAbsoluteX()) + cx, math.floor(m:getAbsoluteY()) + cy
end
function H.nameAt(m, i) local d = m._ctx.items[i]; return d and tostring(d.name) or "?" end

-- ===================================================================== the start
Q.step(2, function()
    if getGameSpeed() <= 0 then pcall(setGameSpeed, 1) end
    local p = S.p
    S.godWas, S.invWas = p:isGodMod(), p:isInvincible()
    p:setGodMod(true)
    p:setInvincible(true)
    S.home = { x = p:getX(), y = p:getY() }
    S.inv0 = p:getInventory():getItems():size()
    local o = H.opt()
    if o then pcall(function() S.styleWas = o:getValue() end) end
    H.closeMenu()
    Events.OnFillInventoryObjectContextMenu.Add(H.fill)
    S.fillOn = true
    for _, ft in ipairs({ "Base.Plank", "Base.Nails", "Base.Pencil", "Base.Spoon" }) do
        if getScriptManager():FindItem(ft) ~= nil then
            local it = RT.give(ft)
            if it then S.cands[#S.cands + 1] = it end
        end
    end
    Q.say("NOTE start: god mode " .. tostring(p:isGodMod()) .. ", invincible " .. tostring(p:isInvincible()) .. ", "
        .. #S.cands .. " things given, Context menu setting " .. tostring(S.styleWas))
end)

-- ===================================================================== W11: the pad keyboard takes a click
function H.key(kb, pred)
    local g = kb and kb._g
    for _, row in ipairs(g and g.keys or {}) do
        for _, r in ipairs(row) do if pred(r.k) then return r end end
    end
    return nil
end
function H.kbText() local t = ""; pcall(function() t = S.kb.box:getInternalText() end); return tostring(t) end
function H.kbAway()
    local K = S.kb
    S.btnWatch = nil
    H.btnUnwrap()
    if not K then return end
    if K.kbd and K.wrapped then K.kbd.prerender = K.preRaw; K.wrapped = false end
    pcall(function() ZeD.Keyboard.hide() end)
    pcall(function() K.box:unfocus() end)
    pcall(function() K.box:removeFromUIManager() end)
    H.mouseOff()
    S.kb = nil
end
function H.kbUp() return S.kb ~= nil and ZeD.Keyboard.isVisible() and ZeD.Keyboard.instance._g ~= nil end
-- a press on a key now; the release comes once the keyboard has drawn again (it lays its keys out anew every frame)
function H.kbDown(pred)
    local K = S.kb
    local r = H.key(K.kbd, pred)
    K.g0 = K.kbd._g
    if not r then K.noKey = true; return false end
    K.noKey = false
    return pcall(K.kbd.onMouseDown, K.kbd, r.x + 2, r.y + 2)
end
function H.kbRedrawn() return S.kb == nil or S.kb.noKey or not H.kbUp() or S.kb.kbd._g ~= S.kb.g0 end
function H.kbRelease(pred)
    local K = S.kb
    local r = H.key(K.kbd, pred)
    if not r then return false end
    return pcall(K.kbd.onMouseUp, K.kbd, r.x + 2, r.y + 2)
end
function H.isQ(k) return k.lo == "q" end
function H.isW(k) return k.lo == "w" end
function H.isBack(k) return k.id == "back" end

Q.step(3, function()
    local KB = ZeD.Keyboard
    S.kb = nil
    if not (KB and KB.edit and ISTextEntryBox) then Q.check(false, "W11 staged: ZeD's pad keyboard is loaded"); return end
    local T = ZeD.T
    local box = ISTextEntryBox:new("", T.px(100), T.px(100), T.px(200), T.px(24))
    box:initialise()
    box:instantiate()
    box:addToUIManager()
    S.kb = { box = box, hov = 0, down = 0, frames = 0 }
    local ok = false
    pcall(function() ok = KB.edit(box, S.pn) end)
    local kbd = KB.instance
    if not (ok and kbd and kbd.textEntryBox == box) then
        Q.check(false, "W11 staged: ZeD's pad keyboard opens on a text box (ZeD.padType)", "opened " .. tostring(ok))
        H.kbAway()
        return
    end
    S.kb.kbd = kbd
end)
Q.waitFor(1, 90, function() return S.kb == nil or H.kbUp() end, function(ok)
    local K = S.kb
    if not K then return end
    if not (ok and H.kbUp()) then
        Q.check(false, "W11 staged: the keyboard shows and has laid out its keys")
        H.kbAway()
        return
    end
    local kbd = K.kbd
    -- its drawn frames counted, and how its keys are drawn (lit under the pointer, pressed)
    K.preRaw = rawget(kbd, "prerender")
    local pre = kbd.prerender
    kbd.prerender = function(self) K.frames = K.frames + 1; return pre(self) end
    K.wrapped = true
    H.btnWrap()
    S.btnWatch = function(panel, x, y, w, h, pressed, opts)
        if panel ~= kbd then return end
        if opts and opts.hover and x == K.wx then K.hov = K.hov + 1 end
        if pressed and x == K.wx then K.down = K.down + 1 end
    end
    H.kbDown(H.isQ)
end)
Q.waitFor(1, 60, H.kbRedrawn, function()
    if not S.kb then return end
    if S.kb.noKey or not H.kbUp() then Q.check(false, "W11 staged: the keyboard has a q key and stays up"); H.kbAway(); return end
    H.kbRelease(H.isQ)
end)
Q.waitFor(2, 150, function() return S.kb == nil or not H.kbUp() or H.kbText() == "q" end, function(ok)
    if not S.kb then return end
    Q.check(ok and H.kbText() == "q", "W11: a click on the keyboard's q key types q (press, a drawn frame, release on the same key)",
        "the field reads '" .. H.kbText() .. "'. Old code: the field stayed empty, the release never matched the press")
    if not H.kbUp() then H.kbAway(); return end
    -- the pointer comes to rest on the w key
    local K = S.kb
    local r = H.key(K.kbd, H.isW)
    if not r then Q.check(false, "W11 staged: the keyboard has a w key"); H.kbAway(); return end
    K.wx, K.wk, K.at = r.x, r.k, H.now()
    H.mouseOn(H.fl(K.kbd:getAbsoluteX()) + r.x + H.fl(r.w / 2), H.fl(K.kbd:getAbsoluteY()) + r.y + H.fl(r.h / 2))
end)
-- (the keyboard reads the pointer in its own update, about every 100 ms: wait until it has read the w key there.
-- Old and new code both keep that key in _hover; only the draw's test of it changed)
Q.waitFor(1, 120, function()
    local K = S.kb
    if not (K and K.wk and H.kbUp()) then return true end
    local hv = K.kbd._hover
    return hv ~= nil and hv.k == K.wk
end, function(ok)
    local K = S.kb
    if not K then return end
    Q.say("NOTE W11: the keyboard's update " .. (ok and "read" or "had not read") .. " the pointer on the w key, "
        .. (H.now() - (K.at or 0)) .. " ms after it came to rest there")
    K.hov, K.down, K.f0 = 0, 0, K.frames
end)
Q.waitFor(1, 240, function() return S.kb == nil or not H.kbUp() or S.kb.frames >= S.kb.f0 + 10 end, function()
    local K = S.kb
    if not (K and H.kbUp()) then return end
    local n = K.frames - K.f0
    if K.kbd.joyfocus ~= nil then
        Q.skip("W11: the key under the pointer is drawn lit", "a controller holds the keyboard here: the pointer's look is off by design")
    else
        Q.check(K.hov >= n - 2 and K.hov > 0, "W11: the key under a resting pointer is drawn lit",
            "the w key drawn lit on " .. K.hov .. " of " .. n .. " frames. Old code: on none")
    end
    K.hov, K.down, K.f0 = 0, 0, K.frames
    H.kbDown(H.isW)
end)
Q.waitFor(1, 240, function() return S.kb == nil or not H.kbUp() or S.kb.frames >= S.kb.f0 + 6 end, function()
    local K = S.kb
    if not (K and H.kbUp()) then return end
    local n = K.frames - K.f0
    if K.kbd.joyfocus ~= nil then
        Q.skip("W11: a held key is drawn pressed", "a controller holds the keyboard here")
    else
        Q.check(K.down >= n - 2 and K.down > 0, "W11: a key held down under the pointer is drawn pressed",
            "the w key drawn pressed on " .. K.down .. " of " .. n .. " frames. Old code: on none")
    end
    H.kbRelease(H.isW)
end)
Q.waitFor(2, 150, function() return S.kb == nil or not H.kbUp() or H.kbText() == "qw" end, function(ok)
    if not S.kb then return end
    Q.check(ok and H.kbText() == "qw", "W11: a second click, on w, types w after it", "the field reads '" .. H.kbText() .. "'")
    if H.kbUp() then RT.bounds(Q, "the pad keyboard") end
    if not H.kbUp() then H.kbAway(); return end
    H.kbDown(H.isBack)
end)
Q.waitFor(1, 60, H.kbRedrawn, function()
    if not S.kb then return end
    if S.kb.noKey or not H.kbUp() then return end
    H.kbRelease(H.isBack)
end)
Q.waitFor(1, 90, function() return S.kb == nil or not ZeD.Keyboard.isVisible() end, function(ok)
    if not S.kb then return end
    Q.check(ok and H.kbText() == "qw", "W11: a click on the keyboard's Back key closes it, the text kept",
        "keyboard up " .. tostring(ZeD.Keyboard.isVisible()) .. ", the field reads '" .. H.kbText() .. "'. Old code: it stayed up")
    H.kbAway()
end)

-- ===================================================================== W48: the Keyboard map reads and draws less
function H.kmAway()
    local K = S.km
    S.btnWatch = nil
    H.btnUnwrap()
    if not K then return end
    if K.readOrig then ZeD.KeyboardMap.read = K.readOrig; K.readOrig = nil end
    local win = K.win
    if win then
        if K.wrapped then win.prerender = K.preRaw; K.wrapped = false end
        win.listening = nil
        if not K.wasOpen then pcall(win.close, win) end
    end
    pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
    S.km = nil
end
function H.kmBinds(win)
    local n = 0
    for _, h in ipairs(win._hits or {}) do if h.id == "bind" then n = n + 1 end end
    return n
end
-- how many action rows the map's body can show (its own row height)
function H.kmFit(win)
    local T = ZeD.T
    local rowH = math.max(T.buttonH, ZeD.TM:getFontHeight(T.fontF2)) + T.px(4)
    return math.floor((win._bodyH or 0) / rowH) + 2, rowH
end

Q.step(3, function()
    local KM = ZeD.KeyboardMap
    S.km = nil
    if not (KM and KM.open and KM.read) then Q.check(false, "W48 staged: ZeD's Keyboard map is loaded"); return end
    local K = { reads = 0, frames = 0, ms = 0, rows = {}, n = 0, last = 0 }
    S.km = K
    local was = KM.windows and KM.windows[S.pn]
    K.wasOpen = was ~= nil and was:isReallyVisible()
    K.readOrig = KM.read
    local readOrig = K.readOrig
    KM.read = function() K.reads = K.reads + 1; return readOrig() end
    local win = nil
    local ok, e = pcall(function() win = KM.open(S.pn) end)
    if not (ok and win) then Q.check(false, "W48 staged: the Keyboard map opens", tostring(e)); H.kmAway(); return end
    K.win = win
    K.preRaw = rawget(win, "prerender")
    local pre = win.prerender
    win.prerender = function(self)
        K.n = 0
        local t0 = getTimestampMs()
        pre(self)
        K.ms = K.ms + (getTimestampMs() - t0)
        K.frames = K.frames + 1
        K.last = K.n
    end
    K.wrapped = true
    H.btnWrap()
    -- a row's key box is the map's only compact button
    S.btnWatch = function(panel, x, y, w, h, pressed, opts)
        if panel ~= win or not (opts and opts.compact) then return end
        K.n = K.n + 1
        local r = K.rows[K.n]
        if not r then r = {}; K.rows[K.n] = r end
        r.x, r.y, r.w, r.h = x, y, w, h
    end
end)
Q.waitFor(1, 120, function() return S.km == nil or S.km.frames >= 2 end, function(ok)
    local K = S.km
    if not K then return end
    if not ok then Q.check(false, "W48 staged: the Keyboard map draws"); H.kmAway(); return end
    Q.check(K.reads >= 1, "W48: opening the Keyboard map reads the game's keys at once", K.reads .. " read(s) in its first " .. K.frames .. " frames")
    K.reads, K.f0, K.ms, K.t0 = 0, K.frames, 0, H.now()
end)
Q.waitFor(1, 3000, function() return S.km == nil or H.now() - S.km.t0 >= 3000 end, function()
    local K = S.km
    if not K then return end
    local win = K.win
    local ms = H.now() - K.t0
    local frames = K.frames - K.f0
    local most = math.floor(ms / 1000) + 2
    local seen = K.reads .. " reads of the binds over " .. frames .. " drawn frames in " .. ms .. " ms (at most " .. most
        .. " promised). Old code: one read every frame, " .. frames .. " here"
    if frames < 20 then
        Q.skip("W48: the binds are read about once a second", "only " .. frames .. " frames drawn in 3 s: too few to tell every frame from once a second")
    else
        Q.check(K.reads <= most, "W48: the Keyboard map open for 3 s reads the game's keys about once a second, not every frame", seen)
        Q.check(K.reads >= 2, "W48: it still reads again each second (a key changed in the game's own Options shows)", K.reads .. " reads in " .. ms .. " ms")
    end
    local total = H.kmBinds(win)
    local fit = H.kmFit(win)
    Q.check(total > fit and K.last <= fit, "W48: only the action rows in view are drawn",
        K.last .. " of " .. total .. " rows drawn a frame, the body has room for " .. fit .. ". Old code: all " .. total .. " every frame")
    Q.say(string.format("NOTE W48: the map's draw took %d ms over %d frames at the top of the page", K.ms, frames))
    RT.bounds(Q, "the Keyboard map")
    pcall(function() win:scrollBy(10000000) end)
    K.f0, K.ms = K.frames, 0
end)
Q.waitFor(1, 240, function() return S.km == nil or S.km.frames >= S.km.f0 + 30 end, function()
    local K = S.km
    if not K then return end
    local win = K.win
    local fit, rowH = H.kmFit(win)
    local tb, bodyH = win:titleBarHeight(), win._bodyH or 0
    local out, pick = 0, nil
    for i = 1, K.last do
        local r = K.rows[i]
        if r.y + rowH < tb or r.y > tb + bodyH then out = out + 1 end
        if not pick and r.y >= tb and r.y + r.h <= tb + bodyH then pick = r end
    end
    Q.check(K.last >= 1 and K.last <= fit and out == 0, "W48: scrolled to the end, the rows there are drawn and no others",
        K.last .. " rows drawn (room for " .. fit .. "), " .. out .. " of them outside the body")
    Q.say(string.format("NOTE W48: the map's draw took %d ms over %d frames at the end of the page", K.ms, K.frames - K.f0))
    -- a click on a row's key box, where it is drawn: the row listens for its key; a second click ends that. Both in
    -- this one step, so no key can answer in between and no key is ever set.
    if not pick then Q.check(false, "W48: a row's key box is drawn whole inside the body, to click on", K.last .. " rows drawn"); return end
    local name = nil
    for _, h in ipairs(win._hits or {}) do
        if h.id == "bind" and h.y == pick.y then name = h.name end
    end
    local cx, cy = pick.x + math.floor(pick.w / 2), pick.y + math.floor(pick.h / 2)
    local ok1, e1 = pcall(function() win:onMouseDown(cx, cy); win:onMouseUp(cx, cy) end)
    local heard = win.listening
    local ok2, e2 = pcall(function() win:onMouseDown(cx, cy); win:onMouseUp(cx, cy) end)
    local after = win.listening
    win.listening = nil
    win._down = nil
    pcall(function() win:update() end)   -- (its update gives the game its keys back when nothing listens)
    Q.check(ok1 and name ~= nil and heard == name, "W48: a click on a row's key box still starts listening for that action's key",
        "the row '" .. tostring(name) .. "', listening for '" .. tostring(heard) .. "'" .. ((not ok1) and (", the click threw: " .. tostring(e1)) or ""))
    Q.check(ok2 and after == nil, "W48: a second click on the same box ends the listening, no key set",
        "listening for '" .. tostring(after) .. "'" .. ((not ok2) and (", the click threw: " .. tostring(e2)) or ""))
end)
Q.step(2, function() H.kmAway() end)

-- ===================================================================== W13: a strip click runs the cell clicked
-- a menu of 10 or fewer actions (no carousel): the first thing whose menu is that short, three rows of ours added
for i = 1, 4 do
    Q.step(2, function()
        if S.short or not S.cands[i] then return end
        S.trying = i
        H.open(S.cands[i], 3, false, 1)
    end)
    Q.waitFor(1, 240, function() return S.trying ~= i or (H.opened() and (H.menu() == nil or H.zone(H.menu(), "ctxcell_1") ~= nil)) end, function()
        if S.trying ~= i then return end
        S.trying = nil
        local m = H.menu()
        local n = m and m._ctx and #(m._ctx.items or {}) or 0
        if m and m.Type == "ZeD_ContextMenu" and not m._ctx.truncating and n >= 4 then
            S.short, S.m = S.cands[i], m
            H.stub(m)
            H.watch(m)
        else
            Q.say("NOTE the menu of thing " .. i .. " is not a short strip (" .. tostring(m and m.Type) .. ", " .. n .. " actions"
                .. (S.openErr and (", " .. S.openErr) or "") .. "): the next thing is tried")
            H.closeMenu()
        end
    end)
end
Q.step(2, function()
    local m = S.m
    if not (S.short and m and m._ctx.open) then
        Q.check(false, "W13 staged: an item's menu opened as an icon strip of 10 or fewer actions", #S.cands .. " things tried")
        return
    end
    local sel0 = m._ctx.selected
    local k, z = nil, nil
    for i = 1, 3 do
        local j = H.idx(m, MINE .. i)
        local zj = j and H.zone(m, "ctxcell_" .. j)
        if not k and j and j ~= sel0 and zj and H.leaf(m, m._ctx.items[j]) then k, z = j, zj end
    end
    if not k then Q.check(false, "W13 staged: one of the script's own actions is a cell of the strip, not the selected one"); H.closeMenu(); return end
    local want, was = H.nameAt(m, k), H.nameAt(m, sel0)
    -- the pointer reaches the cell and the click lands before the menu's next update (a flick-click)
    local cx, cy, sx, sy = H.mid(m, z)
    H.mouseOn(sx, sy)
    S.fired = {}
    local ok, e = pcall(m.onMouseUp, m, cx, cy)
    local ran = S.fired[1]
    Q.check(ok and ran == want and #S.fired == 1, "W13: a click on a strip cell the pointer has only just reached runs that cell's action",
        "clicked cell " .. k .. " '" .. want .. "', ran " .. tostring(ran) .. "; the selection was still on cell " .. sel0 .. " '" .. was
        .. "'. Old code: cell " .. sel0 .. "'s action ran" .. ((not ok) and ("; the click threw: " .. tostring(e)) or ""))
    H.closeMenu()
end)

-- ===================================================================== W14: a resting pointer does not undo a step
Q.step(3, function()
    S.w14 = false
    if not S.short then Q.check(false, "W14 staged: an item's menu opened as an icon strip of 10 or fewer actions"); return end
    H.open(S.short, 3, false, 1)
    S.w14 = true
end)
Q.waitFor(1, 240, function() return not S.w14 or (H.opened() and (H.menu() == nil or H.zone(H.menu(), "ctxcell_2") ~= nil)) end, function()
    if not S.w14 then return end
    local m = H.menu()
    if not (m and m.Type == "ZeD_ContextMenu" and not m._ctx.truncating and H.zone(m, "ctxcell_2")) then
        Q.check(false, "W14 staged: the short strip opened again", tostring(m and m.Type) .. (S.openErr and (", " .. S.openErr) or ""))
        S.w14 = false
        H.closeMenu()
        return
    end
    S.m = m
    H.stub(m)
    H.watch(m)
    -- the pointer moves onto cell 2 and stays there
    S.P = 2
    local _, _, sx, sy = H.mid(m, H.zone(m, "ctxcell_2"))
    H.mouseOn(sx, sy)
    S.u0, S.t = S.upd, H.now()
end)
Q.waitFor(1, 900, function() return not S.w14 or S.upd >= S.u0 + 2 or H.now() - S.t > 1500 end, function()
    if not S.w14 then return end
    local m = S.m
    if m._joyfocus then
        Q.skip("W14: the selection follows a pointer that moves onto a cell", "a controller holds the menu here: hover is off by design")
    else
        Q.check(m._ctx.selected == S.P, "W14: the selection still follows a pointer that moves onto a cell",
            "selected cell " .. tostring(m._ctx.selected) .. ", the pointer on cell " .. S.P .. ", " .. (S.upd - S.u0) .. " updates")
    end
end)
-- one way of stepping, then the game's own updates with the pointer still resting on cell P
local function leg(label, press)
    Q.step(1, function()
        if not S.w14 then return end
        local m = S.m
        if not m._ctx.open then S.w14 = false; Q.check(false, "W14 staged: the strip is still open before " .. label); return end
        S.from = m._ctx.selected
        press(m)
        if m._ctx.selected == S.P then press(m) end   -- (a step that lands on the pointer's own cell proves nothing)
        S.expect = m._ctx.selected
        S.u0, S.t = S.upd, H.now()
    end)
    Q.waitFor(1, 900, function() return not S.w14 or S.upd >= S.u0 + 2 or H.now() - S.t > 1500 end, function()
        if not S.w14 then return end
        local m = S.m
        local byGame = S.upd - S.u0
        if byGame < 2 then pcall(m.update, m); pcall(m.update, m) end   -- (the game ran too few: run as the game runs it)
        Q.check(m._ctx.open and m._ctx.selected == S.expect and S.expect ~= S.P,
            "W14: " .. label .. " steps the selection and it holds while the pointer rests on another cell",
            "stepped from cell " .. tostring(S.from) .. " to " .. tostring(S.expect) .. ", the pointer resting on cell " .. S.P .. "; after "
            .. byGame .. " of the game's updates the selection is on cell " .. tostring(m._ctx.selected) .. ". Old code: back on cell " .. S.P)
    end)
end
leg("the Right arrow key", function(m) m:onKeyPress(Keyboard.KEY_RIGHT) end)
leg("the mouse wheel", function(m) m:onMouseWheel(1) end)
leg("the D-pad", function(m) m:onJoypadDirRight() end)
-- the pointer moves to our own first cell (the selection follows), rests there; a D-pad step off it, then A
Q.step(1, function()
    if not S.w14 then return end
    local m = S.m
    local j = H.idx(m, MINE .. "1")
    local z = j and H.zone(m, "ctxcell_" .. j)
    if not (z and m._ctx.open) then S.w14 = false; Q.check(false, "W14 staged: the script's own cell is on the strip"); return end
    S.P = j
    local _, _, sx, sy = H.mid(m, z)
    H.mouseOn(sx - 3, sy)   -- (3 px off the middle: the pointer moves even when our first cell is cell 2, where it rests)
    S.u0, S.t = S.upd, H.now()
end)
Q.waitFor(1, 900, function() return not S.w14 or S.upd >= S.u0 + 2 or H.now() - S.t > 1500 end, function()
    if not S.w14 then return end
    local m = S.m
    if not m._joyfocus then
        Q.check(m._ctx.selected == S.P, "W14: after the steps, a pointer that moves again takes the selection again",
            "selected cell " .. tostring(m._ctx.selected) .. ", the pointer now on cell " .. S.P)
    end
end)
Q.step(1, function()
    if not S.w14 then return end
    local m = S.m
    if not m._ctx.open then S.w14 = false; Q.check(false, "W14 staged: the strip is still open before the pad's A"); return end
    -- (under a controller the pointer never takes the selection: the D-pad brings it onto our first cell, under the
    -- resting pointer, in this one step)
    for _ = 1, #m._ctx.items do
        if m._ctx.selected == S.P then break end
        m:onJoypadDirRight()
    end
    -- (our three cells stand together: one step right or left of our first is another of ours)
    m:onJoypadDirRight()
    if m._ctx.selected == S.P or not H.mine(H.nameAt(m, m._ctx.selected)) then m:onJoypadDirLeft(); m:onJoypadDirLeft() end
    if m._ctx.selected == S.P then m:onJoypadDirRight() end
    S.expect = m._ctx.selected
    S.u0, S.t = S.upd, H.now()
end)
Q.waitFor(1, 900, function() return not S.w14 or S.upd >= S.u0 + 2 or H.now() - S.t > 1500 end, function()
    if not S.w14 then return end
    local m = S.m
    local d = m._ctx.items[S.expect]
    if not (d and H.mine(d.name) and H.leaf(m, d) and S.expect ~= S.P) then
        Q.skip("W14: A runs the action stepped to", "the cell beside the script's own is not one of its own (cell " .. tostring(S.expect) .. " '" .. H.nameAt(m, S.expect) .. "')")
        H.closeMenu()
        return
    end
    S.fired = {}
    local ok, e = pcall(m.onJoypadDown, m, Joypad.AButton)
    Q.check(ok and S.fired[1] == d.name and #S.fired == 1, "W14: the pad's A runs the action stepped to, not the one under the resting pointer",
        "stepped to cell " .. S.expect .. " '" .. tostring(d.name) .. "', the pointer on cell " .. S.P .. " '" .. H.nameAt(m, S.P) .. "', ran "
        .. tostring(S.fired[1]) .. ". Old code: the pointer's cell ran")
    H.closeMenu()
end)

-- ===================================================================== W15: a strip of 11+ opens on its place
function H.trackWords(tr, n)
    local out = {}
    for i = 1, math.min(#tr, n) do out[#out + 1] = tostring(tr[i].o) end
    return table.concat(out, " ")
end
function H.movedIn(tr, n)
    local c = 0
    for i = 1, math.min(#tr, n) do if H.off(tr[i]) then c = c + 1 end end
    return c
end
Q.step(3, function()
    S.w15 = false
    local it = S.short or S.cands[1]
    if not it then Q.check(false, "W15 staged: a thing to right-click was given"); return end
    H.open(it, 12, true, 1)
    S.tr = {}
    S.w15 = true
end)
-- (looked at every frame: the first frame the strip has drawn is the one that matters)
Q.waitFor(1, 400, function()
    if not S.w15 then return true end
    local m = H.menu()
    if m and not S.m then
        S.m = m
        H.stub(m)
        if m._ctx and m._ctx.firstVisible then S.tr[#S.tr + 1] = H.sample(m) end   -- (it has drawn once already: that frame)
        H.watch(m)
    end
    if S.m then return #S.tr >= 12 end
    return H.opened() and H.menu() == nil
end, function()
    if not S.w15 then return end
    local m = S.m
    local n = m and #(m._ctx.items or {}) or 0
    if not (m and m.Type == "ZeD_ContextMenu" and m._ctx.truncating and #S.tr >= 1) then
        Q.check(false, "W15 staged: an item's menu opened as an icon strip of 11 or more actions",
            tostring(m and m.Type) .. ", " .. n .. " actions, " .. #S.tr .. " frames seen" .. (S.openErr and (", " .. S.openErr) or ""))
        S.w15 = false
        H.closeMenu()
        return
    end
    local s = S.tr[1]
    Q.check(not H.off(s), "W15: a strip of " .. n .. " actions stands on its place on its first drawn frame",
        "track at " .. s.o .. " px, its place " .. s.want .. " px. Old code: near 0, then a slide of about 180 ms")
    local moved = H.movedIn(S.tr, 12)
    Q.check(moved == 0, "W15: the strip does not slide after opening", moved .. " of its first " .. math.min(#S.tr, 12)
        .. " frames off its place (track px: " .. H.trackWords(S.tr, 12) .. ")")
    RT.bounds(Q, "the strip of " .. n .. " actions")
    S.tr = nil
    -- the selection walked to our submenu row
    local j = H.idx(m, MINE .. "nest")
    if not j then Q.check(false, "W15 staged: the script's submenu row is on the strip"); S.w15 = false; H.closeMenu(); return end
    local steps = H.mod(j - m._ctx.selected, n)
    for _ = 1, steps do m:next() end
end)
-- (the walk's own slide and its settle are over and drawn: a snap still pending from the settle would also make the
-- old code's next frame stand on its place, and the hop below would prove nothing)
Q.waitFor(1, 240, function() return not S.w15 or H.settled(S.m) end, function(ok)
    if S.w15 and not ok then Q.say("NOTE W15: the strip had not come to rest after the walk to the submenu row") end
end)
-- into the submenu (13 cells), then back out: each time the strip is on its place on the next drawn frame
local function hop(label, act, depth)
    Q.step(1, function()
        if not S.w15 then return end
        local m = S.m
        if not m._ctx.open then S.w15 = false; Q.check(false, "W15 staged: the strip is still open before going " .. label); return end
        S.pre = m._ctx.trackOriginX
        S.tr = {}
        local ok, e = pcall(act, m)
        if not ok then Q.check(false, "W15: going " .. label .. " ran without an error", tostring(e)) end
    end)
    Q.waitFor(1, 240, function() return not S.w15 or #S.tr >= 6 or not S.m._ctx.open end, function()
        if not S.w15 then return end
        local m = S.m
        local tr = S.tr
        S.tr = nil
        if not (m._ctx.open and #m._ctx.path == depth and #tr >= 1) then
            Q.check(false, "W15 staged: the strip went " .. label, "open " .. tostring(m._ctx.open) .. ", depth " .. #m._ctx.path .. ", " .. #tr .. " frames")
            S.w15 = false
            H.closeMenu()
            return
        end
        local s = tr[1]
        if math.abs(S.pre - s.want) <= 1 then
            Q.skip("W15: " .. label .. ", on its place on the first frame", "the track's place did not change (" .. s.want .. " px): nothing to slide")
            return
        end
        local moved = H.movedIn(tr, 6)
        Q.check(not H.off(s) and moved == 0, "W15: " .. label .. " (" .. #m._ctx.items .. " cells), the strip is on its place on the first drawn frame",
            "track at " .. s.o .. " px, its place " .. s.want .. " px, " .. S.pre .. " px before; " .. moved .. " of " .. math.min(#tr, 6)
            .. " frames off (track px: " .. H.trackWords(tr, 6) .. "). Old code: a slide of about 180 ms from " .. S.pre)
    end)
    -- (at rest before the next hop: the old code's slide over, nothing pending)
    Q.waitFor(1, 120, function() return not S.w15 or H.settled(S.m) end, function() end)
end
hop("into a submenu", function(m) m:confirm() end, 1)
hop("back out of the submenu", function(m) m:cancel() end, 0)
-- W13 again on the carousel: a cell in view that is not the selected one
Q.step(1, function()
    if not S.w15 then return end
    local m = S.m
    local c = m._layoutCache or {}
    local n = #m._ctx.items
    local k, z = nil, nil
    for _, zz in ipairs(m._hitZones or {}) do
        local id = zz.id
        if not k and type(id) == "string" and id:sub(1, 8) == "ctxcell_" and zz.x >= (c.stripX or 0) and zz.x + zz.w <= (c.stripX or 0) + (c.stripW or 0) then
            local j = H.mod(tonumber(id:sub(9)) - 1, n) + 1
            local d = m._ctx.items[j]
            if j ~= m._ctx.selected and H.mine(d.name) and H.leaf(m, d) then k, z = j, zz end
        end
    end
    if not k then Q.skip("W13 on the carousel", "no cell of the script's own is in view beside the selected one"); H.closeMenu(); return end
    local sel0 = m._ctx.selected
    local want, was = H.nameAt(m, k), H.nameAt(m, sel0)
    local cx, cy, sx, sy = H.mid(m, z)
    H.mouseOn(sx, sy)
    S.fired = {}
    local ok, e = pcall(m.onMouseUp, m, cx, cy)
    Q.check(ok and S.fired[1] == want and #S.fired == 1, "W13: on a strip of 11+ too, a click runs the cell clicked",
        "clicked '" .. want .. "', ran " .. tostring(S.fired[1]) .. "; the selection was on '" .. was .. "'. Old code: the click took '" .. was
        .. "' (a submenu row here: its submenu opened, nothing ran)")
    H.closeMenu()
end)
Q.step(1, function() H.closeMenu(); S.w15 = false end)

-- ===================================================================== W12: the menu stays open in a moving car
function H.inCar() return S.v ~= nil and S.p:getVehicle() == S.v end
function H.speed(v)
    local s = 0
    pcall(function() s = math.abs(v:getCurrentSpeedKmHour()) end)
    return s
end
-- a push on the car (BaseVehicle.addImpulse: x, up, y), k times the run's push size
function H.push(D, fx, fz, k)
    local ok = pcall(function()
        local a = D.mass * D.mag * k
        S.v:addImpulse(Vector3f.new(fx * a, 0, fz * a), Vector3f.new(0, 0, 0))
    end)
    if D.impOk == nil then D.impOk = ok end
end
function H.toBrake(D, why)
    if D.phase == "brake" then return end
    H.closeMenu()
    D.phase, D.tb = "brake", H.now()
    if why then D.stopWhy = why end
end
function H.driveOpen(D)
    D.res[D.mi] = { asked = H.now() }
    H.open(S.carItem, 0, false, D.mi)
end
function H.driveNext(D)
    H.closeMenu()
    D.mi = D.mi + 1
    if D.mi > 2 then H.toBrake(D) else H.driveOpen(D) end
end
function H.driveMenu(D, sp, now)
    local R = D.res[D.mi]
    local m = R.m
    if not m then
        m = H.menu()
        if m then
            R.m, R.t = m, now
            R.cx, R.cy = S.v:getX(), S.v:getY()
            S.m = m
            H.watch(m)
        elseif now - R.asked > 2000 then
            R.why = "no menu opened in the car" .. (S.openErr and (": " .. S.openErr) or "")
            H.driveNext(D)
        end
        return
    end
    local at = m._openAt
    local d = at and H.dist(S.p:getX(), S.p:getY(), at.x, at.y) or 0
    R.dist, R.ms, R.upd = d, now - R.t, S.upd
    if sp > (R.sp or 0) then R.sp = sp end
    if not m._ctx.open then
        R.closed = true
        H.driveNext(D)
    elseif d >= 3.2 and S.upd >= 2 and now - R.t >= 500 then
        R.open = true
        H.driveNext(D)
    elseif now - R.t > 4500 then
        R.why = string.format("in 4.5 s with the menu up he moved only %.1f squares from where it opened (the car %.1f)", d,
            H.dist(S.v:getX(), S.v:getY(), R.cx or 0, R.cy or 0))
        H.driveNext(D)
    end
end
-- one frame of the run; true when the car is at rest again
function H.drive()
    local D = S.D
    if not (D and H.inCar()) then return true end
    local v = S.v
    local now = H.now()
    local sp = H.speed(v)
    D.frames = D.frames + 1
    if sp > D.max then D.max = sp end
    local x, y = v:getX(), v:getY()
    local dx, dy = x - D.px, y - D.py
    D.px, D.py = x, y
    D.far = H.dist(x, y, D.x0, D.y0)
    if D.phase ~= "brake" then
        if D.far > 45 then H.toBrake(D, "the car ran 45 squares") elseif now - D.t0 > 17000 then H.toBrake(D, "17 s were up") end
    end
    if D.phase == "brake" then
        if sp > 3 then
            local l = math.sqrt(dx * dx + dy * dy)
            if l > 0.0005 then H.push(D, -dx / l, -dy / l, 0.6) end
        end
        return (sp < 2 and now - D.tb > 500) or now - D.tb > 6000
    end
    -- the push starts small and doubles every 6 frames while the car does not answer, and again while it gains less
    -- than half a km/h in 6 frames short of 15 km/h (a car that holds back); capped at 64; then it only holds about
    -- 25 km/h. (BaseVehicle.addImpulse queues the push; the car's own update applies it as a force,
    -- Bullet.applyCentralForceToVehicle, so the size is mass times about m/s2)
    if D.phase == "accel" and D.frames > 8 and D.mag < 64 and D.frames - D.grewAt >= 6 then
        if D.max < 4 or (sp < 15 and sp - (D.spGrew or 0) < 0.5) then D.mag = math.min(64, D.mag * 2) end
        D.grewAt, D.spGrew = D.frames, sp
    end
    if sp < 22 then H.push(D, D.fx, D.fz, 1) elseif sp > 34 then H.push(D, -D.fx, -D.fz, 0.5) end
    if D.phase == "accel" then
        if sp >= 15 then
            D.phase, D.mi = "menu", 1
            H.driveOpen(D)
        elseif now - D.t0 > 7000 then
            D.noMove = string.format("top speed %.1f km/h after 7 s of pushes (addImpulse usable: %s, push %.1f)", D.max, tostring(D.impOk), D.mag)
            H.toBrake(D)
        end
    else
        H.driveMenu(D, sp, now)
    end
    return false
end

Q.step(3, function()
    S.car = { t0 = H.now() }
    S.carItem = S.short or S.cands[1]
    if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY) then
        S.car.why = "the prelude's car helpers are not loaded (zedqa_prelude.lua runs first)"
        return
    end
    if not S.carItem then S.car.why = "no thing to right-click was given"; return end
    S.p:setGodMod(true)
    S.p:setInvincible(true)
    ZEDQA_CAR_WAIT("Base.CarNormal", "vx_inp", function(v)
        -- (a car ready after the wait was given up, or after the put-back began: nobody gets in, it goes)
        if S.car.gaveUp then pcall(ZEDQA_CAR_AWAY, v); return end
        S.v = v
        S.key = ZEDQA_CAR_PREP(v)
        local ok, why = ZEDQA_CAR_ENTER(v, 0)
        if not ok then S.car.why = why end
        S.car.ready = true
    end, function(why) S.car.why = why or "no ready car" end, 6000)
end)
-- (the helper tries up to 13 spots of 6 s each: waited on the clock, not on frames)
Q.waitFor(5, 20000, function() return S.car == nil or S.car.ready or S.car.why ~= nil or H.now() - (S.car.t0 or 0) > 90000 end, function()
    if not (S.car.ready or S.car.why) then S.car.gaveUp, S.car.why = true, "no ready car in 90 s" end
    Q.check(H.inCar(), "W12 staged: a car spawned on the drag strip, the character in the driver's seat", tostring(S.car.why or ""))
    if not H.inCar() then return end
    local v = S.v
    local D = { t0 = H.now(), frames = 0, grewAt = 0, max = 0, mag = 0.1, mass = 0, phase = "accel", res = {}, fx = 0, fz = -1,
                x0 = v:getX(), y0 = v:getY(), px = v:getX(), py = v:getY(), far = 0 }
    pcall(function() D.mass = v:getMass() end)
    if not D.mass or D.mass <= 0 then D.mass = 1000 end
    -- (the way the car faces, when the game gives it flat and whole; else north, the way the prelude spawns it)
    pcall(function()
        local f = v:getForwardVector(Vector3f.new())
        local x, y, z = f:x(), f:y(), f:z()
        local l = math.sqrt(x * x + z * z)
        if math.abs(y) < 0.3 and l > 0.7 then D.fx, D.fz = x / l, z / l end
    end)
    pcall(function() v:setPhysicsActive(true) end)
    if Vector3f == nil then
        D.noMove = "Vector3f is not open to Lua: the car cannot be pushed"
        D.phase, D.tb = "brake", H.now()
    end
    S.D = D
end)
Q.waitFor(1, 20000, function()
    if not S.D then return true end
    local ok, done = pcall(H.drive)
    if not ok then
        S.D.err = tostring(done)
        return true
    end
    return done
end, function()
    local D = S.D
    if not D then return end
    H.closeMenu()
    if D.err then Q.say("NOTE the run threw: " .. D.err) end
    Q.say(string.format("NOTE the run: top speed %.0f km/h, %.1f squares from the start, push %.1f, addImpulse usable %s%s%s", D.max, D.far, D.mag,
        tostring(D.impOk), D.stopWhy and (", stopped because " .. D.stopWhy) or "", D.noMove and (", " .. D.noMove) or ""))
    local names = { "the icon strip", "the list" }
    for i = 1, 2 do
        local R = D.res[i]
        if R and (R.open or R.closed) then
            Q.check(R.open == true, "W12: " .. names[i] .. " stays open on an item's right-click in a moving car",
                string.format("%s after %.1f squares in %d ms, up to %.0f km/h, %d of the menu's updates. Old code: shut past 2 squares, in a quarter second at this speed",
                    R.open and "still open" or "it shut by itself", R.dist or 0, R.ms or 0, R.sp or 0, R.upd or 0))
        else
            S.need[i] = (R and R.why) or D.noMove or D.err or D.stopWhy or "the run ended before this menu's turn"
        end
    end
end)
-- the car would not move for a menu: the menu's opening place is moved 5 squares instead (the seated character is
-- then 5 squares from where the menu opened, as a moving car leaves him), and the game's updates run on it
for i = 1, 2 do
    local label = (i == 1) and "the icon strip" or "the list"
    Q.step(2, function()
        if not (S.need[i] and H.inCar()) then return end
        Q.skip("W12: " .. label .. " in a car that really moves", tostring(S.need[i]))
        H.open(S.carItem, 0, false, i)
        S.fb = i
    end)
    Q.waitFor(1, 240, function() return S.fb ~= i or H.opened() end, function()
        if S.fb ~= i then return end
        local m = H.menu()
        if not (m and m._openAt) then
            Q.check(false, "W12 staged: " .. label .. " opens on an item's right-click in the parked car", tostring(m and m.Type) .. (S.openErr and (", " .. S.openErr) or ""))
            S.fb = nil
            H.closeMenu()
            return
        end
        S.m = m
        H.watch(m)
        m._openAt.x = m._openAt.x - 5
        S.u0, S.t = S.upd, H.now()
    end)
    Q.waitFor(1, 900, function() return S.fb ~= i or S.upd >= S.u0 + 3 or H.now() - S.t > 1500 end, function()
        if S.fb ~= i then return end
        S.fb = nil
        local m = S.m
        local byGame = S.upd - S.u0
        if byGame < 2 and m._ctx.open then pcall(m.update, m); pcall(m.update, m) end
        Q.check(m._ctx.open == true, "W12: " .. label .. " stays open when the seated character is 5 squares from where it opened (the place moved, not the car)",
            (m._ctx.open and "still open" or "it shut by itself") .. " after " .. byGame .. " of the game's updates. Old code: shut at the first update")
        H.closeMenu()
    end)
end
-- getting out shuts it (the fix's other half: only getting in, out or changing car closes the menu)
Q.step(3, function()
    S.ex = false
    if not H.inCar() then return end
    H.open(S.carItem, 0, false, 1)
    S.ex = true
end)
Q.waitFor(1, 240, function() return not S.ex or H.opened() end, function()
    if not S.ex then return end
    local m = H.menu()
    if not m then S.ex = false; Q.check(false, "W12 staged: the strip opens in the parked car before getting out", tostring(S.openErr or "")); return end
    S.m = m
    H.watch(m)
    pcall(function() S.v:exit(S.p); triggerEvent("OnExitVehicle", S.p) end)
    S.t = H.now()
end)
Q.waitFor(1, 900, function() return not S.ex or not S.m._ctx.open or H.now() - S.t > 2000 end, function()
    if not S.ex then return end
    -- (BaseVehicle.exit leaves him where he sat; the old code shut the menu only past 2 squares, so the distance says
    -- whether this line tells the two apart)
    local at = S.m._openAt
    local d = -1
    pcall(function() if at then d = H.dist(S.p:getX(), S.p:getY(), at.x, at.y) end end)
    local old = (d >= 0 and d <= 2) and "old code: it stayed open, he is within 2 squares of where it opened"
        or "old code: shut too, he is 2 squares or more from where it opened"
    Q.check(S.p:getVehicle() == nil and S.m._ctx.open == false, "W12: getting out of the car shuts the menu that opened in it",
        "out of the car " .. tostring(S.p:getVehicle() == nil) .. ", menu open " .. tostring(S.m._ctx.open) .. " after " .. (H.now() - S.t)
        .. " ms, " .. string.format("%.1f", d) .. " squares from where it opened (" .. old .. ")")
    H.closeMenu()
end)

-- ===================================================================== the put-back
Q.mark()
Q.step(2, function()
    pcall(H.closeMenu)
    pcall(H.kbAway)
    pcall(H.kmAway)
    pcall(H.btnUnwrap)
    pcall(H.unwatch)
    pcall(H.mouseOff)
    if S.fillOn then pcall(function() Events.OnFillInventoryObjectContextMenu.Remove(H.fill) end); S.fillOn = false end
    S.extras, S.nest = 0, false
    local o = H.opt()
    if o and S.styleWas ~= nil then pcall(function() o:setValue(S.styleWas) end) end
    pcall(function() S.p:setGodMod(true) end)
    pcall(function() S.p:setInvincible(true) end)
    S.D = nil
    if S.car then S.car.gaveUp = true end   -- (a car still on its way is sent away, not sat in)
    if S.v and ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, S.v, S.key) end
    S.carGone = S.v ~= nil
    S.v, S.key = nil, nil
end)
Q.waitFor(10, 600, function() return S.p:getVehicle() == nil end, function()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "vx_inp") end
    -- (and onto the very square the run began on)
    pcall(function()
        local p, h = S.p, S.home
        if h and H.dist(p:getX(), p:getY(), h.x, h.y) > 0.6 then p:setX(h.x); p:setY(h.y); p:setLastX(h.x); p:setLastY(h.y) end
    end)
    pcall(function() S.p:setBlockMovement(false) end)
    pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
end)
Q.step(20, function()
    local p = S.p
    pcall(function() p:getBodyDamage():RestoreToFullHealth() end)
    RT.takeBack()
    local hp = -1
    pcall(function() hp = p:getBodyDamage():getOverallBodyHealth() end)
    Q.check(not p:isDead() and hp >= 99, "put back: the character is alive and whole", string.format("health %.0f", hp))
    Q.check(p:getVehicle() == nil and (not S.home or H.dist(p:getX(), p:getY(), S.home.x, S.home.y) < 1.5), "put back: the character is out of the car, on the drag strip where the run began",
        H.fl(p:getX()) .. "," .. H.fl(p:getY()))
    local o = H.opt()
    local style = nil
    if o then pcall(function() style = o:getValue() end) end
    Q.check(style == S.styleWas, "put back: the Context menu setting is as it was", tostring(style))
    local n = p:getInventory():getItems():size()
    Q.check(n == S.inv0, "put back: the bag holds as many things as before", n .. " now, " .. tostring(S.inv0) .. " before")
    Q.check(H.menu() == nil and not S.mouseSwapped and S.btnOrig == nil and not ZeD.Keyboard.isVisible(),
        "put back: no menu or keyboard is left up, the pointer and ZeD's button drawer are their own again")
    pcall(function() p:setInvincible(S.invWas and true or false) end)
    pcall(function() if S.godWas == false then p:setGodMod(false) end end)
    Q.say("NOTE end: god mode " .. tostring(p:isGodMod()) .. " (was " .. tostring(S.godWas) .. "), invincible " .. tostring(p:isInvincible())
        .. " (was " .. tostring(S.invWas) .. ")" .. (S.carGone and ", the car taken away" or ""))
    RT.bounds(Q, "the end")
end)
Q.start()
