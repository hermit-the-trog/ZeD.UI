-- ZeDUI/tools/qa/bx_menu.lua  (Nov 21 2026, QA beast day; tag bx_menu): MAIN MENU ONLY, pushed through the QA bridge.
-- The desk, fringed: everything a player can open at the main menu, fast and in odd orders. No pictures.
--   lightning    a strike started (the painting's lightning, MM._life.zap), then held off for the whole run
--   menu bar     every menu opened (rows, hit boxes, on screen), all of them flicked through; rows pressed through
--                their pull-down hit: Credits, Terms, New game, Load game, Join, Host, Options, Mods, ZeD setup,
--                the wallpaper there and back; the power button and Exit ask and are answered No
--   desktop      the main window's close box, every icon clicked once (picks) and twice (opens), each window's
--                close box
--   windows      every desk window one after another (each on screen, one window up at a time), again with the
--                controller's D-pad walked in each, then a different window every frame, then all in one frame
--   Mods         every tab (the count on the tab against the rows), every mod picked with a detail tab each, every
--                live detail tab at top and bottom, Find with long garbage, Profiles opened (More, the save field
--                typed in and cancelled: nothing created), the Unfiled folder shut and opened, New folder asked
--                and cancelled, the load order page (rows picked, a move, Find, Escape twice: nothing saved), the
--                map order page, a mod that is off turned on (Back asks; Cancel; Undo changes), on and off at once,
--                then Back with nothing waiting
--   Options      every page at top and bottom, the bumpers all the way round, Find with garbage, the controller and
--                sounds pages, a key asked for and Escape, UI scale live (largest, smallest, Auto, back), Text size
--                live and back, a game tick box flipped then Back (asks) and Discard (the tick is back)
--   New game     every playstyle picked, Challenges and back, Sandbox > the spawn map (every town, no save name:
--                Next waits) > sandbox settings (every page, a tick twice, Presets, Find) > occupation and traits
--                (every occupation, many traits taken and all given back, points below zero: Next waits, Random) >
--                looks (Random, turn) and Back all the way to the main window, the way it came
--   Load game    every save picked, a group shut, Find with garbage (Delete asks nothing), Delete asked and
--                cancelled, Rename asked, typed in and cancelled, More; the list of saves is unchanged
--   Join         Public and Saved tabs, Find with garbage, the Add server form filled with rubbish and left
--   small ones   Credits (fast, pause, rewind), Terms, Trash (Empty asks; No)
--   ZeD setup    the welcome: the three ways, theme, text size, accent, input, tutorial and moodles picked, Skip
--                (every option back as the window found it)
--   keyboard map opened (ZeD.KeyboardMap.open), a key picked and unpicked, an action asked for and Escape, Reset
--                pressed once only, closed; keysB42.ini is unchanged
--   Lite         Style set to Lite: the desk's left column is empty, the windows cycled; Full again
-- After each act: the view and the window match, the window sits on screen, nothing threw (every call under test is
-- pcalled, and getLuaDebuggerErrorCount is compared after each part).
-- NEVER pressed: Continue, Tutorial, Play, Delete's Yes, Rename's Return, Upload, Accept terms, Report a bug,
-- Reset Lua, Quit's Yes, Save preset, Save setup, Done.
--
-- What it puts back itself: every ZeD option as found (and the look and scale on screen), ModOptions.ini line for
-- line, the first lines of ZeD_tutorial.txt / ZeD_setup_seen.txt when they were there, the wallpaper, the Mods
-- screen's tab and Hide incompatible, the mods in use (nothing accepted with a change), the lightning let go.
-- Lua cannot delete a file: a file that was not there before (ZeD_setup_seen.txt, ZeD_tutorial.txt, ZeD_wallpaper.txt,
-- ZeD_modsview.txt, ...) is the wrapper's to remove. Files it may write (all under Zomboid/): Lua/ModOptions.ini,
-- Lua/ZeD_setup_seen.txt, Lua/ZeD_tutorial.txt, Lua/ZeD_wallpaper.txt, Lua/ZeD_modsview.txt, Lua/ZeD_modfolders.txt,
-- Lua/pz_modlist_settings.cfg, mods/default.txt, Lua/ZeD_style_carry.txt, Lua/ZeD_custom_additions.txt; and by
-- accident only: Lua/keysB42.ini, Lua/ZeD_setup.txt, Lua/ModFolders.cfg, Lua/ZeD_modprofiles.txt; the Notepad clears
-- Lua/ZeD_desk_draft.txt when it closes with nothing unsaved; ZeD picks may write Lua/ZeD_picks.txt as Mods opens.
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/zed_only_mods.txt `
--        -Script ZeDUI/tools/qa/bx_menu.lua -Tag bx_menu -TimeoutSec 480
-- Lines: "ZEDQA bx_menu PASS ..." / "FAIL ..." / "SKIP ..." / "NOTE ..." / "ERR ...", then "VERDICT PASS n" or
-- "VERDICT FAIL n", then DONE (always from a later frame than the bridge's run line). grep "ZEDQA bx_menu".
local TAG = "bx_menu"
local MM = ZeD and ZeD.MainMenu
local St = ZeD and ZeD.Settings
local WL = ZeD and ZeD.Welcome
local S = { pass = 0, fail = 0, skips = 0, stages = {}, si = 1, maxMs = 400000, start = getTimestampMs() }
local keep = { path = {}, back = {} }
local K = {}
local X = {}
local GARBAGE = string.rep("%[(.-*+?^$)]%% <RGB:1,0,0> {}|\\/~`'\" zZ9_ ", 12) .. string.rep("W", 300)

local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local function check(ok, what, detail)
    if ok then S.pass = S.pass + 1 else S.fail = S.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. ((detail ~= nil and detail ~= "") and (" | " .. tostring(detail)) or ""))
    return ok and true or false
end
local function skip(what, why) S.skips = S.skips + 1; say("SKIP " .. what .. " | " .. tostring(why)) end
local function note(s) say("NOTE " .. tostring(s)) end

-- ---- the stages, on the clock (the menu's frame rate is anyone's guess; the UI's update runs every 100 ms):
-- after(ms, fn) runs fn ms after the stage before it (and three frames at least); waitFor(cond, maxMs, fn) runs
-- fn(true) as soon as cond is true, fn(false) after maxMs; mark() is where the put-back starts (out of time: the
-- queue jumps there)
local function after(ms, fn) S.stages[#S.stages + 1] = { ms = ms, fn = fn } end
local function waitFor(cond, maxMs, fn) S.stages[#S.stages + 1] = { ms = maxMs, cond = cond, fn = fn } end
local function mark() S.markAt = #S.stages + 1 end

function K.short(list)
    local out = {}
    for i, s in ipairs(list or {}) do if i <= 6 then out[#out + 1] = tostring(s) end end
    if #(list or {}) > 6 then out[#out + 1] = "(+" .. (#list - 6) .. " more)" end
    return table.concat(out, "; ")
end
-- a list walked a step every gapMs: stepFn(item, i, st) acts, verifyFn(item, i, st) looks at it one gap later
-- (a mismatch goes into st.bad); one PASS or FAIL for the whole walk
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
        if #st.list == 0 and #st.bad == 0 then skip(label, "nothing to walk here")
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
function K.near(a, b) return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 0.001 end

-- ---- options and files
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
-- a pick as ZeD setup makes it: the value, the live preview (onChange), the Apply (onChangeApply)
function K.setOpt(id, i)
    local o = K.opt(id)
    if not o then error("no ZeD option " .. tostring(id)) end
    o:setValue(i)
    if o.onChange then o.onChange(o, i) end
    if o.onChangeApply then o.onChangeApply(o, i) end
end
-- Style as ZeD setup's row sets it (Lite sets the additions)
function K.style(i)
    local o = St.lookStyleOption
    pcall(function() o:setValue(i) end)
    if o.onChange then pcall(o.onChange, o, i) end
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

-- ---- the lightning (hfr_disk.lua): held off; let go at the end
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
    if view == "desktop" then return r.icons end
    if view == "load" then return r.loadWin end
    if view == "newgame" then return r.newWin end
    if view == "mods" then return r.modsWin end
    if view == "options" then return r.optsWin end
    for _, rv in ipairs(MM.views or {}) do if rv.view == view then return r[rv.field] end end
    return nil
end
function K.up(view)
    local w = K.win(view)
    return MM.view == view and w ~= nil and w:isVisible() and true or false
end
-- nil when the element sits on screen, else what is wrong; second value: its place in words
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
function K.onScreen(label, w, noTube)
    local bad, g = nil, nil
    local ok, e = pcall(function() bad, g = K.sits(w) end)
    if not ok then bad = tostring(e) end
    check(bad == nil, label .. ": sits on screen", bad or g)
    if bad or noTube then return end
    -- (a note only: a desk window past the monitor's own screen)
    pcall(function()
        local L = MM.layout()
        local x, y = w:getAbsoluteX(), w:getAbsoluteY()
        if x < L.tx - 2 or y < L.ty - 2 or x + w:getWidth() > L.tx + L.tw + 2 or y + w:getHeight() > L.ty + L.th + 2 then
            note(label .. ": reaches past the monitor's screen (" .. g .. "; the screen is " .. math.floor(L.tx) .. "," .. math.floor(L.ty)
                .. " " .. math.floor(L.tw) .. "x" .. math.floor(L.th) .. ")")
        end
    end)
end
-- one window up at a time, and it is the view's
function K.oneWindow(label)
    local r = MM.root
    local fields = { "win", "loadWin", "newWin", "modsWin", "optsWin" }
    for _, rv in ipairs(MM.views or {}) do fields[#fields + 1] = rv.field end
    local up, wrong = {}, false
    local act = MM.activeWindow()
    for _, f in ipairs(fields) do
        local w = r[f]
        if w and w:isVisible() then
            up[#up + 1] = f
            if w ~= act then wrong = true end
        end
    end
    local want = (MM.view == "desktop") and 0 or 1
    check(#up == want and not wrong, label .. ": one window up, the view's (view " .. tostring(MM.view) .. ")", table.concat(up, " "))
end
function K.show(view)
    if view == "mods" then MM.openMods() elseif view == "options" then MM.openOptions() else MM.showView(view) end
end
-- back to the main window whatever is up (a vanilla screen left showing would hide the desk)
function K.rescue()
    local m = K.ms()
    for _, f in ipairs({ "charCreationMain", "charCreationProfession", "sandOptions", "mapSpawnSelect", "worldSelect", "onlineCoopScreen" }) do
        local sc = m and m[f]
        if sc then pcall(function() if sc:isVisible() then sc:setVisible(false) end end) end
    end
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

-- ---- the menu bar
function K.dropHit(key, i)
    local drop = MM.root and MM.root.drop
    local id = "drop:" .. key .. ":" .. i
    for _, h in ipairs((drop and drop._hits) or {}) do if h.id == id then return h end end
    return nil
end
-- a menu opened and one of its rows pressed through its pull-down hit (keep.skipNow when it could not be)
function K.menuPress(label, key, pred)
    after(150, function() keep.skipNow = nil; MM.ctx.open = key; MM.ctx.dropFocus = 1 end)
    after(250, function()
        local items = MM.menuItems(key) or {}
        local idx, item = nil, nil
        for i, it in ipairs(items) do
            if not idx and type(it) == "table" and it.text and pred(it) then idx = i; item = it end
        end
        local hit = idx and K.dropHit(key, idx)
        MM.ctx.open = nil
        if not idx then keep.skipNow = true; skip(label, "the " .. key .. " menu has no such row here"); return end
        if item.disabled then keep.skipNow = true; skip(label, "its row in the " .. key .. " menu is greyed"); return end
        if not check(hit ~= nil and hit.fn ~= nil, label .. ": the " .. key .. " menu shows its row", item.text) then keep.skipNow = true; return end
        if not K.try(label .. ": its menu row pressed", hit.fn) then keep.skipNow = true end
    end)
end
-- the rest of a visit: the view comes up on screen, body(w) runs, closer(w) leaves, the desk is back on backTo
function K.visitRest(label, view, body, closer, backTo)
    waitFor(function() return keep.skipNow or K.up(view) end, 4000, function(met)
        if keep.skipNow then return end
        if not check(K.up(view), label .. ": opens (view " .. view .. ")", "view " .. tostring(MM.view)) then keep.skipNow = true; K.rescue() end
    end)
    after(250, function()
        if keep.skipNow then return end
        K.onScreen(label, K.win(view))
        K.oneWindow(label)
        if body then K.try(label .. ": what was done in it", function() body(K.win(view)) end) end
    end)
    after(200, function()
        if keep.skipNow then return end
        K.errCheck(label)
        K.try(label .. ": leaving", function() closer(K.win(view)) end)
    end)
    waitFor(function() return keep.skipNow or MM.view == backTo end, 4000, function(met)
        if keep.skipNow then return end
        if not check(MM.view == backTo, label .. ": leaves to the " .. backTo .. " view", "view " .. tostring(MM.view)) then K.rescue() end
    end)
end
function K.visit(label, view, opener, body, closer, backTo)
    after(150, function()
        keep.skipNow = nil
        if not K.try(label .. ": opening", opener) then keep.skipNow = true end
    end)
    K.visitRest(label, view, body, closer, backTo)
end
-- a pop-up a button opened: open, on screen, then shut
function K.popup(label, key)
    after(250, function()
        if keep.skipNow then return end
        if MM.ctx.open ~= key then note(label .. ": no pop-up opened (its button is not in this window's band now)"); return end
        local drop = MM.root.drop
        check(drop:isVisible(), label .. ": the pop-up shows")
        K.onScreen(label, drop, true)
        MM.ctx.open = nil
    end)
end

-- ---- the Mods screen
function K.W() return MM.root and MM.root.modsWin end
function K.model() return ModSelector and ModSelector.instance and ModSelector.instance.model end
function K.rows() local w = K.W(); local r = {}; if w then pcall(function() r = w:rows() end) end; return r end
function K.activated() local t = {}; pcall(function() t = K.jlist(getActivatedMods()) end); return table.concat(t, ";") end
function K.activeIds()
    local t = {}
    pcall(function() t = K.jlist(K.model():getActiveMods():getMods()) end)
    return table.concat(t, ";")
end
-- why Back (Accept with nothing changed) would reload Lua and end the script, or nil
function K.backReloads(w)
    local m = K.model()
    if not (w and m) then return "no mod list" end
    if w:changed() then return "a change is waiting" end
    local need = false
    pcall(function() need = ActiveMods.requiresResetLua(m:getActiveMods()) end)
    if need then return "the load order differs from the one running" end
    if w._picksRefreshed then return "ZeD picks' copies were written again on this visit" end
    if w._resetPending then return "a mod's settings were reset on this visit" end
    local upd = 0
    pcall(function() upd = #ZeD.ModScan.updatedLoaded() end)
    if upd > 0 then return "Steam updated a loaded mod" end
    return nil
end
-- Back with nothing waiting (Accept); when that would reload Lua, the screen is left as the menu bar leaves it
function K.leaveMods(w)
    w = w or K.W()
    local why = K.backReloads(w)
    if why then
        note("Mods: left without Back (" .. why .. ": Back would reload Lua and end this script)")
        MM.showView("main")
        return
    end
    w:back()
    if w.confirm then
        check(false, "Mods: Back with nothing waiting asks nothing", tostring(w.confirm))
        w:setConfirm(false)
        MM.showView("main")
    end
end
-- the mod with the most to show on a detail tab, or nil
function K.modFor(tab)
    local w, best = K.W(), nil
    for _, d in ipairs(K.rows()) do
        local list = {}
        pcall(function() list = w:detailTabs(d) end)
        for _, t in ipairs(list) do
            if t.id == tab and not t.none and (not best or (t.count or 0) > best.n) then best = { d = d, n = t.count or 0 } end
        end
    end
    return best and best.d or nil
end
-- a mod that is off, can be turned on and brings nothing with it: a local one (no Workshop id) first
function K.devMod()
    local w, m = K.W(), K.model()
    if not (w and m) then return nil end
    local helper = ZeD.ModPicks and ZeD.ModPicks.HELPER
    local best, any = nil, nil
    for _, d in ipairs(m.sortedMods or {}) do
        local id = d.modId
        if not d.isActive and id ~= "ZeD_UI" and id ~= "ModTemplate" and id ~= helper and not w:problem(d) then
            local req, ws = 1, "x"
            pcall(function() local r = d.modInfo:getRequire(); req = r and r:size() or 0 end)
            pcall(function() ws = tostring(d.modInfo:getWorkshopID() or "") end)
            if req == 0 then
                if ws == "" and not best then best = d end
                if not any then any = d end
            end
        end
    end
    return best or any
end
-- a stage's function that runs only while the Mods screen is being walked: fn(w, met)
local function M(fn)
    return function(met)
        if keep.noMods then return end
        local w = K.W()
        if not (w and MM.view == "mods") then
            if not keep.modsLost then keep.modsLost = true; check(false, "Mods: the screen stays up while it is walked", "view " .. tostring(MM.view)) end
            return
        end
        return fn(w, met)
    end
end
-- the same for any other view's window: fn(w, met); flag is the keep field that says the walk was given up
local function V(view, flag, fn)
    return function(met)
        if keep[flag] then return end
        local w = K.win(view)
        if not (w and MM.view == view) then
            keep[flag] = true
            check(false, view .. ": the window stays up while it is walked", "view " .. tostring(MM.view))
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
        keep.opt0 = K.snapAll()
        keep.ini0 = K.readLines("ModOptions.ini")
        keep.setup0 = K.readLines(St.SETUP_FILE or "ZeD_setup.txt")
        keep.tut0 = K.readLines((WL and WL.TUTORIAL_FILE) or "ZeD_tutorial.txt")
        keep.seen0 = K.readLines((WL and WL.SEEN_FILE) or "ZeD_setup_seen.txt")
        keep.keys0 = K.readLines("keysB42.ini")
        keep.wall0 = MM.wallpaper()
        keep.look0 = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize }
        keep.mods0 = K.activated()
        keep.pad0 = MM.forceGamepad
        keep.lite0 = St.lite and St.lite() or false
        keep.scale0 = ZeD.Scale and ZeD.Scale.userScale
        say("as found: " .. K.count(keep.opt0) .. " options; look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize)
            .. ", Style " .. (keep.lite0 and "Lite" or "Full") .. ", UI scale step " .. tostring(keep.scale0) .. ", wallpaper " .. tostring(keep.wall0)
            .. ", view " .. tostring(MM.view) .. ", screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
            .. "; ZeD_tutorial.txt " .. (keep.tut0 and "there" or "absent") .. ", ZeD_setup_seen.txt " .. (keep.seen0 and "there" or "absent"))
        check(MM.openMods and MM.openOptions and MM.openWelcome and MM.menuItems and MM.menus and MM.showView and MM.act and St.lookStyleOption and true or false,
            "the main menu's parts are loaded")
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
            note("the desk had the " .. tostring(MM.view) .. " view up at the start (the first-launch setup): back to the main window, nothing answered")
            MM.showView("main")
        end
        if keep.lite0 then note("Style was Lite: set to Full for the walk, put back at the end"); K.style(1) end
    end)
    after(600, function()
        check(MM.view == "main" and K.up("main"), "the main window is up", "view " .. tostring(MM.view))
        K.onScreen("main window", K.win("main"))
        K.onScreen("menu bar", MM.root.bar, true)
        check(#(MM.root.win._specs or {}) > 0, "the main window has its buttons", #(MM.root.win._specs or {}))
        K.errCheck("the desk at rest")
    end)
end

-- 1: the lightning
function X.zap()
    after(200, function()
        local z = MM._life and MM._life.zap
        if not check(z ~= nil, "lightning: the painting's lightning is there (MM._life.zap)") then keep.noZap = true; return end
        keep.zapFree = true
        z.t0 = nil; z.nextAt = 0
    end)
    waitFor(function() local z = MM._life and MM._life.zap; return keep.noZap or (z ~= nil and z.t0 ~= nil) end, 3000, function(met)
        if keep.noZap then return end
        check(met, "lightning: a strike starts when one is due")
    end)
    after(400, function()
        if keep.noZap then return end
        keep.zapFree = false
        K.holdZap()
    end)
    after(1500, function()
        if keep.noZap then return end
        local z = MM._life.zap
        check(z.t0 == nil and z.nextAt >= 1e14, "lightning: held, no strike in a second and a half", "t0 " .. tostring(z.t0))
        K.errCheck("lightning")
    end)
end

-- 2: the menu bar
function X.menuOne(key)
    after(150, function() MM.ctx.open = key; MM.ctx.dropFocus = 1 end)
    after(300, function()
        local drop = MM.root.drop
        local items = {}
        K.try("menu " .. key .. ": its rows", function() items = MM.menuItems(key) or {} end)
        local rows, missing = 0, {}
        for i, it in ipairs(items) do
            if type(it) == "table" and it.text and not it.header then
                rows = rows + 1
                if not K.dropHit(key, i) then missing[#missing + 1] = tostring(it.text) end
            end
        end
        check(MM.ctx.open == key and drop:isVisible(), "menu " .. key .. ": the pull-down is open")
        check(rows > 0 and #missing == 0, "menu " .. key .. ": every row can be pressed (" .. rows .. " rows)", K.short(missing))
        K.onScreen("menu " .. key .. "'s pull-down", drop, true)
        K.errCheck("menu " .. key)
        MM.ctx.open = nil
    end)
    after(250, function() check(not MM.root.drop:isVisible(), "menu " .. key .. ": shuts") end)
end
function X.menus()
    local keys = {}
    for _, mn in ipairs(MM.menus()) do keys[#keys + 1] = mn.key; X.menuOne(mn.key) end
    each("menu bar: every menu flicked through, six times round", 30, 8000, function()
        local l = {}
        for _ = 1, 6 do for _, k in ipairs(keys) do l[#l + 1] = k end end
        return l
    end, function(k) MM.ctx.open = k; MM.ctx.dropFocus = 1 end, nil, function() MM.ctx.open = nil end)
    after(300, function()
        check(not MM.root.drop:isVisible() and MM.ctx.open == nil, "menu bar: nothing left open after the flicking")
        K.errCheck("menu bar")
    end)
end

-- 3: menu rows pressed, each window opened and left
function X.backOpts(w)
    w:back()
    if w.confirm then note("Options asked on Back (" .. tostring(w.confirm) .. "): Discard"); w:discard() end
end
function X.menuVisits()
    local A = MM.act
    local function back(w) w:back() end
    K.menuPress("Credits (ZeD menu)", "zed", function(it) return it.fn == A.credits end)
    K.visitRest("Credits (ZeD menu)", "credits", nil, back, "main")
    K.menuPress("Terms (ZeD menu)", "zed", function(it) return it.fn == A.tos and MM.hasView("terms") end)
    K.visitRest("Terms (ZeD menu)", "terms", nil, function(w) w:leave() end, "main")
    K.menuPress("New game (File menu)", "file", function(it) return it.fn == A.newGame end)
    K.visitRest("New game (File menu)", "newgame", nil, back, "main")
    K.menuPress("Load game (File menu)", "file", function(it) return it.fn == A.load end)
    K.visitRest("Load game (File menu)", "load", nil, back, "main")
    K.menuPress("Join (Multiplayer menu)", "mp", function(it) return it.fn == A.join end)
    K.visitRest("Join (Multiplayer menu)", "join", nil, back, "main")
    K.menuPress("Host (Multiplayer menu)", "mp", function(it) return it.fn == A.host end)
    K.visitRest("Host (Multiplayer menu)", "host", nil, back, "main")
    K.menuPress("Options (Settings menu)", "settings", function(it) return it.fn == A.options end)
    K.visitRest("Options (Settings menu)", "options", nil, X.backOpts, "main")
    K.menuPress("Mods (Settings menu)", "settings", function(it) return it.fn == A.mods end)
    K.visitRest("Mods (Settings menu)", "mods", nil, K.leaveMods, "main")
    K.menuPress("ZeD setup (Settings menu)", "settings", function(it) return it.text == ZeD.tr("UI_ZeD_Welcome_MenuItem") end)
    K.visitRest("ZeD setup (Settings menu)", "welcome", nil, function() MM.showView("main") end, "main")
    -- the wallpaper, there and back (the row that is not ticked, twice)
    K.menuPress("Wallpaper (Settings menu)", "settings", function(it) return it.check == false end)
    after(300, function()
        if keep.skipNow then return end
        check(MM.wallpaper() ~= keep.wall0, "Wallpaper: the other one is picked", tostring(MM.wallpaper()))
        K.errCheck("Wallpaper")
    end)
    K.menuPress("Wallpaper back (Settings menu)", "settings", function(it) return it.check == false end)
    after(300, function()
        if MM.wallpaper() ~= keep.wall0 then pcall(MM.setWallpaper, keep.wall0) end
        check(MM.wallpaper() == keep.wall0, "Wallpaper: back on the one found", tostring(MM.wallpaper()))
    end)
end

-- 4: the power button and Exit: asked, answered No
function X.power()
    after(200, function()
        local hit = MM.root._hits and MM.root._hits[1]
        if not check(hit ~= nil and hit.id == "power" and hit.fn ~= nil, "power button: its hit box is on the desk") then return end
        K.try("power button: pressed", hit.fn)
    end)
    after(300, function()
        local w = MM.root.win
        check(MM.view == "main" and w.confirm == true, "power button: the main window asks before quitting", tostring(w.confirm))
        K.try("the question: B", function() w:joyB() end)
    end)
    after(250, function()
        check(MM.root.win.confirm == false, "power button: B answers No")
        MM.showView("credits")
    end)
    after(300, function() K.try("Exit from another window", MM.act.askQuit) end)
    after(300, function()
        local w = MM.root.win
        check(MM.view == "main" and w.confirm == true, "Exit from the Credits window: the main window comes up to ask", "view " .. tostring(MM.view))
        K.try("the question: B", function() w:joyB() end)
    end)
    after(250, function()
        check(MM.root.win.confirm == false and MM.view == "main", "Exit: B answers No, the desk stays")
        K.errCheck("power and Exit")
    end)
end

-- 5: the desktop's icons
local ICON_VIEW = { pz = "main", newgame = "newgame", load = "load", join = "join", options = "options", mods = "mods", uploader = "workshop",
                    trash = "trash", cletusworks = "notepad", documents = "docs", mail = "mail" }
function X.iconOne(id)
    local view = ICON_VIEW[id]
    local label = "desktop icon " .. id
    after(200, function()
        keep.skipNow = nil
        if MM.view ~= "desktop" then MM.showView("desktop") end
        local ic = MM.root.icons
        local c = ic and ic:find(id)
        if not c then keep.skipNow = true; skip(label, "not on this desk"); return end
        if c.item.off and c.item.off() then keep.skipNow = true; skip(label, "greyed here"); return end
        ic._openedAt, ic._lastClick = nil, nil
        if not K.try(label .. ": a click", function() ic:click(id) end) then keep.skipNow = true; return end
        check(ic.focusId == id and MM.view == "desktop", label .. ": one click picks it and opens nothing", "view " .. tostring(MM.view))
        if not K.try(label .. ": the second click", function() ic:click(id) end) then keep.skipNow = true end
    end)
    K.visitRest(label, view, nil, function(w)
        if view == "mods" then K.leaveMods(w)
        elseif view == "workshop" then MM.showView("main")   -- (the uploader: looked at, nothing in it touched)
        elseif view == "options" then X.backOpts(w)
        else
            w:close()
            -- (a page with unsaved words asks before it closes, the Notepad's recovered draft: left as the menu bar
            -- leaves it, the words kept in the draft)
            if MM.view == view and w.confirm then
                note(label .. ": its close box asked first (" .. tostring(w.confirm) .. "): left without answering")
                pcall(function() w:setConfirm(false) end)
                MM.showView("desktop")
            end
        end
    end, (view == "main" or view == "trash" or view == "notepad" or view == "docs" or view == "mail") and "desktop" or "main")
end
function X.desktop()
    after(200, function() K.try("the main window's close box", function() MM.root.win:close() end) end)
    waitFor(function() return MM.view == "desktop" end, 3000, function(met)
        check(met, "the main window's close box leaves the desktop", "view " .. tostring(MM.view))
        local ic = MM.root.icons
        local ids = {}
        for _, c in ipairs((ic and ic._cells) or {}) do ids[#ids + 1] = tostring(c.item.id) end
        check(ic ~= nil and #ids > 0, "the desktop has its icons", table.concat(ids, " "))
    end)
    after(300, function() K.oneWindow("desktop") end)
    for _, id in ipairs({ "pz", "newgame", "load", "join", "options", "mods", "uploader", "trash", "cletusworks", "documents", "mail" }) do X.iconOne(id) end
    after(200, function() MM.showView("main") end)
end

-- 6: every window, one after another, then faster than anyone could
function X.cycleList(pad)
    local m = K.ms()
    local l = { "main", "newgame" }
    if MM.hasSaves() then l[#l + 1] = "load" end
    if not pad then l[#l + 1] = "options" end
    for _, v in ipairs({ "mods", "credits", "trash" }) do l[#l + 1] = v end
    if MM.hasView("terms") then l[#l + 1] = "terms" end
    if not St.lite() then for _, v in ipairs({ "docs", "mail", "notepad" }) do if MM.hasView(v) then l[#l + 1] = v end end end
    if not pad then
        l[#l + 1] = "welcome"
        if m and m.workshopSubmit and MM.hasView("workshop") then l[#l + 1] = "workshop" end
    end
    l[#l + 1] = "desktop"
    l[#l + 1] = "main"
    return l
end
function X.cycleVerify(view, i, st)
    if not K.up(view) then st.bad[#st.bad + 1] = view .. ": not up (view " .. tostring(MM.view) .. ")"; return end
    local bad = K.sits(K.win(view))
    if bad then st.bad[#st.bad + 1] = view .. ": " .. bad end
    local act = MM.activeWindow()
    if act ~= K.win(view) then st.bad[#st.bad + 1] = view .. ": the keys would go to another window" end
end
function X.cycle()
    each("windows: one after another, each up and on screen", 400, 40000, function() return X.cycleList(false) end,
        function(view) K.show(view) end, X.cycleVerify,
        function() K.errCheck("windows one after another") end)
    after(300, function() K.oneWindow("after the walk"); MM.forceGamepad = true end)
    each("windows: the D-pad walked in each (down, down, right, up, left, down)", 450, 40000, function() return X.cycleList(true) end,
        function(view) K.show(view) end,
        function(view, i, st)
            X.cycleVerify(view, i, st)
            local w = MM.activeWindow()
            if not (w and w.joyDir) then return end
            for _, d in ipairs({ "down", "down", "right", "up", "left", "down" }) do
                local ok, e = pcall(w.joyDir, w, d)
                if not ok then st.bad[#st.bad + 1] = view .. " " .. d .. ": " .. tostring(e) end
            end
        end,
        function()
            MM.forceGamepad = keep.pad0
            MM.deskAt, MM.deskBack = nil, nil
            K.errCheck("the D-pad in each window")
        end)
    each("windows: a different one every other frame", 25, 20000, function()
        local l = {}
        for _ = 1, 3 do
            for _, v in ipairs({ "main", "newgame", "options", "credits", "trash", "desktop", "welcome", "main", "mods", "credits" }) do l[#l + 1] = v end
        end
        l[#l + 1] = "main"
        return l
    end, function(view) K.show(view) end, nil, nil)
    after(500, function()
        check(K.up("main"), "after the flicking: the main window is up", "view " .. tostring(MM.view))
        K.oneWindow("after the flicking")
        K.errCheck("a window every other frame")
        -- every window five times over inside one frame, ending on Options
        K.try("every window opened in one frame", function()
            for _ = 1, 5 do
                for _, v in ipairs({ "newgame", "credits", "mods", "trash", "desktop", "welcome", "main", "options" }) do K.show(v) end
            end
        end)
    end)
    after(500, function()
        check(K.up("options"), "all in one frame: the last one opened is the one up (Options)", "view " .. tostring(MM.view))
        K.oneWindow("all in one frame")
        K.onScreen("Options after the pile-up", K.win("options"))
        K.errCheck("all in one frame")
        K.try("Options: Back", function() X.backOpts(K.win("options")) end)
    end)
    after(400, function() if MM.view ~= "main" then K.rescue() end end)
end

-- 7: the Mods screen
function X.modsOpen()
    after(200, function() K.try("Mods: opening", MM.openMods) end)
    waitFor(function() return K.up("mods") and #K.rows() > 0 end, 10000, function(met)
        if not check(met, "Mods: the screen opens with its list", "view " .. tostring(MM.view) .. ", rows " .. #K.rows()) then keep.noMods = true; K.rescue(); return end
        local w = K.W()
        keep.filter0, keep.hide0 = w.filter, w.hideInc
        w.hideInc = false
        w.filter = "all"
        w:dirty()
        keep.ids0 = K.activeIds()
    end)
    after(700, M(function(w)
        keep.nRows = #K.rows()
        say("Mods: " .. keep.nRows .. " mods listed, " .. #K.jlist(K.model():getActiveMods():getMods()) .. " on; folders " .. tostring(w.foldersOn and w:foldersOn() or false))
        K.onScreen("Mods", w)
        K.errCheck("Mods open")
    end))
end
function X.modsTabs()
    each("Mods: every tab lists what its count says", 300, 15000, function()
        local w, l = K.W(), {}
        if keep.noMods or not w then return l end
        for _, t in ipairs((w:tabList())) do l[#l + 1] = { id = t[1], n = t[3] } end
        return l
    end, function(t)
        local w = K.W()
        w.filter = t.id; w.scroll = 0
    end, function(t, i, st)
        local w = K.W()
        if w.filter ~= t.id then st.bad[#st.bad + 1] = t.id .. ": the tab did not stay (" .. tostring(w.filter) .. ")"; return end
        if t.id == "ws" then return end
        local n = #K.rows()
        if n ~= t.n then
            if t.id == "all" or t.id == "enabled" or t.id == "off" then st.bad[#st.bad + 1] = t.id .. ": " .. n .. " rows, the tab says " .. tostring(t.n)
            else note("Mods tab " .. t.id .. ": " .. n .. " rows, the tab says " .. tostring(t.n)) end
        end
    end, function()
        local w = K.W()
        if w then w.filter = "all"; w.scroll = 0 end
        K.errCheck("Mods tabs")
    end)
end
function X.modsSelect()
    each("Mods: every mod picked (a detail tab each), its details are that mod's", 50, 40000, function()
        local l = {}
        if keep.noMods then return l end
        local rows = K.rows()
        local stride = math.max(1, math.ceil(#rows / 160))
        for k = 1, #rows, stride do l[#l + 1] = { d = rows[k], k = k } end
        return l
    end, function(e, i)
        local w = K.W()
        w._lastClick = nil   -- (never a double-click: that turns the mod on or off)
        w:clickRow(e.d)
        local tabs = w:detailTabs(e.d)
        local live = {}
        for _, t in ipairs(tabs) do if not t.none then live[#live + 1] = t.id end end
        if #live > 0 then w.dtab = live[(i - 1) - math.floor((i - 1) / #live) * #live + 1] end
        w.scroll = math.max(0, (e.k - 3) * w:rowH())
    end, function(e, i, st)
        local w = K.W()
        if w.sel ~= e.d.modId or w:selected() ~= K.model().mods[e.d.modId] then
            st.bad[#st.bad + 1] = tostring(e.d.modId) .. ": picked, but the screen holds " .. tostring(w.sel)
        end
    end, function()
        local w = K.W()
        if w then w.dtab = "about"; w.scroll = 0; w.dscroll = 0 end
        K.errCheck("Mods: every mod picked")
        if w and MM.view == "mods" then K.onScreen("Mods after the picking", w) end
    end)
end
function X.modsDetail()
    each("Mods: every live detail tab, top and bottom", 180, 30000, function()
        local w, l, seen = K.W(), {}, {}
        if keep.noMods or not w then return l end
        local rows = K.rows()
        local mods = { K.model().mods["ZeD_UI"], K.modFor("options"), K.modFor("sandbox"), K.modFor("conflicts"), K.modFor("files"), rows[1], rows[#rows] }
        for k = 1, 7 do
            local d = mods[k]
            if d and not seen[d.modId] then
                seen[d.modId] = true
                for _, t in ipairs(w:detailTabs(d)) do
                    if not t.none then
                        l[#l + 1] = { d = d, tab = t.id, bottom = false }
                        l[#l + 1] = { d = d, tab = t.id, bottom = true }
                    end
                end
            end
        end
        return l
    end, function(e)
        local w = K.W()
        w.sel = e.d.modId; w.fsel = nil; w.dtab = e.tab
        w.dscroll = e.bottom and 1000000 or 0
    end, function(e, i, st)
        local w = K.W()
        if w.sel ~= e.d.modId or w.dtab ~= e.tab then st.bad[#st.bad + 1] = tostring(e.d.modId) .. " " .. e.tab .. ": the pane moved to " .. tostring(w.sel) .. " " .. tostring(w.dtab) end
        if e.bottom and (w.dscroll or 0) >= 1000000 then st.bad[#st.bad + 1] = tostring(e.d.modId) .. " " .. e.tab .. ": the pane's scroll is not held to its end" end
    end, function()
        local w = K.W()
        if w then w.dtab = "about"; w.dscroll = 0 end
        K.errCheck("Mods: detail tabs")
    end)
end
function X.modsFind()
    after(200, M(function(w) w.find:setText(GARBAGE); w.scroll = 0 end))
    after(800, M(function(w)
        check(#K.rows() == 0, "Mods: Find with long garbage lists nothing", #K.rows() .. " rows")
        K.onScreen("Mods with garbage in Find", w)
        K.errCheck("Mods: Find with garbage")
        w.find:setText("zed"); w.scroll = 0
    end))
    after(800, M(function(w)
        check(#K.rows() >= 1 and #K.rows() <= keep.nRows, "Mods: Find \"zed\" lists ZeD's mods", #K.rows() .. " rows")
        w.find:setText(""); w.scroll = 0
    end))
    after(800, M(function(w)
        check(#K.rows() == keep.nRows, "Mods: Find emptied, the whole list is back", #K.rows() .. " of " .. tostring(keep.nRows))
    end))
end
function X.modsProfiles()
    after(200, M(function(w)
        keep.presets0 = #w:presetNames()
        K.try("Mods: Profiles opened", function() w:enterProfiles() end)
    end))
    after(400, M(function(w)
        check(w.page == "profiles" and #w:profiles() == keep.presets0 + 1, "Mods: the Profiles page lists No mods and every profile", #w:profiles() .. " rows")
        K.onScreen("Mods, Profiles page", w)
    end))
    each("Mods: every profile picked (what loading it would change)", 150, 15000, function()
        local w, l = K.W(), {}
        if keep.noMods or not w or w.page ~= "profiles" then return l end
        for i, p in ipairs(w:profiles()) do if i <= 12 then l[#l + 1] = { p = p, i = i } end end
        return l
    end, function(e)
        local w = K.W()
        w._lastPClick = nil   -- (never a double-click: that loads the profile)
        w:clickProfile(e.p, e.i)
        w:profileDiff(e.p)
    end, function(e, i, st)
        local w = K.W()
        if w.psel ~= e.p.name then st.bad[#st.bad + 1] = tostring(e.p.name) .. ": not the one picked" end
    end, nil)
    after(200, M(function(w) keep.skipNow = nil; K.try("Mods: Profiles, More", function() w:openMore() end) end))
    K.popup("Mods: the profiles' More menu", "profilesMore")
    after(200, M(function(w) K.try("Mods: Profiles, Save as", function() w:setConfirm("save") end) end))
    after(300, M(function(w)
        check(w.confirm == "save" and w.field:isVisible(), "Mods: Save as shows its name field", tostring(w.confirm))
        w.field:setText(GARBAGE)
    end))
    after(300, M(function(w)
        K.errCheck("Mods: garbage in the profile name field")
        K.try("Mods: B on the name field", function() w:joyB() end)
    end))
    after(250, M(function(w)
        check(not w.confirm and not w.field:isVisible(), "Mods: B cancels the name field", tostring(w.confirm))
        K.try("Mods: Escape on the Profiles page", function() w:keyEscape() end)
    end))
    after(300, M(function(w)
        check(w.page == "list" and #w:presetNames() == keep.presets0, "Mods: Profiles left, no profile made or lost", #w:presetNames() .. " (was " .. tostring(keep.presets0) .. ")")
    end))
end
function X.unfiled(w)
    local v = w:folderView()
    for _, e in ipairs(v.ents or {}) do if e.k == "folder" and not e.f then return e end end
    return nil
end
function X.modsFolders()
    after(200, M(function(w)
        local F = ZeD.ModFolders
        keep.fN0 = F and #F.folders() or 0
        keep.fOn = (w.foldersOn and w:foldersOn()) and true or false
        if not keep.fOn then skip("Mods: the Unfiled folder shut and opened", "no folders here (none made, the Simple view or Lite)"); return end
        local e = X.unfiled(w)
        if not e then keep.fOn = false; skip("Mods: the Unfiled folder shut and opened", "no Unfiled row in this list"); return end
        keep.fOpen0 = e.open
        w._lastFClick = nil
        K.try("Mods: the Unfiled folder clicked and its triangle pressed", function() w:clickFolder(e); w:folderOpenClose(e) end)
    end))
    after(400, M(function(w)
        if not keep.fOn then return end
        local e = X.unfiled(w)
        check(e ~= nil and e.open == (not keep.fOpen0), "Mods: the Unfiled folder's triangle shuts or opens it", e and tostring(e.open))
        K.onScreen("Mods with a folder turned", w)
        if e then K.try("Mods: the triangle again", function() w:folderOpenClose(e) end) end
    end))
    after(400, M(function(w)
        if keep.fOn then
            local e = X.unfiled(w)
            check(e ~= nil and e.open == keep.fOpen0, "Mods: the Unfiled folder is as found again", e and tostring(e.open))
        end
        if not w.folderAskNew then keep.noAsk = true; return end
        K.try("Mods: New folder asked", function() w:folderAskNew(nil) end)
    end))
    after(300, M(function(w)
        if keep.noAsk then return end
        check(w.confirm == "fnew" and w.field:isVisible(), "Mods: New folder shows its name field", tostring(w.confirm))
        w.field:setText(GARBAGE)
    end))
    after(300, M(function(w)
        if keep.noAsk then return end
        K.try("Mods: B on the folder name field", function() w:joyB() end)
    end))
    after(250, M(function(w)
        local F = ZeD.ModFolders
        check(not w.confirm and (F and #F.folders() or 0) == keep.fN0, "Mods: New folder cancelled, no folder made", tostring(w.confirm))
        w.fsel = nil
        K.errCheck("Mods: folders")
    end))
end
function X.modsOrder()
    after(200, M(function(w)
        keep.ids1 = K.activeIds()
        K.try("Mods: the load order page opened", function() w:enterOrder("order") end)
    end))
    after(500, M(function(w)
        local n = #K.jlist(K.model():getActiveMods():getMods())
        check(w.page == "order" and #(w.order or {}) == n, "Mods: the load order page lists every mod that is on", #(w.order or {}) .. " of " .. n)
        K.onScreen("Mods, load order page", w)
    end))
    each("Mods: load order rows picked", 80, 10000, function()
        local w, l = K.W(), {}
        if keep.noMods or not w or w.page ~= "order" then return l end
        for i = 1, math.min(#w.order, 25) do l[#l + 1] = i end
        return l
    end, function(i) K.W():orderSelectAt(i, true) end,
    function(i, _, st) if K.W().oSel ~= i then st.bad[#st.bad + 1] = "row " .. i .. " not picked" end end, nil)
    after(200, M(function(w)
        if w.page ~= "order" then return end
        K.try("Mods: a row moved down and up, garbage in the order's Find", function()
            w:orderSelectAt(math.min(2, #w.order), true)
            w:move(1); w:move(-1)
            w.find:setText(GARBAGE)
        end)
    end))
    after(500, M(function(w)
        K.errCheck("Mods: the load order page")
        K.onScreen("Mods, load order with garbage in Find", w)
        K.try("Mods: Escape (clears Find)", function() w:keyEscape() end)
    end))
    after(300, M(function(w)
        check(w.page == "order" and (w.find:getInternalText() or "") == "", "Mods: the first Escape only clears Find", tostring(w.page))
        K.try("Mods: Escape again (leaves, nothing kept)", function() w:keyEscape() end)
    end))
    after(400, M(function(w)
        check(w.page == "list" and K.activeIds() == keep.ids1 and not w:changed(), "Mods: the load order page left without saving, order and mods as before",
            "page " .. tostring(w.page) .. ", changed " .. tostring(w:changed()))
        K.try("Mods: the map order page opened", function() w:enterOrder("maps") end)
    end))
    after(400, M(function(w)
        check(w.page == "maps", "Mods: the map order page opens", tostring(w.page))
        K.onScreen("Mods, map order page", w)
        K.errCheck("Mods: the map order page")
        K.try("Mods: the map order page left", function() if w.page ~= "list" then w:leaveOrder(false) end end)
    end))
    after(300, M(function(w) check(w.page == "list" and K.activeIds() == keep.ids1, "Mods: the map order page left, nothing changed", tostring(w.page)) end))
end
-- the list in the order it had when the screen opened (or the order running now: Undo changes sets that one)
function X.sameOrder() local a = K.activeIds(); return a == keep.ids0 or a == keep.mods0 end
function X.modsToggle()
    after(200, M(function(w)
        local d = K.devMod()
        if not d then keep.noDev = true; skip("Mods: a mod turned on, Back, Undo", "no mod here that is off, can run and needs nothing"); return end
        keep.devId = d.modId
        say("Mods: the mod to turn on and off: " .. tostring(d.name) .. " (" .. tostring(d.modId) .. ")")
        w.sel = d.modId
        K.try("Mods: the mod turned on", function() w:toggle(d) end)
    end))
    after(400, M(function(w)
        if keep.noDev then return end
        local d = K.model().mods[keep.devId]
        if not check(d ~= nil and d.isActive == true, "Mods: a mod that is off and can run turns on", keep.devId) then keep.noDev = true; return end
        check(w:changed() == true, "Mods: a change is waiting")
        local text = nil
        K.try("Mods: the band's waiting line", function() text = w:pendingNow() end)
        check(text ~= nil and text ~= "", "Mods: the band says a change is waiting", text)
        K.try("Mods: Back with a change waiting", function() w:back() end)
    end))
    after(300, M(function(w)
        if keep.noDev then return end
        check(w.confirm == "back", "Mods: Back with a change waiting asks first", tostring(w.confirm))
        K.try("Mods: B on the question", function() w:joyB() end)
    end))
    after(300, M(function(w)
        if keep.noDev then return end
        check(not w.confirm, "Mods: B cancels the question, the screen stays", tostring(w.confirm))
        K.try("Mods: Undo changes", function() w:revert() end)
    end))
    after(500, M(function(w)
        if keep.noDev then return end
        local d = K.model().mods[keep.devId]
        check(not w:changed() and X.sameOrder() and d ~= nil and not d.isActive, "Mods: Undo changes puts the mods and their order back",
            "changed " .. tostring(w:changed()) .. ", same order " .. tostring(X.sameOrder()))
        K.try("Mods: the mod on and off in one frame", function() w:toggle(d); w:toggle(K.model().mods[keep.devId], true) end)
    end))
    after(500, M(function(w)
        if keep.noDev then return end
        local d = K.model().mods[keep.devId]
        local same = X.sameOrder()
        check(d ~= nil and not d.isActive and not w:changed(), "Mods: on and off at once leaves nothing waiting", "changed " .. tostring(w:changed()))
        if not same then
            note("Mods: on and off left the load order different from the one found: Undo changes")
            K.try("Mods: Undo changes", function() w:revert() end)
        end
        K.errCheck("Mods: a mod on and off")
    end))
end
function X.modsLeave()
    after(300, M(function(w)
        w.find:setText("")
        w.filter, w.hideInc = keep.filter0, keep.hide0
        w.dtab = "about"
        w:dirty()
    end))
    after(500, function()
        if keep.noMods then return end
        if MM.view == "mods" then K.try("Mods: Back", function() K.leaveMods(K.W()) end) end
    end)
    waitFor(function() return keep.noMods or MM.view == "main" end, 4000, function(met)
        if keep.noMods then return end
        if not check(MM.view == "main", "Mods: Back with nothing waiting leaves to the main window", "view " .. tostring(MM.view)) then K.rescue() end
        check(K.activated() == keep.mods0, "Mods: the mods in use are the ones found")
        K.errCheck("Mods left")
    end)
end
function X.mods()
    X.modsOpen(); X.modsTabs(); X.modsSelect(); X.modsDetail(); X.modsFind(); X.modsProfiles(); X.modsFolders(); X.modsOrder(); X.modsToggle(); X.modsLeave()
end

-- 8: Options
local function O(fn) return V("options", "noOpts", fn) end
function X.optsPages()
    after(200, function() K.try("Options: opening", MM.openOptions) end)
    waitFor(function() return K.up("options") end, 4000, function(met)
        if not check(met, "Options: opens", "view " .. tostring(MM.view)) then keep.noOpts = true; K.rescue() end
    end)
    after(400, O(function(w) K.onScreen("Options", w); K.errCheck("Options open") end))
    each("Options: every page, top and bottom", 220, 20000, function()
        local w, l = K.win("options"), {}
        if keep.noOpts then return l end
        for i, p in ipairs(w:pages()) do l[#l + 1] = { i = i, p = p, bottom = false }; l[#l + 1] = { i = i, p = p, bottom = true } end
        return l
    end, function(e)
        local w = K.win("options")
        w.pageIdx = e.i; w.focusId = nil
        w.scroll = e.bottom and 10000000 or 0
    end, function(e, i, st)
        local w = K.win("options")
        local n = #w:rowsFor(e.p)
        if n == 0 and not e.bottom then note("Options page " .. tostring(e.p.raw) .. " has no rows here") end
        if w.pageIdx ~= e.i then st.bad[#st.bad + 1] = tostring(e.p.raw) .. ": the page did not stay" end
        if e.bottom and (w.scroll or 0) >= 10000000 then st.bad[#st.bad + 1] = tostring(e.p.raw) .. ": the scroll is not held to the page's end" end
    end, function() K.errCheck("Options: every page") end)
    after(200, O(function(w)
        w.pageIdx = 1; w.scroll = 0
        local n = #w:pages()
        K.try("Options: the bumpers all the way round, both ways", function()
            for _ = 1, n do w:joyBumper(1) end
            for _ = 1, n do w:joyBumper(-1) end
        end)
        check(w.pageIdx == 1, "Options: the bumpers go all the way round and back to the first page", w.pageIdx)
        w.find:setText(GARBAGE); w.scroll = 0
    end))
    after(700, O(function(w)
        K.errCheck("Options: Find with long garbage")
        K.onScreen("Options with garbage in Find", w)
        w.find:setText("scale")
    end))
    after(600, O(function(w) K.errCheck("Options: Find \"scale\""); w.find:setText("") end))
end
function X.optsSubs()
    after(300, O(function(w) K.try("Options: the controller page", function() w:openSub("pad") end) end))
    after(500, O(function(w)
        check(w.sub == "pad", "Options: the controller page opens", tostring(w.sub))
        K.onScreen("Options, controller page", w)
        K.errCheck("Options: the controller page")
        K.try("Options: the sounds page", function() w:openSub("sounds") end)
    end))
    after(500, O(function(w)
        check(w.sub == "sounds", "Options: the sounds page opens over the controller page", tostring(w.sub))
        if #(MM.soundCategories() or {}) >= 2 then K.try("Options: another sound group", function() w:setSoundCat(2) end) end
    end))
    after(400, O(function(w)
        K.errCheck("Options: the sounds page")
        K.try("Options: the page shut", function() w:closeSub() end)
        check(w.sub == nil, "Options: the sounds page shuts", tostring(w.sub))
    end))
    -- a key asked for, then Escape
    after(300, O(function(w)
        keep.keyRow = nil
        for i, p in ipairs(w:pages()) do
            if not p.setup and not keep.keyRow then
                for _, r in ipairs(w:rowsFor(p)) do
                    if not keep.keyRow and r.kind == "key" and r.entry then keep.keyRow = r; w.pageIdx = i; w.scroll = 0 end
                end
            end
        end
        if not keep.keyRow then skip("Options: a key asked for, then Escape", "no key row found"); return end
        K.try("Options: a key row pressed", function() w:activateRow(keep.keyRow) end)
    end))
    after(300, O(function(w)
        if not keep.keyRow then return end
        check(w.confirm == "key", "Options: a key row asks for its key", tostring(w.confirm))
        K.try("Options: Escape while a key is asked for", function() w:keyEscape() end)
    end))
    after(250, O(function(w)
        if not keep.keyRow then return end
        check(not w.confirm and MM.view == "options", "Options: Escape cancels the ask, the window stays", tostring(w.confirm))
        pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
        K.errCheck("Options: a key asked for")
    end))
end
function X.settled()
    local Sc = ZeD.Scale
    return K.near(Sc._appliedRoot, Sc.root()) and K.near(Sc.root(), Sc.compute())
end
function X.scaleOne(i, word)
    after(300, O(function(w)
        K.try("UI scale " .. word .. ": picked", function() K.setOpt("uiScale", i or keep.opt0.uiScale) end)
    end))
    waitFor(function() return keep.noOpts or X.settled() end, 4000, O(function(w, met)
        local Sc = ZeD.Scale
        local idx = i or keep.opt0.uiScale
        local want = St.scaleKeys and St.scaleKeys[idx]
        check(X.settled(), "UI scale " .. word .. ": the desk is drawn at the scale worked out", "applied " .. tostring(Sc._appliedRoot) .. ", root " .. tostring(Sc.root()))
        check(Sc.userScale == ((type(want) == "number") and want or nil), "UI scale " .. word .. ": the step in use is the one picked", tostring(Sc.userScale) .. " / " .. tostring(want))
        check(Sc.root() >= 0.999, "UI scale " .. word .. ": never under 1.0 while the desk is up", tostring(Sc.root()))
    end))
    after(500, O(function(w)
        check(K.up("options"), "UI scale " .. word .. ": Options is still the window up", "view " .. tostring(MM.view))
        K.onScreen("Options at UI scale " .. word, w)
        K.onScreen("menu bar at UI scale " .. word, MM.root.bar, true)
        K.errCheck("UI scale " .. word)
    end))
end
function X.optsLive()
    after(200, O(function(w)
        for i, p in ipairs(w:pages()) do if p.setup then w.pageIdx = i end end
        w.scroll = 0
    end))
    local n = #((St and St.scaleKeys) or {})
    if n >= 2 then
        X.scaleOne(n, "largest")
        X.scaleOne(2, "smallest")
        X.scaleOne(1, "Auto")
        X.scaleOne(nil, "as found")
    else
        after(100, function() skip("Options: UI scale live", "ZeD.Settings.scaleKeys is not there") end)
    end
    after(300, O(function(w)
        keep.size0 = K.val("textSize") or 1
        keep.sizeOther = (keep.size0 == 1) and 2 or 1
        K.try("Text size: the other one picked", function() K.setOpt("textSize", keep.sizeOther) end)
    end))
    after(900, O(function(w)
        check(ZeD.currentSize == (St.sizeKeys and St.sizeKeys[keep.sizeOther]), "Text size: the other size is on screen at once", tostring(ZeD.currentSize))
        K.onScreen("Options at the other text size", w)
        K.errCheck("Text size live")
        K.try("Text size: back", function() K.setOpt("textSize", keep.size0) end)
    end))
    after(900, O(function(w)
        check(ZeD.currentSize == keep.look0[3], "Text size: back on the size found", tostring(ZeD.currentSize))
        K.onScreen("Options at the text size found", w)
    end))
end
-- a game tick box that flips when pressed (not ZeD's page, not the mods' page), or nil
function X.findTick(w)
    local pages = w:pages()
    local tries = 0
    for i = #pages, 1, -1 do
        local p = pages[i]
        if not p.setup and p.raw ~= "mods" and p.raw ~= "zed" then
            for _, r in ipairs(w:rowsFor(p)) do
                local c = r.control
                if r.kind == "tick" and r.opt and not r.moot and c and c.enable ~= false and c.selected and #(c.options or {}) == 1 and tries < 6 then
                    tries = tries + 1
                    local v0 = c.selected[1] == true
                    w.pageIdx = i; w.scroll = 0; w._tickCol = 1
                    w:activateRow(r)
                    if (c.selected[1] == true) ~= v0 then return { c = c, v0 = v0, label = tostring(r.label), page = tostring(p.raw) } end
                end
            end
        end
    end
    return nil
end
function X.optsBack()
    after(300, O(function(w)
        local ok, t = K.try("Options: a game tick box pressed", function() return X.findTick(w) end)
        keep.tick = ok and t or nil
        if not keep.tick then skip("Options: a tick flipped, Back, Discard", "no game tick box here that flips"); return end
        say("Options: the tick flipped: " .. keep.tick.label .. " (page " .. keep.tick.page .. ")")
    end))
    after(400, O(function(w)
        if keep.tick then check(w:anyChanged() == true, "Options: a flipped tick counts as a change") end
        K.try("Options: Back", function() w:back() end)
    end))
    after(300, function()
        if keep.noOpts then return end
        local w = K.win("options")
        if not keep.tick then
            if w.confirm then note("Options asked on Back with nothing flipped (" .. tostring(w.confirm) .. "): Discard"); pcall(function() w:discard() end) end
            return
        end
        check(w.confirm == "back" and MM.view == "options", "Options: Back with a change waiting asks first", tostring(w.confirm))
        K.try("Options: Discard", function() w:discard() end)
    end)
    waitFor(function() return keep.noOpts or MM.view == "main" end, 4000, function(met)
        if keep.noOpts then return end
        if not check(MM.view == "main", "Options: leaves to the main window", "view " .. tostring(MM.view)) then K.rescue() end
        if keep.tick then
            local mo = K.ms() and K.ms().mainOptions
            check((keep.tick.c.selected[1] == true) == keep.tick.v0, "Options: Discard puts the tick back")
            check(not (mo and mo.gameOptions and mo.gameOptions.changed), "Options: nothing is left waiting after Discard")
        end
        K.errCheck("Options left")
    end)
end
function X.options() X.optsPages(); X.optsSubs(); X.optsLive(); X.optsBack() end

-- 9: New game, all the way in and all the way out
local function NG(view, fn)
    return function(met)
        if keep.noPath then return end
        local w = K.win(view)
        if not (w and MM.view == view) then return end   -- (this run's path does not pass here, or it stopped earlier: said where it happened)
        return fn(w, met)
    end
end
function X.ngStart()
    after(200, function() K.try("New game: opening", MM.act.newGame) end)
    waitFor(function() return K.up("newgame") end, 4000, function(met)
        if not check(met, "New game: opens", "view " .. tostring(MM.view)) then keep.noPath = true; K.rescue(); return end
        keep.path[#keep.path + 1] = "newgame"
    end)
    after(300, NG("newgame", function(w) K.onScreen("New game", w); check(#w:items() > 0, "New game: the playstyles are listed", #w:items()) end))
    each("New game: every playstyle picked", 130, 10000, function()
        local l = {}
        if keep.noPath or MM.view ~= "newgame" then return l end
        for i = 1, #K.win("newgame"):items() do l[#l + 1] = i end
        return l
    end, function(i)
        local w = K.win("newgame")
        w._lastClick = nil   -- (never a double-click: that goes on)
        w:clickIcon(i)
    end, function(i, _, st) if K.win("newgame").sel ~= i then st.bad[#st.bad + 1] = "playstyle " .. i .. " not picked" end end, nil)
    after(200, NG("newgame", function(w)
        keep.chal = nil
        for i, d in ipairs(w:items()) do if w:isChallengesItem(d) then keep.chal = i end end
        if not keep.chal then skip("New game: Challenges and back", "no Challenges playstyle here"); return end
        w.sel = keep.chal
        K.try("New game: Challenges, Next", function() w:next() end)
    end))
    after(400, NG("newgame", function(w)
        if not keep.chal then return end
        check(w.challenges == true, "New game: Challenges opens its list (" .. #w:items() .. " challenges)")
        K.onScreen("New game, the challenges", w)
        K.errCheck("New game: challenges")
        K.try("New game: Back from the challenges", function() w:back() end)
    end))
    after(300, NG("newgame", function(w)
        if keep.chal then check(w.challenges == false and MM.view == "newgame", "New game: Back from the challenges lands on the playstyles") end
        local sb = nil
        for i, d in ipairs(w:items()) do if d.mode == "Sandbox" then sb = i end end
        if not sb then keep.noPath = true; skip("New game: the Sandbox path", "no Sandbox playstyle here"); return end
        w.sel = sb; w.focusId = "icon:" .. sb
        K.try("New game: Sandbox, Next", function() w:next() end)
    end))
    waitFor(function() return keep.noPath or K.up("spawn") or K.up("world") end, 6000, function(met)
        if keep.noPath then return end
        if MM.view == "world" then
            keep.path[#keep.path + 1] = "world"
            K.onScreen("New game, the worlds", K.win("world"))
            note("New game: more than one world here: the first is taken")
            K.try("New game: the world, Next", function() K.win("world"):next() end)
        elseif not check(K.up("spawn"), "New game: Sandbox goes on to the spawn map", "view " .. tostring(MM.view)) then keep.noPath = true end
    end)
    waitFor(function() return keep.noPath or K.up("spawn") end, 6000, function(met)
        if keep.noPath then return end
        if not K.up("spawn") then check(false, "New game: the spawn map comes up", "view " .. tostring(MM.view)); keep.noPath = true; return end
        keep.path[#keep.path + 1] = "spawn"
    end)
end
function X.ngSpawn()
    after(500, NG("spawn", function(w)
        K.onScreen("Spawn map", w)
        check(#w:items() > 0, "Spawn: the towns are listed", #w:items())
        keep.name0 = w.nameEntry:getText() or ""
        keep.details = w:hasDetails() and true or false
        K.errCheck("Spawn open")
    end))
    each("Spawn: every town picked", 220, 10000, function()
        local l = {}
        if keep.noPath or MM.view ~= "spawn" then return l end
        for i = 1, math.min(10, #K.win("spawn"):items()) do l[#l + 1] = i end
        return l
    end, function(i) K.win("spawn"):pick(i) end,
    function(i, _, st) if K.win("spawn").sel ~= i then st.bad[#st.bad + 1] = "town " .. i .. " not picked" end end,
    function() K.errCheck("Spawn: every town") end)
    after(250, NG("spawn", function(w)
        if not keep.details then skip("Spawn: no save name, Next waits", "no save name here (a challenge, or no world being made)"); return end
        K.try("Spawn: a new seed", function() w:newSeed() end)
        check((w.seedEntry:getText() or "") ~= "", "Spawn: New seed fills the seed")
        w.nameEntry:setText("")
    end))
    after(300, NG("spawn", function(w)
        if not keep.details then return end
        check(w:nameProblem() ~= nil, "Spawn: an empty save name is a problem, in words", tostring(w:nameProblem()))
        K.try("Spawn: Next with no save name", function() w:next() end)
    end))
    after(400, NG("spawn", function(w)
        if not keep.details then return end
        check(MM.view == "spawn", "Spawn: Next waits while the save name is empty")
        w.nameEntry:setText(".bad/name?.")
    end))
    after(300, NG("spawn", function(w)
        if not keep.details then return end
        check(w:nameProblem() ~= nil, "Spawn: a save name with characters a folder cannot have is a problem", tostring(w:nameProblem()))
        w.nameEntry:setText(GARBAGE)
    end))
    after(300, NG("spawn", function(w)
        if keep.details then
            K.errCheck("Spawn: garbage as the save name")
            w.nameEntry:setText(keep.name0)
        end
    end))
    after(300, NG("spawn", function(w)
        if keep.details and w:nameProblem() then note("Spawn: the save name the game offered is refused (" .. tostring(w:nameProblem()) .. "): the path stops here"); keep.noNext = true; return end
        w:pick(math.min(2, #w:items()))
        K.try("Spawn: Next", function() w:next() end)
    end))
    waitFor(function() return keep.noPath or keep.noNext or K.up("sandbox") or K.up("traits") end, 6000, function(met)
        if keep.noPath or keep.noNext then return end
        if not check(K.up("sandbox") or K.up("traits"), "Spawn: Next goes on (sandbox settings, or occupation)", "view " .. tostring(MM.view)) then keep.noNext = true; return end
        keep.path[#keep.path + 1] = MM.view
    end)
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
function X.ngSandbox()
    after(500, NG("sandbox", function(w)
        K.onScreen("Sandbox settings", w)
        check(#w:pages() > 0, "Sandbox: the pages are listed", #w:pages())
        K.errCheck("Sandbox open")
    end))
    each("Sandbox: every page, top and bottom", 200, 30000, function()
        local l = {}
        if keep.noPath or MM.view ~= "sandbox" then return l end
        for i, p in ipairs(K.win("sandbox"):pages()) do l[#l + 1] = { i = i, p = p, bottom = false }; l[#l + 1] = { i = i, p = p, bottom = true } end
        return l
    end, function(e)
        local w = K.win("sandbox")
        w.pageIdx = e.i; w.focusId = nil
        w.scroll = e.bottom and 10000000 or 0
    end, function(e, i, st)
        local w = K.win("sandbox")
        if #w:rowsFor(e.p) == 0 and not e.bottom then note("Sandbox page " .. tostring(e.p.raw) .. " has no rows here") end
        if e.bottom and (w.scroll or 0) >= 10000000 then st.bad[#st.bad + 1] = tostring(e.p.raw) .. ": the scroll is not held to the page's end" end
    end, function() K.errCheck("Sandbox: every page") end)
    after(250, NG("sandbox", function(w)
        local ok, t = K.try("Sandbox: looking for a tick box", function() return X.sbTick(w) end)
        keep.sbT = ok and t or nil
        if not keep.sbT then skip("Sandbox: a tick flipped twice", "no tick box that can be pressed"); return end
        w.pageIdx = keep.sbT.i; w.scroll = 0; w._tickCol = 1
        keep.sbV0 = keep.sbT.c.selected[1] == true
        w:refreshDiff(true)
        keep.sbN0 = w.nDiff
        K.try("Sandbox: the tick pressed", function() w:activateRow(keep.sbT.r) end)
    end))
    after(300, NG("sandbox", function(w)
        if not keep.sbT then return end
        check((keep.sbT.c.selected[1] == true) ~= keep.sbV0 and w.nDiff ~= keep.sbN0, "Sandbox: a tick flips and the count of changes from the preset moves",
            tostring(keep.sbT.r.label) .. ": changes " .. tostring(w.nDiff) .. " (was " .. tostring(keep.sbN0) .. ")")
        K.try("Sandbox: the tick pressed again", function() w:activateRow(keep.sbT.r) end)
    end))
    after(300, NG("sandbox", function(w)
        if keep.sbT then
            check((keep.sbT.c.selected[1] == true) == keep.sbV0 and w.nDiff == keep.sbN0, "Sandbox: pressed again, the tick and the count are as before", "changes " .. tostring(w.nDiff))
        end
        keep.skipNow = nil
        K.try("Sandbox: Presets", function() w:openPresets() end)
    end))
    K.popup("Sandbox: the Presets menu", "presets")
    after(200, NG("sandbox", function(w) MM.ctx.open = nil; w.find:setText(GARBAGE); w.scroll = 0 end))
    after(600, NG("sandbox", function(w)
        K.errCheck("Sandbox: Find with garbage")
        K.onScreen("Sandbox with garbage in Find", w)
        w.find:setText("")
    end))
    after(300, NG("sandbox", function(w) K.try("Sandbox: Next", function() w:next() end) end))
    waitFor(function() return keep.noPath or keep.noNext or K.up("traits") end, 6000, function(met)
        if keep.noPath or keep.noNext then return end
        if not check(K.up("traits"), "Sandbox: Next goes on to occupation and traits", "view " .. tostring(MM.view)) then keep.noNext = true; return end
        if keep.path[#keep.path] ~= "traits" then keep.path[#keep.path + 1] = "traits" end
    end)
end
function X.prof() local m = K.ms(); return m and m.charCreationProfession end
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
function X.ngTraits()
    after(500, NG("traits", function(w)
        K.onScreen("Occupation and traits", w)
        keep.prof0 = X.prof().listboxProf.selected or 1
        K.errCheck("Traits open")
    end))
    each("Traits: every occupation picked", 70, 10000, function()
        local l = {}
        if keep.noPath or MM.view ~= "traits" then return l end
        for i = 1, math.min(30, #X.prof().listboxProf.items) do l[#l + 1] = i end
        return l
    end, function(i) K.win("traits"):pickProf(i) end,
    function(i, _, st) if X.prof().listboxProf.selected ~= i then st.bad[#st.bad + 1] = "occupation " .. i .. " not picked" end end, nil)
    after(200, NG("traits", function(w)
        K.try("Traits: the occupation found again, the traits cleared", function() w:pickProf(keep.prof0); w:clearTraits() end)
    end))
    after(200, NG("traits", function(w)
        keep.pts0 = X.prof():PointToSpend()
        check(X.chosenLeft() == 0, "Traits: Clear leaves only the occupation's own traits", X.chosenLeft())
    end))
    each("Traits: many traits taken, each lands under Chosen", 70, 10000, function()
        local l = {}
        if keep.noPath or MM.view ~= "traits" then return l end
        for i = 1, 14 do l[#l + 1] = i end
        return l
    end, function(i, _, st)
        local w = K.win("traits")
        local rows = X.traitRows(w)
        st.before, st.took = #X.prof().listboxTraitSelected.items, nil
        if #rows == 0 then return end
        local k = i * 5
        local r = rows[k - math.floor(k / #rows) * #rows + 1]
        st.took = tostring(r.trait)
        w:takeTrait(r.trait)
    end, function(i, _, st)
        if st.took and #X.prof().listboxTraitSelected.items ~= st.before + 1 then
            st.bad[#st.bad + 1] = st.took .. ": taken, but Chosen went from " .. st.before .. " to " .. #X.prof().listboxTraitSelected.items
        end
    end, function() K.errCheck("Traits: many taken") end)
    after(200, NG("traits", function(w)
        K.try("Traits: every chosen trait given back", function()
            for _ = 1, 60 do
                local at = nil
                for i, it in ipairs(X.prof().listboxTraitSelected.items) do if not at and not it.item:isFree() then at = i end end
                if not at then break end
                w:giveBack(at)
            end
        end)
        check(X.chosenLeft() == 0 and X.prof():PointToSpend() == keep.pts0, "Traits: all given back, the points are as before",
            "left " .. X.chosenLeft() .. ", points " .. tostring(X.prof():PointToSpend()) .. " (was " .. tostring(keep.pts0) .. ")")
        -- into the red: traits that cost points until the points are under zero
        K.try("Traits: traits taken until the points run out", function()
            for _ = 1, 25 do
                if X.prof():PointToSpend() < 0 then break end
                local pick = nil
                for _, r in ipairs(X.traitRows(w)) do
                    local cost = 0
                    pcall(function() cost = r.trait:getCost() end)
                    if not pick and cost > 0 then pick = r end
                end
                if not pick then break end
                w:takeTrait(pick.trait)
            end
        end)
        keep.neg = X.prof():PointToSpend() < 0
        if keep.neg then K.try("Traits: Next with the points under zero", function() w:next() end)
        else skip("Traits: Next waits while the points are under zero", "the points never went under zero here") end
    end))
    after(400, function()
        if keep.noPath or keep.noNext then return end
        if keep.neg then check(MM.view == "traits", "Traits: Next waits while the points are under zero", "view " .. tostring(MM.view)) end
        if MM.view == "traits" then K.try("Traits: Clear", function() K.win("traits"):clearTraits() end) end
    end)
    each("Traits: Random five times", 130, 5000, function()
        if keep.noPath or MM.view ~= "traits" then return {} end
        return { 1, 2, 3, 4, 5 }
    end, function() K.win("traits"):random() end,
    function(i, _, st) if type(X.prof():PointToSpend()) ~= "number" then st.bad[#st.bad + 1] = "the points are not a number after Random" end end,
    function() K.errCheck("Traits: Random") end)
    after(200, NG("traits", function(w)
        if X.prof():PointToSpend() < 0 then w:clearTraits() end
        keep.skipNow = nil
        K.try("Traits: Builds", function() w:openBuilds() end)
    end))
    K.popup("Traits: the Builds menu", "builds")
    after(200, NG("traits", function(w) MM.ctx.open = nil; K.onScreen("Occupation and traits, after the picking", w); K.try("Traits: Next", function() w:next() end) end))
    waitFor(function() return keep.noPath or keep.noNext or K.up("looks") end, 6000, function(met)
        if keep.noPath or keep.noNext then return end
        if not check(K.up("looks"), "Traits: Next goes on to the looks", "view " .. tostring(MM.view)) then keep.noNext = true; return end
        keep.path[#keep.path + 1] = "looks"
    end)
end
function X.ngLooks()
    after(600, NG("looks", function(w) K.onScreen("Looks", w); K.errCheck("Looks open") end))
    each("Looks: Random and the figure turned", 220, 6000, function()
        if keep.noPath or MM.view ~= "looks" then return {} end
        return { "random", "left", "random", "right", "right", "random" }
    end, function(a)
        local w = K.win("looks")
        if a == "random" then w:random() elseif a == "left" then w:turn(-1) else w:turn(1) end
    end, nil, function() K.errCheck("Looks: Random and turns") end)
end
-- Back, Back, Back: whatever view is up, its own Back, until the main window
function X.ngBack()
    waitFor(function()
        local now = getTimestampMs()
        if keep.bwAt and now - keep.bwAt < 500 then return false end
        keep.bwAt = now
        local v = MM.view
        if v == "main" then return true end
        keep.back[#keep.back + 1] = tostring(v)
        if #keep.back > 12 then return true end
        local w = K.win(v)
        MM.ctx.open = nil
        if w and w.back then
            local ok, e = pcall(w.back, w)
            if not ok then keep.backErr = tostring(v) .. ": " .. tostring(e) end
        else
            pcall(MM.showView, "main")
        end
        return false
    end, 15000, function(met)
        local want = {}
        for i = #keep.path, 1, -1 do want[#want + 1] = keep.path[i] end
        check(MM.view == "main" and keep.backErr == nil, "New game: Back from each window reaches the main window", table.concat(keep.back, " > ") .. (keep.backErr and (" | " .. keep.backErr) or ""))
        check(table.concat(keep.back, " > ") == table.concat(want, " > "), "New game: Back goes out the way it came in",
            "out " .. table.concat(keep.back, " > ") .. " / in " .. table.concat(keep.path, " > "))
        if MM.view ~= "main" then K.rescue() end
        K.errCheck("New game: the way back")
    end)
    after(400, function()
        K.oneWindow("after New game")
        local m = K.ms()
        check(m ~= nil and m.bottomPanel:isVisible(), "after New game: the desk is the screen up (no game screen left showing)")
    end)
end
function X.newGame() X.ngStart(); X.ngSpawn(); X.ngSandbox(); X.ngTraits(); X.ngLooks(); X.ngBack() end

-- 10: Load game
local function LD(fn) return V("load", "noLoad", fn) end
function X.saveKeys(w)
    local t = {}
    for _, s in ipairs(w.saves or {}) do t[#t + 1] = tostring(s.key) end
    table.sort(t)
    return table.concat(t, ";")
end
function X.saveRows(w)
    local n = 0
    for _, r in ipairs(w.view or {}) do if r.save then n = n + 1 end end
    return n
end
function X.load()
    after(200, function()
        if not MM.hasSaves() then keep.noLoad = true; skip("Load game", "no saves here"); return end
        K.try("Load game: opening", MM.act.load)
    end)
    waitFor(function() return keep.noLoad or K.up("load") end, 5000, function(met)
        if keep.noLoad then return end
        if not check(K.up("load"), "Load game: opens", "view " .. tostring(MM.view)) then keep.noLoad = true; K.rescue() end
    end)
    after(400, LD(function(w)
        keep.saves0 = X.saveKeys(w)
        K.onScreen("Load game", w)
        check(#w.saves > 0 and w:selected() ~= nil, "Load game: the saves are listed, one is picked", #w.saves .. " saves")
        K.errCheck("Load game open")
    end))
    each("Load game: every save picked, its preview is that save's", 130, 15000, function()
        local l = {}
        if keep.noLoad or MM.view ~= "load" then return l end
        for i, s in ipairs(K.win("load").saves) do if i <= 20 then l[#l + 1] = s end end
        return l
    end, function(s)
        local w = K.win("load")
        w._lastClick = nil   -- (never a double-click: that plays the save)
        w:clickSave(s)
        w:whyNot(s)
    end, function(s, _, st)
        local w = K.win("load")
        if w.sel ~= s.key or w:selected() ~= s then st.bad[#st.bad + 1] = tostring(s.key) .. ": not the one picked" end
    end, function() K.errCheck("Load game: every save") end)
    after(200, LD(function(w)
        local s = w:selected()
        keep.rows0 = X.saveRows(w)
        if s then w.collapsed[s.mode] = true; w:filter(); keep.shut = s.mode end
    end))
    after(300, LD(function(w)
        if keep.shut then
            check(X.saveRows(w) < keep.rows0, "Load game: a group shut hides its saves", X.saveRows(w) .. " of " .. keep.rows0)
            w.collapsed[keep.shut] = nil; w:filter()
        end
        w.find:setText(GARBAGE); w:filter()
    end))
    after(400, LD(function(w)
        check(X.saveRows(w) == 0 and w:selected() == nil, "Load game: Find with long garbage lists no save and picks none", X.saveRows(w) .. " rows")
        K.try("Load game: Delete with no save picked", function() w:askDelete() end)
        check(not w.confirm, "Load game: Delete with no save picked asks nothing", tostring(w.confirm))
        K.onScreen("Load game with garbage in Find", w)
        K.errCheck("Load game: Find with garbage")
        w.find:setText(""); w:filter()
    end))
    after(300, LD(function(w)
        check(w:selected() ~= nil and X.saveRows(w) == keep.rows0, "Load game: Find emptied, the saves are back and one is picked", X.saveRows(w) .. " rows")
        K.try("Load game: Delete asked", function() w:askDelete() end)
    end))
    after(300, LD(function(w)
        check(w.confirm == "delete" and w.focusId == "confirm:no", "Load game: Delete asks first, the controller lands on Cancel", tostring(w.confirm) .. ", " .. tostring(w.focusId))
        K.try("Load game: B on the question", function() w:joyB() end)
    end))
    after(250, LD(function(w)
        check(not w.confirm and MM.view == "load", "Load game: B cancels Delete, the window stays", tostring(w.confirm))
        K.try("Load game: Rename asked", function() w:startRename() end)
    end))
    after(300, LD(function(w)
        check(w.confirm == "rename" and w.renameEntry:isVisible(), "Load game: Rename shows its name field", tostring(w.confirm))
        w.renameEntry:setText(GARBAGE)
    end))
    after(300, LD(function(w)
        K.errCheck("Load game: garbage in the rename field")
        K.try("Load game: B on the rename field", function() w:joyB() end)
    end))
    after(250, LD(function(w)
        check(not w.confirm and not w.renameEntry:isVisible(), "Load game: B cancels Rename", tostring(w.confirm))
        keep.skipNow = nil
        K.try("Load game: More", function() w:openMore() end)
    end))
    K.popup("Load game: the More menu", "more")
    after(250, LD(function(w)
        MM.ctx.open = nil
        K.try("Load game: the saves read again", function() w:readSaves(); w:filter() end)
        check(X.saveKeys(w) == keep.saves0, "Load game: the saves are the ones found (none deleted, none renamed)", #w.saves .. " saves")
        K.try("Load game: Back", function() w:back() end)
    end))
    waitFor(function() return keep.noLoad or MM.view == "main" end, 4000, function(met)
        if keep.noLoad then return end
        if not check(MM.view == "main", "Load game: Back leaves to the main window", "view " .. tostring(MM.view)) then K.rescue() end
        K.errCheck("Load game left")
    end)
end

-- 11: Join a server
local function JN(fn) return V("join", "noJoin", fn) end
function X.join()
    after(200, function() K.try("Join: opening", MM.act.join) end)
    waitFor(function() return K.up("join") end, 5000, function(met)
        if not check(met, "Join: opens", "view " .. tostring(MM.view)) then keep.noJoin = true; K.rescue() end
    end)
    after(500, JN(function(w)
        K.onScreen("Join", w)
        keep.jSaved0 = #w:savedRows()
        K.errCheck("Join open")
        K.try("Join: the Public tab", function() w:setTab("public") end)
    end))
    after(500, JN(function(w)
        check(w.tab == "public", "Join: the Public tab opens", tostring(w.tab))
        K.errCheck("Join: Public tab")
        K.try("Join: the Saved tab", function() w:setTab("saved") end)
    end))
    after(300, JN(function(w) K.try("Join: garbage in Find", function() w.find:setText(GARBAGE); w:findChanged() end) end))
    after(500, JN(function(w)
        K.errCheck("Join: Find with garbage")
        K.onScreen("Join with garbage in Find", w)
        K.try("Join: Find emptied, the Add server form opened", function() w.find:setText(""); w:findChanged(); w:openServerForm(nil) end)
    end))
    after(400, JN(function(w)
        check(w.page == "server", "Join: the Add server form opens", tostring(w.page))
        K.try("Join: rubbish in the form", function() w.fName:setText(GARBAGE); w.fAddr:setText("not an address"); w.fPort:setText("ninety") end)
    end))
    after(400, JN(function(w)
        local p = {}
        K.try("Join: the form's problems", function() p = w:serverProblems() end)
        check(p.port ~= nil, "Join: a port that is not a number is a problem, in words", tostring(p.port))
        K.onScreen("Join, the Add server form", w)
        K.errCheck("Join: the form with rubbish")
        K.try("Join: Back from the form", function() w:back() end)
    end))
    after(300, JN(function(w)
        check(w.page == "list" and MM.view == "join" and #w:savedRows() == keep.jSaved0, "Join: Back from the form lands on the list, no server added",
            tostring(w.page) .. ", " .. #w:savedRows() .. " rows (was " .. tostring(keep.jSaved0) .. ")")
        K.try("Join: Back", function() w:back() end)
    end))
    waitFor(function() return keep.noJoin or MM.view == "main" end, 4000, function(met)
        if keep.noJoin then return end
        if not check(MM.view == "main", "Join: Back leaves to the main window", "view " .. tostring(MM.view)) then K.rescue() end
        K.errCheck("Join left")
    end)
end

-- 12: Credits, Terms, the Trash
function X.small()
    K.visit("Credits", "credits", MM.act.credits, function(w)
        w:setMode("fast"); w:togglePause(); w:togglePause(); w:setMode("rewind"); w:setMode("rewind")
        w:wheel(4); w:wheel(-400)
        check(w.mode == "play" and (w.roll or 0) >= 0, "Credits: fast, pause, rewind and the wheel leave it playing, never above its top", tostring(w.mode) .. ", roll " .. tostring(w.roll))
    end, function(w) w:back() end, "main")
    K.visit("Terms", "terms", function() if not MM.hasView("terms") then keep.skipNow = true; skip("Terms", "no terms view here") else MM.showView("terms") end end, function(w)
        w:wheel(-50); w:wheel(500)
    end, function(w) w:leave() end, "main")
    K.visit("Trash", "trash", function() MM.showView("trash") end, function(w)
        w:empty()
        check(w.confirm == true, "Trash: Empty trash asks first", tostring(w.confirm))
        w:joyB()
        check(w.confirm == false and MM.view == "trash", "Trash: B answers No, the window stays", tostring(w.confirm))
    end, function(w) w:close() end, "desktop")
    after(200, function() MM.showView("main") end)
end

-- 13: the welcome (ZeD setup: pick, save or load)
local function WE(fn) return V("welcome", "noWel", fn) end
function X.welcome()
    after(300, function() K.try("Welcome: opening", MM.openWelcome) end)
    waitFor(function() return K.up("welcome") end, 4000, function(met)
        if not check(met, "Welcome: opens", "view " .. tostring(MM.view)) then keep.noWel = true; K.rescue() end
    end)
    after(400, WE(function(w)
        K.onScreen("Welcome", w)
        keep.wSnap = K.snapAll()
        keep.wBase, keep.wSize, keep.wAccent = ZeD.currentBase, ZeD.currentSize, ZeD.currentAccent
        check(K.spec(w, "way:1") ~= nil and K.spec(w, "way:2") ~= nil and K.spec(w, "way:3") ~= nil, "Welcome: the three ways are there")
    end))
    each("Welcome: the ways and the choices pressed", 300, 15000, function()
        if keep.noWel or MM.view ~= "welcome" then return {} end
        local acc = (K.val("accentColor") == 3) and 4 or 3
        return { "way:2", "way:3", "way:1", "opt:theme:" .. ((ZeD.currentBase ~= "light") and 2 or 1), "opt:text:" .. ((ZeD.currentSize ~= "large") and 2 or 1),
                 "opt:accent:" .. acc, "opt:input:2", "opt:tutorial:2", "opt:moodles:" .. ((K.val("moodlePlace") == 1) and 2 or 1), "way:3", "way:1" }
    end, function(id, _, st)
        local why = K.press(K.win("welcome"), id)
        if why then st.bad[#st.bad + 1] = why end
    end, nil, nil)
    after(500, WE(function(w)
        check(ZeD.currentBase ~= keep.wBase and ZeD.currentSize ~= keep.wSize, "Welcome: a theme and a text size picked are on screen at once",
            tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentSize))
        check(w.input == 2 and w.tutorial == 2 and w.way == 1, "Welcome: Controller, No thanks and Pick your own are the ones picked",
            tostring(w.input) .. " " .. tostring(w.tutorial) .. " " .. tostring(w.way))
        K.onScreen("Welcome after the picking", w)
        K.errCheck("Welcome: the picking")
        K.try("Welcome: Skip (the close box)", function() w:close() end)
    end))
    waitFor(function() return keep.noWel or MM.view == "main" end, 4000, function(met)
        if keep.noWel then return end
        if not check(MM.view == "main", "Welcome: Skip leaves to the main window", "view " .. tostring(MM.view)) then K.rescue() end
        local d = K.diff(keep.wSnap, K.snapAll())
        check(#d == 0, "Welcome: Skip puts every option back as the window found it", K.short(d))
        check(ZeD.currentBase == keep.wBase and ZeD.currentSize == keep.wSize and ZeD.currentAccent == keep.wAccent, "Welcome: Skip puts the look on screen back",
            tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize))
        check(WL ~= nil and WL.seen() == true and not WL.tutorialWanted(), "Welcome: answered: the setup is marked seen, no tour asked for")
        K.errCheck("Welcome left")
    end)
end

-- 14: the keyboard map (the window menu opens it in game; here by ZeD.KeyboardMap.open)
function X.kmHit(km, id)
    local tb = km:titleBarHeight()
    for _, h in ipairs(km._hits or {}) do
        if h.id == id and h.y >= tb and h.y + h.h <= tb + (km._bodyH or 0) then return h end
    end
    return nil
end
function X.kmClick(km, h)
    local x, y = h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)
    km:onMouseDown(x, y)
    km:onMouseUp(x, y)
end
local function KMs(fn)
    return function()
        local km = keep.km
        if not km then return end
        return fn(km)
    end
end
function X.kmap()
    after(300, function()
        local KM = ZeD.KeyboardMap
        if not (KM and KM.open) then skip("Keyboard map", "ZeD.KeyboardMap.open is not there"); return end
        keep.keysA = K.readLines("keysB42.ini")
        local ok, win = K.try("Keyboard map: opened at the main menu", function() return KM.open(0) end)
        keep.km = ok and win or nil
    end)
    after(600, KMs(function(km)
        check(km:isReallyVisible(), "Keyboard map: is up")
        K.onScreen("Keyboard map", km, true)
        K.errCheck("Keyboard map open")
        local cap = X.kmHit(km, "cap")
        if not cap then skip("Keyboard map: a key picked and unpicked", "no key drawn in sight"); return end
        K.try("Keyboard map: a key clicked", function() X.kmClick(km, cap) end)
        check(km.picked == cap.code, "Keyboard map: a click picks the key", tostring(km.picked))
        K.try("Keyboard map: the key clicked again", function() X.kmClick(km, cap) end)
        check(km.picked == nil, "Keyboard map: a second click lets it go", tostring(km.picked))
    end))
    after(300, KMs(function(km)
        local b = X.kmHit(km, "bind")
        keep.kmBind = b and b.name or nil
        if not b then skip("Keyboard map: an action asked for, then Escape", "no action's key box in sight"); return end
        K.try("Keyboard map: an action's key box clicked", function() X.kmClick(km, b) end)
        check(km.listening == b.name, "Keyboard map: the action waits for its key", tostring(km.listening))
    end))
    after(400, KMs(function(km)
        if not keep.kmBind then return end
        K.try("Keyboard map: Escape while it waits", function() km:onKeyPress(Keyboard.KEY_ESCAPE) end)
        check(km.listening == nil and km:isReallyVisible(), "Keyboard map: Escape cancels the wait, the map stays up", tostring(km.listening))
    end))
    after(500, KMs(function(km)
        check(not km._keysOff, "Keyboard map: the game's keys are back on after the wait")
        local r = X.kmHit(km, "reset")
        if r then
            -- (once only: a second press inside four seconds would reset every key)
            K.try("Keyboard map: Reset pressed once", function() X.kmClick(km, r) end)
            check(km._resetAt ~= nil, "Keyboard map: Reset pressed once only asks")
            km._resetAt = nil
        end
        K.try("Keyboard map: scrolled to its end and back", function() km:scrollBy(1000000); km:scrollBy(-1000000) end)
        check(km.scroll == 0, "Keyboard map: the scroll is held to its ends", tostring(km.scroll))
    end))
    after(400, KMs(function(km)
        K.errCheck("Keyboard map")
        K.try("Keyboard map: closed", function() km:close() end)
    end))
    after(400, KMs(function(km)
        check(not km:isReallyVisible(), "Keyboard map: shuts")
        check(K.same(K.readLines("keysB42.ini"), keep.keysA), "Keyboard map: no key changed (keysB42.ini line for line)")
        pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
    end))
end

-- 15: Lite
function X.lite()
    after(300, function() K.style(2) end)
    after(900, function()
        keep.liteOn = St.lite() == true
        check(keep.liteOn, "Lite: Style set to Lite is read at once")
        local n = -1
        pcall(function() n = #MM.leftItems() end)
        check(n == 0, "Lite: the desk's left column is empty", n)
        K.errCheck("Lite on")
    end)
    each("Lite: the windows one after another, each up and on screen", 400, 30000, function() return X.cycleList(false) end,
        function(view) K.show(view) end, X.cycleVerify, function() K.errCheck("Lite: the windows") end)
    after(300, function() K.oneWindow("Lite, after the walk"); K.style(1) end)
    after(900, function()
        check(St.lite() == false, "Full again: Style set to Full is read at once")
        local n = -1
        pcall(function() n = #MM.leftItems() end)
        check(n > 0, "Full again: the desk's left column has its apps", n)
        K.onScreen("main window, Full again", K.win("main"))
        K.errCheck("Full again")
    end)
end

-- =========================================================================================================
-- put back
function X.putBack()
    after(300, function()
        K.rescue()
        pcall(function() local KM = ZeD.KeyboardMap; if KM and KM.close then KM.close(0) end end)
        pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
        MM.forceGamepad = keep.pad0
        pcall(function() JoypadState.controllerTest = nil end)
        if keep.wall0 and MM.wallpaper() ~= keep.wall0 then pcall(MM.setWallpaper, keep.wall0) end
        -- (the Mods screen's tab and box, should a part have stopped half way: the values only)
        local w = K.W()
        if w and keep.filter0 ~= nil then w.filter, w.hideInc = keep.filter0, keep.hide0; pcall(function() w.find:setText("") end) end
        if keep.opt0 then
            K.setAll(keep.opt0)
            pcall(function() St.applyScale() end)
            pcall(function() St.applyThemeNow() end)
        end
    end)
    after(1200, function()
        -- (ZeD's own saves are done: the files as found. The seen and tutorial files are one word, no line end.)
        if keep.ini0 then K.writeLines("ModOptions.ini", keep.ini0, "\r\n") end
        if keep.tut0 then K.writeLines((WL and WL.TUTORIAL_FILE) or "ZeD_tutorial.txt", keep.tut0) end
        if keep.seen0 then K.writeLines((WL and WL.SEEN_FILE) or "ZeD_setup_seen.txt", keep.seen0) end
    end)
    after(500, function()
        local d = K.diff(keep.opt0, K.snapAll())
        check(keep.opt0 ~= nil and #d == 0, "put back: every ZeD option as found (" .. K.count(keep.opt0) .. " options)", K.short(d))
        local L = keep.look0 or {}
        check(ZeD.currentBase == L[1] and ZeD.currentAccent == L[2] and ZeD.currentSize == L[3], "put back: the theme, accent and text size on screen as found",
            tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize))
        check(ZeD.Scale.userScale == keep.scale0 and St.lite() == keep.lite0, "put back: the UI scale step and Style as found",
            tostring(ZeD.Scale.userScale) .. ", Lite " .. tostring(St.lite()))
        check(keep.ini0 ~= nil and K.same(K.readLines("ModOptions.ini"), keep.ini0), "put back: ModOptions.ini line for line")
        local files = { { (WL and WL.TUTORIAL_FILE) or "ZeD_tutorial.txt", keep.tut0 }, { (WL and WL.SEEN_FILE) or "ZeD_setup_seen.txt", keep.seen0 } }
        for _, f in ipairs(files) do
            if f[2] then check(K.same(K.readLines(f[1]), f[2]), "put back: " .. f[1] .. " line for line")
            else say("SKIP put back: " .. f[1] .. " was not there before; the wrapper removes it") end
        end
        check(K.same(K.readLines(St.SETUP_FILE or "ZeD_setup.txt"), keep.setup0), "put back: ZeD_setup.txt was never written")
        check(K.same(K.readLines("keysB42.ini"), keep.keys0), "put back: keysB42.ini line for line")
        check(MM.wallpaper() == keep.wall0, "put back: the wallpaper as found", tostring(MM.wallpaper()))
        check(K.activated() == keep.mods0, "put back: the mods in use are the ones found")
        check(MM.view == "main" and K.up("main") and MM.ctx.open == nil, "put back: the main window is up, no menu open", "view " .. tostring(MM.view))
    end)
    after(300, function()
        keep.zapFree = true
        K.freeZap()
        local z = MM._life and MM._life.zap
        if z then check(z.nextAt < 1e14, "put back: the lightning is let go") end
        local n = K.errs()
        if n ~= nil and keep.errs0 ~= nil then say("Lua errors counted during the run: " .. (n - keep.errs0)) end
    end)
end

-- =========================================================================================================
if not (MM and MM.root and St and MM.showView) then
    after(100, function() S.fail = S.fail + 1; say("ERR ZeD's main menu is not up (no desk): nothing was done") end)
else
    X.start()
    X.zap()
    X.menus()
    X.menuVisits()
    X.power()
    X.desktop()
    X.cycle()
    X.mods()
    X.options()
    X.newGame()
    X.load()
    X.join()
    X.small()
    X.welcome()
    X.kmap()
    X.lite()
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
