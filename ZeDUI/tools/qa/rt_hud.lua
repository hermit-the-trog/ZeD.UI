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
--   hint      ZeD_HintStrip.lua: at a door the strip shows above the belt, centred; Off takes it away
-- Every surface: RT.bounds. Puts back: every option, the stats, hands, worn watch, the watch's saved spot, Messages,
-- the guide's flag file and timings, search mode, the time, the character's spot. Things given are taken back.
local Q = RT.make("rt_hud")
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
    S.setOpt(Z.Settings.hintStripOption, 3)
end)
Q.step(10, function()
    if not S.door then return end
    local h = Z.HintStrip._huds[S.pn]
    Q.check(h ~= nil and h._p == nil, "hint: Off takes the strip away")
    S.putHint()
end)
function S.putHint()
    if not S.back.hint then return end
    S.back.hint = nil
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

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    pcall(function() S.p:StopAllActionQueue() end)
    S.putHands(); S.putWatch(); S.putMoodles(); S.putHalo(); S.putGuide(); S.putHint(); S.putForage()
    pcall(function() S.p:setZ(S.home.z); S.p:setLastZ(S.home.z) end)
    S.moveTo(S.home.x, S.home.y)
    if S.pairWas then RT.pairOpen() end
end)
Q.step(10, function()
    Q.check(math.abs(S.p:getX() - S.home.x) < 0.01 and math.abs(S.p:getY() - S.home.y) < 0.01, "put back: the character where it started")
    if S.mood then Q.check(S.opt(Z.Settings.moodlePlaceOption) == (S.mood.opt or 1), "put back: the moodles' place") end
    if S.watch then Q.check(S.opt(Z.Settings.watchPlaceOption) == S.watch.opt, "put back: the watch's place") end
end)
Q.start()
