-- ZeDUI/tools/qa/zedqa_wear_crate.lua  (Nov 14 2026, QA, punch list 189): logs only. A shirt in a crate beside the
-- character; the item card's EQUIP verb (the World window's Wear) through the card's real dispatch; the timed action
-- queue logged right after the press and whenever it changes, then where the shirt ends up. grep "ZEDQA wcr".
local function say(s) print("ZEDQA wcr " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local sq = getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), math.floor(p:getZ()))
if not sq then say("ERR no square"); say("DONE"); return end
local crate = IsoThumpable.new(getCell(), sq, "carpentry_01_16", false, nil)
crate:setIsContainer(true)
crate:getContainer():setType("crate")
sq:AddSpecialObject(crate)
local box = crate:getContainer()
local shirt = box:AddItem("Base.Tshirt_DefaultTEXTURE_TINT")
if not shirt then shirt = box:AddItem("Base.Shirt_FormalWhite") end
say("crate at " .. sq:getX() .. "," .. sq:getY() .. " shirt " .. tostring(shirt and shirt:getDisplayName()))
pcall(function() ISInventoryPage.dirtyUI() end)
local function qline()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local t = {}
    if q and q.queue then for _, a in ipairs(q.queue) do t[#t + 1] = tostring(a.Type) end end
    return #t == 0 and "(empty)" or table.concat(t, " > ")
end
local function where()
    local c = shirt:getContainer()
    local worn = "?"; pcall(function() worn = tostring(p:isEquipped(shirt)) end)
    return "in " .. tostring(c and c:getType()) .. ", worn " .. worn
end
local n, last, fired, quiet = 0, nil, false, 0
local function tick()
    n = n + 1
    if n == 60 then
        local c = ZeD_ItemCard:new(0, 0, 220, 300, "drawer", 0); c:initialise(); c.item = shirt; c.playerNum = 0; c.sourceContext = "loot"
        local ctx = "?"; pcall(function() ctx = c:_effectiveContext() end)
        say("card context " .. tostring(ctx) .. "; shirt " .. where())
        local ok, e = pcall(c._dispatchHeaderVerb, c, "EQUIP")
        say("EQUIP dispatched ok=" .. tostring(ok) .. " " .. tostring(e))
        fired = true
        last = qline(); say("queue right after: " .. last)
    elseif fired then
        local q = qline()
        if q ~= last then say("queue now: " .. q .. " | shirt " .. where()); last = q; quiet = 0 else quiet = quiet + 1 end
        if (q == "(empty)" and quiet > 180) or n > 3000 then
            say("end: shirt " .. where())
            pcall(function() if p:isEquipped(shirt) then p:removeWornItem(shirt) end; local c = shirt:getContainer(); if c then c:Remove(shirt) end end)
            pcall(function() sq:transmitRemoveItemFromSquare(crate) end)
            pcall(function() sq:RemoveTileObject(crate) end)
            Events.OnTick.Remove(tick)
            say("DONE")
        end
    end
end
Events.OnTick.Add(tick)
say("start")
