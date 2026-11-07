-- ZeDUI/tools/qa/mp_admin_rail.lua  (Nov 6 2026, QA; the director: no tab icons and no footer on the World window with Admin open): the window's own numbers with Loot and with Admin
-- up, a real click on the rail's Loot tab from Admin, and pictures. grep "ZEDQA arl".
local function say(s) print("ZEDQA arl " .. tostring(s)) end
local WW = ZeD_WorldWindow.getWindow
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function nums(tag)
    local w = WW()
    local s = w and w._actionTabStrip
    if not w then say(tag .. " no window"); return end
    say(tag .. " tab=" .. tostring(w._activeTab) .. " mode=" .. tostring(w._drawerMode) .. " open=" .. tostring(w._drawerOpen) .. " rolled=" .. tostring(w.windowShaded)
        .. " win " .. math.floor(w:getX()) .. "," .. math.floor(w:getY()) .. " " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight()) .. " footer=" .. tostring(w.footerHeight and w:footerHeight())
        .. " strip x=" .. tostring(s and s:getX()) .. " w=" .. tostring(s and s:getWidth()) .. " h=" .. tostring(s and s:getHeight()) .. " vis=" .. tostring(s and s:isVisible())
        .. " zones=" .. tostring(s and s._hitZones and #s._hitZones) .. " screen " .. getCore():getScreenWidth())
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_arl_" .. n .. ".png") end) end
add(400, function() ZeD_WorldWindow.openTab(0, "loot") end)
add(1500, function() nums("loot"); shot("1_loot") end)
add(300, function() ZeD_WorldWindow.openTab(0, "admin") end)
add(1800, function() nums("admin"); shot("2_admin") end)
add(300, function()
    local s = WW()._actionTabStrip
    for _, z in ipairs(s._hitZones or {}) do if z.id == "tab:loot" then s:onMouseDown(z.x + 2, z.y + 2); say("pressed the rail's Loot at " .. z.x .. "," .. z.y); return end end
    say("no Loot zone on the rail")
end)
add(1500, function() nums("after the rail press"); shot("3_after"); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
