-- ZeDUI/tools/qa/mp_adm2.lua  (Nov 6 2026, QA): what mp_admin.lua leaves as TODO that one client can reach. Phase in Lua/zedqa_tk_phase.txt, set by batch_adm2.ps1.
--   1 E16 requestUsers fills getUsers; a timed ban made short by the shim, the client then leaves: E8, it lifts with nobody on; a repeat left running on the empty server
--   2 rejoin: the ban gone, the repeat's stop; a ban and a repeat kept, /save
--   3 after a stop and start: both still there, then cleared
-- grep "ZEDQA mae".
local function say(s) print("ZEDQA mae " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local S, M = ZeD.ServerPart, ZeD.Admin
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end
local r = getFileReader("zedqa_tk_phase.txt", false)
local PHASE = tonumber((r and r:readLine() or "1"):match("%d+"))
if r then r:close() end
local SID = "76561198000000123"
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(2000, function() nolimits(); pass("phase " .. PHASE .. ": the tools are here", S.adm == true and M.live(), S.adm); say("bans " .. #M.bans .. ", repeats " .. #M.repeats) end)
if PHASE == 1 then
    add(300, function() requestUsers() end)
    add(2500, function()
        local u = getUsers()
        pass("E16: requestUsers fills getUsers", u ~= nil and u:size() >= 1, u and u:size())
        sendClientCommand(p, "ZeDQA", "shortban", { sec = 45 })
    end)
    add(800, function()
        nolimits()
        M.banTyped(SID, "QA: lifts by itself", "h1", function(a) pass("a ban of 45 s acks", a.ok == true, a.err) end)
    end)
    add(1200, function()
        nolimits()
        M.message("ZeD QA repeat on an empty server", 15, function(a) pass("a repeat acks", a.ok == true, a.err) end)
    end)
    add(1200, function() pass("both on the lists", #M.bans == 1 and #M.repeats == 1, #M.bans .. " + " .. #M.repeats) end)
elseif PHASE == 2 then
    add(1000, function()
        pass("E8: the ban lifted while the server was empty", #M.bans == 0, #M.bans)
        nolimits()
        for _, x in ipairs(M.repeats) do M.stop(x.id) end
    end)
    add(1200, function() pass("the repeat stopped", #M.repeats == 0, #M.repeats); nolimits() end)
    add(800, function() M.banTyped(SID, "QA: kept across a restart", "d1", function(a) pass("a ban of a day", a.ok == true, a.err) end) end)
    add(1200, function() nolimits(); M.message("ZeD QA repeat kept", 15, function(a) pass("a repeat", a.ok == true, a.err) end) end)
    add(1200, function() SendCommandToServer("/save") end)
    add(6000, function() say("saved") end)
elseif PHASE == 3 then
    add(1000, function()
        pass("the ban came back", #M.bans == 1 and M.bans[1].sid == SID, #M.bans)
        pass("the repeat came back", #M.repeats == 1, #M.repeats)
        nolimits()
        for _, b in ipairs(M.bans) do M.unban(b) end
    end)
    add(1500, function()
        nolimits()
        for _, x in ipairs(M.repeats) do M.stop(x.id) end
    end)
    add(1500, function() pass("cleared", #M.bans == 0 and #M.repeats == 0) end)
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
