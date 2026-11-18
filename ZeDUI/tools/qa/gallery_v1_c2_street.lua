-- ZeDUI/tools/qa/gallery_v1_c2_street.lua  (Nov 17 2026, QA): ZeD-GUI 1.0 gallery, lived-in retakes on the street in
-- front of the Fossoil, West Point (outdoors, paved, the store behind the character; C2.street). Same content and names
-- as today's captures; only the place and the window places change:
--   42 Thermal Tab       zed_70_thermal_insulation, zed_72_thermal_wetness, zed_66_thermal_skin   (gallery_v3_b2.lua: the
--        clothes worn wet (70), the air at 2 C with wind 0.6, the Thermal tab's views 5, 7 and 1)
--   47 Building          zed_50_building   (gallery_v3_zed.lua: the Building tab, the first unlocked recipe open)
--   48 Foraging and Furniture  zed_51_forage, zed_52_furniture   (gallery_nov1_lot.lua: Search on in the street's own
--        zone, More detail open, finds in the list; a movable piece (the first named outdoor seat the game moves, the
--        Outdoor Bench family first) under the pointer on a clear square, the pointer shown: the hover is the point)
--   53 Dashboards        zqa_r6p_taxi_extras   (zedqa_dash_r6_parts.lua: a taxi on the street, key in, engine running,
--        lights on, the meter's flag down, three riders: the extras)
-- THE NEW RULE: the Character window at the left edge, the World window at the right edge; the character and the store
-- clear in the middle. Every shot logs the load line, any container over its limit and every window's box.
-- Puts back: wetness and weather, the recipe, search mode and the finds list, More detail, the piece placed, the taxi,
-- its key, the riders, the windows, the clock, the character at the QA home. Run after gallery_v1_c2_common.lua (and
-- zedqa_prelude.lua earlier in the run, for the car checks). grep "ZEDQA gv1s".
if not (C2 and C2.make and ZeD and ZeD_CharacterWindow) then print("ZEDQA gv1s ERR run gallery_v1_c2_common.lua first (and ZeD on)"); print("ZEDQA gv1s DONE"); return end
local S = C2.make("gv1s")
S.v.p, S.v.pn = C2.p, C2.pn

-- ===================================================================== the street
S.step(5, function()
    C2.save(S)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    C2.rule()
end)
C2.goWestPoint(S)
S.step(2, function()
    S.v.spot = C2.street(S)
    if not S.v.spot then S.say("ERR no clear paved square on the street in front of the Fossoil") end
end)
S.step(5, function()
    if not S.v.spot then return end
    C2.tpSq(S.v.spot); C2.face("SE")
    C2.placeName = "the street in front of the Fossoil, West Point"
    pcall(function() getGameTime():setTimeOfDay(11.0) end)
end)
S.step(60, function() if S.v.spot then C2.pairOpen() end end)
S.step(30, function() if S.v.spot then C2.sides(S) end end)

-- ===================================================================== 42 Thermal Tab (gallery_v3_b2.lua)
S.step(2, function()
    if not S.v.spot then return end
    S.v.wet = {}
    pcall(function()
        local worn = S.v.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local it = worn:get(i):getItem()
            if instanceof(it, "Clothing") then
                S.v.wet[#S.v.wet + 1] = { it = it, w = it:getWetness() }
                pcall(function() it:setWetness(70) end)
            end
        end
    end)
    C2.clim({ TEMPERATURE = 2.0, WIND_INTENSITY = 0.6 })
    C2.charTab("thermal")
    S.say("thermal: " .. #S.v.wet .. " worn things wet, 2 C, wind 0.6")
end)
S.waitMs(4000)
S.v.TH = { { 5, "zed_70_thermal_insulation" }, { 7, "zed_72_thermal_wetness" }, { 1, "zed_66_thermal_skin" } }
for _, e in ipairs(S.v.TH) do
    S.step(2, function() if S.v.spot then C2.charTab("thermal"); local c = C2.cw(); if c then c._thermalView = e[1] end end end)
    S.step(25, function() end)
    C2.ready(S)
    S.step(5, function()
        if not S.v.spot then S.notTaken(e[2], "no street spot"); return end
        local c = C2.cw()
        if not (c and c._activeTab == "thermal") then S.notTaken(e[2], "no Thermal tab"); return end
        C2.shot(S, e[2])
    end)
end
S.step(2, function()
    local c = C2.cw()
    if c then c._thermalView = 1 end
    for _, w in ipairs(S.v.wet or {}) do pcall(function() w.it:setWetness(w.w) end) end
    C2.climBack()
    C2.charTab("loot")
    S.say("thermal put back: wetness and weather")
end)

-- ===================================================================== 47 Building (gallery_v3_zed.lua's Z.recipe)
function S.v.recipe(open)
    local w = C2.ww()
    if not w then return false, "no World window" end
    local st = w._buildState
    if not st then return false, "no build state" end
    if not open then ZeD.CraftingCore.closeCraft(st); return true end
    local data = ZeD.BuildingTab.gatherData(S.v.p, w)
    local pick = nil
    for _, rd in ipairs(data and data.recipes or {}) do
        if rd.status == "unlocked" then pick = rd; break end
    end
    pick = pick or (data and data.recipes and data.recipes[1])
    if not pick then return false, "no recipe" end
    ZeD.CraftingCore.openCraft(st, pick.entry.name)
    S.say("recipe open: " .. tostring(pick.entry.name))
    return true
end
S.waitFor(2, 120, function() return not S.v.spot or C2.worldTab("build") end, function(ok) S.v.bOk = ok and S.v.spot ~= nil end)
S.step(6, function()
    if not S.v.bOk then return end
    local ok, a, b = pcall(S.v.recipe, true)
    if not ok or a == false then S.v.bOk = false; S.v.bWhy = tostring(ok and b or a) end
end)
S.step(50, function() end)
C2.ready(S)
S.step(5, function()
    if not S.v.bOk then S.notTaken("zed_50_building", S.v.bWhy or "no Building tab"); return end
    C2.shot(S, "zed_50_building")
end)
S.step(2, function() pcall(S.v.recipe, false) end)

-- ===================================================================== 48 Foraging (gallery_nov1_lot.lua's forage)
S.v.FQ = { tries = 0, last = -9999, f = 0 }
function S.v.FQ.queue() return ZeD.ForagingTab._findQueues[S.v.pn] or {} end
S.waitFor(2, 120, function() return not S.v.spot or C2.worldTab("forage") end, function(ok) S.v.fOk = ok and S.v.spot ~= nil and ZeD.ForagingTab ~= nil end)
S.step(30, function()
    if not S.v.fOk then return end
    local w = C2.ww()
    local mgr = ISSearchManager.getManager(S.v.p)
    S.v.FQ.mgr = mgr
    S.v.fWas = { more = w._moreDetailOpen, search = mgr and mgr.isSearchMode or false, finds = ZeD.ForagingTab._findQueues[S.v.pn] }
    local copy = {}
    for i, e in ipairs(S.v.fWas.finds or {}) do copy[i] = e end
    ZeD.ForagingTab._findQueues[S.v.pn] = copy
    w._moreDetailOpen = true
    if mgr and not mgr.isSearchMode then ZeD.ForagingTab.toggleSearch(w) end
    C2.sides(S)
    S.say(string.format("forage: search mode %s (was %s) | finds listed %d | More detail open", tostring(mgr and mgr.isSearchMode), tostring(S.v.fWas.search), #copy))
end)
S.waitMs(8000)
S.step(2, function()
    if not S.v.fOk then return end
    local mgr = S.v.FQ.mgr
    local nA, nF = 0, 0
    for _ in pairs(mgr and mgr.activeIcons or {}) do nA = nA + 1 end
    for _ in pairs(mgr and mgr.forageIcons or {}) do nF = nF + 1 end
    local zone = mgr and mgr.currentZone
    S.say(string.format("forage: zone %s | radius %s | icons %d (%d active) | finds %d by the search itself",
        tostring(zone and (zone.name or zone.type or zone.id)), tostring(mgr and mgr.radius), nF, nA, #S.v.FQ.queue()))
    if mgr and not mgr.isSearchMode then S.say("note: search mode went off: on again"); ZeD.ForagingTab.toggleSearch(C2.ww()) end
end)
S.waitFor(10, 2400, function()
    if not S.v.fOk then return true end
    local mgr = S.v.FQ.mgr
    if not mgr then return true end
    if #S.v.FQ.queue() >= 5 then return true end
    S.v.FQ.f = S.v.FQ.f + 1
    if S.v.FQ.f - S.v.FQ.last < 60 then return false end
    S.v.FQ.last = S.v.FQ.f
    S.v.FQ.tries = S.v.FQ.tries + 1
    local best, bd = nil, 1e9
    local px, py = S.v.p:getX(), S.v.p:getY()
    local reach = (tonumber(mgr.radius) or 6) + 3
    for _, icon in pairs(mgr.activeIcons or {}) do
        local seen = true
        pcall(function() seen = icon:getIsSeen() end)
        if not seen and icon.xCoord and icon.yCoord then
            local ddx, ddy = icon.xCoord - px, icon.yCoord - py
            local d = math.sqrt(ddx * ddx + ddy * ddy)
            if d <= reach and d < bd then best, bd = icon, d end
        end
    end
    if best then
        local ok = pcall(function() best:spotIcon() end)
        S.say(string.format("forage: seen %s at %.1f squares (%s)", tostring(best.itemType), bd, ok and "ok" or "failed"))
    elseif mgr.currentZone then
        pcall(function() mgr:doMoveIconNearPlayer() end)
    end
    return S.v.FQ.tries >= 40
end, function() end)
S.step(2, function()
    if not (S.v.fOk and S.v.FQ.mgr) then return end
    local q = S.v.FQ.queue()
    if #q > 0 then S.say("forage: " .. #q .. " finds in the list from the search"); return end
    local SM = getScriptManager()
    local picks = { { "Base.TinCanEmpty", 3, "UI_ZeD_Forage_CompassNE" }, { "Base.PopEmpty", 5, "UI_ZeD_Forage_CompassE" },
                    { "Base.Newspaper", 6, "UI_ZeD_Forage_CompassS" }, { "Base.ScrapMetal", 8, "UI_ZeD_Forage_CompassW" } }
    for _, k in ipairs(picks) do
        local si = nil
        pcall(function() si = SM:FindItem(k[1]) end)
        if si then table.insert(q, 1, { dist = k[2], bearing = k[3], name = si:getDisplayName(), weight = si:getActualWeight() or 0.1 }) end
    end
    ZeD.ForagingTab._findQueues[S.v.pn] = q
    S.say("forage: finds staged (" .. #q .. "): the search gave none in time")
end)
S.step(30, function() end)
C2.ready(S)
S.step(5, function()
    if not S.v.fOk then S.notTaken("zed_51_forage", "no Foraging tab or no street spot"); return end
    local names = {}
    for i, e in ipairs(S.v.FQ.queue()) do if i <= 8 then names[#names + 1] = tostring(e.name) end end
    S.say("forage: searching " .. tostring(S.v.FQ.mgr and S.v.FQ.mgr.isSearchMode) .. " | finds: " .. table.concat(names, ", "))
    C2.shot(S, "zed_51_forage")
end)
S.step(2, function()
    if not S.v.fWas then return end
    local mgr, w = S.v.FQ.mgr, C2.ww()
    if mgr and mgr.isSearchMode and not S.v.fWas.search then pcall(function() mgr:toggleSearchMode(false) end) end
    ZeD.ForagingTab._findQueues[S.v.pn] = S.v.fWas.finds
    if w then w._moreDetailOpen = S.v.fWas.more end
    S.say("forage put back: search mode " .. tostring(mgr and mgr.isSearchMode) .. ", the finds list as it was")
end)

-- ===================================================================== 48 Furniture (gallery_nov1_lot.lua's furniture)
S.v.FU = { families = { { "furniture_seating_outdoor_01_", 0, 23 }, { "furniture_seating_indoor_01_", 0, 15 },
                        { "furniture_seating_indoor_02_", 0, 15 }, { "furniture_tables_low_01_", 0, 15 },
                        { "trashcontainers_01_", 0, 23 }, { "furniture_storage_02_", 16, 23 } } }
function S.v.FU.screenOf(x, y)
    local sx, sy = -1, -1
    pcall(function() sx = isoToScreenX(S.v.pn, x + 0.5, y + 0.5, 0); sy = isoToScreenY(S.v.pn, x + 0.5, y + 0.5, 0) end)
    return math.floor(sx), math.floor(sy)
end
function S.v.FU.inWin(win, x, y, m)
    if not (win and win:isVisible()) then return false end
    local ax, ay = win:getAbsoluteX(), win:getAbsoluteY()
    return x >= ax - m and x < ax + win:getWidth() + m and y >= ay - m and y < ay + win:getHeight() + m
end
-- a free outdoor square near the character, its middle on the screen clear of both windows and of the character
function S.v.FU.find()
    local cx, cy = math.floor(S.v.p:getX()), math.floor(S.v.p:getY())
    local sw, sh = C2.core:getScreenWidth(), C2.core:getScreenHeight()
    local m = ZeD.T.px(40)
    local r0 = C2.charRect()
    for r = 2, 12 do
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local x, y = cx + dx, cy + dy
                    local sx, sy = S.v.FU.screenOf(x, y)
                    local onChar = sx > r0.x0 - m and sx < r0.x1 + m and sy > r0.y0 and sy < r0.y1 + m
                    if sx > m and sy > m * 2 and sx < sw - m and sy < sh - m * 3 and not onChar
                            and not S.v.FU.inWin(C2.cw(), sx, sy, m) and not S.v.FU.inWin(C2.ww(), sx, sy, m) then
                        local sq = C2.sq(x, y, 0)
                        local free = false
                        pcall(function() free = sq ~= nil and sq:isOutside() and C2.free(sq) end)
                        if free and sq:getObjects():size() <= 2 then return sq, sx, sy end
                    end
                end
            end
        end
    end
    return nil
end
function S.v.FU.props(spr)
    local mp = nil
    pcall(function() mp = ISMoveableSpriteProps.new(spr) end)
    if not (mp and mp.isMoveable) then return nil end
    local nm = nil
    pcall(function() nm = mp.name or (spr:getProperties():has("CustomName") and spr:getProperties():get("CustomName")) end)
    return mp, nm
end
function S.v.FU.onSquare(sq)
    local objs = sq and sq:getObjects()
    for i = 0, (objs and objs:size() or 0) - 1 do
        local o = objs:get(i)
        local spr = o and o:getSprite()
        if spr and o ~= sq:getFloor() then
            local mp, nm = S.v.FU.props(spr)
            if mp then return o, spr:getName(), nm end
        end
    end
    return nil
end
function S.v.FU.movableSprite()
    local fallback = nil
    for _, f in ipairs(S.v.FU.families) do
        for i = f[2], f[3] do
            local name = f[1] .. i
            local spr = getSprite(name)
            if spr then
                local mp, nm = S.v.FU.props(spr)
                local high = false
                pcall(function() high = spr:getProperties():has("IsHigh") end)
                if mp and nm and not high then return name, nm end
                if mp and not fallback then fallback = name end
            end
        end
    end
    return fallback, nil
end
function S.v.FU.capName()
    local FT = ZeD.FurnitureTab
    local c = FT and FT.cap and FT.cap[0]
    local mp = c and c.mp
    local nm = nil
    pcall(function() nm = mp and (mp.name or mp.customName or mp.spriteName) end)
    return nm, c
end
-- a real pointer rest (the engine's UI tick runs every 100 ms): walk onto (x, y) in 2 px steps for half of ms, then hold
function S.v.restOn(getXY, ms)
    local R = {}
    S.waitFor(1, math.floor(ms / 3) + 900, function()
        local now = getTimestampMs()
        if not R.t0 then R.t0, R.n = now, 0 end
        local x, y = getXY()
        if not x then return true end
        R.n = R.n + 1
        if now - R.t0 < ms / 2 then
            if R.n % 4 == 0 then C2.pointAt(x + ((((R.n / 4) % 2) == 0) and 2 or 0), y) end
        else
            C2.pointAt(x, y)
        end
        return now - R.t0 >= ms
    end, function() end)
end
S.waitFor(2, 120, function() return not S.v.spot or C2.worldTab("furniture") end, function(ok) S.v.uOk = ok and S.v.spot ~= nil and ZeD.FurnitureTab ~= nil end)
S.step(30, function()
    if not S.v.uOk then return end
    C2.sides(S)
    S.v.FU.sq, S.v.FU.sx, S.v.FU.sy = S.v.FU.find()
    if not S.v.FU.sq then S.v.uOk = false; S.v.uWhy = "no clear square on the screen for the piece" end
end)
S.step(2, function() if S.v.uOk then C2.pointerOn() end end)
S.v.restOn(function() if S.v.uOk and S.v.FU.sx then return S.v.FU.sx, S.v.FU.sy end return nil end, 600)
S.step(20, function()
    if not S.v.uOk then return end
    local FU = S.v.FU
    local FT = ZeD.FurnitureTab
    local c = FT and FT.cap and FT.cap[0]
    if c and c.sq then
        S.say(string.format("furniture: the pointer's square %d,%d (isoToScreen named %d,%d)", c.sq:getX(), c.sq:getY(), FU.sq:getX(), FU.sq:getY()))
        FU.sq = c.sq
    else
        S.say("furniture: the tab read no square under the pointer; using the named one")
    end
    local o, sname, nm = FU.onSquare(FU.sq)
    if o then S.say(string.format("furniture: a movable piece is already there: %s (%s)", tostring(sname), tostring(nm))); return end
    local name, nm2 = FU.movableSprite()
    if not name then S.v.uOk = false; S.v.uWhy = "no movable furniture sprite found (IsMoveAble)"; return end
    local ok, e = pcall(function()
        local obj = IsoObject.new(getCell(), FU.sq, name)
        FU.sq:AddTileObject(obj)
        FU.obj, FU.sprite = obj, name
    end)
    if not FU.obj then S.v.uOk = false; S.v.uWhy = "the piece could not be placed: " .. tostring(e); return end
    S.say(string.format("furniture: %s (%s) placed at %d,%d", FU.sprite, tostring(nm2), FU.sq:getX(), FU.sq:getY()))
    local cur = FT and FT.cursorOf and FT.cursorOf(0)
    if cur then cur.objectListCache = nil end
end)
S.v.restOn(function() if S.v.uOk and S.v.FU.sx then return S.v.FU.sx + ZeD.T.px(60), S.v.FU.sy + ZeD.T.px(30) end return nil end, 500)
S.v.restOn(function() if S.v.uOk and S.v.FU.sx then return S.v.FU.sx, S.v.FU.sy end return nil end, 900)
S.waitFor(2, 300, function() if not S.v.uOk then return true end return S.v.FU.capName() ~= nil end, function() end)
S.step(20, function()
    if not S.v.uOk then S.notTaken("zed_52_furniture", S.v.uWhy or "no Furniture tab or no street spot"); C2.pointerOff(); return end
    local nm, c = S.v.FU.capName()
    S.say(string.format("furniture: the tab reads %s at %s", tostring(nm), tostring(c and c.sq and (c.sq:getX() .. "," .. c.sq:getY()))))
    if not nm then S.notTaken("zed_52_furniture", "the tab read no piece under the pointer"); C2.pointerOff(); return end
    -- (the pointer stays where it rests: C2.shot with pointer = true does not park it)
    C2.shot(S, "zed_52_furniture", { pointer = true })
end)
S.step(2, function()
    C2.pointerOff()
    if S.v.FU.obj then
        pcall(function() S.v.FU.sq:transmitRemoveItemFromSquare(S.v.FU.obj) end)
        S.say("furniture put back: the piece removed")
    end
    S.v.FU.obj = nil
    C2.worldTab("loot")
end)

-- ===================================================================== 53 Dashboards: the taxi (zedqa_dash_r6_parts.lua)
S.v.D = ZeD.Dashboard
function S.v.dash() return S.v.D and S.v.D.getInstance() end
function S.v.st() local d = S.v.dash(); return d and d._st end
function S.v.click(id)
    local d = S.v.dash(); if not d then return false end
    for _, hr in ipairs(d._hit or {}) do
        if hr.id == id then return d:onMouseDown(hr.x + math.floor(hr.w / 2), hr.y + math.floor(hr.h / 2)) and true or false end
    end
    return false
end
S.step(10, function()
    if not S.v.spot then return end
    C2.charTab("loot"); C2.worldTab("loot")
    local f = C2.footprintsNear({ S.v.spot }, 4)
    S.v.taxiFp = f[1]
    if S.v.taxiFp then S.say(string.format("taxi spot %d,%d (%d of 5 paved)", S.v.taxiFp[1], S.v.taxiFp[2], S.v.taxiFp.paved))
    else S.say("ERR no clear paved footprint for the taxi near the street spot") end
end)
S.step(2, function()
    -- the spawn (C2.carSpawn's steps, inline: the footprint is known only at run time)
    S.v.tWhy = nil
    if not (S.v.taxiFp and ZEDQA_CAR_READY and ZEDQA_CAR_ENTER) then S.v.tWhy = S.v.taxiFp and "no ZEDQA_CAR_* (run zedqa_prelude.lua first)" or "no spot for the taxi"; return end
    C2.tp(S.v.taxiFp[1] + 2.5, S.v.taxiFp[2] + 0.5, 0); C2.face("W")
end)
S.step(60, function()
    if S.v.tWhy then return end
    local ok, v = pcall(addVehicleDebug, "Base.CarTaxi", IsoDirections.N, nil, C2.sq(S.v.taxiFp[1], S.v.taxiFp[2], 0))
    if ok and v then S.v.taxi = v; S.say(string.format("taxi spawned at %d,%d", S.v.taxiFp[1], S.v.taxiFp[2])) else S.v.tWhy = "addVehicleDebug gave no taxi" end
end)
S.waitFor(5, 600, function() if S.v.tWhy then return true end local r = false; pcall(function() r = ZEDQA_CAR_READY(S.v.taxi) end); return r end, function(ok)
    if not S.v.tWhy and not ok then S.v.tWhy = "the taxi never got ready" end
end)
S.step(10, function()
    if S.v.tWhy then return end
    local v = S.v.taxi
    pcall(function() v:repair() end)
    pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
    pcall(function()
        local b = v:getPartById("Battery"); local it = b and b:getInventoryItem()
        if it then pcall(function() it:setCurrentUsesFloat(1.0) end); pcall(function() it:setUsedDelta(1.0) end) end
    end)
end)
S.waitMs(1500)
S.step(5, function()
    if S.v.tWhy then return end
    local v = S.v.taxi
    pcall(function() if v:isKeysInIgnition() then v:setKeysInIgnition(false) end end)
    pcall(function() S.v.taxiKey = S.v.p:getInventory():AddItem(v:createVehicleKey()) end)
    local ok, why = ZEDQA_CAR_ENTER(v, 0)
    if not ok then S.v.tWhy = "not entered: " .. tostring(why) end
end)
S.step(30, function() if not S.v.tWhy then pcall(function() if S.v.taxi:isKeysInIgnition() then S.v.taxi:setKeysInIgnition(false) end end) end end)
S.step(20, function() if not S.v.tWhy then S.v.click("ignition"); S.v.eng = { t0 = getTimestampMs(), tries = 0 } end end)
S.waitFor(5, 1500, function()
    if S.v.tWhy then return true end
    local s = S.v.st()
    if s and s.running then return true end
    if s and s.keyPos == "acc" and not s.cranking and getTimestampMs() - S.v.eng.t0 > 1500 then
        S.v.eng.tries = S.v.eng.tries + 1
        if S.v.eng.tries >= 5 then return true end
        S.v.eng.t0 = getTimestampMs(); S.v.click("ignition")
    end
    return false
end, function()
    local s = S.v.st()
    if not S.v.tWhy and not (s and s.running) then S.say("note: the taxi's engine never ran") end
end)
S.step(5, function() if not S.v.tWhy then local s = S.v.st(); if s and not s.lights then S.v.click("lights") end end end)
S.step(50, function()
    if S.v.tWhy then return end
    if not S.v.click("meter") then S.say("ERR the meter click was not taken") end
end)
S.step(20, function()
    if S.v.tWhy then return end
    S.v.ridersWas = S.v.D.qaRiders
    S.v.D.qaRiders = 3
end)
S.step(15, function() if not S.v.tWhy then C2.sides(S) end end)
S.step(15, function()
    if S.v.tWhy then S.notTaken("zqa_r6p_taxi_extras", S.v.tWhy); return end
    local s = S.v.st() or {}
    S.say(string.format("taxi: running %s, lights %s, meter %s, fare %s, extras %s", tostring(s.running), tostring(s.lights), tostring(s.meterOn),
        tostring(s.fare), tostring(s.fareExtra)))
    C2.shot(S, "zqa_r6p_taxi_extras", { extra = { { "dash", S.v.dash() } } })
end)
S.step(5, function()
    if S.v.D then S.v.D.qaRiders = S.v.ridersWas end
    local v = S.v.taxi
    if not v then return end
    pcall(function() if v:isEngineRunning() then v:shutOff() end end)
end)
S.step(30, function()
    if S.v.taxi and ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(S.v.taxi, S.v.taxiKey) end
    S.v.taxi, S.v.taxiKey = nil, nil
end)

-- ===================================================================== put back
S.mark()
S.step(30, function()
    if S.v.D then S.v.D.qaRiders = S.v.ridersWas end
    if S.v.taxi and ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(S.v.taxi, S.v.taxiKey); S.v.taxi = nil end
    C2.pointerOff()
    if S.v.FU.obj then pcall(function() S.v.FU.sq:transmitRemoveItemFromSquare(S.v.FU.obj) end); S.v.FU.obj = nil end
    for _, w in ipairs(S.v.wet or {}) do pcall(function() w.it:setWetness(w.w) end) end
    S.v.wet = {}
    if S.v.fWas then pcall(function() ZeD.ForagingTab._findQueues[S.v.pn] = S.v.fWas.finds end) end
    pcall(S.v.recipe, false)
end)
S.step(20, function() C2.back(S) end)
S.step(30, function() end)
S.start()
