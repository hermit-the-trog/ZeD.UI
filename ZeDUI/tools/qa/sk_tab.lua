-- ZeDUI/tools/qa/sk_tab.lua  (Nov 27 2026, QA; tag sk_tab): the Character window's Skills tab ("skills") and Info tab
-- ("identity"), the gamut sweep, in the style of the Mechanics and object card sweeps (mt_tab.lua, oca_tab.lua) and the
-- Character window sweeps (ck_tab.lua, th_tab.lua). Its spec is the map ZeDUI/qa/audits/2026-11-27_map_skills_info.md
-- (section 3's cases S1-S35 and I1-I32, section 4's suspected bugs 1-16). Run after zedqa_prelude.lua and rt_kit.lua
-- (sk.txt). grep "ZEDQA sk_tab".
-- Each case single player can stage is checked in the running game against the game's own answer: the perks
-- (PerkFactory, getPerkLevel, getXP, getPerkBoost, getMultiplier), the game's own sums for the bar
-- (ISSkillProgressBar.getPreviousXpLvl and getXpForLvl), the game's own group sort (ISCharacterInfo), the skill books
-- (the script items, SkillBook, getAlreadyReadPages, getAlreadyReadBook, getLvlSkillTrained, getMaxLevelTrained, the
-- Literature list's own known and MetaKnowledge rules), the game's own Info page functions run on a stand-in
-- (ISCharacterScreen.loadBeardAndHairStyle, loadFavouriteWeapon, loadProfession, setDisplayedTraits), the weight as
-- the game rounds it, getZombieKills, the clock's date, the sandbox's start date, the trait definitions, the game's
-- queue (ISTimedActionQueue) and the game's key handler (xpUpdate.displayCharacterInfo); never ZeD's code under test.
-- Each check's words carry both sides, so a FAIL explains itself. A suspected bug is a check: PASS clears it, FAIL
-- proves it with the values.
-- How it drives the tabs: a click is the drawer's own handler at the zone (the drawer panel's onMouseDown / onMouseUp /
-- onRightMouseUp, in the drawer's frame, as the tabs stamp their zones); a hover is the pointer put on the drawer
-- (its getMouseX and getMouseY answered for the leg, the game's own pointer left alone) with the input lock on the
-- mouse; the pad's presses go through FocusManager's QA hook and its own dispatch (RT.pad + RT.padDown, RT.padDir;
-- focus by focusWhere in charTabContent), the input lock on the controller; both locks put back as found. What the
-- tabs drew is read from the draw itself (the words the drawer drew this frame, each row's level bar, the help line,
-- the pad's help words, the hover card asked for).
-- Cases (S<n>, I<n> = the map's cases; the suspected bug a case proves or clears in brackets):
--   S1  the Skills key (the game's own handler) with both windows shut, then again: open on Skills, the game's
--       window hidden; the second press shuts what it opened
--   S2  the Skills key with the windows open on Loot, then again: the second press only folds the drawer
--   S3  the Skills key while paused (every key listener fired at speed 0): does the Character window open [12]
--   S4  the tab strip's S and the D-pad wheel's Tabs slice land on Skills
--   S5  the groups and their skills against the game's ISCharacterInfo order (passive first; other languages SKIP)
--   S6  the level badge at 0, 1, 5, 9 and 10 on every skill against getPerkLevel (the badge as drawn)
--   S7  Carpentry 3 at 0, 45 and 99 percent: the bar's progress and lit segments against the game's sums; the
--       bar's help line by the mouse (hover) and the pad (rest); again with the sandbox XP multiplier at 0.5 and 5
--   S8  Carpentry 10: the bar full and yellow, the help "Carpentry 10", the card "Level 10"
--   S9  Strength 5 with its XP under the level's floor: the progress never under 0
--   S10 the boost tags for boost 0 to 3 against getPerkBoost and the game's percentages
--   S11 a book multiplier on Carpentry: nothing on the row (a NOTE, the game's arrows)
--   S12 the help lines on a row, its bar and the heading (mouse); the hover card's XP numbers against the game's
--       (mouse hover and the pad's rest)
--   S13 pin and unpin Carpentry from the row's right-click menu: the title bar's words, the row's yellow bar
--   S14 a fourth pin (three skills, then an item from the item menu): the oldest goes, the note is said
--   S15 the pin's stored key in a language-neutral form; a pin whose name the language no longer gives is shown or
--       not counted [1]; the restart in German SKIP
--   S16 the pad: A and X on a row open the pin menu; Pin from it; B with an action running stops it, B with none
--   S17 the grid's disclosure by a click and by A: rows and their stops go, the training rows move up; open again
--   S18 Find: a skill's name, a group's name, "zzz" (the empty result and its Clear by A), cleared; dimmed rows no stops
--   S19 the half card with Large text: one column or two, every name whole, Left and Right on a one-column row
--   S20 scroll follow: Down from the disclosure through the last book of an open training row, each stop in view;
--       the wheel past the focus does not snap back
--   S21 the training rows against the game's skill books (one per skill, the shown names, sorted, books per skill)
--   S22 the book states: carried, in a bag in a bag, half read, read, none, one in a crate beside him
--   S23 Carpentry 10 with no Carpentry book read: the game's Literature list counts all five known [4]
--   S24 sandbox MetaKnowledge 3: the game hides unknown books; the tab's titles [4]
--   S25 every skill's book titles and volume numbers against the game's LvlSkillTrained order [3]; other languages SKIP
--   S26 a training row folded by a click and by A; a book row does nothing by either
--   S27 a right-click and a left click on the pinned heading over a row and a training row scrolled under it [7]
--   S28 while open: Carpentry XP gained shows within the tab's 250 ms; a book picked up shows within 500 ms
--   S29 a level up while watching: the badge changes (no flash: a NOTE)
--   S30 paused: the glass takes the presses, the pad's A does nothing, the wheel still scrolls, the help still reads
--   S31 the Character info screen given back to the game (ZeD setup's Screens switch): the Skills key shows the game's
--       window; switched back, the game's window goes
--   S32 add-ons (NOTE of the extras loaded; the mods' own cases SKIP), S33 layout and the look (themes, Large text,
--       picture sk_skills_<WxH>), S34 split screen SKIP, S35 multiplayer SKIP
--   I1  ways in: the Info key (shut, again), the tab strip, the wheel, the belt's buckle, a lipstick's Make Up option
--   I2  the name (both, one empty, both empty, a 30-letter surname) against the descriptor
--   I3  the weight at 79.4, 79.6 and 80.0 against the game's round [2]
--   I4  the weight's trend sign against the game's three flags; its help line on hover
--   I5  sex for him and as a woman (the descriptor's flag set and put back)
--   I6  every vanilla profession (qaProf) against the game's loadProfession [13]; the carry permit (burger flipper
--       NOTE [14])
--   I7  hair and beard words against the game's loadBeardAndHairStyle (bald, short, long, a tied style; no beard, a
--       goatee; as a woman)
--   I8  hair colors, and a grey of 0.6 [11]
--   I9  body hair 0 to 4
--   I10 Survived for against the clock's date [6]
--   I11 favorite weapon: none, then Fav:Axe 5 and Fav:Baseball Bat 7 against the game's loadFavouriteWeapon
--   I12 kills: 10 more by the game's count, then one fire kill: the tab against getZombieKills and the fire count
--   I13 the DL number: the same after a reopen; a Cyrillic surname's first letter [10]
--   I14 the issue and expiry dates against the sandbox's start date
--   I15 traits: free, two positive, two negative, then none, against the game's own displayed traits [5, 9]
--   I16 a trait's description on hover (mouse) and on the pad's rest against its definition
--   I17 the photo: a click swaps, a drag turns without swapping, the wheel on the bust and on the full body [8]; A on
--       identity:photo
--   I18 the studio by its camera and by A on identity:studio; closed again
--   I19 the layout: wide and narrow (qaLayout), full and half card, Simple and the license (qaStyle): every zone
--       inside the tab; picture sk_info_<WxH>
--   I20 the narrow license at 220: ISS, EXP and the survived lines drawn, the permit box, inside the tab
--   I21 Hair and beard: with scissors a row and Cut queue the game's ISCutHair, Stop clears it; without a tool no
--       cut row is offered as doable; a man's trim with a razor queues ISTrimBeard
--   I22 the hair mods SKIP; I23 the make-up part with a lipstick and a mirror: Apply queues ISApplyMakeUp
--   I24 the pad: Down from the photo through every Hair and beard stop and every trait, each in view
--   I25 while open: the weight, the hair and a trait changed: the card follows within 30 frames
--   I26 paused: the glass takes the presses on the page (Cut, the switch); the model's own click (NOTE)
--   I27 the Info key with the Character info screen given back to the game: the game's page shows
--   I28 the words in the run's language (other languages SKIP); I29 themes and the text size: inside the tab;
--   I30 the game's Literature button (NOTE); I31 split screen SKIP; I32 B with a haircut running stops it
--   C15 the Info tab's gathers a second against the Skills tab's clock [15]; bug 16 (stale comments) and the
--       FEATURE_MAP drift are NOTEs at the end
--   every case: no Lua error over it; put back exactly
-- Puts back: his real skill levels and XP (every perk; drift a NOTE), the perk boosts and the Carpentry multiplier,
-- his traits (the set as found), his profession (never changed: the QA hook qaProf put back to none), the skill books
-- read (each book's pages read and the read-books list as found), his name, his look (hair color, hair and beard
-- styles, body hair, the sex flag), his weight and its three trend flags, the zombie kill count and the fire count,
-- the favorite-weapon counts, his stats (an apple bitten), the pins (the list as found), the Skills tab's grid fold,
-- training folds, Find text and scroll, the Info tab's photo, zoom, scroll and Hair and beard part, the QA hooks
-- (qaStyle, qaLayout, qaTrend, qaProf), the sandbox's MetaKnowledge and XP multiplier, ZeD setup's Character info
-- screen switch, the theme, the text size, the width cap (the half card), the input lock, the pointer, the draw
-- watchers, every thing given (bags, books, tools, the crate), the queue, game speed 1, the windows and both tabs as
-- found, the layout, where he stood, god mode and invincible as found.

if not (RT and RT.make) then
    print("ZEDQA sk_tab ERR rt_kit.lua did not run first")
    print("ZEDQA sk_tab VERDICT FAIL 1")
    print("ZEDQA sk_tab DONE")
    return
end
local Q = RT.make("sk_tab")
Q.maxMs = 2200000                    -- (the runner gives this script 2400 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, objs = {}, shots = {}, errs = 0,
            dead = false, xp = {}, said = {}, menuCalls = {}, notes = {}, stash = {} }
local H = {}
local C = {}
S.ST = ZeD and ZeD.SkillsTab
S.IT = ZeD and ZeD.IdentityTab
S.PN = ZeD and ZeD.Pins
S.TF = ZeD and ZeD.TabFind
S.F = RT.focus()
S.CRATE = "carpentry_01_16"
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.THEMES = { { key = "dark", word = "Dark" }, { key = "light", word = "Light" }, { key = "hicon", word = "High contrast" } }
S.STATS = { "HUNGER", "THIRST", "FATIGUE", "BOREDOM", "STRESS", "ENDURANCE", "UNHAPPINESS", "PANIC", "MORALE", "SANITY", "ANGER",
    "DISCOMFORT", "IDLENESS", "FOOD_SICKNESS", "POISON", "SICKNESS" }
S.CARP = { "Base.BookCarpentry1", "Base.BookCarpentry2", "Base.BookCarpentry3", "Base.BookCarpentry4", "Base.BookCarpentry5" }
S.ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }
S.PROMO = { "GRACEFUL", "OUTDOORSMAN" }
S.NEG = { "HEARTY_APPETITE", "DISORGANIZED" }
S.FREE = { "BURGLAR" }

if not (S.p and S.ST and S.IT and S.PN and S.TF and ZeD_CharacterWindow and ZeD_CharacterWindow._tabRenderers) then
    Q.check(false, "the player and ZeD's Skills tab, Info tab, pins, Find and the Character window's tab renderers are loaded")
    Q.start()
    return
end

-- ===================================================================== small helpers
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
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
-- paused as the pause button pauses (rt_inventory's way), and playing again
function H.pause(on)
    local sp = on and 0 or 1
    S.paused = on and true or nil
    pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(sp) end)
    H.speed(sp)
end
function H.list(t, max)
    local o = {}
    for i, v in ipairs(t or {}) do
        if max and i > max then o[#o + 1] = "..."; break end
        o[#o + 1] = tostring(v)
    end
    return (#o > 0) and table.concat(o, ", ") or "none"
end
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
function H.zcall(fn)
    local ok, err = pcall(fn)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(err) end
    return ok
end
function H.has(s, sub) return type(s) == "string" and type(sub) == "string" and sub ~= "" and string.find(s, sub, 1, true) ~= nil end
function H.lang() local l = "?"; pcall(function() l = tostring(Translator.getLanguage():name()) end); return l end
function H.isEN() return H.lang() == "EN" end
function H.lower(s) local o = tostring(s or ""); pcall(function() o = string.lower(o) end); return o end
function H.nums(s)
    local o = {}
    for d in string.gmatch(tostring(s or ""), "%d+") do o[#o + 1] = tonumber(d) end
    return o
end
function H.gameRound(x)
    local r = nil
    pcall(function() r = round(x, 0) end)
    if r == nil then r = math.floor(x + 0.5) end
    return r
end
function H.sameColor(a, b)
    if not (a and b) then return false end
    return math.abs((a.r or 0) - (b.r or 0)) < 0.01 and math.abs((a.g or 0) - (b.g or 0)) < 0.01 and math.abs((a.b or 0) - (b.b or 0)) < 0.01
end

-- ===================================================================== the timed-action queue (the game's)
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 12) end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end

-- ===================================================================== things
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.ft(it) local s = "?"; if H.isItem(it) then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function H.where(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getContainer() end) end; return c end
function H.onFloor(it) local wo = nil; if H.isItem(it) then pcall(function() wo = it:getWorldItem() end) end; return wo ~= nil end
function H.gone(it) return H.where(it) == nil and not H.onFloor(it) end
function H.inv() return S.p:getInventory() end
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
        if not S.found.inv0[it] then H.removeItem(it); n = n + 1 end
    end
    return n
end
-- his own things of the types the cases use are set aside, so a case sees only what it gave
function H.stashTypes(set)
    local kept = 0
    for _, it in ipairs(H.all()) do
        if set[H.ft(it)] and S.found.inv0[it] and not S.found.stashed[it] then
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
function H.lootRefresh()
    pcall(function() local lp = getPlayerLoot(S.pn); if lp and lp.refreshBackpacks then lp:refreshBackpacks() end end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
end

-- ===================================================================== a crate beside him (mt_tab's)
function H.sqAt(dx, dy)
    local sq = nil
    pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, math.floor(S.p:getZ())) end)
    return sq
end
function H.freeSq(dx, dy)
    local sq = H.sqAt(dx, dy)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
    end)
    return good and sq or nil
end
function H.used(sq) for _, c in ipairs(S.objs) do if c.sq == sq and not c.removed then return true end end; return false end
function H.mkCrate()
    for _, d in ipairs(S.NEAR) do
        local sq = H.freeSq(d[1], d[2])
        if sq and not H.used(sq) then
            local o = nil
            pcall(function() o = IsoObject.new(getCell(), sq, S.CRATE) end)
            if o then
                pcall(function() o:createContainersFromSpriteProperties() end)
                pcall(function() sq:AddTileObject(o) end)
                local c = { obj = o, sq = sq, what = "a crate (" .. S.CRATE .. " at " .. sq:getX() .. "," .. sq:getY() .. ")" }
                S.objs[#S.objs + 1] = c
                pcall(function() c.inv = o:getContainer() end)
                if c.inv then pcall(function() c.inv:setExplored(true) end); return c end
                H.rmObj(c)
            end
        end
    end
    return nil
end
function H.rmObj(c)
    if not (c and c.obj) or c.removed then return end
    local o = c.obj
    pcall(function() local ct = o:getContainer(); if ct then ct:removeAllItems() end end)
    local sq = c.sq
    pcall(function() sq = o:getSquare() or c.sq end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        pcall(function() sq:getObjects():remove(o) end)
        pcall(function() sq:RecalcProperties() end)
    end
    pcall(function() o:removeFromWorld() end)
    pcall(function() o:removeFromSquare() end)
    c.removed = true
end
function H.objLeft(c)
    if not (c and c.obj) then return false end
    local left = false
    pcall(function() left = c.sq:getObjects():contains(c.obj) end)
    return left
end

-- ===================================================================== skills (the game's own numbers)
function H.perkOf(t) local p = nil; pcall(function() p = PerkFactory.getPerk(t) end); return p or t end
function H.lvl(t) local l = 0; pcall(function() l = S.p:getPerkLevel(t) end); return l end
function H.getXP(t) local x = 0; pcall(function() x = S.p:getXp():getXP(t) end); return x end
function H.pname(t) local n = nil; pcall(function() n = H.perkOf(t):getName() end); return n end
function H.setLvl(t, n)
    pcall(function() S.p:setPerkLevelDebug(t, n) end)
    pcall(function() S.p:getXp():setXPToLevel(t, n) end)
end
-- the skill at level lvl and frac of the way to the next (by the game's own sums), XP added past any multiplier
function H.atFrac(t, lvl, frac)
    H.setLvl(t, lvl)
    if lvl >= 10 or frac <= 0 then return end
    pcall(function()
        local need = ISSkillProgressBar.getXpForLvl(H.perkOf(t), lvl)
        S.p:getXp():AddXPNoMultiplier(t, need * frac)
    end)
end
-- the game's reading of a skill's place in its level (ISSkillProgressBar's own sums): lvl, xp, prev, need, inLvl, pct
function H.gProg(t)
    local r = { lvl = H.lvl(t) }
    pcall(function()
        local perk = H.perkOf(t)
        r.xp = S.p:getXp():getXP(t)
        r.prev = ISSkillProgressBar.getPreviousXpLvl(perk, r.lvl)
        r.need = ISSkillProgressBar.getXpForLvl(perk, r.lvl)
        r.inLvl = r.xp - r.prev
        r.pct = r.inLvl / r.need
    end)
    if r.lvl >= 10 then r.pct = 1 end
    return r
end
function H.childPerks()
    local o = {}
    pcall(function()
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            if perk:getParent() ~= Perks.None then o[#o + 1] = perk end
        end
    end)
    return o
end
function H.xpSnap()
    pcall(function()
        local xp = S.p:getXp()
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            local r = { perk = perk, xp = xp:getXP(perk), lvl = S.p:getPerkLevel(perk), boost = 0 }
            pcall(function() r.boost = xp:getPerkBoost(perk) end)
            S.xp[#S.xp + 1] = r
        end
    end)
    pcall(function()
        local m = S.p:getXp():getMultiplierMap()
        S.found.multHad = m:containsKey(Perks.Woodwork) and true or false
        if S.found.multHad then S.found.multObj = m:get(Perks.Woodwork) end
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
            pcall(function() if xp:getPerkBoost(r.perk) ~= r.boost then xp:setPerkBoost(r.perk, r.boost) end end)
        end
    end)
    pcall(function()
        local m = S.p:getXp():getMultiplierMap()
        if S.found.multHad then m:put(Perks.Woodwork, S.found.multObj) elseif m:containsKey(Perks.Woodwork) then m:remove(Perks.Woodwork) end
    end)
    pcall(function() SyncXp(S.p) end)
    return grew, left
end
function H.levelsAsFound()
    local bad = 0
    pcall(function() for _, r in ipairs(S.xp) do if S.p:getPerkLevel(r.perk) ~= r.lvl then bad = bad + 1 end end end)
    return bad
end
function H.boostsAsFound()
    local bad = 0
    pcall(function() local xp = S.p:getXp(); for _, r in ipairs(S.xp) do if xp:getPerkBoost(r.perk) ~= r.boost then bad = bad + 1 end end end)
    return bad
end
function H.multNow() local m = 0; pcall(function() m = S.p:getXp():getMultiplier(Perks.Woodwork) end); return m end

-- ===================================================================== skill books (the game's)
function H.bookCatalog()
    local o = {}
    pcall(function()
        local all = getScriptManager():getAllItems()
        for i = 0, all:size() - 1 do
            local it = all:get(i)
            local lit = false
            pcall(function() lit = it:isItemType(ItemType.LITERATURE) end)
            if lit then
                local sk = nil
                pcall(function() sk = it:getSkillTrained() end)
                if sk and sk ~= "" and SkillBook[sk] then
                    local e = { ft = it:getFullName(), dn = tostring(it:getDisplayName()), skill = sk, lvl = 0, maxLvl = 0, pages = 0, item = it }
                    pcall(function() e.lvl = it:getLvlSkillTrained() end)
                    pcall(function() e.maxLvl = it:getMaxLevelTrained() end)
                    pcall(function() e.pages = it:getNumberOfPages() end)
                    pcall(function() e.hidden = (LITERATURE_HIDDEN ~= nil and LITERATURE_HIDDEN[e.ft]) and true or false end)
                    o[#o + 1] = e
                end
            end
        end
    end)
    return o
end
function H.pagesRead(ft) local n = 0; pcall(function() n = S.p:getAlreadyReadPages(ft) or 0 end); return n end
function H.setPages(ft, n) pcall(function() S.p:setAlreadyReadPages(ft, n) end) end
function H.inReadList(ft) local r = false; pcall(function() r = S.p:getAlreadyReadBook():contains(ft) and true or false end); return r end
function H.dropRead(ft) pcall(function() local l = S.p:getAlreadyReadBook(); while l:contains(ft) do l:remove(ft) end end) end
function H.carried(ft)
    local c = false
    pcall(function() c = H.inv():containsTypeRecurse(ft) and true or false end)
    if not c then for _, it in ipairs(H.all()) do if H.ft(it) == ft then c = true end end end
    return c
end
-- a book's state by the game's own getters (the four states the tab names)
function H.gameState(b)
    local rp, np = H.pagesRead(b.ft), b.pages or 0
    if (np > 0 and rp >= np) or H.inReadList(b.ft) then return "read" end
    if rp > 0 then return "reading" end
    if H.carried(b.ft) then return "collected" end
    return "missing"
end
function H.readSnap()
    local f = S.found
    f.pages = {}
    for _, b in ipairs(S.books) do f.pages[b.ft] = H.pagesRead(b.ft) end
    f.readList = {}
    pcall(function() local l = S.p:getAlreadyReadBook(); for i = 0, l:size() - 1 do f.readList[#f.readList + 1] = tostring(l:get(i)) end end)
end
function H.readBack()
    local f = S.found
    if not f.pages then return 0 end
    local n = 0
    for _, b in ipairs(S.books) do
        local was = f.pages[b.ft]
        if was ~= nil and H.pagesRead(b.ft) ~= was then H.setPages(b.ft, was); n = n + 1 end
    end
    local want = {}
    for _, s in ipairs(f.readList or {}) do want[s] = true end
    pcall(function()
        local l = S.p:getAlreadyReadBook()
        local drop = {}
        for i = 0, l:size() - 1 do local s = tostring(l:get(i)); if not want[s] then drop[#drop + 1] = s end end
        for _, s in ipairs(drop) do l:remove(s) end
        for _, s in ipairs(f.readList or {}) do if not l:contains(s) then l:add(s) end end
    end)
    return n
end
function H.readAsFound()
    local f, bad = S.found, {}
    for _, b in ipairs(S.books) do if f.pages and f.pages[b.ft] ~= nil and H.pagesRead(b.ft) ~= f.pages[b.ft] then bad[#bad + 1] = b.ft end end
    local n = 0
    pcall(function() n = S.p:getAlreadyReadBook():size() end)
    if n ~= #(f.readList or {}) then bad[#bad + 1] = "the read-books list (" .. n .. ", found " .. #(f.readList or {}) .. ")" end
    for _, s in ipairs(f.readList or {}) do if not H.inReadList(s) then bad[#bad + 1] = s end end
    return #bad == 0, H.list(bad, 8)
end
-- a book of the tab's (its shown title) matched to the game's book of that skill (the title is the display name, or
-- its end after the skill's words were taken off)
function H.matchBook(skill, title)
    local t = H.lower(title)
    for _, b in ipairs(S.books) do
        if b.skill == skill then
            local d = H.lower(b.dn)
            if d == t or (#t > 0 and #d >= #t and string.sub(d, #d - #t + 1) == t) then return b end
        end
    end
    return nil
end
function H.booksOf(skill) local o = {}; for _, b in ipairs(S.books) do if b.skill == skill then o[#o + 1] = b end end; return o end

-- ===================================================================== traits, look, weight, kills, favorites, stats
function H.knownTraits()
    local o = {}
    pcall(function()
        local l = S.p:getCharacterTraits():getKnownTraits()
        for i = 0, l:size() - 1 do o[#o + 1] = l:get(i) end
    end)
    return o
end
function H.traitSet(key, on)
    pcall(function()
        local ct = CharacterTrait[key]
        if not ct then return end
        if on and not S.p:hasTrait(ct) then S.p:getCharacterTraits():add(ct) end
        if not on and S.p:hasTrait(ct) then S.p:getCharacterTraits():remove(ct) end
    end)
end
function H.traitsBack()
    local want = {}
    for _, t in ipairs(S.found.traits or {}) do want[tostring(t)] = t end
    local have = {}
    for _, t in ipairs(H.knownTraits()) do
        have[tostring(t)] = true
        if not want[tostring(t)] then pcall(function() S.p:getCharacterTraits():remove(t) end) end
    end
    for k, t in pairs(want) do if not have[k] then pcall(function() S.p:getCharacterTraits():add(t) end) end end
end
function H.traitsAsFound()
    local want, have, bad = {}, {}, {}
    for _, t in ipairs(S.found.traits or {}) do want[tostring(t)] = true end
    for _, t in ipairs(H.knownTraits()) do have[tostring(t)] = true; if not want[tostring(t)] then bad[#bad + 1] = "+" .. tostring(t) end end
    for k in pairs(want) do if not have[k] then bad[#bad + 1] = "-" .. k end end
    return #bad == 0, H.list(bad, 8)
end
function H.hv() local v = nil; pcall(function() v = S.p:getHumanVisual() end); return v end
-- the hair color as three numbers (a color object may be a new one at each read)
function H.rgb(c) local o = nil; pcall(function() o = { c:getRedFloat(), c:getGreenFloat(), c:getBlueFloat() } end); return o end
function H.hairIs(rgb)
    local now = nil
    pcall(function() now = H.rgb(H.hv():getHairColor()) end)
    if not (now and rgb) then return now == nil and rgb == nil end
    return math.abs(now[1] - rgb[1]) < 0.002 and math.abs(now[2] - rgb[2]) < 0.002 and math.abs(now[3] - rgb[3]) < 0.002
end
function H.lookSnap()
    local f = S.found
    pcall(function() local d = S.p:getDescriptor(); f.fore, f.sur = d:getForename(), d:getSurname() end)
    pcall(function()
        local hv = H.hv()
        f.hairColor = hv:getHairColor()
        f.hairRGB = H.rgb(f.hairColor)
        f.hairModel = hv:getHairModel()
        f.beardModel = hv:getBeardModel()
        f.bodyHair = hv:getBodyHairIndex()
    end)
    pcall(function() f.female = S.p:isFemale() and true or false end)
    pcall(function()
        local n = S.p:getNutrition()
        f.weight = n:getWeight()
        f.incW, f.incWL, f.decW = n:isIncWeight(), n:isIncWeightLot(), n:isDecWeight()
    end)
    pcall(function() f.kills = S.p:getZombieKills() end)
    local md = S.p:getModData()
    f.killFire = (type(md.ZeD_Kills) == "table") and md.ZeD_Kills.fire or nil
    f.favs = {}
    for k, v in pairs(md) do if type(k) == "string" and string.sub(k, 1, 4) == "Fav:" then f.favs[k] = v end end
end
function H.lookBack()
    local f = S.found
    local changed = false
    pcall(function()
        local d = S.p:getDescriptor()
        if d:getForename() ~= f.fore then d:setForename(f.fore) end
        if d:getSurname() ~= f.sur then d:setSurname(f.sur) end
    end)
    pcall(function()
        local hv = H.hv()
        if f.hairColor and not H.hairIs(f.hairRGB) then hv:setHairColor(f.hairColor); changed = true end
        if hv:getHairModel() ~= f.hairModel then hv:setHairModel(f.hairModel); changed = true end
        if hv:getBeardModel() ~= f.beardModel then hv:setBeardModel(f.beardModel); changed = true end
        if hv:getBodyHairIndex() ~= f.bodyHair then hv:setBodyHairIndex(f.bodyHair); changed = true end
    end)
    if changed then pcall(function() S.p:resetModelNextFrame() end); pcall(function() triggerEvent("OnClothingUpdated", S.p) end) end
    pcall(function()
        local n = S.p:getNutrition()
        if f.weight and math.abs(n:getWeight() - f.weight) > 0.0001 then n:setWeight(f.weight) end
        n:setIncWeight(f.incW and true or false)
        n:setIncWeightLot(f.incWL and true or false)
        n:setDecWeight(f.decW and true or false)
    end)
    pcall(function() if f.kills and S.p:getZombieKills() ~= f.kills then S.p:setZombieKills(f.kills) end end)
    local md = S.p:getModData()
    if type(md.ZeD_Kills) == "table" and S.back.fire then md.ZeD_Kills.fire = f.killFire or 0 end
    local drop = {}
    for k in pairs(md) do if type(k) == "string" and string.sub(k, 1, 4) == "Fav:" and f.favs[k] == nil then drop[#drop + 1] = k end end
    for _, k in ipairs(drop) do md[k] = nil end
    for k, v in pairs(f.favs or {}) do md[k] = v end
end
function H.lookAsFound()
    local f, bad = S.found, {}
    pcall(function() local d = S.p:getDescriptor(); if d:getForename() ~= f.fore or d:getSurname() ~= f.sur then bad[#bad + 1] = "name" end end)
    pcall(function()
        local hv = H.hv()
        if hv:getHairModel() ~= f.hairModel then bad[#bad + 1] = "hair " .. tostring(hv:getHairModel()) end
        if hv:getBeardModel() ~= f.beardModel then bad[#bad + 1] = "beard " .. tostring(hv:getBeardModel()) end
        if hv:getBodyHairIndex() ~= f.bodyHair then bad[#bad + 1] = "body hair" end
        if f.hairColor and not H.hairIs(f.hairRGB) then bad[#bad + 1] = "hair color" end
    end)
    -- (the game's own nutrition moves the weight a little as the hours pass: a few grams are not a staging left)
    pcall(function() if math.abs(S.p:getNutrition():getWeight() - f.weight) > 0.05 then bad[#bad + 1] = "weight " .. H.n2(S.p:getNutrition():getWeight()) end end)
    pcall(function() if S.p:getZombieKills() ~= f.kills then bad[#bad + 1] = "kills" end end)
    local md = S.p:getModData()
    for k in pairs(md) do if type(k) == "string" and string.sub(k, 1, 4) == "Fav:" and md[k] ~= f.favs[k] then bad[#bad + 1] = k end end
    for k, v in pairs(f.favs or {}) do if md[k] ~= v then bad[#bad + 1] = k end end
    return #bad == 0, H.list(bad, 8)
end
function H.statsSnap()
    S.found.stats = {}
    pcall(function()
        local stt = S.p:getStats()
        for _, k in ipairs(S.STATS) do pcall(function() S.found.stats[k] = stt:get(CharacterStat[k]) end) end
    end)
end
function H.statsBack()
    pcall(function()
        local stt = S.p:getStats()
        for k, v in pairs(S.found.stats or {}) do pcall(function() stt:set(CharacterStat[k], v) end) end
    end)
end
-- the pins as found (a copy of each entry)
function H.pinsCopy(src)
    if type(src) ~= "table" then return nil end
    local o = {}
    for i, e in ipairs(src) do local c = {}; for k, v in pairs(e) do c[k] = v end; o[i] = c end
    return o
end
function H.pinsBack()
    local md = S.p:getModData()
    md.ZeD_Pins = H.pinsCopy(S.found.pins)
    md.ZeD_PinnedSkills = H.pinsCopy(S.found.oldPins)
    local w = RT.cw()
    if w then pcall(function() w._pinnedSkills = S.PN.skillNames(S.p) end) end
end
function H.pinsClear()
    S.p:getModData().ZeD_Pins = {}
    local w = RT.cw()
    if w then w._pinnedSkills = {} end
end
function H.pinIds() local o = {}; for _, e in ipairs(S.p:getModData().ZeD_Pins or {}) do o[#o + 1] = tostring(e.k) .. ":" .. tostring(e.id) end; return o end
function H.titleTexts() local o = {}; local w = RT.cw(); for _, st in ipairs((w and w.titleStats) or {}) do o[#o + 1] = tostring(st.text or "") end; return o end
-- sandbox options (the game's)
function H.sbOpt(name) local o = nil; pcall(function() o = getSandboxOptions():getOptionByName(name) end); return o end
function H.sbSet(name, v)
    local o = H.sbOpt(name)
    if not o then return false end
    S.found.sb = S.found.sb or {}
    if S.found.sb[name] == nil then S.found.sb[name] = { v = H.optVal(o) } end
    S.sbAll = S.sbAll or {}
    if S.sbAll[name] == nil then S.sbAll[name] = { v = S.found.sb[name].v } end
    local ok = pcall(function() o:setValue(v) end)
    pcall(function() SandboxVars[name] = v end)
    return ok
end
function H.sbBack()
    for name, r in pairs(S.found.sb or {}) do
        local o = H.sbOpt(name)
        if o and r.v ~= nil then pcall(function() o:setValue(r.v) end); pcall(function() SandboxVars[name] = r.v end) end
    end
    S.found.sb = {}
end
-- ZeD setup's switch that gives the Character info screen back to the game (2 = the game's own)
function H.screenOpt() return ZeD.Settings and ZeD.Settings.screenOptions and ZeD.Settings.screenOptions.charinfo end
function H.screenSet(v)
    local o = H.screenOpt()
    if not o then return false end
    if S.found.screen == nil then S.found.screen = H.optVal(o) or 1 end
    pcall(function() o:setValue(v) end)
    pcall(function() ZeD.Safe.reread() end)
    S.back.screen = true
    return true
end
function H.screenBack()
    if not S.back.screen then return end
    S.back.screen = nil
    local o = H.screenOpt()
    if o then pcall(function() o:setValue(S.found.screen or 1) end) end
    pcall(function() ZeD.Safe.reread() end)
    pcall(function() local gw = getPlayerInfoPanel(S.pn); if gw and gw:getIsVisible() then gw:setVisible(false); gw:removeFromUIManager() end end)
end
function H.gameWinUp() local v = false; pcall(function() local gw = getPlayerInfoPanel(S.pn); v = gw ~= nil and gw:getIsVisible() and true or false end); return v end
-- the game's own key handler for one of its Character info keys (it returns at once while paused)
function H.keyOf(name) local k = nil; pcall(function() k = getCore():getKey(KeybindId[name]) end); return k end
function H.gameKey(name)
    local k = H.keyOf(name)
    if not k then return false end
    return H.zcall(function() xpUpdate.displayCharacterInfo(k) end)
end

-- ===================================================================== the tabs (read from their state and their draw)
function H.tabText()
    local w = RT.cw()
    return "open " .. tostring(RT.isOpen()) .. ", tab " .. tostring(w and w._activeTab) .. ", mode " .. tostring(w and w._drawerMode)
        .. ", drawer open " .. tostring(w and w._drawerOpen)
end
function H.on(id)
    local w = RT.cw()
    return w ~= nil and RT.isOpen() and w._activeTab == id and w._drawerMode == "tab" and w._drawerOpen == true
end
function H.drawn(id)
    if not H.on(id) then return false end
    local r = (id == "skills") and S.skRect or S.idRect
    return r ~= nil and getTimestampMs() - r.t < 400
end
-- queue: the pair open on tab id (the strip pressed, openTab as a fall-back); T.off when it does not draw
function H.toTab(T, id, label)
    H.step(2, function()
        if T.off then return end
        RT.pairOpen()
    end)
    H.wait(5000, function() return T.off or (RT.cw() ~= nil and RT.isOpen()) end, function() end)
    H.step(2, function()
        if T.off then return end
        local w = RT.cw()
        if w and w._drawerMode == "item" then pcall(ZeD_CharacterWindow.openTab, S.pn, "loot") end
    end)
    H.step(2, function()
        if T.off or H.on(id) then return end
        if not RT.charTab(id) then pcall(ZeD_CharacterWindow.openTab, S.pn, id) end
    end)
    H.wait(6000, function()
        if T.off then return true end
        if not H.on(id) and RT.cw() and RT.cw()._drawerOpen == false then RT.charTab(id) end
        return H.drawn(id)
    end, function(ok)
        if T.off then return end
        if not Q.check(ok, label .. ": the " .. id .. " tab is open and draws", H.tabText()) then T.off = true end
    end)
end
function H.skData() local w = RT.cw(); return w and w._skillsCache end
function H.skillOf(name)
    for _, g in ipairs((H.skData() and H.skData().categories) or {}) do
        for _, s in ipairs(g.skills or {}) do if s.name == name then return s, g end end
    end
    return nil
end
function H.skFresh() local w = RT.cw(); if w then w._skillsCache = nil; w._trainingCache = nil end end
function H.rowZ(name) local w = RT.cw(); for _, z in ipairs((w and w._skillRowZones) or {}) do if z.name == name then return z end end; return nil end
function H.trZones() local w = RT.cw(); return (w and w._trainingGroupZones) or {} end
function H.trZ(id) for _, z in ipairs(H.trZones()) do if z.id == id then return z end end; return nil end
function H.trRow(label) for _, z in ipairs(H.trZones()) do if z.label == label and not z.book then return z end end; return nil end
function H.trGroup(label) local w = RT.cw(); for _, g in ipairs((w and w._trainingCache) or {}) do if g.label == label then return g end end; return nil end
function H.view() local w = RT.cw(); return w and w._skillsHoverView end
function H.inView(z, v)
    v = v or H.view()
    if not (z and v) then return false end
    return z.y >= v.y - 1 and z.y + z.h <= v.y + v.h + 1
end
-- the words drawn inside a zone's rows, this frame
function H.textsIn(rec, z)
    local o = {}
    if not z then return o end
    for _, t in ipairs(rec or {}) do
        if t.y >= z.y - 1 and t.y < z.y + z.h and t.x >= z.x - 2 and t.x <= z.x + z.w + 2 then o[#o + 1] = t end
    end
    return o
end
function H.segIn(z)
    if not z then return nil end
    for _, s in ipairs(S.skSeg or {}) do
        if s.y >= z.y - 1 and s.y < z.y + z.h and s.x >= z.x and s.x <= z.x + z.w then return s end
    end
    return nil
end
-- the badge's number as drawn: the digits nearest the row's left edge
function H.badgeIn(z)
    local best = nil
    for _, t in ipairs(H.textsIn(S.skT, z)) do
        if string.match(t.s, "^%d+$") and (best == nil or t.x < best.x) then best = t end
    end
    return best and tonumber(best.s) or nil
end
function H.idData() local w = RT.cw(); return w and w._identityCache end
function H.idFresh() local w = RT.cw(); if w then w._identityCache = nil end end
function H.idWait(T, label, cond)
    H.step(2, function() if not T.off then H.idFresh() end end)
    H.wait(3000, function() return T.off or (H.idData() ~= nil and (cond == nil or cond())) end, function(ok)
        if T.off then return end
        if not ok then H.note(label .. ": the Info tab's data did not come in 3 s (" .. H.tabText() .. ")") end
    end)
end
function H.skWait(T, label, cond)
    H.step(2, function() if not T.off then H.skFresh() end end)
    H.wait(3000, function() return T.off or (H.skData() ~= nil and S.skRect ~= nil and getTimestampMs() - S.skRect.t < 300 and (cond == nil or cond())) end, function(ok)
        if T.off then return end
        if not ok then H.note(label .. ": the Skills tab's data did not come in 3 s (" .. H.tabText() .. ")") end
    end)
    Q.waitMs(120)
end

-- ===================================================================== the draw and the words, watched (on for the run)
-- S.skRect / S.idRect: each tab's rectangle as the window draws it; S.skT / S.idT: the words the drawer drew in the
-- tab last frame { s, x, y }; S.skSeg: each level bar drawn { x, y, w, k, c }; S.skHelp / S.idHelp: the help line's
-- words set in the tab last frame; S.skPad: the pad's help words; S.skCard: the hover card asked for { key, card };
-- S.idHover: the trait or hair card asked for; S.menuCalls: the pin menus asked for; S.notes: the notes said over his
-- head; S.idGathers: the Info tab's data gathers
function H.recDraw(panel, rec)
    local own = rawget(panel, "drawText")
    local base = panel.drawText
    panel.drawText = function(self, text, tx, ty, ...)
        rec[#rec + 1] = { s = tostring(text), x = tx or 0, y = ty or 0 }
        return base(self, text, tx, ty, ...)
    end
    return own
end
function H.wrapOn()
    if S.w0 then return end
    local R = ZeD_CharacterWindow._tabRenderers
    local W = { R = R, sk = R.skills, id = R.identity, help = ZeD.Help and ZeD.Help.set, pad = ZeD.Atoms.padHelp,
                card = ZeD.Atoms.requestDetailCard, seg = ZeD.Atoms.drawSegFill, hb = ZeD.HairBeard and ZeD.HairBeard.hoverCard,
                note = ZeD.Bubbles and ZeD.Bubbles.note, menu = S.PN.skillMenu, gather = S.IT.gatherData,
                text = ZeD.Text and ZeD.Text.draw }
    S.w0 = W
    W.skFn = function(panel, win, x, y, w, h)
        S.skRect = { x = x, y = y, w = w, h = h, t = getTimestampMs() }
        local rec, segs = {}, {}
        S.skSegRec, S.skHelpF, S.skPadF, S.skCardF = segs, nil, nil, nil
        local own = H.recDraw(panel, rec)
        S.inSk = true
        local ok, res = pcall(W.sk, panel, win, x, y, w, h)
        S.inSk = false
        panel.drawText = own
        S.skT, S.skSeg, S.skHelp, S.skPad, S.skCard = rec, segs, S.skHelpF, S.skPadF, S.skCardF
        S.skFrames = (S.skFrames or 0) + 1
        if not ok then S.tabErrs = (S.tabErrs or 0) + 1; S.tabErrLast = res; error(res, 0) end
        return res
    end
    W.idFn = function(panel, win, x, y, w, h)
        S.idRect = { x = x, y = y, w = w, h = h, t = getTimestampMs() }
        local rec = {}
        S.idHelpF, S.idHoverF, S.idRecF = nil, nil, rec
        local own = H.recDraw(panel, rec)
        S.inId = true
        local ok, res = pcall(W.id, panel, win, x, y, w, h)
        S.inId = false
        S.idRecF = nil
        panel.drawText = own
        S.idT, S.idHelp, S.idHover = rec, S.idHelpF, S.idHoverF
        S.idFrames = (S.idFrames or 0) + 1
        if not ok then S.tabErrs = (S.tabErrs or 0) + 1; S.tabErrLast = res; error(res, 0) end
        return res
    end
    W.helpFn = function(panel, text, ...)
        if S.inSk then S.skHelpF = tostring(text) elseif S.inId then S.idHelpF = tostring(text) end
        return W.help(panel, text, ...)
    end
    W.padFn = function(panel, text, ...)
        if S.inSk then S.skPadF = tostring(text) elseif S.inId then S.idPadF = tostring(text) end
        return W.pad(panel, text, ...)
    end
    W.cardFn = function(owner, key, card, ...)
        if S.inSk then S.skCardF = { key = tostring(key), card = card } end
        return W.card(owner, key, card, ...)
    end
    W.segFn = function(panel, x, y, w, h, n, k, color)
        if S.inSk and S.skSegRec then local l = S.skSegRec; l[#l + 1] = { x = x or 0, y = y or 0, w = w or 0, k = k, c = color } end
        return W.seg(panel, x, y, w, h, n, k, color)
    end
    W.hbFn = function(panel, win, key, title, body, ...)
        if S.inId then S.idHoverF = { key = tostring(key), title = tostring(title), body = body } end
        return W.hb(panel, win, key, title, body, ...)
    end
    W.noteFn = function(pn, msg, ...)
        S.notes[#S.notes + 1] = tostring(msg)
        return W.note(pn, msg, ...)
    end
    W.menuFn = function(pn, name, label, x, y)
        S.menuCalls[#S.menuCalls + 1] = { name = tostring(name), t = getTimestampMs() }
        if S.menuStub then return end
        return W.menu(pn, name, label, x, y)
    end
    W.gFn = function(...)
        S.idGathers = (S.idGathers or 0) + 1
        return W.gather(...)
    end
    -- (the license draws its words with ZeD's own text drawer, not the panel's)
    W.textFn = function(panel, font, s, tx, ty, ...)
        if S.inId and S.idRecF then local l = S.idRecF; l[#l + 1] = { s = tostring(s), x = tx or 0, y = ty or 0, sdf = true } end
        return W.text(panel, font, s, tx, ty, ...)
    end
    if W.text then ZeD.Text.draw = W.textFn end
    R.skills, R.identity = W.skFn, W.idFn
    if W.help then ZeD.Help.set = W.helpFn end
    ZeD.Atoms.padHelp = W.padFn
    ZeD.Atoms.requestDetailCard = W.cardFn
    ZeD.Atoms.drawSegFill = W.segFn
    if W.hb then ZeD.HairBeard.hoverCard = W.hbFn end
    if W.note then ZeD.Bubbles.note = W.noteFn end
    S.PN.skillMenu = W.menuFn
    S.IT.gatherData = W.gFn
end
function H.wrapOff()
    local W = S.w0
    if not W then return end
    local R = W.R
    if R.skills == W.skFn then R.skills = W.sk end
    if R.identity == W.idFn then R.identity = W.id end
    if W.help and ZeD.Help.set == W.helpFn then ZeD.Help.set = W.help end
    if ZeD.Atoms.padHelp == W.padFn then ZeD.Atoms.padHelp = W.pad end
    if ZeD.Atoms.requestDetailCard == W.cardFn then ZeD.Atoms.requestDetailCard = W.card end
    if ZeD.Atoms.drawSegFill == W.segFn then ZeD.Atoms.drawSegFill = W.seg end
    if W.hb and ZeD.HairBeard.hoverCard == W.hbFn then ZeD.HairBeard.hoverCard = W.hb end
    if W.note and ZeD.Bubbles.note == W.noteFn then ZeD.Bubbles.note = W.note end
    if S.PN.skillMenu == W.menuFn then S.PN.skillMenu = W.menu end
    if S.IT.gatherData == W.gFn then S.IT.gatherData = W.gather end
    if W.text and ZeD.Text.draw == W.textFn then ZeD.Text.draw = W.text end
    S.w0 = nil
end
function H.wrapped()
    local W = S.w0
    if not W then return true end
    return W.R.skills == W.sk and ZeD.Atoms.drawSegFill == W.seg and S.PN.skillMenu == W.menu
end

-- ===================================================================== the pointer (a hover) and the presses
-- the pointer put on the drawer at (x, y) in its frame: the drawer's own reading of the pointer answers it, and the
-- game's pointer reads there too; the input lock on the mouse (a hover counts only with the mouse in use)
function H.dp() local w = RT.cw(); return w and w._drawerPanel end
function H.hoverOn(x, y)
    local dp = H.dp()
    if not dp then return false end
    H.hoverOff()
    local ax, ay = 0, 0
    pcall(function() ax, ay = dp:getAbsoluteX(), dp:getAbsoluteY() end)
    S.hov = { dp = dp, gx = rawget(dp, "getMouseX"), gy = rawget(dp, "getMouseY"), mo = rawget(dp, "isMouseOver"), mx = getMouseX, my = getMouseY }
    dp.getMouseX = function() return x end
    dp.getMouseY = function() return y end
    dp.isMouseOver = function() return true end
    getMouseX = function() return ax + x end
    getMouseY = function() return ay + y end
    return true
end
function H.hoverOff()
    local h = S.hov
    if not h then return end
    S.hov = nil
    h.dp.getMouseX, h.dp.getMouseY, h.dp.isMouseOver = h.gx, h.gy, h.mo
    getMouseX, getMouseY = h.mx, h.my
end
function H.mid(z) return z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2) end
function H.clickAt(x, y)
    local dp = H.dp()
    if not dp then return false end
    H.zcall(function() dp:onMouseDown(x, y) end)
    H.zcall(function() dp:onMouseUp(x, y) end)
    return true
end
function H.rclickAt(x, y)
    local dp = H.dp()
    if not dp then return false end
    H.zcall(function() dp:onRightMouseDown(x, y) end)
    H.zcall(function() dp:onRightMouseUp(x, y) end)
    return true
end
function H.wheel(del) local dp = H.dp(); if dp then H.zcall(function() dp:onMouseWheel(del) end) end end
-- queue: the zone getZ() scrolled into the Skills view by the wheel (as a player brings a row into view to click it)
function H.intoView(T, getZ)
    H.wait(4000, function()
        if T.off then return true end
        local z, v = getZ(), H.view()
        if not (z and v) then return false end
        local my = z.y + math.floor(z.h / 2)
        if my < v.y + 2 then H.wheel(-1); return false end
        if my > v.y + v.h - 2 then H.wheel(1); return false end
        return true
    end, function(ok) T.inView = ok end)
end
function H.ctx() local c = nil; pcall(function() c = getPlayerContextMenu(S.pn) end); return c end
function H.ctxVisible() local v = false; pcall(function() local c = H.ctx(); v = c ~= nil and c:isAnyVisible() and true or false end); return v end
function H.ctxOpt(name) local c = H.ctx(); local o = nil; if c then pcall(function() if c:isAnyVisible() then o = c:getOptionFromName(name) end end) end; return o end
function H.closeMenu() pcall(function() local c = H.ctx(); if c and c:isAnyVisible() then c:hideAndChildren() end end) end
function H.pickOpt(name) local o = H.ctxOpt(name); if o and o.onSelect then H.zcall(function() o.onSelect(o.target) end); return true end; return false end

-- ===================================================================== the pad (ck_tab's, on the Character window)
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
function H.lockSet(mode)
    local Det = ZeD.Input and ZeD.Input.Detector
    if not (Det and Det.setLockedMode) then return false end
    if S.lockWas == nil then S.lockWas = H.lockFound() end
    pcall(Det.setLockedMode, mode)
    S.back.lock = true
    return true
end
function H.lockBack()
    if not S.back.lock then return end
    S.back.lock = nil
    for _, b in ipairs({ "A", "B", "X", "Y" }) do RT.pad(b, nil) end
    pcall(function() S.F.releaseFocus(S.pn) end)
    local Det = ZeD.Input and ZeD.Input.Detector
    pcall(function()
        Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
    end)
end
function H.padOn()
    if not H.lockSet("gamepad") then return false end
    local w = RT.cw()
    if w and S.F.claimFocus then pcall(S.F.claimFocus, w) end
    return true
end
function H.mouseOn() return H.lockSet("kbm") end
function H.stops()
    local w = RT.cw()
    for _, z in ipairs((w and w._focusRing) or {}) do if z.zone == "charTabContent" then return z.elements or {} end end
    return {}
end
function H.stopOf(id) for _, e in ipairs(H.stops()) do if e.id == id then return e end end; return nil end
function H.stopIds(pre, max)
    local o = {}
    for _, e in ipairs(H.stops()) do
        if pre == nil or string.sub(tostring(e.id), 1, #pre) == pre then o[#o + 1] = tostring(e.id) end
    end
    return H.list(o, max or 16)
end
function H.focusedId() local el = nil; pcall(function() el = S.F.getFocusedElement(RT.cw()) end); return el and el.id or nil end
function H.focusedEl() local el = nil; pcall(function() el = S.F.getFocusedElement(RT.cw()) end); return el end
function H.focusEl(id)
    local w = RT.cw()
    if not (w and S.F and S.F.focusWhere and id) then return false end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "charTabContent", function(el) return el.id == id end) end)
    return e ~= nil
end
-- a tap queued on the Character window: down through the QA hook and FocusManager's dispatch, up 4 frames later
function H.tap(name, joy, gate)
    local st = {}
    H.step(1, function()
        local w = RT.cw()
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
function H.tapX(gate) H.tap("X", "XButton", gate) end
-- queue: the D-pad pressed dir from the focused stop, then a settle of 4 frames; walk(T) after each settle says
-- whether to stop (true), at most max presses
function H.walk(T, dir, max, walk)
    H.step(2, function() T.wk = { phase = "press", n = 0, k = 0 } end)
    H.wait(120000, function()
        if T.off then return true end
        local W = T.wk
        if W.phase == "press" then
            RT.padDir(dir, RT.cw())
            W.n = W.n + 1
            W.phase, W.k = "settle", 0
            return false
        end
        W.k = W.k + 1
        if W.k < 4 then return false end
        local okw, done = pcall(walk, T)
        if not okw then S.errs = S.errs + 1; S.zerr = S.zerr or ("the walk's reading: " .. tostring(done)); return true end
        if done or W.n >= max then return true end
        W.phase = "press"
        return false
    end, function() end)
end

-- ===================================================================== settings, pictures, the half card (ck_tab's)
function H.theme(key)
    local o = H.zopt("baseTheme")
    local i = nil
    for k, v in ipairs(ZeD.Settings.baseKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.back.theme = true
end
function H.themeBack()
    if not S.back.theme then return end
    S.back.theme = nil
    local o = H.zopt("baseTheme")
    if o and S.found.baseIdx then pcall(function() o:setValue(S.found.baseIdx) end) end
    pcall(ZeD.applyTheme, S.found.base, nil, nil)
end
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
        if ok then S.shots[#S.shots + 1] = file; H.note("picture Zomboid/Screenshots/" .. file .. "; the game " .. what)
        else H.note("the picture " .. name .. " was not taken: " .. tostring(e)) end
        H.park(false)
    end)
    Q.waitMs(1200)
end
function H.isHalf() local w = RT.cw(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(220)) <= 1 end
function H.isFull() local w = RT.cw(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(480)) <= 1 end
function H.halfOn(T)
    H.step(2, function()
        T.half = nil
        if T.off then return end
        local w = RT.cw()
        if not H.isHalf() and w then
            if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
            S.layoutTouched = true
            w._maxWinW = ZeD.T.px(620)
        end
        T.hs = { last = -1, n = 0 }
    end)
    H.wait(5000, function()
        if T.off then return true end
        local w = RT.cw()
        local e = math.floor((w and w._drawerEffW) or 0)
        if e == T.hs.last then T.hs.n = T.hs.n + 1 else T.hs.last, T.hs.n = e, 0 end
        return T.hs.n >= 6 and H.isHalf()
    end, function(ok)
        if T.off then return end
        T.half = ok
        if not ok then Q.skip(T.L .. ": the half card (220)", "the Character window would not hold the half card here (the drawer is "
            .. math.floor((RT.cw() and RT.cw()._drawerEffW) or 0) .. " px)") end
    end)
end
function H.halfBack()
    if not S.back.maxW then return end
    local w = RT.cw()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end
-- every zone of the list drawn in the view lies inside the tab's rectangle; RT.bounds after
function H.zonesInside(label, rect, zones, view)
    if not (rect and getTimestampMs() - rect.t < 1000) then Q.skip(label .. ": every zone inside the tab", "the tab's rectangle was not read"); return end
    local bad, n = {}, 0
    for _, z in ipairs(zones or {}) do
        local shown = (not view) or (z.y + z.h > view.y and z.y < view.y + view.h)
        if shown and (z.w or 0) > 0 then
            n = n + 1
            if z.x < rect.x - 1 or z.x + z.w > rect.x + rect.w + 1 then if #bad < 6 then bad[#bad + 1] = tostring(z.id or z.name) .. " " .. math.floor(z.x) .. "+" .. math.floor(z.w) end end
        end
    end
    Q.check(#bad == 0, label .. ": every drawn zone lies inside the tab (" .. math.floor(rect.x) .. "+" .. math.floor(rect.w) .. " px)", n .. " zones; out: " .. H.list(bad))
    RT.bounds(Q, label)
end

-- ===================================================================== a case's start and end
-- the tabs as every case starts: the grid open, no training row open, no Find text, scrolled to the top, the bust, the
-- QA hooks off
function H.tabsReset()
    local w = RT.cw()
    S.IT.qaStyle, S.IT.qaLayout, S.IT.qaTrend, S.IT.qaProf = nil, nil, nil, nil
    if not w then return end
    w._skillsGridExpanded = true
    w._trainingExpanded = {}
    pcall(function() S.TF.clear(w, "skills") end)
    w._identityPhotoExpanded = false
    w._identityCustomZoom = 0
    pcall(function() w._skillsScroll:setScrollPos(0) end)
    pcall(function() w._identityScroll:setScrollPos(0) end)
    H.skFresh()
    H.idFresh()
end
function H.legClean()
    if S.paused then H.pause(false) end
    H.speed(1)
    H.qstop()
    H.hoverOff()
    H.lockBack()
    H.park(false)
    H.closeMenu()
    S.menuStub = nil
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    S.caseMade = {}
    H.sweepNew()
    H.lootRefresh()
end
function H.caseStart(T)
    S.caseMade, S.notes, S.menuCalls = {}, {}, {}
    S.caseObjs = #S.objs
    H.legClean()
    T.t0case = getTimestampMs()
end
-- everything a case may have changed, back as found
function H.restore()
    H.xpBack()
    H.readBack()
    H.lookBack()
    H.traitsBack()
    H.pinsBack()
    H.statsBack()
    H.sbBack()
    H.screenBack()
end
function H.caseEnd(label)
    H.step(2, function()
        H.legClean()
        H.halfBack()
        H.themeBack()
        H.sizeBack()
        for i = (S.caseObjs or 0) + 1, #S.objs do H.rmObj(S.objs[i]) end
        pcall(function() if ZeD.Studio and ZeD.Studio.isOpen() then ZeD.Studio.close() end end)
        H.restore()
        H.tabsReset()
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

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        if not (S.F and S.F.focusWhere and ISTimedActionQueue and ISSkillProgressBar and ISCharacterScreen and xpUpdate and PerkFactory and SkillBook) then
            S.dead = true
            Q.check(false, "setup: the pad's focus manager and the game's skill, Info page and key code are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "sk_tab") end
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
        pcall(function() f.inst = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
        pcall(function() f.god = S.p:isGodMod() and true or false; S.p:setGodMod(true) end)
        pcall(function() f.invinc = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
        f.base, f.baseIdx = ZeD.currentBase, H.optVal(H.zopt("baseTheme"))
        f.size, f.sizeIdx = ZeD.currentSize, H.optVal(H.zopt("textSize"))
        S.lockWas = H.lockFound()
        H.xpSnap()
        S.books = H.bookCatalog()
        H.readSnap()
        f.traits = H.knownTraits()
        H.lookSnap()
        H.statsSnap()
        local md = S.p:getModData()
        f.pins, f.oldPins = H.pinsCopy(md.ZeD_Pins), H.pinsCopy(md.ZeD_PinnedSkills)
        f.qa = { style = S.IT.qaStyle, layout = S.IT.qaLayout, trend = S.IT.qaTrend, prof = S.IT.qaProf }
        f.screen = H.optVal(H.screenOpt())
        RT.pairOpen()
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        local cw, ww = RT.cw(), RT.ww()
        f.ctab, f.wtab = cw and cw._activeTab, ww and ww._activeTab
        f.maxW = cw and cw._maxWinW
        if cw then
            f.grid = cw._skillsGridExpanded
            f.trExp = {}
            for k, v in pairs(cw._trainingExpanded or {}) do f.trExp[k] = v end
            f.find = S.TF.text(cw, "skills")
            f.photo = cw._identityPhotoExpanded
            f.hbPart = cw._hb and cw._hb.part
        end
        f.recorded = true
        S.back.on = true
        H.wrapOn()
        local prof = "?"
        pcall(function() prof = tostring(S.p:getDescriptor():getCharacterProfession()) end)
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", screen " .. H.sizeTag() .. ", language " .. H.lang()
            .. ", theme " .. tostring(f.base) .. ", text " .. tostring(f.size) .. ", input lock " .. tostring(S.lockWas) .. ", Carpentry "
            .. H.lvl(Perks.Woodwork) .. ", profession " .. prof .. ", " .. #f.traits .. " traits, " .. #(f.pins or {}) .. " pins, "
            .. #S.books .. " skill books, Character tab " .. tostring(f.ctab) .. ", the Character info screen switch " .. tostring(f.screen))
    end)
    H.step(2, function()
        -- his own copies of the things the cases give are set aside, so a case sees only what it gave
        local set = {}
        for _, ft in ipairs(S.CARP) do set[ft] = true end
        for _, ft in ipairs({ "Base.BookCooking1", "Base.Scissors", "Base.Razor", "Base.Lipstick", "Base.Mirror", "Base.Hammer", "Base.Apple" }) do set[ft] = true end
        local aside, kept = H.stashTypes(set)
        H.note("setup: " .. aside .. " of his own things of the types given here are set aside" .. (kept > 0 and (", " .. kept .. " worn or held stay") or ""))
        local miss = {}
        for _, ft in ipairs({ "Base.BookCarpentry1", "Base.BookCooking1", "Base.Scissors", "Base.Razor", "Base.Hammer", "Base.Apple" }) do if not H.known(ft) then miss[#miss + 1] = ft end end
        Q.check(#miss == 0, "setup: every item type the cases give is known to this game", "unknown: " .. H.list(miss))
        Q.check(#S.books > 0, "setup: the game's skill books are read from its script items", #S.books .. " books")
    end)
    Q.waitMs(1000)
end

-- ===================================================================== S1, S2: the Skills key
function C.s1()
    local T = { L = "S1 the Skills key" }
    H.step(2, function()
        H.caseStart(T)
        if not H.keyOf("TOGGLE_SKILL_PANEL") then T.off = true; Q.skip(T.L, "the game has no Skills key bound here"); return end
        RT.pairShut()
    end)
    H.wait(4000, function() return T.off or not RT.isOpen() end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.skip(T.L, "the windows would not shut"); return end
        T.n0 = (ZeD.CharInfoRoute and ZeD.CharInfoRoute.count) or 0
        H.gameKey("TOGGLE_SKILL_PANEL")
    end)
    H.wait(3000, function() return T.off or H.on("skills") end, function(ok)
        if T.off then return end
        local r = ZeD.CharInfoRoute and ZeD.CharInfoRoute.last
        local n = ((ZeD.CharInfoRoute and ZeD.CharInfoRoute.count) or 0) - (T.n0 or 0)
        Q.check(ok and not H.gameWinUp() and r ~= nil and r.tab == "skills" and n >= 1,
            T.L .. ": with both windows shut the game's key handler opens ZeD's Character window on Skills, the game's window hidden",
            H.tabText() .. "; the hook's last route " .. tostring(r and r.tab) .. " (" .. n .. " new); the game's window up " .. tostring(H.gameWinUp()))
        H.gameKey("TOGGLE_SKILL_PANEL")
    end)
    H.wait(3000, function() return T.off or not RT.isOpen() end, function(ok)
        if T.off then return end
        Q.check(ok and not H.gameWinUp(), T.L .. ": the same key again shuts the windows it opened (the game's second press shuts its page)", H.tabText())
    end)
    H.caseEnd(T.L)
end
function C.s2()
    local T = { L = "S2 the Skills key on open windows" }
    H.step(2, function()
        H.caseStart(T)
        if not H.keyOf("TOGGLE_SKILL_PANEL") then T.off = true; Q.skip(T.L, "the game has no Skills key bound here"); return end
        RT.pairOpen()
    end)
    H.wait(4000, function() return T.off or RT.isOpen() end, function() if not T.off then RT.charTab("loot") end end)
    H.wait(2000, function() local w = RT.cw(); return T.off or (w ~= nil and w._activeTab == "loot") end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.skip(T.L, "the window would not go to Loot: " .. H.tabText()); return end
        H.gameKey("TOGGLE_SKILL_PANEL")
    end)
    H.wait(3000, function() return T.off or H.on("skills") end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": open on Loot, the key goes to Skills", H.tabText())
        H.gameKey("TOGGLE_SKILL_PANEL")
    end)
    H.wait(3000, function() return T.off or not H.on("skills") end, function(ok)
        if T.off then return end
        Q.check(ok and RT.isOpen(), T.L .. ": the key again only folds the drawer (the windows were up already, CI:79-90)", H.tabText())
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S3: the Skills key while paused (bug 12)
function C.s3()
    local T = { L = "S3 the Skills key while paused" }
    H.step(2, function()
        H.caseStart(T)
        T.k = H.keyOf("TOGGLE_SKILL_PANEL")
        if not T.k then T.off = true; Q.skip(T.L, "the game has no Skills key bound here"); return end
        RT.pairShut()
    end)
    H.wait(4000, function() return T.off or not RT.isOpen() end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.skip(T.L, "the windows would not shut"); return end
        H.pause(true)
    end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        T.sp = getGameSpeed()
        -- (every listener of the key, the game's and ZeD's, as a key press reaches them)
        H.zcall(function() triggerEvent("OnKeyStartPressed", T.k) end)
        H.zcall(function() triggerEvent("OnKeyPressed", T.k) end)
    end)
    H.wait(2500, function() return T.off or RT.isOpen() end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": paused, the Skills key opens the Character window, as ZeD_PausedLook says (PL:6-9) [bug 12]; the game's own handler returns at speed 0 (XPU:128)",
            "game speed " .. tostring(T.sp) .. "; " .. H.tabText() .. "; the game's window up " .. tostring(H.gameWinUp()))
        H.pause(false)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S4: the tab strip and the wheel
function C.s4()
    local T = { L = "S4 the strip and the wheel" }
    H.step(2, function() H.caseStart(T); RT.pairOpen() end)
    H.wait(4000, function() return RT.isOpen() end, function() RT.charTab("loot") end)
    H.step(10, function() T.ok1 = RT.charTab("skills") end)
    H.wait(3000, function() return H.on("skills") end, function(ok)
        Q.check(ok and T.ok1, T.L .. ": the tab strip's S (its own mouse handler) opens Skills", H.tabText())
        RT.charTab("loot")
    end)
    H.step(10, function()
        local list = {}
        pcall(function() list = ZeD.DpadWheels.C.tabs(S.p, S.pn) end)
        for _, e in ipairs(list) do if e.key == "skills" then T.e = e end end
        if not T.e then T.off = true; Q.skip(T.L .. " (wheel)", "the wheel's Tabs slice has no Skills entry here"); return end
        T.off2 = T.e.off
        H.zcall(function() T.e.run(S.p, S.pn) end)
    end)
    H.wait(3000, function() return T.off or H.on("skills") end, function(ok)
        if T.off then return end
        Q.check(ok and T.off2 == nil, T.L .. ": the D-pad wheel's Tabs slice, its Skills entry, opens Skills", H.tabText() .. "; the entry greyed " .. tostring(T.off2))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S5: the groups against the game's order
-- the game's own groups (ISCharacterInfo: the parents of the child perks, passive first, then string.sort; the skills
-- in each by name)
function H.gameGroups()
    local by, order = {}, {}
    for _, perk in ipairs(H.childPerks()) do
        pcall(function()
            local par = perk:getParent()
            local key = tostring(par)
            if not by[key] then
                local pp = PerkFactory.getPerk(par)
                by[key] = { name = tostring(pp:getName()), passive = pp:isPassiv() and true or false, skills = {} }
                order[#order + 1] = by[key]
            end
            local sk = by[key].skills
            sk[#sk + 1] = tostring(perk:getName())
        end)
    end
    local hasSort = string.sort ~= nil
    table.sort(order, function(a, b)
        if a.passive and not b.passive then return true end
        if b.passive and not a.passive then return false end
        if hasSort then return not string.sort(a.name, b.name) end
        return a.name < b.name
    end)
    for _, g in ipairs(order) do table.sort(g.skills, function(a, b) return a < b end) end
    return order, hasSort
end
function C.s5()
    local T = { L = "S5 groups and rows" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local game, hasSort = H.gameGroups()
        local mine = (H.skData() and H.skData().categories) or {}
        local gn, mn, bad = {}, {}, {}
        for _, g in ipairs(game) do gn[#gn + 1] = g.name end
        for _, g in ipairs(mine) do mn[#mn + 1] = tostring(g.name) end
        Q.check(table.concat(gn, "|") == table.concat(mn, "|"), T.L .. ": the groups in the game's order (passive first, then the game's string sort)",
            "tab: " .. H.list(mn, 14) .. "; the game: " .. H.list(gn, 14) .. (hasSort and "" or " (the game's string.sort was not found: the plain sort stood in)"))
        for i, g in ipairs(game) do
            local m = mine[i]
            local ms = {}
            for _, s in ipairs((m and m.skills) or {}) do ms[#ms + 1] = tostring(s.name) end
            if not m or table.concat(ms, "|") ~= table.concat(g.skills, "|") then
                bad[#bad + 1] = g.name .. ": tab " .. H.list(ms, 8) .. " / game " .. H.list(g.skills, 8)
            end
        end
        Q.check(#bad == 0, T.L .. ": each group holds the game's skills in the game's order", (#bad == 0) and (#game .. " groups") or table.concat(bad, "; "))
        if not H.isEN() then H.note(T.L .. ": run in " .. H.lang()) end
        Q.skip(T.L .. " in DE, FR and RU", "a game started in each language (the sort is the game's string sort there)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S6: the level badges
function C.s6leg(T, L)
    H.step(2, function()
        if T.off then return end
        for _, perk in ipairs(H.childPerks()) do H.setLvl(perk, L) end
    end)
    H.skWait(T, T.L .. " " .. L)
    H.step(2, function()
        if T.off then return end
        local bad, drawn, badDraw = {}, 0, {}
        for _, g in ipairs((H.skData() and H.skData().categories) or {}) do
            for _, s in ipairs(g.skills or {}) do
                local want = H.lvl(s.perk)
                if s.level ~= want then bad[#bad + 1] = tostring(s.name) .. " " .. tostring(s.level) .. " (game " .. want .. ")" end
                local z = H.rowZ(s.name)
                if z and H.inView(z) then
                    local b = H.badgeIn(z)
                    if b ~= nil then drawn = drawn + 1; if b ~= want then badDraw[#badDraw + 1] = tostring(s.name) .. " " .. b end end
                end
            end
        end
        Q.check(#bad == 0, T.L .. " at " .. L .. ": every skill's level against getPerkLevel", (#bad == 0) and "all match" or H.list(bad, 8))
        Q.check(drawn > 0 and #badDraw == 0, T.L .. " at " .. L .. ": every badge drawn in the view shows that level", drawn .. " badges read; wrong " .. H.list(badDraw, 8))
    end)
end
function C.s6()
    local T = { L = "S6 level badges" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    for _, L in ipairs({ 0, 1, 5, 9, 10 }) do C.s6leg(T, L) end
    H.caseEnd(T.L)
end

-- ===================================================================== S7 to S9: the bar against the game's sums
function C.barRead(T, label)
    local name = H.pname(Perks.Woodwork)
    local sk = H.skillOf(name)
    local g = H.gProg(Perks.Woodwork)
    local gp = math.max(0, math.min(1, g.pct or 0))
    local z = H.rowZ(name)
    local seg = H.segIn(z)
    local want = (gp >= 1) and 10 or math.floor(gp * 10 + 1e-6)
    Q.check(sk ~= nil and math.abs((sk.xpProgress or -1) - gp) < 0.005, label .. ": the bar's progress against the game's sums (ISSkillProgressBar)",
        "tab " .. H.n3(sk and sk.xpProgress) .. ", game " .. H.n2(g.inLvl) .. " of " .. H.n2(g.need) .. " = " .. H.n3(gp) .. " at level " .. tostring(g.lvl))
    if seg then Q.check(seg.k == want, label .. ": the bar's lit segments against the game's share", tostring(seg.k) .. " lit, the share gives " .. want)
    else Q.skip(label .. ": the bar's lit segments", "the Carpentry row's bar was not drawn in the view") end
    T.sk, T.g, T.z, T.seg, T.gp = sk, g, z, seg, gp
end
-- the percent a help line names against the game's share
function C.pctOk(text, gp)
    local n = tonumber(string.match(tostring(text or ""), "(%d+)%%") or "")
    return n ~= nil and math.abs(n - gp * 100) <= 1, n
end
function C.s7leg(T, frac)
    local label = T.L .. " at " .. math.floor(frac * 100) .. "%"
    H.step(2, function() if not T.off then H.atFrac(Perks.Woodwork, 3, frac) end end)
    H.skWait(T, label)
    H.intoView(T, function() return H.rowZ(H.pname(Perks.Woodwork)) end)
    H.step(3, function() if not T.off then C.barRead(T, label) end end)
    -- the help line on the bar (the pointer on it)
    H.step(2, function()
        if T.off or not T.seg then return end
        H.mouseOn()
        H.hoverOn(T.seg.x + 2, T.seg.y + 1)
    end)
    Q.waitMs(250)
    H.step(2, function()
        if T.off or not T.seg then return end
        local ok, n = C.pctOk(S.skHelp, T.gp)
        Q.check(ok, label .. " (mouse): the help line on the bar names the game's share", tostring(S.skHelp) .. "; read " .. tostring(n) .. "%, game " .. H.n2(T.gp * 100) .. "%")
        H.hoverOff()
        H.lockBack()
    end)
end
function C.s7()
    local T = { L = "S7 the bar" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    for _, fr in ipairs({ 0, 0.45, 0.99 }) do C.s7leg(T, fr) end
    -- the pad's rest on the row: its help words beside it
    H.step(2, function()
        if T.off then return end
        H.atFrac(Perks.Woodwork, 3, 0.45)
        H.skFresh()
        T.go = H.padOn() and H.focusEl("skill:" .. tostring(H.pname(Perks.Woodwork)))
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        local g = H.gProg(Perks.Woodwork)
        local ok, n = C.pctOk(S.skPad, math.max(0, math.min(1, g.pct or 0)))
        Q.check(T.go and ok, T.L .. " (pad): the pad's rest on the Carpentry row shows the bar's help words with the game's share",
            "focus " .. tostring(H.focusedId()) .. "; words " .. tostring(S.skPad) .. "; read " .. tostring(n) .. "%, game " .. H.n2((g.pct or 0) * 100) .. "%")
        H.lockBack()
    end)
    -- the sandbox's XP multiplier at 0.5 and 5: XP given through it, the bar against the game's sums
    for _, m in ipairs({ 0.5, 5 }) do
        H.step(2, function()
            if T.off then return end
            T.mOk = H.sbOpt("XPMultiplierGlobal") ~= nil
            if not T.mOk then return end
            H.sbSet("XPMultiplierGlobalToggle", true)
            H.sbSet("XPMultiplierGlobal", m)
            H.setLvl(Perks.Woodwork, 3)
            pcall(function() S.p:getXp():AddXP(Perks.Woodwork, 20) end)
        end)
        H.skWait(T, T.L .. " multiplier " .. m)
        H.step(2, function()
            if T.off then return end
            if not T.mOk then Q.skip(T.L .. " with the sandbox XP multiplier " .. m, "the sandbox has no XPMultiplierGlobal option"); return end
            C.barRead(T, T.L .. " with the sandbox XP multiplier " .. m)
        end)
    end
    H.caseEnd(T.L)
end
function C.s8()
    local T = { L = "S8 level 10" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.step(2, function() if not T.off then H.setLvl(Perks.Woodwork, 10) end end)
    H.skWait(T, T.L)
    H.intoView(T, function() return H.rowZ(H.pname(Perks.Woodwork)) end)
    H.step(3, function()
        if T.off then return end
        C.barRead(T, T.L)
        Q.check(T.seg ~= nil and H.sameColor(T.seg.c, ZeD.T.warning), T.L .. ": the bar at 10 is yellow (the warning color, the game's gold)",
            T.seg and T.seg.c and (H.n2(T.seg.c.r) .. "," .. H.n2(T.seg.c.g) .. "," .. H.n2(T.seg.c.b)) or "no bar read")
        if not T.seg then return end
        H.mouseOn()
        H.hoverOn(T.seg.x + 2, T.seg.y + 1)
    end)
    Q.waitMs(250)
    H.step(2, function()
        if T.off or not T.seg then return end
        local name = H.pname(Perks.Woodwork)
        Q.check(H.has(S.skHelp, tostring(name)) and H.has(S.skHelp, "10") and not H.has(S.skHelp, "%"), T.L .. ": the bar's help line names the skill at 10 and no share", tostring(S.skHelp))
        H.hoverOn(T.z.x + math.floor(T.z.w / 3), T.z.y + math.floor(T.z.h / 2))
    end)
    Q.waitMs(250)
    H.step(2, function()
        if T.off or not T.seg then return end
        local c = S.skCard and S.skCard.card
        local line = c and c.lines and c.lines[1] and c.lines[1].text
        if not c then
            local ok, cc = pcall(S.ST._skillCard, RT.cw(), T.sk)
            if ok and cc then line = cc.lines[1].text; H.note(T.L .. ": no hover card was asked for under the pointer; the tab's card read directly") end
        end
        Q.check(line ~= nil and line == ZeD.tr("UI_ZeD_Skills_CardMax", 10), T.L .. ": the row's card reads Level 10 (getPerkLevel " .. H.lvl(Perks.Woodwork) .. ")", tostring(line))
        H.hoverOff()
        H.lockBack()
    end)
    H.caseEnd(T.L)
end
function C.s9()
    local T = { L = "S9 a passive skill under its floor" }
    H.step(2, function()
        H.caseStart(T)
        H.setLvl(Perks.Strength, 5)
        pcall(function() S.p:getXp():AddXPNoMultiplier(Perks.Strength, -40) end)
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(3, function()
        if T.off then return end
        local name = H.pname(Perks.Strength)
        local sk = H.skillOf(name)
        local g = H.gProg(Perks.Strength)
        if (g.inLvl or 0) >= 0 then H.note(T.L .. ": Strength's XP could not be put under its level's floor (in the level " .. H.n2(g.inLvl) .. ", level " .. tostring(g.lvl) .. ")") end
        local seg = H.segIn(H.rowZ(name))
        Q.check(sk ~= nil and (sk.xpProgress or -1) >= 0 and ((g.inLvl or 0) > 0 or (sk.xpProgress or 1) == 0), T.L .. ": the progress is never under 0 (the game draws 0, SPB:181-185)",
            "tab " .. H.n3(sk and sk.xpProgress) .. ", game in the level " .. H.n2(g.inLvl) .. " of " .. H.n2(g.need) .. ", level " .. tostring(g.lvl)
            .. "; lit " .. tostring(seg and seg.k))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S10, S11: boosts and a book's multiplier
function C.s10()
    local T = { L = "S10 boost tags" }
    local PCT = { "75%", "100%", "125%" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    for b = 0, 3 do
        H.step(2, function() if not T.off then pcall(function() S.p:getXp():setPerkBoost(Perks.Woodwork, b) end) end end)
        H.skWait(T, T.L .. " " .. b)
        H.intoView(T, function() return H.rowZ(H.pname(Perks.Woodwork)) end)
        H.step(3, function()
            if T.off then return end
            local name = H.pname(Perks.Woodwork)
            local sk = H.skillOf(name)
            local gb = 0
            pcall(function() gb = S.p:getXp():getPerkBoost(Perks.Woodwork) end)
            local tags = {}
            pcall(function() tags = S.ST.rowTags(S.p, sk) end)
            local bt = (tags[1] and tags[1].boost) and tags[1].text or nil
            local want = PCT[gb]
            local drawn = false
            for _, t in ipairs(H.textsIn(S.skT, H.rowZ(name))) do if want and H.has(t.s, want) then drawn = true end end
            Q.check((gb == 0 and bt == nil) or (want ~= nil and H.has(bt, want) and drawn), T.L .. ": boost " .. b .. " (getPerkBoost " .. gb .. ") tags the row with the game's "
                .. tostring(want or "none"), "tag " .. tostring(bt) .. ", drawn " .. tostring(drawn))
        end)
    end
    H.caseEnd(T.L)
end
function C.s11()
    local T = { L = "S11 a book's multiplier" }
    H.step(2, function()
        H.caseStart(T)
        H.setLvl(Perks.Woodwork, 2)
        local ok = pcall(function() addXpMultiplier(S.p, Perks.Woodwork, 2.0, 1, 10) end)
        if not ok then pcall(function() S.p:getXp():addXpMultiplier(Perks.Woodwork, 2.0, 1, 10) end) end
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(3, function()
        if T.off then return end
        local m = H.multNow()
        if m <= 0 then Q.skip(T.L, "the multiplier could not be set here"); return end
        local o = {}
        for _, t in ipairs(H.textsIn(S.skT, H.rowZ(H.pname(Perks.Woodwork)))) do o[#o + 1] = t.s end
        H.note(T.L .. ": the game's getMultiplier " .. H.n2(m) .. " (it draws three moving arrows before the name, ISCI:155-167, and a Multiplier line in its tooltip, SPB:69-73); the tab's row draws: "
            .. H.list(o, 6) .. " (a gap: the tab shows no multiplier)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S12: help lines and the hover card
-- the XP numbers in a card's first line against the game's (the tab floors them; the game's tooltip rounds to two
-- places)
function C.cardOk(T, label, line)
    local g = T.g12
    local n = H.nums(line)
    local x, y = math.floor(g.inLvl or -1), math.floor(g.need or -1)
    local hasX, hasY = false, false
    for _, v in ipairs(n) do if v == x then hasX = true end; if v == y then hasY = true end end
    Q.check(line ~= nil and hasX and hasY, label .. ": the card's XP against the game's (" .. x .. " of " .. y .. ", the tab floors; the game's tooltip shows "
        .. H.n2(g.inLvl) .. ")", tostring(line))
end
function C.s12()
    local T = { L = "S12 help lines and the card" }
    H.step(2, function()
        H.caseStart(T)
        H.pinsClear()
        H.atFrac(Perks.Woodwork, 3, 0.4)
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.intoView(T, function() return H.rowZ(H.pname(Perks.Woodwork)) end)
    H.step(2, function()
        if T.off then return end
        T.name = H.pname(Perks.Woodwork)
        T.z = H.rowZ(T.name)
        T.g12 = H.gProg(Perks.Woodwork)
        if not T.z then T.off = true; Q.skip(T.L, "the Carpentry row was not drawn"); return end
        H.mouseOn()
        H.hoverOn(T.z.x + math.floor(T.z.w / 3), T.z.y + math.floor(T.z.h / 2))
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        Q.check(S.skHelp == ZeD.tr("UI_ZeD_Skills_HelpPin", T.name), T.L .. " (mouse): the pointer on a row: the help line says right-click pins it", tostring(S.skHelp))
        local c = S.skCard
        Q.check(c ~= nil and c.key == "skill:" .. T.name, T.L .. " (mouse): the pointer on a row asks for its hover card", c and c.key or "no card asked for")
        if c and c.card and c.card.lines and c.card.lines[1] then C.cardOk(T, T.L .. " (mouse)", c.card.lines[1].text) end
        if c and c.card then H.note(T.L .. ": the card's lines: " .. tostring(#(c.card.lines or {})) .. " (RecipeIndex's recipe lines under the level)") end
        local gz = RT.cw()._skillsGridZone
        if gz then H.hoverOn(gz.x + 6, gz.y + math.floor(gz.h / 2)) end
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        Q.check(S.skHelp == ZeD.tr("UI_ZeD_Skills_HelpHeader"), T.L .. " (mouse): the pointer on the heading: its help line", tostring(S.skHelp))
        H.hoverOff()
        H.lockBack()
        T.go = H.padOn() and H.focusEl("skill:" .. T.name)
    end)
    Q.waitMs(1600)
    H.step(2, function()
        if T.off then return end
        local c = S.skCard
        Q.check(T.go and c ~= nil and c.key == "skill:" .. T.name, T.L .. " (pad): the pad's rest on the row asks for its card", "focus " .. tostring(H.focusedId()) .. ", card " .. tostring(c and c.key))
        if c and c.card and c.card.lines and c.card.lines[1] then C.cardOk(T, T.L .. " (pad)", c.card.lines[1].text) end
        H.lockBack()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S13 to S15: pins
-- queue: the menu of the row of perk t by a right-click on it (mouse), then the option key picked
function C.menuPick(T, t, key, label)
    H.intoView(T, function() return H.rowZ(H.pname(t)) end)
    H.step(2, function()
        if T.off then return end
        H.closeMenu()
        T.mc0 = #S.menuCalls
        local z = H.rowZ(H.pname(t))
        if not z then T.off = true; Q.check(false, label .. ": the row is drawn for its right-click"); return end
        local x, y = H.mid(z)
        H.rclickAt(x, y)
    end)
    H.wait(2000, function() return T.off or H.ctxOpt(ZeD.tr(key)) ~= nil end, function(ok)
        if T.off then return end
        if not Q.check(ok and #S.menuCalls > T.mc0, label .. ": a right-click on the row opens its menu with " .. ZeD.tr(key),
            (#S.menuCalls - T.mc0) .. " menus asked for, visible " .. tostring(H.ctxVisible())) then return end
        H.pickOpt(ZeD.tr(key))
        H.closeMenu()
    end)
    Q.waitMs(300)
end
function C.titleHas(sub) for _, t in ipairs(H.titleTexts()) do if H.has(t, sub) then return true end end; return false end
function C.s13()
    local T = { L = "S13 pin from the menu" }
    H.step(2, function()
        H.caseStart(T)
        H.pinsClear()
        H.atFrac(Perks.Woodwork, 3, 0.4)
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function() if not T.off then H.mouseOn() end end)
    C.menuPick(T, Perks.Woodwork, "UI_ZeD_Pin_Pin", T.L .. " (pin)")
    Q.waitMs(300)
    H.step(3, function()
        if T.off then return end
        local name = H.pname(Perks.Woodwork)
        local g = H.gProg(Perks.Woodwork)
        local want = math.floor(g.inLvl) .. "/" .. math.floor(g.need)
        Q.check(S.PN.isPinned(S.p, "skill", name), T.L .. ": Carpentry is pinned", H.list(H.pinIds()))
        Q.check(C.titleHas(want), T.L .. ": the title bar shows the game's XP in the level " .. want, H.list(H.titleTexts()))
        local seg = H.segIn(H.rowZ(name))
        Q.check(seg ~= nil and H.sameColor(seg.c, ZeD.T.warning), T.L .. ": the pinned row's bar is yellow", seg and seg.c and (H.n2(seg.c.r) .. "," .. H.n2(seg.c.g)) or "no bar read")
    end)
    C.menuPick(T, Perks.Woodwork, "UI_ZeD_Pin_Unpin", T.L .. " (unpin)")
    H.step(3, function()
        if T.off then return end
        local name = H.pname(Perks.Woodwork)
        local seg = H.segIn(H.rowZ(name))
        Q.check(not S.PN.isPinned(S.p, "skill", name) and seg ~= nil and H.sameColor(seg.c, ZeD.T.positive), T.L .. ": Unpin takes the pin and the yellow off",
            H.list(H.pinIds()) .. "; bar " .. (seg and seg.c and (H.n2(seg.c.r) .. "," .. H.n2(seg.c.g)) or "none"))
    end)
    H.caseEnd(T.L)
end
function C.s14()
    local T = { L = "S14 a fourth pin" }
    H.step(2, function()
        H.caseStart(T)
        H.pinsClear()
        T.names = { H.pname(Perks.Woodwork), H.pname(Perks.Cooking), H.pname(Perks.Fitness) }
        for _, n in ipairs(T.names) do S.PN.toggle(S.p, "skill", n, n) end
        T.item = H.give("Base.Hammer")
        T.n0 = #S.notes
        local rec = { opts = {} }
        function rec:addOption(name, target, fn) self.opts[#self.opts + 1] = { name = name, target = target, fn = fn }; return {} end
        H.zcall(function() S.PN.onFillInventory(S.pn, rec, { T.item }) end)
        T.opt = rec.opts[1]
        if T.opt and T.opt.fn then H.zcall(function() T.opt.fn() end) end
    end)
    Q.waitMs(300)
    H.step(2, function()
        local L = S.p:getModData().ZeD_Pins or {}
        local first = L[1] and tostring(L[1].id)
        Q.check(T.opt ~= nil and T.opt.name == ZeD.tr("UI_ZeD_Pin_Pin"), T.L .. ": the item's menu (ZeD's line in the game's item menu) offers Pin to title bar", tostring(T.opt and T.opt.name))
        Q.check(#L == 3 and first == T.names[2], T.L .. ": three pins at most: the oldest (" .. tostring(T.names[1]) .. ") goes", H.list(H.pinIds()))
        local said = S.notes[T.n0 + 1]
        Q.check(said ~= nil and H.has(said, tostring(T.names[1])), T.L .. ": the note over his head names the pin taken off", tostring(said))
    end)
    H.caseEnd(T.L)
end
function C.s15()
    local T = { L = "S15 the pin's key" }
    H.step(2, function()
        H.caseStart(T)
        H.pinsClear()
        H.atFrac(Perks.Woodwork, 3, 0.4)
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function() if not T.off then H.mouseOn() end end)
    C.menuPick(T, Perks.Woodwork, "UI_ZeD_Pin_Pin", T.L)
    H.step(2, function()
        if T.off then return end
        local L = S.p:getModData().ZeD_Pins or {}
        local e = L[#L]
        local pid, ptype = "?", "?"
        pcall(function() pid = tostring(H.perkOf(Perks.Woodwork):getId()) end)
        pcall(function() ptype = tostring(Perks.Woodwork) end)
        local stored = e and tostring(e.id)
        Q.check(stored ~= nil and (stored == pid or stored == ptype), T.L .. ": the pin is kept by the skill's own id, the same in every language [bug 1]",
            "stored \"" .. tostring(stored) .. "\" (the shown name " .. tostring(H.pname(Perks.Woodwork)) .. "), the perk's id " .. pid)
        -- a pin kept under a name this language does not give (as a German save's pin reads in English), with two
        -- real ones: on the title bar, or not counted against the three
        S.p:getModData().ZeD_Pins = { { k = "skill", id = tostring(H.pname(Perks.Woodwork)) .. " (DE)" },
            { k = "skill", id = H.pname(Perks.Cooking) }, { k = "skill", id = H.pname(Perks.Fitness) } }
        RT.cw()._pinnedSkills = S.PN.skillNames(S.p)
    end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        local shown = 0
        for _, st in ipairs(RT.cw().titleStats or {}) do if not st.noMark and tostring(st.text or "") ~= "" then shown = shown + 1 end end
        Q.check(shown == 3, T.L .. ": a pin whose name the language no longer gives still shows or no longer counts toward the three [bug 1]",
            shown .. " shown of 3 counted: " .. H.list(H.titleTexts()))
        Q.skip(T.L .. ": pinned in English, the game restarted in German", "a restart in another language")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S16: the pad on a row
function C.s16()
    local T = { L = "S16 the pad on a row" }
    H.step(2, function()
        H.caseStart(T)
        H.pinsClear()
        H.atFrac(Perks.Woodwork, 3, 0.4)
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        T.id = "skill:" .. tostring(H.pname(Perks.Woodwork))
        T.go = H.padOn() and H.focusEl(T.id)
        Q.check(T.go, T.L .. ": the pad's focus lands on the Carpentry row", "focus " .. tostring(H.focusedId()) .. "; stops " .. H.stopIds("skill:", 6))
        T.mc0 = #S.menuCalls
    end)
    H.tapA(function() return T.go and not T.off end)
    H.wait(1500, function() return T.off or H.ctxVisible() end, function(ok)
        if T.off or not T.go then return end
        Q.check(ok and #S.menuCalls > T.mc0, T.L .. ": A on the row opens its pin menu", (#S.menuCalls - T.mc0) .. " asked, visible " .. tostring(H.ctxVisible()))
        local joined = false
        pcall(function() joined = JoypadState.players[S.pn + 1] ~= nil end)
        if not joined then H.note(T.L .. ": no controller is joined in this run, so the menu takes no pad focus (PN:278-282 gives it one with a controller)") end
        H.closeMenu()
        T.mc0 = #S.menuCalls
        H.focusEl(T.id)
    end)
    H.tapX(function() return T.go and not T.off end)
    H.wait(1500, function() return T.off or H.ctxVisible() end, function(ok)
        if T.off or not T.go then return end
        Q.check(ok and #S.menuCalls > T.mc0, T.L .. ": X on the row opens the same menu", (#S.menuCalls - T.mc0) .. " asked")
        Q.check(H.pickOpt(ZeD.tr("UI_ZeD_Pin_Pin")) and S.PN.isPinned(S.p, "skill", H.pname(Perks.Woodwork)), T.L .. ": Pin to title bar from the menu the pad opened pins it", H.list(H.pinIds()))
        H.closeMenu()
        -- an action running: an apple being eaten (the game's own action)
        T.apple = H.give("Base.Apple")
        H.zcall(function() ISTimedActionQueue.add(ISEatFoodAction:new(S.p, T.apple, 1)) end)
        H.focusEl(T.id)
    end)
    H.wait(2000, function() return T.off or H.qlen() > 0 end, function(ok)
        if T.off or not T.go then return end
        T.q0 = H.qkinds()
        if not ok then T.noAct = true; Q.skip(T.L .. ": B with an action running", "the game's eat action did not queue") end
    end)
    H.tapB(function() return T.go and not T.off and not T.noAct end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off or not T.go or T.noAct then return end
        Q.check(H.qcount("ISEatFoodAction") == 0 and H.on("skills"), T.L .. ": B on a row with an action running stops the action (FM:1700); the tab stays (the game's B closes its page)",
            "queued before " .. tostring(T.q0) .. ", after " .. H.qkinds() .. "; " .. H.tabText())
        H.qstop()
        H.focusEl(T.id)
        T.mc0 = #S.menuCalls
    end)
    H.tapB(function() return T.go and not T.off end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off or not T.go then return end
        Q.check(H.on("skills") and H.focusedId() == T.id and #S.menuCalls == T.mc0 and not H.ctxVisible(), T.L .. ": B on a row with nothing running changes nothing",
            H.tabText() .. ", focus " .. tostring(H.focusedId()))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S17: the grid's disclosure
function C.trTop() local m = nil; for _, z in ipairs(H.trZones()) do if m == nil or z.y < m then m = z.y end end; return m end
function C.s17judge(T, label, wantOpen)
    local w = RT.cw()
    local rows, stops = #(w._skillRowZones or {}), 0
    for _, e in ipairs(H.stops()) do if string.sub(tostring(e.id), 1, 6) == "skill:" then stops = stops + 1 end end
    local top = C.trTop()
    if wantOpen then
        Q.check(w._skillsGridExpanded == true and rows > 0 and stops > 0, label .. ": the grid opens again, its rows and stops back", rows .. " rows, " .. stops .. " stops")
    else
        Q.check(w._skillsGridExpanded == false and rows == 0 and stops == 0 and top ~= nil and T.top0 ~= nil and top < T.top0,
            label .. ": the grid folds: no rows, no row stops, the training rows move up and stay", rows .. " rows, " .. stops .. " stops, training top "
            .. tostring(top) .. " (was " .. tostring(T.top0) .. ")")
    end
end
function C.s17()
    local T = { L = "S17 the grid's disclosure" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(3, function()
        if T.off then return end
        T.top0 = C.trTop()
        local gz = RT.cw()._skillsGridZone
        if not gz then T.off = true; Q.check(false, T.L .. ": the heading's zone is stamped"); return end
        H.clickAt(gz.x + 6, gz.y + math.floor(gz.h / 2))
    end)
    Q.waitMs(300)
    H.step(2, function() if not T.off then C.s17judge(T, T.L .. " (mouse)", false); local gz = RT.cw()._skillsGridZone; H.clickAt(gz.x + 6, gz.y + math.floor(gz.h / 2)) end end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        C.s17judge(T, T.L .. " (mouse)", true)
        T.go = H.padOn() and H.focusEl("skills:__disclosure")
        Q.check(T.go, T.L .. " (pad): the focus lands on the heading's disclosure", "focus " .. tostring(H.focusedId()))
    end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(300)
    H.step(2, function() if not T.off and T.go then C.s17judge(T, T.L .. " (pad)", false); H.focusEl("skills:__disclosure") end end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(300)
    H.step(2, function() if not T.off and T.go then C.s17judge(T, T.L .. " (pad)", true) end end)
    H.caseEnd(T.L)
end

-- ===================================================================== S18: Find
-- the rows Find should keep for text q: a skill by its name or its group's name (a training row with its skill)
function C.findJudge(T, label, q)
    local w = RT.cw()
    local bad, lit = {}, 0
    for _, g in ipairs((H.skData() and H.skData().categories) or {}) do
        local gm = string.find(H.lower(g.name), q, 1, true) ~= nil
        for _, s in ipairs(g.skills or {}) do
            local want = gm or string.find(H.lower(s.name), q, 1, true) ~= nil
            local on = not S.TF.skillOff(w, s.name)
            if on then lit = lit + 1 end
            if want ~= on then bad[#bad + 1] = tostring(s.name) .. (on and " lit" or " dim") end
        end
    end
    Q.check(#bad == 0 and lit > 0, label .. ": \"" .. q .. "\" keeps exactly the skills named so or in a group named so", lit .. " lit; wrong " .. H.list(bad, 8))
    local stopBad = {}
    for _, e in ipairs(H.stops()) do
        local id = tostring(e.id)
        if string.sub(id, 1, 6) == "skill:" and e.skillName and S.TF.skillOff(w, e.skillName) then stopBad[#stopBad + 1] = id end
    end
    Q.check(#stopBad == 0, label .. ": a dimmed row is no pad stop (Down skips it)", H.list(stopBad, 6))
end
function C.s18()
    local T = { L = "S18 Find" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local name = tostring(H.pname(Perks.Woodwork))
        T.q1 = H.lower(string.sub(name, 1, 4))
        T.label1 = H.trRow("Carpentry")
        S.TF.setText(RT.cw(), "skills", T.q1)
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        C.findJudge(T, T.L, T.q1)
        Q.check(not S.TF.trainOff(RT.cw(), "Carpentry"), T.L .. ": the Carpentry training row stays lit with its skill")
        local grp = nil
        for _, g in ipairs(H.skData().categories or {}) do if not grp and #(g.skills or {}) >= 2 and H.lower(g.name) ~= "" then grp = g end end
        T.q2 = grp and H.lower(grp.name) or "zzzz"
        S.TF.setText(RT.cw(), "skills", T.q2)
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        C.findJudge(T, T.L, T.q2)
        S.TF.setText(RT.cw(), "skills", "zzz")
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        Q.check(H.stopOf("skills:findclear") ~= nil, T.L .. ": \"zzz\" shows the empty result with its Clear as a pad stop", H.stopIds("skills:", 6))
        T.go = H.padOn() and H.focusEl("skills:findclear")
    end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        Q.check(T.go and S.TF.text(RT.cw(), "skills") == "", T.L .. " (pad): A on Clear empties the text", "text \"" .. tostring(S.TF.text(RT.cw(), "skills")) .. "\"")
        H.lockBack()
        S.TF.setText(RT.cw(), "skills", T.q1)
    end)
    Q.waitMs(200)
    H.step(2, function()
        if T.off then return end
        pcall(function() S.TF.clear(RT.cw(), "skills") end)
        H.note(T.L .. " (mouse): the field's x box is the field's own press; cleared here by TabFind.clear, as the box does")
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        local dim = 0
        for _, z in ipairs(RT.cw()._skillRowZones or {}) do if S.TF.skillOff(RT.cw(), z.name) then dim = dim + 1 end end
        Q.check(dim == 0, T.L .. ": cleared, every row is lit again", dim .. " dimmed")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S19: the half card with Large text
function C.s19()
    local T = { L = "S19 the half card, Large text" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.halfOn(T)
    H.step(2, function() if not T.off then H.sizeSet("large") end end)
    Q.waitMs(1500)
    H.skWait(T, T.L)
    H.step(3, function()
        if T.off then return end
        local w = RT.cw()
        T.one = w._skillsOneCol and true or false
        local cut, n = {}, 0
        for _, z in ipairs(w._skillRowZones or {}) do
            if H.inView(z) then
                for _, t in ipairs(H.textsIn(S.skT, z)) do
                    if not string.match(t.s, "^%d+$") then
                        n = n + 1
                        if string.sub(t.s, -3) == "..." then cut[#cut + 1] = t.s end
                    end
                end
            end
        end
        Q.check(n > 0 and #cut == 0, T.L .. ": every skill name drawn whole (drawer " .. math.floor(w._drawerEffW or 0) .. " px, " .. (T.one and "one column" or "two columns") .. ")",
            n .. " words read in the rows; cut " .. H.list(cut, 6))
        if not T.one then Q.skip(T.L .. ": Left and Right on a one-column row", "two columns fit here"); return end
        T.id = "skill:" .. tostring(H.pname(Perks.Woodwork))
        T.go = H.padOn() and H.focusEl(T.id)
    end)
    H.step(3, function() if T.go and not T.off then RT.padDir("left", RT.cw()) end end)
    H.step(4, function()
        if not T.go or T.off then return end
        T.afterL = H.focusedId()
        H.focusEl(T.id)
        RT.padDir("right", RT.cw())
    end)
    H.step(4, function()
        if not T.go or T.off then return end
        Q.check(T.afterL == T.id and H.focusedId() == T.id, T.L .. ": one column, Left and Right on a row do nothing", "after Left " .. tostring(T.afterL) .. ", after Right " .. tostring(H.focusedId()))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S20: the scroll follows the pad
function C.s20()
    local T = { L = "S20 the scroll follows" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(3, function()
        if T.off then return end
        -- the first column's last training row opened (staging), its last book the walk's end
        local minX, pick = nil, nil
        for _, z in ipairs(H.trZones()) do if not z.book and (minX == nil or z.x < minX) then minX = z.x end end
        for _, z in ipairs(H.trZones()) do if not z.book and z.x == minX and (pick == nil or z.y > pick.y) then pick = z end end
        if not pick then T.off = true; Q.skip(T.L, "no training rows drawn"); return end
        RT.cw()._trainingExpanded[pick.id] = true
        H.skFresh()
        local g = H.trGroup(pick.label)
        T.endId = "training:" .. pick.id .. "#" .. #((g and g.items) or {})
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        T.go = H.padOn() and H.focusEl("skills:__disclosure")
        if not T.go then T.off = true; Q.check(false, T.L .. ": the focus lands on the disclosure", tostring(H.focusedId())) end
        T.seen, T.out = {}, {}
    end)
    H.walk(T, "down", 160, function()
        local id = H.focusedId()
        local e = id and H.stopOf(id)
        if id and not T.seen[id] then
            T.seen[id] = true
            if e and string.sub(tostring(id), 1, 7) ~= "skills:" and not H.inView(e) then T.out[#T.out + 1] = tostring(id) end
        end
        if id == T.endId then T.reached = true; return true end
        if id == T.last then T.same = (T.same or 0) + 1 else T.same = 0 end
        T.last = id
        return (T.same or 0) >= 3
    end)
    H.step(2, function()
        if T.off then return end
        local n = 0
        for _ in pairs(T.seen) do n = n + 1 end
        Q.check(T.reached == true, T.L .. ": Down from the disclosure reaches the last book of the open training row (" .. tostring(T.endId) .. ")", "stopped on " .. tostring(H.focusedId()) .. " after " .. n .. " stops")
        Q.check(#T.out == 0, T.L .. ": each stop the pad lands on is scrolled into view", n .. " stops; out of view " .. H.list(T.out, 6))
        T.pos0 = RT.cw()._skillsScroll.scrollPos
        H.lockBack()
        H.wheel(-1); H.wheel(-1); H.wheel(-1)
        T.pos1 = RT.cw()._skillsScroll.scrollPos
    end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        local p2 = RT.cw()._skillsScroll.scrollPos
        Q.check(T.pos1 ~= T.pos0 and math.abs(p2 - T.pos1) < 0.0001, T.L .. ": the wheel past the focus scrolls and does not snap back", H.n3(T.pos0) .. " -> " .. H.n3(T.pos1) .. ", 400 ms later " .. H.n3(p2))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S21: the training rows against the game's books
function C.s21()
    local T = { L = "S21 the training rows" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local groups = RT.cw()._trainingCache or {}
        local game, hidden = {}, {}
        for _, b in ipairs(S.books) do
            if b.hidden then hidden[#hidden + 1] = b.ft else game[b.skill] = (game[b.skill] or 0) + 1 end
        end
        local nGame = 0
        for _ in pairs(game) do nGame = nGame + 1 end
        Q.check(#groups == nGame, T.L .. ": one row per skill the game has books for", #groups .. " rows, the game's skills with books " .. nGame)
        local badName, badN, badOrd = {}, {}, {}
        for i, g in ipairs(groups) do
            local want = nil
            pcall(function() want = tostring(PerkFactory.getPerk(SkillBook[g.label].perk):getName()) end)
            if want and g.disp ~= want then badName[#badName + 1] = tostring(g.label) .. " shows " .. tostring(g.disp) .. " (game " .. want .. ")" end
            if #(g.items or {}) ~= (game[g.label] or 0) then badN[#badN + 1] = tostring(g.label) .. " " .. #(g.items or {}) .. " (game " .. tostring(game[g.label]) .. ")" end
            local nx = groups[i + 1]
            if nx and H.lower(nx.disp) < H.lower(g.disp) then badOrd[#badOrd + 1] = tostring(g.disp) .. " before " .. tostring(nx.disp) end
        end
        Q.check(#badName == 0, T.L .. ": each row shows its skill's name as the game names it", H.list(badName, 6))
        Q.check(#badN == 0, T.L .. ": each row has one square per book the game's Literature list shows for the skill", H.list(badN, 6))
        Q.check(#badOrd == 0, T.L .. ": the rows sorted by the shown name", H.list(badOrd, 6))
        if #hidden > 0 then H.note(T.L .. ": books the game's Literature list hides (LITERATURE_HIDDEN): " .. H.list(hidden, 6)) end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S22 to S24: the books' states
-- the Carpentry books unread and not carried (staging for S22-S24)
function C.booksBlank(fts)
    for _, ft in ipairs(fts) do H.setPages(ft, 0); H.dropRead(ft) end
end
function C.bookOf(ft) for _, b in ipairs(S.books) do if b.ft == ft then return b end end; return nil end
-- the tab's state of the game's book b
function C.tabState(b)
    local g = H.trGroup(b.skill)
    for _, it in ipairs((g and g.items) or {}) do
        local m = H.matchBook(b.skill, it.title)
        if m and m.ft == b.ft then return it.status end
    end
    return nil
end
function C.firstKnown(list) for _, ft in ipairs(list) do if H.known(ft) then return ft end end; return nil end
function C.s22()
    local T = { L = "S22 book states" }
    H.step(2, function()
        H.caseStart(T)
        C.booksBlank(S.CARP)
        C.booksBlank({ "Base.BookCooking1" })
        H.give(S.CARP[1])
        local outer = H.give(C.firstKnown({ "Base.Bag_Schoolbag", "Base.Bag_DuffelBag", "Base.Bag_Satchel" }))
        local inner = nil
        pcall(function() inner = H.giveTo(outer:getInventory(), C.firstKnown({ "Base.Plasticbag", "Base.Bag_FannyPackFront", "Base.Purse" })) end)
        pcall(function() H.giveTo(inner:getInventory(), S.CARP[2]) end)
        local b3, b4 = C.bookOf(S.CARP[3]), C.bookOf(S.CARP[4])
        if b3 then H.setPages(b3.ft, math.max(1, math.min(50, math.floor((b3.pages or 2) / 2)))) end
        if b4 then H.setPages(b4.ft, b4.pages or 1) end
        T.crate = H.mkCrate()
        if T.crate then H.giveTo(T.crate.inv, "Base.BookCooking1") end
        H.lootRefresh()
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local bad, n = {}, 0
        local list = { S.CARP[1], S.CARP[2], S.CARP[3], S.CARP[4], S.CARP[5] }
        if T.crate then list[#list + 1] = "Base.BookCooking1" end
        for _, ft in ipairs(list) do
            local b = C.bookOf(ft)
            if b then
                n = n + 1
                local mine, game = C.tabState(b), H.gameState(b)
                if mine ~= game then bad[#bad + 1] = ft .. " tab " .. tostring(mine) .. " game " .. game end
            end
        end
        Q.check(n >= 5 and #bad == 0, T.L .. ": each book's state against the game's getters (carried, a bag in a bag, half read, read, none"
            .. (T.crate and ", one in a crate beside him" or "") .. ")", n .. " books; wrong " .. H.list(bad, 6))
        if not T.crate then H.note(T.L .. ": no free square for the crate: its leg left out") end
    end)
    H.caseEnd(T.L)
end
function C.s23()
    local T = { L = "S23 known by level" }
    H.step(2, function()
        H.caseStart(T)
        C.booksBlank(S.CARP)
        H.setLvl(Perks.Woodwork, 10)
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local gap, known = {}, 0
        local lv = H.lvl(Perks.Woodwork)
        for _, b in ipairs(H.booksOf("Carpentry")) do
            local k = ((b.pages or 0) > 0 and H.pagesRead(b.ft) == b.pages) or (b.maxLvl or 99) <= lv + 1
            if k then
                known = known + 1
                local mine = C.tabState(b)
                if mine ~= "read" then gap[#gap + 1] = b.ft .. " " .. tostring(mine) end
            end
        end
        Q.check(known > 0 and #gap == 0, T.L .. ": Carpentry " .. lv .. " with none read: the books the game's Literature list counts known (LIT:92) show as read here [bug 4]",
            known .. " known by the game; the tab says " .. H.list(gap, 6))
    end)
    H.caseEnd(T.L)
end
function C.s24()
    local T = { L = "S24 MetaKnowledge" }
    H.step(2, function()
        H.caseStart(T)
        C.booksBlank(S.CARP)
        H.setLvl(Perks.Woodwork, 0)
        T.ok = H.sbSet("MetaKnowledge", 3)
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        if not T.ok then Q.skip(T.L, "the sandbox has no MetaKnowledge option"); return end
        local gameShown = 0
        local lv = H.lvl(Perks.Woodwork)
        for _, b in ipairs(H.booksOf("Carpentry")) do
            local k = ((b.pages or 0) > 0 and H.pagesRead(b.ft) == b.pages) or (b.maxLvl or 99) <= lv + 1
            if k then gameShown = gameShown + 1 end
        end
        local g = H.trGroup("Carpentry")
        local mine = #((g and g.items) or {})
        Q.check(mine <= gameShown, T.L .. ": MetaKnowledge 3 (the game hides unknown books, LIT:78, 124): the tab shows no more Carpentry titles than the game's list [bug 4, stakes]",
            "the tab " .. mine .. ", the game " .. gameShown .. " (Carpentry " .. lv .. ", none read)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S25: the titles and volume numbers (bug 3)
function C.s25()
    local T = { L = "S25 book titles" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local wrongVol, doubled, unmatched, shown = {}, {}, {}, {}
        for _, g in ipairs(RT.cw()._trainingCache or {}) do
            local books = H.booksOf(g.label)
            table.sort(books, function(a, b) return (a.lvl or 0) < (b.lvl or 0) end)
            local rank = {}
            for i, b in ipairs(books) do rank[b.ft] = S.ROMAN[i] or tostring(i) end
            for _, it in ipairs(g.items or {}) do
                local b = H.matchBook(g.label, it.title)
                local text = ZeD.tr("UI_ZeD_Skills_Volume", tostring(it.title), tostring(it.volume))
                if #shown < 6 and (g.label == "Carpentry" or g.label == "Electricity" or g.label == "Farming") then shown[#shown + 1] = text end
                if not b then unmatched[#unmatched + 1] = tostring(it.title)
                elseif rank[b.ft] ~= it.volume then wrongVol[#wrongVol + 1] = b.ft .. " Vol. " .. tostring(it.volume) .. " (LvlSkillTrained order " .. tostring(rank[b.ft]) .. ")" end
                local t = tostring(it.title)
                if string.find(t, "%s[IVX]+:") or string.find(t, "[Vv]ol%.?%s*%d") or string.find(t, "%s%d+$") then doubled[#doubled + 1] = g.label end
            end
        end
        Q.check(#wrongVol == 0 and #unmatched == 0, T.L .. ": every book's volume follows the game's LvlSkillTrained order [bug 3]",
            "wrong " .. H.list(wrongVol, 6) .. "; not matched to a game book " .. H.list(unmatched, 4))
        local skills, seen = {}, {}
        for _, s in ipairs(doubled) do if not seen[s] then seen[s] = true; skills[#skills + 1] = s end end
        Q.check(#doubled == 0, T.L .. ": no shown title keeps its own volume number before the tab's Vol. (" .. H.lang() .. ") [bug 3]",
            #doubled .. " titles in " .. H.list(skills, 12))
        H.note(T.L .. ": shown, e.g. " .. H.list(shown, 6))
        Q.skip(T.L .. " in DE, ES, FR and RU", "a game started in each language")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S26: a training row folded
function C.s26()
    local T = { L = "S26 a training row folded" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local z = H.trRow("Carpentry") or H.trZones()[1]
        if not z then T.off = true; Q.skip(T.L, "no training rows drawn"); return end
        T.key = z.id
    end)
    H.intoView(T, function() return H.trZ(T.key) end)
    H.step(2, function()
        if T.off then return end
        local x, y = H.mid(H.trZ(T.key))
        H.clickAt(x, y)
    end)
    Q.waitMs(250)
    H.step(2, function()
        if T.off then return end
        local w = RT.cw()
        Q.check(w._trainingExpanded[T.key] == true and H.trZ(T.key .. "#1") ~= nil, T.L .. " (mouse): a click opens the row, its books listed", "open " .. tostring(w._trainingExpanded[T.key]))
        local bz = H.trZ(T.key .. "#1")
        if bz then local x, y = H.mid(bz); H.clickAt(x, y) end
    end)
    Q.waitMs(250)
    H.step(2, function()
        if T.off then return end
        Q.check(RT.cw()._trainingExpanded[T.key] == true and H.trZ(T.key .. "#1") ~= nil, T.L .. " (mouse): a click on a book row does nothing", "open " .. tostring(RT.cw()._trainingExpanded[T.key]))
        local x, y = H.mid(H.trZ(T.key))
        H.clickAt(x, y)
    end)
    Q.waitMs(250)
    H.step(2, function()
        if T.off then return end
        Q.check(not RT.cw()._trainingExpanded[T.key] and H.trZ(T.key .. "#1") == nil, T.L .. " (mouse): a second click folds it", "open " .. tostring(RT.cw()._trainingExpanded[T.key]))
        T.go = H.padOn() and H.focusEl("training:" .. T.key)
    end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off or not T.go then return end
        Q.check(RT.cw()._trainingExpanded[T.key] == true, T.L .. " (pad): A opens the row", "open " .. tostring(RT.cw()._trainingExpanded[T.key]))
        T.goB = H.focusEl("training:" .. T.key .. "#1")
    end)
    H.tapA(function() return T.goB and not T.off end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off or not T.go then return end
        Q.check(T.goB and RT.cw()._trainingExpanded[T.key] == true, T.L .. " (pad): A on a book row does nothing", "focus " .. tostring(H.focusedId()) .. ", open " .. tostring(RT.cw()._trainingExpanded[T.key]))
        H.focusEl("training:" .. T.key)
    end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off or not T.go then return end
        Q.check(not RT.cw()._trainingExpanded[T.key], T.L .. " (pad): A again folds it", "open " .. tostring(RT.cw()._trainingExpanded[T.key]))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S27: presses on the heading over rows beneath it (bug 7)
function C.under(list, band, wantBook)
    for _, z in ipairs(list or {}) do
        if (wantBook == nil or (z.book and true or false) == wantBook) and z.y < band.y + band.h - 2 and z.y + z.h > band.y + 2 then return z end
    end
    return nil
end
-- queue: the scroll stepped down until fn() finds a zone under the heading (T[key] set), or the end
function C.scrollTill(T, key, fn)
    H.step(2, function() if not T.off then T.sp = 0; pcall(function() RT.cw()._skillsScroll:setScrollPos(0) end) end end)
    H.wait(8000, function()
        if T.off then return true end
        T[key] = fn()
        if T[key] then return true end
        T.sp = T.sp + 0.01
        if T.sp > 1 then return true end
        pcall(function() RT.cw()._skillsScroll:setScrollPos(T.sp) end)
        return false
    end, function() end)
end
function C.s27()
    local T = { L = "S27 presses through the heading" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        -- every training row opened, so the tab scrolls at any size
        for _, z in ipairs(H.trZones()) do if not z.book then RT.cw()._trainingExpanded[z.id] = true end end
        H.skFresh()
        H.mouseOn()
    end)
    Q.waitMs(300)
    C.scrollTill(T, "rowZ", function() local gz = RT.cw()._skillsGridZone; return gz and C.under(RT.cw()._skillRowZones, gz, nil) end)
    H.step(2, function()
        if T.off then return end
        local gz, z = RT.cw()._skillsGridZone, T.rowZ
        if not (gz and z) then Q.skip(T.L .. ": a right-click on the heading over a row", "no scroll put a skill row under the heading (the tab does not scroll here)"); return end
        S.menuStub = true
        T.mc0 = #S.menuCalls
        H.rclickAt(gz.x + 6, math.max(gz.y, z.y) + 2)
        S.menuStub = nil
        Q.check(#S.menuCalls == T.mc0, T.L .. ": a right-click on the pinned heading does not open the menu of the row scrolled beneath it [bug 7]",
            (#S.menuCalls - T.mc0) .. " menus asked for (" .. tostring(S.menuCalls[#S.menuCalls] and S.menuCalls[#S.menuCalls].name) .. ")")
    end)
    C.scrollTill(T, "trZ0", function() local gz = RT.cw()._skillsGridZone; return gz and C.under(H.trZones(), gz, false) end)
    H.step(2, function()
        if T.off then return end
        local w = RT.cw()
        local gz, z = w._skillsGridZone, T.trZ0
        if not (gz and z) then Q.skip(T.L .. ": a click on the heading over a training row", "no scroll put a training row under the heading"); return end
        local fr = nil
        pcall(function() fr = S.TF.rect(w, "skills") end)
        local x = gz.x + gz.w + 3
        local y = math.max(gz.y, z.y) + 2
        if x > z.x + z.w - 2 or (fr and x >= fr.x and x < fr.x + fr.w and y >= fr.y and y < fr.y + fr.h) then
            Q.skip(T.L .. ": a click on the heading over a training row", "right of the disclosure the heading is the Find field, which takes its own press")
            return
        end
        T.was = w._trainingExpanded[z.id] and true or false
        H.clickAt(x, y)
        Q.check((w._trainingExpanded[z.id] and true or false) == T.was and w._skillsGridExpanded == true, T.L .. ": a click on the heading right of the disclosure does not fold the training row beneath it [bug 7]",
            tostring(z.id) .. " open " .. tostring(T.was) .. " -> " .. tostring(w._trainingExpanded[z.id]))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S28, S29: live
function C.s28()
    local T = { L = "S28 while open" }
    H.step(2, function()
        H.caseStart(T)
        C.booksBlank({ S.CARP[1] })
        H.atFrac(Perks.Woodwork, 3, 0.1)
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        local sk = H.skillOf(H.pname(Perks.Woodwork))
        T.p0 = sk and sk.xpProgress
        pcall(function() S.p:getXp():AddXPNoMultiplier(Perks.Woodwork, ISSkillProgressBar.getXpForLvl(H.perkOf(Perks.Woodwork), 3) * 0.3) end)
        T.t0 = getTimestampMs()
    end)
    H.wait(1500, function()
        local sk = H.skillOf(H.pname(Perks.Woodwork))
        return T.off or (sk ~= nil and sk.xpProgress ~= T.p0)
    end, function(ok)
        if T.off then return end
        local ms = getTimestampMs() - T.t0
        Q.check(ok and ms <= 450, T.L .. ": XP gained shows on the bar within the tab's 250 ms (and a frame or two)", ms .. " ms; " .. H.n3(T.p0) .. " -> " .. H.n3(H.skillOf(H.pname(Perks.Woodwork)).xpProgress))
        -- the books in view for the pick-up
        pcall(function() RT.cw()._skillsScroll:setScrollPos(1) end)
    end)
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local z = H.trRow("Carpentry")
        T.inV = z ~= nil and H.inView(z)
        T.b1 = C.bookOf(S.CARP[1])
        T.s0 = T.b1 and C.tabState(T.b1)
        T.book = H.give(S.CARP[1])
        T.t0 = getTimestampMs()
    end)
    H.wait(2000, function() return T.off or (T.b1 ~= nil and C.tabState(T.b1) == "collected") end, function(ok)
        if T.off then return end
        local ms = getTimestampMs() - T.t0
        if not T.inV then H.note(T.L .. ": the Carpentry training row was not in view at the bottom of the scroll") end
        Q.check(ok and ms <= 750, T.L .. ": a book picked up shows Collected within the 500 ms refresh (the section in view)", ms .. " ms; " .. tostring(T.s0) .. " -> " .. tostring(T.b1 and C.tabState(T.b1)))
        H.removeItem(T.book)
        pcall(function() RT.cw()._skillsScroll:setScrollPos(0) end)
    end)
    Q.waitMs(900)
    H.step(2, function()
        if T.off then return end
        local z = H.trRow("Carpentry")
        local first = nil
        for _, tz in ipairs(H.trZones()) do if first == nil or tz.y < first.y then first = tz end end
        local v = H.view()
        T.away = first ~= nil and v ~= nil and first.y > v.y + v.h
        if not T.away then return end
        T.s1 = T.b1 and C.tabState(T.b1)
        T.book = H.give(S.CARP[1])
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        if not T.away then Q.skip(T.L .. ": the refresh while the section is scrolled away", "the training section shows at the top of the scroll at this size"); return end
        Q.check(T.b1 ~= nil and C.tabState(T.b1) == T.s1, T.L .. ": scrolled away, the section's walk waits (its state not refreshed while out of view)",
            tostring(T.s1) .. " -> " .. tostring(T.b1 and C.tabState(T.b1)))
    end)
    H.caseEnd(T.L)
end
function C.s29()
    local T = { L = "S29 a level up while watching" }
    H.step(2, function() H.caseStart(T); H.atFrac(Perks.Woodwork, 3, 0.9) end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.intoView(T, function() return H.rowZ(H.pname(Perks.Woodwork)) end)
    H.step(3, function()
        if T.off then return end
        T.b0 = H.badgeIn(H.rowZ(H.pname(Perks.Woodwork)))
        pcall(function() S.p:getXp():AddXPNoMultiplier(Perks.Woodwork, ISSkillProgressBar.getXpForLvl(H.perkOf(Perks.Woodwork), 3) * 0.3) end)
    end)
    H.wait(1500, function() return T.off or H.badgeIn(H.rowZ(H.pname(Perks.Woodwork))) == H.lvl(Perks.Woodwork) and H.lvl(Perks.Woodwork) == 4 end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": the badge follows the level up (getPerkLevel " .. H.lvl(Perks.Woodwork) .. ")", tostring(T.b0) .. " -> " .. tostring(H.badgeIn(H.rowZ(H.pname(Perks.Woodwork)))))
        H.note(T.L .. ": the game's bar flashes and fades on a level up (SPB:131-161); the tab has no flash (a gap)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S30: paused
function C.glassOver(g, dp, x, y)
    if not (g and dp) then return false end
    local ax, ay = dp:getAbsoluteX() + x, dp:getAbsoluteY() + y
    local gx, gy = g:getAbsoluteX(), g:getAbsoluteY()
    return ax >= gx and ax < gx + g:getWidth() and ay >= gy and ay < gy + g:getHeight()
end
function C.s30()
    local T = { L = "S30 paused (Skills)" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        for _, z in ipairs(H.trZones()) do if not z.book then RT.cw()._trainingExpanded[z.id] = true end end
        H.skFresh()
        H.pause(true)
    end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local PL = ZeD.PausedLook
        local w = RT.cw()
        local g = PL and PL._glass
        local z = H.rowZ(H.pname(Perks.Woodwork))
        local tz = H.trZones()[1]
        local gz = w._skillsGridZone
        local dp = H.dp()
        local over = z and tz and gz and C.glassOver(g, dp, H.mid(z)) and C.glassOver(g, dp, H.mid(tz)) and C.glassOver(g, dp, gz.x + 6, gz.y + 4)
        local ate = false
        if g then pcall(function() ate = g:onMouseDown(10, 10) == true and g:onRightMouseDown(10, 10) == true end) end
        Q.check(PL ~= nil and PL.on() and g ~= nil and g:isVisible() and over and ate, T.L .. ": the glass lies over a row, a training row and the heading and eats the press and the right press (no pin, no fold)",
            "paused " .. tostring(PL and PL.on()) .. ", glass " .. tostring(g ~= nil and g:isVisible()) .. ", over all three " .. tostring(over) .. ", eats " .. tostring(ate))
        T.id = "skill:" .. tostring(H.pname(Perks.Woodwork))
        T.go = H.padOn() and H.focusEl(T.id)
        T.mc0 = #S.menuCalls
    end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        local PL = ZeD.PausedLook
        Q.check(T.go and #S.menuCalls == T.mc0 and PL.blocks(RT.cw()), T.L .. ": the pad's A on a row does nothing while paused (PL.blocks)", (#S.menuCalls - T.mc0) .. " menus asked for")
        H.lockBack()
        H.mouseOn()
        local w = RT.cw()
        local g = PL._glass
        T.pos0 = w._skillsScroll.scrollPos
        local dp = H.dp()
        H.hoverOn(math.floor(dp:getWidth() / 2), math.floor(dp:getHeight() / 2))
        if g then H.zcall(function() g:onMouseWheel(1) end); H.zcall(function() g:onMouseWheel(1) end) end
        T.pos1 = w._skillsScroll.scrollPos
        local z = H.rowZ(H.pname(Perks.Woodwork))
        for _, rz in ipairs(w._skillRowZones or {}) do if not (z and H.inView(z)) and H.inView(rz) then z = rz end end
        if z then H.hoverOn(z.x + math.floor(z.w / 3), z.y + math.floor(z.h / 2)) end
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        Q.check(T.pos1 ~= T.pos0, T.L .. ": the wheel over the glass still scrolls the tab", H.n3(T.pos0) .. " -> " .. H.n3(T.pos1))
        Q.check(S.skHelp ~= nil and S.skHelp ~= "", T.L .. ": the help line still reads under the pointer", tostring(S.skHelp))
        H.hoverOff()
        H.pause(false)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== S31: the screen given back to the game
-- name: the key (TOGGLE_SKILL_PANEL or TOGGLE_INFO_PANEL)
function C.screenCase(T, name)
    H.step(2, function()
        H.caseStart(T)
        if not H.screenOpt() then T.off = true; Q.skip(T.L, "ZeD setup has no Character info screen switch"); return end
        if not H.keyOf(name) then T.off = true; Q.skip(T.L, "the game has no such key bound here"); return end
        RT.pairShut()
        H.screenSet(2)
    end)
    Q.waitMs(1200)
    H.step(2, function() if not T.off then H.gameKey(name) end end)
    H.wait(3000, function() return T.off or H.gameWinUp() end, function(ok)
        if T.off then return end
        Q.check(ok and not RT.isOpen(), T.L .. ": the Character info screen given to the game (ZeD setup), the key shows the game's own window",
            "the game's window up " .. tostring(H.gameWinUp()) .. "; ZeD's " .. H.tabText())
        H.screenBack()
    end)
    H.wait(3000, function() return T.off or not H.gameWinUp() end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": switched back to ZeD's, the game's window goes (CI:218-226)", "the game's window up " .. tostring(H.gameWinUp()))
    end)
    H.caseEnd(T.L)
end
function C.s31() C.screenCase({ L = "S31 the game's screen (Skills key)" }, "TOGGLE_SKILL_PANEL") end

-- ===================================================================== S32 to S35
function C.s32()
    H.step(2, function()
        local ids = {}
        for _, e in ipairs(S.ST.extras or {}) do ids[#ids + 1] = tostring(e.id) end
        H.note("S32 add-ons: the Skills tab's extras loaded: " .. H.list(ids) .. " (RecipeIndex's is ZeD's own)")
        Q.skip("S32 Skill Recovery Journal, Exp Recovery and Clear Skill Sheet's lanes, keys, tags and card lines", "the add-on mods")
        Q.skip("S32 a mod perk with a new parent; a mod skill book whose SkillTrained is not a SkillBook key", "a mod that adds them")
        Q.skip("S34 split screen, the second player's Skills key", "a second controller")
        Q.skip("S35 multiplayer: XP from the server, pins after a reconnect", "a server")
    end)
end
function C.s33()
    local T = { L = "S33 layout and the look" }
    H.step(2, function()
        H.caseStart(T)
        H.pinsClear()
        H.atFrac(Perks.Woodwork, 3, 0.4)
        S.PN.toggle(S.p, "skill", H.pname(Perks.Woodwork), H.pname(Perks.Woodwork))
    end)
    H.toTab(T, "skills", T.L)
    H.skWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local z = H.trRow("Carpentry")
        if z then RT.cw()._trainingExpanded[z.id] = true end
        H.skFresh()
    end)
    Q.waitMs(600)
    H.shot("sk_skills_" .. H.sizeTag(), "the Skills tab in the found theme: Carpentry pinned (its row and the title bar), its training row open", function() return not T.off end)
    for _, th in ipairs(S.THEMES) do
        H.step(2, function() if not T.off then H.theme(th.key) end end)
        Q.waitMs(900)
        H.step(2, function()
            if T.off then return end
            local all = {}
            for _, z in ipairs(RT.cw()._skillRowZones or {}) do all[#all + 1] = z end
            for _, z in ipairs(H.trZones()) do all[#all + 1] = z end
            H.zonesInside(T.L .. ", " .. th.word, S.skRect, all, H.view())
        end)
    end
    H.step(2, function() H.themeBack() end)
    H.step(2, function() if not T.off then H.sizeSet("large") end end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        local all = {}
        for _, z in ipairs(RT.cw()._skillRowZones or {}) do all[#all + 1] = z end
        for _, z in ipairs(H.trZones()) do all[#all + 1] = z end
        H.zonesInside(T.L .. ", Large text", S.skRect, all, H.view())
        Q.skip(T.L .. " at UI scale 2 and in DE and RU", "the runner's own size and language")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== Info: the game's own Info page functions on a stand-in
-- (ISCharacterScreen's loaders read only self.char and write their answer on self)
function H.gamePage()
    local fake = { char = S.p, displayedTraits = {} }
    pcall(ISCharacterScreen.loadBeardAndHairStyle, fake)
    pcall(ISCharacterScreen.loadFavouriteWeapon, fake)
    pcall(ISCharacterScreen.loadProfession, fake)
    pcall(ISCharacterScreen.setDisplayedTraits, fake)
    return fake
end
-- a word the Info tab drew this frame, in any case (heads and the license draw in their own text case)
function H.idText(sub)
    local l = H.lower(sub)
    for _, t in ipairs(S.idT or {}) do if H.has(H.lower(t.s), l) then return t end end
    return nil
end
function H.idView() local w = RT.cw(); return w and w._idView end

-- ===================================================================== I1: ways in
function C.i1()
    local T = { L = "I1 ways in" }
    H.step(2, function()
        H.caseStart(T)
        T.noKey = H.keyOf("TOGGLE_INFO_PANEL") == nil
        if T.noKey then Q.skip(T.L .. ": the Info key", "the game has no Info key bound here") else RT.pairShut() end
    end)
    H.wait(4000, function() return T.noKey or not RT.isOpen() end, function() if not T.noKey then H.gameKey("TOGGLE_INFO_PANEL") end end)
    H.wait(3000, function() return T.noKey or H.on("identity") end, function(ok)
        if T.noKey then return end
        Q.check(ok and not H.gameWinUp(), T.L .. ": the Info key (the game's handler) with both shut opens Info, the game's window hidden", H.tabText())
        H.gameKey("TOGGLE_INFO_PANEL")
    end)
    H.wait(3000, function() return T.noKey or not RT.isOpen() end, function(ok)
        if T.noKey then return end
        Q.check(ok, T.L .. ": the Info key again shuts what it opened", H.tabText())
    end)
    H.step(2, function() RT.pairOpen() end)
    H.wait(4000, function() return RT.isOpen() end, function() RT.charTab("loot") end)
    H.step(10, function() T.s = RT.charTab("identity") end)
    H.wait(3000, function() return H.on("identity") end, function(ok)
        Q.check(ok and T.s, T.L .. ": the tab strip's I opens Info", H.tabText())
        RT.charTab("loot")
    end)
    H.step(10, function()
        local list = {}
        pcall(function() list = ZeD.DpadWheels.C.tabs(S.p, S.pn) end)
        for _, e in ipairs(list) do if e.key == "identity" then T.e = e end end
        if T.e then H.zcall(function() T.e.run(S.p, S.pn) end) else Q.skip(T.L .. ": the wheel", "the wheel's Tabs slice has no Info entry") end
    end)
    H.wait(3000, function() return T.e == nil or H.on("identity") end, function(ok)
        if T.e then Q.check(ok, T.L .. ": the D-pad wheel's Tabs slice, its Info entry, opens Info", H.tabText()) end
        RT.charTab("loot")
    end)
    H.step(10, function()
        local lite = false
        pcall(function() lite = ZeD.Settings.lite() and true or false end)
        T.buckle = ZeD.Belt and ZeD.Belt.buckleAct and not lite
        if not T.buckle then Q.skip(T.L .. ": the belt's buckle", lite and "Lite has no buckle" or "the belt is not loaded"); return end
        H.note(T.L .. ": the buckle's own click (its belt HUD's place) runs ZeD.Belt.buckleAct; run here directly")
        H.zcall(function() ZeD.Belt.buckleAct(S.pn) end)
    end)
    H.wait(3000, function() return not T.buckle or H.on("identity") end, function(ok)
        if T.buckle then Q.check(ok, T.L .. ": the belt's profession buckle opens Info", H.tabText()) end
        RT.charTab("loot")
    end)
    H.step(10, function()
        T.lip = H.give("Base.Lipstick")
        H.give("Base.Mirror")
        if not (T.lip and ZeD.MakeUp and ZeD.MakeUp.open) then T.noMU = true; Q.skip(T.L .. ": a lipstick's Make Up option", "no lipstick or no make-up module"); return end
        H.zcall(function() T.muOk = ZeD.MakeUp.open(S.p, T.lip) end)
    end)
    H.wait(3000, function() local w = RT.cw(); return T.noMU or (H.on("identity") and w._hb ~= nil and w._hb.part == "makeup") end, function(ok)
        if T.noMU then return end
        local w = RT.cw()
        Q.check(ok and T.muOk, T.L .. ": a lipstick's Make Up option opens Info on Hair and beard's make-up part", H.tabText() .. ", part " .. tostring(w._hb and w._hb.part))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== I2 to I5: name, weight, trend, sex
function C.i2leg(T, fore, sur, what)
    H.step(2, function()
        if T.off then return end
        pcall(function() local d = S.p:getDescriptor(); d:setForename(fore); d:setSurname(sur) end)
    end)
    H.idWait(T, T.L .. " " .. what, function() return H.idData().forename == fore end)
    H.step(2, function()
        if T.off then return end
        local d = H.idData()
        local gf, gs = "", ""
        pcall(function() gf, gs = S.p:getDescriptor():getForename(), S.p:getDescriptor():getSurname() end)
        local game = gf .. " " .. gs
        -- (an empty capture comes back nil in the game's Lua: a blank name is tested by itself)
        local blank = string.find(game, "%S") == nil
        local trimmed = blank and "" or (string.match(game, "^%s*(.-)%s*$") or game)
        if blank then
            H.note(T.L .. " " .. what .. ": the game draws a blank name (\"" .. game .. "\"); the tab: " .. tostring(d.nameFull) .. " / " .. tostring(d.nameComma))
            Q.check(d.nameFull ~= "", T.L .. " " .. what .. ": both names empty, the card still shows a word", tostring(d.nameFull))
            return
        end
        local comma = (gs ~= "" and gf ~= "") and (gs .. ", " .. gf) or (gs .. gf)
        Q.check(d.nameFull == trimmed and d.nameComma == comma, T.L .. " " .. what .. ": the names against the descriptor (the game's \"Forename Surname\", ISCS:84)",
            "full \"" .. tostring(d.nameFull) .. "\", comma \"" .. tostring(d.nameComma) .. "\"; game \"" .. game .. "\"")
    end)
end
function C.i2()
    local T = { L = "I2 the name" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    C.i2leg(T, "Angel", "Cross", "both")
    C.i2leg(T, "Angel", "", "no surname")
    C.i2leg(T, "", "", "both empty")
    C.i2leg(T, "Angel", "Abcdefghijklmnopqrstuvwxyzabcd", "a 30-letter surname")
    H.step(2, function() if not T.off then RT.bounds(Q, T.L .. ", a 30-letter surname") end end)
    H.caseEnd(T.L)
end
function C.i3()
    local T = { L = "I3 the weight" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    for _, wt in ipairs({ 79.4, 79.6, 80.0 }) do
        H.step(2, function() if not T.off then pcall(function() S.p:getNutrition():setWeight(wt) end) end end)
        H.idWait(T, T.L .. " " .. wt)
        H.step(2, function()
            if T.off then return end
            local g = 0
            pcall(function() g = S.p:getNutrition():getWeight() end)
            local mine = tonumber(string.match(tostring(H.idData().weightStr), "(%d+)") or "")
            local want = H.gameRound(g)
            Q.check(mine == want, T.L .. " at " .. H.n2(g) .. " kg: the tab's number against the game's round (ISCS:117) [bug 2]", tostring(H.idData().weightStr) .. "; the game " .. tostring(want))
        end)
    end
    H.caseEnd(T.L)
end
function C.i4()
    local T = { L = "I4 the weight's trend" }
    local LEGS = { { k = "inc", inc = true }, { k = "lot", inc = true, lot = true }, { k = "dec", dec = true }, { k = "steady" } }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    for _, lg in ipairs(LEGS) do
        H.step(2, function()
            if T.off then return end
            pcall(function()
                local n = S.p:getNutrition()
                n:setIncWeight(lg.inc and true or false)
                n:setIncWeightLot(lg.lot and true or false)
                n:setDecWeight(lg.dec and true or false)
            end)
        end)
        H.idWait(T, T.L .. " " .. lg.k)
        H.step(1, function()
            if T.off then return end
            local inc, lot, dec = false, false, false
            pcall(function() local n = S.p:getNutrition(); inc, lot, dec = n:isIncWeight(), n:isIncWeightLot(), n:isDecWeight() end)
            local want = (lot and "++") or (inc and "+") or (dec and "-") or ""
            if (lot and true or false) ~= (lg.lot and true or false) or (inc and true or false) ~= (lg.inc and true or false) then
                H.note(T.L .. " " .. lg.k .. ": the game's Nutrition changed the staged flags before the read (inc " .. tostring(inc) .. ", lot " .. tostring(lot) .. ", dec " .. tostring(dec) .. ")")
            end
            Q.check(H.idData().trend == want, T.L .. " " .. lg.k .. ": the sign against the game's flags (isIncWeightLot, isIncWeight, isDecWeight; ISCS:118-129)",
                "\"" .. tostring(H.idData().trend) .. "\"; the game \"" .. want .. "\"")
        end)
    end
    H.step(2, function() H.note(T.L .. ": the sign's help line needs the pointer on the sign, whose place the license keeps to itself (not read here)") end)
    H.caseEnd(T.L)
end
function C.i5()
    local T = { L = "I5 sex" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local fem = S.p:isFemale()
        local want = getText(fem and "IGUI_char_Female" or "IGUI_char_Male")
        Q.check(H.idData().sexStr == want, T.L .. ": the card's sex against isFemale (" .. tostring(fem) .. ")", tostring(H.idData().sexStr) .. "; the game " .. want)
        Q.skip(T.L .. ": the other sex", "changing the sex rebuilds his body and clothes: not staged on the QA character")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== I6: professions (bugs 13, 14)
function C.i6()
    local T = { L = "I6 professions" }
    local PERMIT = { ["base:policeofficer"] = "yes", ["base:veteran"] = "yes", ["base:securityguard"] = "yes", ["base:parkranger"] = "yes", ["base:burglar"] = "revoked" }
    local profs = {}
    pcall(function()
        local list = CharacterProfessionDefinition.getProfessions()
        for i = 0, list:size() - 1 do local d = list:get(i); profs[#profs + 1] = { id = d:getType():toString(), ui = tostring(d:getUIName()) } end
    end)
    H.step(2, function()
        H.caseStart(T)
        T.bad, T.badP, T.n = {}, {}, 0
        local fake = H.gamePage()
        T.own = fake.profession
        if #profs == 0 then T.off = true; Q.skip(T.L, "the game's profession list could not be read") end
    end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        Q.check(H.idData().profession == T.own, T.L .. ": his own profession against the game's loadProfession", tostring(H.idData().profession) .. "; the game " .. tostring(T.own))
    end)
    for _, pr in ipairs(profs) do
        H.step(2, function() if not T.off then S.IT.qaProf = pr.id end end)
        H.step(3, function()
            if T.off then return end
            local d = H.idData()
            if not d then return end
            T.n = T.n + 1
            if d.profession ~= pr.ui then T.bad[#T.bad + 1] = pr.id .. " \"" .. tostring(d.profession) .. "\" (game \"" .. pr.ui .. "\")" end
            local want = PERMIT[pr.id]
            if pr.id == "base:burgerflipper" then T.flip = d.permit
            elseif d.permit ~= want then T.badP[#T.badP + 1] = pr.id .. " " .. tostring(d.permit) end
        end)
    end
    H.step(2, function()
        if T.off then return end
        S.IT.qaProf = nil
        Q.check(T.n == #profs and #T.bad == 0, T.L .. ": every profession's name as the game's getUIName gives it (ISCS:638-648) [bug 13]", T.n .. " of " .. #profs .. " read; differ " .. H.list(T.bad, 6))
        Q.check(#T.badP == 0, T.L .. ": the carry permit: the armed jobs carry one, the burglar's is revoked, the rest none", H.list(T.badP, 6))
        H.note(T.L .. ": burger flipper's carry permit on the card: " .. tostring(T.flip) .. " (to confirm with the director) [bug 14]")
        H.note(T.L .. ": a mod profession named in capitals (EMT, DJ) cannot be staged without its mod; the title case lowers its letters (IT:362-365)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== I7 to I9: hair, beard, color, body hair
function C.styles(female)
    local o = {}
    pcall(function()
        local l = female and getHairStylesInstance():getAllFemaleStyles() or getHairStylesInstance():getAllMaleStyles()
        for i = 0, l:size() - 1 do o[#o + 1] = l:get(i) end
    end)
    return o
end
function C.hairLegs()
    local fem = S.p:isFemale()
    local legs, short, long, tied = {}, nil, nil, nil
    legs[#legs + 1] = { what = "bald", hair = "Bald" }
    for _, st in ipairs(C.styles(fem)) do
        local nm, lv, at = "", 0, false
        pcall(function() nm, lv, at = st:getName(), st:getLevel(), st:isAttachedHair() end)
        if nm ~= "" and nm ~= "Bald" then
            if at then tied = tied or nm
            else
                if lv > 0 and (short == nil or lv < short.lv) then short = { nm = nm, lv = lv } end
                if long == nil or lv > long.lv then long = { nm = nm, lv = lv } end
            end
        end
    end
    if short then legs[#legs + 1] = { what = "short (" .. short.nm .. ")", hair = short.nm } end
    if long then legs[#legs + 1] = { what = "long (" .. long.nm .. ")", hair = long.nm } end
    if tied then legs[#legs + 1] = { what = "tied (" .. tied .. ")", hair = tied } end
    if not fem then
        legs[#legs + 1] = { what = "no beard", beard = "" }
        local g = nil
        pcall(function()
            local l = getBeardStylesInstance():getAllStyles()
            for i = 0, l:size() - 1 do local nm = l:get(i):getName(); if nm == "Goatee" then g = nm elseif g == nil and nm ~= "" then g = nm end end
        end)
        if g then legs[#legs + 1] = { what = "beard " .. g, beard = g } end
    end
    return legs
end
function C.i7()
    local T = { L = "I7 hair and beard" }
    H.step(2, function() H.caseStart(T); T.legs = C.hairLegs() end)
    H.toTab(T, "identity", T.L)
    for i = 1, 6 do
        H.step(2, function()
            local lg = T.legs and T.legs[i]
            if T.off or not lg then return end
            pcall(function()
                local hv = H.hv()
                if lg.hair then hv:setHairModel(lg.hair) end
                if lg.beard then hv:setBeardModel(lg.beard) end
            end)
            pcall(function() S.p:resetModelNextFrame() end)
        end)
        H.idWait(T, T.L .. " " .. i)
        H.step(2, function()
            local lg = T.legs and T.legs[i]
            if T.off or not lg then return end
            local d, g = H.idData(), H.gamePage()
            if lg.hair then
                Q.check(d.hairStyle == g.hairStyle, T.L .. " " .. lg.what .. ": the hair style's words against the game's loadBeardAndHairStyle", tostring(d.hairStyle) .. "; the game " .. tostring(g.hairStyle))
            else
                Q.check(d.facialHair == g.beardStyle, T.L .. " " .. lg.what .. ": the beard's words against the game's (IGUI_Beard_None for none, ISCS:628)", tostring(d.facialHair) .. "; the game " .. tostring(g.beardStyle))
            end
        end)
    end
    H.step(2, function() if S.p:isFemale() then H.note(T.L .. ": she has no beard row in the game; the card says " .. tostring(H.idData() and H.idData().facialHair)) else Q.skip(T.L .. " as a woman", "the sex is not changed on the QA character") end end)
    H.caseEnd(T.L)
end
function C.color(r, g, b)
    local c = nil
    pcall(function() c = ImmutableColor.new(r, g, b, 1) end)
    return c
end
function C.i8()
    local T = { L = "I8 hair color" }
    local COLS = { { "black", 0.05, 0.05, 0.05 }, { "dark brown", 0.25, 0.17, 0.10 }, { "blonde", 0.90, 0.80, 0.50 }, { "white", 0.95, 0.95, 0.95 },
                   { "ginger", 0.70, 0.30, 0.10 }, { "grey 0.6", 0.6, 0.6, 0.6 }, { "grey 0.4", 0.4, 0.4, 0.4 } }
    H.step(2, function() H.caseStart(T); T.words = {} end)
    H.toTab(T, "identity", T.L)
    for _, c in ipairs(COLS) do
        H.step(2, function()
            if T.off then return end
            local col = C.color(c[2], c[3], c[4])
            if not col then T.noCol = true; return end
            pcall(function() H.hv():setHairColor(col) end)
        end)
        H.idWait(T, T.L .. " " .. c[1])
        H.step(2, function() if not T.off and not T.noCol then T.words[c[1]] = tostring(H.idData().hairColor) end end)
    end
    H.step(2, function()
        if T.off then return end
        if T.noCol then Q.skip(T.L, "a hair color could not be made here (ImmutableColor)"); return end
        local o = {}
        for _, c in ipairs(COLS) do o[#o + 1] = c[1] .. " = " .. tostring(T.words[c[1]]) end
        H.note(T.L .. ": " .. table.concat(o, "; "))
        local browns = { [getText("ContextMenu_Light_Brown")] = true, [getText("ContextMenu_Brown")] = true, [ZeD.tr("UI_ZeD_Identity_HairDarkBrown")] = true,
                         [ZeD.tr("UI_ZeD_Identity_HairBlonde")] = true, [ZeD.tr("UI_ZeD_Identity_HairAuburn")] = true }
        Q.check(not browns[T.words["grey 0.6"]] and not browns[T.words["grey 0.4"]], T.L .. ": a neutral grey reads neither a brown nor blonde [bug 11]",
            "grey 0.6 \"" .. tostring(T.words["grey 0.6"]) .. "\", grey 0.4 \"" .. tostring(T.words["grey 0.4"]) .. "\"")
    end)
    H.caseEnd(T.L)
end
function C.i9()
    local T = { L = "I9 body hair" }
    H.step(2, function() H.caseStart(T); T.words = {} end)
    H.toTab(T, "identity", T.L)
    for i = 0, 4 do
        H.step(2, function() if not T.off then pcall(function() H.hv():setBodyHairIndex(i) end) end end)
        H.idWait(T, T.L .. " " .. i)
        H.step(2, function()
            if T.off then return end
            local got = -1
            pcall(function() got = H.hv():getBodyHairIndex() end)
            T.words[#T.words + 1] = i .. " (game " .. got .. ") " .. tostring(H.idData().bodyHair)
            T["w" .. i] = H.idData().bodyHair
        end)
    end
    H.step(2, function()
        if T.off then return end
        local seen, dup = {}, false
        for i = 0, 4 do local v = tostring(T["w" .. i]); if seen[v] then dup = true end; seen[v] = true end
        Q.check(T.w0 == getText("IGUI_None") and not dup, T.L .. ": index 0 reads the game's None and each of 0 to 4 its own word", H.list(T.words))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== I10 to I14: survived, favorite, kills, DL, dates
function C.i10()
    local T = { L = "I10 survived for" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local vis = nil
        pcall(function() local c = UIManager.getClock(); vis = c ~= nil and c:isDateVisible() and true or false end)
        local d = H.idData()
        local game = "?"
        pcall(function() game = tostring(S.p:getTimeSurvived()) end)
        local shown = d.timeSurv ~= nil and d.timeSurv ~= "--" and H.idText(tostring(d.survLines and d.survLines[1] or d.timeSurv)) ~= nil
        Q.check(d.timeSurv == game, T.L .. ": the time survived against getTimeSurvived", tostring(d.timeSurv) .. "; the game " .. game)
        Q.check(vis == nil or shown == vis, T.L .. ": shown exactly when the game shows it (while the clock's date shows, ISCS:237-240) [bug 6]",
            "the clock's date visible " .. tostring(vis) .. ", the tab draws it " .. tostring(shown))
        if vis then H.note(T.L .. ": the clock's date shows now; the state without it (no watch) is not staged") end
    end)
    H.caseEnd(T.L)
end
function C.i11()
    local T = { L = "I11 favorite weapon" }
    H.step(2, function()
        H.caseStart(T)
        local md = S.p:getModData()
        local drop = {}
        for k in pairs(md) do if type(k) == "string" and string.sub(k, 1, 4) == "Fav:" then drop[#drop + 1] = k end end
        for _, k in ipairs(drop) do md[k] = nil end
    end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local g = H.gamePage()
        Q.check(g.favouriteWeapon == nil, T.L .. ": no Fav keys: the game has no favorite (it hides the row, ISCS:222-226)", tostring(g.favouriteWeapon))
        H.note(T.L .. ": with none the tab shows \"" .. tostring(H.idData().favWeapon) .. "\" where the game shows no row (a different rule)")
        local md = S.p:getModData()
        md["Fav:Axe"] = 5
        md["Fav:Baseball Bat"] = 7
    end)
    H.idWait(T, T.L .. " 2")
    H.step(2, function()
        if T.off then return end
        local g = H.gamePage()
        Q.check(H.idData().favWeapon == g.favouriteWeapon and g.favouriteWeapon ~= nil, T.L .. ": Fav:Axe 5 and Fav:Baseball Bat 7 against the game's loadFavouriteWeapon",
            tostring(H.idData().favWeapon) .. "; the game " .. tostring(g.favouriteWeapon))
    end)
    H.caseEnd(T.L)
end
function C.i12()
    local T = { L = "I12 kills" }
    H.step(2, function()
        H.caseStart(T)
        pcall(function() ZeD.KillTracker.data(S.p) end)
        pcall(function() S.p:setZombieKills(S.p:getZombieKills() + 10) end)
    end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local gk = S.p:getZombieKills()
        local kd = S.p:getModData().ZeD_Kills
        local fire = (type(kd) == "table" and tonumber(kd.fire)) or 0
        Q.check(H.idData().zKills == tostring(gk + fire), T.L .. ": 10 more by the game's count: the tab against getZombieKills plus the fire kills",
            tostring(H.idData().zKills) .. "; the game " .. gk .. " + fire " .. fire)
        T.before = tonumber(H.idData().zKills)
        if type(kd) == "table" then S.back.fire = true; kd.fire = fire + 1 else T.noFire = true end
    end)
    H.idWait(T, T.L .. " fire")
    H.step(2, function()
        if T.off then return end
        if T.noFire then Q.skip(T.L .. ": a fire kill", "KillTracker's table is not there"); return end
        local gk = S.p:getZombieKills()
        Q.check(tonumber(H.idData().zKills) == (T.before or -9) + 1, T.L .. ": one fire kill (as KillTracker counts a burn) reads one more than the game's count",
            tostring(H.idData().zKills) .. "; the game " .. gk)
        H.note(T.L .. ": the burn itself (a zombie set alight and dying of it) is not staged; KillTracker's count was raised as its two deaths raise it")
    end)
    H.caseEnd(T.L)
end
function C.i13()
    local T = { L = "I13 the DL number" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    H.step(2, function() if not T.off then T.dl0 = H.idData().dlNo; RT.charTab("loot") end end)
    H.step(10, function() if not T.off then RT.charTab("identity") end end)
    H.idWait(T, T.L .. " reopened")
    H.step(2, function()
        if T.off then return end
        Q.check(H.idData().dlNo == T.dl0, T.L .. ": the same after the tab is left and opened again", tostring(T.dl0) .. " / " .. tostring(H.idData().dlNo))
        pcall(function() S.p:getDescriptor():setSurname(string.char(0x0416) .. "ukov") end)
    end)
    H.idWait(T, T.L .. " Cyrillic", function() return string.byte(tostring(H.idData().surname), 1) == 0x0416 end)
    H.step(2, function()
        if T.off then return end
        local c = string.byte(tostring(H.idData().dlNo), 1)
        Q.check(c == 0x0416, T.L .. ": a Cyrillic surname's first letter starts the DL number [bug 10]", "the first character's code " .. tostring(c) .. ", wanted " .. 0x0416)
        pcall(function() S.p:getDescriptor():setSurname(string.char(0x00E9) .. "lise") end)
    end)
    H.idWait(T, T.L .. " accented", function() return string.byte(tostring(H.idData().surname), 1) == 0x00E9 end)
    H.step(2, function()
        if T.off then return end
        local c = string.byte(tostring(H.idData().dlNo), 1)
        Q.check(c == 0x00C9, T.L .. ": an accented small first letter starts the DL number as its capital [bug 10]", "the first character's code " .. tostring(c) .. ", wanted " .. 0x00C9)
        Q.skip(T.L .. ": the narrow license's SEX letter in Russian and Japanese", "a game started in each language")
    end)
    H.caseEnd(T.L)
end
function C.i14()
    local T = { L = "I14 dates" }
    H.step(2, function()
        H.caseStart(T)
        H.sbSet("StartMonth", 7)
        H.sbSet("StartDay", 9)
        H.sbSet("StartYear", 1)
    end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        local fy = 1993
        pcall(function() fy = getSandboxOptions():getFirstYear() end)
        local m, d, y = SandboxVars.StartMonth, SandboxVars.StartDay, SandboxVars.StartYear
        local yr = fy + (y or 1) - 1
        local iss = string.format("%02d/%02d/%04d", m or 0, d or 0, yr)
        local exp = string.format("%02d/%02d/%04d", m or 0, d or 0, yr + 4)
        Q.check(H.idData().issStr == iss and H.idData().expStr == exp, T.L .. ": issued and expires against the sandbox's start date (month " .. tostring(m) .. ", day " .. tostring(d) .. ", year " .. tostring(y) .. " = " .. yr .. ")",
            tostring(H.idData().issStr) .. " / " .. tostring(H.idData().expStr) .. "; the game " .. iss .. " / " .. exp)
        Q.skip(T.L .. ": a multiplayer client's dates", "a server")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== I15, I16: traits (bugs 5, 9)
function C.traitsJudge(T, label)
    local d, g = H.idData(), H.gamePage()
    local mine, game, pos, neg = {}, {}, 0, 0
    for _, t in ipairs(d.posTraits or {}) do mine[#mine + 1] = tostring(t.name) end
    for _, t in ipairs(d.negTraits or {}) do mine[#mine + 1] = tostring(t.name) end
    for _, def in ipairs(g.displayedTraits or {}) do
        local l, c = "?", 0
        pcall(function() l, c = tostring(def:getLabel()), def:getCost() end)
        game[l] = true
        if c >= 0 then pos = pos + 1 else neg = neg + 1 end
    end
    local extra, gn = {}, 0
    for _, n in ipairs(mine) do if not game[n] then extra[#extra + 1] = n end end
    for _ in pairs(game) do gn = gn + 1 end
    Q.check(#extra == 0 and #mine == gn, label .. ": the traits listed are the game's displayed traits (those with an icon, ISCS:575-583) [bug 5]",
        #mine .. " listed, the game " .. gn .. "; not the game's " .. H.list(extra, 6))
    Q.check(#(d.posTraits or {}) == pos and #(d.negTraits or {}) == neg, label .. ": cost 0 or more under Positive, below 0 under Negative",
        "positive " .. #(d.posTraits or {}) .. " (game " .. pos .. "), negative " .. #(d.negTraits or {}) .. " (game " .. neg .. ")")
    local sorted = true
    for _, list in ipairs({ d.posTraits or {}, d.negTraits or {} }) do
        for i = 2, #list do if tostring(list[i].name) < tostring(list[i - 1].name) then sorted = false end end
    end
    Q.check(sorted, label .. ": each group sorted by its label")
    if #(d.posTraits or {}) > 0 then
        local head = ZeD.tr("UI_ZeD_Identity_TraitsPositive", #d.posTraits)
        Q.check(H.idText(head) ~= nil, label .. ": the Positive head drawn with its count", head)
    end
end
function C.i15()
    local T = { L = "I15 traits" }
    H.step(2, function()
        H.caseStart(T)
        for _, k in ipairs(S.FREE) do H.traitSet(k, true) end
        for _, k in ipairs(S.PROMO) do H.traitSet(k, true) end
        for _, k in ipairs(S.NEG) do H.traitSet(k, true) end
    end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    H.step(2, function()
        if T.off then return end
        C.traitsJudge(T, T.L .. " (free, two positive, two negative)")
        local free = nil
        pcall(function() free = tostring(CharacterTraitDefinition.getCharacterTraitDefinition(CharacterTrait[S.FREE[1]]):getLabel()) end)
        local inPos = false
        for _, t in ipairs(H.idData().posTraits or {}) do if t.name == free then inPos = true end end
        Q.check(free ~= nil and inPos, T.L .. ": a free trait (cost 0) is under Positive", tostring(free))
        for _, t in ipairs(H.knownTraits()) do pcall(function() S.p:getCharacterTraits():remove(t) end) end
    end)
    H.idWait(T, T.L .. " none")
    Q.waitMs(200)
    H.step(2, function()
        if T.off then return end
        local d = H.idData()
        local word = ZeD.tr("UI_ZeD_Identity_NoTraits")
        Q.check(#(d.posTraits or {}) == 0 and #(d.negTraits or {}) == 0 and H.idText(word) ~= nil, T.L .. ": none: the tab says " .. word, #H.knownTraits() .. " known")
        pcall(function() RT.cw()._identityScroll:setScrollPos(1) end)
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        local t, v = H.idText(ZeD.tr("UI_ZeD_Identity_NoTraits")), H.idView()
        local fh = 0
        pcall(function() fh = ZeD.TM:getFontHeight(ZeD.T.fontF2) end)
        local sc = RT.cw()._identityScroll
        if not (sc and sc.visible) then H.note(T.L .. ": the tab does not scroll at this size, so a short measure cannot show; the line's foot " .. tostring(t and (t.y + fh)) .. ", the view's " .. tostring(v and (v.y + v.h))) end
        Q.check(t ~= nil and v ~= nil and t.y + fh <= v.y + v.h + 1, T.L .. ": scrolled to the end, the No traits line lies inside the view (the measure counts it) [bug 9]",
            "line " .. tostring(t and t.y) .. "+" .. fh .. ", view to " .. tostring(v and (v.y + v.h)) .. ", scrolls " .. tostring(sc and sc.visible))
    end)
    H.caseEnd(T.L)
end
function C.i16()
    local T = { L = "I16 a trait's description" }
    H.step(2, function()
        H.caseStart(T)
        for _, k in ipairs(S.PROMO) do H.traitSet(k, true) end
    end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    Q.waitMs(200)
    H.step(2, function()
        if T.off then return end
        local w = RT.cw()
        local z = nil
        for _, tz in ipairs(w._idTraitZones or {}) do if z == nil and tz.y >= (H.idView().y) and tz.y + tz.h <= H.idView().y + H.idView().h then z = tz end end
        if not z then
            for _, tz in ipairs(w._idTraitZones or {}) do if z == nil then z = tz end end
            if z then pcall(function() w._identityScroll:setScrollPos(1) end) end
        end
        if not z then T.off = true; Q.skip(T.L, "no trait row drawn"); return end
        T.zid = z.id
        T.def = nil
        for _, t in ipairs(H.knownTraits()) do
            pcall(function() local d = CharacterTraitDefinition.getCharacterTraitDefinition(t); if tostring(d:getLabel()) == tostring(z.name) then T.def = d end end)
        end
    end)
    Q.waitMs(200)
    H.step(2, function()
        if T.off then return end
        local z = nil
        for _, tz in ipairs(RT.cw()._idTraitZones or {}) do if tz.id == T.zid then z = tz end end
        if not z then T.off = true; return end
        H.mouseOn()
        H.hoverOn(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        local h = S.idHover
        local wantL, wantD = "?", "?"
        pcall(function() wantL, wantD = tostring(T.def:getLabel()), tostring(T.def:getDescription()) end)
        Q.check(h ~= nil and h.title == wantL and tostring(h.body) == wantD, T.L .. " (mouse): the hover card's label and description against the trait's definition",
            tostring(h and h.title) .. "; the game " .. wantL)
        H.hoverOff()
        H.lockBack()
        T.go = H.padOn() and H.focusEl(T.zid)
    end)
    Q.waitMs(1600)
    H.step(2, function()
        if T.off then return end
        local h = S.idHover
        local wantL = "?"
        pcall(function() wantL = tostring(T.def:getLabel()) end)
        Q.check(T.go and h ~= nil and h.title == wantL, T.L .. " (pad): the pad's rest on the trait shows its card", "focus " .. tostring(H.focusedId()) .. ", card " .. tostring(h and h.title))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== I17, I18: the photo and the studio (bug 8)
function C.photoPress(m) pcall(m.onMouseDown, m, 5, 5); pcall(m.onMouseUp, m, 5, 5) end
function C.i17()
    local T = { L = "I17 the photo" }
    H.step(2, function() H.caseStart(T); S.IT.qaLayout = "tall" end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        local w = RT.cw()
        T.m = w._identityModel
        if not T.m then T.off = true; Q.skip(T.L, "no photo model"); return end
        T.sc = w._identityScroll
        if T.sc and T.sc.visible then T.sc:setScrollPos(0.4) end
        T.p0 = w._identityPhotoExpanded and true or false
        C.photoPress(T.m)
        Q.check((w._identityPhotoExpanded and true or false) ~= T.p0 and (not (T.sc and T.sc.visible) or T.sc.scrollPos == 0),
            T.L .. " (mouse): a click on the photo swaps bust and full body and scrolls to the top", tostring(T.p0) .. " -> " .. tostring(w._identityPhotoExpanded) .. ", scroll " .. H.n3(T.sc and T.sc.scrollPos))
        C.photoPress(T.m)
    end)
    H.step(3, function()
        if T.off then return end
        local w = RT.cw()
        local m = T.m
        T.p1 = w._identityPhotoExpanded and true or false
        pcall(m.onMouseDown, m, 5, 5)
        pcall(m.onMouseMove, m, ZeD.T.px(40), 0)
        pcall(m.onMouseUp, m, 5 + ZeD.T.px(40), 5)
        Q.check((w._identityPhotoExpanded and true or false) == T.p1, T.L .. " (mouse): a drag turns the figure without swapping", tostring(T.p1) .. " -> " .. tostring(w._identityPhotoExpanded))
        -- the wheel on the bust: the tab scrolls, as anywhere else in it (bug 8)
        w._identityPhotoExpanded = false
        if T.sc and T.sc.visible then
            T.sc:setScrollPos(0)
            local took = nil
            pcall(function() took = m:onMouseWheel(1) end)
            T.wheelBust = { pos = T.sc.scrollPos, took = took }
        end
    end)
    H.step(3, function()
        if T.off then return end
        local w = RT.cw()
        if not T.wheelBust then Q.skip(T.L .. ": the wheel on the bust", "the Info tab does not scroll at this size, even narrow")
        else
            Q.check(T.wheelBust.pos > 0, T.L .. ": the wheel with the pointer on the bust scrolls the tab [bug 8]", "scroll " .. H.n3(T.wheelBust.pos) .. " after a notch, the model took it " .. tostring(T.wheelBust.took))
        end
        w._identityPhotoExpanded = true
        w._identityCustomZoom = 0
        T.z = {}
        for i = 1, 30 do pcall(function() T.m:onMouseWheel(1) end); if i == 15 or i == 30 then T.z[#T.z + 1] = w._identityCustomZoom end end
        Q.check(T.z[1] ~= 0 and T.z[1] == T.z[2], T.L .. ": on the full body the wheel zooms, and stops at a bound [bug 8]", "after 15 notches " .. tostring(T.z[1]) .. ", after 30 " .. tostring(T.z[2]))
        w._identityCustomZoom = 0
        w._identityPhotoExpanded = false
        S.IT.qaLayout = nil
    end)
    H.step(3, function()
        if T.off then return end
        T.p2 = RT.cw()._identityPhotoExpanded and true or false
        T.go = H.padOn() and H.focusEl("identity:photo")
    end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        Q.check(T.go and (RT.cw()._identityPhotoExpanded and true or false) ~= T.p2, T.L .. " (pad): A on identity:photo swaps", "focus " .. tostring(H.focusedId()) .. ", " .. tostring(T.p2) .. " -> " .. tostring(RT.cw()._identityPhotoExpanded))
    end)
    H.caseEnd(T.L)
end
function C.i18()
    local T = { L = "I18 the studio" }
    H.step(2, function()
        H.caseStart(T)
        if not (ZeD.Studio and ZeD.Studio.available and ZeD.Studio.available()) then T.off = true; Q.skip(T.L, "the studio is not available (single player only)") end
    end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    H.step(3, function()
        if T.off then return end
        local cam = RT.cw()._studioBtn
        if not cam then T.off = true; Q.skip(T.L, "no camera button on the photo"); return end
        T.sp0 = getGameSpeed()
        H.zcall(function() if cam.forceClick then cam:forceClick() elseif cam.onclick then cam.onclick(cam.target, cam) end end)
    end)
    H.wait(2000, function() return T.off or ZeD.Studio.isOpen() end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. " (mouse): the camera on the photo opens the studio", "open " .. tostring(ZeD.Studio.isOpen()) .. ", speed " .. tostring(getGameSpeed()))
        pcall(ZeD.Studio.close)
    end)
    H.wait(2000, function() return T.off or not ZeD.Studio.isOpen() end, function(ok)
        if T.off then return end
        Q.check(ok and getGameSpeed() == T.sp0, T.L .. ": the studio closes and the speed is back", "speed " .. tostring(getGameSpeed()) .. " (was " .. tostring(T.sp0) .. ")")
        T.go = H.padOn() and H.focusEl("identity:studio")
    end)
    H.tapA(function() return T.go and not T.off end)
    H.wait(2000, function() return T.off or not T.go or ZeD.Studio.isOpen() end, function(ok)
        if T.off then return end
        Q.check(T.go and ok, T.L .. " (pad): A on identity:studio opens the studio", "focus " .. tostring(H.focusedId()))
        pcall(ZeD.Studio.close)
        Q.skip(T.L .. ": no camera in multiplayer", "a server")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== I19, I20: layout and the narrow license
function C.idZones()
    local w = RT.cw()
    local o = {}
    for _, z in ipairs(w._idTraitZones or {}) do o[#o + 1] = z end
    if w._identityPhotoZone then local p = w._identityPhotoZone; o[#o + 1] = { id = "photo", x = p.x, y = p.y, w = p.w, h = p.h } end
    return o
end
function C.i19leg(T, style, layout, label)
    H.step(2, function() if not T.off then S.IT.qaStyle, S.IT.qaLayout = style, layout end end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        local w = RT.cw()
        Q.check(w._idSimple == (style == "simple") and w._idTall == (layout == "tall"), label .. ": the card draws as forced", "simple " .. tostring(w._idSimple) .. ", narrow " .. tostring(w._idTall))
        H.zonesInside(label, S.idRect, C.idZones(), H.idView())
    end)
end
function C.i19()
    local T = { L = "I19 layout" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    Q.waitMs(500)
    H.shot("sk_info_" .. H.sizeTag(), "the Info tab as found (the card in its own style and width, Hair and beard, the traits)", function() return not T.off end)
    C.i19leg(T, "immersive", "wide", T.L .. ", the license wide")
    C.i19leg(T, "immersive", "tall", T.L .. ", the license narrow")
    C.i19leg(T, "simple", "wide", T.L .. ", Simple wide")
    C.i19leg(T, "simple", "tall", T.L .. ", Simple narrow")
    H.step(2, function() S.IT.qaStyle, S.IT.qaLayout = nil, nil end)
    H.halfOn(T)
    H.step(2, function()
        if T.off or not T.half then return end
        H.zonesInside(T.L .. ", the half card", S.idRect, C.idZones(), H.idView())
        Q.check(RT.cw()._idTall == true, T.L .. ": the half card draws the narrow card", "narrow " .. tostring(RT.cw()._idTall))
    end)
    H.caseEnd(T.L)
end
function C.i20()
    local T = { L = "I20 the narrow license at 220" }
    H.step(2, function() H.caseStart(T); S.IT.qaStyle = "immersive"; S.IT.qaProf = "base:burglar" end)
    H.toTab(T, "identity", T.L)
    H.halfOn(T)
    H.idWait(T, T.L)
    Q.waitMs(400)
    H.step(2, function()
        if T.off or not T.half then return end
        local d = H.idData()
        local miss = {}
        for _, s in ipairs({ tostring(d.issStr), tostring(d.expStr), tostring(d.dlNo), tostring((d.survLines or {})[1]) }) do if not H.idText(s) then miss[#miss + 1] = s end end
        Q.check(RT.cw()._idTall == true and #miss == 0, T.L .. ": the narrow license draws ISS, EXP, the DL number and the survived lines", "missing " .. H.list(miss))
        local rv = nil
        for _, t in ipairs(S.idT or {}) do if string.find(string.upper(t.s), "REVOKED", 1, true) then rv = t end end
        Q.check(rv ~= nil and rv.x >= S.idRect.x and rv.x < S.idRect.x + S.idRect.w, T.L .. ": the burglar's REVOKED is drawn inside the card", rv and (math.floor(rv.x) .. "," .. math.floor(rv.y)) or "not drawn")
        local out = {}
        for _, t in ipairs(S.idT or {}) do if t.x < S.idRect.x - 1 or t.x > S.idRect.x + S.idRect.w then out[#out + 1] = t.s end end
        Q.check(#out == 0, T.L .. ": no word starts outside the tab", H.list(out, 6))
        RT.bounds(Q, T.L)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== I21, I23: Hair and beard, make-up
function C.hb() local w = RT.cw(); return w and w._hb end
function C.hbRow(pred)
    local st = C.hb()
    for _, r in ipairs((st and st.rows) or {}) do if r.ok and not r.out and pred(r) then return r end end
    return nil
end
function C.hbZone(key)
    local st = C.hb()
    for _, z in ipairs((st and st.zones) or {}) do if z.item and z.item.kind == "row" and z.item.row and z.item.row.key == key then return z end end
    return nil
end
function C.hbRefresh() local st = C.hb(); if st then st.tick = 999 end end
function C.i21()
    local T = { L = "I21 Hair and beard" }
    H.step(2, function()
        H.caseStart(T)
        T.sc = H.give("Base.Scissors")
    end)
    H.toTab(T, "identity", T.L)
    H.step(2, function()
        if T.off then return end
        if not ZeD.HairBeard then T.off = true; Q.skip(T.L, "Hair and beard is not loaded"); return end
        pcall(ZeD.HairBeard.setPart, RT.cw(), "hair")
        C.hbRefresh()
    end)
    Q.waitMs(600)
    H.wait(3000, function() return T.off or C.hbRow(function(r) return r.part == "hair" end) ~= nil end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.skip(T.L, "with scissors no hair row can be done on this character (" .. tostring(H.hv() and H.hv():getHairModel()) .. ")"); return end
        T.row = C.hbRow(function(r) return r.part == "hair" end)
        T.key = T.row.key
    end)
    -- the row into view (the photo's page scrolled by the wheel), then a click on it and on Cut
    H.wait(4000, function()
        if T.off then return true end
        local z, v = C.hbZone(T.key), H.idView()
        if not (z and v) then return false end
        local my = z.y + math.floor(z.h / 2)
        if my < v.y + 2 then H.wheel(-1); return false end
        if my > v.y + v.h - 2 then H.wheel(1); return false end
        return true
    end, function(ok)
        if T.off then return end
        local z = C.hbZone(T.key)
        if not z then T.off = true; Q.check(false, T.L .. ": the hair row is drawn for its click", T.key); return end
        local x, y = H.mid(z)
        H.clickAt(x, y)
        Q.check(C.hb().sel == T.key, T.L .. " (mouse): a click on a row picks it", "picked " .. tostring(C.hb().sel) .. ", wanted " .. tostring(T.key))
        local b = C.hb().btn
        if b then local bx, by = H.mid(b); H.clickAt(bx, by) end
    end)
    H.wait(2000, function() return T.off or H.qcount("ISCutHair") + H.qcount("ISTrimBeard") > 0 end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. " (mouse): Cut queues the game's own action for the row (" .. tostring(T.row.verb) .. ")", H.qkinds())
        local b = C.hb().btn
        if b and b.stop then local bx, by = H.mid(b); H.clickAt(bx, by) else H.qstop(); T.noStop = true end
    end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        if T.noStop then H.note(T.L .. ": the button did not read Stop while the cut was queued; the queue was cleared by hand") end
        Q.check(H.qcount("ISCutHair") == 0 and H.qcount("ISTrimBeard") == 0, T.L .. " (mouse): Stop clears the queue", H.qkinds())
        H.qstop()
        H.removeItem(T.sc)
        C.hbRefresh()
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        local st = C.hb()
        local bad = {}
        for _, r in ipairs(st.rows or {}) do if r.part == "hair" and r.ok and r.req and string.find(tostring(r.req), "s", 1, true) then bad[#bad + 1] = tostring(r.label) end end
        Q.check(#bad == 0, T.L .. ": without scissors no row that needs them is offered as doable (the game's hairMenu greys them, ISCS:334-450)", H.list(bad, 6))
        if S.p:isFemale() then T.noBeard = true; Q.skip(T.L .. ": a man's trim", "she has no beard"); return end
        T.rz = H.give("Base.Razor")
        pcall(ZeD.HairBeard.setPart, RT.cw(), "beard")
        C.hbRefresh()
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off or T.noBeard then return end
        local r = C.hbRow(function(x) return x.part == "beard" end)
        if not r then T.noTrim = true; Q.skip(T.L .. ": a man's trim", "no beard row can be done (beard " .. tostring(H.hv():getBeardModel()) .. ")"); return end
        T.go = H.padOn() and H.focusEl("hb:row:" .. r.key)
        T.trimVerb = r.verb
    end)
    H.tapA(function() return T.go and not T.off and not T.noTrim and not T.noBeard end)
    H.wait(2000, function() return T.off or T.noBeard or T.noTrim or not T.go or H.qcount("ISTrimBeard") + H.qcount("ISCutHair") > 0 end, function(ok)
        if T.off or T.noBeard or T.noTrim then return end
        Q.check(T.go and H.qcount("ISTrimBeard") > 0, T.L .. " (pad): A on a beard row queues the game's ISTrimBeard (" .. tostring(T.trimVerb) .. ")", "focus " .. tostring(H.focusedId()) .. "; " .. H.qkinds())
        H.qstop()
    end)
    H.caseEnd(T.L)
end
function C.i23()
    local T = { L = "I23 make-up" }
    H.step(2, function()
        H.caseStart(T)
        T.lip = H.give("Base.Lipstick")
        H.give("Base.Mirror")
        if not (T.lip and ZeD.MakeUp and ZeD.MakeUp.open) then T.off = true; Q.skip(T.L, "no lipstick or no make-up module"); return end
        H.zcall(function() ZeD.MakeUp.open(S.p, T.lip) end)
    end)
    H.wait(3000, function() return T.off or (H.on("identity") and C.hb() ~= nil and C.hb().part == "makeup") end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the Make Up option opens the make-up part", H.tabText()) then T.off = true end
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        T.row = C.hbRow(function(r) return r.part == "makeup" and not r.instant end)
        if not T.row then
            local why = nil
            for _, r in ipairs(C.hb().out or {}) do why = why or r.reason end
            T.off = true
            Q.skip(T.L .. ": Apply", "no make-up row can be done here (" .. tostring(why) .. ")")
            return
        end
        H.zcall(function() ZeD.HairBeard.run(RT.cw(), T.row.key) end)
    end)
    H.wait(2000, function() return T.off or H.qcount("ISApplyMakeUp") > 0 end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": Apply on a row queues the game's ISApplyMakeUp", H.qkinds())
        H.qstop()
        H.note(T.L .. ": Apply was pressed through HairBeard.run (the button's own call); Remove is instant and not staged")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== I24, I25: the pad's walk and the live card
function C.i24()
    local T = { L = "I24 the pad's walk" }
    H.step(2, function()
        H.caseStart(T)
        for _, k in ipairs(S.PROMO) do H.traitSet(k, true) end
        for _, k in ipairs(S.NEG) do H.traitSet(k, true) end
    end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        local zs = RT.cw()._idTraitZones or {}
        T.endId = zs[#zs] and zs[#zs].id
        T.go = H.padOn() and H.focusEl("identity:photo")
        if not (T.go and T.endId) then T.off = true; Q.check(false, T.L .. ": the focus lands on the photo and the traits have stops", "focus " .. tostring(H.focusedId()) .. ", last trait " .. tostring(T.endId)) end
        T.seen, T.out, T.kinds = {}, {}, {}
    end)
    H.walk(T, "down", 120, function()
        local id = H.focusedId()
        local e = id and H.stopOf(id)
        local v = H.idView()
        if id and not T.seen[id] then
            T.seen[id] = true
            local k = string.match(tostring(id), "^([^:]+:[^:]+)") or tostring(id)
            T.kinds[k] = true
            if e and v and (e.y < v.y - 1 or e.y + e.h > v.y + v.h + 1) then T.out[#T.out + 1] = tostring(id) end
        end
        if id == T.endId then T.reached = true; return true end
        if id == T.last then T.same = (T.same or 0) + 1 else T.same = 0 end
        T.last = id
        return (T.same or 0) >= 3
    end)
    H.step(2, function()
        if T.off then return end
        local ks = {}
        for k in pairs(T.kinds) do ks[#ks + 1] = k end
        table.sort(ks)
        local hb = false
        for k in pairs(T.kinds) do if string.sub(k, 1, 3) == "hb:" then hb = true end end
        Q.check(T.reached == true and hb, T.L .. ": Down from the photo passes Hair and beard's stops and reaches the last trait", "kinds " .. H.list(ks) .. ", stopped on " .. tostring(H.focusedId()))
        Q.check(#T.out == 0, T.L .. ": each stop the pad lands on is scrolled into view", H.list(T.out, 6))
    end)
    H.caseEnd(T.L)
end
function C.i25()
    local T = { L = "I25 the card follows" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        T.d0 = H.idData()
        local legs = C.hairLegs()
        T.hair = nil
        for _, lg in ipairs(legs) do if lg.hair and lg.hair ~= H.hv():getHairModel() and T.hair == nil then T.hair = lg.hair end end
        pcall(function() S.p:getNutrition():setWeight(S.p:getNutrition():getWeight() + 5) end)
        if T.hair then pcall(function() H.hv():setHairModel(T.hair) end) end
        H.traitSet(S.PROMO[1], true)
        T.f0 = S.idFrames or 0
    end)
    H.wait(3000, function()
        if T.off then return true end
        local d = H.idData()
        return d ~= T.d0 and d.weightStr ~= T.d0.weightStr and (T.hair == nil or d.hairStyle ~= T.d0.hairStyle)
            and #(d.posTraits or {}) + #(d.negTraits or {}) ~= #(T.d0.posTraits or {}) + #(T.d0.negTraits or {})
    end, function(ok)
        if T.off then return end
        local n = (S.idFrames or 0) - T.f0
        Q.check(ok and n <= 32, T.L .. ": the weight, the hair and a new trait show within 30 frames drawn", n .. " frames; weight " .. tostring(H.idData().weightStr) .. ", hair " .. tostring(H.idData().hairStyle))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== I26, I27: paused and the game's screen
function C.i26()
    local T = { L = "I26 paused (Info)" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    Q.waitMs(600)
    H.step(2, function() if not T.off then H.pause(true) end end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local PL = ZeD.PausedLook
        local g = PL and PL._glass
        local dp = H.dp()
        local st = C.hb()
        local pts, over = {}, true
        if st and st.btn then pts[#pts + 1] = st.btn end
        for _, z in ipairs((st and st.zones) or {}) do if z.item and z.item.kind == "parts" then pts[#pts + 1] = z end end
        local pz = RT.cw()._identityPhotoZone
        if pz then pts[#pts + 1] = pz end
        for _, z in ipairs(pts) do if not C.glassOver(g, dp, H.mid(z)) then over = false end end
        local ate = false
        if g then pcall(function() ate = g:onMouseDown(10, 10) == true end) end
        Q.check(g ~= nil and #pts > 0 and over and ate, T.L .. ": the glass lies over Cut, the part switch and the photo's frame and eats the press", #pts .. " places, over all " .. tostring(over) .. ", eats " .. tostring(ate))
        H.note(T.L .. ": the photo's 3D figure is its own element; whether it still takes a click under the glass is the UI's order (not read here)")
        T.part = st and st.part
        T.go = H.padOn() and H.focusEl("hb:part")
    end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        if not T.go then Q.skip(T.L .. ": the pad on the part switch", "no hb:part stop (one part only)"); H.pause(false); return end
        Q.check(C.hb().part == T.part, T.L .. ": the pad's A on the part switch does nothing while paused", tostring(T.part) .. " -> " .. tostring(C.hb().part))
        H.pause(false)
    end)
    H.caseEnd(T.L)
end
function C.i27() C.screenCase({ L = "I27 the game's screen (Info key)" }, "TOGGLE_INFO_PANEL") end

-- ===================================================================== I28 to I32
function C.i28()
    local T = { L = "I28 words" }
    H.step(2, function() H.caseStart(T); S.IT.qaStyle = "simple" end)
    H.toTab(T, "identity", T.L)
    H.idWait(T, T.L)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        local o = {}
        for _, t in ipairs(S.idT or {}) do if #o < 14 and not string.match(t.s, "^[%d%s%p]*$") then o[#o + 1] = t.s end end
        H.note(T.L .. ": the Simple card's words in " .. H.lang() .. ": " .. H.list(o, 14))
        local fem, male = getText("IGUI_char_Female"), getText("IGUI_char_Male")
        Q.check(H.idText(S.p:isFemale() and fem or male) ~= nil, T.L .. ": the sex is the game's own word, drawn", S.p:isFemale() and fem or male)
        Q.skip(T.L .. " in DE, RU and JP", "a game started in each language")
    end)
    H.caseEnd(T.L)
end
function C.i29()
    local T = { L = "I29 themes and text size" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    for _, th in ipairs(S.THEMES) do
        H.step(2, function() if not T.off then H.theme(th.key) end end)
        Q.waitMs(900)
        H.step(2, function() if not T.off then H.zonesInside(T.L .. ", " .. th.word, S.idRect, C.idZones(), H.idView()) end end)
    end
    H.step(2, function() H.themeBack() end)
    H.step(2, function() if not T.off then H.sizeSet("large") end end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        H.zonesInside(T.L .. ", Large text", S.idRect, C.idZones(), H.idView())
        H.note(T.L .. ": the license keeps its cream in every theme and its colored words follow the accent: a look for the director (the picture sk_info_<WxH> is the found theme)")
    end)
    H.caseEnd(T.L)
end
function C.i30()
    H.step(2, function()
        H.note("I30 the game's Literature button (ISCS:211-213, 319-323, 452-472) has no place on the Info tab; its skill books are the Skills tab's Training materials, its recipes the Journal's Recipes page; recorded media and seeds are on neither (a gap)")
        Q.skip("I22 Spongie's Hairstyle Unlocker and Improved Hair Menu rows", "the hair mods")
        Q.skip("I31 split screen, the second player's Info key", "a second controller")
    end)
end
function C.i32()
    local T = { L = "I32 B during a haircut" }
    H.step(2, function() H.caseStart(T); T.sc = H.give("Base.Scissors") end)
    H.toTab(T, "identity", T.L)
    H.step(2, function()
        if T.off then return end
        if not ZeD.HairBeard then T.off = true; Q.skip(T.L, "Hair and beard is not loaded"); return end
        pcall(ZeD.HairBeard.setPart, RT.cw(), "hair")
        C.hbRefresh()
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        local r = C.hbRow(function(x) return x.part == "hair" end)
        if not r then T.off = true; Q.skip(T.L, "no hair row can be done here"); return end
        H.zcall(function() ZeD.HairBeard.run(RT.cw(), r.key) end)
    end)
    H.wait(2000, function() return T.off or H.qcount("ISCutHair") > 0 end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.skip(T.L, "the cut did not queue: " .. H.qkinds()); return end
        T.go = H.padOn() and H.focusEl("identity:photo")
    end)
    H.tapB(function() return T.go and not T.off end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        Q.check(T.go and H.qcount("ISCutHair") == 0 and H.on("identity"), T.L .. ": B on an Info stop with a cut running stops it (FM:1700); the tab stays (the game's B closes its page)",
            "focus " .. tostring(H.focusedId()) .. "; " .. H.qkinds() .. "; " .. H.tabText())
        H.qstop()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== C15: the Info tab's gathers (bug 15)
function C.c15()
    local T = { L = "C15 the Info tab's gathers" }
    H.step(2, function() H.caseStart(T) end)
    H.toTab(T, "identity", T.L)
    Q.waitMs(500)
    H.step(2, function() T.g0, T.f0, T.t0 = S.idGathers or 0, S.idFrames or 0, getTimestampMs() end)
    Q.waitMs(3000)
    H.step(2, function()
        if T.off then return end
        local s = (getTimestampMs() - T.t0) / 1000
        local g = ((S.idGathers or 0) - T.g0) / s
        local f = ((S.idFrames or 0) - T.f0) / s
        Q.check(g <= 4.5, T.L .. ": the Info tab gathers no more often than the Skills tab's clock (4 a second) [bug 15]",
            string.format("%.1f gathers a second at %.0f frames a second", g, f))
    end)
    H.caseEnd(T.L)
end
function C.notes()
    H.step(2, function()
        H.note("bug 16 (stale comments, not run): ST:4-5 and ST:98-104 (the bar is the way to the next level), ST:8-9 (a click pins), ST:511-513 (RecipeIndex always adds an extra), IT:10-11 (identityStyle retired), CW:1679-1681, CW:3162-3186 and CW:6021-6033 (the Identity heading's disclosure is gone)")
        H.note("FEATURE_MAP drift (the map's list): rows 64, 96, 215-219, 226, 227, 230, 501-504, 1035, 1245, 1286 carry old line numbers; row 226's identity:__disclosure stop is dead (IT:1601)")
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
    H.hoverOff()
    H.lockBack()
    H.closeMenu()
    H.themeBack()
    H.sizeBack()
    H.halfBack()
    pcall(function() if ZeD.Studio and ZeD.Studio.isOpen() then ZeD.Studio.close() end end)
    for _, c in ipairs(S.objs) do H.rmObj(c) end
    for _, it in ipairs(S.made) do H.removeItem(it) end
    S.xpGrew, S.xpLeft = H.xpBack()
    S.readFixed = H.readBack()
    H.lookBack()
    H.traitsBack()
    H.pinsBack()
    H.statsBack()
    H.sbBack()
    H.screenBack()
    H.wrapOff()
    S.IT.qaStyle, S.IT.qaLayout, S.IT.qaTrend, S.IT.qaProf = f.qa and f.qa.style, f.qa and f.qa.layout, f.qa and f.qa.trend, f.qa and f.qa.prof
    pcall(function() S.p:setTimedActionInstantCheat(f.inst and true or false) end)
    pcall(function() if f.tod then getGameTime():setTimeOfDay(f.tod) end end)
    local w = RT.cw()
    if w and f.recorded then
        if f.grid ~= nil then w._skillsGridExpanded = f.grid end
        local ex = {}
        for k, v in pairs(f.trExp or {}) do ex[k] = v end
        w._trainingExpanded = ex
        pcall(function() if f.find and f.find ~= "" then S.TF.setText(w, "skills", f.find) else S.TF.clear(w, "skills") end end)
        w._identityPhotoExpanded = f.photo and true or false
        w._identityCustomZoom = 0
        if f.hbPart and ZeD.HairBeard then pcall(ZeD.HairBeard.setPart, w, f.hbPart) end
        pcall(function() w._skillsScroll:setScrollPos(0) end)
        pcall(function() w._identityScroll:setScrollPos(0) end)
        H.skFresh()
        H.idFresh()
    end
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        H.putBack()
        RT.pairOpen()
    end)
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
        pcall(function()
            local a, b = f.hands.p, f.hands.s
            S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
            S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
        end)
        H.home()
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "sk_tab") end
        local w = RT.cw()
        if w then w._maxWinW = f.maxW end
        H.lootRefresh()
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then return end
        pcall(ZeD_CharacterWindow.openTab, S.pn, f.ctab or "loot")
        if f.ctab == "loot" or f.ctab == nil then RT.charTab("loot") end
        RT.worldTab(f.wtab or "loot")
    end)
    Q.step(20, function() C.checkBack() end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
        if f.recorded then
            pcall(function() if f.invinc ~= nil then S.p:setInvincible(f.invinc) end end)
            pcall(function() if f.god ~= nil then S.p:setGodMod(f.god) end end)
        end
    end)
end
function C.checkBack()
    local f = S.found
    if not f.recorded then Q.skip("put back", "nothing was staged"); return end
    local left = {}
    for _, it in ipairs(S.made) do if not H.gone(it) then left[#left + 1] = H.ft(it) end end
    Q.check(#left == 0, "put back: every thing the run gave is gone (books, bags, tools, make-up, the apple, the crate's book)", #S.made .. " given; left " .. H.list(left, 8))
    local extra = {}
    for _, it in ipairs(H.all()) do if not f.inv0[it] then extra[#extra + 1] = H.ft(it) end end
    Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (his set-aside things back)",
        "new " .. H.list(extra, 8) .. "; " .. tostring(S.swept) .. " swept, " .. tostring(S.refilled) .. " of his own used things given again, " .. tostring(S.lost) .. " set-aside things not given back")
    local objs = {}
    for _, c in ipairs(S.objs) do if H.objLeft(c) then objs[#objs + 1] = c.what end end
    Q.check(#objs == 0, "put back: the crate laid beside him is gone", H.list(objs))
    local lv = H.levelsAsFound()
    if S.xpLeftText then H.note("put back: XP drift left (levels checked): " .. S.xpLeftText) end
    Q.check(lv == 0, "put back: his real skill levels as found", tostring(S.xpGrew) .. " skills changed, " .. lv .. " not at their level")
    Q.check(H.boostsAsFound() == 0, "put back: the perk boosts as found", H.boostsAsFound() .. " differ")
    local mHad = false
    pcall(function() mHad = S.p:getXp():getMultiplierMap():containsKey(Perks.Woodwork) and true or false end)
    Q.check(mHad == (f.multHad == true), "put back: the Carpentry book multiplier as found", "there " .. tostring(mHad) .. " (found " .. tostring(f.multHad) .. ")")
    local rok, rbad = H.readAsFound()
    Q.check(rok, "put back: the skill books read as found (each book's pages, the read-books list)", rbad .. "; " .. tostring(S.readFixed) .. " set back")
    local tok, tbad = H.traitsAsFound()
    Q.check(tok, "put back: his traits as found", tbad)
    local lok, lbad = H.lookAsFound()
    Q.check(lok, "put back: his name, look, weight, kills and favorite-weapon counts as found", lbad)
    local prof = "?"
    pcall(function() prof = tostring(S.p:getDescriptor():getCharacterProfession()) end)
    Q.check(S.IT.qaProf == (f.qa and f.qa.prof) and S.IT.qaStyle == (f.qa and f.qa.style) and S.IT.qaLayout == (f.qa and f.qa.layout),
        "put back: his profession never changed (" .. prof .. "), the Info tab's QA hooks as found")
    local md = S.p:getModData()
    local same = #(md.ZeD_Pins or {}) == #(f.pins or {})
    for i, e in ipairs(f.pins or {}) do local m = (md.ZeD_Pins or {})[i]; if not (m and m.k == e.k and tostring(m.id) == tostring(e.id)) then same = false end end
    Q.check(same, "put back: the pins as found", H.list(H.pinIds()))
    local sbBad = {}
    for name, r in pairs(S.sbAll or {}) do if H.optVal(H.sbOpt(name)) ~= r.v then sbBad[#sbBad + 1] = name .. " " .. tostring(H.optVal(H.sbOpt(name))) .. " (found " .. tostring(r.v) .. ")" end end
    Q.check(#sbBad == 0 and H.optVal(H.screenOpt()) == f.screen, "put back: the sandbox options and the Character info screen switch as found", H.list(sbBad) .. "; switch " .. tostring(H.optVal(H.screenOpt())))
    local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
    Q.check(dx < 0.6 and dy < 0.6 and H.qlen() == 0 and getGameSpeed() == 1, "put back: he stands where he stood, no action queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
    local w = RT.cw()
    Q.check(ZeD.currentBase == f.base and ZeD.currentSize == f.size and H.lockFound() == (S.lockWas or H.lockFound()) and S.parked == nil and S.hov == nil
        and S.back.maxW == nil and S.w0 == nil and (w == nil or w._maxWinW == f.maxW),
        "put back: the theme, the text size, the input lock, the width cap, the pointer and the draw watchers as found",
        tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", lock " .. H.lockFound() .. ", width cap " .. tostring(w and w._maxWinW))
    Q.check(w == nil or ((w._skillsGridExpanded == f.grid or f.grid == nil) and S.TF.text(w, "skills") == (f.find or "")),
        "put back: the Skills tab's grid fold and Find text as found", "grid " .. tostring(w and w._skillsGridExpanded) .. ", find \"" .. tostring(w and S.TF.text(w, "skills")) .. "\"")
    Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught" .. (S.zerr and (": " .. S.zerr) or ""))
    if S.tabErrs then Q.check(false, "the tabs drew without a throw", S.tabErrs .. " throws: " .. tostring(S.tabErrLast)) end
    local e1 = H.errN()
    if S.err0 and e1 then Q.check(e1 == S.err0, "the Skills and Info run ran with no Lua error", (e1 - S.err0) .. " new")
    else Q.skip("the run's Lua error count", "the game's Lua error count cannot be read here") end
end

-- ===================================================================== the run
S.setup()
C.s1()
C.s2()
C.s3()
C.s4()
C.s5()
C.s6()
C.s7()
C.s8()
C.s9()
C.s10()
C.s11()
C.s12()
C.s13()
C.s14()
C.s15()
C.s16()
C.s17()
C.s18()
C.s19()
C.s20()
C.s21()
C.s22()
C.s23()
C.s24()
C.s25()
C.s26()
C.s27()
C.s28()
C.s29()
C.s30()
C.s32()
C.s33()
C.i1()
C.i2()
C.i3()
C.i4()
C.i5()
C.i6()
C.i7()
C.i8()
C.i9()
C.i10()
C.i11()
C.i12()
C.i13()
C.i14()
C.i15()
C.i16()
C.i17()
C.i18()
C.i19()
C.i20()
C.i21()
C.i23()
C.i24()
C.i25()
C.i26()
C.i28()
C.i29()
C.i30()
C.i32()
C.c15()
C.s31()
C.i27()
C.notes()
S.buildPutBack()
Q.start()
