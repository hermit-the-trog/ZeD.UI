-- ZeD QA suite: Progress Band. Reading via the queue poll + cancel through the card; cooking on a real stove with the danger state.
local p = getPlayer(); local inv = p:getInventory()
local cw = ZeD_CharacterWindow.getWindow(); local ww = ZeD_WorldWindow.getWindow()
if not cw or not ww then print("ZEDQA band: open both windows first") return end
if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end
local M = ZeD.ItemActionManager
local book = inv:getFirstType("Base.Book") or inv:AddItem("Base.Book")
local function desc(a) return "active=" .. tostring(a ~= nil) .. " kind=" .. tostring(a and a.kind) .. " mode=" .. tostring(a and a.mode) .. " label=" .. tostring(a and a.label) .. " pct=" .. tostring(a and a.percent) .. " time=" .. tostring(a and a.timeStr) end
local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
at(5,   function() local c = ZeD_ItemCard:new(0, 0, 220, 300, "drawer", 0); c:initialise(); c.item = book; c.playerNum = 0; c.sourceContext = "inventory"; c:_dispatchHeaderVerb("READ") end)
at(125, function() print("ZEDQA band reading " .. desc(M.getActiveAction(book)) .. " (expect active reading)"); cw._itemCard:setItem(book); pcall(cw._itemCard._dispatchProgressCancel, cw._itemCard) end)
at(185, function() local q = ISTimedActionQueue.getTimedActionQueue(p); print("ZEDQA band after cancel " .. desc(M.getActiveAction(book)) .. " qlen=" .. tostring(q and q.queue and #q.queue) .. " (expect inactive, 0)") end)
at(200, function()
    local cell, px, py, pz = getCell(), math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local stove = nil
    for dx = -20, 20 do for dy = -20, 20 do
        local sq = cell:getGridSquare(px + dx, py + dy, pz)
        if sq then local objs = sq:getObjects(); for i = 0, objs:size() - 1 do local o = objs:get(i); if instanceof(o, "IsoStove") and not (o.isMicrowave and o:isMicrowave()) then stove = stove or o end end end
    end end
    if not stove then print("ZEDQA band: no real stove within 20 tiles; cooking skipped"); print("ZEDQA band done"); return end
    local steak = inv:AddItem("Base.Steak"); local cnt = stove:getContainer()
    inv:Remove(steak); cnt:AddItem(steak); stove:setActivated(true); ww._drawerItem = steak
    local n2, polls = 0, 0
    local function t2()
        n2 = n2 + 1
        if n2 % 60 == 0 then
            polls = polls + 1
            print("ZEDQA band cook poll" .. polls .. " ct=" .. tostring(steak:getCookingTime()) .. " " .. desc(M.getActiveAction(steak)))
            if polls == 2 then pcall(steak.setCookingTime, steak, (steak:getMinutesToCook() or 50) - 1) end
            if polls == 4 then pcall(steak.setCooked, steak, true) end
            if polls >= 6 then stove:setActivated(false); ww._drawerItem = nil; cnt:Remove(steak); inv:AddItem(steak); Events.OnTick.Remove(t2); print("ZEDQA band done (expect COOKING then BURNING danger)") end
        end
    end
    Events.OnTick.Add(t2)
end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, err = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(err)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick); print("ZEDQA band armed")
