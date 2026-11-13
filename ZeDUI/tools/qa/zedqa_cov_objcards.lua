-- ZeDUI/tools/qa/zedqa_cov_objcards.lua  (Nov 12 2026, QA coverage: ZeDUI/qa/AUDIT_DESIGN_AND_COVERAGE_20261111.md
-- Table B, the object cards that were only photographed or never checked). In game on the ZeD-QA save only
-- (Saves/Sandbox/ZeD-QA: on any other save it stops before it moves, reads or stages anything), the character at the
-- QA home (the drag strip, 925,13040; the prelude puts it there). Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep
-- console.txt for "ZEDQA cov_objcards". Manifest: cov_objcards.txt (also in regression.txt).
-- Every check prints "PASS <what>" or "FAIL <what> (<got> vs <want>)", read from ZeD's own objects: the open card's
-- entry (its def and target t: t.d is the model the body draws, t.verbs the verb row), the def's own header calls
-- (title, pill), the card's zones (a press here calls the zone's run, exactly what the mouse's release over it
-- (ZeD_ObjectCard:_pointer) and the pad's A (buildFocusables) call), the World window's controller ring (where the pad
-- lands in the card) and what a press changed in the world. Each card is opened through the game's own entry point
-- that ZeD hooks, not by ZeD's open call; a hook that is not in place stops its card with a FAIL, and safe mode stops
-- the run (the game's own window would open instead, on the script's things). Ends with "RESULT", "fails <n>" and
-- DONE. Screenshots/zqa_ocv_<card>.png, one "SHOT" line each.
--
-- HOW A PRESS IS JUDGED: a verb's button, the question's two buttons and the close key run the card's own press, which
-- runs the verb inside a pcall of its own and returns early for a disabled verb (ZeD_ObjectCard:press, the band's
-- buttons, close), so pressing one of them comes back ok whenever the button was drawn. Those checks read what the
-- press did instead: the game's action queued (ISTimedActionQueue.hasActionType), the question opened or shut, the card
-- closed, moved or jumped. A row's own button (Add, Light, Take, Sow, Into, a bird's Info) runs its code with nothing
-- round it: a throw there fails its check. A check that a button or a row is absent is made only while the card is on
-- screen and drawing (H.live): a card that does not draw keeps the zones of its last frame (or of the card before it,
-- until its first frame). For the whole run both windows are held down (H.keepDown, as zedqa_b8_cards.lua does): an
-- unpinned window rolls up 2 s after the pointer leaves it, the card in its drawer stops drawing, and with it the card's
-- upkeep (data, leash, validity: OC.tick runs in the card's prerender).
--
-- WHAT IT CHECKS
--   track      (ObjectCardTrack) the game's Inspect Track action (ISInspectAnimalTrackAction) opens the card; the
--              title is the track's type, the direction, the Tracking level, vanilla's species rule (the species
--              only from Tracking 5, else the track size; "???" for a type the game does not know), the tag is the
--              freshness, no verbs, no leash for a carried track (open and drawing 9 squares off), the close key
--              closes it. (The drag strip has no animal tracks and the game makes them only from a virtual herd: the
--              track is a stand-in for the game's track item, answering the five calls the card makes. The card
--              itself is ZeD's, untouched.)
--   placement  (ObjectCardPlacement) the game's Extended placement on a hammer on the ground opens the card; it
--              starts from the item's place and turn; Done is the main verb; the pad lands on Movement X (the card
--              zone's stop in the World window's controller ring); +0.01 X, +15 Z and the D-pad on the Y slider move
--              the item by those steps (and the gizmo follows the group); Z never goes under the floor; -15 from 5
--              degrees wraps to 350; Revert puts it all back; Done closes the card and keeps the new place; opened
--              again, the card closes past vanilla's 3 squares.
--   fluid      (ObjectCardFluid) a bottle's Pour (ISFluidContainerMenu.showUI) opens the card with it on the left;
--              the rows: From on it, an empty bottle tagged Empty and taking the pour, a full one tagged Full and
--              refusing it (the engine's reason); the tag names the liquid; the pad lands on an Into button; no Pour
--              until the right side is set; Into sets it; Max pour is the smaller of what is in and the room; 1/2 and
--              the slider's D-pad set the share; Pour (the game's action) moves that much; Switch swaps; Empty asks
--              first with the litres, Cancel keeps it, the question's Empty queues the game's empty, which empties it.
--   campfire   (ObjectCardFire) the campfire's Info opens the card; a new one reads no fuel and Out; no Put out on a
--              dead fire; Light waits with nothing to light with; Take apart asks; carried planks and paper become
--              rows; with a lighter Light is the main verb; Add fuel jumps to its list; a plank row adds its burn time;
--              the paper row lights it (the tag says Burning, Put out shows, Light goes); Put out queues the game's
--              action, which puts it out; Take apart asks (red), Cancel keeps it, yes queues the game's action, which
--              takes it apart, and the card closes with it.
--   trough     (ObjectCardTrough) Feeding Trough Info opens the card; a new trough is Empty; the zone line names the
--              animal zone it stands in (one drawn over it for the run when it stands in none); water in it: the
--              litres, the tag Water, no Add food, Add water the main verb, Empty asks with the litres, its Empty
--              queues the game's empty, which empties it; Add water opens the fluid card aimed at the trough; feed in
--              it: the tag Food, the rows, no Add water or Empty; Take moves the feed to the bags; carried feed is an
--              Add row, Add food jumps there, Add moves it in.
--   hutch      (ObjectCardHutch) the hen house's Info opens the card; both doors shut: the tag Shut, boxes and
--              perches covered, Open door is the main verb, no Grab eggs; Open hatch (the game's action) uncovers the
--              boxes only. A hen is set on an egg in a box then (a sitting hen lays and leaves her box 350 to 600 game
--              ticks after she sits, IsoHutch.addAnimalInNestBox: 7 to 12 s, so she sits down right before the boxes
--              are read) and the card is opened again through the Info: the egg count; Grab on the box with eggs,
--              none under the sitting hen; Grab eggs is the main verb and the pad lands on the box with eggs; Grab eggs
--              (the game's action) takes the free box's eggs and leaves the sitting hen's; Open door shows the
--              perches, each bird with Grab and Info (in daytime hens walk out of an open hen house one by one,
--              IsoHutch.checkAnimalExitHutch: the list is read as a range); a bird's Info shows it in the Animals tab.
--              Then the door is shut again, the hens that walked out are taken away, the World window goes back to
--              its tab and the card opens again: Clean waits and names water and a mop, is live with both, queues the
--              game's cleaning, which cleans the floor, and shows only while the floor is dirty.
--   farm plot  (ObjectCardFarm) the plot's Info opens the card; plowed: the tag Empty, only Sow, waiting; the
--              garden strip and the header arrows list both plots; carried seeds are a Sow row; Sow is the main verb
--              and jumps to it; the row sows (the game's action) and the card stays on the plot; water set to 20:
--              Parched (vanilla's band, 25 and under: the farming system's ten-minute tick moves the level, rain by up
--              to 30); Water waits, is live with water carried, queues the game's watering, which raises the water;
--              Dig up asks naming the crop and Cancel keeps it; > steps to the next plot, a garden plot picks it, < on
--              the first wraps to the last; the plot dug up from under the card: it moves to one still in reach
--              (keepOnLoss).
--   cleanup    everything staged is gone at the end: the script's hens out of the hen house and the world, and
--              nothing lies on the staged squares.
-- THE LEDGER: everything the script gives, stages or changes is put back at the end, and also on a time-out: given
-- items and anything new on the character (eggs, stones, feed) taken away; the character's own fire starters, planks,
-- paper, seeds, feed bags, water and petrol containers and mops set aside first (so the game's actions use the
-- script's things, never the character's) and given back to the container they came from; the hammer, the campfire,
-- the trough, the hen house (its hens taken off the boxes and the perches first: the house's removal would release
-- them into the world and drop its eggs), its hens and eggs, the plots and the zone removed; anything left lying on the
-- staged squares (all clear at the start) swept up; hands, god mode, instant actions, body stiffness (sowing strains
-- the back), the Animals tab's view (and its Back), the World window's tab (through its own tab strip), both windows'
-- roll-up timers and the character's spot as they were. The script's items and hens carry the mod-data mark
-- ZeDQA_spawned.
-- Known leftover: Husbandry XP for the three eggs grabbed (the game's action gives it; there is no safe take-back).
-- Two checks were written against bugs found while reading the code (Kahlua's % truncates: (-1) % 2 is -1), and FAIL
-- until the build fixes them:
--   "farm: < on the first plot wraps to the last": OC.browse (ObjectCards.lua) steps back from the first object to
--     index 0, e.t is nil, the press throws and the card closes (every kind with two or more in reach). -debug logs
--     that caught error as a Java exception, so the manifests mark it expected (expect=\.browse\(ObjectCards\.lua:);
--     the script closes the card in the same step, before its next frame would throw again in OC.tick.
--   "placement: -15 from 5 degrees wraps to 350": setAxis (ObjectCardPlacement.lua) keeps -10; the readout says -10
--     and the slider's block sits at 0.
-- Timed actions run with the instant cheat; walks still take their time. About three minutes.

local TAG = "cov_objcards"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local OC = ZeD and ZeD.ObjectCards
local WWm, CWm = ZeD_WorldWindow, ZeD_CharacterWindow
local R = { pass = 0, fail = 0, err = 0 }
local function check(ok, what, got, want)
    if ok then
        R.pass = R.pass + 1
        say("PASS " .. what)
    else
        R.fail = R.fail + 1
        say("FAIL " .. what .. " (" .. tostring(got) .. " vs " .. tostring(want) .. ")")
    end
    return ok and true or false
end
local function shot(n)
    local f = "zqa_ocv_" .. n .. ".png"
    pcall(function() getCore():TakeFullScreenshot(f) end)
    say("SHOT " .. f)
end
local H = {}
local S = { off = {}, res = {}, spots = {} }
local LG = { added = {}, taken = {}, had = {}, plots = {}, plowDay = {}, fires = {}, zones = {}, hens = {},
             worldItems = {}, stiff = {}, kept = {}, clearSqs = {}, gone = {}, done = false }

-- ===============================================================================================================
-- HELPERS (all on H, so every step reaches them by a table lookup at run time)
-- ===============================================================================================================
function H.W() return WWm and WWm.getWindow and WWm.getWindow() or nil end
function H.CW() return CWm and CWm.getWindow and CWm.getWindow() or nil end
function H.card() return WWm and WWm.getObjectCard and WWm.getObjectCard() or nil end
function H.e() local c = H.card(); return c and c.entry or nil end
function H.t() local e = H.e(); return e and e.t or nil end
function H.d() local t = H.t(); return t and t.d or nil end
function H.kind() local e = H.e(); return e and e.def and e.def.id or nil end
function H.confirm() local c = H.card(); return c and c._confirm or nil end
function H.zone(fid)
    local c = H.card()
    for _, z in ipairs(c and c._zones or {}) do if z.fid == fid then return z end end
    return nil
end
function H.zonesLike(prefix)
    local out, c = {}, H.card()
    for _, z in ipairs(c and c._zones or {}) do
        if z.fid and string.sub(z.fid, 1, #prefix) == prefix then out[#out + 1] = z.fid end
    end
    return out
end
-- A zone's action, as the mouse's release over it and the pad's A run it. Returns ok, error words. (For a verb, the
-- question's buttons and the close key, ok only says the button was drawn: see HOW A PRESS IS JUDGED.)
function H.press(fid)
    local c, z = H.card(), H.zone(fid)
    if not (c and z) then return false, "no zone " .. tostring(fid) end
    if not z.run then return false, "zone " .. tostring(fid) .. " has no action" end
    local ok, err = pcall(z.run, c, c:player())
    if not ok then return false, tostring(err) end
    return true, nil
end
-- The card is on screen and drawing (its prerender runs OC.tick and stamps the zones each frame): the World window
-- up and not rolled to its title bar, its card drawer and the card shown.
function H.live()
    local w, c = H.W(), H.card()
    if not (w and c) then return false end
    local dr = w._itemDrawerPanel
    return (w:getIsVisible() and not w.windowShaded and (dr == nil or dr:getIsVisible()) and c:getIsVisible()) and true or false
end
-- a button or row absent from a card that is drawing
function H.gone(fid) return H.live() and H.zone(fid) == nil end
-- Where the controller lands in the card: the card zone's stop held in the World window's controller ring (the window
-- moves it to the card's opening focus, card._pendingFocus, once that stop is drawn, and clears the ask); with no ring,
-- the card's ask.
function H.landed()
    local w = H.W()
    for _, z in ipairs(w and w._focusRing or {}) do
        if z.zone == "worldItemCard" then
            local el = z.elements and z.elements[z.focusedElementIdx or 1]
            return el and el.id or nil
        end
    end
    local c = H.card()
    return c and c._pendingFocus or nil
end
-- the game's own timed action of this type in the character's queue (a walk or an equip may come before it)
function H.queued(typ) return ISTimedActionQueue.hasActionType(p, typ) == true end
function H.verb(id)
    local t = H.t()
    for _, v in ipairs(t and t.verbs or {}) do if v.id == id then return v end end
    return nil
end
function H.verbIds()
    local t, ids = H.t(), {}
    for _, v in ipairs(t and t.verbs or {}) do ids[#ids + 1] = tostring(v.id) end
    return table.concat(ids, ",")
end
function H.pill()
    local e = H.e()
    if not (e and e.t and e.def and e.def.pill) then return nil end
    local ok, s = pcall(e.def.pill, e.t)
    return ok and s or nil
end
function H.fresh() local t = H.t(); if t and OC then t._refreshT = OC.REFRESH end end
function H.close() pcall(function() if H.card() then WWm.closeObjectCard() end end) end
function H.queue()
    local q = ISTimedActionQueue.queues and ISTimedActionQueue.queues[p]
    return q and q.queue and #q.queue or 0
end
function H.idle()
    return not ISTimedActionQueue.isPlayerDoingAction(p) and H.queue() == 0
end
function H.put(x, y)
    pcall(function() p:setX(x); p:setY(y); p:setLastX(x); p:setLastY(y) end)
end
function H.home()
    pcall(function() ISTimedActionQueue.clear(p) end)
    if LG.home then H.put(LG.home.x, LG.home.y) end
end
function H.mark(o) pcall(function() o:getModData().ZeDQA_spawned = true end) end
function H.give(full)
    local it = nil
    pcall(function() it = p:getInventory():AddItem(full) end)
    if it then H.mark(it); LG.added[#LG.added + 1] = it end
    if not it then say("could not give " .. tostring(full)) end
    return it
end
-- a given thing taken away now, so a later card does not count it (the ledger skips it at the end)
function H.drop(it)
    if not it then return end
    pcall(function()
        local c = it:getContainer()
        if c then p:removeFromHands(it); c:Remove(it) end
    end)
end
function H.fill(it, fluid)
    pcall(function()
        local fc = it:getFluidContainer()
        fc:Empty()
        if fluid then fc:addFluid(fluid, fc:getCapacity()) end
    end)
end
function H.amt(it)
    local a = -1
    pcall(function() a = it:getFluidContainer():getAmount() end)
    return a
end
function H.count(full)
    local n = 0
    pcall(function() n = p:getInventory():getAllTypeRecurse(full):size() end)
    return n
end
function H.objOn(sq, cls)
    if not sq then return nil end
    local objs = sq:getObjects()
    for k = 0, objs:size() - 1 do
        local o = objs:get(k)
        if instanceof(o, cls) then return o end
    end
    return nil
end
function H.rowWhere(rows, test)
    for i, r in ipairs(rows or {}) do
        local ok, hit = pcall(test, r)
        if ok and hit then return r, i end
    end
    return nil, nil
end
function H.L(v)   -- the fluid card's litres
    v = v or 0
    if v >= 100 then return string.format("%.0f L", v) end
    if v >= 10 then return string.format("%.1f L", v) end
    return string.format("%.2f L", v)
end
function H.f3(v) return string.format("%.3f", tonumber(v) or -1) end
function H.txt(k, fb) local s = getTextOrNull and getTextOrNull(k); return s or fb or k end
function H.breedOf(kind)
    local def = AnimalDefinitions.getDef(kind)
    return def and def:getBreeds():get(0)
end
function H.zoneByName(name)
    local z = nil
    pcall(function() z = DesignationZoneAnimal.getZoneByName(name) end)
    return z
end
function H.campLua(sq)
    local lo = nil
    pcall(function() lo = CCampfireSystem.instance:getLuaObjectOnSquare(sq) end)
    return lo
end
function H.plantLua(sq)
    local lo = nil
    pcall(function() lo = CFarmingSystem.instance:getLuaObjectOnSquare(sq) end)
    return lo
end
-- the plot's water as the farming system holds it (the server's object: the game's watering writes there)
function H.waterLvl()
    local lo = S.plot1 and SFarmingSystem.instance:getLuaObjectOnSquare(S.plot1)
    return lo and lo.waterLvl or nil
end
function H.setWater(v)
    local lo = S.plot1 and SFarmingSystem.instance:getLuaObjectOnSquare(S.plot1)
    if lo then lo.waterLvl = v; lo:saveData() end
end
-- a section that cannot be staged: a FAIL that says what was missing, and the rest of it is skipped
function H.skip(sec, what)
    S.off[sec] = true
    check(false, sec .. ": " .. what, "none", "staged")
end
-- a check the rest of a section stands on: on a FAIL the section is turned off (its FAIL says why)
function H.need(sec, ok, what, got, want)
    check(ok, what, got, want)
    if not ok then S.off[sec] = true end
    return ok and true or false
end
-- ZeD's hook on the game's entry point is in place: else the game's own window would open on the script's things (a
-- vanilla window the run cannot close; the track's stand-in would break it), so that card stops with a FAIL
function H.hooked(sec, flag, entry)
    return H.need(sec, flag == true, sec .. ": ZeD's hook on " .. entry .. " is in place", tostring(flag), "true")
end

-- ---- the windows held down for the run (see the header): unrolled, and the roll-up timers held while _outSince lies
-- ahead (WindowHalves.update). Every tick: a page the game asks for sets _outSince only 500 ms ahead.
function H.hold(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
function H.keepDown() H.hold(H.W()); H.hold(H.CW()) end

-- ---- the Animals tab's view and the World window's tab as they were
function H.atBack()
    local w, a = H.W(), LG.atState
    if not (w and a and ZeD.AnimalsTab and ZeD.AnimalsTab.getState) then return end
    local st = ZeD.AnimalsTab.getState(w)
    st.submode, st.view, st.zoneName, st.animalRef, st.prevView = a.submode, a.view, a.zoneName, a.animalRef, a.prevView
end
-- through the window's own tab strip (ZeD_WorldWindow.openTab replays the strip's click: the drawer, the window's width
-- and the controller's stops follow, as a press does), then its controller ring re-synced
function H.tabBack()
    local w = H.W()
    if not (w and LG.tab0) then return end
    if w._activeTab ~= LG.tab0 then WWm.openTab(0, LG.tab0) end
    if WWm.syncRing then WWm.syncRing(w) end
end

-- ---- the script's hens
function H.perchCount()
    local h, n = S.hutch, 0
    if not h then return 0 end
    for k = 0, h:getMaxAnimals() - 1 do if h:getAnimal(k) then n = n + 1 end end
    return n
end
-- the script's hens out in the loaded world (a hen walks out of an open hen house in daytime; the house's removal
-- releases what is left inside)
function H.hensOut()
    local out = {}
    local list = getCell():getAnimals()
    for k = 0, list:size() - 1 do
        local a = list:get(k)
        for _, mine in ipairs(LG.hens) do if a == mine then out[#out + 1] = a end end
    end
    return out
end
-- a hen taken out of the game, once: off the world and off her square, as the animal scripts do. No removeAnimal(id):
-- in single player a hen made with addAnimal is never registered with AnimalInstanceManager and keeps the default
-- online id 1, which can belong to a real animal of the save (one put down from the inventory or taken out of a
-- trailer), so a lookup by id would delete that animal. No a:remove()/delete() either: removeFromUpdateLists would
-- unregister whatever animal holds id 1.
function H.takeAwayOut(a)
    if LG.gone[a] then return end
    LG.gone[a] = true
    local still = false
    pcall(function() still = getCell():getAnimals():contains(a) end)
    if still then pcall(function() a:removeFromWorld(); a:removeFromSquare() end) end
end

-- ---- open ground: a square with nothing on it but its floor, outdoors, nobody on it
function H.clear(x, y, z, strict)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return false end
    if not sq:isFree(false) or sq:isSolid() or sq:isSolidTrans() then return false end
    if sq:getVehicleContainer() or sq:getRoom() then return false end
    if sq:getWorldObjects():size() > 0 or sq:getMovingObjects():size() > 0 then return false end
    if sq:getSpecialObjects():size() > 0 then return false end
    return sq:getObjects():size() <= (strict and 1 or 3)
end
function H.reserve(x, y, margin)
    for dy = -margin, margin do
        for dx = -margin, margin do S.res[(x + dx) .. "," .. (y + dy)] = true end
    end
end
-- A spot for a footprint fp ({dx, dy} squares off the anchor) rmin..rmax squares from the QA home, all of it open
-- ground and clear of what was spotted before (a square's gap kept round each). The footprint's squares are kept in
-- LG.clearSqs: clear now, anything lying on them at the end is the run's.
function H.spot(fp, rmin, rmax)
    local hx, hy, hz = math.floor(LG.home.x), math.floor(LG.home.y), math.floor(LG.home.z)
    for pass = 1, 2 do
        for r = rmin, rmax do
            for dy = -r, r do
                for dx = -r, r do
                    if math.max(math.abs(dx), math.abs(dy)) == r then
                        local x, y, good = hx + dx, hy + dy, true
                        for _, o in ipairs(fp) do
                            if good and (S.res[(x + o[1]) .. "," .. (y + o[2])] or not H.clear(x + o[1], y + o[2], hz, pass == 1)) then
                                good = false
                            end
                        end
                        if good then
                            for _, o in ipairs(fp) do
                                H.reserve(x + o[1], y + o[2], 1)
                                LG.clearSqs[#LG.clearSqs + 1] = getCell():getGridSquare(x + o[1], y + o[2], hz)
                            end
                            return getCell():getGridSquare(x, y, hz)
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- ---- the character's own things the game's actions would reach for, set aside
S.ASIDE = { ["Base.Plank"] = true, ["Base.SheetPaper2"] = true, ["Base.CarrotSeed"] = true,
            ["Base.AnimalFeedBag"] = true, ["Base.Lighter"] = true, ["Base.Matches"] = true }
function H.asideTest(it)
    if S.ASIDE[it:getFullType()] then return true end
    if it:hasTag(ItemTag.START_FIRE) or it:hasTag(ItemTag.CLEAN_STAINS) then return true end
    local fc = it:getFluidContainer()
    if fc and not fc:isEmpty() and (fc:contains(Fluid.Water) or fc:contains(Fluid.TaintedWater) or fc:contains(Fluid.Petrol)) then
        return true
    end
    return ISFarmingMenu ~= nil and ISFarmingMenu.getWaterUsesInteger(it) > 0
end
function H.setAside()
    -- (every crop's seeds too: the farm card's Sow list reads them all)
    for _, props in pairs(farming_vegetableconf.props) do
        if type(props) == "table" then
            if props.seedName then S.ASIDE[props.seedName] = true end
            for _, s in ipairs(props.seedTypes or {}) do S.ASIDE[s] = true end
        end
    end
    local list = p:getInventory():getAllEvalRecurse(function(it) return H.asideTest(it) == true end)
    local n = 0
    for k = list:size() - 1, 0, -1 do
        local it = list:get(k)
        -- (a worn piece or one hung on the belt stays: taking it off the body is a change of its own)
        local keep = (it:IsClothing() and it:isEquipped()) or (it:getAttachedSlot() > -1)
        local c = it:getContainer()
        if keep or not c then
            LG.kept[#LG.kept + 1] = it:getDisplayName()
        else
            p:removeFromHands(it)
            c:Remove(it)
            LG.taken[#LG.taken + 1] = { item = it, cont = c }
            n = n + 1
        end
    end
    return n
end

-- ---- the ledger: put everything back
-- the hen house's hens out of the game: off the boxes (IsoHutch.tryFindAndRemoveAnimalFromNestBox), off the perches
-- (removeAnimal reads her perch: a sitting hen who has laid moved to one), and every bird the house still holds, so its
-- removal (removeHutch: releaseAllAnimals) has nobody to release into the world
function H.undoHens()
    local h, n = LG.hutch, 0
    local all, seen = {}, {}
    local function take(a)
        if a and not seen[a] and not LG.gone[a] then seen[a] = true; all[#all + 1] = a end
    end
    for _, a in ipairs(LG.hens) do take(a) end
    if h then
        -- (every bird the house still holds: it is the script's house)
        pcall(function()
            for b = 0, h:getMaxNestBox() do take(h:getAnimalInNestBox(b)) end
            for k = 0, h:getMaxAnimals() - 1 do take(h:getAnimal(k)) end
        end)
        for _, a in ipairs(all) do pcall(function() h:tryFindAndRemoveAnimalFromNestBox(a) end) end
        for _, a in ipairs(all) do pcall(function() if a:getHutch() then h:removeAnimal(a) end end) end
    end
    for _, a in ipairs(all) do H.takeAwayOut(a); n = n + 1 end
    return n
end
-- world items on the staged squares (each clear at the start): what a removal dropped (a hen house's eggs, a
-- campfire's contents) or anything else left there
function H.sweepSquares()
    local n = 0
    for _, sq in ipairs(LG.clearSqs) do
        pcall(function()
            local wos = sq:getWorldObjects()
            for k = wos:size() - 1, 0, -1 do
                local wo = wos:get(k)
                sq:transmitRemoveItemFromSquare(wo)
                wo:removeFromWorld(); wo:removeFromSquare()
                n = n + 1
            end
        end)
    end
    return n
end
function H.undoWorld()
    local n = { place = 0, fire = 0, trough = 0, hens = 0, hutch = 0, plots = 0, zones = 0, out = 0, swept = 0 }
    for _, it in ipairs(LG.worldItems) do
        pcall(function()
            local wi = it:getWorldItem()
            if wi then
                local sq = wi:getSquare()
                if sq then sq:transmitRemoveItemFromSquare(wi) end
                wi:removeFromWorld(); wi:removeFromSquare()
                it:setWorldItem(nil)
                n.place = n.place + 1
            end
        end)
    end
    for _, sq in ipairs(LG.fires) do
        pcall(function()
            local lo = SCampfireSystem.instance:getLuaObjectOnSquare(sq)
            if lo then SCampfireSystem.instance:removeCampfire(lo); n.fire = n.fire + 1 end
        end)
    end
    if LG.troughSq then
        pcall(function()
            local lo = SFeedingTroughSystem.instance:getLuaObjectOnSquare(LG.troughSq)
            if lo then lo:removeIsoObject(); n.trough = n.trough + 1 end
        end)
        pcall(function()
            local iso = H.objOn(LG.troughSq, "IsoFeedingTrough")
            if iso then LG.troughSq:transmitRemoveItemFromSquare(iso); n.trough = n.trough + 1 end
        end)
    end
    n.hens = H.undoHens()
    if LG.hutch then
        pcall(function()
            for b = 0, LG.hutch:getMaxNestBox() do
                local nb = LG.hutch:getNestBox(b)
                for _ = 1, 12 do
                    if not nb or nb:getEggsNb() <= 0 then break end
                    nb:removeEgg(0)
                end
            end
        end)
        pcall(function() LG.hutch:removeHutch(); n.hutch = 1 end)
    end
    -- (a hen the house still released on its removal, or one that walked out and was missed)
    local okO, out = pcall(H.hensOut)
    for _, a in ipairs(okO and out or {}) do
        if not LG.gone[a] then H.takeAwayOut(a); n.out = n.out + 1 end
    end
    for k, sq in ipairs(LG.plots) do
        pcall(function()
            local lo = SFarmingSystem.instance:getLuaObjectOnSquare(sq)
            if lo then SFarmingSystem.instance:removePlant(lo); n.plots = n.plots + 1 end
        end)
        pcall(function() sq:getModData().plowDay = LG.plowDay[k] end)
    end
    for _, name in ipairs(LG.zones) do
        for _ = 1, 3 do
            pcall(function()
                local z = H.zoneByName(name)
                if z then DesignationZoneAnimal.removeZone(z, true); n.zones = n.zones + 1 end
            end)
        end
    end
    n.swept = H.sweepSquares()
    return n
end
function H.restore(why)
    if LG.done then return end
    LG.done = true
    -- (the setup never ran: nothing was staged, given or set aside, and nothing of the character's was read)
    if not LG.home then say("restored (" .. tostring(why) .. "): nothing was staged"); return end
    pcall(function() ISTimedActionQueue.clear(p) end)
    H.close()
    local okW, n = pcall(H.undoWorld)
    if not okW then say("ERR putting the world back: " .. tostring(n)); n = {} end
    local gone, swept, back = 0, 0, 0
    -- what was given (newest first), then anything else new on the character, then the set-aside things back
    for k = #LG.added, 1, -1 do
        local it = LG.added[k]
        pcall(function()
            local c = it:getContainer()
            if c then pcall(function() p:removeFromHands(it) end); c:Remove(it); gone = gone + 1 end
        end)
    end
    pcall(function()
        local inv = p:getInventory()
        local items = inv:getItems()
        for k = items:size() - 1, 0, -1 do
            local it = items:get(k)
            if not LG.had[it] then pcall(function() p:removeFromHands(it) end); inv:Remove(it); swept = swept + 1 end
        end
    end)
    for _, t in ipairs(LG.taken) do
        pcall(function() if not t.item:getContainer() then t.cont:AddItem(t.item); back = back + 1 end end)
    end
    pcall(function() if p:getPrimaryHandItem() ~= LG.primary then p:setPrimaryHandItem(LG.primary) end end)
    pcall(function() if p:getSecondaryHandItem() ~= LG.secondary then p:setSecondaryHandItem(LG.secondary) end end)
    pcall(function() p:setTimedActionInstantCheat(LG.instant == true) end)
    pcall(function() p:setGodMod(LG.god == true) end)
    pcall(function()
        local parts = p:getBodyDamage():getBodyParts()
        for k = 0, parts:size() - 1 do if LG.stiff[k] then parts:get(k):setStiffness(LG.stiff[k]) end end
    end)
    pcall(H.atBack)
    pcall(H.tabBack)
    -- (the windows' roll-up timers run again: the hold of H.keepDown let go)
    for _, w in ipairs({ H.W() or false, H.CW() or false }) do if w then w._outSince = nil end end
    H.home()
    pcall(function() if LG.opened and CWm.isOpen() then CWm.toggleBothPaired(0) end end)
    say("restored (" .. tostring(why) .. "): given taken back " .. gone .. ", new things swept " .. swept
        .. ", set aside and given back " .. back .. " of " .. #LG.taken .. "; hammer " .. tostring(n.place)
        .. ", campfire " .. tostring(n.fire) .. ", trough " .. tostring(n.trough) .. ", hens " .. tostring(n.hens)
        .. " (+" .. tostring(n.out) .. " out in the world), hen house " .. tostring(n.hutch) .. ", plots "
        .. tostring(n.plots) .. ", zones " .. tostring(n.zones) .. ", things lying on the staged squares " .. tostring(n.swept))
end
-- what the script staged and is still there
function H.leftovers()
    local left = {}
    for _, sq in ipairs(LG.fires) do if H.campLua(sq) then left[#left + 1] = "campfire" end end
    if LG.troughSq and H.objOn(LG.troughSq, "IsoFeedingTrough") then left[#left + 1] = "trough" end
    if LG.hutchSq and H.objOn(LG.hutchSq, "IsoHutch") then left[#left + 1] = "hen house" end
    local okO, out = pcall(H.hensOut)
    if not okO then left[#left + 1] = "the world's animals unread: " .. tostring(out)
    elseif #out > 0 then left[#left + 1] = #out .. " of the script's hens in the world" end
    for _, sq in ipairs(LG.plots) do if H.plantLua(sq) then left[#left + 1] = "plot" end end
    for _, sq in ipairs(LG.clearSqs) do
        local nw = 0
        pcall(function() nw = sq:getWorldObjects():size() end)
        if nw > 0 then left[#left + 1] = nw .. " thing(s) lying at " .. sq:getX() .. "," .. sq:getY() end
    end
    for _, name in ipairs(LG.zones) do if H.zoneByName(name) then left[#left + 1] = "zone " .. name end end
    for _, it in ipairs(LG.added) do
        local c = nil
        pcall(function() c = it:getContainer() end)
        if c then left[#left + 1] = it:getFullType() end
    end
    pcall(function()
        local items = p:getInventory():getItems()
        for k = 0, items:size() - 1 do
            local it = items:get(k)
            if not LG.had[it] then left[#left + 1] = "new " .. it:getFullType() end
        end
    end)
    for _, t in ipairs(LG.taken) do
        local c = nil
        pcall(function() c = t.item:getContainer() end)
        if not c then left[#left + 1] = "not given back " .. tostring(t.item:getFullType()) end
    end
    return left
end

-- ===============================================================================================================
-- THE PLAN: add(ms, fn) runs fn ms after the step before; waitFor checks cond every tick up to maxMs
-- ===============================================================================================================
local plan, pi, t0, tStart = {}, 1, getTimestampMs(), getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
-- (sec: the section the wait belongs to; a section that could not be staged waits for nothing)
local function waitFor(maxMs, cond, what, sec)
    local tEnd = nil
    plan[#plan + 1] = { ms = 0, wait = true, fn = function()
        if S.dead or (sec and S.off[sec]) then return true end
        tEnd = tEnd or (getTimestampMs() + maxMs)
        local ok, hit = pcall(cond)
        if ok and hit then say("waited for " .. what); tEnd = nil; return true end
        if getTimestampMs() > tEnd then say("gave up waiting for " .. what); tEnd = nil; return true end
        return false
    end }
end

-- 0 SETUP ---------------------------------------------------------------------------------------------------------
add(200, function()
    -- the save first: on any other save nothing is moved, read or staged
    local world = getWorld() and getWorld():getWorld()
    if world ~= "ZeD-QA" then
        S.dead = true
        check(false, "the run is on the ZeD-QA save (the script stages things and moves the character)", world, "ZeD-QA")
        return
    end
    if not (OC and OC.kinds and WWm and CWm) then
        S.dead = true
        check(false, "the object cards are loaded", "missing", "ZeD.ObjectCards")
        return
    end
    -- (safe mode hands every entry point back to the game's own windows)
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then
        S.dead = true
        check(false, "ZeD is out of safe mode (the game's own windows would open on the script's things)", "safe mode", "off")
        return
    end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
    LG.home = { x = p:getX(), y = p:getY(), z = p:getZ() }
    LG.primary, LG.secondary = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    LG.god = p:isGodMod()
    LG.instant = p:isTimedActionInstantCheat()
    local parts = p:getBodyDamage():getBodyParts()
    for k = 0, parts:size() - 1 do LG.stiff[k] = parts:get(k):getStiffness() end
    local all = p:getInventory():getAllEvalRecurse(function(it) return true end)
    for k = 0, all:size() - 1 do LG.had[all:get(k)] = true end
    p:setGodMod(true)
    p:setTimedActionInstantCheat(true)
    local n = H.setAside()
    say("set aside " .. n .. " of the character's own things" .. (#LG.kept > 0 and (" (kept, worn or on the belt: " .. table.concat(LG.kept, ", ") .. ")") or ""))
    -- the spots: the hammer beside the character, then the rest two to four squares off
    local hx, hy = math.floor(LG.home.x), math.floor(LG.home.y)
    S.res[hx .. "," .. hy] = true
    S.spots.place = H.spot({ { 0, 0 } }, 1, 1)
    H.reserve(hx, hy, 1)
    S.spots.fire = H.spot({ { 0, 0 } }, 2, 4)
    S.spots.trough = H.spot({ { 0, 0 } }, 2, 4)
    S.spots.hutch = H.spot({ { 0, 0 }, { 1, 0 }, { 0, -1 }, { 1, -1 }, { 0, 1 } }, 2, 3)
    S.spots.farm = H.spot({ { 0, 0 }, { 1, 0 } }, 2, 4)
    local sp = {}
    for _, k in ipairs({ "place", "fire", "trough", "hutch", "farm" }) do
        local sq = S.spots[k]
        sp[#sp + 1] = k .. " " .. (sq and (sq:getX() .. "," .. sq:getY()) or "none")
    end
    say("home " .. hx .. "," .. hy .. "; spots: " .. table.concat(sp, ", "))
    if not CWm.isOpen() then LG.opened = true; CWm.toggleBothPaired(0) end
    H.keepDown()
end)
add(1500, function()
    if S.dead then return end
    local w = H.W()
    if w then LG.tab0 = w._activeTab end
    if w and ZeD.AnimalsTab and ZeD.AnimalsTab.getState then
        local st = ZeD.AnimalsTab.getState(w)
        LG.atState = { submode = st.submode, view = st.view, zoneName = st.zoneName, animalRef = st.animalRef, prevView = st.prevView }
    end
    check(w ~= nil and w:getIsVisible() and not w.windowShaded, "the World window is open and down", w ~= nil and tostring(w.windowShaded), "false")
    say("World window on the tab " .. tostring(LG.tab0) .. ", pinned " .. tostring(w and w.pinned))
    H.close()
end)

-- 1 ANIMAL TRACKS -------------------------------------------------------------------------------------------------
S.trk = { type = "footstep", dir = "NE", animal = "deer", fresh = "recent" }
S.trkTracks = {
    getTrackType = function() return S.trk.type end,
    getDir = function() return S.trk.dir end,
    getAnimalType = function() return S.trk.animal end,
    getFreshnessString = function() return S.trk.fresh end,
}
S.trkItem = {
    getAnimalTracks = function() return S.trkTracks end,
    getWorldItem = function() return nil end,
    getTex = function() return nil end,
}
add(300, function()
    if S.dead then return end
    H.home()
    if not H.hooked("track", ISInspectAnimalTrackAction and ISInspectAnimalTrackAction._zedCardHooked, "Inspect Track (ISInspectAnimalTrackAction)") then return end
    ISTimedActionQueue.add(ISInspectAnimalTrackAction:new(p, S.trkItem))
end)
waitFor(8000, function() return H.kind() == "track" end, "the track card", "track")
add(500, function()
    if S.dead or S.off.track then return end
    if not H.need("track", H.kind() == "track", "track: Inspect Track (the game's action) opens the track card", H.kind(), "track") then return end
    local t, d = H.t(), H.d()
    if not H.need("track", d ~= nil, "track: the card has its data (its refresh ran)", "nil", "t.d") then return end
    local want = H.txt("IGUI_AnimalTracks_footstep", "footstep")
    local title = H.e().def.title(t)
    check(d.type == want and title == want, "track: the title is the track's type", tostring(d.type) .. " / " .. tostring(title), want)
    check(d.dir == "NE", "track: the way it went is the track's direction", d.dir, "NE")
    local lvl = p:getPerkLevel(Perks.Tracking)
    check(d.level == lvl, "track: reads the character's Tracking level", d.level, lvl)
    local mg = MigrationGroupDefinitions and MigrationGroupDefinitions.deer
    local size = tostring(mg and mg.trackSize)
    local wantSp = (lvl > 4) and H.txt("IGUI_MigrationGroup_deer", "deer") or H.txt("IGUI_MigrationGroup_" .. size, size)
    check(d.species == wantSp and d.speciesKnown == (lvl > 4), "track: the species shows from Tracking 5, the track size below (level " .. lvl .. ")",
        tostring(d.species) .. " known " .. tostring(d.speciesKnown), wantSp .. " known " .. tostring(lvl > 4))
    local pill = H.pill()
    check(pill == OC.cap("recent"), "track: the tag is the freshness", pill, OC.cap("recent"))
    check(#(t.verbs or {}) == 0 and H.live() and #H.zonesLike("oc:verb:") == 0, "track: no verbs drawn",
        #(t.verbs or {}) .. " verbs, live " .. tostring(H.live()), "0, live true")
    shot("track")
    S.trk.animal = "zedqa_nobody"
    H.fresh()
end)
add(600, function()
    if S.dead or S.off.track then return end
    local d = H.d()
    check(d and d.species == "???", "track: an animal the game does not know reads ???", d and d.species, "???")
    H.put(LG.home.x + 9, LG.home.y)
end)
add(900, function()
    if S.dead or S.off.track then return end
    -- (open and drawing: the card's upkeep, leash included, runs every frame it draws)
    check(H.kind() == "track" and H.live(), "track: a carried track's card has no leash (open and drawing 9 squares off)",
        tostring(H.kind()) .. " live " .. tostring(H.live()), "track live true")
    H.home()
    local ok, err = H.press("oc:back")
    check(ok and H.card() == nil, "track: the close key closes the card", err or H.kind(), "nil")
end)

-- 2 PLACEMENT -----------------------------------------------------------------------------------------------------
add(300, function()
    if S.dead then return end
    H.home(); H.close()
    if not H.hooked("placement", ISExtendedPlacementAction and ISExtendedPlacementAction._zedHooked, "Extended placement (ISExtendedPlacementAction)") then return end
    local sq = S.spots.place
    if not sq then H.skip("placement", "a free square beside the character"); return end
    local it = sq:AddWorldInventoryItem("Base.Hammer", 0.5, 0.5, 0)
    if not it then H.skip("placement", "a hammer on the ground"); return end
    H.mark(it)
    LG.worldItems[#LG.worldItems + 1] = it
    LG.placeSq = sq
    S.placeItem, S.wi = it, it:getWorldItem()
    if not S.wi then H.skip("placement", "the hammer's world object"); return end
    ISWorldObjectContextMenu.onExtendedPlacement(S.wi, p)
end)
waitFor(8000, function() return S.off.placement or H.kind() == "place3d" end, "the placement card", "placement")
add(500, function()
    if S.dead or S.off.placement then return end
    if not H.need("placement", H.kind() == "place3d", "placement: Extended placement (the game's action) opens the placement card", H.kind(), "place3d") then return end
    local t = H.t()
    if not H.need("placement", t ~= nil and t.orig ~= nil and t.d ~= nil, "placement: the card has its start and its data", tostring(t and t.orig), "t.orig, t.d") then return end
    local wi, it, o = S.wi, S.placeItem, t.orig
    local same = math.abs(o.mx - wi:getOffX()) < 0.002 and math.abs(o.my - wi:getOffY()) < 0.002
        and math.abs(o.mz - wi:getOffZ()) < 0.002 and math.abs(o.rz - it:getWorldZRotation()) < 0.002
        and math.abs(o.rx - it:getWorldXRotation()) < 0.002 and math.abs(o.ry - it:getWorldYRotation()) < 0.002
    check(same, "placement: the card starts from the item's place and turn", H.f3(o.mx) .. "," .. H.f3(o.rz), H.f3(wi:getOffX()) .. "," .. H.f3(it:getWorldZRotation()))
    local done, rev = H.verb("done"), H.verb("revert")
    check(done ~= nil and done.primary == true and rev ~= nil, "placement: Done is the main verb, Revert beside it", H.verbIds(), "done,revert")
    -- (where the card's opening focus put the pad: the card zone's stop in the World window's controller ring)
    local landed = H.landed()
    check(landed == "p3:move:x", "placement: the controller lands on Movement X", landed, "p3:move:x")
    S.p0 = { x = wi:getOffX(), y = wi:getOffY(), z = wi:getOffZ(), rz = it:getWorldZRotation() }
    local ok, err = H.press("p3:move:x:+")
    local want = math.min(1, S.p0.x + 0.01)
    check(ok and math.abs(wi:getOffX() - want) < 0.001, "placement: +0.01 moves the item along X", H.f3(wi:getOffX()) .. (err and (" " .. err) or ""), H.f3(want))
end)
add(300, function()
    if S.dead or S.off.placement then return end
    local wi, it, t = S.wi, S.placeItem, H.t()
    if not H.need("placement", t ~= nil, "placement: the card is still open", H.kind(), "place3d") then return end
    local ok, err = H.press("p3:turn:z:+")
    local want = S.p0.rz + 15
    if want >= 360 then want = want - 360 end
    check(ok and math.abs(it:getWorldZRotation() - want) < 0.01 and t.group == "rotate",
        "placement: +15 turns the item about Z and the gizmo turns to rotating",
        H.f3(it:getWorldZRotation()) .. " " .. tostring(t.group) .. (err and (" " .. err) or ""), H.f3(want) .. " rotate")
    local z = H.zone("p3:move:y")
    local okd = z and z.dpad and z.dpad("right")
    local wantY = math.min(1, S.p0.y + 0.05)
    check(okd and math.abs(wi:getOffY() - wantY) < 0.001 and t.group == "translate",
        "placement: the D-pad's right on the Y slider moves 0.05 and the gizmo turns to moving",
        H.f3(wi:getOffY()) .. " " .. tostring(t.group), H.f3(wantY) .. " translate")
    wi:setOffZ(0)
    local okz, errz = H.press("p3:move:z:-")
    check(okz and wi:getOffZ() >= 0 and wi:getOffZ() < 0.001, "placement: -0.01 at the floor keeps Z at 0", H.f3(wi:getOffZ()) .. (errz and (" " .. errz) or ""), "0.000")
    shot("placement")
end)
add(300, function()
    if S.dead or S.off.placement then return end
    local it = S.placeItem
    it:setWorldZRotation(5)
    local ok, err = H.press("p3:turn:z:-")
    local got = it:getWorldZRotation()
    check(ok and math.abs(got - 350) < 0.01, "placement: -15 from 5 degrees wraps to 350", string.format("%.1f", got) .. (err and (" " .. err) or ""), "350.0")
end)
add(300, function()
    if S.dead or S.off.placement then return end
    local ok, err = H.press("oc:verb:revert")
    local t, wi, it = H.t(), S.wi, S.placeItem
    local o = t and t.orig
    local back = o ~= nil and math.abs(o.mx - wi:getOffX()) < 0.002 and math.abs(o.my - wi:getOffY()) < 0.002
        and math.abs(o.mz - wi:getOffZ()) < 0.002 and math.abs(o.rz - it:getWorldZRotation()) < 0.002
    check(ok and back, "placement: Revert puts the item back where it was",
        H.f3(wi:getOffX()) .. "," .. H.f3(wi:getOffY()) .. "," .. H.f3(it:getWorldZRotation()) .. (err and (" " .. err) or ""),
        o and (H.f3(o.mx) .. "," .. H.f3(o.my) .. "," .. H.f3(o.rz)) or "the start")
end)
add(300, function()
    if S.dead or S.off.placement then return end
    H.press("p3:move:x:+")
    S.p1x = S.wi:getOffX()
    local ok, err = H.press("oc:verb:done")
    S.doneErr = (not ok) and err or nil
end)
add(500, function()
    if S.dead or S.off.placement then return end
    check(H.card() == nil, "placement: Done closes the card", tostring(H.kind()) .. (S.doneErr and (" " .. S.doneErr) or ""), "nil")
    check(math.abs(S.wi:getOffX() - S.p1x) < 0.001 and S.wi:isExtendedPlacement(), "placement: Done keeps the new place",
        H.f3(S.wi:getOffX()) .. " extended " .. tostring(S.wi:isExtendedPlacement()), H.f3(S.p1x) .. " extended true")
    -- (the card again, through ZeD's own open, for the leash: the game's entry would walk to the hammer first)
    OC.open(p, "place3d", S.wi)
end)
add(500, function()
    if S.dead or S.off.placement then return end
    -- the leash is judged only on a card that opened again and draws (its upkeep runs in its frames)
    S.leashOpen = H.kind() == "place3d" and H.live()
    check(S.leashOpen, "placement: the card opens again on the hammer and draws (for the leash)", tostring(H.kind()) .. " live " .. tostring(H.live()), "place3d live true")
    if S.leashOpen then H.put(LG.home.x + 6, LG.home.y) end
end)
add(900, function()
    if S.dead or S.off.placement or not S.leashOpen then return end
    check(H.card() == nil, "placement: the card closes past the game's 3 squares", H.kind(), "nil")
    H.home()
end)

-- 3 FLUID ---------------------------------------------------------------------------------------------------------
add(300, function()
    if S.dead then return end
    H.home(); H.close()
    if not H.hooked("fluid", ISFluidContainerMenu and ISFluidContainerMenu._zedHooked, "an item's Pour (ISFluidContainerMenu.showUI)") then return end
    S.fA, S.fB, S.fC = H.give("Base.WaterBottle"), H.give("Base.WaterBottle"), H.give("Base.WaterBottle")
    if not (S.fA and S.fB and S.fC) then H.skip("fluid", "three water bottles"); return end
    H.fill(S.fA, Fluid.Water); H.fill(S.fB, nil); H.fill(S.fC, Fluid.Water)
    ISFluidContainerMenu.showUI(p, S.fA:getFluidContainer(), ISFluidTransferUI)
end)
waitFor(5000, function() return S.off.fluid or H.kind() == "fluid" end, "the fluid card", "fluid")
add(500, function()
    if S.dead or S.off.fluid then return end
    if not H.need("fluid", H.kind() == "fluid", "fluid: a bottle's Pour (the game's menu) opens the fluid card", H.kind(), "fluid") then return end
    local t, d = H.t(), H.d()
    if not H.need("fluid", d ~= nil, "fluid: the card has its data (its refresh ran)", "nil", "t.d") then return end
    local fa, fb = S.fA:getFluidContainer(), S.fB:getFluidContainer()
    check(t.from ~= nil and t.from:getFluidContainer() == fa and t.into == nil, "fluid: the bottle goes on the left, the right is empty",
        tostring(t.from ~= nil) .. " " .. tostring(t.into ~= nil), "true false")
    local function rowOf(it) return H.rowWhere(d.rows, function(r) return r.key == "i" .. tostring(it:getID()) end) end
    local rA, rB, rC = rowOf(S.fA), rowOf(S.fB), rowOf(S.fC)
    check(rA ~= nil and rA.isFrom and not rA.canInto, "fluid: the bottle poured from is its row's From", rA and (tostring(rA.isFrom) .. " " .. tostring(rA.canInto)), "true false")
    check(rB ~= nil and rB.tag == ZeD.tr("Fluid_Empty") and rB.canInto, "fluid: an empty bottle is tagged Empty and takes the pour",
        rB and (tostring(rB.tag) .. " " .. tostring(rB.canInto)), ZeD.tr("Fluid_Empty") .. " true")
    check(rC ~= nil and rC.tag == ZeD.tr("UI_ZeD_Fluid_TagFull") and not rC.canInto, "fluid: a full bottle is tagged Full and refuses (the engine's reason)",
        rC and (tostring(rC.tag) .. " " .. tostring(rC.canInto)), ZeD.tr("UI_ZeD_Fluid_TagFull") .. " false")
    local wn = Fluid.Water:getTranslatedName()
    check(H.pill() == wn, "fluid: the tag names the liquid", H.pill(), wn)
    local landed = H.landed()
    check(landed ~= nil and string.sub(landed, 1, 8) == "fl:into:", "fluid: with the right empty the controller lands on an Into button", landed, "fl:into:...")
    check(H.gone("oc:verb:pour"), "fluid: no Pour until the right side is set", "drawn " .. tostring(H.zone("oc:verb:pour") ~= nil) .. ", live " .. tostring(H.live()), "drawn false, live true")
    local ok, err = H.press("fl:into:i" .. tostring(S.fB:getID()))
    check(ok and t.into ~= nil and t.into:getFluidContainer() == fb, "fluid: Into on the empty bottle puts it on the right", err, "ok")
end)
add(500, function()
    if S.dead or S.off.fluid then return end
    local t, d = H.t(), H.d()
    if not H.need("fluid", d ~= nil, "fluid: the card is still open", H.kind(), "fluid") then return end
    local fa, fb = S.fA:getFluidContainer(), S.fB:getFluidContainer()
    local want = FluidUtil.roundTransfer(math.min(fa:getAmount(), fb:getCapacity() - fb:getAmount()))
    check(d.can and math.abs(d.max - want) < 0.001, "fluid: Max pour is the smaller of what is in and the room", H.f3(d.max), H.f3(want))
    check(H.zone("oc:verb:pour") ~= nil, "fluid: Pour shows once both sides are set", H.zone("oc:verb:pour") ~= nil, true)
    H.press("fl:step:2")
    check(math.abs((t.frac or 0) - 0.5) < 0.001, "fluid: 1/2 sets half the max", t.frac, 0.5)
    local z = H.zone("fl:slider")
    local okd = z and z.dpad and z.dpad("left")
    check(okd and math.abs((t.frac or 0) - 0.45) < 0.001, "fluid: the D-pad's left on the slider takes a twentieth off", t.frac, 0.45)
    H.press("fl:step:2")
    S.fA0, S.fB0 = fa:getAmount(), fb:getAmount()
    S.fWant = FluidUtil.roundTransfer(d.max * 0.5)
    local ok, err = H.press("oc:verb:pour")
    check(ok and t.action ~= nil and H.queued("ISFluidTransferAction"), "fluid: Pour queues the game's pour (ISFluidTransferAction)", err or tostring(t.action ~= nil), "queued")
end)
waitFor(15000, function() return H.idle() and math.abs(H.amt(S.fB) - (S.fB0 + S.fWant)) < 0.02 end, "the pour", "fluid")
add(500, function()
    if S.dead or S.off.fluid then return end
    local a, b = H.amt(S.fA), H.amt(S.fB)
    check(math.abs(b - (S.fB0 + S.fWant)) < 0.02 and math.abs(a - (S.fA0 - S.fWant)) < 0.02, "fluid: the pour moved half the max",
        string.format("%.2f / %.2f", a, b), string.format("%.2f / %.2f", S.fA0 - S.fWant, S.fB0 + S.fWant))
    shot("fluid")
    local ok, err = H.press("oc:verb:switch")
    local t = H.t()
    check(ok and t ~= nil and t.from ~= nil and t.into ~= nil and t.from:getFluidContainer() == S.fB:getFluidContainer() and t.into:getFluidContainer() == S.fA:getFluidContainer(),
        "fluid: Switch swaps the two sides", err, "ok")
end)
add(500, function()
    if S.dead or S.off.fluid then return end
    local ok, err = H.press("oc:verb:empty")
    local cf = H.confirm()
    local want = ZeD.tr("UI_ZeD_Fluid_QEmpty", H.L(H.amt(S.fB)), string.lower(Fluid.Water:getTranslatedName()))
    check(ok and cf ~= nil and cf.text == want and cf.danger, "fluid: Empty asks first in the band, with the litres", (cf and cf.text) or err, want)
end)
add(400, function()
    if S.dead or S.off.fluid then return end
    local ok, err = H.press("oc:confirm:no")
    check(ok and H.confirm() == nil and H.amt(S.fB) > 0, "fluid: the question's Cancel empties nothing", err or H.amt(S.fB), "ok")
    H.press("oc:verb:empty")
end)
add(400, function()
    if S.dead or S.off.fluid then return end
    local ok, err = H.press("oc:confirm:yes")
    local queued = H.queued("ISFluidEmptyAction")
    check(ok and H.confirm() == nil and queued, "fluid: the question's Empty shuts the question and queues the game's empty (ISFluidEmptyAction)",
        tostring(err or "pressed") .. ", question " .. tostring(H.confirm() ~= nil) .. ", queued " .. tostring(queued), "pressed, question false, queued true")
end)
waitFor(10000, function() return H.idle() and H.amt(S.fB) < 0.001 end, "the bottle emptied", "fluid")
add(300, function()
    if S.dead or S.off.fluid then return end
    check(H.amt(S.fB) >= 0 and H.amt(S.fB) < 0.001, "fluid: Empty (the game's action) emptied the bottle", H.amt(S.fB), 0)
    H.close()
end)
add(100, function()
    -- (the bottles away: water still in them would read as carried water on the hen house and the plot)
    H.drop(S.fA); H.drop(S.fB); H.drop(S.fC)
end)

-- 4 CAMPFIRE ------------------------------------------------------------------------------------------------------
add(300, function()
    if S.dead then return end
    H.home(); H.close()
    if not H.hooked("fire", ISCampingMenu and ISCampingMenu._zed_onDisplayInfo, "the campfire's Info (ISCampingMenu.onDisplayInfo)") then return end
    local sq = S.spots.fire
    if not sq then H.skip("fire", "a free square for a campfire"); return end
    local ok = pcall(function() SCampfireSystem.instance:addCampfire(sq) end)
    LG.fires[#LG.fires + 1] = sq
    S.fireSq = sq
    if not ok then say("addCampfire threw") end
end)
add(800, function()
    if S.dead or S.off.fire then return end
    local clo = H.campLua(S.fireSq)
    local iso = clo and clo:getIsoObject()
    if not H.need("fire", clo ~= nil and iso ~= nil, "fire: a campfire staged", clo ~= nil, true) then return end
    ISCampingMenu.onDisplayInfo(nil, p, iso, clo)
end)
waitFor(4000, function() return S.off.fire or H.kind() == "fire" end, "the fire card", "fire")
add(500, function()
    if S.dead or S.off.fire then return end
    local t, d = H.t(), H.d()
    if not H.need("fire", H.kind() == "fire" and t ~= nil and t.kind == "campfire", "fire: the campfire's Info (the game's menu) opens the fire card",
        tostring(H.kind()) .. " " .. tostring(t and t.kind), "fire campfire") then return end
    if not H.need("fire", d ~= nil, "fire: the card has its data (its refresh ran)", "nil", "t.d") then return end
    check(d.fuel == 0 and not d.lit, "fire: a new campfire reads no fuel and not lit", tostring(d.fuel) .. " " .. tostring(d.lit), "0 false")
    check(H.pill() == ZeD.tr("UI_ZeD_Fire_PillOut"), "fire: the tag says Out", H.pill(), ZeD.tr("UI_ZeD_Fire_PillOut"))
    local light, out, take = H.verb("light"), H.verb("out"), H.verb("take")
    check(out ~= nil and out.sensible == false and H.gone("oc:verb:out"), "fire: no Put out on a dead fire", out and tostring(out.sensible), "false")
    check(light ~= nil and light.enabled == false and light.needs == ZeD.tr("UI_ZeD_Fire_NeedsFuelFirst"),
        "fire: Light waits with nothing to light with, and says what it needs", light and (tostring(light.enabled) .. " " .. tostring(light.needs)), "false " .. ZeD.tr("UI_ZeD_Fire_NeedsFuelFirst"))
    check(take ~= nil and take.confirm ~= nil and take.danger and H.zone("oc:verb:take") ~= nil, "fire: Take apart shows and asks first", take and tostring(take.confirm), "a question")
    H.give("Base.Plank"); H.give("Base.Plank"); H.give("Base.SheetPaper2"); H.give("Base.Lighter")
    H.fresh()
end)
add(600, function()
    if S.dead or S.off.fire then return end
    local d = H.d()
    if not H.need("fire", d ~= nil, "fire: the card is still open", H.kind(), "fire") then return end
    local row, ri = H.rowWhere(d.fuelRows, function(r) return r.fullType == "Base.Plank" end)
    -- (the game's fuel list also reads the loot containers in reach: planks lying there add to the count)
    check(row ~= nil and row.count >= 2, "fire: the two planks carried are an Add fuel row", row and row.count, ">= 2")
    S.plankN0 = row and row.count or 0
    local lrow, li = H.rowWhere(d.lightRows, function(r) return r.method == "tinder" and r.tinderType == "Base.SheetPaper2" end)
    check(lrow ~= nil, "fire: paper with a lighter is a Light with row", lrow ~= nil, true)
    local light, fuel = H.verb("light"), H.verb("fuel")
    check(light ~= nil and light.enabled ~= false and light.primary, "fire: with a lighter, Light is live and the main verb",
        light and (tostring(light.enabled) .. " " .. tostring(light.primary)), "true true")
    check(fuel ~= nil and fuel.enabled ~= false and not fuel.primary, "fire: Add fuel is live, not the main verb while it can be lit",
        fuel and (tostring(fuel.enabled) .. " " .. tostring(fuel.primary)), "true false")
    local okj = H.press("oc:verb:fuel")
    local c = H.card()
    check(okj and c and c._pendingFocus == "fire:fuel:1", "fire: Add fuel jumps to the fuel list", c and c._pendingFocus, "fire:fuel:1")
    if not (row and lrow) then S.off.fire = true; return end
    S.fuel0, S.plankDur, S.lightFid = d.fuel, ISCampingMenu.getFuelDurationForItem(row.item), "fire:light:" .. li
    local ok, err = H.press("fire:fuel:" .. ri)
    check(ok, "fire: the plank row's Add runs (its row's own code)", err, "ok")
end)
waitFor(10000, function() local c = H.campLua(S.fireSq); return H.idle() and c and (c.fuelAmt or 0) > (S.fuel0 or 0) end, "the fuel", "fire")
add(600, function()
    if S.dead or S.off.fire then return end
    local d = H.d()
    local want = (S.fuel0 or 0) + (S.plankDur or 0)
    check(d and math.abs(d.fuel - want) < 1, "fire: the plank added its burn time", d and string.format("%.1f", d.fuel), string.format("%.1f", want))
    local row = H.rowWhere(d and d.fuelRows, function(r) return r.fullType == "Base.Plank" end)
    check(row ~= nil and row.count == S.plankN0 - 1, "fire: one plank fewer on the list", row and row.count, S.plankN0 - 1)
    local _, li = H.rowWhere(d and d.lightRows, function(r) return r.method == "tinder" and r.tinderType == "Base.SheetPaper2" end)
    local ok, err = H.press(li and ("fire:light:" .. li) or S.lightFid)
    check(ok, "fire: the paper row's Light runs (its row's own code)", err, "ok")
end)
waitFor(15000, function() local c = H.campLua(S.fireSq); return H.idle() and c and c.isLit == true end, "the fire to light", "fire")
add(600, function()
    if S.dead or S.off.fire then return end
    local d = H.d()
    local burning = OC.cap(ZeD.tr("IGUI_Fireplace_Burning"))
    check(d and d.lit and H.pill() == burning, "fire: lit with the paper (the game's action): the tag says Burning", H.pill(), burning)
    check(H.zone("oc:verb:out") ~= nil and H.gone("oc:verb:light"), "fire: lit: Put out shows, Light is gone",
        tostring(H.zone("oc:verb:out") ~= nil) .. " " .. tostring(H.zone("oc:verb:light") ~= nil) .. ", live " .. tostring(H.live()), "true false, live true")
    shot("fire")
    local ok, err = H.press("oc:verb:out")
    local queued = H.queued("ISPutOutCampfireAction")
    check(ok and queued, "fire: Put out queues the game's action (ISPutOutCampfireAction)", tostring(err or "pressed") .. ", queued " .. tostring(queued), "pressed, queued true")
end)
waitFor(10000, function() local c = H.campLua(S.fireSq); return H.idle() and c and c.isLit ~= true end, "the fire to go out", "fire")
add(600, function()
    if S.dead or S.off.fire then return end
    local d = H.d()
    check(d and not d.lit and H.pill() == ZeD.tr("UI_ZeD_Fire_PillOut"), "fire: Put out (the game's action) puts it out: the tag says Out", H.pill(), ZeD.tr("UI_ZeD_Fire_PillOut"))
    local ok, err = H.press("oc:verb:take")
    local cf = H.confirm()
    check(ok and cf ~= nil and cf.text == ZeD.tr("UI_ZeD_Fire_QTakeApart") and cf.danger, "fire: Take apart asks first, a red question",
        (cf and (tostring(cf.text) .. " " .. tostring(cf.danger))) or err, ZeD.tr("UI_ZeD_Fire_QTakeApart") .. " true")
end)
add(400, function()
    if S.dead or S.off.fire then return end
    H.press("oc:confirm:no")
    check(H.confirm() == nil and H.campLua(S.fireSq) ~= nil, "fire: the question's Cancel keeps the campfire", H.campLua(S.fireSq) ~= nil, true)
    H.press("oc:verb:take")
end)
add(400, function()
    if S.dead or S.off.fire then return end
    local ok, err = H.press("oc:confirm:yes")
    local queued = H.queued("ISRemoveCampfireAction")
    check(ok and H.confirm() == nil and queued, "fire: the question's Take apart shuts the question and queues the game's action (ISRemoveCampfireAction)",
        tostring(err or "pressed") .. ", question " .. tostring(H.confirm() ~= nil) .. ", queued " .. tostring(queued), "pressed, question false, queued true")
end)
waitFor(10000, function() return H.idle() and H.campLua(S.fireSq) == nil end, "the campfire taken apart", "fire")
add(600, function()
    if S.dead or S.off.fire then return end
    check(H.campLua(S.fireSq) == nil, "fire: Take apart (the game's action) removes the campfire", H.campLua(S.fireSq) ~= nil, false)
    check(H.card() == nil, "fire: the card closes with its campfire", H.kind(), "nil")
    H.close()
end)

-- 5 FEEDING TROUGH ------------------------------------------------------------------------------------------------
add(300, function()
    if S.dead then return end
    H.home(); H.close()
    if not H.hooked("trough", ISFeedingTroughMenu and ISFeedingTroughMenu._zedCardHooked, "Feeding Trough Info (ISFeedingTroughMenu.onInfo)") then return end
    local sq = S.spots.trough
    if not sq then H.skip("trough", "a free square for a trough"); return end
    LG.troughSq = sq
    local ok, err = pcall(function() SFeedingTroughSystem.instance:addTrough(sq, FeedingTroughDef.simple, false, -1, -1) end)
    if not ok then say("addTrough threw: " .. tostring(err)) end
end)
add(800, function()
    if S.dead or S.off.trough then return end
    S.trough = H.objOn(LG.troughSq, "IsoFeedingTrough")
    if not H.need("trough", S.trough ~= nil, "trough: a feeding trough staged", S.trough ~= nil, true) then return end
    local x, y = LG.troughSq:getX(), LG.troughSq:getY()
    S.zone0 = DesignationZoneAnimal.getZone(x, y, LG.troughSq:getZ())
    ISFeedingTroughMenu.onInfo(S.trough, p)
end)
waitFor(5000, function() return S.off.trough or H.kind() == "trough" end, "the trough card", "trough")
add(500, function()
    if S.dead or S.off.trough then return end
    if not H.need("trough", H.kind() == "trough", "trough: Feeding Trough Info (the game's menu) opens the trough card", H.kind(), "trough") then return end
    local d = H.d()
    if not H.need("trough", d ~= nil, "trough: the card has its data (its refresh ran)", "nil", "t.d") then return end
    check(not d.hasFood and not d.hasWater and H.pill() == ZeD.tr("Fluid_Empty"), "trough: a new trough is tagged Empty", H.pill(), ZeD.tr("Fluid_Empty"))
    local zn0 = S.zone0 and S.zone0:getName() or nil
    check((d.zone ~= nil) == (S.zone0 ~= nil) and d.zoneName == zn0, "trough: the zone line names the animal zone it stands in (or none)", tostring(d.zoneName), tostring(zn0))
    if not S.zone0 then
        S.zoneName = "ZeDQA ObjCard Pen"
        local x, y = LG.troughSq:getX(), LG.troughSq:getY()
        LG.zones[#LG.zones + 1] = S.zoneName
        pcall(function() DesignationZoneAnimal.new(S.zoneName, x - 2, y - 2, 0, x + 2, y + 2, true) end)
    end
    ISFeedingTroughMenu.onAddWaterDebug(p, S.trough, Fluid.Water)
    H.fresh()
end)
add(600, function()
    if S.dead or S.off.trough then return end
    local d = H.d()
    if not H.need("trough", d ~= nil, "trough: the card is still open", H.kind(), "trough") then return end
    if S.zoneName then check(d.zoneName == S.zoneName, "trough: a zone drawn over it is named on the card", d.zoneName, S.zoneName) end
    -- (the card's reading, up to a quarter second old, against the trough now: a margin, not an equality)
    local tw = S.trough:getWater()
    check(d.hasWater and d.water > 0 and math.abs(d.water - tw) < math.max(0.05, 0.01 * tw), "trough: reads the water in it", string.format("%.2f", d.water or -1), string.format("%.2f", tw))
    check(H.pill() == ZeD.tr("Fluid_Name_Water"), "trough: water in it: the tag says Water", H.pill(), ZeD.tr("Fluid_Name_Water"))
    local food, water, empty = H.verb("food"), H.verb("water"), H.verb("empty")
    check(food ~= nil and food.sensible == false and H.gone("oc:verb:food"), "trough: water in it: no Add food (one or the other)", food and tostring(food.sensible), "false")
    check(water ~= nil and water.primary and empty ~= nil and empty.confirm ~= nil, "trough: water in it: Add water is the main verb, Empty asks first", H.verbIds(), "food,water,empty")
    local ok, err = H.press("oc:verb:empty")
    local cf = H.confirm()
    local want = ZeD.tr("UI_ZeD_Trough_QEmpty", string.format("%.1f L", d.water or 0), string.lower(d.fluidName or ZeD.tr("UI_ZeD_Trough_WaterWord")))
    check(ok and cf ~= nil and cf.text == want, "trough: Empty asks first, with the litres", (cf and cf.text) or err, want)
end)
add(400, function()
    if S.dead or S.off.trough then return end
    local ok, err = H.press("oc:confirm:yes")
    local queued = H.queued("ISFluidEmptyAction")
    check(ok and H.confirm() == nil and queued, "trough: the question's Empty shuts the question and queues the game's empty (ISFluidEmptyAction)",
        tostring(err or "pressed") .. ", question " .. tostring(H.confirm() ~= nil) .. ", queued " .. tostring(queued), "pressed, question false, queued true")
end)
waitFor(12000, function() return H.idle() and S.trough:getWater() < 0.01 end, "the trough emptied", "trough")
add(600, function()
    if S.dead or S.off.trough then return end
    local d = H.d()
    check(S.trough:getWater() < 0.01 and d and not d.hasWater and H.pill() == ZeD.tr("Fluid_Empty"), "trough: Empty (the game's action) empties it: the tag says Empty",
        string.format("%.2f ", S.trough:getWater()) .. tostring(H.pill()), "0.00 " .. ZeD.tr("Fluid_Empty"))
    local ok, err = H.press("oc:verb:water")
    S.waterErr = (not ok) and err or nil
end)
add(500, function()
    if S.dead or S.off.trough then return end
    local t, tfc = H.t(), S.trough:getFluidContainer()
    check(H.kind() == "fluid" and t and t.into ~= nil and tfc ~= nil and t.into:getFluidContainer() == tfc,
        "trough: Add water opens the fluid card aimed at the trough", tostring(H.kind()) .. (S.waterErr and (" " .. S.waterErr) or ""), "fluid")
    H.close()
    ISFeedingTroughMenu.onAddFoodDebug(p, S.trough)
    ISFeedingTroughMenu.onInfo(S.trough, p)
end)
add(600, function()
    if S.dead or S.off.trough then return end
    local d = H.d()
    if not H.need("trough", H.kind() == "trough" and d ~= nil, "trough: the card reopens", H.kind(), "trough") then return end
    check(d.hasFood and H.pill() == ZeD.tr("UI_ZeD_Trough_PillFood"), "trough: feed in it: the tag says Food", H.pill(), ZeD.tr("UI_ZeD_Trough_PillFood"))
    local g = d.inside[1]
    local n = S.trough:getContainer():getItems():size()
    check(#d.inside == 1 and g ~= nil and #g.items == n and n > 0, "trough: lists what lies in it", tostring(#d.inside) .. " rows, " .. tostring(g and #g.items), "1 row, " .. n)
    check(H.gone("oc:verb:water") and H.gone("oc:verb:empty"), "trough: feed in it: no Add water, no Empty", H.verbIds() .. ", live " .. tostring(H.live()), "food (water not sensible), live true")
    S.feedType = g and g.item:getFullType()
    local ok, err = H.press("trough:take:1")
    check(ok, "trough: Take runs (its row's own code)", err, "ok")
end)
waitFor(10000, function() return H.idle() and S.trough:getContainer():getItems():size() == 0 end, "the feed taken", "trough")
add(600, function()
    if S.dead or S.off.trough then return end
    local d = H.d()
    check(S.trough:getContainer():getItems():size() == 0 and d and not d.hasFood, "trough: Take (the game's transfer) moved the feed to the bags",
        S.trough:getContainer():getItems():size(), 0)
    local row, ri = H.rowWhere(d and d.feedRows, function(r) return r.item:getFullType() == S.feedType end)
    check(row ~= nil, "trough: the feed carried is an Add row", row ~= nil, true)
    local food = H.verb("food")
    check(food ~= nil and food.enabled ~= false and food.primary, "trough: with feed carried, Add food is live and the main verb",
        food and (tostring(food.enabled) .. " " .. tostring(food.primary)), "true true")
    H.press("oc:verb:food")
    local c = H.card()
    check(c and c._pendingFocus == "trough:feed:1", "trough: Add food jumps to the feed list", c and c._pendingFocus, "trough:feed:1")
    if ri then
        local ok, err = H.press("trough:feed:" .. ri)
        check(ok, "trough: the feed row's Add runs (its row's own code)", err, "ok")
    end
end)
waitFor(10000, function() return H.idle() and S.trough:getContainer():getItems():size() > 0 end, "the feed put in", "trough")
add(600, function()
    if S.dead or S.off.trough then return end
    local d = H.d()
    check(S.trough:getContainer():getItems():size() > 0 and d and d.hasFood, "trough: Add (the game's transfer) moved the feed into the trough",
        S.trough:getContainer():getItems():size(), "> 0")
    shot("trough")
    H.close()
    for _, name in ipairs(LG.zones) do
        pcall(function() local z = H.zoneByName(name); if z then DesignationZoneAnimal.removeZone(z, true) end end)
    end
end)

-- 6 HEN HOUSE -----------------------------------------------------------------------------------------------------
add(300, function()
    if S.dead then return end
    H.home(); H.close()
    if not H.hooked("hutch", ISHutchMenu and ISHutchMenu._zedCardHooked, "the hen house's Info (ISHutchMenu.onInfo)") then return end
    local sq = S.spots.hutch
    if not sq then H.skip("hutch", "free ground for a hen house"); return end
    local def = HutchDefinitions and HutchDefinitions.hutchs and HutchDefinitions.hutchs.hutchhen
    if not def then H.skip("hutch", "the game's hen house (HutchDefinitions.hutchs.hutchhen)"); return end
    LG.hutchSq = sq
    local ok, err = pcall(function()
        local h = IsoHutch.new(sq, true, def.baseSprite, def, nil)
        h:transmitCompleteItemToClients()
    end)
    if not ok then say("IsoHutch.new threw: " .. tostring(err)) end
end)
add(800, function()
    if S.dead or S.off.hutch then return end
    local h = H.objOn(LG.hutchSq, "IsoHutch")
    h = h and (h:getHutch() or h)
    S.hutch, LG.hutch = h, h
    if not H.need("hutch", h ~= nil, "hutch: a hen house staged", h ~= nil, true) then return end
    if h:isOpen() then h:toggleDoor() end
    if h:isEggHatchDoorOpen() then h:toggleEggHatchDoor() end
    -- two hens on the perches, three eggs in box 1, a dirty floor. The hen that sits on an egg comes later, right
    -- before the boxes are read (see the header: she lays and leaves her box 7 to 12 s after she sits down)
    S.breed = H.breedOf("hen")
    for k = 1, 2 do
        local a = addAnimal(getCell(), 0, 0, 0, "hen", S.breed)
        if a then H.mark(a); LG.hens[#LG.hens + 1] = a; a:getData():setPreferredHutchPosition(k - 1); h:addAnimalInside(a) end
    end
    S.eggBox = 1
    local nest = h:getNestBox(S.eggBox)
    if not H.need("hutch", nest ~= nil, "hutch: the hen house has a second nest box", nest ~= nil, true) then return end
    for _ = 1, 3 do nest:addEgg(instanceItem("Base.Egg")) end
    S.eggBoxEggs0 = nest:getEggsNb()
    h:setHutchDirt(3)
    say("hen house at " .. LG.hutchSq:getX() .. "," .. LG.hutchSq:getY() .. ": hens on the perches " .. H.perchCount()
        .. ", eggs in box " .. S.eggBox .. ": " .. S.eggBoxEggs0)
    ISHutchMenu.onInfo(h, p)
end)
waitFor(8000, function() return S.off.hutch or H.kind() == "hutch" end, "the hen house card", "hutch")
add(500, function()
    if S.dead or S.off.hutch then return end
    if not H.need("hutch", H.kind() == "hutch", "hutch: the hen house's Info (the game's menu) opens the hutch card", H.kind(), "hutch") then return end
    local d = H.d()
    if not H.need("hutch", d ~= nil, "hutch: the card has its data (its refresh ran)", "nil", "t.d") then return end
    check(d.allClosed and H.pill() == ZeD.tr("UI_ZeD_Hutch_PillShut"), "hutch: both doors shut: the tag says Shut", H.pill(), ZeD.tr("UI_ZeD_Hutch_PillShut"))
    check(not d.boxesShown and not d.roostShown and H.live() and #H.zonesLike("hutch:") == 0, "hutch: both doors shut: boxes and perches covered, nothing to grab",
        #H.zonesLike("hutch:") .. ", live " .. tostring(H.live()), "0, live true")
    local door = H.verb("door")
    check(door ~= nil and door.primary and H.verb("eggs") == nil, "hutch: shut: Open door is the main verb, no Grab eggs", H.verbIds(), "door,hatch,clean")
    local ok, err = H.press("oc:verb:hatch")
    local queued = H.queued("ISToggleHutchEggHatchDoor")
    check(ok and queued, "hutch: Open hatch queues the game's action (ISToggleHutchEggHatchDoor)", tostring(err or "pressed") .. ", queued " .. tostring(queued), "pressed, queued true")
end)
waitFor(10000, function() return H.idle() and S.hutch:isEggHatchDoorOpen() end, "the hatch to open", "hutch")
add(600, function()
    if S.dead or S.off.hutch then return end
    -- the hen on an egg, now (IsoHutch.addAnimalInNestBox: the first box with no hen and room, box 0)
    local h = S.hutch
    local sit = addAnimal(getCell(), 0, 0, 0, "hen", S.breed)
    local seated = false
    if sit then
        H.mark(sit); LG.hens[#LG.hens + 1] = sit
        seated = h:addAnimalInNestBox(sit) == true
    end
    S.sitBox = nil
    for b = 0, h:getMaxNestBox() do if sit and h:getAnimalInNestBox(b) == sit then S.sitBox = b end end
    if not H.need("hutch", seated and S.sitBox ~= nil and S.sitBox ~= S.eggBox, "hutch: a hen sits in a nest box (set there now)",
        "seated " .. tostring(seated) .. ", box " .. tostring(S.sitBox), "seated true, a box but " .. S.eggBox) then return end
    h:getNestBox(S.sitBox):addEgg(instanceItem("Base.Egg"))
    S.under0 = h:getNestBox(S.sitBox):getEggsNb()
    -- the card again through the game's Info: where the pad lands is picked as a card opens
    ISHutchMenu.onInfo(h, p)
end)
add(600, function()
    if S.dead or S.off.hutch then return end
    if not H.need("hutch", H.kind() == "hutch", "hutch: the card opens again through the game's Info", H.kind(), "hutch") then return end
    local d, h = H.d(), S.hutch
    if not H.need("hutch", d ~= nil, "hutch: the card has its data again", "nil", "t.d") then return end
    local want = 0
    for b = 0, h:getMaxNestBox() do local nb = h:getNestBox(b); if nb then want = want + nb:getEggsNb() end end
    check(d.boxesShown and not d.roostShown and H.pill() == ZeD.tr("IGUI_Open"), "hutch: hatch open (the game's action): the boxes show, the perches stay covered, the tag says Open",
        tostring(d.boxesShown) .. " " .. tostring(d.roostShown) .. " " .. tostring(H.pill()), "true false " .. ZeD.tr("IGUI_Open"))
    check(d.eggs == want and want >= S.eggBoxEggs0 + S.under0, "hutch: counts the eggs in the boxes (the sitting hen's too)", d.eggs, want)
    local sitting = h:getAnimalInNestBox(S.sitBox) ~= nil
    check(sitting and H.zone("hutch:box:" .. S.eggBox) ~= nil and H.gone("hutch:box:" .. S.sitBox),
        "hutch: Grab on the box with eggs, none under the sitting hen",
        table.concat(H.zonesLike("hutch:box:"), ",") .. ", sitting " .. tostring(sitting) .. ", live " .. tostring(H.live()),
        "hutch:box:" .. S.eggBox .. ", sitting true, live true")
    local eggs = H.verb("eggs")
    check(eggs ~= nil and eggs.enabled ~= false and eggs.primary, "hutch: Grab eggs is live and the main verb", eggs and tostring(eggs.primary), "true")
    local landed = H.landed()
    check(landed == "hutch:box:" .. S.eggBox, "hutch: the controller lands on the box with eggs", landed, "hutch:box:" .. S.eggBox)
    S.eggs0 = H.count("Base.Egg")
    shot("hutch")
    local ok, err = H.press("oc:verb:eggs")
    local queued = H.queued("ISHutchGrabEgg")
    check(ok and queued, "hutch: Grab eggs queues the game's grab (ISHutchGrabEgg)", tostring(err or "pressed") .. ", queued " .. tostring(queued), "pressed, queued true")
end)
waitFor(15000, function() return H.idle() and S.hutch:getNestBox(S.eggBox):getEggsNb() == 0 end, "the eggs grabbed", "hutch")
add(600, function()
    if S.dead or S.off.hutch then return end
    local h = S.hutch
    local got = H.count("Base.Egg") - (S.eggs0 or 0)
    local left = h:getNestBox(S.eggBox):getEggsNb()
    -- (the sitting hen's box keeps its egg; one more if she has laid since she sat down)
    local under = h:getNestBox(S.sitBox):getEggsNb()
    check(left == 0 and got == S.eggBoxEggs0 and under >= S.under0 and S.under0 >= 1,
        "hutch: Grab eggs (the game's action) took the free box's " .. S.eggBoxEggs0 .. " eggs, not the sitting hen's",
        "box " .. left .. ", carried +" .. got .. ", under the hen " .. under, "box 0, carried +" .. S.eggBoxEggs0 .. ", under the hen " .. S.under0 .. " or more")
    check(H.gone("oc:verb:eggs"), "hutch: no free eggs left: Grab eggs is gone", "drawn " .. tostring(H.zone("oc:verb:eggs") ~= nil) .. ", live " .. tostring(H.live()), "drawn false, live true")
    local ok, err = H.press("oc:verb:door")
    local queued = H.queued("ISToggleHutchDoor")
    check(ok and queued, "hutch: Open door queues the game's action (ISToggleHutchDoor)", tostring(err or "pressed") .. ", queued " .. tostring(queued), "pressed, queued true")
end)
waitFor(10000, function()
    if not (H.idle() and S.hutch:isOpen()) then return false end
    S.birdsAtOpen = H.perchCount()
    return true
end, "the door to open", "hutch")
add(600, function()
    if S.dead or S.off.hutch then return end
    local d = H.d()
    if not H.need("hutch", d ~= nil, "hutch: the card is still open", H.kind(), "hutch") then return end
    -- (in daytime the hens walk out of an open hen house, one every 4 to 6 s: the perches only lose birds while the
    -- door is open, so the card's list, read up to a quarter second ago, lies between the count now and the count
    -- when the door opened)
    local now, n = H.perchCount(), #d.birds
    local was = S.birdsAtOpen or now
    check(d.roostShown and n >= 1 and n >= now and n <= was, "hutch: door open (the game's action): the perches list the birds in the hen house",
        n .. " listed", "1 or more, " .. now .. " to " .. was)
    local okZ = n > 0 and H.live()
    for _, b in ipairs(d.birds) do
        if not (H.zone("hutch:bird:" .. b.i .. ":grab") and H.zone("hutch:bird:" .. b.i .. ":info")) then okZ = false end
    end
    check(okZ, "hutch: each bird has Grab and Info", table.concat(H.zonesLike("hutch:bird:"), ","), "grab and info per bird")
    local b = d.birds[1]
    S.infoBird = b and b.a
    if not b then check(false, "hutch: a bird's Info shows that bird in the Animals tab", "no bird on the perches", "a bird"); return end
    local ok, err = H.press("hutch:bird:" .. b.i .. ":info")
    check(ok, "hutch: a bird's Info runs (its row's own code)", err, "ok")
end)
add(900, function()
    if S.dead or S.off.hutch or not S.infoBird then return end
    local w, st = H.W(), nil
    if w and ZeD.AnimalsTab and ZeD.AnimalsTab.getState then st = ZeD.AnimalsTab.getState(w) end
    check(H.card() == nil and w ~= nil and w._activeTab == "animals" and st ~= nil and st.view == "animal" and st.animalRef == S.infoBird,
        "hutch: a bird's Info shows that bird in the Animals tab", tostring(w and w._activeTab) .. " " .. tostring(st and st.view), "animals animal")
end)
add(100, function()
    if S.dead or S.off.hutch then return end
    -- the door shut again (the hens left stay in), the hens that walked out taken away now (not left to wander the
    -- strip and the plots), the Animals tab and the World window back as they were
    local h = S.hutch
    if h:isOpen() then h:toggleDoor() end
    local out = H.hensOut()
    for _, a in ipairs(out) do H.takeAwayOut(a) end
    say("hutch: the door shut again; hens that had walked out, taken away: " .. #out)
    H.atBack(); H.tabBack()
end)
add(400, function()
    if S.dead or S.off.hutch then return end
    -- (a step after the tab's own click: openTab can land a tick later, and its Loot press drops a card)
    ISHutchMenu.onInfo(S.hutch, p)
end)
add(600, function()
    if S.dead or S.off.hutch then return end
    if not H.need("hutch", H.kind() == "hutch", "hutch: the card opens again for the floor", H.kind(), "hutch") then return end
    local clean = H.verb("clean")
    local need = ZeD.tr("UI_ZeD_Hutch_NeedsBoth", ZeD.tr("UI_ZeD_Hutch_NeedsWater"), ZeD.tr("UI_ZeD_Hutch_NeedsMop"))
    check(clean ~= nil and clean.enabled == false and clean.needs == need, "hutch: a dirty floor, no water or mop: Clean waits and names both",
        clean and (tostring(clean.enabled) .. " " .. tostring(clean.needs)), "false " .. need)
    S.bucket = H.give("Base.Bucket")
    if S.bucket then H.fill(S.bucket, Fluid.Water) end
    S.sponge = H.give("Base.Sponge")
    H.fresh()
end)
add(600, function()
    if S.dead or S.off.hutch then return end
    local clean = H.verb("clean")
    check(clean ~= nil and clean.enabled ~= false, "hutch: with a bucket of water and a sponge, Clean is live", clean and tostring(clean.enabled), "true")
    S.dirtAt = S.hutch:getHutchDirt()
    local ok, err = H.press("oc:verb:clean")
    local queued = H.queued("ISHutchCleanFloor")
    check(ok and queued, "hutch: Clean queues the game's cleaning (ISHutchCleanFloor)", tostring(err or "pressed") .. ", queued " .. tostring(queued), "pressed, queued true")
end)
waitFor(15000, function() return H.idle() and S.hutch:getHutchDirt() < (S.dirtAt or 3) end, "the floor cleaned", "hutch")
add(600, function()
    if S.dead or S.off.hutch then return end
    -- (a hen house with hens in it gains a point of dirt now and then, IsoHutch.update: a fresh point is allowed for)
    local dirt = S.hutch:getHutchDirt()
    check(dirt < (S.dirtAt or 3) and dirt <= 1, "hutch: Clean (the game's action) cleaned the floor", dirt, "0 (1 with a fresh point) from " .. tostring(S.dirtAt))
    local d = H.d()
    local shown = H.zone("oc:verb:clean") ~= nil
    check(d ~= nil and H.live() and (d.dirt > 0) == shown, "hutch: Clean shows only while the floor is dirty (the card reads " .. tostring(d and d.dirt) .. ")",
        "shown " .. tostring(shown) .. ", live " .. tostring(H.live()), "shown " .. tostring(d ~= nil and d.dirt > 0) .. ", live true")
    H.close()
end)
add(100, function()
    -- (the bucket of water away before the plot's "no water carried")
    H.drop(S.bucket); H.drop(S.sponge)
end)

-- 7 FARM PLOTS ----------------------------------------------------------------------------------------------------
add(300, function()
    if S.dead then return end
    H.home(); H.close()
    if not H.hooked("farm", ISFarmingMenu and ISFarmingMenu._zed_onInfo, "the plot's Info (ISFarmingMenu.onInfo)") then return end
    local sq1 = S.spots.farm
    local sq2 = sq1 and getCell():getGridSquare(sq1:getX() + 1, sq1:getY(), sq1:getZ())
    if not (sq1 and sq2) then H.skip("farm", "free ground for two plots"); return end
    S.plot1, S.plot2 = sq1, sq2
    for _, sq in ipairs({ sq1, sq2 }) do
        local k = #LG.plots + 1
        LG.plots[k] = sq
        LG.plowDay[k] = sq:getModData().plowDay
        local ok, err = pcall(function() SFarmingSystem.instance:plow(sq) end)
        if not ok then say("plow threw: " .. tostring(err)) end
    end
end)
add(800, function()
    if S.dead or S.off.farm then return end
    local c1, c2 = H.plantLua(S.plot1), H.plantLua(S.plot2)
    if not H.need("farm", c1 ~= nil and c2 ~= nil and c1.state == "plow", "farm: two plowed plots staged", tostring(c1 and c1.state) .. " " .. tostring(c2 ~= nil), "plow true") then return end
    ISFarmingMenu.onInfo(nil, c1, S.plot1, p)
end)
waitFor(4000, function() return S.off.farm or H.kind() == "plant" end, "the farm card", "farm")
add(500, function()
    if S.dead or S.off.farm then return end
    if not H.need("farm", H.kind() == "plant", "farm: the plot's Info (the game's menu) opens the farm card", H.kind(), "plant") then return end
    local t, d, e = H.t(), H.d(), H.e()
    if not H.need("farm", d ~= nil, "farm: the card has its data (its refresh ran)", "nil", "t.d") then return end
    check(d.plowed and H.pill() == ZeD.tr("UI_ZeD_Farm_PillEmpty"), "farm: plowed: the tag says Empty", H.pill(), ZeD.tr("UI_ZeD_Farm_PillEmpty"))
    local sow = H.verb("sow")
    check(#t.verbs == 1 and sow ~= nil and sow.enabled == false, "farm: plowed with no seeds carried: only Sow, waiting",
        H.verbIds() .. " " .. tostring(sow and sow.enabled), "sow false")
    check(e.list ~= nil and #e.list >= 2 and H.zone("oc:next") ~= nil and H.zone("farm:g:2") ~= nil,
        "farm: the garden strip and the header arrows list the plots in reach", e.list and #e.list, ">= 2")
    H.give("Base.CarrotSeed"); H.give("Base.CarrotSeed")
    H.fresh()
end)
add(600, function()
    if S.dead or S.off.farm then return end
    local t, d = H.t(), H.d()
    if not H.need("farm", d ~= nil, "farm: the card is still open", H.kind(), "plant") then return end
    local row, ri = H.rowWhere(d.seeds, function(r) return r.seedName == "Base.CarrotSeed" end)
    check(row ~= nil and row.count == 2, "farm: the carrot seeds carried are a Sow row", row and row.count, 2)
    local sow = H.verb("sow")
    check(sow ~= nil and sow.enabled and sow.primary, "farm: with seeds, Sow is live and the main verb", sow and tostring(sow.enabled), "true")
    H.press("oc:verb:sow")
    local c = H.card()
    check(c and c._pendingFocus == "farm:sow:1", "farm: Sow jumps to the seed list", c and c._pendingFocus, "farm:sow:1")
    if not row then S.off.farm = true; return end
    S.plotKey = t.key
    local ok, err = H.press("farm:sow:" .. ri)
    check(ok, "farm: the seed row's Sow runs (its row's own code)", err, "ok")
end)
waitFor(15000, function() local c = H.plantLua(S.plot1); return H.idle() and c and c.state == "seeded" end, "the sowing", "farm")
add(600, function()
    if S.dead or S.off.farm then return end
    local t, c = H.t(), H.plantLua(S.plot1)
    check(c and c.state == "seeded" and c.typeOfSeed == "Carrots" and t and t.key == S.plotKey and t.d and not t.d.plowed,
        "farm: Sow (the game's action) planted carrots and the card stays on the plot", tostring(c and c.state) .. " " .. tostring(c and c.typeOfSeed), "seeded Carrots")
    H.setWater(20)
    H.fresh()
end)
add(600, function()
    if S.dead or S.off.farm then return end
    local d = H.d()
    -- (the farming system's ten-minute tick moves the level, SFarmingSystem.checkWater: -0.1 in the sun, rain up to
    -- +30. The tag is read as vanilla's band for the level set, not the level itself)
    check(d and d.water <= 25 and H.pill() == ZeD.tr("Farming_Parched"), "farm: a parched plot (water set to 20): the tag says Parched (25 and under)",
        tostring(d and d.water) .. " " .. tostring(H.pill()), "<= 25 " .. ZeD.tr("Farming_Parched"))
    local w = H.verb("water")
    check(w ~= nil and w.sensible ~= false and w.enabled == false, "farm: thirsty with no water carried: Water waits", w and tostring(w.enabled), "false")
    local bottle = H.give("Base.WaterBottle")
    if bottle then H.fill(bottle, Fluid.Water) end
    -- (the level set again, so rain since cannot carry it past thirsty, 60, where Water stops being the main verb)
    H.setWater(20)
    H.fresh()
end)
add(600, function()
    if S.dead or S.off.farm then return end
    local w = H.verb("water")
    check(w ~= nil and w.enabled and w.primary, "farm: with water carried, Water is live and the main verb", w and (tostring(w.enabled) .. " " .. tostring(w.primary)), "true true")
    S.water0 = H.waterLvl()
    local ok, err = H.press("oc:verb:water")
    local queued = H.queued("ISWaterPlantAction")
    check(ok and queued, "farm: Water queues the game's watering (ISWaterPlantAction)", tostring(err or "pressed") .. ", queued " .. tostring(queued), "pressed, queued true")
end)
waitFor(15000, function() return H.idle() and (H.waterLvl() or 0) > (S.water0 or 20) + 1 end, "the watering", "farm")
add(600, function()
    if S.dead or S.off.farm then return end
    local lvl, d = H.waterLvl(), H.d()
    -- (the card's reading, up to a quarter second old, against the farming system's: a margin, not an equality)
    check(lvl ~= nil and lvl > (S.water0 or 20) + 1 and d ~= nil and math.abs(d.water - lvl) < 0.5, "farm: Water (the game's action) raised the water and the card reads it",
        tostring(lvl) .. " / " .. tostring(d and d.water), "> " .. tostring((S.water0 or 20) + 1) .. ", within 0.5")
    if not ISFarmingMenu.getShovel(p) then H.give("Base.Shovel") end
    H.fresh()
end)
add(500, function()
    if S.dead or S.off.farm then return end
    local ok, err = H.press("oc:verb:dig")
    local cf = H.confirm()
    local want = ZeD.tr("UI_ZeD_Farm_ConfirmDig", string.lower(H.txt("Farming_Carrots", "Carrots")))
    check(ok and cf ~= nil and cf.text == want and cf.danger, "farm: Dig up asks first, naming the crop", (cf and cf.text) or err, want)
end)
add(400, function()
    if S.dead or S.off.farm then return end
    H.press("oc:confirm:no")
    check(H.confirm() == nil and H.plantLua(S.plot1) ~= nil, "farm: the question's Cancel keeps the plant", H.plantLua(S.plot1) ~= nil, true)
    shot("farm")
    local e = H.e()
    S.k1 = e and e.t and e.t.key
    local ok, err = H.press("oc:next")
    check(ok and H.e() and H.e().t.key ~= S.k1, "farm: > steps to the next plot", err or tostring(H.e() and H.e().idx), "another plot")
end)
add(400, function()
    if S.dead or S.off.farm then return end
    local ok, err = H.press("farm:g:1")
    local e = H.e()
    check(ok and e and e.idx == 1 and e.t == e.list[1], "farm: a plot on the garden strip picks that plot", err or tostring(e and e.idx), 1)
end)
add(400, function()
    if S.dead or S.off.farm then return end
    local e = H.e()
    local n = e and e.list and #e.list or 0
    local ok, err = H.press("oc:prev")
    local e2 = H.e()
    check(ok and e2 ~= nil and e2.idx == n and e2.t ~= nil and e2.t == e2.list[n], "farm: < on the first plot wraps to the last",
        ok and ("idx " .. tostring(e2 and e2.idx)) or err, "idx " .. n)
    -- (the card shut in this same step: with the bug, the entry is left on index 0 and the card's next frame would throw
    -- again in OC.tick; it opens again on the first plot below, whatever < did)
    H.close()
end)
add(600, function()
    if S.dead or S.off.farm then return end
    local c1 = H.plantLua(S.plot1)
    if c1 then ISFarmingMenu.onInfo(nil, c1, S.plot1, p) end
end)
add(600, function()
    if S.dead or S.off.farm then return end
    local t = H.t()
    if not H.need("farm", H.kind() == "plant" and t ~= nil, "farm: the card reopens on the plot", H.kind(), "plant") then return end
    S.goneKey = t.key
    local lo = SFarmingSystem.instance:getLuaObjectOnSquare(t.sq)
    if lo then SFarmingSystem.instance:removePlant(lo) end
end)
add(900, function()
    if S.dead or S.off.farm then return end
    local t = H.t()
    check(H.kind() == "plant" and t ~= nil and t.key ~= S.goneKey and H.live(), "farm: the plot dug up from under the card: it moves to one still in reach",
        tostring(H.kind()) .. " " .. tostring(t and t.key) .. ", live " .. tostring(H.live()), "plant, another plot, live true")
    H.close()
end)

-- 8 PUT BACK ------------------------------------------------------------------------------------------------------
add(500, function()
    H.restore("the end")
end)
add(900, function()
    -- (only when the setup ran: on another save, or with the cards missing, nothing was staged)
    if LG.home then
        local left = H.leftovers()
        check(#left == 0, "cleanup: everything staged is gone", table.concat(left, ", "), "nothing")
    end
    say("RESULT " .. R.pass .. " pass, " .. R.fail .. " fail, " .. R.err .. " step errors")
    say("fails " .. (R.fail + R.err))
    say("DONE")
end)

local function drive()
    local st = plan[pi]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - tStart > 540000 and not LG.done then
        say("ERR the run took over 9 minutes: stopping here")
        H.restore("time out")
        say("fails " .. (R.fail + R.err + 1))
        say("DONE")
        Events.OnTick.Remove(drive)
        return
    end
    -- (both windows held down while the run stages and reads: H.keepDown)
    if LG.home and not LG.done then
        local okK, eK = pcall(H.keepDown)
        if not okK and not S.keepErr then S.keepErr = true; R.err = R.err + 1; say("ERR holding the windows down: " .. tostring(eK)) end
    end
    if st.wait then
        local ok, done = pcall(st.fn)
        if not ok then R.err = R.err + 1; say("ERR wait " .. pi .. ": " .. tostring(done)); done = true end
        if done then pi = pi + 1; t0 = getTimestampMs() end
        return
    end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs()
    pi = pi + 1
    local ok, e = pcall(st.fn)
    if not ok then R.err = R.err + 1; say("ERR step " .. (pi - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
