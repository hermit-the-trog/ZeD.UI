-- ZeDUI/tools/qa/gallery_story_teardown.lua  (Oct 21 2026)
-- Story gallery, part 3 of 3: puts back everything gallery_story_stage.lua and
-- gallery_story_shots.lua changed (from STORY.R / STORY.A):
--   actions, menus, the reader, the seat chooser, a drag, the Vehicle tab card; out of the car;
--   the queue and the outside zombies removed, the native zombies' useless flag back;
--   the cars removed; the window's planks off; the blood the stage put down cleaned;
--   the store's lights that were switched on, off again; the pumps' fuel modData back;
--   the sandbox power option back; the kit off and the character's own clothes, belt,
--   hands and items back; profession, traits, the descriptor's XP boosts, every perk's
--   level, XP and boost, the stats; the flyer's read state, the journal entry, the map
--   note and star; ZeD's options (in memory and the ModOptions values), theme, window
--   accents and map style; time, weather, debug options, zoom and position.
-- Safe to run twice. "ZEDQA stt ..." ending "ZEDQA stt DONE".
local ST = STORY
if not (ST and ST.newSeq and ST.R) then print("ZEDQA stt nothing to put back (no STORY.R)"); print("ZEDQA stt DONE"); return end
local S = ST.newSeq("stt", 240000)
local say = S.say
local p, inv, pn = ST.p, ST.inv, ST.pn
local R, A = ST.R, ST.A

S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    ST.clearActions()
    pcall(function() local m = getPlayerContextMenu(pn); if m then if m._zedMenu then m._zedMenu:close() end; m:hideAndChildren() end end)
    pcall(function() local r = ZeD.Reader.get(pn); if r and r:isVisible() then r:close() end end)
    pcall(function() ZeD.Seats.qaPoint = nil; local w = ZeD.Seats.get(pn); if w and w:isVisible() then w:close() end end)
    pcall(function()
        local c = ZeD_CharacterWindow.getWindow()._mainContent
        if c._drag:isActive() then c._drag:cancel(); c:setCapture(false) end
    end)
    pcall(function()
        local w = ZeD_WorldWindow.getWindow()
        local s = ZeD.MechanicsTab.getState(w)
        s.view, s.card, s.verb = "overview", nil, nil
        local mp = w._worldMapPanel
        if mp then mp.isMouseOver, mp.getMouseX, mp.getMouseY = nil, nil, nil end
    end)
    pcall(function() local L = ZeD.Moodles.getLayer(pn); L.getMouseX, L.getMouseY = nil, nil end)
    pcall(function() ZeD.Watch.togglePop(false) end)
    local v = p:getVehicle()
    if v then
        pcall(function() v:exit(p) end)
        pcall(function() triggerEvent("OnExitVehicle", p) end)
    end
end)
S.step(30, function()
    local nz = 0
    for _, z in ipairs(A.queue or {}) do ST.removeZombie(z); nz = nz + 1 end
    for _, z in ipairs(A.zombies or {}) do ST.removeZombie(z); nz = nz + 1 end
    A.queue, A.zombies = {}, {}
    local nn = 0
    for _, e in ipairs(A.native or {}) do if pcall(function() e.z:setUseless(e.was) end) then nn = nn + 1 end end
    A.native = {}
    local nc = 0
    for _, v in ipairs(A.cars or {}) do if pcall(function() v:permanentlyRemove() end) then nc = nc + 1 end end
    A.cars = {}
    ST.car = nil
    local nw = 0
    for _, it in ipairs(A.world or {}) do
        pcall(function()
            local wi = it:getWorldItem()
            if wi then wi:getSquare():transmitRemoveItemFromSquare(wi); wi:removeFromWorld(); wi:removeFromSquare(); nw = nw + 1 end
        end)
    end
    A.world = {}
    say(string.format("removed %d zombies, %d cars, %d ground things; %d native zombies' flag back", nz, nc, nw, nn))
end)
S.step(5, function()
    -- the window's planks (the store had none on it: the stage only picks bare windows)
    local np = 0
    local w = ST.P and ST.P.win and ST.P.win.o
    if w then
        for _ = 1, 8 do
            local b = nil
            pcall(function() b = w:getBarricadeOnSameSquare() or w:getBarricadeOnOppositeSquare() end)
            if not b then break end
            local n = 0
            pcall(function() n = b:getNumPlanks() end)
            if n > 0 then
                pcall(function() b:removePlank(p) end)
                np = np + 1
            else
                pcall(function() b:getSquare():transmitRemoveItemFromSquare(b) end)
                pcall(function() b:removeFromWorld(); b:removeFromSquare() end)
            end
        end
    end
    -- the blood the stage put down
    local nb = 0
    for _, sq in ipairs(A.blood or {}) do if pcall(function() sq:removeBlood(false, false); sq:removeGrime() end) then nb = nb + 1 end end
    A.blood = {}
    local nl = ST.lights(false)
    local nf = 0
    for _, e in ipairs(A.pumps or {}) do
        if pcall(function() e.o:getModData().fuelAmount = e.raw; e.o:transmitModData() end) then nf = nf + 1 end
    end
    A.pumps = {}
    for name, val in pairs(R.sandbox or {}) do
        pcall(function() getSandboxOptions():getOptionByName(name):setValue(val) end)
    end
    pcall(function() getSandboxOptions():toLua() end)
    R.sandbox = {}
    say(string.format("planks off %d | blood cleaned on %d | lights off %d | pumps back %d | sandbox back", np, nb, nl, nf))
end)
S.step(10, function()
    -- the kit off: hands, belt, worn, every item carried
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
    A.worn = {}
    say("kit off: " .. #worn .. " worn, " .. #items .. " items removed")
end)
S.step(10, function()
    if not R.aside then say("nothing was put aside"); return end
    local n, w = 0, 0
    for _, it in ipairs(R.items or {}) do if pcall(function() inv:AddItem(it) end) then n = n + 1 end end
    for _, x in ipairs(R.worn or {}) do if pcall(function() p:setWornItem(x.loc, x.it) end) then w = w + 1 end end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    pcall(function() p:setPrimaryHandItem(R.prim); p:setSecondaryHandItem(R.sec) end)
    R.aside = false
    say(string.format("back: %d items, %d worn", n, w))
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
end)
S.step(5, function()
    -- profession, traits, boosts, perks, stats
    if R.prof == nil and not R.traits then say("the character was not changed"); return end
    local desc = p:getDescriptor()
    pcall(function() desc:setCharacterProfession(R.prof) end)
    pcall(function()
        local m = desc:getXPBoostMap()
        m:clear()
        for _, e in ipairs(R.descBoost or {}) do m:put(e[1], e[2]) end
    end)
    local ct = p:getCharacterTraits()
    pcall(function()
        local defs = CharacterTraitDefinition.getTraits()
        for i = 0, defs:size() - 1 do ct:set(defs:get(i):getType(), false) end
    end)
    local nt = 0
    for _, t in ipairs(R.traits or {}) do if pcall(function() ct:set(t[1], t[2] == true) end) then nt = nt + 1 end end
    local xp = p:getXp()
    local np = 0
    for _, s in ipairs(R.perks or {}) do
        local ok = pcall(function()
            p:setPerkLevelDebug(s.perk, s.lvl)
            xp:setXPToLevel(s.perk, s.lvl)
            local now = xp:getXP(s.perk)
            if s.xp > now then xp:AddXPNoMultiplier(s.perk, s.xp - now) end
            xp:setPerkBoost(s.perk, s.boost)
        end)
        if ok then np = np + 1 end
    end
    for _, e in ipairs(R.stats or {}) do pcall(function() p:getStats():set(e[1], e[2]) end) end
    if R.lastSmoke then pcall(function() p:setTimeSinceLastSmoke(R.lastSmoke) end) end
    pcall(function() SyncXp(p) end)
    R.traits, R.perks = nil, nil
    say(string.format("character back: profession %s | %d traits | %d perks", tostring(desc:getCharacterProfession()), nt, np))
end)
S.step(5, function()
    -- the seeds: flyer read state, journal entry, map note and star
    pcall(function()
        local id = string.lower(ST.site.flyer)
        if R.flyerWasRead == false then p:getReadPrintMedia():remove(id) end
    end)
    local nj = 0
    pcall(function()
        local e = p:getModData().ZeD_Journal.entries
        for i = #e, 1, -1 do if e[i].text == ST.JOURNAL then table.remove(e, i); nj = nj + 1 end end
        ZeD_CharacterWindow.getWindow()._journalCache = nil
    end)
    local nm = 0
    pcall(function() if R.note and ZeD.MapNotes.remove(R.note) then nm = nm + 1 end end)
    pcall(function() if R.star and ZeD.MapNotes.remove(R.star) then nm = nm + 1 end end)
    pcall(function()
        local s = ZeD.MapNotes.findByText(ST.NOTE)
        if s and ZeD.MapNotes.remove(s) then nm = nm + 1 end
    end)
    R.note, R.star = nil, nil
    say(string.format("seeds back: flyer read %s | journal entries removed %d | map marks removed %d",
        tostring(p:isPrintMediaRead(string.lower(ST.site.flyer))), nj, nm))
end)
S.step(5, function()
    -- ZeD: the option values, theme, window accents, map style
    if not (ZeD and R.zed) then return end
    pcall(function()
        local d = PZAPI.ModOptions:getOptions("ZeD_UI").dict
        for id, val in pairs(R.zed.opts) do if d[id] then d[id]:setValue(val) end end
    end)
    pcall(ZeD.Settings.reapplyFromOptions)
    pcall(function() ZeD_CharacterWindow.getWindow()._accentKey = R.zed.cAcc end)
    pcall(function() ZeD_WorldWindow.getWindow()._accentKey = R.zed.wAcc end)
    pcall(function()
        local w = ZeD_WorldWindow.getWindow()
        if R.zed.mapStyle then ZeD.MapsTab.setStyle(w, R.zed.mapStyle) end
        p:getModData().ZeD_MapStyle = R.zed.mapStyle
    end)
    pcall(function()
        local w = ZeD_WorldWindow.getWindow()
        if w and w._rolled then ZeD.Curtain.unroll(w) end
    end)
    say("ZeD back: " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize)
        .. " (was " .. tostring(R.zed.base) .. " " .. tostring(R.zed.accent) .. " " .. tostring(R.zed.size) .. ")")
end)
S.step(10, function()
    for _, c in ipairs(R.clim or {}) do pcall(function() c.v:setAdminValue(c.val); c.v:setEnableAdmin(c.en) end) end
    R.clim = {}
    pcall(function() ST.gt:setTimeOfDay(R.tod) end)
    pcall(function()
        local o = getDebugOptions()
        if R.dbgVision ~= nil then o:setBoolean("FBORenderChunk.RenderVisionPolygon", R.dbgVision) end
        if R.dbgHigh ~= nil then o:setBoolean("Terrain.RenderTiles.RenderContainerHighlight", R.dbgHigh) end
        if R.dbgSee ~= nil then o:setBoolean("Cheat.Player.SeeEveryone", R.dbgSee) end
        if R.dbgArea ~= nil then o:setBoolean("Vehicle.Render.Area", R.dbgArea) end
    end)
    pcall(function() p:setZombiesDontAttack(R.dda) end)
    pcall(function() p:setGodMod(R.god) end)
    for _, e in ipairs(R.hidden or {}) do pcall(function() e:setVisible(true) end) end
    R.hidden = {}
    ST.tp(R.x, R.y, R.z)
end)
S.waitMs(6000)
S.zoomTo(R.zoom or 1.0)
S.step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(R.speed > 0 and R.speed or 1) end
    say(string.format("back at %d,%d (was %d,%d) | carried %d | zombies in the cell %d", math.floor(p:getX()), math.floor(p:getY()),
        math.floor(R.x), math.floor(R.y), inv:getItems():size(), getCell():getZombieList():size()))
    STORY = nil
end)
S.start()
