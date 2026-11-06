-- ZeDUI/tools/qa/mp_tk_off.lua  (Nov 6 2026, QA): Part D step 10, the fallback on a live server: tickets through the game's own table when ZeD's server part is not there.
-- Forced with ZeD.ServerPart.forceOff unless Lua/zedqa_tk_real.txt exists, which says the server was started with no server part (mp_server.ps1 -NoServerPart): then
-- the client must find that out itself. grep "ZEDQA mtf". Pictures: mtf_*.png.
local function say(s) print("ZEDQA mtf " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local Tk, S, K, TC = ZeD.Tk, ZeD.ServerPart, ZeD.Tickets, ZeD.TicketCards
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local real = getFileReader("zedqa_tk_real.txt", false)
if real then real:close() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("mtf_" .. (real and "real_" or "forced_") .. n .. ".png") end) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local g = nil

if real then
    add(45000, function()
        pass("with no server part the client says so", S.present == false, S.present)
        pass("not staff by the server part", S.staff ~= true)
    end)
else
    add(1000, function() S.forceOff = true end)
end
add(1000, function() pass("the link reads off", not S.available()) end)
add(300, function() CWm.openTab(0, "server") end)
add(2000, function() shot("server") end)
add(300, function()
    pass("Send goes through the game", K.ask("GRIEF", true, "qa: the fallback's words", function(a) say("the ack: " .. tostring(a and a.ok) .. " " .. tostring(a and a.fallback)) end) == "sent")
end)
add(2000, function()
    local r = K.mine[1]
    pass("my list reads the game's row", r and r.game == true and r.kind == "GRIEF", r and r.kind)
    say("its words: " .. tostring(r and r.text) .. "; status " .. tostring(r and r.st))
    g = r and r.id
    shot("mine")
    WWm.openTab(0, "admin")
    K.adminAsk(true)
end)
add(2500, function()
    local q = K.fallbackQueue({ status = "Open" })
    pass("the queue reads the game's list", q.n >= 1, q.n)
    pass("the row keeps its kind", q.rows[1] and q.rows[1].kind == "GRIEF", q.rows[1] and q.rows[1].kind)
    shot("queue")
    K.gameView(g)
end)
add(1200, function()
    local q = K.fallbackQueue({ status = "Open" })
    pass("viewed reads Seen", q.rows[1] and q.rows[1].st == "Seen", q.rows[1] and q.rows[1].st)
    K.gameAnswer(g, "qa: an answer in the fallback")
end)
add(1500, function()
    local r = K.fallbackRow(g)
    pass("answered", r and r.st == "Answered" and r.ansText == "qa: an answer in the fallback", r and r.st)
    K.loadMine()
end)
add(1500, function()
    pass("the player reads Answered", K.mine[1] and K.mine[1].st == "Answered", K.mine[1] and K.mine[1].st)
    shot("answered")
    K.gameRemove(g)
end)
add(1500, function()
    pass("removed", K.fallbackRow(g) == nil)
    S.forceOff = nil
    K.closeQueue()
    say("DONE")
end)
local function drive()
    local stp = plan[i]
    if not stp then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < stp.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(stp.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
