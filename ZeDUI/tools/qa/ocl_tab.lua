-- ZeDUI/tools/qa/ocl_tab.lua  (Nov 26 2026, QA; tag ocl_tab): the World window's object cards and their host, the
-- gamut sweep, in the style of the Mechanics, Cooking and Crafting sweeps (mt_tab.lua, ck_tab.lua, cr_tab.lua). Its
-- spec is the map ZeDUI/qa/audits/2026-11-26_map_cards_lock_medic_rest.md (section 5's suspicions OC1-OC8, LK1-LK9,
-- MD1-MD5, LA1-LA6, PL1-PL5, TK1-TK3, TD1-TD4, PV1-PV4; section 3's states; section 4's gaps). Run after
-- zedqa_prelude.lua and rt_kit.lua (ocl.txt). grep "ZEDQA ocl_tab".
-- Each suspicion single player can stage is proved or cleared with values: PASS when ZeD does what the game does,
-- FAIL with the evidence when it does not, NOTE for a reading with no rule to judge it by. The game's answers are
-- asked of the game itself: its actions' results (the padlock on or off and its code, padlocks and bandages spent, the
-- washer's state, the washer-dryer's mode, the item's place), its own getters (getLockedByCode, isLockedByPadlock,
-- isActivated, isPowered, the body part's health and wounds, the clothes' dirt, blood and wetness, getOffX,
-- isDoingExtendedPlacement, DistToProper, the build script's health and the sandbox's bonus), its own UI rules
-- (ISHealthPanel's words for a doctor at a First Aid level without cheat mode, drawn by the game's own
-- ISHealthBodyPartListBox.doDrawItem; ISExtendedPlacementUI's distance rule; ISAnimalTracksUI's plain freshness) and
-- its own queue (ISTimedActionQueue); never ZeD's code under test. What the card drew is read from the draw itself:
-- every word ZeD_ObjectCard drew in its last frame (its own drawText), its tags and their marks (Molecules.drawTag),
-- its question (drawQuestionBand), its NEEDS lines (drawNeedsLine) and its band's state line (drawBand); only the
-- object card is recorded, so no other window can stand for it.
-- How it drives the card: the mouse is the card's own pointer poll (ZeD_ObjectCard:_pointer reads getMouseX,
-- getMouseY and isMouseButtonDown every frame drawn): the pointer is put on the zone's middle, pressed one frame and
-- let go the next, so the press and the release are judged by the card exactly as a hand's; the wheel is the card's
-- onMouseWheel with the pointer on the zone; a number key is the World window's own onKeyPress with the pointer on
-- the card. The pad goes through FocusManager's QA hook (Focus.qaButton) and its own dispatch on the World window
-- (dispatchJoypadDown, dispatchJoypadDir), focus put by focusWhere in the worldItemCard zone, the input mode locked to
-- the controller and put back as found (ck_tab's and mt_tab's way).
-- Staging (home: ZEDQA_HOME, the Irvington drag strip, 925.5,13040.5; everything within a few tiles of him):
--   the lock card: built crates as the game's carpentry makes them (IsoThumpable, carpentry_01_16, taking a padlock),
--     free, on code 319 or on a key padlock; Combination Padlocks and key padlocks given; a school bag; a key ring
--   the laundry card: a washer and a washer-dryer (the game's laundry tiles by class), a generator 3 tiles off for
--     power, 20 L of water put in by the fluid container; a shirt made dirty, bloody and wet
--   the placement card: a hammer laid on the ground, opened by the game's Extended Placement (its walk and action)
--   the track card: the drag strip has no tracks and the game makes them only from a virtual herd, so the track is a
--     stand-in for the game's track data (type, direction, species, freshness in the game's own words); where it lies
--     its world item is a real hammer on the ground; opened by the game's Inspect Track action
--   the medic card: single player has no other player, so the patient is a stand-in that answers every call with the
--     character's own (gc_cleanup.lua's proxy): his own body is the patient's. The card opens by ZeD's MC.open (the
--     game's ISMedicalCheckAction cannot run on a stand-in: it faces it); a treatment the game's menu queues is handed
--     to the game's own action with him as the patient (ISTimedActionQueue.add / addAfter watched while it runs), so
--     the game's bandage runs on his body and takes his bandage
--   the preview card: the World window's Build and Craft tabs, a recipe picked by the tab's own open, the card opened
--     by the pad's A on the header's icon stop; a car from the prelude's one spawn for the seat (OC8)
-- Cases (the map's names; mouse and pad where the verb has a press):
--   1 LK1 OC1 the Lock question does not freeze the card: a code typed (3 1 9), Lock, then during the question the
--          mouse wheel over wheel 3, a click on wheel 2's up chevron and the key 7; Yes; the code the game locked it
--          with (getLockedByCode) against the code the band showed; padlocks spent; the pad's path: A on Cancel locks
--          nothing, the question's stops are the band's only, Right then A locks it with the dial shown; OC3: B
--          with the question up cancels it, B from a wheel closes the card (nothing locked). Picture ocl_lock_<WxH>
--   2 LK4 the NEEDS words against the main-inventory rule: a Combination Padlock only in a school bag (Lock grey, its
--          NEEDS line, the game's FindAndReturn and its recursive find); two key padlocks, the first without keys
--          (Use padlock against the game's key counts; pressed: the game's padlock on); the key on a key ring
--          (Remove padlock against the game's haveThisKeyId and the game's own Remove Padlock action)
--   3 LK5 a wrong try is a timed action: a wrong code by the mouse and twice by the pad (the game's queue, the time,
--          the code kept, the wrong-code line), the right code after three wrong (the padlock off, a padlock given
--          back); the game's own OK on a wrong code (onCheckDigitalCode) as the baseline: nothing queued
--   4 LK6 the hook keeps the queue: a walk elsewhere running, then the game's Use Combination Padlock from 5 tiles
--          (the hooked onPutDigitalPadlock): the walk still first in the game's queue (the game clears it)
--   5 LK7 the pad's path from the card's open to a locked crate: the opening stop, A grabs, the D-pad turns, A lets
--          go, down to Lock (the verbs' band at the foot), the question on Cancel, Right, A; the presses counted; the
--          grab's prompt; the code locked
--   6 LK8 the half card at the run's size with the busy band and the set note: wheel 3's chevrons and Stop inside the
--          body's width (beside the scroll bar when it shows). Picture ocl_lock_busy_<WxH>
--   7 OC7 three Loot columns open (the World window's own toggleColumn), then the lock card by the game's Remove
--          Combination Padlock: the columns after it opens and after it closes
--   8 PL1 OC2 the placement card closed by the World window's close box and by U (its toggle): the game's
--          isDoingExtendedPlacement, the place kept, the gizmo; then the game's pick up; OC2 the roll-up: the card
--          kept 6 tiles off while rolled (the game's distance), and what the unroll does; OC3 B from Rotation Z
--          (the game's place kept and its placement ended). Picture ocl_placement_<WxH>
--   9 PL2 no typed values: the X slider dragged to 0.25 by the mouse (the game's getOffX after), the pad's steps
--  10 PL3 the leash: the game's window closes past 3 by DistToProper; the card at a spot the game's rule closes; the
--          hold with a walk away running
--  11 PL5 the pad's added option: an item two squares off behind a wall laid between, ZeD's world menu option
--          (onFillWorld) against the game's own line-of-sight rule (LosUtil.lineClear)
--  12 LA1 OC6 Power pressed twice from 4 tiles by the mouse (a double click) and by the pad (A A): the game's toggles
--          queued and isActivated at the end; the face's reading in the 250 ms after a press. Picture
--          ocl_laundry_<WxH>
--  13 LA3 LA2 the power cut and the water drained while it runs (the game's isActivated, isPowered and the card's
--          tag); a dirty, bloody, wet shirt washed at speed: the game's dirt, blood, wetness and isActivated each
--          second against what the card draws
--  14 LA4 Door from 3 tiles (and from 1): the machine's container in the Loot pane, and any word when not
--  15 LA5 the washer-dryer in washer mode with no water: DRY by the mouse, WASH by the pad: the game's
--          ISSetComboWasherDryerMode accepted (isModeDryer, isModeWasher); OC3: B from the Door
--  16 OC5 the leash hold on a walk the card never started: the laundry card open, the game's walk 10 tiles off:
--          the card past its leash, then Power pressed far off (what the game queued)
--  17 MD2 a scratch, a deep wound and a fracture on stand-in patient (his own body) at First Aid 0, 3, 5, 7 and 9:
--          the numbers the card draws and the severity words, against the game's own list rows (doDrawItem) for a
--          doctor at that level. Picture ocl_medic_<WxH>
--  18 MD1 a bandage on a scratch, the part clicked again while the game's bandage runs: the game's job record (its
--          health view's bodyPartAction), what the card drew, and the bandages the game spent
--  19 MD4 MD5 OC3 the pad's A on a row (the game's menu, inside the screen?), B with the menu up; paused (the game's
--          rule: no menu at speed 0 outside debug); B from a row closes the card
--  20 TK1 TK2 the tag's mark for the game's oldest freshness word and its freshest (the game's own window draws it
--          plain); the longest species and freshness words at the run's text size against the card's edge. Picture
--          ocl_track_<WxH>
--  21 TK3 a track lying on the ground (a real world item) inspected by the game's action, picked up, carried 7 tiles
--          off: the card's leash against where the item is (the game's container); the item gone; OC3 B
--  22 PV2 a build recipe with bonus health at Construction Bonus Points 1 and 2: the card's strength against the
--          game's own build health (ISBuildIsoEntity's formula with its fraction, read from the script and the
--          sandbox). Picture ocl_preview_<WxH>
--  23 PV3 OC3 a skill-based build (the log fence) open while Carpentry goes up two levels: the card's strength against
--          the game's at the new level; B from Facing closes it
--  24 PV1 the Craft tab with and without the craft preview open: frames drawn in 3 s (NOTE)
--  25 PV4 a craftable recipe's preview, every loose thing he carries set aside, Craft pressed at once: what the game's
--          craft did (queued, refused, made)
--  26 OC4 the held-in window (the cap at 640 units, as at 1280 wide) with each full card (laundry, medic, placement,
--          track) and the half card (lock): the window against its cap, the inventory beside the card. Pictures
--          ocl_<card>_held_<WxH>
--  27 OC8 (run last) seated in a parked car: the Craft tab and the recipe preview (the card in a vehicle)
--   SKIP: LK2 and LK3 (a server and a second player at one crate), LA6 (two players at one machine), PL4 (the item
--   taken on a server), TD1-TD4 (a trade needs a second player; no trade picture either), MD3 (split screen), LK9 (a
--   scope note: no ZeD surface to sweep)
--   every case: no Lua error over it; put back exactly
-- Puts back: every object laid (crates, the wall, washer, washer-dryer, generator), every thing given or made, his own
-- padlocks, bandages and loose things set aside, the crates' padlocks and mod data, his body's staged wounds and
-- bandages (each part as found), god mode and invincible (off only while his body is the patient), his skill levels
-- (First Aid, Carpentry, Tracking; XP drift a NOTE), the sandbox's Construction Bonus Points, the laundry clock's
-- record of the run's machines, the hidden-actions setting, the windows (both open as found), the World window's tab,
-- columns, width cap and drawer, the Character window's tab, the layout, the pad lock, the pointer and the mouse
-- functions, the draw watchers, the queue watch, the theme and the text size (not changed: checked), game speed 1,
-- the clock, where he stood, and the car (the prelude's removal, a tick after he is out).

if not (RT and RT.make) then
    print("ZEDQA ocl_tab ERR rt_kit.lua did not run first")
    print("ZEDQA ocl_tab VERDICT FAIL 1")
    print("ZEDQA ocl_tab DONE")
    return
end
local Q = RT.make("ocl_tab")
Q.maxMs = 2200000                    -- (the runner gives this script 2400 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, objs = {}, shots = {}, errs = 0,
            dead = false, xp = {}, halo = {}, keep = {}, said = {}, ptr = { x = 0, y = 0, down = false }, parts = {},
            ldKeys = {}, cars = {} }
local H = {}
local C = {}
S.F = RT.focus()
S.OC = ZeD and ZeD.ObjectCards
S.CRATE = "carpentry_01_16"
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.STASH = { "Base.CombinationPadlock", "Base.Padlock", "Base.Bandage", "Base.AlcoholBandage", "Base.Bandaid",
            "Base.RippedSheets", "Base.RippedSheetsDirty", "Base.BandageDirty", "Base.Hammer", "Base.KeyRing" }
S.PARTS = { "ForeArm_L", "Hand_R", "LowerLeg_L", "UpperArm_R", "ForeArm_R", "Hand_L", "LowerLeg_R", "UpperArm_L" }
S.LEVELS = { 0, 3, 5, 7, 9 }

if not (S.p and S.OC and ZeD_WorldWindow and ZeD_ObjectCard and ZeD.Molecules) then
    Q.check(false, "the player, ZeD's object cards and the World window are loaded")
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
-- ones) count as not ours. Returns the count not ours, the count ours, and the first own frame line. (ocp_tab's split)
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
    if own > 0 then H.note(label .. ": TEST FAULT: " .. own .. " Lua error entries thrown in ocl_tab's own code (not ZeD's, not counted below): " .. tostring(first)) end
    Q.check(other == 0, label, other .. " new" .. ((own > 0) and (" (" .. own .. " more in ocl_tab's own code)") or ""))
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
function H.hasI(s, sub) return type(s) == "string" and type(sub) == "string" and sub ~= "" and string.find(string.lower(s), string.lower(sub), 1, true) ~= nil end
function H.lang() local l = "?"; pcall(function() l = tostring(Translator.getLanguage():name()) end); return l end
function H.debug() local d = false; pcall(function() d = isDebugEnabled() and true or false end); return d end
function H.px(u) local v = u; pcall(function() v = ZeD.T.px(u) end); return v end
function H.dist(x, y) local d = 999; pcall(function() local dx, dy = x - S.p:getX(), y - S.p:getY(); d = math.sqrt(dx * dx + dy * dy) end); return d end
function H.sqDist(sq) if not sq then return 999 end; return H.dist(sq:getX() + 0.5, sq:getY() + 0.5) end

-- ===================================================================== the timed-action queue (the game's)
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.head() local a = H.queue()[1]; return a and tostring(a.Type) or "none" end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 14) end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
-- the actions the game was handed while a watch is on (ISTimedActionQueue.add and addAfter), by their Type
function H.qWatchOn()
    if S.qw0 then return end
    local W = { add = ISTimedActionQueue.add, after = ISTimedActionQueue.addAfter }
    S.qw0 = W
    S.qLog = {}
    W.addFn = function(action, ...)
        pcall(function() S.qLog[#S.qLog + 1] = tostring(action and action.Type) end)
        pcall(H.handOver, action)
        return W.add(action, ...)
    end
    W.afterFn = function(prev, action, ...)
        pcall(function() S.qLog[#S.qLog + 1] = tostring(action and action.Type) end)
        pcall(H.handOver, action)
        return W.after(prev, action, ...)
    end
    ISTimedActionQueue.add = W.addFn
    if W.after then ISTimedActionQueue.addAfter = W.afterFn end
end
function H.qWatchOff()
    local W = S.qw0
    if not W then return end
    if ISTimedActionQueue.add == W.addFn then ISTimedActionQueue.add = W.add end
    if W.after and ISTimedActionQueue.addAfter == W.afterFn then ISTimedActionQueue.addAfter = W.after end
    S.qw0 = nil
end
function H.qLogged(ty) local n = 0; for _, t in ipairs(S.qLog or {}) do if t == ty then n = n + 1 end end; return n end
-- a treatment the game's menu made for the stand-in patient goes to the game's own action with him as the patient
-- (the stand-in is a Lua table: the action's facing and its Java calls want the character himself)
function H.handOver(action)
    if not (action and S.patient) then return end
    if rawget(action, "otherPlayer") == S.patient then
        action.otherPlayer = S.p
        pcall(function() action.bandagedPlayerX = S.p:getX(); action.bandagedPlayerY = S.p:getY() end)
        S.handed = (S.handed or 0) + 1
    end
end
-- queue: wait for the game's queue to empty (speed 2: the walks still run there), at most ms
function H.waitQ(T, ms, fast)
    H.step(1, function()
        if T.off then return end
        T.qt0 = getTimestampMs()
        if fast then H.speed(2) end
    end)
    H.wait(ms, function() return T.off or (H.qlen() == 0 and getTimestampMs() - (T.qt0 or 0) > 400) end, function(ok)
        H.speed(1)
        if T.off then return end
        T.qDone = ok
        T.qMs = getTimestampMs() - (T.qt0 or 0)
        if not ok then H.note(T.L .. ": the game's queue did not empty in " .. ms .. " ms (" .. H.qkinds() .. "): cleared"); H.qstop() end
    end)
end

-- ===================================================================== things
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.ft(it) local s = "?"; if H.isItem(it) then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function H.nm(it) local s = "nothing"; if H.isItem(it) then pcall(function() s = tostring(it:getDisplayName()) end) end; return s end
function H.where(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getContainer() end) end; return c end
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
function H.count(ft) local n = 0; for _, it in ipairs(H.all()) do if H.ft(it) == ft then n = n + 1 end end; return n end
function H.mainCount(ft)
    local n = 0
    pcall(function()
        local items = H.inv():getItems()
        for i = 0, items:size() - 1 do if items:get(i):getFullType() == ft then n = n + 1 end end
    end)
    return n
end
function H.mark(it)
    if not H.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    S.caseMade[#S.caseMade + 1] = it
    return it
end
function H.give(ft) if not ft then return nil end; local it = nil; pcall(function() it = H.inv():AddItem(ft) end); return H.mark(it) end
function H.giveTo(inv, ft) local it = nil; if inv and ft then pcall(function() it = inv:AddItem(ft) end) end; return H.mark(it) end
-- a thing kept for the whole run (the car key): never swept between cases, taken away at the end
function H.keep(it)
    if not H.isItem(it) then return end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.keep[it] = true
    S.made[#S.made + 1] = it
end
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
    -- (Nov 26 2026: ItemContainer.Remove clears the item's container only when its list holds the item, and the
    -- game's shared floor container (ISInventoryPage.GetFloorContainer) is emptied by clear(), which leaves each
    -- item it listed pointing at it. A thing that left the floor some other way (taken off the square by the game or
    -- swept) keeps that stale "floor" container for good, and put back read it as left. The stale pointer is cut;
    -- a container that does list the thing has had it removed above.)
    pcall(function()
        local c = it:getContainer()
        if c and not c:contains(it) then it:setContainer(nil) end
    end)
    pcall(function()
        local wo = it:getWorldItem()
        if wo and (wo:getSquare() == nil or not wo:getSquare():getWorldObjects():contains(wo)) then it:setWorldItem(nil) end
    end)
end
-- where a thing the run made still is, for a detail line
function H.whereText(it)
    local o = {}
    pcall(function()
        local c = it:getContainer()
        if c then o[#o + 1] = "container " .. tostring(c:getType()) .. " (lists it " .. tostring(c:contains(it)) .. ")" end
    end)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            o[#o + 1] = "world item " .. (sq and (sq:getX() .. "," .. sq:getY() .. " (on the square " .. tostring(sq:getWorldObjects():contains(wo)) .. ")") or "on no square")
        end
    end)
    return (#o > 0) and table.concat(o, ", ") or "nowhere"
end
function H.gone(it)
    if H.where(it) ~= nil then return false end
    local wo = nil
    pcall(function() wo = it:getWorldItem() end)
    return wo == nil
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
function H.freeOf(it)
    local free = false
    pcall(function()
        free = it:getAttachedSlot() == -1 and not it:isEquipped() and not S.p:isEquippedClothing(it)
            and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
    end)
    return free
end
-- his own things of the types the cases use are set aside, so the game's handlers take only what a case gave;
-- set nil: every loose thing he carries (PV4), the bags he wears and holds kept
function H.stashTypes(set)
    local kept = 0
    for _, it in ipairs(H.all()) do
        if (set == nil or set[H.ft(it)]) and S.found.inv0[it] and not S.found.stashed[it] then
            local c = H.where(it)
            local isBag = false
            pcall(function() isBag = instanceof(it, "InventoryContainer") end)
            if c and H.freeOf(it) and not (set == nil and isBag) and pcall(function() c:Remove(it) end) then
                S.stash = S.stash or {}
                S.stash[#S.stash + 1] = { it = it, c = c }
                S.found.stashed[it] = true
            else
                kept = kept + 1
            end
        end
    end
    return #(S.stash or {}), kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash or {}) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        if H.where(s.it) == nil then lost = lost + 1 end
        S.found.stashed[s.it] = nil
    end
    S.stash = {}
    return lost
end
-- the things set aside after the first n given back (a case's own set-aside; the run's own stays aside)
function H.unstashFrom(n)
    local keep, lost = {}, 0
    for i, s in ipairs(S.stash or {}) do
        if i <= n then keep[#keep + 1] = s
        else
            pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
            if H.where(s.it) == nil then lost = lost + 1 end
            S.found.stashed[s.it] = nil
        end
    end
    S.stash = keep
    return lost
end
function H.weight() local w, cap = 0, 0; pcall(function() w = H.inv():getCapacityWeight(); cap = S.p:getMaxWeight() end); return w, cap end

-- ===================================================================== skills
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
function H.perkSet(name, n) pcall(function() S.p:setPerkLevelDebug(Perks.FromString(name), n) end) end
function H.perk(name) local l = 0; pcall(function() l = S.p:getPerkLevel(Perks.FromString(name)) end); return l end

-- ===================================================================== objects laid round him (ck_tab's)
function H.sqAt(dx, dy)
    local sq = nil
    pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, math.floor(S.p:getZ())) end)
    return sq
end
function H.sqHome(dx, dy)
    local sq = nil
    local f = S.found.pos
    pcall(function() sq = getCell():getGridSquare(math.floor(f.x) + dx, math.floor(f.y) + dy, math.floor(f.z)) end)
    return sq
end
function H.isFree(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
    end)
    return good
end
function H.used(sq) for _, c in ipairs(S.objs) do if c.sq == sq and not c.removed then return true end end; return false end
-- the first free square of a ring round home that no object of the run holds
function H.spot(ring)
    for _, d in ipairs(ring or S.NEAR) do
        local sq = H.sqHome(d[1], d[2])
        if sq and H.isFree(sq) and not H.used(sq) then return sq end
    end
    return nil
end
function H.ring(r)
    local o = {}
    for dy = -r, r do
        for dx = -r, r do if math.abs(dx) == r or math.abs(dy) == r then o[#o + 1] = { dx, dy } end end
    end
    return o
end
function H.keepObj(o, sq, what, kind) local c = { obj = o, sq = sq, what = what, kind = kind }; S.objs[#S.objs + 1] = c; return c end
-- a plain crate (ck_tab's: an IsoObject with the crate's container)
function H.mkCrate(r)
    local sq = H.spot(H.ring(r or 2))
    if not sq then return nil end
    local o = nil
    pcall(function() o = IsoObject.new(getCell(), sq, S.CRATE) end)
    if not o then return nil end
    pcall(function() o:createContainersFromSpriteProperties() end)
    pcall(function() sq:AddTileObject(o) end)
    local c = H.keepObj(o, sq, "a crate at " .. sq:getX() .. "," .. sq:getY(), "tile")
    pcall(function() c.inv = o:getContainer() end)
    if c.inv then pcall(function() c.inv:setExplored(true) end); return c end
    H.rmObj(c)
    return nil
end
-- a crate as the game's carpentry builds one (an IsoThumpable that takes a padlock): code > 0 locks it with that
-- code, keyId locks it on a key padlock (lv_items' mkLocked)
function H.mkLockCrate(sq, code, keyId)
    if not sq then return nil, "no free square" end
    local o, err = nil, nil
    local ok, e = pcall(function()
        local spr = S.CRATE
        local furn = nil
        pcall(function() furn = ISSimpleFurniture:new("Crate", spr, spr) end)
        o = IsoThumpable.new(getCell(), sq, spr, false, furn)
        o:setIsContainer(true)
        pcall(function() o:getContainer():setType("crate") end)
        sq:AddTileObject(o)
        o:setCanBeLockByPadlock(true)
        if code and code > 0 then o:setLockedByCode(code) end
        if keyId then o:setLockedByPadlock(true); o:setKeyId(keyId) end
    end)
    if not ok then err = tostring(e) end
    if not o then return nil, err or "IsoThumpable.new gave nothing" end
    local c = H.keepObj(o, sq, "a padlock crate at " .. sq:getX() .. "," .. sq:getY(), "thump")
    pcall(function() c.inv = o:getContainer(); c.inv:setExplored(true) end)
    if not instanceof(o, "IsoThumpable") then return nil, "not an IsoThumpable" end
    return c, err
end
function H.mkGen(sq)
    local g = nil
    pcall(function()
        g = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), sq)
        g:setFuel(60); g:setCondition(100); g:setConnected(true); g:setActivated(true)
    end)
    if not g then return nil end
    return H.keepObj(g, sq, "the generator at " .. sq:getX() .. "," .. sq:getY(), "gen")
end
function H.laundryTile(cls)
    for i = 0, 47 do
        local name = "appliances_laundry_01_" .. i
        local spr = getSprite(name)
        local props = spr and spr:getProperties()
        local isIt = false
        pcall(function() isIt = props ~= nil and props:has("IsoType") and props:get("IsoType") == cls end)
        if isIt then return name end
    end
    return nil
end
-- a laundry machine by class on sq (zedqa_laundry's placeMachine)
function H.mkMachine(cls, sq)
    local tile = H.laundryTile(cls)
    if not (tile and sq) then return nil, "no tile (" .. tostring(tile) .. ") or square" end
    local o = nil
    local ok, err = pcall(function()
        if cls == "IsoClothingWasher" then o = IsoClothingWasher.new(getCell(), sq, getSprite(tile))
        elseif cls == "IsoClothingDryer" then o = IsoClothingDryer.new(getCell(), sq, getSprite(tile))
        else o = IsoCombinationWasherDryer.new(getCell(), sq, getSprite(tile)) end
    end)
    if not (ok and o) then return nil, tostring(err) end
    pcall(function() o:createContainersFromSpriteProperties() end)
    pcall(function() o:createFluidContainersFromSpriteProperties() end)
    pcall(function() sq:AddSpecialObject(o) end)
    pcall(function() if o:getObjectIndex() < 0 then sq:AddTileObject(o) end end)
    local c = H.keepObj(o, sq, cls .. " (" .. tile .. ") at " .. sq:getX() .. "," .. sq:getY(), "machine")
    pcall(function() c.inv = o:getContainer(); c.inv:setExplored(true) end)
    S.ldKeys[#S.ldKeys + 1] = S.OC.keyOf(sq, "laundry")
    return c
end
-- water in a laundry machine on the drag strip (outdoors, no plumbing). The washer has no fluid container of its own
-- (IsoObject.addFluid pours only into getFluidContainer, which a washer tile lacks: the last run's washer read 0 L,
-- so the card's Power ran nothing and the band said "Requires a source of water"). The game's getFluidAmount then
-- reads the tile's reserve: a piped tile (waterPiped) that was never moved (modData canBeWaterPiped not true) holds
-- modData.waterAmount litres (IsoObject.getReserveWaterAmount); the plumbed-house supply needs a room. So the reserve
-- is set (and emptied the same way). S.waterHow says which way took.
function H.water(o, litres)
    pcall(function() o:setUsesExternalWaterSource(false) end)
    local n = 0
    local function amount() local a = 0; pcall(function() a = o:getFluidAmount() or 0 end); return a end
    if litres and litres > 0 then
        pcall(function() if amount() <= 0 then o:createFluidContainersFromSpriteProperties() end end)
        pcall(function() o:addFluid(FluidType.Water, litres) end)
        S.waterHow = "its fluid container"
        if amount() <= 0 then
            pcall(function() local md = o:getModData(); md.canBeWaterPiped = nil; md.waterAmount = litres end)
            S.waterHow = "the piped tile's reserve (modData.waterAmount)"
        end
    else
        pcall(function() o:emptyFluid() end)
        pcall(function() local md = o:getModData(); if md.waterAmount ~= nil or amount() > 0 then md.waterAmount = 0 end end)
        S.waterHow = "emptied"
    end
    n = amount()
    if litres and litres > 0 and n <= 0 then
        local piped, room, noWater = false, false, false
        pcall(function() piped = o:getSprite():getProperties():has(IsoFlagType.waterPiped) end)
        pcall(function() room = o:getSquare():getRoom() ~= nil end)
        pcall(function() noWater = o:getSquare():isNoWater() end)
        S.waterHow = "none took (the tile piped " .. tostring(piped) .. ", in a room " .. tostring(room) .. ", the square's isNoWater " .. tostring(noWater) .. ")"
    end
    return n
end
function H.on(o) local a = nil; pcall(function() a = o:isActivated() and true or false end); return a end
-- o's getter by name, or nil (a reading for a detail line)
function H.call0(o, fn) local v = nil; if o then pcall(function() v = o[fn](o) end) end; return v end
function H.powered(o) local pw = false; pcall(function() local c = o:getContainer(); pw = c ~= nil and c:isPowered() end); return pw and true or false end
function H.rmObj(c)
    if not (c and c.obj) or c.removed then return end
    local o = c.obj
    pcall(function() if c.kind == "gen" then o:setActivated(false); o:setConnected(false) end end)
    pcall(function() if c.kind == "machine" and o:isActivated() then o:setActivated(false) end end)
    pcall(function() if c.kind == "thump" then o:setLockedByCode(0); o:setLockedByPadlock(false) end end)
    pcall(function() local ct = o:getContainer(); if ct then ct:removeAllItems() end end)
    local sq = c.sq
    pcall(function() sq = o:getSquare() or c.sq end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        pcall(function() sq:getObjects():remove(o) end)
        pcall(function() sq:getSpecialObjects():remove(o) end)
        pcall(function() sq:RecalcProperties() end)
        pcall(function() sq:RecalcAllWithNeighbours(true) end)
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
function H.lootRefresh()
    pcall(function() local lp = getPlayerLoot(S.pn); if lp and lp.refreshBackpacks then lp:refreshBackpacks() end end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
    pcall(function() local w = RT.ww(); if w then w._containersDirty = true; w._containerTimer = 30 end end)
end
-- new world items round home (anything not there at the start), taken away
function H.snapFloor(set, cx, cy, cz)
    for y = cy - 12, cy + 12 do
        for x = cx - 12, cx + 12 do
            local sq = getCell():getGridSquare(x, y, cz)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
function H.sweepFloor()
    local now, n = {}, 0
    local f = S.found.pos
    pcall(H.snapFloor, now, math.floor(f.x), math.floor(f.y), math.floor(f.z))
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
-- a thing laid on the ground at sq (the game's AddWorldInventoryItem): the item and its world object
function H.lay(sq, ft)
    local it, wi = nil, nil
    pcall(function() it = sq:AddWorldInventoryItem(ft, 0.5, 0.5, 0) end)
    if it then pcall(function() wi = it:getWorldItem() end); H.mark(it) end
    return it, wi
end

-- ===================================================================== the pad (mt_tab's, on the World window's card)
function H.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
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
function H.cardStops()
    local w = RT.ww()
    for _, z in ipairs((w and w._focusRing) or {}) do if z.zone == "worldItemCard" then return z.elements or {} end end
    return {}
end
function H.stopIds() local o = {}; for _, e in ipairs(H.cardStops()) do o[#o + 1] = tostring(e.id) end; return H.list(o, 24) end
function H.focusedId()
    local id = nil
    pcall(function()
        local w = RT.ww()
        local el = S.F.liveElement and S.F.liveElement(w) or S.F.getFocusedElement(w)
        id = el and el.id or nil
    end)
    return id
end
function H.focusedEl() local el = nil; pcall(function() el = S.F.liveElement(RT.ww()) end); return el end
function H.focusCard(fid)
    local w = RT.ww()
    if not (w and S.F and S.F.focusWhere and fid) then return false end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "worldItemCard", function(el) return el.id == fid end) end)
    return e ~= nil
end
function H.focusTab(fid)
    local w = RT.ww()
    if not (w and S.F and S.F.focusWhere and fid) then return false end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "worldTabContent", function(el) return el.id == fid end) end)
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
        S.presses = (S.presses or 0) + 1
        RT.pad(name, true)
        if joy then RT.padDown(Joypad[joy], w) end
    end)
    H.step(4, function() if st.on then RT.pad(name, false) end end)
    H.step(4, function() if st.on then RT.pad(name, nil) end end)
end
function H.tapA(gate) H.tap("A", "AButton", gate) end
function H.tapB(gate) H.tap("B", "BButton", gate) end
-- a D-pad step through FocusManager's own dispatch (n: the count, a few frames apart)
function H.dirQ(dir, n, gate)
    for _ = 1, (n or 1) do
        H.step(4, function()
            if gate and not gate() then return end
            local w = RT.ww()
            if w then RT.padDir(dir, w) end
            S.presses = (S.presses or 0) + 1
        end)
    end
    Q.waitMs(150)
end

-- ===================================================================== the card (ZeD_ObjectCard, read from the draw)
function H.card() local c = nil; pcall(function() c = ZeD_WorldWindow.getObjectCard(S.pn) end); return c end
function H.ent() local c = H.card(); return c and c.entry or nil end
function H.kind() local e = H.ent(); return e and e.def and e.def.id or nil end
function H.ct() local e = H.ent(); return e and e.t or nil end
function H.zone(fid)
    local c = H.card()
    for _, z in ipairs((c and c._zones) or {}) do if z.fid == fid then return z end end
    return nil
end
function H.zonesLike(pre)
    local o = {}
    local c = H.card()
    for _, z in ipairs((c and c._zones) or {}) do
        if z.fid and string.sub(tostring(z.fid), 1, #pre) == pre then o[#o + 1] = z end
    end
    return o
end
function H.zoneIds(pre) local o = {}; for _, z in ipairs(H.zonesLike(pre or "")) do o[#o + 1] = tostring(z.fid) end; return H.list(o, 30) end
function H.closeCard() pcall(function() if H.card() then ZeD_WorldWindow.closeObjectCard(S.pn) end end) end
function H.cardShown() local c = H.card(); local v = false; if c then pcall(function() v = c:getIsVisible() and true or false end) end; return v end
-- the card drew a frame since t0 (its upkeep, leash included, runs only in its frames)
function H.drewSince(t0) return S.cr ~= nil and S.cr.t >= (t0 or 0) and S.crCard == H.card() end
function H.texts() return (S.cr and S.cr.texts) or {} end
function H.drew(sub) for _, t in ipairs(H.texts()) do if H.has(t.s, sub) then return t end end; return nil end
function H.drewI(sub) for _, t in ipairs(H.texts()) do if H.hasI(t.s, sub) then return t end end; return nil end
function H.textsLike(sub, max) local o = {}; for _, t in ipairs(H.texts()) do if H.hasI(t.s, sub) then o[#o + 1] = t.s end end; return H.list(o, max or 8) end
function H.allTexts(max) local o = {}; for _, t in ipairs(H.texts()) do o[#o + 1] = t.s end; return H.list(o, max or 30) end
-- the state tag: the topmost tag the card drew (the header's, or its row under a narrow header)
function H.pillTag()
    local best = nil
    for _, g in ipairs((S.cr and S.cr.tags) or {}) do if best == nil or g.y < best.y then best = g end end
    return best
end
function H.status() return S.cr and S.cr.status or nil end
-- every word the card drew last frame in one line (a half card wraps its band's line into a strip of drawn lines)
function H.joined() local o = {}; for _, t in ipairs(H.texts()) do o[#o + 1] = t.s end; return table.concat(o, " ") end
function H.says(sub) return H.has(H.status(), sub) or H.has(H.joined(), sub) end
function H.question() return S.cr and S.cr.q or nil end
function H.needs() return H.list((S.cr and S.cr.needs) or {}, 6) end
function H.needsHas(sub) for _, l in ipairs((S.cr and S.cr.needs) or {}) do if H.hasI(l, sub) then return l end end; return nil end
-- queue: wait for a card of kind to be up and drawing (and still for 400 ms: the drawer widens first)
function H.waitCard(T, kind, ms)
    H.step(1, function() T.wc = { t = getTimestampMs(), w = -1, n = 0 } end)
    H.wait(ms or 8000, function()
        if T.off then return true end
        if H.kind() ~= kind or not H.drewSince(T.wc.t) then return false end
        local c = H.card()
        local w = math.floor(c:getWidth())
        if w == T.wc.w then T.wc.n = T.wc.n + 1 else T.wc.w, T.wc.n = w, 0 end
        return T.wc.n >= 20
    end, function(ok)
        if T.off then return end
        T.cardUp = ok
        if not ok then
            Q.check(false, T.L .. ": the " .. kind .. " card opens and draws", "open " .. tostring(H.kind()) .. ", drawn " .. tostring(H.drewSince(T.wc.t))
                .. ", queue " .. H.qkinds())
            T.off = true
        end
    end)
end

-- ===================================================================== the mouse (the card's own pointer poll)
-- getMouseX / getMouseY / isMouseButtonDown answer S.ptr while it is on (the card's _pointer, hover and wheel read them)
function H.ptrOn(x, y, down)
    if not S.mouse0 then
        local m0 = { mx = getMouseX, my = getMouseY, md = isMouseButtonDown }
        S.mouse0 = m0
        getMouseX = function() return S.ptr.x end
        getMouseY = function() return S.ptr.y end
        isMouseButtonDown = function(b) if b == 0 then return S.ptr.down == true end; return m0.md(b) end
    end
    S.ptr.x, S.ptr.y, S.ptr.down = math.floor(x), math.floor(y), down and true or false
end
function H.ptrOff()
    local m0 = S.mouse0
    S.ptr.down = false
    if not m0 then return end
    getMouseX, getMouseY, isMouseButtonDown = m0.mx, m0.my, m0.md
    S.mouse0 = nil
end
function H.park(on)
    if on then H.ptrOn(-9000, -9000, false); pcall(function() Mouse.setCursorVisible(false) end); return end
    H.ptrOff()
    pcall(function() Mouse.setCursorVisible(true) end)
end
-- a zone's middle on the screen, and the zone (frac: where across it, 0..1; default the middle)
function H.zAbs(fid, frac)
    local c, z = H.card(), H.zone(fid)
    if not (c and z) then return nil end
    local fx = frac or 0.5
    return c:getAbsoluteX() + z.x + math.floor(z.w * fx), c:getAbsoluteY() + z.y + math.floor(z.h / 2), z
end
-- queue: a click on the card's zone fid (the pointer on it, down one frame, up the next); T.clicked[fid] true when
-- the zone was there to click
function H.clickQ(fid, T)
    local st = {}
    H.step(1, function()
        if T and T.off then return end
        local x, y = H.zAbs(fid)
        if not x then
            if T then T.clicked = T.clicked or {}; T.clicked[fid] = false end
            return
        end
        st.x, st.y = x, y
        H.ptrOn(x, y, false)
        if T then T.clicked = T.clicked or {}; T.clicked[fid] = true end
    end)
    H.step(2, function() if st.x then H.ptrOn(st.x, st.y, true) end end)
    H.step(2, function() if st.x then H.ptrOn(st.x, st.y, false) end end)
    H.step(2, function() if st.x then H.ptrOff() end end)
end
-- queue: two clicks one frame apart (a double click)
function H.dblQ(fid, T)
    local st = {}
    H.step(1, function()
        if T and T.off then return end
        local x, y = H.zAbs(fid)
        if not x then return end
        st.x, st.y = x, y
        H.ptrOn(x, y, false)
    end)
    H.step(1, function() if st.x then H.ptrOn(st.x, st.y, true) end end)
    H.step(1, function() if st.x then H.ptrOn(st.x, st.y, false) end end)
    H.step(1, function() if st.x then H.ptrOn(st.x, st.y, true) end end)
    H.step(1, function() if st.x then H.ptrOn(st.x, st.y, false) end end)
    H.step(2, function() if st.x then H.ptrOff() end end)
end
-- queue: the mouse wheel over a zone (del as the engine gives it)
function H.wheelQ(fid, del, T)
    local st = {}
    H.step(1, function()
        if T and T.off then return end
        local x, y = H.zAbs(fid)
        if not x then return end
        st.on = true
        H.ptrOn(x, y, false)
    end)
    H.step(2, function() if st.on then local c = H.card(); if c then H.zcall(function() c:onMouseWheel(del) end) end end end)
    H.step(2, function() if st.on then H.ptrOff() end end)
end
-- queue: a key with the pointer on the card (the World window's own key handler, which hands it to the card)
function H.keyQ(key, T, fid)
    local st = {}
    H.step(1, function()
        if T and T.off then return end
        local c = H.card()
        if not c then return end
        local x, y = nil, nil
        if fid then x, y = H.zAbs(fid) end
        if not x then x, y = c:getAbsoluteX() + math.floor(c:getWidth() / 2), c:getAbsoluteY() + math.floor(c:getHeight() / 2) end
        st.on = true
        H.ptrOn(x, y, false)
    end)
    H.step(2, function()
        if not st.on then return end
        local w = RT.ww()
        if w and w.onKeyPress then H.zcall(function() w:onKeyPress(key) end) end
    end)
    H.step(2, function() if st.on then H.ptrOff() end end)
end
-- queue: a drag on a zone from frac0 to frac1 across it (down, moved over 6 frames, up)
function H.dragQ(fid, frac0, frac1, T)
    local st = {}
    H.step(1, function()
        if T and T.off then return end
        local x, y, z = H.zAbs(fid, frac0)
        if not x then return end
        st.y, st.z = y, z
        st.c = H.card()
        H.ptrOn(x, y, false)
    end)
    H.step(2, function() if st.z then local x = H.zAbs(fid, frac0); H.ptrOn(x or S.ptr.x, st.y, true) end end)
    for i = 1, 6 do
        H.step(1, function()
            if not st.z then return end
            local f = frac0 + (frac1 - frac0) * i / 6
            local x = H.zAbs(fid, f)
            H.ptrOn(x or S.ptr.x, st.y, true)
        end)
    end
    H.step(2, function() if st.z then H.ptrOn(S.ptr.x, st.y, false) end end)
    H.step(2, function() if st.z then H.ptrOff() end end)
end

-- ===================================================================== the draw, watched (on for the run)
-- S.cr: the last frame the object card drew: texts { s, x, y, font }, tags { s, c, x, y }, needs, status, q, t, w
-- (ocp_tab's way, which reads the card in the game: ZeD_ObjectCard.prerender wrapped on the class, and in each call
-- the card's drawText swapped for one that records and draws, then put back. The first run hooked the card itself,
-- gc_cleanup's way, and the card already held a prerender or drawText of its own, so nothing was watched. A card that
-- holds its own prerender is wrapped on itself too, and put back as found.)
function H.wrapOn()
    if S.w0 then return end
    local M = ZeD.Molecules
    local W = { pre = ZeD_ObjectCard.prerender, cards = {},
                tag = M.drawTag, qb = M.drawQuestionBand, nl = M.drawNeedsLine, band = M.drawBand }
    if not W.pre then return end
    S.w0 = W
    -- one frame of the card drawn by base (the class's prerender, or the card's own), its words recorded
    W.run = function(base, self, ...)
        local rec = { texts = {}, tags = {}, needs = {}, t = getTimestampMs(), w = 0 }
        pcall(function() rec.w = self:getWidth() end)
        local own = rawget(self, "drawText")
        local dt = self.drawText
        if dt then
            self.drawText = function(pp, text, x, y, r, g, b, a, font, ...)
                if pp == self then rec.texts[#rec.texts + 1] = { s = tostring(text), x = x or 0, y = y or 0, font = font } end
                return dt(pp, text, x, y, r, g, b, a, font, ...)
            end
        end
        S.recIn, S.recCard = rec, self
        local ok, res = pcall(base, self, ...)
        S.recIn, S.recCard = nil, nil
        self.drawText = own
        if self.entry then S.cr = rec; S.crCard = self end
        if not ok then S.cardErrs = (S.cardErrs or 0) + 1; S.cardErrLast = tostring(res); error(res, 0) end
        return res
    end
    W.preFn = function(self, ...) return W.run(W.pre, self, ...) end
    W.tagFn = function(panel, x, y, text, col, opts)
        local rec = S.recIn
        if rec and S.recCard == panel then rec.tags[#rec.tags + 1] = { s = tostring(text), c = col, x = x or 0, y = y or 0 } end
        return W.tag(panel, x, y, text, col, opts)
    end
    W.qbFn = function(panel, x, y, w, question, verb, opts)
        local rec = S.recIn
        if rec and S.recCard == panel then rec.q = tostring(question); rec.qVerb = tostring(verb) end
        return W.qb(panel, x, y, w, question, verb, opts)
    end
    W.nlFn = function(panel, x, y, w, text)
        local rec = S.recIn
        if rec and S.recCard == panel then rec.needs[#rec.needs + 1] = tostring(text) end
        return W.nl(panel, x, y, w, text)
    end
    W.bandFn = function(panel, x, y, w, spec)
        local rec = S.recIn
        if rec and S.recCard == panel and type(spec) == "table" and type(spec.status) == "table" then rec.status = tostring(spec.status.text) end
        return W.band(panel, x, y, w, spec)
    end
    M.drawTag, M.drawQuestionBand, M.drawNeedsLine, M.drawBand = W.tagFn, W.qbFn, W.nlFn, W.bandFn
    ZeD_ObjectCard.prerender = W.preFn
    H.hookCard()
end
-- the World window's card: one that holds a prerender of its own (a copy of the class's or another hook) has that
-- one wrapped on the card itself, kept to put back (W.cards[card] = { own, fn }); a card with none draws through the
-- class's, wrapped above
function H.hookCard()
    local W = S.w0
    local w = RT.ww()
    local card = w and w._objectCard
    if not (W and card) or W.cards[card] then return end
    local own = rawget(card, "prerender")
    local e = { own = own }
    W.cards[card] = e
    if type(own) == "function" and own ~= W.preFn then
        e.fn = function(self, ...) return W.run(own, self, ...) end
        rawset(card, "prerender", e.fn)
        if not S.said.ownPre then
            S.said.ownPre = true
            H.note("the card holds a prerender of its own (" .. ((own == W.pre) and "a copy of the class's" or "another hook") .. "): wrapped on the card")
        end
    end
end
function H.wrapOff()
    local W = S.w0
    if not W then return end
    local M = ZeD.Molecules
    for card, e in pairs(W.cards) do
        pcall(function() if e.fn and rawget(card, "prerender") == e.fn then rawset(card, "prerender", e.own) end end)
    end
    if ZeD_ObjectCard.prerender == W.preFn then ZeD_ObjectCard.prerender = W.pre end
    if M.drawTag == W.tagFn then M.drawTag = W.tag end
    if M.drawQuestionBand == W.qbFn then M.drawQuestionBand = W.qb end
    if M.drawNeedsLine == W.nlFn then M.drawNeedsLine = W.nl end
    if M.drawBand == W.bandFn then M.drawBand = W.band end
    S.wDone = W
    S.w0 = nil
end
function H.wrapped()
    local W = S.wDone
    local M = ZeD.Molecules
    if S.w0 then return false end
    if W then
        if ZeD_ObjectCard.prerender ~= W.pre then return false end
        for card, e in pairs(W.cards) do
            local left = false
            pcall(function() left = e.fn ~= nil and rawget(card, "prerender") == e.fn end)
            if left then return false end
        end
        if M.drawTag == W.tagFn or M.drawBand == W.bandFn or M.drawNeedsLine == W.nlFn or M.drawQuestionBand == W.qbFn then return false end
    end
    return true
end
-- the windows held down for the run (an unpinned window rolls up 2 s after the pointer leaves it, and a card in a
-- rolled window stops drawing and stops its upkeep); off while a case rolls one up on purpose
function S.keeper()
    pcall(H.hookCard)
    if S.allowRoll then return end
    for _, w in ipairs({ RT.ww(), RT.cw() }) do
        pcall(function()
            w._autoShaded = false
            if w.windowShaded then w:setWindowShaded(false) end
            w._outSince = getTimestampMs() + 600000
        end)
    end
end

-- ===================================================================== settings, pictures, the held-in window
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
function H.drawerW() local w = RT.ww(); return math.floor((w and w._drawerEffW) or 0) end
-- the World window held in: its width cap at 640 units, as the window gets at 1280 wide (half the screen)
function H.heldOn()
    local w = RT.ww()
    if not w then return false end
    if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
    S.layoutTouched = true
    w._maxWinW = H.px(640)
    return true
end
function H.heldBack()
    if not S.back.maxW then return end
    local w = RT.ww()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end
function H.wwUp() local w = RT.ww(); local v = false; if w then pcall(function() v = w:getIsVisible() and true or false end) end; return v end
function H.wwOpen() if not RT.ww() then pcall(ZeD_WorldWindow.open, S.pn) end; RT.pairOpen() end

-- ===================================================================== a case's start and end
function H.legClean()
    H.speed(1)
    H.qstop()
    H.padOff()
    H.ptrOff()
    H.qWatchOff()
    S.allowRoll = nil
    H.closeCard()
    pcall(function() local c = getPlayerContextMenu(S.pn); if c and c:getIsVisible() then c:setVisible(false) end end)
    pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    -- (Nov 26 2026: put back found a Base.Hammer the run laid still not gone, with no case named. Each case's own
    -- things are checked here at its end: one still somewhere is named with its case and where it points, and its
    -- pointers are cut so the case leaves nothing.)
    for _, it in ipairs(S.caseMade) do
        if not H.gone(it) then
            local where = H.whereText(it)
            pcall(function() it:setContainer(nil) end)
            pcall(function() it:setWorldItem(nil) end)
            H.note(tostring(S.caseLabel or "a case") .. ": its " .. H.ft(it) .. " was still somewhere after the clean-up (" .. where .. "): cut loose, gone now " .. tostring(H.gone(it)))
        end
    end
    S.caseMade = {}
    H.sweepNew()
    H.sweepFloor()
    for i = (S.caseObjs or 0) + 1, #S.objs do H.rmObj(S.objs[i]) end
    S.caseObjs = #S.objs
    H.hands()
    H.wwOpen()
    H.lootRefresh()
end
function H.caseStart(T)
    S.caseMade = {}
    S.caseLabel = T.L
    S.presses = 0
    T.t0case = getTimestampMs()
    H.legClean()
    H.hidden("folded")
    H.home()
    return true
end
function H.caseEnd(label)
    H.step(2, function()
        H.legClean()
        H.hiddenBack()
        H.heldBack()
        H.home()
    end)
    H.step(10, function()
        local e1 = H.errN()
        H.errCheck(label .. ": no Lua error over the case", S.e0, e1)
        if S.zerr then Q.check(false, label .. ": nothing ZeD ran for the case threw", S.zerr); S.zerr = nil end
        S.e0 = e1
    end)
end

-- ===================================================================== readings the cases share
-- the dial as the card holds it ("319"): what the band will name, read only to say what a press did
function H.dial()
    local t = H.ct()
    if not (t and t.digits) then return "?" end
    return tostring(t.digits[1]) .. tostring(t.digits[2]) .. tostring(t.digits[3])
end
function H.code(c) local n = nil; pcall(function() n = c.obj:getLockedByCode() end); return n end
function H.keyLocked(c) local n = nil; pcall(function() n = c.obj:isLockedByPadlock() and true or false end); return n end
function H.mainPad(kind) local p = nil; pcall(function() p = H.inv():FindAndReturn(kind) end); return p end
-- the World window's container rows (rt_cards' helpers)
function H.wcontent() local w = RT.ww(); return w and w._mainContent end
function H.inList(inv)
    local w = RT.ww()
    for _, c in ipairs((w and w._containers) or {}) do if c.inventory == inv then return c end end
    return nil
end
function H.shownInv()
    local w = RT.ww()
    local e = w and w._containers and w._containers[w._activeContainer or 0]
    return e and e.inventory or nil
end
function H.ccIdx(key)
    local c = H.wcontent()
    for i, h in ipairs((c and c._cc and c._cc.hits) or {}) do if h.key == key then return i end end
    return nil
end
-- the gears button pressed on the container row through the World window's own mouse handler; true when pressed
function H.pressGears()
    local idx = H.ccIdx("obj:ZeDLaundry")
    if not idx then return false end
    local c = H.wcontent()
    local z = nil
    for _, hz in ipairs((c and c._hitZones) or {}) do if hz.id == "cc:" .. idx then z = hz end end
    if not z then return false end
    H.zcall(function()
        c:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
        c:onMouseUp(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    end)
    return true
end
function H.gizmoUp()
    local up = nil
    pcall(function()
        local G = Gizmos.getInstance()
        local a, b = G:getTranslateGizmo(S.pn), G:getRotateGizmo(S.pn)
        up = ((a ~= nil and a:isVisible()) or (b ~= nil and b:isVisible())) and true or false
    end)
    return up
end
function H.doing(it) local d = nil; pcall(function() d = it:isDoingExtendedPlacement() and true or false end); return d end
function H.offX(wi) local v = nil; pcall(function() v = wi:getOffX() end); return v end
function H.rotZ(it) local v = nil; pcall(function() v = it:getWorldZRotation() end); return v end
function H.distProper(sq) local d = 999; pcall(function() d = S.p:getCurrentSquare():DistToProper(sq) end); return d end
function H.colName(c)
    local T = ZeD.T
    if c == nil then return "no mark" end
    if c == T.positive then return "positive (green)" end
    if c == T.warning then return "warning (amber)" end
    if c == T.danger then return "danger (red)" end
    return "another mark"
end
function H.ctx() local c = nil; pcall(function() c = getPlayerContextMenu(S.pn) end); return c end
function H.ctxVis() local c = H.ctx(); local v = false; if c then pcall(function() v = c:getIsVisible() and true or false end) end; return v end
function H.ctxShut() local c = H.ctx(); if c then pcall(function() c:setVisible(false) end) end end
-- the game's menu option named label picked as its own mouse-up picks one (onSelect with its target and params); a
-- submenu: its first option. Returns the picked option's name, or nil
function H.pickOpt(label)
    local ctx = H.ctx()
    if not (ctx and H.ctxVis()) then return nil end
    local picked = nil
    local function run(o)
        pcall(function() o.onSelect(o.target, o.param1, o.param2, o.param3, o.param4, o.param5, o.param6, o.param7, o.param8, o.param9, o.param10) end)
    end
    for _, o in ipairs(ctx.options or {}) do
        if not picked and o.name == label then
            if o.subOption then
                local sub = nil
                pcall(function() sub = ctx:getSubMenu(o.subOption) end)
                for _, so in ipairs((sub and sub.options) or {}) do
                    if not picked and so.onSelect then picked = tostring(o.name) .. " > " .. tostring(so.name); run(so) end
                end
            elseif o.onSelect then
                picked = tostring(o.name)
                run(o)
            end
        end
    end
    H.ctxShut()
    return picked
end
function H.ctxNames() local o = {}; local c = H.ctx(); for _, op in ipairs((c and c.options) or {}) do o[#o + 1] = tostring(op.name) end; return H.list(o, 12) end

-- ===================================================================== the patient (the medic card)
-- a stand-in patient: every method call answered with the character's own (single player has no other player)
function S.proxyOf(pl)
    local px = { _oclQaPatient = true }
    setmetatable(px, { __index = function(t, k)
        if type(k) ~= "string" then return nil end
        local m = nil
        pcall(function() m = pl[k] end)
        if m == nil then return nil end
        local f = function(self, ...) return m(pl, ...) end
        rawset(t, k, f)
        return f
    end })
    return px
end
function H.medOpen()
    S.patient = S.patient or S.proxyOf(S.p)
    local ok = false
    H.zcall(function() ok = ZeD.Medic.open(S.p, S.patient) and true or false end)
    -- (its close then never asks the game to stop sending the stand-in's body: there is no such player)
    local t = H.ct()
    if t and t.patient == S.patient then t._ended = true end
    return ok
end
function H.bp(nm) local bp = nil; pcall(function() bp = S.p:getBodyDamage():getBodyPart(BodyPartType[nm]) end); return bp end
function H.hurt(bp)
    local h = true
    pcall(function() h = bp:HasInjury() or bp:bandaged() or bp:stitched() or bp:getSplintFactor() > 0 or bp:getFractureTime() > 0 end)
    return h
end
function H.bpHealth(bp) local v = nil; pcall(function() v = bp:getHealth() end); return v end
-- his body as the patient: god mode and invincible off while it is (god mode heals every wound the case lays), and
-- n parts that are whole picked and recorded
function H.bodyOn(T, n)
    local f = S.found
    if not S.back.body then
        S.back.body = true
        pcall(function() if f.god then S.p:setGodMod(false) end end)
        pcall(function() if f.invinc then S.p:setInvincible(false) end end)
        if f.god or f.invinc then H.note(T.L .. ": god mode " .. tostring(f.god) .. " and invincible " .. tostring(f.invinc) .. " off while his body is the patient") end
    end
    T.parts = {}
    for _, nm in ipairs(S.PARTS) do
        local bp = H.bp(nm)
        if bp and not H.hurt(bp) and #T.parts < (n or 3) then
            local rec = { nm = nm, bp = bp, health = H.bpHealth(bp), pain = 0 }
            pcall(function() rec.pain = bp:getAdditionalPain() end)
            T.parts[#T.parts + 1] = rec
            S.parts[#S.parts + 1] = rec
        end
    end
    return #T.parts >= (n or 3)
end
-- a part laid back to whole as it was found (every part used was whole at the start)
function H.bpBack(rec)
    local bp = rec.bp
    pcall(function() S.p:getBodyDamage():SetBandaged(bp:getIndex(), false, 0, false, nil) end)
    pcall(function() bp:setScratched(false, true) end)
    pcall(function() bp:setScratchTime(0) end)
    pcall(function() bp:setCut(false) end)
    pcall(function() bp:setCutTime(0) end)
    pcall(function() bp:setDeepWounded(false) end)
    pcall(function() bp:setDeepWoundTime(0) end)
    pcall(function() bp:setFractureTime(0) end)
    pcall(function() bp:setBleeding(false) end)
    pcall(function() bp:setBleedingTime(0) end)
    pcall(function() bp:setStitched(false) end)
    pcall(function() bp:setAdditionalPain(rec.pain or 0) end)
    -- (BodyPart has SetHealth only: a call to setHealth was nil, logged by the game even inside pcall)
    pcall(function() if rec.health then bp:SetHealth(rec.health) end end)
    rec.back = true
end
function H.bodyBack()
    for _, rec in ipairs(S.parts) do if not rec.back then H.bpBack(rec) end end
    local f = S.found
    if S.back.body then
        S.back.body = nil
        pcall(function() if f.god ~= nil then S.p:setGodMod(f.god) end end)
        pcall(function() if f.invinc ~= nil then S.p:setInvincible(f.invinc) end end)
    end
end
function H.scratch(bp, t) pcall(function() bp:setScratched(true, true) end); pcall(function() bp:setScratchTime(t) end) end
function H.deep(bp, t) pcall(function() bp:setDeepWounded(true) end); pcall(function() bp:setDeepWoundTime(t) end) end
function H.fracture(bp, t) pcall(function() bp:setFractureTime(t) end) end
-- the injury row's stop for a body part (the card's own list, to find the row to press)
function H.rowFid(bp)
    local t = H.ct()
    for _, en in ipairs((t and t.d and t.d.entries) or {}) do if en.bodyPart == bp then return "mc:part:" .. tostring(en.name) end end
    return nil
end
-- the game's own list row for a part, as its ISHealthPanel draws it for a doctor at First Aid lvl (cheat off): the
-- words its ISHealthBodyPartListBox.doDrawItem draws, recorded
function H.gameRows(bp, lvl)
    if not (ISHealthBodyPartListBox and ISHealthBodyPartListBox.doDrawItem) then return nil, "the game's ISHealthBodyPartListBox is not loaded" end
    local rec = {}
    local noop = function() end
    local hp = { doctorLevel = lvl, bodyPartAction = {}, otherPlayer = S.p, character = S.p, actions = {}, bodyPartPanel = { selectedBp = nil } }
    local lb = { parent = hp, width = 400, height = 400, selected = -1, mouseoverselected = -1, drawRect = noop, drawRectBorder = noop,
                 drawProgressBar = noop, drawTexture = noop, drawTextureScaled = noop,
                 drawText = function(self, s) rec[#rec + 1] = tostring(s) end,
                 getWidth = function() return 400 end, getHeight = function() return 400 end }
    local cheat = ISHealthPanel.cheat
    ISHealthPanel.cheat = false
    local ok, err = pcall(function() ISHealthBodyPartListBox.doDrawItem(lb, 0, { item = { bodyPart = bp }, itemindex = 1, height = 20 }, false) end)
    ISHealthPanel.cheat = cheat
    if not ok then return nil, tostring(err) end
    return rec
end
-- the qualifier (Severe, Moderate or none) the words give a wound word
function H.qual(list, word)
    local sev, mod = getText("IGUI_health_Severe"), getText("IGUI_health_Moderate")
    for _, s in ipairs(list or {}) do
        if H.hasI(s, word) then
            if H.hasI(s, sev) then return "severe" end
            if H.hasI(s, mod) then return "moderate" end
            return "none"
        end
    end
    return "absent"
end
function H.cardTags() local o = {}; for _, g in ipairs((S.cr and S.cr.tags) or {}) do o[#o + 1] = g.s end; return o end
function H.pctTexts() local n = 0; for _, t in ipairs(H.texts()) do if string.match(t.s, "^%d+%%$") then n = n + 1 end end; return n end
function H.gameJob(bp)
    local j = nil
    pcall(function()
        local ip = getPlayerInfoPanel(S.pn)
        local hv = ip and ip.healthView
        j = hv and hv.bodyPartAction and hv.bodyPartAction[bp] or nil
    end)
    return j
end

-- ===================================================================== the recipe preview
function H.cbp() local v = nil; pcall(function() v = getSandboxOptions():getOptionByName("ConstructionBonusPoints"):getValue() end); return v end
function H.setCbp(v)
    pcall(function()
        local so = getSandboxOptions()
        so:getOptionByName("ConstructionBonusPoints"):setValue(v)
        pcall(function() so:toLua() end)
    end)
end
function H.buildScript(rd)
    local s = nil
    if not (rd and rd.entry and rd.entry.recipe) then return nil end
    pcall(function()
        local l = BuildLogic.new(S.p, nil, nil)
        l:setRecipe(rd.entry.recipe)
        l:getAllBuildableRecipes()
        -- (a recipe with no build object answers nil: asked before its getScript, as a nil index is logged even in pcall)
        local bo = l:getSelectedBuildObject()
        if bo then s = bo:getScript() end
    end)
    return s
end
-- the game's build health (ISBuildIsoEntity: the script's health, its bonus at the sandbox's multiplier, the highest
-- relevant skill level x the skill base health), unrounded, for this character now
function H.gameHealth(rd, s)
    local g = { base = 0, bonus = 0, k = 1, lvl = 0, sb = 0 }
    if s then
        pcall(function() g.base = math.max(s:getHealth(), 0) end)
        pcall(function() g.bonus = s:getBonusHealth() end)
        pcall(function() g.sb = s:getSkillBaseHealth() end)
    end
    pcall(function() if rd and rd.entry and rd.entry.recipe then g.lvl = rd.entry.recipe:getHighestRelevantSkillLevel(S.p) end end)
    local m = H.cbp()
    if m == 1 then g.k = 0.5 elseif m == 2 then g.k = 0.7 elseif m == 4 then g.k = 1.3 elseif m == 5 then g.k = 1.5 end
    g.total = g.base + g.bonus * g.k + g.lvl * g.sb
    g.text = H.n2(g.total) .. " = " .. tostring(g.base) .. " + " .. tostring(g.bonus) .. " x " .. tostring(g.k) .. " + " .. tostring(g.lvl) .. " x " .. tostring(g.sb)
    return g
end
-- the card's strength line: the number it leads with, whether the card drew it, the line as the card holds it, and
-- as it was drawn. (Nov 26 2026: the preview card draws it in its body, in the card's own prerender, by
-- UI.pairWide: the label in F1, the value in F2 through drawTextRight after ZeD.Atoms.truncateText to the room
-- beside the label. "200 (more with your Masonry + 200 bonus)" does not fit a half card, so the card drew
-- "200 (more with your Ma..." and the last run's exact match read it as not drawn. A drawn cut of the line, its
-- lead number whole, counts as drawn.)
function H.strength()
    local t = H.ct()
    local s = t and t.d and t.d.strength
    if not s then return nil, nil end
    s = tostring(s)
    local lead = string.match(s, "^(%d+)")
    local hit = H.drew(s)
    if not hit then
        for _, d in ipairs(H.texts()) do
            local ds = tostring(d.s)
            if #ds > 3 and string.sub(ds, -3) == "..." then
                local head = string.sub(ds, 1, #ds - 3)
                if lead and string.match(head, "^(%d+)") == lead and string.sub(s, 1, #head) == head then hit = d; break end
            end
        end
    end
    local drawnLead = hit and string.match(tostring(hit.s), "^(%d+)") or lead
    return tonumber(drawnLead), hit ~= nil, s, hit and hit.s or nil
end
function H.findRd(mod, names, pred, max)
    local ok, data = pcall(mod.gatherData, S.p, RT.ww())
    local list = ok and data and data.recipes or {}
    for _, nm in ipairs(names or {}) do
        for _, rd in ipairs(list) do if rd.entry and string.lower(tostring(rd.entry.name)) == string.lower(nm) then return rd, #list end end
    end
    if pred then
        for i, rd in ipairs(list) do
            if max and i > max then break end
            local okp, yes = pcall(pred, rd)
            if okp and yes then return rd, #list end
        end
    end
    return nil, #list
end
-- queue: the recipe picked by its tab's own open (kind build or craft), then the card opened by the pad's A on the
-- header's icon stop (its own handler when the stop is not there, said once)
function H.previewQ(T, kind, noWait)
    H.step(2, function()
        if T.off then return end
        RT.worldTab(kind)
        if kind == "craft" then pcall(function() ZeD.Stations.unbind(S.p) end) end
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off or not T.rd then return end
        local w = RT.ww()
        local st = w and ((kind == "craft") and w._craftState or w._buildState)
        T.st = st
        if not st then T.off = true; Q.skip(T.L, "the " .. kind .. " tab has no recipe state"); return end
        if st.selected ~= T.rd.entry.name then H.zcall(function() ZeD.CraftingCore.openCraft(st, T.rd.entry.name) end) end
    end)
    Q.waitMs(900)
    H.step(2, function()
        if T.off then return end
        H.padOn()
        T.iconStop = H.focusTab(kind .. ":icon")
    end)
    H.tapA(function() return not T.off and T.iconStop end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        H.padOff()
        T.viaIcon = H.kind() == "preview"
        -- (the recipe the tab drew last, which CraftingCore.openPreview opens on: without it the open says no anywhere)
        T.rdReady = T.st ~= nil and T.st._rdLast ~= nil and T.st._rdLast.entry ~= nil
        if not T.viaIcon then
            if not noWait and not S.said.iconStop then S.said.iconStop = true; H.note(T.L .. ": the header's icon stop " .. kind .. ":icon was not there for the pad (found " .. tostring(T.iconStop) .. "): opened by its own handler, CraftingCore.openPreview") end
            H.zcall(function() T.openRet = ZeD.CraftingCore.openPreview(RT.ww(), T.st, S.p) end)
        end
        -- (what the open left before the card's first frame: a card that closes itself at once still opened)
        T.openedNow = H.kind() == "preview"
    end)
    if not noWait then H.waitCard(T, "preview") end
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        if not (S.F and S.F.focusWhere and S.F.liveElement and ISTimedActionQueue and ISWorldObjectContextMenu and ZeD.ObjectCardLock
                and ZeD.ObjectCardLaundry and ZeD.Medic and ZeD.HealthTab and ISHealthPanel and ZeD.CraftingCore) then
            S.dead = true
            Q.check(false, "setup: the pad's focus manager, the game's menus and ZeD's card kinds are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "ocl_tab") end
        H.speed(1)
        H.qstop()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.pair = RT.isOpen()
        f.ww = RT.ww() ~= nil
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.inv0, f.types, f.stashed, f.floor0 = {}, {}, {}, {}
        for _, it in ipairs(H.all()) do
            f.inv0[it] = true
            local ft = H.ft(it)
            f.types[ft] = (f.types[ft] or 0) + 1
        end
        pcall(H.snapFloor, f.floor0, math.floor(f.pos.x), math.floor(f.pos.y), math.floor(f.pos.z))
        pcall(function() f.tod = getGameTime():getTimeOfDay() end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
        pcall(function() f.god = S.p:isGodMod() and true or false end)
        pcall(function() f.invinc = S.p:isInvincible() and true or false end)
        f.cbp = H.cbp()
        f.base, f.size = ZeD.currentBase, ZeD.currentSize
        f.hiddenIdx = H.optVal(ZeD.Settings and ZeD.Settings.hiddenActionsOption)
        f.hcheat = ISHealthPanel.cheat
        S.lockWas = H.lockFound()
        H.xpSnap()
        f.lvl = { Doctor = H.perk("Doctor"), Woodwork = H.perk("Woodwork"), Tracking = H.perk("Tracking") }
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        H.wwOpen()
        local cw, ww = RT.cw(), RT.ww()
        f.ctab, f.wtab = cw and cw._activeTab, ww and ww._activeTab
        f.maxW = ww and ww._maxWinW
        f.invOpen = ww and ww._invDrawerOpen
        f.cols = #((ww and ww._mcSelected) or {})
        pcall(function() f.joy = JoypadState.players[S.pn + 1] end)
        f.recorded = true
        S.back.on = true
        H.wrapOn()
        Events.OnPreUIDraw.Add(S.keeper)
        local w, cap = H.weight()
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", screen " .. H.sizeTag() .. ", language " .. H.lang()
            .. ", debug " .. tostring(H.debug()) .. ", First Aid " .. f.lvl.Doctor .. ", Carpentry " .. f.lvl.Woodwork .. ", Tracking " .. f.lvl.Tracking
            .. ", hidden actions " .. H.hiddenNow() .. ", input lock " .. tostring(S.lockWas) .. ", World tab " .. tostring(f.wtab) .. ", Loot columns " .. f.cols
            .. ", god " .. tostring(f.god) .. ", invincible " .. tostring(f.invinc) .. ", Construction Bonus Points " .. tostring(f.cbp)
            .. ", carrying " .. H.n1(w) .. " of " .. H.n1(cap) .. ", the card watched " .. tostring(S.w0 ~= nil))
        if not S.w0 then Q.check(false, "setup: the object card's draw is watched (ZeD_ObjectCard.prerender found)") end
        local set = {}
        for _, ft in ipairs(S.STASH) do set[ft] = true end
        local aside, kept = H.stashTypes(set)
        H.note("setup: " .. aside .. " of his own padlocks, bandages, hammers and key rings set aside" .. (kept > 0 and (", " .. kept .. " worn or held stay") or ""))
        if f.cols > 0 then pcall(function() ZeD_WorldWindow.closeColumns(ww) end) end
    end)
    H.step(10, function()
        RT.worldTab("loot")
        Q.check(H.wwUp(), "setup: the World window is open", "open " .. tostring(RT.ww() ~= nil))
        H.legClean()
    end)
    Q.waitMs(600)
end

-- ===================================================================== 1. the Lock question (LK1, OC1, OC3)
function C.c1()
    local T = { L = "1 LK1 OC1 the Lock question" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not ISWorldObjectContextMenu._zedPadlockHooked then
            T.off = true
            Q.check(false, T.L .. ": the game's padlock menu is routed to the lock card (Overrides/Padlocks.lua)")
            return
        end
        local c, err = H.mkLockCrate(H.spot(), 0, nil)
        if not c then T.off = true; Q.skip(T.L, "no padlock crate could be built: " .. tostring(err)); return end
        T.c = c
        T.pad = H.give("Base.CombinationPadlock")
        H.give("Base.CombinationPadlock")
        T.pads0 = H.count("Base.CombinationPadlock")
        -- the game's Use Combination Padlock, as its world menu calls it
        H.zcall(function() ISWorldObjectContextMenu.onPutDigitalPadlock(nil, S.pn, c.obj, T.pad) end)
    end)
    H.waitCard(T, "lock")
    H.keyQ(Keyboard.KEY_3, T)
    H.keyQ(Keyboard.KEY_1, T)
    H.keyQ(Keyboard.KEY_9, T)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        T.band = H.status() or H.textsLike(ZeD.tr("UI_ZeD_Lock_StatusReadyLock", "3 1 9"), 3)
        Q.check(H.says("3 1 9"), T.L .. ": the number keys with the pointer on the card type the code, and the band names it (3 1 9)",
            "band: " .. tostring(T.band) .. "; dial " .. H.dial())
    end)
    H.shot("ocl_lock_" .. H.sizeTag(), "the lock card in set mode, the code 3 1 9 typed", function() return not T.off end)
    H.clickQ("oc:verb:lock", T)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        T.q = H.question()
        if not Q.check(T.q ~= nil, T.L .. ": a click on Lock asks first, in the band", "clicked " .. tostring(T.clicked and T.clicked["oc:verb:lock"]) .. "; zones " .. H.zoneIds("oc:")) then T.off = true; return end
        local qw = (T.q ~= "" and T.q) or ZeD.tr("UI_ZeD_Lock_QLock")
        H.note(T.L .. ": the question reads \"" .. tostring(qw) .. "\"; the code drawn anywhere on the card while it asks: " .. tostring(H.says("3 1 9")))
        T.d0 = H.dial()
    end)
    -- while it asks: the mouse wheel over wheel 3, a click on wheel 2's up chevron, the key 7
    H.wheelQ("lk:wheel:3", -1, T)
    H.step(2, function() if not T.off then T.d1 = H.dial() end end)
    H.clickQ("lk:up:2", T)
    H.step(2, function() if not T.off then T.d2 = H.dial() end end)
    H.keyQ(Keyboard.KEY_7, T)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        T.d3 = H.dial()
        Q.check(T.d1 == T.d0 and T.d2 == T.d0 and T.d3 == T.d0, T.L .. " (OC1): the question holds the dial (the wheel, a chevron and a key change nothing while it asks)",
            "dial " .. tostring(T.d0) .. ", after the wheel " .. tostring(T.d1) .. ", the chevron " .. tostring(T.d2) .. ", the key 7 " .. tostring(T.d3)
            .. "; still asking " .. tostring(H.question() ~= nil))
    end)
    H.clickQ("oc:confirm:yes", T)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        local code = H.code(T.c)
        local spent = T.pads0 - H.count("Base.CombinationPadlock")
        Q.check(code == 319, T.L .. " (LK1): Yes locks the crate with the code the band showed (the game's getLockedByCode)",
            "locked with " .. tostring(code) .. "; the band showed 3 1 9, the dial at Yes read " .. tostring(T.d3) .. "; the game's queue took " .. tostring(T.qMs) .. " ms")
        Q.check(spent == 1, T.L .. ": the game's action took one Combination Padlock", spent .. " spent")
        pcall(function() T.c.obj:setLockedByCode(0) end)
        H.closeCard()
        if not H.mainPad("CombinationPadlock") then H.give("Base.CombinationPadlock") end
        T.pads0 = H.count("Base.CombinationPadlock")
    end)
    -- the pad: the opening stop, A grabs wheel 1, Up turns it, A lets go, A on Lock asks on Cancel, A on Cancel, A on
    -- Lock again, Right, A on Yes
    H.step(3, function()
        if T.off then return end
        H.padOn()
        H.zcall(function() ISWorldObjectContextMenu.onPutDigitalPadlock(nil, S.pn, T.c.obj, H.mainPad("CombinationPadlock")) end)
    end)
    H.waitCard(T, "lock")
    H.step(2, function() if not T.off then H.padOn() end end)
    Q.waitMs(300)
    H.step(1, function()
        if T.off then return end
        T.land = H.focusedId()
        Q.check(T.land == "lk:wheel:1", T.L .. " (pad): the card opens with the pad on the first wheel", "on " .. tostring(T.land) .. "; stops " .. H.stopIds())
        if T.land ~= "lk:wheel:1" then H.focusCard("lk:wheel:1") end
    end)
    H.tapA(function() return not T.off end)
    H.dirQ("up", 1, function() return not T.off end)
    H.tapA(function() return not T.off end)
    H.step(2, function()
        if T.off then return end
        T.dp = H.dial()
        T.onLock = H.focusCard("oc:verb:lock")
    end)
    H.tapA(function() return not T.off and T.onLock end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        local stops = H.stopIds()
        Q.check(H.question() ~= nil and H.focusedId() == "oc:confirm:no", T.L .. " (pad): A on Lock asks, the focus on Cancel",
            "question " .. tostring(H.question()) .. ", focus " .. tostring(H.focusedId()) .. ", dial " .. tostring(T.dp))
        Q.check(not H.has(stops, "lk:wheel"), T.L .. " (pad): while it asks the band's buttons are the only stops", "stops " .. stops)
    end)
    H.tapA(function() return not T.off and H.focusedId() == "oc:confirm:no" end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        Q.check(H.question() == nil and (H.code(T.c) or 0) == 0, T.L .. " (pad): A on Cancel locks nothing (the game's getLockedByCode 0)",
            "code " .. tostring(H.code(T.c)) .. ", still asking " .. tostring(H.question() ~= nil))
        T.onLock = H.focusCard("oc:verb:lock")
    end)
    H.tapA(function() return not T.off and T.onLock end)
    Q.waitMs(400)
    H.dirQ("right", 1, function() return not T.off and H.question() ~= nil end)
    H.step(2, function() if not T.off then T.onYes = H.focusedId() end end)
    H.tapA(function() return not T.off and H.focusedId() == "oc:confirm:yes" end)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        local code = H.code(T.c)
        Q.check(code ~= nil and code > 0 and tostring(code) == tostring(tonumber(T.dp)), T.L .. " (pad): Right then A on Yes locks it with the dial shown (the game's getLockedByCode)",
            "locked with " .. tostring(code) .. ", the dial " .. tostring(T.dp) .. "; Right landed on " .. tostring(T.onYes))
        H.padOff()
        pcall(function() T.c.obj:setLockedByCode(0) end)
        H.closeCard()
        if not H.mainPad("CombinationPadlock") then H.give("Base.CombinationPadlock") end
    end)
    -- OC3: B with the question up cancels it; B from a wheel closes the card and locks nothing
    H.step(3, function()
        if T.off then return end
        H.zcall(function() ISWorldObjectContextMenu.onPutDigitalPadlock(nil, S.pn, T.c.obj, H.mainPad("CombinationPadlock")) end)
    end)
    H.waitCard(T, "lock")
    H.keyQ(Keyboard.KEY_5, T)
    H.clickQ("oc:verb:lock", T)
    Q.waitMs(400)
    H.step(2, function() if not T.off then T.asked = H.question() ~= nil; H.padOn(); H.focusCard("oc:confirm:no") end end)
    H.tapB(function() return not T.off end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        Q.check(T.asked and H.question() == nil and H.kind() == "lock", T.L .. " (OC3): B with the question up cancels the question and keeps the card",
            "asked " .. tostring(T.asked) .. ", asking after B " .. tostring(H.question() ~= nil) .. ", card " .. tostring(H.kind()))
        T.onWheel = H.focusCard("lk:wheel:2")
    end)
    H.tapB(function() return not T.off and T.onWheel end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        Q.check(H.kind() == nil and (H.code(T.c) or 0) == 0, T.L .. " (OC3): B from a wheel closes the card with no question and locks nothing (the game's code 0)",
            "card " .. tostring(H.kind()) .. ", code " .. tostring(H.code(T.c)) .. "; the prompt reads \"" .. tostring(ZeD.tr("UI_ZeD_ObjCard_CloseCard")) .. "\"")
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 2. the NEEDS words (LK4)
function C.c2()
    local T = { L = "2 LK4 the NEEDS words" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local c, err = H.mkLockCrate(H.spot(), 0, nil)
        if not c then T.off = true; Q.skip(T.L, "no padlock crate could be built: " .. tostring(err)); return end
        T.c = c
        T.bag = H.give("Base.Bag_Schoolbag")
        local binv = nil
        pcall(function() binv = T.bag:getInventory() end)
        T.inBag = binv and H.giveTo(binv, "Base.CombinationPadlock")
        if not T.inBag then T.off = true; Q.skip(T.L, "no school bag to hold the padlock"); return end
        H.hidden("all")
        H.zcall(function() ISWorldObjectContextMenu.onPutDigitalPadlock(nil, S.pn, c.obj, T.inBag) end)
    end)
    H.waitCard(T, "lock")
    H.keyQ(Keyboard.KEY_4, T)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local main = H.mainPad("CombinationPadlock")
        local deep = nil
        pcall(function() deep = H.inv():getFirstTypeRecurse("CombinationPadlock") end)
        local line = H.needsHas(ZeD.tr("UI_ZeD_Lock_NeedsCombo"))
        -- (fix/cards3, Nov 26 2026: the line now says "in your main inventory", which is right: the game's action takes from
        -- there only. The fault was saying "in your bags" while one was in a bag)
        local mainWords = string.find(string.lower(H.needs()), "main inventory", 1, true) ~= nil
        Q.check(not (line and deep ~= nil and main == nil) or mainWords, T.L .. ": a Combination Padlock only in his school bag: the NEEDS line says where the game's action takes it from (his main inventory), not that he lacks one in his bags",
            "the game's FindAndReturn on the main inventory (the one its action removes from) " .. tostring(main ~= nil) .. ", its recursive find " .. tostring(deep ~= nil)
            .. " (in " .. H.nm(T.bag) .. "); the card's NEEDS lines: " .. H.needs())
        H.closeCard()
        H.removeItem(T.inBag)
        H.removeItem(T.bag)
        -- two key padlocks, the first without keys
        T.p1 = H.give("Base.Padlock")
        T.p2 = H.give("Base.Padlock")
        pcall(function() T.p1:setNumberOfKey(0) end)
        pcall(function() T.p2:setNumberOfKey(2); T.p2:setKeyId(515151) end)
        H.zcall(function() ZeD.ObjectCardLock.openFor(S.p, T.c.obj, false) end)
    end)
    H.waitCard(T, "lock")
    H.step(2, function()
        if T.off then return end
        local keyed, first = 0, nil
        pcall(function()
            local items = H.inv():getItemsFromType("Padlock")
            for i = 0, items:size() - 1 do if items:get(i):getNumberOfKey() > 0 then keyed = keyed + 1 end end
        end)
        pcall(function() first = H.inv():FindAndReturn("Padlock"):getNumberOfKey() end)
        local line = H.needsHas(ZeD.tr("UI_ZeD_Lock_NeedsKeyPad"))
        T.keyed = keyed
        Q.check(not (line and keyed > 0), T.L .. ": two key padlocks, the first without keys: Use padlock is offered (one with keys is in his main inventory)",
            "the game's key counts: " .. keyed .. " with keys, the first found has " .. tostring(first) .. "; the card's NEEDS lines: " .. H.needs())
        S.qLog = {}
        H.qWatchOn()
    end)
    H.clickQ("oc:verb:usepad", T)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        H.qWatchOff()
        H.note(T.L .. ": Use padlock pressed: the game queued " .. H.list(S.qLog) .. "; the crate's key padlock on " .. tostring(H.keyLocked(T.c)) .. " (the game's isLockedByPadlock)")
        H.closeCard()
        pcall(function() T.c.obj:setLockedByPadlock(true); T.c.obj:setKeyId(626262) end)
        T.ring = H.give("Base.KeyRing")
        local rinv = nil
        pcall(function() rinv = T.ring:getInventory() end)
        T.key = rinv and H.giveTo(rinv, "Base.Key1")
        pcall(function() T.key:setKeyId(626262) end)
        if not T.key then T.off = true; Q.skip(T.L .. " (a key on a key ring)", "no key ring or key"); return end
        H.zcall(function() ZeD.ObjectCardLock.openFor(S.p, T.c.obj, false) end)
    end)
    H.waitCard(T, "lock")
    H.step(2, function()
        if T.off then return end
        local have = nil
        pcall(function() have = H.inv():haveThisKeyId(626262) end)
        T.have = have ~= nil
        T.refuses = H.needsHas(ZeD.tr("UI_ZeD_Lock_NeedsKey")) ~= nil
        H.closeCard()
        -- the game's own Remove Padlock, as its world menu calls it
        H.zcall(function() ISWorldObjectContextMenu.onRemovePadlock(nil, S.pn, T.c.obj) end)
    end)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        local still = H.keyLocked(T.c)
        Q.check(T.refuses == (still == true), T.L .. ": the key on a key ring: the card offers Remove padlock exactly when the game's own Remove Padlock takes it off",
            "the card refuses " .. tostring(T.refuses) .. "; the game's haveThisKeyId " .. tostring(T.have) .. "; the game's Remove Padlock left it locked " .. tostring(still))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 3. a wrong code (LK5)
function C.c3()
    local T = { L = "3 LK5 a wrong code" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local c, err = H.mkLockCrate(H.spot(), 319, nil)
        if not c then T.off = true; Q.skip(T.L, "no padlock crate could be built: " .. tostring(err)); return end
        T.c = c
        if c.inv then H.giveTo(c.inv, "Base.Nails") end
        -- the game's own OK on a wrong code (its ISDigitalCode's button): the baseline
        local btn = { internal = "OK", parent = { getCode = function() return 123 end } }
        H.zcall(function() ISWorldObjectContextMenu.onCheckDigitalCode(nil, btn, S.p, nil, c.obj) end)
        T.gameQ = H.qlen()
        T.gameKinds = H.qkinds()
        H.qstop()
        T.pads0 = H.count("Base.CombinationPadlock")
        H.zcall(function() ISWorldObjectContextMenu.onRemoveDigitalPadlock(nil, S.pn, c.obj) end)
    end)
    H.waitCard(T, "lock")
    H.keyQ(Keyboard.KEY_1, T)
    H.keyQ(Keyboard.KEY_2, T)
    H.keyQ(Keyboard.KEY_3, T)
    H.step(2, function() if not T.off then S.qLog = {}; H.qWatchOn() end end)
    H.clickQ("oc:verb:remove", T)
    H.waitQ(T, 10000)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        T.tries = H.qLogged("ISPadlockByCodeAction")
        T.ms1 = T.qMs
        local code = H.code(T.c)
        Q.check(code == 319, T.L .. ": a wrong code leaves the padlock on (the game's getLockedByCode)", "code " .. tostring(code))
        Q.check(H.says(ZeD.tr("UI_ZeD_Lock_StatusWrong", "1 2 3")) or (H.says("1 2 3") and H.dial() == "123"), T.L .. ": the band says the code 1 2 3 was wrong, the dial kept",
            "band: " .. tostring(H.status()) .. "; drawn " .. H.textsLike("1 2 3", 4) .. "; dial " .. H.dial())
        Q.check(T.tries == 0, T.L .. " (LK5): a wrong try costs no time, as the game's own OK (which compares first and queues nothing)",
            "the card handed the game " .. T.tries .. " ISPadlockByCodeAction (" .. tostring(T.ms1) .. " ms with the walk); the game's OK on a wrong code queued "
            .. tostring(T.gameQ) .. " (" .. tostring(T.gameKinds) .. ") (ObjectCardLock's header says each try is the game's 20-tick action by design)")
        H.padOn()
        T.onRemove = H.focusCard("oc:verb:remove")
    end)
    H.tapA(function() return not T.off and T.onRemove end)
    H.waitQ(T, 10000)
    H.step(2, function() if not T.off then H.focusCard("oc:verb:remove") end end)
    H.tapA(function() return not T.off end)
    H.waitQ(T, 10000)
    Q.waitMs(300)
    H.step(2, function()
        if T.off then return end
        H.padOff()
        local n = H.qLogged("ISPadlockByCodeAction") - (T.tries or 0)
        H.note(T.L .. ": two wrong tries by the pad's A handed the game " .. n .. " more ISPadlockByCodeAction; the code " .. tostring(H.code(T.c)))
    end)
    H.keyQ(Keyboard.KEY_3, T)
    H.keyQ(Keyboard.KEY_1, T)
    H.keyQ(Keyboard.KEY_9, T)
    H.clickQ("oc:verb:remove", T)
    H.waitQ(T, 10000)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        H.qWatchOff()
        local code = H.code(T.c)
        local back = H.count("Base.CombinationPadlock") - T.pads0
        Q.check(code == 0 and back == 1, T.L .. ": the right code after three wrong takes the padlock off and the game gives a Combination Padlock back",
            "code " .. tostring(code) .. ", padlocks given back " .. back .. "; the band: " .. tostring(H.status()))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 4. the queue the hook keeps (LK6)
function C.c4()
    local T = { L = "4 LK6 the queue before the walk" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local sq = H.spot({ { 5, 0 }, { 0, 5 }, { -5, 0 }, { 0, -5 }, { 4, 3 }, { -4, 3 } })
        local c, err = H.mkLockCrate(sq, 0, nil)
        if not c then T.off = true; Q.skip(T.L, "no padlock crate 5 tiles off: " .. tostring(err)); return end
        T.c = c
        local dx = sq:getX() - math.floor(S.found.pos.x)
        local dy = sq:getY() - math.floor(S.found.pos.y)
        T.far = H.sqHome(-dx * 2, -dy * 2)
        if not T.far then T.off = true; Q.skip(T.L, "no square for a walk the other way"); return end
        T.pad = H.give("Base.CombinationPadlock")
        H.zcall(function() ISTimedActionQueue.add(ISWalkToTimedAction:new(S.p, T.far)) end)
        T.walk = H.queue()[1]
    end)
    H.step(3, function()
        if T.off then return end
        T.before = H.qkinds()
        if not (T.walk and H.queue()[1] == T.walk) then T.off = true; Q.skip(T.L, "the walk elsewhere was not running when the menu was pressed (" .. T.before .. ")"); return end
        H.zcall(function() ISWorldObjectContextMenu.onPutDigitalPadlock(nil, S.pn, T.c.obj, T.pad) end)
        T.after = H.qkinds()
        T.kept = T.walk ~= nil and H.queue()[1] == T.walk
        Q.check(not T.kept, T.L .. " (LK6): the game's Use Combination Padlock from " .. H.n1(H.sqDist(T.c.sq)) .. " tiles clears the queue first, as the game's (WOCM:1566)",
            "before: " .. tostring(T.before) .. "; after the hooked call: " .. tostring(T.after) .. " (the walk elsewhere still first " .. tostring(T.kept) .. ")")
        H.qstop()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 5. the pad's path (LK7)
-- the pad's focus is on one of the card's verbs (the band at its foot: "oc:verb:<id>")
function C.onVerb() return string.sub(tostring(H.focusedId()), 1, 8) == "oc:verb:" end
function C.c5()
    local T = { L = "5 LK7 the pad's path" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local c, err = H.mkLockCrate(H.spot(), 0, nil)
        if not c then T.off = true; Q.skip(T.L, "no padlock crate could be built: " .. tostring(err)); return end
        T.c = c
        T.pad = H.give("Base.CombinationPadlock")
        H.padOn()
        H.zcall(function() ISWorldObjectContextMenu.onPutDigitalPadlock(nil, S.pn, c.obj, T.pad) end)
    end)
    H.waitCard(T, "lock")
    H.step(2, function() if not T.off then H.padOn() end end)
    Q.waitMs(300)
    H.step(1, function()
        if T.off then return end
        S.presses = 0
        T.path = {}
        T.land = H.focusedId()
        local el = H.focusedEl()
        local pa = el and el.promptA
        local word = nil
        pcall(function() if type(pa) == "function" then word = pa(RT.ww(), el) else word = pa end end)
        local z = H.zone("lk:wheel:1")
        Q.check(T.land == "lk:wheel:1" and type(word) == "string" and word ~= "", T.L .. ": the card opens on the first wheel and its A prompt names the grab",
            "on " .. tostring(T.land) .. ", A reads \"" .. tostring(word) .. "\"; the wheel zone's help line " .. tostring(z and z.help))
        if T.land ~= "lk:wheel:1" then H.focusCard("lk:wheel:1") end
    end)
    H.dirQ("right", 2, function() return not T.off end)
    H.step(1, function() if not T.off then T.path[#T.path + 1] = "Right Right: " .. tostring(H.focusedId()) end end)
    H.tapA(function() return not T.off end)
    H.dirQ("up", 1, function() return not T.off end)
    H.tapA(function() return not T.off end)
    H.step(1, function() if not T.off then T.path[#T.path + 1] = "A Up A: dial " .. H.dial() end end)
    -- (Nov 26 2026: the Lock verb is in the verbs' band at the card's foot, under the wheels (drawVerbBand, foot =
    -- true), so a player goes Down to it; the last run pressed Up four times, which left the card for its header,
    -- the title pins and the window's own stops, and A then pressed a loot row. Down until a verb has the focus,
    -- then along the band to Lock.)
    for _ = 1, 3 do H.dirQ("down", 1, function() return not T.off and not C.onVerb() end) end
    for _ = 1, 3 do H.dirQ("right", 1, function() return not T.off and C.onVerb() and H.focusedId() ~= "oc:verb:lock" end) end
    for _ = 1, 3 do H.dirQ("left", 1, function() return not T.off and C.onVerb() and H.focusedId() ~= "oc:verb:lock" end) end
    H.step(1, function() if not T.off then T.path[#T.path + 1] = "Down to: " .. tostring(H.focusedId()) end end)
    H.tapA(function() return not T.off and H.focusedId() == "oc:verb:lock" end)
    Q.waitMs(300)
    H.step(1, function() if not T.off then T.path[#T.path + 1] = "A: asks on " .. tostring(H.focusedId()) end end)
    H.dirQ("right", 1, function() return not T.off and H.question() ~= nil end)
    H.tapA(function() return not T.off and H.focusedId() == "oc:confirm:yes" end)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        local code = H.code(T.c)
        H.padOff()
        Q.check(code == 1, T.L .. ": the pad alone sets 0 0 1 and locks the crate (the game's getLockedByCode)", "code " .. tostring(code))
        H.note(T.L .. ": " .. tostring(S.presses) .. " presses from the card's open to the locked crate: " .. table.concat(T.path, "; ")
            .. " (the game's ISDigitalCode: three boxes and OK on the pad)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 6. the half card's busy band (LK8)
function C.c6()
    local T = { L = "6 LK8 the half card's busy band" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local sq = H.spot({ { 3, 0 }, { 0, 3 }, { -3, 0 }, { 0, -3 } })
        local c, err = H.mkLockCrate(sq, 0, nil)
        if not c then T.off = true; Q.skip(T.L, "no padlock crate 3 tiles off: " .. tostring(err)); return end
        T.c = c
        T.pad = H.give("Base.CombinationPadlock")
        H.zcall(function() ISWorldObjectContextMenu.onPutDigitalPadlock(nil, S.pn, c.obj, T.pad) end)
    end)
    H.waitCard(T, "lock")
    H.keyQ(Keyboard.KEY_2, T)
    H.clickQ("oc:verb:lock", T)
    Q.waitMs(300)
    H.clickQ("oc:confirm:yes", T)
    H.wait(6000, function()
        if T.off then return true end
        local stop = H.zone("lk:stop")
        if not stop then return H.qlen() == 0 and T.seen ~= nil end
        if not T.seen then
            local c = H.card()
            local sb = (c.scroll and c.scroll.visible) and ZeD.T.sp.scrollbarW or 0
            local right = c:getWidth() - sb
            local out = {}
            for _, fid in ipairs({ "lk:up:3", "lk:dn:3", "lk:stop" }) do
                local z = H.zone(fid)
                if not z then out[#out + 1] = fid .. " not drawn"
                elseif z.x + z.w > right + 1 then out[#out + 1] = fid .. " ends at " .. math.floor(z.x + z.w) end
            end
            T.seen = { out = out, w = math.floor(c:getWidth()), right = math.floor(right), sb = c.scroll and c.scroll.visible, half = math.abs(c:getWidth() - H.px(220)) <= 1 }
            H.park(true)
            pcall(function() getCore():TakeFullScreenshot("ocl_lock_busy_" .. H.sizeTag() .. ".png") end)
            S.shots[#S.shots + 1] = "ocl_lock_busy_" .. H.sizeTag() .. ".png"
            H.note("picture Zomboid/Screenshots/ocl_lock_busy_" .. H.sizeTag() .. ".png | the lock card's busy band in the half card")
            H.park(false)
        end
        return false
    end, function()
        if T.off then return end
        local s = T.seen
        if not s then Q.skip(T.L, "the busy band never showed (the walk and the 20-tick action ended between two frames)"); return end
        Q.check(#s.out == 0 and s.half, T.L .. ": in the half card the third wheel's chevrons and Stop stay inside the body (beside the scroll bar when it shows)",
            "card " .. s.w .. " px (half " .. tostring(s.half) .. "), the body's right " .. s.right .. ", scroll bar " .. tostring(s.sb) .. "; " .. H.list(s.out))
    end)
    H.waitQ(T, 10000)
    H.caseEnd(T.L)
end

-- ===================================================================== 7. Loot columns (OC7)
function C.c7()
    local T = { L = "7 OC7 Loot columns and a card" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.crates = {}
        for _ = 1, 3 do
            local c = H.mkCrate(1)
            if c then H.giveTo(c.inv, "Base.Nails"); T.crates[#T.crates + 1] = c end
        end
        local lc = H.mkLockCrate(H.spot(H.ring(1)), 319, nil)
        if #T.crates < 2 or not lc then T.off = true; Q.skip(T.L, "no room for the crates beside him"); return end
        T.lc = lc
        H.lootRefresh()
    end)
    Q.waitMs(1200)
    for i = 1, 3 do
        H.step(4, function()
            if T.off then return end
            local c = T.crates[i]
            if c and H.inList(c.inv) then H.zcall(function() ZeD_WorldWindow.toggleColumn(c.inv, S.pn) end) end
        end)
    end
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        local w = RT.ww()
        T.cols0 = #((w and w._mcSelected) or {})
        if T.cols0 < 2 then T.off = true; Q.skip(T.L, "only " .. T.cols0 .. " Loot columns opened (the World window's toggleColumn)"); return end
        H.zcall(function() ISWorldObjectContextMenu.onRemoveDigitalPadlock(nil, S.pn, T.lc.obj) end)
    end)
    H.waitCard(T, "lock")
    H.step(2, function()
        if T.off then return end
        local w = RT.ww()
        T.cols1 = #((w and w._mcSelected) or {})
        -- (Nov 26 2026: with no room beside the card a column may step out while it is up; it must come back after)
        if T.cols1 == T.cols0 then
            Q.check(true, T.L .. ": the lock card opened by the game's Remove Combination Padlock keeps his Loot columns", T.cols0 .. " columns before, " .. T.cols1 .. " with the card up")
        else
            H.note(T.L .. ": " .. T.cols0 .. " columns before, " .. T.cols1 .. " with the card up (no room beside the card)")
        end
        H.closeCard()
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        local w = RT.ww()
        local n = #((w and w._mcSelected) or {})
        Q.check(n == T.cols0, T.L .. ": after the card closes his Loot columns are all back", T.cols0 .. " before the card, " .. tostring(T.cols1) .. " with it up, " .. n .. " 1.5 s after it closed")
        if w and #(w._mcSelected or {}) > 0 then pcall(function() ZeD_WorldWindow.closeColumns(w) end) end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== the placement card's opening
-- queue: a hammer laid on a free square beside him (key: T[key] the item, T[key .. "Wi"] its world object), then the
-- game's Extended Placement on it (its walk next to it and its action, whose end ZeD hooks)
function C.placeQ(T, key)
    key = key or "it"
    H.step(2, function()
        if T.off then return end
        if not (ISExtendedPlacementAction and ISExtendedPlacementAction._zedHooked) then
            T.off = true
            Q.check(false, T.L .. ": the game's Extended Placement is routed to the placement card (Overrides/Furniture.lua)")
            return
        end
        if not T[key] then
            local sq = H.spot()
            if not sq then T.off = true; Q.skip(T.L, "no free square beside him"); return end
            T[key], T[key .. "Wi"] = H.lay(sq, "Base.Hammer")
            T[key .. "Sq"] = sq
        end
        if not T[key .. "Wi"] then T.off = true; Q.skip(T.L, "the hammer has no world object"); return end
        H.zcall(function() ISWorldObjectContextMenu.onExtendedPlacement(T[key .. "Wi"], S.p) end)
    end)
    H.waitCard(T, "place3d", 10000)
end

-- ===================================================================== 8. the World window's close (PL1, OC2, OC3)
function C.c8()
    local T = { L = "8 PL1 OC2 the placement card and the window's close" }
    H.step(2, function() H.caseStart(T) end)
    C.placeQ(T)
    H.shot("ocl_placement_" .. H.sizeTag(), "the placement card on a hammer", function() return not T.off end)
    H.step(2, function() if not T.off then T.x0 = H.offX(T.itWi) end end)
    H.clickQ("p3:move:x:+", T)
    Q.waitMs(200)
    H.step(2, function()
        if T.off then return end
        T.x1 = H.offX(T.itWi)
        local want = math.min(1, (T.x0 or 0) + 0.01)
        Q.check(T.x1 ~= nil and math.abs(T.x1 - want) < 0.002, T.L .. ": a click on +0.01 moves the item along X (the game's getOffX)", H.n3(T.x0) .. " -> " .. H.n3(T.x1))
        H.padOn()
        T.onX = H.focusCard("p3:move:x")
    end)
    H.dirQ("right", 1, function() return not T.off and T.onX end)
    H.step(2, function()
        if T.off then return end
        T.x2 = H.offX(T.itWi)
        local want = math.min(1, (T.x1 or 0) + 0.05)
        Q.check(T.x2 ~= nil and math.abs(T.x2 - want) < 0.002, T.L .. " (pad): Right on the X slider moves it 0.05 (the game's getOffX)", H.n3(T.x1) .. " -> " .. H.n3(T.x2))
        H.padOff()
        T.doing0 = H.doing(T.it)
        local w = RT.ww()
        -- the World window's close box (its close: Organisms, the curtain rod, the pad's close-all all come here)
        if w then H.zcall(function() w:close() end) end
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        local doing, gz = H.doing(T.it), H.gizmoUp()
        local kept = T.x2 ~= nil and math.abs((H.offX(T.itWi) or -1) - T.x2) < 0.002
        Q.check(doing == false and gz ~= true, T.L .. " (PL1 OC2): the World window's close box ends the placement as the game's own close does",
            "the game's isDoingExtendedPlacement " .. tostring(T.doing0) .. " -> " .. tostring(doing) .. ", the gizmo shown " .. tostring(gz)
            .. " (ObjectCardPlacement's onClose: setDoingExtendedPlacement(false), syncExtendedPlacement, the gizmo put away)")
        Q.check(kept, T.L .. ": the place is kept after the close box", "X " .. H.n3(H.offX(T.itWi)) .. " (set " .. H.n3(T.x2) .. ")")
        pcall(function() if doing then T.it:setDoingExtendedPlacement(false) end end)
        pcall(function() Gizmos.getInstance():setGizmo(S.pn, nil) end)
        H.wwOpen()
    end)
    Q.waitMs(900)
    -- U: the World window's toggle
    C.placeQ(T)
    H.clickQ("p3:turn:z:+", T)
    H.step(2, function()
        if T.off then return end
        T.rz = H.rotZ(T.it)
        T.doing0 = H.doing(T.it)
        H.zcall(function() ZeD_WorldWindow.toggle(S.pn) end)
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        local doing, gz = H.doing(T.it), H.gizmoUp()
        Q.check(doing == false and gz ~= true, T.L .. " (PL1 OC2): U (the World window's toggle) ends the placement as the game's close does",
            "the game's isDoingExtendedPlacement " .. tostring(T.doing0) .. " -> " .. tostring(doing) .. ", the gizmo shown " .. tostring(gz) .. ", the turn kept "
            .. tostring(T.rz ~= nil and math.abs((H.rotZ(T.it) or -1) - T.rz) < 0.01))
        pcall(function() if doing then T.it:setDoingExtendedPlacement(false) end end)
        pcall(function() Gizmos.getInstance():setGizmo(S.pn, nil) end)
        H.wwOpen()
        -- the game's pick up
        T.grabbed = pcall(function() ISTimedActionQueue.add(ISGrabItemAction:new(S.p, T.itWi, 1)) end)
    end)
    H.waitQ(T, 10000)
    H.step(2, function()
        if T.off then return end
        local carried = false
        pcall(function() carried = H.inv():containsRecursive(T.it) end)
        if not (T.grabbed and carried) then H.note(T.L .. ": the game's pick up (ISGrabItemAction) did not take the hammer (queued " .. tostring(T.grabbed) .. ")"); return end
        Q.check(H.doing(T.it) == false, T.L .. " (PL1): picked up by the game's grab, the hammer is not left mid-placement (the game's flag)",
            "isDoingExtendedPlacement " .. tostring(H.doing(T.it)))
    end)
    -- OC2: the roll-up; a second hammer
    C.placeQ(T, "b")
    H.step(2, function()
        if T.off then return end
        S.allowRoll = true
        local w = RT.ww()
        pcall(function() w._autoShaded = true; w:setWindowShaded(true) end)
        T.rolled = w ~= nil and w.windowShaded == true
    end)
    H.step(5, function()
        if T.off then return end
        local sq = T.bSq
        if sq then H.goTo(sq:getX() + 6.5, sq:getY() + 0.5, sq:getZ()) end
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        T.rolledOpen = H.kind() == "place3d"
        T.gameD = H.distProper(T.bSq)
        Q.check(not (T.rolled and T.rolledOpen), T.L .. " (OC2): rolled up, the card still closes past its leash (the game's DistToProper " .. H.n1(T.gameD) .. ")",
            "rolled " .. tostring(T.rolled) .. ", the card open " .. tostring(T.rolledOpen) .. " (its upkeep runs only in its frames), the placement flag " .. tostring(H.doing(T.b)))
        S.allowRoll = nil
    end)
    Q.waitMs(1200)
    H.step(2, function()
        if T.off then return end
        H.note(T.L .. ": unrolled 6 tiles off: the card " .. tostring(H.kind() or "closed") .. ", the game's isDoingExtendedPlacement " .. tostring(H.doing(T.b)))
        pcall(function() if H.doing(T.b) and not H.card() then T.b:setDoingExtendedPlacement(false) end end)
        H.closeCard()
        H.home()
    end)
    -- OC3: B from Rotation Z
    C.placeQ(T, "b")
    H.step(2, function() if not T.off then H.padOn(); T.onZ = H.focusCard("p3:turn:z") end end)
    H.dirQ("right", 1, function() return not T.off and T.onZ end)
    H.step(2, function() if not T.off then T.rzB = H.rotZ(T.b) end end)
    H.tapB(function() return not T.off and T.onZ end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local kept = T.rzB ~= nil and math.abs((H.rotZ(T.b) or -1) - T.rzB) < 0.01
        Q.check(H.kind() == nil and H.doing(T.b) == false and kept, T.L .. " (OC3): B from Rotation Z closes the card with no question; the game keeps the turn and ends the placement",
            "card " .. tostring(H.kind()) .. ", isDoingExtendedPlacement " .. tostring(H.doing(T.b)) .. ", turn " .. H.n1(H.rotZ(T.b)) .. " (set " .. H.n1(T.rzB) .. ")")
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 9. no typed values (PL2)
function C.c9()
    local T = { L = "9 PL2 the slider" }
    H.step(2, function() H.caseStart(T) end)
    C.placeQ(T)
    -- the X slider dragged to a quarter: the pointer down on the thumb's track and moved there
    H.step(2, function()
        if T.off then return end
        local c, z = H.card(), H.zone("p3:move:x")
        if not (c and z) then T.off = true; Q.check(false, T.L .. ": the X slider is drawn", H.zoneIds("p3:")); return end
        local pad = H.px(6)
        local sx0, sw = z.x + pad, z.w - pad * 2
        T.ax = c:getAbsoluteX()
        T.ay = c:getAbsoluteY() + z.y + math.floor(z.h / 2)
        T.from = T.ax + sx0 + math.floor(sw * ((H.offX(T.itWi) or 0.5)))
        T.to = T.ax + sx0 + math.floor(sw * 0.25)
        H.ptrOn(T.from, T.ay, false)
    end)
    H.step(2, function() if not T.off then H.ptrOn(T.from, T.ay, true) end end)
    for i = 1, 6 do
        H.step(1, function() if not T.off then H.ptrOn(T.from + math.floor((T.to - T.from) * i / 6), T.ay, true) end end)
    end
    H.step(2, function() if not T.off then H.ptrOn(T.to, T.ay, false) end end)
    H.step(2, function() H.ptrOff() end)
    H.step(2, function()
        if T.off then return end
        local x = H.offX(T.itWi)
        Q.check(x ~= nil and math.abs(x - 0.25) <= 0.01, T.L .. ": the X slider dragged to a quarter sets the game's place to 0.25 within 0.01", "getOffX " .. H.n3(x))
        H.note(T.L .. " (PL2): no typed value on the card: the game's ISExtendedPlacementUI has a number box per axis; here the slider (this drag "
            .. H.n3(math.abs((x or 0) - 0.25)) .. " off), the nudges 0.01 or 15, the pad 0.05 or 15: 0.25 to 0.50 is 5 pad steps or 25 nudges, 90 degrees 6 presses")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 10. the leash (PL3)
function C.c10()
    local T = { L = "10 PL3 the placement leash" }
    H.step(2, function() H.caseStart(T) end)
    C.placeQ(T)
    H.step(2, function()
        if T.off then return end
        local sq = T.itSq
        -- a spot 3.2 by 1.2 squares off: the game's window closes there (its square 3,1 off, DistToProper 3.16)
        H.goTo(sq:getX() + 3.2, sq:getY() + 1.2, sq:getZ())
    end)
    Q.waitMs(1300)
    H.step(2, function()
        if T.off then return end
        local game, mine = H.distProper(T.itSq), H.sqDist(T.itSq)
        local open = H.kind() == "place3d"
        Q.check(not (game > 3 and open), T.L .. ": the card closes where the game's placement window closes (its DistToProper over 3)",
            "the game's DistToProper " .. H.n2(game) .. ", the card's own distance " .. H.n2(mine) .. " (its leash 3 + 0.5 from the square's middle), open " .. tostring(open))
        H.closeCard()
        H.home()
    end)
    C.placeQ(T)
    H.step(2, function()
        if T.off then return end
        T.far = H.spot({ { -7, 0 }, { 0, -7 }, { 7, 0 }, { 0, 7 }, { -6, 3 }, { 6, -3 } })
        if not T.far then T.off = true; Q.skip(T.L .. " (the hold)", "no square 7 tiles off"); return end
        T.maxOpen, T.maxD = 0, 0
        -- (what the walk saw of the World window and the card, for the detail: its close reasons, rolled up or
        -- hidden, the card's frames drawn while it read open past 3)
        T.ov = { n = 0, drew = 0, rolled = 0, hidden = 0, frames = 0, wwWhy = nil, ocWhy = nil }
        pcall(function() S.OC.closeWhy = nil end)
        H.zcall(function() ISTimedActionQueue.add(ISWalkToTimedAction:new(S.p, T.far)) end)
    end)
    H.wait(12000, function()
        if T.off then return true end
        local d = H.distProper(T.itSq)
        if d > T.maxD then T.maxD = d end
        local open = H.kind() == "place3d"
        if open and d > T.maxOpen then T.maxOpen = d end
        local ov = T.ov
        ov.frames = ov.frames + 1
        local w = RT.ww()
        local rolled, shown = false, false
        pcall(function() rolled = w.windowShaded == true end)
        pcall(function() shown = w:getIsVisible() and true or false end)
        if rolled then ov.rolled = ov.rolled + 1 end
        if not shown then ov.hidden = ov.hidden + 1 end
        if ZeD_WorldWindow._closeWhy then ov.wwWhy = tostring(ZeD_WorldWindow._closeWhy) end
        if S.OC.closeWhy then ov.ocWhy = tostring(S.OC.closeWhy) end
        if open and d > 3 then
            ov.n = ov.n + 1
            -- the card drew a frame since the last read (its tick runs in its prerender: it ran and kept the card)
            if S.cr and S.crCard == H.card() and S.cr.t ~= ov.lastT then ov.drew = ov.drew + 1 end
        end
        ov.lastT = S.cr and S.cr.t
        return (H.qlen() == 0 and d > 1) or d > 6
    end, function()
        if T.off then return end
        if T.maxD <= 3.5 then Q.skip(T.L .. " (OC5 the hold)", "the game's walk never took him past the leash (" .. H.n2(T.maxD) .. ")"); H.qstop(); return end
        local ov = T.ov
        -- (Nov 26 2026: the test reads once a frame before the card's own tick; one read past 3 with at most one frame drawn
        -- is the card closing on its next tick, not a hold. DistToProper jumps a whole square at a time)
        Q.check(T.maxOpen <= 3 or (ov.n <= 1 and ov.drew <= 1 and H.kind() ~= "place3d"), T.L .. " (OC5): with a walk away running the card still closes past the game's 3",
            "open at the game's DistToProper " .. H.n2(T.maxOpen) .. " during the walk, which reached " .. H.n2(T.maxD) .. " (the hold: any queued action holds the leash); "
            .. ov.n .. " of " .. ov.frames .. " reads open past 3, the card drew " .. ov.drew .. " frames then; the World window rolled up in " .. ov.rolled
            .. " reads, hidden in " .. ov.hidden .. "; ZeD_WorldWindow._closeWhy " .. tostring(ov.wwWhy) .. "; the card's own closeWhy " .. tostring(ov.ocWhy)
            .. "; open now " .. tostring(H.kind() == "place3d"))
        H.qstop()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 11. the pad's added option and a wall (PL5)
function C.c11()
    local T = { L = "11 PL5 the pad's option behind a wall" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not (ZeD.FurniturePlace and ZeD.FurniturePlace.onFillWorld) then T.off = true; Q.skip(T.L, "ZeD's world menu option (Overrides/Furniture.lua) is not loaded"); return end
        -- the item two squares east, a west wall on the square between (between him and the item)
        local mid, far = H.sqHome(1, 0), H.sqHome(2, 0)
        local here = S.p:getCurrentSquare()
        if not (mid and far and H.isFree(mid) and H.isFree(far)) then T.off = true; Q.skip(T.L, "no two free squares east of him"); return end
        for _, spr in ipairs({ "walls_exterior_wooden_01_24", "walls_exterior_wooden_01_25", "walls_exterior_house_01_0", "walls_exterior_house_01_1", "walls_exterior_house_01_4" }) do
            if not T.wall and getSprite(spr) then
                local o = nil
                pcall(function() o = IsoObject.new(getCell(), far, spr); far:AddTileObject(o); far:RecalcAllWithNeighbours(true) end)
                local walled = false
                pcall(function() walled = far:isWallTo(mid) or mid:isWallTo(far) end)
                if o and walled then T.wall = H.keepObj(o, far, "a wall (" .. spr .. ") on " .. far:getX() .. "," .. far:getY(), "tile"); T.spr = spr
                elseif o then H.rmObj({ obj = o, sq = far }) end
            end
        end
        if not T.wall then T.off = true; Q.skip(T.L, "no wall tile made a wall the game's isWallTo sees"); return end
        T.it, T.itWi = H.lay(far, "Base.Hammer")
        if not T.itWi then T.off = true; Q.skip(T.L, "the hammer has no world object"); return end
        -- ZeD's option, as the world menu builds it for a pad player (JoypadState holds a pad for him for this call only)
        local opts = {}
        local stub = {}
        function stub.addOption(self, label) opts[#opts + 1] = tostring(label); return {} end
        function stub.getNew(self) return stub end
        function stub.addSubMenu(self) end
        local had = JoypadState.players[S.pn + 1]
        if had == nil then JoypadState.players[S.pn + 1] = { id = -1, zedQaStub = true } end
        H.zcall(function() ZeD.FurniturePlace.onFillWorld(S.pn, stub, { T.itWi }, false) end)
        if had == nil then JoypadState.players[S.pn + 1] = nil end
        T.offers = #opts > 0
        -- the game's line of sight between his square and the item's
        local res = nil
        pcall(function() res = LosUtil.lineClear(getCell(), here:getX(), here:getY(), here:getZ(), far:getX(), far:getY(), far:getZ(), false) end)
        T.los = tostring(res)
        T.clear = res ~= nil and H.has(T.los, "Clear")
        if res == nil then
            H.note(T.L .. ": the game's LosUtil.lineClear gave nothing here; ZeD offers the option " .. tostring(T.offers) .. " (" .. H.list(opts) .. ") through " .. T.spr)
            return
        end
        Q.check(not (T.offers and not T.clear), T.L .. ": an item two squares off behind a wall: the pad's Extended Placement is not offered where the game's line of sight is blocked",
            "ZeD's option " .. tostring(T.offers) .. " (" .. H.list(opts) .. "), the game's LosUtil.lineClear " .. T.los .. "; the wall " .. tostring(T.spr)
            .. " between his square and the item's next square (placeable checks the wall between the two squares only)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== the laundry card's staging
-- queue: a machine (cls) beside him, a generator 3 tiles off for its power, litres of water in it; its card opened by
-- the gears button on its container row (the World window's own mouse handler)
function C.ldStage(T, cls, litres)
    H.step(2, function()
        if not H.caseStart(T) then return end
        local m, err = H.mkMachine(cls, H.spot({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }))
        if not m then T.off = true; Q.skip(T.L, "no " .. cls .. ": " .. tostring(err)); return end
        T.m = m
        local gsq = H.spot(H.ring(3))
        T.gen = gsq and H.mkGen(gsq)
        if not T.gen then T.off = true; Q.skip(T.L, "no square for the generator"); return end
        if cls == "IsoCombinationWasherDryer" then pcall(function() m.obj:setModeWasher() end) end
        T.litres = H.water(m.obj, litres)
        T.waterHow = S.waterHow
        if litres > 0 and T.litres <= 0 then T.off = true; Q.skip(T.L, "the machine took no water (" .. tostring(S.waterHow) .. "): its Power needs water"); return end
        H.lootRefresh()
    end)
    H.wait(8000, function() return T.off or H.powered(T.m.obj) end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.skip(T.L, "the generator gave the machine no power"); return end
        pcall(function() ZeD_WorldWindow.selectContainer(T.m.inv, 60, S.pn) end)
    end)
    H.wait(6000, function() return T.off or H.ccIdx("obj:ZeDLaundry") ~= nil end, function()
        if T.off then return end
        if not H.pressGears() then
            if not S.said.gears then S.said.gears = true; H.note(T.L .. ": no gears button on the machine's row this frame: opened by ZeD.ObjectCardLaundry.open") end
            H.zcall(function() ZeD.ObjectCardLaundry.open(S.p, T.m.obj) end)
        end
    end)
    H.waitCard(T, "laundry")
end

-- ===================================================================== 12. Power twice (LA1, OC6)
function C.c12()
    local T = { L = "12 LA1 OC6 Power pressed twice" }
    C.ldStage(T, "IsoClothingWasher", 20)
    H.step(2, function()
        if T.off then return end
        local sq = T.m.sq
        H.goTo(sq:getX() - 3.5, sq:getY() + 0.5, sq:getZ())
        T.on0 = H.on(T.m.obj)
        S.qLog = {}
        H.qWatchOn()
    end)
    Q.waitMs(400)
    -- what the card held for Power as the press came (its switch live only with power and water: def.refresh's
    -- canToggle; the zone's run is nil when it is not)
    H.step(1, function()
        if T.off then return end
        local t, z = H.ct(), H.zone("ldy:power")
        local d = (t and t.d) or {}
        T.pw = "the zone drawn " .. tostring(z ~= nil) .. ", live " .. tostring(z ~= nil and z.run ~= nil) .. "; the card read power " .. tostring(d.powered)
            .. ", water " .. H.n1(d.fluid) .. " L (canToggle " .. tostring(d.canToggle) .. "); the game: isPowered " .. tostring(H.powered(T.m.obj))
            .. ", " .. H.n1(T.litres) .. " L staged by " .. tostring(T.waterHow)
    end)
    H.dblQ("ldy:power", T)
    H.step(1, function()
        if T.off then return end
        local t = H.ct()
        T.face = t and t.d and t.d.on
        T.gameNow = H.on(T.m.obj)
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        local n, on = H.qLogged("ISToggleClothingWasher"), H.on(T.m.obj)
        Q.check(n <= 1 and on == true, T.L .. ": a double click on Power from 4 tiles starts the washer once (the game's toggles queued, isActivated after)",
            n .. " toggles handed to the game (" .. H.list(S.qLog, 10) .. "); isActivated " .. tostring(T.on0) .. " -> " .. tostring(on) .. "; " .. tostring(T.pw))
        H.note(T.L .. " (OC6): right after the presses the face read running " .. tostring(T.face) .. " while the game had " .. tostring(T.gameNow)
            .. " (the card reads the game every 250 ms; its face shows nothing of the walk)")
    end)
    H.shot("ocl_laundry_" .. H.sizeTag(), "the laundry card on a running washer", function() return not T.off end)
    -- the pad: A A from 4 tiles
    H.step(2, function()
        if T.off then return end
        pcall(function() T.m.obj:setActivated(false) end)
        local sq = T.m.sq
        H.goTo(sq:getX() - 3.5, sq:getY() + 0.5, sq:getZ())
        S.qLog = {}
        H.padOn()
        T.onPower = H.focusCard("ldy:power")
    end)
    Q.waitMs(400)
    H.tapA(function() return not T.off and T.onPower end)
    H.tapA(function() return not T.off and T.onPower end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        local n, on = H.qLogged("ISToggleClothingWasher"), H.on(T.m.obj)
        Q.check(n <= 1 and on == true, T.L .. " (pad): A A on Power from 4 tiles starts the washer once (the game's toggles queued, isActivated after)",
            n .. " toggles handed to the game (" .. H.list(S.qLog, 10) .. "); isActivated after " .. tostring(on) .. "; the pad's focus put on Power "
            .. tostring(T.onPower) .. ", water now " .. H.n1(H.call0(T.m.obj, "getFluidAmount")) .. " L")
        H.qWatchOff()
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 13. running without power or water, the cycle (LA3, LA2)
function C.c13()
    local T = { L = "13 LA3 LA2 a running washer" }
    C.ldStage(T, "IsoClothingWasher", 20)
    H.clickQ("ldy:power", T)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        if not H.on(T.m.obj) then T.off = true; Q.skip(T.L, "the washer did not start (the game's isActivated false)"); return end
        T.running = ZeD.tr("UI_ZeD_Power_PillRunning")
        pcall(function() T.gen.obj:setActivated(false) end)
    end)
    Q.waitMs(3000)
    H.step(2, function()
        if T.off then return end
        local pw, on, tag = H.powered(T.m.obj), H.on(T.m.obj), H.pillTag()
        local says = tag ~= nil and H.hasI(tag.s, T.running)
        Q.check(not (says and not pw and on), T.L .. " (LA3): the power cut: the card does not say Running over a machine with no power",
            "the game: powered " .. tostring(pw) .. ", isActivated " .. tostring(on) .. " 3 s after the cut; the card's tag \"" .. tostring(tag and tag.s) .. "\"")
        H.note(T.L .. ": the game turned the washer off with its power: " .. tostring(on == false))
        pcall(function() T.gen.obj:setActivated(true) end)
    end)
    H.wait(6000, function() return T.off or H.powered(T.m.obj) end, function()
        if T.off then return end
        pcall(function() if not T.m.obj:isActivated() then T.m.obj:setActivated(true) end end)
        H.water(T.m.obj, 0)
    end)
    Q.waitMs(3000)
    H.step(2, function()
        if T.off then return end
        local wl, on, tag = 0, H.on(T.m.obj), H.pillTag()
        pcall(function() wl = T.m.obj:getFluidAmount() end)
        local says = tag ~= nil and H.hasI(tag.s, T.running)
        Q.check(not (says and on and wl <= 0), T.L .. " (LA3): the water drained: the card does not say Running over a washer with no water",
            "the game: water " .. H.n1(wl) .. " L, isActivated " .. tostring(on) .. " 3 s after; the card's tag \"" .. tostring(tag and tag.s) .. "\"")
        H.note(T.L .. ": the game turned the washer off with no water: " .. tostring(on == false))
        -- LA2: a dirty, bloody, wet shirt washed at speed
        H.water(T.m.obj, 20)
        pcall(function() if not T.m.obj:isActivated() then T.m.obj:setActivated(true) end end)
        T.shirt = H.giveTo(T.m.inv, "Base.Shirt_FormalWhite") or H.giveTo(T.m.inv, "Base.Tshirt_DefaultTEXTURE_TINT")
        if not T.shirt then T.off = true; Q.skip(T.L .. " (LA2)", "no shirt type to wash"); return end
        -- (Clothing's own setters: setDirtiness and setBloodLevel; a call to a name it lacks is logged even in pcall)
        pcall(function() T.shirt:setDirtiness(60) end)
        pcall(function() T.shirt:setBloodLevel(60) end)
        pcall(function() T.shirt:setWetness(0) end)
        T.samples = {}
        T.first = C.shirtNow(T)
        -- the game's own words for clothes (its item tooltip's)
        T.words = { getText("Tooltip_clothing_dirty"), getText("Tooltip_clothing_bloody"), getText("Tooltip_clothing_wet"), getText("Tooltip_Wetness") }
        T.cardSaid = nil
        T.min0 = getGameTime():getWorldAgeHours() * 60
        H.speed(3)
    end)
    for _ = 1, 8 do
        Q.waitMs(1000)
        H.step(1, function()
            if T.off then return end
            local s = C.shirtNow(T)
            local m = math.floor(getGameTime():getWorldAgeHours() * 60 - T.min0)
            T.samples[#T.samples + 1] = m .. " min: dirt " .. H.n1(s.d) .. ", blood " .. H.n1(s.b) .. ", wet " .. H.n1(s.w) .. ", on " .. tostring(H.on(T.m.obj))
            T.last = s
            for _, wd in ipairs(T.words) do if H.drewI(wd) then T.cardSaid = wd end end
        end)
    end
    H.step(2, function()
        H.speed(1)
        if T.off then return end
        H.note(T.L .. " (LA2): the game's washer on the shirt, at speed (each sample a second of real time): " .. table.concat(T.samples, "; "))
        local a, l = T.first or {}, T.last or {}
        local changed = (l.d or 0) ~= (a.d or 0) or (l.b or 0) ~= (a.b or 0) or (l.w or 0) ~= (a.w or 0)
        Q.check(not (changed and T.cardSaid == nil), T.L .. " (LA2): while the game changes the clothes the card names their state in the game's words (dirty, bloody, wet)",
            "the game changed the shirt " .. tostring(changed) .. " (dirt " .. H.n1(a.d) .. " -> " .. H.n1(l.d) .. ", blood " .. H.n1(a.b) .. " -> " .. H.n1(l.b) .. ", wet "
            .. H.n1(a.w) .. " -> " .. H.n1(l.w) .. "); the card drew " .. tostring(T.cardSaid or "none of them") .. " (it shows its own phases and the count inside); the game stopped it itself "
            .. tostring(H.on(T.m.obj) == false))
        pcall(function() T.m.obj:setActivated(false) end)
    end)
    H.caseEnd(T.L)
end

-- the shirt's dirt, blood and wetness, as the game's own getters give them
function C.shirtNow(T)
    local s = { d = -1, b = -1, w = -1 }
    pcall(function() s.d = T.shirt:getDirtiness() end)
    pcall(function() s.b = T.shirt:getBloodLevel() end)
    pcall(function() s.w = T.shirt:getWetness() end)
    return s
end

-- ===================================================================== 14. the Door from afar (LA4)
function C.c14()
    local T = { L = "14 LA4 the Door" }
    C.ldStage(T, "IsoClothingWasher", 20)
    H.step(2, function()
        if T.off then return end
        local sq = T.m.sq
        H.goTo(sq:getX() - 2.5, sq:getY() + 0.5, sq:getZ())
        RT.worldTab("loot")
        H.lootRefresh()
    end)
    Q.waitMs(1200)
    H.step(2, function() if not T.off then T.listed0 = H.inList(T.m.inv) ~= nil end end)
    H.clickQ("ldy:door", T)
    Q.waitMs(3000)
    H.step(2, function()
        if T.off then return end
        local shown = H.shownInv() == T.m.inv
        local said = H.status()
        Q.check(shown or said ~= nil, T.L .. ": Door from 3 tiles shows the washer's contents in the Loot pane, or the card says why not",
            "listed in the World window " .. tostring(T.listed0) .. " -> " .. tostring(H.inList(T.m.inv) ~= nil) .. ", shown " .. tostring(shown) .. "; the band: " .. tostring(said)
            .. " (the game's loot window lists a container within a square)")
        H.goTo(T.m.sq:getX() - 0.5, T.m.sq:getY() + 0.5, T.m.sq:getZ())
        H.lootRefresh()
    end)
    Q.waitMs(1200)
    H.clickQ("ldy:door", T)
    Q.waitMs(2000)
    H.step(2, function()
        if T.off then return end
        Q.check(H.shownInv() == T.m.inv, T.L .. ": Door from beside it shows the washer's contents in the Loot pane", "shown " .. tostring(H.shownInv() == T.m.inv))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 15. the washer-dryer's mode (LA5, OC3)
function C.c15()
    local T = { L = "15 LA5 the washer-dryer's mode" }
    C.ldStage(T, "IsoCombinationWasherDryer", 0)
    H.step(2, function()
        if T.off then return end
        local wm = nil
        pcall(function() wm = T.m.obj:isModeWasher() end)
        if not wm then T.off = true; Q.skip(T.L, "the washer-dryer is not in washer mode"); return end
        S.qLog = {}
        H.qWatchOn()
    end)
    H.clickQ("ldy:mode_dry", T)
    H.waitQ(T, 10000)
    H.step(2, function()
        if T.off then return end
        local dry = nil
        pcall(function() dry = T.m.obj:isModeDryer() end)
        Q.check(dry == true, T.L .. ": DRY with no water in washer mode: the game's ISSetComboWasherDryerMode takes it (isModeDryer)",
            "handed " .. H.list(S.qLog) .. "; isModeDryer " .. tostring(dry))
        H.note(T.L .. ": the game's loot window hides Set mode in washer mode with no water (CombinationWasherDryerSetMode:9); the card offers it with power")
        H.padOn()
        T.onWash = H.focusCard("ldy:mode_wash")
    end)
    H.tapA(function() return not T.off and T.onWash end)
    H.waitQ(T, 10000)
    H.step(2, function()
        if T.off then return end
        local wm = nil
        pcall(function() wm = T.m.obj:isModeWasher() end)
        Q.check(wm == true, T.L .. " (pad): A on WASH sets washer mode (the game's isModeWasher)", "focused " .. tostring(T.onWash) .. ", isModeWasher " .. tostring(wm))
        H.qWatchOff()
        T.onDoor = H.focusCard("ldy:door")
    end)
    H.tapB(function() return not T.off and T.onDoor end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        Q.check(H.kind() == nil, T.L .. " (OC3): B from the Door closes the laundry card with no question", "card " .. tostring(H.kind()))
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 16. the hold (OC5)
function C.c16()
    local T = { L = "16 OC5 the leash hold" }
    C.ldStage(T, "IsoClothingWasher", 20)
    H.step(2, function()
        if T.off then return end
        T.far = H.spot({ { -10, 0 }, { 0, -10 }, { 0, 10 }, { 10, 0 }, { -9, 4 }, { 9, -4 } })
        if not T.far then T.off = true; Q.skip(T.L, "no square 10 tiles off"); return end
        T.maxD, T.reach, T.overN = 0, 0, 0
        pcall(function() S.OC.closeWhy = nil end)
        H.zcall(function() ISTimedActionQueue.add(ISWalkToTimedAction:new(S.p, T.far)) end)
    end)
    H.wait(15000, function()
        if T.off then return true end
        local d = H.sqDist(T.m.sq)
        if d > T.reach then T.reach = d end
        local open = H.kind() == "laundry"
        if open and d > T.maxD then T.maxD = d end
        if open and d > 6.5 then T.overN = T.overN + 1 end
        if not open and T.wasOpen and not T.why then T.why = tostring(S.OC.closeWhy); T.whyD = d end
        T.wasOpen = open
        return d > 8 or (H.qlen() == 0 and d > 1)
    end, function()
        if T.off then return end
        T.openFar = H.kind() == "laundry"
        if T.reach <= 6.5 then T.off = true; Q.skip(T.L, "the game's walk never took him past the leash (" .. H.n1(T.reach) .. " tiles)"); H.qstop(); return end
        -- (Nov 26 2026: the card's leash is 6 + 0.5 from the square's middle (OC.tick: OC.squareDist > leash + 0.5),
        -- as this reads it, and the last run's card closed at 6.53 (its own closeWhy). This wait is asked once a frame
        -- before the card's prerender runs its tick, so the frame the walk first steps past 6.5 is read here with the
        -- card still open: maxD 6.52 printed "6.5" and failed. The card keeps its leash when it closes within one
        -- frame's walk of 6.5 and is shut at the walk's end; a card that held on would read 7 and more.)
        local step = 0.25
        Q.check(T.maxD <= 6.5 + step and not T.openFar, T.L .. ": the card keeps its leash while a walk it never started runs (the game's walk 10 tiles off)",
            "open at most " .. H.n2(T.maxD) .. " tiles from the washer (its leash 6 + 0.5; a frame's walk of " .. step .. " over allowed: this reads before the card's tick), "
            .. T.overN .. " frames read open past 6.5; the card closed: " .. tostring(T.why) .. " (read " .. H.n2(T.whyD) .. " tiles); open now " .. tostring(T.openFar))
        S.qLog = {}
        H.qWatchOn()
    end)
    H.clickQ("ldy:power", T)
    H.step(3, function()
        if T.off then return end
        if T.openFar then H.note(T.L .. ": Power pressed " .. H.n1(H.sqDist(T.m.sq)) .. " tiles off handed the game " .. H.list(S.qLog) .. " (the queue now " .. H.qkinds() .. ")") end
        H.qWatchOff()
        H.qstop()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 17. numbers and words at each First Aid level (MD2)
function C.c17()
    local T = { L = "17 MD2 the medic card's numbers and words" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not H.bodyOn(T, 3) then T.off = true; Q.skip(T.L, "fewer than three whole body parts to lay wounds on"); return end
        T.w = { { rec = T.parts[1], word = getText("IGUI_health_Scratched") }, { rec = T.parts[2], word = getText("IGUI_health_DeepWound") },
                { rec = T.parts[3], word = getText("IGUI_health_Fracture") } }
        H.scratch(T.parts[1].bp, 18)
        H.deep(T.parts[2].bp, 11)
        H.fracture(T.parts[3].bp, 60)
        -- (the game's panel sets its cheat from debug mode: off here, so both read the words a doctor gets in play)
        pcall(function() T.cheat = ISHealthPanel.cheat end)
        if T.cheat then H.note(T.L .. ": the game's health panel cheat is on (a debug game): off for this case, as in play") end
        ISHealthPanel.cheat = false
    end)
    for _, lvl in ipairs(S.LEVELS) do
        H.step(2, function()
            if T.off then return end
            H.closeCard()
            H.perkSet("Doctor", lvl)
        end)
        H.step(2, function() if not T.off then H.medOpen() end end)
        H.waitCard(T, "medic")
        Q.waitMs(400)
        H.step(2, function()
            if T.off then return end
            local tags = H.cardTags()
            local bad, rows = {}, {}
            for _, w in ipairs(T.w) do
                local game, err = H.gameRows(w.rec.bp, lvl)
                if not game then T.noGame = err; break end
                local g, c = H.qual(game, w.word), H.qual(tags, w.word)
                rows[#rows + 1] = w.word .. " game " .. g .. " card " .. c
                if g ~= c then bad[#bad + 1] = w.word .. " (the game's " .. g .. ", the card's " .. c .. ")" end
                for _, s in ipairs(game) do if string.find(s, "%d") then T.gameNum = (T.gameNum or 0) + 1 end end
            end
            if T.noGame then Q.skip(T.L .. " at First Aid " .. lvl, "the game's own list row could not be drawn: " .. tostring(T.noGame)); return end
            Q.check(#bad == 0, T.L .. ": at First Aid " .. lvl .. " the card grades each wound as the game's health panel does for that doctor (cheat off)",
                H.list(rows) .. (#bad > 0 and ("; differs: " .. H.list(bad)) or ""))
            local pct = H.pctTexts()
            if lvl == 0 then
                Q.check(pct == 0, T.L .. " (MD2): at First Aid 0 the card gives no exact health the game's panel gives a doctor only in cheat mode",
                    pct .. " percent figures drawn (the overall tag, the rows' part health); the game's rows drew " .. tostring(T.gameNum or 0)
                    .. " figures and its overall reading is a damage word (the director's call: numbers by design?)")
            else
                H.note(T.L .. ": at First Aid " .. lvl .. " " .. pct .. " percent figures drawn")
            end
        end)
        if lvl == 5 then H.shot("ocl_medic_" .. H.sizeTag(), "the medical check card on a scratch, a deep wound and a fracture, First Aid 5", function() return not T.off end) end
    end
    H.step(2, function()
        H.closeCard()
        for _, rec in ipairs(T.parts or {}) do H.bpBack(rec) end
        H.perkSet("Doctor", S.found.lvl.Doctor)
        ISHealthPanel.cheat = S.found.hcheat
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 18. a second press during a treatment (MD1)
function C.c18()
    local T = { L = "18 MD1 a treatment pressed twice" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not H.bodyOn(T, 1) then T.off = true; Q.skip(T.L, "no whole body part to lay a scratch on"); return end
        T.bp = T.parts[1].bp
        H.perkSet("Doctor", 3)
        H.scratch(T.bp, 10)
        H.give("Base.Bandage")
        H.give("Base.Bandage")
        T.b0 = H.count("Base.Bandage")
        S.qLog, S.handed = {}, 0
        H.qWatchOn()
        T.label = getText("ContextMenu_Bandage")
        H.medOpen()
    end)
    H.waitCard(T, "medic")
    H.step(2, function()
        if T.off then return end
        T.row = H.rowFid(T.bp)
        if not T.row then T.off = true; Q.check(false, T.L .. ": the scratched part has a row on the card", H.zoneIds("mc:")); return end
    end)
    -- (the row's stop id is known only once the card drew: the click reads it when it runs)
    C.rowClickQ(T)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        T.menu1 = H.ctxNames()
        T.pick1 = H.pickOpt(T.label)
        if not T.pick1 then T.off = true; Q.check(false, T.L .. ": a click on the row opens the game's treatment menu with its bandage", "menu " .. tostring(H.ctxVis()) .. ": " .. T.menu1); return end
    end)
    H.wait(4000, function() return T.off or H.head() == "ISApplyBandage" end, function(ok)
        if T.off then return end
        T.running = ok
        T.job = H.gameJob(T.bp)
        T.cardJob = H.drewI(getText("ContextMenu_Bandage")) or H.drewI(getText("ContextMenu_Apply_Bandage"))
    end)
    C.rowClickQ(T)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        T.stillRunning = H.head() == "ISApplyBandage"
        T.pick2 = H.pickOpt(T.label)
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        local spent = T.b0 - H.count("Base.Bandage")
        Q.check(spent <= 1, T.L .. ": the part clicked again while the game's bandage runs spends no second bandage",
            spent .. " bandages spent; offered again during it: " .. tostring(T.pick2) .. " (the first still running " .. tostring(T.stillRunning) .. "); the game was handed "
            .. H.list(S.qLog, 8) .. " (" .. tostring(S.handed) .. " with him as the patient); bandaged now " .. tostring(T.bp:bandaged()))
        Q.check(not (T.job ~= nil and T.cardJob == nil), T.L .. ": the card shows the treatment the game records as running (its health view's bodyPartAction)",
            "the game's record while it ran " .. tostring(T.job ~= nil) .. " (job " .. tostring(T.job and T.job.jobType) .. "), the card drew it " .. tostring(T.cardJob ~= nil))
        H.qWatchOff()
        H.closeCard()
        for _, rec in ipairs(T.parts or {}) do H.bpBack(rec) end
        H.perkSet("Doctor", S.found.lvl.Doctor)
    end)
    H.caseEnd(T.L)
end
-- queue: a click on the injury row T.row (looked up when the click runs)
function C.rowClickQ(T)
    local st = {}
    H.step(1, function()
        if T.off then return end
        T.row = H.rowFid(T.bp) or T.row
        local x, y = H.zAbs(T.row or "")
        if not x then return end
        st.x, st.y = x, y
        H.ptrOn(x, y, false)
    end)
    H.step(2, function() if st.x then H.ptrOn(st.x, st.y, true) end end)
    H.step(2, function() if st.x then H.ptrOn(st.x, st.y, false) end end)
    H.step(2, function() if st.x then H.ptrOff() end end)
end

-- ===================================================================== 19. the pad's menu, paused, B (MD4, MD5, OC3)
function C.c19()
    local T = { L = "19 MD4 MD5 the treatment menu" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not H.bodyOn(T, 1) then T.off = true; Q.skip(T.L, "no whole body part to lay a scratch on"); return end
        T.bp = T.parts[1].bp
        H.perkSet("Doctor", 3)
        H.scratch(T.bp, 10)
        H.give("Base.Bandage")
        H.padOn()
        H.medOpen()
    end)
    H.waitCard(T, "medic")
    H.step(2, function()
        if T.off then return end
        T.land = H.focusedId()
        T.row = H.rowFid(T.bp)
        H.note(T.L .. ": the medic card opened with the pad on " .. tostring(T.land) .. " (its worst injury's row " .. tostring(T.row) .. ")")
        T.onRow = T.row ~= nil and H.focusCard(T.row)
    end)
    H.tapA(function() return not T.off and T.onRow end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local c, card = H.ctx(), H.card()
        local vis = H.ctxVis()
        local sw, sh = H.screen()
        local r = { x = 0, y = 0, w = 0, h = 0 }
        pcall(function() r.x, r.y, r.w, r.h = c:getX(), c:getY(), c:getWidth(), c:getHeight() end)
        local inside = r.x >= 0 and r.y >= 0 and r.x + r.w <= sw + 1 and r.y + r.h <= sh + 1
        local cardR = card and (card:getAbsoluteX() + card:getWidth()) or 0
        Q.check(vis and inside, T.L .. " (MD4): the pad's A on the row opens the game's treatment menu inside the screen",
            "menu " .. tostring(vis) .. " at " .. math.floor(r.x) .. "," .. math.floor(r.y) .. " " .. math.floor(r.w) .. "x" .. math.floor(r.h) .. " on " .. sw .. "x" .. sh
            .. "; the card's right edge " .. math.floor(cardR) .. "; options " .. H.ctxNames())
        local jp = nil
        pcall(function() jp = JoypadState.players[S.pn + 1] end)
        if jp == nil then H.note(T.L .. ": no real pad here (JoypadState has none): the game's menu takes no pad focus on this rig, so where a real pad's focus goes on the menu is for the director's pad") end
        T.menuUp = vis
    end)
    H.tapB(function() return not T.off and T.menuUp end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local vis, kind = H.ctxVis(), H.kind()
        if T.menuUp then
            Q.check(not (kind == nil and vis), T.L .. " (MD4): B with the game's menu up does not close the card and leave the menu standing",
                "after B: the menu up " .. tostring(vis) .. ", the card " .. tostring(kind))
        end
        H.ctxShut()
        H.padOff()
        if not H.card() then H.medOpen() end
    end)
    H.waitCard(T, "medic")
    -- MD5: paused
    H.step(2, function() if not T.off then H.speed(0) end end)
    Q.waitMs(300)
    C.rowClickQ(T)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local vis = H.ctxVis()
        local dbg = false
        pcall(function() dbg = getDebug() and true or false end)
        H.speed(1)
        Q.check(vis == dbg, T.L .. " (MD5): paused, a click on the row opens a treatment menu only as the game's panel would (none at speed 0 outside debug)",
            "menu " .. tostring(vis) .. ", debug " .. tostring(dbg) .. "; nothing said either way (MD5: the press is silent)")
        H.ctxShut()
        H.padOn()
        T.onRow = H.focusCard(H.rowFid(T.bp) or "")
    end)
    -- OC3: B from a row
    H.tapB(function() return not T.off and T.onRow end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        Q.check(H.kind() == nil, T.L .. " (OC3): B from an injury row closes the medic card with no question", "card " .. tostring(H.kind()))
        H.padOff()
        for _, rec in ipairs(T.parts or {}) do H.bpBack(rec) end
        H.perkSet("Doctor", S.found.lvl.Doctor)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== the track's stand-in
-- the game's track data in its own words; wi(): its world item while it lies on the ground, else nil
function C.trackItem(T)
    local at = {
        getTrackType = function() return T.trk.type end,
        getDir = function() return T.trk.dir end,
        getAnimalType = function() return T.trk.animal end,
        getFreshnessString = function() return T.trk.fresh end,
    }
    return {
        getAnimalTracks = function() return at end,
        getWorldItem = function() return T.trkWi end,
        getTex = function() return nil end,
    }
end
function C.trackQ(T)
    H.step(2, function()
        if T.off then return end
        if not (ISInspectAnimalTrackAction and ISInspectAnimalTrackAction._zedCardHooked) then
            T.off = true
            Q.check(false, T.L .. ": the game's Inspect Track is routed to the track card (Overrides/Animals.lua)")
            return
        end
        T.item = T.item or C.trackItem(T)
        H.zcall(function() ISTimedActionQueue.add(ISInspectAnimalTrackAction:new(S.p, T.item)) end)
    end)
    H.waitCard(T, "track", 10000)
end
function C.refreshCard() local t = H.ct(); if t then t._refreshT = 999 end end

-- ===================================================================== 20. the freshness tag, long words (TK1, TK2)
function C.c20()
    local T = { L = "20 TK1 TK2 the track card" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.perkSet("Tracking", 5)
        T.trk = { type = "footstep", dir = "NE", animal = "deer", fresh = getText("IGUI_AnimalTracks_Time_5Days") }
    end)
    C.trackQ(T)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        local tag = H.pillTag()
        T.oldTag = tag
        Q.check(not (tag and tag.c == ZeD.T.positive), T.L .. " (TK1): a track over 4 days old is not tagged as a good state (the game's window writes its freshness plain)",
            "the game's word \"" .. tostring(T.trk.fresh) .. "\", the card's tag \"" .. tostring(tag and tag.s) .. "\" marked " .. H.colName(tag and tag.c))
        T.trk.fresh = getText("IGUI_AnimalTracks_Time_VeryRecent")
        C.refreshCard()
    end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local tag = H.pillTag()
        H.note(T.L .. ": a very recent track's tag \"" .. tostring(tag and tag.s) .. "\" marked " .. H.colName(tag and tag.c) .. ", the old one's " .. H.colName(T.oldTag and T.oldTag.c))
    end)
    H.shot("ocl_track_" .. H.sizeTag(), "the track card on a very recent footstep, Tracking 5", function() return not T.off end)
    -- TK2: the game's longest species and freshness words at the run's text size
    H.step(2, function()
        if T.off then return end
        local f2 = ZeD.T.fontF2
        local best, bw = nil, -1
        for k in pairs(MigrationGroupDefinitions or {}) do
            local s = getTextOrNull and getTextOrNull("IGUI_MigrationGroup_" .. tostring(k))
            if s then
                local w = ZeD.TM:MeasureStringX(f2, s)
                if w > bw then best, bw = k, w end
            end
        end
        local fb, fw = nil, -1
        for _, k in ipairs({ "12Hours", "24Hours", "2Days", "3Days", "4Days", "5Days", "VeryRecent", "Recent", "SomeDays", "Old" }) do
            local s = getText("IGUI_AnimalTracks_Time_" .. k)
            local w = ZeD.TM:MeasureStringX(f2, s)
            if w > fw then fb, fw = s, w end
        end
        if best then T.trk.animal = best end
        if fb then T.trk.fresh = fb end
        T.species = best and getText("IGUI_MigrationGroup_" .. tostring(best)) or nil
        C.refreshCard()
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        local c = H.card()
        local sb = (c and c.scroll and c.scroll.visible) and ZeD.T.sp.scrollbarW or 0
        local right = (c and c:getWidth() or 0) - sb - H.px(10)
        local out = {}
        for _, t in ipairs(H.texts()) do
            if t.s == T.species or t.s == T.trk.fresh then
                local w = ZeD.TM:MeasureStringX(t.font or ZeD.T.fontF2, t.s)
                if t.x + w > right + 1 then out[#out + 1] = "\"" .. t.s .. "\" ends at " .. math.floor(t.x + w) end
            end
        end
        Q.check(#out == 0, T.L .. " (TK2): the game's longest species and freshness words stay inside the card at the run's text size (" .. tostring(ZeD.currentSize) .. ", " .. H.lang() .. ")",
            "the body's right " .. math.floor(right) .. "; " .. H.list(out) .. "; species \"" .. tostring(T.species) .. "\", freshness \"" .. tostring(T.trk.fresh) .. "\"")
    end)
    H.step(1, function()
        Q.skip(T.L .. " (TK2) in German, Russian and Japanese", "the language is the game's own setting, read at its start: a run started in each")
        H.perkSet("Tracking", S.found.lvl.Tracking)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 21. a track that changes hands (TK3, OC3)
function C.c21()
    local T = { L = "21 TK3 a track he picks up" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.trk = { type = "poop", dir = "S", animal = "deer", fresh = getText("IGUI_AnimalTracks_Time_Recent") }
        local sq = H.spot()
        if not sq then T.off = true; Q.skip(T.L, "no free square beside him"); return end
        T.it, T.trkWi = H.lay(sq, "Base.Hammer")
        T.sq = sq
        if not T.trkWi then T.off = true; Q.skip(T.L, "no world item to stand for the droppings"); return end
    end)
    C.trackQ(T)
    -- picked up: the game's grab, the stand-in then has no world item
    H.step(2, function()
        if T.off then return end
        T.grabbed = pcall(function() ISTimedActionQueue.add(ISGrabItemAction:new(S.p, T.trkWi, 1)) end)
    end)
    H.waitQ(T, 8000)
    H.step(2, function()
        if T.off then return end
        local carried = false
        pcall(function() carried = H.inv():containsRecursive(T.it) end)
        if not carried then H.removeItem(T.it); pcall(function() H.inv():AddItem(T.it) end); H.note(T.L .. ": the game's grab did not take it (queued " .. tostring(T.grabbed) .. "): moved to his inventory") end
        T.trkWi = nil
        T.wasOpen = H.kind() == "track"
        H.goTo(T.sq:getX() + 7.5, T.sq:getY() + 0.5, T.sq:getZ())
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        local carried = false
        pcall(function() carried = H.inv():containsRecursive(T.it) end)
        local open = H.kind() == "track"
        Q.check(not (carried and T.wasOpen and not open), T.L .. ": the track he picked up keeps its card while he carries it 7 tiles off",
            "he carries it " .. tostring(carried) .. " (the game's container), open before the walk " .. tostring(T.wasOpen) .. ", open now " .. tostring(open)
            .. " (the card's leash counts from where it lay, " .. H.n1(H.sqDist(T.sq)) .. " tiles)")
        H.home()
    end)
    H.step(2, function() if not T.off and H.kind() ~= "track" then T.item = nil end end)
    C.trackQ(T)
    H.step(2, function() if not T.off then H.removeItem(T.it) end end)
    Q.waitMs(1200)
    H.step(2, function()
        if T.off then return end
        H.note(T.L .. ": the item gone (the game: in no container, on no square " .. tostring(H.gone(T.it)) .. "): the card open " .. tostring(H.kind() == "track")
            .. " (valid() is always true for an item; the game's own window keeps its window too)")
        -- (Nov 26 2026: the leg's own ISInspectAnimalTrackAction was still queued at B and reopened the card after it:
        -- clear the game's queue before B, so only the card's B is judged)
        pcall(function() ISTimedActionQueue.clear(S.p) end)
        H.padOn()
        T.onBack = H.focusCard("oc:back")
        T.qAtB = H.qkinds and H.qkinds() or "?"
    end)
    H.tapB(function() return not T.off and T.onBack end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        -- (Nov 26 2026: say where the pad's focus was before B; with no focus on the card, B never reached it)
        if not T.onBack then
            Q.skip(T.L .. " (OC3): B on the track card closes it", "the pad's focus did not land on oc:back (on " .. tostring(H.focusedId()) .. "), so B was not pressed")
        else
            Q.check(H.kind() == nil, T.L .. " (OC3): B on the track card closes it", "card " .. tostring(H.kind()) .. "; the focus before B on oc:back, now " .. tostring(H.focusedId())
                .. "; the game's queue at B " .. tostring(T.qAtB) .. ", now " .. tostring(H.qkinds and H.qkinds() or "?"))
        end
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 22. the bonus health rounded (PV2)
function C.c22()
    local T = { L = "22 PV2 the strength's bonus" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not (ZeD.BuildingTab and ZeD.BuildingTab.gatherData and BuildLogic) then T.off = true; Q.skip(T.L, "the Build tab or the game's BuildLogic is not loaded"); return end
        RT.worldTab("build")
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        -- the first build recipe whose script has bonus health (the game's own script getters), one whose 0.7 share
        -- has a fraction of a half or more first
        local firstAny = nil
        local function pick(rd)
            local s = H.buildScript(rd)
            if not s then return false end
            local b = 0
            pcall(function() b = s:getBonusHealth() or 0 end)
            if b <= 0 then return false end
            if not firstAny then firstAny = { rd = rd, s = s } end
            local f = b * 0.7 - math.floor(b * 0.7)
            return f >= 0.5
        end
        local rd, n = H.findRd(ZeD.BuildingTab, nil, pick, 80)
        if not rd and firstAny then rd = firstAny.rd end
        if not rd then T.off = true; Q.skip(T.L, "no build recipe of the " .. tostring(n) .. " listed has bonus health"); return end
        T.rd = rd
        T.s = H.buildScript(rd)
        H.note(T.L .. ": the recipe " .. tostring(rd.entry.name) .. " (\"" .. tostring(rd.entry.displayName) .. "\")")
    end)
    for i, v in ipairs({ 1, 2 }) do
        H.step(2, function()
            if T.off then return end
            H.closeCard()
            H.setCbp(v)
        end)
        H.previewQ(T, "build")
        H.step(2, function()
            if T.off then return end
            local lead, shown, s, ds = H.strength()
            local g = H.gameHealth(T.rd, T.s)
            Q.check(lead ~= nil and shown and lead == math.floor(g.total), T.L .. ": at Construction Bonus Points " .. v .. " the card's strength is the game's build health",
                "the card \"" .. tostring(s) .. "\" (drawn " .. tostring(shown) .. (ds and ds ~= s and (" as \"" .. ds .. "\", cut to the room beside its label") or "")
                .. "); the game's ISBuildIsoEntity " .. g.text .. ", the thing built gets " .. math.floor(g.total)
                .. (shown and "" or ("; the card's words with the number: " .. H.textsLike(tostring(lead or "?"), 6))))
        end)
        if i == 1 then H.shot("ocl_preview_" .. H.sizeTag(), "the recipe preview on a build with bonus health", function() return not T.off end) end
    end
    H.step(2, function()
        H.closeCard()
        H.setCbp(S.found.cbp)
        RT.worldTab("loot")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 23. a skill gained while open (PV3, OC3)
function C.c23()
    local T = { L = "23 PV3 a Carpentry level gained while open" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not (ZeD.BuildingTab and ZeD.BuildingTab.gatherData and BuildLogic) then T.off = true; Q.skip(T.L, "the Build tab or the game's BuildLogic is not loaded"); return end
        RT.worldTab("build")
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        local rd = H.findRd(ZeD.BuildingTab, { "LogFence", "LogWall", "WoodenFence" }, function(r)
            local s = H.buildScript(r)
            if not s then return false end
            local sb = 0
            pcall(function() sb = s:getSkillBaseHealth() or 0 end)
            return sb > 0
        end, 160)
        if not rd then T.off = true; Q.skip(T.L, "no build recipe grows with a skill"); return end
        T.rd = rd
        T.s = H.buildScript(rd)
        H.perkSet("Woodwork", 2)
    end)
    H.previewQ(T, "build")
    H.step(2, function()
        if T.off then return end
        T.lead0 = H.strength()
        T.g0 = H.gameHealth(T.rd, T.s)
        H.perkSet("Woodwork", 4)
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        local lead1, shown = H.strength()
        local g1 = H.gameHealth(T.rd, T.s)
        Q.check(lead1 ~= nil and lead1 == math.floor(g1.total), T.L .. ": Carpentry 2 to 4 while the card is open: its strength follows the game's build health",
            "the card " .. tostring(T.lead0) .. " -> " .. tostring(lead1) .. " (drawn " .. tostring(shown) .. "); the game's " .. T.g0.text .. " -> " .. g1.text
            .. " (" .. tostring(T.rd.entry.name) .. ")")
        H.padOn()
        T.onFace = H.focusCard("oc:faceR") or H.focusCard("oc:verb:go") or H.focusCard("oc:back")
    end)
    H.tapB(function() return not T.off and T.onFace end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        Q.check(H.kind() == nil, T.L .. " (OC3): B on the preview card closes it with no question", "card " .. tostring(H.kind()) .. ", focus " .. tostring(H.focusedId()))
        H.padOff()
        H.perkSet("Woodwork", S.found.lvl.Woodwork)
        RT.worldTab("loot")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 24. the craft preview's cost (PV1)
function C.c24()
    local T = { L = "24 PV1 the craft preview's frames" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not (ZeD.CraftingTab and ZeD.CraftingTab.gatherData) then T.off = true; Q.skip(T.L, "the Craft tab is not loaded"); return end
        RT.worldTab("craft")
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        local rd = H.findRd(ZeD.CraftingTab, nil, function(r) return r.entry ~= nil and r.entry.outputDefs ~= nil end, 40)
        if not rd then T.off = true; Q.skip(T.L, "no craft recipe listed"); return end
        T.rd = rd
        local st = RT.ww()._craftState
        if st and st.selected ~= rd.entry.name then H.zcall(function() ZeD.CraftingCore.openCraft(st, rd.entry.name) end) end
    end)
    Q.waitMs(1000)
    H.step(1, function() T.n0 = 0 end)
    H.wait(3000, function() T.n0 = (T.n0 or 0) + 1; return false end, function() end)
    H.previewQ(T, "craft")
    H.step(1, function() T.n1 = 0 end)
    H.wait(3000, function() T.n1 = (T.n1 or 0) + 1; return false end, function() end)
    H.step(2, function()
        if T.off then return end
        H.note(T.L .. ": frames drawn in 3 s with the Craft tab alone " .. tostring(T.n0) .. ", with the preview card on " .. tostring(T.rd.entry.name) .. " " .. tostring(T.n1)
            .. " (the card works the item out every 250 ms: a new item each time)")
        H.closeCard()
        RT.worldTab("loot")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 25. a stale verb (PV4)
function C.c25()
    local T = { L = "25 PV4 Craft with the parts gone" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not (ZeD.CraftingTab and ZeD.CraftingTab.gatherData) then T.off = true; Q.skip(T.L, "the Craft tab is not loaded"); return end
        H.give("Base.Sheet")
        H.give("Base.Plank")
        H.give("Base.Saw")
        RT.worldTab("craft")
    end)
    Q.waitMs(1200)
    H.step(2, function()
        if T.off then return end
        local rd = H.findRd(ZeD.CraftingTab, nil, function(r) return r.status == "craftable" end, 400)
        if not rd then T.off = true; Q.skip(T.L, "no recipe is craftable with what he carries (a sheet, a plank, a saw given)"); return end
        T.rd = rd
    end)
    H.previewQ(T, "craft")
    H.step(2, function()
        if T.off then return end
        local t = H.ct()
        T.lit = t and t.verbs and t.verbs[1] and t.verbs[1].enabled
        if not T.lit then T.off = true; Q.skip(T.L, "the card's Craft is grey for " .. tostring(T.rd.entry.name)); return end
        T.x, T.y = H.zAbs("oc:verb:go")
        if not T.x then T.off = true; Q.skip(T.L, "the card's Craft button is not drawn"); return end
        T.have = {}
        for _, it in ipairs(H.all()) do T.have[it] = true end
        -- every loose thing he carries goes out of reach, and Craft is pressed in the same frame
        T.stashAt = #(S.stash or {})
        H.stashTypes(nil)
        for _, it in ipairs(S.caseMade) do H.removeItem(it) end
        S.qLog = {}
        H.qWatchOn()
        H.ptrOn(T.x, T.y, true)
    end)
    H.step(1, function() if not T.off then H.ptrOn(T.x, T.y, false) end end)
    H.step(2, function() H.ptrOff() end)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        local made = {}
        for _, it in ipairs(H.all()) do if not T.have[it] then made[#made + 1] = H.ft(it) end end
        Q.check(#made == 0, T.L .. ": Craft pressed with the parts gone since the card's last reading makes nothing (the game's craft refuses)",
            "the recipe " .. tostring(T.rd.entry.name) .. ", Craft lit at the press " .. tostring(T.lit) .. "; the game was handed " .. H.list(S.qLog, 8) .. "; new things " .. H.list(made, 8))
        H.qWatchOff()
        H.unstashFrom(T.stashAt or 0)
        H.closeCard()
        RT.worldTab("loot")
    end)
    -- (a time-out above still gives his things back)
    H.step(1, function() if T.stashAt then H.unstashFrom(T.stashAt) end end)
    H.caseEnd(T.L)
end

-- ===================================================================== 26. the held-in window (OC4)
function C.c26one(T, kind, open)
    H.step(2, function()
        if T.off then return end
        H.closeCard()
        RT.worldTab("loot")
        H.heldOn()
        local w = RT.ww()
        if w and not w._invDrawerOpen then w._invDrawerOpen = true end
        local ok, why = pcall(open)
        if not ok then T.skipK = tostring(why) end
    end)
    H.waitCard(T, kind)
    H.step(2, function()
        if T.skipK then H.note(T.L .. ": the " .. kind .. " card's open threw: " .. T.skipK); T.skipK = nil end
        if T.off then T.off = nil; return end
        local w = RT.ww()
        local ww, cap, drawer = math.floor(w:getWidth()), math.floor(w._maxWinW or 0), H.drawerW()
        local strips = H.px(36) * 2
        local inv = ww - strips - drawer
        local folded = not w._invDrawerOpen
        local half = math.abs(drawer - H.px(220)) <= 1
        -- (Hermit, Nov 26 2026: the hook, placement, farm, fire, power and hutch cards stay full width held in; only the
        -- kinds laid out for the half card (def.halfOk) give way)
        local def = nil
        pcall(function() def = ZeD.ObjectCards.kinds[kind] end)
        if def and not def.halfOk then
            H.note(T.L .. ": the " .. kind .. " card stays full width held in, as Hermit picked (window " .. ww .. " px, the inventory beside it " .. inv .. " px)")
            return
        end
        Q.check(ww <= cap + 1 and (folded or inv >= H.px(180) - 1), T.L .. ": the " .. kind .. " card in the held-in window: the window within its cap, the inventory beside the card 180 units or folded",
            "window " .. ww .. " px (cap " .. cap .. "), the card's drawer " .. drawer .. " (" .. (half and "half" or "full") .. "), the inventory beside it "
            .. inv .. " px (180 units is " .. math.floor(H.px(180)) .. "), folded " .. tostring(folded))
    end)
    H.shot("ocl_" .. kind .. "_held_" .. H.sizeTag(), "the " .. kind .. " card in the held-in World window (its cap at 640 units)")
    H.step(2, function() H.closeCard() end)
end
function C.c26()
    local T = { L = "26 OC4 the held-in window" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.m = H.mkMachine("IsoClothingWasher", H.spot({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }))
        T.it, T.wi = H.lay(H.spot(), "Base.Hammer")
        T.c = H.mkLockCrate(H.spot(), 0, nil)
        T.trk = { type = "footstep", dir = "N", animal = "deer", fresh = getText("IGUI_AnimalTracks_Time_Recent") }
        T.item = C.trackItem(T)
    end)
    C.c26one(T, "laundry", function() if T.m then ZeD.ObjectCardLaundry.open(S.p, T.m.obj) end end)
    C.c26one(T, "medic", function() H.medOpen() end)
    C.c26one(T, "place3d", function() if T.wi then S.OC.open(S.p, "place3d", T.wi) end end)
    C.c26one(T, "track", function() S.OC.open(S.p, "track", T.item) end)
    C.c26one(T, "lock", function() if T.c then ZeD.ObjectCardLock.openFor(S.p, T.c.obj, false) end end)
    H.step(2, function()
        H.note(T.L .. ": the cards here were opened by ZeD's own open calls (a layout reading: the game's way in is checked in the cases above)")
        H.heldBack()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 27. seated (OC8), run last
function C.c27()
    local T = { L = "27 OC8 the recipe preview in a car" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY) then
            T.off = true
            Q.skip(T.L, "the prelude's car helpers are not loaded (zedqa_prelude.lua runs first)")
            return
        end
        ZEDQA_CAR_WAIT("Base.CarNormal", "ocl_tab", function(v)
            S.car = v
            S.cars[#S.cars + 1] = v
            H.keep(ZEDQA_CAR_PREP(v))
            T.ready = true
        end, function(why) T.why = why or "no ready car" end, 6000)
    end)
    H.wait(45000, function() return T.off or T.ready or T.why ~= nil end, function()
        if T.off then return end
        if not T.ready then T.off = true; Q.skip(T.L, "no car: " .. tostring(T.why)); return end
        local ok, why = ZEDQA_CAR_ENTER(S.car, 0)
        if not ok then T.off = true; Q.skip(T.L, "he could not sit in the car: " .. tostring(why)); return end
    end)
    Q.waitMs(1000)
    H.step(2, function()
        if T.off then return end
        if not (ZeD.CraftingTab and ZeD.CraftingTab.gatherData) then T.off = true; Q.skip(T.L, "the Craft tab is not loaded"); return end
        H.wwOpen()
        T.rd = H.findRd(ZeD.CraftingTab, nil, function(r) return r.entry ~= nil end, 20)
        if not T.rd then T.off = true; Q.skip(T.L, "no craft recipe listed"); return end
    end)
    H.previewQ(T, "craft", true)
    Q.waitMs(1500)
    H.step(2, function()
        local w = RT.ww()
        local tab = w ~= nil and w._activeTab == "craft"
        local open = H.kind() == "preview"
        local seated = S.p:getVehicle() ~= nil
        -- (the first run: opened by the icon false, up before its first frame false: nothing opened at all. Since QA
        -- FL5 OC.open says no to a kind without vehicleOk while he is seated, so the open is refused before OC.tick
        -- could close it; the detail names which of the two it was. With no recipe drawn on the tab the open says no
        -- on foot too: that is this script's setup, a skip, not ZeD's answer.)
        local def = S.OC.kinds and S.OC.kinds.preview
        local vok = def ~= nil and def.vehicleOk == true
        if T.ready and seated and T.rd and tab and not open and not T.viaIcon and not T.rdReady then
            Q.skip(T.L .. ": the recipe preview seated", "the Craft tab had drawn no recipe to open the preview on (state._rdLast unset): the open could not be asked")
        elseif T.ready and seated and T.rd then
            local how = "not opened"
            if T.viaIcon or T.openedNow then how = open and "opened and still open" or "opened, then closed (OC.tick: in a vehicle)"
            elseif T.openRet == false then how = "refused at open (OC.open says no seated to a kind without vehicleOk, QA FL5)" end
            Q.check(not (tab and not open), T.L .. ": seated in a parked car the recipe preview stays open over the Craft tab, which works there",
                "seated " .. tostring(seated) .. ", the Craft tab " .. tostring(tab) .. ", the recipe drawn " .. tostring(T.rdReady) .. ", the preview kind vehicleOk " .. tostring(vok)
                .. "; the card " .. how .. " (by the icon " .. tostring(T.viaIcon) .. ", by its own handler " .. tostring(T.openRet) .. ", up before its first frame "
                .. tostring(T.openedNow) .. ", open 1.5 s later " .. tostring(open) .. ")")
        end
        T.off = nil
        H.closeCard()
        RT.worldTab("loot")
        pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    end)
    H.step(6, function()
        for _, v in ipairs(S.cars) do pcall(ZEDQA_CAR_AWAY, v) end
    end)
    Q.waitMs(1500)
    H.caseEnd(T.L)
end

-- ===================================================================== the suspicions single player cannot stage
function C.skips()
    H.step(1, function()
        Q.skip("LK2 a right code read as wrong, a second Lock on a server", "a server: the code comes off in the action's complete() on the server; single player runs it in the client's own perform")
        Q.skip("LK3 another player's unlock read as his", "a second player at one crate (a server or split screen)")
        Q.skip("LA6 two players' wash phases", "two players at one machine (a server)")
        Q.skip("PL4 the item taken while the card is open, on a server", "a server and a second client")
        Q.skip("TD1 B ends the trade for both players", "a trade needs a second player (a server)")
        Q.skip("TD2 split screen on a server reads the first player's window", "split screen on a server")
        Q.skip("TD3 an offered item re-sent by the server", "a server's container update mid-trade")
        Q.skip("TD4 a trade the player cannot see holds him", "a trade needs a second player (a server)")
        Q.skip("the trade card's picture ocl_trade", "no trade opens without a second player")
        Q.skip("MD3 the stream outlives the card in split screen", "two checks need split screen (a second local player)")
        Q.skip("LK9 doors, windows, keys, lockpicks and barricades", "a scope note: no ZeD surface to sweep; the game's own menus stand")
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
    H.ptrOff()
    H.padOff()
    H.qWatchOff()
    H.ctxShut()
    H.closeCard()
    H.hiddenBack()
    H.heldBack()
    pcall(function() Events.OnPreUIDraw.Remove(S.keeper) end)
    S.allowRoll = nil
    H.wrapOff()
    pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    for _, c in ipairs(S.objs) do H.rmObj(c) end
    for _, it in ipairs(S.made) do H.removeItem(it) end
    H.bodyBack()
    H.setCbp(f.cbp)
    pcall(function() ISHealthPanel.cheat = f.hcheat end)
    pcall(function() JoypadState.players[S.pn + 1] = f.joy end)
    local LD = ZeD.ObjectCardLaundry
    for _, k in ipairs(S.ldKeys) do if LD and LD._run then LD._run[k] = nil end end
    pcall(function() local MC = ZeD.Medic; if MC.current and MC.current.patient == S.patient then MC.current = nil end end)
    S.xpGrew, S.xpLeft = H.xpBack()
    if f.recorded then
        pcall(function() S.p:setTimedActionInstantCheat(f.inst and true or false) end)
        pcall(function() if f.tod then getGameTime():setTimeOfDay(f.tod) end end)
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
        H.hands()
        H.home()
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "ocl_tab") end
        local w = RT.ww()
        if w then w._maxWinW = f.maxW end
        H.lootRefresh()
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then return end
        pcall(ZeD_CharacterWindow.openTab, S.pn, f.ctab or "loot")
        if f.wtab then RT.worldTab(f.wtab) else RT.worldTab("loot") end
        local w = RT.ww()
        if w and f.invOpen ~= nil then w._invDrawerOpen = f.invOpen end
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
        Q.check(#left == 0, "put back: every thing the run gave is gone (padlocks, bags, keys, bandages, hammers, the shirt)", #S.made .. " given; left " .. H.list(left, 8))
        local extra = {}
        for _, it in ipairs(H.all()) do if not f.inv0[it] then extra[#extra + 1] = H.ft(it) end end
        Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (nothing made left, his set-aside things back)",
            "new " .. H.list(extra, 8) .. "; " .. tostring(S.swept) .. " swept, " .. tostring(S.floorSwept) .. " off the floor, " .. tostring(S.refilled)
            .. " of his own used things given again, " .. tostring(S.lost) .. " set-aside things not given back")
        local objs = {}
        for _, c in ipairs(S.objs) do if H.objLeft(c) then objs[#objs + 1] = c.what end end
        Q.check(#objs == 0, "put back: every object laid is gone (crates, the wall, the machines, the generators)", #S.objs .. " laid; left " .. H.list(objs, 6))
        local hurt = {}
        for _, rec in ipairs(S.parts) do
            local h = H.bpHealth(rec.bp)
            if H.hurt(rec.bp) or (rec.health and h and math.abs(h - rec.health) > 1) then hurt[#hurt + 1] = rec.nm .. " health " .. H.n1(h) end
        end
        Q.check(#hurt == 0 and S.p:isGodMod() == (f.god == true) and S.p:isInvincible() == (f.invinc == true),
            "put back: his body as found (every staged wound and bandage off), god mode and invincible as found", #S.parts .. " parts used; left " .. H.list(hurt))
        local lvlLeft = 0
        pcall(function() for _, r in ipairs(S.xp) do if S.p:getPerkLevel(r.perk) ~= r.lvl then lvlLeft = lvlLeft + 1 end end end)
        if S.xpLeftText then H.note("put back: XP drift left (levels checked): " .. S.xpLeftText) end
        Q.check(lvlLeft == 0, "put back: every skill level as found (First Aid, Carpentry, Tracking)", tostring(S.xpGrew) .. " skills changed, " .. lvlLeft .. " not at their level")
        Q.check(H.cbp() == f.cbp and H.optVal(ZeD.Settings and ZeD.Settings.hiddenActionsOption) == f.hiddenIdx and ISHealthPanel.cheat == f.hcheat,
            "put back: the sandbox's Construction Bonus Points, the hidden-actions setting and the health panel cheat as found",
            "points " .. tostring(H.cbp()) .. " (found " .. tostring(f.cbp) .. "), hidden " .. H.hiddenNow())
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and S.p:getVehicle() == nil and H.qlen() == 0 and getGameSpeed() == 1,
            "put back: he stands where he stood, on foot, no action queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
        local w = RT.ww()
        local jp = nil
        pcall(function() jp = JoypadState.players[S.pn + 1] end)
        Q.check(ZeD.currentBase == f.base and ZeD.currentSize == f.size and H.lockFound() == (S.lockWas or H.lockFound()) and S.mouse0 == nil
            and S.back.maxW == nil and (w == nil or w._maxWinW == f.maxW) and H.wrapped() and S.qw0 == nil and jp == f.joy,
            "put back: the theme, the text size, the input lock, the width cap, the mouse functions, the draw and queue watchers and the pad state as found",
            tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", lock " .. H.lockFound() .. ", width cap " .. tostring(w and w._maxWinW))
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught" .. (S.zerr and (": " .. S.zerr) or ""))
        if S.cardErrs then Q.check(false, "the object card drew without an error", S.cardErrs .. " times; last " .. tostring(S.cardErrLast)) end
        local e1 = H.errN()
        if S.err0 and e1 then
            -- every case window was split at its end; the last stretch (put back) is split here
            local other, own, first = H.errSplit(S.e0 or S.err0, e1)
            if own > 0 then H.note("put back: TEST FAULT: " .. own .. " Lua error entries thrown in ocl_tab's own code: " .. tostring(first)) end
            local ownAll = (S.ownErrs or 0) + own
            local notOurs = (e1 - S.err0) - ownAll
            Q.check(notOurs == 0, "the object card run ran with no Lua error", notOurs .. " new"
                .. ((ownAll > 0) and (" (" .. ownAll .. " more in ocl_tab's own code: a test fault)") or ""))
            if other > 0 then H.note("put back: " .. other .. " of those during the put-back itself") end
        else Q.skip("the object card run's Lua error count", "the game's Lua error count cannot be read here") end
        H.note("pictures taken: " .. H.list(S.shots, 20))
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
        if f.ww == false and RT.ww() then pcall(ZeD_WorldWindow.close, S.pn) end
    end)
end

-- ===================================================================== the run
S.setup()
C.c1()
C.c2()
C.c3()
C.c4()
C.c5()
C.c6()
C.c7()
C.c8()
C.c9()
C.c10()
C.c11()
C.c12()
C.c13()
C.c14()
C.c15()
C.c16()
C.c17()
C.c18()
C.c19()
C.c20()
C.c21()
C.c22()
C.c23()
C.c24()
C.c25()
C.c26()
C.skips()
C.c27()
S.buildPutBack()
Q.start()
