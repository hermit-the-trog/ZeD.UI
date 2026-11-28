-- ZeDUI/tools/qa/mu_new.lua  (Nov 27 2026, QA menus sweep; tag mu_new): MAIN MENU ONLY, pushed through the QA bridge.
-- The New game flow, check by check against its map, ZeDUI/qa/audits/2026-11-27_map_menu_newgame.md (NG1 to NG64):
--   New game     the six playstyles in the game's order, Next on each lands on Spawn (or World) with the game mode
--                set and Back comes home; a double click goes on, a slow one only picks; the arrow keys; Challenges
--                (Next opens the list, sorted, every picture loads, Back lands on Challenges); the way back from a
--                challenge's occupation step (staged: the game's screen set as the challenge's Back leaves it); a
--                list of 60 made-up challenges measured against the window; Choose mods and its Back
--   Spawn        every town, the save name's reasons in words (and Next grayed), a long name, the seed (New seed,
--                an empty seed rolled at Next, Back clears it), Random and its houses, the map framing a town, the
--                videos kept, the details box, the pad's Y and its fields, Back with no previous screen
--   Sandbox      every page's rows against the game's settings, number cells (a bad number kept open, dropped on a
--                click away, the old value kept), Tab between numbers, named steps and Custom number, the game's
--                links (Zombie Count, Respawn, Migrate), Start Day after Start Month, graying, the differs-from-preset
--                count, loading a preset (asks over changes), Save as preset and Delete (named ZeDQA_preset, deleted
--                the window's own way), Find over tooltips, the values across a second visit, Next's SandboxVars, pad
--   Traits       points after each kind of change, exclusions, grants and Free traits, starting skills against the
--                game's percent, the penalty in the title, the help band's lines, the build name offered (in memory
--                only), Save and Delete of a build named ZeDQA_build, the keys, the pad's stops, the skill rows' fit
--   Looks        names both ways and a new sex, skin and hair swatches, the clothing rows, an outfit preset saved,
--                loaded and deleted (named ZeDQA_outfit), Return and A on Play (Play stubbed: never pressed)
--   Back, Back, Back to the main window, then where the game's map panel and 3D figure were left.
-- Harness lines (the desk, the put-back) carry NG0. Checks not stageable at the main menu get one SKIP each.
-- NEVER pressed: Play on Looks (nor Return or A there: NG64 swaps in a stub first), a challenge's Next (every New
-- game Next goes through X.ngNext, which refuses a challenge), the voice preview (NG61), any Load, Continue, Reset Lua.
--
-- What it puts back itself: every ZeD option as found; Lua/saved_builds.txt, Lua/saved_outfits.txt,
-- Lua/pz_modlist_settings.cfg and Lua/ModOptions.ini line for line; the sandbox screen's values and preset as the
-- Sandbox step found them; the builds and outfits lists in memory; MM.forceGamepad; the lightning let go.
-- Files it may write (all under Zomboid/): Sandbox Presets/ZeDQA_preset.cfg (deleted again by the window's Delete),
-- Lua/saved_builds.txt and Lua/saved_outfits.txt (a ZeDQA_ entry saved and deleted, then the file written back as
-- found), Lua/pz_modlist_settings.cfg (Choose mods' Back saves the list's settings; written back as found).
-- Lua cannot delete a file: should saved_builds.txt or saved_outfits.txt not have been there before, an empty one
-- stays (the same as none; the runner's snapshot puts the folder back).
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/zed_only_mods.txt `
--        -Script ZeDUI/tools/qa/mu_new.lua -Tag mu_new -TimeoutSec 540
--   with $env:ZEDQA_NOSTEAM = "1" set first: a Steam launch loads the Workshop copy of ZeD, which has no QA bridge.
-- Lines: "ZEDQA mu_new PASS NGn: ..." / "FAIL ..." / "SKIP ..." / "NOTE ..." / "ERR ...", then "VERDICT PASS n" or
-- "VERDICT FAIL n", then DONE (always from a later frame than the bridge's run line). grep "ZEDQA mu_new".
local TAG = "mu_new"
local MM = ZeD and ZeD.MainMenu
local St = ZeD and ZeD.Settings
local S = { pass = 0, fail = 0, skips = 0, stages = {}, si = 1, maxMs = 400000, start = getTimestampMs() }
local keep = { said = {}, lost = {}, ng1bad = {}, ng1seen = {}, ng1want = 0 }
local K = {}
local X = {}
local PCT = string.char(37)
local QA_PRESET, QA_BUILD, QA_OUTFIT = "ZeDQA_preset", "ZeDQA_build", "ZeDQA_outfit"

local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local function mark_id(what)
    local id = tostring(what or ""):match("^(NG%d+)")
    if id then keep.said[id] = true end
end
local function check(ok, what, detail)
    if ok then S.pass = S.pass + 1 else S.fail = S.fail + 1 end
    mark_id(what)
    say((ok and "PASS " or "FAIL ") .. what .. ((detail ~= nil and detail ~= "") and (" | " .. tostring(detail)) or ""))
    return ok and true or false
end
local function skip(what, why) S.skips = S.skips + 1; mark_id(what); say("SKIP " .. what .. " | " .. tostring(why)) end
local function note(s) mark_id(s); say("NOTE " .. tostring(s)) end

-- ---- the stages, on the clock (as bx_menu.lua): after(ms, fn), waitFor(cond, maxMs, fn), mark()
local function after(ms, fn) S.stages[#S.stages + 1] = { ms = ms, fn = fn } end
local function waitFor(cond, maxMs, fn) S.stages[#S.stages + 1] = { ms = maxMs, cond = cond, fn = fn } end
local function mark() S.markAt = #S.stages + 1 end

function K.short(list)
    local out = {}
    for i, s in ipairs(list or {}) do if i <= 6 then out[#out + 1] = tostring(s) end end
    if #(list or {}) > 6 then out[#out + 1] = "(+" .. (#list - 6) .. " more)" end
    return table.concat(out, "; ")
end
-- a list walked a step every gapMs: stepFn acts, verifyFn looks one gap later (a mismatch into st.bad)
local function each(label, gapMs, maxMs, listFn, stepFn, verifyFn, doneFn)
    local st = { bad = {}, i = 0, at = 0 }
    waitFor(function()
        local now = getTimestampMs()
        if not st.list then
            local ok, l = pcall(listFn)
            st.list = (ok and l) or {}
            if not ok then st.bad[#st.bad + 1] = "the list: " .. tostring(l) end
        end
        if now - st.at < gapMs then return false end
        if st.i >= 1 and st.i <= #st.list and verifyFn then
            local ok, e = pcall(verifyFn, st.list[st.i], st.i, st)
            if not ok then st.bad[#st.bad + 1] = "after step " .. st.i .. ": " .. tostring(e) end
        end
        st.i = st.i + 1
        if st.i > #st.list then return true end
        st.at = now
        local ok, e = pcall(stepFn, st.list[st.i], st.i, st)
        if not ok then st.bad[#st.bad + 1] = "step " .. st.i .. ": " .. tostring(e) end
        return false
    end, maxMs, function(met)
        if #st.list == 0 and #st.bad == 0 then skip(label, "nothing to walk here (the path did not reach it)")
        else
            check(#st.bad == 0 and met, label .. " (" .. math.min(st.i, #st.list) .. " of " .. #st.list .. ")",
                K.short(st.bad) .. ((not met) and " (ran out of time)" or ""))
        end
        if doneFn then
            local ok, e = pcall(doneFn, st)
            if not ok then check(false, label .. ": its last look ran without an error", e) end
        end
    end)
end

-- ---- small things (bx_menu.lua's)
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
function K.opts()
    if St and St.opts then return St.opts end
    local zo = nil
    pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end)
    return zo
end
function K.opt(id) local o = K.opts(); return o and o.dict and o.dict[id] end
function K.val(id)
    local o, v = K.opt(id), nil
    if o then pcall(function() v = o:getValue() end) end
    return v
end
function K.snapAll()
    local t = {}
    for _, o in ipairs((K.opts() and K.opts().data) or {}) do
        if o.id and o.getValue and o.type ~= "multipletickbox" and o.type ~= "button" then
            local ok, v = pcall(o.getValue, o)
            if ok and v ~= nil and type(v) ~= "table" then t[o.id] = v end
        end
    end
    return t
end
function K.count(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
function K.diff(a, b)
    local bad, seen = {}, {}
    for id, v in pairs(a or {}) do seen[id] = true; if (b or {})[id] ~= v then bad[#bad + 1] = id .. "=" .. tostring((b or {})[id]) .. " (was " .. tostring(v) .. ")" end end
    for id, v in pairs(b or {}) do if not seen[id] then bad[#bad + 1] = id .. "=" .. tostring(v) .. " (was nil)" end end
    table.sort(bad)
    return bad
end
function K.setAll(t)
    for id, v in pairs(t or {}) do
        local o = K.opt(id)
        if o and o.setValue and K.val(id) ~= v then pcall(function() o:setValue(v) end) end
    end
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
function K.writeLines(name, lines, eol)
    if not lines then return end
    pcall(function()
        local w = getFileWriter(name, true, false)
        for i, l in ipairs(lines) do
            w:write(l)
            if eol or i < #lines then w:write(eol or "\n") end
        end
        w:close()
    end)
end
function K.same(a, b)
    if a == nil or b == nil then return a == b end
    return table.concat(a, "\n") == table.concat(b, "\n")
end
function K.copy(t) local o = {}; for i, v in ipairs(t or {}) do o[i] = v end; return o end
function K.has(t, x) for _, v in ipairs(t or {}) do if v == x then return true end end; return false end

-- ---- the lightning: held off for the run, let go at the end
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
    if view == "newgame" then return r.newWin end
    if view == "mods" then return r.modsWin end
    for _, rv in ipairs(MM.views or {}) do if rv.view == view then return r[rv.field] end end
    return nil
end
function K.up(view)
    local w = K.win(view)
    return MM.view == view and w ~= nil and w:isVisible() and true or false
end
function K.sits(w)
    if not w then return "no window" end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local x, y, ww, hh = w:getAbsoluteX(), w:getAbsoluteY(), w:getWidth(), w:getHeight()
    local g = math.floor(x) .. "," .. math.floor(y) .. " " .. math.floor(ww) .. "x" .. math.floor(hh) .. " on " .. sw .. "x" .. sh
    if not w:isVisible() then return "hidden (" .. g .. ")", g end
    if ww <= 0 or hh <= 0 then return "no size (" .. g .. ")", g end
    if x < -1 or y < -1 or x + ww > sw + 1 or y + hh > sh + 1 then return "off the screen (" .. g .. ")", g end
    return nil, g
end
function K.onScreen(label, w)
    local bad, g = nil, nil
    local ok, e = pcall(function() bad, g = K.sits(w) end)
    if not ok then bad = tostring(e) end
    check(bad == nil, label .. ": sits on screen", bad or g)
end
-- back to the main window whatever is up (a game screen left showing would hide the desk)
function K.rescue()
    local m = K.ms()
    for _, f in ipairs({ "charCreationMain", "charCreationProfession", "sandOptions", "mapSpawnSelect", "worldSelect" }) do
        local sc = m and m[f]
        if sc then pcall(function() if sc:isVisible() then sc:setVisible(false) end end) end
    end
    MM.ctx.open = nil
    pcall(MM.showView, "main")
end
-- why New game's Back (the game's resetLuaIfNeeded) would reload Lua and end the script, or nil
function K.wouldReset()
    local need = false
    pcall(function() need = ActiveMods.requiresResetLua(ActiveMods.getById("default")) end)
    if need then return "the mod list in memory is not the one running" end
    return nil
end
function K.spec(w, id)
    for _, s in ipairs((w and w._specs) or {}) do if s.id == id then return s end end
    return nil
end
function K.lostOnce(view)
    if keep.lost[view] then return end
    keep.lost[view] = true
    check(false, "NG0: the " .. view .. " window stays up while it is walked", "view " .. tostring(MM.view))
end
-- a stage's function that runs only while view's window is up: fn(w, met)
local function NG(view, fn)
    return function(met)
        if keep.noPath then return end
        local w = K.win(view)
        if not (w and MM.view == view) then K.lostOnce(view); return end
        return fn(w, met)
    end
end

-- ---- the game's screens behind the windows
function X.van() return MapSpawnSelect and MapSpawnSelect.instance end
function X.sand() local m = K.ms(); return m and m.sandOptions end
function X.prof() local m = K.ms(); return m and m.charCreationProfession end
function X.ccm() local m = K.ms(); return m and m.charCreationMain end
function X.desc() local m = K.ms(); return m and m.desc end
function X.ngs() local m = K.ms(); return m and m.soloScreen end

-- New game's Next, never on a challenge (a challenge's Next makes the world at once)
function X.ngNext(w)
    local d = w:items()[w.sel]
    if w.challenges or not d or d.challenge then error("refused: a challenge's Next is never pressed") end
    w:next()
end
function X.chalIndex(w)
    for i, d in ipairs(w:items()) do if w:isChallengesItem(d) then return i end end
    return nil
end
function X.modeIndex(w, mode)
    for i, d in ipairs(w:items()) do if d.mode == mode then return i end end
    return nil
end

-- =========================================================================================================
-- 0: as found
function X.start()
    after(100, function()
        keep.errs = K.errs()
        keep.errs0 = keep.errs
        keep.opt0 = K.snapAll()
        keep.ini0 = K.readLines("ModOptions.ini")
        keep.builds0 = K.readLines((BCRC and BCRC.savefile) or "saved_builds.txt")
        keep.outfits0 = K.readLines((CharacterCreationMain and CharacterCreationMain.savefile) or "saved_outfits.txt")
        keep.pzml0 = K.readLines("pz_modlist_settings.cfg")
        keep.pad0 = MM.forceGamepad
        keep.presetsFound = {}
        pcall(function() keep.presetsFound = K.jlist(getSandboxPresets()) end)
        say("as found: " .. K.count(keep.opt0) .. " options, view " .. tostring(MM.view) .. ", screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
            .. ", text size " .. tostring(ZeD.currentSize) .. ", debug " .. tostring(getDebug()) .. "; saved_builds.txt " .. (keep.builds0 and (#keep.builds0 .. " lines") or "absent")
            .. ", saved_outfits.txt " .. (keep.outfits0 and (#keep.outfits0 .. " lines") or "absent") .. ", sandbox presets " .. #keep.presetsFound)
        check(ZeD_MMNewGame and ZeD_MMSpawn and ZeD_MMSandbox and ZeD_MMTraits and ZeD_MMLooks and MM.act and MM.act.newGame and X.van() and X.sand()
            and X.prof() and X.ccm() and true or false, "NG0: the New game windows and the game's screens behind them are loaded")
        if K.has(keep.presetsFound, QA_PRESET) then note("NG0: a sandbox preset named " .. QA_PRESET .. " was already there (an earlier run's)") end
        keep.resetRisk = K.wouldReset()
        if keep.resetRisk then note("NG0: at the start the mod list in memory is not the one running: New game's Back would reload Lua, so it is left by the menu bar's way") end
    end)
    waitFor(function()
        local m = K.ms()
        return m ~= nil and not MM.waking and not MM.poweringOn() and (m.delay or 0) <= 0 and MM.root:isVisible()
    end, 30000, function(met)
        check(met, "NG0: the desk is awake (powered on, the fade-in over)", "waking " .. tostring(MM.waking))
    end)
    after(1500, function()
        if MM.view ~= "main" then note("NG0: the desk had the " .. tostring(MM.view) .. " view up at the start: back to the main window, nothing answered"); MM.showView("main") end
    end)
    after(400, function()
        check(MM.view == "main" and K.up("main"), "NG0: the main window is up", "view " .. tostring(MM.view))
        K.errCheck("NG0: the desk at rest")
    end)
end

-- =========================================================================================================
-- 1: New game, the playstyles
function X.ngOpen()
    after(200, function() K.try("NG0: New game opened", MM.act.newGame) end)
    waitFor(function() return K.up("newgame") end, 5000, function(met)
        if not check(met, "NG0: New game opens", "view " .. tostring(MM.view)) then keep.noPath = true; K.rescue() end
    end)
end
-- one playstyle: Next, where it lands, the game mode, Back
function X.modeTrip(i, d)
    after(150, NG("newgame", function(w)
        keep.tripGo = nil
        w._lastClick = nil
        w.sel = i; w.focusId = "icon:" .. i
        X.ngNext(w)
        keep.tripGo = true
    end))
    waitFor(function() return keep.noPath or not keep.tripGo or K.up("spawn") or K.up("world") end, 6000, function()
        if keep.noPath or not keep.tripGo then keep.ng1bad[#keep.ng1bad + 1] = tostring(d.mode) .. ": Next not pressed"; return end
        local gm = tostring(getWorld():getGameMode())
        local where = MM.view
        if where == "world" then keep.sawWorld = true end
        if not (where == "spawn" or where == "world") then keep.ng1bad[#keep.ng1bad + 1] = tostring(d.mode) .. ": landed on " .. tostring(where)
        elseif gm ~= tostring(d.mode) then keep.ng1bad[#keep.ng1bad + 1] = tostring(d.mode) .. ": game mode " .. gm end
        keep.ng1seen[#keep.ng1seen + 1] = tostring(d.mode) .. ">" .. tostring(where)
        local bw = K.win(where)
        if bw and bw.back then bw:back() end
    end)
    waitFor(function() return keep.noPath or K.up("newgame") end, 6000, function(met)
        if keep.noPath then return end
        if not met then
            keep.ng1bad[#keep.ng1bad + 1] = tostring(d.mode) .. ": Back left " .. tostring(MM.view)
            K.rescue(); MM.showView("newgame")
        end
    end)
end
function X.ngModes()
    after(300, NG("newgame", function(w)
        keep.ng1bad, keep.ng1seen = {}, {}
        local items = w:items()
        local same = (items == NewGameScreen.defaultGameModeData)
        local bad = {}
        for k, d in ipairs(items) do
            if tostring(getText(d.title) or "") == "" then bad[#bad + 1] = k .. ": no title" end
            if tostring(getText(d.desc) or "") == "" then bad[#bad + 1] = k .. ": no description" end
        end
        check(same and #items == 6 and #bad == 0, "NG1: the six playstyles are the game's own list, in its order, each with its title and description",
            #items .. " items, the game's table " .. tostring(same) .. (#bad > 0 and ("; " .. K.short(bad)) or ""))
        K.onScreen("NG1: New game", w)
    end))
    for i, d in ipairs((NewGameScreen and NewGameScreen.defaultGameModeData) or {}) do
        if not (GameMode and GameMode.CHALLENGES and d.mode == GameMode.CHALLENGES:toString()) then keep.ng1want = keep.ng1want + 1; X.modeTrip(i, d) end
    end
    after(200, function()
        if keep.noPath then return end
        check(#keep.ng1bad == 0 and keep.ng1want > 0 and #keep.ng1seen == keep.ng1want, "NG1: Next on each playstyle lands on Spawn (or World) with the game mode set, and Back comes home",
            table.concat(keep.ng1seen, " ") .. (#keep.ng1bad > 0 and (" | " .. K.short(keep.ng1bad)) or ""))
        K.errCheck("NG1: the playstyles")
    end)
end
-- the double click (450 ms) and the slow one; the arrow keys
function X.ngClicks()
    after(200, NG("newgame", function(w)
        keep.dbl = nil
        w.sel = 1; w._lastClick = nil
        local d = w:items()[1]
        if not d or d.challenge or w:isChallengesItem(d) or w.challenges then skip("NG9: a double click goes on", "the first icon is not a plain playstyle"); return end
        w:clickIcon(1)
        keep.dbl = (MM.view == "newgame")   -- (one click: still here)
        w:clickIcon(1)
    end))
    waitFor(function() return keep.dbl == nil or K.up("spawn") or K.up("world") end, 6000, function(met)
        if keep.dbl == nil then return end
        check(keep.dbl and met, "NG9: one click on a playstyle picks it; a second within 450 ms goes on", "landed on " .. tostring(MM.view))
        local bw = K.win(MM.view)
        if met and bw and bw.back then bw:back() end
    end)
    waitFor(function() return keep.noPath or K.up("newgame") end, 6000, function(met)
        if not met then K.rescue(); MM.showView("newgame") end
    end)
    after(200, NG("newgame", function(w)
        w.sel = 2; w._lastClick = MM.now() - 1000
        w:clickIcon(2)
        local slow = (MM.view == "newgame" and w.sel == 2)
        w:clickIcon(3)
        local other = (MM.view == "newgame" and w.sel == 3)
        w._lastClick = nil
        check(slow and other, "NG9: a slow second click only picks again, and a quick click on another icon only picks it", "view " .. tostring(MM.view) .. ", picked " .. tostring(w.sel))
        -- the keys
        w.sel = 1
        local up = w:keyOther(Keyboard.KEY_DOWN)
        local afterDown = w.sel
        local dn = w:keyOther(Keyboard.KEY_UP)
        local r1 = w:keyOther(Keyboard.KEY_RIGHT)
        local afterRight = w.sel
        w:keyOther(Keyboard.KEY_LEFT)
        note("NG6: in the playstyles Up and Down do nothing (keyOther gives " .. tostring(up) .. " and " .. tostring(dn) .. ", the pick stays " .. tostring(afterDown)
            .. "); Right moves the pick to " .. tostring(afterRight) .. " (" .. tostring(r1) .. "), Left back to " .. tostring(w.sel) .. ": with seven or more challenges only Left and Right reach the second row")
        K.errCheck("NG9: clicks and keys")
    end))
end
-- Challenges: the list, its order, its pictures; the keys there; 60 made-up challenges; Back
function X.ngChallenges()
    after(200, NG("newgame", function(w)
        keep.chal = X.chalIndex(w)
        if not keep.chal then skip("NG2: Challenges opens its list", "no Challenges playstyle here"); return end
        w.sel = keep.chal; w.focusId = "icon:" .. keep.chal
        X.ngNext(w)   -- (the Challenges playstyle's Next only opens the list)
    end))
    after(400, NG("newgame", function(w)
        if not keep.chal then return end
        local items = w:items()
        keep.chalOpen = (w.challenges == true)
        local sorted, noPic = true, {}
        for k, d in ipairs(items) do
            if k > 1 and tostring(items[k - 1].challenge and items[k - 1].challenge.name) > tostring(d.challenge and d.challenge.name) then sorted = false end
            local tex = nil
            pcall(function() tex = d.thumb and getTexture(d.thumb) end)
            if not tex then noPic[#noPic + 1] = tostring(d.title) end
            if not d.challenge then noPic[#noPic + 1] = tostring(d.title) .. " (no challenge)" end
        end
        check(keep.chalOpen and MM.view == "newgame" and #items > 0 and sorted and #noPic == 0,
            "NG2: Next on Challenges opens the list in place (nothing starts), sorted by name, every picture loads",
            #items .. " challenges, sorted " .. tostring(sorted) .. (#noPic > 0 and ("; no picture: " .. K.short(noPic)) or ""))
        K.onScreen("NG2: the challenges", w)
        if keep.chalOpen then
            w.sel = 1
            local r = w:keyOther(Keyboard.KEY_RIGHT)
            local s1 = w.sel
            local u = w:keyOther(Keyboard.KEY_DOWN)
            note("NG6: in the challenges Right moves the pick to " .. tostring(s1) .. " (" .. tostring(r) .. "); Down does nothing (" .. tostring(u) .. ", the pick stays " .. tostring(w.sel) .. ")")
            w.sel = 1
        end
    end))
    -- NG4: 60 made-up challenges (never pressed: no challenge in them, and nothing calls Next here)
    after(200, NG("newgame", function(w)
        if not keep.chalOpen then skip("NG4: many challenges fit the window", "the challenges list did not open"); return end
        local fake = {}
        local d1 = NewGameScreen.defaultGameModeData[1] or {}
        for k = 1, 60 do fake[k] = { mode = "ZeDQA_fake", title = "ZeDQA " .. k, desc = d1.desc, thumb = d1.thumb, internal = "ZeDQA_fake" } end
        w._challengeItems = fake
        w.sel = 1
        keep.fakeOn = true
    end))
    after(400, NG("newgame", function(w)
        if not keep.fakeOn then return end
        local last, n = nil, 0
        for _, s in ipairs(w._specs or {}) do
            if tostring(s.id):sub(1, 5) == "icon:" then n = n + 1; if not last or s.y + s.h > last.y + last.h then last = s end end
        end
        local back = K.spec(w, "back")
        local bottom = last and (last.y + last.h) or 0
        local band = back and back.y or w.height
        check(n == 60 and bottom <= band, "NG4: 60 challenges: every row of icons ends above the window's band (no scroll in the grid)",
            n .. " icons laid out, the last row ends at " .. math.floor(bottom) .. ", the band starts at " .. math.floor(band) .. ", window " .. math.floor(w.height)
            .. " high on " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight())
        local fits = 0
        for _, s in ipairs(w._specs or {}) do if tostring(s.id):sub(1, 5) == "icon:" and s.y + s.h <= band then fits = fits + 1 end end
        note("NG4: the game has 4 challenges (one row); at this screen " .. fits .. " of the 60 end above the band, so a mod list past " .. fits .. " challenges runs over it")
        w._challengeItems = nil
        keep.fakeOn = nil
        w.sel = 1
    end))
    after(250, NG("newgame", function(w)
        -- NG5: the longest description against the box
        local T = ZeD.T
        local width = w.width - T.px(MM.U.STACK_PAD) * 2 - T.px(32)
        local most, who = 0, ""
        for _, d in ipairs(NewGameScreen.defaultGameModeData or {}) do
            local n = #ZeD.Atoms.wrapText(MM.ui.plain(getText(d.desc) or ""), T.fontF2, width)
            if n > most then most, who = n, tostring(getText(d.title)) end
        end
        note("NG5: a description longer than its box is cut at the box, no scroll and no ellipsis; the longest playstyle description here is "
            .. most .. " lines (" .. who .. ")")
        if keep.chalOpen then
            K.try("NG2: Back from the challenges", function() w:back() end)
            check(w.challenges == false and MM.view == "newgame" and w.sel == keep.chal, "NG2: Back from the challenges lands on the playstyles with Challenges picked",
                "picked " .. tostring(w.sel) .. " of Challenges " .. tostring(keep.chal))
        end
        K.errCheck("NG2: challenges")
    end))
    -- NG3, staged: the game's New Game screen as a challenge's Back leaves it, then New game shown again
    after(250, NG("newgame", function(w)
        local ng = X.ngs()
        if not (ng and keep.chal) then skip("NG3: back from a challenge reopens its list on it", "no challenges here"); return end
        w.challenges = true; w._challengeItems = nil
        local items = w:items()
        w.challenges = false; w._challengeItems = nil
        if #items == 0 then skip("NG3: back from a challenge reopens its list on it", "no challenges here"); return end
        local k = math.min(2, #items)
        keep.ngsIn, keep.ngsSel = ng.inChallengesView, ng.selectedItem
        ng.inChallengesView = true
        ng.selectedItem = { data = items[k] }
        local ok, e = pcall(function() w:onShow() end)
        local onIt = ok and w.challenges == true and w.sel == k
        ng.inChallengesView, ng.selectedItem = keep.ngsIn, keep.ngsSel
        -- (leaving the list: Back while it is up only shows the playstyles)
        if w.challenges then w:back() end
        check(onIt and w.challenges == false, "NG3: back from a challenge's occupation step reopens the challenge list on that challenge (staged: the game's screen set as that Back leaves it, no challenge started)",
            ok and ("list " .. tostring(onIt) .. ", picked " .. tostring(k)) or tostring(e))
    end))
end
-- NG8: Choose mods, then its Back
function X.modsWhy(mw)
    local m = ModSelector and ModSelector.instance and ModSelector.instance.model
    if not (mw and m) then return "no mod list" end
    if mw:changed() then return "a change is waiting" end
    local flip = false
    pcall(function() flip = m.ModsEnabled ~= getCore():getOptionModsEnabled() end)
    if flip then return "the game's mods switch moved since the list was read" end
    local need = false
    pcall(function() need = ActiveMods.requiresResetLua(m:getActiveMods()) end)
    if need then return "the new game's load order differs from the one running" end
    return nil
end
function X.ngMods()
    after(200, NG("newgame", function(w)
        keep.modsGo = nil
        if not (ModSelector and ModSelector.instance) then skip("NG8: Choose mods and its Back", "no ModSelector here"); return end
        K.try("NG8: Choose mods", function() w:chooseMods() end)
        keep.modsGo = true
    end))
    waitFor(function() return not keep.modsGo or K.up("mods") end, 10000, function(met)
        if not keep.modsGo then return end
        local inst = ModSelector.instance
        check(met and inst.model.isNewGame == true and inst.returnToUI == NewGameScreen.instance, "NG8: Choose mods opens the mod list for a new game, coming back to New game",
            "view " .. tostring(MM.view) .. ", new game " .. tostring(inst.model.isNewGame))
        if not met then keep.modsGo = nil; K.rescue(); MM.showView("newgame"); return end
    end)
    after(600, function()
        if not keep.modsGo then return end
        local mw = K.win("mods")
        local why = X.modsWhy(mw)
        if why then
            note("NG8: the mod list was left without its Back (" .. why .. ": Back would reload Lua)")
            MM.showView("newgame")
        else
            K.try("NG8: the mod list's Back", function() mw:back() end)
        end
    end)
    waitFor(function() return not keep.modsGo or K.up("newgame") end, 6000, function(met)
        if not keep.modsGo then return end
        check(met, "NG8: the mod list's Back lands on New game", "view " .. tostring(MM.view))
        if not met then K.rescue(); MM.showView("newgame") end
        local why = K.wouldReset()
        check(why == nil, "NG8: with no mod changed, New game's Back would not reset Lua (the reset itself is never run)", why)
        K.errCheck("NG8: Choose mods")
    end)
end
-- not stageable here
function X.ngSkips()
    after(50, function()
        skip("NG7: a challenge's Next and the save it may leave", "never pressed: a challenge's Next makes the world at once (read only)")
        skip("NG10: Better Mod Experience's checks on Next", "that mod is not loaded in this run")
        local ws = WorldSelect and WorldSelect.instance
        local choices = false
        pcall(function() choices = ws:hasChoices() end)
        local why = choices and "map groups are here, but this script does not walk the World step" or "no map mods: WorldSelect has one map group, the World step never shows"
        for _, id in ipairs({ "NG11: World shows only with two or more map groups", "NG13: an ignored map group and the world index",
                              "NG14: World's Advanced panel", "NG15: World's details scroll" }) do skip(id, why) end
        if keep.sawWorld then note("NG11: the World step showed on this run") end
        local words = tostring(ZeD.tr("UI_ZeD_MMHelp_WorldNext") or "")
        check(not words:lower():find("start the new game", 1, true), "NG12: World's Next help names the next step (the spawn town), not the start", words)
        skip("NG21: respawn Random with only with-player places", "a running game only (a death or a second player)")
        skip("NG63: a refused respawn accept brings Looks back", "a running game only (a death or a second player)")
    end)
end
function X.ngToSpawn()
    after(200, NG("newgame", function(w)
        local sb = X.modeIndex(w, GameMode.SANDBOX:toString())
        if not sb then keep.noPath = true; skip("NG16: the Sandbox path", "no Sandbox playstyle here"); return end
        w.sel = sb; w.focusId = "icon:" .. sb
        X.ngNext(w)
    end))
    waitFor(function() return keep.noPath or K.up("spawn") or K.up("world") end, 6000, function()
        if keep.noPath then return end
        if MM.view == "world" then note("NG11: more than one world here: the first is taken"); pcall(function() K.win("world"):next() end) end
    end)
    waitFor(function() return keep.noPath or K.up("spawn") end, 6000, function(met)
        if keep.noPath then return end
        if not check(met, "NG0: Sandbox goes on to the spawn town", "view " .. tostring(MM.view)) then keep.noPath = true; K.rescue() end
    end)
end

-- =========================================================================================================
-- 2: Spawn
function X.spawnLook()
    after(400, NG("spawn", function(w)
        local v = X.van()
        K.onScreen("NG26: Spawn", w)
        keep.name0 = w.nameEntry:getText() or ""
        keep.details = w:hasDetails() and true or false
        local mp = v and v.mapPanel
        keep.mapIn = mp and mp.parent == w and getmetatable(mp) == ZeD_MMSpawnMap
        check(#w:items() > 0 and keep.details, "NG0: Spawn lists the towns, with the save name and seed (a world is being made)", #w:items() .. " towns, details " .. tostring(keep.details))
        K.errCheck("NG16: Spawn open")
    end))
    waitFor(function() local v = X.van(); return keep.noPath or (v and v.mapPanel and v.mapPanel.hasResetView) end, 8000, function(met)
        keep.mapReady = met and true or false
        if not met then note("NG22: the map's data did not load in 8 s: the map checks are skipped") end
    end)
    each("NG24: every town picked, each drawn with its map and video", 200, 15000, function()
        local l = {}
        if keep.noPath or MM.view ~= "spawn" then return l end
        for i = 1, math.min(40, #K.win("spawn"):items()) do l[#l + 1] = i end
        return l
    end, function(i) K.win("spawn"):pick(i) end,
    function(i, _, st) if K.win("spawn").sel ~= i then st.bad[#st.bad + 1] = "town " .. i .. " not picked" end end,
    function()
        local w = K.win("spawn")
        local n = K.count(w and w.videos)
        note("NG24: the town videos are made at 1920x1080 and kept for the session: " .. n .. " held after one look at each town")
        local it = w and w._cur
        note("NG25: the description box is " .. tostring(w and w._descH) .. " px for every town (the tallest town's words); the town on screen needs "
            .. tostring(w and w._descContentH) .. " px")
        K.errCheck("NG24: every town")
    end)
end
function X.spawnName()
    after(200, NG("spawn", function(w)
        keep.exists = false
        pcall(function() keep.exists = checkSaveFolderExists(tostring(getWorld():getGameMode()) .. getFileSeparator() .. "ZeD-QA") end)
        if not keep.exists then note("NG16: Saves/" .. tostring(getWorld():getGameMode()) .. "/ZeD-QA is not here: the exists case is left out") end
    end))
    each("NG16: each refused save name says why in words and grays Next", 250, 8000, function()
        if keep.noPath or MM.view ~= "spawn" or not keep.details then return {} end
        local l = { { "", "UI_ZeD_Spawn_ErrNoName" }, { "a b", "UI_ZeD_Spawn_ErrSpaces" }, { "a?b", "UI_ZeD_Spawn_ErrCharacters" },
                    { ".a", "UI_ZeD_Spawn_ErrDot" }, { "a.", "UI_ZeD_Spawn_ErrDot" } }
        if keep.exists then l[#l + 1] = { "ZeD-QA", "UI_ZeD_Spawn_ErrExists" } end
        l[#l + 1] = { "ZeDQA_free_name_9", nil }
        return l
    end, function(e) K.win("spawn").nameEntry:setText(e[1]) end,
    function(e, i, st)
        local w = K.win("spawn")
        local why = w:nameProblem()
        local want = e[2] and ZeD.tr(e[2]) or nil
        local nx = K.spec(w, "next")
        if why ~= want then st.bad[#st.bad + 1] = "\"" .. e[1] .. "\": " .. tostring(why) .. " (want " .. tostring(want) .. ")" end
        if nx and (nx.disabled and true or false) ~= (want ~= nil) then st.bad[#st.bad + 1] = "\"" .. e[1] .. "\": Next grayed " .. tostring(nx.disabled) end
        if e[1] == "ZeD-QA" then keep.cacheKey = w._existsKey end
    end, function() K.errCheck("NG16: save names") end)
    after(200, NG("spawn", function(w)
        if not keep.details then skip("NG17: the exists check's cache", "no save name here"); return end
        note("NG17: the exists check is cached by game mode and name (key " .. tostring(keep.cacheKey or w._existsKey)
            .. "): a folder made after the name was typed is not seen until the name changes; not staged (Lua cannot make a folder)")
        w.nameEntry:setText(string.rep("Z", 300))
    end))
    after(300, NG("spawn", function(w)
        if not keep.details then skip("NG18: a very long save name", "no save name here"); return end
        local raw = w.nameEntry:getText() or ""
        local san = ""
        pcall(function() san = sanitizeWorldName(raw) end)
        local why = w:nameProblem()
        check(#raw == 300, "NG18: a 300-letter save name stays whole in the field (no length limit, as the game)",
            "field " .. #raw .. " letters, the folder name " .. #san .. ", reason " .. tostring(why) .. " (the folder made at Play is not reached)")
        w.nameEntry:setText(keep.name0)
        K.errCheck("NG18: a long name")
    end))
end
function X.spawnSeed()
    after(200, NG("spawn", function(w)
        if not keep.details then skip("NG19: the seed", "no seed here"); return end
        K.try("NG19: New seed", function() w:newSeed() end)
        local s = w.seedEntry:getText() or ""
        check(s ~= "" and s:match("^%a+$") ~= nil and #s <= 16, "NG19: New seed fills the seed with letters, 16 at most", s)
        w.seedEntry:setText("abc123ABCDEFGHIJKLMNOPQRST")
        local t = w.seedEntry:getText() or ""
        note("NG19: the seed field's letters-only and 16 rules hold for typed keys; set from code it holds \"" .. t .. "\" (" .. #t .. " characters)")
        w.seedEntry:setText(s)
    end))
    -- NG26 and NG27: the list's room; the pad's Y and fields
    after(200, NG("spawn", function(w)
        local T = ZeD.T
        local l = w._list
        local rows = l and math.floor(l.h / T.px(30)) or 0
        check(rows >= 3, "NG26: the towns list keeps room for three rows or more under the details box",
            rows .. " rows in " .. tostring(l and math.floor(l.h)) .. " px on " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. ", text size " .. tostring(ZeD.currentSize)
            .. "; the list scrolls " .. tostring(l and l.rowsH > l.h) .. " (not 1280x720 here)")
        if not keep.details then skip("NG27: the pad's Y and fields", "no fields here"); return end
        MM.forceGamepad = true
        w.focusId = "town:" .. w.sel
        local s0 = w.seedEntry:getText() or ""
        w:joyY()
        local s1 = w.seedEntry:getText() or ""
        local hasY = false
        for _, p in ipairs(w:getFooterPrompts() or {}) do if p.glyph == "Y" then hasY = true end end
        check(s1 ~= "" and s1 ~= s0 and hasY, "NG27: with a pad, Y rolls a new seed while the fields show, and the prompts say so", s0 .. " > " .. s1)
        local jd = MM.joypad and MM.joypad() or nil
        if jd then skip("NG27: A on a field opens the game's on-screen keyboard", "a real controller is connected: the keyboard is not opened by this script")
        else
            w:edit(w.nameEntry)
            local f = w.nameEntry:isFocused()
            w.nameEntry:unfocus()
            check(f, "NG27: A on the save name field takes the field (no controller connected: the caret, not the on-screen keyboard)", "focused " .. tostring(f))
        end
        MM.forceGamepad = keep.pad0
        K.errCheck("NG27: the pad")
    end))
end
function X.spawnMap()
    -- NG20: Random, every town's houses drawn
    after(200, NG("spawn", function(w)
        keep.rnd = nil
        for i, it in ipairs(w:items()) do if w:isRandom(it) then keep.rnd = i end end
        if keep.rnd then w:pick(keep.rnd) end
    end))
    after(500, NG("spawn", function(w)
        if not keep.rnd then skip("NG20: Random shows every town's houses", "no Random here (one town)"); return end
        if not keep.mapReady then skip("NG20: Random shows every town's houses", "the map's data did not load"); return end
        local missing, towns = {}, 0
        for _, it in ipairs(w:items()) do
            if it.region and not w:isRandom(it) then
                towns = towns + 1
                if type(it._zedPts) ~= "table" then missing[#missing + 1] = tostring(it.name) end
            end
        end
        check(#missing == 0 and towns > 0, "NG20: with Random picked the map marks every town's houses", towns .. " towns" .. (#missing > 0 and ("; not marked: " .. K.short(missing)) or ""))
    end))
    -- NG22: a town framed
    after(200, NG("spawn", function(w)
        keep.t22 = nil
        if not keep.mapReady then return end
        for i, it in ipairs(w:items()) do
            if not keep.t22 and not w:isRandom(it) and it.region and type(it._zedPts) == "table" and #it._zedPts > 0 then keep.t22 = i end
        end
        if keep.t22 then w:pick(keep.t22) end
    end))
    waitFor(function()
        if not keep.t22 or keep.noPath then return true end
        local mp = X.van().mapPanel
        local g = mp and mp.zedGoal
        if not (g and g.x and g.key == mp.zedShownKey) then return false end
        local api = mp.mapAPI
        return math.abs(api:getZoomF() - g.z) < 0.02 and math.abs(api:getCenterWorldX() - g.x) < 3 and math.abs(api:getCenterWorldY() - g.y) < 3
    end, 6000, NG("spawn", function(w, met)
        if not keep.t22 then skip("NG22: the map frames a town's houses", keep.mapReady and "no town with houses" or "the map's data did not load"); return end
        local mp = X.van().mapPanel
        local api = mp.mapAPI
        local it = w:items()[keep.t22]
        local g = mp.zedGoal or {}
        local m = w._map
        local ins = w:insetRect(m, it)
        local right = ins and (ins.x - m.x) or m.w
        local zmax = (it.zoomS and it.zoomS > 0) and it.zoomS or 16
        local out, pts = 0, it._zedPts or {}
        for _, p in ipairs(pts) do
            local ux, uy = api:worldToUIX(p.x, p.y), api:worldToUIY(p.x, p.y)
            if ux < -2 or ux > right + 2 or uy < -2 or uy > m.h + 2 then out = out + 1 end
        end
        check(met and #pts > 0 and out == 0 and (g.z or 99) <= zmax + 0.001, "NG22: the map frames every house of the town left of the video, never closer than the town's own zoom",
            tostring(it.name) .. ": " .. #pts .. " houses, " .. out .. " outside the free part; zoom " .. tostring(g.z) .. " (cap " .. tostring(zmax) .. "); settled " .. tostring(met))
        -- a town with no houses
        local bare = nil
        for _, o in ipairs(w:items()) do
            if not bare and o.region and not w:isRandom(o) and type(o._zedPts) == "table" and #o._zedPts == 0 then bare = o end
        end
        if bare then
            local gb = w:mapGoal(bare, mp, m)
            local zoomed = bare.zoomX and not (bare.zoomX == 0 and bare.zoomY == 0 and bare.zoomS == 0)
            check(gb and ((zoomed and gb.x == bare.zoomX and gb.z == bare.zoomS) or ((not zoomed) and gb.key == "all")), "NG22: a town with no houses uses its map.info zoom, else the whole map",
                tostring(bare.name) .. ": " .. tostring(gb and gb.key))
        else
            note("NG22: every town here has houses: the no-houses case is not seen")
        end
        K.errCheck("NG22: the map")
    end))
end
-- Next with Random and an empty seed: a real town, a seed rolled
function X.spawnNext()
    after(200, NG("spawn", function(w)
        keep.spawnGo = nil
        if keep.details then
            w.nameEntry:setText(keep.name0)
            if w:nameProblem() then note("NG0: the save name the game offered is refused (" .. tostring(w:nameProblem()) .. "): the path stops here"); keep.noPath = true; return end
            w.seedEntry:setText("")
        end
        if keep.rnd then w:pick(keep.rnd) end
        K.try("NG0: Spawn's Next", function() w:next() end)
        keep.spawnGo = true
    end))
    waitFor(function() return keep.noPath or K.up("sandbox") or K.up("traits") end, 6000, function(met)
        if keep.noPath then return end
        if not check(K.up("sandbox"), "NG0: Spawn's Next goes on to the sandbox settings (Sandbox playstyle)", "view " .. tostring(MM.view)) then keep.noPath = true; K.rescue(); return end
        local v = X.van()
        if keep.details then
            local s = v.seedTextBox:getText() or ""
            check(s ~= "", "NG19: an empty seed gets one rolled at Next", s)
        end
        if keep.rnd then
            local it = v.listbox.items[v.listbox.selected]
            local real = it and it.item and it.item.region and it.item.name ~= getText("UI_mapspawn_random")
            check(real and true or false, "NG20: Next with Random picks one of the real towns", tostring(it and it.item and it.item.name))
        end
    end)
end

-- =========================================================================================================
-- 3: Sandbox
function X.sbFind(w, pred)
    for i, p in ipairs(w:pages()) do
        for _, r in ipairs(w:rowsFor(p)) do
            if r.kind ~= "header" and pred(r) then return r, i end
        end
    end
    return nil, nil
end
function X.sbRow(w, name) return X.sbFind(w, function(r) return r.name == name end) end
function X.optType(name) local t = nil; pcall(function() t = tostring(getSandboxOptions():getOptionByName(name):getType()) end); return t end
function X.numeric(w, r)
    local t = X.optType(r.name)
    return r.kind == "entry" and (t == "double" or t == "integer") and not w:rowDisabled(r)
end
function X.sbVals(s) local o = SandboxOptions.new(); s:settingsFromUI(o); return o end
function X.sbDiffer(a, b)
    local bad = {}
    for i = 0, a:getNumOptions() - 1 do
        local o = a:getOptionByIndex(i)
        local p = b:getOptionByName(o:getName())
        if p and p:getValueAsString() ~= o:getValueAsString() then bad[#bad + 1] = o:getName() end
    end
    return bad
end
function X.sbRestore(w)
    local s = X.sand()
    pcall(function() w:endCell() end)
    pcall(function() w:setConfirm(false) end)
    MM.ctx.open = nil
    if keep.sbPreset and s.presets[keep.sbPreset] then s.presetList.selected = keep.sbPreset end
    if keep.sbSnap then s:settingsToUI(keep.sbSnap) end
    w.find:setText("")
    w:refreshDiff(true)
end
function X.sbTick(w)
    for i, p in ipairs(w:pages()) do
        for _, r in ipairs(w:rowsFor(p)) do
            local c = r.control
            if r.kind == "tick" and c and c.selected and #(c.options or {}) == 1 and not w:rowDisabled(r) then return { r = r, c = c, i = i } end
        end
    end
    return nil
end
function X.sbLook()
    after(500, NG("sandbox", function(w)
        local s = X.sand()
        keep.sbSnap = X.sbVals(s)
        keep.sbPreset = s.presetList.selected
        K.onScreen("NG0: Sandbox", w)
        -- NG29: every page's rows against the game's settings
        local bad, nRows = {}, 0
        for _, p in ipairs(w:pages()) do
            local want, got = {}, {}
            for _, st in ipairs(p.page.settings or {}) do if s.controls[st.name] then want[#want + 1] = st.name end end
            local lastHead = nil
            for _, r in ipairs(w:rowsFor(p)) do
                if r.kind == "header" then lastHead = r.text else got[#got + 1] = r.name end
                if r.setting and r.setting.title and lastHead ~= getText("Sandbox_Title_" .. r.setting.title) then bad[#bad + 1] = tostring(r.name) .. ": no header over it" end
            end
            nRows = nRows + #got
            if table.concat(want, ",") ~= table.concat(got, ",") then
                local miss = {}
                for _, n in ipairs(want) do if not K.has(got, n) then miss[#miss + 1] = n end end
                bad[#bad + 1] = tostring(p.raw) .. ": " .. #got .. " rows of " .. #want .. ((#miss > 0) and (", missing " .. table.concat(miss, " ")) or ", out of order")
            end
            if not getDebug() then
                for _, n in ipairs(got) do if n == "WaterShutModifier" or n == "ElecShutModifier" then bad[#bad + 1] = n .. " shows outside debug" end end
            end
        end
        check(#bad == 0 and nRows > 0, "NG29: every page shows each of the game's settings in its order, with its section header; the debug-only rows only in debug",
            #w:pages() .. " pages, " .. nRows .. " rows" .. (#bad > 0 and ("; " .. K.short(bad)) or ""))
        -- NG30
        if getDebug() then
            local r = X.sbRow(w, "WaterShutModifier")
            local want = getText("IGUI_DebugContext_Title") .. " " .. getText("Sandbox_WaterShutModifier")
            check(r ~= nil and r.label == want, "NG30: in debug the shutoff-day rows read as the game's (Debug before the name)", tostring(r and r.label) .. " (the game: " .. want .. ")")
        else
            skip("NG30: the debug shutoff-day rows' names", "the game is not in debug mode")
        end
        local adv = 0
        for _, p in ipairs(w:pages()) do for _, r in ipairs(w:rowsFor(p)) do if r.kind == "adv" then adv = adv + 1 end end end
        note("NG44: there is no Advanced mode: " .. adv .. " named-steps settings each show as one list of steps; Custom number types one at a time")
        K.errCheck("NG29: Sandbox open")
    end))
end
function X.sbCells()
    -- NG31: a bad number
    after(200, NG("sandbox", function(w)
        local r, pi = X.sbFind(w, function(r) return X.numeric(w, r) end)
        if not r then skip("NG31: a bad number in a cell", "no number row"); return end
        w.find:setText(""); w.pageIdx = pi; w.scroll = 0
        local old = tostring(r.control:getText() or "")
        w:startCell(r)
        w.cell:setText("zz9x")
        local invalid = not w:cellValid()
        w:commitCell(true)
        local stays = (w._cellRow == r)
        w:commitCell()
        local dropped = (w._cellRow == nil)
        local kept = tostring(r.control:getText() or "") == old
        w:startCell(r)
        w.cell:setText("12345")
        w:keyEscape()
        local esc = (w._cellRow == nil) and tostring(r.control:getText() or "") == old
        check(invalid and stays and dropped and kept and esc, "NG31: a bad number: Return keeps the cell open, a click away drops it, Escape leaves; the old value stays",
            tostring(r.label) .. ": invalid " .. tostring(invalid) .. ", open after Return " .. tostring(stays) .. ", dropped " .. tostring(dropped) .. ", value kept " .. tostring(kept) .. ", Escape " .. tostring(esc))
    end))
    -- NG32: Tab and Shift+Tab (the rows on screen: a page with two number rows or more)
    after(200, NG("sandbox", function(w)
        keep.tabPage = nil
        for i, p in ipairs(w:pages()) do
            local n = 0
            for _, r in ipairs(w:rowsFor(p)) do if (r.kind == "entry" or r.kind == "adv") and not w:rowDisabled(r) then n = n + 1 end end
            if not keep.tabPage and n >= 2 then keep.tabPage = i end
        end
        if keep.tabPage then w.pageIdx = keep.tabPage; w.scroll = 0 end
    end))
    after(300, NG("sandbox", function(w)
        if not keep.tabPage then skip("NG32: Tab between number rows", "no page with two number rows"); return end
        local rows = w._rowsNow or {}
        local function nextOf(at, dir)
            local i = at + dir
            while rows[i] do
                if (rows[i].kind == "entry" or rows[i].kind == "adv") and not w:rowDisabled(rows[i]) then return rows[i] end
                i = i + dir
            end
            return nil
        end
        local a = nil
        for i, r in ipairs(rows) do if not a and (r.kind == "entry" or r.kind == "adv") and not w:rowDisabled(r) then a = i end end
        local want = a and nextOf(a, 1)
        w:startCell(rows[a])
        w:tabCell(1)
        local r2 = w._cellRow
        w:tabCell(-1)
        local r3 = w._cellRow
        w:endCell()
        check(want ~= nil and r2 == want and r3 == rows[a], "NG32: Tab goes to the next number row (grayed ones skipped), Shift+Tab back",
            tostring(rows[a] and rows[a].label) .. " > " .. tostring(r2 and r2.label) .. " (want " .. tostring(want and want.label) .. ") > " .. tostring(r3 and r3.label))
        K.errCheck("NG31: number cells")
    end))
end
function X.sbLinks()
    after(200, NG("sandbox", function(w)
        local s = X.sand()
        -- NG33: the named steps
        local r = X.sbRow(w, "ZombieConfig.PopulationMultiplier")
        local zc = s.controls["Zombies"]
        if not (r and r.kind == "adv") then skip("NG33: named steps", "no Zombie Count steps row")
        else
            local c = r.control
            local vals = c.setting.advancedCombo.values
            local bad = {}
            for i = 1, #vals do
                w:setAdv(r, i)
                if tostring(c.entry:getText()) ~= tostring(vals[i].text) or c.combo.selected ~= i then bad[#bad + 1] = "step " .. i .. ": " .. tostring(c.entry:getText()) end
                if zc and zc.selected ~= i then bad[#bad + 1] = "step " .. i .. ": Zombie Count " .. tostring(zc.selected) end
            end
            local rz = X.sbRow(w, "Zombies")
            if rz and zc then
                local z0 = zc.selected
                w:nudge(rz, (z0 > 1) and -1 or 1)
                local want = ZombiePopulationMultiplierTable and ZombiePopulationMultiplierTable[zc.selected]
                if want ~= nil and tostring(c:getText()) ~= tostring(want) then bad[#bad + 1] = "Zombie Count " .. zc.selected .. ": the multiplier reads " .. tostring(c:getText()) .. ", not " .. tostring(want) end
            else
                note("NG33: Zombie Count is not a row of its own here: only the steps' way is checked")
            end
            w:startCell(r)
            w.cell:setText("1.2345")
            w:commitCell(true)
            local custom = tostring(c:getText()) == "1.2345" and w:advLabel(c) == getText("Sandbox_Custom")
            if not custom then bad[#bad + 1] = "Custom number: " .. tostring(c:getText()) .. " reads " .. tostring(w:advLabel(c)) end
            check(#bad == 0, "NG33: each named step puts its number in and Zombie Count follows (both ways); Custom number types a value and reads Custom", K.short(bad))
        end
        -- NG34: Zombie Respawn's three numbers, Zombie Migrate's hours
        local bad = {}
        local rr = X.sbRow(w, "ZombieRespawn")
        if rr and rr.kind == "combo" then
            local c = rr.control
            w:nudge(rr, (c.selected > 1) and -1 or 1)
            local hours = { "16.0", "72.0", "216.0", "0.0" }
            local got = tostring(s.controls["ZombieConfig.RespawnHours"]:getText())
            if hours[c.selected] and got ~= hours[c.selected] then bad[#bad + 1] = "Respawn step " .. c.selected .. ": hours " .. got .. ", not " .. hours[c.selected] end
        else bad[#bad + 1] = "no Zombie Respawn row" end
        local rm = X.sbRow(w, "ZombieMigrate")
        if rm and rm.kind == "tick" and not w:rowDisabled(rm) then
            for _ = 1, 2 do
                w._tickCol = 1
                w:activateRow(rm)
                local on = rm.control.selected[1] == true
                local got = tostring(s.controls["ZombieConfig.RedistributeHours"]:getText())
                if got ~= (on and "12.0" or "0.0") then bad[#bad + 1] = "Migrate " .. tostring(on) .. ": hours " .. got end
            end
        else bad[#bad + 1] = "no Zombie Migrate tick" end
        check(#bad == 0, "NG34: Zombie Respawn sets its three numbers and Zombie Migrate its hours, through the game's own handlers", K.short(bad))
        -- NG35: Start Day after Start Month (set to January, day 31, then February)
        local sm, sd = s.controls.StartMonth, s.controls.StartDay
        if sm and sd then
            keep.sm0 = sm.selected
            sm.selected = 1
            pcall(function() s:syncStartDay() end)
            sd.selected = #sd.options
            sm.selected = 2
            keep.sd35 = true
        else skip("NG35: Start Day follows Start Month", "no Start Month or Start Day control") end
    end))
    after(300, NG("sandbox", function(w)
        if not keep.sd35 then return end
        local s = X.sand()
        local sd = s.controls.StartDay
        local feb = nil
        pcall(function() feb = getGameTime():daysInMonth(getSandboxOptions():getFirstYear(), 1) end)
        check(feb ~= nil and #sd.options == feb and sd.selected <= feb, "NG35: Start Day's list follows Start Month while the game's screen is hidden (February)",
            #sd.options .. " days listed, " .. tostring(feb) .. " in February " .. tostring(getSandboxOptions():getFirstYear()) .. ", day picked " .. tostring(sd.selected))
        K.errCheck("NG33: links")
    end))
end
function X.sbGray()
    after(200, NG("sandbox", function(w)
        local s = X.sand()
        local bad = {}
        local wm = s.controls["Map.AllowWorldMap"]
        local rMini = X.sbRow(w, "Map.AllowMiniMap")
        if wm and rMini then
            local was = wm.selected[1]
            wm.selected[1] = false
            local mv = rMini.control.selected[1]
            w._tickCol = 1
            w:activateRow(rMini)
            local took = w:nudge(rMini, 1)
            if not w:rowDisabled(rMini) then bad[#bad + 1] = "mini map not grayed without the world map" end
            if rMini.control.selected[1] ~= mv then bad[#bad + 1] = "a grayed mini map row took a press" end
            wm.selected[1] = true
            if w:rowDisabled(rMini) then bad[#bad + 1] = "mini map grayed with the world map on" end
            wm.selected[1] = was
            if not took then bad[#bad + 1] = "a grayed row let Left and Right through" end
        else bad[#bad + 1] = "no world map or mini map row" end
        local gt = s.controls["MultiplierConfig.GlobalToggle"]
        local rG = X.sbRow(w, "MultiplierConfig.Global")
        local rSkill = X.sbFind(w, function(r) local n = tostring(r.name or ""); return n:sub(1, 17) == "MultiplierConfig." and n ~= "MultiplierConfig.Global" and n ~= "MultiplierConfig.GlobalToggle" end)
        if gt and rG and rSkill then
            local was = gt.selected[1]
            gt.selected[1] = true
            if w:rowDisabled(rG) or not w:rowDisabled(rSkill) then bad[#bad + 1] = "global on: global grayed " .. tostring(w:rowDisabled(rG)) .. ", a skill grayed " .. tostring(w:rowDisabled(rSkill)) end
            gt.selected[1] = false
            if not w:rowDisabled(rG) or w:rowDisabled(rSkill) then bad[#bad + 1] = "global off: global grayed " .. tostring(w:rowDisabled(rG)) .. ", a skill grayed " .. tostring(w:rowDisabled(rSkill)) end
            gt.selected[1] = was
        else note("NG36: no multiplier rows here: only the map rows are checked") end
        check(#bad == 0, "NG36: the mini map grays without the world map, the multipliers by the global toggle, and a grayed row takes no press", K.short(bad))
        -- NG37: the count against the preset, and its 400 ms
        local scratch = X.sbVals(s)
        local p = w:preset()
        local mine = 0
        for i = 0, scratch:getNumOptions() - 1 do
            local o = scratch:getOptionByIndex(i)
            local n = o:getName()
            local po = p and p.options and p.options:getOptionByName(n)
            if s.controls[n] and po and po:getValueAsString() ~= o:getValueAsString() then mine = mine + 1 end
        end
        w:refreshDiff(true)
        local same = (w.nDiff == mine)
        local t = X.sbTick(w)
        local quick, later = nil, nil
        if t then
            local n0 = w.nDiff
            t.c.selected[1] = not (t.c.selected[1] == true)
            w:refreshDiff(false)
            quick = (w.nDiff == n0)
            keep.t37 = { t = t, n0 = n0 }
        end
        check(same, "NG37: the differs-from-preset count is every control whose value is not the chosen preset's", "count " .. tostring(w.nDiff) .. ", measured " .. mine)
        if t then keep.quick37 = quick end
    end))
    after(500, NG("sandbox", function(w)
        local k = keep.t37
        if not k then skip("NG37: the count refreshes after 400 ms", "no tick box to flip"); return end
        w:refreshDiff(false)
        local moved = (w.nDiff ~= k.n0) and w.diff[k.t.r.name] ~= nil
        check(keep.quick37 and moved, "NG37: a change shows in the count within 400 ms (not on the same frame), and its row gets the dot",
            "at once " .. tostring(keep.quick37) .. ", after 0.5 s " .. tostring(k.n0) .. " > " .. tostring(w.nDiff))
        k.t.c.selected[1] = not (k.t.c.selected[1] == true)
        keep.t37 = nil
        K.errCheck("NG36: graying and the count")
    end))
end
function X.sbPresets()
    -- NG38: loading a preset
    after(200, NG("sandbox", function(w)
        local s = X.sand()
        local sel0 = s.presetList.selected
        w:loadPreset(sel0)
        local clean = (w.nDiff == 0)
        w:pickPreset(sel0)
        local nothing = (not w.confirm) and s.presetList.selected == sel0
        local other = (sel0 == 1) and 2 or 1
        w:pickPreset(other)
        local atOnce = (not w.confirm) and s.presetList.selected == other
        local t = X.sbTick(w)
        local asks, onKeep, stays = false, false, false
        if t then
            t.c.selected[1] = not (t.c.selected[1] == true)
            w:refreshDiff(true)
            w:pickPreset(sel0)
            asks = (w.confirm == "load") and w._pending == sel0
            onKeep = (w.focusId == "confirm:no")
            stays = s.presetList.selected == other
            w:setConfirm(false)
            t.c.selected[1] = not (t.c.selected[1] == true)
        end
        check(clean and nothing and atOnce and asks and onKeep and stays, "NG38: the same preset with no changes does nothing, another loads at once; over changes it asks first and lands on Keep editing",
            "clean " .. tostring(clean) .. ", same " .. tostring(nothing) .. ", at once " .. tostring(atOnce) .. ", asks " .. tostring(asks) .. ", on Keep editing " .. tostring(onKeep) .. ", nothing loaded " .. tostring(stays))
        X.sbRestore(w)
        -- NG39: Save as preset
        local p = w:preset()
        w:setConfirm("save")
        local offered = w.field:getText()
        local want = (p and p.userDefined) and tostring(p.name) or ZeD.tr("UI_ZeD_Sandbox_NewPresetName")
        keep.offer39 = { offered, want }
        w.field:setText("")
    end))
    after(300, NG("sandbox", function(w)
        local nx = K.spec(w, "confirm:yes")
        keep.gray39 = nx and nx.disabled and true or false
        w.field:setText(QA_PRESET)
    end))
    after(300, NG("sandbox", function(w)
        local s = X.sand()
        local nx = K.spec(w, "confirm:yes")
        local live = nx and not nx.disabled
        local o = keep.offer39 or {}
        K.try("NG39: Save as preset (" .. QA_PRESET .. ")", function() w:savePreset() end)
        local p = w:preset()
        local listed = false
        pcall(function() listed = K.has(K.jlist(getSandboxPresets()), QA_PRESET) end)
        check(o[1] == o[2] and keep.gray39 and live and p and p.userDefined and p.name == QA_PRESET and listed and not w.confirm,
            "NG39: Save as preset offers the preset's name (or New), grays Save for a bad name, saves and picks the new one",
            "offered " .. tostring(o[1]) .. " (want " .. tostring(o[2]) .. "), empty grayed " .. tostring(keep.gray39) .. ", saved and picked " .. tostring(p and p.name) .. ", in the folder " .. tostring(listed))
        -- the built-in's name: the name rule and the reload's loop, read without saving
        local valid = false
        pcall(function() valid = SandboxOptions.isValidPresetName("Apocalypse") end)
        local first = nil
        for i, q in ipairs(s.presets) do if not first and q.name == "Apocalypse" then first = { i = i, user = q.userDefined } end end
        check(not (valid and first and not first.user), "NG39: a preset saved under a built-in's name reloads as the player's (not staged: it would write Sandbox Presets/Apocalypse.cfg)",
            "the name rule takes Apocalypse " .. tostring(valid) .. "; the reload's loop takes the first preset of that name: #" .. tostring(first and first.i) .. ", the built-in " .. tostring(first and not first.user))
        -- NG40: Delete
        local hasDel = false
        for _, it in ipairs(w:presetItems()) do if type(it) == "table" and it.text == ZeD.tr("UI_ZeD_Sandbox_DeletePreset", QA_PRESET) then hasDel = true end end
        keep.vals40 = X.sbVals(s)
        w:setConfirm("delete")
        keep.cancel40 = (w.focusId == "confirm:no")
        keep.hasDel40 = hasDel
    end))
    after(300, NG("sandbox", function(w)
        local s = X.sand()
        K.try("NG40: Delete " .. QA_PRESET, function() w:deletePreset() end)
        local gone = true
        pcall(function() gone = not K.has(K.jlist(getSandboxPresets()), QA_PRESET) end)
        for _, q in ipairs(s.presets) do if q.name == QA_PRESET then gone = false end end
        local moved = X.sbDiffer(keep.vals40, X.sbVals(s))
        local p = w:preset()
        w:loadPreset(1)
        -- (a built-in's pop-up: every preset, a line, Save as preset; a Delete row would make one more)
        local builtinDel = #w:presetItems() ~= #s.presets + 2
        check(keep.hasDel40 and keep.cancel40 and gone and #moved == 0 and p and p.name ~= QA_PRESET and not builtinDel,
            "NG40: Delete shows only on a saved preset, asks and lands on Cancel; after it the values stay, measured from the nearest built-in, and the file is gone",
            "offered " .. tostring(keep.hasDel40) .. ", on Cancel " .. tostring(keep.cancel40) .. ", gone " .. tostring(gone) .. ", values moved " .. #moved .. ", measured from " .. tostring(p and p.name)
            .. ", Delete on a built-in " .. tostring(builtinDel))
        X.sbRestore(w)
        K.errCheck("NG39: presets")
    end))
end
-- NG41: Find over tooltips; a word in a tooltip and in no setting's name
function X.sbWord(w)
    local labels = {}
    local rowsAll = {}
    for _, p in ipairs(w:pages()) do
        for _, r in ipairs(w:rowsFor(p)) do
            if r.kind ~= "header" then labels[#labels + 1] = string.lower(tostring(r.label or "")); rowsAll[#rowsAll + 1] = r end
        end
    end
    local all = table.concat(labels, " | ")
    for _, r in ipairs(rowsAll) do
        local t = r.control and r.control.tooltip
        if type(t) == "table" then t = t.defaultTooltip end
        if type(t) == "string" then
            for word in string.lower(MM.ui.plain(t)):gmatch("%a+") do
                if #word >= 7 and not all:find(word, 1, true) then return word, r end
            end
        end
    end
    return nil, nil
end
function X.sbFind41()
    after(200, NG("sandbox", function(w)
        local word, r = X.sbWord(w)
        keep.w41 = word and { word = word, r = r } or nil
        if not word then skip("NG41: Find matches tooltips", "no tooltip word outside every setting's name"); return end
        w.find:setText(word)
        w.scroll = 0
    end))
    after(400, NG("sandbox", function(w)
        local k = keep.w41
        if not k then return end
        local rows = w._rowsNow or {}
        local found, heads = false, 0
        for _, r in ipairs(rows) do
            if r == k.r then found = true end
            if r.kind == "header" then heads = heads + 1 end
        end
        check(found and rows[1] and rows[1].kind == "header", "NG41: Find matches a word that is only in a setting's tooltip, under its page's header",
            "\"" .. k.word .. "\": " .. #rows .. " rows, " .. heads .. " page headers, " .. tostring(k.r.label) .. " found " .. tostring(found))
        w.find:setText("")
    end))
end
-- NG45: the pad
function X.sbPad()
    after(200, NG("sandbox", function(w)
        local r, pi = X.sbFind(w, function(r) return r.kind == "combo" and not w:rowDisabled(r) and #(r.control.options or {}) > 1 end)
        keep.r45 = r
        if r then w.find:setText(""); w.pageIdx = pi; w.scroll = 0 end
        MM.forceGamepad = true
    end))
    after(300, NG("sandbox", function(w)
        local bad = {}
        local r = keep.r45
        if r then
            for _, b in ipairs(w._specs or {}) do if b.rowRef == r then w.focusId = b.id end end
            local c0 = r.control.selected
            w:joyDir((c0 > 1) and "left" or "right")
            if r.control.selected == c0 then bad[#bad + 1] = "Left or Right did not change " .. tostring(r.label) end
            w:joyDir((c0 > 1) and "right" or "left")
            if r.control.selected ~= c0 then bad[#bad + 1] = tostring(r.label) .. " not back on " .. c0 end
        else bad[#bad + 1] = "no list row" end
        local p0, n = w.pageIdx, #w:pages()
        w:joyBumper(1)
        local p1 = w.pageIdx
        w:joyBumper(-1)
        if p1 == p0 or w.pageIdx ~= p0 then bad[#bad + 1] = "RB and LB: " .. p0 .. " > " .. p1 .. " > " .. w.pageIdx .. " of " .. n end
        w:joyY()
        if MM.ctx.open ~= "presets" then bad[#bad + 1] = "Y opened " .. tostring(MM.ctx.open) end
        MM.ctx.open = nil
        -- B leaves a cell (the cell opened without the pad: with one, the pad keyboard would open), then a question
        local rn = X.sbFind(w, function(x) return X.numeric(w, x) end)
        if rn then
            MM.forceGamepad = keep.pad0
            w:startCell(rn)
            MM.forceGamepad = true
            w:joyB()
            if w._cellRow ~= nil or MM.view ~= "sandbox" then bad[#bad + 1] = "B did not just leave the cell" end
        end
        w._pending = X.sand().presetList.selected
        w:setConfirm("load")
        w:joyB()
        if w.confirm or MM.view ~= "sandbox" then bad[#bad + 1] = "B did not just leave the question" end
        MM.forceGamepad = keep.pad0
        check(#bad == 0, "NG45: pad: Left and Right change a list, RB and LB the page, Y Presets, B leaves a cell then a question (A's pad keyboard not opened here)", K.short(bad))
        X.sbRestore(w)
        K.errCheck("NG45: the pad")
    end))
end
-- NG43: a change kept across Back to New game and in again; NG19: Back clears the seed
function X.sbTrip()
    after(200, NG("sandbox", function(w)
        X.sbRestore(w)
        keep.t43 = X.sbTick(w)
        if not keep.t43 then skip("NG43: values across a second visit", "no tick box to flip"); return end
        keep.t43.v = not (keep.t43.c.selected[1] == true)
        keep.t43.c.selected[1] = keep.t43.v
        w:back()
    end))
    waitFor(function() return keep.noPath or not keep.t43 or K.up("spawn") end, 6000, function(met)
        if not keep.t43 or keep.noPath then return end
        if not check(met, "NG42: Sandbox's Back lands on Spawn", "view " .. tostring(MM.view)) then keep.noPath = true; K.rescue(); return end
        K.win("spawn"):back()
    end)
    waitFor(function() return keep.noPath or not keep.t43 or K.up("newgame") end, 6000, function(met)
        if not keep.t43 or keep.noPath then return end
        if not check(met, "NG0: Spawn's Back lands on New game", "view " .. tostring(MM.view)) then keep.noPath = true; K.rescue(); return end
        local v = X.van()
        check((v.seedTextBox:getText() or "") == "", "NG19: Spawn's Back clears the seed (the game's discardGenParams)", tostring(v.seedTextBox:getText()))
        local w = K.win("newgame")
        w.sel = X.modeIndex(w, GameMode.SANDBOX:toString()) or 1
        X.ngNext(w)
    end)
    waitFor(function() return keep.noPath or not keep.t43 or K.up("spawn") end, 6000, function(met)
        if not keep.t43 or keep.noPath then return end
        if not met then keep.noPath = true; K.rescue(); return end
        local w = K.win("spawn")
        if keep.details and w:nameProblem() then w.nameEntry:setText(keep.name0) end
        w:next()
    end)
    waitFor(function() return keep.noPath or not keep.t43 or K.up("sandbox") end, 6000, NG("sandbox", function(w, met)
        if not keep.t43 then return end
        local t = keep.t43
        local onScreen = (t.c.selected[1] == true) == t.v
        local eng = nil
        pcall(function() eng = getSandboxOptions():getOptionByName(t.r.name):getValue() end)
        w:refreshDiff(true)
        check(met and onScreen and w.diff[t.r.name] ~= nil, "NG43: a change on the screen stays across Back to New game and in again (the game resets its own options in between, not the screen's)",
            tostring(t.r.label) .. ": screen " .. tostring(t.c.selected[1]) .. ", the game's option " .. tostring(eng) .. ", count " .. tostring(w.nDiff))
        X.sbRestore(w)
        local moved = X.sbDiffer(keep.sbSnap, X.sbVals(X.sand()))
        check(#moved == 0, "NG0: the sandbox screen's values are back as the Sandbox step found them", K.short(moved))
    end))
end
function X.sbNext()
    after(200, NG("sandbox", function(w) K.try("NG42: Sandbox's Next", function() w:next() end) end))
    waitFor(function() return keep.noPath or K.up("traits") end, 6000, function(met)
        if keep.noPath then return end
        if not met then check(false, "NG42: Sandbox's Next goes on to occupation and traits", "view " .. tostring(MM.view)); keep.noPath = true; K.rescue(); return end
        local s = X.sand()
        local preset = s.presets[s.presetList.selected]
        local bad = {}
        if tostring(getWorld():getPreset()) ~= tostring(preset and preset.name) then bad[#bad + 1] = "preset " .. tostring(getWorld():getPreset()) .. ", not " .. tostring(preset and preset.name) end
        local zc = s.controls["Zombies"]
        if zc and SandboxVars and SandboxVars.Zombies ~= zc.selected then bad[#bad + 1] = "SandboxVars.Zombies " .. tostring(SandboxVars.Zombies) .. ", the screen " .. tostring(zc.selected) end
        local ws = nil
        pcall(function() ws = getSandboxOptions():getOptionByName("WaterShutModifier"):getValue() end)
        if type(ws) ~= "number" then bad[#bad + 1] = "no water shutoff day rolled" end
        check(#bad == 0, "NG42: Sandbox's Next goes on to occupation and traits with the screen's values in SandboxVars, the shutoff days rolled and the preset's name",
            "water shutoff day " .. tostring(ws) .. (#bad > 0 and ("; " .. K.short(bad)) or ""))
        K.errCheck("NG42: Sandbox's Next")
    end)
end

-- =========================================================================================================
-- 4: Occupation and traits
function X.chosenLeft()
    local n = 0
    for _, it in ipairs(X.prof().listboxTraitSelected.items) do if not it.item:isFree() then n = n + 1 end end
    return n
end
function X.traitRows(w)
    local t = {}
    for _, r in ipairs((w:columns())[2] or {}) do if r.kind == "trait" then t[#t + 1] = r end end
    return t
end
function X.hasLabel(lb, label) for _, it in ipairs(lb.items or {}) do if tostring(it.text) == tostring(label) then return true end end; return false end
function X.ptsText(w)
    local st = w.titleStats and w.titleStats[#w.titleStats]
    return st and st.text
end
function X.trLook()
    after(500, NG("traits", function(w)
        K.onScreen("NG56: Occupation and traits", w)
        keep.prof0 = X.prof().listboxProf.selected or 1
        w:clearTraits()
        K.errCheck("NG46: Traits open")
    end))
    each("NG46: the title's points and Next follow the game's PointToSpend after each kind of change", 250, 10000, function()
        if keep.noPath or MM.view ~= "traits" then return {} end
        return { "take", "take", "give", "prof", "random", "reset", "red", "reset" }
    end, function(a)
        local w = K.win("traits")
        local p = X.prof()
        if a == "take" then local r = X.traitRows(w)[1]; if r then w:takeTrait(r.trait) end
        elseif a == "give" then
            for i, it in ipairs(p.listboxTraitSelected.items) do if not it.item:isFree() then w:giveBack(i); break end end
        elseif a == "prof" then w:pickProf(math.min(2, #p.listboxProf.items))
        elseif a == "random" then w:random()
        elseif a == "reset" then w:clearTraits()
        elseif a == "red" then
            for _ = 1, 25 do
                if p:PointToSpend() < 0 then break end
                local pick = nil
                for _, r in ipairs(X.traitRows(w)) do if not pick and r.trait:getCost() > 0 then pick = r end end
                if not pick then break end
                w:takeTrait(pick.trait)
            end
        end
    end, function(a, i, st)
        local w = K.win("traits")
        local pts = X.prof():PointToSpend()
        local want = ZeD.tr(math.abs(pts) == 1 and "UI_ZeD_Traits_PointsOne" or "UI_ZeD_Traits_PointsMany", pts)
        local nx = K.spec(w, "next")
        if X.ptsText(w) ~= want then st.bad[#st.bad + 1] = a .. ": the title says " .. tostring(X.ptsText(w)) .. ", the game " .. tostring(pts) end
        if nx and (nx.disabled and true or false) ~= (pts < 0) then st.bad[#st.bad + 1] = a .. ": Next grayed " .. tostring(nx.disabled) .. " at " .. pts end
        if a == "red" then keep.red46 = pts < 0 end
    end, function()
        if keep.red46 == false then note("NG46: the points never went under zero here: Next's gray at below zero was not seen") end
        K.errCheck("NG46: points")
    end)
end
function X.trRules()
    after(200, NG("traits", function(w)
        local p = X.prof()
        local bad = {}
        w:clearTraits()
        -- exclusions
        local tex = nil
        for _, r in ipairs(X.traitRows(w)) do
            if not tex then
                local n = 0
                pcall(function() n = r.trait:getMutuallyExclusiveTraits():size() end)
                if n > 0 then tex = r.trait end
            end
        end
        if tex then
            w:takeTrait(tex)
            local ex = tex:getMutuallyExclusiveTraits()
            for j = 0, ex:size() - 1 do
                local def = CharacterTraitDefinition.getCharacterTraitDefinition(ex:get(j))
                local lab = def and def:getLabel()
                if lab and (X.hasLabel(p.listboxTrait, lab) or X.hasLabel(p.listboxBadTrait, lab)) then bad[#bad + 1] = tostring(tex:getLabel()) .. " taken, " .. tostring(lab) .. " still offered" end
            end
        else bad[#bad + 1] = "no trait with exclusions offered" end
        w:clearTraits()
        -- grants
        local tg = nil
        for _, r in ipairs(X.traitRows(w)) do
            if not tg then
                local n = 0
                pcall(function() n = r.trait:getGrantedTraits():size() end)
                if n > 0 then tg = r.trait end
            end
        end
        if tg then
            w:takeTrait(tg)
            local g = tg:getGrantedTraits()
            for j = 0, g:size() - 1 do
                local def = CharacterTraitDefinition.getCharacterTraitDefinition(g:get(j))
                if def and not X.hasLabel(p.listboxTraitSelected, def:getLabel()) then bad[#bad + 1] = tostring(tg:getLabel()) .. " taken, " .. tostring(def:getLabel()) .. " not granted" end
            end
        else note("NG47: no trait that grants another is offered here: grants not checked") end
        w:clearTraits()
        -- an occupation's own traits: Free, not given back
        local fi = nil
        for i, it in ipairs(p.listboxProf.items) do
            if not fi then
                local n = 0
                pcall(function() n = it.item:getGrantedTraits():size() end)
                if n > 0 then fi = i end
            end
        end
        if fi then
            w:pickProf(fi)
            local at, n0 = nil, #p.listboxTraitSelected.items
            for i, it in ipairs(p.listboxTraitSelected.items) do if not at and it.item:isFree() then at = i end end
            if at then
                w:giveBack(at)
                if #p.listboxTraitSelected.items ~= n0 then bad[#bad + 1] = "a Free trait was given back" end
                local freeRow = nil
                for _, r in ipairs((w:columns())[3]) do if r.kind == "chosen" and r.free then freeRow = r end end
                if not freeRow or freeRow.fn ~= nil then bad[#bad + 1] = "the Free row takes a click" end
            else bad[#bad + 1] = "occupation " .. fi .. " brought no Free trait" end
            keep.freeProf = fi
        else bad[#bad + 1] = "no occupation with traits of its own" end
        check(#bad == 0, "NG47: a trait's exclusions leave the lists, its grants come in, an occupation's own traits come in Free and cannot be given back", K.short(bad))
        w:pickProf(keep.prof0); w:clearTraits()
        K.errCheck("NG47: trait rules")
    end))
    each("NG48: every occupation's starting skills read the game's level and percent", 60, 12000, function()
        if keep.noPath or MM.view ~= "traits" then return {} end
        local l = {}
        for i = 1, math.min(40, #X.prof().listboxProf.items) do l[#l + 1] = i end
        return l
    end, function(i)
        K.win("traits"):pickProf(i)
        X.prof():checkXPBoost()
    end, function(i, _, st)
        for _, it in ipairs(X.prof().listboxXpBoost.items) do
            local lv = it.item.level or 0
            local perk = it.item.perk
            if perk ~= Perks.Fitness and perk ~= Perks.Strength then
                local cl = math.max(0, math.min(10, lv))
                local zed = (cl >= 3) and "125" or ((cl == 2) and "100" or "75")
                local game = (lv == 2) and "100" or ((lv >= 3) and "125" or "75")
                if zed ~= game then st.bad[#st.bad + 1] = tostring(it.text) .. " level " .. lv .. ": ZeD +" .. zed .. PCT .. ", the game +" .. game .. PCT end
                if lv <= 0 then keep.low48 = tostring(it.text) .. " " .. lv end
            end
        end
    end, function()
        if keep.low48 then note("NG48: a skill at level " .. keep.low48 .. " (a negative boost) reads +75" .. PCT .. " in both ZeD and the game") end
        local w = K.win("traits")
        if w then w:pickProf(keep.prof0); w:clearTraits() end
    end)
end
function X.trTitle()
    -- NG49: the penalty
    after(200, NG("traits", function(w)
        local o = getSandboxOptions():getOptionByName("NegativeTraitsPenalty")
        keep.pen0 = o:getValue()
        pcall(function() o:setValue(2) end)
        w:clearTraits()
    end))
    after(300, NG("traits", function(w)
        local zeroShown = #(w.titleStats or {}) > 1
        local p = X.prof()
        local n = 0
        for _, r in ipairs(X.traitRows(w)) do if n < 3 and r.trait:getCost() < 0 then w:takeTrait(r.trait); n = n + 1 end end
        keep.n49 = n
        keep.zero49 = zeroShown
    end))
    after(300, NG("traits", function(w)
        local p = X.prof()
        local off = p:negativeTraitOffset()
        local first = w.titleStats and w.titleStats[1]
        local shows = first and first.text == ZeD.tr("UI_ZeD_Traits_Penalty", off)
        note("NG49: with the sandbox penalty on (one per three negative traits) the title shows nothing at penalty 0 (shown " .. tostring(keep.zero49)
            .. "; the game shows the count, 0, whenever the setting is on); after " .. tostring(keep.n49) .. " negative traits it shows \"" .. tostring(first and first.text) .. "\" (penalty " .. off .. ", in words " .. tostring(shows) .. ")")
        pcall(function() getSandboxOptions():getOptionByName("NegativeTraitsPenalty"):setValue(keep.pen0) end)
        w:clearTraits()
        -- NG50: the help band's lines for each occupation
        local T = ZeD.T
        local h, fh = T.px(54), MM.fontH(T.fontF2)
        local fit, ly = 0, T.px(7)
        while ly + fh <= h - T.px(4) do fit = fit + 1; ly = ly + fh + T.px(2) end
        local width = w.width - T.px(MM.U.STACK_PAD) * 2 - T.px(24)
        local cut, worst = {}, 0
        for _, it in ipairs(p.listboxProf.items) do
            local n = 0
            local text = tostring(it.text) .. ": " .. tostring(it.tooltip or "")
            for line in (text .. "\n"):gmatch("([^\n]*)\n") do
                local pl = MM.ui.plain(line)
                if pl ~= "" then n = n + #ZeD.Atoms.wrapText(pl, T.fontF2, width) end
            end
            if n > worst then worst = n end
            if n > fit then cut[#cut + 1] = tostring(it.text) .. " " .. n end
        end
        check(#cut == 0, "NG50: the help band shows every line of each occupation's description (no scroll in it)",
            "room for " .. fit .. " lines; the longest has " .. worst .. (#cut > 0 and ("; cut: " .. K.short(cut)) or ""))
    end))
end
function X.trBuilds()
    after(200, NG("traits", function(w)
        local p = X.prof()
        keep.bopts0, keep.bsel0 = K.copy(p.savedBuilds.options), p.savedBuilds.selected
        -- NG51 in memory: a build named as the occupation is listed; the name each would offer
        local occ = tostring(p:getSelectedProf():getUIName())
        local opts = K.copy(keep.bopts0)
        if not K.has(opts, occ) then opts[#opts + 1] = occ end
        p.savedBuilds.options = opts
        p.savedBuilds.selected = 0
        w:setConfirm("save")
        local zed = w.field:getText()
        local game = occ
        local exists = false
        pcall(function() exists = p:presetExists(occ) end)
        if exists then
            local k = 1
            while p:presetExists(occ .. " " .. k) do k = k + 1 end
            game = occ .. " " .. k
        end
        w:setConfirm(false)
        p.savedBuilds.options = K.copy(keep.bopts0)
        p.savedBuilds.selected = keep.bsel0
        check(zed == game, "NG51: with a build named as the occupation already saved, Save build offers the game's numbered name (staged in memory only)",
            "ZeD offers \"" .. tostring(zed) .. "\", the game \"" .. tostring(game) .. "\": saving ZeD's would overwrite that build with no question")
        -- a build saved under a test name
        w:setConfirm("save")
        w.field:setText(QA_BUILD)
    end))
    after(250, NG("traits", function(w)
        local p = X.prof()
        local take = X.traitRows(w)[1]
        if take then w:takeTrait(take.trait) end
        K.try("NG51: Save build (" .. QA_BUILD .. ")", function() w:saveBuild() end)
        local saved = K.has(p.savedBuilds.options, QA_BUILD) and p.savedBuilds.options[p.savedBuilds.selected] == QA_BUILD
        keep.order52a = table.concat(p.savedBuilds.options, ", ")
        w:setConfirm("save")
        local offered = w.field:getText()
        K.try("NG51: Save build again under the same name", function() w:saveBuild() end)
        local asked = w.confirm
        check(saved and offered == QA_BUILD and not asked, "NG51: Save build saves and picks the build; saved again it offers the loaded build's name and overwrites with no question (as the game)",
            "saved " .. tostring(saved) .. ", offered " .. tostring(offered) .. ", asked " .. tostring(asked))
        keep.chosen53 = #p.listboxTraitSelected.items
        w:setConfirm("delete")
        keep.cancel53 = (w.focusId == "confirm:no")
    end))
    after(250, NG("traits", function(w)
        local p = X.prof()
        K.try("NG53: Delete build", function() w:deleteBuild() end)
        local gone = not K.has(p.savedBuilds.options, QA_BUILD)
        local file = BCRC.readSaveFile()
        local inFile = file[QA_BUILD] ~= nil
        check(gone and not inFile and keep.cancel53, "NG53: Delete build asks (landing on Cancel), then the build leaves the list and the file",
            "listed " .. tostring(not gone) .. ", in the file " .. tostring(inFile) .. ", on Cancel " .. tostring(keep.cancel53))
        note("NG53: after Delete ZeD loads nothing: " .. #p.listboxTraitSelected.items .. " traits on screen (were " .. tostring(keep.chosen53) .. "), the list's pick " .. tostring(p.savedBuilds.selected)
            .. " (the game loads another build)")
        note("NG52: after a save the list is in the game's pairs order (" .. tostring(keep.order52a) .. "), after ZeD's delete sorted (" .. table.concat(p.savedBuilds.options, ", ") .. ")")
        -- the file and the list as found
        if keep.builds0 then K.writeLines((BCRC and BCRC.savefile) or "saved_builds.txt", keep.builds0, "\n") end
        p.savedBuilds.options = K.copy(keep.bopts0)
        p.savedBuilds.selected = keep.bsel0
        w:clearTraits()
        K.errCheck("NG51: builds")
    end))
end
function X.trKeysPad()
    after(200, NG("traits", function(w)
        local p = X.prof()
        -- NG54: the keys
        w:pickProf(1)
        local i0 = p.listboxProf.selected
        local rd = w:keyOther(Keyboard.KEY_DOWN)
        local i1 = p.listboxProf.selected
        local ru = w:keyOther(Keyboard.KEY_UP)
        local i2 = p.listboxProf.selected
        check(rd and ru and i1 == i0 + 1 and i2 == i0, "NG54: Down and Up walk the occupations", i0 .. " > " .. tostring(i1) .. " > " .. tostring(i2))
        note("NG54: there is no keyboard way to take or give back a trait (mouse or pad only)")
        -- NG55: the pad
        MM.forceGamepad = true
        if keep.freeProf then w:pickProf(keep.freeProf) end
        local r = X.traitRows(w)[1]
        if r then w:takeTrait(r.trait) end
        w.focusId = nil
        w.jcol, w.jidx = 1, 1
    end))
    after(300, NG("traits", function(w)
        local bad = {}
        local freeStop = false
        for _, f in ipairs((w._colFocus and w._colFocus[3]) or {}) do if f.row.free then freeStop = true end end
        if freeStop then bad[#bad + 1] = "a Free trait is a pad stop" end
        local n2 = #((w._colFocus and w._colFocus[2]) or {})
        if n2 > 0 then
            w:setJoy(2, n2)
            keep.n55 = n2
            w:joyA()
        else bad[#bad + 1] = "no trait stops" end
        keep.bad55 = bad
    end))
    after(300, NG("traits", function(w)
        local bad = keep.bad55 or {}
        local n2 = #((w._colFocus and w._colFocus[2]) or {})
        if keep.n55 and (w.jidx > n2 or w.focusId ~= ("c2:" .. w.jidx)) then bad[#bad + 1] = "after A the focus is " .. tostring(w.focusId) .. " of " .. n2 end
        local n3 = #((w._colFocus and w._colFocus[3]) or {})
        local reached = false
        if n3 > 0 then
            w:setJoy(3, n3)
            for _ = 1, 30 do
                if w.focusId == "next" then reached = true; break end
                w:joyDir("down")
            end
        end
        local nx = K.spec(w, "next")
        check(#bad == 0, "NG55: pad: Free traits are not stops, and the focus stays in range when a take shortens a column", K.short(bad))
        note("NG55: Down past the last chosen row reaches Next (" .. tostring(reached) .. "), Next grayed " .. tostring(nx and nx.disabled) .. "; a Free trait's description never shows on a pad")
        MM.forceGamepad = keep.pad0
        w:clearTraits()
        -- NG56: the skill rows' room
        local T = ZeD.T
        local box = w._colBox and w._colBox[3]
        if box then
            local f2, f3 = T.fontF2, T.fontF3
            local rw = box.w - T.px(2) - T.sp.scrollbarW
            local pctW = MM.textW(f3, "+125" .. PCT)
            local px = rw - T.px(10) - pctW
            local lvX = px - T.px(10) - MM.textW(f2, "10")
            local bx = lvX - T.px(8) - T.px(56)
            local nameW = bx - T.px(14)
            check(nameW >= T.px(40), "NG56: a starting skill row keeps room for its name beside the bar, the level and +125" .. PCT,
                math.floor(nameW) .. " px for the name in a " .. math.floor(box.w) .. " px column on " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. ", text size " .. tostring(ZeD.currentSize) .. " (not 1280x720 here)")
        else skip("NG56: the skill rows' room", "the columns were not drawn") end
        w:pickProf(keep.prof0); w:clearTraits()
        K.errCheck("NG54: keys and pad")
    end))
end
function X.trNext()
    after(200, NG("traits", function(w) K.try("NG0: Traits' Next", function() w:next() end) end))
    waitFor(function() return keep.noPath or K.up("looks") end, 6000, function(met)
        if keep.noPath then return end
        if not check(met, "NG0: Traits' Next goes on to the looks", "view " .. tostring(MM.view)) then keep.noPath = true; K.rescue() end
    end)
end

-- =========================================================================================================
-- 5: Looks (Play is never pressed)
function X.lkState()
    local v, d = X.ccm(), X.desc()
    local hc = (v.hairColorButton and v.hairColorButton.backgroundColor) or {}
    return { fem = d:isFemale(), skin = v.skinColor, hair = v.hairTypeCombo.selected, voice = v.voiceTypeCombo.selected, hr = hc.r or 0, hg = hc.g or 0, hb = hc.b or 0 }
end
function X.lkDiff(a, b)
    local bad = {}
    for _, k in ipairs({ "fem", "skin", "hair", "voice" }) do if a[k] ~= b[k] then bad[#bad + 1] = k .. " " .. tostring(b[k]) .. " (saved " .. tostring(a[k]) .. ")" end end
    for _, k in ipairs({ "hr", "hg", "hb" }) do if math.abs((a[k] or 0) - (b[k] or 0)) > 0.01 then bad[#bad + 1] = "hair color " .. k end end
    return bad
end
function X.lkRow(w, pred) for _, r in ipairs(w:rowsNow()) do if pred(r) then return r end end; return nil end
function X.lkLook()
    after(600, NG("looks", function(w)
        local v = X.ccm()
        K.onScreen("NG0: Looks", w)
        local m = v.avatarPanel and v.avatarPanel.avatarPanel
        keep.figIn = m and m.parent == w
        -- NG57: a typed name reaches the game's field
        w.fore:setVisible(true)
        w.fore:focus()
        w.fore:setText("ZeDQA")
        w:syncNames()
        keep.n57a = v.forenameEntry:getText() == "ZeDQA"
        w:nameEntered(w.fore)
        keep.n57b = (not w.fore:isFocused()) and v.forenameEntry:getText() == "ZeDQA"
        K.errCheck("NG57: Looks open")
    end))
    after(300, NG("looks", function(w)
        local v = X.ccm()
        local t = w.titleStats and w.titleStats[1] and w.titleStats[1].text or ""
        keep.n57c = tostring(t):sub(1, 5) == "ZeDQA"
        keep.g0 = v.genderCombo.selected
        local r = X.lkRow(w, function(x) return x.control == v.genderCombo end)
        if r then w:nudge(r, (keep.g0 > 1) and -1 or 1) end
    end))
    after(300, NG("looks", function(w)
        local v = X.ccm()
        local rolled = w.fore:getText() == v.forenameEntry:getText() and w.fore:getText() ~= "ZeDQA"
        check(keep.n57a and keep.n57b and keep.n57c and rolled, "NG57: a typed name reaches the game's field (as typed and on Return), the title shows it, a new sex re-rolls both names",
            "typed " .. tostring(keep.n57a) .. ", Return " .. tostring(keep.n57b) .. ", title " .. tostring(keep.n57c) .. ", after the sex " .. tostring(w.fore:getText()))
        local r = X.lkRow(w, function(x) return x.control == v.genderCombo end)
        if r and v.genderCombo.selected ~= keep.g0 then w:nudge(r, (v.genderCombo.selected > keep.g0) and -1 or 1) end
        -- NG58: swatches
        local skin = X.lkRow(w, function(x) return x.kind == "swatch" and x.key == "skin" end)
        local hair = X.lkRow(w, function(x) return x.kind == "swatch" and x.key == "hair" end)
        keep.s58 = nil
        if skin and hair and #skin.colors > 1 and #hair.colors > 1 then
            local si = ((skin.cur or 1) >= #skin.colors) and 1 or ((skin.cur or 1) + 1)
            local hi = ((hair.cur or 1) >= #hair.colors) and 1 or ((hair.cur or 1) + 1)
            skin.pick(si); hair.pick(hi)
            keep.s58 = { si = si, hi = hi }
        end
    end))
    after(250, NG("looks", function(w)
        local v = X.ccm()
        if not keep.s58 then skip("NG58: skin and hair swatches", "no swatch rows"); return end
        local skin = X.lkRow(w, function(x) return x.kind == "swatch" and x.key == "skin" end)
        local hair = X.lkRow(w, function(x) return x.kind == "swatch" and x.key == "hair" end)
        local okS, okH = skin.cur == keep.s58.si, hair.cur == keep.s58.hi
        v:onHairColorPicked({ r = 0.11, g = 0.93, b = 0.02 }, true)
        local custom = X.lkRow(w, function(x) return x.kind == "swatch" and x.key == "hair" end)
        local none = custom.cur == nil
        hair.pick(keep.s58.hi)
        check(okS and okH and none, "NG58: a skin or hair swatch picked is the one marked; a hair color off the palette marks none",
            "skin " .. tostring(skin.cur) .. " (picked " .. keep.s58.si .. "), hair " .. tostring(hair.cur) .. " (picked " .. keep.s58.hi .. "), off-palette marks " .. tostring(custom.cur))
        -- NG59
        local all = false
        pcall(function() all = getSandboxOptions():getAllClothesUnlocked() end)
        local kinds = {}
        for _, r in ipairs(w:rowsNow()) do kinds[r.kind] = (kinds[r.kind] or 0) + 1 end
        note("NG59: all clothes unlocked " .. tostring(all) .. ": the outfit list shows " .. tostring(v.outfitCombo ~= nil) .. "; " .. tostring(kinds.cloth or 0)
            .. " clothing rows (item, tint, fabric), no decal row and no outfit re-roll button (the game has both with all clothes unlocked; not staged)")
        note("NG61: the voice preview is not pressed: the game's preview sets the music state to InGame and nothing in ZeD's Looks puts the menu music back")
        K.errCheck("NG58: swatches")
    end))
end
function X.lkOutfits()
    after(200, NG("looks", function(w)
        local v = X.ccm()
        keep.oopts0, keep.osel0 = K.copy(v.savedBuilds.options), v.savedBuilds.selected
        w:setConfirm("save")
        local offered = w.field:getText()
        local want = v.savedBuilds.options[v.savedBuilds.selected]
        if not want then
            want = ((w.fore:getText() or "") .. " " .. (w.sur:getText() or "")):gsub("^%s+", ""):gsub("%s+$", "")
            if want == "" then want = ZeD.tr("UI_ZeD_Looks_PresetName") end
        end
        keep.offer60 = { offered, want }
        w.field:setText(QA_OUTFIT)
        keep.st60 = X.lkState()
        K.try("NG60: Save preset (" .. QA_OUTFIT .. ")", function() w:saveOutfit() end)
        local lines = K.readLines((CharacterCreationMain and CharacterCreationMain.savefile) or "saved_outfits.txt") or {}
        keep.ver60 = tostring(lines[1] or "")
        keep.saved60 = K.has(v.savedBuilds.options, QA_OUTFIT)
        w:random()
    end))
    after(300, NG("looks", function(w)
        local v = X.ccm()
        local idx = nil
        for i, n in ipairs(v.savedBuilds.options) do if n == QA_OUTFIT then idx = i end end
        if idx then K.try("NG60: the preset loaded", function() w:loadOutfit(idx) end) end
        keep.idx60 = idx
    end))
    after(300, NG("looks", function(w)
        local v = X.ccm()
        local o = keep.offer60 or {}
        local moved = keep.idx60 and X.lkDiff(keep.st60, X.lkState()) or { "not listed" }
        w:setConfirm("delete")
        local onCancel = (w.focusId == "confirm:no")
        K.try("NG60: Delete preset", function() w:deleteOutfit() end)
        local gone = not K.has(v.savedBuilds.options, QA_OUTFIT)
        local inFile = (CharacterCreationMain.readSavedOutfitFile() or {})[QA_OUTFIT] ~= nil
        check(o[1] == o[2] and keep.saved60 and keep.ver60:sub(1, 8) == "VERSION=" and #moved == 0 and onCancel and gone and not inFile,
            "NG60: outfit presets: the name offered, saved with the file's VERSION line, loaded back over Random (sex, skin, hair, voice), Delete asks on Cancel and removes it",
            "offered " .. tostring(o[1]) .. " (want " .. tostring(o[2]) .. "), first line " .. keep.ver60 .. ", after load: " .. (#moved > 0 and K.short(moved) or "as saved")
            .. ", on Cancel " .. tostring(onCancel) .. ", gone " .. tostring(gone and not inFile))
        if keep.outfits0 then K.writeLines((CharacterCreationMain and CharacterCreationMain.savefile) or "saved_outfits.txt", keep.outfits0, "\n") end
        v.savedBuilds.options = K.copy(keep.oopts0)
        v.savedBuilds.selected = keep.osel0
        w:setConfirm(false)
        K.errCheck("NG60: outfits")
    end))
    -- NG64: Return and A on Play, with Play swapped for a stub on this window only
    after(250, NG("looks", function(w)
        local hits = 0
        local stub = function() hits = hits + 1 end
        -- (what the window held as its own before, nil when Play is only its class's; the real Play is the class's)
        local orig = rawget(w, "play")
        local real = ZeD_MMLooks and ZeD_MMLooks.play
        local function putBack()
            rawset(w, "play", orig)
            if rawget(w, "play") == stub or w.play == stub then rawset(w, "play", real) end
        end
        rawset(w, "play", stub)
        if rawget(w, "play") ~= stub then putBack(); skip("NG64: Return and A on Play", "Play could not be swapped for a stub: not tried"); return end
        w._enterAt = nil
        pcall(function() w:setConfirm(false) end)
        local free = not (w.field:isFocused() or w.fore:isFocused() or w.sur:isFocused() or w.confirm)
        if free then pcall(function() w:keyOther(Keyboard.KEY_RETURN) end) end
        local h1 = hits
        local sp = K.spec(w, "play")
        if sp and sp.fn and rawget(w, "play") == stub then pcall(sp.fn) end
        putBack()
        -- (judged on the two presses; the put-back only has to leave the real Play in place: the stub out of reach
        -- both raw and through the class)
        local restored = rawget(w, "play") ~= stub and w.play ~= stub and (real == nil or w.play == real)
        check(free and h1 == 1 and hits == 2, "NG64: Return on Looks (outside a field) and A on Play both press Play: every QA script keeps them away (Play stubbed here, never pressed)",
            "Return " .. h1 .. ", A on Play " .. (hits - h1) .. ", outside a field " .. tostring(free))
        check(restored, "NG64: the real Play is back on Looks once the stub is taken out", "raw " .. tostring(rawget(w, "play") == stub and "stub" or rawget(w, "play")) .. ", the window's Play is the class's " .. tostring(w.play == real))
    end))
end

-- =========================================================================================================
-- 6: Back, Back, Back
function X.backOne(view, label, fn, want)
    after(250, function()
        keep.bk = nil
        if keep.noPath or MM.view ~= view then return end
        MM.ctx.open = nil
        local w = K.win(view)
        keep.bk = true
        K.try(label, function() fn(w) end)
    end)
    waitFor(function() return not keep.bk or K.up(want) end, 6000, function(met)
        if not keep.bk then return end
        if not check(met, label .. " lands on " .. want, "view " .. tostring(MM.view)) then keep.noPath = true; K.rescue() end
    end)
end
function X.walkBack()
    X.backOne("looks", "NG0: Looks' Back", function(w) w:back() end, "traits")
    X.backOne("traits", "NG0: Traits' Back", function(w) w:back() end, "sandbox")
    X.backOne("sandbox", "NG45: B on Sandbox with nothing open (Back)", function(w) MM.forceGamepad = true; w:joyB(); MM.forceGamepad = keep.pad0 end, "spawn")
    X.backOne("spawn", "NG28: Spawn's Back with no previous screen", function(w)
        local v = X.van()
        keep.prev28 = v.previousScreen
        v.previousScreen = nil
        w:back()
        -- (as the game's own Back would leave it: the seed discarded, no previous screen)
        pcall(function() MapSpawnSelect.discardGenParams(v) end)
    end, "newgame")
    after(100, function()
        if keep.prev28 ~= nil or keep.bk then note("NG28: Spawn's previous screen was " .. tostring(keep.prev28) .. "; with none ZeD's Back goes to New game, where the game would go by it (Load game from Load's route)") end
    end)
    after(250, function()
        if MM.view ~= "newgame" then return end
        local w = K.win("newgame")
        if w.challenges then w:back() end
        local why = K.wouldReset()
        if why then
            check(false, "NG0: New game's Back can be pressed without a Lua reload", why .. ": left by the menu bar's way instead")
            local ng = X.ngs()
            if ng then ng.inChallengesView = false end
            MM.showView("main")
        else
            w:back()
        end
    end)
    waitFor(function() return MM.view == "main" end, 6000, function(met)
        check(met, "NG0: Back from each window reaches the main window", "view " .. tostring(MM.view))
        if not met then K.rescue() end
    end)
    after(300, function()
        local m = K.ms()
        check(m ~= nil and m.bottomPanel:isVisible() and K.up("main"), "NG0: after New game the desk is the screen up (no game screen left showing)")
        -- NG23 and NG62: where the game's map panel and 3D figure were left
        local v = X.van()
        local mp = v and v.mapPanel
        local sw = K.win("spawn")
        if mp and sw then
            check(mp.parent ~= sw, "NG23: once Spawn is left the game's map panel goes back to the game's spawn screen (else safe mode shows the game's screen with no working map)",
                "a child of ZeD's spawn window " .. tostring(mp.parent == sw) .. ", ZeD's map metatable " .. tostring(getmetatable(mp) == ZeD_MMSpawnMap)
                .. " (moved in on show: " .. tostring(keep.mapIn) .. "); safe mode's hand-back does not move it; safe mode itself not turned on here")
        else skip("NG23: the map panel after Spawn", "no map panel or no Spawn window") end
        local c = X.ccm()
        local fig = c and c.avatarPanel and c.avatarPanel.avatarPanel
        local lw = K.win("looks")
        if fig and lw then
            check(fig.parent ~= lw, "NG62: once Looks is left the game's 3D figure goes back to the game's looks screen (else safe mode shows the game's screen with no figure)",
                "a child of ZeD's looks window " .. tostring(fig.parent == lw) .. " (moved in on show: " .. tostring(keep.figIn) .. "); safe mode itself not turned on here")
        else skip("NG62: the figure after Looks", "no figure or no Looks window") end
        K.errCheck("NG0: the way back")
    end)
end

-- =========================================================================================================
-- 7: put back
function X.putBack()
    after(300, function()
        pcall(function()
            for _, view in ipairs({ "newgame", "spawn", "sandbox", "traits", "looks" }) do
                local w = K.win(view)
                if w and w.confirm and w.setConfirm then pcall(w.setConfirm, w, false) end
            end
        end)
        pcall(function() local w = K.win("looks"); if w and rawget(w, "play") then rawset(w, "play", nil) end end)
        pcall(function() local w = K.win("newgame"); if w then w._challengeItems = nil; w.challenges = false end end)
        pcall(function() if keep.pen0 then getSandboxOptions():getOptionByName("NegativeTraitsPenalty"):setValue(keep.pen0) end end)
        pcall(function() local p = X.prof(); if p and keep.bopts0 then p.savedBuilds.options = K.copy(keep.bopts0); p.savedBuilds.selected = keep.bsel0 end end)
        pcall(function() local v = X.ccm(); if v and keep.oopts0 then v.savedBuilds.options = K.copy(keep.oopts0); v.savedBuilds.selected = keep.osel0 end end)
        MM.forceGamepad = keep.pad0
        if MM.view ~= "main" then pcall(K.rescue) end
        MM.ctx.open = nil
        if keep.opt0 then pcall(K.setAll, keep.opt0) end
    end)
    after(800, function()
        local files = { { (BCRC and BCRC.savefile) or "saved_builds.txt", keep.builds0, "\n" }, { (CharacterCreationMain and CharacterCreationMain.savefile) or "saved_outfits.txt", keep.outfits0, "\n" },
                        { "pz_modlist_settings.cfg", keep.pzml0, "\n" }, { "ModOptions.ini", keep.ini0, "\r\n" } }
        for _, f in ipairs(files) do
            if f[2] and not K.same(K.readLines(f[1]), f[2]) then K.writeLines(f[1], f[2], f[3]) end
        end
    end)
    after(500, function()
        local d = K.diff(keep.opt0, K.snapAll())
        check(keep.opt0 ~= nil and #d == 0, "NG0: put back: every ZeD option as found (" .. K.count(keep.opt0) .. " options)", K.short(d))
        local files = { { (BCRC and BCRC.savefile) or "saved_builds.txt", keep.builds0 }, { (CharacterCreationMain and CharacterCreationMain.savefile) or "saved_outfits.txt", keep.outfits0 },
                        { "pz_modlist_settings.cfg", keep.pzml0 }, { "ModOptions.ini", keep.ini0 } }
        for _, f in ipairs(files) do
            local now = K.readLines(f[1])
            if f[2] then check(K.same(now, f[2]), "NG0: put back: Lua/" .. f[1] .. " line for line")
            elseif now == nil then check(true, "NG0: put back: Lua/" .. f[1] .. " was not there and is not there")
            else note("NG0: put back: Lua/" .. f[1] .. " was not there before and is now (" .. #now .. " lines; the same as none when empty): the runner's snapshot puts it back") end
        end
        local listed = true
        pcall(function() listed = K.has(K.jlist(getSandboxPresets()), QA_PRESET) end)
        check(not listed or K.has(keep.presetsFound or {}, QA_PRESET), "NG0: put back: no " .. QA_PRESET .. " sandbox preset left")
        check(K.wouldReset() == nil, "NG0: put back: no Lua reload waiting", K.wouldReset())
        check(MM.view == "main" and K.up("main") and MM.ctx.open == nil, "NG0: put back: the main window is up, no menu open", "view " .. tostring(MM.view))
        -- every check id of the map has a line
        for i = 1, 64 do
            if not keep.said["NG" .. i] then skip("NG" .. i .. ": not reached on this run", "the path stopped before it (see the lines above)") end
        end
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
    X.ngOpen()
    X.ngModes()
    X.ngClicks()
    X.ngChallenges()
    X.ngMods()
    X.ngSkips()
    X.ngToSpawn()
    X.spawnLook()
    X.spawnName()
    X.spawnSeed()
    X.spawnMap()
    X.spawnNext()
    X.sbLook()
    X.sbCells()
    X.sbLinks()
    X.sbGray()
    X.sbPresets()
    X.sbFind41()
    X.sbPad()
    X.sbTrip()
    X.sbNext()
    X.trLook()
    X.trRules()
    X.trTitle()
    X.trBuilds()
    X.trKeysPad()
    X.trNext()
    X.lkLook()
    X.lkOutfits()
    X.walkBack()
    mark()
    X.putBack()
end
after(300, function()
    say("end: " .. S.pass .. " pass, " .. S.fail .. " fail, " .. S.skips .. " skipped; " .. math.floor((getTimestampMs() - S.start) / 1000) .. " s; view=" .. tostring(MM and MM.view))
    say(S.fail > 0 and ("VERDICT FAIL " .. S.fail) or ("VERDICT PASS " .. S.pass))
end)
after(100, function() say("DONE") end)

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
