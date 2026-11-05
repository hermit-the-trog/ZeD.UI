-- ZeDUI/tools/qa/mp_chat_admin.lua  (Nov 5 2026, QA; multiplayer parts 2 and 3: 9eab0506, ef3fa17e): ZeD's chat and the
-- Admin tab on the multiplayer client (zedqa_run.ps1 -Mp, the server's admin; one client, so lines come back from the
-- server to the same player). grep "ZEDQA mca".
--   chat     the belt's chat key and its count, the window, say and /all and a whisper and /a sent with ZeD.Chat.send and
--            arriving back in ZeD.Chat.lines, the count while the window is shut, the game's chat box hidden, the dim
--   admin    the World window's Admin tab on the strip, its rows and buttons, god mode ticked from the tab (survives a
--            rejoin: mp_chat_admin_after.lua), a server message (the box), the ticket list, More tools' windows
-- Pictures: mca_chat.png, mca_admin.png. God mode is ticked back off by the after script.
local function say(s) print("ZEDQA mca " .. tostring(s)) end
local p = getPlayer()
local C = ZeD.Chat
local A = ZeD.AdminTab
local function vis(e) return e ~= nil and e.getIsVisible and e:getIsVisible() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("mca_" .. n .. ".png") end) end
local function has(text) for _, l in ipairs(C.lines) do if l.text and l.text:find(text, 1, true) then return l end end; return nil end
local function WW() return ZeD_WorldWindow.getWindow() end
local function stripIds(w)
    local out = {}
    local strip = w and w._tabStripPanel
    for _, hz in ipairs(strip and strip._hitZones or {}) do if hz.id and hz.id:find("^tab:") then out[#out + 1] = hz.id:sub(5) end end
    return out
end
local stamp = tostring(getTimestampMs() % 100000)

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
-- chat
add(300, function()
    say("chat active " .. tostring(C.active()) .. ", on belt " .. tostring(C.onBelt()) .. ", unread " .. tostring(C.unread()) .. ", lines " .. #C.lines)
    say("the game's chat box visible " .. tostring(vis(ISChat and ISChat.instance)))
    C.open(true)
end)
add(1200, function()
    say("chat window open " .. tostring(vis(C.win)) .. (C.win and (" at " .. C.win:getX() .. "," .. C.win:getY() .. " " .. C.win:getWidth() .. "x" .. C.win:getHeight()) or ""))
    say("tabs " .. table.concat((function() local o = {}; for _, t in ipairs(C.tabsShown(p) or {}) do o[#o + 1] = type(t) == "table" and (t.id or "?") or tostring(t) end; return o end)(), ", "))
    C.tab = "general"
    say("send say: " .. tostring(C.send("qa say " .. stamp)))
end)
add(2500, function()
    local l = has("qa say " .. stamp); say((l and "PASS" or "FAIL") .. " say came back" .. (l and (" (" .. tostring(l.kind) .. ", " .. tostring(l.author) .. ")") or ""))
    say("send /all: " .. tostring(C.send("/all qa all " .. stamp)))
end)
add(2500, function()
    local l = has("qa all " .. stamp); say((l and "PASS" or "FAIL") .. " /all came back" .. (l and (" (" .. tostring(l.kind) .. ")") or ""))
    say("send whisper to self: " .. tostring(C.send("/w " .. p:getUsername() .. " qa whisper " .. stamp)))
end)
add(2500, function()
    local l = has("qa whisper " .. stamp); say((l and "PASS" or "NOTE") .. " whisper to self came back " .. tostring(l ~= nil) .. (l and (" (" .. tostring(l.kind) .. ")") or " (the game may refuse a whisper to yourself)"))
    say("send /a: " .. tostring(C.send("/a qa admin " .. stamp)))
end)
add(2500, function()
    local l = has("qa admin " .. stamp); say((l and "PASS" or "FAIL") .. " admin chat came back" .. (l and (" (" .. tostring(l.kind) .. ")") or ""))
    shot("chat")
    -- the count with the window shut
    if C.win then C.win:setVisible(false) end
    C.unreadN = 0
    C.send("/all qa unseen " .. stamp)
end)
add(2500, function()
    say((C.unread() > 0 and "PASS" or "FAIL") .. " a line with the window shut counts on the belt: " .. tostring(C.unread()))
    C.open(false)
end)
add(14000, function()
    local w = C.win
    say("after 14 s idle: window dim " .. tostring(w and (w._dim or w.dimmed or w._dimA)) .. " (field names guessed; see mca_dim.png)")
    shot("dim")
    if w then w:setVisible(false) end
end)
-- admin
add(500, function()
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
add(1500, function()
    local w = WW()
    local ids = stripIds(w)
    local hasAdmin = false; for _, id in ipairs(ids) do if id == "admin" then hasAdmin = true end end
    say("World tabs [" .. table.concat(ids, ", ") .. "]")
    say((hasAdmin and "PASS" or "FAIL") .. " the Admin tab on the World window (admin)")
    w._activeTab = "admin"; w._drawerMode = "tab"; w._drawerOpen = true
end)
add(2500, function()
    local st = WW()._adminTab
    local rows = {}
    for _, hz in ipairs(st and st.hits or {}) do
        local lab = hz.btn and ("btn:" .. tostring(hz.btn.id) .. (hz.btn.disabled and "(greyed)" or "")) or (hz.item and (tostring(hz.item.k) .. ":" .. tostring(hz.item.id)))
        rows[#rows + 1] = lab
    end
    say("admin hits (" .. #rows .. "): " .. table.concat(rows, ", "))
    shot("admin")
    -- god mode ticked from the tab
    GOD0 = p:isGodMod()
    for _, hz in ipairs(st and st.hits or {}) do
        if hz.item and hz.item.k == "check" and tostring(hz.item.id):lower():find("god") then
            A.onClick(WW(), hz.x + 2, hz.y + 2)
            say("ticked " .. tostring(hz.item.id))
            break
        end
    end
end)
add(2500, function() say("god mode was " .. tostring(GOD0) .. ", now " .. tostring(p:isGodMod())) end)
-- each More tools button: a new top-level UI element appears
add(500, function()
    local st = WW()._adminTab
    MORE = {}
    for _, hz in ipairs(st and st.hits or {}) do if hz.btn and tostring(hz.btn.id):find("^more:") then MORE[#MORE + 1] = hz end end
    say("More tools buttons " .. #MORE)
    MI = 0
end)
for k = 1, 12 do
    add(900, function()
        local hz = MORE and MORE[k]
        if not hz then return end
        local before = UIManager.getUI():size()
        A.onClick(WW(), hz.x + 2, hz.y + 2)
        local after = UIManager.getUI():size()
        say("  " .. tostring(hz.btn.id) .. ": UI elements " .. before .. " -> " .. after)
        -- close what it opened (the newest top element)
        if after > before then pcall(function() local e = UIManager.getUI():get(after - 1); if e.close then e:close() else e:setVisible(false); e:removeFromUIManager() end end) end
    end)
end
add(500, function()
    say("tickets known " .. tostring(A.tickets and #A.tickets or "?"))
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
