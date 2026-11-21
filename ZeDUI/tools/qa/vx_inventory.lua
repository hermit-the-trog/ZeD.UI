-- ZeDUI/tools/qa/vx_inventory.lua  (Nov 21 2026, QA beast day): the in-game proof of Build's fixes for the code
-- sweep's findings W1 W2 W3 W4 W5 (ZeDUI/qa/audits/2026-11-21_beast_code_sweep.md; Build's commits 9293090b3 and
-- cddc29bbe). Each check is the thing the player meets, and each says what the old code showed.
--   W3  Equip tab, List view: a tank top under a T-shirt and a nose stud are put on. Every worn thing has a row of
--       its own. (Old: one row per slot, so the tank top or the T-shirt had none, and the nose had no row at all.)
--   W1  Character window, the inventory and a bag side by side: a row dragged from the inventory and let go BELOW
--       the window at the bag column's X is not put in the bag (it goes to the ground when the spot is over the
--       world). (Old: it went into the bag.) The same in the World window: a thing dragged from the Floor column and
--       let go below the window at a bag's column stays on the floor. (Old: it went into that bag.)
--   W2  The card's Repair all on a T-shirt with three holes, a needle, a thread and three ripped sheets carried:
--       no hole left. (Old: one hole patched, two left.) Then a shirt with two holes and the sewing things in a
--       bag held in the hand: no hole left. (Old: nothing happened.)
--   W4  Reading a book with its card open: the band's Cancel (A on it) stops the reading. (Old: the character read
--       on.) A cooking band (staged through ZeD's action manager, no stove) has no Cancel, and its cancel path
--       leaves the queue alone. (Old: an X that wiped the queued actions.)
--   W5  Seated in a car with a thing and a bag on the ground at the seat: the World window lists only the car's
--       own containers, the Floor is empty, the bag on the ground is out of reach. (Old: the ground things and the
--       bag were listed and could be taken.) With the seat's window shut a drag to the ground drops nothing; with
--       it open the same drag does. (Old: it dropped with the window shut.)
-- None of the five fixes is about speed, so nothing is counted over frames here.
-- Faked: the pointer's place for a release (getMouseX / getMouseY and the lists' own readings, for that call only),
-- and the game's addXp for the sewing (the Tailoring points are held back, so the character's skill is as found).
-- The character's own sewing things are set aside for the run and put back. Everything made is taken away.
-- Copy to Zomboid/Lua/ after zedqa_prelude.lua and rt_kit.lua; grep "ZEDQA vx_inv".
-- (Nov 21 2026, the skeptic's read before the first run, every check walked through the old and the new code:
--  * a thing taken off the ground kept its link to the ground object (the game clears it itself: ISGrabItemAction
--    calls setWorldItem(nil)); "on the ground" read that stale link, so the window-shut W5 line and the put-back's
--    "every thing made is gone" would have failed on the fixed code. The link is cleared now, and "on the ground"
--    asks the square whether the object is still on it.
--  * every wait is by the clock now (its frame count read at 60 frames a second): at 144 frames a second a "nothing
--    moved in 90 frames" check lasted 0.6 s.
--  * Base.CanOpener is not in B42 (Base.TinOpener is); things the game hides (make-up, wound and bandage pictures)
--    are not counted as worn things missing a row; the three clothes made for W3 all go, worn or not;
--    add-on containers in the seated World window are named, not counted as "from outside the car"; the window
--    bounds checks are out (they are not about these fixes); a car that is ready only after the wait gave up is
--    taken away, never sat in.
--  * W1: when no spot at the bag column's X is over the world, the release lands over a window, where that
--    window's own rules decide (a title bar takes it): "not in the bag" is still checked, "on the ground" is a SKIP.
--    The World window's line is split the same way.
--  * W4: Cancel must stop the read within one second (a no-page book reads for about 20 s at normal speed on a
--    one-hour day), so on the old code a read that ran on cannot end by itself inside the wait and pass.
--  * W5: the seated list is read once the window has built it after the stage (its _containerAtMs stamp).)

if not (RT and RT.make) then
    print("ZEDQA vx_inv ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx_inv VERDICT FAIL 1")
    print("ZEDQA vx_inv DONE")
    return
end

local Q = RT.make("vx_inv")
Q.maxMs = 300000   -- (the budget is 6 minutes: past 5 the run jumps to the put-back)
local S = { p = RT.p, pn = RT.pn, made = {}, stash = {}, stacks = {}, errs = 0, dead = false }
local H = {}
S.F = RT.focus()
S.SEW = { RippedSheets = true, DenimStrips = true, LeatherStrips = true, Thread = true, Needle = true }

local function step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
-- after n frames, until cond() holds, for at most max frames' worth of time at 60 frames a second (a frame count
-- alone is shorter at a higher frame rate); then fn(ok), ok true when cond held
local function waitFor(n, max, cond, fn)
    local st = {}
    local ms = math.floor(max * 1000 / 60)
    Q.waitFor(n, max * 6 + 900, function()
        if S.dead then return true end
        st.t = st.t or getTimestampMs()
        local okC, r = pcall(cond)
        if okC and r then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function()
        if S.dead then return end
        fn(st.ok == true)
    end)
end

-- ===================================================================== small helpers
function H.cc() local w = RT.cw(); return w and w._mainContent end
function H.wc() local w = RT.ww(); return w and w._mainContent end
function H.inv() return S.p:getInventory() end
function H.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function H.list(inv)
    local out = {}
    pcall(function()
        local it = inv:getItems()
        for i = 0, it:size() - 1 do out[#out + 1] = it:get(i) end
    end)
    return out
end
function H.size(inv) local n = -1; pcall(function() n = inv:getItems():size() end); return n end
function H.where(it) local c = nil; pcall(function() c = it:getContainer() end); return c end
function H.typeOf(inv) local t = "nothing"; pcall(function() t = tostring(inv:getType()) end); return t end
function H.nm(it)
    if it == nil then return "nil" end
    local n = nil
    pcall(function() n = it:getDisplayName() end)
    return tostring(n or it)
end
-- on the ground: its ground object is still on a square (a link alone can be stale)
function H.onFloor(it)
    local on = false
    pcall(function()
        local wo = it:getWorldItem()
        local sq = wo and wo:getSquare()
        on = sq ~= nil and sq:getWorldObjects():contains(wo)
    end)
    return on and true or false
end
function H.queue()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return (q and q.queue) or {}
end
function H.queueLen() return #H.queue() end
function H.queueTypes()
    local t = {}
    for _, a in ipairs(H.queue()) do t[#t + 1] = tostring(a.Type) end
    return (#t > 0) and table.concat(t, " ") or "none"
end
function H.stopActions() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.reading() local r = false; pcall(function() r = S.p:isReading() end); return r and true or false end
function H.inCar() local v = nil; pcall(function() v = S.p:getVehicle() end); return v ~= nil end
function H.instant(on) pcall(function() S.p:setTimedActionInstantCheat(on and true or false) end) end
function H.try(what, fn)
    local ok, err = pcall(fn)
    if not ok then S.errs = S.errs + 1; Q.check(false, what .. ": ran without an error", tostring(err)) end
    return ok
end
function H.dirty()
    pcall(function() ZeD.InventoryRenderer.dirtyModels() end)
    pcall(function() ISInventoryPage.dirtyUI() end)
    pcall(function() local w = RT.cw(); if w then w._containersDirty = true end end)
    pcall(function() local w = RT.ww(); if w then w._containersDirty = true end end)
end
function H.wornSet()
    local set = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do set[wi:get(i):getItem()] = true end
    end)
    return set
end
function H.wornBack()
    local on = H.wornSet()
    for _, e in ipairs(S.worn or {}) do
        if not on[e.item] and H.where(e.item) == H.inv() then
            pcall(function() S.p:setWornItem(e.loc, e.item) end)
        end
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
end
function H.handsBack()
    if not S.handWas then return end
    pcall(function() if S.p:getPrimaryHandItem() ~= S.handWas.p then S.p:setPrimaryHandItem(S.handWas.p) end end)
    pcall(function() if S.p:getSecondaryHandItem() ~= S.handWas.s then S.p:setSecondaryHandItem(S.handWas.s) end end)
end
-- a thing off the character and out of the world, wherever it is
function H.removeItem(it)
    if not it then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() S.p:removeWornItem(it) end)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            -- (as the game's own pick-up does, ISGrabItemAction: none of the calls above clears the links)
            pcall(function() wo:setSquare(nil) end)
        end
    end)
    pcall(function() if it:getWorldItem() then it:setWorldItem(nil) end end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function H.track(it)
    if it then
        pcall(function() it:getModData().ZeDQA_spawned = true end)
        S.made[#S.made + 1] = it
    end
    return it
end
function H.add(inv, ft)
    local it = nil
    pcall(function() it = inv:AddItem(ft) end)
    return H.track(it)
end
function H.addFloor(sq, ft, ox, oy)
    local it = nil
    pcall(function() it = sq:AddWorldInventoryItem(ft, ox, oy, 0) end)
    return H.track(it)
end
function H.put(it, inv)
    if not (it and inv) then return end
    if H.where(it) == inv and not H.onFloor(it) then return end
    H.removeItem(it)
    pcall(function() inv:AddItem(it) end)
    H.dirty()
end
-- every thing the character carries, bags and all
function H.walk(inv, fn, depth)
    depth = depth or 0
    if not inv or depth > 4 then return end
    for _, it in ipairs(H.list(inv)) do
        fn(it, inv)
        local sub = nil
        pcall(function() if instanceof(it, "InventoryContainer") then sub = it:getInventory() end end)
        if sub then H.walk(sub, fn, depth + 1) end
    end
end
function H.isSewing(it)
    local t, tag = "", false
    pcall(function() t = it:getType() end)
    if S.SEW[t] then return true end
    pcall(function() tag = it:hasTag(ItemTag.THREAD) end)
    if not tag then pcall(function() tag = it:hasTag(ItemTag.SEWING_NEEDLE) end) end
    return tag and true or false
end
-- the first kind of the list the character does not carry (its row is then its own, never a stack's)
function H.addUnique(kinds, make)
    local have = {}
    H.walk(H.inv(), function(it) pcall(function() have[it:getFullType()] = true end) end)
    for _, ft in ipairs(kinds) do
        if not have[ft] and not S.usedKind[ft] then
            local it = make(ft)
            if it then S.usedKind[ft] = true; return it end
        end
    end
    return nil
end
-- a stack of this kind drawn open in the Character window's list (each thing its own row); put back at the end
function H.expand(ft)
    local c = H.cc()
    if not (c and ft) then return end
    c._expandedStacks = c._expandedStacks or {}
    if S.stacks[ft] == nil then S.stacks[ft] = c._expandedStacks[ft] or false end
    c._expandedStacks[ft] = true
end

-- ===================================================================== windows
function H.pins(win)
    local s = win and win._halves
    if s then return { inv = s.inv.pinned and true or false, drawer = s.drawer.pinned and true or false } end
    local on = win ~= nil and win.pinned == true
    return { inv = on, drawer = on }
end
function H.setPins(win, inv, drawer)
    if not win then return end
    if win._halves and ZeD.Halves and ZeD.Halves.setPin then
        pcall(ZeD.Halves.setPin, win, "inv", inv)
        pcall(ZeD.Halves.setPin, win, "drawer", drawer)
    else
        win.pinned = (inv and drawer) and true or false
    end
end
function H.down(win)
    if not win then return end
    pcall(function() if win.windowShaded then win._autoShaded = false; win:setWindowShaded(false) end end)
    pcall(function()
        local s = win._halves
        if s then s.inv.rolled, s.inv.hand, s.inv.out, s.drawer.rolled = false, false, nil, false end
    end)
    pcall(function() if win._rolled then ZeD.Curtain.finishUnroll(win) end end)
end
function H.openBoth()
    if not (RT.isOpen() and H.worldOpen()) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
end
function H.lootTabs()
    RT.charTab("loot")
    if not RT.worldTab("loot") then pcall(ZeD_WorldWindow.openTab, S.pn, "loot") end
end
function H.closeCols()
    pcall(function() local cw = RT.cw(); if cw and #(cw._mcSelected or {}) > 0 then ZeD_CharacterWindow.closeColumns(cw) end end)
    pcall(function() local ww = RT.ww(); if ww and #(ww._mcSelected or {}) > 0 then ZeD_WorldWindow.closeColumns(ww) end end)
end
function H.listed(win, inv)
    for _, e in ipairs((win and win._containers) or {}) do if e.inventory == inv then return true end end
    return false
end
function H.col(c, inv)
    for _, cs in ipairs((c and c._colStates) or {}) do
        if cs.inventory == inv and (cs.renderW or 0) > 0 then return cs end
    end
    return nil
end
function H.zone(c, id)
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == id then return z end end
    return nil
end
-- (a condition, every frame: the row drawn last frame, else the list one step further down; wraps at the end)
function H.seek(c, item, scroll)
    if not c then return false end
    if H.zone(c, item) then return true end
    local sc = scroll or c._scroll
    if sc and sc.setScrollPos then
        S.seekPos = (S.seekPos or -0.1) + 0.1
        if S.seekPos > 1.001 then S.seekPos = 0 end
        pcall(function() sc:setScrollPos(S.seekPos) end)
    end
    return false
end
function H.click(c, item)
    local z = H.zone(c, item)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c._zedLastClick = nil
    c:onMouseDown(x, y)
    c:onMouseUp(x, y)
    return true
end
function H.card() local w = RT.cw(); return w and w._itemCard end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end

-- ===================================================================== the pointer (the one thing faked)
-- is a spot over a window that takes the mouse? (the same test as the drop's own, InventoryRenderer pointerOverUI)
function H.overUI(x, y)
    local over = true
    pcall(function()
        local hit = false
        local uis = UIManager.getUI()
        for i = 0, uis:size() - 1 do
            local ui = uis:get(i)
            if ui:isPointOver(x, y) then
                local okC, takes = pcall(function() return ui:isConsumeMouseEvents() end)
                if not okC or takes then hit = true end
            end
        end
        over = hit
    end)
    return over
end
-- a spot over the world at screen x, below the list (else above it); nil when every spot there is over a window
function H.freeY(c, x)
    local sh = RT.core:getScreenHeight()
    local top = c:getAbsoluteY()
    local bottom = top + c:getHeight()
    local y = bottom + 40
    while y < sh - 10 do
        if not H.overUI(x, y) then return y end
        y = y + 20
    end
    y = top - 40
    while y > 10 do
        if not H.overUI(x, y) then return y end
        y = y - 20
    end
    return nil
end
-- any spot over the world
function H.freeSpot()
    local sw, sh = RT.core:getScreenWidth(), RT.core:getScreenHeight()
    for yi = 1, 19 do
        for xi = 1, 19 do
            local x, y = math.floor(sw * xi / 20), math.floor(sh * yi / 20)
            if not H.overUI(x, y) then return x, y end
        end
    end
    return nil
end
function H.hud()
    local h = nil
    pcall(function() h = ZeD.Belt.getHUD(S.pn) end)
    return h
end
-- the press on a row and the move past the drag threshold (the list's own handlers); the drag is then in the air
function H.grab(src, item)
    local z = H.zone(src, item)
    if not z then return false, "the row is not on screen" end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    src._zedLastClick = nil   -- (never a double-click: that would be the quick use)
    local okD, errD = pcall(function() src:onMouseDown(x, y) end)
    if not okD then S.errs = S.errs + 1; return false, "the press threw: " .. tostring(errD) end
    local d = src._drag
    if not (d and d:isPending()) then return false, "the press began no drag" end
    d:checkThreshold(d.startX + 40, d.startY + 40)
    if not d:isActive() then pcall(function() d:cancel() end); return false, "the drag did not start" end
    S.grabAt = { x, y }
    return true, "in the air"
end
-- the release with the pointer at screen ax, ay: every list and strip reads that spot, none says "over me"
function H.release(src, ax, ay)
    local saved = {}
    local function set(o, k, v) saved[#saved + 1] = { o, k, rawget(o, k) }; o[k] = v end
    local cw, ww = RT.cw(), RT.ww()
    local panels = {}
    if cw and cw._mainContent then panels[#panels + 1] = cw._mainContent end
    if ww and ww._mainContent then panels[#panels + 1] = ww._mainContent end
    if cw and cw._containerStrip then panels[#panels + 1] = cw._containerStrip end
    if ww and ww._containerStrip then panels[#panels + 1] = ww._containerStrip end
    for _, o in ipairs(panels) do
        local lx, ly = ax - o:getAbsoluteX(), ay - o:getAbsoluteY()
        set(o, "isMouseOver", function() return false end)
        set(o, "getMouseX", function() return lx end)
        set(o, "getMouseY", function() return ly end)
    end
    local hud = H.hud()
    if hud then set(hud, "getMouseX", function() return -1 end) end
    S.fake = { getMouseX, getMouseY }
    getMouseX = function() return ax end
    getMouseY = function() return ay end
    local g = S.grabAt or { 0, 0 }
    local ok, err = pcall(function() src:onMouseUpOutside(g[1], g[2]) end)
    H.fakeOff()
    for i = #saved, 1, -1 do local s = saved[i]; s[1][s[2]] = s[3] end
    if not ok then S.errs = S.errs + 1 end
    return ok, ok and "let go" or ("the release threw: " .. tostring(err))
end
function H.fakeOff()
    if S.fake then getMouseX, getMouseY = S.fake[1], S.fake[2]; S.fake = nil end
end
function H.cancelDrags()
    for _, c in ipairs({ H.cc(), H.wc() }) do
        pcall(function()
            local d = c._drag
            if d and (d:isActive() or d:isPending()) then d:cancel(); c:setCapture(false) end
        end)
    end
    pcall(function() ISMouseDrag.dragging = nil end)
end

-- ===================================================================== the pad (the card's buttons)
function H.padOn()
    if S.padIsOn then return end
    pcall(function() local md = S.p:getModData().ZeD_Gamepad; S.lockWas = md and md.inputModeLock end)
    pcall(function() ZeD.Input.Detector.setLockedMode("gamepad") end)
    local w = RT.cw()
    if w and S.F and S.F.claimFocus then pcall(S.F.claimFocus, w) end
    S.padIsOn = true
end
function H.padOff()
    if not S.padIsOn then return end
    S.padIsOn = nil
    RT.pad("A", nil)
    pcall(function() S.F.releaseFocus(S.pn) end)
    pcall(function()
        local Dt = ZeD.Input.Detector
        Dt.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Dt.setLockedMode(S.lockWas) end
    end)
end
-- the pad's focus on a stop of the card by its id (FocusManager, charItemCard)
function H.focusCardId(id)
    local w = RT.cw()
    if not (w and S.F and S.F.focusWhere) then return false end
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "charItemCard", function(el) return el.id == id end) end)
    return e ~= nil
end
-- queue: A down, up, let go (S.armA false: the focus did not land, so no A is pressed on whatever holds it)
function H.queueA()
    step(1, function()
        if S.armA ~= true then return end
        RT.pad("A", true); RT.padDown(Joypad.AButton, RT.cw())
    end)
    step(4, function() RT.pad("A", false) end)
    step(4, function() RT.pad("A", nil); S.armA = nil end)
end
-- queue: the row of S[key] found and clicked, its card up
function H.queueCard(key, label)
    step(2, function() S.seekPos = nil; S.cardUp = false end)
    waitFor(1, 240, function() return S[key] == nil or H.seek(H.cc(), S[key]) end, function(ok)
        if S[key] == nil then return end
        Q.check(ok, label .. ": its row is in the Character window's list", H.nm(S[key]))
        if ok and not H.cardOn(S[key]) then H.try(label .. ": the click on its row", function() H.click(H.cc(), S[key]) end) end
    end)
    waitFor(2, 120, function() return S[key] == nil or H.cardOn(S[key]) end, function(ok)
        S.cardUp = (S[key] ~= nil and ok) and true or false
        if S[key] ~= nil then Q.check(S.cardUp, label .. ": a click on its row opens its card") end
    end)
end

-- ===================================================================== clothes (W2)
function H.parts(shirt)
    local out = {}
    pcall(function()
        local ps = shirt:getCoveredParts()
        for i = 0, ps:size() - 1 do out[#out + 1] = ps:get(i) end
    end)
    return out
end
function H.holes(shirt)
    local n = 0
    for _, part in ipairs(H.parts(shirt)) do
        pcall(function() if shirt:getVisual():getHole(part) > 0 then n = n + 1 end end)
    end
    return n
end
function H.patches(shirt) local n = -1; pcall(function() n = shirt:getPatchesNumber() end); return n end
function H.holeShirt(n)
    local shirt = H.add(H.inv(), "Base.Tshirt_DefaultTEXTURE")
    if not shirt then return nil end
    local ps = H.parts(shirt)
    for i = 1, math.min(n, #ps) do pcall(function() shirt:getVisual():setHole(ps[i]) end) end
    H.expand("Base.Tshirt_DefaultTEXTURE")
    return shirt
end
-- the Tailoring points a patch gives are held back for the run (the character's skill stays as found)
function H.xpHold(on)
    if on and not S.addXpWas and addXp then
        S.addXpWas = addXp
        S.xpHeld = S.xpHeld or 0
        local real = addXp
        addXp = function(chr, perk, amt)
            if chr == S.p and perk == Perks.Tailoring then S.xpHeld = S.xpHeld + (tonumber(amt) or 0); return end
            return real(chr, perk, amt)
        end
    elseif not on and S.addXpWas then
        addXp = S.addXpWas
        S.addXpWas = nil
    end
end
-- queue: the card of S[key], the pad's focus on Repair all, A; S.pressed says the press went out
function H.queueRepairAll(key, label)
    H.queueCard(key, label)
    waitFor(4, 240, function() return not S.cardUp or H.focusCardId("verb_repair_all") end, function(ok)
        S.armA = (S.cardUp and ok) and true or false
        S.pressed = S.armA
        if S[key] ~= nil and S.cardUp then Q.check(S.armA, label .. ": the card offers Repair all and the pad's focus lands on it") end
    end)
    H.queueA()
end

-- ===================================================================== setup
Q.step(1, function()
    S.pairWas = RT.isOpen()
    S.worldWas = H.worldOpen()
    S.usedKind = {}
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "vx_inv") end
    local deadNow = true
    pcall(function() deadNow = S.p:isDead() end)
    if not Q.check(not deadNow, "the character is alive") then S.dead = true; return end
    -- nothing here should hurt him; god mode and invincible are on all the same
    pcall(function() S.invWas = S.p:isInvincible() end)
    pcall(function() S.p:setGodMod(true) end)
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() if getGameSpeed() ~= 1 then if ZEDQA_SPEED then ZEDQA_SPEED(1) else setGameSpeed(1) end end end)
    H.stopActions()
    H.openBoth()
    pcall(function() S.instWas = S.p:isTimedActionInstantCheat() end)
    S.handWas = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
    -- (the clothes he wears; what the game hides itself, the pictures of a wound or a bandage, comes and goes with
    -- his health and is the game's, not his clothes: not counted, never put on by this script)
    S.worn = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local w = wi:get(i)
            local hid = false
            pcall(function() hid = w:getItem():isHidden() end)
            if not hid then S.worn[#S.worn + 1] = { loc = w:getLocation(), item = w:getItem() } end
        end
    end)
    -- the character's own sewing things are set aside: the repairs then use only what the test gives
    -- (one held in a hand or hung on the belt stays where it is: taking it out of its container under the hand or
    -- the belt would leave them holding nothing real)
    local found, held = {}, 0
    H.walk(H.inv(), function(it, inv)
        if H.isSewing(it) then
            local on = false
            pcall(function() on = S.p:isEquipped(it) or S.p:isAttachedItem(it) end)
            if on then held = held + 1 else found[#found + 1] = { it = it, c = inv } end
        end
    end)
    for _, e in ipairs(found) do
        local ok = pcall(function() e.c:Remove(e.it) end)
        if ok then S.stash[#S.stash + 1] = e end
    end
    Q.say("NOTE " .. #S.stash .. " sewing things of the character's own set aside for the run" .. ((held > 0) and (", " .. held .. " left in a hand or on the belt") or ""))
    H.instant(true)
end)
step(30, function()
    local cw, ww = RT.cw(), RT.ww()
    if not Q.check(cw ~= nil and ww ~= nil, "both windows are open") then S.dead = true; return end
    S.pins = { c = H.pins(cw), w = H.pins(ww) }
    H.setPins(cw, true, true)
    H.setPins(ww, true, true)
    H.down(cw)
    H.down(ww)
    S.charTabWas, S.worldTabWas = cw._activeTab, ww._activeTab
    S.charCols, S.worldCols = {}, {}
    for _, j in ipairs(cw._mcSelected or {}) do local e = cw._containers[j]; if e then S.charCols[#S.charCols + 1] = e.inventory end end
    for _, j in ipairs(ww._mcSelected or {}) do local e = ww._containers[j]; if e then S.worldCols[#S.worldCols + 1] = e.inventory end end
    H.closeCols()
    H.lootTabs()
end)
step(20, function()
    local cc, wc = H.cc(), H.wc()
    if not Q.check(cc ~= nil and cc._inventory == H.inv(), "the Character window lists the character's inventory",
        H.typeOf(cc and cc._inventory)) then S.dead = true; return end
    S.worldInvWas = wc and wc._inventory
    S.scrollWas = cc._scroll and cc._scroll.scrollPos or 0
end)

-- ===================================================================== W3: the Equip tab's list shows every worn thing
-- A tank top, a T-shirt and a nose stud are put on (each only where nothing is worn yet, so none of the
-- character's own clothes comes off for it). Old code: the Inner row kept the first match only, and "nose" was
-- on no row, so two of the three had no row and were in no ZeD list at all.
step(4, function()
    S.w3 = false
    local D = ZeD.EquipDoll
    local cw = RT.cw()
    if not (D and D.view and ZeD.EquipmentTab and cw) then Q.skip("W3 the Equip tab's list", "the Equip tab is not loaded"); return end
    S.eqViewWas = D.view()
    -- (the view is switched in memory only: the option's file is not written)
    if S.eqViewWas ~= "list" then pcall(function() ZeD.Settings.equipViewOption:setValue(1) end) end
    S.eq, S.eqMine, S.eqMade = {}, {}, {}
    for _, e in ipairs({ { "tank", "Base.Vest_DefaultTEXTURE" }, { "tee", "Base.Tshirt_DefaultTEXTURE" }, { "stud", "Base.NoseStud_Silver" } }) do
        local it = H.add(H.inv(), e[2])
        if it then S.eqMade[#S.eqMade + 1] = it end
        local loc = nil
        if it then pcall(function() loc = it:getBodyLocation() end) end
        local there = nil
        if loc then pcall(function() there = S.p:getWornItem(loc) end) end
        if it and loc and not there then
            pcall(function() S.p:setWornItem(loc, it) end)
            S.eqMine[#S.eqMine + 1] = it
        end
        S.eq[e[1]] = { loc = loc }
    end
    for _, k in ipairs({ "tank", "tee", "stud" }) do
        local e = S.eq[k]
        if e.loc then pcall(function() e.item = S.p:getWornItem(e.loc) end) end
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    S.eqListWas, S.eqSelWas = cw._equipListExpanded, cw._equipSelected
    cw._equipListExpanded = true
    cw._equipSelected = nil
    S.w3 = RT.charTab("equip") and true or false
    if not S.w3 then Q.skip("W3 the Equip tab's list", "the Equip tab is not on the strip") end
end)
function H.eqRows()
    local rows, n = {}, 0
    local cw = RT.cw()
    for _, z in ipairs((cw and cw._equipSlotZones) or {}) do
        if z.item then rows[z.item] = tostring(z.type); n = n + 1 end
    end
    return rows, n
end
waitFor(6, 240, function()
    if not S.w3 then return true end
    local cw = RT.cw()
    if not (cw and cw._activeTab == "equip") then return false end
    local rows = H.eqRows()
    for _, k in ipairs({ "tank", "tee", "stud" }) do
        local it = S.eq[k].item
        if it and not rows[it] then return false end
    end
    return true
end, function(ok)
    if not S.w3 then return end
    local cw = RT.cw()
    local rows, n = H.eqRows()
    local tank, tee, stud = S.eq.tank.item, S.eq.tee.item, S.eq.stud.item
    Q.check(cw ~= nil and cw._activeTab == "equip" and ZeD.EquipDoll.view() == "list", "W3: the Equip tab shows its List view",
        "tab " .. tostring(cw and cw._activeTab) .. ", view " .. tostring(ZeD.EquipDoll.view()) .. ", " .. n .. " rows with a thing")
    if tank and tee then
        Q.check(rows[tank] ~= nil and rows[tee] ~= nil and rows[tank] ~= rows[tee],
            "W3: a tank top under a T-shirt: each has a row of its own in the list (old code: one row, the other hidden)",
            "tank top " .. H.nm(tank) .. " row " .. tostring(rows[tank]) .. ", T-shirt " .. H.nm(tee) .. " row " .. tostring(rows[tee]))
    else
        Q.skip("W3 a tank top under a T-shirt", "the game would not wear both here (tank top " .. tostring(tank ~= nil) .. ", T-shirt " .. tostring(tee ~= nil) .. ")")
    end
    if stud then
        Q.check(rows[stud] ~= nil, "W3: a nose stud has a row in the list (old code: the nose was on no row)",
            H.nm(stud) .. " row " .. tostring(rows[stud]))
    else
        Q.skip("W3 a nose stud", "the game would not wear it here")
    end
    -- every worn thing, whatever it is: none without a row. A thing the game itself hides (make-up, the pictures of a
    -- wound or a bandage: hidden = true in its script, never in the game's own lists either) is not counted.
    local worn, missing, hidden = 0, {}, 0
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local w = wi:get(i)
            local it = w:getItem()
            local hid = false
            pcall(function() hid = it:isHidden() end)
            if hid then
                hidden = hidden + 1
            else
                worn = worn + 1
                if not rows[it] then missing[#missing + 1] = H.nm(it) .. " (" .. tostring(w:getLocation()) .. ")" end
            end
        end
    end)
    Q.check(worn > 0 and #missing == 0, "W3: every worn thing has a row in the Equip list (old code: fewer rows than things worn)",
        worn .. " worn, " .. (worn - #missing) .. " with a row" .. ((#missing > 0) and (", none for: " .. table.concat(missing, "; ")) or "")
        .. ((hidden > 0) and (" (" .. hidden .. " more the game hides itself, not counted)") or ""))
end)
function H.w3Back()
    -- the three clothes made here, worn or not (one not worn because the character wore his own there is still made)
    for _, it in ipairs(S.eqMade or {}) do H.removeItem(it) end
    for _, it in ipairs(S.eqMine or {}) do H.removeItem(it) end
    S.eqMade, S.eqMine = {}, {}
    H.wornBack()
    if S.eqViewWas and S.eqViewWas ~= "list" then pcall(function() ZeD.Settings.equipViewOption:setValue(2) end) end
    S.eqViewWas = nil
    local cw = RT.cw()
    if cw and S.eqListWas ~= nil then cw._equipListExpanded = S.eqListWas; S.eqListWas = nil end
    if cw and S.eqSelWas ~= nil then cw._equipSelected = S.eqSelWas; S.eqSelWas = nil end
end
step(4, function()
    H.w3Back()
    RT.charTab("loot")
    H.dirty()
end)

-- ===================================================================== W1: a drag let go outside the list
-- The inventory and a bag (held in the hand) side by side. A row of the inventory is dragged and let go below the
-- window, at the bag column's X. Old code: the column test read X only, so the thing went into the bag.
step(10, function()
    S.w1 = false
    S.bagItem = H.add(H.inv(), "Base.Bag_Schoolbag")
    pcall(function() S.bagInv = S.bagItem:getInventory() end)
    if not S.bagInv then Q.skip("W1 a drag let go below the window", "no bag could be made"); return end
    pcall(function() S.p:setSecondaryHandItem(S.bagItem) end)
    S.thing = H.addUnique({ "Base.Spoon", "Base.Fork", "Base.ButterKnife", "Base.Ladle", "Base.Spatula", "Base.TinOpener" },
        function(ft) return H.add(H.inv(), ft) end)
    H.dirty()
    S.w1 = S.thing ~= nil
    if not S.w1 then Q.skip("W1 a drag let go below the window", "no thing of a kind the character does not carry could be made") end
end)
waitFor(2, 300, function() return not S.w1 or H.listed(RT.cw(), S.bagInv) end, function(ok)
    if not S.w1 then return end
    if not ok then S.w1 = false; Q.skip("W1 a drag let go below the window", "the bag held in the hand is not on the Character window's buttons"); return end
    H.try("W1: the bag's column opens", function() ZeD_CharacterWindow.toggleColumn(S.bagInv, S.pn) end)
end)
waitFor(4, 120, function() return not S.w1 or (H.col(H.cc(), S.bagInv) ~= nil and H.col(H.cc(), H.inv()) ~= nil) end, function(ok)
    if not S.w1 then return end
    if not ok then
        S.w1 = false
        Q.skip("W1 a drag let go below the window", "the inventory and the bag do not show side by side here (" .. #((H.cc() and H.cc()._colStates) or {}) .. " columns)")
        return
    end
    S.seekPos = nil
end)
waitFor(1, 240, function()
    if not S.w1 then return true end
    local cs = H.col(H.cc(), H.inv())
    return H.seek(H.cc(), S.thing, cs and cs.scroll)
end, function(ok)
    if not S.w1 then return end
    local cc = H.cc()
    local bagCs = H.col(cc, S.bagInv)
    if not (ok and bagCs) then S.w1 = false; Q.skip("W1 a drag let go below the window", "the thing's row is not in the inventory's column"); return end
    local okG, whyG = H.grab(cc, S.thing)
    if not okG then S.w1 = false; Q.check(false, "W1: a row of the inventory's column starts a drag", whyG); return end
    local ax = cc:getAbsoluteX() + bagCs.renderX + math.floor(bagCs.renderW / 2)
    local ay = H.freeY(cc, ax)
    S.w1World = ay ~= nil
    if not ay then ay = cc:getAbsoluteY() + cc:getHeight() + 40 end
    S.w1Spot = math.floor(ax) .. "," .. math.floor(ay) .. " (the list is " .. math.floor(cc:getAbsoluteY()) .. " to " .. math.floor(cc:getAbsoluteY() + cc:getHeight())
        .. " tall, the bag's column " .. math.floor(cc:getAbsoluteX() + bagCs.renderX) .. " to " .. math.floor(cc:getAbsoluteX() + bagCs.renderX + bagCs.renderW) .. " wide)"
    local okR, whyR = H.release(cc, ax, ay)
    if not okR then S.w1 = false; Q.check(false, "W1: the release below the window ran without an error", whyR) end
end)
-- (the wait ends early on either outcome: in the bag, the old code's; on the ground, the fix's)
waitFor(2, 240, function()
    if not S.w1 then return true end
    if H.queueLen() > 0 then return false end
    return H.where(S.thing) == S.bagInv or H.onFloor(S.thing) or not S.w1World
end, function(ok)
    if not S.w1 then return end
    local at = H.onFloor(S.thing) and "on the ground" or ("in " .. ((H.where(S.thing) == S.bagInv) and "the bag" or ((H.where(S.thing) == H.inv()) and "the inventory" or H.typeOf(H.where(S.thing)))))
    Q.check(H.where(S.thing) ~= S.bagInv, "W1: a row let go below the window at the bag column's X does not land in the bag (old code: it did)",
        "the " .. H.nm(S.thing) .. " is " .. at .. "; let go at " .. tostring(S.w1Spot))
    if S.w1World then
        Q.check(H.onFloor(S.thing), "W1: let go over the world, it goes to the ground, as a drag out of the window does", at)
    else
        -- (over a window the drop goes by that window's own rules: its list, its buttons, its title bar; the line
        -- above, not in the bag, is the proof either way)
        Q.skip("W1 let go over the world", "at the bag column's X every spot above and below the list is over a window at this layout; it was let go over one (" .. at .. ")")
    end
end)
step(4, function()
    H.cancelDrags()
    H.closeCols()
    if S.thing then H.put(S.thing, H.inv()) end
end)

-- W1, the World window: the Floor and a bag on the ground side by side; a thing dragged from the Floor column and let
-- go below the window at the bag column's X. Old code (tryFloorTransfer read X only): it went into that bag.
step(6, function()
    S.w1b = false
    local sq = nil
    pcall(function() sq = S.p:getCurrentSquare() end)
    pcall(function() S.floorInv = ZeD_WorldWindow.getFloorContainer(S.pn) end)
    if not (sq and S.floorInv) then Q.skip("W1 the World window's Floor column", "no square or no floor list"); return end
    S.gBag = H.addFloor(sq, "Base.Bag_Schoolbag", 0.3, 0.3)
    pcall(function() S.gBagInv = S.gBag:getInventory() end)
    S.gThing = H.addUnique({ "Base.Fork", "Base.ButterKnife", "Base.Ladle", "Base.Spatula", "Base.TinOpener", "Base.Spoon" },
        function(ft) return H.addFloor(sq, ft, 0.6, 0.6) end)
    H.dirty()
    S.w1b = S.gBagInv ~= nil and S.gThing ~= nil
    if not S.w1b then Q.skip("W1 the World window's Floor column", "the bag or the thing could not be put on the ground") end
end)
waitFor(4, 300, function() return not S.w1b or H.listed(RT.ww(), S.gBagInv) end, function(ok)
    if not S.w1b then return end
    if not ok then S.w1b = false; Q.skip("W1 the World window's Floor column", "the bag on the ground is not on the World window's buttons"); return end
    pcall(ZeD_WorldWindow.selectContainer, S.floorInv, 60, S.pn)
end)
waitFor(4, 300, function() local wc = H.wc(); return not S.w1b or (wc ~= nil and wc._inventory == S.floorInv) end, function(ok)
    if not S.w1b then return end
    if not ok then S.w1b = false; Q.skip("W1 the World window's Floor column", "the World window would not show the Floor"); return end
    H.try("W1: the ground bag's column opens", function() ZeD_WorldWindow.toggleColumn(S.gBagInv, S.pn) end)
end)
waitFor(4, 120, function() return not S.w1b or (H.col(H.wc(), S.gBagInv) ~= nil and H.col(H.wc(), S.floorInv) ~= nil) end, function(ok)
    if not S.w1b then return end
    if not ok then
        S.w1b = false
        Q.skip("W1 the World window's Floor column", "the Floor and the bag do not show side by side here (" .. #((H.wc() and H.wc()._colStates) or {}) .. " columns)")
        return
    end
    S.seekPos = nil
end)
waitFor(1, 240, function()
    if not S.w1b then return true end
    local cs = H.col(H.wc(), S.floorInv)
    return H.seek(H.wc(), S.gThing, cs and cs.scroll)
end, function(ok)
    if not S.w1b then return end
    local wc = H.wc()
    local bagCs = H.col(wc, S.gBagInv)
    if not (ok and bagCs) then S.w1b = false; Q.skip("W1 the World window's Floor column", "the thing's row is not in the Floor column"); return end
    local okG, whyG = H.grab(wc, S.gThing)
    if not okG then S.w1b = false; Q.check(false, "W1: a row of the Floor column starts a drag", whyG); return end
    local ax = wc:getAbsoluteX() + bagCs.renderX + math.floor(bagCs.renderW / 2)
    local ay = H.freeY(wc, ax)
    S.w1bWorld = ay ~= nil
    if not ay then ay = wc:getAbsoluteY() + wc:getHeight() + 40 end
    local okR, whyR = H.release(wc, ax, ay)
    if not okR then S.w1b = false; Q.check(false, "W1: the release below the World window ran without an error", whyR) end
end)
-- (with instant actions the old code's transfer into the bag is done within a few frames: the wait ends on it)
waitFor(2, 90, function() return not S.w1b or H.where(S.gThing) == S.gBagInv end, function(inBag)
    if not S.w1b then return end
    local at = (H.where(S.gThing) == S.gBagInv) and "in the bag" or (H.onFloor(S.gThing) and "on the floor" or H.typeOf(H.where(S.gThing)))
    Q.check(H.where(S.gThing) ~= S.gBagInv, "W1: a Floor row let go below the World window at a bag column's X does not go into that bag (old code: it did)",
        "the " .. H.nm(S.gThing) .. " is " .. at .. ", queue " .. H.queueTypes())
    if S.w1bWorld then
        Q.check(H.onFloor(S.gThing) and H.queueLen() == 0, "W1: let go over the world, the Floor row stays on the floor with nothing queued (a floor thing is never dropped)",
            at .. ", queue " .. H.queueTypes())
    else
        Q.skip("W1 a Floor row let go over the world", "at the bag column's X every spot above and below the World window's list is over a window at this layout (" .. at .. ")")
    end
end)
step(4, function()
    H.cancelDrags()
    H.stopActions()
    H.closeCols()
    H.removeItem(S.gThing); H.removeItem(S.gBag)
    S.gThing, S.gBag, S.gBagInv = nil, nil, nil
    H.dirty()
    H.lootTabs()
end)

-- ===================================================================== W2: the card's Repair all
-- Old code: every part's repair was built with the same one fabric, so the second found it gone and the rest of the
-- queue was dropped (one hole patched a press); and with the sewing things in a bag nothing was carried over first,
-- so a press did nothing.
step(10, function()
    S.w2 = false
    if not (ISInventoryPaneContextMenu and ISRepairClothing and S.F and S.F.focusWhere) then Q.skip("W2 Repair all", "the game's repair or the pad's focus is not loaded"); return end
    H.stopActions()
    H.instant(true)
    H.xpHold(true)
    S.shirt1 = H.holeShirt(3)
    S.needle, S.thread = H.add(H.inv(), "Base.Needle"), H.add(H.inv(), "Base.Thread")
    S.sheets1 = {}
    for i = 1, 3 do S.sheets1[i] = H.add(H.inv(), "Base.RippedSheets") end
    H.dirty()
    S.h1 = S.shirt1 and H.holes(S.shirt1) or 0
    S.w2 = S.shirt1 ~= nil and S.needle ~= nil and S.thread ~= nil and #S.sheets1 == 3 and S.h1 >= 2
    if not S.w2 then Q.skip("W2 Repair all", "the shirt with holes or the sewing things could not be made (holes " .. tostring(S.h1) .. ")"); S.shirt1 = nil; return end
    Q.say("NOTE W2 staged: a T-shirt with " .. S.h1 .. " holes, a needle, a thread and 3 ripped sheets in the inventory")
    H.padOn()
end)
H.queueRepairAll("shirt1", "W2 kit carried")
waitFor(2, 600, function() return not (S.w2 and S.pressed) or (H.queueLen() == 0 and H.holes(S.shirt1) == 0) end, function(ok)
    if not (S.w2 and S.pressed) then return end
    local left = 0
    for _, sh in ipairs(S.sheets1) do if H.where(sh) ~= nil then left = left + 1 end end
    Q.check(H.holes(S.shirt1) == 0, "W2: one press of Repair all patches every hole (old code: one hole patched, " .. (S.h1 - 1) .. " left)",
        "holes " .. S.h1 .. " -> " .. H.holes(S.shirt1) .. ", patches " .. H.patches(S.shirt1) .. ", ripped sheets left " .. left .. " of 3, queue " .. H.queueTypes())
    Q.check(left == 3 - S.h1 or (S.h1 > 3 and left == 0), "W2: each patch took a sheet of its own", (3 - left) .. " used for " .. S.h1 .. " holes")
end)
-- the second shirt; the needle, the thread and two sheets inside the bag held in the hand
step(6, function()
    S.w2b = false
    if not S.w2 then return end
    H.stopActions()
    if not (S.bagInv and S.bagItem and S.p:getSecondaryHandItem() == S.bagItem) then Q.skip("W2 the sewing things in a bag", "no bag is held in the hand"); return end
    for _, sh in ipairs(S.sheets1) do H.removeItem(sh) end
    H.removeItem(S.shirt1)
    S.shirt2 = H.holeShirt(2)
    H.put(S.needle, S.bagInv)
    H.put(S.thread, S.bagInv)
    S.sheets2 = {}
    for i = 1, 2 do S.sheets2[i] = H.add(S.bagInv, "Base.RippedSheets") end
    H.dirty()
    S.h2 = S.shirt2 and H.holes(S.shirt2) or 0
    S.w2b = S.shirt2 ~= nil and #S.sheets2 == 2 and S.h2 == 2 and H.where(S.needle) == S.bagInv and H.where(S.thread) == S.bagInv
    if not S.w2b then Q.skip("W2 the sewing things in a bag", "the second shirt or the things in the bag could not be staged"); S.shirt2 = nil; return end
    Q.say("NOTE W2 staged: a T-shirt with 2 holes in the inventory; the needle, the thread and 2 ripped sheets in the bag held in the hand")
end)
H.queueRepairAll("shirt2", "W2 kit in a bag")
waitFor(2, 900, function() return not (S.w2b and S.pressed) or (H.queueLen() == 0 and H.holes(S.shirt2) == 0) end, function(ok)
    if not (S.w2b and S.pressed) then return end
    Q.check(H.holes(S.shirt2) == 0, "W2: with the sewing things in a bag, Repair all brings them over and patches every hole (old code: nothing happened)",
        "holes 2 -> " .. H.holes(S.shirt2) .. ", patches " .. H.patches(S.shirt2) .. ", the needle is in " .. ((H.where(S.needle) == H.inv()) and "the inventory" or "the bag")
        .. ", queue " .. H.queueTypes())
end)
step(4, function()
    H.stopActions()
    H.xpHold(false)
    if S.w2 then Q.say("NOTE W2: " .. tostring(S.xpHeld or 0) .. " Tailoring points of the patches were held back (the character's skill is as found)") end
    for _, sh in ipairs(S.sheets2 or {}) do H.removeItem(sh) end
    H.removeItem(S.shirt1); H.removeItem(S.shirt2)
    H.removeItem(S.needle); H.removeItem(S.thread)
    S.shirt1, S.shirt2 = nil, nil
    H.dirty()
end)

-- ===================================================================== W4: the progress band's Cancel
-- Old code: the reading poll wiped the band's action each tick, so Cancel fell to "clear the queue", which does not
-- stop the action that runs: the character read on, and the band came back.
function H.active(item)
    local a = nil
    pcall(function() a = ZeD.ItemActionManager.getActiveAction(item) end)
    return a
end
step(6, function()
    S.w4 = false
    S.book = nil
    if not (ZeD.ItemActionManager and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.readItem) then Q.skip("W4 the band's Cancel", "the action manager or the game's read is not loaded"); return end
    local dark = true
    pcall(function() dark = S.p:tooDarkToRead() end)
    if dark then Q.skip("W4 the band's Cancel on a book", "it is too dark to read here"); return end
    H.stopActions()
    H.instant(false)   -- (a read at its real length)
    H.padOn()
    S.book = H.add(H.inv(), "Base.Book")
    if S.book then H.expand("Base.Book") end
    H.dirty()
    S.w4 = S.book ~= nil
    if not S.w4 then Q.skip("W4 the band's Cancel on a book", "no book could be made") end
end)
H.queueCard("book", "W4 the book")
step(2, function()
    if not (S.w4 and S.cardUp) then S.w4 = false; return end
    H.try("W4: the game's read starts", function() ISInventoryPaneContextMenu.readItem(S.book, S.pn) end)
end)
waitFor(2, 600, function() return not S.w4 or (H.reading() and H.active(S.book) ~= nil) end, function(ok)
    if not S.w4 then return end
    if not ok then
        S.w4 = false
        Q.skip("W4 the band's Cancel on a book", "the read did not start (reading " .. tostring(H.reading()) .. ", queue " .. H.queueTypes() .. ")")
        H.stopActions()
    end
end)
-- (two seconds of reading: many ticks of both polls over the band)
Q.waitMs(2000)
step(1, function()
    if not S.w4 then return end
    local a = H.active(S.book)
    local head = H.queue()[1]
    Q.check(H.reading() and a ~= nil and a.kind == "reading", "W4: two seconds in, the book's card shows the reading band",
        "reading " .. tostring(H.reading()) .. ", band " .. tostring(a and a.kind))
    Q.check(a ~= nil and a._action ~= nil and a._action == head, "W4: the band holds the read it would stop (old code: wiped each tick, nothing to stop)",
        "the band's action " .. tostring(a and a._action and a._action.Type) .. ", the queue's head " .. tostring(head and head.Type))
    -- Cancel, as the pad presses it: the focus on the band's X, then A
    S.armA = H.focusCardId("cancel_band")
    S.w4Pad = S.armA
end)
H.queueA()
step(1, function()
    if not S.w4 or S.w4Pad then return end
    -- (the pad's focus would not land on the band here: the same cancel is run straight from the card)
    Q.skip("W4 A on the band's Cancel", "the pad's focus did not land on the band's Cancel: the card's cancel is called instead")
    local card = H.card()
    if card then H.try("W4: the card's cancel", function() card:_dispatchProgressCancel() end) end
end)
-- (one second at most: the fixed cancel stops the read on the next tick. A read of a book with no pages lasts
-- 20 times the day length's real minutes in ticks, about 20 s on a one-hour day, so on the old code a read that
-- ran on cannot end by itself inside this second and pass)
waitFor(2, 60, function() return not S.w4 or not H.reading() end, function(ok)
    if not S.w4 then return end
    Q.check(not H.reading() and H.queueLen() == 0, "W4: Cancel on the reading band stops the reading within a second (old code: the character read on)",
        "reading " .. tostring(H.reading()) .. ", queue " .. H.queueTypes() .. ", by " .. (S.w4Pad and "A on the band's Cancel" or "the card's cancel"))
end)
Q.waitMs(500)
step(1, function()
    if not S.w4 then return end
    Q.check(H.active(S.book) == nil and not H.reading(), "W4: the band is gone and stays gone half a second later (old code: back on the next tick)",
        "band " .. tostring(H.active(S.book) and H.active(S.book).kind) .. ", reading " .. tostring(H.reading()))
end)
-- the cooking band: nothing to stop, so no Cancel. The band is staged through ZeD's action manager on a steak's card
-- (no stove), with a read running behind it. Old code: the band drew an X, and its press wiped the queue.
step(4, function()
    S.w4b = false
    if not ZeD.ItemActionManager then return end
    H.stopActions()
    H.padOn()
    S.food = H.addUnique({ "Base.Steak", "Base.Chicken", "Base.PorkChop", "Base.Salmon" }, function(ft) return H.add(H.inv(), ft) end)
    H.dirty()
    S.w4b = S.food ~= nil
    if not S.w4b then Q.skip("W4 the cooking band", "no food of a kind the character does not carry could be made") end
end)
H.queueCard("food", "W4 the food")
step(2, function()
    if not (S.w4b and S.cardUp) then S.w4b = false; return end
    S.cookOn = true
    H.try("W4: a cooking band staged on the food", function()
        ZeD.ItemActionManager.notify(S.food, "start", { kind = "cooking", label = "COOKING", mode = "active", percent = 0.4, timeStr = "5 min", _action = nil })
    end)
    if S.w4 and S.book and H.where(S.book) == H.inv() then pcall(function() ISInventoryPaneContextMenu.readItem(S.book, S.pn) end) end
end)
waitFor(2, 300, function() return not S.w4b or not S.w4 or H.reading() end, function(ok) end)
step(20, function()
    if not S.w4b then return end
    local card = H.card()
    local a = H.active(S.food)
    local staged = card ~= nil and card.item == S.food and a ~= nil and a.kind == "cooking"
    if not staged then Q.skip("W4 the cooking band", "the staged band did not hold on the food's card"); S.w4b = false; return end
    Q.check(card._cancelRect == nil and not H.focusCardId("cancel_band"), "W4: the cooking band has no Cancel, for the mouse or the pad (old code: an X on it)",
        "the X's rectangle " .. tostring(card._cancelRect ~= nil) .. ", a pad stop on it " .. tostring(H.focusCardId("cancel_band")))
    local n0, read0 = H.queueLen(), H.reading()
    H.try("W4: the card's cancel on a cooking band", function() card:_dispatchProgressCancel() end)
    local a2 = H.active(S.food)
    if n0 > 0 then
        Q.check(H.queueLen() == n0 and a2 ~= nil, "W4: the cooking band's cancel path leaves the queued actions alone (old code: it wiped them)",
            "queue " .. n0 .. " -> " .. H.queueLen() .. " (" .. H.queueTypes() .. "), reading " .. tostring(read0) .. ", the band still up " .. tostring(a2 ~= nil))
    else
        Q.check(a2 ~= nil, "W4: the cooking band's cancel path does nothing (no action could be queued behind it here)", "the band still up " .. tostring(a2 ~= nil))
    end
end)
function H.w4Back()
    H.stopActions()
    if S.cookOn and S.food then pcall(function() ZeD.ItemActionManager.notify(S.food, "complete", nil) end) end
    S.cookOn = nil
    H.padOff()
    H.instant(true)
end
step(4, function() H.w4Back() end)
waitFor(2, 300, function() return not H.reading() end, function(ok)
    H.removeItem(S.food); H.removeItem(S.book)
    S.food, S.book = nil, nil
    H.dirty()
end)

-- ===================================================================== W5: seated in a car
-- Old code: the World window scanned the 3x3 squares round the seat all the same, so things on the ground and bags
-- and furniture beside the car were listed and could be taken from the seat; and a drag to the ground dropped with
-- the window shut.
function H.seatWindow()
    local w = nil
    pcall(function()
        local v = S.p:getVehicle()
        local door = v:getPassengerDoor(v:getSeat(S.p))
        local part = VehicleUtils.getChildWindow(door)
        if part and part:getInventoryItem() then w = part:getWindow() end
    end)
    return w
end
step(6, function()
    S.w5 = false
    S.carDone, S.carWhy = false, nil
    H.padOff()
    H.stopActions()
    H.instant(true)
    H.closeCols()
    if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY) then
        S.carWhy = "the prelude's car helpers are not loaded (zedqa_prelude.lua runs first)"
        return
    end
    S.carGiveUp = nil
    ZEDQA_CAR_WAIT("Base.CarNormal", "vx_inv", function(v)
        -- (a car ready only after this script stopped waiting, or after the put-back began, is taken away unseated:
        -- the character is never left sitting in a car)
        if S.carGiveUp then pcall(ZEDQA_CAR_AWAY, v); return end
        S.v = v
        S.key = ZEDQA_CAR_PREP(v)
        local ok, why = ZEDQA_CAR_ENTER(v, 0)
        if not ok then S.carWhy = why end
        S.carDone = true
    end, function(why) S.carWhy = why or "no ready car" end, 6000)
end)
waitFor(5, 5400, function() return S.carDone or S.carWhy ~= nil end, function(ok)
    if not ok then S.carGiveUp = true; S.carWhy = S.carWhy or "no ready car in 90 seconds" end
    S.w5 = S.v ~= nil and H.inCar()
    if not S.w5 then Q.skip("W5 seated in a car", "no car to sit in: " .. tostring(S.carWhy)); return end
    -- the stage: a thing and a bag on the ground on the seat's own square, a thing in the glove box
    local sq = nil
    pcall(function() sq = S.p:getCurrentSquare() end)
    if not sq then pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())) end) end
    if sq then
        S.cBag = H.addFloor(sq, "Base.Bag_Schoolbag", 0.4, 0.4)
        pcall(function() S.cBagInv = S.cBag:getInventory() end)
        S.cThing = H.addFloor(sq, "Base.Saucepan", 0.6, 0.6)
        pcall(function() S.onSq = sq:getWorldObjects():size() end)
    end
    pcall(function()
        local gb = S.v:getPartById("GloveBox")
        S.gloveInv = gb and gb:getItemContainer()
        if S.gloveInv then S.gloveThing = H.add(S.gloveInv, "Base.Pencil") end
    end)
    if not (S.cBagInv and S.cThing) then S.w5 = false; Q.skip("W5 seated in a car", "nothing could be put on the ground at the seat"); return end
    H.openBoth()
end)
step(20, function()
    if not S.w5 then return end
    H.down(RT.cw()); H.down(RT.ww())
    H.lootTabs()
    H.dirty()
    S.w5At = getTimestampMs()
end)
-- (a list built after the stage: the window stamps each build with its time, _containerAtMs, every half second or
-- sooner when dirty)
waitFor(6, 300, function()
    if not S.w5 then return true end
    local ww = RT.ww()
    return ww ~= nil and ww._containers ~= nil and (ww._containerAtMs or 0) >= (S.w5At or 0)
end, function(ok)
    if not S.w5 then return end
    local ww = RT.ww()
    if not (ok and ww and H.inCar()) then S.w5 = false; Q.skip("W5 seated in a car", "the World window did not build its list again in the seat (its strip not drawn?)"); return end
    -- (an add-on's own containers, sourceType "provided" (ExtraContainers.lua), are named, not counted: they are the
    -- add-on's, not this window's scan)
    local kinds, outside, cars, floorE, provided = {}, 0, 0, nil, {}
    for _, e in ipairs(ww._containers or {}) do
        local st = tostring(e.sourceType)
        kinds[#kinds + 1] = st
        if e.isFloor then floorE = e
        elseif st == "vehicle" or st == "vehicle_container" then cars = cars + 1
        elseif st == "provided" then provided[#provided + 1] = tostring(e.provider)
        else outside = outside + 1 end
    end
    if #provided > 0 then Q.say("NOTE W5: add-on containers listed in the seat, not counted: " .. table.concat(provided, " ")) end
    -- the car's own containers the seat can reach, by the game's own test
    local want = 0
    pcall(function()
        for pi = 0, S.v:getPartCount() - 1 do
            local part = S.v:getPartByIndex(pi)
            if part and part:getItemContainer() and S.v:canAccessContainer(pi, S.p) then want = want + 1 end
        end
    end)
    Q.check(outside == 0 and not H.listed(ww, S.cBagInv),
        "W5: seated, the World window lists nothing from outside the car (old code: the bag on the ground and any furniture beside it)",
        "its buttons: " .. table.concat(kinds, " ") .. "; " .. tostring(S.onSq) .. " things lie on the seat's square")
    Q.check(want > 0 and cars >= want and (S.gloveInv == nil or H.listed(ww, S.gloveInv)), "W5: it lists the car's own containers the seat can reach",
        cars .. " car buttons for " .. want .. " containers in reach, the glove box " .. tostring(S.gloveInv ~= nil and H.listed(ww, S.gloveInv)))
    -- a fresh look by the window's own reach test (it builds the list again), then the Floor as that build left it
    local reach = nil
    H.try("W5: the reach test", function() reach = ZeD_WorldWindow.inReach(S.cBagInv, S.pn) end)
    local onFloor = floorE and H.size(floorE.inventory) or -1
    Q.check(floorE ~= nil and onFloor == 0, "W5: the Floor button stays, empty (old code: it held the things on the ground round the seat)",
        "the Floor holds " .. onFloor .. " with " .. tostring(S.onSq) .. " things on the seat's square")
    Q.check(reach == false, "W5: the bag on the ground at the seat is out of reach from the seat (old code: in reach, and lootable)", "in reach " .. tostring(reach))
end)
-- the drag to the ground from the seat: the window shut, then open
step(4, function()
    S.w5d = false
    if not S.w5 then return end
    local win = H.seatWindow()
    local can = false
    if win then pcall(function() can = win:isOpenable() end) end
    if not can then Q.skip("W5 a drag to the ground with the window shut", "the seat's door has no window that opens"); return end
    pcall(function() S.winWas = win:isOpen(); win:setOpen(false) end)
    if not S.thing then S.thing = H.addUnique({ "Base.Spoon", "Base.Fork", "Base.Ladle" }, function(ft) return H.add(H.inv(), ft) end) end
    if S.thing then H.put(S.thing, H.inv()) end
    S.w5d = S.thing ~= nil
    S.seekPos = nil
end)
function H.seatDrag(label)
    local cc = H.cc()
    local ax, ay = H.freeSpot()
    if not ax then return false, "no spot of the screen is over the world" end
    local okG, whyG = H.grab(cc, S.thing)
    if not okG then return false, whyG end
    local okR, whyR = H.release(cc, ax, ay)
    if not okR then Q.check(false, label .. ": the release ran without an error", whyR); return false, whyR end
    return true, "let go at " .. ax .. "," .. ay
end
waitFor(2, 240, function() return not S.w5d or H.seek(H.cc(), S.thing) end, function(ok)
    if not S.w5d then return end
    local okD, why = false, "its row is not in the Character window's list"
    if ok then okD, why = H.seatDrag("W5 window shut") end
    if not okD then S.w5d = false; Q.skip("W5 a drag to the ground with the window shut", why) end
    S.w5Why = why
end)
-- (the wait ends early when the thing reaches the ground: the old code's outcome)
waitFor(2, 120, function() return not S.w5d or H.onFloor(S.thing) end, function(fell)
    if not S.w5d then return end
    local win = H.seatWindow()
    local open = nil
    if win then pcall(function() open = win:isOpen() end) end
    Q.check(not H.onFloor(S.thing) and H.where(S.thing) == H.inv() and H.queueLen() == 0,
        "W5: seated with the window shut, a row dragged out over the world is not dropped (old code: it went to the ground)",
        "the " .. H.nm(S.thing) .. " is " .. (H.onFloor(S.thing) and "on the ground" or "in the inventory") .. ", the window open " .. tostring(open) .. ", " .. tostring(S.w5Why) .. ", queue " .. H.queueTypes())
    H.stopActions()
    if H.onFloor(S.thing) or H.where(S.thing) ~= H.inv() then H.put(S.thing, H.inv()) end
    if win then pcall(function() win:setOpen(true) end) end
    S.seekPos = nil
end)
waitFor(4, 240, function() return not S.w5d or H.seek(H.cc(), S.thing) end, function(ok)
    if not S.w5d then return end
    local okD, why = false, "its row is not in the Character window's list"
    if ok then okD, why = H.seatDrag("W5 window open") end
    if not okD then S.w5d = false; Q.skip("W5 a drag to the ground with the window open", why) end
end)
waitFor(2, 900, function() return not S.w5d or (H.onFloor(S.thing) and H.queueLen() == 0) end, function(ok)
    if not S.w5d then return end
    Q.check(H.onFloor(S.thing), "W5: with the window open the same drag puts it on the ground, as the game's own list does",
        "the " .. H.nm(S.thing) .. " is " .. (H.onFloor(S.thing) and "on the ground" or "in the inventory") .. ", queue " .. H.queueTypes())
end)
function H.w5Back()
    H.cancelDrags()
    H.stopActions()
    pcall(function() local win = H.seatWindow(); if win and S.winWas ~= nil then win:setOpen(S.winWas) end end)
    S.winWas = nil
    H.removeItem(S.gloveThing); S.gloveThing = nil
    if S.v and ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, S.v, S.key) end
    S.v, S.key = nil, nil
    H.removeItem(S.cThing); H.removeItem(S.cBag)
    S.cThing, S.cBag, S.cBagInv = nil, nil, nil
end
step(4, function()
    H.w5Back()
    Q.check(S.errs == 0, "nothing ZeD ran for this script threw", S.errs .. " caught")
end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    S.carGiveUp = true   -- (a car still being waited for is taken away when it is ready, never sat in)
    pcall(H.fakeOff)
    pcall(H.xpHold, false)
    pcall(H.cancelDrags)
    pcall(function() RT.pad("A", nil) end)
    pcall(H.w4Back)
    pcall(H.w5Back)
    pcall(function() if getGameSpeed() ~= 1 then if ZEDQA_SPEED then ZEDQA_SPEED(1) else setGameSpeed(1) end end end)
end)
Q.waitFor(4, 600, function() return not H.inCar() end, function(ok)
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "vx_inv") end
    pcall(H.openBoth)
end)
Q.step(20, function()
    local cw, ww = RT.cw(), RT.ww()
    pcall(H.down, cw); pcall(H.down, ww)
    pcall(H.closeCols)
    pcall(H.w3Back)
    -- everything the test made, then the hands, the clothes and the character's own sewing things
    for _, it in ipairs(S.made) do pcall(H.removeItem, it) end
    pcall(H.handsBack)
    pcall(H.wornBack)
    local back = 0
    for _, e in ipairs(S.stash) do
        pcall(function() if H.where(e.it) == nil then e.c:AddItem(e.it) end end)
        if H.where(e.it) == e.c then back = back + 1 end
    end
    S.stashBack = back
    pcall(function()
        local c = H.cc()
        if c and c._expandedStacks then
            for ft, was in pairs(S.stacks) do c._expandedStacks[ft] = was or nil end
        end
        if c and c._scroll and S.scrollWas then c._scroll:setScrollPos(S.scrollWas) end
    end)
    pcall(H.dirty)
    pcall(H.lootTabs)
end)
Q.step(20, function()
    if S.worldInvWas then pcall(ZeD_WorldWindow.selectContainer, S.worldInvWas, 60, S.pn) end
    for _, inv in ipairs(S.charCols or {}) do pcall(ZeD_CharacterWindow.toggleColumn, inv, S.pn) end
    for _, inv in ipairs(S.worldCols or {}) do pcall(ZeD_WorldWindow.toggleColumn, inv, S.pn) end
    if S.charTabWas and S.charTabWas ~= "loot" then pcall(RT.charTab, S.charTabWas) end
    if S.worldTabWas and S.worldTabWas ~= "loot" then pcall(RT.worldTab, S.worldTabWas) end
    pcall(function()
        local cw, ww = RT.cw(), RT.ww()
        if cw and S.pins and S.pins.c then H.setPins(cw, S.pins.c.inv, S.pins.c.drawer) end
        if ww and S.pins and S.pins.w then H.setPins(ww, S.pins.w.inv, S.pins.w.drawer) end
    end)
    if S.instWas ~= nil then H.instant(S.instWas) end
    -- the character: whole, alive, as protected as he was found
    pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
    local dead, health = true, -1
    pcall(function() dead = S.p:isDead() end)
    pcall(function() health = S.p:getBodyDamage():getOverallBodyHealth() end)
    Q.check(not dead and health >= 99, "the character is alive and whole", "health " .. tostring(math.floor(health)))
    if S.invWas ~= nil then pcall(function() S.p:setInvincible(S.invWas) end) end
    local left = 0
    for _, it in ipairs(S.made) do if H.where(it) ~= nil or H.onFloor(it) then left = left + 1 end end
    Q.check(left == 0, "every thing the test made is gone", left .. " of " .. #S.made .. " left")
    Q.check((S.stashBack or 0) == #S.stash, "the character's own sewing things are back where they were", tostring(S.stashBack) .. " of " .. #S.stash)
    if S.handWas then
        Q.check(S.p:getPrimaryHandItem() == S.handWas.p and S.p:getSecondaryHandItem() == S.handWas.s, "the hands hold what they held")
    end
    local worn, onNow = 0, H.wornSet()
    for _, e in ipairs(S.worn or {}) do if onNow[e.item] then worn = worn + 1 end end
    local wornNow = 0
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local hid = false
            pcall(function() hid = wi:get(i):getItem():isHidden() end)
            if not hid then wornNow = wornNow + 1 end
        end
    end)
    Q.check(worn == #(S.worn or {}) and wornNow == worn, "the character wears what he wore, nothing more", worn .. " of " .. #(S.worn or {}) .. " back, " .. wornNow .. " worn now")
    Q.check(S.fake == nil and S.addXpWas == nil and not H.inCar() and H.queueLen() == 0 and getGameSpeed() == 1,
        "the pointer's readings, the game's addXp, the seat, the queue and the game speed are as found",
        "in a car " .. tostring(H.inCar()) .. ", queue " .. H.queueTypes() .. ", speed " .. tostring(getGameSpeed()))
end)
Q.step(10, function()
    if S.pairWas == false and S.worldWas == false then
        if RT.isOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn) end
        if H.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
    elseif S.pairWas == false and RT.isOpen() then
        pcall(ZeD_CharacterWindow.toggle, S.pn)
    elseif S.worldWas == false and H.worldOpen() then
        pcall(ZeD_WorldWindow.close, S.pn)
    end
end)
Q.start()
