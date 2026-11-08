-- ZeDUI/tools/qa/zedqa_b8_world_devices.lua  (Nov 7 2026, QA; CHECK_world_devices_20261107.md parts 1 to 3)
-- Every way into the game's radio window goes to ZeD's Radio tab (WorldRoutes.lua, Overrides/RadioWindow.lua). The script
-- calls the game's own entry, ISRadioWindow.activate(player, device), which every click, menu option and wheel slice ends in,
-- and checks that ZeD's tab opens on that device and the game's gray window does not:
--   TV near / house radio / TV across the room (pinned, "Floor") / the pin kept while walking about and dropped past 10 tiles,
--   not brought back on the way back / a TV 13 tiles away (the game's own behavior: no pin) / a carried radio and a walkie
--   (Character window, Radio tab, on that radio) / a car's radio part from outside (pill "Vehicle") / the car's radio from the
--   driver's seat (up close, no window) / the radio taken out of the car (the part drops off).
-- Puts everything back: sets and cars removed, hands emptied, windows as the prelude left them.
-- Not scripted (manual): a real click on a TV, the stairs (1.5a to 1.5c), a placed portable radio (1.7), the item card (1.8),
-- the controller, Deck size, split screen, safe mode (6.x). grep "ZEDQA b8wd"; shots zqa_b8wd_*.png.
local TAG = "b8wd"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
local p = getPlayer()
local pn = p and p:getPlayerNum() or 0
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local RT, WR = ZeD and ZeD.RadioTab, ZeD and ZeD.WorldRoutes
if not (p and CW and WW and RT and WR) then say("ERR ZeD's windows or routes are not loaded"); say("DONE"); return end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8wd_" .. n .. ".png") end) end
local function cw() return CW.getWindow() end
local function ww() return WW.getWindow() end
local function keepDown(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
local function holdBoth() keepDown(cw()); keepDown(ww()) end

-- the step list: step(waitTicks, fn) runs fn that many ticks after the step before; waitFor(max, cond, fn) runs fn when cond holds (fn(timedOut))
local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end
local function waitFor(max, cond, fn) Q[#Q + 1] = { max = max, cond = cond, fn = fn } end
local cleanups = {}
local function onCleanup(fn) cleanups[#cleanups + 1] = fn end
local ticker
local function finish()
    for i = #cleanups, 1, -1 do local ok, e = pcall(cleanups[i]); if not ok then say("ERR cleanup " .. i .. ": " .. tostring(e)) end end
    cleanups = {}
    say("checks: passes=" .. passes .. " misses=" .. misses)
    say("DONE")
end
local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(ticker); finish(); return end
    qc = qc + 1
    local go, timedOut = false, false
    if s.cond then
        local ok, v = pcall(s.cond)
        if ok and v then go = true elseif qc >= s.max then go, timedOut = true, true end
    else
        go = qc >= s.wait
    end
    if go then
        qi = qi + 1; qc = 0
        local ok, e = pcall(s.fn, timedOut)
        if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(e)) end
    end
end

-- ---- helpers
local HOME = { x = p:getX(), y = p:getY() }
local function warp(x, y) p:setX(x); p:setY(y); p:setLastX(x); p:setLastY(y) end
local px, py = math.floor(p:getX()), math.floor(p:getY())
local function sqAt(dx, dy) return getCell():getGridSquare(px + dx, py + dy, 0) end
local placed = {}
local function putSet(tv, spr, sq)
    if not (sq and getSprite(spr)) then return nil end
    local obj
    if tv then obj = IsoTelevision.new(getCell(), sq, getSprite(spr)) else obj = IsoRadio.new(getCell(), sq, getSprite(spr)) end
    sq:AddTileObject(obj)
    local d = obj:getDeviceData()
    if d then d:setIsTurnedOn(false); d:setDeviceVolume(0.5) end
    placed[#placed + 1] = obj
    return obj
end
onCleanup(function()
    for _, obj in ipairs(placed) do
        local sq = obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end
    end
    placed = {}
end)
local function vanillaUp()
    for _, t in ipairs({ ISRadioWindow.instances, ISRadioWindow.instancesIso }) do
        local w = t and t[pn]
        if w and w:isVisible() then return true end
    end
    return false
end
local function closeVanilla()
    for _, t in ipairs({ ISRadioWindow.instances, ISRadioWindow.instancesIso }) do
        local w = t and t[pn]
        if w then pcall(function() w:setVisible(false); w:removeFromUIManager() end); t[pn] = nil end
    end
end
onCleanup(closeVanilla)
local function bothShut()
    if CW.isOpen() or WW.isOpen() then
        if CW.isOpen() then pcall(CW.toggle, pn) end
        if WW.isOpen() then pcall(WW.close) end
    end
end
-- the Radio tab's current entry in the World window
local function worldCur() local w = ww(); return w and w._radios and w._radios[w._radioIdx] or nil end
local function onRadioTab() return ww() ~= nil and WW.isTabShowing and WW.isTabShowing("radio") == true end
local function activate(dev)
    local ok, e = pcall(ISRadioWindow.activate, p, dev)
    if not ok then say("ERR activate: " .. tostring(e)) end
end
local wasOpen = { cw = CW.isOpen(), ww = WW.isOpen() }
local inv = p:getInventory()
local given = {}
local function give(ft) local it = inv:AddItem(ft); if it then given[#given + 1] = it end; return it end
onCleanup(function()
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    for _, it in ipairs(given) do pcall(function() inv:Remove(it) end) end
    given = {}
    -- the windows as the prelude left them
    if wasOpen.cw and not CW.isOpen() then pcall(CW.toggle, pn) end
    if wasOpen.ww and not WW.isOpen() then pcall(WW.open, pn) end
    warp(HOME.x, HOME.y)
end)

local tvNear, tvFar, tvOut, house
local car, spawned = nil, {}
onCleanup(function() for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end; spawned = {} end)

-- ---- setup
step(1, function()
    p:setGodMod(true)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    tvNear = putSet(true, "appliances_television_01_1", sqAt(1, 1))
    house = putSet(false, "appliances_radio_01_9", sqAt(-1, 1))
    tvFar = putSet(true, "appliances_television_01_5", sqAt(6, 3))
    tvOut = putSet(true, "appliances_television_01_9", sqAt(13, 0))
    check(tvNear and house and tvFar and tvOut, "setup: a TV beside, a house radio, a TV across the room (6,3) and a TV 13 tiles off")
    closeVanilla()
    bothShut()
end)

-- ---- 1.1 left-click / Device Options on a TV beside the character, windows shut
step(25, function()
    check(not CW.isOpen() and not WW.isOpen(), "1.1: both windows start shut")
    activate(tvNear)
end)
waitFor(120, function() return onRadioTab() end, function(t)
    holdBoth()
    check(not t and ww() ~= nil and ww():isVisible(), "1.1: the World window opens on the Radio tab")
    local cur = worldCur()
    check(cur and cur.radioInstance == tvNear, "1.1: on that TV (" .. tostring(cur and cur.locationTag) .. ")")
    check(not vanillaUp(), "1.1: the game's radio window did not show")
end)
-- 1.6 the house radio, windows already open
step(10, function() activate(house) end)
step(20, function()
    holdBoth()
    local cur = worldCur()
    check(cur and cur.radioInstance == house, "1.6: the house radio, with the windows already open")
    check(not vanillaUp(), "1.6: the game's radio window did not show")
end)

-- ---- 1.2 the TV across the room, pinned
step(5, function() activate(tvFar) end)
step(25, function()
    holdBoth()
    local cur = worldCur()
    check(cur and cur.radioInstance == tvFar, "1.2: the Radio tab is on the far TV")
    check(cur and cur.pinned == true and cur.locationTag == "Floor", "1.2: pinned, the pill reads Floor (tag " .. tostring(cur and cur.locationTag) .. ")")
    check(WR.pins[pn] == tvFar, "1.2: WorldRoutes holds the pin")
    check(not vanillaUp(), "1.2: the game's radio window did not show")
end)
step(20, function() shot("tv_far") end)
-- 1.3 walk 3 tiles toward it: the tab stays
step(5, function() warp(HOME.x + 3, HOME.y) end)
step(70, function()
    holdBoth()
    local cur = worldCur()
    check(cur and cur.radioInstance == tvFar, "1.3: still on the far TV after walking 3 tiles toward it and the list re-sorting")
    warp(HOME.x, HOME.y)
end)
step(40, function()
    holdBoth()
    local cur = worldCur()
    check(cur and cur.radioInstance == tvFar, "1.3: and after walking back")
end)
-- 1.4 more than 10 tiles away: the TV drops off; back: it does not return
step(5, function() warp(HOME.x - 14, HOME.y) end)
step(70, function()
    holdBoth()
    check(WR.pins[pn] == nil, "1.4: past 10 tiles the pin drops")
    check(RT.indexOf(RT.buildWorldRadios(p), tvFar) == nil, "1.4: the far TV is off the Radio tab's list")
    warp(HOME.x, HOME.y)
end)
step(70, function()
    holdBoth()
    check(RT.indexOf(RT.buildWorldRadios(p), tvFar) == nil, "1.4: walking back does not bring it back")
end)
-- 1.5 a TV more than 10 tiles away: the game's own behavior
step(5, function()
    bothShut()
end)
step(20, function()
    activate(tvOut)
end)
step(30, function()
    check(WR.pins[pn] == nil, "1.5: a TV 13 tiles away is not pinned")
    check(not WW.isOpen() or not onRadioTab(), "1.5: ZeD's Radio tab did not open for it")
    say("NOTE 1.5: the game's own window for a far TV opens and closes by itself; it showed: " .. tostring(vanillaUp()))
    closeVanilla()
end)

-- ---- 2. a carried radio and a walkie (Character window, Radio tab)
local radio1, walkie
step(5, function()
    bothShut()
    radio1 = give("Base.RadioBlack")
    walkie = give("Base.WalkieTalkie1")
    check(radio1 and walkie, "2: a portable radio and a walkie given")
    if radio1 then p:setPrimaryHandItem(radio1) end
    if walkie then p:setSecondaryHandItem(walkie) end
end)
step(25, function() activate(radio1) end)
waitFor(120, function() return cw() ~= nil and cw()._activeTab == "radio" end, function(t)
    holdBoth()
    check(not t and cw() ~= nil, "2.1: the Character window opens on the Radio tab")
    local w = cw()
    local cur = w and w._radios and w._radios[w._radioIdx]
    check(cur and cur.radioInstance == radio1, "2.1: on the radio in the main hand")
    check(not vanillaUp(), "2.1: the game's radio window did not show")
end)
step(10, function() activate(walkie) end)
step(25, function()
    holdBoth()
    local w = cw()
    local cur = w and w._radios and w._radios[w._radioIdx]
    check(cur and cur.radioInstance == walkie, "2.2: on the walkie, not on the first radio")
    check(not vanillaUp(), "2.2: the game's radio window did not show")
end)
step(20, function() shot("walkie") end)
step(5, function()
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
    for _, it in ipairs(given) do pcall(function() inv:Remove(it) end) end
    given = {}
    bothShut()
end)

-- ---- 3. a car's radio part
local part
step(15, function()
    local sq = sqAt(-4, -4)
    if sq then
        local ok, v = pcall(addVehicleDebug, "Base.PickUpTruck", IsoDirections.N, nil, sq)
        if ZEDQA_VPROBE then ZEDQA_VPROBE(TAG, sq, ok and v or nil) end
        if ok and v then car = v; spawned[#spawned + 1] = v end
    end
    if not car then say("NOTE 3: no car could be spawned; the car checks are skipped"); return end
    part = car:getPartById("Radio")
    if part and not part:getInventoryItem() then
        pcall(function()
            part:setInventoryItem(instanceItem("Base.RadioRed"))
            Vehicles.InstallComplete.Radio(car, part)
            local dd = part:getDeviceData()
            if dd:getDevicePresets():getPresets():size() == 0 then dd:generatePresets() end
        end)
    end
    check(part ~= nil and part:getInventoryItem() ~= nil and part:getDeviceData() ~= nil, "3: the car has a radio part with a radio in it")
end)
-- the car needs a few ticks to settle on its square
step(40, function()
    if not (car and part) then return end
    activate(part)
end)
step(30, function()
    if not (car and part) then return end
    holdBoth()
    local cur = worldCur()
    check(cur and cur.radioInstance == part, "3.2: from outside the car the World window's Radio tab is on the car's radio")
    check(cur and cur.locationTag == "Vehicle", "3.2: the pill reads Vehicle (tag " .. tostring(cur and cur.locationTag) .. ")")
    check(not vanillaUp(), "3.2: the game's radio window did not show")
end)
step(20, function() if car then shot("car_part") end end)
-- 3.4 the radio taken out of the car
step(5, function()
    if not (car and part) then return end
    pcall(function() part:setInventoryItem(nil) end)
end)
step(70, function()
    if not (car and part) then return end
    holdBoth()
    check(RT.indexOf(RT.buildWorldRadios(p), part) == nil, "3.4: with the radio taken out the part drops off the tab")
    pcall(function()
        part:setInventoryItem(instanceItem("Base.RadioRed"))
        Vehicles.InstallComplete.Radio(car, part)
        local dd = part:getDeviceData()
        if dd:getDevicePresets():getPresets():size() == 0 then dd:generatePresets() end
    end)
    bothShut()
    WR.unpin(p)
end)
-- 3.1 the driver's seat: the car's radio comes up close, no window
step(20, function()
    if not (car and part) then return end
    if car:DistTo(p) > 12 then say("NOTE 3.1: the car is " .. car:DistTo(p) .. " tiles off; not entering a far vehicle"); return end
    car:enter(0, p); triggerEvent("OnEnterVehicle", p)
end)
step(40, function()
    if not (car and part) or p:getVehicle() ~= car then return end
    pcall(function() car:setKeysInIgnition(true) end)
    activate(part)
end)
step(40, function()
    if not (car and part) or p:getVehicle() ~= car then return end
    local CR = ZeD.CarRadio
    local prop = CR and CR.props and CR.props[pn]
    check(prop ~= nil and prop:isReallyVisible(), "3.1: from the driver's seat the car radio comes up close")
    check(not vanillaUp(), "3.1: the game's radio window did not show")
    check(not WW.isOpen() or not onRadioTab(), "3.1: and no World window Radio tab")
    shot("car_close")
    if CR and CR.closeFor then pcall(CR.closeFor, pn) end
end)
step(10, function()
    if p:getVehicle() then car:exit(p); triggerEvent("OnExitVehicle", p) end
end)
step(20, function() end)

ticker = onTick
Events.OnTick.Add(ticker)
say("start")
