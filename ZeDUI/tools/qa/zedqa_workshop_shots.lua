-- ZeDUI/tools/qa/zedqa_workshop_shots.lua  (Oct 20 2026)
-- Steam Workshop screenshots: clean, good-looking scenes of ZeD-UI, staged in a
-- town street, each one a full-resolution getCore():TakeFullScreenshot of
-- ws_<nn>_<name>.png in Zomboid/Screenshots. Meant for the ZeD-QA save
-- (Saves/Sandbox/ZeD-QA: no zombies, whole map revealed, -debug) at 4K
-- fullscreen, game unpaused. NOT in regression.txt: it moves the character far,
-- builds a crate and spawns a car (all put back), and it needs the test language
-- Off (it asserts that at the start and stops if it is On).
--
-- The tag is "wsh", not "ws": "ws" is already zedqa_wheel_sizes.lua's in
-- regression.txt. Change TAG below if the caller wants another. Output:
--   ZEDQA wsh <nn> <name> ok       a shot taken
--   ZEDQA wsh <nn> ERR <reason>    a shot that could not be staged (the walk goes on)
--   ZEDQA wsh DONE                 last line, after everything is put back
--
-- Place: Muldraugh (houses around 10737,10234, then three more streets there),
-- West Point (11300,6700 and two more) and, last, the QA field. After the
-- teleport it waits ~9 s for the cell to load, then scans the loaded squares
-- for a clear stretch of road (3 x 6 squares, car sized) with a clear
-- sidewalk or grass square beside it for the character and one next to that
-- for a crate, and prefers spots with houses around.
-- Time is set to 10:00 and the weather cleared (fog, rain, clouds forced to 0);
-- the car scene sets 22:00 for the night shot.
--
-- Shots (the numbers are the brief's; 26 and 27 are extras taken in the car):
--   01 both windows over the street (Character on Loot, World showing the crate)
--   02 item card on a food (nutrition label)   03 item card on a weapon
--   04 Health, body figure   05 Health, an exercise chosen   06 Equip, doll
--   07 Skills   08 Maps Survey   09 Maps Color   10 Maps Paper
--   11 flyer map pins with a hover card   12 Crafting with a recipe open
--   13 context menu strip   14 context menu list
--   15 belt + mini watch (HUD only)   16 the popped full watch
--   17 the action bar during a timed action (reading)   18 car by day: dash + radio
--   19 the same at night, lights on   20 the emote wheel
--   21 the World window curtain rolled up   22 Options page (ZeD setup) in the pause menu
--   23 clean wide gameplay shot, HUD only (belt, moodles)
--   24 windows open, the character looting the crate
--   26 the vehicle wheel in the car   27 the car radio up close
-- Everything is put back: position, time, weather, the kit (bag, belt, hat,
-- jacket, watch, weapon, food, walkie), the crate and its items, the car and
-- its key, hands, worn items, the options set for the shots, view choices, map
-- style, windows, game speed, stats, debug console.
-- Driven from OnRenderTick (the pause menu stops OnTick). grep "ZEDQA wsh".
local TAG = "wsh"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
if not (ZeD and ZeD.Settings and ZeD.trTestOn and ZeD_CharacterWindow and ZeD_WorldWindow) then say("ERR ZeD is not loaded"); return end
if ZeD.trTestOn() then say("ERR the test language is On: turn it Off first, the shots must not show stretched text; nothing was touched"); return end
if ZeD.Safe and ZeD.Safe.on() then say("ERR safe mode is on: the ZeD windows are off; nothing was touched"); return end

local pn = p:getPlayerNum()
local inv = p:getInventory()
local core = getCore()
local gt = getGameTime()
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local MM = ZeD.MainMenu
local RO, CR = ZeD.RadioOps, ZeD.CarRadio
local Opt = ZeD.Settings
local ctxOpt, watchOpt, barOpt = Opt.contextStyleOption, Opt.watchPlaceOption, Opt.actionBarOption
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function zm() local v = getPlayerContextMenu(pn); return v and v._zedMenu end

-- ---------------------------------------------------------------------------
-- What there was, to put back
-- ---------------------------------------------------------------------------
local gvStore = p:getModData().ZeD_GridViews
local was = {
    x = p:getX(), y = p:getY(), z = p:getZ(),
    tod = gt:getTimeOfDay(), speed = getGameSpeed(),
    ctx = ctxOpt:getValue(), watch = watchOpt:getValue(), bar = barOpt:getValue(),
    equip = ZeD.EquipDoll.view(), grid = gvStore and gvStore.player,
    pop = p:getModData().ZeD_WatchPop,
    prim = p:getPrimaryHandItem(), sec = p:getSecondaryHandItem(),
    char = CWm.isOpen(), world = WWm.isOpen(),
    cwTab = CW() and CW()._activeTab, wwTab = WW() and WW()._activeTab,
    cheat = false, mapStyle = nil, hunger = nil, thirst = nil, exSel = nil,
}
pcall(function() was.cheat = p:isBuildCheat() end)
pcall(function() was.hunger = p:getStats():get(CharacterStat.HUNGER); was.thirst = p:getStats():get(CharacterStat.THIRST) end)

-- ---------------------------------------------------------------------------
-- State shared by the steps (one table: a chunk may declare only so many locals)
-- ---------------------------------------------------------------------------
local X = {
    added = {}, worn = {}, attached = {}, crateItems = {},
    crate = nil, crateInv = nil, crateSq = nil,
    spot = nil,                -- { px, py, cx, cy (crate), carX, carY, axis, note }
    car = nil, key = nil, entered = false, carDir = nil,
    clim = {}, hidden = {}, flyerAdded = {}, flyerSeen = nil,
    nOk = 0, nErr = 0, mapZoom = 15,
    jumpAbort = false, tripped = false,
}
local tick, qi, lastDone = 0, 1, 0
local startMs = getTimestampMs()
local queue, marks = {}, {}
local sc = { ok = true, why = "" }     -- the scene being staged

local function shot(nn, name)
    local f = string.format("ws_%02d_%s.png", nn, name)
    local ok, e = pcall(function() core:TakeFullScreenshot(f) end)
    if ok then X.nOk = X.nOk + 1; say(string.format("%02d %s ok", nn, name))
    else X.nErr = X.nErr + 1; say(string.format("%02d ERR %s: %s", nn, name, tostring(e))) end
end
local function err(nn, reason)
    X.nErr = X.nErr + 1
    say(string.format("%02d ERR %s", nn, tostring(reason)))
end

-- ---------------------------------------------------------------------------
-- The sequencer (as zedqa_testlang.lua): step(after, fn) runs fn once, `after`
-- frames after the step before it ended; poll(after, max, fn, onTimeout) runs
-- fn every frame until it returns true. A failing step prints ERR, the walk
-- goes on.
-- ---------------------------------------------------------------------------
local function step(after, fn) queue[#queue + 1] = { after = after, fn = fn } end
local function poll(after, max, fn, onTimeout) queue[#queue + 1] = { after = after, fn = fn, max = max, timeout = onTimeout } end
local function mark(name) marks[name] = #queue + 1 end
local function noop() end
local function waitMs(ms)
    local t0 = nil
    poll(0, math.floor(ms / 3) + 900, function()
        t0 = t0 or getTimestampMs()
        return getTimestampMs() - t0 >= ms
    end)
end

-- ---------------------------------------------------------------------------
-- Windows and tabs (zedqa_testlang.lua)
-- ---------------------------------------------------------------------------
local function closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
end
local function openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
end
local function goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function charTab(id) local w = CW(); return (w and goTab(w, w._tabStripPanel, id)) and true or false end
local function worldTab(id) local w = WW(); return (w and goTab(w, w._actionTabStrip, id)) and true or false end

-- an item selected in the Character window's Loot list opens its card (nil closes it)
local function selectItem(item)
    local w = CW()
    local c = w and w._mainContent
    if not c then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end

local function openRecipe(kind)   -- "craft" | "build": the first recipe the character can make
    local w = WW()
    if not w then return false, "no World window" end
    local mod = (kind == "craft") and ZeD.CraftingTab or ZeD.BuildingTab
    local st = (kind == "craft") and w._craftState or w._buildState
    if not st then return false, "no " .. kind .. " state" end
    local data = mod.gatherData(p, w)
    local pick = nil
    for _, rd in ipairs(data and data.recipes or {}) do
        if rd.status == "unlocked" then pick = rd; break end
    end
    pick = pick or (data and data.recipes and data.recipes[1])
    if not pick then return false, "no recipe to open in " .. kind end
    ZeD.CraftingCore.openCraft(st, pick.entry.name)
    say("recipe open in " .. kind .. ": " .. tostring(pick.entry.name))
    return true
end
local function closeRecipe(kind)
    local w = WW()
    local st = w and ((kind == "craft") and w._craftState or w._buildState)
    if st then ZeD.CraftingCore.closeCraft(st) end
end

-- ---------------------------------------------------------------------------
-- A scene: setup (may return false, reason), settle, shot. T also goes to a tab.
-- ---------------------------------------------------------------------------
local function runSetup(fn)
    sc.ok, sc.why = true, ""
    if not fn then return end
    local ok, a, b = pcall(fn)
    if not ok then sc.ok, sc.why = false, tostring(a)
    elseif a == false then sc.ok, sc.why = false, tostring(b or "setup refused") end
end
local function finishShot(nn, name)
    if sc.ok then shot(nn, name) else err(nn, name .. ": " .. sc.why) end
end
local function S(nn, name, settle, fn)
    step(2, function() runSetup(fn) end)
    step(settle or 30, function() finishShot(nn, name) end)
end
local function T(nn, name, which, tabId, settle, fn)
    step(2, function() sc.ok, sc.why = true, "" end)
    poll(2, 120, function()
        if which == "c" then return charTab(tabId) end
        return worldTab(tabId)
    end, function() sc.ok = false; sc.why = "tab " .. tabId .. " is not on the strip" end)
    step(6, function() if sc.ok then runSetup(fn) end end)
    step(settle or 30, function() finishShot(nn, name) end)
end

-- ---------------------------------------------------------------------------
-- Items
-- ---------------------------------------------------------------------------
local function give(full, container, name)
    local it = (container or inv):AddItem(full)
    if it then
        X.added[#X.added + 1] = it
        if name then pcall(function() it:setName(name); it:setCustomName(true) end) end
    else
        say("note: could not add " .. full)
    end
    return it
end
local function found(full)
    for _, it in ipairs(X.added) do
        local ok, hit = pcall(function() return it:getFullType() == full end)
        if ok and hit then return it end
    end
    return nil
end
-- worn only into a free place: nothing the character wears is displaced
local function wear(full)
    local it = inv:AddItem(full)
    if not it then say("note: could not add " .. full); return nil end
    local busy = false
    pcall(function() busy = p:getWornItem(it:getBodyLocation()) ~= nil end)
    if busy then inv:Remove(it); say("note: " .. full .. " not worn, the place is taken"); return nil end
    p:setWornItem(it:getBodyLocation(), it)
    X.worn[#X.worn + 1] = it
    return it
end
local function beltAttach(it)
    local hb = ZeD.Belt and ZeD.Belt.hotbar(pn)
    if not (hb and it) then return false end
    for i, slot in ipairs(hb.availableSlot or {}) do
        if not hb.attachedItems[i] and ZeD.Belt.fits(hb, i, it) then
            local ok = pcall(function() hb:attachItem(it, slot.def.attachments[it:getAttachmentType()], i, slot.def, false) end)
            if ok and hb.attachedItems[i] == it then X.attached[#X.attached + 1] = it; return true end
        end
    end
    return false
end

-- the believable kit: worn belt, cap, jacket, backpack and watch; a weapon in hand; a walkie and
-- tools on the belt; food, water, medical and tools in the bag
local function giveKit()
    wear("Base.Belt2")
    wear("Base.Hat_BaseballCapBlue")
    wear("Base.Jacket_Varsity")
    local bag = nil
    pcall(function() bag = p:getClothingItem_Back() end)
    if not bag then bag = wear("Base.Bag_Schoolbag") end
    local bagInv = nil
    if bag then pcall(function() bagInv = bag:getInventory() end) end
    if not bagInv then say("note: no backpack, the items go loose") end
    local into = bagInv or inv
    for _, ft in ipairs({ "Base.Saw", "Base.Rope", "Base.Bandage", "Base.Bandage", "Base.TinnedBeans", "Base.Crisps",
                          "Base.Banana", "Base.BeefJerky", "Base.Matches", "Base.Nails" }) do give(ft, into) end
    local bottle = give("Base.WaterBottle", into)
    if bottle then pcall(function() bottle:getFluidContainer():addFluid("Water", 0.6) end) end
    -- loose in the main inventory: the cards and menus are made on these
    give("Base.Apple"); give("Base.Apple"); give("Base.Chocolate")
    give("Base.Machete")
    give("Base.Book")
    local watch = nil
    if not (ZeD.Watch and ZeD.Watch.beltWatch(p)) then watch = wear("Base.WristWatch_Left_DigitalBlack") end
    triggerEvent("OnClothingUpdated", p)
    local hb = ZeD.Belt and ZeD.Belt.hotbar(pn)
    if hb then pcall(function() hb:refresh() end) end
    local walkie = give("Base.WalkieTalkie2")
    if walkie and not beltAttach(walkie) then say("note: the walkie-talkie did not fit a belt slot") end
    local hammer = give("Base.Hammer")
    if hammer and not beltAttach(hammer) then say("note: the hammer did not fit a belt slot") end
    local crow = give("Base.Crowbar")
    if crow then
        p:setPrimaryHandItem(crow)
        local both = false
        pcall(function() both = crow:isRequiresEquippedBothHands() end)
        if both then p:setSecondaryHandItem(crow) end
    end
    say("kit: worn " .. #X.worn .. ", on the belt " .. #X.attached .. ", added " .. #X.added .. ", watch " .. tostring(ZeD.Watch.beltWatch(p) ~= nil))
end

-- ---------------------------------------------------------------------------
-- Weather and time
-- ---------------------------------------------------------------------------
local function clearWeather()
    local cm = getClimateManager()
    for i = 0, cm:getFloatMax() - 1 do
        local v = cm:getClimateFloat(i)
        local n = tostring(v:getName()):lower()
        if n:find("fog", 1, true) or n:find("precip", 1, true) or n:find("cloud", 1, true) then
            X.clim[#X.clim + 1] = { v = v, en = v:isEnableAdmin(), val = v:getAdminValue() }
            v:setEnableAdmin(true)
            v:setAdminValue(0)
        end
    end
end
local function restoreWeather()
    for _, c in ipairs(X.clim) do
        pcall(function() c.v:setAdminValue(c.val); c.v:setEnableAdmin(c.en) end)
    end
    X.clim = {}
end

-- ---------------------------------------------------------------------------
-- The town search
-- ---------------------------------------------------------------------------
local H = {
    R = 24,    -- scan radius around an anchor
    ANCH = {
        { 10737, 10234, "Muldraugh, houses north east of the crossroads" },
        { 10650, 10267, "Muldraugh, houses on the west side" },
        { 10815, 10037, "Muldraugh, houses further north" },
        { 10720, 9990, "Muldraugh, north street" },
        { 11300, 6700, "West Point, north east streets" },
        { 11190, 6800, "West Point, centre" },
        { 11940, 7010, "West Point, east" },
        { math.floor(was.x), math.floor(was.y), "the QA field (no town found)" },
    },
}
local L = { i = 0, ph = "next", t0 = 0, row = 0, pass = 1, best = nil, a = nil }

local function tp(x, y, z)
    p:teleportTo(x, y, z or 0)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z or 0); p:setLastX(x); p:setLastY(y); p:setLastZ(z or 0) end)
end
local function sqAt(x, y) return getCell():getGridSquare(x, y, 0) end
local function isRoad(sq)
    if not sq then return false end
    local name = ""
    pcall(function() name = tostring(sq:getFloor():getSprite():getName()) end)
    return name:find("street", 1, true) ~= nil
end
local function clear(sq)
    if not sq or not sq:isOutside() or not sq:getFloor() then return false end
    if not sq:isFree(false) or sq:HasTree() or sq:getVehicleContainer() then return false end
    if sq:getProperties():has(IsoFlagType.water) then return false end
    return true
end
local function neighbours(px, py)
    local n = 0
    if clear(sqAt(px + 1, py)) then n = n + 1 end
    if clear(sqAt(px - 1, py)) then n = n + 1 end
    if clear(sqAt(px, py + 1)) then n = n + 1 end
    if clear(sqAt(px, py - 1)) then n = n + 1 end
    return n
end
-- a car-sized clear stretch (3 x 6, lying along y for axis 1, along x for axis 2)
local function rectOk(x, y, axis, needRoad)
    local nx, ny = 2, 5
    if axis == 2 then nx, ny = 5, 2 end
    local roads = 0
    for dy = 0, ny do
        for dx = 0, nx do
            local s = sqAt(x + dx, y + dy)
            if not clear(s) then return false end
            if isRoad(s) then roads = roads + 1 end
        end
    end
    if needRoad and roads < 16 then return false end
    return true
end
-- the character's square beside the stretch, and the crate's beside that
local function sideSpot(x, y, axis)
    for k = 0, 4 do
        for side = 1, 2 do
            local px, py, ox, oy
            if axis == 1 then
                py = y + 3; oy = 0
                if side == 1 then px = x - 2 - k; ox = -1 else px = x + 4 + k; ox = 1 end
            else
                px = x + 3; ox = 0
                if side == 1 then py = y - 2 - k; oy = -1 else py = y + 4 + k; oy = 1 end
            end
            local s = sqAt(px, py)
            if clear(s) and not isRoad(s) and neighbours(px, py) >= 3 then
                local cx, cy = px + ox, py + oy
                if not clear(sqAt(cx, cy)) then
                    cx, cy = px + oy, py + ox     -- sideways instead
                    if not clear(sqAt(cx, cy)) then cx, cy = px - oy, py - ox end
                end
                if clear(sqAt(cx, cy)) then return px, py, cx, cy end
            end
        end
    end
    return nil
end
local function indoorCount(px, py)
    local n = 0
    for dy = -10, 10, 2 do
        for dx = -10, 10, 2 do
            local s = sqAt(px + dx, py + dy)
            if s and not s:isOutside() then n = n + 1 end
        end
    end
    return n
end
local function scanRow(ax, ay, rowY, needRoad)
    local y = ay + rowY
    for x = ax - H.R, ax + H.R do
        for axis = 1, 2 do
            if rectOk(x, y, axis, needRoad) then
                local px, py, cx, cy = sideSpot(x, y, axis)
                if px then
                    local score = math.min(indoorCount(px, py), 25) - 0.02 * (math.abs(x - ax) + math.abs(y - ay))
                    if not L.best or score > L.best.score then
                        local carX, carY
                        if axis == 1 then carX, carY = x + 1, y + 3 else carX, carY = x + 3, y + 1 end
                        L.best = { score = score, px = px, py = py, cx = cx, cy = cy, carX = carX, carY = carY, axis = axis,
                                   houses = indoorCount(px, py), road = needRoad }
                    end
                end
            end
        end
    end
end
-- one call per frame, true when a spot is chosen (or every anchor failed)
local function locateStep()
    local now = getTimestampMs()
    if L.ph == "next" then
        L.i = L.i + 1
        L.a = H.ANCH[L.i]
        if not L.a then L.ph = "fail"; return true end
        L.best, L.row, L.pass = nil, -H.R, 1
        tp(L.a[1] + 0.5, L.a[2] + 0.5, 0)
        L.t0 = now; L.ph = "load"
        say("note: moving to " .. L.a[3] .. " (" .. L.a[1] .. "," .. L.a[2] .. "), waiting for the cell to load")
    elseif L.ph == "load" then
        local sq = sqAt(L.a[1], L.a[2])
        if sq and now - L.t0 >= 9000 then L.ph = "scan"
        elseif now - L.t0 > 40000 then say("note: the cell around " .. L.a[1] .. "," .. L.a[2] .. " did not load in 40 s"); L.ph = "next" end
    elseif L.ph == "scan" then
        scanRow(L.a[1], L.a[2], L.row, L.pass == 1)
        L.row = L.row + 1
        if L.row > H.R then
            -- good enough: houses around it, or the last anchor (the QA field) with anything clear
            if L.best and (L.best.houses >= 4 or L.i >= #H.ANCH) then L.ph = "found"; return true end
            if L.pass == 1 then L.pass = 2; L.row = -H.R     -- once more, a car spot off the road allowed
            else L.ph = "next" end
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- The crate (as zedqa_padlock.lua builds one) and what is in it
-- ---------------------------------------------------------------------------
local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
    return nil
end
local function thumpOn(sq)
    if not sq then return nil end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if instanceof(o, "IsoThumpable") and o:getContainer() then return o end
    end
    return nil
end
local function buildCrate()
    local sp = X.spot
    if not sp then return false end
    local info = findInfo("Base.Wood_Crate_Lvl1")
    if not info then say("note: no entity info for the crate"); return false end
    local sq = sqAt(sp.cx, sp.cy)
    if not sq then return false end
    p:setBuildCheat(true)
    local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
    b.buildCheat = true
    b.player = pn
    local ok, valid = pcall(function() b.sq = sq; return b:isValid(sq) end)
    if ok and valid then pcall(function() b:create(sp.cx, sp.cy, 0, false, nil) end) end
    p:setBuildCheat(was.cheat)
    X.crateSq = sq
    say("crate build at " .. sp.cx .. "," .. sp.cy .. " valid=" .. tostring(ok and valid))
    return ok and valid
end
local function fillCrate()
    local o = thumpOn(X.crateSq)
    if not o then return false end
    X.crate = o
    X.crateInv = o:getContainer()
    for _, ft in ipairs({ "Base.Hammer", "Base.Saw", "Base.Screwdriver", "Base.Wrench", "Base.Nails", "Base.Nails", "Base.TinnedBeans",
                          "Base.TinnedBeans", "Base.Bandage", "Base.Rope", "Base.Battery", "Base.DuctTape", "Base.Crisps", "Base.Peanuts" }) do
        local it = X.crateInv:AddItem(ft)
        if it then X.crateItems[#X.crateItems + 1] = it end
    end
    pcall(function() p:faceThisObject(o) end)
    say("crate ready with " .. #X.crateItems .. " things")
    return true
end
local function removeCrate()
    for _, it in ipairs(X.crateItems) do
        pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    end
    X.crateItems = {}
    local o, sq = X.crate, X.crateSq
    if o and sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        local still = thumpOn(sq)
        if still then pcall(function() sq:RemoveTileObject(still) end) end
    end
    X.crate, X.crateInv, X.crateSq = nil, nil, nil
end

-- ---------------------------------------------------------------------------
-- The car
-- ---------------------------------------------------------------------------
local function radioPart(v) return v and v:getPartById("Radio") end
local function fitRadio(v, ft)
    local part = radioPart(v)
    if not part then return false end
    local ok = pcall(function()
        part:setInventoryItem(instanceItem(ft))
        Vehicles.InstallComplete.Radio(v, part)
        local dd = part:getDeviceData()
        if dd:getDevicePresets():getPresets():size() == 0 then dd:generatePresets() end
    end)
    return ok
end
local function leaveCar()
    local v = p:getVehicle()
    if v then
        pcall(function() v:exit(p) end)
        pcall(function() triggerEvent("OnExitVehicle", p) end)
    end
    X.entered = false
end
local function removeCar()
    if X.car then pcall(function() X.car:permanentlyRemove() end) end
    if X.key then pcall(function() inv:Remove(X.key) end) end
    X.car, X.key, X.entered = nil, nil, false
end
local function dash() return ZeD.Dashboard and ZeD.Dashboard.getInstance() end

-- ---------------------------------------------------------------------------
-- The flyer map (zedqa_flyermap.lua)
-- ---------------------------------------------------------------------------
local FLYERS = { "ustoreitmuldraugh", "fossoil1", "sunstarmotel", "muldraughbakesale" }
local function mp() local w = WW(); return w and w._worldMapPanel end

-- ---------------------------------------------------------------------------
-- Put everything back (safe to run twice; also the abort path). Three parts: the
-- screen and the items now, the car after the character is out of it, the
-- position last.
-- ---------------------------------------------------------------------------
local function restoreScreen()
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() local m = getPlayerRadialMenu(pn); if m then m:undisplay() end end)
    pcall(function() local m = zm(); if m then m:close() end end)
    pcall(function() if CR and CR.closeFor then CR.closeFor(pn) end end)
    pcall(function() if WWm.getObjectCard and WWm.getObjectCard() then WWm.closeObjectCard() end end)
    pcall(function() selectItem(nil) end)
    pcall(function() closeRecipe("craft"); closeRecipe("build") end)
    pcall(function()
        local ms = MainScreen.instance
        if ms and ms.inGame and ms:isVisible() and ToggleEscapeMenu then
            if MM.pauseOpts and MM.pauseOpts:isVisible() then MM.pauseOpts:back() end
            MM.pauseView = "pause"
            ToggleEscapeMenu(Keyboard.KEY_ESCAPE)
        end
    end)
    pcall(function()
        local w = WW()
        if w and w._rolled then ZeD.Curtain.unroll(w) end
    end)
    -- the map: its style, and the mouse fake of the hover shot
    pcall(function()
        local m = mp()
        if m then m.isMouseOver, m.getMouseX, m.getMouseY = nil, nil, nil end
        local w = WW()
        if was.mapStyle and w then ZeD.MapsTab.setStyle(w, was.mapStyle) end
        if m then m.mapAPI:centerOn(p:getX(), p:getY()) end
    end)
    pcall(function()
        local read = p:getReadPrintMedia()
        for _, id in ipairs(X.flyerAdded) do read:remove(id) end
        X.flyerAdded = {}
        local md = p:getModData()
        if md.ZeD_FlyerSeen then md.ZeD_FlyerSeen["fossoil1:1:1"] = X.flyerSeen end
    end)
    -- the kit: hands first, then the belt, then what is worn, then the items
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    local hb = ZeD.Belt and ZeD.Belt.hotbar(pn)
    for _, it in ipairs(X.attached) do
        pcall(function() if hb then hb:removeItem(it, false) end end)
    end
    X.attached = {}
    for _, it in ipairs(X.worn) do pcall(function() p:removeWornItem(it) end) end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    for _, it in ipairs(X.worn) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    for _, it in ipairs(X.added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    X.worn, X.added = {}, {}
    pcall(function() p:setPrimaryHandItem(was.prim); p:setSecondaryHandItem(was.sec) end)
    pcall(function() if hb then hb:refresh() end end)
    pcall(removeCrate)
    pcall(function() p:setBuildCheat(was.cheat) end)
    -- the options and view choices set for the shots
    pcall(function() ctxOpt:setValue(was.ctx) end)
    pcall(function() watchOpt:setValue(was.watch) end)
    pcall(function() barOpt:setValue(was.bar) end)
    pcall(function() p:getModData().ZeD_WatchPop = was.pop end)
    pcall(function() ZeD.EquipDoll.setView(was.equip) end)
    pcall(function() local gv = p:getModData().ZeD_GridViews; if gv then gv.player = was.grid end end)
    pcall(function() local w = CW(); if w then w._healthExerciseSel = was.exSel end end)
    pcall(function()
        local st = p:getStats()
        if was.hunger then st:set(CharacterStat.HUNGER, was.hunger) end
        if was.thirst then st:set(CharacterStat.THIRST, was.thirst) end
    end)
    pcall(restoreWeather)
    pcall(function() gt:setTimeOfDay(was.tod) end)
    pcall(function() if getGameSpeed() <= 0 then setGameSpeed(was.speed > 0 and was.speed or 1) end end)
    for _, e in ipairs(X.hidden) do pcall(function() e:setVisible(true) end) end
    X.hidden = {}
end

-- ===========================================================================
-- THE WALK
-- ===========================================================================

-- ---- 1. start: the console out of the way, the windows shut, the kit
step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false); X.hidden[#X.hidden + 1] = e end
    end
    p:setGodMod(true)
    if Mouse and Mouse.setXY then pcall(function() Mouse.setXY(math.floor(core:getScreenWidth() / 2), 4) end) end
    say("start: " .. core:getScreenWidth() .. "x" .. core:getScreenHeight() .. " | test language off | windows char " .. tostring(was.char)
        .. " world " .. tostring(was.world) .. " | from " .. math.floor(was.x) .. "," .. math.floor(was.y))
    watchOpt:setValue(1)           -- the watch on the belt
    ctxOpt:setValue(1)
    barOpt:setValue(1)
    closePair()
end)
step(20, function() giveKit() end)

-- ---- 2. the town: move, wait for the cell, scan, move to the spot
poll(10, 9000, locateStep, function() L.ph = "fail"; say("ERR the search for a street ran out of time") end)
step(2, function()
    if L.ph == "found" and L.best then
        X.spot = L.best
        X.spot.note = L.a[3]
        tp(X.spot.px + 0.5, X.spot.py + 0.5, 0)
        say(string.format("spot: %s | character %d,%d | crate %d,%d | car %d,%d axis %d | houses %d | on road %s",
            X.spot.note, X.spot.px, X.spot.py, X.spot.cx, X.spot.cy, X.spot.carX, X.spot.carY, X.spot.axis, X.spot.houses, tostring(X.spot.road)))
        if L.a[3]:find("QA field", 1, true) then err(0, "no town street found: shooting in the QA field") end
    else
        err(0, "no clear spot found anywhere: the street scenes, crate and car are skipped")
    end
end)
waitMs(2500)
step(2, function()
    local sq = p:getCurrentSquare()
    say("standing on a loaded square: " .. tostring(sq ~= nil) .. " outside " .. tostring(sq ~= nil and sq:isOutside()))
    -- the shots are of the day: 10:00, clear weather
    gt:setTimeOfDay(10.0)
    clearWeather()
    pcall(buildCrate)
end)
step(25, function()
    if X.spot then
        if not fillCrate() then err(0, "the crate was not built: shots 01 and 24 show the ground") end
    end
end)
waitMs(1500)

-- ---- 3. both windows over the street (01), the character looting (24)
step(2, function() gt:setTimeOfDay(10.0); openPair() end)
step(60, function() end)
T(1, "windows_street", "c", "loot", 50, function()
    selectItem(nil)
    if X.crateInv then WWm.selectContainer(X.crateInv, 150) end
end)
S(24, "looting_container", 50, function()
    if not X.crateInv then return false, "no crate to loot" end
    pcall(function() p:faceThisObject(X.crate) end)
    local n = 0
    for _, it in ipairs(X.crateItems) do
        if n < 8 and it:getContainer() == X.crateInv then
            pcall(function() ISInventoryPaneContextMenu.transferIfNeeded(p, it) end)
            n = n + 1
        end
    end
    if n == 0 then return false, "nothing left in the crate" end
end)
step(2, function() pcall(function() ISTimedActionQueue.clear(p) end) end)
step(30, function() end)

-- ---- 4. item cards on the Character window's Loot list
T(2, "card_food", "c", "loot", 40, function()
    local it = found("Base.Apple")
    if not it then return false, "no apple" end
    if not selectItem(it) then return false, "the Loot list is not ready" end
end)
S(3, "card_weapon", 40, function()
    local it = found("Base.Machete")
    if not it then return false, "no machete" end
    if not selectItem(it) then return false, "the Loot list is not ready" end
end)
step(2, function() selectItem(nil) end)
step(20, function() end)

-- ---- 5. Health, Equip, Skills
T(4, "health_figure", "c", "health", 45, function()
    local w = CW()
    w._healthFigureExpanded = true
    w._healthScroll:setScrollPos(0)
end)
S(5, "health_exercise", 30, function()
    local w = CW()
    if not (ZeD.HealthTab and ZeD.HealthTab.exerciseInfo and ZeD.HealthTab.exerciseInfo(p, "pushups")) then return false, "no exercise info" end
    was.exSel = w._healthExerciseSel
    w._healthFigureExpanded = true
    w._healthExerciseSel = "pushups"
end)
step(2, function() local w = CW(); if w then w._healthExerciseSel = was.exSel end end)
T(6, "equip_doll", "c", "equip", 55, function() ZeD.EquipDoll.setView("doll") end)
step(2, function() ZeD.EquipDoll.setView(was.equip) end)
T(7, "skills", "c", "skills", 40)
step(2, function() charTab("loot") end)

-- ---- 6. Maps: Survey, Color, Paper, then the flyer pins
local function mapSetup(style)
    return function()
        local w, m = WW(), mp()
        if not (w and m) then return false, "the map panel is not up" end
        was.mapStyle = was.mapStyle or m.style
        ZeD.MapsTab.setStyle(w, style)
        if style == "paper" and mp().style ~= "paper" then return false, "no paper map style here" end
        pcall(function() mp().mapAPI:centerOn(p:getX(), p:getY()) end)
        pcall(function() mp():_zoomTo(X.mapZoom) end)
    end
end
T(8, "maps_survey", "w", "maps", 90, mapSetup("survey"))
S(9, "maps_color", 90, mapSetup("color"))
S(10, "maps_paper", 90, mapSetup("paper"))
step(2, function()
    -- the four Muldraugh flyers read, one marked visited
    pcall(function()
        local read = p:getReadPrintMedia()
        for _, id in ipairs(FLYERS) do
            if not read:contains(id) then p:addReadPrintMedia(id); X.flyerAdded[#X.flyerAdded + 1] = id end
        end
        local md = p:getModData(); md.ZeD_FlyerSeen = md.ZeD_FlyerSeen or {}
        X.flyerSeen = md.ZeD_FlyerSeen["fossoil1:1:1"]
        md.ZeD_FlyerSeen["fossoil1:1:1"] = true
    end)
end)
step(2, function()
    runSetup(function()
        local w, m = WW(), mp()
        if not (w and m) then return false, "the map panel is not up" end
        ZeD.MapsTab.setStyle(w, "survey")
        m = mp()
        m.mapAPI:centerOn(10700, 9950)
        m:_zoomTo(15)
    end)
end)
step(60, function()
    -- hover the motel's pin (the mouse is faked on the panel)
    if not sc.ok then return end
    local m = mp()
    local pick = nil
    for _, q in ipairs(m and m._flyerPins or {}) do
        if q.id == "sunstarmotel" then pick = q end
    end
    if not pick then for _, q in ipairs(m and m._flyerPins or {}) do pick = pick or q end end
    if not pick then sc.ok = false; sc.why = "no flyer pin on the map"; return end
    local fx, fy = pick.x + math.floor(pick.w / 2), pick.y + math.floor(pick.h / 2)
    m.isMouseOver = function() return true end
    m.getMouseX = function() return fx end
    m.getMouseY = function() return fy end
end)
step(30, function()
    if sc.ok then
        local m = mp()
        say("hover card: " .. tostring(m and m._flyerHover and m._flyerHover.id))
    end
    finishShot(11, "flyer_pins_hover")
end)
step(2, function()
    local m = mp()
    if m then m.isMouseOver, m.getMouseX, m.getMouseY = nil, nil, nil end
    local w = WW()
    if w and was.mapStyle then ZeD.MapsTab.setStyle(w, was.mapStyle) end
    pcall(function() local mm = mp(); mm.mapAPI:centerOn(p:getX(), p:getY()) end)
    pcall(function()
        local read = p:getReadPrintMedia()
        for _, id in ipairs(X.flyerAdded) do read:remove(id) end
        X.flyerAdded = {}
        local md = p:getModData()
        if md.ZeD_FlyerSeen then md.ZeD_FlyerSeen["fossoil1:1:1"] = X.flyerSeen end
    end)
end)

-- ---- 7. Crafting with a recipe open
T(12, "crafting_recipe", "w", "craft", 60, function() return openRecipe("craft") end)
step(2, function() closeRecipe("craft") end)

-- ---- 8. the context menu on an inventory item: the strip, then the list
local function menuAt()
    local w = CW()
    if w then return w:getX() + math.floor(w:getWidth() * 0.42), w:getY() + math.floor(w:getHeight() * 0.30) end
    return 700, 300
end
step(2, function() charTab("loot"); selectItem(nil) end)
S(13, "context_menu_strip", 30, function()
    ctxOpt:setValue(1)
    local food = found("Base.Apple")
    if not food then return false, "no food to open the menu on" end
    local x, y = menuAt()
    ISInventoryPaneContextMenu.createMenu(pn, true, { food }, x, y)
end)
step(2, function() local m = zm(); if m then m:close() end end)
S(14, "context_menu_list", 30, function()
    ctxOpt:setValue(2)
    local food = found("Base.Apple")
    if not food then return false, "no food to open the menu on" end
    local x, y = menuAt()
    ISInventoryPaneContextMenu.createMenu(pn, true, { food }, x, y)
end)
step(2, function() local m = zm(); if m then m:close() end; ctxOpt:setValue(was.ctx) end)
step(15, function() end)

-- ---- 9. the World window's curtain
step(2, function()
    if not WWm.isTabShowing("maps") then WWm.openTab(0, "maps") end
end)
S(21, "window_curtain_rolled", 100, function()
    local w = WW()
    if not w then return false, "no World window" end
    local r = w._rollBtn
    if r then w:onMouseDown(r.x + 2, r.y + 2)
    else
        local ok = pcall(function() ZeD.Curtain.roll(w) end)
        if not ok then return false, "the roll button is not there" end
    end
    if not w._rolled then return false, "the window did not roll" end
end)
step(2, function() local w = WW(); if w and w._rolled then ZeD.Curtain.unroll(w) end end)
step(100, function()
    local w = WW()
    say("curtain back: rolled=" .. tostring(w and w._rolled))
    if w and w._rolled then ZeD.Curtain.unroll(w) end
    WWm.openTab(0, "maps", true)     -- the Maps tab shut again
end)
step(40, function() worldTab("loot") end)

-- ---- 10. HUD only: windows shut. The wide shot first (23), then the belt (15), the watch (16)
step(2, function()
    closePair()
    -- a little hunger and thirst, so the moodles have something to show
    pcall(function()
        p:getStats():set(CharacterStat.HUNGER, 0.3)
        p:getStats():set(CharacterStat.THIRST, 0.35)
    end)
    p:getModData().ZeD_WatchPop = nil
    gt:setTimeOfDay(10.0)
end)
step(120, function()
    local vi, vl = getPlayerInventory(pn), getPlayerLoot(pn)
    say("HUD only: vanilla inventory visible=" .. tostring(vi and vi:isVisible()) .. " loot visible=" .. tostring(vl and vl:isVisible()))
    pcall(function() if X.crate then p:faceThisObject(X.crate) end end)
end)
S(23, "hud_only_street", 30, nil)
S(15, "belt_mini_watch", 20, function()
    local item = ZeD.Watch.beltWatch(p)
    if not item then return false, "no watch on the belt (none worn)" end
end)
S(16, "watch_popped", 40, function()
    if not ZeD.Watch.beltWatch(p) then return false, "no watch on the belt (none worn)" end
    ZeD.Watch.togglePop(true)
    local inst = ZeD.Watch.getInstance()
    if inst then inst._popTouched = getTimestampMs() end
end)
step(2, function() pcall(function() ZeD.Watch.togglePop(false) end) end)
step(30, function() end)

-- ---- 11. the action bar: reading a book
S(17, "action_bar_reading", 90, function()
    barOpt:setValue(1)
    local book = found("Base.Book")
    if not book then return false, "no book" end
    local ok = pcall(function() ISInventoryPaneContextMenu.readItem(book, pn) end)
    if not ok then pcall(function() ISTimedActionQueue.add(ISReadABook:new(p, book, 150)) end) end
end)
step(2, function() pcall(function() ISTimedActionQueue.clear(p) end); barOpt:setValue(was.bar) end)
step(40, function() end)

-- ---- 12. the emote wheel
S(20, "wheel_emotes", 40, function()
    ISEmoteRadialMenu:new(p):fillMenu()
end)
step(2, function() local m = getPlayerRadialMenu(pn); if m then m:undisplay() end end)
step(20, function() end)

-- ---- 13. the Options page (ZeD setup) in the pause menu
local pauseW0 = nil
step(2, function()
    if not ToggleEscapeMenu then sc.ok, sc.why = false, "ToggleEscapeMenu is not there"; return end
    sc.ok, sc.why = true, ""
    pauseW0 = MM.pause and MM.pause.page
    ToggleEscapeMenu(Keyboard.KEY_ESCAPE)
end)
step(45, function()
    local ms = MainScreen.instance
    if sc.ok and ms and ms:isVisible() then MM.openOptions()
    elseif sc.ok then sc.ok = false; sc.why = "the pause menu did not come up" end
end)
step(45, function()
    if not sc.ok then return end
    local w = MM.pauseOpts
    if not (w and w:isVisible()) then sc.ok = false; sc.why = "the Options window did not open"; return end
    local idx = nil
    for i, pg in ipairs(w:pages()) do if pg.raw == "zed" then idx = i end end
    if not idx then sc.ok = false; sc.why = "no ZeD setup page in the Options"; return end
    w.pageIdx = idx; w.scroll = 0; w.focusId = nil
end)
step(40, function() if sc.ok then shot(22, "options_zed_settings") else err(22, "options_zed_settings: " .. sc.why) end end)
step(2, function()
    local w = MM.pauseOpts
    if w and w:isVisible() then
        if w:anyChanged() then say("note: the Options window shows changes: left for the player") end
        w:back()
    end
end)
step(25, function()
    local ms = MainScreen.instance
    if ms and ms:isVisible() and MM.pause then MM.pause.page = pauseW0; MM.pause.focusId = nil end
end)
step(5, function()
    local ms = MainScreen.instance
    if ms and ms:isVisible() and ToggleEscapeMenu then
        MM.pauseView = "pause"
        ToggleEscapeMenu(Keyboard.KEY_ESCAPE)
    end
end)
step(40, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    local ms = MainScreen.instance
    say("resumed: pause menu visible=" .. tostring(ms and ms:isVisible()) .. " speed " .. tostring(getGameSpeed()))
end)

-- ---- 14. the car: day (18, 27, 26), then night (19)
local ES = { tries = 0, last = -9999 }
step(2, function()
    X.carOk = false
    closePair()
    gt:setTimeOfDay(10.0)
    pcall(function() p:getStats():set(CharacterStat.HUNGER, was.hunger or 0); p:getStats():set(CharacterStat.THIRST, was.thirst or 0) end)
    local sp = X.spot
    if not sp then sc.ok, sc.why = false, "no street spot for a car"; return end
    local sq = sqAt(sp.carX, sp.carY)
    if not sq then sc.ok, sc.why = false, "no square for the car"; return end
    local dir = (sp.axis == 1) and IsoDirections.N or IsoDirections.E
    local ok, v = pcall(addVehicleDebug, "Base.CarNormal", dir, nil, sq)
    if not (ok and v) then sc.ok, sc.why = false, "the car would not spawn: " .. tostring(v); return end
    X.car = v
    pcall(function() v:repair() end)
    pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
    pcall(function()
        local b = v:getPartById("Battery"); local it = b and b:getInventoryItem()
        if it then pcall(function() it:setCurrentUsesFloat(1.0) end); pcall(function() it:setUsedDelta(1.0) end) end
    end)
    pcall(function() X.key = inv:AddItem(v:createVehicleKey()) end)
    local part = radioPart(v)
    if part and not part:getInventoryItem() then fitRadio(v, "Base.RadioRed") end
    sc.ok, sc.why = true, ""
    say("car spawned at " .. sp.carX .. "," .. sp.carY .. ", radio part " .. tostring(part ~= nil))
end)
step(90, function()          -- (the car settles; physics wake up beside the character)
    local v = X.car
    if not v then return end
    local d = 99
    pcall(function() d = v:DistTo(p) end)
    if d > 12 then sc.ok, sc.why = false, "the car is " .. tostring(d) .. " tiles away: not entering it"; return end
    pcall(function() v:enter(0, p) end)
    X.entered = p:getVehicle() ~= nil
    if not X.entered then sc.ok, sc.why = false, "the driver seat could not be entered"; return end
    pcall(function() triggerEvent("OnEnterVehicle", p) end)
end)
step(30, function() if X.car and X.entered then pcall(function() X.car:setKeysInIgnition(true) end) end end)
poll(10, 1500, function()
    local v = X.car
    if not (v and X.entered) then return true end
    local run = false
    pcall(function() run = v:isEngineRunning() end)
    if run then return true end
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local busy = q and q.queue and #q.queue > 0
    if not busy and tick - ES.last > 120 and ES.tries < 5 then
        ES.tries = ES.tries + 1; ES.last = tick
        pcall(function() ISVehicleMenu.onStartEngine(p) end)
    end
    return false
end, function() say("note: the engine did not start in time") end)
step(60, function()
    local d = dash()
    local v = X.car
    if not (v and X.entered and d and d._st) then return end
    if not d._st.radioOn then d:_fire("pwr", false) end
    if not d._st.lights then d:_fire("lights", false) end
    local part = radioPart(v)
    if part then
        pcall(function() RO.setChannel(p, part, 101200) end)
        pcall(function() RO.run("SetVolume", p, part, 0.6) end)
    end
end)
step(120, function()
    local run = false
    pcall(function() run = X.car:isEngineRunning() end)
    local d = dash()
    say("car: engine running " .. tostring(run) .. " | dash up " .. tostring(d ~= nil) .. " radio " .. tostring(d and d._st and d._st.radioOn)
        .. " lights " .. tostring(d and d._st and d._st.lights))
    if not (X.car and X.entered and d) then err(18, "car_day_dash_radio: " .. (sc.why ~= "" and sc.why or "no dashboard")); return end
    shot(18, "car_day_dash_radio")
end)
-- the radio up close (the wheel's Device Options entry)
step(2, function()
    local part = radioPart(X.car)
    if not (part and X.entered) then err(27, "car_radio_up_close: no radio part or not seated"); return end
    pcall(function() ISVehicleMenu.onSignalDevice(p, part) end)
end)
step(60, function()
    local pr = CR and CR.props and CR.props[pn]
    if X.entered and pr and pr:isReallyVisible() then shot(27, "car_radio_up_close")
    elseif X.entered then err(27, "car_radio_up_close: the radio did not come up") end
    pcall(function() CR.closeFor(pn) end)
end)
-- the vehicle wheel from the seat
step(15, function()
    if not X.entered then err(26, "wheel_vehicle: not seated"); return end
    pcall(function() ISVehicleMenu.showRadialMenu(p) end)
end)
step(40, function() if X.entered then shot(26, "wheel_vehicle") end end)
step(2, function() local m = getPlayerRadialMenu(pn); if m then m:undisplay() end end)
-- night
step(15, function()
    if not X.entered then return end
    gt:setTimeOfDay(22.0)
end)
step(260, function()
    local d = dash()
    if not (X.car and X.entered and d) then err(19, "car_night_dash_lit: " .. (sc.why ~= "" and sc.why or "no dashboard")); return end
    say("night: dash lights " .. tostring(d._st and d._st.lights))
    shot(19, "car_night_dash_lit")
end)
step(2, function() leaveCar() end)
step(60, function() removeCar(); gt:setTimeOfDay(10.0) end)

-- ---- 15. put everything back
mark("restore")
step(5, function() restoreScreen() end)
step(15, function() leaveCar() end)
step(60, function() removeCar() end)
step(10, function()
    -- the way back: the character where it was, and the cell around it
    tp(was.x, was.y, was.z)
end)
waitMs(5000)
step(5, function()
    gt:setTimeOfDay(was.tod)
    if getGameSpeed() <= 0 then setGameSpeed(was.speed > 0 and was.speed or 1) end
    if was.char and was.world then openPair()
    else
        if was.char then CWm.toggle(0) end
        if was.world then WWm.open(0) end
    end
end)
step(50, function()
    if was.cwTab and CW() then charTab(was.cwTab) end
    if was.wwTab and WW() then worldTab(was.wwTab) end
    say(string.format("back at %d,%d | windows char %s world %s | test language off %s | %d shots ok, %d errors",
        math.floor(p:getX()), math.floor(p:getY()), tostring(CWm.isOpen()), tostring(WWm.isOpen()),
        tostring(not ZeD.trTestOn()), X.nOk, X.nErr))
    say("DONE")
end)

-- ---------------------------------------------------------------------------
-- Driving it (OnRenderTick: it runs while the pause menu is up)
-- ---------------------------------------------------------------------------
local MAX_TICKS = 24000     -- a stuck run stops here and puts things back
local MAX_MS = 540000       -- nine minutes of wall clock, the same
local function onFrame()
    tick = tick + 1
    if X.jumpAbort and marks.restore and qi < marks.restore then
        X.jumpAbort = false
        say("aborting the walk, putting things back")
        qi = marks.restore; lastDone = tick
    end
    local s = queue[qi]
    if not s then Events.OnRenderTick.Remove(onFrame); return end
    if marks.restore and qi < marks.restore and (tick > MAX_TICKS or getTimestampMs() - startMs > MAX_MS) then
        say("ERR the walk ran too long (frame " .. tick .. ", step " .. qi .. "): putting things back")
        qi = marks.restore; lastDone = tick
        return
    end
    if not s.startTick then
        if tick - lastDone < s.after then return end
        s.startTick = tick
    end
    local done = true
    local ok, r = pcall(s.fn)
    if not ok then
        say("ERR step " .. qi .. " (frame " .. tick .. ") " .. tostring(r))
    elseif s.max then
        done = r == true
        if not done and tick - s.startTick >= s.max then
            local ok2, e2 = pcall(s.timeout or noop)
            if not ok2 then say("ERR step " .. qi .. " timeout " .. tostring(e2)) end
            done = true
        end
    end
    if done then
        lastDone = tick
        qi = qi + 1
    end
end
Events.OnRenderTick.Add(onFrame)
say("start (" .. #queue .. " steps)")
