-- ZeDUI/tools/qa/zedqa_b19_old_b.lua  (Nov 16 2026, QA): punch list items built in beta 14 and never checked in the
-- running game, each through the fix's own code on the real windows. Run on the QA save at the drag strip
-- (925,13040); nothing here walks to or enters a vehicle.
-- No controller is plugged into the QA PC: a stand-in pad record goes into JoypadState.players for the length of one
-- call only (withPad) and comes out again before the next frame. A and Y presses go through ZeD's FocusManager poll
-- with QA's button hook (Focus.qaButton), the pad's mode locked on. What needs a real held button is said "not run".
--   189   Put things back on: a T-shirt in a placed crate, the item card's Wear (its real dispatch): once the queue is
--         done the shirt is still worn and on the character, not taken off and put back in the crate.
--   195   a baseball bat's card open on the pad (a food card has no footer): on the card's top button with the card at
--         its top, Up goes to the footer's verbs (Repair).
--   199   a Knox Knews paper not yet read (Journal > Papers, its quick look): A on Read queues the game's read action
--         (noon set for the light; the read is cancelled at once so the paper stays unread).
--   203   Furniture tab, Pick up: the cursor's target moved off the character; Y (the game hands it to the cursor)
--         leaves the target where it was.
--   207   a radio placed beside the character: (a) Down along the World window's side tab strip reaches the Radio tab;
--         (b) on the Radio tab, Up from the face's top control reaches the radio's tab in the header.
--   (208 and 209 need power: a generator placed beside the oven, switched on; without power the oven has no
--   controls and the game will not turn it on, so they are said "not run")
--   208   Turn on from the oven's right-click menu (the game's onToggleStove route): when the action ends the oven
--         opens (the Craft tab on it, or its face popped out); Turn off from the menu opens nothing.
--   209   the oven's pop-out: Up / Down / Left / Right go to the control that lies that way (every control, every
--         direction); a knob grabbed and turned 30 steps past its end keeps the pad and the window; B lets go of the
--         knob, B again closes the pop-out, and B closes it from a key too.
--   216   a TV and a radio beside the character: with the TV showing the Radio tab says Television with the TV picture;
--         with the radio showing it says Radio with the radio picture.
--   222   a raw pork chop on the character, held hot: its inventory row draws the Cooking word or the cooking bar.
--   224   the same chop in the oven, held switched on with no power or gas (before the generator): the Craft tab's
--         contents say Raw, not Cooking; held hot, they say Cooking. (ZeD panels draw through their own lean
--         drawText, so the words are caught on each panel of both windows, not on ISUIElement.)
--   225   a quick A on a raw pork chop's row opens its card and eats nothing; A again (card open) is the menu and eats
--         nothing; the card's Eat is a hold only; A held on an apple's row queues the eat (cancelled at once).
--   227b  the pad resting on a row (no card open) asks for the item's loot card after its short wait.
-- Pictures: Screenshots/zqa_b19b_*.png. Puts back: Put things back as found, the time of day, game speed, the pad's
-- mode, focus, the pad records and QA button holds, the draw hooks, every placed object (crate, oven, TV, radio, generator switched off first) and
-- every item given, cards and menus closed, the furniture cursor ended, both windows on Loot and open.
-- grep "ZEDQA b19b".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA b19b " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b19b_" .. n .. ".png") end) end
local Q = {}
-- a step's fn returning true runs again after n frames
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local Focus = ZeD.Input and ZeD.Input.Focus
local Det = ZeD.Input and ZeD.Input.Detector
local function CW() return ZeD_CharacterWindow.getWindow(pn) end
local function WW() return ZeD_WorldWindow.getWindow(pn) end
-- the run's state, and what it changes, kept to put back
local S = { placed = {}, added = {}, speed = getGameSpeed(), tod = getGameTime():getTimeOfDay() }

-- the stand-in pad: in JoypadState only for the call
local fake = { player = pn, focus = nil }
local function withPad(fn, ...)
    local real = JoypadState.players[pn + 1]
    if real then say("note: a real pad is bound; the stand-in is not used") return fn(...) end
    JoypadState.players[pn + 1] = fake
    local ok, r = pcall(fn, ...)
    JoypadState.players[pn + 1] = nil
    pcall(setPlayerButtonsActive, pn, true)
    pcall(setJoypadIgnoreAim, pn, false)
    if not ok then say("ERR " .. tostring(r)) end
    return r
end

-- small helpers, kept in S so the main chunk stays light on locals
function S.sq(dx, dy) return getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ())) end
function S.give(ft) local ok, it = pcall(function() return p:getInventory():AddItem(ft) end); if ok and it then S.added[#S.added + 1] = it; return it end; return nil end
function S.keep(o) if o then S.placed[#S.placed + 1] = o end; return o end
function S.queue()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local t = {}
    if q and q.queue then for _, a in ipairs(q.queue) do t[#t + 1] = tostring(a.Type) end end
    return t
end
function S.queueHas(pat) for _, t in ipairs(S.queue()) do if t:find(pat, 1, true) then return true end end; return false end
function S.stopAll() pcall(function() ISTimedActionQueue.clear(p) end); pcall(function() p:StopAllActionQueue() end) end
function S.fid(w) local e = w and Focus.getFocusedElement(w); return e and e.id end
-- focus the first stop pred(el, zoneName) takes, in any focusable zone of w
function S.focusAny(w, pred)
    if not w then return nil end
    pcall(Focus.flatElements, w)
    local names = {}
    for _, z in ipairs(w._focusRing or {}) do names[#names + 1] = z.zone end
    for _, n in ipairs(names) do
        local e = Focus.focusWhere(w, n, function(x) return pred(x, n) end)
        if e then return e end
    end
    return nil
end
function S.rowFocus(item)
    local w = CW()
    pcall(Focus.flatElements, w)
    return Focus.focusWhere(w, "charMainInv", function(x) return x.item == item or x.rep == item end)
end
-- the Character window's card on item (nil: closed), as a pick in its list
function S.pick(item)
    local w = CW()
    local sel = w._mainContent._selectedItems
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    w._updateDrawer(w._mainContent)
end
function S.claim(w) withPad(function() Focus.claimFocus(w); fake.focus = w end) end
function S.closeMenus()
    pcall(function() local m = getPlayerContextMenu(pn); if m and m.closeAll then m:closeAll() end end)
    pcall(function()
        local ui = UIManager.getUI()
        for i = ui:size() - 1, 0, -1 do
            local t = ui:get(i):getTable()
            if t and (t.Type == "ZeD_ContextMenu" or t.Type == "ZeD_ContextList") and t:isVisible() then t:close() end
        end
    end)
end
-- an A press through ZeD's poll: down (the window's dispatch), held hold frames, up, handed back
local function pressA(win, hold, after)
    step(2, function()
        local w = win()
        if not w then return end
        withPad(function() Focus.dispatchJoypadDown(w, Joypad.AButton, fake) end)
        Focus.qaButton("A", true, pn)
    end)
    step(hold, function() if after then after() end; Focus.qaButton("A", false, pn) end)
    step(3, function() Focus.qaButton("A", nil, pn) end)
end
-- what the draw passes write: words looked for (lower case) and the cooking bar's thin accent rects.
-- (Nov 16 2026, round 2: ZeD's classes carry their own lean drawText / drawRect (Overrides/TextScale.lua, LEAN), so a
-- hook on ISUIElement never sees them. Each panel of both windows gets the hook on itself, put back after.)
function S.noteText(self, str)
    if type(str) ~= "string" or not S.capWords then return end
    local l = string.lower(str)
    for _, w in ipairs(S.capWords) do if not S.cap[w] and l:find(w, 1, true) then S.cap[w] = tostring(self.Type) end end
end
function S.noteRect(h, r, g, b)
    local T = ZeD.T
    local ac = T and T.accent
    if ac and S.capWords and h == T.px(2) and r == ac.r and g == ac.g and b == ac.b then S.capRects = S.capRects + 1 end
end
function S.hookEl(el)
    if type(el) ~= "table" or S.hooked[el] then return end
    local okT, rt = pcall(rawget, el, "drawText")
    local okR, rr = pcall(rawget, el, "drawRect")
    S.hooked[el] = { dt = okT and rt or nil, dr = okR and rr or nil }
    local odt, odr = el.drawText, el.drawRect
    if odt then el.drawText = function(self, str, ...) S.noteText(self, str); return odt(self, str, ...) end end
    if odr then el.drawRect = function(self, x, y, w, h, a, r, g, b) S.noteRect(h, r, g, b); return odr(self, x, y, w, h, a, r, g, b) end end
    for _, c in pairs(el.children or {}) do S.hookEl(c) end
end
function S.capStart(words)
    S.capWords, S.cap, S.capRects = {}, {}, 0
    for _, w in ipairs(words) do S.capWords[#S.capWords + 1] = string.lower(tostring(w)) end
    S.hooked = S.hooked or {}
    S.hookEl(CW()); S.hookEl(WW())
    if S.realDT then return end
    -- (and the game's own panels, through ISUIElement)
    S.realDT, S.realDR = ISUIElement.drawText, ISUIElement.drawRect
    ISUIElement.drawText = function(self, str, ...) S.noteText(self, str); return S.realDT(self, str, ...) end
    ISUIElement.drawRect = function(self, x, y, w, h, a, r, g, b) S.noteRect(h, r, g, b); return S.realDR(self, x, y, w, h, a, r, g, b) end
end
function S.capStop()
    if S.realDT then ISUIElement.drawText = S.realDT; ISUIElement.drawRect = S.realDR end
    for el, o in pairs(S.hooked or {}) do el.drawText = o.dt; el.drawRect = o.dr end
    S.hooked = {}
    S.realDT, S.realDR, S.capWords = nil, nil, nil
end
-- a food held hot each frame (its own heat is the game's test for cooking); an oven held on with no power (224)
S.heatFn = function()
    if S.hot then pcall(function() S.hot:setHeat(2.5) end) end
    if S.keepOn and S.oven then pcall(function() if not S.oven:Activated() then S.oven:setActivated(true) end end) end
end
Events.OnPreUIDraw.Add(S.heatFn)

-- ===================================================================== setup
step(20, function()
    say("start: pad bound " .. tostring(JoypadState.players[pn + 1] ~= nil) .. ", at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()))
    if not (Focus and Det and Focus.qaButton and Focus.dispatchJoypadDown) then say("ERR ZeD's pad code is not loaded"); return end
    if S.speed == 0 then setGameSpeed(1) end
    if not ZeD_CharacterWindow.isOpen(pn) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(function() Mouse.setXY(getCore():getScreenWidth() - 4, getCore():getScreenHeight() - 4) end)
    S.stopAll()
end)

-- ===================================================================== 189: Wear from a crate, with Put things back on
step(10, function()
    local PB, St = ZeD.PutBack, ZeD.Settings
    if not (PB and St and St.putBackOption) then say("not run: 189 (Put things back is not loaded)"); S.skip189 = true; return end
    S.pbWas = St.putBackOption:getValue()
    pcall(function() St.putBackOption:setValue(2) end)
    local sq = S.sq(0, -1)
    local ok, err = pcall(function()
        local crate = IsoThumpable.new(getCell(), sq, "carpentry_01_16", false, nil)
        crate:setIsContainer(true)
        crate:getContainer():setType("crate")
        sq:AddSpecialObject(crate)
        S.crate = S.keep(crate)
        S.shirt = crate:getContainer():AddItem("Base.Tshirt_DefaultTEXTURE_TINT")
    end)
    if not (ok and S.shirt) then say("not run: 189 (no crate or shirt: " .. tostring(err) .. ")"); S.skip189 = true; return end
    check(PB.on(), "189: Put things back is on")
    pcall(function() ISInventoryPage.dirtyUI() end)
end)
step(30, function()
    if S.skip189 then return end
    local c = ZeD_ItemCard:new(0, 0, 220, 300, "drawer", pn)
    c:initialise(); c.item = S.shirt; c.playerNum = pn; c.sourceContext = "loot"
    local ok, e = pcall(c._dispatchHeaderVerb, c, "EQUIP")
    say("189: the card's Wear dispatched (ok " .. tostring(ok) .. " " .. tostring(e) .. "); queue " .. table.concat(S.queue(), " > "))
    S.t, S.quiet, S.seen = 0, 0, {}
end)
step(2, function()
    if S.skip189 then return end
    S.t = S.t + 1
    local q = S.queue()
    for _, t in ipairs(q) do S.seen[t] = true end
    if #q == 0 then S.quiet = S.quiet + 1 else S.quiet = 0 end
    if S.quiet < 90 and S.t < 1500 then return true end
end)
step(5, function()
    if S.skip189 then return end
    local seen = {}
    for t in pairs(S.seen) do seen[#seen + 1] = t end
    say("189: actions seen " .. table.concat(seen, ", "))
    local worn = false
    pcall(function() worn = p:isEquippedClothing(S.shirt) end)
    local c = S.shirt:getContainer()
    check(worn, "189: the shirt worn from the crate stays on")
    check(c == p:getInventory(), "189: the shirt is on the character, not put back in the crate (in " .. tostring(c and c:getType()) .. ")")
    check(not S.seen["ISInventoryTransferAction"] or c == p:getInventory(), "189: no move back to the crate after the wear")
    shot("189_worn")
    pcall(function() ZeD.Settings.putBackOption:setValue(S.pbWas or 1) end)
    pcall(function() if p:isEquippedClothing(S.shirt) then p:removeWornItem(S.shirt) end end)
    pcall(function() local ct = S.shirt:getContainer(); if ct then ct:Remove(S.shirt) end end)
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
end)

-- ===================================================================== 199: A on a paper's Read
step(10, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    local id
    for i = 1, 9 do
        local key = "KnoxKnews_July" .. i
        if not id and getTextOrNull("Print_Media_" .. key .. "_title") and not p:isPrintMediaRead(string.lower(key)) then id = key end
    end
    if not id then say("not run: 199 (every Knox Knews July paper is read on this character)"); S.skip199 = true; return end
    S.paperId = string.lower(id)
    S.paper = S.give("Base.Newspaper")
    S.paper:getModData().printMedia = { id = S.paperId, title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" }
    S.paper:setName(getText("Print_Media_" .. id .. "_title"))
    getGameTime():setTimeOfDay(12)
    local w = CW()
    w._activeTab = "journal"; w._drawerMode = "tab"; w._drawerOpen = true
    w._journalSubTab = 3
    ZeD.JournalReaders.refresh(w)
    say("199: paper " .. id .. " (unread)")
end)
step(30, function() if not S.skip199 then CW()._jr.paperOpen = S.paperId end; S.t = 0 end)
step(10, function()
    if S.skip199 then return end
    S.t = S.t + 1
    if p:tooDarkToRead() and S.t < 30 then return true end
    if p:tooDarkToRead() then say("not run: 199 (too dark to read even at noon)"); S.skip199 = true; return end
    local w = CW()
    S.claim(w)
    local e = S.focusAny(w, function(x) return x.id == "jr:read" end)
    if not check(e ~= nil, "199: the quick look's Read is a pad stop") then S.skip199 = true; return end
    S.stopAll()
    shot("199_read_focus")
end)
pressA(function() if not S.skip199 then return CW() end end, 3)
step(2, function()
    if S.skip199 then return end
    local q = S.queue()
    say("199: queue after A " .. table.concat(q, " > "))
    check(S.queueHas("Read"), "199: A on Read queues the game's read action")
    S.stopAll()
end)
step(20, function()
    if S.skip199 then return end
    check(not p:isPrintMediaRead(S.paperId), "199: the read was cancelled: the paper is still unread")
    pcall(function() CW()._jr.paperOpen = nil end)
    getGameTime():setTimeOfDay(S.tod)
    pcall(function() local ct = S.paper:getContainer(); if ct then ct:Remove(S.paper) end end)
    ZeD_CharacterWindow.openTab(pn, "loot")
end)

-- ===================================================================== 225 (tap) / 195 / 225 (menu): a raw pork chop
step(10, function()
    ZeD_CharacterWindow.openTab(pn, "loot")
    S.pick(nil)
    S.chop = S.give("Base.PorkChop")
    S.apple = S.give("Base.Apple")
end)
step(30, function()
    local w = CW()
    S.claim(w)
    pcall(Focus.dispatchJoypadDir, w, "down")   -- (the pad's marks shown)
    local e = S.rowFocus(S.chop)
    if not e then say("not run: 225 / 195 / 227b (no row for the pork chop in the main inventory)"); S.skipChop = true; return end
    say("225: on " .. tostring(e.id) .. ", raw " .. tostring(not S.chop:isCooked()) .. ", hold prompt " .. tostring(e.promptHold and e.promptHold(w, e)))
    S.stopAll()
end)
pressA(function() if not S.skipChop then return CW() end end, 3)
step(20, function()
    if S.skipChop then return end
    local w = CW()
    check(not S.queueHas("Eat"), "225: a quick A on the raw chop's row eats nothing (queue " .. table.concat(S.queue(), " > ") .. ")")
    check(S.chop:getContainer() == p:getInventory(), "225: the chop is still whole on the character")
    check(w._drawerItem == S.chop, "225: the quick A opens its card")
    shot("225_card_after_tap")
end)
step(10, function()
    if S.skipChop then return end
    local w = CW()
    local c = w._itemCard
    if not (c and c:isVisible()) then say("not run: 225 card Eat (the card did not open)"); return end
    -- 225: the card's Eat is a hold only
    local eat
    pcall(Focus.flatElements, w)
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == "charItemCard" then
            for _, x in ipairs(z.elements or {}) do if x.isStrip and x.onHoldActivate and x.promptHold then eat = x end end
        end
    end
    check(eat ~= nil and eat.onActivate == nil, "225: the card's " .. tostring(eat and eat.promptHold) .. " runs on A held only (no tap)")
end)
step(10, function()
    if S.skipChop then return end
    local e = S.rowFocus(S.chop)
    say("225: back on the row " .. tostring(e and e.id) .. ", A prompt " .. tostring(e and e.promptA and e.promptA(CW(), e)))
end)
pressA(function() if not S.skipChop then return CW() end end, 3)
step(20, function()
    if S.skipChop then return end
    check(not S.queueHas("Eat"), "225: A again with its card open eats nothing (queue " .. table.concat(S.queue(), " > ") .. ")")
    shot("225_menu_after_second_a")
    S.closeMenus()
    S.stopAll()
    S.pick(nil)
end)

-- ===================================================================== 195: Up from the card's top button to its footer
-- (Nov 16 2026, round 2: a food card has no footer (ItemCardOrganism.maintenanceVerbsForItem: food, books, bags have
-- no maintenance verbs), so Up there rightly stays. A baseball bat's card has the footer's Repair.)
step(10, function()
    S.bat = S.give("Base.BaseballBat")
end)
step(20, function() if S.bat then S.pick(S.bat) end end)
step(20, function()
    local w = CW()
    local c = w._itemCard
    if not (S.bat and c and c:isVisible() and w._drawerItem == S.bat) then say("not run: 195 (the bat's card did not open)"); return end
    S.claim(w)
    c._scrollPixels = 0
    pcall(function() c._sb:setScrollPos(0) end)
    pcall(Focus.flatElements, w)
    local feet = {}
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == "charItemCard" then for _, x in ipairs(z.elements or {}) do if x.isFooter then feet[#feet + 1] = tostring(x.id) end end end
    end
    if not check(#feet > 0, "195: the bat's card has footer verbs (" .. table.concat(feet, ", ") .. ")") then return end
    local e = Focus.focusWhere(w, "charItemCard", function(x) return x.isPrimary end)
    if not check(e ~= nil and e.isStrip, "195: the card's top button is a pad stop (" .. tostring(e and e.id) .. ")") then return end
    Focus.dispatchJoypadDir(w, "up")
    local f = Focus.getFocusedElement(w)
    check(f ~= nil and f.isFooter == true, "195: Up from the top button, card at its top, goes to the footer's verbs (" .. tostring(f and f.id) .. ")")
    shot("195_footer")
end)
step(10, function()
    pcall(Focus.releaseFocus, pn)
    S.pick(nil)
end)

-- ===================================================================== 227b: the loot card for the pad's row
step(20, function()
    if S.skipChop then return end
    local w = CW()
    S.claim(w)
    pcall(Focus.dispatchJoypadDir, w, "down")
    local e = S.rowFocus(S.chop)
    check(e ~= nil and w._drawerItem ~= S.chop, "227b: the pad rests on the chop's row, no card open")
end)
step(45, function()
    if S.skipChop then return end
    local IT = ZeD.InvTip
    local wt = IT and IT._want
    check(wt ~= nil and wt.item == S.chop and wt.content ~= nil and (wt.frame or -9) >= (IT._frame or 0) - 2,
        "227b: after the rest the row asks for its loot card (" .. tostring(wt and wt.item and wt.item:getName()) .. ")")
    shot("227b_row_tip")
end)

-- ===================================================================== 225 (hold): A held on an apple eats
step(5, function()
    if S.skipChop then return end
    S.stopAll()
    local e = S.rowFocus(S.apple)
    if not e then say("not run: 225 hold (no row for the apple)"); S.skipApple = true end
end)
pressA(function() if not (S.skipChop or S.skipApple) then return CW() end end, 45,
    function() if not (S.skipChop or S.skipApple) then S.appleEat = S.queueHas("Eat"); say("225: queue while A is held " .. table.concat(S.queue(), " > ")) end end)
step(2, function()
    if S.skipChop or S.skipApple then return end
    check(S.appleEat, "225: A held on a food row queues the eat")
    S.stopAll()
end)

-- ===================================================================== 222: the cooking bar on the row
step(10, function()
    if S.skipChop then return end
    S.pick(nil)
    pcall(Focus.releaseFocus, pn)
    pcall(function() S.chop:setCookingTime((S.chop:getMinutesToCook() or 20) * 0.4) end)
    S.hot = S.chop
    S.cookWord = ZeD.tr("IGUI_invpanel_Cooking")
end)
step(10, function()
    if S.skipChop then return end
    say("222: chop heat " .. tostring(S.chop:getHeat()) .. ", cooking time " .. tostring(S.chop:getCookingTime()) .. " of " .. tostring(S.chop:getMinutesToCook()))
    S.capStart({ S.cookWord })
end)
step(20, function()
    if S.skipChop then return end
    local by = S.cap[string.lower(S.cookWord)]
    say("222: Cooking drawn by " .. tostring(by) .. ", thin accent bars " .. tostring(S.capRects))
    check(by ~= nil or S.capRects > 0, "222: the hot chop's row shows it cooking (the word or the bar)")
    shot("222_row_cooking")
    S.capStop()
    S.hot = nil
end)

-- ===================================================================== place the oven, a TV and a radio
step(10, function()
    local function special(o, sq)
        pcall(function() o:createContainersFromSpriteProperties() end)
        sq:AddSpecialObject(o)
        if o:getObjectIndex() < 0 then sq:AddTileObject(o) end
        return o
    end
    local ok, e = pcall(function() S.oven = S.keep(special(IsoStove.new(getCell(), S.sq(1, 0), getSprite("appliances_cooking_01_12")), S.sq(1, 0))) end)
    if not ok then say("ERR placing the oven: " .. tostring(e)) end
    ok, e = pcall(function() local sq = S.sq(-1, 0); S.tv = S.keep(IsoTelevision.new(getCell(), sq, getSprite("appliances_television_01_1"))); sq:AddTileObject(S.tv) end)
    if not ok then say("ERR placing the TV: " .. tostring(e)) end
    ok, e = pcall(function() local sq = S.sq(0, 1); S.radio = S.keep(IsoRadio.new(getCell(), sq, getSprite("appliances_radio_01_9"))); sq:AddTileObject(S.radio) end)
    if not ok then say("ERR placing the radio: " .. tostring(e)) end
    say("placed: oven " .. tostring(S.oven ~= nil) .. ", TV " .. tostring(S.tv ~= nil) .. ", radio " .. tostring(S.radio ~= nil))
end)

-- ===================================================================== 216: the tab follows a TV
function S.radioIdx(obj)
    for i, r in ipairs(WW()._radios or {}) do if r.radioInstance == obj then return i end end
    return nil
end
function S.radioTab() for _, t in ipairs(ZeD_WorldWindow.TABS or {}) do if t.id == "radio" then return t end end end
step(60, function()
    ZeD_WorldWindow.openTab(pn, "radio")
    S.tvI, S.rdI = S.radioIdx(S.tv), S.radioIdx(S.radio)
    say("216: " .. #(WW()._radios or {}) .. " sets in reach; TV " .. tostring(S.tvI) .. ", radio " .. tostring(S.rdI))
    if S.tvI then ZeD.RadioTab.selectRadio(WW(), S.tvI) end
end)
step(20, function()
    local tab = S.radioTab()
    if not (S.tvI and tab) then say("not run: 216 TV (the TV is not on the Radio tab)"); return end
    local lab = ZeD_WorldWindow.tabLabel(tab, WW())
    local px = ZeD_WorldWindow.tabIcon(tab, WW())
    check(lab == ZeD.tr("UI_ZeD_World_TabTelevision") and px == "tv", "216: a TV showing, the tab says " .. tostring(lab) .. " with the " .. tostring(px) .. " picture")
    shot("216_tv_tab")
    if S.rdI then ZeD.RadioTab.selectRadio(WW(), S.rdI) end
end)
step(20, function()
    local tab = S.radioTab()
    if not (S.rdI and tab) then say("not run: 216 radio (the radio is not on the Radio tab)"); return end
    local lab = ZeD_WorldWindow.tabLabel(tab, WW())
    local px = ZeD_WorldWindow.tabIcon(tab, WW())
    check(lab == getText("IGUI_ItemType_Radio") and px == "radio", "216: a radio showing, the tab says " .. tostring(lab) .. " with the " .. tostring(px) .. " picture")
    shot("216_radio_tab")
end)

-- ===================================================================== 207: the Radio tab on the D-pad
step(10, function()
    local w = WW()
    S.claim(w)
    pcall(Focus.flatElements, w)
    local has = Focus.focusWhere(w, "worldTabBar", function(x) return x.id == "tab:radio" end)
    if not check(has ~= nil, "207a: the Radio tab is a stop on the side strip") then S.skip207a = true; return end
    local first = Focus.focusWhere(w, "worldTabBar", function(x) return x.id == "tab:animals" end)
        or Focus.focusWhere(w, "worldTabBar", function() return true end)
    say("207a: from " .. tostring(first and first.id))
    S.n = 0
end)
step(4, function()
    if S.skip207a then return end
    local w = WW()
    S.n = S.n + 1
    local z = Focus.getFocusedZone(w)
    if S.fid(w) ~= "tab:radio" and z and z.zone == "worldTabBar" and S.n <= 14 then Focus.dispatchJoypadDir(w, "down"); return true end
    check(S.fid(w) == "tab:radio", "207a: Down along the strip reaches the Radio tab (" .. tostring(S.fid(w)) .. ", " .. (S.n - 1) .. " Downs)")
end)
step(30, function()
    local w = WW()
    ZeD_WorldWindow.openTab(pn, "radio")
    if S.rdI then ZeD.RadioTab.selectRadio(w, S.rdI) end
end)
step(20, function()
    local w = WW()
    if not w._radioTw then say("not run: 207b (no radio face on the tab)"); return end
    S.claim(w)
    local ok, flat = pcall(Focus.flatElements, w)
    -- (the face's own controls are "radio:tw:<id>"; any other radio stop only when the face has none)
    local top, other, tabs = nil, nil, 0
    for _, f in ipairs(ok and flat or {}) do
        local id = tostring(f.id)
        if f.zone == "worldTabContent" then
            if id:sub(1, 10) == "radio:tab:" then tabs = tabs + 1
            elseif id:sub(1, 9) == "radio:tw:" then if not top or f.y < top.y then top = f end
            elseif id:sub(1, 6) == "radio:" and id:sub(1, 10) ~= "radio:full" then if not other or f.y < other.y then other = f end end
        end
    end
    top = top or other
    check(tabs > 0, "207b: the radio's tab in the header is a stop (" .. tabs .. ")")
    if not top then say("not run: 207b Up (no face control found)"); return end
    Focus.focusWhere(w, "worldTabContent", function(x) return x.id == top.id end)
    Focus.dispatchJoypadDir(w, "up")
    check(tostring(S.fid(w)):sub(1, 10) == "radio:tab:", "207b: Up from the face's top control (" .. tostring(top.id) .. ") reaches the header (" .. tostring(S.fid(w)) .. ")")
    shot("207b_header")
end)

-- ===================================================================== 224: an oven on with no power cooks nothing
-- (Nov 16 2026, round 2: the drag strip has no power, and the game switches an unpowered oven back off within a
-- frame or two; the run holds its switch on each frame (S.keepOn) to stage the director's "on, but no heat".)
function S.ovenPowered()
    local ok, v = pcall(function() return S.oven:getContainer():isPowered() end)
    return ok and v == true
end
step(10, function()
    ZeD_WorldWindow.openTab(pn, "loot")
    pcall(Focus.releaseFocus, pn)
    if not S.oven then say("not run: 208 / 224 / 209 (no oven)"); S.skipOven = true; return end
    say("224: the oven powered " .. tostring(S.ovenPowered()))
    S.keepOn = true
    S.ovenFood = S.oven:getContainer():AddItem("Base.PorkChop")
    ZeD.Stations.open(p, S.oven)
    S.rawWord = ZeD.tr("UI_ZeD_Appliance_Raw")
    S.cookWord = ZeD.tr("IGUI_invpanel_Cooking")
end)
step(30, function()
    if S.skipOven or not S.ovenFood then return end
    say("224: oven on " .. tostring(S.oven:Activated()) .. ", the chop's heat " .. tostring(S.ovenFood:getHeat()) .. ", tab " .. tostring(WW()._activeTab))
    S.capStart({ S.rawWord, S.cookWord })
end)
step(15, function()
    if S.skipOven or not S.ovenFood then return end
    local cooking, raw = S.cap[string.lower(S.cookWord)], S.cap[string.lower(S.rawWord)]
    check(raw ~= nil and cooking == nil, "224: on with no power or gas, the contents say " .. tostring(S.rawWord) .. " (" .. tostring(raw) .. "), not "
        .. tostring(S.cookWord) .. " (" .. tostring(cooking) .. ")")
    shot("224_oven_raw")
    S.hot = S.ovenFood
end)
step(15, function()
    if S.skipOven or not S.ovenFood then return end
    check(S.cap[string.lower(S.cookWord)] ~= nil, "224: the same chop held hot reads " .. tostring(S.cookWord) .. " (heat " .. tostring(S.ovenFood:getHeat()) .. ")")
    shot("224_oven_cooking")
    S.capStop()
    S.hot, S.keepOn = nil, false
    pcall(function() S.oven:getContainer():Remove(S.ovenFood) end)
    pcall(function() ZeD.Stations.unbind(p) end)
    ZeD_WorldWindow.openTab(pn, "loot")
    pcall(function() if S.oven:Activated() then S.oven:setActivated(false) end end)
end)

-- ===================================================================== power for 208 and 209: a generator beside the oven
-- (the pop-out's controls are stamped only while the oven has power, StationAppliance.lua stamp(); the game's
-- Toggle turns on only a powered oven)
step(10, function()
    if S.skipOven then return end
    local ok, e = pcall(function()
        local g = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), S.sq(0, -2))
        g:setConnected(true); g:setFuel(60); pcall(function() g:setCondition(90) end)
        g:setActivated(true)
        S.gen = S.keep(g)
    end)
    if not ok then say("ERR placing the generator: " .. tostring(e)) end
    S.t = 0
end)
step(10, function()
    if S.skipOven or not S.gen then return end
    S.t = S.t + 1
    if not S.ovenPowered() and S.t < 40 then return true end
    say("power: generator on " .. tostring(S.gen:isActivated()) .. ", the oven powered " .. tostring(S.ovenPowered()) .. " after " .. S.t .. " polls")
end)

-- ===================================================================== 208: Turn on from the menu opens the oven
step(10, function()
    if S.skipOven then return end
    if not S.ovenPowered() then say("not run: 208 / 209 (no power reaches the oven at the drag strip)"); S.skipOven = true; return end
    S.stopAll()
    say("208: oven on before " .. tostring(S.oven:Activated()))
    ISWorldObjectContextMenu.onToggleStove({}, S.oven, pn)
    S.t = 0
end)
step(5, function()
    if S.skipOven then return end
    S.t = S.t + 1
    if (#S.queue() > 0 or not S.oven:Activated()) and S.t < 120 then return true end
end)
step(20, function()
    if S.skipOven then return end
    check(S.oven:Activated(), "208: the menu's Turn on turns the powered oven on (queue " .. table.concat(S.queue(), " > ") .. ")")
    local TF = ZeD.TwoWayFull
    local popped = TF and TF.showingObj and TF.showingObj(pn, S.oven)
    local st = ZeD.Stations.current(p)
    local tab = st ~= nil and st.obj == S.oven and WW()._activeTab == "craft"
    check(popped or tab, "208: when it ends the oven opens (" .. (popped and "its face popped out" or (tab and "the Craft tab on it" or "nothing")) .. ")")
    shot("208_oven_open")
    if popped then pcall(TF.close, pn) end
end)


-- ===================================================================== 209: the oven's pop-out
function S.mid(z) return z.x + (z.w or 0) / 2, z.y + (z.h or 0) / 2 end
step(10, function()
    if S.skipOven then return end
    local st = ZeD.Stations.current(p)
    if not (st and st.obj == S.oven) then ZeD.Stations.open(p, S.oven); st = ZeD.Stations.current(p) end
    if not (st and st.obj == S.oven and ZeD.StationPopout) then say("not run: 209 (the oven is not bound)"); S.skip209 = true; return end
    fake.focus = WW()
    S.pop = withPad(function() return ZeD.StationPopout.open(p, st) end)
    if not S.pop then say("not run: 209 (no pop-out)"); S.skip209 = true end
end)
step(30, function()
    if S.skip209 then return end
    local win = S.pop
    check(fake.focus == win, "209: the pop-out takes the pad")
    shot("209_popout")
    local c = win:controls()
    local bad, moves = {}, 0
    for i = 1, #c do
        for _, dir in ipairs({ "up", "down", "left", "right" }) do
            win.fi, win._grab = i, false
            local from = c[i]
            win:moveDir(dir)
            local to = c[win.fi]
            if to ~= from and from.x and to.x then
                moves = moves + 1
                local fx, fy = S.mid(from)
                local tx, ty = S.mid(to)
                local ok = (dir == "up" and ty < fy) or (dir == "down" and ty > fy) or (dir == "left" and tx < fx) or (dir == "right" and tx > fx)
                if not ok then bad[#bad + 1] = i .. dir end
            end
        end
    end
    check(#c > 1 and moves > 0 and #bad == 0, "209a: each D-pad move goes to a control that lies that way (" .. #c .. " controls, " .. moves .. " moves, wrong: " .. table.concat(bad, " ") .. ")")
    S.knob = nil
    for i, z in ipairs(c) do if not S.knob and z.kind == "turn" then S.knob = i end end
    S.key = nil
    for i, z in ipairs(c) do if not S.key and z.kind ~= "turn" then S.key = i end end
end)
step(5, function()
    if S.skip209 then return end
    local win = S.pop
    if not S.knob then say("not run: 209b (no knob on this face)"); return end
    win.fi, win._grab = S.knob, false
    withPad(function() win:onJoypadDown(Joypad.AButton, fake) end)
    check(win:knobGrabbed(), "209b: A grabs the knob")
    for _ = 1, 30 do withPad(function() win:onJoypadDirRight() end) end
    check(win:isReallyVisible() and fake.focus == win and win.fi == S.knob, "209b: turned 30 steps right, the knob keeps the pad and the window stays")
    for _ = 1, 30 do withPad(function() win:onJoypadDirLeft() end) end
    check(win:isReallyVisible() and fake.focus == win and win.fi == S.knob, "209b: turned 30 steps left, the same")
    shot("209_knob_end")
    withPad(function() win:onJoypadDown(Joypad.BButton, fake) end)
    check(not win:knobGrabbed() and win:isReallyVisible(), "209b: B lets go of the knob, the pop-out stays")
    withPad(function() win:onJoypadDown(Joypad.BButton, fake) end)
    check(not win:isReallyVisible(), "209b: B again closes the pop-out (the pad now on " .. tostring(fake.focus and (fake.focus.Type or fake.focus)) .. ")")
end)
step(10, function()
    if S.skip209 or not S.key then return end
    local st = ZeD.Stations.current(p)
    if not st then say("not run: 209b B on a key (the oven was let go)"); return end
    fake.focus = WW()
    local win = withPad(function() return ZeD.StationPopout.open(p, st) end)
    if not win then return end
    win.fi = S.key
    withPad(function() win:onJoypadDown(Joypad.BButton, fake) end)
    check(not win:isReallyVisible(), "209b: B on a key closes the pop-out")
    say("not run: 209 the held D-pad's own repeat on a knob (no controller here: the director's hands)")
end)

-- 208 again: Turn off from the menu leaves the windows as they are
step(10, function()
    if S.skipOven then return end
    pcall(function() ZeD.Stations.unbind(p) end)
    ZeD_WorldWindow.openTab(pn, "loot")
end)
step(10, function()
    if S.skipOven then return end
    S.stopAll()
    if not S.oven:Activated() then say("not run: 208 Turn off (the oven is already off)"); return end
    ISWorldObjectContextMenu.onToggleStove({}, S.oven, pn)
    S.t = 0
end)
step(5, function()
    if S.skipOven then return end
    S.t = S.t + 1
    if (#S.queue() > 0 or S.oven:Activated()) and S.t < 120 then return true end
end)
step(20, function()
    if S.skipOven then return end
    local TF = ZeD.TwoWayFull
    local popped = TF and TF.showingObj and TF.showingObj(pn, S.oven)
    say("208: the oven on after the menu's Turn off " .. tostring(S.oven:Activated()))
    check(not popped and WW()._activeTab == "loot", "208: Turn off from the menu opens nothing (tab " .. tostring(WW()._activeTab) .. ")")
end)

-- ===================================================================== 203: Furniture's Pick up keeps its square on Y
step(10, function()
    pcall(Focus.releaseFocus, pn)
    ZeD_WorldWindow.openTab(pn, "furniture")
end)
step(30, function()
    local FT = ZeD.FurnitureTab
    local cur = FT and (FT.cursorOf(pn) or FT.startCursor(pn, "pickup"))
    if not (cur and FT.active(pn)) then say("not run: 203 (the Furniture tab's cursor is not up)"); S.skip203 = true; return end
    pcall(function() cur:setMoveableMode("pickup") end)
    S.fx, S.fy = math.floor(p:getX()) + 3, math.floor(p:getY()) + 2
    cur.xJoypad, cur.yJoypad, cur.zJoypad = S.fx, S.fy, math.floor(p:getZ())
    withPad(function() cur:onJoypadPressButton(pn, fake, Joypad.YButton) end)
    check(cur.xJoypad == S.fx and cur.yJoypad == S.fy, "203: Y with the tab up keeps the chosen square (" .. tostring(cur.xJoypad) .. "," .. tostring(cur.yJoypad)
        .. ", chosen " .. S.fx .. "," .. S.fy .. ")")
    shot("203_cursor_kept")
end)
step(10, function()
    if S.skip203 then return end
    ZeD_WorldWindow.openTab(pn, "loot")
end)
step(10, function() pcall(function() local d = getCell():getDrag(pn); if d and d.Type == "ISMoveableCursor" then getCell():setDrag(nil, pn) end end) end)

-- ===================================================================== put back
step(20, function()
    S.capStop()
    S.hot, S.keepOn = nil, false
    pcall(function() Events.OnPreUIDraw.Remove(S.heatFn) end)
    pcall(function() if S.gen then S.gen:setActivated(false) end end)
    for _, b in ipairs({ "A", "Y", "B", "X" }) do pcall(Focus.qaButton, b, nil, pn) end
    JoypadState.players[pn + 1] = nil
    S.stopAll()
    S.closeMenus()
    pcall(function() if ZeD.StationPopout then ZeD.StationPopout.close(p) end end)
    pcall(function() if ZeD.TwoWayFull and S.oven and ZeD.TwoWayFull.showingObj(pn, S.oven) then ZeD.TwoWayFull.close(pn) end end)
    pcall(function() ZeD.Stations.unbind(p) end)
    pcall(function() if S.oven and S.oven:Activated() then S.oven:Toggle() end end)
    pcall(function() S.pick(nil) end)
    pcall(function() if ZeD.Settings.putBackOption and S.pbWas then ZeD.Settings.putBackOption:setValue(S.pbWas) end end)
    for _, obj in ipairs(S.placed) do
        pcall(function() local sq = obj:getSquare(); if sq then sq:transmitRemoveItemFromSquare(obj) end end)
        pcall(function() local sq = obj:getSquare(); if sq then sq:RemoveTileObject(obj) end end)
        pcall(function() if instanceof(obj, "IsoGenerator") then obj:remove() end end)
    end
    for _, it in ipairs(S.added) do
        pcall(function() if p:isEquippedClothing(it) then p:removeWornItem(it) end end)
        pcall(function() if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end; if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end end)
        pcall(function() local ct = it:getContainer(); if ct then ct:Remove(it) end end)
    end
    pcall(function() if S.shirt then local ct = S.shirt:getContainer(); if ct then ct:Remove(S.shirt) end end end)
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    pcall(function() getGameTime():setTimeOfDay(S.tod) end)
    pcall(function() ZeD_WorldWindow.openTab(pn, "loot"); ZeD_CharacterWindow.openTab(pn, "loot") end)
    pcall(function() if not ZeD_CharacterWindow.isOpen(pn) then ZeD_CharacterWindow.toggleBothPaired(pn) end end)
    pcall(Focus.releaseFocus, pn)
    pcall(function() Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil) end)
    pcall(function() p:setIgnoreContextKey(false) end)
    pcall(function() p:setBlockMovement(false) end)
    if S.paperId and p:isPrintMediaRead(S.paperId) then say("note: the character has now read " .. S.paperId) end
    say("put back: " .. #S.placed .. " objects and " .. #S.added .. " items taken away")
end)
step(20, function()
    if getGameSpeed() ~= S.speed then setGameSpeed(S.speed) end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- (stepped on each drawn frame: a paused game stops the tick)
local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    local ok, again = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(again)) end
    if not (ok and again == true) then qi = qi + 1 end
end
Events.OnPreUIDraw.Add(tick)
say("start")
