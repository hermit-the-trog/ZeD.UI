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
--             back and the facing): ZeD's pin is drawn and the pointer is ZeD's hand at its set size and alpha (ISBaseIcon._zedHandSize), white; the eye note
--   guide     ZeD_GuideBubble.lua: a fresh machine's guide bubble comes out of the belt with the guide's words and fades,
--             with ZeD setup's balloons Off (the default; Nov 22 2026, QA K1-15) and again with them On
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
--   paused    ZeD_PausedLook.lua: paused, the Character window's glass covers its open page and eats presses, a veil
--             on its item list lets them through (KISS #41: moves between bags wait for play), the tab strip still
--             switches tabs; playing again the glass and the veil are gone
--   pin       ZeD_Pins.lua: a skill row's right-click menu pins the skill; the title bar shows its level and XP
--   popclear  PopClear.lua: a spot over a ZeD window moves clear of it (or stays only when neither side has room)
--   prompts   ZeD_Prompt.lua / Overrides/Prompts.lua: the game's ISTextBox is ZeD's text prompt and OK hands the typed
--             text back; a long rich text stays on screen and scrolls; Escape and Enter answer the prompt on top and
--             the pause menu stays shut
--   mini-map  Overrides/MiniMap.lua: the game's mini-map shown is hidden again within 500 ms; restore shows it
-- (Nov 18 2026, QA, the ledger's proof pass, more closed here:)
--   alone     ZeD_CharacterWindow.toggle opens the Character window without the World window, on Loot; UI scale Auto's
--             root is the screen height over 1080, held to 0.75 .. 4, times the font knob
--   column    the game's left-edge column shows no hands and no window buttons
--   keys      a number key held opens its slot's list at the slot; its release draws nothing; the Messages notice in
--             the screen's corner (ZeD_ErrorBox.lua, Nov 22 2026: the note left the belt) opens the Messages window
-- (Nov 23 2026, QA, Build's fix/beltrow2 on main 99d56a202: the director's "Belt, space, time, space, messages, chat"
-- put the notice back on player one's belt row:)
--   notice    while the belt draws the Messages notice stands on the row (ZeD.Belt.noticeScreen(0) is its place,
--             ZeD.ErrorBox.rect()'s fourth value true) and single player's row ends with it after the speed keys (on
--             a server the chat key follows it); a click opens Messages and the balloons come out of it; with the
--             belt away (the game's Toggle UI flag, ISUIHandler.allUIVisible false, the belt's own wanted() test) it
--             falls back to the screen's bottom right corner; the guide bubble comes out of it where it stands
--   more      the action bar's queue count; the watch's light; an item pinned from its own menu, and a fourth pin
--             taking off the oldest with a note; the run button's hold crouching and standing (RunSneak's QA hook)
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

-- ===================================================================== one window alone; UI scale Auto
-- (Nov 18 2026, QA, the ledger: ZeD_CharacterWindow.toggle, what the pair key calls for the Character window, opens it
-- alone, on Loot with its drawer shut; Auto's root worked out with no fixed pick, the run's own scale left as it is)
Q.step(5, function() pcall(ZeD_CharacterWindow.toggle, S.pn) end)
Q.waitFor(2, 120, function() local w = RT.cw(); return w ~= nil and w:isReallyVisible() end, function(ok)
    local w = RT.cw()
    local ww, wwVis = RT.ww(), false
    if ww then pcall(function() wwVis = ww:isReallyVisible() end) end
    Q.check(ok and w ~= nil and not wwVis, "window alone: toggle opens the Character window without the World window")
    Q.check(w ~= nil and w._activeTab == "loot" and w._drawerOpen ~= true, "window alone: it opens on Loot with the drawer shut",
        tostring(w and w._activeTab) .. ", drawer " .. tostring(w and w._drawerOpen))
    RT.bounds(Q, "the Character window alone")
    pcall(ZeD_CharacterWindow.toggle, S.pn)
end)
Q.step(5, function()
    Q.check(ZeD_CharacterWindow.getWindow(S.pn) == nil, "window alone: toggle again closes it")
    local Sc = ZeD.Scale
    if not Q.check(Sc ~= nil and Sc.computeGame ~= nil and Sc.userMul ~= nil, "UI scale Auto: ZeD.Scale is loaded") then return end
    local want = math.max(0.75, math.min(4, S.sh / 1080)) * Sc.userMul()
    local us, ov = Sc.userScale, Sc.override
    Sc.userScale, Sc.override = nil, nil
    local ok, got = pcall(Sc.computeGame)
    Sc.userScale, Sc.override = us, ov
    Q.check(ok and type(got) == "number" and math.abs(got - want) < 0.001,
        "UI scale Auto: the root is the screen height over 1080, held to 0.75 .. 4, times the font knob",
        tostring(got) .. ", want " .. tostring(want) .. " at " .. tostring(S.sh) .. " px high")
    if us == nil and ov == nil then
        Q.check(math.abs(Sc.root() - want) < 0.001, "UI scale Auto: the run is on Auto and draws at that root", tostring(Sc.root()))
    end
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
    -- (Nov 18 2026, QA, the ledger: the game's left-edge column, ISEquippedItem: its hands and its window buttons are
    -- hidden, or the whole column is; under -debug the column stays for its debug buttons, the window buttons still go)
    local eq, eqVis = nil, false
    pcall(function() local pd = getPlayerData(S.pn); eq = pd and pd.equipped end)
    if eq then pcall(function() eqVis = eq:getIsVisible() end) end
    local shown = {}
    if eq and eqVis then
        for _, k in ipairs({ "invBtn", "healthBtn", "craftingBtn", "buildBtn", "movableBtn", "searchBtn", "zoneBtn", "mapBtn", "mainHand", "offHand" }) do
            local b, v = eq[k], false
            if b then pcall(function() v = b:getIsVisible() end) end
            if v then shown[#shown + 1] = k end
        end
    end
    Q.check(eq ~= nil and #shown == 0, "belt: the game's left column shows no hands and no window buttons",
        eq and (eqVis and ("column up; showing: " .. table.concat(shown, " ")) or "column hidden") or "no column")
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

-- ===================================================================== belt: a number key held; the Messages note
-- (Nov 18 2026, QA, the ledger. The held key: the game's own OnKeyKeepPressed with the slot's key, the press half a
-- second old (Overrides/Belt.lua's holdKeepPressed reads the hotbar's keyPressedMS), then the release through
-- OnKeyPressed, which ZeD's handler takes so it draws nothing. The note: the belt's own mouse handler on its box.)
function S.listUp()
    local m = S.menu()
    local v = false
    if m then pcall(function() v = m:isReallyVisible() end) end
    if v then return m end
    local c = S.ctx()
    if c then pcall(function() v = c:isReallyVisible() end) end
    return v and c or nil
end
Q.step(5, function()
    S.closeMenu()
    local hb = Z.Belt.hotbar and Z.Belt.hotbar(S.pn)
    local hud = S.hud()
    local i = hud and hud:_firstSlotIdx()
    local b = i and hud._boxes[i]
    if not (hb and b and b.kind == "slot") then S.hkSkip = true; Q.skip("belt: a number key held", "the belt shows no slot"); return end
    local key = nil
    for k = 2, 11 do   -- (Keyboard.KEY_1 .. KEY_0)
        local okS, si = pcall(function() return hb:getSlotForKey(k) end)
        if not key and okS and si == b.i then key = k end
    end
    if not key then S.hkSkip = true; Q.skip("belt: a number key held", "no number key is bound to slot " .. tostring(b.i)); return end
    S.hk = { key = key, i = b.i, hands = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() } }
    hb.keyPressedMS = getTimestampMs() - 700
    pcall(triggerEvent, "OnKeyKeepPressed", key)
end)
Q.waitFor(2, 60, function() return S.hkSkip or S.listUp() ~= nil end, function(ok)
    if S.hkSkip then return end
    local m = S.listUp()
    if not Q.check(ok and m ~= nil, "belt: a number key held past half a second opens its slot's list") then return end
    local x, y, w, h = m:getX(), m:getY(), m:getWidth(), m:getHeight()
    local bx = Z.Belt.boxScreen(S.hk.i, S.pn)
    local slack = ZeD.T.px(40)
    Q.check(bx ~= nil and bx >= x - slack and bx <= x + w + slack and S.onScreen(x, y, w, h), "belt: the slot's list opens at its slot, on screen",
        string.format("%d,%d %dx%d", x, y, w, h) .. ", slot at x " .. tostring(bx))
    RT.bounds(Q, "the slot's list")
    S.closeMenu()
    pcall(triggerEvent, "OnKeyPressed", S.hk.key)
end)
Q.step(10, function()
    if S.hkSkip then return end
    Q.check(S.p:getPrimaryHandItem() == S.hk.hands[1] and S.p:getSecondaryHandItem() == S.hk.hands[2],
        "belt: the key's release after the list draws nothing")
    pcall(function() S.p:setPrimaryHandItem(S.hk.hands[1]); S.p:setSecondaryHandItem(S.hk.hands[2]) end)
    S.closeMenu()
end)
-- (Nov 18 2026: the Messages note showed only while ZeD.Messages held a note. Nov 22 2026, the error box (2db43d57a):
-- the note left the belt for the screen's bottom right corner, ZeD.ErrorBox._note, shown while anything is unread and
-- a few seconds after something new. The check stages its own unread note (always: an unread line keeps the notice
-- up) and clears it after. The click is the notice's own mouse handler (ZeD.ErrorBox.press, as a click does).)
-- (Nov 23 2026, Build's fix/beltrow2: the notice is back on player one's belt row after the speed keys, shown all the
-- time the belt draws; the corner is its fallback while the belt is away. The first checks read it on the row; the
-- corner is staged after the click with the game's Toggle UI flag.)
Q.step(5, function()
    local M = ZeD.Messages
    if M then
        pcall(function() M.add("ZeDQA rt_hud", "mods", { head = "QA", text = "a note for the Messages notice check" }) end)
        S.msgStaged = true
    end
end)
Q.waitFor(2, 120, function()
    local el = Z.ErrorBox and Z.ErrorBox._note
    return el ~= nil and el:getIsVisible()
end, function(ok)
    local E = Z.ErrorBox
    local el = E and E._note
    local MW = ZeD.MessagesWindow
    local x, y, w, h = 0, 0, 0, 0
    if el then x, y, w, h = el:getX(), el:getY(), el:getWidth(), el:getHeight() end
    -- (on the row: the belt's place for it, ZeD.Belt.noticeScreen(0), and ZeD.ErrorBox.rect()'s fourth value true)
    local hud = S.hud()
    local okN, nx, ny = false, nil, nil
    if Z.Belt and Z.Belt.noticeScreen then okN, nx, ny = pcall(Z.Belt.noticeScreen, 0) end
    if not okN then nx, ny = nil, nil end
    local onRow = false
    if E and E.rect then
        local okR, _, _, _, r4 = pcall(E.rect)
        onRow = okR and r4 == true
    end
    -- (an error marker up lifts the notice by its height: then it stands no lower than its row place)
    local lifted = E ~= nil and E._mk ~= nil and E._mk.phase ~= nil
    local atRow = nx ~= nil and ny ~= nil and math.abs(x - nx) <= 1 and (math.abs(y - ny) <= 1 or (lifted and y <= ny))
    local drawn = hud ~= nil and hud._drawn == true
    if not Q.check(ok and el ~= nil and drawn and atRow and onRow and S.onScreen(x, y, w, h) and MW ~= nil,
        "notice: while the belt draws, the Messages notice stands on the belt row (ZeD.Belt.noticeScreen(0), ZeD.ErrorBox.rect() on the row)",
        string.format("%d,%d %dx%d on %dx%d", x, y, w, h, S.sw, S.sh) .. "; the row place " .. tostring(nx) .. "," .. tostring(ny)
        .. ", rect on the row " .. tostring(onRow) .. ", the belt drawn " .. tostring(drawn) .. ", the marker up " .. tostring(lifted)) then
        S.lampSkip = true
        if S.msgStaged then pcall(function() ZeD.Messages.clear("ZeDQA rt_hud") end); S.msgStaged = nil end
        return
    end
    -- (the row's order: the speed keys, then the notice; single player's row ends with it, on a server the chat key
    -- follows it and there are no speed keys)
    local kinds = {}
    for _, b in ipairs(hud._boxes or {}) do kinds[#kinds + 1] = tostring(b.kind) end
    local ni = nil
    for i, k in ipairs(kinds) do if k == "notice" then ni = i end end
    local server = (isClient and isClient()) and true or false
    local orderOk = false
    if ni and server then orderOk = kinds[ni + 1] == "chat"
    elseif ni then orderOk = ni == #kinds and kinds[ni - 1] == "speed" end
    Q.check(orderOk, "notice: the belt row ends with the Messages notice after the speed keys (single player; on a server the chat key follows it)",
        (server and "server: " or "single player: ") .. table.concat(kinds, ","))
    -- (where Messages' balloons come out, read while it shows: its top middle)
    S.noteAx, S.noteAy = E.anchor(S.pn)
    S.noteBox = { x = x, y = y, w = w, h = h }
    local w0 = MW.get(S.pn)
    S.msgWas = w0 ~= nil and w0:isReallyVisible()
    S.toastsWas = Z.Messages.toasts   -- (the window's open clears the toasts: put back after)
    S.back.lamp = true
    el:onMouseDown(math.floor(w / 2), math.floor(h / 2))
    pcall(function() el:onMouseUp(math.floor(w / 2), math.floor(h / 2)) end)
end)
Q.waitFor(2, 60, function()
    if S.lampSkip then return true end
    local w = ZeD.MessagesWindow.get(S.pn)
    return w ~= nil and w:isReallyVisible()
end, function(ok)
    if S.lampSkip then return end
    local w = ZeD.MessagesWindow.get(S.pn)
    Q.check(ok and w ~= nil, "notice: a click on the Messages notice opens the Messages window")
    if w then Q.check(S.onScreen(w:getX(), w:getY(), w:getWidth(), w:getHeight()), "notice: the Messages window is on screen") end
    RT.bounds(Q, "the Messages window")
    local ax, ay, nb = S.noteAx, S.noteAy, S.noteBox
    Q.check(nb ~= nil and ax ~= nil and ax >= nb.x and ax <= nb.x + nb.w and ay >= nb.y - 1 and ay <= nb.y + nb.h,
        "notice: Messages' balloons come out of the notice (ZeD.ErrorBox.anchor is a point on it)", tostring(ax) .. "," .. tostring(ay))
    S.putLamp()
    if S.msgStaged then pcall(function() ZeD.Messages.clear("ZeDQA rt_hud") end); S.msgStaged = nil end
end)
function S.putLamp()
    if not S.back.lamp then return end
    S.back.lamp = nil
    if not S.msgWas then pcall(function() local w = ZeD.MessagesWindow.get(S.pn); if w and w:isReallyVisible() then w:close() end end) end
    if S.toastsWas then Z.Messages.toasts = S.toastsWas end
end
-- (Nov 23 2026: the corner fallback. The belt is put away by the game's Toggle UI flag alone (ISUIHandler.allUIVisible
-- false: the belt's own wanted() test, ZeD_BeltHUD:wanted), not ISUIHandler.toggleUI, so the rest of the UI still
-- draws and the notice can be read; driving, death and the tutorial are dearer to stage. A new note starts the corner
-- notice's few seconds. The flag is put back at once after, and by the put-back.)
Q.step(5, function()
    if S.lampSkip then return end
    if not (ISUIHandler and Z.ErrorBox and Z.ErrorBox.rect) then
        S.awaySkip = true
        Q.skip("notice: the corner fallback", "no ISUIHandler in this game to put the belt away")
        return
    end
    S.uiWas = ISUIHandler.allUIVisible
    S.back.away = true
    ISUIHandler.allUIVisible = false
    pcall(function() ZeD.Messages.add("ZeDQA rt_hud", "mods", { head = "QA", text = "a note for the notice's corner" }) end)
    S.msgStaged = true
end)
Q.waitFor(2, 120, function()
    if S.lampSkip or S.awaySkip then return true end
    local E = Z.ErrorBox
    local el = E._note
    local okR, rx, _, _, r4 = pcall(E.rect)
    return okR and r4 == false and el ~= nil and el:getIsVisible() and math.abs(el:getX() - rx) <= 1
end, function(ok)
    if S.lampSkip or S.awaySkip then return end
    local E = Z.ErrorBox
    local el = E._note
    local okR, rx, ry, _, r4 = pcall(E.rect)
    local x, y, w, h = 0, 0, 0, 0
    if el then x, y, w, h = el:getX(), el:getY(), el:getWidth(), el:getHeight() end
    -- (the bottom right corner: its right and bottom edges within its own size plus the game box's width of the screen's)
    local corner = el ~= nil and x + w >= S.sw - w - 100 - ZeD.T.px(10) - 2 and y + h >= S.sh - ZeD.T.px(10) - 2 and S.onScreen(x, y, w, h)
    Q.check(ok and okR and r4 == false and corner and el:getIsVisible(),
        "notice: with the belt away (the interface hidden), the Messages notice falls back to the screen's bottom right corner",
        string.format("%d,%d %dx%d on %dx%d", x, y, w, h, S.sw, S.sh) .. "; rect " .. tostring(rx) .. "," .. tostring(ry) .. " on the row " .. tostring(r4))
    S.putAway()
    if S.msgStaged then pcall(function() ZeD.Messages.clear("ZeDQA rt_hud") end); S.msgStaged = nil end
end)
function S.putAway()
    if not S.back.away then return end
    S.back.away = nil
    if ISUIHandler then ISUIHandler.allUIVisible = S.uiWas end
end

-- ===================================================================== the Simple belt
Q.step(5, function()
    S.beltStyle = S.opt(Z.Settings.lookStyleOption)
    S.back.beltStyle = true
    S.setOpt(Z.Settings.lookStyleOption, 2)
end)
Q.step(20, function()
    local hud = S.hud()
    if not Q.check(hud ~= nil and hud._drawn == true and Z.Belt.simple(), "Lite belt: Style Lite gives the simple belt (Z.Belt.simple())") then return end
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
    S.setOpt(Z.Settings.lookStyleOption, 1)
end)
Q.step(20, function()
    local hud = S.hud()
    Q.check(hud ~= nil and hud._strap ~= nil, "Lite belt: Style Full brings the strap back")
    S.putBeltStyle()
end)
function S.putBeltStyle()
    if not S.back.beltStyle then return end
    S.back.beltStyle = nil
    S.setOpt(Z.Settings.lookStyleOption, S.beltStyle or 1)
end

-- ===================================================================== watch, mini and full
Q.step(5, function()
    S.watch = { opt = S.opt(Z.Settings.watchPlaceOption), pop = S.p:getModData().ZeD_WatchPop, style = S.opt(Z.Settings.lookStyleOption) }
    S.back.watch = true
    -- (Nov 21 2026, QA: the watch on the belt is Full's. Lite keeps the worn watch in the corner, ZeD_Watch.lua W.beltMode
    -- (the director, Nov 18), and rt_lite checks that; this block runs on Full and S.putWatch puts the style back)
    S.setOpt(Z.Settings.lookStyleOption, 1)
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
    -- (Nov 18 2026, QA, the ledger: the light. A press on the mini's light, through the belt's own mouse handler; a
    -- watch whose mini has no light spot takes it on the watch's own light control, said so)
    local b = S.boxes("watch")[1]
    S.lit = nil
    if not (inst and b) then return end
    if not Z.Watch.hasLight(inst._def) then
        Q.skip("watch: the light", "this watch has no light: " .. tostring(S.watch.item and S.watch.item:getFullType()))
        return
    end
    local hx, hy = nil, nil
    for yy = 0, b.h - 1 do
        for xx = 0, b.w - 1 do
            if not hx and Z.WatchMini.hit(b.plate, xx, yy) == "light" then hx, hy = xx, yy end
        end
    end
    S.lit = { mini = hx ~= nil }
    if hx then S.hud():onMouseDown(b.x + hx, b.y + hy) else Z.Watch.act("light") end
end)
Q.step(5, function()
    if S.lit then
        local inst = Z.Watch.getInstance()
        local ms = Z.Watch.miniState(S.p, S.watch.item)
        Q.check(inst ~= nil and (inst._litUntil or 0) > getTimestampMs() and ms and ms.lit == true, "watch: its light comes on",
            S.lit.mini and "pressed on the mini" or "no light spot on the mini: the watch's own light control")
    end
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
    S.setOpt(Z.Settings.lookStyleOption, w.style)
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
    -- (Nov 18 2026, QA, the ledger: the count of the same actions queued, as RIPPING 4/12 reads)
    Q.check(st.qn == #(S.packed or {}) and (st.qi or -1) >= 0 and st.qi < st.qn, "action bar: the queue count reads the moves queued",
        "qi " .. tostring(st.qi) .. " of " .. tostring(st.qn) .. ", queued " .. #(S.packed or {}))
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
    S.setOpt(Z.Settings.lookStyleOption, S.abStyle or 1)
end
Q.step(5, function()
    S.abStyle = S.opt(Z.Settings.lookStyleOption)
    S.back.abStyle = true
    S.setOpt(Z.Settings.lookStyleOption, 2)
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
    if not Q.check(ok and AB.mode() == "simple" and L._drawMode == "simple" and L._lay.bar == "simple", "bar style: Style Lite draws the simple bar",
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
    S.setOpt(Z.Settings.lookStyleOption, 1)
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
-- a fresh machine's bubble armed: no flag file, no line in Messages, ZeD setup's balloons as asked (1 Off, 2 On), the
-- game's "Show the guide on startup" on, and the clock short (first showing after 1 s, up 3 s)
function S.guideArm(balloons)
    local G, M = Z.GuideBubble, Z.Messages
    M.sources[G.head()] = nil
    for i = #M.toasts, 1, -1 do if M.toasts[i].source == G.head() then table.remove(M.toasts, i) end end
    S.setOpt(Z.Settings.messagesToastOption, balloons)
    S.writeFile(S.GFILE, "")
    RT.core:setOptionShowSurvivalGuide(true)
    G.start()
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = 1000, 600000, 3600000, 3000
end
-- (Nov 22 2026, QA K1-15: the bubble is the first game's pointer to F1, so it shows with ZeD setup's balloons Off, the
-- default. Until beta 21c it was a plain balloon that ended at once with balloons Off, and this check turned balloons
-- On first, which hid that. So the bubble is watched with balloons Off first, then once more with them On. On
-- 2488ceead the Off check FAILS (the offer ends "off" with no bubble); on 0ebd56570 it PASSES. The On checks pass on
-- both.)
Q.step(5, function()
    local G, M = Z.GuideBubble, Z.Messages
    local core = RT.core
    local lines = S.readFile(S.GFILE)
    S.guide = { flag = lines and (table.concat(lines, "\n") .. ((#lines > 0) and "\n" or "")) or nil,
        FIRST = G.FIRST_MS, EVERY = G.EVERY_MS, HOUR = G.HOUR_MS, SHOW = G.SHOW_MS, st = G.st,
        show = core:getOptionShowSurvivalGuide(), toastOpt = S.opt(Z.Settings.messagesToastOption), src = M.sources[G.head()] }
    S.back.guide = true
    S.guideArm(1)
    Q.check(G.st ~= nil, "guide: a fresh machine arms the bubble")
end)
Q.waitFor(1, 900, function() return S.guideToast() ~= nil end, function(ok)
    local t = S.guideToast()
    local on = Z.Settings.messagesToastOn()
    local st = Z.GuideBubble.st
    if not Q.check(ok and t ~= nil and not on, "guide: with balloons Off, ZeD setup's default, the bubble still comes out (QA K1-15)",
        "balloons " .. (on and "On" or "Off") .. ", the offer " .. tostring(st and st.done and ("ended: " .. tostring(st.why)) or "open")) then return end
    Q.check(t.text == Z.GuideBubble.text(0), "guide: the guide's own words", t.text)
    Q.check(t.bare and t.long and (t.pn or 0) == 0, "guide: a long bare balloon for player one")
end)
Q.step(10, function()
    if not S.guideToast() then return end
    -- (Nov 22 2026: the balloons come out of the Messages notice in the screen's corner, ZeD.ErrorBox.anchor; it shows
    -- while a balloon is up. Nov 23 2026, Build's fix/beltrow2: the notice stands on the belt row while the belt draws,
    -- the corner only while the belt is away; the check follows its place, ZeD.ErrorBox.rect(), wherever that is.)
    local E = Z.ErrorBox
    local ax, ay = nil, nil
    if E and E.anchor then ax, ay = E.anchor(S.pn) end
    local el = E and E._note
    local rx, r4 = nil, nil
    if E and E.rect then
        local okR, x1, _, _, o4 = pcall(E.rect)
        if okR then rx, r4 = x1, o4 end
    end
    local on = el ~= nil and ax ~= nil and ax >= el:getX() and ax <= el:getX() + el:getWidth() and ay >= el:getY() - 1 and ay <= el:getY() + el:getHeight()
        and rx ~= nil and math.abs(el:getX() - rx) <= 1
    Q.check(on, "guide: it comes out of the Messages notice where it stands (on the belt row while the belt draws, else the screen's corner)",
        tostring(ax) .. "," .. tostring(ay) .. "; the notice's place x " .. tostring(rx) .. ", on the row " .. tostring(r4))
    RT.bounds(Q, "guide bubble")
end)
Q.waitFor(1, 900, function() return S.guideToast() == nil end, function(ok)
    Q.check(ok, "guide: the bubble goes by itself")
    Q.check(Z.GuideBubble.lineKept(), "guide: its line stays in Messages")
    -- the same fresh machine with balloons On, as this check ran before K1-15
    S.guideArm(2)
end)
Q.waitFor(1, 900, function() return S.guideToast() ~= nil end, function(ok)
    Q.check(ok and Z.Settings.messagesToastOn(), "guide: with balloons On the bubble comes out too")
end)
Q.waitFor(1, 900, function() return S.guideToast() == nil end, function(ok)
    Q.check(ok, "guide: with balloons On it goes by itself too")
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
-- (Nov 18 2026, the director: "The hand should be pointing at things that aren't pinned yet." Build's 1e5e438e6:
-- a spotted find (any pin) has an empty pointer; the hand shows only while a find in sight is not spotted yet. The
-- game spots a find in sight after its spot timer; "unspotted" stops that timer for this one test find so it stays
-- in sight and unspotted, the state a player sees for a moment.)
function S.F.hold(o) o.updateSpotTimer = function() end end
function S.F.mk(dx, dy, unspotted, tag)
    local F = S.F
    local sq = getCell():getGridSquare(F.px + dx, F.py + dy, F.pz)
    if not (sq and F.ty) then return nil end
    local id = "zedqa_rthud_find" .. (tag or "")
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
    if unspotted then F.hold(o) else o:spotIcon() end
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
-- (Nov 18 2026, QA, the director in play: "most of them are the vanilla arrows, and I only saw a few of the hands".
-- The game's ISWorldItemIcon (a thing lying on the ground, found by searching), ISStashIcon and ISWorldItemIconTrack
-- (an animal track) each place their pointer with their own setWorldMarkerPosition, which ZeD's ISBaseIcon wrap
-- never reached; the staged ISForageIcon above passed all along. So a real thing is laid on the ground and its find
-- is made as ISSearchManager makes one (createIconsForWorldItems, then loadIcons' own steps); a track is made with
-- the game's track class on a thing on the ground the same way (an animal's real track needs an animal).)
S.F.ground = {}
function S.F.lay(dx, dy, ft)
    local F = S.F
    local sq = getCell():getGridSquare(F.px + dx, F.py + dy, F.pz)
    if not sq then return nil end
    local it = nil
    pcall(function() it = instanceItem(ft) end)
    if not it then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    local okA = pcall(function() sq:AddWorldInventoryItem(it, 0.5, 0.5, 0) end)
    local wi = nil
    pcall(function() wi = it:getWorldItem() end)
    if not (okA and wi) then return nil end
    F.ground[#F.ground + 1] = { sq = sq, it = it }
    return sq, it, wi
end
function S.F.mkGround(dx, dy, track, unspotted)
    local F = S.F
    local sq, it, wi = F.lay(dx, dy, "Base.Pencil")
    if not sq then return nil, "no thing could be laid on the ground" end
    local id = tostring(sq) .. "-" .. it:getFullType()
    local icon = nil
    if not track then
        pcall(function() F.mgr:createIconsForWorldItems(sq) end)
        icon = F.mgr.worldIconStack and F.mgr.worldIconStack[id]
        if F.mgr.worldIconStack then F.mgr.worldIconStack[id] = nil end
    else
        id = "zedqa_rthud_track"
    end
    if not icon then
        icon = { id = id, x = wi:getWorldPosX(), y = wi:getWorldPosY(), z = wi:getWorldPosZ(), itemObj = it, itemObjTable = {},
            itemType = it:getFullType(), isBonusIcon = false, isTrack = track and true or false }
        icon.itemObjTable[it] = it
    end
    local o = nil
    local okN, err = pcall(function()
        if track then o = ISWorldItemIconTrack:new(F.mgr, icon) else o = ISWorldItemIcon:new(F.mgr, icon) end
    end)
    if not (okN and o) then return nil, tostring(err) end
    o.iconClass = "worldObject"
    o:findTextureCenter()
    F.mgr.worldObjectIcons[o.iconID] = o
    o:doUpdateEvents(true)
    o:addToUIManager()
    if unspotted then F.hold(o) else o:spotIcon() end
    F.icons[#F.icons + 1] = o
    return o
end
-- the hand on a find's pointer: the same reading as the forage pointer checks above (the hand for its side, at its set size)
-- (Nov 18 2026, the director: the hand smaller and a little see-through, 36 x 63 at 0.75; ForagePins exposes it as
-- ISBaseIcon._zedHandSize = { w, h, alpha }, read here so the check follows the mod, not a copied number)
function S.handSize()
    local z = ISBaseIcon and ISBaseIcon._zedHandSize
    if type(z) == "table" and z[1] then return z[1], z[2], z[3] or 1 end
    return 36, 63, 0.75
end
function S.F.handCheck(o, why, what)
    local F = S.F
    if not o then Q.check(false, what, "not staged: " .. tostring(why)); return end
    local r = F.mark(o)
    local mg = F.mgr or {}
    local d = "no pointer up (seen " .. tostring(o.isSeenThisUpdate) .. ", forageable " .. tostring(o.isForageable)
        .. ", distance " .. string.format("%.4f", o.distanceToPlayer or -1)
        .. ", radius " .. tostring(mg.radius) .. ", darkness capped " .. tostring(o.isDarknessCapped)
        .. ", view distance " .. tostring(o.viewDistance) .. ", disable tick " .. tostring(mg.disableTick) .. ")"
    if r then
        d = tostring(r.hand) .. ", " .. math.floor((r.w or 0) + 0.5) .. " x " .. math.floor((r.h or 0) + 0.5)
    else
        -- (Nov 18 2026, Build: what the marker also needs, ISBaseIcon:updateWorldMarker: isNearby(), and the update
        -- itself. Called once here by hand; if that raises the marker while the game's own update did not, it says so.)
        local near, direct = "?", "?"
        local live, valid, seenNow, removing, cls, wiNow = "?", "?", "?", "?", "?", "?"
        pcall(function() near = tostring(o:isNearby()) end)
        pcall(function() live = tostring(o:checkIsForageable()) end)
        pcall(function() valid = tostring(o:isValid()) end)
        pcall(function() seenNow = tostring(o:getIsSeenThisUpdate()) end)
        pcall(function() removing = tostring(o.isBeingRemoved) end)
        pcall(function() cls = tostring(o.iconClass) end)
        pcall(function() wiNow = tostring(o.itemObj ~= nil and o.itemObj:getWorldItem() ~= nil) end)
        -- (Build: o:update() recomputes isSeenThisUpdate and calls updateWorldMarker itself, a fair direct test)
        local okU, errU = pcall(function() o:update(); direct = tostring(o.worldMarker ~= nil) end)
        if not okU then direct = "error: " .. tostring(errU) end
        local okW, errW = pcall(function() o:updateWorldMarker() end)
        direct = direct .. "; updateWorldMarker " .. (okW and "ran" or ("error: " .. tostring(errW))) .. ", marker " .. tostring(o.worldMarker ~= nil)
        local r2 = F.mark(o)
        d = d .. ", nearby " .. near .. ", checkIsForageable " .. live .. ", isValid " .. valid .. ", seen this update " .. seenNow
            .. ", being removed " .. removing .. ", class " .. cls .. ", its item in the world " .. wiNow
            .. ", a direct update raises it " .. direct
            .. (r2 and (" (" .. tostring(r2.hand) .. ")") or "")
        -- what stands on the squares between the character and the find
        local seen = {}
        pcall(function()
            local px, py, pz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
            local fx, fy = math.floor(o.xCoord), math.floor(o.yCoord)
            local n = math.max(math.abs(fx - px), math.abs(fy - py))
            for k = 1, n do
                local sx = px + math.floor((fx - px) * k / n + 0.5)
                local sy = py + math.floor((fy - py) * k / n + 0.5)
                local sq = getCell():getGridSquare(sx, sy, pz)
                local names = {}
                if sq then
                    local objs = sq:getObjects()
                    for i = 0, objs:size() - 1 do
                        local ob = objs:get(i)
                        local nm = "?"
                        pcall(function() nm = ob:getSprite() and ob:getSprite():getName() or ob:getObjectName() end)
                        names[#names + 1] = tostring(nm)
                    end
                end
                seen[#seen + 1] = sx .. "," .. sy .. "=" .. ((#names > 0) and table.concat(names, "+") or "empty")
            end
        end)
        d = d .. ", between: " .. table.concat(seen, " ")
    end
    local hw, hh = S.handSize()
    Q.check(r ~= nil and r.hand == F.want(F.side(o)) and math.floor((r.w or 0) + 0.5) == hw and math.floor((r.h or 0) + 0.5) == hh,
        what, d)
end
-- (Nov 18 2026, run r7: the ground find's pointer passed in r6 and failed in r7 with no code change. The game raises a
-- find's pointer only in range for its update (ISBaseIcon:isInRangeForUpdate: within manager.radius and not darkness
-- capped, or within viewDistance), and both follow the light (forageSystem.getLightLevelPenalty reads the square's
-- light and ClimateManager:getDayLightStrength). So beside noon the sky is pinned clear through the climate's own
-- overrides (fog, cloud and rain none, daylight full), the way the game's debug scenarios clear fog; each override
-- goes back as it was in S.putForage. stopWeatherAndThunder is not used: it cannot be put back.)
function S.F.clearSky()
    local F = S.F
    F.sky = {}
    local cm = nil
    pcall(function() cm = getClimateManager() end)
    if not cm then return end
    local want = {
        { k = "FLOAT_FOG_INTENSITY", v = 0 }, { k = "FLOAT_CLOUD_INTENSITY", v = 0 },
        { k = "FLOAT_PRECIPITATION_INTENSITY", v = 0 }, { k = "FLOAT_DAYLIGHT_STRENGTH", v = 1 },
    }
    for _, w in ipairs(want) do
        pcall(function()
            local idx = ClimateManager[w.k]
            local cf = idx and cm:getClimateFloat(idx)
            if not cf then return end
            local e = { cf = cf, on = cf:isEnableOverride(), val = cf:getOverride(), interp = cf:getOverrideInterpolate() }
            cf:setEnableOverride(true)
            cf:setOverride(w.v, 1)
            F.sky[#F.sky + 1] = e
        end)
    end
end
function S.F.putSky()
    local F = S.F
    for _, e in ipairs(F.sky or {}) do
        pcall(function()
            if e.val ~= nil then e.cf:setOverride(e.val, e.interp or 0) end
            e.cf:setEnableOverride(e.on == true)
        end)
    end
    F.sky = {}
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
    F.clearSky()
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
-- (Nov 18 2026, run r8: the squares by the home held WorldInventoryItems left by earlier runs; createIconsForWorldItems
-- keys its icon by square and type, so the find could be tied to an old pencil, isValid false, and no pointer. Only
-- things the tests marked ZeDQA_spawned are taken, within 4 tiles of the home.)
function S.F.clearStray()
    local F = S.F
    local n = 0
    for dx = -4, 4 do
        for dy = -4, 4 do
            local sq = getCell():getGridSquare(F.px + dx, F.py + dy, F.pz)
            if sq then
                local objs = nil
                pcall(function() objs = sq:getWorldObjects() end)
                if objs then
                    for i = objs:size() - 1, 0, -1 do
                        local wi = objs:get(i)
                        local mine = false
                        pcall(function() mine = wi:getItem():getModData().ZeDQA_spawned == true end)
                        if mine then
                            pcall(function() sq:transmitRemoveItemFromSquare(wi) end)
                            pcall(function() wi:removeFromWorld() end)
                            n = n + 1
                        end
                    end
                end
            end
        end
    end
    Q.say("NOTE forage: " .. n .. " things earlier runs left on the ground by the home taken away")
end
Q.step(30, function()
    local F = S.F
    F.clearStray()
end)
Q.step(10, function()
    local F = S.F
    F.one = F.mk(3, -1)                     -- spotted: its pin shows, its pointer is empty
    F.raw = F.mk(3, 1, true, "_raw")         -- in sight, not spotted yet: the hand
    local okG, okT
    okG, F.gnd, F.gndWhy = pcall(F.mkGround, 2, 0, false, true)   -- (Build: 2 tiles, well inside the radius; at 3 the float distance sat on its edge)
    if not okG then F.gndWhy, F.gnd = F.gnd, nil end
    okT, F.trk, F.trkWhy = pcall(F.mkGround, 2, -1, true, true)
    if not okT then F.trkWhy, F.trk = F.trk, nil end
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
    local r1 = F.mark(o)
    Q.check(r1 ~= nil and r1.hand == "zed_forage_hand_none", "forage: a pinned find's pointer is empty (its pin marks it)", tostring(r1 and r1.hand))
    local u = F.raw
    local r = u and F.mark(u)
    if Q.check(r ~= nil, "forage: the pointer to the find is up", "a find in sight, not spotted yet: " .. tostring(u ~= nil)) then
        Q.check(r.hand == F.want(F.side(u)), "forage: the pointer is ZeD's hand for the find's side", tostring(r.hand))
        local hw, hh, ha = S.handSize()
        Q.check(math.floor((r.w or 0) + 0.5) == hw and math.floor((r.h or 0) + 0.5) == hh, "forage: the hand is its set size", math.floor((r.w or 0) + 0.5) .. " x " .. math.floor((r.h or 0) + 0.5) .. ", want " .. hw .. " x " .. hh)
        Q.check(math.abs((r.r or 0) - 1) < 0.01 and math.abs((r.a or 0) - ha) < 0.01, "forage: white at its set alpha", "alpha " .. tostring(r.a) .. ", want " .. ha)
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
    F.handCheck(F.gnd, F.gndWhy, "forage pointer: a find on the ground shows ZeD's hand")
    -- (the game gives a stash no pointer: ISBaseIcon:updateWorldMarker adds one only for iconClass "forageIcon" or
    -- "worldObject", and ISSearchManager makes every stash "stashObject"; ZeD's ISStashIcon wrap is only a guard)
    Q.skip("forage pointer: a stash find shows ZeD's hand", "the game draws no pointer to a stash (ISBaseIcon:updateWorldMarker skips iconClass stashObject)")
    F.handCheck(F.trk, F.trkWhy, "forage pointer: an animal track shows ZeD's hand")
    RT.bounds(Q, "forage")
    S.putForage()
end)
Q.step(20, function()
    local left = 0
    for _, o in ipairs(S.F.icons) do if o.worldMarker then left = left + 1 end end
    Q.check(left == 0, "forage: the find and its pointer are gone again")
end)
-- (Nov 18 2026, QA, the ledger: the World window's Foraging tab, its band's Search button through the tab's own click
-- handler, flips the game's search mode; a second press flips it back)
-- (Nov 18 2026, QA, run r5: a same-step race: the pair was just opened, and the strip fills its hit zones only when
-- it draws. So the press waits for the strip to list the Foraging tab.)
Q.step(5, function()
    RT.pairOpen()
    S.fsSkip = nil
end)
Q.waitFor(2, 300, function()
    for _, id in ipairs(RT.tabs(RT.worldStrip())) do if id == "forage" then return true end end
    return false
end, function(ok)
    local pressed = ok and RT.worldTab("forage")
    if not Q.check(pressed, "forage tab: the World window's Foraging tab opens from the strip", (not pressed) and (ok and "the press found no tab" or "the strip never listed it") or nil) then S.fsSkip = true end
end)
Q.waitFor(5, 300, function() local w = RT.ww(); return S.fsSkip or (w ~= nil and w._forageSearchBtn ~= nil) end, function(ok)
    if S.fsSkip then return end
    if not Q.check(ok, "forage tab: the band draws its Search button") then S.fsSkip = true; return end
    local w = RT.ww()
    S.fsMgr = ISSearchManager.getManager(S.p)
    S.fsWas = S.fsMgr.isSearchMode == true
    local b = w._forageSearchBtn
    ZeD.ForagingTab.onClick(w, b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2))
end)
Q.step(10, function()
    if S.fsSkip then return end
    Q.check((S.fsMgr.isSearchMode == true) ~= S.fsWas, "forage tab: a click on Search flips the game's search mode", tostring(S.fsMgr.isSearchMode))
    local w = RT.ww()
    local b = w and w._forageSearchBtn
    if b then ZeD.ForagingTab.onClick(w, b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)) end
end)
Q.step(10, function()
    if S.fsSkip then RT.pairShut(); return end
    Q.check((S.fsMgr.isSearchMode == true) == S.fsWas, "forage tab: a second click puts search mode back")
    if (S.fsMgr.isSearchMode == true) ~= S.fsWas then pcall(function() S.fsMgr:toggleSearchMode(S.fsWas) end) end
    RT.worldTab("loot")
    RT.pairShut()
end)
function S.putForage()
    if not S.back.forage then return end
    S.back.forage = nil
    local F = S.F
    for _, o in ipairs(F.icons) do F.drop(o) end
    -- the things laid on the ground for the finds there, taken up again (and any find the game made of them since)
    for _, g in ipairs(F.ground) do
        pcall(function()
            local wi = g.it:getWorldItem()
            if wi then
                g.sq:transmitRemoveItemFromSquare(wi)
                if g.it:getWorldItem() then wi:removeFromWorld(); wi:removeFromSquare(); wi:setSquare(nil) end
            end
        end)
        pcall(function()
            local id = tostring(g.sq) .. "-" .. g.it:getFullType()
            if F.mgr.worldIconStack then F.mgr.worldIconStack[id] = nil end
            local o = F.mgr.worldObjectIcons[id]
            if o then F.drop(o) end
        end)
    end
    F.ground = {}
    pcall(function() getGameTime():setTimeOfDay(F.tod) end)
    F.putSky()
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
-- (Nov 22 2026, KISS #41, the director's pick: moves between bags go while paused and run on play, as the game's drag
-- does. The glass now lies over the open tab's page only and takes its presses; the item list gets a veil the mouse
-- goes through (PL._glassList, its line "moves between bags wait for play"). Until K3 (0b366177e) one glass covered
-- the page and the list and ate every press, and these checks read that. Skills is opened first, so there is a page.)
Q.waitFor(5, 300, function() local w = RT.cw(); return w ~= nil and w:isReallyVisible() and w._mainContent ~= nil end, function(ok)
    if not Q.check(ok, "paused: the Character window is open") then S.plSkip = true; return end
    S.plTab = RT.cw()._activeTab
    RT.charTab("skills")
end)
Q.waitFor(2, 120, function() local w = RT.cw(); return S.plSkip or (w ~= nil and w._activeTab == "skills" and w._drawerOpen == true and w._drawerPanel ~= nil) end, function(ok)
    if S.plSkip then return end
    if not Q.check(ok, "paused: the Skills page is open for the glass") then S.plSkip = true; return end
    S.pause(true)
end)
function S.inside(g, panel)
    if not (g and panel) then return false end
    local gx, gy, gw, gh = g:getAbsoluteX(), g:getAbsoluteY(), g:getWidth(), g:getHeight()
    local mx, my = panel:getAbsoluteX() + math.floor(panel:getWidth() / 2), panel:getAbsoluteY() + math.floor(panel:getHeight() / 2)
    return mx >= gx and mx < gx + gw and my >= gy and my < gy + gh
end
Q.step(10, function()
    if S.plSkip then return end
    local PL = Z.PausedLook
    local w = RT.cw()
    local g, v = PL._glass, PL._glassList
    Q.check(PL.on(), "paused: the game reads paused")
    if Q.check(g ~= nil and g.win == w and g:isVisible(), "paused: the glass lies on the Character window's open page") then
        Q.check(S.inside(g, w._drawerPanel), "paused: the glass covers the tab's page")
        Q.check(g:onMouseDown(10, 10) == true and g:onRightMouseDown(10, 10) == true, "paused: the glass takes a press and a right press (nothing on the page is used)")
    end
    if Q.check(v ~= nil and v.win == w and v:isVisible(), "paused: a veil lies on the item list (KISS #41)") then
        Q.check(S.inside(v, w._mainContent), "paused: the veil covers the item list")
        Q.check(v:onMouseDown(10, 10) ~= true and v:onRightMouseDown(10, 10) ~= true and not (g ~= nil and S.inside(g, w._mainContent)),
            "paused: the veil lets a press through to the list, so a move between bags still goes (KISS #41)")
    end
    local F = ZeD.Input and ZeD.Input.Focus
    local fz = F and F.liveZone and F.liveZone(w)
    local free = (fz and S.FREE[fz.zone]) and true or false
    Q.check(PL.blocks(w) == (not free), "paused: the pad's A and X are held outside the tab strip and the bags", fz and fz.zone or "no live zone")
    RT.bounds(Q, "paused Character window")
    S.plAlt = nil
    for _, id in ipairs(RT.tabs(RT.charStrip())) do if not S.plAlt and id ~= "skills" and id ~= "loot" then S.plAlt = id end end
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
    local g, v = Z.PausedLook._glass, Z.PausedLook._glassList
    Q.check(not (g and g:isVisible()) and not (v and v:isVisible()) and not Z.PausedLook.blocks(RT.cw()), "paused: playing again, the glass is gone (and the list's veil)")
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
end)

-- ===================================================================== pin items; a fourth pin
-- (Nov 18 2026, QA, the ledger: the first item pinned from the game's own item menu (ZeD's Pin to title bar, added on
-- OnFillInventoryObjectContextMenu), three more by the same pick (ZeD.Pins.toggle); the pins start empty for it and
-- the character's own are put back after)
function S.ctxOpt(name)
    local c = S.ctx()
    local o = nil
    if c then pcall(function() o = c:getOptionFromName(name) end) end
    return o
end
Q.step(5, function()
    S.closeMenu()
    if not S.back.pin then S.pin = { had = S.p:getModData().ZeD_Pins ~= nil, list = {} }; S.back.pin = true end
    S.p:getModData().ZeD_Pins = {}
    S.pinItems = {}
    for _, ft in ipairs({ "Base.Hammer", "Base.Crowbar", "Base.BaseballBat", "Base.Axe" }) do
        local it = RT.give(ft)
        if it and Z.Pins.kindOf(it) then S.pinItems[#S.pinItems + 1] = it end
    end
    if not Q.check(#S.pinItems == 4, "pin item: four pinnable things to pin", #S.pinItems .. " of 4") then S.pinItemSkip = true; return end
    pcall(function() ISInventoryPaneContextMenu.createMenu(S.pn, true, { S.pinItems[1] }, 200, 200) end)
end)
Q.waitFor(2, 120, function() return S.pinItemSkip or S.ctxOpt(ZeD.tr("UI_ZeD_Pin_Pin")) ~= nil end, function(ok)
    if S.pinItemSkip then return end
    local opt = S.ctxOpt(ZeD.tr("UI_ZeD_Pin_Pin"))
    if not Q.check(ok and opt ~= nil and opt.onSelect ~= nil, "pin item: the item's own menu offers Pin to title bar") then S.pinItemSkip = true; S.closeMenu(); return end
    opt.onSelect(opt.target)
    S.closeMenu()
end)
Q.step(10, function()
    if S.pinItemSkip then return end
    local it = S.pinItems[1]
    local e = (S.p:getModData().ZeD_Pins or {})[1]
    Q.check(e ~= nil and e.k == Z.Pins.kindOf(it) and tostring(e.id) == tostring(it:getID()), "pin item: the pick puts the item's kind and id in ZeD_Pins",
        e and (tostring(e.k) .. " " .. tostring(e.id)) or "none")
    local rows = Z.Pins.stats(S.p) or {}
    Q.check(#rows == 1 and tostring(rows[1].text or "") ~= "", "pin item: ZeD.Pins.stats gives its row", rows[1] and rows[1].text)
    local w = RT.cw()
    local name = tostring(it:getDisplayName()):sub(1, 4)
    local seen, all = false, {}
    for _, st in ipairs((w and w.titleStats) or {}) do
        local t = tostring(st.text or "")
        all[#all + 1] = t
        if t:find(name, 1, true) then seen = true end
    end
    Q.check(seen, "pin item: the Character window's title bar shows it", name .. " in: " .. table.concat(all, " | "))
    for i = 2, 4 do
        local o = S.pinItems[i]
        pcall(Z.Pins.toggle, S.p, Z.Pins.kindOf(o), o:getID(), o:getDisplayName())
    end
end)
Q.step(5, function()
    if S.pinItemSkip then S.putPins(); return end
    local L = S.p:getModData().ZeD_Pins or {}
    local first, last = S.pinItems[1], S.pinItems[4]
    Q.check(#L == Z.Pins.MAX and Z.Pins.MAX == 3 and not Z.Pins.isPinned(S.p, Z.Pins.kindOf(first), first:getID()),
        "pins: a fourth pin takes off the oldest (three at most)", #L .. " pins")
    local want = Z.Bubbles.clean(ZeD.tr("UI_ZeD_Pin_Replaced", last:getDisplayName(), first:getDisplayName(), Z.Pins.MAX))
    local seen = false
    for _, n in ipairs(Z.Bubbles._notes[S.pn] or {}) do if n.text == want then seen = true end end
    Q.check(seen, "pins: a note over the head says which pin went", want)
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

-- ===================================================================== the run button also crouches (ZeD setup, off by default)
-- (Nov 18 2026, QA, the ledger: Input/RunSneak.lua's own QA hook stands in for the pad, RS.qaInput: Run held 400 ms
-- standing still crouches, held again stands. It means something only where the game's Run is a button or a trigger.)
function S.putRs()
    if not S.back.rs then return end
    S.back.rs = nil
    local RS = ZeD.Input and ZeD.Input.RunSneak
    if RS then pcall(RS.qaInput, S.pn, nil) end
    S.setOpt(Z.Settings.runSneakOption, S.rs.opt or 1)
    pcall(function() S.p:setSneaking(S.rs.sneak) end)
end
function S.rsHold(on) local RS = ZeD.Input.RunSneak; pcall(RS.qaInput, S.pn, { held = on, moving = false, pad = true }) end
Q.step(5, function()
    local RS = ZeD.Input and ZeD.Input.RunSneak
    if not Q.check(RS ~= nil and RS.qaInput ~= nil and Z.Settings.runSneakOption ~= nil, "run-sneak: the module and its setting are loaded") then S.rsSkip = true; return end
    local kind = RS.runBindingKind()
    if kind ~= "button" and kind ~= "trigger" then
        S.rsSkip = true
        Q.skip("run-sneak: Run held crouches", "the game's Run is on " .. tostring(kind) .. " in this layout, where a hold means nothing")
        return
    end
    S.rs = { opt = S.opt(Z.Settings.runSneakOption), sneak = S.p:isSneaking() }
    S.back.rs = true
    pcall(function() S.p:setSneaking(false) end)
    S.setOpt(Z.Settings.runSneakOption, 2)
    S.rsHold(false)
end)
Q.step(10, function() if not S.rsSkip then S.rsHold(true) end end)
Q.waitMs(700)
Q.step(1, function()
    if S.rsSkip then return end
    local act = ZeD.Input.RunSneak.lastAction(S.pn)
    Q.check(act == "crouch" and S.p:isSneaking(), "run-sneak: Run held 400 ms standing still crouches", tostring(act))
    S.rsHold(false)
end)
Q.step(10, function() if not S.rsSkip then S.rsHold(true) end end)
Q.waitMs(700)
Q.step(1, function()
    if S.rsSkip then return end
    local act = ZeD.Input.RunSneak.lastAction(S.pn)
    Q.check(act == "stand" and not S.p:isSneaking(), "run-sneak: held again, it stands", tostring(act))
    S.putRs()
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    pcall(function() S.p:StopAllActionQueue() end)
    if S.paused then S.pause(false) end
    S.putRs(); S.putLamp(); S.putAway()
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
