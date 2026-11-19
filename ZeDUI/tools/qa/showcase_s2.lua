-- ZeDUI/tools/qa/showcase_s2.lua  (Nov 18 2026, QA): the 1.0 Workshop description's showcase graphic 2, "Gadgets you
-- can hold / Know where you stand" (ZeDUI/workshop/showcase/SHOWCASE_CAPTURES.md, section 2). The UI as it is played:
-- windows at their working size to the sides (C2.sides), tabs and drawers open, the belt and HUD showing, Angel clear
-- in the middle. All at the QA home, the drag strip (925,13040): the open ground east of the shed and garden beds
-- (931,13045, gallery_v1_forage_pins.lua's spot: nothing stands in front of the character there), and a sedan on the
-- strip's marked stretch (ZEDQA_CAR_WAIT) for the dashboard.
--   sc2_forage        noon; search mode on through the Foraging tab, three spotted finds (the magnifier pins) and one
--                     not spotted yet (the pointer hand points at it); Character window left, World window right on
--                     the Foraging tab (gallery_v1_forage_pins.lua's staging)
--   sc2_watch_radio   noon; a radio set on the ground beside Angel, on (power on for the shot), shown in the World
--                     window's Radio tab; the worn watch on the belt popped up full (ZeD.Watch.togglePop); the
--                     Character window on Loot
--   sc2_context       the whole-screen moment: Angel eating (three apples queued: the action bar's thought bubble), a
--                     line said (the speech balloon), five moodles held (placed above the belt), a bandaged scratch;
--                     Character window on Health (drawer out, the left forearm lit), World window on the Radio tab with
--                     the radio playing
--   sc2_survival      the same moment closer to the brief: the World window shut, the moodles at the right side, the
--                     Character window on Health, still eating, a new line said
--   sc2_map           the World window's Maps tab on Survey (the Revised Survey Map Colors, the paper road-map look),
--                     both windows tall, centred on Irvington (2427,14185) at zoom 15 (SC2_MAPZOOM to change)
--   sc2_dash          dusk (21:00, SC2_DASH_HOUR to change), in the sedan's driver's seat, engine running, headlights on,
--                     the Full dashboard at the foot, the CD receiver (Base.RadioRed) fitted, on and tuned; windows shut
--   sc2_dash_radio    the same moment, the car radio up close (ISVehicleMenu.onSignalDevice): a close-up for the cut
-- Shots: plain names, as every gallery script (C2.shot: TakeFullScreenshot("sc2_dash.png")), so they land in
-- Zomboid/Screenshots/. Move them after the run into Zomboid/Screenshots/showcase/ (make_showcase.py's folder):
--   pwsh: New-Item -ItemType Directory -Force "$HOME\Zomboid\Screenshots\showcase"; Move-Item "$HOME\Zomboid\Screenshots\sc2_*.png" "$HOME\Zomboid\Screenshots\showcase\" -Force
-- Run after gallery_v1_c2_common.lua (manifest showcase_s2.txt):
--   zedqa_run.ps1 -Mode fullscreen4k -Manifest showcase_s2.txt -Report showcase_s2   (QA only)
-- Puts back: the finds and search mode, the radio set taken off the ground, power as it was, the watch (one given is
-- taken off and away), the watch place, device, dashboard and moodle options, the stats, the scratch, the apples
-- given, the map's style and the window heights, the car (and its key) taken away, the time, the windows, the
-- character at the start. Map ground marked known and visited round Irvington stays (QA save only).
-- Every line is "ZEDQA sc2 ..."; grep "ZEDQA sc2" ("not taken", "COVERS the character", "OVER").
-- Kahlua: no next(), ASCII only, no percent sign outside string.format, every risky call in pcall.
if not (C2 and C2.make and ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA sc2 ERR run gallery_v1_c2_common.lua first (and ZeD on)"); print("ZEDQA sc2 DONE"); return end
local S = C2.make("sc2")
S.maxMs = 960000                                  -- (16 minutes, then straight to the put-back: the manifest gives 20)
S.v.p, S.v.pn = C2.p, C2.pn
S.v.icons, S.v.optWas, S.v.statsWas = {}, {}, {}
S.v.St = ZeD.Settings
S.v.MOOD = { STRESS = 0.6, HUNGER = 0.45, THIRST = 0.45, BOREDOM = 0.6 }   -- (gallery_v1_a_zed.lua's five moodles)
S.v.SAY1 = "Last apple in Kentucky, probably."
S.v.SAY2 = "Needs salt. Everything needs salt."
S.v.TOWN = { x = 2427, y = 14185 }                -- Irvington's middle (MapsSurveyData.lua's town label)

-- ===================================================================== helpers
function S.v.moveTo(x, y) pcall(function() S.v.p:setX(x); S.v.p:setY(y); S.v.p:setLastX(x); S.v.p:setLastY(y) end) end
function S.v.setOpt(k, v) local o = S.v.St and S.v.St[k]; if o and v then pcall(function() o:setValue(v) end) end end
function S.v.face()
    local x, y = S.v.hx + 3.5, S.v.hy + 0.5   -- (between the spotted find "one" and the unspotted "two")
    if not pcall(function() S.v.p:faceLocationF(x, y) end) then pcall(function() S.v.p:faceLocation(x, y) end) end
    pcall(function() S.v.p:setForwardDirection(x - S.v.p:getX(), y - S.v.p:getY()) end)
end
-- a find, made and kept as the game makes its forage pins (gallery_v1_forage_pins.lua's S.v.mk, unchanged)
function S.v.mk(kind, dx, dy, unspotted)
    local mgr, zone = S.v.mgr, S.v.zone
    local sq = getCell():getGridSquare(S.v.px + dx, S.v.py + dy, 0)
    if not (sq and S.v.ty and mgr and zone) then S.say("not staged: " .. kind); return nil end
    local id = "zedqa_sc2_" .. kind
    local fi = { id = id, zoneid = zone.id, x = sq:getX(), y = sq:getY(), z = 0, catName = S.v.ty.cat, itemType = S.v.ty.type,
        isBonusIcon = false, canRollForSearchFocus = false }
    local o = ISForageIcon:new(mgr, fi, zone)
    o.isValidSquare = true
    o.checkIsForageable = function(me) me.isForageable = true; return true end
    mgr.xpIcons[id] = id
    mgr.worldObjectIcons[id] = o
    o:doUpdateEvents(true)
    o:addToUIManager()
    -- (the hand points only at a find not spotted yet: its spot timer stopped keeps it that way for the shot)
    if unspotted then o.updateSpotTimer = function() end else o:spotIcon() end
    S.v.icons[#S.v.icons + 1] = o
    return o
end
function S.v.drop(o)
    local mgr = S.v.mgr
    pcall(function()
        mgr.seenIcons[o.iconID] = nil
        mgr.xpIcons[o.iconID] = nil
        mgr:removeIcon(o)
        mgr.worldObjectIcons[o.iconID] = nil
        if mgr.isoMarkers then mgr.isoMarkers[o.iconID] = nil end
        if mgr.worldMarkers then mgr.worldMarkers[o.iconID] = nil end
    end)
end
function S.v.pointers()
    local n = 0
    for _, o in ipairs(S.v.icons) do
        local up = false
        pcall(function() up = o.worldMarker ~= nil and not o.worldMarker:isRemoved() end)
        if up then n = n + 1 end
    end
    return n
end
function S.v.dropFinds()
    for _, o in ipairs(S.v.icons) do S.v.drop(o) end
    S.v.icons = {}
    local mgr = S.v.mgr
    if mgr and mgr.isSearchMode and not S.v.searchWas then pcall(function() mgr:toggleSearchMode(false) end) end
end
-- the stats held every tick (eating and the clock would move them off the moodles)
function S.v.hold()
    pcall(function()
        local st = S.v.p:getStats()
        for k, v in pairs(S.v.MOOD) do st:set(CharacterStat[k], v) end
    end)
end
-- the Health figure's left forearm held as if hovered (gallery_v1_a_zed.lua 26): the scratch's detail shows, lit
function S.v.holdArm()
    local w = C2.cw()
    if w and w._activeTab == "health" then w._healthHoveredPart = "Left Forearm"; w._healthFigureExpanded = true end
end
-- the full watch kept up (it tucks itself away after a few idle seconds)
function S.v.holdWatch()
    local inst = nil
    pcall(function() inst = ZeD.Watch.getInstance() end)
    if inst then inst._popTouched = getTimestampMs() end
end
function S.v.on(fn, key) if not S.v[key] then Events.OnTick.Add(fn); S.v[key] = true end end
function S.v.off(fn, key) if S.v[key] then Events.OnTick.Remove(fn); S.v[key] = nil end end
function S.v.forearm()
    local bp = nil
    pcall(function() bp = S.v.p:getBodyDamage():getBodyPart(BodyPartType.ForeArm_L) end)
    return bp
end
-- a bandaged scratch on the left forearm, or gone again (gallery_v1_a_common.lua's G1.wound)
function S.v.wound(on)
    local bp = S.v.forearm()
    if not bp then S.say("ERR no left forearm"); return end
    if on then
        pcall(function() bp:setScratched(true, true) end)
        pcall(function() bp:setInfectedWound(false) end)
        if not pcall(function() bp:setBandaged(true, 10.0, false, "Base.Bandage") end) then pcall(function() bp:setBandaged(true, 10.0) end) end
        S.v.wounded = true
    elseif S.v.wounded then
        pcall(function() bp:setBandaged(false, 0.0) end)
        pcall(function() bp:setScratched(false, true) end)
        pcall(function() bp:setScratchTime(0) end)
        S.v.wounded = nil
    end
end
-- the first timed action, its type and how far along (gallery_story_stage.lua's ST.action)
function S.v.action()
    local q = ISTimedActionQueue.getTimedActionQueue(S.v.p)
    local a = q and q.queue and q.queue[1]
    if not a then return nil, 0 end
    local d = 0
    pcall(function() d = a:getJobDelta() end)
    return a.Type, d
end
-- three apples given and eaten whole, queued (zedqa_bubbles.lua's eat): the action bar shows the queue
function S.v.eat()
    for _ = 1, 3 do
        local it = C2.give("Base.Apple")
        if it then pcall(function() ISInventoryPaneContextMenu.eatItem(it, 1, S.v.pn) end) end
    end
end
function S.v.eating() local t, d = S.v.action(); return t == "ISEatFoodAction" and d >= 0.15 end
function S.v.moodlesLine(place)
    local L = nil
    pcall(function() L = ZeD.Moodles.getLayer(S.v.pn) end)
    local keys = {}
    for _, e in ipairs(L and L._list or {}) do keys[#keys + 1] = tostring(e.key) end
    S.say("moodles " .. place .. ": " .. #keys .. " on (" .. table.concat(keys, " ") .. ")")
    return #keys
end
-- the World window open with the Character window (it may have been shut alone for the survival shot)
function S.v.bothOpen()
    if not C2.isOpen() then C2.pairOpen(); return end
    local wOpen = false
    pcall(function() wOpen = ZeD_WorldWindow.isOpen(S.v.pn) end)
    if not wOpen then pcall(ZeD_WorldWindow.open, S.v.pn) end
end
function S.v.worldShut() pcall(ZeD_WorldWindow.close, S.v.pn) end
-- a free square beside the character, not in front of him (the ones to the north and west draw behind)
function S.v.besideSq()
    for _, d in ipairs({ { 1, -1 }, { 0, -1 }, { -1, -1 }, { -1, 0 }, { 2, -1 } }) do
        local sq = C2.sq(S.v.px + d[1], S.v.py + d[2], 0)
        if C2.free(sq) then return sq end
    end
    return nil
end
function S.v.radioUp() pcall(function() local dd = S.v.radio:getDeviceData(); dd:setIsTurnedOn(true) end) end
function S.v.radioAway()
    local o = S.v.radio
    if not o then return end
    pcall(function() o:getDeviceData():setIsTurnedOn(false) end)
    pcall(function() local sq = o:getSquare(); if sq then sq:transmitRemoveItemFromSquare(o) end end)
    S.v.radio = nil
end
-- the worn watch (any alarm-clock clothing on the wrist); none worn: a CaZio digital is given and worn for the run
function S.v.watchOn()
    pcall(function()
        local worn = S.v.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local wi = worn:get(i)
            if instanceof(wi:getItem(), "AlarmClockClothing") then S.v.kit = wi:getItem() end
        end
    end)
    if S.v.kit then return end
    pcall(function()
        S.v.ownWatch = S.v.p:getInventory():AddItem("Base.WristWatch_Left_DigitalBlack")
        S.v.p:setWornItem(S.v.ownWatch:getBodyLocation(), S.v.ownWatch)
    end)
end
function S.v.watchOff()
    if not S.v.ownWatch then return end
    pcall(function() S.v.p:removeWornItem(S.v.ownWatch, false) end)
    pcall(function() local c = S.v.ownWatch:getContainer(); if c then c:Remove(S.v.ownWatch) end end)
    S.v.ownWatch = nil
end
function S.v.dash() local d = nil; pcall(function() d = ZeD.Dashboard.getInstance() end); return d end
-- both windows taller for the map (their heights kept to put back)
function S.v.tall(on)
    local c, w = C2.cw(), C2.ww()
    if on then
        S.v.hWas = { c = c and c:getHeight(), w = w and w:getHeight() }
        local H = math.floor(C2.core:getScreenHeight() * 0.80)
        for _, e in ipairs({ c, w }) do
            if e then pcall(function() e:setY(C2.margin()); e:setHeight(H); e:onResize() end) end
        end
    elseif S.v.hWas then
        if c and S.v.hWas.c then pcall(function() c:setHeight(S.v.hWas.c); c:onResize() end) end
        if w and S.v.hWas.w then pcall(function() w:setHeight(S.v.hWas.w); w:onResize() end) end
        S.v.hWas = nil
    end
end
function S.v.carOff()
    local v = S.v.car
    if not v then return end
    local d = S.v.dash()
    if S.v.inside and d and d._st then
        if d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
        if d._st.lights then pcall(function() d:_fire("lights", false) end) end
    end
    pcall(function() ZeD.CarRadio.closeFor(S.v.pn) end)
    pcall(function() if v:isEngineRunning() then v:shutOff() end end)
    pcall(function() v:setKeysInIgnition(false) end)
    -- (ZEDQA_CAR_AWAY: Angel out, the key out of the inventory, the car removed on a later tick)
    if ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(v, S.v.key) end
    S.v.car, S.v.key, S.v.inside = nil, nil, nil
end

-- (Nov 18 2026, QA: SC2_ONLY = { map = true, dash = true } takes only those sections, for Build's retakes;
-- SC2_MAPWIDE widens the World window for the map shot, put back after)
local function want(k) return (not SC2_ONLY) or SC2_ONLY[k] == true end
-- ===================================================================== the place, what is kept to put back
S.step(5, function()
    C2.save(S)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    C2.rule()
    for _, k in ipairs({ "watchPlaceOption", "watchStyleOption", "dashStyleOption", "devicesStyleOption", "beltStyleOption", "moodlePlaceOption" }) do
        local o = S.v.St and S.v.St[k]
        if o then S.v.optWas[k] = o:getValue() end
    end
    pcall(function() for k, _ in pairs(S.v.MOOD) do S.v.statsWas[k] = S.v.p:getStats():get(CharacterStat[k]) end end)
    local md = S.v.p:getModData()
    S.v.mapWas = { style = md.ZeD_MapStyle, paper = md.ZeD_MapPaper }
    -- the immersive looks (Full dashboard, devices as hardware, the belt and watch drawn), the watch on the belt
    S.v.setOpt("dashStyleOption", 1); S.v.setOpt("devicesStyleOption", 1); S.v.setOpt("beltStyleOption", 1)
    S.v.setOpt("watchStyleOption", 1); S.v.setOpt("watchPlaceOption", 1)
    -- (the open ground east of the shed: nothing between Angel and the camera)
    S.v.hx, S.v.hy = 931.5, 13045.5
    S.v.px, S.v.py = 931, 13045
    S.v.moveTo(S.v.hx, S.v.hy)
    getGameTime():setTimeOfDay(12.0)
    S.v.mgr = ISSearchManager.getManager(S.v.p)
    S.v.searchWas = S.v.mgr and S.v.mgr.isSearchMode == true
    -- a mushroom type the forage system knows, the lowest name so every run picks the same one
    for t, d in pairs(forageSystem.itemDefs) do
        local inCat = false
        for _, c in ipairs(d.categories or {}) do if c == "Mushrooms" then inCat = true end end
        if inCat and pcall(instanceItem, t) and (not S.v.ty or t < S.v.ty.type) then S.v.ty = { type = t, cat = "Mushrooms" } end
    end
    S.say("at 931,13045 (the drag strip, east of the shed), noon; search mode was " .. tostring(S.v.searchWas)
        .. "; find type " .. tostring(S.v.ty and S.v.ty.type) .. "; options kept")
    C2.pairOpen()
end)

if want("forage") then
-- ===================================================================== sc2_forage
S.waitFor(10, 300, function() return C2.worldTab("forage") end, function(ok) S.v.tabOk = ok; S.say("the Foraging tab open " .. tostring(ok)) end)
S.step(20, function()
    local w, mgr = C2.ww(), S.v.mgr
    if mgr and not mgr.isSearchMode then
        -- (the tab's own switch first, the manager's if that did not take)
        if not pcall(ZeD.ForagingTab.toggleSearch, w) or not mgr.isSearchMode then pcall(function() mgr:toggleSearchMode(true) end) end
    end
    local okZ, z = pcall(function() return mgr:getAndActivateZoneAtXY(S.v.hx, S.v.hy) end)
    S.v.zone = okZ and z or nil
    if not S.v.zone then
        -- (no forage zone here: a made-up one named after the first zone kind)
        local zn
        for n in pairs(forageSystem.zoneDefs) do if not zn or n < zn then zn = n end end
        S.v.zone = { id = "zedqa_sc2_zone", name = zn, forageIcons = {} }
    end
    S.say("search mode " .. tostring(mgr and mgr.isSearchMode) .. "; zone " .. tostring(S.v.zone and S.v.zone.name))
end)
S.step(20, function()
    S.v.mk("one", 3, -1)
    S.v.mk("two", 3, 2, true)        -- not spotted yet: the hand points at it
    S.v.mk("three", 1, 3)
    S.v.mk("four", -3, -2)
    S.v.moveTo(S.v.hx - 1, S.v.hy)   -- (a step back and in again, so the game sees the finds from the spot)
end)
S.step(15, function() S.v.moveTo(S.v.hx, S.v.hy); S.v.face() end)
C2.ready(S)
S.step(60, function()
    S.v.face()
    S.say("pointers up " .. S.v.pointers() .. " of " .. #S.v.icons .. "; search mode " .. tostring(S.v.mgr and S.v.mgr.isSearchMode))
end)
S.step(5, function()
    if not S.v.tabOk then S.notTaken("sc2_forage", "the Foraging tab did not open"); return end
    if S.v.pointers() == 0 then S.notTaken("sc2_forage", "no pointer up"); return end
    C2.shot(S, "sc2_forage")
end)
S.step(10, function()
    S.v.dropFinds()
    pcall(C2.worldTab, "loot")
    S.say("finds gone, search mode " .. tostring(S.v.mgr and S.v.mgr.isSearchMode))
end)
end

if want("watch") then
-- ===================================================================== sc2_watch_radio
S.step(10, function()
    C2.power(true)                                -- (the radio runs off the grid: power on, put back by C2.back)
    local sq = S.v.besideSq()
    if not sq then S.say("ERR no free square beside Angel for the radio"); return end
    pcall(function()
        local o = IsoRadio.new(getCell(), sq, getSprite("appliances_radio_01_0"))
        sq:AddTileObject(o)
        S.v.radio = o
    end)
    S.say("radio set down at " .. sq:getX() .. "," .. sq:getY() .. ": " .. tostring(S.v.radio ~= nil))
    S.v.watchOn()
    S.say("watch: " .. (S.v.kit and ("worn " .. tostring(S.v.kit:getFullType())) or ("given " .. tostring(S.v.ownWatch and S.v.ownWatch:getFullType()))))
end)
S.step(30, function()
    pcall(function() local dd = S.v.radio:getDeviceData(); dd:setDeviceVolume(0.3); dd:setIsTurnedOn(true) end)
    C2.charTab("loot")
end)
-- the radio in the World window's Radio tab (gallery_b19_a.lua's TV: the tab follows _radioIdx)
S.waitFor(10, 600, function()
    local w = C2.ww()
    for _, r in ipairs(w and w._radios or {}) do if r.radioInstance == S.v.radio then return true end end
    return S.v.radio == nil
end, function(ok)
    local w = C2.ww()
    for i, r in ipairs(w and w._radios or {}) do if r.radioInstance == S.v.radio then w._radioIdx = i end end
    S.v.radioTab = C2.worldTab("radio")
    S.say("the radio in the World window's list " .. tostring(ok) .. "; Radio tab " .. tostring(S.v.radioTab))
end)
S.waitFor(5, 600, function() local w = C2.ww(); local t = w and w._radioTw; return S.v.radio == nil or (t ~= nil and t.dev == S.v.radio) end, function() end)
S.step(20, function()
    local on = false
    pcall(function() on = S.v.radio:getDeviceData():getIsTurnedOn() end)
    S.say("radio on " .. tostring(on))
    pcall(function() ZeD.Watch.togglePop(true) end)
    S.v.on(S.v.holdWatch, "watchHeld")
end)
C2.ready(S)
S.step(30, function()
    local inst, popped = nil, false
    pcall(function() inst = ZeD.Watch.getInstance(); popped = inst and inst._popped == true end)
    if not S.v.radio then S.notTaken("sc2_watch_radio", "no radio set down"); return end
    if not popped then S.say("note: the full watch is not up (" .. tostring(inst ~= nil) .. ")") end
    local w = C2.ww()
    local t = w and w._radioTw
    if not (t and t.dev == S.v.radio) then S.say("note: the Radio tab shows " .. tostring(t and t.dev)) end
    C2.shot(S, "sc2_watch_radio", { extra = { { "watch", inst } } })
end)
S.step(5, function()
    S.v.off(S.v.holdWatch, "watchHeld")
    pcall(function() ZeD.Watch.togglePop(false) end)
end)
end

if want("context") then
-- ===================================================================== sc2_context (both windows) and sc2_survival
S.step(10, function()
    pcall(function() S.v.p:setGodMod(false) end)    -- (god mode clears the stats every tick)
    S.v.hold()
    S.v.on(S.v.hold, "statsHeld")
    S.v.setOpt("moodlePlaceOption", 3)              -- (above the belt: both windows stand at the sides)
    S.v.wound(true)
    S.v.face()
end)
S.waitFor(10, 120, function() return C2.charTab("health") end, function(ok)
    S.say("Health tab " .. tostring(ok))
    local w = C2.cw()
    if w then w._healthFigureExpanded = true; pcall(function() w._healthScroll:setScrollPos(0) end) end
    S.v.on(S.v.holdArm, "armHeld")
end)
S.step(10, function() S.v.eat() end)
S.waitFor(10, 1200, function() return S.v.eating() end, function(ok)
    local t, d = S.v.action()
    S.say(string.format("eating %s: %s at %.2f", tostring(ok), tostring(t), d or 0))
end)
C2.ready(S)
S.step(2, function() pcall(function() S.v.p:Say(S.v.SAY1) end) end)
S.step(30, function()
    S.v.radioUp()
    local n = S.v.moodlesLine("above the belt")
    if not S.v.eating() then S.say("note: the eating had ended by the shot") end
    if n < 3 then S.say("note: only " .. n .. " moodles on") end
    C2.shot(S, "sc2_context")
end)
-- the survival close-up: the World window shut, the moodles at the right side
S.step(5, function()
    S.v.worldShut()
    S.v.setOpt("moodlePlaceOption", 1)
    -- (still eating: else three more apples)
    if not S.v.eating() then pcall(function() ISTimedActionQueue.clear(S.v.p) end); S.v.eat() end
end)
S.waitFor(10, 1200, function() return S.v.eating() end, function(ok) S.say("eating again " .. tostring(ok)) end)
C2.ready(S)
S.step(60, function() pcall(function() S.v.p:Say(S.v.SAY2) end) end)
S.step(30, function()
    local n = S.v.moodlesLine("right")
    local w = C2.cw()
    if not (w and w._activeTab == "health") then S.say("note: the Character window is on " .. tostring(w and w._activeTab)) end
    if n < 3 then S.say("note: only " .. n .. " moodles on") end
    C2.shot(S, "sc2_survival")
end)
S.step(10, function()
    pcall(function() ISTimedActionQueue.clear(S.v.p) end)
    S.v.off(S.v.holdArm, "armHeld")
    local w = C2.cw()
    if w then w._healthHoveredPart = nil end
    S.v.wound(false)
    S.v.off(S.v.hold, "statsHeld")
    pcall(function() for k, v in pairs(S.v.statsWas) do S.v.p:getStats():set(CharacterStat[k], v) end end)
    S.v.setOpt("moodlePlaceOption", S.v.optWas.moodlePlaceOption)
    S.v.radioAway()
    S.v.bothOpen()
    S.say("eating stopped, scratch and stats back, radio taken away")
end)
end

if want("map") then
-- ===================================================================== sc2_map
S.step(20, function()
    C2.charTab("loot")
    -- (Build, Nov 18 2026: unvisited ground draws as fog patches; Irvington and the strip marked known AND visited)
    local okR = pcall(function()
        local v = WorldMapVisited.getInstance()
        v:setKnownInSquares(0, 11800, 4400, 15900)
        v:setVisitedInSquares(0, 11800, 4400, 15900)
    end)
    S.say("Irvington and the strip revealed " .. tostring(okR))
end)
S.waitFor(10, 300, function() return C2.worldTab("maps") end, function(ok) S.v.mapTab = ok; S.say("the Maps tab open " .. tostring(ok)) end)
S.step(10, function()
    S.v.tall(true)
    if SC2_MAPWIDE then
        local w = C2.ww()
        if w then
            S.v.mapWWas = w:getWidth()
            pcall(function() w:setWidth(math.floor(C2.core:getScreenWidth() * SC2_MAPWIDE)); w:onResize() end)
            S.say("World window widened for the map: " .. tostring(S.v.mapWWas) .. " to " .. tostring(w:getWidth()))
        end
    end
    pcall(function() ZeD.MapsTab.setStyle(C2.ww(), "survey") end)
end)
-- (a restyle holds the map off the screen a few frames: centred and zoomed after it)
S.step(40, function()
    local mp = C2.ww() and C2.ww()._worldMapPanel
    if not mp then S.say("ERR no map panel"); return end
    S.v.zoom = SC2_MAPZOOM or 15
    pcall(function() mp.mapAPI:centerOn(S.v.TOWN.x, S.v.TOWN.y); mp:_zoomTo(S.v.zoom) end)
    S.say("map style " .. tostring(mp.style) .. ", on Irvington " .. S.v.TOWN.x .. "," .. S.v.TOWN.y .. " at zoom " .. S.v.zoom)
end)
S.step(90, function() end)
C2.ready(S)
S.step(10, function()
    local w = C2.ww()
    local mp = w and w._worldMapPanel
    if not (S.v.mapTab and mp) then S.notTaken("sc2_map", "the Maps tab did not open"); return end
    if mp.style ~= "survey" then S.say("note: the map is on " .. tostring(mp.style)) end
    pcall(function() S.say(string.format("map on screen: panel %d,%d %dx%d", math.floor(mp:getAbsoluteX()), math.floor(mp:getAbsoluteY()),
        math.floor(mp:getWidth()), math.floor(mp:getHeight()))) end)
    C2.shot(S, "sc2_map")
end)
S.step(10, function()
    local w = C2.ww()
    local md = S.v.p:getModData()
    local want = S.v.mapWas.style or ((S.v.mapWas.paper == true) and "paper" or "survey")
    pcall(function() ZeD.MapsTab.setStyle(w, want) end)
    md.ZeD_MapStyle, md.ZeD_MapPaper = S.v.mapWas.style, S.v.mapWas.paper
    S.v.tall(false)
    if S.v.mapWWas and w then pcall(function() w:setWidth(S.v.mapWWas); w:onResize() end); S.v.mapWWas = nil end
    C2.worldTab("loot")
    S.say("map put back: style " .. tostring(want) .. ", window heights")
end)
end

if want("dash") then
-- ===================================================================== sc2_dash and sc2_dash_radio
S.step(20, function()
    C2.pairShut()
    getGameTime():setTimeOfDay(SC2_DASH_HOUR or 21.0)
    if not ZEDQA_CAR_WAIT then S.v.carWhy = "no ZEDQA_CAR_WAIT (run zedqa_prelude.lua first)"; return end
    -- (a sedan on the strip's next clear spot, ready once its physics woke)
    ZEDQA_CAR_WAIT("Base.CarNormal", "sc2", function(v) S.v.car = v end, function(why) S.v.carWhy = why or "no car" end)
end)
S.waitFor(10, 1200, function() return S.v.car ~= nil or S.v.carWhy ~= nil end, function()
    if not S.v.car then
        S.v.carWhy = S.v.carWhy or "the car never got ready"
        S.notTaken("sc2_dash", S.v.carWhy); S.notTaken("sc2_dash_radio", S.v.carWhy)
        return
    end
    local v = S.v.car
    S.v.key = ZEDQA_CAR_PREP and ZEDQA_CAR_PREP(v)
    -- the CD receiver fitted the way vanilla's install ends (gallery_b19_b.lua's g5_car_radio)
    local part = v:getPartById("Radio")
    S.v.part = part
    if part then
        local okF, e = pcall(function()
            part:setInventoryItem(instanceItem("Base.RadioRed"))
            Vehicles.InstallComplete.Radio(v, part)
            local dd = part:getDeviceData()
            if dd and dd:getDevicePresets():getPresets():size() == 0 then dd:generatePresets() end
        end)
        if not okF then S.say("note: the CD receiver did not fit: " .. tostring(e)); S.v.part = nil end
    else S.say("note: the sedan has no Radio part") end
    local okE, why = ZEDQA_CAR_ENTER(v, 0)
    if not okE then S.v.carWhy = why; S.notTaken("sc2_dash", why); S.notTaken("sc2_dash_radio", why); return end
    S.v.inside = true
    pcall(function() v:setKeysInIgnition(true) end)
    S.v.t, S.v.tries = 0, 0
end)
-- the engine: up to 5 tries, one each second while no action is queued
S.waitFor(10, 1500, function()
    if not S.v.inside then return true end
    local run = false
    pcall(function() run = S.v.car:isEngineRunning() end)
    if run then return true end
    S.v.t = S.v.t + 1
    local q = ISTimedActionQueue.getTimedActionQueue(S.v.p)
    if not (q and q.queue and #q.queue > 0) and S.v.t >= 60 * S.v.tries and S.v.tries < 5 then
        S.v.tries = S.v.tries + 1
        pcall(function() ISVehicleMenu.onStartEngine(S.v.p) end)
    end
    return false
end, function()
    if not S.v.inside then return end
    local run = false
    pcall(function() run = S.v.car:isEngineRunning() end)
    S.say("engine running " .. tostring(run) .. " after " .. tostring(S.v.tries) .. " tries")
    local d = S.v.dash()
    if d and d._st then
        if not d._st.lights then pcall(function() d:_fire("lights", false) end) end
        if not d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
    end
end)
S.step(60, function()
    if not (S.v.inside and S.v.part) then return end
    pcall(function() ZeD.RadioOps.setChannel(S.v.p, S.v.part, 101200) end)
    pcall(function() ZeD.RadioOps.run("SetVolume", S.v.p, S.v.part, 0.6) end)
end)
S.step(120, function() C2.hidePointer() end)
S.step(10, function()
    if not S.v.inside then return end
    local d = S.v.dash()
    S.say("dashboard " .. tostring(d ~= nil) .. " | lights " .. tostring(d and d._st and d._st.lights) .. " | radio " .. tostring(d and d._st and d._st.radioOn)
        .. string.format(" | %.2f o'clock", getGameTime():getTimeOfDay()))
    C2.shot(S, "sc2_dash", { extra = { { "dash", d } } })
end)
S.step(30, function() if S.v.inside and S.v.part then pcall(function() ISVehicleMenu.onSignalDevice(S.v.p, S.v.part) end) end end)
S.step(60, function() C2.hidePointer() end)
S.step(10, function()
    if not S.v.inside then return end
    if not S.v.part then S.notTaken("sc2_dash_radio", "no car radio"); return end
    local pr = nil
    pcall(function() pr = ZeD.CarRadio.props[S.v.pn] end)
    if pr and pr:isReallyVisible() then C2.shot(S, "sc2_dash_radio", { extra = { { "carradio", pr } } })
    else S.notTaken("sc2_dash_radio", "the car radio did not come up") end
end)
S.step(10, function() S.v.carOff() end)
S.step(30, function() S.say("out of the car: " .. tostring(S.v.p:getVehicle() == nil)) end)
end

-- ===================================================================== put back
S.mark()
S.step(10, function()
    S.v.off(S.v.holdWatch, "watchHeld"); S.v.off(S.v.holdArm, "armHeld"); S.v.off(S.v.hold, "statsHeld")
    pcall(function() ZeD.Watch.togglePop(false) end)
    S.v.carOff()
    S.v.dropFinds()
    S.v.radioAway()
    S.v.wound(false)
    local w = C2.cw()
    if w then w._healthHoveredPart = nil end
    pcall(function() for k, v in pairs(S.v.statsWas) do S.v.p:getStats():set(CharacterStat[k], v) end end)
    if S.v.hWas then S.v.tall(false) end
end)
S.step(20, function()
    S.v.watchOff()
    for k, v in pairs(S.v.optWas) do S.v.setOpt(k, v) end
    local md = S.v.p:getModData()
    md.ZeD_MapStyle, md.ZeD_MapPaper = S.v.mapWas and S.v.mapWas.style, S.v.mapWas and S.v.mapWas.paper
    S.say("put back: finds, radio, watch " .. tostring(S.v.kit and S.v.kit:getFullType() or "given and taken away")
        .. ", options, stats, scratch, map style, car")
end)
S.step(20, function() C2.back(S) end)
S.step(30, function() end)
S.start()
