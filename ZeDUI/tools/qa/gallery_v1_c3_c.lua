-- ZeDUI/tools/qa/gallery_v1_c3_c.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's lived-in retakes, part c: chapters
-- 71 See-through, 67 Controller Highlight and 69 Themes and Accents, all inside the West Point Fossoil at the stocking
-- spot among the shelves (spot stock). Same content and settings as the captures they replace; the new rule: the
-- windows sit to one side (the Character window at the left edge, the World window beside it, or at the right edge when
-- it would cover Angel) and Angel and the store stay uncovered.
--   71  zqa_cw_08_seethrough_100, zqa_cw_12_seethrough_60   both windows as tall as the screen allows, Dark, small
--       text, the apple's card open, see-through 100 then 60 (see-through only works in Dark)
--       zqa_cw_12b_solid_in_use   see-through 60, Solid while in use on, the pointer resting on the Character window's
--                                 title bar (hidden in the picture; the controller's focus if the pointer does not count)
--                                 (gallery_nov1_cohesion.lua page 16)
--   67  zqa_cw_14_focus_hand_inventory_row, zqa_cw_16_focus_corners_inventory_row, zqa_cw_18_focus_wash_inventory_row,
--       zqa_cw_20_focus_ants_inventory_row   the inventory as a list, no card, the pad's focus on the hammer's row in
--                                 each highlight style (page 17)
--   69  theme_dark_orange, theme_dark_green, theme_light_blue, theme_light_red, theme_hicon_teal, theme_hicon_purple
--                                 both windows on Loot at their own heights, worn bags and the nearest shelves as
--                                 columns, Character sorted by category and World by name; one spot, only the colors
--                                 change (gallery_v3_zed.lua's themes, the six the gallery uses)
-- Adds three apples and a hammer (taken away after). Puts back: the theme, see-through, Solid while in use, the
-- highlight style, the list view choices, the input mode, the card, the columns and sort, heights, places, tabs, the
-- place. grep "ZEDQA c3c".
if not C3 then print("ZEDQA c3c ERR run gallery_v1_c3_common.lua first"); print("ZEDQA c3c DONE"); return end
local Q = C3.make("c3c", 1500000)
local K = { items = {}, was = {}, sortWas = {}, cols = { c = {}, w = {} } }
K.p, K.pn, K.core = C3.p, C3.pn, C3.core
K.St, K.F, K.D = ZeD.Settings, ZeD.Input.Focus, ZeD.Input.Detector

function K.add(ft) local it = K.p:getInventory():AddItem(ft); if it then K.items[#K.items + 1] = it end; return it end
function K.selectItem(item)
    local w = C3.CW()
    local c = w and w._mainContent
    if not (c and w._updateDrawer) then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
-- both windows as tall as the screen allows (top at the margin), or back to the heights they had
function K.tall(on)
    local c, w = C3.CW(), C3.WW()
    if not (c and w) then return end
    local m = C3.m()
    if on then
        if not K.hWas then K.hWas = { c = c:getHeight(), w = w:getHeight(), cy = c:getY(), wy = w:getY() } end
        for _, win in ipairs({ c, w }) do win:setY(m); win:setHeight(K.core:getScreenHeight() - 2 * m); pcall(function() win:onResize() end) end
        K.top = m
    elseif K.hWas then
        c:setHeight(K.hWas.c); pcall(function() c:onResize() end); c:setY(K.hWas.cy)
        w:setHeight(K.hWas.w); pcall(function() w:onResize() end); w:setY(K.hWas.wy)
        K.hWas, K.top = nil, nil
    end
end
function K.place() C3.side({ { C3.CW(), "char", K.top }, { C3.WW(), "world", K.top } }, "left") end
-- the pad's focus on an inventory row (the hammer's when it is on screen)
function K.zoneOf(w, name) for i, z in ipairs(w and w._focusRing or {}) do if z.zone == name then return i, z end end; return nil, nil end
function K.pickRow(w, prefer)
    local _, z = K.zoneOf(w, "charMainInv")
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
function K.focusOn(w, el)
    K.F.claimFocus(w)
    local zone = nil
    for _, z in ipairs(w._focusRing or {}) do for _, e in ipairs(z.elements or {}) do if e == el then zone = z.zone end end end
    if not zone then return nil end
    local got = K.F.focusWhere(w, zone, function(x) return x == el end)
    if got then K.F.dispatchJoypadDown(w, "QA") end
    return got
end
-- the columns (gallery_v3_zed.lua's Z.mc): worn bags in the Character window, the nearest shelves in the World window
function K.colOn(win, inv)
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv then
            for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
function K.findCols()
    K.cols = { c = {}, w = {} }
    pcall(function()
        local worn = K.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local it = worn:get(i):getItem()
            if instanceof(it, "InventoryContainer") and #K.cols.c < 2 then K.cols.c[#K.cols.c + 1] = it:getInventory() end
        end
    end)
    local q = STORY and STORY.P and STORY.P.stock
    for _, e in ipairs((STORY and STORY.F and STORY.F.shelves) or {}) do
        if q and e.inv and math.abs(e.x - q[1]) <= 1 and math.abs(e.y - q[2]) <= 1 and #K.cols.w < 2 then K.cols.w[#K.cols.w + 1] = e.inv end
    end
    Q.say("columns: " .. #K.cols.c .. " worn bags, " .. #K.cols.w .. " shelves")
end
function K.mc(on)
    local c, w = C3.CW(), C3.WW()
    if not (c and w) then return false end
    local done = true
    for _, inv in ipairs(K.cols.c) do if K.colOn(c, inv) ~= on then done = false; if K.flip then C3.CWm.toggleColumn(inv) end end end
    for _, inv in ipairs(K.cols.w) do if K.colOn(w, inv) ~= on then done = false; if K.flip then C3.WWm.toggleColumn(inv) end end end
    return done
end
-- wait (at most 600 frames) for the columns, toggling at most every 15 frames
function K.mcWait(on)
    local st = { n = 0 }
    Q.waitFor(5, 600, function()
        st.n = st.n + 1
        K.flip = (st.n % 15 == 1)
        local d = K.mc(on)
        K.flip = false
        return d
    end, function(ok) Q.say("columns " .. (on and "on" or "off") .. " " .. tostring(ok)) end)
end
function K.sort(win, key, asc)
    local c = win and win._mainContent
    if not c then return end
    if not K.sortWas[win] then K.sortWas[win] = { c._sortCol, c._sortAsc } end
    c._sortCol, c._sortAsc = key, asc
    for _, cs in ipairs(c._colStates or {}) do cs.sortCol, cs.sortAsc = key, asc end
end
function K.sortBack()
    for win, v in pairs(K.sortWas) do
        local c = win._mainContent
        if c and v[1] then
            c._sortCol, c._sortAsc = v[1], v[2]
            for _, cs in ipairs(c._colStates or {}) do cs.sortCol, cs.sortAsc = v[1], v[2] end
        end
    end
    K.sortWas = {}
end
function K.live()
    local St = K.St
    local function try(fn) local ok, v = pcall(fn); return ok and tostring(v) or "?" end
    return string.format("theme %s %s %s | see-through %s | solid in use %s | highlight %s | input %s",
        tostring(ZeD.currentBase), tostring(ZeD.currentAccent), tostring(ZeD.currentSize), try(St.seeThrough),
        try(St.solidInUse), try(St.focusStyle), try(K.D.getMode))
end
function K.seeIdx(v) for i, k in ipairs(K.St.seeThroughKeys or { 100, 90, 80, 70, 60 }) do if k == v then return i end end; return nil end

-- ===================================================================== setup
Q.step(10, function()
    local W, St = K.was, K.St
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    W.base, W.accent, W.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    W.see = St.seeThroughIndex and St.seeThroughIndex() or nil
    W.solid = St.solidInUse and St.solidInUse() or false
    W.focus = St.focusStyle and St.focusStyle() or "hand"
    W.home = { x = K.p:getX(), y = K.p:getY(), z = K.p:getZ() }
    K.wins = C3.snapWins()
    C3.listView(true)
    C3.go(Q, "stock", "SE")
    K.D.setLockedMode("kbm")
    -- (cohesion's look: Dark, small text, the gallery's accent; see-through applies the theme again from the options)
    ZeD.applyTheme("dark", (GAL_LOOK and GAL_LOOK[2]) or ZeD.currentAccent, "small")
    pcall(St.syncToModOptions)
    C3.pairOpen()
    for _ = 1, 3 do local a = K.add("Base.Apple"); K.apple = K.apple or a end
    K.hammer = K.add("Base.Hammer")
    pcall(function() ISInventoryPage.dirtyUI() end)
    C3.park()
    Q.say("start: " .. K.live() .. " | apples " .. tostring(K.apple ~= nil) .. ", hammer " .. tostring(K.hammer ~= nil))
end)
Q.still(40, function() C3.charTab("loot"); C3.worldTab("loot"); K.tall(true); Q.hold = K.place end)
Q.still(30, function() K.tall(true) end)

-- ===================================================================== 71 See-through
Q.still(20, function() if not K.selectItem(K.apple) then Q.say("ERR the inventory pane is not there to pick the apple") end end)
for _, v in ipairs({ 100, 60 }) do
    Q.step(2, function()
        local i = K.seeIdx(v)
        if i then K.St.setSeeThrough(i) else Q.say("ERR no see-through step " .. v) end
        C3.park()
    end)
    Q.still(30, function()
        local name = (v == 100) and "zqa_cw_08_seethrough_100" or "zqa_cw_12_seethrough_60"
        Q.say(name .. ": the apple's card open at see-through " .. v .. " | " .. K.live())
        Q.shot(name)
    end)
end
Q.step(2, function()
    K.St.setSolidInUse(true)
    local c = C3.CW()
    if c then pcall(function() c:bringToTop() end) end
    K.rest = {}
end)
-- the pointer walks onto the Character window's title bar (2 px steps, the engine's UI tick sees the move), then rests
Q.waitFor(1, 900, function()
    local R, c = K.rest, C3.CW()
    if not c then return true end
    local now = getTimestampMs()
    if not R.t0 then R.t0, R.n = now, 0 end
    R.n = R.n + 1
    local x, y = c:getAbsoluteX() + math.floor(c:getWidth() * 0.4), c:getAbsoluteY() + math.floor(c:titleBarHeight() / 2)
    if now - R.t0 < 350 then
        if R.n % 4 == 0 then pcall(function() Mouse.setXY(x + ((((R.n / 4) % 2) == 0) and 2 or 0), y) end) end
    else
        pcall(function() Mouse.setXY(x, y) end)
    end
    return now - R.t0 >= 700
end)
Q.waitFor(1, 120, function() local c = C3.CW(); return c ~= nil and (c._seeA or 0) >= 0.99 end, function(ok)
    if ok then K.solidBy = "the pointer"; return end
    Q.say("note: cw_12b: the pointer did not count; the controller's focus instead")
    K.solidBy = "the controller's focus"
    K.D.setLockedMode("gamepad")
    local c = C3.CW(); if c then K.F.claimFocus(c) end
end)
Q.waitFor(6, 180, function() local c = C3.CW(); return c ~= nil and (c._seeA or 0) >= 0.99 end, function(ok)
    local c, w = C3.CW(), C3.WW()
    Q.say(string.format("zqa_cw_12b_solid_in_use: in use by %s (surface %s), World see-through (%s) | %s", tostring(K.solidBy),
        tostring(c and c._seeA), tostring(w and w._seeA), K.live()))
    C3.hidePointer()
    Q.shot("zqa_cw_12b_solid_in_use")
end)
Q.step(2, function()
    if K.solidBy == "the controller's focus" then pcall(function() K.F.releaseFocus() end); K.D.setLockedMode("kbm") end
    K.St.setSolidInUse(K.was.solid)
    K.St.setSeeThrough(K.was.see or 2)
    C3.park()
end)

-- ===================================================================== 67 Controller Highlight
Q.still(30, function() K.selectItem(nil); C3.park() end)
Q.still(30, function() K.D.setLockedMode("gamepad") end)
K.NUM = { hand = 14, corners = 16, wash = 18, ants = 20 }
for _, style in ipairs({ "hand", "corners", "wash", "ants" }) do
    Q.step(8, function() K.St.setFocusStyle(style); C3.park() end)
    Q.step(10, function()
        local w = C3.CW()
        local row = K.pickRow(w, K.hammer)
        local got = row and K.focusOn(w, row)
        if not got then Q.say("ERR highlight " .. style .. ": no inventory row to put the pad on") end
    end)
    Q.step(12, function()
        local name = string.format("zqa_cw_%02d_focus_%s_inventory_row", K.NUM[style], style)
        local e = K.F.getFocusedElement(C3.CW())
        Q.say(name .. ": pad focus on " .. tostring(e and e.item and e.item:getDisplayName()) .. " | " .. K.live())
        Q.shot(name)
    end)
end
Q.step(2, function()
    K.St.setFocusStyle(K.was.focus)
    pcall(function() K.F.releaseFocus() end)
    K.D.setLockedMode("kbm")
    C3.park()
end)

-- ===================================================================== 69 Themes and Accents (one spot)
Q.still(20, function()
    K.tall(false)
    ZeD.applyTheme(K.was.base, K.was.accent, K.was.size)
    C3.charTab("loot"); C3.worldTab("loot")
    K.findCols()
end)
K.mcWait(true)
Q.step(30, function() K.sort(C3.CW(), "cat", true); K.sort(C3.WW(), "name", true) end)
for _, t in ipairs({ { "dark", "orange" }, { "dark", "green" }, { "light", "blue" }, { "light", "red" }, { "hicon", "teal" }, { "hicon", "purple" } }) do
    Q.step(2, function() C3.theme(t[1], t[2]) end)
    Q.still(10, function() end)
    Q.step(15, function() Q.shot("theme_" .. t[1] .. "_" .. t[2]) end)
end
K.mcWait(false)

-- ===================================================================== put back
Q.mark()
Q.step(10, function()
    Q.hold = nil
    local W, St = K.was, K.St
    K.flip = true; pcall(K.mc, false); K.flip = false
    pcall(K.sortBack)
    pcall(function() K.D.setLockedMode(nil) end)
    pcall(function() K.selectItem(nil) end)
    for i = #K.items, 1, -1 do local it = K.items[i]; pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    K.items = {}
    pcall(function() ISInventoryPage.dirtyUI() end)
    pcall(function() St.setSolidInUse(W.solid) end)
    pcall(function() St.setFocusStyle(W.focus) end)
    pcall(function() ZeD.applyTheme(W.base, W.accent, W.size); if St.syncToModOptions then St.syncToModOptions() end end)
    pcall(function() if W.see then St.setSeeThrough(W.see) end end)
    pcall(function() if St.save then St.save() end end)
    pcall(function() K.F.releaseFocus() end)
    K.tall(false)
    C3.listView(false)
    pcall(function() STORY.tp(W.home.x, W.home.y, W.home.z) end)
end)
Q.step(20, function()
    C3.backWins(K.wins)
    Q.say("put back: " .. K.live() .. " | items, card, columns, sort, list view, windows, place")
end)
Q.start()
