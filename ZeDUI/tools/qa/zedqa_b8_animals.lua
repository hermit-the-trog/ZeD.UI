-- ZeDUI/tools/qa/zedqa_b8_animals.lua  (Nov 7 2026, QA; CHECK_world_devices_20261107.md parts 4 and 5)
-- The game's animal info window and livestock zone window go to ZeD's Animals tab (WorldRoutes.lua, Overrides/Animals.lua).
-- The script builds a livestock zone with a hen in it, a second empty zone and a hen outside any zone, then calls the game's
-- own entries (AnimalContextMenu.onAnimalInfo, AnimalContextMenu.onCheckZone) and checks:
--   a zone animal's Info: the Animals tab on that animal's view, the game's animal window not made (4.1), the view staying when
--   the character walks 14 tiles off (4.8) / an animal outside any zone: the view, then stepping back to the overview once the
--   character is past the game's 5 tiles (4.4, 4.6) / Check zone on a zone, on a new empty zone, on a second zone with the tab
--   already open (5.1, 5.2, 5.4), the game's zone window and first-time note not made (the note's option is turned on for the
--   test and put back) / the "?" help text and its ZeD note (5.5, 5.6).
-- Removes the zones and animals and puts the option back. Manual: a right-click menu, the pad (4.2, 5.3, 5.7), a hutch bird
-- (4.3), a trailer (4.5, 4.7), Deck size and Large text, safe mode.  grep "ZEDQA b8an"; shots zqa_b8an_*.png.
local TAG = "b8an"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
local p = getPlayer()
local pn = p and p:getPlayerNum() or 0
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local AT, WR = ZeD and ZeD.AnimalsTab, ZeD and ZeD.WorldRoutes
if not (p and CW and WW and AT and WR) then say("ERR ZeD's windows or routes are not loaded"); say("DONE"); return end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8an_" .. n .. ".png") end) end
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
local wasOpen = { cw = CW.isOpen(), ww = WW.isOpen() }
local function state() local w = ww(); return w and AT.getState(w) or nil end
local function onAnimals() return ww() ~= nil and WW.isTabShowing("animals") == true end
local function breedOf(kind)
    local def = AnimalDefinitions.getDef(kind)
    return def and def:getBreeds():get(0)
end

-- the game's windows, counted when made
local counts = { animalUI = 0, zoneUI = 0, note = 0 }
local origs = {}
local function wrapNew(cls, key, label)
    if not (cls and cls.new) then say("NOTE " .. label .. " has no new() here; its count stays 0"); return end
    local orig = cls.new
    origs[#origs + 1] = { cls = cls, new = orig }
    cls.new = function(...) counts[key] = counts[key] + 1; return orig(...) end
end
wrapNew(ISAnimalUI, "animalUI", "ISAnimalUI")
wrapNew(ISDesignationZoneAnimalZoneUI, "zoneUI", "ISDesignationZoneAnimalZoneUI")
wrapNew(ISAnimalZoneFirstInfo, "note", "ISAnimalZoneFirstInfo")
local noteWas = nil
pcall(function() noteWas = getCore():getOptionShowFirstAnimalZoneInfo() end)
onCleanup(function()
    for _, o in ipairs(origs) do o.cls.new = o.new end
    origs = {}
    if noteWas ~= nil then pcall(function() getCore():setOptionShowFirstAnimalZoneInfo(noteWas) end) end
    local P = ZeD.Prompt
    for _ = 1, 3 do
        local top = P and P.top and P.top()
        if top then pcall(top.close, top) end
    end
end)

local zoneA, zoneB, nameA, nameB = nil, nil, "B8 Yard A", "B8 Yard B"
local henIn, henOut = nil, nil
local zones, animals = {}, {}
onCleanup(function()
    for _, a in ipairs(animals) do pcall(function() a:removeFromWorld(); a:removeFromSquare() end) end
    animals = {}
    for _, z in ipairs(zones) do pcall(function() DesignationZoneAnimal.removeZone(z, true) end) end
    zones = {}
    pcall(function() ZeD.AnimalsAlertPoller.refreshCache() end)
    pcall(function() p:resetSelectedZonesForHighlight(); p:setSeeDesignationZone(false) end)
    local s = state()
    if s then s.view, s.zoneName, s.animalRef = "overview", nil, nil end
    warp(HOME.x, HOME.y)
    if wasOpen.cw and not CW.isOpen() then pcall(CW.toggle, pn) end
    if wasOpen.ww and not WW.isOpen() then pcall(WW.open, pn) end
end)

-- ---- setup: zone A (west, with a hen), zone B (empty, further north-west), a hen outside every zone
step(1, function()
    p:setGodMod(true)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    pcall(function() getCore():setOptionShowFirstAnimalZoneInfo(true) end)
    if not WW.isOpen() then pcall(WW.open, pn) end
    local okA, zA = pcall(DesignationZoneAnimal.new, nameA, px - 12, py - 4, 0, px - 4, py + 4, true)
    local okB, zB = pcall(DesignationZoneAnimal.new, nameB, px - 12, py - 12, 0, px - 4, py - 6, true)
    if okA and zA then zoneA = zA; zones[#zones + 1] = zA end
    if okB and zB then zoneB = zB; zones[#zones + 1] = zB end
    check(zoneA ~= nil and zoneB ~= nil, "setup: two livestock zones made (" .. tostring(zA) .. ")")
    local okH, h1 = pcall(addAnimal, getCell(), px - 8 + 0.5, py + 0.5, 0, "hen", breedOf("hen"))
    if okH and h1 then henIn = h1; animals[#animals + 1] = h1 end
    local okO, h2 = pcall(addAnimal, getCell(), px + 3 + 0.5, py + 3 + 0.5, 0, "hen", breedOf("hen"))
    if okO and h2 then henOut = h2; animals[#animals + 1] = h2 end
    check(henIn ~= nil and henOut ~= nil, "setup: a hen inside zone A and a hen outside every zone")
    pcall(function() ZeD.AnimalsAlertPoller.refreshCache() end)
end)
step(60, function()
    holdBoth()
    local dz = henIn and henIn:getDZone()
    say("NOTE the hen in zone A is in a zone: " .. tostring(dz ~= nil) .. "; the outside hen: " .. tostring(henOut and henOut:getDZone() ~= nil))
    pcall(function() ZeD.AnimalsAlertPoller.refreshCache() end)
end)

-- ---- 4.1 Info on a zone animal
step(5, function() counts.animalUI = 0; pcall(AnimalContextMenu.onAnimalInfo, henIn, p) end)
step(40, function()
    holdBoth()
    local s = state()
    check(onAnimals(), "4.1: the World window shows the Animals tab")
    check(s and s.view == "animal" and s.animalRef == henIn, "4.1: on that animal's view (view " .. tostring(s and s.view) .. ")")
    check(counts.animalUI == 0, "4.1: the game's animal info window was not made")
end)
step(20, function() shot("animal_view") end)
-- 4.8 a zone animal: the view stays when the character walks off
step(5, function() warp(HOME.x + 14, HOME.y) end)
step(60, function()
    holdBoth()
    local s = state()
    check(s and s.view == "animal" and s.animalRef == henIn, "4.8: a zone animal's view stays with the character 14 tiles off")
    warp(HOME.x, HOME.y)
end)

-- ---- 4.4 / 4.6 an animal outside every zone: the game's reach
step(30, function() counts.animalUI = 0; pcall(AnimalContextMenu.onAnimalInfo, henOut, p) end)
step(40, function()
    holdBoth()
    local s = state()
    check(s and s.view == "animal" and s.animalRef == henOut, "4.4: the outside hen's view opens (view " .. tostring(s and s.view) .. ")")
    check(counts.animalUI == 0, "4.4: the game's animal info window was not made")
    local w = ww()
    check((w and w._zedAnimalReach ~= nil) or (henOut and henOut:getDZone() ~= nil), "4.4: the outside hen's view keeps the game's reach")
end)
step(5, function() warp(HOME.x - 9, HOME.y + 3) end)
step(70, function()
    holdBoth()
    local s = state()
    check(s and s.view ~= "animal", "4.6: past 5 tiles the view steps back (view " .. tostring(s and s.view) .. ")")
    warp(HOME.x, HOME.y)
end)

-- ---- 5.1 Check zone
local function zoneObj(name) return DesignationZoneAnimal.getZoneByName and DesignationZoneAnimal.getZoneByName(name) or nil end
step(30, function()
    counts.zoneUI, counts.note = 0, 0
    local z = zoneObj(nameA) or zoneA
    pcall(AnimalContextMenu.onCheckZone, z, p)
end)
step(40, function()
    holdBoth()
    local s = state()
    check(onAnimals(), "5.1: the World window shows the Animals tab")
    check(s and s.view == "zone" and s.zoneName == nameA, "5.1: on zone A's view (view " .. tostring(s and s.view) .. ", zone " .. tostring(s and s.zoneName) .. ")")
    check(counts.zoneUI == 0, "5.1: the game's zone window was not made")
    check(counts.note == 0, "5.1: the game's first-time zone note was not made (option on: " .. tostring(getCore():getOptionShowFirstAnimalZoneInfo()) .. ")")
end)
step(20, function() shot("zone_view") end)
-- 5.5 the help line: the game note's first sentence
step(5, function()
    local lead = WR.zoneNoteLead and WR.zoneNoteLead() or nil
    check(lead ~= nil and lead ~= "", "5.5: the help line has the game's note first sentence (" .. tostring(lead) .. ")")
end)
-- 5.6 the "?" button: a ZeD note
step(5, function()
    local w = ww()
    local ok, e = pcall(AT.zoneHelp, w)
    check(ok and e ~= false, "5.6: the zone view's help opens a note (" .. tostring(e) .. ")")
end)
step(25, function()
    local P = ZeD.Prompt
    local top = P and P.top and P.top()
    check(top ~= nil, "5.6: a ZeD note is up")
    check(counts.note == 0, "5.6: and it is not the game's own note")
    shot("zone_help")
    if top then pcall(top.close, top) end
end)
step(20, function()
    local P = ZeD.Prompt
    check(not (P and P.top and P.top()), "5.6: closing the note leaves nothing behind")
end)
-- 5.4 the Animals tab already on zone A: Check zone on zone B (an empty zone, 5.2)
step(5, function()
    counts.zoneUI, counts.note = 0, 0
    local z = zoneObj(nameB) or zoneB
    pcall(AnimalContextMenu.onCheckZone, z, p)
end)
step(40, function()
    holdBoth()
    local s = state()
    check(s and s.view == "zone" and s.zoneName == nameB, "5.2/5.4: the view switches to the new empty zone B (zone " .. tostring(s and s.zoneName) .. ")")
    check(counts.zoneUI == 0 and counts.note == 0, "5.2/5.4: no game zone window or note")
end)
step(10, function() end)

ticker = onTick
Events.OnTick.Add(ticker)
say("start")
