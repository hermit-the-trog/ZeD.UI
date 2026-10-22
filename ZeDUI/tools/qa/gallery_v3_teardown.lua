-- ZeDUI/tools/qa/gallery_v3_teardown.lua  (Oct 21 2026)
-- Workshop gallery v3, last part: puts back everything gallery_v3_core.lua and
-- gallery_v3_stage.lua changed (from GAL.R / GAL.A): out of the car, menus shut,
-- zombies, ground things and cars removed, the kit off, the character's own clothes,
-- belt, hands and loose items back, weather, time, debug options, zoom and position.
-- ZeD-independent (the ZeD bits are guarded). Safe to run twice. "ZEDQA g3t ... DONE".
local G = GAL
if not (G and G.newSeq and G.R) then print("ZEDQA g3t nothing to put back (no GAL.R)"); print("ZEDQA g3t DONE"); return end
local S = G.newSeq("g3t", 180000)
local say = S.say
local p, inv, pn = G.p, G.inv, G.pn
local R, A = G.R, G.A

S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() local m = getPlayerRadialMenu(pn); if m then m:undisplay() end end)
    pcall(function() local m = getPlayerContextMenu(pn); if m then m:hideAndChildren() end end)
    local v = p:getVehicle()
    if v then
        pcall(function() v:exit(p) end)
        pcall(function() triggerEvent("OnExitVehicle", p) end)
    end
end)
S.step(30, function()
    for _, z in ipairs(A.near or {}) do G.removeZombie(z) end
    for _, z in ipairs(A.zombies or {}) do G.removeZombie(z) end
    local nz = #(A.zombies or {}) + #(A.near or {})
    A.near, A.zombies = {}, {}
    local nw = 0
    for _, it in ipairs(A.world or {}) do
        pcall(function()
            local wi = it:getWorldItem()
            if wi then
                local sq = wi:getSquare()
                if sq then sq:transmitRemoveItemFromSquare(wi) end
                wi:removeFromWorld()
                wi:removeFromSquare()
                nw = nw + 1
            end
        end)
    end
    A.world = {}
    local nc = 0
    for _, v in ipairs(A.cars or {}) do
        if pcall(function() v:permanentlyRemove() end) then nc = nc + 1 end
    end
    A.cars = {}
    G.car, G.trunk, G.trunkPart, G.duffel = nil, nil, nil, nil
    say(string.format("removed %d zombies, %d ground things, %d cars | zombies left in the cell %d", nz, nw, nc, getCell():getZombieList():size()))
end)
S.step(10, function()
    -- the kit off: hands, belt, worn, then every item now carried
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    local hb = getPlayerHotbar and getPlayerHotbar(pn)
    if hb then
        local now = {}
        for _, it in pairs(hb.attachedItems or {}) do now[#now + 1] = it end
        for _, it in ipairs(now) do pcall(function() hb:removeItem(it, false) end) end
    end
    local worn = {}
    pcall(function()
        local wi = p:getWornItems()
        for i = 0, wi:size() - 1 do worn[#worn + 1] = wi:get(i):getItem() end
    end)
    for _, it in ipairs(worn) do pcall(function() p:removeWornItem(it, false) end) end
    local items = {}
    local list = inv:getItems()
    for i = 0, list:size() - 1 do items[#items + 1] = list:get(i) end
    for _, it in ipairs(items) do pcall(function() inv:Remove(it) end) end
    A.worn, A.attached = {}, {}
    say("kit off: " .. #worn .. " worn, " .. #items .. " items removed")
end)
S.step(10, function()
    if not R.aside then say("nothing was put aside"); return end
    local n, w, h = 0, 0, 0
    for _, it in ipairs(R.items or {}) do if pcall(function() inv:AddItem(it) end) then n = n + 1 end end
    for _, x in ipairs(R.worn or {}) do
        if pcall(function() p:setWornItem(x.loc, x.it) end) then w = w + 1 end
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    pcall(function() p:setPrimaryHandItem(R.prim); p:setSecondaryHandItem(R.sec) end)
    R.aside = false
    say(string.format("back: %d items, %d worn, hands %s / %s", n, w, tostring(R.prim and R.prim:getFullType()), tostring(R.sec and R.sec:getFullType())))
end)
S.step(20, function()
    local hb = getPlayerHotbar and getPlayerHotbar(pn)
    local h = 0
    if hb then
        pcall(function() hb:refresh() end)
        for _, x in ipairs(R.hot or {}) do
            pcall(function()
                local slot = hb.availableSlot[x.i]
                if slot and not hb.attachedItems[x.i] then
                    hb:attachItem(x.it, slot.def.attachments[x.it:getAttachmentType()], x.i, slot.def, false)
                    if hb.attachedItems[x.i] == x.it then h = h + 1 end
                end
            end)
        end
    end
    say("belt back: " .. h .. "/" .. #(R.hot or {}))
    -- ZeD: the theme from the options, the watch popped in, the windows unrolled
    if ZeD then
        pcall(function() ZeD.Watch.togglePop(false) end)
        pcall(function()
            local w = ZeD_WorldWindow.getWindow()
            if w and w._rolled then ZeD.Curtain.unroll(w) end
        end)
        pcall(ZeD.Settings.reapplyFromOptions)
    end
end)
S.step(10, function()
    for _, c in ipairs(R.clim or {}) do pcall(function() c.v:setAdminValue(c.val); c.v:setEnableAdmin(c.en) end) end
    R.clim = {}
    pcall(function() G.gt:setTimeOfDay(R.tod) end)
    pcall(function()
        local o = getDebugOptions()
        if R.dbgVision ~= nil then o:setBoolean("FBORenderChunk.RenderVisionPolygon", R.dbgVision) end
        if R.dbgHigh ~= nil then o:setBoolean("Terrain.RenderTiles.RenderContainerHighlight", R.dbgHigh) end
        if R.dbgSee ~= nil then o:setBoolean("Cheat.Player.SeeEveryone", R.dbgSee) end
        if R.dbgArea ~= nil then o:setBoolean("Vehicle.Render.Area", R.dbgArea) end
    end)
    pcall(function() p:setZombiesDontAttack(R.dda) end)
    for _, e in ipairs(R.hidden or {}) do pcall(function() e:setVisible(true) end) end
    R.hidden = {}
    G.tp(R.x, R.y, R.z)
end)
S.waitMs(6000)
S.zoomTo(R.zoom or 1.0)
S.step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(R.speed > 0 and R.speed or 1) end
    say(string.format("back at %d,%d (was %d,%d) | carried %d | zombies in the cell %d", math.floor(p:getX()), math.floor(p:getY()),
        math.floor(R.x), math.floor(R.y), inv:getItems():size(), getCell():getZombieList():size()))
    GAL = nil
end)
S.start()
