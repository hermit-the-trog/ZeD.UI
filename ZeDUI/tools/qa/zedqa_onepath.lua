-- ZeDUI/tools/qa/zedqa_onepath.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the single-path audit fixes.
--   * an item's menu (as a list): Move To -> the World window's crate, Rename
--   * Rename through the prompt; the card's name row as a pad stop
--   * double-click: a hammer in the main inventory gets equipped
--   * a crate's world menu: Take all
--   * card verbs: DRINK + MORE on a water bottle, SHARPEN on a dull knife
--   * the no-craft chip is vanilla's setNoRecipes
-- Screenshots zqa_op_*.png. grep "ZEDQA op".
local p = getPlayer()
local function say(s) print("ZEDQA op " .. tostring(s)) end
local opt = ZeD.Settings.contextStyleOption
local was = opt:getValue()
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function zm() local v = getPlayerContextMenu(0); return v and v._zedMenu end
local function rows(lv)
    local names = {}
    for _, r in ipairs(lv and lv.rows or {}) do names[#names + 1] = r.sep and "|" or tostring(r.def.name) end
    return table.concat(names, ", ")
end
local function pick(menu, li, text)
    local lv = menu._levels[li]
    for i, r in ipairs(lv.rows) do if r.def and tostring(r.def.name):lower():find(text:lower(), 1, true) then lv.sel = i; return true end end
    return false
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_op_" .. n .. ".png") end) end
local function select(item)
    local w = cw(); local c = w._mainContent
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    sel[item] = true
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
end

local inv = p:getInventory()
local apple, hammer, bottle, knife, crate, crateInv

at(2, function()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    opt:setValue(2)
    apple = inv:AddItem("Base.Apple")
    hammer = inv:AddItem("Base.Hammer")
    bottle = inv:AddItem("Base.WaterBottle")
    pcall(function() bottle:getFluidContainer():addFluid("Water", 0.5) end)
    knife = inv:AddItem("Base.KitchenKnife")
    pcall(function() knife:setSharpness(0.4) end)
    local sq = getCell():getGridSquare(p:getX() + 1, p:getY(), p:getZ())
    crate = IsoObject.new(getCell(), sq, "carpentry_01_16")
    crate:createContainersFromSpriteProperties()
    sq:AddTileObject(crate)
    crateInv = crate:getContainer()
    if crateInv then
        crateInv:setExplored(true)
        crateInv:AddItem("Base.Nails"); crateInv:AddItem("Base.Plank")
    end
    say("crate " .. tostring(crateInv) .. " type " .. tostring(crateInv and crateInv:getType()))
end)
at(40, function()
    local ok = ZeD_WorldWindow.selectContainer and ZeD_WorldWindow.selectContainer(crateInv)
    say("world select crate " .. tostring(ok))
end)
-- 1) the apple's menu, as a list
at(70, function() ISInventoryPaneContextMenu.createMenu(0, true, { apple }, 700, 300) end)
at(90, function()
    local m = zm()
    say("apple menu: " .. rows(m and m._levels[1]))
    if m and pick(m, 1, "Move To") then m:onJoypadDirRight(); say("move to: " .. rows(m._levels[2])) end
end)
at(100, function() shot(1) end)
at(110, function()
    local m = zm()
    local name = ZeD_WorldWindow.getWindow()._containers[ZeD_WorldWindow.getWindow()._activeContainer].name
    if m and pick(m, 2, name) then m:onJoypadDown(Joypad.AButton); say("picked " .. name) else say("no crate row " .. tostring(name)) end
end)
at(400, function() say("apple now in " .. tostring(apple:getContainer() == crateInv and "crate" or apple:getContainer() and apple:getContainer():getType())) end)
-- 2) Rename through the prompt
at(410, function() ISInventoryPaneContextMenu.createMenu(0, true, { hammer }, 700, 300) end)
at(430, function()
    local m = zm()
    say("hammer menu: " .. rows(m and m._levels[1]))
    if m and pick(m, 1, "Rename") then m:onJoypadDown(Joypad.AButton) end
end)
at(450, function()
    local top = ZeD.Prompt and ZeD.Prompt.top and ZeD.Prompt.top()
    say("prompt " .. tostring(top ~= nil) .. " entry " .. tostring(top and top.entry and top.entry:getText()))
    if top and top.entry then top.entry:setText("Old Faithful") end
end)
at(460, function() shot(2) end)
at(470, function()
    local top = ZeD.Prompt.top()
    if top then top:pressPrimary() end
end)
at(480, function() say("hammer name: " .. tostring(hammer:getName()) .. " custom " .. tostring(hammer:isCustomName())) end)
-- 3) the card's name row
at(490, function() select(hammer) end)
at(520, function()
    local card = cw()._itemCard
    local ids = {}
    for _, e in ipairs(card:getActionStripElements()) do ids[#ids + 1] = e.id end
    say("card els: " .. table.concat(ids, ", "))
end)
-- 4) double-click the hammer (main inventory -> equip)
at(530, function()
    local c = cw()._mainContent
    local a = ZeD.InventoryRenderer.doubleClick(c, hammer, 0)
    local b = ZeD.InventoryRenderer.doubleClick(c, hammer, 0)
    say("dbl: first " .. tostring(a) .. " second " .. tostring(b))
end)
at(700, function() say("primary: " .. tostring(p:getPrimaryHandItem() == hammer)) end)
-- 5) the crate's world menu
at(710, function() ISWorldObjectContextMenu.createMenu(0, { crate }, 700, 300, false) end)
at(730, function()
    local m = zm()
    say("crate menu: " .. rows(m and m._levels[1]))
end)
at(740, function() shot(3) end)
at(750, function()
    local m = zm()
    if m and pick(m, 1, "Take all") then m:onJoypadDown(Joypad.AButton); say("take all pressed") end
end)
at(1100, function() say("crate left: " .. tostring(crateInv:getItems():size()) .. " apple home " .. tostring(apple:getContainer() == inv)) end)
-- 6) card verbs
at(1110, function() select(bottle) end)
at(1140, function()
    local hv = {}
    for _, v in ipairs(cw()._itemCard._lastHeaderVerbs or {}) do hv[#hv + 1] = v.label end
    say("bottle verbs: " .. table.concat(hv, ", "))
    shot(4)
end)
at(1150, function() select(knife) end)
at(1180, function()
    local vd = {}
    for _, v in ipairs(cw()._itemCard._verbDefs or {}) do vd[#vd + 1] = v.key end
    say("knife maint: " .. table.concat(vd, ", ") .. " sharp " .. tostring(knife:getSharpness()))
end)
-- 7) no-craft chip = setNoRecipes
at(1190, function()
    ZeD.ActionStrip.setState(knife, "protect", true, 0)
    local a = knife:isNoRecipes(p)
    ZeD.ActionStrip.setState(knife, "protect", false, 0)
    say("nocraft on " .. tostring(a) .. " off " .. tostring(knife:isNoRecipes(p)))
end)
at(1200, function()
    pcall(function() ISTimedActionQueue.clear(p) end)
    if p:getPrimaryHandItem() then p:setPrimaryHandItem(nil) end
    for _, it in ipairs({ apple, hammer, bottle, knife }) do
        local c = it:getContainer(); if c then c:Remove(it) end
    end
    for _, t in ipairs({ "Base.Nails", "Base.Plank" }) do local it = inv:getFirstTypeRecurse(t); if it then it:getContainer():Remove(it) end end
    local sq = crate:getSquare(); if sq then sq:transmitRemoveItemFromSquare(crate); sq:RemoveTileObject(crate) end
    local c = cw()._mainContent
    c._selectedItems = {}; c._lastClickedItem = nil; cw()._updateDrawer(c)
    opt:setValue(was)
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 1205 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
