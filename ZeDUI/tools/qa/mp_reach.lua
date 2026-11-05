-- ZeDUI/tools/qa/mp_reach.lua  (Nov 5 2026, QA; for Build's multiplayer work): on the multiplayer client with ZeD on,
-- can a player reach the game's own server panels: the left column's Safety (PvP), Client (ISUserPanelUI: players,
-- scoreboard, safehouse, faction) and Admin (ISAdminPanelUI) buttons, and the chat box? Reports what is on screen, then
-- presses each button the column's own way (onOptionMouseDown) and checks the panel opens; then the chat: shown,
-- focus takes typing, fades. A picture of the screen with the column and chat. grep "ZEDQA mpr".
local function say(s) print("ZEDQA mpr " .. tostring(s)) end
local p = getPlayer()
local col = ISEquippedItem and ISEquippedItem.instance
local function vis(e) return e ~= nil and e.getIsVisible and e:getIsVisible() end
local function onScreen(e)
    if not vis(e) then return false end
    local x, y = e:getAbsoluteX(), e:getAbsoluteY()
    return x >= 0 and y >= 0 and x < getCore():getScreenWidth() and y < getCore():getScreenHeight()
end
say("client " .. tostring(isClient()) .. ", access " .. tostring(p:getAccessLevel()) .. ", ZeD " .. tostring(ZeD ~= nil))
say("left column: exists " .. tostring(col ~= nil) .. ", visible " .. tostring(vis(col)) .. (col and (" at " .. col:getAbsoluteX() .. "," .. col:getAbsoluteY()) or ""))
local btns = { "safetyBtn", "clientBtn", "adminBtn", "warManagerBtn", "invBtn", "healthBtn", "craftingBtn", "mapBtn", "debugBtn" }
for _, b in ipairs(btns) do
    local e = col and col[b]
    say(string.format("  %-14s %s", b, e and ("exists, visible " .. tostring(vis(e)) .. ", on screen " .. tostring(onScreen(e))) or "none"))
end
local chat = ISChat and ISChat.instance
say("chat: exists " .. tostring(chat ~= nil) .. ", visible " .. tostring(vis(chat)) .. (chat and (" at " .. chat:getAbsoluteX() .. "," .. chat:getAbsoluteY() .. " size " .. chat:getWidth() .. "x" .. chat:getHeight()) or ""))
pcall(function() getCore():TakeFullScreenshot("mp_reach_screen.png") end)

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function press(name)
    local e = col and col[name]
    if not e then say(name .. ": no button"); return end
    pcall(function() ISEquippedItem.onOptionMouseDown(col, e, 0, 0) end)
end
add(500, function() press("clientBtn") end)
add(1500, function()
    local u = ISUserPanelUI and ISUserPanelUI.instance
    say("Client button -> user panel open " .. tostring(vis(u)) .. ", on screen " .. tostring(onScreen(u)))
    pcall(function() getCore():TakeFullScreenshot("mp_reach_user.png") end)
    if u then pcall(function() u:close() end) end
end)
add(500, function() press("adminBtn") end)
add(1500, function()
    local a = ISAdminPanelUI and ISAdminPanelUI.instance
    say("Admin button -> admin panel open " .. tostring(vis(a)) .. ", on screen " .. tostring(onScreen(a)))
    pcall(function() getCore():TakeFullScreenshot("mp_reach_admin.png") end)
    if a then pcall(function() a:close() end) end
end)
add(500, function() S_PVP = p:getSafety() and p:getSafety():isEnabled(); press("safetyBtn") end)
add(2500, function()
    local now = p:getSafety() and p:getSafety():isEnabled()
    say("Safety button: safety was " .. tostring(S_PVP) .. ", now " .. tostring(now) .. " (a cooldown may delay it)")
end)
-- the chat
add(500, function()
    if not chat then say("chat: none"); return end
    pcall(function() ISChat.instance:focus() end)
end)
add(800, function()
    if not chat then return end
    local te = chat.textEntry
    say("chat focus: text box visible " .. tostring(vis(te)) .. ", has focus " .. tostring(te and te:isFocused()))
    pcall(function() te:setText("zedqa chat test") end)
    pcall(function() chat:onCommandEntered() end)
end)
add(2500, function()
    if not chat then return end
    local text = ""
    pcall(function() local tp = chat.tabs and chat.tabs[chat.currentTabID] or chat.panel and chat.panel.activeView; text = tostring(tp and (tp.chatText and tp.chatText.text or tp.text)) end)
    say("after Enter: message shown in the chat " .. tostring(text:find("zedqa chat test", 1, true) ~= nil))
    say("fade: time " .. tostring(chat.fadeTime) .. " s, chat visible now " .. tostring(vis(chat)))
    pcall(function() getCore():TakeFullScreenshot("mp_reach_chat.png") end)
end)
add(12000, function()
    local a = 1
    pcall(function() a = chat.fade:fraction() end)
    say("after 12 s idle: fade fraction " .. tostring(a) .. ", chat visible " .. tostring(vis(chat)))
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
