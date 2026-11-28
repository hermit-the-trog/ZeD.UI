-- ZeDUI/tools/qa/mu_opt.lua  (Nov 27 2026, QA menus sweep; tag mu_opt): MAIN MENU ONLY, pushed through the QA bridge.
-- The gamut sweep of ZeD's Options window and the first-launch welcome, check by check against the map
-- ZeDUI/qa/audits/2026-11-27_map_menu_options.md (OP1 to OP80). No pictures. Every check line starts with the map's id.
--   ways in      the desk's Options, the game's OPTIONS item, the game's screen asked to show; the page kept (OP1)
--   the pages    nine groups in order, titles, every game option filed, nothing under Other, the Advanced sound
--                button's name, the moot and ONLY rows, ZeD-GUI's drop-downs on the Mods page, ZeD setup's rows
--                against the map's table, the debug rows, the tips, the language marks, the colors (OP3 to OP11,
--                OP23, OP24, OP30, OP33, OP37)
--   drawing      ZeD setup walked top to bottom at the text size found and at the other one: each ZeD control
--                drawn as itself or as the drop-down, the wells, two-line names, the help band's three lines, the
--                window and the button map's labels on screen (OP12, OP16, OP31, OP68, OP80)
--   ZeD setup    UI scale (the off steps, the pad's walk), See-through, Controller highlight, the preset, the
--                merged rows, Button pictures, the give-backs, Lite and Full, Reset to defaults, Discard and the
--                live previews; every pick on the controls only, then the window's own Discard (OP13 to OP29, OP48)
--   game rows    a drop-down, a tick box, a volume, a slider and a mega volume changed and put back; the changed
--                flag and the dots; Back's ask, the footer's Discard, X, Return and Y (OP32, OP43, OP45 to OP47, OP51)
--   keys         a key asked for and bound (Shift, a modifier alone, Escape and Enter), a duplicate asked and
--                cancelled, Default; Discard puts every key back; keysB42.ini unchanged (OP56, OP57, OP59 to OP61)
--   Find         help words, one row for a ZeD option, capitals, no match, a page or a bumper clears it, the frame
--                cost of one letter (OP8, OP52 to OP55)
--   bands        the restart band raised as Apply raises it (OP38), and on the button map page (OP44)
--   sub-pages    the button map (Back, B, Escape, the labels' pull-down) and the sounds page (categories, volumes,
--                no Reload) (OP65, OP68 to OP70)
--   welcome      opened by MM.openWelcome: layout, Save setup greyed, a pick live, Playing with, Lite then Full,
--                the Tutorial it starts on, B (Skip) only when ZeD_setup_seen.txt was there before (OP71 to OP79)
--   setup file   Save setup, Load a setup with three staged lines, a file with no valid line (OP75 to OP77)
-- Not stageable here, one SKIP each with the reason: OP2, OP22, OP34, OP35, OP39, OP41, OP42, OP50, OP58, OP66, OP67
-- (by hand), OP40, OP62, OP64 (in game), the in-game parts of OP1 and OP21, Apply itself (OP38, OP51).
-- NEVER pressed or called: Apply (the window's or the game's MainOptions:apply: it re-sets the screen mode and sets
-- the frame rate from its list, display settings this script must never touch), Accept or Done on the
-- welcome, Load (the welcome's), a chord's pick or X, Play or Stop on the sounds page, any sound volume, the
-- Advanced sound button itself, Take it, the screen-settings question's answers, Safe mode, display mode,
-- fullscreen, borderless, resolution, VSync, Pause on focus loss, the language, Quit, Reset Lua.
-- What it puts back itself: every ZeD option as found (K.snapAll, compared at the end), the look, the UI scale and
-- Style as found, every control on the window back from the stored values (the window's Discard, never Apply),
-- ModOptions.ini line for line, keysB42.ini (only should a key have been written: the game's keys read again),
-- ZeD_tutorial.txt and ZeD_setup_seen.txt when they were there, ZeD_custom_additions.txt when it was there,
-- the setup file used for OP75 to OP77 (ZeD_setup.txt line for line when it was there; else the test file
-- Lua/ZeD_qa_mu_opt_setup.txt, left empty: Lua cannot delete a file), ZeD_chords.txt untouched (Reset to defaults
-- is pressed with ZeD.QuickChords.reset counted, not run), a mod's key bind (OP49) set back by hand.
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/zed_only_mods.txt `
--        -Script ZeDUI/tools/qa/mu_opt.lua -Tag mu_opt -TimeoutSec 540
--   with $env:ZEDQA_NOSTEAM = "1" set first: a Steam launch loads the Workshop copy of ZeD, which has no QA bridge.
-- Lines: "ZEDQA mu_opt PASS ..." / "FAIL ..." / "SKIP ..." / "NOTE ..." / "ERR ...", then "VERDICT PASS n" or
-- "VERDICT FAIL n", then DONE (always from a later frame than the bridge's run line). grep "ZEDQA mu_opt".
local TAG = "mu_opt"
local MM = ZeD and ZeD.MainMenu
local St = ZeD and ZeD.Settings
local WL = ZeD and ZeD.Welcome
local G = MM and MM.optionGroups
local S = { pass = 0, fail = 0, skips = 0, stages = {}, si = 1, maxMs = 400000, start = getTimestampMs() }
local keep = {}
local K = {}
local X = {}

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
-- (a mismatch goes into st.bad); one PASS or FAIL for the whole walk (label nil: no line, doneFn judges)
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
        st.met = met
        if label then
            if #st.list == 0 and #st.bad == 0 then skip(label, "nothing to walk here")
            else
                check(#st.bad == 0 and met, label .. " (" .. math.min(st.i, #st.list) .. " of " .. #st.list .. ")",
                    K.short(st.bad) .. ((not met) and " (ran out of time)" or ""))
            end
        end
        if doneFn then
            local ok, e = pcall(doneFn, st)
            if not ok then check(false, tostring(label or "a walk") .. ": its last look ran without an error", e) end
        end
    end)
end

-- =========================================================================================================
-- small things
function K.ms() return MainScreen and MainScreen.instance end
function K.mo() local m = K.ms(); return m and m.mainOptions end
function K.W() return MM.root and MM.root.optsWin end
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
function K.count(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
function K.idx(list, v) for i, x in ipairs(list or {}) do if x == v then return i end end; return nil end
function K.same01(a, b) return (a and true or false) == (b and true or false) end
function K.mode()
    local m = nil
    pcall(function() m = ZeD.Input.Detector.getMode() end)
    return m
end
function K.lang()
    local l = "?"
    pcall(function() l = tostring(Translator.getLanguage()) end)
    return l
end
function K.changed()
    local mo = K.mo()
    return mo and mo.gameOptions and mo.gameOptions.changed and true or false
end

-- ---- options and files (as bx_menu.lua)
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
function K.live(id) local v = nil; pcall(function() v = G.liveOf(K.opts(), id) end); return v end
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
-- Style as ZeD setup's row sets it, stored (Lite sets the additions' controls): bx_menu's K.style
function K.style(i)
    local o = St.lookStyleOption
    pcall(function() o:setValue(i) end)
    if o.onChange then pcall(o.onChange, o, i) end
end
-- every ZeD option whose control (the Mods page's combo) shows another pick than its stored value
function K.controlsOff()
    local bad = {}
    for _, o in ipairs((K.opts() and K.opts().data) or {}) do
        local el = o.element
        if o.type == "combobox" and el and el.selected ~= nil then
            local v = K.val(o.id)
            if v ~= nil and el.selected ~= v then bad[#bad + 1] = tostring(o.id) .. " " .. tostring(el.selected) .. "/" .. tostring(v) end
        end
    end
    return bad
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

-- ---- windows
function K.win(view)
    local r = MM.root
    if not r then return nil end
    if view == "main" then return r.win end
    if view == "options" then return r.optsWin end
    for _, rv in ipairs(MM.views or {}) do if rv.view == view then return r[rv.field] end end
    return nil
end
function K.up(view)
    local w = K.win(view)
    return MM.view == view and w ~= nil and w:isVisible() and true or false
end
function K.onScreen(label, w)
    local bad, g = nil, ""
    local ok, e = pcall(function()
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        local x, y, ww, hh = w:getAbsoluteX(), w:getAbsoluteY(), w:getWidth(), w:getHeight()
        g = math.floor(x) .. "," .. math.floor(y) .. " " .. math.floor(ww) .. "x" .. math.floor(hh) .. " on " .. sw .. "x" .. sh
        if not w:isVisible() then bad = "hidden"
        elseif ww <= 0 or hh <= 0 then bad = "no size"
        elseif x < -1 or y < -1 or x + ww > sw + 1 or y + hh > sh + 1 then bad = "off the screen" end
    end)
    if not ok then bad = tostring(e) end
    check(bad == nil, label .. ": sits on screen", (bad and (bad .. " ") or "") .. g)
end
function K.rescue()
    MM.ctx.open = nil
    pcall(MM.showView, "main")
end
function K.spec(w, id)
    for _, s in ipairs((w and w._specs) or {}) do if s.id == id then return s end end
    return nil
end
-- the band's and the window's button ids drawn last frame (the rows' stops left out)
function K.btnIds(w)
    local t = {}
    for _, s in ipairs((w and w._specs) or {}) do
        if not s.listRow and not s.padLab and s.id and not tostring(s.id):find("^field:") then t[#t + 1] = tostring(s.id) end
    end
    return table.concat(t, ",")
end
function K.press(w, id)
    local s = K.spec(w, id)
    if not s then return "no control " .. id end
    if s.disabled then return id .. " is greyed" end
    if not s.fn then return id .. " does nothing" end
    local ok, e = pcall(s.fn)
    if not ok then return id .. ": " .. tostring(e) end
    return nil
end
function K.hit(w, id)
    for _, h in ipairs((w and w._hits) or {}) do if h.id == id then return h end end
    return nil
end
function K.settled()
    local Sc = ZeD.Scale
    local ok, r = pcall(function()
        return math.abs(Sc._appliedRoot - Sc.root()) < 0.001 and math.abs(Sc.root() - Sc.compute()) < 0.001
    end)
    return ok and r and true or false
end

-- ---- the Options window's pages and rows
function K.pages(w) local ok, p = pcall(function() return w:pages() end); return (ok and p) or {} end
function K.pageOf(w, raw) for i, p in ipairs(K.pages(w)) do if p.raw == raw then return p, i end end; return nil, nil end
function K.rowsOf(w, raw)
    local p = K.pageOf(w, raw)
    if not p then return {} end
    local ok, r = pcall(function() return w:rowsFor(p) end)
    return (ok and r) or {}
end
function K.toPage(w, raw)
    local _, i = K.pageOf(w, raw)
    if i then w.pageIdx = i end
    w.scroll = 0
    w.focusId = nil
    pcall(function() w.find:setText("") end)
end
function K.optName(r)
    local n = r and r.opt and r.opt.name
    return n and tostring(n) or nil
end
-- a game option's row (outside ZeD setup) by its GameOption name
function K.grow(w, name)
    for _, p in ipairs(K.pages(w)) do
        if not p.setup then
            for _, r in ipairs(K.rowsOf(w, p.raw)) do if K.optName(r) == name then return r, p end end
        end
    end
    return nil, nil
end
-- a ZeD setup row by option id, or a merged row by its key (readMarks, messages, hiddenFacts, glyphs, wheels, screens)
function K.zrow(w, id)
    for _, r in ipairs(K.rowsOf(w, "zed")) do
        local c = r.control
        local mk = (type(c) == "table") and c.zedMerged or nil
        if mk ~= nil then
            if mk == id then return r end
        elseif K.optName(r) == "ZeD_UI." .. id then return r end
    end
    return nil
end
function K.rname(r)
    if not r then return "?" end
    if r.labelKey then return tostring(ZeD.tr(r.labelKey)) end
    if r.chord then return tostring(r.chord) end
    return tostring(r.label or K.optName(r) or r.kind)
end
-- a pick as the window's own setCombo makes it (a click on a ZeD control, or a drop-down's item)
function K.pick(r, i)
    local c = r and r.control
    if not c then error("no control to pick on") end
    if c.disabled then return false end
    c.selected = i
    if c.onChange then c.onChange(c.target, c, c.onChangeArgs and c.onChangeArgs[1], c.onChangeArgs and c.onChangeArgs[2]) end
    return true
end
-- a tick as the window's own setTick makes it
function K.tick(r, i, v)
    local c = r.control
    c.selected[i] = v
    if c.changeOptionMethod then c.changeOptionMethod(c.changeOptionTarget, i, v, c.changeOptionArg1, c.changeOptionArg2, c) end
end
-- the rows the window drew as stops last frame (with Find: the rows found)
function K.found(w)
    local t = {}
    for _, s in ipairs((w and w._specs) or {}) do if s.listRow and s.rowRef then t[#t + 1] = s.rowRef end end
    return t
end
function K.isStop(w, r)
    for _, s in ipairs((w and w._specs) or {}) do if s.listRow and s.rowRef == r then return true end end
    return false
end
-- a row the window dims (no hit boxes): See-through and Solid while in use outside Dark, a row waiting on a switch
function K.dimmed(r)
    if r.moot then return true end
    if (r.labelKey == "UI_ZeD_Settings_SeeThrough" or r.labelKey == "UI_ZeD_Settings_SolidInUse") and ZeD.seeThroughWorks and not ZeD.seeThroughWorks() then return true end
    return (r.zedNeeds or r.zedNeedsNot) and true or false
end
-- the help band's wrap width for a row (the rows' box less its padding and the "Default:" column)
function K.helpWrapW(w, r)
    local T = ZeD.T
    local pad = T.px(MM.U.STACK_PAD)
    local rowsW = w.width - pad * 3 - T.px(210)
    local dcol = 0
    if r.zedDefault and r.control then
        local t = ""
        pcall(function() t = tostring(r.control:getOptionText(r.zedDefault) or "") end)
        local dt = ZeD.tr("UI_ZeD_Options_DefaultIs", t)
        dcol = math.min(T.px(240), MM.textW(T.fontF2, dt) + T.px(26))
    end
    return rowsW - T.px(24) - dcol
end
-- a stage's function that runs only while Options is up: fn(w, met)
local function O(fn)
    return function(met)
        if keep.noOpts then return end
        local w = K.W()
        if not (w and MM.view == "options" and w:isVisible()) then
            keep.noOpts = true
            check(false, "Options: the window stays up while it is walked", "view " .. tostring(MM.view))
            return
        end
        return fn(w, met)
    end
end
-- the same for the welcome
local function WE(fn)
    return function(met)
        if keep.noWel then return end
        local w = K.win("welcome")
        if not (w and MM.view == "welcome") then
            keep.noWel = true
            check(false, "Welcome: the window stays up while it is walked", "view " .. tostring(MM.view))
            return
        end
        return fn(w, met)
    end
end
-- Options opened again (after a part that closes it)
function X.reopen(label)
    after(250, function()
        if MM.view ~= "main" then K.rescue() end
        keep.noOpts = nil
        K.try(label .. ": Options opened again", MM.openOptions)
    end)
    waitFor(function() return K.up("options") end, 4000, function(met)
        if not check(met, label .. ": Options opens again", "view " .. tostring(MM.view)) then keep.noOpts = true; K.rescue() end
    end)
end
-- the footer's Discard, the window kept (the controls back from the stored values, ZeD's look put back)
function X.discard(label)
    after(250, O(function(w)
        K.try(label .. ": Discard (the window stays)", function() w:discardStay() end)
    end))
    waitFor(function() return K.settled() end, 4000, O(function(w, met)
        check(not K.changed() and #K.controlsOff() == 0 and not w.confirm, label .. ": after Discard nothing waits and every ZeD control reads its stored value",
            K.short(K.controlsOff()) .. ((not met) and " (the scale did not settle)" or ""))
    end))
end

-- =========================================================================================================
-- 0: as found
function X.start()
    after(100, function()
        keep.errs = K.errs()
        keep.errs0 = keep.errs
        keep.opt0 = K.snapAll()
        keep.ini0 = K.readLines("ModOptions.ini")
        keep.keys0 = K.readLines("keysB42.ini")
        keep.setupF = (St and St.SETUP_FILE) or "ZeD_setup.txt"
        keep.setup0 = K.readLines(keep.setupF)
        keep.tutF = (WL and WL.TUTORIAL_FILE) or "ZeD_tutorial.txt"
        keep.seenF = (WL and WL.SEEN_FILE) or "ZeD_setup_seen.txt"
        keep.tut0 = K.readLines(keep.tutF)
        keep.seen0 = K.readLines(keep.seenF)
        keep.custom0 = K.readLines("ZeD_custom_additions.txt")
        keep.chords0 = K.readLines("ZeD_chords.txt")
        -- (the setup file for OP75 to OP77: ZeD_setup.txt itself when it is there, put back line for line; else a test
        -- file, so the welcome's Load stays greyed for the player)
        keep.tfile = keep.setup0 and keep.setupF or "ZeD_qa_mu_opt_setup.txt"
        keep.tfile0 = K.readLines(keep.tfile)
        keep.look0 = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize }
        keep.status0 = ZeD.currentStatus
        keep.alpha0 = ZeD.surfaceAlpha
        keep.scale0 = ZeD.Scale and ZeD.Scale.userScale
        keep.lite0 = St.lite and St.lite() or false
        keep.pad0 = MM.forceGamepad
        keep.mode0 = K.mode()
        keep.dbg = (isDebugEnabled and isDebugEnabled()) and true or false
        say("as found: " .. K.count(keep.opt0) .. " ZeD options; look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize)
            .. ", Style " .. (keep.lite0 and "Lite" or "Full") .. ", UI scale step " .. tostring(keep.scale0) .. ", input " .. tostring(keep.mode0)
            .. ", debug " .. tostring(keep.dbg) .. ", language " .. K.lang() .. ", screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
            .. "; ZeD_setup_seen.txt " .. (keep.seen0 and "there" or "absent") .. ", ZeD_tutorial.txt " .. (keep.tut0 and "there" or "absent")
            .. ", ZeD_setup.txt " .. (keep.setup0 and "there" or "absent"))
        check(MM.openOptions and MM.openWelcome and G and G.GROUPS and St and St.loadSetup and St.saveSetup and ZeD_MMOptions and MainOptions and true or false,
            "the parts under test are loaded (ZeD_MainMenuOptions, ZeD_MainMenuOptionGroups, ZeD_MainMenuWelcome, Settings)")
    end)
    waitFor(function()
        local m = K.ms()
        return m ~= nil and not MM.waking and not (MM.poweringOn and MM.poweringOn()) and (m.delay or 0) <= 0 and MM.root:isVisible()
    end, 30000, function(met)
        check(met, "the desk is awake (powered on, the fade-in over)", "delay " .. tostring(K.ms() and K.ms().delay))
    end)
    after(2500, function()
        -- (a first launch opens the welcome by itself, 120 frames in: left as it came, nothing answered)
        if MM.view ~= "main" then
            note("the desk had the " .. tostring(MM.view) .. " view up at the start (the first-launch setup): back to the main window, nothing answered")
            MM.showView("main")
        end
        if keep.lite0 then note("Style was Lite: set to Full for the sweep, put back at the end"); K.style(1) end
    end)
    after(500, function()
        check(MM.view == "main" and K.up("main"), "the main window is up", "view " .. tostring(MM.view))
        K.errCheck("the desk at rest")
    end)
end

-- =========================================================================================================
-- 1: ways in (OP1)
function X.ways()
    after(200, function() K.try("OP1: the desk's Options", MM.openOptions) end)
    waitFor(function() return K.up("options") end, 4000, function(met)
        if not check(met, "OP1: the desk's Options opens ZeD's Options window", "view " .. tostring(MM.view)) then keep.noOpts = true; K.rescue() end
    end)
    after(400, O(function(w)
        K.onScreen("OP1: Options at the menu", w)
        check(not (K.mo() and K.mo():isVisible()), "OP1: the game's own Options screen stays hidden underneath")
        if K.changed() then note("OP1: the game's changed flag was set as Options opened"); pcall(function() w:discardStay() end) end
        w.pageIdx = 3; w.scroll = 0
    end))
    after(300, O(function(w) K.try("OP1: Back with nothing changed", function() w:back() end) end))
    waitFor(function() return MM.view == "main" end, 3000, function(met)
        if keep.noOpts then return end
        if not check(met, "OP1: Back with nothing changed leaves to the main window", "view " .. tostring(MM.view)) then K.rescue() end
    end)
    after(250, function()
        K.try("OP1: the game's OPTIONS item", function() MainScreen.onMenuItemMouseDownMainMenu({ internal = "OPTIONS" }, 0, 0) end)
    end)
    waitFor(function() return K.up("options") end, 4000, function(met)
        local w = K.W()
        if not check(met, "OP1: the game's OPTIONS item opens ZeD's window", "view " .. tostring(MM.view)) then keep.noOpts = true; K.rescue(); return end
        check(w.pageIdx == 3, "OP1: reopened, the window is on the page used last", "page " .. tostring(w.pageIdx))
    end)
    after(300, O(function(w) K.try("OP1: Back", function() w:back() end) end))
    waitFor(function() return MM.view == "main" end, 3000, function(met) if not met then K.rescue() end end)
    after(250, function()
        if keep.noOpts then return end
        -- (only while ZeD's hook is on the game's screen: without it the game's own Options would show)
        if not (K.mo() and K.mo()._zedHooked) then
            keep.noVis = true
            check(false, "OP1: ZeD's hooks are on the game's Options screen (MM.hookOptions)")
            K.try("OP1: the desk's Options again", MM.openOptions)
            return
        end
        K.try("OP1: the game's screen asked to show (setVisible true)", function() K.mo():setVisible(true) end)
    end)
    waitFor(function() return K.up("options") end, 4000, function(met)
        if keep.noOpts or keep.noVis then return end
        if not check(met and not K.mo():isVisible(), "OP1: the game's screen asked to show opens ZeD's window instead", "view " .. tostring(MM.view)) then keep.noOpts = true; K.rescue() end
    end)
    after(100, function()
        skip("OP1: the pause window's Options and the D-pad ZeD wheel's setup slice", "in game only (a QA save)")
        K.errCheck("OP1 ways in")
    end)
end

-- =========================================================================================================
-- 2: the pages as built (read only)
function X.sGroups(w)
    -- OP3
    local want = { "zed", "display", "graphics", "audio", "controls", "gameplay", "interface", "access", "mods" }
    local got, badT = {}, {}
    for i, p in ipairs(K.pages(w)) do
        got[#got + 1] = tostring(p.raw)
        local key = G.GROUPS[i] and G.GROUPS[i].title
        if p.title == nil or p.title == "" or p.title == key then badT[#badT + 1] = tostring(p.raw) .. "=" .. tostring(p.title) end
    end
    check(table.concat(got, ",") == table.concat(want, ","), "OP3: the nine groups in order", table.concat(got, ","))
    check(#badT == 0, "OP3: every group's title reads in the player's language (" .. K.lang() .. ")", K.short(badT))
    local extra = {}
    for _, vp in ipairs(w:vpages()) do if not G.pageId(vp.raw) then extra[#extra + 1] = tostring(vp.raw) end end
    if #extra == 0 then
        note("OP3: no mod added a page with MainOptions:addPage here; the Mods group is the game's Mods page alone")
    else
        local heads = {}
        for _, r in ipairs(K.rowsOf(w, "mods")) do if r.kind == "header" then heads[tostring(r.text)] = true end end
        local miss = {}
        for _, t in ipairs(extra) do if not heads[t] then miss[#miss + 1] = t end end
        check(#miss == 0, "OP3: each page a mod added shows under Mods with its title (" .. #extra .. ")", K.short(miss))
    end
    -- OP4
    local other = getText("UI_ServerSettingGroup_Other")
    local placed, underOther = {}, {}
    for _, p in ipairs(K.pages(w)) do
        if not p.setup then
            local inOther = false
            for _, r in ipairs(K.rowsOf(w, p.raw)) do
                if r.kind == "header" then inOther = (r.text == other)
                else
                    local n = K.optName(r)
                    if n then placed[n] = true end
                    if inOther then underOther[#underOther + 1] = tostring(p.raw) .. ": " .. tostring(n or r.label) end
                end
            end
        end
    end
    local names, lost = 0, {}
    for _, o in ipairs((K.mo() and K.mo().gameOptions and K.mo().gameOptions.options) or {}) do
        local n = tostring(o.name)
        if not n:find(".", 1, true) then
            names = names + 1
            if not placed[n] and not G.MOOT[n] then lost[#lost + 1] = n end
        end
    end
    check(#underOther == 0, "OP4: no game option lands under Other", K.short(underOther))
    check(names > 0 and #lost == 0, "OP4: every one of the game's " .. names .. " options is filed in a group (the eight moot ones hidden)", K.short(lost))
    -- OP10
    local badS = {}
    for _, g in ipairs(G.GROUPS) do
        for _, sec in ipairs(g.sections or {}) do
            local k = sec[1]
            if k then
                local t = G.text(k)
                if t == nil or t == "" or t == k then badS[#badS + 1] = k end
            end
        end
    end
    check(#badS == 0, "OP10: every section title borrowed from a key reads as words in " .. K.lang(), K.short(badS))
    note("OP10: section titles read in this language only; EN, DE, FR, ES, RU and JP each need a launch in that language")
end
function X.sAudio(w)
    -- OP5
    local btn = nil
    for _, r in ipairs(K.rowsOf(w, "audio")) do if r.kind == "button" and not r.opt then btn = r end end
    if not btn then skip("OP5: the Advanced sound button's row", "the game offers no Advanced or Reload sound button here"); return end
    local c = btn.control
    check(tostring(btn.label or "") ~= "", "OP5: the Advanced (or Reload) sound button's row has a name",
        "name \"" .. tostring(btn.label) .. "\", the button reads \"" .. tostring(c and c.title) .. "\", its tooltip " .. tostring(c and c.tooltip) .. " (the help band reads nothing either)")
end
function X.sMoot(w)
    local shown, onlyRows = {}, {}
    local onMods, marked, oldShown = 0, {}, {}
    local old = {}
    for _, id in ipairs(G.RETIRED or {}) do old["ZeD_UI." .. id] = true end
    for _, id in ipairs({ "solidInUse", "healthBlink", "gridTint" }) do old["ZeD_UI." .. id] = true end
    for _, p in ipairs(K.pages(w)) do
        for _, r in ipairs(K.rowsOf(w, p.raw)) do
            local n = K.optName(r)
            if n and not p.setup then
                if G.MOOT[n] then shown[#shown + 1] = n end
                if G.ONLY[n] then onlyRows[n] = r end
                if p.raw == "mods" and n:sub(1, 7) == "ZeD_UI." then
                    onMods = onMods + 1
                    if old[n] then
                        oldShown[#oldShown + 1] = n:sub(8)
                        if r.moot or r.under or r.only or r.why then marked[#marked + 1] = n:sub(8) end
                    end
                end
            end
        end
    end
    -- OP6 (design)
    note("OP6: the eight settings that do nothing with ZeD active are hidden, not grayed: " .. #shown .. " of 8 show in any group or under Other"
        .. ((#shown > 0) and (" (" .. K.short(shown) .. ")") or "") .. "; the gray \"Does nothing with ZeD active\" drawing is reached by nothing")
    -- OP7 (bug or design)
    note("OP7: Inventory windows given back (screenWindows) stored " .. tostring(K.val("screenWindows")) .. ", Watch given back (screenWatch) " .. tostring(K.val("screenWatch"))
        .. "; either way the seven settings the game's own inventory and clock read again stay hidden (" .. #shown .. " shown)")
    -- OP8
    local bad = {}
    for n, pair in pairs(G.ONLY) do
        local r = onlyRows[n]
        if not r then bad[#bad + 1] = n .. ": no row"
        elseif not r.only then bad[#bad + 1] = n .. ": no mark"
        else
            for _, k in ipairs(pair) do
                local t = G.text(k)
                if t == nil or t == "" or t == k then bad[#bad + 1] = n .. ": " .. k .. " has no words" end
            end
        end
    end
    check(#bad == 0, "OP8: the three ONLY rows (Dyslexic font, Sidebar size, Tooltip font) carry their line and help note", K.short(bad))
    note("OP8: Tooltip font sizing ZeD's tooltips and Sidebar size working in multiplayer only are seen in game, not here")
    -- OP9 (design)
    note("OP9: the Mods group lists " .. onMods .. " of ZeD-GUI's options as plain drop-downs; of the retired styles and the three no-ops "
        .. #oldShown .. " are among them (" .. K.short(oldShown) .. "), " .. #marked .. " with a mark that they do nothing")
end
X.SETUP_SPEC = {
    { "lookStyle", "radio", 2, 1 }, { "baseTheme", "radio", 3, "dark" }, { "accentColor", "swatch", "accents", "accent" },
    { "statusColors", "radio", 2, 1 }, { "textSize", "radio", 2, "size" }, { "seeThrough", "scale", 5, "see" },
    { "uiScale", "scale", "scales", 1 }, { "additionsPreset", "radio", 4, 1 }, { "ammoBox", "onoff", 2, 1 },
    { "readMarks", "radio", 3, 1 }, { "dashLamps", "onoff", 2, 1 }, { "moodleNotices", "onoff", 2, 1 },
    { "messages", "radio", 3, 1 }, { "haloBubble", "onoff", 2, 1 }, { "hintStrip", "radio", 3, 1 },
    { "putBack", "onoff", 2, 1 }, { "sandboxInGame", "onoff", 2, 1 }, { "hiddenFacts", "radio", 2, 1 },
    { "appliances", "onoff", 2, 1 }, { "smartAttach", "onoff", 2, 1 }, { "contextStyle", "radio", 2, 2 },
    { "menuGuess", "onoff", 2, 2 }, { "wornInList", "radio", 2, 1 }, { "uiSounds", "radio", 3, 1 },
    { "hiddenActions", "radio", 3, 1 }, { "moodlePlace", "radio", 3, 1 }, { "watchPlace", "radio", 2, 1, full = true },
    { "focusStyle", "drop", 4, 1 }, { "glyphs", "radio", 2, 1 }, { "wheels", "drop", 4, 2 },
    { "wheelDeadZone", "scale", 9, 4 }, { "runSneak", "onoff", 2, 1 }, { "safeMode", "onoff", 2, 1 },
    { "screens", "tick", 8, nil }, { "inputModeLock", "radio", 3, 1 },
    { "screenConsole", "onoff", 2, 1, debug = true }, { "testLanguage", "onoff", 2, 1, debug = true },
}
function X.specDefault(d)
    if d == "dark" then return K.idx(St.baseKeys, "dark") end
    if d == "accent" then return K.idx(St.accentKeys, ZeD.DEFAULT_ACCENT) end
    if d == "size" then return K.idx(St.sizeKeys, St.defaultSizeKey) end
    if d == "see" then return K.idx(St.seeThroughKeys, 90) end
    return d
end
function X.sSetup(w)
    -- OP11, OP23
    local bad, dbgBad = {}, {}
    for _, e in ipairs(X.SETUP_SPEC) do
        local id, style, n = e[1], e[2], e[3]
        if n == "accents" then n = #(St.accentKeys or {}) elseif n == "scales" then n = #(St.scaleKeys or {}) end
        local r = K.zrow(w, id)
        if e.debug then
            if keep.dbg ~= (r ~= nil) then dbgBad[#dbgBad + 1] = id .. ((r ~= nil) and " shows" or " is missing") end
        elseif e.full and St.lite() then
            if r then bad[#bad + 1] = id .. " shows in Lite" end
        elseif not r then bad[#bad + 1] = id .. ": no row"
        else
            local c = r.control
            local gotStyle = (r.kind == "tick") and "tick" or (r.zedStyle or "drop")
            if gotStyle ~= style then bad[#bad + 1] = id .. " drawn " .. tostring(gotStyle) .. " (want " .. style .. ")" end
            local cn = #((c and c.options) or {})
            if cn ~= n then bad[#bad + 1] = id .. " " .. cn .. " items (want " .. n .. ")" end
            local def = X.specDefault(e[4])
            if def ~= nil and r.zedDefault ~= def then bad[#bad + 1] = id .. " default " .. tostring(r.zedDefault) .. " (want " .. tostring(def) .. ")" end
        end
    end
    check(#bad == 0, "OP11: every ZeD setup row has the map's control, item count and default (" .. #X.SETUP_SPEC .. " rows)", K.short(bad))
    check(#dbgBad == 0, "OP23: the Lua console and Test language rows show " .. (keep.dbg and "in debug mode" or "only in debug mode (this launch is not)"), K.short(dbgBad))
    if not keep.dbg then
        local hid = {}
        for _, o in ipairs(w:zedHiddenOpts()) do hid[tostring(o.id)] = true end
        check(hid.screenConsole and hid.testLanguage and true or false, "OP23: outside debug the two debug options are among those Reset to defaults puts back (hidden options)")
    else
        note("OP23: a debug launch: whether Reset to defaults puts the two debug options back outside debug is read on a plain launch")
    end
    local others = {}
    local other = getText("UI_ServerSettingGroup_Other")
    local inO = false
    for _, r in ipairs(K.rowsOf(w, "zed")) do
        if r.kind == "header" then inO = (r.text == other) elseif inO then others[#others + 1] = K.rname(r) end
    end
    if #others > 0 then note("OP11: ZeD options no table names sit under Other on ZeD setup: " .. K.short(others)) end
    check(ZeD.tr("UI_ZeD_Options_DefaultIs", "x") ~= "UI_ZeD_Options_DefaultIs", "OP11: the help band's \"Default: X\" has its words")
    -- OP30
    local noTip = {}
    for _, r in ipairs(K.rowsOf(w, "zed")) do
        if r.zedTipKey then
            local t = ZeD.tr(r.zedTipKey)
            if t == nil or t == "" or t == r.zedTipKey then noTip[#noTip + 1] = tostring(r.zedTipKey) end
        elseif r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "chord" and not r.zedTip then
            noTip[#noTip + 1] = K.rname(r) .. " (no tip)"
        end
    end
    check(#noTip == 0, "OP30: every ZeD setup row's help reads a real tip", K.short(noTip))
    local sc = ZeD.tr("Sandbox_Custom")
    check(sc ~= "Sandbox_Custom" and sc ~= "", "OP30: Sandbox_Custom, a game key, reads as words through ZeD.tr", sc)
end
function X.sLang(w)
    -- OP37
    if not ZeD.isMachineLangText then skip("OP37: the machine translation mark", "ZeD.isMachineLangText is not there"); return end
    local r = K.grow(w, "language")
    if not (r and r.control) then skip("OP37: the machine translation mark", "no Language row"); return end
    local c = r.control
    local mark = ZeD.tr("UI_ZeD_Options_MachineTranslation")
    local n, bad = 0, {}
    for i = 1, #(c.options or {}) do
        local t = ""
        pcall(function() t = tostring(c:getOptionText(i) or "") end)
        if ZeD.isMachineLangText(t) then n = n + 1 end
        if mark ~= "" and t:find(mark, 1, true) then bad[#bad + 1] = t end
    end
    check(mark ~= "UI_ZeD_Options_MachineTranslation" and #bad == 0, "OP37: the language list's own option text stays as the game wrote it (the mark is drawn only)",
        n .. " of " .. #(c.options or {}) .. " languages marked \"" .. mark .. "\"; " .. K.short(bad))
    note("OP37: picking and applying a language resets Lua: by hand only")
end
X.PALETTE = { 555, 303, 304, 403, 503, 314, 315, 505, 414, 523, 524, 525, 535, 545,
              444, 300, 400, 310, 500, 311, 501, 510, 422, 521, 433, 532, 533, 544,
              333, 420, 330, 430, 431, 530, 341, 442, 443, 543, 451, 550, 553, 554,
              222, 20, 121, 30, 132, 230, 141, 142, 50, 52, 243, 250, 343, 353,
              111, 33, 35, 134, 43, 233, 44, 144, 145, 53, 55, 154, 254, 455,
              0, 2, 3, 4, 5, 103, 113, 125, 224, 225, 325, 235, 345, 445 }
function X.onPalette(b)
    for _, code in ipairs(X.PALETTE) do
        local cr = math.floor(code / 100) / 5
        local cg = math.fmod(math.floor(code / 10), 10) / 5
        local cb = math.fmod(code, 10) / 5
        if math.abs((b.r or -1) - cr) < 0.02 and math.abs((b.g or -1) - cg) < 0.02 and math.abs((b.b or -1) - cb) < 0.02 then return true end
    end
    return false
end
function X.sColors(w)
    -- OP33
    local rows, off = {}, {}
    for _, p in ipairs(K.pages(w)) do
        if not p.setup then
            for _, r in ipairs(K.rowsOf(w, p.raw)) do
                if r.kind == "color" and r.control then
                    rows[#rows + 1] = r
                    local b = r.control.backgroundColor or {}
                    if not X.onPalette(b) then off[#off + 1] = r end
                end
            end
        end
    end
    if #rows == 0 then skip("OP33: the color rows", "no color row found"); return end
    if #off == 0 then
        check(true, "OP33: every color row's stored color (" .. #rows .. " rows) is one of the 84 swatches here, so its frame and the pad's start are right")
    else
        local r = off[1]
        local at = nil
        pcall(function()
            w:openPalette(r, { x = w:getAbsoluteX() + 100, y = w:getAbsoluteY() + 100, w = 10, h = 10 })
            at = w._palette and w._palette.at
        end)
        w._palette = nil
        local b = r.control.backgroundColor or {}
        check(false, "OP33: a stored color off the 84 swatches is framed in the palette and the pad starts on it",
            #off .. " rows off the palette, first " .. K.rname(r) .. " (" .. string.format("%.3f,%.3f,%.3f", b.r or 0, b.g or 0, b.b or 0) .. "): no frame, the pad starts on swatch " .. tostring(at))
    end
    note("OP33: a palette pick sets the button's color and the game's changed flag only: the game's live highlight call and a mod color option's onChange are skipped (code read, not staged)")
end
function X.sMods(w)
    -- OP36, OP49, OP63: a mod's text option and a mod's key bind, if any mod here has one
    keep.textRow, keep.modKey = nil, nil
    for _, r in ipairs(K.rowsOf(w, "mods")) do
        if r.kind == "text" and not keep.textRow then keep.textRow = r end
        if r.kind == "key" and r.entry and r.entry.isModBind and not keep.modKey then keep.modKey = r end
    end
    if not keep.textRow then skip("OP36: a mod's text option edited in the band", "no mod with a text option is on") end
    if not keep.modKey then
        skip("OP49: a mod's key bind changed then discarded", "no mod with a PZAPI key bind is on (ZeD has none)")
        skip("OP63: a mod's key binds on the Mods page", "no mod with a PZAPI key bind is on (ZeD has none)")
    else
        note("OP63: mod key binds show on the Mods page as key rows with ZeD's generic key help (" .. K.rname(keep.modKey) .. "); ModOptions saves the key only, not its modifiers (code read)")
    end
end
function X.sChord(w)
    -- OP24
    local r = nil
    for _, x in ipairs(K.rowsOf(w, "zed")) do if x.kind == "chord" and not r then r = x end end
    if not r then skip("OP24: the quick action chords", "no chord rows here (Lite hides them)"); return end
    local items = {}
    K.try("OP24: a chord's list opened", function()
        w:openChord(r, { x = w:getAbsoluteX() + 100, y = w:getAbsoluteY() + 100, w = 200, h = 24 })
        items = (MM.popup and MM.popup.items) or {}
    end)
    MM.ctx.open = nil
    local live = 0
    for _, it in ipairs(items) do if type(it) == "table" and it.fn and not it.disabled then live = live + 1 end end
    check(getSpecificPlayer(0) == nil and live == 1 and type(items[1]) == "table" and items[1].fn ~= nil, "OP24: at the main menu a chord's list offers None alone (the actions need a player)",
        #items .. " items, " .. live .. " live")
    note("OP24: a chord's pick or X saves at once (ZeD_chords.txt), is not counted as a change and Discard does not bring it back (code read; no chord picked here)")
end
function X.structure()
    after(300, O(function(w) K.toPage(w, "zed") end))
    after(400, O(function(w) K.try("OP3/OP4/OP10: the groups", function() X.sGroups(w) end) end))
    after(150, O(function(w)
        K.try("OP5: the Advanced sound button", function() X.sAudio(w) end)
        K.try("OP6 to OP9: the moot and ONLY rows", function() X.sMoot(w) end)
    end))
    after(150, O(function(w) K.try("OP11/OP23/OP30: ZeD setup's rows", function() X.sSetup(w) end) end))
    after(150, O(function(w)
        K.try("OP37: the language list", function() X.sLang(w) end)
        K.try("OP33: the color rows", function() X.sColors(w) end)
        K.try("OP36/OP49/OP63: the mods' rows", function() X.sMods(w) end)
        K.try("OP24: the chords", function() X.sChord(w) end)
    end))
    -- OP36: a mod's text option, edited in the band and left with Escape
    after(250, O(function(w)
        local r = keep.textRow
        if not r then return end
        if MM.gamepad() then
            -- (with a pad the field opens the pad keyboard over the desk)
            keep.textRow = nil
            skip("OP36: a mod's text option edited in the band", "a controller drives the menu: the field would open the pad keyboard")
            return
        end
        keep.text0 = tostring(r.control:getText() or "")
        K.try("OP36: the text row opened in the band", function() w:editText(r) end)
    end))
    after(300, O(function(w)
        local r = keep.textRow
        if not r then return end
        check(w.confirm == "text" and w.field:isVisible(), "OP36: a mod's text option opens the band's Value field", tostring(w.confirm))
        K.try("OP36: Escape in the field", function() w.field.onEscape() end)
        check(not w.confirm and not w.field:isVisible() and tostring(r.control:getText() or "") == keep.text0, "OP36: Escape cancels, the text unchanged", tostring(w.confirm))
    end))
    after(150, function() K.errCheck("the pages read") end)
end

-- =========================================================================================================
-- 3: ZeD setup drawn, top to bottom (OP12, OP16, OP31, OP80)
X.DRAWN = { seg1 = "radio", box = "drop", sw1 = "swatch", sc = "scale", onoff = "onoff", t1 = "tick" }
function X.collectDraw(w)
    for _, h in ipairs(w._hits or {}) do
        local i, part = tostring(h.id):match("^options:r(%d+):(%w+)$")
        if i and X.DRAWN[part] then keep.draw[tonumber(i)] = X.DRAWN[part] end
    end
end
function X.judgeDraw(w, word)
    local rows = K.rowsOf(w, "zed")
    local missing, fell, two = {}, {}, 0
    local swRow = nil
    for i, r in ipairs(rows) do
        if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "chord" then
            if r._lab then two = two + 1 end
            if r.kind == "combo" and r.zedStyle and not K.dimmed(r) then
                local d = keep.draw[i]
                if not d then missing[#missing + 1] = K.rname(r)
                elseif d == "drop" then fell[#fell + 1] = K.rname(r) end
                if r.zedStyle == "swatch" then swRow = { r = r, d = d } end
            end
        end
    end
    check(#missing == 0, "OP12: every ZeD control on ZeD setup is drawn, as itself or as the drop-down (" .. word .. ")", K.short(missing))
    note("OP12: at text size " .. tostring(ZeD.currentSize) .. " these ZeD controls are drawn as the drop-down: " .. ((#fell > 0) and K.short(fell) or "none"))
    -- OP16
    if swRow and swRow.d == "swatch" then
        local names = {}
        for i = 1, #(St.accentKeys or {}) do
            local t = ""
            pcall(function() t = tostring(swRow.r.control:getOptionText(i) or "") end)
            if t == "" then names[#names + 1] = "well " .. i .. " has no name" end
        end
        check(#names == 0, "OP16: Accent color is drawn as " .. #(St.accentKeys or {}) .. " wells, each with its color's name for the hint (" .. word .. ")", K.short(names))
    elseif swRow then
        note("OP16: Accent color is drawn as the drop-down at text size " .. tostring(ZeD.currentSize) .. " (too wide for its room)")
    end
    note("OP16: the hover hint, the pick's frame and the name beside the wells are drawn only (not read by a script)")
    -- OP80
    K.onScreen("OP80: Options at text size " .. tostring(ZeD.currentSize), w)
    local pb = w._pagesBox
    local over = pb and (#K.pages(w) * ZeD.T.px(30) > pb.h) or false
    check(not over or K.hit(w, "options:pagestrack") ~= nil, "OP80: the page list scrolls in its own box when it is taller than the box (" .. word .. ")",
        "over " .. tostring(over))
    note("OP80: at text size " .. tostring(ZeD.currentSize) .. ", " .. two .. " ZeD setup names take two lines; the window " .. math.floor(w.width) .. "x" .. math.floor(w.height))
    -- OP31
    local long = {}
    for _, r in ipairs(rows) do
        if r.zedTipKey and r.kind ~= "header" then
            local t = MM.ui.plain(ZeD.tr(r.zedTipKey))
            if r.labelKey == "UI_ZeD_Settings_UiScale" and St.scaleTooBigHelp then
                local tb = St.scaleTooBigHelp()
                if tb then t = t .. " " .. tb end
            end
            local n = #ZeD.Atoms.wrapText(t, ZeD.T.fontF2, K.helpWrapW(w, r))
            if n > 3 then long[#long + 1] = K.rname(r) .. " " .. n .. " lines" end
        end
    end
    check(#long == 0, "OP31: every ZeD setup tip fits the help band's three lines (" .. word .. ", text size " .. tostring(ZeD.currentSize) .. ")",
        ((#long > 0) and "the rest is not drawn, with no mark: " or "") .. K.short(long))
end
function X.drawWalk(word)
    after(300, O(function(w) K.toPage(w, "zed"); keep.draw = {} end))
    each(nil, 260, 15000, function()
        local w = K.W()
        local l = {}
        if keep.noOpts or not w then return l end
        local total = 0
        for _, r in ipairs(K.rowsOf(w, "zed")) do total = total + (r._h or 0) end
        local vh = (w._list and w._list.h) or 400
        local y = 0
        while y < total + 1 and #l < 40 do l[#l + 1] = y; y = y + math.max(40, math.floor(vh * 0.6)) end
        if #l == 0 then l[1] = 0 end
        return l
    end, function(y) K.W().scroll = y end, function() X.collectDraw(K.W()) end, function(st)
        if keep.noOpts then return end
        if #st.bad > 0 or not st.met then check(false, "OP12: ZeD setup walked top to bottom (" .. word .. ")", K.short(st.bad)) end
    end)
    after(200, O(function(w)
        K.try("OP12/OP16/OP31/OP80: ZeD setup as drawn (" .. word .. ")", function() X.judgeDraw(w, word) end)
        w.scroll = 0
    end))
end
-- OP68: the button map's labels inside the figure's box
function X.padFit(word)
    after(300, O(function(w) K.try("OP68: the button map opened", function() w:openSub("pad") end) end))
    after(600, O(function(w)
        local fig = w._padFig
        if not (w.sub == "pad" and fig) then check(false, "OP68: the button map draws its figure (" .. word .. ")", "sub " .. tostring(w.sub)); return end
        local b, out = fig.box, {}
        for id, l in pairs(fig.labs or {}) do
            if l.x < b.x - 1 or l.y < b.y - 1 or l.x + l.w > b.x + b.w + 1 or l.y + l.h > b.y + b.h + 1 then out[#out + 1] = tostring(id) end
        end
        check(K.count(fig.labs) == 13 and #out == 0, "OP68: the button map's 13 labels sit inside the figure's box (" .. word .. ", text size " .. tostring(ZeD.currentSize) .. ")",
            K.count(fig.labs) .. " labels; outside: " .. K.short(out))
        K.onScreen("OP68: Options on the button map (" .. word .. ")", w)
        K.try("OP68: the button map shut", function() w:closeSub() end)
    end))
end
function X.drawing()
    X.drawWalk("the text size found")
    X.padFit("the text size found")
    -- the other text size, picked on ZeD setup (live; the window's Discard puts it back)
    after(300, O(function(w)
        local r = K.zrow(w, "textSize")
        if not r then keep.noSize = true; check(false, "OP80: ZeD setup has the Text size row"); return end
        keep.size0 = r.control.selected
        keep.sizeOther = (keep.size0 == 1) and 2 or 1
        K.try("OP80: the other text size picked on ZeD setup", function() K.pick(r, keep.sizeOther) end)
    end))
    waitFor(function() return keep.noSize or ZeD.currentSize ~= keep.look0[3] end, 3000, O(function(w, met)
        if keep.noSize then return end
        check(met, "OP80: the other text size is on screen at once (a pick, before Apply)", tostring(ZeD.currentSize))
    end))
    X.drawWalk("the other text size")
    X.padFit("the other text size")
    X.discard("text size")
    after(200, O(function(w)
        check(ZeD.currentSize == keep.look0[3], "OP80: Discard puts the text size found back on screen", tostring(ZeD.currentSize))
        K.errCheck("ZeD setup drawn")
    end))
end

-- =========================================================================================================
-- 4: ZeD setup's controls (every pick on the controls; the window's Discard after)
function X.scale()
    after(300, O(function(w)
        K.toPage(w, "zed")
        local r = K.zrow(w, "uiScale")
        if not r then keep.noScale = true; check(false, "OP13: ZeD setup has the UI scale row"); return end
        local c = r.control
        keep.sc0 = c.selected
        check(St.scaleStepOff(c, 2) == true, "OP13: the retired 0.5x step is off (dimmed, no pick takes it)", tostring(c:getOptionText(2)))
        local off = {}
        for i = 3, #(c.options or {}) do if St.scaleStepOff(c, i) then off[#off + 1] = tostring(c:getOptionText(i)) end end
        local tb = St.scaleTooBigHelp and St.scaleTooBigHelp() or nil
        check((#off == 0) == (tb == nil), "OP13: the help says which steps are too big for this screen exactly when some are",
            "too big here: " .. ((#off > 0) and K.short(off) or "none") .. "; help: " .. tostring(tb))
        local ro = ZeD.tr("UI_ZeD_Options_ScaleAutoNow", "1.5x")
        check(ro ~= "UI_ZeD_Options_ScaleAutoNow" and ro:find("1.5x", 1, true) ~= nil, "OP13: Auto's readout names the size Auto came to", ro)
        local ca = ZeD.tr("UI_ZeD_Options_ScaleCappedNow", "2x", "1.5x")
        check(ca ~= "UI_ZeD_Options_ScaleCappedNow", "OP13: a saved step above the cap reads \"X (Y here)\"", ca)
        local items = {}
        K.try("OP13: the UI scale pop-up list", function()
            w:openCombo(r, { x = w:getAbsoluteX() + 100, y = w:getAbsoluteY() + 100, w = 100, h = 20 })
            items = (MM.popup and MM.popup.items) or {}
        end)
        MM.ctx.open = nil
        check(items[2] ~= nil and items[2].disabled == true, "OP13: in the pop-up list an off step is greyed and takes no pick", tostring(items[2] and items[2].text))
        note("OP13: a click on the track picks the nearest step from the pointer's place: not staged (a script does not move the pointer)")
        K.try("OP14: UI scale set to Auto on the control", function() K.pick(r, 1) end)
        w:nudge(r, -1)
        check(c.selected == 1, "OP14: left at Auto stops at the end", tostring(c.selected))
    end))
    waitFor(function() return keep.noScale or K.settled() end, 4000, function() end)
    each(nil, 700, 15000, function()
        if keep.noScale or keep.noOpts then return {} end
        return { 1, 2, 3, 4, 5, 6, 7, 8 }
    end, function(_, i, st)
        local w = K.W()
        local r = K.zrow(w, "uiScale")
        w:nudge(r, 1)
        st.seen = st.seen or {}
        st.seen[#st.seen + 1] = r.control.selected
    end, nil, function(st)
        if keep.noScale or keep.noOpts then return end
        local w = K.W()
        local r = K.zrow(w, "uiScale")
        local c = r.control
        local offHit, lastOn = {}, 1
        for _, v in ipairs(st.seen or {}) do if St.scaleStepOff(c, v) then offHit[#offHit + 1] = v end end
        for i = 1, #(c.options or {}) do if not St.scaleStepOff(c, i) then lastOn = i end end
        local seen = {}
        for _, v in ipairs(st.seen or {}) do seen[#seen + 1] = tostring(v) end
        check(#offHit == 0 and c.selected == lastOn and #st.bad == 0, "OP14: right on the pad skips the off steps and stops at the last step that fits",
            "steps " .. table.concat(seen, ",") .. "; the last that fits " .. lastOn .. " " .. K.short(st.bad))
        w:activateRow(r)
        check(c.selected == 1, "OP14: A past the last step that fits wraps to Auto", tostring(c.selected))
    end)
    waitFor(function() return keep.noScale or K.settled() end, 4000, O(function(w)
        if keep.noScale then return end
        local r = K.zrow(w, "uiScale")
        K.try("UI scale: the control back as found", function() K.pick(r, keep.sc0) end)
    end))
    waitFor(function() return keep.noScale or K.settled() end, 4000, O(function(w, met)
        if keep.noScale then return end
        check(met and ZeD.Scale.userScale == keep.scale0, "OP14: UI scale back on the step found", tostring(ZeD.Scale.userScale))
        K.onScreen("Options after the UI scale walk", w)
        K.errCheck("UI scale")
    end))
end
function X.seeAndFocus()
    -- OP15
    after(300, O(function(w)
        local see, th = K.zrow(w, "seeThrough"), K.zrow(w, "baseTheme")
        if not (see and th) then keep.noSee = true; check(false, "OP15: ZeD setup has See-through and Theme"); return end
        keep.th0 = th.control.selected
        keep.wasDark = (ZeD.currentBase == "dark")
        keep.seeStop0 = K.isStop(w, see)
        if keep.wasDark then
            local a0 = ZeD.surfaceAlpha
            local s0 = see.control.selected
            local dir = (s0 >= #(see.control.options or {})) and -1 or 1
            w:nudge(see, dir)
            keep.seeMoved = (ZeD.surfaceAlpha ~= a0) and (tostring(a0) .. " to " .. tostring(ZeD.surfaceAlpha)) or nil
            w:nudge(see, -dir)
            K.pick(th, K.idx(St.baseKeys, "light"))
        else
            K.pick(th, K.idx(St.baseKeys, "dark"))
        end
    end))
    after(500, O(function(w)
        if keep.noSee then return end
        local see = K.zrow(w, "seeThrough")
        local stop = K.isStop(w, see)
        if keep.wasDark then
            check(keep.seeStop0 and not stop, "OP15: See-through is a stop in Dark and dims (no stop) in Light", "Dark " .. tostring(keep.seeStop0) .. ", Light " .. tostring(stop))
            check(keep.seeMoved ~= nil, "OP15: in Dark a See-through step changes the windows at once", tostring(keep.seeMoved))
        else
            check(not keep.seeStop0 and stop, "OP15: See-through dims outside Dark and is a stop in Dark", tostring(ZeD.currentBase) .. " " .. tostring(keep.seeStop0) .. ", Dark " .. tostring(stop))
        end
        note("OP15: the dimmed row's help line is See-through's own tip (drawn, not read here)")
        K.pick(K.zrow(w, "baseTheme"), keep.th0)
    end))
    -- OP25
    after(400, O(function(w)
        local r = K.zrow(w, "focusStyle")
        if not r then check(false, "OP25: ZeD setup has Controller highlight"); return end
        local c = r.control
        local s0 = c.selected
        local other = (s0 == 2) and 3 or 2
        K.pick(r, other)
        local got = St.focusStyle()
        check(got == St.focusStyleKeys[other] and K.val("focusStyle") == s0, "OP25: Controller highlight's sample follows the pick before Apply",
            "the sample draws " .. tostring(got) .. ", stored " .. tostring(K.val("focusStyle")))
        K.pick(r, s0)
        K.errCheck("See-through and Controller highlight")
    end))
end
function X.preset()
    -- OP17
    after(300, O(function(w)
        local pre, ammo = K.zrow(w, "additionsPreset"), K.zrow(w, "ammoBox")
        if not (pre and ammo) then keep.noPre = true; check(false, "OP17: ZeD setup has Preset and Ammo on the belt"); return end
        local P = St.ADDITION_PRESETS[2]
        K.pick(pre, 2)
        local bad = {}
        for _, id in ipairs(St.ADDITION_IDS or {}) do
            local want = P[id]
            if want and not tostring(id):find("Style$") and not tostring(id):find(".", 1, true) and K.live(id) ~= want then bad[#bad + 1] = id .. "=" .. tostring(K.live(id)) end
        end
        check(#bad == 0, "OP17: a preset (Vanilla Plus) sets every addition live", K.short(bad))
        K.pick(ammo, 1)
        St.syncAdditionsPreset()
        check(pre.control.selected == 4, "OP17: a hand change reads Custom", "preset " .. tostring(pre.control.selected))
        K.pick(pre, 1)
        K.pick(pre, 4)
        check(K.live("ammoBox") == 1 and K.live("readMarks") == 2, "OP17: Custom picked again brings back the hand picks",
            "ammoBox " .. tostring(K.live("ammoBox")) .. ", readMarks " .. tostring(K.live("readMarks")))
        -- no held set: the file, or nothing (the preset snaps back to what the values make). (Vanilla first, while the
        -- hand picks still read Custom, holds them; so the held set is forgotten after it)
        K.pick(pre, 1)
        St.forgetHeldCustom()
        K.pick(pre, 4)
        St.syncAdditionsPreset()
        if keep.custom0 then
            note("OP17: Custom with no held set reads ZeD_custom_additions.txt: the preset now reads " .. tostring(pre.control.selected) .. ", ammoBox " .. tostring(K.live("ammoBox")))
        else
            check(pre.control.selected == 1 and K.live("ammoBox") == 1, "OP17: Custom with no held set and no file changes nothing and snaps back to the preset the values make",
                "preset " .. tostring(pre.control.selected))
        end
    end))
    -- OP18
    after(300, O(function(w)
        if keep.noPre then return end
        local bad = {}
        for _, key in ipairs({ "readMarks", "messages", "hiddenFacts", "glyphs", "wheels" }) do
            local r, d = K.zrow(w, key), G.MERGED[key]
            if not (r and d) then bad[#bad + 1] = key .. ": no row"
            else
                for i, it in ipairs(d.items) do
                    local before = {}
                    for id in pairs(it[2]) do before[id] = K.live(id) end
                    K.mo().gameOptions.changed = false
                    K.pick(r, i)
                    local moved = false
                    for id, v in pairs(it[2]) do
                        if K.live(id) ~= v then bad[#bad + 1] = key .. " " .. i .. ": " .. id .. "=" .. tostring(K.live(id)) end
                        if before[id] ~= v then moved = true end
                    end
                    if r.control.selected ~= i then bad[#bad + 1] = key .. " reads " .. tostring(r.control.selected) .. " after " .. i end
                    if moved and not K.changed() then bad[#bad + 1] = key .. " " .. i .. ": no changed flag" end
                end
                K.pick(r, r.zedDefault or 1)
            end
        end
        local sr = K.zrow(w, "screens")
        if sr then
            for i, t in ipairs(G.MERGED.screens.ticks) do
                K.tick(sr, i, true)
                if K.live(t[1]) ~= 2 then bad[#bad + 1] = t[1] .. " not ticked" end
                K.tick(sr, i, false)
                if K.live(t[1]) ~= 1 then bad[#bad + 1] = t[1] .. " not unticked" end
            end
        else bad[#bad + 1] = "screens: no row" end
        check(#bad == 0, "OP18: each merged row sets every option under it as clicks would (Read marks, Other mods' notes, Hidden facts, Button pictures, Wheels, Give back)", K.short(bad))
    end))
    -- OP19, OP20, OP21
    after(300, O(function(w)
        if keep.noPre then return end
        local rm = K.zrow(w, "readMarks")
        local el = K.opt("readNext") and K.opt("readNext").element
        if rm and el then
            K.pick(rm, 1)
            el.selected = 2
            if el.onChange then el.onChange(el.target, el) end
            check(rm.control.selected == 2 and w:isChanged(rm) == (keep.opt0.readNext ~= 2), "OP19: Next level alone, changed on the Mods page, shows on ZeD setup as another choice of the trio, its dot following",
                "the trio reads " .. tostring(rm.control.selected) .. ", dot " .. tostring(w:isChanged(rm)))
            K.pick(rm, 1)
        else check(false, "OP19: the Read marks row and Next level's control are there") end
        -- OP20 (design)
        local gr = K.zrow(w, "glyphs")
        local gel = K.opt("glyphDisplay") and K.opt("glyphDisplay").element
        if gr and gel then
            local reads = {}
            for _, v in ipairs({ 2, 3, 4, 5, 6, 7 }) do
                gel.selected = v
                reads[#reads + 1] = v .. ">" .. tostring(gr.control.selected)
            end
            gel.selected = 3
            K.pick(gr, 1)
            note("OP20: Button pictures reads (stored set > row): " .. table.concat(reads, " ") .. "; a press of Auto on a forced set leaves glyphDisplay " .. tostring(gel.selected) .. " (the forced set dropped)")
            gel.selected = K.val("glyphDisplay") or 1
        end
        -- OP21
        local sr = K.zrow(w, "screens")
        if sr then
            K.tick(sr, 2, true)
            check(K.live("screenBelt") == 2 and K.val("screenBelt") == keep.opt0.screenBelt, "OP21: a give-back tick waits for Apply (the control ticked, the stored value not)",
                "control " .. tostring(K.live("screenBelt")) .. ", stored " .. tostring(K.val("screenBelt")))
            K.tick(sr, 2, false)
            local taken = {}
            for _, t in ipairs(G.MERGED.screens.ticks) do
                local u = t[3] and ZeD.StepAside and ZeD.StepAside.underFor and ZeD.StepAside.underFor(t[3])
                if u then taken[#taken + 1] = u end
            end
            note("OP21: screens a mod took, named under the row: " .. ((#taken > 0) and K.short(taken) or "none here"))
        end
        skip("OP21: the screen handed to the game within half a second of Apply", "needs Apply and a game (a QA save)")
    end))
    X.discard("the preset and the merged rows")
    after(100, function() K.errCheck("the preset and the merged rows") end)
end
function X.lite()
    -- OP27 (design): Lite then Full before Apply; Lite, ZeD's own Apply (opts.apply), Full
    after(300, O(function(w)
        local pre, sty = K.zrow(w, "additionsPreset"), K.zrow(w, "lookStyle")
        if not (pre and sty) then keep.noLite = true; check(false, "OP27: ZeD setup has Preset and Style"); return end
        K.pick(pre, 2)
        K.pick(sty, 2)
        St.syncAdditionsPreset()
        keep.liteA = pre.control.selected
        K.pick(sty, 1)
        St.syncAdditionsPreset()
        check(keep.liteA == 1 and pre.control.selected == 2 and K.live("ammoBox") == 2, "OP27: Style Lite then Full before Apply puts the additions back",
            "under Lite the preset read " .. tostring(keep.liteA) .. ", back in Full " .. tostring(pre.control.selected))
        K.pick(sty, 2)
        local applied = false
        if K.val("additionsPreset") ~= 4 then applied = pcall(function() St.opts:apply() end) end
        K.pick(sty, 1)
        St.syncAdditionsPreset()
        if applied then
            note("OP27: Lite, then ZeD's own Apply step (opts.apply, which forgets what Lite kept), then Full: the additions read preset " .. tostring(pre.control.selected)
                .. ((pre.control.selected == 1) and " (left at Vanilla: all Off)" or ""))
        else
            note("OP27: the stored additions are Custom: ZeD's Apply step would write ZeD_custom_additions.txt, so the Lite, Apply, Full half is not staged")
        end
    end))
    X.discard("Lite and Full on the controls")
    -- OP26: Lite stored (as bx_menu sets it; put back at once)
    after(300, O(function(w)
        if keep.noLite then return end
        K.style(2)
    end))
    after(600, O(function(w)
        if keep.noLite then return end
        local rows = K.rowsOf(w, "zed")
        local heads, watch = {}, false
        for _, r in ipairs(rows) do
            if r.kind == "header" then heads[tostring(r.text)] = true end
            if K.optName(r) == "ZeD_UI.watchPlace" then watch = true end
        end
        local addT, chT = G.text("UI_ZeD_Options_ZedAdditions"), G.text("UI_ZeD_Options_ZedChords")
        local keepAdd = St.additionsOffVanilla and St.additionsOffVanilla() or false
        check(St.lite() and not heads[chT] and not watch and (heads[addT] and true or false) == keepAdd,
            "OP26: in Lite ZeD setup hides Quick actions and the Watch row, and Additions unless the stored additions are off Vanilla",
            "Lite " .. tostring(St.lite()) .. ", Additions shown " .. tostring(heads[addT] and true or false) .. " (stored off Vanilla " .. tostring(keepAdd) .. "), Quick actions " .. tostring(heads[chT] and true or false) .. ", Watch " .. tostring(watch))
        K.style(1)
    end))
    after(600, O(function(w)
        if keep.noLite then return end
        local heads = {}
        for _, r in ipairs(K.rowsOf(w, "zed")) do if r.kind == "header" then heads[tostring(r.text)] = true end end
        check(not St.lite() and heads[G.text("UI_ZeD_Options_ZedChords")] and heads[G.text("UI_ZeD_Options_ZedAdditions")] and true or false,
            "OP26: Full again shows Additions and Quick actions")
    end))
    X.discard("Lite stored and Full again")
    after(100, function() K.errCheck("Lite and Full") end)
end
function X.defaults()
    -- OP28, OP29
    after(300, O(function(w) K.toPage(w, "zed") end))
    after(300, O(function(w)
        local d = K.spec(w, "defaults")
        if not d then keep.noDef = true; check(false, "OP28: ZeD setup's band has Reset to defaults", K.btnIds(w)); return end
        check((d.disabled and true or false) == (not w:zedOffDefault()), "OP28: Reset to defaults is grey exactly when every ZeD option is at its start",
            "grey " .. tostring(d.disabled) .. ", something off its default " .. tostring(w:zedOffDefault()))
        local mg = K.zrow(w, "menuGuess")
        if mg then K.pick(mg, (mg.control.selected == 2) and 1 or 2) end
    end))
    after(300, O(function(w)
        if keep.noDef then return end
        local d = K.spec(w, "defaults")
        check(d ~= nil and not d.disabled, "OP28: with a ZeD option off its start, Reset to defaults is live")
        keep.defStyle = K.zrow(w, "lookStyle") and K.zrow(w, "lookStyle").control.selected
        keep.defBefore = "safeMode " .. tostring(K.live("safeMode")) .. ", inputModeLock " .. tostring(K.live("inputModeLock"))
        -- (the chords reset at once and would write ZeD_chords.txt: reset is counted here, not run)
        local Q = ZeD.QuickChords
        keep.resets = 0
        keep.qReset = Q.reset
        Q.reset = function() keep.resets = keep.resets + 1 end
        local why = K.press(w, "defaults")
        Q.reset = keep.qReset
        keep.qReset = nil
        check(why == nil, "OP28: Reset to defaults pressed", why)
    end))
    after(300, O(function(w)
        if keep.noDef then return end
        local bad = {}
        for _, r in ipairs(K.rowsOf(w, "zed")) do
            local c = r.control
            if r.zedDefault and not r.zedNoReset and c and not c.disabled and c.selected ~= r.zedDefault then bad[#bad + 1] = K.rname(r) .. " " .. tostring(c.selected) end
        end
        for _, o in ipairs(w:zedHiddenOpts()) do
            local el = o.element
            if el and o.zedDefault and not el.disabled and el.selected ~= o.zedDefault then bad[#bad + 1] = tostring(o.id) .. " (hidden) " .. tostring(el.selected) end
        end
        for _, t in ipairs(G.MERGED.screens.ticks) do if K.live(t[1]) ~= 1 then bad[#bad + 1] = t[1] .. " still given back" end end
        local sty = K.zrow(w, "lookStyle")
        if sty and sty.control.selected ~= keep.defStyle then bad[#bad + 1] = "Style moved" end
        local ts = K.zrow(w, "textSize")
        if ts and ts.control.selected ~= K.idx(St.sizeKeys, St.defaultSizeKey) then bad[#bad + 1] = "Text size " .. tostring(ts.control.selected) end
        local nCh = #((ZeD.QuickChords and ZeD.QuickChords.CHORDS) or {})
        if keep.resets ~= nCh then bad[#bad + 1] = "chords reset " .. tostring(keep.resets) .. " of " .. nCh end
        check(#bad == 0, "OP28: Reset to defaults puts every row, the hidden and debug options and the give-backs on their start, leaves Style, resets every chord at once, Text size to the screen's default",
            K.short(bad))
        note("OP29: one press of Reset to defaults also sets " .. keep.defBefore .. " to safeMode " .. tostring(K.live("safeMode")) .. ", inputModeLock " .. tostring(K.live("inputModeLock"))
            .. " and every give-back to ZeD's own (pending until Apply): a player who gave a screen back gets ZeD's again on the next Apply")
    end))
    after(300, O(function(w)
        if keep.noDef then return end
        local d = K.spec(w, "defaults")
        check(d ~= nil and d.disabled == true, "OP28: after the press Reset to defaults is grey")
    end))
    waitFor(function() return K.settled() end, 4000, function() end)
    X.discard("Reset to defaults")
    after(100, function() K.errCheck("Reset to defaults") end)
end
function X.looks()
    -- OP48: the live previews put back by Discard
    after(300, O(function(w)
        local th, ac, ts, sc = K.zrow(w, "baseTheme"), K.zrow(w, "accentColor"), K.zrow(w, "textSize"), K.zrow(w, "statusColors")
        local us, il, see = K.zrow(w, "uiScale"), K.zrow(w, "inputModeLock"), K.zrow(w, "seeThrough")
        if not (th and ac and ts and sc and us and il) then keep.noLook = true; check(false, "OP48: ZeD setup has the look rows"); return end
        K.pick(th, (th.control.selected == 1) and 2 or 1)
        K.pick(ac, (ac.control.selected == 1) and 2 or 1)
        K.pick(ts, (ts.control.selected == 1) and 2 or 1)
        K.pick(sc, (sc.control.selected == 1) and 2 or 1)
        if see and not K.dimmed(see) then K.pick(see, (see.control.selected == 1) and 2 or 1) end
        local step = nil
        for _, i in ipairs({ 4, 5, 3, 6 }) do if not step and i ~= us.control.selected and not St.scaleStepOff(us.control, i) then step = i end end
        if step then K.pick(us, step) end
        keep.lockPick = (il.control.selected == 2) and 1 or 2
        K.pick(il, keep.lockPick)
    end))
    waitFor(function() return keep.noLook or K.settled() end, 4000, O(function(w)
        if keep.noLook then return end
        local moved = ZeD.currentBase ~= keep.look0[1] and ZeD.currentAccent ~= keep.look0[2] and ZeD.currentSize ~= keep.look0[3] and ZeD.currentStatus ~= keep.status0
        check(moved, "OP48: the theme, accent, text size and status colors picked are on screen at once",
            tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize) .. " " .. tostring(ZeD.currentStatus))
        keep.lockMode = K.mode()
        if keep.lockPick == 2 then check(keep.lockMode == "kbm", "OP48: Playing with picked Mouse and keys locks the input at once", tostring(keep.lockMode)) end
    end))
    X.discard("the live previews")
    after(300, O(function(w)
        if keep.noLook then return end
        local L = keep.look0
        local bad = {}
        if ZeD.currentBase ~= L[1] or ZeD.currentAccent ~= L[2] or ZeD.currentSize ~= L[3] then bad[#bad + 1] = "look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize) end
        if ZeD.currentStatus ~= keep.status0 then bad[#bad + 1] = "status " .. tostring(ZeD.currentStatus) end
        if ZeD.surfaceAlpha ~= keep.alpha0 then bad[#bad + 1] = "see-through " .. tostring(ZeD.surfaceAlpha) end
        if ZeD.Scale.userScale ~= keep.scale0 then bad[#bad + 1] = "UI scale " .. tostring(ZeD.Scale.userScale) end
        if K.mode() ~= keep.mode0 then bad[#bad + 1] = "input " .. tostring(K.mode()) end
        check(#bad == 0, "OP48: Discard puts back the theme, accent, text size, see-through, status colors, UI scale and input lock", K.short(bad))
        K.onScreen("Options after Discard of the live previews", w)
        K.errCheck("the live previews")
    end))
end

-- =========================================================================================================
-- 5: the game's rows, the changed flag, the questions (OP32, OP43, OP45 to OP47, OP51)
function X.firstRow(w, names, kind)
    for _, n in ipairs(names) do
        local r = K.grow(w, n)
        if r and r.kind == kind and r.control and not r.moot then return r, n end
    end
    return nil, nil
end
function X.gameRows()
    after(300, O(function(w)
        local mo = K.mo()
        local bad, done = {}, {}
        -- a drop-down
        local r, n = X.firstRow(w, { "iso_cursor", "temperatureDisplay", "reticleMode", "aimTexture", "crosshairTexture" }, "combo")
        if r then
            local c = r.control
            local s0 = c.selected
            local dir = (s0 >= #(c.options or {})) and -1 or 1
            mo.gameOptions.changed = false
            w:nudge(r, dir)
            if c.selected == s0 or not K.changed() then bad[#bad + 1] = n .. " did not change" end
            w:nudge(r, -dir)
            if c.selected ~= s0 then bad[#bad + 1] = n .. " not back" end
            done[#done + 1] = n
        else bad[#bad + 1] = "no drop-down" end
        -- a tick box
        r, n = X.firstRow(w, { "showUsername", "autoDrink", "clock24hour", "showItemModInfo", "dropItemsOnSquareCenter", "autoWalkContainer" }, "tick")
        if r and r.control.enable ~= false then
            local c = r.control
            local v0 = c.selected[1] == true
            mo.gameOptions.changed = false
            w._tickCol = 1
            w:activateRow(r)
            if (c.selected[1] == true) == v0 or not K.changed() then bad[#bad + 1] = n .. " did not flip" end
            w:activateRow(r)
            if (c.selected[1] == true) ~= v0 then bad[#bad + 1] = n .. " not back" end
            keep.tickName = n
            done[#done + 1] = n
        else bad[#bad + 1] = "no tick box" end
        -- a volume
        r, n = X.firstRow(w, { "jumpscareVolume", "vehicleEngineVolume", "soundVolume" }, "volume")
        if r then
            local c = r.control
            local v0 = c.volume or 0
            local dir = (v0 >= 10) and -1 or 1
            mo.gameOptions.changed = false
            w:nudge(r, dir)
            if c.volume == v0 or not K.changed() then bad[#bad + 1] = n .. " did not change" end
            w:nudge(r, -dir)
            if c.volume ~= v0 then bad[#bad + 1] = n .. " not back" end
            done[#done + 1] = n
        else bad[#bad + 1] = "no volume" end
        -- a slider
        local sl = nil
        for _, p in ipairs(K.pages(w)) do
            if not p.setup and p.raw ~= "mods" and p.raw ~= "display" then
                for _, x in ipairs(K.rowsOf(w, p.raw)) do if not sl and x.kind == "slider" and x.control then sl = x end end
            end
        end
        if sl then
            local c = sl.control
            local v0 = c.currentValue
            mo.gameOptions.changed = false
            local dir = ((c.currentValue or 0) >= (c.maxValue or 1)) and -1 or 1
            w:nudge(sl, dir)
            if c.currentValue == v0 then bad[#bad + 1] = K.rname(sl) .. " did not move" end
            pcall(function() c:setCurrentValue(v0) end)
            done[#done + 1] = K.rname(sl)
        else note("OP32: no game slider found outside Display") end
        check(#bad == 0, "OP32: a game drop-down, tick box, volume and slider change as the game's own controls do, each setting the game's changed flag", table.concat(done, ", ") .. "; " .. K.short(bad))
        -- a mega volume (0 to 11)
        local mg = nil
        for _, x in ipairs(K.rowsOf(w, "audio")) do if not mg and x.kind == "volume" and x.control and x.control.Type == "ISMegaVolumeControl" then mg = x end end
        if mg then
            local c = mg.control
            local v0 = c.volume or 0
            for _ = 1, 13 do w:nudge(mg, 1) end
            local top = c.volume
            pcall(function() c:setVolume(v0) end)
            check(top == 11 and c.volume == v0, "OP32: a voice volume (the game's Mega control) runs to 11", K.rname(mg) .. " top " .. tostring(top))
        else note("OP32: no Mega volume control found (voice chat off here)") end
        note("OP32: the text field (a mod's) and the Advanced sound button are covered by OP36 and OP69; the button itself is not pressed")
    end))
    X.discard("the game's rows")
    -- OP45, OP46, OP47, OP43, OP51 on the tick box
    after(300, O(function(w)
        local r = keep.tickName and K.grow(w, keep.tickName)
        if not r then keep.noTick = true; skip("OP45 to OP47: a tick box flipped", "no game tick box found"); return end
        local _, p = K.grow(w, keep.tickName)
        K.toPage(w, p.raw)
        keep.tick0 = r.control.selected[1] == true
        w._tickCol = 1
        w:activateRow(r)
        w:activateRow(r)
    end))
    after(300, O(function(w)
        if keep.noTick then return end
        local r = K.grow(w, keep.tickName)
        local d, a = K.spec(w, "discard"), K.spec(w, "apply")
        check(not w:isChanged(r) and w:anyChanged() and d ~= nil and not d.disabled and a ~= nil and not a.disabled and #(w.titleStats or {}) > 0,
            "OP45: a change set back by hand clears its dot but the game's flag stays: Changed, Discard and Apply stay lit",
            "dot " .. tostring(w:isChanged(r)) .. ", flag " .. tostring(w:anyChanged()))
        K.try("OP46: Back with the flag on and no row changed", function() w:back() end)
    end))
    after(300, O(function(w)
        if keep.noTick then return end
        check(not (w.confirm == "back" and w:changedCount() == 0), "OP46: Back with no row changed does not ask to discard changes",
            "asks \"" .. ZeD.tr("UI_ZeD_Options_AskDiscardMany", 1) .. "\" with " .. w:changedCount() .. " rows changed (confirm " .. tostring(w.confirm) .. ")")
        if w.confirm then w:setConfirm(false) end
        local r = K.grow(w, keep.tickName)
        w._tickCol = 1
        w:activateRow(r)
        w.focusId = nil
        K.try("OP47: Back with a change", function() w:back() end)
    end))
    after(300, O(function(w)
        if keep.noTick then return end
        check(w.confirm == "back" and w.focusId == "confirm:apply" and K.spec(w, "confirm:no") ~= nil and K.spec(w, "confirm:yes") ~= nil and K.spec(w, "confirm:apply") ~= nil,
            "OP47: Back with changes asks Keep editing, Discard changes or Apply, the pad landing on Apply", tostring(w.confirm) .. " " .. tostring(w.focusId) .. " " .. K.btnIds(w))
        local rowsLive, pagesLive = 0, 0
        for _, h in ipairs(w._hits or {}) do
            local id = tostring(h.id)
            if id:find("^options:r%d+:") then rowsLive = rowsLive + 1 end
            if id:find("^options:page:%d+$") then pagesLive = pagesLive + 1 end
        end
        check(rowsLive == 0 and pagesLive == 0, "OP43: under Back's question the rows and pages take no click", rowsLive .. " row hit boxes and " .. pagesLive .. " page hit boxes live under the question")
        note("OP43: a change made under Back's question is discarded or applied with the count asked before it (no recount)")
        K.press(w, "confirm:no")
    end))
    after(300, O(function(w)
        if keep.noTick then return end
        check(not w.confirm, "OP47: Keep editing answers the question, nothing lost", tostring(w.confirm))
        local why = K.press(w, "discard")
        check(why == nil, "OP47: the footer's Discard pressed", why)
    end))
    after(300, O(function(w)
        if keep.noTick then return end
        check(w.confirm == "discard" and w.focusId == "confirm:no" and K.spec(w, "confirm:apply") == nil and K.spec(w, "confirm:yes") ~= nil,
            "OP47: the footer's Discard asks two answers, the pad landing on Keep editing", tostring(w.confirm) .. " " .. tostring(w.focusId) .. " " .. K.btnIds(w))
        w:setConfirm(false)
        w.focusId = nil
        w:joyX()
        check(w.confirm == "discard", "OP47: X asks the footer's Discard question", tostring(w.confirm))
        w:setConfirm(false)
        -- OP51: Return just after Enter in a field does not apply
        w._enterAt = MM.now()
        local took = w:keyOther(Keyboard.KEY_RETURN)
        check(took == true and w:anyChanged() and not w.confirm, "OP51: Return within 400 ms of Enter in a field does not apply", "taken " .. tostring(took) .. ", still changed " .. tostring(w:anyChanged()))
        w._enterAt = nil
        K.try("OP47: Back, then Discard changes", function() w:back() end)
    end))
    after(300, O(function(w)
        if keep.noTick then return end
        -- (Back's question's confirm:yes is Discard changes; checked before the press, never Apply)
        if w.confirm ~= "back" then check(false, "OP47: Back with a change asks again", tostring(w.confirm)); return end
        local why = K.press(w, "confirm:yes")
        check(why == nil, "OP47: Back's Discard changes pressed", why)
    end))
    waitFor(function() return keep.noTick or keep.noOpts or MM.view == "main" end, 3000, function(met)
        if keep.noTick or keep.noOpts then return end
        check(MM.view == "main", "OP47: Back's Discard changes closes the window", "view " .. tostring(MM.view))
        check(not K.changed(), "OP47: nothing is left waiting after Back's Discard")
    end)
    X.reopen("after Back's Discard")
    after(300, O(function(w)
        if not keep.noTick then
            local r = K.grow(w, keep.tickName)
            check(r and (r.control.selected[1] == true) == keep.tick0, "OP47: the tick box is back as it was", keep.tickName)
        end
        -- OP51 with nothing changed: Return and Y do nothing (pressed only while nothing waits: with a change either applies)
        if K.changed() or w.find:isFocused() or w.field:isFocused() then
            skip("OP51: Return and Y with nothing changed", "a change was waiting as Options opened again: not pressed (either would apply)")
        else
            local took = w:keyOther(Keyboard.KEY_RETURN)
            w:joyY()
            check(took == true and not w.confirm and not K.changed() and MM.view == "options", "OP51: with nothing changed Return and Y do nothing (the window stays, nothing applied)")
        end
        skip("OP51: Apply itself (the window kept, the dots cleared, the files written)", "never Apply: the game's apply re-sets the screen mode and sets the frame rate from its list")
        K.errCheck("the game's rows and the questions")
    end))
end

-- =========================================================================================================
-- 6: key binding (OP56, OP57, OP59 to OP61); Discard after
function X.keyPick()
    local avoid = { Aim = true, Run = true, Sprint = true, ManualFloorAtk = true }
    local e, other = nil, nil
    for _, v in ipairs(MainOptions.keyText or {}) do
        if not v.value and not v.isModBind and v.txt and v.btn and (v.keyCode or 0) > 0 then
            local n = tostring(v.txt:getName())
            if not avoid[n] then
                if not e then e = v elseif not other and v.keyCode ~= e.keyCode then other = v end
            end
        end
    end
    return e, other
end
function X.freeKey()
    for _, k in ipairs({ "KEY_F9", "KEY_F10", "KEY_F11", "KEY_SCROLL", "KEY_PAUSE", "KEY_NUMPAD7", "KEY_NUMPAD9", "KEY_INSERT" }) do
        local ok, c = pcall(function() return Keyboard[k] end)
        if ok and type(c) == "number" and c > 0 then
            local used = false
            for _, v in ipairs(MainOptions.keyText or {}) do if not v.value and v.keyCode == c then used = true end end
            if not used then return c end
        end
    end
    return nil
end
-- after a catcher's key: the duplicate question cancelled, or nothing
function X.keyBound(w, e, key, noMod)
    local ok = false
    if w.confirm == "dup" and w._dup then
        ok = w._dup.key == key and (not noMod or not w._dup.ctrl)
        w._dup = nil
        w:setConfirm(false)
    else
        ok = e.keyCode == key and (not noMod or not e.ctrl)
    end
    pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
    return ok
end
function X.keys()
    after(300, O(function(w)
        K.toPage(w, "controls")
        local e, other = X.keyPick()
        keep.kE, keep.kO, keep.kFree = e, other, X.freeKey()
        if not (e and other and keep.kFree) then keep.noKeys = true; skip("OP56 to OP61: key binding", "no key binding, second binding or free key found"); return end
        keep.k0 = { e.keyCode, e.shift, e.ctrl, e.alt }
        keep.kName = tostring(e.txt:getName())
        K.try("OP56: a key asked for", function() w:startCapture(e) end)
    end))
    after(300, O(function(w)
        if keep.noKeys then return end
        local e = keep.kE
        local name = tostring((e.txt.translation or e.txt.name or (e.txt.getName and e.txt:getName())) or "")
        check(w.confirm == "key" and w._keyEntry == e and name ~= "", "OP56: the band asks for the action's key by its name", keep.kName .. " \"" .. name .. "\" " .. tostring(w.confirm))
        -- OP61
        check(K.spec(w, w.focusId or "") ~= nil, "OP61: on the pad the key band's focus lands on one of its answers",
            "focus " .. tostring(w.focusId) .. "; the band has " .. K.btnIds(w))
        K.try("OP56: a free key with Shift", function() w:gotKey(keep.kFree, true, false, false) end)
        check(e.keyCode == keep.kFree and e.shift == true and not e.ctrl and not w.confirm and K.changed(), "OP56: the key binds with its one modifier, the game's flag set",
            tostring(e.keyCode) .. " shift " .. tostring(e.shift))
        pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
    end))
    after(250, O(function(w)
        if keep.noKeys then return end
        local e = keep.kE
        w:startCapture(e)
        K.try("OP56: Ctrl alone released", function() w.catcher:onKeyRelease(Keyboard.KEY_LCONTROL) end)
        check(X.keyBound(w, e, Keyboard.KEY_LCONTROL, true), "OP56: a modifier alone binds itself (no modifier with it)")
        note("OP56: Shift over Ctrl over Alt is read from the keyboard as the key comes up: not staged")
    end))
    after(250, O(function(w)
        if keep.noKeys then return end
        -- OP57
        local e = keep.kE
        w:startCapture(e)
        K.try("OP57: Escape released while asked", function() w.catcher:onKeyRelease(Keyboard.KEY_ESCAPE) end)
        local esc = X.keyBound(w, e, Keyboard.KEY_ESCAPE, false) and MM.view == "options"
        w:startCapture(e)
        K.try("OP57: Enter released while asked", function() w.catcher:onKeyRelease(Keyboard.KEY_RETURN) end)
        local ent = X.keyBound(w, e, Keyboard.KEY_RETURN, false) and MM.view == "options"
        check(esc and ent, "OP57: Escape and Enter while the band asks are bound like any key (the game's dialog the same; only Cancel and B leave)",
            "Escape " .. tostring(esc) .. ", Enter " .. tostring(ent))
    end))
    after(250, O(function(w)
        if keep.noKeys then return end
        -- OP59 (design)
        local e, o = keep.kE, keep.kO
        local before = e.keyCode
        w:startCapture(e)
        K.try("OP59: another action's key", function() w:gotKey(o.keyCode, o.shift, o.ctrl, o.alt) end)
    end))
    after(300, O(function(w)
        if keep.noKeys then return end
        local d = w._dup
        local nOthers = d and #(d.others or {}) or 0
        check(w.confirm == "dup" and d ~= nil, "OP59: a key already in use asks Cancel, Keep both or Take it", tostring(w.confirm) .. " " .. K.btnIds(w))
        note("OP59: the duplicate names only the first other action (" .. nOthers .. " share the key); Take it clears every other; the pad lands on " .. tostring(w.focusId)
            .. ((w.focusId == "confirm:yes") and " (Take it: one A clears another action's key)" or ""))
        local why = K.press(w, "confirm:no")
        if why then w._dup = nil; w:setConfirm(false) end
        check(not w.confirm, "OP59: Cancel leaves the duplicate unbound", why)
    end))
    after(250, O(function(w)
        if keep.noKeys then return end
        -- OP60
        local e = keep.kE
        local def = 0
        for _, v in ipairs(keyBinding or {}) do if v.value == keep.kName then def = v.key or 0 end end
        w:startCapture(e)
        K.try("OP60: Default", function() w:defaultKey() end)
        local ok = (def == 0 and e.keyCode == 0) or X.keyBound(w, e, def, false)
        check(ok, "OP60: Default takes the game's default key (through the same duplicate question)", keep.kName .. " default " .. tostring(def) .. ", now " .. tostring(e.keyCode))
        note("OP60: the game's own Default passes the key alone too (ISSetKeybindDialog onDefault), and the game's defaults carry no Shift or Ctrl; a mod bind's defaultKeyCode is not staged (no mod bind here)")
        pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
    end))
    X.discard("key binding")
    after(250, O(function(w)
        if keep.noKeys then return end
        local e, k = keep.kE, keep.k0
        -- (Discard reads the keys file again: the entry may be a fresh one)
        local now = nil
        for _, v in ipairs(MainOptions.keyText or {}) do if not v.value and v.txt and tostring(v.txt:getName()) == keep.kName then now = v end end
        now = now or e
        check(now.keyCode == k[1] and K.same01(now.shift, k[2]) and K.same01(now.ctrl, k[3]) and K.same01(now.alt, k[4]), "OP56: Discard puts the key back as the file has it",
            keep.kName .. " " .. tostring(now.keyCode) .. " (was " .. tostring(k[1]) .. ")")
        check(K.same(K.readLines("keysB42.ini"), keep.keys0), "OP56: keysB42.ini unchanged (line for line)")
        pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
        K.errCheck("key binding")
    end))
end

-- OP49: a mod's key bind changed, then the window's Discard (only with a mod that has one; set back by hand after)
function X.modKey()
    after(250, O(function(w)
        local r = keep.modKey
        if not r then return end
        local e = r.entry
        local free = X.freeKey()
        if not free then keep.modKey = nil; skip("OP49: a mod's key bind changed then discarded", "no free key found"); return end
        keep.mk0 = { e.keyCode, e.shift, e.ctrl, e.alt }
        K.try("OP49: a mod's key bind asked for", function() w:startCapture(e) end)
        K.try("OP49: a free key", function() w:gotKey(free, false, false, false) end)
        if w.confirm == "dup" then w._dup = nil; w:setConfirm(false) end
        keep.mkMoved = e.keyCode
        K.try("OP49: Discard", function() w:discardStay() end)
    end))
    after(400, O(function(w)
        local r = keep.modKey
        if not (r and keep.mk0) then return end
        local e, k = r.entry, keep.mk0
        local kept = e.keyCode
        check(kept == k[1], "OP49: a mod's key bind changed then discarded is back on its old key",
            K.rname(r) .. ": set to " .. tostring(keep.mkMoved) .. ", after Discard " .. tostring(kept) .. " (was " .. tostring(k[1]) .. "): the next Apply would save it")
        e.keyCode, e.shift, e.ctrl, e.alt = k[1], k[2], k[3], k[4]
        pcall(function() e.btn:setTitle(MainOptions.getKeyPrefix(e) .. getKeyName(e.keyCode or 0)) end)
        pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
        K.errCheck("a mod's key bind")
    end))
end

-- =========================================================================================================
-- 7: Find (OP8, OP52 to OP55)
function X.countLabel(w, key)
    local n, setupOnly = 0, true
    for _, r in ipairs(K.found(w)) do
        if r.labelKey == key then n = n + 1; if not r.setupCopy then setupOnly = false end end
    end
    return n, setupOnly
end
function X.find()
    after(300, O(function(w) K.toPage(w, "zed"); w.find:setText("key") end))
    after(400, O(function(w)
        local f = K.found(w)
        local keys, all = 0, 0
        for _, r in ipairs(f) do if r.kind == "key" then keys = keys + 1 end end
        for _, r in ipairs(K.rowsOf(w, "controls")) do if r.kind == "key" then all = all + 1 end end
        keep.f52 = { #f, keys, all }
        w.find:setText("the")
    end))
    after(400, O(function(w)
        local f = K.found(w)
        local total = 0
        for _, p in ipairs(K.pages(w)) do
            for _, r in ipairs(K.rowsOf(w, p.raw)) do if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then total = total + 1 end end
        end
        local a = keep.f52 or { 0, 0, 0 }
        note("OP52: Find reads the help too: \"key\" finds " .. a[1] .. " rows, " .. a[2] .. " of the " .. a[3] .. " key bindings (their help says to click the key); \"the\" finds "
            .. #f .. " of the " .. total .. " rows (both pages' copies counted once each)")
        keep.q53 = string.lower(ZeD.tr("UI_ZeD_Settings_UiScale"))
        w.find:setText(keep.q53)
    end))
    after(400, O(function(w)
        local n, onSetup = X.countLabel(w, "UI_ZeD_Settings_UiScale")
        check(n == 1 and onSetup, "OP53: Find shows a ZeD option once, on ZeD setup", n .. " found (\"" .. keep.q53 .. "\"), on ZeD setup " .. tostring(onSetup))
        check(K.spec(w, "defaults") == nil, "OP55: Reset to defaults is hidden while Find has words", K.btnIds(w))
        w.find:setText(string.upper(keep.q53))
    end))
    after(400, O(function(w)
        local n = X.countLabel(w, "UI_ZeD_Settings_UiScale")
        check(n == 1, "OP53: Find in capitals finds the same row", n .. " found")
        note("OP53: section titles and current values are not searched (code read); a word with an accent typed in DE or FR needs a launch in that language")
        local only = tostring(G.text(G.ONLY.tooltipFont[2]) or "")
        keep.q8 = string.lower(string.sub(only, 1, 24))
        w.find:setText(keep.q8)
    end))
    after(400, O(function(w)
        local hit = false
        for _, r in ipairs(K.found(w)) do if K.optName(r) == "tooltipFont" then hit = true end end
        check(keep.q8 ~= "" and hit, "OP8: Tooltip font's help carries its note (Find on the note's words finds the row)", "\"" .. tostring(keep.q8) .. "\"")
        w.find:setText("qqzzxjqvw")
    end))
    after(400, O(function(w)
        check(#K.found(w) == 0 and ZeD.tr("UI_ZeD_Options_NoMatch") ~= "UI_ZeD_Options_NoMatch", "OP55: Find with no match lists no row and says so", #K.found(w) .. " rows")
        local h = K.hit(w, "options:page:2")
        if h and h.fn then pcall(h.fn) end
        check(h ~= nil and w.find:getInternalText() == "" and w.pageIdx == 2, "OP55: a page click clears Find and shows that page",
            "find \"" .. tostring(w.find:getInternalText()) .. "\", page " .. tostring(w.pageIdx))
        w.find:setText("scale")
        w:joyBumper(1)
        check(w.find:getInternalText() == "" and w.pageIdx == 3, "OP55: a bumper clears Find", "page " .. tostring(w.pageIdx))
        K.toPage(w, "zed")
        keep.frAt = getTimestampMs(); keep.fr = 0
    end))
    waitFor(function() keep.fr = (keep.fr or 0) + 1; return getTimestampMs() - (keep.frAt or 0) >= 1500 end, 4000, O(function(w)
        keep.frA = keep.fr
        w.find:setText("e")
        keep.frAt = getTimestampMs(); keep.fr = 0
    end))
    waitFor(function() keep.fr = (keep.fr or 0) + 1; return getTimestampMs() - (keep.frAt or 0) >= 1500 end, 4000, O(function(w)
        local a, b = keep.frA or 0, keep.fr or 0
        check(b * 2 >= a, "OP54: one letter in Find keeps at least half the frames", a .. " frames in 1.5 s with Find empty, " .. b .. " with \"e\" (" .. #K.found(w) .. " rows found)")
        w.find:setText("")
        K.errCheck("Find")
    end))
end

-- =========================================================================================================
-- 8: the restart band (OP38), the sub-pages (OP44, OP65, OP68 to OP70)
function X.bands()
    after(300, O(function(w)
        K.toPage(w, "graphics")
        K.try("OP38: the restart band raised as Apply raises it", function() w:askRestart(false) end)
    end))
    after(300, O(function(w)
        check(w.confirm == "restart" and K.spec(w, "confirm:yes") ~= nil and K.spec(w, "back") == nil and K.spec(w, "apply") == nil,
            "OP38: the restart band has its OK only", tostring(w.confirm) .. " " .. K.btnIds(w))
        w:setConfirm(false)
        skip("OP38: Apply of a restart option (texcompress), then put back", "never Apply on the game's pages")
    end))
end
function X.subs()
    after(300, O(function(w)
        K.toPage(w, "controls")
        keep.spRow = nil
        for _, x in ipairs(K.rowsOf(w, "controls")) do if x.kind == "special" and not keep.spRow then keep.spRow = x end end
        if not keep.spRow then skip("OP65: Open controller setup", "no Button map and test row on Controls") end
    end))
    after(300, O(function(w)
        if not keep.spRow then return end
        keep.sc1 = w.scroll
        w.focusId = "orow:2"
        keep.fo1 = w.focusId
        local hp = ZeD.tr("UI_ZeD_Options_HelpPadMap")
        check(hp ~= "UI_ZeD_Options_HelpPadMap" and hp ~= "", "OP65: the row's help names its job", hp)
        K.try("OP65: Open controller setup", function() w:activateRow(keep.spRow) end)
    end))
    after(500, O(function(w)
        if not keep.spRow then return end
        check(w.sub == "pad", "OP65: Open controller setup opens the button map", tostring(w.sub))
        -- OP68: a label's pull-down lists every action
        local part = nil
        for _, p in ipairs(MM.PAD_PARTS or {}) do if p.id == "A" then part = p end end
        local n, want = 0, 0
        pcall(function() for _ in ipairs(CharacterJoypadButtonBinding.allBindings()) do want = want + 1 end end)
        if part then
            K.try("OP68: the A label's pull-down", function()
                w:openPadPart(part, { x = w:getAbsoluteX() + 100, y = w:getAbsoluteY() + 100, w = 120, h = 30 })
                for _, it in ipairs((MM.popup and MM.popup.items) or {}) do if type(it) == "table" and it.fn then n = n + 1 end end
            end)
            MM.ctx.open = nil
            check(want > 0 and n == want, "OP68: a label's pull-down lists every action", n .. " of " .. want)
        end
        -- OP44: a restart question raised while the button map shows
        K.try("OP44: the restart question raised on the button map", function() w:askRestart(false) end)
    end))
    after(300, O(function(w)
        if not keep.spRow then return end
        check(not (w.confirm == "restart" and K.spec(w, "confirm:yes") == nil), "OP44: a question raised on the button map shows there",
            "confirm " .. tostring(w.confirm) .. " but the band draws " .. K.btnIds(w) .. ": nothing shows until Back")
        w:setConfirm(false)
        K.try("OP65: B on the button map", function() w:joyB() end)
        check(w.sub == nil and w.scroll == keep.sc1 and w.focusId == keep.fo1, "OP65: B on the button map comes back to the same scroll and row",
            "sub " .. tostring(w.sub) .. ", scroll " .. tostring(w.scroll) .. " (was " .. tostring(keep.sc1) .. "), focus " .. tostring(w.focusId))
        w:activateRow(keep.spRow)
    end))
    after(400, O(function(w)
        if not keep.spRow then return end
        K.try("OP65: Escape on the button map", function() w:keyEscape() end)
        check(w.sub == nil and MM.view == "options", "OP65: Escape on the button map comes back to Options", tostring(w.sub))
        w:activateRow(keep.spRow)
    end))
    after(400, O(function(w)
        if not keep.spRow then return end
        local why = K.press(w, "back")
        check(why == nil and w.sub == nil, "OP65: the band's Back on the button map comes back", why)
        JoypadState.controllerTest = nil
    end))
    -- the sounds page
    after(300, O(function(w)
        keep.sndAdv = false
        pcall(function() keep.sndAdv = SystemDisabler.getEnableAdvancedSoundOptions() end)
        K.try("OP69: the sounds page", function() w:openSub("sounds") end)
    end))
    after(500, O(function(w)
        local cats = MM.soundCategories() or {}
        if #cats == 0 then
            skip("OP69/OP70: the sounds page", "the game lists no sound categories here")
            pcall(function() w:closeSub() end)
            return
        end
        local drawn = 0
        for _, h in ipairs(w._hits or {}) do if tostring(h.id):find("^options:cat:%d+$") then drawn = drawn + 1 end end
        check(w.sub == "sounds" and drawn == #cats, "OP69: every sound category is drawn in its box",
            drawn .. " of " .. #cats .. " drawn (no scroll: the rest can be neither seen nor clicked); the game offers the Advanced button: " .. tostring(keep.sndAdv))
        local rows = MM.soundsIn(cats[w.sndCat or 1] and cats[w.sndCat or 1].id)
        local bad = {}
        for _, r in ipairs(rows) do
            local v = -1
            pcall(function() v = r.snd:getUserVolume() end)
            if v < 0 or v > 2.0001 then bad[#bad + 1] = tostring(r.name) .. " " .. tostring(v) end
        end
        local ids = K.btnIds(w)
        check(#bad == 0 and ids == "back", "OP70: the sounds page reads each volume from 0 to 200 percent and its band is Back alone (no Reload)",
            #rows .. " sounds; band " .. ids .. " " .. K.short(bad))
        if #cats >= 2 then
            local c0 = w.sndCat
            w:joyBumper(1)
            check(w.sndCat ~= c0, "OP69: RB walks the sound categories", tostring(c0) .. " to " .. tostring(w.sndCat))
            w:joyBumper(-1)
        end
        note("OP70: no volume changed and no Play pressed (sounds.ini lies outside Lua's reach to put back, and Play stops the menu music)")
    end))
    after(300, O(function(w)
        K.try("OP69: the sounds page shut", function() w:closeSub() end)
        check(w.sub == nil, "OP69: the sounds page shuts", tostring(w.sub))
        K.errCheck("the sub-pages")
    end))
end
-- Options left (Back with nothing waiting)
function X.leave()
    after(300, O(function(w)
        if w.confirm then w:setConfirm(false) end
        if K.changed() then note("Options had a change waiting before it was left: Discard"); pcall(function() w:discardStay() end) end
        K.try("Options: Back", function() w:back() end)
    end))
    waitFor(function() return keep.noOpts or MM.view == "main" end, 3000, function(met)
        if keep.noOpts then K.rescue(); return end
        if not check(MM.view == "main", "Options: Back leaves to the main window", "view " .. tostring(MM.view)) then K.rescue() end
    end)
end

-- =========================================================================================================
-- 9: the welcome (OP71 to OP79)
function X.welcome()
    after(300, function()
        keep.wSnap = K.snapAll()
        K.try("OP71: the welcome opened (MM.openWelcome)", MM.openWelcome)
    end)
    waitFor(function() return K.up("welcome") end, 4000, function(met)
        if not check(met, "OP71: MM.openWelcome puts the welcome up", "view " .. tostring(MM.view)) then keep.noWel = true; K.rescue() end
    end)
    after(400, WE(function(w)
        K.onScreen("OP78: the welcome", w)
        note("OP71: ZeD_setup_seen.txt " .. (keep.seen0 and ("is here (\"" .. tostring(keep.seen0[1]) .. "\")") or "is not here") .. ", QA autoload " .. tostring(ZeD.QAAutoload)
            .. ": the welcome opens by itself only without the seen file, never on a QA autoload, on the main view 120 ticks in; a seen file from before beta 21 means an upgrader never sees it")
        -- OP74
        local wanted = WL.tutorialWanted()
        local tutWord = keep.tut0 and ("holds \"" .. tostring(keep.tut0[1]) .. "\"") or "is not there"
        if keep.seen0 then
            check(not (w.tutorial == 1 and not wanted), "OP74: reopened, Tutorial starts on the answer given (not Show me around after No thanks or a tour done)",
                "Tutorial starts on " .. tostring(w.tutorial) .. " (1 Show me around); ZeD_tutorial.txt " .. tutWord .. ": Accept would write \"1\" and arm the tour again")
        else
            note("OP74: the setup was never answered on this machine (no seen file): Tutorial starts on " .. tostring(w.tutorial) .. ", ZeD_tutorial.txt " .. tutWord)
        end
        w.way = 1
    end))
    -- OP78: the layout
    after(300, WE(function(w)
        local T = ZeD.T
        local pad = T.px(MM.U.STACK_PAD)
        local prevW = math.floor((w.width - pad * 2) * 0.34)
        local prevX = w:getAbsoluteX() + w.width - pad - prevW
        local into, longLab = {}, {}
        for _, row in ipairs(WL.ROWS) do
            local right = 0
            for _, h in ipairs(w._hits or {}) do
                if tostring(h.id):find("^welcome:opt:" .. row.key .. ":") then right = math.max(right, h.x + h.w) end
            end
            if right > prevX then into[#into + 1] = row.key .. " by " .. math.floor(right - prevX) .. " px" end
            if MM.textW(T.fontF2, ZeD.tr(row.label)) > T.px(120) - T.px(4) then longLab[#longLab + 1] = row.key end
        end
        check(#into == 0, "OP78: the welcome's choices stay clear of the preview (text size " .. tostring(ZeD.currentSize) .. ", " .. K.lang() .. ")", K.short(into))
        check(#longLab == 0, "OP78: every choice's name fits the 120-unit label column", K.short(longLab))
        local bandTop = w:getAbsoluteY() + w.height - w:footerHeight() - MM.bandH()
        local low = 0
        for _, h in ipairs(w._hits or {}) do if tostring(h.id):find("^welcome:opt:") then low = math.max(low, h.y + h.h) end end
        check(low > 0 and low <= bandTop + 1, "OP78: every choice sits above the band (the window is capped to the desk with no scroll)",
            "the lowest choice ends at " .. math.floor(low) .. ", the band starts at " .. math.floor(bandTop))
        note("OP78: Large text, DE and the test language are the cases the map names; this run reads the size and language found")
        w.way = 2
    end))
    -- OP77: Save setup grey unless Pick your own
    after(300, WE(function(w)
        local s2 = K.spec(w, "save")
        keep.save2 = s2 and s2.disabled
        w.way = 3
    end))
    after(300, WE(function(w)
        local s3 = K.spec(w, "save")
        local s3d = s3 and s3.disabled
        w.way = 1
        keep.save3 = s3d
    end))
    after(300, WE(function(w)
        local s1 = K.spec(w, "save")
        check(keep.save2 == true and keep.save3 == true and s1 ~= nil and not s1.disabled, "OP77: Save setup is grey unless Pick your own",
            "Load " .. tostring(keep.save2) .. ", Skip " .. tostring(keep.save3) .. ", Pick " .. tostring(s1 and s1.disabled))
        -- OP72: a pick sets the stored option at once
        keep.wBase0, keep.wTheme0 = ZeD.currentBase, K.val("baseTheme")
        local thOther = (ZeD.currentBase ~= "light") and 2 or 1
        local why = K.press(w, "opt:theme:" .. thOther)
        check(why == nil and K.val("baseTheme") ~= keep.wTheme0 and ZeD.currentBase ~= keep.wBase0, "OP72: a welcome pick sets the stored option at once and the desk changes",
            tostring(why) .. "; theme " .. tostring(keep.wTheme0) .. " to " .. tostring(K.val("baseTheme")) .. ", on screen " .. tostring(ZeD.currentBase))
        -- OP73
        keep.lock0, keep.gly0 = K.val("inputModeLock"), K.val("glyphDisplay")
        local inOther = (w.input == 2) and 1 or 2
        K.press(w, "opt:input:" .. inOther)
        note("OP73: Playing with picked " .. inOther .. " is the window's own answer (" .. tostring(w.input) .. "): Playing with in ZeD setup stays " .. tostring(K.val("inputModeLock"))
            .. " (was " .. tostring(keep.lock0) .. "), Button pictures " .. tostring(K.val("glyphDisplay")) .. " (was " .. tostring(keep.gly0) .. "); it picks the tour's words alone")
    end))
    -- OP79: Lite then Full in the welcome, on a player with Vanilla Plus additions (staged, put back below)
    after(300, WE(function(w)
        for id, v in pairs((St.ADDITION_PRESETS and St.ADDITION_PRESETS[2]) or {}) do
            local o = K.opt(id)
            if o and o.setValue then pcall(o.setValue, o, v) end
        end
        K.press(w, "opt:style:2")
    end))
    after(500, WE(function(w)
        keep.wLite = St.lite()
        K.press(w, "opt:style:1")
    end))
    after(500, WE(function(w)
        local a = K.val("ammoBox")
        note("OP79: in the welcome Style Lite (read " .. tostring(keep.wLite) .. ") then Full on a player with Vanilla Plus additions: ammoBox " .. tostring(a) .. ", readMarks " .. tostring(K.val("readMarks"))
            .. ((a == 1) and " (left at Vanilla: nothing kept them; only Skip brings them back)" or " (put back)"))
        K.onScreen("the welcome after the picks", w)
        K.errCheck("the welcome's picks")
    end))
    -- OP72: B (Skip) only when the seen file was there before (Skip writes it; Lua cannot delete it)
    after(300, WE(function(w)
        if keep.seen0 == nil then
            keep.noSkip = true
            skip("OP72: B (Skip) on the welcome throws every pick away", "ZeD_setup_seen.txt was not there before and Skip would make it: the options put back by hand")
            K.setAll(keep.wSnap)
            pcall(function() St.applyThemeNow() end)
            MM.showView("main")
            return
        end
        K.try("OP72: B on the welcome", function() w:joyB() end)
    end))
    waitFor(function() return keep.noWel or MM.view == "main" end, 4000, function(met)
        if keep.noWel then return end
        local d = K.diff(keep.wSnap, K.snapAll())
        if keep.noSkip then
            check(#d == 0, "Welcome: left by hand, every option as the window found it", K.short(d))
            check(K.readLines(keep.seenF) == nil, "Welcome: ZeD_setup_seen.txt was not made")
            return
        end
        if not check(MM.view == "main", "OP72: B leaves the welcome to the main window", "view " .. tostring(MM.view)) then K.rescue() end
        check(#d == 0, "OP72: B throws every pick away (every option as the window found it)", K.short(d))
        note("OP72: B, the pad's usual way back, is Skip: every pick thrown away and ZeD_setup_seen.txt written (seen " .. tostring(WL.seen()) .. "); the close box keeps the picks")
    end)
    after(200, function() K.errCheck("the welcome") end)
end

-- =========================================================================================================
-- 10: the setup file (OP75 to OP77)
function X.setupFile()
    after(300, function()
        if MM.view ~= "main" then K.rescue() end
        local f = keep.tfile
        -- OP77
        local ok = St.saveSetup(f)
        local lines = K.readLines(f) or {}
        local have = {}
        for _, l in ipairs(lines) do local id = l:match("^([%w_]+)=") ; if id then have[id] = true end end
        local miss = {}
        for id in pairs(keep.opt0 or {}) do if not have[id] then miss[#miss + 1] = id end end
        for _, id in ipairs(G.RETIRED or {}) do if not have[id] then miss[#miss + 1] = id .. " (retired)" end end
        local saved = ZeD.tr("UI_ZeD_Welcome_Saved", f)
        check(ok and #miss == 0 and saved ~= "UI_ZeD_Welcome_Saved", "OP77: Save setup writes every ZeD option, the retired ones too, and says where",
            K.count(have) .. " lines in " .. f .. "; missing " .. K.short(miss) .. "; \"" .. saved .. "\"")
        -- OP75: three lines staged
        local us = K.val("uiScale") or 1
        local step = nil
        for _, i in ipairs({ 4, 5, 3, 6 }) do if not step and i ~= us and not St.scaleStepOff(St.uiScaleOption, i) then step = i end end
        local acc = ((K.val("accentColor") or 1) == 1) and 2 or 1
        local lock = ((K.val("inputModeLock") or 1) == 1) and 2 or 1
        keep.l75 = { step = step or us, acc = acc, lock = lock, scale = ZeD.Scale.userScale, mode = K.mode() }
        K.writeLines(f, { "ZeD-GUI setup; <option id>=<item>", "uiScale=" .. tostring(step or us), "accentColor=" .. acc, "inputModeLock=" .. lock })
        local n = St.loadSetup(f)
        local L = keep.l75
        check(n == 3 and K.val("uiScale") == L.step and K.val("accentColor") == acc and K.val("inputModeLock") == lock, "OP75: Load a setup takes every valid line",
            tostring(n) .. " taken")
        check(ZeD.currentAccent == St.accentKeys[acc], "OP75: Load a setup puts the theme and accent on screen at once", tostring(ZeD.currentAccent))
        check(ZeD.Scale.userScale ~= L.scale or step == nil, "OP75: Load a setup re-applies the UI scale it takes",
            "stored step " .. tostring(K.val("uiScale")) .. " but the scale on screen is still " .. tostring(ZeD.Scale.userScale) .. "; Playing with stored " .. tostring(K.val("inputModeLock"))
            .. ", the input still " .. tostring(K.mode()) .. ": both wait for the next menu or game start")
        note("OP75: Load takes any ZeD option a line names, Safe mode, Test language and the give-backs included (code read; not staged: Safe mode would hand the desk back at once)")
        -- put back at once
        K.setAll(keep.opt0)
        pcall(function() St.applyThemeNow() end)
        pcall(function() St.applyScale() end)
        pcall(function() if keep.l75.mode ~= K.mode() then ZeD.Input.Detector.setLockedMode(nil) end end)
        -- OP76: a file with no valid line
        K.writeLines(f, { "not a setup", "uiScale=99", "baseTheme=abc", "notAnOption=2", "=", "" })
        local n0 = St.loadSetup(f)
        local d = K.diff(keep.opt0, K.snapAll())
        check(#d == 0, "OP76: a file with no valid line changes no option", K.short(d))
        check(n0 == nil, "OP76: a setup file with no valid line is refused, not taken as loaded",
            "loadSetup gave " .. tostring(n0) .. ": the welcome's Load counts that as done and closes with nothing changed and no note")
        -- the file as found (or the test file emptied)
        if keep.tfile0 then K.writeLines(f, keep.tfile0, "\n") else K.writeLines(f, {}) end
    end)
    waitFor(function() return K.settled() end, 4000, function()
        check(ZeD.Scale.userScale == keep.scale0 and ZeD.currentAccent == keep.look0[2], "OP75: the staged values put back (UI scale and accent as found)",
            tostring(ZeD.Scale.userScale) .. " " .. tostring(ZeD.currentAccent))
        K.errCheck("the setup file")
    end)
end

-- =========================================================================================================
-- the checks the map marks by hand or in game
function X.notHere()
    after(100, function()
        local H = "by hand (the map marks it [H])"
        skip("OP2: Options pressed while the desk fades in", H)
        skip("OP22: Safe mode On, Apply at the menu, Off again from the game's Mods page", H .. "; Safe mode is never set here")
        skip("OP34: a tick row with several boxes walked on the pad", H .. ", a controller")
        skip("OP35: the dead zone stepper", H .. ", a test controller picked")
        skip("OP39: a reset-Lua option applied at the menu", H .. "; it resets Lua and would end the script")
        skip("OP40: Pause on focus loss and Map view pause asking to keep screen settings", "in game with Keep only (the map marks it [G]); never set here")
        skip("OP41: the screen-settings band's count, B, Escape and Back", H .. "; it needs a display change")
        skip("OP42: the mouse on the rows while Keep these screen settings is up", H .. "; it needs a display change")
        skip("OP50: button map edits not undone by Discard", H .. ", a controller")
        skip("OP58: a click off the band's buttons binds that mouse button", H .. ", the real pointer")
        skip("OP62: a key band left up when the pause menu goes down", "in game only (the map marks it [G])")
        skip("OP64: a key set in the keyboard map shows in Options", "in game only (the map marks it [G])")
        skip("OP66: a test controller picked on the button map", H .. ", a controller")
        skip("OP67: a label's pull-down edit on a built-in preset", H .. ", a controller")
    end)
end

-- =========================================================================================================
-- put back
function X.putBack()
    after(300, function()
        -- (each part on its own, so one that throws does not stop the ones after it)
        pcall(function() local Q = ZeD.QuickChords; if keep.qReset then Q.reset = keep.qReset; keep.qReset = nil end end)
        pcall(function()
            local w = K.W()
            if w then
                if w.sub then pcall(function() w:closeSub() end) end
                w._palette = nil
                if w.confirm then pcall(w.setConfirm, w, false) end
                if w.anyChanged and w:anyChanged() then note("put back: Options had a change waiting (never applied): Discard") end
                -- (always: a control changed with the game's flag cleared by a part would not show as a change)
                w:discardStay()
                pcall(function() w.find:setText("") end)
            end
        end)
        pcall(function() local wl = K.win("welcome"); if wl and wl.confirm and wl.setConfirm then wl:setConfirm(false) end end)
        pcall(K.rescue)
        pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
        pcall(function() JoypadState.controllerTest = nil end)
        MM.forceGamepad = keep.pad0
        if keep.opt0 then
            pcall(K.setAll, keep.opt0)
            pcall(function() St.applyScale() end)
            pcall(function() St.applyThemeNow() end)
        end
        pcall(function() if K.mode() ~= keep.mode0 and (K.val("inputModeLock") or 1) == 1 then ZeD.Input.Detector.setLockedMode(nil) end end)
    end)
    after(1200, function()
        -- (ZeD's own saves are done: the files as found. The seen and tutorial files are one word, no line end.)
        if keep.ini0 then K.writeLines("ModOptions.ini", keep.ini0, "\r\n") end
        if keep.tut0 then K.writeLines(keep.tutF, keep.tut0) end
        if keep.seen0 then K.writeLines(keep.seenF, keep.seen0) end
        if keep.custom0 and not K.same(K.readLines("ZeD_custom_additions.txt"), keep.custom0) then K.writeLines("ZeD_custom_additions.txt", keep.custom0, "\n") end
        if keep.tfile and not K.same(K.readLines(keep.tfile), keep.tfile0) then
            if keep.tfile0 then K.writeLines(keep.tfile, keep.tfile0, "\n") else K.writeLines(keep.tfile, {}) end
        end
        if keep.keys0 and not K.same(K.readLines("keysB42.ini"), keep.keys0) then
            keep.keysMoved = true
            K.writeLines("keysB42.ini", keep.keys0, "\r\n")
            pcall(function() MainOptions.loadKeys() end)
        end
    end)
    waitFor(function() return K.settled() end, 4000, function()
        local d = K.diff(keep.opt0, K.snapAll())
        check(keep.opt0 ~= nil and #d == 0, "put back: every ZeD option as found (" .. K.count(keep.opt0) .. " options)", K.short(d))
        local L = keep.look0 or {}
        check(ZeD.currentBase == L[1] and ZeD.currentAccent == L[2] and ZeD.currentSize == L[3] and ZeD.currentStatus == keep.status0, "put back: the theme, accent, text size and status colors on screen as found",
            tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize) .. " " .. tostring(ZeD.currentStatus))
        check(ZeD.Scale.userScale == keep.scale0 and St.lite() == keep.lite0, "put back: the UI scale step and Style as found",
            tostring(ZeD.Scale.userScale) .. ", Lite " .. tostring(St.lite()))
        check(#K.controlsOff() == 0, "put back: every ZeD control on the Options window reads its stored value", K.short(K.controlsOff()))
        check(K.mode() == keep.mode0, "put back: the input mode as found", tostring(K.mode()) .. " (was " .. tostring(keep.mode0) .. ")")
        check(keep.ini0 ~= nil and K.same(K.readLines("ModOptions.ini"), keep.ini0), "put back: ModOptions.ini line for line")
        check(not keep.keysMoved and K.same(K.readLines("keysB42.ini"), keep.keys0), "put back: keysB42.ini line for line",
            keep.keysMoved and "a key was written during the run: the file was written back as found" or nil)
        local files = { { keep.tutF, keep.tut0 }, { keep.seenF, keep.seen0 } }
        for _, f in ipairs(files) do
            local now = K.readLines(f[1])
            if f[2] then check(K.same(now, f[2]), "put back: " .. f[1] .. " line for line")
            elseif now == nil then check(true, "put back: " .. f[1] .. " was not there and is not there")
            elseif f[1] == keep.seenF then
                check(false, "put back: " .. f[1] .. " was not there before and is there now", "delete Zomboid/Lua/" .. f[1] .. " by hand, or the next launch will not offer the setup")
            else
                note("put back: " .. f[1] .. " was not there before and now holds \"" .. tostring(now[1]) .. "\" (the same as no file: no tour asked for)")
            end
        end
        check(K.same(K.readLines(keep.setupF), keep.setup0), "put back: " .. keep.setupF .. " as found")
        if keep.tfile ~= keep.setupF then
            local t = K.readLines(keep.tfile)
            if keep.tfile0 == nil and t ~= nil then note("put back: Zomboid/Lua/" .. keep.tfile .. " was made for OP75 to OP77 and is left empty (" .. #t .. " lines): Lua cannot delete it") end
        end
        check(K.same(K.readLines("ZeD_custom_additions.txt"), keep.custom0), "put back: ZeD_custom_additions.txt as found")
        check(K.same(K.readLines("ZeD_chords.txt"), keep.chords0), "put back: ZeD_chords.txt as found (no chord written)")
        local w = K.W()
        check(MM.view == "main" and K.up("main") and MM.ctx.open == nil and not (w and w.confirm), "put back: the main window is up, no menu open, no question open", "view " .. tostring(MM.view))
        local n = K.errs()
        if n ~= nil and keep.errs0 ~= nil then say("Lua errors counted during the run: " .. (n - keep.errs0)) end
    end)
end

-- =========================================================================================================
if not (MM and MM.root and St and G and MM.showView and MM.openOptions) then
    after(100, function() S.fail = S.fail + 1; say("ERR ZeD's main menu or its Options parts are not up (no desk): nothing was done") end)
else
    X.start()
    X.ways()
    X.structure()
    X.drawing()
    X.scale()
    X.seeAndFocus()
    X.preset()
    X.lite()
    X.defaults()
    X.looks()
    X.gameRows()
    X.keys()
    X.modKey()
    X.find()
    X.bands()
    X.subs()
    X.leave()
    X.welcome()
    X.setupFile()
    X.notHere()
    mark()
    X.putBack()
end
after(300, function()
    say("end: " .. S.pass .. " pass, " .. S.fail .. " fail, " .. S.skips .. " skipped; " .. math.floor((getTimestampMs() - S.start) / 1000) .. " s; view=" .. tostring(MM and MM.view))
    say(S.fail > 0 and ("VERDICT FAIL " .. S.fail) or ("VERDICT PASS " .. S.pass))
    say("DONE")
end)

local function tickFn()
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
