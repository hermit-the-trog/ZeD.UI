-- ZeDUI/tools/qa/mp_tk_mouse.lua  (Nov 6 2026, QA): the ticket cards with the real mouse on the real server: Ask, a kind, Include where I am, the field, Send; then the queue:
-- a row, Take it, the answer field, Answer, a filter's pop-up, Refresh, back. Each press goes through release_check_mouse.ps1 (zedqa_click.txt) and can take 7 s to land.
-- Words go in with queueCharEvent, the way ZeD's keyboard types. grep "ZEDQA mtm". Pictures: mtm_*.png.
local function say(s) print("ZEDQA mtm " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local S, K, TC = ZeD.ServerPart, ZeD.Tickets, ZeD.TicketCards
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local CW, WW = CWm.getWindow, WWm.getWindow
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("mtm_" .. n .. ".png") end) end
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local PRESS = 7000
local ST, AT = ZeD.ServerTab, ZeD.AdminTab
local function stopsOf(win, def)
    return def.buildFocusables(win)
end
-- a press on a stop, by its id, in the panel's coordinates
local function press(getWin, def, id, label)
    add(400, function()
        local w = getWin()
        local e
        for _, x in ipairs(stopsOf(w, def)) do if x.id == id then e = x end end
        pass("the stop for " .. label, e ~= nil, id)
        if not e then return end
        local panel = w._drawerPanel or w
        -- (a foot button's stop is said to lie under the list, for Down: the button itself is in footRects)
        local st = (def == ST) and w._serverTab or w._adminTab
        for _, rc in ipairs(st.tk and st.tk.footRects or {}) do
            if "tk:" .. tostring(rc.b.id) == id then e = { x = rc.x, y = rc.y, w = rc.w, h = rc.h } end
        end
        local x = math.floor(panel:getAbsoluteX() + e.x + (e.w or 20) / 2)
        local y = math.floor(panel:getAbsoluteY() + e.y + (e.h or 10) / 2)
        say(label .. " at " .. x .. "," .. y)
        req("left " .. x .. " " .. y)
    end)
    add(PRESS, function() end)
end
local function typeInto(win, key, words)
    add(300, function()
        local box = win()._tkFields and win()._tkFields[key]
        local inner = box and (box._entry or box.input)
        local focused = inner ~= nil and inner:isFocused()
        pass("the click puts the cursor in " .. key, focused)
        for c = 1, #words do queueCharEvent(words:sub(c, c)) end
    end)
    add(800, function() end)
end

add(600, function()
    local u = UIManager.getUI()
    for k = 0, u:size() - 1 do local e = u:get(k); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    nolimits()
    S.hello()
end)
add(1200, function() CWm.openTab(0, "server") end)
add(2000, function() shot("server") end)
press(CW, ST, "srv:ask", "Ask the admins")
add(500, function() pass("the Ask card is up", CW()._serverTab.card and CW()._serverTab.card.kind == "ask"); shot("ask") end)
press(CW, ST, "tk:k:GRIEF", "the kind Griefing")
press(CW, ST, "tk:here", "Include where I am")
add(500, function() shot("ask_picked") end)
press(CW, ST, "tk:f:ask", "the words field")
typeInto(CW, "ask", "someone took my wheels")
add(800, function() shot("ask_typed") end)
press(CW, ST, "tk:send", "Send")
add(1500, function()
    pass("back on the tab", CW()._serverTab.card == nil)
    local r = K.mine[1]
    pass("the ticket is in my list", r and r.kind == "GRIEF", r and r.last)
    TK = r and r.id
    shot("sent")
    WWm.openTab(0, "admin")
    nolimits()
end)
add(5000, function() shot("queue") end)
add(300, function() END_ID = "adm:tk:t:" .. tostring(TK) end)
add(300, function()
    local w = WW()
    local e
    for _, x in ipairs(stopsOf(w, AT)) do if x.id == END_ID then e = x end end
    pass("the row", e ~= nil, END_ID)
    if e then
        local panel = w._drawerPanel or w
        req("left " .. math.floor(panel:getAbsoluteX() + e.x + (e.w or 20) / 2) .. " " .. math.floor(panel:getAbsoluteY() + e.y + (e.h or 10) / 2))
    end
end)
add(PRESS, function() end)
add(1000, function()
    pass("the card opened", WW()._adminTab.card ~= nil and WW()._adminTab.card.kind == "staff")
    pass("Seen", K.card and K.card.status == "Seen", K.card and K.card.status)
    shot("card")
end)
press(WW, AT, "tk:take", "Take it")
add(800, function() pass("taken", K.card and K.card.status == "Progress", K.card and K.card.status) end)
press(WW, AT, "tk:f:answer", "the answer field")
typeInto(WW, "answer", "on my way")
add(800, function() shot("card_typed") end)
press(WW, AT, "tk:ans", "Answer")
add(1200, function()
    pass("answered", K.card and K.card.status == "Answered", K.card and K.card.status)
    shot("answered")
end)
press(WW, AT, "tk:back", "the back key")
add(800, function() pass("back on the queue", WW()._adminTab.card == nil) end)
press(WW, AT, "adm:tk:pop:kind", "the Kind filter")
add(600, function()
    local t = WW()._adminTab.tk
    pass("its pop-up is up", t and t.popup ~= nil)
    shot("pop")
end)
add(300, function()
    local t = WW()._adminTab.tk
    local z = t and t.popup and t.popup.zones and t.popup.zones[3]
    if z then
        local w = WW()
        local panel = w._drawerPanel or w
        req("left " .. math.floor(panel:getAbsoluteX() + z.x + z.w / 2) .. " " .. math.floor(panel:getAbsoluteY() + z.y + z.h / 2))
    end
end)
add(PRESS, function()
    local t = WW()._adminTab.tk
    pass("a pick closes it and filters", t and t.popup == nil, t and t.q and t.q.kind)
    nolimits()
    shot("filtered")
end)
add(500, function() K.closeQueue(); say("DONE") end)

local function drive()
    local stp = plan[i]
    if not stp then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < stp.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(stp.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
