-- ZeDUI/tools/qa/mp_surfaces_shots.lua  (Nov 5 2026, QA; the director: "Take screens of each so we can plan immersive"):
-- every multiplayer surface ZeD draws, and the game's windows they open, on the multiplayer client (zedqa_run.ps1 -Mp).
-- Pictures mps_<nn>_<name>.png in Zomboid/Screenshots. grep "ZEDQA mss".
local function say(s) print("ZEDQA mss " .. tostring(s)) end
local p = getPlayer()
local C = ZeD.Chat
local function CW() return ZeD_CharacterWindow.getWindow() end
local function WW() return ZeD_WorldWindow.getWindow() end
local n = 0
local function shot(name) n = n + 1; local f = string.format("mps_%02d_%s.png", n, name); pcall(function() getCore():TakeFullScreenshot(f) end); say("shot " .. f) end
local function tab(w, id) w._activeTab = id; w._drawerMode = "tab"; w._drawerOpen = true end
local function scrollTo(st, frac) pcall(function() st.scroll:setScrollPos(frac) end); pcall(function() if frac >= 1 then st.off = 100000 elseif frac <= 0 then st.off = 0 end end) end
local function closeTop(before) local ui = UIManager.getUI(); for k = ui:size() - 1, before, -1 do pcall(function() local e = ui:get(k); e:setVisible(false); e:removeFromUIManager() end) end end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

add(300, function() if C.win then C.win:setVisible(false) end; if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
add(1500, function() tab(CW(), "server"); tab(WW(), "loot") end)
add(2000, function() shot("server_tab_top") end)
add(300, function() scrollTo(CW()._serverTab, 1) end)
add(1500, function() shot("server_tab_foot") end)
-- the belt marker, windows shut
add(300, function() ZeD_CharacterWindow.toggleBothPaired(0) end)
add(1500, function() shot("belt_pvp_marker_and_chat_key") end)
-- chat: some lines, then open, then dimmed
add(300, function()
    C.send("/all Anyone near the Muldraugh water tower?")
    C.send("Heading to the gas station, need fuel")
    C.send("/a admin note: restart at 6")
end)
add(2500, function() shot("belt_chat_count") end)
add(300, function() C.open(false) end)
add(1500, function() shot("chat_window_general") end)
add(300, function() C.tab = "admin"; if C.win then C.win._dirty = true end end)
add(1200, function() shot("chat_window_admin_tab") end)
add(300, function() C.tab = "general"; C.open(true) end)
add(1200, function() shot("chat_window_typing") end)
add(300, function() pcall(function() C.win.input:unfocus() end) end)
add(14000, function() shot("chat_window_dimmed") end)
add(300, function() if C.win then C.win:setVisible(false) end end)
-- Admin tab: top (a player picked), middle, foot
add(300, function() ZeD_CharacterWindow.toggleBothPaired(0) end)
add(1500, function()
    tab(CW(), "server"); tab(WW(), "admin")
end)
add(1500, function()
    local st = WW()._adminTab
    for _, hz in ipairs(st and st.hits or {}) do if hz.item and hz.item.k == "pick" then ZeD.AdminTab.onClick(WW(), hz.x + 2, hz.y + 2); break end end
end)
add(1500, function() shot("admin_tab_top_player_picked") end)
add(300, function() scrollTo(WW()._adminTab, 0.5) end)
add(1500, function() shot("admin_tab_middle") end)
add(300, function() scrollTo(WW()._adminTab, 1) end)
add(1500, function() shot("admin_tab_foot") end)
-- the game's windows the tabs open
local OPEN = ZeD.ServerTab.OPEN
for _, id in ipairs({ "options", "faction", "tickets" }) do
    add(500, function() B0 = UIManager.getUI():size(); pcall(OPEN[id], p) end)
    add(1500, function() shot("game_window_" .. id); closeTop(B0) end)
end
add(500, function() say("DONE (" .. n .. " pictures)") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
