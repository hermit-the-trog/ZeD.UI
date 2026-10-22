-- ZeDUI/tools/qa/zedqa_gallery_more.lua  (Oct 21 2026)
-- More Steam Workshop screenshots, after the director's review of the first
-- gallery: the same windows in the three base themes, and the same scene with
-- vanilla's windows and with ZeD's (before and after). Each one is a
-- getCore():TakeFullScreenshot in Zomboid/Screenshots:
--   ws_30_theme_dark.png  ws_31_theme_light.png  ws_32_theme_hicon.png
--   ws_33_compare_zed.png ws_34_compare_vanilla.png
-- Meant for the ZeD-QA save at 4K fullscreen like zedqa_gallery_shots.lua (its
-- helpers are copied from there). It stays where the character stands: builds a
-- crate on a free square beside it and fills it, sets 10:00 and clear weather.
-- The themes are switched with ZeD.applyTheme only (nothing is written to the
-- options file); the per-window accents are lifted for those shots so each
-- window shows its theme's own accent. Vanilla's windows come from Safe mode,
-- switched on in memory (not saved) and off again.
-- The pair is placed side by side, centred, and left that way.
-- Everything else is put back: theme and window accents (from the stored options),
-- Safe mode, the clothes and pocket things it adds, the crate and its items, time, weather, windows, tabs, game speed.
-- NOT in regression.txt (it changes the theme and Safe mode mid-run).
-- Output: ZEDQA wsm <nn> <name> ok | ZEDQA wsm <nn> ERR <reason> | ZEDQA wsm DONE
local TAG = "wsm"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
if not (ZeD and ZeD.Settings and ZeD.trTestOn and ZeD_CharacterWindow and ZeD_WorldWindow and ZeD.applyTheme) then say("ERR ZeD is not loaded"); return end
if ZeD.trTestOn() then say("ERR the test language is On: turn it Off first; nothing was touched"); return end
if ZeD.Safe and ZeD.Safe.on() then say("ERR safe mode is already on; nothing was touched"); return end

local pn = p:getPlayerNum()
local core, gt = getCore(), getGameTime()
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local safeOpt = ZeD.Settings.safeModeOption
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end

local was = {
    tod = gt:getTimeOfDay(), speed = getGameSpeed(),
    char = CWm.isOpen(), world = WWm.isOpen(),
    cwTab = CW() and CW()._activeTab, wwTab = WW() and WW()._activeTab,
    base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize,
    safe = safeOpt and safeOpt:getValue() or 1, cheat = false,
}
pcall(function() was.cheat = p:isBuildCheat() end)
local X = { clim = {}, crate = nil, crateInv = nil, crateSq = nil, items = {}, worn = {}, added = {}, nOk = 0, nErr = 0 }
local inv = p:getInventory()

-- dressed for the pictures (the QA character is often in its underwear), and a few
-- things in its pockets so its own list is not empty; worn only into free places
local function wear(full)
    local it = inv:AddItem(full)
    if not it then say("note: could not add " .. full); return nil end
    local busy = false
    pcall(function() busy = p:getWornItem(it:getBodyLocation()) ~= nil end)
    if busy then inv:Remove(it); return nil end
    p:setWornItem(it:getBodyLocation(), it)
    X.worn[#X.worn + 1] = it
    return it
end
local function dress()
    for _, ft in ipairs({ "Base.Tshirt_DefaultTEXTURE_TINT", "Base.Trousers_Denim", "Base.Shoes_Black", "Base.Socks_Ankle",
                          "Base.Jacket_Varsity", "Base.Hat_BaseballCapBlue", "Base.Belt2" }) do wear(ft) end
    for _, ft in ipairs({ "Base.Apple", "Base.Apple", "Base.Chocolate", "Base.WaterBottle", "Base.WalkieTalkie2", "Base.Machete", "Base.Book" }) do
        local it = inv:AddItem(ft)
        if it then X.added[#X.added + 1] = it end
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    say("dressed: worn " .. #X.worn .. ", added " .. #X.added)
end
local function undress()
    for _, it in ipairs(X.worn) do pcall(function() p:removeWornItem(it) end) end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    for _, it in ipairs(X.worn) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    for _, it in ipairs(X.added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    X.worn, X.added = {}, {}
end

local function shot(nn, name)
    local f = string.format("ws_%02d_%s.png", nn, name)
    local ok, e = pcall(function() core:TakeFullScreenshot(f) end)
    if ok then X.nOk = X.nOk + 1; say(string.format("%02d %s ok", nn, name))
    else X.nErr = X.nErr + 1; say(string.format("%02d ERR %s: %s", nn, name, tostring(e))) end
end

-- the sequencer (as zedqa_gallery_shots.lua)
local tick, qi, lastDone = 0, 1, 0
local queue = {}
local function step(after, fn) queue[#queue + 1] = { after = after, fn = fn } end

-- weather (zedqa_gallery_shots.lua)
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
    for _, c in ipairs(X.clim) do pcall(function() c.v:setAdminValue(c.val); c.v:setEnableAdmin(c.en) end) end
    X.clim = {}
end

-- windows and tabs (zedqa_gallery_shots.lua)
local function openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
end
local function closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
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

-- the crate (zedqa_gallery_shots.lua / zedqa_padlock.lua)
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
    local info = findInfo("Base.Wood_Crate_Lvl1")
    if not info then return false, "no entity info for the crate" end
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    p:setBuildCheat(true)
    local built = false
    for _, d in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local x, y = px + d[1], py + d[2]
        local sq = getCell():getGridSquare(x, y, 0)
        if sq and not thumpOn(sq) then
            local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
            b.buildCheat = true
            b.player = pn
            local ok, valid = pcall(function() b.sq = sq; return b:isValid(sq) end)
            if ok and valid then
                pcall(function() b:create(x, y, 0, false, nil) end)
                if thumpOn(sq) then X.crateSq = sq; built = true; break end
            end
        end
    end
    p:setBuildCheat(was.cheat)
    if not built then return false, "no free square for the crate beside the character" end
    X.crate = thumpOn(X.crateSq)
    X.crateInv = X.crate:getContainer()
    for _, ft in ipairs({ "Base.Hammer", "Base.Saw", "Base.Screwdriver", "Base.Wrench", "Base.Nails", "Base.TinnedBeans",
                          "Base.TinnedBeans", "Base.Bandage", "Base.Rope", "Base.Battery", "Base.DuctTape", "Base.Crisps", "Base.Peanuts" }) do
        local it = X.crateInv:AddItem(ft)
        if it then X.items[#X.items + 1] = it end
    end
    pcall(function() p:faceThisObject(X.crate) end)
    say("crate ready with " .. #X.items .. " things")
    return true
end
local function removeCrate()
    for _, it in ipairs(X.items) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    X.items = {}
    local o, sq = X.crate, X.crateSq
    if o and sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        local still = thumpOn(sq)
        if still then pcall(function() sq:RemoveTileObject(still) end) end
    end
    X.crate, X.crateInv, X.crateSq = nil, nil, nil
end

-- the pair side by side, centred, a small gap between (the saved layout can leave the
-- World window over the Character window; director, Oct 21: "sit next to each other,
-- not overlapped"). The Character window keeps its right edge as its anchor.
local function placePair()
    local c, w = CW(), WW()
    if not (c and w) then return false end
    local gap = ZeD.T and ZeD.T.px and ZeD.T.px(8) or 16
    local cw, ww = c:getWidth(), w:getWidth()
    local x0 = math.floor((getCore():getScreenWidth() - (cw + gap + ww)) / 2)
    c._anchorRightEdge = x0 + cw
    c:setX(x0)
    w:setX(x0 + cw + gap)
    return true
end
local function pairText()
    local c, w = CW(), WW()
    if not (c and w) then return "pair not open" end
    local f = math.floor
    return string.format("char x %d..%d, world x %d..%d", f(c:getX()), f(c:getX() + c:getWidth()), f(w:getX()), f(w:getX() + w:getWidth()))
end

local function showCrate()
    if X.crateInv then pcall(function() WWm.selectContainer(X.crateInv, 150) end) end
end
local function setSafe(v)
    if not safeOpt then return false end
    safeOpt:setValue(v)
    ZeD.Safe.reread()
    return true
end

-- ---- 1. the scene ----------------------------------------------------------------
step(1, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    gt:setTimeOfDay(10.0)
    clearWeather()
    local ok, why = buildCrate()
    if not ok then say("ERR " .. tostring(why)) end
    dress()
end)
step(30, function() openPair() end)
step(40, function() charTab("loot"); worldTab("loot"); showCrate() end)
step(40, function() showCrate(); placePair() end)
step(20, function() placePair(); say("placed: " .. pairText()) end)

-- ---- 2. the three base themes ------------------------------------------------------
local THEMES = { { 30, "theme_dark", "dark", "orange" }, { 31, "theme_light", "light", "blue" }, { 32, "theme_hicon", "hicon", "teal" } }
for _, t in ipairs(THEMES) do
    step(10, function()
        ZeD.applyTheme(t[3], t[4], was.size)
        local c, w = CW(), WW()
        if c then c._accentKey = nil end
        if w then w._accentKey = nil end
        showCrate()
    end)
    step(20, function() placePair() end)
    step(30, function() say(t[2] .. ": " .. pairText()); shot(t[1], t[2]) end)
end
step(10, function() pcall(ZeD.Settings.reapplyFromOptions) end)
step(50, function()
    say(string.format("theme back: %s %s %s", tostring(ZeD.currentBase), tostring(ZeD.currentAccent), tostring(ZeD.currentSize)))
    showCrate()
end)

-- ---- 3. the same scene with ZeD, then with vanilla ----------------------------------
step(10, function() placePair() end)
step(30, function() say("compare: " .. pairText()); shot(33, "compare_zed") end)
step(5, function()
    closePair()
    if not setSafe(2) then say("ERR no Safe mode option") end
end)
step(60, function()
    local vi, vl = getPlayerInventory(pn), getPlayerLoot(pn)
    for _, pg in ipairs({ vi, vl }) do
        if pg then
            pcall(function() pg:setVisible(true) end)
            pcall(function() pg.pin = true; pg.isCollapsed = false; pg:clearMaxDrawHeight() end)
        end
    end
    pcall(function() vl:refreshBackpacks() end)
    -- the crate's button in vanilla's loot page, so it shows the crate
    pcall(function()
        for _, b in ipairs(vl.backpacks or {}) do
            if b.inventory == X.crateInv then vl:selectContainer(b); break end
        end
    end)
    say("vanilla pages: inventory " .. tostring(vi and vi:isVisible()) .. " loot " .. tostring(vl and vl:isVisible()))
end)
step(60, function() shot(34, "compare_vanilla") end)

-- ---- 4. put everything back -------------------------------------------------------
step(5, function()
    local vi, vl = getPlayerInventory(pn), getPlayerLoot(pn)
    setSafe(was.safe)
end)
step(60, function()
    pcall(function() ISTimedActionQueue.clear(p) end)
    if was.char and was.world then openPair()
    else
        closePair()
        if was.char then CWm.toggle(0) end
        if was.world then WWm.open(0) end
    end
end)
step(40, function()
    placePair()   -- left side by side (the layout the director asked for), not put back over each other
    if was.cwTab and CW() then charTab(was.cwTab) end
    if was.wwTab and WW() then worldTab(was.wwTab) end
    removeCrate()
    undress()
    restoreWeather()
    gt:setTimeOfDay(was.tod)
    if getGameSpeed() <= 0 then setGameSpeed(was.speed > 0 and was.speed or 1) end
end)
step(30, function()
    local vi = getPlayerInventory(pn)
    say(string.format("back: theme %s %s %s | safe %s | char %s world %s | vanilla inventory shown %s | %d shots ok, %d errors",
        tostring(ZeD.currentBase), tostring(ZeD.currentAccent), tostring(ZeD.currentSize), tostring(ZeD.Safe.on()),
        tostring(CWm.isOpen()), tostring(WWm.isOpen()), tostring(vi and vi:isVisible()), X.nOk, X.nErr))
    say("DONE")
end)

local function onFrame()
    tick = tick + 1
    local s = queue[qi]
    if not s then Events.OnRenderTick.Remove(onFrame); return end
    if not s.startTick then
        if tick - lastDone < s.after then return end
        s.startTick = tick
    end
    local ok, r = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " (frame " .. tick .. ") " .. tostring(r)) end
    lastDone = tick
    qi = qi + 1
end
Events.OnRenderTick.Add(onFrame)
say("start (" .. #queue .. " steps)")
