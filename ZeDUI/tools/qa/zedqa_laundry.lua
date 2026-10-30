-- ZeDUI/tools/qa/zedqa_laundry.lua  (Oct 30 2026)
-- The laundry machines' face cards (ZeDUI/HANDOFF_radio_tv_laundry_20261030.md; ObjectCardLaundry.lua), in game.
-- A washer, a dryer and a washer-dryer are placed beside the character indoors (grid power on for the run, as
-- zedqa_appliances.lua does; the Fossoil at West Point when no room is in reach). For each machine:
--   the entry point: its container in the World window's Loot pane, the container row holds the gears button
--     (obj:ZeDLaundry) and none of vanilla's laundry buttons; pressing it opens the laundry card
--   the card: the full card, the face picked by the class (washer / dryer / washer_dryer, at the width that fills
--     the card), its click areas as zones (power primary; the washer-dryer's WASH / DRY), the controller lands on power
--   live parts: no power lamp off, the water meter against the fluid, FILL with no water in washer mode, the clothes
--     sprite with a shirt inside
--   presses: door shows its contents in the Loot pane; power starts it and stops it (vanilla's action, the instant
--     cheat on); while it runs one phase lamp is lit, the cycle dial moves, the drum turns, and a phase later (the
--     clock wound back) the next lamp; stopped: lamps dark, dial at 0. The washer-dryer: DRY then WASH set its mode.
--   the washer with no water: its switch does nothing, the band says so
--   the plain controls: with LD.useFace answering false the row holds vanilla's buttons again
-- Everything placed and given is taken away, the switches put back, the character back where they stood.
-- Screenshots/zqa_ldy_*.png; grep "ZEDQA ldy".
local p = getPlayer()
local pn = p:getPlayerNum()
local OC, LD, CT = ZeD.ObjectCards, ZeD.ObjectCardLaundry, ZeD.ContainerControls
local Sc = ZeD.Scale
local function say(s) print("ZEDQA ldy " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function WW() return ZeD_WorldWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ldy_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- after n frames, every frame until cond() is true (at most max frames), then fn
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
if not (OC and LD and CT and OC.kinds.laundry) then say("ERR the laundry card is not loaded"); say("DONE"); return end

-- ---- indoors, with grid power (zedqa_appliances.lua's staging; three powerable squares)
local function sqAt(x, y, z) return getCell():getGridSquare(x, y, z) end
local function freeSq(x, y, z)
    local sq = sqAt(x, y, z)
    local ok = false
    if sq then pcall(function() ok = sq:isFree(false) and not sq:getVehicleContainer() end) end
    return ok and sq or nil
end
local function powerable(x, y, z)
    local sq = freeSq(x, y, z)
    if not sq then return nil end
    if sq:getRoom() then return sq end
    for _, d in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
        local n = sqAt(x + d[1], y + d[2], z)
        if n and n:getRoom() then return sq end
    end
    return nil
end
local function findSpot(cx, cy, cz, R)
    for r = 0, R do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local x, y = cx + dx, cy + dy
                    if freeSq(x, y, cz) and powerable(x - 2, y, cz) and powerable(x + 2, y, cz) and powerable(x, y - 2, cz) then
                        return { x = x + 0.5, y = y + 0.5, z = cz }
                    end
                end
            end
        end
    end
    return nil
end
local STORE = { x0 = 12052, y0 = 7117, x1 = 12069, y1 = 7126 }   -- the Fossoil at West Point
local home = { x = p:getX(), y = p:getY(), z = p:getZ() }
local spot = findSpot(math.floor(home.x), math.floor(home.y), math.floor(home.z), 45)
local travelled, t0 = false, 0
local function moveTo(x, y, z)
    p:teleportTo(x, y, z)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end)
end

-- the game's laundry tiles, by the class their IsoType names (no tile name is assumed)
local function tileFor(cls)
    for i = 0, 47 do
        local name = "appliances_laundry_01_" .. i
        local spr = getSprite(name)
        local props = spr and spr:getProperties()
        if props and props:has("IsoType") and props:get("IsoType") == cls then return name end
    end
    return nil
end
local placed, added = {}, {}
local function placeMachine(cls, dx, dy)
    local tile = tileFor(cls)
    local sq = sqAt(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
    if not (tile and sq) then say("ERR no tile or square for " .. cls .. " (tile " .. tostring(tile) .. ")"); return nil end
    local obj
    local ok, err = pcall(function()
        if cls == "IsoClothingWasher" then obj = IsoClothingWasher.new(getCell(), sq, getSprite(tile))
        elseif cls == "IsoClothingDryer" then obj = IsoClothingDryer.new(getCell(), sq, getSprite(tile))
        else obj = IsoCombinationWasherDryer.new(getCell(), sq, getSprite(tile)) end
    end)
    if not (ok and obj) then say("ERR " .. cls .. " not made: " .. tostring(err)); return nil end
    pcall(function() obj:createContainersFromSpriteProperties() end)
    pcall(function() obj:createFluidContainersFromSpriteProperties() end)
    sq:AddSpecialObject(obj)
    if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
    placed[#placed + 1] = obj
    say(string.format("placed %s (%s) at %d,%d: container %s, powered %s, fluid %s / %s", cls, tile, sq:getX(), sq:getY(),
        tostring(obj:getContainer() and obj:getContainer():getType()), tostring(obj:getContainer() and obj:getContainer():isPowered()),
        tostring(obj:getFluidAmount()), tostring(obj:getFluidCapacity())))
    return obj
end
local function water(obj, litres)
    pcall(function() obj:addFluid(FluidType.Water, litres) end)
    return obj:getFluidAmount() or 0
end

local so = getSandboxOptions()
local elec = so and so:getOptionByName("ElecShutModifier")
local elecWas = elec and elec:getValue()
local hydroWas = getWorld():isHydroPowerOn()
local winsWere = ZeD_CharacterWindow.isOpen()
local instantWas = false
pcall(function() instantWas = p:isTimedActionInstantCheat() end)
local useFaceWas = LD.useFace
local washer, dryer, combo

step(10, function()
    if elec then elec:setValue(99999); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(true)
    pcall(function() p:setTimedActionInstantCheat(true) end)
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    if not spot then
        travelled, t0 = true, getTimestampMs()
        say(string.format("no room in reach of %d,%d: to the Fossoil at West Point", math.floor(home.x), math.floor(home.y)))
        moveTo(math.floor((STORE.x0 + STORE.x1) / 2) + 0.5, math.floor((STORE.y0 + STORE.y1) / 2) + 0.5, 0)
    end
end)
waitFor(5, 3000, function()
    return not travelled or (sqAt(STORE.x0, STORE.y0, 0) ~= nil and sqAt(STORE.x1, STORE.y1, 0) ~= nil and getTimestampMs() - t0 > 9000)
end, function()
    if travelled then spot = findSpot(math.floor((STORE.x0 + STORE.x1) / 2), math.floor((STORE.y0 + STORE.y1) / 2), 0, 12) end
    say(spot and string.format("indoors at %d,%d", math.floor(spot.x), math.floor(spot.y)) or "ERR no powered floor for the three machines")
    if spot then moveTo(spot.x, spot.y, spot.z) end
end)
step(30, function()
    washer = placeMachine("IsoClothingWasher", 2, 0)
    dryer = placeMachine("IsoClothingDryer", -2, 0)
    combo = placeMachine("IsoCombinationWasherDryer", 0, -2)
    if not ZeD_WorldWindow.isOpen() then pcall(ZeD_WorldWindow.open, pn) end
    pcall(function() Mouse.setXY(20, 20) end)
end)

-- ---- helpers on the live card
local function root() return (Sc and Sc.root and Sc.root()) or 1 end
local function card() local w = WW(); return w and w._objectCard end
local function entry() local c = card(); return c and c.entry end
local function zone(fid)
    local c = card()
    for _, z in ipairs((c and (c._lastZones or c._zones)) or {}) do if z.fid == fid then return z end end
    return nil
end
local function press(fid, tag)
    local z = zone(fid)
    if not (z and z.run) then say("FAIL " .. tag .. ": no live control " .. fid); fails = fails + 1; return false end
    z.run(card(), p)
    return true
end
local function liveState()
    local e = entry()
    return e and e.t and e.t._st or {}
end
local function litPhases(st)
    local out = {}
    for _, k in ipairs({ "phWash", "phRinse", "phSpin", "phDry", "phCool" }) do if st[k] then out[#out + 1] = k end end
    return out
end
local function content() local w = WW(); return w and w._mainContent end
local function rowKeys()
    local c = content()
    local keys = {}
    for _, h in ipairs((c and c._cc and c._cc.hits) or {}) do keys[#keys + 1] = tostring(h.key) end
    return keys
end
local function rowHas(pred)
    for _, k in ipairs(rowKeys()) do if pred(k) then return true end end
    return false
end
local function vanillaLaundryKey(k) return k:find("ClothingWasher", 1, true) or k:find("ClothingDryer", 1, true) or k:find("CombinationWasherDryer", 1, true) end

-- one machine through the entry point, the face, the live parts and the presses
local function machine(tag, getObj, pidWant, opts)
    local obj
    step(5, function()
        obj = getObj()
        if not obj then say("FAIL " .. tag .. ": not placed"); fails = fails + 1; return end
        pcall(function() ISTimedActionQueue.clear(p) end)
        if spot then moveTo(spot.x, spot.y, spot.z) end
        if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end
        check(LD.plateId(obj) == pidWant, tag .. ": the class picks the " .. pidWant .. " face (" .. tostring(LD.plateId(obj)) .. ")")
        check(LD.useFace(obj), tag .. ": the face shows (LD.useFace)")
        if opts.water then say(tag .. ": water in " .. tostring(water(obj, opts.water)) .. " L") end
        ZeD_WorldWindow.selectContainer(obj:getContainer(), 120)
    end)
    -- the entry point: the container row's gears button, none of vanilla's laundry buttons
    waitFor(10, 600, function() return rowHas(function(k) return k == "obj:ZeDLaundry" end) end, function()
        say(tag .. ": row " .. table.concat(rowKeys(), " "))
        check(rowHas(function(k) return k == "obj:ZeDLaundry" end), tag .. ": the container row has the gears button")
        check(not rowHas(vanillaLaundryKey), tag .. ": vanilla's laundry buttons give way to it")
        local c = content()
        local idx
        for i, h in ipairs((c and c._cc and c._cc.hits) or {}) do if h.key == "obj:ZeDLaundry" then idx = i end end
        if idx then CT.press(c, idx) end
    end)
    waitFor(10, 300, function() local e = entry(); return e and e.t and e.t._face ~= nil end, function()
        local e, c = entry(), card()
        check(e and e.def.id == "laundry" and e.t.obj == obj, tag .. ": the gears button opens the laundry card on it")
        check(c and math.abs(c:getWidth() - ZeD.T.px(480)) <= 1, tag .. ": the card is the full card")
        if not (e and c) then return end
        local _, wantId = ZeD.Px.pick(pidWant, c._plateRoom or 0)
        say(string.format("%s [root %.2f]: plate room %d, face %s at %dx (want %s)", tag, root(), c._plateRoom or -1, tostring(e.t._face), e.t._k or 0, tostring(wantId)))
        check(e.t._face == wantId, tag .. ": the face that fills the card is drawn")
        local des = ZeD.PhysPx.plates[e.t._face or ""]
        check(des and des.w * (e.t._k or 1) <= (c._plateRoom or 0), tag .. ": it sits inside the card at a whole zoom")
        local ids = {}
        for _, z in ipairs(c._lastZones or {}) do if z.fid and z.fid:sub(1, 4) == "ldy:" then ids[#ids + 1] = z.fid end end
        say(tag .. ": controls " .. table.concat(ids, " "))
        check(zone("ldy:power") ~= nil and zone("ldy:door") ~= nil, tag .. ": power and door are on the face")
        check(zone("ldy:power") and zone("ldy:power").primary, tag .. ": power is the primary stop")
        if opts.combo then check(zone("ldy:mode_wash") ~= nil and zone("ldy:mode_dry") ~= nil, tag .. ": WASH and DRY are on the face") end
        check(e.def.openFocus(e.t) == "ldy:power", tag .. ": the controller lands on power")
        local stops = 0
        for _, el in ipairs(c:buildFocusables(WW())) do if tostring(el.id):sub(1, 4) == "ldy:" then stops = stops + 1 end end
        check(stops == #ids, tag .. ": every click area is a controller stop (" .. stops .. " of " .. #ids .. ")")
        local st = liveState()
        check(st.noPower == false, tag .. ": the no-power lamp is dark with power")
        check(st.running == false and #litPhases(st) == 0 and (st.cycleF or 0) == 0, tag .. ": stopped: phase lamps dark, the dial at 0")
        if opts.water then check((st.water or 0) >= 1, tag .. ": the water meter reads the water in (" .. tostring(st.water) .. " of 5)") end
        if opts.needsWater and not opts.water then check(st.noWater == true, tag .. ": FILL lights with no water") end
        -- a shirt inside: the clothes in the drum
        local shirt = obj:getContainer():AddItem("Base.Tshirt_DefaultTEXTURE_TINT")
        if shirt then added[#added + 1] = shirt end
        shot(tag .. "_1_open")
    end)
    step(30, function()
        check(liveState().hasItems == true, tag .. ": the clothes show with a shirt inside")
        press("ldy:door", tag)
    end)
    step(20, function()
        local c = content()
        check(c and c._inventory == obj:getContainer(), tag .. ": the door shows its contents in the Loot pane")
    end)
    if opts.combo then
        step(5, function() press("ldy:mode_dry", tag) end)
        waitFor(10, 600, function() return obj:isModeDryer() end, function()
            check(obj:isModeDryer(), tag .. ": DRY sets dryer mode")
        end)
        step(30, function()
            local st = liveState()
            check(st.modeDry == true and st.modeWash == false, tag .. ": the DRY lamp lights")
            press("ldy:mode_wash", tag)
        end)
        waitFor(10, 600, function() return obj:isModeWasher() end, function()
            check(obj:isModeWasher(), tag .. ": WASH sets washer mode")
        end)
    end
    if opts.water or not opts.needsWater then
        step(20, function() press("ldy:power", tag) end)
        waitFor(10, 600, function() return obj:isActivated() end, function()
            check(obj:isActivated(), tag .. ": power starts it (vanilla's action)")
        end)
        local drum0
        step(30, function()
            local st = liveState()
            local lit = litPhases(st)
            drum0 = st.drumF
            say(tag .. ": running, lamps " .. table.concat(lit, " ") .. ", dial " .. tostring(st.cycleF) .. ", drum " .. tostring(st.drumF))
            check(st.running == true, tag .. ": the run lamp lights")
            check(#lit == 1 and lit[1] == opts.first, tag .. ": one phase lamp, the first (" .. tostring(opts.first) .. ")")
            shot(tag .. "_2_running")
            -- a phase later: the clock wound back PHASE_MIN + 1 game minutes
            local run = LD._run[entry().t.key]
            if run then run.min = run.min - (LD.PHASE_MIN + 1) end
        end)
        step(20, function()
            local st = liveState()
            local lit = litPhases(st)
            check(#lit == 1 and lit[1] == opts.second, tag .. ": the next phase lamp a phase later (" .. table.concat(lit, " ") .. ")")
            check((st.cycleF or 0) > 0 and (st.cycleF or 0) < 1, tag .. ": the cycle dial moves (" .. tostring(st.cycleF) .. ")")
            check(st.drumF ~= drum0, tag .. ": the drum turns")
            press("ldy:power", tag)
        end)
        waitFor(10, 600, function() return not obj:isActivated() end, function()
            check(not obj:isActivated(), tag .. ": power stops it")
        end)
        step(20, function()
            local st = liveState()
            check(#litPhases(st) == 0 and st.cycleF == 0, tag .. ": stopped again: lamps dark, the dial at 0")
        end)
    else
        step(20, function()
            local z = zone("ldy:power")
            check(z and z.run == nil, tag .. ": with no water the switch does nothing")
            local e = entry()
            local s = e and e.def.status(e.t)
            say(tag .. ": band " .. tostring(s and s.text))
            check(s ~= nil, tag .. ": the band says what it needs")
            shot(tag .. "_2_nowater")
        end)
    end
    -- the plain controls, through the one switch
    step(5, function()
        LD.useFace = function() return false end
        local c = content()
        if c and c._cc then c._cc.frame = -1000 end
    end)
    step(30, function()
        say(tag .. ": plain row " .. table.concat(rowKeys(), " "))
        check(not rowHas(function(k) return k == "obj:ZeDLaundry" end), tag .. ": LD.useFace false: no gears button")
        if opts.plainVisible then check(rowHas(vanillaLaundryKey), tag .. ": LD.useFace false: vanilla's own laundry buttons are back") end
        LD.useFace = useFaceWas
        local c = content()
        if c and c._cc then c._cc.frame = -1000 end
        if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end
    end)
end

-- the washer without water first (vanilla hides its switch then: no plain button either), then with water
machine("washer_dry", function() return washer end, "washer", { needsWater = true, plainVisible = false })
machine("washer", function() return washer end, "washer", { needsWater = true, water = 20, first = "phWash", second = "phRinse", plainVisible = true })
machine("dryer", function() return dryer end, "dryer", { first = "phDry", second = "phCool", plainVisible = true })
machine("combo", function() return combo end, "washer_dryer", { combo = true, needsWater = true, water = 20, first = "phWash", second = "phRinse", plainVisible = true })

step(20, function()
    LD.useFace = useFaceWas
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
    for _, it in ipairs(added) do local c = it:getContainer(); if c then pcall(function() c:Remove(it) end) end end
    for _, obj in ipairs(placed) do
        pcall(function() if obj:isActivated() then obj:setActivated(false) end end)
        local sq = obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end
    end
    if elec and elecWas ~= nil then elec:setValue(elecWas); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(hydroWas)
    pcall(function() p:setTimedActionInstantCheat(instantWas) end)
    if winsWere and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    if spot or travelled then moveTo(home.x, home.y, home.z); t0 = getTimestampMs() end
    say("cleanup done: " .. #placed .. " machines removed, " .. #added .. " items taken back")
end)
waitFor(5, 3000, function()
    return not travelled or (sqAt(math.floor(home.x), math.floor(home.y), math.floor(home.z)) ~= nil and getTimestampMs() - t0 > 3000)
end, function()
    say(string.format("back at %d,%d", math.floor(p:getX()), math.floor(p:getY())))
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    if s.cond then
        s.left = (s.left or s.max) - 1
        local ok, done = pcall(s.cond)
        if not (ok and done) and s.left > 0 then wait = 1; return end
        if not (ok and done) then say("WARN step " .. qi .. ": waited " .. s.max .. " frames, the condition never held") end
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
