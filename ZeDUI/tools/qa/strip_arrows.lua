-- ZeDUI/tools/qa/strip_arrows.lua  (Nov 25 2026, QA; tag strip_arrows): the strips' bottom [^ v] scroll rows, in the
-- running game on the QA save. The director: "the scroll buttons on the container strip are not on center", then
-- "Maybe there should be a line dividing up and down as well", and asked whether the window tab strips scroll.
-- Build's fix (fix/striparrows): ZeD.Atoms.stripArrowHalves(w, lineL, lineR) returns L, M, M2, R (the up half
-- [L, M), the line [M, M2), the down half [M2, R)), stripArrowX centres an arrow in its half, stripArrowLine draws
-- the line between. Four strips use them: the Character window's container strip and tab strip, the World window's
-- container strip and tab strip.
-- Run after zedqa_prelude.lua and rt_kit.lua (strip_arrows.txt). grep "ZEDQA strip_arrows".
--
-- How it reads a row: while the script runs, ZeD.Atoms.stripArrowHalves, stripArrowLine, stripArrowX,
-- drawTriangleUp and drawTriangleDown are wrapped (put back at the end). Each strip calls Halves, then Line on its
-- own panel, then X and the two triangles, so one record per panel holds the w passed in, the L, M, M2, R returned,
-- the line's coordinates and both arrows as drawn. Halves is called only when the strip's list overflows
-- (needsScroll), so a fresh record says the row shows.
-- Staging:
--   * the container strips: key rings given to him (the Character window's strip lists the bags he wears and every
--     key ring he carries; a bag carried but not worn is not listed), crates (carpentry_01_16, lv_move's) on the
--     free squares round him on the drag strip for the World window's; a strip that still does not scroll has its
--     window made as short as it goes
--   * the tab strips: the window made as short as it goes (its minimumHeight)
--   * each strip's scroll offset set half way (so both arrows are live and both hit zones exist), put back after
-- At each strip, in Dark and in High contrast:
--   * CHECK the row shows (needsScroll: Halves was called for this panel in the last frames)
--   * CHECK the up and down hit zones meet at the divider and cover the row: up [0, M), down [M2, w), the line
--     [M, M2) one hairline, both on the row's y and height
--   * CHECK stripArrowX puts each arrow's box centre within 1 px of its half's centre (the triangles as drawn)
--   * CHECK the divider line is drawn (stripArrowLine called on the panel with M, M2 as Halves gave them, from the
--     row's top to the panel's bottom)
--   * a picture Zomboid/Screenshots/strip_<cw|ww>_<containers|tabs>_<dark|hicon>_<w>x<h>.png and a STRIP line:
--       ZEDQA strip_arrows STRIP pic=<picture> strip=<cw_containers|cw_tabs|ww_containers|ww_tabs> theme=<t>
--         ax=<abs x> ay=<abs y> w=<w> pw=<panel w> ph=<panel h> rowY=<row y> rowH=<row h> L= M= M2= R= lineL=0|1
--         lineR=0|1 hl=<hairline> upX= dnX= aS=<arrow size> arY= upZ=<x>+<w> dnZ=<x>+<w> off=<offset> max=<max>
--         short=0|1 line=<rrggbb> screen=<w>x<h>
--     (ax, ay: the strip panel's place on the screen in pixels; the row is x ax..ax+w-1, y ay+rowY..ay+rowY+rowH-1;
--     L, M, M2, R and the rest are panel-local; strip_measure.py measures the picture from it)
-- Puts back: the theme, both windows' heights (and the layout), the key rings, the crates, both windows' tabs, every
-- strip's scroll offset (_stripScrollOffset, _tabScrollOffset, _actionTabScrollOffset), him where he stood, the
-- pointer and the wrapped atoms.
if not RT then print("ZEDQA strip_arrows ERR rt_kit.lua did not run first"); print("ZEDQA strip_arrows DONE"); return end
local Q = RT.make("strip_arrows")
Q.maxMs = 780000                     -- (the runner gives this script 900 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, crates = {}, shots = {}, frame = 0, errs = 0,
            shrinks = {}, stripN = 0 }

-- ===================================================================== constants
S.TAG = "strip_arrows"
S.RING = "Base.KeyRing"
S.RINGS = 16
S.CRATE = "carpentry_01_16"
S.THEMES = { "dark", "hicon" }
S.WRAP = { "stripArrowHalves", "stripArrowLine", "stripArrowX", "drawTriangleUp", "drawTriangleDown" }
S.HEX = "0123456789abcdef"
-- the four strips: the window, the panel's field, the scroll offset's field, the hit zones' ids, the lines the code
-- asks Halves for (lineL, lineR)
S.STRIPS = {
    { id = "cw_containers", win = "cw", kind = "containers", panel = "_containerStrip", off = "_stripScrollOffset",
      up = "strip_scroll_up", dn = "strip_scroll_down", label = "the Character window's container strip" },
    { id = "ww_containers", win = "ww", kind = "containers", panel = "_containerStrip", off = "_stripScrollOffset",
      up = "scroll_up", dn = "scroll_down", label = "the World window's container strip" },
    { id = "cw_tabs", win = "cw", kind = "tabs", panel = "_tabStripPanel", off = "_tabScrollOffset",
      up = "tab_scroll_up", dn = "tab_scroll_down", label = "the Character window's tab strip" },
    { id = "ww_tabs", win = "ww", kind = "tabs", panel = "_actionTabStrip", off = "_actionTabScrollOffset",
      up = "tab_scroll_up", dn = "tab_scroll_down", label = "the World window's tab strip" },
}
-- every offset put back (the World window keeps its tab strip's in _actionTabScrollOffset)
S.OFFS = { { "cw", "_stripScrollOffset" }, { "cw", "_tabScrollOffset" }, { "ww", "_stripScrollOffset" },
           { "ww", "_actionTabScrollOffset" }, { "ww", "_tabScrollOffset" } }

-- ===================================================================== small helpers (sb_edges')
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.note(s) Q.say("NOTE " .. tostring(s)) end
function S.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function S.wait(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end
function S.waitIdle(n) Q.step(n, function() end) end
function S.i(v) local x = tonumber(v); if x == nil then return "?" end; return tostring(math.floor(x + 0.5)) end
function S.n(v) local x = tonumber(v); if x == nil then return 0 end; return math.floor(x + 0.5) end
function S.f1(v) return string.format("%.1f", tonumber(v) or 0) end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function S.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function S.known(ft)
    local ok = false
    if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end
    return ok
end
function S.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function S.hex2(v)
    local n = math.floor((tonumber(v) or 0) * 255 + 0.5)
    if n < 0 then n = 0 elseif n > 255 then n = 255 end
    local hi = math.floor(n / 16)
    local lo = n - hi * 16
    return string.sub(S.HEX, hi + 1, hi + 1) .. string.sub(S.HEX, lo + 1, lo + 1)
end
function S.hexC(c)
    if type(c) ~= "table" then return "none" end
    return S.hex2(c.r) .. S.hex2(c.g) .. S.hex2(c.b)
end
function S.isItem(it) return it ~= nil and instanceof(it, "InventoryItem") end
function S.win(key) if key == "cw" then return RT.cw() end; return RT.ww() end

-- ===================================================================== things (sb_edges' and lv_move's)
function S.removeItem(it)
    if not S.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    local c = it:getContainer()
    if c then pcall(function() c:Remove(it) end) end
end
-- key rings carried: each one a button on the Character window's container strip
function S.giveRings()
    if not S.known(S.RING) then return 0, S.RING .. " is not an item this game knows" end
    local n = 0
    for k = 1, S.RINGS do
        local it = RT.give(S.RING)
        if S.isItem(it) then
            S.made[#S.made + 1] = it
            n = n + 1
        end
    end
    local cw = RT.cw()
    if cw then cw._containerTimer = 30 end
    return n
end
-- the free squares round him (lv_move's)
function S.freeSquares()
    local x, y, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    local free = {}
    for _, d in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x + d[1], y + d[2], z)
        local ok = sq ~= nil
        if sq then pcall(function() ok = sq:isFree(false) end) end
        if ok then free[#free + 1] = sq end
    end
    return free
end
-- a crate (lv_move's mkCrate): a plain IsoObject with the crate sprite's container
function S.mkCrate(sq)
    local c = nil
    pcall(function()
        local o = IsoObject.new(getCell(), sq, S.CRATE)
        o:createContainersFromSpriteProperties()
        sq:AddTileObject(o)
        local inv = o:getContainer()
        c = { obj = o, sq = sq }
        if inv then pcall(function() inv:setExplored(true) end) end
    end)
    if c then S.crates[#S.crates + 1] = c end
    return c
end
function S.layCrates()
    local free = S.freeSquares()
    local n = 0
    for _, sq in ipairs(free) do if S.mkCrate(sq) then n = n + 1 end end
    local ww = RT.ww()
    if ww then ww._containerTimer = 30 end
    return n, #free
end
function S.rmCrate(c)
    if not (c and c.obj) then return end
    pcall(function()
        local sq = c.obj:getSquare() or c.sq
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(c.obj) end); sq:RemoveTileObject(c.obj) end
    end)
end
function S.crateLeft(c)
    if not (c and c.obj) then return false end
    local left = false
    pcall(function() local objs = c.sq:getObjects(); left = objs:contains(c.obj) end)
    return left
end

-- ===================================================================== the pointer and pictures (sb_edges')
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
-- a picture, then after(name) (the STRIP line for it)
function S.shot(name, what, gate, after)
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
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then
            S.shots[#S.shots + 1] = file
            Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. tostring(what))
            if after then pcall(after, tostring(nm)) end
        else Q.say("NOTE the picture " .. tostring(nm) .. " was not taken: " .. tostring(e)) end
        if st.mine then S.park(false) end
    end)
    Q.waitMs(1500)
end

-- ===================================================================== the theme (sb_edges')
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

-- ===================================================================== the windows' heights (sb_edges' shrink)
function S.geo(win)
    if not win then return "none" end
    return S.i(win:getX()) .. "," .. S.i(win:getY()) .. "," .. S.i(win:getWidth()) .. "," .. S.i(win:getHeight())
end
-- the window as short as it goes (its minimumHeight); put back by S.shrinkBack
function S.shrinkMin(win)
    if not win then return false end
    local h = win:getHeight()
    local minH = win.minimumHeight or ZeD.T.px(220)
    if minH >= h then return false end
    S.shrinks[#S.shrinks + 1] = { win = win, h = h }
    S.layoutTouched = true
    win:setHeight(minH)
    return true
end
function S.shrinkBack()
    for i = #S.shrinks, 1, -1 do
        local s = S.shrinks[i]
        pcall(function() s.win:setHeight(s.h) end)
    end
    S.shrinks = {}
end
function S.offsBack()
    local f = S.found.offs
    if not f then return end
    for _, o in ipairs(S.OFFS) do
        local w = S.win(o[1])
        if w then w[o[2]] = f[o[1] .. o[2]] end
    end
end

-- ===================================================================== the atoms as drawn
function S.count() S.frame = S.frame + 1 end
function S.spyOn()
    if S.spy then return true end
    local A = ZeD and ZeD.Atoms
    if type(A) ~= "table" then return false, "ZeD.Atoms is not loaded" end
    for _, k in ipairs(S.WRAP) do
        if type(rawget(A, k)) ~= "function" then return false, "ZeD.Atoms." .. k .. " is missing (the fix is not in this build)" end
    end
    local sp = { own = {}, cur = nil, byPanel = {}, lines = 0 }
    for _, k in ipairs(S.WRAP) do sp.own[k] = rawget(A, k) end
    A.stripArrowHalves = function(w, lineL, lineR)
        local L, M, M2, R = sp.own.stripArrowHalves(w, lineL, lineR)
        sp.cur = { frame = S.frame, w = w, lineL = lineL, lineR = lineR, L = L, M = M, M2 = M2, R = R, xs = {}, tris = {} }
        return L, M, M2, R
    end
    A.stripArrowLine = function(panel, M, M2, y, y2)
        local c = sp.cur
        sp.lines = sp.lines + 1
        if c and c.frame == S.frame and c.panel == nil then
            c.panel = panel
            c.line = { M = M, M2 = M2, y = y, y2 = y2 }
            sp.byPanel[panel] = c
        end
        return sp.own.stripArrowLine(panel, M, M2, y, y2)
    end
    A.stripArrowX = function(a, b, s)
        local x = sp.own.stripArrowX(a, b, s)
        local c = sp.cur
        if c and c.frame == S.frame and #c.xs < 4 then c.xs[#c.xs + 1] = { a = a, b = b, s = s, x = x } end
        return x
    end
    A.drawTriangleUp = function(panel, x, y, size, color)
        local c = sp.cur
        if c and c.panel == panel and c.frame == S.frame and c.up == nil then c.up = { x = x, y = y, s = size } end
        return sp.own.drawTriangleUp(panel, x, y, size, color)
    end
    A.drawTriangleDown = function(panel, x, y, size, color)
        local c = sp.cur
        if c and c.panel == panel and c.frame == S.frame and c.dn == nil then c.dn = { x = x, y = y, s = size } end
        return sp.own.drawTriangleDown(panel, x, y, size, color)
    end
    S.spy = sp
    return true
end
function S.spyOff()
    local sp = S.spy
    if not sp then return end
    S.spy = nil
    local A = ZeD and ZeD.Atoms
    if type(A) ~= "table" then return end
    for _, k in ipairs(S.WRAP) do A[k] = sp.own[k] end
end
function S.spyIsOff()
    local A = ZeD and ZeD.Atoms
    if not (S.own0 and type(A) == "table") then return true end
    for _, k in ipairs(S.WRAP) do if rawget(A, k) ~= S.own0[k] then return false end end
    return true
end

-- ===================================================================== one strip, read
function S.panelOf(st) local w = S.win(st.win); return w and w[st.panel] or nil end
-- the panel's fresh record (Halves called for it in the last few frames: the row shows)
function S.recOf(st)
    local p = S.panelOf(st)
    local sp = S.spy
    if not (p and sp) then return nil, p end
    local r = sp.byPanel[p]
    if r and r.frame >= S.frame - 3 then return r, p end
    return nil, p
end
function S.zone(p, id)
    for _, z in ipairs((p and p._hitZones) or {}) do if z.id == id then return z end end
    return nil
end
function S.lab(st, theme) return st.label .. " (" .. tostring(theme) .. ")" end
function S.picName(st, theme) return "strip_" .. st.id .. "_" .. tostring(theme) .. "_" .. S.sizeTag() end
-- the checks, on the record of the last frame
function S.checks(T, st, theme)
    local r, p = T.rec, T.p
    local lab = S.lab(st, theme)
    local hl = ZeD.T.px(1)
    local w = tonumber(r.w) or 0
    local L, M, M2, R = r.L, r.M, r.M2, r.R
    local ln = r.line
    local rowY, rowH = ln.y, ln.y2 - ln.y
    local ph = p:getHeight()
    T.hl, T.rowY, T.rowH, T.ph, T.pw = hl, rowY, rowH, ph, p:getWidth()
    -- hit zones
    local up, dn = S.zone(p, st.up), S.zone(p, st.dn)
    T.upZ, T.dnZ = up, dn
    local zt = "up " .. (up and (S.i(up.x) .. "+" .. S.i(up.w) .. " y " .. S.i(up.y) .. "+" .. S.i(up.h)) or "none")
        .. ", down " .. (dn and (S.i(dn.x) .. "+" .. S.i(dn.w) .. " y " .. S.i(dn.y) .. "+" .. S.i(dn.h)) or "none")
        .. "; L " .. S.i(L) .. " M " .. S.i(M) .. " M2 " .. S.i(M2) .. " R " .. S.i(R) .. " w " .. S.i(w) .. " (panel " .. S.i(T.pw)
        .. "), row y " .. S.i(rowY) .. "+" .. S.i(rowH) .. ", offset " .. S.i(T.offNow) .. " of " .. S.i(T.max)
    local zok = up ~= nil and dn ~= nil
    if zok then
        zok = up.x == 0 and up.x + up.w == M and dn.x == M2 and dn.x + dn.w == w and M2 - M == hl
            and up.y == rowY and dn.y == rowY and up.h == rowH and dn.h == rowH and rowY + rowH == ph
    end
    Q.check(zok, lab .. ": the up and down hit zones meet at the divider and cover the row (up [0, M), the line [M, M2) one hairline, down [M2, w))", zt)
    -- the arrows: each box's centre on its half's centre
    local u, d = r.up, r.dn
    local cu, cd = (L + M) / 2, (M2 + R) / 2
    local au = u and (u.x + u.s / 2) or nil
    local ad = d and (d.x + d.s / 2) or nil
    local xs = {}
    for _, x in ipairs(r.xs or {}) do xs[#xs + 1] = "X(" .. S.i(x.a) .. "," .. S.i(x.b) .. "," .. S.i(x.s) .. ")=" .. S.i(x.x) end
    local at = "up box " .. (u and (S.i(u.x) .. "+" .. S.i(u.s) .. " centre " .. S.f1(au)) or "not drawn") .. " vs its half's " .. S.f1(cu)
        .. "; down box " .. (d and (S.i(d.x) .. "+" .. S.i(d.s) .. " centre " .. S.f1(ad)) or "not drawn") .. " vs " .. S.f1(cd)
        .. "; halves " .. S.i(M - L) .. " and " .. S.i(R - M2) .. " px; " .. table.concat(xs, " ")
    local aok = au ~= nil and ad ~= nil and math.abs(au - cu) <= 1 and math.abs(ad - cd) <= 1
    if aok and #xs >= 2 then aok = r.xs[1].x == u.x and r.xs[2].x == d.x end
    Q.check(aok, lab .. ": stripArrowX puts each arrow's box centre within 1 px of its half's centre", at)
    if math.abs((M - L) - (R - M2)) > 1 then S.note(lab .. ": the halves differ by more than a pixel (" .. S.i(M - L) .. " and " .. S.i(R - M2) .. ")") end
    local wantL = (r.lineL == false) and 0 or hl
    local wantR = (r.lineR == false) and w or (w - hl)
    if L ~= wantL or R ~= wantR then S.note(lab .. ": L/R " .. S.i(L) .. "/" .. S.i(R) .. " are not what lineL/lineR ask (" .. S.i(wantL) .. "/" .. S.i(wantR) .. ")") end
    -- the divider line
    local lok = ln.M == M and ln.M2 == M2 and M2 - M == hl and M > 0 and M2 < w and ln.y >= 0 and ln.y2 > ln.y
        and math.abs(ln.y2 - ph) < 0.5
    Q.check(lok, lab .. ": the divider line is drawn (stripArrowLine on the strip's panel, sane coordinates)",
        "line x " .. S.i(ln.M) .. "-" .. S.i(ln.M2) .. " y " .. S.i(ln.y) .. "-" .. S.i(ln.y2) .. " (panel height " .. S.i(ph)
        .. "), Halves' M/M2 " .. S.i(M) .. "/" .. S.i(M2) .. ", hairline " .. S.i(hl) .. ", Line calls so far " .. S.spy.lines)
end
function S.stripLine(T, st, theme, pic)
    local r, p = T.rec, T.p
    if not (r and p) then return end
    S.stripN = S.stripN + 1
    local u, d = r.up or {}, r.dn or {}
    local ax, ay = p:getAbsoluteX(), p:getAbsoluteY()
    local zs = function(z) return z and (S.i(z.x) .. "+" .. S.i(z.w)) or "none" end
    Q.say("STRIP pic=" .. pic .. " strip=" .. st.id .. " theme=" .. tostring(theme) .. " ax=" .. S.i(ax) .. " ay=" .. S.i(ay)
        .. " w=" .. S.i(r.w) .. " pw=" .. S.i(T.pw) .. " ph=" .. S.i(T.ph) .. " rowY=" .. S.i(T.rowY) .. " rowH=" .. S.i(T.rowH)
        .. " L=" .. S.i(r.L) .. " M=" .. S.i(r.M) .. " M2=" .. S.i(r.M2) .. " R=" .. S.i(r.R)
        .. " lineL=" .. ((r.lineL == false) and 0 or 1) .. " lineR=" .. ((r.lineR == false) and 0 or 1) .. " hl=" .. S.i(T.hl)
        .. " upX=" .. S.i(u.x) .. " dnX=" .. S.i(d.x) .. " aS=" .. S.i(u.s or d.s) .. " arY=" .. S.i(u.y or d.y)
        .. " upZ=" .. zs(T.upZ) .. " dnZ=" .. zs(T.dnZ) .. " off=" .. S.i(T.offNow) .. " max=" .. S.i(T.max)
        .. " short=" .. (T.shrunk and 1 or 0) .. " line=" .. S.hexC(ZeD.T.borderS) .. " screen=" .. S.sizeTag())
end

-- ===================================================================== one strip, staged
function S.settle(T, st)
    S.wait(4, 600, function()
        if T.off then return true end
        local g = S.geo(S.win(st.win))
        T.st = T.st or { last = "", n = 0 }
        if g == T.st.last then T.st.n = T.st.n + 1 else T.st.last, T.st.n = g, 0 end
        return T.st.n >= 6
    end, function(ok)
        if T.off then return end
        if not ok then S.note(st.label .. ": the window did not settle (" .. tostring(T.st and T.st.last) .. ")") end
        T.st = nil
    end)
    S.waitIdle(4)
end
function S.strip(st, theme)
    local T = {}
    local lab = S.lab(st, theme)
    S.step(2, function()
        local w = S.win(st.win)
        if not (w and w[st.panel]) then T.off = true; Q.skip(lab, "the window or its strip panel (" .. st.panel .. ") is not there"); return end
        if st.kind == "containers" then
            w._containerTimer = 30
            if st.win == "cw" then RT.charTab("loot") else RT.worldTab("loot") end
        else
            -- the tab strips: the window as short as it goes
            T.shrunk = S.shrinkMin(w) or nil
            if not T.shrunk then S.note(lab .. ": the window is already as short as it goes (" .. S.geo(w) .. ")") end
        end
    end)
    S.settle(T, st)
    S.waitIdle(20)
    -- a container strip that still does not scroll: its window made as short as it goes
    S.step(1, function()
        if T.off then return end
        local r = S.recOf(st)
        if r or st.kind ~= "containers" then return end
        T.shrunk = S.shrinkMin(S.win(st.win)) or nil
    end)
    S.settle(T, st)
    -- the offset half way (both arrows live, both hit zones there)
    S.step(1, function()
        if T.off then return end
        local r = S.recOf(st)
        if not r then
            local w = S.win(st.win)
            local p = S.panelOf(st)
            T.off = true
            Q.check(false, lab .. ": the [^ v] row shows (needsScroll)", "Halves was not called for this panel lately; window " .. S.geo(w)
                .. " (minimumHeight " .. S.i(w and w.minimumHeight) .. "), the panel " .. S.i(p and p:getWidth()) .. "x" .. S.i(p and p:getHeight())
                .. ", made shorter " .. tostring(T.shrunk == true) .. ((st.id == "cw_containers") and (", " .. tostring(S.ringN) .. " key rings given") or "")
                .. ((st.id == "ww_containers") and (", " .. tostring(S.crateN) .. " crates laid") or ""))
            return
        end
        S.win(st.win)[st.off] = 999999
    end)
    S.waitIdle(4)
    S.step(1, function()
        if T.off then return end
        local w = S.win(st.win)
        T.max = tonumber(w[st.off]) or 0
        w[st.off] = math.floor(T.max / 2)
    end)
    S.waitIdle(8)
    S.step(1, function()
        if T.off then return end
        local r, p = S.recOf(st)
        local w = S.win(st.win)
        T.offNow = w and w[st.off]
        Q.check(r ~= nil and p ~= nil and p:isVisible(), lab .. ": the [^ v] row shows (needsScroll)",
            "window " .. S.geo(w) .. (T.shrunk and " (made as short as it goes)" or "") .. ", offset " .. S.i(T.offNow) .. " of " .. S.i(T.max))
        if not (r and p) then T.off = true; return end
        T.rec, T.p = r, p
        local ok, e = pcall(S.checks, T, st, theme)
        if not ok then S.errs = S.errs + 1; Q.check(false, lab .. ": the checks ran without an error", tostring(e)) end
    end)
    S.shot(function() return S.picName(st, theme) end, lab .. ": its [^ v] row (arrows centred in their halves, the line between)",
        function() return not T.off and T.rec ~= nil end,
        function(pic)
            -- (the record of the frame before the picture)
            local r, p = S.recOf(st)
            if r and p then T.rec, T.p = r, p end
            S.stripLine(T, st, theme, pic)
        end)
    S.step(2, function()
        S.offsBack()
        if #S.shrinks > 0 then S.shrinkBack() end
        T.shrunk = nil
    end)
    S.waitIdle(10)
end

-- ===================================================================== setup and the passes
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.err0 = S.errN()
        f.pair = RT.isOpen()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        if ZEDQA_HOME then pcall(ZEDQA_HOME, S.TAG) end
        f.base, f.baseIdx = ZeD.currentBase, S.optVal(S.zopt("baseTheme"))
        f.inv0 = {}
        pcall(function()
            local items = S.p:getInventory():getItems()
            for i = 0, items:size() - 1 do f.inv0[items:get(i)] = true end
        end)
        if ZEDQA_LAYOUT_SNAP and f.pair then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        S.back.on = true
        RT.pairOpen()
        Events.OnPreUIDraw.Add(S.count)
        S.counting = true
        local spied, why = S.spyOn()
        Q.check(spied, "setup: the strip atoms can be watched (stripArrowHalves, stripArrowLine, stripArrowX, the triangles)", why)
        if not spied then S.dead = true end
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", theme " .. tostring(f.base) .. ", text "
            .. tostring(ZeD.currentSize) .. ", hairline " .. S.i(ZeD.T.px(1)) .. ", screen " .. S.sizeTag())
    end)
    S.wait(10, 300, function()
        local cw, ww = RT.cw(), RT.ww()
        return cw ~= nil and cw._tabStripPanel ~= nil and cw._containerStrip ~= nil and ww ~= nil and ww._actionTabStrip ~= nil
            and ww._containerStrip ~= nil
    end, function(ok)
        local cw, ww = RT.cw(), RT.ww()
        if not Q.check(ok, "setup: the Character and World windows are open, their strips there") then S.dead = true; return end
        local f = S.found
        f.charTab, f.worldTab = cw._activeTab, ww._activeTab
        f.cwH, f.wwH = cw:getHeight(), ww:getHeight()
        f.offs = {}
        for _, o in ipairs(S.OFFS) do
            local w = S.win(o[1])
            f.offs[o[1] .. o[2]] = w and w[o[2]] or nil
        end
        Q.say("found: Character tab " .. tostring(f.charTab) .. ", World tab " .. tostring(f.worldTab) .. ", Character window "
            .. S.geo(cw) .. " (minimumHeight " .. S.i(cw.minimumHeight) .. "), World window " .. S.geo(ww) .. " (minimumHeight "
            .. S.i(ww.minimumHeight) .. "), offsets cw " .. S.i(cw._stripScrollOffset) .. "/" .. S.i(cw._tabScrollOffset) .. " ww "
            .. S.i(ww._stripScrollOffset) .. "/" .. S.i(ww._actionTabScrollOffset))
    end)
    -- more containers: key rings for the Character window, crates round him for the World window
    S.step(2, function()
        local n, why = S.giveRings()
        S.ringN = n
        if n == 0 then S.note("no key ring could be given (" .. tostring(why) .. "): the Character window's container strip scrolls only if its window is made shorter") end
        local c, free = S.layCrates()
        S.crateN = c
        Q.say("staged: " .. n .. " key rings carried (" .. S.RING .. "), " .. c .. " crates laid on " .. free .. " free squares round him")
    end)
    S.waitIdle(40)
end
function S.passStart(theme)
    S.step(2, function() if ZeD.currentBase ~= theme then S.theme(theme) end end)
    S.waitIdle(30)
    S.step(2, function() Q.say("pass " .. tostring(theme) .. ": theme " .. tostring(ZeD.currentBase) .. ", line " .. S.hexC(ZeD.T.borderS)) end)
end
function S.build()
    S.setup()
    for _, theme in ipairs(S.THEMES) do
        S.passStart(theme)
        for _, st in ipairs(S.STRIPS) do S.strip(st, theme) end
    end
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    S.park(false)
    S.shrinkBack()
    S.offsBack()
    S.themeBack()
    for _, it in ipairs(S.made) do S.removeItem(it) end
    for _, c in ipairs(S.crates) do S.rmCrate(c) end
    local cw, ww = RT.cw(), RT.ww()
    if cw then cw._containerTimer = 30 end
    if ww then ww._containerTimer = 30 end
    pcall(function() triggerEvent("OnContainerUpdate") end)
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        S.putBack()
        RT.pairOpen()
    end)
    Q.step(10, function()
        local f = S.found
        if f.pos then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
        if f.dir then pcall(function() S.p:setDir(f.dir) end) end
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, S.TAG) end
    end)
    Q.step(20, function()
        local f = S.found
        if f.charTab then RT.charTab(f.charTab) end
        if f.worldTab then RT.worldTab(f.worldTab) end
        local cw, ww = RT.cw(), RT.ww()
        if cw and f.cwH and cw:getHeight() ~= f.cwH then cw:setHeight(f.cwH) end
        if ww and f.wwH and ww:getHeight() ~= f.wwH then ww:setHeight(f.wwH) end
        S.offsBack()
    end)
    Q.step(10, function()
        S.spyOff()
        if S.counting then Events.OnPreUIDraw.Remove(S.count); S.counting = nil end
        local f = S.found
        if not f.base then Q.skip("put back", "nothing was staged"); return end
        local left = 0
        for _, it in ipairs(S.made) do
            local c = S.isItem(it) and it:getContainer() or nil
            local held = false
            if c then pcall(function() held = c:contains(it) end) end
            if held then left = left + 1 end
        end
        Q.check(left == 0, "put back: every key ring given is gone", left .. " of " .. #S.made .. " left")
        local extra = 0
        pcall(function()
            local items = S.p:getInventory():getItems()
            for i = 0, items:size() - 1 do if not f.inv0[items:get(i)] then extra = extra + 1 end end
        end)
        Q.check(extra == 0, "put back: the inventory holds only what it held", extra .. " more")
        local cl = 0
        for _, c in ipairs(S.crates) do if S.crateLeft(c) then cl = cl + 1 end end
        Q.check(cl == 0, "put back: every crate laid is gone", cl .. " of " .. #S.crates .. " left")
        Q.check(ZeD.currentBase == f.base and S.optVal(S.zopt("baseTheme")) == f.baseIdx, "put back: the theme as found (and its option)",
            tostring(ZeD.currentBase) .. " (found " .. tostring(f.base) .. ")")
        local cw, ww = RT.cw(), RT.ww()
        Q.check(cw ~= nil and ww ~= nil and cw._activeTab == f.charTab and ww._activeTab == f.worldTab and #S.shrinks == 0
            and math.abs(cw:getHeight() - (f.cwH or 0)) < 0.5 and math.abs(ww:getHeight() - (f.wwH or 0)) < 0.5,
            "put back: both windows' tabs and heights",
            "Character " .. tostring(cw and cw._activeTab) .. " " .. S.geo(cw) .. " (found height " .. S.i(f.cwH) .. "), World "
            .. tostring(ww and ww._activeTab) .. " " .. S.geo(ww) .. " (found height " .. S.i(f.wwH) .. ")")
        local offOk, offT = true, {}
        for _, o in ipairs(S.OFFS) do
            local w = S.win(o[1])
            local now, was = w and w[o[2]], f.offs and f.offs[o[1] .. o[2]]
            if now ~= was then offOk = false end
            offT[#offT + 1] = o[1] .. "." .. o[2] .. " " .. tostring(now) .. " (found " .. tostring(was) .. ")"
        end
        Q.check(offOk, "put back: every strip's scroll offset as found", table.concat(offT, ", "))
        Q.check(S.spyIsOff() and S.spy == nil and S.parked == nil, "put back: the strip atoms and the pointer the game's own again")
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6, "put back: he stands where he stood", string.format("%.1f,%.1f off", dx, dy))
        Q.check(S.errs == 0, "put back: nothing staged for this script threw", S.errs .. " caught")
        local e1 = S.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the strip arrow run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the run's Lua error count", "the game's Lua error count cannot be read here") end
        Q.say("pictures: " .. #S.shots .. ", STRIP lines: " .. S.stripN .. " (measure them: strip_measure.py --console console.txt --pics <Screenshots folder> --crops <folder>)")
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
    end)
end

-- ===================================================================== the run
S.own0 = {}
if ZeD and type(ZeD.Atoms) == "table" then for _, k in ipairs(S.WRAP) do S.own0[k] = rawget(ZeD.Atoms, k) end end
if not (ZeD and ZeD.T and ZeD.T.px and ZeD.applyTheme and ZeD.Settings and S.own0.stripArrowHalves) then
    Q.check(false, "ZeD's tokens, theme and the strip atoms (ZeD.Atoms.stripArrowHalves: Build's fix/striparrows) are loaded")
else
    S.build()
end
S.buildPutBack()
Q.start()
