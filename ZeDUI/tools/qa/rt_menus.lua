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
            if not (d.heading or d.isBack or d.pxIcon or d.iconTexture or d.check ~= nil) then out[#out + 1] = tostring(d.name) end
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
        if #S.tools < 2 and not have[ft] then
            local it = RT.give(ft)
            if it then S.tools[#S.tools + 1] = it end
        end
    end
    if not Q.check(#S.tools == 2, "two tools of kinds the bag does not hold were given", #S.tools .. " given") then S.dead = true end
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
        m:cancel()
        Q.check(H.depth(m) == 1 and H.menu() ~= nil, "the " .. sname .. ": back out of the submenu to the top", "depth " .. H.depth(m))
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

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    H.closeMenu()
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
