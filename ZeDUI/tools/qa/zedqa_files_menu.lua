-- ZeDUI/tools/qa/zedqa_files_menu.lua  (Nov 11 2026, QA, punch list 170, check file CHECK_pl170_files_tab.md, parts 2 to 5: the main menu)
-- At the main menu with Bandits, Bandits Week One, Ladders!? and ZeD picks on (zedqa_files_run.ps1; run after zedqa_files_game.lua so the
-- jump and the error places are in Zomboid/Lua). Opens the Mods screen the way its button does, checks Open in Mods' jump landed on
-- BWOScheduler.lua of Bandits Week One, reads the Files tab, switches one file off through the tab's own A (fileA), checks a
-- file others use only opens its card, the game-file guard, then leaves the file off (the next run checks the game, then
-- zedqa_files_run.ps1 turns it back on). Writes Lua/zedqa_files_state.txt for it. grep "ZEDQA fm". Pictures zqa_fm_*.png.
local MM = ZeD.MainMenu
local R = MM.root
local F, P, MS = ZeD.ModFiles, ZeD.ModPicks, ZeD.ModScan
local BWO = "BanditsWeekOne"
local function say(s) print("ZEDQA fm " .. tostring(s)) end
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra ~= nil and (" | " .. tostring(extra)) or "")) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_fm_" .. n .. ".png") end) end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function win() return R.modsWin end
local function model() return ModSelector and ModSelector.instance and ModSelector.instance.model end
local function d() local m = model(); return m and m.mods and m.mods[BWO] end
local S = {}

at(2, function() MM.showView("main") end)
at(20, function()
    local jump = nil
    pcall(function() local r = getFileReader(F.JUMP_FILE, false); if r then jump = r:readLine(); r:close() end end)
    say("jump file before the screen opens: " .. tostring(jump))
    S.jump = jump
    MM.act.mods()
end)
at(140, function()
    local w = win()
    local dd = d()
    check(w ~= nil and dd ~= nil, "the Mods screen is up and lists Bandits Week One")
    say("selected " .. tostring(w and w.sel) .. ", tab " .. tostring(w and w.dtab) .. ", file " .. tostring(w and (w.fileSel or w._fileJump)))
    check(w ~= nil and w.sel == BWO and w.dtab == "files", "Open in Mods: the screen picked Bandits Week One on its Files tab")
    check(S.jump ~= nil and tostring(S.jump):find("BWOScheduler", 1, true) ~= nil, "the jump was left by the error card for BWOScheduler.lua", S.jump)
    shot("1_jump")
end)
at(260, function()
    local w, dd = win(), d()
    local fp = w and (w.fileSel or w._fileJump)
    check(fp ~= nil and tostring(fp):lower():find("bwoscheduler.lua", 1, true) ~= nil, "BWOScheduler.lua is the picked file", fp)
    local list = F.files(BWO)
    local sides = {}
    for _, f in ipairs(list) do sides[f.side] = (sides[f.side] or 0) + 1 end
    say("Files: " .. #list .. " (client " .. tostring(sides.client) .. ", shared " .. tostring(sides.shared) .. ", server " .. tostring(sides.server) .. ")")
    check(#list > 10, "the tab lists the mod's code files", #list)
    check(F.errorCount("Bandits Week One") > 0, "the last game's errors are known to the screen", F.errorCount("Bandits Week One"))
    check(#F.placesOn("Bandits Week One", "BWOScheduler.lua") > 0, "BWOScheduler.lua carries errors")
    shot("2_files_tab")
    S.list = list
end)
-- the scan reads the files a little each frame (the tab's own F.step, once a frame; F.scan only reads the result)
at(900, function()
    local ok = F.scan(BWO)
    say("scan done: " .. tostring(ok ~= nil and ok ~= false))
end)
at(1000, function()
    -- (the checks below need every file read: finish here whatever the frame rate was)
    for _ = 1, 100000 do if F.step(BWO) then break end end
    local w, dd = win(), d()
    local free, used, game = nil, nil, nil
    for _, f in ipairs(S.list) do
        local st = w:fileState(dd, f)
        if st == "game" then game = game or f end
        if st == "on" then
            local u = F.usedBy(BWO, f.path)
            if u and #u == 0 and #F.placesOn("Bandits Week One", f.path) == 0 then free = free or f end
            if u and #u > 0 then used = used or f end
        end
    end
    -- the first choice is the file the check names: no intro music at boot
    for _, f in ipairs(S.list) do
        if tostring(f.path):find("BWOIntro.lua", 1, true) then
            local u = F.usedBy(BWO, f.path)
            say("BWOIntro.lua used by " .. tostring(u and #u))
            if u and #u == 0 then free = f end
        end
    end
    S.free, S.used, S.game = free, used, game
    say("free file " .. tostring(free and free.path) .. "; used file " .. tostring(used and used.path) .. "; game file " .. tostring(game and game.path))
    check(free ~= nil, "a file with no 'used by' and no errors is on the tab")
    check(used ~= nil, "a file others name is on the tab ('used by')")
    -- 4: the used file only opens its card
    if used then
        local before = #P.offFor(BWO)
        w:fileA(dd, used)
        check(#P.offFor(BWO) == before and w.fileSel == used.path, "A on a used file opens its card and switches nothing", used.path)
        shot("3_used_card")
    end
    -- the error file: card only
    for _, f in ipairs(S.list) do
        if tostring(f.path):find("BWOScheduler.lua", 1, true) then
            local before = #P.offFor(BWO)
            w:fileA(dd, f)
            check(#P.offFor(BWO) == before, "A on BWOScheduler.lua (errors) opens its card and switches nothing")
            shot("4_error_card")
        end
    end
end)
at(1100, function()
    local w, dd = win(), d()
    local f = S.free
    if not f then return end
    local before = {}
    S.pathOff = f.path
    w:fileA(dd, f)
    check(P.offOf(f.path) == BWO and w:fileState(dd, f) == "off", "A on a free file switches it off", f.path)
    check(#P.offFor(BWO) == 1, "the mod's row would say 1 file off", #P.offFor(BWO))
    shot("5_one_off")
end)
at(1200, function()
    -- the game-file guard
    local w, dd = win(), d()
    check(F.isGameFile("media/lua/client/ISUI/ISInventoryPane.lua") == true, "a path the game ships is a game file (ISInventoryPane.lua)")
    check(F.isGameFile("media/lua/client/BWOIntro.lua") == false, "a mod's own file is not")
    if S.game then
        local before = #P.offFor(BWO)
        w:fileA(dd, S.game)
        check(w:fileState(dd, S.game) == "game" and #P.offFor(BWO) == before, "never offered on a game file: A on " .. S.game.path .. " switches nothing")
    else
        say("no game file among Bandits Week One's files; the guard is checked on the path rule only")
    end
    -- the other mods: any of them shipping a game file
    local m = model()
    for id, dm in pairs(m and m.mods or {}) do
        if id == "Bandits" or id == "Ladders" then
            for _, f in ipairs(F.files(id)) do
                if w:fileState(dm, f) == "game" then
                    local before = #P.offFor(id)
                    w:fileA(dm, f)
                    check(#P.offFor(id) == before, "never offered on a game file in " .. id .. ": " .. f.path)
                end
            end
        end
    end
    -- write what the next steps need
    local state = { off = P.offFor(BWO) }
    pcall(function()
        local fw = getFileWriter("zedqa_files_state.txt", true, false)
        for _, p in ipairs(state.off) do fw:write("off\t" .. BWO .. "\t" .. p .. "\n") end
        fw:close()
    end)
    say("off now: " .. table.concat(state.off, ", "))
    shot("6_end")
end)
at(1300, function()
    say("fails " .. fails)
    say("DONE")
end)
local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 1350 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
