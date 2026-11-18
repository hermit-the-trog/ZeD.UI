-- ZeDUI/tools/qa/rt_hud.lua  (Nov 18 2026, QA): the release test's HUD row (qa/RELEASE_TEST.md, rt_hud.lua).
-- Built on rt_kit.lua (the global RT). grep "ZEDQA rt_hud". No pictures.
--   belt      ZeD_Belt.lua / Overrides/Belt.lua: drawn at the bottom, the game's hotbar parked off screen, two hand
--             circles (the main hand the bigger); one item in both hands slides the off hand under the main hand
--   watch     WatchMini.lua / ZeD_Watch.lua: a worn watch sits on the belt beside its hand; a press on its face (the
--             belt's own mouse handler) pops the full watch above the belt; a second press tucks it back
--   action    ZeD_ActionBar.lua: a real timed action (the game's own ISInventoryTransferAction, a few things into a
--             bag) is drawn and its bar moves; it ends with Done drawn from it, then clears
--   moodles   ZeD_Moodles.lua: a few moodles on; right, left and bottom each put them where they belong
--   bubble    ZeD_Bubbles.lua: a line the character says shows in ZeD's balloon over the head and fades
--   xp note   ZeD_HaloText.lua: skill XP (Perks.Woodwork: B42 has no Perks.Carpentry) goes through with no error and is
--             logged in Messages; a game note (HaloTextHelper.addGoodText) shows in ZeD's bubble and fades
--   forage    Overrides/ForagePins.lua: a find staged as zedqa_forage_pointer.lua stages it (tile 925,13040, the step
--             back and the facing): ZeD's pin is drawn and the pointer is ZeD's hand, 44 x 77, white; the eye note
--   guide     ZeD_GuideBubble.lua: a fresh machine's guide bubble comes out of the belt with the guide's words and fades
--   hint      ZeD_HintStrip.lua: at a door the strip shows above the belt, centred; paused it hides; First hours stops a
--             hint after its three uses (counted in Zomboid/Lua/ZeD_hints.txt); Off takes it away
-- (Nov 18 2026, QA, the ledger's HUD gaps closed here:)
--   belt menu ZeD_Belt.lua: a right-click on the main hand (the belt's onRightMouseUp) and the pad's X on the hand and
--             on a slot (the belt's own onJoypadDown) open a menu on screen; the pad's menu names the belt its origin
--   simple    the Simple belt: no strap, the slots SIMPLE_GAP apart, on screen; Full has its strap again
--   bar style the action bar Simple (53 x 9 units, above the head) and Detailed (the thought bubble), each on a real
--             transfer; an attach to the hotbar (useProgressBar false in the game) draws no bar
--   balloon   Balloon.lua: one balloon at a time near the screen's corner, on screen; Escape's dismiss keeps it down
--             until the focus moves to another control
--   paused    ZeD_PausedLook.lua: paused, the Character window's glass covers its list and eats presses, the tab strip
--             still switches tabs; playing again the glass is gone
--   pin       ZeD_Pins.lua: a skill row's right-click menu pins the skill; the title bar shows its level and XP
--   popclear  PopClear.lua: a spot over a ZeD window moves clear of it (or stays only when neither side has room)
--   prompts   ZeD_Prompt.lua / Overrides/Prompts.lua: the game's ISTextBox is ZeD's text prompt and OK hands the typed
--             text back; a long rich text stays on screen and scrolls; Escape and Enter answer the prompt on top and
--             the pause menu stays shut
--   mini-map  Overrides/MiniMap.lua: the game's mini-map shown is hidden again within 500 ms; restore shows it
-- Every surface: RT.bounds. Puts back: every option, the stats, hands, worn watch, the watch's saved spot, Messages,
-- the guide's flag file and timings, search mode, the time, the character's spot, the hint uses file, the pins, the
-- hotbar, the game speed, the mini-map. Things given are taken back.
local Q = RT.make("rt_hud")
Q.maxMs = 780000                     -- (the runner gives this script 900 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, back = {} }
local Z = ZeD
S.sw, S.sh = RT.core:getScreenWidth(), RT.core:getScreenHeight()

function S.moveTo(x, y) pcall(function() S.p:setX(x); S.p:setY(y); S.p:setLastX(x); S.p:setLastY(y) end) end
function S.opt(o) local v = nil; pcall(function() v = o:getValue() end); return v end
function S.setOpt(o, v) if o and v then pcall(function() o:setValue(v) end) end end
function S.hud() return Z.Belt and Z.Belt.getHUD and Z.Belt.getHUD(S.pn) or nil end
function S.boxes(kind)
    local out = {}
    local hud = S.hud()
    for _, b in ipairs(hud and hud._boxes or {}) do if b.kind == kind then out[#out + 1] = b end end
    return out
end
function S.handBox(which)
    for _, b in ipairs(S.boxes("hand")) do if b.which == which then return b end end
    return nil
end
function S.onScreen(x, y, w, h) return x >= -1 and y >= -1 and x + w <= S.sw + 1 and y + h <= S.sh + 1 and w > 0 and h > 0 end

-- ===================================================================== start
Q.step(10, function()
    S.home = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.pairWas = RT.isOpen()
    RT.pairShut()
    pcall(function() S.p:StopAllActionQueue() end)
    if getGameSpeed() ~= 1 then if ZEDQA_SPEED then ZEDQA_SPEED(1) else setGameSpeed(1) end end
    S.safeWas = Z.Safe and Z.Safe.on() or false
    Q.check(not S.safeWas, "safe mode is off, so ZeD draws the HUD")
    Q.check(Z.Belt and Z.Watch and Z.WatchMini and Z.ActionBar and Z.Moodles and Z.Bubbles and Z.HaloText and Z.GuideBubble
        and Z.HintStrip and Z.Messages and Z.Settings, "every HUD module is loaded")
end)

-- ===================================================================== belt and hands
Q.step(20, function()
    local hud = S.hud()
    if not Q.check(hud ~= nil and hud._drawn == true and hud:getIsVisible(), "belt: drawn") then return end
    local x, y, w, h = hud:getX(), hud:getY(), hud:getWidth(), hud:getHeight()
    Q.check(S.onScreen(x, y, w, h) and y + h >= S.sh - h * 2, "belt: at the bottom of the screen",
        string.format("%d,%d %dx%d", x, y, w, h))
    local parked = false
    pcall(function() parked = ISHotbar._zedBelt == true and getPlayerHotbar(S.pn):getX() < -1000 end)
    Q.check(parked, "belt: the game's hotbar is parked off screen (Overrides/Belt.lua)")
    local main, off = S.handBox("p"), S.handBox("s")
    Q.check(main ~= nil and off ~= nil and main.w > off.w, "hands: two circles, the main hand the bigger",
        main and off and (main.w .. " and " .. off.w) or "missing")
    Q.check(off and main and off.x < main.x, "hands: the off hand left of the main hand (seen from behind)")
    RT.bounds(Q, "belt")
    S.hands = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() }
    S.back.hands = true
    S.hammer = RT.give("Base.Hammer")
    pcall(function() S.p:setPrimaryHandItem(S.hammer); S.p:setSecondaryHandItem(S.hammer) end)
end)
Q.step(15, function()
    local off = S.handBox("s")
    Q.check(off ~= nil and off.peek == true, "hands: one item in both hands slides the off hand under the main hand")
    pcall(function() S.p:setSecondaryHandItem(nil) end)
end)
Q.step(15, function()
    local off = S.handBox("s")
    Q.check(off ~= nil and not off.peek, "hands: one hand free again, the off hand back beside the main hand")
    S.putHands()
end)
function S.putHands()
    if not S.back.hands then return end
    S.back.hands = nil
    pcall(function() S.p:setPrimaryHandItem(S.hands[1]); S.p:setSecondaryHandItem(S.hands[2]) end)
end

-- ===================================================================== belt: the menus on a hand and a slot
-- (mouse: the belt's own onRightMouseUp on the main hand; pad: the belt's own onJoypadDown X, the pad's place set as
-- B.focus sets it. The pad's way back to the belt when the menu closes needs a joined controller: by hand.)
function S.ctx() local c = nil; pcall(function() c = getPlayerContextMenu(S.pn) end); return c end
function S.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
function S.closeMenu()
    local m = S.menu()
    if m then pcall(function() m:close() end) end
    pcall(function() local c = S.ctx(); if c and c:isAnyVisible() then c:hideAndChildren() end end)
end
function S.menuOk(what)
    local m = S.menu()
    local vis = false
    if m then pcall(function() vis = m:isReallyVisible() end) end
    if not Q.check(m ~= nil and vis, what .. ": a menu opens") then return false end
    local x, y, w, h = m:getX(), m:getY(), m:getWidth(), m:getHeight()
    Q.check(S.onScreen(x, y, w, h), what .. ": the menu is on screen", string.format("%d,%d %dx%d", x, y, w, h))
    RT.bounds(Q, what)
    return true
end
function S.boxIdx(kind, which)
    local hud = S.hud()
    for i, b in ipairs(hud and hud._boxes or {}) do
        if b.kind == kind and (which == nil or b.which == which) then return i, b end
    end
    return nil
end
function S.putRc()
    if not S.back.rc then return end
    S.back.rc = nil
    S.closeMenu()
    local hud = S.hud()
    if hud then hud._gp = nil end
    pcall(function() S.p:setPrimaryHandItem(S.rc.hands[1]); S.p:setSecondaryHandItem(S.rc.hands[2]) end)
end
Q.step(5, function()
    S.rc = { hands = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() } }
    S.back.rc = true
    S.closeMenu()
    pcall(function() S.p:setPrimaryHandItem(S.hammer); S.p:setSecondaryHandItem(nil) end)
end)
Q.step(15, function()
    local hud = S.hud()
    local _, b = S.boxIdx("hand", "p")
    if not Q.check(hud ~= nil and b ~= nil and S.hammer ~= nil and S.p:getPrimaryHandItem() == S.hammer,
        "belt menu: the hammer is in the main hand") then S.rcSkip = true; return end
    local cx, cy = b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)
    pcall(function() Mouse.setXY(hud:getAbsoluteX() + cx, hud:getAbsoluteY() + cy) end)
    pcall(function() hud:onRightMouseDown(cx, cy) end)
    Q.check(hud:onRightMouseUp(cx, cy) == true, "belt menu: the belt takes a right-click on the main hand")
end)
Q.waitFor(2, 120, function() return S.rcSkip or S.menu() ~= nil end, function()
    if S.rcSkip then return end
    if S.menuOk("belt menu, right-click on the main hand") then
        local c = S.ctx()
        Q.check(c ~= nil and (c.numOptions or 0) > 1, "belt menu: it holds the hammer's own options", c and c.numOptions)
    end
    S.closeMenu()
    pcall(function() Mouse.setXY(20, 20) end)
end)
Q.step(10, function()
    if S.rcSkip then return end
    local hud = S.hud()
    local i = S.boxIdx("hand", "p")
    if not (hud and i) then return end
    hud._gp = { idx = i, inList = false, row = 1, list = {} }
    hud:onJoypadDown(Joypad.XButton, nil)
end)
Q.waitFor(2, 120, function() return S.rcSkip or S.menu() ~= nil end, function()
    if S.rcSkip then return end
    if S.menuOk("belt menu, the pad's X on the main hand") then
        local c = S.ctx()
        Q.check(c ~= nil and c.origin == S.hud(), "belt menu: the pad's menu names the belt its origin (the way back to it)")
    end
    S.closeMenu()
end)
Q.step(10, function()
    local hud = S.hud()
    local i = hud and hud:_firstSlotIdx()
    local b = i and hud._boxes[i]
    if not (b and b.kind == "slot") then S.noSlot = true; Q.skip("belt menu on a slot", "the belt shows no slot"); return end
    hud._gp = { idx = i, inList = false, row = 1, list = {} }
    hud:onJoypadDown(Joypad.XButton, nil)
end)
Q.waitFor(2, 120, function() return S.noSlot or S.menu() ~= nil end, function()
    if not S.noSlot then S.menuOk("belt menu, the pad's X on a slot") end
    S.putRc()
end)

-- ===================================================================== the Simple belt
Q.step(5, function()
    S.beltStyle = S.opt(Z.Settings.beltStyleOption)
    S.back.beltStyle = true
    S.setOpt(Z.Settings.beltStyleOption, 2)
end)
Q.step(20, function()
    local hud = S.hud()
    if not Q.check(hud ~= nil and hud._drawn == true and Z.Belt.simple(), "simple belt: the Belt option's Simple is read") then return end
    Q.check(hud._strap == nil and hud._buckle == nil, "simple belt: no strap and no buckle")
    local slots = S.boxes("slot")
    if #slots >= 2 then
        local gap = slots[2].x - (slots[1].x + slots[1].w)
        Q.check(gap == ZeD.T.px(6), "simple belt: the slots SIMPLE_GAP apart", gap .. " px, want " .. ZeD.T.px(6))
    else
        Q.skip("simple belt: the gap between slots", #slots .. " slot(s) on this character's belt")
    end
    Q.check(S.onScreen(hud:getX(), hud:getY(), hud:getWidth(), hud:getHeight()), "simple belt: on screen")
    RT.bounds(Q, "simple belt")
    S.setOpt(Z.Settings.beltStyleOption, 1)
end)
Q.step(20, function()
    local hud = S.hud()
    Q.check(hud ~= nil and hud._strap ~= nil, "simple belt: Full brings the strap back")
    S.putBeltStyle()
end)
function S.putBeltStyle()
    if not S.back.beltStyle then return end
    S.back.beltStyle = nil
    S.setOpt(Z.Settings.beltStyleOption, S.beltStyle or 1)
end

-- ===================================================================== watch, mini and full
Q.step(5, function()
    S.watch = { opt = S.opt(Z.Settings.watchPlaceOption), pop = S.p:getModData().ZeD_WatchPop }
    S.back.watch = true
    S.setOpt(Z.Settings.watchPlaceOption, 1)
    S.p:getModData().ZeD_WatchPop = nil
    local worn = Z.Watch._wornWatch and Z.Watch._wornWatch(S.p) or nil
    if worn then
        S.watch.item = worn
        Q.say("watch: the character's own " .. tostring(worn:getDisplayName()))
        return
    end
    local it = RT.give("Base.WristWatch_Left_DigitalBlack")
    if not it then return end
    local loc = it:getBodyLocation()
    pcall(function() S.watch.prev = S.p:getWornItem(loc) end)
    local ok = pcall(function() S.p:setWornItem(loc, it) end)
    if ok then S.watch.item, S.watch.given, S.watch.loc = it, it, loc end
end)
Q.step(30, function()
    local b = S.boxes("watch")[1]
    if not Q.check(b ~= nil, "watch: the worn watch is on the belt", S.watch.item and S.watch.item:getFullType()) then return end
    local main, off = S.handBox("p"), S.handBox("s")
    local beside = (b.wrist == "right" and main and b.x > main.x) or (b.wrist ~= "right" and off and b.x < off.x)
    Q.check(beside, "watch: the mini sits beside its own hand (" .. tostring(b.wrist) .. " wrist)")
    local inst = Z.Watch.getInstance()
    Q.check(inst ~= nil and inst:getWidth() == 0 and not inst._popped, "watch: the full watch is tucked away while the mini shows")
    -- a press on the face, through the belt's own mouse handler
    local cx, cy = math.floor(b.w / 2), math.floor(b.h / 2)
    local id = Z.WatchMini.hit(b.plate, cx, cy)
    Q.check(id == "face", "watch: the middle of the mini is its face", id)
    S.hud():onMouseDown(b.x + cx, b.y + cy)
end)
Q.step(20, function()
    local inst = Z.Watch.getInstance()
    local hud = S.hud()
    Q.check(inst and inst._popped == true and inst:getWidth() > 0 and inst:isVisible(), "watch: the face opens the full watch",
        inst and (inst:getWidth() .. "x" .. inst:getHeight()))
    local bx, by = Z.Belt.watchScreen(S.pn)
    if inst and by then
        Q.check(inst:getY() + inst:getHeight() <= by + 1, "watch: the full watch stands above the mini on the belt",
            math.floor(inst:getY() + inst:getHeight()) .. " over " .. math.floor(by))
    end
    RT.bounds(Q, "full watch")
    local b = S.boxes("watch")[1]
    if b then S.hud():onMouseDown(b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)) end
end)
Q.step(15, function()
    local inst = Z.Watch.getInstance()
    Q.check(inst and not inst._popped and inst:getWidth() == 0, "watch: a second press tucks it back")
    S.putWatch()
end)
function S.putWatch()
    if not S.back.watch then return end
    S.back.watch = nil
    local w = S.watch
    if w.given then
        pcall(function() S.p:removeWornItem(w.given) end)
        if w.prev then pcall(function() S.p:setWornItem(w.loc, w.prev) end) end
    end
    pcall(function() Z.Watch.togglePop(false) end)
    S.p:getModData().ZeD_WatchPop = w.pop
    S.setOpt(Z.Settings.watchPlaceOption, w.opt)
end

-- ===================================================================== action bar
Q.step(5, function()
    local inv = S.p:getInventory()
    S.bag = RT.give("Base.Bag_Schoolbag")
    if not Q.check(S.bag ~= nil, "action bar: a bag to pack") then return end
    local dest = S.bag:getInventory()
    S.packed = {}
    for i = 1, 4 do
        local it = RT.give("Base.Pencil")
        if it then
            S.packed[#S.packed + 1] = it
            ISTimedActionQueue.add(ISInventoryTransferAction:new(S.p, it, inv, dest, 90))
        end
    end
end)
Q.waitFor(1, 180, function() return Z.ActionBar.state(S.p, S.pn) ~= nil end, function(ok)
    local AB = Z.ActionBar
    local st = AB.state(S.p, S.pn)
    if not Q.check(ok and st ~= nil, "action bar: the game's timed action is drawn") then return end
    Q.check(st.phase == "work" and tostring(st.label or "") ~= "", "action bar: it names the action", tostring(st.label) .. " " .. tostring(st.item))
    local L = AB._layers[S.pn]
    Q.check(L ~= nil and L:isVisible(), "action bar: its layer shows")
    S.prog0 = (st.qi + st.frac) / math.max(1, st.qn)
    RT.bounds(Q, "action bar")
end)
Q.waitMs(700)
Q.step(1, function()
    local st = Z.ActionBar.state(S.p, S.pn)
    local now = st and ((st.qi + st.frac) / math.max(1, st.qn)) or 1
    Q.check(now > (S.prog0 or 0), "action bar: the bar follows the action", string.format("%.2f to %.2f", S.prog0 or -1, now))
end)
Q.waitFor(1, 2400, function()
    local e = Z.ActionBar._ends[S.pn]
    if e and e.st and e.st.phase == "done" then S.doneSeen = true end
    return S.doneSeen == true
end, function(ok)
    Q.check(ok, "action bar: the job ends with Done drawn from it")
end)
Q.waitFor(1, 300, function() return Z.ActionBar._ends[S.pn] == nil and Z.ActionBar.state(S.p, S.pn) == nil end, function(ok)
    Q.check(ok, "action bar: the Done fades and the bar clears")
    local inBag = 0
    for _, it in ipairs(S.packed or {}) do if S.bag and it:getContainer() == S.bag:getInventory() then inBag = inBag + 1 end end
    Q.check(inBag == #(S.packed or {}) and inBag > 0, "action bar: the action did its work (" .. inBag .. " in the bag)")
end)

-- ===================================================================== action bar: Simple and Detailed, and no bar
-- (each style on its own real transfer: the pencils out of the bag for Simple, back in for Detailed)
function S.moveAll(fromInv, toInv)
    for _, it in ipairs(S.packed or {}) do
        pcall(function() ISTimedActionQueue.add(ISInventoryTransferAction:new(S.p, it, fromInv, toInv, 90)) end)
    end
end
function S.putAbStyle()
    if not S.back.abStyle then return end
    S.back.abStyle = nil
    S.setOpt(Z.Settings.actionBarOption, S.abStyle or 1)
end
Q.step(5, function()
    S.abStyle = S.opt(Z.Settings.actionBarOption)
    S.back.abStyle = true
    S.setOpt(Z.Settings.actionBarOption, 2)
    if not (S.bag and S.packed and #S.packed > 0) then S.abSkip = true; Q.skip("action bar styles", "no bag packed above"); return end
    S.moveAll(S.bag:getInventory(), S.p:getInventory())
end)
Q.waitFor(1, 180, function()
    local L = Z.ActionBar._layers[S.pn]
    return S.abSkip or (L ~= nil and L._drawSt ~= nil and L._lay ~= nil and L._lay.bar ~= nil)
end, function(ok)
    if S.abSkip then return end
    local AB = Z.ActionBar
    local L = AB._layers[S.pn]
    if not Q.check(ok and AB.mode() == "simple" and L._drawMode == "simple" and L._lay.bar == "simple", "bar style: Simple draws the simple bar",
        tostring(L and L._drawMode)) then return end
    local W, H = AB.sizeSimple()
    local k = L._k or 1
    Q.check(W == 53 and H == 9, "bar style: the simple bar is 53 x 9 units", W .. " x " .. H)
    local x, y, w, h = L._lay.px, L._lay.py, W * k, H * k
    Q.check(S.onScreen(x, y, w, h), "bar style: the simple bar is on screen", string.format("%d,%d %dx%d", x, y, w, h))
    local _, hy = AB.headScreen(S.pn, S.p)
    Q.check(hy ~= nil and y + h <= hy + 1, "bar style: the simple bar stands above the head", tostring(y + h) .. " over " .. tostring(hy))
    RT.bounds(Q, "simple action bar")
end)
Q.waitFor(1, 2400, function() return S.abSkip or Z.ActionBar.state(S.p, S.pn) == nil end, function(ok)
    if S.abSkip then return end
    Q.check(ok, "bar style: the simple job ends")
    S.setOpt(Z.Settings.actionBarOption, 1)
end)
Q.step(30, function()
    if S.abSkip then return end
    S.moveAll(S.p:getInventory(), S.bag:getInventory())
end)
Q.waitFor(1, 180, function()
    local L = Z.ActionBar._layers[S.pn]
    return S.abSkip or (L ~= nil and L._drawSt ~= nil and L._lay ~= nil and L._lay.bar ~= nil)
end, function(ok)
    if S.abSkip then return end
    local AB = Z.ActionBar
    local L = AB._layers[S.pn]
    if not Q.check(ok and AB.mode() == "verbose" and L._drawMode == "verbose" and L._lay.bar == "thought",
        "bar style: Detailed draws the thought bubble", tostring(L and L._drawMode)) then return end
    local vw, vh = AB.sizeVerbose(L._drawSt)
    Q.check(vw >= 60 and vh > 0, "bar style: the detailed bar has its size", vw .. " x " .. vh)
    Q.check(S.onScreen(L:getX(), L:getY(), L:getWidth(), L:getHeight()), "bar style: the detailed bar is on screen",
        string.format("%d,%d %dx%d", L:getX(), L:getY(), L:getWidth(), L:getHeight()))
    RT.bounds(Q, "detailed action bar")
end)
Q.waitFor(1, 2400, function() return S.abSkip or Z.ActionBar.state(S.p, S.pn) == nil end, function(ok)
    if not S.abSkip then Q.check(ok, "bar style: the detailed job ends") end
    S.putAbStyle()
end)
-- an attach to the hotbar: the game's own ISAttachItemHotbar has useProgressBar false, so ZeD draws no bar for it
function S.putAttach()
    local hb = S.att and S.att.hb
    if not hb then return end
    pcall(function() if hb:isItemAttached(S.hammer) then hb:removeItem(S.hammer, false) end end)
    S.att = nil
end
Q.step(30, function()
    local hb = Z.Belt.hotbar and Z.Belt.hotbar(S.pn)
    local it = S.hammer
    local slot, idx = nil, nil
    if hb and it then
        pcall(function()
            if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end
            if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end
        end)
        for i, sl in pairs(hb.availableSlot or {}) do
            if not idx and not (hb.attachedItems and hb.attachedItems[i]) and Z.Belt.fits(hb, i, it) then slot, idx = sl, i end
        end
    end
    if not idx then S.attSkip = true; Q.skip("no bar for an attach to the hotbar", "no free hotbar slot takes a hammer on this character"); return end
    S.att = { hb = hb }
    local name = slot.def and slot.def.attachments and slot.def.attachments[it:getAttachmentType()]
    S.attAct = ISAttachItemHotbar:new(S.p, it, name, idx, slot.def)
    ISTimedActionQueue.add(S.attAct)
end)
Q.waitFor(1, 120, function() return S.attSkip or (S.attAct ~= nil and (S.attAct.action ~= nil or S.attAct._zedBar ~= nil)) end, function(ok)
    if S.attSkip then return end
    local a = S.attAct
    if not Q.check(ok, "no bar: the attach starts") then return end
    Q.check(a.useProgressBar == false and a._zedBar == false, "no bar: the game's own flag is read (useProgressBar false, _zedBar false)")
    Q.check(Z.ActionBar.state(S.p, S.pn) == nil, "no bar: the action bar has no state for it")
end)
Q.waitFor(1, 300, function()
    if S.attSkip then return true end
    local q = ISTimedActionQueue.queues and ISTimedActionQueue.queues[S.p]
    return not (q and q.queue and q.queue[1])
end, function()
    pcall(function() S.p:StopAllActionQueue() end)
    S.putAttach()
end)

-- ===================================================================== moodles in their three places
S.WANT = { HUNGER = 0.45, THIRST = 0.45, FATIGUE = 0.75, BOREDOM = 0.6, STRESS = 0.6 }
function S.setStats()
    local st = S.p:getStats()
    for k, v in pairs(S.WANT) do pcall(function() st:set(CharacterStat[k], v) end) end
end
Q.step(5, function()
    local st = S.p:getStats()
    S.mood = { opt = S.opt(Z.Settings.moodlePlaceOption), god = S.p:isGodMod(), stats = {} }
    for k, _ in pairs(S.WANT) do pcall(function() S.mood.stats[k] = st:get(CharacterStat[k]) end) end
    S.back.mood = true
    S.setStats()
end)
Q.step(90, function()
    if #Z.Moodles.active(S.p) < 3 then pcall(function() S.p:setGodMod(false) end); S.setStats() end
end)
for i, place in ipairs({ "right", "left", "bottom" }) do
    Q.step(5, function() S.setOpt(Z.Settings.moodlePlaceOption, i); S.setStats() end)
    Q.step(40, function()
        S.setStats()
        local r = Z.Moodles.rect(S.pn)
        if not Q.check(r ~= nil and r.place == place, place .. ": the moodles are placed " .. place, r and r.place) then return end
        Q.check((r.n or 0) >= 3, place .. ": at least three moodles are on", r.n)
        Q.check(S.onScreen(r.x, r.y, r.w, r.h), place .. ": every moodle is on screen", string.format("%d,%d %dx%d", r.x, r.y, r.w, r.h))
        local mui = UIManager.getMoodleUI(S.pn)
        local hud = S.hud()
        if place == "right" then
            Q.check(r.x + r.w >= S.sw - 30, "right: the column is at the right edge", r.x)
        elseif place == "left" then
            Q.check(r.x <= 30, "left: the column is at the left edge", r.x)
        else
            Q.check(math.abs(r.x + r.w / 2 - S.sw / 2) <= 2, "bottom: the row is centred")
            if hud and hud._drawn then Q.check(r.y + r.h <= hud:getY(), "bottom: the row sits above the belt") end
            Q.check(mui and mui:getY() < -5000, "bottom: the game's column is out of sight (no double)")
        end
        RT.bounds(Q, "moodles " .. place)
    end)
end
Q.step(5, function() S.putMoodles() end)
function S.putMoodles()
    if not S.back.mood then return end
    S.back.mood = nil
    local st = S.p:getStats()
    for k, v in pairs(S.mood.stats) do pcall(function() st:set(CharacterStat[k], v) end) end
    pcall(function() S.p:setGodMod(S.mood.god) end)
    S.setOpt(Z.Settings.moodlePlaceOption, S.mood.opt or 1)
end

-- ===================================================================== a speech bubble shows and fades
S.LINE = "ZeD QA: testing the bubble"
Q.step(5, function() pcall(function() S.p:Say(S.LINE) end) end)
Q.waitFor(1, 180, function()
    local sp = Z.Bubbles._sp[S.pn]
    return sp ~= nil and tostring(sp.text):find("testing the bubble", 1, true) ~= nil
end, function(ok)
    Q.check(ok, "bubble: a line the character says is in ZeD's balloon")
    local L = Z.ActionBar._layers[S.pn]
    Q.check(L ~= nil and L._drawSp ~= nil, "bubble: the over-head layer draws it")
    RT.bounds(Q, "speech bubble")
end)
Q.waitFor(1, 3000, function() return Z.Bubbles._sp[S.pn] == nil end, function(ok)
    Q.check(ok, "bubble: it fades and goes")
end)

-- ===================================================================== the +XP note and a game note
Q.step(5, function()
    local M = Z.Messages
    S.halo = { opt = S.opt(Z.Settings.haloBubbleOption), name = Z.tr("UI_ZeD_Msg_OverHead") }
    S.halo.src = M.sources[S.halo.name]
    S.back.halo = true
    M.sources[S.halo.name] = nil
    S.setOpt(Z.Settings.haloBubbleOption, 2)
    Q.check(Perks.Woodwork ~= nil, "xp: Perks.Woodwork exists in this build")
    local ok, err = pcall(function() S.p:getXp():AddXP(Perks.Woodwork, 5) end)
    Q.check(ok, "xp: skill XP goes through with ZeD on, no error", err)
end)
Q.step(10, function()
    local s = Z.Messages.sources[S.halo.name]
    local top = s and s.items and s.items[1]
    Q.check(top ~= nil and top.sumKey ~= nil and tostring(top.sumKey):sub(1, 3) == "xp:", "xp: the gain is logged in Messages",
        top and top.text)
    pcall(function() HaloTextHelper.addGoodText(S.p, "ZeD QA note") end)
end)
Q.step(5, function()
    local found = false
    for _, n in ipairs(Z.Bubbles._notes[S.pn] or {}) do if n.text == "ZeD QA note" and n.tone == "good" then found = true end end
    Q.check(found, "xp: a game note goes to ZeD's bubble, marked good")
    local L = Z.ActionBar._layers[S.pn]
    Q.check(L ~= nil and L._drawNotes ~= nil, "xp: the over-head layer draws the note")
    RT.bounds(Q, "over-head note")
end)
Q.waitFor(1, 900, function()
    for _, n in ipairs(Z.Bubbles._notes[S.pn] or {}) do if n.text == "ZeD QA note" then return false end end
    return true
end, function(ok)
    Q.check(ok, "xp: the note fades and goes")
    S.putHalo()
end)
function S.putHalo()
    if not S.back.halo then return end
    S.back.halo = nil
    Z.Messages.sources[S.halo.name] = S.halo.src
    S.setOpt(Z.Settings.haloBubbleOption, S.halo.opt or 1)
end

-- ===================================================================== the guide bubble
S.GFILE = "ZeD_guidebubble.txt"
function S.readFile(name)
    local r = nil
    pcall(function() r = getFileReader(name, false) end)
    if not r then return nil end
    local t = {}
    pcall(function()
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
    end)
    pcall(function() r:close() end)
    return t
end
function S.writeFile(name, text)
    pcall(function() local w = getFileWriter(name, true, false); w:write(text or ""); w:close() end)
end
function S.guideToast()
    local G = Z.GuideBubble
    for _, t in ipairs(Z.Messages.toasts) do if t.source == G.head() then return t end end
    return nil
end
Q.step(5, function()
    local G, M = Z.GuideBubble, Z.Messages
    local core = RT.core
    local lines = S.readFile(S.GFILE)
    S.guide = { flag = lines and (table.concat(lines, "\n") .. ((#lines > 0) and "\n" or "")) or nil,
        FIRST = G.FIRST_MS, EVERY = G.EVERY_MS, HOUR = G.HOUR_MS, SHOW = G.SHOW_MS, st = G.st,
        show = core:getOptionShowSurvivalGuide(), toastOpt = S.opt(Z.Settings.messagesToastOption), src = M.sources[G.head()] }
    S.back.guide = true
    M.sources[G.head()] = nil
    for i = #M.toasts, 1, -1 do if M.toasts[i].source == G.head() then table.remove(M.toasts, i) end end
    S.setOpt(Z.Settings.messagesToastOption, 2)
    S.writeFile(S.GFILE, "")
    core:setOptionShowSurvivalGuide(true)
    G.start()
    Q.check(G.st ~= nil, "guide: a fresh machine arms the bubble")
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = 1000, 600000, 3600000, 3000
end)
Q.waitFor(1, 900, function() return S.guideToast() ~= nil end, function(ok)
    local t = S.guideToast()
    if not Q.check(ok and t ~= nil, "guide: the bubble comes out") then return end
    Q.check(t.text == Z.GuideBubble.text(0), "guide: the guide's own words", t.text)
    Q.check(t.bare and t.long and (t.pn or 0) == 0, "guide: a long bare balloon for player one")
end)
Q.step(10, function()
    if not S.guideToast() then return end
    local anchor = Z.Belt.noteAnchor and Z.Belt.noteAnchor(S.pn)
    Q.check(anchor ~= nil, "guide: it comes out of the belt's Messages note")
    RT.bounds(Q, "guide bubble")
end)
Q.waitFor(1, 900, function() return S.guideToast() == nil end, function(ok)
    Q.check(ok, "guide: the bubble goes by itself")
    Q.check(Z.GuideBubble.lineKept(), "guide: its line stays in Messages")
    S.putGuide()
end)
function S.putGuide()
    if not S.back.guide then return end
    S.back.guide = nil
    local G, M, g = Z.GuideBubble, Z.Messages, S.guide
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = g.FIRST, g.EVERY, g.HOUR, g.SHOW
    G.st = g.st
    S.writeFile(S.GFILE, g.flag or "")
    pcall(function() RT.core:setOptionShowSurvivalGuide(g.show) end)
    M.sources[G.head()] = g.src
    for i = #M.toasts, 1, -1 do if M.toasts[i].source == G.head() then table.remove(M.toasts, i) end end
    S.setOpt(Z.Settings.messagesToastOption, g.toastOpt or 1)
end

-- ===================================================================== the hint strip at a door
function S.findDoor()
    local cell = getCell()
    local px, py, pz = math.floor(S.home.x), math.floor(S.home.y), math.floor(S.home.z)
    local best, bd = nil, 999
    for dx = -12, 12 do
        for dy = -12, 12 do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            local objs = sq and sq:getObjects()
            for i = 0, (objs and objs:size() or 0) - 1 do
                local o = objs:get(i)
                if instanceof(o, "IsoDoor") then
                    local d = math.abs(dx) + math.abs(dy)
                    if d < bd then best, bd = o, d end
                end
            end
        end
    end
    return best
end
-- where to stand and the spot to face, on each side of the door
function S.doorSpots(door)
    local sq = door:getSquare()
    local x, y = sq:getX(), sq:getY()
    local north = false
    pcall(function() north = door:getNorth() end)
    if north then
        return { { x + 0.5, y + 0.5, x + 0.5, y - 0.5 }, { x + 0.5, y - 0.5, x + 0.5, y + 0.5 } }
    end
    return { { x + 0.5, y + 0.5, x - 0.5, y + 0.5 }, { x - 0.5, y + 0.5, x + 0.5, y + 0.5 } }
end
function S.face(fx, fy)
    if not pcall(function() S.p:faceLocationF(fx, fy) end) then pcall(function() S.p:faceLocation(fx, fy) end) end
    pcall(function() S.p:setForwardDirection(fx - S.p:getX(), fy - S.p:getY()) end)
end
Q.step(5, function()
    S.hint = { opt = S.opt(Z.Settings.hintStripOption) }
    S.back.hint = true
    S.setOpt(Z.Settings.hintStripOption, 1)
    S.door = S.findDoor()
    if not S.door then Q.skip("hint strip at a door", "no door within 12 tiles on this floor"); return end
    S.spots = S.doorSpots(S.door)
    local s = S.spots[1]
    S.moveTo(s[1], s[2]); S.face(s[3], s[4])
end)
for k = 1, 2 do
    Q.waitFor(2, 60, function()
        if not S.door or S.hintOn then return true end
        local s = S.spots[k]
        S.face(s[3], s[4])
        local h = Z.HintStrip._huds[S.pn]
        return h ~= nil and h._p ~= nil
    end, function(ok)
        if not S.door or S.hintOn then return end
        if ok then S.hintOn = true; return end
        local s = S.spots[k + 1]
        if s then S.moveTo(s[1], s[2]); S.face(s[3], s[4]) end
    end)
end
Q.step(2, function()
    if not S.door then return end
    local h = Z.HintStrip._huds[S.pn]
    if not Q.check(S.hintOn == true and h ~= nil and h._p ~= nil, "hint: facing a door, the strip has the game's hints") then return end
    local words = {}
    for _, pr in ipairs(h._p) do words[#words + 1] = tostring(pr.glyph) .. " " .. tostring(pr.label) end
    Q.say("hint: " .. table.concat(words, " | "))
    local x, y, w, hh = h:getX(), h:getY(), h:getWidth(), h:getHeight()
    Q.check(math.abs(x + w / 2 - S.sw / 2) <= 2, "hint: the strip is centred")
    local belt = S.hud()
    if belt and belt._drawn then Q.check(y + hh <= belt:getY(), "hint: the strip sits above the belt") end
    RT.bounds(Q, "hint strip")
    S.pause(true)
end)
-- paused: no strip (H.prompts asks the game's speed controls)
Q.step(10, function()
    if not (S.door and S.hintOn) then S.pause(false); return end
    local h = Z.HintStrip._huds[S.pn]
    Q.check(h ~= nil and h._p == nil and Z.HintStrip.prompts(S.pn) == nil, "hint: paused, the strip is not shown")
    S.pause(false)
end)
Q.step(15, function()
    if not (S.door and S.hintOn) then return end
    local h = Z.HintStrip._huds[S.pn]
    Q.check(h ~= nil and h._p ~= nil, "hint: playing again, the strip is back")
    -- First hours: from no uses (the uses file put back after)
    S.hint.file = S.readFile(S.HFILE)
    S.hint.fileTouched = true
    S.writeFile(S.HFILE, "")
    Z.HintStrip.uses = {}
    S.setOpt(Z.Settings.hintStripOption, 2)
end)
Q.step(15, function()
    if not (S.door and S.hintOn) then return end
    local h = Z.HintStrip._huds[S.pn]
    if not Q.check(Z.Settings.hintStripMode() == "first" and h ~= nil and h._p ~= nil, "hint: First hours shows a hint not used yet") then return end
    -- three uses of each hint shown, counted as the Interact key and a right-click in the world count them
    local st = Z.HintStrip._eval[S.pn]
    for _ = 1, 3 do
        if st and st.a then Z.HintStrip.used(st.aFn, st.a) end
        Z.HintStrip.used("rightclick", "rightclick")
    end
end)
Q.waitMs(500)
Q.step(5, function()
    if not (S.door and S.hintOn) then return end
    local h = Z.HintStrip._huds[S.pn]
    Q.check(h ~= nil and h._p == nil, "hint: First hours, a hint used three times is not shown again")
    local lines = S.readFile(S.HFILE) or {}
    local counted = false
    for _, l in ipairs(lines) do if l == "rightclick=3" then counted = true end end
    Q.check(counted, "hint: the uses are kept in Zomboid/Lua/" .. S.HFILE, table.concat(lines, "; "))
    S.putHintUses()
    S.setOpt(Z.Settings.hintStripOption, 3)
end)
Q.step(10, function()
    if not S.door then return end
    local h = Z.HintStrip._huds[S.pn]
    Q.check(h ~= nil and h._p == nil and Z.HintStrip.prompts(S.pn) == nil, "hint: Off takes the strip away")
    S.putHint()
end)
S.HFILE = "ZeD_hints.txt"
function S.pause(on)
    S.paused = on and true or nil
    if on then
        pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(0) end)
        if ZEDQA_SPEED then ZEDQA_SPEED(0) else pcall(setGameSpeed, 0) end
    else
        pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(1) end)
        if ZEDQA_SPEED then ZEDQA_SPEED(1) else pcall(setGameSpeed, 1) end
    end
end
function S.putHintUses()
    if not (S.hint and S.hint.fileTouched) then return end
    S.hint.fileTouched = nil
    local f = S.hint.file
    S.writeFile(S.HFILE, f and (table.concat(f, "\n") .. ((#f > 0) and "\n" or "")) or "")
    Z.HintStrip.uses = nil   -- (read again from the file put back)
end
function S.putHint()
    if not S.back.hint then return end
    S.back.hint = nil
    S.putHintUses()
    S.setOpt(Z.Settings.hintStripOption, S.hint.opt or 1)
    S.moveTo(S.home.x, S.home.y)
end

-- ===================================================================== the forage pin and its pointer hand
-- (staged exactly as zedqa_forage_pointer.lua, which passed on beta 20: tile 925,13040, a find 3 east and 1 north, a
-- one-tile step back to the spot, then facing the find)
S.F = { icons = {} }
function S.F.mark(o)
    local m = o and o.worldMarker
    if not m then return nil end
    local r = { m = m }
    pcall(function() r.removed = m:isRemoved() end)
    if r.removed then return nil end
    pcall(function() r.w, r.h = m:getRenderWidth(), m:getRenderHeight() end)
    pcall(function() r.r, r.g, r.b, r.a = m:getR(), m:getG(), m:getB(), m:getA() end)
    r.hand = (o._zedHandOn == m) and o._zedHand or nil
    return r
end
function S.F.side(o) return ((o.xCoord - S.p:getX()) - (o.yCoord - S.p:getY()) >= 0) and "right" or "left" end
function S.F.want(side) return side == "right" and "zed_forage_hand_up_a" or "zed_forage_hand_up_b" end
function S.F.mk(dx, dy)
    local F = S.F
    local sq = getCell():getGridSquare(F.px + dx, F.py + dy, F.pz)
    if not (sq and F.ty) then return nil end
    local id = "zedqa_rthud_find"
    local fi = { id = id, zoneid = F.zone.id, x = sq:getX(), y = sq:getY(), z = sq:getZ(), catName = F.ty.cat, itemType = F.ty.type,
        isBonusIcon = false, canRollForSearchFocus = false }
    local o = ISForageIcon:new(F.mgr, fi, F.zone)
    o.isValidSquare = true
    o.checkIsForageable = function(me) me.isForageable = true; return true end
    -- (the pin's own drawing, read as it happens: the textures this icon draws)
    o._rtDrawn = {}
    o.drawTextureScaled = function(me, tex, ...)
        local n = nil
        pcall(function() n = tex:getName() end)
        me._rtDrawn[#me._rtDrawn + 1] = { tex = tex, name = tostring(n) }
        return ISUIElement.drawTextureScaled(me, tex, ...)
    end
    F.mgr.xpIcons[id] = id
    F.mgr.worldObjectIcons[id] = o
    o:doUpdateEvents(true)
    o:addToUIManager()
    o:spotIcon()
    F.icons[#F.icons + 1] = o
    return o
end
function S.F.drop(o)
    local F = S.F
    if not o or o._rtGone then return end
    pcall(function()
        F.mgr.seenIcons[o.iconID] = nil
        F.mgr.xpIcons[o.iconID] = nil
        F.mgr:removeIcon(o)
        F.mgr.worldObjectIcons[o.iconID] = nil
        if F.mgr.isoMarkers then F.mgr.isoMarkers[o.iconID] = nil end
        if F.mgr.worldMarkers then F.mgr.worldMarkers[o.iconID] = nil end
    end)
    o._rtGone = true
end
function S.F.faceOne()
    local F = S.F
    local x, y = F.hx + 3.5, F.hy - 0.5
    S.face(x, y)
end
Q.step(10, function()
    local F = S.F
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "rt_hud") end
    if math.floor(S.p:getZ()) == 0 then S.moveTo(925.5, 13040.5) end
    F.hx, F.hy, F.hz = S.p:getX(), S.p:getY(), S.p:getZ()
    F.px, F.py, F.pz = math.floor(F.hx), math.floor(F.hy), math.floor(F.hz)
    F.tod = getGameTime():getTimeOfDay()
    F.mgr = ISSearchManager.getManager(S.p)
    F.searchWas = F.mgr.isSearchMode == true
    S.back.forage = true
    Q.check(ISBaseIcon._zedOrigAddWorldMarker ~= nil and ISBaseIcon._zedOrigRenderPinIcon ~= nil, "forage: ZeD's pin and pointer are loaded")
    for t, d in pairs(forageSystem.itemDefs) do
        local inCat = false
        for _, c in ipairs(d.categories or {}) do if c == "Mushrooms" then inCat = true end end
        if inCat and pcall(instanceItem, t) and (not F.ty or t < F.ty.type) then F.ty = { type = t, cat = "Mushrooms" } end
    end
    getGameTime():setTimeOfDay(12.0)
end)
Q.step(10, function()
    local F = S.F
    F.mgr:toggleSearchMode(true)
    Q.check(F.mgr.isSearchMode == true, "forage: search mode is on")
    local okZ, z = pcall(function() return F.mgr:getAndActivateZoneAtXY(F.hx, F.hy) end)
    F.zone = okZ and z or nil
    if not F.zone then
        local zn
        for n in pairs(forageSystem.zoneDefs) do if not zn or n < zn then zn = n end end
        F.zone = { id = "zedqa_rthud_zone", name = zn, forageIcons = {} }
    end
end)
Q.step(30, function()
    local F = S.F
    F.one = F.mk(3, -1)
    S.moveTo(F.hx - 1, F.hy)
end)
Q.step(15, function()
    S.moveTo(S.F.hx, S.F.hy)
    S.F.faceOne()
end)
Q.step(60, function()
    local F = S.F
    local o = F.one
    if not Q.check(o ~= nil, "forage: a find is staged", F.ty and F.ty.type) then return end
    local r = F.mark(o)
    if Q.check(r ~= nil, "forage: the pointer to the find is up") then
        Q.check(r.hand == F.want(F.side(o)), "forage: the pointer is ZeD's hand for the find's side", tostring(r.hand))
        Q.check(math.floor((r.w or 0) + 0.5) == 44 and math.floor((r.h or 0) + 0.5) == 77, "forage: the hand is 44 x 77")
        Q.check(math.abs((r.r or 0) - 1) < 0.01 and math.abs((r.a or 0) - 1) < 0.01, "forage: white at full alpha")
    end
    local zed, any = 0, #o._rtDrawn
    local want = { getTexture("media/textures/ZeD/forage/pinB_back.png"), getTexture("media/textures/ZeD/forage/pinB_unknown.png") }
    for _, d in ipairs(o._rtDrawn) do
        if d.tex == want[1] or d.tex == want[2] or d.name:find("pinB_", 1, true) then zed = zed + 1 end
    end
    Q.check(zed > 0, "forage: the pin over the find is ZeD's magnifying glass", zed .. " of " .. any .. " draws")
    local notes = Z.Bubbles.notes(S.pn, getTimestampMs()) or {}
    local eye = false
    for _, n in ipairs(notes) do if n.eye then eye = true end end
    Q.check(eye, "forage: the search-mode eye is in ZeD's over-head stack")
    RT.bounds(Q, "forage")
    S.putForage()
end)
Q.step(20, function()
    local left = 0
    for _, o in ipairs(S.F.icons) do if o.worldMarker then left = left + 1 end end
    Q.check(left == 0, "forage: the find and its pointer are gone again")
end)
function S.putForage()
    if not S.back.forage then return end
    S.back.forage = nil
    local F = S.F
    for _, o in ipairs(F.icons) do F.drop(o) end
    pcall(function() getGameTime():setTimeOfDay(F.tod) end)
    if not F.searchWas then
        pcall(function() F.mgr:toggleSearchMode(false) end)
        pcall(function() local eng = getSearchMode(); eng:setOverride(S.pn, false); eng:setEnabled(S.pn, false) end)
    end
end

-- ===================================================================== balloon help: one at a time, dismiss
-- (probes of the test ask for balloons from their own render, as every ZeD control does through ZeD.Balloon.draw)
S.Probe = ISUIElement:derive("ZeD_RTBalloonProbe")
function S.Probe:render()
    local a = self.ask
    self.got = nil
    if not a then return end
    local ok, x = pcall(Z.Balloon.draw, self, a.c, a.rect, "above", a.opts)
    self.got = (ok and x ~= nil) and true or false
    if not ok then self.err = tostring(x) end
end
function S.newProbe()
    local o = S.Probe:new(S.sw - 3, S.sh - 3, 2, 2)
    o:initialise()
    o:addToUIManager()
    pcall(function() o:setAlwaysOnTop(true) end)
    S.probes[#S.probes + 1] = o
    return o
end
function S.putBalloon()
    if not S.back.balloon then return end
    S.back.balloon = nil
    for _, o in ipairs(S.probes or {}) do
        o.ask = nil
        pcall(function() o:removeFromUIManager() end)
    end
    S.probes = {}
end
Q.step(5, function()
    S.probes = {}
    S.bl = { t0 = getTimestampMs() }
    S.back.balloon = true
    pcall(function() Mouse.setXY(20, 20) end)
    local px = ZeD.T.px
    local a = S.newProbe()
    a.ask = { c = { kind = "plain", title = "ZeD QA: a balloon near the corner of the screen" },
        rect = { x = S.sw - px(40), y = S.sh - px(24), w = px(30), h = px(18) },
        opts = { key = "rtqa:a", since = S.bl.t0, owner = a } }
    S.bl.a = a
end)
Q.waitFor(2, 60, function() return Z.Balloon.up() and Z.Balloon._slot.key == "rtqa:a" end, function(ok)
    if not Q.check(ok, "balloon: it shows", S.bl.a.err or tostring(Z.Balloon._slot.key)) then return end
    local b = Z.Balloon._slot.box
    Q.check(b ~= nil and S.onScreen(b.x, b.y, b.w, b.h), "balloon: near the screen's corner it stays fully on screen",
        b and string.format("%d,%d %dx%d", b.x, b.y, b.w, b.h))
    local p2 = S.newProbe()
    p2.ask = { c = { kind = "plain", title = "ZeD QA: a second balloon" },
        rect = { x = math.floor(S.sw / 2), y = math.floor(S.sh / 2), w = 20, h = 20 },
        opts = { key = "rtqa:b", since = S.bl.t0 - 1000, owner = p2 } }
    S.bl.b = p2
end)
Q.step(10, function()
    if not S.bl.b then return end
    Q.check(Z.Balloon._slot.key == "rtqa:a" and S.bl.a.got == true and S.bl.b.got == false,
        "balloon: one at a time (a second one asked while it is up does not draw)", "up: " .. tostring(Z.Balloon._slot.key))
    S.bl.b.ask = nil
    -- (Escape's handler, Balloon.lua's OnKeyPressed, and the pad's B, FocusManager, both call dismiss)
    Z.Balloon.dismiss()
end)
Q.step(10, function()
    if not S.bl.b then return end
    Q.check(not Z.Balloon.up() and S.bl.a.got == false, "balloon: dismissed, it stays down while its control still asks")
    S.bl.a.ask.opts = { key = "rtqa:c", since = getTimestampMs(), owner = S.bl.a }
end)
Q.waitFor(2, 60, function() return S.bl.b == nil or (Z.Balloon.up() and Z.Balloon._slot.key == "rtqa:c") end, function(ok)
    if S.bl.b then Q.check(ok, "balloon: the focus on another control brings a balloon back") end
    S.putBalloon()
end)

-- ===================================================================== the Character window read-only while paused
S.FREE = { charTabBar = true, charContainerStrip = true, worldTabBar = true, worldContainerStrip = true,
    charTitlePins = true, worldTitlePins = true }
Q.step(5, function()
    S.closeMenu()
    RT.pairOpen()
end)
Q.waitFor(5, 300, function() local w = RT.cw(); return w ~= nil and w:isReallyVisible() and w._mainContent ~= nil end, function(ok)
    if not Q.check(ok, "paused: the Character window is open") then S.plSkip = true; return end
    S.plTab = RT.cw()._activeTab
    S.pause(true)
end)
Q.step(10, function()
    if S.plSkip then return end
    local PL = Z.PausedLook
    local w = RT.cw()
    local g = PL._glass
    Q.check(PL.on(), "paused: the game reads paused")
    if not Q.check(g ~= nil and g.win == w and g:isVisible(), "paused: the glass lies on the Character window") then return end
    local c = w._mainContent
    local gx, gy, gw, gh = g:getAbsoluteX(), g:getAbsoluteY(), g:getWidth(), g:getHeight()
    local mx, my = c:getAbsoluteX() + math.floor(c:getWidth() / 2), c:getAbsoluteY() + math.floor(c:getHeight() / 2)
    Q.check(mx >= gx and mx < gx + gw and my >= gy and my < gy + gh, "paused: the glass covers the item list")
    Q.check(g:onMouseDown(10, 10) == true and g:onRightMouseDown(10, 10) == true, "paused: the glass takes a press and a right press (nothing is used)")
    local F = ZeD.Input and ZeD.Input.Focus
    local fz = F and F.liveZone and F.liveZone(w)
    local free = (fz and S.FREE[fz.zone]) and true or false
    Q.check(PL.blocks(w) == (not free), "paused: the pad's A and X are held outside the tab strip and the bags", fz and fz.zone or "no live zone")
    RT.bounds(Q, "paused Character window")
    S.plAlt = nil
    for _, id in ipairs(RT.tabs(RT.charStrip())) do if not S.plAlt and id ~= S.plTab and id ~= "loot" then S.plAlt = id end end
    if S.plAlt then RT.charTab(S.plAlt) end
end)
Q.step(15, function()
    if S.plSkip then return end
    if S.plAlt then
        Q.check(RT.cw()._activeTab == S.plAlt, "paused: the tab strip still switches tabs", tostring(RT.cw()._activeTab) .. ", want " .. S.plAlt)
    end
    S.pause(false)
end)
Q.step(10, function()
    if S.plSkip then return end
    local g = Z.PausedLook._glass
    Q.check(not (g and g:isVisible()) and not Z.PausedLook.blocks(RT.cw()), "paused: playing again, the glass is gone")
end)

-- ===================================================================== pin a skill from its row's menu
function S.putPins()
    if not S.back.pin then return end
    S.back.pin = nil
    S.closeMenu()
    local md = S.p:getModData()
    md.ZeD_Pins = S.pin.had and S.pin.list or nil
    local w = RT.cw()
    if w then
        w._pinnedSkills = Z.Pins.skillNames(S.p)
        if S.pin.grid ~= nil then w._skillsGridExpanded = S.pin.grid; w._skillsCache = nil end
    end
end
Q.step(5, function()
    local md = S.p:getModData()
    S.pin = { had = md.ZeD_Pins ~= nil, list = {} }
    for i, e in ipairs(md.ZeD_Pins or {}) do
        local c = {}
        for k2, v in pairs(e) do c[k2] = v end
        S.pin.list[i] = c
    end
    S.back.pin = true
    local w = RT.cw()
    -- (the skill rows draw only while the grid is open: opened for the test if a player folded it, put back after)
    if w then S.pin.grid = w._skillsGridExpanded; w._skillsGridExpanded = true; w._skillsCache = nil end
    if not Q.check(w ~= nil and RT.charTab("skills"), "pin: the Skills tab opens from the strip") then S.pinSkip = true end
end)
Q.waitFor(5, 300, function()
    local w = RT.cw()
    local z = w and w._skillRowZones
    return S.pinSkip or (z ~= nil and (z.n or 0) > 0 and w._drawerPanel ~= nil and w._activeTab == "skills")
end, function(ok)
    if S.pinSkip then return end
    if not Q.check(ok, "pin: the Skills tab draws its skill rows") then S.pinSkip = true; return end
    local w = RT.cw()
    local zl = w._skillRowZones
    for i = 1, zl.n do
        local z = zl[i]
        if not S.pinZone and z and z.name and not Z.Pins.isPinned(S.p, "skill", z.name) then S.pinZone = z end
    end
    if not S.pinZone then S.pinSkip = true; Q.skip("pin a skill", "every skill row is pinned already"); return end
    local z = S.pinZone
    w._drawerPanel:onRightMouseUp(z.x + 2, z.y + 2)
end)
Q.waitFor(2, 120, function() return S.pinSkip or S.menu() ~= nil end, function(ok)
    if S.pinSkip then return end
    if not Q.check(ok, "pin: a right-click on the skill row opens its menu") then S.pinSkip = true; return end
    RT.bounds(Q, "skill row menu")
    local c = S.ctx()
    local opt = c and c:getOptionFromName(ZeD.tr("UI_ZeD_Pin_Pin"))
    if Q.check(opt ~= nil and opt.onSelect ~= nil, "pin: the menu offers Pin to title bar") then opt.onSelect(opt.target) end
    S.closeMenu()
end)
Q.step(15, function()
    if S.pinSkip then return end
    local name = S.pinZone.name
    Q.check(Z.Pins.isPinned(S.p, "skill", name), "pin: the skill is pinned", name)
    local pd = ZeD.SkillsTab.getPinData(S.p, name)
    local want = (pd and pd.level < 10) and (tostring(pd.xpInLevel) .. "/" .. tostring(pd.xpForLevel)) or nil
    local seen, all = false, {}
    for _, st in ipairs(RT.cw().titleStats or {}) do
        local t = tostring(st.text or "")
        all[#all + 1] = t
        if want and t:find(want, 1, true) then seen = true end
        if pd and not want and not st.noMark and t ~= "" then seen = true end
    end
    Q.check(seen, "pin: the title bar shows its level and XP", tostring(want) .. " in: " .. table.concat(all, " | "))
    S.putPins()
end)

-- ===================================================================== pop-outs keep clear of ZeD windows
Q.step(5, function()
    local PC = ZeD.PopClear
    local wins = {}
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        local vis = false
        if w then pcall(function() vis = w:isReallyVisible() end) end
        if vis then wins[#wins + 1] = { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() } end
    end
    if not Q.check(PC ~= nil and #wins > 0, "popclear: a ZeD window is open to keep clear of") then return end
    local s = ZeD.T.px(60)
    local function over(x, y)
        for _, b in ipairs(wins) do
            if x < b.x + b.w and b.x < x + s and y < b.y + b.h and b.y < y + s then return b end
        end
        return nil
    end
    local last = wins[#wins]
    local x, y = last.x + math.floor((last.w - s) / 2), last.y + math.floor(last.h / 2)
    local nx, ny = PC.spot(S.pn, x, y, s, s)
    if nx ~= x or ny ~= y then
        Q.check(over(nx, ny) == nil and S.onScreen(nx, ny, s, s), "popclear: a pop-out over a ZeD window moves clear of it, on screen",
            string.format("%d,%d to %d,%d", x, y, nx, ny))
    else
        local b = over(x, y)
        local gap = ZeD.T.px(8)
        local room = false
        for _, ty in ipairs({ b.y + b.h + gap, b.y - s - gap }) do
            if ty >= 0 and ty + s <= S.sh and over(x, ty) == nil then room = true end
        end
        Q.check(not room, "popclear: it stays over the window only when neither below nor above has room")
    end
    local fx, fy = nil, nil
    for gy = 0, S.sh - s, s do
        for gx = 0, S.sw - s, s do
            if not fx and over(gx, gy) == nil then fx, fy = gx, gy end
        end
    end
    if fx then
        local kx, ky = PC.spot(S.pn, fx, fy, s, s)
        Q.check(kx == fx and ky == fy, "popclear: a spot clear of the windows is kept", string.format("%d,%d to %d,%d", fx, fy, kx, ky))
    else
        Q.skip("popclear: a clear spot is kept", "the windows cover the whole screen")
    end
    if S.plTab then RT.charTab(S.plTab) end
    RT.pairShut()
end)

-- ===================================================================== the prompts: text box, rich text, Escape and Enter
S.pr = { open = {} }
function S.prCb(target, button)
    local par = button and button.parent
    S.pr.got = { internal = button and button.internal, text = par and par.entry and par.entry:getText() }
end
function S.prOpen(o)
    o._zedSource = nil   -- (the test's own prompt: never one of another mod's notes kept in Messages)
    o:initialise()
    o:addToUIManager()
    S.pr.open[#S.pr.open + 1] = o
    return o
end
function S.prClick(o, b)
    for _, h in ipairs((o and o._g and o._g.hits) or {}) do
        if b and h.b == b then
            local x, y = h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)
            o:onMouseDown(x, y)
            o:onMouseUp(x, y)
            return true
        end
    end
    return false
end
function S.prShut(o)
    local vis = false
    if o then pcall(function() vis = o:isReallyVisible() end) end
    return o == nil or o._dead == true or not vis
end
function S.prOnScreen(o) return S.onScreen(o:getX(), o:getY(), o:getWidth(), o:getHeight()) end
function S.pauseMenuUp()
    local up = false
    pcall(function() local ms = MainScreen.instance; up = ms ~= nil and ms.inGame and ms:isVisible() end)
    return up and true or false
end
function S.shutPauseMenu()
    if S.pauseMenuUp() and ToggleEscapeMenu then pcall(ToggleEscapeMenu, Keyboard.KEY_ESCAPE) end
end
function S.putPrompts()
    if not S.back.prompts then return end
    S.back.prompts = nil
    for _, o in ipairs(S.pr.open or {}) do
        if not S.prShut(o) then pcall(function() o:answerCancel() end) end
        if not S.prShut(o) then pcall(function() o:destroy() end) end
    end
    S.pr.open = {}
    S.shutPauseMenu()
end
Q.step(5, function()
    S.back.prompts = true
    pcall(function() Mouse.setXY(20, 20) end)
    local o = ISTextBox:new(0, 0, 280, 180, "ZeD QA: a name for it?", "ZeD QA default", nil, S.prCb, S.pn)
    if not Q.check(o ~= nil and o.kind == "text", "prompt: the game's ISTextBox is ZeD's text prompt", o and o.Type) then return end
    S.pr.text = S.prOpen(o)
end)
Q.waitFor(3, 120, function() local o = S.pr.text; return o == nil or (o._g ~= nil and o:isReallyVisible()) end, function(ok)
    local o = S.pr.text
    if not o then return end
    if not Q.check(ok, "prompt: the text prompt shows") then return end
    Q.check(S.prOnScreen(o), "prompt: the text prompt is on screen")
    RT.bounds(Q, "text prompt")
    o.entry:setText("ZeD QA typed")
    Q.check(S.prClick(o, o.yes), "prompt: the text prompt has its OK")
end)
Q.step(5, function()
    local o = S.pr.text
    if not o then return end
    local g = S.pr.got
    Q.check(g ~= nil and g.internal == "OK" and g.text == "ZeD QA typed", "prompt: OK hands the typed text back in entry",
        g and (tostring(g.internal) .. " " .. tostring(g.text)))
    Q.check(S.prShut(o), "prompt: the text prompt closes on OK")
    S.pr.got = nil
    local para = "ZeD QA: a long note to lay out. " .. string.rep("The words run on to fill the line and the next. ", 6)
    local t = {}
    for _ = 1, 14 do t[#t + 1] = para end
    local r = ISModalRichText:new(0, 0, 420, 300, table.concat(t, " <LINE> <LINE> "), false, nil, S.prCb, S.pn)
    if not Q.check(r ~= nil and r.kind == "rich", "prompt: the game's ISModalRichText is ZeD's rich prompt", r and r.Type) then return end
    S.pr.rich = S.prOpen(r)
end)
Q.waitFor(3, 120, function()
    local o = S.pr.rich
    return o == nil or (o._g ~= nil and o._maxScroll ~= nil and o:isReallyVisible())
end, function(ok)
    local o = S.pr.rich
    if not o then return end
    if not Q.check(ok, "prompt: the rich prompt shows") then return end
    Q.check(S.prOnScreen(o), "prompt: the long rich text stays on screen", string.format("%d,%d %dx%d on %dx%d",
        o:getX(), o:getY(), o:getWidth(), o:getHeight(), S.sw, S.sh))
    Q.check((o._maxScroll or 0) > 0, "prompt: the long text scrolls inside it instead of growing past the screen", o._maxScroll)
    RT.bounds(Q, "rich prompt")
    Q.check(S.prClick(o, o.ok), "prompt: the rich prompt has its OK")
end)
Q.step(5, function()
    local o = S.pr.rich
    if not o then return end
    Q.check(S.pr.got ~= nil and S.pr.got.internal == "OK" and S.prShut(o), "prompt: OK answers and closes the rich prompt")
    S.pr.got = nil
    if not (_G._zedPromptKeys and ToggleEscapeMenu) then
        S.pr.keySkip = true
        Q.skip("Escape and Enter on a prompt", "ZeD's key handler is not in place")
        return
    end
    local q = ISModalDialog:new(0, 0, 250, 150, "ZeD QA: Escape answers No", true, nil, S.prCb, S.pn)
    if not Q.check(q ~= nil and q.kind == "question", "prompt: the game's ISModalDialog is ZeD's question") then S.pr.keySkip = true; return end
    S.pr.q1 = S.prOpen(q)
end)
Q.waitFor(3, 120, function() return S.pr.keySkip or Z.Prompt.top() == S.pr.q1 end, function(ok)
    if S.pr.keySkip then return end
    if not Q.check(ok, "prompt: the question is the prompt on top") then S.pr.keySkip = true; return end
    -- (the game's own key handler: ToggleEscapeMenu is ZeD's onKey, with the game's behind it)
    ToggleEscapeMenu(Keyboard.KEY_ESCAPE)
end)
Q.step(5, function()
    if S.pr.keySkip then return end
    local g = S.pr.got
    Q.check(g ~= nil and g.internal == "NO" and S.prShut(S.pr.q1), "prompt: Escape answers No on the prompt on top", g and g.internal)
    Q.check(not S.pauseMenuUp(), "prompt: that Escape does not open the pause menu")
    S.shutPauseMenu()
    S.pr.got = nil
    S.pr.q2 = S.prOpen(ISModalDialog:new(0, 0, 250, 150, "ZeD QA: Enter answers Yes", true, nil, S.prCb, S.pn))
end)
Q.waitFor(3, 120, function() return S.pr.keySkip or Z.Prompt.top() == S.pr.q2 end, function(ok)
    if S.pr.keySkip then return end
    if not Q.check(ok, "prompt: the second question is the prompt on top") then return end
    ToggleEscapeMenu(Keyboard.KEY_RETURN)
end)
Q.step(5, function()
    if not S.pr.keySkip then
        local g = S.pr.got
        Q.check(g ~= nil and g.internal == "YES" and S.prShut(S.pr.q2), "prompt: Enter presses the main answer (Yes)", g and g.internal)
    end
    S.putPrompts()
end)

-- ===================================================================== the game's mini-map stays hidden
function S.putMiniMap()
    if not S.back.mm then return end
    S.back.mm = nil
    local m = S.mm
    if m.inUI then
        pcall(function() m.m:setVisible(m.vis) end)
        Z.MiniMapOff._hidden[S.pn] = m.hid
    else
        pcall(function() m.m:setVisible(false) end)
        pcall(function() m.m:removeFromUIManager() end)
        Z.MiniMapOff._hidden[S.pn] = nil
    end
end
Q.step(5, function()
    local mm = getPlayerMiniMap and getPlayerMiniMap(S.pn)
    if not (mm and Z.MiniMapOff) then S.mmSkip = true; Q.skip("the mini-map stays hidden", "the game made no mini-map for this player"); return end
    S.mm = { m = mm, inUI = false, hid = Z.MiniMapOff._hidden[S.pn] }
    pcall(function() S.mm.vis = mm:isVisible() end)
    for _, r in ipairs(RT.roots()) do if r.t == mm then S.mm.inUI = true end end
    S.back.mm = true
    if not S.mm.inUI then pcall(function() mm:addToUIManager() end) end
    pcall(function() mm:setVisible(true) end)
    S.mm.t0 = getTimestampMs()
end)
Q.waitFor(1, 600, function()
    if S.mmSkip then return true end
    local v = true
    pcall(function() v = S.mm.m:isReallyVisible() end)
    return not v
end, function(ok)
    if S.mmSkip then return end
    local ms = getTimestampMs() - S.mm.t0
    Q.check(ok and ms <= 700, "mini-map: shown, it is hidden again within 500 ms", ms .. " ms")
    Q.check(Z.MiniMapOff._hidden[S.pn] == S.mm.m, "mini-map: kept to give back")
    Z.MiniMapOff.restore()
    local v = false
    pcall(function() v = S.mm.m:isVisible() end)
    Q.check(v, "mini-map: restore (safe mode's leave) shows it again")
    S.putMiniMap()
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    pcall(function() S.p:StopAllActionQueue() end)
    if S.paused then S.pause(false) end
    S.putPrompts(); S.putBalloon(); S.putPins(); S.putMiniMap(); S.putRc(); S.putAttach(); S.putBeltStyle(); S.putAbStyle()
    S.putHands(); S.putWatch(); S.putMoodles(); S.putHalo(); S.putGuide(); S.putHint(); S.putForage()
    pcall(function() S.p:setZ(S.home.z); S.p:setLastZ(S.home.z) end)
    S.moveTo(S.home.x, S.home.y)
    if S.pairWas then RT.pairOpen() else RT.pairShut() end
end)
Q.step(10, function()
    Q.check(math.abs(S.p:getX() - S.home.x) < 0.01 and math.abs(S.p:getY() - S.home.y) < 0.01, "put back: the character where it started")
    if S.mood then Q.check(S.opt(Z.Settings.moodlePlaceOption) == (S.mood.opt or 1), "put back: the moodles' place") end
    if S.watch then Q.check(S.opt(Z.Settings.watchPlaceOption) == S.watch.opt, "put back: the watch's place") end
end)
Q.start()
