-- ZeDUI/tools/qa/zedqa_b8_windows_mp.lua  (Nov 7 2026, QA; tag b8vm): the multiplayer and admin windows of VANILLA_WINDOWS_20261107.md
-- section C, on the local test server's client as its admin (mp_server.ps1 -Start, zedqa_run.ps1 -Mp -Manifest b8_menus_review_mp.txt).
-- For each row of the Admin tab's More tools (ZeD.AdminTab.MORE: See server options, Server sandbox options, PvP log, Zones,
-- Statistics, Check your stats, Climate control) and the Server tab's See server options it presses the row the way the tab does and
-- records which windows were put on the UI list (a class named ZeD_* is ZeD's; any other is the game's or a mod's) and what the tab
-- shows, prints "<row> | expected ZeD card | ..." with PASS or FAIL, and closes the card / window again. Rows whose capability this
-- account lacks are NOT RUN. Pressing a row only opens a view: nothing is sent to the server except the reads those views ask for.
-- Staff who change options are handed on to the game's own options window by design (the Server tab's card says so): that row reads
-- "ZeD card or the game's options window" and passes with either, and the game's window is named in the line.
-- Not scriptable: C1 Players, C3 Invite (the pause window), C17 the kicked screen, B10/B11 (two players). grep "ZEDQA b8vm".
local TAG = "b8vm"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if not isClient() then say("NOTE not a multiplayer client: nothing to check here"); say("DONE"); return end

local p = getPlayer()
local WW = ZeD_WorldWindow
local A, ST = ZeD.AdminTab, ZeD.ServerTab
local Q = { pass = 0, fail = 0, notrun = 0 }
local seen = {}
local realAdd = ISUIElement.addToUIManager
ISUIElement.addToUIManager = function(self, ...)
    seen[#seen + 1] = { t = tostring(self and self.Type), el = self }
    return realAdd(self, ...)
end
local function gameWindows()
    local out = {}
    for _, s in ipairs(seen) do
        if s.t ~= "nil" and s.t:sub(1, 3) ~= "ZeD" then
            local vis = true
            pcall(function() vis = s.el:getIsVisible() end)
            if vis then out[#out + 1] = s.t end
        end
    end
    return out
end
local function closeSeen()
    for _, s in ipairs(seen) do
        if s.t ~= "nil" and s.t:sub(1, 3) ~= "ZeD" then pcall(function() s.el:setVisible(false); s.el:removeFromUIManager() end) end
    end
    seen = {}
end

local rows, idx, tick, phase, at0 = {}, 0, 0, "open", 0
local function can(cap) local ok, r = pcall(function() return p:getRole():hasCapability(Capability[cap]) end); return ok and r end
local function winInfo(w, tag)
    local st = w and w._adminTab
    return tostring(tag) .. " (tab " .. tostring(w and w._activeTab) .. ", card " .. tostring(st and st.card and st.card.kind or (st and st.card ~= nil)) .. ", screen " .. tostring(st and st.screen) .. ")"
end

local function finish(r, w, extra)
    local g = gameWindows()
    local ok = (#g == 0) or r.orGame
    local line = r.id .. " | expected " .. (r.orGame and "ZeD card or the game's options window" or "ZeD card") .. " | " .. winInfo(w, "tab") .. " | game windows: " ..
        (#g == 0 and "-" or table.concat(g, ", ")) .. (extra and (" | " .. extra) or "")
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. line)
    pcall(function() getCore():TakeFullScreenshot("zqa_b8_vm_" .. string.gsub(string.lower(r.id), "[^%w]+", "_") .. ".png") end)
end

-- the rows
if A and A.MORE then
    for _, m in ipairs(A.MORE) do
        rows[#rows + 1] = { id = "C More tools: " .. tostring(m.id), cap = m.cap, orGame = (m.id == "options"), run = function(win, st) return m.run(p, win, st) end, tab = "admin" }
    end
end
if ST and ST.openOptionsFor then
    rows[#rows + 1] = { id = "C2 Server tab: See server options", orGame = true, run = function(win) return ST.openOptionsFor(p) end, tab = "server" }
end

local function resetTab(w)
    local st = w and w._adminTab
    if st then st.card, st.screen = nil, nil end
    pcall(function() if ST and ST.closeCard then ST.closeCard(w) end end)
    closeSeen()
end

local function onTick()
    tick = tick + 1
    if tick < 5 then return end
    if phase == "open" then
        idx = idx + 1
        local r = rows[idx]
        if not r then
            ISUIElement.addToUIManager = realAdd
            if WW.isOpen() then pcall(WW.close) end
            say("summary: " .. Q.pass .. " PASS, " .. Q.fail .. " FAIL, " .. Q.notrun .. " not run")
            say("DONE")
            Events.OnTick.Remove(onTick)
            return
        end
        if r.cap and not can(r.cap) then
            Q.notrun = Q.notrun + 1
            say(r.id .. " | NOT RUN (this account lacks " .. tostring(r.cap) .. ")")
            return
        end
        if not WW.isOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, 0) end
        local okTab = pcall(WW.openTab, 0, r.tab)
        r.cur = r
        phase, at0 = "press", tick
        if not okTab then say("ERR " .. r.id .. ": the " .. r.tab .. " tab did not open") end
    elseif phase == "press" and tick - at0 >= 50 then
        local r = rows[idx]
        local w = WW.getWindow()
        seen = {}
        local st = w and w._adminTab
        local ok, e = pcall(r.run, w, st)
        if not ok then say("ERR " .. r.id .. ": " .. tostring(e)) end
        phase, at0 = "look", tick
    elseif phase == "look" and tick - at0 >= 60 then
        local r = rows[idx]
        local w = WW.getWindow()
        finish(r, w)
        resetTab(w)
        phase, at0 = "settle", tick
    elseif phase == "settle" and tick - at0 >= 20 then
        phase = "open"
    end
end
Events.OnTick.Add(onTick)
