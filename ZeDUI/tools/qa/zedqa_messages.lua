-- ZeDUI/tools/qa/zedqa_messages.lua  (Oct 24 2026)
-- Messages (MESSAGES_SPEC.md): another mod's notes kept in one window, its
-- questions still asked (and copied), errors filed per mod, the toast, the
-- belt's envelope, the window's buttons (mouse and controller), the per-mod
-- pop-up switch, Clear. The other mod is a test source (ZeD.Messages.qaSource);
-- one Lua error is made on purpose (expect= in the manifest).
-- Everything is put back: the store emptied, the switch off, the window shut.
-- grep "ZEDQA msg".
local p = getPlayer()
local pn = p:getPlayerNum()
local MS, MW, P = ZeD.Messages, ZeD.MessagesWindow, ZeD.Prompt
local function say(s) print("ZEDQA msg " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_msg_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

if not (MS and MW and P) then say("ERR ZeD.Messages is not loaded"); say("DONE"); return end

local SRC = "QA Mod"
local calls = { note = 0, rich = 0, coll = 0, ask = 0 }
local target = {}
local function onNote() calls.note = calls.note + 1 end
local function onRich() calls.rich = calls.rich + 1 end
local function onColl() calls.coll = calls.coll + 1 end
local function onAsk(_, button) calls.ask = calls.ask + 1; calls.askAnswer = button and button.internal end
local catchWas = ZeD.Settings.messagesCatchOption and ZeD.Settings.messagesCatchOption:getValue()
local toastWas = ZeD.Settings.messagesToastOption and ZeD.Settings.messagesToastOption:getValue()
local function lampBox()
    local hud = ZeD.Belt and ZeD.Belt._hud
    for _, b in ipairs(hud and hud._boxes or {}) do if b.kind == "lamp" then return b end end
    return nil
end
local function onScreen(o) return o and o.javaObject and o:isReallyVisible() or false end

step(10, function()
    MS.sources, MS.toasts = {}, {}
    pcall(function() ZeD.Settings.messagesCatchOption:setValue(2); ZeD.Settings.messagesToastOption:setValue(2) end)
    MS.setPopups(SRC, false)
    MS.qaSource = SRC
    check(lampBox() == nil, "nothing kept: no envelope on the belt")
end)

-- a note (one OK) from another mod: kept, not shown, a toast, the envelope with a count
local note, rich, coll
step(10, function()
    note = ISModalDialog:new(0, 0, 300, 150, "QA: a note from another mod.", false, target, onNote, pn)
    note:initialise()
    note:addToUIManager()
    rich = ISModalRichText:new(0, 0, 400, 300, "<H1> QA heading <LINE> <TEXT> A rich note from another mod. <LINE> <LINE> A second paragraph.", false, target, onRich, pn)
    rich:initialise()
    rich:addToUIManager()
    -- vanilla's collapsible rich-text note (Horse Mod's), and the mod pausing the game after it
    coll = ISCollapsableModalRichText:new(0, 0, 400, 300, "QA: a collapsible note; the mod pauses the game after it.", false, target, onColl, pn)
    coll:initialise()
    coll:addToUIManager()
    setGameSpeed(0)
end)
step(20, function()
    check(not onScreen(note) and not onScreen(rich) and not onScreen(coll), "the three notes are not on screen")
    check(note._zedCaught and rich._zedCaught and coll._zedCaught, "the three notes are kept in Messages")
    local s = MS.sources[SRC]
    check(s and #s.items == 3, "the source has three messages (" .. tostring(s and #s.items) .. ")")
    local un = MS.unread()
    check(un == 3, "three are new (" .. tostring(un) .. ")")
    check(#MS.toasts >= 1 and MS.toasts[#MS.toasts].source == SRC, "a toast names the mod")
    check(getGameSpeed() > 0, "the game runs on after the mod paused it for its note (speed " .. tostring(getGameSpeed()) .. ")")
end)
step(10, function()
    local b = lampBox()
    check(b ~= nil, "the envelope is on the belt")
    shot("belt_toast")
end)

-- a question from another mod: asked at once; its answer copied into Messages
local ask
step(10, function()
    ask = ISModalDialog:new(0, 0, 300, 150, "QA: a question from another mod?", true, target, onAsk, pn)
    ask:initialise()
    ask:addToUIManager()
end)
step(10, function()
    check(onScreen(ask), "a question still asks at once")
    ask:press(ask.yes)
end)
step(10, function()
    check(calls.ask == 1 and calls.askAnswer == "YES", "the mod got its answer (YES)")
    local s = MS.sources[SRC]
    local it = s and s.items[1]
    check(it and it.k == "ask" and it.read, "a copy of the question, already read, is in Messages")
end)

-- a Lua error (uncaught, in an event): filed under the source the trace names
local errBefore = 0
step(5, function()
    for _, s in pairs(MS.sources) do if s.kind == "err" then errBefore = errBefore + (s.items[1] and s.items[1].count or 0) end end
    MS.qaLog = true
    local function boom() Events.OnTick.Remove(boom); local t = nil; return t.qaMessagesError end
    Events.OnTick.Add(boom)
end)
step(200, function()
    local n = 0
    for _, s in pairs(MS.sources) do if s.kind == "err" then n = n + (s.items[1] and s.items[1].count or 0) end end
    MS.qaLog = nil
    check(n == errBefore + 1, "the one error is filed in Messages, counted once (" .. errBefore .. " -> " .. n .. ")")
end)

-- the window: the sources, the cards, the mod's own OK
local win
step(10, function()
    win = MW.open(pn, SRC)
end)
step(20, function()
    check(win and win:isReallyVisible() and win.sel == SRC, "Messages opens on the mod")
    local s = MS.sources[SRC]
    local un = 0
    for _, it in ipairs(s and s.items or {}) do if not it.read then un = un + 1 end end
    check(un == 0, "opening it marks the mod's messages read")
    local g = win._g
    check(g and #g.cards == 4, "four cards: three notes and the question (" .. tostring(g and #g.cards) .. ")")
    check(g and #g.btns == 3, "three OK buttons, one per note (" .. tostring(g and #g.btns) .. ")")
    shot("window_mod")
    -- the mouse: OK on the first card (the newest note: the collapsible one)
    local b = g and g.btns[1]
    if b then win:pressCard(b) end
end)
step(10, function()
    check(calls.coll == 1 and calls.note == 0 and calls.rich == 0, "OK ran that mod's callback once (" .. calls.coll .. "/" .. calls.note .. "/" .. calls.rich .. ")")
    -- the controller: into the cards, A on the next OK
    MW.qaJoy = true
    win:onJoypadDirRight()
    win:onJoypadDown(Joypad.AButton)
end)
step(10, function()
    check(calls.rich + calls.note == 1, "A on the next card's OK ran its callback")
    check(win.zone == "cards", "the controller is in the cards")
end)

-- the error source and the bug report text
step(10, function()
    local _, errs = MS.list()
    if check(#errs > 0, "the window lists an error source") then
        win:choose(errs[1].name)
        local r = MS.report(errs[1].name)
        check(r:find("errors", 1, true) ~= nil and #r > 40, "the bug report text names the errors (" .. #r .. " characters)")
    end
end)
step(20, function() shot("window_error") end)

-- the switch: this mod's notes as pop-ups again
local shown
step(10, function()
    MS.setPopups(SRC, true)
    shown = ISModalDialog:new(0, 0, 300, 150, "QA: shown as a pop-up.", false, target, onNote, pn)
    shown:initialise()
    shown:addToUIManager()
end)
step(10, function()
    check(onScreen(shown) and not shown._zedCaught, "with the switch on, the mod's note shows as a pop-up")
    shown:press(shown.ok)
    MS.setPopups(SRC, false)
end)

-- Clear: the mod's messages go; a kept note nobody answered is answered OK as it leaves
step(10, function()
    win:choose(SRC)
    local before = calls.note + calls.rich
    MS.clear(SRC)
    check(MS.sources[SRC] == nil, "Clear removes the mod's messages")
    check(calls.note + calls.rich == before + 1, "the last unanswered note got its OK as it left")
end)

-- put back
step(10, function()
    MS.qaSource = nil
    MW.qaJoy = nil
    if win then win:close() end
    MS.sources, MS.toasts = {}, {}
    pcall(function()
        if catchWas then ZeD.Settings.messagesCatchOption:setValue(catchWas) end
        if toastWas then ZeD.Settings.messagesToastOption:setValue(toastWas) end
    end)
    if getGameSpeed() == 0 then setGameSpeed(1) end
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
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
