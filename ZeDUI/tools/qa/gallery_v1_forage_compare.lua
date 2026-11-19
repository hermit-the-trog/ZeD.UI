-- ZeDUI/tools/qa/gallery_v1_forage_compare.lua  (Nov 18 2026, QA): the forage pointer, the game's arrow beside ZeD's
-- hand from the same spot. The director, Nov 18: "those fingers are not pointing at the object... Are they pointing
-- the same way as the arrows?" Staged as gallery_v1_forage_pins.lua (four mushroom finds made with the game's
-- ISForageIcon) but in open ground east of the drag strip's shed so nothing stands in front of the character, the
-- windows shut. Two pictures: zqa_fcmp_hands (ZeD on) and zqa_fcmp_arrows (ZeD's safe mode on: the game's own arrow
-- on the same markers), then safe mode put back as found. Not a gallery picture: for Build. grep "ZEDQA fcmp".
if not (C2 and C2.make and ZeD and ZeD_CharacterWindow) then print("ZEDQA fcmp ERR run gallery_v1_c2_common.lua first (and ZeD on)"); print("ZEDQA fcmp DONE"); return end
local S = C2.make("fcmp")
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
    local id = "zedqa_fcmp_" .. kind
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
    S.v.moveTo(931.5, 13045.5)
    S.v.hx, S.v.hy = 931.5, 13045.5
    S.v.px, S.v.py = 931, 13045
    getGameTime():setTimeOfDay(12.0)
    S.v.mgr = ISSearchManager.getManager(S.v.p)
    S.v.searchWas = S.v.mgr and S.v.mgr.isSearchMode == true
    for t, d in pairs(forageSystem.itemDefs) do
        local inCat = false
        for _, c in ipairs(d.categories or {}) do if c == "Mushrooms" then inCat = true end end
        if inCat and pcall(instanceItem, t) and (not S.v.ty or t < S.v.ty.type) then S.v.ty = { type = t, cat = "Mushrooms" } end
    end
    S.say("at 931,13045, noon; search mode was " .. tostring(S.v.searchWas) .. "; find type " .. tostring(S.v.ty and S.v.ty.type))
end)
S.step(20, function()
    local w, mgr = C2.ww(), S.v.mgr
    if mgr and not mgr.isSearchMode then
        pcall(function() mgr:toggleSearchMode(true) end)
    end
    local okZ, z = pcall(function() return mgr:getAndActivateZoneAtXY(S.v.hx, S.v.hy) end)
    S.v.zone = okZ and z or nil
    if not S.v.zone then
        local zn
        for n in pairs(forageSystem.zoneDefs) do if not zn or n < zn then zn = n end end
        S.v.zone = { id = "zedqa_fcmp_zone", name = zn, forageIcons = {} }
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
S.step(10, function() C2.pairShut() end)
S.step(60, function()
    S.v.face()
    S.say("pointers up " .. S.v.pointers() .. " of " .. #S.v.icons .. "; search mode " .. tostring(S.v.mgr and S.v.mgr.isSearchMode))
    for _, o in ipairs(S.v.icons) do S.say(string.format("find %s at %d,%d (character %.1f,%.1f)", tostring(o.iconID), o.xCoord or -1, o.yCoord or -1, S.v.p:getX(), S.v.p:getY())) end
end)
S.step(5, function()
    if S.v.pointers() == 0 then S.say("ERR no pointer up"); return end
    C2.shot(S, "zqa_fcmp_hands")
end)
S.step(5, function()
    local opt, Sf = ZeD.Settings and ZeD.Settings.safeModeOption, ZeD.Safe
    if not (opt and Sf and Sf.reread) then S.say("ERR no safe mode option"); return end
    local ok, v = pcall(function() return opt:getValue() end)
    S.v.safeWas = ok and v or nil
    pcall(function() opt:setValue(2) end)
    Sf.reread()
    S.say("safe mode on (was " .. tostring(S.v.safeWas) .. "): " .. tostring(Sf.on()))
end)
S.step(60, function() S.v.face() end)
S.step(5, function()
    if not (ZeD.Safe and ZeD.Safe.on()) then S.say("ERR safe mode did not hold"); return end
    C2.shot(S, "zqa_fcmp_arrows")
end)
S.step(5, function()
    if S.v.safeWas ~= nil then
        pcall(function() ZeD.Settings.safeModeOption:setValue(S.v.safeWas) end)
        pcall(function() ZeD.Safe.reread() end)
    end
    S.say("safe mode put back to " .. tostring(S.v.safeWas) .. ": " .. tostring(ZeD.Safe and ZeD.Safe.on()))
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
