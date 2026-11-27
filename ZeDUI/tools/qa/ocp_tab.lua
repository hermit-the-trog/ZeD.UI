-- ZeDUI/tools/qa/ocp_tab.lua  (Nov 26 2026, QA; tag ocp_tab): the World window's Power, Fluid and Fire object cards,
-- the gamut sweep, in the style of the Mechanics and Cooking sweeps (mt_tab.lua, ck_tab.lua). Its spec is the map
-- ZeDUI/qa/audits/2026-11-26_map_cards_power_fluid_fire.md (section 5's suspicions PW1-PW10, FL1-FL10, FI1-FI10,
-- section 3's states, section 4's gaps). Run after zedqa_prelude.lua and rt_kit.lua (ocp.txt). grep "ZEDQA ocp_tab".
-- Each suspicion single player can stage is proved or cleared with values: PASS when ZeD does what the game does (or
-- tells what the game does), FAIL with the evidence when it does not; where ZeD and the game share a gap, a NOTE.
-- How it drives the cards: a click is the card's own pointer poll (ZeD_ObjectCard:_pointer) fed the button down and
-- up over the zone's middle, as the mouse does; a body zone scrolled out of view is brought in first (the card's own
-- jump), else pressed as the pad's A presses it, said once. The pad's presses go through FocusManager's QA hook and
-- its own dispatch on the World window (RT.pad + RT.padDown, focus by focusWhere in worldItemCard), the input mode
-- locked to the controller and put back as found. The face pop-out takes the mouse and the pad itself (its own
-- onMouseDown / onJoypadDown, as the game hands them to it); the Lights wheel's slices are taken as the wheel takes
-- them (ZeD.DpadWheels.take). The cards are reached the game's way: the game's own menu handlers, which ZeD hooks
-- (Generator Info, the campfire's and the barbecue's fuel line, an item's Liquid > Transfer / Show info, a world
-- container's Transfer / Show info).
-- The game's answers are asked of the game itself: the generator's getFuel, getCondition, isActivated, isConnected
-- and getTotalPowerUsing, the world clock; the fluid container's amount, its fluids, isTaintedStatusKnown,
-- isHiddenAmount, FluidContainer.CanTransfer; the campfire's own fuel and lit flags (the game's campfire system), the
-- barbecue's isLit / isSmouldering / hasPropaneTank; the items the game burned or moved; the game's queue; the game's
-- own menus (ISWorldObjectContextMenu.createMenu, read and shut before it draws); never ZeD's code under test. What a
-- card drew is read from the draw itself (every word the card drew last frame, its warning boxes, its NEEDS lines,
-- its question, the keys it asked for), each by its own surface so two things on screen never stand for one another.
-- The Cooking sweep proved the fire card's cook minutes (K12) and the propane gauge (K14): not redone here.
-- Cases (PWn / FLn / FIn = the map's suspicion; mouse and pad where the verb has a press):
--   PW1  indoors (a building near home; SKIP when the map offers none): the card warns (the control); the face
--        popped out by a click on the machine and by the pad's Interact A, its engine switch pressed by the mouse
--        and by the pad, and the Lights wheel's Generator slice: started indoors, is he told about the fumes (the
--        pop-out's words, the keys it asked, the words over his head, the slice's words; the game's own Turn on
--        tooltip read from its menu)
--   PW2  two generators, one 5 tiles north (first in reading order), one beside him: the Lights wheel's Turn on and
--        Turn off: which one the game started and stopped (isActivated on both)
--   PW3  Electricity 0, the Generator recipe unknown, connected and off: the game's menu offers Disconnect; the card's
--        Disconnect (folded, then shown greyed) and its outlet by the mouse and the pad; the game's own Disconnect
--        handler at Electricity 0 (isConnected after)
--   PW4  condition 0: the card's Turn on lit or not, pressed by the mouse and the pad, what the game did and what he
--        was told; condition 50: three starts by the mouse, the game's failure roll counted (NOTE)
--   PW5  Fix at 60% with 10 Scrap Electronics at Electricity 3 (mouse): the scrap the game's chain spent and the
--        condition reached, against what the card said first; at 90% with 2 (pad); Electricity 2: the card's NEEDS
--        line against the game's own tooltip (NOTE)
--   PW6  SKIP (multiplayer: another player's change, the server's fuel)
--   PW7  two cans: the first can's Add (mouse), the second's (pad) while the first pours: the fuel the game took;
--        the game's Add all against the card's presses; a can of petrol and water (NOTE); PW10's "+x.x L" (NOTE)
--   PW8  running with nothing powered, then with a range on: the card's run time left against the game's own burn
--        over two game hours each on fast-forward; the load needle, OIL lamp and meters (NOTE). Picture
--        ocp_power_<WxH>
--   PW9  Info from 2 (control), 7 and 15 tiles: the card shown, or the game's walk; seated: in the seated case
--   PW10 words and docs: a NOTE (no in-game case beyond PW7's gain words)
--   FL1  tainted water: 0.5 L and 1.5 L of tainted water, 1:9 and 9:1 mixes: the card's Tainted (header tag,
--        Liquids row) against the game's isTaintedStatusKnown; the 0.5 L bottle drunk the game's way (its poison,
--        NOTE)
--   FL2  a rain collector and a bottle: Switch, Empty (mouse), its question, Cancel; Switch back, Empty (pad), Yes
--        (pad): what the game emptied, whether the question named it
--   FL3  the collector 5 tiles off: Pour, Stop at once during the walk (mouse); Pour into a container tagged Mixes,
--        Stop at once (pad): what the game poured
--   FL4  Pour pressed twice in one frame (mouse) and A A (pad) into a pot of bleach: the transfers the game queued,
--        the liters moved against one Max Pour
--   FL5  seated: in the seated case
--   FL6  a well (the game hides its amount): what the card shows of its level (words, lit segments)
--   FL7  Transfer on the collector from 2 (control), 7 and 15 tiles: the card shown, or the game's walk
--   FL8  a bottle in a bag poured: where the game left it; a full inventory and a near-full one: the card's Too heavy
--        tag against the game's own refusal (CanTransfer)
--   FL9  the pour's drawn progress against the liters the game moved; the Into bottle put in a crate: no stale side;
--        another player's drain SKIP (multiplayer)
--   FL10 words: Empty's question lowercases the liquid (a FAIL only where the run's language capitalizes it)
--   FI1  an indoor campfire (a building near home; SKIP when none) on a floor the game can set alight, lit from the
--        card: does the card warn; an hour on fast-forward, any fire the game starts nearby put out at once (NOTE)
--   FI2  All fuel with a crate beside the fire holding a skill book, a map and a plank (mouse; pad): what the game
--        burned (gone for good: NOTE). Picture ocp_fire_<WxH>
--   FI3  a skill book in the bags, paper in a bag, matches and a lighter: the pad's A A on Light, the mouse's two
--        clicks: what the game burned and which starter it used
--   FI4  a fireplace 5 tiles north and a campfire cooking beside him, both lit: the Lights wheel's Put out: which one
--        the game put out
--   FI5  Take apart on a lit campfire with a pot of stew (mouse; Yes) and an unlit one with a steak (pad; Yes): where
--        the game put the food, against the question's words
--   FI6  a propane grill with an empty tank in and a full one in the bags: the game's menu offers Insert, the card's
--        verbs; the tank key (mouse; pad): what the game queued; a spare on the floor beside it: Insert (mouse)
--   FI7  a charcoal barbecue lit, Put out (mouse): smouldering; a steak on it over 10 game minutes: the game's heat
--        against the card's cooking reading; Light offered again (NOTE)
--   FI8  SKIP (multiplayer: two players feeding one fire)
--   FI9  the campfire's Info from 2 (control), 7 and 15 tiles; seated: in the seated case
--   FI10 no fuel, paper and no starter: Light's NEEDS line against the game's own lighting rule
--   seated (run last) a passenger seat in a car: the generator's Info (PW9), a bottle's Transfer and Show info (FL5),
--        the campfire's Info (FI9): what showed, against the game's own menus seated
--   every case: no Lua error over it (an error thrown in this script's own code, its first frame here, is a TEST
--        FAULT note, not counted against ZeD); put back exactly
-- Puts back: every object laid (the generators, the range, the collectors and the well, the campfires, the fireplace,
-- the barbecues, the crates: named if left) and any fire near home or the building put out; every thing given or made
-- (the bags, the floor, the crates, the fires' own containers); his own free things set aside for the run (so the
-- game's moves have room and the lists hold only what a case gave) and given back; his skills (Electricity) and the
-- Generator recipe; his traits (not changed: checked); his stats (the drink); the windows, the World and Character
-- tabs, the card drawer (shut), the pop-out (shut); the hidden-actions setting; the pad lock; the pointer; the theme
-- and the text size (not changed: checked); the draw watchers; instant actions, game speed 1, the clock, where he
-- stood; the car (the prelude's removal); god mode and invincible as found (on for the run: fires burn beside him).

if not (RT and RT.make) then
    print("ZEDQA ocp_tab ERR rt_kit.lua did not run first")
    print("ZEDQA ocp_tab VERDICT FAIL 1")
    print("ZEDQA ocp_tab DONE")
    return
end
local Q = RT.make("ocp_tab")
Q.maxMs = 2200000                    -- (the runner gives this script 2400 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, objs = {}, fires = {}, stash = {},
            shots = {}, errs = 0, dead = false, xp = {}, halo = {}, said = {}, trSeen = {}, trPop = {}, cars = {}, keep = {} }
local H = {}
local C = {}
S.OC = ZeD and ZeD.ObjectCards
S.FP = ZeD and ZeD.FacePop
S.TF = ZeD and ZeD.TwoWayFull
S.DW = ZeD and ZeD.DpadWheels
S.F = RT.focus()
S.CRATE = "carpentry_01_16"
S.STOVES = { "appliances_cooking_01_0", "appliances_cooking_01_8" }
S.BBQ_GAS = "appliances_cooking_01_37"
S.BBQ_COAL = "appliances_cooking_01_35"
S.FIREPLACE = "fixtures_fireplaces_01_0"
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.RING2 = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 2, 2 }, { -2, -2 }, { 2, -2 }, { -2, 2 }, { 3, 0 }, { -3, 0 } }
S.STATS = { "HUNGER", "THIRST", "FATIGUE", "BOREDOM", "STRESS", "ENDURANCE", "UNHAPPINESS", "PANIC", "MORALE", "SANITY", "ANGER",
    "DISCOMFORT", "IDLENESS", "WETNESS", "FOOD_SICKNESS", "POISON", "SICKNESS" }
S.TR_KEYS = { UI_ZeD_Power_Fumes = true, UI_ZeD_ObjCard_MinLeft = true, UI_ZeD_Fluid_PourProgress = true }
S.FT = { gen = "Base.Generator", can = "Base.PetrolCan", scrap = "Base.ElectronicsScrap", bottle = "Base.WaterBottle",
         pop = "Base.PopBottle", pot = "Base.Pot", bucket = "Base.BucketEmpty", bag = "Base.Bag_Schoolbag", plank = "Base.Plank",
         paper = "Base.SheetPaper2", matches = "Base.Matches", lighter = "Base.Lighter", book = "Base.BookCarpentry1",
         map = "Base.MuldraughMap", stew = "Base.PotOfStew", steak = "Base.Steak", tank = "Base.PropaneTank", stone = "Base.Stone2" }

if not (S.p and S.OC and S.OC.kinds and S.OC.kinds.generator and S.OC.kinds.fluid and S.OC.kinds.fire and ZeD_WorldWindow
        and ZeD_ObjectCard and ZeD.Molecules and ZeD.Atoms) then
    Q.check(false, "the player, ZeD's object cards (generator, fluid, fire) and the World window are loaded")
    Q.start()
    return
end

-- ===================================================================== small helpers
function H.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
-- the first Lua frame's file in an F11 entry ("Lua(Vanilla).fn(spawnpoints.lua:1969)": spawnpoints), or nil. This
-- script runs under the name spawnpoints.lua (as the prelude and rt_kit do); no other code that throws is named so.
function H.errFile(s)
    if type(s) ~= "string" then return nil end
    local f = string.match(s, "([%w_%-%.]+)%.lua:%d+")
    return f
end
-- the F11 list's entries counted from e0 to e1 (getLuaDebuggerErrorCount counts entries, several to one error), split
-- by where each error was thrown: in this script's own code (its first Lua frame in spawnpoints.lua: a test fault,
-- fixed, never ZeD's) or anywhere else (ZeD's, the game's). An entry with no frame takes the frame of the next entry
-- that has one (an error's message comes before its stack). Entries the list no longer holds (it keeps its last
-- ones) count as not ours. Returns the count not ours, the count ours, and the first own frame line.
function H.errSplit(e0, e1)
    if not (e0 and e1) or e1 <= e0 then return 0, 0, nil end
    local new = e1 - e0
    local list, size = nil, 0
    pcall(function() list = getLuaDebuggerErrors() end)
    if list then pcall(function() size = list:size() end) end
    if not (list and size and size > 0) then return new, 0, nil end
    local from = math.max(0, size - new)
    local files = {}
    for i = from, size - 1 do
        local s = nil
        pcall(function() s = tostring(list:get(i) or "") end)
        files[#files + 1] = { f = H.errFile(s), s = s }
    end
    local own, firstOwn = 0, nil
    for i = 1, #files do
        local f = files[i].f
        local j = i
        while not f and j < #files do j = j + 1; f = files[j].f end
        if not f then j = i; while not f and j > 1 do j = j - 1; f = files[j].f end end
        if f == "spawnpoints" then
            own = own + 1
            if not firstOwn then firstOwn = string.match(files[j].s or "", "[^\n]*spawnpoints%.lua:%d+[^\n]*") end
        end
    end
    return new - own, own, firstOwn
end
-- the window e0 to e1 judged: "no Lua error" counts only the errors not thrown in this script's own code; its own are
-- said as a NOTE (a test fault to fix, not ZeD's) and kept for the run's total
function H.errCheck(label, e0, e1)
    if not (e0 and e1) then Q.check(true, label, "the count cannot be read"); return end
    local other, own, first = H.errSplit(e0, e1)
    S.ownErrs = (S.ownErrs or 0) + own
    if own > 0 then H.note(label .. ": TEST FAULT: " .. own .. " Lua error entries thrown in ocp_tab's own code (not ZeD's, not counted below): " .. tostring(first)) end
    Q.check(other == 0, label, other .. " new" .. ((own > 0) and (" (" .. own .. " more in ocp_tab's own code)") or ""))
end
function H.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function H.note(s) Q.say("NOTE " .. tostring(s)) end
-- time, not frames: cond asked every drawn frame until it holds, at most ms; fn(ok)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 4000000, function()
        if S.dead then return true end
        local now = getTimestampMs()
        st.t = st.t or now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() if S.dead then return end; fn(st.ok == true) end)
end
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
function H.call(o, m, ...)
    if o == nil then return nil end
    local f = nil
    pcall(function() f = o[m] end)
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
function H.list(t, max)
    local o = {}
    for i, v in ipairs(t or {}) do
        if max and i > max then o[#o + 1] = "..."; break end
        o[#o + 1] = tostring(v)
    end
    return (#o > 0) and table.concat(o, ", ") or "none"
end
function H.n1(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.1f", x) end
function H.n2(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.2f", x) end
function H.n3(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.3f", x) end
function H.screen() local w, h = 0, 0; pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end); return math.floor(w), math.floor(h) end
function H.sizeTag() local w, h = H.screen(); return w .. "x" .. h end
function H.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function H.home() local f = S.found; if f.pos then H.goTo(f.pos.x, f.pos.y, f.pos.z) end; if f.dir then pcall(function() S.p:setDir(f.dir) end) end end
-- the game's own code run for a case (its answer, not ZeD's): a throw is said, not counted against ZeD
function H.gcall(what, fn)
    local ok, err = pcall(fn)
    if not ok then Q.say("NOTE " .. tostring(what) .. " threw in the game's own code: " .. tostring(err)) end
    return ok
end
function H.zcall(fn)
    local ok, err = pcall(fn)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(err) end
    return ok
end
function H.has(s, sub) return type(s) == "string" and type(sub) == "string" and sub ~= "" and string.find(s, sub, 1, true) ~= nil end
function H.lc(s) return string.lower(tostring(s or "")) end
function H.hasLc(s, sub) return H.has(H.lc(s), H.lc(sub)) end
function H.lang() local l = "?"; pcall(function() l = tostring(Translator.getLanguage():name()) end); return l end
function H.worldH() local h = 0; pcall(function() h = getGameTime():getWorldAgeHours() end); return h end
function H.worldMin() return H.worldH() * 60 end
-- globals set for the length of fn, always put back (eq_tab's)
function H.withGlobals(over, fn)
    local was = {}
    for k, v in pairs(over) do was[k] = _G[k]; _G[k] = v end
    local ok, err = pcall(fn)
    for k, v in pairs(was) do _G[k] = v end
    return ok, err
end
function H.fluid(name)
    local f = nil
    pcall(function() f = Fluid[name] end)
    if not f then pcall(function() f = Fluid.Get(name) end) end
    return f
end

-- ===================================================================== the timed-action queue (the game's)
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.head() local a = H.queue()[1]; return a and tostring(a.Type) or "none" end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qfind(ty) for _, a in ipairs(H.queue()) do if a.Type == ty then return a end end; return nil end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 14) end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
-- queue: wait for the game's queue to empty (speed 2 by default), at most ms
function H.waitQ(T, ms, spd)
    H.step(1, function()
        if T.off then return end
        T.qt0 = getTimestampMs()
        H.speed(spd or 2)
    end)
    H.wait(ms, function() return T.off or (H.qlen() == 0 and getTimestampMs() - (T.qt0 or 0) > 500) end, function(ok)
        H.speed(1)
        if T.off then return end
        T.qDone = ok
        if not ok then H.note(T.L .. ": the game's queue did not empty in " .. ms .. " ms (" .. H.qkinds() .. "): cleared"); H.qstop() end
    end)
end

-- ===================================================================== things
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.ft(it) local s = "?"; if H.isItem(it) then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function H.nm(it) local s = "nothing"; if H.isItem(it) then pcall(function() s = tostring(it:getDisplayName()) end) end; return s end
function H.where(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getContainer() end) end; return c end
function H.ctype(c) local t = "none"; if c then pcall(function() t = tostring(c:getType()) end) end; return t end
-- its world object, while a square still holds it (the game's own moves can leave an item pointing at a world object
-- it took off the square: the item is on no floor then)
function H.onFloor(it)
    local wo = nil
    if H.isItem(it) then pcall(function() wo = it:getWorldItem() end) end
    if wo then
        local on = true
        pcall(function() local sq = wo:getSquare(); on = sq ~= nil and sq:getWorldObjects():contains(wo) end)
        if not on then return nil end
    end
    return wo
end
function H.whereText(it)
    local c = H.where(it)
    if c then return H.ctype(c) end
    local wo = H.onFloor(it)
    local s = "nowhere"
    if wo then pcall(function() local sq = wo:getSquare(); s = "the floor at " .. sq:getX() .. "," .. sq:getY() end) end
    return s
end
function H.gone(it) return H.where(it) == nil and H.onFloor(it) == nil end
function H.inv() return S.p:getInventory() end
function H.carried(it) local c = false; pcall(function() c = H.inv():containsRecursive(it) and true or false end); return c end
function H.known(ft) local ok = false; if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end; return ok end
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
function H.all() local out = {}; pcall(H.walkInv, H.inv(), out, 0); return out end
function H.count(ft) local n = 0; for _, it in ipairs(H.all()) do if H.ft(it) == ft then n = n + 1 end end; return n end
function H.mark(it)
    if not H.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    S.caseMade[#S.caseMade + 1] = it
    return it
end
function H.give(ft) if not ft then return nil end; local it = nil; pcall(function() it = H.inv():AddItem(ft) end); return H.mark(it) end
function H.giveTo(inv, ft) local it = nil; if inv and ft then pcall(function() it = inv:AddItem(ft) end) end; return H.mark(it) end
function H.loose(it)
    if not H.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
end
function H.removeItem(it)
    if not H.isItem(it) then return end
    H.loose(it)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            pcall(function() it:setWorldItem(nil) end)
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function H.sweepNew()
    local n = 0
    for _, it in ipairs(H.all()) do
        if not S.found.inv0[it] and not S.keep[it] then H.removeItem(it); n = n + 1 end
    end
    return n
end
function H.hands()
    local f = S.found
    if not f.hands then return end
    pcall(function()
        local a, b = f.hands.p, f.hands.s
        S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
        S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
    end)
end
function H.uses(it) local u = nil; if H.isItem(it) then pcall(function() u = it:getCurrentUses() end) end; return u end

-- fluids: the item's (or the world object's) container, its amount, filled from nothing with parts { { fluid, liters } }
function H.fcOf(x)
    local fc = nil
    if x == nil then return nil end
    pcall(function() fc = x:getFluidContainer() end)
    return fc
end
function H.amt(fc) local a = -1; if fc then pcall(function() a = fc:getAmount() end) end; return a end
function H.fill(fc, parts)
    if not fc then return false end
    pcall(function() fc:Empty() end)
    for _, p in ipairs(parts or {}) do
        if p[1] then pcall(function() fc:addFluid(p[1], p[2]) end) end
    end
    return true
end
function H.part(fc, f) local a = 0; if fc and f then pcall(function() a = fc:getSpecificFluidAmount(f) end) end; return a or 0 end

-- ===================================================================== his own things set aside, and given back
function H.isFree(it)
    local free = false
    pcall(function()
        free = it:getAttachedSlot() == -1 and not it:isEquipped() and not S.p:isEquippedClothing(it)
            and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
    end)
    return free
end
-- every free thing in his main inventory and in the bags he wears or holds; a loose bag goes whole with its things
function H.asideAll()
    local inv = H.inv()
    local moved, kept = 0, {}
    for _, it in ipairs(H.all()) do
        local c = H.where(it)
        local here = (c == inv)
        if not here and c then
            local bag = nil
            pcall(function() bag = c:getContainingItem() end)
            if bag and not H.isFree(bag) then here = true end
        end
        if here and S.found.inv0[it] and not S.found.stashed[it] then
            if H.isFree(it) and pcall(function() c:Remove(it) end) then
                S.stash[#S.stash + 1] = { it = it, c = c }
                S.found.stashed[it] = true
                moved = moved + 1
            elseif not instanceof(it, "Clothing") and not instanceof(it, "InventoryContainer") then
                kept[#kept + 1] = H.ft(it)
            end
        end
    end
    return moved, kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash or {}) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        if H.where(s.it) == nil then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end
function H.weight() local w, m = nil, nil; pcall(function() w = H.inv():getCapacityWeight(); m = S.p:getMaxWeight() end); return w, m end

-- ===================================================================== skills, recipes, traits, stats
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
    local grew, left = 0, 0
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
                local nx, nl = xp:getXP(r.perk), S.p:getPerkLevel(r.perk)
                if math.abs(nx - r.xp) > 0.01 or nl ~= r.lvl then
                    left = left + 1
                    S.xpLeftText = (S.xpLeftText or "") .. tostring(r.perk) .. " level " .. tostring(nl) .. " (found " .. tostring(r.lvl) .. ") xp "
                        .. string.format("%.2f", nx) .. " (found " .. string.format("%.2f", r.xp) .. "); "
                end
            end
        end
    end)
    pcall(function() SyncXp(S.p) end)
    return grew, left
end
function H.elec(n) pcall(function() S.p:setPerkLevelDebug(Perks.Electricity, n) end) end
function H.elecLvl() local l = 0; pcall(function() l = S.p:getPerkLevel(Perks.Electricity) end); return l end
function H.recipeKnown(r) local k = false; pcall(function() k = S.p:isRecipeActuallyKnown(r) and true or false end); return k end
function H.recipeInList(r) local k = false; pcall(function() k = S.p:getKnownRecipes():contains(r) and true or false end); return k end
function H.recipeOff(r) if H.recipeInList(r) then pcall(function() S.p:getKnownRecipes():remove(r) end); S.back.recipe = true end end
function H.recipeBack()
    local was = S.found.genRecipe
    local now = H.recipeInList("Generator")
    if was == true and not now then pcall(function() S.p:learnRecipe("Generator") end) end
    if was == false and now then pcall(function() S.p:getKnownRecipes():remove("Generator") end) end
    S.back.recipe = nil
end
function H.hasTrait(key)
    local has = false
    pcall(function() local ct = CharacterTrait[key]; if ct then has = S.p:hasTrait(ct) and true or false end end)
    return has
end
function H.stat(k) local v = nil; pcall(function() v = S.p:getStats():get(CharacterStat[k]) end); return v end
function H.statsBack()
    pcall(function()
        local stt = S.p:getStats()
        for k, v in pairs(S.found.stats or {}) do pcall(function() stt:set(CharacterStat[k], v) end) end
    end)
end

-- ===================================================================== objects laid round him
function H.sqXY(x, y, z) local sq = nil; pcall(function() sq = getCell():getGridSquare(x, y, z or 0) end); return sq end
function H.sqAt(dx, dy)
    local sq = nil
    pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, math.floor(S.p:getZ())) end)
    return sq
end
function H.sqFree(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
    end)
    return good
end
function H.freeSq(dx, dy) local sq = H.sqAt(dx, dy); return H.sqFree(sq) and sq or nil end
function H.used(sq)
    for _, c in ipairs(S.objs) do if c.sq == sq and not c.removed then return true end end
    for _, f in ipairs(S.fires) do if f.sq == sq and not f.removed then return true end end
    return false
end
function H.firstFree(ring) for _, d in ipairs(ring) do local sq = H.freeSq(d[1], d[2]); if sq and not H.used(sq) then return sq end end; return nil end
function H.keepObj(o, sq, what, kind) local c = { obj = o, sq = sq, what = what, kind = kind }; S.objs[#S.objs + 1] = c; return c end
function H.mkCrate()
    for _, d in ipairs(S.NEAR) do
        local sq = H.freeSq(d[1], d[2])
        if sq and not H.used(sq) then
            local o = nil
            pcall(function() o = IsoObject.new(getCell(), sq, S.CRATE) end)
            if o then
                pcall(function() o:createContainersFromSpriteProperties() end)
                pcall(function() sq:AddTileObject(o) end)
                local c = H.keepObj(o, sq, "a crate at " .. sq:getX() .. "," .. sq:getY(), "tile")
                pcall(function() c.inv = o:getContainer() end)
                if c.inv then pcall(function() c.inv:setExplored(true) end); return c end
                H.rmObj(c)
            end
        end
    end
    return nil
end
-- a generator (opts: fuel, cond, conn, on)
function H.mkGen(sq, o)
    if not sq then return nil end
    local g = nil
    pcall(function() g = IsoGenerator.new(instanceItem(S.FT.gen), getCell(), sq) end)
    if not g then return nil end
    pcall(function() g:setFuel(o.fuel or 0) end)
    pcall(function() g:setCondition(o.cond or 100) end)
    pcall(function() g:setConnected(o.conn and true or false) end)
    pcall(function() g:setActivated(o.on and true or false) end)
    return H.keepObj(g, sq, "a generator at " .. sq:getX() .. "," .. sq:getY(), "gen")
end
function H.mkStove(sq)
    for _, name in ipairs(S.STOVES) do
        local spr = getSprite(name)
        if spr and sq then
            local o = nil
            pcall(function()
                o = IsoStove.new(getCell(), sq, spr)
                pcall(function() o:createContainersFromSpriteProperties() end)
                sq:AddSpecialObject(o)
                if o:getObjectIndex() < 0 then sq:AddTileObject(o) end
            end)
            if o then return H.keepObj(o, sq, "a range at " .. sq:getX() .. "," .. sq:getY(), "stove") end
        end
    end
    return nil
end
function H.mkBBQ(sq, sprite)
    if not sq then return nil end
    local o = nil
    pcall(function() o = IsoBarbecue.new(getCell(), sq, getSprite(sprite)); sq:AddTileObject(o) end)
    if not o then return nil end
    return H.keepObj(o, sq, "a barbecue (" .. sprite .. ") at " .. sq:getX() .. "," .. sq:getY(), "bbq")
end
function H.mkFireplace(sq)
    if not sq then return nil end
    local o = nil
    pcall(function() o = IsoFireplace.new(getCell(), sq, getSprite(S.FIREPLACE)); sq:AddTileObject(o) end)
    if not o then return nil end
    return H.keepObj(o, sq, "a fireplace at " .. sq:getX() .. "," .. sq:getY(), "bbq")
end
function H.rmObj(c)
    if not (c and c.obj) or c.removed then return end
    local o = c.obj
    pcall(function() if c.kind == "gen" then o:setActivated(false); o:setConnected(false) end end)
    pcall(function() if c.kind == "stove" and o:Activated() then o:Toggle() end end)
    pcall(function() if c.kind == "bbq" and o:isLit() then o:extinguish() end end)
    pcall(function() if c.kind == "bbq" and o:isLit() then o:setLit(false) end end)
    pcall(function() local ct = o:getContainer(); if ct then ct:removeAllItems() end end)
    local sq = c.sq
    pcall(function() sq = o:getSquare() or c.sq end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        pcall(function() sq:getObjects():remove(o) end)
        pcall(function() sq:getSpecialObjects():remove(o) end)
        pcall(function() sq:RecalcProperties() end)
    end
    pcall(function() if c.kind == "gen" then o:remove() end end)
    pcall(function() o:removeFromWorld() end)
    pcall(function() o:removeFromSquare() end)
    c.removed = true
end
function H.objLeft(c)
    if not (c and c.obj) then return false end
    local left = false
    pcall(function() left = c.sq:getObjects():contains(c.obj) end)
    if not left then pcall(function() local sq = c.obj:getSquare(); left = sq ~= nil and sq:getObjects():contains(c.obj) end) end
    return left
end
function H.powered(o) local pw = false; pcall(function() local c = o:getContainer(); pw = c ~= nil and c:isPowered() end); return pw and true or false end
function H.genOn(g) local on = false; pcall(function() on = g:isActivated() and true or false end); return on end
function H.genConn(g) local on = false; pcall(function() on = g:isConnected() and true or false end); return on end
function H.genFuel(g) local f = nil; pcall(function() f = g:getFuel() end); return f end
function H.genCond(g) local f = nil; pcall(function() f = g:getCondition() end); return f end
-- the campfire (the game's campfire system)
function H.mkFire(sq)
    if not (sq and SCampfireSystem and SCampfireSystem.instance) then return nil end
    pcall(function() SCampfireSystem.instance:addCampfire(sq) end)
    local f = { sq = sq }
    S.fires[#S.fires + 1] = f
    return f
end
function H.fireLua(f) local lo = nil; if f and CCampfireSystem and CCampfireSystem.instance then pcall(function() lo = CCampfireSystem.instance:getLuaObjectOnSquare(f.sq) end) end; return lo end
function H.fireServer(f) local so = nil; if f and SCampfireSystem and SCampfireSystem.instance then pcall(function() so = SCampfireSystem.instance:getLuaObjectOnSquare(f.sq) end) end; return so end
function H.fireIso(f) local lo = H.fireLua(f); local iso = nil; if lo then pcall(function() iso = lo:getIsoObject() end) end; return iso end
function H.fireLit(f) local so = H.fireServer(f); local lit = false; if so then lit = so.isLit == true end; return lit end
function H.fireFuel(f) local so = H.fireServer(f); return so and so.fuelAmt or nil end
function H.fireLight(f, fuel) local so = H.fireServer(f); if so then pcall(function() if fuel then so:addFuel(fuel) end; so:lightFire() end) end end
function H.fireOut(f) local so = H.fireServer(f); if so then pcall(function() so:putOut() end) end end
function H.rmFire(f)
    if not f or f.removed then return end
    local iso = H.fireIso(f)
    pcall(function() local c = iso and iso:getContainer(); if c then c:removeAllItems() end end)
    local so = H.fireServer(f)
    if so then pcall(function() so:putOut() end); pcall(function() SCampfireSystem.instance:removeCampfire(so) end) end
    f.removed = true
end
-- any fire within r tiles of (cx, cy) put out (burnt food or a spread can start one)
function H.fireSweepAt(cx, cy, cz, r)
    local n = 0
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            pcall(function()
                local sq = getCell():getGridSquare(x, y, cz)
                if sq and sq:haveFire() then sq:stopFire(); n = n + 1 end
            end)
        end
    end
    return n
end
function H.fireSweep()
    local n = 0
    local f = S.found.pos
    if f then n = n + H.fireSweepAt(math.floor(f.x), math.floor(f.y), math.floor(f.z), 8) end
    for _, s in ipairs(S.sites or {}) do n = n + H.fireSweepAt(s.x, s.y, s.z, 8) end
    return n
end
-- new world items (anything not there at the start), taken away: only round the places snapped
function H.snapFloor(set, cx, cy, cz)
    for y = cy - 8, cy + 8 do
        for x = cx - 8, cx + 8 do
            local sq = getCell():getGridSquare(x, y, cz)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
function H.snapAt(x, y, z)
    S.floorAt = S.floorAt or {}
    local c = { x = math.floor(x), y = math.floor(y), z = math.floor(z or 0) }
    S.floorAt[#S.floorAt + 1] = c
    pcall(H.snapFloor, S.found.floor0, c.x, c.y, c.z)
end
function H.sweepFloor()
    local now, n = {}, 0
    for _, c in ipairs(S.floorAt or {}) do pcall(H.snapFloor, now, c.x, c.y, c.z) end
    for wo in pairs(now) do
        if not S.found.floor0[wo] then
            pcall(function() local sq = wo:getSquare(); if sq then sq:transmitRemoveItemFromSquare(wo) end end)
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            n = n + 1
        end
    end
    return n
end
function H.lootRefresh()
    pcall(function() local lp = getPlayerLoot(S.pn); if lp and lp.refreshBackpacks then lp:refreshBackpacks() end end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
    pcall(function() local w = RT.ww(); if w then w._containersDirty = true end end)
end
-- an entity built with the game's build code (the build cheat; bx_cook's rain collector): the new objects as kept
-- records, the first with a fluid container as .fc / .master
function H.findInfo(full)
    local found = nil
    pcall(function()
        local infos = SpriteConfigManager.GetObjectInfoList()
        for i = 0, infos:size() - 1 do
            local info = infos:get(i)
            local parent = info:getScript() and info:getScript():getParent()
            if not found and parent and tostring(parent:getScriptObjectFullType()) == full then found = info end
        end
    end)
    return found
end
function H.objsAround(cx, cy, cz, r)
    local set = {}
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            local sq = getCell():getGridSquare(x, y, cz)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do set[objs:get(i)] = true end
            end
        end
    end
    return set
end
function H.build(full, sq, what)
    if not (sq and ISBuildIsoEntity and SpriteConfigManager) then return nil, "the game's build code is not loaded" end
    local info = H.findInfo(full)
    if not info then return nil, "no entity info for " .. full end
    -- (the game's build code needs a craft recipe: BuildLogic:setRecipe and setInfo take it unchecked; an entity with
    -- none, as the well, is laid by H.placeEntity)
    local rec = nil
    pcall(function() rec = info:getRecipe() and info:getRecipe():getCraftRecipe() end)
    if not rec then return nil, "the game builds " .. full .. " from no craft recipe" end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local before = H.objsAround(x, y, z, 2)
    local cheatWas = false
    pcall(function() cheatWas = S.p:isBuildCheat() end)
    pcall(function() S.p:setBuildCheat(true) end)
    local okB, errB = pcall(function()
        local b = ISBuildIsoEntity:new(S.p, info, 1, ISInventoryPaneContextMenu.getContainers(S.p))
        b.buildCheat = true
        b.player = S.pn
        b.sq = sq
        if b:isValid(sq) then b:create(x, y, z, false, nil) end
    end)
    pcall(function() S.p:setBuildCheat(cheatWas and true or false) end)
    if not okB then return nil, "the build threw: " .. tostring(errB) end
    local out = { parts = {} }
    for obj in pairs(H.objsAround(x, y, z, 2)) do
        if not before[obj] then
            local osq = sq
            pcall(function() osq = obj:getSquare() or sq end)
            out.parts[#out.parts + 1] = H.keepObj(obj, osq, what .. " part at " .. osq:getX() .. "," .. osq:getY(), "built")
            if not out.fc then
                local m = obj
                pcall(function() m = obj:getMasterObject() or obj end)
                local fc = H.fcOf(m)
                if fc then out.fc, out.master = fc, m end
            end
        end
    end
    if #out.parts == 0 then return nil, "the game built nothing at " .. x .. "," .. y end
    return out, nil
end
function H.rmBuilt(b) for _, c in ipairs((b and b.parts) or {}) do H.rmObj(c) end end
-- an entity with no craft recipe (the well: a map object) laid as the map's loading lays it: a plain object of its
-- sprite on the square, its components made from its entity script (GameEntityFactory.CreateIsoObjectEntity, as the
-- game's MORainCollectorBarrel and ISBuildIsoEntity do). Returns { parts, fc, master } as H.build, or nil and why
function H.placeEntity(full, sq, sprite, what)
    if not (sq and GameEntityFactory and GameEntityFactory.CreateIsoObjectEntity and SpriteConfigManager) then return nil, "the game's entity code is not loaded" end
    if not getSprite(sprite) then return nil, "no sprite " .. sprite end
    local script = nil
    pcall(function()
        local info = SpriteConfigManager.getObjectInfoFromSprite(sprite)
        if info and info:getScript() then script = info:getScript():getParent() end
    end)
    if not script then
        pcall(function() local info = H.findInfo(full); if info and info:getScript() then script = info:getScript():getParent() end end)
    end
    if not script then return nil, "no entity script for " .. full .. " (sprite " .. sprite .. ")" end
    local o = nil
    pcall(function() o = IsoObject.new(getCell(), sq, sprite) end)
    if not o then return nil, "no object of sprite " .. sprite end
    local okE, errE = pcall(function() GameEntityFactory.CreateIsoObjectEntity(o, script, true) end)
    if not okE then return nil, "the entity threw: " .. tostring(errE) end
    pcall(function() sq:AddSpecialObject(o) end)
    pcall(function() if o:getObjectIndex() < 0 then sq:AddTileObject(o) end end)
    pcall(function() sq:RecalcProperties() end)
    local c = H.keepObj(o, sq, what .. " at " .. sq:getX() .. "," .. sq:getY(), "built")
    local out = { parts = { c } }
    local fc = H.fcOf(o)
    if fc then out.fc, out.master = fc, o end
    if not H.objLeft(c) then H.rmObj(c); return nil, "the square took no " .. what end
    return out, nil
end

-- ===================================================================== the object card (read from its draw)
function H.ocard() local c = nil; pcall(function() c = ZeD_WorldWindow.getObjectCard(S.pn) end); return c end
function H.entry() local c = H.ocard(); return c and c.entry end
function H.kind() local e = H.entry(); return e and e.def and e.def.id end
function H.tt() local e = H.entry(); return e and e.t end
function H.closeCard() pcall(function() if H.ocard() and H.entry() then ZeD_WorldWindow.closeObjectCard(S.pn) end end) end
function H.zone(fid)
    local c = H.ocard()
    for _, z in ipairs((c and c._zones) or {}) do if z.fid == fid then return z end end
    return nil
end
function H.lit(fid) local z = H.zone(fid); return z ~= nil and z.run ~= nil end
function H.zoneIds(pre)
    local o = {}
    local c = H.ocard()
    for _, z in ipairs((c and c._zones) or {}) do
        if z.fid and (pre == nil or string.sub(tostring(z.fid), 1, #pre) == pre) then o[#o + 1] = tostring(z.fid) .. (z.run and "" or "(no run)") end
    end
    return H.list(o, 30)
end
-- the card on this kind (and object) drawn within the last 400 ms with its data
function H.cardOn(kind, obj)
    local e = H.entry()
    if not (e and e.def and e.def.id == kind and e.t and e.t.d) then return false end
    if obj ~= nil and e.t.obj ~= obj then return false end
    return S.cardT ~= nil and getTimestampMs() - S.cardT < 400
end
function H.cardFire(f)
    local e = H.entry()
    return e ~= nil and e.def and e.def.id == "fire" and e.t and e.t.sq == f.sq and e.t.d ~= nil and S.cardT ~= nil and getTimestampMs() - S.cardT < 400
end
function H.sideOwner(c) local o = nil; if c then pcall(function() o = c:getOwner() end) end; return o end
function H.cardFluid(fromObj)
    local t = H.tt()
    if not (H.kind() == "fluid" and t and t.d) then return false end
    if fromObj ~= nil and H.sideOwner(t.from) ~= fromObj then return false end
    return S.cardT ~= nil and getTimestampMs() - S.cardT < 400
end
function H.drew(sub) for _, t in ipairs(S.cardTexts or {}) do if H.hasLc(t.s, sub) then return t end end; return nil end
function H.drewEq(s) local n = 0; for _, t in ipairs(S.cardTexts or {}) do if H.lc(t.s) == H.lc(s) then n = n + 1 end end; return n end
function H.drewAll(sub, max) local o = {}; for _, t in ipairs(S.cardTexts or {}) do if H.hasLc(t.s, sub) then o[#o + 1] = t.s end end; return H.list(o, max or 6) end
function H.cardWords(max) local o = {}; for _, t in ipairs(S.cardTexts or {}) do o[#o + 1] = t.s end; return H.list(o, max or 40) end
-- the words drawn on the zone's own row (its y band), left of its button
function H.rowWords(fid)
    local z = H.zone(fid)
    if not z then return "no row " .. tostring(fid) end
    local o = {}
    local T = ZeD.T
    local band = (T and T.px and T.px(8)) or 8
    for _, t in ipairs(S.cardTexts or {}) do
        if t.y >= z.y - band and t.y <= z.y + z.h and t.x < z.x then o[#o + 1] = t.s end
    end
    return H.list(o, 8)
end
-- the value drawn on the same line just right of a label (UI.pair's left value)
function H.valueRight(label)
    local lt = nil
    for _, t in ipairs(S.cardTexts or {}) do if H.lc(t.s) == H.lc(label) then lt = t end end
    if not lt then return nil end
    local best = nil
    for _, t in ipairs(S.cardTexts or {}) do
        if t ~= lt and math.abs(t.y - lt.y) <= 3 and t.x > lt.x and (best == nil or t.x < best.x) then best = t end
    end
    return best and best.s or nil
end
-- a mouse click on a card zone: the card's own pointer poll fed the button down, then up, over its middle; a body
-- zone out of view is pressed as the pad's A presses it (said once)
function H.cardClick(fid, what)
    local c = H.ocard()
    local z = H.zone(fid)
    if not (c and z) then return false, "no " .. tostring(fid) .. " on the card (" .. H.zoneIds() .. ")" end
    local inV = true
    if z.body then inV = z.y + z.h > (c._viewY or 0) and z.y < (c._viewY or 0) + (c._viewH or 0) end
    if not inV then
        if not S.said[fid] then
            S.said[fid] = true
            H.note(tostring(what) .. ": " .. fid .. " is out of the card's view: pressed as the pad's A presses it")
        end
        if z.run then H.zcall(function() z.run(c, S.p) end) end
        return true, "pressed as A"
    end
    local x = c:getAbsoluteX() + z.x + math.floor(z.w / 2)
    local y = c:getAbsoluteY() + z.y + math.floor(z.h / 2)
    local mx, my = function() return x end, function() return y end
    pcall(function() c._wasDown = false end)
    local ok1, e1 = H.withGlobals({ getMouseX = mx, getMouseY = my, isMouseButtonDown = function() return true end }, function() c:_pointer() end)
    local ok2, e2 = H.withGlobals({ getMouseX = mx, getMouseY = my, isMouseButtonDown = function() return false end }, function() c:_pointer() end)
    if not (ok1 and ok2) then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(e1 or e2); return false, "the press threw" end
    return true, "clicked"
end
-- queue: bring a body zone into the card's view (the card's own jump), then click it (when: run only while it says yes)
function H.clickQ(T, fid, what, key, when)
    H.step(1, function()
        if T.off or (when and not when()) then return end
        local c = H.ocard()
        if c and H.zone(fid) then pcall(function() c._jumpTo = fid; c._followId = nil end) end
    end)
    H.step(3, function()
        if T.off or (when and not when()) then return end
        local ok, how = H.cardClick(fid, what)
        if key then T[key] = ok end
        if not ok then H.note(tostring(what) .. ": " .. tostring(how)) end
    end)
end
-- the card's zones' press as the pad's A runs it (a row picked for staging, not the verb under test)
function H.press(fid) local c, z = H.ocard(), H.zone(fid); if c and z and z.run then return H.zcall(function() z.run(c, S.p) end) end; return false end

-- ===================================================================== the pad (on the World window's card)
function H.lockFound()
    local key = nil
    pcall(function()
        local o = H.zopt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
function H.padOn()
    local Det = ZeD.Input and ZeD.Input.Detector
    if not (Det and Det.setLockedMode and S.F) then return false end
    if S.lockWas == nil then S.lockWas = H.lockFound() end
    pcall(Det.setLockedMode, "gamepad")
    S.back.pad = true
    local w = RT.ww()
    if w and S.F.claimFocus then pcall(S.F.claimFocus, w) end
    return true
end
function H.padOff()
    if not S.back.pad then return end
    S.back.pad = nil
    for _, b in ipairs({ "A", "B", "X", "Y" }) do RT.pad(b, nil) end
    pcall(function() S.F.releaseFocus(S.pn) end)
    local Det = ZeD.Input and ZeD.Input.Detector
    pcall(function()
        Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
    end)
end
function H.focusedId() local el = nil; pcall(function() el = S.F.getFocusedElement(RT.ww()) end); return el and el.id or nil end
function H.focusEl(id)
    local w = RT.ww()
    if not (w and S.F and S.F.focusWhere and id) then return false end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "worldItemCard", function(el) return el.id == id end) end)
    return e ~= nil
end
-- a tap queued on the World window: down through the QA hook and FocusManager's dispatch, up 4 frames later, then
-- the hook lets go (nothing is pressed when gate says no)
function H.tap(name, joy, gate)
    local st = {}
    H.step(1, function()
        local w = RT.ww()
        if not w then return end
        if gate and not gate() then return end
        st.on = true
        RT.pad(name, true)
        if joy then RT.padDown(Joypad[joy], w) end
    end)
    H.step(4, function() if st.on then RT.pad(name, false) end end)
    H.step(4, function() if st.on then RT.pad(name, nil) end end)
end
function H.tapA(gate) H.tap("A", "AButton", gate) end
-- A, A: the second down two frames after the first (inside the card's 50 ms refresh)
function H.tapAA(gate)
    local st = {}
    H.step(1, function()
        local w = RT.ww()
        if not w or (gate and not gate()) then return end
        st.on = true
        RT.pad("A", true); RT.padDown(Joypad.AButton, w)
    end)
    H.step(1, function() if st.on then RT.pad("A", false) end end)
    H.step(1, function() local w = RT.ww(); if st.on and w then RT.pad("A", true); RT.padDown(Joypad.AButton, w) end end)
    H.step(3, function() if st.on then RT.pad("A", false) end end)
    H.step(3, function() if st.on then RT.pad("A", nil) end end)
end
-- queue: the pad's A on a card zone (focus by focusWhere, then the tap); T[key] true when the focus took (when: run
-- only while it says yes)
function H.padPress(T, fid, label, key, when)
    H.step(2, function()
        T[key or "go"] = nil
        if T.off or (when and not when()) then return end
        local go = H.padOn() and H.focusEl(fid)
        T[key or "go"] = go
        if not go then Q.check(false, label .. " (pad): the pad's focus lands on " .. fid, "on " .. tostring(H.focusedId()) .. "; card zones " .. H.zoneIds()) end
    end)
    H.tapA(function() return not T.off and T[key or "go"] end)
end

-- ===================================================================== the face pop-out and the Lights wheel
function H.popView() local v = nil; pcall(function() v = S.TF.get(S.pn) end); return v end
function H.popShowing(obj) local s = false; pcall(function() s = S.TF.showingObj(S.pn, obj) and true or false end); return s end
function H.popUp() local d = nil; pcall(function() d = S.TF.showing(S.pn) end); return d ~= nil end
function H.popClose() pcall(function() if S.TF.showing(S.pn) then S.TF.close(S.pn) end end) end
function H.popHit(id)
    local v = H.popView()
    for _, h in ipairs((v and v._hits) or {}) do if h.id == id then return h, v end end
    return nil, v
end
function H.popHits() local v = H.popView(); local o = {}; for _, h in ipairs((v and v._hits) or {}) do o[#o + 1] = tostring(h.id) end; return H.list(o) end
-- the pop-out's mouse: its own press and release over the control
function H.popClick(id)
    local h, v = H.popHit(id)
    if not h then return false end
    local x, y = h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)
    H.zcall(function() v:onMouseDown(x, y); v:onMouseUp(x, y) end)
    return true
end
-- the pop-out's pad: its focus on the control, then its own A
function H.popPad(id)
    local h, v = H.popHit(id)
    if not h then return false end
    pcall(function() v.focusId = id end)
    H.zcall(function() v:onJoypadDown(Joypad.AButton, nil) end)
    return true
end
function H.lights()
    local D = S.DW
    if not (D and D.H and D.H.lights) then return {} end
    local ok, sl = pcall(D.H.lights, S.p, S.pn)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(sl); return {} end
    return sl or {}
end
function H.sliceWords(sl) if not sl then return "no slice" end; return tostring(sl.name) .. " | " .. tostring(sl.detail) .. (sl.off and (" | off: " .. tostring(sl.off)) or "") end
function H.wheelTake(sl) if S.DW and S.DW.take and sl then return H.zcall(function() S.DW.take(S.pn, sl) end) end; return false end

-- ===================================================================== the game's own menus (built, read, shut)
function H.menuShut(ctx)
    pcall(function() if ctx and ctx._zedMenu then ctx._zedMenu:close() end end)
    pcall(function() if ctx and ctx.closeAll then ctx:closeAll() end end)
    pcall(function() if ctx then ctx:setVisible(false) end end)
    pcall(function() local v = getPlayerContextMenu(S.pn); if v then v:closeAll(); v:setVisible(false) end end)
end
function H.menuWalk(ctx, path, out, depth)
    local n = (ctx.numOptions or 1) - 1
    for i = 1, n do
        local o = ctx.options and ctx.options[i]
        if o and o.name then
            local tip = nil
            pcall(function() tip = o.toolTip and o.toolTip.description end)
            local e = { name = tostring(o.name), path = path .. tostring(o.name), na = o.notAvailable == true, tip = tip and tostring(tip) or nil }
            out[#out + 1] = e
            if o.subOption and depth < 4 then
                local sub = nil
                pcall(function() sub = ctx:getSubMenu(o.subOption) end)
                if sub and sub ~= ctx then H.menuWalk(sub, e.path .. " > ", out, depth + 1) end
            end
        end
    end
end
-- the game's world menu as a right-click on the object builds it (ISWorldObjectContextMenu.createMenu): the objects
-- of the object's own square in worldobjects (the object among them), the point the object's square stands at on
-- the screen (the game picks world items and corpses at that point; a point off the object read the floor items on
-- his square instead), every option with its path, grey flag and tooltip; shut before it draws. Returns the whole
-- menu, an error, and the object's own options (those under its own heading: its tile name, or "Generator")
function H.gameMenu(objs)
    local out, own, ctx = {}, {}, nil
    local obj = objs and objs[1]
    local sq = nil
    if obj then pcall(function() sq = obj:getSquare() end) end
    local list = {}
    if sq then pcall(function() local ol = sq:getObjects(); for i = 0, ol:size() - 1 do list[#list + 1] = ol:get(i) end end) end
    for _, o in ipairs(objs or {}) do
        local has = false
        for _, l in ipairs(list) do if l == o then has = true end end
        if not has then list[#list + 1] = o end
    end
    local sw, sh = H.screen()
    local mx, my = math.floor(sw * 0.45), math.floor(sh * 0.4)
    if sq then
        pcall(function()
            local x, y, z = sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ()
            local px, py = isoToScreenX(S.pn, x, y, z), isoToScreenY(S.pn, x, y, z)
            if type(px) == "number" and type(py) == "number" then
                mx = math.max(1, math.min(sw - 2, math.floor(px)))
                my = math.max(1, math.min(sh - 2, math.floor(py)))
            end
        end)
    end
    local ok, err = pcall(function() ctx = ISWorldObjectContextMenu.createMenu(S.pn, list, mx, my, false) end)
    if ok and type(ctx) == "table" and ctx.options then pcall(H.menuWalk, ctx, "", out, 0) end
    H.menuShut(ctx)
    local heads = {}
    local tn = obj and H.call(obj, "getTileName")
    if tn and tn ~= "" then heads[#heads + 1] = tostring(tn) end
    local isGen = false
    if obj then pcall(function() isGen = instanceof(obj, "IsoGenerator") end) end
    if isGen then heads[#heads + 1] = getText("ContextMenu_Generator") end
    for _, e in ipairs(out) do
        for _, h in ipairs(heads) do
            if e.path == h or string.sub(e.path, 1, #h + 3) == h .. " > " then own[#own + 1] = e; break end
        end
    end
    return out, (not ok) and tostring(err) or nil, own
end
-- the game's menu read off the object, or why not: a menu without the object's own options was read off something
-- else (or the game offers nothing on it here); a check on it is a SKIP with the menu read
function H.ownMenuWhy(all, own, err)
    if #(own or {}) > 0 then return nil end
    return "the game's menu read did not hold the object's own options (read: " .. H.menuNames(all, 10) .. (err and ("; " .. err) or "") .. ")"
end
function H.menuFind(list, name) for _, e in ipairs(list or {}) do if e.name == name then return e end end; return nil end
function H.menuLike(list, sub) for _, e in ipairs(list or {}) do if H.has(e.path, sub) then return e end end; return nil end
function H.menuNames(list, max) local o = {}; for _, e in ipairs(list or {}) do o[#o + 1] = e.path .. (e.na and " (grey)" or "") end; return H.list(o, max or 16) end

-- ===================================================================== the draw and the words, watched (on for the run)
-- S.cardTexts: every word the object card drew last frame ({ s, x, y }); S.cardWarns: its warning boxes; S.cardNeeds:
-- its NEEDS lines; S.cardQ: its question; S.cardSeg: its segment fills ({ lit, y }); S.cardT: when. S.popTexts: the
-- face pop-out's words; S.trSeen[key] / S.trPop[key]: a watched key asked by the card / the pop-out ({ t, a, b });
-- S.genSt / S.popSt: the generator plate's state as drawn on the card / the pop-out; S.halo: words over his head
function H.wrapOn()
    if S.w0 then return end
    local W = { pre = ZeD_ObjectCard.prerender, warn = S.OC.ui.warn, nl = ZeD.Molecules.drawNeedsLine, qb = ZeD.Molecules.drawQuestionBand,
                seg = ZeD.Atoms.drawSegFill, tr = ZeD.tr, plate = ZeD.Plate and ZeD.Plate.draw,
                ppre = ZeD_TwoWayFull and rawget(ZeD_TwoWayFull, "prerender") }
    S.w0 = W
    W.preFn = function(self, ...)
        local rec = {}
        S.recWarn, S.recNeeds, S.recSeg, S.qFrame = {}, {}, {}, nil
        local own = rawget(self, "drawText")
        local base = self.drawText
        if base then self.drawText = function(pp, text, tx, ty, ...) rec[#rec + 1] = { s = tostring(text), x = tx or 0, y = ty or 0 }; return base(pp, text, tx, ty, ...) end end
        S.inCard = true
        local ok, res = pcall(W.pre, self, ...)
        S.inCard = false
        self.drawText = own
        if self.entry then
            S.cardTexts, S.cardWarns, S.cardNeeds, S.cardSeg, S.cardQ, S.cardT = rec, S.recWarn, S.recNeeds, S.recSeg, S.qFrame, getTimestampMs()
            if S.qFrame then S.cardQLast = S.qFrame end
        end
        if not ok then S.cardErrs = (S.cardErrs or 0) + 1; S.cardErrLast = res; error(res, 0) end
        return res
    end
    W.warnFn = function(card, x, y, w, text, ...)
        if S.inCard and S.recWarn then S.recWarn[#S.recWarn + 1] = tostring(text) end
        if S.inPop and S.popRec then S.popRec[#S.popRec + 1] = { s = tostring(text), x = x or 0, y = y or 0 } end
        return W.warn(card, x, y, w, text, ...)
    end
    W.nlFn = function(panel, x, y, w, text, ...)
        if S.inCard and S.recNeeds then S.recNeeds[#S.recNeeds + 1] = tostring(text) end
        return W.nl(panel, x, y, w, text, ...)
    end
    W.qbFn = function(panel, x, y, w, question, verb, opts, ...)
        if S.inCard then S.qFrame = tostring(question) end
        return W.qb(panel, x, y, w, question, verb, opts, ...)
    end
    W.segFn = function(panel, x, y, w, h, n, lit, ...)
        if S.inCard and S.recSeg then S.recSeg[#S.recSeg + 1] = { lit = lit, y = y or 0 } end
        return W.seg(panel, x, y, w, h, n, lit, ...)
    end
    W.trFn = function(key, a, b, ...)
        if S.TR_KEYS[key] then
            local r = { t = getTimestampMs(), a = a, b = b }
            if S.inPop then S.trPop[key] = r elseif S.inCard then S.trSeen[key] = r end
        end
        return W.tr(key, a, b, ...)
    end
    W.plateFn = function(cv, des, st, ...)
        if type(st) == "table" and st.volts ~= nil then
            local copy = { load = st.load, overload = st.overload, service = st.service, volts = st.volts, hz = st.hz, fuel = st.fuel, running = st.running, t = getTimestampMs() }
            if S.inPop then S.popSt = copy elseif S.inCard then S.genSt = copy end
        end
        return W.plate(cv, des, st, ...)
    end
    S.OC.ui.warn = W.warnFn
    ZeD.Molecules.drawNeedsLine = W.nlFn
    ZeD.Molecules.drawQuestionBand = W.qbFn
    ZeD.Atoms.drawSegFill = W.segFn
    ZeD.tr = W.trFn
    if W.plate then ZeD.Plate.draw = W.plateFn end
    ZeD_ObjectCard.prerender = W.preFn
    -- the pop-out: every word it draws in a frame (its prerender draws the face, its strip and the mark)
    if W.ppre then
        W.ppreFn = function(self, ...)
            local rec = {}
            S.popRec = rec
            local own = rawget(self, "drawText")
            local base = self.drawText
            if base then self.drawText = function(pp, text, tx, ty, ...) rec[#rec + 1] = { s = tostring(text), x = tx or 0, y = ty or 0 }; return base(pp, text, tx, ty, ...) end end
            S.inPop = true
            local ok, res = pcall(W.ppre, self, ...)
            S.inPop = false
            self.drawText = own
            S.popTexts, S.popT = rec, getTimestampMs()
            if #rec > 0 then S.popAll = S.popAll or {}; for _, t in ipairs(rec) do S.popAll[t.s] = true end end
            if not ok then error(res, 0) end
            return res
        end
        ZeD_TwoWayFull.prerender = W.ppreFn
    end
    W.halo = {}
    if HaloTextHelper then
        for _, k in ipairs({ "addText", "addBadText", "addGoodText" }) do
            local orig = HaloTextHelper[k]
            if orig then
                local fn = function(pl, text, ...)
                    S.halo[#S.halo + 1] = { text = tostring(text), t = getTimestampMs() }
                    return orig(pl, text, ...)
                end
                W.halo[k] = { orig = orig, fn = fn }
                HaloTextHelper[k] = fn
            end
        end
    end
end
function H.wrapOff()
    local W = S.w0
    if not W then return end
    if ZeD_ObjectCard.prerender == W.preFn then ZeD_ObjectCard.prerender = W.pre end
    if S.OC.ui.warn == W.warnFn then S.OC.ui.warn = W.warn end
    if ZeD.Molecules.drawNeedsLine == W.nlFn then ZeD.Molecules.drawNeedsLine = W.nl end
    if ZeD.Molecules.drawQuestionBand == W.qbFn then ZeD.Molecules.drawQuestionBand = W.qb end
    if ZeD.Atoms.drawSegFill == W.segFn then ZeD.Atoms.drawSegFill = W.seg end
    if ZeD.tr == W.trFn then ZeD.tr = W.tr end
    if W.plate and ZeD.Plate.draw == W.plateFn then ZeD.Plate.draw = W.plate end
    if W.ppreFn and ZeD_TwoWayFull.prerender == W.ppreFn then ZeD_TwoWayFull.prerender = W.ppre end
    for k, e in pairs(W.halo or {}) do if HaloTextHelper[k] == e.fn then HaloTextHelper[k] = e.orig end end
    S.w0 = nil
end
function H.wrapped()
    local W = S.w0
    if not W then return true end
    return ZeD_ObjectCard.prerender == W.pre and ZeD.tr == W.tr
end
function H.saidSince(t0)
    local o = {}
    for _, h in ipairs(S.halo) do if h.t >= (t0 or 0) then o[#o + 1] = h.text end end
    return o
end

-- ===================================================================== settings, pointer, pictures
function H.hidden(key)
    local o = ZeD.Settings and ZeD.Settings.hiddenActionsOption
    local i = nil
    for k, v in ipairs((ZeD.Settings and ZeD.Settings.hiddenActionsKeys) or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end); S.back.hidden = true end
end
function H.hiddenNow() local v = "?"; pcall(function() v = ZeD.Settings.hiddenActions() end); return v end
function H.hiddenBack()
    if not S.back.hidden then return end
    S.back.hidden = nil
    local o = ZeD.Settings and ZeD.Settings.hiddenActionsOption
    if o and S.found.hiddenIdx then pcall(function() o:setValue(S.found.hiddenIdx) end) end
end
function H.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return -9000 end
            getMouseY = function() return -9000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
-- queue: a picture once the World window and the card stand still (6 frames alike, 4 s at most)
function H.shot(name, what, gate)
    local st = { last = "", n = 0 }
    H.wait(4000, function()
        local w, c = RT.ww(), H.ocard()
        local k = tostring(w and math.floor(w:getWidth())) .. "/" .. tostring(w and math.floor(w._drawerEffW or 0)) .. "/" .. tostring(c and math.floor(c:getHeight()))
        if k == st.last then st.n = st.n + 1 else st.last, st.n = k, 0 end
        return st.n >= 6
    end, function() end)
    Q.step(1, function() if not S.dead and (gate == nil or gate()) then H.park(true) end end)
    Q.step(4, function()
        if S.dead or not (gate == nil or gate()) then H.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then S.shots[#S.shots + 1] = file; H.note("picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else H.note("the picture " .. name .. " was not taken: " .. tostring(e)) end
        H.park(false)
    end)
    Q.waitMs(1200)
end

-- ===================================================================== a building near home (the game's floors)
-- the game's own spread rule (SCampfireSystem.lowerFirelvl): a wood floor of floors_interior_tilesandwood (its grid
-- id 40 or more) or a carpet
function H.floorBurns(sq)
    local burns = false
    pcall(function()
        local floor = sq:getFloor()
        local spr = floor and floor:getSprite()
        local name = spr and spr:getName()
        local n = spr and spr:getSheetGridIdFromName()
        if name and n and n >= 0 then
            burns = (string.sub(name, 1, 28) == "floors_interior_tilesandwood" and n >= 40)
                or string.sub(name, 1, 22) == "floors_interior_carpet" or string.sub(name, 1, 6) == "carpet"
        end
    end)
    return burns
end
function H.indoorFree(sq)
    local ok = false
    pcall(function() ok = H.sqFree(sq) and sq:getRoom() ~= nil and not sq:isOutside() and sq:getBuilding() ~= nil end)
    return ok
end
-- the nearest indoor square with a free indoor square east or south of it to stand on (no wall between); for a fire,
-- the count of its spread targets (west, north, north-west: ZombRand(-1, 1) gives -1 or 0) the game can set alight
function H.findIndoor(radius)
    local f = S.found.pos
    local hx, hy, hz = math.floor(f.x), math.floor(f.y), 0
    local gen, fire = nil, nil
    for y = hy - radius, hy + radius do
        for x = hx - radius, hx + radius do
            local sq = H.sqXY(x, y, hz)
            if sq and H.indoorFree(sq) then
                local stand = nil
                for _, d in ipairs({ { 1, 0 }, { 0, 1 } }) do
                    local s2 = H.sqXY(x + d[1], y + d[2], hz)
                    local open = false
                    pcall(function() open = s2 ~= nil and not sq:isSomethingTo(s2) end)
                    if not stand and s2 and open and H.indoorFree(s2) then stand = s2 end
                end
                if stand then
                    local dist = math.abs(x - hx) + math.abs(y - hy)
                    if not gen or dist < gen.dist then gen = { sq = sq, stand = stand, dist = dist } end
                    local burn = 0
                    for _, d in ipairs({ { -1, 0 }, { 0, -1 }, { -1, -1 } }) do
                        local s3 = H.sqXY(x + d[1], y + d[2], hz)
                        if s3 and H.floorBurns(s3) then burn = burn + 1 end
                    end
                    local score = dist - burn * 1000
                    if not fire or score < fire.score then fire = { sq = sq, stand = stand, dist = dist, burn = burn, score = score } end
                end
            end
        end
    end
    return gen, fire
end

-- ===================================================================== a case's start and end
function H.legClean()
    H.speed(1)
    H.qstop()
    H.padOff()
    H.park(false)
    H.popClose()
    H.closeCard()
    H.hiddenBack()
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    S.caseMade = {}
    H.sweepNew()
    for i = (S.caseObjs or 0) + 1, #S.objs do if not S.objs[i].keep then H.rmObj(S.objs[i]) end end
    for i = (S.caseFires or 0) + 1, #S.fires do H.rmFire(S.fires[i]) end
    H.fireSweep()
    H.sweepFloor()
    H.elec(S.found.elec or 0)
    if S.back.recipe then H.recipeBack() end
    H.hands()
    H.lootRefresh()
end
function H.caseStart(T)
    S.caseMade = {}
    S.caseObjs = #S.objs
    S.caseFires = #S.fires
    S.halo = {}
    S.cardQLast = nil
    S.trSeen, S.trPop = {}, {}
    T.t0case = getTimestampMs()
    H.home()
    H.hidden("folded")
    return true
end
function H.caseEnd(label)
    H.step(2, function()
        H.legClean()
        H.home()
    end)
    H.step(10, function()
        local e1 = H.errN()
        H.errCheck(label .. ": no Lua error over the case", S.e0, e1)
        if S.zerr then Q.check(false, label .. ": nothing ZeD ran for the case threw", S.zerr); S.zerr = nil end
        S.e0 = e1
    end)
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        if not (S.F and S.F.focusWhere and ISTimedActionQueue and ISWorldObjectContextMenu and ISCampingMenu and ISBBQMenu and ISFluidContainerMenu
                and SCampfireSystem and CCampfireSystem and FluidContainer and FluidUtil) then
            S.dead = true
            Q.check(false, "setup: the pad's focus manager and the game's generator, camping, barbecue and fluid code are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "ocp_tab") end
        H.speed(1)
        H.qstop()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.pair = RT.isOpen()
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.inv0, f.types, f.stashed, f.floor0 = {}, {}, {}, {}
        for _, it in ipairs(H.all()) do
            f.inv0[it] = true
            local ft = H.ft(it)
            f.types[ft] = (f.types[ft] or 0) + 1
        end
        H.snapAt(f.pos.x, f.pos.y, f.pos.z)
        pcall(function() f.tod = getGameTime():getTimeOfDay() end)
        f.stats = {}
        for _, k in ipairs(S.STATS) do f.stats[k] = H.stat(k) end
        pcall(function() f.inst = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
        pcall(function() f.god = S.p:isGodMod() and true or false; S.p:setGodMod(true) end)
        pcall(function() f.invinc = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
        f.genRecipe = H.recipeInList("Generator")
        f.traits = {}
        for _, k in ipairs({ "ELECTRICIAN", "HANDY", "NUTRITIONIST" }) do f.traits[k] = H.hasTrait(k) end
        f.base, f.size = ZeD.currentBase, ZeD.currentSize
        f.hiddenIdx = H.optVal(ZeD.Settings and ZeD.Settings.hiddenActionsOption)
        S.lockWas = H.lockFound()
        H.xpSnap()
        f.elec = H.elecLvl()
        RT.pairOpen()
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        local cw, ww = RT.cw(), RT.ww()
        f.ctab, f.wtab = cw and cw._activeTab, ww and ww._activeTab
        f.faces = S.FP and S.FP.on and S.FP.on() or false
        f.recorded = true
        S.back.on = true
        H.wrapOn()
        local w0, m0 = H.weight()
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", screen " .. H.sizeTag() .. ", language " .. H.lang()
            .. ", Electricity " .. f.elec .. ", the Generator recipe " .. tostring(f.genRecipe) .. ", hidden actions " .. H.hiddenNow()
            .. ", input lock " .. tostring(S.lockWas) .. ", faces (Devices Immersive) " .. tostring(f.faces) .. ", World tab " .. tostring(f.wtab)
            .. ", carrying " .. H.n1(w0) .. " of " .. H.n1(m0) .. ", the sandbox fuel factor " .. tostring(SandboxVars and SandboxVars.GeneratorFuelConsumption)
            .. ", tainted water text " .. tostring(SandboxVars and SandboxVars.EnableTaintedWaterText) .. ", fire fuel max " .. tostring(getCampingFuelMax and getCampingFuelMax()))
    end)
    -- his own free things set aside (room for the game's moves; only what a case gives in the lists), the item types
    -- checked, a building near home found
    H.step(2, function()
        local moved, kept = H.asideAll()
        local w1, m1 = H.weight()
        H.note("setup: " .. moved .. " of his own free things set aside for the run (given back at the end); worn, held or on the belt stay: "
            .. H.list(kept, 10) .. "; now carrying " .. H.n1(w1) .. " of " .. H.n1(m1))
        local miss = {}
        for k, ft in pairs(S.FT) do if not H.known(ft) then miss[#miss + 1] = k .. " " .. ft end end
        Q.check(#miss == 0, "setup: every item type the cases use is known to this game", "unknown: " .. H.list(miss))
        local gen, fire = H.findIndoor(60)
        S.indoor = { gen = gen, fire = fire }
        S.sites = {}
        for _, s in ipairs({ gen, fire }) do
            if s then
                S.sites[#S.sites + 1] = { x = s.sq:getX(), y = s.sq:getY(), z = s.sq:getZ() }
                H.snapAt(s.sq:getX(), s.sq:getY(), s.sq:getZ())
            end
        end
        if not gen then S.indoorWhy = "no free indoor floor with room to stand beside it within 60 tiles of home (the loaded map)" end
        H.note("setup: indoor floor for the generator " .. (gen and (gen.sq:getX() .. "," .. gen.sq:getY() .. ", " .. gen.dist .. " tiles off") or "none")
            .. "; for the campfire " .. (fire and (fire.sq:getX() .. "," .. fire.sq:getY() .. ", " .. fire.burn .. " of its 3 spread targets burn by the game's rule") or "none"))
        H.lootRefresh()
    end)
    Q.waitMs(1000)
end

-- =====================================================================================================================
-- POWER
-- =====================================================================================================================
-- the fumes words: ZeD's warning, the game's toxic line
function H.fumesIn(s) return H.hasLc(s, ZeD.tr("UI_ZeD_Power_Fumes")) or H.hasLc(s, getText("IGUI_Generator_IsToxic")) end
function H.fumesInList(list) for _, s in ipairs(list or {}) do if H.fumesIn(s) then return true end end; return false end
function H.genInfo(g) H.zcall(function() ISWorldObjectContextMenu.onInfoGenerator(nil, g, S.pn) end) end

-- ===================================================================== PW1 fumes indoors
function C.pw1leg(T, how)
    local L = T.L .. " (" .. how .. ")"
    H.step(2, function()
        T.legOff = nil
        if T.off then return end
        H.closeCard(); H.popClose(); H.qstop(); H.padOff()
        pcall(function() T.gen:setActivated(false) end)
        H.goTo(T.site.stand:getX() + 0.5, T.site.stand:getY() + 0.5, T.site.sq:getZ())
        S.trPop, S.popAll, S.popTexts = {}, {}, nil
        T.t0 = getTimestampMs()
        T.slice = nil
        if how == "the Lights wheel" then
            local sl = H.lights()[2]
            T.slice = H.sliceWords(sl)
            if not (sl and sl.run) then T.legOff = true; Q.check(false, L .. ": the wheel's Generator slice can start it", T.slice); return end
            H.wheelTake(sl)
            return
        end
        if not (S.FP and S.FP.on and S.FP.on()) then T.legOff = true; Q.skip(L, "faces are off in this setup (Devices Simple or Lite): nothing pops out"); return end
        if how == "pop-out, mouse" then
            H.zcall(function() S.FP.worldClick(T.gen) end)            -- (a left click on the machine in the world)
            T.via = "a click on the machine (the game's click handler)"
        else
            if ISButtonPrompt and ISButtonPrompt.zedFacePop then
                H.zcall(function() ISButtonPrompt.zedFacePop({ player = S.pn }, T.gen) end)   -- (the pad's A at it: the Interact prompt's own call)
                T.via = "the pad's Interact A"
            else
                H.zcall(function() S.FP.toggle(S.p, T.gen) end)
                T.via = "FacePop.toggle (the Interact prompt's hook is not on)"
            end
        end
    end)
    H.wait(4000, function()
        if T.off or T.legOff or how == "the Lights wheel" or H.popHit("gen:engine") ~= nil then return true end
        -- (a click the game's handler did not pass on, the square not yet seen after the move: the card's own route
        -- to the same pop-out, said)
        if not T.fb and getTimestampMs() - T.t0 > 1800 then
            T.fb = true
            H.note(L .. ": " .. tostring(T.via) .. " popped nothing out in 1.8 s: the face opened by FacePop.toggle, the route the card's header button takes")
            H.zcall(function() S.FP.toggle(S.p, T.gen) end)
        end
        return false
    end, function(ok)
        T.fb = nil
        if T.off or T.legOff or how == "the Lights wheel" then return end
        if not ok then
            T.legOff = true
            Q.check(false, L .. ": the face pops out with its engine switch (" .. tostring(T.via) .. ")", "showing " .. tostring(H.popShowing(T.gen)) .. "; controls " .. H.popHits())
            return
        end
        if how == "pop-out, mouse" then H.popClick("gen:engine") else H.popPad("gen:engine") end
    end)
    H.wait(15000, function() return T.off or T.legOff or H.genOn(T.gen) end, function(ok)
        if T.off or T.legOff then return end
        H.speed(1)
        local said = H.saidSince(T.t0)
        local popWords = {}
        for s in pairs(S.popAll or {}) do popWords[#popWords + 1] = s end
        local told = H.fumesInList(said) or H.fumesInList(popWords) or (S.trPop.UI_ZeD_Power_Fumes ~= nil) or H.fumesIn(T.slice or "")
        if not Q.check(ok, L .. ": the press starts the generator (the game's ISActivateGenerator)", "queue " .. H.qkinds()) then return end
        Q.check(told, L .. " (PW1): started indoors, he is told about the fumes",
            "the game calls the square indoors " .. tostring(T.indoorGame) .. "; over his head: " .. H.list(said)
            .. "; the pop-out drew: " .. H.list(popWords, 20) .. "; the wheel's slice: " .. tostring(T.slice)
            .. "; the game's own Turn on tooltip warns " .. tostring(T.gameWarns) .. " (" .. tostring(T.gameTip) .. ")")
        pcall(function() T.gen:setActivated(false) end)
        H.popClose()
    end)
end
function C.pw1()
    local T = { L = "PW1 the fumes indoors" }
    H.step(2, function()
        H.caseStart(T)
        T.site = S.indoor and S.indoor.gen
        if not T.site then T.off = true; Q.skip(T.L, S.indoorWhy or "no indoor floor near home"); return end
        H.goTo(T.site.stand:getX() + 0.5, T.site.stand:getY() + 0.5, T.site.sq:getZ())
        local g = H.mkGen(T.site.sq, { fuel = 2, cond = 100, conn = true, on = false })
        if not g then T.off = true; Q.skip(T.L, "no generator could be laid on the indoor floor"); return end
        T.gen = g.obj
        pcall(function() T.indoorGame = (not T.site.sq:isOutside()) and T.site.sq:getBuilding() ~= nil end)
    end)
    Q.waitMs(1500)   -- (the square seen and the chunk settled after the move)
    H.step(2, function()
        if T.off then return end
        local m, err, own = H.gameMenu({ T.gen })
        local on = H.menuLike(own, getText("ContextMenu_Turn_On"))
        T.gameTip = on and on.tip or nil
        T.gameWarns = H.fumesIn(T.gameTip or "")
        H.note(T.L .. ": the game's menu on the indoor generator: " .. (H.ownMenuWhy(m, own, err) or H.menuNames(own, 14)))
        H.genInfo(T.gen)
    end)
    H.wait(4000, function() return T.off or H.cardOn("generator", T.gen) end, function(ok)
        if T.off then return end
        Q.check(ok and H.fumesInList(S.cardWarns), T.L .. " (the card, the control): indoors the card's body warns of the fumes",
            "the game calls it indoors " .. tostring(T.indoorGame) .. "; the card's warning boxes: " .. H.list(S.cardWarns))
        H.closeCard()
    end)
    C.pw1leg(T, "pop-out, mouse")
    C.pw1leg(T, "pop-out, pad")
    C.pw1leg(T, "the Lights wheel")
    H.caseEnd(T.L)
end

-- ===================================================================== PW2 the Lights wheel's pick
function C.pw2()
    local T = { L = "PW2 the Lights wheel's generator" }
    H.step(2, function()
        H.caseStart(T)
        local a = H.mkGen(H.freeSq(1, -5), { fuel = 2, cond = 100, conn = true })
        local b = H.mkGen(H.freeSq(1, 1), { fuel = 2, cond = 100, conn = true })
        if not (a and b) then T.off = true; Q.skip(T.L, "no room for two generators (5 tiles north and beside him) on the strip"); return end
        T.far, T.near = a.obj, b.obj
        T.dFar = math.sqrt(1.5 * 1.5 + 5 * 5)
    end)
    H.step(3, function()
        if T.off then return end
        local sl = H.lights()[2]
        T.w1 = H.sliceWords(sl)
        if not (sl and sl.run) then T.off = true; Q.check(false, T.L .. ": the slice can start a generator", T.w1); return end
        H.wheelTake(sl)
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        Q.check(H.genOn(T.near) and not H.genOn(T.far), T.L .. " (PW2): Turn on starts the nearest generator",
            "the slice said '" .. T.w1 .. "'; the game started the one beside him " .. tostring(H.genOn(T.near)) .. ", the one 5 tiles north (first in reading order) " .. tostring(H.genOn(T.far)))
        pcall(function() T.near:setActivated(true); T.far:setActivated(true) end)
        H.home()
    end)
    H.step(3, function()
        if T.off then return end
        local sl = H.lights()[2]
        T.w2 = H.sliceWords(sl)
        if sl and sl.run then H.wheelTake(sl) end
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        Q.check(not H.genOn(T.near) and H.genOn(T.far), T.L .. " (PW2): Turn off stops the nearest generator",
            "the slice said '" .. tostring(T.w2) .. "'; the one beside him still on " .. tostring(H.genOn(T.near)) .. ", the one 5 tiles north still on " .. tostring(H.genOn(T.far)))
        pcall(function() T.near:setActivated(false); T.far:setActivated(false) end)
        H.home()
        H.genInfo(T.near)
    end)
    H.wait(3000, function() return T.off or H.cardOn("generator", T.near) end, function(ok)
        if T.off then return end
        local e = H.entry()
        H.note(T.L .. ": the card on the one beside him browses " .. tostring(e and e.list and #e.list) .. " generators in reach (arrows " .. tostring(H.zone("oc:next") ~= nil) .. ")")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== PW3 Disconnect without the skill
function C.pw3()
    local T = { L = "PW3 Disconnect at Electricity 0" }
    H.step(2, function()
        H.caseStart(T)
        H.elec(0)
        H.recipeOff("Generator")
        if H.recipeKnown("Generator") then T.off = true; Q.skip(T.L, "he still knows the Generator recipe at Electricity 0 (his profession): the card would allow it"); return end
        local g = H.mkGen(H.firstFree(S.RING2), { fuel = 2, cond = 100, conn = true })
        if not g then T.off = true; Q.skip(T.L, "no square for a generator"); return end
        T.gen = g.obj
        local m, err, own = H.gameMenu({ T.gen })
        T.gameDis = H.menuLike(own, getText("ContextMenu_GeneratorUnplug"))
        T.gameMenu = H.menuNames(own, 14)
        T.gameWhy = H.ownMenuWhy(m, own, err)
        H.genInfo(T.gen)
    end)
    H.wait(4000, function() return T.off or H.cardOn("generator", T.gen) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the game's Info opens the card on it") then T.off = true; return end
        T.cardDis = H.lit("oc:verb:plug")
        T.hv = H.zone("oc:hv:plug") ~= nil
        T.outlet = H.lit("gen:outlet")
        if T.gameWhy then
            Q.skip(T.L .. " (PW3): the card offers Disconnect where the game's menu does", T.gameWhy)
        else
            Q.check(T.gameDis == nil or T.gameDis.na or T.cardDis or T.outlet, T.L .. " (PW3): the card offers Disconnect where the game's menu does",
                "the game's menu on the generator: " .. T.gameMenu .. "; Disconnect " .. tostring(T.gameDis and (T.gameDis.na and "grey" or "offered") or "not listed")
                .. "; the card: the verb live " .. tostring(T.cardDis) .. ", folded away " .. tostring(T.hv) .. ", the outlet live " .. tostring(T.outlet) .. "; Electricity " .. H.elecLvl())
        end
        T.k0 = H.qkinds()
        H.cardClick("gen:outlet", T.L)
        H.hidden("all")
    end)
    H.clickQ(T, "oc:verb:plug", T.L .. " (mouse, the greyed verb)")
    H.padPress(T, "oc:verb:plug", T.L)
    H.step(10, function()
        H.padOff()
        if T.off then return end
        T.n = H.qcount("ISPlugGenerator")
        H.note(T.L .. ": the card's presses (the outlet and Disconnect by the mouse, Disconnect by the pad) queued " .. T.n
            .. " ISPlugGenerator; connected " .. tostring(H.genConn(T.gen)) .. "; the NEEDS lines: " .. H.list(S.cardNeeds))
        H.qstop()
        H.closeCard()
        -- the game's own Disconnect at Electricity 0
        H.gcall("the game's Disconnect", function() ISWorldObjectContextMenu.onPlugGenerator(nil, T.gen, S.pn, false) end)
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        Q.check(not H.genConn(T.gen), T.L .. ": the game's own Disconnect runs at Electricity 0 (ISPlugGenerator has no skill check)", "connected " .. tostring(H.genConn(T.gen)))
        H.genInfo(T.gen)
    end)
    H.wait(3000, function() return T.off or H.cardOn("generator", T.gen) end, function(ok)
        if T.off then return end
        H.note(T.L .. ": disconnected, the card's Take is live " .. tostring(H.lit("oc:verb:take")) .. " (it waited on Disconnect)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== PW4 a broken generator, a failed start
function C.pw4press(T, how)
    local L = T.L .. " (" .. how .. ")"
    H.step(2, function()
        T.pOff = nil
        if T.off then return end
        pcall(function() T.gen:setActivated(false); T.gen:setCondition(0) end)
        T.tp = getTimestampMs()
        S.cardQLast = nil
        if not H.lit("oc:verb:power") then T.pOff = true; Q.skip(L, "the card offers no live Turn on at condition 0: nothing to press"); return end
        if how == "mouse" then H.cardClick("oc:verb:power", L) end
    end)
    if how == "pad" then H.padPress(T, "oc:verb:power", L, "goPad", function() return not T.pOff end) end
    H.step(3, function() H.padOff(); if not T.off then T.kq = H.qkinds() end end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off or T.pOff then return end
        local said = H.saidSince(T.tp)
        Q.check(not H.genOn(T.gen) and (#said > 0 or S.cardQLast ~= nil), L .. " (PW4): a Turn on the game refuses at condition 0 says why",
            "the game's queue after the press " .. tostring(T.kq) .. "; on " .. tostring(H.genOn(T.gen)) .. "; over his head: " .. H.list(said)
            .. "; the card's question " .. tostring(S.cardQLast) .. "; its NEEDS lines " .. H.list(S.cardNeeds))
    end)
end
function C.pw4try(T, i)
    H.step(2, function()
        if T.off then return end
        pcall(function() T.gen:setActivated(false); T.gen:setCondition(50) end)
        T.tp = getTimestampMs()
        H.cardClick("oc:verb:power", T.L .. " (condition 50)")
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        local on = H.genOn(T.gen)
        T.rolls[#T.rolls + 1] = (on and "started" or "failed") .. " (said: " .. H.list(H.saidSince(T.tp)) .. ")"
        if not on then T.fails = T.fails + 1 end
        pcall(function() T.gen:setActivated(false) end)
    end)
end
function C.pw4()
    local T = { L = "PW4 a broken generator" }
    H.step(2, function()
        H.caseStart(T)
        H.elec(3)
        local g = H.mkGen(H.firstFree(S.RING2), { fuel = 2, cond = 0, conn = true })
        if not g then T.off = true; Q.skip(T.L, "no square for a generator"); return end
        T.gen = g.obj
        T.rolls, T.fails = {}, 0
        H.genInfo(T.gen)
    end)
    H.wait(4000, function() return T.off or H.cardOn("generator", T.gen) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the game's Info opens the card on it") then T.off = true; return end
        local c = H.ocard()
        T.main = c and c._mainFid
        Q.check(not H.lit("oc:verb:power"), T.L .. " (PW4): at condition 0 the card does not offer Turn on (the game's ISActivateGenerator refuses at 0)",
            "Turn on live " .. tostring(H.lit("oc:verb:power")) .. ", the card's main verb " .. tostring(T.main) .. "; the condition row: " .. H.drewAll("%", 4)
            .. "; the game's condition " .. tostring(H.genCond(T.gen)))
    end)
    C.pw4press(T, "mouse")
    C.pw4press(T, "pad")
    C.pw4try(T, 1)
    C.pw4try(T, 2)
    C.pw4try(T, 3)
    H.step(2, function()
        if T.off then return end
        H.note(T.L .. ": three starts at condition 50 by the mouse: " .. T.fails .. " failed by the game's roll (ZombRand(2)): " .. H.list(T.rolls)
            .. "; the card's condition row then: " .. H.drewAll("%", 4))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== PW5 Fix spends every scrap
function C.pw5fix(T, how, cond, scrap)
    local L = T.L .. " (" .. how .. ", " .. cond .. "% with " .. scrap .. " scrap)"
    H.step(2, function()
        if T.off then return end
        H.closeCard(); H.qstop()
        pcall(function() T.gen:setActivated(false); T.gen:setCondition(cond) end)
        for _, it in ipairs(T.scrap or {}) do H.removeItem(it) end
        T.scrap = {}
        for _ = 1, scrap do T.scrap[#T.scrap + 1] = H.give(S.FT.scrap) end
        H.genInfo(T.gen)
    end)
    H.wait(4000, function() return T.off or (H.cardOn("generator", T.gen) and H.lit("oc:verb:fix")) end, function(ok)
        T.fixOff = nil
        if T.off then return end
        if not Q.check(ok, L .. ": Fix is live on the card", "zones " .. H.zoneIds("oc:")) then T.fixOff = true; return end
        T.s0, T.c0 = H.count(S.FT.scrap), H.genCond(T.gen)
        local z = H.zone("oc:verb:fix")
        T.words = H.cardWords(60) .. " | its help line: " .. tostring(z and z.help)
        local scrapName = "scrap"
        pcall(function() scrapName = H.lc(getScriptManager():FindItem(S.FT.scrap):getDisplayName()) end)
        T.told = false
        for _, t in ipairs(S.cardTexts or {}) do if H.has(H.lc(t.s), scrapName) and string.find(t.s, "%d") then T.told = true end end
        if z and z.help and string.find(tostring(z.help), "%d") then T.told = true end
        if how == "mouse" then H.cardClick("oc:verb:fix", L) end
    end)
    if how == "pad" then H.padPress(T, "oc:verb:fix", L, "goPad", function() return not T.fixOff end) end
    H.step(2, function() H.padOff() end)
    H.waitQ(T, 150000, 3)
    H.step(2, function()
        if T.off or T.fixOff then return end
        local spent, c1 = (T.s0 or 0) - H.count(S.FT.scrap), H.genCond(T.gen)
        Q.check(spent <= 1 or T.told, L .. " (PW5): a Fix that spends more than one piece says how many first",
            "the game's chain spent " .. spent .. " of " .. tostring(T.s0) .. " Scrap Electronics (his inventory), condition " .. tostring(T.c0) .. " -> " .. tostring(c1)
            .. " (+4 + Electricity/2 a piece); the card's words before the press: " .. tostring(T.words))
    end)
end
function C.pw5()
    local T = { L = "PW5 Fix" }
    H.step(2, function()
        H.caseStart(T)
        H.elec(3)
        local g = H.mkGen(H.firstFree(S.RING2), { fuel = 2, cond = 60, conn = false })
        if not g then T.off = true; Q.skip(T.L, "no square for a generator"); return end
        T.gen = g.obj
    end)
    C.pw5fix(T, "mouse", 60, 10)
    C.pw5fix(T, "pad", 90, 2)
    -- the NEEDS line at Electricity 2 against the game's own tooltip
    H.step(2, function()
        if T.off then return end
        H.closeCard()
        H.elec(2)
        pcall(function() T.gen:setCondition(80) end)
        for _, it in ipairs(T.scrap or {}) do H.removeItem(it) end
        T.scrap = { H.give(S.FT.scrap) }
        H.hidden("all")
        local m, err, own = H.gameMenu({ T.gen })
        local fix = H.menuLike(own, getText("ContextMenu_GeneratorFix"))
        T.gameFixTip = fix and (tostring(fix.tip) .. (fix.na and " (grey)" or "")) or (H.ownMenuWhy(m, own, err) or "no Fix in the game's menu on the generator")
        H.genInfo(T.gen)
    end)
    H.wait(4000, function() return T.off or (H.cardOn("generator", T.gen) and #(S.cardNeeds or {}) > 0) end, function(ok)
        if T.off then return end
        H.note(T.L .. ": at Electricity 2 the card's NEEDS lines: " .. H.list(S.cardNeeds) .. "; the game's own Fix tooltip: " .. tostring(T.gameFixTip)
            .. " (the game's ContextMenu_GeneratorPlugTT names the profession and the magazine: \"" .. getText("ContextMenu_GeneratorPlugTT") .. "\")")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== PW7 one can at a time
function C.pw7()
    local T = { L = "PW7 Add fuel" }
    H.step(2, function()
        H.caseStart(T)
        local g = H.mkGen(H.firstFree(S.RING2), { fuel = 0, cond = 100, conn = true })
        if not g then T.off = true; Q.skip(T.L, "no square for a generator"); return end
        T.gen = g.obj
        T.petrol = H.fluid("Petrol")
        T.cans = { H.give(S.FT.can), H.give(S.FT.can) }
        for _, it in ipairs(T.cans) do H.fill(H.fcOf(it), { { T.petrol, 3 } }) end
        T.max = H.call(T.gen, "getMaxFuel") or 10
        local m, err, own = H.gameMenu({ T.gen })
        T.gameAll = H.menuLike(own, getText("ContextMenu_GeneratorAddFuel") .. " > " .. getText("ContextMenu_AddAll"))
        T.gameMenu = H.menuNames(own, 16)
        T.gameWhy = H.ownMenuWhy(m, own, err)
        H.genInfo(T.gen)
    end)
    H.wait(4000, function() return T.off or (H.cardOn("generator", T.gen) and H.zone("gen:can:2") ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": off and empty, the card lists both cans", "zones " .. H.zoneIds("gen:")) then T.off = true; return end
        local all = false
        local c = H.ocard()
        for _, z in ipairs((c and c._zones) or {}) do
            local id = tostring(z.fid)
            if string.sub(id, 1, 4) == "gen:" and not string.find(id, "^gen:can:%d+$") and id ~= "gen:engine" and id ~= "gen:outlet" then all = true end
            -- (fix/cards2, Nov 26 2026: Add All is a header verb, oc:verb:fuelall, with the game's ContextMenu_AddAll)
            if id == "oc:verb:fuelall" then all = true end
        end
        if T.gameWhy then
            Q.skip(T.L .. " (PW7): the card has one press for every can, as the game's Add all", T.gameWhy)
        else
            Q.check(T.gameAll == nil or all, T.L .. " (PW7): the card has one press for every can, as the game's Add all",
                "the game's menu on the generator: " .. T.gameMenu .. "; the card's can rows: " .. H.zoneIds("gen:can") .. "; its verbs: " .. H.zoneIds("oc:verb"))
        end
        H.note("PW10: the can rows' gain words as drawn: " .. H.drewAll("+", 4) .. " (built in code: \"+%.1f L\")")
    end)
    H.clickQ(T, "gen:can:1", T.L .. " (mouse, the first can)")
    H.step(2, function()
        if T.off then return end
        T.k1 = H.qkinds()
        T.act1 = H.qfind("ISAddFuel")
    end)
    H.padPress(T, "gen:can:2", T.L .. " (the second can, while the first pours)", "goPad")
    H.step(3, function()
        H.padOff()
        if T.off then return end
        T.nAdd = H.qcount("ISAddFuel")
        T.k2 = H.qkinds()
        T.act2 = H.qfind("ISAddFuel")
    end)
    H.waitQ(T, 60000)
    H.step(2, function()
        if T.off then return end
        local fuel = H.genFuel(T.gen) or 0
        local want = math.min(6, T.max)
        -- which can each queued pour holds (the game's ISAddFuel .petrol)
        local function canNo(a)
            if not a then return "none" end
            for i, it in ipairs(T.cans) do if a.petrol == it then return "can " .. i end end
            return "another can"
        end
        local L2 = T.L .. " (PW7): the second can's Add pressed while the first pours runs too (both cans' petrol in)"
        local what = "after the first press the game's queue " .. tostring(T.k1) .. " (its pour: " .. canNo(T.act1) .. "); after the second " .. tostring(T.k2)
            .. " (its pours: " .. tostring(T.nAdd) .. ", " .. canNo(T.act2) .. "); the generator's fuel " .. H.n2(fuel) .. " (want " .. H.n2(want) .. ")"
        if not T.act1 then
            Q.skip(L2, "the first press queued no pour: " .. what)
        elseif T.act2 == T.act1 then
            Q.skip(L2, "the second press reached nothing (the pad's focus took " .. tostring(T.goPad) .. "; the first pour still the queue's own): " .. what)
        else
            -- the card's row calls the game's doAddFuelGenerator, whose luautils.walkAdj clears the queue first: the
            -- second press drops the first can's pour (the game's own Add One twice does the same; its Add All queues
            -- both)
            Q.check(math.abs(fuel - want) < 0.05, L2, what .. ((T.act2 and (T.nAdd or 0) <= 1) and "; the second press replaced the first can's pour (the row runs the game's doAddFuelGenerator, whose walkAdj clears the queue)" or ""))
        end
        -- a can of petrol and water: its liquid as fuel
        H.closeCard()
        pcall(function() T.gen:setFuel(0) end)
        for _, it in ipairs(T.cans) do H.removeItem(it) end
        T.mix = H.give(S.FT.can)
        H.fill(H.fcOf(T.mix), { { T.petrol, 1 }, { H.fluid("Water"), 1 } })
        local fc = H.fcOf(T.mix)
        T.mixP, T.mixW = H.part(fc, T.petrol), H.part(fc, H.fluid("Water"))
        H.genInfo(T.gen)
    end)
    H.wait(4000, function() return T.off or (H.cardOn("generator", T.gen) and H.zone("gen:can:1") ~= nil) end, function(ok)
        T.mixOff = nil
        if T.off then return end
        if not ok or T.mixW < 0.01 then
            T.mixOff = true
            H.note(T.L .. ": a can of petrol and water: the game's can took petrol " .. H.n2(T.mixP) .. " and water " .. H.n2(T.mixW) .. "; card row " .. tostring(ok) .. ": not run")
            return
        end
        T.rowMix = H.rowWords("gen:can:1")
    end)
    H.clickQ(T, "gen:can:1", T.L .. " (the mixed can)", nil, function() return not T.mixOff end)
    H.waitQ(T, 40000)
    H.step(2, function()
        if T.off or T.mixOff then return end
        H.note(T.L .. ": the can of " .. H.n2(T.mixP) .. " L petrol and " .. H.n2(T.mixW) .. " L water: the card's row '" .. tostring(T.rowMix)
            .. "'; the game's ISAddFuel put " .. H.n2(H.genFuel(T.gen)) .. " L in (all its liquid counts as fuel, as the game: AF:54)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== PW8 the run time against the game's burn
function H.hoursOf(s)
    if not s then return nil end
    local h, m = string.match(s, "(%d+):(%d+)")
    if h then return tonumber(h) + tonumber(m) / 60 end
    local d = string.match(s, "(%d+)")
    if d and (H.hasLc(s, ZeD.tr("UI_ZeD_Power_Days", "")) or H.hasLc(s, "day")) then return tonumber(d) * 24 end
    return nil
end
function C.pw8phase(T, label, stoveOn)
    H.step(2, function()
        T.ph = nil
        if T.off then return end
        if T.stove and stoveOn then pcall(function() if not T.stove.obj:Activated() then T.stove.obj:Toggle() end end) end
        H.lootRefresh()
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        -- the fuel set so the run time reads in hours (under 100)
        local tot = H.call(T.gen, "getTotalPowerUsing") or 0
        local fuel = math.max(0.3, math.min(5, tot * 50))
        pcall(function() T.gen:setFuel(fuel) end)
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        local label2 = ZeD.tr("UI_ZeD_Power_RunTimeLeft")
        local v = H.valueRight(ZeD.Atoms.textCase and ZeD.Atoms.textCase(label2) or label2) or H.valueRight(label2)
        -- (the plain card, Simple or Lite: the run time in large type, "33:20", its label above)
        if not v then for _, t in ipairs(S.cardTexts or {}) do if string.match(t.s, "^%s*%d+:%d%d") then v = t.s end end end
        T.ph = { drawn = v, hrs = H.hoursOf(v), f0 = H.genFuel(T.gen), h0 = H.worldH(), tot = H.call(T.gen, "getTotalPowerUsing"),
                 base = H.call(T.gen, "getBasePowerConsumption"), totS = H.call(T.gen, "getTotalPowerUsingString"), st = S.genSt,
                 powered = T.stove and H.powered(T.stove.obj) }
        H.speed(3)
    end)
    H.wait(120000, function() return T.off or not T.ph or H.worldH() - T.ph.h0 >= 2 end, function(ok)
        H.speed(1)
        if T.off or not T.ph then return end
        local ph = T.ph
        ph.f1, ph.h1 = H.genFuel(T.gen), H.worldH()
        local dh = ph.h1 - ph.h0
        ph.rate = (dh > 0) and ((ph.f0 - ph.f1) / dh) or nil
        local implied = (ph.hrs and ph.hrs > 0) and (ph.f0 / ph.hrs) or nil
        local okR = ph.rate ~= nil and ph.rate > 0 and implied ~= nil and math.abs(implied - ph.rate) <= 0.2 * ph.rate
        Q.check(okR, T.L .. " (PW8, " .. label .. "): the card's run time left matches the game's own burn over " .. H.n1(dh) .. " game hours",
            "the card drew '" .. tostring(ph.drawn) .. "' (" .. H.n2(ph.hrs) .. " h for " .. H.n3(ph.f0) .. " L: " .. H.n3(implied) .. " L/h); the game burnt "
            .. H.n3(ph.f0 - (ph.f1 or 0)) .. " L (" .. H.n3(ph.rate) .. " L/h); its getTotalPowerUsing " .. H.n3(ph.tot) .. " (\"" .. tostring(ph.totS) .. "\"), base " .. H.n3(ph.base)
            .. (stoveOn and ("; the range powered " .. tostring(ph.powered)) or ""))
        T[label] = ph
    end)
end
function C.pw8()
    local T = { L = "PW8 readings" }
    H.step(2, function()
        H.caseStart(T)
        local g = H.mkGen(H.firstFree(S.RING2), { fuel = 2, cond = 100, conn = true, on = true })
        T.stove = H.mkStove(H.firstFree(S.NEAR))
        if not g then T.off = true; Q.skip(T.L, "no square for a generator"); return end
        T.gen = g.obj
        H.genInfo(T.gen)
    end)
    H.wait(5000, function() return T.off or (H.cardOn("generator", T.gen) and H.drew(ZeD.tr("UI_ZeD_Power_RunTimeLeft")) ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the card on the running generator draws its run time left", "words " .. H.cardWords(20)) then T.off = true end
    end)
    H.shot("ocp_power_" .. H.sizeTag(), "the Power card: a running generator outdoors (its face, run time, fuel, condition, what it powers)", function() return not T.off end)
    C.pw8phase(T, "idle", false)
    C.pw8phase(T, "the range on", true)
    H.step(2, function()
        if T.off then return end
        local a, b = T["idle"], T["the range on"]
        local fac = tonumber(SandboxVars and SandboxVars.GeneratorFuelConsumption) or 1
        local st = b and b.st
        local extra = (a and b and a.rate and b.rate) and (b.rate - a.rate) or nil
        H.note(T.L .. ": the load needle drawn at " .. H.n2(st and st.load) .. " of full (overload " .. tostring(st and st.overload) .. ") with the range on; the game's burn above idle "
            .. H.n3(extra) .. " L/h; ZeD's full scale 0.5 L/h above idle, divided by the sandbox factor " .. tostring(fac) .. " (needle at the game's burn: " .. H.n2(extra and (extra / fac / 0.5)) .. ")")
        H.note(T.L .. ": the meters drawn 120 V " .. tostring(st and st.volts) .. ", 60 Hz " .. tostring(st and st.hz) .. ", the OIL lamp " .. tostring(st and st.service)
            .. " at condition " .. tostring(H.genCond(T.gen)) .. " (ZeD's own: under 25); the game's condition bands are its own (IsoGenerator)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== PW9 reach (far; seated in the seated case)
function H.walking() for _, a in ipairs(H.queue()) do local ty = tostring(a.Type); if H.has(ty, "Walk") or H.has(ty, "PathFind") then return true end end; return false end
-- the object's square for the reach legs: free (FL7's collector stood on the first free RING2 square), with loaded
-- floor he can stand on 2, 7 and 15 tiles east of it (the legs stand there); home's west square, the first run's
-- only try, held things earlier runs left
S.REACH = { { -2, 0 }, { -2, -2 }, { -2, 2 }, { -3, 0 }, { -3, -1 }, { -3, 1 }, { 0, -2 }, { 0, 2 }, { -4, 0 }, { -2, -3 }, { -2, 3 },
            { -5, 0 }, { -5, -2 }, { -5, 2 }, { 2, -2 }, { 2, 2 }, { 0, -4 }, { 0, 4 }, { -6, -4 }, { -6, 4 }, { -8, 0 }, { -8, -3 }, { -8, 3 } }
function H.reachSq()
    local f = S.found.pos
    if not f then return nil end
    local hx, hy, hz = math.floor(f.x), math.floor(f.y), math.floor(f.z)
    for _, o in ipairs(S.REACH) do
        local x, y = hx + o[1], hy + o[2]
        local sq = H.sqXY(x, y, hz)
        if sq and H.sqFree(sq) and not H.used(sq) then
            local all = true
            for _, e in ipairs({ 2, 7, 15 }) do
                local st = H.sqXY(x + e, y, hz)
                local good = false
                pcall(function() good = st ~= nil and st:getFloor() ~= nil and st:isFree(false) and st:getVehicleContainer() == nil end)
                if not good or H.used(st) then all = false end
            end
            if all then return sq end
        end
    end
    return nil
end
-- queue: stand d tiles east of the object's square, run open(), 1.5 s later: shown(), or a walk queued
function C.reachLeg(T, d, open, shown)
    local L = T.L .. " (" .. d .. " tiles)"
    H.step(2, function()
        T.rOff = nil
        if T.off then return end
        H.closeCard(); H.qstop()
        local sq = T.sq
        local stand = H.sqXY(sq:getX() + d, sq:getY(), sq:getZ())
        if not (stand and stand:getFloor()) then T.rOff = true; Q.skip(L, "no loaded floor " .. d .. " tiles east"); return end
        H.goTo(sq:getX() + d + 0.5, sq:getY() + 0.5, sq:getZ())
    end)
    Q.waitMs(400)
    H.step(1, function() if not (T.off or T.rOff) then open() end end)
    Q.waitMs(1500)
    H.step(1, function()
        if T.off or T.rOff then return end
        local s, walk = shown(), H.walking()
        if d <= 2 then
            Q.check(s, L .. ": the card opens and stays", "kind " .. tostring(H.kind()) .. "; closed for " .. tostring(ZeD_WorldWindow._closeWhy))
        else
            Q.check(s or walk, L .. ": from " .. d .. " tiles the press shows the card or walks there, as the game's own does",
                "card " .. tostring(H.kind()) .. ", the queue " .. H.qkinds() .. "; ZeD's last close: " .. tostring(ZeD_WorldWindow._closeWhy))
        end
        H.qstop()
        H.home()
    end)
end
function C.pw9()
    local T = { L = "PW9 Info from far off" }
    H.step(2, function()
        H.caseStart(T)
        local g = H.mkGen(H.reachSq(), { fuel = 2, cond = 100, conn = true })
        if not g then T.off = true; Q.skip(T.L, "no free square near home with loaded floor to stand on 2, 7 and 15 tiles east of it"); return end
        T.gen, T.sq = g.obj, g.sq
    end)
    for _, d in ipairs({ 2, 7, 15 }) do
        C.reachLeg(T, d, function() H.genInfo(T.gen) end, function() return H.kind() == "generator" and H.entry().t.obj == T.gen end)
    end
    H.caseEnd(T.L)
end

-- =====================================================================================================================
-- FLUID
-- =====================================================================================================================
function H.colReady() return S.col ~= nil and S.col.fc ~= nil end
function H.colFill(amt) if H.colReady() then H.fill(S.col.fc, { { H.fluid("Water"), amt or 50 } }) end end
function H.colNames()
    local o = {}
    if not H.colReady() then return o end
    pcall(function() local n = S.col.fc:getTranslatedContainerName(); if n and n ~= "" then o[#o + 1] = n end end)
    pcall(function() local n = S.col.master:getTileName(); if n and n ~= "" then o[#o + 1] = n end end)
    pcall(function() local n = S.col.master:getEntityDisplayName(); if n and n ~= "" then o[#o + 1] = n end end)
    return o
end
function H.namesIn(s, names) for _, n in ipairs(names or {}) do if H.hasLc(s, n) then return true end end; return false end
function H.openItemFluid(it, info) H.zcall(function() ISFluidContainerMenu.showUI(S.p, H.fcOf(it), info and ISFluidInfoUI or ISFluidTransferUI) end) end
function H.openWorldFluid(fc, info)
    H.zcall(function()
        if info then ISWorldObjectContextMenu.onFluidInfo(S.pn, fc) else ISWorldObjectContextMenu.onFluidTransfer(S.pn, fc) end
    end)
end
function H.intoFid(it) local id = nil; pcall(function() id = it:getID() end); return "fl:into:i" .. tostring(id) end
function H.colOnCard() local t = H.tt(); return H.kind() == "fluid" and t ~= nil and t.pinned ~= nil and S.cardT ~= nil and getTimestampMs() - S.cardT < 400 end

function C.flStart()
    H.step(2, function()
        H.home()
        local sq = H.firstFree(S.RING2)
        local b, why = nil, "no free square two tiles from home"
        if sq then b, why = H.build("Base.RainCollector", sq, "the rain collector") end
        if b and b.fc then
            for _, c in ipairs(b.parts) do c.keep = true end
            S.col = b
            H.colFill(50)
            H.note("fluid: a rain collector built at " .. sq:getX() .. "," .. sq:getY() .. " (" .. #b.parts .. " objects), " .. H.n1(H.amt(b.fc)) .. " L of water in it")
        else
            S.noCol = "no rain collector could be built (" .. tostring(why) .. ")"
            if b then H.rmBuilt(b) end
            H.note("fluid: " .. S.noCol)
        end
    end)
end
function C.flEnd()
    H.step(2, function() H.closeCard(); if S.col then H.rmBuilt(S.col) end end)
end

-- ===================================================================== FL1 tainted water
function C.fl1leg(T, spec)
    local L = T.L .. " (" .. spec.label .. ")"
    H.step(2, function()
        T.lOff = nil
        if T.off then return end
        H.closeCard()
        T.it = H.give(spec.ft)
        local fc = H.fcOf(T.it)
        if not (fc and T.tw) then T.lOff = true; Q.skip(L, "no container or no tainted water in this game"); return end
        local parts = {}
        if spec.t > 0 then parts[#parts + 1] = { T.tw, spec.t } end
        if spec.w > 0 then parts[#parts + 1] = { T.water, spec.w } end
        H.fill(fc, parts)
        T.fc = fc
        pcall(function() T.known = fc:isTaintedStatusKnown() and true or false end)
        pcall(function() T.tainted = fc:isTainted() and true or false end)
        pcall(function() T.poison = tostring(fc:getPoisonEffect()) end)
        H.openItemFluid(T.it, true)
    end)
    H.wait(4000, function() return T.off or T.lOff or H.cardFluid(T.it) end, function(ok)
        if T.off or T.lOff then return end
        if not Q.check(ok, L .. ": its Show info opens the fluid card on it", "kind " .. tostring(H.kind())) then return end
        -- (the card's own tag is the word alone; the game's item name may carry it too, so only an exact tag counts)
        local tw = getText("Tooltip_tainted")
        local shown = H.drewEq(tw) > 0
        Q.check(shown == (T.known == true), L .. " (FL1): the card says Tainted exactly when the game knows it is (isTaintedStatusKnown)",
            "the game: known " .. tostring(T.known) .. ", tainted " .. tostring(T.tainted) .. ", poison " .. tostring(T.poison) .. ", " .. H.n2(H.part(T.fc, T.tw)) .. " L tainted + "
            .. H.n2(H.part(T.fc, T.water)) .. " L water; the card drew Tainted " .. tostring(shown) .. " (" .. H.drewAll(tw, 4) .. "); its words: " .. H.cardWords(16))
        H.closeCard()
        if not spec.keep then H.removeItem(T.it) else T.kept = T.it end
    end)
end
function C.fl1()
    local T = { L = "FL1 tainted water" }
    H.step(2, function()
        H.caseStart(T)
        T.tw, T.water = H.fluid("TaintedWater"), H.fluid("Water")
    end)
    C.fl1leg(T, { label = "0.5 L tainted in a bottle", ft = S.FT.bottle, t = 0.5, w = 0, keep = true })
    C.fl1leg(T, { label = "1.5 L tainted in a pop bottle", ft = S.FT.pop, t = 1.5, w = 0 })
    C.fl1leg(T, { label = "a 1:9 mix of water and tainted water", ft = S.FT.bottle, t = 0.81, w = 0.09 })
    C.fl1leg(T, { label = "a 9:1 mix of water and tainted water", ft = S.FT.bottle, t = 0.09, w = 0.81 })
    -- the 0.5 L bottle drunk the game's way
    H.step(2, function()
        if T.off or not T.kept then return end
        T.p0, T.s0 = H.stat("POISON"), H.stat("SICKNESS")
        T.bd = nil; pcall(function() T.bd = S.p:getBodyDamage() end)
        T.bd0 = H.call(T.bd, "getPoisonLevel")   -- (gone from BodyDamage in 42.2x: the poison is the POISON stat; nil then)
        H.gcall("the game's drink", function() ISInventoryPaneContextMenu.onDrinkFluid(T.kept, 1, S.p) end)
    end)
    H.waitQ(T, 30000)
    H.step(2, function()
        if T.off or not T.kept then return end
        local bd1 = H.call(T.bd, "getPoisonLevel")
        H.note(T.L .. ": the 0.5 L of tainted water drunk the game's way: the bottle holds " .. H.n2(H.amt(H.fcOf(T.kept))) .. " L after; poison stat "
            .. H.n2(T.p0) .. " -> " .. H.n2(H.stat("POISON")) .. ", sickness " .. H.n2(T.s0) .. " -> " .. H.n2(H.stat("SICKNESS")) .. ", the body's poison level "
            .. H.n2(T.bd0) .. " -> " .. H.n2(bd1) .. " (god mode on for the run)")
        H.statsBack()
        if T.bd0 ~= nil then H.call(T.bd, "setPoisonLevel", T.bd0) end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FL2 Empty after Switch
function C.fl2()
    local T = { L = "FL2 Empty empties the left side" }
    H.step(2, function()
        H.caseStart(T)
        if not H.colReady() then T.off = true; Q.skip(T.L, S.noCol or "no rain collector"); return end
        H.colFill(50)
        T.b = H.give(S.FT.bottle)
        H.fill(H.fcOf(T.b), { { H.fluid("Water"), 0.5 } })
        T.c0 = H.amt(S.col.fc)
        H.openWorldFluid(S.col.fc, false)
    end)
    H.wait(4000, function() return T.off or (H.colOnCard() and H.zone(H.intoFid(T.b)) ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the game's Transfer on the collector opens the card, the bottle a row to pour into", "zones " .. H.zoneIds("fl:")) then T.off = true end
    end)
    H.step(1, function() if not T.off then H.press(H.intoFid(T.b)) end end)
    Q.waitMs(600)
    H.shot("ocp_fluid_" .. H.sizeTag(), "the Fluid card: a rain collector pouring into a water bottle (the tanks, the amount, the rows)", function() return not T.off end)
    -- Switch: the bottle on the left; Empty (mouse) asks; Cancel
    H.clickQ(T, "oc:verb:switch", T.L .. " (Switch)")
    Q.waitMs(500)
    H.clickQ(T, "oc:verb:empty", T.L .. " (Empty, mouse)")
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        T.q1 = S.cardQLast
        Q.check(T.q1 ~= nil and H.hasLc(T.q1, H.nm(T.b)), T.L .. " (FL2): with the bottle on the left, Empty's question names the bottle",
            "the question: \"" .. tostring(T.q1) .. "\"; the bottle is a " .. H.nm(T.b))
        H.cardClick("oc:confirm:no", T.L .. " (Cancel)")
    end)
    -- Switch back: the collector on the left; Empty by the pad, the focus on No, then Yes
    H.clickQ(T, "oc:verb:switch", T.L .. " (Switch back)")
    Q.waitMs(500)
    H.padPress(T, "oc:verb:empty", T.L .. " (Empty, pad)", "goE")
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        T.q2 = S.cardQLast
        T.f2 = H.focusedId()
        Q.check(T.q2 ~= nil and H.namesIn(T.q2, H.colNames()), T.L .. " (FL2): with the rain collector on the left, Empty's question names the collector",
            "the question: \"" .. tostring(T.q2) .. "\"; the collector's names (the game's): " .. H.list(H.colNames()) .. "; the focus on " .. tostring(T.f2))
    end)
    H.padPress(T, "oc:confirm:yes", T.L .. " (Yes, pad)", "goY")
    H.waitQ(T, 30000)
    H.step(2, function()
        H.padOff()
        if T.off then return end
        H.note(T.L .. ": Yes by the pad: the game emptied the collector " .. H.n1(T.c0) .. " -> " .. H.n1(H.amt(S.col.fc)) .. " L; the bottle holds " .. H.n2(H.amt(H.fcOf(T.b))) .. " L")
        H.colFill(50)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FL3 Stop before the pour begins
function C.fl3leg(T, how)
    local L = T.L .. " (" .. how .. ")"
    H.step(2, function()
        T.lOff = nil
        if T.off then return end
        H.closeCard(); H.qstop()
        H.colFill(50)
        if T.b then H.removeItem(T.b) end
        T.b = H.give(how == "pad" and S.FT.pop or S.FT.bottle)
        if how == "pad" then H.fill(H.fcOf(T.b), { { H.fluid("CarbonatedWater"), 0.3 } }) else H.fill(H.fcOf(T.b), {}) end
        T.a0 = H.amt(H.fcOf(T.b))
        local sq = S.col.parts[1].sq
        H.goTo(sq:getX() + 5.5, sq:getY() + 0.5, sq:getZ())
    end)
    Q.waitMs(300)
    H.step(1, function() if not (T.off or T.lOff) then H.openWorldFluid(S.col.fc, false) end end)
    H.wait(4000, function() return T.off or T.lOff or (H.colOnCard() and H.zone(H.intoFid(T.b)) ~= nil) end, function(ok)
        if T.off or T.lOff then return end
        if not Q.check(ok, L .. ": the card on the collector 5 tiles off lists the bottle", "zones " .. H.zoneIds("fl:")) then T.lOff = true; return end
        H.press(H.intoFid(T.b))
    end)
    Q.waitMs(500)
    H.step(1, function() if not (T.off or T.lOff) then T.tag = H.rowWords(H.intoFid(T.b)) end end)
    local live = function() return not T.lOff end
    if how == "pad" then H.padPress(T, "oc:verb:pour", L, "goP", live) else H.clickQ(T, "oc:verb:pour", L, nil, live) end
    H.wait(3000, function() return T.off or T.lOff or H.zone("fl:stop") ~= nil end, function(ok)
        if T.off or T.lOff then return end
        T.headStop = H.head()
        T.stopSeen = ok
        if not ok then return end
        if how == "mouse" then H.cardClick("fl:stop", L) end
    end)
    if how == "pad" then H.padPress(T, "fl:stop", L .. " (Stop)", "goS", function() return T.stopSeen and not T.lOff end) end
    H.step(2, function() H.padOff() end)
    H.waitQ(T, 40000, 1)
    H.step(2, function()
        if T.off or T.lOff then return end
        local moved = H.amt(H.fcOf(T.b)) - (T.a0 or 0)
        if not T.stopSeen then
            Q.skip(L, "the Pour showed no strip with Stop in 3 s (nothing poured, " .. H.n2(moved) .. " L moved; the row read '" .. tostring(T.tag) .. "')")
        else
            Q.check(moved < 0.01, L .. " (FL3): Stop pressed at once (the game's queue head " .. tostring(T.headStop) .. ") stops the pour",
                "the game moved " .. H.n2(moved) .. " L into the " .. H.nm(T.b) .. " after the Stop (its row read '" .. tostring(T.tag) .. "')")
        end
        H.home()
    end)
end
function C.fl3()
    local T = { L = "FL3 Stop during the walk" }
    H.step(2, function()
        H.caseStart(T)
        if not H.colReady() then T.off = true; Q.skip(T.L, S.noCol or "no rain collector") end
    end)
    C.fl3leg(T, "mouse")
    C.fl3leg(T, "pad")
    H.caseEnd(T.L)
end

-- ===================================================================== FL4 Pour pressed twice
function C.fl4leg(T, how)
    local L = T.L .. " (" .. how .. ")"
    H.step(2, function()
        T.lOff = nil
        if T.off then return end
        H.closeCard(); H.qstop(); H.home()
        H.colFill(50)
        if T.pot then H.removeItem(T.pot) end
        T.pot = H.give(S.FT.pot)
        H.fill(H.fcOf(T.pot), { { H.fluid("Bleach"), 0.2 } })
        local ok = false
        pcall(function() ok = FluidContainer.CanTransfer(S.col.fc, H.fcOf(T.pot)) and true or false end)
        T.bleach = ok
        if not ok then H.fill(H.fcOf(T.pot), {}) end
        T.a0 = H.amt(H.fcOf(T.pot))
        H.openWorldFluid(S.col.fc, false)
    end)
    H.wait(4000, function() return T.off or T.lOff or (H.colOnCard() and H.zone(H.intoFid(T.pot)) ~= nil) end, function(ok)
        if T.off or T.lOff then return end
        if not Q.check(ok, L .. ": the card on the collector lists the pot", "zones " .. H.zoneIds("fl:")) then T.lOff = true; return end
        H.press(H.intoFid(T.pot))
    end)
    Q.waitMs(500)
    H.step(1, function()
        if T.off or T.lOff then return end
        local fc = H.fcOf(T.pot)
        pcall(function() T.max = FluidUtil.roundTransfer(math.min(S.col.fc:getAmount(), fc:getCapacity() - fc:getAmount())) end)
        if how == "mouse" then
            H.cardClick("oc:verb:pour", L)
            H.cardClick("oc:verb:pour", L)
        end
    end)
    if how == "pad" then
        H.step(2, function() if not (T.off or T.lOff) then T.go = H.padOn() and H.focusEl("oc:verb:pour") end end)
        H.tapAA(function() return not (T.off or T.lOff) and T.go end)
    end
    H.step(2, function()
        H.padOff()
        if T.off or T.lOff then return end
        T.n = H.qcount("ISFluidTransferAction")
        T.k = H.qkinds()
    end)
    H.waitQ(T, 40000)
    H.step(2, function()
        if T.off or T.lOff then return end
        local moved = H.amt(H.fcOf(T.pot)) - (T.a0 or 0)
        Q.check(T.n <= 1 and moved <= (T.max or 0) + 0.01, L .. " (FL4): two presses at once queue one pour",
            "the game queued " .. tostring(T.n) .. " ISFluidTransferAction (" .. tostring(T.k) .. "); moved " .. H.n2(moved) .. " L against one Max Pour of " .. H.n2(T.max)
            .. (T.bleach and " (into a pot of bleach)" or " (into an empty pot: the game will not mix water into bleach)"))
        local t = H.tt()
        H.note(L .. ": after the pour the card's amount stays at " .. H.n2(t and t.frac) .. " of Max Pour (the game's slider goes back to 0, FTUI:507); its words: " .. H.drewAll("L", 6))
    end)
end
function C.fl4()
    local T = { L = "FL4 Pour twice" }
    H.step(2, function()
        H.caseStart(T)
        if not H.colReady() then T.off = true; Q.skip(T.L, S.noCol or "no rain collector") end
    end)
    C.fl4leg(T, "mouse")
    C.fl4leg(T, "pad")
    H.caseEnd(T.L)
end

-- ===================================================================== FL6 hidden amounts
function C.fl6()
    local T = { L = "FL6 a hidden amount" }
    H.step(2, function()
        H.caseStart(T)
        local sq = H.firstFree(S.RING2)
        local b, why = nil, "no free square two tiles from home"
        -- (the well has no craft recipe: the game's build code threw "expected argument of type CraftRecipe, got
        -- Boolean" on it in the first run; it is laid as the map lays one, its sprite and its entity script)
        if sq then b, why = H.placeEntity("Base.Well", sq, "camping_01_16", "the well") end
        if not (b and b.fc) then
            if b then H.rmBuilt(b) end
            T.off = true
            Q.skip(T.L, "only the well hides its amount in this game (entity_well HiddenAmount) and none could be laid: " .. tostring(why or "it has no fluid container"))
            return
        end
        T.well = b
        pcall(function() T.hidden = b.fc:isHiddenAmount() and true or false end)
        T.amt, T.cap = H.amt(b.fc), nil
        pcall(function() T.cap = b.fc:getCapacity() end)
        T.bucket = H.give(S.FT.bucket)
        H.fill(H.fcOf(T.bucket), {})
        H.openWorldFluid(b.fc, true)
    end)
    H.wait(4000, function() return T.off or H.colOnCard() end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the game's Show info on the well opens the card", "kind " .. tostring(H.kind())) then T.off = true; return end
        H.press(H.intoFid(T.bucket))
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        local L = ZeD.Fluid and ZeD.Fluid.L
        local lw = L and L(T.amt) or tostring(math.floor(T.amt))
        local leakText = H.drew(lw) ~= nil
        local lits = {}
        local leakSeg = false
        for _, s in ipairs(S.cardSeg or {}) do lits[#lits + 1] = tostring(s.lit); if (tonumber(s.lit) or 0) > 0 then leakSeg = true end end
        Q.check(not T.hidden or not (leakText or leakSeg), T.L .. " (FL6): the game hides the well's amount (its panel writes Unknown); the card shows no level of it",
            "the game hides it " .. tostring(T.hidden) .. ", holds " .. H.n1(T.amt) .. " of " .. H.n1(T.cap) .. " L; the card drew '" .. lw .. "' " .. tostring(leakText)
            .. "; its segment fills lit " .. H.list(lits) .. " (the bucket is empty: any lit segment is the well's); its words: " .. H.cardWords(24))
        H.closeCard()
        H.rmBuilt(T.well)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FL7 reach
function C.fl7()
    local T = { L = "FL7 Transfer from far off" }
    H.step(2, function()
        H.caseStart(T)
        if not H.colReady() then T.off = true; Q.skip(T.L, S.noCol or "no rain collector"); return end
        T.sq = S.col.parts[1].sq
    end)
    for _, d in ipairs({ 2, 7, 15 }) do
        C.reachLeg(T, d, function() H.openWorldFluid(S.col.fc, false) end, function() return H.colOnCard() end)
    end
    H.caseEnd(T.L)
end

-- ===================================================================== FL8 a bottle in a bag; Too heavy
function C.fl8heavy(T, label, over)
    local L = T.L .. " (" .. label .. ")"
    H.step(2, function()
        T.lOff = nil
        if T.off then return end
        H.closeCard()
        for _, it in ipairs(T.weights or {}) do H.removeItem(it) end
        T.weights = {}
        -- (planks counted from one reading of the weight: the game's own refusal is the answer either way)
        local w, m = H.weight()
        local probe = H.give(S.FT.plank)
        local pw = 1
        pcall(function() pw = math.max(0.1, probe:getActualWeight()) end)
        H.removeItem(probe)
        local want = 0
        if w and m then
            if over then want = math.ceil((m + 1.5 - w) / pw) else want = math.floor((m - 0.8 - w) / pw) end
        end
        want = math.max(0, math.min(60, want))
        for _ = 1, want do T.weights[#T.weights + 1] = H.give(S.FT.plank) end
        T.w0, T.add = w, want * pw
        H.colFill(50)
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        T.w, T.m = H.weight()
        pcall(function() T.can = FluidContainer.CanTransfer(S.col.fc, H.fcOf(T.pop)) and true or false end)
        pcall(function() T.why = tostring(FluidContainer.GetTransferReason(S.col.fc, H.fcOf(T.pop))) end)
        H.openWorldFluid(S.col.fc, false)
    end)
    H.wait(4000, function() return T.off or (H.colOnCard() and H.zone(H.intoFid(T.pop)) ~= nil) end, function(ok)
        if T.off then return end
        local heavy = H.lc(ZeD.tr("UI_ZeD_Fluid_TagTooHeavy"))
        local row = H.rowWords(H.intoFid(T.pop))
        local tagged = H.hasLc(row, heavy) or H.drew(heavy) ~= nil
        Q.check(ok and tagged == (T.can == false), L .. " (FL8): the card tags the bottle Too heavy exactly when the game refuses the pour",
            "carrying " .. H.n1(T.w) .. " of " .. H.n1(T.m) .. " (" .. H.n1(T.w0) .. " + " .. H.n1(T.add) .. " of planks); the game's CanTransfer " .. tostring(T.can)
            .. " (its reason \"" .. tostring(T.why) .. "\"); the row drew '" .. row .. "'")
    end)
end
function C.fl8()
    local T = { L = "FL8 bags and weight" }
    H.step(2, function()
        H.caseStart(T)
        if not H.colReady() then T.off = true; Q.skip(T.L, S.noCol or "no rain collector"); return end
        T.bag = H.give(S.FT.bag)
        local binv = nil
        pcall(function() binv = T.bag:getInventory() end)
        T.bb = binv and H.giveTo(binv, S.FT.bottle)
        T.pop = H.give(S.FT.pop)
        if not T.bb then T.off = true; Q.skip(T.L, "no bottle could be put in a bag"); return end
        H.fill(H.fcOf(T.bb), { { H.fluid("Water"), 0.5 } })
        H.fill(H.fcOf(T.pop), {})
        H.openItemFluid(T.bb, false)
    end)
    H.wait(4000, function() return T.off or (H.cardFluid(T.bb) and H.zone(H.intoFid(T.pop)) ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the bag's bottle's Transfer opens the card on it", "zones " .. H.zoneIds("fl:")) then T.off = true; return end
        T.where0 = H.ctype(H.where(T.bb))
        H.press(H.intoFid(T.pop))
    end)
    Q.waitMs(400)
    H.clickQ(T, "oc:verb:pour", T.L .. " (Pour from the bag)")
    H.waitQ(T, 30000)
    H.step(2, function()
        if T.off then return end
        local c = H.where(T.bb)
        Q.check(H.carried(T.bb), T.L .. " (FL8): the bag's bottle poured is still his", "in " .. H.ctype(c))
        H.note(T.L .. ": the bottle was in " .. tostring(T.where0) .. " when the card opened; after Pour it is in " .. H.ctype(c) .. " (main inventory "
            .. tostring(c == H.inv()) .. "); the game's own Transfer moves it to the main inventory once, when its window opens (FCM:232); the pop bottle holds " .. H.n2(H.amt(H.fcOf(T.pop))) .. " L")
        H.fill(H.fcOf(T.pop), {})
    end)
    C.fl8heavy(T, "over the limit", true)
    C.fl8heavy(T, "just under the limit", false)
    H.caseEnd(T.L)
end

-- ===================================================================== FL9 the progress, a side put away
function C.fl9()
    local T = { L = "FL9 the card while it pours" }
    H.step(2, function()
        H.caseStart(T)
        Q.skip("FL9 another player draining the collector mid-pour", "multiplayer: a second player on a server")
        T.pop = H.give(S.FT.pop)
        T.wb = H.give(S.FT.bottle)
        H.fill(H.fcOf(T.pop), { { H.fluid("Water"), 1.5 } })
        H.fill(H.fcOf(T.wb), {})
        H.openItemFluid(T.pop, false)
    end)
    H.wait(4000, function() return T.off or (H.cardFluid(T.pop) and H.zone(H.intoFid(T.wb)) ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the pop bottle's Transfer opens the card, the water bottle a row", "zones " .. H.zoneIds("fl:")) then T.off = true; return end
        H.press(H.intoFid(T.wb))
    end)
    Q.waitMs(400)
    H.clickQ(T, "oc:verb:pour", T.L .. " (Pour)")
    H.step(1, function() T.mid = nil; S.trSeen.UI_ZeD_Fluid_PourProgress = nil end)
    H.wait(20000, function()
        if T.off then return true end
        local r = S.trSeen.UI_ZeD_Fluid_PourProgress
        local a = H.amt(H.fcOf(T.wb))
        if r and getTimestampMs() - r.t < 100 and a > 0.2 and a < 0.8 then T.mid = { done = tonumber(r.a), real = a, b = r.b }; return true end
        return H.qlen() == 0
    end, function(ok)
        if T.off then return end
        if not T.mid then Q.skip(T.L .. " (the drawn progress)", "no frame caught the pour between 0.2 and 0.8 L"); return end
        Q.check(T.mid.done ~= nil and math.abs(T.mid.done - T.mid.real) <= 0.15, T.L .. " (FL9): the drawn progress is what the game has moved",
            "the strip drew " .. tostring(T.mid.done) .. " of " .. tostring(T.mid.b) .. "; the water bottle held " .. H.n2(T.mid.real) .. " L that frame")
    end)
    H.waitQ(T, 30000)
    H.step(2, function()
        if T.off then return end
        T.crate = H.mkCrate()
        if not T.crate then Q.skip(T.L .. " (a side put in a crate)", "no square for a crate"); return end
        pcall(function() local c = T.wb:getContainer(); if c then c:Remove(T.wb) end; T.crate.inv:AddItem(T.wb) end)
        H.lootRefresh()
    end)
    Q.waitMs(1200)
    H.step(2, function()
        if T.off or not T.crate then return end
        local name = H.nm(T.wb)
        Q.check(H.where(T.wb) == T.crate.inv and H.drew(name) == nil, T.L .. " (FL9): the water bottle put in a crate leaves the card (no stale Pouring To)",
            "in the crate " .. tostring(H.where(T.wb) == T.crate.inv) .. "; the card still drew '" .. H.drewAll(name, 4) .. "'; its words: " .. H.cardWords(20))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FL10 words
function C.fl10()
    local T = { L = "FL10 words" }
    H.step(2, function()
        H.caseStart(T)
        T.b = H.give(S.FT.bottle)
        H.fill(H.fcOf(T.b), { { H.fluid("Water"), 0.5 } })
        H.openItemFluid(T.b, false)
    end)
    H.wait(4000, function() return T.off or H.cardFluid(T.b) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the bottle's Transfer opens the card") then T.off = true; return end
        H.cardClick("oc:verb:empty", T.L)
    end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        local q = S.cardQLast
        local name = ""
        pcall(function() name = H.fluid("Water"):getTranslatedName() end)
        local lowered = name ~= string.lower(name) and H.has(tostring(q), string.lower(name)) and not H.has(tostring(q), name)
        local lang = H.lang()
        if lang == "DE" then
            Q.check(not lowered, T.L .. " (FL10): Empty's question keeps the liquid's capital (German nouns)", "the question: \"" .. tostring(q) .. "\"; the game's name " .. name)
        else
            H.note(T.L .. ": the run is in " .. lang .. ": the question \"" .. tostring(q) .. "\" lowercases the game's \"" .. name .. "\" " .. tostring(lowered)
                .. " (a FAIL only in a language that capitalizes it, German: other languages SKIP, a game started in each)")
        end
        H.note(T.L .. ": \"L\", \"1/4\" and \"1/2\" are written in code (OFL:41-46, 535, 553): drawn here " .. H.drewAll("1/", 3))
        H.cardClick("oc:confirm:no", T.L)
    end)
    H.caseEnd(T.L)
end

-- =====================================================================================================================
-- FIRE
-- =====================================================================================================================
function H.fireInfo(f)
    local lo, iso = H.fireLua(f), H.fireIso(f)
    if iso then H.zcall(function() ISCampingMenu.onDisplayInfo(nil, S.p, iso, lo) end) end
end
function H.bbqInfo(o) H.zcall(function() ISBBQMenu.onDisplayInfo(nil, S.pn, o) end) end
-- queue: a campfire laid at sq (T.f), its object seen, then extra(T)
function C.fireLay(T, sqFn, extra)
    H.step(2, function()
        if T.off then return end
        local sq = sqFn()
        T.f = sq and H.mkFire(sq)
        if not T.f then T.off = true; Q.skip(T.L, "no free square or no campfire system") end
    end)
    H.wait(5000, function() return T.off or H.fireIso(T.f) ~= nil end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.skip(T.L, "the campfire system made no fire object"); return end
        if extra then extra(T) end
    end)
end
-- the things in his reach (the game's own list: ISInventoryPaneContextMenu.getContainers, the bags, the floor round him,
-- the containers beside him) the game would burn or light with that the script did not give: fuel, tinder, starters
function H.foreignFire(fuelOnly)
    local o = {}
    pcall(function()
        local cs = ISInventoryPaneContextMenu.getContainers(S.p)
        for i = 0, cs:size() - 1 do
            local c = cs:get(i)
            local items = c:getItems()
            for j = 0, items:size() - 1 do
                local it = items:get(j)
                local mine = false
                pcall(function() mine = it:getModData().ZeDQA_spawned == true end)
                if not mine then
                    local fuel, tinder, starter = false, false, false
                    pcall(function() fuel = ISCampingMenu.isValidFuel(it) and true or false end)
                    pcall(function() tinder = ISCampingMenu.isValidTinder(it) and true or false end)
                    pcall(function() local ty = it:getType(); starter = (ty == "Lighter" or ty == "Matches" or it:hasTag(ItemTag.START_FIRE)) and it:getCurrentUses() > 0 end)
                    if fuel or ((tinder or starter) and not fuelOnly) then o[#o + 1] = H.nm(it) .. " (" .. H.ctype(c) .. ")" end
                end
            end
        end
    end)
    return o
end
-- a square with nothing round it the game would count in his reach: 5 x 5 loaded floor, outdoors, no world items, no
-- object with a container, no car within 6 tiles. Home's square has the keys and things earlier runs left (none the
-- script's to take): the cases that need a bare reach (FI2's All fuel, FI10's nothing to light with) stand here. The
-- site is snapped (its floor swept after) and its fires swept at the end.
S.CLEAN = { { 0, -6 }, { 0, 6 }, { -6, 0 }, { 6, 0 }, { -6, -6 }, { 6, -6 }, { -6, 6 }, { 6, 6 }, { 0, -10 }, { 0, 10 }, { -10, 0 }, { 10, 0 },
            { -12, -6 }, { 12, -6 }, { -12, 6 }, { 12, 6 } }
function H.bareAt(cx, cy, cz)
    local cars = {}
    pcall(function() local vs = getCell():getVehicles(); for i = 0, vs:size() - 1 do cars[#cars + 1] = vs:get(i) end end)
    for _, v in ipairs(cars) do
        local far = true
        pcall(function() far = math.abs(v:getX() - cx) > 6 or math.abs(v:getY() - cy) > 6 end)
        if not far then return false end
    end
    for y = cy - 2, cy + 2 do
        for x = cx - 2, cx + 2 do
            local sq = H.sqXY(x, y, cz)
            local bare = false
            pcall(function()
                bare = sq ~= nil and sq:getFloor() ~= nil and sq:isOutside() and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
                    and not H.used(sq)
                if bare then
                    local objs = sq:getObjects()
                    for i = 0, objs:size() - 1 do
                        local ob = objs:get(i)
                        local n = 0
                        pcall(function() n = ob:getContainerCount() end)
                        if n > 0 or instanceof(ob, "IsoGenerator") then bare = false end
                    end
                end
            end)
            if not bare then return false end
        end
    end
    return true
end
function H.cleanSite()
    local f = S.found.pos
    if not f then return nil end
    local hx, hy, hz = math.floor(f.x), math.floor(f.y), math.floor(f.z)
    for _, d in ipairs(S.CLEAN) do
        local x, y = hx + d[1], hy + d[2]
        local sq = H.sqXY(x, y, hz)
        if sq and H.sqFree(sq) and H.bareAt(x, y, hz) then
            local c = { x = x, y = y, z = hz }
            if not S.cleanSnapped or S.cleanSnapped.x ~= x or S.cleanSnapped.y ~= y then
                S.cleanSnapped = c
                H.snapAt(x, y, hz)
                S.sites = S.sites or {}
                S.sites[#S.sites + 1] = c
            end
            return c
        end
    end
    return nil
end
-- stand on the clean site (T.site), or say why not (nil)
function H.toClean(T)
    T.site = H.cleanSite()
    if not T.site then return false end
    H.goTo(T.site.x + 0.5, T.site.y + 0.5, T.site.z)
    return true
end
function H.fireItems(f) local o = {}; pcall(function() local c = H.fireIso(f):getContainer(); for i = 0, c:getItems():size() - 1 do o[#o + 1] = H.ft(c:getItems():get(i)) end end); return o end

-- ===================================================================== FI1 an indoor campfire
function C.fi1()
    local T = { L = "FI1 an indoor campfire" }
    H.step(2, function()
        H.caseStart(T)
        T.site = S.indoor and S.indoor.fire
        if not T.site then T.off = true; Q.skip(T.L, S.indoorWhy or "no indoor floor near home"); return end
        H.goTo(T.site.stand:getX() + 0.5, T.site.stand:getY() + 0.5, T.site.sq:getZ())
        T.paper = { H.give(S.FT.paper), H.give(S.FT.paper) }
        H.give(S.FT.matches)
    end)
    Q.waitMs(1200)
    C.fireLay(T, function() return T.site.sq end, function()
        local so = H.fireServer(T.f)
        if so then pcall(function() so:addFuel(120) end) end   -- (two hours of fuel, unlit: the light comes from the card)
        H.lootRefresh()
        H.fireInfo(T.f)
    end)
    H.wait(4000, function() return T.off or (H.cardFire(T.f) and H.zone("fire:light:1") ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the card on the indoor campfire offers its Light rows", "zones " .. H.zoneIds("fire:")) then T.off = true end
    end)
    H.clickQ(T, "oc:verb:light", T.L .. " (Light)")
    H.clickQ(T, "fire:light:1", T.L .. " (its first row)")
    H.waitQ(T, 30000)
    H.step(2, function()
        if T.off then return end
        if not Q.check(H.fireLit(T.f), T.L .. ": lit from the card (the game's light from paper)", "lit " .. tostring(H.fireLit(T.f))) then T.off = true; return end
        H.fireInfo(T.f)
    end)
    H.wait(3000, function() return T.off or H.cardFire(T.f) end, function(ok)
        if T.off then return end
        local warned = #(S.cardWarns or {}) > 0
        Q.check(warned, T.L .. " (FI1): lit indoors on a floor the game can set alight, the card warns",
            T.site.burn .. " of its 3 spread targets burn by the game's rule (SCampfireSystem.lowerFirelvl: wood floors, carpets); the card's warning boxes: "
            .. H.list(S.cardWarns) .. "; its words: " .. H.cardWords(16))
        H.closeCard()
        T.h0 = H.worldH()
        T.spread = {}
        T.fx, T.fy, T.fz = T.f.sq:getX(), T.f.sq:getY(), T.f.sq:getZ()
        H.speed(3)
    end)
    -- an hour on fast-forward; any fire the game starts nearby is put out on the frame it is seen
    H.wait(150000, function()
        if T.off then return true end
        for y = T.fy - 3, T.fy + 3 do
            for x = T.fx - 3, T.fx + 3 do
                if not (x == T.fx and y == T.fy) then
                    local sq = H.sqXY(x, y, T.fz)
                    local burning = false
                    pcall(function() burning = sq ~= nil and sq:haveFire() end)
                    if burning then
                        pcall(function() sq:stopFire() end)
                        T.spread[#T.spread + 1] = x .. "," .. y .. " after " .. H.n1((H.worldH() - T.h0) * 60) .. " min"
                    end
                end
            end
        end
        return #T.spread > 0 or H.worldH() - T.h0 >= 1
    end, function()
        H.speed(1)
        if T.off then return end
        H.fireOut(T.f)
        local n = H.fireSweepAt(T.fx, T.fy, T.fz, 6)
        H.note(T.L .. ": an hour on fast-forward (" .. H.n1((H.worldH() - T.h0) * 60) .. " game minutes): the game set alight " .. H.list(T.spread)
            .. " (put out at once); fires put out round it after: " .. n)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FI2 All fuel takes the crate's things
function C.fi2leg(T, how)
    local L = T.L .. " (" .. how .. ")"
    H.step(2, function()
        T.off = nil
        H.legClean()
        H.caseStart(T)
        -- (the first run: at home the game's reach held 22 burnables earlier runs left, so the lot of 26 overfilled
        -- the fire, the All row stood greyed with no press, and the click did nothing: the case stands on a bare site)
        if not H.toClean(T) then T.off = true; Q.skip(L, "no bare square within 12 tiles of home (no world items, containers or car round it)"); return end
        T.crate = H.mkCrate()
        if not T.crate then T.off = true; Q.skip(L, "no square for a crate"); return end
        T.book = H.giveTo(T.crate.inv, S.FT.book)
        T.map = H.giveTo(T.crate.inv, S.FT.map)
        T.cplank = H.giveTo(T.crate.inv, S.FT.plank)
        T.bplank = H.give(S.FT.plank)
        H.lootRefresh()
    end)
    C.fireLay(T, function() return H.firstFree(S.RING2) end, function()
        T.fuel0 = H.fireFuel(T.f)
        local m, err, own = H.gameMenu({ H.fireIso(T.f) })
        T.gameAll = H.menuLike(own, getText("ContextMenu_AllWithCount", 4)) or H.menuLike(own, getText("ContextMenu_AllWithCount", 3))
        T.gameMenu = H.ownMenuWhy(m, own, err) or H.menuNames(own, 14)
        H.lootRefresh()
        H.fireInfo(T.f)
    end)
    -- (fix/cards2, Nov 26 2026: All fuel takes plain fuel only; with one plain kind in reach, the planks, the card shows
    -- that kind's "all" row (fire:fuelmany:1) and no separate All row: either is the press that burns "all")
    H.wait(5000, function() return T.off or (H.cardFire(T.f) and (H.zone("fire:fuelall") ~= nil or H.zone("fire:fuelmany:1") ~= nil)) end, function(ok)
        if T.off then return end
        if not Q.check(ok, L .. ": the card offers All fuel (or a plain kind's all row) with the crate beside him", "zones " .. H.zoneIds("fire:") .. "; words " .. H.cardWords(24)) then T.off = true; return end
        T.allId = (H.zone("fire:fuelall") ~= nil) and "fire:fuelall" or "fire:fuelmany:1"
        T.allRow = H.rowWords(T.allId)
        T.head = H.drewAll(ZeD.tr("UI_ZeD_Fire_AddFromBags"), 2)
        T.bookRow = H.drew(H.nm(T.book)) ~= nil
        -- the press must reach the game: the All row live (the lot fits the fire), and nothing in reach the script did
        -- not give (All would burn it)
        local foreign = H.foreignFire(true)
        if not H.lit(T.allId) then
            T.off = true
            Q.skip(L .. " (FI2): one press of All fuel, no question, leaves the crate's skill book and map", "the card's All row has no press (its row '"
                .. tostring(T.allRow) .. "'; the fire's fuel " .. H.n1(T.fuel0) .. " min; not the script's in reach: " .. H.list(foreign, 8) .. ")")
        elseif #foreign > 0 then
            T.off = true
            Q.skip(L .. " (FI2): one press of All fuel, no question, leaves the crate's skill book and map", "All would burn things in his reach the script did not give: " .. H.list(foreign, 8))
        end
    end)
    if how == "mouse" then
        H.shot("ocp_fire_" .. H.sizeTag(), "the Fire card: a campfire with fuel to add (the strip, the Light rows, Add fuel with a crate's skill book and map in the list)", function() return not T.off end)
        H.clickQ(T, "fire:fuelall", L, "clicked", function() return T.allId == "fire:fuelall" end)
        H.clickQ(T, "fire:fuelmany:1", L, "clicked", function() return T.allId == "fire:fuelmany:1" end)
    else
        H.padPress(T, "fire:fuelall", L, "goA", function() return T.allId == "fire:fuelall" end)
        H.padPress(T, "fire:fuelmany:1", L, "goA2", function() return T.allId == "fire:fuelmany:1" end)
    end
    H.step(2, function()
        H.padOff()
        if T.off then return end
        T.k = H.qkinds()
        T.nFuel = H.qcount("ISAddFuelAction") + H.qcount("ISBBQAddFuel") + H.qcount("ISAddFuel")
    end)
    H.waitQ(T, 60000)
    H.step(2, function()
        if T.off then return end
        local burned, kept = {}, {}
        for _, e in ipairs({ { T.book, "the skill book (crate)" }, { T.map, "the map (crate)" }, { T.cplank, "the plank (crate)" }, { T.bplank, "the plank (bags)" } }) do
            if H.gone(e[1]) then burned[#burned + 1] = e[2] else kept[#kept + 1] = e[2] end
        end
        local fuel1 = H.fireFuel(T.f)
        local rose = type(fuel1) == "number" and type(T.fuel0) == "number" and fuel1 > T.fuel0 + 0.5
        local what = "the game burned " .. H.list(burned) .. "; kept " .. H.list(kept) .. "; the fire's fuel " .. H.n1(T.fuel0) .. " -> " .. H.n1(fuel1)
            .. " min; the queue after the press " .. tostring(T.k) .. " (" .. tostring(T.nFuel) .. " fuel actions); the card's head read '" .. tostring(T.head)
            .. "', its All row '" .. tostring(T.allRow) .. "', the book listed " .. tostring(T.bookRow)
        -- judged only when the press reached the game: its fuel actions queued, or the fire's fuel rose
        if (T.nFuel or 0) == 0 and not rose then
            Q.skip(L .. " (FI2): one press of All fuel, no question, leaves the crate's skill book and map", "the press ran nothing in the game ("
                .. ((how == "mouse") and ("the click landed " .. tostring(T.clicked)) or ("the pad's focus took " .. tostring(T.goA or T.goA2))) .. "): " .. what)
        else
            Q.check(not H.gone(T.book) and not H.gone(T.map), L .. " (FI2): one press of All fuel, no question, leaves the crate's skill book and map", what)
        end
        H.note(L .. ": gone for good (test items the script gave): " .. H.list(burned) .. "; the game's own menu on the campfire: " .. tostring(T.gameMenu))
    end)
end
function C.fi2()
    local T = { L = "FI2 All fuel" }
    C.fi2leg(T, "mouse")
    C.fi2leg(T, "pad")
    H.caseEnd(T.L)
end

-- ===================================================================== FI3 A A lights with the first tinder
function C.fi3leg(T, how)
    local L = T.L .. " (" .. how .. ")"
    H.step(2, function()
        T.off = nil
        H.legClean()
        H.caseStart(T)
        T.book = H.give(S.FT.book)
        T.bag = H.give(S.FT.bag)
        local binv = nil
        pcall(function() binv = T.bag:getInventory() end)
        T.paper = binv and H.giveTo(binv, S.FT.paper)
        T.matches = H.give(S.FT.matches)
        T.lighter = H.give(S.FT.lighter)
        T.mu0, T.lu0 = H.uses(T.matches), H.uses(T.lighter)
        H.lootRefresh()
    end)
    C.fireLay(T, function() return H.firstFree(S.RING2) end, function()
        local so = H.fireServer(T.f)
        if so then pcall(function() so:addFuel(30) end) end
        local m, err, own = H.gameMenu({ H.fireIso(T.f) })
        T.gameLight = H.ownMenuWhy(m, own, err) or H.menuNames(own, 20)
        H.fireInfo(T.f)
    end)
    H.wait(5000, function() return T.off or (H.cardFire(T.f) and H.zone("fire:light:1") ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, L .. ": the card offers its Light rows", "zones " .. H.zoneIds("fire:")) then T.off = true; return end
        T.row1 = H.rowWords("fire:light:1")
        T.row2 = H.rowWords("fire:light:2")
    end)
    if how == "pad" then
        H.padPress(T, "oc:verb:light", L .. " (A on Light)", "goL")
        Q.waitMs(400)
        H.step(1, function() if not T.off then T.f1 = H.focusedId() end end)
        H.tapA(function() return not T.off and T.goL end)
    else
        H.clickQ(T, "oc:verb:light", L .. " (Light)")
        Q.waitMs(400)
        H.clickQ(T, "fire:light:1", L .. " (its first row)")
    end
    H.step(2, function() H.padOff() end)
    H.waitQ(T, 30000)
    H.step(2, function()
        if T.off then return end
        local bookGone, paperGone = H.gone(T.book), H.gone(T.paper)
        Q.check(H.fireLit(T.f) and not bookGone, L .. " (FI3): Light's first row, pressed twice over, lights with the paper and leaves the skill book",
            "lit " .. tostring(H.fireLit(T.f)) .. "; the game burned the skill book " .. tostring(bookGone) .. ", the paper (in a bag) " .. tostring(paperGone)
            .. "; row 1 read '" .. tostring(T.row1) .. "', row 2 '" .. tostring(T.row2) .. "'" .. (T.f1 and ("; after the first A the focus on " .. tostring(T.f1)) or ""))
        H.note(L .. ": the starter: matches " .. tostring(T.mu0) .. " -> " .. tostring(H.uses(T.matches)) .. ", lighter " .. tostring(T.lu0) .. " -> " .. tostring(H.uses(T.lighter))
            .. " (the card takes the game's first starter, unsorted); the game's own menu: " .. tostring(T.gameLight))
        H.fireOut(T.f)
    end)
end
function C.fi3()
    local T = { L = "FI3 Light A A" }
    C.fi3leg(T, "pad")
    C.fi3leg(T, "mouse")
    H.caseEnd(T.L)
end

-- ===================================================================== FI4 the Lights wheel's Put out
function C.fi4()
    local T = { L = "FI4 the Lights wheel's fire" }
    H.step(2, function()
        H.caseStart(T)
        T.fp = H.mkFireplace(H.freeSq(1, -5))
        if T.fp then
            pcall(function() T.fp.obj:setFuelAmount(60) end)
            pcall(function() T.fp.obj:setLit(true) end)
            T.fpLit = H.call(T.fp.obj, "isLit") == true
        end
    end)
    C.fireLay(T, function() return H.freeSq(1, 1) end, function()
        H.fireLight(T.f, 60)
        local c = nil
        pcall(function() c = H.fireIso(T.f):getContainer() end)
        if c then H.giveTo(c, S.FT.steak) end
        if not T.fpLit then
            -- (no fireplace would light: a second campfire 5 tiles north instead)
            if T.fp then H.rmObj(T.fp); T.fp = nil end
            local sq = H.freeSq(1, -5)
            T.f2 = sq and H.mkFire(sq)
        end
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        if T.f2 then H.fireLight(T.f2, 60) end
        H.lootRefresh()
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        local sl = H.lights()[3]
        T.w = H.sliceWords(sl)
        if not (sl and sl.run) then T.off = true; Q.check(false, T.L .. ": the wheel's fire slice can put a fire out", T.w); return end
        H.wheelTake(sl)
        T.k = H.qkinds()
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        local nearLit = H.fireLit(T.f)
        local farLit = T.fp and (H.call(T.fp.obj, "isLit") == true) or (T.f2 and H.fireLit(T.f2))
        Q.check(not nearLit and farLit, T.L .. " (FI4): Put out puts out the nearest fire (the campfire cooking beside him)",
            "the slice said '" .. T.w .. "', the game queued " .. tostring(T.k) .. "; the campfire beside him lit " .. tostring(nearLit) .. ", the "
            .. (T.fp and "fireplace" or "campfire") .. " 5 tiles north (first in reading order) lit " .. tostring(farLit))
        H.fireOut(T.f)
        if T.f2 then H.fireOut(T.f2) end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FI5 Take apart drops what cooks
function C.fi5leg(T, how)
    local L = T.L .. " (" .. how .. ")"
    H.step(2, function()
        T.off = nil
        H.legClean()
        H.caseStart(T)
        T.st0 = H.count(S.FT.stone)
    end)
    C.fireLay(T, function() return H.firstFree(S.RING2) end, function()
        if how == "mouse" then H.fireLight(T.f, 60) end
        local c = nil
        pcall(function() c = H.fireIso(T.f):getContainer() end)
        T.food = c and H.giveTo(c, how == "mouse" and S.FT.stew or S.FT.steak)
        if not T.food then T.off = true; Q.skip(L, "the campfire has no container for the food"); return end
        H.fireInfo(T.f)
    end)
    H.wait(4000, function() return T.off or (H.cardFire(T.f) and H.zone("oc:verb:take") ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, L .. ": the card offers Take apart", "zones " .. H.zoneIds("oc:")) then T.off = true; return end
        if how == "mouse" then H.cardClick("oc:verb:take", L) end
    end)
    if how == "pad" then H.padPress(T, "oc:verb:take", L, "goT") end
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        T.q = S.cardQLast
        T.fq = H.focusedId()
        if how == "mouse" then H.cardClick("oc:confirm:yes", L) end
    end)
    if how == "pad" then H.padPress(T, "oc:confirm:yes", L .. " (Yes)", "goY") end
    H.step(2, function() H.padOff() end)
    H.waitQ(T, 30000)
    H.step(2, function()
        if T.off then return end
        local wo = H.onFloor(T.food)
        local sq = nil
        pcall(function() sq = wo and wo:getSquare() end)
        local named = T.q ~= nil and (H.hasLc(T.q, H.nm(T.food)) or T.q == ZeD.tr("UI_ZeD_Fire_ConfirmTakeApart"))
        Q.check(H.fireLua(T.f) == nil, L .. ": Yes takes the campfire apart (the game's ISRemoveCampfireAction)", "the campfire left " .. tostring(H.fireLua(T.f) ~= nil))
        Q.check(wo == nil or named, L .. " (FI5): Take apart's question says what is on the fire drops to the ground",
            "the question: \"" .. tostring(T.q) .. "\"" .. (how == "pad" and (" (the focus then on " .. tostring(T.fq) .. ")") or "") .. "; the " .. H.nm(T.food)
            .. " is on the ground " .. tostring(wo ~= nil) .. (sq and (" at " .. sq:getX() .. "," .. sq:getY()) or "") .. "; stones given " .. (H.count(S.FT.stone) - (T.st0 or 0))
            .. "; the unused key UI_ZeD_Fire_ConfirmTakeApart reads \"" .. ZeD.tr("UI_ZeD_Fire_ConfirmTakeApart") .. "\"")
    end)
end
function C.fi5()
    local T = { L = "FI5 Take apart" }
    C.fi5leg(T, "mouse")
    C.fi5leg(T, "pad")
    H.caseEnd(T.L)
end

-- ===================================================================== FI6 the propane tank swap
function H.tankItem(uses)
    local tank = nil
    pcall(function() tank = instanceItem(S.FT.tank) end)
    if not tank then return nil end
    pcall(function() tank:setUsedDelta(uses) end)
    pcall(function() tank:setCurrentUsesFloat(uses) end)
    return tank
end
-- every propane tank the case gave (T.floorTank, the spares) or the game moved (the tanks its Remove and Insert put
-- on the floor where he stood), taken away: the floor within 2 tiles of the grill and of him (what was not there at
-- the start), his bags (what he did not carry), the grill's own. Returns the count, and true when the floor's tank is
-- still somewhere
function H.tanksAway(T)
    local n = 0
    for _, it in ipairs({ T.floorTank, T.spare }) do
        if H.isItem(it) then
            H.removeItem(it)
            pcall(function() it:setWorldItem(nil) end)
        end
    end
    T.spare = nil
    local spots = {}
    if T.bbq and T.bbq.sq then spots[#spots + 1] = T.bbq.sq end
    pcall(function() local cs = S.p:getCurrentSquare(); if cs then spots[#spots + 1] = cs end end)
    for _, c in ipairs(spots) do
        local cx, cy, cz = c:getX(), c:getY(), c:getZ()
        for y = cy - 2, cy + 2 do
            for x = cx - 2, cx + 2 do
                local sq = H.sqXY(x, y, cz)
                local wos = {}
                pcall(function() local l = sq:getWorldObjects(); for i = 0, l:size() - 1 do wos[#wos + 1] = l:get(i) end end)
                for _, wo in ipairs(wos) do
                    local it = nil
                    pcall(function() it = wo:getItem() end)
                    if H.ft(it) == S.FT.tank and not S.found.floor0[wo] then
                        pcall(function() sq:transmitRemoveItemFromSquare(wo) end)
                        pcall(function() wo:removeFromWorld() end)
                        pcall(function() wo:removeFromSquare() end)
                        pcall(function() it:setWorldItem(nil) end)
                        n = n + 1
                    end
                end
            end
        end
    end
    for _, it in ipairs(H.all()) do
        if H.ft(it) == S.FT.tank and not S.found.inv0[it] then H.removeItem(it); n = n + 1 end
    end
    pcall(function() if T.bbq.obj:hasPropaneTank() then T.bbq.obj:removePropaneTank(); n = n + 1 end end)
    return n, (T.floorTank ~= nil and not H.gone(T.floorTank))
end
function C.fi6tank(T, how)
    local L = T.L .. " (the tank key, " .. how .. ")"
    H.step(2, function()
        if T.off then return end
        H.closeCard(); H.qstop()
        pcall(function() T.bbq.obj:removePropaneTank() end)
        pcall(function() T.bbq.obj:setPropaneTank(H.tankItem(0)) end)
        if T.spare then H.removeItem(T.spare) end
        T.spare = H.give(S.FT.tank)
        pcall(function() T.spare:setCurrentUsesFloat(1.0) end)
        H.bbqInfo(T.bbq.obj)
    end)
    H.wait(4000, function() return T.off or (H.cardOn("fire", T.bbq.obj) and H.zone("bbq:tank") ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, L .. ": the grill's card draws its tank key", "zones " .. H.zoneIds()) then return end
        T.verbs = H.zoneIds("oc:")
        T.ins = H.zone("oc:verb:insert") ~= nil or H.zone("oc:hv:insert") ~= nil
        if how == "mouse" then
            local m, err, own = H.gameMenu({ T.bbq.obj })
            T.gameIns = H.menuLike(own, getText("ContextMenu_Insert_Propane_Tank"))
            local why = H.ownMenuWhy(m, own, err)
            if why then
                Q.skip(T.L .. " (FI6): with an empty tank in and a full one in the bags, the card offers Insert as the game's menu does", why)
            else
                Q.check(T.gameIns == nil or T.ins, T.L .. " (FI6): with an empty tank in and a full one in the bags, the card offers Insert as the game's menu does",
                    "the game's menu on the grill offers Insert " .. tostring(T.gameIns ~= nil) .. " (its action drops the old tank, BIT:65-72); the card's verbs: " .. T.verbs)
            end
        end
    end)
    if how == "mouse" then H.clickQ(T, "bbq:tank", L) else H.padPress(T, "bbq:tank", L, "goK") end
    H.step(2, function() H.padOff(); if not T.off then T.k = H.qkinds() end end)
    H.waitQ(T, 30000)
    H.step(2, function()
        if T.off then return end
        local has = H.call(T.bbq.obj, "hasPropaneTank") == true
        local fuel = H.call(T.bbq.obj, "getFuelAmount")
        H.note(L .. ": the press queued " .. tostring(T.k) .. "; after it the grill has a tank " .. tostring(has) .. " with " .. H.n1(fuel)
            .. " min of gas; the spare in the bags " .. tostring(H.carried(T.spare)) .. " (a swap takes the card two presses and two walks, the game one)")
    end)
end
function C.fi6()
    local T = { L = "FI6 the propane grill's tank" }
    H.step(2, function()
        H.caseStart(T)
        T.bbq = H.mkBBQ(H.firstFree(S.RING2), S.BBQ_GAS)
        if not (T.bbq and H.call(T.bbq.obj, "isPropaneBBQ")) then T.off = true; Q.skip(T.L, "no propane grill could be laid"); return end
    end)
    C.fi6tank(T, "mouse")
    C.fi6tank(T, "pad")
    -- a spare on the floor beside the grill, none in it, none in the bags
    H.step(2, function()
        if T.off then return end
        H.closeCard(); H.qstop()
        pcall(function() T.bbq.obj:removePropaneTank() end)
        if T.spare then H.removeItem(T.spare); T.spare = nil end
        for _, it in ipairs(H.all()) do if H.ft(it) == S.FT.tank and not S.found.inv0[it] then H.removeItem(it) end end
        local tank = H.tankItem(1.0)
        local sq = H.sqXY(T.bbq.sq:getX(), T.bbq.sq:getY() + 1, T.bbq.sq:getZ())
        if tank and sq then pcall(function() sq:AddWorldInventoryItem(tank, 0.5, 0.5, 0) end); T.floorTank = H.mark(tank) end
        H.hidden("all")
        H.bbqInfo(T.bbq.obj)
    end)
    H.wait(4000, function() return T.off or H.cardOn("fire", T.bbq.obj) end, function(ok)
        if T.off then return end
        T.insLit = H.lit("oc:verb:insert")
        T.needs = H.list(S.cardNeeds)
    end)
    H.clickQ(T, "oc:verb:insert", T.L .. " (Insert, the floor's tank)")
    H.waitQ(T, 30000)
    H.step(2, function()
        if T.off then return end
        local has = H.call(T.bbq.obj, "hasPropaneTank") == true
        Q.check(T.insLit and has, T.L .. " (FI6): with a full tank on the floor beside the grill, the card's Insert puts it in (the game's FindPropaneTank looks there too)",
            "Insert live " .. tostring(T.insLit) .. "; the grill has a tank after " .. tostring(has) .. "; the NEEDS lines " .. tostring(T.needs)
            .. "; the needs words (none in reach): \"" .. ZeD.tr("UI_ZeD_Fire_NeedsSpareTank") .. "\"")
        pcall(function() T.bbq.obj:removePropaneTank() end)
    end)
    -- the clean-up: every propane tank the case gave or the game moved (the first run's put back found one left)
    H.step(2, function()
        if not T.bbq then return end
        local n, still = H.tanksAway(T)
        if still then H.note(T.L .. ": the floor's tank still not gone after the clean-up (" .. H.whereText(T.floorTank) .. ")") end
        if n > 0 then H.note(T.L .. ": the clean-up took away " .. n .. " propane tanks (the floor round the grill and him, his bags, the grill)") end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FI7 smouldering
function H.cookRead(it)
    local o = { m = H.worldMin() }
    pcall(function() o.ct = it:getCookingTime(); o.heat = it:getHeat(); o.cooked = it:isCooked() end)
    return o
end
function C.fi7()
    local T = { L = "FI7 a smouldering barbecue" }
    H.step(2, function()
        H.caseStart(T)
        T.bbq = H.mkBBQ(H.firstFree(S.RING2), S.BBQ_COAL)
        if not T.bbq or H.call(T.bbq.obj, "isPropaneBBQ") then T.off = true; Q.skip(T.L, "no charcoal barbecue could be laid"); return end
        pcall(function() T.bbq.obj:setFuelAmount(60) end)
        pcall(function() T.bbq.obj:setLit(true) end)
        if H.call(T.bbq.obj, "isLit") ~= true then T.off = true; Q.skip(T.L, "the barbecue would not light for the staging"); return end
        local c = H.call(T.bbq.obj, "getContainer")
        T.steak = c and H.giveTo(c, S.FT.steak)
        H.bbqInfo(T.bbq.obj)
    end)
    H.wait(4000, function() return T.off or (H.cardOn("fire", T.bbq.obj) and H.zone("oc:verb:out") ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": lit, the card offers Put out", "zones " .. H.zoneIds("oc:")) then T.off = true end
    end)
    H.clickQ(T, "oc:verb:out", T.L .. " (Put out)")
    H.waitQ(T, 30000)
    H.step(2, function()
        if T.off then return end
        T.smo = H.call(T.bbq.obj, "isSmouldering") == true
        if not T.smo then T.off = true; Q.skip(T.L, "the game's Put out did not leave it smouldering (lit " .. tostring(H.call(T.bbq.obj, "isLit")) .. ")"); return end
        H.bbqInfo(T.bbq.obj)
    end)
    H.wait(3000, function() return T.off or H.cardOn("fire", T.bbq.obj) end, function(ok)
        if T.off then return end
        local _, _, gm = H.gameMenu({ T.bbq.obj })
        T.gameOut = H.menuLike(gm, getText("ContextMenu_Put_out_fire")) or H.menuLike(gm, campingText and campingText.putOutCampfire or "?")
        Q.check(H.zone("oc:verb:out") == nil, T.L .. " (FI7): smouldering, the card has no Put out, as the game's menu",
            "the card's verbs " .. H.zoneIds("oc:") .. "; the game's menu offers Put out " .. tostring(T.gameOut ~= nil) .. " (" .. H.menuNames(gm, 10) .. ")")
        T.r0 = T.steak and H.cookRead(T.steak)
        S.trSeen.UI_ZeD_ObjCard_MinLeft = nil
        T.tm = getTimestampMs()
        T.cardCooks = nil
        H.speed(3)
    end)
    -- (the card's On the fire row: its Cooking tag, the game's word, drawn on any frame of the ten minutes)
    H.wait(60000, function()
        if T.off or not T.r0 then return true end
        if H.cardOn("fire", T.bbq.obj) and H.drewEq(ZeD.tr("IGUI_invpanel_Cooking")) > 0 then T.cardCooks = true end
        return H.worldMin() - T.r0.m >= 10
    end, function()
        H.speed(1)
        if T.off or not T.r0 then return end
        local r1 = H.cookRead(T.steak)
        local heating = (r1.ct or 0) > (T.r0.ct or 0) + 0.5
        local r = S.trSeen.UI_ZeD_ObjCard_MinLeft
        local cardCooks = T.cardCooks == true or (r ~= nil and r.t >= T.tm)
        Q.check(cardCooks == heating, T.L .. " (FI7): on the smouldering barbecue the card reads the steak cooking exactly when the game heats it",
            "over " .. H.n1(r1.m - T.r0.m) .. " game minutes the steak's cooking time " .. H.n1(T.r0.ct) .. " -> " .. H.n1(r1.ct) .. ", heat " .. H.n2(T.r0.heat) .. " -> " .. H.n2(r1.heat)
            .. "; the card drew its minutes " .. tostring(cardCooks) .. "; still smouldering " .. tostring(H.call(T.bbq.obj, "isSmouldering")))
        local _, _, gm = H.gameMenu({ T.bbq.obj })
        H.note(T.L .. ": smouldering, the card's Light verb shown " .. tostring(H.zone("oc:verb:light") ~= nil or H.zone("oc:hv:light") ~= nil) .. "; the game's menu: " .. H.menuNames(gm, 12))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FI9 reach
function C.fi9()
    local T = { L = "FI9 the fire's Info from far off" }
    H.step(2, function() H.caseStart(T) end)
    C.fireLay(T, function() return H.reachSq() end, function() T.sq = T.f.sq end)
    for _, d in ipairs({ 2, 7, 15 }) do
        C.reachLeg(T, d, function() H.fireInfo(T.f) end, function() return H.cardFire(T.f) end)
    end
    H.caseEnd(T.L)
end

-- ===================================================================== FI10 the Light NEEDS words
function C.fi10()
    local T = { L = "FI10 Light's NEEDS words" }
    H.step(2, function()
        H.caseStart(T)
        -- (the first run: at home the game's reach held books, bats and the like earlier runs left: "no fuel and no
        -- lighter" did not hold there; the case stands on a bare site)
        if not H.toClean(T) then T.off = true; Q.skip(T.L, "no bare square within 12 tiles of home (no world items, containers or car round it)"); return end
        T.paper = H.give(S.FT.paper)
        H.hidden("all")
        H.lootRefresh()
    end)
    C.fireLay(T, function() return H.firstFree(S.RING2) end, function()
        local m, err, own = H.gameMenu({ H.fireIso(T.f) })
        T.gameNo = H.menuLike(own, getText("ContextMenu_No_LightingMethod"))
        T.gameWhy = H.ownMenuWhy(m, own, err)
        T.gameMenu = T.gameWhy or H.menuNames(own, 12)
        H.lootRefresh()
        H.fireInfo(T.f)
    end)
    H.wait(4000, function() return T.off or (H.cardFire(T.f) and #(S.cardNeeds or {}) > 0) end, function(ok)
        if T.off then return end
        local lighter = ZeD.tr("UI_ZeD_Fire_NeedsLighter")
        local fuelFirst = ZeD.tr("UI_ZeD_Fire_NeedsFuelFirst")
        local line = nil
        for _, l in ipairs(S.cardNeeds or {}) do if not line and (H.hasLc(l, lighter) or H.hasLc(l, fuelFirst)) then line = l end end
        local L2 = T.L .. " (FI10): with paper, no fuel and no lighter, Light's NEEDS line names the lighter or matches (the game lights tinder with no fuel, CM:257)"
        local foreign = H.foreignFire(false)
        if #foreign > 0 then
            Q.skip(L2, "his reach holds fuel, tinder or a starter the script did not give: " .. H.list(foreign, 8))
        elseif not H.carried(T.paper) then
            Q.skip(L2, "the paper the script gave is not in his bags")
        else
            Q.check(line ~= nil and H.hasLc(line, lighter), L2,
                "Light's line: \"" .. tostring(line) .. "\"; every NEEDS line: " .. H.list(S.cardNeeds) .. "; the game's menu on the campfire: " .. T.gameMenu
                .. " (its no lighting method line " .. tostring(T.gameNo ~= nil) .. ")")
        end
        local raw = ZeD.tr("UI_ZeD_Fire_ScaleHours", 2)
        H.note("FI10: the hour mark \"" .. raw .. "\" as drawn: " .. H.drewAll(raw, 2) .. " (ZeD.textCase on the key: OCF:358, ZUI:1045)")
    end)
    H.caseEnd(T.L)
end

-- =====================================================================================================================
-- SEATED (run last): PW9, FL5, FI9
-- =====================================================================================================================
function C.seatLeg(T, label, open, shown, gameMenuFn)
    H.step(2, function()
        if T.off then return end
        H.closeCard()
        T.gm = gameMenuFn and gameMenuFn() or nil
        open()
    end)
    Q.waitMs(1500)
    H.step(1, function()
        if T.off then return end
        local s = shown()
        local gameWin = RT.find(function(t) local ty = tostring(t.Type or ""); return ty == "ISFluidTransferUI" or ty == "ISFluidInfoUI" or ty == "ISGeneratorInfoWindow" end) ~= nil
        Q.check(s or gameWin or (T.gm ~= nil and T.gm == "nothing"), label .. ": seated in a passenger seat, the press shows something (ZeD's card or the game's window), or the game offers nothing seated either",
            "the card " .. tostring(H.kind()) .. " (ZeD's last close: " .. tostring(ZeD_WorldWindow._closeWhy) .. "); a game window " .. tostring(gameWin)
            .. "; the game's own menu seated: " .. tostring(T.gm))
        H.closeCard()
    end)
end
function C.seated()
    local T = { L = "seated" }
    H.step(2, function()
        H.caseStart(T)
        if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY) then
            T.off = true
            Q.skip("PW9, FL5, FI9 seated", "the prelude's car helpers are not loaded (zedqa_prelude.lua runs first)")
            return
        end
        ZEDQA_CAR_WAIT("Base.CarNormal", "ocp_tab", function(v)
            T.v = v
            S.cars[#S.cars + 1] = v
            local key = ZEDQA_CAR_PREP(v)
            if key then S.keep[key] = true; S.made[#S.made + 1] = key; S.carKey = key end
            H.snapAt(v:getX(), v:getY(), 0)
        end, function(why) T.noCar = why or "no ready car" end, 6000)
    end)
    H.wait(45000, function() return T.off or T.v ~= nil or T.noCar ~= nil end, function(ok)
        if T.off then return end
        if not T.v then T.off = true; Q.skip("PW9, FL5, FI9 seated", "no car on the strip: " .. tostring(T.noCar)); return end
        H.goTo(T.v:getX() - 2.5, T.v:getY() + 0.5, 0)
        local g = H.mkGen(H.firstFree(S.RING2), { fuel = 2, cond = 100, conn = true })
        T.gen = g and g.obj
        T.b = H.give(S.FT.bottle)
        H.fill(H.fcOf(T.b), { { H.fluid("Water"), 0.5 } })
        T.b2 = H.give(S.FT.bottle)
        H.fill(H.fcOf(T.b2), {})
    end)
    C.fireLay(T, function() return H.firstFree(S.RING2) end, nil)
    H.step(2, function()
        if T.off then return end
        local ok, why = ZEDQA_CAR_ENTER(T.v, 1)
        if not ok then T.off = true; Q.skip("PW9, FL5, FI9 seated", "the passenger seat: " .. tostring(why)) end
    end)
    Q.waitMs(1000)
    C.seatLeg(T, "PW9 the generator's Info", function() if T.gen then H.genInfo(T.gen) end end,
        function() return T.gen ~= nil and H.kind() == "generator" end,
        function() local m = T.gen and H.gameMenu({ T.gen }) or {}; local g = H.menuLike(m, getText("ContextMenu_Generator")); return g and H.menuNames(m, 10) or "nothing" end)
    C.seatLeg(T, "FL5 a bottle's Liquid > Transfer", function() H.openItemFluid(T.b, false) end, function() return H.kind() == "fluid" end, nil)
    C.seatLeg(T, "FL5 a bottle's Liquid > Show info", function() H.openItemFluid(T.b, true) end, function() return H.kind() == "fluid" end, nil)
    C.seatLeg(T, "FI9 the campfire's Info", function() H.fireInfo(T.f) end, function() return H.kind() == "fire" end,
        function() local iso = H.fireIso(T.f); local own = {}; if iso then local _, _, o2 = H.gameMenu({ iso }); own = o2 or {} end; return (#own > 0) and H.menuNames(own, 10) or "nothing" end)
    H.step(2, function()
        pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    end)
    H.step(6, function()
        if T.v then
            if ZEDQA_CAR_KEEP then ZEDQA_CAR_KEEP[T.v] = nil end
            pcall(ZEDQA_CAR_AWAY, T.v, S.carKey)
            S.carKey = nil
        end
    end)
    Q.waitMs(800)
    H.caseEnd(T.L)
end

-- ===================================================================== multiplayer and words (no in-game case)
function C.skips()
    H.step(2, function()
        Q.skip("PW6 the generator changing while the card is open", "multiplayer: another player's Take, Turn off or Add fuel, the server's fuel and condition against the client's copy")
        Q.skip("FI8 the fire changing while the card is open", "multiplayer: two players feeding one fire, a piece taken by another player between the scan and the press")
        H.note("PW10: \"+%.1f L\" and the \"%.4f L/h\" fallback are built in code (OCP:673, 690); FacePop's header (FP:26-28) and FEATURE_MAP rows 360, 362 are stale (the map's top): no in-game case")
    end)
end

-- ===================================================================== put back
function H.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    H.speed(1)
    H.qstop()
    H.park(false)
    H.padOff()
    H.popClose()
    H.closeCard()
    H.hiddenBack()
    H.wrapOff()
    pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    for _, c in ipairs(S.objs) do H.rmObj(c) end
    for _, fr in ipairs(S.fires) do H.rmFire(fr) end
    S.fireSwept = H.fireSweep()
    for _, it in ipairs(S.made) do H.removeItem(it) end
    H.recipeBack()
    S.xpGrew, S.xpLeft = H.xpBack()
    if f.recorded then
        pcall(function() S.p:setTimedActionInstantCheat(f.inst and true or false) end)
        pcall(function() if f.tod then getGameTime():setTimeOfDay(f.tod) end end)
        H.statsBack()
    end
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        H.putBack()
        H.home()
    end)
    Q.step(6, function()
        for _, v in ipairs(S.cars) do
            if ZEDQA_CAR_KEEP then ZEDQA_CAR_KEEP[v] = nil end
            if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, v) else pcall(function() v:permanentlyRemove() end) end
        end
    end)
    Q.waitMs(1500)
    Q.step(10, function()
        local f = S.found
        if not f.recorded then return end
        S.swept = H.sweepNew()
        S.lost = H.unstash()
        local now, n = {}, 0
        for _, it in ipairs(H.all()) do local ft = H.ft(it); now[ft] = (now[ft] or 0) + 1 end
        for ft, was in pairs(f.types or {}) do
            for _ = 1, was - (now[ft] or 0) do
                local it = nil
                pcall(function() it = H.inv():AddItem(ft) end)
                if it then f.inv0[it] = true; n = n + 1 end
            end
        end
        S.refilled = n
        S.floorSwept = H.sweepFloor()
        S.fireSwept = (S.fireSwept or 0) + H.fireSweep()
        H.hands()
        H.home()
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "ocp_tab") end
        H.lootRefresh()
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then return end
        pcall(ZeD_CharacterWindow.openTab, S.pn, f.ctab or "loot")
        RT.worldTab(f.wtab or "loot")
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        local carsLeft = 0
        for _, v in ipairs(S.cars) do
            local live = false
            pcall(function() local it = getCell():getVehicles():iterator(); while it:hasNext() do if it:next() == v then live = true end end end)
            if live then carsLeft = carsLeft + 1 end
        end
        Q.check(carsLeft == 0, "put back: the car the run spawned is gone", #S.cars .. " spawned, " .. carsLeft .. " left")
        local left = {}
        for _, it in ipairs(S.made) do if not H.gone(it) then left[#left + 1] = H.ft(it) .. " (" .. H.whereText(it) .. ")" end end
        Q.check(#left == 0, "put back: every thing the run gave is gone (the bags, the floor, the crates, the fires)", #S.made .. " given; left " .. H.list(left, 8))
        local extra = {}
        for _, it in ipairs(H.all()) do if not f.inv0[it] then extra[#extra + 1] = H.ft(it) end end
        Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (nothing made left, his set-aside things back)",
            "new " .. H.list(extra, 8) .. "; " .. tostring(S.swept) .. " swept, " .. tostring(S.floorSwept) .. " off the floor, " .. tostring(S.refilled)
            .. " of his own used things given again, " .. tostring(S.lost) .. " set-aside things not given back")
        local objs = {}
        for _, c in ipairs(S.objs) do if H.objLeft(c) then objs[#objs + 1] = c.what end end
        for _, fr in ipairs(S.fires) do if H.fireLua(fr) ~= nil then objs[#objs + 1] = "the campfire at " .. fr.sq:getX() .. "," .. fr.sq:getY() end end
        Q.check(#objs == 0, "put back: every object laid is gone (generators, the range, the collector, the well, campfires, the fireplace, barbecues, crates)",
            #S.objs .. " laid, " .. #S.fires .. " campfires; left " .. H.list(objs) .. "; fires put out near home and the building " .. tostring(S.fireSwept))
        local lvlLeft = 0
        pcall(function() for _, r in ipairs(S.xp) do if S.p:getPerkLevel(r.perk) ~= r.lvl then lvlLeft = lvlLeft + 1 end end end)
        if S.xpLeftText then H.note("put back: XP drift left (levels checked): " .. S.xpLeftText) end
        Q.check(lvlLeft == 0 and H.elecLvl() == f.elec, "put back: Electricity and every skill level as found", tostring(S.xpGrew) .. " skills changed, " .. lvlLeft
            .. " not at their level; Electricity " .. H.elecLvl() .. " (found " .. tostring(f.elec) .. ")")
        local tbad = {}
        for k, was in pairs(f.traits or {}) do if H.hasTrait(k) ~= was then tbad[#tbad + 1] = k end end
        Q.check(H.recipeInList("Generator") == (f.genRecipe == true) and #tbad == 0, "put back: the Generator recipe and his traits as found",
            "the recipe " .. tostring(H.recipeInList("Generator")) .. " (found " .. tostring(f.genRecipe) .. "); traits changed " .. H.list(tbad))
        local sbad = {}
        for k, v in pairs(f.stats or {}) do local now2 = H.stat(k); if v and now2 and math.abs(now2 - v) > 0.01 then sbad[#sbad + 1] = k .. " " .. H.n2(now2) .. " (" .. H.n2(v) .. ")" end end
        if #sbad > 0 then H.note("put back: stats that moved after the put-back (the clock ran): " .. H.list(sbad, 8)) end
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and S.p:getVehicle() == nil and H.qlen() == 0 and getGameSpeed() == 1,
            "put back: he stands where he stood, on foot, no action queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
        Q.check(ZeD.currentBase == f.base and ZeD.currentSize == f.size and H.lockFound() == (S.lockWas or H.lockFound()) and S.parked == nil and S.w0 == nil and H.wrapped()
            and H.optVal(ZeD.Settings and ZeD.Settings.hiddenActionsOption) == f.hiddenIdx and H.entry() == nil and not H.popUp(),
            "put back: the theme, the text size, the input lock, the pointer, the hidden-actions setting, the draw watchers, the card drawer and the pop-out as found",
            tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", lock " .. H.lockFound() .. ", hidden " .. H.hiddenNow() .. ", card " .. tostring(H.kind()))
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught" .. (S.zerr and (": " .. S.zerr) or ""))
        if S.cardErrs then Q.check(false, "the object card drew without an error", S.cardErrs .. " times; last " .. tostring(S.cardErrLast)) end
        local e1 = H.errN()
        if S.err0 and e1 then
            -- every case window was split at its end; the last stretch (put back) is split here
            local other, own = H.errSplit(S.e0 or S.err0, e1)
            local ownAll = (S.ownErrs or 0) + own
            local notOurs = (e1 - S.err0) - ownAll
            Q.check(notOurs == 0, "the Power, Fluid and Fire card run ran with no Lua error", notOurs .. " new"
                .. ((ownAll > 0) and (" (" .. ownAll .. " more in ocp_tab's own code: a test fault)") or ""))
            if other > 0 then H.note("put back: " .. other .. " of those during the put-back itself") end
        else Q.skip("the run's Lua error count", "the game's Lua error count cannot be read here") end
        H.note("pictures: " .. H.list(S.shots))
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
        if f.recorded then
            pcall(function() if f.invinc ~= nil then S.p:setInvincible(f.invinc) end end)
            pcall(function() if f.god ~= nil then S.p:setGodMod(f.god) end end)
        end
    end)
end

-- ===================================================================== the run
S.setup()
C.skips()
C.pw1()
C.pw2()
C.pw3()
C.pw4()
C.pw5()
C.pw7()
C.pw8()
C.pw9()
C.flStart()
C.fl1()
C.fl2()
C.fl3()
C.fl4()
C.fl6()
C.fl7()
C.fl8()
C.fl9()
C.fl10()
C.flEnd()
C.fi1()
C.fi2()
C.fi3()
C.fi4()
C.fi5()
C.fi6()
C.fi7()
C.fi9()
C.fi10()
C.seated()
S.buildPutBack()
Q.start()
