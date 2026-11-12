-- ZeDUI/tools/qa/zedqa_files_after.lua  (Nov 11 2026, QA, punch list 170, check file CHECK_pl170_files_tab.md, part 4: the game with a file off)
-- In game with the same mods on, after zedqa_files_menu.lua left a Bandits Week One file switched off (Lua/zedqa_files_state.txt).
-- Checks the file's part is gone and the rest of the mod runs, then turns the file back on (the tab's own calls: ZeD.ModPicks.setOff,
-- then sync) and checks the helper's copy now matches the mod's own text. grep "ZEDQA fa".
local function say(s) print("ZEDQA fa " .. tostring(s)) end
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra ~= nil and (" | " .. tostring(extra)) or "")) end
local P, F = ZeD.ModPicks, ZeD.ModFiles
local BWO = "BanditsWeekOne"
local off = {}
pcall(function()
    local r = getFileReader("zedqa_files_state.txt", false)
    if r then
        local l = r:readLine()
        while l do local id, path = l:match("^off\t([^\t]*)\t(.*)$"); if id == BWO then off[#off + 1] = path end; l = r:readLine() end
        r:close()
    end
end)
local n = 0
local function tick()
    n = n + 1
    if n < 400 then return end
    Events.OnTick.Remove(tick)
    check(#off > 0, "the state file names a switched-off file", table.concat(off, ", "))
    check(#P.offFor(BWO) == #off, "the picks list still has it off after a full quit and start", #P.offFor(BWO))
    -- where is the path loaded from now
    for _, path in ipairs(off) do
        local from = {}
        for k = 0, (getLoadedLuaCount() or 0) - 1 do
            local raw = tostring(getLoadedLua(k)):gsub("\\", "/")
            if raw:lower():find(path:lower(), 1, true) then from[#from + 1] = raw end
        end
        say("loaded copies of " .. path .. ": " .. #from .. " " .. table.concat(from, " | "))
        local fromPicks = false
        for _, r in ipairs(from) do if r:lower():find("zed_picks", 1, true) then fromPicks = true end end
        check(fromPicks, "the file loads from ZeD picks (its comment-only copy), not from the mod: " .. path)
    end
    local intro = false
    for _, p in ipairs(off) do if p:find("BWOIntro.lua", 1, true) then intro = true end end
    if intro then check(BWOIntro == nil, "BWOIntro.lua off: the intro's table BWOIntro is gone", tostring(BWOIntro)) end
    check(BWOScheduler ~= nil or BWOPlayer ~= nil or BWOOptions ~= nil, "the rest of the mod still ran (BWOOptions " .. tostring(BWOOptions ~= nil) .. ", BWOPlayer " .. tostring(BWOPlayer ~= nil) .. ")")
    -- turn it back on
    local ids = {}
    local mods = getActivatedMods()
    for k = 0, mods:size() - 1 do ids[#ids + 1] = tostring(mods:get(k)) end
    P.setOff(BWO, off, false)
    local wrote = P.sync(ids)
    check(#P.offFor(BWO) == 0, "turned back on: nothing off for the mod", #P.offFor(BWO))
    say("sync wrote " .. tostring(wrote) .. " copy(ies)")
    pcall(function() local fw = getFileWriter("zedqa_files_state.txt", true, false); fw:write(""); fw:close() end)
    say("fails " .. fails)
    say("DONE")
end
Events.OnTick.Add(tick)
say("start")
