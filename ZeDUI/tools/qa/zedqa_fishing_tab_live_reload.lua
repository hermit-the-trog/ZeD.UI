-- ZeDUI/tools/qa/zedqa_fishing_tab_live_reload.lua  (Nov 11 2026, QA, punch list 167): the Fishing tab's saved records came back
-- after a save and a fresh start. Run after zedqa_fishing_tab_live.lua (its quit saved the game); reads Lua/zedqa_ftl_expect.txt.
-- Then takes that run's catch out of the records again (and the file away). grep "ZEDQA ftr".
local function say(s) print("ZEDQA ftr " .. tostring(s)) end
local p = getPlayer()
local L = ZeD.FishingLog
local function main()
local E = {}
pcall(function()
    local r = getFileReader("zedqa_ftl_expect.txt", false)
    if r then
        local l = r:readLine()
        while l do local k, v = l:match("^(%w+)=(.*)$"); if k then E[k] = v end; l = r:readLine() end
        r:close()
    end
end)
if not E.n then say("FAIL no expect file (the live run did not write one)"); say("DONE"); return end
local d = L.data(p)
local last = d.log[#d.log]
local pass, fail = 0, 0
local function check(ok, s) if ok then pass = pass + 1 else fail = fail + 1 end; say((ok and "PASS " or "FAIL ") .. s) end
check(tostring(d.n) == E.n and tostring(d.fish) == E.fish, "the counts came back: n " .. tostring(d.n) .. " (was " .. E.n .. "), fish " .. tostring(d.fish) .. " (was " .. E.fish .. ")")
check(tostring(#d.log) == E.logN and #d.top == tonumber(E.topN), "the catch log and the wall came back: log " .. #d.log .. " (was " .. E.logN .. "), wall " .. #d.top .. " (was " .. E.topN .. ")")
local found = nil
for _, e in ipairs(d.log) do if math.abs((tonumber(e.wa) or -1) - tonumber(E.wa)) < 0.001 then found = e end end
check(found ~= nil and found.type == E.type and math.abs((found.wt or 0) - tonumber(E.wt)) < 0.001, "the real catch is there: " .. tostring(found and found.type) .. " " .. tostring(found and found.wt) .. " kg (was " .. E.type .. " " .. E.wt .. ")")
local best = d.best[E.type]
check(best ~= nil and (best.wt or 0) >= tonumber(E.wt) - 0.001, "the species plaque came back for " .. E.type)
-- take that catch out again
if tostring(E.hadData) == "false" then
    p:getModData()[L.KEY] = nil
else
    for i = #d.log, 1, -1 do if math.abs((tonumber(d.log[i].wa) or -1) - tonumber(E.wa)) < 0.001 then table.remove(d.log, i) end end
    for i = #d.top, 1, -1 do if math.abs((tonumber(d.top[i].wa) or -1) - tonumber(E.wa)) < 0.001 then table.remove(d.top, i) end end
    for k, v in pairs(d.best) do if math.abs((tonumber(v.wa) or -1) - tonumber(E.wa)) < 0.001 then d.best[k] = nil end end
    d.n, d.fish = tonumber(E.origN), tonumber(E.origFish)
end
pcall(function() local fw = getFileWriter("zedqa_ftl_expect.txt", true, false); fw:write(""); fw:close() end)
say("the run's catch taken out again")
say("RESULT " .. pass .. " pass, " .. fail .. " fail")
say("DONE")
end
-- (the runner counts a DONE only after the bridge's own run line, so the work waits some ticks)
local n = 0
local function later()
    n = n + 1
    if n < 30 then return end
    Events.OnTick.Remove(later)
    local ok, e = pcall(main)
    if not ok then say("ERR " .. tostring(e)); say("DONE") end
end
Events.OnTick.Add(later)
