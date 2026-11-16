-- ZeDUI/tools/qa/zedqa_b17_scroll.lua  (Nov 16 2026, QA): beta 17's pad scroll fixes in the running game, single
-- player (punch list 257, 258 and the in-game parts of 264; commit a9443a4d7). The sims (pad_scroll_sim.lua,
-- pad_reach_b17_sim.lua, pad_reach_fixes_sim.lua) prove the logic; this proves it on the real windows.
-- For the run: ZeD's Large text, both windows held to 45% of the screen's height, the pad's mode locked on.
--   257 faces: a TV, a radio and a ham two-way set placed beside the character (World window, Radio tab), the CD
--       player in the hand (Character window, Radio tab), an oven and a microwave (Craft tab), and the generator,
--       propane grill and washer object cards. On each: D-pad Down to the face's lowest control, then Up until the
--       next Up would leave the face: the face's scroll is back at 0 (the case and art whole). A face that fits
--       the short window is said (NOTE), not failed.
--   258 long views: a food item card (Character window), a Mechanics part card's About text (a car within 8 tiles,
--       else one spawned through the prelude) and the Furniture tab's Place list (14 chairs carried). Down at the
--       last stop scrolls the view with the focus kept (the steps printed; Furniture and Mechanics a step no more
--       than 60 units), the move leaves the view only once its end shows, Up scrolls it back to 0.
--   264: the Journal's delete question on a test entry lands on Cancel; Cancel puts the pad back on the entry's
--       cross; Delete lands on the next entry's cross. The Equip tab: Unequip, then Drop, from a worn test item's
--       card lands on the next filled slot, with no jump to the top.
-- Pictures: Screenshots/zqa_b17s_<face>_top.png (each face after the walk back up), zqa_b17s_journal_ask.png,
-- zqa_b17s_journal_after_delete.png, zqa_b17s_equip_card_<verb>.png, zqa_b17s_equip_after_<verb>.png,
-- zqa_b17s_<view>_foot.png. Put back: Large text, window heights, placed objects, items and the car, the test
-- entries, the hands, game speed, instant actions, cards closed, tabs on Loot, the pad handed back.
-- grep "ZEDQA b17s".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det = ZeD.Input and ZeD.Input.Focus, ZeD.Input and ZeD.Input.Detector
local T = ZeD.T
local function say(s) print("ZEDQA b17s " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b17s_" .. n .. ".png") end) end
local Q = {}
-- a step's fn returning true runs again after n frames
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
if not (Focus and Det and Focus.dispatchJoypadDir and Focus.previewMove and Focus.scrollView and T) then
    say("ERR the pad scroll is not loaded"); say("DONE"); return
end
local function CW() return ZeD_CharacterWindow.getWindow(pn) end
local function WW() return ZeD_WorldWindow.getWindow(pn) end
local function f2(v) return string.format("%.3f", tonumber(v) or -1) end
local SH = getCore():getScreenHeight()
-- what the run changes, kept to put back
local K = { placed = {}, added = {}, prim = p:getPrimaryHandItem(), sec = p:getSecondaryHandItem(), speed = getGameSpeed() }
local O = {}   -- the placed objects by name
-- the character back where the run found it (moved beside the car for Mechanics)
local function goHome()
    local h = K.home
    if not h then return end
    K.home = nil
    pcall(function() p:teleportTo(h.x, h.y, h.z) end)
    pcall(function() p:setX(h.x); p:setY(h.y); p:setZ(h.z); p:setLastX(h.x); p:setLastY(h.y); p:setLastZ(h.z) end)
end

local function fid(w) local e = w and Focus.getFocusedElement(w); return e and e.id end
local function fzone(w) local z = w and Focus.getFocusedZone(w); return z and z.zone end
-- focus the first stop pred(el, zoneName) takes, in any focusable zone of w
local function focusAny(w, pred)
    if not w then return nil end
    pcall(Focus.flatElements, w)   -- (the stops brought up to date)
    local names = {}
    for _, z in ipairs(w._focusRing or {}) do names[#names + 1] = z.zone end
    for _, n in ipairs(names) do
        local e = Focus.focusWhere(w, n, function(x) return pred(x, n) end)
        if e then return e end
    end
    return nil
end
local function sqAt(dx, dy) return getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ())) end
local function keep(obj) if obj then K.placed[#K.placed + 1] = obj end; return obj end
local function newItem(ft) local ok, it = pcall(function() return p:getInventory():AddItem(ft) end); if ok and it then K.added[#K.added + 1] = it; return it end; return nil end

-- ===================================================================== setup: Large text, the pad, short windows, the machines
step(5, function()
    local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
    local o = opts and opts:getOption("textSize")
    if o then
        pcall(function() K.size = o:getValue() end)
        if K.size ~= 2 then pcall(function() o:setValue(2); if o.onChangeApply then o:onChangeApply(2) else ZeD.Settings.reapplyFromOptions() end end) end
    end
    say("text size " .. tostring(K.size) .. " -> " .. tostring(ZeD.currentSize))
    if not ZeD_CharacterWindow.isOpen(pn) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    if K.speed == 0 then setGameSpeed(1) end   -- (Unequip, Drop and the car's removal need the game running)
    pcall(function() K.instant = p:isTimedActionInstantCheat(); p:setTimedActionInstantCheat(true) end)
    Det.setLockedMode(Det.MODE_GAMEPAD)
end)
step(60, function()
    local w, c = WW(), CW()
    if not (w and c) then say("ERR the windows are not open"); return end
    K.hW, K.hC = w:getHeight(), c:getHeight()
    local h = math.floor(SH * 0.45)
    w:setHeight(h); c:setHeight(h)
    -- the machines one square apart round the character (b16's and the face tests' ways); make(sq) builds one
    local function place(key, dx, dy, make)
        local sq = sqAt(dx, dy)
        local ok, obj = pcall(make, sq)
        if ok and obj then O[key] = keep(obj) else say("ERR placing the " .. key .. ": " .. tostring(obj)) end
    end
    local function special(o, sq)   -- (in the square's special list so the game counts it, zedqa_appliances.lua)
        pcall(function() o:createContainersFromSpriteProperties() end)
        sq:AddSpecialObject(o)
        if o:getObjectIndex() < 0 then sq:AddTileObject(o) end
        return o
    end
    local function tile(o, sq) sq:AddTileObject(o); return o end
    place("tv", 1, 0, function(sq) return tile(IsoTelevision.new(getCell(), sq, getSprite("appliances_television_01_1")), sq) end)
    place("radio", -1, 0, function(sq) return tile(IsoRadio.new(getCell(), sq, getSprite("appliances_radio_01_9")), sq) end)
    place("ham", 0, 1, function(sq)
        local d = instanceItem("Base.HamRadio1"):getDeviceData()
        d:setHasBattery(true); d:setPower(0.8); d:setIsTurnedOn(false)
        local o = IsoRadio.new(getCell(), sq, getSprite("appliances_com_01_0"))
        o:setDeviceData(d)
        return tile(o, sq)
    end)
    place("oven", 2, 0, function(sq) return special(IsoStove.new(getCell(), sq, getSprite("appliances_cooking_01_12")), sq) end)
    place("micro", -2, 0, function(sq) return special(IsoStove.new(getCell(), sq, getSprite("appliances_cooking_01_24")), sq) end)
    place("gen", 0, -2, function(sq)
        local g = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), sq)
        pcall(function() g:setFuel(60); g:setCondition(90) end)
        return g
    end)
    place("bbq", 2, 2, function(sq) return tile(IsoBarbecue.new(getCell(), sq, getSprite("appliances_cooking_01_37")), sq) end)
    place("washer", 1, 1, function(sq)   -- (a washer tile found by its IsoType, as zedqa_laundry.lua does)
        local name
        for i = 0, 47 do
            local spr = getSprite("appliances_laundry_01_" .. i)
            local pr = spr and spr:getProperties()
            if not name and pr and pr:has("IsoType") and pr:get("IsoType") == "IsoClothingWasher" then name = "appliances_laundry_01_" .. i end
        end
        local o = IsoClothingWasher.new(getCell(), sq, getSprite(name))
        pcall(function() o:createFluidContainersFromSpriteProperties() end)
        return special(o, sq)
    end)
    say("windows held to " .. h .. " px (World " .. w:getHeight() .. ", Character " .. c:getHeight() .. "); " .. #K.placed .. " machines placed")
end)

-- ===================================================================== 257: the faces scroll back to the very top
local function inFace(o, id) return id ~= nil and (o.pre == nil or string.sub(tostring(id), 1, #o.pre) == o.pre) end
local function faceWalk(tag, o)
    local W = { t = 0 }
    step(5, function()
        W.t = W.t + 1
        local ok, r = pcall(o.ready, W.t)
        if not (ok and r) then
            if W.t < 60 then return true end
            say("not run: " .. tag .. " (" .. (ok and "its face never showed" or ("ERR " .. tostring(r))) .. ")"); W.skip = true; return
        end
        -- the face's height, top stop to lowest control, read off its stops (window px, the scroll at 0)
        local w = o.win()
        local top, bot = nil, nil
        local ok2, flat = pcall(Focus.flatElements, w)
        for _, f in ipairs(ok2 and flat or {}) do
            if f.zone == o.zone and inFace(o, f.id) then
                if not top or f.y < top then top = f.y end
                if not bot or f.y + (f.h or 0) > bot then bot = f.y + (f.h or 0) end
            end
        end
        W.span = (top and bot) and (bot - top) or 0
        W.h0 = w:getHeight()
        say(tag .. ": face " .. math.floor(W.span) .. " px top stop to lowest control; window " .. W.h0 .. " px")
        W.n = 0
    end)
    -- (Nov 16 2026, the 4K run: at 45% of the screen every face fit) the window shrinks a step at a time until the
    -- face's view is under 0.6 of the face (read from its scrollbar's height), or the window stops getting shorter
    step(4, function()
        if W.skip or W.span <= 0 then return end
        local w = o.win()
        local sc = o.scroll()
        local viewH = (sc and sc.visible) and sc.height or nil
        local h = w:getHeight()
        W.n = W.n + 1
        if (not viewH or viewH > W.span * 0.6) and h > T.px(160) and W.n <= 40 and h ~= W.hLast then
            W.hLast = h
            w:setHeight(math.max(T.px(160), h - T.px(30)))
            return true
        end
        say(tag .. ": window " .. h .. " px, face view " .. tostring(viewH and math.floor(viewH)) .. " px for a "
            .. math.floor(W.span) .. " px face (" .. (W.n - 1) .. " steps)")
    end)
    step(4, function()
        if W.skip then return end
        local w = o.win()
        Focus.claimFocus(w)
        local e = focusAny(w, function(x, zn) return zn == o.zone and inFace(o, x.id) end)
        W.skip = (e == nil)
        check(e ~= nil, tag .. ": the face's controls are pad stops (" .. tostring(e and e.id) .. ")")
        W.n = 0
    end)
    -- Down to the lowest control
    step(4, function()
        if W.skip then return end
        local w = o.win()
        local r = Focus.previewMove(w, "down")
        W.n = W.n + 1
        if W.n <= 25 and r and r.zone == o.zone and inFace(o, r.id) and r.id ~= fid(w) then Focus.dispatchJoypadDir(w, "down"); return true end
        local sc = o.scroll()
        W.low = sc and sc.scrollPos or 0
        say(tag .. ": lowest control " .. tostring(fid(w)) .. " after " .. (W.n - 1) .. " Downs, scroll " .. f2(W.low))
        if not (sc and sc.visible) then say(tag .. ": NOTE the face fits the short window: nothing to scroll") end
        W.n = 0
    end)
    -- Up until the next Up would leave the face
    step(4, function()
        if W.skip then return end
        local w = o.win()
        local r = Focus.previewMove(w, "up")
        W.n = W.n + 1
        if W.n <= 25 and r and r.zone == o.zone and inFace(o, r.id) and r.id ~= fid(w) then Focus.dispatchJoypadDir(w, "up"); return true end
    end)
    step(6, function()
        if W.skip then if o.close then pcall(o.close) end; if W.h0 then o.win():setHeight(W.h0) end; return end
        local sc = o.scroll()
        local pos = sc and sc.scrollPos or 0
        if (W.low or 0) > 0.001 then
            check(pos <= 0.001, tag .. ": Up from the lowest control scrolls the face to the very top (" .. f2(W.low) .. " -> " .. f2(pos)
                .. ", on " .. tostring(fid(o.win())) .. " after " .. (W.n - 1) .. " Ups)")
        else
            say(tag .. ": NOTE the walk down never scrolled the face (scroll now " .. f2(pos) .. ")")
        end
        shot(tag .. "_top")
        if o.close then pcall(o.close) end
        if W.h0 then o.win():setHeight(W.h0) end
    end)
end
-- the World window's Radio tab on a placed set
local function radioFace(tag, key)
    faceWalk(tag, { win = WW, zone = "worldTabContent", pre = "radio:",
        scroll = function() return WW()._radioScroll end,
        ready = function()
            local w, obj = WW(), O[key]
            if not obj then return false end
            for i, r in ipairs(w._radios or {}) do if r.radioInstance == obj and w._radioIdx ~= i then w._radioIdx = i end end
            if w._activeTab ~= "radio" then ZeD_WorldWindow.openTab(pn, "radio") end
            return w._radioTw ~= nil and w._radioTw.dev == obj
        end })
end
radioFace("tv", "tv")
radioFace("radio", "radio")
radioFace("twoway_ham", "ham")
-- the CD player in the hand: the Character window's Radio tab
faceWalk("cd_player", { win = CW, zone = "charTabContent", pre = "radio:",
    scroll = function() return CW()._radioScroll end,
    ready = function(t)
        local w = CW()
        if t == 1 then
            O.cd = newItem("Base.CDplayer")
            pcall(function() local d = O.cd:getDeviceData(); d:setHasBattery(true); d:setPower(0.8) end)
            p:setPrimaryHandItem(O.cd)
        end
        if not O.cd then return false end
        local listed = false
        for _, r in ipairs(w._radios or {}) do if r.radioInstance == O.cd then listed = true end end
        if listed and w._activeTab ~= "radio" then ZeD_CharacterWindow.openTab(pn, "radio") end
        return w._radioTw ~= nil and w._radioTw.dev == O.cd
    end,
    close = function() p:setPrimaryHandItem(K.prim); ZeD_CharacterWindow.openTab(pn, "loot") end })
-- the Craft tab's oven and microwave (ZeD's station route, zedqa_appliances.lua)
local function stationFace(tag, key)
    faceWalk(tag, { win = WW, zone = "worldTabContent", pre = "craft:",
        scroll = function() local s = WW()._craftState; return s and s.scroll end,
        ready = function(t)
            local ST = ZeD.Stations
            if not (ST and O[key]) then return false end
            if t == 1 then ST.open(p, O[key]) end
            local st = ST.current(p)
            return st ~= nil and st.obj == O[key] and WW()._activeTab == "craft" and WW()._craftState ~= nil
        end,
        close = function() ZeD.Stations.unbind(p) end })
end
stationFace("oven", "oven")
stationFace("microwave", "micro")
-- the object cards, opened over Loot (zedqa_plates_336.lua's openCard)
local function cardFace(tag, kind, key)
    faceWalk(tag, { win = WW, zone = "worldItemCard",
        scroll = function() local c = WW()._objectCard; return c and c.scroll end,
        ready = function(t)
            local OC = ZeD.ObjectCards
            local def = OC and OC.kinds[kind]
            if not (def and O[key]) then return false end
            if t == 1 then ZeD_WorldWindow.openTab(pn, "loot"); return false end
            if t == 2 then
                local ok, list = pcall(def.nearby, p)
                for _, c in ipairs(ok and list or {}) do if c.obj == O[key] then ZeD_WorldWindow.openObjectCard(pn, { def = def, t = c }) end end
            end
            local c = WW()._objectCard
            return c ~= nil and c:isVisible() and c.entry ~= nil
        end,
        close = function() ZeD_WorldWindow.closeObjectCard(pn) end })
end
cardFace("generator", "generator", "gen")
cardFace("propane_grill", "fire", "bbq")
cardFace("laundry", "laundry", "washer")

-- ===================================================================== 258: Down at the last stop reads on, Up past the first goes to the top
-- R: win(), read() -> off, max; inView(el); stepMax (nil: a section may be a step, the item card)
-- the last press's effect: a scroll step (kept: the focus stayed), or nothing at all (stuck)
local function settle(R, off, id)
    if not R.pending then return false end
    R.pending = nil
    local d = off - R.before
    if d > 0.5 then
        R.deltas[#R.deltas + 1] = math.floor(d + 0.5)
        if id == R.beforeId then R.kept = R.kept + 1 end
    end
    return d <= 0.5 and id == R.beforeId
end
local function longWalk(tag, R)
    step(4, function()
        if R.skip then return end
        local w = R.win()
        local off, max = R.read()
        local e = Focus.getFocusedElement(w)
        local stuck = settle(R, off, e and e.id)
        R.n = (R.n or 0) + 1
        if not R.inView(e) then R.leftAt, R.left = off, true; return end
        -- (nothing under the view: Down does nothing once the end shows; before the end that is a fault)
        if stuck then R.leftAt = (off >= max - 0.5) and off or nil; say(tag .. ": Down did nothing at " .. f2(off) .. " of " .. f2(max)); return end
        if R.n > 40 then return end
        R.before, R.beforeId, R.pending = off, e and e.id, true
        Focus.dispatchJoypadDir(w, "down")
        return true
    end)
    step(4, function()
        if R.skip then return end
        local off, max = R.read()
        local big = 0
        for _, d in ipairs(R.deltas) do if d > big then big = d end end
        say(tag .. ": Down steps " .. table.concat(R.deltas, " ") .. " (60 units = " .. T.px(60) .. " px), view " .. f2(off) .. " of " .. f2(max))
        check(R.kept > 0, tag .. ": Down at the last stop scrolls the view with the focus kept (" .. R.kept .. " presses)")
        if R.stepMax then check(big > 0 and big <= R.stepMax + 1, tag .. ": a step is at most 60 units (" .. big .. " <= " .. R.stepMax .. ")") end
        check(R.leftAt ~= nil and R.leftAt >= max - 0.5, tag .. ": the move leaves the view only once its end shows (left at " .. f2(R.leftAt) .. ")")
        shot(tag .. "_foot")
        if R.left then Focus.dispatchJoypadDir(R.win(), "up") end   -- (back the way it came, into the view)
        R.n = 0
    end)
    step(4, function()
        if R.skip then return end
        local off = R.read()
        R.n = R.n + 1
        if off > 0.5 and R.n <= 40 then Focus.dispatchJoypadDir(R.win(), "up"); return true end
        check(off <= 0.5 and R.inView(Focus.getFocusedElement(R.win())), tag .. ": Up past the first stop scrolls to the top (" .. f2(off) .. ", "
            .. (R.n - 1) .. " Ups, on " .. tostring(fid(R.win())) .. ")")
        if R.close then pcall(R.close) end
    end)
end

-- the food item card in the Character window (zedqa_m1_cards.lua's pick)
local IC = { deltas = {}, kept = 0, win = CW }
local function icPick(item)
    local w = CW()
    local sel = w._mainContent._selectedItems
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    w._updateDrawer(w._mainContent)
end
IC.read = function()
    local c = CW()._itemCard
    return (c and c._scrollPixels) or 0, c and math.max(0, (c._contentH or 0) - c:viewH()) or 0
end
IC.inView = function(e) return e ~= nil and fzone(CW()) == "charItemCard" and not e.isFooter end
IC.close = function() icPick(nil) end
step(5, function()
    ZeD_CharacterWindow.openTab(pn, "loot")
    for _, ft in ipairs({ "Base.TinnedBeans", "Base.CannedChili", "Base.Crisps" }) do if not IC.it then IC.it = newItem(ft) end end
end)
step(20, function() if IC.it then icPick(IC.it) end end)
step(20, function()
    local w = CW()
    local c = w._itemCard
    if not check(IC.it and w._drawerItem == IC.it and c and c:isVisible(), "item card: the food card opens (" .. tostring(IC.it and IC.it:getName()) .. ")") then IC.skip = true; return end
    Focus.claimFocus(w)
    Focus.focusWhere(w, "charItemCard", function(x) return x.isPrimary end)
    local _, max = IC.read()
    if max <= 0 then say("not run: item card: the food card fits the short window"); IC.skip = true end
end)
longWalk("item_card", IC)

-- the Mechanics part card's About text (a car within 8 tiles, else the prelude's car)
local MC = { deltas = {}, kept = 0, win = WW, stepMax = T.px(60) }
MC.read = function() local s = WW()._mech or {}; return s.cardScroll or 0, s.maxRight or 0 end
-- (a verb in the band reads the view too, scrollFixed: in the view only when the card has no stop of its own there)
MC.inView = function(e) return e ~= nil and e.scrollView ~= nil and (MC.fixed or not e.scrollFixed) end
MC.close = function()
    local e = Focus.getFocusedElement(WW())
    if e and e.onCancel then e.onCancel(WW(), e) end
    ZeD_WorldWindow.openTab(pn, "loot")
    goHome()
end
step(5, function()
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for dy = -8, 8 do for dx = -8, 8 do
        local sq = getCell():getGridSquare(px + dx, py + dy, pz)
        local v = sq and sq:getVehicleContainer()
        if v and not MC.car then MC.car = v end
    end end
    if not MC.car and ZEDQA_CAR_SPAWN then MC.car = ZEDQA_CAR_SPAWN("Base.CarNormal", "b17s"); K.car = MC.car end
    if not MC.car then say("not run: Mechanics (no car within 8 tiles and no prelude to spawn one)"); MC.skip = true; return end
    -- (Nov 16 2026, the 4K run found no part rows: the Vehicle tab offers a car within 4.5 tiles of its centre and
    -- ends an inspection past 6 (MechanicsTab.lua REACH_TILES / KEEP_TILES); the car found or spawned stood further
    -- off, so the list never drew. The character stands 2 tiles beside the car for this part, then goes back.)
    local dx, dy = MC.car:getX() - p:getX(), MC.car:getY() - p:getY()
    local d = math.sqrt(dx * dx + dy * dy)
    if d > 3.5 then
        K.home = { x = p:getX(), y = p:getY(), z = p:getZ() }
        local x, y = MC.car:getX() + 2.5, MC.car:getY()
        pcall(function() p:teleportTo(x, y, pz) end)
        pcall(function() p:setX(x); p:setY(y); p:setLastX(x); p:setLastY(y) end)
    end
    local ex, ey = MC.car:getX() - p:getX(), MC.car:getY() - p:getY()
    say(string.format("mechanics: car %s %.1f tiles off, now %.1f", tostring(MC.car:getScript() and MC.car:getScript():getName()), d,
        math.sqrt(ex * ex + ey * ey)))
end)
step(10, function()
    if MC.skip then return end
    ZeD.MechanicsTab.openFromAction(p, MC.car, false)
end)
step(40, function()
    if MC.skip then return end
    local s = WW()._mech
    local rows = 0
    for _, z in ipairs(s and s.zones or {}) do if string.sub(tostring(z.id), 1, 9) == "mech:row:" then rows = rows + 1 end end
    say("mechanics: tab " .. tostring(WW()._activeTab) .. ", " .. #(s and s.vehicles or {}) .. " cars offered, view "
        .. tostring(s and s.view) .. ", " .. rows .. " part rows")
    local part
    for _, z in ipairs(s and s.zones or {}) do
        local id = string.match(tostring(z.id), "^mech:row:(.+)$")
        local key = "IGUI_Vehicle_CondInfo" .. tostring(id)
        if id and getText(key) ~= key and (not part or id == "Engine") then part = id end
    end
    if not check(part ~= nil, "mechanics: a part with About text in the list (" .. tostring(part) .. ")") then MC.skip = true; return end
    Focus.claimFocus(WW())
    local e = focusAny(WW(), function(x) return x.id == "mech:row:" .. part end)
    if e and e.onActivate then e.onActivate(WW(), e) else s.byId["mech:row:" .. part].fn() end
end)
step(30, function()
    if MC.skip then return end
    local s = WW()._mech
    local e = focusAny(WW(), function(x) return x.scrollView ~= nil and not x.scrollFixed end)
    if not e then e = focusAny(WW(), function(x) return x.scrollView ~= nil end); MC.fixed = e ~= nil end
    say("mechanics: card " .. tostring(s.card) .. ", right column scrolls " .. f2(s.maxRight) .. ", from " .. tostring(e and e.id))
    if not e or (s.maxRight or 0) <= 0 then say("not run: mechanics: the part card fits the short window"); MC.skip = true; pcall(MC.close); return end
    s.cardScroll = 0
end)
longWalk("mechanics", MC)

-- the Furniture tab's Place list: 14 chairs carried (zedqa_cov_equipfurn.lua's Moveable item)
local FU = { deltas = {}, kept = 0, win = WW, stepMax = T.px(60) }
FU.read = function() local s = WW()._fur or {}; return s.scrollY or 0, s.maxScroll or 0 end
FU.inView = function(e) return e ~= nil and e.scrollView ~= nil end
FU.close = function() if FU.mode then ZeD.FurnitureTab.setMode(pn, FU.mode) end; ZeD_WorldWindow.openTab(pn, "loot") end
step(5, function()
    local name
    for i = 0, 63 do
        local nm = "furniture_seating_indoor_01_" .. i
        local ok, mp = pcall(function() return ISMoveableSpriteProps.new(getSprite(nm)) end)
        if not name and ok and mp and mp.isMoveable and mp.sprite and not mp.isMultiSprite and mp.type == "Object" then name = nm; FU.mp = mp end
    end
    for _ = 1, (name and 14 or 0) do
        local ok, it = pcall(function() return FU.mp:instanceItem(name) end)
        if ok and it then p:getInventory():AddItem(it); K.added[#K.added + 1] = it end
    end
    FU.mode = ZeD.FurnitureTab.state.mode
    ZeD.FurnitureTab.setMode(pn, "place")
    ZeD_WorldWindow.openTab(pn, "furniture")
end)
step(40, function()
    local s = WW()._fur
    Focus.claimFocus(WW())
    local e = focusAny(WW(), function(x) return string.sub(tostring(x.id), 1, 8) == "fur:inv:" end)
    say("furniture: place list scrolls " .. f2(s and s.maxScroll) .. ", from " .. tostring(e and e.id))
    if not (e and s and (s.maxScroll or 0) > 0) then check(false, "furniture: the Place list overflows the short window"); FU.skip = true; pcall(FU.close) end
end)
longWalk("furniture", FU)

-- ===================================================================== 264: the Journal's delete question
local JN = {}
local function jEntries() local md = p:getModData(); return md.ZeD_Journal and md.ZeD_Journal.entries or {} end
local function isCross(e, entry) return e ~= nil and e.journalKind == "delete" and e.entryIdx ~= nil and jEntries()[e.entryIdx] == entry end
step(5, function()
    JN.had = p:getModData().ZeD_Journal ~= nil
    ZeD_CharacterWindow.openTab(pn, "journal")
end)
step(20, function()
    local w, JT = CW(), ZeD.JournalTab
    JT.setPage(w, 1)
    JN.search = w._journalSearchText
    JT.setSearch(w, "")
    ZeD.JournalReaders.addLogEntry(w, "ZEDQA b17s test entry two", nil, nil)
    JN.b = jEntries()[1]
    ZeD.JournalReaders.addLogEntry(w, "ZEDQA b17s test entry one", nil, nil)
    JN.a = jEntries()[1]
end)
step(20, function()
    local w = CW()
    Focus.claimFocus(w)
    local e = focusAny(w, function(x) return isCross(x, JN.a) end)
    if not check(e ~= nil and e.onActivate ~= nil, "journal: the test entry's delete cross is a pad stop") then JN.skip = true; return end
    e.onActivate(w, e)
end)
step(10, function()
    if JN.skip then return end
    local w = CW()
    local e = Focus.getFocusedElement(w)
    check(w._journalAsk ~= nil, "journal: A on the cross asks first")
    check(e ~= nil and e.id == "journal:ask:cancel", "journal: the question lands on Cancel (" .. tostring(e and e.id) .. ")")
    shot("journal_ask")
    if e and e.id == "journal:ask:cancel" then e.onActivate(w, e) else ZeD.JournalTab.cancelDelete(w) end
end)
step(10, function()
    if JN.skip then return end
    local w = CW()
    local e = Focus.getFocusedElement(w)
    check(w._journalAsk == nil and isCross(e, JN.a), "journal: Cancel puts the pad back on the entry's cross (" .. tostring(e and e.id) .. ")")
    local c = focusAny(w, function(x) return isCross(x, JN.a) end)
    if c then c.onActivate(w, c) end
end)
step(10, function()
    if JN.skip then return end
    local e = focusAny(CW(), function(x) return x.id == "journal:ask:verb" end)
    if not check(e ~= nil, "journal: Delete is a pad stop on the question") then JN.skip = true; return end
    e.onActivate(CW(), e)
end)
step(10, function()
    if JN.skip then return end
    local gone = true
    for _, x in ipairs(jEntries()) do if x == JN.a then gone = false end end
    local e = Focus.getFocusedElement(CW())
    check(gone, "journal: Delete takes the test entry away")
    check(isCross(e, JN.b), "journal: after Delete the pad lands on the next entry's cross (" .. tostring(e and e.id) .. ")")
    shot("journal_after_delete")
end)

-- ===================================================================== 264: Unequip and Drop from the Equip card
local EQ = { items = {} }
step(5, function()
    for _, ft in ipairs({ "Base.Hat_BaseballCap", "Base.Gloves_LeatherGloves", "Base.Necklace_Gold", "Base.Scarf_StripeBlackWhite" }) do
        if #EQ.items < 2 then
            pcall(function()
                local it = instanceItem(ft)
                local loc = it and it:getBodyLocation()
                if loc and p:getWornItem(loc) == nil then
                    p:getInventory():AddItem(it); K.added[#K.added + 1] = it
                    p:setWornItem(loc, it)
                    EQ.items[#EQ.items + 1] = it
                end
            end)
        end
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    say("equip: wearing " .. #EQ.items .. " test items")
    ZeD_CharacterWindow.openTab(pn, "equip")
end)
local function equipOne(i, verb)
    local E = {}
    step(30, function()
        local w, it = CW(), EQ.items[i]
        if not it then say("not run: equip " .. verb .. " (no test item " .. i .. " worn)"); E.skip = true; return end
        Focus.claimFocus(w)
        local e = focusAny(w, function(x) return x.item == it and string.sub(tostring(x.id), 1, 10) == "equipslot:" end)
        if not check(e ~= nil, "equip: the worn test item's slot is a pad stop (" .. tostring(e and e.id) .. ")") then E.skip = true; return end
        local order, k = w._equipFilledOrder or {}, nil
        for j, id in ipairs(order) do if id == e.id then k = j end end
        E.want = k and (order[k + 1] or order[k - 1]) or nil
        E.scroll = w._equipScroll and w._equipScroll.scrollPos or 0
        e.onActivate(w, e)
    end)
    step(20, function()
        if E.skip then return end
        local w = CW()
        local c = w._drawerPanel and w._drawerPanel._equipCard
        local idx
        for j, v in ipairs(c and c._lastHeaderVerbs or {}) do if (v.id or v.label) == verb then idx = j end end
        local e = idx and focusAny(w, function(x) return x.id == "equipcard:hverb_" .. idx end)
        if not check(e ~= nil and e.onActivate ~= nil, "equip: the card offers " .. verb .. " as a pad stop") then E.skip = true; return end
        shot("equip_card_" .. string.lower(verb))
        e.onActivate(w, e)
        E.t = 0
    end)
    step(10, function()
        if E.skip then return end
        E.t = E.t + 1
        if p:isEquippedClothing(EQ.items[i]) and E.t < 30 then return true end
    end)
    step(20, function()
        if E.skip then return end
        local w = CW()
        local e = Focus.getFocusedElement(w)
        local pos = w._equipScroll and w._equipScroll.scrollPos or 0
        check(not p:isEquippedClothing(EQ.items[i]), "equip: " .. verb .. " takes the test item off")
        check(e ~= nil and E.want ~= nil and e.id == E.want, "equip: after " .. verb .. " the pad lands on the next filled slot (" .. tostring(e and e.id) .. ", want " .. tostring(E.want) .. ")")
        check(E.scroll <= 0.001 or pos > 0.001, "equip: no jump to the top (scroll " .. f2(E.scroll) .. " -> " .. f2(pos) .. ")")
        shot("equip_after_" .. string.lower(verb))
    end)
end
equipOne(1, "UNEQUIP")
equipOne(2, "DROP")

-- ===================================================================== put back
step(10, function()
    local w, c = WW(), CW()
    pcall(function() ZeD_WorldWindow.closeObjectCard(pn) end)
    pcall(function() ZeD.Stations.unbind(p) end)
    pcall(function() if IC.it then icPick(nil) end end)
    -- the test entries (and the journal itself, when the run made it)
    pcall(function()
        local es = jEntries()
        for j = #es, 1, -1 do if es[j] == JN.a or es[j] == JN.b then table.remove(es, j) end end
        if not JN.had and #es == 0 then p:getModData().ZeD_Journal = nil end
        c._journalCache, c._journalGroupCache = nil, nil
        if JN.search ~= nil then ZeD.JournalTab.setSearch(c, JN.search) end
    end)
    for _, obj in ipairs(K.placed) do
        pcall(function() local sq = obj:getSquare(); if sq then sq:transmitRemoveItemFromSquare(obj) end end)
        pcall(function() if instanceof(obj, "IsoGenerator") then obj:remove() end end)
    end
    pcall(function() p:setPrimaryHandItem(K.prim); p:setSecondaryHandItem(K.sec) end)
    for _, it in ipairs(K.added) do
        pcall(function() if p:isEquippedClothing(it) then p:removeWornItem(it) end end)
        pcall(function()
            local wo = it:getWorldItem()
            if wo then local sq = wo:getSquare(); if sq then sq:removeWorldObject(wo) end; wo:removeFromWorld() end
        end)
        pcall(function() local ct = it:getContainer(); if ct then ct:Remove(it) end end)
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    goHome()
    if K.car and ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, K.car) end
    if K.hW and w then w:setHeight(K.hW) end
    if K.hC and c then c:setHeight(K.hC) end
    pcall(function() ZeD_WorldWindow.openTab(pn, "loot"); ZeD_CharacterWindow.openTab(pn, "loot") end)
    if K.size ~= nil and K.size ~= 2 then
        pcall(function()
            local o = PZAPI.ModOptions:getOptions("ZeD_UI"):getOption("textSize")
            o:setValue(K.size); if o.onChangeApply then o:onChangeApply(K.size) else ZeD.Settings.reapplyFromOptions() end
        end)
    end
    pcall(function() p:setTimedActionInstantCheat(K.instant == true) end)
    Focus.releaseFocus(pn)
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    say("put back: " .. #K.placed .. " objects and " .. #K.added .. " items taken away, heights " .. tostring(K.hW) .. " / " .. tostring(K.hC))
end)
step(30, function()
    if getGameSpeed() ~= K.speed then setGameSpeed(K.speed) end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- (stepped on each drawn frame: a paused game stops the tick)
local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    local ok, again = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(again)) end
    if not (ok and again == true) then qi = qi + 1 end
end
Events.OnPreUIDraw.Add(tick)
say("start")
