-- ZeDUI/tools/qa/gallery_story_shots.lua  (Oct 21 2026)
-- Story gallery, part 2 of 3: after gallery_story_stage.lua (needs STORY.ready), ZeD on.
-- The Fossoil story told through ZeD's tabs, in the order a player would do it. Full 4K
-- screenshots in Zomboid/Screenshots named story_<nn>_<beat>.png:
--   00  who they are: the Identity tab (profession, traits) and the Skills tab
--   01  the old job: the reader on the Fossoil flyer (paper, words)        10:00
--   02  the plan: the Journal tab with the character's entry; the flyer's quick look
--   03  the route: the Maps tab, the flyer pin's hover card and the note at the store
--   04a driving in: the seat chooser, then the dash with the low fuel lamp  11:00
--   04b the flat: the Vehicle tab on the missing tire (Install picked), the install's bar
--   05  barricading: the window's context menu (icon strip), the bar counting 2/3   12:00
--   06  cleaning up: bleach and a dish cloth on the blood, the bar           13:00
--   07  stocking: the World window's columns on the shelves, an item dragged to a shelf
--   08  open for business: the window box's menu, Theme > Light and Accent > Blue  14:00
--   09  pumping gas: refuelling the car, the gas can's card while it fills, the dash full
--   10  customers: a queue of passive zombies at the counter, the HUD          15:00
--   11  smoke break: smoking, the Stressed moodle's hover, the watch           16:00
--   12  night shift: the store lit, the dash at night, the CaZio watch's LIGHT, the windows
-- Beats 1-7 in high contrast + PZ Teal, 8-11 Light + Blue (picked from the window box's
-- menu, which saves them with the other ZeD options; the teardown puts the options back),
-- 12 Dark (STORY_NIGHT_BASE = "hicon" for high contrast). STORY_ONLY =
-- { ["01"] = true, ... } above this header takes only those beats (the beats depend on
-- each other a little: 9 needs the car from 4, 12 the theme from 8).
-- Beat 08's four shots: a) the pointer on the World window's box, the box lit; b) its menu
-- pulled down, the Theme submenu open, the pointer on Light (picked right after); c) the
-- Accent submenu, the pointer on Blue (the Character window already blue; picked right
-- after); d) the pointer parked, Light + Blue.
-- Each window's rect and its window box are printed ("box ... windowbox") for the crops.
-- "ZEDQA stz ..." ending "DONE".
local ST = STORY
if not (ST and ST.ready and ST.newSeq) then print("ZEDQA stz ERR run gallery_story_stage.lua first"); print("ZEDQA stz DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA stz ERR ZeD is not loaded"); print("ZEDQA stz DONE"); return end
local S = ST.newSeq("stz", 1500000)
local say = S.say
local p, pn, core = ST.p, ST.pn, ST.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local Z = { lock = nil, ok = true }
local function want(k) return (not STORY_ONLY) or STORY_ONLY[k] == true end

-- ---------------------------------------------------------------------------
-- windows (as gallery_v3_zed.lua)
-- ---------------------------------------------------------------------------
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end
function Z.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(pn)
    else
        if CWm.isOpen() then CWm.toggle(pn) end
        if WWm.isOpen() then WWm.close() end
    end
end
function Z.place()
    local c, w = Z.CW(), Z.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) or w._rolled then return false end
    if not Z.lock then
        local gap = ZeD.T.px(8)
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        Z.lock = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap }
    end
    c._anchorRightEdge = Z.lock.right
    c:setX(Z.lock.right - c:getWidth()); w:setX(Z.lock.left)
    c:setY(0); w:setY(0)
    return true
end
function Z.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then
        if WWm.isOpen() then WWm.close() end
        if CWm.isOpen() then CWm.toggle(pn) end
        CWm.toggleBothPaired(pn)
    end
    Z.place()
end
function Z.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function Z.charTab(id) local w = Z.CW(); return (w and Z.goTab(w, w._tabStripPanel, id)) and true or false end
function Z.worldTab(id) local w = Z.WW(); return (w and Z.goTab(w, w._actionTabStrip, id)) and true or false end
-- the window box's corners on the screen (left, top, right, bottom), nil when the window has none
function Z.boxRect(win)
    local b = win and win.windowBoxRect and win:windowBoxRect()
    if not b then return nil end
    local ax, ay = win:getAbsoluteX(), win:getAbsoluteY()
    return math.floor(ax + b.x), math.floor(ay + b.y), math.floor(ax + b.x + b.w), math.floor(ay + b.y + b.h)
end
function Z.box(tag, win)
    if win and win:isVisible() then
        say(string.format("box %s %d,%d-%d,%d", tag, win:getX(), win:getY(), win:getX() + win:getWidth(), win:getY() + win:getHeight()))
        -- the window box at the right end of the title bar, in screen coordinates
        local x0, y0, x1, y1 = Z.boxRect(win)
        if x0 then say(string.format("box %s windowbox %d,%d-%d,%d", tag, x0, y0, x1, y1)) end
    end
end
function Z.shot(name)
    S.shot(name)
    if CWm.isOpen() then Z.box(name .. " char", Z.CW()) end
    if WWm.isOpen() then Z.box(name .. " world", Z.WW()) end
end
-- the theme in memory (beats 1-7; the window menu's choices, beat 8 on, also save to the options)
function Z.theme(base, accent)
    ZeD.applyTheme(base, accent, ZeD.currentSize)
    local c, w = Z.CW(), Z.WW()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
end
-- beats 9-11 on their own (a retake): Light + Blue as beat 8 left it
function Z.lightBlue()
    ZeD.applyTheme("light", (STORY_GLOBAL_BLUE ~= false) and "blue" or nil, nil)
    local c, w = Z.CW(), Z.WW()
    if c then c._accentKey = "blue" end
    if w then w._accentKey = "blue" end
end

-- ---------------------------------------------------------------------------
-- the window box and its menu (ZeD.WindowMenu), driven the way the player drives them
-- ---------------------------------------------------------------------------
function Z.pointAt(x, y)
    if Mouse and Mouse.setXY then pcall(function() Mouse.setXY(math.floor(x), math.floor(y)) end) end
end
-- the pointer on the window box (ZeD_Window:update lights the box from the real pointer)
function Z.hoverBox(win)
    local x0, y0, x1, y1 = Z.boxRect(win)
    if x0 then Z.pointAt((x0 + x1) / 2, (y0 + y1) / 2) end
end
-- the words of a Theme or Accent choice, as the menu builds them
function Z.leafName(kind, key)
    local Sx = ZeD.Settings
    local keys, labels = Sx.baseKeys, Sx.baseLabels
    if kind == "accent" then keys, labels = Sx.accentKeys, Sx.accentLabels end
    for i, k in ipairs(keys) do
        if k == key then return ZeD.tr(labels[i]) end
    end
    return tostring(key)
end
-- the menu that is pulled down now (ZeD.WindowMenu.current), nil when none is
function Z.menu()
    local m = ZeD.WindowMenu and ZeD.WindowMenu.current
    return (m and m._ctx and m._ctx.open) and m or nil
end
-- the hit zone of the row on level li whose words are `name` (the menu's panel covers the
-- screen, so its zones are in screen coordinates; they exist once the menu has drawn a frame)
function Z.menuRow(li, name)
    local m = Z.menu()
    local lv = m and m._levels and m._levels[li]
    if not lv then return nil end
    for ri, r in ipairs(lv.rows) do
        if r.def and r.def.name == name then
            for _, zn in ipairs(m._hitZones or {}) do
                if zn.id == "row:" .. li .. ":" .. ri then return zn end
            end
        end
    end
    return nil
end
function Z.menuHover(li, name)
    local zn = Z.menuRow(li, name)
    if zn then Z.pointAt(zn.x + zn.w / 2, zn.y + zn.h / 2) end
    return zn ~= nil
end
-- a click on a row: the context list's own mouse-up. A row with a submenu opens it; a choice
-- runs its onFire (what the window menu hangs on every leaf) and the menu closes.
function Z.menuClick(li, name)
    local m, zn = Z.menu(), Z.menuRow(li, name)
    if not (m and zn) then return false end
    m:onMouseUp(math.floor(zn.x + zn.w / 2), math.floor(zn.y + zn.h / 2))
    return true
end
-- Queue one choice from a window's menu in the steps a player takes. The box's own click action
-- pulls the menu down (ZeD_Window:openWindowMenu, what update runs on a press and release over
-- the box), a click on the parent row opens its submenu, the pointer rests on the choice (the
-- shot, when one is named, is taken here, before the pick), a click on the choice runs it and
-- closes the menu. getWin is a function: the window may not be up when the steps are queued.
function Z.menuPick(getWin, parent, choice, shot)
    local tag = shot or choice
    S.step(2, function()
        local w = getWin()
        if not w then S.err(tag, "no window to pull the menu from"); return end
        Z.hoverBox(w)
        w:openWindowMenu()
        say(string.format("%s: menu down %s | box lit %s", tag, tostring(Z.menu() ~= nil), tostring(w._wboxOpen)))
    end)
    S.poll(2, 180, function() return Z.menuRow(1, parent) ~= nil end,
        function() S.err(tag, "the menu did not draw its " .. parent .. " row") end)
    S.step(2, function() Z.menuClick(1, parent) end)
    S.poll(2, 180, function() return Z.menuRow(2, choice) ~= nil end,
        function() S.err(tag, "the " .. parent .. " submenu did not draw " .. choice) end)
    S.step(2, function() Z.menuHover(2, choice) end)
    S.step(30, function() if shot then Z.shot(shot) end end)
    S.step(2, function()
        local ok = Z.menuClick(2, choice)
        say(string.format("%s: %s clicked %s | menu closed %s", tag, choice, tostring(ok), tostring(Z.menu() == nil)))
    end)
end
-- A choice for when no window is up to pull a menu down from (the night step): the leaf the
-- window menu builds, fired as a click on its row fires it (its onFire; the menu itself is not
-- drawn). With no window built at all, ZeD.applyTheme directly.
function Z.fireTheme(base)
    local win = Z.WW() or Z.CW()
    local WM = ZeD.WindowMenu
    local items = (win and WM and WM.build) and WM.build(win) or {}
    local leaf = nil
    for _, it in ipairs(items) do
        if it.name == ZeD.tr("UI_ZeD_WinMenu_Theme") then
            for _, c in ipairs(it.children or {}) do
                if c.name == Z.leafName("base", base) then leaf = c end
            end
        end
    end
    if leaf and leaf.onFire then leaf.onFire(); return "the menu's choice" end
    ZeD.applyTheme(base, nil, nil)
    return "ZeD.applyTheme"
end
function Z.selectItem(item)
    local w = Z.CW()
    local c = w and w._mainContent
    if not c then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
function Z.colOn(win, inv)
    for i, c in ipairs(win and win._containers or {}) do
        if c.inventory == inv then
            for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
-- the store's shelves within the World window's reach (its _containers), up to three
function Z.shelfInvs()
    local w = Z.WW()
    local out = {}
    for _, c in ipairs(w and w._containers or {}) do
        for _, e in ipairs(ST.F.shelves) do
            if c.inventory == e.inv and #out < 3 then out[#out + 1] = c.inventory end
        end
    end
    return out
end
function Z.mc(on)
    local c, w = Z.CW(), Z.WW()
    if not (c and w) then return false end
    if on then Z.charTab("loot"); Z.worldTab("loot") end
    local done = true
    local back = ST.bags and ST.bags.back and ST.bags.back:getInventory()
    if back and Z.colOn(c, back) ~= on then CWm.toggleColumn(back); done = false end
    for _, inv in ipairs(Z.mcWorld or {}) do
        if Z.colOn(w, inv) ~= on then WWm.toggleColumn(inv); done = false end
    end
    return done
end
function Z.drag(on)
    local cw, ww = Z.CW(), Z.WW()
    local c = cw and cw._mainContent
    if not c then return false, "no content" end
    if not on then
        if Z.dragSt then
            pcall(function() c._drag:cancel() end)
            pcall(function() c:setCapture(false) end)
            c._deferredSelect, c._dragSourceCol, c._dragSourceInv = nil, nil, nil
            if Z.dragSt.src then Z.dragSt.src.selectedItems[Z.dragSt.item] = nil end
            Z.dragSt = nil
        end
        return true
    end
    local back = ST.bags.back:getInventory()
    local item = ST.find("Base.Pop", back) or ST.find("Base.Crisps", back)
    if not item then return false, "nothing in the backpack" end
    local srcIdx, src = nil, nil
    for i, cs in ipairs(c._colStates or {}) do if cs.inventory == back then srcIdx, src = i, cs end end
    local wc = ww._mainContent
    local dst = nil
    for _, cs in ipairs(wc._colStates or {}) do if Z.mcWorld and cs.inventory == Z.mcWorld[1] then dst = cs end end
    if not (src and dst) then return false, "columns not found (backpack " .. tostring(src ~= nil) .. ", shelf " .. tostring(dst ~= nil) .. ")" end
    local gx = wc:getAbsoluteX() + dst.renderX + math.floor(dst.renderW / 2)
    local gy = wc:getAbsoluteY() + math.floor(wc:getHeight() * 0.35)
    src.selectedItems[item] = true
    c._selectedItems = src.selectedItems
    c._dragSourceCol, c._dragSourceInv, c._activeCol = srcIdx, back, srcIdx
    c._drag:beginPending({ item }, item, gx, gy)
    c._drag:activate()
    c._drag:updateGhostPos(gx, gy)
    cw._drawerItem = nil
    cw:bringToTop()
    pcall(function() c:setCapture(true) end)
    if Mouse and Mouse.setXY then pcall(function() Mouse.setXY(gx, gy) end) end
    Z.dragSt = { src = src, item = item }
    say(string.format("dragging %s from the backpack column to the shelf column at %d,%d", item:getFullType(), gx, gy))
    return true
end
function Z.zm() local v = getPlayerContextMenu(pn); return v and v._zedMenu end
-- the screen point of a square's middle
function Z.screenOf(x, y, z)
    local sx, sy = 0, 0
    pcall(function() sx = isoToScreenX(pn, x + 0.5, y + 0.5, (z or 0) + 0.4); sy = isoToScreenY(pn, x + 0.5, y + 0.5, (z or 0) + 0.4) end)
    return math.floor(sx), math.floor(sy)
end
function Z.dirTo(d)
    if d[1] == 1 then return "E" elseif d[1] == -1 then return "W" elseif d[2] == -1 then return "N" end
    return "S"
end
function Z.enterCar()
    local v = ST.car
    if not v then return false end
    local d = 99
    pcall(function() d = v:DistTo(p) end)
    if d > 8 then
        local q = ST.outNear(math.floor(v:getX()), math.floor(v:getY()), 5)
        if q then ST.tpSq(q) end
        pcall(function() d = v:DistTo(p) end)
    end
    if d > 12 then say("ERR the car is " .. d .. " away: not getting in"); return false end
    pcall(function() v:enter(0, p) end)
    local ok = p:getVehicle() ~= nil
    if ok then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
    return ok
end
function Z.exitCar()
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
end
-- start the engine (vanilla's start can fail: retried), the steps queued on S
function Z.engineOn()
    local E = { tries = 0, last = -9999 }
    S.step(30, function() if p:getVehicle() then pcall(function() ST.car:setKeysInIgnition(true) end) end end)
    S.poll(10, 1500, function()
        if not p:getVehicle() then return true end
        local run = false
        pcall(function() run = ST.car:isEngineRunning() end)
        if run then return true end
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        if not (q and q.queue and #q.queue > 0) and S.tick - E.last > 120 and E.tries < 5 then
            E.tries = E.tries + 1; E.last = S.tick
            pcall(function() ISVehicleMenu.onStartEngine(p) end)
        end
        return false
    end, function() say("note: the engine did not start") end)
end
function Z.engineOff()
    pcall(function() if ST.car:isEngineRunning() then ST.car:shutOff() end end)
end
function Z.lights(on)
    local cur = false
    pcall(function() cur = ST.car:getHeadlightsOn() end)
    if cur ~= on then pcall(function() ISVehicleMenu.onToggleHeadlights(p) end) end
end
function Z.dashInfo(tag)
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    local st = d and d._st
    local g = ST.car and ST.car:getPartById("GasTank")
    say(string.format("%s: fuel %.1f/%.1f | dash fuel %s lamp %s lights %s running %s", tag, g and g:getContainerContentAmount() or -1,
        g and g:getContainerCapacity() or -1, tostring(st and st.fuel), tostring(st and st.fuelLamp), tostring(st and st.lights), tostring(st and st.running)))
end
-- wait for a timed action of a type to reach a progress (and a count of that type left), then shoot
function Z.actionShot(name, typ, delta, sameLeft, maxFrames)
    S.poll(5, maxFrames or 2400, function()
        local a, t, d, same = ST.action()
        if t == typ and d >= delta and (not sameLeft or same == sameLeft) then
            say(string.format("%s: %s at %d%% (%d of that type queued)", name, t, math.floor(d * 100), same))
            Z.shot(name)
            return true
        end
        return false
    end, function()
        local a, t, d, same = ST.action()
        S.err(name, "no " .. typ .. " in progress (running: " .. tostring(t) .. " " .. tostring(d) .. ")")
    end)
end
function Z.waitIdle(maxFrames)
    S.poll(5, maxFrames or 1800, function()
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        return not (q and q.queue and #q.queue > 0)
    end, function() ST.clearActions() end)
end

-- ===========================================================================
local P = ST.P
local flyerId = string.lower(ST.site.flyer)
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    ST.cleanLook()
    ST.parkMouse()
    ST.day(10.0)
    local O = ZeD.Settings
    O.watchPlaceOption:setValue(1)
    O.contextStyleOption:setValue(1)
    O.actionBarOption:setValue(1)
    Z.theme("hicon", "teal")
    say("theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " | profession " .. tostring(p:getDescriptor():getCharacterProfession()))
    Z.closePair()
end)

-- ---- 00 who they are: the Identity and Skills tabs (profession, traits, buckle, skills) ----
if want("00") then
    S.step(2, function() ST.tpSq(P.smoke); ST.face("SE"); Z.openPair() end)
    S.zoomTo(1.0)
    S.poll(10, 120, function() return Z.charTab("identity") end)
    S.step(40, function() Z.place(); Z.shot("story_00a_identity") end)
    S.poll(2, 120, function() return Z.charTab("skills") end)
    S.step(40, function() Z.place(); Z.shot("story_00b_skills") end)
    S.step(2, function() Z.charTab("loot"); Z.closePair() end)
end

-- ---- 01 the old job: the reader on the Fossoil flyer -------------------------------------
if want("01") then
    S.step(2, function() ST.tpSq(P.smoke); ST.face("SE") end)
    S.zoomTo(1.0)
    S.step(20, function()
        Z.ok = ZeD.Reader.openPrint(p, ST.flyerItem) or ZeD.Reader.openPrintId(p, flyerId)
        local r = ZeD.Reader.get(pn)
        if r then r:setView("paper") end
        say("reader open " .. tostring(Z.ok) .. " | read " .. tostring(r and r:isRead()))
    end)
    S.step(60, function() local r = ZeD.Reader.get(pn); if r then Z.box("story_01a reader", r) end; Z.shot("story_01a_flyer_reader") end)
    S.step(2, function() local r = ZeD.Reader.get(pn); if r then r:setView("words") end end)
    S.step(40, function() Z.shot("story_01b_flyer_words") end)
    S.step(2, function() local r = ZeD.Reader.get(pn); if r then r:close() end end)
end

-- ---- 02 the plan: the Journal tab ---------------------------------------------------------
if want("02") then
    S.step(10, function() ST.gt:setTimeOfDay(10.25); Z.openPair() end)
    S.poll(10, 120, function() return Z.charTab("journal") end)
    S.step(10, function()
        local w = Z.CW()
        w._journalSubTab = 1
        w._journalCache = nil
        Z.place()
    end)
    S.step(50, function() Z.shot("story_02a_journal_entry") end)
    S.step(2, function()
        local w = Z.CW()
        w._journalSubTab = 3
        pcall(function() ZeD.JournalReaders.refresh(w) end)
    end)
    S.step(10, function() local w = Z.CW(); w._jr = w._jr or {}; w._jr.paperOpen = flyerId end)
    S.step(50, function() Z.place(); Z.shot("story_02b_journal_flyer_look") end)
    S.step(2, function() local w = Z.CW(); if w._jr then w._jr.paperOpen = nil end; w._journalSubTab = 1; Z.charTab("loot") end)
end

-- ---- 03 the route: the Maps tab ------------------------------------------------------------
if want("03") then
    local M3 = { zoom = STORY_MAPZOOM or 14, tries = 0 }
    S.step(10, function() ST.gt:setTimeOfDay(10.5); Z.openPair() end)
    S.poll(10, 120, function() return Z.worldTab("maps") end)
    S.step(30, function()
        local w = Z.WW()
        pcall(function() ZeD.MapsTab.setStyle(w, "survey") end)
        local loc = PrintMediaDefinitions.MiscDetails[flyerId].location1[1]
        M3.pin = { (loc.x1 + loc.x2) / 2, (loc.y1 + loc.y2) / 2 }
        M3.mid = { (M3.pin[1] + P.centre[1]) / 2, (M3.pin[2] + P.centre[2]) / 2 }
        say(string.format("map: flyer place %d,%d, the store %d,%d", math.floor(M3.pin[1]), math.floor(M3.pin[2]), P.centre[1], P.centre[2]))
    end)
    -- centre between the flyer's place and the store; zoom out until the pin is on the map
    S.poll(10, 1200, function()
        local mp = Z.WW()._worldMapPanel
        if not mp then return false end
        if not M3.set then
            pcall(function() mp.mapAPI:centerOn(M3.mid[1], M3.mid[2]); mp:_zoomTo(M3.zoom) end)
            M3.set, M3.t = true, S.tick
            return false
        end
        if S.tick - M3.t < 90 then return false end
        for _, q in ipairs(mp._flyerPins or {}) do
            if q.id == flyerId then M3.q = q; return true end
        end
        M3.tries = M3.tries + 1
        if M3.tries > 4 then return true end
        M3.zoom = M3.zoom - 1
        M3.set = false
        return false
    end)
    S.step(2, function()
        local mp = Z.WW()._worldMapPanel
        local q = M3.q
        say("map zoom " .. M3.zoom .. " | pin " .. tostring(q ~= nil))
        if q then
            local fx, fy = q.x + math.floor(q.w / 2), q.y + math.floor(q.h / 2)
            mp.isMouseOver = function() return true end
            mp.getMouseX = function() return fx end
            mp.getMouseY = function() return fy end
        end
        Z.place()
    end)
    S.step(40, function()
        local mp = Z.WW()._worldMapPanel
        say("hover card on " .. tostring(mp and mp._flyerHover and mp._flyerHover.id))
        Z.shot("story_03_route_map")
    end)
    S.step(2, function()
        local mp = Z.WW()._worldMapPanel
        if mp then mp.isMouseOver, mp.getMouseX, mp.getMouseY = nil, nil, nil end
        Z.worldTab("loot")
    end)
end

-- ---- 04a driving in: the seat chooser, the dash on low fuel --------------------------------
if want("04") then
    S.step(10, function()
        ST.gt:setTimeOfDay(11.0)
        Z.closePair()
        local v = ST.car
        local q = v and ST.outNear(math.floor(v:getX()), math.floor(v:getY()), 4)
        if q then ST.tpSq(q) end
        ST.face("SE")
    end)
    S.zoomTo(1.0)
    S.step(10, function()
        pcall(function() ISVehicleMenu.onShowSeatUI(p, ST.car) end)
        ZeD.Seats.qaPoint = { seat = 1 }   -- 1-based: the driver
    end)
    S.step(50, function()
        local win = ZeD.Seats.get(pn)
        say("seat chooser " .. tostring(win and win:isVisible()) .. " pointed " .. tostring(win and win:pointedSeat()))
        if win then Z.box("story_04a seats", win) end
        Z.shot("story_04a_seat_chooser")
    end)
    S.step(2, function()
        ZeD.Seats.qaPoint = nil
        local win = ZeD.Seats.get(pn)
        if win and win:isVisible() then win:close() end
        Z.entered = Z.enterCar()
        say("in the car " .. tostring(Z.entered))
    end)
    Z.engineOn()
    S.step(30, function() Z.lights(false) end)
    S.step(150, function() Z.dashInfo("dash low fuel"); if Z.entered then Z.shot("story_04a_dash_low_fuel") else S.err("story_04a_dash_low_fuel", "not seated") end end)
    S.step(2, function() Z.engineOff() end)
    S.step(30, function() Z.exitCar() end)
end

-- ---- 04b the flat: the Vehicle tab, the tire install ---------------------------------------
if want("04b") then
    local MT = ZeD.MechanicsTab
    local T4 = {}
    S.step(30, function()
        ST.gt:setTimeOfDay(11.5)
        Z.theme("hicon", "teal")
        local v = ST.car
        -- the tire nearest the camera (largest x + y of its area) comes off: the spare goes in the inventory
        local best, bs = nil, -1e9
        for _, id in ipairs({ "TireFrontLeft", "TireFrontRight", "TireRearLeft", "TireRearRight" }) do
            local part = v:getPartById(id)
            if part and part:getInventoryItem() then
                local ac = nil
                pcall(function() ac = v:getAreaCenter(part:getArea()) end)
                if ac and ac:getX() + ac:getY() > bs and ST.free(ST.sqAt(math.floor(ac:getX()), math.floor(ac:getY()))) then best, bs = part, ac:getX() + ac:getY() end
            end
        end
        if not best then S.err("story_04b", "no tire with a clear square beside it"); return end
        local item = best:getInventoryItem()
        best:setInventoryItem(nil)
        pcall(function() Vehicles.UninstallComplete.Tire(v, best, item) end)
        pcall(function() v:transmitPartItem(best) end)
        pcall(function() item:setCondition(item:getConditionMax()) end)
        -- the spare in the bag is always an Old tire (Oct 28 2026): the car's own tires are random, and
        -- a long name like Tire - Performance is cut to "TIRE - PERFORMA.." on the action bar plate
        local size = tostring(item:getFullType()):match("Tire(%d)$")   -- Base.ModernTire2: the car's wheel size
        if size and item:getFullType() ~= "Base.OldTire" .. size then
            item = ST.inv:AddItem("Base.OldTire" .. size)
            pcall(function() item:setCondition(item:getConditionMax()) end)
        else
            ST.inv:AddItem(item)
        end
        T4.part, T4.id = best, best:getId()
        say("tire off: " .. tostring(T4.id) .. " (" .. item:getFullType() .. " in the inventory)")
        Z.closePair()
        ISVehicleMenu.onMechanic(p, v)
    end)
    S.poll(10, 2400, function()
        local w = Z.WW()
        return MT.isInspected(ST.car) and w and w._activeTab == "vehicle"
    end, function() say("note: the inspection did not open the Vehicle tab") end)
    S.step(30, function()
        local w = Z.WW()
        if not (w and T4.id) then return end
        local s = MT.getState(w)
        s.view, s.card, s.verb, s.confirm, s.cardScroll, s.pick, s.fixPick = "card", T4.id, "install", nil, 0, 1, 1
        s.items, s.needsCache, s.fixCache, s.partsCache = nil, nil, nil, nil
        if not CWm.isOpen() then CWm.toggle(pn) end
        Z.place()
        ST.face("SE")
    end)
    S.step(60, function() Z.place(); Z.shot("story_04b_vehicle_tab_tire") end)
    S.step(2, function()
        local w = Z.WW()
        local s = w and MT.getState(w)
        local z = s and s.byId and s.byId["mech:verb:install"]
        say("install button " .. tostring(z ~= nil) .. " | verb " .. tostring(s and s.verb))
        if z then z.fn() end
        if CWm.isOpen() then CWm.toggle(pn) end
    end)
    Z.actionShot("story_04b_tire_install_bar", "ISInstallVehiclePart", 0.35, nil, 3000)
    Z.waitIdle(2400)
    S.step(10, function()
        local it = T4.part and T4.part:getInventoryItem()
        say("tire back on: " .. tostring(it ~= nil))
        local w = Z.WW()
        if w then local s = MT.getState(w); s.view, s.card = "overview", nil end
        Z.closePair()
    end)
end

-- ---- 05 barricading --------------------------------------------------------------------
if want("05") then
    local B5 = {}
    S.step(10, function()
        ST.gt:setTimeOfDay(12.0)
        Z.theme("hicon", "teal")
        Z.closePair()
        if not P.win then S.err("story_05", "no window"); return end
        ST.tpSq(P.win.out)
        pcall(function() p:faceThisObject(P.win.o) end)
    end)
    S.zoomTo(0.75)
    S.step(20, function()
        if not P.win then return end
        local sx, sy = Z.screenOf(P.win.x, P.win.y, 0)
        if Mouse and Mouse.setXY then pcall(function() Mouse.setXY(sx, sy) end) end
        local objs = {}
        local sq = ST.sqAt(P.win.x, P.win.y)
        for i = 0, sq:getObjects():size() - 1 do objs[#objs + 1] = sq:getObjects():get(i) end
        ISWorldObjectContextMenu.createMenu(pn, objs, sx, sy)
        local names = {}
        pcall(function() for _, o in ipairs(getPlayerContextMenu(pn).options) do names[#names + 1] = tostring(o.name) end end)
        say("world menu: " .. table.concat(names, " | "))
    end)
    S.step(10, function()
        local m = Z.zm()
        if not m then S.err("story_05a", "no ZeD menu"); return end
        -- Barricade (Planks) sits in the Window submenu: pick Window, open it
        local items = m._ctx and m._ctx.items or {}
        for i = 1, #items + 1 do
            local cur = m._ctx.items[m._ctx.selected]
            if cur and tostring(cur.name):find(getText("ContextMenu_Window"), 1, true) then B5.win = true; break end
            m:next()
        end
        if B5.win then m:confirm() end
    end)
    S.step(6, function()
        local m = Z.zm()
        if not m then return end
        local names = {}
        for i = 1, #(m._ctx.items or {}) + 1 do
            local cur = m._ctx.items[m._ctx.selected]
            if cur and tostring(cur.name):find(getText("ContextMenu_Barricade"), 1, true) then B5.sel = true; break end
            m:next()
        end
        for _, d in ipairs(m._ctx.items or {}) do names[#names + 1] = tostring(d.name) end
        say("window submenu " .. tostring(B5.win) .. ": " .. table.concat(names, " | ") .. " | barricade picked " .. tostring(B5.sel))
    end)
    S.step(20, function() Z.shot("story_05a_barricade_menu") end)
    S.step(2, function()
        local m = Z.zm()
        if m then m:close() end
        ST.parkMouse()
        if not P.win then return end
        -- the hammer in the right hand, a plank in the left; three planks queued back to back
        p:setPrimaryHandItem(ST.find("Base.Hammer"))
        p:setSecondaryHandItem(ST.find("Base.Plank"))
        for k = 1, 3 do
            local a = ISBarricadeAction:new(p, P.win.o, false, false)
            -- the next plank goes in the left hand between planks (the action empties it)
            a.isValid = function(self)
                if not self.character:getSecondaryHandItem() then
                    local pl = ST.find("Base.Plank")
                    if pl then self.character:setSecondaryHandItem(pl) end
                end
                if ISBarricadeAction.isValid(self) then return true end
                -- B42: a Base.Hammer in hand does not answer the legacy hasEquippedTag(ItemType.HAMMER)
                -- (the menu's own path is the build system); the rest of vanilla's check as is
                local b = self.item:getBarricadeForCharacter(self.character)
                return self.item:getObjectIndex() ~= -1 and (b == nil or b:canAddPlank())
                    and self.character:hasEquipped("Plank") and self.character:getInventory():getItemCount("Base.Nails", true) >= 2
            end
            ISTimedActionQueue.add(a)
        end
    end)
    Z.actionShot("story_05b_barricade_bar", "ISBarricadeAction", 0.4, 2, 2400)
    Z.waitIdle(1800)
    S.step(10, function()
        local n = 0
        pcall(function() local b = P.win.o:getBarricadeForCharacter(p); if b then n = b:getNumPlanks() end end)
        say("planks on the window: " .. n)
        pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    end)
end

-- ---- 06 cleaning up -------------------------------------------------------------------
if want("06") then
    S.step(10, function()
        ST.gt:setTimeOfDay(13.0)
        Z.closePair()
        local b = P.blood
        local q = nil
        for _, o in ipairs({ { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, 0 }, { 0, -1 }, { 0, 2 }, { 2, 0 } }) do
            local x, y = b[1] + o[1], b[2] + o[2]
            if not q and ST.inRoom(x, y) and ST.free(ST.sqAt(x, y)) then q = { x, y } end
        end
        ST.tpSq(q or b)
        ISWorldObjectContextMenu.doCleanBlood(p, ST.sqAt(b[1], b[2]))
    end)
    S.zoomTo(0.75)
    Z.actionShot("story_06_clean_blood_bar", "ISCleanBlood", 0.4, nil, 2400)
    Z.waitIdle(1800)
    S.step(10, function()
        local left = false
        pcall(function() left = ST.sqAt(P.blood[1], P.blood[2]):haveStains() end)
        say("stains left on the square: " .. tostring(left))
        pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    end)
end

-- ---- 07 stocking the shelves -------------------------------------------------------------
if want("07") then
    S.step(10, function()
        ST.gt:setTimeOfDay(13.5)
        ST.tpSq(P.stock)
        ST.face("SE")
        Z.openPair()
    end)
    S.zoomTo(1.0)
    S.step(30, function()
        Z.charTab("loot"); Z.worldTab("loot")
        local w = Z.WW()
        if w then w._containerTimer = 30 end
    end)
    S.step(40, function()
        Z.mcWorld = Z.shelfInvs()
        say("shelves in the World window's reach: " .. #Z.mcWorld)
    end)
    S.poll(10, 600, function() return Z.mc(true) end, function() say("note: not every column came on") end)
    S.step(40, function()
        Z.place()
        local c, w = Z.CW(), Z.WW()
        say(string.format("columns: char %d world %d", #(c._mcSelected or {}), #(w._mcSelected or {})))
    end)
    S.step(20, function() Z.place(); Z.shot("story_07a_shelves_columns") end)
    S.step(2, function()
        local ok, why = Z.drag(true)
        if not ok then S.err("story_07b", why) end
    end)
    S.step(20, function() Z.shot("story_07b_drag_to_shelf") end)
    S.step(2, function() Z.drag(false); ST.parkMouse() end)
    S.step(2, function() Z.mc(false) end)
    S.poll(10, 300, function() return Z.mc(false) end)
end

-- ---- 08 open for business: the window box's menu -----------------------------------------
if want("08") then
    S.step(10, function()
        ST.gt:setTimeOfDay(14.0)
        ST.tpSq(P.stock)
        Z.openPair()
        Z.charTab("loot"); Z.worldTab("loot")
    end)
    -- a) the pointer on the World window's box: the box lit
    S.step(30, function() Z.place(); Z.hoverBox(Z.WW()) end)
    S.step(20, function()
        local w = Z.WW()
        say("window box under the pointer: lit " .. tostring(w and w._wboxHover))
        Z.shot("story_08a_footer_before")
    end)
    -- b) the menu pulled down, Theme open, the pointer on Light; then the click on Light
    Z.menuPick(Z.WW, ZeD.tr("UI_ZeD_WinMenu_Theme"), Z.leafName("base", "light"), "story_08b_footer_light")
    S.step(2, function() say("theme " .. tostring(ZeD.currentBase)) end)
    -- c) the Character window's Accent > Blue first (no shot), then the World window's menu
    -- with Accent open and the pointer on Blue; then the click on Blue. On these two windows
    -- the Accent choice sets the window's own accent.
    Z.menuPick(Z.CW, ZeD.tr("UI_ZeD_WinMenu_Accent"), Z.leafName("accent", "blue"), nil)
    Z.menuPick(Z.WW, ZeD.tr("UI_ZeD_WinMenu_Accent"), Z.leafName("accent", "blue"), "story_08c_footer_blue")
    S.step(2, function()
        -- the rest of the UI (belt, watch, menus, the action bar) to the same blue, in memory
        if STORY_GLOBAL_BLUE ~= false then ZeD.applyTheme(nil, "blue", nil) end
        say("accent: char " .. tostring(Z.CW()._accentKey) .. " world " .. tostring(Z.WW()._accentKey) .. " global " .. tostring(ZeD.currentAccent))
    end)
    -- d) the pointer parked, Light + Blue
    S.step(2, function() ST.parkMouse() end)
    S.step(30, function() Z.place(); Z.shot("story_08d_open_light_blue") end)
end

-- ---- 09 pumping gas ------------------------------------------------------------------------
if want("09") then
    local F9 = {}
    S.step(10, function()
        ST.gt:setTimeOfDay(14.5)
        Z.lightBlue()
        Z.closePair()
        local v = ST.car
        local tank = v and v:getPartById("GasTank")
        F9.tank = tank
        local ac = nil
        pcall(function() ac = v:getAreaCenter(tank:getArea()) end)
        if ac then ST.tp(ac:getX(), ac:getY(), 0) end
        pcall(function() F9.pump = ISVehiclePartMenu.getNearbyFuelPump(v) end)
        local inA = false
        pcall(function() inA = v:isInArea(tank:getArea(), p) end)
        say("refuel: in the gas tank area " .. tostring(inA) .. " | pump " .. tostring(F9.pump ~= nil) .. " reads " .. tostring(F9.pump and F9.pump:getPipedFuelAmount()))
        if F9.pump and tank then ISTimedActionQueue.add(ISRefuelFromGasPump:new(p, tank, F9.pump)) end
    end)
    S.zoomTo(0.75)
    Z.actionShot("story_09a_refuel_car_bar", "ISRefuelFromGasPump", 0.15, nil, 2400)
    S.step(2, function()
        ST.clearActions()
        -- the rest of the tank filled (the action at speed 1 takes about a minute)
        pcall(function() F9.tank:setContainerContentAmount(F9.tank:getContainerCapacity() * 0.95); ST.car:transmitPartModData(F9.tank) end)
        -- the gas can: beside the pump, in the left hand
        local pump = F9.pump or (P.pump and P.pump.o)
        local q = pump and ST.outNear(pump:getSquare():getX(), pump:getSquare():getY(), 2)
        if q then ST.tpSq(q) end
        F9.can = ST.find("Base.PetrolCan")
        if F9.can then p:setSecondaryHandItem(F9.can) end
        if pump and F9.can then ISTimedActionQueue.add(ISTakeFuel:new(p, pump, F9.can)) end
        Z.openPair()
        Z.charTab("loot")
    end)
    S.step(30, function() Z.place(); if F9.can then Z.selectItem(F9.can) end end)
    Z.actionShot("story_09b_gas_can_card", "ISTakeFuel", 0.35, nil, 2400)
    S.step(2, function()
        ST.clearActions()
        Z.selectItem(nil)
        Z.closePair()
        pcall(function() p:setSecondaryHandItem(nil) end)
        Z.entered = Z.enterCar()
    end)
    S.zoomTo(1.0)
    Z.engineOn()
    S.step(30, function() Z.lights(false) end)
    S.step(150, function() Z.dashInfo("dash refuelled"); if Z.entered then Z.shot("story_09c_dash_fuel_full") end end)
    S.step(2, function() Z.engineOff() end)
    S.step(30, function() Z.exitCar() end)
end

-- ---- 10 customers ----------------------------------------------------------------------------
if want("10") then
    S.step(10, function()
        ST.gt:setTimeOfDay(15.0)
        Z.lightBlue()
        Z.closePair()
        ST.tpSq(P.clerk)
        say("queue zombies: " .. ST.queueZombies(true))
    end)
    S.zoomTo(0.75)
    S.step(60, function()
        ST.face(Z.dirTo(P.queueDir))
        for _, z in ipairs(ST.A.queue) do pcall(function() z:faceLocation(P.clerk[1] + 0.5, P.clerk[2] + 0.5) end) end
    end)
    S.step(30, function() Z.shot("story_10_customers_queue") end)
end

-- ---- 11 smoke break --------------------------------------------------------------------------
if want("11") then
    local M11 = {}
    S.step(10, function()
        ST.gt:setTimeOfDay(16.0)
        ST.queueZombies(false)
        Z.closePair()
        ST.tpSq(P.smoke)
        ST.face("SE")
        Z.lightBlue()
        -- god mode clears the stats every tick: held while the beat lasts, so the right edge
        -- shows a few moodles (stressed, peckish, thirsty, bored) and the hover is on one of them
        -- (director, Oct 25 2026: "show the moodles, so it looks like you are hovering over one")
        M11.hold = function() pcall(function()
            local s = p:getStats()
            s:set(CharacterStat.STRESS, 0.55); s:set(CharacterStat.HUNGER, 0.3)
            s:set(CharacterStat.THIRST, 0.3); s:set(CharacterStat.BOREDOM, 0.5)
        end) end
        Events.OnTick.Add(M11.hold)
        ZeD.Watch.togglePop(true)
    end)
    S.zoomTo(0.5)
    S.step(30, function()
        local cig = ST.find("Base.CigaretteSingle")
        if cig then ISInventoryPaneContextMenu.eatItem(cig, 1, pn) else S.err("story_11", "no cigarette") end
        local inst = ZeD.Watch.getInstance()
        if inst then inst._popTouched = getTimestampMs() end
    end)
    S.poll(5, 1800, function()
        local a, t, d = ST.action()
        return (t == "ISEatFoodAction" or t == "ISTakePillAction") and d >= 0.25
    end, function() say("note: no smoking action in progress") end)
    S.step(2, function()
        -- the hover on the Stressed moodle (ZeD's hover text reads the layer's mouse only)
        local L = ZeD.Moodles and ZeD.Moodles.getLayer(pn)
        if not L then return end
        local idx = nil
        for i, e in ipairs(L._list or {}) do if tostring(e.key):upper():find("STRESS", 1, true) then idx = i end end
        idx = idx or 1
        local s = L._size or 32
        local lx, ly = s / 2, (idx - 1) * (s + 10) + s / 2
        if L._mode == "bottom" then lx, ly = (idx - 1) * (s + 10) + s / 2, s / 2 end
        L.getMouseX = function() return lx end
        L.getMouseY = function() return ly end
        M11.L = L
        local keys = {}
        for _, e in ipairs(L._list or {}) do keys[#keys + 1] = tostring(e.key) end
        say("moodles: " .. table.concat(keys, " ") .. " | hover on " .. idx)
        local inst = ZeD.Watch.getInstance()
        if inst then inst._popTouched = getTimestampMs() end
    end)
    S.step(20, function() Z.shot("story_11_smoke_break") end)
    S.step(2, function()
        if M11.L then M11.L.getMouseX, M11.L.getMouseY = nil, nil end
        if M11.hold then Events.OnTick.Remove(M11.hold); M11.hold = nil end
        ST.clearActions()
        pcall(function() ZeD.Watch.togglePop(false) end)
    end)
end

-- ---- 12 night shift ---------------------------------------------------------------------------
if want("12") then
    S.step(10, function()
        ST.night()
        say("store lights switched on: " .. ST.lights(true))
        -- the window menu's Theme choice, Dark (or High contrast). The windows are shut at this
        -- point (and closed again just below), so there is no box to pull the menu from: the
        -- choice the menu builds is fired directly.
        local target = STORY_NIGHT_BASE or "dark"
        local how = (ZeD.currentBase ~= target) and Z.fireTheme(target) or "nothing to do"
        say("night theme " .. tostring(ZeD.currentBase) .. " (" .. how .. ")")
        Z.closePair()
        local q = ST.outNear(P.smoke[1] + 2, P.smoke[2] + 2, 4) or P.smoke
        ST.tpSq(q)
        ST.face("NW")
    end)
    S.zoomTo(1.25)
    S.waitMs(4000)
    S.step(10, function() Z.shot("story_12a_store_night") end)
    S.step(2, function() Z.entered = Z.enterCar() end)
    S.zoomTo(1.0)
    Z.engineOn()
    S.step(30, function() Z.lights(true) end)
    S.waitMs(3000)
    S.step(10, function() Z.dashInfo("dash night"); if Z.entered then Z.shot("story_12b_dash_night") end end)
    S.step(2, function() Z.lights(false); Z.engineOff() end)
    S.step(30, function() Z.exitCar() end)
    S.step(30, function()
        ST.tpSq(P.smoke)
        ST.face("SE")
        ZeD.Watch.togglePop(true)
    end)
    S.zoomTo(0.5)
    S.step(20, function()
        local inst = ZeD.Watch.getInstance()
        local lit = false
        if inst then
            inst._popTouched = getTimestampMs()
            -- the LIGHT pusher through the watch's own mouse handler (as zedqa_cazio_light.lua), else its action
            local h = nil
            for _, q in ipairs(inst._hit or {}) do if q.id == "light" then h = q end end
            if h then pcall(function() inst:onMouseDown(h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)) end) end
            if not ((inst._litUntil or 0) > getTimestampMs()) then pcall(function() inst:_act("light") end) end
            lit = (inst._litUntil or 0) > getTimestampMs()
        end
        say("watch " .. tostring(inst and inst._item and inst._item:getFullType()) .. " | has a light " .. tostring(inst and ZeD.Watch.hasLight(inst._def)) .. " | lit " .. tostring(lit))
    end)
    S.step(25, function() Z.shot("story_12c_watch_light") end)
    S.step(2, function() pcall(function() ZeD.Watch.togglePop(false) end) end)
    S.zoomTo(1.0)
    S.step(10, function() ST.tpSq(P.stock); Z.openPair(); Z.charTab("loot"); Z.worldTab("loot") end)
    S.step(40, function() Z.place(); Z.shot("story_12d_windows_night") end)
end

-- ---- end: the windows shut, the queue gone, the mouse parked (the teardown puts the rest back) ----
S.step(10, function()
    ST.clearActions()
    ST.queueZombies(false)
    Z.drag(false)
    pcall(function() ZeD.Watch.togglePop(false) end)
    ST.parkMouse()
    say("theme now " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " (the teardown re-applies the options)")
end)
S.start()
