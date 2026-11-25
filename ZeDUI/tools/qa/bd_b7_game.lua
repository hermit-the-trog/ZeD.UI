-- ZeDUI/tools/qa/bd_b7_game.lua  (Nov 25 2026, QA; tag bd_b7_game): B7 from the Build tab sweep, asked of the GAME.
-- With the cross's three inputs in a crate (then on the floor) where the build is started, the cross placed 6 to 9
-- tiles away: does the game's own build window build it, and from where does it take the inputs? ZeD's Build tab ran
-- one build action to its end there, built nothing and used nothing (bd_tab, "materials, built far from ..."). If the
-- game also builds nothing, ZeD matches it; if the game builds, ZeD must change. Evidence only: no PASS/FAIL on the
-- comparison. grep "ZEDQA bd_b7_game" (the B7GAME lines). Run after zedqa_prelude.lua and rt_kit.lua (cb.txt), after
-- bd_tab.lua, so both answers are in the same console.
--
-- The game's path, not ZeD's: ZeD routes ISEntityUI.OpenBuildWindow to its Build tab (42/media/lua/client/ZeD/
-- Overrides/Stations.lua:134-149, the only build hook). The script does what that function does without calling it:
--   the window   ISXuiSkin.build(skin, "BuildWindow", ISBuildWindow, 0, 0, 60, 30, player) (ISEntityUI.lua:581),
--                then ISEntityUI's local createWindow copied (ISEntityUI.lua:372-445: CloseWindows, the window
--                registry, initialise, instantiate, the lock, calculateLayout, addToUIManager; the controller branch
--                left out: no pad on the QA PC). Its createChildren makes the game's ISBuildPanel
--                (ISBuildWindow.lua:62), whose new() makes the logic, BuildLogic.new(player, nil, nil), with its
--                listeners onUpdateContainers / onRecipeChanged / onStopCraft (ISBuildPanel.lua:447-482), and whose
--                createChildren reads the containers (updateContainers: ISInventoryPaneContextMenu.getContainers,
--                logic:setContainers, autoPopulateInputs, ISBuildPanel.lua:214-221) and sets the recipe list
--                (refreshList: getAllBuildableRecipes, setRecipes, ISBuildPanel.lua:39-44).
--   the recipe   logic:setRecipe(cross), as OpenBuildWindow does for a recipe asked for (ISEntityUI.lua:584).
--   Build        the window's own Build button handler, craftControl:onButtonClick(buttonCraft)
--                (ISWidgetBuildControl.lua:189-208: ISBuildWindow.instance:createBuildIsoEntity(), the cursor
--                ISBuildIsoEntity:new(player, info, 1, containers, logic) set with getCell():setDrag,
--                ISBuildPanel.lua:310-356), pressed once the button reads enabled (its prerender, :159-173).
--   placing      the game's DoTileBuilding with the cursor's build flag set, as a click's release (bd_tab's way,
--                ISBuildingObject.lua:97-176): tryBuild starts the craft action, walks, queues ISBuildAction.
--   the re-read  the window's own update loop: ISBuildPanel:update reads the containers again when he has moved a
--                square (ISBuildPanel.lua:185-221). The window is hidden while its cursor is up
--                (ISBuildPanel.SetDragItem) but a hidden element's update still runs; the script counts those
--                runs and, should none come for 300 ms, calls the same ISBuildPanel:update itself (said in the
--                detail line: game n / script n).
-- Counting only (the game's functions called through, nothing changed): the panel's update, updateContainers and
-- createBuildIsoEntity on the instance, and ISBuildIsoEntity.create (the action's end) on the class.
--
-- Staging (bd_tab's helpers and pattern): ISBuildMenu.cheat and BuildCheat off, instant actions off (all as found
-- after); god mode on (left on), invincible on (as found after); his own building things set aside, his hands empty;
-- a crate (carpentry_01_16) on a tile beside him; the cross (RuggedCross: a branch, a long stick, a rag). Two runs:
-- the three in the crate, then on the floor at his feet. Each opens a new game window, presses Build, places the
-- cross 6 to 9 tiles away, walks at x1 and runs the build action at x20 (ZEDQA_SPEED 3) until the queue is empty.
--
-- Logs per run:
--   B7GAME run=<crate|floor> actions=<n> built=<n> used=<kind from where, ...> leftIn=<kind:where, ...>
--   B7GAME detail run=... (the tile, the containers at the action's start and end, the re-reads, the create call)
--   NOTE the comparison with ZeD (bd_tab's lines above)
-- Checks (staging only): the game's window opened with its panel and logic; the cross found and the logic can build
-- it with the materials in place; Build started the game's own cursor; a far tile takes it; the click queued the
-- build. Put back: the cursor, the queue, game speed, the window (closed, ISEntityUI's registry entry and
-- ISBuildWindow.instance as found), the wrappers, what was built (checked by name), the crate, the materials, his
-- own things, his hands, the skill levels, the cheats, his position (the run's home square, then ZEDQA_HOME).

if not (RT and RT.make) then
    print("ZEDQA bd_b7_game ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA bd_b7_game VERDICT FAIL 1")
    print("ZEDQA bd_b7_game DONE")
    return
end

local Q = RT.make("bd_b7_game")
Q.maxMs = 780000                     -- (the put-back runs before 13 minutes are up; the manifest gives 900 s)
local S = { p = RT.p, pn = RT.pn, built = {}, given = {}, had = {}, floorHad = {}, stash = {}, xp = {}, mats = {},
            runs = {}, dead = false }
local H = {}
local C = {}
S.CRATE = "carpentry_01_16"
S.CROSS = "RuggedCross"
S.WKEY = "BuildWindow"
S.MAT = { branch = "Base.TreeBranch2", stick = "Base.LongStick", rag = "Base.RippedSheets" }
S.MAT_ORDER = { "branch", "stick", "rag" }
S.OWN = { "Base.TreeBranch2", "Base.WoodenStick2", "Base.LongStick", "Base.Sapling", "Base.RippedSheets",
          "Base.RippedSheetsDirty", "Base.Twine", "Base.Rope", "Base.SheetRope", "Base.Plank", "Base.Nails",
          "Base.NailsBox", "Base.BlowTorch", "Base.SheetMetal", "Base.WeldingRods", "Base.Hammer", "Base.HammerStone",
          "Base.BallPeenHammer", "Base.ClubHammer" }
S.RING1 = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.FAR = { { 8, 0 }, { 0, 8 }, { -8, 0 }, { 0, -8 }, { 7, 3 }, { -7, 3 }, { 7, -3 }, { 6, 0 }, { 0, 6 }, { -6, 0 }, { 0, -6 }, { 9, 0 } }

if not (S.p and ISBuildWindow and ISBuildPanel and ISEntityUI and ISXuiSkin and ISBuildIsoEntity and BuildLogic) then
    Q.check(false, "the player and the game's build window classes (ISBuildWindow, ISBuildPanel, ISEntityUI, ISBuildIsoEntity, BuildLogic) are loaded")
    Q.start()
    return
end

-- ===================================================================== small helpers (bd_tab's)
function H.note(s) Q.say("NOTE " .. tostring(s)) end
function H.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
-- time, not frames: cond asked every 100 ms, at most ms; fn(true) when cond came true
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 400000, function()
        if S.dead then return true end
        local now = getTimestampMs()
        st.t = st.t or now
        if st.last and now - st.last < 100 then return false end
        st.last = now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() if S.dead then return end; fn(st.ok == true) end)
end
function H.call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
function H.fl(v) return math.floor(tonumber(v) or 0) end
function H.join(t, max)
    max = max or 8
    local out = {}
    for i = 1, math.min(#t, max) do out[#out + 1] = tostring(t[i]) end
    local s = table.concat(out, ", ")
    if #t > max then s = s .. " (+" .. (#t - max) .. " more)" end
    if s == "" then s = "none" end
    return s
end
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
function H.queue()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return (q and q.queue) or {}
end
function H.qlen() return #H.queue() end
function H.head() local a = H.queue()[1]; return a and tostring(a.Type) or "none" end
function H.stop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.drag() local d = nil; pcall(function() d = getCell():getDrag(S.pn) end); return d end
function H.noDrag() pcall(function() if getCell():getDrag(S.pn) then getCell():setDrag(nil, S.pn) end end) end
function H.dragType(d) if d == nil then return "none" end; return tostring(d.Type) end
function H.isBuildCur(d) return d ~= nil and d.Type == "ISBuildIsoEntity" end

-- ===================================================================== things (bd_tab's)
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.ft(it) local f = "?"; if H.isItem(it) then pcall(function() f = it:getFullType() end) end; return f end
function H.walkInv(inv, out, depth)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        out[#out + 1] = it
        if depth < 4 and instanceof(it, "InventoryContainer") then
            local sub = nil
            pcall(function() sub = it:getInventory() end)
            if sub then H.walkInv(sub, out, depth + 1) end
        end
    end
end
function H.all() local out = {}; pcall(H.walkInv, S.p:getInventory(), out, 0); return out end
function H.track(it)
    if not H.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.given[#S.given + 1] = it
    return it
end
function H.rmItem(it)
    if not H.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() if S.p:isEquippedClothing(it) then S.p:removeWornItem(it) end end)
    local wo = nil
    pcall(function() wo = it:getWorldItem() end)
    if wo then
        local sq = nil
        pcall(function() sq = wo:getSquare() end)
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
        pcall(function() wo:removeFromWorld() end)
        pcall(function() wo:removeFromSquare() end)
        pcall(function() it:setWorldItem(nil) end)
    end
    local c = nil
    pcall(function() c = it:getContainer() end)
    if c then pcall(function() c:Remove(it) end) end
end
function H.still(it)
    if not H.isItem(it) then return false end
    local held, laid = false, false
    pcall(function() local c = it:getContainer(); held = c ~= nil and c:contains(it) end)
    pcall(function() local wo = it:getWorldItem(); laid = wo ~= nil and wo:getSquare() ~= nil end)
    return held or laid
end
function H.isHammer(it)
    local yes = false
    pcall(function() if ItemTag and ItemTag.HAMMER then yes = it:hasTag(ItemTag.HAMMER) and true or false end end)
    return yes
end
function H.stashOwn()
    local want, kept = {}, {}
    for _, ft in ipairs(S.OWN) do want[ft] = true end
    for _, it in ipairs(H.all()) do
        if want[H.ft(it)] or H.isHammer(it) then
            local c, free = nil, false
            pcall(function() c = it:getContainer(); free = it:getAttachedSlot() == -1 and not it:isEquipped() end)
            if c and free and pcall(function() c:Remove(it) end) then
                S.stash[#S.stash + 1] = { it = it, c = c }
            else
                kept[#kept + 1] = H.ft(it)
            end
        end
    end
    return #S.stash, kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        local back = false
        pcall(function() back = s.it:getContainer() ~= nil end)
        if not back then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end
function H.xpSnap()
    pcall(function()
        local xp = S.p:getXp()
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            S.xp[#S.xp + 1] = { perk = perk, xp = xp:getXP(perk), lvl = S.p:getPerkLevel(perk) }
        end
    end)
end
function H.xpBack()
    local grew = 0
    pcall(function()
        local xp = S.p:getXp()
        for _, r in ipairs(S.xp) do
            if math.abs(xp:getXP(r.perk) - r.xp) > 0.001 or S.p:getPerkLevel(r.perk) ~= r.lvl then
                grew = grew + 1
                pcall(function()
                    S.p:setPerkLevelDebug(r.perk, r.lvl)
                    xp:setXPToLevel(r.perk, r.lvl)
                    local now = xp:getXP(r.perk)
                    if math.abs(r.xp - now) > 0.001 then xp:AddXPNoMultiplier(r.perk, r.xp - now) end
                end)
            end
        end
    end)
    pcall(function() SyncXp(S.p) end)
    return grew
end

-- ===================================================================== containers, squares, objects (bd_tab's)
function H.refreshLoot()
    pcall(function() getPlayerLoot(S.pn):refreshBackpacks() end)
    pcall(function() getPlayerInventory(S.pn):refreshBackpacks() end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
end
-- the list the game's build panel reads (ISBuildPanel:updateContainers), asked of the game itself
function H.conts()
    local list = nil
    pcall(function()
        if getPlayerInventory(S.pn) ~= nil and getPlayerLoot(S.pn) ~= nil then
            list = ISInventoryPaneContextMenu.getContainers(S.p)
        end
    end)
    return list
end
function H.inConts(it)
    local conts = H.conts()
    local has = false
    if not (conts and it) then return false end
    pcall(function()
        for i = 0, conts:size() - 1 do if conts:get(i):contains(it) then has = true end end
    end)
    return has
end
function H.sq(x, y) local s = nil; pcall(function() s = getCell():getGridSquare(x, y, 0) end); return s end
function H.free(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
    end)
    return good
end
function H.homeSq() return H.sq(S.hx, S.hy) end
function H.goHome()
    pcall(function()
        S.p:setX(S.hx + 0.5); S.p:setY(S.hy + 0.5); S.p:setZ(0)
        S.p:setLastX(S.hx + 0.5); S.p:setLastY(S.hy + 0.5); S.p:setLastZ(0)
    end)
    H.refreshLoot()
end
function H.dist(sq) return math.sqrt((sq:getX() - S.hx) ^ 2 + (sq:getY() - S.hy) ^ 2) end
function H.snapObjs(cx, cy, r)
    local set = {}
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            local sq = H.sq(x, y)
            local objs = sq and sq:getObjects()
            for i = 0, (objs and objs:size() or 0) - 1 do set[objs:get(i)] = true end
        end
    end
    return set
end
function H.newObjs(before, cx, cy, r)
    local out = {}
    for o in pairs(H.snapObjs(cx, cy, r)) do
        local wi = false
        pcall(function() wi = instanceof(o, "IsoWorldInventoryObject") end)
        if not before[o] and not wi then out[#out + 1] = o end
    end
    return out
end
function H.snapWorld(set)
    for y = S.hy - 12, S.hy + 12 do
        for x = S.hx - 12, S.hx + 12 do
            local sq = H.sq(x, y)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
function H.objName(o) local n = "?"; pcall(function() n = o:getSprite():getName() end); return tostring(n) end
function H.objOn(o)
    local on = false
    pcall(function() local sq = o:getSquare(); on = sq ~= nil and sq:getObjects():contains(o) end)
    return on
end
function H.rmObj(o)
    if not o then return end
    local sq = nil
    pcall(function() sq = o:getSquare() end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        pcall(function() sq:getObjects():remove(o) end)
        pcall(function() sq:getSpecialObjects():remove(o) end)
        pcall(function() sq:RecalcProperties() end)
    end
    pcall(function() o:removeFromWorld() end)
    pcall(function() o:removeFromSquare() end)
end
function H.mkCrate(sq)
    local made = nil
    pcall(function()
        local o = IsoObject.new(getCell(), sq, S.CRATE)
        o:createContainersFromSpriteProperties()
        if not o:getContainer() then return end
        sq:AddTileObject(o)
        pcall(function() o:getContainer():setExplored(true) end)
        made = o
    end)
    return made
end
function H.crateInv() local c = nil; if S.crate then pcall(function() c = S.crate:getContainer() end) end; return c end

-- ===================================================================== the materials, and where each one is
function H.putMat(ft, where)
    local it = nil
    if where == "floor" then pcall(function() it = H.homeSq():AddWorldInventoryItem(ft, 0.5, 0.5, 0) end)
    elseif where == "crate" then pcall(function() it = H.crateInv():AddItem(ft) end)
    end
    H.track(it)
    return H.isItem(it) and it or nil
end
function H.stageMat(where)
    for _, k in ipairs(S.MAT_ORDER) do
        local it = H.putMat(S.MAT[k], where)
        if it then S.mats[#S.mats + 1] = { it = it, where = where, kind = k, seen = where } end
    end
    H.refreshLoot()
end
function H.clearMat() for _, m in ipairs(S.mats) do H.rmItem(m.it) end; S.mats = {}; H.refreshLoot() end
-- where a thing is now: inv, bag, crate, floor@dx,dy (from the run's home square), another container, or gone
function H.where(it)
    if not H.isItem(it) then return "gone" end
    local w = nil
    pcall(function()
        local wo = it:getWorldItem()
        local sq = wo and wo:getSquare()
        if sq then w = "floor@" .. (sq:getX() - S.hx) .. "," .. (sq:getY() - S.hy) end
    end)
    if w then return w end
    pcall(function()
        local c = it:getContainer()
        if not (c and c:contains(it)) then return end
        if c == S.p:getInventory() then w = "inv"
        elseif c == H.crateInv() then w = "crate"
        elseif c:getContainingItem() ~= nil then w = "bag"
        else w = "container:" .. tostring(c:getType()) end
    end)
    return w or "gone"
end
function H.whereAll()
    local t = {}
    for _, m in ipairs(S.mats) do t[#t + 1] = m.kind .. ":" .. H.where(m.it) end
    return table.concat(t, " ")
end
-- the last place each staged thing was seen (so a used thing says where it was taken from)
function H.seeMats()
    for _, m in ipairs(S.mats) do
        local w = H.where(m.it)
        if w ~= "gone" then m.seen = w end
    end
end
function H.allInReach()
    local inR = true
    for _, m in ipairs(S.mats) do if H.still(m.it) and not H.inConts(m.it) then inR = false end end
    return inR
end

-- ===================================================================== the cursor (bd_tab's)
function H.placeAt(cur, sq, label)
    local ok, err = pcall(function()
        cur.square = sq
        cur.isLeftDown = false
        cur.canBeBuild = cur:isValid(sq) and true or false
        cur.build = true
        DoTileBuilding(cur, false, sq:getX(), sq:getY(), sq:getZ(), sq)
    end)
    if not ok then Q.check(false, tostring(label) .. ": the placement (the game's DoTileBuilding) ran without an error", err) end
    return ok
end
function H.valid(cur, sq) local v = nil; if cur and sq then pcall(function() v = cur:isValid(sq) and true or false end) end; return v end
function H.farSq(cur)
    for _, d in ipairs(S.FAR) do
        local sq = H.sq(S.hx + d[1], S.hy + d[2])
        if sq and H.free(sq) and H.valid(cur, sq) then return sq end
    end
    return nil
end

-- ===================================================================== the game's own build window
-- ISEntityUI's window registry entry for the build window, kept as found (createWindow and close write it)
function H.regSnap()
    pcall(function() ISEntityUI.EnsurePlayers() end)
    local P = ISEntityUI.players
    local p = P and P[S.pn]
    S.reg = { hadP = p ~= nil, hadW = p ~= nil and p.windows ~= nil, entry = nil }
    local e = p and p.windows and p.windows[S.WKEY]
    if e then
        local copy = {}
        for k, v in pairs(e) do copy[k] = v end
        S.reg.entry = copy
    end
end
function H.regBack()
    if not S.reg then return end
    pcall(function()
        local P = ISEntityUI.players
        if not P then return end
        if not S.reg.hadP then P[S.pn] = nil; return end
        if not P[S.pn] then return end
        if not S.reg.hadW then P[S.pn].windows = nil; return end
        if not P[S.pn].windows then P[S.pn].windows = {} end
        if S.reg.entry then
            local copy = {}
            for k, v in pairs(S.reg.entry) do copy[k] = v end
            P[S.pn].windows[S.WKEY] = copy
        else
            P[S.pn].windows[S.WKEY] = nil
        end
    end)
end
function H.regSame()
    local P = ISEntityUI.players
    local p = P and P[S.pn]
    if not S.reg then return true end
    if not S.reg.hadP then return p == nil end
    if not p then return false end
    if not S.reg.hadW then return p.windows == nil end
    local e = p.windows and p.windows[S.WKEY]
    if not S.reg.entry then return e == nil end
    if not e then return false end
    for k, v in pairs(S.reg.entry) do if e[k] ~= v then return false end end
    for k, v in pairs(e) do if S.reg.entry[k] ~= v then return false end end
    return true
end
-- ISEntityUI.lua:372-445 (its local createWindow), copied; the controller branch is left out (no pad on the QA PC)
function H.createWindow(win)
    local pn = S.pn
    local x, y, width, height = 0, 0, 0, 0
    local locked = true
    local cipw = 210
    local key = win.xuiStyleName or (win.entity and win.entity:getName()) or "Default"
    ISEntityUI.CloseWindows()
    ISEntityUI.EnsurePlayers()
    local P = ISEntityUI.players
    if P[pn] and P[pn].windows[key] then
        local e = P[pn].windows[key]
        if e.instance then e.instance:close() end
        if e.width and e.height then
            width = math.min(e.width, getCore():getScreenWidth() - cipw)
            height = math.min(e.height, getCore():getScreenHeight() - cipw)
        end
        if e.x and e.y then
            x = math.min(e.x, getCore():getScreenWidth() - width - cipw)
            y = math.min(e.y, getCore():getScreenHeight() - height - cipw)
        end
        locked = e.locked
    else
        P[pn] = P[pn] or {}
        P[pn].windows = P[pn].windows or {}
        P[pn].windows[key] = {}
    end
    win:initialise()
    win:instantiate()
    win:setX(x)
    win:setY(y)
    win:setVisible(true)
    local ty = getmetatable(win).Type
    if ty == "ISBuildWindow" or ty == "ISHandcraftWindow" then
        if locked then win:toggleLock() end
    end
    if win.calculateLayout then win:calculateLayout(width, height) end
    win:addToUIManager()
    P[pn].windows[key].instance = win
    P[pn].windows[key].playerObj = S.p
    P[pn].windows[key].entityObj = nil
end
-- the cross among the logic's buildable recipes (by name; a "cross" in the name as the fallback)
function H.findCross(logic)
    local found, byWord = nil, nil
    pcall(function()
        local list = logic:getAllBuildableRecipes()
        for i = 0, list:size() - 1 do
            local r = list:get(i)
            local nm = tostring(r:getName())
            if nm == S.CROSS then found = r end
            if not byWord and string.find(string.lower(nm), "cross", 1, true) then byWord = r end
        end
    end)
    if not found then pcall(function() found = getScriptManager():getCraftRecipe(S.CROSS) end) end
    return found or byWord
end
-- counting wrappers on the panel instance (each calls the game's own function through)
function H.watchPanel(T, P)
    P.update = function(self)
        if S.inScript then T.updScript = T.updScript + 1 else T.updGame = T.updGame + 1; T.lastUpd = getTimestampMs() end
        return ISBuildPanel.update(self)
    end
    P.updateContainers = function(self, force)
        T.rereads = T.rereads + 1
        return ISBuildPanel.updateContainers(self, force)
    end
    P.createBuildIsoEntity = function(self, dontSetDrag)
        if dontSetDrag then T.contChanged = T.contChanged + 1 else T.armed = T.armed + 1 end
        return ISBuildPanel.createBuildIsoEntity(self, dontSetDrag)
    end
end
-- the action's end: ISBuildAction:perform calls item:create (ISBuildAction.lua:228), counted on the class
function H.createOn()
    if S.createWas then return end
    S.createWas = ISBuildIsoEntity.create
    local orig = S.createWas
    S.createWrap = function(self, x, y, z, north, sprite)
        local T = S.T
        if T then
            T.creates = T.creates + 1
            pcall(function() T.canAtCreate = self.buildPanelLogic:canPerformCurrentRecipe() and true or false end)
            T.reachAtCreate = H.allInReach()
            T.whereAtCreate = H.whereAll()
        end
        return orig(self, x, y, z, north, sprite)
    end
    ISBuildIsoEntity.create = S.createWrap
end
function H.createOff()
    if not S.createWas then return end
    if ISBuildIsoEntity.create == S.createWrap then ISBuildIsoEntity.create = S.createWas end
    S.createWas, S.createWrap = nil, nil
end
function H.closeWin()
    if S.win then
        local w = S.win
        S.win = nil
        pcall(function() w:close() end)
        pcall(function() w:removeFromUIManager() end)
    end
    H.regBack()
    ISBuildWindow.instance = S.instWasWin
end
-- the game's per-update re-read, should the hidden window's own update not come (the same function, ISBuildPanel:update)
function H.mirror(T)
    if not (S.win and S.win.BuildPanel) then return end
    local now = getTimestampMs()
    if T.lastUpd == nil or now - T.lastUpd > 300 then
        S.inScript = true
        pcall(function() S.win.BuildPanel:update() end)
        S.inScript = false
    end
end

-- ===================================================================== setup
Q.step(2, function()
    S.dead = S.p:isDead() and true or false
    if S.dead then Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    if ZEDQA_HOME then ZEDQA_HOME("bd_b7_game") end
    H.speed(1)
    H.stop()
    H.noDrag()
    S.hx, S.hy = math.floor(S.p:getX()), math.floor(S.p:getY())
    for _, it in ipairs(H.all()) do S.had[it] = true end
    H.snapWorld(S.floorHad)
    S.handWas = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() }
    pcall(function() if not S.p:isGodMod() then S.p:setGodMod(true); H.note("god mode was off: turned on and left on") end end)
    pcall(function() S.invWas = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
    pcall(function() S.instWas = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
    pcall(function() S.bcWas = S.p:isBuildCheat(); S.p:setBuildCheat(false) end)
    pcall(function() S.bmWas = ISBuildMenu.cheat; ISBuildMenu.cheat = false end)
    Q.say("setup: found ISBuildMenu.cheat " .. tostring(S.bmWas) .. ", BuildCheat " .. tostring(S.bcWas)
        .. ", instant actions " .. tostring(S.instWas) .. ": all three off for the run")
    H.xpSnap()
    S.instWasWin = ISBuildWindow.instance
    H.regSnap()
    pcall(function() S.p:setPrimaryHandItem(nil); S.p:setSecondaryHandItem(nil) end)
    local aside, kept = H.stashOwn()
    H.note(aside .. " of his own building things are set aside for the run" .. (#kept > 0 and ("; kept (worn, held or on the belt): " .. H.join(kept)) or ""))
    for _, d in ipairs(S.RING1) do
        if not S.crate then
            local sq = H.sq(S.hx + d[1], S.hy + d[2])
            if sq and H.free(sq) then
                S.crate = H.mkCrate(sq)
                if S.crate then S.crateSq = sq end
            end
        end
    end
    S.ok = Q.check(S.crate ~= nil, "setup: a crate (" .. S.CRATE .. ") laid on a tile beside him",
        "crate " .. (S.crateSq and (S.crateSq:getX() .. "," .. S.crateSq:getY()) or "none") .. ", him at " .. S.hx .. "," .. S.hy)
    S.e0 = H.errN()
    H.refreshLoot()
end)

-- ===================================================================== one run: the materials in one place, the cross placed far
function C.run(where)
    local lab = "game window, materials " .. (where == "crate" and "in the crate beside him" or "on the floor at his feet")
    local T = { where = where, acts = 0, updGame = 0, updScript = 0, rereads = 0, contChanged = 0, armed = 0, creates = 0 }
    S.runs[#S.runs + 1] = T
    -- the materials staged, then the game's window opened with the cross (as a player opens it beside his things)
    H.step(2, function()
        if not S.ok then return end
        H.speed(1)
        H.stop()
        H.noDrag()
        H.clearMat()
        H.goHome()
        H.stageMat(where)
        T.staged = #S.mats
        T.whereStart = H.whereAll()
        local ok, err = pcall(function()
            -- ISEntityUI.lua:580-582 (OpenBuildWindow without ZeD's hook): the window built from the global skin
            -- the function reads, then createWindow
            local win = ISXuiSkin.build(skin, S.WKEY, ISBuildWindow, 0, 0, 60, 30, S.p, nil, nil)
            S.win = win
            H.createWindow(win)
        end)
        local P = S.win and S.win.BuildPanel
        T.logic = P and P.logic
        T.open = Q.check(ok and P ~= nil and T.logic ~= nil and ISBuildWindow.instance == P,
            lab .. ": staging: the game's own build window opens (ISBuildWindow, its ISBuildPanel and BuildLogic; ZeD's hook not called)",
            ok and ("panel " .. tostring(P ~= nil) .. ", logic " .. tostring(T.logic ~= nil) .. ", ISBuildWindow.instance is the panel " .. tostring(P ~= nil and ISBuildWindow.instance == P)) or tostring(err))
        if not T.open then H.closeWin(); return end
        H.watchPanel(T, P)
        T.recipe = H.findCross(T.logic)
        if not T.recipe then Q.check(false, lab .. ": staging: the game lists the cross (" .. S.CROSS .. ")"); T.open = false; H.closeWin(); return end
        pcall(function() T.rname = tostring(T.recipe:getName()) end)
        -- ISEntityUI.lua:584: a recipe asked for is set on the panel's logic
        local okR, errR = pcall(function() T.logic:setRecipe(T.recipe) end)
        if not okR then Q.check(false, lab .. ": staging: the logic takes the cross (setRecipe)", tostring(errR)); T.open = false; H.closeWin() end
    end)
    -- the Build button's state is set in its prerender: give it frames, then wait for it to read enabled
    Q.waitMs(800)
    H.wait(4000, function()
        if not T.open then return true end
        local cc = S.win and S.win.BuildPanel and S.win.BuildPanel.craftRecipePanel and S.win.BuildPanel.craftRecipePanel.craftControl
        return cc ~= nil and cc.buttonCraft ~= nil and cc.buttonCraft.enable == true
    end, function(btnOk)
        if not T.open then return end
        local P = S.win and S.win.BuildPanel
        local cc = P and P.craftRecipePanel and P.craftRecipePanel.craftControl
        pcall(function() T.canPress = T.logic:canPerformCurrentRecipe() and true or false end)
        T.btn = btnOk
        T.ready = Q.check(T.canPress == true and cc ~= nil and cc.buttonCraft ~= nil,
            lab .. ": staging: the game's logic can build the cross with the materials in place (its Build button there)",
            "canPerformCurrentRecipe " .. tostring(T.canPress) .. ", the button reads enabled " .. tostring(btnOk) .. ", recipe " .. tostring(T.rname)
            .. ", materials " .. T.whereStart)
        if not T.ready then return end
        if not btnOk then H.note(lab .. ": the Build button never read enabled (its prerender); pressed through its handler anyway, the logic says it can build") end
        -- the button's own handler (ISWidgetBuildControl.lua:189-208)
        H.noDrag()
        local okB, errB = pcall(function() cc:onButtonClick(cc.buttonCraft) end)
        T.cur = H.drag()
        T.curUp = Q.check(okB and H.isBuildCur(T.cur) and T.cur == P.buildEntity,
            lab .. ": staging: Build starts the game's own cursor (ISBuildPanel.buildEntity, an ISBuildIsoEntity set with getCell():setDrag)",
            okB and (H.dragType(T.cur) .. ", the panel's own " .. tostring(T.cur ~= nil and T.cur == P.buildEntity) .. ", blockBuild " .. tostring(T.cur and T.cur.blockBuild)) or tostring(errB))
        if not T.curUp then return end
        T.sq = H.farSq(T.cur)
        if not Q.check(T.sq ~= nil, lab .. ": staging: a tile 6 to 9 away takes the cursor (ISBuildIsoEntity:isValid)") then return end
        T.d = H.fl(H.dist(T.sq))
        T.before = H.snapObjs(S.hx, S.hy, 10)
        S.T = T
        H.createOn()
        H.speed(1)
        H.placeAt(T.cur, T.sq, lab)
        T.q0 = H.qlen()
        T.go = Q.check(T.q0 > 0, lab .. ": staging: the click queues the build (the walk, then ISBuildAction)",
            "queue " .. T.q0 .. " (" .. H.head() .. "), tile " .. T.sq:getX() .. "," .. T.sq:getY() .. ", " .. T.d .. " tiles off")
        T.t0 = getTimestampMs()
    end)
    -- the walk at x1, the build action at x20, until the queue is empty; the game's re-read watched each tick
    H.wait(60000, function()
        if not T.go then return true end
        H.mirror(T)
        H.seeMats()
        local a = H.queue()[1]
        if a and a.Type == "ISBuildAction" then
            if T.lastAct ~= a then
                T.lastAct = a
                T.acts = T.acts + 1
                if T.acts == 1 then T.reachAtAct = H.allInReach(); T.whereAtAct = H.whereAll() end
            end
            H.speed(3)
        else
            H.speed(1)
        end
        return H.qlen() == 0
    end, function(ok)
        H.speed(1)
        if not T.go then return end
        T.done = ok
        if not ok then H.stop() end
    end)
    -- a moment for the action's end to settle (onStopCraft re-arms the cursor), then the answer
    Q.waitMs(1500)
    H.step(2, function()
        H.createOff()
        S.T = nil
        if not T.go then
            Q.say("B7GAME run=" .. where .. " actions=0 built=0 used=none leftIn=" .. H.whereAll() .. " (not run: the staging did not hold)")
            return
        end
        T.new = H.newObjs(T.before, S.hx, S.hy, 10)
        for _, o in ipairs(T.new) do S.built[#S.built + 1] = o end
        local used, left = {}, {}
        for _, m in ipairs(S.mats) do
            local w = H.where(m.it)
            if w == "gone" then used[#used + 1] = m.kind .. " from " .. tostring(m.seen) end
            left[#left + 1] = m.kind .. ":" .. w
        end
        T.used, T.built = #used, #T.new
        local names = {}
        for _, o in ipairs(T.new) do names[#names + 1] = H.objName(o) end
        Q.say("B7GAME run=" .. where .. " actions=" .. T.acts .. " built=" .. T.built .. " used=" .. H.join(used)
            .. " leftIn=" .. table.concat(left, " "))
        Q.say("B7GAME detail run=" .. where .. " tile=" .. T.sq:getX() .. "," .. T.sq:getY() .. " (" .. T.d .. " tiles off)"
            .. " queueEmptied=" .. tostring(T.done) .. " in " .. H.fl((getTimestampMs() - (T.t0 or getTimestampMs())) / 1000) .. "s"
            .. " materialsAtStart=[" .. tostring(T.whereStart) .. "] atAction=[" .. tostring(T.whereAtAct) .. "] inGameContainersAtAction=" .. tostring(T.reachAtAct)
            .. " create=" .. T.creates .. " canPerformAtCreate=" .. tostring(T.canAtCreate) .. " inGameContainersAtCreate=" .. tostring(T.reachAtCreate)
            .. " rereads(updateContainers)=" .. T.rereads .. " containerChanges=" .. T.contChanged .. " panelUpdate=game " .. T.updGame .. "/script " .. T.updScript
            .. " cursorAfter=" .. H.dragType(H.drag()) .. (H.drag() == T.cur and " (re-armed, the same)" or "")
            .. " built=" .. H.join(names))
        local zedLine = where == "crate" and "materials, built far from the crate" or "materials, built far from the floor pile"
        local verdict
        if T.built > 0 then
            verdict = "the game BUILDS here (" .. T.built .. " standing, " .. T.used .. " of 3 used): if ZeD built nothing, ZeD must change"
        elseif T.acts > 0 then
            verdict = "the game ran " .. T.acts .. " build action(s) and built nothing (" .. T.used .. " of 3 used): if ZeD also built nothing, ZeD matches the game"
        else
            verdict = "the game ran no build action (" .. T.used .. " of 3 used): compare with ZeD's action count"
        end
        H.note("B7 compare (" .. where .. "): " .. verdict .. ". ZeD's answer is bd_tab's \"" .. zedLine .. "\" line above in this console (its actions, new objects and used)")
        -- this run's things away
        for _, o in ipairs(T.new) do H.rmObj(o) end
        H.stop()
        H.closeWin()
        H.noDrag()
        H.clearMat()
        H.goHome()
    end)
end

C.run("crate")
C.run("floor")
H.step(2, function()
    local parts = {}
    for _, T in ipairs(S.runs) do
        parts[#parts + 1] = T.where .. ": " .. tostring(T.acts) .. " action(s), " .. tostring(T.built or 0) .. " built, " .. tostring(T.used or 0) .. " used"
    end
    H.note("B7 the game's own build window, the cross 6 to 9 tiles from its materials: " .. H.join(parts)
        .. ". Evidence for Build: nothing built in both = ZeD's Build tab matches the game; built = ZeD must change.")
    local e1 = H.errN()
    if S.e0 and e1 and e1 ~= S.e0 then H.note("the game's Lua error count rose by " .. (e1 - S.e0) .. " over the runs (see console.txt)") end
end)

-- ===================================================================== put back
Q.mark()
H.step(2, function()
    H.speed(1)
    H.stop()
    H.createOff()
    S.T = nil
    H.closeWin()
    H.noDrag()
end)
H.step(3, function()
    if S.dead then return end
    for _, o in ipairs(S.built) do if H.objOn(o) then H.rmObj(o) end end
    for _, m in ipairs(S.mats) do H.rmItem(m.it) end
    S.mats = {}
    for _, it in ipairs(S.given) do H.rmItem(it) end
    RT.takeBack()
    if S.crate then H.rmObj(S.crate) end
    local n = 0
    for _, it in ipairs(H.all()) do if not S.had[it] then H.rmItem(it); n = n + 1 end end
    local now = {}
    H.snapWorld(now)
    for wo in pairs(now) do
        if not S.floorHad[wo] then
            pcall(function() local sq = wo:getSquare(); if sq then sq:transmitRemoveItemFromSquare(wo) end end)
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            n = n + 1
        end
    end
    S.swept = n
    S.stashLost = H.unstash()
    pcall(function()
        local a, b = S.handWas[1], S.handWas[2]
        S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
        S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
    end)
    S.xpGrew = H.xpBack()
    pcall(function() S.p:setTimedActionInstantCheat(S.instWas and true or false) end)
    pcall(function() S.p:setBuildCheat(S.bcWas and true or false) end)
    pcall(function() ISBuildMenu.cheat = S.bmWas end)
    H.goHome()
end)
H.step(5, function()
    if S.dead then return end
    if ZEDQA_HOME then ZEDQA_HOME("bd_b7_game") end
end)
H.step(5, function()
    if S.dead then return end
    pcall(function() getCell():setDrag(nil, S.pn) end)
    Q.check(H.drag() == nil and H.qlen() == 0, "put back: no cursor and no action left (getCell():setDrag(nil, pn))", H.dragType(H.drag()) .. " / " .. H.head())
    local open = nil
    pcall(function() open = ISEntityUI.IsWindowOpen(S.pn, S.WKEY) end)
    Q.check(S.win == nil and not open and ISBuildWindow.instance == S.instWasWin and H.regSame(),
        "put back: the game's build window closed, ISEntityUI's registry entry and ISBuildWindow.instance as found",
        "open " .. tostring(open and true or false) .. ", instance as found " .. tostring(ISBuildWindow.instance == S.instWasWin) .. ", registry as found " .. tostring(H.regSame()))
    Q.check(S.createWas == nil and ISBuildIsoEntity.create ~= nil, "put back: the counting wrapper off ISBuildIsoEntity.create", tostring(S.createWas == nil))
    local left = {}
    for _, o in ipairs(S.built) do if H.objOn(o) then left[#left + 1] = H.objName(o) end end
    if S.crate and H.objOn(S.crate) then left[#left + 1] = "the crate " .. S.CRATE end
    Q.check(#left == 0, "put back: nothing built or laid is left", #S.built .. " built and the crate taken away" .. (#left > 0 and ("; left: " .. H.join(left)) or ""))
    local gl = {}
    for _, it in ipairs(S.given) do if H.still(it) then gl[#gl + 1] = H.ft(it) end end
    Q.check(#gl == 0, "put back: every material staged is gone (crate, floor, inventory)", #S.given .. " given" .. (#gl > 0 and ("; left: " .. H.join(gl)) or ""))
    local extra = {}
    for _, it in ipairs(H.all()) do if not S.had[it] then extra[#extra + 1] = H.ft(it) end end
    local now, floor = {}, 0
    H.snapWorld(now)
    for wo in pairs(now) do if not S.floorHad[wo] then floor = floor + 1 end end
    Q.check(#extra == 0 and floor == 0 and (S.stashLost or 0) == 0, "put back: he carries what he carried, his own things back, nothing new on the floor",
        tostring(S.swept) .. " swept; carried extra: " .. H.join(extra) .. "; " .. floor .. " new on the floor; " .. tostring(S.stashLost) .. " of his own not given back")
    local bm, bc, ia = nil, nil, nil
    pcall(function() bm = ISBuildMenu.cheat end)
    pcall(function() bc = S.p:isBuildCheat() end)
    pcall(function() ia = S.p:isTimedActionInstantCheat() end)
    Q.check(bm == S.bmWas and (bc and true or false) == (S.bcWas and true or false) and (ia and true or false) == (S.instWas and true or false),
        "put back: the cheats as found (ISBuildMenu.cheat, BuildCheat, instant actions)", tostring(bm) .. " / " .. tostring(bc) .. " / " .. tostring(ia)
        .. " (found " .. tostring(S.bmWas) .. " / " .. tostring(S.bcWas) .. " / " .. tostring(S.instWas) .. ")")
    local lvlLeft = 0
    pcall(function() for _, r in ipairs(S.xp) do if S.p:getPerkLevel(r.perk) ~= r.lvl then lvlLeft = lvlLeft + 1 end end end)
    Q.check(lvlLeft == 0, "put back: the skill levels as found", tostring(S.xpGrew) .. " skills changed, " .. lvlLeft .. " levels not back")
    Q.check(getGameSpeed() == 1, "put back: game speed 1", tostring(getGameSpeed()))
    pcall(function() if S.invWas ~= nil then S.p:setInvincible(S.invWas) end end)
end)
Q.start()
