-- (Nov 20 2026, QA: OUT OF DATE since beta 21. This script sets one or more of the retired per-piece Simple switches,
-- which nothing reads now (one Style switch: ZeD.Settings.lookStyleOption, 1 Full, 2 Lite). A Simple leg runs against
-- Full; a Full pick is a no-op. To reuse it, set lookStyleOption instead (the value only). Not in the release test.)
-- ZeDUI/tools/qa/gallery_v1_c1_house.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's lived-in retakes in a furnished
-- house in West Point (gallery_v1_c1_common.lua's "kitchen" and "living"; the house at 12021-12033, 7078-7090). ZeD on.
-- Same content and settings as today's captures, same file names; the new rule: the windows at their default places
-- and sizes (ZEDQA_LAYOUT_DEFAULT), then moved to one side (C1.pairSide every frame: both on the left when they fit
-- beside the character, else the Character window on the left edge and the World window on the right edge).
--   THE KITCHEN
--     18 Item Cards     at a glance versus inspected (ADD_ch11_glance_vs_inspected.md; they replace zed_18_card_food
--                       and zed_19_card_weapon): an apple, a machete and a worn padded jacket on the kitchen floor, the
--                       World window on Loot; zed_11g_<food|weapon|clothing>_glance (the pad lands on the row: the light
--                       balloon beside it), then zed_11i_<food|weapon|clothing>_card (picked: the full card, pointer hidden)
--     20 Context Menus  zed_20_ctx_strip, zed_21_ctx_list: the apple's menu from the Character window, strip then list
--     19 List or Grid   zed_13_crafting: the Character window's inventory as a list, the World window on Craft with
--                       the first unlocked recipe open (gallery_v3_zed.lua); zed_53b_grid_tinted: the inventory as a
--                       grid, Item-colored tiles on, light things plus a red axe, a CD, a bat and a wrench, sorted by
--                       name (gallery_b19_a.lua's lotGrid)
--   THE LIVING ROOM
--     29 Every Window   zqa_cw_01_dark_small_card (the apple's card in the Character window, dark, small text),
--                       zqa_cw_02_dark_small_window_menu_theme (the window box's menu, Theme open, the pointer on
--                       Dark: the hover is the point, so the pointer shows), zqa_cw_14_focus_hand_inventory_row (the
--                       list, gamepad mode, the hand on an inventory row) as gallery_nov1_cohesion.lua
--     24 Action Bar     zed_32_action_bar_reading (windows shut, zoom 0.5, hungry and thirsty, reading a book) and
--                       zed_32b_action_endless (resting: ISRestAction, no end, its icon) as gallery_b19_a.lua's lotHud.
--                       Today's two zombies near are left out: a zombie in a living room is not lived-in.
-- Puts back: the options (context style, watch place, action bar, tint, focus style), the theme, the List | Grid
-- choice, sorts, things given and put on the floor, the input mode, the zoom, the stats, the window layout
-- (ZEDQA_LAYOUT_BACK). The place, the grid power and the cheats: gallery_v1_c1_end.lua. grep "ZEDQA c1h".
if not C1 then print("ZEDQA c1h ERR run gallery_v1_c1_common.lua first"); print("ZEDQA c1h DONE"); return end
local S = C1.make("c1h")
if not C1.zed then S.say("ERR ZeD is not loaded: this script is for the ZeD run"); S.say("DONE"); return end
S.p, S.pn, S.inv = C1.p, C1.pn, C1.p:getInventory()
S.CWm, S.WWm = ZeD_CharacterWindow, ZeD_WorldWindow
S.Opt = ZeD.Settings
S.was, S.added = {}, {}

-- ===================================================================== helpers
function S.CW() return S.CWm.getWindow() end
function S.WW() return S.WWm.getWindow() end
function S.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (S.CWm.isOpen() and S.WWm.isOpen()) then
        if S.WWm.isOpen() then S.WWm.close() end
        if S.CWm.isOpen() then S.CWm.toggle(S.pn) end
        S.CWm.toggleBothPaired(S.pn)
    end
end
function S.closePair()
    if S.CWm.isOpen() and S.WWm.isOpen() then S.CWm.toggleBothPaired(S.pn)
    else
        if S.CWm.isOpen() then S.CWm.toggle(S.pn) end
        if S.WWm.isOpen() then S.WWm.close() end
    end
end
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
function S.give(ft)
    local it = nil
    pcall(function() it = S.inv:AddItem(ft) end)
    if it then S.added[#S.added + 1] = it end
    return it
end
function S.take(it)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    for i = #S.added, 1, -1 do if S.added[i] == it then table.remove(S.added, i) end end
end
function S.found(ft)
    local items = S.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
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
        v.c._sortCol, v.c._sortAsc = v.col, v.asc
        for _, cs in ipairs(v.c._colStates or {}) do cs.sortCol, cs.sortAsc = v.col, v.asc end
    end
    S.was.sorts = nil
end
-- one source per window (every extra column off), as gallery_b19_a.lua
function S.oneSource()
    local done = true
    for _, pair in ipairs({ { S.CW(), S.CWm }, { S.WW(), S.WWm } }) do
        local win, mod = pair[1], pair[2]
        if win and #(win._mcSelected or {}) > 1 and mod.toggleColumn then
            for _, j in ipairs(win._mcSelected) do
                local c = win._containers and win._containers[j]
                if c and c.inventory then mod.toggleColumn(c.inventory); done = false; break end
            end
        end
    end
    return done
end
-- a thing on a free floor square of the room beside the character (the k-th fitting side)
function S.dropBeside(ft, k)
    local P = C1.PLACES.kitchen
    local px, py = math.floor(S.p:getX()), math.floor(S.p:getY())
    local n = 0
    for _, d in ipairs({ { 1, 1 }, { 1, 0 }, { 0, 1 }, { -1, 1 }, { 1, -1 }, { -1, 0 }, { 0, -1 }, { -1, -1 } }) do
        if C1.fits(P, C1.sqAt(px + d[1], py + d[2], 0)) then
            n = n + 1
            if n == k then return C1.drop(ft, d[1], d[2]) end
        end
    end
    return C1.drop(ft, 1, 1)
end
function S.weight() return (GAL_UNLOAD and GAL_UNLOAD.weight) and GAL_UNLOAD.weight() or S.inv:getCapacityWeight() end
function S.recipe(open)
    local w = S.WW()
    local st = w and w._craftState
    if not st then return false end
    if not open then pcall(function() ZeD.CraftingCore.closeCraft(st) end); return true end
    local data = ZeD.CraftingTab.gatherData(S.p, w)
    local pick = nil
    for _, rd in ipairs(data and data.recipes or {}) do
        if rd.status == "unlocked" then pick = rd; break end
    end
    pick = pick or (data and data.recipes and data.recipes[1])
    if not pick then return false end
    ZeD.CraftingCore.openCraft(st, pick.entry.name)
    S.say("recipe open: " .. tostring(pick.entry.name))
    return true
end
-- the window box's menu (gallery_nov1_cohesion.lua's)
function S.boxRect(win)
    local b = win and win.windowBoxRect and win:windowBoxRect()
    if not b then return nil end
    local ax, ay = win:getAbsoluteX(), win:getAbsoluteY()
    return math.floor(ax + b.x), math.floor(ay + b.y), math.floor(ax + b.x + b.w), math.floor(ay + b.y + b.h)
end
function S.menu()
    local m = ZeD.WindowMenu and ZeD.WindowMenu.current
    return (m and m._ctx and m._ctx.open) and m or nil
end
function S.menuRow(li, name)
    local m = S.menu()
    local lv = m and m._levels and m._levels[li]
    if not lv then return nil end
    for ri, r in ipairs(lv.rows) do
        if r.def and r.def.name == name then
            for _, zn in ipairs(m._hitZones or {}) do if zn.id == "row:" .. li .. ":" .. ri then return zn end end
        end
    end
    return nil
end
function S.leafName(key)
    local Sx = ZeD.Settings
    for i, k in ipairs(Sx.baseKeys or {}) do if k == key then return ZeD.tr(Sx.baseLabels[i]) end end
    return tostring(key)
end
-- the pad's focus on an inventory row on screen (the hammer's when it is), as gallery_nov1_cohesion.lua
function S.padRow()
    local F = ZeD.Input.Focus
    local w = S.CW()
    F.claimFocus(w)
    local zone = nil
    for _, z in ipairs(w._focusRing or {}) do if z.zone == "charMainInv" then zone = z end end
    if not (zone and zone.focusable) then return false end
    local ch = (w._mainContent and w._mainContent:getHeight()) or 0
    local pref, vis, any = nil, nil, nil
    for _, e in ipairs(zone.elements or {}) do
        if e.item then
            any = any or e
            if ch > 0 and e.y >= 0 and e.y + e.h <= ch then
                vis = vis or e
                if e.item == S.hammer and not pref then pref = e end
            end
        end
    end
    local row = pref or vis or any
    if not row then return false end
    local got = F.focusWhere(w, "charMainInv", function(x) return x == row end)
    if got then F.dispatchJoypadDown(w, "QA") end
    return got and true or false
end
-- every frame: ZeD's windows to one side
function S.hold() C1.pairSide(nil) end

-- ===================================================================== start: the kitchen
C1.go(S, "kitchen")
S.step(10, function()
    local W, Opt = S.was, S.Opt
    W.layout = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() or nil
    W.base, W.accent, W.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    W.ctx = Opt.contextStyleOption:getValue()
    W.watch = Opt.watchPlaceOption:getValue()
    W.bar = Opt.actionBarOption:getValue()
    W.tint = Opt.gridTintOption and Opt.gridTintOption:getValue()
    W.focus = Opt.focusStyle and Opt.focusStyle() or "hand"
    local g = S.p:getModData().ZeD_GridViews
    W.gridHad, W.grid = g ~= nil, g and { player = g.player, world = g.world } or {}
    C1.grid(true)
    Opt.watchPlaceOption:setValue(1)
    Opt.contextStyleOption:setValue(1)
    Opt.actionBarOption:setValue(1)
    S.openPair()
    if ZEDQA_LAYOUT_DEFAULT then ZEDQA_LAYOUT_DEFAULT("c1h") end
end)
S.step(40, function()
    -- Dark + PZ Teal (gallery_b11_look.lua's options), the list view, tiles plain
    local b, a = (GAL_LOOK and GAL_LOOK[1]) or "dark", (GAL_LOOK and GAL_LOOK[2]) or "teal"
    if ZeD.currentBase ~= b or ZeD.currentAccent ~= a then ZeD.applyTheme(b, a, ZeD.currentSize); S.was.themed = true end
    ZeD.InventoryRenderer.setGridKey("player", false, S.p); ZeD.InventoryRenderer.setGridKey("world", false, S.p)
    if S.Opt.gridTintOption then S.Opt.gridTintOption:setValue(1) end
    S.charTab("loot"); S.worldTab("loot")
    C1.extraBoxes = nil
    C1.hold = S.hold
    S.say("look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " size " .. tostring(ZeD.currentSize)
        .. " | screen " .. C1.core:getScreenWidth() .. "x" .. C1.core:getScreenHeight())
end)
S.waitFor(10, 600, function() return S.oneSource() end, function() C1.pairSide(S) end)
S.mark()

-- 18 Item Cards, at a glance versus inspected (workshop/gallery/v1_plan/ADD_ch11_glance_vs_inspected.md; these six
-- replace zed_18_card_food and zed_19_card_weapon). Each pair: one thing on the kitchen floor, the World window on Loot.
--   glance:    the controller lands on its row (gamepad mode locked, the stand-in pad record in JoypadState for the
--              focus calls only, as zedqa_b19_pad.lua's withPad): the light loot balloon stands beside the row at once
--              (5923be905). The pointer is parked BEFORE the pad lands and only hidden at the shot (how.stay): a
--              pointer move turns the focus cues, and so the balloon, off.
--   inspected: the pad let go and the mode unlocked, the thing picked in the World window: its full card in the drawer,
--              the pointer hidden.
S.PAIRS = { { "food", "Base.Apple", 1, 1.0 }, { "weapon", "Base.Machete", 2, 0.85 }, { "clothing", "Base.Jacket_Padded", 3, 0.6 } }
S.fake = { player = S.pn, focus = nil }
function S.withPad(fn)
    if JoypadState.players[S.pn + 1] then S.say("note: a real pad is bound; the stand-in is not used"); return fn() end
    JoypadState.players[S.pn + 1] = S.fake
    local ok, r = pcall(fn)
    JoypadState.players[S.pn + 1] = nil
    pcall(setPlayerButtonsActive, S.pn, true)
    pcall(setJoypadIgnoreAim, S.pn, false)
    if not ok then S.say("ERR withPad: " .. tostring(r)) end
    return r
end
-- the pad onto the World window's row for item (zone worldMainInv, else any World list zone holding it)
function S.padOn(item)
    local F, w = ZeD.Input.Focus, S.WW()
    if not (w and item) then return false end
    pcall(function() ZeD.Input.Detector.setLockedMode("gamepad") end)
    return S.withPad(function()
        F.claimFocus(w)
        local got = F.focusWhere(w, "worldMainInv", function(x) return x.item == item end)
        if not got then
            for _, z in ipairs(w._focusRing or {}) do
                if not got and tostring(z.zone):match("^worldMC%d+$") then got = F.focusWhere(w, z.zone, function(x) return x.item == item end) end
            end
        end
        if got then F.dispatchJoypadDown(w, "QA") end
        return got and true or false
    end)
end
function S.padOff()
    pcall(function() ZeD.Input.Focus.releaseFocus(S.pn) end)
    pcall(function() ZeD.Input.Detector.setLockedMode(nil) end)
end
for _, c in ipairs(S.PAIRS) do
    S.step(5, function()
        S.select(S.WW(), nil)
        S.card = S.dropBeside(c[2], c[3])
        if S.card and c[4] < 1 then pcall(function() S.card:setCondition(math.max(1, math.floor(S.card:getConditionMax() * c[4] + 0.5))) end) end
        S.worldTab("loot")
    end)
    S.still(60, function() C1.pointerHidden() end)
    S.step(10, function() S.was.padOn = S.padOn(S.card) end)
    S.step(15, function()
        local T = ZeD.InvTip
        local want = T and T._want
        S.say(string.format("glance %s: pad on the row %s, balloon wanted for it %s", c[1], tostring(S.was.padOn), tostring(want ~= nil and want.item == S.card)))
        if not S.card then S.notTaken("zed_11g_" .. c[1] .. "_glance", c[2] .. " could not be put on the floor")
        elseif not S.was.padOn then S.notTaken("zed_11g_" .. c[1] .. "_glance", "the pad did not land on its row")
        else S.shot("zed_11g_" .. c[1] .. "_glance", { stay = true }) end
    end)
    S.step(5, function() S.padOff(); if S.card then S.select(S.WW(), S.card) end end)
    S.still(40, function()
        if not S.card then S.notTaken("zed_11i_" .. c[1] .. "_card", c[2] .. " could not be put on the floor"); return end
        local w = S.WW()
        if not (w and w._drawerItem == S.card) then S.say("note: zed_11i_" .. c[1] .. "_card: the World card shows " .. tostring(w and w._drawerItem)) end
        S.shot("zed_11i_" .. c[1] .. "_card")
    end)
    S.step(2, function() S.select(S.WW(), nil) end)
end
S.step(5, function() S.padOff(); C1.groundBack() end)

-- 20 Context Menus: the apple's menu, strip then list
S.step(20, function() S.apple = S.give("Base.Apple") end)
for _, c in ipairs({ { "zed_20_ctx_strip", 1 }, { "zed_21_ctx_list", 2 } }) do
    S.step(20, function()
        S.Opt.contextStyleOption:setValue(c[2])
        local w = S.CW()
        S.menuUp = false
        if not (S.apple and w) then return end
        ISInventoryPaneContextMenu.createMenu(S.pn, true, { S.apple }, w:getX() + math.floor(w:getWidth() * 0.42), w:getY() + math.floor(w:getHeight() * 0.30))
        S.menuUp = true
    end)
    S.step(30, function() if S.menuUp then S.shot(c[1], { keepMenu = true }) else S.notTaken(c[1], "no apple or no Character window") end end)
    S.step(2, function() C1.closeMenus() end)
end
S.step(5, function() S.Opt.contextStyleOption:setValue(1) end)

-- 19 List or Grid: the list with a recipe open, then the tinted grid
S.step(2, function() ZeD.InventoryRenderer.setGridKey("player", false, S.p); S.charTab("loot") end)
S.waitFor(2, 120, function() return S.worldTab("craft") end, function() end)
S.step(10, function() S.was.recipe = S.recipe(true) end)
S.still(60, function()
    if ZeD.InventoryRenderer.isGridKey("player") then ZeD.InventoryRenderer.setGridKey("player", false, S.p) end
    if S.was.recipe then S.shot("zed_13_crafting") else S.notTaken("zed_13_crafting", "no recipe to open on the Craft tab") end
end)
S.step(5, function() S.recipe(false); S.worldTab("loot") end)
S.step(5, function()
    S.fill = {}
    for _, ft in ipairs({ "Base.Apple", "Base.Orange", "Base.Battery", "Base.Bandage", "Base.Pencil", "Base.Matches",
                          "Base.Socks_Ankle", "Base.Spoon", "Base.Lighter", "Base.Scissors", "Base.Needle", "Base.Thread",
                          "Base.Axe", "Base.Disc_Retail", "Base.BaseballBat", "Base.Wrench" }) do
        local it = S.give(ft)
        if not it and ft == "Base.Wrench" then it = S.give("Base.PipeWrench") end
        if it then S.fill[#S.fill + 1] = it end
    end
    -- within the weight limit: the heaviest given things go back first
    local max = 20
    pcall(function() max = S.p:getMaxWeight() end)
    for _, ft in ipairs({ "Base.BaseballBat", "Base.Axe" }) do
        if S.weight() > max - 1 then
            for i = #S.fill, 1, -1 do if S.fill[i]:getFullType() == ft then S.take(S.fill[i]); table.remove(S.fill, i); S.say("given " .. ft .. " taken back (weight)"); break end end
        end
    end
    S.sort(S.CW(), "name", true)
    ZeD.InventoryRenderer.setGridKey("player", true, S.p)
    if S.Opt.gridTintOption then S.Opt.gridTintOption:setValue(2) end
end)
S.still(60, function()
    if not S.Opt.gridTintOption then S.notTaken("zed_53b_grid_tinted", "no Item-colored tiles option in this build"); return end
    S.shot("zed_53b_grid_tinted")
end)
S.step(5, function()
    if S.Opt.gridTintOption then S.Opt.gridTintOption:setValue(1) end
    for _, it in ipairs(S.fill or {}) do S.take(it) end
    S.fill = nil
    S.sortBack()
    ZeD.InventoryRenderer.setGridKey("player", false, S.p)
end)

-- ===================================================================== the living room
C1.go(S, "living")
-- 29 Every Window: dark, small text, three apples and a hammer
S.step(10, function()
    S.openPair()
    S.charTab("loot"); S.worldTab("loot")
    ZeD.applyTheme("dark", (GAL_LOOK and GAL_LOOK[2]) or ZeD.currentAccent, "small")
    S.was.themed = true
    for _ = 1, 2 do S.give("Base.Apple") end
    S.hammer = S.give("Base.Hammer")
    pcall(function() ISInventoryPage.dirtyUI() end)
end)
S.step(30, function() if not S.select(S.CW(), S.apple) then S.say("note: cw_01: the inventory pane is not there to pick the apple") end end)
S.still(30, function() S.shot("zqa_cw_01_dark_small_card") end)
S.step(2, function()
    local w = S.CW()
    if not w then return end
    pcall(function() w:bringToTop() end)
    local x0, y0, x1, y1 = S.boxRect(w)
    C1.pointerShown(true)
    if x0 then pcall(function() Mouse.setXY(math.floor((x0 + x1) / 2), math.floor((y0 + y1) / 2)) end) end
    w:openWindowMenu()
end)
S.waitFor(2, 180, function() return S.menuRow(1, ZeD.tr("UI_ZeD_WinMenu_Theme")) ~= nil end, function(ok)
    if not ok then S.say("note: cw_02: the menu did not draw its Theme row") end
    local m, zn = S.menu(), S.menuRow(1, ZeD.tr("UI_ZeD_WinMenu_Theme"))
    if m and zn then m:onMouseUp(math.floor(zn.x + zn.w / 2), math.floor(zn.y + zn.h / 2)) end
end)
S.waitFor(2, 180, function() return S.menuRow(2, S.leafName(ZeD.currentBase)) ~= nil end, function(ok)
    local zn = S.menuRow(2, S.leafName(ZeD.currentBase))
    if zn then pcall(function() Mouse.setXY(math.floor(zn.x + zn.w / 2), math.floor(zn.y + zn.h / 2)) end)
    else S.say("note: cw_02: the Theme submenu did not draw the theme in use") end
end)
S.step(12, function()
    if S.menu() then S.shot("zqa_cw_02_dark_small_window_menu_theme", { keepMenu = true, pointer = true })
    else C1.pointerShown(false); S.notTaken("zqa_cw_02_dark_small_window_menu_theme", "the window menu is not open") end
end)
S.step(2, function()
    local m = S.menu()
    if m then pcall(function() m:close() end) end
    C1.pointerShown(false)
    S.select(S.CW(), nil)
    ZeD.InventoryRenderer.setGridKey("player", false, S.p)
end)
S.still(30, function() pcall(function() ZeD.Input.Detector.setLockedMode("gamepad") end); pcall(function() S.Opt.setFocusStyle("hand") end) end)
S.step(12, function() S.was.padRow = S.padRow() end)
S.step(12, function()
    if S.was.padRow then S.shot("zqa_cw_14_focus_hand_inventory_row") else S.notTaken("zqa_cw_14_focus_hand_inventory_row", "no inventory row to put the pad on") end
end)
S.step(5, function()
    pcall(function() S.Opt.setFocusStyle(S.was.focus) end)
    pcall(function() ZeD.Input.Focus.releaseFocus(S.pn) end)
    pcall(function() ZeD.Input.Detector.setLockedMode(nil) end)
    pcall(function() ZeD.applyTheme(S.was.base, S.was.accent, S.was.size) end)
end)

-- 24 Action Bar: windows shut, zoom 0.5, reading, then resting
S.step(10, function() S.closePair(); C1.face("SE") end)
S.zoomTo(0.5)
S.step(2, function()
    pcall(function() S.was.hunger = S.p:getStats():get(CharacterStat.HUNGER); S.was.thirst = S.p:getStats():get(CharacterStat.THIRST) end)
    pcall(function() S.p:getStats():set(CharacterStat.HUNGER, 0.3); S.p:getStats():set(CharacterStat.THIRST, 0.35) end)
end)
S.step(60, function()
    local book = S.found("Base.Book") or S.give("Base.Book")
    S.was.book = book ~= nil
    if not book then return end
    local ok = pcall(function() ISInventoryPaneContextMenu.readItem(book, S.pn) end)
    if not ok then pcall(function() ISTimedActionQueue.add(ISReadABook:new(S.p, book, 150)) end) end
end)
S.step(90, function() if S.was.book then S.shot("zed_32_action_bar_reading") else S.notTaken("zed_32_action_bar_reading", "no book") end end)
S.step(5, function() pcall(function() ISTimedActionQueue.clear(S.p) end) end)
S.step(30, function()
    pcall(function() S.was.endur = S.p:getStats():get(CharacterStat.ENDURANCE) end)
    pcall(function() S.p:getStats():set(CharacterStat.ENDURANCE, 0.4) end)
    pcall(function() ISTimedActionQueue.add(ISRestAction:new(S.p, nil, false)) end)
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
    pcall(function() S.p:getStats():set(CharacterStat.HUNGER, S.was.hunger or 0); S.p:getStats():set(CharacterStat.THIRST, S.was.thirst or 0) end)
end)
S.zoomTo(C1.was.zoom or 1.0)

-- ===================================================================== put back
S.mark()
S.step(5, function()
    local W, Opt = S.was, S.Opt
    C1.hold = nil
    C1.closeMenus()
    C1.pointerShown(false)
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    pcall(function() ZeD.Input.Detector.setLockedMode(nil) end)
    C1.groundBack()
    S.sortBack()
    for i = #S.added, 1, -1 do S.take(S.added[i]) end
    pcall(function() Opt.contextStyleOption:setValue(W.ctx) end)
    pcall(function() Opt.watchPlaceOption:setValue(W.watch) end)
    pcall(function() Opt.actionBarOption:setValue(W.bar) end)
    pcall(function() if Opt.gridTintOption and W.tint then Opt.gridTintOption:setValue(W.tint) end end)
    pcall(function() Opt.setFocusStyle(W.focus) end)
    pcall(function()
        local g = S.p:getModData().ZeD_GridViews
        if g then g.player = W.grid.player; g.world = W.grid.world end
        if not W.gridHad then S.p:getModData().ZeD_GridViews = nil end
    end)
    if W.themed then pcall(Opt.reapplyFromOptions) end
    S.openPair()
end)
S.step(30, function()
    if ZEDQA_LAYOUT_BACK then ZEDQA_LAYOUT_BACK(S.was.layout, "c1h") end
    S.say("put back: options, theme, List | Grid, sorts, things given and on the floor, input mode, zoom, stats, window layout")
end)
S.start()
