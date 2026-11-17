-- ZeDUI/tools/qa/gallery_b19_a.lua  (Nov 17 2026, QA): the beta 19 gallery recapture, first half
-- (workshop/gallery/B19_RECAPTURE.md). 4K, 1.75x, Dark + PZ Teal, the list view, the same names as the beta 13 pictures.
-- Runs TWICE in gallery_b19_a.txt; which half it takes is read from GAL (gallery_v3_core / gallery_v3_stage's staging):
--   tag gb19a  (GAL staged: the mall lot, after gallery_v3_core + reveal + stage, before gallery_v3_teardown)
--     07  zed_53_grid (tiles off, as before), zed_53b_grid_tinted (new: Item-colored tiles on; a red axe, a blue CD,
--         tan bats, a gray wrench given for the shot, the list sorted by name so they are in view)
--     09  zed_01_hero_mid: one source each, the list, a third apple given so the Apple stack opens: its header row and
--         each apple on its own row
--     11  zed_18_card_food, zed_19_card_weapon: an apple and a machete on the ground, picked in the World window, so
--         the card's foot reads Grab, the main action, More (windows tall, as gallery_nov1_lot.lua)
--     32  zed_20_ctx_strip, zed_21_ctx_list: the apple's menu, strip then list (gallery_v3_zed.lua's place)
--     33  zed_32_action_bar_reading (as before: windows shut, zoom 0.5, two zombies near), zed_32b_action_endless
--         (new: resting, ISRestAction with no end: its icon, no bar)
--   tag gb19ah (no GAL: after gallery_v3_teardown, at the QA home; staging from zedqa_appliances / gallery_t14_indoor)
--     the grid power on, the character on a free room square (else the Fossoil at West Point)
--     22  zqa_ap_1_tab_stove (the Craft tab, its pop-out button top right), zqa_ap_2b_popout_stove_on (BAKE started,
--         popped out beside the character), zqa_ap_4_popout_microwave
--     12  g14_ldy_washer (running), g14_ldy_dryer, g14_ldy_combo: each popped out beside the character
--     26  g19_radio_popout (new: a placed radio, on, popped out), g19_tv_tab (new: a TV in the World window's Radio tab)
--     35  zqa_b19_speed_bubble (new: back home outdoors, windows shut, ZEDQA_SPEED(2): the speed bubble over the head)
-- Spread 26's four half-card faces, 27 (two-way) and 34 (belt) are straight retakes by their own scripts in the
-- manifest (gallery_t14_radios, zedqa_twoway, zedqa_hands_together).
-- Every shot: invisible and god mode off (zombies-don't-attack on instead), the debug console hidden, the pointer
-- parked in the bottom-left corner, menus closed unless the picture is the menu, both windows still for 30 frames.
-- Puts back: theme and options, grid views and sorts, tint, items given, things placed, window places, game speed,
-- invisible / god mode, the grid power, the character's place. Full 4K PNGs in Zomboid/Screenshots under the gallery
-- names (gallery_b13_collect.ps1's way: copied into gallery_t14 after). grep "ZEDQA gb19a".
local S = { Q = {}, qi = 1, wait = nil, was = {}, placed = {}, added = {}, objs = {}, lock = nil }
S.lot = (GAL and GAL.spot and GAL.newSeq and GAL.car) and true or false
S.tag = S.lot and "gb19a" or "gb19ah"
function S.say(s) print("ZEDQA " .. S.tag .. " " .. tostring(s)) end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then S.say("ERR ZeD is not loaded"); S.say("DONE"); return end
S.p = getPlayer()
S.pn = S.p:getPlayerNum()
S.core = getCore()
S.CWm, S.WWm = ZeD_CharacterWindow, ZeD_WorldWindow

-- ===================================================================== the queue (OnPreUIDraw)
function S.step(n, fn) S.Q[#S.Q + 1] = { n = n, fn = fn } end
-- after n frames, every frame until cond() (at most max frames), then fn
function S.waitFor(n, max, cond, fn) S.Q[#S.Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
function S.tick()
    local s = S.Q[S.qi]
    if not s then Events.OnPreUIDraw.Remove(S.tick); return end
    if not s.started then
        S.wait = (S.wait or s.n) - 1
        if S.wait > 0 then return end
        S.wait = nil
        s.started = true
    end
    if s.cond then
        s.left = (s.left or s.max) - 1
        local ok, done = pcall(s.cond)
        if not (ok and done) and s.left > 0 then return end
        if not (ok and done) then S.say("note: step " .. S.qi .. " waited " .. s.max .. " frames, went on") end
    end
    S.qi = S.qi + 1
    local ok, err = pcall(s.fn)
    if not ok then S.say("ERR step " .. (S.qi - 1) .. ": " .. tostring(err)) end
end

-- ===================================================================== shared helpers
function S.CW() return S.CWm.getWindow() end
function S.WW() return S.WWm.getWindow() end
function S.shape()
    if GAL_SHAPE then return GAL_SHAPE() end
    local t = {}
    for _, w in ipairs({ S.CW() or false, S.WW() or false }) do
        if w and w:isVisible() then t[#t + 1] = string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0)) end
    end
    return table.concat(t, ";")
end
-- both windows the same for 30 frames (at most 900), then fn
function S.still(n, fn)
    local last, same = nil, 0
    S.waitFor(n, 900, function()
        local s = S.shape()
        if s == last then same = same + 1 else last, same = s, 0 end
        return same >= 30
    end, fn)
end
function S.closeMenus()
    pcall(function() local m = getPlayerContextMenu(S.pn); if m and m._zedMenu then m._zedMenu:close() end end)
    pcall(function() local m = getPlayerContextMenu(S.pn); if m and m:isVisible() then m:closeAll() end end)
end
-- the gallery rule (Build, Nov 17): no debug overlay; zombies leave the character alone
function S.clean()
    pcall(function() S.p:setInvisible(false) end)
    pcall(function() S.p:setGodMod(false) end)
    pcall(function() S.p:setZombiesDontAttack(true) end)
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false); S.was.console = e end
        end
    end)
end
function S.park() pcall(function() Mouse.setXY(10, S.core:getScreenHeight() - 10) end) end
-- keepMenu: the picture is the menu
function S.shot(name, keepMenu)
    S.clean()
    S.park()
    if not keepMenu then S.closeMenus() end
    local ok, e = pcall(function() S.core:TakeFullScreenshot(name .. ".png") end)
    S.say((ok and "shot " or "ERR shot ") .. name .. (ok and "" or (": " .. tostring(e))))
    for _, pair in ipairs({ { "char", S.CW() }, { "world", S.WW() } }) do
        local w = pair[2]
        if w and w:isVisible() then S.say(string.format("box %s %s %d,%d-%d,%d", name, pair[1], w:getX(), w:getY(), w:getX() + w:getWidth(), w:getY() + w:getHeight())) end
    end
    local v = ZeD.TwoWayFull and ZeD.TwoWayFull.get and ZeD.TwoWayFull.get(S.pn)
    if v and v:isVisible() then S.say(string.format("box %s popout %d,%d-%d,%d", name, v:getX(), v:getY(), v:getX() + v:getWidth(), v:getY() + v:getHeight())) end
end
function S.notTaken(name, why) S.say("not taken: " .. name .. " (" .. tostring(why) .. ")") end
function S.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab or (tab ~= "loot" and win._drawerOpen == false) then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function S.charTab(id) local w = S.CW(); return (w and S.goTab(w, w._tabStripPanel, id)) and true or false end
function S.worldTab(id) local w = S.WW(); return (w and S.goTab(w, w._actionTabStrip, id)) and true or false end
function S.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (S.CWm.isOpen() and S.WWm.isOpen()) then S.CWm.toggleBothPaired(S.pn) end
end
function S.closePair()
    if S.CWm.isOpen() and S.WWm.isOpen() then S.CWm.toggleBothPaired(S.pn)
    else
        if S.CWm.isOpen() then S.CWm.toggle(S.pn) end
        if S.WWm.isOpen() then S.WWm.close() end
    end
end
function S.give(ft)
    local it
    pcall(function() it = S.p:getInventory():AddItem(ft) end)
    if it then S.added[#S.added + 1] = it end
    return it
end
function S.found(ft, from)
    local items = (from or S.p:getInventory()):getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
end
-- the zoom eases: read once settled, wheel steps of 0.25
function S.zoomTo(z)
    local left
    S.step(40, function() end)
    S.waitFor(20, 1200, function()
        if left == nil then left = math.floor((S.core:getZoom(0) - z) / 0.25 + 0.5) end
        if left == 0 then return true end
        S.core:doZoomScroll(0, (left > 0) and -1 or 1)
        left = (left > 0) and (left - 1) or (left + 1)
        return left == 0
    end, function() end)
    S.step(100, function() S.say("zoom " .. tostring(S.core:getZoom(0))) end)
end
function S.saveCommon()
    local W = S.was
    W.base, W.accent, W.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    W.speed = getGameSpeed()
    pcall(function() W.inv = S.p:isInvisible() end)
    pcall(function() W.god = S.p:isGodMod() end)
    pcall(function() W.dda = S.p:isZombiesDontAttack() end)
    pcall(function() W.layout = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() end)
    pcall(function() local m = S.p:getModData().ZeD_TwoWayFull; W.popPlace = m and { x = m.x, y = m.y } end)
    local Opt = ZeD.Settings
    W.ctx = Opt.contextStyleOption:getValue()
    W.watch = Opt.watchPlaceOption:getValue()
    W.bar = Opt.actionBarOption:getValue()
    W.tint = Opt.gridTintOption and Opt.gridTintOption:getValue()
    local g = S.p:getModData().ZeD_GridViews
    W.grid = g and { player = g.player, world = g.world } or {}
    pcall(function() W.font = S.core:getOptionFontSize() end)
end
-- Dark + PZ Teal (gallery_b11_look.lua sets the options; this checks and applies in memory when they differ)
function S.look()
    local b, a = (GAL_LOOK and GAL_LOOK[1]) or "dark", (GAL_LOOK and GAL_LOOK[2]) or "teal"
    if ZeD.currentBase ~= b or ZeD.currentAccent ~= a then
        ZeD.applyTheme(b, a, ZeD.currentSize)
        S.was.themed = true
        local c, w = S.CW(), S.WW()
        if c then c._accentKey = nil end
        if w then w._accentKey = nil end
    end
    local IR = ZeD.InventoryRenderer
    if IR and IR.setGridKey then IR.setGridKey("player", false, S.p); IR.setGridKey("world", false, S.p) end
    if ZeD.Settings.gridTintOption then ZeD.Settings.gridTintOption:setValue(1) end
    S.say("look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " size " .. tostring(ZeD.currentSize)
        .. " | scale " .. tostring(ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) .. " | font size option " .. tostring(S.was.font)
        .. " | screen " .. S.core:getScreenWidth() .. "x" .. S.core:getScreenHeight())
end
function S.putBackCommon()
    local W = S.was
    S.closeMenus()
    pcall(function() ZeD.TwoWayFull.close(S.pn) end)
    for _, it in ipairs(S.added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    S.added = {}
    local Opt = ZeD.Settings
    pcall(function() Opt.contextStyleOption:setValue(W.ctx) end)
    pcall(function() Opt.watchPlaceOption:setValue(W.watch) end)
    pcall(function() Opt.actionBarOption:setValue(W.bar) end)
    pcall(function() if Opt.gridTintOption and W.tint then Opt.gridTintOption:setValue(W.tint) end end)
    pcall(function()
        local g = S.p:getModData().ZeD_GridViews
        if g then g.player = W.grid.player; g.world = W.grid.world end
    end)
    if W.themed then pcall(Opt.reapplyFromOptions) end
    pcall(function() if W.popPlace then S.p:getModData().ZeD_TwoWayFull = W.popPlace else S.p:getModData().ZeD_TwoWayFull = nil end end)
    pcall(function() if ZEDQA_SPEED then ZEDQA_SPEED(W.speed or 1) else setGameSpeed(W.speed or 1) end end)
    pcall(function() S.p:setInvisible(W.inv == true) end)
    pcall(function() S.p:setGodMod(W.god == true) end)
    pcall(function() S.p:setZombiesDontAttack(W.dda == true) end)
    if W.console then pcall(function() W.console:setVisible(true) end) end
end

-- ===================================================================== the mall lot (gb19a)
function S.place()
    local c, w = S.CW(), S.WW()
    if not (c and w and S.CWm.isOpen() and S.WWm.isOpen()) or w._rolled then return false end
    local L = S.lock
    if not L then
        local gap = ZeD.T and ZeD.T.px and ZeD.T.px(8) or 16
        local x0 = math.floor((S.core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        L = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap, cy = c:getY(), wy = w:getY() }
        S.lock = L
    end
    c._anchorRightEdge = L.right
    c:setX(L.right - c:getWidth())
    w:setX(L.left)
    c:setY(L.cy)
    w:setY(L.wy)
    return true
end
function S.tall(on)
    local c, w = S.CW(), S.WW()
    if not (c and w) then return end
    if on then
        S.was.tallWas = S.was.tallWas or { c = { c:getX(), c:getY(), c:getHeight() }, w = { w:getX(), w:getY(), w:getHeight() } }
        local m = ZeD.T.px(12)
        local h = S.core:getScreenHeight() - 2 * m
        S.lock = nil
        for _, win in ipairs({ c, w }) do win:setY(m); win:setHeight(h); pcall(function() win:onResize() end) end
        S.place()
        return
    end
    local s = S.was.tallWas
    if not s then return end
    c:setHeight(s.c[3]); pcall(function() c:onResize() end); c:setX(s.c[1]); c:setY(s.c[2])
    w:setHeight(s.w[3]); pcall(function() w:onResize() end); w:setX(s.w[1]); w:setY(s.w[2])
    S.lock, S.was.tallWas = nil, nil
end
-- one source per window (GAL_ONE_SOURCE's hero): every extra column off
function S.oneSource()
    local done = true
    for _, pair in ipairs({ { S.CW(), S.CWm }, { S.WW(), S.WWm } }) do
        local win, mod = pair[1], pair[2]
        if win then
            for _, j in ipairs(win._mcSelected or {}) do
                local c = win._containers and win._containers[j]
                if c and c.inventory and mod.toggleColumn and #(win._mcSelected or {}) > 1 then mod.toggleColumn(c.inventory); done = false; break end
            end
        end
    end
    return done
end
function S.sort(win, key, asc)
    local c = win and win._mainContent
    if not c then return end
    S.was.sorts = S.was.sorts or {}
    local known = false
    for _, v in ipairs(S.was.sorts) do if v.c == c then known = true end end
    if not known then S.was.sorts[#S.was.sorts + 1] = { c = c, col = c._sortCol, asc = c._sortAsc } end
    c._sortCol, c._sortAsc = key, asc
    for _, cs in ipairs(c._colStates or {}) do cs.sortCol, cs.sortAsc = key, asc end
end
function S.sortBack()
    for _, v in ipairs(S.was.sorts or {}) do
        local c = v.c
        c._sortCol, c._sortAsc = v.col, v.asc
        for _, cs in ipairs(c._colStates or {}) do cs.sortCol, cs.sortAsc = v.col, v.asc end
    end
end
function S.select(win, item)
    local c = win and win._mainContent
    if not (c and win._updateDrawer) then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    win._updateDrawer(c)
    return true
end
-- the Character list's apple stack opened (or shut): its header row and each apple on its own row
-- (an open stack leaves cnt._stacks for cnt._openHeads, InventoryRenderer's model; both are read; the biggest wins)
function S.openStack(ft, on)
    local cnt = S.CW() and S.CW()._mainContent
    if not cnt then return nil end
    local best
    local function look(stk)
        local ok, full = pcall(function() return stk.rep:getFullType() end)
        if ok and full == ft and stk.count and stk.count > 1 and (not best or stk.count > best.count) then best = stk end
    end
    for _, stk in pairs(cnt._stacks or {}) do look(stk) end
    for _, stk in ipairs(cnt._openHeads or {}) do look(stk) end
    if not best then return nil end
    cnt._expandedStacks = cnt._expandedStacks or {}
    cnt._expandedStacks[best.key] = on or nil
    for _, cs in ipairs(cnt._colStates or {}) do
        cs.expandedStacks = cs.expandedStacks or cnt._expandedStacks
        cs.expandedStacks[best.key] = on or nil
    end
    return best.count
end
-- is that stack drawn open now (its header row in the list)
function S.stackShown(ft)
    local cnt = S.CW() and S.CW()._mainContent
    for _, stk in ipairs(cnt and cnt._openHeads or {}) do
        local ok, full = pcall(function() return stk.rep:getFullType() end)
        if ok and full == ft then return stk.count end
    end
    return nil
end
function S.dropOnGround(ft, dx, dy)
    local G = GAL
    local it = G.worldItem(ft, G.spot.px + dx, G.spot.py + dy, 0.5, 0.5)
    if it then S.was.ground = S.was.ground or {}; S.was.ground[#S.was.ground + 1] = it end
    return it
end
function S.groundBack()
    for _, it in ipairs(S.was.ground or {}) do
        pcall(function() local wi = it:getWorldItem(); if wi then wi:getSquare():transmitRemoveItemFromSquare(wi) end end)
    end
    S.was.ground = nil
end
function S.weightNote(tag)
    pcall(function()
        local inv = S.p:getInventory()
        S.say(string.format("%s: inventory %.1f of %.1f kg", tag, inv:getCapacityWeight(), inv:getEffectiveCapacity(S.p)))
    end)
end

function S.lotStart()
    local G = GAL
    S.step(10, function()
        S.saveCommon()
        S.say("start: the mall lot at " .. tostring(G.spot.px) .. "," .. tostring(G.spot.py))
        if getGameSpeed() <= 0 then setGameSpeed(1) end
        pcall(G.cleanLook)
        pcall(G.day)
        S.clean()
        local Opt = ZeD.Settings
        Opt.watchPlaceOption:setValue(1)
        Opt.contextStyleOption:setValue(1)
        Opt.actionBarOption:setValue(1)
        pcall(G.stand)
        S.openPair()
    end)
    S.step(40, function() S.look(); S.charTab("loot"); S.worldTab("loot"); S.place() end)
    S.waitFor(10, 600, function() return S.oneSource() end, function() S.place() end)
    S.zoomTo(1.0)
end

function S.lotHero()
    S.step(5, function()
        S.sort(S.CW(), "cat", true); S.sort(S.WW(), "name", true)
        -- three new apples (0.2 kg each): fresh alike, so they make one stack of three or more with any fresh ones
        for _ = 1, 3 do S.give("Base.Apple") end
        S.weightNote("apples given")
        pcall(GAL.faceFront)
    end)
    S.step(60, function()
        local n = S.openStack("Base.Apple", true)
        S.say("the apple stack opened: " .. tostring(n))
        S.place()
    end)
    S.waitFor(10, 300, function() return S.stackShown("Base.Apple") ~= nil end, function() S.place() end)
    S.step(20, function() S.place() end)
    S.still(5, function()
        S.weightNote("zed_01_hero_mid")
        local n = S.stackShown("Base.Apple")
        if n and n >= 3 then S.say("open stack: Apple (" .. n .. ")"); S.shot("zed_01_hero_mid")
        else S.notTaken("zed_01_hero_mid", "no open apple stack of three in the list (" .. tostring(n) .. ")") end
    end)
    S.step(2, function() S.openStack("Base.Apple", false) end)
end

-- (Build, Nov 17 2026: the grid shots read 27.0 / 20 kg in the header. The heaviest loose things (not worn, held or on
-- the belt) are set aside until the load is at most `to` kg, and put back after the grid shots: S.lightenBack)
function S.lightenTo(to)
    S.was.aside = S.was.aside or {}
    pcall(function()
        local inv = S.p:getInventory()
        local loose = {}
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local keep = S.p:isEquipped(it) or S.p:isEquippedClothing(it) or S.p:isHandItem(it) or (it:getAttachedSlot() and it:getAttachedSlot() > -1)
            if not keep then loose[#loose + 1] = it end
        end
        table.sort(loose, function(a, b) return a:getUnequippedWeight() > b:getUnequippedWeight() end)
        local w = 0
        for i = 0, items:size() - 1 do local it = items:get(i); w = w + (S.p:isEquipped(it) and it:getEquippedWeight() or it:getUnequippedWeight()) end
        for _, it in ipairs(loose) do
            if w <= to then break end
            w = w - it:getUnequippedWeight()
            inv:Remove(it)
            S.was.aside[#S.was.aside + 1] = it
        end
        S.say(string.format("set aside %d things for the grid shots, load now about %.1f kg", #S.was.aside, w))
    end)
end
function S.lightenBack()
    local inv = S.p:getInventory()
    for _, it in ipairs(S.was.aside or {}) do pcall(function() inv:AddItem(it) end) end
    S.say("put back " .. #(S.was.aside or {}) .. " things set aside for the grid shots")
    S.was.aside = {}
end

function S.lotGrid()
    S.step(5, function()
        S.lightenTo(6)
        -- light things so the grid stays full (about 17 tiles with the tinted set), each taken away after
        S.was.fill = {}
        for _, ft in ipairs({ "Base.Apple", "Base.Orange", "Base.Battery", "Base.Bandage", "Base.Pencil", "Base.Matches",
                              "Base.Socks_Ankle", "Base.Spoon", "Base.Lighter", "Base.Scissors", "Base.Needle", "Base.Thread" }) do
            local it = S.give(ft); if it then S.was.fill[#S.was.fill + 1] = it end
        end
        S.weightNote("grid filled with light things")
        ZeD.InventoryRenderer.setGridKey("player", true, S.p); S.place()
    end)
    S.step(50, function() S.place() end)
    S.still(5, function() S.shot("zed_53_grid") end)
    -- the new one: Item-colored tiles on, things of clearly different colors, sorted by name so they show
    S.step(5, function()
        local Opt = ZeD.Settings
        if not Opt.gridTintOption then S.was.noTint = true; return end
        S.was.tintGive = {}
        for _, ft in ipairs({ "Base.Axe", "Base.Disc_Retail", "Base.BaseballBat", "Base.Wrench" }) do   -- (one bat: two put the load over 20 kg)
            local it = S.give(ft)
            if not it and ft == "Base.Wrench" then it = S.give("Base.PipeWrench") end
            if it then S.was.tintGive[#S.was.tintGive + 1] = it end
        end
        -- (within the weight limit: a bat goes back if the inventory is over)
        pcall(function()
            local inv = S.p:getInventory()
            if inv:getCapacityWeight() > inv:getEffectiveCapacity(S.p) then
                for i = #S.added, 1, -1 do
                    local it = S.added[i]
                    if it:getFullType() == "Base.BaseballBat" then inv:Remove(it); table.remove(S.added, i); S.say("one bat taken back (weight)"); break end
                end
            end
        end)
        S.sort(S.CW(), "name", true)
        Opt.gridTintOption:setValue(2)
        S.place()
    end)
    S.step(60, function() S.place() end)
    S.still(5, function()
        if S.was.noTint then S.notTaken("zed_53b_grid_tinted", "no Item-colored tiles option in this build"); return end
        S.weightNote("zed_53b_grid_tinted")
        S.shot("zed_53b_grid_tinted")
    end)
    S.step(5, function()
        local Opt = ZeD.Settings
        if Opt.gridTintOption then Opt.gridTintOption:setValue(1) end
        for _, it in ipairs(S.was.tintGive or {}) do
            pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
            for i = #S.added, 1, -1 do if S.added[i] == it then table.remove(S.added, i) end end
        end
        S.was.tintGive = nil
        S.sort(S.CW(), "cat", true)
        ZeD.InventoryRenderer.setGridKey("player", false, S.p)
        for _, it in ipairs(S.was.fill or {}) do
            pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
            for i = #S.added, 1, -1 do if S.added[i] == it then table.remove(S.added, i) end end
        end
        S.was.fill = nil
        S.lightenBack()
    end)
    S.step(30, function() S.place() end)
end

-- the card from the World window's ground, so its foot reads Grab, the main action, More
function S.lotCard(name, ft, dx, dy)
    S.step(5, function()
        S.was.card = S.dropOnGround(ft, dx, dy)
        if not S.was.card then S.say("note: " .. ft .. " not placed on the ground") end
        S.worldTab("loot")
    end)
    S.step(60, function()
        local it = S.was.card
        if it then S.select(S.WW(), it) end
        S.place()
    end)
    S.step(40, function() S.place() end)
    S.still(5, function()
        local w = S.WW()
        if not S.was.card then S.notTaken(name, ft .. " could not be put on the ground"); return end
        if not (w and w._drawerItem == S.was.card) then S.say("note: " .. name .. ": the World card shows " .. tostring(w and w._drawerItem)) end
        S.shot(name)
    end)
    S.step(2, function() S.select(S.WW(), nil) end)
end
function S.lotCards()
    S.step(5, function() S.tall(true) end)
    S.step(60, function() S.tall(true) end)
    S.lotCard("zed_18_card_food", "Base.Apple", 1, 1)
    S.lotCard("zed_19_card_weapon", "Base.Machete", -1, 1)
    S.step(5, function() S.groundBack(); S.tall(false) end)
    S.step(40, function() S.place() end)
end

function S.lotMenus()
    local function menu(style)
        local Opt = ZeD.Settings
        Opt.contextStyleOption:setValue(style)
        local food = S.found("Base.Apple")
        if not food then return false end
        local w = S.CW()
        ISInventoryPaneContextMenu.createMenu(S.pn, true, { food }, w:getX() + math.floor(w:getWidth() * 0.42), w:getY() + math.floor(w:getHeight() * 0.30))
        return true
    end
    S.step(20, function() S.place(); S.was.m1 = menu(1) end)
    S.step(30, function() if S.was.m1 then S.shot("zed_20_ctx_strip", true) else S.notTaken("zed_20_ctx_strip", "no apple") end end)
    S.step(2, function() S.closeMenus() end)
    S.step(10, function() S.was.m2 = menu(2) end)
    S.step(30, function() if S.was.m2 then S.shot("zed_21_ctx_list", true) else S.notTaken("zed_21_ctx_list", "no apple") end end)
    S.step(2, function() S.closeMenus(); ZeD.Settings.contextStyleOption:setValue(S.was.ctx) end)
    S.step(2, function() S.say("not taken: the Install / Uninstall / Take apart list variant (optional; the apple's menu is the spread's frame)") end)
end

function S.lotHud()
    local G = GAL
    S.step(5, function() S.closePair() end)
    S.zoomTo(0.5)
    S.step(2, function()
        pcall(G.nearZombies, true)
        pcall(function() S.p:getStats():set(CharacterStat.HUNGER, 0.3); S.p:getStats():set(CharacterStat.THIRST, 0.35) end)
    end)
    S.step(90, function() pcall(G.faceFront) end)
    S.step(5, function()
        local book = S.found("Base.Book")
        S.was.book = book ~= nil
        if not book then return end
        local ok = pcall(function() ISInventoryPaneContextMenu.readItem(book, S.pn) end)
        if not ok then ISTimedActionQueue.add(ISReadABook:new(S.p, book, 150)) end
    end)
    S.step(90, function() if S.was.book then S.shot("zed_32_action_bar_reading") else S.notTaken("zed_32_action_bar_reading", "no book in the inventory") end end)
    S.step(5, function() pcall(function() ISTimedActionQueue.clear(S.p) end) end)
    -- resting has no end (ISRestAction maxTime -1): the bar is its icon
    S.step(30, function()
        pcall(function() S.was.endur = S.p:getStats():get(CharacterStat.ENDURANCE) end)
        pcall(function() S.p:getStats():set(CharacterStat.ENDURANCE, 0.4) end)
        local ok = pcall(function() ISTimedActionQueue.add(ISRestAction:new(S.p, nil, false)) end)
        S.was.rest = ok
    end)
    S.step(90, function()
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        local cur = q and q.queue and q.queue[1]
        S.say("endless: current action " .. tostring(cur and cur.Type) .. ", maxTime " .. tostring(cur and cur.maxTime))
        if cur and (tonumber(cur.maxTime) or 0) < 0 then S.shot("zed_32b_action_endless")
        else S.notTaken("zed_32b_action_endless", "the rest action did not start") end
    end)
    S.step(5, function()
        pcall(function() ISTimedActionQueue.clear(S.p) end)
        pcall(function() if S.was.endur then S.p:getStats():set(CharacterStat.ENDURANCE, S.was.endur) end end)
        pcall(G.nearZombies, false)
        pcall(function() S.p:getStats():set(CharacterStat.HUNGER, 0); S.p:getStats():set(CharacterStat.THIRST, 0) end)
    end)
    S.zoomTo(1.0)
end

function S.lotEnd()
    S.step(5, function()
        S.groundBack()
        S.sortBack()
        S.putBackCommon()
        S.openPair()
        pcall(GAL.stand)
    end)
    S.step(30, function()
        pcall(function() if ZEDQA_LAYOUT_BACK and S.was.layout then ZEDQA_LAYOUT_BACK(S.was.layout, S.tag) end end)
        S.say("put back: options, theme, grid views, sorts, tint, given things, ground things, window places, speed, god mode")
        S.say("DONE")
    end)
end

-- ===================================================================== the QA home (gb19ah)
function S.sqAt(x, y, z) return getCell():getGridSquare(x, y, z) end
function S.freeSq(x, y, z)
    local sq = S.sqAt(x, y, z)
    local ok = false
    if sq then pcall(function() ok = sq:isFree(false) and not sq:getVehicleContainer() end) end
    return ok and sq or nil
end
S.RING = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
function S.ring(x, y, z)
    local here = S.freeSq(x, y, z)
    local all, sides = {}, {}
    if not (here and here:getRoom()) then return all, sides end
    for i, d in ipairs(S.RING) do
        local n = S.freeSq(x + d[1], y + d[2], z)
        local reach = false
        if n then pcall(function() reach = n:getRoom() ~= nil and here:canReachTo(n) end) end
        if reach then all[#all + 1] = n; if i <= 4 then sides[#sides + 1] = n end end
    end
    return all, sides
end
function S.findSpot(cx, cy, cz, rad)
    for r = 0, rad do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local all, sides = S.ring(cx + dx, cy + dy, cz)
                    if #all >= 4 and #sides >= 3 then return { x = cx + dx + 0.5, y = cy + dy + 0.5, z = cz, all = all, sides = sides } end
                end
            end
        end
    end
    return nil
end
function S.moveTo(x, y, z)
    S.p:teleportTo(x, y, z)
    pcall(function() S.p:setX(x); S.p:setY(y); S.p:setZ(z); S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z) end)
end
S.STORE = { x0 = 12052, y0 = 7117, x1 = 12069, y1 = 7126 }   -- the Fossoil at West Point
function S.grid(on)
    local W = S.was
    if W.elec then W.elec:setValue(on and 99999 or W.elecWas); pcall(function() W.so:toLua() end) end
    if W.watr then W.watr:setValue(on and 99999 or W.watrWas); pcall(function() W.so:toLua() end) end
    getWorld():setHydroPowerOn(on and true or W.hydro)
end
function S.addObj(obj, sq)
    sq:AddSpecialObject(obj)
    if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
    S.placed[#S.placed + 1] = obj
    return obj
end
function S.putStove(spr, sq)
    if not sq then return nil end
    local obj = IsoStove.new(getCell(), sq, getSprite(spr))
    pcall(function() obj:createContainersFromSpriteProperties() end)
    return S.addObj(obj, sq)
end
function S.laundryTile(cls)
    for i = 0, 47 do
        local name = "appliances_laundry_01_" .. i
        local spr = getSprite(name)
        local props = spr and spr:getProperties()
        if props and props:has("IsoType") and props:get("IsoType") == cls then return name end
    end
    return nil
end
function S.putMachine(cls, sq)
    local tile = S.laundryTile(cls)
    if not (tile and sq) then S.say("note: no tile or square for " .. cls); return nil end
    local obj
    pcall(function()
        if cls == "IsoClothingWasher" then obj = IsoClothingWasher.new(getCell(), sq, getSprite(tile))
        elseif cls == "IsoClothingDryer" then obj = IsoClothingDryer.new(getCell(), sq, getSprite(tile))
        else obj = IsoCombinationWasherDryer.new(getCell(), sq, getSprite(tile)) end
    end)
    if not obj then return nil end
    pcall(function() obj:createContainersFromSpriteProperties() end)
    pcall(function() obj:createFluidContainersFromSpriteProperties() end)
    S.addObj(obj, sq)
    if cls == "IsoCombinationWasherDryer" then pcall(function() obj:setModeWasher() end) end
    local shirt
    pcall(function() shirt = obj:getContainer():AddItem("Base.Tshirt_DefaultTEXTURE_TINT") end)
    if shirt then S.added[#S.added + 1] = shirt end
    if cls ~= "IsoClothingDryer" then
        pcall(function() obj:getModData().canBeWaterPiped = nil end)
        pcall(function() obj:setUsesExternalWaterSource(false) end)
        pcall(function() if (obj:getFluidAmount() or 0) <= 0 then obj:addFluid(FluidType.Water, 20) end end)
    end
    return obj
end
function S.clearPlaced()
    pcall(function() ZeD.TwoWayFull.close(S.pn) end)
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    pcall(function() ZeD.Stations.unbind(S.p) end)
    pcall(function() if S.WWm.closeObjectCard then S.WWm.closeObjectCard() end end)
    for _, obj in ipairs(S.placed) do
        pcall(function() if obj.isActivated and obj:isActivated() then obj:setActivated(false) end end)
        pcall(function() if obj.Activated and obj:Activated() then obj:Toggle() end end)
        pcall(function() local dd = obj.getDeviceData and obj:getDeviceData(); if dd then dd:setIsTurnedOn(false) end end)
        local sq = obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end
    end
    S.placed, S.objs = {}, {}
end
-- pop a world object's face out beside the character (ZeD.FacePop: faces on, safe mode off)
function S.popOut(obj)
    local FP = ZeD.FacePop
    if not (FP and obj) then return false end
    pcall(function() ZeD.TwoWayFull.close(S.pn) end)
    local ok, r = pcall(FP.open, S.p, obj)
    return ok and r == true
end
function S.popShot(key, name, prep)
    S.step(10, function()
        local o = S.objs[key]
        if prep and o then pcall(prep, o) end
        S.was.popped = o and S.popOut(o) or false
        if o and not S.was.popped then S.say("note: " .. key .. ": FacePop.open said no (faces on " .. tostring(ZeD.FacePop and ZeD.FacePop.on and ZeD.FacePop.on()) .. ")") end
    end)
    S.step(60, function() end)
    S.still(5, function()
        if not S.objs[key] then S.notTaken(name, key .. " not placed"); return end
        if not S.was.popped then S.notTaken(name, "the face did not pop out"); return end
        S.shot(name)
    end)
    S.step(5, function() pcall(function() ZeD.TwoWayFull.close(S.pn) end) end)
end
function S.platePress(id)
    local ST, SA = ZeD.Stations, ZeD.StationAppliance
    local w = S.WW()
    for _, z in ipairs((w and w._craftState and w._craftState.zones) or {}) do
        if z.type == "plate" and z.id == id then
            SA.onClick(w, w._craftState, ST.current(S.p), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
            return true
        end
    end
    return false
end

function S.homeStart()
    S.step(10, function()
        S.saveCommon()
        local W = S.was
        W.home = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        W.so = getSandboxOptions()
        W.elec = W.so and W.so:getOptionByName("ElecShutModifier")
        W.watr = W.so and W.so:getOptionByName("WaterShutModifier")
        W.elecWas, W.watrWas = W.elec and W.elec:getValue(), W.watr and W.watr:getValue()
        W.hydro = getWorld():isHydroPowerOn()
        W.prim, W.sec = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
        if getGameSpeed() <= 0 then setGameSpeed(1) end
        S.clean()
        S.grid(true)
        S.openPair()
        S.spot = S.findSpot(math.floor(W.home.x), math.floor(W.home.y), math.floor(W.home.z), 45)
        if not S.spot then
            W.travelled, W.t0 = true, getTimestampMs()
            S.say("no room in reach: to the Fossoil at West Point")
            S.moveTo(math.floor((S.STORE.x0 + S.STORE.x1) / 2) + 0.5, math.floor((S.STORE.y0 + S.STORE.y1) / 2) + 0.5, 0)
        end
    end)
    S.waitFor(5, 3000, function()
        local W = S.was
        return not W.travelled or (S.sqAt(S.STORE.x0, S.STORE.y0, 0) ~= nil and S.sqAt(S.STORE.x1, S.STORE.y1, 0) ~= nil and getTimestampMs() - W.t0 > 9000)
    end, function()
        if S.was.travelled then S.spot = S.findSpot(math.floor((S.STORE.x0 + S.STORE.x1) / 2), math.floor((S.STORE.y0 + S.STORE.y1) / 2), 0, 12) end
        if S.spot then
            S.moveTo(S.spot.x, S.spot.y, S.spot.z)
            S.say(string.format("indoors at %d,%d: %d room squares round, %d sides", math.floor(S.spot.x), math.floor(S.spot.y), #S.spot.all, #S.spot.sides))
        else S.say("ERR no room square with free room squares round it") end
    end)
    S.step(60, function()
        S.look()
        S.charTab("loot"); S.worldTab("loot")
        local g = false
        pcall(function() g = S.p:getCurrentSquare():hasGridPower() end)
        S.say("grid power here " .. tostring(g) .. " | faces on " .. tostring(ZeD.FacePop and ZeD.FacePop.on and ZeD.FacePop.on()))
    end)
end

function S.homeOvens()
    local ST = ZeD.Stations
    S.step(10, function()
        local sides = S.spot and S.spot.sides or {}
        S.objs.oven = S.putStove("appliances_cooking_01_12", sides[1])
        S.objs.micro = S.putStove("appliances_cooking_01_24", sides[2])
        S.say("placed: oven " .. tostring(S.objs.oven ~= nil) .. ", microwave " .. tostring(S.objs.micro ~= nil))
    end)
    S.step(30, function() S.worldTab("craft") end)
    S.step(10, function() S.was.ovenTab = (ST and S.objs.oven and ST.open(S.p, S.objs.oven)) and true or false end)
    S.step(90, function() end)
    S.still(5, function()
        if not S.was.ovenTab then S.notTaken("zqa_ap_1_tab_stove", "the oven did not open in the Craft tab"); return end
        local btn = false
        for _, z in ipairs((S.WW()._craftState and S.WW()._craftState.zones) or {}) do if z.type == "popout" then btn = true end end
        S.say("the Craft tab's pop-out button: " .. tostring(btn))
        S.shot("zqa_ap_1_tab_stove")
    end)
    -- BAKE started on the tab's plate (gallery_t14_indoor's presses), then popped out
    for _, id in ipairs({ "bake", "d1", "d7", "d5", "start" }) do S.step(8, function() S.platePress(id) end) end
    S.step(60, function() S.say("oven on " .. tostring(S.objs.oven and S.objs.oven:Activated())) end)
    S.popShot("oven", "zqa_ap_2b_popout_stove_on")
    S.step(5, function()
        pcall(function() if S.objs.oven:Activated() then S.objs.oven:Toggle() end end)
        pcall(function() ST.unbind(S.p) end)
        S.worldTab("loot")
    end)
    S.popShot("micro", "zqa_ap_4_popout_microwave")
    S.step(10, function() S.clearPlaced() end)
end

function S.homeLaundry()
    S.step(10, function()
        local sides = S.spot and S.spot.sides or {}
        S.objs.washer = S.putMachine("IsoClothingWasher", sides[1])
        S.objs.dryer = S.putMachine("IsoClothingDryer", sides[2])
        S.objs.combo = S.putMachine("IsoCombinationWasherDryer", sides[3])
        S.say("machines placed " .. #S.placed)
    end)
    S.step(60, function() end)
    S.popShot("washer", "g14_ldy_washer", function(o) o:setActivated(true) end)
    S.step(5, function() pcall(function() S.objs.washer:setActivated(false) end) end)
    S.popShot("dryer", "g14_ldy_dryer")
    S.popShot("combo", "g14_ldy_combo")
    S.step(10, function() S.clearPlaced() end)
end

function S.homeRadios()
    S.step(10, function()
        local ring = S.spot and S.spot.all or {}
        pcall(function()
            local sq = ring[1]
            local o = IsoRadio.new(getCell(), sq, getSprite("appliances_radio_01_0"))
            sq:AddTileObject(o)
            S.placed[#S.placed + 1] = o
            S.objs.radio = o
        end)
        pcall(function()
            local sq = ring[2]
            local o = IsoTelevision.new(getCell(), sq, getSprite("appliances_television_01_1"))
            sq:AddTileObject(o)
            S.placed[#S.placed + 1] = o
            S.objs.tv = o
        end)
        S.say("placed: radio " .. tostring(S.objs.radio ~= nil) .. ", TV " .. tostring(S.objs.tv ~= nil))
    end)
    S.step(30, function()
        for _, k in ipairs({ "radio", "tv" }) do
            pcall(function() local dd = S.objs[k]:getDeviceData(); dd:setDeviceVolume(0.3); dd:setIsTurnedOn(true) end)
        end
    end)
    S.popShot("radio", "g19_radio_popout")
    -- the TV in the World window's Radio tab: its tab and title say Television, the TV icon
    S.waitFor(10, 600, function()
        for _, r in ipairs(S.WW()._radios or {}) do if r.radioInstance == S.objs.tv then return true end end
        return S.objs.tv == nil
    end, function()
        for i, r in ipairs(S.WW()._radios or {}) do if r.radioInstance == S.objs.tv then S.WW()._radioIdx = i end end
        S.worldTab("radio")
    end)
    S.waitFor(5, 600, function() local t = S.WW()._radioTw; return S.objs.tv == nil or (t ~= nil and t.dev == S.objs.tv) end, function() end)
    S.step(30, function() end)
    S.still(5, function()
        local t = S.WW()._radioTw
        if not S.objs.tv then S.notTaken("g19_tv_tab", "no TV placed"); return end
        if not (t and t.dev == S.objs.tv) then S.say("note: g19_tv_tab: the Radio tab shows " .. tostring(t and t.dev)) end
        S.shot("g19_tv_tab")
    end)
    S.step(10, function() S.worldTab("loot"); S.clearPlaced() end)
end

function S.homeEnd()
    -- back home (outdoors): the speed bubble over the character, windows shut
    S.step(10, function()
        local W = S.was
        S.grid(false)
        S.moveTo(W.home.x, W.home.y, W.home.z)
        W.t0 = getTimestampMs()
    end)
    S.waitFor(5, 3000, function()
        local h = S.was.home
        return S.sqAt(math.floor(h.x), math.floor(h.y), math.floor(h.z)) ~= nil and getTimestampMs() - S.was.t0 > 3000
    end, function() S.closePair() end)
    S.step(30, function()
        pcall(function() S.p:setDir(IsoDirections.SE) end)
        if ZEDQA_SPEED then ZEDQA_SPEED(2) else setGameSpeed(2) end
    end)
    S.step(60, function()
        local sp = getGameSpeed()
        if sp == 2 then S.shot("zqa_b19_speed_bubble") else S.notTaken("zqa_b19_speed_bubble", "the game speed is " .. tostring(sp)) end
        if ZEDQA_SPEED then ZEDQA_SPEED(1) else setGameSpeed(1) end
    end)
    S.step(10, function()
        local W = S.was
        S.clearPlaced()
        S.putBackCommon()
        pcall(function() S.p:setPrimaryHandItem(W.prim); S.p:setSecondaryHandItem(W.sec) end)
        S.openPair()
    end)
    S.step(30, function()
        pcall(function() if ZEDQA_LAYOUT_BACK and S.was.layout then ZEDQA_LAYOUT_BACK(S.was.layout, S.tag) end end)
        S.say(string.format("put back: things taken away, grid and water, options, theme, speed, god mode, window places; at %d,%d",
            math.floor(S.p:getX()), math.floor(S.p:getY())))
        S.say("DONE")
    end)
end

-- ===================================================================== run
-- GB19A_ONLY = { hero = true } (set before this script, e.g. "GB19A_ONLY = { hero = true }" in a one-line setter run
-- ahead of it) takes only those lot sections: grid, hero, cards, menus, hud. Cleared at the end.
S.only = GB19A_ONLY
GB19A_ONLY = nil
function S.want(k) return (not S.only) or S.only[k] == true end
if S.lot then
    S.lotStart()
    if S.want("grid") then S.lotGrid() end
    if S.want("hero") then S.lotHero() end
    if S.want("cards") then S.lotCards() end
    if S.want("menus") then S.lotMenus() end
    if S.want("hud") then S.lotHud() end
    S.lotEnd()
else
    if not (ZeD.FacePop and ZeD.TwoWayFull and ZeD.Stations and ZeD.StationAppliance) then
        S.say("ERR the pop-out or station modules are not loaded"); S.say("DONE"); return
    end
    S.homeStart()
    S.homeOvens()
    S.homeLaundry()
    S.homeRadios()
    S.homeEnd()
end
Events.OnPreUIDraw.Add(S.tick)
S.say("start (" .. (S.lot and "the mall lot" or "the QA home") .. ", " .. #S.Q .. " steps)")
