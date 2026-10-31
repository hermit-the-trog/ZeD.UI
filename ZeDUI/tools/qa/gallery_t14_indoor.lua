-- ZeDUI/tools/qa/gallery_t14_indoor.lua  (Oct 30 2026)
-- Workshop gallery, slides 58-60 (0.2.0-t14): the machines that need grid power in a room, one trip.
-- The staging is zedqa_rtv.lua's and zedqa_laundry.lua's: the game's grid flag on for the run (the QA world is past the
-- shut-off; a square has grid power only inside a room), the water supply on, and the character on a free room square
-- with free room squares round it (the Fossoil at West Point when no room is in reach of the QA home). The things are
-- set down on those squares, shot one section at a time, and taken away before the next. Full 4K screenshots in
-- Zomboid/Screenshots, each once both windows have stopped moving:
--   tvs      58  g14_tv_widescreen  the wide-screen set playing a retail tape (the picture: the tape's title and its lines)
--               g14_tv_widescreen_snow  the same set, the tape stopped, off the dial: snow (Oct 31 2026, a spare)
--               g14_tv_black       the black set tuned off the dial: snow
--               g14_tv_antique     the antique set on the first station of its dial (sign-off or standby, as the
--                                  game's broadcast clock has it; the QA world is past the broadcasts: standby)
--               g14_tv_antique_bars the antique set on channel 12, no station: the bars (a spare)
--   laundry  59  g14_ldy_washer     the washer with water and a shirt in, running (vanilla's toggle, instant)
--               g14_ldy_dryer      the dryer with a shirt in, stopped
--               g14_ldy_combo      the washer-dryer, stopped, washer mode
--   plates   60  g14_plate_oven      an oven in the Craft tab, BAKE 175 started
--               g14_plate_microwave a microwave in the Craft tab
--               g14_plate_generator a generator's card (connected, 60 per cent fuel, off)
-- At UI scale 1.75 (the runner's fullscreen4k sets it; set here for the run when it is not, put back after).
-- GAL14_ONLY = { tvs = true, ... } above this header takes only those sections. Each window's box is printed ("box").
-- Everything placed or given is taken away; the grid, the water, the instant cheat, the scale, the tabs and the
-- character's place are put back. Run after gallery_t14_look.lua. "ZEDQA g14i ..." ending "ZEDQA g14i DONE".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA g14i " .. tostring(s)) end
local Z = { Q = {}, qi = 0, wait = 0, placed = {}, added = {}, objs = {} }
local OC, LD, CT, R, ST, SA, Sc = ZeD.ObjectCards, ZeD.ObjectCardLaundry, ZeD.ContainerControls, ZeD.Rtv, ZeD.Stations, ZeD.StationAppliance, ZeD.Scale
if not (OC and LD and CT and R and ST and SA) then say("ERR the laundry, TV or station modules are not loaded"); say("DONE"); return end
local function want(k) return (not GAL14_ONLY) or GAL14_ONLY[k] == true end
local function WW() return ZeD_WorldWindow.getWindow() end
local function CW() return ZeD_CharacterWindow.getWindow() end
function Z.step(n, fn) Z.Q[#Z.Q + 1] = { n = n, fn = fn } end
function Z.waitFor(n, max, cond, fn) Z.Q[#Z.Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
function Z.shape()
    if GAL_SHAPE then return GAL_SHAPE() end
    local w = WW()
    return w and string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0)) or ""
end
-- both windows the same for 30 frames (at most 900), then fn
function Z.whenStill(n, fn)
    local last, same = nil, 0
    Z.waitFor(n, 900, function()
        local s = Z.shape()
        if s == last then same = same + 1 else last, same = s, 0 end
        return same >= 30
    end, fn)
end
function Z.shot(name)
    pcall(function() Mouse.setXY(20, 20) end)
    local ok, e = pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
    say((ok and "shot " or "ERR shot ") .. name .. (ok and "" or (": " .. tostring(e))))
    for _, pair in ipairs({ { "char", CW() }, { "world", WW() } }) do
        local w = pair[2]
        if w and w:isVisible() then say(string.format("box %s %s %d,%d-%d,%d", name, pair[1], w:getX(), w:getY(), w:getX() + w:getWidth(), w:getY() + w:getHeight())) end
    end
    local c = WW() and WW()._objectCard
    if c and c:isVisible() then say(string.format("box %s card %d,%d-%d,%d", name, c:getAbsoluteX(), c:getAbsoluteY(), c:getAbsoluteX() + c:getWidth(), c:getAbsoluteY() + c:getHeight())) end
end
function Z.tab(id)
    local w = WW()
    for _, z in ipairs(w and w._actionTabStrip and w._actionTabStrip._hitZones or {}) do
        if z.id == "tab:" .. id then
            if w._activeTab ~= id or (id ~= "loot" and not w._drawerOpen) then w._actionTabStrip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end

-- ---- the room, the grid and the water (zedqa_rtv.lua / zedqa_laundry.lua)
function Z.sqAt(x, y, z) return getCell():getGridSquare(x, y, z) end
function Z.freeSq(x, y, z)
    local sq = Z.sqAt(x, y, z)
    local ok = false
    if sq then pcall(function() ok = sq:isFree(false) and not sq:getVehicleContainer() end) end
    return ok and sq or nil
end
local RING = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
-- the reachable free room squares round (x, y): all eight, and the four sides apart
function Z.ring(x, y, z)
    local here = Z.freeSq(x, y, z)
    local all, sides = {}, {}
    if not (here and here:getRoom()) then return all, sides end
    for i, d in ipairs(RING) do
        local n = Z.freeSq(x + d[1], y + d[2], z)
        local reach = false
        if n then pcall(function() reach = n:getRoom() ~= nil and here:canReachTo(n) end) end
        if reach then all[#all + 1] = n; if i <= 4 then sides[#sides + 1] = n end end
    end
    return all, sides
end
function Z.findSpot(cx, cy, cz, rad)
    for r = 0, rad do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local all, sides = Z.ring(cx + dx, cy + dy, cz)
                    if #all >= 4 and #sides >= 3 then return { x = cx + dx + 0.5, y = cy + dy + 0.5, z = cz, all = all, sides = sides } end
                end
            end
        end
    end
    return nil
end
function Z.moveTo(x, y, z)
    p:teleportTo(x, y, z)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end)
end
local STORE = { x0 = 12052, y0 = 7117, x1 = 12069, y1 = 7126 }   -- the Fossoil at West Point
Z.home = { x = p:getX(), y = p:getY(), z = p:getZ() }
Z.so = getSandboxOptions()
Z.elec = Z.so and Z.so:getOptionByName("ElecShutModifier")
Z.watr = Z.so and Z.so:getOptionByName("WaterShutModifier")
Z.was = { elec = Z.elec and Z.elec:getValue(), watr = Z.watr and Z.watr:getValue(), hydro = getWorld():isHydroPowerOn(),
          open = ZeD_CharacterWindow.isOpen(), scale = Sc and Sc.override, prim = p:getPrimaryHandItem(), sec = p:getSecondaryHandItem() }
pcall(function() Z.was.instant = p:isTimedActionInstantCheat() end)
function Z.grid(on)
    if Z.elec then Z.elec:setValue(on and 99999 or Z.was.elec); pcall(function() Z.so:toLua() end) end
    if Z.watr then Z.watr:setValue(on and 99999 or Z.was.watr); pcall(function() Z.so:toLua() end) end
    getWorld():setHydroPowerOn(on and true or Z.was.hydro)
end
function Z.clearAll()
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() ST.unbind(p) end)
    pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
    for _, obj in ipairs(Z.placed) do
        pcall(function() if obj.isActivated and obj:isActivated() then obj:setActivated(false) end end)
        pcall(function() local dd = obj:getDeviceData(); if dd then dd:StopPlayMedia(); dd:setIsTurnedOn(false) end end)
        local sq = obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end
        pcall(function() if instanceof(obj, "IsoGenerator") then obj:remove() end end)
    end
    for _, it in ipairs(Z.added) do local c = it:getContainer(); if c then pcall(function() c:Remove(it) end) end end
    Z.placed, Z.added, Z.objs = {}, {}, {}
    if Z.spot then Z.moveTo(Z.spot.x, Z.spot.y, Z.spot.z) end
end

Z.step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    Z.grid(true)
    pcall(function() p:setTimedActionInstantCheat(true) end)
    if Sc and Sc.root and math.abs(Sc.root() - 1.75) > 0.01 then Sc.override = 1.75; Sc.refresh(); ZeD.applyTheme(); Z.scaled = true end
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    Z.spot = Z.findSpot(math.floor(Z.home.x), math.floor(Z.home.y), math.floor(Z.home.z), 45)
    if not Z.spot then
        Z.travelled, Z.t0 = true, getTimestampMs()
        say("no room in reach: to the Fossoil at West Point")
        Z.moveTo(math.floor((STORE.x0 + STORE.x1) / 2) + 0.5, math.floor((STORE.y0 + STORE.y1) / 2) + 0.5, 0)
    end
end)
Z.waitFor(5, 3000, function()
    return not Z.travelled or (Z.sqAt(STORE.x0, STORE.y0, 0) ~= nil and Z.sqAt(STORE.x1, STORE.y1, 0) ~= nil and getTimestampMs() - Z.t0 > 9000)
end, function()
    if Z.travelled then Z.spot = Z.findSpot(math.floor((STORE.x0 + STORE.x1) / 2), math.floor((STORE.y0 + STORE.y1) / 2), 0, 12) end
    if Z.spot then
        Z.moveTo(Z.spot.x, Z.spot.y, Z.spot.z)
        say(string.format("indoors at %d,%d: %d room squares round, %d sides", math.floor(Z.spot.x), math.floor(Z.spot.y), #Z.spot.all, #Z.spot.sides))
    else
        say("ERR no room square with free room squares round it")
    end
end)
Z.step(60, function()
    if not ZeD_WorldWindow.isOpen() then pcall(ZeD_WorldWindow.open, pn) end
    local sq = p:getCurrentSquare()
    local g = false
    pcall(function() g = sq:hasGridPower() end)
    say("grid power here " .. tostring(g) .. " | look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " | scale " .. tostring(Sc and Sc.root and Sc.root()))
end)

-- ===================================================================== 58 the TVs
-- a set on a square first, its data touched after (zedqa_rtv.lua: a set not on a square asks a squareless item about power)
function Z.putTv(spr, sq)
    local obj = IsoTelevision.new(getCell(), sq, getSprite(spr))
    sq:AddTileObject(obj)
    Z.placed[#Z.placed + 1] = obj
    return obj
end
-- ready(st, air): the state the shot waits for (at most `max` frames; the run prints WARN if it never comes)
function Z.showTv(key, name, prep, ready, max)
    Z.step(5, function()
        for i, r in ipairs(WW()._radios or {}) do if r.radioInstance == Z.objs[key] then WW()._radioIdx = i end end
        Z.tab("radio")
    end)
    Z.waitFor(5, 600, function() local t = WW()._radioTw; return Z.objs[key] == nil or (t ~= nil and t.dev == Z.objs[key]) end, function()
        local o = Z.objs[key]
        if not o then say("ERR " .. key .. " not placed"); return end
        if prep then prep(o, o:getDeviceData()) end
    end)
    Z.step(30, function() end)
    Z.waitFor(5, max or 1200, function()
        local o = Z.objs[key]
        if not o then return true end
        local st = R.read(o)
        if not st then return true end
        return ready(st, R.air(st))
    end, function()
        local o = Z.objs[key]
        local st = o and R.read(o)
        if st then
            local h = R._heard[st.key]
            say(string.format("%s: on %s, channel %s, air %s, media %s, playing %s, title %s, lines %d", key, tostring(st.on), tostring(st.channel),
                tostring(R.air(st)), tostring(st.hasMedia), tostring(st.playing), tostring(st.mediaTitle), h and h.lines and #h.lines or 0))
        end
    end)
    Z.whenStill(10, function() Z.shot(name) end)
end
-- a retail tape with its recording set (Oct 31 2026: an item made by AddItem has no recorded media until it is
-- given one, as loot is; the t14 take put a blank tape in, addMediaItem refused it, and nothing played). The tape
-- goes in from the character's inventory, as ISDeviceMediaAction does it.
function Z.tape(dd)
    local it = p:getInventory():AddItem("Base.VHS_Retail")
    if not it then say("ERR no VHS_Retail"); return false end
    Z.added[#Z.added + 1] = it
    local md = nil
    pcall(function()
        local list = getZomboidRadio():getRecordedMedia():getAllMediaForCategory("Retail-VHS")
        if list and list:size() > 0 then md = list:get(0) end
    end)
    if not md then say("ERR no Retail-VHS recording to put on the tape"); return false end
    it:setRecordedMediaData(md)
    local ok, e = pcall(function() dd:addMediaItem(it) end)
    say("tape: " .. tostring(md:getTitleEN()) .. (ok and "" or (" | ERR addMediaItem: " .. tostring(e))) .. " | has media " .. tostring(dd:hasMedia()))
    return ok
end
local function offDial(dd) local s = R.stops(); dd:setChannel(s[#s].freq + 4) end
if want("tvs") then
    Z.step(10, function()
        local ring = Z.spot and Z.spot.all or {}
        local SETS = { { "tv_widescreen", "appliances_television_01_1" }, { "tv_black", "appliances_television_01_5" }, { "tv_antique", "appliances_television_01_9" } }
        for i, s in ipairs(SETS) do if ring[i] then Z.objs[s[1]] = Z.putTv(s[2], ring[i]) end end
        local sq = ring[1]
        local g = false
        pcall(function() g = sq:hasGridPower() end)
        say("TVs placed " .. #Z.placed .. " | grid power on their squares " .. tostring(g))
    end)
    Z.waitFor(10, 600, function()
        local n = 0
        for _, r in ipairs(WW()._radios or {}) do for _, o in pairs(Z.objs) do if r.radioInstance == o then n = n + 1 end end end
        return n >= #Z.placed
    end, function() say("the World window lists the sets") end)
    -- the wide screen: on, a retail tape in, playing; the shot once the picture has shown three of the tape's lines
    -- (the t14 take's step 9 "went on": the tape never played)
    Z.showTv("tv_widescreen", "g14_tv_widescreen", function(o, dd)
        dd:setDeviceVolume(0.3)
        dd:setIsTurnedOn(true)
        if Z.tape(dd) then pcall(function() dd:StartPlayMedia() end) end
    end, function(st) return st.playing == true and (R._heard[st.key] and #R._heard[st.key].lines >= 3) end, 3600)
    -- the same set, the tape stopped and the dial off its last stop: snow (the spare for slide 58's snow: the black
    -- set's face drew no screen in any state on Oct 30, its bars and standby included; see the report)
    Z.showTv("tv_widescreen", "g14_tv_widescreen_snow", function(o, dd)
        pcall(function() dd:StopPlayMedia() end)
        pcall(function() offDial(dd) end)
    end, function(st, air) return air == "snow" and not st.playing end, 600)
    -- the black set: on, a frequency off the dial (the stops' last one plus 4 kHz): snow
    Z.showTv("tv_black", "g14_tv_black", function(o, dd)
        dd:setDeviceVolume(0.3)
        dd:setIsTurnedOn(true)
        pcall(function() offDial(dd) end)
    end, function(st, air) return st.on and air == "snow" end, 600)
    -- the antique set: on, the first stop of its dial with a station. The QA world is past the broadcasts, so every
    -- station shows its standby card (zedqa_rtv.lua's dial sweep: standby on 1-11, bars on 12 and 13); a sign-off card
    -- needs a world still on the air.
    Z.showTv("tv_antique", "g14_tv_antique", function(o, dd)
        dd:setDeviceVolume(0.3)
        dd:setIsTurnedOn(true)
        local stop = nil
        for _, s in ipairs(R.stops()) do if s.id and not stop then stop = s end end
        pcall(function() ZeD.RadioOps.setChannel(p, o, (stop or R.stops()[1]).freq) end)
    end, function(st, air) return st.on and air ~= "snow" end, 1200)
    -- and on channel 12, where no station is: the bars (a spare)
    Z.showTv("tv_antique", "g14_tv_antique_bars", function(o, dd)
        pcall(function() ZeD.RadioOps.setChannel(p, o, R.stops()[12].freq) end)
    end, function(st, air) return air == "bars" end, 600)
    Z.step(10, function() Z.tab("loot"); Z.clearAll() end)
end

-- ===================================================================== 59 the laundry machines
function Z.tileFor(cls)
    for i = 0, 47 do
        local name = "appliances_laundry_01_" .. i
        local spr = getSprite(name)
        local props = spr and spr:getProperties()
        if props and props:has("IsoType") and props:get("IsoType") == cls then return name end
    end
    return nil
end
function Z.putMachine(cls, sq)
    local tile = Z.tileFor(cls)
    if not (tile and sq) then say("ERR no tile or square for " .. cls); return nil end
    local obj
    pcall(function()
        if cls == "IsoClothingWasher" then obj = IsoClothingWasher.new(getCell(), sq, getSprite(tile))
        elseif cls == "IsoClothingDryer" then obj = IsoClothingDryer.new(getCell(), sq, getSprite(tile))
        else obj = IsoCombinationWasherDryer.new(getCell(), sq, getSprite(tile)) end
    end)
    if not obj then say("ERR " .. cls .. " not made"); return nil end
    pcall(function() obj:createContainersFromSpriteProperties() end)
    pcall(function() obj:createFluidContainersFromSpriteProperties() end)
    sq:AddSpecialObject(obj)
    if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
    Z.placed[#Z.placed + 1] = obj
    if cls == "IsoCombinationWasherDryer" then pcall(function() obj:setModeWasher() end) end
    local shirt = obj:getContainer() and obj:getContainer():AddItem("Base.Tshirt_DefaultTEXTURE_TINT")
    if shirt then Z.added[#Z.added + 1] = shirt end
    return obj
end
function Z.water(obj)
    pcall(function() obj:getModData().canBeWaterPiped = nil end)
    pcall(function() obj:setUsesExternalWaterSource(false) end)
    if (obj:getFluidAmount() or 0) <= 0 then pcall(function() obj:addFluid(FluidType.Water, 20) end) end
end
function Z.ldyZone(fid)
    local c = WW() and WW()._objectCard
    local zs = c and ((c._zones and #c._zones > 0) and c._zones or c._lastZones) or nil
    for _, z in ipairs(zs or {}) do if z.fid == fid then return z, c end end
    return nil
end
function Z.machine(key, name, run)
    Z.step(5, function()
        pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
        local obj = Z.objs[key]
        if obj then ZeD_WorldWindow.selectContainer(obj:getContainer(), 900) end
    end)
    Z.waitFor(10, 900, function()
        local c = WW() and WW()._mainContent
        for _, h in ipairs((c and c._cc and c._cc.hits) or {}) do if h.key == "obj:ZeDLaundry" then return true end end
        return Z.objs[key] == nil
    end, function()
        local c = WW() and WW()._mainContent
        for i, h in ipairs((c and c._cc and c._cc.hits) or {}) do if h.key == "obj:ZeDLaundry" then CT.press(c, i); return end end
        say("ERR " .. key .. ": no gears button on its container row")
    end)
    Z.waitFor(10, 900, function()
        local c = WW() and WW()._objectCard
        local e = c and c.entry
        return Z.objs[key] == nil or (e and e.t and e.t._face ~= nil and math.abs(c:getWidth() - ZeD.T.px(480)) <= 1)
    end, function()
        local c = WW() and WW()._objectCard
        say(key .. ": card " .. tostring(c and c:getWidth()) .. " px, face " .. tostring(c and c.entry and c.entry.t and c.entry.t._face))
        if run then
            local z = Z.ldyZone("ldy:power")
            if z and z.run then z.run(c, p) else say("ERR " .. key .. ": no power control") end
        end
    end)
    if run then Z.waitFor(10, 900, function() local o = Z.objs[key]; return o == nil or o:isActivated() end, function()
        say(key .. ": running " .. tostring(Z.objs[key] and Z.objs[key]:isActivated()))
    end) end
    Z.step(run and 90 or 20, function() end)
    Z.whenStill(5, function() Z.shot(name) end)
end
if want("laundry") then
    Z.step(10, function()
        local sides = Z.spot and Z.spot.sides or {}
        Z.objs.washer = Z.putMachine("IsoClothingWasher", sides[1])
        Z.objs.dryer = Z.putMachine("IsoClothingDryer", sides[2])
        Z.objs.combo = Z.putMachine("IsoCombinationWasherDryer", sides[3])
        if Z.objs.washer then Z.water(Z.objs.washer) end
        if Z.objs.combo then Z.water(Z.objs.combo) end
        say("machines placed " .. #Z.placed)
    end)
    Z.step(60, function() end)
    Z.machine("washer", "g14_ldy_washer", true)
    Z.machine("dryer", "g14_ldy_dryer", false)
    Z.machine("combo", "g14_ldy_combo", false)
    Z.step(10, function() Z.clearAll() end)
end

-- ===================================================================== 60 the machine plates
function Z.putStove(spr, sq)
    if not sq then return nil end
    local obj = IsoStove.new(getCell(), sq, getSprite(spr))
    pcall(function() obj:createContainersFromSpriteProperties() end)
    sq:AddSpecialObject(obj)
    if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
    Z.placed[#Z.placed + 1] = obj
    return obj
end
function Z.platePress(id)
    local zs = (WW() and WW()._craftState and WW()._craftState.zones) or {}
    for _, z in ipairs(zs) do
        if z.type == "plate" and z.id == id then
            SA.onClick(WW(), WW()._craftState, ST.current(p), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
            return true
        end
    end
    say("ERR no control " .. id .. " on the plate")
    return false
end
if want("plates") then
    Z.step(10, function()
        local sides = Z.spot and Z.spot.sides or {}
        Z.objs.oven = Z.putStove("appliances_cooking_01_12", sides[1])
        Z.objs.micro = Z.putStove("appliances_cooking_01_24", sides[2])
        local gsq = sides[3]
        if gsq then pcall(function()
            local g = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), gsq)
            g:setConnected(true); g:setFuel(60); g:setCondition(90)
            Z.objs.gen = g
            Z.placed[#Z.placed + 1] = g
        end) end
        say(string.format("placed: oven %s, microwave %s, generator %s", tostring(Z.objs.oven ~= nil), tostring(Z.objs.micro ~= nil), tostring(Z.objs.gen ~= nil)))
    end)
    Z.step(30, function() Z.tab("craft") end)
    Z.step(10, function() if not (Z.objs.oven and ST.open(p, Z.objs.oven)) then say("ERR the oven did not open in the Craft tab") end end)
    Z.step(90, function() end)
    for _, id in ipairs({ "bake", "d1", "d7", "d5", "start" }) do Z.step(8, function() Z.platePress(id) end) end
    Z.step(60, function() say("oven on " .. tostring(Z.objs.oven and Z.objs.oven:Activated())) end)
    Z.whenStill(5, function() Z.shot("g14_plate_oven") end)
    Z.step(5, function() pcall(function() Z.objs.oven:Toggle() end); pcall(function() ST.unbind(p) end) end)
    Z.step(10, function() if not (Z.objs.micro and ST.open(p, Z.objs.micro)) then say("ERR the microwave did not open in the Craft tab") end end)
    Z.step(90, function() end)
    Z.whenStill(5, function() Z.shot("g14_plate_microwave") end)
    Z.step(5, function() pcall(function() ST.unbind(p) end); Z.tab("loot") end)
    Z.step(30, function()
        local def = OC.kinds.generator
        local ok, list = pcall(def.nearby, p)
        local t
        for _, c in ipairs(ok and list or {}) do if c.obj == Z.objs.gen then t = c end end
        if t then ZeD_WorldWindow.openObjectCard(pn, { def = def, t = t }) else say("ERR the generator card: no generator beside the character") end
    end)
    Z.step(120, function() end)
    Z.whenStill(5, function() Z.shot("g14_plate_generator") end)
    Z.step(10, function() Z.clearAll() end)
end

-- ===================================================================== put back
Z.step(10, function()
    Z.clearAll()
    Z.tab("loot")
    Z.grid(false)
    pcall(function() p:setTimedActionInstantCheat(Z.was.instant) end)
    if Z.scaled then Sc.override = Z.was.scale; Sc.refresh(); ZeD.applyTheme() end
    p:setPrimaryHandItem(Z.was.prim); p:setSecondaryHandItem(Z.was.sec)
    if Z.was.open ~= ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    Z.moveTo(Z.home.x, Z.home.y, Z.home.z)
    Z.t0 = getTimestampMs()
    say("put back: things taken away, grid and water switches, instant cheat, scale")
end)
Z.waitFor(5, 3000, function()
    return Z.sqAt(math.floor(Z.home.x), math.floor(Z.home.y), math.floor(Z.home.z)) ~= nil and getTimestampMs() - Z.t0 > 3000
end, function()
    say(string.format("back at %d,%d", math.floor(p:getX()), math.floor(p:getY())))
    GAL14_ONLY = nil   -- (gallery_t14_retake_tvs.lua's section list, for a later full run)
    say("DONE")
end)

function Z.tick()
    local s = Z.Q[Z.qi + 1]
    if not s then Events.OnTick.Remove(Z.tick); return end
    Z.wait = Z.wait + 1
    if Z.wait < s.n then return end
    if s.cond then
        s.left = (s.left or s.max) - 1
        local ok, done = pcall(s.cond)
        if not (ok and done) and s.left > 0 then return end
        if not (ok and done) then say("WARN step " .. (Z.qi + 1) .. ": waited " .. s.max .. " frames, went on") end
    end
    Z.wait = 0
    Z.qi = Z.qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. Z.qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(Z.tick)
say("start")
