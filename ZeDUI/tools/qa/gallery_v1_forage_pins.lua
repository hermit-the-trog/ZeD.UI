-- ZeDUI/tools/qa/gallery_v1_forage_pins.lua  (Nov 18 2026, QA): the ZeD-GUI 1.0 gallery's picture 48 "Foraging",
-- zed_51_forage retaken with beta 20's foraging pins and Design's pointer hand (Overrides/ForagePins.lua). The street
-- retake (gallery_v1_c2_street.lua) had no finds round it, so search mode was off by the shot and no pin showed.
-- Staged as zedqa_forage_pointer.lua stages its finds (it passed 2/2 at 4K and Deck on beta 20): on the QA home's
-- tile 925,13040 (the drag strip's shed and garden beds), noon, search mode on through the Foraging tab's own switch,
-- four finds made with the game's ISForageIcon (a mushroom type, spotted with spotIcon, no XP), kept in the manager's
-- worldObjectIcons so its checkMarkers keeps their pointers, the character one tile back then facing the first find
-- (the game keeps a pointer only while its find is seen). Gallery rule: Character window left, World window right
-- (C2.sides), the World window on the Foraging tab, the pointer hidden, the load logged.
-- Run after gallery_v1_c2_common.lua (gallery_v1_forage_pins.txt). Puts back: the finds removed, search mode and
-- the time as found, the windows, the character at its start. grep "ZEDQA g1fp".
if not (C2 and C2.make and ZeD and ZeD_CharacterWindow) then print("ZEDQA g1fp ERR run gallery_v1_c2_common.lua first (and ZeD on)"); print("ZEDQA g1fp DONE"); return end
local S = C2.make("g1fp")
S.v.p, S.v.pn = C2.p, C2.pn
S.v.icons = {}
function S.v.moveTo(x, y) pcall(function() S.v.p:setX(x); S.v.p:setY(y); S.v.p:setLastX(x); S.v.p:setLastY(y) end) end
function S.v.face()
    local x, y = S.v.hx + 3.5, S.v.hy - 0.5
    if not pcall(function() S.v.p:faceLocationF(x, y) end) then pcall(function() S.v.p:faceLocation(x, y) end) end
    pcall(function() S.v.p:setForwardDirection(x - S.v.p:getX(), y - S.v.p:getY()) end)
end
-- a find, made and kept as the game makes its forage pins (zedqa_forage_pointer.lua's S.mk)
function S.v.mk(kind, dx, dy)
    local mgr, zone = S.v.mgr, S.v.zone
    local sq = getCell():getGridSquare(S.v.px + dx, S.v.py + dy, 0)
    if not (sq and S.v.ty and mgr and zone) then S.say("not staged: " .. kind); return nil end
    local id = "zedqa_g1fp_" .. kind
    local fi = { id = id, zoneid = zone.id, x = sq:getX(), y = sq:getY(), z = 0, catName = S.v.ty.cat, itemType = S.v.ty.type,
        isBonusIcon = false, canRollForSearchFocus = false }
    local o = ISForageIcon:new(mgr, fi, zone)
    o.isValidSquare = true
    o.checkIsForageable = function(me) me.isForageable = true; return true end
    mgr.xpIcons[id] = id
    mgr.worldObjectIcons[id] = o
    o:doUpdateEvents(true)
    o:addToUIManager()
    o:spotIcon()
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
        local m = o.worldMarker
        local up = false
        pcall(function() up = m ~= nil and not m:isRemoved() end)
        if up then n = n + 1 end
    end
    return n
end

-- ===================================================================== the place
S.step(5, function()
    C2.save(S)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    C2.rule()
    S.v.tod = getGameTime():getTimeOfDay()
    S.v.moveTo(925.5, 13040.5)
    S.v.hx, S.v.hy = 925.5, 13040.5
    S.v.px, S.v.py = 925, 13040
    getGameTime():setTimeOfDay(12.0)
    S.v.mgr = ISSearchManager.getManager(S.v.p)
    S.v.searchWas = S.v.mgr and S.v.mgr.isSearchMode == true
    for t, d in pairs(forageSystem.itemDefs) do
        local inCat = false
        for _, c in ipairs(d.categories or {}) do if c == "Mushrooms" then inCat = true end end
        if inCat and pcall(instanceItem, t) and (not S.v.ty or t < S.v.ty.type) then S.v.ty = { type = t, cat = "Mushrooms" } end
    end
    S.say("at 925,13040, noon; search mode was " .. tostring(S.v.searchWas) .. "; find type " .. tostring(S.v.ty and S.v.ty.type))
    C2.pairOpen()
end)
S.waitFor(10, 300, function() return C2.worldTab("forage") end, function(ok) S.v.tabOk = ok; S.say("the Foraging tab open " .. tostring(ok)) end)
S.step(20, function()
    local w, mgr = C2.ww(), S.v.mgr
    if mgr and not mgr.isSearchMode then
        if not pcall(ZeD.ForagingTab.toggleSearch, w) or not mgr.isSearchMode then pcall(function() mgr:toggleSearchMode(true) end) end
    end
    local okZ, z = pcall(function() return mgr:getAndActivateZoneAtXY(S.v.hx, S.v.hy) end)
    S.v.zone = okZ and z or nil
    if not S.v.zone then
        local zn
        for n in pairs(forageSystem.zoneDefs) do if not zn or n < zn then zn = n end end
        S.v.zone = { id = "zedqa_g1fp_zone", name = zn, forageIcons = {} }
    end
    S.say("search mode " .. tostring(mgr and mgr.isSearchMode) .. "; zone " .. tostring(S.v.zone and S.v.zone.name))
end)
-- the finds (zedqa_forage_pointer.lua's several: one ahead right, three round), then the step back and the facing
S.step(20, function()
    S.v.mk("one", 3, -1)
    S.v.mk("two", -2, 2)
    S.v.mk("three", 1, 3)
    S.v.mk("four", -3, -2)
    S.v.moveTo(S.v.hx - 1, S.v.hy)
end)
S.step(15, function() S.v.moveTo(S.v.hx, S.v.hy); S.v.face() end)
C2.ready(S)
S.step(60, function()
    S.v.face()
    S.say("pointers up " .. S.v.pointers() .. " of " .. #S.v.icons .. "; search mode " .. tostring(S.v.mgr and S.v.mgr.isSearchMode))
end)
S.step(5, function()
    if not S.v.tabOk then S.notTaken("zed_51_forage", "the Foraging tab did not open"); return end
    if S.v.pointers() == 0 then S.notTaken("zed_51_forage", "no pointer up"); return end
    C2.shot(S, "zed_51_forage")
end)

-- ===================================================================== put back
S.mark()
S.step(10, function()
    for _, o in ipairs(S.v.icons) do S.v.drop(o) end
    S.v.icons = {}
    local mgr = S.v.mgr
    if mgr and mgr.isSearchMode and not S.v.searchWas then pcall(function() mgr:toggleSearchMode(false) end) end
    if S.v.tod then getGameTime():setTimeOfDay(S.v.tod) end
    pcall(C2.worldTab, "loot")
    S.say("put back: the finds gone, search mode " .. tostring(mgr and mgr.isSearchMode) .. ", the time")
end)
S.step(20, function() C2.back(S) end)
S.step(30, function() end)
S.start()
