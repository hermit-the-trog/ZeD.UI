-- ZeDUI/tools/qa/zedqa_furniture.lua  (S124)
-- Furniture tab + placement card check for the QA save. Copy to
-- Zomboid/Lua/zedqa.lua and bump zedqa.go; grep console.txt for "ZEDQA fu".
-- Opens the Furniture tab, checks the cursor starts, walks the five modes,
-- reads the capture for a square with furniture (the cursor's isValid is
-- called directly, as the mouse would), picks a list row and a facing, then
-- leaves the tab and checks the cursor ends.

local p = getPlayer()
local FT = ZeD.FurnitureTab
local function say(s) print("ZEDQA fu " .. tostring(s)) end
local function W() return ZeD_WorldWindow.getWindow() end

-- nearest square within 8 tiles holding something the pickup cursor lists
local function furnitureSquare(cur)
    local cell = getCell()
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for r = 1, 8 do
        for y = py - r, py + r do
            for x = px - r, px + r do
                local sq = cell:getGridSquare(x, y, pz)
                if sq then
                    cur.currentSquare = nil
                    local ok, list = pcall(function() cur.currentSquare = sq; return cur:getObjectList() end)
                    if ok and list and #list > 0 then return sq end
                end
            end
        end
    end
end

local n = 0
local sq
local function tick()
    n = n + 1
    if n == 1 then
        ZeD_WorldWindow.openTab(0, "furniture")
    elseif n == 30 then
        local cur = FT.cursorOf(0)
        say("tab=" .. tostring(ZeD_WorldWindow.isTabShowing("furniture")) .. " cursor=" .. tostring(cur ~= nil) .. " mode=" .. tostring(FT.state.mode))
        if cur then sq = furnitureSquare(cur) end
        say("furniture square=" .. tostring(sq and (sq:getX() .. "," .. sq:getY())))
    elseif n == 40 and sq then
        local cur = FT.cursorOf(0)
        cur:isValid(sq)
        local c = FT.cap[0]
        local info = c and c.mp and FT.readLines(c)
        say("pickup capture name=" .. tostring(info and info.name) .. " can=" .. tostring(c and c.canCreate) .. " facts=" .. tostring(info and #info.facts) .. " notes=" .. tostring(info and #info.notes))
        if info then for _, f in ipairs(info.facts) do say("  fact " .. f.label .. " = " .. f.value .. " [" .. f.state .. "]") end end
        if info then for _, x in ipairs(info.notes) do say("  note " .. x.text .. " [" .. x.state .. "]") end end
    elseif n == 50 then
        for _, m in ipairs({ "place", "rotate", "scrap", "repair", "pickup" }) do
            FT.setMode(0, m)
            local cur = FT.cursorOf(0)
            if sq and cur then cur:isValid(sq) end
            local c = FT.cap[0]
            say("mode " .. m .. " -> cursor mode=" .. tostring(ISMoveableCursor.mode[0]) .. " target=" .. tostring(c and c.mp ~= nil) .. " can=" .. tostring(c and c.canCreate))
        end
    elseif n == 70 then
        local s = W()._fur
        local ids = {}
        for _, z in ipairs(s and s.zones or {}) do ids[#ids + 1] = z.id end
        say("zones " .. table.concat(ids, ","))
    elseif n == 80 then
        ZeD_WorldWindow.openTab(0, "loot")
    elseif n == 110 then
        say("after leaving tab=" .. tostring(ZeD_WorldWindow.isTabShowing("furniture")) .. " cursor=" .. tostring(FT.cursorOf(0) ~= nil) .. " active=" .. tostring(FT.state.active))
        Events.OnTick.Remove(tick)
    end
end
Events.OnTick.Add(tick)
