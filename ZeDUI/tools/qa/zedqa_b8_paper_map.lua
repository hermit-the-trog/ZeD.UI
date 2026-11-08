-- ZeDUI/tools/qa/zedqa_b8_paper_map.lua  (Nov 7 2026, QA; CHECK_paper-map_20261107.md parts 1, 2, 4, 7)
-- Read Map on a map item opens ZeD's map window on the paper (PaperMap.lua, Overrides/PaperMap.lua). The script calls the game's
-- own entry, ISInventoryPaneContextMenu.onCheckMap(map, player), which the Read Map menu option and the double-click end in, and
-- checks, with the World window shut before and then open before:
--   a town map: ZeD's map window on that paper, titled with the map's name, the paper's area read (revealed), the whole paper in
--   view, no game ISMap window; closing it puts the World window back as it was / a map in a bag: the game's transfer first, then
--   the window / a stash map: the "Find on map" band button, its press (the reading bar, then the world map unfolded, the paper
--   put away, the World window kept) / dropping the map closes the paper / a second map replaces the first / the unfolded world
--   map folds for a paper / closing the World window folds the paper / the World window's own fold keeps the World window /
--   safe mode: the game's own ISMap window.
-- Costs one thing it cannot undo: the Muldraugh paper's area is now known on the QA character's world map (that is what Read Map
-- does). Everything else is put back (items removed, safe mode option, windows).
-- Manual: how it looks (title, colors, Key button, no fog or player dot), the marks and notes (part 3), the controller (part 5),
-- Deck size and Large text (part 6), the Muldraugh stash's building, server world-map-off, Draw On The Map.
-- grep "ZEDQA b8pm"; shots zqa_b8pm_*.png.
local TAG = "b8pm"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
local p = getPlayer()
local pn = p and p:getPlayerNum() or 0
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local PM, MT = ZeD and ZeD.PaperMap, ZeD and ZeD.MapsTab
if not (p and CW and WW and PM and MT and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onCheckMap) then
    say("ERR ZeD's paper map is not loaded"); say("DONE"); return
end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8pm_" .. n .. ".png") end) end
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
local wasOpen = { cw = CW.isOpen(), ww = WW.isOpen() }
local inv = p:getInventory()
local given = {}
local function give(ft) local it = inv:AddItem(ft); if it then given[#given + 1] = it end; return it end
local gameWin = { map = 0, wrap = 0, lastWrap = nil }
local origs = {}
local function wrapNew(cls, key, label)
    if not (cls and cls.new) then say("NOTE " .. label .. " has no new() here"); return end
    local orig = cls.new
    origs[#origs + 1] = { cls = cls, new = orig }
    cls.new = function(...)
        gameWin[key] = gameWin[key] + 1
        local o = orig(...)
        if key == "wrap" then gameWin.lastWrap = o end
        return o
    end
end
wrapNew(ISMap, "map", "ISMap")
wrapNew(ISMapWrapper, "wrap", "ISMapWrapper")
local safeOpt = ZeD.Settings and ZeD.Settings.safeModeOption
local safeWas = nil
if safeOpt then pcall(function() safeWas = safeOpt:getValue() end) end
local function setSafe(v)
    if not safeOpt then return false end
    local ok = pcall(function() safeOpt:setValue(v) end)
    pcall(ZeD.Safe.reread)
    return ok
end
local function closeGameMap()
    local w = gameWin.lastWrap
    if w then pcall(function() w:setVisible(false); w:removeFromUIManager() end) end
    gameWin.lastWrap = nil
end
local function popOf() local w = ww(); return w and w._mapPopout or nil end
local function paperOf() local w = ww(); return w and w._mapPaperItem or nil end
local function paperUp(item) return popOf() ~= nil and paperOf() == item end
local function noPaper() return popOf() == nil end
local function readMap(item) local ok, e = pcall(ISInventoryPaneContextMenu.onCheckMap, item, pn); if not ok then say("ERR onCheckMap: " .. tostring(e)) end end
local function shut()
    -- the paper, the unfolded map, the windows: all away
    local w = ww()
    if w and w._mapPopout then pcall(MT.closePopout, w, true) end
    if CW.isOpen() then pcall(CW.toggle, pn) end
    if WW.isOpen() then pcall(WW.close) end
end
onCleanup(function()
    for _, o in ipairs(origs) do o.cls.new = o.new end
    origs = {}
    closeGameMap()
    if safeWas ~= nil and safeOpt then pcall(function() safeOpt:setValue(safeWas) end); pcall(ZeD.Safe.reread) end
    shut()
    for _, it in ipairs(given) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    given = {}
    if wasOpen.cw and not CW.isOpen() then pcall(CW.toggle, pn) end
    if wasOpen.ww and not WW.isOpen() then pcall(WW.open, pn) end
end)

local town, stash, bagMap, bag
local worldWinBefore = nil

-- ---- setup
step(1, function()
    p:setGodMod(true)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    town = give("Base.MuldraughMap")
    stash = give("Base.MuldraughMap")
    if stash then pcall(function() stash:setStashMap("MulStashMap1") end) end
    bag = give("Base.Bag_Schoolbag")
    bagMap = bag and bag:getInventory():AddItem("Base.RosewoodMap") or nil
    give("Base.Pencil"); give("Base.RedPen"); give("Base.Eraser")
    check(town and stash and bag and bagMap, "setup: a town map, a stash map, a map in a backpack, a pencil, a red pen and an eraser given")
    say("NOTE the stash map's stash: " .. tostring(stash and stash:getStashMap()) .. "; the town map's name: " .. tostring(town and town:getName()))
    shut()
end)

-- ---- 1. Read Map on the town map, the World window shut before
step(25, function()
    check(not WW.isOpen(), "1: the World window starts shut")
    readMap(town)
end)
waitFor(150, function() return paperUp(town) end, function(t)
    keepDown(ww())
    check(not t, "1.1: ZeD's map window opens on the town map")
    local pop = popOf()
    check(pop ~= nil and pop.title == town:getName(), "1.1: titled with the map's name (" .. tostring(pop and pop.title) .. ")")
    check(gameWin.map == 0 and gameWin.wrap == 0, "1.1: no game ISMap window was made")
    check(ww() and ww()._mapPaperOwnsWindow == true, "1.2: Read Map opened the World window just for the paper")
end)
step(45, function()
    keepDown(ww())
    local w = ww()
    local mp = w and w._worldMapPanel
    check(mp ~= nil and mp._paperItem == town, "1.1: the map panel is bound to the paper")
    check(mp ~= nil and mp._paperRevealed == true, "1.1: the paper's area was read and revealed on the world map")
    check(mp ~= nil and mp._paperViewSet == true, "1.1: the whole paper is put in view")
    local pop = popOf()
    check(pop ~= nil and pop:isReallyVisible(), "1.1: the window is on the screen")
end)
step(25, function() shot("paper_town") end)
-- 1.2 close it: the World window it opened goes again
step(5, function()
    local pop = popOf()
    if pop then pcall(pop.close, pop) end
end)
step(15, function()
    check(noPaper(), "1.2: the paper is put away")
    check(not WW.isOpen(), "1.2: the World window Read Map opened closes with it")
end)

-- ---- 1.4 a map in a backpack: the game's transfer first, then the window
step(10, function()
    check(bagMap and bagMap:getContainer() ~= inv, "1.4: the map starts in the backpack")
    readMap(bagMap)
end)
waitFor(600, function() return paperUp(bagMap) end, function(t)
    keepDown(ww())
    check(not t, "1.4: after the character moves it to the main inventory the window opens on it")
    check(bagMap and bagMap:getContainer() == inv, "1.4: the map is now in the main inventory")
    local pop = popOf()
    if pop then pcall(pop.close, pop) end
end)
step(15, function() end)

-- ---- 2. a stash map: the Find on map button
step(10, function()
    shut()
end)
step(20, function() readMap(stash) end)
waitFor(150, function() return paperUp(stash) end, function(t)
    keepDown(ww())
    check(not t, "2.1: ZeD's map window opens on the stash map")
end)
step(40, function()
    keepDown(ww())
    local ext = PM.ext
    local b = ext and ext.button and ext.button(ww()) or nil
    check(b ~= nil and b.id == "paperfind", "2.2: the band has the Find on map button (" .. tostring(b and b.text) .. ")")
    if b then say("NOTE 2.2 help line: " .. tostring(b.help) .. "; greyed: " .. tostring(b.dim)) end
    local tb = ext and ext.button and ext.button(nil)
    local pbt = PM.itemOf(ww())
    check(pbt == stash, "2.2: the paper in the window is the stash map")
    local tf = nil
    if town then
        -- the town map has no stash: no such button on it
        local w = ww()
        local keep = w._mapPaperItem
        w._mapPaperItem = town
        tf = ext.button(w)
        w._mapPaperItem = keep
    end
    check(tf == nil, "2.2: a town map has no Find on map button")
    shot("paper_stash")
end)
-- 2.3 press it: the reading bar, then the world map opens and the paper goes
local findBusy = false
step(5, function()
    local w = ww()
    if ISWorldMap and ISWorldMap.IsAllowed and not ISWorldMap.IsAllowed() then
        say("NOTE 2.3: the world map is not allowed here; the press is skipped")
        return
    end
    findBusy = true
    local ok = PM.revealOnWorldMap(w)
    check(ok == true, "2.3: Find on map starts the game's map-reading action")
end)
waitFor(900, function() return not findBusy or (not ISTimedActionQueue.isPlayerDoingAction(p) and noPaper()) end, function(t)
    if not findBusy then return end
    keepDown(ww())
    check(not t, "2.3: the reading bar ended")
    check(paperOf() == nil, "2.3: the paper is put away")
end)
step(30, function()
    if not findBusy then return end
    keepDown(ww())
    check(WW.isOpen(), "2.3 / 4.6: the World window stays open")
    local w = ww()
    check(w and w._mapPopout ~= nil and w._mapPaperItem == nil, "2.3: ZeD's world map is unfolded")
    shot("find_on_map")
    if w and w._mapPopout then pcall(MT.closePopout, w, true) end
end)
step(15, function() if findBusy then check(WW.isOpen(), "4.6: folding that world map leaves the World window open") end end)

-- ---- 4. closing rules (World window shut first)
-- 4.1 dropped map
step(10, function() shut() end)
step(20, function() readMap(town) end)
waitFor(150, function() return paperUp(town) end, function(t)
    keepDown(ww())
    check(not t, "4.1: the paper is up")
    inv:Remove(town)     -- the map leaves the main inventory (as a drop does)
end)
step(30, function()
    check(noPaper(), "4.1: with the map out of the main inventory the paper closes by itself")
    check(not WW.isOpen(), "4.1: and the World window it opened goes with it")
    local ok = pcall(function() inv:AddItem(town) end)
    check(ok and town:getContainer() == inv, "4.1: (the map is back in the inventory)")
end)
-- 4.2 a second map replaces the first, the World window stays meanwhile
step(10, function() shut() end)
step(20, function() readMap(town) end)
waitFor(150, function() return paperUp(town) end, function() keepDown(ww()) end)
step(10, function() readMap(stash) end)
waitFor(150, function() return paperUp(stash) end, function(t)
    keepDown(ww())
    check(not t, "4.2: reading a second map replaces the first")
    check(WW.isOpen(), "4.2: the World window stays meanwhile")
    local pop = popOf()
    if pop then pcall(pop.close, pop) end
end)
step(15, function()
    check(noPaper(), "4.2: the second paper is away")
    check(not WW.isOpen(), "4.2: closing the second paper closes the World window the first Read Map opened")
end)
-- 4.3 the unfolded world map folds for a paper
step(10, function() shut() end)
step(15, function() pcall(WW.open, pn) end)
step(40, function()
    keepDown(ww())
    local w = ww()
    if w and not w._mapPopout then pcall(MT.openPopout, w) end
end)
step(25, function()
    keepDown(ww())
    check(popOf() ~= nil and paperOf() == nil, "4.3: the world map is unfolded")
    readMap(town)
end)
waitFor(150, function() return paperUp(town) end, function(t)
    keepDown(ww())
    check(not t, "4.3: Read Map on a paper folds the world map and opens the paper")
    check(ww() and ww()._mapPaperOwnsWindow ~= true, "4.3: the World window was open before (the paper does not own it)")
end)
-- 4.7 the World window's own fold keeps the World window
step(10, function()
    local w = ww()
    if w then pcall(MT.closePopout, w, true) end
end)
step(15, function()
    check(noPaper() and WW.isOpen(), "4.7: the World window's own fold puts the paper away and keeps the World window")
end)
-- 2 (World window open before): close the paper by its close box, the World window stays
step(10, function() readMap(town) end)
waitFor(150, function() return paperUp(town) end, function(t)
    keepDown(ww())
    local pop = popOf()
    if pop then pcall(pop.close, pop) end
end)
step(15, function()
    check(noPaper() and WW.isOpen(), "4.0: a World window that was open before stays open when the paper closes")
end)
-- 4.5 closing the World window folds the paper
local oldPop = nil
step(10, function() readMap(town) end)
waitFor(150, function() return paperUp(town) end, function(t)
    keepDown(ww())
    oldPop = popOf()
    pcall(WW.close)
end)
step(25, function()
    check(not WW.isOpen(), "4.5: the World window is shut")
    check(oldPop ~= nil and not oldPop:isReallyVisible(), "4.5: the paper went with it, nothing left on the screen")
    check(PM._paperWin == nil, "4.5: the paper map module holds nothing")
end)

-- ---- 7.1 safe mode: the game's own window
step(15, function()
    if not safeOpt then say("NOTE 7.1: no safe mode option found; skipped"); return end
    if ZeD.Safe.on() then say("NOTE 7.1: safe mode is already on; skipped"); return end
    gameWin.map, gameWin.wrap = 0, 0
    setSafe(2)
end)
step(60, function()
    if not safeOpt or not ZeD.Safe.on() then return end
    readMap(town)
end)
step(40, function()
    if not safeOpt or not ZeD.Safe.on() then return end
    check(gameWin.map == 1, "7.1: safe mode on: the game's own ISMap window opens (made " .. gameWin.map .. ")")
    check(popOf() == nil, "7.1: and ZeD's paper window does not")
    shot("safe_mode_map")
    closeGameMap()
    setSafe(safeWas or 1)
end)
step(60, function()
    check(not ZeD.Safe.on(), "7.1: safe mode is back off")
end)

ticker = onTick
Events.OnTick.Add(ticker)
say("start")
