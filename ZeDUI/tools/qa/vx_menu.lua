-- ZeDUI/tools/qa/vx_menu.lua  (Nov 21 2026, QA beast day; tag vx_menu): MAIN MENU ONLY, pushed through the QA bridge.
-- The proof in the game of Build's fixes (commit 1cea31b69) for five findings of the beast code sweep
-- (ZeDUI/qa/audits/2026-11-21_beast_code_sweep.md). Each part says what the old code would have shown.
--
--   W52  Reset settings took other mods' files whose names merely hold the mod's id.
--        Staged: a made-up mod "VxqaMod" and a made-up folder listing (the game's calls that list and read
--        Zomboid/Lua, and its list of mods in use, are swapped for the length of one ZeD.ModReset.plan call; the
--        made-up names all read from one real file, zedqa_vx_menu_reset.txt; "VxqaMod_Armor" is made to be in use).
--        Old: VxqaModPlus_settings.ini and VxqaMod_Armor.ini (other mods' files) were in the plan, and a mod called
--        ServerList took the game's ServerList.txt and ServerListSteam.txt. New: only the mod's own files.
--        Reset is never called.
--   W53  The first-launch setup opened the setup file twice a frame while "Load a setup" was picked.
--        Counted: ZeD.Settings.hasSetup calls over three seconds of the window drawn with that way picked.
--        Old: two a frame (hundreds). New: one a second. Then the answer is made to say the opposite and watched
--        for 1.5 s, twice (there and back): Done must turn within the second while the file is still asked for
--        only once or twice (old: Done turned at once, but the file was asked for twice every frame).
--   W39  Options paired every control with every label on every page again every two seconds.
--        Counted: MM.optionRows / MM.keyRows calls over seven seconds of the Options window at rest. Old: every
--        page three times. New: none. Then a page really changes (a hidden 1 px panel added to it, taken off
--        again): only that page is read again. The key page's toggles come without the pairing walk and are the
--        same rows. The new pairing (labels in bands) gives the label the old every-label walk gave, on every page
--        (the key page too), and makes no every-label pass: math.min / math.max are counted while each page is
--        read (the old walk called them three times for each label against each control; the bands call neither).
--        The Mods screen's Options tab (ZeD.ModSettings.optionRows, asked every frame for five seconds): old read
--        the page three times, new once at most.
--   W38  Mods > Profiles: Rename / Duplicate acted on whichever profile was clicked after the question opened.
--        The question opened on profile A, then B's row clicked. Old: the pick moved to B, the copy or the new
--        name would have gone to B, and Rename's button greyed. New: the click waits, the target stays A, the
--        button stays live. The question is always cancelled: nothing is renamed or copied.
--   W51  Load Game: Rename file renamed another save when a row was clicked, a group folded or Find typed.
--        Rename opened on save A, then B clicked, A's group folded, Find filled with garbage. Old: the save Rename
--        would act on became B, then nothing (the button greyed). New: A throughout. Always cancelled.
-- NEVER pressed: Continue, Play, Delete's or Rename's confirm, Save (a profile), Upload, Reset's confirm, Quit's
-- Yes, the setup's Done / Skip / Save setup, the Mods screen's Back (it accepts the list: the game writes
-- pz_modlist_settings.cfg and mods/default.txt again and may reload Lua; the main window is put up instead).
-- ZeD.ModReset.reset is never called.
--
-- What it puts back itself: the three game calls it swaps (at once, inside the same stage), math.min / math.max
-- (counted for one page reading at a time), every counter it hangs on a ZeD function, the 1 px panel, the
-- Welcome's way, the Mods screen's page and pick, any profile it staged in memory (never saved), Load Game's pick,
-- folds and Find. It changes no option and no real file. (Opening Mods and Options runs their own onShow, as a
-- player opening them does: ZeD picks' copies and ModOptions.ini are rewritten there only when they differ.)
-- The one file it writes: Zomboid/Lua/zedqa_vx_menu_reset.txt (two lines; Lua cannot delete it: QA's to remove).
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/zed_only_mods.txt `
--        -Script ZeDUI/tools/qa/vx_menu.lua -Tag vx_menu -TimeoutSec 420
-- Lines: "ZEDQA vx_menu PASS ..." / "FAIL ..." / "SKIP ..." / "NOTE ..." / "ERR ...", then "VERDICT PASS n" or
-- "VERDICT FAIL n", then DONE (always from a later frame than the bridge's run line). grep "ZEDQA vx_menu".
local TAG = "vx_menu"
local MM = ZeD and ZeD.MainMenu
local St = ZeD and ZeD.Settings
local WL = ZeD and ZeD.Welcome
local S = { pass = 0, fail = 0, skips = 0, stages = {}, si = 1, maxMs = 240000, start = getTimestampMs() }
local keep = { undo = {} }
local K = {}
local X = {}
local STAGE_FILE = "zedqa_vx_menu_reset.txt"
local GARBAGE = string.rep("%[(.-*+?^$)]%% zZ9_ ", 6)
-- the three game calls W52 swaps for one call each time, and the two math calls W39 counts, as they were when the
-- script started
local G0 = { list = listFilesInZomboidLuaDirectory, read = getFileReader, act = getActivatedMods, min = math.min, max = math.max }

local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local function check(ok, what, detail)
    if ok then S.pass = S.pass + 1 else S.fail = S.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. ((detail ~= nil and detail ~= "") and (" | " .. tostring(detail)) or ""))
    return ok and true or false
end
local function skip(what, why) S.skips = S.skips + 1; say("SKIP " .. what .. " | " .. tostring(why)) end
local function note(s) say("NOTE " .. tostring(s)) end

-- ---- the stages, on the clock (bx_menu.lua's): after(ms, fn) runs fn ms after the stage before it (and three
-- frames at least); waitFor(cond, maxMs, fn) runs fn(true) as soon as cond is true, fn(false) after maxMs;
-- mark() is where the put-back starts (out of time: the queue jumps there)
local function after(ms, fn) S.stages[#S.stages + 1] = { ms = ms, fn = fn } end
local function waitFor(cond, maxMs, fn) S.stages[#S.stages + 1] = { ms = maxMs, cond = cond, fn = fn } end
local function mark() S.markAt = #S.stages + 1 end

-- ---- small things
function K.ms() return MainScreen and MainScreen.instance end
function K.try(what, fn)
    local ok, a = pcall(fn)
    if not ok then check(false, what .. " ran without an error", a) end
    return ok, a
end
function K.errs() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function K.errCheck(label)
    local n = K.errs()
    if n == nil or keep.errs == nil then keep.errs = n; return end
    local d = n - keep.errs
    keep.errs = n
    check(d == 0, label .. ": no new Lua error", (d ~= 0) and (d .. " new, see console.txt") or nil)
end
function K.jlist(l)
    local t = {}
    if l then for i = 0, l:size() - 1 do t[#t + 1] = tostring(l:get(i)) end end
    return t
end
function K.short(list)
    local out = {}
    for i, s in ipairs(list or {}) do if i <= 6 then out[#out + 1] = tostring(s) end end
    if #(list or {}) > 6 then out[#out + 1] = "(+" .. (#list - 6) .. " more)" end
    return table.concat(out, "; ")
end
function K.readLines(name)
    local t = nil
    pcall(function()
        local r = getFileReader(name, false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function K.same(a, b)
    if a == nil or b == nil then return a == b end
    return table.concat(a, "\n") == table.concat(b, "\n")
end
function K.activated() local t = {}; pcall(function() t = K.jlist(getActivatedMods()) end); return table.concat(t, ";") end
-- t's own field k, or nil when t only inherits it (the game's Kahlua rawget follows __index and returns the class's
-- function; pairs walks the table's own fields only), so a wrapper hung on a window is taken off, not left as a copy
function K.own(t, k)
    for kk, v in pairs(t) do if kk == k then return v end end
    return nil
end
-- something to undo at the put-back if its own stage never got to it (each runs once)
function K.later(fn) keep.undo[#keep.undo + 1] = fn end
function K.undoAll()
    for i = #keep.undo, 1, -1 do
        local fn = keep.undo[i]
        keep.undo[i] = nil
        pcall(fn)
    end
end

-- ---- the lightning (bx_menu.lua): held off for the run, so no flash lands in a count; let go at the end
function K.holdZap()
    local z = MM._life and MM._life.zap
    if not z then return end
    if keep.zapAt == nil then keep.zapAt = z.nextAt or 0 end
    z.t0 = nil; z.nextAt = 1e15
end
function K.freeZap()
    local z = MM._life and MM._life.zap
    if z and keep.zapAt ~= nil then z.nextAt = keep.zapAt end
end

-- ---- windows
function K.win(view)
    local r = MM.root
    if not r then return nil end
    if view == "main" then return r.win end
    if view == "load" then return r.loadWin end
    if view == "mods" then return r.modsWin end
    if view == "options" then return r.optsWin end
    for _, rv in ipairs(MM.views or {}) do if rv.view == view then return r[rv.field] end end
    return nil
end
function K.up(view)
    local w = K.win(view)
    return MM.view == view and w ~= nil and w:isVisible() and true or false
end
function K.rescue()
    MM.ctx.open = nil
    pcall(MM.showView, "main")
end
function K.spec(w, id)
    for _, s in ipairs((w and w._specs) or {}) do if s.id == id then return s end end
    return nil
end
-- a control pressed as the player's click or A: its own fn; returns nil, or why it could not be pressed
function K.press(w, id)
    local s = K.spec(w, id)
    if not s then return "no control " .. id end
    if s.disabled then return id .. " is greyed" end
    if not s.fn then return id .. " does nothing" end
    local ok, e = pcall(s.fn)
    if not ok then return id .. ": " .. tostring(e) end
    return nil
end
-- "live", "greyed" or "missing"
function K.specWord(w, id)
    local s = K.spec(w, id)
    if not s then return "missing" end
    return s.disabled and "greyed" or "live"
end
-- a stage's function that runs only while view's window is up: fn(w, met); flag is the keep field that says
-- the part was given up
local function V(view, flag, fn)
    return function(met)
        if keep[flag] then return end
        local w = K.win(view)
        if not (w and MM.view == view) then
            keep[flag] = true
            check(false, view .. ": the window stays up while it is checked", "view " .. tostring(MM.view))
            return
        end
        return fn(w, met)
    end
end

-- =========================================================================================================
-- 0: as found
function X.start()
    after(100, function()
        keep.errs = K.errs()
        keep.errs0 = keep.errs
        keep.mods0 = K.activated()
        keep.ini0 = K.readLines("ModOptions.ini")
        keep.setup0 = K.readLines((St and St.SETUP_FILE) or "ZeD_setup.txt")
        keep.seen0 = K.readLines((WL and WL.SEEN_FILE) or "ZeD_setup_seen.txt")
        keep.tut0 = K.readLines((WL and WL.TUTORIAL_FILE) or "ZeD_tutorial.txt")
        say("as found: view " .. tostring(MM.view) .. ", screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
            .. "; ZeD_setup.txt " .. (keep.setup0 and "there" or "absent") .. ", ZeD_setup_seen.txt " .. (keep.seen0 and "there" or "absent"))
        check(MM.openMods and MM.openOptions and MM.openWelcome and MM.showView and MM.act and MM.optionRows and MM.keyRows
            and ZeD.ModReset and ZeD.ModReset.plan and ZeD.ModSettings and St.hasSetup and true or false, "the main menu's parts are loaded")
    end)
    waitFor(function()
        local m = K.ms()
        return m ~= nil and not MM.waking and not MM.poweringOn() and (m.delay or 0) <= 0 and MM.root:isVisible()
    end, 30000, function(met)
        check(met, "the desk is awake (powered on, the fade-in over)", "waking " .. tostring(MM.waking) .. ", delay " .. tostring(K.ms() and K.ms().delay))
    end)
    after(2500, function()
        -- (a first launch opens the welcome by itself, 120 frames in: it is left as it came, nothing answered)
        if MM.view ~= "main" then
            note("the desk had the " .. tostring(MM.view) .. " view up at the start: back to the main window, nothing answered")
            MM.showView("main")
        end
    end)
    after(500, function() check(MM.view == "main" and K.up("main"), "the main window is up", "view " .. tostring(MM.view)) end)
end

-- =========================================================================================================
-- W52: Reset settings and other mods' files
-- R.plan(id) run over a made-up Zomboid/Lua listing: the listing call gives the real names plus `names`, the
-- reader gives STAGE_FILE's lines for each of them, the mods in use gain `mods`. All three calls are the game's
-- own globals, swapped for this one call and put back before it returns. Returns the plan's files as a set
-- (lower case), and the plan.
function X.planWith(id, names, mods)
    local R = ZeD.ModReset
    local list0, read0, act0 = listFilesInZomboidLuaDirectory, getFileReader, getActivatedMods
    local fake = {}
    for _, n in ipairs(names) do fake[string.lower(n)] = n end
    local function restore()
        listFilesInZomboidLuaDirectory, getFileReader, getActivatedMods = list0, read0, act0
    end
    K.later(restore)
    listFilesInZomboidLuaDirectory = function(dir)
        if dir ~= "" then return list0(dir) end
        local out = ArrayList.new()
        local real = list0(dir)
        for i = 0, (real and real:size() or 0) - 1 do
            local n = tostring(real:get(i))
            if not fake[string.lower(n)] then out:add(n) end
        end
        for _, n in ipairs(names) do out:add(n) end
        return out
    end
    getFileReader = function(name, create)
        if fake[string.lower(tostring(name))] then return read0(STAGE_FILE, false) end
        return read0(name, create)
    end
    getActivatedMods = function()
        local out = ArrayList.new()
        local real = act0()
        for i = 0, (real and real:size() or 0) - 1 do out:add(real:get(i)) end
        for _, m in ipairs(mods or {}) do out:add(m) end
        return out
    end
    local ok, plan = pcall(function()
        R.forget()
        return R.plan(id)
    end)
    restore()
    pcall(R.forget)   -- (the made-up listing must not stay in the reset's memory)
    if not ok then error("ZeD.ModReset.plan threw: " .. tostring(plan)) end
    local set, list = {}, {}
    for _, p in ipairs((plan and plan.files) or {}) do set[string.lower(tostring(p))] = true; list[#list + 1] = tostring(p) end
    table.sort(list)
    return set, plan, table.concat(list, ", ")
end
function X.reset()
    after(300, function()
        -- the one real file: what every made-up name reads as (a file with nothing in it is never listed)
        local wrote = pcall(function()
            local w = getFileWriter(STAGE_FILE, true, false)
            w:write("volume=7\n")
            w:write("made by vx_menu.lua for the Reset settings check; safe to delete\n")
            w:close()
        end)
        local back = K.readLines(STAGE_FILE)
        keep.stageOk = wrote and back ~= nil and #back == 2
        if not check(keep.stageOk, "W52 staging: Zomboid/Lua/" .. STAGE_FILE .. " is written (two lines)", back and (#back .. " lines") or "not there") then return end
        check(getModInfoByID("VxqaMod") == nil and getModInfoByID("ServerList") == nil, "W52 staging: no real mod is called VxqaMod or ServerList")
    end)
    after(200, function()
        if not keep.stageOk then skip("W52: Reset settings leaves other mods' files alone", "the stand-in file could not be written"); return end
        local names = { "VxqaMod.ini", "my_VxqaMod_settings.txt", "VxqaMod_notes.txt", "VxqaModPlus_settings.ini", "VxqaMod_Armor.ini" }
        local ok, set, plan, seen = pcall(X.planWith, "VxqaMod", names, { "VxqaMod_Armor" })
        if not ok then check(false, "W52: the plan for the made-up mod is worked out", set); return end
        say("W52: Reset settings on VxqaMod would empty: " .. (seen ~= "" and seen or "(nothing)"))
        check(plan ~= nil, "W52: the plan is ready at once (the made-up mod has no code to read)")
        -- (these three were taken before the fix and must still be: they are the mod's own)
        check(set["vxqamod.ini"] and set["my_vxqamod_settings.txt"] and set["vxqamod_notes.txt"] and true or false,
            "W52: the mod's own files are still in the plan (VxqaMod.ini, my_VxqaMod_settings.txt, VxqaMod_notes.txt)", seen)
        -- old code: any name holding "vxqamod" was taken, so both of these were in the plan and would be emptied
        check(not set["vxqamodplus_settings.ini"], "W52: a file of a mod whose id only starts the same (VxqaModPlus_settings.ini) is left out of the plan", seen)
        check(not set["vxqamod_armor.ini"], "W52: a file named after another mod in use with a longer id (VxqaMod_Armor) is left out of the plan", seen)
    end)
    after(200, function()
        if not keep.stageOk then return end
        -- old code: a mod called ServerList took the game's own server lists (they were not on the game's-files list)
        local ok, set, _, seen = pcall(X.planWith, "ServerList", { "ServerList.txt", "ServerListSteam.txt" }, {})
        if not ok then check(false, "W52: the plan for a mod called ServerList is worked out", set); return end
        check(not set["serverlist.txt"] and not set["serverliststeam.txt"], "W52: the game's server lists are never in a plan (a mod called ServerList)", seen ~= "" and seen or "(nothing)")
        check(listFilesInZomboidLuaDirectory == G0.list and getFileReader == G0.read and getActivatedMods == G0.act,
            "W52: the game's three calls swapped for the plan are the game's own again")
        check(K.same(K.readLines(STAGE_FILE), { "volume=7", "made by vx_menu.lua for the Reset settings check; safe to delete" }),
            "W52: only a plan was made: the stand-in file still holds its two lines")
        K.errCheck("W52")
    end)
end

-- =========================================================================================================
-- W53: the first-launch setup and the setup file
local function WE(fn) return V("welcome", "noWel", fn) end
function X.welcomeOff()
    if keep.hs0 then St.hasSetup = keep.hs0; keep.hs0 = nil end
    local w = K.win("welcome")
    if w and keep.wePre then w.prerender = keep.wePre0; keep.wePre = nil end
end
-- a watch of 1.5 s: the ask answers the opposite of the file (flipped) or the truth, and every ask is counted;
-- the frame Done first shows the answer wanted is noted (wantGrey() says whether Done should then be greyed)
local WATCH_MS = 1500
function X.weWatch(flipped)
    local hs0 = keep.hs0
    if not hs0 then return false end
    keep.wAsks, keep.wTurn, keep.wFrames0, keep.wT0 = 0, nil, keep.frames or 0, getTimestampMs()
    if flipped then
        St.hasSetup = function(file) keep.wAsks = keep.wAsks + 1; return not hs0(file) end
    else
        St.hasSetup = function(file) keep.wAsks = keep.wAsks + 1; return hs0(file) end
    end
    return true
end
function X.weWatchCond(wantGrey)
    return function()
        if keep.noWel or not keep.wT0 then return true end
        local now = getTimestampMs()
        local s = K.spec(K.win("welcome"), "done")
        if keep.wTurn == nil and s ~= nil and (s.disabled and true or false) == wantGrey() then keep.wTurn = now - keep.wT0 end
        return now - keep.wT0 >= WATCH_MS
    end
end
function X.weWatchSeen()
    local frames = (keep.frames or 0) - (keep.wFrames0 or 0)
    return "Done turned " .. (keep.wTurn and (keep.wTurn .. " ms in") or "never") .. "; the file asked for " .. tostring(keep.wAsks)
        .. " times over " .. frames .. " frames in " .. (WATCH_MS / 1000) .. " s (old code: twice a frame, about " .. (frames * 2) .. ")"
end
function X.welcome()
    after(300, function() K.try("W53: the setup window opening", MM.openWelcome) end)
    waitFor(function() return K.up("welcome") end, 4000, function(met)
        if not check(met, "W53: the first-launch setup opens", "view " .. tostring(MM.view)) then keep.noWel = true; K.rescue() end
    end)
    after(400, WE(function(w)
        local why = K.press(w, "way:2")
        check(why == nil and w.way == 2, "W53: Load a setup is picked", why or ("way " .. tostring(w.way)))
    end))
    after(1300, WE(function(w)
        keep.hasFile = St.hasSetup() and true or false
        -- (kept from before the fix: with no file to load, Done is greyed)
        check((K.spec(w, "done") ~= nil) and ((K.spec(w, "done").disabled and true or false) == (not keep.hasFile)),
            "W53: Done is greyed exactly when there is no setup file", "file " .. (keep.hasFile and "there" or "absent") .. ", Done " .. K.specWord(w, "done"))
        -- the count: every ask for the file, and every frame the window draws
        keep.hs0 = St.hasSetup
        keep.wePre0 = K.own(w, "prerender")
        keep.wePre = true
        keep.asks, keep.frames = 0, 0
        K.later(X.welcomeOff)
        local hs0, pre = keep.hs0, w.prerender
        St.hasSetup = function(file) keep.asks = keep.asks + 1; return hs0(file) end
        w.prerender = function(self) keep.frames = keep.frames + 1; return pre(self) end
        keep.weT0 = getTimestampMs()
    end))
    waitFor(function() return keep.noWel or not keep.weT0 or getTimestampMs() - keep.weT0 >= 3000 end, 6000, WE(function(w)
        if not keep.weT0 then check(false, "W53: the counters went on the setup window", "they never did (see the line before)"); keep.noWel = true; return end
        local secs = (getTimestampMs() - keep.weT0) / 1000
        local seen = keep.asks .. " asks in " .. keep.frames .. " frames, " .. string.format("%.1f", secs) .. " s (old code: two a frame, about " .. (keep.frames * 2) .. ")"
        if keep.frames < 20 then
            skip("W53: the setup file is asked for once a second, not twice a frame", "the window drew only " .. keep.frames .. " frames in " .. string.format("%.1f", secs) .. " s")
        else
            -- old code: two asks every frame. New: one a second (three seconds: three or four, five allowed)
            check(keep.asks <= 5, "W53: the setup file is asked for once a second, not twice a frame", seen)
            check(keep.asks >= 1, "W53: the file is still asked for while Load a setup is picked", seen)
        end
        -- the answer must still follow the file: the ask now says the opposite of the file, watched for 1.5 s
        X.weWatch(true)
    end))
    -- old code: Done turned at once, but the file was asked for twice every frame of the watch. New: Done turns
    -- within the second (the answer is not kept for good) and the file is asked for once or twice
    waitFor(X.weWatchCond(function() return keep.hasFile end), WATCH_MS + 1500, WE(function(w)
        check(keep.wTurn ~= nil and (keep.wAsks or 99) <= 3, "W53: made to read the other way, Done follows within a second while the file is asked for once a second",
            "the file made to read as " .. (keep.hasFile and "absent" or "there") .. "; " .. X.weWatchSeen() .. "; Done now " .. K.specWord(w, "done"))
        X.weWatch(false)
    end))
    waitFor(X.weWatchCond(function() return not keep.hasFile end), WATCH_MS + 1500, WE(function(w)
        check(keep.wTurn ~= nil and (keep.wAsks or 99) <= 3, "W53: the real answer again, Done is back within a second, the file still asked for once a second",
            "file " .. (keep.hasFile and "there" or "absent") .. "; " .. X.weWatchSeen() .. "; Done now " .. K.specWord(w, "done"))
        X.welcomeOff()
        w.way = 1
        K.errCheck("W53")
        -- (left the way the menu bar leaves it: Skip and Done write the seen and tutorial files, and are not pressed)
        MM.showView("main")
    end))
    waitFor(function() return MM.view == "main" end, 3000, function(met)
        X.welcomeOff()
        if not met then K.rescue() end
        check(K.same(K.readLines((WL and WL.SEEN_FILE) or "ZeD_setup_seen.txt"), keep.seen0) and K.same(K.readLines((WL and WL.TUTORIAL_FILE) or "ZeD_tutorial.txt"), keep.tut0)
            and K.same(K.readLines((St and St.SETUP_FILE) or "ZeD_setup.txt"), keep.setup0), "W53: nothing was answered: the setup's three files are as found")
    end)
end

-- =========================================================================================================
-- W39: the Options rows
-- the counters on the two readers of a vanilla page (MM.optionRows pairs controls with labels, MM.keyRows reads
-- the key page): how often, for which page, how long
local C = { n = 0, keys = 0, ms = 0, max = 0, by = {} }
function K.tapZero() C.n, C.keys, C.ms, C.max, C.by = 0, 0, 0, 0, {} end
function K.tapOff()
    if keep.or0 then MM.optionRows = keep.or0; keep.or0 = nil end
    if keep.kr0 then MM.keyRows = keep.kr0; keep.kr0 = nil end
end
function K.tapOn()
    K.tapOff()
    K.tapZero()
    local or0, kr0 = MM.optionRows, MM.keyRows
    keep.or0, keep.kr0 = or0, kr0
    K.later(K.tapOff)
    MM.optionRows = function(page)
        C.n = C.n + 1
        local v = page and page.view
        if v then C.by[v] = (C.by[v] or 0) + 1 end
        local t = getTimestampMs()
        local r = or0(page)
        local d = getTimestampMs() - t
        C.ms = C.ms + d
        if d > C.max then C.max = d end
        return r
    end
    MM.keyRows = function(page) C.keys = C.keys + 1; return kr0(page) end
end
-- which pages the counter saw read, by their titles ("Display x3; Audio x3")
function K.byNames()
    local out = {}
    for _, p in ipairs(keep.vpages or {}) do
        local n = p.view and C.by[p.view]
        if n and n > 0 then out[#out + 1] = tostring(p.raw) .. " x" .. n end
    end
    return (#out > 0) and table.concat(out, "; ") or "none"
end
-- one reading by fn(arg) with math.min and math.max counted while it runs (the old pairing called them three times
-- for every label it looked at, for every control; the banded pairing calls neither). Put back before it returns.
function K.countMath(fn, arg)
    local min0, max0 = math.min, math.max
    local n = 0
    K.later(function() math.min, math.max = G0.min, G0.max end)
    math.min = function(...) n = n + 1; return min0(...) end
    math.max = function(...) n = n + 1; return max0(...) end
    local t = getTimestampMs()
    local ok, r = pcall(fn, arg)
    local took = getTimestampMs() - t
    math.min, math.max = min0, max0
    return ok, r, n, took
end

-- the pairing as it was before the fix, written out again here: every control against every label on the page.
-- Returns control element -> the label text it should carry ("" none), or nil for the controller page (its
-- deadzone stepper takes labels out first); then the counts of controls and labels, and of the label passes the
-- old walk made (each pass called math.min twice and math.max once).
local PAIR = { ISComboBox = true, ISTickBox = true, ISVolumeControl = true, ISMegaVolumeControl = true, ISSliderPanel = true,
               ISButton = true, ISTextEntryBox = true, ISRichTextPanel = true, ISControllerBindingsEditorPanel = true, ISControllerTestPanel = true }
local PASSBY = { HorizontalLine = true, ISVolumeIndicator = true, ISScrollBar = true }
function K.kids(el)
    local t = {}
    local ch = el and el.getChildren and el:getChildren() or nil
    if ch then for _, c in pairs(ch) do t[#t + 1] = c end end
    return t
end
function K.collect(el, out, depth)
    if depth > 8 then return end
    local kids = K.kids(el)
    local hasSlider = false
    for _, c in ipairs(kids) do if c.Type == "ISSliderPanel" then hasSlider = true end end
    for _, c in ipairs(kids) do
        local ty = c.Type
        local ok, ax, ay = pcall(function() return c:getAbsoluteX(), c:getAbsoluteY() end)
        if ok then
            if PAIR[ty] then
                out.controls[#out.controls + 1] = { el = c, x = ax, y = ay, h = c.height }
            elseif PASSBY[ty] then
                -- nothing
            elseif ty == "ISLabel" then
                if not hasSlider then
                    local t = c.translation or c.name
                    if t == nil and c.getName then t = c:getName() end
                    out.labels[#out.labels + 1] = { x = ax, y = ay, w = c.width or 0, h = c.height or 0, text = tostring(t or ""), medium = (c.font == UIFont.Medium) }
                end
            else
                K.collect(c, out, depth + 1)
            end
        end
    end
end
function K.pairOld(view)
    local b = { labels = {}, controls = {} }
    K.collect(view, b, 0)
    for _, c in ipairs(b.controls) do
        local t = c.el and c.el.target
        if type(t) == "table" and t.btnJoypadSensitivityM and t.btnJoypadSensitivityP then return nil, #b.controls, #b.labels, 0 end
    end
    local used, want, passes = {}, {}, 0
    for _, c in ipairs(b.controls) do
        local best, bestRight = nil, -1e9
        local ch = math.min(c.h, 40)
        for _, l in ipairs(b.labels) do
            if not used[l] and not l.medium then
                passes = passes + 1
                local right = l.x + l.w
                local sameRow = math.abs((l.y + l.h / 2) - (c.y + ch / 2)) <= math.max(8, ch / 2)
                if sameRow and right <= c.x + 6 and right > bestRight then best, bestRight = l, right end
            end
        end
        if best then used[best] = true end
        want[c.el] = best and best.text or ""
    end
    return want, #b.controls, #b.labels, passes
end

local function O(fn) return V("options", "noOpts", fn) end
function X.optsOff()
    K.tapOff()
    local w = K.win("options")
    if w and keep.rf then w.rowsFor = keep.rf0; keep.rf = nil end
    if keep.probe then
        pcall(function() keep.probeView:removeChild(keep.probe) end)
        keep.probe = nil
    end
end
function X.options()
    after(300, function() K.try("W39: Options opening", MM.openOptions) end)
    waitFor(function() return K.up("options") end, 4000, function(met)
        if not check(met, "W39: Options opens", "view " .. tostring(MM.view)) then keep.noOpts = true; K.rescue() end
    end)
    after(800, O(function(w)
        keep.vpages = w:vpages()
        keep.rowAsks = 0
        keep.rf0 = K.own(w, "rowsFor")
        keep.rf = true
        K.later(X.optsOff)
        local rf = w.rowsFor
        w.rowsFor = function(self, p) keep.rowAsks = keep.rowAsks + 1; return rf(self, p) end
        K.tapOn()
        keep.optT0 = getTimestampMs()
    end))
    -- seven seconds at rest: the old two-second timer ran out three times in it
    waitFor(function() return keep.noOpts or not keep.optT0 or getTimestampMs() - keep.optT0 >= 7000 end, 10000, O(function(w)
        if not keep.optT0 then check(false, "W39: the counters went on the Options window", "they never did (see the line before)"); keep.noOpts = true; return end
        local secs = (getTimestampMs() - keep.optT0) / 1000
        local np = #keep.vpages
        local seen = C.n .. " page readings (" .. C.keys .. " of the key page; pages read: " .. K.byNames() .. "), " .. C.ms .. " ms in all, longest " .. C.max .. " ms, over " .. string.format("%.1f", secs)
            .. " s and " .. keep.rowAsks .. " asks for rows; " .. np .. " pages (old code: every page again every 2 s, about " .. (np * 3) .. " readings)"
        if keep.rowAsks < 20 then
            skip("W39: Options at rest does not read its pages again", "the window asked for rows only " .. keep.rowAsks .. " times in " .. string.format("%.1f", secs) .. " s")
        else
            -- old code: the group cache was thrown away every 2000 ms and every page paired again (np readings a time)
            check(C.n == 0 and C.keys == 0, "W39: Options at rest for 7 s reads none of its pages again", seen)
        end
        -- a page really changes: a hidden 1 px panel added to the first page that is not the key page
        local page = nil
        for _, p in ipairs(keep.vpages) do if not p.keys and not page then page = p end end
        if not page then keep.noProbe = true; skip("W39: a changed page is read again", "no page besides the key page"); return end
        K.tapZero()
        local ok, e = pcall(function()
            local probe = ISPanel:new(0, 0, 1, 1)
            probe:initialise()
            page.view:addChild(probe)
            keep.probe, keep.probeView, keep.probePage = probe, page.view, page   -- (on record at once: the put-back takes it off)
            probe:setVisible(false)
        end)
        if not ok then keep.noProbe = true; skip("W39: a changed page is read again", "the 1 px panel could not be added: " .. tostring(e)) end
    end))
    waitFor(function() return keep.noOpts or keep.noProbe or (keep.probeView ~= nil and (C.by[keep.probeView] or 0) >= 1) end, 5000, O(function(w, met)
        if keep.noProbe or not keep.probeView then return end
        local mine = C.by[keep.probeView] or 0
        check(mine >= 1, "W39: a page that changed (one element more) is read again within a few seconds", mine .. " readings of " .. tostring(keep.probePage.raw))
    end))
    after(600, O(function(w)
        if keep.noProbe or not keep.probeView then return end
        local mine = C.by[keep.probeView] or 0
        -- old code: every page was read again each time, changed or not
        check(C.n == mine and C.keys == 0, "W39: only the page that changed is read again, the others stay as built",
            C.n .. " readings, " .. mine .. " of the changed page (" .. tostring(keep.probePage.raw) .. "), " .. C.keys .. " of the key page; pages read: " .. K.byNames())
        K.tapZero()
        pcall(function() keep.probeView:removeChild(keep.probe) end)
        keep.probe = nil
    end))
    waitFor(function() return keep.noOpts or keep.noProbe or (keep.probeView ~= nil and (C.by[keep.probeView] or 0) >= 1) end, 5000, O(function(w, met)
        if keep.noProbe or not keep.probeView then return end
        check((C.by[keep.probeView] or 0) >= 1, "W39: the panel taken off again, the page is read once more", (C.by[keep.probeView] or 0) .. " readings")
    end))
    after(300, O(function(w)
        -- the key page: its toggles without the pairing walk, and the same rows as the walk gives
        local o = K.ms() and K.ms().mainOptions
        local keyPage = nil
        for _, p in ipairs(keep.vpages) do if p.keys then keyPage = p end end
        if not (keyPage and o and o.keyTickBoxes and #o.keyTickBoxes > 0) then
            skip("W39: the key page's toggles are read without the pairing walk", "no key page or no toggles on it here")
        else
            K.tapZero()
            local t = getTimestampMs()
            local ok, rows = pcall(MM.keyRows, keyPage)
            local took = getTimestampMs() - t
            local walks = C.n
            if not ok then check(false, "W39: the key page is read", rows)
            else
                -- old code: MM.keyRows ran the whole pairing (about 250 buttons against 250 labels) to find five tick boxes
                check(walks == 0, "W39: the key page's toggles are read without the pairing walk", walks .. " walks, " .. took .. " ms, " .. #rows .. " rows")
                local got = {}
                local inTog = false
                for _, r in ipairs(rows) do
                    if r.kind == "header" then inTog = (r.id == "toggles") elseif inTog and r.kind == "tick" then got[#got + 1] = r end
                end
                local okG, generic = pcall(keep.or0 or MM.optionRows, keyPage)
                local want = {}
                for _, r in ipairs(okG and generic or {}) do if r.kind == "tick" then want[#want + 1] = r end end
                local bad = {}
                if #got ~= #want then bad[#bad + 1] = #got .. " toggles, the walk finds " .. #want end
                for i, r in ipairs(want) do
                    local g = got[i]
                    if g and (g.control ~= r.control or g.label ~= r.label or g.opt ~= r.opt) then
                        bad[#bad + 1] = "toggle " .. i .. ": \"" .. tostring(g.label) .. "\", the walk gives \"" .. tostring(r.label) .. "\""
                    end
                end
                check(#bad == 0 and #got > 0, "W39: the key page's toggles are the same rows, in the same order, as the pairing walk gives (" .. #got .. ")", K.short(bad))
            end
        end
    end))
    after(300, O(function(w)
        -- every page (the key page too, the densest): the label each control carries, against the old every-label
        -- walk; and how many math.min / math.max calls one reading makes (the old pairing: three for every label it
        -- looked at, for every control; the bands: none)
        local bad, pages, ctl, lines = {}, 0, 0, {}
        local mathCalls, passes, ctlAll, readMs, oldMs = 0, 0, 0, 0, 0
        local read = keep.or0 or MM.optionRows
        for _, p in ipairs(keep.vpages) do
            local t0 = getTimestampMs()
            local okW, want, nc, nl, np = pcall(K.pairOld, p.view)
            local tookOld = getTimestampMs() - t0
            local okR, rows, mm, took = K.countMath(read, { view = p.view })
            if not okR then bad[#bad + 1] = tostring(p.raw) .. ": " .. tostring(rows)
            elseif not okW then bad[#bad + 1] = tostring(p.raw) .. " (the check's own walk): " .. tostring(want)
            else
                mathCalls, ctlAll, readMs = mathCalls + mm, ctlAll + (nc or 0), readMs + took
                if want == nil then lines[#lines + 1] = tostring(p.raw) .. " " .. #rows .. " rows " .. took .. " ms (labels not compared: the deadzone stepper)"
                else
                    pages, passes, oldMs = pages + 1, passes + (np or 0), oldMs + tookOld
                    lines[#lines + 1] = tostring(p.raw) .. " " .. nc .. " controls x " .. nl .. " labels, " .. #rows .. " rows, " .. took .. " ms (the old walk " .. tookOld .. " ms)"
                    for _, r in ipairs(rows) do
                        if r.control and want[r.control] ~= nil and r.kind ~= "special" then
                            ctl = ctl + 1
                            local has = r.tickNoText and "" or tostring(r.label or "")
                            if has ~= want[r.control] then
                                bad[#bad + 1] = tostring(p.raw) .. ": \"" .. has .. "\" where the every-label walk gives \"" .. want[r.control] .. "\""
                            end
                        end
                    end
                end
            end
        end
        note("W39: one reading of each page now: " .. table.concat(lines, "; "))
        if pages == 0 then skip("W39: the banded pairing gives each control the label the old walk gave", "no page to compare")
        else check(#bad == 0 and ctl > 0, "W39: the banded pairing gives each control the label the old walk gave (" .. ctl .. " controls on " .. pages .. " pages)", K.short(bad)) end
        -- old code: the reading itself was the every-label walk, so it made about passes x 3 calls
        local seen = mathCalls .. " math.min / max calls in one reading of every page (" .. ctlAll .. " controls, " .. readMs .. " ms); the old every-label walk makes "
            .. (passes * 3) .. " (" .. passes .. " label passes, " .. oldMs .. " ms in this script)"
        if passes * 3 < ctlAll * 2 then skip("W39: the pairing looks only at the labels near each control, with no every-label pass", "too few labels here to tell the two apart: " .. seen)
        else check(mathCalls < ctlAll, "W39: the pairing looks only at the labels near each control, with no every-label pass", seen) end
        X.optsOff()
        K.errCheck("W39 Options")
        K.try("W39: Options, Back", function()
            w:back()
            if w.confirm then note("Options asked on Back (" .. tostring(w.confirm) .. ") with nothing changed by this script: Discard"); w:discard() end
        end)
    end))
    waitFor(function() return MM.view == "main" end, 4000, function(met)
        X.optsOff()
        if not check(MM.view == "main", "W39: Options leaves to the main window", "view " .. tostring(MM.view)) then K.rescue() end
        local o = K.ms() and K.ms().mainOptions
        check(not (o and o.gameOptions and o.gameOptions.changed), "W39: no option is left waiting")
    end)
end

-- =========================================================================================================
-- the Mods screen: W39's other half (the Options tab), then W38 (Profiles)
function K.W() return MM.root and MM.root.modsWin end
function K.model() return ModSelector and ModSelector.instance and ModSelector.instance.model end
function K.rows() local w = K.W(); local r = {}; if w then pcall(function() r = w:rows() end) end; return r end
-- The Mods screen is left without Back: Back accepts the list, and the game's accept writes the player's
-- pz_modlist_settings.cfg (every profile in memory) and mods/default.txt again, and can reload Lua (which would end
-- this script). Nothing was changed here, so the main window is simply put up (MM.showView, as the desk does).
function K.leaveMods(w)
    w = w or K.W()
    if w then
        if w.confirm then pcall(function() w:setConfirm(false) end) end
        if w.page == "profiles" then pcall(function() w:leaveProfiles() end) end
    end
    MM.showView("main")
end
local function M(fn) return V("mods", "noMods", fn) end

function X.modsOptionsTab()
    after(300, M(function(w)
        K.tapOn()
        keep.msN, keep.msOpts, keep.msRows = 0, 0, 0
        keep.msT0 = getTimestampMs()
    end))
    -- five seconds of the Options tab's own question, asked every frame as the pane asks it
    waitFor(function()
        if keep.noMods or not keep.msT0 then return true end
        local out = ZeD.ModSettings.optionRows("ZeD_UI")
        keep.msN = keep.msN + 1
        keep.msOpts = out.count or 0
        local withRow = 0
        for _, sec in ipairs(out.sections or {}) do
            for _, e in ipairs(sec.entries or {}) do if e.kind == "opt" and e.r then withRow = withRow + 1 end end
        end
        keep.msRows = withRow
        return getTimestampMs() - keep.msT0 >= 5000
    end, 8000, M(function(w)
        if not keep.msT0 then K.tapOff(); check(false, "W39: the counter went on for the Mods screen's Options tab", "it never did (see the line before)"); return end
        local secs = (getTimestampMs() - keep.msT0) / 1000
        local seen = C.n .. " readings of the game's Mods options page, " .. C.ms .. " ms in all, over " .. keep.msN .. " asks in " .. string.format("%.1f", secs)
            .. " s; ZeD's " .. keep.msOpts .. " options, " .. keep.msRows .. " with their row (old code: read again every 2 s, 3 readings)"
        K.tapOff()
        if keep.msOpts == 0 then skip("W39: the Mods screen's Options tab does not read the page again every 2 s", "ZeD's own options are not listed here (" .. seen .. ")"); return end
        -- old code: the rows were thrown away every 2000 ms: a reading at 0, 2 and 4 s
        check(C.n <= 1, "W39: the Mods screen's Options tab reads the game's page once, not every 2 s", seen)
        local o = K.ms() and K.ms().mainOptions
        local hasPage = false
        for _, v in ipairs(o and o.tabs and o.tabs.viewList or {}) do if v.name == getText("UI_mainscreen_mods") then hasPage = true end end
        if not hasPage then skip("W39: the tab's options still carry their rows", "the game's Options has no Mods page here")
        else check(keep.msRows > 0, "W39: the tab's options still carry their rows (the control each one changes)", keep.msRows .. " of " .. keep.msOpts) end
        K.errCheck("W39 Mods options tab")
    end))
end

-- W38
function X.profClick(w, name)   -- a click on a profile's row: the row's own hit when it is drawn
    w._lastPClick = nil   -- (never a double-click: that loads the profile)
    local idx, prow = nil, nil
    for i, p in ipairs(w:profiles()) do if p.name == name and not idx then idx, prow = i, p end end
    if not idx then error("no row for " .. tostring(name)) end
    for _, h in ipairs(w._hits or {}) do
        if h.id == "mods:prow:" .. idx then h.fn(); return "the row on screen" end
    end
    w:clickProfile(prow, idx)
    return "the row's click (the row is off screen)"
end
-- the profile a Rename or Duplicate confirmed now would act on (the fixed code keeps it; the old code read the pick)
function X.profTarget(w)
    if w._pTarget ~= nil then return w._pTarget end
    return w.psel
end
function X.unstage()
    local m = K.model()
    for _, n in ipairs(keep.staged or {}) do if m and m.presets then m.presets[n] = nil end end
    keep.staged = nil
    local w = K.W()
    if w then w._diffs = nil end
end
function X.profQuestion(mode, word)
    after(300, M(function(w)
        if keep.noProf then return end
        K.try("W38: profile A picked", function() if w.psel ~= keep.pA then X.profClick(w, keep.pA) end end)
        if w.psel ~= keep.pA then w.psel = keep.pA end
        K.try("W38: " .. word .. " asked on A", function() w:setConfirm(mode) end)
    end))
    after(400, M(function(w)
        if keep.noProf then return end
        check(w.confirm == mode and w.field:isVisible(), "W38: " .. word .. " opens its name field on profile A", tostring(w.confirm) .. ", field \"" .. tostring(w.field:getText()) .. "\"")
        if mode == "rename" then keep.yes0 = K.specWord(w, "confirm:yes") end
        local ok, how = K.try("W38: profile B's row clicked while " .. word .. " is open", function() return X.profClick(w, keep.pB) end)
        keep.how = ok and how or "?"
    end))
    after(400, M(function(w)
        if keep.noProf then return end
        local bName = keep.pB or "(the No mods row)"
        -- old code: the click moved the pick to B while the question stayed open
        check(w.psel == keep.pA, "W38: a click on another profile while " .. word .. " is open does not move the pick",
            "picked " .. tostring(w.psel) .. " (A is " .. keep.pA .. ", clicked " .. bName .. " by " .. keep.how .. ")")
        -- old code: renameProfile / duplicateProfile read the pick at confirm time, so they would act on B
        check(X.profTarget(w) == keep.pA, "W38: " .. word .. " confirmed now would act on A, the profile it opened on",
            "would act on " .. tostring(X.profTarget(w)) .. "; the field says \"" .. tostring(w.field:getText()) .. "\"")
        if mode == "rename" then
            -- old code: the band checked the name against B, so A's own name read as taken and the button greyed
            if keep.yes0 ~= "live" then
                skip("W38: Rename's button stays live for A's own name after the click", "it was " .. tostring(keep.yes0) .. " before the click (the name \"" .. keep.pA .. "\" is not one the game takes)")
            else
                check(K.specWord(w, "confirm:yes") == "live", "W38: Rename's button stays live for A's own name after the click",
                    "before the click " .. tostring(keep.yes0) .. ", after " .. K.specWord(w, "confirm:yes"))
            end
        end
        check(w.confirm == mode, "W38: the question is still open after the click", tostring(w.confirm))
        K.try("W38: B on the name field (cancel)", function() w:joyB() end)
    end))
    after(300, M(function(w)
        if keep.noProf then return end
        check(not w.confirm and not w.field:isVisible(), "W38: " .. word .. " is cancelled, nothing confirmed", tostring(w.confirm))
        check(table.concat(w:presetNames(), ";") == keep.names1, "W38: the profiles are the ones there before " .. word .. " was asked", #w:presetNames() .. " profiles")
    end))
end
function X.profiles()
    after(300, M(function(w)
        keep.names0 = table.concat(w:presetNames(), ";")
        local names = w:presetNames()
        local m = K.model()
        keep.staged = {}
        K.later(X.unstage)
        -- two named profiles are needed: real ones are only read; what is missing is staged in memory, never saved
        local i = 0
        while #names < 2 and m and m.presets and i < 2 do
            i = i + 1
            local n = "zedqa_vx_profile_" .. ((i == 1) and "a" or "b")
            if not m.presets[n] then
                m.presets[n] = {}
                keep.staged[#keep.staged + 1] = n
                names[#names + 1] = n
            end
        end
        w._diffs = nil
        if #keep.staged > 0 then note("W38: " .. #keep.staged .. " empty profile(s) staged in memory for the check (never saved, taken out after): " .. table.concat(keep.staged, ", ")) end
        if #names < 2 then keep.noProf = true; skip("W38: Rename and Duplicate keep the profile they opened on", "no two profiles to use and none could be staged"); return end
        keep.pA, keep.pB = names[1], names[2]
        K.try("W38: Profiles opened", function() w:enterProfiles() end)
        keep.psel0 = w.psel
    end))
    after(500, M(function(w)
        if keep.noProf then return end
        keep.names1 = table.concat(w:presetNames(), ";")
        check(w.page == "profiles" and not w.confirm, "W38: the Profiles page is up, nothing asked", tostring(w.page))
        say("W38: profile A is \"" .. keep.pA .. "\", profile B is \"" .. keep.pB .. "\"")
    end))
    X.profQuestion("dup", "Duplicate")
    X.profQuestion("rename", "Rename")
    after(300, M(function(w)
        if w.confirm then pcall(function() w:setConfirm(false) end) end
        if not keep.noProf then w.psel = keep.psel0 end
        X.unstage()
        if w.psel and not (K.model() and K.model().presets[w.psel]) then w.psel = nil end
        if w.page == "profiles" then K.try("W38: Profiles left", function() w:leaveProfiles() end) end
    end))
    after(300, M(function(w)
        check(w.page == "list" and table.concat(w:presetNames(), ";") == keep.names0, "W38: Profiles left; the profiles are the ones found (none made, renamed or lost)", #w:presetNames() .. " profiles")
        K.errCheck("W38")
    end))
end
function X.mods()
    after(300, function() K.try("Mods: opening", MM.openMods) end)
    waitFor(function() return K.up("mods") and #K.rows() > 0 end, 10000, function(met)
        if not check(met, "Mods: the screen opens with its list", "view " .. tostring(MM.view) .. ", rows " .. #K.rows()) then keep.noMods = true; K.rescue() end
    end)
    X.modsOptionsTab()
    X.profiles()
    after(400, function()
        K.tapOff()
        X.unstage()
        if keep.noMods then return end
        if MM.view == "mods" then K.try("Mods: left (no Back: nothing accepted)", function() K.leaveMods(K.W()) end) end
    end)
    waitFor(function() return keep.noMods or MM.view == "main" end, 4000, function(met)
        if keep.noMods then return end
        if not check(MM.view == "main", "Mods: the main window is back up (the list never accepted)", "view " .. tostring(MM.view)) then K.rescue() end
        check(K.activated() == keep.mods0, "Mods: the mods in use are the ones found")
        local m = K.model()
        local left = {}
        for name in pairs((m and m.presets) or {}) do if tostring(name):sub(1, 9) == "zedqa_vx_" then left[#left + 1] = tostring(name) end end
        check(#left == 0, "Mods: no staged profile is left in the list in memory", table.concat(left, ", "))
    end)
end

-- =========================================================================================================
-- W51: Load Game, Rename file
local function LD(fn) return V("load", "noLoad", fn) end
function X.saveKeys(w)
    local t = {}
    for _, s in ipairs(w.saves or {}) do t[#t + 1] = tostring(s.key) end
    table.sort(t)
    return table.concat(t, ";")
end
-- the save a Rename confirmed now would act on (the fixed code keeps it by key; the old code read the pick)
function X.renTarget(w)
    if w.renameTarget then return w:renameTarget() end
    return w:selected()
end
function X.renWord(w)
    local s = X.renTarget(w)
    return s and tostring(s.key) or "no save"
end
function X.loadBack(w)
    if not w then return end
    if w.confirm then pcall(function() w:setConfirm(false) end) end
    pcall(function() w.renameEntry:setVisible(false) end)
    if keep.fold0 then
        for mode in pairs(keep.foldSet or {}) do w.collapsed[mode] = keep.fold0[mode] end
        keep.fold0 = nil
    end
    if keep.findSet then pcall(function() w.find:setText("") end); keep.findSet = nil end
    pcall(function() w:filter() end)
    if keep.sel0 ~= nil then w.sel = keep.sel0 end
end
function X.load()
    after(300, function()
        if not (MM.act and MM.act.load) then keep.noLoad = true; skip("W51: Rename keeps the save it opened on", "no Load game on this menu"); return end
        K.try("W51: Load game opening", MM.act.load)
    end)
    waitFor(function() return keep.noLoad or K.up("load") end, 5000, function(met)
        if keep.noLoad then return end
        if not K.up("load") then keep.noLoad = true; K.rescue(); skip("W51: Rename keeps the save it opened on", "Load game did not open (no save to load?), view " .. tostring(MM.view)) end
    end)
    after(500, LD(function(w)
        keep.saves0 = X.saveKeys(w)
        keep.sel0 = w.sel
        K.later(function() X.loadBack(K.win("load")) end)
        if #w.saves == 0 or not w:selected() then keep.noRen = true; skip("W51: Rename keeps the save it opened on", "no save listed"); return end
        -- A: the save picked as the window opened; B: another one that is listed (in a group that is open)
        local a = w:selected()
        keep.sA = a
        for _, r in ipairs(w.view or {}) do if r.save and r.save.key ~= a.key and not keep.sB then keep.sB = r.save end end
        say("W51: " .. #w.saves .. " saves; A is " .. tostring(a.key) .. ", B is " .. (keep.sB and tostring(keep.sB.key) or "(none: only one save listed)"))
        K.try("W51: Rename asked on A", function() w:startRename() end)
    end))
    after(400, LD(function(w)
        if keep.noRen then return end
        if not check(w.confirm == "rename" and w.renameEntry:isVisible() and w.renameEntry:getText() == keep.sA.saveName, "W51: Rename opens its field on save A, A's name in it",
            tostring(w.confirm) .. ", \"" .. tostring(w.renameEntry:getText()) .. "\"") then keep.noRen = true; return end
        -- a fresh name typed, as a player renaming would (never confirmed)
        w.renameEntry:setText("ZQAvx51name")
        if not keep.sB then skip("W51: a click on another save while Rename is open", "only one save is listed here"); return end
        w._lastClick = nil   -- (never a double-click: that plays the save)
        local hit = nil
        for _, h in ipairs(w._hits or {}) do if h.id == "load:save:" .. tostring(keep.sB.key) then hit = h end end
        K.try("W51: save B's row clicked while Rename is open", function()
            if hit then hit.fn() else w:clickSave(keep.sB) end
        end)
        keep.how = hit and "the row on screen" or "the row's click (the row is off screen)"
    end))
    after(400, LD(function(w)
        if keep.noRen then return end
        if keep.sB then
            -- old code: the click moved the pick to B, and rename() read the pick: B's folder would take the name typed for A
            check(w.sel == keep.sA.key, "W51: a click on another save while Rename is open does not move the pick",
                "picked " .. tostring(w.sel) .. " (clicked " .. tostring(keep.sB.key) .. " by " .. tostring(keep.how) .. ")")
            check(X.renTarget(w) == keep.sA, "W51: Rename confirmed now would rename save A, the one it opened on", "would rename " .. X.renWord(w))
            check(w.confirm == "rename", "W51: the rename field is still open after the click", tostring(w.confirm))
        end
        -- A's group folded (the header's own act)
        keep.fold0, keep.foldSet = {}, {}
        keep.fold0[keep.sA.mode] = w.collapsed[keep.sA.mode]
        keep.foldSet[keep.sA.mode] = true
        w.collapsed[keep.sA.mode] = true
        K.try("W51: A's group folded while Rename is open", function() w:filter() end)
    end))
    after(400, LD(function(w)
        if keep.noRen then return end
        -- old code: with A hidden the pick jumped to the first save still listed (or to none), and Rename followed it
        check(X.renTarget(w) == keep.sA, "W51: with A's group folded, Rename would still rename save A", "would rename " .. X.renWord(w) .. "; picked " .. tostring(w.sel))
        w.collapsed[keep.sA.mode] = keep.fold0[keep.sA.mode]
        keep.fold0 = nil
        w:filter()
        keep.findSet = true
        w.find:setText(GARBAGE)
        K.try("W51: Find filled while Rename is open", function() w:filter() end)
    end))
    after(500, LD(function(w)
        if keep.noRen then return end
        local listed = 0
        for _, r in ipairs(w.view or {}) do if r.save then listed = listed + 1 end end
        -- old code: Find hid every save, the pick went to none, and Rename had nothing to act on (its button greyed
        -- with a good new name in the field); typed a little less, it would have picked whichever save Find left first
        check(listed == 0 and X.renTarget(w) == keep.sA, "W51: with Find hiding every save, Rename would still rename save A",
            "would rename " .. X.renWord(w) .. "; " .. listed .. " saves listed")
        local fresh = sanitizeWorldName("ZQAvx51name") == "ZQAvx51name" and not checkSaveFolderExists(keep.sA.mode .. getFileSeparator() .. "ZQAvx51name")
        if fresh then
            check(K.specWord(w, "confirm:yes") == "live", "W51: Rename's button stays live for the new name while Find hides the list", K.specWord(w, "confirm:yes"))
        else
            skip("W51: Rename's button stays live for the new name", "the game would not take ZQAvx51name as a save's name here (one is really there?)")
        end
        K.try("W51: B on the rename field (cancel)", function() w:joyB() end)
    end))
    after(300, LD(function(w)
        if not keep.noRen then check(not w.confirm and not w.renameEntry:isVisible(), "W51: Rename is cancelled, nothing confirmed", tostring(w.confirm)) end
        X.loadBack(w)
        K.try("W51: the saves read again", function() w:readSaves(); w:filter() end)
        if keep.sel0 ~= nil then w.sel = keep.sel0 end
        check(X.saveKeys(w) == keep.saves0, "W51: the saves are the ones found (none renamed, none deleted)", #w.saves .. " saves")
        K.errCheck("W51")
        K.try("W51: Load game, Back", function() w:back() end)
    end))
    waitFor(function() return keep.noLoad or MM.view == "main" end, 4000, function(met)
        if keep.noLoad then return end
        if not check(MM.view == "main", "W51: Load game leaves to the main window", "view " .. tostring(MM.view)) then K.rescue() end
    end)
end

-- =========================================================================================================
-- the put-back (also reached when the time runs out or a stage throws)
function X.putBack()
    after(200, function()
        K.undoAll()
        X.welcomeOff()
        X.optsOff()
        X.unstage()
        local lw = K.win("load")
        if lw and MM.view == "load" then X.loadBack(lw) end
        local w = K.W()
        if w and w.confirm then pcall(function() w:setConfirm(false) end) end
        local ow = K.win("options")
        if MM.view == "options" and ow then
            pcall(function() ow:back(); if ow.confirm then ow:discard() end end)
        end
        if MM.view ~= "main" then K.rescue() end
    end)
    after(600, function()
        check(listFilesInZomboidLuaDirectory == G0.list and getFileReader == G0.read and getActivatedMods == G0.act
            and math.min == G0.min and math.max == G0.max
            and keep.or0 == nil and keep.kr0 == nil and keep.hs0 == nil and keep.probe == nil,
            "put back: the game's calls and math.min / max are their own, every counter is off ZeD's functions, the 1 px panel is off the page")
        check(K.activated() == keep.mods0, "put back: the mods in use are the ones found")
        check(K.same(K.readLines("ModOptions.ini"), keep.ini0), "put back: ModOptions.ini line for line")
        check(K.same(K.readLines((St and St.SETUP_FILE) or "ZeD_setup.txt"), keep.setup0), "put back: ZeD_setup.txt was never written")
        local m = K.model()
        local left = {}
        for name in pairs((m and m.presets) or {}) do if tostring(name):sub(1, 9) == "zedqa_vx_" then left[#left + 1] = tostring(name) end end
        check(#left == 0, "put back: no staged profile is left in the list", table.concat(left, ", "))
        check(MM.view == "main" and K.up("main") and MM.ctx.open == nil, "put back: the main window is up, no menu open", "view " .. tostring(MM.view))
        say("left for QA to remove: Zomboid/Lua/" .. STAGE_FILE)
    end)
    after(300, function()
        keep.zapFree = true
        K.freeZap()
        local n = K.errs()
        if n ~= nil and keep.errs0 ~= nil then say("Lua errors counted during the run: " .. (n - keep.errs0)) end
    end)
end

-- =========================================================================================================
if not (MM and MM.root and St and MM.showView) then
    after(100, function() S.fail = S.fail + 1; say("ERR ZeD's main menu is not up (no desk): nothing was done") end)
else
    X.start()
    X.reset()
    X.welcome()
    X.options()
    X.mods()
    X.load()
    mark()
    X.putBack()
end
after(300, function()
    say("end: " .. S.pass .. " pass, " .. S.fail .. " fail, " .. S.skips .. " skipped; " .. math.floor((getTimestampMs() - S.start) / 1000) .. " s; view=" .. tostring(MM and MM.view))
    say(S.fail > 0 and ("VERDICT FAIL " .. S.fail) or ("VERDICT PASS " .. S.pass))
    say("DONE")
end)

local function tickFn()
    if MM and not keep.zapFree then pcall(K.holdZap) end
    local s = S.stages[S.si]
    if not s then Events.OnFETick.Remove(tickFn); return end
    local now = getTimestampMs()
    if S.markAt and S.si < S.markAt and now - S.start > S.maxMs then
        S.fail = S.fail + 1
        say("ERR out of time at stage " .. S.si .. " of " .. #S.stages .. ": on to the put-back")
        S.si = S.markAt; S.t0 = nil
        return
    end
    if not S.t0 then S.t0 = now; S.n = 0 end
    S.n = S.n + 1
    local el = now - S.t0
    local go, met = false, false
    if s.cond then
        if S.n >= 2 then
            local ok, r = pcall(s.cond)
            met = ok and r and true or false
            if not ok and not s.said then s.said = true; say("ERR stage " .. S.si .. " (its wait): " .. tostring(r)); S.fail = S.fail + 1 end
        end
        go = met or el >= s.ms
    else
        go = el >= s.ms and S.n >= 3
    end
    if not go then return end
    S.si = S.si + 1
    S.t0 = nil
    local ok, e = pcall(s.fn, met)
    if not ok then S.fail = S.fail + 1; say("ERR stage " .. (S.si - 1) .. ": " .. tostring(e)) end
end
Events.OnFETick.Add(tickFn)
say("start (" .. #S.stages .. " stages)")
