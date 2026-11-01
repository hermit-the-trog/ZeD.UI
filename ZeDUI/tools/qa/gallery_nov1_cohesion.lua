-- ZeDUI/tools/qa/gallery_nov1_cohesion.lua  (Nov 1 2026, QA)
-- The Workshop gallery retake (workshop/gallery/REVIEW_20261101.md, "Retakes" 4 and 10), the cohesion walk's
-- pictures for pages 15-17: zedqa_cohesion_walk.lua's steps for these shots only, with its screenshot names, so the
-- gallery's shots.json keeps working. Runs in the mall lot like the t14 walk did (after gallery_v3_stage.lua, before
-- gallery_v3_teardown.lua: it uses GAL's sequencer), both windows as tall as the screen allows, the default look.
--   page 15  zqa_cw_01_dark_small_card                both windows, the apple's card open (dark, small text)
--            zqa_cw_01b_help_line                     the same, the pointer on the Character window's Inventory button
--                                                     on the bag strip: the footer help line in plain words
--            zqa_cw_02_dark_small_window_menu_theme   the window box's menu down, Theme open, the pointer on Dark
--   page 16  zqa_cw_08_seethrough_100, zqa_cw_12_seethrough_60   (the apple's card open, the world behind)
--            zqa_cw_12b_solid_in_use                  see-through 60, Solid while in use on, the pointer on the
--                                                     Character window's title bar (that window solid, World see-through)
--   page 17  zqa_cw_14_focus_hand_inventory_row, zqa_cw_16_focus_corners_inventory_row,
--            zqa_cw_18_focus_wash_inventory_row, zqa_cw_20_focus_ants_inventory_row
--                                                     the inventory as a LIST, no card, the pad's focus on one row
-- Every shot prints "shot <name> | what it shows | the live settings" and the windows' rects ("rect <name> ...").
-- Adds three apples and a hammer (taken away after). Puts back: the theme, see-through, Solid while in use, the
-- highlight style, the List | Grid choice, the input mode, the card, heights, places, tabs, the options file.
-- "ZEDQA n1c ..." ending "ZEDQA n1c DONE".
local G = GAL
if not (G and G.newSeq and G.p) then print("ZEDQA n1c ERR run gallery_v3_core.lua first (its sequencer)"); print("ZEDQA n1c DONE"); return end
if not (ZeD and ZeD.applyTheme and ZeD.Settings and ZeD.Settings.setSeeThrough and ZeD.Settings.setSolidInUse
        and ZeD.Settings.setFocusStyle and ZeD.Input and ZeD.Input.Focus and ZeD.Input.Detector
        and ZeD_CharacterWindow and ZeD_WorldWindow) then
    print("ZEDQA n1c ERR ZeD is not loaded, or it is older than the cohesion pass"); print("ZEDQA n1c DONE"); return
end
local S = G.newSeq("n1c", 600000)
local say = S.say
local p, pn, core = G.p, G.pn, G.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local F, D = ZeD.Input.Focus, ZeD.Input.Detector
local B = { items = {}, was = {} }

-- ---------------------------------------------------------------------------
-- windows (zedqa_cohesion_walk.lua's, with gallery_v3_zed.lua's Z.tall)
-- ---------------------------------------------------------------------------
function B.CW() return CWm.getWindow() end
function B.WW() return WWm.getWindow() end
function B.place()
    local c, w = B.CW(), B.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) or w._rolled then return false end
    if not B.lock then
        local gap = ZeD.T.px(8)
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        B.lock = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap, cy = c:getY(), wy = w:getY() }
    end
    c._anchorRightEdge = B.lock.right
    c:setX(B.lock.right - c:getWidth()); w:setX(B.lock.left)
    c:setY(B.lock.cy); w:setY(B.lock.wy)
    return true
end
function B.openPair()
    if not (CWm.isOpen() and WWm.isOpen()) then
        if WWm.isOpen() then WWm.close() end
        if CWm.isOpen() then CWm.toggle(pn) end
        CWm.toggleBothPaired(pn)
    end
    B.place()
end
function B.tall()
    local c, w = B.CW(), B.WW()
    if not (c and w) then return end
    if not B.was.heights then
        B.was.heights = { c = { c:getX(), c:getY(), c:getHeight() }, w = { w:getX(), w:getY(), w:getHeight() } }
    end
    local m = ZeD.T.px(12)
    local h = core:getScreenHeight() - 2 * m
    B.lock = nil
    for _, win in ipairs({ c, w }) do
        win:setY(m); win:setHeight(h)
        pcall(function() win:onResize() end)
    end
    B.place()
end
function B.untall()
    local c, w = B.CW(), B.WW()
    local s = B.was.heights
    if not s then return end
    if c then c:setHeight(s.c[3]); pcall(function() c:onResize() end); c:setX(s.c[1]); c:setY(s.c[2]) end
    if w then w:setHeight(s.w[3]); pcall(function() w:onResize() end); w:setX(s.w[1]); w:setY(s.w[2]) end
    B.lock, B.was.heights = nil, nil
end
function B.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function B.charTab(id) local w = B.CW(); return (w and B.goTab(w, w._tabStripPanel, id)) and true or false end
function B.worldTab(id) local w = B.WW(); return (w and B.goTab(w, w._actionTabStrip, id)) and true or false end
-- what "still" compares: each window's place, size, drawer width and see-through fade
function B.shape()
    local t = {}
    for _, win in ipairs({ B.CW() or false, B.WW() or false }) do
        if win and win:isVisible() then
            local dp = win._drawerPanel
            t[#t + 1] = string.format("%d,%d,%d,%d,%d,%d,%d", math.floor(win:getX()), math.floor(win:getY()), math.floor(win:getWidth()),
                math.floor(win:getHeight()), math.floor(win._drawerEffW or 0), dp and math.floor(dp:getWidth()) or 0, math.floor((win._seeA or 0) * 100))
        end
    end
    return table.concat(t, ";")
end
function B.still(n, max)
    local last, same = nil, 0
    S.poll(1, max or 600, function()
        local s = B.shape()
        if s == last then same = same + 1 else same, last = 0, s end
        return same >= (n or 30)
    end, function() say("note: the windows were still moving after " .. tostring(max or 600) .. " frames; going on") end)
end
function B.rect(name, which)
    local win = (which == "c") and B.CW() or B.WW()
    local dp = win and win._drawerPanel
    if not (win and dp) then say("rect " .. name .. " " .. which .. " none"); return end
    local fh = 0
    pcall(function() fh = win:footerHeight() end)
    say(string.format("rect %s %s drawer %d %d %d %d window %d %d %d %d header %d footer %d tab %s",
        name, (which == "c") and "char" or "world",
        math.floor(dp:getAbsoluteX()), math.floor(dp:getAbsoluteY()), math.floor(dp:getWidth()), math.floor(dp:getHeight()),
        math.floor(win:getAbsoluteX()), math.floor(win:getAbsoluteY()), math.floor(win:getWidth()), math.floor(win:getHeight()),
        math.floor(ZeD.Molecules.getTabHeaderH()), math.floor(fh), tostring(win._activeTab)))
end

-- ---------------------------------------------------------------------------
-- the pointer, the window box's menu, the shot (as the walk)
-- ---------------------------------------------------------------------------
function B.pointAt(x, y)
    if Mouse and Mouse.setXY then pcall(function() Mouse.setXY(math.floor(x), math.floor(y)) end) end
end
function B.parkPos(k)
    local sw, sh = core:getScreenWidth(), core:getScreenHeight()
    return math.floor(sw * 0.03) + ((k == 2) and math.floor(sw * 0.04) or 0), math.floor(sh * 0.5)
end
function B.park() B.parkK = 1; B.pointAt(B.parkPos(1)) end
function B.nudge() B.parkK = (B.parkK == 1) and 2 or 1; B.pointAt(B.parkPos(B.parkK)) end
-- (Nov 1 2026, the fixes after the first run) a real pointer rest: the pointer walks onto (x, y) in 2 px steps for
-- the first half of ms (the engine's UI tick runs every 100 ms and only a move it sees counts), then holds still
-- there; getXY is asked each frame (nil: give up)
function B.restOn(getXY, ms)
    local R = {}
    S.poll(1, math.floor(ms / 3) + 900, function()
        local now = getTimestampMs()
        if not R.t0 then R.t0, R.n = now, 0 end
        local x, y = getXY()
        if not x then return true end
        R.n = R.n + 1
        if now - R.t0 < ms / 2 then
            if R.n % 4 == 0 then B.pointAt(x + ((((R.n / 4) % 2) == 0) and 2 or 0), y) end
        else
            B.pointAt(x, y)
        end
        return now - R.t0 >= ms
    end)
end
-- pred true for n frames running (max frames, then a note and on)
function B.waitFor(label, pred, n, max)
    local R = { n = 0 }
    S.poll(1, max or 180, function()
        local ok = false
        pcall(function() ok = pred() == true end)
        if ok then R.n = R.n + 1 else R.n = 0 end
        return R.n >= (n or 6)
    end, function() say("note: " .. label .. ": not reached") end)
end
-- the top-level UI elements drawn above win that hold the point (what makes pointerOn false), for the log
function B.coverAt(x, y, win)
    local out = {}
    pcall(function()
        local ui = UIManager.getUI()
        local jo = win and win.javaObject
        local seen = jo == nil
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if seen and e ~= jo and e:isVisible() and e:isPointOver(x, y) then
                local t = nil
                pcall(function() t = e:getTable() and e:getTable().Type end)
                out[#out + 1] = tostring(t or e:getClass():getSimpleName())
            end
            if e == jo then seen = true end
        end
    end)
    if #out == 0 then return "nothing" end
    return table.concat(out, ", ")
end
function B.boxRect(win)
    local b = win and win.windowBoxRect and win:windowBoxRect()
    if not b then return nil end
    local ax, ay = win:getAbsoluteX(), win:getAbsoluteY()
    return math.floor(ax + b.x), math.floor(ay + b.y), math.floor(ax + b.x + b.w), math.floor(ay + b.y + b.h)
end
function B.hoverBox(win)
    local x0, y0, x1, y1 = B.boxRect(win)
    if x0 then B.pointAt((x0 + x1) / 2, (y0 + y1) / 2) end
end
function B.leafName(kind, key)
    local Sx = ZeD.Settings
    local keys, labels = Sx.baseKeys, Sx.baseLabels
    if kind == "accent" then keys, labels = Sx.accentKeys, Sx.accentLabels end
    for i, k in ipairs(keys or {}) do
        if k == key then return ZeD.tr(labels[i]) end
    end
    return tostring(key)
end
function B.menu()
    local m = ZeD.WindowMenu and ZeD.WindowMenu.current
    return (m and m._ctx and m._ctx.open) and m or nil
end
function B.menuRow(li, name)
    local m = B.menu()
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
function B.menuHover(li, name)
    local zn = B.menuRow(li, name)
    if zn then B.pointAt(zn.x + zn.w / 2, zn.y + zn.h / 2) end
    return zn ~= nil
end
function B.menuClick(li, name)
    local m, zn = B.menu(), B.menuRow(li, name)
    if not (m and zn) then return false end
    m:onMouseUp(math.floor(zn.x + zn.w / 2), math.floor(zn.y + zn.h / 2))
    return true
end
function B.live()
    local St = ZeD.Settings
    local function try(fn, dflt)
        local ok, v = pcall(fn)
        if ok and v ~= nil then return tostring(v) end
        return dflt
    end
    return string.format("theme %s, accent %s, size %s | see-through %s | solid while in use %s | highlight %s | input mode %s | grid %s",
        tostring(ZeD.currentBase), tostring(ZeD.currentAccent), tostring(ZeD.currentSize),
        try(St.seeThrough, "?"), try(function() return St.solidInUse() and "on" or "off" end, "?"),
        try(St.focusStyle, "?"), try(D.getMode, "?"), try(function() return ZeD.InventoryRenderer.isGridKey("player") end, "?"))
end
function B.shotNow(name, what)
    local ok, txt = pcall(function() if type(what) == "function" then return what() end return what end)
    if not ok then txt = "(no description: " .. tostring(txt) .. ")" end
    say("shot " .. name .. " | " .. tostring(txt) .. " | " .. B.live())
    S.shot(name)
    B.rect(name, "c"); B.rect(name, "w")
end
function B.snap(name, what)
    S.step(2, function() B.shotNow(name, what) end)
    S.step(20, function() end)
end

-- ---------------------------------------------------------------------------
-- items, card, pad (as the walk)
-- ---------------------------------------------------------------------------
function B.addItem(fullType)
    local it = p:getInventory():AddItem(fullType)
    if it then B.items[#B.items + 1] = it end
    return it
end
function B.removeItems()
    for i = #B.items, 1, -1 do
        local it = B.items[i]
        pcall(function()
            local c = it:getContainer()
            if c then c:Remove(it) end
        end)
    end
    B.items = {}
    B.apple, B.hammer = nil, nil
    pcall(function() ISInventoryPage.dirtyUI() end)
end
function B.selectItem(item)
    local w = B.CW()
    local c = w and w._mainContent
    if not (c and w._updateDrawer) then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
function B.padTouch(w) F.dispatchJoypadDown(w, "QA") end
function B.zoneOf(w, name)
    for i, z in ipairs(w and w._focusRing or {}) do
        if z.zone == name then return i, z end
    end
    return nil, nil
end
function B.findEl(w, pred)
    for _, z in ipairs(w and w._focusRing or {}) do
        if z.focusable then
            for _, e in ipairs(z.elements or {}) do
                if pred(e) then return e, z.zone end
            end
        end
    end
    return nil, nil
end
function B.focusOn(w, pred)
    if not w then return nil end
    F.claimFocus(w)
    local e, zone = B.findEl(w, pred)
    if not e then return nil end
    local got = F.focusWhere(w, zone, function(x) return x == e end)
    if got then B.padTouch(w) end
    return got
end
function B.focusDesc(w)
    local z, e = F.getFocusedZone(w), F.getFocusedElement(w)
    return string.format("pad on zone %s, element %s, cues %s", tostring(z and z.zone), tostring(e and e.id),
        tostring(F.cuesVisible and F.cuesVisible()))
end
-- an inventory row on screen now (the hammer's when it is), else the first row
function B.pickRow(w, prefer)
    local _, z = B.zoneOf(w, "charMainInv")
    if not (z and z.focusable) then return nil end
    local ch = (w._mainContent and w._mainContent:getHeight()) or 0
    local pref, firstVis, firstAny
    for _, e in ipairs(z.elements or {}) do
        if e.item then
            firstAny = firstAny or e
            if ch > 0 and e.y >= 0 and e.y + e.h <= ch then
                firstVis = firstVis or e
                if prefer and e.item == prefer and not pref then pref = e end
            end
        end
    end
    return pref or firstVis or firstAny
end

-- ---------------------------------------------------------------------------
-- the snapshot and the put-back
-- ---------------------------------------------------------------------------
function B.snapshot()
    local W = B.was
    local St = ZeD.Settings
    W.base, W.accent, W.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    W.see = St.seeThroughIndex and St.seeThroughIndex() or nil
    W.solid = St.solidInUse and St.solidInUse() or false
    W.focus = St.focusStyle and St.focusStyle() or "hand"
    W.speed = getGameSpeed()
    local s = p:getModData().ZeD_GridViews
    W.gridHad, W.grid = s ~= nil, s and s.player
    W.focusWin = F.getFocusedWindow()
    say(string.format("start: theme %s/%s/%s, see-through index %s, solid %s, highlight %s, grid key %s",
        tostring(W.base), tostring(W.accent), tostring(W.size), tostring(W.see), tostring(W.solid), tostring(W.focus), tostring(W.grid)))
end
function B.try(label, fn)
    local ok, e = pcall(fn)
    if not ok then say("ERR put-back " .. label .. ": " .. tostring(e)) end
end
function B.finish()
    local W = B.was
    local St = ZeD.Settings
    local try = B.try
    try("input mode", function() D.setLockedMode(nil) end)
    try("window menu", function() local m = B.menu(); if m then m:close() end end)
    try("card", function() B.selectItem(nil) end)
    try("added items", function() B.removeItems() end)
    try("grid", function()
        local s = p:getModData().ZeD_GridViews
        if s then s.player = W.grid end
        if not W.gridHad then p:getModData().ZeD_GridViews = nil end
    end)
    try("solid while in use", function() St.setSolidInUse(W.solid) end)
    try("highlight", function() St.setFocusStyle(W.focus) end)
    try("theme", function()
        ZeD.applyTheme(W.base, W.accent, W.size)
        if St.syncToModOptions then St.syncToModOptions() end
    end)
    try("see-through", function() if W.see then St.setSeeThrough(W.see) end end)
    try("options file", function() if St.save then St.save() end end)
    try("tabs", function() B.charTab("loot"); B.worldTab("loot") end)
    try("heights", function() B.untall(); B.openPair() end)
    try("pad focus", function()
        if W.focusWin and W.focusWin.isVisible and W.focusWin:isVisible() then F.claimFocus(W.focusWin)
        elseif F.getFocusedWindow() then F.releaseFocus() end
    end)
    try("pointer", function() B.nudge() end)
    try("game speed", function() if W.speed and W.speed <= 0 then setGameSpeed(W.speed) end end)
    say("put back: the settings, the options file, the windows, the added items")
end

-- ===========================================================================
-- start: snapshot, the look, apples and a hammer, both windows tall on Loot
S.step(2, function()
    if getGameSpeed() <= 0 then pcall(setGameSpeed, 1) end
    B.snapshot()
    pcall(G.cleanLook)
    D.setLockedMode("kbm")
    -- dark / small in the options too (setSeeThrough applies the theme again from the options), the accent the look's
    ZeD.applyTheme("dark", (GAL_LOOK and GAL_LOOK[2]) or ZeD.currentAccent, "small")
    pcall(ZeD.Settings.syncToModOptions)
    B.openPair()
    for _ = 1, 3 do
        local a = B.addItem("Base.Apple")
        B.apple = B.apple or a
    end
    B.hammer = B.addItem("Base.Hammer")
    pcall(function() ISInventoryPage.dirtyUI() end)
    B.park()
    say(string.format("added: apples %s, hammer %s", tostring(B.apple ~= nil), tostring(B.hammer ~= nil)))
end)
B.still(40)
S.step(2, function() B.charTab("loot"); B.worldTab("loot"); B.tall(); B.nudge() end)
B.still(30)
S.step(2, function() B.tall() end)
B.still(30)

-- page 15: the card, the help line, the window menu --------------------------------
S.step(2, function()
    if not B.selectItem(B.apple) then S.err("cw_01", "the inventory pane is not there to pick the apple") end
end)
B.still(30)
S.step(2, function() B.place(); B.park() end)
S.step(10, function() end)
B.snap("zqa_cw_01_dark_small_card", function()
    local w = B.CW()
    return string.format("both windows: Character on its inventory with the apple's card open (card item %s), World on Loot",
        tostring(w and w._drawerItem and w._drawerItem:getDisplayName()))
end)
-- the help line (Nov 1 2026, the fix after the first run: the bag strip's stamp never reached the footer, which kept
-- the item count). The window box, an icon-only button: the window watches the raw pointer on it every frame
-- (ZeD_Window:_watchBoxes sets _wboxHover while pointerOn, the engine's isMouseOver, says no window above holds the
-- pointer) and its own help line draws the box's hint (UI_ZeD_WinMenu_Help) while _wboxHover is set. The Character
-- window is brought to the top first (a click on it would), the pointer walks onto the box and rests 600 ms, and
-- the shot waits until the window reads the hover for 6 frames.
S.step(2, function()
    local c = B.CW()
    if not c then S.err("cw_01b", "no Character window"); return end
    pcall(function() c:bringToTop() end)
end)
B.restOn(function()
    local x0, y0, x1, y1 = B.boxRect(B.CW())
    if not x0 then return nil end
    return math.floor((x0 + x1) / 2), math.floor((y0 + y1) / 2)
end, 600)
B.waitFor("cw_01b: the window box hover", function() local c = B.CW(); return c and c._wboxHover == true end, 6, 240)
S.step(1, function()
    local c = B.CW()
    if c and not c._wboxHover then
        say("note: cw_01b: no hover on the window box (pointer on the window " .. tostring(c:pointerOn()) .. ", above it: "
            .. B.coverAt(getMouseX(), getMouseY(), c) .. ")")
    end
end)
B.snap("zqa_cw_01b_help_line", function()
    local c = B.CW()
    local x0, y0, x1, y1 = B.boxRect(c)
    return string.format("the pointer resting on the Character window's window box (%s,%s-%s,%s): its hover %s, pointer on the window %s; the footer help line shows the box's plain-words help",
        tostring(x0), tostring(y0), tostring(x1), tostring(y1), tostring(c and c._wboxHover), tostring(c and c:pointerOn()))
end)
S.step(2, function() B.park() end)
S.step(10, function() end)
-- the window box's menu: pulled down, Theme opened, the pointer on the theme in use; shut without a pick
S.step(2, function()
    local w = B.CW()
    if not w then S.err("cw_02", "no window to pull the menu from"); return end
    B.hoverBox(w)
    w:openWindowMenu()
end)
S.poll(2, 180, function() return B.menuRow(1, ZeD.tr("UI_ZeD_WinMenu_Theme")) ~= nil end,
    function() S.err("cw_02", "the menu did not draw its Theme row") end)
S.step(2, function() B.menuClick(1, ZeD.tr("UI_ZeD_WinMenu_Theme")) end)
S.poll(2, 180, function() return B.menuRow(2, B.leafName("base", ZeD.currentBase)) ~= nil end,
    function() S.err("cw_02", "the Theme submenu did not draw the theme in use") end)
S.step(2, function() B.menuHover(2, B.leafName("base", ZeD.currentBase)) end)
S.step(12, function() end)
B.snap("zqa_cw_02_dark_small_window_menu_theme",
    "the Character window's window box menu pulled down, its Theme submenu open, the pointer on the theme in use")
S.step(2, function()
    local m = B.menu()
    if m then pcall(function() m:close() end) end
    B.park()
end)
S.step(10, function() end)

-- page 16: see-through 100 and 60, then 60 with Solid while in use -------------------
S.step(2, function() B.place() end)
B.still(30)
function B.seeIdx(v)
    for i, k in ipairs(ZeD.Settings.seeThroughKeys or { 100, 90, 80, 70, 60 }) do if k == v then return i end end
    return nil
end
for _, v in ipairs({ 100, 60 }) do
    S.step(2, function()
        local i = B.seeIdx(v)
        if i then ZeD.Settings.setSeeThrough(i) else S.err("see-through", "no step " .. v) end
        B.park()
    end)
    B.still(30)
    B.snap((v == 100) and "zqa_cw_08_seethrough_100" or "zqa_cw_12_seethrough_60", function()
        return "both windows with the apple's card open at see-through " .. v .. ", the world behind them"
    end)
end
-- Solid while in use (Nov 1 2026, the fix after the first run: both windows stayed see-through). ZeD_Window:_inUse
-- is the pointer on the window (pointerOn: the engine's isMouseOver, false while any window above holds the point)
-- or the controller in it (the pad's focus on it in gamepad mode). The Character window is brought to the top, the
-- pointer walks onto its title bar (nothing there answers a hover) and rests 700 ms, and the shot waits until its
-- surface reads solid (_seeA 0.99) for 6 frames. If the pointer still does not count, the controller path is used
-- (the pad's focus claimed on the Character window in gamepad mode) and the line says so.
S.step(2, function()
    ZeD.Settings.setSolidInUse(true)
    local c = B.CW()
    if c then pcall(function() c:bringToTop() end) end
end)
B.restOn(function()
    local c = B.CW()
    if not c then return nil end
    return c:getAbsoluteX() + math.floor(c:getWidth() * 0.4), c:getAbsoluteY() + math.floor(c:titleBarHeight() / 2)
end, 700)
B.waitFor("cw_12b: the Character window solid under the pointer", function()
    local c = B.CW()
    return c ~= nil and (c._seeA or 0) >= 0.99
end, 6, 120)
S.step(2, function()
    local c = B.CW()
    if c and (c._seeA or 0) >= 0.99 then B.solidBy = "the pointer"; return end
    say("note: cw_12b: the pointer did not count (pointer on the window " .. tostring(c and c:pointerOn()) .. ", above it: "
        .. B.coverAt(getMouseX(), getMouseY(), c) .. "); the controller's focus instead")
    B.solidBy = "the controller's focus"
    D.setLockedMode("gamepad")
    if c then F.claimFocus(c) end
end)
B.waitFor("cw_12b: the Character window solid", function()
    local c = B.CW()
    return c ~= nil and (c._seeA or 0) >= 0.99
end, 6, 180)
B.snap("zqa_cw_12b_solid_in_use", function()
    local c, w = B.CW(), B.WW()
    return string.format("see-through 60 with Solid while in use on, the Character window in use by %s (its surface alpha %s), the World window see-through (%s)",
        tostring(B.solidBy), tostring(c and c._seeA), tostring(w and w._seeA))
end)
S.step(2, function()
    if B.solidBy == "the controller's focus" then
        pcall(function() F.releaseFocus() end)
        D.setLockedMode("kbm")
    end
    ZeD.Settings.setSolidInUse(B.was.solid)
    ZeD.Settings.setSeeThrough(B.was.see or 2)
    B.park()
end)
S.waitMs(500)
B.still(30)

-- page 17: the four highlight styles on an inventory row, the inventory as a list -------
S.step(2, function()
    B.selectItem(nil)
    local IR = ZeD.InventoryRenderer
    if IR and IR.setGridKey then IR.setGridKey("player", false) end
    B.park()
end)
B.still(40)
S.step(2, function() B.place() end)
S.step(2, function() D.setLockedMode("gamepad") end)
S.step(8, function() end)
local NUM = { hand = 14, corners = 16, wash = 18, ants = 20 }
for _, style in ipairs({ "hand", "corners", "wash", "ants" }) do
    S.step(2, function() ZeD.Settings.setFocusStyle(style); B.park() end)
    S.step(10, function() end)
    S.step(2, function()
        local w = B.CW()
        F.claimFocus(w)
        local row = B.pickRow(w, B.hammer)
        local got = row and B.focusOn(w, function(x) return x == row end)
        if not got then S.err("highlight " .. style, "no inventory row to put the pad on") end
    end)
    S.step(12, function() end)
    B.snap(string.format("zqa_cw_%02d_focus_%s_inventory_row", NUM[style], style), function()
        local w = B.CW()
        local e = F.getFocusedElement(w)
        return string.format("pad focus on an inventory row of the Character window, list view (row %s at y %s) | %s",
            tostring(e and e.item and e.item:getDisplayName()), tostring(e and e.y), B.focusDesc(w))
    end)
end
S.step(2, function() ZeD.Settings.setFocusStyle(B.was.focus); D.setLockedMode("kbm"); B.nudge() end)
S.waitMs(350)
S.step(2, function() B.nudge() end)
S.step(6, function() end)
S.step(2, function() B.finish() end)
B.still(20)
S.start()
