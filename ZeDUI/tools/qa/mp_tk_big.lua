-- ZeDUI/tools/qa/mp_tk_big.lua  (Nov 5 2026, QA): E14, the game's ticket list past the server's 1 MB buffer, and what ZeD's queue does then. grep "ZEDQA mtz".
local function say(s) print("ZEDQA mtz " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local S, K = ZeD.ServerPart, ZeD.Tickets
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end
local replies, size = 0, 0
local function view(list) replies = replies + 1; size = list:size() end
Events.ViewTickets.Add(view)
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local BIG = string.rep("b", 30000)
local function fill(n)
    for k = 1, n do add(60, function() addTicket("qa_big" .. (k % 7), BIG, -1) end) end
end
local function ask(label)
    add(2500, function() replies = 0; size = 0; getTickets(nil) end)
    add(4000, function() say(label .. ": a reply " .. tostring(replies > 0) .. ", rows " .. tostring(size)) end)
end
ask("empty")
fill(20)
ask("about 600 kB")
fill(25)
ask("about 1.35 MB")
fill(60)
ask("about 3.1 MB")
add(500, function() nolimits(); K.openQueue({ status = "All" }) end)
add(15000, function()
    pass("ZeD's queue still answers", K.queue ~= nil, K.queue and K.queue.n)
    pass("still connected", isClient() and getPlayer() ~= nil)
    nolimits()
    K.closeQueue()
    K.openQueue({ status = "All" })
end)
add(8000, function()
    say("the queue: " .. tostring(K.queue and K.queue.n) .. ", skipped " .. tostring(K.queue and K.queue.skipped) .. ", gameMax " .. tostring(K.gameMax))
    K.closeQueue()
    Events.ViewTickets.Remove(view)
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
