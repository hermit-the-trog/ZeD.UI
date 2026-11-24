-- ZeDUI/tools/qa/hs_tip.lua  (Nov 23 2026, QA; tag hs_tip): the trough and farm plot hover facts in ZeD's balloon, in
-- game. Build's fix/specialtip (main 39159199c: shared/ZeD/ZeD_SpecialTipHook.lua, client/ZeD/ZeD_SpecialTip.lua): the
-- game's own box over a feeding trough and over a planted farm plot (CFeedingTroughSystem.lua's and CFarmingSystem.lua's
-- Events.DoSpecialTooltip handlers, kept back by ZeD's wrap on Events.DoSpecialTooltip.Add) is redrawn by ZeD in its
-- balloon, beside the square on the side away from the character, never over him. The director, Nov 23 2026: "Redraw."
-- Run after zedqa_prelude.lua and rt_kit.lua (hs_tip.txt). grep "ZEDQA hs_tip".
--
-- How the hover is driven: the game's hover comes from its object picker reading the real pointer (Mouse.setXY does
-- not move the read pointer), so this script fires the game's own event instead, the way the game's ObjectTooltip does
-- it every frame it draws (IsoObject.DoSpecialTooltip): a real ObjectTooltip.new(), its height set to 0, then
-- triggerEvent("DoSpecialTooltip", tooltip, square) from a UI panel's render, so every handler runs (ZeD's, the kept
-- game handlers through ZeD in safe mode, any mod's). Where triggerEvent does not reach ZeD's handler the script says
-- so (FAIL) and calls ZeD.SpecialTip.onTip(tooltip, square) straight. Stopping means not firing it any more.
-- Staged at the farm with troughs (zedqa_farm_spot.lua's point, 1635,14221): the character stands 3 tiles from the
-- nearest trough with no feed in it (the farm's troughs are read first, each as found is logged); the trough's water
-- and feed are set with the game's own debug paths (ISFeedingTroughMenu.lua: addWater / removeWater, the fluid
-- container, two animal feed bags in its item container); a plot is plowed and seeded with the game's server farming
-- system (SFarmingSystem:plow, SPlantGlobalObject:seed, as ISPlowAction / ISSeedActionNew complete), aphids 5 on it.
-- Checks:
--   1  at the start ZeD.SpecialTip.captured is 2 (both game handlers kept back), the Add is ZeD's wrapper
--   2  trough: the event reaches ZeD's handler (.muted rises); with water, empty, then with feed: .shown, .kind
--      "trough", .title and .lines are the game's own words for that state (CFeedingTroughSystem.lua's DoSpecialTooltip1
--      reproduced here with getText), the lines change from state to state; with water: .rect off .charRect and off the
--      character measured from the tile's own width, inside the screen, .anchor the trough's square (picture
--      hs_tip_trough_<w>x<h>)
--   3  farm plot: Farming 3: kind "farm", the plant's name, the water level line, the aphid line, no next phase;
--      Farming 6: the next growing phase too; the same balloon checks (picture hs_tip_farm_<w>x<h>)
--   4  gates: a plot at Farming 2 shows nothing; a trough 14+ tiles away shows nothing; nothing while the right button
--      is held (Mouse.isRightDown held true from Lua; SKIP when it cannot be); "nothing" = .muted does not rise, no
--      balloon, the tooltip left with no height (the game hides it, as before)
--   5  the balloon goes within 3 frames after the event stops (trough and plot)
--   6  safe mode (ZeD.Settings.safeModeOption On, ZeD.Safe.reread, rt_system.lua's way): the game's own trough handler
--      runs again and its box measures a height, .muted does not rise, ZeD's balloon is not shown; Off again: ZeD back
--   7  a mod's handler added after load (Events.DoSpecialTooltip.Add of a test function that adds one line) goes past
--      ZeD's wrapper untouched and still runs while ZeD's balloon shows; NOTE whether its line has a background
--      (Build: "they now draw with no background"; picture hs_tip_modline_<w>x<h>); removed, it runs no more
--   no Lua error over the run
-- Puts back: the character's place and facing (the drag strip, exactly), Farming level and XP, the trough's water,
-- fluid container, item container and feed as found, the plot removed and its square's plowDay as found, the test
-- handler removed, Mouse.isRightDown, the kept game handler, the Safe mode option, the time of day (set to 11:00 only
-- if it was night), the window pair as found, the driving panel gone, the pointer the game's. Nothing is given.
if not RT then print("ZEDQA hs_tip ERR rt_kit.lua did not run first"); print("ZEDQA hs_tip DONE"); return end
local Q = RT.make("hs_tip")
Q.maxMs = 780000                     -- (the runner gives this script 900 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, f = {}, back = {}, t0 = getTimestampMs(), fires = 0, f0 = 0, m0 = 0, maxH = 0,
            modCalls = 0, modShown = 0, gameCalls = 0, feedItems = {}, outItems = {}, held = {} }

S.FARM = { x = 1635.5, y = 14221.5, z = 0 }   -- (zedqa_farm_spot.lua's point, by the farm's troughs)
S.FAR = 16                                    -- tiles from the trough for the out-of-reach check (the game's reach: 13)
S.WATER_L = 1.5                               -- liters put in an empty trough
S.SEED = "Carrots"
S.MODLINE = "ZeD QA: a mod's line"
S.PESTS = { { "aphidLvl", "Farming_Aphid" }, { "mildewLvl", "Farming_Mildew" }, { "fliesLvl", "Farming_Pest_Flies" },
            { "slugsLvl", "Farming_Slugs" } }

-- ===================================================================== small helpers
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.r(v) local x = tonumber(v); if x == nil then return "?" end; return tostring(math.floor(x + 0.5)) end
function S.n(v) local x = tonumber(v); if x == nil then return "?" end; return tostring(math.floor(x * 100 + 0.5) / 100) end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.until1(n, max, cond, fn)
    Q.waitFor(n, max, function() return S.dead or cond() end, function(ok) if not S.dead then fn(ok) end end)
end
function S.sq(x, y, z) local s = nil; pcall(function() s = getCell():getGridSquare(x, y, z) end); return s end
function S.sqText(sq) if not sq then return "none" end; return sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ() end
function S.rt(r) if not r then return "none" end; return S.r(r.x) .. "," .. S.r(r.y) .. "," .. S.r(r.w) .. "," .. S.r(r.h) end
function S.over(a, b)
    if not (a and b) then return false end
    return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end
function S.onScreen(r)
    local w, h = S.screen()
    return r ~= nil and r.x >= 0 and r.y >= 0 and r.x + r.w <= w + 0.5 and r.y + r.h <= h + 0.5
end
function S.same(a, b)
    if type(a) ~= "table" or type(b) ~= "table" or #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end
function S.copy(t) local o = {}; for i, v in ipairs(t or {}) do o[i] = v end; return o end
function S.join(t) if type(t) ~= "table" then return tostring(t) end; return "[" .. table.concat(t, " / ") .. "]" end
function S.has(t, s) for _, l in ipairs(t or {}) do if l == s then return true end end; return false end
function S.hasPre(t, s)
    for _, l in ipairs(t or {}) do if type(l) == "string" and string.sub(l, 1, #s) == s then return true end end
    return false
end
function S.on() return S.fireSq ~= nil end

-- ===================================================================== the character
function S.standAt(x, y, z)
    pcall(function() S.p:setX(x); S.p:setY(y); S.p:setZ(z); S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z) end)
end
function S.dir() local d = nil; pcall(function() d = S.p:getDir() end); return d end
function S.ang() local a = nil; pcall(function() a = S.p:getDirectionAngle() end); return a end
-- the character on the screen measured here: a tile's width from the game's own iso math (0.8 of it wide), from his
-- feet to 0.75 of a floor up (Build's head height), with Build's room of a tenth of a tile
function S.myChar()
    local r = nil
    pcall(function()
        local x, y, z = S.p:getX(), S.p:getY(), S.p:getZ()
        local fx, fy = isoToScreenX(S.pn, x, y, z), isoToScreenY(S.pn, x, y, z)
        local tw = 2 * math.abs(isoToScreenX(S.pn, x + 1, y, z) - fx)
        local hy = isoToScreenY(S.pn, x, y, z + 0.75)
        S.tileW = tw
        r = { x = fx - tw * 0.4, y = hy - tw * 0.1, w = tw * 0.8, h = (fy - hy) + tw * 0.2 }
    end)
    return r
end

-- ===================================================================== Farming
function S.farmLv() local v = nil; pcall(function() v = S.p:getPerkLevel(Perks.Farming) end); return v end
function S.farmXp() local v = nil; pcall(function() v = S.p:getXp():getXP(Perks.Farming) end); return v end
function S.setFarm(n)
    pcall(function() S.p:setPerkLevelDebug(Perks.Farming, n) end)
    pcall(function() S.p:getXp():setXPToLevel(Perks.Farming, n) end)
    return S.farmLv() == n
end
function S.putFarm()
    local f = S.f
    if f.farmLv == nil then return end
    pcall(function() S.p:setPerkLevelDebug(Perks.Farming, f.farmLv) end)
    pcall(function() S.p:getXp():setXPToLevel(Perks.Farming, f.farmLv) end)
    local x = S.farmXp()
    if x and f.farmXp and f.farmXp > x + 0.001 then
        pcall(function() S.p:getXp():AddXPNoMultiplier(Perks.Farming, f.farmXp - x) end)
    end
end

-- ===================================================================== the trough
function S.tsys() return CFeedingTroughSystem and CFeedingTroughSystem.instance or nil end
function S.tLo(sq)
    local sys, lo = S.tsys(), nil
    if sys and sq then pcall(function() lo = sys:getLuaObjectOnSquare(sq) end) end
    return lo
end
-- the trough the game's handler reads for a hovered square (a linked half reads its partner): its steps
function S.resolve(sq)
    local lo = S.tLo(sq)
    if not lo then return nil end
    if lo.linkedX and lo.linkedY and lo.linkedX > 0 and lo.linkedY > 0 then
        local sq2 = getSquare(lo.linkedX, lo.linkedY, sq:getZ())
        if sq2 then lo = S.tLo(sq2) end
    end
    if not lo then return nil end
    local t = nil
    pcall(function() t = lo:getIsoObject() end)
    return t
end
function S.ctn(t) local c = nil; if t then pcall(function() c = t:getContainer() end) end; return c end
function S.items(c)
    local out = {}
    if not c then return out end
    pcall(function()
        local list = c:getItems()
        for i = 0, list:size() - 1 do out[#out + 1] = list:get(i) end
    end)
    return out
end
function S.tRead(t)
    local s = { water = 0, feed = 0, max = 0, fc = false, ctn = false, items = 0 }
    if not t then return s end
    pcall(function() s.water = t:getWater() end)
    pcall(function() s.feed = t:getCurrentFeedAmount() end)
    pcall(function() s.max = t:getMaxWater() end)
    pcall(function() s.fc = t:getFluidContainer() ~= nil end)
    local c = S.ctn(t)
    s.ctn = c ~= nil
    s.items = #S.items(c)
    return s
end
function S.tText(s)
    return "water " .. S.n(s.water) .. " of " .. S.n(s.max) .. " L, feed " .. S.n(s.feed) .. ", fluid container "
        .. tostring(s.fc) .. ", item container " .. tostring(s.ctn) .. " (" .. tostring(s.items) .. " items)"
end
function S.fluidType(t)
    local ft = nil
    pcall(function()
        local fc = t:getFluidContainer()
        if fc then
            local fl = fc:getPrimaryFluid()
            if fl then ft = fl:getFluidType() end
        end
    end)
    return ft
end
-- the game's own words for a hovered trough: CFeedingTroughSystem.lua's DoSpecialTooltip1, its title and its labels in
-- order (the water line only with no feed, the feed line only with no water, then the three how-to lines)
function S.gameTrough(sq)
    local t = S.resolve(sq)
    if not t then return nil end
    local pl = getPlayer()
    if pl and pl:DistToProper(t) > 13 then return nil end
    local feedAmount = t:getCurrentFeedAmount()
    local waterAmount = t:getWater()
    local lines = {}
    local text = getText("Fluid_Empty")
    if waterAmount > 0 then
        text = round(t:getWater(), 2) * 1000 .. " / " .. t:getMaxWater() * 1000 .. getText("IGUI_Milliliter")
    end
    if feedAmount <= 0 then lines[#lines + 1] = getText("IGUI_FeedingTroughUI_Water") .. ": " .. text end
    text = getText("Fluid_Empty")
    if feedAmount > 0 then text = round(feedAmount, 2) end
    if waterAmount <= 0 then lines[#lines + 1] = getText("IGUI_FeedingTroughUI_Feeding") .. ": " .. text end
    lines[#lines + 1] = getText("Tooltip_trough_info1")
    lines[#lines + 1] = getText("Tooltip_trough_info2")
    lines[#lines + 1] = getText("Tooltip_trough_info3")
    return { title = getText("ContextMenu_FeedingTrough"), lines = lines }
end
function S.settle(t)
    pcall(function() t:checkContainer() end)
    pcall(function() t:checkOverlayAfterAnimalEat() end)
end
-- the feed out of the trough: this script's own is dropped, what was there is kept for the put-back
function S.feedOut(t)
    local c = S.ctn(t)
    for _, it in ipairs(S.items(c)) do
        local mine = false
        for _, m in ipairs(S.feedItems) do if m == it then mine = true end end
        pcall(function() c:Remove(it) end)
        if not mine then S.outItems[#S.outItems + 1] = it end
    end
    S.feedItems = {}
end
function S.dropWater(t)
    local w = 0
    pcall(function() w = t:getWater() end)
    if w > 0 then pcall(function() t:removeWater(w + 1) end) end
end
function S.needFC(t)
    local fc = nil
    pcall(function() fc = t:getFluidContainer() end)
    if not fc then pcall(function() t:createFluidContainer() end) end
end
function S.stageWater(t)
    S.feedOut(t)
    S.needFC(t)
    local w = 0
    pcall(function() w = t:getWater() end)
    if w <= 0 then pcall(function() t:addWater(FluidType.Water, S.WATER_L) end) end
    S.settle(t)
end
function S.stageEmpty(t)
    S.feedOut(t)
    S.needFC(t)
    S.dropWater(t)
    S.settle(t)
end
-- feed as the game's debug "Add Food" puts it (ISFeedingTroughMenu.onAddFoodDebug): no fluid container, two bags
function S.stageFeed(t)
    S.dropWater(t)
    pcall(function() t:removeFluidContainer() end)
    if not S.ctn(t) then pcall(function() t:setContainer(ItemContainer.new()) end) end
    local c = S.ctn(t)
    if not c then return false end
    local before = S.items(c)
    pcall(function() c:addItems(ItemKey.Drainable.ANIMAL_FEED_BAG, 2) end)
    for _, it in ipairs(S.items(c)) do
        local old = false
        for _, b in ipairs(before) do if b == it then old = true end end
        if not old then S.feedItems[#S.feedItems + 1] = it end
    end
    S.settle(t)
    return #S.feedItems > 0
end
-- the trough as found: this script's feed out, the feed that was there back in, the fluid container and its water
-- (the found fluid) as found, an item container this script made taken off again when empty
function S.troughBack()
    local t, f = S.T, S.f.tr
    if not (t and f) then return end
    local c = S.ctn(t)
    for _, it in ipairs(S.feedItems) do if c then pcall(function() c:Remove(it) end) end end
    S.feedItems = {}
    if #S.outItems > 0 then
        if not c then pcall(function() t:setContainer(ItemContainer.new()) end); c = S.ctn(t) end
        for _, it in ipairs(S.outItems) do if c then pcall(function() c:AddItem(it) end) end end
        S.outItems = {}
    end
    local fc = nil
    pcall(function() fc = t:getFluidContainer() end)
    if f.fc then
        if not fc then pcall(function() t:createFluidContainer() end) end
        local w = 0
        pcall(function() w = t:getWater() end)
        if math.abs(w - f.water) > 0.001 then
            S.dropWater(t)
            if f.water > 0 then pcall(function() t:addWater(S.f.trType or FluidType.Water, f.water) end) end
        end
    elseif fc then
        S.dropWater(t)
        pcall(function() t:removeFluidContainer() end)
    end
    c = S.ctn(t)
    if c and not f.ctn and #S.items(c) == 0 then pcall(function() t:setContainer(nil) end) end
    S.settle(t)
end
-- an open square: loaded, free, no tree, a floor, no trough; outdoors unless inOk
function S.openSq(x, y, z, inOk)
    local s = S.sq(x, y, z)
    if not s then return nil end
    local ok = false
    pcall(function() ok = s:isFree(false) and (inOk or s:getRoom() == nil) and not s:HasTree() and s:getFloor() ~= nil end)
    if not ok or S.tLo(s) then return nil end
    return s
end
-- the first open square r tiles round cx, cy (the eight straight and diagonal ones first), not refused by avoid
function S.ringSq(cx, cy, z, r, avoid, inOk)
    local dirs = { { 0, 1 }, { 1, 0 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { 0, -1 }, { -1, 0 }, { -1, -1 } }
    for _, d in ipairs(dirs) do
        local s = S.openSq(cx + d[1] * r, cy + d[2] * r, z, inOk)
        if s and not (avoid and avoid(s)) then return s end
    end
    for dx = -r, r do
        for dy = -r, r do
            if math.max(math.abs(dx), math.abs(dy)) == r then
                local s = S.openSq(cx + dx, cy + dy, z, inOk)
                if s and not (avoid and avoid(s)) then return s end
            end
        end
    end
    return nil
end
-- the farm's troughs (the game's client trough system), each square the game reads a trough for
function S.findTroughs()
    local sys, out = S.tsys(), {}
    if not sys then return out end
    local n = 0
    pcall(function() n = sys:getLuaObjectCount() or 0 end)
    if type(n) ~= "number" then n = 0 end
    for i = 1, n do
        local lo = nil
        pcall(function() lo = sys:getLuaObjectByIndex(i) end)
        if lo and lo.x and lo.y and math.abs(lo.x - S.FARM.x) <= 40 and math.abs(lo.y - S.FARM.y) <= 40 then
            local sq = S.sq(lo.x, lo.y, lo.z or 0)
            local t = S.resolve(sq)
            if t then out[#out + 1] = { sq = sq, t = t, s = S.tRead(t) } end
        end
    end
    if #out == 0 then
        local fx, fy = math.floor(S.FARM.x), math.floor(S.FARM.y)
        for x = fx - 30, fx + 30 do
            for y = fy - 30, fy + 30 do
                local sq = S.sq(x, y, 0)
                local t = sq and S.tLo(sq) and S.resolve(sq) or nil
                if t then out[#out + 1] = { sq = sq, t = t, s = S.tRead(t) } end
            end
        end
    end
    return out
end
function S.pickTrough()
    local list = S.findTroughs()
    Q.say("troughs read near the farm: " .. #list)
    for i, c in ipairs(list) do
        if i <= 12 then Q.say("  trough at " .. S.sqText(c.sq) .. ": " .. S.tText(c.s)) end
    end
    if #list == 0 then S.noTrough = "no feeding trough the game reads within 40 tiles of the farm point"; return end
    local function key(c)
        local dx, dy = c.sq:getX() - S.FARM.x, c.sq:getY() - S.FARM.y
        local fed = (c.s.feed > 0 or c.s.items > 0) and 100000 or 0
        return fed + dx * dx + dy * dy
    end
    table.sort(list, function(a, b) return key(a) < key(b) end)
    for pass = 1, 2 do
        for _, c in ipairs(list) do
            local x, y, z = c.sq:getX(), c.sq:getY(), c.sq:getZ()
            local st = S.ringSq(x, y, z, 3, nil, pass == 2) or S.ringSq(x, y, z, 2, nil, pass == 2) or S.ringSq(x, y, z, 4, nil, pass == 2)
            if st then
                S.T, S.tSq, S.stand = c.t, c.sq, st
                S.f.tr = c.s
                S.f.trType = S.fluidType(c.t)
                Q.say("the trough: " .. S.sqText(c.sq) .. " (as found: " .. S.tText(c.s) .. ", fluid " .. tostring(S.f.trType)
                    .. "); the character stands at " .. S.sqText(st))
                return
            end
        end
    end
    S.noTrough = "no open square 2 to 4 tiles from any of the farm's troughs"
end

-- ===================================================================== the farm plot
function S.fsys() return CFarmingSystem and CFarmingSystem.instance or nil end
function S.ssys() return SFarmingSystem and SFarmingSystem.instance or nil end
function S.cPlant(sq)
    local sys, pl = S.fsys(), nil
    if sys and sq then pcall(function() pl = sys:getLuaObjectOnSquare(sq) end) end
    return pl
end
function S.sPlant(sq)
    local sys, pl = S.ssys(), nil
    if sys and sq then pcall(function() pl = sys:getLuaObjectOnSquare(sq) end) end
    return pl
end
function S.plotOk(s)
    if s == S.stand or S.cPlant(s) or S.sPlant(s) then return false end
    if S.tSq and math.abs(s:getX() - S.tSq:getX()) <= 1 and math.abs(s:getY() - S.tSq:getY()) <= 1 then return false end
    local n = 1
    pcall(function() n = s:getSpecialObjects():size() end)
    return n == 0
end
-- a plot as the game makes one (ISPlowAction / ISSeedActionNew complete, without the grass taken off), aphids 5
function S.plant(sq)
    local ss = S.ssys()
    if not ss then return false, "no SFarmingSystem in this game (the server's farming runs elsewhere)" end
    local md = nil
    pcall(function() md = sq:getModData() end)
    S.f.plowDay = md and md.plowDay or nil
    S.f.plowRead = md ~= nil
    S.plotSq = sq
    local ok, e = pcall(function() ss:plow(sq) end)
    S.planted = true
    if not ok then return false, "plow: " .. tostring(e) end
    local sp = S.sPlant(sq)
    if not sp then return false, "no plant on the square after plowing" end
    local props = farming_vegetableconf and farming_vegetableconf.props or {}
    local seed = props[S.SEED] and S.SEED or nil
    if not seed then for k, _ in pairs(props) do if not seed then seed = k end end end
    if not seed then return false, "no seed kind in farming_vegetableconf.props" end
    ok, e = pcall(function() sp:seed(seed, 3) end)
    if not ok then return false, "seed: " .. tostring(e) end
    pcall(function() sp.aphidLvl = 5; sp:saveData() end)
    return true, seed
end
function S.unplant()
    if not S.planted then return end
    S.planted = nil
    local sq, ss = S.plotSq, S.ssys()
    local sp = S.sPlant(sq)
    if ss and sp then pcall(function() ss:removePlant(sp) end) end
    if S.f.plowRead then
        local md = nil
        pcall(function() md = sq:getModData() end)
        if md then md.plowDay = S.f.plowDay end
    end
end
-- the game's own words for the plot (CFarmingSystem.lua's DoSpecialTooltip1, no cheat), as ZeD's lines read them:
-- "label: value"
function S.gameFarm(sq, lv)
    local plant = S.cPlant(sq)
    if not plant or plant.typeOfSeed == "none" then return nil end
    local g = { title = farming_vegetableconf.getObjectName(plant), pests = {},
                water = getText("Farming_Water_levels") .. ": " .. tostring(ISFarmingInfo.getWaterLvl(plant, lv)),
                phase = getText("Farming_Next_growing_phase") .. ": " }
    for _, k in ipairs(S.PESTS) do
        local v = plant[k[1]] or 0
        if v > 0 then g.pests[#g.pests + 1] = getText(k[2]) .. ": " .. tostring(ISFarmingInfo.getDiseaseString(v, lv)) end
    end
    return g
end
function S.farmCheck(lab, lv, ok)
    local ST = S.ST
    local L = ST.lines or {}
    Q.check(ok and S.farmLv() == lv and ST.kind == "farm", lab .. ": the balloon shows the plot (kind farm)",
        "Farming " .. tostring(S.farmLv()) .. ", shown " .. tostring(ST.shown) .. ", kind " .. tostring(ST.kind))
    local g = S.gameFarm(S.plotSq, lv)
    if not g then Q.check(false, lab .. ": the game's facts for the plot can be read", "no planted plot"); return end
    Q.check(ST.title == g.title, lab .. ": the title is the plant's name, the game's word", tostring(ST.title) .. " | the game's " .. tostring(g.title))
    Q.check(S.has(L, g.water), lab .. ": the water level line in the game's words", "want " .. g.water .. " | " .. S.join(L))
    if lv >= 6 then
        Q.check(S.hasPre(L, g.phase), lab .. ": the next growing phase from Farming 6", S.join(L))
    else
        Q.check(not S.hasPre(L, g.phase), lab .. ": no next growing phase below Farming 6", S.join(L))
    end
    if #g.pests > 0 then
        local miss = {}
        for _, s in ipairs(g.pests) do if not S.has(L, s) then miss[#miss + 1] = s end end
        Q.check(#miss == 0, lab .. ": the pest lines the game shows from Farming 3",
            #miss == 0 and S.join(g.pests) or ("missing " .. S.join(miss) .. " | " .. S.join(L)))
    else
        Q.skip(lab .. ": the pest lines", "the plot has no pest (aphids 5 on the game's server object did not reach it)")
    end
    if not S.f.cheat then
        local want = 1 + ((lv >= 6) and 1 or 0) + #g.pests
        Q.check(#L == want, lab .. ": no line the game would not show", #L .. " lines, the game's " .. want .. ": " .. S.join(L))
    end
    S.linesFarm = S.copy(L)
end

-- ===================================================================== firing the game's event
function S.makeDriver()
    if S.drv then return true end
    if not (ISPanel and ObjectTooltip) then return false end
    local tip = nil
    pcall(function() tip = ObjectTooltip.new() end)
    if not tip then return false end
    S.tip = tip
    local d = ISPanel:new(0, 0, 1, 1)
    d.background = false
    d.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    d.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    d:initialise()
    d:instantiate()
    pcall(function() d.javaObject:setConsumeMouseEvents(false) end)
    d.prerender = function() end
    d.render = function()
        if not S.fireSq then return end
        local ok, e = pcall(S.fireOnce)
        if not ok and not S.fireErr then S.fireErr = tostring(e) end
    end
    d:addToUIManager()
    S.drv = d
    return true
end
-- one frame of the game's ObjectTooltip on the square: height 0, the event, its height read (the game hides it at 0)
function S.fireOnce()
    local sq, tip = S.fireSq, S.tip
    local x = isoToScreenX(S.pn, sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ())
    local y = isoToScreenY(S.pn, sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ())
    tip:setX(x + 16)
    tip:setY(y + 16)
    tip:setHeight(0)
    S.fires = S.fires + 1
    if S.useTrigger then
        local ok, e = pcall(triggerEvent, "DoSpecialTooltip", tip, sq)
        if not ok then S.trigErr = tostring(e); S.useTrigger = false end
    end
    if not S.useTrigger then S.ST.onTip(tip, sq) end
    local h = tip:getHeight()
    if h > S.maxH then S.maxH = h end
end
function S.fireOn(sq)
    S.fireSq = sq
    S.maxH = 0
    S.f0 = S.fires
    S.m0 = S.ST.muted or 0
end
function S.fireOff() S.fireSq = nil end
function S.fired() return S.fires - S.f0 end
function S.nothing(lab)
    local ST = S.ST
    return Q.check(S.fired() > 0 and (ST.muted or 0) == S.m0 and S.maxH == 0 and not ST.shown, lab,
        "fired " .. S.fired() .. ", .muted +" .. ((ST.muted or 0) - S.m0) .. ", the tooltip's height " .. S.n(S.maxH)
        .. ", shown " .. tostring(ST.shown) .. (S.fireErr and (", fire error " .. S.fireErr) or ""))
end
-- the kept game trough handler, counted (ZeD calls it in safe mode)
function S.wrapGame()
    if S.gOrig then return end
    S.gOrig = S.ST.gameTrough
    local orig = S.gOrig
    S.ST.gameTrough = function(tooltip, square) S.gameCalls = S.gameCalls + 1; return orig(tooltip, square) end
end
function S.unwrapGame() if S.gOrig then S.ST.gameTrough = S.gOrig; S.gOrig = nil end end
-- a mod's handler, as a mod writes one: one line on the game's tooltip
function S.modFn(tooltip, square)
    S.modCalls = S.modCalls + 1
    if S.ST and S.ST.shown then S.modShown = S.modShown + 1 end
    pcall(function()
        local layout = tooltip:beginLayout()
        local it = layout:addItem()
        it:setLabel(S.MODLINE, 1, 1, 1, 1)
        local y = layout:render(5, 5, tooltip)
        if tooltip:getHeight() < y + 5 then tooltip:setHeight(y + 5) end
        tooltip:endLayout(layout)
    end)
end
function S.modOff()
    if not S.modAdded then return end
    S.modAdded = nil
    pcall(function() Events.DoSpecialTooltip.Remove(S.modFn) end)
end
-- the right button held, from Lua (the game's handler and ZeD's both ask Mouse.isRightDown)
function S.rightHold(on)
    if on then
        if S.rdOrig == nil then
            S.rdOrig = Mouse.isRightDown
            pcall(function() Mouse.isRightDown = function() return true end end)
        end
        local v = false
        pcall(function() v = Mouse.isRightDown() end)
        return v == true
    end
    if S.rdOrig ~= nil then
        pcall(function() Mouse.isRightDown = S.rdOrig end)
        S.rdOrig = nil
    end
end
-- Safe mode by its option (rt_system.lua's way)
function S.safeOn()
    local opt, Sf = ZeD.Settings and ZeD.Settings.safeModeOption, ZeD.Safe
    if not (opt and Sf and Sf.reread and Sf.on) then return false, "no Safe mode option or ZeD.Safe.reread" end
    local okv, v = pcall(function() return opt:getValue() end)
    if not okv or v == nil then return false, "the Safe mode option cannot be read" end
    S.safeWas, S.safeSet = v, true
    pcall(function() opt:setValue(2) end)
    pcall(Sf.reread)
    local on = false
    pcall(function() on = Sf.on() == true end)
    return on, "ZeD.Safe.on() " .. tostring(on)
end
function S.safeOff()
    if not S.safeSet then return end
    S.safeSet = nil
    local opt = ZeD.Settings and ZeD.Settings.safeModeOption
    if opt then pcall(function() opt:setValue(S.safeWas) end) end
    pcall(ZeD.Safe.reread)
end
function S.safeNow() local on = false; pcall(function() on = ZeD.Safe.on() == true end); return on end

-- ===================================================================== the balloon's place
function S.balloonCheck(lab, sq)
    local ST = S.ST
    local r, cr, a = ST.rect, ST.charRect, ST.anchor
    local my = S.myChar()
    Q.check(r ~= nil and cr ~= nil and not S.over(r, cr), lab .. ": the balloon does not cover the character (.rect off .charRect)",
        "rect " .. S.rt(r) .. ", charRect " .. S.rt(cr))
    Q.check(r ~= nil and my ~= nil and not S.over(r, my), lab .. ": the balloon does not cover the character measured from the tile's own width",
        "rect " .. S.rt(r) .. ", measured " .. S.rt(my) .. " (a tile " .. S.r(S.tileW) .. " px wide; .charRect " .. S.r(cr and cr.w) .. " wide)")
    Q.check(S.onScreen(r), lab .. ": the balloon is inside the screen", S.rt(r) .. " on " .. S.sizeTag())
    local h = ST._hover
    local hs = h and h.square or nil
    local cx, cy = -1, -1
    pcall(function()
        cx = isoToScreenX(S.pn, sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ())
        cy = isoToScreenY(S.pn, sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ())
    end)
    local same = hs ~= nil and hs:getX() == sq:getX() and hs:getY() == sq:getY() and hs:getZ() == sq:getZ()
    local aOk = same and a ~= nil and math.abs((a.x + a.w / 2) - cx) <= 2 and cy >= a.y - 1 and cy <= a.y + a.h + 1
    Q.check(aOk, lab .. ": .anchor is the hovered square " .. S.sqText(sq),
        "anchor " .. S.rt(a) .. ", the tile's middle " .. S.r(cx) .. "," .. S.r(cy) .. ", the facts' square " .. S.sqText(hs))
    local pl = ZeD.Balloon and ZeD.Balloon.lastPlace or nil
    local away = "?"
    if a and cr then away = ((a.x + a.w / 2) >= (cr.x + cr.w / 2)) and "right" or "left" end
    Q.say("NOTE " .. lab .. ": the balloon went " .. tostring(pl and pl.side) .. " of the square (the side away from the character: "
        .. away .. "); over the square too: " .. tostring(S.over(r, a)))
end

-- ===================================================================== pictures (hg_tint.lua's S.shot)
function S.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return -9000 end
            getMouseY = function() return -9000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function S.shot(name, what, gate)
    Q.step(1, function() if not S.dead and not (gate and gate()) then S.park(true) end end)
    Q.step(4, function()
        if S.dead or (gate and gate()) then S.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then
            Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what .. " | balloon " .. S.rt(S.ST.rect)
                .. ", shown " .. tostring(S.ST.shown))
        else
            Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e))
        end
        S.park(false)
    end)
    Q.waitMs(1200)
end

-- ===================================================================== the guard
function S.safety()
    if S.back.on and getTimestampMs() - S.t0 > Q.maxMs + 100000 then
        pcall(S.putBack)
        Q.say("ERR the put-back did not come in time: the guard put things back")
    end
end

-- ===================================================================== start
function S.start()
    S.err0 = S.errN()
    local ST = ZeD and ZeD.SpecialTip
    S.ST = ST
    local ready = ST ~= nil and ST.onTip ~= nil and ST.drawOn ~= nil and ST.place ~= nil and ZeD.Balloon ~= nil and S.p ~= nil
    if not Q.check(ready, "ZeD's trough and farm plot hover facts are loaded (ZeD.SpecialTip, Build 39159199c)") then S.dead = true; return end
    Q.check(ST.captured == 2 and ST.gameTrough ~= nil and ST.gameFarm ~= nil,
        "1 at the start .captured is 2: both game handlers (trough and farm plot) kept back",
        "captured " .. tostring(ST.captured) .. ", trough " .. tostring(ST.gameTrough ~= nil) .. ", farm " .. tostring(ST.gameFarm ~= nil))
    local ev = Events.DoSpecialTooltip
    Q.check(ev ~= nil and ST._addWrapper ~= nil and ev.Add == ST._addWrapper,
        "1 Events.DoSpecialTooltip.Add is ZeD's wrapper (every later Add goes through it)")
    if S.safeNow() then Q.skip("the whole script", "Safe mode is on in this game: the game's own box draws"); S.dead = true; return end
    if S.p:getVehicle() then Q.skip("the whole script", "the character is in a vehicle"); S.dead = true; return end
    S.useTrigger = triggerEvent ~= nil
    if not Q.check(S.makeDriver(), "a real ObjectTooltip and a panel to fire the game's event from (ObjectTooltip.new, ISPanel)") then
        S.dead = true
        return
    end
    local f = S.f
    f.x, f.y, f.z = S.p:getX(), S.p:getY(), S.p:getZ()
    f.dir, f.ang = S.dir(), S.ang()
    f.farmLv, f.farmXp = S.farmLv(), S.farmXp()
    f.pair = RT.isOpen()
    pcall(function() f.tod = getGameTime():getTimeOfDay() end)
    f.cheat = ISFarmingMenu and ISFarmingMenu.cheat or false
    S.g0 = ST.gameTrough
    S.rd0 = Mouse and Mouse.isRightDown or nil
    f.recorded = true
    S.back.on = true
    Q.say("found: at " .. S.n(f.x) .. "," .. S.n(f.y) .. "," .. S.n(f.z) .. " facing " .. tostring(f.dir) .. " (angle " .. S.n(f.ang)
        .. "), Farming " .. tostring(f.farmLv) .. " (" .. S.n(f.farmXp) .. " XP), pair open " .. tostring(f.pair) .. ", time "
        .. S.n(f.tod) .. ", farming cheat " .. tostring(f.cheat) .. ", screen " .. S.sizeTag() .. ", triggerEvent " .. tostring(S.useTrigger))
    if f.cheat then Q.say("NOTE ISFarmingMenu.cheat is on: the plot shows the cheat rows too (the line count check is left out)") end
    Events.OnTick.Add(S.safety)
    RT.pairShut()
    S.standAt(S.FARM.x, S.FARM.y, S.FARM.z)
    if f.tod and (f.tod < 8 or f.tod > 17) then
        pcall(function() getGameTime():setTimeOfDay(11.0) end)
        S.todSet = true
    end
end

-- ===================================================================== the trough
function S.buildTrough(sz)
    -- the farm's cells loaded, the trough picked, the character beside it
    Q.step(300, function()
        if S.dead then return end
        S.pickTrough()
        if S.noTrough then Q.skip("2, 4, 5, 6 and 7 (the trough checks)", S.noTrough); return end
        S.standAt(S.stand:getX() + 0.5, S.stand:getY() + 0.5, S.stand:getZ())
    end)
    -- (2) water; the event reaches ZeD's handler
    Q.step(60, function()
        if S.dead or S.noTrough then return end
        S.stageWater(S.T)
        local s = S.tRead(S.T)
        Q.check(s.water > 0 and s.feed <= 0, "2 the trough holds water and no feed", S.tText(s))
        S.fireOn(S.tSq)
    end)
    Q.step(6, function()
        if S.dead or S.noTrough then return end
        local rose = (S.ST.muted or 0) > S.m0
        if S.useTrigger then
            Q.check(rose, "2 the game's event fired with triggerEvent(\"DoSpecialTooltip\", tooltip, square) reaches ZeD's handler (.muted rises)",
                ".muted +" .. ((S.ST.muted or 0) - S.m0) .. " over " .. S.fired() .. " fires" .. (S.fireErr and (", fire error " .. S.fireErr) or ""))
            if not rose then
                S.useTrigger = false
                Q.say("NOTE from here ZeD's handler is called straight: ZeD.SpecialTip.onTip(tooltip, square)")
            end
        else
            Q.say("NOTE triggerEvent is not there (" .. tostring(S.trigErr) .. "): ZeD.SpecialTip.onTip(tooltip, square) is called straight")
        end
    end)
    S.until1(1, 120, function() return S.noTrough or (S.ST.shown and S.ST.kind == "trough") end, function(ok)
        if S.noTrough then return end
        S.linesW = S.troughCheck("2 trough with water", ok)
        Q.check(S.maxH == 1, "2 ZeD keeps the game's tooltip up with a height of 1 (it draws nothing of its own)", "height " .. S.n(S.maxH))
        S.balloonCheck("2 trough with water", S.tSq)
    end)
    S.shot("hs_tip_trough_" .. sz, "a trough with water: ZeD's balloon beside it, away from the character", function() return S.noTrough end)
    S.gone("5 trough")
    -- (2) empty
    S.troughState("2 trough empty", function(t) S.stageEmpty(t); local s = S.tRead(t); return s.water <= 0 and s.feed <= 0, s end, "linesE")
    -- (2) feed
    Q.step(2, function()
        if S.dead or S.noTrough then return end
        S.feedStaged = S.stageFeed(S.T)
    end)
    S.until1(1, 120, function()
        if S.noTrough then return true end
        S.settle(S.T)
        return S.tRead(S.T).feed > 0
    end, function(ok)
        if S.noTrough then return end
        local s = S.tRead(S.T)
        if not (ok and S.feedStaged) then
            S.noFeed = true
            Q.skip("2 trough with feed", "the game did not count the feed bags put in the trough (" .. S.tText(s) .. ")")
            return
        end
        Q.check(s.water <= 0 and s.feed > 0, "2 the trough holds feed and no water", S.tText(s))
        S.fireOn(S.tSq)
    end)
    S.until1(2, 120, function() return S.noTrough or S.noFeed or (S.ST.shown and S.ST.kind == "trough" and S.lineMatch()) end, function(ok)
        if S.noTrough or S.noFeed then return end
        S.linesF = S.troughCheck("2 trough with feed", ok)
    end)
    S.gone(nil)
    Q.step(1, function()
        if S.dead or S.noTrough then return end
        local a, b, c = S.linesW, S.linesE, S.linesF
        local diff = a ~= nil and b ~= nil and not S.same(a, b) and (c == nil or (not S.same(a, c) and not S.same(b, c)))
        Q.check(diff, "2 the lines change with what the trough holds (water, empty" .. (c and ", feed" or "") .. ")",
            "water " .. S.join(a) .. " | empty " .. S.join(b) .. " | feed " .. S.join(c))
    end)
    S.buildGates()
    S.buildMod(sz)
    S.buildSafe()
end
-- the facts as the game would word them right now, matching ZeD's
function S.lineMatch()
    local g = S.gameTrough(S.tSq)
    return g ~= nil and S.same(S.ST.lines, g.lines)
end
function S.troughCheck(lab, ok)
    local ST = S.ST
    local g = S.gameTrough(S.tSq)
    local okT = ok and ST.shown == true and ST.kind == "trough" and g ~= nil and ST.title == g.title and S.same(ST.lines, g.lines)
    Q.check(okT, lab .. ": the balloon shows the trough in the game's own words (kind trough, its title and lines)",
        "shown " .. tostring(ST.shown) .. ", kind " .. tostring(ST.kind) .. ", title " .. tostring(ST.title) .. ", lines " .. S.join(ST.lines)
        .. (okT and "" or (" | the game's: " .. tostring(g and g.title) .. " " .. S.join(g and g.lines))))
    return S.copy(ST.lines)
end
-- one trough state: staged by stage(t) (true, its read), the event fired, the words checked, the event stopped
function S.troughState(lab, stage, keep)
    Q.step(2, function()
        if S.dead or S.noTrough then return end
        local ok, s = stage(S.T)
        Q.check(ok, lab .. ": staged", S.tText(s))
        S.fireOn(S.tSq)
    end)
    S.until1(2, 120, function() return S.noTrough or (S.ST.shown and S.ST.kind == "trough" and S.lineMatch()) end, function(ok)
        if S.noTrough then return end
        S[keep] = S.troughCheck(lab, ok)
    end)
    S.gone(nil)
end
-- the event stopped; with lab, check 5: the balloon goes within 3 frames
function S.gone(lab)
    Q.step(1, function() S.fireOff(); S.goneK = 0 end)
    S.until1(1, 3, function() S.goneK = S.goneK + 1; return not S.ST.shown end, function(ok)
        if lab and not S.noTrough then
            Q.check(ok, lab .. ": the balloon goes within 3 frames after the event stops", "gone after " .. tostring(S.goneK) .. " frames, shown " .. tostring(S.ST.shown))
        end
    end)
    if not lab then Q.waitFor(1, 10, function() return not S.ST.shown end, function() end) end
end

-- ===================================================================== (4) the trough's gates
function S.buildGates()
    -- the right button held
    Q.step(2, function()
        if S.dead or S.noTrough then return end
        S.rdOk = S.rightHold(true)
        if not S.rdOk then
            S.rightHold(false)
            Q.skip("4 nothing while the right button is held", "Mouse.isRightDown could not be held true from Lua")
            return
        end
        S.fireOn(S.tSq)
    end)
    Q.step(8, function()
        if S.dead or S.noTrough or not S.rdOk then return end
        S.fireOff()
        S.rightHold(false)
        S.nothing("4 a trough with the right button held: nothing (no facts, no balloon, the tooltip with no height)")
    end)
    -- 14+ tiles away
    Q.step(4, function()
        if S.dead or S.noTrough then return end
        local x, y, z = S.tSq:getX(), S.tSq:getY(), S.tSq:getZ()
        local sq = S.ringSq(x, y, z, S.FAR) or S.ringSq(x, y, z, S.FAR + 2) or S.ringSq(x, y, z, S.FAR, nil, true)
        if not sq then S.farSkip = true; Q.skip("4 a trough 14+ tiles away shows nothing", "no open square " .. S.FAR .. " tiles from the trough"); return end
        S.standAt(sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ())
    end)
    Q.step(60, function()
        if S.dead or S.noTrough or S.farSkip then return end
        S.farD = nil
        pcall(function() S.farD = S.p:DistToProper(S.T) end)
        S.fireOn(S.tSq)
    end)
    Q.step(8, function()
        if S.dead or S.noTrough or S.farSkip then return end
        S.fireOff()
        Q.check(S.farD ~= nil and S.farD > 13, "4 the character stands 14+ tiles from the trough", "distance " .. S.n(S.farD))
        S.nothing("4 a trough 14+ tiles away: nothing")
        S.standAt(S.stand:getX() + 0.5, S.stand:getY() + 0.5, S.stand:getZ())
    end)
    Q.step(60, function() end)   -- (the camera back on him)
end

-- ===================================================================== (7) a mod's handler added after load
function S.buildMod(sz)
    Q.step(2, function()
        if S.dead or S.noTrough then return end
        S.stageWater(S.T)
        S.gameCalls = 0
        S.wrapGame()
        local g1, c1 = S.ST.gameTrough, S.ST.captured
        local okA, eA = pcall(function() Events.DoSpecialTooltip.Add(S.modFn) end)
        S.modAdded = okA
        Q.check(okA and S.ST.gameTrough == g1 and S.ST.captured == c1 and S.ST.gameFarm ~= S.modFn,
            "7 a mod's handler added after load goes past ZeD's wrapper untouched (not kept back)",
            okA and ("captured " .. tostring(S.ST.captured)) or tostring(eA))
        S.modCalls, S.modShown = 0, 0
        S.fireOn(S.tSq)
    end)
    S.until1(4, 120, function() return S.noTrough or not S.useTrigger or (S.ST.shown and S.modShown >= 3) end, function(ok)
        if S.noTrough then return end
        if not S.useTrigger then
            Q.skip("7 a mod's handler still runs", "the event is called straight here (triggerEvent did not reach the handlers)")
            return
        end
        Q.check(ok and S.modCalls > 0, "7 the mod's handler still runs while ZeD's balloon shows",
            "called " .. S.modCalls .. " times, " .. S.modShown .. " with the balloon up")
        Q.say("NOTE 7 the mod's line (\"" .. S.MODLINE .. "\") background: "
            .. ((S.gameCalls == 0) and "none (the game's trough handler, the only one that draws the box behind the lines, ran 0 times)"
                or ("the game's trough handler ran " .. S.gameCalls .. " times"))
            .. "; the tooltip's height " .. S.n(S.maxH) .. "; see the picture")
    end)
    S.shot("hs_tip_modline_" .. sz, "a trough with water and a test mod's line on the game's tooltip by the square (NOTE: its background)",
        function() return S.noTrough end)
    Q.step(1, function()
        if S.dead or S.noTrough then return end
        S.fireOff()
        S.modOff()
        S.unwrapGame()
        S.modCalls = 0
    end)
    Q.waitFor(4, 10, function() return not S.ST.shown end, function() end)
    Q.step(1, function() if not (S.dead or S.noTrough) then S.fireOn(S.tSq) end end)
    Q.step(6, function()
        if S.dead or S.noTrough then return end
        S.fireOff()
        Q.check(S.modCalls == 0, "7 the test handler removed (Events.DoSpecialTooltip.Remove) runs no more", "called " .. S.modCalls .. " times")
    end)
    Q.waitFor(1, 10, function() return not S.ST.shown end, function() end)
end

-- ===================================================================== (6) safe mode
function S.buildSafe()
    Q.step(2, function()
        if S.dead or S.noTrough then return end
        local ok, why = S.safeOn()
        S.safeRan = ok
        if not ok then
            S.safeOff()
            Q.skip("6 safe mode brings the game's box back", why)
            return
        end
        S.gameCalls = 0
        S.wrapGame()
    end)
    Q.step(30, function() if S.safeRan then S.fireOn(S.tSq) end end)
    Q.step(10, function()
        if not S.safeRan then return end
        local ST = S.ST
        S.fireOff()
        Q.check(S.safeNow() and S.gameCalls > 0 and S.maxH > 1,
            "6 safe mode: the game's own trough handler runs again and its box draws (the tooltip measured a height)",
            "Safe.on " .. tostring(S.safeNow()) .. ", the game handler called " .. S.gameCalls .. " times, the tooltip's height " .. S.n(S.maxH))
        Q.check((ST.muted or 0) == S.m0 and not ST.shown, "6 safe mode: .muted stops rising and ZeD's balloon is not shown",
            ".muted +" .. ((ST.muted or 0) - S.m0) .. ", shown " .. tostring(ST.shown))
        S.unwrapGame()
        S.safeOff()
    end)
    S.until1(5, 300, function() return not S.safeRan or not S.safeNow() end, function(ok)
        if not S.safeRan then return end
        Q.check(ok, "6 Safe mode Off again", "ZeD.Safe.on() " .. tostring(S.safeNow()))
        S.fireOn(S.tSq)
    end)
    S.until1(2, 120, function() return not S.safeRan or (S.ST.shown and S.ST.kind == "trough") end, function(ok)
        if not S.safeRan then return end
        Q.check(ok and S.ST.muted > S.m0, "6 after Safe mode: ZeD's balloon is back on the trough", "shown " .. tostring(S.ST.shown))
    end)
    S.gone(nil)
end

-- ===================================================================== (3) the farm plot
function S.buildFarm(sz)
    Q.step(4, function()
        if S.dead then return end
        local px, py, pz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
        local sq = S.ringSq(px, py, pz, 2, S.plotOk) or S.ringSq(px, py, pz, 3, S.plotOk) or S.ringSq(px, py, pz, 1, S.plotOk)
        if not sq then S.noPlot = "no open square 1 to 3 tiles from the character"; Q.skip("3 the farm plot checks", S.noPlot); return end
        local ok, why = S.plant(sq)
        if not ok then S.noPlot = tostring(why); Q.skip("3 the farm plot checks", "the plot could not be planted: " .. S.noPlot); return end
        S.seedKind = why
        Q.say("plowed and seeded (" .. tostring(why) .. ") at " .. S.sqText(sq) .. ", aphids 5 set on the game's server object")
    end)
    S.until1(2, 300, function()
        if S.noPlot then return true end
        local cp = S.cPlant(S.plotSq)
        return cp ~= nil and cp.typeOfSeed ~= nil and cp.typeOfSeed ~= "none"
    end, function(ok)
        if S.noPlot then return end
        local cp = S.cPlant(S.plotSq)
        if not ok then
            S.noPlot = "the game's client farm system did not show the planted plot within 300 frames"
            Q.skip("3 the farm plot checks", S.noPlot)
            return
        end
        Q.say("NOTE the plot as the game's client reads it: " .. tostring(cp.typeOfSeed) .. ", state " .. tostring(cp.state) .. ", water "
            .. tostring(cp.waterLvl) .. ", aphids " .. tostring(cp.aphidLvl) .. ", alive " .. tostring(cp:isAlive()) .. ", "
            .. S.n(S.p:DistTo(S.plotSq:getX(), S.plotSq:getY())) .. " tiles from the character")
        Q.check(S.setFarm(2), "4 Farming set to 2", tostring(S.farmLv()))
    end)
    -- (4) Farming 2
    Q.step(4, function() if not (S.dead or S.noPlot) then S.fireOn(S.plotSq) end end)
    Q.step(8, function()
        if S.dead or S.noPlot then return end
        S.fireOff()
        S.nothing("4 a planted plot at Farming 2: nothing")
    end)
    -- (3) Farming 3
    Q.step(4, function()
        if S.dead or S.noPlot then return end
        S.setFarm(3)
        S.fireOn(S.plotSq)
    end)
    S.until1(2, 120, function() return S.noPlot or (S.ST.shown and S.ST.kind == "farm") end, function(ok)
        if not S.noPlot then S.farmCheck("3 plot at Farming 3", 3, ok) end
    end)
    Q.step(1, function() S.fireOff() end)
    Q.waitFor(1, 10, function() return not S.ST.shown end, function() end)
    -- (3) Farming 6 (the new level's words over the head gone before the picture)
    Q.step(2, function()
        if S.dead or S.noPlot then return end
        S.setFarm(6)
        S.fireOn(S.plotSq)
    end)
    Q.waitMs(3000)
    S.until1(1, 120, function()
        if S.noPlot then return true end
        local g = S.gameFarm(S.plotSq, 6)
        return S.ST.shown and S.ST.kind == "farm" and g ~= nil and S.hasPre(S.ST.lines, g.phase)
    end, function(ok)
        if S.noPlot then return end
        S.farmCheck("3 plot at Farming 6", 6, ok)
        S.balloonCheck("3 plot at Farming 6", S.plotSq)
    end)
    S.shot("hs_tip_farm_" .. sz, "a planted plot at Farming 6: ZeD's balloon beside it, away from the character", function() return S.noPlot end)
    Q.step(1, function() S.fireOff(); S.goneK = 0 end)
    S.until1(1, 3, function() S.goneK = S.goneK + 1; return not S.ST.shown end, function(ok)
        if S.noPlot then return end
        Q.check(ok, "5 plot: the balloon goes within 3 frames after the event stops", "gone after " .. tostring(S.goneK) .. " frames")
    end)
end

-- ===================================================================== the run
function S.build()
    local sz = S.sizeTag()
    Q.step(10, S.start)
    S.buildTrough(sz)
    S.buildFarm(sz)
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    S.fireOff()
    S.park(false)
    S.modOff()
    S.unwrapGame()
    S.rightHold(false)
    S.safeOff()
    if S.drv then pcall(function() S.drv:removeFromUIManager() end); S.drv = nil end
    S.troughBack()
    S.unplant()
    S.putFarm()
    local f = S.f
    S.standAt(f.x, f.y, f.z)
    if f.dir ~= nil then pcall(function() S.p:setDir(f.dir) end) end
    if f.ang ~= nil then pcall(function() S.p:setDirectionAngle(f.ang) end) end
    if S.todSet and f.tod then pcall(function() getGameTime():setTimeOfDay(f.tod) end); S.todSet = nil end
    pcall(function() Events.OnTick.Remove(S.safety) end)
end
function S.buildPutBack()
    Q.mark()
    Q.step(5, function()
        if not S.back.on then return end
        S.putBack()
        if S.f.pair then RT.pairOpen() else RT.pairShut() end
    end)
    S.until1(5, 300, function()
        if not S.f.recorded then return true end
        local plotGone = S.plotSq == nil or (S.cPlant(S.plotSq) == nil and S.sPlant(S.plotSq) == nil)
        return plotGone and RT.isOpen() == (S.f.pair == true)
    end, function(ok)
        local f, p = S.f, S.p
        if not f.recorded then
            Q.skip("put back", "nothing was staged")
            return
        end
        Q.check(math.abs(p:getX() - f.x) < 0.01 and math.abs(p:getY() - f.y) < 0.01 and math.abs(p:getZ() - f.z) < 0.01,
            "put back: the character where he was (" .. S.n(f.x) .. "," .. S.n(f.y) .. "," .. S.n(f.z) .. ")",
            S.n(p:getX()) .. "," .. S.n(p:getY()) .. "," .. S.n(p:getZ()))
        local a1 = S.ang()
        Q.check(tostring(S.dir()) == tostring(f.dir) and (f.ang == nil or (a1 ~= nil and math.abs(a1 - f.ang) < 0.01)),
            "put back: his facing", tostring(S.dir()) .. " (angle " .. S.n(a1) .. "), was " .. tostring(f.dir) .. " (" .. S.n(f.ang) .. ")")
        local xp = S.farmXp()
        Q.check(S.farmLv() == f.farmLv and xp ~= nil and f.farmXp ~= nil and math.abs(xp - f.farmXp) < 0.01,
            "put back: Farming level and XP", tostring(S.farmLv()) .. " (" .. S.n(xp) .. " XP), was " .. tostring(f.farmLv) .. " (" .. S.n(f.farmXp) .. ")")
        if S.T and f.tr then
            local s = S.tRead(S.T)
            Q.check(math.abs(s.water - f.tr.water) < 0.01 and math.abs(s.feed - f.tr.feed) < 0.01 and s.fc == f.tr.fc
                and s.ctn == f.tr.ctn and s.items == f.tr.items and S.f.trType == S.fluidType(S.T),
                "put back: the trough as found (water and its fluid, feed, its containers)", S.tText(s) .. " | found " .. S.tText(f.tr))
        end
        if S.plotSq then
            local md = nil
            pcall(function() md = S.plotSq:getModData() end)
            Q.check(S.cPlant(S.plotSq) == nil and S.sPlant(S.plotSq) == nil and (md == nil or md.plowDay == f.plowDay),
                "put back: the plot removed, its square's plowDay as found", "plant left " .. tostring(S.cPlant(S.plotSq) ~= nil or S.sPlant(S.plotSq) ~= nil))
        end
        Q.check(not S.modAdded and S.ST.gameTrough == S.g0 and Mouse.isRightDown == S.rd0 and S.drv == nil and S.parked == nil,
            "put back: the test handler removed, the kept game handler, Mouse.isRightDown, no driving panel, the pointer the game's")
        local optOk = true
        if S.safeWas ~= nil then
            pcall(function() optOk = ZeD.Settings.safeModeOption:getValue() == S.safeWas end)
        end
        Q.check(not S.safeNow() and optOk and not S.safeSet, "put back: Safe mode off, its option as found", "option was " .. tostring(S.safeWas))
        Q.check(ok and RT.isOpen() == (f.pair == true), "put back: the window pair " .. (f.pair and "open" or "shut") .. " as found")
        local e1 = S.errN()
        if S.err0 and e1 then
            Q.check(e1 == S.err0, "the run ran with no Lua error", (e1 - S.err0) .. " new")
        else
            Q.skip("the run's Lua error count", "the game's Lua error count cannot be read here")
        end
    end)
end

S.build()
S.buildPutBack()
Q.start()
