-- ZeDUI/tools/qa/gallery_v1_b_lib.lua  (Nov 17 2026, QA): the shared helpers of the ZeD-GUI 1.0 gallery captures, part B
-- (HANDOFF_design_gallery_v1_20261117.md, "For QA: the shot list": 04, 05, 46, 59, 63, 65). Run it once in a manifest
-- before gallery_v1_b_*.lua; it only defines the global GV1 and calls NOTHING of ZeD's, so the vanilla run
-- (gallery_v1_b_van.txt, ZeD off) uses it too. grep "ZEDQA g1lib".
--   GV1.new(tag)               a script's state table S: S.p, S.pn, S.say, S.step(n, fn) (fn returning true runs again
--                              after n frames), S.took, S.skipped; GV1.run(S) steps it on each drawn frame (OnPreUIDraw)
--   GV1.shot(S, name)          the gallery rules before the shot: the debug console hidden, god mode and invisible off,
--                              zombies-don't-attack on, the pointer hidden, a load over 19 kg (or the game's heavy flag)
--                              refused; then the load line, every window box and whether the character stands clear
--   GV1.tryPlaces(S, places, finder, key)  teleports to each place in turn until finder(place) answers; S[key] holds it
--   GV1.findStreet(c), GV1.findShore(c)    a mid-street square (street floor all round), a shore with open water ahead
GV1 = GV1 or {}
local L = GV1
L.HOME = { x = 925.5, y = 13040.5, z = 0 }   -- the QA home, the drag strip (zedqa_prelude.lua's HOME)

function L.new(tag)
    local S = { tag = tag, Q = {}, qi = 1, took = {}, skipped = {}, given = {}, hidden = {} }
    S.p = getPlayer()
    S.pn = S.p:getPlayerNum()
    S.inv = S.p:getInventory()
    S.say = function(s) print("ZEDQA " .. tag .. " " .. tostring(s)) end
    S.step = function(n, fn) S.Q[#S.Q + 1] = { n = n, fn = fn } end
    return S
end

-- DONE once: the last step says it, and the queue's end says it if a failed last step did not
function L.done(S)
    if S.doneSaid then return end
    S.doneSaid = true
    S.say("DONE")
end
function L.run(S)
    S.tick = function()
        if S.every then pcall(S.every) end
        local s = S.Q[S.qi]
        if not s then Events.OnPreUIDraw.Remove(S.tick); L.done(S); return end
        S.wait = (S.wait or s.n) - 1
        if S.wait > 0 then return end
        S.wait = nil
        local ok, r = pcall(s.fn)
        if not ok then S.say("ERR step " .. S.qi .. ": " .. tostring(r)) end
        if ok and r == true then return end
        S.qi = S.qi + 1
    end
    Events.OnPreUIDraw.Add(S.tick)
    S.say("start")
end

-- ---------------------------------------------------------------- the look
function L.console()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false) end
        end
    end)
end
-- a method called only when the object has it: a pcall'd call of a missing method still lands in the game's error
-- list (and so in the red error box), so nothing here calls a method it has not found first
-- (the arguments are passed by count: a Java method counts a trailing nil as an argument, "expected 0 arguments, got 2")
function L.call(o, name, ...)
    if o == nil then return nil end
    local f = o[name]
    if f == nil then return nil end
    return f(o, ...)
end
function L.cheats(S)
    L.call(S.p, "setGodMod", false)
    L.call(S.p, "setInvisible", false)
    L.call(S.p, "setZombiesDontAttack", true)
end
function L.keepCheats(S)
    S.godWas = L.call(S.p, "isGodMod")
    S.invisWas = L.call(S.p, "isInvisible")
    S.zdaWas = L.call(S.p, "isZombiesDontAttack")
    L.hideErrors(S, true)
end
function L.putCheats(S)
    L.call(S.p, "setGodMod", S.godWas == true)
    L.call(S.p, "setInvisible", S.invisWas == true)
    L.call(S.p, "setZombiesDontAttack", S.zdaWas == true)
    L.showErrors(S)
end

-- ---------------------------------------------------------------- the glasses (the QA character is short-sighted)
-- gallery_b10_glasses.lua puts a pair on; a teleport or a staging that strips them gets them put back before a shot
L.GLASSES = "Base.Glasses_Prescription"
function L.glasses(S)
    local g, worn = nil, false
    local items = S.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == L.GLASSES then
            if S.p:isEquippedClothing(it) then worn = true end
            g = g or it
        end
    end
    if worn then return true end
    if not g then g = S.inv:AddItem(L.GLASSES) end
    if not g then S.say("ERR no prescription glasses to wear: the world will blur"); return false end
    S.p:setWornItem(g:getBodyLocation(), g)
    S.say("glasses put back on")
    return true
end

-- ---------------------------------------------------------------- the red error box
-- With ZeD on, the game's own error list is filed by ZeD.Messages and shows as a red "Error / Project Zomboid N
-- errors" note (ZeD_MessagesToasts; the belt's paper note counts the same sources). The error sources are held out
-- of ZeD.Messages for the script (L.hideErrors, with keep = true at the start: put back by L.showErrors at the end)
-- and the toasts are dropped before each shot. Any visible element whose class or Lua Type names an error
-- (ZeD_MessagesToasts, the game's DebugErrorsWindow) is hidden too; with ZeD off only that walk runs.
function L.hideErrors(S, keep)
    local M = ZeD and ZeD.Messages
    if M and M.sources then
        local n = 0
        S.errStash = S.errStash or {}
        for name, src in pairs(M.sources) do
            if type(src) == "table" and src.kind == "err" then S.errStash[name] = src; n = n + 1 end
        end
        for name, _ in pairs(S.errStash) do M.sources[name] = nil end
        M.toasts = {}
        M.seq = (M.seq or 0) + 1
        if keep and n > 0 then S.say("error sources held out of Messages for the run: " .. n) end
    end
    local hid = {}
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:isVisible() then
                local nm = e:getClass():getSimpleName()
                local t = e:getTable()
                if t and t.Type then nm = tostring(t.Type) end
                if nm == "ZeD_MessagesToasts" or string.find(nm, "Error", 1, true) then e:setVisible(false); hid[#hid + 1] = nm end
            end
        end
    end)
    if #hid > 0 then S.say("hidden: " .. table.concat(hid, ", ")) end
end
function L.showErrors(S)
    local M = ZeD and ZeD.Messages
    if not (M and M.sources and S.errStash) then return end
    for name, src in pairs(S.errStash) do if M.sources[name] == nil then M.sources[name] = src end end
    S.errStash = nil
    M.seq = (M.seq or 0) + 1
end

-- the window boxes: every visible element at least 160 x 120 that is not the whole screen (the HUD's small pieces
-- and the full-screen layers left out)
function L.boxes()
    local out = {}
    pcall(function()
        local W, H = getCore():getScreenWidth(), getCore():getScreenHeight()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:isVisible() and e:getClass():getSimpleName() ~= "UIDebugConsole" then
                local w, h = math.floor(e:getWidth()), math.floor(e:getHeight())
                if w >= 160 and h >= 120 and not (w >= W - 4 and h >= H - 4) then
                    local nm = e:getClass():getSimpleName()
                    pcall(function() local t = e:getTable(); if t and t.Type then nm = tostring(t.Type) end end)
                    out[#out + 1] = { n = nm, x = math.floor(e:getX()), y = math.floor(e:getY()), w = w, h = h }
                end
            end
        end
    end)
    return out
end
function L.boxLine()
    local t = {}
    for _, b in ipairs(L.boxes()) do t[#t + 1] = b.n .. "@" .. b.x .. "," .. b.y .. " " .. b.w .. "x" .. b.h end
    return (#t > 0) and table.concat(t, "; ") or "none"
end
-- the character on the screen (feet and head) against the boxes: "clear" or the boxes over it
function L.clear(S)
    local line = "?"
    pcall(function()
        local sx = isoToScreenX(S.pn, S.p:getX(), S.p:getY(), S.p:getZ())
        local sy = isoToScreenY(S.pn, S.p:getX(), S.p:getY(), S.p:getZ())
        local over = {}
        for _, b in ipairs(L.boxes()) do
            for _, yy in ipairs({ sy - 10, sy - 90 }) do
                if sx >= b.x and sx < b.x + b.w and yy >= b.y and yy < b.y + b.h then over[b.n] = true end
            end
        end
        local t = {}
        for n, _ in pairs(over) do t[#t + 1] = n end
        line = "at " .. math.floor(sx) .. "," .. math.floor(sy) .. ((#t > 0) and (" COVERED by " .. table.concat(t, ", ")) or " clear")
    end)
    return line
end
function L.covered(x, y)
    for _, b in ipairs(L.boxes()) do
        if x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h then return b.n end
    end
    return nil
end

-- the load: gallery_unload.lua's line when it ran, else the game's own numbers
function L.load(S)
    local U = GAL_UNLOAD
    if U and U.line and U.weight then
        local w = U.weight()
        local hv = U.heavy and U.heavy() or 0
        return w, U.line(), hv
    end
    local w, mx = 999, 0
    pcall(function() w = S.p:getInventoryWeight(); mx = S.p:getMaxWeight() end)
    local hv = (w > mx) and 1 or 0
    return w, string.format("%.1f of %s kg (gallery_unload.lua did not run)", w, tostring(mx)), hv
end
function L.notTaken(S, name, why)
    S.skipped[#S.skipped + 1] = name
    S.say("not taken: " .. name .. " (" .. tostring(why) .. ")")
end
function L.shot(S, name)
    L.console(); L.cheats(S)
    pcall(L.glasses, S)
    L.hideErrors(S)
    local w, line, hv = L.load(S)
    if w > 19 or (hv and hv > 0) then L.notTaken(S, name, "over the load limit: " .. line); return false end
    pcall(function() Mouse.setCursorVisible(false) end)
    local ok = pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
    if ok then S.took[#S.took + 1] = name end
    S.say((ok and "shot " or "ERR shot ") .. name .. " | load " .. line)
    S.say("  boxes " .. L.boxLine())
    S.say("  character " .. L.clear(S))
    return ok
end
function L.summary(S)
    S.say("taken " .. #S.took .. ": " .. table.concat(S.took, " "))
    S.say("not taken " .. #S.skipped .. ": " .. table.concat(S.skipped, " "))
end

-- ---------------------------------------------------------------- things
function L.give(S, ft)
    local it = nil
    pcall(function() it = S.inv:AddItem(ft) end)
    if it then S.given[#S.given + 1] = it end
    return it
end
function L.takeBack(S)
    for _, it in ipairs(S.given) do
        pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
        pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
        pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    end
    S.given = {}
end
-- every carried thing holding a fluid (top level and in the bags worn or held) taken out for the run, so no fuel
-- the character carries fills a recipe's fluid slot; keep = the one thing to leave. L.unhide puts them back.
function L.hideFluids(S, keep)
    local bags = { S.inv }
    pcall(function()
        local items = S.inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if instanceof(it, "InventoryContainer") and S.p:isEquipped(it) then bags[#bags + 1] = it:getInventory() end
        end
    end)
    local list = {}
    for _, c in ipairs(bags) do
        pcall(function()
            local items = c:getItems()
            for i = 0, items:size() - 1 do
                local it = items:get(i)
                local fc = L.call(it, "getFluidContainer")
                local full = fc ~= nil and not fc:isEmpty()
                if full and it ~= keep and not S.p:isEquipped(it) then list[#list + 1] = { it = it, c = c } end
            end
        end)
    end
    for _, e in ipairs(list) do
        if pcall(function() e.c:Remove(e.it) end) then S.hidden[#S.hidden + 1] = e end
    end
    S.say("fluid holders taken out for the run: " .. #S.hidden)
end
function L.unhide(S)
    local n = 0
    for _, e in ipairs(S.hidden) do if pcall(function() e.c:AddItem(e.it) end) then n = n + 1 end end
    S.hidden = {}
    S.say("fluid holders put back: " .. n)
end

-- ---------------------------------------------------------------- places
function L.moveTo(S, x, y, z)
    pcall(function()
        local car = S.p:getVehicle()
        if car then car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end
    end)
    pcall(function() S.p:setX(x); S.p:setY(y); S.p:setZ(z); S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z) end)
end
function L.tryPlaces(S, places, finder, key)
    for _, c in ipairs(places) do
        S.step(5, function()
            if S[key] then return end
            S.say("trying " .. c.name .. " at " .. c.x .. "," .. c.y)
            L.moveTo(S, c.x + 0.5, c.y + 0.5, 0)
            S.t = 0
        end)
        S.step(10, function()
            if S[key] then return end
            S.t = S.t + 1
            local sq = getCell():getGridSquare(c.x, c.y, 0)
            if not (sq and sq:getChunk()) and S.t < 80 then return true end
            if not sq then S.say("  " .. c.name .. ": not loaded after " .. S.t .. " polls") end
        end)
        S.step(150, function()
            if S[key] then return end
            local ok, r = pcall(finder, c)
            if ok and r then
                r.place = c.name
                S[key] = r
                S.say("  found at " .. r.x .. "," .. r.y .. " (" .. c.name .. ")" .. (r.dir and (" facing " .. r.dir) or ""))
            else
                S.say("  none at " .. c.name .. (ok and "" or (": ERR " .. tostring(r))))
            end
        end)
    end
end
function L.floorName(sq)
    local n = ""
    pcall(function() n = sq:getFloor():getSprite():getName() or "" end)
    return string.lower(n)
end
function L.streetSq(sq)
    if not sq then return false end
    local n = L.floorName(sq)
    if not (n:find("street", 1, true) or n:find("road", 1, true) or n:find("asphalt", 1, true)) then return false end
    local good = sq:isOutside() and sq:getObjects():size() <= 2 and sq:getMovingObjects():size() == 0
    return good and L.call(sq, "getVehicleContainer") == nil
end
L.AROUND = { { 3, 0 }, { -3, 0 }, { 0, 3 }, { 0, -3 }, { 2, 2 }, { -2, -2 }, { 2, -2 }, { -2, 2 } }
function L.findStreet(c)
    local cell, best, bd = getCell(), nil, nil
    for dx = -50, 50, 2 do
        for dy = -50, 50, 2 do
            local x, y = c.x + dx, c.y + dy
            if L.streetSq(cell:getGridSquare(x, y, 0)) then
                local all = true
                for _, d in ipairs(L.AROUND) do
                    if all and not L.streetSq(cell:getGridSquare(x + d[1], y + d[2], 0)) then all = false end
                end
                local dd = dx * dx + dy * dy
                if all and (not bd or dd < bd) then best, bd = { x = x, y = y, floor = L.floorName(cell:getGridSquare(x, y, 0)) }, dd end
            end
        end
    end
    return best
end
function L.isWater(sq)
    if not sq then return false end
    local pr = sq:getProperties()
    if not pr then return false end
    if pr.has then return pr:has(IsoFlagType.water) and true or false end
    return L.call(pr, "Is", IsoFlagType.water) and true or false
end
L.DIRS = { { "E", 1, 0 }, { "S", 0, 1 }, { "W", -1, 0 }, { "N", 0, -1 } }
-- a dry square (floor, no building, no tree) with at least 6 water squares straight ahead; the cast target 5 ahead;
-- the one with the most fish in front, then the nearest to the place
function L.findShore(c)
    local cell, best = getCell(), nil
    for dx = -60, 60, 2 do
        for dy = -60, 60, 2 do
            local x, y = c.x + dx, c.y + dy
            local sq = cell:getGridSquare(x, y, 0)
            if sq and sq:getFloor() and not L.isWater(sq) and not sq:getBuilding() and not sq:getTree() then
                for _, d in ipairs(L.DIRS) do
                    local run = 0
                    for k = 1, 7 do
                        if run == k - 1 and L.isWater(cell:getGridSquare(x + d[2] * k, y + d[3] * k, 0)) then run = run + 1 end
                    end
                    if run >= 6 then
                        local tx, ty = x + d[2] * 5 + 0.5, y + d[3] * 5 + 0.5
                        local fish, nofish = -1, false
                        if FishSchoolManager and FishSchoolManager.getInstance then fish = L.call(FishSchoolManager.getInstance(), "getFishAbundance", tx, ty) or -1 end
                        if Fishing and Fishing.isNoFishZone then nofish = Fishing.isNoFishZone(tx, ty) end
                        local dd = dx * dx + dy * dy
                        if not nofish and (not best or fish > best.fish or (fish == best.fish and dd < best.dd)) then
                            best = { x = x, y = y, dir = d[1], dx = d[2], dy = d[3], fish = fish, tx = tx, ty = ty, dd = dd }
                        end
                    end
                end
            end
        end
    end
    return best
end

print("ZEDQA g1lib GV1 defined (gallery_v1_b helpers)")
L.libN = 0
L.libDone = function()
    L.libN = L.libN + 1
    if L.libN < 10 then return end
    Events.OnPreUIDraw.Remove(L.libDone)
    print("ZEDQA g1lib DONE")
end
Events.OnPreUIDraw.Add(L.libDone)
