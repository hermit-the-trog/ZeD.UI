-- ZeDUI/tools/qa/dn_footer_head.lua  (Nov 22 2026, QA; tag dn_fh): the director's two notes pictured, before Build's
-- fix and again after it. 4K full screen, mouse and keyboard, on the 1.0 gallery's staging (manifest dn_fh.txt: the
-- story stage, gallery_unload.lua, G1, hfr_common.lua). Pictures to Zomboid/Screenshots/dn_fh_<name>.png.
--   (1) "It's not drawing the border lines in the footer when there is no hint in the footer." Organisms.lua
--       ZeD_Window:_drawHelpLine (1108-1157): a help strip with nothing to say (no help words, no controller prompts,
--       no resize handle lit) is filled and returns before its top hairline (:1140) is drawn.
--   (2) The right-click menu on the ground in Light: its heading (the pointed-at name) may be too light to read.
--       ZeD_ContextList.lua:346-366 draws it in T.textDim on T.surf1. The strip (ZeD_ContextMenu) names nothing it
--       acts on: its one heading is its balloon's title (the lit action's name), drawn in the balloon's own light
--       palette (Balloon.lua:49-72 LIGHT, :602-613 drawWords).
-- Each picture in the Light theme, then again in Dark (ZeD's Base theme option set for the three pictures and put
-- back after them, ZeD.applyTheme with the accent and text size as found):
--   footer_<theme>         both windows open on Loot at their default places (moved off him only if they cover him),
--                          both held "in use" (ZeD_Window.pointerOn held true, as kiss_loot.lua holds a window: the
--                          pointer on them), the pointer the game reads parked off every window (nothing hovered: no
--                          help words), ZeD's input mode locked to the mouse (no controller prompts): the empty help
--                          strip at the foot of each. For one frame each window's _drawHelpLine is wrapped to read what
--                          it decided: footerHeight, says (prompts, help words or a lit resize handle), and whether the
--                          strip's top hairline was drawn (the overlay's drawRect watched during the call)
--   ground_list_<theme>    the windows closed; ZeD's Context menu option set to the list for the picture; a right-click
--                          on a bare square of the open patch beside him, the way the game opens it
--                          (ISWorldObjectContextMenu.createMenu with the square's objects at its point on the screen,
--                          the pointer the game reads there, Overrides/ContextMenu.lua:192-223 anchors at it), then the
--                          pointer parked off the menu; the square picked so the menu stays clear of him. For one frame
--                          the menu panel's drawText and drawRect are wrapped (then put back): the heading's words, the
--                          RGBA it is drawn in, the rectangle under it (the menu's background) and the contrast ratio
--                          (WCAG 2 relative luminance, the heading's alpha composited over the background)
--   ground_strip_<theme>   the same with the Context menu option set to the strip: its balloon's title read the same way
-- Each picture prints "ZEDQA dn_fh SHOT <name> | what is in it" or "ZEDQA dn_fh SKIP <name> | why".
-- What it puts back: the Base theme (option and palette), the Context menu option, the input mode lock, the windows'
-- "in use" test, the pointer the game reads, the wrapped draws, the menus (closed), the zoom, both windows' places,
-- sizes, pins and tabs (ZEDQA_LAYOUT_BACK) and the pair as found; he ends at the stock spot. Not undone: S.notesRead
-- marks unread Messages read before each picture (bxr_inv.lua's practice). grep "ZEDQA dn_fh".
local S = HFR and HFR.init and HFR.init("dn_fh")
if not S then return end
S.DIR = "dn_fh_"
local Q = S.Q
S.pic, S.held = {}, {}
S.Det = ZeD and ZeD.Input and ZeD.Input.Detector
S.THEMES = { { key = "light", word = "Light" }, { key = "dark", word = "Dark" } }

if not (ZeD and ZeD.Settings and ZeD.Settings.contextStyleOption and ZeD.Settings.baseKeys and ZeD.applyTheme and ZeD.T
        and ZeD_Window and ZeD.Help and ZeD.Help.take and ZeD.ContextMenu and ZeD.ContextMenu.Registry
        and ISWorldObjectContextMenu and ISWorldObjectContextMenu.createMenu and S.CWm and S.WWm and S.CWm.toggleBothPaired) then
    Q.say("ERR ZeD's windows, settings, help line or menus are not loaded")
    Q.start()
    return
end

-- ===================================================================== the error watch (kiss_loot.lua's)
S.errN, S.errAt = nil, -100000
function S.errWatch()
    local n = nil
    if getLuaDebuggerErrorCount then n = getLuaDebuggerErrorCount() end
    if n ~= nil and n ~= S.errN then
        if S.errN ~= nil then S.errAt = getTimestampMs() end
        S.errN = n
    end
end
function S.quiet() S.errWatch(); return getTimestampMs() - S.errAt > 3600 end
Events.OnPreUIDraw.Add(S.errWatch)
function Q.still(n, fn)
    local st = { last = nil, same = 0 }
    Q.waitFor(n, 900, function()
        local s = G1.shape()
        if s == st.last then st.same = st.same + 1 else st.last, st.same = s, 0 end
        return st.same >= 30 and S.quiet()
    end, fn)
end

-- ===================================================================== small helpers
function S.skip(name, why) Q.notTaken(name, why); Q.say("SKIP " .. name .. " | " .. tostring(why)) end
function S.fl(v) return math.floor(tonumber(v) or 0) end
function S.scr() return S.core:getScreenWidth(), S.core:getScreenHeight() end
function S.zoom()
    local z = 1
    pcall(function() z = S.core:getZoom(S.pn) end)
    if not z or z <= 0 then z = 1 end
    return z
end
function S.sqAt(x, y) return getCell():getGridSquare(x, y, 0) end
function S.notesRead()
    local M = ZeD.Messages
    if not (M and M.unread and M.markAllRead) then return end
    if M.readErrors then pcall(M.readErrors) end
    local un, err = 0, false
    pcall(function() un, err = M.unread() end)
    if (un or 0) > 0 then pcall(M.markAllRead) end
    local gone = 0
    if M.toasts and M.dropToast then
        for i = #M.toasts, 1, -1 do
            local t = M.toasts[i]
            if t and t.kind == "crit" then pcall(M.dropToast, t); gone = gone + 1 end
        end
    end
    if (un or 0) > 0 or gone > 0 then
        Q.say("note: before the picture " .. tostring(un) .. " unread message(s) marked read (an error among them " .. tostring(err)
            .. "), " .. gone .. " error balloon(s) dismissed")
    end
end
function S.shotOk(name, what, keepMenu)
    S.notesRead()
    if not S.quiet() then
        Q.say("NOTE " .. name .. ": a Lua error came " .. tostring(getTimestampMs() - S.errAt) .. " ms before the picture: the game's red error box may be in it")
    end
    S.shot(name, keepMenu)
    S.pic[#S.pic + 1] = name
    Q.say("SHOT " .. name .. " | " .. tostring(what))
end
-- time, not frames: cond asked every 100 ms, at most ms; fn(true) when cond came true (kiss_loot.lua)
function S.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 400000, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if st.last and now - st.last < 100 then return false end
        st.last = now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- the camera has stopped after a move: his place on screen the same for 20 drawn frames (kiss_loot.lua)
function S.settle(on)
    local st = { same = 0 }
    Q.waitFor(5, 900, function()
        if on and not on() then return true end
        if S.p:getCurrentSquare() == nil then return false end
        local v = math.floor(isoToScreenX(S.pn, S.p:getX(), S.p:getY(), 0)) .. "," .. math.floor(isoToScreenY(S.pn, S.p:getX(), S.p:getY(), 0))
        if v == st.last then st.same = st.same + 1 else st.last, st.same = v, 0 end
        return st.same >= 20
    end, function() end)
end
-- the camera's zoom to get() (nil: left as it is), a quarter step a frame (kiss_loot.lua)
function S.zoomDyn(get)
    local st = {}
    Q.waitFor(2, 1200, function()
        if st.left == nil then
            local z = get()
            st.left = z and math.floor((S.core:getZoom(S.pn) - z) / 0.25 + 0.5) or 0
            st.moved = st.left ~= 0
        end
        if st.left == 0 then return true end
        S.core:doZoomScroll(S.pn, (st.left > 0) and -1 or 1)
        st.left = (st.left > 0) and (st.left - 1) or (st.left + 1)
        return st.left == 0
    end, function() end)
    Q.waitFor(1, 200, function()
        if not st.moved then return true end
        st.n = (st.n or 0) + 1
        return st.n >= 100
    end, function() if st.moved then Q.say("zoom " .. tostring(S.core:getZoom(S.pn))) end end)
end
function S.over(x, y, w, h)
    local r = G1.charRect()
    return x < r.x1 and x + w > r.x0 and y < r.y1 and y + h > r.y0
end
function S.box(x, y, w, h) return S.fl(x) .. "," .. S.fl(y) .. " " .. S.fl(w) .. "x" .. S.fl(h) end

-- ===================================================================== the open patch (kiss_loot.lua's)
function S.goodSq(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree() and sq:isOutside()
            and sq:getRoom() == nil and sq:getObjects():size() <= 3 and sq:getWorldObjects():size() == 0
            and sq:getVehicleContainer() == nil and sq:getMovingObjects():size() == 0
    end)
    return good and sq or nil
end
S.AHEAD = { { 2, 0 }, { 0, 2 }, { 2, 1 }, { 1, 2 }, { 2, 2 }, { 3, 1 }, { 1, 3 }, { 3, 2 }, { 2, 3 }, { 3, 3 } }
function S.clearAhead(x, y)
    for _, o in ipairs(S.AHEAD) do
        local sq = S.sqAt(x + o[1], y + o[2])
        local ok = false
        if sq then
            pcall(function() ok = sq:isOutside() and sq:getRoom() == nil and not sq:HasTree() and sq:getVehicleContainer() == nil end)
        end
        if not ok then return false end
    end
    return true
end
function S.patchAt(x, y, lo, hi)
    for dy = lo, hi do
        for dx = lo, hi do
            if not S.goodSq(S.sqAt(x + dx, y + dy)) then return false end
        end
    end
    return true
end
function S.findPatch(cx, cy)
    for _, r in ipairs({ { -3, 2 }, { -2, 2 } }) do
        local best, bs = nil, 1e9
        for dy = -14, 14 do
            for dx = -14, 14 do
                local sc = math.abs(dx) + math.abs(dy) - (dx + dy) * 0.25
                if sc < bs and S.patchAt(cx + dx, cy + dy, r[1], r[2]) and S.clearAhead(cx + dx, cy + dy) then best, bs = { x = cx + dx, y = cy + dy, lo = r[1] }, sc end
            end
        end
        if best then return best end
    end
    return nil
end
function S.home(dir) if S.c then G1.tp({ S.c.x, S.c.y }, dir or "SE") end end

-- ===================================================================== the pointer the game reads, the menus
-- (Mouse.setXY does not move the pointer the game's Lua reads: getMouseX / getMouseY swapped, kiss_loot.lua)
function S.mouseOn(x, y)
    S.fx, S.fy = x, y
    if S.mouseSwapped then return end
    S.realMX, S.realMY = getMouseX, getMouseY
    S.mouseSwapped = true
    pcall(function()
        getMouseX = function() return S.fx end
        getMouseY = function() return S.fy end
    end)
end
function S.mouseOff()
    if not S.mouseSwapped then return end
    pcall(function() getMouseX, getMouseY = S.realMX, S.realMY end)
    S.mouseSwapped = false
end
function S.ctxOpt() return ZeD.Settings.contextStyleOption end
function S.style(v) if v ~= nil then pcall(function() S.ctxOpt():setValue(v) end) end end
function S.vmenu() local v = nil; pcall(function() v = getPlayerContextMenu(S.pn) end); return v end
function S.menu() local v = S.vmenu(); return v and v._zedMenu or nil end
function S.closeMenu()
    S.mcOff()
    local m = S.menu()
    if m then pcall(m.close, m) end
    local v = S.vmenu()
    pcall(function() if v and not v._zedMenu and v.closeAll and v:isVisible() then v:closeAll() end end)
    S.mouseOff()
end
function S.menuSettled()
    if S.menu() then return true end
    local v = S.vmenu()
    if not v then return true end
    return v._zedFailed == true
end

-- ===================================================================== the input mode ZeD reads (kiss_loot.lua's)
function S.lockFound()
    local key = nil
    pcall(function()
        local o = S.opt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
function S.lock(mode)
    if not (S.Det and S.Det.setLockedMode) then return end
    pcall(function()
        if S.lockWas == nil then S.lockWas = S.lockFound() end
        if mode then
            S.Det.setLockedMode(mode)
            S.locked = true
            return
        end
        if not S.locked then return end
        S.locked = false
        S.Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
    end)
end

-- ===================================================================== "in use" (kiss_loot.lua's)
-- ZeD_Window:_inUse (Organisms.lua:418) asks pointerOn (:1706, the REAL pointer): held to what the picture's player does
function S.holdWin(w, val)
    if not w then return end
    w.pointerOn = function() return val end
    S.held[#S.held + 1] = w
end
function S.unhold()
    for _, w in ipairs(S.held) do w.pointerOn = nil end
    S.held = {}
end

-- ===================================================================== the windows
function S.homeLayout()
    if ZEDQA_LAYOUT_DEFAULT then pcall(ZEDQA_LAYOUT_DEFAULT, "dn_fh") else pcall(function() ZeD_Window.resetLayout() end) end
end
-- one list in each window: a column added on Loot taken off, one a frame (true when none is left)
function S.noColumns()
    local done = true
    for _, pair in ipairs({ { S.CW(), S.CWm }, { S.WW(), S.WWm } }) do
        local w, mod = pair[1], pair[2]
        local sel = w and w._mcSelected
        if sel and #sel > 0 and mod.toggleColumn then
            local c = w._containers and w._containers[sel[1]]
            if c and c.inventory then pcall(mod.toggleColumn, c.inventory, S.pn); done = false end
        end
    end
    return done
end

-- ===================================================================== the Base theme (Settings.lua:147-151, 1170-1201)
-- The option set as a player sets it (its index in ZeD.Settings.baseKeys) and the palette applied with the accent and
-- the text size as they are (ZeD.applyTheme keeps a nil key as found); nothing saved. Put back: the index and the base
-- found.
function S.themeIdx(key)
    for i, k in ipairs(ZeD.Settings.baseKeys) do if k == key then return i end end
    return nil
end
function S.theme(key)
    local o = S.opt("baseTheme")
    if S.was.base == nil then
        S.was.base = ZeD.currentBase or "dark"
        if o then pcall(function() S.was.baseIdx = o:getValue() end) end
    end
    local i = S.themeIdx(key)
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.themeSet = true
end
function S.themeBack()
    if not S.themeSet then return end
    S.themeSet = false
    local o = S.opt("baseTheme")
    if o and S.was.baseIdx then pcall(function() o:setValue(S.was.baseIdx) end) end
    pcall(ZeD.applyTheme, S.was.base, nil, nil)
end
function S.themeWord()
    local v = "?"
    local o = S.opt("baseTheme")
    if o then pcall(function() v = tostring(o:getValue()) end) end
    return tostring(ZeD.currentBase) .. " (option " .. v .. ")"
end

-- ===================================================================== colors
function S.lin(c)
    c = math.max(0, math.min(1, tonumber(c) or 0))
    if c <= 0.04045 then return c / 12.92 end
    return ((c + 0.055) / 1.055) ^ 2.4
end
function S.lum(c) return 0.2126 * S.lin(c.r) + 0.7152 * S.lin(c.g) + 0.0722 * S.lin(c.b) end
-- fg with its alpha over an opaque bg
function S.blend(fg, bg)
    local a = math.max(0, math.min(1, tonumber(fg.a) or 1))
    local function m(f, b) return (tonumber(f) or 0) * a + (tonumber(b) or 0) * (1 - a) end
    return { r = m(fg.r, bg.r), g = m(fg.g, bg.g), b = m(fg.b, bg.b), a = 1 }
end
-- the contrast ratio of fg over bg (a see-through bg is taken over black: what the game draws behind it is not known)
function S.ratio(fg, bg)
    local b0 = bg
    if (tonumber(bg.a) or 1) < 1 then b0 = S.blend(bg, { r = 0, g = 0, b = 0 }) end
    local f = S.blend(fg, b0)
    local l1, l2 = S.lum(f), S.lum(b0)
    if l1 < l2 then l1, l2 = l2, l1 end
    return (l1 + 0.05) / (l2 + 0.05), f, b0
end
function S.c4(c)
    if not c then return "none" end
    return string.format("%.3f,%.3f,%.3f alpha %.2f", tonumber(c.r) or 0, tonumber(c.g) or 0, tonumber(c.b) or 0, tonumber(c.a) or 1)
end
function S.c255(c)
    if not c then return "none" end
    local function k(v) return S.fl((tonumber(v) or 0) * 255 + 0.5) end
    return k(c.r) .. "," .. k(c.g) .. "," .. k(c.b)
end

-- ===================================================================== (1) the help line's decision, one frame
-- Each window's _drawHelpLine wrapped for the first frame it draws: footerHeight, the controller's prompts, the help
-- words the line took (ZeD.Help.take watched during the call), the lit resize handle, and whether a hairline was drawn
-- at the strip's top (the overlay's drawRect watched during the call: Organisms.lua:1140, T.hair high at fY)
function S.fcOn(wins)
    S.fcOff()
    local C = { on = true, rec = {}, wins = {} }
    for _, w in ipairs(wins) do
        if w then
            local e = { w = w, was = rawget(w, "_drawHelpLine"), orig = w._drawHelpLine }
            C.wins[#C.wins + 1] = e
            w._drawHelpLine = function(self, p, ww, hh, lit) return S.fcDraw(C, e, self, p, ww, hh, lit) end
        end
    end
    S.fc = C
end
function S.fcDraw(C, e, self, p, ww, hh, lit)
    if not (C.on and C.rec[self] == nil and p) then return e.orig(self, p, ww, hh, lit) end
    local r = { fH = -1, np = 0, lit = lit, hair = false, hairN = 0 }
    C.rec[self] = r
    pcall(function() r.fH = self:footerHeight() end)
    pcall(function() local pr = self:_footerPrompts(); r.np = pr and #pr or 0 end)
    pcall(function() r.inUse = self:_inUse() end)
    r.fwu, r.idle = self.footerWhenUsed, self._footIdle
    local H = ZeD.Help
    local tk = H.take
    H.take = function(win)
        local t = tk(win)
        if win == self then r.took, r.text = true, t end
        return t
    end
    local drWas, dr = rawget(p, "drawRect"), p.drawRect
    local fY, hair = hh - r.fH, ZeD.T.hair
    p.drawRect = function(pp, x, y, rw, rh, ...)
        if rh == hair and y == fY and rw > ww / 2 then r.hair = true; r.hairN = r.hairN + 1 end
        return dr(pp, x, y, rw, rh, ...)
    end
    local ok, err = pcall(e.orig, self, p, ww, hh, lit)
    p.drawRect = drWas
    H.take = tk
    if not ok then r.err = tostring(err) end
    r.says = (r.np > 0) or (r.text ~= nil and r.text ~= "") or (lit ~= nil and lit ~= false)
    r.wh = S.fl(ww) .. "x" .. S.fl(hh)
end
function S.fcOff()
    local C = S.fc
    if not C then return end
    C.on = false
    for _, e in ipairs(C.wins) do pcall(function() e.w._drawHelpLine = e.was end) end
    S.fc = nil
end
function S.fcDone()
    local C = S.fc
    if not C then return true end
    for _, e in ipairs(C.wins) do if C.rec[e.w] == nil then return false end end
    return true
end
function S.fcWord(C, w, label)
    local r = (C and w) and C.rec[w] or nil
    if not r then return label .. ": NOTE its help line was not drawn in the frame read" end
    return label .. " (" .. tostring(r.wh) .. "): footerHeight " .. tostring(r.fH) .. ", says " .. tostring(r.says)
        .. " (help words " .. ((r.text and r.text ~= "") and ("\"" .. tostring(r.text) .. "\"") or "none") .. ", controller prompts " .. tostring(r.np)
        .. ", resize handle lit " .. tostring(r.lit) .. "), the strip's top hairline drawn " .. tostring(r.hair)
        .. ", in use " .. tostring(r.inUse) .. ", footerWhenUsed " .. tostring(r.fwu)
        .. (r.err and (", NOTE the help line's draw threw: " .. r.err) or "")
end

-- ===================================================================== (2) the menu's draws, one frame
-- The menu panel's drawText and drawRect wrapped (instance fields over the class's; put back as found): every call of
-- the frame in order, so the heading's color and the rectangle drawn under it are read as drawn
function S.mcOn(m)
    S.mcOff()
    local C = { m = m, calls = {}, on = true }
    C.dtWas, C.drWas = rawget(m, "drawText"), rawget(m, "drawRect")
    C.dt, C.dr = m.drawText, m.drawRect
    m.drawText = function(self, s, x, y, r, g, b, a, ...)
        if C.on and #C.calls < 800 then C.calls[#C.calls + 1] = { k = "t", s = tostring(s), x = tonumber(x) or 0, y = tonumber(y) or 0, r = r, g = g, b = b, a = a } end
        return C.dt(self, s, x, y, r, g, b, a, ...)
    end
    m.drawRect = function(self, x, y, w, h, a, r, g, b, ...)
        if C.on and #C.calls < 800 then
            C.calls[#C.calls + 1] = { k = "r", x = tonumber(x) or 0, y = tonumber(y) or 0, w = tonumber(w) or 0, h = tonumber(h) or 0, a = a, r = r, g = g, b = b }
        end
        return C.dr(self, x, y, w, h, a, r, g, b, ...)
    end
    S.mc = C
end
function S.mcOff()
    local C = S.mc
    if not C then return end
    C.on = false
    pcall(function() C.m.drawText = C.dtWas end)
    pcall(function() C.m.drawRect = C.drWas end)
    S.mc = nil
end
function S.mcTexts(C)
    local n = 0
    for _, c in ipairs((C and C.calls) or {}) do if c.k == "t" then n = n + 1 end end
    return n
end
-- the first text call whose words start with first (nil: the first with words)
function S.mcFind(C, first)
    for i, c in ipairs(C.calls) do
        if c.k == "t" and c.s ~= "" and (first == nil or c.s:sub(1, #first) == first) then return i end
    end
    return nil
end
-- the last rectangle drawn before call i that holds the text's first pixel
function S.mcUnder(C, i)
    local t = C.calls[i]
    local px, py = t.x + 1, t.y + 1
    for j = i - 1, 1, -1 do
        local c = C.calls[j]
        if c.k == "r" and (tonumber(c.a) or 1) > 0 and px >= c.x and px < c.x + c.w and py >= c.y and py < c.y + c.h then return c end
    end
    return nil
end
-- the words of the heading's line: the text calls from i on at its height in its color
function S.mcLine(C, i)
    local t = C.calls[i]
    local out = {}
    for j = i, #C.calls do
        local c = C.calls[j]
        if c.k == "t" and c.y == t.y and c.r == t.r and c.g == t.g and c.b == t.b and c.a == t.a then out[#out + 1] = c.s end
    end
    return table.concat(out, " ")
end

-- ===================================================================== (2) the square right-clicked
-- Where the menu takes room on the screen from a click at (sx, sy): the list down and right of it
-- (ZeD_ContextList.lua:100-131, at most 420 units wide; room taken for a dozen rows), the strip's panel centered on it
-- with the balloon's room above (ZeD_ContextMenu.lua:1016-1087)
function S.foot(style, sx, sy)
    local T = ZeD.T
    if style == 2 then return sx, sy, T.px(420), T.px(4 * 2 + 26 + 24 * 12 + 9 * 3) end
    local stripH = T.px(48)
    local k = T.ctx
    if k and k.cellH and k.drilledBorderTop then stripH = k.cellH + k.drilledBorderTop + T.px(1) end
    return sx - T.px(200), sy - T.px(6) - stripH - T.px(160), T.px(400), T.px(160) + stripH + T.px(8)
end
-- the nearest bare square round him (up to 10 out) whose menu stays on screen and clear of him (G1.charRect); else
-- the nearest bare one on screen (clear = false)
function S.pickSq(style)
    if not S.c then return nil end
    local sw, sh = S.scr()
    local m = ZeD.T.px(8)
    local best, any = nil, nil
    for d = 1, 10 do
        for dy = -d, d do
            for dx = -d, d do
                if best == nil and math.max(math.abs(dx), math.abs(dy)) == d then
                    local X, Y = S.c.x + dx, S.c.y + dy
                    local sq = S.goodSq(S.sqAt(X, Y))
                    local sx, sy = nil, nil
                    if sq then
                        pcall(function()
                            sx = S.fl(isoToScreenX(S.pn, X + 0.5, Y + 0.5, 0))
                            sy = S.fl(isoToScreenY(S.pn, X + 0.5, Y + 0.5, 0))
                        end)
                    end
                    if sx and sy and sx > m and sy > m and sx < sw - m and sy < sh - m then
                        local c = { x = X, y = Y, sx = sx, sy = sy, sq = sq, d = d, clear = false }
                        if any == nil then any = c end
                        local bx, by, bw, bh = S.foot(style, sx, sy)
                        if bx >= m and by >= m and bx + bw <= sw - m and by + bh <= sh - m and not S.over(bx, by, bw, bh) then
                            c.clear = true
                            best = c
                        end
                    end
                end
            end
        end
    end
    return best or any
end
-- the menu's drawn box on the screen (the list's top level; the strip and its balloon)
function S.menuBox(m)
    if m.Type == "ZeD_ContextList" then
        local lv = m._levels and m._levels[1]
        if not lv then return nil end
        return { x = lv.x, y = lv.y, w = lv.w, h = lv.h }
    end
    local lc = m._layoutCache or {}
    local x0, y0 = m:getX(), m:getY()
    local x, y = x0 + (lc.stripX or 0), y0 + (lc.stripY or 0)
    local x1, y1 = x + (lc.stripW or 0), y + (lc.stripH or 0)
    if (lc.balloonW or 0) > 0 then
        local bx, by = x0 + (lc.balloonX or 0), y0 + (lc.balloonY or 0)
        x, y = math.min(x, bx), math.min(y, by)
        x1, y1 = math.max(x1, bx + lc.balloonW), math.max(y1, by + lc.balloonH)
    end
    return { x = x, y = y, w = x1 - x, h = y1 - y }
end
function S.laidOut(m)
    if not m then return false end
    if m.Type == "ZeD_ContextList" then return m._levels ~= nil and m._levels[1] ~= nil and (m._levels[1].w or 0) > 0 end
    local lc = m._layoutCache
    return lc ~= nil and (lc.stripW or 0) > 0 and (lc.balloonW or 0) > 0
end

-- ===================================================================== the pictures
function S.footerPic(th)
    local K = { name = "footer_" .. th.key }
    Q.step(10, function()
        S.closeMenu()
        S.openPair()
    end)
    Q.waitFor(5, 300, function() return S.CWm.isOpen() and S.WWm.isOpen() and S.CW() ~= nil and S.WW() ~= nil end, function(ok)
        if not ok then S.skip(K.name, "the windows did not open"); K.off = true end
    end)
    Q.step(20, function()
        if K.off then return end
        S.homeLayout()
        S.charTab("loot"); S.worldTab("loot")
        -- nothing hovered: the pointer the game reads off every window; both held in use, as the pointer on them holds them
        S.mouseOn(-9000, -9000)
        S.holdWin(S.CW(), true)
        S.holdWin(S.WW(), true)
    end)
    Q.waitFor(10, 600, function() return K.off or S.noColumns() end, function() end)
    Q.still(10, function() if not K.off then S.clearChar() end end)
    Q.still(6, function()
        if K.off then return end
        S.fcOn({ S.CW(), S.WW() })
        K.armed = true
    end)
    Q.waitFor(1, 60, function() return not K.armed or S.fcDone() end, function()
        if not K.armed then return end
        local C = S.fc
        S.fcOff()
        local cw, ww = S.CW(), S.WW()
        S.shotOk(K.name, "the " .. th.word .. " theme (" .. S.themeWord() .. "); both windows open on Loot (Character tab "
            .. tostring(cw and cw._activeTab) .. ", World tab " .. tostring(ww and ww._activeTab) .. "), held in use (the pointer on them), the pointer the game reads parked off"
            .. " every window (nothing hovered), the input mode locked to the mouse (no controller prompts); what each help line decided in the frame before the picture: "
            .. S.fcWord(C, cw, "the Character window") .. "; " .. S.fcWord(C, ww, "the World window")
            .. ((G1.covers(cw) or G1.covers(ww)) and "; NOTE a window covers him" or ""))
    end)
    Q.step(5, function() S.fcOff(); S.unhold(); S.mouseOff() end)
end

function S.groundPic(th, style)
    local K = { name = ((style == 2) and "ground_list_" or "ground_strip_") .. th.key, style = style }
    K.look = (style == 2) and "the list" or "the strip"
    Q.step(10, function()
        S.closeMenu()
        if not S.c then S.skip(K.name, "no open patch near the smoking spot"); K.off = true; return end
        -- the windows closed: the menu alone over the ground
        S.closePair()
        S.home("SE")
    end)
    S.settle(function() return not K.off end)
    Q.waitFor(5, 300, function() return K.off or not (S.CWm.isOpen() or S.WWm.isOpen()) end, function(ok)
        if not K.off and not ok then Q.say("note: " .. K.name .. ": a window is still open") end
    end)
    Q.step(10, function()
        if K.off then return end
        local c = S.pickSq(style)
        if not c then S.skip(K.name, "no bare square of the patch on the screen round him"); K.off = true; return end
        K.c = c
        -- ZeD's Context menu option for the picture (Settings.lua:275-281: 1 the strip, 2 the list)
        S.style(style)
        local objs = {}
        pcall(function()
            local os = c.sq:getObjects()
            for i = 0, os:size() - 1 do objs[#objs + 1] = os:get(i) end
        end)
        K.nObjs = #objs
        -- the right-click on the ground: the game's world menu for the square's objects at its point on the screen, the
        -- pointer the game reads there (ZeD anchors the menu at it, Overrides/ContextMenu.lua:213-219)
        S.mouseOn(c.sx, c.sy)
        local okM, e = pcall(ISWorldObjectContextMenu.createMenu, S.pn, objs, c.sx, c.sy)
        if not okM then K.err = tostring(e) end
        K.asked = true
    end)
    -- made: the pointer the game reads goes off the menu (no row or cell hovered)
    Q.waitFor(1, 300, function() return K.off or not K.asked or K.err ~= nil or S.menuSettled() end, function()
        if K.asked then S.mouseOn(-9000, -9000) end
    end)
    Q.waitFor(1, 180, function() return K.off or not K.asked or K.err ~= nil or S.laidOut(S.menu()) end, function() end)
    S.wait(500, function() return false end, function() end)
    Q.still(2, function()
        if K.off or not K.asked then return end
        local m = S.menu()
        if K.err or not m then
            local v = S.vmenu()
            S.skip(K.name, K.err and ("the world menu threw: " .. K.err) or ("ZeD's menu did not open (the game's options "
                .. tostring(v and v.options and #v.options) .. ", ZeD's menu failed " .. tostring(v and v._zedFailed) .. ")"))
            K.off = true
            return
        end
        local want = (style == 2) and "ZeD_ContextList" or "ZeD_ContextMenu"
        if m.Type ~= want then S.skip(K.name, "the menu opened as " .. tostring(m.Type) .. ", not " .. want); K.off = true; return end
        S.mcOn(m)
        K.armed = true
    end)
    Q.waitFor(1, 60, function() return not K.armed or S.mcTexts(S.mc) > 0 end, function()
        if not K.armed then return end
        local C = S.mc
        S.mcOff()
        local m = S.menu()
        if not (C and m) then S.skip(K.name, "the menu closed before its frame was read"); return end
        S.groundShot(K, th, C, m)
    end)
    Q.step(5, function()
        S.mcOff()
        S.closeMenu()
        S.style(S.was.style)
    end)
end

-- the menu's heading read from the frame's draws, and the picture
function S.groundShot(K, th, C, m)
    local T = ZeD.T
    local head, i = nil, nil
    if K.style == 2 then
        local nm = nil
        pcall(function() nm = ZeD.ContextMenu.Registry.getTargetDisplay(m._ctx.target) end)
        if m.headText then nm = m.headText end
        head = tostring(nm or "")
        i = S.mcFind(C, nil)
    else
        local def = m._ctx and m._ctx.currentDef
        head = tostring((def and def.name) or "")
        local w1 = head:match("^%s*(%S+)")
        i = S.mcFind(C, w1)
    end
    local t = i and C.calls[i] or nil
    local bg = i and S.mcUnder(C, i) or nil
    local col = t and { r = tonumber(t.r) or 0, g = tonumber(t.g) or 0, b = tonumber(t.b) or 0, a = tonumber(t.a) or 1 } or nil
    local bgc = bg and { r = tonumber(bg.r) or 0, g = tonumber(bg.g) or 0, b = tonumber(bg.b) or 0, a = tonumber(bg.a) or 1 } or nil
    local cr, seen = "not read", ""
    if col and bgc then
        local ratio, f, b0 = S.ratio(col, bgc)
        cr = string.format("%.2f", ratio) .. ":1 (" .. ((ratio >= 4.5) and "passes" or "BELOW") .. " WCAG AA 4.5:1 for normal text, "
            .. ((ratio >= 3) and "passes" or "BELOW") .. " 3:1 for large text; the heading as seen " .. S.c255(f) .. " on " .. S.c255(b0) .. ")"
    end
    local box = S.menuBox(m)
    local where = "?"
    if box then
        where = S.box(box.x, box.y, box.w, box.h) .. (S.over(box.x, box.y, box.w, box.h) and " (NOTE over the character)" or " (clear of him)")
    end
    local c = K.c
    local rows = "?"
    if K.style == 2 then rows = tostring(m._levels and m._levels[1] and m._levels[1].rows and #m._levels[1].rows) .. " rows"
    else rows = tostring(m._ctx and m._ctx.items and #m._ctx.items) .. " cells" end
    local what = "the " .. th.word .. " theme (" .. S.themeWord() .. "); the windows closed; Context menu set to " .. K.look .. " for the picture (the setting was "
        .. tostring(S.was.style) .. "); a right-click on the bare square " .. c.x .. "," .. c.y .. " (" .. c.d .. " out from him, "
        .. tostring(K.nObjs) .. " object(s) on it) at " .. c.sx .. "," .. c.sy .. " on the screen" .. (c.clear and "" or " (NOTE no square round him keeps the menu clear of him)")
        .. ": ZeD's " .. tostring(m.Type) .. " open with " .. rows .. ", at " .. where .. ", the pointer the game reads parked off it; "
    if K.style == 2 then
        what = what .. "its heading (the pointed-at name, ZeD_ContextList.lua:346-366 in T.textDim) \"" .. head .. "\""
    else
        what = what .. "the strip names nothing it acts on; its one heading is the balloon's title (the lit cell's action, Balloon.lua drawWords in its own light palette) \"" .. head .. "\""
    end
    if t then
        what = what .. ", drawn as \"" .. S.mcLine(C, i) .. "\" in RGBA " .. S.c4(col) .. " (" .. S.c255(col) .. ")"
            .. "; under it the " .. ((K.style == 2) and "menu's" or "balloon's") .. " background " .. S.c4(bgc) .. " (" .. S.c255(bgc) .. ")"
            .. "; contrast " .. cr
    else
        what = what .. ", NOTE not found among the frame's " .. S.mcTexts(C) .. " text draws"
    end
    what = what .. "; the theme's T.textDim " .. S.c4(T.textDim) .. ", T.surf1 " .. S.c4(T.surf1) .. ", T.textHead " .. S.c4(T.textHead)
    S.shotOk(K.name, what, true)
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    if getGameSpeed() ~= 1 then pcall(setGameSpeed, 1) end
    S.was.style = S.ctxOpt():getValue()
    pcall(function() S.was.zoom = S.core:getZoom(S.pn) end)
    S.lock("kbm")
    local c = S.P.smoke or S.P.centre
    if c then S.c = S.findPatch(c[1], c[2]) end
    S.openPair()
    Q.say("the patch's middle " .. (S.c and (S.c.x .. "," .. S.c.y) or "none") .. " | Context menu setting " .. tostring(S.was.style)
        .. " (1 the strip, 2 the list) | theme " .. S.themeWord() .. " | input lock found " .. tostring(S.lockWas) .. " | zoom found " .. tostring(S.was.zoom))
end)
Q.zoomTo(1.0)
Q.waitFor(10, 600, function() return S.CW() ~= nil and S.WW() ~= nil and S.CWm.isOpen() and S.WWm.isOpen() end, function(ok)
    if not ok then Q.say("ERR the windows did not open") end
    pcall(function() S.was.snap = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() or nil end)
end)
Q.step(5, function() if S.c then S.home("SE") end end)
S.settle(function() return S.c ~= nil end)

for _, th in ipairs(S.THEMES) do
    Q.step(10, function()
        S.closeMenu()
        S.theme(th.key)
        Q.say(th.word .. ": theme now " .. S.themeWord())
    end)
    S.footerPic(th)
    S.groundPic(th, 2)
    S.groundPic(th, 1)
    Q.step(10, function()
        S.closeMenu()
        S.themeBack()
        Q.say(th.word .. " done: theme back to " .. S.themeWord())
    end)
end

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.fcOff()
    S.closeMenu()
    S.mouseOff()
    S.unhold()
    S.style(S.was.style)
    S.themeBack()
    S.lock(false)
    G1.glassesBack(Q)
end)
Q.waitFor(5, 300, function() return S.noColumns() end, function() end)
S.zoomDyn(function() return S.was.zoom end)
Q.step(20, function()
    S.openPair()
    S.charTab("loot"); S.worldTab("loot")
    if ZEDQA_LAYOUT_BACK and S.was.snap then pcall(ZEDQA_LAYOUT_BACK, S.was.snap, "dn_fh") end
    if S.P.stock then G1.tp(S.P.stock, "SE") end
    S.back0()
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Events.OnPreUIDraw.Remove(S.errWatch)
    local mode = "?"
    if S.Det and S.Det.getMode then pcall(function() mode = tostring(S.Det.getMode(S.pn)) end) end
    Q.say("put back: theme " .. S.themeWord() .. " (found " .. tostring(S.was.base) .. ", option " .. tostring(S.was.baseIdx) .. "), Context menu setting "
        .. tostring(S.ctxOpt():getValue()) .. " (found " .. tostring(S.was.style) .. "), input lock as found (" .. tostring(S.lockWas) .. "; ZeD reads " .. mode
        .. "), zoom " .. tostring(S.zoom()) .. " (found " .. tostring(S.was.zoom) .. "), mouse swap " .. tostring(S.mouseSwapped == true) .. ", windows held " .. #S.held
        .. ", draws wrapped " .. tostring(S.fc ~= nil or S.mc ~= nil) .. ", a menu open " .. tostring(S.menu() ~= nil)
        .. "; pictures taken: " .. ((#S.pic > 0) and table.concat(S.pic, ", ") or "none"))
end)
Q.start()
