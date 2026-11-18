-- ZeDUI/tools/qa/rt_menus.lua  (Nov 18 2026, QA): the release test's right-click menu (RELEASE_TEST.md, rt_menus.lua).
-- The menu ZeD draws for the game's own options: Overrides/ContextMenu.lua (it spawns ZeD's menu on the game's
-- first drawn frame), ZeD_ContextMenu.lua (the strip), ZeD_ContextList.lua (the list), ContextMenuRegistry.lua (an
-- option to an action with its icon) and shared ContextIcons / ContextPxIcons (the icons).
-- For each style of the ZeD setting "Context menu" (1 the strip, 2 the list; zedqa_ctxlist.lua, zedqa_ctx_icons.lua):
--   1. a tool given to the bag (a kind the bag does not hold, so its row is its own) is right-clicked on its row in
--      the Character window (the list's own right-click handler); ZeD's menu of that style opens on it;
--   2. every row, and every row of its submenus, has its icon (a pixel icon, the game's picture, or a checkbox);
--   3. on screen: RT.bounds, and for the list (a full-screen layer RT.bounds skips) every level's box;
--   4. a submenu opens (Move To, ZeD's own, always has one) and backs out;
--   5. a pick runs the game's own option: Equip Primary, and the tool is in the hand once the action is done.
-- The style, the hands, the scroll, the tab and the pair are put back; the tools are taken back.
-- Copy to Zomboid/Lua/ after rt_kit.lua; grep "ZEDQA rt_menu".

local Q = RT.make("rt_menu")
local S = { p = RT.p, pn = RT.pn, dead = false, tools = {}, scroll = {} }
local H = {}

local function step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
local function waitFor(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end

-- ===================================================================== helpers
function H.cc() local w = RT.cw(); return w and w._mainContent end
function H.opt() return ZeD.Settings and ZeD.Settings.contextStyleOption end
function H.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
function H.closeMenu()
    local m = H.menu()
    if m then pcall(function() m:close() end) end
end
function H.queueEmpty()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return not q or not q.queue or #q.queue == 0
end
function H.zone(c, id)
    for _, z in ipairs(c and c._hitZones or {}) do if z.id == id then return z end end
    return nil
end
function H.reveal(c, item)
    local s = c and c._scroll
    local y = c and c._itemRenderYMap and c._itemRenderYMap[item]
    if not (s and y) then return end
    if S.scroll[c] == nil then S.scroll[c] = s.scrollPos or 0 end
    if not (s.visible and s.barSizeRatio and s.barSizeRatio > 0 and s.barSizeRatio < 1) then return end
    local vis = s.height
    local range = vis / s.barSizeRatio - vis
    if range <= 0 then return end
    local logical = y - s.y + math.floor(s.scrollPos * range)
    s:setScrollPos(math.max(0, math.min(1, (logical - math.floor(vis / 3)) / range)))
end
function H.rightClick(c, item)
    local z = H.zone(c, item)
    if not z then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c:onRightMouseDown(x, y)
    c:onRightMouseUp(x, y)
    return true
end
function H.same(a, b) return a == b or string.lower(tostring(a)) == string.lower(tostring(b)) end
function H.names(defs)
    local t = {}
    for _, d in ipairs(defs or {}) do t[#t + 1] = tostring(d and d.name) end
    return table.concat(t, ", ")
end
-- a def has its icon: a pixel icon, a picture, or a checkbox in the icon's place (a heading has none)
function H.iconless(defs, out, seen)
    for _, d in ipairs(defs or {}) do
        if type(d) == "table" and not seen[d] then
            seen[d] = true
            -- (Nov 18 2026, Build: the strip's navigation Back is drawn with A.drawBackGlyph, never an icon; its def may
            -- reach here as the "__back" id or by its words, so all three are exempt)
            local back = d.isBack or d.id == "__back" or H.same(d.name, ZeD.tr("UI_ZeD_CtxMenu_Back"))
            if not (d.heading or back or d.pxIcon or d.iconTexture or d.check ~= nil) then
                out[#out + 1] = tostring(d.name) .. " (id " .. tostring(d.id) .. ", isBack " .. tostring(d.isBack) .. ")"
            end
            H.iconless(d.children, out, seen)
        end
    end
    return out
end
function H.count(defs, seen)
    local n = 0
    for _, d in ipairs(defs or {}) do
        if type(d) == "table" and not seen[d] then seen[d] = true; n = n + 1 + H.count(d.children, seen) end
    end
    return n
end
-- the path (names) to the first def named name, at the top or one submenu down
function H.path(defs, name)
    for _, d in ipairs(defs or {}) do if d and H.same(d.name, name) then return { d.name } end end
    for _, d in ipairs(defs or {}) do
        for _, k in ipairs(d and d.children or {}) do if k and H.same(k.name, name) then return { d.name, k.name } end end
    end
    return nil
end
-- open the submenu of the top-level def named name, as the menu's confirm does (a click or A on it)
function H.openSub(m, name)
    if m._levels then
        local lv = m._levels[1]
        for ri, r in ipairs(lv and lv.rows or {}) do
            if r.def and H.same(r.def.name, name) then
                lv.sel = ri
                m:confirm(1)
                local sub = m._levels[2]
                return sub ~= nil and #(sub.rows or {}) > 0, sub and #(sub.rows or {}) or 0
            end
        end
        return false, 0
    end
    for i, d in ipairs(m._ctx.items or {}) do
        if d and H.same(d.name, name) then
            m._ctx.selected = i
            m:confirm()
            local n = #(m._ctx.items or {}) - 1   -- (less the Back cell)
            return #m._ctx.path == 1 and n > 0, n
        end
    end
    return false, 0
end
function H.depth(m)
    if m._levels then return #m._levels end
    return #m._ctx.path + 1
end
-- choose each name in turn and confirm it, as the menu's click does (selection and confirm in one go: the menu
-- follows the real pointer's hover between frames)
function H.pick(m, names)
    if m._levels then
        for depth, nm in ipairs(names) do
            local lv = m._levels[depth]
            if not lv then return false, "no level " .. depth end
            local ri = nil
            for k, r in ipairs(lv.rows or {}) do if not ri and r.def and H.same(r.def.name, nm) then ri = k end end
            if not ri then return false, "no row " .. tostring(nm) end
            lv.sel = ri
            m:confirm(depth)
        end
        return true, "picked"
    end
    for _, nm in ipairs(names) do
        local idx = nil
        for i, d in ipairs(m._ctx.items or {}) do if not idx and d and H.same(d.name, nm) then idx = i end end
        if not idx then return false, "no cell " .. tostring(nm) end
        m._ctx.selected = idx
        m:confirm()
    end
    return true, "picked"
end
-- the list's levels inside the screen (the list is a full-screen layer, which RT.bounds leaves out)
function H.levelsOnScreen(m)
    local W, H2 = getCore():getScreenWidth(), getCore():getScreenHeight()
    local bad = {}
    for i, lv in ipairs(m._levels or {}) do
        if lv.x < -1 or lv.y < -1 or lv.x + lv.w > W + 1 or lv.y + lv.h > H2 + 1 then
            bad[#bad + 1] = string.format("level %d at %d,%d %dx%d", i, math.floor(lv.x), math.floor(lv.y), math.floor(lv.w), math.floor(lv.h))
        end
    end
    return #bad == 0, (#bad == 0) and (#(m._levels or {}) .. " levels inside " .. W .. "x" .. H2) or table.concat(bad, "; ")
end

-- ===================================================================== navigation (Nov 18 2026, the ledger's gaps)
function H.zoneOf(m, id)
    for _, z in ipairs(m and m._hitZones or {}) do if z.id == id then return z end end
    return nil
end
function H.press(m, z)
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    m:onMouseDown(x, y)
    m:onMouseUp(x, y)
end
function H.cats(items)
    local seen, n = {}, 0
    for _, d in ipairs(items or {}) do
        local c = d and not d.isBack and tostring(d.category or "ACTION")
        if c and not seen[c] then seen[c] = true; n = n + 1 end
    end
    return n
end
function H.catAt(m) local d = m._ctx.items[m._ctx.selected]; return d and tostring(d.category or "ACTION") end
function H.stripReset(m, s0)
    m._ctx.selected = s0
    pcall(function() m:_rebuildTrack() end)
end
-- the strip: the pad
function H.stripPad()
    local m = H.menu()
    if not (m and m._ctx and not m._levels) then Q.check(false, "the strip is open for its navigation"); return end
    local N = #m._ctx.items
    local s0 = m._ctx.selected
    m:onJoypadDirRight()
    local s1 = m._ctx.selected
    m:onJoypadDirLeft()
    local s2 = m._ctx.selected
    Q.check(N > 1 and s1 == ((s0 >= N) and 1 or (s0 + 1)) and s2 == s0, "the strip: the pad's D-pad Right steps one cell on, Left steps back",
        s0 .. " -> " .. s1 .. " -> " .. s2 .. " of " .. N)
    if H.cats(m._ctx.items) < 2 then
        Q.skip("the strip: RB / LB jump groups", "this menu has one group only")
    else
        local c0 = H.catAt(m)
        m:onJoypadDown(Joypad.RBumper)
        local c1 = H.catAt(m)
        m:onJoypadDown(Joypad.LBumper)
        local c2 = H.catAt(m)
        Q.check(c1 ~= c0 and c2 == c0, "the strip: the pad's RB jumps to the next group, LB back to the group before", c0 .. " -> " .. tostring(c1) .. " -> " .. tostring(c2))
    end
    H.stripReset(m, s0)
end
-- the strip: the mouse (chevrons page, bumpers jump groups; a strip that does not overflow has no chevrons and its
-- page steps one cell)
function H.stripMouse()
    local m = H.menu()
    if not (m and m._ctx and not m._levels) then Q.check(false, "the strip is open for the mouse"); return end
    local N = #m._ctx.items
    local s0 = m._ctx.selected
    local zr, zl = H.zoneOf(m, "ctxchev_r"), H.zoneOf(m, "ctxchev_l")
    if zr and zl then
        H.press(m, zr)
        local s1 = m._ctx.selected
        H.press(m, zl)
        local s2 = m._ctx.selected
        Q.check(s1 ~= s0 and s2 == s0, "the strip: a click on the right chevron pages on, the left one pages back", s0 .. " -> " .. s1 .. " -> " .. s2 .. " of " .. N)
    else
        Q.check(not m._ctx.truncating, "the strip: a strip that overflows shows its chevrons", "truncating " .. tostring(m._ctx.truncating))
        m:nextPage()
        local s1 = m._ctx.selected
        m:prevPage()
        Q.check(s1 == ((s0 >= N) and 1 or (s0 + 1)) and m._ctx.selected == s0, "the strip: on a strip that does not overflow a page is one cell (" .. N .. " cells)",
            s0 .. " -> " .. s1 .. " -> " .. m._ctx.selected)
    end
    H.stripReset(m, s0)
    local br, bl = H.zoneOf(m, "ctxbump_r"), H.zoneOf(m, "ctxbump_l")
    if not (br and bl) then
        Q.skip("the strip: a click on a bumper jumps groups", "no bumpers drawn on this strip")
    elseif H.cats(m._ctx.items) < 2 then
        Q.skip("the strip: a click on a bumper jumps groups", "this menu has one group only")
    else
        local c0 = H.catAt(m)
        H.press(m, br)
        local c1 = H.catAt(m)
        H.press(m, bl)
        Q.check(c1 ~= c0 and H.catAt(m) == c0, "the strip: a click on the right bumper jumps a group, the left one back",
            c0 .. " -> " .. tostring(c1) .. " -> " .. tostring(H.catAt(m)))
    end
    H.stripReset(m, s0)
    Q.check(H.menu() == m, "the strip stays open through its navigation")
end
-- the list: the pad
function H.rowIdx(lv, name)
    for ri, r in ipairs(lv and lv.rows or {}) do if r.def and H.same(r.def.name, name) then return ri end end
    return nil
end
function H.listPad()
    local m = H.menu()
    local lv = m and m._levels and m._levels[1]
    if not lv then Q.check(false, "the list is open for its navigation"); return end
    local s0 = lv.sel
    m:onJoypadDirDown()
    local s1 = lv.sel
    m:onJoypadDirUp()
    Q.check(s1 ~= nil and s1 ~= s0 and lv.sel == s0, "the list: the pad's Down moves the selection a row, Up back",
        tostring(s0) .. " -> " .. tostring(s1) .. " -> " .. tostring(lv.sel))
    local ri = H.rowIdx(lv, S.moveTo)
    if not ri then Q.check(false, "the list has " .. S.moveTo .. " for its cascade"); return end
    lv.sel = ri
    m:onJoypadDirRight()
    local sub = m._levels[2]
    Q.check(sub ~= nil and sub.sel ~= nil and sub.parentRow == ri, "the list: the pad's Right on " .. S.moveTo .. " opens its submenu, its first row selected",
        "levels " .. #m._levels)
    if sub then
        local okL, why = H.levelsOnScreen(m)
        Q.check(okL and sub.x >= lv.x + lv.w - ZeD.T.px(4), "the list: the submenu cascades beside the list, on screen", why)
    end
    m:onJoypadDirLeft()
    Q.check(#m._levels == 1, "the list: the pad's Left backs out of the submenu", "levels " .. #m._levels)
    lv.sel = s0
    m:onJoypadDirDown()   -- (the pad's selection, for the balloon next)
end
-- the list's balloon: the selected row's words beside it, for the pad at once (when the row has words)
function H.listBalloon()
    local m = H.menu()
    local lv = m and m._levels and m._levels[1]
    if not lv then return end
    local r = lv.rows[lv.sel]
    local def = r and r.def
    local words = def and ((def.body and def.body ~= "") or def.bodyRich or (def.state and def.state(m._ctx.target) ~= ""))
    if not words then
        Q.skip("the list: the balloon for the selected row", "the row " .. tostring(def and def.name) .. " has no words to show")
    else
        Q.check(m._bl ~= nil and m._bl.def == def and m._bl.key == "1:" .. lv.sel, "the list: the balloon shows the selected row's words beside it",
            tostring(m._bl and m._bl.key))
    end
end
-- the list: the mouse (a click on a row with a submenu opens it, as the list's onMouseUp confirms it)
function H.listMouse()
    local m = H.menu()
    local lv = m and m._levels and m._levels[1]
    if not lv then return end
    local ri = H.rowIdx(lv, S.moveTo)
    local z = ri and H.zoneOf(m, "row:1:" .. ri)
    if not z then Q.check(false, "the list's " .. S.moveTo .. " row has its place this frame"); return end
    H.press(m, z)
    Q.check(#m._levels == 2 and m._levels[2].parentRow == ri, "the list: a click on " .. S.moveTo .. " opens its submenu", "levels " .. #m._levels)
    m:cancel()
end
-- the menu's drawn words, caught for a frame
function H.capOn(m)
    if not m then return end
    S.capM, S.capHad, S.capList = m, rawget(m, "drawText"), {}
    local base = m.drawText
    m.drawText = function(self, s, ...)
        S.capList[#S.capList + 1] = tostring(s)
        return base(self, s, ...)
    end
end
function H.capOff()
    if S.capM then S.capM.drawText = S.capHad; S.capM = nil end
end
function H.lightAndHead(sname)
    local m = H.menu()
    local words = S.capList or {}
    H.capOff()
    if not m then Q.check(false, "the " .. sname .. " is open to read its light"); return end
    local R = ZeD.ContextMenu.Registry
    local sel = nil
    if m._levels then
        local lv = m._levels[#m._levels]
        sel = lv and lv.sel and lv.rows[lv.sel] and lv.rows[lv.sel].def
    else
        sel = m._ctx.currentDef
    end
    local hm = m._hlMenu
    Q.check(sel ~= nil and m._hlDef == sel and (hm == nil or hm.highlightedOption == sel.vanillaRef),
        "the " .. sname .. ": the selected option is the one lit in the game's menu (its target outline)",
        tostring(sel and sel.name) .. " / lit " .. tostring(m._hlDef and m._hlDef.name))
    local name = nil
    pcall(function() name = R.getTargetDisplay(m._ctx.target) end)
    local want = S.item and S.item:getDisplayName()
    local okMeta, meta = pcall(R.getMetaFor, m._ctx.target)
    Q.check(name == want and okMeta and type(meta) == "string", "the " .. sname .. ": the target reads as the tool (getTargetDisplay; getMetaFor answers)",
        tostring(name) .. " / meta \"" .. tostring(meta) .. "\"")
    if m._levels then
        local drawn = false
        for _, s in ipairs(words) do if s == want then drawn = true end end
        Q.check(m._levels[1].head and drawn, "the list: its heading names the tool", "drew: " .. table.concat(words, " | "))
    end
end

-- ===================================================================== setup
Q.step(1, function()
    S.pairWas = RT.isOpen()
    RT.pairOpen()
    local o = H.opt()
    if not Q.check(o ~= nil, "ZeD's Context menu setting is there") then S.dead = true; return end
    S.styleWas = o:getValue()
    S.ph, S.sh = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
end)
step(30, function()
    local cw = RT.cw()
    if not Q.check(cw ~= nil and H.cc() ~= nil, "the Character window is open") then S.dead = true; return end
    S.tabWas = cw._activeTab
    RT.charTab("loot")
    local have = {}
    for i = 0, S.p:getInventory():getItems():size() - 1 do have[S.p:getInventory():getItems():get(i):getFullType()] = true end
    for _, ft in ipairs({ "Base.Hammer", "Base.Crowbar", "Base.Screwdriver", "Base.BallPeenHammer", "Base.ClubHammer", "Base.Wrench" }) do
        if #S.tools < 3 and not have[ft] then
            local it = RT.give(ft)
            if it then S.tools[#S.tools + 1] = it end
        end
    end
    if not Q.check(#S.tools == 3, "three tools of kinds the bag does not hold were given", #S.tools .. " given") then S.dead = true end
    -- (the saved pins as found: the pin check below adds one and takes it back)
    local md = S.p:getModData()
    S.pinsWas = md.ZeD_PinnedContextIds
    local c = H.cc()
    if c and c._scroll then S.scroll[c] = c._scroll.scrollPos or 0 end
end)

-- ===================================================================== each style
S.equip = getTextOrNull("ContextMenu_Equip_Primary") or "Equip Primary"
S.moveTo = getTextOrNull("ContextMenu_Move_To") or "Move To"
for si, style in ipairs({ 1, 2 }) do
    local sname = (style == 1) and "strip" or "list"
    local want = (style == 1) and "ZeD_ContextMenu" or "ZeD_ContextList"
    step(4, function()
        H.closeMenu()
        H.opt():setValue(style)
        S.item = S.tools[si]
        H.reveal(H.cc(), S.item)
    end)
    step(6, function()
        Q.check(H.rightClick(H.cc(), S.item), "the " .. sname .. " test: the tool's row in the bag takes a right-click",
            tostring(S.item and S.item:getName()))
    end)
    waitFor(2, 120, function() return H.menu() ~= nil end, function(ok)
        local m = H.menu()
        local has = false
        for _, t in ipairs((m and type(m._ctx.target) == "table") and m._ctx.target or {}) do if t == S.item then has = true end end
        Q.check(ok and m.Type == want and has, "the right-click opens ZeD's " .. sname .. " (" .. want .. ") on the tool",
            "menu " .. tostring(m and m.Type) .. ", on the tool " .. tostring(has))
    end)
    step(4, function()
        local m = H.menu()
        if not m then Q.check(false, "the " .. sname .. " is still open to read"); return end
        local defs = m._ctx.actions
        local missing = H.iconless(defs, {}, {})
        Q.check(#defs > 0 and #missing == 0, "the " .. sname .. ": every row and submenu row has its icon",
            H.count(defs, {}) .. " rows" .. ((#missing > 0) and ("; no icon: " .. table.concat(missing, ", ")) or ""))
        RT.bounds(Q, "the " .. sname .. " open")
        if m._levels then
            local okL, why = H.levelsOnScreen(m)
            Q.check(okL, "the list's box is on screen", why)
        end
        S.top = H.names(defs)
    end)
    if style == 1 then
        -- the strip's navigation: the pad's D-pad steps a cell each way, RB / LB jump to the next / previous group;
        -- the mouse's chevrons page and its bumpers jump groups (the strip's own onJoypad* and onMouseUp)
        step(2, function() H.stripPad() end)
        step(2, function() H.stripMouse() end)
    else
        -- the list's navigation: the pad's Up / Down move the selection, Right opens the selected row's submenu
        -- (a cascade beside it), Left backs out; a click on a submenu row opens it too; the balloon follows the pad
        step(2, function() H.listPad() end)
        step(3, function() H.listBalloon() end)
        step(2, function() H.listMouse() end)
    end
    -- the selection told to the game's menu (Registry.highlight: the outline on a world target); the list's heading
    -- names the target (Registry.getTargetDisplay); the strip has no target card by design
    step(1, function() H.capOn(H.menu()) end)
    step(3, function() H.lightAndHead(sname) end)
    step(2, function()
        local m = H.menu()
        if not m then Q.check(false, "the " .. sname .. " is still open for its submenu"); return end
        local ok, n = H.openSub(m, S.moveTo)
        Q.check(ok, "the " .. sname .. ": " .. S.moveTo .. " opens its submenu", n .. " rows under it; top: " .. tostring(S.top))
    end)
    step(4, function()
        local m = H.menu()
        if not m then Q.check(false, "the " .. sname .. " stays open with its submenu"); return end
        RT.bounds(Q, "the " .. sname .. " with its submenu")
        if m._levels then
            local okL, why = H.levelsOnScreen(m)
            Q.check(okL, "the list and its submenu are on screen", why)
        end
        m:onJoypadDown(Joypad.BButton)   -- (the pad's B: one level back, the menu's own cancel)
        Q.check(H.depth(m) == 1 and H.menu() ~= nil, "the " .. sname .. ": the pad's B backs out of the submenu to the top", "depth " .. H.depth(m))
    end)
    step(2, function()
        local m = H.menu()
        if not m then Q.check(false, "the " .. sname .. " is still open for the pick"); return end
        local path = H.path(m._ctx.actions, S.equip)
        local ok, why = false, "no " .. S.equip .. " in: " .. tostring(S.top)
        if path then ok, why = H.pick(m, path) end
        if not Q.check(ok, "the " .. sname .. ": " .. S.equip .. " is picked", why) then H.closeMenu() end
    end)
    waitFor(5, 900, function() return H.menu() == nil and H.queueEmpty() and S.p:getPrimaryHandItem() == S.item end, function(ok)
        Q.check(ok, "the " .. sname .. "'s pick ran the game's Equip Primary: the tool is in the hand, the menu closed",
            "hand " .. tostring(S.p:getPrimaryHandItem() and S.p:getPrimaryHandItem():getName()) .. ", menu " .. tostring(H.menu() ~= nil))
    end)
end

-- ===================================================================== pinned actions
-- No control in ZeD sets a pin (Registry.togglePin has no caller: FEATURE_MAP's dead list), but saved pins apply:
-- an option whose id is in the player's ZeD_PinnedContextIds comes first in its group, marked pinned. A pin is
-- written for an option that is not first in its group, the menu opened again, and the pin taken back.
function H.pinTarget(defs)
    local firstOf, pick = {}, nil
    for i, d in ipairs(defs or {}) do
        local c = tostring(d.category or "ACTION")
        if not d.heading and not d.isBack then
            if firstOf[c] == nil then firstOf[c] = i
            elseif d.id and not d.pinned then pick = d end
        end
    end
    return pick
end
function H.firstOfCat(defs, cat)
    for _, d in ipairs(defs or {}) do
        if not d.heading and not d.isBack and tostring(d.category or "ACTION") == cat then return d end
    end
    return nil
end
step(4, function()
    H.closeMenu()
    H.opt():setValue(1)
    S.item = S.tools[3]
    H.reveal(H.cc(), S.item)
end)
step(6, function() Q.check(H.rightClick(H.cc(), S.item), "pins: the third tool's row takes a right-click") end)
waitFor(2, 120, function() return H.menu() ~= nil end, function(ok)
    local m = H.menu()
    local d = m and H.pinTarget(m._ctx.actions)
    if not d then Q.skip("pins: a saved pin comes first in its group", "no group with two options on this menu"); H.closeMenu(); return end
    S.pinId, S.pinCat, S.pinName = d.id, tostring(d.category or "ACTION"), tostring(d.name)
    H.closeMenu()
    local md = S.p:getModData()
    md.ZeD_PinnedContextIds = md.ZeD_PinnedContextIds or {}
    S.pinPrev = md.ZeD_PinnedContextIds[S.pinId]
    md.ZeD_PinnedContextIds[S.pinId] = true
end)
step(4, function()
    if not S.pinId then return end
    Q.check(H.rightClick(H.cc(), S.item), "pins: the tool's row takes a right-click again")
end)
waitFor(2, 120, function() return S.pinId == nil or H.menu() ~= nil end, function(ok)
    if not S.pinId then return end
    local m = H.menu()
    local first = m and H.firstOfCat(m._ctx.actions, S.pinCat)
    Q.check(ok and first ~= nil and first.id == S.pinId and first.pinned == true,
        "pins: a saved pin (" .. S.pinName .. ") comes first in its group (" .. S.pinCat .. "), marked pinned",
        "first: " .. tostring(first and first.name) .. ", pinned " .. tostring(first and first.pinned))
    H.closeMenu()
    local pins = S.p:getModData().ZeD_PinnedContextIds
    if pins then pins[S.pinId] = S.pinPrev end
end)

-- ===================================================================== the game's tooltips, restyled
-- (Overrides/Tooltip.lua) A tooltip (ISToolTip) and an item's tooltip (ISToolTipInv, the tool) shown: ZeD's methods
-- draw them (each tooltip's box drawn with ZeD's frame, Atoms.frame, and no error), they take ZeD's frame color, and
-- they sit fully on screen. In safe mode they are the game's: that is rt_system's.
function H.tipWrap(t, cls)
    local pre, ren = cls.prerender, cls.render
    t.prerender = function(s) local ok, e = pcall(pre, s); if not ok then S.tipErr = tostring(e) end end
    t.render = function(s) local ok, e = pcall(ren, s); if not ok then S.tipErr = tostring(e) end end
end
function H.tipCheck(t, label)
    local W, Hs = getCore():getScreenWidth(), getCore():getScreenHeight()
    local x, y, w, h = t:getX(), t:getY(), t:getWidth(), t:getHeight()
    local T = ZeD.T
    local bc = t.borderColor
    Q.check(S.tipFrames[t] == true and S.tipErr == nil and bc ~= nil and T.borderS ~= nil and bc.r == T.borderS.r and bc.g == T.borderS.g and bc.b == T.borderS.b,
        "tooltip: " .. label .. " draws as ZeD's box (its frame, ZeD's frame color, no error)",
        "framed " .. tostring(S.tipFrames[t]) .. ", error " .. tostring(S.tipErr)
        -- (the game's item tooltip draws nothing while its menu says it is showing: ISContextMenu.instance.visibleCheck)
        .. ", the game's menu visibleCheck " .. tostring(ISContextMenu.instance and ISContextMenu.instance.visibleCheck))
    Q.check(w > 2 and h > 2 and x >= -1 and y >= -1 and x + w <= W + 1 and y + h <= Hs + 1, "tooltip: " .. label .. " is on screen",
        string.format("%d,%d %dx%d in %dx%d", math.floor(x), math.floor(y), math.floor(w), math.floor(h), W, Hs))
end
step(4, function()
    H.closeMenu()
    if ZeD.Safe and ZeD.Safe.on() then S.tipSkip = true; Q.skip("tooltip restyled", "safe mode is on: the game's tooltips"); return end
    local V = ISToolTip._zedVanilla
    Q.check(V ~= nil and ISToolTip.render ~= V.render and ISToolTipInv.render ~= V.invRender, "tooltip: ZeD's methods are on the game's tooltips")
    S.tipFrames = {}
    S.atomsFrame = ZeD.Atoms.frame
    ZeD.Atoms.frame = function(panel, ...)
        S.tipFrames[panel] = true
        return S.atomsFrame(panel, ...)
    end
    local ok, err = pcall(function()
        local t = ISToolTip:new()
        t:initialise()
        t:setName(tostring(S.tools[3]:getDisplayName()))
        t.description = "ZeD QA"
        t.followMouse = false
        t:setDesiredPosition(math.floor(getCore():getScreenWidth() / 3), math.floor(getCore():getScreenHeight() / 3))
        H.tipWrap(t, ISToolTip)
        t:addToUIManager()
        t:setVisible(true)
        S.tip = t
        local ti = ISToolTipInv:new(S.tools[3])
        ti:initialise()
        ti:setCharacter(S.p)
        H.tipWrap(ti, ISToolTipInv)
        ti:addToUIManager()
        ti:setVisible(true)
        S.tipInv = ti
    end)
    Q.check(ok, "tooltip: a tooltip and the tool's tooltip are made and shown", tostring(err or ""))
end)
step(6, function()
    if S.tipSkip then return end
    if S.tip then H.tipCheck(S.tip, "a tooltip (ISToolTip)") end
    if S.tipInv then H.tipCheck(S.tipInv, "the tool's tooltip (ISToolTipInv)") end
    H.tipOff()
end)
function H.tipOff()
    for _, k in ipairs({ "tip", "tipInv" }) do
        local t = S[k]
        if t then pcall(function() t:setVisible(false); t:removeFromUIManager() end) end
        S[k] = nil
    end
    if S.atomsFrame then ZeD.Atoms.frame = S.atomsFrame; S.atomsFrame = nil end
end

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    H.closeMenu()
    H.capOff()
    H.tipOff()
    pcall(function()
        local md = S.p:getModData()
        if S.pinsWas == nil then md.ZeD_PinnedContextIds = nil
        elseif S.pinId then S.pinsWas[S.pinId] = S.pinPrev end
    end)
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    if S.styleWas ~= nil then pcall(function() H.opt():setValue(S.styleWas) end) end
    pcall(function() S.p:setPrimaryHandItem(S.ph) end)
    pcall(function() S.p:setSecondaryHandItem(S.sh) end)
    local c = H.cc()
    if c then
        local sel = c._selectedItems or {}
        for k in pairs(sel) do sel[k] = nil end
        c._lastClickedItem = nil
        pcall(function() RT.cw()._updateDrawer(c) end)
    end
end)
Q.step(10, function()
    for c, pos in pairs(S.scroll) do pcall(function() c._scroll:setScrollPos(pos) end) end
    if S.tabWas and S.tabWas ~= "loot" then RT.charTab(S.tabWas) end
    local o = H.opt()
    Q.check(o == nil or o:getValue() == S.styleWas, "the Context menu setting is back as it was", tostring(o and o:getValue()))
    Q.check(S.p:getPrimaryHandItem() == S.ph and S.p:getSecondaryHandItem() == S.sh, "the hands hold what they held")
end)
Q.step(10, function()
    if S.pairWas == false then RT.pairShut() end
end)
Q.start()
