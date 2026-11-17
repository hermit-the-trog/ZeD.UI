-- ZeDUI/tools/qa/zedqa_b19_light_popups.lua  (Nov 17 2026, QA): Build's light pop-ups in the running game. The moodle's
-- note and its hover balloon (ZeD_Moodles: _drawChip and ZeD.Balloon.draw inside ZeD.Balloon.inLight), the action bar
-- Simple and Detailed (ZeD_ActionBar render: drawBar inside ZeD.Balloon.inLight) and the notice balloons, a mod's note
-- out of the belt and the guide's offer (ZeD.Bubbles.drawNoticeBalloons with ZeD.Balloon.LIGHT), each in Dark, Light
-- and High contrast (ZeD.applyTheme, the accent and size kept).
-- How it is judged: while one of those draws runs (ZeD.Balloon.inLight, ZeD.Balloon.draw, ZeD.Bubbles.drawNoticeBalloons
-- wrapped to mark it), every ISUIElement.drawRect at full alpha is tallied by color and area. The fill is the color
-- with the most area; PASS when it is the tooltips' light grey (ZeD.Balloon.LIGHT surf1 / surf2 / surf3, within 0.03)
-- in every theme, else FAIL with the colors drawn. The hovers (the pointer stood in for on the layer, as
-- zedqa_moodles.lua does) also look for the light hover wash (LIGHT.borderS at about 0.14 alpha) on the notice balloons.
--   mood    the Moodles row at right, left and bottom; hunger, thirst, tiredness raised (as zedqa_moodles.lua): the note
--           by itself (lpp_<theme>_mood_<place>_note), then the pointer on moodle 2 (lpp_<theme>_mood_<place>)
--   bar     Simple, then Detailed: reading a book (work), stopped (the queue stopped mid-read), resting (no end, its
--           icon), done (an apple eaten to its end): lpp_<theme>_<simple|detailed>_<read|stopped|rest|done>
--   notice  two made-up mods' notes (zedqa_gallery_t4.lua's), the balloon and its hover; the guide's offer
--           (zedqa_guide_bubble.lua, first show at 1.5 s), the balloon and its hover: lpp_<theme>_notice_<mod|guide>[_hover]
-- Run after gallery_unload.lua (the load under 20 kg, the pointer hidden) and before gallery_reload.lua.
-- Puts back: the theme, the Moodles place, the action bar row, Moodle notices, the stats, god mode, the actions, the
-- given things, Messages, the guide's constants and flag, Overhead notes, the game speed, the wrapped draws. Over the head
-- (S.overhead): a spoken line, speed 2 and pause (the speed bubble), a red and a green halo note, each judged the same
-- way, the notes' status marks checked for LIGHT.danger / LIGHT.positive: lpp_<theme>_<speech|speed|pause|halo_red|halo_green>.
-- grep "ZEDQA lpp".
local S = { Q = {}, qi = 1, given = {}, tally = {}, depth = 0, res = {} }
S.p = getPlayer()
S.pn = S.p:getPlayerNum()
S.inv = S.p:getInventory()
S.St = ZeD.Settings
S.MO, S.AB, S.MS, S.Bl, S.Bb = ZeD.Moodles, ZeD.ActionBar, ZeD.Messages, ZeD.Balloon, ZeD.Bubbles
S.fails, S.passes = 0, 0
function S.say(s) print("ZEDQA lpp " .. tostring(s)) end
function S.step(n, fn) S.Q[#S.Q + 1] = { n = n, fn = fn } end
function S.check(ok, what) if ok then S.passes = S.passes + 1; S.say("PASS " .. what) else S.fails = S.fails + 1; S.say("FAIL " .. what) end; return ok end
if not (S.MO and S.AB and S.MS and S.Bl and S.Bl.LIGHT and S.Bl.inLight and S.Bb and S.Bb.drawNoticeBalloons) then
    S.say("ERR the balloon, moodle, action bar or Messages modules are not loaded"); S.say("DONE"); return
end
S.LIGHT = S.Bl.LIGHT

-- ---------------------------------------------------------------- the capture
function S.console()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false) end end
    end)
end
function S.shot(name)
    S.console()
    pcall(function() S.p:setInvisible(false) end)
    local ok = pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
    S.say((ok and "shot " or "ERR shot ") .. name)
end
S.real = { drawRect = ISUIElement.drawRect, inLight = S.Bl.inLight, draw = S.Bl.draw, notice = S.Bb.drawNoticeBalloons }
function S.near(c, r, g, b, tol) return c and math.abs(c.r - r) <= tol and math.abs(c.g - g) <= tol and math.abs(c.b - b) <= tol end
function S.onRect(self, x, y, w, h, a, r, g, b)
    if S.capOn and type(r) == "number" then
        if S.depth > 0 and (a or 1) >= 0.9 and w and h and w > 0 and h > 0 then
            local key = string.format("%.2f,%.2f,%.2f", r, g, b)
            S.tally[key] = (S.tally[key] or 0) + w * h
        end
        local bs = S.LIGHT.borderS
        if a and a > 0.05 and a < 0.3 and S.near(bs, r, g, b, 0.03) then S.wash = (S.wash or 0) + 1 end
    end
    return S.real.drawRect(self, x, y, w, h, a, r, g, b)
end
function S.marked(fn)
    return function(...)
        S.depth = S.depth + 1
        local ok, a, b, c, d = pcall(fn, ...)
        S.depth = S.depth - 1
        if not ok then error(a) end
        return a, b, c, d
    end
end
function S.wrap()
    ISUIElement.drawRect = S.onRect
    S.Bl.inLight = S.marked(S.real.inLight)
    S.Bl.draw = S.marked(S.real.draw)
    S.Bb.drawNoticeBalloons = S.marked(S.real.notice)
end
function S.unwrap()
    ISUIElement.drawRect = S.real.drawRect
    S.Bl.inLight = S.real.inLight
    S.Bl.draw = S.real.draw
    S.Bb.drawNoticeBalloons = S.real.notice
end
function S.start(tag) S.tally, S.wash, S.capOn, S.tag = {}, 0, true, tag end
-- the fill: the color with the most area drawn inside the marked draws since S.start
function S.judge(wantWash)
    S.capOn = false
    local list = {}
    for k, v in pairs(S.tally) do list[#list + 1] = { k = k, v = v } end
    table.sort(list, function(a, b) return a.v > b.v end)
    local top = list[1]
    local tops = {}
    for i = 1, math.min(3, #list) do tops[#tops + 1] = list[i].k .. " (" .. math.floor(list[i].v) .. ")" end
    if not top then S.check(false, S.tag .. ": nothing was drawn by the light draws (no fill caught)"); return end
    local r, g, b = string.match(top.k, "([%d.]+),([%d.]+),([%d.]+)")
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    local L = S.LIGHT
    local light = S.near(L.surf1, r, g, b, 0.03) or S.near(L.surf2, r, g, b, 0.03) or S.near(L.surf3, r, g, b, 0.03)
    S.check(light, S.tag .. ": the fill is the tooltips' light grey (" .. table.concat(tops, ", ") .. ")")
    if wantWash then S.check((S.wash or 0) > 0, S.tag .. ": the hover wash is the light palette's faint dark line (" .. tostring(S.wash) .. " rects)") end
end

-- ---------------------------------------------------------------- set up
S.THEMES = { "dark", "light", "hicon" }
S.WANT = { HUNGER = 0.45, THIRST = 0.45, FATIGUE = 0.75 }
function S.setStats(bump)
    local st = S.p:getStats()
    for k, v in pairs(S.WANT) do pcall(function() st:set(CharacterStat[k], v + (bump or 0)) end) end
end
S.step(10, function()
    local p, St = S.p, S.St
    S.look = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize }
    S.was = {
        place = St.moodlePlaceOption and St.moodlePlaceOption:getValue(), bar = St.actionBarOption and St.actionBarOption:getValue(),
        notices = St.moodleNoticesOption and St.moodleNoticesOption:getValue(), god = p:isGodMod(),
        catch = St.messagesCatchOption and St.messagesCatchOption:getValue(), toast = St.messagesToastOption and St.messagesToastOption:getValue(),
        speed = getGameSpeed(), stats = {}, halo = St.haloBubbleOption and St.haloBubbleOption:getValue(),
    }
    pcall(function() S.was.zda = p:isZombiesDontAttack() end)
    for k, _ in pairs(S.WANT) do pcall(function() S.was.stats[k] = p:getStats():get(CharacterStat[k]) end) end
    if ZeD_CharacterWindow.isOpen(S.pn) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn); S.closed = true end
    if getGameSpeed() ~= 1 then if ZEDQA_SPEED then ZEDQA_SPEED(1) else setGameSpeed(1) end end
    pcall(function() St.moodleNoticesOption:setValue(2) end)
    pcall(function() p:setZombiesDontAttack(true) end)
    pcall(function() p:setGodMod(false) end)   -- (god mode holds the stats at zero)
    S.wrap()
    S.console()
    local w = 0; pcall(function() w = S.inv:getCapacityWeight() end)
    S.say(string.format("start: carried %.1f of %s kg%s", w, tostring(p:getMaxWeight()), (w > 19) and " (OVER: run gallery_unload.lua first)" or ""))
end)

-- ---------------------------------------------------------------- the moodle note and its hover
function S.layer() return S.MO.getLayer(S.pn) end
function S.hoverMoodle(on)
    local L = S.layer()
    if not L then return end
    if not on then L.getMouseX, L.getMouseY, L.isMouseOver = nil, nil, nil; return end
    local s = L._size or 32
    local lx, ly = s / 2, s + 10 + s / 2
    if L._mode == "bottom" then lx, ly = s + 10 + s / 2, s / 2 end
    L.getMouseX = function() return lx end
    L.getMouseY = function() return ly end
    L.isMouseOver = function() return true end
end
function S.mood(theme)
    for _, place in ipairs({ { 2, "left" }, { 3, "bottom" }, { 1, "right" } }) do
        local tag = theme .. "_mood_" .. place[2]
        S.step(10, function() pcall(function() S.St.moodlePlaceOption:setValue(place[1]) end); S.setStats() end)
        S.step(60, function() S.setStats(0.08); S.start(tag .. "_note"); S.t = 0 end)   -- (a change: the note comes by itself)
        S.step(5, function()
            S.t = S.t + 1
            local L = S.layer()
            if not (L and L._chip) and S.t < 60 then return true end
            if not (L and L._chip) then S.say("not run: " .. tag .. "_note (no note came)"); S.capOn = false; return end
        end)
        S.step(30, function() if S.capOn then S.shot("lpp_" .. tag .. "_note"); S.judge(false) end end)
        S.step(5, function() S.setStats(); S.hoverMoodle(true); S.start(tag); S.t = 0 end)
        S.step(5, function()
            S.t = S.t + 1
            local L = S.layer()
            local c = L and L._chip
            if not (c and c.idx == 2) and S.t < 60 then return true end
            if not (c and c.idx == 2) then S.say("not run: " .. tag .. " (no hover balloon on moodle 2)"); S.capOn = false end
        end)
        S.step(30, function() if S.capOn then S.shot("lpp_" .. tag); S.judge(false) end end)
        S.step(2, function() S.hoverMoodle(false) end)
    end
    S.step(10, function()
        local st = S.p:getStats()
        for k, v in pairs(S.was.stats) do pcall(function() st:set(CharacterStat[k], v) end) end
    end)
end

-- ---------------------------------------------------------------- the action bar
function S.barSt() local l = S.AB._layers and S.AB._layers[S.pn]; return l and l._drawSt end
function S.give(ft) local it = S.inv:AddItem(ft); if it then S.given[#S.given + 1] = it end; return it end
function S.stopAll() pcall(function() S.p:StopAllActionQueue() end) end
-- waits (5 frames a poll, up to n polls) until the bar's phase is want, then takes the picture and judges it
function S.barShot(tag, want, n)
    S.step(2, function() S.t = 0; S.start(tag) end)
    S.step(5, function()
        S.t = S.t + 1
        local st = S.barSt()
        if not (st and st.phase == want) and S.t < n then return true end
        if not (st and st.phase == want) then S.say("not run: " .. tag .. " (the bar's phase is " .. tostring(st and st.phase) .. ", not " .. want .. ")"); S.capOn = false; return end
        S.shot("lpp_" .. tag)
        S.judge(false)
    end)
end
function S.bar(theme)
    for _, b in ipairs({ { 2, "simple" }, { 1, "detailed" } }) do
        local tag = theme .. "_" .. b[2]
        S.step(10, function() pcall(function() S.St.actionBarOption:setValue(b[1]) end); S.stopAll() end)
        -- reading, then stopped
        S.step(10, function()
            S.book = S.book or S.give("Base.Book")
            if S.book then pcall(function() ISTimedActionQueue.add(ISReadABook:new(S.p, S.book)) end) end
        end)
        S.step(60, function() end)
        S.barShot(tag .. "_read", "work", 60)
        S.step(5, function() S.stopAll() end)
        S.barShot(tag .. "_stopped", "stopped", 20)
        -- resting (no end: its icon)
        S.step(90, function() pcall(function() ISTimedActionQueue.add(ISRestAction:new(S.p, nil, true)) end) end)
        S.step(60, function() end)
        S.barShot(tag .. "_rest", "work", 60)
        S.step(5, function() S.stopAll() end)
        -- an apple eaten to the end: done
        S.step(90, function()
            local a = S.give("Base.Apple")
            if a then pcall(function() ISTimedActionQueue.add(ISEatFoodAction:new(S.p, a, 0.25)) end) end
        end)
        S.barShot(tag .. "_done", "done", 600)
        S.step(60, function() S.stopAll() end)
    end
end

-- ---------------------------------------------------------------- the notice balloons
S.RADIO, S.FARM = "Sample Radio Plus", "Sample Farm Map"
function S.noop() end
function S.note(src, text, rich)
    S.MS.qaSource = src
    local d
    if rich then d = ISModalRichText:new(0, 0, 420, 300, text, false, {}, S.noop, S.pn)
    else d = ISModalDialog:new(0, 0, 320, 150, text, false, {}, S.noop, S.pn) end
    d:initialise(); d:addToUIManager()
    S.MS.qaSource = nil
end
function S.toastLayer()
    local found
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local t = nil
            pcall(function() t = ui:get(i):getTable() end)
            if type(t) == "table" and t.Type == "ZeD_MessagesToasts" and t._boxes and #t._boxes > 0 then found = t end
        end
    end)
    return found
end
function S.hoverToast(on)
    local t = S.toastLayer()
    if not on then
        if S.hovered then S.hovered.getMouseX, S.hovered.getMouseY, S.hovered.isMouseOver = nil, nil, nil end
        S.hovered = nil
        return t ~= nil
    end
    if not t then return false end
    local b = t._boxes[#t._boxes]
    local mx, my = b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)
    t.getMouseX = function() return mx end
    t.getMouseY = function() return my end
    t.isMouseOver = function() return true end
    S.hovered = t
    return true
end
function S.clearNotes() S.MS.sources, S.MS.toasts = {}, {} end
S.GB = { file = "ZeD_guidebubble.txt" }
function S.gbFlag(s) pcall(function() local w = getFileWriter(S.GB.file, true, false); w:write(s or ""); w:close() end) end
function S.notices(theme)
    -- a mod's note out of the belt
    S.step(10, function()
        S.clearNotes()
        pcall(function() S.St.messagesCatchOption:setValue(2); S.St.messagesToastOption:setValue(2) end)
        S.note(S.RADIO, "Sample Radio Plus: your saved stations were moved to the new list.")
    end)
    S.step(30, function()
        S.note(S.FARM, "<H1> Welcome to Sample Farm <LINE> <TEXT> The farmhouse keys are in the mailbox by the road. The barn's generator needs fuel before the first winter.", true)
        S.start(theme .. "_notice_mod")
    end)
    S.step(30, function() S.shot("lpp_" .. theme .. "_notice_mod"); S.judge(false) end)
    S.step(2, function() if not S.hoverToast(true) then S.say("not run: " .. theme .. "_notice_mod_hover (no balloon on screen)") end; S.start(theme .. "_notice_mod_hover") end)
    S.step(30, function() S.shot("lpp_" .. theme .. "_notice_mod_hover"); S.judge(S.hovered ~= nil); S.hoverToast(false) end)
    -- the guide's offer
    S.step(10, function()
        local G = ZeD.GuideBubble
        S.clearNotes()
        if not (G and ZeD.Guide) then S.say("not run: " .. theme .. "_notice_guide (the guide bubble is not loaded)"); return end
        S.GB.const = S.GB.const or { G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS }
        if S.GB.flag == nil then
            S.GB.flag = ""
            pcall(function() local r = getFileReader(S.GB.file, false); if r then S.GB.flag = r:readLine() or ""; r:close() end end)
            S.GB.option = getCore():getOptionShowSurvivalGuide()
        end
        G.FIRST_MS = 1500
        S.gbFlag("")
        getCore():setOptionShowSurvivalGuide(true)
        G.start()
        S.t = 0
    end)
    S.step(10, function()
        local G = ZeD.GuideBubble
        if not G then return end
        S.t = S.t + 1
        local up = false
        for _, x in ipairs(S.MS.toasts or {}) do if x.source == G.head() then up = true end end
        if not up and S.t < 120 then return true end
        if not up then S.say("not run: " .. theme .. "_notice_guide (the offer never came up)"); return end
        S.start(theme .. "_notice_guide")
        S.guideUp = true
    end)
    S.step(40, function() if S.guideUp then S.shot("lpp_" .. theme .. "_notice_guide"); S.judge(false) end end)
    S.step(2, function() if S.guideUp then S.hoverToast(true); S.start(theme .. "_notice_guide_hover") end end)
    S.step(30, function()
        if S.guideUp then S.shot("lpp_" .. theme .. "_notice_guide_hover"); S.judge(S.hovered ~= nil) end
        S.hoverToast(false)
        S.guideUp = false
        S.guideEnd()
    end)
end
function S.guideEnd()
    local G = ZeD.GuideBubble
    if not (G and S.GB.const) then return end
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = S.GB.const[1], S.GB.const[2], S.GB.const[3], S.GB.const[4]
    G.st = nil
    S.gbFlag(S.GB.flag or "")
    pcall(function() getCore():setOptionShowSurvivalGuide(S.GB.option) end)
    S.clearNotes()
end

-- ---------------------------------------------------------------- over the head: speech, speed and pause, halo notes
-- (ZeD_ActionBar render: drawOverhead inside ZeD.Balloon.inLight; Bubbles.drawSpeech, Bubbles.drawNotes. A halo note's
-- status mark is LIGHT.danger for a red note, LIGHT.positive for a green one; the notes need ZeD setup's Overhead notes on.)
function S.hasColor(c)
    for k, _ in pairs(S.was.lastTally or {}) do
        local r, g, b = string.match(k, "([%d.]+),([%d.]+),([%d.]+)")
        if S.near(c, tonumber(r), tonumber(g), tonumber(b), 0.03) then return true end
    end
    return false
end
function S.judgeMark(c, what)
    S.was.lastTally = S.tally
    S.judge(false)
    S.check(S.hasColor(c), S.tag .. ": the " .. what .. " note keeps its color (" .. string.format("%.2f,%.2f,%.2f", c.r, c.g, c.b) .. " drawn)")
end
function S.speed(n) local sp = ZEDQA_SPEED or setGameSpeed; pcall(sp, n) end
function S.halo(text, red)
    local H = HaloTextHelper
    if not H then return false end
    local col
    pcall(function() col = red and H.getColorRed() or H.getColorGreen() end)
    local ok = pcall(function() H.addTextWithArrow(S.p, text, red and false or true, col) end)
    if not ok then ok = pcall(function() H.addText(S.p, text, col) end) end
    return ok
end
function S.overhead(theme)
    S.step(10, function()
        S.stopAll()
        pcall(function() S.St.haloBubbleOption:setValue(2) end)
        S.speed(1)
        S.p:Say("Is anyone out there? I have food and water.")
        S.start(theme .. "_speech")
    end)
    S.step(40, function() S.shot("lpp_" .. theme .. "_speech"); S.judge(false) end)
    S.step(300, function() S.speed(2); S.start(theme .. "_speed") end)   -- (the line runs out first)
    S.step(40, function() S.shot("lpp_" .. theme .. "_speed"); S.judge(false) end)
    S.step(10, function()
        S.speed(0)
        S.start(theme .. "_pause")
        S.pauseT = getTimestampMs()
    end)
    S.step(40, function()
        -- (the queue steps on drawn frames, which still come while paused: this step running proves it)
        S.say(theme .. " pause: the queue still steps while paused (" .. (getTimestampMs() - S.pauseT) .. " ms on, speed " .. tostring(getGameSpeed()) .. ")")
        S.shot("lpp_" .. theme .. "_pause"); S.judge(false)
        S.speed(1)
    end)
    S.step(30, function()
        if not S.halo("Too heavy", true) then S.say("not run: " .. theme .. "_halo_red (no HaloTextHelper)") end
        S.start(theme .. "_halo_red")
    end)
    S.step(40, function() S.shot("lpp_" .. theme .. "_halo_red"); S.judgeMark(S.LIGHT.danger, "red") end)
    S.step(10, function()
        pcall(function() S.Bb._notes[S.pn] = {} end)
        if not S.halo("Learned a new recipe", false) then S.say("not run: " .. theme .. "_halo_green (no HaloTextHelper)") end
        S.start(theme .. "_halo_green")
    end)
    S.step(40, function() S.shot("lpp_" .. theme .. "_halo_green"); S.judgeMark(S.LIGHT.positive, "green") end)
    S.step(10, function()
        pcall(function() S.Bb._notes[S.pn] = {} end)
        pcall(function() S.St.haloBubbleOption:setValue(S.was.halo) end)
    end)
end

-- ---------------------------------------------------------------- the run: each theme
for _, theme in ipairs(S.THEMES) do
    S.step(20, function()
        S.stopAll()
        pcall(function() ZeD.applyTheme(theme, S.look[2], S.look[3]) end)
        S.say("theme " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent))
    end)
    S.step(40, function() end)
    S.mood(theme)
    S.bar(theme)
    S.notices(theme)
    S.overhead(theme)
end

-- ---------------------------------------------------------------- put back
S.step(20, function()
    S.capOn = false
    S.hoverMoodle(false); S.hoverToast(false)
    S.stopAll()
    S.unwrap()
    S.guideEnd()
    for _, it in ipairs(S.given) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    local St, w = S.St, S.was
    pcall(function() St.moodlePlaceOption:setValue(w.place) end)
    pcall(function() St.actionBarOption:setValue(w.bar) end)
    pcall(function() St.moodleNoticesOption:setValue(w.notices) end)
    pcall(function() St.haloBubbleOption:setValue(w.halo) end)
    pcall(function() S.Bb._notes[S.pn] = {} end)
    pcall(function() St.messagesCatchOption:setValue(w.catch); St.messagesToastOption:setValue(w.toast) end)
    local st = S.p:getStats()
    for k, v in pairs(w.stats) do pcall(function() st:set(CharacterStat[k], v) end) end
    pcall(function() ZeD.applyTheme(S.look[1], S.look[2], S.look[3]) end)
end)
S.step(20, function()
    pcall(function() S.p:setGodMod(S.was.god == true) end)
    pcall(function() S.p:setZombiesDontAttack(S.was.zda == true) end)
    if S.closed and not ZeD_CharacterWindow.isOpen(S.pn) then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end
    local sp = ZEDQA_SPEED or setGameSpeed
    pcall(sp, S.was.speed or 1)
    S.say("put back: theme " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. ", options, stats, actions, things, draws")
    S.say(S.passes .. " passed, " .. S.fails .. " failed")
    S.say("DONE")
end)

-- (stepped on each drawn frame; a step returning true runs again after n frames)
function S.tick()
    local s = S.Q[S.qi]
    if not s then Events.OnPreUIDraw.Remove(S.tick); return end
    S.wait = (S.wait or s.n) - 1
    if S.wait > 0 then return end
    S.wait = nil
    local ok, r = pcall(s.fn)
    if not ok then S.say("ERR step " .. S.qi .. ": " .. tostring(r)) end
    if ok and r == true then return end
    S.qi = S.qi + 1
end
Events.OnPreUIDraw.Add(S.tick)
S.say("start (" .. #S.Q .. " steps)")
