-- ZeDUI/tools/qa/vk1_pad.lua  (Nov 22 2026, QA batch K1; tag vk1_pad): the in-game proof of Build's fixes for the
-- controller half of the KISS audit's plain bugs: K1-1, K1-3, K1-4, K1-5 (commit e25f4ca68) and K1-8 (commit
-- 7fb4f1f97). Findings: ZeDUI/qa/audits/2026-11-22_kiss_bugs_K1.md. The old code is 2488ceead (0.3.0-beta21c), the
-- new 0ebd56570. Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua (its ZEDQA_CAR_* helpers place the
-- car). grep "ZEDQA vk1_pad". Manifest (QA writes vk1.txt): vk1_pad.lua | vk1_pad | timeout=300
--
-- No controller is plugged in. The pad is driven through the game's own handlers, as rt_pad.lua and
-- zedqa_quick_chords.lua drive it: JoypadControllerData:onPressButtonNoFocus and :onReleaseButton with a stand-in pad
-- (player 0, id 0, no focus), the bumper held through ZeD's own hook (ZeD.QuickChords.qaBumper). A chord is the pad's
-- order of presses: the bumper down, the face button down and up, the bumper up. Which chord runs an action is read
-- from ZeD_chords.txt (QuickChords.chordFor: RB + A Medicine, RB + B Weapons, LB + A Eat, LB + B Drink by default).
-- ZeD's input lock is NOT set: nothing these checks drive reads ZeD's input mode (the chords, the D-pad Left lists,
-- the game's RB release, the strip's place), and a lock to the controller opens the pair and hands the pad to a
-- window a frame later (vx12_wheel.lua), which makes QuickChords refuse every chord. A window found holding the pad
-- is let go for the run and given it back after.
--
-- SAFETY. Nothing is eaten, drunk, taken, treated, equipped, reloaded or read: while a chord or a list line is
-- pressed, the game's ISTimedActionQueue.add (and addAfter) is stood in for by a recorder that keeps the action and
-- queues nothing (nothing begins), and ISInventoryPaneContextMenu.OnNewCraft (a can's opening recipe) only records.
-- HaloTextHelper.addBadText is watched (passed through) for the words said over his head. All are put back in the
-- same call and checked at the end. Every wound is staged and healed inside ONE step (one Lua call: the game never
-- updates the body in between, so god mode's heal, bleeding and infection never run on it): a laceration with no
-- infection (BodyPart.setCut(true, true)), bleeding, glass, a clean bandage. No bite, no scratch, nothing infects.
--
-- What each check reads, and what the old code (2488ceead) does there. Every check marked "old FAIL" passes on the
-- new code (0ebd56570); "guard" lines pass on both and prove the staging worked.
--
-- K1-1, the Medicine chord (RB + A) and the Medicine list (D-pad Left > Medicine), one step. Precondition: no body
-- part wants care (no injury, bandage, stitch or splint: god mode keeps him healed), else the item says SKIP. The
-- health menu's debug cheat entries (ISHealthPanel.cheat, on in -debug) are off for the step, as a player sees it.
-- Given, in this order: a dirty bandage, a clean bandage, alcohol wipes, tweezers and five kinds of pills.
--   Scenario A: a clean bandage alone on the left forearm (only bandaged, no wound), a bleeding laceration with glass
--   in the right shin. The chord's action is read from the recorder: the game's health menu action it starts
--   (HealthPanelAction: its handler's kind and body part).
--     A1 RB + A treats the worst wound first, the shin. Old FAIL: Remove bandage on the left forearm (the first part
--        in the body's index order that offers anything).
--     A2 RB + A never takes off the clean bandage of a part that is only bandaged. Old FAIL: Remove bandage.
--   The Medicine list as D-pad Left > Medicine builds it (the Character wheel's own builder and the slice's sub, what
--   the wheel draws; a line with no key is a treatment, a line keyed by an item type is a thing carried, "health" is
--   the Health tab line):
--     C1 every treatment comes before any pills. Needs pills on him (P > 0, the five given), else SKIP: with none the
--        old list passes too. Old FAIL: the pills first.
--     C2 the cut at ten drops pills, not treatments: the list holds min(T, 10) treatments (T: every treatment the
--        wounds have, D.H.treatments). Needs T + P > 10 (P: kinds of pills), else SKIP. Old FAIL: 10 - P treatments.
--     C3 the first treatment is the worst wound's (the shin), as the Health tab orders parts. Old FAIL: the forearm's
--        Remove bandage (body order).
--   Scenario B: the forearm healed again, the shin's laceration with glass alone; each press read, then the state the
--   game's own treatment leaves (the glass out: setHaveGlass(false); disinfected: setAlcoholLevel(4)).
--     B1 RB + A takes the glass out first (HRemoveGlass). Old FAIL: Bandage (the game's menu lists Bandage before
--        Disinfect and Remove glass, and the old pick took the menu's first).
--     B2 the glass out: RB + A disinfects (HDisinfect). Old FAIL: Bandage.
--     B3 disinfected: RB + A puts on a clean bandage, not a dirty one. Runs only when the game lists a dirty bandage
--        first (the first item with bandage power in ISInventoryPaneContextMenu.getContainers' order, as its health
--        menu finds them): his own clean bandages in his main inventory come before the ones given, and then the old
--        pick is clean too (SKIP, said). Old FAIL: the dirty bandage.
-- K1-3, quick Eat and Drink, one step each.
--   Eat: a raw egg (Base.Egg, the game's DangerousUncooked) given, aged to a moment before it rots. SKIP when he is
--   too full to eat (the game's Well fed 3: the Eat list is empty in both).
--     E1 no line of the Eat list (D-pad Left > Eat) eats raw food that needs cooking: every line of a kind of raw
--        dangerous food he carries is pressed (recorded) and what it would eat read. Old FAIL: the egg's line eats
--        the raw egg (the new list has no such line, or its line eats a cooked one).
--     E2 LB + A (quick Eat) never eats raw food that needs cooking. Runs only when the egg spoils sooner than any other
--        food he carries (the old pick is whatever spoils soonest), else SKIP with that food named. Old FAIL: the
--        raw egg.
--   Drink: two kinds of bottle he does not carry (K and K2). K: a bottle of tainted water given FIRST, then one of
--   clean water; K2: water with bleach in it. "Known tainted" is the game's FluidContainer:isTaintedStatusKnown()
--   (bleach always; tainted water while the sandbox's tainted water text is on). SKIP when the given tainted bottle
--   is not known tainted.
--     Da no line of the Drink list (D-pad Left > Drink) drinks known-tainted water or water with bleach: every line
--        of a kind with a known-tainted item on him is pressed (recorded). Old FAIL: K's line drinks the tainted
--        bottle (it folds into the clean one), K2's line drinks the bleach water.
--     Db the clean and the tainted bottle of K do not fold into one line: K's line counts one bottle (no "(2)") and
--        drinks the clean one. Old FAIL: "(2)", and it drinks the tainted bottle.
--     Dc LB + B (quick Drink) never drinks known-tainted fluid. Runs only when he carries no other water (then the old
--        pick is K or K2, water first), else SKIP with his water named. Old FAIL: tainted water or bleach water.
-- K1-5, RB + B (the Weapons quick action), one step. A copy of the first weapon kind in his main inventory (the bag's
-- first: the old pick) is given and put in his hand, with a weapon of another kind in good condition; with no weapon
-- on him, a worn hammer (first, held) and an axe. The action read from the recorder.
--     W1 RB + B never puts away the weapon in hand. Old FAIL: ISUnequipAction of the held weapon (the game's
--        ISDPadWheels.onEquipPrimary toggles the one in hand away).
--     W2 RB + B draws the best weapon not in hand: an ISEquipWeaponAction of a weapon that is not the held one, and no
--        other kind on him is in better condition (condition over its most, the game's numbers; a kind read as its
--        wheel line shows it: the copy in a hand, else its best). Old FAIL: no draw at all (the unequip above).
--     W3 with only the held weapon's kind on him (the other one taken back): nothing is done and he says "In your
--        hands" (UI_ZeD_Wheel_InYourHands, over his head). Runs only when he carries no other weapon kind in his main
--        inventory, else SKIP (his weapons are never moved). Old FAIL: ISUnequipAction of the held weapon.
-- K1-4, RB in a chord does not reload the gun in hand, one step. A pistol held (Base.Pistol, emptied: no magazine,
-- no round) and an empty magazine given; the game's RB prompt set by its own rule
-- (ISFirearmRadialMenu.getBestRBButtonAction: RELOAD), as the game sets it each tick on a pad.
--     K4a (guard) RB alone, pressed and let go: the game's release asks for its reload (ISReloadWeaponAction.
--        BeginAutomaticReload: ISInsertMagazine and the like). SKIP of K1-4 when the game offers no RELOAD on RB.
--     K4b RB + A (an RB chord; the Medicine chord by default) with the pistol held: RB let go after the chord asks for
--        no reload. Old FAIL: the reload (ZeD took only the face button; the game still heard RB).
-- K1-8, the hint strip in a car. A pickup truck from the prelude's spots (ZEDQA_CAR_WAIT, as the vehicle scripts
-- place cars), he seated as driver (ZEDQA_CAR_ENTER), then moved to the passenger seat as the game's ISSwitchVehicleSeat
-- does (switchSeat, OnSwitchVehicleSeat). ZeD setup's Hint strip is set to Always and a Moodles row at the bottom to
-- the right for the part (in memory, put back), since moodles at the bottom also lift the strip in the old code. With
-- no pad the strip shows the keyboard's prompts (E Exit vehicle, Right-click More); its place is the same code.
-- Read once the dash and the strip have kept one place for 300 ms:
--     (guard) ZeD's dash is up and the strip shows its prompts, in each seat.
--     K8 driver / passenger: the strip's prompts sit above the dash's top edge (its bottom at or above the dash's
--        top, 1 px), fully on screen. Old FAIL: the strip sits 16u above the screen's bottom, inside the dash.
-- Nothing in pixels is written in but the 1 px tolerance: it runs as it is at 4K (UI scale 1.75) and 1280x800 (Auto).
--
-- What it puts back (also when a step throws or the time runs out): the stand-ins off (checked), the health menu's
-- cheat flag, QuickChords.qaBumper and .lastChord, the game's RB prompt, every thing given taken back, his hands as
-- they were, every staged body part healed to the health, stiffness and pain it had, his stats (hunger, thirst,
-- fatigue, stress, sickness, food sickness, poison, panic, pain) as found, out of the car, the car taken away
-- (ZEDQA_CAR_AWAY), back where he stood, the Hint strip and Moodles settings as found, the pad given back to a window
-- that held it. Checked: alive, no part found clean with a wound or dressing, the staged parts at the health they had,
-- not infected, nothing queued, the windows open or shut on their tabs as found. No option is applied or saved, no file
-- is written, no car found parked is touched.
-- Not covered here (no pad): the bumper zoom (LB + RB) and a long RB hold (the game's firearm wheel) need the buttons
-- really down (JoypadButton.isDown); the claim is dropped three ticks after RB reads up. K1-2 (the item card's Drink
-- and Eat) is not in this script.
-- Run offline before the first game run (Nov 22 2026: KRun, rt_kit.lua and this script in the game's Kahlua with the
-- real ZeD_QuickChords, ZeD_QuickWheel, ZeD_DpadWheels and ZeD_HintStrip of 2488ceead and of 0ebd56570, the game's
-- objects and vanilla's health menu, pad dispatch, firearm release and eat, drink, pill and equip verbs stubbed after
-- their 42.21 source; the harness is not in the repo): 0ebd56570 PASS 40 (B3, Dc and W3 SKIP) with a deep-run
-- inventory and PASS 43 with nothing carried, at 3840x2160 and 1280x800, Moodles at the right and at the bottom;
-- 2488ceead FAIL 16 and FAIL 19, every check marked old FAIL and no other; nothing ever reached the real queue.
-- Review (Nov 22 2026, adversarial pass): C1 now needs pills on him (else the old list passes too); W2 reads each
-- other kind as its wheel line shows it (a worse copy in the other hand stands for its kind, as in the game's list);
-- after every recording the real queue is looked at, and anything that reached it is cleared in the same Lua call
-- (before it can begin) and FAILs the queue put-back check. Checked against the game's 42.21 Lua and classes: the
-- health menu sees only the top containers' own items (ISHealthPanel:checkItems re-reads the parent, never a bag),
-- so S.firstBandage reads as the game's Bandage menu does; tainted water is a water source and "known tainted" needs
-- the sandbox's tainted water text (bleach as the main fluid always); a laceration offers no Stitch (deep wounds
-- only). Same harness after the review: 0ebd56570 PASS 40 / 43, 2488ceead FAIL 16 / 19, 4K and 1280x800.

if not (RT and RT.make) then
    print("ZEDQA vk1_pad ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk1_pad VERDICT FAIL 1")
    print("ZEDQA vk1_pad DONE")
    return
end

local Q = RT.make("vk1_pad")
Q.maxMs = 240000   -- (four minutes, then the put-back; a run takes about one)
local S = { p = RT.p, pn = RT.pn, was = {}, orig = {}, given = {}, TOL = 1 }
S.jd = { player = S.pn, id = 0, focus = nil }
S.MED_THINGS = { "Base.BandageDirty", "Base.Bandage", "Base.AlcoholWipes", "Base.Tweezers", "Base.Pills", "Base.PillsBeta",
                 "Base.PillsAntiDep", "Base.PillsSleepingTablets", "Base.PillsVitamins" }
S.BOTTLES = { "Base.Sportsbottle", "Base.Canteen", "Base.CanteenMilitary", "Base.BottleCrafted", "Base.CanteenCowboy",
              "Base.Flask", "Base.WaterBottle", "Base.PopBottle" }
S.OTHER_WEAPONS = { "Base.Crowbar", "Base.BaseballBat", "Base.Axe", "Base.Hammer", "Base.KitchenKnife" }
S.STATS = { "HUNGER", "THIRST", "FATIGUE", "STRESS", "SICKNESS", "FOOD_SICKNESS", "POISON", "PANIC", "PAIN" }

-- ===================================================================== words and numbers
function S.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
function S.join(t)
    if t == nil or #t == 0 then return "none" end
    return table.concat(t, "; ")
end
function S.itemName(it)
    if it == nil then return "nothing" end
    if not instanceof(it, "InventoryItem") then return tostring(it) end
    return tostring(it:getDisplayName()) .. " (" .. tostring(it:getFullType()) .. ")"
end
function S.partName(bp)
    if bp == nil then return "no part" end
    return tostring(BodyPartType.getDisplayName(bp:getType()))
end
function S.exists(ft)
    local sm = getScriptManager()
    return sm ~= nil and sm:FindItem(ft) ~= nil
end
-- a line's count, from its name ("Water Bottle (2)": 2; no count: 1)
function S.count(name)
    local n = tostring(name or ""):match("%((%d+)%)$")
    return n and tonumber(n) or 1
end
function S.optGet(o)
    if o and o.getValue then return o:getValue() end
    return nil
end
function S.optSet(o, v)
    if o and o.setValue and v ~= nil then o:setValue(v) end
end

-- ===================================================================== waits (vx12_wheel.lua)
-- until cond() holds (asked every drawn frame; it never throws), for at most ms of real time; then fn(ok)
function S.waitUntil(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if cond() then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end

-- ===================================================================== what he carries
-- ZeD's own walk (ZeD_QuickWheel carried()): the main inventory and the bags in it, two deep
function S.carried()
    local out = {}
    local function scan(c, depth)
        local items = c and c:getItems() or nil
        if items == nil then return end
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            out[#out + 1] = it
            if depth < 2 and instanceof(it, "InventoryContainer") then scan(it:getInventory(), depth + 1) end
        end
    end
    scan(S.p:getInventory(), 0)
    return out
end
-- a thing given (taken back at the end; S.given keeps every one for the put-back check)
function S.give(ft)
    if not S.exists(ft) then return nil end
    local it = RT.give(ft)
    if it ~= nil then S.given[#S.given + 1] = it end
    return it
end
function S.takeBack() RT.takeBack() end
function S.holdPrimary(it)
    local a, b = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    if b ~= nil and b == a then S.p:setSecondaryHandItem(nil) end
    S.p:setPrimaryHandItem(it)
end
function S.handsBack()
    local h = S.was.hands
    if h == nil then return end
    if S.p:getPrimaryHandItem() ~= h.a then S.p:setPrimaryHandItem(h.a) end
    if S.p:getSecondaryHandItem() ~= h.b then S.p:setSecondaryHandItem(h.b) end
end
function S.queueSize()
    local q = ISTimedActionQueue.queues and ISTimedActionQueue.queues[S.p] or nil
    return (q and q.queue) and #q.queue or 0
end

-- ===================================================================== food, drink, weapons, by the game's numbers
function S.rawDanger(it)
    return it ~= nil and instanceof(it, "Food") and it:isbDangerousUncooked() and not it:isCooked()
end
function S.knownTainted(it)
    if it == nil or not instanceof(it, "InventoryItem") then return false end
    local fc = it:getFluidContainer()
    return fc ~= nil and fc:isTaintedStatusKnown()
end
function S.water(it)
    local fc = it:getFluidContainer()
    return fc ~= nil and it:isWaterSource() and fc:getAmount() > 0
end
-- days until it spoils (ZeD's spoil order: rotten last, food that keeps after everything that spoils)
function S.spoil(it)
    if instanceof(it, "Food") and it:isRotten() then return 1e9 end
    local off = it:getOffAge()
    if off >= 1e6 then return 1e8 end
    return off - it:getAge()
end
function S.fill(it, parts)
    local fc = it and it:getFluidContainer() or nil
    if fc == nil then return false end
    fc:Empty()
    local cap = fc:getCapacity()
    for _, pt in ipairs(parts) do fc:addFluid(pt[1], cap * pt[2]) end
    return fc:getAmount() > 0
end
function S.weaponsMain()
    local out = {}
    local items = S.p:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if instanceof(it, "HandWeapon") and it:getCondition() > 0 then out[#out + 1] = it end
    end
    return out
end
function S.share(it)
    local mx = it:getConditionMax()
    if mx <= 0 then return 0 end
    return it:getCondition() / mx
end

-- ===================================================================== the body
function S.partBy(name)
    local t = BodyPartType.FromString(name)
    local bd = S.p:getBodyDamage()
    if t == nil or bd == nil then return nil end
    return bd:getBodyPart(t)
end
function S.woundsOf(bp)
    local w = {}
    if bp:bitten() then w[#w + 1] = "bite" end
    if bp:scratched() then w[#w + 1] = "scratch" end
    if bp:isCut() then w[#w + 1] = "laceration" end
    if bp:deepWounded() then w[#w + 1] = "deep wound" end
    if bp:bleeding() then w[#w + 1] = "bleeding" end
    if bp:haveBullet() then w[#w + 1] = "bullet" end
    if bp:haveGlass() then w[#w + 1] = "glass" end
    if bp:getBurnTime() > 0 then w[#w + 1] = "burn" end
    if bp:getFractureTime() > 0 then w[#w + 1] = "fracture" end
    if bp:isInfectedWound() then w[#w + 1] = "infected wound" end
    if bp:IsInfected() then w[#w + 1] = "infection" end
    if bp:bandaged() then w[#w + 1] = "bandage" end
    if bp:stitched() then w[#w + 1] = "stitches" end
    if bp:getSplintFactor() > 0 then w[#w + 1] = "splint" end
    if bp:getAlcoholLevel() > 0 then w[#w + 1] = "disinfected" end
    if #w == 0 then return "clean" end
    return table.concat(w, "+")
end
function S.bodyNow()
    local out = { parts = {}, wants = {} }
    local bd = S.p:getBodyDamage()
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local bp = parts:get(i)
        local w = S.woundsOf(bp)
        out.parts[i + 1] = { name = S.partName(bp), w = w, h = bp:getHealth() }
        if bp:HasInjury() or bp:bandaged() or bp:stitched() or bp:getSplintFactor() > 0 then
            out.wants[#out.wants + 1] = S.partName(bp) .. " (" .. w .. ")"
        end
    end
    out.health = bd:getOverallBodyHealth()
    out.infected = bd:isInfected()
    return out
end
function S.partState(bp) return { h = bp:getHealth(), stiff = bp:getStiffness(), pain = bp:getAdditionalPain() } end
-- the part as it was found (it was clean: the precondition): the game's own full heal of the part, then its health,
-- stiffness and pain as found
function S.healPart(bp, st)
    if bp == nil or st == nil then return end
    bp:RestoreToFullHealth()
    bp:SetHealth(st.h)
    bp:setStiffness(st.stiff)
    bp:setAdditionalPain(st.pain)
end
-- a laceration with no infection, bleeding, and glass if asked
function S.stageLeg(bp, glass)
    bp:setCut(true, true)
    bp:setCutTime(15)
    bp:setBleeding(true)
    bp:setBleedingTime(10)
    if glass then bp:setHaveGlass(true) end
end
function S.statsNow()
    local out = {}
    local st = S.p:getStats()
    for _, k in ipairs(S.STATS) do
        local cs = CharacterStat and CharacterStat[k] or nil
        if cs ~= nil and st ~= nil then out[k] = st:get(cs) end
    end
    return out
end
function S.statsBack()
    local st = S.p:getStats()
    local now = S.statsNow()
    for _, k in ipairs(S.STATS) do
        local v = S.was.stats and S.was.stats[k] or nil
        if v ~= nil and now[k] ~= nil and math.abs(now[k] - v) > 0.0001 then st:set(CharacterStat[k], v) end
    end
end

-- ===================================================================== the windows (as found, checked at the end)
function S.windowsNow()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    local c = (CW ~= nil and CW.isOpen ~= nil and CW.isOpen(S.pn)) and true or false
    local w = (WW ~= nil and WW.isOpen ~= nil and WW.isOpen(S.pn)) and true or false
    local cw, ww = RT.cw(), RT.ww()
    return { c = c, w = w, ct = (c and cw) and cw._activeTab or nil, wt = (w and ww) and ww._activeTab or nil }
end

-- ===================================================================== the recorder (nothing is queued)
-- While on: ISTimedActionQueue.add / addAfter keep the action and queue nothing; ISInventoryPaneContextMenu.OnNewCraft
-- (a can's opening recipe, which starts a craft) only records; HaloTextHelper.addBadText is watched and passed on.
function S.dryOn()
    if S.dry then return S.dry end
    local d = { acts = {}, halos = {}, phase = "" }
    d.add, d.after, d.halo, d.craft = ISTimedActionQueue.add, ISTimedActionQueue.addAfter, HaloTextHelper.addBadText,
        ISInventoryPaneContextMenu.OnNewCraft
    d.wAdd = function(action, ...)
        d.acts[#d.acts + 1] = { a = action, phase = d.phase }
        local ch = (type(action) == "table") and action.character or nil
        if ch ~= nil then return ISTimedActionQueue.getTimedActionQueue(ch) end
        return nil
    end
    d.wAfter = function(prev, action, ...)
        d.acts[#d.acts + 1] = { a = action, phase = d.phase }
        return nil
    end
    d.wHalo = function(pl, text, ...)
        d.halos[#d.halos + 1] = tostring(text)
        if d.halo then return d.halo(pl, text, ...) end
    end
    d.wCraft = function(item, ...)
        d.acts[#d.acts + 1] = { a = { Type = "OnNewCraft (opening recipe)", item = item }, phase = d.phase }
    end
    ISTimedActionQueue.add, ISTimedActionQueue.addAfter = d.wAdd, d.wAfter
    HaloTextHelper.addBadText = d.wHalo
    ISInventoryPaneContextMenu.OnNewCraft = d.wCraft
    S.dry = d
    return d
end
function S.dryOff()
    local d = S.dry
    if d == nil then return end
    S.dry = nil
    if ISTimedActionQueue.add == d.wAdd then ISTimedActionQueue.add = d.add else S.dryStuck = true end
    if ISTimedActionQueue.addAfter == d.wAfter then ISTimedActionQueue.addAfter = d.after else S.dryStuck = true end
    if HaloTextHelper.addBadText == d.wHalo then HaloTextHelper.addBadText = d.halo else S.dryStuck = true end
    if ISInventoryPaneContextMenu.OnNewCraft == d.wCraft then ISInventoryPaneContextMenu.OnNewCraft = d.craft else S.dryStuck = true end
    S.queueGuard()
end
-- (review, Nov 22 2026: a safety net. Should any path reach the game's queue around the recorder (a reference to
-- the real add kept from before), the queue is cleared at once, in the same Lua call, before any action begins its
-- work; the put-back check FAILs on it)
function S.queueGuard()
    local n = S.queueSize()
    if S.was.queue ~= nil and n > S.was.queue then
        pcall(ISTimedActionQueue.clear, S.p)
        S.leaked = (S.leaked or 0) + (n - S.was.queue)
        Q.say("ERR a timed action reached the real queue during a recording: the queue cleared (" .. n .. ", found " .. S.was.queue .. ")")
    end
end
-- the actions recorded in a phase (nil: every phase)
function S.acts(d, phase)
    local out = {}
    for _, r in ipairs(d and d.acts or {}) do
        if phase == nil or r.phase == phase then out[#out + 1] = r.a end
    end
    return out
end
function S.actWords(list)
    local out = {}
    for _, a in ipairs(list) do
        local t, extra = tostring(a), nil
        if type(a) == "table" then
            t = tostring(a.Type)
            local h = a.handler
            if type(h) == "table" and h.bodyPart ~= nil then
                local arg = (type(a.args) == "table") and a.args[1] or nil
                extra = tostring(h.Type) .. " on the " .. S.partName(h.bodyPart) .. ((arg ~= nil) and (", " .. tostring(arg)) or "")
            elseif a.item ~= nil then
                extra = S.itemName(a.item)
            end
        end
        out[#out + 1] = t .. ((extra ~= nil) and (" (" .. extra .. ")") or "")
    end
    return S.join(out)
end
-- the health menu action a Medicine press started: its handler's kind, body part and item type
function S.medPick(d)
    for _, a in ipairs(S.acts(d, "face")) do
        if type(a) == "table" and a.Type == "HealthPanelAction" and type(a.handler) == "table" and a.handler.bodyPart ~= nil then
            return { kind = tostring(a.handler.Type), bp = a.handler.bodyPart, arg = (type(a.args) == "table") and a.args[1] or nil }
        end
    end
    return nil
end
function S.samePart(bp, ref) return bp ~= nil and ref ~= nil and bp:getType() == ref:getType() end
-- the thing an eat or drink action of the phase would take
function S.taken(d, phase)
    for _, a in ipairs(S.acts(d, phase)) do
        if type(a) == "table" and a.item ~= nil then
            local t = tostring(a.Type or "")
            if t:find("Drink", 1, true) or t:find("Eat", 1, true) or t:find("OnNewCraft", 1, true) then return a.item, t end
        end
    end
    return nil, nil
end

-- ===================================================================== the pad (the game's handlers, a stand-in pad)
function S.btn(button, down)
    if down then pcall(JoypadControllerData.onPressButtonNoFocus, S.ctl, button)
    else pcall(JoypadControllerData.onReleaseButton, S.ctl, button) end
end
function S.bumper(bump) return (bump == "LB") and Joypad.LBumper or Joypad.RBumper end
-- the chord that runs a wheel path (ZeD_chords.txt; nil when none does)
function S.chordOf(path)
    local c = S.QC.chordFor(path)
    if c == nil then return nil end
    local bump, face = c:match("^([LR]B)%+(.+)$")
    if not (bump and S.FACE[face]) then return nil end
    return c
end
-- the chord pressed as the pad presses it, inside a recording (S.dry): the bumper down, the face button down and up
-- with the bumper held (QuickChords.qaBumper), the bumper up. True when QuickChords took the press as that chord.
function S.press(chord)
    local QC, d = S.QC, S.dry
    local bump, face = chord:match("^([LR]B)%+(.+)$")
    local fb = S.FACE[face]
    local was = QC.onPress
    S.took = nil
    QC.onPress = function(jd, b)
        local r = was(jd, b)
        if b == fb then S.took = r end
        return r
    end
    QC.lastChord = nil
    d.phase = "bumper down"
    S.btn(S.bumper(bump), true)
    QC.qaBumper = bump
    d.phase = "face"
    S.btn(fb, true)
    S.btn(fb, false)
    QC.qaBumper = nil
    d.phase = "bumper up"
    S.btn(S.bumper(bump), false)
    d.phase = ""
    QC.onPress = was
    return QC.lastChord == chord and S.took == true
end
function S.chord(chord)
    local d = S.dryOn()
    d.ran = S.press(chord)
    S.dryOff()
    return d
end
-- a list line pressed (its run, as the wheel's slice runs it), recorded
function S.dryLine(line)
    local d = S.dryOn()
    d.phase = "line"
    if line.run then pcall(line.run, S.p, S.pn) end
    d.phase = ""
    S.dryOff()
    return d
end
-- a chord that did not run is the staging's fault (a FAIL line); true when it ran
function S.ran(d, what, chord)
    if d and d.ran then return true end
    Q.check(false, what, chord .. " did not run: QuickChords took the press " .. tostring(S.took) .. ", lastChord "
        .. tostring(S.QC.lastChord) .. " (a ZeD window holding the pad, the game paused or safe mode makes a chord nothing)")
    return false
end

-- ===================================================================== the Character wheel (D-pad Left)
function S.ring()
    local ok, ring = pcall(S.D.B.character, S.p, S.pn)
    if ok and type(ring) == "table" then return ring end
    return {}
end
-- a slice's list, as the wheel builds it when the slice is entered (its sub); nil when the slice is not there
function S.lines(name)
    for _, e in ipairs(S.ring()) do
        if e.name == name then
            if not e.sub then return {} end
            local ok, list = pcall(e.sub, S.p, S.pn)
            return (ok and type(list) == "table") and list or {}
        end
    end
    return nil
end
function S.lineWords(lines)
    local out = {}
    for i, l in ipairs(lines or {}) do
        local det = (l.detail ~= nil and l.detail ~= "") and (" / " .. tostring(l.detail)) or ""
        out[#out + 1] = i .. " " .. tostring(l.name) .. det
        if i >= 14 then out[#out + 1] = "..."; break end
    end
    return S.join(out)
end
-- the first thing with bandage power the game's health menu finds (its handlers walk
-- ISInventoryPaneContextMenu.getContainers, items in order, bags not opened): the type its Bandage menu lists first
function S.firstBandage()
    local cs = ISInventoryPaneContextMenu.getContainers(S.p)
    if cs == nil then return nil end
    for i = 0, cs:size() - 1 do
        local c = cs:get(i)
        local items = c and c:getItems() or nil
        for j = 0, (items and items:size() or 0) - 1 do
            local it = items:get(j)
            if not it:IsInventoryContainer() and it:getBandagePower() > 0 then return it end
        end
    end
    return nil
end

-- ===================================================================== start
function S.start()
    local Z = ZeD or {}
    S.D, S.QC, S.QW, S.HS, S.Dash = Z.DpadWheels, Z.QuickChords, Z.QuickWheel, Z.HintStrip, Z.Dashboard
    S.Focus = Z.Input and Z.Input.Focus or nil
    local ready = S.p ~= nil and not S.p:isDead() and S.D ~= nil and S.D.B ~= nil and S.D.B.character ~= nil and S.D.H ~= nil
        and S.D.H.treatments ~= nil and S.D.H.quick ~= nil and S.QC ~= nil and S.QC.onPress ~= nil and S.QC.chordFor ~= nil
        and S.QW ~= nil and S.QW.tooFull ~= nil and JoypadControllerData ~= nil and JoypadControllerData._zedChords == true
        and ISTimedActionQueue ~= nil and HaloTextHelper ~= nil and ISHealthPanel ~= nil and ISFirearmRadialMenu ~= nil
        and ISInventoryPaneContextMenu ~= nil and getButtonPrompts ~= nil and Joypad ~= nil and CharacterStat ~= nil
    if not Q.check(ready, "ZeD's quick chords, D-pad wheels and quick lists and the game's pad, health and firearm code are loaded") then
        S.dead = true
        return
    end
    S.FACE = { A = Joypad.AButton, B = Joypad.BButton, X = Joypad.XButton, Y = Joypad.YButton, L3 = Joypad.LStickButton, R3 = Joypad.RStickButton }
    S.ctl = setmetatable({ joypad = S.jd }, { __index = JoypadControllerData })
    S.orig = { add = ISTimedActionQueue.add, after = ISTimedActionQueue.addAfter, halo = HaloTextHelper.addBadText,
               craft = ISInventoryPaneContextMenu.OnNewCraft, onPress = S.QC.onPress }
    S.was.cheat = ISHealthPanel.cheat
    S.was.lastChord, S.was.qaBumper = S.QC.lastChord, S.QC.qaBumper
    S.was.hands = { a = S.p:getPrimaryHandItem(), b = S.p:getSecondaryHandItem() }
    S.was.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.was.stats = S.statsNow()
    S.was.body = S.bodyNow()
    S.was.queue = S.queueSize()
    S.was.win = S.windowsNow()
    local St = Z.Settings
    S.was.hintOpt = S.optGet(St and St.hintStripOption)
    S.was.moodOpt = S.optGet(St and St.moodlePlaceOption)
    local buts = getButtonPrompts(S.pn)
    S.was.rb = buts and { prompt = buts.rbPrompt, func = buts.rbFunc, params = buts.rbParams } or nil
    -- (the pad is the world's for a chord: a ZeD window holding it makes QuickChords refuse the press)
    S.was.focus = (S.Focus and S.Focus.getFocusedWindow) and S.Focus.getFocusedWindow(S.pn) or nil
    if S.was.focus ~= nil and S.Focus.releaseFocus then S.Focus.releaseFocus(S.pn) end
    local h = S.was.hands
    Q.say("start: screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", ZeD's scale " .. tostring(Z.T and Z.T.scale)
        .. "; god mode " .. tostring(S.p:isGodMod()) .. "; in his hands " .. S.itemName(h.a) .. " and " .. S.itemName(h.b)
        .. "; parts wanting care: " .. S.join(S.was.body.wants) .. "; queue " .. S.was.queue .. "; the health menu's cheat "
        .. tostring(S.was.cheat) .. "; a window held the pad " .. tostring(S.was.focus ~= nil) .. "; chords: Medicine "
        .. tostring(S.QC.chordFor("character:5")) .. ", Weapons " .. tostring(S.QC.chordFor("character:2")) .. ", Eat "
        .. tostring(S.QC.chordFor("character:3")) .. ", Drink " .. tostring(S.QC.chordFor("character:4")) .. "; Hint strip "
        .. tostring(S.was.hintOpt) .. ", Moodles " .. tostring(S.was.moodOpt) .. "; in a car " .. tostring(S.p:getVehicle() ~= nil))
end

-- ===================================================================== K1-1: the Medicine chord and list
function S.partMedicine()
    if S.dead then return end
    local chord = S.chordOf("character:5")
    if chord == nil then
        Q.skip("K1-1 the Medicine chord", "no chord runs D-pad Left > Medicine (character:5) in ZeD_chords.txt")
        return
    end
    local body = S.bodyNow()
    if #body.wants > 0 then
        Q.skip("K1-1 the Medicine chord and list", "he has wounds or dressings of his own (" .. S.join(body.wants) .. "): the run stages none over them")
        return
    end
    local M = { chord = chord, fa = S.partBy("ForeArm_L"), leg = S.partBy("LowerLeg_R") }
    if not Q.check(M.fa ~= nil and M.leg ~= nil, "K1-1 staging: his left forearm and right shin are found") then return end
    M.found = { fa = S.partState(M.fa), leg = S.partState(M.leg) }
    S.stagedFa, S.stagedLeg = S.partName(M.fa), S.partName(M.leg)
    ISHealthPanel.cheat = false
    for _, ft in ipairs(S.MED_THINGS) do S.give(ft) end
    local ok, err = pcall(S.medicineRun, M)
    S.dryOff()
    S.healPart(M.fa, M.found.fa)
    S.healPart(M.leg, M.found.leg)
    ISHealthPanel.cheat = S.was.cheat
    S.takeBack()
    Q.say("K1-1 healed: the " .. S.partName(M.fa) .. " " .. S.woundsOf(M.fa) .. ", the " .. S.partName(M.leg) .. " " .. S.woundsOf(M.leg))
    if not ok then Q.check(false, "K1-1 ran to its end", tostring(err)) end
end
function S.medStep(M, what, test)
    local d = S.chord(M.chord)
    if not S.ran(d, what, M.chord) then return end
    local a = S.medPick(d)
    Q.check(a ~= nil and S.samePart(a.bp, M.leg) and test(a), what, M.chord .. " asked for: " .. S.actWords(S.acts(d, "face"))
        .. "; said: " .. S.join(d.halos) .. "; the " .. S.partName(M.leg) .. " is " .. S.woundsOf(M.leg))
end
function S.medicineRun(M)
    local fa, leg = S.partName(M.fa), S.partName(M.leg)
    -- A: the forearm only bandaged (clean), the shin's bleeding laceration with glass
    M.fa:setBandaged(true, 4, false, "Base.Bandage")
    S.stageLeg(M.leg, true)
    Q.say("K1-1 scenario A: the " .. fa .. " " .. S.woundsOf(M.fa) .. " (bandage life " .. S.num(M.fa:getBandageLife()) .. "), the "
        .. leg .. " " .. S.woundsOf(M.leg))
    local d = S.chord(M.chord)
    local A = "K1-1 scenario A (a clean bandage alone on the " .. fa .. ", a bleeding laceration with glass in the " .. leg .. "): " .. M.chord
    if S.ran(d, A, M.chord) then
        local a = S.medPick(d)
        local how = M.chord .. " asked for: " .. S.actWords(S.acts(d, "face")) .. "; said: " .. S.join(d.halos)
        Q.check(a ~= nil and S.samePart(a.bp, M.leg), A .. " treats the worst wound first, the " .. leg, how)
        Q.check(a ~= nil and a.kind ~= "HRemoveBandage", A .. " never takes off the clean bandage of a part that is only bandaged", how)
    end
    -- the Medicine list, as D-pad Left > Medicine builds it
    local lines = S.lines(ZeD.tr("UI_ZeD_Wheel_Medicine"))
    if Q.check(lines ~= nil and #lines > 0, "K1-1 the Character wheel (D-pad Left) has its Medicine list") then
        local okT, treat = pcall(S.D.H.treatments, S.p, S.pn)
        local T = (okT and type(treat) == "table") and #treat or 0
        local okP, pills = pcall(S.D.H.quick, S.p, "pills")
        local P = (okP and type(pills) == "table") and #pills or 0
        local nT, first, thingSeen, thingFirst = 0, nil, false, false
        for _, l in ipairs(lines) do
            if l.key == nil then
                nT = nT + 1
                if first == nil then first = l end
                if thingSeen then thingFirst = true end
            elseif l.key ~= "health" then
                thingSeen = true
            end
        end
        local said = "the list: " .. S.lineWords(lines) .. "; " .. T .. " treatments, " .. P .. " kinds of pills on him"
        if P > 0 then
            Q.check(nT > 0 and not thingFirst, "K1-1 the Medicine list lists every treatment before any pills", said)
        else
            Q.skip("K1-1 the Medicine list lists every treatment before any pills", "no pills on him: the old order cannot show here")
        end
        if T + P > 10 and P > 0 then
            Q.check(nT == math.min(T, 10), "K1-1 the Medicine list's cut at ten drops pills, not treatments (it holds " .. math.min(T, 10)
                .. " of the " .. T .. " treatments)", nT .. " treatments listed; " .. said)
        else
            Q.skip("K1-1 the Medicine list's cut at ten drops pills", T .. " treatments and " .. P .. " kinds of pills fit in ten: no cut to see")
        end
        Q.check(first ~= nil and tostring(first.detail) == leg, "K1-1 the Medicine list's first treatment is the worst wound's (the " .. leg
            .. "), as the Health tab orders them", said)
    end
    -- B: the forearm healed; the shin alone, step by step as the game's treatments leave it
    S.healPart(M.fa, M.found.fa)
    local B = "K1-1 scenario B (the bleeding laceration with glass in the " .. leg .. " alone)"
    Q.say(B .. ": the " .. fa .. " " .. S.woundsOf(M.fa) .. ", the " .. leg .. " " .. S.woundsOf(M.leg))
    S.medStep(M, B .. ": " .. M.chord .. " takes the glass out first", function(a) return a.kind == "HRemoveGlass" end)
    M.leg:setHaveGlass(false)
    S.medStep(M, B .. ", the glass out: " .. M.chord .. " disinfects next", function(a) return a.kind == "HDisinfect" end)
    M.leg:setAlcoholLevel(4)
    local fb = S.firstBandage()
    local dirtyFirst = fb ~= nil and tostring(fb:getFullType()):find("Dirty", 1, true) ~= nil
    if dirtyFirst then
        S.medStep(M, B .. ", disinfected: " .. M.chord .. " puts on a clean bandage, not the dirty one the game lists first ("
            .. S.itemName(fb) .. ")", function(a) return a.kind == "HApplyBandage" and a.arg ~= nil and tostring(a.arg):find("Dirty", 1, true) == nil end)
    else
        Q.skip(B .. ", disinfected: a clean bandage before a dirty one", "the game's health menu lists " .. S.itemName(fb)
            .. " first among his bandages, so the old code took a clean one too: nothing to tell apart without reordering his things")
    end
end

-- ===================================================================== K1-3: quick Eat
function S.partEat()
    if S.dead then return end
    if S.QW.tooFull(S.p) then
        Q.skip("K1-3 quick Eat", "he is too full to eat (the game's Well fed at 3): the Eat list is empty in the old code and the new")
        return
    end
    local egg = S.give("Base.Egg")
    if not Q.check(egg ~= nil and S.rawDanger(egg), "K1-3 staging: a raw egg the game marks dangerous uncooked", S.itemName(egg)) then
        S.takeBack()
        return
    end
    local mx, off = egg:getOffAgeMax(), egg:getOffAge()
    if mx > off then egg:setAge(mx - 0.05) end
    local ok, err = pcall(S.eatRun, egg)
    S.dryOff()
    S.takeBack()
    if not ok then Q.check(false, "K1-3 (Eat) ran to its end", tostring(err)) end
end
function S.eatRun(egg)
    local lines = S.lines(getText("ContextMenu_Eat"))
    if not Q.check(lines ~= nil, "K1-3 the Character wheel (D-pad Left) has its Eat list") then return end
    local raw = {}
    for _, it in ipairs(S.carried()) do
        if S.rawDanger(it) then raw[it:getFullType()] = true end
    end
    local seen, bad = {}, {}
    for _, l in ipairs(lines) do
        if l.key ~= nil and raw[l.key] then
            local d = S.dryLine(l)
            local item = S.taken(d, "line")
            seen[#seen + 1] = tostring(l.name) .. " eats " .. S.itemName(item)
            if S.rawDanger(item) then bad[#bad + 1] = tostring(l.name) end
        end
    end
    Q.check(#bad == 0, "K1-3 the Eat list (D-pad Left > Eat) offers no raw food that needs cooking first (a raw egg carried)",
        "lines of the raw kinds he carries: " .. S.join(seen) .. "; the list: " .. S.lineWords(lines))
    local chord = S.chordOf("character:3")
    if chord == nil then
        Q.skip("K1-3 quick Eat's chord", "no chord runs D-pad Left > Eat (character:3) in ZeD_chords.txt")
        return
    end
    local rEgg, minO, other = S.spoil(egg), nil, nil
    for _, it in ipairs(S.carried()) do
        if it ~= egg and it:getFullType() ~= egg:getFullType() and it:getCategory() == "Food" then
            local r = S.spoil(it)
            if r < 1e8 and (minO == nil or r < minO) then minO, other = r, it end
        end
    end
    local what = "K1-3 " .. chord .. " (quick Eat) never eats raw food that needs cooking"
    if minO ~= nil and minO <= rEgg then
        Q.skip(what, S.itemName(other) .. " spoils sooner (" .. S.num(minO) .. " days) than the raw egg can (" .. S.num(rEgg)
            .. "): the old pick is that, so the chord cannot show the old fault here; the Eat list's check covers it")
        return
    end
    local d = S.chord(chord)
    if not S.ran(d, what, chord) then return end
    local item, t = S.taken(d, "face")
    Q.check(not S.rawDanger(item), what .. ": with a raw egg about to spoil it eats something else, or nothing",
        chord .. " asked for: " .. S.actWords(S.acts(d, "face")) .. "; said: " .. S.join(d.halos) .. "; the egg spoils in "
        .. S.num(rEgg) .. " days, the next food in " .. S.num(minO))
end

-- ===================================================================== K1-3: quick Drink
function S.partDrink()
    if S.dead then return end
    local have = {}
    for _, it in ipairs(S.carried()) do have[it:getFullType()] = true end
    local kinds = {}
    for _, ft in ipairs(S.BOTTLES) do
        if #kinds < 2 and not have[ft] and S.exists(ft) then kinds[#kinds + 1] = ft end
    end
    if #kinds < 2 then
        Q.skip("K1-3 quick Drink", "he carries every kind of bottle the run could use (" .. table.concat(S.BOTTLES, ", ") .. ")")
        return
    end
    local G = { K = kinds[1], K2 = kinds[2] }
    G.T = S.give(G.K)        -- (first: on the old code the kind's line holds the first found)
    G.C = S.give(G.K)
    G.B = S.give(G.K2)
    local filled = G.T ~= nil and G.C ~= nil and G.B ~= nil
        and S.fill(G.T, { { FluidType.TaintedWater, 1.0 } }) and S.fill(G.C, { { FluidType.Water, 0.8 } })
        and S.fill(G.B, { { FluidType.Water, 0.6 }, { FluidType.Bleach, 0.3 } })
    if not Q.check(filled, "K1-3 staging: two bottles of " .. G.K .. " (tainted water, then clean water) and one of " .. G.K2
        .. " (water with bleach) on him") then
        S.takeBack()
        return
    end
    Q.say("K1-3 drink: tainted " .. S.itemName(G.T) .. " known " .. tostring(S.knownTainted(G.T)) .. "; clean " .. S.itemName(G.C)
        .. " known " .. tostring(S.knownTainted(G.C)) .. "; bleach water " .. S.itemName(G.B) .. " known " .. tostring(S.knownTainted(G.B))
        .. "; sandbox tainted water text " .. tostring(SandboxVars and SandboxVars.EnableTaintedWaterText))
    if not S.knownTainted(G.T) or S.knownTainted(G.C) then
        Q.skip("K1-3 quick Drink", "the game does not know the tainted bottle is tainted (the sandbox's tainted water text is off): the game would drink it too")
        S.takeBack()
        return
    end
    local ok, err = pcall(S.drinkRun, G)
    S.dryOff()
    S.takeBack()
    if not ok then Q.check(false, "K1-3 (Drink) ran to its end", tostring(err)) end
end
function S.drinkRun(G)
    local lines = S.lines(getText("ContextMenu_Drink"))
    if not Q.check(lines ~= nil, "K1-3 the Character wheel (D-pad Left) has its Drink list") then return end
    local tainted, waterOther = {}, {}
    for _, it in ipairs(S.carried()) do
        if S.knownTainted(it) then tainted[it:getFullType()] = true end
        if it ~= G.T and it ~= G.C and it ~= G.B and S.water(it) then waterOther[#waterOther + 1] = S.itemName(it) end
    end
    local seen, bad, kLine = {}, {}, nil
    for _, l in ipairs(lines) do
        if l.key ~= nil and tainted[l.key] then
            local d = S.dryLine(l)
            local item = S.taken(d, "line")
            seen[#seen + 1] = tostring(l.name) .. " drinks " .. S.itemName(item)
            if S.knownTainted(item) then bad[#bad + 1] = tostring(l.name) end
            if l.key == G.K then kLine = { l = l, item = item } end
        end
    end
    local list = "the list: " .. S.lineWords(lines)
    Q.check(#bad == 0, "K1-3 the Drink list (D-pad Left > Drink) offers no known-tainted water and no water with bleach",
        "lines of the kinds with known-tainted fluid on him: " .. S.join(seen) .. "; " .. list)
    local kName = kLine and tostring(kLine.l.name) or "none"
    Q.check(kLine ~= nil and S.count(kLine.l.name) == 1 and kLine.item == G.C,
        "K1-3 a clean and a tainted " .. G.K .. " do not fold into one line: its line counts the clean one alone and drinks it",
        "its line \"" .. kName .. "\" drinks " .. S.itemName(kLine and kLine.item) .. " (the clean one is " .. S.itemName(G.C) .. "); " .. list)
    local chord = S.chordOf("character:4")
    local what = "K1-3 " .. tostring(chord) .. " (quick Drink) never drinks known-tainted water or water with bleach"
    if chord == nil then
        Q.skip("K1-3 quick Drink's chord", "no chord runs D-pad Left > Drink (character:4) in ZeD_chords.txt")
        return
    end
    if #waterOther > 0 then
        Q.skip(what, "he carries water of his own (" .. S.join(waterOther) .. "): the old pick may be his, so the chord cannot show the old fault here; the Drink list's checks cover it")
        return
    end
    local d = S.chord(chord)
    if not S.ran(d, what, chord) then return end
    local item = S.taken(d, "face")
    Q.check(item ~= nil and not S.knownTainted(item), what .. ": it drinks the clean water",
        chord .. " asked for: " .. S.actWords(S.acts(d, "face")) .. "; said: " .. S.join(d.halos))
end

-- ===================================================================== K1-5: RB + B, the Weapons quick action
function S.partWeapons()
    if S.dead then return end
    local chord = S.chordOf("character:2")
    if chord == nil then
        Q.skip("K1-5 the Weapons chord", "no chord runs D-pad Left > Weapons (character:2) in ZeD_chords.txt")
        return
    end
    local W = { chord = chord }
    local w0 = S.weaponsMain()[1]
    if w0 ~= nil then
        W.kind = w0:getFullType()
        W.held = S.give(W.kind)
        for _, ft in ipairs(S.OTHER_WEAPONS) do
            if W.other == nil and ft ~= W.kind then W.other = S.give(ft) end
        end
    else
        W.kind = "Base.Hammer"
        W.held = S.give(W.kind)
        if W.held ~= nil then W.held:setCondition(math.max(1, math.floor(W.held:getConditionMax() * 0.3))) end
        W.other = S.give("Base.Axe")
    end
    if not Q.check(W.held ~= nil and W.other ~= nil and instanceof(W.held, "HandWeapon") and instanceof(W.other, "HandWeapon"),
        "K1-5 staging: a " .. tostring(W.kind) .. " in his hand (the bag's first weapon kind) and a weapon of another kind on him",
        "held " .. S.itemName(W.held) .. ", other " .. S.itemName(W.other)) then
        S.takeBack()
        return
    end
    S.holdPrimary(W.held)
    local ok, err = pcall(S.weaponsRun, W)
    S.dryOff()
    S.handsBack()
    S.takeBack()
    if not ok then Q.check(false, "K1-5 ran to its end", tostring(err)) end
end
function S.weaponsRun(W)
    local held = W.held
    local mine = {}
    for _, it in ipairs(S.weaponsMain()) do mine[#mine + 1] = S.itemName(it) .. " " .. S.num(S.share(it) * 100) .. "%" end
    Q.say("K1-5: in his hand " .. S.itemName(held) .. "; the weapons in his main inventory, in the bag's order: " .. S.join(mine))
    local what = "K1-5 " .. W.chord .. " with the bag's first weapon kind in his hand"
    local d = S.chord(W.chord)
    if S.ran(d, what, W.chord) then
        local putAway, drawn = false, nil
        for _, a in ipairs(S.acts(d, "face")) do
            if type(a) == "table" and a.Type == "ISUnequipAction" and a.item == held then putAway = true end
            if type(a) == "table" and a.Type == "ISEquipWeaponAction" and drawn == nil then drawn = a.item end
        end
        local how = W.chord .. " asked for: " .. S.actWords(S.acts(d, "face")) .. "; said: " .. S.join(d.halos)
        Q.check(not putAway, what .. ": it never puts away the weapon in hand", how)
        local better = {}
        if drawn ~= nil and instanceof(drawn, "HandWeapon") then
            -- (review, Nov 22 2026: a kind is the copy its wheel line shows, the one in a hand or else the best kept,
            -- as the game's own wheel line does; a worse copy held in the other hand stands for its kind)
            local reps, order = {}, {}
            for _, it in ipairs(S.weaponsMain()) do
                local ft = it:getFullType()
                local r = reps[ft]
                if r == nil then order[#order + 1] = ft end
                if r == nil or S.p:isEquipped(it) or it:getCondition() > r:getCondition() then reps[ft] = it end
            end
            for _, ft in ipairs(order) do
                local it = reps[ft]
                if ft ~= held:getFullType() and ft ~= drawn:getFullType() and S.share(it) > S.share(drawn) + 1e-6 then
                    better[#better + 1] = S.itemName(it) .. " " .. S.num(S.share(it) * 100) .. "%"
                end
            end
        end
        Q.check(drawn ~= nil and drawn ~= held and #better == 0, what .. ": it draws the best weapon not in hand (by condition), not the bag's first",
            how .. "; drawn " .. S.itemName(drawn) .. ((drawn ~= nil and instanceof(drawn, "HandWeapon")) and (" " .. S.num(S.share(drawn) * 100) .. "%") or "")
            .. "; better ones of other kinds: " .. S.join(better))
    end
    -- only the held weapon's kind on him: "In your hands", nothing done
    local c = W.other:getContainer()
    if c ~= nil then c:Remove(W.other) end
    local others = {}
    for _, it in ipairs(S.weaponsMain()) do
        if it:getFullType() ~= W.kind then others[#others + 1] = S.itemName(it) end
    end
    local what3 = "K1-5 " .. W.chord .. " with only the weapon in hand"
    if #others > 0 then
        Q.skip(what3, "he carries other weapon kinds in his main inventory (" .. S.join(others) .. "): his weapons are never moved for the run")
        return
    end
    local d3 = S.chord(W.chord)
    if not S.ran(d3, what3, W.chord) then return end
    local word = ZeD.tr("UI_ZeD_Wheel_InYourHands")
    local said = false
    for _, t in ipairs(d3.halos) do if t == word then said = true end end
    Q.check(#S.acts(d3, "face") == 0 and said, what3 .. ": nothing is done and he says \"" .. tostring(word) .. "\"",
        W.chord .. " asked for: " .. S.actWords(S.acts(d3, "face")) .. "; said: " .. S.join(d3.halos))
end

-- ===================================================================== K1-4: RB in a chord does not reload
function S.partReload()
    if S.dead then return end
    local chord = nil
    for _, path in ipairs({ "character:5", "character:2" }) do
        local c = S.chordOf(path)
        if chord == nil and c ~= nil and c:sub(1, 2) == "RB" then chord = c end
    end
    if chord == nil then
        Q.skip("K1-4 RB in a chord", "neither the Medicine nor the Weapons action is on an RB chord in ZeD_chords.txt")
        return
    end
    local buts = getButtonPrompts(S.pn)
    local gun, mag = S.give("Base.Pistol"), S.give("Base.9mmClip")
    if not Q.check(buts ~= nil and gun ~= nil and mag ~= nil and instanceof(gun, "HandWeapon"), "K1-4 staging: a pistol and an empty magazine, and the game's button prompts",
        S.itemName(gun) .. ", " .. S.itemName(mag)) then
        S.takeBack()
        return
    end
    if gun:isContainsClip() then gun:setContainsClip(false) end
    gun:setCurrentAmmoCount(0)
    gun:setRoundChambered(false)
    mag:setCurrentAmmoCount(0)
    S.holdPrimary(gun)
    local ok, err = pcall(S.reloadRun, chord, buts, gun)
    S.dryOff()
    S.QC.qaBumper = S.was.qaBumper
    if S.was.rb ~= nil then buts.rbPrompt, buts.rbFunc, buts.rbParams = S.was.rb.prompt, S.was.rb.func, S.was.rb.params end
    S.handsBack()
    S.takeBack()
    if not ok then Q.check(false, "K1-4 ran to its end", tostring(err)) end
end
function S.reloadRun(chord, buts, gun)
    local offered = ISFirearmRadialMenu.getBestRBButtonAction(buts)
    if not (offered and buts.rbFunc ~= nil) then
        Q.skip("K1-4 RB in a chord", "the game offers no RELOAD on RB with the pistol in hand (its RB prompt " .. tostring(buts.rbPrompt) .. ")")
        return
    end
    local d = S.dryOn()
    d.phase = "rb alone down"
    S.btn(Joypad.RBumper, true)
    d.phase = "rb alone up"
    S.btn(Joypad.RBumper, false)
    d.ran = S.press(chord)
    S.dryOff()
    local alone, after = S.acts(d, "rb alone up"), S.acts(d, "bumper up")
    Q.check(#alone > 0, "K1-4 (guard) RB alone with the pistol in hand: the game's release still asks for its reload",
        "asked for: " .. S.actWords(alone) .. "; the pistol " .. S.itemName(gun) .. ", RB prompt " .. tostring(buts.rbPrompt))
    if #alone == 0 then return end
    if not S.ran(d, "K1-4 " .. chord .. " with the pistol in hand", chord) then return end
    Q.check(#after == 0, "K1-4 " .. chord .. " with the pistol in hand: RB let go after the chord asks for no reload",
        "at RB's release: " .. S.actWords(after) .. "; the chord's own action: " .. S.actWords(S.acts(d, "face")) .. "; said: " .. S.join(d.halos))
end

-- ===================================================================== K1-8: the hint strip in a car
function S.dash() return S.Dash and S.Dash.getInstance and S.Dash.getInstance(S.pn) or nil end
function S.strip() return (S.HS and S.HS._huds) and S.HS._huds[S.pn] or nil end
function S.rect(e) return { x = e:getX(), y = e:getY(), w = e:getWidth(), h = e:getHeight() } end
function S.rs(r) return S.num(r.x) .. "," .. S.num(r.y) .. " " .. S.num(r.w) .. "x" .. S.num(r.h) end
function S.carStart()
    if S.dead then S.carOff = true; return end
    if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY) then
        Q.skip("K1-8 the hint strip in a car", "the prelude's car helpers (ZEDQA_CAR_*) are not here: run after zedqa_prelude.lua")
        S.carOff = true
        return
    end
    if S.p:getVehicle() ~= nil then
        Q.skip("K1-8 the hint strip in a car", "he sits in a car already: the run places its own")
        S.carOff = true
        return
    end
    if not Q.check(S.strip() ~= nil and S.Dash ~= nil and S.Dash.getInstance ~= nil, "K1-8 staging: ZeD's hint strip and dash are loaded") then
        S.carOff = true
        return
    end
    local St = ZeD.Settings
    if S.was.hintOpt ~= nil and S.was.hintOpt ~= 1 then S.optSet(St.hintStripOption, 1) end      -- (Always)
    if S.was.moodOpt == 3 then S.optSet(St.moodlePlaceOption, 1) end                             -- (bottom: right)
    S.car = { state = "wait" }
    local car = S.car
    ZEDQA_CAR_WAIT("Base.PickUpTruck", "vk1_pad", function(v)
        car.v = v
        car.state = "ready"
        if car.cancel then ZEDQA_CAR_AWAY(v) end   -- (ready only after the put-back began)
    end, function(why) car.state = "fail"; car.why = tostring(why) end, 6000)
end
function S.carEnter(ok)
    if S.carOff then return end
    local car = S.car
    if not Q.check(car.state == "ready" and car.v ~= nil, "K1-8 staging: a pickup truck stands beside him (the prelude's car spots)",
        tostring(car.why or car.state)) then
        S.carOff = true
        return
    end
    local okE, why = ZEDQA_CAR_ENTER(car.v, 0)
    if not Q.check(okE == true, "K1-8 staging: he sits in the driver's seat", tostring(why)) then S.carOff = true; return end
    S.sig, S.sigAt = nil, nil
end
function S.toPassenger()
    if S.carOff then return end
    local v = S.car.v
    if not (v ~= nil and S.p:getVehicle() == v and v:isSeatInstalled(1) and not v:isSeatOccupied(1)) then
        Q.skip("K1-8 the passenger seat", "the truck has no free passenger seat")
        S.car.noPass = true
        return
    end
    v:switchSeat(S.p, 1)
    v:playPassengerAnim(1, "idle")
    triggerEvent("OnSwitchVehicleSeat", S.p)
    S.sig, S.sigAt = nil, nil
end
-- the dash up for his car and the strip with prompts, both at one place for 300 ms
function S.seatReady()
    if S.carOff or (S.car and S.car.noPass) then return true end
    local v = S.car and S.car.v or nil
    local d, h = S.dash(), S.strip()
    if not (v ~= nil and S.p:getVehicle() == v and d ~= nil and h ~= nil and d:getIsVisible() and d.vehicle == v and h._p ~= nil) then
        S.sig = nil
        return false
    end
    local sig = S.rs(S.rect(d)) .. " | " .. S.rs(S.rect(h))
    local now = getTimestampMs()
    if sig ~= S.sig then
        S.sig, S.sigAt = sig, now
        return false
    end
    return now - S.sigAt >= 300
end
function S.seatJudge(seat, ok)
    if S.carOff or (S.car and S.car.noPass) then return end
    local d, h = S.dash(), S.strip()
    local up = ok and d ~= nil and h ~= nil and d:getIsVisible() and type(h._p) == "table"
    local words = {}
    if h ~= nil and type(h._p) == "table" then
        for _, pr in ipairs(h._p) do words[#words + 1] = tostring(pr.glyph) .. " " .. tostring(pr.label) end
    end
    local simple = ZeD.Dashboard and ZeD.Dashboard.simple and ZeD.Dashboard.simple() or false
    if not Q.check(up, "K1-8 " .. seat .. " (guard): ZeD's dash is up and the hint strip shows its prompts",
        "dash " .. tostring(d ~= nil and d:getIsVisible()) .. ", the strip's prompts " .. S.join(words)) then return end
    local rd, rh = S.rect(d), S.rect(h)
    local W, H = RT.core:getScreenWidth(), RT.core:getScreenHeight()
    local above = rh.y + rh.h <= rd.y + S.TOL
    local inside = rh.x >= -S.TOL and rh.y >= -S.TOL and rh.x + rh.w <= W + S.TOL and rh.y + rh.h <= H + S.TOL
    Q.check(above and inside, "K1-8 " .. seat .. ": the hint strip's prompts sit above the dash's top edge, fully on screen",
        "strip " .. S.rs(rh) .. " (bottom " .. S.num(rh.y + rh.h) .. "), dash " .. S.rs(rd) .. " (top " .. S.num(rd.y) .. ", "
        .. (simple and "the simple strip" or "the pixel plate") .. "), screen " .. W .. "x" .. H .. "; prompts " .. S.join(words))
end

-- ===================================================================== put back
-- (IsoCell.getVehicles is a Set on 42.2x: walked with its iterator, as the prelude walks it)
function S.carLive()
    local v = S.car and S.car.v or nil
    if v == nil then return false end
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        if it:next() == v then return true end
    end
    return false
end
function S.backCar()
    S.dryOff()
    if S.car ~= nil then
        S.car.cancel = true
        if S.car.v ~= nil and ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(S.car.v) end
    end
    local St = ZeD and ZeD.Settings
    if St and S.was.hintOpt ~= nil and S.optGet(St.hintStripOption) ~= S.was.hintOpt then S.optSet(St.hintStripOption, S.was.hintOpt) end
    if St and S.was.moodOpt ~= nil and S.optGet(St.moodlePlaceOption) ~= S.was.moodOpt then S.optSet(St.moodlePlaceOption, S.was.moodOpt) end
end
function S.backAll()
    if S.was.pos == nil then return end   -- (the run stopped before it read him)
    local P = S.was.pos
    if S.p:getVehicle() == nil then
        local dx, dy = S.p:getX() - P.x, S.p:getY() - P.y
        if dx * dx + dy * dy > 0.25 or math.floor(S.p:getZ()) ~= math.floor(P.z) then
            S.p:setX(P.x); S.p:setY(P.y); S.p:setZ(P.z)
            S.p:setLastX(P.x); S.p:setLastY(P.y); S.p:setLastZ(P.z)
            S.movedBack = true
        end
    end
    S.handsBack()
    S.takeBack()
    ISHealthPanel.cheat = S.was.cheat
    if S.QC then S.QC.qaBumper, S.QC.lastChord = S.was.qaBumper, S.was.lastChord end
    local buts = getButtonPrompts(S.pn)
    if buts and S.was.rb then buts.rbPrompt, buts.rbFunc, buts.rbParams = S.was.rb.prompt, S.was.rb.func, S.was.rb.params end
    S.statsBack()
    if S.was.focus ~= nil and S.Focus and S.Focus.claimFocus and S.was.focus:isVisible() then S.Focus.claimFocus(S.was.focus) end
end
function S.backChecks()
    if S.was.body == nil then return end
    Q.check(ISTimedActionQueue.add == S.orig.add and ISTimedActionQueue.addAfter == S.orig.after and HaloTextHelper.addBadText == S.orig.halo
        and ISInventoryPaneContextMenu.OnNewCraft == S.orig.craft and S.QC.onPress == S.orig.onPress and not S.dryStuck,
        "put back: the action queue, the halo text, the opening recipe and the chords' press are the game's and ZeD's own again",
        "add " .. tostring(ISTimedActionQueue.add == S.orig.add) .. ", addAfter " .. tostring(ISTimedActionQueue.addAfter == S.orig.after)
        .. ", addBadText " .. tostring(HaloTextHelper.addBadText == S.orig.halo) .. ", OnNewCraft " .. tostring(ISInventoryPaneContextMenu.OnNewCraft == S.orig.craft)
        .. ", onPress " .. tostring(S.QC.onPress == S.orig.onPress) .. ", another hand wrapped one meanwhile " .. tostring(S.dryStuck == true))
    local buts = getButtonPrompts(S.pn)
    local rbOk = buts == nil or S.was.rb == nil or (buts.rbPrompt == S.was.rb.prompt and buts.rbFunc == S.was.rb.func)
    Q.check(ISHealthPanel.cheat == S.was.cheat and S.QC.qaBumper == S.was.qaBumper and S.QC.lastChord == S.was.lastChord and rbOk,
        "put back: the health menu's cheat flag, the chords' test hooks and the game's RB prompt as found",
        "cheat " .. tostring(ISHealthPanel.cheat) .. " (found " .. tostring(S.was.cheat) .. "), qaBumper " .. tostring(S.QC.qaBumper)
        .. ", lastChord " .. tostring(S.QC.lastChord) .. " (found " .. tostring(S.was.lastChord) .. "), RB prompt " .. tostring(buts and buts.rbPrompt))
    -- (what the run can touch: a part found clean must end clean, and the two staged parts at the health they had;
    -- a wound of his own, were god mode off, may change by itself and is only said)
    local b = S.bodyNow()
    local diff, own = {}, {}
    for i, pt in ipairs(b.parts) do
        local w0 = S.was.body.parts[i]
        local staged = pt.name == S.stagedFa or pt.name == S.stagedLeg
        if w0 == nil or (w0.w == "clean" and pt.w ~= "clean") or (staged and math.abs(pt.h - w0.h) > 0.5) then
            diff[#diff + 1] = pt.name .. " " .. pt.w .. " " .. S.num(pt.h) .. " (found " .. tostring(w0 and w0.w) .. " " .. S.num(w0 and w0.h) .. ")"
        elseif w0.w ~= pt.w then
            own[#own + 1] = pt.name .. " " .. pt.w .. " (found " .. w0.w .. ")"
        end
    end
    Q.check(not S.p:isDead() and #diff == 0 and (b.infected == false or S.was.body.infected == true),
        "put back: alive and unhurt: no part found clean has a wound or dressing, the staged parts at their health, not infected",
        "health " .. S.num(b.health) .. " (found " .. S.num(S.was.body.health) .. "), infected " .. tostring(b.infected) .. " (found "
        .. tostring(S.was.body.infected) .. "); changed: " .. S.join(diff) .. "; his own wounds changed by themselves: " .. S.join(own))
    local now, sd = S.statsNow(), {}
    for _, k in ipairs(S.STATS) do
        local v0 = S.was.stats[k]
        if v0 ~= nil and now[k] ~= nil and math.abs(now[k] - v0) > 0.001 then sd[#sd + 1] = k .. " " .. tostring(now[k]) .. " (found " .. tostring(v0) .. ")" end
    end
    Q.check(#sd == 0, "put back: his stats as found (hunger, thirst, fatigue, stress, sickness, food sickness, poison, panic, pain)", S.join(sd))
    local left = {}
    for _, it in ipairs(S.given) do
        if it:getContainer() ~= nil then left[#left + 1] = S.itemName(it) end
    end
    local h = S.was.hands
    Q.check(#left == 0 and S.p:getPrimaryHandItem() == h.a and S.p:getSecondaryHandItem() == h.b,
        "put back: every thing given taken back, his hands holding what they held",
        "left on him: " .. S.join(left) .. "; in his hands " .. S.itemName(S.p:getPrimaryHandItem()) .. " and " .. S.itemName(S.p:getSecondaryHandItem())
        .. " (found " .. S.itemName(h.a) .. " and " .. S.itemName(h.b) .. ")")
    Q.check(S.queueSize() <= S.was.queue and not S.leaked, "put back: no timed action of the run's is queued (nothing eaten, drunk, taken, treated, equipped or reloaded)",
        "queue " .. S.queueSize() .. " (found " .. S.was.queue .. "); actions that reached the real queue and were cleared: " .. tostring(S.leaked or 0))
    if S.car ~= nil then
        local P = S.was.pos
        local dx, dy = S.p:getX() - P.x, S.p:getY() - P.y
        Q.check(S.p:getVehicle() == nil and not S.carLive() and dx * dx + dy * dy <= 0.25 and math.floor(S.p:getZ()) == math.floor(P.z),
            "put back: out of the car, the car taken away, standing where he stood",
            "in a car " .. tostring(S.p:getVehicle() ~= nil) .. ", the truck still there " .. tostring(S.carLive()) .. ", at " .. S.num(S.p:getX()) .. ","
            .. S.num(S.p:getY()) .. "," .. S.num(S.p:getZ()) .. " (found " .. S.num(P.x) .. "," .. S.num(P.y) .. "," .. S.num(P.z) .. ")"
            .. (S.movedBack and "; set back from where the car left him" or ""))
    end
    local St = ZeD.Settings
    Q.check(S.optGet(St and St.hintStripOption) == S.was.hintOpt and S.optGet(St and St.moodlePlaceOption) == S.was.moodOpt,
        "put back: ZeD setup's Hint strip and Moodles settings as found",
        "Hint strip " .. tostring(S.optGet(St and St.hintStripOption)) .. " (found " .. tostring(S.was.hintOpt) .. "), Moodles "
        .. tostring(S.optGet(St and St.moodlePlaceOption)) .. " (found " .. tostring(S.was.moodOpt) .. ")")
    local w = S.windowsNow()
    local fw = (S.Focus and S.Focus.getFocusedWindow) and S.Focus.getFocusedWindow(S.pn) or nil
    Q.check(w.c == S.was.win.c and w.w == S.was.win.w and w.ct == S.was.win.ct and w.wt == S.was.win.wt and fw == S.was.focus,
        "put back: the Character and World windows open or shut as found, on their tabs, the pad where it was",
        "Character " .. tostring(w.c) .. " on " .. tostring(w.ct) .. ", World " .. tostring(w.w) .. " on " .. tostring(w.wt) .. " (found "
        .. tostring(S.was.win.c) .. " on " .. tostring(S.was.win.ct) .. ", " .. tostring(S.was.win.w) .. " on " .. tostring(S.was.win.wt)
        .. "); a window holds the pad " .. tostring(fw ~= nil) .. " (found " .. tostring(S.was.focus ~= nil) .. ")")
end

-- ===================================================================== the run
Q.step(5, S.start)
Q.step(5, S.partMedicine)
Q.step(5, S.partEat)
Q.step(5, S.partDrink)
Q.step(5, S.partWeapons)
Q.step(10, S.partReload)
Q.step(10, S.carStart)
S.waitUntil(40000, function() return S.carOff or (S.car ~= nil and S.car.state ~= "wait") end, S.carEnter)
S.waitUntil(8000, S.seatReady, function(ok) S.seatJudge("the driver's seat", ok) end)
Q.step(5, S.toPassenger)
S.waitUntil(8000, S.seatReady, function(ok) S.seatJudge("the passenger seat", ok) end)

Q.mark()
Q.step(3, S.backCar)
-- (ZEDQA_CAR_AWAY takes the car away two ticks after he is out; real time, at any frame rate)
Q.waitMs(600)
Q.step(3, S.backAll)
Q.step(5, S.backChecks)
Q.start()
