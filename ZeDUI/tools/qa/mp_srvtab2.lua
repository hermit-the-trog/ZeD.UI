-- ZeDUI/tools/qa/mp_srvtab2.lua  (Nov 5 2026, QA; multiplayer part 1 follow-up, 5d24409d): the PvP marker's click with
-- the Character window rolled up (opens the Server tab, rolled down), turning PvP OFF (the countdown), the Tickets
-- button below the scroll (scrolled to, pressed: the game's tickets window), the button words, and the game's column
-- (Safety, Client, Admin hidden on a server). grep "ZEDQA ms2".
local function say(s) print("ZEDQA ms2 " .. tostring(s)) end
local p = getPlayer()
local S = ZeD.ServerTab
local function CW() return ZeD_CharacterWindow.getWindow() end
local function vis(e) return e ~= nil and e.getIsVisible and e:getIsVisible() end
local function btn(id) local st = CW()._serverTab; for _, b in ipairs(st and st.btns or {}) do if b.id == id then return b end end end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(300, function()
    local col = ISEquippedItem and ISEquippedItem.instance
    for _, b in ipairs({ "safetyBtn", "clientBtn", "adminBtn", "debugBtn" }) do say("game column " .. b .. " visible " .. tostring(vis(col and col[b]))) end
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
add(1500, function()
    local w = CW()
    if w.setPinned then w:setPinned(false) end
    w._activeTab = "loot"; w._autoShaded = true; w:setWindowShaded(true)
end)
add(1000, function()
    say("rolled " .. tostring(CW().windowShaded) .. "; marker '" .. tostring(ZeD.Belt.pvpWords(p)) .. "', clicking it")
    ZeD.Belt.tailAct("pvp", false)
end)
add(1500, function()
    local w = CW()
    say(((not w.windowShaded and w._activeTab == "server") and "PASS" or "FAIL") .. " marker click: rolled " .. tostring(w.windowShaded) .. ", tab " .. tostring(w._activeTab))
    if w.setPinned then w:setPinned(true) end
end)
add(1500, function()
    local ids = {}
    for _, b in ipairs(CW()._serverTab.btns or {}) do ids[#ids + 1] = b.id end
    say("buttons now [" .. table.concat(ids, ", ") .. "]")
    local pv = S.pvpState(p)
    say("pvp on " .. tostring(pv and pv.on))
    local b = btn("pvp")
    if b then S.onClick(CW(), b.x + 2, b.y + 2); say("pressed the PvP switch") end
end)
for k = 1, 8 do
    add(1500, function()
        local pv = S.pvpState(p)
        say(string.format("+%.1f s: on %s, left %s, marker '%s'", k * 1.5, tostring(pv and pv.on), tostring(pv and pv.left), tostring(ZeD.Belt.pvpWords(p))))
        if k == 2 then pcall(function() getCore():TakeFullScreenshot("ms2_pvp_countdown.png") end) end
    end)
end
-- Tickets: scroll the tab to the foot, press it
add(500, function()
    local st = CW()._serverTab
    pcall(function() st.scroll:setScrollPos(1) end)
    pcall(function() st.off = 100000 end)
end)
add(1200, function()
    local b = btn("tickets")
    say("tickets button " .. tostring(b ~= nil) .. (b and (" label '" .. tostring(b.label) .. "'") or ""))
    if b then S.onClick(CW(), b.x + 2, b.y + 2) end
    pcall(function() getCore():TakeFullScreenshot("ms2_foot.png") end)
end)
add(1500, function()
    local t = ISTicketsUI and ISTicketsUI.instance
    say("tickets -> the game's window open " .. tostring(vis(t)))
    if t then pcall(function() t:close() end) end
    local labs = {}
    for _, b in ipairs(CW()._serverTab.btns or {}) do labs[#labs + 1] = tostring(b.label or b.text or b.id) end
    say("button words [" .. table.concat(labs, " | ") .. "]")
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
