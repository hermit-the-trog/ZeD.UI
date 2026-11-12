-- ZeDUI/tools/qa/zedqa_animals_cleanup_far.lua  (Nov 11 2026, QA): takes away what zedqa_animals_quick_far.lua / _more.lua left 35 squares west of the QA home (a stadium stand: the
-- first far try) and the zones "QA Quick", "QA Quick2", "QA Pen RCT". Only animals within 12 squares of that spot. grep "ZEDQA acl".
local function say(s) print("ZEDQA acl " .. s) end
local p = getPlayer()
local hx, hy = p:getX(), p:getY()
p:setX(hx - 35); p:setY(hy); p:setLastX(hx - 35); p:setLastY(hy)
local n = 0
local function later()
    n = n + 1
    if n == 240 then
        local cell = getCell()
        local gone = 0
        local list = cell:getObjectList()
        local victims = {}
        for k = 0, list:size() - 1 do
            local o = list:get(k)
            if instanceof(o, "IsoAnimal") and (math.abs(o:getX() - (hx - 35)) < 14 or math.abs(o:getX() - (hx - 16)) < 6) and math.abs(o:getY() - hy) < 14 then victims[#victims + 1] = o end
        end
        for _, a in ipairs(victims) do pcall(function() a:removeFromWorld(); a:removeFromSquare(); gone = gone + 1 end) end
        for _, name in ipairs({ "QA Quick", "QA Quick2", "QA Pen RCT" }) do
            for _ = 1, 4 do pcall(function() local z = DesignationZoneAnimal.getZoneByName(name); if z then DesignationZoneAnimal.removeZone(z, true) end end) end
        end
        say("animals taken away: " .. gone .. " of " .. #victims)
        p:setX(hx); p:setY(hy); p:setLastX(hx); p:setLastY(hy)
    elseif n == 300 then
        Events.OnTick.Remove(later); say("DONE")
    end
end
Events.OnTick.Add(later)
say("start")
