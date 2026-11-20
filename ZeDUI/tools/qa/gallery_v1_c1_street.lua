-- (Nov 20 2026, QA: OUT OF DATE since beta 21. This script sets one or more of the retired per-piece Simple switches,
-- which nothing reads now (one Style switch: ZeD.Settings.lookStyleOption, 1 Full, 2 Lite). A Simple leg runs against
-- Full; a Full pick is a no-op. To reuse it, set lookStyleOption instead (the value only). Not in the release test.)
-- ZeDUI/tools/qa/gallery_v1_c1_street.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's lived-in retakes on West Point's
-- main street (gallery_v1_c1_common.lua's "street": the walk outside the cafe, the post office, the tool store and the
-- grocery across the road). ZeD on. Same content and settings as today's captures, same file names. The windows are
-- shut for all but the Messages window, which goes to the left edge (the character and the street beside it).
--   22 The Belt and 30 Speech, Thoughts and Hands (one capture serves both)   as zedqa_hands_together.lua:
--        zqa_ht_01_two (dark, small text, a hammer in the main hand at 80%, a kitchen knife in the off hand at 50%,
--        no watch on the belt), zqa_ht_02_both (the hammer in both hands: the off hand peeking),
--        zqa_ht_06_rightwatch_pistol (a right-wrist ClassicBrown watch, a pistol with 12 in the magazine and one
--        chambered, two spare magazines and a box carried)
--   27 Watches   gbw_DigitalBlack, gbw_DigitalTimez, gbw_ClassicGold, gbw_DigitalRed (the watch on the belt, 13:00;
--        the kit's own watch taken off and put back), as gallery_b19_b.lua
--   30 Speech, Thoughts and Hands   lpp_dark_detailed_read (Dark, the action bar Detailed, reading a book, taken at
--        about 30%), lpp_dark_speech (Overhead notes on, a line said), as zedqa_b19_light_popups.lua
--   31 Messages  zqa_g4_belt_toast, zqa_g4_window_radio (two made-up mods' notes; the toast, then the Messages window on
--        Sample Radio Plus) as gallery_b19_b.lua (zedqa_gallery_t4.lua); zqa_g4_guide_bubble (the guide's balloon from
--        the belt, first show at 1.5 s; zedqa_guide_bubble.lua)
-- Puts back: the theme, the hands, conditions, given things, watches worn, the options (watch place, action bar,
-- Overhead notes, Messages catch and toasts), Messages' sources and toasts, the guide's constants, flag and option,
-- the time of day, the game speed, the window pair. The place: gallery_v1_c1_end.lua. grep "ZEDQA c1s".
if not C1 then print("ZEDQA c1s ERR run gallery_v1_c1_common.lua first"); print("ZEDQA c1s DONE"); return end
local S = C1.make("c1s")
if not C1.zed then S.say("ERR ZeD is not loaded: this script is for the ZeD run"); S.say("DONE"); return end
S.p, S.pn, S.inv = C1.p, C1.pn, C1.p:getInventory()
S.CWm = ZeD_CharacterWindow
S.Opt = ZeD.Settings
S.B = ZeD.Belt
S.MS, S.MW = ZeD.Messages, ZeD.MessagesWindow
S.was, S.added, S.worn = { opt = {} }, {}, {}
S.RADIO, S.FARM = "Sample Radio Plus", "Sample Farm Map"

function S.pairShut() if S.CWm.isOpen(S.pn) then pcall(S.CWm.toggleBothPaired, S.pn) end end
function S.pairOpen() if not S.CWm.isOpen(S.pn) then pcall(S.CWm.toggleBothPaired, S.pn) end end
function S.give(ft)
    local it = nil
    pcall(function() it = S.inv:AddItem(ft) end)
    if it then S.added[#S.added + 1] = it end
    return it
end
function S.setOpt(key, v) local o = S.Opt[key]; if o and v then pcall(function() o:setValue(v) end) end end
function S.saveOpt(key) local o = S.Opt[key]; if o then S.was.opt[key] = o:getValue() end end
function S.stopAll() pcall(function() S.p:StopAllActionQueue() end) end
function S.speed(n) pcall(ZEDQA_SPEED or setGameSpeed, n) end
function S.setCond(it, f) pcall(function() it:setCondition(math.max(1, math.floor(it:getConditionMax() * f + 0.5))) end) end
-- a watch on a wrist; what that wrist wore goes back after (zedqa_hands_together.lua's wearNew / takeOff)
function S.wearNew(full)
    local it = S.inv:AddItem(full)
    local loc = it:getBodyLocation()
    S.worn[#S.worn + 1] = { it = it, loc = loc, prev = S.p:getWornItem(loc) }
    S.p:setWornItem(loc, it)
    return it
end
function S.takeOff(it)
    for _, w in ipairs(S.worn) do
        if w.it == it and not w.off then
            w.off = true
            pcall(function() S.p:removeWornItem(it); S.inv:Remove(it) end)
            if w.prev and S.inv:contains(w.prev) then pcall(function() S.p:setWornItem(w.loc, w.prev) end) end
        end
    end
end
-- the kit's own watch (gallery_b19_b.lua's findKit), off for the belt watches and back after
function S.findKit()
    pcall(function()
        local worn = S.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local wi = worn:get(i)
            if instanceof(wi:getItem(), "AlarmClockClothing") then S.kit, S.kitLoc = wi:getItem(), wi:getLocation() end
        end
    end)
end
function S.wear(name)
    if S.curWatch then pcall(function() S.p:removeWornItem(S.curWatch, false); S.inv:Remove(S.curWatch) end); S.curWatch = nil end
    if S.kit then pcall(function() S.p:removeWornItem(S.kit, false) end) end
    if not name then
        if S.kit then pcall(function() S.p:setWornItem(S.kitLoc, S.kit) end) end
        return
    end
    pcall(function()
        S.curWatch = S.inv:AddItem("Base.WristWatch_Left_" .. name)
        S.p:setWornItem(S.curWatch:getBodyLocation(), S.curWatch)
    end)
end
-- everything given so far taken back out of the inventory (worn watches come off with S.takeOff / S.wear first)
function S.giveBack()
    for i = #S.added, 1, -1 do local it = S.added[i]; pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    S.added = {}
end
function S.load(gun, n, mag)
    pcall(function() gun:setCurrentAmmoCount(n) end)
    if mag then pcall(function() gun:setContainsClip(true) end) end
    pcall(function() gun:setRoundChambered(n > 0) end)
end
function S.beltLine(tag)
    pcall(function()
        local hud = S.B.getHUD()
        local t = {}
        for _, b in ipairs(hud._boxes or {}) do t[#t + 1] = tostring(b.kind) .. (b.which and ("/" .. b.which) or "") .. (b.peek and "(peek)" or "") end
        S.say(tag .. ": belt " .. table.concat(t, " ") .. " at " .. math.floor(hud:getAbsoluteX()) .. "," .. math.floor(hud:getAbsoluteY()))
    end)
end
function S.prog()
    local d = -1
    pcall(function() local q = ISTimedActionQueue.getTimedActionQueue(S.p); d = q.queue[1].action:getJobDelta() end)
    return d or -1
end
function S.note(src, text, rich)
    S.MS.qaSource = src
    local d
    if rich then d = ISModalRichText:new(0, 0, 420, 300, text, false, {}, S.noop, S.pn)
    else d = ISModalDialog:new(0, 0, 320, 150, text, false, {}, S.noop, S.pn) end
    d:initialise(); d:addToUIManager()
    S.MS.qaSource = nil
end
function S.noop() end
function S.gbToast()
    local G = ZeD.GuideBubble
    for _, x in ipairs(S.MS.toasts or {}) do if x.source == G.head() then return x end end
    return nil
end
function S.gbFlag(s) pcall(function() local w = getFileWriter("ZeD_guidebubble.txt", true, false); w:write(s or ""); w:close() end) end

-- ===================================================================== start
C1.go(S, "street")
S.step(10, function()
    local W = S.was
    W.base, W.accent, W.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    W.p1, W.p2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    W.cw = S.CWm.isOpen(S.pn)
    W.tod = getGameTime():getTimeOfDay()
    W.speed = getGameSpeed()
    for _, k in ipairs({ "watchPlaceOption", "actionBarOption", "haloBubbleOption", "messagesCatchOption", "messagesToastOption" }) do S.saveOpt(k) end
    S.findKit()
    S.pairShut()
    C1.hold = nil
    C1.extraBoxes = nil
    S.say("start | look " .. tostring(W.base) .. " " .. tostring(W.accent) .. " " .. tostring(W.size) .. " | kit watch " .. tostring(S.kit and S.kit:getFullType()))
end)
-- the load: the character's limit is 18 kg here; the heaviest loose things are set aside for the whole street set
-- (put back at the end), and what each section gives is taken back when it is done
S.step(5, function()
    local max = 18
    pcall(function() max = S.p:getMaxWeight() end)
    C1.lightenTo(S, max - 4)
end)
S.mark()

-- ===================================================================== 22 / 30: the hands on the belt
S.step(30, function()
    S.main = S.give("Base.Hammer")
    S.off = S.give("Base.KitchenKnife")
    S.setOpt("watchPlaceOption", 2)   -- (no watch on the belt yet)
    ZeD.applyTheme("dark", ZeD.currentAccent, "small")
    S.setCond(S.main, 0.80); S.setCond(S.off, 0.50)
    S.p:setPrimaryHandItem(S.main); S.p:setSecondaryHandItem(S.off)
    C1.face("SE")
end)
S.step(40, function() S.beltLine("01 two items"); S.shot("zqa_ht_01_two") end)
S.step(10, function() S.p:setSecondaryHandItem(S.main) end)
S.step(30, function() S.beltLine("02 both hands"); S.shot("zqa_ht_02_both") end)
S.step(10, function()
    S.setOpt("watchPlaceOption", 1)
    S.w2 = S.wearNew("Base.WristWatch_Right_ClassicBrown")
    S.gun = S.give("Base.Pistol")
    if S.gun then S.load(S.gun, 12, true) end
    S.give("Base.9mmClip"); S.give("Base.9mmClip"); S.give("Base.Bullets9mmBox")
    S.p:setPrimaryHandItem(S.gun); S.p:setSecondaryHandItem(S.off)
end)
S.step(60, function()
    S.beltLine("06 right wrist, pistol")
    if S.gun then S.shot("zqa_ht_06_rightwatch_pistol") else S.notTaken("zqa_ht_06_rightwatch_pistol", "no pistol item") end
end)
S.step(10, function()
    S.takeOff(S.w2)
    S.p:setPrimaryHandItem(S.was.p1); S.p:setSecondaryHandItem(S.was.p2)
    pcall(function() ZeD.applyTheme(S.was.base, S.was.accent, S.was.size) end)
    S.giveBack()
    S.say("the hands' things taken back | load " .. ((GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "?"))
end)

-- ===================================================================== 27: the belt watches, 13:00 in daylight
-- (the first take had two thirds of each frame black: the map round the street not loaded yet. The clock is set to
-- 13:00 first, then the shots wait for the rings of squares round the character to load, plus 4 s)
S.step(30, function()
    S.setOpt("watchPlaceOption", 1)
    getGameTime():setTimeOfDay(13.0)
end)
C1.waitMap(S, "watches")
C1.reveal(S, "watches")   -- (two thirds black again in daylight: squares never seen draw black; the tour sees them)
for _, name in ipairs({ "DigitalBlack", "DigitalTimez", "ClassicGold", "DigitalRed" }) do
    S.step(10, function() S.wear(name) end)
    S.step(60, function() C1.face("SE") end)
    S.step(30, function() S.shot("gbw_" .. name) end)
end
S.step(10, function()
    S.wear(nil)
    S.setOpt("watchPlaceOption", S.was.opt.watchPlaceOption)
    getGameTime():setTimeOfDay(S.was.tod)
end)

-- ===================================================================== 30: the detailed bar while reading, the spoken line
S.step(20, function()
    S.stopAll()
    ZeD.applyTheme("dark", S.was.accent, S.was.size)
    S.setOpt("actionBarOption", 1)   -- Detailed
end)
S.step(10, function()
    S.book = S.give("Base.Book")
    if S.book then pcall(function() ISTimedActionQueue.add(ISReadABook:new(S.p, S.book)) end) end
    S.speed(3)
end)
S.waitFor(5, 2000, function() return S.prog() >= 0.3 end, function(ok)
    S.speed(1)
    S.say(string.format("reading: progress %.2f%s", S.prog(), ok and "" or " (not at 0.30: taken anyway)"))
end)
S.step(10, function()
    if S.book then S.shot("lpp_dark_detailed_read") else S.notTaken("lpp_dark_detailed_read", "no book item") end
end)
S.step(10, function()
    S.stopAll()
    S.giveBack()
    S.setOpt("actionBarOption", S.was.opt.actionBarOption)
    S.setOpt("haloBubbleOption", 2)
    S.speed(1)
end)
S.step(30, function() C1.face("SE"); S.p:Say("Is anyone out there? I have food and water.") end)
S.step(40, function() S.shot("lpp_dark_speech") end)
S.step(300, function()   -- (the line runs out first)
    S.setOpt("haloBubbleOption", S.was.opt.haloBubbleOption)
    pcall(function() ZeD.applyTheme(S.was.base, S.was.accent, S.was.size) end)
end)

-- ===================================================================== 31: Messages
S.step(30, function()
    S.msgWas = { S.MS.sources, S.MS.toasts }
    S.MS.sources, S.MS.toasts = {}, {}
    S.setOpt("messagesCatchOption", 2); S.setOpt("messagesToastOption", 2)
end)
S.step(10, function()
    S.note(S.RADIO, "<H1> Sample Radio Plus 2.1 <LINE> <TEXT> New in this version: the scanner remembers the last ten stations it found. <LINE> <LINE> Hold R beside any radio to scan.", true)
    S.note(S.RADIO, "Sample Radio Plus: your saved stations were moved to the new list.")
end)
S.step(40, function()
    S.note(S.FARM, "<H1> Welcome to Sample Farm <LINE> <TEXT> The farmhouse keys are in the mailbox by the road. The barn's generator needs fuel before the first winter.", true)
end)
S.step(25, function() S.shot("zqa_g4_belt_toast") end)
S.step(10, function()
    S.MW.open(S.pn, S.FARM)
    C1.extraBoxes = { { "messages", function() return S.MW.get(S.pn) end } }
end)
S.step(30, function()
    local w = S.MW.get(S.pn)
    if w then w:choose(S.RADIO) end
    C1.side(S, { { "messages", w, "left" } })
    C1.hold = function() C1.side(nil, { { "messages", S.MW.get(S.pn), "left" } }) end
end)
S.still(30, function()
    if S.MW.get(S.pn) then S.shot("zqa_g4_window_radio") else S.notTaken("zqa_g4_window_radio", "the Messages window did not open") end
end)
S.step(10, function()
    C1.hold = nil
    C1.extraBoxes = nil
    local w = S.MW.get(S.pn)
    if w then pcall(function() w:close() end) end
    S.MS.sources, S.MS.toasts = S.msgWas[1] or {}, S.msgWas[2] or {}
end)
-- the guide's balloon from the belt (first show at 1.5 s)
S.step(20, function()
    local G = ZeD.GuideBubble
    if not (G and ZeD.Guide) then S.GB = nil; return end
    S.GB = { const = { G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS } }
    pcall(function() local r = getFileReader("ZeD_guidebubble.txt", false); if r then S.GB.flag = r:readLine(); r:close() end end)
    S.GB.option = getCore():getOptionShowSurvivalGuide()
    S.GB.sources, S.GB.toasts = S.MS.sources, S.MS.toasts
    S.MS.sources, S.MS.toasts = {}, {}
    G.FIRST_MS = 1500
    S.gbFlag("")
    getCore():setOptionShowSurvivalGuide(true)
    G.start()
end)
S.waitFor(10, 1200, function() return S.GB == nil or S.gbToast() ~= nil end, function(ok)
    if not S.GB then S.notTaken("zqa_g4_guide_bubble", "the guide bubble is not loaded"); return end
    if not ok then S.notTaken("zqa_g4_guide_bubble", "the balloon never came up"); S.GB.none = true end
end)
S.step(90, function() if S.GB and not S.GB.none then S.shot("zqa_g4_guide_bubble") end end)
S.step(10, function()
    local G = ZeD.GuideBubble
    if not (S.GB and G) then return end
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = S.GB.const[1], S.GB.const[2], S.GB.const[3], S.GB.const[4]
    G.st = nil
    S.gbFlag(S.GB.flag or "")
    pcall(function() getCore():setOptionShowSurvivalGuide(S.GB.option) end)
    S.MS.sources, S.MS.toasts = S.GB.sources or {}, S.GB.toasts or {}
end)

-- ===================================================================== put back
S.mark()
S.step(10, function()
    local W = S.was
    C1.hold, C1.extraBoxes = nil, nil
    S.stopAll()
    pcall(function() local w = S.MW.get(S.pn); if w and w:isVisible() then w:close() end end)
    if S.msgWas then S.MS.sources, S.MS.toasts = S.msgWas[1] or {}, S.msgWas[2] or {} end
    S.wear(nil)
    for _, w in ipairs(S.worn) do S.takeOff(w.it) end
    pcall(function() S.p:setPrimaryHandItem(W.p1); S.p:setSecondaryHandItem(W.p2) end)
    for i = #S.added, 1, -1 do local it = S.added[i]; pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    S.added = {}
    C1.lightenBack(S)
    for k, v in pairs(W.opt) do S.setOpt(k, v) end
    pcall(function() ZeD.applyTheme(W.base, W.accent, W.size) end)
    pcall(function() getGameTime():setTimeOfDay(W.tod) end)
    S.speed((W.speed and W.speed > 0) and W.speed or 1)
    if W.cw then S.pairOpen() end
    S.say("put back: theme, hands, things given, watches, options, Messages, the guide, time of day, speed, windows")
end)
S.start()
