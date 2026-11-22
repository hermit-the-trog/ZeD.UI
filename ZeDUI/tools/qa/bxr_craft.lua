-- ZeDUI/tools/qa/bxr_craft.lua  (Nov 21 2026, QA; tag bxrc): the beast day report's pictures of the Crafting tab's
-- fixes (git 49039efdf c500fbab2). Pictures to Zomboid/Screenshots/bxr_<name>.png (QA's runner moves them to
-- Screenshots/beast_day_report/). Manifest beast_report_craft.txt (the story stage, gallery_unload.lua, G1,
-- hfr_common.lua). Style and theme as found. Nothing is crafted: Craft is never pressed.
--   W24_planks_1_of_4          a recipe that takes 4 planks, 1 carried: the card's plank row reads 1/4 (was 1/1)
--   B6-16_alternatives_1_of_4  a slot that takes 4 of two types (Divide Food into 4 Bowls: bowls or clay bowls, a
--                              recipe he knows), 1 bowl carried: its alternatives list reads 1/4 and 0/4 (was 1/1)
--   B6-14_any_surface_ready    beside a table, a plank and a screwdriver carried: Drill Plank reads ready, Craft lit
--   W23_chosen_in_list         Drill Plank's plank slot, the large branch chosen by hand in the alternatives list
--   W23_chosen_on_card         the same choice named on the card's row, before Craft
--   W25_floor_2_of_4           no plank carried, 2 on the floor beside him: the plank row reads 2/4
--   W25_floor_and_crate_4_of_4 2 more in a crate in reach: the plank row reads 4/4
-- The scene: the story's smoking spot (in the open, on the camera side of the store), or the nearest open square to
-- it with room; a table, the crate and the floor's planks stand north or west of him or level with him, never
-- between him and the camera (which looks from the south-east).
-- The crate: the tab counts from the game's own loot list (CC.craftContainers), which ZeD keeps hidden; a hidden page
-- takes a new container in only when he turns or steps (ISInventoryPage:update; OnContainerUpdate's refresh runs in
-- its prerender, which a hidden page never draws). So he turns to the crate and back to the camera, as a player
-- walking up to a crate would; whether the list held it before the turn is logged.
-- Each picture prints "ZEDQA bxrc SHOT <name> | what is in it" or "ZEDQA bxrc SKIP <name> | why".
-- What it puts back: the things given, his own things set aside (the slots' own types, and anything set aside for
-- the weight), the planks on the floor, the crate, the table, Carpentry as found, a bound station, the Crafting tab's
-- Show / Sort / category / search / Required fold / chosen ingredients / card / scroll, both windows to the place, size
-- and tab they had (ZeD's own restore, the steps "Go to saved position" takes), game speed, the pair as found.
-- grep "ZEDQA bxrc".
local S = HFR and HFR.init and HFR.init("bxrc")
if not S then return end
S.DIR = "bxr_"
local Q = S.Q
local CC, CT = ZeD.CraftingCore, ZeD.CraftingTab
S.MOLD, S.DRILL = "MakeWoodenBlacksmithAnvilMold", "DrillPlank"
S.PLANK, S.BIGBRANCH = "Base.Plank", "Base.LargeBranch"
-- a slot with alternatives, as the game's scripts write it (no per-type amounts): recipes he knows first (no Unknown
-- chip on the card), the framepack (4 sticks or branches, must be learned) after them
S.ALTS = { { "Make4Bowls", "Base.Bowl" }, { "MakeTentKit", "Base.TreeBranch2" }, { "AssembleSmallFramepack", "Base.TreeBranch2" } }
-- the squares round him that are never between him and the camera: north, west, level right, level left, behind
S.SLOTS = { { 0, -1 }, { -1, 0 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
S.FRONT = { { 0, 1 }, { 1, 0 }, { 1, 1 } }
S.TABLES = { "furniture_tables_high_01_16", "furniture_tables_high_01_0", "furniture_tables_high_01_8", "furniture_tables_high_01_24",
    "furniture_tables_high_01_32", "furniture_tables_high_01_40", "furniture_tables_low_01_0", "furniture_tables_low_01_8" }
S.aside, S.floorIts, S.crateIts, S.pic = {}, {}, {}, {}

if not (CC and CT) then
    Q.say("ERR ZeD's Crafting tab is not loaded")
    Q.start()
    return
end

-- ===================================================================== helpers
function S.skip(name, why) Q.notTaken(name, why); Q.say("SKIP " .. name .. " | " .. why) end
-- the main inventory's load (summed from the items, as gallery_unload.lua: the game's own figure lags a frame)
function S.load()
    if GAL_UNLOAD and GAL_UNLOAD.weight then return GAL_UNLOAD.weight() end
    local t = 0
    pcall(function()
        local items = S.p:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if S.p:isEquipped(it) then t = t + it:getEquippedWeight() else t = t + it:getUnequippedWeight() end
        end
    end)
    return t
end
function S.maxLoad()
    local max = 20
    pcall(function() max = S.p:getMaxWeight() end)
    return max
end
-- the gallery rule: no picture over the weight limit (the header would show it)
function S.shotOk(name, what)
    local l, max = S.load(), S.maxLoad()
    if l > max then S.skip(name, string.format("over the weight limit (%.1f of %s kg): the header would show it", l, tostring(max))); return end
    S.shot(name)
    Q.say("SHOT " .. name .. " | " .. what)
end
-- time, not frames: cond asked every 100 ms (a UI update), at most ms; fn(true) when cond came true
function S.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 400000, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if st.last and now - st.last < 100 then return false end
        st.last = now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
function S.cst() local w = S.WW(); return w and w._craftState end
function S.data() local w = S.WW(); return w and w._craftCache end
function S.row(name) local d = S.data(); return d and d.byName and d.byName[name] or nil end
function S.zoneOf(kind, pred)
    local st = S.cst()
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == kind and z.w > 0 and z.h > 0 and (pred == nil or pred(z)) then return z end
    end
    return nil
end
function S.press(z)
    if not z then return false end
    local ok, err = pcall(CT.onClick, S.WW(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    if not ok then Q.say("ERR click: " .. tostring(err)) end
    return ok
end
function S.craftTab()
    if S.worldTab("craft") then return true end
    return pcall(S.WWm.openTab, S.pn, "craft") and true or false
end
function S.tabShowing()
    local s = false
    pcall(function() s = S.WWm.isTabShowing("craft", S.pn) end)
    return s and true or false
end
-- the list scrolled so the recipe's row is in the middle of its view (the rows are stamped out of view too)
function S.rowIntoView(name)
    local st = S.cst()
    local g = st and st._listGeo
    local z = S.zoneOf("recipeRow", function(zz) return zz.id == name end)
    if not (g and z and st.scroll and st.scroll.setScrollPos) then return false end
    local span = (g.totalH or 0) - (g.viewH or 0)
    if span <= 0 then return true end
    local off = math.floor((st.scroll.scrollPos or 0) * span)
    local want = (z.y - g.viewY + off) - math.floor((g.viewH - z.h) / 2)
    if want < 0 then want = 0 end
    if want > span then want = span end
    st.scroll:setScrollPos(want / span)
    return true
end
-- a recipe's card opened as a click on its row does (from code when the row is out of view)
function S.openCard(name)
    local st = S.cst()
    if not (st and S.row(name)) then return false end
    if st.altSlotName then pcall(CC.exitAltMode, st) end
    if st.selected ~= name then
        local z = S.zoneOf("recipeRow", function(zz) return zz.id == name end)
        local lg = st._listGeo
        if z and lg and z.y >= lg.viewY and z.y + z.h <= lg.viewY + lg.viewH then S.press(z) else pcall(CC.openCraft, st, name) end
    end
    return st.selected == name
end
function S.shutCard()
    local st = S.cst()
    if not st then return end
    pcall(function() if st.altSlotName then CC.exitAltMode(st) end end)
    pcall(function() if st.selected then CC.closeCraft(st) end end)
end
function S.cardUp(name)
    local st, rd = S.cst(), S.row(name)
    return st ~= nil and rd ~= nil and st.selected == name and rd.ingredients ~= nil
        and (st.splitTarget or 1) == 1 and (st.splitFrac or 1) >= 0.99
end
-- the card's row for the slot that takes the type
function S.ing(name, ft)
    local rd = S.row(name)
    for idx, ing in ipairs((rd and rd.ingredients) or {}) do
        if ing.validTypes and ing.validTypes[ft] and not ing.isTool then return ing, idx, rd end
    end
    return nil, nil, rd
end
function S.ready(rd) return (rd ~= nil and rd.status == "craftable" and rd.canStart == true) and true or false end
function S.readyWord(rd) return "list status " .. tostring(rd and rd.status) .. ", Craft lit " .. tostring(rd and rd.canStart == true) end
function S.reqLine(rd)
    local n = #((rd and rd.ingredients) or {})
    return "Required " .. tostring(n - ((rd and rd.missingCount) or 0)) .. "/" .. n
end
-- the lists asked again now (as a drop or a pick-up makes them): the World window's strip, the card's counts
function S.recount()
    local w = S.WW()
    if not w then return end
    w._containersDirty = true
    w._craftContainerAt = nil
    w._craftLogicAt = nil
end
-- everything carried, bags in bags too
function S.walk(inv, out, depth)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        out[#out + 1] = it
        if depth < 4 and instanceof(it, "InventoryContainer") then
            local sub = nil
            pcall(function() sub = it:getInventory() end)
            if sub then S.walk(sub, out, depth + 1) end
        end
    end
end
function S.isMade(it)
    for _, m in ipairs(S.made) do if m == it then return true end end
    return false
end
function S.loose(it)
    local free = false
    pcall(function()
        free = it:getAttachedSlot() == -1 and not it:isEquipped() and not S.p:isEquipped(it) and not S.p:isEquippedClothing(it)
            and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
    end)
    return free
end
function S.setAside(it)
    local c = nil
    pcall(function() c = it:getContainer() end)
    if not c then return false end
    if not pcall(function() c:Remove(it) end) then return false end
    S.aside[#S.aside + 1] = { it = it, c = c }
    return true
end
-- his own things of the counted slots' types, set aside so the numbers in the pictures are the staged ones
function S.asideTypes(set)
    local all, n = {}, 0
    pcall(S.walk, S.p:getInventory(), all, 0)
    for _, it in ipairs(all) do
        local ft = nil
        pcall(function() ft = it:getFullType() end)
        if ft and set[ft] and not S.isMade(it) and S.loose(it) and S.setAside(it) then n = n + 1 end
    end
    return n
end
function S.asideBack()
    local lost = 0
    for _, e in ipairs(S.aside) do
        pcall(function() if e.it:getContainer() == nil then e.c:AddItem(e.it) end end)
        local back = false
        pcall(function() back = e.it:getContainer() ~= nil end)
        if not back then lost = lost + 1 end
    end
    S.aside = {}
    return lost
end
-- the gallery rule: never over the weight limit. His own loose things go aside (heaviest first) until the load is
-- a kilo under it; they come back in the put-back.
function S.lighten()
    local max = S.maxLoad()
    local n = 0
    for _ = 1, 40 do
        if S.load() <= max - 1 then break end
        local best, bw = nil, 0
        local items = S.p:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local w = 0
            pcall(function() w = it:getUnequippedWeight() end)
            if w > bw and not S.isMade(it) and S.loose(it) and not instanceof(it, "InventoryContainer") then best, bw = it, w end
        end
        if not (best and S.setAside(best)) then break end
        n = n + 1
    end
    Q.say(string.format("load %.1f of %s kg%s", S.load(), tostring(max), (n > 0) and (" (" .. n .. " of his own things set aside for the weight)") or ""))
    return S.load() <= max
end
-- the squares
function S.sqAt(x, y) return getCell():getGridSquare(x, y, 0) end
function S.goodSq(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree() and sq:isOutside()
            and sq:getObjects():size() <= 3 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
            and sq:getMovingObjects():size() == 0
    end)
    return good and sq or nil
end
-- a square to stand on: in the open, its three camera-side neighbours bare, and at least three of the slots free
-- and in reach; the nearest such to (cx, cy), the more south-east the better
function S.findSpot(cx, cy)
    local best, bs = nil, -1e9
    for dy = -7, 7 do
        for dx = -7, 7 do
            local x, y = cx + dx, cy + dy
            local c = S.goodSq(S.sqAt(x, y))
            local inRoom = false
            pcall(function() inRoom = STORY.inRoom(x, y) and true or false end)
            if c and not inRoom then
                local front = true
                for _, o in ipairs(S.FRONT) do if not S.goodSq(S.sqAt(x + o[1], y + o[2])) then front = false end end
                local slots = {}
                for _, o in ipairs(S.SLOTS) do
                    local sq = S.goodSq(S.sqAt(x + o[1], y + o[2]))
                    local reach = false
                    if sq then pcall(function() reach = c:canReachTo(sq) and true or false end) end
                    if sq and reach then slots[#slots + 1] = sq end
                end
                if front and #slots >= 3 then
                    local sc = (dx + dy) * 0.5 - (math.abs(dx) + math.abs(dy)) * 3
                    if sc > bs then best, bs = { x = x, y = y, slots = slots }, sc end
                end
            end
        end
    end
    return best
end
-- the way from him to a square beside him (never south-east: no slot is there)
function S.dirTo(sq)
    local d = ""
    pcall(function()
        local dx, dy = sq:getX() - math.floor(S.p:getX()), sq:getY() - math.floor(S.p:getY())
        d = ((dy < 0) and "N" or ((dy > 0) and "S" or "")) .. ((dx > 0) and "E" or ((dx < 0) and "W" or ""))
    end)
    if d == "" or d == "SE" then d = "N" end
    return IsoDirections[d]
end
function S.facing(name)
    local is = false
    pcall(function() is = S.p:getDir() == IsoDirections[name] end)
    return is
end
function S.removeObj(obj)
    local sq = nil
    pcall(function() sq = obj:getSquare() end)
    if not sq then return end
    pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
    pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
end
-- a table the game itself takes as a crafting surface
function S.setTable(sq)
    for _, name in ipairs(S.TABLES) do
        if not S.tableObj then
            local o = nil
            pcall(function() o = IsoObject.new(getCell(), sq, name); sq:AddTileObject(o) end)
            local takes = false
            if o then pcall(function() takes = S.p:canUseAsGenericCraftingSurface(o) and true or false end) end
            if o and takes then S.tableObj, S.tableSprite = o, name elseif o then S.removeObj(o) end
        end
    end
    return S.tableObj ~= nil
end
function S.surface()
    local surf = nil
    pcall(function() surf = ISEntityUI.FindCraftSurface(S.p, 2) end)
    return surf
end
function S.setCrate(sq)
    pcall(function()
        local o = IsoObject.new(getCell(), sq, "carpentry_01_16")
        o:createContainersFromSpriteProperties()
        sq:AddTileObject(o)
        S.crateObj, S.crate = o, o:getContainer()
    end)
    if S.crateObj and not S.crate then S.removeObj(S.crateObj); S.crateObj = nil end
    if S.crate then pcall(function() S.crate:setExplored(true) end) end
    return S.crate ~= nil
end
function S.dropOn(sq, ft, ox, oy)
    local it = nil
    pcall(function() it = sq:AddWorldInventoryItem(ft, ox, oy, 0.0) end)
    if it then S.floorIts[#S.floorIts + 1] = it end
    return it
end
function S.floorBack()
    for _, it in ipairs(S.floorIts) do
        pcall(function()
            local wo = it:getWorldItem()
            if wo then
                local sq = wo:getSquare()
                if sq then sq:transmitRemoveItemFromSquare(wo) end
                pcall(function() wo:removeFromWorld() end)
                pcall(function() wo:removeFromSquare() end)
            end
        end)
        -- (one picked up by a stray action: out of whatever holds it)
        pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    end
    S.floorIts = {}
end
function S.crateBack()
    for _, it in ipairs(S.crateIts) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    S.crateIts = {}
    if S.crateObj then S.removeObj(S.crateObj) end
    S.crateObj, S.crate = nil, nil
end
-- whether the list the Crafting tab counts from holds the container
function S.listHolds(c)
    local has = false
    pcall(function()
        local l = CC.craftContainers(S.p)
        for i = 0, l:size() - 1 do if l:get(i) == c then has = true end end
    end)
    return has
end
function S.woodwork(n)
    pcall(function() S.p:setPerkLevelDebug(Perks.Woodwork, n) end)
    local w = S.WW()
    if w then w._craftCache = nil end   -- (the rows are gathered again with the new level)
    local st = S.cst()
    if st then st.filterDirty = true end
end
-- a recipe that takes 3 or more planks in a slot of its own (the named one first)
function S.findPlankRecipe()
    local function fits(rd)
        for _, inp in ipairs((rd and rd.entry and rd.entry.inputDefs) or {}) do
            if inp.validTypes and inp.validTypes[S.PLANK] and not inp.isTool and not inp.isKeep and (inp.amount or 1) >= 3 and (inp.amount or 1) <= 8 then return inp.amount end
        end
        return nil
    end
    local a = fits(S.row(S.MOLD))
    if a then return S.MOLD, a end
    local d = S.data()
    for _, rd in ipairs((d and d.recipes) or {}) do
        local n = fits(rd)
        if n and not rd.entry.stationInfo and not rd.entry.needLearn then return rd.entry.name, n end
    end
    return nil, nil
end
-- the type to give for a slot with alternatives that takes 2 to 8 whole items (want: that type only), and the amount
function S.altFits(rd, want)
    for _, inp in ipairs((rd and rd.entry and rd.entry.inputDefs) or {}) do
        local amt = inp.amount or 1
        if (inp.altCount or 0) > 0 and inp.validTypes and not inp.isTool and not inp.isKeep and amt >= 2 and amt <= 8
            and (want == nil or inp.validTypes[want]) then
            local ft = want
            if not ft then
                local names = {}
                for k in pairs(inp.validTypes) do names[#names + 1] = k end
                table.sort(names)
                ft = names[1]
            end
            return ft, amt
        end
    end
    return nil, nil
end
-- the recipe, the type given and the slot's amount: the named ones first (their slots read in the game's scripts: one
-- amount for every type), a recipe he knows before one he does not; then any other in Hand mode the same way (last:
-- a slot whose types take different amounts, "1:Base.BurlapPiece", would read wrong for one of them)
function S.findAltSlot()
    for pass = 1, 2 do
        for _, c in ipairs(S.ALTS) do
            local rd = S.row(c[1])
            if rd and (pass == 2 or rd.status ~= "locked") then
                local ft, amt = S.altFits(rd, c[2])
                if ft then return c[1], ft, amt end
            end
        end
    end
    local d = S.data()
    for pass = 1, 2 do
        for _, rd in ipairs((d and d.recipes) or {}) do
            if not rd.entry.stationInfo and (pass == 2 or rd.status ~= "locked") then
                local ft, amt = S.altFits(rd, nil)
                if ft then return rd.entry.name, ft, amt end
            end
        end
    end
    return nil, nil, nil
end
-- a window back to the place, size and tab it had: ZeD's own restore (applyState, the one a fresh open uses), after
-- the steps "Go to saved position" takes first (ZeD_WindowPlaces.lua goPair); k "char" or "world"
function S.placeBack(win, k, rec, CW)
    if not (win and rec and CW and CW.applyState) then return false end
    local ok, err = pcall(function()
        local T = ZeD.T
        if win._rolled and ZeD.Curtain and ZeD.Curtain.finishUnroll then ZeD.Curtain.finishUnroll(win) end
        if win._halves and ZeD.Halves and ZeD.Halves.forgetFold then ZeD.Halves.forgetFold(win) end
        if win.windowShaded then win:setWindowShaded(false) end
        if CW.closeColumns then CW.closeColumns(win) end
        win.minimumWidth = T.minWinW or 0
        win._maxWinW = math.floor(ZeD.screenOf(win) * 0.5)
        win._drawerCapPush, win._drawerCapLost, win._preDrawerW = 0, 0, nil
        win._drawerOpen, win._drawerEffW, win._prevEffW, win._drawerMode = false, 0, 0, nil
        win._invDrawerOpen = true
        local cs = {}
        for f, v in pairs(rec) do cs[f] = v end
        CW.applyState(win, cs)
        if k == "world" then win._anchorRightEdge = win:getX() + win:getWidth() end
        win._lastSetX = win:getX()
        if CW.syncRing then CW.syncRing(win) end
        -- (resetLayout dropped a window accent of its own and set the option to the default: both follow it back)
        if rec.accentKey ~= nil and ZeD.Settings and ZeD.Settings.syncWindowAccent then ZeD.Settings.syncWindowAccent(win) end
    end)
    if not ok then Q.say("ERR " .. k .. " window back: " .. tostring(err)) end
    return ok
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    pcall(function() S.was.wood = S.p:getPerkLevel(Perks.Woodwork) end)
    local c = S.P.smoke or { math.floor(S.p:getX()), math.floor(S.p:getY()) }
    S.spot = S.findSpot(c[1], c[2])
    if not S.spot then
        S.why = "no open square with room for the table, the crate and the planks near " .. c[1] .. "," .. c[2]
        Q.say("ERR " .. S.why .. ": no picture can be staged")
        return
    end
    G1.tp({ S.spot.x, S.spot.y }, "SE")
    Q.say(string.format("standing at %d,%d (the smoking spot %d,%d), %d free squares beside him", S.spot.x, S.spot.y, c[1], c[2], #S.spot.slots))
end)
Q.zoomTo(1.0)
Q.step(10, function()
    if not S.spot then return end
    G1.tp({ S.spot.x, S.spot.y }, "SE")
    S.setTable(S.spot.slots[1])
    S.surf = S.surface()
    Q.say("table " .. tostring(S.tableSprite) .. " set beside him; the game finds a crafting surface: " .. tostring(S.surf ~= nil))
    S.openPair()
end)
Q.step(40, function()
    if not S.spot then return end
    -- the windows at their default places for every picture; the place, size and tab each had are kept for the
    -- put-back (stateOf: what the save keeps and a fresh open restores)
    S.was.place = {}
    for k, pair in pairs({ char = { S.CW(), S.CWm }, world = { S.WW(), S.WWm } }) do
        local w, mod = pair[1], pair[2]
        if w and mod.stateOf then
            local ok, rec = pcall(mod.stateOf, w)
            if ok and rec then
                S.was.place[k] = rec
                Q.say(string.format("%s window was at %s,%s, %sx%s units, tab %s", k, tostring(rec.x), tostring(rec.y), tostring(rec.w), tostring(rec.h), tostring(rec.activeTab)))
            end
        end
    end
    local ww = S.WW()
    S.was.tab = ww and ww._activeTab
    pcall(function() ZeD_Window.resetLayout() end)
end)
Q.step(20, function()
    if not S.spot then return end
    S.charTab("loot")
    S.tabAsk = S.craftTab()
end)
S.wait(10000, function()
    if not S.spot then return true end
    local st = S.cst()
    return S.tabShowing() and st ~= nil and S.data() ~= nil and st.filteredCache ~= nil
end, function(ok)
    if not S.spot then return end
    local st = S.cst()
    S.ok = (ok and st ~= nil) and true or false
    Q.say("the Crafting tab is open with its list: " .. tostring(S.ok))
    if not S.ok then return end
    S.was.craft = { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat, req = st.reqCollapsed, owned = st.ownedOnly,
        search = st.search or "", sel = st.selected, picks = st.picks, scroll = (st.scroll and st.scroll.scrollPos) or 0 }
    -- Show: All (a recipe short of planks is on the list), sorted as a new save sorts it, no search (a search that
    -- leaves the card's recipe out closes the card), Required unfolded, no pop-up open
    pcall(CC.setShow, st, "all")
    st.sort, st.activeCat, st.search, st.filterDirty, st.reqCollapsed, st.ownedOnly = "craftable", "all", "", true, false, false
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
    pcall(function()
        local cur = ZeD.Stations and ZeD.Stations.current(S.p)
        if cur then S.was.station = cur; ZeD.Stations.unbind(S.p); Q.say("a station was bound: unbound for the pictures, bound again at the end") end
    end)
    local set = {}
    for _, ft in ipairs({ S.PLANK, S.BIGBRANCH, "Base.Log", "Base.TreeBranch2", "Base.WoodenStick2", "Base.Nails", "Base.Bowl", "Base.ClayBowl" }) do set[ft] = true end
    Q.say("his own planks, logs, branches, sticks, nails and bowls set aside: " .. S.asideTypes(set))
end)
S.wait(6000, function() return not S.ok or (S.cst().filterDirty == false and #(S.cst().filteredCache or {}) > 20) end, function()
    if not S.ok then return end
    S.pic.mold, S.pic.moldNeed = S.findPlankRecipe()
    S.pic.pack, S.pic.packType, S.pic.packNeed = S.findAltSlot()
    local prd = S.row(S.pic.pack or "")
    Q.say("recipes: planks " .. tostring(S.pic.mold) .. " (" .. tostring(S.pic.moldNeed) .. "), alternatives " .. tostring(S.pic.pack)
        .. " (" .. tostring(S.pic.packNeed) .. " of " .. tostring(S.pic.packType) .. ", " .. tostring(prd and prd.status) .. "), any-surface "
        .. S.DRILL .. " " .. tostring(S.row(S.DRILL) ~= nil))
    -- Carpentry at the level the plank recipe asks (the story's mechanic has none), so the card is not a locked one
    local rd = S.row(S.pic.mold or "")
    local need = 0
    for _, sd in ipairs((rd and rd.entry and rd.entry.skillDefs) or {}) do
        if CC.getPerkType(sd.name) == Perks.Woodwork then need = sd.required or 0 end
    end
    if need > (S.was.wood or 0) then
        S.woodSet = true
        S.woodwork(need)
        Q.say("Carpentry " .. tostring(S.was.wood) .. " -> " .. need .. " for the pictures (put back at the end)")
    end
end)

-- ===================================================================== W24: the plank row, 1 of 4
Q.step(10, function()
    if not (S.ok and S.pic.mold) then return end
    S.add("Base.Hammer"); S.add("Base.Saw"); S.add("Base.Nails")
    S.add(S.PLANK)
    S.lighten()
    S.recount()
end)
S.wait(8000, function() return not (S.ok and S.pic.mold) or S.row(S.pic.mold) ~= nil end, function()
    if not (S.ok and S.pic.mold) then return end
    S.rowIntoView(S.pic.mold)
end)
Q.step(10, function()
    if not (S.ok and S.pic.mold) then return end
    S.pic.moldOpen = S.openCard(S.pic.mold)
end)
S.wait(10000, function()
    if not (S.ok and S.pic.moldOpen) then return true end
    local ing = S.ing(S.pic.mold, S.PLANK)
    return S.cardUp(S.pic.mold) and ing ~= nil and ing.have == 1
end, function()
    if S.ok then S.rowIntoView(S.pic.mold or ""); S.clearChar() end
end)
Q.still(2, function()
    local name = "W24_planks_1_of_4"
    if not S.ok then S.skip(name, S.why or "the Crafting tab did not open"); return end
    if not S.pic.moldOpen then S.skip(name, "no recipe that takes 3 or more planks is on the list, or its card did not open (" .. tostring(S.pic.mold) .. ")"); return end
    local ing, _, rd = S.ing(S.pic.mold, S.PLANK)
    if not (S.cardUp(S.pic.mold) and ing and ing.have == 1) then S.skip(name, "the card's plank row does not read 1 carried (" .. tostring(ing and ing.have) .. "/" .. tostring(ing and ing.need) .. ")"); return end
    if ing.need < 3 then S.skip(name, "the plank row reads " .. ing.have .. "/" .. ing.need .. ": the recipe's real amount (" .. tostring(S.pic.moldNeed) .. ") is not on the card"); return end
    S.shotOk(name, "Crafting tab, " .. tostring(rd.entry.displayName) .. ": 1 plank carried, the card's plank row reads " .. ing.have .. "/" .. ing.need
        .. " and is drawn as missing; " .. S.reqLine(rd) .. "; " .. S.readyWord(rd))
end)

-- ===================================================================== B6-16: the alternatives list, 1 of 4
Q.step(10, function()
    if not S.ok then return end
    S.shutCard()
    S.takeMade()
    if not S.pic.pack then return end
    S.pic.stick = S.add(S.pic.packType)
    S.lighten()
    S.recount()
    S.rowIntoView(S.pic.pack)
end)
Q.step(20, function()
    if not (S.ok and S.pic.pack and S.pic.stick) then return end
    S.pic.packOpen = S.openCard(S.pic.pack)
end)
S.wait(10000, function()
    if not (S.ok and S.pic.packOpen) then return true end
    local ing, idx = S.ing(S.pic.pack, S.pic.packType)
    return S.cardUp(S.pic.pack) and ing ~= nil and ing.have == 1 and S.zoneOf("slotAlt", function(z) return z.idx == idx end) ~= nil
end, function(ok)
    if not (S.ok and S.pic.packOpen and ok) then return end
    local _, idx = S.ing(S.pic.pack, S.pic.packType)
    S.pic.packIdx = idx
    S.press(S.zoneOf("slotAlt", function(z) return z.idx == idx end))
end)
S.wait(6000, function()
    if not (S.ok and S.pic.packIdx) then return true end
    local st = S.cst()
    return st.altItems ~= nil and st.altSlotIdx == S.pic.packIdx and S.zoneOf("altPick", function(z) return z.id == S.pic.packType end) ~= nil
end, function()
    if S.ok then S.clearChar() end
end)
Q.still(2, function()
    local name = "B6-16_alternatives_1_of_4"
    if not S.ok then S.skip(name, S.why or "the Crafting tab did not open"); return end
    if not (S.pic.pack and S.pic.stick) then S.skip(name, "no slot with alternatives that takes 2 or more items is on the list, or its thing could not be given (" .. tostring(S.pic.pack) .. ", " .. tostring(S.pic.packType) .. ")"); return end
    local st = S.cst()
    local alts = st.altItems
    if not (S.pic.packIdx and alts and st.altSlotIdx == S.pic.packIdx) then S.skip(name, "the slot's alternatives list did not open"); return end
    local n, bad, mine, none = 0, 0, nil, 0
    for _, grp in ipairs({ alts.owned or {}, alts.other or {} }) do
        for _, a in ipairs(grp) do
            n = n + 1
            if a.need ~= S.pic.packNeed then bad = bad + 1 end
            if a.have == 0 then none = none + 1 end
            if a.fullType == S.pic.packType then mine = a end
        end
    end
    if bad > 0 or not mine or mine.have ~= 1 then
        S.skip(name, "the list does not read the slot's amount: " .. bad .. " of " .. n .. " types with another need, the carried one " .. tostring(mine and mine.have) .. "/" .. tostring(mine and mine.need))
        return
    end
    local rd = S.row(S.pic.pack)
    S.shotOk(name, "Crafting tab, " .. tostring(rd.entry.displayName) .. " (" .. tostring(rd.status) .. "), a slot that takes " .. S.pic.packNeed .. ": its alternatives list open, 1 "
        .. tostring(mine.displayName) .. " carried reads " .. mine.have .. "/" .. mine.need .. ", " .. none .. " types not carried read 0/" .. S.pic.packNeed .. " (" .. n .. " types in all; was N/1)")
end)

-- ===================================================================== B6-14: an any-surface recipe beside a table
Q.step(10, function()
    if not S.ok then return end
    S.shutCard()
    S.takeMade()
    S.surf = S.surf or S.surface()   -- (asked again: the first ask came the frame he was set down)
    S.pic.drill = S.row(S.DRILL) ~= nil and S.surf ~= nil
    if not S.pic.drill then return end
    S.pic.screw = S.add("Base.Screwdriver")
    S.pic.plank = S.add(S.PLANK)
    S.lighten()
    S.recount()
    S.rowIntoView(S.DRILL)
end)
Q.step(20, function()
    if not (S.ok and S.pic.drill) then return end
    S.pic.drillOpen = S.openCard(S.DRILL)
end)
-- (the list asks the game again every 1.2 s; the row is given 12 s to turn, as a player by the table would see it)
S.wait(12000, function()
    if not (S.ok and S.pic.drillOpen) then return true end
    return S.cardUp(S.DRILL) and S.ready(S.row(S.DRILL)) and S.zoneOf("action_build") ~= nil
end, function()
    if S.ok then S.rowIntoView(S.DRILL); S.clearChar() end
end)
Q.still(2, function()
    local name = "B6-14_any_surface_ready"
    if not S.ok then S.skip(name, S.why or "the Crafting tab did not open"); return end
    if not S.pic.drill then S.skip(name, "Drill Plank on the list " .. tostring(S.row(S.DRILL) ~= nil) .. ", a table the game takes as a surface beside him " .. tostring(S.surf ~= nil)); return end
    local rd = S.row(S.DRILL)
    if not (S.pic.drillOpen and S.cardUp(S.DRILL)) then S.skip(name, "Drill Plank's card did not open"); return end
    if not S.ready(rd) then S.skip(name, "beside the table with a plank and a screwdriver carried, Drill Plank does not read ready: " .. S.readyWord(rd)); return end
    S.shotOk(name, "Crafting tab, Drill Plank (an any-surface recipe), a table beside him, a plank and a screwdriver carried: " .. S.readyWord(rd)
        .. "; " .. S.reqLine(rd) .. " (was Missing, Craft dimmed, \"Needs a workbench or station nearby\")")
end)

-- ===================================================================== W23 / B6-15: an ingredient chosen by hand
Q.step(10, function()
    if not (S.ok and S.pic.drillOpen) then return end
    S.pic.branch = S.add(S.BIGBRANCH)
    S.lighten()
    S.recount()
end)
S.wait(10000, function()
    if not (S.ok and S.pic.drillOpen and S.pic.branch) then return true end
    local ing, idx = S.ing(S.DRILL, S.PLANK)
    return S.cardUp(S.DRILL) and ing ~= nil and ing.have >= 2 and S.zoneOf("slotAlt", function(z) return z.idx == idx end) ~= nil
end, function(ok)
    if not (S.ok and S.pic.drillOpen and S.pic.branch and ok) then return end
    local _, idx = S.ing(S.DRILL, S.PLANK)
    S.pic.drillIdx = idx
    S.press(S.zoneOf("slotAlt", function(z) return z.idx == idx end))
end)
S.wait(6000, function()
    if not (S.ok and S.pic.drillIdx) then return true end
    return S.cst().altItems ~= nil and S.zoneOf("altPick", function(z) return z.id == S.BIGBRANCH end) ~= nil
end, function(ok)
    if not (S.ok and S.pic.drillIdx and ok) then return end
    S.press(S.zoneOf("altPick", function(z) return z.id == S.BIGBRANCH end))
    pcall(function() S.pic.chosen = CC.pickFor(S.cst(), S.DRILL, S.pic.drillIdx) end)
    Q.say("the large branch chosen in the alternatives list: " .. tostring(S.pic.chosen))
    S.clearChar()
end)
Q.still(2, function()
    local name = "W23_chosen_in_list"
    if not S.ok then S.skip(name, S.why or "the Crafting tab did not open"); return end
    if not (S.pic.drillOpen and S.pic.branch) then S.skip(name, "Drill Plank's card is not open, or no large branch could be given"); return end
    local st = S.cst()
    if not (S.pic.chosen == S.BIGBRANCH and st.altItems and st.selected == S.DRILL) then S.skip(name, "the large branch could not be chosen in the plank slot's alternatives (chosen " .. tostring(S.pic.chosen) .. ")"); return end
    local ing = S.ing(S.DRILL, S.PLANK)
    S.shotOk(name, "Crafting tab, Drill Plank, a plank and a large branch carried: the plank slot's alternatives list open, " .. CC.typeName(S.BIGBRANCH)
        .. " picked by hand (its row washed), the card's row reads \"" .. tostring(ing and ing.name) .. ": " .. CC.typeName(S.BIGBRANCH) .. "\"")
end)
-- the list shut by its Back button: the card alone, the choice still named on its row
Q.step(10, function()
    if not (S.ok and S.pic.chosen == S.BIGBRANCH) then return end
    local z = S.zoneOf("altStrip_back")
    if z then S.press(z) end
    local st = S.cst()
    if st.altSlotName then pcall(CC.exitAltMode, st) end
end)
S.wait(8000, function()
    if not (S.ok and S.pic.chosen == S.BIGBRANCH) then return true end
    local st = S.cst()
    return st.altSlotName == nil and S.cardUp(S.DRILL) and S.zoneOf("action_build") ~= nil
end, function()
    if S.ok then S.rowIntoView(S.DRILL); S.clearChar() end
end)
Q.still(2, function()
    local name = "W23_chosen_on_card"
    if not S.ok then S.skip(name, S.why or "the Crafting tab did not open"); return end
    local st = S.cst()
    local chosen = nil
    pcall(function() chosen = CC.pickFor(st, S.DRILL, S.pic.drillIdx) end)
    if not (S.pic.chosen == S.BIGBRANCH and chosen == S.BIGBRANCH and S.cardUp(S.DRILL) and st.altSlotName == nil) then
        S.skip(name, "no chosen ingredient is held on Drill Plank's card (chosen " .. tostring(chosen) .. ")")
        return
    end
    local ing, _, rd = S.ing(S.DRILL, S.PLANK)
    S.shotOk(name, "Crafting tab, Drill Plank's card before Craft: the row reads \"" .. tostring(ing and ing.name) .. ": " .. CC.typeName(S.BIGBRANCH)
        .. "\" (the ingredient picked by hand), " .. tostring(ing and ing.have) .. "/" .. tostring(ing and ing.need) .. "; " .. S.readyWord(rd) .. "; Craft not pressed")
end)

-- ===================================================================== W25: the floor and a crate in reach count
Q.step(10, function()
    if not S.ok then return end
    S.shutCard()
    S.takeMade()
    if not S.pic.mold then return end
    S.add("Base.Hammer"); S.add("Base.Saw"); S.add("Base.Nails")
    S.lighten()
    local sq = S.spot.slots[2]
    S.pic.f1 = S.dropOn(sq, S.PLANK, 0.35, 0.45)
    S.pic.f2 = S.dropOn(sq, S.PLANK, 0.65, 0.6)
    Q.say("2 planks put on the floor at " .. sq:getX() .. "," .. sq:getY() .. " (beside him): " .. tostring(S.pic.f1 ~= nil and S.pic.f2 ~= nil))
    S.recount()
    S.rowIntoView(S.pic.mold)
end)
Q.step(20, function()
    if not (S.ok and S.pic.mold and S.pic.f1 and S.pic.f2) then return end
    S.pic.floorOpen = S.openCard(S.pic.mold)
end)
S.wait(12000, function()
    if not (S.ok and S.pic.floorOpen) then return true end
    local ing = S.ing(S.pic.mold, S.PLANK)
    return S.cardUp(S.pic.mold) and ing ~= nil and ing.have == 2
end, function()
    if S.ok then S.rowIntoView(S.pic.mold or ""); S.clearChar() end
end)
Q.still(2, function()
    local name = "W25_floor_2_of_4"
    if not S.ok then S.skip(name, S.why or "the Crafting tab did not open"); return end
    if not S.pic.floorOpen then S.skip(name, "the plank recipe's card did not open, or the planks could not be put on the floor"); return end
    local ing, _, rd = S.ing(S.pic.mold, S.PLANK)
    if not (S.cardUp(S.pic.mold) and ing and ing.have == 2) then
        S.skip(name, "no plank carried and 2 on the floor beside him, the card's plank row reads " .. tostring(ing and ing.have) .. "/" .. tostring(ing and ing.need) .. ": the floor is not counted")
        return
    end
    S.pic.floorCounted = true
    S.shotOk(name, "Crafting tab, " .. tostring(rd.entry.displayName) .. ": no plank carried (the Character window's list beside it), 2 planks on the floor beside him, the card's plank row reads "
        .. ing.have .. "/" .. ing.need .. " (was 0)")
end)
-- two more planks in a crate in reach
Q.step(10, function()
    if not (S.ok and S.pic.floorOpen) then return end
    local sq = S.spot.slots[3]
    if not S.setCrate(sq) then Q.say("the crate could not be set"); return end
    for _ = 1, 2 do
        local it = nil
        pcall(function() it = S.crate:AddItem(S.PLANK) end)
        if it then S.crateIts[#S.crateIts + 1] = it end
    end
    Q.say("a crate with " .. #S.crateIts .. " planks set at " .. sq:getX() .. "," .. sq:getY() .. " (in reach)")
    -- (what the game fires when a thing with a container is put into the world: ZeD's World window looks again)
    pcall(function() triggerEvent("OnContainerUpdate") end)
    S.recount()
end)
-- the game's own loot list with him standing still (logged), then turned to the crate if it is not in it yet
S.wait(1500, function() return not (S.ok and S.crate) or S.listHolds(S.crate) end, function(ok)
    if not (S.ok and S.crate) then return end
    S.pic.crateStill = ok
    Q.say("the game's loot list (what the tab counts from) holds the crate with him standing still: " .. tostring(ok))
    if not ok then pcall(function() S.p:setDir(S.dirTo(S.spot.slots[3])) end) end
end)
S.wait(3000, function() return not (S.ok and S.crate) or S.listHolds(S.crate) end, function(ok)
    if not (S.ok and S.crate) then return end
    if not S.pic.crateStill then Q.say("he turned to the crate: the list holds it " .. tostring(ok)) end
    pcall(function() S.p:setDir(IsoDirections.SE) end)
    S.recount()
end)
S.wait(12000, function()
    if not (S.ok and S.crate and #S.crateIts == 2) then return true end
    local ing = S.ing(S.pic.mold, S.PLANK)
    return S.cardUp(S.pic.mold) and ing ~= nil and ing.have == 4 and S.facing("SE")
end, function()
    if S.ok then S.clearChar() end
end)
Q.still(2, function()
    local name = "W25_floor_and_crate_4_of_4"
    if not S.ok then S.skip(name, S.why or "the Crafting tab did not open"); return end
    if not S.pic.floorOpen then S.skip(name, "the plank recipe's card did not open"); return end
    if not (S.crate and #S.crateIts == 2) then S.skip(name, "no crate with 2 planks could be set beside him"); return end
    local ing, _, rd = S.ing(S.pic.mold, S.PLANK)
    if not (S.cardUp(S.pic.mold) and ing and ing.have == 4) then
        S.skip(name, "2 planks on the floor and 2 in a crate in reach, the card's plank row reads " .. tostring(ing and ing.have) .. "/" .. tostring(ing and ing.need)
            .. "; the list the tab counts from holds the crate: " .. tostring(S.listHolds(S.crate)) .. " (false: the game's own loot list has not taken the crate in)")
        return
    end
    if not S.facing("SE") then S.skip(name, "he is not facing the camera again after turning to the crate"); return end
    S.shotOk(name, "Crafting tab, " .. tostring(rd.entry.displayName) .. ": no plank carried, 2 on the floor and 2 in the crate beside him, the card's plank row reads "
        .. ing.have .. "/" .. ing.need .. "; " .. S.reqLine(rd) .. "; " .. S.readyWord(rd)
        .. (S.pic.crateStill and "" or " (the crate counted once he had turned to it: the hidden loot list takes it in on a turn or a step)"))
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    S.shutCard()
    pcall(function()
        local st, k = S.cst(), S.was.craft
        if st and k then
            st.show, st.showAll, st.sort, st.activeCat = k.show, k.showAll, k.sort, k.cat
            st.reqCollapsed, st.ownedOnly, st.search, st.qty, st.filterDirty = k.req and true or false, k.owned and true or false, k.search or "", 1, true
            st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
            -- (the card that was open, with the ingredients chosen on it: openCraft starts a card with none)
            if k.sel then pcall(CC.openCraft, st, k.sel) end
            st.picks = k.picks or {}
            if st.scroll and st.scroll.setScrollPos then st.scroll:setScrollPos(k.scroll or 0) end
        end
    end)
    S.floorBack()
    S.crateBack()
    if S.tableObj then S.removeObj(S.tableObj) end
    S.takeMade()
    local lost = S.asideBack()
    if S.woodSet then S.woodwork(S.was.wood or 0) end
    pcall(function() if S.was.station then ZeD.Stations.bind(S.p, S.was.station) end end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
    S.recount()
    local stood = 0
    pcall(function() if S.tableObj and S.tableObj:getObjectIndex() >= 0 then stood = stood + 1 end end)
    S.tableObj = nil
    Q.say("put back: things given and the floor's planks taken away, the crate and the table removed (still standing " .. stood .. "), his own things set aside not back: "
        .. lost .. ", Carpentry " .. tostring(S.p:getPerkLevel(Perks.Woodwork)) .. " (found " .. tostring(S.was.wood) .. ")")
    G1.glassesBack(Q)
end)
Q.step(20, function()
    S.openPair()
    S.charTab("loot")
    local t = S.was.tab
    if not (t and t ~= "craft" and S.worldTab(t)) then S.worldTab("loot") end
end)
Q.step(30, function()
    -- the windows to the place, size and tab they had
    for _, k in ipairs({ "char", "world" }) do
        local rec = S.was.place and S.was.place[k]
        local mod = (k == "char") and S.CWm or S.WWm
        local w = (k == "char") and S.CW() or S.WW()
        if w and rec then Q.say(k .. " window back to its place, size and tab: " .. tostring(S.placeBack(w, k, rec, mod))) end
    end
    local hurt = false
    pcall(function() hurt = S.p:getBodyDamage():getOverallBodyHealth() < 99 end)
    if hurt then pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end) end
    if S.P.stock then G1.tp(S.P.stock, "SE") end
    S.back0()
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Q.say("put back: windows, tabs and game speed as found; alive " .. tostring(not S.p:isDead()))
end)
Q.start()
