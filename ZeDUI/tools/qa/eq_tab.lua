-- ZeDUI/tools/qa/eq_tab.lua  (Nov 24 2026, QA; tag eq_tab): the Equipment tab of the Character window, the whole
-- gamut, in the style of the Health and loot sweeps (hg.txt, lv.txt). Its spec is the map
-- ZeDUI/qa/audits/2026-11-24_map_equipment.md (section 4's gaps, the suspicions S1-S18). Run after zedqa_prelude.lua and
-- rt_kit.lua (et.txt). grep "ZEDQA eq_tab". Built the way lv_calls.lua is (its helpers copied: each script stands alone).
--
-- The character's own outfit is set aside first: every worn thing that gives no belt slot and is no bag comes off into
-- the inventory (belts, holsters and bags stay on, so the belt keeps its slots and keys), the hands are emptied and a
-- stocked outfit the test makes goes on: a tank top under a T-shirt, a sweater under a jacket, a cap, glasses, a scarf,
-- a necklace, leather gloves, a watch, a ring on each hand, jeans, socks under boots and a knee pad. Every case starts
-- from it and puts it back. Timed actions are instant (lv_move's way). No controller is plugged into the QA PC: for the
-- pad the input mode is locked to the controller (Detector.setLockedMode, put back as found) and the presses go through
-- FocusManager's QA hook and its own dispatch (Focus.qaButton + dispatchJoypadDown / dispatchJoypadDir, rt_cards.lua's
-- way). A mouse press on the tab goes through the drawer's own handlers (rt_windows.lua's way); a press on the item
-- card's verb goes through the card's own pointer poll (ItemCard:_pointer) with the pointer held on the verb, down,
-- then up. A drop on the doll is handed to the doll's drop taker (EquipDoll.takeDrop, bx_inventory 10c's way).
-- Checks (S<n> = the map's suspicion; a design call is a NOTE with its data, a plain bug a FAIL):
--   1 places   every body location of the game's Human group (BodyLocations.getGroup) with a garment that goes there
--              (the first one the script manager has): worn alone, it lands in a list row (EquipmentTab.gatherData) and
--              in a doll slot with the bands showing and folded (EquipDoll.gather); FAIL for a place it shows in
--              neither view or in one only; NOTE legs5 (unused, the map's "neither"), the places with no garment, and
--              the map's section 3 differences (underwearbottom, torsoextravest, vesttexture, gorget, shoulderholster)
--   2 layers   list: T-shirt INR then tank top INR#2, jacket OUT then sweater OUT#2, two RNG rows, socks and boots
--              their own rows, each drawn, outermost above; doll: Torso 2 layers, Outer 2, Feet 2, folded Hands 3
--              (gloves and both rings), outermost first; the card's layer strip "Layer 1 of 2" with Inner on and Outer
--              off, Inner by the mouse shows the sweater and Outer the jacket again; the same by the pad
--              (equipcard:__layer_1 / __layer_-1); B goes back and the focus returns to the Outer box
--   3 off      the card on the cap (UNEQUIP, DROP, MORE; on screen): UNEQUIP by the mouse takes it off, the card
--              closes; the jacket over the sweater by the mouse: UNEQUIP takes the jacket alone off and (S1) the card
--              closes or still shows the jacket, never the sweater (FAIL); the same by the pad, A on the OUT row then A:
--              S1 again; a second A must not take the sweater off as well (FAIL); DROP by the mouse on the glasses
--              puts them on the floor, the card closes; DROP by the pad on the outer ring of two: that ring on the
--              floor, the other still worn and (S1) the card never turns into the other ring (FAIL)
--   4 belt     a webbing, a double holster, a shoulder holster and an ankle holster worn where their places are free
--              (more slots, past 8 keys): every slot has its row; ATTACH by the mouse opens the slot's list with a
--              hammer in it, picked it hangs there and the row says DETACH; DETACH by the mouse takes it off; pad A on
--              a filled row detaches at once (S5 NOTE); pad X opens the thing's menu, on an empty row the slot's list;
--              a right-click opens the menu; the slot's key puts the hammer in the hand, the row says PUT BACK, PUT
--              BACK puts it back; S4: a flashlight on its webbing slot held in the hand, PUT BACK must put it back
--              and not switch its light (FAIL); the ninth row has no key ("-"); S8, the director's call 6 (Nov 25
--              2026): with Held and Belt folded every belt slot, the empty ones too, keeps its row (FAIL otherwise);
--              the shoulder holster's row names it (Slot from <provider>), then the holster taken off:
--              its row goes and the pistol on it is back in the inventory, off the belt
--   5 doll     a click on a filled box opens its card (after DOUBLE_MS: the director's call 5); S7, call 5: a click or
--              A on an empty slot opens its list of what fits (lastWearMenu; et_calls 5 checks the list itself); a
--              click on an empty belt box opens its attach list; S2: a beanie dropped on the Head box while a hoodie's
--              hood is up must keep the hoodie on with its hood lowered, as the game's Wear does (FAIL); S3, call 9: a
--              hammer dropped on the Main box goes to the main hand (FAIL otherwise; et_calls 9 has the rest); the
--              D-pad from the first filled box reaches every filled box; on the full card the bands show (the rings in their own small slots), on the half card they fold (the rings in Hands)
--   6 defense  for each of the game's 17 parts (and Back, index 17) ZeD's bite, scratch and bullet against the
--              game's getBodyPartClothingDefense (what ISCharacterProtection shows), within 1 (FAIL past it); the
--              average, grade, worst and best zone agree with the per-part numbers; the block shows the same numbers;
--              S11 NOTE (the worst zone named, Back with no tile, the game's 17-part average); pad focus on a part shows
--              that part's bars (equippart:<name>)
--   7 columns  each row's bar is its condition (getCondition / getConditionMax) or how full a held bottle or lighter
--              is (ItemMeter); the Bite, Scratch and Bullet dots one per value above 0 (the protective clothes have
--              theirs); Wt is getUnequippedWeight to one decimal (the row's draws watched for one frame); S6: the SLOT
--              divider dragged wide, then the half card and Large text: no dot, bar or weight past the card's right
--              edge (FAIL)
--   8 states   a T-shirt clean, wet, bloody, dirty, holed, patched and broken (condition 0), each worn and its card
--              opened from its row: the card's zones show it (ItemDetail.getZones: wet, blood, dirt, TORN, the patch's
--              material, condition 0); WASH offered when dirty or bloody and not when clean, REPAIR when holed; S12
--              NOTE: the row's Inspect opens which card
--   9 hands    S9, the director's call 7: a two-handed axe shows in PRI and the doll's Main; SEC keeps it as bothHands
--              and the doll's Off box as offBoth (FAIL otherwise; et_calls 7 checks the drawing); a knife and a hammer in
--              PRI and SEC and the doll's Main and Off; a bag held in the off hand in SEC; a lit hurricane lantern's
--              UNEQUIP from its card leaves no lit lantern in the hand or the inventory (the game's own rule); the
--              watch in WCH and the doll's left wrist
--   10 find    the tank top's name lights its INR#2 row and dims the T-shirt's INR; the Defense block hides; a body
--              part's name keeps the rows that cover it, each with its covers line; the Doll view lights Torso, not
--              Outer; text that matches nothing shows the empty result, Clear empties the field
--   11 setting Worn and held on the Equipment tab: the inventory list ends in the worn line and it opens the tab;
--              Lite: the tab lists the outfit and a card opens; the right-click menu as the strip and as a list opens
--              on a row; each put back
--   12 pad     LB steps the Character window's tabs to Equipment; A on the Equipped heading folds the list and A again
--              opens it; A on a group heading folds it and back; A on the cap's row opens its card with the pad on the
--              card; B goes back and the focus returns to the cap's row
--   13 picture pictures eq_<what>_<w>x<h>: the list and the doll stocked, a layered card, the Defense block, in Dark;
--              the list and the doll in Light and High contrast (a person judges them)
--   14 seated  in a pickup's driver seat, the door and window shut: the card's DROP on a held hammer leaves it in the
--              hand and the DROP is grayed with the game's reason (FAIL otherwise; SKIP when no car can be staged)
--   each case no Lua error over it; put back exactly
-- Already covered elsewhere and not repeated: the heading fold, the right-click menu on a worn row and Find in the List
-- view (rt_inventory 8e); List / Doll and the option, a group's fold, a divider's drag (rt_windows 5); EQUIP from the
-- inventory card and pad A on PRI's full card (rt_cards); HUD belt drags, a cap dropped on the doll, a doll box dragged
-- into a crate (bx_inventory 10); the figure's strain tint (rt_strain, hg_tint); smart attach and the menu guess
-- (lv_calls B, C, O); held and belt things kept out of Transfer all (lv_move).
-- Puts back: the character's own outfit (worn in its order), the hands, the belt's own things on their slots; every
-- thing the test made or the game made from it (a lowered hoodie, an unlit lantern) removed; the Equip view, Worn and
-- held, Lite, the menu's look, the theme and text size; the Equip tab's folds, columns, selection and Find text; the
-- input lock and the pad focus; the windows' width cap and layout (when the half card was forced); the car away, the
-- character where he stood; the Character window's tab and the windows as found.
if not RT then print("ZEDQA eq_tab ERR rt_kit.lua did not run first"); print("ZEDQA eq_tab DONE"); return end
local Q = RT.make("eq_tab")
Q.maxMs = 1500000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, base = {}, baseSet = {}, keptSet = {},
            errs = 0, shots = {}, t0 = getTimestampMs() }
S.F = RT.focus()
S.TOL = 1                            -- (the defense numbers: points of difference allowed)
S.GROUPS = { "head", "torso", "arms", "legs", "held" }
S.DIRS = { "up", "down", "left", "right" }
S.KIND = {
    tank = { "Base.Vest_DefaultTEXTURE_TINT" }, tee = { "Base.Tshirt_DefaultTEXTURE_TINT" },
    sweater = { "Base.Jumper_RoundNeck" }, jacket = { "Base.Jacket_Black" },
    cap = { "Base.Hat_BaseballCap" }, beany = { "Base.Hat_Beany", "Base.Hat_BaseballCap" },
    glasses = { "Base.Glasses_Normal" }, scarf = { "Base.Scarf_StripeBlackWhite" }, necklace = { "Base.Necklace_Gold" },
    gloves = { "Base.Gloves_LeatherGloves" }, watch = { "Base.WristWatch_Left_DigitalBlack" },
    ringL = { "Base.Ring_Left_RingFinger_Gold" }, ringR = { "Base.Ring_Right_RingFinger_Gold" },
    pants = { "Base.Trousers_Denim" }, socks = { "Base.Socks_Ankle" }, shoes = { "Base.Shoes_BlackBoots", "Base.Shoes_TrainerTINT" },
    knee = { "Base.Kneepad_Left_Tactical" },
    hoodieUp = { "Base.HoodieUP_WhiteTINT" },
    webbing = { "Base.Bag_ALICE_BeltSus" }, holsterD = { "Base.HolsterDouble" }, holsterSh = { "Base.HolsterShoulder" },
    holsterAn = { "Base.HolsterAnkle" },
    hammer = { "Base.Hammer" }, torch = { "Base.FlashLight_AngleHead" }, pistol = { "Base.Pistol" },
    axe = { "Base.Axe", "Base.WoodAxe" }, knife = { "Base.HuntingKnife", "Base.KitchenKnife" }, bag = { "Base.Bag_Schoolbag" },
    lantern = { "Base.Lantern_HurricaneLit" }, bottle = { "Base.WaterBottle" }, lighter = { "Base.Lighter" },
    fabric = { "Base.DenimStrips", "Base.RippedSheets" },
}
-- the stocked outfit, put on in this order
S.OUTFIT = { "tank", "tee", "sweater", "jacket", "cap", "glasses", "scarf", "necklace", "gloves", "watch", "ringL", "ringR",
             "pants", "socks", "shoes", "knee" }

-- ===================================================================== small helpers (lv_calls')
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function S.wait(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end
function S.noop() end
function S.list(inv)
    local out = {}
    if inv == nil then return out end
    pcall(function()
        local it = inv:getItems()
        for i = 0, it:size() - 1 do out[#out + 1] = it:get(i) end
    end)
    return out
end
function S.where(it) local c = nil; if it then pcall(function() c = it:getContainer() end) end; return c end
function S.ft(it) local s = "?"; if it then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function S.nm(it) local s = "nothing"; if it then pcall(function() s = tostring(it:getDisplayName()) end) end; return s end
function S.onFloor(it) local wo = nil; if it then pcall(function() wo = it:getWorldItem() end) end; return wo ~= nil end
function S.inv() return S.p:getInventory() end
function S.queueLen()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return (q and q.queue and #q.queue) or 0
end
function S.queueEmpty() return S.queueLen() == 0 end
function S.settled(k)
    local st = { n = 0 }
    return function()
        if S.queueEmpty() then st.n = st.n + 1 else st.n = 0 end
        return st.n >= (k or 8)
    end
end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.instant(on) pcall(function() S.p:setTimedActionInstantCheat(on and true or false) end) end
function S.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function S.setOpt(o, v) if o and v ~= nil then pcall(function() o:setValue(v) end) end end
function S.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function S.guard()
    pcall(function() if not S.p:isGodMod() then S.p:setGodMod(true) end end)
    pcall(function() if not S.p:isInvincible() then S.p:setInvincible(true) end end)
end
function S.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function S.inList(list, x) for _, v in ipairs(list or {}) do if v == x then return true end end; return false end
function S.idsText(t) local o = {}; for _, v in ipairs(t or {}) do o[#o + 1] = tostring(v) end; return (#o > 0) and table.concat(o, ", ") or "none" end
function S.namesOf(items) local o = {}; for _, it in ipairs(items or {}) do o[#o + 1] = S.nm(it) end; return S.idsText(o) end
function S.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = v end
    return o
end
function S.withGlobals(over, fn)
    local was = {}
    for k, v in pairs(over) do was[k] = _G[k]; _G[k] = v end
    local ok, err = pcall(fn)
    for k, v in pairs(was) do _G[k] = v end
    return ok, err
end
-- fields set on objects for the length of fn (list of { object, key, value }), always put back
function S.withFields(list, fn)
    local saved = {}
    for _, e in ipairs(list) do saved[#saved + 1] = { e[1], e[2], rawget(e[1], e[2]) }; e[1][e[2]] = e[3] end
    local ok, err = pcall(fn)
    for i = #saved, 1, -1 do local s = saved[i]; s[1][s[2]] = s[3] end
    return ok, err
end
function S.findField(el, key, depth)
    if type(el) ~= "table" or depth > 8 then return nil end
    if el[key] ~= nil then return el[key] end
    for _, ch in pairs(el.children or {}) do
        local r = S.findField(ch, key, depth + 1)
        if r ~= nil then return r end
    end
    return nil
end
function S.known(ft)
    local ok = false
    if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end
    return ok
end
function S.firstKnown(list) for _, ft in ipairs(list or {}) do if S.known(ft) then return ft end end; return nil end
function S.kind(k) return S.firstKnown(S.KIND[k]) end
function S.normLoc(loc)
    local ls = string.lower(tostring(loc))
    local c = string.find(ls, ":", 1, true)
    if c then ls = string.sub(ls, c + 1) end
    return (string.gsub(ls, "_", ""))
end

-- ===================================================================== things: made, moved, taken away (lv_calls')
function S.loose(it)
    if not it then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() S.p:removeWornItem(it) end)
    pcall(function()
        local hb = getPlayerHotbar(S.pn)
        if hb and hb:isInHotbar(it) then hb:removeItem(it, false) end
    end)
    pcall(function()
        if (it:getAttachedSlot() or -1) > -1 then
            S.p:removeAttachedItem(it)
            it:setAttachedSlot(-1)
            it:setAttachedSlotType(nil)
            it:setAttachedToModel(nil)
        end
    end)
end
function S.removeItem(it)
    if not it then return end
    S.loose(it)
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
function S.put(it, inv)
    if not (it and inv) then return end
    if S.where(it) == inv and not S.onFloor(it) then return end
    S.removeItem(it)
    pcall(function() inv:AddItem(it) end)
end
function S.mark(it)
    if not it then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    S.caseMade[#S.caseMade + 1] = it
    return it
end
function S.give(ft) if not ft then return nil end; local it = RT.give(ft); return S.mark(it) end
function S.make(k) return S.give(S.kind(k)) end

-- ===================================================================== the clothes
function S.wornList()
    local out = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local w = wi:get(i)
            out[#out + 1] = { loc = w:getLocation(), item = w:getItem() }
        end
    end)
    return out
end
function S.wornSet()
    local set = {}
    for _, e in ipairs(S.wornList()) do set[e.item] = true end
    return set
end
function S.isWorn(it)
    if not it then return false end
    local w = false
    pcall(function() w = S.p:isEquippedClothing(it) end)
    return w and true or false
end
function S.locOf(it)
    local loc = nil
    pcall(function() loc = it:getBodyLocation() end)
    if loc == nil or tostring(loc) == "" then loc = nil; pcall(function() loc = it:canBeEquipped() end) end
    if loc ~= nil and tostring(loc) == "" then loc = nil end
    return loc
end
function S.wearIt(it)
    if not it then return false end
    local loc = S.locOf(it)
    if loc then pcall(function() S.p:setWornItem(loc, it) end) end
    return S.isWorn(it)
end
function S.unwear(it)
    if not it then return end
    pcall(function() S.p:removeWornItem(it) end)
    if S.isWorn(it) then pcall(function() S.p:removeWornItem(it, false) end) end
end
-- a worn thing kept on for the run: it gives belt slots, or it is a bag
function S.keeps(it)
    local k = false
    pcall(function() local ap = it:getAttachmentsProvided(); k = ap ~= nil and ap:size() > 0 end)
    if not k then pcall(function() k = it:IsInventoryContainer() == true end) end
    return k
end
function S.keptBack()
    for _, e in ipairs(S.found.kept or {}) do
        if not S.isWorn(e.item) and S.where(e.item) == S.inv() then pcall(function() S.p:setWornItem(e.loc, e.item) end) end
    end
end
function S.eqDirty()
    local w = RT.cw()
    if not w then return end
    w._equipCache = nil
    w._equipProtCache = nil
    w._equipDollTimer = 99
    w._equipDollStale = true
end
function S.wornEvent()
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    pcall(function() S.p:resetModelNextFrame() end)
    S.eqDirty()
end
function S.outfitOff() for _, k in ipairs(S.OUTFIT) do S.unwear(S.base[k]) end end
-- every case's start and end: the stocked outfit on, the kept things on, nothing else worn, the hands empty
function S.outfitBack()
    local inv = S.inv()
    for _, e in ipairs(S.wornList()) do
        if not S.baseSet[e.item] and not S.keptSet[e.item] then S.unwear(e.item) end
    end
    for _, k in ipairs(S.OUTFIT) do
        local it = S.base[k]
        if it then
            if S.where(it) ~= inv or S.onFloor(it) then S.put(it, inv) end
            if not S.isWorn(it) then S.wearIt(it) end
        end
    end
    S.keptBack()
    pcall(function() S.p:setPrimaryHandItem(nil) end)
    pcall(function() S.p:setSecondaryHandItem(nil) end)
    S.wornEvent()
end
function S.wornOfType(prefix)
    local out = {}
    for _, e in ipairs(S.wornList()) do
        local ft = S.ft(e.item)
        if string.sub(ft, 1, #prefix) == prefix then out[#out + 1] = ft end
    end
    return out
end
-- what the test (or the game, from a thing of the test's) left in the main inventory: anything not there at the start
function S.sweepNew()
    local f = S.found
    if not f.inv0 then return end
    for _, it in ipairs(S.list(S.inv())) do
        if not f.inv0[it] and not S.baseSet[it] then S.removeItem(it) end
    end
end

-- ===================================================================== the belt (the game's hotbar)
function S.hb() local hb = nil; pcall(function() hb = getPlayerHotbar(S.pn) end); return hb end
function S.bslots() local s = nil; pcall(function() s = ZeD.Belt.slots(S.pn) end); return s or {} end
function S.bslot(i) for _, s in ipairs(S.bslots()) do if s.i == i then return s end end; return nil end
function S.slotOf(it) local s = -1; if it then pcall(function() s = it:getAttachedSlot() end) end; return s or -1 end
function S.hbSnap()
    local out = {}
    local hb = S.hb()
    for i, it in pairs((hb and hb.attachedItems) or {}) do
        local st, model = nil, nil
        pcall(function() st = hb.availableSlot[i].slotType end)
        pcall(function() model = it:getAttachedToModel() end)
        out[#out + 1] = { item = it, i = i, slotType = st, model = model }
    end
    return out
end
function S.hbBack()
    local hb = S.hb()
    if not hb then return end
    pcall(function() hb:refresh() end)
    for _, e in ipairs(S.found.hb or {}) do
        local on = false
        pcall(function() on = hb:isInHotbar(e.item) end)
        if not on and S.where(e.item) == S.inv() and e.slotType then
            local i = nil
            pcall(function() i = hb:getThisSlotIndex(e.slotType) end)
            local slot = i and hb.availableSlot and hb.availableSlot[i]
            if slot then
                local model = nil
                pcall(function() model = slot.def.attachments[e.item:getAttachmentType()] end)
                model = model or e.model
                pcall(function() hb:attachItem(e.item, model, i, slot.def, false) end)
            end
        end
    end
end
-- the first empty slot that takes it (the game's rule, ZeD.Belt.fits)
function S.emptyFor(it)
    if not it then return nil end
    local hb = S.hb()
    for _, s in ipairs(S.bslots()) do
        local fits = false
        pcall(function() fits = ZeD.Belt.fits(hb, s.i, it) end)
        if not s.item and fits then return s.i end
    end
    return nil
end
-- the first empty slot that takes it, else a slot lent for the case: its own thing comes off into the main inventory
-- (S.hbBack puts it back at the case's clean, as lv_move's hotBorrow lends one)
function S.emptyOrLend(it, what)
    local i = S.emptyFor(it)
    if i or not it then return i end
    local hb = S.hb()
    if not (hb and hb.availableSlot and hb.attachedItems) then return nil end
    for j, slot in pairs(hb.availableSlot) do
        local old = hb.attachedItems[j]
        local okA, can = pcall(function() return hb:canBeAttached(slot, it) end)
        if old and old ~= it and okA and can then
            pcall(function() hb:removeItem(old, false) end)
            pcall(function() hb:refresh() end)
            local on = true
            pcall(function() on = hb:isInHotbar(old) end)
            if not on then
                Q.say("NOTE " .. tostring(what) .. ": belt slot " .. tostring(j) .. " lent for the case (its " .. S.nm(old) .. " off into the bag, back at the end)")
                return j
            end
        end
    end
    return nil
end
function S.emptyAny() for _, s in ipairs(S.bslots()) do if not s.item then return s.i end end; return nil end

-- ===================================================================== the menu (lv_calls')
function S.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
function S.menuUp()
    if S.menu() then return true end
    local up = false
    pcall(function() local c = getPlayerContextMenu(S.pn); up = c ~= nil and c:getIsVisible() and #(c.options or {}) > 0 end)
    return up and true or false
end
function S.closeMenu()
    local m = S.menu()
    if m then pcall(function() m:close() end) end
    pcall(function() local v = getPlayerContextMenu(S.pn); if v then v:hideAndChildren() end end)
end
function S.same(a, b) return a == b or string.lower(tostring(a)) == string.lower(tostring(b)) end
function S.pick(m, names)
    if not m then return false, "no menu" end
    if m._levels then
        for depth, nm in ipairs(names) do
            local lv = m._levels[depth]
            if not lv then return false, "no level " .. depth end
            local ri = nil
            for k, r in ipairs(lv.rows or {}) do if r.def and not ri and S.same(r.def.name, nm) then ri = k end end
            if not ri then return false, "no row " .. tostring(nm) end
            lv.sel = ri
            m:confirm(depth)
        end
        return true, "picked"
    end
    for _, nm in ipairs(names) do
        local items = m._ctx.items or m:_currentItems()
        local idx = nil
        for i, d in ipairs(items) do if not idx and d and S.same(d.name, nm) then idx = i end end
        if not idx then return false, "no cell " .. tostring(nm) end
        m._ctx.selected = idx
        m:confirm()
    end
    return true, "picked"
end
-- a row of the menu picked: ZeD's menu when it shows one, else the game's option run as its click runs it
function S.pickOpt(name)
    local m = S.menu()
    if m then
        local ok, why = false, "the pick threw"
        pcall(function() ok, why = S.pick(m, { name }) end)
        if ok then return true, why end
    end
    local done, why = false, "no option " .. tostring(name)
    pcall(function()
        local c = getPlayerContextMenu(S.pn)
        for _, o in ipairs(c.options or {}) do
            if not done and S.same(o.name, name) and o.onSelect then
                o.onSelect(o.target, o.param1, o.param2, o.param3, o.param4)
                done, why = true, "picked (the game's option)"
            end
        end
    end)
    return done, why
end
function S.menuNames(m)
    local out = {}
    local function walk(defs)
        for _, d in ipairs(defs or {}) do
            out[#out + 1] = tostring(d.name)
            if d.children then walk(d.children) end
        end
    end
    walk(m and m._ctx and m._ctx.actions)
    pcall(function()
        local c = getPlayerContextMenu(S.pn)
        for _, o in ipairs(c.options or {}) do out[#out + 1] = tostring(o.name) end
    end)
    return out
end

-- ===================================================================== pictures (lv_calls')
function S.park(on)
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
function S.shot(name, what)
    Q.step(1, function() if not S.dead then S.park(true) end end)
    Q.step(4, function()
        if S.dead then S.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then S.shots[#S.shots + 1] = file; Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
        S.park(false)
    end)
    Q.waitMs(1500)
end
function S.caseEnd(label)
    Q.step(1, function()
        if S.dead then return end
        S.cancelDrags()
        S.closeMenu()
        local e1 = S.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, label .. ": no Lua error over the case",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        S.e0 = e1
    end)
end

-- ===================================================================== the theme and the text size (lv_calls')
S.THEMES = { { key = "dark", word = "Dark" }, { key = "light", word = "Light" }, { key = "hicon", word = "High contrast" } }
function S.theme(key)
    local o = S.zopt("baseTheme")
    local i = nil
    for k, v in ipairs(ZeD.Settings.baseKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.back.theme = true
end
function S.themeBack()
    if not S.back.theme then return end
    S.back.theme = nil
    local o = S.zopt("baseTheme")
    if o and S.found.baseIdx then pcall(function() o:setValue(S.found.baseIdx) end) end
    pcall(ZeD.applyTheme, S.found.base, nil, nil)
end
function S.sizeSet(key)
    local o = S.zopt("textSize")
    local i = nil
    for k, v in ipairs(ZeD.Settings.sizeKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, nil, nil, key)
    S.back.size = true
end
function S.sizeBack()
    if not S.back.size then return end
    S.back.size = nil
    local f = S.found
    local o = S.zopt("textSize")
    if o and f.sizeIdx then pcall(function() o:setValue(f.sizeIdx) end) end
    pcall(ZeD.applyTheme, nil, nil, f.size)
end

-- ===================================================================== the pad (lv_calls')
function S.lockFound()
    local key = nil
    pcall(function()
        local o = S.zopt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
function S.padOn()
    local Det = ZeD.Input and ZeD.Input.Detector
    if not (Det and Det.setLockedMode) then return false end
    if S.lockWas == nil then S.lockWas = S.lockFound() end
    pcall(Det.setLockedMode, "gamepad")
    S.back.pad = true
    local w = RT.cw()
    if w and S.F and S.F.claimFocus then pcall(S.F.claimFocus, w) end
    return true
end
function S.padOff()
    if not S.back.pad then return end
    S.back.pad = nil
    for _, b in ipairs({ "A", "B", "X", "Y", "LeftBump", "RightBump" }) do RT.pad(b, nil) end
    pcall(function() S.F.releaseFocus(S.pn) end)
    local Det = ZeD.Input and ZeD.Input.Detector
    pcall(function()
        Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
    end)
end
function S.focused(w)
    local z, el = nil, nil
    pcall(function() z = S.F.getFocusedZone(w); el = S.F.getFocusedElement(w) end)
    return z, el
end
function S.focusedId() local _, el = S.focused(RT.cw()); return el and el.id or nil end
-- the pad's focus put on the Equip tab's stop with this id (charTabContent: the tab and its card)
function S.focusEl(id)
    local w = RT.cw()
    if not (w and S.F and S.F.focusWhere and id) then return false end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "charTabContent", function(el) return el.id == id end) end)
    return e ~= nil
end
-- a tap queued: the QA hook holds the button, FocusManager's dispatch takes the press on the window, up after 4
-- frames, then the hook lets go (nothing is pressed when gate says no: a case that could not stage its focus)
function S.tap(name, joy, gate)
    local st = {}
    S.step(1, function()
        local w = RT.cw()
        if not w then return end
        if gate and not gate() then return end
        st.on = true
        RT.pad(name, true)
        if joy then RT.padDown(Joypad[joy], w) end
    end)
    S.step(4, function() if st.on then RT.pad(name, false) end end)
    S.step(4, function() if st.on then RT.pad(name, nil) end end)
end
function S.tapA(gate) S.tap("A", "AButton", gate) end
function S.tapB(gate) S.tap("B", "BButton", gate) end
function S.tapX(gate) S.tap("X", "XButton", gate) end

-- ===================================================================== the Equip tab
function S.w() return RT.cw() end
function S.dp() local w = RT.cw(); return w and w._drawerPanel end
function S.ep() local w = RT.cw(); return w and (w._equipPanel or w._drawerPanel) end
function S.ecard()
    local p = S.ep()
    local c = p and p._equipCard
    if c then return c end
    local w = RT.cw()
    return w and S.findField(w, "_equipCard", 0) or nil
end
function S.cardItem()
    local w, c = RT.cw(), S.ecard()
    if not (w and w._equipSelected and c) then return nil end
    local vis = false
    pcall(function() vis = c:isVisible() end)
    return vis and c.item or nil
end
function S.cardOn(item) local ci = S.cardItem(); return ci ~= nil and (item == nil or ci == item) end
function S.cardClose()
    local w = RT.cw()
    if w then w._equipSelected = nil end
end
function S.cardVerbIdx(id)
    local c = S.ecard()
    for i, v in ipairs((c and c._lastHeaderVerbs) or {}) do if v.id == id then return i, v end end
    return nil, nil
end
function S.cardIds()
    local out = {}
    local c = S.ecard()
    for _, v in ipairs((c and c._lastHeaderVerbs) or {}) do out[#out + 1] = tostring(v.id) end
    return table.concat(out, " ")
end
-- a click on the card's verb, as the card's pointer poll takes it: the button down over the verb, then up
function S.cardClick(id)
    local c = S.ecard()
    local i = S.cardVerbIdx(id)
    local r = i and c._backBarRects and c._backBarRects.verbs and c._backBarRects.verbs[i]
    if not r then return false, "no " .. tostring(id) .. " on the card (" .. S.cardIds() .. ")" end
    local x, y = c:getAbsoluteX() + r.x + math.floor(r.w / 2), c:getAbsoluteY() + r.y + math.floor(r.h / 2)
    local mx, my = function() return x end, function() return y end
    local ok1, e1 = S.withGlobals({ getMouseX = mx, getMouseY = my, isMouseButtonDown = function() return true end }, function() c:_pointer() end)
    local ok2, e2 = S.withGlobals({ getMouseX = mx, getMouseY = my, isMouseButtonDown = function() return false end }, function() c:_pointer() end)
    if not (ok1 and ok2) then S.errs = S.errs + 1; return false, "the press threw: " .. tostring(e1 or e2) end
    return true, "pressed " .. tostring(id)
end
function S.slotZone(item)
    local w = RT.cw()
    if not item then return nil end
    for _, z in ipairs((w and w._equipSlotZones) or {}) do if z.item == item then return z end end
    return nil
end
function S.zoneT(ty)
    local w = RT.cw()
    for _, z in ipairs((w and w._equipSlotZones) or {}) do if z.type == ty then return z end end
    return nil
end
function S.beltZone(i)
    local w = RT.cw()
    for _, z in ipairs((w and w._equipBeltZones) or {}) do if z.i == i then return z end end
    return nil
end
function S.rect(id)
    local w = RT.cw()
    for _, r in ipairs((w and w._equipDollAll) or {}) do if r.id == id then return r end end
    return nil
end
function S.mid(z) return z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2) end
-- a press and release on the drawer at (x, y), its own handlers (rt_windows' X.clickAt)
function S.clickAt(x, y)
    local dp = S.dp()
    if not dp then return false, "no drawer" end
    local ok, e = pcall(function() dp:onMouseDown(x, y); dp:onMouseUp(x, y) end)
    if not ok then S.errs = S.errs + 1 end
    return ok, e
end
function S.clickZone(z) if not z then return false, "no zone" end; local x, y = S.mid(z); return S.clickAt(x, y) end
function S.rclickZone(z)
    local dp = S.dp()
    if not (dp and z) then return false end
    local x, y = S.mid(z)
    local ok = pcall(function() dp:onRightMouseDown(x, y); dp:onRightMouseUp(x, y) end)
    if not ok then S.errs = S.errs + 1 end
    return ok
end
function S.beltClick(i)
    local z = S.beltZone(i)
    if not (z and z.btn) then return false, "no row for slot " .. tostring(i) end
    return S.clickZone(z.btn)
end
function S.cancelDrags()
    pcall(function() local w = RT.cw(); if w and w._equipDrag then w._equipDrag:cancel() end; if w then w._equipPress = nil; w._equipColDrag = nil end end)
    pcall(function() local dp = S.dp(); if dp then dp:setCapture(false) end end)
    pcall(function() ISMouseDrag.dragging = nil end)
end
function S.isHalf() local w = RT.cw(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(220)) <= 1 end
function S.isFull() local w = RT.cw(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(480)) <= 1 end
function S.eqReady(view)
    local w = RT.cw()
    if not (w and w._activeTab == "equip" and w._drawerOpen ~= false and w._equipDefenseZone ~= nil) then return false end
    if w._equipSelected then return false end
    if view == "doll" then return w._equipDollShown == true and w._equipDollAll ~= nil end
    return #(w._equipGroupZones or {}) > 0
end
-- queue: the Equip tab on its view, the list open, every group open, at the top, the drawer settled
function S.toEquip(view, T, label)
    S.step(2, function()
        if T.off then return end
        local w = RT.cw()
        if w then w._equipSelected = nil end
        if ZeD.EquipDoll.view() ~= view then pcall(ZeD.EquipDoll.setView, view) end
        RT.charTab("equip")
        w = RT.cw()
        if w then
            w._equipListExpanded = true
            w._equipExpanded = w._equipExpanded or {}
            for _, g in ipairs(S.GROUPS) do w._equipExpanded[g] = true end
            if w._equipScroll then pcall(function() w._equipScroll:setScrollPos(0) end) end
        end
        S.eqDirty()
        T.eqSt = { last = -1, n = 0 }
    end)
    S.wait(4, 600, function()
        if T.off then return true end
        if not S.eqReady(view) then return false end
        local e = math.floor(RT.cw()._drawerEffW or 0)
        if e == T.eqSt.last then T.eqSt.n = T.eqSt.n + 1 else T.eqSt.last, T.eqSt.n = e, 0 end
        return T.eqSt.n >= 4
    end, function(ok)
        if T.off then return end
        local w = RT.cw()
        if not Q.check(ok, label .. ": the Equipment tab shows its " .. view .. " view",
            "tab " .. tostring(w and w._activeTab) .. ", view " .. tostring(ZeD.EquipDoll.view()) .. ", drawer " .. tostring(w and math.floor(w._drawerEffW or 0))) then
            T.off = true
        end
    end)
end
-- queue: a row's card opened by the mouse (itemFn names the thing when the step runs); T[key] true once it is open
function S.openRow(T, key, itemFn, label)
    S.step(2, function()
        T[key] = nil
        T[key .. "It"] = nil
        if T.off then return end
        S.cardClose()
        T[key .. "It"] = itemFn()
    end)
    S.wait(2, 90, function() return T.off or T[key .. "It"] == nil or S.slotZone(T[key .. "It"]) ~= nil end, function(ok)
        if T.off then return end
        local it = T[key .. "It"]
        if it == nil then T[key .. "Row"] = nil; return end   -- (nothing to open: the case said why)
        T[key .. "Row"] = Q.check(ok, label .. ": the row of " .. S.nm(it) .. " is drawn on the tab")
        if T[key .. "Row"] then S.clickZone(S.slotZone(it)) end
    end)
    -- (one click opens the card once ZeD.EquipmentTab.DOUBLE_MS is up, the director's call 5: a second click inside it
    -- takes the thing off instead; et_calls 5 checks both)
    S.wait(2, 150, function() return T.off or not T[key .. "Row"] or S.cardOn(T[key .. "It"]) end, function(ok)
        if T.off or not T[key .. "Row"] then return end
        T[key] = Q.check(ok, label .. ": a click on its row opens its card (after DOUBLE_MS)", "the card shows " .. S.nm(S.cardItem()))
    end)
end
-- queue: a row's card opened by the pad (focus on its stop, A)
function S.openRowPad(T, key, itemFn, label)
    S.step(2, function()
        T[key] = nil
        T[key .. "It"] = nil
        T[key .. "Row"] = nil
        if T.off then return end
        S.cardClose()
        local it = itemFn()
        T[key .. "It"] = it
        if it == nil then Q.skip(label, "the thing to open is not there"); return end
        local z = S.slotZone(it)
        T[key .. "Row"] = z ~= nil and S.padOn() and S.focusEl("equipslot:" .. tostring(z.type))
        Q.check(T[key .. "Row"], label .. ": the pad's focus lands on the row of " .. S.nm(it), "on " .. tostring(S.focusedId()))
    end)
    S.tapA(function() return T[key .. "Row"] end)
    S.wait(2, 120, function() return T.off or not T[key .. "Row"] or S.cardOn(T[key .. "It"]) end, function(ok)
        if T.off or not T[key .. "Row"] then return end
        T[key] = Q.check(ok, label .. ": A on its row opens its card", "the card shows " .. S.nm(S.cardItem()))
    end)
end
-- the pad's focus on the card's verb (its stop equipcard:hverb_<n>)
function S.focusVerb(id)
    local i = S.cardVerbIdx(id)
    if not i then return false end
    return S.focusEl("equipcard:hverb_" .. i)
end

-- ===================================================================== a frame's draws watched (the rows' bars, dots, weights)
function S.spyOn()
    if S.spy then return end
    local A = ZeD.Atoms
    local sp = { A = A, fill = A.drawFillBar, dot = A.drawStatusDot, txr = A.drawTextRight, fills = {}, dots = {}, txts = {}, panel = S.ep() }
    S.spy = sp
    sp.myFill = function(panel, x, y, w, f, ...)
        if panel == sp.panel then sp.fills[#sp.fills + 1] = { x = x, y = y, w = w, f = f } end
        return sp.fill(panel, x, y, w, f, ...)
    end
    sp.myDot = function(panel, x, y, color, size, ...)
        if panel == sp.panel then sp.dots[#sp.dots + 1] = { x = x, y = y, c = color, s = size or 0 } end
        return sp.dot(panel, x, y, color, size, ...)
    end
    sp.myTxr = function(panel, text, x, y, ...)
        if panel == sp.panel then sp.txts[#sp.txts + 1] = { t = text, x = x, y = y } end
        return sp.txr(panel, text, x, y, ...)
    end
    A.drawFillBar, A.drawStatusDot, A.drawTextRight = sp.myFill, sp.myDot, sp.myTxr
end
function S.spyOff()
    local sp = S.spy
    if not sp then return nil end
    S.spy = nil
    local A = sp.A
    if A.drawFillBar == sp.myFill then A.drawFillBar = sp.fill end
    if A.drawStatusDot == sp.myDot then A.drawStatusDot = sp.dot end
    if A.drawTextRight == sp.myTxr then A.drawTextRight = sp.txr end
    return sp
end

-- ===================================================================== setup
function S.dressBase()
    local missing = {}
    for _, k in ipairs(S.OUTFIT) do
        local ft = S.kind(k)
        local it = ft and RT.give(ft) or nil
        if it then
            pcall(function() it:getModData().ZeDQA_spawned = true end)
            S.made[#S.made + 1] = it
            S.base[k] = it
            S.baseSet[it] = true
            S.wearIt(it)
        else
            missing[#missing + 1] = k
        end
    end
    return missing
end
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.err0 = S.errN()
        S.e0 = S.err0
        f.pair = RT.isOpen()
        f.world = false
        pcall(function() f.world = ZeD_WorldWindow.isOpen(S.pn) and true or false end)
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "eq_tab") end
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat() end)
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.worn = S.wornList()
        f.hb = S.hbSnap()
        f.inv0 = {}
        for _, it in ipairs(S.list(S.inv())) do f.inv0[it] = true end
        f.view = ZeD.EquipDoll and ZeD.EquipDoll.view() or "list"
        f.wornOpt = S.optVal(ZeD.Settings and ZeD.Settings.wornListOption)
        f.ctx = S.optVal(ZeD.Settings and ZeD.Settings.contextStyleOption)
        f.style = S.optVal(ZeD.Settings and ZeD.Settings.lookStyleOption)
        f.base, f.baseIdx = ZeD.currentBase, S.optVal(S.zopt("baseTheme"))
        f.size, f.sizeIdx = ZeD.currentSize, S.optVal(S.zopt("textSize"))
        if ZEDQA_LAYOUT_SNAP and f.pair then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        f.recorded = true
        S.back.on = true
        S.guard()
        RT.pairOpen()
        S.instant(true)
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", " .. #f.worn .. " worn, " .. #f.hb
            .. " on the belt, Equip view " .. tostring(f.view) .. ", worn list " .. tostring(f.wornOpt) .. ", menu look "
            .. tostring(f.ctx) .. ", Style " .. tostring(f.style) .. ", theme " .. tostring(f.base) .. ", text "
            .. tostring(f.size) .. ", input lock " .. S.lockFound() .. ", screen " .. S.sizeTag())
    end)
    S.step(30, function()
        local w = RT.cw()
        if not Q.check(w ~= nil, "setup: the Character window is open") then S.dead = true; return end
        if not Q.check(ZeD.EquipmentTab and ZeD.EquipmentTab.gatherData and ZeD.EquipDoll and ZeD.EquipDoll.gather and ZeD.ProtectionTab
            and ZeD.Belt and ZeD.Belt.slots and S.F and S.F.focusWhere, "setup: the Equip tab's modules and the pad's focus manager are loaded") then S.dead = true; return end
        local f = S.found
        f.charTab = w._activeTab
        f.listExp, f.exp, f.colW = w._equipListExpanded, S.copy(w._equipExpanded), S.copy(w._equipColWidths)
        -- the character's own outfit aside: the belt-givers and the bags stay on
        f.kept = {}
        for _, e in ipairs(f.worn) do
            if S.keeps(e.item) then
                f.kept[#f.kept + 1] = e
                S.keptSet[e.item] = true
            else
                S.unwear(e.item)
            end
        end
        pcall(function() S.p:setPrimaryHandItem(nil) end)
        pcall(function() S.p:setSecondaryHandItem(nil) end)
        local miss = S.dressBase()
        S.keptBack()
        S.wornEvent()
        f.missing = miss
    end)
    S.step(10, function()
        local n = 0
        for _, k in ipairs(S.OUTFIT) do if S.isWorn(S.base[k]) then n = n + 1 end end
        Q.check(n == #S.OUTFIT, "setup: the stocked outfit is worn (" .. #S.OUTFIT .. " pieces), the character's own kept aside",
            n .. " worn; not made: " .. S.idsText(S.found.missing) .. "; kept on: " .. #(S.found.kept or {}))
        if n < 8 then S.dead = true end
    end)
end

-- every case: what it made goes, the outfit back on, nothing open
function S.caseStart()
    S.caseMade = {}
    S.closeMenu()
    S.cardClose()
end
function S.caseClean()
    S.padOff()
    S.spyOff()
    S.cancelDrags()
    S.closeMenu()
    S.cardClose()
    pcall(function() local w = RT.cw(); if w then w._equipDefHoveredPart = nil end end)
    for _, it in ipairs(S.caseMade) do S.removeItem(it) end
    S.caseMade = {}
    S.sweepNew()
    S.outfitBack()
    local hb = S.hb()
    if hb then pcall(function() hb:refresh() end) end
    S.hbBack()
end

-- ===================================================================== 1. every body location placed in both views
S.NOT_GARMENT = { bandage = true, wound = true, zeddmg = true }
S.NOWHERE_OK = { legs5 = "the game marks it unused (BodyLocations.lua)" }
S.LOC_FALLBACK = { back = "Base.Bag_Schoolbag", satchel = "Base.Bag_Satchel", fannypackfront = "Base.Bag_FannyPackFront",
                   fannypackback = "Base.Bag_FannyPackBack", webbing = "Base.Bag_ALICE_BeltSus", shoulderholster = "Base.HolsterShoulder" }
-- one item kind for each body location (the first the script manager lists)
function S.locKinds()
    local out = {}
    local all, n = nil, 0
    pcall(function() all = getScriptManager():getAllItems(); n = all:size() end)
    for i = 0, n - 1 do
        local si, bl, fn, obs = nil, nil, nil, false
        pcall(function() si = all:get(i); bl = si:getBodyLocation() end)
        if bl ~= nil then
            pcall(function() fn = si:getFullName() end)
            pcall(function() obs = si:getObsolete() == true end)
            local k = S.normLoc(bl)
            if fn and not obs and k ~= "" and out[k] == nil then out[k] = fn end
        end
    end
    for k, ft in pairs(S.LOC_FALLBACK) do if out[k] == nil and S.known(ft) then out[k] = ft end end
    return out
end
function S.listWhere(data, it)
    for _, g in ipairs((data and data.groups) or {}) do
        for _, s in ipairs(g.slots or {}) do if s.item == it then return s.type, g.id end end
    end
    return nil, nil
end
function S.dollWhere(data, it)
    if not (data and it) then return nil end
    for id, s in pairs(data.slots or {}) do for _, x in ipairs(s.items or {}) do if x == it then return id end end end
    for id, s in pairs(data.small or {}) do for _, x in ipairs(s.items or {}) do if x == it then return id end end end
    if data.main == it then return "main" end
    if data.off == it then return "off" end
    return nil
end
function S.placeOne(T, L)
    local r = { key = L.key }
    T.res[#T.res + 1] = r
    if S.NOT_GARMENT[L.key] or string.sub(L.key, 1, 6) == "makeup" then r.skip = "not a garment"; return end
    local ft = T.kinds[L.key]
    if not ft then r.skip = "no item goes there"; return end
    r.ft = ft
    local it = S.give(ft)
    if not it then r.skip = "the item could not be made"; return end
    pcall(function() S.p:setWornItem(L.id, it) end)
    if not S.isWorn(it) then r.skip = "the game would not wear " .. ft .. " there"; S.removeItem(it); S.keptBack(); return end
    local ok, err = pcall(function()
        local data = ZeD.EquipmentTab.gatherData(S.p)
        r.list, r.group = S.listWhere(data, it)
        r.dollB = S.dollWhere(ZeD.EquipDoll.gather(S.p, S.pn, true), it)
        r.dollF = S.dollWhere(ZeD.EquipDoll.gather(S.p, S.pn, false), it)
    end)
    if not ok then r.err = tostring(err); S.errs = S.errs + 1 end
    S.removeItem(it)
    S.keptBack()
end
function S.case1Report(T, ok)
    local miss, oneView, notes, skipped, placed, lines = {}, {}, {}, {}, 0, {}
    for _, r in ipairs(T.res) do
        if r.skip then skipped[#skipped + 1] = r.key .. " (" .. r.skip .. ")"
        elseif r.err then miss[#miss + 1] = r.key .. " (the gather threw " .. r.err .. ")"
        else
            local inL, inB, inF = r.list ~= nil, r.dollB ~= nil, r.dollF ~= nil
            lines[#lines + 1] = r.key .. "=" .. tostring(r.list) .. "/" .. tostring(r.dollB) .. "/" .. tostring(r.dollF)
            if inL and inB and inF then placed = placed + 1
            elseif S.NOWHERE_OK[r.key] then
                notes[#notes + 1] = r.key .. ": list " .. tostring(r.list) .. ", doll " .. tostring(r.dollB) .. " / " .. tostring(r.dollF) .. " (" .. S.NOWHERE_OK[r.key] .. ")"
            elseif not inL and not inB and not inF then miss[#miss + 1] = r.key .. " (" .. tostring(r.ft) .. ")"
            else oneView[#oneView + 1] = r.key .. ": list " .. tostring(r.list) .. ", doll with the bands " .. tostring(r.dollB) .. ", folded " .. tostring(r.dollF) end
        end
    end
    Q.check(ok and #miss == 0, "1 places: every body location a garment can be worn at shows in a list row and a doll slot (" .. placed .. " placed)",
        (#miss == 0) and (#T.res .. " locations walked") or ("in neither view: " .. table.concat(miss, "; ")))
    Q.check(#oneView == 0, "1 places: nothing worn shows in one view and is missing from the other (the doll with its bands and folded)",
        (#oneView == 0) and "none" or table.concat(oneView, "; "))
    for _, s in ipairs(notes) do Q.say("NOTE 1 places, shown nowhere, as the map says: " .. s) end
    Q.say("NOTE 1 places, walked without an item: " .. S.idsText(skipped))
    for i = 1, #lines, 12 do
        local chunk = {}
        for j = i, math.min(#lines, i + 11) do chunk[#chunk + 1] = lines[j] end
        Q.say("NOTE 1 places (location=list/doll with bands/doll folded): " .. table.concat(chunk, " "))
    end
    for _, key in ipairs({ "underwearbottom", "torsoextravest", "vesttexture", "gorget", "shoulderholster", "legs5" }) do
        for _, r in ipairs(T.res) do
            if r.key == key then
                Q.say("NOTE 1 places, where the views differ (map section 3): " .. key .. " is the list's " .. tostring(r.list)
                    .. " (" .. tostring(r.group) .. "), the doll's " .. tostring(r.dollB) .. " with the bands and " .. tostring(r.dollF)
                    .. " folded" .. (r.skip and (" [" .. r.skip .. "]") or ""))
            end
        end
    end
end
function S.case1()
    local T = { res = {}, i = 0 }
    S.step(2, function()
        S.caseStart()
        local g = nil
        pcall(function() g = BodyLocations.getGroup("Human") end)
        if not g then T.off = true; Q.skip("1 places", "the game's body locations (BodyLocations.getGroup) cannot be read here"); return end
        T.locs = {}
        local n = 0
        pcall(function() n = g:size() end)
        for i = 0, n - 1 do
            local id = nil
            pcall(function() id = g:getLocationByIndex(i):getId() end)
            if id ~= nil then T.locs[#T.locs + 1] = { id = id, key = S.normLoc(id) } end
        end
        T.kinds = S.locKinds()
        S.outfitOff()
        Q.say("1 places: " .. #T.locs .. " body locations in the game's Human group, walked bare (the kept belt and bags stay on)")
    end)
    S.wait(1, 900, function()
        if T.off then return true end
        for _ = 1, 4 do
            T.i = T.i + 1
            local L = T.locs[T.i]
            if not L then return true end
            S.placeOne(T, L)
        end
        return false
    end, function(ok)
        if T.off then return end
        S.case1Report(T, ok)
    end)
    S.step(2, function() S.caseClean() end)
    S.caseEnd("1 places")
end

-- ===================================================================== 2. layers
function S.case2()
    local T = {}
    S.step(2, function() S.caseStart() end)
    S.toEquip("list", T, "2 layers")
    S.step(4, function()
        if T.off then return end
        local B = S.base
        local data = ZeD.EquipmentTab.gatherData(S.p)
        local want = { { "INR", B.tee }, { "INR#2", B.tank }, { "OUT", B.jacket }, { "OUT#2", B.sweater }, { "SOC", B.socks }, { "BOT", B.shoes } }
        local bad = {}
        for _, pr in ipairs(want) do
            if pr[2] then
                local t = S.listWhere(data, pr[2])
                if t ~= pr[1] then bad[#bad + 1] = S.nm(pr[2]) .. " in " .. tostring(t) .. " (want " .. pr[1] .. ")" end
            end
        end
        local r1, r2 = S.listWhere(data, B.ringL), S.listWhere(data, B.ringR)
        local rings = (r1 == "RNG" and r2 == "RNG#2") or (r1 == "RNG#2" and r2 == "RNG")
        if not rings then bad[#bad + 1] = "the rings in " .. tostring(r1) .. " and " .. tostring(r2) end
        Q.check(#bad == 0, "2 layers, list: the outermost layer has the slot's row and each layer under it a row of its own (INR then INR#2, OUT then OUT#2, two RNG rows); socks and boots their own rows",
            (#bad == 0) and "as wanted" or table.concat(bad, "; "))
        local miss = {}
        for _, ty in ipairs({ "INR", "INR#2", "OUT", "OUT#2", "RNG", "RNG#2", "SOC", "BOT" }) do if not S.zoneT(ty) then miss[#miss + 1] = ty end end
        local zi, zi2, zo, zo2 = S.zoneT("INR"), S.zoneT("INR#2"), S.zoneT("OUT"), S.zoneT("OUT#2")
        Q.check(#miss == 0 and zi ~= nil and zi2 ~= nil and zi.y < zi2.y and zo ~= nil and zo2 ~= nil and zo.y < zo2.y,
            "2 layers, list: every layer row is drawn, each layer right under the one over it",
            (#miss == 0) and "drawn" or ("not drawn: " .. S.idsText(miss)))
    end)
    S.toEquip("doll", T, "2 layers")
    S.step(4, function()
        if T.off then return end
        local w = RT.cw()
        local B = S.base
        local d = ZeD.EquipDoll.gather(S.p, S.pn, true)
        local fd = ZeD.EquipDoll.gather(S.p, S.pn, false)
        local function n(data, id) local s = data.slots[id]; return s and #s.items or 0 end
        local function first(data, id) local s = data.slots[id]; return s and s.items[1] or nil end
        Q.check(n(d, "torso") == 2 and n(d, "outer") == 2 and n(d, "feet") == 2,
            "2 layers, doll: Torso holds 2 layers (tank top, T-shirt), Outer 2 (sweater, jacket), Feet 2 (socks, boots)",
            "torso " .. n(d, "torso") .. ", outer " .. n(d, "outer") .. ", feet " .. n(d, "feet"))
        Q.check(first(d, "outer") == B.jacket and first(d, "torso") == B.tee and first(d, "feet") == B.shoes,
            "2 layers, doll: each box leads with its outermost layer (the jacket, the T-shirt, the boots)",
            S.nm(first(d, "outer")) .. ", " .. S.nm(first(d, "torso")) .. ", " .. S.nm(first(d, "feet")))
        Q.check(n(fd, "hands") == 3, "2 layers, doll folded (the half card): Hands holds the gloves and both rings as 3 layers",
            "hands " .. n(fd, "hands") .. "; on show the bands are " .. tostring(w._equipDollBands))
        T.outer = S.zoneT("doll:outer")
        if not Q.check(T.outer ~= nil, "2 layers, doll: the Outer box is drawn with the jacket") then T.off = true; return end
        S.clickZone(T.outer)
    end)
    S.wait(2, 120, function() return T.off or S.cardOn(S.base.jacket) end, function(ok)
        if T.off then return end
        T.card = Q.check(ok, "2 layers, doll: a click on the Outer box opens the jacket's card (the outermost)", "the card shows " .. S.nm(S.cardItem()))
    end)
    S.step(4, function()
        if not T.card then return end
        local w = RT.cw()
        local zin, zout = nil, nil
        for _, z in ipairs(w._equipLayerZones or {}) do if z.dir == 1 then zin = z elseif z.dir == -1 then zout = z end end
        T.zin, T.zout = zin, zout
        Q.check(zin ~= nil and zout ~= nil and zin.enabled and not zout.enabled and w._equipLayer == 1,
            "2 layers, the card's layer strip: layer 1 of 2, Inner on and Outer off",
            "layer " .. tostring(w._equipLayer) .. ", Inner " .. tostring(zin and zin.enabled) .. ", Outer " .. tostring(zout and zout.enabled))
        if zin then S.clickZone(zin) end
    end)
    S.wait(2, 60, function() return not T.card or S.cardOn(S.base.sweater) end, function(ok)
        if not T.card then return end
        Q.check(ok, "2 layers, the layer strip by the mouse: Inner shows the sweater under the jacket", "the card shows " .. S.nm(S.cardItem()))
        local zout = nil
        for _, z in ipairs(RT.cw()._equipLayerZones or {}) do if z.dir == -1 then zout = z end end
        if zout then S.clickZone(zout) end
    end)
    S.wait(2, 60, function() return not T.card or S.cardOn(S.base.jacket) end, function(ok)
        if not T.card then return end
        Q.check(ok, "2 layers, the layer strip by the mouse: Outer shows the jacket again", "the card shows " .. S.nm(S.cardItem()))
        T.pIn = S.padOn() and S.focusEl("equipcard:__layer_1")
        Q.check(T.pIn, "2 layers, the layer strip by the pad: the focus lands on Inner (equipcard:__layer_1)", "on " .. tostring(S.focusedId()))
    end)
    S.tapA(function() return T.pIn end)
    S.wait(2, 60, function() return not T.pIn or S.cardOn(S.base.sweater) end, function(ok)
        if not T.pIn then return end
        Q.check(ok, "2 layers, the layer strip by the pad: A on Inner shows the sweater", "the card shows " .. S.nm(S.cardItem()))
        T.pOut = S.focusEl("equipcard:__layer_-1")
    end)
    S.tapA(function() return T.pOut end)
    S.wait(2, 60, function() return not T.pOut or S.cardOn(S.base.jacket) end, function(ok)
        if T.pOut then Q.check(ok, "2 layers, the layer strip by the pad: A on Outer shows the jacket again", "the card shows " .. S.nm(S.cardItem())) end
    end)
    S.tapB(function() return T.pIn end)
    S.wait(2, 90, function() return not T.pIn or (S.cardItem() == nil and S.focusedId() == "equipslot:doll:outer") end, function(ok)
        if T.pIn then
            Q.check(ok, "2 layers, the pad: B leaves the card and the focus returns to the Outer box it came from",
                "card " .. S.nm(S.cardItem()) .. ", focus on " .. tostring(S.focusedId()))
        end
    end)
    S.step(2, function() S.caseClean() end)
    S.caseEnd("2 layers")
end

-- ===================================================================== 3. UNEQUIP and DROP from the tab (S1)
function S.case3()
    local T = {}
    local B = S.base
    S.step(2, function() S.caseStart() end)
    S.toEquip("list", T, "3 off")
    -- 3a the cap, the mouse, UNEQUIP
    S.openRow(T, "a", function() return B.cap end, "3a off (mouse)")
    S.step(6, function()
        if not T.a then return end
        local ids = S.cardIds()
        -- (the director's call 8 adds OFF HAND and TWO HANDS to an equipped weapon's card only: et_calls 8)
        Q.check(S.cardVerbIdx("UNEQUIP") ~= nil and S.cardVerbIdx("DROP") ~= nil and S.cardVerbIdx("MORE") ~= nil
            and S.cardVerbIdx("OFF HAND") == nil and S.cardVerbIdx("TWO HANDS") == nil,
            "3a off: the worn cap's card offers UNEQUIP, DROP and MORE (no hand buttons: it is no weapon)", ids)
        RT.bounds(Q, "the Equip tab's card")
        local ok, why = S.cardClick("UNEQUIP")
        T.a = Q.check(ok, "3a off: UNEQUIP pressed on the cap's card (the mouse)", why)
    end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(30, function()
        if not T.a then return end
        Q.check(not S.isWorn(B.cap) and S.where(B.cap) == S.inv(), "3a off: UNEQUIP takes the cap off into the inventory",
            "worn " .. tostring(S.isWorn(B.cap)))
        Q.check(S.cardItem() == nil, "3a off: with the slot empty the card closes", "the card shows " .. S.nm(S.cardItem()))
    end)
    -- 3b the jacket over the sweater, the mouse (S1)
    S.step(2, function() S.cardClose(); S.outfitBack() end)
    S.openRow(T, "b", function() return B.jacket end, "3b off (mouse, layered)")
    S.step(6, function()
        if not T.b then return end
        local ok, why = S.cardClick("UNEQUIP")
        T.b = Q.check(ok, "3b off: UNEQUIP pressed on the jacket's card (the mouse)", why)
    end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(30, function()
        if not T.b then return end
        local ci = S.cardItem()
        Q.check(not S.isWorn(B.jacket) and S.isWorn(B.sweater), "3b off: UNEQUIP takes the jacket off and leaves the sweater under it on",
            "jacket worn " .. tostring(S.isWorn(B.jacket)) .. ", sweater worn " .. tostring(S.isWorn(B.sweater)))
        Q.check(ci == nil or ci == B.jacket, "3b S1: after UNEQUIP of the outer layer the card closes or still shows the jacket it named, never the sweater under it",
            "the card shows " .. (ci and S.nm(ci) or "nothing (closed)"))
        S.cardClose()
    end)
    -- 3c the same by the pad: A on the OUT row, A on UNEQUIP, then A again (S1)
    S.step(4, function() S.outfitBack() end)
    S.step(20, S.noop)
    S.openRowPad(T, "c", function() return B.jacket end, "3c off (pad, layered)")
    S.step(4, function()
        if not T.c then return end
        Q.say("NOTE 3c: the jacket's card opened with the pad on " .. tostring(S.focusedId()))
        local i = S.cardVerbIdx("UNEQUIP")
        if S.focusedId() ~= ("equipcard:hverb_" .. tostring(i)) then T.c = S.focusVerb("UNEQUIP") end
        Q.check(T.c, "3c off: the pad's focus is on the card's UNEQUIP", "on " .. tostring(S.focusedId()))
    end)
    S.tapA(function() return T.c end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(30, function()
        if not T.c then return end
        local ci = S.cardItem()
        Q.check(not S.isWorn(B.jacket) and S.isWorn(B.sweater), "3c off: A on UNEQUIP takes the jacket off, the sweater stays on",
            "jacket worn " .. tostring(S.isWorn(B.jacket)) .. ", sweater worn " .. tostring(S.isWorn(B.sweater)))
        Q.check(ci == nil or ci == B.jacket, "3c S1: after A on UNEQUIP the card closes or still shows the jacket, never the sweater",
            "the card shows " .. (ci and S.nm(ci) or "nothing (closed)") .. ", the pad on " .. tostring(S.focusedId()))
    end)
    S.tapA(function() return T.c end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(30, function()
        if not T.c then return end
        Q.check(S.isWorn(B.sweater), "3c S1: a second A, as a player presses A, A, does not take the sweater off as well",
            "sweater worn " .. tostring(S.isWorn(B.sweater)) .. ", the card shows " .. S.nm(S.cardItem()))
        S.padOff()
        S.cardClose()
    end)
    -- 3d DROP by the mouse on the glasses
    S.step(4, function() S.outfitBack() end)
    S.openRow(T, "d", function() return B.glasses end, "3d drop (mouse)")
    S.step(6, function()
        if not T.d then return end
        local ok, why = S.cardClick("DROP")
        T.d = Q.check(ok, "3d drop: DROP pressed on the glasses' card (the mouse)", why)
    end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(30, function()
        if not T.d then return end
        Q.check(not S.isWorn(B.glasses) and S.onFloor(B.glasses), "3d drop: DROP takes the glasses off and puts them on the floor",
            "worn " .. tostring(S.isWorn(B.glasses)) .. ", on the floor " .. tostring(S.onFloor(B.glasses)))
        Q.check(S.cardItem() == nil, "3d drop: with the slot empty the card closes", "the card shows " .. S.nm(S.cardItem()))
    end)
    -- 3e DROP by the pad on the outer of two rings (S1)
    S.step(4, function()
        S.outfitBack()
    end)
    S.step(20, function()
        local z = S.zoneT("RNG")
        T.ring = z and z.item
        T.other = (T.ring == B.ringL) and B.ringR or B.ringL
    end)
    S.openRowPad(T, "e", function() return T.ring end, "3e drop (pad, layered)")
    S.step(4, function()
        if not T.e then return end
        T.e = S.focusVerb("DROP")
        Q.check(T.e, "3e drop: the pad's focus is on the card's DROP", "on " .. tostring(S.focusedId()))
    end)
    S.tapA(function() return T.e end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(30, function()
        if not T.e then return end
        local ci = S.cardItem()
        Q.check(S.onFloor(T.ring) and S.isWorn(T.other), "3e drop: A on DROP puts the outer ring on the floor, the other ring stays on",
            "dropped " .. tostring(S.onFloor(T.ring)) .. ", the other worn " .. tostring(S.isWorn(T.other)))
        Q.check(ci == nil or ci == T.ring, "3e S1: after DROP the card closes or still shows the ring it named, never the other ring",
            "the card shows " .. (ci and S.nm(ci) or "nothing (closed)"))
    end)
    S.step(2, function() S.caseClean() end)
    S.caseEnd("3 off")
end

-- ===================================================================== 4. the belt rows (S4, S5, S8)
function S.case4stage(T)
    S.step(2, function()
        S.caseStart()
        T.hb = S.hb()
        if not (T.hb and ZeD.Belt and ZeD.Belt.slots and ZeD.Belt.attach) then T.off = true; Q.skip("4 belt", "the game's hotbar or ZeD's belt is not loaded"); return end
        T.n0 = #S.bslots()
        T.added = {}
        for _, k in ipairs({ "webbing", "holsterD", "holsterSh", "holsterAn" }) do
            local it = S.make(k)
            if it then
                local loc = S.locOf(it)
                local free = false
                pcall(function() free = loc ~= nil and S.p:getWornItem(loc) == nil end)
                if free and S.wearIt(it) then T.added[#T.added + 1] = it; T[k] = it else S.removeItem(it) end
            end
        end
        S.wornEvent()
        T.ham, T.torch, T.gun = S.make("hammer"), S.make("torch"), S.make("pistol")
        -- (its own name: the slot list names every hammer in the bag alike, and the pick goes by name)
        if T.ham then pcall(function() T.ham:setName("QA Claw Hammer") end); pcall(function() T.ham:setCustomName(true) end) end
    end)
    S.step(6, function() if not T.off then pcall(function() T.hb:refresh() end) end end)
    S.toEquip("list", T, "4 belt")
    S.step(4, function()
        if T.off then return end
        local sl = S.bslots()
        Q.say("NOTE 4 belt: " .. #sl .. " belt slots (" .. T.n0 .. " before; worn for the case: " .. S.namesOf(T.added) .. ")")
        T.iHam = S.emptyOrLend(T.ham, "4 belt, the hammer")
        local miss = {}
        for _, s in ipairs(sl) do if not S.beltZone(s.i) then miss[#miss + 1] = tostring(s.i) end end
        Q.check(#sl > 0 and #miss == 0, "4 belt: with Held and Belt open every belt slot has its row (" .. #sl .. ")",
            (#miss == 0) and "all drawn" or ("no row for " .. S.idsText(miss)))
    end)
end
function S.case4attach(T)
    -- 4a ATTACH by the mouse: the slot's list, the hammer picked
    S.step(2, function()
        T.a = nil
        if T.off then return end
        if not (T.iHam and T.ham) then Q.skip("4a ATTACH", "no empty belt slot takes a hammer on this character"); return end
        local z = S.beltZone(T.iHam)
        T.a = z ~= nil and z.action == "attach"
        if not Q.check(T.a, "4a belt: the empty slot's row offers ATTACH", z and tostring(z.action) or "no row") then return end
        S.closeMenu()
        S.beltClick(T.iHam)
    end)
    S.wait(2, 60, function() return not T.a or S.menuUp() end, function(ok)
        if not T.a then return end
        local names = S.menuNames(S.menu())
        T.a = Q.check(ok and S.inList(names, S.nm(T.ham)), "4a belt: ATTACH opens the slot's list with the hammer in it", S.idsText(names))
        if T.a then
            local okP, why = S.pickOpt(S.nm(T.ham))
            T.a = Q.check(okP, "4a belt: the hammer picked from the slot's list", why)
        end
        S.closeMenu()
    end)
    S.wait(4, 600, function() return not T.a or (S.queueEmpty() and S.slotOf(T.ham) == T.iHam) end, function(ok)
        if not T.a then return end
        T.a = Q.check(ok, "4a belt: the hammer hangs on that slot (the game's attach)", "slot " .. S.slotOf(T.ham) .. ", wanted " .. tostring(T.iHam))
    end)
    S.step(20, function()
        if not T.a then return end
        local z = S.beltZone(T.iHam)
        Q.check(z ~= nil and z.item == T.ham and z.action == "detach", "4a belt: its row now names the hammer and offers DETACH",
            z and (S.nm(z.item) .. ", " .. tostring(z.action)) or "no row")
        local s = S.bslot(T.iHam)
        local prov = nil
        pcall(function() prov = ZeD.Belt.provider(S.p, s.slot.slotType) end)
        Q.say("NOTE 4a belt: the hammer's slot " .. tostring(s and s.slot and s.slot.slotType) .. " reads \"from " .. (prov and S.nm(prov) or "always there") .. "\" on its second line")
        -- 4c DETACH by the mouse
        S.beltClick(T.iHam)
    end)
    S.wait(4, 600, function() return not T.a or (S.queueEmpty() and S.slotOf(T.ham) < 0) end, function(ok)
        if not T.a then return end
        Q.check(ok and S.where(T.ham) == S.inv(), "4c belt: DETACH takes the hammer off the belt into the inventory", "slot " .. S.slotOf(T.ham))
    end)
    S.step(20, function()
        if not T.a then return end
        local z = S.beltZone(T.iHam)
        Q.check(z ~= nil and z.item == nil and z.action == "attach", "4c belt: the emptied row offers ATTACH again", z and tostring(z.action) or "no row")
    end)
end
function S.case4pad(T)
    -- 4d pad A on a filled row: DETACH at once (S5)
    S.step(2, function()
        T.d = nil
        if T.off or not T.iHam then return end
        T.d = ZeD.Belt.attach(S.pn, T.ham, T.iHam)
    end)
    S.wait(4, 600, function() return not T.d or (S.queueEmpty() and S.slotOf(T.ham) == T.iHam) end, function(ok)
        if not T.d then return end
        T.d = ok and S.padOn() and S.focusEl("equipbelt:" .. T.iHam)
        Q.check(T.d, "4d belt: the hammer is on its slot again and the pad's focus is on its row", "on " .. tostring(S.focusedId()))
    end)
    S.tapA(function() return T.d end)
    S.wait(4, 600, function() return not T.d or (S.queueEmpty() and S.slotOf(T.ham) < 0) end, function(ok)
        if not T.d then return end
        Q.check(ok, "4d belt: pad A on a filled belt row runs DETACH", "slot " .. S.slotOf(T.ham))
        Q.say("NOTE 4d S5: pad A on a belt row acts at once (DETACH, PUT BACK or the ATTACH list); on a worn row A opens the card first. A card opened here: " .. tostring(S.cardItem() ~= nil))
    end)
    -- 4e pad X: the hammer's menu; on an empty row the slot's list
    S.step(20, function()
        T.x = nil
        if T.off or not T.iHam then return end
        T.x = ZeD.Belt.attach(S.pn, T.ham, T.iHam)
    end)
    S.wait(4, 600, function() return not T.x or (S.queueEmpty() and S.slotOf(T.ham) == T.iHam) end, function(ok)
        if not T.x then return end
        S.closeMenu()
        T.x = ok and S.focusEl("equipbelt:" .. T.iHam)
    end)
    S.tapX(function() return T.x end)
    S.wait(2, 60, function() return not T.x or S.menuUp() end, function(ok)
        if T.x then Q.check(ok, "4e belt: pad X on a filled belt row opens the thing's menu", S.idsText(S.menuNames(S.menu()))) end
        S.closeMenu()
        local e = S.emptyAny()
        T.xe = e ~= nil and S.focusEl("equipbelt:" .. e)
        if not e then Q.skip("4e belt, X on an empty row", "every belt slot is filled") end
    end)
    S.tapX(function() return T.xe end)
    S.wait(2, 60, function() return not T.xe or S.menuUp() end, function(ok)
        if T.xe then Q.check(ok, "4e belt: pad X on an empty belt row opens the slot's list", S.idsText(S.menuNames(S.menu()))) end
        S.closeMenu()
        S.padOff()
        -- 4f a right-click on the hammer's row
        T.f = T.x and S.slotOf(T.ham) == T.iHam and S.beltZone(T.iHam) ~= nil
        if T.f then S.rclickZone(S.beltZone(T.iHam)) end
    end)
    S.wait(2, 60, function() return not T.f or S.menuUp() end, function(ok)
        if T.f then Q.check(ok, "4f belt: a right-click on a filled belt row opens a menu", S.idsText(S.menuNames(S.menu()))) end
        S.closeMenu()
    end)
end
function S.case4putBack(T)
    -- 4g the slot's key puts the hammer in the hand; PUT BACK puts it back
    S.step(4, function()
        T.g = nil
        if T.off or not (T.iHam and S.slotOf(T.ham) == T.iHam) then return end
        T.g = true
        pcall(function() T.hb:activateSlot(T.iHam) end)
    end)
    S.wait(4, 600, function() return not T.g or (S.queueEmpty() and S.p:getPrimaryHandItem() == T.ham) end, function(ok)
        if not T.g then return end
        T.g = Q.check(ok and S.slotOf(T.ham) == T.iHam, "4g belt: the slot's key puts the hammer in the hand, still on its slot",
            "in the hand " .. S.nm(S.p:getPrimaryHandItem()) .. ", slot " .. S.slotOf(T.ham))
    end)
    S.step(20, function()
        if not T.g then return end
        local z = S.beltZone(T.iHam)
        T.g = Q.check(z ~= nil and z.action == "putback", "4g belt: the row of the hammer in the hand offers PUT BACK", z and tostring(z.action) or "no row")
        if T.g then S.beltClick(T.iHam) end
    end)
    S.wait(4, 600, function() return not T.g or (S.queueEmpty() and S.p:getPrimaryHandItem() ~= T.ham) end, function(ok)
        if T.g then
            Q.check(ok and S.slotOf(T.ham) == T.iHam, "4g belt: PUT BACK puts the hammer back on its slot, the hand empty",
                "in the hand " .. S.nm(S.p:getPrimaryHandItem()) .. ", slot " .. S.slotOf(T.ham))
        end
    end)
    -- 4h S4: a flashlight on its webbing slot, held: PUT BACK must not switch its light
    S.step(4, function()
        T.t = nil
        if T.off then return end
        if T.torch and not T.iTorch then T.iTorch = S.emptyOrLend(T.torch, "4h belt, the flashlight") end
        if not (T.iTorch and T.torch) then Q.skip("4h S4 PUT BACK on a held flashlight", "no belt slot takes the angle-head flashlight here, even lent (it needs a webbing slot)"); return end
        T.t = ZeD.Belt.attach(S.pn, T.torch, T.iTorch)
    end)
    S.wait(4, 600, function() return not T.t or (S.queueEmpty() and S.slotOf(T.torch) == T.iTorch) end, function(ok)
        if not T.t then return end
        T.t = Q.check(ok, "4h belt: the flashlight hangs on its webbing slot", "slot " .. S.slotOf(T.torch) .. ", wanted " .. tostring(T.iTorch))
        if not T.t then return end
        pcall(function() T.torch:setActivated(false) end)
        pcall(function() S.p:setPrimaryHandItem(T.torch) end)
        S.eqDirty()
    end)
    S.step(20, function()
        if not T.t then return end
        local z = S.beltZone(T.iTorch)
        T.t = Q.check(z ~= nil and z.action == "putback", "4h belt: the flashlight in the hand and on its slot: its row offers PUT BACK", z and tostring(z.action) or "no row")
        if not T.t then return end
        T.lit0 = false
        pcall(function() T.lit0 = T.torch:isActivated() end)
        S.beltClick(T.iTorch)
    end)
    S.wait(4, 600, S.settled(10), S.noop)
    S.step(10, function()
        if not T.t then return end
        local lit = false
        pcall(function() lit = T.torch:isActivated() end)
        local held = S.p:getPrimaryHandItem() == T.torch
        Q.check(not held and lit == T.lit0, "4h S4: PUT BACK on a held flashlight puts it back on the belt and leaves its light as it was",
            "still in the hand " .. tostring(held) .. ", light " .. tostring(T.lit0) .. " -> " .. tostring(lit) .. ", slot " .. S.slotOf(T.torch))
        pcall(function() T.torch:setActivated(false) end)
        pcall(function() if S.p:getPrimaryHandItem() == T.torch then S.p:setPrimaryHandItem(nil) end end)
    end)
end
function S.case4slots(T)
    -- 4j keys past 8
    S.step(4, function()
        if T.off then return end
        local sl = S.bslots()
        if #sl < 9 then Q.skip("4j belt keys past 8", "only " .. #sl .. " belt slots on this character with the case's holsters"); return end
        local s9 = sl[9]
        Q.check(s9.key == nil and S.beltZone(s9.i) ~= nil, "4j belt: the ninth slot has its row and no key of its own (its key box reads \"-\")",
            "key " .. tostring(s9.key) .. ", row " .. tostring(S.beltZone(s9.i) ~= nil))
    end)
    -- 4k S8: Held and Belt folded
    S.step(2, function()
        if T.off then return end
        local w = RT.cw()
        w._equipExpanded.held = false
    end)
    S.step(6, function()
        if T.off then return end
        local w = RT.cw()
        local sl = S.bslots()
        local filled = 0
        for _, s in ipairs(sl) do if s.item then filled = filled + 1 end end
        -- (the director's call 6, Nov 25 2026: every belt slot keeps its row while folded; it was S8, a NOTE that the
        -- empty slots hid. et_calls 6 has the same check against the hotbar's slot count.)
        local miss = {}
        for _, s in ipairs(sl) do if not S.beltZone(s.i) then miss[#miss + 1] = tostring(s.i) .. (s.item and " (filled)" or " (empty)") end end
        Q.check(#sl > 0 and #miss == 0 and #(w._equipBeltZones or {}) == #sl,
            "4k S8: with Held and Belt folded every belt slot, filled and empty, keeps its row (the director's call 6)",
            #(w._equipBeltZones or {}) .. " belt rows of " .. #sl .. " slots (" .. filled .. " filled)" .. ((#miss > 0) and ("; no row for " .. S.idsText(miss)) or ""))
        w._equipExpanded.held = true
    end)
    -- 4i the shoulder holster's slot, then the holster taken off
    S.step(4, function()
        T.h = nil
        if T.off then return end
        if not (T.holsterSh and T.gun) then Q.skip("4i belt, a slot from a worn holster", "no shoulder holster could be worn for the case (its place is taken)"); return end
        local i = nil
        for _, s in ipairs(S.bslots()) do if s.slot and s.slot.slotType == "HolsterShoulder" then i = s.i end end
        T.iH = i
        if not i then Q.skip("4i belt, a slot from a worn holster", "the shoulder holster gives no slot here"); return end
        local prov = nil
        pcall(function() prov = ZeD.Belt.provider(S.p, "HolsterShoulder") end)
        Q.check(prov == T.holsterSh, "4i belt: the shoulder holster's slot says it comes from the holster (its row's \"from\" line)", "from " .. S.nm(prov))
        T.h = ZeD.Belt.attach(S.pn, T.gun, i)
        if not T.h then Q.skip("4i belt, the holster taken off", "the pistol does not fit the shoulder holster's slot") end
    end)
    S.wait(4, 600, function() return not T.h or (S.queueEmpty() and S.slotOf(T.gun) == T.iH) end, function(ok)
        if not T.h then return end
        T.h = Q.check(ok, "4i belt: the pistol hangs on the holster's slot", "slot " .. S.slotOf(T.gun))
        if not T.h then return end
        S.unwear(T.holsterSh)
        S.wornEvent()
        pcall(function() T.hb:refresh() end)
    end)
    S.step(20, function()
        if not T.h then return end
        local still = false
        for _, s in ipairs(S.bslots()) do if s.slot and s.slot.slotType == "HolsterShoulder" then still = true end end
        local rows = 0
        for _, z in ipairs(RT.cw()._equipBeltZones or {}) do rows = rows + 1 end
        Q.check(not still and S.slotOf(T.gun) < 0 and S.where(T.gun) == S.inv() and rows == #S.bslots(),
            "4i belt: the holster taken off, its slot's row goes and the pistol is back in the inventory, off the belt",
            "slot still there " .. tostring(still) .. ", pistol slot " .. S.slotOf(T.gun) .. ", rows " .. rows .. " of " .. #S.bslots())
    end)
end
function S.case4()
    local T = {}
    S.case4stage(T)
    S.case4attach(T)
    S.case4pad(T)
    S.case4putBack(T)
    S.case4slots(T)
    S.step(2, function() S.caseClean() end)
    S.step(10, function() S.hbBack() end)
    S.caseEnd("4 belt")
end

-- ===================================================================== 5. the doll (S2, S3, S7)
-- a drop on the doll at its box r: the doll's drop taker, the pointer answered as over the box
function S.dropOnDoll(r, item)
    local w = RT.cw()
    local panel = w and w._equipDollPanel
    if not (panel and r and item) then return false, "the doll or its box is not drawn" end
    local x, y = r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2)
    local took = false
    local ok, err = S.withFields({ { panel, "getMouseX", function() return x end }, { panel, "getMouseY", function() return y end } },
        function() took = ZeD.EquipDoll.takeDrop(S.pn, { item }) end)
    if not ok then S.errs = S.errs + 1; return false, "the drop threw: " .. tostring(err) end
    return took and true or false, "takeDrop answered " .. tostring(took)
end
function S.case5basic(T)
    S.step(2, function() S.caseStart() end)
    S.toEquip("doll", T, "5 doll")
    -- 5a a filled box opens its card
    S.step(4, function()
        T.a = nil
        if T.off then return end
        local z = S.zoneT("doll:head")
        T.a = Q.check(z ~= nil and z.item == S.base.cap, "5a doll: the cap shows in the Head box", z and S.nm(z.item) or "no Head box")
        if T.a then S.clickZone(z) end
    end)
    S.wait(2, 120, function() return not T.a or S.cardOn(S.base.cap) end, function(ok)
        if T.a then
            Q.check(ok, "5a doll: a click on a filled box opens its card", "the card shows " .. S.nm(S.cardItem()))
            RT.bounds(Q, "the doll's card")
        end
        S.cardClose()
    end)
    -- 5b an empty slot (S7)
    S.step(6, function()
        T.e = nil
        if T.off then return end
        local e = (RT.cw()._equipDollEmpty or {})[1]
        if not e then Q.skip("5b doll, an empty slot", "the doll shows no empty slot"); return end
        T.e = { type = e.type, x = e.x, y = e.y, w = e.w, h = e.h }
        S.closeMenu()
        ZeD.EquipmentTab.lastWearMenu = nil
        S.clickZone(T.e)
    end)
    -- (S7 was a NOTE that an empty slot took no press; the director's call 5, Nov 25 2026: a press or A on an empty
    -- slot opens the list of what the player carries that fits it. et_calls 5 checks the list's count and the pick.)
    S.wait(2, 90, function() return not T.e or S.menuUp() end, function(ok)
        if not T.e then return end
        local lw = ZeD.EquipmentTab.lastWearMenu
        Q.check(ok and RT.cw()._equipSelected == nil and lw ~= nil and lw.key == T.e.type,
            "5b doll S7: a click on an empty slot opens its list of what fits (no card; the director's call 5)",
            T.e.type .. ": menu up " .. tostring(S.menuUp()) .. ", lastWearMenu " .. tostring(lw and lw.key) .. " n " .. tostring(lw and lw.n)
            .. ", selected " .. tostring(RT.cw()._equipSelected))
        S.closeMenu()
        ZeD.EquipmentTab.lastWearMenu = nil
        T.pe = S.padOn() and S.focusEl("equipslot:" .. T.e.type)
        if not T.pe then Q.say("NOTE 5b doll: the pad's focus could not be put on the empty slot " .. T.e.type .. " (on " .. tostring(S.focusedId()) .. ")") end
    end)
    S.tapA(function() return T.pe end)
    S.wait(2, 90, function() return not T.pe or S.menuUp() end, function(ok)
        if T.pe then
            local lw = ZeD.EquipmentTab.lastWearMenu
            Q.check(ok and RT.cw()._equipSelected == nil and lw ~= nil and lw.key == T.e.type, "5b doll S7: A on an empty slot opens the same list",
                "menu up " .. tostring(S.menuUp()) .. ", lastWearMenu " .. tostring(lw and lw.key) .. ", selected " .. tostring(RT.cw()._equipSelected))
        end
        S.padOff()
        S.closeMenu()
    end)
    -- 5c an empty belt box: its attach list
    S.step(4, function()
        T.bz = nil
        if T.off then return end
        for _, z in ipairs(RT.cw()._equipBeltZones or {}) do if not z.item and not T.bz then T.bz = z end end
        if not T.bz then Q.skip("5c doll, an empty belt box", "no empty belt box under the doll"); return end
        S.clickZone(T.bz.btn)
    end)
    S.wait(2, 60, function() return not T.bz or S.menuUp() end, function(ok)
        if T.bz then Q.check(ok, "5c doll: a click on an empty belt box opens its attach list", S.idsText(S.menuNames(S.menu()))) end
        S.closeMenu()
    end)
end
function S.case5drops(T)
    -- 5d S2: a beanie dropped on the Head box while a hoodie's hood is up
    S.step(4, function()
        T.h = nil
        if T.off then return end
        S.cardClose()
        local up, hat = S.kind("hoodieUp"), S.kind("beany")
        if not (up and hat) then Q.skip("5d S2", "no hoodie with its hood up or no hat is known"); return end
        for _, k in ipairs({ "cap", "jacket", "sweater" }) do S.unwear(S.base[k]) end
        T.hoodie = S.give(up)
        S.wearIt(T.hoodie)
        T.hat = S.give(hat)
        S.wornEvent()
        T.h = S.isWorn(T.hoodie) and S.where(T.hat) == S.inv()
        if not T.h then Q.skip("5d S2", "the hoodie with its hood up could not be worn here") end
    end)
    S.wait(6, 120, function() return not T.h or (S.eqReady("doll") and S.rect("head") ~= nil) end, function(ok)
        if not T.h then return end
        local res, why = S.dropOnDoll(S.rect("head"), T.hat)
        T.hd = Q.check(ok and res, "5d doll: the beanie dropped on the Head box is taken (the doll's drop taker)", why)
    end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(10, function()
        if not T.hd then return end
        local hoodies = S.wornOfType("Base.Hoodie")
        local hatOn = S.isWorn(T.hat)
        Q.check(hatOn and #hoodies > 0, "5d S2: a hat dropped on the doll while a hoodie's hood is up lowers the hood and keeps the hoodie on, as the game's Wear does (onWearItems)",
            "beanie worn " .. tostring(hatOn) .. ", hoodies worn: " .. S.idsText(hoodies))
    end)
    -- 5e S3: a hammer dropped on the Main box
    S.step(4, function()
        T.m = nil
        if T.off then return end
        S.caseClean()
        T.hammer = S.make("hammer")
        local w = RT.cw()
        if w._equipScroll and w._equipScroll.visible then pcall(function() w._equipScroll:setScrollPos(1) end) end
        T.m = T.hammer ~= nil
    end)
    S.step(10, function()
        if not T.m then return end
        local w = RT.cw()
        local mz = nil
        for _, z in ipairs(w._equipDollEmpty or {}) do if z.type == "doll:main" then mz = z end end
        if not mz then T.m = nil; Q.skip("5e S3", "the doll's Main box is not drawn empty"); return end
        local panel = w._equipDollPanel
        local x, y = S.mid(mz)
        local took = false
        local ok = S.withFields({ { panel, "getMouseX", function() return x end }, { panel, "getMouseY", function() return y end } },
            function() took = ZeD.EquipDoll.takeDrop(S.pn, { T.hammer }) end)
        if not ok then S.errs = S.errs + 1 end
        T.mTook = took
    end)
    S.wait(4, 600, S.settled(10), S.noop)
    S.step(6, function()
        if not T.m then return end
        -- (S3 was a NOTE that the hand boxes took no drop; the director's call 9, Nov 25 2026: a weapon dropped on the
        -- Main box goes to the main hand. et_calls 9 checks Off, a two-handed weapon and a non-weapon too.)
        Q.check(T.mTook == true and S.p:getPrimaryHandItem() == T.hammer, "5e S3: a hammer dropped on the doll's Main box goes to the main hand (the director's call 9)",
            "the drop taker answered " .. tostring(T.mTook) .. ", the main hand holds " .. S.nm(S.p:getPrimaryHandItem()))
        local w = RT.cw()
        if w._equipScroll then pcall(function() w._equipScroll:setScrollPos(0) end) end
    end)
end
function S.case5pad(T)
    -- 5f the D-pad from the first filled box reaches every filled box
    S.step(10, function()
        T.bfs = nil
        if T.off then return end
        local w = RT.cw()
        if not S.eqReady("doll") then Q.skip("5f doll D-pad", "the doll is not on show"); return end
        T.want = {}
        for _, z in ipairs(w._equipSlotZones or {}) do T.want[#T.want + 1] = "equipslot:" .. tostring(z.type) end
        local first = T.want[1]
        if not (first and S.padOn() and S.focusEl(first)) then Q.skip("5f doll D-pad", "the pad's focus could not be put on the first filled box"); return end
        T.bfs = { seen = { [first] = true }, q = { first }, qi = 1, d = 1, moves = 0 }
    end)
    S.wait(2, 1500, function()
        local B = T.bfs
        if not B then return true end
        for _ = 1, 6 do
            local id = B.q[B.qi]
            if not id then return true end
            S.focusEl(id)
            RT.padDir(S.DIRS[B.d], RT.cw())
            B.moves = B.moves + 1
            local nid = S.focusedId()
            if nid and string.sub(nid, 1, 15) == "equipslot:doll:" and not B.seen[nid] then B.seen[nid] = true; B.q[#B.q + 1] = nid end
            B.d = B.d + 1
            if B.d > 4 then B.d = 1; B.qi = B.qi + 1 end
        end
        return false
    end, function(ok)
        if not T.bfs then return end
        local miss = {}
        for _, id in ipairs(T.want) do if not T.bfs.seen[id] then miss[#miss + 1] = id end end
        Q.check(ok and #miss == 0, "5f doll: the D-pad's moves, from the first filled box, reach every filled box (" .. #T.want .. ")",
            T.bfs.moves .. " moves, " .. #T.bfs.q .. " stops reached; not reached: " .. S.idsText(miss))
        S.padOff()
    end)
    -- 5g the bands: on at the full card, folded at the half card
    S.step(4, function()
        if T.off then return end
        local w = RT.cw()
        T.fullBands = { full = S.isFull(), bands = w._equipDollBands }
        if S.isFull() then
            local d = w._equipDollData
            local inSmall = d and d.small and d.small.lring and d.small.lring.items[1] == S.base.ringL
            Q.check(w._equipDollBands == true and inSmall, "5g doll, the full card: the bands of small slots show, the left ring in its own slot",
                "bands " .. tostring(w._equipDollBands) .. ", left ring in its small slot " .. tostring(inSmall))
        else
            Q.say("NOTE 5g doll: the drawer is not the full card here (" .. math.floor(w._drawerEffW or 0) .. " px): the bands " .. tostring(w._equipDollBands))
        end
    end)
    S.halfOn(T)
    S.step(10, function()
        if T.off then return end
        local w = RT.cw()
        if not T.half then Q.skip("5g doll, the half card", "the half card could not be brought about"); return end
        local d = w._equipDollData
        local hands = d and d.slots and d.slots.hands and d.slots.hands.items or {}
        Q.check(w._equipDollBands == false and S.inList(hands, S.base.ringL), "5g doll, the half card: the bands fold, the rings are layers of Hands",
            "bands " .. tostring(w._equipDollBands) .. ", Hands holds " .. S.namesOf(hands))
        RT.bounds(Q, "the doll at the half card")
    end)
    S.halfOff(T)
end
function S.case5()
    local T = {}
    S.case5basic(T)
    S.case5drops(T)
    S.case5pad(T)
    S.step(2, function() S.caseClean() end)
    S.caseEnd("5 doll")
end

-- the half card brought about: the window's width cap made too narrow for the full card beside the inventory (the
-- drawer's own rule, getTargetDrawerW); put back by S.halfOff and the layout put back at the end
function S.halfOn(T)
    S.step(2, function()
        T.half = nil
        if T.off then return end
        local w = RT.cw()
        if not S.isHalf() and w then
            if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
            S.layoutTouched = true
            w._maxWinW = ZeD.T.px(700)
        end
        T.hs = { last = -1, n = 0 }
    end)
    S.wait(4, 900, function()
        if T.off then return true end
        local w = RT.cw()
        local e = math.floor((w and w._drawerEffW) or 0)
        if e == T.hs.last then T.hs.n = T.hs.n + 1 else T.hs.last, T.hs.n = e, 0 end
        return T.hs.n >= 6 and S.isHalf()
    end, function(ok)
        if T.off then return end
        T.half = ok
        if not ok then Q.say("NOTE the half card could not be brought about here (the drawer is " .. math.floor(RT.cw()._drawerEffW or 0) .. " px)") end
    end)
end
function S.halfBack()
    if not S.back.maxW then return end
    local w = RT.cw()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end
function S.halfOff(T)
    S.step(2, function() S.halfBack() end)
    S.wait(4, 900, function()
        local w = RT.cw()
        local e = math.floor((w and w._drawerEffW) or 0)
        T.hs2 = T.hs2 or { last = -1, n = 0 }
        if e == T.hs2.last then T.hs2.n = T.hs2.n + 1 else T.hs2.last, T.hs2.n = e, 0 end
        return T.hs2.n >= 6
    end, function() T.hs2 = nil end)
end

-- ===================================================================== 6. the Defense block against the game (S11)
function S.round(x) local r = nil; pcall(function() r = luautils.round(x) end); if r == nil then r = math.floor(x + 0.5) end; return math.floor(r) end
-- the game's numbers for part index i (ISCharacterProtection's read): bite, scratch, bullet
function S.gameDef(i)
    local b, s, u = nil, nil, nil
    pcall(function() b = S.round(S.p:getBodyPartClothingDefense(i, true, false)) end)
    pcall(function() s = S.round(S.p:getBodyPartClothingDefense(i, false, false)) end)
    pcall(function() u = S.round(S.p:getBodyPartClothingDefense(i, false, true)) end)
    return b, s, u
end
function S.case6compare(T)
    local pd = ZeD.ProtectionTab.gatherData(S.p)
    T.pd = pd
    local n = 0
    pcall(function() n = BodyPartType.ToIndex(BodyPartType.MAX) end)
    local bad, rows, sum17 = {}, {}, 0
    for i = 0, n - 1 do
        local name = nil
        pcall(function() name = BodyPartType.ToString(BodyPartType.FromIndex(i)) end)
        local gb, gs, gu = S.gameDef(i)
        local ps = name and pd.partStats[name]
        local zb = ps and math.max(0, ps.bite) or nil
        local zs = ps and math.max(0, ps.scratch) or nil
        local zu = ps and math.max(0, ps.bullet) or nil
        sum17 = sum17 + (gb or 0)
        rows[#rows + 1] = tostring(name) .. " " .. tostring(zb) .. "/" .. tostring(gb) .. " " .. tostring(zs) .. "/" .. tostring(gs)
        if not (zb and gb and zs and gs and math.abs(zb - gb) <= S.TOL and math.abs(zs - gs) <= S.TOL) then
            bad[#bad + 1] = tostring(name) .. ": bite " .. tostring(zb) .. " (game " .. tostring(gb) .. "), scratch " .. tostring(zs) .. " (game " .. tostring(gs) .. ")"
        elseif gu and zu and math.abs(zu - gu) > S.TOL then
            bad[#bad + 1] = tostring(name) .. ": bullet " .. tostring(zu) .. " (game " .. tostring(gu) .. ")"
        end
    end
    -- Back, the game's part index 17 (no row in the game's own table)
    local bb, bs = S.gameDef(17)
    local pb = pd.partStats.Back
    T.back = "Back " .. tostring(pb and math.max(0, pb.bite)) .. "/" .. tostring(bb) .. " bite, " .. tostring(pb and math.max(0, pb.scratch)) .. "/" .. tostring(bs) .. " scratch"
    if bb and pb and (math.abs(math.max(0, pb.bite) - bb) > S.TOL or math.abs(math.max(0, pb.scratch) - bs) > S.TOL) then bad[#bad + 1] = T.back end
    Q.check(n >= 17 and #bad == 0, "6 defense: each body part's bite, scratch and bullet in ZeD's Defense block are the game's (getBodyPartClothingDefense, what its protection table shows), within " .. S.TOL,
        (#bad == 0) and (n .. " parts and Back agree") or table.concat(bad, "; "))
    Q.say("NOTE 6 defense (part ZeD/game bite, scratch): " .. table.concat(rows, "; ") .. "; " .. T.back)
    T.avg17 = (n > 0) and math.floor(sum17 / n) or 0
end
function S.case6summary(T)
    local pd = T.pd
    local PT = ZeD.ProtectionTab
    local sum, worst, best = 0, nil, nil
    for _, part in ipairs(PT.ALL_PARTS) do
        local d = pd.partDefense[part]
        sum = sum + math.max(0, d)
        if worst == nil or d < worst then worst = d end
        if best == nil or d > best then best = d end
    end
    local avg = math.floor(sum / #PT.ALL_PARTS)
    Q.check(pd.avgBiteDef == avg and pd.grade == PT.gradeForAvg(avg), "6 defense: the average bite and the grade follow from the per-part numbers",
        "average " .. tostring(pd.avgBiteDef) .. " (from the parts " .. avg .. "), grade " .. tostring(pd.grade) .. " (want " .. PT.gradeForAvg(avg) .. ")")
    Q.check(pd.worstPart.biteDef == worst and pd.bestPart.biteDef == best, "6 defense: the worst and best zones are the parts with the lowest and highest bite",
        "worst " .. tostring(pd.worstPart.name) .. " " .. tostring(pd.worstPart.biteDef) .. " (lowest " .. tostring(worst) .. "), best "
        .. tostring(pd.bestPart.name) .. " " .. tostring(pd.bestPart.biteDef) .. " (highest " .. tostring(best) .. ")")
    local shown = RT.cw()._equipProtCache
    Q.check(shown ~= nil and shown.avgBiteDef == pd.avgBiteDef and shown.grade == pd.grade and shown.totalGarments == pd.totalGarments,
        "6 defense: the block on the tab shows these numbers (grade, average, garments)",
        shown and (tostring(shown.grade) .. " " .. tostring(shown.avgBiteDef) .. " " .. tostring(shown.totalGarments) .. " garments") or "the block has no numbers")
    Q.say("NOTE 6 S11: the block's worst zone reads " .. tostring(pd.worstPart.name) .. " (" .. tostring(pd.worstPart.biteDef)
        .. "); the average is over 18 parts with Back (" .. tostring(pd.avgBiteDef) .. "), the game's 17 parts average " .. tostring(T.avg17)
        .. "; Back has no tile on the figure; the row's Bullet dot reads the first part covered only")
end
function S.case6()
    local T = {}
    S.step(2, function() S.caseStart() end)
    S.toEquip("list", T, "6 defense")
    S.step(10, function()
        if T.off then return end
        S.case6compare(T)
        S.case6summary(T)
        T.pad = S.padOn() and S.focusEl("equippart:Left Hand")
        Q.check(T.pad, "6 defense: the pad's focus lands on the figure's Left Hand (equippart:Left Hand)", "on " .. tostring(S.focusedId()))
    end)
    S.step(4, function()
        if not T.pad then return end
        Q.check(RT.cw()._equipDefHoveredPart == "Left Hand", "6 defense: with the pad on a part the block shows that part's bars",
            "the block shows " .. tostring(RT.cw()._equipDefHoveredPart))
    end)
    S.step(2, function() S.caseClean() end)
    S.caseEnd("6 defense")
end

-- ===================================================================== 7. the row columns against the thing (S6)
function S.protCount(it)
    local b, s, u = 0, 0, 0
    -- (only a garment has these: a pcall over a missing method still dumps a stack trace the runner counts)
    if not instanceof(it, "Clothing") then return 0, 0, 0 end
    pcall(function() b = it:getBiteDefense() or 0 end)
    pcall(function() s = it:getScratchDefense() or 0 end)
    pcall(function() local cp = it:getCoveredParts(); if cp and cp:size() > 0 then u = it:getDefForPart(cp:get(0), false, true) or 0 end end)
    return (b > 0 and 1 or 0) + (s > 0 and 1 or 0) + (u > 0 and 1 or 0), b, s
end
function S.rowsCheck(sp, label)
    local w = RT.cw()
    local wtOn = w._equipDivZones ~= nil and w._equipDivZones[3] ~= nil
    local badM, badD, badW, noDot, seen = {}, {}, {}, {}, 0
    for _, z in ipairs(w._equipSlotZones or {}) do
        local it = z.item
        if it then
            seen = seen + 1
            local y0, y1 = z.y, z.y + z.h
            local fill, dots, txt = nil, 0, nil
            for _, f in ipairs(sp.fills) do if f.y >= y0 and f.y < y1 then fill = f.f end end
            for _, d in ipairs(sp.dots) do if d.y >= y0 and d.y < y1 then dots = dots + 1 end end
            for _, t in ipairs(sp.txts) do if t.y >= y0 and t.y < y1 then txt = t.t end end
            local kind, f = nil, nil
            pcall(function() kind, f = ZeD.ItemMeter.of(it) end)
            if kind == "hidden" then f = nil end
            if kind == "cond" then
                local c, cm = 0, 1
                pcall(function() c = it:getCondition(); cm = it:getConditionMax() end)
                if cm and cm > 0 then f = math.max(0, math.min(1, c / cm)) end
            end
            if f ~= nil then
                if not (fill and math.abs(fill - f) <= 0.011) then badM[#badM + 1] = S.nm(it) .. " " .. tostring(fill) .. " (want " .. string.format("%.2f", f) .. ")" end
            elseif fill ~= nil then
                badM[#badM + 1] = S.nm(it) .. " has a bar " .. tostring(fill) .. " and no condition"
            end
            if wtOn then
                local wt = 0
                pcall(function() wt = it:getUnequippedWeight() end)
                local want = string.format("%.1f", wt)
                if txt ~= want then badW[#badW + 1] = S.nm(it) .. " " .. tostring(txt) .. " (want " .. want .. ")" end
                local e, b = S.protCount(it)
                if dots ~= e then badD[#badD + 1] = S.nm(it) .. " " .. dots .. " dots (want " .. e .. ")" end
                if b > 0 and dots == 0 then noDot[#noDot + 1] = S.nm(it) end
            end
        end
    end
    Q.check(seen > 0 and #badM == 0, label .. ": each row's bar is its condition (getCondition / getConditionMax) or how full a held bottle or lighter is",
        seen .. " rows; " .. ((#badM == 0) and "all agree" or table.concat(badM, "; ")))
    if wtOn then
        Q.check(#badD == 0 and #noDot == 0, label .. ": each row has a Bite, Scratch and Bullet dot for each value above 0 (the protective clothes show theirs)",
            ((#badD == 0) and "all agree" or table.concat(badD, "; ")) .. ((#noDot > 0) and ("; no dot on " .. S.idsText(noDot)) or ""))
        Q.check(#badW == 0, label .. ": each row's Wt is the thing's weight (getUnequippedWeight, one decimal)", (#badW == 0) and "all agree" or table.concat(badW, "; "))
    else
        Q.say("NOTE " .. label .. ": the card left the weight and protection columns out at this width (the narrow-card fitting)")
    end
end
-- the right edge a row may draw to: the scrollbar's left edge, or the drawer's
function S.rightLimit()
    local w = RT.cw()
    local sc = w and w._equipScroll
    if sc and sc.visible and sc.x then return sc.x end
    local ep = S.ep()
    local pw = 0
    pcall(function() pw = ep:getWidth() end)
    return math.min(pw, math.floor(w._drawerEffW or pw))
end
function S.case7()
    local T = {}
    S.step(2, function()
        S.caseStart()
        T.bottle, T.lighter = S.make("bottle"), S.make("lighter")
        pcall(function() S.p:setPrimaryHandItem(T.lighter) end)
        pcall(function() S.p:setSecondaryHandItem(T.bottle) end)
        S.eqDirty()
    end)
    S.toEquip("list", T, "7 columns")
    S.step(10, function() if not T.off then S.spyOn() end end)
    S.step(1, function()
        local sp = S.spyOff()
        if T.off or not sp then return end
        S.rowsCheck(sp, "7 columns")
    end)
    -- S6: the SLOT divider dragged wide, then the half card and Large text
    S.step(2, function()
        T.s6 = nil
        if T.off then return end
        local w, dp = RT.cw(), S.dp()
        local dz = (w._equipDivZones or {})[1]
        if not dz then Q.skip("7 S6", "the list's column dividers are not drawn"); return end
        local x, y = S.mid(dz)
        pcall(function() dp:onMouseDown(x, y) end)
        local cd = w._equipColDrag
        if not cd then Q.skip("7 S6", "a press on the SLOT divider began no drag"); return end
        T.slot0 = cd.startW
        local tx = cd.startX - ZeD.T.px(400)
        S.withGlobals({ getMouseX = function() return tx end }, function() dp:onMouseMove(-ZeD.T.px(400), 0) end)
        pcall(function() dp:onMouseUp(x, y) end)
        local nw = w._equipColWidths and w._equipColWidths.slot
        T.s6 = Q.check(w._equipColDrag == nil and nw ~= nil and nw > (T.slot0 or 0), "7 S6: the SLOT column's divider dragged left widens the column",
            tostring(T.slot0) .. " -> " .. tostring(nw))
        if T.s6 then S.sizeSet("large") end
    end)
    S.step(30, S.noop)
    S.halfOn(T)
    S.step(10, function() if T.s6 then S.spyOn() end end)
    S.step(1, function()
        local sp = S.spyOff()
        if not (T.s6 and sp) then return end
        local lim = S.rightLimit()
        local over = {}
        for _, d in ipairs(sp.dots) do if d.x + d.s > lim + 1 then over[#over + 1] = "a dot to " .. math.floor(d.x + d.s) end end
        for _, t in ipairs(sp.txts) do if t.x > lim + 1 then over[#over + 1] = "the weight " .. tostring(t.t) .. " to " .. math.floor(t.x) end end
        for _, f in ipairs(sp.fills) do if f.x + f.w > lim + 1 then over[#over + 1] = "a bar to " .. math.floor(f.x + f.w) end end
        Q.check(#over == 0, "7 S6: with the SLOT column dragged wide, at the " .. (T.half and "half" or "same") .. " card and Large text, no column draws past the card's right edge",
            "edge " .. lim .. "; " .. ((#over == 0) and (#sp.dots .. " dots, " .. #sp.txts .. " weights, " .. #sp.fills .. " bars inside") or S.idsText(over)))
        RT.bounds(Q, "the Equip tab at the half card, Large text")
    end)
    -- (the proof for S6 a person can see: the columns at the half card after the drag)
    S.shot("eq_s6_half_large_" .. S.sizeTag(), "the Equip list at the half card in Large text, the SLOT column dragged wide (S6)")
    S.halfOff(T)
    S.step(2, function()
        local w = RT.cw()
        if w then w._equipColWidths = S.copy(S.found.colW) end
        S.sizeBack()
        S.caseClean()
    end)
    S.step(30, S.noop)
    S.caseEnd("7 columns")
end

-- ===================================================================== 8. garment states (S12)
S.STATES = { "clean", "wet", "bloody", "dirty", "holed", "patched", "broken" }
function S.partsOf(it)
    local out = {}
    pcall(function() local cp = it:getCoveredParts(); for i = 0, cp:size() - 1 do out[#out + 1] = cp:get(i) end end)
    return out
end
-- the state staged with the game's own setters; true when the game reads it back
function S.stage(it, st)
    local parts = S.partsOf(it)
    local p1 = parts[1]
    local v = nil
    pcall(function() v = it:getVisual() end)
    local got = false
    if st == "clean" then got = true
    elseif st == "wet" then
        pcall(function() it:setWetness(80) end)
        pcall(function() got = it:getWetness() > 0 end)
    elseif st == "bloody" then
        for _, p in ipairs(parts) do pcall(function() v:setBlood(p, 1) end) end
        pcall(function() it:setBloodLevel(100) end)
        pcall(function() got = p1 ~= nil and v:getBlood(p1) > 0 end)
    elseif st == "dirty" then
        for _, p in ipairs(parts) do pcall(function() v:setDirt(p, 1) end) end
        pcall(function() it:setDirtiness(60) end)
        pcall(function() got = p1 ~= nil and v:getDirt(p1) > 0 end)
    elseif st == "holed" then
        pcall(function() v:setHole(p1) end)
        pcall(function() got = p1 ~= nil and v:getHole(p1) > 0 end)
    elseif st == "patched" then
        pcall(function() v:setHole(p1) end)
        local fab = S.make("fabric")
        pcall(function() it:addPatch(S.p, p1, fab) end)
        pcall(function() got = p1 ~= nil and it:getPatchType(p1) ~= nil end)
    elseif st == "broken" then
        pcall(function() it:setCondition(0) end)
        pcall(function() got = it:getCondition() == 0 end)
    end
    pcall(function() it:synchWithVisual() end)
    return got
end
function S.verbKeys(c)
    local out = {}
    for _, v in ipairs((c and c._verbDefs) or {}) do out[#out + 1] = tostring(v.key) end
    for _, v in ipairs((c and c._moreVerbs) or {}) do out[#out + 1] = tostring(v.key) end
    return out
end
function S.stateCheck(T, st)
    local it = T.cur
    local zones = {}
    pcall(function() zones = ZeD.ItemDetail.getZones(it) end)
    local keys = S.verbKeys(S.ecard())
    local has = function(k) return S.inList(keys, k) end
    local z1 = zones[1] or {}
    local ok, what = true, ""
    if st == "clean" then
        ok, what = not has("wash"), "no WASH on a clean garment"
    elseif st == "wet" then
        ok, what = (z1.wetPct or 0) > 0, "its zones read wet"
    elseif st == "bloody" then
        local b = false
        for _, z in ipairs(zones) do if (z.bloodPct or 0) > 0 then b = true end end
        ok, what = b and has("wash"), "its zones read blood and WASH is offered"
    elseif st == "dirty" then
        ok, what = z1.hasDirt == true and has("wash"), "its zones read dirt and WASH is offered"
    elseif st == "holed" then
        ok, what = z1.flagText == "TORN" and has("repair_all"), "its first zone reads TORN and REPAIR is offered"
    elseif st == "patched" then
        ok, what = z1.flagText ~= nil and z1.flagText ~= "TORN", "its first zone names the patch's material"
    elseif st == "broken" then
        ok, what = (z1.zoneR or 1) == 0, "its zones read condition 0"
    end
    Q.check(ok, "8 states, " .. st .. ": the T-shirt's card from its row: " .. what,
        "zone 1: wet " .. tostring(z1.wetPct) .. ", blood " .. tostring(z1.bloodPct) .. ", dirt " .. tostring(z1.hasDirt) .. ", flag "
        .. tostring(z1.flagText) .. ", condition " .. tostring(z1.zoneR) .. "; verbs " .. S.idsText(keys))
end
function S.case8one(T, st)
    S.step(2, function()
        T.go = nil
        if T.off then return end
        S.cardClose()
        T.cur = S.make("tee")
        if not T.cur then T.off = true; Q.skip("8 states", "no T-shirt could be made"); return end
        local staged = S.stage(T.cur, st)
        if not staged then Q.skip("8 states, " .. st, "the state could not be staged with the game's setters"); return end
        S.wearIt(T.cur)
        S.wornEvent()
        T.go = S.isWorn(T.cur)
        if not T.go then Q.skip("8 states, " .. st, "the T-shirt could not be worn") end
    end)
    S.openRow(T, "card", function() return T.go and T.cur or nil end, "8 states, " .. st)
    S.step(6, function()
        if not (T.go and T.card) then return end
        S.stateCheck(T, st)
        S.cardClose()
    end)
end
function S.case8()
    local T = {}
    S.step(2, function() S.caseStart() end)
    S.toEquip("list", T, "8 states")
    for _, st in ipairs(S.STATES) do S.case8one(T, st) end
    -- S12: the row's Inspect
    S.step(4, function()
        T.i = nil
        if T.off or not (T.cur and S.isWorn(T.cur)) then return end
        S.closeMenu()
        T.i = S.rclickZone(S.slotZone(T.cur))
    end)
    S.wait(2, 60, function() return not T.i or S.menuUp() end, function(ok)
        if not T.i then return end
        local names = S.menuNames(S.menu())
        Q.say("NOTE 8 S12: the T-shirt's row menu " .. (ok and "opened" or "did not open") .. "; Inspect (" .. getText("IGUI_invpanel_Inspect") .. ") in it: "
            .. tostring(S.inList(names, getText("IGUI_invpanel_Inspect"))))
        S.closeMenu()
        pcall(function() ISInventoryPaneContextMenu.onInspectClothingUI(S.p, T.cur) end)
    end)
    S.step(10, function()
        if not T.i then return end
        local w = RT.cw()
        Q.say("NOTE 8 S12: Inspect (onInspectClothingUI, as the menu runs it) from an Equip row opens the inventory's own card over the tab: "
            .. tostring(w._drawerItem == T.cur) .. " (its card on " .. S.nm(w._drawerItem) .. "); the Equip tab's card is "
            .. (S.cardItem() and ("open on " .. S.nm(S.cardItem())) or "closed") .. "; that card is the second, different card the map names")
        pcall(function() local c = w._itemCard; if c and c.onBackClick then c:onBackClick() end end)
    end)
    S.step(4, function() S.caseClean() end)
    S.caseEnd("8 states")
end

-- ===================================================================== 9. the hands (S9)
function S.slotItem(data, ty)
    for _, g in ipairs((data and data.groups) or {}) do
        for _, s in ipairs(g.slots or {}) do if s.type == ty then return s.item end end
    end
    return nil
end
function S.hands(p, s)
    pcall(function() S.p:setPrimaryHandItem(p) end)
    pcall(function() S.p:setSecondaryHandItem(s) end)
    S.eqDirty()
end
function S.case9()
    local T = {}
    S.step(2, function()
        S.caseStart()
        T.axe, T.knife, T.ham, T.bag = S.make("axe"), S.make("knife"), S.make("hammer"), S.make("bag")
        S.hands(T.axe, T.axe)
    end)
    S.toEquip("list", T, "9 hands")
    S.step(4, function()
        if T.off then return end
        local data = ZeD.EquipmentTab.gatherData(S.p)
        local pri, sec = S.slotItem(data, "PRI"), S.slotItem(data, "SEC")
        local dd = ZeD.EquipDoll.gather(S.p, S.pn, true)
        Q.check(T.axe ~= nil and pri == T.axe, "9a hands: a two-handed axe held in both hands shows in the PRI row and the doll's Main box",
            "PRI " .. S.nm(pri) .. ", Main " .. S.nm(dd.main))
        -- (S9 was a NOTE that SEC read "---" and the Off box stood empty; the director's call 7, Nov 25 2026: the off hand
        -- shows the two-handed weapon dimmed, "both hands". et_calls 7 checks the words, the dim and the icons' alpha.)
        local secDef = nil
        for _, g in ipairs(data.groups or {}) do for _, s in ipairs(g.slots or {}) do if s.type == "SEC" then secDef = s end end end
        Q.check(T.axe ~= nil and sec == nil and secDef ~= nil and secDef.bothHands == T.axe and dd.offBoth == T.axe and dd.off == nil,
            "9a S9: the axe held in both hands: the SEC row keeps it as bothHands and the doll's Off box as offBoth (the director's call 7)",
            "SEC item " .. S.nm(sec) .. ", bothHands " .. S.nm(secDef and secDef.bothHands) .. "; Off " .. S.nm(dd.off) .. ", offBoth " .. S.nm(dd.offBoth)
            .. "; the game's off hand is the axe " .. tostring(S.p:getSecondaryHandItem() == T.axe))
        S.hands(T.knife, T.ham)
    end)
    S.step(6, function()
        if T.off then return end
        local data = ZeD.EquipmentTab.gatherData(S.p)
        local dd = ZeD.EquipDoll.gather(S.p, S.pn, true)
        Q.check(S.slotItem(data, "PRI") == T.knife and S.slotItem(data, "SEC") == T.ham and dd.main == T.knife and dd.off == T.ham,
            "9b hands: a knife in the main hand and a hammer in the off hand fill PRI and SEC and the doll's Main and Off",
            "PRI " .. S.nm(S.slotItem(data, "PRI")) .. ", SEC " .. S.nm(S.slotItem(data, "SEC")) .. ", Main " .. S.nm(dd.main) .. ", Off " .. S.nm(dd.off))
        S.hands(nil, T.bag)
    end)
    S.step(6, function()
        if T.off then return end
        local data = ZeD.EquipmentTab.gatherData(S.p)
        Q.check(T.bag ~= nil and S.slotItem(data, "SEC") == T.bag and S.listWhere(data, T.bag) == "SEC",
            "9c hands: a school bag held in the off hand (not worn) shows in SEC, not as a worn bag",
            "SEC " .. S.nm(S.slotItem(data, "SEC")) .. ", the bag's row " .. tostring(S.listWhere(data, T.bag)))
        S.hands(nil, nil)
        T.lan = S.make("lantern")
        if T.lan then
            pcall(function() T.lan:setActivated(true) end)
            S.hands(T.lan, nil)
        else
            Q.skip("9d hands, a lit lantern", "no lit hurricane lantern is known")
        end
    end)
    -- 9d the lit lantern's UNEQUIP from its card
    S.openRow(T, "d", function() return T.lan end, "9d hands, a lit lantern")
    S.step(6, function()
        if not T.d then return end
        local ok, why = S.cardClick("UNEQUIP")
        T.d = Q.check(ok, "9d hands: UNEQUIP pressed on the lit lantern's card", why)
    end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(20, function()
        if not T.d then return end
        local lit = {}
        for _, it in ipairs(S.list(S.inv())) do
            local ft = S.ft(it)
            local on = ft == "Base.Lantern_HurricaneLit"
            if not on then pcall(function() on = string.find(string.lower(ft), "lantern", 1, true) ~= nil and it:isActivated() end) end
            if on then lit[#lit + 1] = ft end
        end
        local hand = S.p:getPrimaryHandItem()
        Q.check(hand == nil and #lit == 0, "9d hands: UNEQUIP on a lit lantern empties the hand and leaves no lit lantern, as the game puts it out",
            "in the hand " .. S.nm(hand) .. ", lit lanterns in the inventory: " .. S.idsText(lit))
    end)
    -- 9e the watch
    S.step(4, function()
        if T.off then return end
        S.cardClose()
        local data = ZeD.EquipmentTab.gatherData(S.p)
        local db = ZeD.EquipDoll.gather(S.p, S.pn, true)
        local df = ZeD.EquipDoll.gather(S.p, S.pn, false)
        local wt = S.base.watch
        Q.check(wt ~= nil and S.listWhere(data, wt) == "WCH" and S.dollWhere(db, wt) == "wristl" and S.dollWhere(df, wt) == "arms",
            "9e hands: the watch shows in the WCH row, the doll's left wrist (bands) and Arms (folded)",
            "list " .. tostring(S.listWhere(data, wt)) .. ", doll " .. tostring(S.dollWhere(db, wt)) .. " / " .. tostring(S.dollWhere(df, wt)))
    end)
    S.step(2, function() S.caseClean() end)
    S.caseEnd("9 hands")
end

-- ===================================================================== 10. Find
-- a body part's name one worn thing covers that no worn name and no slot word holds (the covers match)
function S.coversQuery()
    local TF = ZeD.TabFind
    local data = ZeD.EquipmentTab.gatherData(S.p)
    local words = {}
    for _, g in ipairs(data.groups or {}) do
        for _, s in ipairs(g.slots or {}) do
            words[#words + 1] = string.lower(ZeD.EquipmentTab.wordsOf(s))
            if s.item then words[#words + 1] = string.lower(S.nm(s.item)) end
        end
    end
    for _, k in ipairs(S.OUTFIT) do
        local it = S.base[k]
        local parts = (it and TF.infoOf and TF.infoOf(it).parts) or {}
        for _, pn in ipairs(parts) do
            local q = string.lower(pn)
            local clash = false
            for _, wd in ipairs(words) do if string.find(wd, q, 1, true) then clash = true end end
            if not clash then return q end
        end
    end
    return nil
end
function S.findRes() local w = RT.cw(); return w and w._findEquip and w._findEquip.res or nil end
function S.case10()
    local T = {}
    local TF = ZeD.TabFind
    S.step(2, function() S.caseStart() end)
    S.toEquip("list", T, "10 find")
    S.step(4, function()
        if T.off then return end
        if not (TF and TF.setText and TF.clear) then T.off = true; Q.skip("10 find", "ZeD.TabFind is not loaded"); return end
        T.q = string.lower(S.nm(S.base.tank))
        TF.setText(RT.cw(), "equip", T.q)
    end)
    S.step(6, function()
        if T.off then return end
        local w = RT.cw()
        Q.check(TF.active(w, "equip") and not TF.equipOff(w, "INR#2") and TF.equipOff(w, "INR"),
            "10a find, list: the tank top's name keeps its layer row (INR#2) lit and dims the T-shirt's row (INR) over it",
            "\"" .. T.q .. "\": INR#2 dimmed " .. tostring(TF.equipOff(w, "INR#2")) .. ", INR dimmed " .. tostring(TF.equipOff(w, "INR")))
        Q.check(w._equipDefHidden == true, "10a find: the Defense block hides while the field holds text", tostring(w._equipDefHidden))
        T.cq = S.coversQuery()
        if T.cq then TF.setText(w, "equip", T.cq) else Q.skip("10b find, covers", "every covered part's name is also in a worn name or a slot's words") end
    end)
    S.step(6, function()
        if T.off or not T.cq then return end
        local res = S.findRes()
        local covered, lines = {}, {}
        for ty, why in pairs((res and res.hit) or {}) do
            if why == "covers" then
                covered[#covered + 1] = ty
                local ln = TF.coversLine(res, ty)
                if ln then lines[#lines + 1] = ln end
            end
        end
        Q.check(#covered > 0 and #lines == #covered, "10b find, list: a body part's name (" .. T.cq .. ") keeps the rows of the clothes that cover it, each with its covers line",
            "rows " .. S.idsText(covered) .. "; " .. S.idsText(lines))
    end)
    S.step(2, function()
        if T.off then return end
        pcall(ZeD.EquipDoll.setView, "doll")
        TF.setText(RT.cw(), "equip", T.q)
    end)
    S.wait(6, 120, function() return T.off or RT.cw()._equipDollShown == true end, function(ok)
        if T.off then return end
        local res = S.findRes()
        Q.check(ok and res ~= nil and res.hit["doll:torso"] ~= nil and res.hit["doll:outer"] == nil,
            "10c find, doll: the tank top's name lights the Torso box it is a layer of and dims Outer",
            "torso " .. tostring(res and res.hit["doll:torso"]) .. ", outer " .. tostring(res and res.hit["doll:outer"]))
        TF.setText(RT.cw(), "equip", "zzqxj")
    end)
    S.step(6, function()
        if T.off then return end
        local w = RT.cw()
        local res = S.findRes()
        local b = w._findClearBtn and w._findClearBtn.equip
        T.cb = (b and b.drawn) and { x = b.x, y = b.y, w = b.w, h = b.h } or nil
        Q.check(res ~= nil and res.shown == 0 and T.cb ~= nil, "10d find: text that matches nothing shows the empty result with its Clear key",
            "shown " .. tostring(res and res.shown) .. ", Clear drawn " .. tostring(T.cb ~= nil))
        if T.cb then S.clickZone(T.cb) end
    end)
    S.step(4, function()
        if T.off or not T.cb then return end
        Q.check(not TF.active(RT.cw(), "equip"), "10d find: Clear empties the field and the tab comes back", "text \"" .. tostring(TF.text and TF.text(RT.cw(), "equip")) .. "\"")
    end)
    S.step(2, function()
        pcall(function() TF.clear(RT.cw(), "equip") end)
        pcall(ZeD.EquipDoll.setView, "list")
        S.caseClean()
    end)
    S.caseEnd("10 find")
end

-- ===================================================================== 11. settings
function S.ccHit(c, key)
    for i, h in ipairs((c and c._cc and c._cc.hits) or {}) do if h.key == key then return i, h end end
    return nil, nil
end
function S.case11worn(T)
    S.step(2, function()
        S.caseStart()
        T.w = nil
        if not (ZeD.Settings and ZeD.Settings.wornListOption) then Q.skip("11a worn and held", "the setting is not loaded"); return end
        S.setOpt(ZeD.Settings.wornListOption, 2)
        S.back.wornOpt = true
        RT.charTab("loot")
        pcall(ZeD_CharacterWindow.showBagAlone, S.pn, S.inv())
        T.w = true
    end)
    S.wait(6, 300, function()
        if not T.w then return true end
        local c = RT.cw() and RT.cw()._mainContent
        if c and c._scroll then pcall(function() c._scroll:setScrollPos(1) end) end
        return S.ccHit(c, "wornline") ~= nil
    end, function(ok)
        if not T.w then return end
        local c = RT.cw()._mainContent
        T.w = Q.check(ok, "11a settings, worn and held on the Equipment tab: the inventory list ends in the worn line", "the list's band: " .. tostring(c and c._cc ~= nil))
        if not T.w then return end
        local i, h = S.ccHit(c, "wornline")
        local ok2 = pcall(function()
            local z = nil
            for _, hz in ipairs(c._hitZones or {}) do if hz.id == "cc:" .. i then z = hz end end
            if z and z.w > 0 then c:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)); c:onMouseUp(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
            else ZeD.ContainerControls.press(c, i) end
        end)
        if not ok2 then S.errs = S.errs + 1 end
    end)
    S.wait(4, 120, function() return not T.w or RT.cw()._activeTab == "equip" end, function(ok)
        if T.w then Q.check(ok, "11a settings: the worn line opens the Equipment tab", "tab " .. tostring(RT.cw()._activeTab)) end
        S.setOpt(ZeD.Settings.wornListOption, S.found.wornOpt)
        S.back.wornOpt = nil
    end)
end
function S.case11()
    local T = {}
    S.case11worn(T)
    -- 11b Lite
    S.step(2, function()
        S.setOpt(ZeD.Settings.lookStyleOption, 2)
        S.back.style = true
    end)
    S.toEquip("list", T, "11b Lite")
    S.openRow(T, "lite", function() return S.base.cap end, "11b settings, Lite")
    S.step(4, function()
        if T.off then return end
        Q.check(T.lite and #(RT.cw()._equipSlotZones or {}) > 0, "11b settings, Lite: the Equipment tab lists the outfit and a row's card opens",
            #(RT.cw()._equipSlotZones or {}) .. " rows")
        S.cardClose()
        S.setOpt(ZeD.Settings.lookStyleOption, S.found.style)
        S.back.style = nil
    end)
    -- 11c the menu as the strip and as a list
    for _, v in ipairs({ 1, 2 }) do
        S.step(4, function()
            T.rz = nil
            if T.off or not ZeD.Settings.contextStyleOption then return end
            S.setOpt(ZeD.Settings.contextStyleOption, v)
            S.back.ctx = true
            S.closeMenu()
            local z = S.slotZone(S.base.cap)
            T.rz = z ~= nil
            if z then S.rclickZone(z) end
        end)
        S.wait(2, 60, function() return not T.rz or S.menuUp() end, function(ok)
            if T.rz then
                Q.check(ok, "11c settings, the right-click menu as " .. ((v == 1) and "the strip" or "a list") .. ": a right-click on a row opens it",
                    S.idsText(S.menuNames(S.menu())))
            end
            S.closeMenu()
        end)
    end
    S.step(2, function()
        if S.back.ctx then S.setOpt(ZeD.Settings.contextStyleOption, S.found.ctx); S.back.ctx = nil end
        Q.check(S.optVal(ZeD.Settings.wornListOption) == S.found.wornOpt and S.optVal(ZeD.Settings.lookStyleOption) == S.found.style
            and S.optVal(ZeD.Settings.contextStyleOption) == S.found.ctx, "11 settings: Worn and held, Lite and the menu's look are back as found")
        S.caseClean()
    end)
    S.caseEnd("11 settings")
end

-- ===================================================================== 12. the pad end to end
function S.case12()
    local T = {}
    S.step(2, function()
        S.caseStart()
        pcall(ZeD.EquipDoll.setView, "list")
        RT.charTab("loot")
        T.on = S.padOn()
        local w = RT.cw()
        if w then w._equipListExpanded = true end
    end)
    for _ = 1, 16 do
        S.tap("LeftBump", "LBumper", function() local w = RT.cw(); return T.on and w ~= nil and w._activeTab ~= "equip" end)
        S.step(4, S.noop)
    end
    S.wait(2, 120, function() local w = RT.cw(); return w ~= nil and w._activeTab == "equip" end, function(ok)
        T.inn = Q.check(ok, "12 pad: LB steps the Character window's tabs to the Equipment tab", "on " .. tostring(RT.cw() and RT.cw()._activeTab))
    end)
    S.step(20, function()
        if not T.inn then return end
        Q.say("NOTE 12 pad: after LB the pad is on " .. tostring(S.focusedId()))
        T.d = S.focusEl("equipslot:__disclosure")
        T.exp0 = RT.cw()._equipListExpanded
        Q.check(T.d, "12 pad: the focus lands on the Equipped heading", "on " .. tostring(S.focusedId()))
    end)
    S.tapA(function() return T.d end)
    S.step(4, function()
        if T.d then Q.check(RT.cw()._equipListExpanded ~= T.exp0, "12 pad: A on the Equipped heading folds the list", tostring(T.exp0) .. " -> " .. tostring(RT.cw()._equipListExpanded)) end
    end)
    S.tapA(function() return T.d end)
    S.step(6, function()
        if not T.d then return end
        Q.check(RT.cw()._equipListExpanded == T.exp0, "12 pad: A again opens it", tostring(RT.cw()._equipListExpanded))
        T.g = S.focusEl("equipgroup:head")
        T.g0 = RT.cw()._equipExpanded and RT.cw()._equipExpanded.head
    end)
    S.tapA(function() return T.g end)
    S.step(4, function()
        if T.g then Q.check((RT.cw()._equipExpanded.head and true or false) ~= (T.g0 and true or false), "12 pad: A on a group heading folds or opens the group", tostring(T.g0) .. " -> " .. tostring(RT.cw()._equipExpanded.head)) end
    end)
    S.tapA(function() return T.g end)
    S.step(6, function()
        if T.g then Q.check((RT.cw()._equipExpanded.head and true or false) == (T.g0 and true or false), "12 pad: A again puts the group back", tostring(RT.cw()._equipExpanded.head)) end
        local z = S.slotZone(S.base.cap)
        T.s = T.inn and z ~= nil and S.focusEl("equipslot:" .. tostring(z.type))
        T.sid = z and ("equipslot:" .. tostring(z.type))
    end)
    S.tapA(function() return T.s end)
    S.wait(2, 120, function() return not T.s or S.cardOn(S.base.cap) end, function(ok)
        if not T.s then return end
        local id = S.focusedId()
        T.s = Q.check(ok and id ~= nil and string.sub(id, 1, 10) == "equipcard:", "12 pad: A on the cap's row opens its card with the pad on the card",
            "the card shows " .. S.nm(S.cardItem()) .. ", the pad on " .. tostring(id))
    end)
    S.tapB(function() return T.s end)
    S.wait(2, 90, function() return not T.s or (S.cardItem() == nil and S.focusedId() == T.sid) end, function(ok)
        if T.s then Q.check(ok, "12 pad: B leaves the card and the focus returns to the cap's row", "card " .. S.nm(S.cardItem()) .. ", on " .. tostring(S.focusedId())) end
    end)
    S.step(2, function() S.caseClean() end)
    S.caseEnd("12 pad")
end

-- ===================================================================== 13. pictures
function S.case13theme(T, th, all)
    local tag = th.key .. "_" .. S.sizeTag()
    S.step(2, function() if not T.off then S.theme(th.key) end end)
    S.toEquip("list", T, "13 pictures (" .. th.word .. ")")
    S.step(20, S.noop)
    S.shot("eq_list_" .. tag, th.word .. ": the Equipment tab's list, the stocked outfit (layer rows, belt rows, the columns)")
    S.toEquip("doll", T, "13 pictures (" .. th.word .. ")")
    S.step(20, S.noop)
    S.shot("eq_doll_" .. tag, th.word .. ": the doll, the stocked outfit (layer plates, the bands, the belt boxes)")
    if all then
        S.step(2, function() if not T.off then S.clickZone(S.zoneT("doll:outer")) end end)
        -- (a single click opens the card once DOUBLE_MS is up, the director's call 5: waited for, not 20 frames)
        S.wait(2, 150, function() return T.off or S.cardOn(S.base.jacket) end, S.noop)
        S.step(10, S.noop)
        S.shot("eq_card_layers_" .. tag, th.word .. ": the jacket's card from the doll's Outer box, its layer strip (layer 1 of 2)")
        S.step(2, function() S.cardClose() end)
        S.toEquip("list", T, "13 pictures (" .. th.word .. ")")
        S.step(2, function() local w = RT.cw(); if w then w._equipListExpanded = false end end)
        S.step(20, S.noop)
        S.shot("eq_defense_" .. tag, th.word .. ": the Defense block (the figure, grade, average, worst and best zone, garments) with the list folded")
        S.step(2, function() local w = RT.cw(); if w then w._equipListExpanded = true end end)
    end
end
function S.case13()
    local T = {}
    S.step(2, function() S.caseStart(); S.closeMenu() end)
    for i, th in ipairs(S.THEMES) do S.case13theme(T, th, i == 1) end
    S.step(2, function()
        S.themeBack()
        Q.check(#S.shots >= 6, "13 pictures: the list, the doll, a layered card and the Defense block in Dark, the list and the doll in Light and High contrast were taken (a person judges them)",
            S.idsText(S.shots))
        S.caseClean()
    end)
    S.step(20, S.noop)
    S.caseEnd("13 pictures")
end

-- ===================================================================== 14. seated in a car (DROP refused)
function S.case14()
    local T = {}
    S.step(2, function()
        S.caseStart()
        if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY and ZEDQA_CAR_KEEP) then T.off = true; Q.skip("14 seated", "the prelude's car helpers are not loaded"); return end
        T.ham = S.make("hammer")
        S.hands(T.ham, nil)
        T.t0 = getTimestampMs()
        ZEDQA_CAR_WAIT("Base.PickUpTruck", "eq_tab", function(v)
            S.car = v
            ZEDQA_CAR_KEEP[v] = true
            T.ready = true
        end, function(why) T.why = why or "no ready car" end, 6000)
    end)
    S.wait(4, 30000, function() return T.off or T.ready or T.why ~= nil or getTimestampMs() - T.t0 > 60000 end, function()
        if T.off then return end
        if not T.ready then T.off = true; Q.skip("14 seated", "no car could be staged: " .. tostring(T.why or "not ready in a minute")); return end
        if ZEDQA_CAR_PREP then
            local ok, k = pcall(ZEDQA_CAR_PREP, S.car)
            if ok and k then S.carKey = k; S.mark(k) end
        end
        local okC, okE, why = pcall(ZEDQA_CAR_ENTER, S.car, 0)
        T.seated = okC and okE == true and S.p:getVehicle() == S.car
        if not T.seated then T.off = true; Q.skip("14 seated", "the character could not be seated: " .. tostring(why or okE)); return end
        pcall(function()
            local door = S.car:getPassengerDoor(S.car:getSeat(S.p))
            pcall(function() local dd = door and door:getDoor(); if dd then dd:setOpen(false) end end)
            pcall(function() VehicleUtils.getChildWindow(door):getWindow():setOpen(false) end)
        end)
    end)
    S.toEquip("list", T, "14 seated")
    S.openRow(T, "c", function() return T.ham end, "14 seated")
    S.step(6, function()
        if not T.c then return end
        pcall(function() T.shut = ZeD.InventoryRenderer.carWindowShut(S.p) end)
        if not T.shut then Q.say("NOTE 14 seated: the seat's door and window are not shut here (carWindowShut false): DROP refused is not checked"); return end
        local _, v = S.cardVerbIdx("DROP")
        T.dropV = v
        local ok, why = S.cardClick("DROP")
        T.pressed = Q.check(ok, "14 seated: DROP pressed on the held hammer's card", why)
    end)
    S.wait(4, 600, S.settled(10), S.noop)
    S.step(10, function()
        if not (T.c and T.shut and T.pressed) then return end
        Q.check(S.p:getPrimaryHandItem() == T.ham and not S.onFloor(T.ham), "14 seated, the door and window shut: the card's DROP leaves the hammer in the hand (nothing goes out of the car)",
            "in the hand " .. S.nm(S.p:getPrimaryHandItem()) .. ", on the floor " .. tostring(S.onFloor(T.ham)))
        local v = T.dropV
        Q.check(v ~= nil and v.disabled == true and v.offHelp ~= nil, "14 seated: the card's DROP is grayed and says why, as the game's Drop does (ContextMenu_DropFromVehicle)",
            v and ("DROP grayed " .. tostring(v.disabled) .. ", its reason " .. tostring(v.offHelp)) or "no DROP on the card")
        S.cardClose()
    end)
    S.step(4, function()
        if S.car then
            pcall(function() ZEDQA_CAR_KEEP[S.car] = nil end)
            pcall(ZEDQA_CAR_AWAY, S.car, S.carKey)
            S.carAway = true
        end
    end)
    S.wait(4, 600, function() return S.p:getVehicle() == nil end, function(ok)
        if S.car then Q.check(ok, "14 seated: out of the car and the car taken away", "in a car " .. tostring(S.p:getVehicle() ~= nil)) end
        S.car = nil
        S.goTo(S.found.pos.x, S.found.pos.y, S.found.pos.z)
        S.caseClean()
    end)
    S.caseEnd("14 seated")
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    S.park(false)
    S.spyOff()
    S.padOff()
    S.cancelDrags()
    S.closeMenu()
    S.themeBack()
    S.sizeBack()
    S.halfBack()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    if S.car and not S.carAway then pcall(function() ZEDQA_CAR_KEEP[S.car] = nil end); pcall(ZEDQA_CAR_AWAY, S.car, S.carKey) end
    if f.recorded then
        if f.wornOpt ~= nil then S.setOpt(ZeD.Settings.wornListOption, f.wornOpt) end
        if f.ctx ~= nil then S.setOpt(ZeD.Settings.contextStyleOption, f.ctx) end
        if f.style ~= nil then S.setOpt(ZeD.Settings.lookStyleOption, f.style) end
        if ZeD.EquipDoll and ZeD.EquipDoll.view() ~= f.view then pcall(ZeD.EquipDoll.setView, f.view) end
    end
    local w = RT.cw()
    if w then
        pcall(function() ZeD.TabFind.clear(w, "equip") end)
        w._equipSelected = nil
        w._equipDefHoveredPart = nil
        if f.recorded then
            w._equipListExpanded = f.listExp
            w._equipExpanded = S.copy(f.exp)
            w._equipColWidths = S.copy(f.colW)
        end
    end
    -- the test's things away (the stocked outfit too), then what the game made from them
    for _, it in ipairs(S.made) do S.removeItem(it) end
    S.sweepNew()
    -- the character's own outfit, worn in its order, and the hands
    for _, e in ipairs(f.worn or {}) do
        if not S.isWorn(e.item) and S.where(e.item) == S.inv() then pcall(function() S.p:setWornItem(e.loc, e.item) end) end
    end
    if f.hands then
        pcall(function() if S.p:getPrimaryHandItem() ~= f.hands.p then S.p:setPrimaryHandItem(f.hands.p) end end)
        pcall(function() if S.p:getSecondaryHandItem() ~= f.hands.s then S.p:setSecondaryHandItem(f.hands.s) end end)
    end
    S.wornEvent()
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        S.putBack()
        RT.pairOpen()
    end)
    Q.step(10, function()
        S.hbBack()
        local f = S.found
        if f.pos then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
        if f.dir then pcall(function() S.p:setDir(f.dir) end) end
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "eq_tab") end
    end)
    Q.step(20, function()
        local f = S.found
        if f.charTab then RT.charTab(f.charTab) end
        S.instant(f.inst)
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        local left, names = 0, {}
        for _, it in ipairs(S.made) do
            if S.where(it) ~= nil or S.onFloor(it) then
                left = left + 1
                if #names < 4 then names[#names + 1] = S.ft(it) end
            end
        end
        Q.check(left == 0, "put back: every thing the test made is gone (inventory, floor, hands, belt)", left .. " of " .. #S.made .. " left " .. S.idsText(names))
        local extra = {}
        for _, it in ipairs(S.list(S.inv())) do if not f.inv0[it] then extra[#extra + 1] = S.ft(it) end end
        Q.check(#extra == 0, "put back: the inventory holds only what it held (nothing the game made from the test's things)", S.idsText(extra))
        local worn, on = 0, S.wornSet()
        for _, e in ipairs(f.worn or {}) do if on[e.item] then worn = worn + 1 end end
        local wl = S.wornList()
        Q.check(worn == #(f.worn or {}) and #wl == #(f.worn or {}), "put back: he wears what he wore, nothing else", worn .. " of " .. #(f.worn or {}) .. " back, " .. #wl .. " worn")
        local hp, hs = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
        Q.check(f.hands == nil or (hp == f.hands.p and hs == f.hands.s), "put back: the hands hold what they held", S.nm(hp) .. ", " .. S.nm(hs))
        local hb, belt = S.hb(), 0
        for _, e in ipairs(f.hb or {}) do
            local onIt = false
            pcall(function() onIt = hb:isInHotbar(e.item) end)
            if onIt then belt = belt + 1 end
        end
        Q.check(belt == #(f.hb or {}), "put back: the belt holds its own things again", belt .. " of " .. #(f.hb or {}))
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and S.p:getVehicle() == nil, "put back: he stands where he stood, out of any car", string.format("%.1f,%.1f off", dx, dy))
        Q.check(S.optVal(ZeD.Settings.wornListOption) == f.wornOpt and S.optVal(ZeD.Settings.contextStyleOption) == f.ctx
            and S.optVal(ZeD.Settings.lookStyleOption) == f.style and ZeD.EquipDoll.view() == f.view
            and ZeD.currentBase == f.base and ZeD.currentSize == f.size,
            "put back: the Equip view, Worn and held, Lite, the menu's look, the theme and the text size as found",
            tostring(ZeD.EquipDoll.view()) .. ", " .. tostring(S.optVal(ZeD.Settings.wornListOption)) .. ", " .. tostring(S.optVal(ZeD.Settings.lookStyleOption))
            .. ", " .. tostring(S.optVal(ZeD.Settings.contextStyleOption)) .. ", " .. tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize))
        local w = RT.cw()
        Q.check(S.lockFound() == (S.lockWas or S.lockFound()) and S.spy == nil and S.parked == nil and S.back.maxW == nil
            and (w == nil or (w._equipSelected == nil and not (ZeD.TabFind and ZeD.TabFind.active(w, "equip")))),
            "put back: the input lock as found; the draws, the pointer and the width cap the game's own; no card and no Find text on the tab",
            "lock " .. S.lockFound() .. " (found " .. tostring(S.lockWas) .. ")")
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught")
        local e1 = S.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the Equipment tab run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the Equipment tab run's Lua error count", "the game's Lua error count cannot be read here") end
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
    end)
end

-- ===================================================================== the run
function S.build()
    S.setup()
    S.case1()
    S.case2()
    S.case3()
    S.case6()
    S.case7()
    S.case8()
    S.case9()
    S.case10()
    S.case5()
    S.case4()
    S.case11()
    S.case12()
    S.case13()
    S.case14()
end
S.build()
S.buildPutBack()
Q.start()
