-- ZeDUI/tools/qa/gallery_cinema_lib.lua  (Nov 4 2026, QA; the director's cinema breaks for the gallery)
-- Shared helpers for gallery_cinema_<who>.lua, run first in the same game session (globals stay). Run after
-- gallery_t14_look.lua (no debug text, the default look). grep "ZEDQA cinlib".
CIN = {}
local C = CIN
C.core = getCore()
C.gt = getGameTime()

-- a frame sequencer on OnTick: C.seq(tag) -> S with S.step(frames, fn), S.poll(frames, max, fn), S.run()
function C.seq(tag)
    local S = { q = {}, qi = 0, wait = 0, tag = tag }
    function S.say(s) print("ZEDQA " .. tag .. " " .. tostring(s)) end
    function S.step(n, fn) S.q[#S.q + 1] = { n = n, fn = fn } end
    function S.poll(n, max, fn) S.q[#S.q + 1] = { n = n, fn = fn, max = max, poll = true } end
    function S.run()
        local cnt = 0
        local function tick()
            local q = S.q[S.qi + 1]
            if not q then Events.OnTick.Remove(tick); return end
            S.wait = S.wait + 1
            if S.wait < q.n then return end
            if q.poll then
                cnt = cnt + 1
                local ok, done = pcall(q.fn)
                if not ok then S.say("ERR " .. tostring(done)) end
                if (ok and done) or cnt >= q.max or not ok then S.qi = S.qi + 1; S.wait = 0; cnt = 0 end
                return
            end
            S.wait = 0
            S.qi = S.qi + 1
            local ok, err = pcall(q.fn)
            if not ok then S.say("ERR step " .. S.qi .. ": " .. tostring(err)) end
        end
        Events.OnTick.Add(tick)
        S.say("start")
    end
    return S
end

function C.player() return getPlayer() end

function C.moveTo(x, y, z)
    local p = getPlayer()
    p:setX(x + 0.5); p:setY(y + 0.5); p:setZ(z or 0)
    p:setLastX(x + 0.5); p:setLastY(y + 0.5); p:setLastZ(z or 0)
end

-- dressed from scratch: wear = { "Base.X", ... } (first free place each), hand = "Base.Y"
function C.dress(wear, hand, extra)
    local p = getPlayer()
    local inv = p:getInventory()
    local old = {}
    pcall(function() local wi = p:getWornItems(); for i = 0, wi:size() - 1 do old[#old + 1] = wi:get(i):getItem() end end)
    for _, it in ipairs(old) do pcall(function() p:removeWornItem(it, false) end); pcall(function() inv:Remove(it) end) end
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    -- (the carried load too: a believable kit only)
    pcall(function()
        local items = inv:getItems()
        local rm = {}
        for i = 0, items:size() - 1 do rm[#rm + 1] = items:get(i) end
        for _, it in ipairs(rm) do inv:Remove(it) end
    end)
    local worn = {}
    for _, ft in ipairs(wear or {}) do
        local it = inv:AddItem(ft)
        if it then
            local ok = pcall(function() p:setWornItem(it:getBodyLocation(), it) end)
            if ok then worn[#worn + 1] = it else inv:Remove(it) end
        end
    end
    if hand then local h = inv:AddItem(hand); if h then p:setPrimaryHandItem(h); if h:isTwoHandWeapon() then p:setSecondaryHandItem(h) end end end
    for _, ft in ipairs(extra or {}) do inv:AddItem(ft) end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    pcall(function() p:resetModelNextFrame() end)
    return worn
end

-- a worn item's tint (r, g, b in 0..1)
function C.tint(ft, r, g, b)
    local p = getPlayer()
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local it = wi:get(i):getItem()
        if it:getFullType() == ft then
            pcall(function() it:getVisual():setTint(ImmutableColor.new(r, g, b, 1)) end)
            pcall(function() it:setColor(Color.new(r, g, b, 1)) end)
            pcall(function() it:synchWithVisual() end)
        end
    end
    pcall(function() p:resetModelNextFrame() end)
end

function C.time(h) pcall(function() C.gt:setTimeOfDay(h) end) end

-- clear skies (no fog, rain or cloud)
function C.clearSky()
    pcall(function()
        local cm = getClimateManager()
        for i = 0, cm:getFloatMax() - 1 do
            local v = cm:getClimateFloat(i)
            local l = tostring(v:getName()):lower()
            if l:find("fog", 1, true) or l:find("precip", 1, true) or l:find("cloud", 1, true) then v:setEnableAdmin(true); v:setAdminValue(0) end
        end
    end)
end

function C.zoom(S, z)
    local left = nil
    S.poll(20, 200, function()
        if left == nil then left = math.floor((C.core:getZoom(0) - z) / 0.25 + 0.5) end
        if left == 0 then return true end
        C.core:doZoomScroll(0, (left > 0) and -1 or 1)
        left = (left > 0) and (left - 1) or (left + 1)
        return left == 0
    end)
    S.step(90, function() S.say("zoom " .. tostring(C.core:getZoom(0))) end)
end

-- the windows: which are shown, and their tabs (nil leaves a window closed)
function C.windows(charTab, worldTab)
    local cw = ZeD_CharacterWindow.getWindow()
    if not (cw and cw:getIsVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    cw = ZeD_CharacterWindow.getWindow()
    local ww = ZeD_WorldWindow.getWindow()
    for _, w in ipairs({ cw, ww }) do if w then if w.setPinned then w:setPinned(true) else w.pinned = true end; if w.windowShaded then w:setWindowShaded(false) end end end
    -- QA's checks leave the windows moved and resized in the saves: back to the default spread first (the window
    -- menu's "Reset windows"), then the tabs
    if ZeD_Window and ZeD_Window.resetLayout then pcall(ZeD_Window.resetLayout) end
    if charTab then cw:setVisible(true); cw._activeTab = charTab; cw._drawerMode = "tab"; cw._drawerOpen = true else cw:setVisible(false) end
    if ww then
        if worldTab then ww:setVisible(true); ww._activeTab = worldTab; ww._drawerMode = "tab"; ww._drawerOpen = true else ww:setVisible(false) end
    end
end
function C.noWindows()
    local cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    if cw then cw:setVisible(false) end
    if ww then ww:setVisible(false) end
end

function C.shot(S, name)
    local ok = pcall(function() C.core:TakeFullScreenshot("cin_" .. name .. ".png") end)
    S.say("shot " .. name .. " " .. tostring(ok))
end

-- a vehicle on a square, facing dir ("N" "E" "S" "W"); white = true paints it white
function C.car(script, x, y, dir, white)
    local sq = getCell():getGridSquare(x, y, 0)
    if not sq then return nil end
    local v = nil
    pcall(function() v = addVehicleDebug(script, IsoDirections[dir or "E"], nil, sq) end)
    if v and white then pcall(function() v:setColorHSV(0, 0, 0.92) end) end
    return v
end

function C.fire(x, y)
    local sq = getCell():getGridSquare(x, y, 0)
    if sq then pcall(function() IsoFireManager.StartFire(getCell(), sq, true, 100) end) end
end

-- the nearest road square (floor sprite with "street" or "road") around cx, cy with no building within `clear`
function C.findRoad(cx, cy, r, clear)
    local cell = getCell()
    local best, bd = nil, 1e9
    for dx = -r, r, 2 do for dy = -r, r, 2 do
        local sq = cell:getGridSquare(cx + dx, cy + dy, 0)
        local fl = sq and sq:getFloor()
        local nm = fl and fl:getSprite() and fl:getSprite():getName() or ""
        nm = string.lower(tostring(nm))
        if nm:find("street", 1, true) or nm:find("road", 1, true) then
            local ok = true
            for ex = -clear, clear, 3 do for ey = -clear, clear, 3 do
                local s2 = cell:getGridSquare(cx + dx + ex, cy + dy + ey, 0)
                if s2 and s2:getBuilding() then ok = false end
            end end
            local d = dx * dx + dy * dy
            if ok and d < bd then best, bd = { cx + dx, cy + dy }, d end
        end
    end end
    return best
end

print("ZEDQA cinlib loaded")
local n = 0
local function t() n = n + 1; if n == 10 then Events.OnTick.Remove(t); print("ZEDQA cinlib DONE") end end
Events.OnTick.Add(t)

-- a scene's look: base "dark" | "light" | "hicon", accent "red" | "orange" | ... (the mod's own options, so the windows
-- repaint as a player's choice would; gallery_t14_end.lua puts the director's look back)
function C.look(base, accent)
    local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
    if not opts then return end
    local function idx(list, key) for i, k in ipairs(list) do if k == key then return i end end end
    local b, a = idx(ZeD.Settings.baseKeys, base), idx(ZeD.Settings.accentKeys, accent)
    if b then pcall(function() opts:getOption("baseTheme"):setValue(b) end) end
    if a then pcall(function() opts:getOption("accentColor"):setValue(a) end) end
    pcall(function() ZeD.Settings.reapplyFromOptions() end)
    for _, w in ipairs({ ZeD_CharacterWindow.getWindow() or false, ZeD_WorldWindow.getWindow() or false }) do
        if w then w._accentKey = nil end
    end
    print("ZEDQA cinlib look " .. tostring(base) .. " " .. tostring(accent))
end

-- the game draws ground the character has never looked at as black: turn a full circle (every direction for a moment)
-- so the whole view counts as seen, then face `final`
function C.lookAround(S, final)
    local dirs = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
    for _, d in ipairs(dirs) do
        S.step(12, function() getPlayer():setDir(IsoDirections[d]) end)
    end
    S.step(12, function() getPlayer():setDir(IsoDirections[final]) end)
end

-- a rerun on a shot save finds the last run's props (the save keeps them): remove vehicles within r of x, y and the
-- litter, broken glass and fires the scene scripts lay down
function C.clearScene(x, y, r, z)
    z = z or 0
    local cell = getCell()
    local gone = 0
    local list = {}
    local it = cell:getVehicles():iterator()      -- (a set, not a list: no get(i))
    while it:hasNext() do
        local v = it:next()
        if math.abs(v:getX() - x) <= r and math.abs(v:getY() - y) <= r then list[#list + 1] = v end
    end
    for _, v in ipairs(list) do if pcall(function() v:permanentlyRemove() end) then gone = gone + 1 end end
    local litter = 0
    for dx = -r, r do for dy = -r, r do
        local sq = cell:getGridSquare(x + dx, y + dy, z)
        if sq then
            pcall(function() sq:stopFire() end)
            local objs = sq:getObjects()
            for i = objs:size() - 1, 0, -1 do
                local o = objs:get(i)
                local nm = o:getSprite() and o:getSprite():getName() or ""
                if instanceof(o, "IsoBrokenGlass") or nm:find("^trash_01_") or nm:find("^d_trash_") or nm:find("^brokenglass") then
                    local ok = pcall(function() sq:RemoveTileObject(o) end)
                    if not ok then ok = pcall(function() sq:transmitRemoveItemFromSquare(o) end) end
                    if ok then litter = litter + 1 end
                end
            end
        end
    end end
    print("ZEDQA cinlib cleared " .. gone .. " vehicles, " .. litter .. " litter around " .. x .. "," .. y)
end

-- every window within r of x, y on floor z smashed (the game's own smash: glass falls, the frame stays)
function C.smashWindows(x, y, r, z)
    local cell, n = getCell(), 0
    for dx = -r, r do for dy = -r, r do
        local sq = cell:getGridSquare(x + dx, y + dy, z)
        if sq then
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                if instanceof(o, "IsoWindow") and not o:isSmashed() then
                    if pcall(function() o:setSmashed(true) end) or pcall(function() o:smashWindow(true) end) then n = n + 1 end
                end
            end
        end
    end end
    print("ZEDQA cinlib smashed " .. n .. " windows")
    return n
end

-- broken glass on floor squares around x, y (a fixed pattern, never on the character's own square)
function C.glass(x, y, r, z, count)
    local cell, seed, n = getCell(), 11, 0
    local function rnd(m) seed = (seed * 1103515245 + 12345) % 2147483648; return seed % m end
    for i = 1, count * 3 do
        if n >= count then break end
        local gx, gy = x + rnd(r * 2 + 1) - r, y + rnd(r * 2 + 1) - r
        local sq = cell:getGridSquare(gx, gy, z)
        if sq and sq:getFloor() and not (gx == x and gy == y) then
            local ok = pcall(function() local g = IsoBrokenGlass.new(cell); g:setSquare(sq); sq:AddTileObject(g) end)
            if ok then n = n + 1 end
        end
    end
    return n
end

-- the pointer out of the picture (the director): the real mouse (release_check_mouse.ps1, started by cinema_run.ps1)
-- moves it to the bottom right corner, which the cinema frame's right curtain covers anyway. Run it before the
-- windows open: a pointer moving off a window clears its hover state.
function C.pointerAway(S)
    local w, h = getCore():getScreenWidth(), getCore():getScreenHeight()
    S.step(2, function()
        pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
        pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write("move " .. (w - 6) .. " " .. (h - 6)); f:close() end)
    end)
    S.poll(5, 120, function()
        local r = getFileReader("zedqa_click_done.txt", false)
        local l = r and r:readLine(); if r then r:close() end
        return l ~= nil and l:find("done", 1, true) ~= nil
    end)
    S.step(5, function() S.say("pointer away " .. getMouseX() .. "," .. getMouseY()) end)
end

-- the character's profession (the director: one that fits the role), e.g. "VETERAN" (CharacterProfession's names)
function C.profession(name)
    local ok = pcall(function() getPlayer():getDescriptor():setCharacterProfession(CharacterProfession[name]) end)
    print("ZEDQA cinlib profession " .. name .. " " .. tostring(ok))
end
