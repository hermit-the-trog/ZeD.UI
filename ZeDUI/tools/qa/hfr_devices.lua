-- ZeDUI/tools/qa/hfr_devices.lua  (Nov 20 2026, QA; tag hfd): the beta 21 hotfix report, CUTS D: devices and cards
-- (git 107b914a8). Pictures to Screenshots/hfr_D_*.png. Manifest hotfix_devices.txt. Every section guards itself: one that
-- cannot be staged logs "not taken" and the next goes on. What it puts back: the things given, the placed stoves and radios
-- and the car taken away, the watch's alarm as found, Style as found (picked through ZeD setup), the windows as found.
-- grep "ZEDQA hfd".
local S = HFR and HFR.init and HFR.init("hfd")
if not S then return end
local Q = S.Q
S.placed = {}
S.ST = ZeD.Stations

function S.place(kind, spr, sq)
    local obj = nil
    pcall(function()
        if kind == "stove" then obj = IsoStove.new(getCell(), sq, getSprite(spr)) else obj = IsoRadio.new(getCell(), sq, getSprite(spr)) end
        pcall(function() obj:createContainersFromSpriteProperties() end)
        if kind == "stove" then sq:AddSpecialObject(obj) else sq:AddTileObject(obj) end
        if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
    end)
    if obj then S.placed[#S.placed + 1] = { obj = obj, sq = sq } end
    return obj
end
function S.unplace(obj)
    for i, e in ipairs(S.placed) do
        if e.obj == obj then pcall(function() e.sq:transmitRemoveItemFromSquare(obj) end); table.remove(S.placed, i); return end
    end
end
function S.unplaceAll()
    if S.removeBuilt then S.removeBuilt() end
    for _, e in ipairs(S.placed) do pcall(function() e.sq:transmitRemoveItemFromSquare(e.obj) end) end
    S.placed = {}
end
-- an appliance bound on the Craft tab, a picture, unbound and removed
function S.station(name, spr, offs)
    Q.step(10, function()
        S.obj = nil
        local sq = S.freeSq(offs)
        if sq then S.obj = S.place("stove", spr, sq) end
        Q.say(name .. " placed " .. tostring(S.obj ~= nil))
    end)
    Q.step(30, function()
        S.open = S.obj ~= nil and S.ST.open(S.p, S.obj) or false
        Q.say(name .. " on the Craft tab " .. tostring(S.open))
    end)
    Q.step(60, function() S.clearChar() end)
    Q.still(10, function()
        if S.open then S.shot(name) else Q.notTaken(name, "the appliance did not open") end
    end)
    Q.step(10, function()
        pcall(function() S.ST.unbind(S.p) end)
        if S.obj then S.unplace(S.obj) end
        S.obj = nil
        S.worldTab("loot")
    end)
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    S.was.style = ZeD.Settings.lookStyleOption:getValue()
    G1.tp(S.P.stock, "SE")
    S.openPair()
end)
Q.zoomTo(1.0)

-- D: microwave (plain card, "Power level [Med]", no band), oven (no band), a bench away ("N tiles away")
S.station("D_microwave_card", "appliances_cooking_01_24")
S.station("D_oven_view", "appliances_cooking_01_0")
-- a craft bench (a Primitive Kiln, built with the game's build code and the build cheat, as rt_cards.lua) several tiles away,
-- bound on the Craft tab: its band reads "N tiles away" (QA, Nov 20: the first pass showed the microwave, which has no band)
S.built = {}
function S.findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
    return nil
end
function S.snapshot(cx, cy, r)
    local set = {}
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            local sq = getCell():getGridSquare(x, y, math.floor(S.p:getZ()))
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do set[objs:get(i)] = true end
            end
        end
    end
    return set
end
function S.buildAway(full, offs)
    local info = S.findInfo(full)
    if not info then return nil, "no entity info for " .. full end
    local px, py, pz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for _, o in ipairs(offs) do
        local x, y = px + o[1], py + o[2]
        local before = S.snapshot(x, y, 2)
        S.p:setBuildCheat(true)
        local okB = pcall(function()
            local b = ISBuildIsoEntity:new(S.p, info, 1, ISInventoryPaneContextMenu.getContainers(S.p))
            b.buildCheat = true
            b.player = S.pn
            local sq = getCell():getGridSquare(x, y, pz)
            b.sq = sq
            if b:isValid(sq) then b:create(x, y, pz, false, nil) end
        end)
        S.p:setBuildCheat(false)
        if okB then
            local new = {}
            for obj in pairs(S.snapshot(x, y, 2)) do if not before[obj] then new[#new + 1] = obj; S.built[#S.built + 1] = obj end end
            if #new > 0 then return new end
        end
    end
    return nil, "no room to build " .. full
end
function S.removeBuilt()
    for _, obj in ipairs(S.built) do
        local sq = nil
        pcall(function() sq = obj:getSquare() end)
        if sq then
            pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
            pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
        end
    end
    S.built = {}
end
Q.step(10, function()
    S.kiln = nil
    local objs, why = S.buildAway("Base.Kiln_Small", { { 4, -3 }, { -4, -3 }, { 4, 3 }, { -4, 3 }, { 5, 0 }, { -5, 0 }, { 0, -5 }, { 0, 5 } })
    for _, o in ipairs(objs or {}) do
        local m = S.ST.call(o, "getMasterObject") or o
        if not S.kiln and S.ST.classify(m, true) == "bench" then S.kiln = m end
    end
    Q.say("kiln built away " .. tostring(S.kiln ~= nil) .. " " .. tostring(why))
end)
Q.step(20, function()
    if not S.kiln then return end
    local ok, err = pcall(ISEntityUI.OpenWindow, S.p, S.kiln)
    if not ok then Q.say("NOTE ISEntityUI.OpenWindow: " .. tostring(err)) end
end)
Q.waitFor(5, 600, function()
    if not S.kiln then return true end
    local st = S.ST.current(S.p)
    local w = S.WW()
    return st ~= nil and st.obj == S.kiln and w ~= nil and w._activeTab == "craft"
end, function(ok) Q.say("kiln bound on the Craft tab " .. tostring(ok)) end)
Q.step(10, function()
    -- the game's own station window beside ours is shut
    pcall(function()
        local pl = ISEntityUI.players and ISEntityUI.players[S.pn]
        for _, w in pairs((pl and pl.windows) or {}) do
            local inst = w and w.instance
            if inst then pcall(function() if inst.close then inst:close() else inst:removeFromUIManager() end end) end
        end
    end)
end)
Q.step(60, function() S.clearChar() end)
Q.still(10, function()
    local st = S.ST.current(S.p)
    Q.say("station " .. tostring(st and st.name) .. " dist " .. tostring(st and st.dist))
    if S.kiln and st and st.obj == S.kiln then S.shot("D_station_tiles_away") else Q.notTaken("D_station_tiles_away", "the bench did not bind") end
end)
Q.step(10, function()
    pcall(function() S.ST.unbind(S.p) end)
    S.removeBuilt()
    S.worldTab("loot")
end)

-- D: a free-standing radio in hand: plain, off and on (Lite is the plain face)
S.pickStyle(2)
Q.step(10, function()
    S.radio = S.add("Base.RadioRed")
    pcall(function() S.p:setPrimaryHandItem(S.radio) end)
    pcall(function() local d = S.radio:getDeviceData(); d:setIsTurnedOn(false); d:setHasBattery(true); d:setPower(0.8) end)
    S.openPair()
end)
Q.waitFor(10, 300, function()
    local w = S.CW()
    local r = w and w._radios and w._radios[1]
    return r ~= nil and r.radioInstance == S.radio
end, function(ok) Q.say("radio in hand, Radio tab " .. tostring(ok and S.charTab("radio"))) end)
Q.step(40, function() S.clearChar() end)
Q.still(10, function()
    local w = S.CW()
    if w and w._activeTab == "radio" then S.shot("D_radio_plain_off") else Q.notTaken("D_radio_plain_off", "the Radio tab did not open") end
end)
Q.step(10, function() pcall(function() S.radio:getDeviceData():setIsTurnedOn(true) end) end)
Q.step(40, function() end)
Q.still(10, function()
    local w = S.CW()
    if w and w._activeTab == "radio" then S.shot("D_radio_plain_on") else Q.notTaken("D_radio_plain_on", "the Radio tab did not open") end
end)
Q.step(5, function()
    pcall(function() S.radio:getDeviceData():setIsTurnedOn(false) end)
    pcall(function() S.p:setPrimaryHandItem(nil) end)
    S.charTab("loot")
end)
-- D: the Lite clock, alarm off then set
Q.step(10, function()
    S.closePair()
    S.watch = nil
    pcall(function()
        local worn = S.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local it = worn:getItemByIndex(i)
            if it and instanceof(it, "AlarmClockClothing") then S.watch = it end
        end
        if not S.watch then
            local its = S.p:getInventory():getItems()
            for i = 0, its:size() - 1 do if instanceof(its:get(i), "AlarmClockClothing") or instanceof(its:get(i), "AlarmClock") then S.watch = its:get(i) end end
        end
    end)
    if S.watch then
        pcall(function() S.was.alarm = { S.watch:isAlarmSet(), S.watch:getHour(), S.watch:getMinute() } end)
        pcall(function() S.watch:setAlarmSet(false) end)
    end
    Q.say("watch item " .. tostring(S.watch ~= nil and S.watch:getType()))
end)
Q.still(20, function()
    local W = ZeD.Watch and ZeD.Watch._instance
    local vis = false
    pcall(function() vis = W ~= nil and W:isReallyVisible() end)
    if vis then S.shot("D_clock_lite_alarm_off") else Q.notTaken("D_clock_lite_alarm_off", "no clock on screen (watch " .. tostring(S.watch ~= nil) .. ")") end
end)
Q.step(10, function() if S.watch then pcall(function() S.watch:setHour(7); S.watch:setMinute(30); S.watch:setAlarmSet(true) end) end end)
Q.still(20, function()
    local W = ZeD.Watch and ZeD.Watch._instance
    local vis = false
    pcall(function() vis = W ~= nil and W:isReallyVisible() end)
    if vis and S.watch then S.shot("D_clock_lite_alarm_set") else Q.notTaken("D_clock_lite_alarm_set", "no clock on screen (watch " .. tostring(S.watch ~= nil) .. ")") end
end)
Q.step(5, function()
    if S.watch and S.was.alarm then pcall(function() S.watch:setHour(S.was.alarm[2]); S.watch:setMinute(S.was.alarm[3]); S.watch:setAlarmSet(S.was.alarm[1]) end) end
end)
S.pickStyle(S.was and 1 or 1)

-- D: two ham radios on the World window's Radio tab
S.HAMS = { { ft = "Base.HamRadio1", spr = "appliances_com_01_0" }, { ft = "Base.HamRadio2", spr = "appliances_com_01_8" } }
Q.step(10, function()
    S.openPair()
    local x0, y0, z0 = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    local here = S.p:getCurrentSquare()
    local spots = {}
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x0 + d[1], y0 + d[2], z0)
        if sq and sq:isFree(false) and here and here:canReachTo(sq) then spots[#spots + 1] = sq end
    end
    S.hams = {}
    for i, h in ipairs(S.HAMS) do
        local sq = spots[i]
        local it = instanceItem(h.ft)
        if sq and it then
            local d = it:getDeviceData()
            d:setHasBattery(true); d:setPower(0.8); d:setIsTurnedOn(false); d:setMicIsMuted(true)
            local obj = nil
            pcall(function()
                obj = IsoRadio.new(getCell(), sq, getSprite(h.spr))
                obj:setDeviceData(d)
                sq:AddTileObject(obj)
            end)
            if obj then S.placed[#S.placed + 1] = { obj = obj, sq = sq }; S.hams[#S.hams + 1] = obj end
        end
    end
    Q.say("ham sets placed " .. #S.hams)
end)
Q.waitFor(5, 300, function()
    local n = 0
    for _, r in ipairs(S.WW() and S.WW()._radios or {}) do for _, o in ipairs(S.hams or {}) do if r.radioInstance == o then n = n + 1 end end end
    return n >= 2
end, function(ok) Q.say("both hams listed " .. tostring(ok) .. "; Radio tab " .. tostring(S.worldTab("radio"))) end)
Q.step(40, function() S.clearChar() end)
Q.still(15, function()
    local w = S.WW()
    if #(S.hams or {}) >= 2 and w and w._activeTab == "radio" then S.shot("D_radio_tab_two_hams") else Q.notTaken("D_radio_tab_two_hams", "hams " .. #(S.hams or {}) .. ", tab " .. tostring(w and w._activeTab)) end
end)
Q.step(10, function() S.worldTab("loot"); for _, o in ipairs(S.hams or {}) do S.unplace(o) end; S.hams = {} end)

-- D: Cooking tab, empty and filled
S.CK = ZeD.CookingTab
function S.cook() local w = S.CW(); return w and w._cook end
function S.czone(id) local s = S.cook(); return s and s.byId and s.byId[id] end
function S.press(id)
    local z, w = S.czone(id), S.CW()
    if not (z and w and S.CK) then Q.say("(no zone " .. id .. ")"); return false end
    S.CK.onClick(w, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    return true
end
function S.cookDrawn() local w, s = S.CW(), S.cook(); return w and w._activeTab == "cooking" and s and #(s.zones or {}) > 0 end
Q.step(10, function()
    S.closePair()
    G1.tp(S.P.clerk, "SE")
    S.p:getModData().ZeD_CookDishes = {}
    S.pot = S.add("Base.Pot")
    pcall(function() local fc = S.pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end)
    S.add("Base.Carrots"); S.add("Base.Potato"); S.add("Base.Cabbage")
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not S.CWm.isOpen() then S.CWm.toggle(S.pn) end
    if S.WWm.isOpen() then S.WWm.close(S.pn) end
end)
Q.step(70, function() local s = S.cook(); if s then s.scanAt = -1; s.visAt = nil; s.ingCache = nil end end)
Q.waitFor(10, 600, function() return S.charTab("cooking") end, function(ok) if not ok then Q.say("note: no Cooking tab in the strip") end end)
Q.waitFor(10, 600, function() return S.cookDrawn() end, function() end)
Q.step(30, function() S.clearChar() end)
Q.still(10, function()
    if S.cookDrawn() then S.shot("D_cooking_empty") else Q.notTaken("D_cooking_empty", "the Cooking tab is not drawn") end
end)
Q.step(20, function() S.press("cook:dish") end)
Q.step(20, function()
    local s = S.cook()
    local label = (getTextOrNull and getTextOrNull("ContextMenu_EvolvedRecipe_Stew")) or "Stew"
    S.dishKey = nil
    for _, m in ipairs((s and s.dishGeo and s.dishGeo.modes) or {}) do
        if not S.dishKey and m.label == label and tostring(m.id):sub(1, 5) == "dish:" then S.dishKey = tostring(m.id):sub(6) end
    end
    if not (S.dishKey and S.press("cook:pop:dish:" .. S.dishKey)) then Q.say("(no " .. label .. " in the Dish list)"); if s then s.popup = nil end end
end)
Q.step(20, function() S.press("cook:ing:Base.Carrots") end)
Q.step(20, function() S.press("cook:ing:Base.Potato") end)
Q.step(20, function() S.press("cook:ing:Base.Cabbage") end)
Q.step(20, function() S.clearChar() end)
Q.still(10, function()
    local s = S.cook()
    if s and #(s.plan or {}) >= 1 then S.shot("D_cooking_filled") else Q.notTaken("D_cooking_filled", "nothing planned") end
end)
Q.step(10, function() local s = S.cook(); if s then s.popup = nil; s.plan = {} end; S.charTab("loot"); S.takeMade() end)

-- D: the reader on a newspaper and a notebook
Q.step(10, function()
    S.closePair()
    G1.tp(S.P.smoke, "SE")
    S.was.cheat = nil
    pcall(function() S.was.cheat = S.p:isTimedActionInstantCheat() end)
    pcall(function() S.p:setTimedActionInstantCheat(true) end)
    pcall(function() STORY.day(11.0) end)
    local function media(id) return { id = string.lower(id), title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" } end
    S.news = S.add("Base.Newspaper")
    if S.news then
        S.news:getModData().printMedia = media("KnoxKnews_July1"); S.news:setName(getText("Print_Media_KnoxKnews_July1_title"))
        pcall(function() ISTimedActionQueue.add(ISReadABook:new(S.p, S.news)) end)
    end
end)
Q.waitFor(10, 400, function() return ZeD.Reader.get(S.pn) ~= nil and ZeD.Reader.get(S.pn):isVisible() end, function(ok) Q.say("newspaper reader up " .. tostring(ok)) end)
Q.step(40, function() local w = ZeD.Reader.get(S.pn); if w then G1.clear(Q, w, "left", "the reader") end end)
Q.still(10, function()
    local w = ZeD.Reader.get(S.pn)
    if w and w:isVisible() then S.shot("D_reader_newspaper") else Q.notTaken("D_reader_newspaper", "no reader") end
end)
Q.step(10, function() local w = ZeD.Reader.get(S.pn); if w then pcall(function() w:close() end) end end)
Q.step(20, function()
    S.nb = S.add("Base.Notebook")
    -- (QA, Nov 20: openNotebook hands the window to the write action, which adds it to the screen; no action here, so it is added by hand)
    pcall(function() local nw = ZeD.Reader.openNotebook(S.p, S.nb, nil, true); if nw then nw:addToUIManager() end end)
end)
Q.waitFor(10, 300, function() local r = ZeD.Reader.get(S.pn); return r ~= nil and r:isVisible() and r.mode == "notebook" end, function(ok) Q.say("notebook reader up " .. tostring(ok)) end)
Q.step(40, function() local w = ZeD.Reader.get(S.pn); if w then G1.clear(Q, w, "left", "the reader") end end)
Q.still(10, function()
    local w = ZeD.Reader.get(S.pn)
    if w and w:isVisible() then S.shot("D_reader_notebook") else Q.notTaken("D_reader_notebook", "no reader") end
end)
Q.step(10, function()
    local w = ZeD.Reader.get(S.pn); if w then pcall(function() w:close() end) end
    pcall(function() S.p:setTimedActionInstantCheat(S.was.cheat == true) end)
    S.takeMade()
end)

-- D: the action bar reading a long title
Q.step(10, function()
    S.closePair()
    S.food = S.add("Base.Apple")
    if S.food then pcall(function() S.food:setName("Extremely Long Named Fresh Apple") end) end
    pcall(function() ISTimedActionQueue.add(ISEatFoodAction:new(S.p, S.food, 1)) end)
end)
Q.step(25, function()
    local ok, st = pcall(function() return ZeD.ActionBar.state(S.p, S.pn) end)
    Q.say("action bar state " .. tostring(ok and st ~= nil))
    S.shot("D_action_bar_long_title")
end)
Q.step(10, function()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    S.takeMade()
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.unplaceAll()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    pcall(function() S.p:setTimedActionInstantCheat(S.was.cheat == true) end)
    pcall(function() S.ST.unbind(S.p) end)
    if S.watch and S.was.alarm then pcall(function() S.watch:setHour(S.was.alarm[2]); S.watch:setMinute(S.was.alarm[3]); S.watch:setAlarmSet(S.was.alarm[1]) end) end
    S.takeMade()
    G1.glassesBack(Q)
end)
Q.step(20, function()
    if ZeD.Settings.lookStyleOption:getValue() ~= (S.was.style or 1) then
        pcall(function() ZeD.Settings.lookStyleOption:setValue(S.was.style or 1); ZeD.Settings.lookStyleOption:onChange(S.was.style or 1) end)
        pcall(ZeD.Settings.reapplyFromOptions)
    end
    S.openPair(); S.charTab("loot"); S.worldTab("loot")
    S.back0()
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Q.say("put back: Style " .. tostring(ZeD.Settings.lookStyleOption:getValue()))
end)
Q.start()
