-- ZeDUI/tools/qa/zedqa_card_pad.lua  (Oct 17 2026)
-- In game on the ZeD-QA save, the pad simulated: select a hammer in the
-- Character window's inventory (A), press Left and land on the item card, move
-- across its buttons, check the card's button rects sit on the card (mouse),
-- then B closes it. Also checks Left/Right on the Health tab still reach the
-- tab drawer and the inventory. grep "ZEDQA cp".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local function say(s) print("ZEDQA cp " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function where(tag)
    local w = cw(); local z = Focus.getFocusedZone(w); local e = Focus.getFocusedElement(w)
    say(tag .. ": zone=" .. tostring(z and z.zone) .. " el=" .. tostring(e and e.id))
end
local function zoneIdx(w, name)
    for i, z in ipairs(w._focusRing or {}) do if z.zone == name then return i, z end end
end
local apple
at(2, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
at(20, function()
    Focus.claimFocus(cw()); tab("loot")
    apple = p:getInventory():AddItem("Base.Hammer")
end)
at(50, function()
    local w = cw(); local zi, z = zoneIdx(w, "charMainInv")
    for ei, el in ipairs(z and z.elements or {}) do
        if el.item == apple then
            w._focusIdx = zi; z.focusedElementIdx = ei
            if el.onFocus then el.onFocus(w, el) end
            el.onActivate(w, el)   -- A = select: opens the card
            say("selected the apple row " .. ei)
        end
    end
end)
at(80, function()
    local w = cw(); local _, z = zoneIdx(w, "charItemCard")
    local ids = {}
    for _, el in ipairs(z and z.elements or {}) do ids[#ids + 1] = el.id end
    say("card open " .. tostring(w._drawerItem == apple) .. " | card buttons " .. #ids .. " {" .. table.concat(ids, ",") .. "}")
    local c = w._itemCard; local r = c and c.toggleRects and c.toggleRects[1]
    if c and r then
        local ax, ay = c:getAbsoluteX(), c:getAbsoluteY()
        local on = r.x >= ax and r.x + r.w <= ax + c:getWidth() and r.y >= ay and r.y + r.h <= ay + c:getHeight()
        say("fav chip rect on the card (mouse): " .. tostring(on))
    end
    where("before left")
    Focus.dispatchJoypadDir(w, "left")
    where("after left (expect charItemCard)")
end)
at(100, function()
    pcall(function() getCore():TakeFullScreenshot("zqa_cp_card.png") end)
end)
at(110, function() Focus.dispatchJoypadDir(cw(), "right"); where("right 1") end)
at(120, function() Focus.dispatchJoypadDir(cw(), "right"); where("right 2") end)
at(130, function() Focus.dispatchJoypadDir(cw(), "left"); where("left") end)
at(140, function()
    local w = cw(); local e = Focus.getFocusedElement(w)
    if e and e.onCancel then e.onCancel(w, e) end
    say("after B: card item " .. tostring(w._drawerItem) .. " (expect nil)")
end)
-- regression: the Health tab, inventory <-> drawer
at(160, function() tab("health") end)
at(190, function()
    local w = cw(); local zi, z = zoneIdx(w, "charMainInv")
    w._focusIdx = zi; z.focusedElementIdx = 1
    Focus.dispatchJoypadDir(w, "left"); where("health: inv then left (expect charTabContent)")
end)
at(200, function() Focus.dispatchJoypadDir(cw(), "right"); where("health: right") end)
at(220, function()
    p:getInventory():Remove(apple); tab("loot")
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 225 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
