-- ZeDUI/tools/qa/zedqa_restock_probe.lua  (Oct 29 2026)
-- In game on the ZeD-QA save: a look round before zedqa_restock.lua. Says whether the
-- restock modules loaded, opens the Equip tab (the loadouts' bar draws), and lists the
-- buildings near the character with their containers and taps (nearest first).
-- Changes nothing it does not put back. grep "ZEDQA rp".
local p = getPlayer()
local function say(s) print("ZEDQA rp " .. tostring(s)) end
local n = 0
local function tick()
    n = n + 1
    if n == 2 then
        say("modules: Restock " .. tostring(ZeD.Restock ~= nil) .. " EquipLoadout " .. tostring(ZeD.EquipLoadout ~= nil)
            .. " Pin " .. tostring(ZeD.RestockPin ~= nil) .. " setting " .. tostring(ZeD.Settings.restockOption ~= nil)
            .. " mode " .. tostring(ZeD.Restock and ZeD.Restock.mode()))
        local w = ZeD_CharacterWindow.getWindow()
        if not (w and w:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    elseif n == 20 then
        local w = ZeD_CharacterWindow.getWindow()
        local strip = w._tabStripPanel
        for _, z in ipairs(strip._hitZones or {}) do
            if z.id == "tab:equip" then strip:onMouseDown(z.x + 2, z.y + 2) end
        end
    elseif n == 80 then
        local w = ZeD_CharacterWindow.getWindow()
        local ids = {}
        for _, z in ipairs(w._elZones or {}) do ids[#ids + 1] = z.id end
        say("equip tab " .. tostring(w._activeTab) .. " bar zones: " .. table.concat(ids, ","))
        local ok, plan = pcall(ZeD.Restock.plan, p, {})
        say("plan ok " .. tostring(ok) .. " " .. (ok and ("rows " .. #plan.rows .. " secs " .. tostring(plan.secs)) or tostring(plan)))
    elseif n == 90 then
        local cx, cy = math.floor(p:getX()), math.floor(p:getY())
        local cell = getCell()
        local bs, order = {}, {}
        for y = cy - 90, cy + 90 do
            for x = cx - 90, cx + 90 do
                local sq = cell:getGridSquare(x, y, 0)
                local b = sq and sq:getBuilding()
                if b then
                    local d = b:getDef()
                    local k = d:getX() .. "," .. d:getY()
                    local e = bs[k]
                    if not e then
                        e = { k = k, sq = 0, conts = 0, explored = 0, waters = 0, dist = 1e9, x = x, y = y, lv = d:getMaxLevel(), rooms = {} }
                        bs[k] = e
                        order[#order + 1] = e
                    end
                    e.sq = e.sq + 1
                    local dd = math.abs(x - cx) + math.abs(y - cy)
                    if dd < e.dist then e.dist, e.x, e.y = dd, x, y end
                    local r = sq:getRoom()
                    if r then e.rooms[tostring(r:getName())] = true end
                    local obs = sq:getObjects()
                    for i = 0, obs:size() - 1 do
                        local o = obs:get(i)
                        if o:getContainerCount() > 0 then
                            e.conts = e.conts + 1
                            if o:getContainer():isExplored() then e.explored = e.explored + 1 end
                        end
                        if o:hasWater() and o:getFluidAmount() > 0 then e.waters = e.waters + 1 end
                    end
                end
            end
        end
        table.sort(order, function(a, b) return a.dist < b.dist end)
        say("buildings within 90: " .. #order)
        for i = 1, math.min(15, #order) do
            local e = order[i]
            local rn = {}
            for r in pairs(e.rooms) do rn[#rn + 1] = r end
            say(string.format("  %s dist %d squares %d containers %d (explored %d) taps %d near %d,%d lv %d rooms %s",
                e.k, e.dist, e.sq, e.conts, e.explored, e.waters, e.x, e.y, e.lv, table.concat(rn, "/")))
        end
        say("DONE")
        Events.OnTick.Remove(tick)
    end
end
Events.OnTick.Add(tick)
say("start at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()))
