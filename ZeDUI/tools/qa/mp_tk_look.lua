-- ZeDUI/tools/qa/mp_tk_look.lua  (Nov 6 2026, QA): what the card states run does not reach: the three filter pop-ups and Find under the pad on the real queue, where a
-- real answered card opens (the states' pictures show some scrolled past the first rows), and every theme and accent on the cards. grep "ZEDQA mtv". Pictures: mtv_*.png.
-- Lua/zedqa_tk_states.lua is a copy of mp_ticket_cards.lua, made by batch_tk_look.ps1: its states are used with ZEDQA_CARDS_SIM set.
local function say(s) print("ZEDQA mtv " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local me = p:getUsername()
local Tk, S, K, TC = ZeD.Tk, ZeD.ServerPart, ZeD.Tickets, ZeD.TicketCards
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local CW, WW = CWm.getWindow, WWm.getWindow
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("mtv_" .. n .. ".png") end) end
local realJd, realFocus = getJoypadData, updateJoypadFocus
local jd = { player = 0, id = 0 }

local function readAll(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local s, l = "", r:readLine()
    while l do s = s .. l .. string.char(10); l = r:readLine() end
    r:close()
    return s
end
ZEDQA_CARDS_SIM = true
local Q = loadstring(readAll("zedqa_tk_states.lua"), "states")()
ZEDQA_CARDS_SIM = nil
local states = Q.bind(TC, K, S, me)
local byName = {}
for _, s in ipairs(states) do byName[s.name] = s end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function liveId(w)
    local e = Focus.liveElement and Focus.liveElement(w)
    return e and e.id
end
local function goTo(w, pred)
    for _, z in ipairs(w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do
            if pred(tostring(e.id)) then Focus.focusWhere(w, z.zone, function(x) return x.id == e.id end); return e.id end
        end
    end
    return nil
end
local function pressA()
    add(60, function() Focus.qaButton("A", true); Focus.dispatchJoypadDown(WW(), Joypad.AButton, nil) end)
    add(120, function() Focus.qaButton("A", false) end)
    add(200, function() Focus.qaButton("A", nil) end)
end
local function pick(id)
    add(350, function() pass("the stop " .. id, goTo(WW(), function(x) return x == id end) ~= nil) end)
    pressA()
end
local function popup(key)
    pick("adm:tk:pop:" .. key)
    add(800, function()
        local t = WW()._adminTab.tk
        pass("the " .. key .. " pop-up opens", t and t.popup ~= nil and t.popup.key == key)
        say(key .. ": focus on " .. tostring(liveId(WW())))
        shot("pop_" .. key)
    end)
    add(200, function() pcall(Focus.dispatchJoypadDir, WW(), "down", nil) end)
    add(300, function() say(key .. ": Down to " .. tostring(liveId(WW()))) end)
    add(200, function() pcall(Focus.dispatchJoypadDown, WW(), Joypad.BButton, nil) end)
    add(800, function()
        local t = WW()._adminTab.tk
        pass("B closes it", t and t.popup == nil)
        say(key .. ": back on " .. tostring(liveId(WW())))
    end)
end

-- a few real tickets
add(1000, function() nolimits(); S.hello() end)
add(600, function() nolimits(); K.ask("BUG", true, "qa: answered, to see where its card opens", function(a) T1 = a and a.id end) end)
add(1500, function() nolimits(); K.openQueue({ status = "All" }) end)
add(4000, function() nolimits(); K.openCard(T1) end)
add(800, function() nolimits(); K.answer(T1, "qa: an answer with a line of some length so the card has a thread") end)
add(1200, function() K.closeCard(); K.closeQueue(); nolimits() end)
add(600, function() K.ask("GRIEF", true, "qa: open, to fill the list", function(a) T2 = a and a.id end) end)
add(1500, function()
    getJoypadData = function() return jd end
    updateJoypadFocus = function() end
    WWm.openTab(0, "admin")
end)
-- where a real answered card opens with the mouse
add(4000, function()
    local w = WW()
    TC.openStaff(w, w._adminTab, T1)
end)
add(1500, function()
    local t = WW()._adminTab.tk
    pass("mouse: an answered card opens at the top", t and (t.off or 0) == 0, t and t.off)
    shot("answered_mouse")
    TC.back(WW(), WW()._adminTab)
end)
add(1200, function() Det.setLockedMode(Det.MODE_GAMEPAD) end)
add(1200, function() Focus.claimFocus(WW()) end)   -- (a claim in the same tick as the mode change is lost)
add(800, function() end)
pick("adm:tk:s:All")
add(1500, function() end)
popup("kind")
popup("who")
popup("mine")
pick("adm:tk:find")
add(900, function()
    local k = ZeD.Keyboard.instance
    pass("the keyboard on Find", k and k:isVisible())
    if k then for _, ch in ipairs({ "g", "r", "i", "e", "f" }) do k:pressKey({ lo = ch, up = ch }) end end
end)
add(700, function() local k = ZeD.Keyboard.instance; if k then k:enter() end; nolimits() end)
add(2500, function()
    local n = K.queue and K.queue.n
    pass("Find filters", n == 0 or n == 1, n)
    shot("find")
    say("focus on " .. tostring(liveId(WW())))
end)
add(300, function()
    getJoypadData, updateJoypadFocus = realJd, realFocus
    Det.setLockedMode(nil)
    Focus.releaseFocus()
end)

-- every theme and accent, on the states
local function state(name, tag)
    local s = byName[name]
    add(200, function() if s.tab == "server" then CWm.openTab(0, "server") else WWm.openTab(0, "admin") end end)
    add(350, function()
        local win = (s.tab == "server") and CW() or WW()
        local st = (s.tab == "server") and win._serverTab or win._adminTab
        s.reset(win, st)
        s.run(win, st)
    end)
    add(650, function() shot(tag) end)
end
local St = ZeD.Settings
for _, base in ipairs(ZEDQA_TK_THEMES and St.baseKeys or {}) do
    add(200, function() ZeD.applyTheme(base, "teal", nil) end)
    state("ask-griefing", base .. "_ask")
    state("mine-open", base .. "_mine")
    state("queue-open", base .. "_queue")
    state("card-progress-notes", base .. "_card")
    state("card-confirm", base .. "_confirm")
    for _, ac in ipairs(St.accentKeys) do
        add(200, function() ZeD.applyTheme(base, ac, nil) end)
        state("queue-spam-admin", base .. "_" .. ac)
    end
end
add(300, function()
    ZeD.applyTheme("dark", "teal", nil)
    TC.qaHold, TC.qaRole, TC.qaGo, TC.qaStats, TC.qaLink = nil, nil, nil, nil, nil
    K.mine, K.one, K.queue, K.card, K.list = {}, {}, nil, nil, nil
    K.closeQueue()
    say("DONE")
end)

local function drive()
    local stp = plan[i]
    if not stp then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < stp.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(stp.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
