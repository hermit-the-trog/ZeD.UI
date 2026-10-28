-- ZeDUI/tools/qa/zedqa_curtain.lua  (Oct 19 2026, geometry round trips Oct 21 2026)
-- In game on the ZeD-QA save: the window curtains (WindowCurtain.lua).
--
-- 0. Prints the geometry both windows loaded with (and their saved copy in
--    modData), then resets both windows the way the footer's "R" square does
--    (ZeD_Window.resetLayout) so no earlier run's layout carries in.
-- 1. The World window: opens the Maps tab, presses the title's roll triangle,
--    shoots mid-roll and rolled, checks the controller stop, unrolls through
--    it, then rolls again and closes the Maps tab (the side must come back by
--    itself, at the size it had before the tab opened).
-- 2. For the World window (its side is on the left) and the Character window
--    (its side is on the right; neither window rolls the other side): the
--    exact getX / getY / getWidth / getHeight of BOTH windows and their saved
--    copies before the roll, while rolled and after the unroll; two plain
--    cycles, one where the rolled window is moved 200 px by its rod, one where
--    it is moved 200 px by its own title bar (it must unroll at its new x / y
--    with its old size), and a plain cycle from there. Any difference above
--    0 px is a FAIL line.
-- 4. (Oct 22 2026) Each window closed while rolled, by every close path the
--    script can drive (the inventory key, the World rod's close box, the
--    Character close box's close(), the controller Y hold's close of both):
--    no ZeD_CurtainRod may stay in the engine's UI list or visible, and the
--    reopened windows are unrolled, to the pixel where the same close and
--    reopen put them without a roll (measured first, each case).
-- 5. (Oct 22 2026) Tab presses while rolled, in the engine's press order, on
--    both windows: every other tab (the rolled geometry kept, the unroll exact),
--    a tab and back, Loot (the side comes down at Loot's own geometry, never
--    wider) and the base tab pressed again.
-- 3. Last of all: leaves both windows rolled with their whole geometry printed
--    ("at quit"), so the next launch's step 0 shows whether the save kept the
--    unrolled geometry (compare "loaded" with the previous run's "at quit").
-- Screenshots zqa_cu_*.png. grep "ZEDQA cu".
local function say(s) print("ZEDQA cu " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function ww() return ZeD_WorldWindow.getWindow() end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cu_" .. n .. ".png") end) end
local fails, checks = 0, 0

local function geo(w) return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() } end
local function gstr(g) return g.x .. "," .. g.y .. " " .. g.w .. "x" .. g.h end
local function same(a, b) return a.x == b.x and a.y == b.y and a.w == b.w and a.h == b.h end
local function num(v) return v and string.format("%.3f", v) or "-" end
local function saved(key)
    local p = getSpecificPlayer(0)
    local st = p and p:getModData().ZeD_WinState
    st = st and st[key]
    if not st then return "saved -" end
    return "saved " .. num(st.x) .. "," .. num(st.y) .. " " .. num(st.w) .. "x" .. num(st.h)
        .. (st.anchorRightEdge and (" anchor " .. num(st.anchorRightEdge)) or "")
        .. " tab " .. tostring(st.activeTab) .. " drawer " .. tostring(st.drawerOpen)
end
local function savedTbl(key)
    local p = getSpecificPlayer(0)
    local st = p and p:getModData().ZeD_WinState
    st = st and st[key]
    if not st then return nil end
    return { x = st.x, y = st.y, w = st.w, h = st.h, a = st.anchorRightEdge }
end
local function both(label)
    local c, w = cw(), ww()
    say(label .. ": Character " .. gstr(geo(c)) .. " rolled " .. tostring(c._rolled) .. " (" .. saved("char") .. ") | World "
        .. gstr(geo(w)) .. " rolled " .. tostring(w._rolled) .. " (" .. saved("world") .. ")")
end
local function cmp(label, who, got, want)
    checks = checks + 1
    if same(got, want) then
        say("ok " .. label .. " " .. who .. " " .. gstr(got))
    else
        fails = fails + 1
        say("FAIL " .. label .. " " .. who .. ": got " .. gstr(got) .. " want " .. gstr(want)
            .. " (dx " .. (got.x - want.x) .. " dy " .. (got.y - want.y) .. " dw " .. (got.w - want.w) .. " dh " .. (got.h - want.h) .. ")")
    end
end
local function cmpSaved(label, who, got, want, dxU, dyU)
    checks = checks + 1
    if not (got and want) then fails = fails + 1; say("FAIL " .. label .. " " .. who .. " saved: missing"); return end
    local function eq(a, b) return math.abs(a - b) < 1e-6 end   -- (design units: a move of 200 px is 200 / scale)
    local ok = eq(got.x, want.x + dxU) and eq(got.y, want.y + dyU) and eq(got.w, want.w) and eq(got.h, want.h)
        and ((got.a == nil and want.a == nil) or (got.a and want.a and eq(got.a, want.a + dxU)))
    if ok then say("ok " .. label .. " " .. who .. " saved " .. num(got.x) .. "," .. num(got.y) .. " " .. num(got.w) .. "x" .. num(got.h))
    else
        fails = fails + 1
        say("FAIL " .. label .. " " .. who .. " saved: got " .. num(got.x) .. "," .. num(got.y) .. " " .. num(got.w) .. "x" .. num(got.h) .. " a " .. num(got.a)
            .. " want " .. num(want.x + dxU) .. "," .. num(want.y + dyU) .. " " .. num(want.w) .. "x" .. num(want.h) .. " a " .. num(want.a and (want.a + dxU)))
    end
end
-- A press the way the engine delivers a mouse press: inside the UI update,
-- followed at once by the engine's ISUIElement:onResize (it enforces the
-- window's minimum width). A press from OnTick ran before the window's layout
-- and never met that check, so the roll bug of Oct 21 hid from this script.
-- (el._qaPressDone: false until the update has run the press. This script counts game
-- ticks, and at 4K a window's update can come more than 10 ticks after the press was
-- queued; a check waits for the press, not for a tick count. Oct 27 2026)
local function viaUpdate(el, fn)
    local own = rawget(el, "update")
    el._qaPressDone = false
    el.update = function(self)
        self.update = own
        self:update()
        fn(self)
        self:onResize()
        self._qaPressDone = true
    end
end
local function rollNow(w)
    local r = w._rollBtn
    if not r then return false end
    viaUpdate(w, function(self) self:onMouseDown(r.x + 2, r.y + 2); self:onMouseUp(r.x + 2, r.y + 2) end)
    return true
end
-- the rolled tab's own way down: a press on the rod's tab (the rod rolls down, then the side returns)
local function unrollNow(w)
    local rod = w._rod
    local c = rod and rod._chip
    if not (w._rolled and c and rod:isVisible()) then ZeD.Curtain.unroll(w); return end
    viaUpdate(rod, function(self) self:onMouseDown(c.x + 2, c.y + 2); self:onMouseUp(c.x + 2, c.y + 2) end)
end
local function rodFlush(label, who, w)
    checks = checks + 1
    local rod = w._rod
    if not (w._rolled and rod and rod:isVisible()) then
        fails = fails + 1; say("FAIL " .. label .. " " .. who .. ": not rolled / no rod (rolled " .. tostring(w._rolled) .. ")"); return
    end
    local wantX = (w._curtain.side == "right") and (w:getX() + w:getWidth()) or (w:getX() - w._rollW)
    if rod:getX() ~= wantX or rod:getY() ~= w:getY() or rod:getWidth() ~= w._rollW then
        fails = fails + 1
        say("FAIL " .. label .. " " .. who .. ": rod " .. rod:getX() .. "," .. rod:getY() .. " " .. rod:getWidth() .. " want " .. wantX .. "," .. w:getY() .. " " .. w._rollW)
    else
        say("ok " .. label .. " " .. who .. " rod flush at " .. rod:getX() .. "," .. rod:getY() .. " " .. rod:getWidth() .. "x" .. rod:getHeight())
    end
end
local function clickTab(win, id)
    for _, ch in pairs(win:getChildren() or {}) do
        for _, z in ipairs(ch._hitZones or {}) do
            if z.id == "tab:" .. id then ch:onMouseDown(z.x + 2, z.y + 2); return true end
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- 0. As loaded, then the reset
-- ---------------------------------------------------------------------------
local G0
at(2, function()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
at(8, function()
    both("loaded")
    say("scale " .. tostring(ZeD.T.scale) .. " root " .. tostring(ZeD.T.root) .. " screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight())
    shot(0)
end)
at(10, function()
    if ZeD_Window and ZeD_Window.resetLayout then ZeD_Window.resetLayout(); say("reset: ZeD_Window.resetLayout")
    else say("reset: no ZeD_Window.resetLayout (old build)") end
end)
at(40, function() both("reset") end)

-- ---------------------------------------------------------------------------
-- 1. The World window's curtain, the player's way
-- ---------------------------------------------------------------------------
local x0, w0, y0, h0
at(45, function()
    G0 = geo(ww())
    if not ZeD_WorldWindow.isTabShowing("maps") then ZeD_WorldWindow.openTab(0, "maps") end
end)
at(110, function()
    local w = ww()
    x0, w0, y0, h0 = w:getX(), w:getWidth(), w:getY(), w:getHeight()
    local r = w._rollBtn
    say("before: x " .. x0 .. " w " .. w0 .. " title " .. tostring(w.title) .. " button " .. tostring(r and (r.x .. "," .. r.y .. " " .. r.w)))
    rollNow(w)
end)
at(116, function() shot(1) end)
at(160, function()
    local w = ww(); local rod = w._rod
    say("rolled " .. tostring(w._rolled) .. ": x " .. w:getX() .. " w " .. w:getWidth() .. " (sum " .. (w:getX() + w:getWidth()) .. " was " .. (x0 + w0) .. ")"
        .. " rod " .. tostring(rod and (rod:getX() .. "," .. rod:getY() .. " " .. rod:getWidth() .. "x" .. rod:getHeight()))
        .. " content " .. tostring(w._mainContent:isVisible()) .. " title " .. tostring(w.title))
    local ids = {}
    for _, z in ipairs(w._focusRing or {}) do
        if z.focusable then for _, e in ipairs(z.elements or {}) do if e.id and tostring(e.id):find("curtain") then ids[#ids + 1] = z.zone .. ":" .. e.id end end end
    end
    say("pad stops: " .. table.concat(ids, ", "))
    shot(2)
end)
at(170, function()
    local w = ww()
    for _, z in ipairs(w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.id == "curtain:unroll" then e.onActivate(w, e); say("A on the tab") end end
    end
end)
at(176, function() shot(3) end)
at(240, function()
    local w = ww()
    say("unrolled " .. tostring(not w._rolled) .. ": x " .. w:getX() .. " w " .. w:getWidth() .. " content " .. tostring(w._mainContent:isVisible())
        .. " rod " .. tostring(w._rod and w._rod:isVisible()))
    cmp("first roll", "World", geo(w), { x = x0, y = y0, w = w0, h = h0 })
    rollNow(w)
end)
at(300, function() say("rolled again " .. tostring(ww()._rolled)); ZeD_WorldWindow.openTab(0, "maps", true) end)
at(380, function()
    local w = ww()
    say("tab closed: rolled " .. tostring(w._rolled) .. " x " .. w:getX() .. " w " .. w:getWidth() .. " content " .. tostring(w._mainContent:isVisible()) .. " drawer " .. tostring(w._drawerOpen))
    cmp("tab closed while rolled", "World", geo(w), G0)
    shot(4)
end)

-- ---------------------------------------------------------------------------
-- 2. Geometry round trips
-- ---------------------------------------------------------------------------
local clock = 400
local function after(d, fn) clock = clock + d; at(clock, fn) end
local MOVE = 200   -- screen px

-- one window's round trips; who = "World" or "Character"
local function phase(who, key, get, other, open)
    local S0, O0, SS0, exp, dxU, dyU
    local function cycle(label, move)
        after(2, function()
            local w = get()
            SS0 = savedTbl(key)
            both(label .. " " .. who .. " before roll")
            if not rollNow(w) then fails = fails + 1; say("FAIL " .. label .. " " .. who .. ": no roll button") end
        end)
        after(40, function()
            local w = get()
            both(label .. " " .. who .. " rolled")
            say(label .. " " .. who .. " rollW " .. tostring(w._rollW))
            rodFlush(label .. " rolled", who, w)
            local rw = w._rollW or 0
            cmp(label .. " rolled", who, geo(w), { x = (w._curtain.side == "right") and S0.x or (S0.x + rw), y = S0.y, w = S0.w - rw, h = S0.h })
            cmp(label .. " while rolled: other", (who == "World" and "Character" or "World"), geo(other()), O0)
            dxU, dyU = 0, 0
            if move then
                local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
                local dx = (S0.x + MOVE + S0.w <= sw) and MOVE or ((S0.x >= MOVE) and -MOVE or 0)
                local dy = (S0.y + MOVE + S0.h <= sh) and MOVE or ((S0.y >= MOVE) and -MOVE or 0)
                if dx == 0 and dy == 0 then fails = fails + 1; say("FAIL " .. label .. " " .. who .. ": no room to move the rolled window") end
                if move == "rod" then
                    local rod = w._rod
                    rod._dragging = true
                    rod:onMouseMove(dx, 0); rod:onMouseMove(0, dy)
                    rod._dragging = false
                else
                    w.moving = true
                    w:onMouseMove(dx, 0); w:onMouseMove(0, dy)
                    w.moving = false
                end
                exp = { x = S0.x + dx, y = S0.y + dy, w = S0.w, h = S0.h }
                local sc = ZeD.T.scale or 1
                dxU, dyU = dx / sc, dy / sc
                say(label .. " " .. who .. " moved by " .. dx .. "," .. dy .. " (" .. move .. ") to " .. gstr(geo(w)))
            else
                exp = S0
            end
        end)
        after(90, function()
            local w = get()
            if move then rodFlush(label .. " moved", who, w) end
            both(label .. " " .. who .. " rolled, before unroll")
            unrollNow(w)
        end)
        after(90, function()
            local w = get()
            both(label .. " " .. who .. " unrolled")
            if w._rolled then fails = fails + 1; say("FAIL " .. label .. " " .. who .. ": still rolled after the unroll") end
            cmp(label, who, geo(w), exp)
            cmp(label, "other (" .. (who == "World" and "Character" or "World") .. ")", geo(other()), O0)
            cmpSaved(label, who, savedTbl(key), SS0, dxU, dyU)
            S0 = geo(w)
        end)
    end
    after(5, open)
    after(120, function()
        local w = get()
        S0, O0 = geo(w), geo(other())
        say(who .. " before: " .. gstr(S0) .. " (other " .. gstr(O0) .. ") drawer " .. tostring(w._drawerOpen) .. " " .. tostring(w._drawerMode) .. " tab " .. tostring(w._activeTab))
    end)
    cycle("cycle1")
    cycle("cycle2")
    cycle("moved by rod", "rod")
    cycle("moved by title", "title")
    cycle("cycle5")
end

phase("World", "world", ww, cw, function()
    if not ZeD_WorldWindow.isTabShowing("maps") then ZeD_WorldWindow.openTab(0, "maps") end
end)
phase("Character", "char", cw, ww, function()
    local c = cw()
    if not (c._drawerOpen and c._drawerMode == "tab") then say("character health tab " .. tostring(clickTab(c, "health"))) end
end)

-- ---------------------------------------------------------------------------
-- 4. Closed while rolled (Oct 22 2026): the rod leaves the UI with its window,
--    and the window reopens unrolled at its pre-roll geometry
-- ---------------------------------------------------------------------------
local function check(label, ok, detail)
    checks = checks + 1
    if ok then say("ok " .. label .. (detail and (" (" .. detail .. ")") or ""))
    else fails = fails + 1; say("FAIL " .. label .. (detail and (": " .. detail) or "")) end
end
-- every ZeD_CurtainRod in the engine's UI list (a removed one leaves it by the next frame)
local function rodsInUI()
    local n, ui = 0, UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local ok, t = pcall(function() return ui:get(i):getTable() end)
        if ok and t and t.Type == "ZeD_CurtainRod" then n = n + 1 end
    end
    return n
end
local function bothOpen() return ZeD_CharacterWindow.isOpen() and ZeD_WorldWindow.isOpen() end
local function invKey() ZeD_CharacterWindow._onKeyPressed(getCore():getKey("Toggle Inventory")) end
local function hasTab(win, id)
    for _, ch in pairs(win:getChildren() or {}) do
        for _, z in ipairs(ch._hitZones or {}) do if z.id == "tab:" .. id then return true end end
    end
    return false
end
-- a tab press in the engine's order (inside the window's update, then onResize)
local function clickTabNow(w, id) viaUpdate(w, function(self) clickTab(self, id) end) end
-- each window on its tab drawer: World on Maps, Character on Health
local function openBase(who)
    if who == "World" then
        if not ZeD_WorldWindow.isTabShowing("maps") then ZeD_WorldWindow.openTab(0, "maps") end
    else
        local c = cw()
        if not (c._drawerOpen and c._drawerMode == "tab" and c._activeTab == "health") then clickTab(c, "health") end
    end
end
local function closeBy(how, w)
    if how == "inventory key" then invKey()
    elseif how == "rod close box" then
        local rod = w._rod
        local r = rod and rod._closeRect
        if not r then return false end
        viaUpdate(rod, function(self) self:onMouseDown(r.x + 2, r.y + 2); self:onMouseUp(r.x + 2, r.y + 2) end)
    elseif how == "close box" then
        w:close()   -- (the box polls the real mouse in ZeD_Window:update; this is what it calls)
    else
        -- the controller's Y hold: every registered window's close (FocusManager _closeAllWindows)
        local c, x = cw(), ww()
        if c then c:close() end
        if x then x:close() end
    end
    return true
end

local CLOSES = {
    { who = "World", how = "inventory key" },
    { who = "World", how = "rod close box" },
    { who = "World", how = "controller Y hold" },
    { who = "Character", how = "inventory key" },
    { who = "Character", how = "close box" },
    { who = "Character", how = "controller Y hold" },
}
for _, cs in ipairs(CLOSES) do
    local who = cs.who
    local get = (who == "World") and ww or cw
    local other = (who == "World") and cw or ww
    local oname = (who == "World") and "Character" or "World"
    local label = "closed rolled (" .. cs.how .. ")"
    local S, O, R, RO, rod
    local function reopen() if cs.how == "inventory key" then invKey() else ZeD_CharacterWindow.toggleBothPaired(0) end end
    after(5, function() if not bothOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
    after(10, function() openBase(who) end)
    -- the reference: the same close and reopen unrolled (the World window
    -- reopens on Loot whatever tab it closed on; the roll must change nothing)
    after(90, function()
        S, O = geo(get()), geo(other())
        if cs.how == "rod close box" then get():close() else closeBy(cs.how, get()) end
    end)
    after(15, function() reopen() end)
    after(90, function()
        R, RO = geo(get()), geo(other())
        both(label .. " " .. who .. " reference, closed and reopened unrolled")
        openBase(who)
    end)
    after(90, function()
        cmp(label .. " reference back on its tab", who, geo(get()), S)
        both(label .. " " .. who .. " before roll")
        if not rollNow(get()) then check(label .. " " .. who .. " roll button", false, "none") end
    end)
    after(40, function()
        local w = get()
        rod = w._rod
        check(label .. " " .. who .. " rolled", w._rolled and rod ~= nil and rod:isVisible(), "rods in UI " .. rodsInUI())
        if not closeBy(cs.how, w) then check(label .. " " .. who .. " close box on the rod", false, "none") end
    end)
    after(15, function()
        check(label .. " " .. who .. " window closed", get() == nil)
        check(label .. " " .. who .. " rod gone", rod ~= nil and not rod:isVisible() and rodsInUI() == 0,
            "rod visible " .. tostring(rod and rod:isVisible()) .. ", rods in UI " .. rodsInUI())
        reopen()   -- the player's way: the key again, or the pair's open for one window
    end)
    after(90, function()
        local w = get()
        if not w then check(label .. " " .. who .. " reopened", false, "still closed"); return end
        both(label .. " " .. who .. " reopened")
        check(label .. " " .. who .. " reopened unrolled", not w._rolled and w._rod == nil and rodsInUI() == 0,
            "rolled " .. tostring(w._rolled) .. ", rods in UI " .. rodsInUI())
        cmp(label .. " reopened as unrolled", who, geo(w), R)
        cmp(label .. " reopened: other", oname, geo(other()), RO)
    end)
end

-- ---------------------------------------------------------------------------
-- 5. Tab presses while rolled (Oct 22 2026). Every other tab: roll on the base
--    tab, press the tab (still rolled, the rolled geometry kept), roll down
--    (exactly the pre-roll geometry). Then a tab and back while rolled; Loot
--    (no drawer: the side comes down with the press, at the geometry Loot has
--    when pressed unrolled); the base tab pressed again (its drawer closes, the
--    side comes down, the same Loot geometry).
-- ---------------------------------------------------------------------------
local function tabPhase(who, get, other, base, tabs)
    local oname = (who == "World") and "Character" or "World"
    local S, O, GL
    after(5, function() if not bothOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
    after(10, function() openBase(who) end)
    after(90, function()
        S, O = geo(get()), geo(other())
        say(who .. " tabs: on " .. base .. " " .. gstr(S) .. " (other " .. gstr(O) .. ")")
    end)
    -- R: the unrolled geometry the rolled window stands for (the base tab's, or the tab's own)
    local function rolledGeo(w, R)
        R = R or S
        local rw = w._rollW or 0
        return { x = (w._curtain.side == "right") and R.x or (R.x + rw), y = R.y, w = R.w - rw, h = R.h }
    end
    for _, id in ipairs(tabs) do
        local shown, T
        -- (Oct 26 2026) each tab's drawer has its own width (the Maps toolbar made Maps 65 px wider
        -- than the rest at 4K): the tab's own unrolled geometry is taken first and is what the
        -- rolled and unrolled window on that tab must match
        after(2, function()
            shown = hasTab(get(), id)
            if not shown then say("tab " .. id .. " " .. who .. ": not shown here, skipped"); return end
            clickTabNow(get(), id)
        end)
        after(90, function()
            if not shown then return end
            T = geo(get())
            if T.w ~= S.w then say("tab " .. id .. " " .. who .. ": its own width, " .. gstr(T) .. " (" .. base .. " " .. gstr(S) .. ")") end
            clickTab(get(), base)
        end)
        after(90, function()
            if not shown then return end
            cmp("tab " .. id .. " reference, back on " .. base, who, geo(get()), S)
            if not rollNow(get()) then check("tab " .. id .. " " .. who .. " roll button", false, "none") end
        end)
        after(40, function()
            if not shown then return end
            local w = get()
            check("tab " .. id .. " " .. who .. " rolled before the press", w._rolled == true)
            clickTabNow(w, id)
        end)
        after(60, function()
            if not shown then return end
            local w = get()
            check("tab " .. id .. " " .. who .. " still rolled on the tab", w._rolled == true and w._activeTab == id, "tab " .. tostring(w._activeTab))
            cmp("tab " .. id .. " rolled", who, geo(w), rolledGeo(w, T))
            unrollNow(w)
        end)
        after(90, function()
            if not shown then return end
            local w = get()
            check("tab " .. id .. " " .. who .. " unrolled", not w._rolled and rodsInUI() == 0, "rods in UI " .. rodsInUI())
            cmp("tab " .. id .. " unrolled", who, geo(w), T)
            cmp("tab " .. id .. " unrolled: other", oname, geo(other()), O)
            clickTab(w, base)
        end)
        after(60, function()
            if shown then cmp("tab " .. id .. " back on " .. base, who, geo(get()), S) end
        end)
    end
    -- a tab and back while rolled
    local there = tabs[1]
    after(2, function() rollNow(get()) end)
    after(40, function() clickTabNow(get(), there) end)
    after(40, function() clickTabNow(get(), base) end)
    after(40, function()
        local w = get()
        check(there .. " and back " .. who .. " still rolled", w._rolled == true and w._activeTab == base, "tab " .. tostring(w._activeTab))
        cmp(there .. " and back rolled", who, geo(w), rolledGeo(w))
        unrollNow(w)
    end)
    after(90, function()
        cmp(there .. " and back, unrolled", who, geo(get()), S)
    end)
    -- Loot: its geometry pressed unrolled first, then pressed while rolled
    after(2, function() clickTabNow(get(), "loot") end)
    after(40, function()
        GL = geo(get())
        say(who .. " Loot (unrolled) " .. gstr(GL))
        clickTab(get(), base)
    end)
    after(80, function()
        cmp("Loot reference, back on " .. base, who, geo(get()), S)
        rollNow(get())
    end)
    local rod
    after(40, function()
        local w = get()
        rod = w._rod
        check("Loot " .. who .. " rolled before the press", w._rolled == true)
        clickTabNow(w, "loot")
    end)
    local function sideDown()
        local w = get()
        check("Loot " .. who .. " side down with the press", not w._rolled and w._activeTab == "loot" and not (rod and rod:isVisible()) and rodsInUI() == 0,
            "rolled " .. tostring(w._rolled) .. " tab " .. tostring(w._activeTab) .. " rods in UI " .. rodsInUI())
    end
    local deferred = false
    after(10, function()
        if get()._qaPressDone == false then deferred = true; say(who .. " Loot press not delivered by the window's update after 10 ticks; checked 30 ticks later")
        else sideDown() end
    end)
    after(30, function()
        local w = get()
        if deferred then sideDown() end
        cmp("Loot while rolled", who, geo(w), GL)
        cmp("Loot while rolled: other", oname, geo(other()), O)
        clickTab(w, base)
    end)
    after(80, function()
        cmp("Loot while rolled, back on " .. base, who, geo(get()), S)
        rollNow(get())
    end)
    -- the base tab pressed again while rolled: its drawer closes and the side comes down
    after(40, function()
        check(base .. " again " .. who .. " rolled before the press", get()._rolled == true)
        clickTabNow(get(), base)
    end)
    after(80, function()
        local w = get()
        check(base .. " again " .. who .. " side down", not w._rolled and rodsInUI() == 0, "rolled " .. tostring(w._rolled))
        cmp(base .. " pressed again while rolled", who, geo(w), GL)
        clickTab(w, base)
    end)
    after(80, function()
        cmp(base .. " again, back on " .. base, who, geo(get()), S)
    end)
end
tabPhase("World", ww, cw, "maps", { "forage", "craft", "build", "furniture", "animals", "radio", "vehicle" })
tabPhase("Character", cw, ww, "health", { "skills", "equip", "thermal", "identity", "journal", "radio" })

after(5, function()
    say("geometry checks " .. checks .. ", differences " .. fails)
    shot(5)
end)
-- 3. Both rolled at quit: the save must keep the unrolled geometry
after(5, function()
    both("at quit, unrolled")
    rollNow(ww()); rollNow(cw())
end)
after(120, function()
    both("at quit, rolled")
    shot(6)
    say("DONE")
end)
local endTick = clock + 5

local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > endTick then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
