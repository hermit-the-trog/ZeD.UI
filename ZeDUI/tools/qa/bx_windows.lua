-- ZeDUI/tools/qa/bx_windows.lua  (Nov 21 2026, QA beast mode): the two ZeD windows worked hard, the way a restless
-- player works them. Built on rt_kit.lua (the global RT); run after zedqa_prelude.lua. grep "ZEDQA bx_win".
-- Every act goes through the window's own handlers (a title-bar press and its moves, the resize the edges run, the
-- boxes' update path, the menu's own rows), then: RT.bounds, both windows in one piece, no new Lua error, and at the
-- end of each part a tab switched on both windows ("still usable").
--   1. Drag: both windows by the title bar to the four edges and four corners (far past them, in six moves), then
--      half off each edge in one move; again with a full card open on both. The screen edge must stop them.
--   2. Resize in the engine's order (the press inside update, then onResize): bottom edge, grow box, bottom-left
--      corner, the side edges; to the least and to the most the screen allows; again with a drawer open.
--   3. Roll up and down: a double-click on the title bar, at the default place and parked at the screen's foot; a tab
--      opened by its key on a rolled-up window; the curtain rolled, dragged by its rod to both sides, shaded while
--      rolled, unrolled by the rod's tab.
--   4. Pins: each half's pin and the joined pin through the title bar's own path (update), saved with the character;
--      21 presses in one frame; with no pad, all unpinned and the pointer away both windows roll up, the pointer on the
--      Character bar brings it down, pinning brings everything back.
--   5. The window box's menu: opened at a screen corner, one menu at a time, left behind when its window closes;
--      every choice of Theme, Accent, Text size, See-through and Controller highlight; Reset this, Save position, Go to
--      saved position (greyed with nothing saved), Bug report, the keyboard map, Hide interface (and back).
--      ZeD setup is not pressed: it opens the pause screen, and a pause screen left up would stop the scripts after this.
--   6. Reset both windows out of a mess (one rolled up small at a corner, one with its side rolled).
--   7. One window on top of the other: the one pressed last is on top, the menu above both.
--   8. Closed and opened 50 times, five ways to close, a tab picked every time (by the strip, or by the tab's key
--      action at once): one window each, no rod left behind, and the windows where they started (2 px).
-- Put back: the pointer the game reads, menus and maps shut, the interface shown, theme, text size, see-through and
-- controller highlight, each window's accent, the clipboard, the halves' pins, the saved places file, the layout
-- (ZEDQA_LAYOUT_BACK), the tabs, the game speed, and the pair open or shut as found.
-- The character (Nov 21 2026, after the first run): nothing here hurts him, but the world stays live for the whole
-- run and after it, so god mode and invincible are ON from the first step and stay ON when the script ends (never
-- turned off here); the put-back heals him if anything is wrong and prints "put back: the character is alive and
-- whole" as a PASS or a FAIL.
-- ZeD faults the first run found, their checks kept as they are (they FAIL until Build fixes them):
--   * a window rolled up by a double-click while its side is rolled keeps its rod on screen (WindowCurtain.lua C.sync
--     hides it, but C.sync runs from the drawer's prerender, which a rolled-up window does not draw);
--   * the window box's menu stays up when the inventory key closes its window (ZeD_WindowMenu.lua has no watch);
--   * Reset both windows leaves the World window's tab as it was, its card shut (Organisms.lua resetWorld never sets
--     _activeTab = "loot" as resetChar does). The put-back here presses Loot before its own reset because of it.
local Q = RT.make("bx_win")
Q.maxMs = 420000   -- (7 minutes: past it the run jumps to the put-back)
local pn = RT.pn
local S = { tabs = { c = {}, w = {} }, ti = { c = 0, w = 0 }, st = {}, tab = {}, fired = {}, realMX = getMouseX, realMY = getMouseY }
local X = {}
local KS = { "c", "w" }
local PIN_KEYS = { "charInv", "charTabs", "char", "worldInv", "worldTabs", "world" }

-- ===================================================================== helpers
function X.T() return ZeD.T end
function X.sw() return RT.core:getScreenWidth() end
function X.sh() return RT.core:getScreenHeight() end
function X.mod(n, m) return n - math.floor(n / m) * m end
function X.err()
    local n = nil
    pcall(function() n = getLuaDebuggerErrorCount() end)
    return n
end
function X.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for a, b in pairs(t) do o[a] = b end
    return o
end
-- the character as the game has him now (the kit's RT.p is read once, when the kit loads)
function X.me()
    local p = nil
    pcall(function() p = getSpecificPlayer(pn) end)
    return p or RT.p
end
-- the character: what is wrong with him (an empty list: alive and whole), and his overall health. Never throws: a
-- part of him that cannot be read counts as wrong.
function X.hurt()
    local p = X.me()
    local bad = {}
    local dead = true
    pcall(function() dead = p:isDead() end)
    if dead then bad[#bad + 1] = "dead" end
    local bd = nil
    pcall(function() bd = p:getBodyDamage() end)
    if not bd then bad[#bad + 1] = "his body cannot be read"; return bad, nil end
    local overall = nil
    pcall(function() overall = bd:getOverallBodyHealth() end)
    if not (overall and overall >= 99.5) then bad[#bad + 1] = "health " .. tostring(overall) end
    local inf = nil
    pcall(function() inf = bd:IsInfected() end)
    if inf ~= false then bad[#bad + 1] = "infected " .. tostring(inf) end
    local wounds, breaks, n = 0, 0, 0
    local okP = pcall(function()
        local parts = bd:getBodyParts()
        n = parts:size()
        for i = 0, n - 1 do
            local b = parts:get(i)
            local w, f = true, true
            pcall(function()
                w = b:HasInjury() or b:bleeding() or b:bitten() or b:scratched() or b:isCut() or b:deepWounded()
                    or b:haveBullet() or b:haveGlass() or b:getBurnTime() > 0 or b:isInfectedWound()
            end)
            pcall(function() f = b:getFractureTime() > 0 end)
            if w then wounds = wounds + 1 end
            if f then breaks = breaks + 1 end
        end
    end)
    if not (okP and n > 0) then bad[#bad + 1] = "his body parts cannot be read" end
    if wounds > 0 then bad[#bad + 1] = wounds .. " wounded part(s)" end
    if breaks > 0 then bad[#bad + 1] = breaks .. " fracture(s)" end
    return bad, overall
end
-- every part and the whole body healed (the restores take no argument; the three setters take one)
function X.heal()
    local bd = nil
    pcall(function() bd = X.me():getBodyDamage() end)
    if not bd then return end
    pcall(function()
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            pcall(function() b:RestoreToFullHealth() end)
        end
    end)
    pcall(function() bd:RestoreToFullHealth() end)
    pcall(function() bd:setInfected(false) end)
    pcall(function() bd:setIsFakeInfected(false) end)
    pcall(function() bd:setOverallBodyHealth(100) end)
end
function X.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function X.gs(g)
    if not g then return "none" end
    return math.floor(g.x) .. "," .. math.floor(g.y) .. " " .. math.floor(g.w) .. "x" .. math.floor(g.h)
end
function X.same(a, b, slack)
    if not (a and b) then return false end
    slack = slack or 0
    return math.abs(a.x - b.x) <= slack and math.abs(a.y - b.y) <= slack and math.abs(a.w - b.w) <= slack and math.abs(a.h - b.h) <= slack
end
function X.win(k) if k == "c" then return RT.cw() end; return RT.ww() end
function X.name(k) if k == "c" then return "Character" end; return "World" end
function X.strip(k) if k == "c" then return RT.charStrip() end; return RT.worldStrip() end
function X.press(k, id)
    if k == "c" then return RT.charTab(id) end
    return RT.worldTab(id)
end
function X.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(pn) end); return o end
function X.bothOpen()
    local c, w = RT.cw(), RT.ww()
    return RT.isOpen() and X.worldOpen() and c ~= nil and w ~= nil and c:isVisible() and w:isVisible()
end
function X.bothShut() return (not RT.isOpen()) and (not X.worldOpen()) end
function X.toggle() return pcall(ZeD_CharacterWindow.toggleBothPaired, pn) end
function X.pinAll()
    for _, k in ipairs(KS) do
        local w = X.win(k)
        if w and w._halves and ZeD.Halves and ZeD.Halves.setPin then pcall(ZeD.Halves.setPin, w, nil, true) end
    end
end
-- the pointer the game reads: x, y for as long as it takes (nil: the real one again)
function X.pointer(x, y)
    if x then
        getMouseX = function() return x end
        getMouseY = function() return y end
    else
        getMouseX, getMouseY = S.realMX, S.realMY
    end
end
-- the pointer at mx, my for the length of fn only
function X.withMouse(mx, my, fn)
    local ox, oy = getMouseX, getMouseY
    getMouseX = function() return mx end
    getMouseY = function() return my end
    local ok, e = pcall(fn)
    getMouseX, getMouseY = ox, oy
    return ok, e
end
-- a press the way the engine delivers one: inside the element's update, followed by its onResize
-- (zedqa_curtain.lua's viaUpdate; el._qaPressDone is false until the update ran it)
function X.via(el, fn)
    local own = rawget(el, "update")
    el._qaPressDone = false
    S.pressErr = nil
    el.update = function(self)
        self.update = own
        self:update()
        local ok, e = pcall(fn, self)
        if not ok then S.pressErr = tostring(e) end
        pcall(function() self:onResize() end)
        self._qaPressDone = true
    end
end
-- any part of a window (and its rod, while its side is rolled) outside the screen
function X.offOne(w)
    if not w then return true end
    local W, H = X.sw(), X.sh()
    local x, y = w:getX(), w:getY()
    if x < -1 or y < -1 or x + w:getWidth() > W + 1 or y + w:getHeight() > H + 1 then return true end
    local rod = w._rod
    if w._rolled and rod and rod:isVisible() then
        local rx, ry = rod:getX(), rod:getY()
        if rx < -1 or ry < -1 or rx + rod:getWidth() > W + 1 or ry + rod:getHeight() > H + 1 then return true end
    end
    return false
end
-- every visible ZeD root outside the screen, as RT.bounds reads them, without a line printed
function X.off()
    local W, H = X.sw(), X.sh()
    local bad = {}
    for _, r in ipairs(RT.roots()) do
        local vis = false
        pcall(function() vis = r.e:isVisible() end)
        if vis and RT.isZeD(r.t) then
            local x, y, w, h = r.e:getX(), r.e:getY(), r.e:getWidth(), r.e:getHeight()
            if w > 2 and h > 2 and not (w >= W - 2 and h >= H - 2) and (x < -1 or y < -1 or x + w > W + 1 or y + h > H + 1) then
                bad[#bad + 1] = tostring(r.t.Type) .. " " .. math.floor(x) .. "," .. math.floor(y) .. " " .. math.floor(w) .. "x" .. math.floor(h)
            end
        end
    end
    return bad
end
-- curtain rods on screen that no rolled, open window holds
function X.strayRods()
    local n = 0
    for _, r in ipairs(RT.roots()) do
        local vis = false
        pcall(function() vis = r.e:isVisible() end)
        if vis and r.t and r.t.Type == "ZeD_CurtainRod" then
            local win = r.t.win
            local held = win ~= nil and (win == RT.cw() or win == RT.ww()) and win._rod == r.t and win._rolled
            if not held then n = n + 1 end
        end
    end
    return n
end
-- how many Character and World windows the UI manager holds
function X.countWins()
    local c, w = 0, 0
    for _, r in ipairs(RT.roots()) do
        if r.t and r.t.Type == "ZeD_Window" then
            if r.t._zedLabel == "Character" then c = c + 1 end
            if r.t._zedLabel == "World" then w = w + 1 end
        end
    end
    return c, w
end
-- a window in one piece: nil, or what is wrong
function X.sane(k)
    local w = X.win(k)
    if not w then return "closed" end
    local bad = {}
    if not w:isVisible() then bad[#bad + 1] = "not shown" end
    if w.moving then bad[#bad + 1] = "still held by a drag" end
    if w._resizing then bad[#bad + 1] = "still held by a resize" end
    if w:getWidth() < 10 or w:getHeight() < w:titleBarHeight() - 1 then bad[#bad + 1] = "size " .. X.gs(X.geo(w)) end
    local rod = w._rod
    if w._rolled and not rod then bad[#bad + 1] = "side rolled with no rod" end
    if (not w._rolled) and rod and rod:isVisible() then bad[#bad + 1] = "a rod showing with the side down" end
    if #bad == 0 then return nil end
    return table.concat(bad, ", ")
end
-- after every act: RT.bounds, and a FAIL line only when a window is in pieces or a Lua error came
function X.after(label)
    RT.bounds(Q, label)
    local bad = {}
    for _, k in ipairs(KS) do
        local s = X.sane(k)
        if s then bad[#bad + 1] = X.name(k) .. ": " .. s end
    end
    local rods = X.strayRods()
    if rods > 0 then bad[#bad + 1] = rods .. " curtain rod(s) showing with no rolled window" end
    if #bad > 0 then Q.check(false, label .. ": both windows in one piece", table.concat(bad, "; ")) end
    if S.hasErr then
        local e = X.err()
        if e ~= S.errAt then
            Q.check(false, label .. ": no new Lua error", tostring(S.errAt) .. " -> " .. tostring(e))
            S.errAt = e
        end
    end
end
-- the end of a part: one line for its Lua errors
function X.partEnd(part)
    Q.step(2, function()
        if not S.hasErr then return end
        local e = X.err()
        Q.check(e == S.secErr, part .. ": no Lua error through the whole part", tostring(S.secErr) .. " -> " .. tostring(e))
        S.secErr, S.errAt = e, e
    end)
end

-- ===================================================================== tabs
-- true once window k shows tab id and its drawer has held one width for 10 frames
function X.settled(k, id)
    local w = X.win(k)
    if not w then return false end
    local st = S.st[k]
    if not st then st = { same = 0 }; S.st[k] = st end
    local e = math.floor(w._drawerEffW or 0)
    if e == st.last then st.same = st.same + 1 else st.same, st.last = 0, e end
    return w._activeTab == id and st.same >= 10
end
function X.pref(k, list)
    for _, want in ipairs(list) do
        for _, id in ipairs(S.tabs[k]) do if id == want then return id end end
    end
    for _, id in ipairs(S.tabs[k]) do if id ~= "loot" then return id end end
    return nil
end
-- open a tab for the acts after it (list: the tabs wanted, first one the strip offers; nil: Loot)
function X.tabStep(k, list)
    Q.step(3, function()
        S.st[k] = nil
        local id = "loot"
        if list then id = X.pref(k, list) end
        S.tab[k] = id
        S.tabIn = (id ~= nil) and X.press(k, id) or false
    end)
    Q.waitFor(3, 400, function() return (not S.tab[k]) or X.settled(k, S.tab[k]) end, function(ok)
        if not (ok and S.tabIn) then
            local w = X.win(k)
            Q.check(false, X.name(k) .. " tab " .. tostring(S.tab[k]) .. ": opens for the acts after it", "active " .. tostring(w and w._activeTab))
        end
    end)
end
-- the next tab on the strip a player could press now: on view on the strip, not the open one
function X.pick(k)
    local w, strip = X.win(k), X.strip(k)
    if not (w and strip) then return nil end
    local zs = {}
    for _, z in ipairs(strip._hitZones or {}) do
        local id = type(z.id) == "string" and z.id:match("^tab:(.+)$")
        if id then zs[#zs + 1] = { id = id, z = z } end
    end
    if #zs == 0 then return nil end
    local sh = strip:getHeight()
    for _ = 1, #zs do
        S.ti[k] = S.ti[k] + 1
        local e = zs[X.mod(S.ti[k] - 1, #zs) + 1]
        local top = e.z.y + 2
        if e.id ~= w._activeTab and top >= 0 and top < sh then return e.id end
    end
    return nil
end
-- "still usable": a tab switched on both windows through their strips, the next tab along each time
function X.usable(label)
    Q.step(3, function()
        S.u = {}
        for _, k in ipairs(KS) do
            local w = X.win(k)
            local u = { miss = w == nil }
            if w then
                u.shaded = w.windowShaded and true or false
                if u.shaded then
                    pcall(ZeD.Halves.showAll, w)
                    if w.windowShaded then pcall(w.setWindowShaded, w, false) end
                end
            end
            S.u[k] = u
        end
    end)
    Q.step(4, function()
        for _, k in ipairs(KS) do
            local u = S.u[k]
            if not u.miss then
                u.from = X.win(k)._activeTab
                u.id = X.pick(k)
                u.pressed = false
                if u.id then u.pressed = X.press(k, u.id) end
            end
            S.st[k] = nil
        end
    end)
    Q.waitFor(2, 300, function()
        local done = true
        for _, k in ipairs(KS) do
            local u = S.u[k]
            if u.id and not X.settled(k, u.id) then done = false end
        end
        return done
    end, function()
        for _, k in ipairs(KS) do
            local u, w = S.u[k], X.win(k)
            local act = w and w._activeTab
            local eff = w and math.floor(w._drawerEffW or 0) or -1
            Q.check((not u.miss) and u.id ~= nil and u.pressed and act == u.id and (u.id == "loot" or eff > 0),
                label .. ": the " .. X.name(k) .. " window still switches tabs (" .. tostring(u.from) .. " to " .. tostring(u.id) .. ")",
                "active " .. tostring(act) .. ", drawer " .. eff .. " px" .. (u.shaded and ", it was rolled up" or ""))
        end
        X.after(label .. ", after the tab switch")
    end)
end

-- ===================================================================== a fresh start for each part
function X.ensure(label)
    Q.step(2, function()
        X.pointer(nil)
        if not X.bothOpen() then
            Q.check(false, label .. ": both windows are open when the part starts", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(X.worldOpen()))
            pcall(function() if not ISUIHandler.allUIVisible then ISUIHandler.toggleUI() end end)
            if not (RT.isOpen() and X.worldOpen()) then X.toggle() end
        end
    end)
    Q.waitFor(2, 240, X.bothOpen, function()
        X.pinAll()
        for _, k in ipairs(KS) do
            local w = X.win(k)
            if w then
                w.moving = false
                if w._resizing then pcall(function() w:_stopResize() end) end
                if w._rolled then pcall(ZeD.Curtain.finishUnroll, w) end
                if w.windowShaded then pcall(ZeD.Halves.showAll, w) end
                if w.windowShaded then pcall(w.setWindowShaded, w, false) end
            end
        end
    end)
end
-- both windows open, pinned, down, at the default spread on Loot (staging: the mod's own reset)
function X.fresh(label)
    X.ensure(label)
    Q.step(3, function() pcall(function() ZeD_Window.resetLayout() end) end)
    Q.step(3, function()
        -- (Loot pressed on each strip too: part 6 is where the reset's own tab is checked)
        X.press("c", "loot")
        X.press("w", "loot")
        S.st = {}
    end)
    Q.waitFor(3, 300, function() return X.settled("c", "loot") and X.settled("w", "loot") end, function(ok)
        if not ok then Q.check(false, label .. ": staging, both windows reset and on Loot") end
        S.def = { c = X.geo(RT.cw()), w = X.geo(RT.ww()) }
        if #S.tabs.c == 0 then S.tabs.c = RT.tabs(RT.charStrip()) end
        if #S.tabs.w == 0 then S.tabs.w = RT.tabs(RT.worldStrip()) end
    end)
end

-- ===================================================================== 1. drag
function X.titlePt(w) return math.floor(w:getWidth() / 2), math.floor(w:titleBarHeight() / 2) end
-- a press on the title bar, n moves, the release (outside: the moves as the engine sends them off the window)
function X.drag(w, dx, dy, n, outside)
    local px, py = X.titlePt(w)
    w._lastTitleClick = nil   -- (no double-click out of two quick drags)
    local ok, e = pcall(w.onMouseDown, w, px, py)
    if not ok then S.dragErr = tostring(e) end
    local grabbed = w.moving == true
    local sx, sy = math.floor(dx / n), math.floor(dy / n)
    local move = outside and w.onMouseMoveOutside or w.onMouseMove
    for _ = 1, n do
        local ok2, e2 = pcall(move, w, sx, sy)
        if not ok2 then S.dragErr = tostring(e2) end
    end
    pcall(w.onMouseUp, w, px, py)
    w._lastTitleClick = nil
    return grabbed
end
function X.atEdge(w, tx, ty)
    local W, H = X.sw(), X.sh()
    local g = X.geo(w)
    if tx < 0 and g.x > 1 then return false end
    if tx > 0 and g.x + g.w < W - 1 then return false end
    if ty < 0 and g.y > 1 then return false end
    if ty > 0 and g.y + g.h < H - 1 then return false end
    return true
end
-- how far to pull: far past the edge, or (half) to leave half the window off it
function X.delta(w, tx, ty, half)
    if not half then return tx * S.big, ty * S.big end
    local W, H = X.sw(), X.sh()
    local g = X.geo(w)
    local dx, dy = 0, 0
    if tx < 0 then dx = -(g.x + math.floor(g.w / 2)) end
    if tx > 0 then dx = (W - g.x - g.w) + math.floor(g.w / 2) end
    if ty < 0 then dy = -(g.y + math.floor(g.h / 2)) end
    if ty > 0 then dy = (H - g.y - g.h) + math.floor(g.h / 2) end
    return dx, dy
end
X.EDGES = {
    { n = "the left edge", tx = -1, ty = 0 }, { n = "the top right corner", tx = 1, ty = -1 },
    { n = "the foot", tx = 0, ty = 1 }, { n = "the top left corner", tx = -1, ty = -1 },
    { n = "the right edge", tx = 1, ty = 0 }, { n = "the bottom left corner", tx = -1, ty = 1 },
    { n = "the top", tx = 0, ty = -1 }, { n = "the bottom right corner", tx = 1, ty = 1 },
}
X.HALVES = {
    { n = "half off the left edge", tx = -1, ty = 0, half = true }, { n = "half off the foot", tx = 0, ty = 1, half = true },
    { n = "half off the right edge", tx = 1, ty = 0, half = true }, { n = "half off the top", tx = 0, ty = -1, half = true },
}
X.CORNERS = { X.EDGES[2], X.EDGES[6], X.EDGES[4], X.EDGES[8] }
-- the Character window dragged to t, the World window the opposite way, in one frame; then both read again
function X.dragStep(t, tag)
    Q.step(3, function()
        S.d = {}
        S.dragErr = nil
        for _, k in ipairs(KS) do
            local w = X.win(k)
            if w then
                local sgn = (k == "c") and 1 or -1
                local tx, ty = t.tx * sgn, t.ty * sgn
                local dx, dy = X.delta(w, tx, ty, t.half)
                local grabbed = X.drag(w, dx, dy, t.half and 1 or 6, k == "w")
                S.d[k] = { tx = tx, ty = ty, grabbed = grabbed, g = X.geo(w), at = X.atEdge(w, tx, ty), off = X.offOne(w) }
            end
        end
    end)
    Q.step(6, function()
        for _, k in ipairs(KS) do
            local d, w = S.d[k], X.win(k)
            local label = "drag" .. tag .. ": the " .. X.name(k) .. " window, " .. ((k == "c") and "to " or "away from ") .. t.n
            if not (d and w) then
                Q.check(false, label .. ": the window is there to drag")
            else
                Q.check(d.grabbed and d.at and not d.off and S.dragErr == nil, label .. ": the screen edge stops it, all of it on screen",
                    X.gs(d.g) .. (d.grabbed and "" or ", the title bar did not take the press") .. (S.dragErr and (", error " .. S.dragErr) or ""))
                local g = X.geo(w)
                Q.check(X.same(g, d.g, 1), label .. ": let go, it stays where it was dropped", X.gs(d.g) .. " -> " .. X.gs(g))
            end
        end
        X.after("drag" .. tag .. ", " .. t.n)
    end)
end
function X.partDrag()
    X.fresh("1 drag")
    for _, t in ipairs(X.EDGES) do X.dragStep(t, "") end
    X.usable("1 drag, after the edges and corners")
    for _, t in ipairs(X.HALVES) do X.dragStep(t, "") end
    X.tabStep("c", { "skills", "health", "equip" })
    X.tabStep("w", { "craft", "maps", "forage" })
    for _, t in ipairs(X.CORNERS) do X.dragStep(t, " (cards open)") end
    X.usable("1 drag, after the corners with cards open")
    X.partEnd("1 drag")
end

-- ===================================================================== 2. resize (the engine's order)
X.RZ = {
    { n = "the bottom edge pushed up past the title", mode = "s", px = "mid", py = "up", h = "min" },
    { n = "the bottom edge pulled to the screen's foot", mode = "s", px = "mid", py = "foot", h = "max" },
    { n = "the grow box pushed up and in past the corner", mode = "se", px = "in", py = "up", h = "min", w = "min", use = true },
    { n = "the grow box pulled to the screen's far corner", mode = "se", px = "far", py = "foot", h = "max", w = "max" },
    { n = "the bottom left corner pushed in past the right edge", mode = "sw", px = "right", py = "up", h = "min", w = "min" },
    { n = "the bottom left corner pulled to the screen's left foot", mode = "sw", px = "zero", py = "foot", h = "max", w = "max" },
    { n = "the right edge pushed in", mode = "e", px = "in", py = "mid", w = "min" },
    { n = "the left edge pulled to the screen's left", mode = "w", px = "zero", py = "mid", w = "max" },
}
X.RZ_CARD = {
    { n = "the grow box pushed up and in, a card open", mode = "se", px = "in", py = "up", card = true },
    { n = "the grow box pulled to the far corner, a card open", mode = "se", px = "far", py = "foot", card = true },
}
function X.rzPoint(w, a)
    local ax, ay = w:getAbsoluteX(), w:getAbsoluteY()
    local mx, my = ax + math.floor(w:getWidth() / 2), ay + math.floor(w:getHeight() / 2)
    if a.px == "in" then mx = ax - 400 end
    if a.px == "far" then mx = X.sw() - 1 end
    if a.px == "right" then mx = ax + w:getWidth() + 400 end
    if a.px == "zero" then mx = 0 end
    if a.py == "up" then my = ay - 400 end
    if a.py == "foot" then my = X.sh() - 1 end
    return mx, my
end
function X.rzVerify(k, a, label)
    local w, r = X.win(k), S.r
    local g = X.geo(w)
    local bad = {}
    if not r.done then bad[#bad + 1] = "the press never ran in the window's update" end
    if S.pressErr then bad[#bad + 1] = "error " .. S.pressErr end
    if X.offOne(w) then bad[#bad + 1] = "part of it off the screen" end
    if a.h == "min" then
        if r.minH and r.g1 and math.abs(r.g1.h - r.minH) > 1 then bad[#bad + 1] = "height " .. r.g1.h .. " at the press, least " .. tostring(r.minH) end
        if g.h < (w.minimumHeight or 0) - 1 or g.h > r.g0.h + 1 then bad[#bad + 1] = "height " .. g.h .. " (least " .. tostring(w.minimumHeight) .. ")" end
    end
    if a.h == "max" and (g.y + g.h < X.sh() - 2 or g.h < r.g0.h - 1) then bad[#bad + 1] = "foot at " .. (g.y + g.h) .. " of " .. X.sh() end
    if a.w == "min" then
        if r.minW and r.g1 and math.abs(r.g1.w - r.minW) > 1 then bad[#bad + 1] = "width " .. r.g1.w .. " at the press, least " .. tostring(r.minW) end
        if g.w < (w.minimumWidth or 0) - 1 or g.w > r.g0.w + 1 then bad[#bad + 1] = "width " .. g.w .. " (least " .. tostring(w.minimumWidth) .. ")" end
        local c = w._mainContent
        if not (c and c:isVisible()) then bad[#bad + 1] = "the list is gone" end
    end
    if a.w == "max" then
        local cap = w._maxWinW or math.floor(X.sw() / 2)
        if g.w > cap + 1 or g.w < r.g0.w - 1 then bad[#bad + 1] = "width " .. g.w .. " (half-screen cap " .. cap .. ")" end
    end
    if a.card then
        if w._activeTab ~= r.tab or math.floor(w._drawerEffW or 0) <= 0 then bad[#bad + 1] = "the card closed (tab " .. tostring(w._activeTab) .. ")" end
        if g.w < (w.minimumWidth or 0) - 1 then bad[#bad + 1] = "width " .. g.w .. " under the least " .. tostring(w.minimumWidth) end
    end
    if type(w._baseInvW) ~= "number" then bad[#bad + 1] = "the kept inventory width is " .. tostring(w._baseInvW) end
    Q.check(#bad == 0, label, X.gs(r.g0) .. " -> " .. X.gs(g) .. ((#bad > 0) and (": " .. table.concat(bad, "; ")) or ""))
    X.after(label)
end
function X.rzStep(k, a)
    local label = "resize: the " .. X.name(k) .. " window, " .. a.n
    Q.step(3, function()
        local w = X.win(k)
        S.r = { g0 = X.geo(w), minW = w.minimumWidth, minH = w.minimumHeight, tab = w._activeTab }
        S.r.mx, S.r.my = X.rzPoint(w, a)
        local mx, my = S.r.mx, S.r.my
        X.via(w, function(self)
            local ok, e = X.withMouse(mx, my, function() self:_startResize(a.mode); self:_resizeStep() end)
            if not ok then error(e) end
        end)
    end)
    Q.waitFor(1, 90, function() local w = X.win(k); return w ~= nil and w._qaPressDone == true end, function(ok)
        local w = X.win(k)
        S.r.done = ok
        S.r.g1 = X.geo(w)   -- (after the press and the engine's onResize)
        -- the pointer held there one more step, then the release
        if w._resizing then X.withMouse(S.r.mx, S.r.my, function() w:_resizeStep() end) end
        pcall(function() w:_stopResize() end)
    end)
    Q.step(8, function() X.rzVerify(k, a, label) end)
end
function X.partResize()
    X.fresh("2 resize")
    for _, k in ipairs(KS) do
        for _, a in ipairs(X.RZ) do
            X.rzStep(k, a)
            if a.use then
                X.usable("2 resize, the " .. X.name(k) .. " window at its smallest")
                X.tabStep("c", nil)
                X.tabStep("w", nil)
            end
        end
    end
    X.tabStep("c", { "health", "skills", "equip" })
    X.tabStep("w", { "maps", "craft", "forage" })
    for _, k in ipairs(KS) do
        for _, a in ipairs(X.RZ_CARD) do X.rzStep(k, a) end
    end
    X.usable("2 resize, after the resizes with cards open")
    X.partEnd("2 resize")
end

-- ===================================================================== 3. roll up and down
function X.dbl(w)
    local px, py = X.titlePt(w)
    w._lastTitleClick = nil
    w:onMouseDown(px, py); w:onMouseUp(px, py)
    w:onMouseDown(px, py); w:onMouseUp(px, py)
end
-- a double-click on window k's title bar, in its update; then wait until it is shaded (want) or down
function X.dblStep(k, want, fn)
    Q.step(3, function()
        local w = X.win(k)
        S.sh = S.sh or {}
        S.sh.before = X.geo(w)
        X.via(w, function(self) X.dbl(self) end)
    end)
    Q.waitFor(1, 120, function()
        local w = X.win(k)
        return w ~= nil and w._qaPressDone == true and (w.windowShaded and true or false) == want
    end, fn)
end
function X.shade(k)
    local name = "roll: the " .. X.name(k) .. " window"
    Q.step(2, function() S.sh = { g0 = X.geo(X.win(k)) } end)
    X.dblStep(k, true, function(ok)
        local w = X.win(k)
        local g = X.geo(w)
        local g0 = S.sh.g0
        local c = w._mainContent
        Q.check(ok and g.h == w:titleBarHeight() and g.x == g0.x and g.y == g0.y and g.w == g0.w and not (c and c:isVisible()),
            name .. ", a double-click on its title: rolled up to its title bar, in place, the list hidden",
            X.gs(g0) .. " -> " .. X.gs(g) .. ", rolled up " .. tostring(w.windowShaded) .. (S.pressErr and (", error " .. S.pressErr) or ""))
        local z = nil
        pcall(function() z = w:_resizeZoneAt(w:getWidth() - 2, w:getHeight() - 2) end)
        Q.check(z == nil, name .. ": rolled up, its corner starts no resize", tostring(z))
        X.after(name .. " rolled up")
    end)
    X.dblStep(k, false, function(ok)
        local w = X.win(k)
        local g = X.geo(w)
        local c = w._mainContent
        Q.check(ok and X.same(g, S.sh.g0, 0) and c ~= nil and c:isVisible(), name .. ", a double-click again: down, in the same box to the pixel, the list back",
            X.gs(S.sh.g0) .. " -> " .. X.gs(g))
        X.after(name .. " down again")
    end)
    -- parked at the screen's foot: rolled up there, the bar dragged to the very foot, then down
    Q.step(3, function() X.drag(X.win(k), 0, S.big, 3, false) end)
    Q.step(4, function() S.sh.g0 = X.geo(X.win(k)) end)
    X.dblStep(k, true, function(ok)
        if not ok then Q.check(false, name .. ": rolls up at the screen's foot") end
        X.drag(X.win(k), 0, S.big, 3, true)
    end)
    Q.step(6, function()
        local w = X.win(k)
        Q.check(X.atEdge(w, 0, 1) and not X.offOne(w), name .. ": rolled up, its bar drags to the very foot of the screen", X.gs(X.geo(w)))
        X.after(name .. " rolled up at the foot")
    end)
    X.dblStep(k, false, function(ok)
        local w = X.win(k)
        local g = X.geo(w)
        Q.check(ok and not X.offOne(w) and g.h == S.sh.g0.h, name .. ": brought down at the foot, the whole window is on screen at its height",
            X.gs(g) .. " (was " .. X.gs(S.sh.g0) .. ")")
        X.after(name .. " down at the foot")
    end)
end
-- a tab opened by its key's action on a rolled-up window: the window comes down on that tab
function X.shadeOpenTab(k)
    local name = "roll: the " .. X.name(k) .. " window"
    X.dblStep(k, true, function(ok)
        if not ok then Q.check(false, name .. ": rolls up before its tab key") end
        local id = X.pref(k, (k == "c") and { "health", "skills" } or { "craft", "maps" })
        S.sh.id = id
        local okT, e = false, "no tab"
        if id then
            if k == "c" then okT, e = pcall(ZeD_CharacterWindow.openTab, pn, id) else okT, e = pcall(ZeD_WorldWindow.openTab, pn, id) end
        end
        if not okT then Q.check(false, name .. ": the tab's key action runs on a rolled-up window", tostring(e)) end
        S.st[k] = nil
    end)
    Q.waitFor(2, 300, function()
        local w = X.win(k)
        return w ~= nil and not w.windowShaded and S.sh.id ~= nil and X.settled(k, S.sh.id)
    end, function(ok)
        local w = X.win(k)
        Q.check(ok, name .. ": rolled up, a tab's key action brings it down on that tab (" .. tostring(S.sh.id) .. ")",
            "rolled up " .. tostring(w and w.windowShaded) .. ", tab " .. tostring(w and w._activeTab))
        X.after(name .. " down by a tab's key")
    end)
end
-- a spot on the rod that is neither its close box, its pin nor its tab
function X.rodPt(rod)
    local y = math.floor(ZeD.T.titleBarH / 2)
    local function inR(r, x) return r ~= nil and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
    for x = rod:getWidth() - 3, 2, -3 do
        if not (inR(rod._closeRect, x) or inR(rod._pinRect, x) or inR(rod._chip, x)) then return x, y end
    end
    return nil
end
function X.rodDrag(w, dx, dy)
    local rod = w._rod
    if not rod then return false end
    local x, y = X.rodPt(rod)
    if not x then return false end
    pcall(rod.onMouseDown, rod, x, y)
    local grabbed = rod._dragging == true
    for _ = 1, 4 do pcall(rod.onMouseMove, rod, math.floor(dx / 4), math.floor(dy / 4)) end
    pcall(rod.onMouseUp, rod, x, y)
    return grabbed
end
function X.rodFlush(w)
    local rod = w._rod
    if not (w._rolled and rod and rod:isVisible()) then return false, "no rod showing" end
    local wantX = (w._curtain.side == "right") and (w:getX() + w:getWidth()) or (w:getX() - (w._rollW or 0))
    return rod:getX() == wantX and rod:getY() == w:getY(), "rod " .. rod:getX() .. "," .. rod:getY() .. ", want " .. wantX .. "," .. w:getY()
end
function X.rodCheck(k, label)
    Q.step(8, function()
        if S.cskip then return end
        local w = X.win(k)
        local flush, det = X.rodFlush(w)
        Q.check(S.cu.grabbed and flush and not X.offOne(w), label .. ": the window and its rod stay whole, together and on screen",
            X.gs(X.geo(w)) .. ", " .. det .. (S.cu.grabbed and "" or ", the rod did not take the press"))
        X.after(label)
    end)
end
function X.curtain(k)
    local name = "curtain: the " .. X.name(k) .. " window"
    X.tabStep(k, (k == "c") and { "skills", "health", "journal" } or { "maps", "forage", "craft" })
    Q.step(4, function()
        local w = X.win(k)
        S.cskip = nil
        S.cu = { box = X.geo(w) }
        local can = false
        pcall(function() can = w._curtain.canRoll() end)
        if not (S.tabIn and can) then S.cskip = "its side cannot roll on " .. tostring(S.tab[k]) .. " here"; return end
        X.via(w, function(self) ZeD.Curtain.roll(self) end)
    end)
    Q.waitFor(2, 400, function()
        if S.cskip then return true end
        local w = X.win(k)
        local rod = w and w._rod
        return w ~= nil and w._qaPressDone == true and w._rolled == true and rod ~= nil and rod._chip ~= nil
    end, function(ok)
        if S.cskip then Q.skip(name, S.cskip); return end
        local w = X.win(k)
        local g = X.geo(w)
        Q.check(ok and g.w == S.cu.box.w - (w._rollW or 0), name .. ": its side rolls up under a rod, the window narrower by the side",
            X.gs(S.cu.box) .. " less " .. tostring(w._rollW) .. " -> " .. X.gs(g) .. (S.pressErr and (", error " .. S.pressErr) or ""))
        -- the rod pulled far past the screen edge on its own side
        local dir = (w._curtain.side == "right") and 1 or -1
        S.cu.grabbed = X.rodDrag(w, dir * S.big, 0)
    end)
    X.rodCheck(k, name .. ", dragged by its rod past the edge on the rod's side")
    Q.step(2, function()
        if S.cskip then return end
        local w = X.win(k)
        local dir = (w._curtain.side == "right") and 1 or -1
        S.cu.grabbed = X.rodDrag(w, -dir * S.big, S.big)
    end)
    X.rodCheck(k, name .. ", dragged by its rod to the far bottom corner")
    -- rolled up whole while its side is rolled, and down again
    Q.step(3, function()
        if S.cskip then return end
        X.via(X.win(k), function(self) X.dbl(self) end)
    end)
    Q.waitFor(1, 120, function()
        if S.cskip then return true end
        local w = X.win(k)
        local rod = w and w._rod
        return w ~= nil and w.windowShaded == true and not (rod and rod:isVisible())
    end, function(ok)
        if S.cskip then return end
        local w = X.win(k)
        Q.check(ok, name .. ", a double-click while its side is rolled: the window rolls up and the rod leaves the screen",
            "rolled up " .. tostring(w.windowShaded) .. ", rod showing " .. tostring(w._rod ~= nil and w._rod:isVisible()))
        X.after(name .. " rolled up over a rolled side")
        X.via(w, function(self) X.dbl(self) end)
    end)
    Q.waitFor(1, 120, function() local w = X.win(k); return S.cskip ~= nil or (w ~= nil and not w.windowShaded) end, function(ok)
        if S.cskip then return end
        Q.check(ok, name .. ": a double-click again brings it down")
    end)
    Q.step(20, function()
        if S.cskip then return end
        local w = X.win(k)
        local okR, det = true, "side down"
        if w._rolled then okR, det = X.rodFlush(w) end
        Q.check(okR and not X.offOne(w), name .. ": down again, the side is down, or rolled with its rod beside it", det)
        X.after(name .. " down over a rolled side")
        S.cu.rg = X.geo(w)
        local rod = w._rod
        local c = rod and rod._chip
        if w._rolled and rod and c and rod:isVisible() then
            X.via(rod, function(self) self:onMouseDown(c.x + 2, c.y + 2); self:onMouseUp(c.x + 2, c.y + 2) end)
        elseif w._rolled then
            pcall(ZeD.Curtain.unroll, w)
        end
    end)
    Q.waitFor(2, 600, function() local w = X.win(k); return S.cskip ~= nil or (w ~= nil and not w._rolled) end, function(ok)
        if S.cskip then return end
        local w = X.win(k)
        local g = X.geo(w)
        Q.check(ok and math.abs(g.w - S.cu.box.w) <= 1 and g.h == S.cu.box.h and not X.offOne(w) and not (w._rod and w._rod:isVisible()),
            name .. ": the rod's tab pressed, the side is back, the window its old size and on screen, the rod gone",
            X.gs(S.cu.box) .. " -> " .. X.gs(g) .. ", rolled " .. tostring(w._rolled))
        X.after(name .. " unrolled")
    end)
    X.tabStep(k, nil)
end
function X.partRoll()
    X.fresh("3 roll")
    for _, k in ipairs(KS) do X.shade(k) end
    X.usable("3 roll, after the roll-ups")
    for _, k in ipairs(KS) do X.shadeOpenTab(k) end
    X.fresh("3 roll, the curtains")
    for _, k in ipairs(KS) do X.curtain(k) end
    X.usable("3 roll, after the curtains")
    X.partEnd("3 roll")
end

-- ===================================================================== 4. pins
function X.pinSaved(k, half)
    local md = nil
    pcall(function() md = RT.p:getModData().ZeD_WinPinned end)
    if not md then return nil end
    local key = (k == "c") and "char" or "world"
    if half == "inv" then return md[key .. "Inv"] end
    if half == "drawer" then return md[key .. "Tabs"] end
    return md[key]
end
-- a pin pressed through the title bar's own path (the release asks update for it), then pressed back
function X.pinStep(k, half)
    local label = "pins: the " .. X.name(k) .. " window's " .. ((half == "both") and "joined pin" or (half .. " pin"))
    Q.step(2, function()
        local w = X.win(k)
        S.p = { was = ZeD.Halves.isPinned(w, half) and true or false }
        w._boxDo = "pin:" .. half
    end)
    Q.waitFor(1, 90, function()
        local w = X.win(k)
        return w ~= nil and (ZeD.Halves.isPinned(w, half) and true or false) ~= S.p.was
    end, function(ok)
        local w = X.win(k)
        local now = ZeD.Halves.isPinned(w, half) and true or false
        local saved = X.pinSaved(k, half)
        Q.check(ok and saved ~= nil and (saved and true or false) == now, label .. ": pressed, it flips and the character keeps it",
            tostring(S.p.was) .. " -> " .. tostring(now) .. ", kept " .. tostring(saved))
        local okT, e = pcall(ZeD.Halves.togglePin, w, half)
        local back = ZeD.Halves.isPinned(w, half) and true or false
        Q.check(okT and back == S.p.was and (X.pinSaved(k, half) and true or false) == back, label .. ": pressed again, it is back",
            tostring(back) .. (okT and "" or (", error " .. tostring(e))))
        X.after(label)
    end)
end
function X.pinBurst(k)
    Q.step(3, function()
        local w, H = X.win(k), ZeD.Halves
        local label = "pins: the " .. X.name(k) .. " window, each pin pressed 21 times in one frame"
        local okAll, err = true, nil
        for _ = 1, 21 do
            for _, half in ipairs({ "inv", "drawer" }) do
                local ok, e = pcall(H.togglePin, w, half)
                if not ok then okAll, err = false, e end
            end
        end
        local i, d = H.isPinned(w, "inv") and true or false, H.isPinned(w, "drawer") and true or false
        Q.check(okAll and i == false and d == false and X.pinSaved(k, "inv") == false and X.pinSaved(k, "drawer") == false and X.pinSaved(k, "both") == false,
            label .. ": both end unpinned, and so the character keeps them",
            "inv " .. tostring(i) .. ", drawer " .. tostring(d) .. (err and (", error " .. tostring(err)) or ""))
        pcall(H.setPin, w, nil, true)
        Q.check(H.isPinned(w, "both") == true and X.pinSaved(k, "both") == true, label .. ": pinned again, both halves pinned")
        X.after(label)
    end)
end
-- time on the clock (the halves' timers), never past ms
function X.waitUntil(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 100000, function()
        st.t = st.t or getTimestampMs()
        if getTimestampMs() - st.t >= ms then return true end
        return cond()
    end, function()
        local ok, r = pcall(cond)
        fn((ok and r) and true or false)
    end)
end
function X.autoRoll()
    Q.step(3, function()
        S.ar = { pad = JoypadState ~= nil and JoypadState.players ~= nil and JoypadState.players[pn + 1] ~= nil }
        if S.ar.pad then Q.skip("pins: unpinned windows roll up by themselves", "a controller is connected: the game pins its windows for a pad"); return end
        if isMouseButtonDown(0) or isMouseButtonDown(1) then
            S.ar.pad = true
            Q.skip("pins: unpinned windows roll up by themselves", "a mouse button is held down: the timers wait for it")
            return
        end
        S.ar.tab = S.tab.c
        -- the pointer at the screen's bottom left, clear of both windows at the default spread; all four halves unpinned
        X.pointer(2, X.sh() - 2)
        for _, k in ipairs(KS) do pcall(ZeD.Halves.setPin, X.win(k), nil, false) end
    end)
    X.waitUntil(6000, function()
        if S.ar.pad then return true end
        local c, w = RT.cw(), RT.ww()
        return c ~= nil and w ~= nil and c.windowShaded == true and w.windowShaded == true
    end, function(ok)
        if S.ar.pad then return end
        local c, w = RT.cw(), RT.ww()
        Q.check(ok, "pins: all unpinned and the pointer away, both windows roll up by themselves (2 s)",
            "Character " .. tostring(c and c.windowShaded) .. ", World " .. tostring(w and w.windowShaded))
        X.after("pins: both windows rolled up by themselves")
        -- the pointer rests on the inventory's part of the Character window's rolled bar
        if c then X.pointer(c:getAbsoluteX() + math.floor(c:getWidth() * 0.6), c:getAbsoluteY() + math.floor(c:titleBarHeight() / 2)) end
    end)
    X.waitUntil(4000, function()
        if S.ar.pad then return true end
        local c = RT.cw()
        return c ~= nil and not c.windowShaded
    end, function(ok)
        if S.ar.pad then return end
        local c, w = RT.cw(), RT.ww()
        local fold = c and ZeD.Halves.foldedTab(c)
        Q.check(ok and c ~= nil and (fold or c._activeTab) == S.ar.tab and w ~= nil and w.windowShaded == true,
            "pins: the pointer resting on the Character window's rolled bar brings it down, still on its tab; the World window stays up",
            "Character rolled up " .. tostring(c and c.windowShaded) .. ", tab " .. tostring(c and c._activeTab) .. ", folded " .. tostring(fold)
                .. ", World rolled up " .. tostring(w and w.windowShaded))
        X.after("pins: the Character window brought down by the pointer")
        X.pinAll()
    end)
    X.waitUntil(4000, function()
        if S.ar.pad then return true end
        local c, w = RT.cw(), RT.ww()
        return c ~= nil and w ~= nil and not c.windowShaded and not w.windowShaded and not ZeD.Halves.anyRolled(c) and not ZeD.Halves.anyRolled(w)
    end, function(ok)
        X.pointer(nil)
        if S.ar.pad then return end
        local c, w = RT.cw(), RT.ww()
        Q.check(ok, "pins: pinned again, every half that rolled by itself comes back on both windows",
            "Character rolled up " .. tostring(c and c.windowShaded) .. ", World rolled up " .. tostring(w and w.windowShaded))
        X.after("pins: everything back after pinning")
    end)
end
function X.partPins()
    X.fresh("4 pins")
    X.tabStep("c", { "skills", "health", "equip" })
    for _, k in ipairs(KS) do
        for _, half in ipairs({ "inv", "drawer", "both" }) do X.pinStep(k, half) end
        X.pinBurst(k)
    end
    X.autoRoll()
    X.usable("4 pins")
    X.partEnd("4 pins")
end

-- ===================================================================== 5. the window box's menu
function X.rows(w)
    local items = {}
    pcall(function() items = ZeD.WindowMenu.build(w) end)
    return items
end
function X.row(w, key)
    local name = ZeD.tr(key)
    for _, it in ipairs(X.rows(w)) do if it.name == name then return it end end
    return nil
end
function X.menuOpen()
    local m = ZeD.WindowMenu and ZeD.WindowMenu.current
    return m ~= nil and m._ctx ~= nil and m._ctx.open == true, m
end
-- the menu pulled down with the window at a screen corner; one menu at a time; left behind by a closed window
function X.menuBasics()
    Q.step(3, function()
        X.drag(RT.cw(), S.big, S.big, 3, false)      -- Character: bottom right
        X.drag(RT.ww(), -S.big, S.big, 3, false)     -- World: bottom left
    end)
    for _, k in ipairs(KS) do
        Q.step(6, function() X.win(k)._boxDo = "menu" end)
        Q.waitFor(1, 90, function() local on, m = X.menuOpen(); return on and m.win == X.win(k) end, function(ok)
            local w = X.win(k)
            local _, m = X.menuOpen()
            Q.check(ok and w._wboxOpen == true, "menu: the " .. X.name(k) .. " window's box pulls its menu down (the window in a bottom corner)",
                "menu " .. tostring(m ~= nil) .. ", box open " .. tostring(w._wboxOpen))
            if k == "w" then
                local c = RT.cw()
                Q.check(c._wboxOpen == nil, "menu: one menu at a time, the Character window's shut when the World's opened", tostring(c._wboxOpen))
            end
        end)
        Q.step(6, function() X.after("menu: the " .. X.name(k) .. " window's menu, the window in a bottom corner") end)
    end
    Q.step(3, function()
        local _, m = X.menuOpen()
        if m then pcall(function() m:close() end) end
        local on = X.menuOpen()
        Q.check(not on and RT.ww()._wboxOpen == nil, "menu: it closes", "box open " .. tostring(RT.ww()._wboxOpen))
        RT.cw()._boxDo = "menu"
    end)
    Q.waitFor(1, 90, function() return (X.menuOpen()) end, function(ok)
        local _, m = X.menuOpen()
        S.orph = ok and m or nil
        if not ok then Q.check(false, "menu: opens again before the windows close") end
        X.toggle()
    end)
    Q.waitFor(2, 240, X.bothShut, function(ok)
        if not ok then Q.check(false, "menu: the pair closes with a menu open") end
    end)
    Q.step(8, function()
        local m = S.orph
        if m then
            local left = m._ctx ~= nil and m._ctx.open == true
            Q.check(not left, "menu: the windows closed (the inventory key) while a menu was down, the menu goes with its window",
                left and "the menu is still open, its window gone" or "closed")
            if left then
                local it = nil
                for _, a in ipairs(m._ctx.actions or {}) do if a.name == ZeD.tr("UI_ZeD_WinMenu_ResetThis") then it = a end end
                local ok, e = true, nil
                if it then ok, e = pcall(it.onFire) end
                Q.check(ok, "menu: a row of the menu left behind (Reset this window) runs without an error", tostring(e))
                pcall(function() m:close() end)
            end
        end
        X.toggle()
    end)
    Q.waitFor(2, 240, X.bothOpen, function(ok)
        if not ok then Q.check(false, "menu: the pair opens again") end
        X.pinAll()
        X.after("menu: the pair open again")
    end)
end
-- every choice of one submenu fired through its own row, then the one in use put back
function X.subWalk(k, key, maxN, optional)
    Q.step(3, function()
        S.sub = nil
        local it = X.row(X.win(k), key)
        if not (it and it.children) then
            if optional then Q.skip("menu: " .. key, "this build's menu has no such row") else Q.check(false, "menu: the row " .. key .. " and its choices") end
            return
        end
        local orig = nil
        for i, c in ipairs(it.children) do
            local ok, on = pcall(c.checked)
            if ok and on and not orig then orig = i end
        end
        local dis = false
        if it.disabled then pcall(function() dis = it.disabled() and true or false end) end
        S.sub = { it = it, orig = orig, n = #it.children, bad = {}, off = {}, fired = 0, dis = dis }
        S.fired[#S.fired + 1] = tostring(it.name) .. " (" .. #it.children .. ")"
    end)
    for i = 1, maxN do
        Q.step(2, function()
            local s = S.sub
            local c = s and s.it.children[i]
            if not c then return end
            local ok, e = pcall(c.onFire)
            s.fired = s.fired + 1
            if not ok then s.bad[#s.bad + 1] = tostring(c.name) .. ": " .. tostring(e) end
        end)
        Q.step(4, function()
            local s = S.sub
            local c = s and s.it.children[i]
            if not c then return end
            local ok, on = pcall(c.checked)
            if not (ok and on) then s.bad[#s.bad + 1] = tostring(c.name) .. ": no check mark after it was picked" end
            if not X.bothOpen() then s.bad[#s.bad + 1] = tostring(c.name) .. ": a window closed" end
            local off = X.off()
            if #off > 0 then s.off[#s.off + 1] = tostring(c.name) .. ": " .. table.concat(off, ", ") end
        end)
    end
    Q.step(2, function()
        local s = S.sub
        if not s then return end
        local label = "menu: the " .. X.name(k) .. " window, " .. tostring(s.it.name)
        Q.check(s.fired == s.n and #s.bad == 0, label .. ": every choice picked takes the check mark, no error (" .. s.n .. " choices)",
            (#s.bad > 0) and table.concat(s.bad, "; ") or ((s.fired ~= s.n) and (s.fired .. " of " .. s.n .. " walked") or (s.dis and "the row is greyed here" or nil)))
        Q.check(#s.off == 0, label .. ": after every choice every ZeD window is on screen", table.concat(s.off, "; "))
        local back = s.orig and s.it.children[s.orig]
        if back then pcall(back.onFire) end
    end)
    Q.step(6, function()
        local s = S.sub
        if not s then return end
        local label = "menu: the " .. X.name(k) .. " window, " .. tostring(s.it.name)
        local back = s.orig and s.it.children[s.orig]
        if back then
            local ok, on = pcall(back.checked)
            Q.check(ok and on, label .. ": the choice it had is picked again", tostring(back.name))
        end
        X.after(label .. ", the choice it had put back")
    end)
end
function X.spreadOk(k)
    local w, T = X.win(k), ZeD.T
    local sw, _, sl, st = ZeD.screenOf(w)
    local mid = sl + math.floor(sw / 2)
    if k == "c" then
        local right = w:getX() + w:getWidth()
        return math.abs(right - (mid - T.px(5))) <= 1 and math.abs(w:getY() - st) <= 1, "right edge " .. right .. " (want " .. (mid - T.px(5)) .. "), y " .. w:getY()
    end
    return math.abs(w:getX() - (mid + T.px(5))) <= 1 and math.abs(w:getY() - st) <= 1, "x " .. w:getX() .. " (want " .. (mid + T.px(5)) .. "), y " .. w:getY()
end
-- Reset this window; Go to saved position greyed; Save position at a corner; Go to saved position
function X.placeRows(k)
    local name = "menu: the " .. X.name(k) .. " window"
    local pk = (k == "c") and "char" or "world"
    Q.step(4, function()
        local w = X.win(k)
        X.drag(w, ((k == "c") and -1 or 1) * S.big, S.big, 2, false)
        local it = X.row(w, "UI_ZeD_WinMenu_ResetThis")
        S.pr = { ok = it ~= nil }
        if not it then Q.check(false, name .. ": has Reset this window"); return end
        S.fired[#S.fired + 1] = tostring(it.name)
        local ok, e = pcall(it.onFire)
        if not ok then Q.check(false, name .. ", Reset this window: runs without an error", tostring(e)) end
    end)
    Q.step(10, function()
        if not S.pr.ok then return end
        local w = X.win(k)
        local ok, det = X.spreadOk(k)
        Q.check(ok and w._activeTab == "loot" and not w._rolled, name .. ", Reset this window from a bottom corner: back in the spread, on Loot",
            det .. ", tab " .. tostring(w._activeTab))
        X.after(name .. ", Reset this window")
        -- nothing saved (in memory only: the file is read again right after): Go to saved position is greyed
        local WP = ZeD.WindowPlaces
        local pl = WP.load()
        pl[pk] = nil
        local go = X.row(w, "UI_ZeD_WinMenu_GoSaved")
        local dis, state = nil, nil
        if go then pcall(function() dis, state = go.disabled(), go.state() end) end
        Q.check(go ~= nil and dis == true and state == ZeD.tr("UI_ZeD_WinMenu_NoSaved"), name .. ": with nothing saved, Go to saved position is greyed and says why",
            "greyed " .. tostring(dis) .. ", '" .. tostring(state) .. "'")
        WP.places = nil
        X.drag(w, ((k == "c") and -1 or 1) * S.big, S.big, 2, false)   -- to a bottom corner, then saved there
    end)
    Q.step(8, function()
        if not S.pr.ok then return end
        local w, WP = X.win(k), ZeD.WindowPlaces
        local it = X.row(w, "UI_ZeD_WinMenu_SavePos")
        if not it then Q.check(false, name .. ": has Save position"); S.pr.ok = false; return end
        S.fired[#S.fired + 1] = tostring(it.name)
        S.wpTouched = true
        local M = ZeD.Messages
        local said, old = false, M and M.notice
        if M then M.notice = function() said = true end end   -- (its Messages note counted, not posted)
        local ok, e = pcall(it.onFire)
        if M then M.notice = old end
        local rec = WP.load()[pk]
        Q.check(ok and rec ~= nil and said, name .. ", Save position at a bottom corner: its place is in the file, and a note says so",
            (rec and ("x " .. tostring(rec.x) .. " y " .. tostring(rec.y)) or "nothing in the file") .. (ok and "" or (", error " .. tostring(e))))
        S.pr.geo = X.geo(w)
        pcall(function() ZeD_Window.resetLayout(pk, pn) end)
    end)
    Q.step(10, function()
        if not S.pr.ok then return end
        local w = X.win(k)
        local it = X.row(w, "UI_ZeD_WinMenu_GoSaved")
        local dis = true
        if it then pcall(function() dis = it.disabled() end) end
        if not (it and dis == false) then Q.check(false, name .. ": with a place saved, Go to saved position is live", "greyed " .. tostring(dis)); S.pr.ok = false; return end
        S.fired[#S.fired + 1] = tostring(it.name)
        local ok, e = pcall(it.onFire)
        if not ok then Q.check(false, name .. ", Go to saved position: runs without an error", tostring(e)) end
    end)
    Q.step(12, function()
        if not S.pr.ok then return end
        local w = X.win(k)
        local g = X.geo(w)
        Q.check(X.same(g, S.pr.geo, 2), name .. ", Go to saved position: back in the bottom corner it was saved in", X.gs(S.pr.geo) .. " -> " .. X.gs(g))
        X.after(name .. ", Go to saved position")
    end)
    -- (Nov 21 2026, QA B9-2) left in that corner, with no menu at all: the inventory key closes both windows and opens
    -- them again, and this one comes back as it was (on a small screen the restore narrows it again, its edge kept)
    Q.step(2, function()
        if not S.pr.ok then return end
        S.pr.geo2 = X.geo(X.win(k))
        local ok, e = X.toggle()
        if not ok then Q.check(false, name .. ", left in the corner: the inventory key closes the windows without an error", tostring(e)); S.pr.ok = false end
    end)
    Q.waitFor(1, 90, X.bothShut, function(ok)
        if not S.pr.ok then return end
        if not ok then Q.check(false, name .. ", left in the corner: the inventory key closes both windows", "still open after 90 frames"); S.pr.ok = false; return end
        local ok2, e2 = X.toggle()
        if not ok2 then Q.check(false, name .. ", left in the corner: the inventory key opens the windows again without an error", tostring(e2)); S.pr.ok = false end
    end)
    Q.waitFor(1, 90, X.bothOpen, function(ok)
        if not S.pr.ok then return end
        if not ok then Q.check(false, name .. ", left in the corner: the inventory key opens both windows again", "not both open after 90 frames"); S.pr.ok = false end
    end)
    Q.step(12, function()
        if not S.pr.ok then return end
        local g = X.geo(X.win(k))
        Q.check(X.same(g, S.pr.geo2, 2), name .. ", left in the bottom corner, closed and opened again: the same place and width", X.gs(S.pr.geo2) .. " -> " .. X.gs(g))
        X.after(name .. ", closed and opened again in the corner")
    end)
end
-- the rows below the line: Bug report, the keyboard map, the controller map, Hide interface; ZeD setup said, not pressed
function X.setupRows()
    -- Bug report: its box caught as it is made (ZeD's prompt, built through ISModalDialog.new) and closed; the clipboard
    -- and Messages put back. A clipboard that cannot be read back is left alone (as rt_system does).
    Q.step(4, function()
        local MS = ZeD.Messages
        local it = (MS and MS.copyBugReport) and X.row(RT.cw(), "UI_ZeD_Msg_BugReport") or nil
        if not it then Q.skip("menu: Bug report", "this build's menu has no such row"); return end
        local clip = nil
        pcall(function() clip = Clipboard.getClipboard() end)
        if clip == nil then Q.skip("menu: Bug report", "the clipboard cannot be read back here, so the test leaves it alone"); return end
        S.fired[#S.fired + 1] = tostring(it.name)
        local src0 = {}
        for name in pairs(MS.sources or {}) do src0[name] = true end
        local newWas, box = ISModalDialog.new, nil
        ISModalDialog.new = function(self, ...)
            local o = newWas(self, ...)
            box = o
            return o
        end
        local ok, e = pcall(it.onFire)
        ISModalDialog.new = newWas
        Q.check(ok and box ~= nil, "menu: Bug report runs and says so in a box", ok and ("box " .. tostring(box ~= nil)) or ("error " .. tostring(e)))
        pcall(function() Clipboard.setClipboard(clip) end)
        pcall(function() if box then box:destroy() end end)
        pcall(function() if box and box:isVisible() then box:setVisible(false); box:removeFromUIManager() end end)
        local fresh = {}
        for name in pairs(MS.sources or {}) do if not src0[name] then fresh[#fresh + 1] = name end end
        for _, name in ipairs(fresh) do pcall(MS.clear, name) end
    end)
    Q.step(8, function()
        if getGameSpeed() ~= 1 then pcall(setGameSpeed, 1) end
        X.after("menu: after Bug report")
    end)
    Q.step(4, function()
        local KM = ZeD.KeyboardMap
        local it = (KM and KM.open) and X.row(RT.cw(), "UI_ZeD_KMap_Title") or nil
        S.km = nil
        if not it then Q.skip("menu: the keyboard map", "this build's menu has no such row"); return end
        S.fired[#S.fired + 1] = tostring(it.name)
        local ok, e = pcall(it.onFire)
        S.km = { ok = ok, e = e }
    end)
    Q.step(8, function()
        if not S.km then return end
        local KM = ZeD.KeyboardMap
        local win = KM.windows and KM.windows[pn]
        local up = win ~= nil and win:isReallyVisible()
        Q.check(S.km.ok and up, "menu: the keyboard map opens", S.km.ok and "" or ("error " .. tostring(S.km.e)))
        X.after("menu: the keyboard map")
        pcall(KM.close, pn)
        Q.check(not (win ~= nil and win:isReallyVisible()), "menu: the keyboard map closes")
    end)
    Q.step(4, function()
        local CM = ZeD.ControllerMap
        local it = X.row(RT.cw(), "UI_ZeD_Wheel_ControllerMap")
        if not (CM and it) then Q.skip("menu: the controller map", "the row shows only with a controller connected"); return end
        S.fired[#S.fired + 1] = tostring(it.name)
        local ok, e = pcall(it.onFire)
        Q.check(ok, "menu: the controller map opens without an error", tostring(e))
        X.after("menu: the controller map")
        pcall(CM.close, pn)
    end)
    -- Hide interface and back within one frame (this script is driven by the interface's own draw)
    Q.step(6, function()
        local WH = ZeD.DpadWheels and ZeD.DpadWheels.H
        local it = (WH and WH.hideInterface) and X.row(RT.cw(), "UI_ZeD_Wheel_HideInterface") or nil
        if not it then Q.skip("menu: Hide interface", "this build's menu has no such row"); return end
        if ISUIHandler.allUIVisible == false then Q.skip("menu: Hide interface", "the interface is already hidden"); return end
        S.fired[#S.fired + 1] = tostring(it.name)
        local c, w = RT.cw(), RT.ww()
        local ok1, e1 = pcall(it.onFire)
        local hidC, hidW = not c:isVisible(), not w:isVisible()
        local ok2, e2 = true, nil
        if ISUIHandler.allUIVisible == false then ok2, e2 = pcall(it.onFire) end
        Q.check(ok1 and ok2 and hidC and hidW and ISUIHandler.allUIVisible == true and c:isVisible() and w:isVisible(),
            "menu: Hide interface hides both windows, and the same again shows both",
            "hidden " .. tostring(hidC) .. " / " .. tostring(hidW) .. ", back " .. tostring(c:isVisible()) .. " / " .. tostring(w:isVisible())
                .. ((ok1 and ok2) and "" or (", error " .. tostring(e1 or e2))))
    end)
    Q.step(6, function()
        X.after("menu: after Hide interface and back")
        local it = X.row(RT.cw(), "UI_ZeD_WinMenu_Setup")
        Q.check(it ~= nil and type(it.onFire) == "function", "menu: has ZeD setup")
        Q.skip("menu: ZeD setup pressed", "it opens the pause screen; left up it would stop the scripts after this one")
        -- every row this build's menu has, and the ones this script pressed
        local names = {}
        for _, r in ipairs(X.rows(RT.cw())) do names[#names + 1] = tostring(r.name) end
        Q.say("menu rows (Character): " .. table.concat(names, " / "))
        Q.say("rows pressed: " .. table.concat(S.fired, " / "))
    end)
end
function X.partMenu()
    X.fresh("5 menu")
    X.menuBasics()
    X.fresh("5 menu, the choices")
    X.tabStep("c", { "skills", "health", "equip" })
    X.tabStep("w", { "craft", "maps", "forage" })
    X.subWalk("c", "UI_ZeD_WinMenu_Theme", 5, false)
    X.subWalk("c", "UI_ZeD_WinMenu_Accent", 14, false)
    X.subWalk("w", "UI_ZeD_WinMenu_Accent", 14, false)
    X.subWalk("c", "UI_ZeD_Settings_TextSize", 5, false)
    X.usable("5 menu, after the text sizes")
    X.subWalk("w", "UI_ZeD_Settings_SeeThrough", 8, true)
    X.subWalk("w", "UI_ZeD_Settings_FocusStyle", 8, true)
    X.fresh("5 menu, the rows")
    for _, k in ipairs(KS) do X.placeRows(k) end
    X.setupRows()
    X.usable("5 menu")
    X.partEnd("5 menu")
end

-- ===================================================================== 6. Reset both windows out of a mess
function X.partReset()
    X.fresh("6 reset")
    X.tabStep("c", { "skills", "health", "equip" })
    X.tabStep("w", { "maps", "forage", "craft" })
    -- the Character window: to the bottom right, as small as it goes, then rolled up
    Q.step(3, function() X.drag(RT.cw(), S.big, S.big, 3, false) end)
    X.rzStep("c", X.RZ_CARD[1])
    X.dblStep("c", true, function(ok)
        if not ok then Q.check(false, "reset: the Character window rolls up for the mess") end
    end)
    -- the World window: its side rolled, dragged by the rod to the top left
    Q.step(3, function()
        local w = RT.ww()
        S.rs = { rolled = false }
        local can = false
        pcall(function() can = w._curtain.canRoll() end)
        if can then X.via(w, function(self) ZeD.Curtain.roll(self) end) end
        S.rs.can = can
    end)
    Q.waitFor(2, 300, function() local w = RT.ww(); return (not S.rs.can) or (w._rolled == true and w._rod ~= nil and w._rod._chip ~= nil) end, function()
        local w = RT.ww()
        if w._rolled then X.rodDrag(w, -S.big, -S.big) else X.drag(w, -S.big, -S.big, 2, false) end
    end)
    Q.step(8, function()
        X.after("reset: the mess before it")
        local it = X.row(RT.cw(), "UI_ZeD_WinMenu_ResetBoth")
        S.rs.ok = it ~= nil
        if not it then Q.check(false, "reset: the Character window's menu has Reset both windows"); return end
        S.fired[#S.fired + 1] = tostring(it.name)
        S.rs.wasShaded = RT.cw().windowShaded and true or false
        local ok, e = pcall(it.onFire)
        if not ok then Q.check(false, "reset: Reset both windows runs without an error", tostring(e)) end
    end)
    Q.step(12, function()
        if not S.rs.ok then return end
        local c, w = RT.cw(), RT.ww()
        local okC, detC = X.spreadOk("c")
        local okW, detW = X.spreadOk("w")
        Q.check(okC and c._activeTab == "loot" and not c._rolled, "reset: out of the mess, the Character window is back in the spread, on Loot",
            detC .. ", tab " .. tostring(c._activeTab))
        Q.check(okW and w._activeTab == "loot" and not w._rolled and not (w._rod and w._rod:isVisible()),
            "reset: the World window is back in the spread, on Loot, its side down and its rod gone", detW .. ", tab " .. tostring(w._activeTab) .. ", rolled " .. tostring(w._rolled))
        Q.check(c:getWidth() == w:getWidth(), "reset: both windows are the same width", c:getWidth() .. " and " .. w:getWidth())
        X.after("reset: after Reset both windows")
        S.rs.stillShaded = c.windowShaded and true or false
        if S.rs.stillShaded then X.via(c, function(self) X.dbl(self) end) end
    end)
    Q.waitFor(2, 120, function() local c = RT.cw(); return c ~= nil and not c.windowShaded end, function(ok)
        if not S.rs.ok then return end
        local c, w = RT.cw(), RT.ww()
        Q.check(ok and c:getHeight() == w:getHeight(),
            "reset: the Character window was rolled up when both were reset; down again it has the reset's height, as the World window",
            "Character " .. c:getHeight() .. ", World " .. w:getHeight() .. (S.rs.stillShaded and ", it stayed rolled up through the reset" or ", the reset brought it down"))
        X.after("reset: the Character window down after the reset")
    end)
    X.usable("6 reset")
    X.partEnd("6 reset")
end

-- ===================================================================== 7. one window on top of the other
function X.zOf(el)
    local at = nil
    for i, r in ipairs(RT.roots()) do if r.t == el then at = i end end
    return at
end
function X.pressTitle(w)
    local px, py = X.titlePt(w)
    w._lastTitleClick = nil
    pcall(w.onMouseDown, w, px, py)
    pcall(w.onMouseUp, w, px, py)
    w._lastTitleClick = nil
end
function X.topStep(k)
    local o = (k == "c") and "w" or "c"
    Q.step(4, function() X.pressTitle(X.win(k)) end)
    Q.waitFor(1, 90, function()
        local a, b = X.zOf(X.win(k)), X.zOf(X.win(o))
        return a ~= nil and b ~= nil and a > b
    end, function(ok)
        Q.check(ok, "overlap: the " .. X.name(k) .. " window pressed is drawn above the " .. X.name(o) .. " window",
            tostring(X.zOf(X.win(k))) .. " and " .. tostring(X.zOf(X.win(o))) .. " in the draw order")
    end)
end
function X.partOverlap()
    X.fresh("7 overlap")
    Q.step(3, function()
        local c, w = RT.cw(), RT.ww()
        X.drag(w, c:getX() - w:getX() + ZeD.T.px(20), ZeD.T.px(20), 2, false)   -- the World window onto the Character window
    end)
    Q.step(6, function()
        local c, w = RT.cw(), RT.ww()
        local over = w:getX() < c:getX() + c:getWidth() and c:getX() < w:getX() + w:getWidth()
        Q.check(over, "overlap: the World window dragged onto the Character window", X.gs(X.geo(c)) .. " and " .. X.gs(X.geo(w)))
        X.after("overlap: one window on the other")
    end)
    X.topStep("c")
    X.topStep("w")
    X.topStep("c")
    Q.step(3, function() RT.ww()._boxDo = "menu" end)
    Q.waitFor(1, 120, function()
        local on, m = X.menuOpen()
        if not on then return false end
        local a, b, c = X.zOf(m), X.zOf(RT.cw()), X.zOf(RT.ww())
        return a ~= nil and b ~= nil and c ~= nil and a > b and a > c
    end, function(ok)
        local on, m = X.menuOpen()
        Q.check(ok, "overlap: the lower window's menu is drawn above both windows", "menu open " .. tostring(on))
        X.after("overlap: the menu over both windows")
        if m then pcall(function() m:close() end) end
    end)
    X.usable("7 overlap, cards opening over each other")
    X.usable("7 overlap, again")
    Q.step(3, function()
        -- ten tab presses in one frame, the two windows by turns
        local bad = nil
        for i = 1, 10 do
            local k = (X.mod(i, 2) == 0) and "c" or "w"
            local id = X.pick(k)
            local ok, e = true, nil
            if id then ok, e = pcall(X.press, k, id) end
            if not ok then bad = tostring(e) end
        end
        Q.check(bad == nil, "overlap: ten tab presses in one frame, the two windows by turns, no error", bad)
        S.st = {}
    end)
    Q.waitFor(4, 400, function()
        local c, w = RT.cw(), RT.ww()
        return c ~= nil and w ~= nil and X.settled("c", c._activeTab) and X.settled("w", w._activeTab)
    end, function(ok)
        Q.check(ok, "overlap: after the burst both drawers come to rest")
        X.after("overlap: after ten tab presses in one frame")
    end)
    X.partEnd("7 overlap")
end

-- ===================================================================== 8. closed and opened 50 times
function X.loopCheck(i)
    Q.step(12, function()
        local L = S.loop
        local nc, nw = X.countWins()
        local rods = X.strayRods()
        Q.check(X.bothOpen() and nc == 1 and nw == 1 and rods == 0, "50 times: after " .. i .. ", one Character and one World window, no rod left behind",
            nc .. " Character, " .. nw .. " World, " .. rods .. " stray rod(s)")
        X.after("50 times: after " .. i)
        Q.say("50 times: after " .. i .. ": " .. L.stuck .. " slow closes, " .. L.late .. " slow opens, " .. L.tabs .. " tabs picked")
    end)
end
function X.cycle(i)
    Q.step(1, function()
        local L = S.loop
        if not X.bothOpen() then L.late = L.late + 1; return end
        local m = X.mod(i, 5)
        local c, w = RT.cw(), RT.ww()
        local ok, e = true, nil
        if m == 1 then ok, e = pcall(function() c:close(); w:close() end)                     -- both close boxes
        elseif m == 2 then c._boxDo = "close"; w._boxDo = "close"                              -- the close boxes' own path (update)
        elseif m == 3 then ok, e = pcall(function() ZeD_WorldWindow.forceClose(pn); ZeD_CharacterWindow.toggle(pn) end)
        elseif m == 4 then ok, e = pcall(function() w:close(); ZeD_CharacterWindow.toggleBothPaired(pn); ZeD_CharacterWindow.toggleBothPaired(pn) end)
        else ok, e = X.toggle() end                                                            -- the inventory key
        if not ok then L.errs[#L.errs + 1] = "close " .. i .. ": " .. tostring(e) end
    end)
    Q.waitFor(1, 90, X.bothShut, function(ok)
        local L = S.loop
        if ok then return end
        L.stuck = L.stuck + 1
        L.errs[#L.errs + 1] = "close " .. i .. " (way " .. X.mod(i, 5) .. "): still open after 90 frames"
        pcall(ZeD_WorldWindow.forceClose, pn)
        if RT.isOpen() then pcall(ZeD_CharacterWindow.toggle, pn) end
    end)
    Q.step(1, function()
        local L = S.loop
        local ok, e = X.toggle()
        if not ok then L.errs[#L.errs + 1] = "open " .. i .. ": " .. tostring(e) end
        if X.mod(i, 2) == 0 then
            -- a tab by its key's action in the same frame the windows open (it presses the strip once it is drawn)
            local idc = S.tabs.c[X.mod(i, #S.tabs.c) + 1]
            local idw = S.tabs.w[X.mod(i, #S.tabs.w) + 1]
            local ok1, e1 = pcall(ZeD_CharacterWindow.openTab, pn, idc)
            local ok2, e2 = pcall(ZeD_WorldWindow.openTab, pn, idw)
            if not (ok1 and ok2) then L.errs[#L.errs + 1] = "tab key " .. i .. ": " .. tostring(e1 or e2) end
            L.tabs = L.tabs + 1
        end
    end)
    Q.waitFor(1, 90, X.bothOpen, function(ok)
        local L = S.loop
        if not ok then L.late = L.late + 1; L.errs[#L.errs + 1] = "open " .. i .. ": not both open after 90 frames"; return end
        if X.mod(i, 2) == 1 then
            local idc, idw = X.pick("c"), X.pick("w")
            if idc and X.press("c", idc) then L.tabs = L.tabs + 1 end
            if idw then X.press("w", idw) end
        end
    end)
end
function X.partLoop()
    X.fresh("8 fifty times")
    Q.step(3, function()
        S.loop = { g = { c = X.geo(RT.cw()), w = X.geo(RT.ww()) }, stuck = 0, late = 0, tabs = 0, errs = {} }
    end)
    for i = 1, 50 do
        X.cycle(i)
        if X.mod(i, 10) == 0 then
            Q.waitMs(350)   -- (the UI manager takes closed windows off its list on its own 100 ms beat)
            X.loopCheck(i)
        end
    end
    Q.waitFor(2, 240, X.bothOpen, function(ok)
        local L = S.loop
        local first = {}
        for n = 1, math.min(#L.errs, 6) do first[n] = L.errs[n] end
        Q.check(ok and L.stuck == 0 and L.late == 0 and #L.errs == 0, "50 times: every close closed both windows and every open opened both, no error",
            (#L.errs > 0) and (#L.errs .. " faults, the first: " .. table.concat(first, "; ")) or (L.tabs .. " tabs picked on the way"))
        X.pinAll()
    end)
    Q.step(40, function() end)   -- (the last tab key's press, waiting for its strip to draw, lands before Loot is pressed)
    X.tabStep("c", nil)
    X.tabStep("w", nil)
    Q.step(20, function()
        local gc, gw = X.geo(RT.cw()), X.geo(RT.ww())
        local L = S.loop
        Q.check(X.same(gc, L.g.c, 2) and X.same(gw, L.g.w, 2), "50 times: back on Loot, both windows are where and as big as before the 50 (2 px)",
            "Character " .. X.gs(L.g.c) .. " -> " .. X.gs(gc) .. ", World " .. X.gs(L.g.w) .. " -> " .. X.gs(gw))
        local vi, vl = nil, nil
        pcall(function() vi = getPlayerInventory(pn):getIsVisible() end)
        pcall(function() vl = getPlayerLoot(pn):getIsVisible() end)
        Q.check(vi == false and vl == false, "50 times: the game's own inventory and loot pages are still hidden", "inventory " .. tostring(vi) .. ", loot " .. tostring(vl))
        X.after("50 times: at the end")
    end)
    X.usable("8 fifty times")
    X.partEnd("8 fifty times")
end

-- ===================================================================== setup
Q.step(10, function()
    -- the character kept safe for the whole run, and after it (the last step of the put-back leaves both ON)
    S.safe = {}
    pcall(function() S.safe.god = X.me():isGodMod() end)
    pcall(function() S.safe.inv = X.me():isInvincible() end)
    pcall(function() X.me():setGodMod(true) end)
    pcall(function() X.me():setInvincible(true) end)
    pcall(function()
        local bad = X.hurt()
        S.safe.bad0 = table.concat(bad, ", ")
        if #bad > 0 then Q.say("note: the character came to this script not whole: " .. S.safe.bad0) end
    end)
    S.hasErr = X.err() ~= nil
    if not S.hasErr then Q.say("note: no Lua error counter (getLuaDebuggerErrorCount) in this game: the no-error checks are off") end
    S.errAt, S.secErr = X.err(), X.err()
    S.big = 3 * math.max(X.sw(), X.sh())
    S.big = S.big - X.mod(S.big, 12)
    S.wasChar, S.wasWorld = RT.isOpen(), X.worldOpen()
    S.wasOpen = S.wasChar and S.wasWorld
    S.speed = getGameSpeed()
    if S.speed == 0 then pcall(setGameSpeed, 1) end
    S.snap = (S.wasOpen and ZEDQA_LAYOUT_SNAP) and ZEDQA_LAYOUT_SNAP() or nil
    S.geoC, S.geoW = X.geo(RT.cw()), X.geo(RT.ww())
    S.tabC0 = RT.cw() and RT.cw()._activeTab or nil
    S.tabW0 = RT.ww() and RT.ww()._activeTab or nil
    S.accC0 = RT.cw() and RT.cw()._accentKey or nil
    S.accW0 = RT.ww() and RT.ww()._accentKey or nil
    S.pins = {}
    pcall(function()
        local t = RT.p:getModData().ZeD_WinPinned
        if t then for _, key in ipairs(PIN_KEYS) do S.pins[key] = t[key] end end
    end)
    pcall(function()
        local ws = RT.p:getModData().ZeD_WinState
        S.winState = { had = ws ~= nil, char = ws and X.copy(ws.char), world = ws and X.copy(ws.world) }
    end)
    pcall(function()
        local pl = ZeD.WindowPlaces.load()
        S.places0 = { char = X.copy(pl.char), world = X.copy(pl.world) }
    end)
    S.look = { base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize }
    pcall(function() S.look.see = ZeD.Settings.seeThroughIndex() end)
    pcall(function() S.look.focus = ZeD.Settings.focusStyle() end)
    Q.say("screen " .. X.sw() .. "x" .. X.sh() .. ", scale " .. tostring(ZeD.T.scale) .. ", pair open " .. tostring(S.wasOpen)
        .. ", theme " .. tostring(S.look.base) .. " / " .. tostring(S.look.accent) .. " / " .. tostring(S.look.size))
    if not (RT.isOpen() and X.worldOpen()) then X.toggle() end
end)
Q.waitFor(5, 300, X.bothOpen, function(ok)
    Q.check(ok, "setup: both windows open", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(X.worldOpen()))
    X.pinAll()
    if not S.wasOpen then
        S.accC0 = RT.cw() and RT.cw()._accentKey or nil
        S.accW0 = RT.ww() and RT.ww()._accentKey or nil
    end
end)

X.partDrag()
X.partResize()
X.partRoll()
X.partPins()
X.partMenu()
X.partReset()
X.partOverlap()
X.partLoop()

-- ===================================================================== put back
Q.mark()
-- the character first, in a step of its own (a fault in the steps below cannot skip it): healed if anything is wrong
Q.step(2, function()
    pcall(function() X.me():setGodMod(true) end)
    pcall(function() X.me():setInvincible(true) end)
    local bad = X.hurt()
    S.safe = S.safe or {}
    S.safe.badEnd = table.concat(bad, ", ")
    if #bad > 0 then X.heal() end
end)
Q.step(5, function()
    X.pointer(nil)
    pcall(function() local on, m = X.menuOpen(); if m then m:close() end end)
    pcall(function() ZeD.KeyboardMap.close(pn) end)
    pcall(function() if ISUIHandler.allUIVisible == false then ISUIHandler.toggleUI() end end)
    for _, k in ipairs(KS) do
        local w = X.win(k)
        if w then
            w.moving = false
            if w._resizing then pcall(function() w:_stopResize() end) end
            if w._rolled and ZeD.Curtain then pcall(ZeD.Curtain.finishUnroll, w) end
        end
    end
    -- the look: theme, text size, see-through, controller highlight
    pcall(function()
        local L = S.look
        if L and (ZeD.currentBase ~= L.base or ZeD.currentAccent ~= L.accent or ZeD.currentSize ~= L.size) then
            ZeD.applyTheme(L.base, L.accent, L.size)
            if ZeD.Settings.syncToModOptions then ZeD.Settings.syncToModOptions() end
        end
    end)
    pcall(function() if S.look.see and ZeD.Settings.seeThroughIndex() ~= S.look.see then ZeD.Settings.setSeeThrough(S.look.see) end end)
    pcall(function() if S.look.focus and ZeD.Settings.focusStyle() ~= S.look.focus then ZeD.Settings.setFocusStyle(S.look.focus) end end)
    -- the halves' pins as they were (the saved table; the open windows below read it again)
    pcall(function()
        local md = RT.p:getModData()
        md.ZeD_WinPinned = md.ZeD_WinPinned or {}
        for _, key in ipairs(PIN_KEYS) do md.ZeD_WinPinned[key] = S.pins[key] end
    end)
    if S.wpTouched and S.places0 then
        pcall(function()
            local WP = ZeD.WindowPlaces
            local pl = WP.load()
            pl.char, pl.world = X.copy(S.places0.char), X.copy(S.places0.world)
            WP.flush()
        end)
    end
    if getGameSpeed() ~= 1 and S.speed ~= 0 then pcall(setGameSpeed, 1) end
    if S.wasOpen then
        if not (RT.isOpen() and X.worldOpen()) then X.toggle() end
    else
        if RT.isOpen() and X.worldOpen() then X.toggle() end
        if X.worldOpen() and not S.wasWorld then pcall(ZeD_WorldWindow.close, pn) end
        if RT.isOpen() and not S.wasChar then pcall(ZeD_CharacterWindow.toggle, pn) end
    end
end)
Q.waitFor(10, 300, function()
    if S.wasOpen then return X.bothOpen() end
    return RT.isOpen() == S.wasChar and X.worldOpen() == S.wasWorld
end, function()
    if not S.wasOpen then
        -- as found: the layout the character keeps, as it was (the closes and resets wrote it)
        pcall(function()
            local md = RT.p:getModData()
            if S.winState and S.winState.had then
                md.ZeD_WinState = md.ZeD_WinState or {}
                md.ZeD_WinState.char, md.ZeD_WinState.world = X.copy(S.winState.char), X.copy(S.winState.world)
            elseif S.winState then
                md.ZeD_WinState = nil
            end
        end)
        return
    end
    local c, w = RT.cw(), RT.ww()
    -- (Loot pressed on both strips before the reset: the mod's reset shuts the World window's card but leaves its
    -- tab, so the next script found the World window on the last tab this one opened, with no card)
    for _, k in ipairs(KS) do
        local win = X.win(k)
        if win then
            if win._rolled and ZeD.Curtain then pcall(ZeD.Curtain.finishUnroll, win) end
            pcall(X.press, k, "loot")
        end
    end
    if ZEDQA_LAYOUT_BACK and S.snap then
        ZEDQA_LAYOUT_BACK(S.snap, "bx_win")
    else
        -- (run without the prelude: the mod's own reset, then each window's box as found)
        pcall(function() ZeD_Window.resetLayout() end)
        for _, k in ipairs(KS) do
            local win, g = X.win(k), (k == "c") and S.geoC or S.geoW
            if win and g then pcall(function() win:setWidth(g.w); win:setHeight(g.h); win:setX(g.x); win:setY(g.y) end) end
        end
    end
    -- the pins back on the live windows (after the layout: its reset pins both)
    if c and c._halves and ZeD.Halves then
        pcall(ZeD.Halves.setPin, c, "inv", S.pins.charInv == true); pcall(ZeD.Halves.setPin, c, "drawer", S.pins.charTabs == true)
    end
    if w and w._halves and ZeD.Halves then
        pcall(ZeD.Halves.setPin, w, "inv", S.pins.worldInv == true); pcall(ZeD.Halves.setPin, w, "drawer", S.pins.worldTabs == true)
    end
    pcall(function()
        local md = RT.p:getModData()
        for _, key in ipairs(PIN_KEYS) do md.ZeD_WinPinned[key] = S.pins[key] end
    end)
    -- each window's own accent (the reset clears it)
    c, w = RT.cw(), RT.ww()
    if c then c._accentKey = S.accC0; pcall(ZeD.Settings.syncWindowAccent, c) end
    if w then w._accentKey = S.accW0; pcall(ZeD.Settings.syncWindowAccent, w) end
end)
Q.step(30, function()
    if not S.wasOpen then return end
    if S.tabC0 and S.tabC0 ~= "loot" then RT.charTab(S.tabC0) end
    if S.tabW0 and S.tabW0 ~= "loot" then RT.worldTab(S.tabW0) end
end)
Q.step(60, function()
    if S.speed == 0 then pcall(setGameSpeed, 0) end
    local L = S.look
    local see, focus = nil, nil
    pcall(function() see = ZeD.Settings.seeThroughIndex() end)
    pcall(function() focus = ZeD.Settings.focusStyle() end)
    Q.check(ZeD.currentBase == L.base and ZeD.currentAccent == L.accent and ZeD.currentSize == L.size and see == L.see and focus == L.focus,
        "put back: theme, accent, text size, see-through and controller highlight are as found",
        tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize) .. " / " .. tostring(see) .. " / " .. tostring(focus))
    Q.check(getMouseX == S.realMX and getMouseY == S.realMY and ISUIHandler.allUIVisible ~= false, "put back: the pointer the game reads and the interface are the real ones")
    if S.wasOpen then
        local c, w = X.geo(RT.cw()), X.geo(RT.ww())
        Q.check(X.same(c, S.geoC, 1) and X.same(w, S.geoW, 1), "put back: both windows are where and as big as they were",
            "Character " .. X.gs(S.geoC) .. " -> " .. X.gs(c) .. ", World " .. X.gs(S.geoW) .. " -> " .. X.gs(w))
        local tc, tw = RT.cw() and RT.cw()._activeTab, RT.ww() and RT.ww()._activeTab
        Q.check(tc == S.tabC0 and tw == S.tabW0, "put back: both windows are on the tabs they were found on",
            "Character " .. tostring(S.tabC0) .. " -> " .. tostring(tc) .. ", World " .. tostring(S.tabW0) .. " -> " .. tostring(tw))
    else
        Q.check(RT.isOpen() == S.wasChar and X.worldOpen() == S.wasWorld, "put back: the pair is open or shut as found")
    end
end)
-- the character, last and in a step of its own: healed once more if need be, read, and god mode and invincible left
-- ON (never turned off here: the world stays live after this script, and the prelude's rule is god mode on)
Q.step(2, function()
    local sf = S.safe or {}
    pcall(function() X.me():setGodMod(true) end)
    pcall(function() X.me():setInvincible(true) end)
    local bad, overall = X.hurt()
    if #bad > 0 then
        X.heal()
        sf.badEnd = ((sf.badEnd and sf.badEnd ~= "") and (sf.badEnd .. "; then ") or "") .. table.concat(bad, ", ")
        bad, overall = X.hurt()
    end
    local came = (sf.bad0 and sf.bad0 ~= "") and (", he came to this script with: " .. sf.bad0) or ""
    Q.check(#bad == 0, "put back: the character is alive and whole (health 100, no wound, no fracture, not infected)",
        (#bad == 0) and ("health " .. tostring(overall) .. ((sf.badEnd and sf.badEnd ~= "") and (", healed here from: " .. sf.badEnd) or ", already whole when the put-back began") .. came)
            or (table.concat(bad, ", ") .. came))
    local god, inv = nil, nil
    pcall(function() god = X.me():isGodMod() end)
    pcall(function() inv = X.me():isInvincible() end)
    Q.say("god mode " .. tostring(sf.god) .. " -> " .. tostring(god) .. ", invincible " .. tostring(sf.inv) .. " -> " .. tostring(inv)
        .. " (left ON)")
end)
Q.start()
