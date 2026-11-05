-- ZeDUI/tools/qa/mp_chat2.lua  (Nov 5 2026, QA; the chat reopen fix 4cdb45a6 and the open items): on the multiplayer
-- client, with Lua/ZeD_chatwin.txt kept from before. grep "ZEDQA mc2".
--   reopen   the chat window opens where the kept place says (design units x the scale)
--   T        the game's chat key opens it with the typing line focused
--   Escape   the window's own Escape closes it
--   dim      after 12 s idle win._dim is true; a new line brings it back
--   admin    the Admin tab scrolled to its foot: Server message (the box opens), Tickets, More tools (each opens a window)
-- Picture: mc2_admin_foot.png.
local function say(s) print("ZEDQA mc2 " .. tostring(s)) end
local p = getPlayer()
local C = ZeD.Chat
local A = ZeD.AdminTab
local function vis(e) return e ~= nil and e.getIsVisible and e:getIsVisible() end
local function WW() return ZeD_WorldWindow.getWindow() end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(300, function()
    local r = getFileReader("ZeD_chatwin.txt", false); local l = r and r:readLine(); if r then r:close() end
    KEPT = l
    say("kept place: " .. tostring(l) .. ", scale " .. tostring(ZeD.T.scale))
    if C.win then C.win:setVisible(false) end
    C.open(false)
end)
add(1000, function()
    local w = C.win
    say("reopen: window " .. tostring(vis(w)) .. (w and (" at " .. w:getX() .. "," .. w:getY() .. " " .. w:getWidth() .. "x" .. w:getHeight()) or ""))
    local xs, ys = nil, nil
    if KEPT then xs, ys = KEPT:match("^(%-?%d+) (%-?%d+)") end
    local kx, ky = tonumber(xs), tonumber(ys)
    if w and kx and ky then
        local sc = ZeD.T.scale or 1
        local ok = math.abs(w:getX() - kx * sc) <= 2 and math.abs(w:getY() - ky * sc) <= 2
        say((ok and "PASS" or "FAIL") .. " reopened where kept (expected " .. (kx * sc) .. "," .. (ky * sc) .. ")")
    else say((vis(w) and "PASS" or "FAIL") .. " reopened (no kept place to compare)") end
    -- Escape, the window's own way
    if w then pcall(function() w:onKeyPress(Keyboard.KEY_ESCAPE) end) end
end)
add(800, function()
    say((not vis(C.win) and "PASS" or "FAIL") .. " Escape closes it: visible " .. tostring(vis(C.win)))
    -- T: the game's chat key, as the engine fires it
    local k = getCore():getKey("Toggle chat") or getCore():getKey("Chat")
    TKEY = k
    say("chat key code " .. tostring(k))
    pcall(function() triggerEvent("OnKeyStartPressed", k) end)
    pcall(function() triggerEvent("OnKeyPressed", k) end)
end)
add(1000, function()
    local w = C.win
    local te = w and w.input
    say("T key: window " .. tostring(vis(w)) .. ", typing line focused " .. tostring(te and te.isFocused and te:isFocused()))
    if te and te.unfocus then pcall(function() te:unfocus() end) end
end)
add(13500, function()
    local w = C.win
    say((w and w._dim == true and "PASS" or "FAIL") .. " idle 13.5 s: win._dim " .. tostring(w and w._dim))
    C.send("/all qa wake " .. tostring(getTimestampMs() % 100000))
end)
add(2500, function()
    local w = C.win
    say((w and not w._dim and "PASS" or "FAIL") .. " a new line wakes it: win._dim " .. tostring(w and w._dim))
    if w then w:setVisible(false) end
end)
-- admin, scrolled to its foot
add(500, function()
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
add(1500, function()
    local w = WW(); w._activeTab = "admin"; w._drawerMode = "tab"; w._drawerOpen = true
end)
add(1500, function()
    local st = WW()._adminTab
    local ids = {}
    for _, hz in ipairs(st and st.hits or {}) do if hz.btn then ids[#ids + 1] = tostring(hz.btn.id); if hz.btn.id == "servermsg" then SRV0 = hz end end end
    say("admin buttons at the top: " .. table.concat(ids, ", "))
    if SRV0 then local b = UIManager.getUI():size(); A.onClick(WW(), SRV0.x + 2, SRV0.y + 2); SRVB = b end
end)
add(1200, function()
    if SRVB then
        local n = UIManager.getUI():size(); local top = UIManager.getUI():get(n - 1)
        say((n > SRVB and "PASS" or "FAIL") .. " Server message opens a box: " .. SRVB .. " -> " .. n .. " (" .. tostring(top and top.Type) .. ")")
        if n > SRVB and top then pcall(function() if top.destroy then top:destroy() else top:setVisible(false); top:removeFromUIManager() end end) end
    else say("Server message: no button seen") end
end)
add(500, function()
    local st = WW()._adminTab
    pcall(function() st.scroll:setScrollPos(1) end)
    pcall(function() st.off = 100000 end)
end)
add(1500, function()
    local st = WW()._adminTab
    local ids = {}
    MORE, SRV = {}, nil
    for _, hz in ipairs(st and st.hits or {}) do
        if hz.btn then
            ids[#ids + 1] = tostring(hz.btn.id) .. (hz.btn.disabled and "(greyed)" or "")
            if tostring(hz.btn.id):find("^more:") then MORE[#MORE + 1] = hz end
            if hz.btn.id == "servermsg" then SRV = hz end
        end
    end
    say("admin buttons at the foot: " .. table.concat(ids, ", "))
    pcall(function() getCore():TakeFullScreenshot("mc2_admin_foot.png") end)
    if SRV then
        local before = UIManager.getUI():size()
        A.onClick(WW(), SRV.x + 2, SRV.y + 2)
        say("Server message: UI elements " .. before .. " -> " .. UIManager.getUI():size())
    end
end)
add(1200, function()
    local n = UIManager.getUI():size()
    local top = n > 0 and UIManager.getUI():get(n - 1)
    say("the top element now: " .. tostring(top and top.Type) .. ", " .. tostring(top and top.getTitle and top:getTitle()))
    if top and top.Type == "ISTextBox" then pcall(function() top:destroy() end) end
end)
for k = 1, 10 do
    add(900, function()
        local hz = MORE[k]
        if not hz then return end
        MB = UIManager.getUI():size()
        A.onClick(WW(), hz.x + 2, hz.y + 2)
    end)
    add(700, function()
        local hz = MORE[k]
        if not hz then return end
        local after = UIManager.getUI():size()
        local top = after > 0 and UIManager.getUI():get(after - 1)
        say((after > MB and "PASS " or "FAIL ") .. tostring(hz.btn.id) .. ": " .. MB .. " -> " .. after .. " (" .. tostring(top and top.Type) .. ")")
        if after > MB and top then pcall(function() if top.close then top:close() end end); pcall(function() top:setVisible(false); top:removeFromUIManager() end) end
    end)
end
add(500, function() say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
