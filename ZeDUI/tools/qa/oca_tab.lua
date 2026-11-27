-- ZeDUI/tools/qa/oca_tab.lua  (Nov 26 2026, QA; tag oca_tab): four of ZeD's object cards in the World window's card
-- drawer, the gamut sweep: Farm (plots and crops, ObjectCardFarm.lua), Trough (ObjectCardTrough.lua), Hutch
-- (ObjectCardHutch.lua) and Hook (the butcher's hook, ObjectCardHook.lua). Its spec is the read-only map
-- ZeDUI/qa/audits/2026-11-26_map_cards_farm_animals.md (section 5's suspicions FA1-FA13, TG1-TG10, HU1-HU9, HK1-HK12,
-- section 3's states, section 4's gaps). Run after zedqa_prelude.lua and rt_kit.lua (oca.txt). grep "ZEDQA oca_tab".
-- Built in the style of mt_tab.lua (the helpers, the pad, the pictures, the drawn-words wrapper, the logging, his own
-- things set aside) and ck_tab.lua (the text size), with the farm, trough, hutch and hook staging of bx_farm.lua,
-- zedqa_cov_farmcards.lua and zedqa_animals.lua.
-- HOW IT JUDGES: each suspicion single player can stage is proved or cleared in the running game against the game's
-- own answers: the plant's own fields (health, waterLvl, fertilizer, the pests, nbOfGrow, waterNeeded, cursed, state,
-- read on the farming system's server object), the trough's fluid and food (getWater, its fluid container, its
-- items, getCurrentFeedAmount, the trough system's own object), the hutch's eggs (each nest box's getEggsNb), the
-- hook's carcass, blood and parts (the hook's animal and its mod data: BloodQty, leather, headless, parts; the
-- animal bodies on the ground), and what the game's own actions did (the doses applied, the items used up, the eggs
-- taken, the seeds given, the timed actions in the game's queue). Never through ZeD's code under test: what the card
-- shows is read from its draw (the words, the status marks and the buttons the card drew last frame, each by its
-- place), and what it offers from its verb row. A check FAILs when the suspicion holds (with the evidence) and PASSes
-- when it does not; where the game's own menu has the same gap a NOTE says so. (Nov 26 2026, after the first 4K
-- run: FA1, FA5, FA6, FA7 at None, FA9 below Farming 6, TG4 and HK5 are game parity and read as NOTEs, each saying
-- which game code behaves the same; TG6's system-object reading is a NOTE, as single player never writes it.)
-- HOW IT PRESSES: a mouse press is the card's own hit test at the zone's middle (ZeD_ObjectCard:zoneAt) and the zone's
-- run, as the card's release runs it; a zone that the hit test does not reach there is pressed as the pad's A presses
-- it, said once. A pad press goes through FocusManager's QA hook and its own dispatch on the World window (RT.pad +
-- RT.padDown, focus by focusWhere in the worldItemCard zone), the input mode locked to the controller and put back.
-- WHERE: ZEDQA_HOME first (the Irvington drag strip, 925.5,13040.5). Farming needs soil: the nearest 9 x 6 block of
-- the game's own "dirt" (ISShovelGroundCursor.GetDirtGravelSand, the game's plow rule) within 40 tiles of home is the
-- farm; the nearest 15 x 11 of open ground there, clear of the farm, is the yard (the trough, the hen house, the hooks,
-- the dead animals). He is put on the farm or the yard for each case and comes home at the end.
-- Timed actions run with the game's instant cheat (the walks still walk) except where a case needs the walk.
-- Cases (FA, TG, HU, HK: the map's suspicions; mouse and pad where the verb has a press):
--   FA1  Fertilize twice: (mouse) two presses during the walk on a young plant at 60 health, fertilizer 0; (pad) A A
--        on a fresh one; (third) a fresh plant staged at fertilizer 2 and 25 health, one press: the doses queued,
--        the plant's fertilizer and health after each dose, the fertilizer's uses, cursed, state; whether the card
--        asks or reads the dose before the next
--   FA2  a crop needing 80 water at stage 2, set to 65 and to 60, at Farming 3 and 4: the card's water word and its
--        mark, the garden cell's mark and the garden summary against the game's ISFarmingInfo.getWaterLvlColor and
--        calcWater. Picture oca_farm_<WxH>
--   FA3  the pad's opening focus on a watered, unripe plant with no water carried and fertilizer in the bags
--        (opened through the game's Info): where it lands, then A (the plant's fertilizer after)
--   FA4  the Dig question open while the shown plot is removed by the game's own Remove (ISFarmingMenu.onShovel), a
--        plot of another crop beside it: the question after the card steps on, Yes (mouse; pad): which plot is dug
--   FA5  Harvest on a Ready plant (mouse) and on one In bloom (pad): the main verb at Ready, the seeds the game gave
--   FA6  Fertilize on a dead plot (mouse), Compost on a composted plot (pad): the item's uses against the plant
--   FA7  Treat at Farming 3 on aphids at None (mouse): the spray's uses; heavy aphids (60) by the pad: the presses
--        and the walks and equips it takes against the game's one spray of up to 10 uses
--   FA8  a smaller and a bigger drinking-water container carried (mouse; pad): the card's Water from against the
--        game's set of sources (ISFarmingMenu.doFarmingMenu2), biggest first, each with its litres, +N and Use; Use
--        on the smaller then Water (which one the game's watering emptied, the level after); then a fresh card with
--        nothing picked: Water alone pours from the biggest
--   FA9  seasons on (the sandbox's PlantGrowingSeasons, put back): sowing out of season at Farming 5 without the
--        season recipe (mouse): the plant's cursed flag and what the card said; at Farming 6 (pad): the tag
--   FA10 small screens: the drawer at 480 units, the inventory beside the card, the card inside the screen, at the
--        run's size, with Large text and at UI scale 2 (a FAIL only at 1280x800; a NOTE at other sizes); the garden's
--        three-letter labels against their cells at Large text
--   FA11 the words: UI_ZeD_Farm_MoreAt and UI_ZeD_Farm_ListAnd in the mod's UI.json files (the game's mod file
--        reader); the three-letter garden labels that collide in the run's language; a trampled (destroyed) plant's
--        tag against the game's name; the German capitals (a NOTE: only a German run reads them)
--   FA12 a field of 27 plots in reach: the card's frame cost against one plot (a NOTE); the shovel dropped between
--        Dig and Yes: what Yes queued and the game's Lua error count. MP: SKIP
--   FA13 test drift: a NOTE
--   TG1  a bottle of bleach (mouse) and one of gasoline (pad) carried: listed to pour, and the pour through the fluid
--        card: what the trough holds after (the game's own trough path pours water only)
--   TG2  a feed bag drained to no feed in the trough: the card's tag against getCurrentFeedAmount
--   TG3  food in (the game's debug add), Take All (mouse; pad, hidden actions all): Add water against the trough's
--        fluid container, its NEEDS line when it is drawn greyed
--   TG4  a double trough with one tile in an animal zone: the card's zone line against each tile's zone. MP: SKIP
--   TG5  ten carrots (or three feed bags): one Add then Add All (mouse, carried), one Take then Take All (pad, in
--        the trough): one press moves one, the All row (its label the game's) moves the rest
--   TG6  Empty (mouse; pad): the trough system's own object against the trough after; the question's words (TG9).
--        Picture oca_trough_<WxH>. MP: SKIP
--   TG7  the Transfer row and the fluid card's Pour (mouse; pad): which card is up after the pour
--   TG8  small screens: as FA10, the trough card
--   TG9  the words: the fluid's name in the Empty question against the game's, "L" in the numbers (in TG6)
--   TG10 test drift: a NOTE
--   HU1  four boxes with eggs, Grab eggs (mouse) and the pointer off the window (the window rolls up): the eggs left
--        in each box while rolled and after it opens again; the pad's Grab eggs with the window down as the control.
--        Picture oca_hutch_<WxH>
--   HU2  SKIP (MP: the server's egg sync)
--   HU3  the card left open while the game runs fast (60 s at speed 3): the hutch's dirt and eggs (a NOTE: the card
--        never calls reforceUpdate; days of play are needed to prove a stalled hutch)
--   HU4  a hen carried to a full hutch, and to one with both doors shut: what the card shows against the game's
--        menu (greyed, "Hutch full", "Doors closed")
--   HU5  the pad: a box's Grab, then where the focus is when that box empties; a bird's Info, then B: the way back
--   HU6  Large text with four boxes and a sitting hen with a long name: Grab against its box, the words in the card
--   HU7  the words: UI_ZeD_Hutch_Birds and UI_ZeD_Hutch_Eggs in the UI.json files; one egg: "1 eggs"
--   HU8  the leash: he stands where the game's DistToProper from the entry is just past 5, and past 5.5: the card
--   HU9  test drift: a NOTE
--   HK1  two dead cows beside the hook, Hang on row 1 then row 2 (mouse); a carried carcass, A A (pad): the puts
--        queued, what is on the hook, what lies on the ground, any hook animal left orphaned
--   HK2  Bleed with no bucket (pad): the band's percent and the Blood row against the game's
--        getRemovingBloodProgress and BloodQty while it bleeds. Picture oca_hook_<WxH>
--   HK3  (single player) bleeding, the header's > to a second hook and < back: the card after the bleed ends; the
--        split-screen half SKIP (a second local player)
--   HK4  the pad from the Animals tab's hook row: the opening focus and A (what the game queued)
--   HK5  Meat (mouse) and Head (pad) with blood still in: a question, and the blood the game spilled
--   HK6  a part the animal never had (the game's leather false): the card's word and Gather (mouse; pad)
--   HK7  only a dead hen near (not a hook animal): Add corpse lit, and where it jumps (mouse; pad)
--   HK8  that row's name: no bare key and no "%1"
--   HK9  Large text: the part labels against the value column; the card at the run's size
--   HK10 SKIP (MP: the using player on a client)
--   HK11 the card's blood liters against the game's BloodQty, and the Animals tab's format (a NOTE)
--   HK12 test drift: a NOTE
--   every case: no Lua error over it; everything it staged is taken away before the next
-- Puts back: every plot and plant made (and each square's plowDay), every trough, hen house, hook, hen, cow and animal
-- body made, every hook animal (and any orphan), every zone drawn, anything new lying on the farm and the yard, the
-- items given and anything new on him, his own set-aside things, his skills (Farming, Butchering, Animal Care: every
-- skill as found, XP drift a NOTE), the season recipes, the sandbox's PlantGrowingSeasons, the hidden-actions
-- setting, the text size, the UI scale, the windows (the World window's tab, the card drawer shut, the Animals tab's
-- view, the Character window's tab, the layout), the pad lock, the pointer, the draw watchers, the instant cheat, the
-- build cheat, the farming menu's cursor, his body (stiffness, blood), game speed 1, the clock, where he stood, god
-- mode and invincible as found. Known leftovers: the grass the game's plow and dig cut, blood splats on the ground,
-- XP the game's actions gave (put back as levels; drift a NOTE).

if not (RT and RT.make) then
    print("ZEDQA oca_tab ERR rt_kit.lua did not run first")
    print("ZEDQA oca_tab VERDICT FAIL 1")
    print("ZEDQA oca_tab DONE")
    return
end
local Q = RT.make("oca_tab")
Q.maxMs = 2250000                    -- (the runner gives this script 2400 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, shots = {}, errs = 0, dead = false,
            xp = {}, said = {}, texts = {}, dots = {}, btns = {}, plots = {}, plowDay = {}, animals = {}, gone = {},
            hutches = {}, troughs = {}, zones = {}, bodies = {}, recipesOff = {}, stash = {}, keepAn = {} }
local H = {}
local C = {}
S.OC = ZeD and ZeD.ObjectCards
S.F = RT.focus()
S.WWm = ZeD_WorldWindow
S.HOME = { x = 925.5, y = 13040.5, z = 0 }
S.REACH = 40
S.FW, S.FH = 9, 6          -- the farm: plots on its first rows, he stands on its fourth
S.YW, S.YH = 15, 11        -- the yard
S.PESTS = { "mildewLvl", "fliesLvl", "aphidLvl", "slugsLvl" }
S.BLOCK = { "wall", "fenc", "door", "window", "gate", "roof", "location_", "fixtures_", "furniture_", "appliances_" }

if not (S.p and S.OC and S.OC.kinds and S.WWm and S.WWm.getObjectCard and ZeD.Molecules and ZeD.Atoms and ZeD_ObjectCard) then
    Q.check(false, "the player, ZeD's object cards and the World window are loaded")
    Q.start()
    return
end

-- ===================================================================== small helpers (mt_tab's)
function H.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
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
function H.pause(ms) Q.waitMs(ms) end
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
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
function H.screen() local w, h = 0, 0; pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end); return math.floor(w), math.floor(h) end
function H.sizeTag() local w, h = H.screen(); return w .. "x" .. h end
function H.isDeck() local w, h = H.screen(); return w == 1280 and h == 800 end
function H.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z or 0)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z or 0)
    end)
end
function H.home() local f = S.found; if f.pos then H.goTo(f.pos.x, f.pos.y, f.pos.z) end; if f.dir then pcall(function() S.p:setDir(f.dir) end) end end
function H.zcall(fn)
    local ok, err = pcall(fn)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(err) end
    return ok
end
function H.has(s, sub) return type(s) == "string" and type(sub) == "string" and sub ~= "" and string.find(s, sub, 1, true) ~= nil end
function H.low(s) return string.lower(tostring(s or "")) end
function H.lang() local l = "?"; pcall(function() l = tostring(Translator.getLanguage():name()) end); return l end
function H.txt(k, fb) local s = nil; pcall(function() s = getTextOrNull(k) end); return s or fb or k end
function H.tr(k, ...) local s = k; local a = { ... }; pcall(function() s = ZeD.tr(k, a[1], a[2], a[3]) end); return s end
-- a verdict that holds only where the map asks for it: a check at 1280x800, a NOTE at any other size
function H.sizeCheck(ok, what, detail)
    if H.isDeck() then return Q.check(ok, what, detail) end
    H.note(what .. ": " .. (ok and "holds" or "does not hold") .. " at " .. H.sizeTag() .. " (checked only at 1280x800) | " .. tostring(detail))
    return ok
end

-- ===================================================================== the timed-action queue (the game's)
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 14) end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.doing() local d = false; pcall(function() d = ISTimedActionQueue.isPlayerDoingAction(S.p) and true or false end); return d end
function H.instant(on) pcall(function() S.p:setTimedActionInstantCheat(on and true or false) end) end
-- queue: the game's queue emptied (speed spd, 2 by default: the walks run there), at most ms
function H.idleQ(T, ms, spd)
    H.step(1, function()
        if T.off then return end
        T.qt0 = getTimestampMs()
        H.speed(spd or 2)
    end)
    H.wait(ms, function() return T.off or (H.qlen() == 0 and not H.doing() and getTimestampMs() - (T.qt0 or 0) > 400) end, function(ok)
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
function H.uses(it)
    local u = nil
    if not H.isItem(it) then return nil end
    pcall(function() u = it:getCurrentUses() end)
    if u == nil then pcall(function() u = it:getCurrentUsesFloat() end) end
    return u
end
function H.fc(it) local f = nil; if H.isItem(it) then pcall(function() f = it:getFluidContainer() end) end; return f end
function H.amount(it) local a = -1; pcall(function() a = H.fc(it):getAmount() end); return a end
function H.fill(it, fluid)
    pcall(function()
        local f = H.fc(it)
        f:Empty()
        if fluid then f:addFluid(fluid, f:getCapacity()) end
    end)
end
function H.inv() return S.p:getInventory() end
function H.known(ft) local ok = false; if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end; return ok end
function H.firstKnown(list) for _, ft in ipairs(list) do if H.known(ft) then return ft end end; return nil end
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
function H.giveN(ft, n) local o = {}; for _ = 1, n do local it = H.give(ft); if it then o[#o + 1] = it end end; return o end
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
function H.gone(it) return H.where(it) == nil end
function H.sweepNew()
    local n = 0
    for _, it in ipairs(H.all()) do
        if not S.found.inv0[it] then H.removeItem(it); n = n + 1 end
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
-- his own things a case's game action would reach for, set aside (given back to the container they came from)
function H.asideTest(it)
    local ft = H.ft(it)
    if S.SEEDS and S.SEEDS[ft] then return true end
    local set = { ["Base.Fertilizer"] = true, ["Base.CompostBag"] = true, ["Base.AnimalFeedBag"] = true, ["Base.Carrots"] = true,
                  ["Base.HayTuft"] = true, ["Base.Egg"] = true, ["Base.Shovel"] = true, ["Base.GardeningSprayAphids"] = true,
                  ["Base.GardeningSprayMilk"] = true, ["Base.GardeningSprayCigarettes"] = true, ["Base.SlugRepellent"] = true }
    if set[ft] then return true end
    local hit = false
    pcall(function()
        if it:hasTag(ItemTag.FERTILIZER) or it:hasTag(ItemTag.COMPOST) or it:hasTag(ItemTag.CLEAN_STAINS) or it:hasTag(ItemTag.BUTCHER_ANIMAL) then hit = true end
    end)
    if hit then return true end
    if H.fc(it) ~= nil then return true end
    pcall(function() if ISFarmingMenu.getShovel and instanceof(it, "HandWeapon") and it:hasTag(ItemTag.DIG_PLOW) then hit = true end end)
    pcall(function() if instanceof(it, "AnimalInventoryItem") or it:getType() == "CorpseAnimal" then hit = true end end)
    return hit
end
function H.stashAside()
    local kept = 0
    for _, it in ipairs(H.all()) do
        if S.found.inv0[it] and not S.found.stashed[it] and H.asideTest(it) then
            local c, free = nil, false
            pcall(function()
                c = it:getContainer()
                free = it:getAttachedSlot() == -1 and not it:isEquipped() and not S.p:isEquippedClothing(it)
                    and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
            end)
            if c and free and pcall(function() c:Remove(it) end) then
                S.stash[#S.stash + 1] = { it = it, c = c }
                S.found.stashed[it] = true
            else
                kept = kept + 1
            end
        end
    end
    return #S.stash, kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        if H.where(s.it) == nil then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end
-- a held thing still on him that no case stashed (a canteen on the belt): the game's actions may reach for it
function H.ownWaterLeft()
    local o = {}
    for _, it in ipairs(H.all()) do
        if S.found.inv0[it] and not S.found.stashed[it] then
            local u = 0
            pcall(function() u = ISFarmingMenu.getWaterUsesInteger(it) end)
            if u > 0 then o[#o + 1] = H.nm(it) end
        end
    end
    return o
end

-- ===================================================================== skills, recipes, the body
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
function H.perk(name) local p = nil; pcall(function() p = Perks[name] end); if p == nil then pcall(function() p = Perks.FromString(name) end) end; return p end
function H.perkSet(name, n) pcall(function() S.p:setPerkLevelDebug(H.perk(name), n) end) end
function H.perkLvl(name) local l = -1; pcall(function() l = S.p:getPerkLevel(H.perk(name)) end); return l end
function H.farmLvl() local l = -1; pcall(function() l = CFarmingSystem.instance:getXp(S.p) end); return l end
function H.recipeInList(r) local k = false; pcall(function() k = S.p:getKnownRecipes():contains(r) and true or false end); return k end
function H.recipeKnown(r) local k = false; pcall(function() k = S.p:isRecipeActuallyKnown(r) and true or false end); return k end
-- a recipe he knows, forgotten for a case (given back at the end)
function H.recipeOff(r)
    if not r or not H.recipeInList(r) then return end
    pcall(function() S.p:getKnownRecipes():remove(r) end)
    S.recipesOff[#S.recipesOff + 1] = r
end
function H.recipesBack()
    for _, r in ipairs(S.recipesOff) do if not H.recipeInList(r) then pcall(function() S.p:learnRecipe(r) end) end end
    S.recipesOff = {}
end
function H.stiffSnap()
    S.found.stiff = {}
    pcall(function()
        local parts = S.p:getBodyDamage():getBodyParts()
        for k = 0, parts:size() - 1 do S.found.stiff[k] = parts:get(k):getStiffness() end
    end)
end
function H.bodyBack()
    pcall(function()
        local parts = S.p:getBodyDamage():getBodyParts()
        for k = 0, parts:size() - 1 do if S.found.stiff[k] then parts:get(k):setStiffness(S.found.stiff[k]) end end
    end)
    -- (the butchering puts blood on him and his clothes: washed off)
    pcall(function()
        local hv = S.p:getHumanVisual()
        for i = 0, BloodBodyPartType.MAX:index() - 1 do
            local part = BloodBodyPartType.FromIndex(i)
            hv:setBlood(part, 0)
            hv:setDirt(part, 0)
        end
    end)
    pcall(function()
        local worn = S.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local it = worn:getItemByIndex(i)
            local vis = it and it:getVisual()
            if vis then
                for k = 0, BloodBodyPartType.MAX:index() - 1 do
                    local part = BloodBodyPartType.FromIndex(k)
                    vis:setBlood(part, 0)
                    vis:setDirt(part, 0)
                end
            end
            pcall(function() it:setBloodLevel(0) end)
        end
    end)
    pcall(function() S.p:resetModelNextFrame() end)
    pcall(function() sendVisual(S.p) end)
end

-- ===================================================================== the pad (mt_tab's, on the World window's card)
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
function H.cardRing()
    local w = RT.ww()
    for i, z in ipairs((w and w._focusRing) or {}) do if z.zone == "worldItemCard" then return z, i end end
    return nil, nil
end
function H.stops() local z = H.cardRing(); return (z and z.elements) or {} end
function H.stopIds(pre)
    local o = {}
    for _, e in ipairs(H.stops()) do
        local id = tostring(e.id)
        if pre == nil or string.sub(id, 1, #pre) == pre then o[#o + 1] = id end
    end
    return o
end
-- where the controller is in the card: the card zone's focused stop (the window moves it to the card's opening focus
-- once that stop is drawn); with no ring, the card's ask
function H.landed()
    local z = H.cardRing()
    local el = z and z.elements and z.elements[z.focusedElementIdx or 1]
    if el then return el.id end
    local c = H.card()
    return c and c._pendingFocus or nil
end
function H.ringOnCard() local w = RT.ww(); local _, i = H.cardRing(); return w ~= nil and i ~= nil and w._focusIdx == i end
function H.focusCard(id)
    local w = RT.ww()
    if not (w and S.F and S.F.focusWhere and id) then return false end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "worldItemCard", function(el) return el.id == id end) end)
    return e ~= nil
end
-- a tap queued on the World window: down through the QA hook and FocusManager's dispatch, up 4 frames later, then the
-- hook lets go (nothing is pressed when gate says no)
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
function H.tapB(gate) H.tap("B", "BButton", gate) end
-- queue: the stop fid (or what fid() names when the case runs) focused, then A
function H.padPress(T, fid, gate)
    H.step(1, function()
        T.focusOk = nil
        if T.off or (gate and not gate()) then return end
        local id = fid
        if type(fid) == "function" then id = fid() end
        T.focusOk = H.focusCard(id)
        if not T.focusOk then H.note(T.L .. ": the pad's stop " .. tostring(id) .. " is not in the card's ring (" .. H.list(H.stopIds(), 16) .. ")") end
    end)
    H.tapA(function() return not T.off and T.focusOk == true end)
end

-- ===================================================================== the card's draw, watched (on for the run)
-- S.texts: every word the World window's object card drew last frame { s, x, y, f }; S.dots: its status marks
-- { x, y, c }; S.btns: its push buttons { label, x, y, w, fid, disabled }; S.qNow / S.qLast: the foot band's question;
-- S.needs: its NEEDS lines; S.preMs / S.preN: the time its draw took
function H.wrapOn()
    if S.w0 then return end
    local W = { pre = ZeD_ObjectCard.prerender, dot = ZeD.Atoms.drawStatusDot, btn = S.OC.ui and S.OC.ui.button,
                qb = ZeD.Molecules.drawQuestionBand, nl = ZeD.Molecules.drawNeedsLine,
                td = (ZeD.Text and type(ZeD.Text.draw) == "function") and ZeD.Text.draw or nil }
    S.w0 = W
    W.preFn = function(self, ...)
        local mine = false
        pcall(function() mine = self == S.WWm.getObjectCard(S.pn) end)
        if not mine then return W.pre(self, ...) end
        local rec, dots, btns, needs = {}, {}, {}, {}
        S.recT, S.recDots, S.recBtns, S.recNeeds, S.qFrame, S.cardNow = rec, dots, btns, needs, nil, self
        local ownD, ownR, ownC = nil, nil, nil
        pcall(function() ownD = rawget(self, "drawText"); ownR = rawget(self, "drawTextRight"); ownC = rawget(self, "drawTextCentre") end)
        local baseD, baseR, baseC = self.drawText, self.drawTextRight, self.drawTextCentre
        if baseD then self.drawText = function(s, text, tx, ty, ...) local f = select(5, ...); rec[#rec + 1] = { s = tostring(text), x = tx or 0, y = ty or 0, f = f }; return baseD(s, text, tx, ty, ...) end end
        if baseR then self.drawTextRight = function(s, text, tx, ty, ...) local f = select(5, ...); rec[#rec + 1] = { s = tostring(text), x = tx or 0, y = ty or 0, f = f, right = true }; return baseR(s, text, tx, ty, ...) end end
        if baseC then self.drawTextCentre = function(s, text, tx, ty, ...) local f = select(5, ...); rec[#rec + 1] = { s = tostring(text), x = tx or 0, y = ty or 0, f = f, centre = true }; return baseC(s, text, tx, ty, ...) end end
        S.inCard = true
        local t0 = getTimestampMs()
        local ok, res = pcall(W.pre, self, ...)
        S.inCard = false
        S.preMs = (S.preMs or 0) + (getTimestampMs() - t0)
        S.preN = (S.preN or 0) + 1
        self.drawText, self.drawTextRight, self.drawTextCentre = ownD, ownR, ownC
        S.texts, S.dots, S.btns, S.needs = rec, dots, btns, needs
        S.qNow = S.qFrame
        if S.qFrame then S.qLast = S.qFrame end
        S.drawAt = getTimestampMs()
        if not ok then S.cardErrs = (S.cardErrs or 0) + 1; S.cardErrLast = res; error(res, 0) end
        return res
    end
    W.dotFn = function(panel, x, y, color, size, ...)
        if S.inCard and panel == S.cardNow and S.recDots then S.recDots[#S.recDots + 1] = { x = x or 0, y = y or 0, c = color, s = size } end
        return W.dot(panel, x, y, color, size, ...)
    end
    W.btnFn = function(card, x, y, label, opts, ...)
        if S.inCard and card == S.cardNow and S.recBtns then
            local o = opts or {}
            S.recBtns[#S.recBtns + 1] = { label = tostring(label), x = x or 0, y = y or 0, w = o.w, h = o.h, fid = o.fid, disabled = o.disabled and true or false }
        end
        return W.btn(card, x, y, label, opts, ...)
    end
    W.qbFn = function(panel, x, y, w, question, ...)
        if S.inCard and panel == S.cardNow then S.qFrame = tostring(question) end
        return W.qb(panel, x, y, w, question, ...)
    end
    W.nlFn = function(panel, x, y, w, text, ...)
        if S.inCard and panel == S.cardNow and S.recNeeds then S.recNeeds[#S.recNeeds + 1] = tostring(text) end
        return W.nl(panel, x, y, w, text, ...)
    end
    if W.td then
        W.tdFn = function(panel, font, text, x, y, ...)
            if S.inCard and panel == S.cardNow and S.recT then S.recT[#S.recT + 1] = { s = tostring(text), x = x or 0, y = y or 0, big = true } end
            return W.td(panel, font, text, x, y, ...)
        end
        ZeD.Text.draw = W.tdFn
    end
    ZeD_ObjectCard.prerender = W.preFn
    ZeD.Atoms.drawStatusDot = W.dotFn
    if W.btn then S.OC.ui.button = W.btnFn end
    ZeD.Molecules.drawQuestionBand = W.qbFn
    ZeD.Molecules.drawNeedsLine = W.nlFn
end
function H.wrapOff()
    local W = S.w0
    if not W then return end
    if ZeD_ObjectCard.prerender == W.preFn then ZeD_ObjectCard.prerender = W.pre end
    if ZeD.Atoms.drawStatusDot == W.dotFn then ZeD.Atoms.drawStatusDot = W.dot end
    if W.btn and S.OC.ui.button == W.btnFn then S.OC.ui.button = W.btn end
    if ZeD.Molecules.drawQuestionBand == W.qbFn then ZeD.Molecules.drawQuestionBand = W.qb end
    if ZeD.Molecules.drawNeedsLine == W.nlFn then ZeD.Molecules.drawNeedsLine = W.nl end
    if W.td and ZeD.Text.draw == W.tdFn then ZeD.Text.draw = W.td end
    S.w0 = nil
end
function H.wrapped()
    local W = S.w0
    if not W then return true end
    return ZeD_ObjectCard.prerender == W.pre and ZeD.Atoms.drawStatusDot == W.dot
end
function H.drew(sub) for _, t in ipairs(S.texts or {}) do if H.has(t.s, sub) then return t end end; return nil end
function H.drewLow(sub) local l = H.low(sub); for _, t in ipairs(S.texts or {}) do if H.has(H.low(t.s), l) then return t end end; return nil end
function H.drewExactLow(s) local l = H.low(s); for _, t in ipairs(S.texts or {}) do if H.low(t.s) == l then return t end end; return nil end
function H.textsLike(sub, max) local o = {}; for _, t in ipairs(S.texts or {}) do if H.has(H.low(t.s), H.low(sub)) then o[#o + 1] = t.s end end; return H.list(o, max or 8) end
-- a drawn word about seed that is not the stage strip's "Seedling" label (whole or cut short with dots): its words, or nil
function H.seedWord()
    local sl = H.low(H.txt("Farming_Seedling", "Seedling"))
    for _, t in ipairs(S.texts or {}) do
        local l = H.low(t.s)
        local bare = (string.gsub(l, "%.+$", ""))
        local strip = bare ~= "" and (H.has(sl, bare) or H.has(bare, sl))
        if not strip and H.has(l, "seed") then return t.s end
    end
    return nil
end
-- the words drawn on the same line as t (within dy px), but t
function H.rowOf(t, dy)
    local o = {}
    if not t then return o end
    for _, u in ipairs(S.texts or {}) do if u ~= t and math.abs(u.y - t.y) <= (dy or 6) then o[#o + 1] = u end end
    return o
end
function H.dotsNearY(y, dy) local o = {}; for _, d in ipairs(S.dots or {}) do if math.abs(d.y - y) <= (dy or 14) then o[#o + 1] = d end end; return o end
function H.dotsIn(z)
    local o = {}
    if not z then return o end
    for _, d in ipairs(S.dots or {}) do if d.x >= z.x - 1 and d.x <= z.x + z.w + 1 and d.y >= z.y - 1 and d.y <= z.y + z.h + 1 then o[#o + 1] = d end end
    return o
end
function H.btn(fid) for _, b in ipairs(S.btns or {}) do if b.fid == fid then return b end end; return nil end
function H.textW(t)
    local w = 0
    pcall(function() w = getTextManager():MeasureStringX(t.f or UIFont.Small, t.s) end)
    return w
end
-- a status mark's colour as a word: the theme's green, amber or red, or what else
function H.dotClass(c)
    local T = ZeD.T
    if c == nil then return "none" end
    if c == T.positive then return "green" end
    if c == T.warning then return "orange" end
    if c == T.danger then return "red" end
    local function near(a, b) return a and b and math.abs((a.r or 0) - (b.r or 0)) < 0.02 and math.abs((a.g or 0) - (b.g or 0)) < 0.02 and math.abs((a.b or 0) - (b.b or 0)) < 0.02 end
    if near(c, T.positive) then return "green" end
    if near(c, T.warning) then return "orange" end
    if near(c, T.danger) then return "red" end
    return "other"
end

-- ===================================================================== settings, pointer, pictures, the windows
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
-- the text size (ck_tab's)
function H.sizeSet(key)
    local o = H.zopt("textSize")
    local i = nil
    for k, v in ipairs(ZeD.Settings.sizeKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, nil, nil, key)
    S.back.size = true
end
function H.sizeBack()
    if not S.back.size then return end
    S.back.size = nil
    local o = H.zopt("textSize")
    if o and S.found.sizeIdx then pcall(function() o:setValue(S.found.sizeIdx) end) end
    pcall(ZeD.applyTheme, nil, nil, S.found.size)
end
-- the UI scale (bxr_win's): a pick as ZeD setup makes it
function H.scaleIdx(v)
    for i, k in ipairs((ZeD.Settings and ZeD.Settings.scaleKeys) or {}) do if type(k) == "number" and math.abs(k - v) < 0.001 then return i end end
    return nil
end
function H.scaleSet(i)
    local o = ZeD.Settings and ZeD.Settings.uiScaleOption
    if not (o and i) then return false end
    pcall(function() o:setValue(i) end)
    pcall(function() if o.onChange then o.onChange(o, i) end end)
    pcall(function() if o.onChangeApply then o.onChangeApply(o, i) end end)
    S.scaleAt = getTimestampMs()
    return true
end
function H.scaleSettled()
    local Sc = ZeD.Scale
    if not Sc then return true end
    if getTimestampMs() - (S.scaleAt or 0) < 600 then return false end
    if Sc._reopenAt ~= nil then return false end
    local ok = true
    pcall(function()
        local a = Sc._appliedRoot
        ok = a ~= nil and math.abs(a - Sc.compute()) < 0.001 and math.abs(Sc.root() - a) < 0.001
    end)
    return ok
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
function H.shot(name, what, gate)
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
-- both windows held down while the cards are read (an unpinned window rolls up 2 s after the pointer leaves it, and a
-- rolled-up card stops drawing and ticking: zedqa_cov_farmcards.lua, H.keepDown); god mode and invincible kept on
function H.hold(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded then pcall(function() w:setWindowShaded(false) end) end
    w._outSince = getTimestampMs() + 600000
end
function H.keepTick()
    if S.guard then
        pcall(function()
            if not S.p:isDead() then
                if not S.p:isGodMod() then S.p:setGodMod(true) end
                if not S.p:isInvincible() then S.p:setInvincible(true) end
            end
        end)
    end
    if not S.holdOn then return end
    H.hold(RT.ww())
    H.hold(RT.cw())
end
function H.holdLetGo()
    for _, w in ipairs({ RT.ww() or false, RT.cw() or false }) do if w then w._outSince = nil end end
end
-- the Animals tab's view and the World window's tab as they were (zedqa_cov_farmcards.lua's)
function H.atBack()
    local w, a = RT.ww(), S.found.at
    if not (w and a and ZeD.AnimalsTab and ZeD.AnimalsTab.getState) then return end
    pcall(function()
        local st = ZeD.AnimalsTab.getState(w)
        st.submode, st.view, st.zoneName, st.animalRef, st.prevView = a.submode, a.view, a.zoneName, a.animalRef, a.prevView
    end)
end
function H.tabBack()
    local w = RT.ww()
    local tab = S.found.wtab or "loot"
    if not w then return end
    if w._activeTab ~= tab then pcall(S.WWm.openTab, S.pn, tab) end
    pcall(function() if S.WWm.syncRing then S.WWm.syncRing(w) end end)
end

-- ===================================================================== the card (the World window's object card)
function H.card() local c = nil; pcall(function() c = S.WWm.getObjectCard(S.pn) end); return c end
function H.e() local c = H.card(); return c and c.entry or nil end
function H.t() local e = H.e(); return e and e.t or nil end
function H.d() local t = H.t(); return t and t.d or nil end
function H.kind() local e = H.e(); return e and e.def and e.def.id or nil end
function H.confirm() local c = H.card(); return c and c._confirm or nil end
function H.zone(fid)
    local c = H.card()
    for _, z in ipairs((c and c._zones) or {}) do if z.fid == fid then return z end end
    return nil
end
function H.zonesLike(pre)
    local out, c = {}, H.card()
    for _, z in ipairs((c and c._zones) or {}) do
        if z.fid and string.sub(z.fid, 1, #pre) == pre then out[#out + 1] = z.fid end
    end
    return out
end
-- the card is on screen and drawing (its prerender runs OC.tick and stamps the zones each frame)
function H.live()
    local w, c = RT.ww(), H.card()
    if not (w and c and c.entry) then return false end
    local ok = false
    pcall(function()
        local dr = w._itemDrawerPanel
        ok = w:getIsVisible() and not w.windowShaded and (dr == nil or dr:getIsVisible()) and c:getIsVisible()
    end)
    return ok and getTimestampMs() - (S.drawAt or 0) < 500
end
function H.verb(id)
    local t = H.t()
    for _, v in ipairs((t and t.verbs) or {}) do if v.id == id then return v end end
    return nil
end
function H.verbIds()
    local t, ids = H.t(), {}
    for _, v in ipairs((t and t.verbs) or {}) do ids[#ids + 1] = tostring(v.id) .. ((v.enabled == false) and "(grey)" or "") .. (v.primary and "*" or "") end
    return table.concat(ids, ",")
end
-- a verb the card drew as a live button (its zone this frame, the button not greyed)
-- (the verb row's buttons carry no fid of their own: a verb is lit when its zone was drawn this frame and the verb
-- is not greyed; a row's button is read from its own draw)
function H.lit(fid)
    local z = H.zone(fid)
    if string.sub(tostring(fid), 1, 8) == "oc:verb:" then
        local v = H.verb(string.sub(fid, 9))
        return z ~= nil and v ~= nil and v.enabled ~= false
    end
    local b = H.btn(fid)
    if b then return not b.disabled end
    return z ~= nil and z.run ~= nil
end
function H.fresh() local t = H.t(); if t and S.OC then t._refreshT = S.OC.REFRESH end end
function H.close()
    if not H.card() or not H.e() then return end
    pcall(function() S.WWm.closeObjectCard(S.pn) end)
end
function H.mainFid() local c = H.card(); return c and c._mainFid or nil end
-- a press by the mouse: the card's own hit test at the zone's middle, then the zone's run, as the card's release
-- runs it; a zone the hit test does not reach there (scrolled out, under another) is pressed as the pad's A presses it
function H.click(fid, what)
    local c, z = H.card(), H.zone(fid)
    if not (c and z) then return false end
    local mx, my = z.x + math.floor((z.w or 0) / 2), z.y + math.floor((z.h or 0) / 2)
    local hit = nil
    pcall(function() hit = c:zoneAt(mx, my) end)
    if not (hit and hit.fid == fid) and not S.said[fid] then
        S.said[fid] = true
        H.note(tostring(what or fid) .. ": " .. fid .. " cannot be clicked where it is drawn (" .. math.floor(z.x) .. "," .. math.floor(z.y) .. "): pressed as the pad's A presses it")
    end
    if not z.run then return false end
    H.zcall(function() z.run(c, c:player()) end)
    return true
end
-- ===================================================================== the ground: the farm and the yard near home
function H.sqXY(x, y, z) local sq = nil; pcall(function() sq = getCell():getGridSquare(x, y, z or 0) end); return sq end
function H.key(x, y) return x * 100000 + y end
function H.objOn(sq, cls)
    if not sq then return nil end
    local o = nil
    pcall(function()
        local objs = sq:getObjects()
        for k = 0, objs:size() - 1 do
            local x = objs:get(k)
            if not o and instanceof(x, cls) then o = x end
        end
    end)
    return o
end
-- open ground: loaded, outdoors, free, no tree, no car, nothing lying on it, nothing built on it, in no animal zone,
-- no plot (bx_farm's rules)
function H.openSq(sq)
    if not sq then return false end
    local ok = false
    pcall(function()
        ok = sq:getChunk() ~= nil and sq:getFloor() ~= nil and sq:getRoom() == nil and sq:isFree(false) and not sq:HasTree()
            and not sq:isSolid() and not sq:isSolidTrans() and sq:getVehicleContainer() == nil
            and sq:getWorldObjects():size() == 0 and sq:getMovingObjects():size() == 0 and sq:getSpecialObjects():size() == 0
            and sq:getObjects():size() <= 4
    end)
    if not ok then return false end
    pcall(function()
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local spr = objs:get(i):getSprite()
            local nm = string.lower(tostring(spr and spr:getName() or ""))
            for _, w in ipairs(S.BLOCK) do if ok and string.find(nm, w, 1, true) then ok = false end end
        end
    end)
    if ok then pcall(function() if DesignationZoneAnimal.getZone(sq:getX(), sq:getY(), sq:getZ()) then ok = false end end) end
    if ok then pcall(function() if CFarmingSystem.instance:getLuaObjectOnSquare(sq) then ok = false end end) end
    return ok
end
-- the game's own plow rule for the ground (ISFarmingMenu.canDigHereSquare: ISShovelGroundCursor.GetDirtGravelSand)
function H.dirtSq(sq)
    if not H.openSq(sq) then return false end
    local g = nil
    pcall(function() g = ISShovelGroundCursor.GetDirtGravelSand(sq) end)
    return g == "dirt"
end
-- the nearest w x h rectangle (its top left corner) whose every square passes test, within S.REACH tiles of home,
-- clear of the squares in avoid
function H.findRect(w, h, test, avoid)
    local hx, hy = math.floor(S.HOME.x), math.floor(S.HOME.y)
    local R = S.REACH
    local good = {}
    for y = hy - R - h, hy + R + h do
        for x = hx - R - w, hx + R + w do
            local k = H.key(x, y)
            if not (avoid and avoid[k]) and test(H.sqXY(x, y)) then good[k] = true end
        end
    end
    for r = 0, R do
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local x0, y0 = hx + dx - math.floor(w / 2), hy + dy - math.floor(h / 2)
                    local all = true
                    for yy = y0, y0 + h - 1 do
                        for xx = x0, x0 + w - 1 do
                            if all and not good[H.key(xx, yy)] then all = false end
                        end
                    end
                    if all then return x0, y0 end
                end
            end
        end
    end
    return nil, nil
end
-- every square of the farm and the yard, a margin of 2 round each
function H.eachSite(fn)
    for _, r in ipairs({ S.farm or false, S.yard or false }) do
        if r then
            for y = r.y0 - 2, r.y0 + r.h + 1 do
                for x = r.x0 - 2, r.x0 + r.w + 1 do
                    local sq = H.sqXY(x, y)
                    if sq then fn(sq) end
                end
            end
        end
    end
end
-- what lies, stands and lives on the sites at the start (only what is new there is taken away at the end)
function H.siteSnap()
    S.objs0, S.floor0, S.bodies0, S.an0 = {}, {}, {}, {}
    H.eachSite(function(sq)
        pcall(function() local objs = sq:getObjects(); for i = 0, objs:size() - 1 do S.objs0[objs:get(i)] = true end end)
        pcall(function() local wos = sq:getWorldObjects(); for i = 0, wos:size() - 1 do S.floor0[wos:get(i)] = true end end)
        pcall(function() local ms = sq:getStaticMovingObjects(); for i = 0, ms:size() - 1 do S.bodies0[ms:get(i)] = true end end)
    end)
    pcall(function() local list = getCell():getAnimals(); for i = 0, list:size() - 1 do S.an0[list:get(i)] = true end end)
end
function H.onSite(x, y)
    for _, r in ipairs({ S.farm or false, S.yard or false }) do
        if r and x >= r.x0 - 3 and x <= r.x0 + r.w + 2 and y >= r.y0 - 3 and y <= r.y0 + r.h + 2 then return true end
    end
    return false
end
function H.atFarm() if S.farm then H.goTo(S.farm.sx, S.farm.sy, 0) end end
function H.atYard(dx, dy) if S.yard then H.goTo(S.yard.cx + (dx or 0) + 0.5, S.yard.cy + (dy or 0) + 0.5, 0) end end
function H.ysq(dx, dy) return S.yard and H.sqXY(S.yard.cx + dx, S.yard.cy + dy) or nil end

-- ===================================================================== the farming system (the game's)
function H.sLo(sq) local lo = nil; if sq then pcall(function() lo = SFarmingSystem.instance:getLuaObjectOnSquare(sq) end) end; return lo end
function H.cLo(sq) local lo = nil; if sq then pcall(function() lo = CFarmingSystem.instance:getLuaObjectOnSquare(sq) end) end; return lo end
-- the farm's plot slot i (its first row, then its second)
function H.plotSq(i)
    if not S.farm then return nil end
    local r = math.floor((i - 1) / S.FW)
    local c = (i - 1) - r * S.FW
    return H.sqXY(S.farm.x0 + c, S.farm.y0 + r)
end
function H.plow(sq)
    if not sq or H.sLo(sq) then return H.sLo(sq) end
    local k = #S.plots + 1
    S.plots[k] = sq
    pcall(function() S.plowDay[k] = sq:getModData().plowDay end)
    pcall(function() SFarmingSystem.instance:plow(sq) end)
    return H.sLo(sq)
end
-- the plant kept well while it is grown (the farming system's own grow step, bx_farm's way)
function H.keepWell(lo)
    pcall(function()
        lo.waterLvl = math.max(lo.waterNeeded or 0, 80)
        if lo.waterNeededMax and lo.waterLvl > lo.waterNeededMax then lo.waterLvl = lo.waterNeededMax end
        for _, k in ipairs(S.PESTS) do lo[k] = 0 end
        lo.health = 100
    end)
end
-- grown until stop(lo) holds (a number: that nbOfGrow), at most 30 steps
function H.grow(lo, upto)
    if not lo then return end
    local stop = upto
    if type(upto) == "number" then local n = upto; stop = function(l) return (l.nbOfGrow or 0) >= n end end
    for _ = 1, 30 do
        local done = false
        pcall(function() done = lo.state ~= "seeded" or stop(lo) end)
        if done then break end
        H.keepWell(lo)
        pcall(function() SFarmingSystem.instance:growPlant(lo, nil, true) end)
    end
    H.keepWell(lo)
    pcall(function() local spr = farming_vegetableconf.getSpriteName(lo); if spr then lo:setSpriteName(spr) end end)
    pcall(function() lo:setObjectName(farming_vegetableconf.getObjectName(lo)) end)
    pcall(function() lo:saveData() end)
end
function H.plant(sq, crop, upto)
    local lo = H.plow(sq)
    if not lo then return nil end
    pcall(function() lo:seed(crop, 10) end)
    if upto then H.grow(lo, upto) else pcall(function() lo:saveData() end) end
    return H.sLo(sq)
end
function H.setPlant(sq, f)
    local lo = H.sLo(sq)
    if not lo then return nil end
    for k, v in pairs(f) do lo[k] = v end
    pcall(function() lo:saveData() end)
    return lo
end
function H.pf(sq, k) local lo = H.sLo(sq); return lo and lo[k] end
function H.plantText(sq)
    local lo = H.sLo(sq)
    if not lo then return "no plant" end
    return tostring(lo.typeOfSeed) .. " " .. tostring(lo.state) .. " stage " .. tostring(lo.nbOfGrow) .. ", health " .. H.n1(lo.health)
        .. ", water " .. H.n1(lo.waterLvl) .. " (needs " .. tostring(lo.waterNeeded) .. "), fertilizer " .. tostring(lo.fertilizer)
        .. ", compost " .. tostring(lo.compost) .. ", cursed " .. tostring(lo.cursed)
end
function H.unplantAll()
    local n = 0
    for k, sq in ipairs(S.plots) do
        local lo = H.sLo(sq)
        if lo then pcall(function() SFarmingSystem.instance:removePlant(lo) end); n = n + 1 end
        pcall(function() sq:getModData().plowDay = S.plowDay[k] end)
    end
    S.plots, S.plowDay = {}, {}
    return n
end
function H.crops()
    local keys = {}
    pcall(function()
        for k, p in pairs(farming_vegetableconf.props) do
            if type(p) == "table" and p.seedName and H.known(p.seedName) then keys[#keys + 1] = k end
        end
    end)
    table.sort(keys)
    return keys
end
function H.prop(crop) local p = nil; pcall(function() p = farming_vegetableconf.props[crop] end); return p end
function H.cropName(crop) return H.txt("Farming_" .. tostring(crop), tostring(crop)) end
-- the farming menu's click-another-square cursor (the game's handlers arm it) put away
function H.cursorOff()
    pcall(function() if ISFarmingMenu.cursor then getCell():setDrag(nil, S.pn); ISFarmingMenu.cursor = nil end end)
end

-- ===================================================================== troughs, hen houses, hooks, animals (the game's)
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
-- a thing built on sq by the game's own build (ISBuildIsoEntity with the build cheat, zedqa_animals.lua's way)
function H.build(full, sq)
    local info = H.findInfo(full)
    if not (info and sq) then return false, "no build info for " .. tostring(full) end
    local ok, why = false, nil
    pcall(function() S.p:setBuildCheat(true) end)
    local okB, err = pcall(function()
        local b = ISBuildIsoEntity:new(S.p, info, 1, ISInventoryPaneContextMenu.getContainers(S.p))
        b.buildCheat = true
        b.player = S.pn
        b.sq = sq
        if b:isValid(sq) then b:create(sq:getX(), sq:getY(), sq:getZ(), false, nil); ok = true else why = "the game's build says the square is not valid" end
    end)
    pcall(function() S.p:setBuildCheat(S.found.buildCheat == true) end)
    if not okB then why = tostring(err) end
    return ok, why
end
function H.rmIso(o)
    if not o then return end
    local sq = nil
    pcall(function() sq = o:getSquare() end)
    pcall(function() local ct = o:getContainer(); if ct then ct:removeAllItems() end end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        pcall(function() sq:RecalcProperties() end)
    end
    pcall(function() o:removeFromWorld() end)
end
function H.mkTrough(sq, def)
    if not sq then return nil end
    pcall(function() SFeedingTroughSystem.instance:addTrough(sq, def or FeedingTroughDef.simple, false, -1, -1) end)
    local o = H.objOn(sq, "IsoFeedingTrough")
    if o then S.troughs[#S.troughs + 1] = sq end
    return o
end
function H.rmTroughAt(sq)
    local n = 0
    pcall(function() local o = H.objOn(sq, "IsoFeedingTrough"); if o and o:getContainer() then o:getContainer():removeAllItems() end end)
    pcall(function() local lo = SFeedingTroughSystem.instance:getLuaObjectOnSquare(sq); if lo then lo:removeIsoObject(); n = n + 1 end end)
    pcall(function() local iso = H.objOn(sq, "IsoFeedingTrough"); if iso then sq:transmitRemoveItemFromSquare(iso); n = n + 1 end end)
    return n
end
function H.troughLo(o) local lo = nil; pcall(function() lo = SFeedingTroughSystem.instance:getLuaObjectOnSquare((o:getMasterTrough() or o):getSquare()) end); return lo end
function H.water(o) local w = -1; pcall(function() w = o:getWater() end); return w end
function H.tfc(o) local f = nil; pcall(function() f = (o:getMasterTrough() or o):getFluidContainer() end); return f end
function H.tItems(o) local n = 0; pcall(function() n = o:getContainer():getItems():size() end); return n end
function H.feed(o) local f = -1; pcall(function() f = o:getCurrentFeedAmount() end); return f end
function H.breed(kind) local b = nil; pcall(function() b = AnimalDefinitions.getDef(kind):getBreeds():get(0) end); return b end
function H.markAnimal(a)
    if not a then return nil end
    pcall(function() a:getModData().ZeDQA_spawned = true end)
    S.animals[#S.animals + 1] = a
    return a
end
-- an animal made by the game's own spawn (addAnimal), kept still
function H.spawnAnimal(kind, x, y)
    local a = nil
    pcall(function() a = addAnimal(getCell(), x or 0, y or 0, 0, kind, H.breed(kind)) end)
    if not a then return nil end
    H.markAnimal(a)
    pcall(function() a:setDebugStress(0) end)
    pcall(function() local b = a:getBehavior(); if b then b:setBlockMovement(true) end end)
    return a
end
function H.inCell(a) local yes = false; pcall(function() yes = getCell():getAnimals():contains(a) end); return yes end
-- an animal out of the game, once: off its perch or box, off the world and its square (never remove() on a bird made
-- with addAnimal: zedqa_cov_farmcards.lua, H.takeAwayOut)
function H.takeAway(a)
    if not a or S.gone[a] then return end
    S.gone[a] = true
    pcall(function() local h = a:getHutch(); if h then h:tryFindAndRemoveAnimalFromNestBox(a); h:removeAnimal(a) end end)
    if H.inCell(a) then pcall(function() a:removeFromWorld(); a:removeFromSquare() end) end
end
function H.mkHutch(sq)
    local def = nil
    pcall(function() def = HutchDefinitions.hutchs.hutchhen end)
    if not (def and sq and IsoHutch) then return nil end
    pcall(function() local h = IsoHutch.new(sq, true, def.baseSprite, def, nil); h:transmitCompleteItemToClients() end)
    local h = H.objOn(sq, "IsoHutch")
    pcall(function() h = h and (h:getHutch() or h) end)
    if h then
        S.hutches[#S.hutches + 1] = h
        pcall(function() if h:isOpen() then h:toggleDoor() end end)
        pcall(function() if h:isEggHatchDoorOpen() then h:toggleEggHatchDoor() end end)
        pcall(function() h:setHutchDirt(0) end)
    end
    return h
end
function H.boxes(h) local n = 0; pcall(function() n = h:getMaxNestBox() + 1 end); return n end
function H.eggsIn(h, b) local n = 0; pcall(function() local nb = h:getNestBox(b); n = nb and nb:getEggsNb() or 0 end); return n end
function H.eggsAll(h) local o = {}; for b = 0, H.boxes(h) - 1 do o[#o + 1] = H.eggsIn(h, b) end; return o end
function H.addEggs(h, b, n) pcall(function() local nb = h:getNestBox(b); for _ = 1, n do nb:addEgg(instanceItem("Base.Egg")) end end) end
function H.hutchEmpty(h)
    if not h then return end
    local all, seen = {}, {}
    pcall(function()
        for b = 0, h:getMaxNestBox() do local a = h:getAnimalInNestBox(b); if a and not seen[a] then seen[a] = true; all[#all + 1] = a end end
        for k = 0, h:getMaxAnimals() - 1 do local a = h:getAnimal(k); if a and not seen[a] then seen[a] = true; all[#all + 1] = a end end
    end)
    for _, a in ipairs(all) do pcall(function() h:tryFindAndRemoveAnimalFromNestBox(a) end) end
    for _, a in ipairs(all) do pcall(function() if a:getHutch() then h:removeAnimal(a) end end) end
    for _, a in ipairs(all) do H.takeAway(a) end
    pcall(function()
        for b = 0, h:getMaxNestBox() do
            local nb = h:getNestBox(b)
            for _ = 1, 14 do if not nb or nb:getEggsNb() <= 0 then break end; nb:removeEgg(0) end
        end
    end)
end
function H.rmHutch(h)
    if not h then return end
    H.hutchEmpty(h)
    pcall(function() h:removeHutch() end)
end
function H.mkHook(sq)
    local ok, why = H.build("Base.ButcherHook", sq)
    local hk = H.objOn(sq, "IsoButcherHook")
    return hk, (hk == nil) and (why or "no hook on the square after the build") or nil
end
-- the animal bodies on the squares within r of x,y
function H.bodiesNear(x, y, r)
    local out = {}
    for yy = y - r, y + r do
        for xx = x - r, x + r do
            local sq = H.sqXY(xx, yy)
            -- (Nov 26 2026: a nil square here threw inside the pcall on every frame of a wait, and the game logs each
            -- caught throw: 161390 errors, the console rolled over and the runner missed the run's end)
            if sq then pcall(function()
                local list = sq:getStaticMovingObjects()
                if not list then return end
                for i = 0, list:size() - 1 do
                    local o = list:get(i)
                    if instanceof(o, "IsoDeadBody") and o:isAnimal() then out[#out + 1] = o end
                end
            end) end
        end
    end
    return out
end
function H.rmBody(b)
    if not b then return end
    pcall(function() local sq = b:getSquare(); if sq then sq:removeCorpse(b, false) end end)
    pcall(function() b:invalidateCorpse() end)
    pcall(function() b:removeFromWorld() end)
end
-- the hook's carcass taken down and away (the game makes the hook animal with IsoAnimal.new and removes it with remove())
function H.hookClear(hk)
    if not hk then return end
    pcall(function()
        local a = hk:getAnimal()
        if a then hk:setAnimal(nil); a:remove() end
    end)
    pcall(function() hk:setLuaHook(nil) end)
end
-- the animals in the cell on a hook (getHook) or marked on one: any not on its hook's getAnimal() is an orphan
function H.hookAnimals()
    local o = {}
    pcall(function()
        local list = getCell():getAnimals()
        for i = 0, list:size() - 1 do
            local a = list:get(i)
            local on = false
            pcall(function() on = a:isOnHook() == true end)
            if not on then pcall(function() on = a:getHook() ~= nil end) end
            if on then o[#o + 1] = a end
        end
    end)
    return o
end
-- queue: an animal of kind made by the game's own spawn at dx,dy from the yard's middle and killed there (its health
-- set to 0: the game makes its body); T[key] is the body, nil when none came
-- (Nov 26 2026, the first 4K run: the callers passed S.yard.cx + dx as they built the queue, before the setup step had
-- found the yard, so every hook case spawned its cow at 2,2 and waited 10 s for a body there. The square is read when
-- the step runs.)
function H.killQ(T, key, kind, dx, dy)
    local at = {}
    H.step(1, function()
        if T.off then return end
        T[key] = nil
        if not S.yard then T.off = true; Q.check(false, T.L .. ": open ground for the yard near home", S.noYard or "none found"); return end
        at.x, at.y = S.yard.cx + (dx or 0), S.yard.cy + (dy or 0)
        local before = {}
        for _, b in ipairs(H.bodiesNear(at.x, at.y, 3)) do before[b] = true end
        T[key .. "0"] = before
        local a = H.spawnAnimal(kind, at.x + 0.5, at.y + 0.5)
        if not a then T.off = true; Q.check(false, T.L .. ": the game spawns a " .. kind, "addAnimal gave nothing at " .. at.x .. "," .. at.y); return end
        pcall(function() a:setHealth(0) end)
    end)
    H.wait(10000, function()
        if T.off then return true end
        for _, b in ipairs(H.bodiesNear(at.x, at.y, 3)) do if not T[key .. "0"][b] then T[key] = b; return true end end
        return false
    end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, T.L .. ": the " .. kind .. " the game spawned and killed left a body", "no new animal body near " .. tostring(at.x) .. "," .. tostring(at.y) .. " in 10 s")
        else S.bodies[#S.bodies + 1] = T[key] end
    end)
end
-- a carcass hung by the game's own code (ButcheringUtil.onAddedCorpseOnHook, what ISPutAnimalOnHook's complete runs)
function H.hang(hk, body)
    local ok = pcall(function()
        body:setOnHook(true)
        ButcheringUtil.onAddedCorpseOnHook(hk, body, S.p)
    end)
    return ok and hk:getAnimal() ~= nil
end
function H.md(hk) local m = nil; pcall(function() m = hk:getAnimal():getModData() end); return m end
function H.blood(hk) local b = nil; pcall(function() b = tonumber(hk:getAnimal():getModData()["BloodQty"]) end); return b end
function H.mkZone(name, x1, y1, x2, y2)
    pcall(function() DesignationZoneAnimal.new(name, x1, y1, 0, x2, y2, true) end)
    local z = nil
    pcall(function() z = DesignationZoneAnimal.getZoneByName(name) end)
    if z then S.zones[#S.zones + 1] = name end
    return z
end
function H.zonesBack()
    local n = 0
    for _, name in ipairs(S.zones) do
        for _ = 1, 3 do
            pcall(function() local z = DesignationZoneAnimal.getZoneByName(name); if z then DesignationZoneAnimal.removeZone(z, true); n = n + 1 end end)
        end
    end
    S.zones = {}
    return n
end

-- everything a case staged taken away (also the run's put-back): the plots, the troughs, the hen houses (their birds
-- and eggs first), the hooks (their carcasses first), anything else new built on the sites, the animals made and any
-- new animal on the sites, the bodies, the zones, anything new lying there
function H.worldBack()
    local n = { plots = 0, troughs = 0, hutches = 0, built = 0, animals = 0, bodies = 0, zones = 0, floor = 0 }
    n.plots = H.unplantAll()
    for _, h in ipairs(S.hutches) do H.rmHutch(h); n.hutches = n.hutches + 1 end
    S.hutches = {}
    for _, sq in ipairs(S.troughs) do n.troughs = n.troughs + H.rmTroughAt(sq) end
    S.troughs = {}
    if S.objs0 then
        H.eachSite(function(sq)
            local new = {}
            pcall(function() local objs = sq:getObjects(); for i = 0, objs:size() - 1 do local o = objs:get(i); if not S.objs0[o] then new[#new + 1] = o end end end)
            for _, o in ipairs(new) do
                local kind = nil
                pcall(function()
                    if instanceof(o, "IsoFeedingTrough") then kind = "trough"
                    elseif instanceof(o, "IsoButcherHook") then kind = "hook"
                    elseif instanceof(o, "IsoHutch") then kind = "hutch" end
                end)
                if kind == "trough" then n.troughs = n.troughs + H.rmTroughAt(sq)
                elseif kind == "hook" then H.hookClear(o); H.rmIso(o); n.built = n.built + 1
                elseif kind == "hutch" then pcall(function() H.rmHutch(o:getHutch() or o) end); n.hutches = n.hutches + 1 end
            end
        end)
    end
    for _, a in ipairs(H.hookAnimals()) do
        local x, y = -1, -1
        pcall(function() x, y = math.floor(a:getX()), math.floor(a:getY()) end)
        if H.onSite(x, y) and not (S.an0 and S.an0[a]) then pcall(function() a:remove() end); n.animals = n.animals + 1 end
    end
    for _, a in ipairs(S.animals) do if not S.gone[a] then H.takeAway(a); n.animals = n.animals + 1 end end
    S.animals = {}
    pcall(function()
        local list = getCell():getAnimals()
        local out = {}
        for i = 0, list:size() - 1 do
            local a = list:get(i)
            local x, y = math.floor(a:getX()), math.floor(a:getY())
            if not (S.an0 and S.an0[a]) and H.onSite(x, y) then out[#out + 1] = a end
        end
        for _, a in ipairs(out) do H.takeAway(a); n.animals = n.animals + 1 end
    end)
    if S.bodies0 then
        H.eachSite(function(sq)
            local new = {}
            pcall(function()
                local ms = sq:getStaticMovingObjects()
                for i = 0, ms:size() - 1 do local o = ms:get(i); if not S.bodies0[o] and instanceof(o, "IsoDeadBody") then new[#new + 1] = o end end
            end)
            for _, b in ipairs(new) do H.rmBody(b); n.bodies = n.bodies + 1 end
        end)
    end
    S.bodies = {}
    n.zones = H.zonesBack()
    if S.floor0 then
        H.eachSite(function(sq)
            local new = {}
            pcall(function() local wos = sq:getWorldObjects(); for i = 0, wos:size() - 1 do local wo = wos:get(i); if not S.floor0[wo] then new[#new + 1] = wo end end end)
            for _, wo in ipairs(new) do
                pcall(function() sq:transmitRemoveItemFromSquare(wo) end)
                pcall(function() wo:removeFromWorld() end)
                pcall(function() wo:removeFromSquare() end)
                n.floor = n.floor + 1
            end
        end)
    end
    return n
end
-- what the run staged that is still there
function H.leftovers()
    local left = {}
    for _, sq in ipairs(S.plots) do if H.sLo(sq) then left[#left + 1] = "a plot at " .. sq:getX() .. "," .. sq:getY() end end
    if S.objs0 then
        H.eachSite(function(sq)
            pcall(function()
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if not S.objs0[o] and (instanceof(o, "IsoFeedingTrough") or instanceof(o, "IsoButcherHook") or instanceof(o, "IsoHutch")) then
                        left[#left + 1] = tostring(o:getObjectName()) .. " at " .. sq:getX() .. "," .. sq:getY()
                    end
                end
            end)
            pcall(function() if H.sLo(sq) then left[#left + 1] = "a plant at " .. sq:getX() .. "," .. sq:getY() end end)
        end)
    end
    if S.bodies0 then
        H.eachSite(function(sq)
            pcall(function()
                local ms = sq:getStaticMovingObjects()
                for i = 0, ms:size() - 1 do if not S.bodies0[ms:get(i)] and instanceof(ms:get(i), "IsoDeadBody") then left[#left + 1] = "a body at " .. sq:getX() .. "," .. sq:getY() end end
            end)
        end)
    end
    pcall(function()
        local list = getCell():getAnimals()
        for i = 0, list:size() - 1 do
            local a = list:get(i)
            if not (S.an0 and S.an0[a]) and H.onSite(math.floor(a:getX()), math.floor(a:getY())) then left[#left + 1] = "an animal (" .. tostring(a:getAnimalType()) .. ")" end
        end
    end)
    for _, name in ipairs(S.zones) do left[#left + 1] = "zone " .. name end
    return left
end

-- ===================================================================== a case's start and end
function H.legClean()
    H.speed(1)
    H.qstop()
    H.padOff()
    H.park(false)
    H.cursorOff()
    H.close()
    S.holdOn = true
    H.instant(true)
    H.qstop()
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    S.caseMade = {}
    H.sweepNew()
    H.worldBack()
    H.hands()
    H.bodyBack()
    S.qLast = nil
end
-- (inside a step) the case begins clean: nothing staged, hidden actions folded, the skills it needs
function H.caseStart(T, where)
    S.caseMade = {}
    T.e0 = H.errN()
    H.legClean()
    H.hidden("folded")
    if where == "farm" then
        if not S.farm then T.off = true; Q.check(false, T.L .. ": a farm on the game's dirt near home", S.noFarm or "none found"); return false end
        H.atFarm()
    elseif where == "yard" then
        if not S.yard then T.off = true; Q.check(false, T.L .. ": open ground for the yard near home", S.noYard or "none found"); return false end
        H.atYard(0, 0)
    end
    T.t0case = getTimestampMs()
    return true
end
function H.caseEnd(label)
    H.step(2, function()
        H.legClean()
        H.hiddenBack()
        H.sizeBack()
        H.home()
    end)
    H.step(10, function()
        local e1 = H.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, label .. ": no Lua error over the case",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        if S.zerr then Q.check(false, label .. ": nothing ZeD ran for the case threw", S.zerr); S.zerr = nil end
        S.e0 = e1
    end)
end
-- queue: the card opened by the game's own way in (openFn(T)), then drawing with its data, at most 8 s
function H.cardQ(T, kind, openFn)
    H.step(2, function()
        if T.off then return end
        T.openAt = getTimestampMs()
        H.zcall(function() openFn(T) end)
    end)
    H.wait(8000, function()
        return T.off or (H.kind() == kind and H.d() ~= nil and H.live() and (S.drawAt or 0) > (T.openAt or 0) + 120)
    end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the game's own way in opens the " .. kind .. " card", "card " .. tostring(H.kind()) .. ", live " .. tostring(H.live())
            .. ", queue " .. H.qkinds()) then T.off = true end
    end)
end
function H.openPlot(sq) local c = H.cLo(sq); if c then ISFarmingMenu.onInfo(nil, c, sq, S.p) end end
function H.openTrough(o) ISFeedingTroughMenu.onInfo(o, S.p) end
function H.openHutch(h) ISHutchMenu.onInfo(h, S.p) end
function H.openHook(hk) ISTimedActionQueue.add(ISOpenButcherHookUI:new(S.p, hk)) end
-- queue: a short settle for the card to draw what changed (its refresh every 250 ms)
function H.settle(ms) H.step(1, function() H.fresh() end); H.pause(ms or 500) end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        local world = nil
        pcall(function() world = getWorld():getWorld() end)
        if world ~= "ZeD-QA" then S.dead = true; Q.check(false, "setup: the run is on the ZeD-QA save (it stages things and moves him)", tostring(world)); return end
        if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then S.dead = true; Q.check(false, "setup: ZeD is out of safe mode (the game's own windows would open)"); return end
        local hooks = (ISFarmingMenu and ISFarmingMenu._zed_onInfo) and (ISFeedingTroughMenu and ISFeedingTroughMenu._zedCardHooked)
            and (ISHutchMenu and ISHutchMenu._zedCardHooked) and (ISOpenButcherHookUI and ISOpenButcherHookUI._zedCardHooked)
        if not (hooks and S.F and S.F.focusWhere and ISTimedActionQueue and SFarmingSystem and SFarmingSystem.instance and CFarmingSystem
            and SFeedingTroughSystem and SFeedingTroughSystem.instance and IsoHutch and ButcheringUtil) then
            S.dead = true
            Q.check(false, "setup: ZeD's hooks on the four Info paths, the pad's focus manager and the game's farming and animal code are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "oca_tab") end
        H.speed(1)
        H.qstop()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.pair = RT.isOpen()
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.inv0, f.types, f.stashed = {}, {}, {}
        for _, it in ipairs(H.all()) do
            f.inv0[it] = true
            local ft = H.ft(it)
            f.types[ft] = (f.types[ft] or 0) + 1
        end
        pcall(function() f.tod = getGameTime():getTimeOfDay() end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat() end)
        pcall(function() f.buildCheat = S.p:isBuildCheat() end)
        pcall(function() f.god = S.p:isGodMod() and true or false; S.p:setGodMod(true) end)
        pcall(function() f.invinc = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
        S.guard = true
        pcall(function() f.seasons = getSandboxOptions():getOptionByName("PlantGrowingSeasons"):getValue() end)
        f.fmCheat = ISFarmingMenu.cheat
        f.base, f.size = ZeD.currentBase, ZeD.currentSize
        f.sizeIdx = H.optVal(H.zopt("textSize"))
        f.hiddenIdx = H.optVal(ZeD.Settings and ZeD.Settings.hiddenActionsOption)
        f.scaleIdx = H.optVal(ZeD.Settings and ZeD.Settings.uiScaleOption)
        S.lockWas = H.lockFound()
        H.xpSnap()
        H.stiffSnap()
        f.farming, f.butcher, f.husb = H.perkLvl("Farming"), H.perkLvl("Butchering"), H.perkLvl("Husbandry")
        RT.pairOpen()
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        local cw, ww = RT.cw(), RT.ww()
        f.ctab, f.wtab = cw and cw._activeTab, ww and ww._activeTab
        f.maxW = ww and ww._maxWinW
        if ww and ZeD.AnimalsTab and ZeD.AnimalsTab.getState then
            pcall(function()
                local st = ZeD.AnimalsTab.getState(ww)
                f.at = { submode = st.submode, view = st.view, zoneName = st.zoneName, animalRef = st.animalRef, prevView = st.prevView }
            end)
        end
        f.recorded = true
        S.back.on = true
        pcall(function() Events.OnTick.Add(H.keepTick) end)
        S.holdOn = true
        H.instant(true)
        H.wrapOn()
        S.SEEDS = {}
        pcall(function()
            for _, props in pairs(farming_vegetableconf.props) do
                if type(props) == "table" then
                    if props.seedName then S.SEEDS[props.seedName] = true end
                    for _, s in ipairs(props.seedTypes or {}) do S.SEEDS[s] = true end
                end
            end
        end)
        local aside, kept = H.stashAside()
        H.note("setup: " .. aside .. " of his own things the cases' game actions would reach for are set aside (seeds, fertilizer, compost, sprays, feed, fluid containers, mops, knives, shovels)"
            .. (kept > 0 and (", " .. kept .. " worn, held or on the belt stay") or ""))
        local still = H.ownWaterLeft()
        if #still > 0 then H.note("setup: water he keeps on him that the card's Water could pour: " .. H.list(still)) end
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", screen " .. H.sizeTag() .. ", language " .. H.lang()
            .. ", Farming " .. f.farming .. ", Butchering " .. f.butcher .. ", Animal Care " .. f.husb .. ", hidden actions " .. H.hiddenNow()
            .. ", input lock " .. tostring(S.lockWas) .. ", World tab " .. tostring(f.wtab) .. ", text size " .. tostring(f.size)
            .. ", seasons " .. tostring(f.seasons) .. ", time " .. H.n2(f.tod))
    end)
    -- the farm (the game's dirt) and the yard (open ground), both within 40 tiles of home
    H.step(30, function()
        local fx, fy = H.findRect(S.FW, S.FH, H.dirtSq, nil)
        if fx then
            S.farm = { x0 = fx, y0 = fy, w = S.FW, h = S.FH, sx = fx + 4.5, sy = fy + 3.5 }
        else
            S.noFarm = "no 9 x 6 of the game's dirt within " .. S.REACH .. " tiles of home"
        end
        local avoid = {}
        if S.farm then
            for y = S.farm.y0 - 3, S.farm.y0 + S.farm.h + 2 do for x = S.farm.x0 - 3, S.farm.x0 + S.farm.w + 2 do avoid[H.key(x, y)] = true end end
        end
        local yx, yy = H.findRect(S.YW, S.YH, H.openSq, avoid)
        if yx then
            S.yard = { x0 = yx, y0 = yy, w = S.YW, h = S.YH, cx = yx + 7, cy = yy + 5 }
        else
            S.noYard = "no 15 x 11 of open ground within " .. S.REACH .. " tiles of home"
        end
        local hx, hy = math.floor(S.HOME.x), math.floor(S.HOME.y)
        Q.check(S.farm ~= nil, "setup: a farm of the game's dirt within " .. S.REACH .. " tiles of home",
            S.farm and (S.farm.x0 .. "," .. S.farm.y0 .. " (" .. math.floor(H.d2(S.farm.x0, S.farm.y0, hx, hy)) .. " tiles)") or S.noFarm)
        Q.check(S.yard ~= nil, "setup: open ground for the yard within " .. S.REACH .. " tiles of home",
            S.yard and (S.yard.x0 .. "," .. S.yard.y0 .. " (" .. math.floor(H.d2(S.yard.x0, S.yard.y0, hx, hy)) .. " tiles)") or S.noYard)
        H.siteSnap()
        local keys = H.crops()
        S.cropList = keys
        S.crop = H.prop("Carrots") and "Carrots" or keys[1]
        S.crop2 = nil
        for _, k in ipairs({ "Cabbages", "Broccoli", "Potatoes", "Tomato", "Lettuce" }) do if not S.crop2 and H.prop(k) and k ~= S.crop then S.crop2 = k end end
        if not S.crop2 then for _, k in ipairs(keys) do if not S.crop2 and k ~= S.crop then S.crop2 = k end end end
        H.note("setup: crops " .. tostring(S.crop) .. " and " .. tostring(S.crop2) .. " (" .. #keys .. " crops with seeds in this game)")
    end)
    H.pause(800)
end
-- ===================================================================== shared readings
function H.dist(sq)
    local d = 999
    pcall(function() local dx, dy = sq:getX() + 0.5 - S.p:getX(), sq:getY() + 0.5 - S.p:getY(); d = math.sqrt(dx * dx + dy * dy) end)
    return d
end
function H.d2(ax, ay, bx, by) local dx, dy = ax - bx, ay - by; return math.sqrt(dx * dx + dy * dy) end
-- the words drawn in a zone's row (its y span, 8 px of slack), leftmost first
function H.rowTexts(z)
    local o = {}
    if not z then return o end
    for _, t in ipairs(S.texts or {}) do if t.y >= z.y - 8 and t.y <= z.y + z.h + 8 then o[#o + 1] = t end end
    table.sort(o, function(a, b) return a.x < b.x end)
    return o
end
-- the drawn words that run past the card's edges
function H.overflow()
    local c = H.card()
    local cw = 0
    pcall(function() cw = c:getWidth() end)
    local over = {}
    for _, t in ipairs(S.texts or {}) do
        if not t.big then
            local tw = H.textW(t)
            local x0 = t.x
            if t.right then x0 = t.x - tw elseif t.centre then x0 = t.x - tw / 2 end
            if x0 < -1 or x0 + tw > cw + 1 then over[#over + 1] = "'" .. t.s .. "' " .. math.floor(x0) .. "+" .. math.floor(tw) end
        end
    end
    return over, cw
end
-- the card at the run's size: the drawer, the inventory beside it, the card on screen, the words inside it
function C.measure(T, label)
    local w, c = RT.ww(), H.card()
    local sw = H.screen()
    local full = ZeD.T.px(480)
    local dw = math.floor((w and w._drawerEffW) or 0)
    H.sizeCheck(math.abs(dw - full) <= 1, label .. ": the card drawer is the full card (480 units, " .. full .. " px)", dw .. " px, the screen " .. H.sizeTag())
    if w and w._invDrawerOpen then
        local invW = nil
        pcall(function() invW = math.floor(w._mainContent:getWidth()) end)
        if invW == nil then pcall(function() invW = math.floor(w:getWidth() - dw - ZeD.T.px(36) - ZeD.T.px(36)) end) end
        local min = ZeD.T.px(180)
        H.sizeCheck((invW or 0) >= min, label .. ": the inventory beside the card keeps its 180-unit minimum (" .. min .. " px)",
            tostring(invW) .. " px; the window " .. math.floor(w:getWidth()) .. " px of the half-screen cap " .. tostring(w._maxWinW or math.floor(sw * 0.5)))
    else
        H.note(label .. ": the World window's inventory is shut beside the card here: its squeeze is not read")
    end
    local cx, cw = 0, 0
    pcall(function() cx = c:getAbsoluteX(); cw = c:getWidth() end)
    H.sizeCheck(cx >= -1 and cx + cw <= sw + 1, label .. ": the card lies inside the screen", math.floor(cx) .. "+" .. math.floor(cw) .. " of " .. sw)
    local over = H.overflow()
    H.sizeCheck(#over == 0, label .. ": no word the card drew runs past its edges", H.list(over, 6))
    pcall(function() RT.bounds(Q, label) end)
end
-- the keys in the mod's UI.json files, read through the game's mod file reader (mt_tab's way)
function H.langKeys(keys)
    local missing, read, seen = {}, 0, {}
    for _, L in ipairs({ "EN", "DE", "ES", "FR", "RU", "JP", "IT", "PL", "PTBR", "CN", "KO", "TR", "UA", "NL", "CS", "HU", "AR", "TH" }) do
        local found = false
        for _, path in ipairs({ "media/lua/shared/Translate/" .. L .. "/UI.json", "42/media/lua/shared/Translate/" .. L .. "/UI.json" }) do
            local r = nil
            pcall(function() r = getModFileReader("ZeD_UI", path, false) end)
            if r and not found then
                found = true
                read = read + 1
                local have = {}
                pcall(function()
                    local ln = r:readLine()
                    while ln do
                        for _, k in ipairs(keys) do if string.find(ln, '"' .. k .. '"', 1, true) then have[k] = true end end
                        ln = r:readLine()
                    end
                end)
                pcall(function() r:close() end)
                local miss = {}
                for _, k in ipairs(keys) do if not have[k] then miss[#miss + 1] = k end end
                if #miss > 0 then missing[#missing + 1] = L .. " (" .. table.concat(miss, ", ") .. ")" end
                seen[#seen + 1] = L
            end
        end
    end
    return read, missing, seen
end

-- ===================================================================== FA1 Fertilize twice (and a third dose)
function C.fa1(how)
    local T = { L = "FA1 Fertilize (" .. how .. ")", log = {} }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        T.sq = H.plotSq(1)
        local lo = H.plant(T.sq, S.crop, 3)
        if not (lo and lo.state == "seeded") then T.off = true; Q.check(false, T.L .. ": a young plant staged by the farming system", H.plantText(T.sq)); return end
        T.f0 = (how == "third") and 2 or 0
        T.h0 = (how == "third") and 25 or 60
        H.setPlant(T.sq, { health = T.h0, fertilizer = T.f0, cursed = false, waterLvl = 100, compost = false })
        H.perkSet("Farming", 10)
        T.fert = H.give("Base.Fertilizer")
        T.u0 = H.uses(T.fert)
        -- (the walk is wanted: the second press comes while the first is walked to)
        H.instant(false)
        if how == "pad" then H.padOn(); H.park(true) end
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.lit0 = H.lit("oc:verb:fert")
        T.dist0 = H.dist(T.sq)
        if how == "mouse" then H.click("oc:verb:fert", T.L); H.click("oc:verb:fert", T.L)
        elseif how == "third" then H.click("oc:verb:fert", T.L) end
    end)
    if how == "pad" then
        H.padPress(T, "oc:verb:fert")
        H.step(3, function() end)
        H.tapA(function() return not T.off and T.focusOk == true end)
    end
    H.step(1, function()
        if T.off then return end
        T.queued = H.qcount("ISFertilizeAction")
        T.kinds = H.qkinds()
        T.asked = H.confirm() ~= nil
        H.speed(2)
    end)
    -- the doses, watched as the game applies them (the plant's own fertilizer and health)
    H.wait(40000, function()
        if T.off then return true end
        local f, h = H.pf(T.sq, "fertilizer"), H.pf(T.sq, "health")
        local last = T.log[#T.log]
        if f ~= nil and (not last or last.f ~= f or last.h ~= h) then T.log[#T.log + 1] = { f = f, h = h, st = H.pf(T.sq, "state") } end
        if f and f >= T.f0 + 1 and not T.after1 then
            local v = H.verb("fert")
            T.after1 = { lit = H.lit("oc:verb:fert"), ask = v ~= nil and v.confirm ~= nil }
        end
        return H.qlen() == 0 and not H.doing() and getTimestampMs() - (T.openAt or 0) > 1500
    end, function(ok)
        H.speed(1)
        if T.off then return end
        if not ok then H.qstop() end
        local doses = {}
        for _, r in ipairs(T.log) do doses[#doses + 1] = "fertilizer " .. tostring(r.f) .. " health " .. H.n1(r.h) .. " " .. tostring(r.st) end
        local u1 = H.uses(T.fert)
        local ev = "queued " .. tostring(T.queued) .. " ISFertilizeAction (" .. tostring(T.kinds) .. ", he stood " .. H.n1(T.dist0) .. " tiles off); the plant: "
            .. H.list(doses, 6) .. "; the fertilizer's uses " .. tostring(T.u0) .. " -> " .. tostring(u1) .. "; now " .. H.plantText(T.sq)
        -- (Nov 26 2026 triage: game parity, a NOTE. The game's Fertilize asks nothing at any dose (ISFarmingMenu
        -- doFarmingMenu2 offers it whenever fertilizer is carried), and its menu arms a cursor whose every click on the
        -- plant queues one more ISFertilizeAction with no dose check (onFertilizeSquareSelected, isFertilizeValid), so
        -- a second press during the walk queues a second dose there too)
        if how == "third" then
            local alive = H.pf(T.sq, "state") == "seeded" and (H.pf(T.sq, "health") or 0) > 0
            H.note(T.L .. ": a third dose (the game curses the plant and takes 25 health: at 25 it dies) " .. ((T.asked or not T.lit0 or alive) and "is asked about or spared" or "is given with no question")
                .. "; the game's own Fertilize asks nothing either (game parity) | Fertilize lit " .. tostring(T.lit0) .. ", a question " .. tostring(T.asked) .. "; " .. ev)
        else
            H.note(T.L .. ": a second press while the first dose is walked to " .. (((T.queued or 0) <= 1) and "queues no second dose" or "queues a second dose")
                .. "; the game's cursor queues one per click with no dose check (game parity) | " .. ev)
            local a = T.after1
            H.note(T.L .. ": once dosed, the card " .. ((a and a.lit and not a.ask) and "offers the next dose with no question" or "asks first or does not offer it")
                .. " (the game's second dose takes 25 health; its menu asks nothing: game parity) | "
                .. (a and ("after the first dose: Fertilize lit " .. tostring(a.lit) .. ", asks " .. tostring(a.ask)) or "no first dose was seen"))
        end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FA2 the water marks against the crop's need
function H.gameWaterClass(c, lvl)
    local out = "none"
    pcall(function()
        local rgb = ISFarmingInfo.getWaterLvlColor(c, lvl)
        local g, o, r, w = {}, {}, {}, {}
        ISFarmingInfo:getGreen(g, nil); ISFarmingInfo:getOrange(o, nil); ISFarmingInfo:getRed(r, nil); ISFarmingInfo:getWhite(w, nil)
        local function same(a, b) return a and b and math.abs((a.r or 0) - (b.r or 0)) < 0.01 and math.abs((a.g or 0) - (b.g or 0)) < 0.01 and math.abs((a.b or 0) - (b.b or 0)) < 0.01 end
        if same(rgb, g) then out = "green" elseif same(rgb, o) then out = "orange" elseif same(rgb, r) then out = "red" elseif same(rgb, w) then out = "none" else out = "other" end
    end)
    return out
end
function C.fa2read(T, sk, wl)
    local lo = H.sLo(T.sq)
    local game = H.gameWaterClass(H.cLo(T.sq), H.farmLvl())
    local cw = "?"
    pcall(function() cw = tostring(farming_vegetableconf.calcWater(lo.waterNeeded, lo.waterLvl)) end)
    -- (the Water row: the label "Water" with a word drawn to its right on its line; a lone "Water" is a button)
    local want = H.low(H.tr("Fluid_Name_Water"))
    local word, mark = "?", "none"
    for _, lbl in ipairs(S.texts or {}) do
        if word == "?" and H.low(lbl.s) == want then
            local best = nil
            for _, u in ipairs(H.rowOf(lbl, 8)) do if u.x > lbl.x and (best == nil or u.x > best.x) then best = u end end
            if best then
                word = best.s
                local ds = H.dotsNearY(lbl.y, 14)
                if #ds > 0 then mark = H.dotClass(ds[1].c) end
            end
        end
    end
    local gd = H.dotsIn(H.zone("farm:g:1"))
    local gmark = (#gd > 0) and H.dotClass(gd[1].c) or "none"
    local head = H.drewExactLow(H.tr("UI_ZeD_Farm_Garden"))
    local summary = "?"
    if head then local r = H.rowOf(head, 6); if #r > 0 then summary = r[#r].s end end
    local tag = "Farming " .. sk .. ", water " .. wl .. ", the crop needs " .. tostring(lo and lo.waterNeeded)
    Q.check(mark == game, T.L .. " (" .. tag .. "): the water word's mark is the game's colour",
        "the card: '" .. word .. "' marked " .. mark .. "; the game's word colour " .. game .. " (calcWater " .. cw .. "; it grows at the need, stops under need/1.1, loses health under need/1.3)")
    Q.check(gmark == game, T.L .. " (" .. tag .. "): the garden cell's mark is the game's colour", "the cell " .. gmark .. ", the game " .. game)
    H.note(T.L .. " (" .. tag .. "): the garden summary reads '" .. summary .. "' (fixed bands 50 and 60; the game's calcWater " .. cw .. ")")
end
function C.fa2()
    local T = { L = "FA2 the water marks" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        local crop = nil
        for _, k in ipairs(S.cropList or {}) do local p = H.prop(k); if not crop and p and p.waterLvl == 80 then crop = k end end
        T.crop = crop or S.crop
        T.sq = H.plotSq(2)
        local lo = H.plant(T.sq, T.crop, 2)
        if not (lo and lo.state == "seeded") then T.off = true; Q.check(false, T.L .. ": a stage-2 plant staged", H.plantText(T.sq)); return end
        T.need0 = lo.waterNeeded
        if not crop then H.note(T.L .. ": no crop in this game needs 80 water: " .. tostring(T.crop) .. " is given the need 80") end
        H.setPlant(T.sq, { waterNeeded = 80, waterLvl = 65, health = 100 })
        H.perkSet("Farming", 3)
        H.note(T.L .. ": " .. tostring(T.crop) .. " (the game's waterLvl " .. tostring(H.prop(T.crop) and H.prop(T.crop).waterLvl) .. ", its need after the grow " .. tostring(T.need0) .. ")")
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    for _, leg in ipairs({ { 3, 65 }, { 3, 60 }, { 4, 65 }, { 4, 60 } }) do
        local sk, wl = leg[1], leg[2]
        H.step(1, function()
            if T.off then return end
            H.perkSet("Farming", sk)
            H.setPlant(T.sq, { waterLvl = wl, waterNeeded = 80 })
            H.fresh()
        end)
        H.pause(800)
        H.step(1, function()
            if T.off then return end
            H.setPlant(T.sq, { waterLvl = wl })
            H.fresh()
        end)
        H.pause(400)
        H.step(1, function() if not T.off then C.fa2read(T, sk, wl) end end)
        if sk == 4 and wl == 65 then H.shot("oca_farm_" .. H.sizeTag(), "the farm card at Farming 4: a stage-2 crop needing 80 at water 65", function() return not T.off and H.live() end) end
    end
    H.caseEnd(T.L)
end

-- ===================================================================== FA3 the pad's opening focus on a watered plant
function C.fa3()
    local T = { L = "FA3 the pad's opening focus" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        T.sq = H.plotSq(3)
        local lo = H.plant(T.sq, S.crop, 3)
        if not (lo and lo.state == "seeded") then T.off = true; Q.check(false, T.L .. ": a young plant staged", H.plantText(T.sq)); return end
        H.setPlant(T.sq, { waterLvl = 100, health = 100, fertilizer = 0 })
        H.perkSet("Farming", 10)
        T.fert = H.give("Base.Fertilizer")
        T.u0 = H.uses(T.fert)
        H.padOn()
        H.park(true)
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(700)
    H.step(1, function()
        if T.off then return end
        T.landed = H.landed()
        T.onCard = H.ringOnCard()
        T.verbs = H.verbIds()
        T.main = H.mainFid()
    end)
    H.tapA(function() return not T.off and T.landed ~= nil end)
    H.idleQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        Q.check(T.landed ~= "oc:verb:fert", T.L .. ": on a watered, unripe plant with fertilizer carried, the pad does not open on Fertilize",
            "opened on " .. tostring(T.landed) .. " (the ring on the card " .. tostring(T.onCard) .. "; the main stop " .. tostring(T.main) .. "); verbs " .. tostring(T.verbs)
            .. "; A then: fertilizer " .. tostring(H.pf(T.sq, "fertilizer")) .. ", the fertilizer's uses " .. tostring(T.u0) .. " -> " .. tostring(H.uses(T.fert)) .. ", " .. H.plantText(T.sq))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FA4 the Dig question when the plot goes under it
function C.fa4(how)
    local T = { L = "FA4 the Dig question (" .. how .. ")" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        T.a, T.b = H.plotSq(4), H.plotSq(5)
        local la = H.plant(T.a, S.crop, 3)
        local lb = H.plant(T.b, S.crop2 or S.crop, 3)
        if not (la and lb) then T.off = true; Q.check(false, T.L .. ": two plants staged side by side", H.plantText(T.a) .. "; " .. H.plantText(T.b)); return end
        H.perkSet("Farming", 10)
        T.sh = H.give("Base.Shovel")
        if how == "pad" then H.padOn(); H.park(true) end
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.a) end)
    H.pause(300)
    if how == "mouse" then
        H.step(1, function() if not T.off then H.click("oc:verb:dig", T.L) end end)
    else
        H.padPress(T, "oc:verb:dig")
    end
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        local cf = H.confirm()
        T.q1 = cf and cf.text
        T.l1 = H.landed()
        -- the game's own Remove on the shown plot, while the question is up (ISFarmingMenu.onShovel, its cursor put away)
        pcall(ISFarmingMenu.onShovel, nil, H.cLo(T.a), S.p, T.a)
        H.cursorOff()
    end)
    H.wait(8000, function() return T.off or H.sLo(T.a) == nil end, function(ok) if not T.off then T.aGone = ok end end)
    H.pause(800)
    H.step(1, function()
        if T.off then return end
        local t = H.t()
        T.shown = t and t.sq
        local cf = H.confirm()
        T.q2 = cf and cf.text
        if T.q2 and how == "mouse" then H.click("oc:confirm:yes", T.L) end
    end)
    if how == "pad" then H.padPress(T, "oc:confirm:yes", function() return T.q2 ~= nil end) end
    H.idleQ(T, 10000)
    H.step(2, function()
        if T.off then return end
        H.cursorOff()
        Q.check(T.q1 ~= nil, T.L .. ": Dig up asks first, naming the crop", tostring(T.q1) .. " (the pad's focus " .. tostring(T.l1) .. ")")
        local shownTxt = "none"
        if T.shown then shownTxt = T.shown:getX() .. "," .. T.shown:getY() .. ((T.shown == T.b) and " (the " .. tostring(S.crop2) .. " beside it)" or "") end
        local bGone = H.sLo(T.b) == nil
        Q.check(not bGone, T.L .. ": with the shown plot removed under the question, Yes does not dig up the plot the card stepped on to",
            "the game's Remove took the first plot " .. tostring(T.aGone) .. "; the card then shows " .. shownTxt .. ", the question still up: " .. tostring(T.q2)
            .. "; the " .. tostring(S.crop2) .. " plot after: " .. (bGone and "dug up" or H.plantText(T.b)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FA5 Harvest at Ready and In bloom
function C.fa5()
    local T = { L = "FA5 Harvest at Ready and In bloom" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        T.r, T.b = H.plotSq(1), H.plotSq(3)
        local lr = H.plant(T.r, S.crop, function(l) return l.hasVegetable == true and not l.hasSeed end)
        local lb = H.plant(T.b, S.crop, function(l) return l.hasSeed == true end)
        if not (lr and lb and lr.hasVegetable and not lr.hasSeed and lb.hasSeed) then
            T.off = true
            Q.check(false, T.L .. ": a Ready and an In bloom plant grown by the farming system", H.plantText(T.r) .. " seed " .. tostring(lr and lr.hasSeed) .. "; " .. H.plantText(T.b) .. " seed " .. tostring(lb and lb.hasSeed))
            return
        end
        H.perkSet("Farming", 10)
        local p = H.prop(S.crop)
        T.seed, T.veg = p and p.seedName, p and p.vegetableName
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.r) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.mainR = H.mainFid()
        -- (Nov 26 2026 triage: drewLow("seed") also matched the stage strip's "Seedling" label, drawn at every
        -- Farming level from 2, so the old check passed on that word alone; the strip's label is left out here)
        T.seedWord = H.seedWord()
        T.s0, T.v0 = H.count(T.seed), H.count(T.veg)
        H.click("oc:verb:harvest", T.L)
    end)
    H.idleQ(T, 12000)
    H.step(2, function()
        if T.off then return end
        T.sR, T.vR = H.count(T.seed) - T.s0, H.count(T.veg) - T.v0
        H.close()
        H.padOn()
        H.park(true)
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.b) end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        T.landedB = H.landed()
        T.s1, T.v1 = H.count(T.seed), H.count(T.veg)
    end)
    H.padPress(T, "oc:verb:harvest")
    H.idleQ(T, 12000)
    H.step(2, function()
        if T.off then return end
        T.sB, T.vB = H.count(T.seed) - T.s1, H.count(T.veg) - T.v1
        -- (Nov 26 2026 triage: game parity, a NOTE. The game's menu offers Harvest the moment canHarvest holds
        -- (ISFarmingMenu doFarmingMenu2) and says nothing about seed either; seeds come only In bloom)
        local silent = T.mainR == "oc:verb:harvest" and T.sR == 0 and T.sB > 0 and not T.seedWord
        H.note(T.L .. ": where Harvest is the main verb at Ready, the card " .. (silent and "says nothing about the seed In bloom gives" or "says that In bloom gives seed, or the case does not hold")
            .. "; the game's menu is as silent (game parity) | Ready (mouse): main verb " .. tostring(T.mainR) .. ", the game gave " .. T.sR .. " seed and " .. T.vR
            .. " crop; In bloom (pad, opened on " .. tostring(T.landedB) .. "): " .. T.sB .. " seed and " .. T.vB .. " crop; a word about seed drawn at Ready (the stage strip left out) "
            .. tostring(T.seedWord))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FA6 Fertilize on a dead plot, Compost twice
function C.fa6(how)
    local T = { L = (how == "dead") and "FA6 Fertilize on a dead plot (mouse)" or "FA6 Compost on a composted plot (pad)" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        T.sq = H.plotSq(6)
        local lo = H.plant(T.sq, S.crop, 3)
        if not lo then T.off = true; Q.check(false, T.L .. ": a plant staged", H.plantText(T.sq)); return end
        H.perkSet("Farming", 10)
        if how == "dead" then
            pcall(function() lo:killThis() end)
            pcall(function() lo:saveData() end)
            T.it = H.give("Base.Fertilizer")
            T.vid = "oc:verb:fert"
        else
            H.setPlant(T.sq, { compost = true })
            T.it = H.give("Base.CompostBag")
            T.vid = "oc:verb:compost"
            H.padOn()
            H.park(true)
        end
        T.u0 = H.uses(T.it)
        T.before = H.plantText(T.sq)
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.lit = H.lit(T.vid)
        T.verbs = H.verbIds()
        if how == "dead" then H.click(T.vid, T.L) end
    end)
    if how ~= "dead" then H.padPress(T, "oc:verb:compost") end
    H.idleQ(T, 12000)
    H.step(2, function()
        if T.off then return end
        local u1 = H.uses(T.it)
        -- (Nov 26 2026 triage: game parity, a NOTE. The game's menu offers Fertilize and Compost on any plot that is
        -- not plowed land (ISFarmingMenu doFarmingMenu2: dead and composted plots too), its cursor checks no dose
        -- (isFertilizeValid, isCompostValid), and ISFertilizeAction:complete spends the item (UseAndSync) whether
        -- SPlantGlobalObject:fertilize did anything or not)
        local spent = T.lit and u1 ~= nil and T.u0 ~= nil and u1 < T.u0
        H.note(T.L .. ": the card " .. (spent and "spends" or "spends no") .. " " .. H.nm(T.it) .. " where the game's dose does nothing; the game's menu wastes it the same way (game parity) | "
            .. T.vid .. " lit " .. tostring(T.lit) .. " (verbs " .. tostring(T.verbs) .. "); uses " .. tostring(T.u0) .. " -> " .. tostring(u1) .. "; the plant before: " .. T.before .. "; after: " .. H.plantText(T.sq))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FA7 Treat at None, heavy aphids
function C.fa7none()
    local T = { L = "FA7 Treat on aphids at None (mouse)" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        T.sq = H.plotSq(7)
        local lo = H.plant(T.sq, S.crop, 3)
        if not lo then T.off = true; Q.check(false, T.L .. ": a plant staged", H.plantText(T.sq)); return end
        H.setPlant(T.sq, { aphidLvl = 0, mildewLvl = 0, fliesLvl = 0, slugsLvl = 0, waterLvl = 100 })
        H.perkSet("Farming", 3)
        T.spray = H.give("Base.GardeningSprayAphids")
        T.u0 = H.uses(T.spray)
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        local lt = H.drewExactLow(H.textCaseOf(H.tr("Farming_Aphids")))
        T.word = "?"
        if lt then local best = nil; for _, u in ipairs(H.rowOf(lt, 8)) do if u.x > lt.x and (best == nil or u.x > best.x) and u.s ~= H.tr("UI_ZeD_Farm_Treat") then best = u end end; if best then T.word = best.s end end
        T.rowLit = H.lit("farm:treat:3")
        H.click("farm:treat:3", T.L)
    end)
    H.idleQ(T, 10000)
    H.step(2, function()
        if T.off then return end
        local u1 = H.uses(T.spray)
        -- (Nov 26 2026 triage: game parity, a NOTE. The game's Treat Problem menu lists Aphids whenever the plant is
        -- seeded and the spray carried, at any level (ISFarmingMenu doFarmingMenu2), and SPlantGlobalObject:cureAphids
        -- uses the spray once per use whatever the level)
        local spent = u1 ~= nil and T.u0 ~= nil and u1 < T.u0
        H.note(T.L .. ": a Treat on a pest at None (Farming 3: the row reads None) " .. (spent and "spends" or "spends no") .. " spray; the game's own Treat spends it the same way (game parity) | "
            .. "the Aphids row reads '" .. tostring(T.word) .. "', its Treat lit " .. tostring(T.rowLit) .. "; the spray's uses " .. tostring(T.u0) .. " -> " .. tostring(u1)
            .. "; aphids " .. tostring(H.pf(T.sq, "aphidLvl")))
    end)
    H.caseEnd(T.L)
end
function H.textCaseOf(s) local o = tostring(s or ""); pcall(function() o = ZeD.textCase(o) end); return o end
function C.fa7heavy()
    local T = { L = "FA7 heavy aphids (pad)", presses = 0 }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        T.sq = H.plotSq(7)
        local lo = H.plant(T.sq, S.crop, 3)
        if not lo then T.off = true; Q.check(false, T.L .. ": a plant staged", H.plantText(T.sq)); return end
        H.setPlant(T.sq, { aphidLvl = 60, waterLvl = 100 })
        H.perkSet("Farming", 3)
        T.spray = H.give("Base.GardeningSprayAphids")
        T.u0 = H.uses(T.spray)
        H.padOn()
        H.park(true)
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(400)
    for _ = 1, 8 do
        H.padPress(T, "farm:treat:3", function() return (H.pf(T.sq, "aphidLvl") or 0) > 0 end)
        H.step(1, function() if T.focusOk then T.presses = T.presses + 1 end end)
        H.idleQ(T, 6000)
    end
    H.step(2, function()
        if T.off then return end
        local u1 = H.uses(T.spray)
        Q.check(T.presses <= 1, T.L .. ": heavy aphids (60) clear in one Treat, as the game's one spray of up to 10 uses does (FM:436-446)",
            T.presses .. " presses of the row's Treat (each its own walk and equip) to aphids " .. tostring(H.pf(T.sq, "aphidLvl")) .. "; the spray's uses " .. tostring(T.u0) .. " -> " .. tostring(u1))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FA8 which water source (the Water-from list)
-- (the director's call FA8, Nov 26 2026: the card's "Water from" lists the game's water sources, biggest first, each
-- with its name, its litres, "+N" for the plant and Use; Water pours from the one picked, else the biggest. The old
-- check, "Water keeps the bigger", was the old design.)
-- the game's water uses of an item (ISFarmingMenu.getWaterUsesInteger)
function H.waterUses(it) local n = 0; if H.isItem(it) then pcall(function() n = ISFarmingMenu.getWaterUsesInteger(it) end) end; return tonumber(n) or 0 end
-- the game's own water sources for a plant (ISFarmingMenu.doFarmingMenu2, 324-335): the item in his hand alone when it
-- holds water, else every one in his main inventory; put biggest first by the game's uses
function H.gameWaterSet()
    local out = {}
    local h = nil
    pcall(function() h = S.p:getPrimaryHandItem() end)
    if h and H.waterUses(h) > 0 then out[1] = h; return out end
    pcall(function()
        local items = H.inv():getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if H.waterUses(it) > 0 then out[#out + 1] = it end
        end
    end)
    table.sort(out, function(a, b) return H.waterUses(a) > H.waterUses(b) end)
    return out
end
-- the Water-from rows the card drew: for each farm:water:i stop, the words drawn on its line left of its Use button
function H.waterRows()
    local out = {}
    for i = 1, 12 do
        local z = H.zone("farm:water:" .. i)
        if not z then break end
        local r = { i = i, words = {} }
        local zh = z.h or 20
        for _, t in ipairs(S.texts or {}) do
            if t.x < z.x and t.y >= z.y - zh * 0.5 and t.y <= z.y + zh * 0.75 then r.words[#r.words + 1] = t.s end
        end
        out[#out + 1] = r
    end
    return out
end
function H.rowHas(r, s) for _, w in ipairs((r and r.words) or {}) do if H.has(H.low(w), H.low(s)) then return true end end; return false end
-- (a long name is cut short with dots at a narrow card: its first six letters are enough to tell these apart)
function H.rowNamed(r, it) return H.rowHas(r, string.sub(H.nm(it), 1, 6)) end
function H.rowOf(it) for _, r in ipairs(H.waterRows()) do if H.rowNamed(r, it) then return r.i end end; return nil end
function H.waterEv(T)
    return H.nm(T.small) .. " " .. H.n2(T.s0) .. " -> " .. H.n2(H.amount(T.small)) .. " L, " .. H.nm(T.big) .. " " .. H.n2(T.b0) .. " -> " .. H.n2(H.amount(T.big))
        .. " L; the plot's water " .. H.n1(T.w0) .. " -> " .. H.n1(H.pf(T.sq, "waterLvl")) .. "; Water lit " .. tostring(T.lit)
end
function C.fa8(how)
    local T = { L = "FA8 the water source (" .. how .. ")" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        T.sq = H.plotSq(8)
        local lo = H.plant(T.sq, S.crop, 3)
        if not lo then T.off = true; Q.check(false, T.L .. ": a plant staged", H.plantText(T.sq)); return end
        H.setPlant(T.sq, { waterLvl = 20, health = 100 })
        H.perkSet("Farming", 10)
        local a = H.give("Base.WaterBottle")
        local b = H.give(H.firstKnown({ "Base.PopBottle", "Base.Canteen" }))
        H.fill(a, Fluid.Water)
        H.fill(b, Fluid.Water)
        local ua, ub = H.waterUses(a), H.waterUses(b)
        if ua == ub or ua == 0 or ub == 0 then
            T.off = true
            Q.check(false, T.L .. ": a smaller and a bigger drinking-water container staged", H.nm(a) .. " " .. ua .. " uses, " .. H.nm(b) .. " " .. ub .. " uses (the game's)")
            return
        end
        if ua < ub then T.small, T.big = a, b else T.small, T.big = b, a end
        T.s0, T.b0, T.w0 = H.amount(T.small), H.amount(T.big), H.pf(T.sq, "waterLvl")
        if how == "pad" then H.padOn(); H.park(true) end
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(400)
    -- leg 1: the list against the game's set, then Use on the smaller and Water
    H.step(1, function()
        if T.off then return end
        local set, rows, bad, seen = H.gameWaterSet(), H.waterRows(), {}, {}
        local missing = math.ceil((100 - (tonumber(H.pf(T.sq, "waterLvl")) or 0)) / 10)
        for i, it in ipairs(set) do
            local r = rows[i]
            local litres = string.format("%.1f L", H.amount(it))
            local gain = "+" .. tostring(math.min(H.waterUses(it), missing, 10) * 10)
            seen[#seen + 1] = H.nm(it) .. " " .. H.waterUses(it) .. " uses " .. litres .. " " .. gain
            if not r then
                bad[#bad + 1] = H.nm(it) .. " has no row " .. i
            else
                if not H.rowNamed(r, it) then bad[#bad + 1] = "row " .. i .. " is not " .. H.nm(it) .. " (" .. H.list(r.words, 5) .. ")" end
                if not H.rowHas(r, litres) then bad[#bad + 1] = "row " .. i .. " has no '" .. litres .. "' (" .. H.list(r.words, 5) .. ")" end
                if not H.rowHas(r, gain) then bad[#bad + 1] = "row " .. i .. " has no '" .. gain .. "' (" .. H.list(r.words, 5) .. ")" end
                if not H.lit("farm:water:" .. i) then bad[#bad + 1] = "row " .. i .. " has no live Use" end
            end
        end
        if #rows ~= #set then bad[#bad + 1] = #rows .. " rows drawn for the game's " .. #set .. " sources" end
        Q.check(#set >= 2 and #bad == 0, T.L .. ": Water from lists each of his water containers, biggest first, each with its litres, its +N and Use (the game's set: ISFarmingMenu.doFarmingMenu2 324-335)",
            "the game's, biggest first: " .. H.list(seen, 6) .. "; the plot's water " .. H.n1(H.pf(T.sq, "waterLvl")) .. "; " .. H.list(bad, 6))
        T.smallRow = H.rowOf(T.small)
        T.lit = H.lit("oc:verb:water")
        if not T.smallRow then T.off = true; Q.check(false, T.L .. ": the smaller container (" .. H.nm(T.small) .. ") has a Water-from row", H.list(H.zonesLike("farm:water:"), 6)); return end
        if how == "mouse" then H.click("farm:water:" .. T.smallRow, T.L .. " Use") end
    end)
    if how == "pad" then
        H.padPress(T, function() return "farm:water:" .. tostring(T.smallRow) end, function() return T.smallRow ~= nil end)
        H.step(1, function() T.useFocus = T.focusOk end)
    end
    H.settle(400)
    H.step(1, function()
        if T.off then return end
        T.lit = H.lit("oc:verb:water")
        if how == "mouse" then H.click("oc:verb:water", T.L) end
    end)
    if how == "pad" then H.padPress(T, "oc:verb:water") end
    H.idleQ(T, 12000)
    H.step(2, function()
        if T.off then return end
        local s1, b1, w1 = H.amount(T.small), H.amount(T.big), tonumber(H.pf(T.sq, "waterLvl")) or 0
        Q.check(s1 < T.s0 - 0.001 and math.abs(b1 - T.b0) < 0.001 and w1 > (tonumber(T.w0) or 0),
            T.L .. ": Use on the smaller, then Water, pours from the smaller: its litres drop, the bigger's stay, the plot's water rises",
            H.waterEv(T) .. ((how == "pad") and ("; the pad reached Use " .. tostring(T.useFocus)) or ""))
    end)
    -- leg 2: nothing picked (a fresh card, the hands cleared, both filled, the plot dry again): Water alone
    H.step(2, function()
        if T.off then return end
        H.qstop()
        H.close()
        H.loose(T.small)
        H.loose(T.big)
        H.fill(T.small, Fluid.Water)
        H.fill(T.big, Fluid.Water)
        H.setPlant(T.sq, { waterLvl = 20 })
        T.s0, T.b0, T.w0 = H.amount(T.small), H.amount(T.big), H.pf(T.sq, "waterLvl")
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.lit = H.lit("oc:verb:water")
        if how == "mouse" then H.click("oc:verb:water", T.L) end
    end)
    if how == "pad" then H.padPress(T, "oc:verb:water") end
    H.idleQ(T, 12000)
    H.step(2, function()
        if T.off then return end
        local s1, b1, w1 = H.amount(T.small), H.amount(T.big), tonumber(H.pf(T.sq, "waterLvl")) or 0
        Q.check(b1 < T.b0 - 0.001 and math.abs(s1 - T.s0) < 0.001 and w1 > (tonumber(T.w0) or 0),
            T.L .. ": with nothing picked, Water pours from the biggest: its litres drop, the smaller's stay, the plot's water rises", H.waterEv(T))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FA9 sowing out of season
function C.fa9(how)
    local T = { L = (how == "mouse") and "FA9 sowing out of season (Farming 5, mouse)" or "FA9 sowing out of season (Farming 6, pad)" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        local opt = nil
        pcall(function() opt = getSandboxOptions():getOptionByName("PlantGrowingSeasons") end)
        if not opt then T.off = true; Q.check(false, T.L .. ": the sandbox's PlantGrowingSeasons is there"); return end
        pcall(function() opt:setValue(true) end)
        S.back.seasons = true
        T.month = 1
        pcall(function() T.month = getGameTime():getMonth() + 1 end)
        local function inList(list) for _, m in ipairs(list or {}) do if m == T.month then return true end end; return false end
        for _, k in ipairs(S.cropList or {}) do
            local p = H.prop(k)
            if not T.crop and p and p.sowMonth and #p.sowMonth > 0 and not inList(p.sowMonth) and H.known((p.seedTypes and p.seedTypes[1]) or p.seedName) then T.crop = k end
        end
        if not T.crop then
            T.off = true
            H.note(T.L .. ": every crop of this game may be sown in month " .. T.month .. ": out of season cannot be staged this month (no verdict)")
            return
        end
        local p = H.prop(T.crop)
        -- (Build, Nov 26 2026: the game and the card sow from seedTypes (Base.BarleySeed), not seedName (the sheaf))
        T.seed = (p.seedTypes and p.seedTypes[1]) or p.seedName
        T.recipe = p.seasonRecipe
        if how == "mouse" then H.perkSet("Farming", 5); H.recipeOff(T.recipe) else H.perkSet("Farming", 6) end
        T.sq = H.plotSq(9)
        H.plow(T.sq)
        T.it = H.give(T.seed)
        if how == "pad" then H.padOn(); H.park(true) end
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.row = nil
        for i, r in ipairs((H.d() and H.d().seeds) or {}) do if r.seedName == T.seed and not T.row then T.row = i end end
        local bad = H.tr("Farming_Tooltip_BadMonth")
        T.tag = H.drewExactLow(bad) ~= nil
        T.tags = H.textsLike(bad, 3)
        if T.row and how == "mouse" then H.click("farm:sow:" .. T.row, T.L) end
    end)
    if how == "pad" then H.padPress(T, function() return "farm:sow:" .. tostring(T.row) end, function() return T.row ~= nil end) end
    H.pause(300)
    H.step(1, function() if not T.off then T.asked = H.confirm() ~= nil end end)
    H.idleQ(T, 12000)
    H.step(2, function()
        if T.off then return end
        local lo = H.sLo(T.sq)
        local cursed = lo and lo.cursed
        local ev = tostring(T.crop) .. " sown in month " .. T.month .. " (the game's sowMonth " .. H.list(H.prop(T.crop).sowMonth) .. "): the plant " .. tostring(lo and lo.state)
            .. ", cursed " .. tostring(cursed) .. "; the row " .. tostring(T.row) .. ", the bad-month tag drawn " .. tostring(T.tag) .. ", a question " .. tostring(T.asked)
            .. "; Farming " .. H.farmLvl() .. ", the season recipe " .. tostring(T.recipe) .. " known " .. tostring(H.recipeKnown(T.recipe))
        if how == "mouse" then
            -- (Nov 26 2026 triage: game parity, a NOTE. Below Farming 6 without the season recipe the game shows no
            -- season word either: its seed tooltip needs Farming 6 or the recipe (ISFarmingMenu.canPlow) and the
            -- seed row's season word needs the farming cheat (doSeedMenu); ISFarmingMenu.onSeed sows with no question)
            H.note(T.L .. ": sowing out of season " .. ((cursed and not T.tag and not T.asked) and "says nothing before the game curses the plant" or "says so, or the game did not curse it")
                .. "; the game's own Sow is as silent at this level (game parity) | " .. ev)
        else
            Q.check(T.tag, T.L .. ": at Farming 6 the seed row carries the bad-month tag", ev)
        end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FA10 small screens (the drawer, Large text, UI scale 2)
function C.gardenFit(T, label)
    local bad, n = {}, 0
    for i = 1, 9 do
        local z = H.zone("farm:g:" .. i)
        if z then
            for _, t in ipairs(S.texts or {}) do
                if t.y >= z.y and t.y <= z.y + z.h and t.x >= z.x - 2 and t.x <= z.x + z.w then
                    n = n + 1
                    local tw = H.textW(t)
                    if t.x < z.x - 0.5 or t.x + tw > z.x + z.w + 0.5 then bad[#bad + 1] = "'" .. t.s .. "' " .. math.floor(tw) .. " px in a " .. math.floor(z.w) .. " px cell" end
                end
            end
        end
    end
    Q.check(#bad == 0, T.L .. " (" .. label .. "): each garden label stays inside its cell", n .. " labels; " .. H.list(bad, 6))
end
function C.fa10()
    local T = { L = "FA10 small screens (the farm card)" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        for i = 1, 8 do
            local crop = (S.cropList or {})[i] or S.crop
            H.plant(H.plotSq(i), crop, 3)
        end
        H.perkSet("Farming", 10)
        T.sq = H.plotSq(1)
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(600)
    H.step(1, function()
        if T.off then return end
        C.measure(T, "FA10 the farm card at " .. H.sizeTag())
        C.gardenFit(T, "the run's text size")
        H.sizeSet("large")
    end)
    H.pause(1500)
    H.step(1, function() if not T.off and not H.live() then H.zcall(function() H.openPlot(T.sq) end) end end)
    H.pause(900)
    H.step(1, function()
        if T.off then return end
        C.measure(T, "FA10 the farm card at " .. H.sizeTag() .. ", Large text")
        C.gardenFit(T, "Large text")
        H.sizeBack()
    end)
    H.pause(1200)
    -- UI scale 2: picked as ZeD setup picks it (the windows reopen), then put back
    H.step(1, function()
        if T.off then return end
        T.si = H.scaleIdx(2.0)
        local tooBig = false
        pcall(function() tooBig = ZeD.Scale.stepTooBig(2.0) and true or false end)
        if not T.si or tooBig then
            T.noScale = true
            H.note(T.L .. ": UI scale 2 is not offered here (ZeD's setup " .. (tooBig and "dims the step: it does not fit " .. H.sizeTag() or "has no 2x step") .. "): not measured at 2x")
            return
        end
        H.close()
        S.back.scale = true
        H.scaleSet(T.si)
    end)
    H.wait(15000, function() return T.off or T.noScale or H.scaleSettled() end, function(ok)
        if T.off or T.noScale then return end
        if not ok then H.note(T.L .. ": the UI scale did not settle at 2x in 15 s") end
        RT.pairOpen()
    end)
    H.pause(1500)
    H.step(1, function() if not (T.off or T.noScale) then T.openAt = getTimestampMs(); H.zcall(function() H.openPlot(T.sq) end) end end)
    H.wait(6000, function() return T.off or T.noScale or (H.kind() == "plant" and H.live()) end, function() end)
    H.pause(700)
    H.step(1, function()
        if T.off or T.noScale then return end
        if H.kind() == "plant" then C.measure(T, "FA10 the farm card at " .. H.sizeTag() .. ", UI scale 2")
        else H.note(T.L .. ": the card did not open again at UI scale 2") end
        H.close()
        H.scaleBack()
    end)
    H.wait(15000, function() return T.noScale or H.scaleSettled() end, function() if not T.noScale then RT.pairOpen() end end)
    H.pause(800)
    H.caseEnd(T.L)
end
function H.scaleBack()
    if not S.back.scale then return end
    S.back.scale = nil
    local f = S.found
    local cur = H.optVal(ZeD.Settings and ZeD.Settings.uiScaleOption)
    if f.scaleIdx and cur ~= f.scaleIdx then H.scaleSet(f.scaleIdx) end
end

-- ===================================================================== FA11 the words
function C.fa11()
    local T = { L = "FA11 the words" }
    H.step(2, function()
        local read, missing, seen = H.langKeys({ "UI_ZeD_Farm_MoreAt", "UI_ZeD_Farm_ListAnd" })
        Q.check(read > 0 and #missing == 0, "FA11: UI_ZeD_Farm_MoreAt and UI_ZeD_Farm_ListAnd are in every language the mod ships (else the line under Farming 6 reads English)",
            read .. " UI.json files read (" .. H.list(seen, 20) .. "); missing in " .. H.list(missing, 20))
        -- (fix/cards3, Nov 26 2026: each label is the shortest start of the crop's name, 3 letters or more, no other
        -- crop's name shares; the check works that rule out from the game's names and finds any two labels alike)
        local names, by, coll = {}, {}, {}
        for _, k in ipairs(S.cropList or {}) do names[#names + 1] = H.cropName(k) end
        for i, nm in ipairs(names) do
            local lab = nm
            for n = 3, string.len(nm) do
                local pre, clash = string.sub(nm, 1, n), false
                for j, other in ipairs(names) do if j ~= i and string.sub(other, 1, n) == pre then clash = true end end
                if not clash then lab = pre; break end
            end
            by[lab] = by[lab] or {}
            by[lab][#by[lab] + 1] = nm
        end
        for three, list in pairs(by) do if #list > 1 then coll[#coll + 1] = three .. " (" .. table.concat(list, ", ") .. ")" end end
        table.sort(coll)
        Q.check(#coll == 0, "FA11: the garden's labels (the shortest unique start, 3 letters or more) tell the crops apart in " .. H.lang(), #coll .. " collisions: " .. H.list(coll, 12))
        H.note("FA11: the next-stage words and the crop names are lowercased into ZeD's lines (German nouns lose their capitals): this run is in " .. H.lang()
            .. (H.lang() == "DE" and "" or "; only a German run shows it"))
    end)
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        T.sq = H.plotSq(1)
        local lo = H.plant(T.sq, S.crop, 3)
        if not lo then T.off = true; Q.check(false, T.L .. ": a plant staged", H.plantText(T.sq)); return end
        pcall(function() lo:destroyThis() end)
        pcall(function() lo:saveData() end)
        H.perkSet("Farming", 10)
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        local lo = H.sLo(T.sq)
        local gameName = "?"
        pcall(function() gameName = farming_vegetableconf.getObjectName(lo) end)
        local dead = H.txt("Farming_Dead", "Dead")
        local capDead = dead
        pcall(function() capDead = S.OC.cap(dead) end)
        local deadTag = H.drewExactLow(capDead) ~= nil
        Q.check(not deadTag, "FA11: a trampled (destroyed) plant's tag says what the game calls it", "the game: '" .. tostring(gameName) .. "' (state " .. tostring(lo and lo.state)
            .. "); the card drew the tag '" .. capDead .. "' " .. tostring(deadTag) .. "; words with Dead or Destroyed: " .. H.textsLike(dead, 4) .. " | " .. H.textsLike(H.txt("Farming_Destroyed", "Destroyed"), 4))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== FA12 a field in reach, the shovel dropped before Yes
function C.fa12field()
    local T = { L = "FA12 a field of plots in reach" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        H.plant(H.plotSq(1), S.crop, 3)
        H.perkSet("Farming", 10)
    end)
    H.cardQ(T, "plant", function() H.openPlot(H.plotSq(1)) end)
    H.step(1, function() S.preMs, S.preN = 0, 0 end)
    H.pause(3000)
    H.step(1, function()
        if T.off then return end
        T.one, T.n1 = (S.preMs or 0) / math.max(1, S.preN or 1), S.preN
        for i = 2, S.FW * 3 do H.plant(H.plotSq(i), (i % 2 == 0) and S.crop or (S.crop2 or S.crop), nil) end
        S.preMs, S.preN = 0, 0
    end)
    H.pause(3000)
    H.step(1, function()
        if T.off then return end
        T.many = (S.preMs or 0) / math.max(1, S.preN or 1)
        local n = #((H.e() and H.e().list) or {})
        H.note(T.L .. ": the card's draw took " .. H.n2(T.one) .. " ms a frame with 1 plot (" .. tostring(T.n1) .. " frames) and " .. H.n2(T.many) .. " ms with " .. n
            .. " plots in reach (the garden reads every plot every 250 ms); MP's other player watering: see the SKIP")
        Q.check(H.live() and n >= S.FW * 3 - 1, T.L .. ": the card keeps drawing with the field in reach", n .. " plots listed, drawing " .. tostring(H.live()))
        Q.skip("FA12 on a server", "multiplayer: the card following another player's watering and spraying needs a server and a second player")
    end)
    H.caseEnd(T.L)
end
function C.fa12shovel()
    local T = { L = "FA12 the shovel dropped before Yes (mouse)" }
    H.step(2, function()
        if not H.caseStart(T, "farm") then return end
        T.sq = H.plotSq(2)
        H.plant(T.sq, S.crop, 3)
        H.perkSet("Farming", 10)
        T.sh = H.give("Base.Shovel")
    end)
    H.cardQ(T, "plant", function() H.openPlot(T.sq) end)
    H.pause(300)
    H.step(1, function() if not T.off then H.click("oc:verb:dig", T.L) end end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.q = H.confirm() and H.confirm().text
        H.removeItem(T.sh)
        T.ex = H.errN()
    end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        if T.q then H.click("oc:confirm:yes", T.L) end
        T.kinds = H.qkinds()
        T.sa = H.qcount("ISShovelAction")
        T.item = "none"
        for _, a in ipairs(H.queue()) do if a.Type == "ISShovelAction" then T.item = tostring(a.item) end end
    end)
    H.pause(1500)
    H.step(1, function()
        if T.off then return end
        local e1 = H.errN()
        local new = (T.ex and e1) and (e1 - T.ex) or 0
        Q.check(T.q ~= nil and T.sa == 0 and new == 0, T.L .. ": with the shovel dropped between Dig and Yes, Yes queues no dig without a shovel and nothing throws",
            "the question '" .. tostring(T.q) .. "'; Yes queued " .. tostring(T.kinds) .. " (the dig's item " .. T.item .. "); " .. new .. " new Lua errors; the plant: " .. H.plantText(T.sq))
        -- (counted here: the case's own error check below counts the rest)
        if S.e0 and new > 0 then S.e0 = S.e0 + new end
        H.qstop()
    end)
    H.caseEnd(T.L)
end
-- ===================================================================== the trough cases
-- (inside a step) a simple trough on the yard, he two tiles south of it
function H.troughHere(T)
    T.tsq = H.ysq(-5, -3)
    T.tr = H.mkTrough(T.tsq)
    if not T.tr then T.off = true; Q.check(false, T.L .. ": a trough staged by the game's trough system", "addTrough left none at " .. tostring(T.tsq and (T.tsq:getX() .. "," .. T.tsq:getY()))); return false end
    H.atYard(-5, -1)
    return true
end
function H.pourRow(T, item)
    for i, r in ipairs((H.d() and H.d().pourRows) or {}) do if r.item == item then return i end end
    return nil
end
function C.tg1(how)
    local T = { L = (how == "mouse") and "TG1 bleach to pour (mouse)" or "TG1 gasoline to pour (pad)" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.troughHere(T) then return end
        T.fluid = (how == "mouse") and Fluid.Bleach or Fluid.Petrol
        -- (the game's own bottle of bleach when it has one; else a bottle filled with it)
        T.bottle = nil
        if how == "mouse" and H.known("Base.Bleach") then
            T.bottle = H.give("Base.Bleach")
            if H.amount(T.bottle) <= 0 then H.removeItem(T.bottle); T.bottle = nil end
        end
        if not T.bottle then
            T.bottle = H.give("Base.WaterBottle")
            H.fill(T.bottle, T.fluid)
        end
        T.amt0 = H.amount(T.bottle)
        if T.amt0 <= 0 then T.off = true; Q.check(false, T.L .. ": a bottle holding the fluid is carried", H.nm(T.bottle) .. " holds " .. H.n2(T.amt0) .. " L"); return end
        T.fname = "?"
        pcall(function() T.fname = H.fc(T.bottle):getPrimaryFluid():getTranslatedName() end)
        T.can = "?"
        pcall(function() T.can = tostring(FluidContainer.CanTransfer(H.fc(T.bottle), H.tfc(T.tr))) end)
        T.gameWater = false
        pcall(function() T.gameWater = H.inv():getAllWaterFluidSources(true):contains(T.bottle) and true or false end)
        if how == "pad" then H.padOn(); H.park(true) end
    end)
    H.cardQ(T, "trough", function() H.openTrough(T.tr) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.row = H.pourRow(T, T.bottle)
        T.rows = #((H.d() and H.d().pourRows) or {})
        if T.row and how == "mouse" then H.click("trough:pour:" .. T.row, T.L) end
    end)
    if how == "pad" then H.padPress(T, function() return "trough:pour:" .. tostring(T.row) end, function() return T.row ~= nil end) end
    H.pause(600)
    H.step(1, function()
        if T.off then return end
        T.k1 = H.kind()
        if T.k1 == "fluid" and how == "mouse" then H.click("oc:verb:pour", T.L) end
    end)
    if how == "pad" then H.padPress(T, "oc:verb:pour", function() return T.k1 == "fluid" end) end
    H.idleQ(T, 12000)
    H.pause(500)
    H.step(2, function()
        if T.off then return end
        local amt = 0
        pcall(function() amt = H.tfc(T.tr):getSpecificFluidAmount(T.fluid) end)
        Q.check(T.row == nil, T.L .. ": the card lists no " .. T.fname .. " to pour where animals drink (the game's trough path pours water only)",
            "carried: " .. H.nm(T.bottle) .. " with " .. H.n2(T.amt0) .. " L; listed as row " .. tostring(T.row) .. " of " .. tostring(T.rows) .. "; the game's FluidContainer.CanTransfer "
            .. tostring(T.can) .. ", among the game's water sources " .. tostring(T.gameWater))
        Q.check(amt <= 0.001, T.L .. ": no " .. T.fname .. " reaches the trough", H.n2(amt) .. " L of it in the trough after the pour (the Transfer opened the " .. tostring(T.k1) .. " card)")
    end)
    H.caseEnd(T.L)
end
function C.tg2()
    local T = { L = "TG2 the Food tag with no feed left" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.troughHere(T) then return end
        local cont = nil
        pcall(function() cont = T.tr:getContainer() end)
        T.how = "none"
        -- a feed bag drained to nothing (its uses 0), lying in the trough
        local it = nil
        pcall(function() it = instanceItem("Base.AnimalFeedBag") end)
        if it and cont then
            pcall(function() cont:AddItem(it) end)
            pcall(function() it:setCurrentUses(0) end)
            pcall(function() it:setUsedDelta(0) end)
            pcall(function() it:setCurrentUsesFloat(0) end)
            T.it, T.how = it, "an emptied feed bag"
        end
        pcall(function() T.tr:checkOverlayAfterAnimalEat() end)
        T.feed = H.feed(T.tr)
    end)
    H.cardQ(T, "trough", function() H.openTrough(T.tr) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.feed = H.feed(T.tr)
        local food = H.tr("UI_ZeD_Trough_PillFood")
        T.pill = H.drewExactLow(food) ~= nil
        Q.check(not (T.pill and T.feed <= 0), T.L .. ": the Food tag shows only while the trough holds feed",
            "the tag '" .. food .. "' drawn " .. tostring(T.pill) .. "; the game's getCurrentFeedAmount " .. H.n2(T.feed) .. " with " .. H.tItems(T.tr) .. " item(s) in it (" .. T.how .. ", uses " .. tostring(H.uses(T.it)) .. ")")
        H.note("TG2: the Animals tab's trough row counts the same items (AnimalsTab.lua 1979-1981)")
    end)
    H.caseEnd(T.L)
end
function C.tg3(how)
    local T = { L = "TG3 Add water after Take all (" .. how .. ")", pressed = {} }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.troughHere(T) then return end
        pcall(ISFeedingTroughMenu.onAddFoodDebug, S.p, T.tr)
        T.items0 = H.tItems(T.tr)
        T.fc0 = H.tfc(T.tr) ~= nil
        if how == "pad" then H.padOn(); H.park(true); H.hidden("all") end
    end)
    H.cardQ(T, "trough", function() H.openTrough(T.tr) end)
    H.pause(400)
    -- (the director's call TG5, Nov 26 2026: Take moves one, Take All the kind. The game's debug add puts two feed
    -- bags in, one kind, so the row's Take All empties it; Take on the first row until empty where none is drawn)
    for _ = 1, 3 do
        H.step(1, function()
            T.zid = nil
            if T.off or H.tItems(T.tr) == 0 then return end
            T.zid = (H.zone("trough:takeall:1") ~= nil) and "trough:takeall:1" or "trough:take:1"
            T.pressed[#T.pressed + 1] = T.zid
            if how == "mouse" then H.click(T.zid, T.L) end
        end)
        if how == "pad" then H.padPress(T, function() return T.zid end, function() return T.zid ~= nil end) end
        H.idleQ(T, 12000)
        H.settle(600)
    end
    H.settle(300)
    H.step(1, function()
        if T.off then return end
        T.items1 = H.tItems(T.tr)
        T.fc1 = H.tfc(T.tr) ~= nil
        T.lit = H.lit("oc:verb:water")
        T.drawn = H.zone("oc:verb:water") ~= nil
        T.folded = H.zone("oc:hv:water") ~= nil
        local needs = H.list(S.needs, 6)
        Q.check(T.items0 > 0 and T.items1 == 0, T.L .. ": Take All (the game's transfers) empties the trough of its food",
            T.items0 .. " -> " .. T.items1 .. " by " .. H.list(T.pressed, 4))
        Q.check(T.lit == T.fc1, T.L .. ": after Take all, Add water is live exactly when the trough has its fluid container again",
            "the game's fluid container: with food " .. tostring(T.fc0) .. ", after " .. tostring(T.fc1) .. "; Add water lit " .. tostring(T.lit) .. ", in the verb row " .. tostring(T.drawn)
            .. ", folded " .. tostring(T.folded) .. " (hidden actions " .. H.hiddenNow() .. "); NEEDS lines: " .. needs)
        if how == "pad" then
            -- (Nov 26 2026: the NEEDS words are asked only of a greyed Add water the card drew. With food left in the
            -- trough Add water is gone, as the game's one-or-the-other has it, and has nothing to say; live, neither)
            if T.drawn and not T.lit then
                local named = false
                for _, l in ipairs(S.needs or {}) do if H.has(H.low(l), H.low(H.tr("UI_ZeD_Trough_AddWater"))) and string.len(l) > string.len(H.tr("UI_ZeD_Trough_AddWater")) + 8 then named = true end end
                Q.check(named, T.L .. ": under hidden actions all, the greyed Add water says what it needs", needs)
            else
                H.note(T.L .. ": under hidden actions all, Add water is " .. (T.lit and "live" or "not drawn") .. " with " .. T.items1 .. " item(s) left in the trough: no greyed Add water to read | NEEDS lines: " .. needs)
            end
        end
    end)
    H.caseEnd(T.L)
end
function C.tg4()
    local T = { L = "TG4 a double trough on a zone's edge" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        local sq = H.ysq(-5, 2)
        local ok, why = H.build("Base.FeedingTroughDoubleMetal", sq)
        local tiles = {}
        for dy = -1, 1 do
            for dx = -1, 1 do
                local s = H.sqXY(sq:getX() + dx, sq:getY() + dy)
                local o = H.objOn(s, "IsoFeedingTrough")
                if o and not (S.objs0 and S.objs0[o]) then tiles[#tiles + 1] = o end
            end
        end
        if #tiles < 2 then T.off = true; Q.check(false, T.L .. ": a double trough built by the game's build", tostring(ok) .. " " .. tostring(why) .. ", " .. #tiles .. " trough tiles"); return end
        local m = tiles[1]
        pcall(function() m = tiles[1]:getMasterTrough() or tiles[1] end)
        T.tr = m
        for _, o in ipairs(tiles) do if o ~= m and not T.other then T.other = o end end
        local ms, os = m:getSquare(), T.other:getSquare()
        local mx, my, ox, oy = ms:getX(), ms:getY(), os:getX(), os:getY()
        local dx, dy = ox - mx, oy - my
        -- the tiles the zone covers: the other tile and the side away from the master, never the master's
        -- (Nov 26 2026 triage: the zone's end is one past its last tile, as ISAddDesignationAnimalZoneUI passes
        -- endX + 1; with the master east or south of the other tile the old bounds left both tiles out)
        local x1 = ox - ((dx == 0) and 1 or ((dx > 0) and 0 or 1))
        local x2 = ox + ((dx == 0) and 1 or ((dx > 0) and 1 or 0))
        local y1 = oy - ((dy == 0) and 1 or ((dy > 0) and 0 or 1))
        local y2 = oy + ((dy == 0) and 1 or ((dy > 0) and 1 or 0))
        T.zname = "ZeDQA oca edge"
        H.mkZone(T.zname, x1, y1, x2 + 1, y2 + 1)
        T.zm, T.zo = "none", "none"
        pcall(function() local z = DesignationZoneAnimal.getZone(mx, my, 0); if z then T.zm = z:getName() end end)
        pcall(function() local z = DesignationZoneAnimal.getZone(ox, oy, 0); if z then T.zo = z:getName() end end)
        H.goTo(mx + 0.5, my + 2.5, 0)
    end)
    H.cardQ(T, "trough", function() H.openTrough(T.tr) end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        T.named = H.drew(T.zname) ~= nil
        T.warn = H.drewLow(string.sub(H.tr("UI_ZeD_Trough_NoZoneWarn"), 1, 20)) ~= nil
        local linked = "?"
        pcall(function() linked = tostring(T.tr:getLinkedAnimals():size()) end)
        -- (Nov 26 2026 triage: game parity, a NOTE. ISFeedingTroughUI:render reads the zone at the master's square
        -- only, as the card does)
        local ev = "the master tile's zone " .. T.zm .. ", the other tile's " .. T.zo .. "; the card drew the zone's name " .. tostring(T.named) .. ", the no-zone warning " .. tostring(T.warn)
            .. ", linked animals " .. linked
        if T.zo == "none" or T.zm ~= "none" then
            H.note(T.L .. ": the staging did not put only the other tile in the zone: no reading | " .. ev)
        else
            H.note(T.L .. ": with only the other tile in an animal zone, the card " .. (T.named and "names that zone" or "reads no zone")
                .. "; the game's own window reads the master square too (ISFeedingTroughUI:render, game parity) | " .. ev)
        end
        Q.skip("TG4 the linked count on a client", "multiplayer: getLinkedAnimals read on a client needs a server and a second player")
    end)
    H.caseEnd(T.L)
end
-- the TG5 row's stops for the staged kind: Add and Add All in "Your feed" (mouse), Take and Take All in "In the
-- trough" (pad); the All stop nil when the card drew none
function H.tg5fids(T, how)
    local rows = (how == "mouse") and ((H.d() and H.d().feedRows) or {}) or ((H.d() and H.d().inside) or {})
    local row = nil
    for i, g in ipairs(rows) do if g.item and H.ft(g.item) == T.ft and not row then row = i end end
    if not row then return nil, nil end
    local one = ((how == "mouse") and "trough:feed:" or "trough:take:") .. row
    local all = ((how == "mouse") and "trough:feedall:" or "trough:takeall:") .. row
    if not H.zone(all) then all = nil end
    return one, all
end
function C.tg5(how)
    local T = { L = (how == "mouse") and "TG5 Add one, then Add All (mouse)" or "TG5 Take one, then Take All (pad)" }
    T.allKey = (how == "mouse") and "ContextMenu_AddAll" or "IGUI_invpage_Loot_all"
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.troughHere(T) then return end
        local cont = T.tr:getContainer()
        local probe = nil
        pcall(function() probe = instanceItem("Base.Carrots") end)
        local allowed = false
        pcall(function() allowed = T.tr:isItemAllowedInContainer(cont, probe) == true end)
        T.ft, T.n = allowed and "Base.Carrots" or "Base.AnimalFeedBag", allowed and 10 or 3
        T.items = H.giveN(T.ft, T.n)
        if how == "pad" then
            for _, it in ipairs(T.items) do pcall(function() H.inv():Remove(it); cont:AddItem(it) end) end
            H.padOn(); H.park(true)
        end
        T.in0 = H.tItems(T.tr)
    end)
    H.cardQ(T, "trough", function() H.openTrough(T.tr) end)
    H.pause(400)
    -- one press of the row's own button
    H.step(1, function()
        if T.off then return end
        T.one, T.all = H.tg5fids(T, how)
        T.all0 = T.all
        if how == "mouse" and T.one then H.click(T.one, T.L) end
        T.q1 = H.qcount("ISInventoryTransferAction")
    end)
    if how == "pad" then
        H.padPress(T, function() return T.one end, function() return T.one ~= nil end)
        H.step(1, function() T.q1 = H.qcount("ISInventoryTransferAction") end)
    end
    H.idleQ(T, 15000)
    H.settle(600)
    -- then the All beside it, on what is left of the kind
    H.step(1, function()
        if T.off then return end
        T.in1 = H.tItems(T.tr)
        local _, all = H.tg5fids(T, how)
        T.all = all
        local b = all and H.btn(all)
        T.allLabel = b and b.label or "none"
        if how == "mouse" and all then H.click(all, T.L) end
        T.q2 = H.qcount("ISInventoryTransferAction")
    end)
    if how == "pad" then
        H.padPress(T, function() return T.all end, function() return T.all ~= nil end)
        H.step(1, function() T.q2 = H.qcount("ISInventoryTransferAction") end)
    end
    H.idleQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        local in2 = H.tItems(T.tr)
        local m = (how == "mouse")
        local moved1 = m and (T.in1 - T.in0) or (T.in0 - T.in1)
        local moved2 = m and (in2 - T.in1) or (T.in1 - in2)
        local carried = H.count(T.ft)
        local word = H.tr(T.allKey)
        local whole = false
        if m then whole = (in2 == T.n and carried == 0) else whole = (in2 == 0 and carried == T.n) end
        Q.check(T.one ~= nil and moved1 == 1, T.L .. ": one press of " .. (m and "Add" or "Take") .. " moves one " .. H.nm(T.items[1]) .. " (the loot window's one)",
            "the stop " .. tostring(T.one) .. "; one press queued " .. tostring(T.q1) .. " transfers and moved " .. moved1 .. " of " .. T.n .. " (in the trough " .. T.in0 .. " -> " .. tostring(T.in1) .. ")")
        Q.check(T.all ~= nil and T.allLabel == word and moved2 == T.n - 1 and whole,
            T.L .. ": the kind of several has '" .. word .. "' beside its row (" .. T.allKey .. "), and one press of it moves the rest",
            "the All stop " .. tostring(T.all) .. " (before the first press " .. tostring(T.all0) .. "), its label '" .. tostring(T.allLabel) .. "'; one press queued " .. tostring(T.q2)
            .. " transfers and moved " .. moved2 .. " of the " .. (T.n - 1) .. " left (in the trough " .. tostring(T.in1) .. " -> " .. in2 .. ", carried " .. carried .. ")")
    end)
    H.caseEnd(T.L)
end
function C.tg6(how)
    local T = { L = "TG6 Empty (" .. how .. ")" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.troughHere(T) then return end
        pcall(ISFeedingTroughMenu.onAddWaterDebug, S.p, T.tr, Fluid.Water)
        T.w0 = H.water(T.tr)
        local lo0 = H.troughLo(T.tr)
        T.loW0 = lo0 and lo0.water
        T.fname = "?"
        pcall(function() T.fname = H.tfc(T.tr):getPrimaryFluid():getTranslatedName() end)
        if how == "pad" then H.padOn(); H.park(true) end
    end)
    H.cardQ(T, "trough", function() H.openTrough(T.tr) end)
    H.pause(400)
    if how == "mouse" then H.shot("oca_trough_" .. H.sizeTag(), "the trough card with water in it", function() return H.kind() == "trough" and H.live() end) end
    H.step(1, function() if not T.off and how == "mouse" then H.click("oc:verb:empty", T.L) end end)
    if how == "pad" then H.padPress(T, "oc:verb:empty") end
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.q = H.confirm() and H.confirm().text
        T.qDrawn = S.qLast
        T.lq = H.landed()
        if T.q and how == "mouse" then H.click("oc:confirm:yes", T.L) end
    end)
    if how == "pad" then H.padPress(T, "oc:confirm:yes", function() return T.q ~= nil end) end
    H.idleQ(T, 12000)
    H.pause(500)
    H.step(2, function()
        if T.off then return end
        local lo = H.troughLo(T.tr)
        local loW = lo and lo.water
        local w1 = H.water(T.tr)
        Q.check(T.q ~= nil and w1 < 0.01, T.L .. ": Empty asks, then the game's fluid empty empties the trough", "the question '" .. tostring(T.q) .. "' (the pad's focus on it " .. tostring(T.lq)
            .. "); the trough " .. H.n2(T.w0) .. " -> " .. H.n2(w1) .. " L")
        -- (Nov 26 2026 triage: a NOTE, not a check. In single player no Lua path keeps the system object's water: the
        -- debug add and the game's own ISAddWaterToTrough:complete never write it, and stateToIsoObject leaves the
        -- trough's water alone, so a stale 0 matched the emptied trough and the match proved nothing. The values
        -- before and after are kept; the server proof is the SKIP.)
        H.note(T.L .. ": the trough system's own object reads " .. tostring(T.loW0 and H.n2(T.loW0)) .. " L after the staged fill (the trough " .. H.n2(T.w0)
            .. " L) and " .. tostring(loW and H.n2(loW)) .. " L after the card's Empty (the trough " .. H.n2(w1) .. " L); the game's ISEmptyWaterInTrough sets it to 0 (STG:84-91), the card's generic empty does not: only a server shows the cost")
        if how == "mouse" then
            -- (Nov 26 2026 triage: the old check matched the fluid's name with its capital, so "Empty 20.0 L of water?"
            -- failed in English, where a lowercase common noun is right; the lowercasing is wrong only where nouns keep
            -- a capital: a NOTE, as FA11's German capitals)
            Q.check(H.has(H.low(tostring(T.q)), H.low(T.fname)), "TG9: the Empty question names the fluid the game names ('" .. T.fname .. "')", tostring(T.q))
            H.note("TG9: the question writes the fluid's name lowercased ('" .. tostring(T.q) .. "' for the game's '" .. T.fname .. "'): right in English, wrong where nouns keep a capital (this run is in " .. H.lang() .. ")")
            H.note("TG9: the question and the body write the liters with 'L' in the number (string.format \"%.1f L\"): '" .. tostring(T.q) .. "'")
            Q.skip("TG6 on a server", "multiplayer: the server and the other clients reading 0 after the card's Empty need a server")
        end
    end)
    H.caseEnd(T.L)
end
function C.tg7(how)
    local T = { L = "TG7 the card after a pour (" .. how .. ")" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.troughHere(T) then return end
        T.bottle = H.give("Base.WaterBottle")
        H.fill(T.bottle, Fluid.Water)
        if how == "pad" then H.padOn(); H.park(true) end
    end)
    H.cardQ(T, "trough", function() H.openTrough(T.tr) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.row = H.pourRow(T, T.bottle)
        if T.row and how == "mouse" then H.click("trough:pour:" .. T.row, T.L) end
    end)
    if how == "pad" then H.padPress(T, function() return "trough:pour:" .. tostring(T.row) end, function() return T.row ~= nil end) end
    H.pause(600)
    H.step(1, function()
        if T.off then return end
        T.k1 = H.kind()
        if T.k1 == "fluid" and how == "mouse" then H.click("oc:verb:pour", T.L) end
    end)
    if how == "pad" then H.padPress(T, "oc:verb:pour", function() return T.k1 == "fluid" end) end
    H.idleQ(T, 12000)
    H.pause(900)
    H.step(2, function()
        if T.off then return end
        T.k2 = H.kind()
        Q.check(T.k2 == "trough", T.L .. ": after the pour the trough card is back (to read the level)", "the Transfer row " .. tostring(T.row) .. " opened the " .. tostring(T.k1)
            .. " card; after the pour the card is " .. tostring(T.k2) .. "; the trough holds " .. H.n2(H.water(T.tr)) .. " L")
    end)
    H.caseEnd(T.L)
end
function C.tg8()
    local T = { L = "TG8 small screens (the trough card)" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.troughHere(T) then return end
        pcall(ISFeedingTroughMenu.onAddWaterDebug, S.p, T.tr, Fluid.Water)
    end)
    H.cardQ(T, "trough", function() H.openTrough(T.tr) end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        C.measure(T, "TG8 the trough card at " .. H.sizeTag())
        H.sizeSet("large")
    end)
    H.pause(1500)
    H.step(1, function() if not T.off and not H.live() then H.zcall(function() H.openTrough(T.tr) end) end end)
    H.pause(900)
    H.step(1, function() if not T.off then C.measure(T, "TG8 the trough card at " .. H.sizeTag() .. ", Large text") end end)
    H.caseEnd(T.L)
end

-- ===================================================================== the hutch cases
-- (inside a step) a hen house on the yard, he on its entry square
function H.hutchHere(T)
    T.h = H.mkHutch(H.ysq(3, -3))
    if not T.h then T.off = true; Q.check(false, T.L .. ": a hen house staged (IsoHutch.new, the game's hen house)"); return false end
    T.entry = nil
    pcall(function() T.entry = T.h:getEntrySq() end)
    if T.entry then H.goTo(T.entry:getX() + 0.5, T.entry:getY() + 0.5, 0) else H.atYard(3, -1) end
    return true
end
function H.henIn(h, k)
    local a = H.spawnAnimal("hen", 0, 0)
    if a then pcall(function() a:getData():setPreferredHutchPosition(k or 0); h:addAnimalInside(a) end) end
    return a
end
function H.sum(t) local n = 0; for _, v in ipairs(t or {}) do n = n + (v or 0) end; return n end
function C.hu1(how)
    local T = { L = (how == "mouse") and "HU1 Grab eggs, the pointer off the window (mouse)" or "HU1 Grab eggs, the window down (pad)" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.hutchHere(T) then return end
        pcall(function() T.h:toggleEggHatchDoor() end)
        T.n = H.boxes(T.h)
        for b = 0, T.n - 1 do H.addEggs(T.h, b, 2) end
        T.e0 = H.eggsAll(T.h)
        if how == "pad" then H.padOn(); H.park(true) end
    end)
    H.cardQ(T, "hutch", function() H.openHutch(T.h) end)
    H.pause(500)
    if how == "mouse" then H.shot("oca_hutch_" .. H.sizeTag(), "the hutch card, the hatch open, " .. "eggs in every box", function() return H.kind() == "hutch" and H.live() end) end
    H.step(1, function()
        if T.off then return end
        if how == "mouse" then
            H.click("oc:verb:eggs", T.L)
            S.holdOn = false
            H.holdLetGo()
            H.park(true)
            local w = RT.ww()
            T.pinned = w and w.pinned
        end
    end)
    if how == "pad" then H.padPress(T, "oc:verb:eggs") end
    if how == "mouse" then
        H.wait(6000, function() local w = RT.ww(); return T.off or (w ~= nil and w.windowShaded == true) end, function(ok)
            if T.off then return end
            T.rolled = ok
            if not ok then
                local w = RT.ww()
                pcall(function() w:setWindowShaded(true) end)
                T.byHand = true
            end
        end)
        H.pause(12000)
        H.step(1, function()
            if T.off then return end
            T.e1 = H.eggsAll(T.h)
            T.drawnRolled = H.live()
            S.holdOn = true
            H.park(false)
            H.hold(RT.ww())
        end)
        H.pause(6000)
        H.step(1, function() if not T.off then T.e2 = H.eggsAll(T.h) end end)
    else
        H.pause(12000)
        H.step(1, function() if not T.off then T.e1 = H.eggsAll(T.h) end end)
    end
    H.step(2, function()
        if T.off then return end
        S.holdOn = true
        local ev = "eggs per box: before " .. H.list(T.e0) .. ", 12 s after Grab eggs " .. H.list(T.e1)
        if how == "mouse" then
            ev = ev .. " (the card drawing then " .. tostring(T.drawnRolled) .. "), 6 s after the window opened again " .. H.list(T.e2)
                .. "; the window rolled up by itself " .. tostring(T.rolled) .. (T.byHand and " (it did not: rolled by hand, as the player's own roll)" or "") .. ", pinned " .. tostring(T.pinned)
        end
        Q.check(H.sum(T.e1) == 0, T.L .. ": Grab eggs takes every free box", ev)
    end)
    H.caseEnd(T.L)
end
function C.hu3()
    local T = { L = "HU3 the hutch with only the card open" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.hutchHere(T) then return end
        H.henIn(T.h, 0)
        H.henIn(T.h, 1)
        pcall(function() T.h:toggleEggHatchDoor() end)
        pcall(function() T.h:setHutchDirt(5) end)
        T.d0 = -1
        pcall(function() T.d0 = T.h:getHutchDirt() end)
        T.e0 = H.sum(H.eggsAll(T.h))
        T.reforce = false
        pcall(function() T.reforce = T.h.reforceUpdate ~= nil end)
    end)
    H.cardQ(T, "hutch", function() H.openHutch(T.h) end)
    H.step(1, function()
        if T.off then return end
        pcall(function() T.hr0 = getGameTime():getWorldAgeHours() end)
        H.speed(3)
    end)
    H.pause(60000)
    H.step(1, function()
        H.speed(1)
        if T.off then return end
        local d1 = -1
        pcall(function() d1 = T.h:getHutchDirt() end)
        local e1 = H.sum(H.eggsAll(T.h))
        local hr = 0
        pcall(function() hr = getGameTime():getWorldAgeHours() - T.hr0 end)
        -- (fix/cards3, Nov 26 2026: the egg count is the game's own IGUI_Hutch_EggsNb)
        local word = getText("IGUI_Hutch_EggsNb", e1)
        local shown = H.drew(word) ~= nil
        Q.check(shown, T.L .. ": the card counts the eggs the game holds after the run", e1 .. " eggs; drawn '" .. word .. "' " .. tostring(shown))
        H.note("HU3: with only the card open for " .. H.n1(hr) .. " game hours: dirt " .. H.n1(T.d0) .. " -> " .. H.n1(d1) .. ", eggs " .. T.e0 .. " -> " .. e1
            .. "; the card never calls the game's reforceUpdate (present on this hutch: " .. tostring(T.reforce) .. "; the game's window calls it on every open, HUI:971-972). A hutch that stopped updating shows over days of play: not provable in one run")
    end)
    H.caseEnd(T.L)
end
function C.hu4(which)
    local T = { L = (which == "full") and "HU4 a hen carried to a full hutch" or "HU4 a hen carried, both doors shut" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.hutchHere(T) then return end
        T.max = 0
        pcall(function() T.max = T.h:getMaxAnimals() end)
        if which == "full" then
            for k = 0, T.max - 1 do H.henIn(T.h, k) end
            pcall(function() T.h:toggleDoor() end)
        end
        T.inside = 0
        pcall(function() T.inside = T.h:getAnimalInside():size() end)
        local ex, ey = S.p:getX(), S.p:getY()
        T.hen = H.spawnAnimal("hen", ex + 1, ey)
        if T.hen then pcall(AnimalContextMenu.onPickupAnimal, T.hen, S.p) end
    end)
    H.wait(8000, function()
        if T.off then return true end
        local it = S.p:getPrimaryHandItem()
        return it ~= nil and instanceof(it, "AnimalInventoryItem") and not H.doing() and H.qlen() == 0
    end, function(ok)
        if T.off then return end
        if not ok then H.qstop(); T.off = true; Q.check(false, T.L .. ": the game's pick-up puts a hen in his hands", "in hand " .. H.nm(S.p:getPrimaryHandItem())); return end
        T.canPut = "?"
        pcall(function() T.canPut = tostring(S.p:getPrimaryHandItem():getAnimal():canBePutInHutch(T.h)) end)
    end)
    H.cardQ(T, "hutch", function() H.openHutch(T.h) end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        -- (the foot band, Nov 26 2026: a greyed verb may draw with no stop; the card's verb list says it is there)
        T.putin = H.zone("oc:verb:putin") ~= nil or string.find(H.verbIds(), "putin", 1, true) ~= nil
        T.putinLit = H.lit("oc:verb:putin")
        T.folded = H.zone("oc:hv:putin") ~= nil
        local full = H.txt("IGUI_PutAnimalInHutch_HutchFull", "Hutch full")
        local shut = H.txt("IGUI_PutAnimalInHutch_DoorsClosed", "Doors closed")
        T.reason = H.drewLow(full) ~= nil or H.drewLow(shut) ~= nil
        for _, l in ipairs(S.needs or {}) do if H.has(H.low(l), H.low(H.tr("UI_ZeD_Hutch_PutIn"))) then T.reason = true end end
        -- (the game's words in a NEEDS line, Build's fix/cards3: "Hutch is full." / the doors closed words)
        for _, l in ipairs(S.needs or {}) do if H.has(H.low(l), H.low(full)) or H.has(H.low(l), H.low(shut)) then T.reason = true end end
        local shutNow = "?"
        pcall(function() shutNow = tostring(T.h:isAllDoorClosed()) end)
        local ev = "Put in in the verb row " .. tostring(T.putin) .. " (lit " .. tostring(T.putinLit) .. "), in the folded row " .. tostring(T.folded) .. ", a reason drawn " .. tostring(T.reason)
            .. "; the hutch " .. tostring(T.inside) .. "/" .. tostring(T.max) .. ", doors shut " .. shutNow .. ", the game's canBePutInHutch " .. tostring(T.canPut)
            .. "; verbs " .. H.verbIds()
        if which == "full" then
            Q.check(T.putin or T.reason, T.L .. ": the card shows why a carried hen cannot go in (the game greys Put in: Hutch full)", ev)
        else
            Q.check(T.putin, T.L .. ": Put in shows, greyed, with both doors shut, not folded away (the game greys it: Doors closed)", ev)
        end
    end)
    H.caseEnd(T.L)
end
function C.hu5()
    local T = { L = "HU5 the pad in the hutch card" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.hutchHere(T) then return end
        H.henIn(T.h, 0)
        pcall(function() T.h:toggleEggHatchDoor() end)
        pcall(function() T.h:toggleDoor() end)
        H.addEggs(T.h, 0, 2)
        H.addEggs(T.h, 1, 2)
        H.padOn()
        H.park(true)
    end)
    H.cardQ(T, "hutch", function() H.openHutch(T.h) end)
    H.pause(600)
    H.step(1, function() if not T.off then T.l0 = H.landed() end end)
    H.tapA(function() return not T.off and T.l0 ~= nil and string.sub(tostring(T.l0), 1, 10) == "hutch:box:" end)
    H.idleQ(T, 10000)
    H.pause(700)
    H.step(1, function()
        if T.off then return end
        T.l1 = H.landed()
        local stops = H.stopIds()
        local live = false
        for _, id in ipairs(stops) do if id == T.l1 then live = true end end
        Q.check(T.l1 ~= nil and live and H.ringOnCard(), T.L .. ": after a box's Grab empties it, the pad's focus is on a live stop of the card",
            "opened on " .. tostring(T.l0) .. "; the boxes now " .. H.list(H.eggsAll(T.h)) .. "; the focus " .. tostring(T.l1) .. " (the ring on the card " .. tostring(H.ringOnCard()) .. "); stops " .. H.list(stops, 16))
        T.birdStops = #H.stopIds("hutch:bird:")
        T.bird = nil
        for _, b in ipairs((H.d() and H.d().birds) or {}) do if not T.bird then T.bird = b.i end end
    end)
    H.padPress(T, function() return "hutch:bird:" .. tostring(T.bird) .. ":info" end, function() return T.bird ~= nil end)
    H.pause(900)
    H.step(1, function()
        if T.off then return end
        local w = RT.ww()
        T.at = w and w._activeTab
        T.cardGone = H.e() == nil
    end)
    H.tapB(function() return not T.off and T.bird ~= nil end)
    H.pause(900)
    H.step(1, function()
        if T.off then return end
        local w = RT.ww()
        Q.check(H.kind() == "hutch", T.L .. ": B from a bird's Info comes back to the hutch card", "the Info opened the World tab " .. tostring(T.at) .. " (the card closed " .. tostring(T.cardGone)
            .. "); after B the card is " .. tostring(H.kind()) .. ", the tab " .. tostring(w and w._activeTab))
        H.note("HU5: " .. tostring(T.birdStops) .. " bird stops for one bird (two each: up to 40 for 20 birds before the floor and the verbs)")
        H.atBack()
        H.tabBack()
    end)
    H.caseEnd(T.L)
end
function C.hutchFit(T, label)
    local bad = {}
    for _, b in ipairs(S.btns or {}) do
        if b.fid and string.sub(b.fid, 1, 10) == "hutch:box:" then
            local need = 0
            pcall(function() need = ZeD.Molecules.buttonW(b.label) end)
            if b.w and b.w + 0.5 < need then bad[#bad + 1] = "'" .. b.label .. "' " .. math.floor(b.w) .. " px of " .. math.floor(need) end
        end
    end
    local over = H.overflow()
    local name = H.textsLike(string.sub(S.henName or "Hen", 1, 5), 2)
    H.sizeCheck(#bad == 0, T.L .. " (" .. label .. "): each box's Grab holds its word", H.list(bad, 6))
    H.sizeCheck(#over == 0, T.L .. " (" .. label .. "): no word in the hutch card runs past its edge", H.list(over, 6))
    H.note(T.L .. " (" .. label .. "): the sitting hen's name drawn as " .. name .. " (" .. H.boxes(T.h) .. " boxes)")
end
function C.hu6()
    local T = { L = "HU6 Large text with four boxes" }
    S.henName = "Henrietta Featherstonehaugh the Third"
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.hutchHere(T) then return end
        pcall(function() T.h:toggleEggHatchDoor() end)
        for b = 1, H.boxes(T.h) - 1 do H.addEggs(T.h, b, 3) end
        local hen = H.spawnAnimal("hen", 0, 0)
        if hen then
            pcall(function() hen:setCustomName(S.henName) end)
            pcall(function() T.h:addAnimalInNestBox(hen) end)
            pcall(function() T.h:getNestBox(0):addEgg(instanceItem("Base.Egg")) end)
        end
    end)
    H.cardQ(T, "hutch", function() H.openHutch(T.h) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        C.measure(T, "HU6 the hutch card at " .. H.sizeTag())
        C.hutchFit(T, "the run's text size")
        H.sizeSet("large")
    end)
    H.pause(1400)
    H.step(1, function() if not T.off and not H.live() then H.zcall(function() H.openHutch(T.h) end) end end)
    H.pause(800)
    H.step(1, function() if not T.off then C.hutchFit(T, "Large text") end end)
    H.caseEnd(T.L)
end
function C.hu7()
    local T = { L = "HU7 the words" }
    H.step(2, function()
        local read, missing, seen = H.langKeys({ "UI_ZeD_Hutch_Birds" })
        Q.check(read > 0 and #missing == 0, "HU7: UI_ZeD_Hutch_Birds is in every language the mod ships (the egg count is the game's IGUI_Hutch_EggsNb since fix/cards3)",
            read .. " UI.json files read (" .. H.list(seen, 20) .. "); missing in " .. H.list(missing, 20))
        if not H.caseStart(T, "yard") then return end
        if not H.hutchHere(T) then return end
        pcall(function() T.h:toggleEggHatchDoor() end)
        H.addEggs(T.h, 0, 1)
    end)
    H.cardQ(T, "hutch", function() H.openHutch(T.h) end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        local one = getText("IGUI_Hutch_EggsNb", 1)
        Q.check(not H.drewLow("1 eggs"), T.L .. ": one egg reads in the singular", "the game holds " .. H.sum(H.eggsAll(T.h)) .. " egg; the card drew '" .. one .. "' " .. tostring(H.drew(one) ~= nil)
            .. " (" .. H.textsLike("egg", 4) .. ")")
    end)
    H.caseEnd(T.L)
end
function C.hu8()
    local T = { L = "HU8 the leash from the entry" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.hutchHere(T) then return end
        if not T.entry then T.off = true; Q.check(false, T.L .. ": the hen house has an entry square"); return end
    end)
    H.cardQ(T, "hutch", function() H.openHutch(T.h) end)
    for _, d in ipairs({ { 5, 1 }, { 5, 3 } }) do
        H.step(1, function()
            if T.off then return end
            H.qstop()
            H.goTo(T.entry:getX() + d[1] + 0.5, T.entry:getY() + d[2] + 0.5, 0)
        end)
        H.pause(1300)
        H.step(1, function()
            if T.off then return end
            local open = H.kind() == "hutch"
            local game = 99
            pcall(function() game = S.p:getCurrentSquare():DistToProper(T.entry) end)
            local zed = H.dist(T.entry)
            Q.check(open == (game <= 5), T.L .. ": the card is open exactly where the game's window stays (it closes past 5 by DistToProper, HUI:738-740)",
                "he stands " .. H.n2(game) .. " from the entry by the game's DistToProper, " .. H.n2(zed) .. " from its middle: the card is " .. (open and "open" or "shut"))
        end)
    end
    H.caseEnd(T.L)
end
-- ===================================================================== the hook cases
-- (inside a step) a butcher hook built on the yard, he on the square north of it (the game's open needs 2 tiles)
function H.hookHere(T, dx)
    local sq = H.ysq(dx or 0, 3)
    local hk, why = H.mkHook(sq)
    if not hk then T.off = true; Q.check(false, T.L .. ": a butcher hook built by the game's build", tostring(why)); return false end
    T.hk = hk
    T.hx, T.hy = sq:getX(), sq:getY()
    H.goTo(T.hx + 0.5, T.hy - 0.5, 0)
    H.perkSet("Butchering", 5)
    return true
end
function H.bare(s) local o = tostring(s or ""); o = (string.gsub(o, ":%s*$", "")); return o end
function H.partValue(key, fb)
    local lab = H.bare(H.txt(key, fb))
    local lt = H.drewExactLow(lab)
    if not lt then return nil, lab, nil end
    local best = nil
    local gather = H.low(H.txt("IGUI_ButcherHook_Gather", "Gather"))
    for _, u in ipairs(H.rowOf(lt, 6)) do
        if u.x > lt.x and H.low(u.s) ~= gather and H.low(u.s) ~= H.low(H.txt("IGUI_ButcherHook_Bleed", "Bleed")) and (best == nil or u.x < best.x) then best = u end
    end
    return best, lab, lt
end
function H.pctTexts() local o = {}; for _, t in ipairs(S.texts or {}) do if string.sub(t.s, -1) == "%" then o[#o + 1] = t.s end end; return table.concat(o, " ") end
function C.hk1(how)
    local T = { L = (how == "mouse") and "HK1 Hang on row 1 then row 2 (mouse)" or "HK1 A A on a carried carcass (pad)" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.hookHere(T, 0) then return end
    end)
    H.step(1, function() if not T.off then T.px, T.py = math.floor(S.p:getX()), math.floor(S.p:getY()) end end)
    H.step(1, function() end)
    H.killQ(T, "b1", "cow", 2, 2)
    if how == "mouse" then
        H.killQ(T, "b2", "cow", -2, 2)
    else
        H.step(1, function()
            if T.off then return end
            -- (beside the body for the game's grab)
            pcall(function() local bs = T.b1:getSquare(); H.goTo(bs:getX() - 0.5, bs:getY() + 0.5, 0) end)
            pcall(function() ISTimedActionQueue.add(ISGrabCorpseAction:new(S.p, T.b1)) end)
        end)
        H.idleQ(T, 10000)
        H.step(1, function()
            if T.off then return end
            T.carried = nil
            for _, it in ipairs(H.all()) do pcall(function() if it:getType() == "CorpseAnimal" and not T.carried then T.carried = it end end) end
            if not T.carried then T.off = true; Q.check(false, T.L .. ": the game's grab puts the dead cow in his hands", "in hand " .. H.nm(S.p:getPrimaryHandItem())); return end
            H.goTo(T.hx + 0.5, T.hy - 0.5, 0)
            H.padOn()
            H.park(true)
        end)
    end
    H.step(1, function()
        if T.off then return end
        H.goTo(T.hx + 0.5, T.hy - 0.5, 0)
        T.ground0 = #H.bodiesNear(T.hx, T.hy, 4)
    end)
    H.cardQ(T, "hook", function() H.openHook(T.hk) end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        T.rows = #H.zonesLike("hook:hang:")
        if how == "mouse" then
            H.click("hook:hang:1", T.L)
            H.click("hook:hang:2", T.L)
            T.queued = H.qcount("ISPutAnimalOnHook")
        end
    end)
    if how == "pad" then
        H.padPress(T, "hook:hang:1")
        H.step(3, function() end)
        H.tapA(function() return not T.off and T.focusOk == true end)
        H.step(1, function() T.queued = H.qcount("ISPutAnimalOnHook"); T.kinds = H.qkinds() end)
    end
    H.idleQ(T, 20000)
    H.pause(800)
    H.step(2, function()
        if T.off then return end
        local on = T.hk:getAnimal()
        local orph = 0
        for _, a in ipairs(H.hookAnimals()) do if a ~= on then orph = orph + 1 end end
        local ground = #H.bodiesNear(T.hx, T.hy, 4)
        local carried = 0
        for _, it in ipairs(H.all()) do pcall(function() if it:getType() == "CorpseAnimal" then carried = carried + 1 end end) end
        Q.check((T.queued or 0) <= 1 and orph == 0, T.L .. ": a second Hang while the first is queued puts nothing more up and loses no carcass",
            "the card listed " .. tostring(T.rows) .. " rows; puts queued " .. tostring(T.queued) .. "; after: on the hook " .. tostring(on ~= nil) .. ", bodies on the ground "
            .. ground .. " (" .. tostring(T.ground0) .. " before), carried " .. carried .. ", hook animals not on the hook (orphans) " .. orph)
    end)
    H.caseEnd(T.L)
end
-- queue: a hook with a dead cow hung on it, a knife carried, the card open (the game's way in)
function H.carcassQ(T, dx, pad)
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.hookHere(T, dx or 0) then return end
        T.knife = H.give("Base.HuntingKnife")
    end)
    H.killQ(T, "b1", "cow", (dx or 0) + 2, 2)
    H.step(1, function()
        if T.off then return end
        if not H.hang(T.hk, T.b1) then T.off = true; Q.check(false, T.L .. ": the dead cow hung by the game's own code (ButcheringUtil.onAddedCorpseOnHook)"); return end
        T.blood0 = H.blood(T.hk)
        H.goTo(T.hx + 0.5, T.hy - 0.5, 0)
        if pad then H.padOn(); H.park(true) end
    end)
end
function C.hk2()
    local T = { L = "HK2 Bleed onto the ground (pad)", samples = {} }
    H.carcassQ(T, 0, true)
    H.cardQ(T, "hook", function() H.openHook(T.hk) end)
    H.pause(600)
    H.shot("oca_hook_" .. H.sizeTag(), "the hook card with a dead cow on the hook", function() return H.kind() == "hook" and H.live() end)
    H.step(1, function() if not T.off then H.park(true) end end)
    H.padPress(T, "hook:blood")
    H.step(2, function() if not T.off then H.speed(3) end end)
    for k = 1, 10 do
        H.pause(2500)
        H.step(1, function()
            if T.off then return end
            local prog, bleeding = -1, false
            pcall(function() prog = T.hk:getRemovingBloodProgress() end)
            pcall(function() bleeding = T.hk:isRemovingBlood() end)
            local v = H.partValue("IGUI_ButcherHook_Blood", "Blood:")
            T.samples[#T.samples + 1] = { prog = prog, blood = H.blood(T.hk), pct = H.pctTexts(), lit = v and v.s or "?", bleeding = bleeding }
        end)
    end
    H.step(2, function()
        H.speed(1)
        if T.off then return end
        local gameMoved, cardMoved, words = false, false, {}
        local first = T.samples[1]
        for _, s in ipairs(T.samples) do
            if first and (math.abs((s.prog or 0) - (first.prog or 0)) > 0.02 or math.abs((s.blood or 0) - (first.blood or 0)) > 0.01) then gameMoved = true end
            if first and (s.pct ~= first.pct or s.lit ~= first.lit) then cardMoved = true end
            words[#words + 1] = string.format("game %s %d%% %s L / card '%s' '%s'", tostring(s.bleeding), math.floor((s.prog or 0) * 100 + 0.5), H.n2(s.blood), s.pct, s.lit)
        end
        Q.check(not gameMoved or cardMoved, T.L .. ": while the game bleeds the carcass onto the ground, the card's band and Blood row follow it",
            "the blood before " .. H.n2(T.blood0) .. " L; every 2.5 s at speed 3: " .. H.list(words, 10))
        H.qstop()
    end)
    H.caseEnd(T.L)
end
function C.hk3()
    local T = { L = "HK3 the bridge after > and < while bleeding (mouse)" }
    H.carcassQ(T, 0, false)
    H.step(1, function()
        if T.off then return end
        local sq2 = H.ysq(3, 3)
        local hk2, why = H.mkHook(sq2)
        if not hk2 then T.off = true; Q.check(false, T.L .. ": a second hook built beside the first", tostring(why)); return end
        T.hk2 = hk2
        -- (the carcass's blood set low, the game's own field, so the game's bleed ends inside the run)
        pcall(function() T.hk:getAnimal():getModData()["BloodQty"] = 1.0 end)
        H.goTo(T.hx + 1.5, T.hy - 0.5, 0)
    end)
    H.cardQ(T, "hook", function() H.openHook(T.hk) end)
    H.pause(500)
    H.step(1, function() if not T.off then H.click("hook:blood", T.L) end end)
    H.pause(1500)
    H.step(1, function()
        if T.off then return end
        pcall(function() T.bleed0 = T.hk:isRemovingBlood() end)
        H.click("oc:next", T.L)
    end)
    H.pause(1200)
    H.step(1, function()
        if T.off then return end
        T.onB = H.t() and H.t().obj == T.hk2
        H.click("oc:prev", T.L)
    end)
    H.pause(1000)
    H.step(1, function()
        if T.off then return end
        T.onA = H.t() and H.t().obj == T.hk
        H.speed(4)
    end)
    H.wait(90000, function()
        if T.off then return true end
        local b = true
        pcall(function() b = T.hk:isRemovingBlood() end)
        return not b
    end, function(ok)
        H.speed(1)
        if T.off then return end
        T.ended = ok
    end)
    H.settle(1200)
    H.step(1, function()
        if T.off then return end
        local d = H.d()
        T.removeLit = H.lit("oc:verb:remove")
        Q.check(T.removeLit or not T.ended, T.L .. ": after the game's bleed ends, the card is not left busy (Remove corpse lit)",
            "bleeding after Bleed " .. tostring(T.bleed0) .. ", > showed the second hook " .. tostring(T.onB) .. ", < came back " .. tostring(T.onA) .. "; the game's bleed ended "
            .. tostring(T.ended) .. " (blood " .. H.n2(H.blood(T.hk)) .. " L); Remove lit " .. tostring(T.removeLit) .. ", the card busy " .. tostring(d and d.busy))
        Q.skip("HK3 split screen", "two cards on one hook need a second local player (split screen), which a script cannot add")
    end)
    H.caseEnd(T.L)
end
function C.hk4()
    local T = { L = "HK4 the pad from the Animals tab's hook row" }
    H.carcassQ(T, 0, true)
    H.cardQ(T, "hook", function() ZeD.AnimalsTab.openStruct("hook", T.hk, S.pn) end)
    H.pause(700)
    H.step(1, function()
        if T.off then return end
        T.landed = H.landed()
        T.main = H.mainFid()
        T.onCard = H.ringOnCard()
    end)
    H.tapA(function() return not T.off and T.landed ~= nil end)
    H.step(1, function() if not T.off then T.kinds = H.qkinds() end end)
    H.idleQ(T, 12000)
    H.step(2, function()
        if T.off then return end
        local on = T.hk:getAnimal() ~= nil
        Q.check(on, T.L .. ": the pad's A on the card's opening focus does not take the carcass down",
            "opened on " .. tostring(T.landed) .. " (the main stop " .. tostring(T.main) .. ", the ring on the card " .. tostring(T.onCard) .. "); A queued " .. tostring(T.kinds)
            .. "; the hook holds the carcass after " .. tostring(on) .. " (the game's pad starts on the parts, Remove on X: BHU:72-78)")
    end)
    H.caseEnd(T.L)
end
function C.hk5(how)
    local T = { L = (how == "mouse") and "HK5 Meat with blood still in (mouse)" or "HK5 Head with blood still in (pad)" }
    T.fid = (how == "mouse") and "hook:meat" or "hook:head"
    H.carcassQ(T, 0, how == "pad")
    H.cardQ(T, "hook", function() H.openHook(T.hk) end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        T.b0 = H.blood(T.hk)
        T.warn = H.drewLow(H.n2(T.b0 or 0)) ~= nil
        if how == "mouse" then H.click(T.fid, T.L) end
    end)
    if how == "pad" then H.padPress(T, T.fid) end
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.asked = H.confirm() ~= nil
        T.q = H.confirm() and H.confirm().text
        if T.asked then local c = H.card(); if c then c._confirm = nil end end
    end)
    H.idleQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        local b1 = H.blood(T.hk)
        -- (Nov 26 2026 triage: game parity, a NOTE. ISButcherHookUI:onRemoveMeat and onRemoveHead queue the action at
        -- once with blood still in, and the action spills it (RMA:105-110))
        H.note(T.L .. ": taking it with blood still in " .. ((T.asked or (T.b0 or 0) <= 0) and "asks first, or no blood was left" or "asks nothing")
            .. "; the game's own Meat and Head buttons ask nothing either (game parity) | the blood " .. H.n2(T.b0) .. " L before (the liters shown on the card " .. tostring(T.warn) .. "), "
            .. tostring(b1 and H.n2(b1) or "no carcass") .. " after; a question " .. tostring(T.q))
    end)
    H.caseEnd(T.L)
end
function C.hk6(how)
    local T = { L = "HK6 a part the animal never had (" .. how .. ")" }
    H.carcassQ(T, 0, how == "pad")
    H.step(1, function()
        if T.off then return end
        -- a hook animal's breed with no leather, if this game has one; else the game's own false set on the cow (as
        -- setAnimalBodyData writes it for a breed with none)
        T.breedNone = nil
        pcall(function()
            for name, d in pairs(AnimalPartsDefinitions.animals) do
                if type(d) == "table" and d.leather == nil and not T.breedNone then T.breedNone = name end
            end
        end)
        local md = H.md(T.hk)
        if md then md["leather"] = false end
        pcall(function() T.hk:getAnimal():transmitModData() end)
        T.leather = md and md["leather"]
    end)
    H.cardQ(T, "hook", function() H.openHook(T.hk) end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        local v, lab = H.partValue("IGUI_ButcherHook_Leather", "Leather:")
        T.word = v and v.s or "?"
        T.lab = lab
        T.lit = H.lit("hook:leather")
        T.n0 = 0
        for _, it in ipairs(H.all()) do if H.has(H.ft(it), "Leather") then T.n0 = T.n0 + 1 end end
        if how == "mouse" and T.lit then H.click("hook:leather", T.L) end
    end)
    if how == "pad" then H.padPress(T, "hook:leather", function() return T.lit == true end) end
    H.step(1, function() if not T.off then T.kinds = H.qkinds() end end)
    H.idleQ(T, 12000)
    H.step(2, function()
        if T.off then return end
        local n1 = 0
        for _, it in ipairs(H.all()) do if H.has(H.ft(it), "Leather") then n1 = n1 + 1 end end
        local taken = H.low(T.word) == H.low(H.tr("UI_ZeD_Hook_Taken"))
        Q.check(not (T.lit and taken), T.L .. ": a part the animal never had reads as the game reads it (No) with no Gather",
            "the card's " .. tostring(T.lab) .. " row: '" .. tostring(T.word) .. "', Gather lit " .. tostring(T.lit) .. "; the game's leather " .. tostring(T.leather)
            .. " (a breed with none in this game: " .. tostring(T.breedNone) .. "); the press queued " .. tostring(T.kinds) .. ", leather items " .. T.n0 .. " -> " .. n1)
    end)
    H.caseEnd(T.L)
end
function C.hk7(how)
    local T = { L = "HK7 only a dead hen near (" .. how .. ")" }
    H.step(2, function()
        if not H.caseStart(T, "yard") then return end
        if not H.hookHere(T, 0) then return end
        if how == "pad" then H.padOn(); H.park(true) end
    end)
    H.killQ(T, "b1", "hen", 1, 2)
    H.step(1, function() if not T.off then H.goTo(T.hx + 0.5, T.hy - 0.5, 0) end end)
    H.cardQ(T, "hook", function() H.openHook(T.hk) end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        local md = nil
        pcall(function() md = T.b1:getModData() end)
        local adef = nil
        pcall(function() adef = AnimalAvatarDefinition[md["AnimalType"]] end)
        T.type = md and md["AnimalType"]
        T.size = md and md["animalSize"]
        T.gameOk = (adef ~= nil and adef.hook == true and (T.size or 0) >= 0.4 and not md["skeleton"]) and true or false
        T.addLit = H.lit("oc:verb:add")
        T.rowLit = H.lit("hook:hang:1")
        local row = H.rowTexts(H.zone("hook:hang:1"))
        T.name = row[1] and row[1].s or "?"
        if how == "mouse" and T.addLit then H.click("oc:verb:add", T.L) end
    end)
    if how == "pad" then H.padPress(T, "oc:verb:add", function() return T.addLit == true end) end
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.jump = H.landed()
        if how == "mouse" then local c = H.card(); T.jump = (c and (c._pendingFocus or c._jumpTo)) or T.jump end
    end)
    if how == "pad" then H.tapA(function() return not T.off and T.jump == "hook:hang:1" end) end
    H.step(1, function() if not T.off then T.kinds = H.qkinds() end end)
    H.idleQ(T, 8000)
    H.step(2, function()
        if T.off then return end
        Q.check(not (T.addLit and not T.gameOk), T.L .. ": Add corpse waits when no body in reach can go on the hook (the game's rule)",
            "a dead " .. tostring(T.type) .. " (the game's hook " .. tostring(T.gameOk) .. ", size " .. tostring(T.size) .. "); Add corpse lit " .. tostring(T.addLit) .. ", it went to "
            .. tostring(T.jump) .. ", that row's Hang lit " .. tostring(T.rowLit) .. "; then queued " .. tostring(T.kinds) .. "; on the hook " .. tostring(T.hk:getAnimal() ~= nil))
        if how == "mouse" then
            Q.check(not H.has(T.name, "%1") and not H.has(T.name, "IGUI_"), "HK8: a ground body with no name of its own reads as a name, not a key", "the row: '" .. tostring(T.name) .. "'")
            H.note("HK8: the game passes no name there either (ISButcherHookUI 470-474)")
        end
    end)
    H.caseEnd(T.L)
end
function C.hookFit(T, label)
    local bad = {}
    for _, k in ipairs({ { "IGUI_ButcherHook_Leather", "Leather:" }, { "IGUI_ButcherHook_Blood", "Blood:" }, { "IGUI_ButcherHook_Head", "Head:" }, { "IGUI_ButcherHook_Meat", "Meat:" } }) do
        local v, lab, lt = H.partValue(k[1], k[2])
        if lt and v then
            local right = lt.x + H.textW(lt)
            if right > v.x - 2 then bad[#bad + 1] = "'" .. lab .. "' ends at " .. math.floor(right) .. ", '" .. v.s .. "' starts at " .. math.floor(v.x) end
        elseif not lt then bad[#bad + 1] = "'" .. lab .. "' not drawn"
        end
    end
    Q.check(#bad == 0, T.L .. " (" .. label .. "): each part's label ends before its value", H.list(bad, 4))
end
function C.hk9()
    local T = { L = "HK9 the part rows and the card's size" }
    H.carcassQ(T, 0, false)
    H.cardQ(T, "hook", function() H.openHook(T.hk) end)
    H.pause(600)
    H.step(1, function()
        if T.off then return end
        C.measure(T, "HK9 the hook card at " .. H.sizeTag())
        C.hookFit(T, "the run's text size")
        local bl = H.blood(T.hk) or 0
        local want = string.format("%.2f L", bl)
        Q.check(H.drew(want) ~= nil, "HK11: the card's Blood row reads the game's BloodQty", "the game " .. H.n2(bl) .. "; drawn: " .. H.textsLike(" L", 4))
        H.note("HK11: the card writes the blood \"%.2f L\", the Animals tab's hook row \"%.1f\" (AnimalsTab.lua 2004) for the same carcass: " .. want .. " against " .. string.format("%.1f", bl))
        H.sizeSet("large")
    end)
    H.pause(1500)
    H.step(1, function() if not T.off and not H.live() then H.zcall(function() H.openHook(T.hk) end) end end)
    H.pause(900)
    H.step(1, function() if not T.off then C.hookFit(T, "Large text") end end)
    H.caseEnd(T.L)
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
    H.cursorOff()
    H.close()
    H.hiddenBack()
    H.sizeBack()
    H.wrapOff()
    S.worldN = H.worldBack()
    for _, it in ipairs(S.made) do H.removeItem(it) end
    H.recipesBack()
    S.xpGrew, S.xpLeft = H.xpBack()
    if S.back.seasons then
        S.back.seasons = nil
        pcall(function() getSandboxOptions():getOptionByName("PlantGrowingSeasons"):setValue(f.seasons) end)
    end
    ISFarmingMenu.cheat = f.fmCheat
    if f.recorded then
        pcall(function() S.p:setTimedActionInstantCheat(f.inst and true or false) end)
        pcall(function() S.p:setBuildCheat(f.buildCheat and true or false) end)
        pcall(function() if f.tod then getGameTime():setTimeOfDay(f.tod) end end)
    end
    H.bodyBack()
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        H.putBack()
        H.home()
    end)
    -- (the UI scale back first: the windows reopen there)
    Q.step(2, function() H.scaleBack() end)
    Q.waitFor(5, 900, function() return H.scaleSettled() end, function() end)
    Q.waitMs(800)
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
        H.worldBack()
        H.hands()
        H.home()
        RT.pairOpen()
        if f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "oca_tab") end
        local w = RT.ww()
        if w then w._maxWinW = f.maxW end
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then return end
        H.atBack()
        pcall(ZeD_CharacterWindow.openTab, S.pn, f.ctab or "loot")
        H.tabBack()
        S.holdOn = false
        H.holdLetGo()
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        local left = H.leftovers()
        Q.check(#left == 0, "put back: every plot, plant, trough, hen house, hook, animal, body and zone the run made is gone",
            H.list(left, 10) .. " (taken away: " .. (S.worldN and ("plots " .. S.worldN.plots .. ", troughs " .. S.worldN.troughs .. ", hen houses " .. S.worldN.hutches .. ", built "
                .. S.worldN.built .. ", animals " .. S.worldN.animals .. ", bodies " .. S.worldN.bodies .. ", zones " .. S.worldN.zones .. ", things on the ground " .. S.worldN.floor) or "?") .. ")")
        local gone = {}
        for _, it in ipairs(S.made) do if not H.gone(it) then gone[#gone + 1] = H.ft(it) end end
        Q.check(#gone == 0, "put back: every thing the run gave is gone", #S.made .. " given; left " .. H.list(gone, 8))
        local extra = {}
        for _, it in ipairs(H.all()) do if not f.inv0[it] then extra[#extra + 1] = H.ft(it) end end
        Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (nothing made left, his set-aside things back)",
            "new " .. H.list(extra, 8) .. "; " .. tostring(S.swept) .. " swept, " .. tostring(S.refilled) .. " of his own used things given again, " .. tostring(S.lost) .. " set-aside things not given back")
        local lvlLeft = 0
        pcall(function() for _, r in ipairs(S.xp) do if S.p:getPerkLevel(r.perk) ~= r.lvl then lvlLeft = lvlLeft + 1 end end end)
        if S.xpLeftText then H.note("put back: XP drift left (levels checked): " .. S.xpLeftText) end
        Q.check(lvlLeft == 0 and H.perkLvl("Farming") == f.farming and H.perkLvl("Butchering") == f.butcher and H.perkLvl("Husbandry") == f.husb,
            "put back: Farming, Butchering, Animal Care and every other skill level as found",
            tostring(S.xpGrew) .. " skills changed, " .. lvlLeft .. " not at their level; Farming " .. H.perkLvl("Farming") .. " (" .. tostring(f.farming) .. "), Butchering "
            .. H.perkLvl("Butchering") .. " (" .. tostring(f.butcher) .. "), Animal Care " .. H.perkLvl("Husbandry") .. " (" .. tostring(f.husb) .. ")")
        local seasons = nil
        pcall(function() seasons = getSandboxOptions():getOptionByName("PlantGrowingSeasons"):getValue() end)
        Q.check(#S.recipesOff == 0 and seasons == f.seasons, "put back: the season recipes and the sandbox's PlantGrowingSeasons as found", "seasons " .. tostring(seasons) .. " (" .. tostring(f.seasons) .. ")")
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and H.qlen() == 0 and getGameSpeed() == 1,
            "put back: he stands where he stood, no action queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
        local w = RT.ww()
        Q.check(ZeD.currentBase == f.base and ZeD.currentSize == f.size and H.lockFound() == (S.lockWas or H.lockFound()) and S.parked == nil and S.w0 == nil and H.wrapped()
            and H.optVal(ZeD.Settings and ZeD.Settings.hiddenActionsOption) == f.hiddenIdx and H.optVal(ZeD.Settings and ZeD.Settings.uiScaleOption) == f.scaleIdx
            and (w == nil or w._activeTab == (f.wtab or "loot")) and H.e() == nil,
            "put back: the theme, the text size, the UI scale, the hidden-actions setting, the input lock, the pointer, the draw watchers, the World window's tab and its card as found",
            tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", scale " .. tostring(H.optVal(ZeD.Settings and ZeD.Settings.uiScaleOption)) .. ", hidden " .. H.hiddenNow()
            .. ", lock " .. H.lockFound() .. ", tab " .. tostring(w and w._activeTab) .. " (" .. tostring(f.wtab) .. "), a card open " .. tostring(H.e() ~= nil))
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught" .. (S.zerr and (": " .. S.zerr) or ""))
        if S.cardErrs then Q.check(false, "the object card drew without an error", S.cardErrs .. " times; last " .. tostring(S.cardErrLast)) end
        local e1 = H.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the run ran with no Lua error", (e1 - S.err0) .. " new")
        else H.note("the game's Lua error count cannot be read here") end
        H.note("FA13 is test drift (zedqa_cov_farmcards 1104 expects the tag Parched on a living plant, which ObjectCardFarm 349-351 no longer draws; its comment at 70-74 expects the < wrap to fail, fixed in ObjectCards 313; FEATURE_MAP 366 cites InfoCards 59-62 for IC 80-85): no in-game case")
        H.note("TG10, HU9, HK12 are test drift (FEATURE_MAP 367, 368 and 369 read not yet; zedqa_cov_farmcards is in no run list; no script before this one opens the hook card): no in-game case")
        H.note("pictures: " .. H.list(S.shots, 8))
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
        S.guard = false
        pcall(function() Events.OnTick.Remove(H.keepTick) end)
        if f.recorded then
            pcall(function() if f.invinc ~= nil then S.p:setInvincible(f.invinc) end end)
            pcall(function() if f.god ~= nil then S.p:setGodMod(f.god) end end)
        end
    end)
end

-- ===================================================================== the run
S.setup()
C.fa1("mouse")
C.fa1("pad")
C.fa1("third")
C.fa2()
C.fa3()
C.fa4("mouse")
C.fa4("pad")
C.fa5()
C.fa6("dead")
C.fa6("compost")
C.fa7none()
C.fa7heavy()
C.fa8("mouse")
C.fa8("pad")
C.fa9("mouse")
C.fa9("pad")
C.fa11()
C.fa12field()
C.fa12shovel()
C.tg1("mouse")
C.tg1("pad")
C.tg2()
C.tg3("mouse")
C.tg3("pad")
C.tg4()
C.tg5("mouse")
C.tg5("pad")
C.tg6("mouse")
C.tg6("pad")
C.tg7("mouse")
C.tg7("pad")
C.tg8()
C.hu1("mouse")
C.hu1("pad")
H.step(1, function() Q.skip("HU2 the egg chain on a server", "multiplayer: the server's animEvent and hutch:sync timing need a server and a client") end)
C.hu3()
C.hu4("full")
C.hu4("shut")
C.hu5()
C.hu6()
C.hu7()
C.hu8()
C.hk1("mouse")
C.hk1("pad")
C.hk2()
C.hk3()
C.hk4()
C.hk5("mouse")
C.hk5("pad")
C.hk6("mouse")
C.hk6("pad")
C.hk7("mouse")
C.hk7("pad")
C.hk9()
H.step(1, function() Q.skip("HK10 In use and the last part on a server", "multiplayer: the using player is set only on the server, and another player's last part needs a second client") end)
C.fa10()
S.buildPutBack()
Q.start()
