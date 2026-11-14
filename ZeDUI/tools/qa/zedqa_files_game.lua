-- ZeDUI/tools/qa/zedqa_files_game.lua  (Nov 11 2026, QA, punch list 170, check file CHECK_pl170_files_tab.md, part 1: the game)
local setGameSpeed = ZEDQA_SPEED or setGameSpeed   -- (Nov 13 2026: the prelude's speed sets the time multiplier too; see zedqa_prelude.lua)
-- In game on the ZeD-QA save with Bandits, Bandits Week One, Ladders!? and ZeD picks on (zedqa_files_run.ps1 copies them in).
-- Waits for Bandits Week One's scheduler to error (a save not started with it), then checks the plain-words error cards:
-- one place BWOScheduler.lua line 42, its count rising on the same card, the plain words, the copy without a user name,
-- Open in Mods (the jump file and the pause window's Mods page). grep "ZEDQA fg". Pictures zqa_fg_*.png.
local function say(s) print("ZEDQA fg " .. tostring(s)) end
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra ~= nil and (" | " .. tostring(extra)) or "")) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_fg_" .. n .. ".png") end) end
local M = ZeD.Messages
local BWO = "Bandits Week One"
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function waitFor(maxMs, cond, what)
    local tEnd
    plan[#plan + 1] = { ms = 0, wait = true, fn = function()
        tEnd = tEnd or (getTimestampMs() + maxMs)
        if cond() then say("waited for " .. what); tEnd = nil; return true end
        if getTimestampMs() > tEnd then say("gave up waiting for " .. what); tEnd = nil; return true end
        return false
    end }
end
local function item(name) local s = M.sources[name]; return s and s.kind == "err" and s.items[1] or nil end
local function place42()
    local it = item(BWO)
    for _, p in ipairs(it and it.placeOrder or {}) do if tostring(p.file):find("BWOScheduler", 1, true) then return p end end
end
local O = { speed = getGameSpeed() }

add(300, function()
    local mods = getActivatedMods()
    local ids = {}
    for k = 0, mods:size() - 1 do ids[#ids + 1] = tostring(mods:get(k)) end
    say("mods on: " .. table.concat(ids, ", "))
    for _, id in ipairs({ "Bandits", "BanditsWeekOne", "Ladders", "ZeD_Picks", "ZeD_UI" }) do
        local on = false
        for _, x in ipairs(ids) do if x == id then on = true end end
        check(on, "the mod " .. id .. " is on")
    end
    if getGameSpeed() == 0 then setGameSpeed(1) end
    setGameSpeed(3)
end)
waitFor(240000, function() return item(BWO) ~= nil and item(BWO).count >= 3 and place42() ~= nil end, "Bandits Week One's errors")
add(500, function()
    setGameSpeed(O.speed > 0 and O.speed or 1)
    local it = item(BWO)
    check(it ~= nil, "Bandits Week One has an error source")
    if not it then return end
    local nPlaces = #(it.placeOrder or {})
    local p = place42()
    say("errors " .. it.count .. ", places " .. nPlaces .. "; scheduler place: " .. tostring(p and (p.file .. ":" .. tostring(p.line) .. " " .. tostring(p.fn))))
    check(p ~= nil and tostring(p.file):find("BWOScheduler.lua", 1, true) ~= nil, "the place file is BWOScheduler.lua", p and p.file)
    check(p ~= nil and tonumber(p.line) == 42, "the error is at line 42", p and p.line)
    check(p ~= nil and tostring(p.fn):find("generateSchedule", 1, true) ~= nil, "in generateSchedule", p and p.fn)
    check(p ~= nil and p.caller ~= nil, "it names the caller", p and p.caller and (tostring(p.caller.fn) .. " " .. tostring(p.caller.file)))
    local words = p and M.plainWords(p.msg)
    check(words ~= nil, "the message has plain words", words)
    say("message: " .. tostring(p and p.msg))
    O.count0 = p and p.count
    O.nPlaces = nPlaces
    M.open(BWO)
end)
add(2500, function() shot("1_cards") end)
add(1500, function()
    check(item("Ladders!? (v0.0.13)") ~= nil, "Ladders!? (v0.0.13) has its own error source (a name with brackets)", item("Ladders!? (v0.0.13)") and item("Ladders!? (v0.0.13)").count)
    for name, s in pairs(M.sources) do if s.kind == "err" then say("error source: " .. name .. " x" .. tostring(s.items[1] and s.items[1].count)) end end
end)
-- the count rises on the same card
waitFor(90000, function() local p = place42(); return p ~= nil and p.count > (O.count0 or 0) end, "the count to rise")
add(500, function()
    local it = item(BWO)
    local p = place42()
    check(p ~= nil and p.count > (O.count0 or 0), "the count rose on the same card", (O.count0 or "?") .. " -> " .. tostring(p and p.count))
    check(#(it.placeOrder or {}) == O.nPlaces, "no new card for the same place", O.nPlaces .. " -> " .. #(it.placeOrder or {}))
    -- copy
    local text = M.reportPlace(BWO, p)
    local user = nil
    pcall(function() user = tostring(getMyDocumentFolder()):match("[/\\][Uu]sers[/\\]([^/\\]+)") end)
    local leaked = (user and user ~= "" and text:lower():find(user:lower(), 1, true) ~= nil) or text:find("[Uu]sers[/\\]%w") ~= nil
    check(text:find("BWOScheduler.lua", 1, true) ~= nil and text:find(BWO, 1, true) ~= nil, "the copy has the header, the place line and the error")
    check(not leaked, "the copy has no user name")
    say("copy head: " .. text:sub(1, 200):gsub("\n", " / "))
    -- Open in Mods
    check(M.openInMods(BWO, p) == true, "Open in Mods set the jump")
end)
add(2500, function()
    local jf = nil
    pcall(function() local r = getFileReader(ZeD.ModFiles.JUMP_FILE, false); if r then jf = r:readLine(); r:close() end end)
    say("jump file line: " .. tostring(jf))
    local MM = ZeD.MainMenu
    shot("2_open_in_mods")
    say("pause mods page: " .. tostring(MM and MM.view))
end)
add(500, function()
    pcall(function() if M.close then M.close() end end)
    say("fails " .. fails)
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if st.wait then
        local ok, done = pcall(st.fn)
        if not ok then say("ERR wait " .. i .. ": " .. tostring(done)); done = true end
        if done then i = i + 1; t0 = getTimestampMs() end
        return
    end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
