-- ZeDUI/tools/qa/mp_admin_rail.lua  (Nov 6 2026, QA; the director: no tab icons and no footer on the World window with Admin open): the World window's own numbers and pictures on
-- Admin home, the ticket queue, one card, an item card over Admin and closed again, a real press on the rail, and every other World tab. Pictures zqa_arl_*.png. grep "ZEDQA arl".
local function say(s) print("ZEDQA arl " .. tostring(s)) end
local WW = ZeD_WorldWindow.getWindow
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function nums(tag)
    local w = WW()
    local s = w and w._actionTabStrip
    if not w then say(tag .. " no window"); return end
    say(tag .. " tab=" .. tostring(w._activeTab) .. " mode=" .. tostring(w._drawerMode) .. " win " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight())
        .. " footer=" .. tostring(w.footerHeight and w:footerHeight()) .. " strip x=" .. tostring(s and s:getX()) .. " vis=" .. tostring(s and s:isVisible()) .. " zones=" .. tostring(s and s._hitZones and #s._hitZones))
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_arl_" .. n .. ".png") end) end
local function st() return WW()._adminTab end
local item
add(400, function() ZeD_WorldWindow.openTab(0, "loot") end)
add(1200, function() nums("loot"); shot("01_loot") end)
add(300, function() ZeD_WorldWindow.openTab(0, "admin") end)
add(1800, function() nums("admin home"); shot("02_admin_home") end)
add(300, function() st().screen = "tickets" end)
add(1200, function() nums("queue"); shot("03_queue") end)
add(300, function() st().screen = nil; ZeD.AdminCards.qaOpen(WW(), st(), "roles") end)
add(1500, function() nums("card"); shot("04_card") end)
add(300, function() st().card = nil end)
add(1200, function() nums("card closed"); shot("05_card_closed") end)
add(300, function()
    local items = getPlayer():getInventory():getItems()
    item = items:size() > 0 and items:get(0) or nil
    WW()._drawerItem = item
    say("item card over Admin: " .. tostring(item and item:getDisplayName()))
end)
add(1500, function() nums("item card"); shot("06_item_over_admin") end)
add(300, function() WW()._drawerItem = nil end)
add(1500, function() nums("item card closed"); shot("07_item_closed") end)
add(300, function()
    local s = WW()._actionTabStrip
    for _, z in ipairs(s._hitZones or {}) do if z.id == "tab:loot" then s:onMouseDown(z.x + 2, z.y + 2); say("pressed the rail's Loot"); return end end
    say("no Loot zone on the rail")
end)
add(1200, function() nums("after the rail press") end)
for n, t in ipairs(ZeD_WorldWindow.TABS or {}) do
    local id = t.id
    if id ~= "admin" and id ~= "loot" then
        local shown = false
        add(300, function() shown = ZeD_WorldWindow.isTabVisible(t, WW()); if shown then ZeD_WorldWindow.openTab(0, id) end end)
        add(1300, function() if shown then nums("tab " .. id); shot(string.format("1%d_tab_%s", n, id)) end end)
    end
end
add(300, function() ZeD_CharacterWindow.openTab(0, "server") end)
add(1500, function() local c = ZeD_CharacterWindow.getWindow(); say("Character server tab: active=" .. tostring(c and c._activeTab) .. " footer=" .. tostring(c and c.footerHeight and c:footerHeight())); shot("20_char_server") end)
add(300, function() ZeD_WorldWindow.openTab(0, "loot"); say("DONE") end)
local function drive()
    local p = plan[i]
    if not p then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < p.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(p.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
