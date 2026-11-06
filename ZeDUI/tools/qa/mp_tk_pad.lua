-- ZeDUI/tools/qa/mp_tk_pad.lua  (Nov 5 2026, QA): Part D steps 8 and 9 under a controller on the real server, with no pad here: the rig's pad mode is locked, A goes
-- through Focus.qaButton, D-pad through Focus.dispatchJoypadDir, and getJoypadData is stood in for so ZeD's keyboard opens the way a real pad opens it. The walk goes
-- Ask, kind, the field, the keyboard, Accept, Send, back; then the Admin tab: a ticket arriving live, its card, the answer field, Answer, back. grep "ZEDQA mtp".
-- Pictures: mtp_*.png. A first-press check of the walk 1 refusal from mp_tk_a.lua sits at the end.
local function say(s) print("ZEDQA mtp " .. tostring(s)) end
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
local function shot(n) pcall(function() getCore():TakeFullScreenshot("mtp_" .. n .. ".png") end) end

local realJd, realFocus = getJoypadData, updateJoypadFocus
local jd = { player = 0, id = 0, focus = nil }
local function stubPad(on)
    if on then
        getJoypadData = function() return jd end
        updateJoypadFocus = function() end
    else
        getJoypadData, updateJoypadFocus = realJd, realFocus
    end
end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function liveId(w)
    local e = Focus.liveElement and Focus.liveElement(w)
    return e and e.id
end
local function stops(w)
    local out = {}
    for _, z in ipairs(w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do out[#out + 1] = tostring(z.zone) .. "/" .. tostring(e.id) end
    end
    return out
end
local function goTo(w, pred)
    for _, z in ipairs(w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do
            if pred(tostring(e.id)) then return Focus.focusWhere(w, z.zone, function(x) return x.id == e.id end) ~= false, e.id end
        end
    end
    return false
end
local function pressA(w)
    add(60, function() Focus.qaButton("A", true); Focus.dispatchJoypadDown(w(), Joypad.AButton, nil) end)
    add(120, function() Focus.qaButton("A", false) end)
    add(200, function() Focus.qaButton("A", nil) end)
end
local function pick(w, pred, label)
    add(350, function()
        local ok, id = goTo(w(), pred)
        pass("the stop for " .. label, ok, id)
    end)
    pressA(w)
end

add(1000, function()
    nolimits(); S.hello()
    Focus.qaButton("A", nil)
end)
add(1200, function() CWm.openTab(0, "server") end)   -- (the windows first: they aren't built until they open, and not under the stood-in pad)
add(1500, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    stubPad(true)
end)
add(1500, function() local w = CW(); Focus.claimFocus(w); say("server stops: " .. table.concat(stops(w), " ")); shot("server") end)
pick(CW, function(id) return id:find("ask", 1, true) ~= nil end, "Ask the admins")
add(1200, function()
    local w = CW()
    pass("the Ask card opened", w._serverTab and w._serverTab.card and w._serverTab.card.kind == "ask")
    say("ask stops: " .. table.concat(stops(w), " "))
    say("landed on " .. tostring(liveId(w)))
    shot("ask")
end)
for n = 1, 12 do
    add(150, function()
        local w = CW()
        pcall(Focus.dispatchJoypadDir, w, "down", nil)
        say("Down " .. n .. ": " .. tostring(liveId(w)))
    end)
end
for n = 1, 12 do add(120, function() pcall(Focus.dispatchJoypadDir, CW(), "up", nil) end) end
add(300, function() say("back up at " .. tostring(liveId(CW()))) end)
pick(CW, function(id) return id:find("BUG", 1, true) ~= nil or id:find("bug", 1, true) ~= nil end, "the kind Bug")
add(600, function() shot("ask_kind") end)
pick(CW, function(id) return id:find("field", 1, true) ~= nil or id:find(":ask", 1, true) ~= nil and id:find("back", 1, true) == nil end, "the words field")
add(900, function()
    local k = ZeD.Keyboard and ZeD.Keyboard.instance
    pass("A on the field opens the keyboard", k ~= nil and k:isVisible(), k and tostring(k:isVisible()))
    pass("one RT ends the typing", k and k._multi == false, k and tostring(k._multi))
    pass("the window has the pad back after", k and k.prevFocus == CW())
    if k then
        for _, ch in ipairs({ "s", "t", "u", "c", "k" }) do k:pressKey({ lo = ch, up = ch }) end
    end
end)
add(900, function()
    local k = ZeD.Keyboard.instance
    local b = k and k.textEntryBox
    say("typed: " .. tostring(b and b:getText()))
    pass("the keys reach the field", b and b:getText() == "stuck", b and b:getText())
    local kbTop = k and k:getY()
    local fy = b and b:getAbsoluteY()
    local fb = fy and (fy + b:getHeight())
    say("keyboard top " .. tostring(kbTop) .. ", the field " .. tostring(fy) .. " to " .. tostring(fb))
    pass("the field stays clear of the keyboard", fb and kbTop and fb <= kbTop, tostring(fb) .. " under " .. tostring(kbTop))
    shot("keyboard")
    if k then k:enter() end
end)
add(900, function()
    local k = ZeD.Keyboard.instance
    pass("Accept closes it", not (k and k:isVisible()))
    pass("the words stay", TC and CW()._tkFields and CW()._tkFields.ask ~= nil)
    say("focus on " .. tostring(liveId(CW())))
    shot("after_keyboard")
end)
pick(CW, function(id) return id:find("send", 1, true) ~= nil end, "Send")
add(1800, function()
    local w = CW()
    pass("back on the Server tab after Send", w._serverTab and w._serverTab.card == nil)
    say("focus on " .. tostring(liveId(w)))
    shot("sent")
    pass("the new ticket is in my list", K.mine[1] and tostring(K.mine[1].last):find("stuck", 1, true) ~= nil, K.mine[1] and K.mine[1].last)
    MINE = K.mine[1] and K.mine[1].id
end)
add(2000, function() Focus.releaseFocus() end)

-- the Admin tab, open: a ticket arrives while it is on screen
add(1000, function() WWm.openTab(0, "admin"); nolimits() end)
add(800, function() WW()._adminTab.screen = "tickets" end)   -- (Nov 6 2026: the queue has a screen of its own now)
add(5000, function() local w = WW(); Focus.claimFocus(w); say("admin stops: " .. table.concat(stops(w), " ")); shot("admin"); QN = K.queue and K.queue.n end)
add(300, function() addTicket("qa_live", "qa: arrives with the tab open", -1) end)
add(9000, function()
    local found
    for _, r in ipairs(K.queue and K.queue.rows or {}) do if r.author == "qa_live" then found = r end end
    pass("a ticket from the game's window shows live, on the tab", found ~= nil, K.queue and K.queue.n)
    shot("admin_live")
end)
add(5000, function()
    local found
    for _, r in ipairs(K.queue and K.queue.rows or {}) do if r.author == "qa_live" then found = r end end
    say("14 s on: found " .. tostring(found ~= nil) .. ", the tab's label: " .. tostring(TC.tabLabel and TC.tabLabel("Admin")))
    nolimits()
end)
pick(WW, function(id) return MINE ~= nil and id:find("t:" .. tostring(MINE), 1, true) ~= nil end, "my ticket's row")
add(1500, function()
    local w = WW()
    pass("the staff card opened", w._adminTab and w._adminTab.card and w._adminTab.card.kind == "staff")
    say("card stops: " .. table.concat(stops(w), " "))
    say("landed on " .. tostring(liveId(w)))
    shot("card")
end)
pick(WW, function(id) return id:find("answer", 1, true) ~= nil and id:find("btn", 1, true) == nil end, "the answer field")
add(900, function()
    local k = ZeD.Keyboard.instance
    pass("the keyboard on the answer", k and k:isVisible())
    if k then for _, ch in ipairs({ "o", "k" }) do k:pressKey({ lo = ch, up = ch }) end end
end)
add(700, function()
    local k = ZeD.Keyboard.instance
    local b = k and k.textEntryBox
    local kbTop, fy = k and k:getY(), b and b:getAbsoluteY()
    local fb = fy and (fy + b:getHeight())
    say("keyboard top " .. tostring(kbTop) .. ", the field " .. tostring(fy) .. " to " .. tostring(fb))
    pass("the answer stays clear of the keyboard", fb and kbTop and fb <= kbTop, tostring(fb) .. " under " .. tostring(kbTop))
    shot("card_keyboard")
    if k then k:enter() end
end)
add(900, function() say("focus on " .. tostring(liveId(WW()))); shot("card_typed"); nolimits() end)
pick(WW, function(id) return id == "tk:ans" end, "the Answer button")
add(1500, function()
    say("the card: " .. tostring(K.card and K.card.status))
    shot("answered")
end)
add(800, function()
    pcall(Focus.dispatchJoypadDown, WW(), Joypad.BButton, nil)
end)
add(1200, function()
    local w = WW()
    say("after B: card " .. tostring(w._adminTab and w._adminTab.card ~= nil) .. ", focus on " .. tostring(liveId(w)))
    shot("back")
end)

-- walk 1 of mp_tk_a.lua, with room to answer
add(800, function() Focus.releaseFocus(); nolimits() end)
local fresh
add(500, function() K.ask("BUG", false, "qa: walk one again", function(a) fresh = a and a.id end) end)
add(1500, function() nolimits(); K.closeCard(); K.openCard(fresh) end)
local acks = {}
local function tap(module, command, args) if module == "ZeDT" and command == "t_ack" and args.rid == 7001 then acks[#acks + 1] = args end end
add(1000, function() Events.OnServerCommand.Add(tap); nolimits() end)
add(300, function() S.send("ZeDT", "t_reopen", { id = fresh, rid = 7001 }) end)
add(1500, function()
    Events.OnServerCommand.Remove(tap)
    pass("t_reopen on a Seen ticket answers state", acks[1] and acks[1].err == "state", acks[1] and acks[1].err)
    K.closeCard()
    K.closeQueue()
    stubPad(false)
    Det.setLockedMode(nil)
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
