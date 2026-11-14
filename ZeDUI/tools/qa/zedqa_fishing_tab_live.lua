-- ZeDUI/tools/qa/zedqa_fishing_tab_live.lua  (Nov 11 2026, QA, punch list 167; built on zedqa_fish_smoke.lua)
local setGameSpeed = ZEDQA_SPEED or setGameSpeed   -- (Nov 13 2026: the prelude's speed sets the time multiplier too; see zedqa_prelude.lua)
-- The World window's Fishing tab checked live, with ZeD on and a real cast and catch at the shore 13913,4555 facing east.
-- Needs the real mouse (release_check_mouse.ps1) running beside the game, as zedqa_fish_smoke.lua does. grep "ZEDQA ftl".
-- Pictures zqa_ftl_on_<n>.png. Run: zedqa_run.ps1 -Mode fullscreen4k -Manifest zedqa_fishing_tab_live.txt (then the manifest's second
-- script after a quit and a fresh start (zedqa_fishing_tab_live_reload.lua, tag ftr): the saved records came back).
--   a  the World window is open on another tab, parked top left; the tab's Cast pressed with no aim: says to aim first
--   b  a real left click on the water (the pointer away from the window): the line goes out; the Fishing tab comes up by itself
--   c  a fish on: the real left button held on the tab's Reel in button reels (the game's ReelIn state, rod:isReel), to the landing
--   d  the landing wrote the catch log (ZeD.FishingLog.data)
--   e  Idle aimed at water again: the tab's Cast calls the game's Cast
--   f  the wall (three trophies added, then taken away): D-pad right / left across the plaques, B leaves the wall
--   g  the Fishing tab's icon pictures load; a picture of the tab strip
--   the catch stays in the player's mod data for the reload script; Lua/zedqa_ftl_expect.txt says what to look for
local TAG = "ftl"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local R = { pass = 0, fail = 0 }
local function check(ok, s) if ok then R.pass = R.pass + 1 else R.fail = R.fail + 1 end; say((ok and "PASS " or "FAIL ") .. s); return ok end
local p = getPlayer()
local pn = p:getPlayerNum()
local core = getCore()
local gt = getGameTime()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local ZED = (ZeD ~= nil and ZeD.FishRod ~= nil and Fishing ~= nil and Fishing.ISTensionUI ~= nil and Fishing.ISTensionUI._zedOrigRender ~= nil)
local MODE = ZED and "on" or "off"
local T0 = getTimestampMs()
local function el() return string.format("%.1fs", (getTimestampMs() - T0) / 1000) end
local function clock() return string.format("%02d:%02d", gt:getHour(), gt:getMinutes()) end
local function shot(n)
    local nm = "zqa_ftl_" .. MODE .. "_" .. n .. ".png"
    pcall(function() core:TakeFullScreenshot(nm) end)
    say("shot " .. nm)
end
local okV, ver = pcall(function() return getCore():getVersion() end)
say("start; ZeD " .. MODE .. "; screen " .. sw .. "x" .. sh .. "; game " .. tostring(okV and ver or "?"))

-- ------------------------------------------------------------------ state to put back
local O = { ids = {}, md = {}, consoles = {} }
O.x, O.y, O.z = p:getX(), p:getY(), p:getZ()
O.h1, O.h2 = p:getPrimaryHandItem(), p:getSecondaryHandItem()
O.speed = getGameSpeed()
O.god = p:isGodMod()
O.xp = p:getXp():getXP(Perks.Fishing)
O.lvl = p:getPerkLevel(Perks.Fishing)
local LOG = ZeD.FishingLog
local FT = ZeD.FishingTab
do
    local md0 = p:getModData()[LOG.KEY]
    O.hadData = type(md0) == "table"
    local d0 = LOG.data(p)
    O.n, O.fish, O.logN = d0.n, d0.fish, #d0.log
end
local function W() return ZeD_WorldWindow.getWindow() end
do
    local items = p:getInventory():getItems()
    for k = 0, items:size() - 1 do O.ids[items:get(k):getID()] = true end
    for key, v in pairs(p:getModData()) do
        local ks = tostring(key)
        if ks:find("fishing", 1, true) == 1 or ks:find("Fishing", 1, true) == 1 then
            if type(v) == "table" then local c = {}; for a, b in pairs(v) do c[a] = b end; O.md[ks] = c else O.md[ks] = v end
        end
    end
end
local S = { added = {}, undo = {} }
local function spawn(full)
    local it = p:getInventory():AddItem(full)
    if it then S.added[#S.added + 1] = it end
    return it
end
local function hookFn(tbl, name, wrap)
    local orig = tbl and tbl[name]
    if orig == nil then return false end
    tbl[name] = wrap(orig)
    S.undo[#S.undo + 1] = function() tbl[name] = orig end
    return true
end
local function newItems()
    local out = {}
    local items = p:getInventory():getItems()
    for k = 0, items:size() - 1 do
        local it = items:get(k)
        if not O.ids[it:getID()] then out[#out + 1] = it end
    end
    return out
end
local function queueEmpty()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    return not (q and q.queue and #q.queue > 0)
end

-- ------------------------------------------------------------------ the real mouse (release_check_mouse.ps1)
local MOUSE = { pending = false, sentAt = 0, cmd = "", dead = false, answered = 0, x = 0, y = 0, holding = false, lastRead = 0 }
local function mouseSend(cmd, x, y)
    x, y = math.floor(math.max(2, math.min(sw - 2, x))), math.floor(math.max(2, math.min(sh - 2, y)))
    pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
    pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write(cmd .. " " .. x .. " " .. y); f:close() end)
    MOUSE.pending, MOUSE.sentAt, MOUSE.cmd, MOUSE.x, MOUSE.y = true, getTimestampMs(), cmd, x, y
    MOUSE.onBtn = false
end
-- true once the helper has answered the last request (or gave up on it)
local function mouseIdle()
    if not MOUSE.pending then return true end
    local now = getTimestampMs()
    if now - MOUSE.lastRead < 150 then return false end
    MOUSE.lastRead = now
    local l = nil
    pcall(function() local r = getFileReader("zedqa_click_done.txt", false); if r then l = r:readLine(); r:close() end end)
    if l and l:find("done", 1, true) then MOUSE.pending = false; MOUSE.answered = MOUSE.answered + 1; return true end
    if now - MOUSE.sentAt > 9000 then
        MOUSE.pending = false; MOUSE.dead = true
        say("ERR the mouse helper never answered '" .. MOUSE.cmd .. "': the button is stood in for from here (FALLBACK)")
        return true
    end
    return false
end

-- ------------------------------------------------------------------ the fishing manager
local F = { phase = "setup", rod = nil, worms = {}, last = nil, shore = nil, tx = 0, ty = 0 }
local function mgr() return Fishing and Fishing.ManagerInstances and Fishing.ManagerInstances[pn] or nil end
local function stateName(m)
    m = m or mgr()
    if not m then return "nomanager" end
    for k, v in pairs(m.states or {}) do if v == m.state then return k end end
    return "?"
end
local function lineInfo(m)
    local s = ""
    pcall(function()
        local r = m and m.fishingRod
        if not r then s = "rod object nil"; return end
        s = "bobber " .. tostring(r.bobber ~= nil) .. " spawnDelay " .. string.format("%.1f", tonumber(r.spawnBobberDelayTimer) or -1)
        if r.bobber then
            s = s .. " fish " .. tostring(r.bobber.fish ~= nil) .. string.format(" tension %.2f", r:getTension())
            if r.bobber.fish then s = s .. " size " .. tostring(r.bobber.fish.fishSizeLen) .. " trash " .. tostring(r.bobber.fish.isTrash) end
        end
    end)
    return s
end
local function speedInfo()
    local fps = "?"
    pcall(function() fps = string.format("%.0f", getAverageFPS()) end)
    return string.format("speed %s mult %.3f fps %s", tostring(getGameSpeed()), gt:getMultiplier(), fps)
end
local function hasLure() return F.rod ~= nil and F.rod:getModData().fishing_Lure ~= nil end

-- ------------------------------------------------------------------ the shore
local function isWater(sq)
    if not sq then return false end
    local ok, r = pcall(function() return sq:getProperties() and sq:getProperties():has(IsoFlagType.water) end)
    return (ok and r) and true or false
end
local DIRS = { { "S", 0, 1 }, { "E", 1, 0 }, { "W", -1, 0 }, { "N", 0, -1 } }
local function findShores(cx, cy, r)
    local cell, out = getCell(), {}
    for dx = -r, r, 2 do for dy = -r, r, 2 do
        local x, y = cx + dx, cy + dy
        local sq = cell:getGridSquare(x, y, 0)
        if sq and sq:getFloor() and not isWater(sq) and not sq:getBuilding() and not sq:getTree() then
            for _, d in ipairs(DIRS) do
                local run = 0
                for k = 1, 7 do
                    if isWater(cell:getGridSquare(x + d[2] * k, y + d[3] * k, 0)) then run = run + 1 else break end
                end
                if run >= 6 then
                    local tx, ty = x + d[2] * 5 + 0.5, y + d[3] * 5 + 0.5
                    local fish, nofish = -1, false
                    pcall(function() fish = FishSchoolManager.getInstance():getFishAbundance(tx, ty) end)
                    pcall(function() nofish = Fishing.isNoFishZone(tx, ty) end)
                    if not nofish then out[#out + 1] = { x = x, y = y, dir = d[1], dx = d[2], dy = d[3], fish = fish, tx = tx, ty = ty } end
                end
            end
        end
    end end
    return out
end

-- ------------------------------------------------------------------ the UI under a point
local function uiUnder(mx, my)
    local names = {}
    pcall(function()
        local u = UIManager.getUI()
        for k = 0, u:size() - 1 do
            local e = u:get(k)
            if e:isVisible() then
                local x, y, w, h = e:getX(), e:getY(), e:getWidth(), e:getHeight()
                if mx >= x and mx < x + w and my >= y and my < y + h then
                    local nm = e:getClass():getSimpleName()
                    pcall(function() local t = e:getTable(); if t and t.Type then nm = tostring(t.Type) end end)
                    names[#names + 1] = nm .. "@" .. math.floor(x) .. "," .. math.floor(y) .. " " .. math.floor(w) .. "x" .. math.floor(h)
                end
            end
        end
    end)
    return names
end

-- ------------------------------------------------------------------ ZeD's rod meter (ZeD on only)
local Z = { draws = 0, drawsTrue = 0, logs = {}, lineOutDraws = 0 }
if ZED then
    hookFn(ZeD.FishRod, "draw", function(orig) return function(self, ox, oy, k, t, ...)
        local a, b = orig(self, ox, oy, k, t, ...)
        Z.draws = Z.draws + 1
        if a then Z.drawsTrue = Z.drawsTrue + 1 end
        Z.lastT, Z.lastBox = t, { ox + self:getAbsoluteX(), oy + self:getAbsoluteY(), ZeD.FishRod.W * k, ZeD.FishRod.H * k }
        return a, b
    end end)
    hookFn(ZeD, "logOnce", function(orig) return function(key, msg, ...)
        Z.logs[#Z.logs + 1] = tostring(key) .. ": " .. tostring(msg)
        say("ZeD log " .. tostring(key) .. ": " .. tostring(msg))
        return orig(key, msg, ...)
    end end)
end

-- the Fishing tab's band: remember the panel it draws on (to find the Reel in button on the screen)
local TB = { panel = nil, dx = 0, dy = 0 }
local D   -- (the driver below fills it; the plan steps above it read it)
hookFn(FT, "drawBand", function(orig) return function(panel, win, st, s, ...)
    TB.panel = panel
    return orig(panel, win, st, s, ...)
end end)
local function reelRect()
    local w = W()
    local stt = w and w._fishTab
    if not (stt and TB.panel and ZeD_WorldWindow.isTabShowing("fishing")) then return nil end
    for _, r in ipairs(stt.band or {}) do if r.b.id == "reel" then return r end end
    return nil
end
-- the screen point over the Reel in button (the pointer's place read back from the panel, and corrected)
local function reelPoint()
    local r = reelRect()
    if not r then return nil end
    local cx, cy = r.x + r.w / 2, r.y + r.h / 2
    local ok, mx, my = pcall(function() return TB.panel:getMouseX(), TB.panel:getMouseY() end)
    if ok and mx and MOUSE.x and not MOUSE.pending and MOUSE.onBtn then
        TB.dx, TB.dy = TB.dx + (cx - mx), TB.dy + (cy - my)
    end
    return TB.panel:getAbsoluteX() + cx + TB.dx, TB.panel:getAbsoluteY() + cy + TB.dy, r
end

-- ------------------------------------------------------------------ the plan
local plan, pi, pt0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function addWhen(max, cond, fn) plan[#plan + 1] = { ms = max, cond = cond, fn = fn } end

add(300, function()
    if getGameSpeed() == 0 then setGameSpeed(1); say("the game was paused: speed 1") end
    p:setGodMod(true)
    -- the debug console off the screen (it is not the player's; it would sit under the pointer)
    pcall(function()
        local u = UIManager.getUI()
        for k = 0, u:size() - 1 do local e = u:get(k); if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false); O.consoles[#O.consoles + 1] = e end end
    end)
    local cw, ww = nil, nil
    if ZED and ZeD_CharacterWindow and ZeD_WorldWindow then   -- (ZeD off: no probe, -debug logs even a caught error)
        pcall(function() cw = ZeD_CharacterWindow.getWindow(); ww = ZeD_WorldWindow.getWindow() end)
    end
    say("windows: character " .. tostring(cw and cw:isVisible()) .. ", world " .. tostring(ww and ww:isVisible()))
    say(string.format("fishing before: level %d xp %.1f; at %d,%d; %s", O.lvl, O.xp, math.floor(O.x), math.floor(O.y), clock()))
    say("manager before: " .. tostring(mgr() ~= nil) .. " state " .. stateName())
end)

-- the World window open on another tab, parked top left (the water is to the right of the player)
add(300, function() if not ZeD_WorldWindow.isOpen() then O.openedWin = true; ZeD_CharacterWindow.toggleBothPaired(0) end end)
add(1500, function()
    ZeD_WorldWindow.openTab(0, "forage")
    local w = W()
    if w then w:setX(20); w:setY(20) end
    check(w ~= nil and ZeD_WorldWindow.isTabShowing("forage") and not ZeD_WorldWindow.isTabShowing("fishing"), "b the World window is open on another tab (Foraging), the Fishing tab not showing")
end)

-- 1. the gear
add(300, function()
    F.rod = spawn("Base.FishingRod")
    for k = 1, 6 do F.worms[#F.worms + 1] = spawn("Base.Worm") end
    local md = F.rod and F.rod:getModData() or {}
    say("rod " .. tostring(F.rod and F.rod:getFullType()) .. " hook " .. tostring(md.fishing_HookType) .. " line " .. tostring(md.fishing_LineType)
        .. " lure " .. tostring(md.fishing_Lure) .. "; worms " .. #F.worms .. " (" .. tostring(F.worms[1] and F.worms[1]:getFullType()) .. ")")
    check(F.rod ~= nil and md.fishing_HookType ~= nil and md.fishing_LineType ~= nil, "1 the rod has a hook and a line (" .. tostring(md.fishing_HookType) .. ", " .. tostring(md.fishing_LineType) .. ")")
    -- Equip Primary, as the inventory's context menu does it
    local two = false
    pcall(function() two = F.rod:isTwoHandWeapon() end)
    ISInventoryPaneContextMenu.equipWeapon(F.rod, true, two, pn)
    say("equip queued (two hands " .. tostring(two) .. ")")
end)
addWhen(15000, function() return queueEmpty() and p:getPrimaryHandItem() == F.rod end, function()
    check(p:getPrimaryHandItem() == F.rod, "1 the rod is in the primary hand by the equip action")
    local m = mgr()
    check(m ~= nil, "1 the game made its FishingManager for the rod (OnEquipPrimary); state " .. stateName(m))
end)
-- Add Bait, through the rod's context menu
add(300, function()
    local done = false
    local ok, e = pcall(function()
        local ctx = ISInventoryPaneContextMenu.createMenu(pn, true, { F.rod }, 400, 400)
        local o1 = ctx and ctx:getOptionFromName(F.rod:getDisplayName())
        local m1 = o1 and o1.subOption and ctx:getSubMenu(o1.subOption)
        local o2 = m1 and m1:getOptionFromName(getText("ContextMenu_Add_Bait"))
        local m2 = o2 and o2.subOption and ctx:getSubMenu(o2.subOption)
        local o3 = m2 and m2:getOptionFromName(F.worms[1]:getName())
        say("menu: rod option " .. tostring(o1 ~= nil) .. ", Add Bait " .. tostring(o2 ~= nil) .. ", " .. tostring(F.worms[1]:getName()) .. " " .. tostring(o3 ~= nil)
            .. (o3 and (" (onSelect is addLure: " .. tostring(o3.onSelect == ISInventoryPaneContextMenu.addLure) .. ")") or ""))
        if o3 then
            o3.onSelect(o3.target, o3.param1, o3.param2, o3.param3, o3.param4, o3.param5, o3.param6, o3.param7, o3.param8, o3.param9, o3.param10)
            done = true
        end
        pcall(function() ctx:closeAll() end)
        pcall(function() ctx:hideAndChildren() end)
    end)
    if not ok then say("ERR the context menu: " .. tostring(e)) end
    check(done, "1 Add Bait > " .. tostring(F.worms[1]:getName()) .. " found in the rod's context menu and chosen")
    if not done then ISInventoryPaneContextMenu.addLure(pn, F.rod, F.worms[1]); say("FALLBACK addLure called directly") end
end)
addWhen(20000, function() return queueEmpty() and hasLure() end, function()
    local md = F.rod:getModData()
    check(md.fishing_Lure ~= nil, "1 the rod has bait after the action: " .. tostring(md.fishing_Lure) .. " (" .. tostring(F.rod:getName()) .. ")")
    check(p:getPrimaryHandItem() == F.rod, "1 the rod is still in the primary hand after baiting")
end)

-- 2. the shore
add(200, function() p:setX(13913.5); p:setY(4555.5); p:setZ(0); p:setLastX(13913.5); p:setLastY(4555.5); p:setLastZ(0) end)
add(4000, function()
    local list = findShores(13913, 4555, 0)
    local east = {}
    for _, s in ipairs(list) do if s.dir == "E" then east[#east + 1] = s end end
    say("the shore 13913,4555: " .. #list .. " direction(s) with water, east " .. #east)
    if #east > 0 then list = east else list = findShores(13913, 4555, 10) end
    table.sort(list, function(a, b)
        if a.fish ~= b.fish then return a.fish > b.fish end
        return math.abs(a.x - 13903) + math.abs(a.y - 4549) < math.abs(b.x - 13903) + math.abs(b.y - 4549)
    end)
    say("shores found " .. #list .. (list[1] and string.format("; best %d,%d facing %s, fish in front %s", list[1].x, list[1].y, list[1].dir, tostring(list[1].fish)) or ""))
    F.shore = list[1]
    if not check(F.shore ~= nil, "2 a shore with water in front") then return end
    p:setX(F.shore.x + 0.5); p:setY(F.shore.y + 0.5); p:setLastX(F.shore.x + 0.5); p:setLastY(F.shore.y + 0.5)
    p:setDir(IsoDirections[F.shore.dir])
    F.tx, F.ty = F.shore.tx, F.shore.ty
end)
add(2500, function()
    if not F.shore then return end
    p:setDir(IsoDirections[F.shore.dir])
    -- a: Cast from the tab with the rod not aimed at water: it says to aim first and the game's state does not move
    pcall(function()
        local m = mgr()
        local before = stateName(m)
        pcall(function() p:setIsAiming(false) end)
        FT.press(W(), "cast")
        local w = W()
        local stt = w and w._fishTab
        local want = ZeD.tr("UI_ZeD_Fish_AimFirst")
        check(stt ~= nil and stt.msg == want and stateName(m) == before, "a Cast from the tab with no aim: says '" .. tostring(want) .. "' and the state stays " .. before .. " (msg '" .. tostring(stt and stt.msg) .. "', state " .. stateName(m) .. ")")
    end)
    F.phase = "aim"   -- the driver below takes it from here
    F.started = getTimestampMs()
    F.gh0 = gt:getWorldAgeHours()
    say(string.format("at %.1f,%.1f facing %s, target %.1f,%.1f; %s; %s", p:getX(), p:getY(), F.shore.dir, F.tx, F.ty, clock(), speedInfo()))
end)
-- 2-4 run in the driver; the plan waits for it
addWhen(16 * 60 * 1000, function() return F.phase == "end" or F.shore == nil end, function() end)

-- ------------------------------------------------------------------ g, f: the icon, the wall by the pad
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local PAD = {}
local function deep(t) if type(t) ~= "table" then return t end local o = {}; for k, v in pairs(t) do o[k] = deep(v) end; return o end
local function ringFind(w, id)
    for _, z in ipairs(w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.id == id then return z, e end end
    end
end
local function focusId(w) local e = Focus.getFocusedElement(w); return e and e.id end
add(500, function()
    if MOUSE.holding then mouseSend("up", MOUSE.x, MOUSE.y); MOUSE.holding = false end
    local TP = ZeD.TabPx
    local miss = {}
    for _, tone in ipairs({ "sh", "k", "d", "m", "l", "w" }) do
        local ok, t = pcall(function() return ZeD.Px.tex(TP.DIR .. FT.ID .. "_" .. tone .. ".png") end)
        if not (ok and t) then miss[#miss + 1] = tone end
    end
    check(TP ~= nil and TP.has(FT.ID) and #miss == 0, "g the Fishing tab's icon is listed and its six pictures load" .. (#miss > 0 and (" (missing " .. table.concat(miss, ",") .. ")") or ""))
    ZeD_WorldWindow.openTab(0, "fishing")
end)
add(1500, function() shot("7_tab_strip_icon") end)
add(300, function()
    PAD.snap = deep(LOG.data(p))
    for _, s in ipairs({ { "Bluegill", 1.2, 19 }, { "LargemouthBass", 2.5, 48 }, { "YellowPerch", 0.8, 27 } }) do
        LOG.record(p, { kind = "fish", type = "Base." .. s[1], name = getItemNameFromFullType("Base." .. s[1]), wt = s[2], len = s[3], bait = "Base.Worm", rod = "Fishing Rod", lv = 1 })
    end
    ZeD_WorldWindow.openTab(0, "fishing")
    FT.press(W(), "wall")
end)
add(1500, function()
    local w = W()
    local wl = w and w._fishTab and w._fishTab.wall
    check(wl ~= nil and #(wl.plaques or {}) >= 4, "f the wall opened with " .. tostring(wl and #(wl.plaques or {})) .. " plaques")
    Det.setLockedMode(Det.MODE_GAMEPAD)
    Focus.claimFocus(w)
end)
add(800, function()
    local w = W()
    local z = ringFind(w, "fish:plq:1")
    if z then Focus.focusWhere(w, z.zone, function(x) return x.id == "fish:plq:1" end) end
    check(focusId(w) == "fish:plq:1", "f the pad's focus is on the first plaque (" .. tostring(focusId(w)) .. ")")
    Focus.dispatchJoypadDir(w, "right")
end)
add(700, function()
    local w = W()
    check(focusId(w) == "fish:plq:2", "f D-pad right moves to the second plaque (" .. tostring(focusId(w)) .. ")")
    Focus.dispatchJoypadDir(w, "right")
end)
add(700, function()
    local w = W()
    -- (the plaques sit in rows: at 1.75x two to a row, so Right from the second leaves for the tab strip)
    local wl = w._fishTab and w._fishTab.wall
    local cols = 0
    for _, r in ipairs(wl and wl.plaques or {}) do if math.abs(r.y - wl.plaques[1].y) < 4 then cols = cols + 1 end end
    PAD.cols = cols
    say("f the wall has " .. cols .. " plaque(s) to a row; right from the last in a row goes to " .. tostring(focusId(w)))
    check(cols >= 2 and (cols > 2 or focusId(w) ~= "fish:plq:3"), "f D-pad right past the last plaque in a row goes on to the " .. tostring(focusId(w)) .. " (" .. cols .. " to a row)")
    Focus.dispatchJoypadDir(w, "left")
end)
add(700, function()
    local w = W()
    check(focusId(w) == "fish:plq:1" or focusId(w) == "fish:plq:2", "f D-pad left comes back onto the plaques (" .. tostring(focusId(w)) .. ")")
    Focus.focusWhere(w, ringFind(w, "fish:plq:1").zone, function(x) return x.id == "fish:plq:1" end)
    Focus.dispatchJoypadDir(w, "down")
end)
add(700, function()
    local w = W()
    local want = "fish:plq:" .. tostring((PAD.cols or 2) + 1)
    check(focusId(w) == want, "f D-pad down from the first plaque moves to the next row, " .. want .. " (" .. tostring(focusId(w)) .. ")")
    shot("8_wall_pad_focus")
    Focus.dispatchJoypadDown(w, Joypad.BButton)
end)
add(1000, function()
    local w = W()
    local stt = w and w._fishTab
    check(stt ~= nil and stt.wall == nil, "f B leaves the wall and the tab shows again (focus now " .. tostring(focusId(w)) .. ")")
    shot("9_after_b")
    p:getModData()[LOG.KEY] = PAD.snap   -- the three trophies away; the real catch stays for the reload script
    Det.setLockedMode(nil)
    local e = D.expect
    pcall(function()
        local fw = getFileWriter("zedqa_ftl_expect.txt", true, false)
        if e then
            fw:write("n=" .. e.n .. "\nfish=" .. e.fish .. "\nlogN=" .. e.logN .. "\nwa=" .. tostring(e.wa) .. "\ntype=" .. tostring(e.type) .. "\nwt=" .. tostring(e.wt) .. "\ntopN=" .. e.topN .. "\nhadData=" .. tostring(O.hadData) .. "\norigN=" .. tostring(O.n) .. "\norigFish=" .. tostring(O.fish) .. "\n")
        end
        fw:close()
    end)
    say("expect file written: " .. tostring(e ~= nil))
end)

-- ------------------------------------------------------------------ cleanup
add(300, function()
    if MOUSE.holding then mouseSend("up", MOUSE.x, MOUSE.y); MOUSE.holding = false end
    F.phase = "off"
    pcall(function() p:setIsAiming(false) end)
    local m = mgr()
    if m then pcall(function() m:changeState("None") end) end
    pcall(function() ISTimedActionQueue.clear(p) end)
    setGameSpeed(O.speed > 0 and O.speed or 1)
end)
addWhen(10000, function() return mouseIdle() end, function()
    shot("9_after")
    for k = #S.undo, 1, -1 do pcall(S.undo[k]) end
    S.undo = {}
end)
add(1500, function()
    pcall(function() p:setPrimaryHandItem(O.h1); p:setSecondaryHandItem(O.h2) end)
    local gone = 0
    for _, it in ipairs(newItems()) do
        pcall(function() p:getInventory():Remove(it) end); gone = gone + 1
    end
    for _, it in ipairs(S.added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    -- what fell to the floor (a dropped catch)
    pcall(function()
        local sq = p:getCurrentSquare()
        local objs = sq and sq:getWorldObjects()
        if objs then
            for k = objs:size() - 1, 0, -1 do
                local w = objs:get(k)
                local it = w:getItem()
                if it and not O.ids[it:getID()] then sq:transmitRemoveItemFromSquare(w); gone = gone + 1 end
            end
        end
    end)
    say("cleanup: " .. gone .. " new item(s) removed")
    p:setX(O.x); p:setY(O.y); p:setZ(O.z); p:setLastX(O.x); p:setLastY(O.y); p:setLastZ(O.z)
    p:setGodMod(O.god)
    -- Fishing XP and the fishing mod data back
    pcall(function() p:getXp():setXPToLevel(Perks.Fishing, O.lvl) end)
    pcall(function() local d = O.xp - p:getXp():getXP(Perks.Fishing); if d > 0 then p:getXp():AddXP(Perks.Fishing, d, false, false, false) end end)
    local md = p:getModData()
    local drop = {}
    for key, _ in pairs(md) do
        local ks = tostring(key)
        if (ks:find("fishing", 1, true) == 1 or ks:find("Fishing", 1, true) == 1) and O.md[ks] == nil then drop[#drop + 1] = key end
    end
    for _, key in ipairs(drop) do md[key] = nil end
    for ks, v in pairs(O.md) do md[ks] = v end
    for _, e in ipairs(O.consoles) do pcall(function() e:setVisible(true) end) end
    if O.openedWin and ZeD_WorldWindow.isOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, 0) end
    say(string.format("cleanup: fishing level %d xp %.1f (was %d, %.1f); speed %s", p:getPerkLevel(Perks.Fishing), p:getXp():getXP(Perks.Fishing), O.lvl, O.xp, tostring(getGameSpeed())))
end)
add(800, function()
    local left = #newItems()
    for _, it in ipairs(S.added) do if it:getContainer() then left = left + 1 end end
    check(left == 0, "cleanup: everything spawned or caught is gone (" .. left .. " left)")
    check(p:getPrimaryHandItem() == O.h1, "cleanup: the hands are as before")
    say(string.format("RESULT %d pass, %d fail", R.pass, R.fail))
    say("DONE")
end)

-- ------------------------------------------------------------------ the driver (steps 2-4)
D = { aimTry = 0, aimAt = 0, castAt = 0, castClicked = false, waitAt = 0, fishAt = 0, pickupAt = 0, beat = 0, sample = 0,
            casts = 0, bites = 0, lost = 0, landed = 0, fishLanded = false, lineOutChecked = false, fightShot = false, outShot = false,
            fallbackCast = false, fallbackReel = false, castReal = false, rebaitAt = 0, tensMax = -9, uiWarned = {} }
local LIMIT_MS = 14 * 60 * 1000
local LIMIT_GH = 6

local function finish(why)
    if F.phase == "end" then return end
    say("fishing ends: " .. why .. string.format("; casts %d, bites %d, lost %d, landed %d; %.1f game hours, %s real", D.casts, D.bites, D.lost, D.landed, gt:getWorldAgeHours() - (F.gh0 or 0), el()))
    -- 3. the outcome
    local xp = p:getXp():getXP(Perks.Fishing)
    local caught = {}
    for _, it in ipairs(newItems()) do
        local wormish = false
        for _, w in ipairs(F.worms) do if w == it then wormish = true end end
        if not wormish and it ~= F.rod then caught[#caught + 1] = it:getFullType() .. (it:getModData().fishing_FishSize and (" size " .. tostring(it:getModData().fishing_FishSize)) or "") end
    end
    check(#caught > 0, "3 a catch reached the inventory: " .. (#caught > 0 and table.concat(caught, ", ") or "none"))
    check(D.fishLanded, "3 the catch is a fish (not trash)")
    check(xp > O.xp, string.format("3 Fishing XP rose: %.1f -> %.1f", O.xp, xp))
    do
        local d = LOG.data(p)
        local last = d.log[#d.log]
        check(d.n == O.n + 1 and d.fish == O.fish + 1 and last ~= nil and last.k == "fish" and last.type ~= nil,
              string.format("d a real landing wrote the catch log: n %s -> %s, fish %s -> %s, last %s %s %.2f kg", tostring(O.n), tostring(d.n), tostring(O.fish), tostring(d.fish), tostring(last and last.k), tostring(last and last.type), last and last.wt or 0))
        if last then D.expect = { n = d.n, fish = d.fish, logN = #d.log, wa = last.wa, type = last.type, wt = last.wt, topN = #d.top } end
    end
    if not D.reelChecked then say("c not tested: no fish bit while the pointer was on the Reel in button") end
    if ZED then
        check(D.lineOutChecked, "4 the ZeD rod meter drew while the line was out (draws " .. Z.lineOutDraws .. ", all " .. Z.drawsTrue .. "/" .. Z.draws .. ")")
        check(#Z.logs == 0, "4 no ZeD draw error logged (" .. #Z.logs .. ")")
    end
    say("cast by the real click: " .. tostring(D.castReal) .. "; stand-ins used: cast " .. tostring(D.fallbackCast) .. ", reel " .. tostring(D.fallbackReel))
    if why == "a fish landed" and not F.s2 and F.shore then
        -- e: once more, to the Idle state aimed at the water, to press the tab's Cast
        F.s2 = true; D.aimTry = 0; F.last = nil; F.phase = "aim"
        say("stage 2: aim again and press Cast on the tab")
    else
        F.phase = "end"
    end
end

-- the aim: the pointer onto the target water square; getAimCoords reads the pointer 100 px lower
local function aimStep(now, m)
    if not mouseIdle() then return end
    if D.aimTry > 0 and now - D.aimAt < 400 then return end
    local ax, ay = Fishing.Utils.getAimCoords(p)
    local onWater = Fishing.Utils.isPlayerAimOnWater(p)
    local err = math.sqrt((ax - F.tx) ^ 2 + (ay - F.ty) ^ 2)
    if D.aimTry > 0 then
        say(string.format("aim try %d: pointer %d,%d (scaled %d,%d) -> aim %.1f,%.1f, %.1f from the target, on water %s, state %s",
            D.aimTry, getMouseX(), getMouseY(), getMouseXScaled(), getMouseYScaled(), ax, ay, err, tostring(onWater), stateName(m)))
    end
    if D.aimTry > 0 and ((err < 1.6 and onWater) or D.aimTry >= 6 or MOUSE.dead) then
        F.phase = "idle"; D.idleAt = now
        return
    end
    D.aimTry = D.aimTry + 1
    D.aimAt = now
    local sx, sy = isoToScreenX(pn, F.tx, F.ty, 0), isoToScreenY(pn, F.tx, F.ty, 0)
    local mx, my
    if D.aimTry == 1 then
        mx, my = sx, sy - 100
    else
        local asx, asy = isoToScreenX(pn, ax, ay, 0), isoToScreenY(pn, ax, ay, 0)
        mx, my = MOUSE.x + (sx - asx), MOUSE.y + (sy - asy)
    end
    mouseSend("move", mx, my)
end

local function lineOut(st) return st == "Wait" or st == "ReelIn" or st == "ReelOut" end

local function driveInner()
    if F.phase == "setup" or F.phase == "end" or F.phase == "off" then return end
    local now = getTimestampMs()
    local m = mgr()
    local st = stateName(m)
    -- every state change, with the real and the game time
    if st ~= F.last then
        say(string.format("STATE %s -> %s at %s (game %s); %s; %s; player state %s", tostring(F.last), st, el(), clock(), lineInfo(m), speedInfo(),
            tostring(p:getCurrentState() and p:getCurrentState():getClass():getSimpleName())))
        if st == "Cast" then D.casts = D.casts + 1; D.castAt = now end
        if st == "Wait" and F.last == "Cast" then D.waitAt = now; D.outShot = false end
        if st == "PickupFish" then D.pickupAt = now; D.pickShot = false end
        F.last = st
    end
    -- the aim held as the right button holds it (Wait and the reel states hold it themselves)
    if (st == "None" or st == "Idle" or st == "nomanager") and F.phase ~= "rebait" and queueEmpty() then pcall(function() p:setIsAiming(true) end) end
    -- the limit
    if now - (F.started or now) > LIMIT_MS then finish("real-time limit"); return end
    if gt:getWorldAgeHours() - (F.gh0 or 0) > LIMIT_GH then finish("game-time limit"); return end
    -- a sample every second while casting, every 20 s otherwise (the stall watch sees the log move)
    if st == "Cast" and now - D.sample > 1000 then D.sample = now; say("  cast: " .. lineInfo(m) .. "; " .. speedInfo()) end
    if now - D.beat > 20000 then
        D.beat = now
        say(string.format("  beat %s game %s: phase %s state %s; %s; %s; xp %.1f", el(), clock(), F.phase, st, lineInfo(m), speedInfo(), p:getXp():getXP(Perks.Fishing)))
    end

    if F.phase == "aim" then aimStep(now, m); return end

    if F.phase == "idle" then
        -- the manager goes None -> Idle once the aim is on water
        if st == "Idle" and mouseIdle() then
            local under = uiUnder(MOUSE.x, MOUSE.y)
            say("UI under the cast point " .. MOUSE.x .. "," .. MOUSE.y .. ": " .. (#under > 0 and table.concat(under, "; ") or "nothing"))
            local zedUnder = {}
            for _, n in ipairs(under) do if n:find("ZeD", 1, true) then zedUnder[#zedUnder + 1] = n end end
            if ZED then check(#zedUnder == 0, "4 no ZeD window over the cast point" .. (#zedUnder > 0 and (": " .. table.concat(zedUnder, "; ")) or "")) end
            if F.s2 then
                shot("5_idle_for_tab_cast")
                FT.press(W(), "cast")
                D.t2At = now; F.phase = "tabcast"
                return
            end
            if D.casts == 0 then shot("1_aim") end
            if MOUSE.dead then
                D.fallbackCast = true
                say("FALLBACK the cast button stood in for (Fishing.Utils.isCastButtonPressed true once)")
                local orig = Fishing.Utils.isCastButtonPressed
                Fishing.Utils.isCastButtonPressed = function(j) Fishing.Utils.isCastButtonPressed = orig; return true end
            else
                mouseSend("left", MOUSE.x, MOUSE.y)
            end
            D.clickAt = now
            F.phase = "casting"
        elseif now - (D.idleAt or now) > 10000 then
            say("ERR the manager never reached Idle (state " .. st .. ", aim on water " .. tostring(Fishing.Utils.isPlayerAimOnWater(p)) .. ", aiming " .. tostring(p:isAiming()) .. ")")
            finish("no Idle")
        end
        return
    end

    if F.phase == "tabcast" then
        if st == "Cast" or lineOut(st) then
            check(true, "e Cast on the tab, from Idle aimed at the water, called the game's Cast (state " .. st .. ")")
            shot("6_tab_cast")
            pcall(FT.stopFishing, p)
            F.phase = "end"
        elseif now - D.t2At > 4000 then
            local stt = W() and W()._fishTab
            check(false, "e Cast on the tab from Idle did not reach the game's Cast (state " .. st .. ", tab says '" .. tostring(stt and stt.msg) .. "')")
            F.phase = "end"
        end
        return
    end

    if F.phase == "casting" then
        if st == "Cast" or lineOut(st) then
            D.castReal = not D.fallbackCast
            check(true, "2 the click cast the line (Idle -> Cast" .. (D.fallbackCast and ", stand-in" or ", real left click") .. ")")
            F.phase = "line"
        elseif mouseIdle() and now - D.clickAt > 6000 then
            if not D.fallbackCast then
                say("the real click did not cast (state " .. st .. ", aim on water " .. tostring(Fishing.Utils.isPlayerAimOnWater(p)) .. ", mouse down now " .. tostring(isMouseButtonDown(0)) .. ")")
                check(false, "2 the real left click on the water cast the line")
                MOUSE.dead = true   -- the stand-in from here
                F.phase = "idle"; D.idleAt = now
            else
                finish("no cast even with the stand-in")
            end
        end
        return
    end

    if F.phase == "rebait" then
        if queueEmpty() and hasLure() then
            say("re-baited: " .. tostring(F.rod:getModData().fishing_Lure))
            p:setDir(IsoDirections[F.shore.dir])
            D.aimTry = 0; F.phase = "aim"
        elseif now - D.rebaitAt > 20000 then finish("re-bait never finished") end
        return
    end

    -- F.phase == "line": the line is out
    local rod = m and m.fishingRod
    local fish = rod and rod.bobber and rod.bobber.fish
    if lineOut(st) and rod and rod.bobber then
        -- 4: ZeD's meter while the line is out
        local vis = m.tensionUI and m.tensionUI:isVisible()
        if ZED and vis and Z.lastT ~= nil then Z.lineOutDraws = Z.lineOutDraws + 1 end
        if not D.lineOutChecked and now - D.waitAt > 2000 then
            check(vis == true, "4 the tension meter is shown while the line is out (" .. st .. ")")
            if ZED then
                D.lineOutChecked = Z.drawsTrue > 0 and m.tensionUI.zedTension ~= nil
                say(string.format("ZeD rod meter: draws %d (drawn %d), zedTension %s, safe mode %s, box %s", Z.draws, Z.drawsTrue, tostring(m.tensionUI.zedTension),
                    tostring(ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on()), Z.lastBox and (math.floor(Z.lastBox[1]) .. "," .. math.floor(Z.lastBox[2]) .. " " .. math.floor(Z.lastBox[3]) .. "x" .. math.floor(Z.lastBox[4])) or "none"))
            else
                D.lineOutChecked = true
            end
        end
        if not D.tabChecked and now - D.waitAt > 1200 then
            D.tabChecked = true
            check(ZeD_WorldWindow.isTabShowing("fishing"), "b the Fishing tab came up by itself on the cast, with the World window open on Foraging")
            shot("2a_tab_on_cast")
        end
        if not D.outShot and now - D.waitAt > 3000 then D.outShot = true; shot("2_line_out_" .. D.casts) end
        -- fast-forward while nothing bites (the game drops to speed 1 itself on a bite)
        if not fish and not MOUSE.holding and getGameSpeed() < 3 and st == "Wait" then setGameSpeed(3); say("  speed 3 while the line waits") end
        if fish and not D.fishOn then
            D.fishOn = true; D.bites = D.bites + 1; D.fishAt = now
            if getGameSpeed() > 1 then setGameSpeed(1) end
            say(string.format("BITE %d at %s (game %s): %s", D.bites, el(), clock(), lineInfo(m)))
        elseif not fish and D.fishOn and st ~= "PickupFish" then
            D.fishOn = false; D.lost = D.lost + 1
            say("the fish got away: " .. lineInfo(m) .. "; lure " .. tostring(F.rod:getModData().fishing_Lure))
        end
        -- the reel: the left button held while the tension is low, let go when it is high
        local t = rod:getTension()
        if fish and t > D.tensMax then D.tensMax = t end
        local want = MOUSE.holding
        if fish then
            if t < 0.3 then want = true elseif t > 0.6 then want = false end
        else
            want = false
        end
        if MOUSE.dead and fish then
            if not D.fallbackReel then
                D.fallbackReel = true
                say("FALLBACK the reel button stood in for (the rod's isReel)")
            end
            rod.isReel = function(self) return MOUSE.holding end
            rod.isReleaseLine = function(self) return false end
        end
        if want ~= MOUSE.holding then
            if MOUSE.dead then
                MOUSE.holding = want
            elseif mouseIdle() then
                -- c: the reel is the left button held on the Fishing tab's Reel in button
                local bx, by = nil, nil
                if want and fish then bx, by = reelPoint() end
                if bx and (not MOUSE.onBtn or ((math.abs(bx - MOUSE.x) > 4 or math.abs(by - MOUSE.y) > 4) and (D.btnTry or 0) < 6)) then
                    D.btnTry = (D.btnTry or 0) + 1
                    mouseSend("move", bx, by)
                    MOUSE.onBtn = true
                    say(string.format("  pointer to the Reel in button (try %d): %d,%d; panel mouse %s,%s", D.btnTry, MOUSE.x, MOUSE.y, tostring(TB.panel and TB.panel:getMouseX()), tostring(TB.panel and TB.panel:getMouseY())))
                    return
                end
                mouseSend(want and "down" or "up", MOUSE.x, MOUSE.y)
                MOUSE.onBtn = bx ~= nil or MOUSE.onBtn
                MOUSE.holding = want
                if want and fish and bx and not D.reelDownAt then D.reelDownAt = now; shot("3a_reel_on_tab_" .. D.casts) end
            end
        end
        if MOUSE.holding and fish and D.reelDownAt and not D.reelChecked and mouseIdle() and (D.reelAnsAt or now) and (D.reelAnsAt == nil or now - D.reelAnsAt > 900) then
            if D.reelAnsAt == nil then D.reelAnsAt = now; return end
            D.reelChecked = true
            local isR = false
            pcall(function() isR = rod:isReel() end)
            check(st == "ReelIn" and isR, "c holding the tab's Reel in button reels: game state " .. st .. ", rod:isReel " .. tostring(isR) .. ", the tab's pull " .. tostring(LOG.pulling()) .. ", tension " .. string.format("%.2f", t))
        end
        if fish and st == "ReelIn" and not D.fightShot and now - D.fishAt > 1500 then D.fightShot = true; shot("3_fight") end
    end
    if st == "PickupFish" then
        if MOUSE.holding and mouseIdle() then mouseSend("up", MOUSE.x, MOUSE.y); MOUSE.holding = false end
        if not D.pickShot and now - D.pickupAt > 1500 then D.pickShot = true; shot("4_landed") end
    end
    -- the line is in again: a catch, a miss or a break
    if (st == "None" or st == "Idle") and now - D.castAt > 1500 and queueEmpty() then
        if MOUSE.holding and mouseIdle() then mouseSend("up", MOUSE.x, MOUSE.y); MOUSE.holding = false end
        if not mouseIdle() then return end
        if getGameSpeed() > 1 then setGameSpeed(1) end
        D.fishOn = false
        local got = nil
        for _, it in ipairs(newItems()) do
            local isWorm = false
            for _, w in ipairs(F.worms) do if w == it then isWorm = true end end
            if not isWorm and it ~= F.rod and not D.uiWarned[it:getID()] then
                D.uiWarned[it:getID()] = true
                got = it
                local md = it:getModData()
                local isFish = md.fishing_FishSize ~= nil or md.fishing_FishHandItem ~= nil
                D.landed = D.landed + 1
                if isFish then D.fishLanded = true end
                say(string.format("LANDED %s (%s) fish %s; xp %.1f", it:getFullType(), tostring(it:getName()), tostring(isFish), p:getXp():getXP(Perks.Fishing)))
            end
        end
        if D.fishLanded then finish("a fish landed"); return end
        if p:getPrimaryHandItem() ~= F.rod then finish("the rod is no longer in hand (" .. tostring(p:getPrimaryHandItem() and p:getPrimaryHandItem():getFullType()) .. ")"); return end
        -- again: re-bait if the bait is gone, then aim and cast
        say("line in without a fish (" .. st .. "); lure " .. tostring(F.rod:getModData().fishing_Lure) .. "; again")
        D.castAt = now
        if not hasLure() then
            local worm = nil
            for _, w in ipairs(F.worms) do if w:getContainer() == p:getInventory() then worm = w end end
            if not worm then finish("out of worms"); return end
            ISInventoryPaneContextMenu.addLure(pn, F.rod, worm)
            D.rebaitAt = now; F.phase = "rebait"
        else
            D.aimTry = 0; F.phase = "aim"
        end
    end
end
local function drive()
    local ok, e = pcall(driveInner)
    if not ok then
        R.fail = R.fail + 1
        say("ERR driver: " .. tostring(e))
        pcall(function() finish("driver error") end)
        F.phase = "end"
    end
end
Events.OnTick.Add(drive)

local function run()
    local now = getTimestampMs()
    local st = plan[pi]
    if not st then Events.OnTick.Remove(run); Events.OnTick.Remove(drive); return end
    if st.cond then
        local okC, met = pcall(st.cond)
        if not (okC and met) and now - pt0 < st.ms then return end
    elseif now - pt0 < st.ms then
        return
    end
    pt0 = now; pi = pi + 1
    local ok, e = pcall(st.fn)
    if not ok then R.fail = R.fail + 1; say("ERR step " .. (pi - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(run)
