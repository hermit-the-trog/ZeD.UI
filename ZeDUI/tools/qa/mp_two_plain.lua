-- ZeDUI/tools/qa/mp_two_plain.lua  (Nov 5 2026, QA): on the second client, a plain player with no admin rights: the role, the tabs, the chat's channels,
-- a line sent, the PvP marker's words, the wheels' server slices. grep "ZEDQA m2p".
local function say(s) print("ZEDQA m2p " .. tostring(s)) end
local function check(ok, s) say((ok and "PASS " or "FAIL ") .. s) end
local p = getPlayer()
local C = ZeD.Chat
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function tabs(w, field)
    local out = {}
    local strip = w and w[field]
    for _, hz in ipairs(strip and strip._hitZones or {}) do if hz.id and hz.id:find("^tab:") then out[#out + 1] = hz.id:sub(5) end end
    return out
end
local function has(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(500, function()
    pcall(function() p:getModData().ZeD_WinPinned = { char = true, world = true } end)
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)
add(3000, function()
    local a, b = tabs(CWm.getWindow(), "_tabStripPanel"), tabs(WWm.getWindow(), "_actionTabStrip")
    local role; pcall(function() role = p:getRole():getName() end)
    say("user " .. tostring(p:getUsername()) .. ", role " .. tostring(role) .. ", Character tabs [" .. table.concat(a, ", ") .. "], World tabs [" .. table.concat(b, ", ") .. "]")
    check(has(a, "server"), "a plain player has the Server tab")
    check(not has(b, "admin"), "a plain player has no Admin tab")
    local w = CWm.getWindow(); w._activeTab = "server"; w._drawerMode = "tab"; w._drawerOpen = true
end)
add(2500, function()
    pcall(function() getCore():TakeFullScreenshot("m2p_server_tab.png") end)
    local st = CWm.getWindow()._serverTab
    local ids = {}
    for _, hz in ipairs(st and st.hits or {}) do if hz.btn then ids[#ids + 1] = tostring(hz.btn.id) .. (hz.btn.disabled and "(off)" or "") end end
    say("Server tab buttons: " .. table.concat(ids, ", "))
    say("the belt's PvP words: " .. tostring(ZeD.Belt and ZeD.Belt.pvpWords and ZeD.Belt.pvpWords(p)))
    C.open(false)
end)
add(1500, function()
    local names, shown = {}, {}
    for _, t in ipairs(C.TABS or {}) do names[#names + 1] = tostring(t.id) end
    local w = C.win
    say("chat channels " .. table.concat(names, ", "))
    C.send("/all hello from a plain player")
end)
add(2500, function()
    pcall(function() getCore():TakeFullScreenshot("m2p_chat.png") end)
    local n, first = #C.lines, C.lines[1]
    say("chat lines " .. n .. ", newest: " .. tostring(first and first.text))
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
