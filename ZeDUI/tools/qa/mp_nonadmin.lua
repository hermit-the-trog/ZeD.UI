-- ZeDUI/tools/qa/mp_nonadmin.lua  (Nov 5 2026, QA): what a player without admin rights sees on a server. A -debug client may
-- only join as an admin, so the test account drops its own rights once in (/setaccesslevel, the server's own command; the
-- server's user list is copied before the run and put back after). Then: the Admin tab gone from the World window, the
-- Server tab still there, chat's Admin channel gone, the tab buttons that need rights gone, wheels, and no errors.
-- Pictures mna_<n>.png. grep "ZEDQA mna".
local function say(s) print("ZEDQA mna " .. tostring(s)) end
local p = getPlayer()
local C = ZeD.Chat
local function CW() return ZeD_CharacterWindow.getWindow() end
local function WW() return ZeD_WorldWindow.getWindow() end
local function tabs(w)
    local out = {}
    local strip = w and (w._tabStripPanel or w._actionTabStrip)
    for _, hz in ipairs(strip and strip._hitZones or {}) do if hz.id and hz.id:find("^tab:") then out[#out + 1] = hz.id:sub(5) end end
    return out
end
local function has(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
local function role() local r; pcall(function() r = p:getRole():getName() end); return tostring(r) end
local function report(tag)
    local a, b = tabs(CW()), tabs(WW())
    say(tag .. ": role " .. role() .. ", Character tabs [" .. table.concat(a, ", ") .. "], World tabs [" .. table.concat(b, ", ") .. "]")
    return a, b
end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(300, function() if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
add(2500, function()
    local _, b = report("as admin")
    say((has(b, "admin") and "PASS" or "FAIL") .. " the Admin tab shows for the admin")
    -- the server won't take /setaccesslevel on the logged-in account: the client's own role, what ZeD's tabs read
    KEEP_ROLE = p:getRole()
    local roles = getRoles()
    local low, names
    names = {}
    for k = 0, roles:size() - 1 do
        local r = roles:get(k)
        names[#names + 1] = r:getName() .. "@" .. tostring(r:getPosition())
        if not low or r:getPosition() < low:getPosition() then low = r end
    end
    say("roles: " .. table.concat(names, ", ") .. "; taking " .. tostring(low and low:getName()))
    p:setRole(low)
end)
add(4000, function()
    local a, b = report("rights dropped")
    say((role() ~= "admin" and "PASS" or "FAIL") .. " the role changed")
    say((not has(b, "admin") and "PASS" or "FAIL") .. " no Admin tab without rights")
    say((has(a, "server") and "PASS" or "FAIL") .. " the Server tab stays")
    local w = CW(); w._activeTab = "server"; w._drawerMode = "tab"; w._drawerOpen = true
    local v = WW(); if v._activeTab == "admin" then say("FAIL the World window sits on the Admin tab") end
    v._activeTab = "loot"; v._drawerMode = "tab"; v._drawerOpen = true
end)
add(2000, function()
    pcall(function() getCore():TakeFullScreenshot("mna_1_server_tab.png") end)
    local st = CW()._serverTab
    local ids = {}
    for _, hz in ipairs(st and st.hits or {}) do if hz.btn then ids[#ids + 1] = tostring(hz.btn.id) .. (hz.btn.disabled and "(off)" or "") end end
    say("Server tab buttons: " .. table.concat(ids, ", "))
    ZeD_CharacterWindow.toggleBothPaired(0)
    C.open(false)
end)
add(1500, function()
    local names = {}
    for _, t in ipairs(C.TABS or {}) do names[#names + 1] = tostring(t.id) end
    say("chat channel list: " .. table.concat(names, ", ") .. "; on show: " .. tostring(C.tab))
    local items = C.menuItems and C.menuItems() or {}
    local m = {}
    for _, it in ipairs(items) do m[#m + 1] = tostring(it.name) end
    say("chat menu: " .. table.concat(m, ", "))
    C.send("/all a message from a plain player")
    C.send("/a an admin-channel line from a plain player")
end)
add(2500, function()
    pcall(function() getCore():TakeFullScreenshot("mna_2_chat.png") end)
    if C.win then C.win:setVisible(false) end
    pcall(function() getCore():TakeFullScreenshot("mna_3_belt.png") end)
    if KEEP_ROLE then p:setRole(KEEP_ROLE) end
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
