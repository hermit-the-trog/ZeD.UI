-- ZeDUI/tools/qa/lv_calls.lua  (Nov 24 2026, QA; tag lv_calls): the calls Build merged on Nov 24 2026 (main at fab001ccf,
-- then the smart menu, c6dafe460), each checked in the running game. Run after zedqa_prelude.lua and rt_kit.lua
-- (lv_calls.txt). grep "ZEDQA lv_calls". Built the way lv_move.lua is (its helpers copied: each script stands alone).
--
-- Two crates (A and B, IsoObjects) stand beside the character, as lv_move makes them. No controller is plugged into the
-- QA PC: for the pad cases ZeD's input mode is locked to the controller (Detector.setLockedMode, put back as found) and
-- the presses go through FocusManager's QA hook and its own dispatch (Focus.qaButton + dispatchJoypadDown, rt_pad.lua's
-- and rt_cards.lua's way): a tap is down, a few frames, up, then the hook let go.
-- Checks (the FEATURE_MAP rows each one closes):
--   A filter   (Filter hides) crate A with tools, an apple and planks, sorted by Category: text set to the hammer's
--              name: every listed row matches, _fres.total > _fres.matched, each category heading's count is its
--              matches, the apple's category gone; text that matches nothing: no rows, and the empty line drawn is
--              UI_ZeD_Inv_FilterNone (Molecules.drawEmptyLine watched for a frame); Clear: every row back
--   E card     (Narrow card) an apple in crate A, its row clicked: the 220 card's header verbs lead with TAKE, at the
--              text size found and again in Large text; where Eat does not fit, More's menu holds Eat
--   B attach   (Smart attach on takes) Attach looted tools and weapons on for the case: Loot all of crate A holding a
--              hammer with an empty belt slot that takes it (a slot lent when none is: lv_move's way) queues the game's
--              ISAttachItemHotbar (_zedSmartAttach) after the hammer's transfer, and the hammer ends on that slot; Off:
--              nothing attaches; the slot full: its own thing stays (no swap); two hammers: one attaches per free slot
--   C spare    (Smart attach spare) a baseball bat in the hands at condition 1, two spares at 3 and 9 in the main
--              inventory: the held one broken (its condition set to 0, then the game's OnPlayerAttackFinished fired with
--              it, the event ZeD_SmartAttach.lua listens to; no swing is staged) brings the spare at 3 to hand by
--              ISEquipWeaponAction
--   F no room  (Pad X No room) a backpack on show filled until a plank no longer fits, pad X on crate A's plank: nothing
--              moves, ZeD.Bubbles holds a "bad" note reading UI_ZeD_Drag_NoRoom, CT.lastNoRoom stamped; with room the
--              same X moves it
--   G help     (Pad help line) the pad on crate A's rows: win:_footerPrompts() holds the left arrow + X, Loot all;
--              gone on the strip and once the crate is emptied
--   J stack    (Pad A on a closed stack) three of a kind in crate A, closed: A opens the game's menu with Grab one,
--              Grab half and Grab all; B on the stack opens it (_expandedStacks)
--   H RB       (Pad RB) the pad on crate A's rows: RB tapped steps _activeContainer to the next unlocked container in
--              the strip's order (the Floor, then the list), the tab unchanged, the pad on its first row
--   I Y        (Pad Y) the pad's row in crate B, facing crate A: Y, Y lands on crate A's first row; facing B, Y, Y comes
--              back to the remembered row
--   P guess    (Menu guess setting) menuGuess Off: no guess; On: a guess; Lite (the Style value only, as lv_move's
--              case 1 sets it): no guess whatever the setting says (ZeD.MenuGuess.on() is false in Lite)
--   O use      (Menu guess main use) a bat opens on Equip, a garment not worn on Wear, a book on Read, an apple on
--              Eat; the guessed row is never a danger row
--   N repeat   (Menu guess repeat) Favorite picked on one of two things of a kind: the other's menu opens on it
--   M move     (Menu guess last move) a thing dragged into crate A: the next menu on another thing opens on the row
--              that moves to crate A; 4 tiles away (set, not walked) it is forgotten; a drop on the floor is not noted
--   L needs    (Menu guess needs) hungry: food opens on Eat; thirsty: a water bottle on Drink; a scratch: a bandage on
--              Apply Bandage (a submenu's parent row, not opened); tired: a book on Read
--   D setting  (Attach looted tools and weapons) ZeD setup (the pause menu's Options, never applied): Access sets it
--              On, Vanilla and Plus Off; switched by hand the preset reads Custom; Discard puts every control back
--   K belt     (Belt blocks) a pistol in the hand (Ammo on the belt on for the case) and the Messages notice up:
--              pictures lv_calls_belt_<theme>_<w>x<h> in Dark, Light and High contrast (a person judges them)
--   each case no Lua error over it; put back exactly
-- Puts back: every thing the test made removed; the crates removed; the hands, the clothes, the belt slots lent; the
-- settings (smart attach, menu guess, Style, text size, theme, Ammo on the belt), the stats, god mode, the food timer,
-- the scratch; the input lock and the pad focus; the filter bar, the sort; the menu guess's remembered move and picks;
-- the windows, tabs and the container on show; the character where he stood, facing as found.
if not RT then print("ZEDQA lv_calls ERR rt_kit.lua did not run first"); print("ZEDQA lv_calls DONE"); return end
local Q = RT.make("lv_calls")
Q.maxMs = 1500000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, crates = {}, grid = {}, used = {},
            errs = 0, t0 = getTimestampMs() }
S.F = RT.focus()

S.SMALL = { "Base.Pencil", "Base.Pen", "Base.Eraser", "Base.Paperclip", "Base.RubberBand", "Base.Battery", "Base.Spoon",
            "Base.Fork", "Base.Button", "Base.Dice", "Base.Comb", "Base.Toothbrush", "Base.Sponge", "Base.Cork" }
S.BACKS = { "Base.Bag_Schoolbag", "Base.Bag_NormalHikingBag", "Base.Bag_DuffelBag", "Base.Bag_BigHikingBag" }
S.GARMENTS = { "Base.Hat_BaseballCap", "Base.Tshirt_White", "Base.Socks_Ankle", "Base.Gloves_LeatherGloves", "Base.Hat_Beany" }
S.GLYPH_X = "\226\134\144 X"         -- (the left arrow, then X: ZeD_WorldWindow.padTakeAllHint)

-- ===================================================================== small helpers (lv_move's)
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function S.wait(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end
function S.cc() local w = RT.cw(); return w and w._mainContent or nil end
function S.wc() local w = RT.ww(); return w and w._mainContent or nil end
function S.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function S.list(inv)
    local out = {}
    if inv == nil then return out end
    pcall(function()
        local it = inv:getItems()
        for i = 0, it:size() - 1 do out[#out + 1] = it:get(i) end
    end)
    return out
end
function S.size(inv) local n = -1; if inv then pcall(function() n = inv:getItems():size() end) end; return n end
function S.where(it) local c = nil; if it then pcall(function() c = it:getContainer() end) end; return c end
function S.ft(it) local s = "?"; if it then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function S.nm(it) local s = "nothing"; if it then pcall(function() s = tostring(it:getName()) end) end; return s end
function S.onFloor(it) local wo = nil; if it then pcall(function() wo = it:getWorldItem() end) end; return wo ~= nil end
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
function S.room(inv, it)
    local r = true
    if inv and it then pcall(function() r = inv:hasRoomFor(S.p, it) end) end
    return r and true or false
end
function S.typeOf(inv)
    if inv == nil then return "nothing" end
    local t = "nothing"; pcall(function() t = tostring(inv:getType()) end); return t
end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.dirty()
    pcall(function() ZeD.InventoryRenderer.dirtyModels() end)
    pcall(function() ISInventoryPage.dirtyUI() end)
    pcall(function() local w = RT.cw(); if w then w._containersDirty = true; w._containerTimer = 30 end end)
    pcall(function() local w = RT.ww(); if w then w._containerTimer = 30 end end)
end
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
function S.idsText(t) local o = {}; for _, v in ipairs(t or {}) do o[#o + 1] = tostring(v) end; return (#o > 0) and table.concat(o, ",") or "none" end

-- ===================================================================== things: made, moved, taken away (lv_move's)
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
function S.give(ft) local it = RT.give(ft); return S.mark(it) end
function S.add(inv, ft)
    local it = nil
    pcall(function() it = inv:AddItem(ft) end)
    return S.mark(it)
end
function S.known(ft)
    local ok = false
    pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end)
    return ok
end
function S.firstKnown(list) for _, ft in ipairs(list) do if S.known(ft) then return ft end end; return nil end
function S.unique(kinds)
    local own = S.p:getInventory()
    for _, ft in ipairs(kinds) do
        if not S.used[ft] and S.known(ft) then
            local have = 1
            pcall(function() have = own:getCountTypeRecurse(ft) end)
            if have == 0 then S.used[ft] = true; return ft end
        end
    end
    return nil
end
function S.caseClean()
    for _, it in ipairs(S.caseMade) do S.removeItem(it) end
    S.caseMade = {}
    S.restoreBag()
    S.handsBack()
    S.wornBack()
    S.dirty()
end
function S.restoreBag()
    for _, it in ipairs(S.bagOrig or {}) do
        if S.where(it) ~= S.bag then
            S.removeItem(it)
            pcall(function() S.bag:AddItem(it) end)
        end
    end
end
function S.handsBack()
    local h = S.found.hands
    if not h then return end
    pcall(function() if S.p:getPrimaryHandItem() ~= h.p then S.p:setPrimaryHandItem(h.p) end end)
    pcall(function() if S.p:getSecondaryHandItem() ~= h.s then S.p:setSecondaryHandItem(h.s) end end)
end
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
function S.wornBack()
    local on = S.wornSet()
    for _, e in ipairs(S.found.worn or {}) do
        if not on[e.item] and S.where(e.item) == S.p:getInventory() then
            pcall(function() S.p:setWornItem(e.loc, e.item) end)
        end
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
end
function S.wearOrHold(bag)
    local loc = nil
    pcall(function() loc = bag:getBodyLocation() end)
    local free = false
    pcall(function() free = loc ~= nil and tostring(loc) ~= "" and S.p:getWornItem(loc) == nil end)
    if free then pcall(function() S.p:setWornItem(loc, bag) end) end
    local how = "worn"
    local worn = false
    pcall(function() worn = S.p:isEquippedClothing(bag) end)
    if not worn then
        pcall(function() S.p:setSecondaryHandItem(bag) end)
        how = "held in the second hand"
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    S.dirty()
    return how
end
S.STATS = { "HUNGER", "THIRST", "UNHAPPINESS", "BOREDOM", "STRESS", "FATIGUE", "ENDURANCE" }
function S.statsSnap()
    local s = {}
    for _, k in ipairs(S.STATS) do
        if CharacterStat[k] then pcall(function() s[k] = S.p:getStats():get(CharacterStat[k]) end) end
    end
    return s
end
function S.statsBack(s)
    if not s then return end
    for _, k in ipairs(S.STATS) do
        if s[k] ~= nil then pcall(function() S.p:getStats():set(CharacterStat[k], s[k]) end) end
    end
end
function S.stat(k, v) if CharacterStat[k] then pcall(function() S.p:getStats():set(CharacterStat[k], v) end) end end
function S.moodle(name)
    local n = 0
    pcall(function() n = S.p:getMoodles():getMoodleLevel(MoodleType[name]) end)
    return n or 0
end

-- ===================================================================== the lists, the bands, the menu (lv_move's)
function S.zone(c, id)
    for _, z in ipairs(c and c._hitZones or {}) do if z.id == id then return z end end
    return nil
end
function S.zoneStarts(c, pre)
    for _, z in ipairs(c and c._hitZones or {}) do
        if type(z.id) == "string" and string.sub(z.id, 1, #pre) == pre then return z end
    end
    return nil
end
-- a press and release in the middle of a zone, through the list's own mouse handlers (rt_inventory's H.click)
function S.click(c, z)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c._zedLastClick = nil
    local ok = pcall(function() c:onMouseDown(x, y); c:onMouseUp(x, y) end)
    if not ok then S.errs = S.errs + 1 end
    return ok
end
function S.rep(c, key)
    for _, it in ipairs(c and c._flatItems or {}) do
        local st = c._stacks and c._stacks[it]
        if st and st.key == key and not (c._childParent and c._childParent[it]) then return it, st end
    end
    return nil, nil
end
function S.stackOpen(c, key, open)
    if not c then return end
    c._expandedStacks = c._expandedStacks or {}
    c._expandedStacks[key] = open and true or nil
    for _, cs in ipairs(c._colStates or {}) do
        if cs.expandedStacks then cs.expandedStacks[key] = open and true or nil end
    end
    S.dirty()
end
function S.closedRep(c, key)
    if c and c._expandedStacks and c._expandedStacks[key] then return nil end
    local rep, st = S.rep(c, key)
    if rep and st and (st.count or 0) > 1 then return rep, st end
    return nil, nil
end
function S.listed(win, inv)
    for _, e in ipairs((win and win._containers) or {}) do if e.inventory == inv then return true end end
    return false
end
function S.idxOf(win, inv)
    for i, e in ipairs((win and win._containers) or {}) do if e.inventory == inv then return i end end
    return nil
end
function S.show(inv) if inv then pcall(ZeD_WorldWindow.selectContainer, inv, 200, S.pn) end end
function S.shows(inv) local wc = S.wc(); return wc ~= nil and inv ~= nil and wc._inventory == inv end
function S.showBag(inv) if inv then pcall(ZeD_CharacterWindow.showBagAlone, S.pn, inv) end end
function S.charShows(inv) local cc = S.cc(); return cc ~= nil and inv ~= nil and cc._inventory == inv end
function S.rebuild()
    for _, c in ipairs({ S.cc(), S.wc() }) do
        if c and c._cc then c._cc.frame = -1000 end
    end
end
function S.spec(c, id)
    for _, m in ipairs((c and c._cc and c._cc.moves) or {}) do if m.id == id then return m end end
    return nil
end
function S.specText(sp) if not sp then return "no such button" end; return tostring(sp.label) .. (sp.enabled and " (on)" or " (off)") end
-- a band button pressed as a click presses it
function S.press(c, id)
    local cc = c and c._cc
    for i, h in ipairs(cc and cc.hits or {}) do
        if h.spec and h.spec.id == id then
            if not h.spec.enabled then return false, tostring(h.spec.label) .. " is off" end
            local z = S.zone(c, "cc:" .. i)
            local ok, err = pcall(function()
                if z and z.w > 0 then c:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
                else ZeD.ContainerControls.press(c, i) end
            end)
            if not ok then S.errs = S.errs + 1; return false, "the press threw: " .. tostring(err) end
            return true, tostring(h.spec.label)
        end
    end
    return false, "no button " .. id
end
-- every drop target answers "the pointer is not over me" but target (lv_move's S.over / S.grab / S.let)
function S.over(target, fn)
    local saved = {}
    local function set(o, k, v) saved[#saved + 1] = { o, k, rawget(o, k) }; o[k] = v end
    local cw, ww = RT.cw(), RT.ww()
    local panels = {}
    if cw and cw._mainContent then panels[#panels + 1] = cw._mainContent end
    if ww and ww._mainContent then panels[#panels + 1] = ww._mainContent end
    if cw and cw._containerStrip then panels[#panels + 1] = cw._containerStrip end
    if ww and ww._containerStrip then panels[#panels + 1] = ww._containerStrip end
    for _, o in ipairs(panels) do
        local on = o == target
        set(o, "isMouseOver", function() return on end)
    end
    local hud = nil
    pcall(function() hud = ZeD.Belt.getHUD(S.pn) end)
    if hud and hud ~= target then set(hud, "getMouseX", function() return -1 end) end
    local ok, err = pcall(fn)
    for i = #saved, 1, -1 do local s = saved[i]; s[1][s[2]] = s[3] end
    return ok, err
end
function S.grab(src, item)
    local z = S.zone(src, item)
    if not z then return false, "the row is not on screen" end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    src._zedLastClick = nil
    local okD, errD = pcall(function() src:onMouseDown(x, y) end)
    if not okD then S.errs = S.errs + 1; return false, "the press threw: " .. tostring(errD) end
    local d = src._drag
    if not (d and d:isPending()) then return false, "the press began no drag" end
    d:checkThreshold(d.startX + 40, d.startY + 40)
    if not d:isActive() then pcall(function() d:cancel() end); return false, "the drag did not start" end
    S.grabAt = { x, y }
    return true, "in the air"
end
function S.drag(src, item, target)
    local ok, why = S.grab(src, item)
    if not ok then return false, why end
    local g = S.grabAt or { 0, 0 }
    local okR, err = S.over(target, function() src:onMouseUpOutside(g[1], g[2]) end)
    if not okR then S.errs = S.errs + 1 end
    return okR, okR and "dropped" or ("the release threw: " .. tostring(err))
end
function S.withGlobals(over, fn)
    local was = {}
    for k, v in pairs(over) do was[k] = _G[k]; _G[k] = v end
    local ok, err = pcall(fn)
    for k, v in pairs(was) do _G[k] = v end
    return ok, err
end
function S.dragToWorld(src, item)
    local ok, why = S.grab(src, item)
    if not ok then return false, why end
    local g = S.grabAt or { 0, 0 }
    local okR, err = S.withGlobals({ getMouseX = function() return -60 end, getMouseY = function() return -60 end }, function()
        local ok2, e2 = S.over(nil, function() src:onMouseUpOutside(g[1], g[2]) end)
        if not ok2 then error(e2) end
    end)
    if not okR then S.errs = S.errs + 1 end
    return okR, okR and "released over the world" or ("the release threw: " .. tostring(err))
end
function S.cancelDrags()
    for _, c in ipairs({ S.cc(), S.wc() }) do
        pcall(function() local d = c._drag; if d and (d:isActive() or d:isPending()) then d:cancel(); c:setCapture(false) end end)
    end
    pcall(function() ISMouseDrag.dragging = nil end)
end
function S.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
function S.closeMenu()
    local m = S.menu()
    if m then pcall(function() m:close() end) end
    pcall(function() local v = getPlayerContextMenu(S.pn); if v then v:hideAndChildren() end end)
end
function S.openMenu(items, inInv)
    S.closeMenu()
    local w, h = S.screen()
    local ok, err = pcall(function() ISInventoryPaneContextMenu.createMenu(S.pn, inInv, items, math.floor(w / 2), math.floor(h / 2)) end)
    if not ok then S.errs = S.errs + 1 end
    return ok, err
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

-- ===================================================================== crates (lv_move's)
function S.freeSquares()
    local x, y, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    local free = {}
    for _, d in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x + d[1], y + d[2], z)
        local ok = sq ~= nil
        if sq then pcall(function() ok = sq:isFree(false) end) end
        if ok then free[#free + 1] = sq end
    end
    return free
end
function S.mkCrate(sq, label)
    local c = nil
    pcall(function()
        local o = IsoObject.new(getCell(), sq, "carpentry_01_16")
        o:createContainersFromSpriteProperties()
        sq:AddTileObject(o)
        local inv = o:getContainer()
        if inv then
            pcall(function() inv:setExplored(true) end)
            c = { obj = o, inv = inv, sq = sq, label = label }
        end
    end)
    if c then S.crates[#S.crates + 1] = c end
    return c
end
function S.rmCrate(c)
    if not (c and c.obj) then return end
    pcall(function()
        local sq = c.obj:getSquare() or c.sq
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(c.obj) end); sq:RemoveTileObject(c.obj) end
    end)
    c.obj = nil
    pcall(function() RT.ww()._containerTimer = 30 end)
end
function S.listView(inv)
    local st = S.p:getModData().ZeD_GridViews or {}
    S.p:getModData().ZeD_GridViews = st
    local key = nil
    pcall(function() key = ZeD.InventoryRenderer.containerKey(inv, S.p) end)
    if key and S.grid[key] == nil then
        if st[key] == nil then S.grid[key] = "NIL" else S.grid[key] = st[key] end
        pcall(function() ZeD.InventoryRenderer.setGridKey(key, false, S.p) end)
    end
end
function S.emptyCrate(c) for _, it in ipairs(S.list(c and c.inv)) do S.removeItem(it) end end

-- ===================================================================== the queue watched (lv_move's, the action kept)
function S.qOn()
    if S.qOrig then return end
    S.qLog = {}
    S.qOrig = ISTimedActionQueue.add
    local orig = S.qOrig
    S.qMine = function(action, a2, a3, a4)
        local t, it = nil, nil
        pcall(function() t = action and action.Type; it = action and action.item end)
        S.qLog[#S.qLog + 1] = { t = tostring(t), item = it, a = action }
        return orig(action, a2, a3, a4)
    end
    ISTimedActionQueue.add = S.qMine
end
function S.qOff()
    if not S.qOrig then return end
    if ISTimedActionQueue.add == S.qMine then ISTimedActionQueue.add = S.qOrig end
    S.qOrig, S.qMine = nil, nil
end
function S.qAt(t, item)
    for i, e in ipairs(S.qLog or {}) do if e.t == t and (item == nil or e.item == item) then return i, e end end
    return nil, nil
end
function S.qHas(t, item) return S.qAt(t, item) ~= nil end
function S.qText()
    local t = {}
    for i, e in ipairs(S.qLog or {}) do if i <= 10 then t[#t + 1] = e.t end end
    return #t > 0 and table.concat(t, ", ") or "nothing queued"
end

-- ===================================================================== pictures (lv_move's)
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
S.shots = {}
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

-- ===================================================================== the pad (rt_pad.lua's and rt_cards.lua's way)
-- the input mode ZeD reads, found (dn_footer_head.lua's lockFound)
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
    return true
end
function S.padOff()
    if not S.back.pad then return end
    S.back.pad = nil
    for _, b in ipairs({ "A", "B", "X", "Y", "RightBump" }) do RT.pad(b, nil) end
    pcall(function() S.F.releaseFocus(S.pn) end)
    local Det = ZeD.Input and ZeD.Input.Detector
    pcall(function()
        Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
    end)
end
function S.padMode() local m = nil; pcall(function() m = ZeD.Input.Detector.getMode(S.pn) end); return m end
-- the pad on window w's list, on a row of inv (pred: which row)
function S.focusRow(w, inv, pred)
    if not (w and S.F and S.F.focusWhere) then return nil end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function()
        e = S.F.focusWhere(w, "worldMainInv", function(el)
            if el.item == nil or S.where(el.item) ~= inv then return false end
            return pred == nil or pred(el)
        end)
    end)
    return e
end
function S.focused(w)
    local z, el = nil, nil
    pcall(function() z = S.F.getFocusedZone(w); el = S.F.getFocusedElement(w) end)
    return z, el
end
-- the index of a zone's first row of inv
function S.firstRow(z, inv)
    for i, e in ipairs(z and z.elements or {}) do
        if e.item ~= nil and S.where(e.item) == inv then return i, e end
    end
    return nil, nil
end
-- a tap queued: the QA hook holds the button, FocusManager's dispatch takes the press on the window (wfn() nil: no
-- window holds the pad, the tick reads the hook alone), up after 4 frames, then the hook lets go
-- (nothing is pressed when wfn is given and names no window, or gate says no: a case that could not stage its focus
-- presses nothing on whatever holds the pad instead)
function S.tap(name, joy, wfn, gate)
    local st = {}
    S.step(1, function()
        local w = wfn and wfn()
        if wfn and not w then return end
        if gate and not gate() then return end
        st.on = true
        RT.pad(name, true)
        if w and joy then RT.padDown(Joypad[joy], w) end
    end)
    S.step(4, function() if st.on then RT.pad(name, false) end end)
    S.step(4, function() if st.on then RT.pad(name, nil) end end)
end
function S.rows() local wc = S.wc(); return (wc and #(wc._flatItems or {})) or 0 end
-- scroll the list so item's row is on screen (lv_move's S.reveal)
function S.reveal(c, item)
    local s = c and c._scroll
    local y = c and c._itemRenderYMap and c._itemRenderYMap[item]
    if not (s and y) then return end
    if not (s.visible and s.barSizeRatio and s.barSizeRatio > 0 and s.barSizeRatio < 1) then return end
    local vis = s.height
    local range = vis / s.barSizeRatio - vis
    if range <= 0 then return end
    local logical = y - s.y + math.floor(s.scrollPos * range)
    pcall(function() s:setScrollPos(math.max(0, math.min(1, (logical - math.floor(vis / 3)) / range))) end)
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.err0 = S.errN()
        S.e0 = S.err0
        f.pair = RT.isOpen()
        f.world = S.worldOpen()
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "lv_calls") end
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat() end)
        pcall(function() f.god = S.p:isGodMod() end)
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.worn = S.wornList()
        f.stats = S.statsSnap()
        pcall(function() f.foodTimer = S.p:getBodyDamage():getHealthFromFoodTimer() end)
        f.style = S.optVal(ZeD.Settings and ZeD.Settings.lookStyleOption)
        f.smart = S.optVal(ZeD.Settings and ZeD.Settings.smartAttachOption)
        f.guess = S.optVal(ZeD.Settings and ZeD.Settings.menuGuessOption)
        f.ammo = S.optVal(ZeD.Settings and ZeD.Settings.ammoBoxOption)
        f.base, f.baseIdx = ZeD.currentBase, S.optVal(S.zopt("baseTheme"))
        f.size, f.sizeIdx = ZeD.currentSize, S.optVal(S.zopt("textSize"))
        local G = ZeD.MenuGuess
        if G then f.gMove, f.gPicks = G._moves[S.pn], G._picks[S.pn] end
        f.recorded = true
        S.back.on = true
        S.guard()
        if not (RT.isOpen() and S.worldOpen()) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
        S.instant(true)
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", Style " .. tostring(f.style)
            .. ", smart attach " .. tostring(f.smart) .. ", menu guess " .. tostring(f.guess) .. ", theme " .. tostring(f.base)
            .. ", text " .. tostring(f.size) .. ", input lock " .. S.lockFound() .. ", screen " .. S.sizeTag())
    end)
    S.step(30, function()
        local cw, ww = RT.cw(), RT.ww()
        if not Q.check(cw ~= nil and ww ~= nil, "setup: both windows are open") then S.dead = true; return end
        local f = S.found
        f.charTab, f.worldTab = cw._activeTab, ww._activeTab
        f.charCols, f.worldCols = {}, {}
        for _, j in ipairs(cw._mcSelected or {}) do local e = cw._containers[j]; if e then f.charCols[#f.charCols + 1] = e.inventory end end
        for _, j in ipairs(ww._mcSelected or {}) do local e = ww._containers[j]; if e then f.worldCols[#f.worldCols + 1] = e.inventory end end
        if #f.charCols > 0 then pcall(ZeD_CharacterWindow.closeColumns, cw) end
        if #f.worldCols > 0 then pcall(ZeD_WorldWindow.closeColumns, ww) end
        RT.charTab("loot")
        if not RT.worldTab("loot") then pcall(ZeD_WorldWindow.openTab, S.pn, "loot") end
    end)
    S.step(20, function()
        S.bag = S.p:getInventory()
        local wc = S.wc()
        S.found.worldInv = wc and wc._inventory
        if not S.charShows(S.bag) then S.showBag(S.bag) end
        S.bagOrig = S.list(S.bag)
        local free = S.freeSquares()
        S.A = free[1] and S.mkCrate(free[1], "crate A")
        S.B = free[2] and S.mkCrate(free[2], "crate B")
        if not Q.check(S.A ~= nil and S.B ~= nil, "setup: crates A and B stand beside the character", #free .. " free squares round him") then S.dead = true; return end
        for _, inv in ipairs({ S.bag, S.A.inv, S.B.inv }) do S.listView(inv) end
        S.show(S.A.inv)
    end)
    S.wait(10, 600, function() return S.shows(S.A.inv) and S.charShows(S.bag) end, function(ok)
        if not Q.check(ok, "setup: the World window shows crate A and the Character window the main inventory",
            "World on " .. S.typeOf(S.wc() and S.wc()._inventory)) then S.dead = true end
    end)
end

-- ===================================================================== A. the Filter hides (loot KISS call 7)
function S.catOf(c, it) return tostring((c and c._catOf and c._catOf[it]) or ZeD.InventoryRenderer.catKey(it)) end
function S.typeQuery(F, q)
    if F.field and F.field.onFilter then
        pcall(function() F.field.input:setText(q) end)
        local ok = pcall(F.field.onFilter, F.field, q)
        if not ok then ZeD.InvFilter.setQuery(F, q) end
    else
        ZeD.InvFilter.setQuery(F, q)
    end
end
-- the rows listed all match (a closed stack's row by any thing in it)
function S.rowsMatch(wc, fr)
    local bad = {}
    for _, it in ipairs(wc._flatItems or {}) do
        local ok = fr ~= nil and fr.match[it] == true
        local st = wc._stacks and wc._stacks[it]
        if not ok and fr and st and st.items then
            for _, x in ipairs(st.items) do if fr.match[x] then ok = true end end
        end
        if not ok then bad[#bad + 1] = S.nm(it) end
    end
    return bad
end
function S.caseA()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        S.emptyCrate(S.A)
        local wc = S.wc()
        T.sort = wc and { wc._sortCol, wc._sortAsc }
        T.ham = S.add(S.A.inv, "Base.Hammer")
        for _, ft in ipairs({ "Base.Screwdriver", "Base.Wrench", "Base.Saw", "Base.Apple", "Base.Plank", "Base.Plank" }) do
            if S.known(ft) then S.add(S.A.inv, ft) end
        end
        T.apple = nil
        for _, it in ipairs(S.list(S.A.inv)) do if S.ft(it) == "Base.Apple" then T.apple = it end end
        if wc then wc._sortCol, wc._sortAsc = "cat", true end
        S.dirty()
        S.show(S.A.inv)
    end)
    S.wait(6, 300, function()
        local wc = S.wc()
        return S.shows(S.A.inv) and wc ~= nil and wc._zedFilter ~= nil and S.zoneStarts(wc, "view:filter:") ~= nil and #(wc._flatItems or {}) > 0
    end, function(ok)
        local wc = S.wc()
        if not Q.check(ok and T.ham ~= nil, "A filter: crate A shows its mixed things, sorted by Category, with the Filter button on its heading",
            tostring(S.size(S.A.inv)) .. " things; sort " .. tostring(wc and wc._sortCol)) then T.off = true; return end
        T.F = wc._zedFilter
        T.wasOpen = T.F.open == true
        T.rows0 = #(wc._flatItems or {})
        if not T.F.open then S.click(wc, S.zoneStarts(wc, "view:filter:")) end
    end)
    S.wait(4, 120, function() return T.off or (T.F and T.F.open == true) end, function(ok)
        if T.off then return end
        if not Q.check(ok, "A filter: the Filter button opens the bar") then T.off = true; return end
        T.q = string.lower(S.nm(T.ham))
        S.typeQuery(T.F, T.q)
    end)
    S.step(6, function()
        if T.off then return end
        local wc = S.wc()
        local fr = wc and wc._fres
        local bad = S.rowsMatch(wc, fr)
        -- each heading's number is #_groups[cat] (InventoryRenderer drawCatRow): it must be the category's matches
        local heads, hbad = {}, {}
        for _, cat in ipairs(wc._catOrder or {}) do
            local n = #((wc._groups and wc._groups[cat]) or {})
            local want = fr and fr.catMatched and fr.catMatched[cat] or -1
            heads[#heads + 1] = tostring(cat) .. " " .. n
            if n ~= want or n == 0 then hbad[#hbad + 1] = tostring(cat) .. " shows " .. n .. ", matches " .. tostring(want) end
        end
        local hamCat, inCat = S.catOf(wc, T.ham), 0
        for _, it in ipairs(S.list(S.A.inv)) do if S.catOf(wc, it) == hamCat then inCat = inCat + 1 end end
        local appleCat = T.apple and S.catOf(wc, T.apple)
        local appleGone = appleCat == nil or appleCat == hamCat or not S.inList(wc._catOrder, appleCat)
        Q.check(fr ~= nil and #bad == 0 and #(wc._flatItems or {}) > 0 and (fr.total or 0) > (fr.matched or 0) and wc._useGroups == true
            and #hbad == 0 and appleGone,
            "A filter: with text set every listed row matches, total is above matched, each category heading's count is its matches and a category with none goes",
            "text \"" .. tostring(T.q) .. "\"; " .. tostring(fr and fr.matched) .. " of " .. tostring(fr and fr.total) .. " match; rows not matching: "
            .. S.idsText(bad) .. "; headings " .. S.idsText(heads) .. " (the hammer's category holds " .. inCat .. " in the crate)"
            .. ((#hbad > 0) and ("; wrong: " .. table.concat(hbad, "; ")) or "") .. "; the apple's category " .. tostring(appleCat) .. " gone " .. tostring(appleGone))
        -- text that matches nothing; the list's empty line watched for a frame (Molecules.drawEmptyLine)
        T.saw = {}
        local M = ZeD.Molecules
        if M and M.drawEmptyLine and not S.emptyWas then
            S.emptyWas = M.drawEmptyLine
            local orig = S.emptyWas
            M.drawEmptyLine = function(panel, x, y, w, text, a6, a7)
                if panel == S.wc() then T.saw[#T.saw + 1] = tostring(text) end
                return orig(panel, x, y, w, text, a6, a7)
            end
        end
        S.typeQuery(T.F, "zzqxjv")
    end)
    S.step(6, function()
        S.emptyBack()
        if T.off then return end
        local wc = S.wc()
        local fr = wc and wc._fres
        local none = ZeD.tr("UI_ZeD_Inv_FilterNone")
        Q.check(fr ~= nil and #(wc._flatItems or {}) == 0 and #(wc._catOrder or {}) == 0 and (fr.total or 0) > 0 and fr.matched == 0
            and S.inList(T.saw, none),
            "A filter: text that matches nothing shows no rows and the empty line reads the Filter's Nothing matches (UI_ZeD_Inv_FilterNone)",
            #(wc._flatItems or {}) .. " rows; " .. tostring(fr and fr.matched) .. " of " .. tostring(fr and fr.total) .. "; drawn: " .. S.idsText(T.saw) .. "; want \"" .. tostring(none) .. "\"")
        T.clearZ = S.zone(wc, "view:fbar:clear")
        if T.clearZ then S.click(wc, T.clearZ) else ZeD.InvFilter.clear(T.F) end
    end)
    S.step(6, function()
        if T.off then return end
        local wc = S.wc()
        Q.check(wc._fres == nil and #(wc._flatItems or {}) == T.rows0 and not ZeD.InvFilter.active(T.F),
            "A filter: Clear brings every row back", #(wc._flatItems or {}) .. " rows of " .. tostring(T.rows0) .. "; by the bar's Clear " .. tostring(T.clearZ ~= nil))
        if not T.wasOpen and T.F.open then
            local z = S.zoneStarts(wc, "view:filter:")
            if z then S.click(wc, z) else ZeD.InvFilter.toggleOpen(T.F) end
        end
    end)
    S.step(4, function()
        local wc = S.wc()
        if wc and T.sort then wc._sortCol, wc._sortAsc = T.sort[1], T.sort[2] end
        if T.F and not T.off then Q.check((T.F.open == true) == (T.wasOpen == true), "A filter: the bar is open or shut as found", tostring(T.F.open)) end
        S.caseClean()
    end)
    S.caseEnd("A filter")
end
function S.emptyBack()
    if S.emptyWas then pcall(function() ZeD.Molecules.drawEmptyLine = S.emptyWas end); S.emptyWas = nil end
end

-- ===================================================================== E. the narrow card (loot KISS call 4)
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
function S.card() local w = RT.ww(); return w and w._itemCard end
function S.cardIds()
    local c = S.card()
    local t = {}
    for _, v in ipairs((c and c._lastHeaderVerbs) or {}) do t[#t + 1] = tostring(v.id) end
    return t
end
function S.cardOn(it)
    local w, c = RT.ww(), S.card()
    return it ~= nil and w ~= nil and w._drawerItem == it and c ~= nil and c.item == it and c._lastHeaderVerbs ~= nil
end
function S.clickRow(it)
    local wc = S.wc()
    local z = S.zone(wc, it)
    if not z then return false end
    return S.click(wc, z)
end
function S.cardLeg(T, label)
    S.wait(4, 300, function() return T.off or (S.shows(S.A.inv) and S.zone(S.wc(), T.apple) ~= nil) end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, "E card (" .. label .. "): the apple's row is on screen in crate A"); return end
        if not S.cardOn(T.apple) then S.clickRow(T.apple) end
    end)
    S.wait(6, 300, function() return T.off or S.cardOn(T.apple) end, function(ok)
        if T.off then return end
        local c = S.card()
        local w = 0
        if c then pcall(function() w = c:getWidth() end) end
        local ids = S.cardIds()
        T.res[label] = { ok = ok and ids[1] == "TAKE", ids = ids, w = w, narrow = w > 0 and w < ZeD.T.px(320), noEat = not S.inList(ids, "EAT") }
        Q.say("NOTE E card (" .. label .. "): the card " .. math.floor(w) .. " wide, header verbs " .. S.idsText(ids))
    end)
end
function S.caseE()
    local T = { res = {} }
    S.step(2, function()
        S.caseMade = {}
        S.emptyCrate(S.A)
        T.apple = S.add(S.A.inv, "Base.Apple")
        if not T.apple then T.off = true; Q.skip("E narrow card", "no apple could be made"); return end
        S.dirty()
        S.show(S.A.inv)
    end)
    S.cardLeg(T, "as found")
    S.step(2, function() if not T.off then S.sizeSet("large") end end)
    S.step(30, function() if not T.off then S.show(S.A.inv) end end)
    S.cardLeg(T, "Large text")
    -- where Eat did not fit (TAKE,MORE): More's menu (the card's own verb dispatch, as its click does) holds Eat
    S.step(2, function()
        if T.off then return end
        local r = T.res["Large text"]
        if r and r.noEat and S.inList(r.ids, "MORE") then
            T.more = true
            local c = S.card()
            local ok, err = pcall(function() c:_dispatchHeaderVerb("MORE") end)
            if not ok then S.errs = S.errs + 1; T.more = false; Q.check(false, "E card: More runs", tostring(err)) end
        end
    end)
    S.wait(2, 120, function() return T.off or not T.more or S.menu() ~= nil end, function(ok)
        if T.off then return end
        local eat = getText("ContextMenu_Eat")
        T.moreOk = nil
        if T.more then
            local names = S.menuNames(S.menu())
            T.moreOk = ok and S.inList(names, eat)
            Q.say("NOTE E card: More's menu holds " .. S.idsText(names))
        end
        S.closeMenu()
        local a, b = T.res["as found"], T.res["Large text"]
        if S.found.size == "large" then Q.say("NOTE E card: the text size found was Large already; both legs are Large text") end
        local allTake = a ~= nil and b ~= nil and a.ok and b.ok and a.narrow and b.narrow
        local shapes = true
        for _, r in ipairs({ a, b }) do
            if r then
                local s = table.concat(r.ids, ",")
                if s ~= "TAKE,EAT,MORE" and s ~= "TAKE,MORE" then shapes = false end
            end
        end
        local moreFine = (T.moreOk == nil) or T.moreOk == true
        Q.check(allTake and shapes and moreFine,
            "E card: an apple in crate A gets a narrow card that leads with Grab (TAKE) at both text sizes, and where Eat does not fit More's menu holds it",
            "as found " .. (a and (S.idsText(a.ids) .. " " .. math.floor(a.w) .. " wide") or "not read") .. "; Large text "
            .. (b and (S.idsText(b.ids) .. " " .. math.floor(b.w) .. " wide") or "not read") .. "; More holds " .. getText("ContextMenu_Eat") .. " " .. tostring(T.moreOk))
        if T.moreOk == nil then Q.skip("E card: More's menu holds Eat", "Eat still fit beside Grab and More in Large text at this size, so the main verb never went into More") end
    end)
    S.step(2, function()
        S.sizeBack()
        local wc = S.wc()
        if wc then wc._selectedItems = {} end
    end)
    S.step(20, function()
        Q.check(ZeD.currentSize == S.found.size, "E card: the text size is back as found", tostring(ZeD.currentSize))
        S.caseClean()
    end)
    S.caseEnd("E card")
end

-- ===================================================================== B. smart attach on takes
function S.hb() local hb = nil; pcall(function() hb = getPlayerHotbar(S.pn) end); return hb end
-- the empty slots that take it, lowest first (the game's order, its Attach to menu's; SmartAttach.slotFor's rule)
function S.emptyFits(it)
    local hb = S.hb()
    local out = {}
    if not (hb and hb.availableSlot and it) then return out end
    local atype = nil
    pcall(function() atype = it:getAttachmentType() end)
    local repl = hb.replacements or {}
    for i, s in pairs(hb.availableSlot) do
        local model = s.def and s.def.attachments and s.def.attachments[atype]
        if model and s.def.name == "Back" and repl[atype] then model = repl[atype] end
        if model and model ~= "null" and not (hb.attachedItems or {})[i] then out[#out + 1] = i end
    end
    table.sort(out)
    return out
end
-- a slot that takes it made empty: its own thing comes off (kept in T.lent, given back after)
function S.lendSlot(T, it)
    if #S.emptyFits(it) > 0 then return true end
    local hb = S.hb()
    if not (hb and hb.availableSlot and hb.attachedItems) then return false end
    for i, slot in pairs(hb.availableSlot) do
        local old = hb.attachedItems[i]
        local okA, can = pcall(function() return hb:canBeAttached(slot, it) end)
        if old and okA and can and not T.lent then
            local oldAtt = nil
            pcall(function() oldAtt = slot.def.attachments[old:getAttachmentType()] end)
            if oldAtt then
                T.lent = { item = old, att = oldAtt, i = i, def = slot.def }
                S.back.lent = T.lent
                pcall(function() hb:removeItem(old, false) end)
            end
        end
    end
    return #S.emptyFits(it) > 0
end
function S.giveBack(lent)
    if not lent then return end
    local hb = S.hb()
    if not hb then return end
    pcall(function() if not hb:isInHotbar(lent.item) then hb:attachItem(lent.item, lent.att, lent.i, lent.def, false) end end)
    if S.back.lent == lent then S.back.lent = nil end
end
function S.inHotbar(it) local on = false; pcall(function() on = S.hb():isInHotbar(it) end); return on and true or false end
function S.slotOf(it) local s = -1; pcall(function() s = it:getAttachedSlot() end); return s end
-- one Loot all of crate A with n hammers in it; judge(T, L) checks
function S.attachLeg(T, label, n, on, prep, judge)
    local L = {}
    S.step(2, function()
        if T.off then return end
        S.emptyCrate(S.A)
        prep(L)
        L.hams = {}
        for _ = 1, n do L.hams[#L.hams + 1] = S.add(S.A.inv, "Base.Hammer") end
        S.setOpt(ZeD.Settings.smartAttachOption, on and 2 or 1)
        L.fits = S.emptyFits(L.hams[1])
        S.dirty()
        S.show(S.A.inv)
        S.rebuild()
    end)
    S.wait(6, 300, function() return T.off or (S.shows(S.A.inv) and S.size(S.A.inv) == n and S.spec(S.wc(), "take") ~= nil) end, function(ok)
        if T.off then return end
        S.qOn()
        pcall(function() ZeD.SmartAttach.lastAttached = nil end)
        local okP, why = false, "crate A not shown with its " .. n .. " hammer(s), or no Loot all"
        if ok then okP, why = S.press(S.wc(), "take") end
        L.go = Q.check(okP, "B attach (" .. label .. "): Loot all presses on crate A", why)
    end)
    S.wait(4, 900, S.settled(10), function()
        if T.off then S.qOff(); return end
        if L.go then judge(T, L) end
        S.qOff()
        for _, h in ipairs(L.hams or {}) do S.removeItem(h) end
    end)
end
function S.caseB()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        if not (ZeD.SmartAttach and ZeD.Settings.smartAttachOption and S.hb()) then T.off = true; Q.skip("B smart attach on takes", "ZeD_SmartAttach, its setting or the hotbar is not loaded"); return end
        T.probe = S.give("Base.Hammer")
        T.free = S.lendSlot(T, T.probe)
        S.removeItem(T.probe)
        if not T.free then T.off = true; Q.skip("B smart attach on takes", "no belt slot on this character takes a hammer, even lent"); return end
        Q.say("NOTE B attach: a slot for the hammer " .. (T.lent and ("lent by " .. S.ft(T.lent.item) .. " (slot " .. tostring(T.lent.i) .. ")") or "was empty already"))
    end)
    -- 1. on, a free slot
    S.attachLeg(T, "on, a free slot", 1, true, function() end, function(_, L)
        local h = L.hams[1]
        local iT = S.qAt("ISInventoryTransferAction", h)
        local iA, eA = S.qAt("ISAttachItemHotbar", h)
        local tagged = eA ~= nil and eA.a ~= nil and eA.a._zedSmartAttach == true
        local want = L.fits[1]
        Q.check(iT ~= nil and iA ~= nil and iA > iT and tagged and ZeD.SmartAttach.lastAttached == 1 and S.inHotbar(h) and S.slotOf(h) == want,
            "B attach: with the setting on, Loot all of a crate holding a hammer queues the game's ISAttachItemHotbar (_zedSmartAttach) after the hammer's transfer and the hammer ends on the empty belt slot",
            "queued: " .. S.qText() .. "; transfer at " .. tostring(iT) .. ", attach at " .. tostring(iA) .. ", tagged " .. tostring(tagged)
            .. "; lastAttached " .. tostring(ZeD.SmartAttach.lastAttached) .. "; on the belt " .. tostring(S.inHotbar(h)) .. " at slot " .. tostring(S.slotOf(h)) .. ", want " .. tostring(want))
    end)
    -- 2. off
    S.attachLeg(T, "off", 1, false, function() end, function(_, L)
        local h = L.hams[1]
        Q.check(not S.qHas("ISAttachItemHotbar") and not S.inHotbar(h) and S.where(h) == S.bag,
            "B attach: with the setting off the hammer is taken into the bag and nothing attaches",
            "queued: " .. S.qText() .. "; on the belt " .. tostring(S.inHotbar(h)))
    end)
    -- 3. on, the slot full (its own thing back, or a test hammer on it)
    S.attachLeg(T, "on, the slot full", 1, true, function(L)
        if T.lent then
            S.giveBack(T.lent)
            L.holder, L.slot = T.lent.item, T.lent.i
        else
            local h0 = S.give("Base.Hammer")
            local hb = S.hb()
            local i = S.emptyFits(h0)[1]
            if hb and i then
                pcall(function() local s = hb.availableSlot[i]; hb:attachItem(h0, s.def.attachments[h0:getAttachmentType()], i, s.def, false) end)
            end
            L.holder, L.slot = h0, i
        end
    end, function(_, L)
        local h = L.hams[1]
        local hb = S.hb()
        local still = L.holder ~= nil and L.slot ~= nil and hb ~= nil and hb.attachedItems ~= nil and hb.attachedItems[L.slot] == L.holder
        local others = #L.fits
        Q.check(still and not S.qHas("ISDetachItemHotbar") and (others > 0 or not S.inHotbar(h)),
            "B attach: a belt slot that holds something keeps it, Loot all never swaps",
            "slot " .. tostring(L.slot) .. " holds " .. S.ft(L.holder) .. " still " .. tostring(still) .. "; other empty slots for a hammer " .. others
            .. "; the hammer on the belt " .. tostring(S.inHotbar(h)) .. "; queued: " .. S.qText())
        if not T.lent then S.removeItem(L.holder) end
    end)
    -- 4. on, two hammers, the slot free again
    S.attachLeg(T, "on, two hammers", 2, true, function()
        if T.lent then
            local hb = S.hb()
            pcall(function() hb:removeItem(T.lent.item, false) end)
            S.back.lent = T.lent
        end
    end, function(_, L)
        local on = 0
        for _, h in ipairs(L.hams) do if S.inHotbar(h) then on = on + 1 end end
        local want = math.min(2, #L.fits)
        Q.check(want >= 1 and on == want and ZeD.SmartAttach.lastAttached == want,
            "B attach: two hammers looted with one empty slot that takes them: one goes on the belt, one stays in the bag",
            on .. " on the belt, want " .. want .. " (" .. #L.fits .. " empty slots take a hammer); lastAttached " .. tostring(ZeD.SmartAttach.lastAttached))
    end)
    Q.step(2, function()
        S.setOpt(ZeD.Settings.smartAttachOption, S.found.smart)
        S.giveBack(T.lent)
        if T.lent then Q.check(S.inHotbar(T.lent.item), "B attach: the belt thing that lent its slot is back on the belt", S.ft(T.lent.item)) end
        Q.check(S.optVal(ZeD.Settings.smartAttachOption) == S.found.smart, "B attach: the setting is back as found", tostring(S.optVal(ZeD.Settings.smartAttachOption)))
        if not S.dead then S.caseClean() end
    end)
    S.caseEnd("B smart attach")
end

-- ===================================================================== C. a spare to hand when the weapon breaks
function S.wear(w) local r = 1; pcall(function() r = w:getCondition() / math.max(1, w:getConditionMax()) end); return r end
function S.caseC()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        local SA = ZeD.SmartAttach
        T.ft = S.firstKnown({ "Base.BaseballBat", "Base.Plank", "Base.Crowbar" })
        if not (SA and SA._kindOf and T.ft) then T.off = true; Q.skip("C spare to hand", "ZeD_SmartAttach or a melee weapon kind is missing"); return end
        T.held = S.give(T.ft)
        T.s3 = S.give(T.ft)
        T.s9 = S.give(T.ft)
        pcall(function() T.held:setCondition(1); T.s3:setCondition(3); T.s9:setCondition(9) end)
        -- (a weapon he carries of the same kind, more worn than the spare at 3, would rightly win: then the case says so)
        T.kind = SA._kindOf(T.held)
        local w3 = S.wear(T.s3)
        T.rival = nil
        for _, it in ipairs(S.list(S.bag)) do
            if not S.inList(S.caseMade, it) and instanceof(it, "HandWeapon") and not it:isBroken() and it:getCondition() > 0 then
                local k = nil
                pcall(function() k = SA._kindOf(it) end)
                if k == T.kind and S.wear(it) < w3 then T.rival = it end
            end
        end
        T.two = false
        pcall(function() T.two = T.held:isTwoHandWeapon() end)
        S.setOpt(ZeD.Settings.smartAttachOption, 2)
        pcall(function() S.p:setPrimaryHandItem(T.held) end)
        if T.two then pcall(function() S.p:setSecondaryHandItem(T.held) end) end
    end)
    S.step(6, function()
        if T.off then return end
        if T.rival then T.off = true; Q.skip("C spare to hand", "he carries " .. S.ft(T.rival) .. " of the same kind, more worn than the spare at 3: the rule picks it"); return end
        if not Q.check(S.p:getPrimaryHandItem() == T.held, "C spare: the " .. T.ft .. " at condition 1 is in the hands (" .. tostring(T.kind) .. ")") then T.off = true; return end
        -- the break: its condition to 0, then the game's own event of the swing's end, which ZeD_SmartAttach listens to
        pcall(function() T.held:setCondition(0) end)
        T.broken = false
        pcall(function() T.broken = T.held:isBroken() end)
        S.qOn()
        pcall(function() ZeD.SmartAttach.lastSpare = nil end)
        local ok, err = pcall(triggerEvent, "OnPlayerAttackFinished", S.p, T.held)
        if not ok then S.errs = S.errs + 1; Q.check(false, "C spare: the game's OnPlayerAttackFinished fires", tostring(err)) end
    end)
    S.wait(4, 900, S.settled(10), function()
        if T.off then S.qOff(); return end
        local inHand = S.p:getPrimaryHandItem() == T.s3
        local both = (not T.two) or S.p:getSecondaryHandItem() == T.s3
        Q.check(T.broken and S.qHas("ISEquipWeaponAction", T.s3) and inHand and both and ZeD.SmartAttach.lastSpare == T.s3,
            "C spare: the weapon in the hands broken (condition 0, then the game's OnPlayerAttackFinished) brings the most worn spare, the one at condition 3, to hand by ISEquipWeaponAction",
            "broken " .. tostring(T.broken) .. "; queued: " .. S.qText() .. "; in the hand " .. S.ft(S.p:getPrimaryHandItem()) .. " at "
            .. tostring(S.p:getPrimaryHandItem() and S.p:getPrimaryHandItem():getCondition()) .. "; two hands " .. tostring(T.two) .. " " .. tostring(both))
        S.qOff()
    end)
    Q.step(2, function()
        S.setOpt(ZeD.Settings.smartAttachOption, S.found.smart)
        if not S.dead then S.caseClean() end
        local h = S.found.hands
        Q.check(h == nil or (S.p:getPrimaryHandItem() == h.p and S.p:getSecondaryHandItem() == h.s), "C spare: the hands hold what they held, the setting as found")
    end)
    S.caseEnd("C spare")
end

-- ===================================================================== F. pad X into a bag with no room (loot KISS call 6)
function S.noteSince(t0, text)
    local want = text
    pcall(function() want = ZeD.Bubbles.clean(text) end)
    local list = (ZeD.Bubbles and ZeD.Bubbles._notes and ZeD.Bubbles._notes[S.pn]) or {}
    for _, n in ipairs(list) do
        if n.tone == "bad" and n.text == want and (n.ms or 0) >= t0 then return true, n.text end
    end
    local seen = {}
    for _, n in ipairs(list) do seen[#seen + 1] = tostring(n.tone) .. " " .. tostring(n.text) end
    return false, S.idsText(seen)
end
function S.caseF()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        S.emptyCrate(S.A)
        local bk = S.unique(S.BACKS)
        if not bk then T.off = true; Q.skip("F pad X No room", "no backpack kind he does not carry"); return end
        T.pack = S.give(bk)
        pcall(function() T.pack:setName("LV Full Pack"); T.pack:setCustomName(true) end)
        T.how = S.wearOrHold(T.pack)
        T.pinv = T.pack:getInventory()
        T.plank = S.add(S.A.inv, "Base.Plank")
        T.fill = {}
        while #T.fill < 80 and S.room(T.pinv, T.plank) do
            local it = S.add(T.pinv, "Base.Plank")
            if not it then break end
            T.fill[#T.fill + 1] = it
        end
        T.heavy = false
        pcall(function() T.heavy = isForceDropHeavyItem(T.plank) end)
        if S.room(T.pinv, T.plank) or T.heavy then T.off = true; Q.skip("F pad X No room", "the pack would not fill, or a plank is a heavy thing here"); return end
        S.listView(T.pinv)
        S.dirty()
    end)
    S.wait(4, 300, function() return T.off or S.listed(RT.cw(), T.pinv) end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, "F no room: the pack is on the Character window's buttons", T.how); return end
        S.showBag(T.pinv)
        S.show(S.A.inv)
    end)
    S.wait(4, 300, function() return T.off or (S.charShows(T.pinv) and S.shows(S.A.inv) and S.zone(S.wc(), T.plank) ~= nil) end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, "F no room: the full pack on show, crate A's plank listed"); return end
        if not S.padOn() then T.off = true; Q.skip("F pad X No room", "ZeD's input detector is not loaded"); return end
        T.n0 = S.size(T.pinv)
        T.t0 = getTimestampMs()
        T.on = S.focusRow(RT.ww(), S.A.inv, function(e) return e.item == T.plank end) ~= nil
    end)
    S.tap("X", "XButton", function() return (not T.off and T.on) and RT.ww() or nil end)
    S.wait(4, 600, S.settled(8), function()
        if T.off then return end
        local okN, said = S.noteSince(T.t0, ZeD.tr("UI_ZeD_Drag_NoRoom"))
        local CT = ZeD.ContainerControls
        Q.check(T.on and S.where(T.plank) == S.A.inv and S.size(T.pinv) == T.n0 and okN and (CT.lastNoRoom or 0) >= T.t0,
            "F no room: pad X on a crate row that will not fit the bag on show moves nothing and puts a bad No room note over his head (UI_ZeD_Drag_NoRoom)",
            "the pad on the plank " .. tostring(T.on) .. " (mode " .. tostring(S.padMode()) .. "); plank in " .. S.typeOf(S.where(T.plank)) .. "; the pack " .. S.size(T.pinv) .. " of " .. tostring(T.n0)
            .. "; notes: " .. tostring(said) .. "; lastNoRoom " .. tostring(CT.lastNoRoom))
        for i = 1, 4 do S.removeItem(T.fill[i]) end
        S.dirty()
    end)
    S.wait(4, 120, function() return T.off or S.room(T.pinv, T.plank) end, function(ok)
        if T.off then return end
        T.on2 = ok and S.focusRow(RT.ww(), S.A.inv, function(e) return e.item == T.plank end) ~= nil
    end)
    S.tap("X", "XButton", function() return (not T.off and T.on2) and RT.ww() or nil end)
    S.wait(4, 900, S.settled(8), function()
        if T.off then return end
        Q.check(T.on2 and S.where(T.plank) == T.pinv, "F no room: with room the same pad X moves the row into the bag on show",
            "the plank in " .. S.typeOf(S.where(T.plank)) .. ((S.where(T.plank) == T.pinv) and " (the pack)" or ""))
    end)
    Q.step(2, function()
        S.padOff()
        if S.dead then return end
        S.showBag(S.bag)
        S.caseClean()
    end)
    S.caseEnd("F no room")
end

-- ===================================================================== G. the pad's help line on a crate's rows (call 1)
function S.hintIn(prompts)
    local s = getText("IGUI_invpage_Loot_all")
    local word = s:sub(1, 1) .. s:sub(2):lower()
    for _, p in ipairs(prompts or {}) do
        if p.glyph == S.GLYPH_X and p.label == word then return true, word end
    end
    return false, word
end
function S.promptText(prompts)
    local t = {}
    for _, p in ipairs(prompts or {}) do t[#t + 1] = tostring(p.glyph) .. " " .. tostring(p.label) end
    return S.idsText(t)
end
function S.prompts() local w, pr = RT.ww(), nil; if w then pcall(function() pr = w:_footerPrompts() end) end; return pr end
function S.caseG()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        S.emptyCrate(S.A)
        S.add(S.A.inv, "Base.Apple")
        S.add(S.A.inv, "Base.Pencil")
        S.dirty()
        S.show(S.A.inv)
    end)
    S.wait(4, 300, function() return S.shows(S.A.inv) and S.rows() > 0 end, function(ok)
        if not (ok and S.padOn()) then T.off = true; Q.check(false, "G help line: crate A listed and the pad on"); return end
        T.on = S.focusRow(RT.ww(), S.A.inv) ~= nil
    end)
    S.step(4, function()
        if T.off then return end
        local pr = S.prompts()
        local has, word = S.hintIn(pr)
        Q.check(T.on and has, "G help line: with the pad on a crate's rows in the World window the help line shows the left arrow and X, Loot all",
            "want \"" .. S.GLYPH_X .. "\" + \"" .. word .. "\"; the line: " .. S.promptText(pr) .. "; padOnRows " .. tostring(ZeD_WorldWindow.padOnRows(RT.ww())))
        local ww = RT.ww()
        pcall(function() S.F.focusWhere(ww, "worldContainerStrip", function(e) return e.containerIdx == ww._activeContainer end) end)
    end)
    S.step(4, function()
        if T.off then return end
        local z = S.focused(RT.ww())
        local pr = S.prompts()
        Q.check(z ~= nil and z.zone == "worldContainerStrip" and not S.hintIn(pr), "G help line: on the strip the Loot all prompt is gone",
            "zone " .. tostring(z and z.zone) .. "; the line: " .. S.promptText(pr))
        S.focusRow(RT.ww(), S.A.inv)
        S.emptyCrate(S.A)
        S.dirty()
    end)
    S.step(10, function()
        if T.off then return end
        local pr = S.prompts()
        Q.check(ZeD_WorldWindow.padTakeAllHint(RT.ww()) == nil and not S.hintIn(pr), "G help line: on an emptied crate the Loot all prompt is gone",
            "the line: " .. S.promptText(pr))
    end)
    Q.step(2, function() S.padOff(); if not S.dead then S.caseClean() end end)
    S.caseEnd("G help line")
end

-- ===================================================================== J. pad A on a closed stack: Grab menu; B opens it
function S.caseJ()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        S.emptyCrate(S.A)
        T.k = S.unique(S.SMALL)
        if not T.k then T.off = true; Q.skip("J pad A on a stack", "no small kind left"); return end
        for _ = 1, 3 do S.add(S.A.inv, T.k) end
        S.stackOpen(S.wc(), T.k, false)
        S.show(S.A.inv)
    end)
    S.wait(4, 300, function() return T.off or (S.shows(S.A.inv) and S.closedRep(S.wc(), T.k) ~= nil) end, function(ok)
        if T.off then return end
        if not (ok and S.padOn()) then T.off = true; Q.check(false, "J stack: crate A shows a closed stack of 3 " .. tostring(T.k)); return end
        T.rep = S.closedRep(S.wc(), T.k)
        T.on = S.focusRow(RT.ww(), S.A.inv, function(e) return e.item == T.rep end) ~= nil
    end)
    S.tap("A", "AButton", function() return (not T.off and T.on) and RT.ww() or nil end)
    S.wait(2, 120, function() return T.off or S.menu() ~= nil end, function(ok)
        if T.off then return end
        local names = S.menuNames(S.menu())
        local want = { getText("ContextMenu_Grab_one"), getText("ContextMenu_Grab_half"), getText("ContextMenu_Grab_all") }
        local all = ok
        for _, w in ipairs(want) do if not S.inList(names, w) then all = false end end
        Q.check(T.on and all, "J stack: pad A on a closed stack in crate A opens the game's menu with Grab one, Grab half and Grab all",
            "the pad on the stack " .. tostring(T.on) .. "; the menu: " .. S.idsText(names))
        S.closeMenu()
    end)
    S.step(4, function()
        if T.off then return end
        T.on2 = S.focusRow(RT.ww(), S.A.inv, function(e) return e.item == T.rep end) ~= nil
        if T.on2 then RT.padDown(Joypad.BButton, RT.ww()) end
    end)
    S.step(6, function()
        if T.off then return end
        local wc = S.wc()
        local open = wc ~= nil and wc._expandedStacks ~= nil and wc._expandedStacks[T.k] == true
        Q.check(T.on2 and open, "J stack: pad B on the closed stack opens it (_expandedStacks)", "open " .. tostring(open))
        S.stackOpen(wc, T.k, false)
    end)
    Q.step(2, function() S.padOff(); if not S.dead then S.caseClean() end end)
    S.caseEnd("J stack")
end

-- ===================================================================== H. pad RB on the rows: the next container (call 2)
-- the container RB should go to: the strip's order (the Floor at the top, then the list as drawn), past locked ones
function S.nextAfter(w)
    local cnts = w._containers or {}
    local order = {}
    if cnts[#cnts] and cnts[#cnts].isFloor then order[1] = #cnts end
    local list = w._worldListOrder
    if not (list and w._worldListFor == cnts) then
        list = {}
        for i, c in ipairs(cnts) do if not c.isFloor then list[#list + 1] = i end end
    end
    for _, ci in ipairs(list) do order[#order + 1] = ci end
    local at = 0
    for i, ci in ipairs(order) do if ci == w._activeContainer then at = i end end
    for st = 1, #order do
        local ci = order[((at - 1 + st) % #order) + 1]
        if ci ~= w._activeContainer and cnts[ci] and not cnts[ci].locked then return ci, #order end
    end
    return nil, #order
end
function S.caseH()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        S.emptyCrate(S.A); S.emptyCrate(S.B)
        S.add(S.A.inv, "Base.Apple")
        S.add(S.B.inv, "Base.Pencil")
        S.add(S.B.inv, "Base.Apple")
        S.dirty()
        S.show(S.A.inv)
    end)
    S.wait(4, 300, function() return S.shows(S.A.inv) and S.listed(RT.ww(), S.B.inv) and S.rows() > 0 end, function(ok)
        if not (ok and S.padOn()) then T.off = true; Q.check(false, "H RB: crates A and B listed, A on show, the pad on"); return end
        local ww = RT.ww()
        T.on = S.focusRow(ww, S.A.inv) ~= nil
        T.tab = ww._activeTab
        T.want, T.n = S.nextAfter(ww)
        T.wantInv = T.want and ww._containers[T.want] and ww._containers[T.want].inventory
    end)
    S.tap("RightBump", "RBumper", function() return (not T.off and T.on) and RT.ww() or nil end)
    S.wait(6, 120, function()
        if T.off then return true end
        local ww = RT.ww()
        if not ww then return false end
        local z, el = S.focused(ww)
        return ww._activeContainer == T.want and z ~= nil and (el ~= nil and (el.item ~= nil or z.zone == "worldContainerStrip"))
            and (S.size(T.wantInv) <= 0 or (el.item ~= nil and S.where(el.item) == T.wantInv))
    end, function(ok)
        if T.off then return end
        local ww = RT.ww()
        local z, el = S.focused(ww)
        local first = S.firstRow(z, T.wantInv)
        local onFirst
        if S.size(T.wantInv) > 0 then onFirst = z ~= nil and z.zone == "worldMainInv" and z.focusedElementIdx == first
        else onFirst = z ~= nil and z.zone == "worldContainerStrip" and el ~= nil and el.containerIdx == T.want end
        local e = ww._containers[ww._activeContainer]
        Q.check(T.on and ok and ww._activeContainer == T.want and ww._activeTab == T.tab and onFirst,
            "H RB: RB tapped on the World window's rows shows the next unlocked container in the strip's order, the tab unchanged, the pad on its first row",
            "from crate A to " .. tostring(ww._activeContainer) .. " (" .. tostring(e and e.name) .. "), want " .. tostring(T.want) .. " of " .. tostring(T.n)
            .. "; tab " .. tostring(T.tab) .. " -> " .. tostring(ww._activeTab) .. "; focus " .. tostring(z and z.zone) .. " " .. tostring(z and z.focusedElementIdx) .. ", first " .. tostring(first))
    end)
    Q.step(2, function()
        S.padOff()
        if S.dead then return end
        S.caseClean()
        S.show(S.A.inv)
    end)
    S.caseEnd("H RB")
end

-- ===================================================================== I. pad Y lands on the crate he faces (call 3)
S.DIRS = { ["0,-1"] = "N", ["1,-1"] = "NE", ["1,0"] = "E", ["1,1"] = "SE", ["0,1"] = "S", ["-1,1"] = "SW", ["-1,0"] = "W", ["-1,-1"] = "NW" }
function S.face(c)
    local dx = c.sq:getX() - math.floor(S.p:getX())
    local dy = c.sq:getY() - math.floor(S.p:getY())
    local d = S.DIRS[dx .. "," .. dy]
    if d and IsoDirections[d] then pcall(function() S.p:setDir(IsoDirections[d]) end); return true end
    return false
end
-- Y tapped twice: the pair hides (the row remembered), then comes back
function S.yTwice(T)
    S.tap("Y", "YButton", function() return (not T.off) and RT.ww() or nil end)
    S.wait(2, 300, function() return T.off or (not RT.isOpen() and not S.worldOpen()) end, function(ok)
        if T.off then return end
        T.hid = ok
    end)
    S.tap("Y", nil, nil, function() return not T.off and T.hid == true end)
    S.wait(2, 600, function() return T.off or (RT.isOpen() and S.worldOpen()) end, function(ok)
        if T.off then return end
        T.back = ok
    end)
end
function S.caseI()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        S.emptyCrate(S.A); S.emptyCrate(S.B)
        S.add(S.A.inv, "Base.Apple"); S.add(S.A.inv, "Base.Pencil")
        S.add(S.B.inv, "Base.Pen"); S.add(S.B.inv, "Base.Eraser"); S.add(S.B.inv, "Base.Spoon")
        S.dirty()
        S.show(S.B.inv)
    end)
    S.wait(4, 300, function() return S.shows(S.B.inv) and S.rows() > 1 end, function(ok)
        if not (ok and S.padOn()) then T.off = true; Q.check(false, "I Y: crate B on show, the pad on"); return end
        local z = nil
        local first = nil
        T.on = S.focusRow(RT.ww(), S.B.inv) ~= nil
        z = S.focused(RT.ww())
        first = S.firstRow(z, S.B.inv)
        -- (a row of B that is not its first: the second row, so "back on the row" is told from "on the first row")
        if z and first and z.elements[first + 1] and z.elements[first + 1].item then
            local it = z.elements[first + 1].item
            S.focusRow(RT.ww(), S.B.inv, function(e) return e.item == it end)
        end
        local _, el = S.focused(RT.ww())
        T.mem = el and el.item
        T.faced = S.face(S.A)
    end)
    S.yTwice(T)
    S.wait(4, 300, function()
        if T.off or not T.back then return true end
        local ww = RT.ww()
        local z, el = S.focused(ww)
        return ww ~= nil and S.F.getFocusedWindow(S.pn) == ww and el ~= nil and el.item ~= nil and S.where(el.item) == S.A.inv
    end, function(ok)
        if T.off then return end
        local ww = RT.ww()
        local z, el = S.focused(ww)
        local first = S.firstRow(z, S.A.inv)
        local e = ww and ww._containers and ww._containers[ww._activeContainer]
        Q.check(T.on and T.faced and T.hid and T.back and ok and e ~= nil and e.inventory == S.A.inv and z ~= nil and z.focusedElementIdx == first,
            "I Y: with the pad's row in crate B and the character facing crate A, Y then Y lands on crate A's first row",
            "the row left " .. S.nm(T.mem) .. " in B; hid " .. tostring(T.hid) .. ", back " .. tostring(T.back) .. "; on show " .. tostring(e and e.name)
            .. "; focus " .. tostring(z and z.zone) .. " " .. tostring(z and z.focusedElementIdx) .. " (" .. S.nm(el and el.item) .. "), first " .. tostring(first))
        -- the second leg: the row in B again, facing B
        T.hid, T.back = nil, nil
        S.show(S.B.inv)
    end)
    S.wait(4, 300, function() return T.off or S.shows(S.B.inv) end, function(ok)
        if T.off then return end
        T.on2 = ok and T.mem ~= nil and S.focusRow(RT.ww(), S.B.inv, function(e) return e.item == T.mem end) ~= nil
        T.faced2 = S.face(S.B)
    end)
    S.yTwice(T)
    S.wait(4, 300, function()
        if T.off or not T.back then return true end
        local _, el = S.focused(RT.ww())
        return el ~= nil and el.item == T.mem
    end, function(ok)
        if T.off then return end
        local _, el = S.focused(RT.ww())
        Q.check(T.on2 and T.faced2 and T.hid and T.back and ok, "I Y: facing crate B, the crate the row was in, Y then Y comes back to the remembered row",
            "want " .. S.nm(T.mem) .. ", on " .. S.nm(el and el.item) .. "; hid " .. tostring(T.hid) .. ", back " .. tostring(T.back))
    end)
    Q.step(2, function()
        S.padOff()
        if S.found.dir then pcall(function() S.p:setDir(S.found.dir) end) end
        if not (RT.isOpen() and S.worldOpen()) then RT.pairOpen() end
        if S.dead then return end
        RT.charTab("loot")
        if not RT.worldTab("loot") then pcall(ZeD_WorldWindow.openTab, S.pn, "loot") end
        S.caseClean()
        S.showBag(S.bag)
        S.show(S.A.inv)
    end)
    S.wait(4, 300, function() return S.shows(S.A.inv) end, function() end)
    S.caseEnd("I Y")
end

-- ===================================================================== the menu's best guess (smart menu): helpers
function S.nameIs(name, keys)
    if type(name) ~= "string" then return false end
    for _, k in ipairs(keys) do
        local t = getTextOrNull(k)
        if t then
            if name == t then return true end
            local cut = string.find(t, "%1", 1, true)
            local pre = cut and string.sub(t, 1, cut - 1) or nil
            if pre and pre ~= "" and string.sub(name, 1, #pre) == pre then return true end
        end
    end
    return false
end
-- what the open item menu guessed and shows: idx, rule, its row, the selection, a submenu open
function S.guessRead()
    local g = {}
    local c = nil
    pcall(function() c = getPlayerContextMenu(S.pn) end)
    if c then g.idx, g.rule = c._zedGuessIdx, c._zedGuessRule end
    local m = S.menu()
    local acts = m and m._ctx and m._ctx.actions
    if g.idx and acts then g.def = acts[g.idx] end
    g.name = g.def and g.def.name
    g.kids = g.def ~= nil and g.def.children ~= nil and #g.def.children > 0
    if m and m._levels then
        local lv = m._levels[1]
        local r = (lv and lv.sel and lv.rows) and lv.rows[lv.sel] or nil
        g.look, g.sel = "list", lv and lv.sel
        g.selName = r and r.def and r.def.name
        g.selOk = g.def ~= nil and r ~= nil and r.def == g.def
        g.sub = #m._levels > 1
        local fl = nil
        if lv then pcall(function() fl = m:_firstLive(lv, 1, 1) end) end
        g.firstSel = lv ~= nil and lv.sel == (fl or 1)
    elseif m and m._ctx then
        g.look, g.sel = "strip", m._ctx.selected
        if acts and m._ctx.selected then g.selName = acts[m._ctx.selected] and acts[m._ctx.selected].name end
        g.selOk = g.idx ~= nil and m._ctx.selected == g.idx
        g.sub = #(m._ctx.path or {}) > 0
        g.firstSel = (m._ctx.selected or 1) == 1
    end
    local G = ZeD.MenuGuess
    local L = G and G.last and G.last[S.pn]
    g.lastName, g.lastRule = L and L.name, L and L.rule
    g.danger = g.def ~= nil and G ~= nil and G.isDanger(g.def)
    g.menu = m ~= nil
    return g
end
function S.gText(g)
    return "rule " .. tostring(g.rule) .. " on row " .. tostring(g.idx) .. " \"" .. tostring(g.name) .. "\" (" .. tostring(g.look)
        .. ", selection " .. tostring(g.sel) .. " \"" .. tostring(g.selName) .. "\" on it " .. tostring(g.selOk) .. ", a submenu "
        .. tostring(g.kids) .. ", one open " .. tostring(g.sub) .. "); MenuGuess.last " .. tostring(g.lastRule) .. " \"" .. tostring(g.lastName) .. "\""
end
-- an item menu opened on items (lv_move's openMenu, the game's createMenu), read the frame ZeD builds it, closed
function S.guessLeg(T, itemsFn, judge)
    local L = {}
    S.step(2, function()
        if T.off then return end
        L.items = itemsFn()
        if not (L.items and L.items[1]) then L.off = true; judge(nil, L); return end
        S.openMenu(L.items, true)
    end)
    S.wait(2, 120, function() return T.off or L.off or S.menu() ~= nil end, function(ok)
        if T.off or L.off then return end
        local g = S.guessRead()
        g.menu = ok
        judge(g, L)
        S.closeMenu()
    end)
end
-- the guess's remembered move and picks out of the way for a case, and back after (they are its own state)
function S.gClear()
    local G = ZeD.MenuGuess
    if not G then return end
    G._moves[S.pn], G._picks[S.pn] = nil, nil
end
function S.gBack()
    local G = ZeD.MenuGuess
    if not G then return end
    G._moves[S.pn], G._picks[S.pn] = S.found.gMove, S.found.gPicks
end
-- no need for the cases that are not about needs: not hungry, thirsty or tired (put back after)
function S.calm()
    S.stat("HUNGER", 0); S.stat("THIRST", 0); S.stat("FATIGUE", 0)
end
function S.calmNow() return S.moodle("HUNGRY") == 0 and S.moodle("THIRST") == 0 and S.moodle("TIRED") == 0 end

-- ===================================================================== P. the setting: Off, On, Lite
function S.caseP()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        if not (ZeD.MenuGuess and ZeD.Settings.menuGuessOption and ZeD.Settings.lite) then T.off = true; Q.skip("P menu guess setting", "ZeD_MenuGuess or its setting is not loaded"); return end
        S.gClear()
        S.calm()
        T.bat = S.give(S.firstKnown({ "Base.BaseballBat", "Base.Crowbar" }) or "Base.Hammer")
    end)
    S.wait(2, 300, function() return T.off or S.calmNow() end, function(ok)
        if T.off then return end
        if not ok then Q.say("NOTE P: a need moodle is still up after the stats were set to 0") end
        S.setOpt(ZeD.Settings.menuGuessOption, 2)
    end)
    S.guessLeg(T, function() return { T.bat } end, function(g)
        T.on = g ~= nil and g.idx ~= nil
        T.onText = g and S.gText(g) or "no menu"
        S.setOpt(ZeD.Settings.menuGuessOption, 1)
    end)
    S.guessLeg(T, function() return { T.bat } end, function(g)
        local okOff = g ~= nil and g.menu and g.idx == nil and g.lastRule == nil and g.firstSel and ZeD.MenuGuess.on() == false
        Q.check(T.on and okOff, "P setting: menuGuess Off opens the item menu on its first row with no guess (On, the same menu has one)",
            "On: " .. tostring(T.onText) .. " | Off: " .. (g and S.gText(g) or "no menu") .. ", on its first row " .. tostring(g and g.firstSel))
        -- Lite with the setting On: the Style value only (as lv_move's case 1 sets it; the additions are not touched)
        S.setOpt(ZeD.Settings.menuGuessOption, 2)
        S.setOpt(ZeD.Settings.lookStyleOption, 2)
        S.back.lite = true
    end)
    S.guessLeg(T, function() return { T.bat } end, function(g)
        local lite = false
        pcall(function() lite = ZeD.Settings.lite() end)
        Q.check(lite and g ~= nil and g.menu and g.idx == nil and g.firstSel and ZeD.MenuGuess.on() == false,
            "P setting: in Lite the item menu makes no guess and opens on its first row, even with menuGuess On (ZeD.MenuGuess.on() is false in Lite)",
            "lite() " .. tostring(lite) .. ", menuGuess " .. tostring(S.optVal(ZeD.Settings.menuGuessOption)) .. "; " .. (g and S.gText(g) or "no menu"))
        S.setOpt(ZeD.Settings.lookStyleOption, S.found.style)
        S.back.lite = nil
        S.setOpt(ZeD.Settings.menuGuessOption, S.found.guess)
    end)
    Q.step(2, function()
        if T.off then return end
        Q.check(S.optVal(ZeD.Settings.lookStyleOption) == S.found.style and S.optVal(ZeD.Settings.menuGuessOption) == S.found.guess,
            "P setting: Style and menuGuess are back as found", tostring(S.optVal(ZeD.Settings.lookStyleOption)) .. ", " .. tostring(S.optVal(ZeD.Settings.menuGuessOption)))
        S.statsBack(S.found.stats)
        S.gBack()
        if not S.dead then S.caseClean() end
    end)
    S.caseEnd("P menu guess setting")
end

-- ===================================================================== O. main use
function S.caseO()
    local T = { res = {} }
    S.step(2, function()
        S.caseMade = {}
        if not ZeD.MenuGuess then T.off = true; Q.skip("O main use", "ZeD_MenuGuess is not loaded"); return end
        S.gClear()
        S.calm()
        -- (QA, Nov 24 2026, after the first run: with the Well Fed moodle at 3 the game greys Eat, and a greyed row is never
        -- guessed: the food timer emptied, as case L does; the run's end puts it back from S.found.foodTimer)
        pcall(function() S.p:getBodyDamage():setHealthFromFoodTimer(0) end)
        S.setOpt(ZeD.Settings.menuGuessOption, 2)
        T.legs = {
            { what = "a weapon", ft = S.firstKnown({ "Base.BaseballBat", "Base.Crowbar" }), keys = { "ContextMenu_Equip_Primary", "ContextMenu_Equip_Two_Hands" } },
            { what = "a garment not worn", ft = S.unique(S.GARMENTS), keys = { "ContextMenu_Wear" } },
            { what = "a book", ft = S.firstKnown({ "Base.Book" }), keys = { "ContextMenu_Read" } },
            { what = "food", ft = "Base.Apple", keys = { "ContextMenu_Eat", "ContextMenu_OpenAndEat" } },
        }
        for _, l in ipairs(T.legs) do l.it = l.ft and S.give(l.ft) end
    end)
    S.wait(2, 300, function() return T.off or S.calmNow() end, function() end)
    for i = 1, 4 do
        S.guessLeg(T, function() local l = T.legs and T.legs[i]; return l and { l.it } end, function(g)
            local l = T.legs[i]
            if not g then T.res[i] = { ok = false, d = l.what .. ": not made" }; return end
            local ok = g.menu and g.rule == "use" and S.nameIs(g.name, l.keys) and not g.danger and g.selOk and not g.sub
            T.res[i] = { ok = ok, d = l.what .. " (" .. S.ft(l.it) .. "): " .. S.gText(g) .. ", danger " .. tostring(g.danger) }
        end)
    end
    Q.step(2, function()
        if T.off then return end
        local all, d = true, {}
        for i = 1, 4 do
            local r = T.res[i] or { ok = false, d = "not read" }
            if not r.ok then all = false end
            d[#d + 1] = r.d
        end
        Q.check(all, "O main use: an item menu opens on its main use: a weapon on Equip, a garment not worn on Wear, a book on Read, food on Eat, never a danger row",
            table.concat(d, " | "))
        S.setOpt(ZeD.Settings.menuGuessOption, S.found.guess)
        S.statsBack(S.found.stats)
        S.gBack()
        if not S.dead then S.caseClean() end
    end)
    S.caseEnd("O main use")
end

-- ===================================================================== N. repeat: the last pick on the same kind
function S.caseN()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        if not ZeD.MenuGuess then T.off = true; Q.skip("N repeat", "ZeD_MenuGuess is not loaded"); return end
        S.gClear()
        S.calm()
        S.setOpt(ZeD.Settings.menuGuessOption, 2)
        T.k = S.unique(S.SMALL)
        if not T.k then T.off = true; Q.skip("N repeat", "no small kind left"); return end
        T.one, T.two = S.give(T.k), S.give(T.k)
        T.fav = getText("IGUI_CraftUI_Favorite")
    end)
    S.wait(2, 300, function() return T.off or S.calmNow() end, function() end)
    S.step(2, function() if not T.off then S.openMenu({ T.one }, true) end end)
    S.wait(2, 120, function() return T.off or S.menu() ~= nil end, function(ok)
        if T.off then return end
        local okP, why = false, "no ZeD menu"
        if ok then okP, why = S.pick(S.menu(), { T.fav }) end
        local P = ZeD.MenuGuess._picks[S.pn]
        local kept = P and P.map and P.map[T.k]
        T.picked = Q.check(okP and kept ~= nil and kept[1] == T.fav, "N repeat: Favorite picked on one " .. T.k .. " is remembered for its kind",
            why .. "; remembered " .. S.idsText(kept))
        if not okP then S.closeMenu() end
    end)
    S.guessLeg(T, function() return T.picked and { T.two } or nil end, function(g)
        if not g then return end
        Q.check(g.menu and g.rule == "repeat" and g.name == T.fav and g.selOk, "N repeat: the next item menu on another thing of the same kind opens on the row picked last time",
            S.gText(g))
    end)
    Q.step(2, function()
        if T.off then return end
        pcall(function() T.one:setFavorite(false); T.two:setFavorite(false) end)
        S.setOpt(ZeD.Settings.menuGuessOption, S.found.guess)
        S.statsBack(S.found.stats)
        S.gBack()
        if not S.dead then S.caseClean() end
    end)
    S.caseEnd("N repeat")
end

-- ===================================================================== M. the last move
function S.caseM()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        if not ZeD.MenuGuess then T.off = true; Q.skip("M last move", "ZeD_MenuGuess is not loaded"); return end
        S.gClear()
        S.calm()
        S.setOpt(ZeD.Settings.menuGuessOption, 2)
        S.emptyCrate(S.A)
        -- (three kinds he carries none of: each its own row, never a stack that would carry two)
        T.k1, T.k2, T.k3 = S.unique(S.SMALL), S.unique(S.SMALL), S.unique(S.SMALL)
        if not (T.k1 and T.k2 and T.k3) then T.off = true; Q.skip("M last move", "no three small kinds left"); return end
        T.moved = S.give(T.k1)
        T.other = S.give(T.k2)
        T.drop = S.give(T.k3)
        S.dirty()
        S.show(S.A.inv)
    end)
    S.wait(4, 300, function()
        if T.off then return true end
        S.reveal(S.cc(), T.moved)
        return S.shows(S.A.inv) and S.charShows(S.bag) and S.zone(S.cc(), T.moved) ~= nil and S.calmNow()
    end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, "M move: the thing's row in the bag and crate A on show"); return end
        local okD, why = S.drag(S.cc(), T.moved, S.wc())
        T.d = Q.check(okD, "M move: the thing drags from the bag into crate A", why)
    end)
    S.wait(4, 600, S.settled(8), function()
        if T.off or not T.d then T.off = true; return end
        local m = ZeD.MenuGuess._moves[S.pn]
        T.noted = m ~= nil and m.dest == S.A.inv and S.where(T.moved) == S.A.inv
        if not T.noted then Q.say("NOTE M move: after the drag the thing is in " .. S.typeOf(S.where(T.moved)) .. ", the move noted for " .. S.typeOf(m and m.dest)) end
    end)
    S.guessLeg(T, function() return { T.other } end, function(g)
        T.mv = g
        local moves = g.def ~= nil and ZeD.MenuGuess.movesTo ~= nil
        local into = false
        if g.def then
            pcall(function() into = ZeD.MenuGuess.movesTo(g.def, S.A.inv, S.pn) end)
            for _, k in ipairs(g.def.children or {}) do
                local yes = false
                pcall(function() yes = ZeD.MenuGuess.movesTo(k, S.A.inv, S.pn) end)
                if yes then into = true end
            end
        end
        Q.check(T.noted and g.menu and g.rule == "move" and into and g.selOk and not g.sub and moves,
            "M move: after a thing is moved into crate A the next item menu on another thing opens on the row that moves it to crate A",
            "noted " .. tostring(T.noted) .. "; " .. S.gText(g) .. "; the row moves to crate A " .. tostring(into))
        -- four tiles away (set, not walked): the move is forgotten
        T.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        S.goTo(T.pos.x + 4, T.pos.y, T.pos.z)
    end)
    S.guessLeg(T, function() return { T.other } end, function(g)
        Q.check(g.menu and g.rule ~= "move" and ZeD.MenuGuess._moves[S.pn] == nil, "M move: four tiles away the move is forgotten (no move guess, nothing remembered)",
            S.gText(g) .. "; remembered " .. tostring(ZeD.MenuGuess._moves[S.pn] ~= nil))
        S.goTo(T.pos.x, T.pos.y, T.pos.z)
    end)
    S.wait(4, 300, function()
        if T.off then return true end
        S.reveal(S.cc(), T.drop)
        return S.zone(S.cc(), T.drop) ~= nil and S.shows(S.A.inv)
    end, function(ok)
        if T.off then return end
        ZeD.MenuGuess._moves[S.pn] = nil
        local okD, why = false, "the row is not on screen"
        if ok then okD, why = S.dragToWorld(S.cc(), T.drop) end
        T.fd = okD
        if not okD then Q.say("NOTE M move: the drop on the floor did not run: " .. tostring(why)) end
    end)
    S.wait(4, 600, S.settled(8), function()
        if T.off then return end
        Q.check(T.fd and S.onFloor(T.drop) and ZeD.MenuGuess._moves[S.pn] == nil, "M move: a thing dropped on the floor is never noted as a move",
            "on the floor " .. tostring(S.onFloor(T.drop)) .. "; remembered " .. tostring(ZeD.MenuGuess._moves[S.pn] ~= nil))
    end)
    Q.step(2, function()
        if T.pos then S.goTo(T.pos.x, T.pos.y, T.pos.z) end
        S.setOpt(ZeD.Settings.menuGuessOption, S.found.guess)
        S.statsBack(S.found.stats)
        S.gBack()
        if not S.dead then S.caseClean() end
    end)
    S.caseEnd("M last move")
end

-- ===================================================================== L. needs
S.NEEDS = {
    { id = "hungry", stat = "HUNGER", v = 0.35, moodle = "HUNGRY", ft = "Base.Apple", keys = { "ContextMenu_Eat", "ContextMenu_OpenAndEat" } },
    { id = "thirsty", stat = "THIRST", v = 0.35, moodle = "THIRST", ft = "Base.WaterBottle", fill = true, keys = { "ContextMenu_Drink", "ContextMenu_OpenAndDrink" } },
    { id = "wound", wound = true, ft = "Base.Bandage", keys = { "ContextMenu_Apply_Bandage", "ContextMenu_Bandage", "ContextMenu_Disinfect", "ContextMenu_Splint" } },
    { id = "tired", stat = "FATIGUE", v = 0.75, moodle = "TIRED", ft = "Base.Book", keys = { "ContextMenu_Read" } },
}
function S.hurt() local h = false; pcall(function() h = ZeD.QuickWheel.hurt(S.p) end); return h and true or false end
function S.scratch(on)
    local b = nil
    pcall(function() b = S.p:getBodyDamage():getBodyPart(BodyPartType.Hand_L) end)
    if not b then return false end
    if on then
        pcall(function() b:setScratched(true, true); b:setScratchTime(15) end)
        S.back.scratch = true
    elseif S.back.scratch then
        S.back.scratch = nil
        pcall(function() b:setScratched(false, true); b:setScratchTime(0) end)
    end
    return true
end
function S.needLeg(T, n)
    local L = {}
    S.step(2, function()
        if T.off then return end
        S.calm()
        if n.stat then S.stat(n.stat, n.v) end
        if n.wound and not S.hurt() then S.scratch(true) end
        -- (QA, Nov 24 2026, after the first run: the game's auto-drink emptied his thirst from the full bottle he was given,
        -- getCore():getOptionAutoDrink(); off for the leg, put back at the case's end)
        if n.fill then
            pcall(function()
                if S.autoDrinkWas == nil then S.autoDrinkWas = getCore():getOptionAutoDrink() end
                getCore():setOptionAutoDrink(false)
            end)
        end
        L.it = S.give(n.ft)
        -- (QA, Nov 24 2026, after the second run: a book whose literature title he has read offers Reread, and ZeD never
        -- guesses a book already read: a book with an unread title is given, up to 20 tries, else its title is cleared)
        if n.id == "tired" and L.it then
            for _ = 1, 20 do
                local t, read = nil, false
                pcall(function() t = L.it:getModData().literatureTitle end)
                if t then pcall(function() read = S.p:isLiteratureRead(t) end) end
                if not read then break end
                S.removeItem(L.it)
                L.it = S.give(n.ft)
                if not L.it then break end
            end
            pcall(function()
                local t = L.it:getModData().literatureTitle
                if t and S.p:isLiteratureRead(t) then L.it:getModData().literatureTitle = nil end
            end)
        end
        if n.fill and L.it then
            pcall(function() local fc = L.it:getFluidContainer(); fc:Empty(); fc:addFluid(FluidType.Water, fc:getCapacity()) end)
        end
    end)
    S.wait(2, 600, function()
        if T.off then return true end
        local others = 0
        for _, m in ipairs(S.NEEDS) do if m.moodle and m ~= n and S.moodle(m.moodle) > 0 then others = others + 1 end end
        local mine = (n.moodle and S.moodle(n.moodle) >= 1) or (n.wound and S.hurt())
        return mine and others == 0 and S.moodle("FOOD_EATEN") < 3
    end, function(ok)
        if T.off then return end
        L.ready = ok
        if not ok then Q.say("NOTE L " .. n.id .. ": the need did not show alone in time (hungry " .. S.moodle("HUNGRY") .. ", thirst " .. S.moodle("THIRST")
            .. ", tired " .. S.moodle("TIRED") .. ", hurt " .. tostring(S.hurt()) .. ", well fed " .. S.moodle("FOOD_EATEN") .. ")") end
    end)
    S.guessLeg(T, function() return L.it and { L.it } or nil end, function(g)
        if not g then T.res[#T.res + 1] = { ok = false, d = n.id .. ": " .. n.ft .. " not made" }; return end
        local ok = L.ready and g.menu and g.rule == n.id and S.nameIs(g.name, n.keys) and g.selOk and not g.sub
        T.res[#T.res + 1] = { ok = ok, d = n.id .. " (" .. n.ft .. "): " .. S.gText(g) }
        if n.wound then T.sub = g.kids; T.subOpen = g.sub end
        S.calm()
        S.scratch(false)
    end)
end
function S.caseL()
    local T = { res = {} }
    S.step(2, function()
        S.caseMade = {}
        if not (ZeD.MenuGuess and ZeD.QuickWheel and ZeD.QuickWheel.hurt) then T.off = true; Q.skip("L needs", "ZeD_MenuGuess or the wound test is not loaded"); return end
        S.gClear()
        S.setOpt(ZeD.Settings.menuGuessOption, 2)
        -- (god mode may hold the stats and heal: off for the case, invincible stays; the game will not start an eat with
        -- the Well Fed moodle at 3 or more, ISEatFoodAction:isValidStart: the food timer emptied, as lv_move's case 15)
        pcall(function() S.p:setGodMod(false) end)
        S.back.god = true
        pcall(function() S.p:getBodyDamage():setHealthFromFoodTimer(0) end)
    end)
    for _, n in ipairs(S.NEEDS) do S.needLeg(T, n) end
    Q.step(2, function()
        if S.autoDrinkWas ~= nil then
            local was = S.autoDrinkWas
            pcall(function() getCore():setOptionAutoDrink(was) end)
            S.autoDrinkWas = nil
        end
        if T.off then return end
        local all, d = #T.res == #S.NEEDS, {}
        for _, r in ipairs(T.res) do if not r.ok then all = false end; d[#d + 1] = r.d end
        Q.check(all, "L needs: hungry, food opens on Eat; thirsty, a drink on Drink; hurt, a bandage on Apply Bandage; tired, a book on Read",
            table.concat(d, " | "))
        Q.check(T.sub == nil or not T.subOpen, "L needs: a guess inside a submenu lands on its parent row and does not open it",
            "the bandage's guessed row a submenu " .. tostring(T.sub) .. ", a submenu open " .. tostring(T.subOpen))
    end)
    Q.step(2, function()
        S.needsBack()
        S.gBack()
        if not S.dead then S.caseClean() end
    end)
    S.caseEnd("L needs")
end
function S.needsBack()
    S.scratch(false)
    S.statsBack(S.found.stats)
    if S.found.foodTimer then pcall(function() S.p:getBodyDamage():setHealthFromFoodTimer(S.found.foodTimer) end) end
    if S.back.god then S.back.god = nil; pcall(function() S.p:setGodMod(S.found.god and true or false) end); S.guard() end
    S.setOpt(ZeD.Settings.menuGuessOption, S.found.guess)
end

-- ===================================================================== D. the setting in ZeD setup (never applied)
function S.menuUp()
    local up = false
    pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end)
    return up
end
function S.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
function S.setupRow(w, id)
    local o = S.zopt(id)
    local el = o and o.element
    if not el then return nil end
    local rows = {}
    pcall(function() rows = w:zedSetupRows() end)
    for _, r in ipairs(rows) do if r.control == el then return r end end
    for _, r in ipairs(rows) do
        for _, z in ipairs(r.zedIds or (r.control and r.control.zedIds) or {}) do if z == id then return r end end
    end
    return nil
end
function S.nudgeTo(w, r, want)
    local c = r and r.control
    if not c then return false end
    for _ = 1, 16 do
        local cur = c.selected or 1
        if cur == want then return true end
        pcall(function() w:nudge(r, (want > cur) and 1 or -1) end)
        if c.selected == cur then return false end
    end
    return c.selected == want
end
function S.liveOff()
    local bad = {}
    local zo = nil
    pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end)
    for _, o in ipairs((zo and zo.data) or {}) do
        if o.type == "combobox" and o.element and o.element.selected ~= o.selected then bad[#bad + 1] = tostring(o.id) end
    end
    return bad
end
function S.caseD()
    local T = {}
    local MM = ZeD.MainMenu
    S.step(5, function()
        if not (MM and MM.openOptions and ZeD.Settings.ADDITION_PRESETS) then T.off = true; Q.skip("D setting", "ZeD's Options window or the presets are not loaded"); return end
        T.menuWas = S.menuUp()
        T.stored = { smart = S.optVal(ZeD.Settings.smartAttachOption), preset = S.optVal(S.zopt("additionsPreset")) }
        if not T.menuWas then S.toggleMenu() end
        S.back.menu = T
    end)
    S.wait(10, 400, function() return T.off or (S.menuUp() and MM.pauseOpts ~= nil) end, function(ok)
        if T.off then return end
        if ok then pcall(MM.openOptions) end
    end)
    S.wait(5, 300, function() return T.off or (MM.pauseOpts ~= nil and MM.pauseOpts:isVisible()) end, function(ok)
        if T.off then return end
        if not Q.check(ok, "D setting: Options opens from the pause menu") then T.off = true; T.shut = true; return end
        local w = MM.pauseOpts
        T.page = w.pageIdx
        for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
        w.scroll = 0
    end)
    S.step(3, function()
        if T.off then return end
        local w = MM.pauseOpts
        local rP, rS = S.setupRow(w, "additionsPreset"), S.setupRow(w, "smartAttach")
        if not (rP and rS) then
            T.shut = true
            local lite = false
            pcall(function() lite = ZeD.Settings.lite() end)
            if lite then Q.skip("D setting: the presets set Attach looted tools and weapons", "Style is Lite, and Lite leaves the Additions group out of ZeD setup")
            else Q.check(false, "D setting: ZeD setup has the Preset and Attach looted tools and weapons rows") end
            return
        end
        local got = {}
        for _, i in ipairs({ 3, 1, 2 }) do
            S.nudgeTo(w, rP, i)
            got[i] = rS.control.selected
        end
        local P = ZeD.Settings.ADDITION_PRESETS
        Q.check(got[3] == 2 and got[1] == 1 and got[2] == 1 and P[3].smartAttach == 2 and P[1].smartAttach == 1 and P[2].smartAttach == 1,
            "D setting: picking the Access preset sets Attach looted tools and weapons On, Vanilla and Plus set it Off",
            "Access " .. tostring(got[3]) .. ", Vanilla " .. tostring(got[1]) .. ", Plus " .. tostring(got[2]) .. " (1 Off, 2 On)")
        S.nudgeTo(w, rS, (rS.control.selected == 2) and 1 or 2)
        pcall(ZeD.Settings.syncAdditionsPreset)
        Q.check(rP.control.selected == 4, "D setting: switching Attach looted tools and weapons by hand makes the preset read Custom",
            "preset " .. tostring(rP.control.selected))
        pcall(function() w:discardStay() end)
    end)
    S.step(3, function()
        local w = MM and MM.pauseOpts
        if not T.off and not T.shut and w then
            local bad = S.liveOff()
            Q.check(#bad == 0 and not w:anyChanged() and S.optVal(ZeD.Settings.smartAttachOption) == T.stored.smart and S.optVal(S.zopt("additionsPreset")) == T.stored.preset,
                "D setting: Discard puts the preset and every addition back, nothing applied", S.idsText(bad))
        end
        S.menuBack()
    end)
    S.wait(10, 600, function() return T.off or T.menuWas or not S.menuUp() end, function(ok)
        if T.off then return end
        Q.check(ok, "D setting: the pause menu shuts again")
    end)
    S.caseEnd("D setting")
end
function S.menuBack()
    local T = S.back.menu
    if not T then return end
    S.back.menu = nil
    local MM = ZeD.MainMenu
    local w = MM and MM.pauseOpts
    if w then
        pcall(function() if w:anyChanged() then w:discardStay() end end)
        if T.page then w.pageIdx = T.page end
        pcall(function() if w:isVisible() then w:back() end end)
    end
    if not T.menuWas and S.menuUp() then S.toggleMenu() end
end

-- ===================================================================== K. the belt's blocks in three themes (pictures)
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
function S.beltKinds()
    local hud = nil
    pcall(function() hud = ZeD.Belt.getHUD(S.pn) end)
    local t = {}
    for _, b in ipairs((hud and hud._boxes) or {}) do t[#t + 1] = tostring(b.kind) end
    return t
end
function S.caseK()
    local T = {}
    S.step(2, function()
        S.caseMade = {}
        if not (ZeD.Settings.ammoBoxOption and ZeD.Messages and ZeD.ErrorBox and ZeD.Settings.baseKeys) then T.off = true; Q.skip("K belt pictures", "the ammo setting, Messages or the notice is not loaded"); return end
        S.setOpt(ZeD.Settings.ammoBoxOption, 2)
        S.back.ammo = true
        T.gun = S.give(S.firstKnown({ "Base.Pistol", "Base.Pistol2", "Base.Revolver" }) or "Base.Pistol")
        pcall(function() T.gun:setCurrentAmmoCount(8); T.gun:setRoundChambered(true) end)
        pcall(function() S.p:setPrimaryHandItem(T.gun) end)
        pcall(function() ZeD.Messages.add("ZeDQA lv_calls", "mods", { head = "QA", text = "a note for the belt row's Messages notice" }) end)
        S.back.msg = true
        T.pairWas = RT.isOpen()
        RT.pairShut()
    end)
    S.wait(4, 300, function()
        if T.off then return true end
        local el = ZeD.ErrorBox._note
        local vis = false
        if el then pcall(function() vis = el:getIsVisible() end) end
        return vis and S.inList(S.beltKinds(), "ammo") and not RT.isOpen()
    end, function(ok)
        if T.off then return end
        T.ready = ok
        if not ok then Q.say("NOTE K belt: the ammo tab or the notice is not up: the row holds " .. S.idsText(S.beltKinds())) end
    end)
    for _, th in ipairs(S.THEMES) do
        S.step(2, function() if not T.off then S.theme(th.key) end end)
        Q.waitMs(800)
        S.shot("lv_calls_belt_" .. th.key .. "_" .. S.sizeTag(), "the " .. th.word .. " theme; a pistol in the hand (the ammo tab) and the Messages notice on the belt row: they should read as the slots do (light paper, a thin dark edge, a dark shadow one unit right and down)")
    end
    S.step(2, function()
        S.themeBack()
        if T.off then return end
        Q.check(T.ready and #S.shots >= 3, "K belt: pictures of the belt row with the ammo tab and the Messages notice were taken in Dark, Light and High contrast (a person judges them)",
            S.idsText(S.shots) .. "; the row: " .. S.idsText(S.beltKinds()))
        S.kBack()
        if T.pairWas then RT.pairOpen() end
        S.caseClean()
    end)
    S.wait(4, 300, function() return ZeD.currentBase == S.found.base end, function(ok)
        Q.check(ok and S.optVal(ZeD.Settings.ammoBoxOption) == S.found.ammo, "K belt: the theme and Ammo on the belt are back as found",
            tostring(ZeD.currentBase) .. ", ammo " .. tostring(S.optVal(ZeD.Settings.ammoBoxOption)))
    end)
    S.caseEnd("K belt")
end
function S.kBack()
    if S.back.msg then S.back.msg = nil; pcall(function() ZeD.Messages.clear("ZeDQA lv_calls") end) end
    if S.back.ammo then S.back.ammo = nil; S.setOpt(ZeD.Settings.ammoBoxOption, S.found.ammo) end
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    S.park(false)
    S.qOff()
    S.emptyBack()
    S.padOff()
    S.cancelDrags()
    S.closeMenu()
    S.menuBack()
    S.themeBack()
    S.sizeBack()
    S.kBack()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    if S.back.lent then S.giveBack(S.back.lent) end
    if f.recorded then
        S.needsBack()
        S.setOpt(ZeD.Settings.lookStyleOption, f.style)
        S.setOpt(ZeD.Settings.smartAttachOption, f.smart)
        S.setOpt(ZeD.Settings.menuGuessOption, f.guess)
        S.gBack()
    end
    if S.bag then S.restoreBag() end
    for _, it in ipairs(S.made) do S.removeItem(it) end
    for _, c in ipairs(S.crates) do S.rmCrate(c) end
    S.handsBack()
    S.wornBack()
    local st = S.p:getModData().ZeD_GridViews
    if st then for key, v in pairs(S.grid) do if v == "NIL" then st[key] = nil else st[key] = v end end end
    S.dirty()
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        S.putBack()
        if not (RT.isOpen() and S.worldOpen()) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
    end)
    Q.step(4, function()
        local f = S.found
        if f.pos then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
        if f.dir then pcall(function() S.p:setDir(f.dir) end) end
    end)
    Q.step(20, function()
        local f = S.found
        RT.charTab("loot")
        if not RT.worldTab("loot") then pcall(ZeD_WorldWindow.openTab, S.pn, "loot") end
        if S.bag and not S.charShows(S.bag) then S.showBag(S.bag) end
        if f.worldInv then pcall(ZeD_WorldWindow.selectContainer, f.worldInv, 60, S.pn) end
        for _, inv in ipairs(f.charCols or {}) do pcall(ZeD_CharacterWindow.toggleColumn, inv, S.pn) end
        for _, inv in ipairs(f.worldCols or {}) do pcall(ZeD_WorldWindow.toggleColumn, inv, S.pn) end
        if f.charTab and f.charTab ~= "loot" then RT.charTab(f.charTab) end
        if f.worldTab and f.worldTab ~= "loot" then RT.worldTab(f.worldTab) end
        S.instant(f.inst)
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        if S.bagOrig then
            local back = 0
            for _, it in ipairs(S.bagOrig) do if S.where(it) == S.bag then back = back + 1 end end
            Q.check(back == #S.bagOrig, "put back: the bag holds all its own things again", back .. " of " .. #S.bagOrig)
        end
        local left, names = 0, {}
        for _, it in ipairs(S.made) do
            if S.where(it) ~= nil or S.onFloor(it) then
                left = left + 1
                if #names < 4 then names[#names + 1] = S.ft(it) end
            end
        end
        Q.check(left == 0, "put back: every thing the test made is gone (containers, floor, hands, belt)", left .. " of " .. #S.made .. " left " .. S.idsText(names))
        local crates = 0
        for _, c in ipairs(S.crates) do if c.obj ~= nil then crates = crates + 1 end end
        Q.check(crates == 0, "put back: the crates are gone", crates .. " left")
        local hp, hs = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
        Q.check(f.hands == nil or (hp == f.hands.p and hs == f.hands.s), "put back: the hands hold what they held")
        local worn, on = 0, S.wornSet()
        for _, e in ipairs(f.worn or {}) do if on[e.item] then worn = worn + 1 end end
        Q.check(worn == #(f.worn or {}), "put back: he wears what he wore", worn .. " of " .. #(f.worn or {}))
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6, "put back: he stands where he stood", string.format("%.1f,%.1f off", dx, dy))
        Q.check(S.optVal(ZeD.Settings.lookStyleOption) == f.style and S.optVal(ZeD.Settings.smartAttachOption) == f.smart
            and S.optVal(ZeD.Settings.menuGuessOption) == f.guess and S.optVal(ZeD.Settings.ammoBoxOption) == f.ammo
            and ZeD.currentBase == f.base and ZeD.currentSize == f.size,
            "put back: Style, smart attach, menu guess, Ammo on the belt, the theme and the text size as found",
            tostring(S.optVal(ZeD.Settings.lookStyleOption)) .. ", " .. tostring(S.optVal(ZeD.Settings.smartAttachOption)) .. ", "
            .. tostring(S.optVal(ZeD.Settings.menuGuessOption)) .. ", " .. tostring(S.optVal(ZeD.Settings.ammoBoxOption)) .. ", "
            .. tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize))
        local god = nil
        pcall(function() god = S.p:isGodMod() end)
        Q.check(S.lockFound() == (S.lockWas or S.lockFound()) and god == true, "put back: the input lock as found, the character guarded",
            "lock " .. S.lockFound() .. " (found " .. tostring(S.lockWas) .. "), god mode " .. tostring(god))
        Q.check(S.qOrig == nil and S.emptyWas == nil and S.parked == nil and S.back.lent == nil and S.back.menu == nil,
            "put back: the queue, the empty line, the pointer, the belt slots and the pause menu are the game's own again")
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught")
        local e1 = S.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the calls run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the calls run's Lua error count", "the game's Lua error count cannot be read here") end
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and f.world == false then
            if RT.isOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
        elseif f.pair == false and RT.isOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn)
        elseif f.world == false and S.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
    end)
end

-- ===================================================================== the run
function S.build()
    S.setup()
    S.caseA()
    S.caseE()
    S.caseB()
    S.caseC()
    S.caseF()
    S.caseG()
    S.caseJ()
    S.caseH()
    S.caseI()
    S.caseP()
    S.caseO()
    S.caseN()
    S.caseM()
    S.caseL()
    S.caseD()
    S.caseK()
end
S.build()
S.buildPutBack()
Q.start()
