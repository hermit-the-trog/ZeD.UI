-- ZeDUI/tools/qa/gallery_loadouts.lua  (Oct 30 2026)
-- Workshop gallery, the Loadouts card (0.2.0-t13, the director: "call out the new load outs"):
-- after gallery_v3_core.lua, gallery_v3_stage.lua and gallery_v3_zed.lua (the pair placed, the
-- scene staged), before gallery_v3_teardown.lua. Makes a loadout "Supply run" from what the
-- character carries (the machete in the main hand, apples and water by the day) and two things
-- it lacks (bandages, a hammer), then three full 4K screenshots in Zomboid/Screenshots:
--   zed_70_loadout_save   the right-click menu as a list on the machete: Save to loadout
--   zed_71_loadout_fold   the Equip tab, list view, Equipped folded, the Loadouts fold open
--   zed_72_loadout_todo   the to-do's top: the loadout, applied, the load after restock
--   zed_73_loadout_todo_lines  the to-do scrolled to its foot: the lines and their states
-- Puts back the character's lists, the menu look, the view, the fold and the tab.
-- "ZEDQA glo ..." ending "ZEDQA glo DONE".
local p = getPlayer()
local pn = p:getPlayerNum()
local L, R, EL = ZeD.Lists, ZeD.Restock, ZeD.EquipLoadout
local Opt = ZeD.Settings
local function say(s) print("ZEDQA glo " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot(n .. ".png") end); say("shot " .. n) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = deepCopy(v) end
    return o
end
local md = p:getModData()
local was = { lists = deepCopy(md.ZeD_Lists), ctx = Opt.contextStyleOption:getValue(), view = ZeD.EquipDoll.view(),
              fold = EL.openFor[pn], tab = cw() and cw()._activeTab, listExp = cw() and cw()._equipListExpanded }
local function line(t) t.amount = t.amount or 1; t.unit = t.unit or "n"; t.place = t.place or "inv"; t.rule = t.rule or "any"; return t end
local function found(ft)
    local items = p:getInventory():getAllTypeRecurse(ft)
    return items and items:size() > 0 and items:get(0) or nil
end
local function closeMenus()
    local ui = UIManager.getUI()
    for i = ui:size() - 1, 0, -1 do
        local t = ui:get(i):getTable()
        if t and (t.Type == "ZeD_ContextMenu" or t.Type == "ZeD_ContextList") and t._ctx and t._ctx.open then pcall(function() t:close() end) end
    end
end

local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

step(5, function()
    local machete = found("Base.Machete")
    say("machete " .. tostring(machete ~= nil) .. ", apple " .. tostring(found("Base.Apple") ~= nil))
    md.ZeD_Lists = nil
    local lo = L.create(p, "loadout", "Supply run")
    local id = lo.id
    if machete then L.addLine(p, id, line({ sec = "gear", place = "hand:main", rule = "this", type = "Base.Machete", itemId = machete:getID(), name = machete:getDisplayName() })) end
    L.addLine(p, id, line({ sec = "gear", type = "Base.Hammer", name = "Hammer" }))
    L.addLine(p, id, line({ sec = "supply", per = "day", type = "Base.Apple", name = "Apple", amount = 2 }))
    L.addLine(p, id, line({ sec = "supply", per = "day", kind = "water", unit = "l", type = "Base.WaterBottle", name = "Water", amount = 1 }))
    L.addLine(p, id, line({ sec = "supply", per = "fixed", type = "Base.Bandage", name = "Bandage", amount = 4 }))
    R.setLoadout(p, id); R.setDays(p, 2)
    EL.plan(cw(), true)
end)
-- 1. the right-click menu as a list, on the machete (Save to loadout near the foot)
step(10, function()
    Opt.contextStyleOption:setValue(2)
    local it = found("Base.Machete") or found("Base.Apple")
    local w = cw()
    ISInventoryPaneContextMenu.createMenu(pn, true, { it }, w:getX() + math.floor(w:getWidth() * 0.42), w:getY() + math.floor(w:getHeight() * 0.22))
end)
step(40, function() shot("zed_70_loadout_save") end)
step(5, function() closeMenus(); Opt.contextStyleOption:setValue(was.ctx) end)
-- 2. the Equip tab: the list view, Equipped folded, the Loadouts fold open under it
step(10, function()
    local w = cw()
    ZeD.EquipDoll.setView("list")
    w._activeTab = "equip"; w._drawerMode = "tab"; w._drawerOpen = true
    w._equipSelected = nil; w._equipListExpanded = false
    EL.openFor[pn] = true
    if w._equipScroll then w._equipScroll:setScrollPos(0) end
    EL.plan(w, true)
end)
step(60, function()
    local s = EL.state(cw())
    say("ready " .. tostring(s.readyN) .. " of " .. tostring(s.readyM))
    shot("zed_71_loadout_fold")
end)
-- 3. the to-do
step(5, function() EL.openTodo(cw()) end)
step(60, function() shot("zed_72_loadout_todo") end)
-- the to-do scrolled to its foot: the lines, each with its state
step(5, function() local s = EL.state(cw()); if s.scroll then s.scroll:setScrollPos(1) end end)
step(40, function() shot("zed_73_loadout_todo_lines") end)
-- put back
step(5, function()
    local w = cw()
    EL.closeTodo(w)
    md.ZeD_Lists = was.lists
    L.gen = L.gen + 1
    pcall(function() R.touch() end)
    ZeD.EquipDoll.setView(was.view)
    EL.openFor[pn] = was.fold
    w._equipListExpanded = was.listExp
    w._activeTab = was.tab or "loot"
    say("put back")
end)
step(20, function() say("DONE") end)

local function onTick()
    if qi >= #Q then Events.OnTick.Remove(onTick); return end
    wait = wait + 1
    if wait < Q[qi + 1].n then return end
    wait = 0
    qi = qi + 1
    local ok, e = pcall(Q[qi].fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
end
Events.OnTick.Add(onTick)
say("start")
