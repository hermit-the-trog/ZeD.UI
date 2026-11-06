-- ZeDUI/tools/qa/mp_two_admin.lua  (Nov 5 2026, QA): on the first client, the admin, with the second player on the server: the Server tab's player list, the
-- plain player's chat line and its name color, the Admin tab with that player picked. grep "ZEDQA m2a".
local function say(s) print("ZEDQA m2a " .. tostring(s)) end
local function check(ok, s) say((ok and "PASS " or "FAIL ") .. s) end
local C = ZeD.Chat
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(300, function() if not CWm.isOpen() then CWm.toggleBothPaired(0) end end)
add(2000, function()
    local c, w = CWm.getWindow(), WWm.getWindow()
    c._activeTab = "server"; c._drawerMode = "tab"; c._drawerOpen = true
    w._activeTab = "admin"; w._drawerMode = "tab"; w._drawerOpen = true
end)
add(3000, function()
    local c = CWm.getWindow()
    local st = c._serverTab
    local names = {}
    local list = getOnlinePlayers and getOnlinePlayers()
    if list then for k = 0, list:size() - 1 do names[#names + 1] = tostring(list:get(k):getUsername()) end end
    say("online by the game: " .. table.concat(names, ", "))
    check(#names >= 2, "two players on the server")
    say("chat lines " .. #C.lines)
    local found
    for _, l in ipairs(C.lines) do if tostring(l.text):find("plain player", 1, true) then found = l end end
    check(found ~= nil, "the plain player's line reached the admin's chat: " .. tostring(found and found.text))
    say("the plain player's name ink: " .. tostring(pcall(function() local k = C.nameInk("bob"); return string.format("%.2f,%.2f,%.2f", k.r, k.g, k.b) end)))
    local a = WWm.getWindow()._adminTab
    local picks = {}
    for _, hz in ipairs(a and a.hits or {}) do if hz.item and hz.item.k == "pick" then picks[#picks + 1] = hz end end
    say("admin rows " .. #picks)
    for _, hz in ipairs(picks) do
        if tostring(hz.item.name or hz.item.user or hz.item.label):find("bob", 1, true) then ZeD.AdminTab.onClick(WWm.getWindow(), hz.x + 2, hz.y + 2); say("bob picked") end
    end
    pcall(function() getCore():TakeFullScreenshot("m2a_server_tab.png") end)
end)
add(2000, function()
    pcall(function() getCore():TakeFullScreenshot("m2a_admin_bob.png") end)
    C.open(false)
end)
add(1500, function()
    pcall(function() getCore():TakeFullScreenshot("m2a_chat.png") end)
    if C.win then C.win:setVisible(false) end
    CWm.toggleBothPaired(0)
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
