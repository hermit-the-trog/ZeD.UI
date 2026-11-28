-- ZeDUI/tools/qa/mu_mods.lua  (Nov 27 2026, QA menus sweep; tag mu_mods): MAIN MENU ONLY, pushed through the QA bridge.
-- The mod manager's main window against its map, ZeDUI/qa/audits/2026-11-27_map_menu_mods.md (checks MM1-MM78). No pictures.
--   opening      the About mods note once per run (the flag cleared first, put back), the main list's title and flags,
--                a new game's list (read only), the menu bar's way out and back (MM2), a reload need forgotten (MM5),
--                a Workshop download while the window is up (OnModsModified fired, MM7)
--   tabs         every tab's count against its rows with and without Find, Hide incompatible, a tab with nothing,
--                one read back from ZeD_modsview.txt, the tab row fitting the list (also at Large text), LB and RB
--   Find         plain text ("%", "(", ".", "[", a mod ID), Return and B leave the field, Clear, empty on each visit
--   rows         the hit boxes, a click then a second click, the box, the star, Space; a mod that cannot run
--   on and off   the cascade note, Turn every mod on (then Undo changes), what No mods would turn off (read only),
--                the template question (asked, never answered), "Made for game" and "Needs" on made-up records
--   the pane     the verbs and the detail tabs inside the pane, ZeD-GUI's Options tab with a change waiting, the
--                Sandbox and Conflicts tabs when a mod has them, Open in Mods (the jump file)
--   profiles     only names starting "ZeDQA_mu_": New, the names refused, Rename, Duplicate, two with the same mods,
--                the close box under a question, Load greyed with the order changed, Copy as text and Paste, Paste
--                over a name, a "\" id, a mod not installed (loaded, then Undo changes), Delete from the Delete key;
--                every one deleted the code's own way
--   the band     the pending line's words, the buttons fitting, Back's question (Keep editing), Undo changes
--   Workshop     MS.ws faked (four items, none of them a mod here): rows, tags, the pane's reason, the empty lines
--   pad          the prompts at each stop, B back to the stop that asked, Up and Down under a question, Find to Hide
--   Lite         Style set to Lite and back: the tab falls back to All, the star, the band
-- NEVER pressed or called: Accept, Reload, Keep, Discard changes, Quit to restart, Open in Steam, Open Workshop,
-- Homepage, a Workshop row's second click, Reset settings, Pick files, a file switch, Fine hide this, Load after (only
-- when a conflict offers it, then Undo changes), Back with nothing waiting (it accepts). The window is left the way the
-- menu bar leaves it (MM.showView "main"), so nothing is ever accepted and default.txt is never written.
--
-- What it puts back itself: every mod on or off and the load order as found (Undo changes, or the set and order kept
-- at the start, then a fresh visit), every ZeD option (Style and Text size are flipped and put back), MS.ws (the Workshop
-- state) as found, the main list's pins and rules, the stars, the About mods flag and the welcome debug option, the
-- clipboard (Copy as text writes it), MM.forceGamepad, the tab and Hide incompatible; and these files under
-- Zomboid/Lua, text for text when they changed: ModOptions.ini, ZeD_modsview.txt, pz_modlist_settings.cfg,
-- ZeD_modprofiles.txt, ZeD_modprofiles_spare.txt, ZeD_mods_jump.txt, ZeD_modconflicts_hidden.txt (never meant to change),
-- ZeD_style_carry.txt and ZeD_custom_additions.txt (Lite's switch may write them) (the profile and paste checks write the first ones
-- through the code's own saves; Open in Mods writes and empties the jump file). Lua cannot delete a file: one that was
-- not there before is left empty (the same as no file) and said in a NOTE. ZeD picks may write Lua/ZeD_picks.txt as
-- the window opens (not this script's).
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/zed_only_mods.txt `
--        -Script ZeDUI/tools/qa/mu_mods.lua -Tag mu_mods -TimeoutSec 540
--   with $env:ZEDQA_NOSTEAM = "1" set first. Lines: "ZEDQA mu_mods PASS ..." / "FAIL ..." / "SKIP ..." / "NOTE ..." /
--   "ERR ...", then "VERDICT PASS n" or "VERDICT FAIL n", then DONE (from a later frame). grep "ZEDQA mu_mods".
local TAG = "mu_mods"
local MM = ZeD and ZeD.MainMenu
local St = ZeD and ZeD.Settings
local MS = ZeD and ZeD.ModScan
local S = { pass = 0, fail = 0, skips = 0, stages = {}, si = 1, maxMs = 400000, start = getTimestampMs() }
local keep = { files = {}, made = {} }
local K = {}
local X = {}
-- the QA profiles (every name starts "ZeDQA_"), a mod id that is never installed
local Q = { A = "ZeDQA_mu_a", A2 = "ZeDQA_mu_a2", A3 = "ZeDQA_mu_a3", B = "ZeDQA_mu_b", R = "ZeDQA_mu_r", SL = "ZeDQA_mu_s",
            MISS = "ZeDQA_mu_m", BAD = "ZeDQA_mu*?", FRESH = "ZeDQA_mu_fresh", GONE = "ZeDQANotInstalled42" }
-- the files under Zomboid/Lua this run may change, and the line end each is written with
local FILES = { { "ModOptions.ini", "\r\n" }, { "ZeD_modsview.txt", "\n" }, { "pz_modlist_settings.cfg", "\n" },
                { "ZeD_modprofiles.txt", "\n" }, { "ZeD_modprofiles_spare.txt", "\n" }, { "ZeD_mods_jump.txt", "\n" },
                { "ZeD_modconflicts_hidden.txt", "\n" }, { "ZeD_style_carry.txt", "\n" }, { "ZeD_custom_additions.txt", "\n" } }

local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local function check(ok, what, detail)
    if ok then S.pass = S.pass + 1 else S.fail = S.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. ((detail ~= nil and detail ~= "") and (" | " .. tostring(detail)) or ""))
    return ok and true or false
end
local function skip(what, why) S.skips = S.skips + 1; say("SKIP " .. what .. " | " .. tostring(why)) end
local function note(s) say("NOTE " .. tostring(s)) end

-- ---- the stages, on the clock (as bx_menu.lua): after(ms, fn) runs fn ms after the stage before it (three frames at
-- least); waitFor(cond, maxMs, fn) runs fn(true) as soon as cond is true, fn(false) after maxMs; mark() is where the
-- put-back starts (out of time: the queue jumps there)
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
function K.tr(key, a, b) local s = nil; pcall(function() s = ZeD.tr(key, a, b) end); return tostring(s) end
function K.has(t, v) for _, x in ipairs(t or {}) do if x == v then return true end end; return false end
function K.copy(t) local o = {}; for i, v in ipairs(t or {}) do o[i] = v end; return o end

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
function K.setOpt(id, i)
    local o = K.opt(id)
    if not o then error("no ZeD option " .. tostring(id)) end
    o:setValue(i)
    if o.onChange then o.onChange(o, i) end
    if o.onChangeApply then o.onChangeApply(o, i) end
end
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
-- a file's text as found means the same as no file when it holds nothing
function K.empty(lines) return lines == nil or #lines == 0 or (#lines == 1 and lines[1] == "") end

-- ---- the Mods window
function K.W() return MM.root and MM.root.modsWin end
function K.model() return ModSelector and ModSelector.instance and ModSelector.instance.model end
function K.rows() local w = K.W(); local r = {}; if w then pcall(function() r = w:rows() end) end; return r end
function K.activated() local t = {}; pcall(function() t = K.jlist(getActivatedMods()) end); return table.concat(t, ";") end
function K.activeList() local t = {}; pcall(function() t = K.jlist(K.model():getActiveMods():getMods()) end); return t end
function K.activeIds() return table.concat(K.activeList(), ";") end
function K.up() local w = K.W(); return MM.view == "mods" and w ~= nil and w:isVisible() and true or false end
function K.spec(w, id)
    for _, s in ipairs((w and w._specs) or {}) do if s.id == id then return s end end
    return nil
end
function K.hit(w, id)
    for _, h in ipairs((w and w._hits) or {}) do if h.id == id then return h end end
    return nil
end
function K.hitsFrom(w, pfx)
    local n = 0
    for _, h in ipairs((w and w._hits) or {}) do if tostring(h.id):sub(1, #pfx) == pfx then n = n + 1 end end
    return n
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
function K.tabIds(w) local t = {}; pcall(function() for _, x in ipairs((w:tabList())) do t[#t + 1] = x[1] end end); return t end
function K.tabOf(w, id) local r = nil; pcall(function() for _, x in ipairs((w:tabList())) do if x[1] == id then r = x end end end); return r end
-- the band's buttons, left to right
function K.band(w)
    local t = {}
    for _, s in ipairs((w and w._specs) or {}) do if s.band then t[#t + 1] = s end end
    table.sort(t, function(a, b) return (a.x or 0) < (b.x or 0) end)
    return t
end
function K.bandIds(w) local t = {}; for _, s in ipairs(K.band(w)) do t[#t + 1] = s.id end; return t end
-- the band's buttons inside the window, none over another: nil, or what is wrong
function K.bandFit(w)
    local bad, list, ww = {}, K.band(w), w:getWidth()
    for i, s in ipairs(list) do
        if (s.x or 0) < 0 or (s.x or 0) + (s.w or 0) > ww + 1 then bad[#bad + 1] = s.id .. " past the window (" .. math.floor(s.x or 0) .. "+" .. math.floor(s.w or 0) .. " of " .. math.floor(ww) .. ")" end
        local n = list[i + 1]
        if n and (s.x or 0) + (s.w or 0) > (n.x or 0) + 1 and math.abs((s.y or 0) - (n.y or 0)) < 2 then bad[#bad + 1] = s.id .. " over " .. n.id end
    end
    return bad
end
-- the pane's verbs (row 500) and its tabs (dtab:...) inside the pane: a list of what is not
function K.paneFit(w)
    local bad, d = {}, w._detail
    if not d then return { "no pane drawn" } end
    for _, s in ipairs(w._specs or {}) do
        local id = tostring(s.id)
        if (s.row == 500 or id:sub(1, 5) == "dtab:") and s.x and s.w then
            if s.x < d.x - 1 or s.x + s.w > d.x + d.w + 1 then bad[#bad + 1] = id .. " at " .. math.floor(s.x) .. "+" .. math.floor(s.w) .. " (pane " .. math.floor(d.x) .. "+" .. math.floor(d.w) .. ")" end
        end
    end
    return bad
end
-- the open tab's hit box inside the list and as wide as its words at least: nil, or what is wrong
function K.openTabFits(w)
    local L = w._list
    if not L then return "no list drawn" end
    local h = K.hit(w, "mods:tab:" .. tostring(w.filter))
    if not h then return "the open tab " .. tostring(w.filter) .. " has no hit box (out of sight)" end
    local left = w:getAbsoluteX() + L.x
    local right = left + L.w
    local t = K.tabOf(w, w.filter)
    local need = 0
    pcall(function() need = MM.textW(ZeD.T.fontF2, t[2]) end)
    if h.x < left - 1 or h.x + h.w > right + 1 then return "the open tab " .. w.filter .. " runs past the list" end
    if h.w + 1 < need then return "the open tab " .. w.filter .. " is cut (" .. math.floor(h.w) .. " of " .. math.floor(need) .. " px)" end
    return nil
end
-- a mod that is off, can be turned on and brings nothing with it: a local one (no Workshop id) first (bx_menu.lua)
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
function K.dev() local m = K.model(); return keep.devId and m and m.mods[keep.devId] or nil end
-- the set and order the window opened with, back (exactly, as Undo changes does it)
function K.restoreSet(w)
    w = w or K.W()
    if not (w and keep.on0) then return end
    w:applyOnSet(keep.on0, true)
    w:saveOrder(keep.order0)
    w:dirty()
end
-- the mods and the order as the window opened with them
function K.asFound() return K.activeIds() == keep.ids0 end
-- B or Escape only where they cannot reach Back (Back with nothing waiting accepts)
function K.safeB(w)
    if w.confirm or w._palette or w.page == "profiles" or w.page == "picks" or w.find:isFocused() then w:joyB(); return true end
    return false
end
-- a made-up mod record for problemRun / problemNow (nothing in the model): o.self, o.vmin, o.vmax, o.req
function K.fakeList(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
function K.fakeVer(s) if not s then return nil end; return { toString = function() return s end } end
function K.fakeRec(o)
    local info = {
        isAvailableSelf = function() return o.self end,
        getVersionMin = function() return K.fakeVer(o.vmin) end,
        getVersionMax = function() return K.fakeVer(o.vmax) end,
        getRequire = function() return K.fakeList(o.req or {}) end,
        getWorkshopID = function() return "" end,
    }
    return { modId = "ZeDQA_fake", name = "ZeDQA fake", modInfo = info, isAvailable = o.avail, isActive = o.active,
             isIncompatible = o.inc, incompatibleWith = o.incWith or {} }
end
-- the rows a tab should hold (Find as plain text over name, ID and Workshop number), worked out here
function K.want(w, d, tab, q)
    local k = true
    if tab == "enabled" then k = d.isActive == true
    elseif tab == "off" then k = not d.isActive
    elseif tab == "favs" then k = d.favorite and true or false
    elseif tab == "maps" then k = d.category == "map"
    elseif tab == "problems" then k = w:problem(d) ~= nil
    elseif tab == "conflicts" then k = MS.count(d.modId) > 0 end
    if k and w.hideInc and not d.isActive and w:problem(d) then k = false end
    if k and q ~= "" then
        local wid = ""
        pcall(function() wid = tostring(d.modInfo:getWorkshopID() or "") end)
        k = string.lower(tostring(d.name) .. " " .. tostring(d.modId) .. " " .. wid):find(q, 1, true) ~= nil
    end
    return k
end
function K.wantN(w, tab, q)
    local n = 0
    for _, d in ipairs(K.model().sortedMods or {}) do if K.want(w, d, tab, q) then n = n + 1 end end
    return n
end
-- the Lua reload a Back would run now, or nil (bx_menu.lua's test)
function K.wouldReset()
    local need = false
    pcall(function() need = ActiveMods.requiresResetLua(ActiveMods.getById("default")) end)
    if need then return "the mod list in memory is not the one running" end
    return nil
end
function K.vanillaNag()
    local shown = nil
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            local t = e:getTable()
            if t and t.Type == "ISModsNagPanel" and e:isVisible() then shown = t end
        end
    end)
    return shown
end
function K.prompt() local p = nil; pcall(function() p = ZeD.Prompt.top() end); return p end
function K.jd() local j = nil; pcall(function() j = JoypadState.getMainMenuJoypad() end); return j end
function K.glyphs(w)
    local t = {}
    pcall(function() for _, p in ipairs(w:getFooterPrompts() or {}) do t[#t + 1] = p.glyph end end)
    return table.concat(t, ",")
end

-- a stage's function that runs only while the Mods window is up: fn(w, met)
local function M(fn)
    return function(met)
        if keep.noMods then return end
        local w = K.W()
        if not (w and MM.view == "mods") then
            if not keep.modsLost then keep.modsLost = true; check(false, "the Mods window stays up while it is walked", "view " .. tostring(MM.view)) end
            return
        end
        return fn(w, met)
    end
end
-- a visit again: the menu bar's way out (no Back), then Mods as its button opens it
function X.revisit(label)
    after(200, function() if keep.noMods then return end; K.try(label .. ": the main window", function() MM.showView("main") end) end)
    after(250, function() if keep.noMods then return end; K.try(label .. ": Mods again", MM.openMods) end)
    waitFor(function() return keep.noMods or (K.up() and #K.rows() > 0) end, 6000, function(met)
        if keep.noMods then return end
        if not met then keep.noMods = true; check(false, label .. ": the Mods window opens again", "view " .. tostring(MM.view)) end
    end)
end

-- =========================================================================================================
-- 0: as found
function X.start()
    after(100, function()
        keep.errs = K.errs()
        keep.errs0 = keep.errs
        keep.opt0 = K.snapAll()
        for _, f in ipairs(FILES) do keep.files[f[1]] = { lines = K.readLines(f[1]), eol = f[2] } end
        keep.mods0 = K.activated()
        keep.pad0 = MM.forceGamepad
        keep.lite0 = St.lite and St.lite() or false
        keep.size0 = K.val("textSize")
        keep.ws0 = MS.ws
        pcall(function() keep.popup0 = getCore():isModsPopupDone() end)
        pcall(function() if getDebug() then keep.welcome0 = getDebugOptions():getBoolean("UI.DisableWelcomeMessage") end end)
        pcall(function() keep.clip0 = tostring(Clipboard.getClipboard() or "") end)
        local fl = {}
        for _, f in ipairs(FILES) do fl[#fl + 1] = f[1] .. " " .. (keep.files[f[1]].lines and (#keep.files[f[1]].lines .. " lines") or "absent") end
        say("as found: " .. K.count(keep.opt0) .. " options, Style " .. (keep.lite0 and "Lite" or "Full") .. ", text size " .. tostring(keep.size0)
            .. ", view " .. tostring(MM.view) .. ", screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
            .. ", About mods shown " .. tostring(keep.popup0) .. ", mods in use " .. keep.mods0 .. "; files: " .. table.concat(fl, ", "))
        check(MM.openMods and MM.showView and ZeD_MMMods and MS and MS.ws and St.lookStyleOption and true or false, "the mod manager's parts are loaded")
        if K.wouldReset() then note("at the start the mod list in memory is not the one running") end
    end)
    waitFor(function()
        local m = K.ms()
        return m ~= nil and not MM.waking and not MM.poweringOn() and (m.delay or 0) <= 0 and MM.root:isVisible()
    end, 30000, function(met)
        check(met, "the desk is awake (powered on, the fade-in over)", "waking " .. tostring(MM.waking) .. ", delay " .. tostring(K.ms() and K.ms().delay))
    end)
    after(2500, function()
        if MM.view ~= "main" then note("the desk had the " .. tostring(MM.view) .. " view up at the start: back to the main window, nothing answered"); MM.showView("main") end
        if keep.lite0 then note("Style was Lite: set to Full for the walk, put back at the end"); K.style(1) end
    end)
end

-- the checks a main-menu script cannot stage: one line each, and what the code does (design calls the map names)
function X.skips()
    after(100, function()
        skip("MM1 (a save's list, the server settings' list)", "needs the QA save under Saves/Sandbox/ZeD-QA or a server's settings screen (by hand)")
        skip("MM21: a requirement that conflicts with a mod that is on", "no two installed mods declare each other incompatible here; needs two QA test mods")
        skip("MM28: frame cost with the 1,500-mod library", "this run's library holds " .. #((K.model() and K.model().sortedMods) or {}) .. " mods; the perf baseline is by hand")
        skip("MM34: the Options tab with a mod's own options", "no mod but ZeD-GUI runs in this run (zed_only_mods.txt); ModOptions.ini changes by hand with a QA test mod")
        skip("MM35: left and right on a mod's option row", "no mod but ZeD-GUI runs, so no mod option rows")
        skip("MM36: a mod's colour row and its palette", "no mod but ZeD-GUI runs, so no colour row")
        skip("MM37: Reset settings and its backup", "never pressed (writes Lua cannot remove)")
        skip("MM38: a reset of options only", "never pressed (Reset settings)")
        skip("MM44: the Pick files page", "lasting writes into the ZeD picks mod's folder (by hand)")
        skip("MM45: a file switched off in a save's list", "needs a save's list and a file switch (by hand)")
        skip("MM47: the safety question in a save's list", "needs the QA save's list (by hand)")
        skip("MM48: profiles, No mods and Discard in a save's list", "needs the QA save's list (by hand)")
        skip("MM49: the safety grades for a save's mods", "needs the QA save's list (by hand)")
        skip("MM60: pz_modlist_settings.cfg read by the game's own screen", "needs safe mode (by hand)")
        skip("MM65: Accept forces the reload vanilla skips", "Accept reloads Lua (by hand)")
        skip("MM66: Accept writes default.txt, a save's mods.txt", "nothing is accepted here (by hand)")
        skip("MM67: the Steam memory after Reload", "Reload reloads Lua (by hand)")
        skip("MM68: an update finished before the first visit", "needs a real Steam update (by hand)")
        skip("MM76: safe mode's own ModSelector", "needs safe mode (by hand)")
        skip("MM77: the server settings' list", "needs a server's settings screen (by hand)")
        note("MM78: design call: ZeD has no Help page and no category filters past Maps (the game's combo has map, vehicle, features, modpack); ZeD's tabs here: (read at the window)")
        note("MM41: design call: a hidden conflict is keyed by its kind and its two mods (\"kind:loser>winner\", ZeD_ModScan addConflict), so a file the same pair shares later is hidden too")
        note("MM75: drift: the band's test \"not simple or lite()\" (MD:1259) is always true, since modsSimple() is lite(); Profiles and Load order show in both styles (checked in Lite below)")
    end)
end

-- =========================================================================================================
-- 1: the About mods note, then the main list (MM6, MM1)
function X.nag()
    after(200, function()
        if MM.view ~= "main" then MM.showView("main") end
        pcall(function() getCore():setModsPopupDone(false) end)
        pcall(function() if keep.welcome0 ~= nil then getDebugOptions():setBoolean("UI.DisableWelcomeMessage", false) end end)
        keep.jd = K.jd()
        keep.jdFocus0 = keep.jd and keep.jd.focus or nil
        K.try("MM6: Mods opened with the About mods flag cleared", MM.openMods)
    end)
    waitFor(function() return K.prompt() ~= nil or K.vanillaNag() ~= nil end, 4000, function(met)
        local p, v = K.prompt(), K.vanillaNag()
        keep.nag = p
        if v then
            check(false, "MM6: the About mods warning is ZeD's note, not the game's panel", "the game's ISModsNagPanel is up")
            pcall(function() v:setVisible(false); v:removeFromUIManager() end)
            return
        end
        if not check(p ~= nil and p.kind == "rich" and p._zedModsNag == true, "MM6: opening Mods once this run shows ZeD's About mods note", p and tostring(p.kind) or "no prompt") then return end
        local body = tostring(p.text or "")
        local done = false
        pcall(function() done = getCore():isModsPopupDone() end)
        check(p.ok ~= nil and p.yes == nil and done and MM.view == "mods" and body:find("<H1>", 1, true) ~= nil,
            "MM6: one OK, vanilla's heading, the once-per-run flag set, the Mods window behind it", "view " .. tostring(MM.view) .. ", flag " .. tostring(done))
        if keep.jd then check(keep.jd.focus == p, "MM6: the menu's controller holds the note", tostring(keep.jd.focus and keep.jd.focus.Type))
        else note("MM6: no controller plugged in: the pad's hold on the note is not checked") end
    end)
    after(400, function()
        local p = keep.nag
        if p then K.try("MM6: the note's OK", function() p:press(p.ok) end) end
    end)
    after(400, function()
        if not keep.nag then return end
        check(K.prompt() == nil and MM.view == "mods", "MM6: OK shuts the note, the Mods window stays", "view " .. tostring(MM.view))
        if keep.jd then check(keep.jd.focus == K.ms(), "MM6: the controller goes back to the menu that holds the desk and the Mods window", tostring(keep.jd.focus and keep.jd.focus.Type)) end
    end)
    X.revisit("MM6")
    after(300, function()
        check(K.prompt() == nil and K.vanillaNag() == nil, "MM6: the second visit shows no note (once per run)", K.prompt() and tostring(K.prompt().kind) or nil)
    end)
end
function X.open()
    waitFor(function() return K.up() and #K.rows() > 0 end, 8000, function(met)
        if not check(met, "the Mods window opens with its list", "view " .. tostring(MM.view) .. ", rows " .. #K.rows()) then keep.noMods = true; MM.showView("main"); return end
        local w, m = K.W(), K.model()
        keep.filter0, keep.hide0, keep.preset0 = w.filter, w.hideInc, w.preset
        keep.pr0 = w._picksRefreshed
        w.filter, w.hideInc = "all", false
        w:dirty()
        keep.ids0 = K.activeIds()
        keep.order0 = K.activeList()
        keep.on0 = {}
        for _, id in ipairs(keep.order0) do keep.on0[id] = true end
        local d = K.devMod()
        keep.devId = d and d.modId or nil
        say("the window: " .. #K.rows() .. " mods, on: " .. keep.ids0 .. "; the mod to turn on and off: " .. tostring(keep.devId)
            .. "; tab found " .. tostring(keep.filter0) .. ", Hide incompatible " .. tostring(keep.hide0) .. ", folders " .. tostring(w.foldersOn and w:foldersOn() or false)
            .. ", ZeD picks wrote copies " .. tostring(keep.pr0))
    end)
    after(300, M(function(w)
        local m = K.model()
        local want = K.tr("UI_ZeD_Mods_TitleFmt", K.tr("UI_ZeD_Mods_Title"))
        check(w.title == want and not m.isNewGame and not m.loadGameFolder and not m.isServerSettingsMods and w.page == "list",
            "MM1: the main menu's Mods lands on the main list, titled for it", tostring(w.title))
        K.errCheck("the window open")
    end))
end

-- MS.ws faked: four Workshop items, none of them a mod installed here
function X.wsFake()
    after(100, M(function(w)
        local now = 0
        pcall(function() now = getTimestamp() end)
        local items = {
            { id = "9990000004", title = "ZeDQA Fake Collection", state = "ok", updated = now - 86400 * 30, size = 0, children = 3 },
            { id = "9990000001", title = "ZeDQA Fake Installed", state = "ok", updated = now - 7200, size = 2500000, children = 0 },
            { id = "9990000002", title = "ZeDQA Fake Needs Update", state = "update", updated = now - 86400 * 3, size = 831488, children = 0 },
            { id = "9990000003", title = "ZeDQA Fake Not Fetched", state = "missing", updated = 0, size = 0, children = 0 },
        }
        local map = {}
        for _, it in ipairs(items) do map[it.id] = it end
        keep.wsItems, keep.wsMap = items, map
        MS.ws = { fake = true, items = map, order = items, at = 0, pending = false, first = {}, updatedNow = {}, asked = true, steamOff = false, subscribed = 4 }
        local clash = {}
        for _, it in ipairs(items) do if w:modForWs(it.id) then clash[#clash + 1] = it.id end end
        if #clash > 0 then note("the fake Workshop ids match installed mods: " .. table.concat(clash, ", ")) end
        w:dirty()
    end))
end

-- =========================================================================================================
-- 2: tabs, counts, Hide incompatible (MM8, MM9, MM10)
function X.counts()
    after(200, M(function(w)
        local m = K.model()
        local bad, info = {}, {}
        local all, on, favs, maps, probs, confs, wsn = w:counts()
        local exp = { all = #m.sortedMods, enabled = #K.activeList(), favs = K.wantN(w, "favs", ""), maps = K.wantN(w, "maps", ""),
                      problems = K.wantN(w, "problems", ""), conflicts = K.wantN(w, "conflicts", ""), ws = #MS.ws.order }
        exp.off = exp.all - exp.enabled
        local got = { all = all, enabled = on, off = all - on, favs = favs, maps = maps, problems = probs, conflicts = confs, ws = wsn }
        for _, k in ipairs({ "all", "enabled", "off", "favs", "maps", "problems", "conflicts", "ws" }) do
            if got[k] ~= exp[k] then bad[#bad + 1] = k .. " counts " .. tostring(got[k]) .. ", " .. tostring(exp[k]) .. " here" end
            info[#info + 1] = k .. " " .. tostring(got[k])
        end
        -- each tab's rows, without Find and with "zed" in it (the counts stay the whole library's)
        for _, q in ipairs({ "", "zed" }) do
            w.find:setText(q)
            for _, k in ipairs({ "all", "enabled", "off", "favs", "maps", "problems", "conflicts" }) do
                w.filter = k
                local n, e = #w:rows(), K.wantN(w, k, q)
                if n ~= e then bad[#bad + 1] = k .. (q ~= "" and " with Find " or "") .. ": " .. n .. " rows, " .. e .. " here" end
            end
        end
        w.find:setText(""); w.filter = "all"; w:dirty()
        local t = K.tabOf(w, "ws")
        if not (t and t[3] == #MS.ws.order) then bad[#bad + 1] = "the Workshop tab says " .. tostring(t and t[3]) .. " (items " .. #MS.ws.order .. ", one a collection, one not fetched)" end
        check(#bad == 0, "MM8: every tab's count against its rows, with and without Find (Workshop counts Steam's items)", (#bad > 0) and K.short(bad) or table.concat(info, ", "))
        note("MM78: ZeD's tabs here: " .. table.concat(K.tabIds(w), ", ") .. " (no vehicle, features or modpack filter)")
        K.errCheck("MM8")
    end))
end
function X.hide()
    after(200, M(function(w)
        local inc = select(8, w:counts()) or 0
        local probs = select(5, w:counts()) or 0
        w.filter = "all"; w.hideInc = false
        local before = #w:rows()
        w.hideInc = true
        local after_ = #w:rows()
        local offProb, onProb = 0, 0
        for _, d in ipairs(w:rows()) do if not d.isActive and w:problem(d) then offProb = offProb + 1 end end
        w.filter = "problems"
        for _, d in ipairs(w:rows()) do if d.isActive then onProb = onProb + 1 end end
        local probRows = #w:rows()
        w.filter = "off"
        local offRows = #w:rows()
        check(before - after_ == inc and offProb == 0, "MM9: Hide incompatible takes out exactly the off mods that cannot run (" .. inc .. ")",
            before .. " rows, " .. after_ .. " ticked")
        note("MM9: design call: ticked, Problems lists " .. probRows .. " row(s) (only broken mods that are on) while its tab counts " .. probs
            .. "; Off lists " .. offRows .. " while its tab counts every mod that is off" .. ((probs == 0) and " (no mod here has a problem, so nothing differs this run)" or ""))
        w.hideInc = false; w.filter = "all"; w:dirty()
    end))
end
function X.emptyTab()
    after(200, M(function(w)
        local all, on, favs, maps, probs, confs = w:counts()
        local zero = nil
        for _, k in ipairs({ "favs", "maps", "conflicts", "problems" }) do
            local c = ({ favs = favs, maps = maps, conflicts = confs, problems = probs })[k]
            if not zero and c == 0 then zero = k end
        end
        keep.zeroTab = zero
        if not zero then return end
        -- a tab with nothing: there while open, gone once left
        w.filter = zero; w:dirty()
        local whileOpen = K.has(K.tabIds(w), zero)
        w.filter = "all"; w:dirty()
        local left = K.has(K.tabIds(w), zero)
        keep.emptyOk = whileOpen and not left
        keep.emptyWhy = "open: there " .. tostring(whileOpen) .. ", left: there " .. tostring(left)
        -- the last starred mod unstarred on Starred (stars are memory only until Accept, which never runs)
        local d = K.dev()
        if zero == "favs" and d then
            w:toggleFav(d)
            local shows = K.has(K.tabIds(w), "favs")
            w.filter = "favs"
            w:toggleFav(K.model().mods[keep.devId])
            local stays = K.has(K.tabIds(w), "favs") and #w:rows() == 0
            w.filter = "all"; w:dirty()
            local goes = not K.has(K.tabIds(w), "favs")
            keep.emptyOk = keep.emptyOk and shows and stays and goes
            keep.emptyWhy = keep.emptyWhy .. "; a star shows Starred " .. tostring(shows) .. ", unstarred while open it stays " .. tostring(stays) .. ", left it goes " .. tostring(goes)
        end
        -- the same tab read back from ZeD_modsview.txt on the next visit
        K.writeLines("ZeD_modsview.txt", { "tab=" .. zero, "hideInc=0" }, "\n")
        w._view = nil
    end))
    X.revisit("MM10")
    after(300, M(function(w)
        local zero = keep.zeroTab
        if not zero then skip("MM10: a tab with nothing hides unless open", "every optional tab holds something here"); return end
        local fromFile = w.filter == zero and K.has(K.tabIds(w), zero) and #w:rows() == 0
        check(keep.emptyOk and fromFile, "MM10: a tab with nothing (" .. zero .. ") shows only while open, and opens when read back from ZeD_modsview.txt",
            tostring(keep.emptyWhy) .. "; from the file: tab " .. tostring(w.filter) .. ", rows " .. #w:rows())
        w.filter = "all"; w:dirty()
        K.errCheck("MM10")
    end))
end

-- MM11 and MM12: the tab row fits the list; LB and RB
function X.tabsFit(label)
    each(label, 250, 12000, function()
        local w = K.W()
        if keep.noMods or not w then return {} end
        return K.tabIds(w)
    end, function(id) local w = K.W(); w.filter = id; w.scroll = 0; w.sel = nil; w.wsSel = nil end,
    function(id, i, st)
        local w = K.W()
        local why = K.openTabFits(w)
        if why then st.bad[#st.bad + 1] = why end
    end, function()
        local w = K.W()
        if w then w.filter = "all"; w.scroll = 0 end
    end)
end
function X.tabs()
    after(100, M(function(w) w.filter = "all" end))
    X.tabsFit("MM11: each tab opened in turn sits whole inside the list (" .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. "; languages are never changed)")
    after(300, M(function(w)
        local order = w._tabOrder or {}
        local first, last = order[1], order[#order]
        local bad = {}
        w.filter = first; w:joyBumper(-1)
        if w.filter ~= first then bad[#bad + 1] = "LB on the first tab moved to " .. tostring(w.filter) end
        w.filter = last; w:joyBumper(1)
        if w.filter ~= last then bad[#bad + 1] = "RB on the last tab moved to " .. tostring(w.filter) end
        w.filter = first; w:joyBumper(1)
        if w.filter ~= order[2] then bad[#bad + 1] = "RB from the first went to " .. tostring(w.filter) end
        check(#order >= 2 and #bad == 0, "MM12: LB and RB walk the tabs and stop at the ends (no wrap)", table.concat(order, ","))
        -- the fallback order, used before the list's first frame
        local saved = w._tabOrder
        w._tabOrder = nil
        w.filter = "off"; w:joyBumper(1)
        local stuck = w.filter == "off"
        w._tabOrder = saved
        note("MM12: before a frame is drawn the bumpers' order is All, On, Starred, Maps, Problems, Conflicts: from Off RB " .. (stuck and "does nothing" or ("goes to " .. tostring(w.filter))) .. "; Workshop is not in it")
        w.filter = "all"; w:dirty()
        K.errCheck("MM12")
    end))
end

-- =========================================================================================================
-- 3: Find (MM14, MM15, MM16)
function X.find()
    after(200, M(function(w)
        local bad, info = {}, {}
        local qs = { "%", "(", ".", "[", "%a+", "zed" }
        local d = K.dev()
        if d then qs[#qs + 1] = string.lower(tostring(d.modId)) end
        local wid = nil
        for _, x in ipairs(K.model().sortedMods or {}) do
            pcall(function() local v = tostring(x.modInfo:getWorkshopID() or ""); if v ~= "" and not wid then wid = v end end)
        end
        if wid then qs[#qs + 1] = wid end
        w.filter = "all"
        for _, q in ipairs(qs) do
            local ok, e = pcall(function() w.find:setText(q) end)
            local n = #w:rows()
            local want = K.wantN(w, "all", string.lower(q))
            info[#info + 1] = "\"" .. q .. "\" " .. n
            if not ok then bad[#bad + 1] = q .. ": " .. tostring(e) elseif n ~= want then bad[#bad + 1] = "\"" .. q .. "\": " .. n .. " rows, " .. want .. " as plain text" end
        end
        w.find:setText("")
        check(#bad == 0, "MM14: Find is plain text (pattern characters, a mod ID" .. (wid and ", a Workshop number" or "; no mod here has a Workshop number") .. ")",
            (#bad > 0) and K.short(bad) or table.concat(info, ", "))
        K.errCheck("MM14")
    end))
    after(200, M(function(w)
        w.find:setText("zed")
        w.find:focus()
    end))
    after(250, M(function(w)
        local bad = {}
        if not w.find:isFocused() then skip("MM15: Return and B leave Find", "Find would not take the focus from a script"); keep.noFind = true; return end
        -- Return in the field: the field's own handler, then the key the menu hears in the same frame
        local took = nil
        K.try("MM15: Return in Find", function()
            w.find.onCommandEntered()
            if w._enterAt and MM.now() - w._enterAt < 400 then took = w:keyOther(Keyboard.KEY_RETURN) end
        end)
        if took ~= true then bad[#bad + 1] = "the menu's Return was not swallowed (" .. tostring(took) .. ")" end
        if w.find:isFocused() then bad[#bad + 1] = "Return left the field focused" end
        if MM.view ~= "mods" or w.page ~= "list" then bad[#bad + 1] = "Return left the window (view " .. tostring(MM.view) .. ")" end
        keep.findBad = bad
        w.find:focus()
    end))
    after(250, M(function(w)
        if keep.noFind then return end
        local bad = keep.findBad or {}
        if w.find:isFocused() then
            K.safeB(w)
            if w.find:isFocused() then bad[#bad + 1] = "B left the field focused" end
            if (w.find:getInternalText() or "") ~= "zed" then bad[#bad + 1] = "B lost the text" end
            if MM.view ~= "mods" then bad[#bad + 1] = "B left the window" end
        else bad[#bad + 1] = "Find would not take the focus a second time" end
        keep.findBad = bad
    end))
    after(250, M(function(w)
        if keep.noFind then return end
        local bad = keep.findBad or {}
        local why = K.press(w, "find:clear")
        if why then bad[#bad + 1] = "Clear: " .. why elseif (w.find:getInternalText() or "") ~= "" then bad[#bad + 1] = "Clear left text" end
        check(#bad == 0, "MM15: Return leaves Find and is not taken as Accept, B leaves it keeping the text, Clear empties it", K.short(bad) .. " (Ctrl+F is not pressed: a script cannot hold Ctrl)")
        -- MM16: the picked mod hidden by Find stays picked
        local d = K.dev() or K.model().mods["ZeD_UI"]
        w.sel = d and d.modId or nil
        w.find:setText("zzqqxxnothingmatches")
    end))
    after(300, M(function(w)
        local d = w:selected()
        note("MM16: design call: Find hides every row and the picked mod (" .. tostring(w.sel) .. ") stays picked with its pane ("
            .. ((d and w._detail) and "drawn" or "not drawn") .. "), " .. #w:rows() .. " rows beside it")
        w.find:setText("zed")
    end))
    X.revisit("MM15")
    after(200, M(function(w)
        check((w.find:getInternalText() or "") == "" and w.sel == nil and not w.confirm, "MM15: Find is empty and nothing is picked on each visit", "Find \"" .. tostring(w.find:getInternalText()) .. "\"")
        w.filter = "all"
        K.errCheck("MM14-MM16")
    end))
end

-- =========================================================================================================
-- 4: rows, on and off (MM17, MM18, MM19, MM20)
function X.rowsOnOff()
    after(200, M(function(w)
        local d = K.dev()
        w.filter = "all"; w.sel = nil
        if d then
            local idx = 1
            for i, x in ipairs(w:rows()) do if x.modId == d.modId then idx = i end end
            w.scroll = math.max(0, (idx - 3) * w:rowH())
        end
    end))
    after(300, M(function(w)
        local bad, n = {}, 0
        for _, d in ipairs(K.model().sortedMods or {}) do
            local ok, e = pcall(function() return w:rowChips(d) end)
            if not ok then bad[#bad + 1] = tostring(d.modId) .. " chips: " .. tostring(e) end
        end
        local rows = K.hitsFrom(w, "mods:row:")
        local boxes = K.hitsFrom(w, "mods:cb:")
        local stars = K.hitsFrom(w, "mods:star:")
        if rows == 0 then bad[#bad + 1] = "no row hit boxes drawn" end
        if boxes ~= rows or stars ~= rows then bad[#bad + 1] = rows .. " rows, " .. boxes .. " boxes, " .. stars .. " stars" end
        check(#bad == 0, "MM17: every row in sight has its row, box and star; every mod's tags work out", (#bad > 0) and K.short(bad) or (rows .. " rows in sight"))
        local d = K.dev()
        if not d then keep.noDev = true; return end
        -- a click picks, a second click soon after turns it on
        w._lastClick = nil
        w:clickRow(d)
        keep.click1 = w.sel == d.modId and not K.model().mods[d.modId].isActive
        w:clickRow(K.model().mods[d.modId])
        keep.click2 = K.model().mods[d.modId].isActive == true
    end))
    after(300, M(function(w)
        if keep.noDev then return end
        local bad = {}
        if not keep.click1 then bad[#bad + 1] = "one click did not just pick it" end
        if not keep.click2 then bad[#bad + 1] = "a second click did not turn it on" end
        local h = K.hit(w, "mods:cb:" .. keep.devId)
        if h then pcall(h.fn) else bad[#bad + 1] = "no box hit for it (out of sight)" end
        if K.dev().isActive then bad[#bad + 1] = "the box did not turn it off" end
        local s = K.hit(w, "mods:star:" .. keep.devId)
        if s then
            pcall(s.fn)
            if not K.dev().favorite then bad[#bad + 1] = "the star did not star it" end
            pcall(s.fn)
            if K.dev().favorite then bad[#bad + 1] = "the star again did not unstar it" end
        else bad[#bad + 1] = "no star hit for it" end
        w.sel = keep.devId
        if not w.confirm and not w.find:isFocused() and w.page == "list" then
            w:keyOther(Keyboard.KEY_SPACE)
            if not K.dev().isActive then bad[#bad + 1] = "Space did not turn it on" end
            w:keyOther(Keyboard.KEY_SPACE)
            if K.dev().isActive then bad[#bad + 1] = "Space again did not turn it off" end
        else bad[#bad + 1] = "Space not pressed (a question or Find was open)" end
        if not K.asFound() then K.restoreSet(w) end
        check(#bad == 0 and not w:changed() and K.asFound(), "MM18: a click picks, a second click within 450 ms turns it on, the box, the star and Space turn it",
            K.short(bad) .. " (" .. keep.devId .. ")")
        -- MM19: a mod that cannot run
        local p = nil
        for _, d in ipairs(K.model().sortedMods or {}) do if not p and not d.isActive and w:problem(d) then p = d end end
        if not p then skip("MM19: turning on a mod that cannot run", "every mod that is off here can run"); return end
        w:toggle(p)
        local still = not K.model().mods[p.modId].isActive and not w:changed()
        note("MM19: design call: turning on " .. tostring(p.modId) .. " (\"" .. tostring(w:problem(p)) .. "\") " .. (still and "only plays the hover sound: it stays off, nothing else says why" or "TURNED IT ON"))
        if not still then K.restoreSet(w) end
        K.errCheck("MM17-MM19")
    end))
    -- MM20: the cascade note (a mod that needs one that is on, then that one off)
    after(250, M(function(w)
        local m = K.model()
        local D, R = nil, nil
        for _, d in ipairs(m.sortedMods or {}) do
            if not D and not d.isActive and not w:problem(d) and d.modId ~= "ModTemplate" then
                for _, r in ipairs(K.jlist(d.modInfo:getRequire())) do
                    if not R and m.mods[r] and m.mods[r].isActive then D, R = d, m.mods[r] end
                end
            end
        end
        if not D then keep.noCascade = true; skip("MM20: the cascade note", "no mod here that is off needs one that is on"); return end
        keep.cD, keep.cR = D.modId, R.modId
        w.note = nil
        w:toggle(D)
        keep.cOn = K.model().mods[D.modId].isActive == true
        w.note = nil
        w:toggle(K.model().mods[R.modId])
    end))
    after(250, M(function(w)
        if keep.noCascade then return end
        local m = K.model()
        local D = m.mods[keep.cD]
        local text = w.note and tostring(w.note.text) or ""
        local left = w.note and (w.note.untilMs - MM.now()) or 0
        local want = K.tr("UI_ZeD_Mods_AlsoOff", tostring(D.name))
        local named = text == want or (text ~= "" and text:find(tostring(D.name), 1, true) ~= nil)
        check(keep.cOn and not D.isActive and named and left > 4500 and left <= 6100,
            "MM20: turning off a mod others need says which came along, for 6 s", "\"" .. text .. "\", " .. math.floor(left) .. " ms left (" .. keep.cR .. " off took " .. keep.cD .. ")")
        K.try("MM20: Undo changes", function() w:revert() end)
    end))
    after(300, M(function(w)
        if keep.noCascade then return end
        check(not w:changed() and K.asFound(), "MM20: Undo changes puts the mods and the order back", K.activeIds())
        note("MM20: a mod with two needs is not staged (no such mod installed here)")
        K.errCheck("MM20")
    end))
end

-- =========================================================================================================
-- 5: made-up records, the template question, every mod on, No mods (MM22, MM23, MM24, MM25, MM26, MM27)
function X.records()
    after(200, M(function(w)
        local any = K.tr("UI_ZeD_Mods_Any")
        local a = w:problemRun(K.fakeRec({ self = false, vmin = "41.78", avail = false }))
        local b = w:problemRun(K.fakeRec({ self = false, vmax = "41.78.16", avail = false }))
        local c = w:problemRun(K.fakeRec({ self = false, avail = false }))
        local wa = K.tr("UI_ZeD_Mods_ProbVersionRange", "41.78", any)
        local wb = K.tr("UI_ZeD_Mods_ProbVersionRange", any, "41.78.16")
        local wc = K.tr("UI_ZeD_Mods_ProbVersion")
        check(a == wa and b == wb and c == wc, "MM26: \"Made for game x to y\" with \"any\" for an open end (made-up records)", tostring(a) .. " / " .. tostring(b) .. " / " .. tostring(c))
        local real = {}
        for _, d in ipairs(K.model().sortedMods or {}) do
            local self_ = true
            pcall(function() self_ = d.modInfo:isAvailableSelf() ~= false end)
            if not self_ then real[#real + 1] = tostring(d.modId) .. ": " .. tostring(w:problem(d)) end
        end
        if #real > 0 then note("MM26: the installed mods made for another game: " .. K.short(real)) end
        -- MM27: ids for mods not installed, names for installed ones that cannot run
        local m = K.model()
        local broken = nil
        for _, d in ipairs(m.sortedMods or {}) do if not broken and not d.isAvailable then broken = d end end
        local req = { "ZeDQA_NotInstalled_A", "ZeD_UI" }
        if broken then req[#req + 1] = broken.modId end
        req[#req + 1] = "ZeDQA_NotInstalled_B"
        local got = w:problemRun(K.fakeRec({ self = true, avail = false, req = req }))
        local list = { "ZeDQA_NotInstalled_A" }
        if broken then list[#list + 1] = tostring(broken.name) end
        list[#list + 1] = "ZeDQA_NotInstalled_B"
        local want = K.tr("UI_ZeD_Mods_ProbNeeds", table.concat(list, ", "))
        check(got == want, "MM27: \"Needs a, b\": ids for mods not installed" .. (broken and ", names for installed ones that cannot run" or "") .. ", none for one that runs (a made-up record)",
            tostring(got) .. (broken and "" or " (no installed mod here cannot run: the name half not staged)"))
        -- MM22: an incompatible mod that is on shows no problem
        local onRec = K.fakeRec({ self = true, avail = true, active = true, inc = true, incWith = { ZeD_UI = true } })
        local offRec = K.fakeRec({ self = true, avail = true, active = false, inc = true, incWith = { ZeD_UI = true } })
        local pOn, pOff = w:problemNow(onRec), w:problemNow(offRec)
        note("MM22: design call: a mod that is on and incompatible with one that is on reads " .. (pOn == nil and "no problem" or ("\"" .. tostring(pOn) .. "\""))
            .. "; the same mod off reads \"" .. tostring(pOff) .. "\" (made-up records); only About's Cannot run with dot is red")
        K.errCheck("MM22-MM27 records")
    end))
    -- MM23: the template question (asked on a stand-in record, never answered)
    after(200, M(function(w)
        local d = K.dev() or K.model().mods["ZeD_UI"]
        w.focusId = "mrow:" .. tostring(d and d.modId)
        keep.tFocus = w.focusId
        w._templateFor = d
        K.try("MM23: the template question", function() w:setConfirm("template") end)
        keep.tLands = w.focusId
    end))
    after(250, M(function(w)
        local yes = K.spec(w, "confirm:yes")
        note("MM23: design call: the template question puts the controller on " .. tostring(keep.tLands) .. " (" .. tostring(yes and yes.text) .. "), not Cancel; \"template\" is not in SAFE_ANSWER")
        w:setConfirm(false)
        w._templateFor = nil
        check(not w.confirm and w.focusId == keep.tFocus and not w:changed(), "MM23: Cancel shuts the template question, back on the row that asked, nothing turned on", tostring(w.focusId))
    end))
    -- MM25 (read only) and MM24 (Turn every mod on, then Undo changes)
    after(200, M(function(w)
        local diff = w:profileDiff({ name = nil })
        local names = {}
        local zed = false
        for _, d in ipairs(diff.off or {}) do names[#names + 1] = tostring(d.modId); if d.modId == "ZeD_UI" then zed = true end end
        note("MM25: design call: No mods would turn off " .. #names .. " mod(s) (" .. K.short(names) .. ")" .. (zed and ", ZeD-GUI among them; nothing says the next reload drops ZeD" or "") .. " (not loaded)")
        local fn = nil
        for _, it in ipairs(w:moreItems()) do if type(it) == "table" and it.text == K.tr("UI_ZeD_Mods_MoreAllOn") then fn = it.fn end end
        if not fn then keep.noAllOn = true; check(false, "MM24: More has Turn every mod on", "not in the menu"); return end
        w.note = nil
        K.try("MM24: Turn every mod on", fn)
    end))
    after(300, M(function(w)
        if keep.noAllOn then return end
        local m = K.model()
        local bad, n = {}, 0
        for _, d in ipairs(m.sortedMods or {}) do
            local runs = w:problemRun(d) == nil
            if d.modId == "ModTemplate" then
                if d.isActive then bad[#bad + 1] = "the template mod went on" end
            elseif runs and not d.isActive then
                local blocked = false
                for x in pairs(d.incompatibleWith or {}) do if m.mods[x] and m.mods[x].isActive then blocked = true end end
                if not blocked then bad[#bad + 1] = tostring(d.modId) .. " stayed off" end
            end
            if d.isActive then n = n + 1 end
        end
        local said = w.note and tostring(w.note.text) or ""
        if said ~= K.tr("UI_ZeD_Mods_SayAllOn") then bad[#bad + 1] = "the note says \"" .. said .. "\"" end
        check(#bad == 0 and w.page == "list", "MM24: Turn every mod on: every mod that can run is on, the template stays off, the note says so", (#bad > 0) and K.short(bad) or (n .. " on"))
        K.try("MM24: Undo changes", function() w:revert() end)
    end))
    after(300, M(function(w)
        if keep.noAllOn then return end
        check(not w:changed() and K.asFound(), "MM24: Undo changes after Turn every mod on puts the mods and the order back", K.activeIds())
        K.errCheck("MM23-MM25")
    end))
end

-- =========================================================================================================
-- 6: the detail pane (MM3, MM29-MM33, MM39-MM43, MM50)
function X.detail()
    after(200, M(function(w)
        w.filter = "all"; w.sel = "ZeD_UI"; w.fsel = nil; w.dtab = "about"; w.dscroll = 0
    end))
    after(300, M(function(w)
        local d = K.model().mods["ZeD_UI"]
        if not d then check(false, "the pane: ZeD-GUI is in the list"); return end
        local ids = {}
        for _, s in ipairs(w._specs or {}) do if s.row == 500 then ids[#ids + 1] = tostring(s.id) end end
        local posters = 0
        pcall(function() posters = d.modInfo:getPosterCount() end)
        note("MM29: design call: About has no Path or Source line and draws poster 1 only (ZeD-GUI has " .. posters .. " poster(s)); its verbs: " .. table.concat(ids, ", "))
        local url = ""
        pcall(function() url = tostring(d.modInfo:getUrl() or "") end)
        local hp = K.spec(w, "homepage")
        note("MM31: design call: " .. (hp and "Homepage is a pane button that opens the mod's page at once, with no question (not pressed: it opens a browser)" or ("no Homepage button for ZeD-GUI (url \"" .. url .. "\")")))
        local bad = K.paneFit(w)
        check(#bad == 0, "MM32: the pane's verbs sit inside the pane (ZeD-GUI, this text size)", K.short(bad))
        check(#bad == 0, "MM33: the detail tabs sit inside the pane (ZeD-GUI, this text size)", K.short(bad))
        -- MM50: If you turn it off, on the main list, asks nothing
        local asks = nil
        pcall(function() asks = w:askTurnOff(d) end)
        local grade = nil
        pcall(function() grade = ZeD.ModSafety.forTurnOff(K.model(), d).grade end)
        note("MM50: design call: About's If you turn it off shows for the main list (grade " .. tostring(grade) .. ", \"for your main list\") but turning it off there asks " .. (asks and "FIRST" or "nothing"))
        if w.confirm then w:setConfirm(false) end
        -- MM30: a mod with needs: its rows are text
        local need = nil
        for _, x in ipairs(K.model().sortedMods or {}) do if not need and #K.jlist(x.modInfo:getRequire()) > 0 then need = x end end
        keep.needId = need and need.modId or nil
        if need then w.sel = need.modId; w.dscroll = 0 end
        keep.hits0 = #(w._hits or {})
    end))
    after(300, M(function(w)
        if keep.needId then
            local links = 0
            for _, h in ipairs(w._hits or {}) do local id = tostring(h.id); if id:find("need", 1, true) or id:find("req", 1, true) then links = links + 1 end end
            note("MM30: design call: " .. keep.needId .. "'s Needs rows are text (" .. links .. " hit boxes for them); the game's open that mod in the pane")
        else note("MM30: design call: Needs and Cannot run with are text, not links (no mod here needs another to show it)") end
        -- MM3: ZeD-GUI's Options tab with a change waiting
        local d = K.dev()
        if d then w:toggle(d) end
        w.sel = "ZeD_UI"; w.dtab = "options"; w.dscroll = 0
    end))
    after(300, M(function(w)
        local s = K.spec(w, "opt:open")
        if not K.dev() then skip("MM3: ZeD-GUI's Open in Options with a change waiting", "no mod to turn on here")
        elseif not s then check(false, "MM3: ZeD-GUI's Options tab offers Open in Options", "no opt:open button")
        else
            check(s.disabled == true, "MM3: ZeD-GUI's Open in Options is greyed while a change waits (every other mod's is)",
                "changed " .. tostring(w:changed()) .. ", greyed " .. tostring(s.disabled) .. ": it leaves the window as in MM2")
        end
        K.restoreSet(w)
        w.dtab = "about"
        -- MM39: a Sandbox tab
        keep.sbId = nil
        for _, x in ipairs(K.model().sortedMods or {}) do
            if not keep.sbId then
                pcall(function() for _, t in ipairs(w:detailTabs(x)) do if t.id == "sandbox" and not t.none then keep.sbId = x.modId end end end)
            end
        end
        if keep.sbId then w.sel = keep.sbId; w.dtab = "sandbox"; w.dscroll = 0 end
    end))
    after(300, M(function(w)
        if not keep.sbId then skip("MM39: the Sandbox tab", "no mod here has sandbox options")
        else
            local errs = K.errs()
            check(w.dtab == "sandbox" and w.sel == keep.sbId and (errs == nil or keep.errs == nil or errs == keep.errs), "MM39: the Sandbox tab draws for " .. keep.sbId .. " (read only)",
                "on " .. tostring(K.model().mods[keep.sbId].isActive))
        end
        -- MM40: a Conflicts tab
        keep.cfId = nil
        for _, x in ipairs(K.model().sortedMods or {}) do
            if not keep.cfId then
                pcall(function() for _, t in ipairs(w:detailTabs(x)) do if t.id == "conflicts" and not t.none then keep.cfId = x.modId end end end)
            end
        end
        if keep.cfId then w.sel = keep.cfId; w.dtab = "conflicts"; w.dscroll = 0 end
        w.dtab = keep.cfId and "conflicts" or "about"
    end))
    after(300, M(function(w)
        if not keep.cfId then
            skip("MM40: the Conflicts tab", "no conflict among the mods loaded (only ZeD-GUI runs)")
            skip("MM43: Load after...", "no file conflict a loaded mod loses here")
        else
            local list = MS.forMod(keep.cfId)
            local hides, afters = 0, nil
            for _, s in ipairs(w._specs or {}) do
                local id = tostring(s.id)
                if id:sub(1, 8) == "cf:hide:" then hides = hides + 1 end
                if id:sub(1, 9) == "cf:after:" and not afters then afters = id end
            end
            check(hides >= 1, "MM40: the Conflicts tab lists " .. #list .. " conflict(s) for " .. keep.cfId .. " with a Fine, hide this each (not pressed)", hides .. " Hide buttons")
            if list[1] then note("MM41: a conflict's key here: " .. tostring(list[1].key)) end
            if afters then
                keep.afterId = afters
                local why = K.press(w, afters)
                check(why == nil and w:reordered(), "MM43: Load after... moves the mod and says reload", tostring(why) .. ", note " .. tostring(w.note and w.note.text))
            else skip("MM43: Load after...", "no conflict here offers it (a patch, fixed, or not this mod's to lose)") end
        end
        if keep.afterId then K.restoreSet(w) end
        w.dtab = "about"; w.sel = nil
        K.errCheck("the pane")
    end))
end

-- MM46: Open in Mods (the jump file)
function X.jump()
    after(200, M(function(w)
        local d = K.model().mods["ZeD_UI"]
        keep.jumpName = d and tostring(d.name) or "ZeD_UI"
        w.filter = "enabled"
        local ok = false
        pcall(function() ok = ZeD.ModFiles.setJump(keep.jumpName, "media/lua/client/ZeD/ZeD_MainMenuMods.lua") end)
        keep.noJump = not ok
    end))
    X.revisit("MM46")
    waitFor(function() local w = K.W(); return keep.noJump or (w and w._pendingJump == nil) end, 6000, M(function(w, met)
        if keep.noJump then check(false, "MM46: the jump file is written (ZeD_ModFiles.setJump)"); return end
        local left = K.readLines("ZeD_mods_jump.txt")
        check(w.sel == "ZeD_UI" and w.dtab == "files" and w.filter == "all" and w.focusId == "dtab:files" and K.empty(left),
            "MM46: Open in Mods picks the mod on its Files tab, the tab set to All, the jump file emptied",
            "sel " .. tostring(w.sel) .. ", tab " .. tostring(w.dtab) .. ", filter " .. tostring(w.filter) .. ", file " .. (left and (#left .. " lines") or "absent"))
    end))
    after(300, M(function(w) w.dtab = "about"; w.sel = nil; w.filter = "all"; K.errCheck("MM46") end))
end

-- =========================================================================================================
-- 7: leaving by another way, a reload need, a Workshop download (MM2, MM5, MM7)
function X.leaving()
    after(200, M(function(w)
        local d = K.dev()
        if not d then keep.noDev2 = true; return end
        w:toggle(d)
        keep.m2before = w:changed()
    end))
    X.revisit("MM2")
    after(250, M(function(w)
        if keep.noDev2 then skip("MM2: leaving by the menu bar with a change waiting", "no mod to turn on here"); return end
        local d = K.dev()
        local still = d and d.isActive
        local asks = w:changed()
        check(not (still and not asks), "MM2: a change left by the menu bar's way is still counted when the window comes back (Back still asks)",
            "before leaving changed " .. tostring(keep.m2before) .. "; back again: " .. keep.devId .. " on " .. tostring(still) .. ", changed " .. tostring(asks)
            .. " (the in-memory list became the baseline; default.txt is not written)")
        K.restoreSet(w)
    end))
    X.revisit("MM2 put back")
    after(250, M(function(w)
        check(K.asFound() and not w:changed() and K.wouldReset() == nil, "MM2: the list and its baseline are as found again", K.activeIds())
        -- MM5: a reload need (the Files tab's count, set by hand: no file is switched)
        w._filesChanged = 2
        w:dirty()
        keep.m5before = w:pendingNow()
    end))
    X.revisit("MM5")
    after(250, M(function(w)
        local now = w:pendingNow()
        check(keep.m5before ~= nil and w._filesChanged ~= nil, "MM5: a reload need (files switched) is kept when the window is left and opened again",
            "before \"" .. tostring(keep.m5before) .. "\", after \"" .. tostring(now) .. "\" (staged: the Files tab's count set by hand)")
        w._filesChanged = nil
        -- MM7: a Workshop download while the window is up
        local d = K.dev()
        if not d then keep.noDev7 = true; return end
        w:toggleFav(d)
        w:toggle(K.model().mods[keep.devId])
        keep.m7 = { fav = K.model().mods[keep.devId].favorite == true, changed = w:changed() }
        K.try("MM7: OnModsModified fired", function() triggerEvent("OnModsModified") end)
    end))
    after(400, M(function(w)
        if keep.noDev7 then skip("MM7: a Workshop download while the window is up", "no mod to turn on here"); return end
        local d = K.dev()
        note("MM7: design call: OnModsModified reloads the list: the star set this visit is " .. ((d and d.favorite) and "kept" or "gone")
            .. " (was " .. tostring(keep.m7.fav) .. "), the mod turned on is " .. ((d and d.isActive) and "still on" or "off")
            .. " and changed() reads " .. tostring(w:changed()) .. " (was " .. tostring(keep.m7.changed) .. "): the changed set is the new baseline")
        if d and d.favorite then w:toggleFav(d) end
        K.restoreSet(w)
    end))
    X.revisit("MM7 put back")
    after(250, M(function(w)
        local d = K.dev()
        check(K.asFound() and not w:changed() and not (d and d.favorite), "MM7: the list, its baseline and the stars are as found again", K.activeIds())
        K.errCheck("MM2-MM7")
    end))
end

-- =========================================================================================================
-- 8: profiles (MM4, MM51-MM59); only ZeDQA_mu_ names, each deleted the code's own way
function X.profiles()
    after(200, M(function(w)
        local m = K.model()
        local taken = {}
        for _, n in ipairs(w:presetNames()) do if n:sub(1, 9) == "ZeDQA_mu_" or n:sub(1, 9) == "ZeDQA_mu*" then taken[#taken + 1] = n end end
        if #taken > 0 then keep.noProf = true; note("profiles: QA profiles are already there (" .. table.concat(taken, ", ") .. "): the profile checks are skipped, nothing touched"); return end
        keep.presets0 = #w:presetNames()
        pcall(function() keep.lo0 = ZeD.ModOrder.getLo(ZeD.ModOrder.listKey(m)) end)
        K.try("MM51: Profiles, New...", function()
            w:enterProfiles()
            w:setConfirm("save")
            w.field:setText(Q.A)
            w:savePreset()
        end)
    end))
    after(300, M(function(w)
        if keep.noProf then return end
        local m = K.model()
        local diff = w:profileDiff({ name = Q.A })
        local e = ZeD.ModOrder.entry(Q.A)
        local order = e and table.concat(e.order or {}, ";") or ""
        check(m.presets[Q.A] ~= nil and #w:profiles() == keep.presets0 + 2 and diff.count == #keep.order0 and diff.inUse and order == keep.ids0,
            "MM51: New saves the mods on now with their order; the page lists No mods and every profile; its counts match",
            "rows " .. #w:profiles() .. ", count " .. tostring(diff.count) .. ", in use " .. tostring(diff.inUse) .. ", order " .. order)
        w.psel = Q.A
    end))
    after(300, M(function(w)
        if keep.noProf then return end
        local ts = w.titleStats and w.titleStats[1]
        check(w:profileInUse() == Q.A and ts ~= nil and ts.text == Q.A, "MM59: the profile in use sits in the title", tostring(ts and ts.text))
        local ld, up = K.spec(w, "load"), K.spec(w, "update")
        check(ld and ld.disabled and up and up.disabled, "MM52: Load and Update are greyed on the profile whose mods are on", "load " .. tostring(ld and ld.disabled) .. ", update " .. tostring(up and up.disabled))
        -- MM54: names refused
        local bad = {}
        local valid = true
        pcall(function() valid = SandboxOptions.isValidPresetName(Q.BAD) end)
        local cases = { { Q.A, false, "a taken name" }, { "No mods", false, "No mods" }, { K.tr("UI_ZeD_Mods_NoMods"), false, "No mods translated" },
                        { "@ZeDQA_mu", false, "an @ name" }, { "", false, "nothing" }, { Q.FRESH, true, "a free name" } }
        if not valid then cases[#cases + 1] = { Q.BAD, false, "invalid characters" } end
        for _, c in ipairs(cases) do if w:nameFree(c[1]) ~= c[2] then bad[#bad + 1] = c[3] .. " (" .. c[1] .. ") free " .. tostring(w:nameFree(c[1])) end end
        keep.nameBad = bad
        w:setConfirm("save")
        w.field:setText(Q.A)
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local s = K.spec(w, "confirm:yes")
        if not (s and s.disabled) then keep.nameBad[#keep.nameBad + 1] = "Save not greyed on a taken name" end
        w.field:setText(Q.FRESH)
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local s = K.spec(w, "confirm:yes")
        if not (s and not s.disabled) then keep.nameBad[#keep.nameBad + 1] = "Save greyed on a free name" end
        w:setConfirm(false)
        w.psel = Q.A
        w:setConfirm("rename")
        if w.field:getText() ~= Q.A then keep.nameBad[#keep.nameBad + 1] = "Rename offers \"" .. tostring(w.field:getText()) .. "\"" end
        w.field:setText(Q.A2)
        w:renameProfile()
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local m = K.model()
        if not (m.presets[Q.A2] and not m.presets[Q.A] and w.preset == Q.A2) then keep.nameBad[#keep.nameBad + 1] = "Rename: " .. tostring(m.presets[Q.A2] ~= nil) .. ", old gone " .. tostring(m.presets[Q.A] == nil) .. ", in use " .. tostring(w.preset) end
        w.psel = Q.A2
        w:setConfirm("dup")
        if w.field:getText() ~= K.tr("UI_ZeD_Mods_CopyName", Q.A2) then keep.nameBad[#keep.nameBad + 1] = "Duplicate offers \"" .. tostring(w.field:getText()) .. "\"" end
        w.field:setText(Q.A3)
        w:duplicateProfile()
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local m = K.model()
        if not (m.presets[Q.A3] and w:profileDiff({ name = Q.A3 }).count == w:profileDiff({ name = Q.A2 }).count) then keep.nameBad[#keep.nameBad + 1] = "Duplicate made no copy" end
        check(#keep.nameBad == 0, "MM54: New, Rename and Duplicate refuse bad names (Save greyed), Rename offers the name, Duplicate offers \"Copy of\"", K.short(keep.nameBad))
        -- MM59: two profiles with the same mods: the last loaded or saved wins
        local a = w:profileInUse()
        w.preset = Q.A3
        local b = w:profileInUse()
        w.preset = Q.A2
        check(a == Q.A2 and b == Q.A3, "MM59: two profiles with the same mods: the one last loaded or saved is in use", tostring(a) .. ", then " .. tostring(b))
        -- MM4: the close box under a question on the Profiles page
        w.psel = Q.A3
        if w.page ~= "profiles" then w:enterProfiles(); w.psel = Q.A3 end
        w:setConfirm("rename")
        -- (the close box runs back(): on any page but the list it leaves that page, never Accept)
        if w.page == "profiles" then K.try("MM4: the close box under Rename", function() w:close() end) end
        local cf, vis, page = w.confirm, w.field:isVisible(), w.page
        check(page == "list" and not cf and not vis, "MM4: the close box on the Profiles page shuts a question left open there",
            "page " .. tostring(page) .. ", question " .. tostring(cf) .. ", field shown " .. tostring(vis) .. ", Find \"" .. tostring(w.find:getInternalText()) .. "\"")
        if w.confirm then w:setConfirm(false) end
        if w.page ~= "list" then w:leaveProfiles() end
        w.find:setText("")
    end))
    -- MM52: the same mods in another order; MM56: Copy as text and Paste
    after(250, M(function(w)
        if keep.noProf then return end
        local d = K.dev()
        if d then w:toggle(d) end
        w:enterProfiles()
        w:setConfirm("save")
        w.field:setText(Q.B)
        w:savePreset()
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local e = ZeD.ModOrder.entry(Q.B)
        keep.orderB = K.copy(e and e.order or {})
        local rev = {}
        for i = #keep.orderB, 1, -1 do rev[#rev + 1] = keep.orderB[i] end
        w:saveOrder(rev)
        w:dirty()
        w.psel = Q.B
    end))
    after(300, M(function(w)
        if keep.noProf then return end
        local ld = K.spec(w, "load")
        local up = K.spec(w, "update")
        note("MM52: design call: with " .. #keep.orderB .. " mods in another order (" .. K.activeIds() .. " against the profile's " .. table.concat(keep.orderB, ";")
            .. ") Load is " .. ((ld and ld.disabled) and "greyed" or "offered") .. " and Update is " .. ((up and up.disabled) and "greyed" or "offered")
            .. ": the order alone cannot be loaded back or saved" .. ((#keep.orderB < 2) and " (only one mod on: not staged)" or ""))
        w:copyPreset()
        local clip = ""
        pcall(function() clip = tostring(Clipboard.getClipboard() or "") end)
        keep.clipB = clip
        keep.clipWant = Q.B .. ":" .. table.concat(keep.orderB, ";") .. ";"
        local body = clip:match(":(.*)$") or ""
        w:setConfirm("paste")
        w.field:setText(Q.R .. ":" .. body)
        w:pastePreset()
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local m = K.model()
        local e = ZeD.ModOrder.entry(Q.R)
        local order = e and table.concat(e.order or {}, ";") or ""
        check(keep.clipB == keep.clipWant and m.presets[Q.R] ~= nil and order == table.concat(keep.orderB, ";"),
            "MM56: Copy as text writes \"name:id;id;\" in the profile's order, and Paste brings it back in that order",
            "clipboard \"" .. tostring(keep.clipB) .. "\", pasted order " .. order .. " (the clipboard is put back at the end)")
        -- MM53: a share text over a profile's name
        w:setConfirm("paste")
        w.field:setText(Q.A2 .. ":ZeD_UI;" .. tostring(keep.devId or "ZeDQA_x") .. ";")
        w.note = nil
        w:pastePreset()
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local m = K.model()
        local got = w:profileDiff({ name = Q.A2 }).count
        local said = w.note and tostring(w.note.text) or ""
        local nothing = said == K.tr("UI_ZeD_Mods_SayNothingToAdd")
        check(not (nothing and got == 2), "MM53: Paste over an existing profile's name says what it did",
            Q.A2 .. " now holds " .. tostring(got) .. " mods (the game replaced it, saved at once) while the note says \"" .. said .. "\"")
        local valid = true
        pcall(function() valid = SandboxOptions.isValidPresetName(Q.BAD) end)
        keep.badIn = nil
        if not valid then
            w:setConfirm("paste")
            w.field:setText(Q.BAD .. ":ZeD_UI;")
            w:pastePreset()
            keep.badIn = K.model().presets[Q.BAD] ~= nil
        end
        if keep.badIn ~= nil then
            check(not keep.badIn, "MM53: Paste refuses a name New would refuse", "\"" .. Q.BAD .. "\" (invalid) got in: " .. tostring(keep.badIn) .. "; No mods and @ names are not staged (QA names only)")
        else note("MM53: \"" .. Q.BAD .. "\" is a valid preset name here: the invalid-name half is not staged; No mods and @ names are not staged (QA names only)") end
        -- MM57: "\" ids
        w:setConfirm("paste")
        w.field:setText(Q.SL .. ":\\ZeD_UI;\\" .. tostring(keep.devId or "ZeDQA_x") .. ";")
        w:pastePreset()
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local diff = w:profileDiff({ name = Q.SL })
        local e = ZeD.ModOrder.entry(Q.SL)
        local order = e and table.concat(e.order or {}, ";") or "(no entry)"
        check(K.model().presets[Q.SL] ~= nil and diff.count == 2 and order == "ZeD_UI;" .. tostring(keep.devId or "ZeDQA_x"),
            "MM57: a pasted profile whose ids lead with \"\\\" keeps its mods and order", "mods read " .. tostring(diff.count) .. " of 2, order \"" .. order .. "\"")
        -- MM58: a profile with a mod not installed, loaded
        w:setConfirm("paste")
        w.field:setText(Q.MISS .. ":ZeD_UI;" .. Q.GONE .. ";")
        w:pastePreset()
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local diff = w:profileDiff({ name = Q.MISS })
        keep.missList = K.has(diff.missing, Q.GONE)
        w.note = nil
        K.try("MM58: the profile with a mod not installed loaded", function() w:loadProfile({ name = Q.MISS }) end)
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local said = w.note and tostring(w.note.text) or ""
        check(keep.missList and said:find(Q.GONE, 1, true) ~= nil and w.page == "list", "MM58: a profile with a mod not installed lists it, and loading it says which", "\"" .. said .. "\"")
        note("MM58: design call: the missing ids are only named in the note; nothing leads to their Steam pages (the game's Missed mods window does)")
        pcall(function() local O = ZeD.ModOrder; if keep.lo0 then O.putLo(O.listKey(K.model()), keep.lo0, false) end end)
        K.try("MM58: Undo changes", function() w:revert() end)
    end))
    -- MM55: Delete from the Delete key acts on the profile it was opened on
    after(250, M(function(w)
        if keep.noProf then return end
        w:enterProfiles()
        w.psel = Q.A3
        if w.confirm or w.find:isFocused() then keep.noDel = true; return end
        w:keyOther(Keyboard.KEY_DELETE)
        keep.delAsk = w.confirm == "delete" and w._pTarget == Q.A3
        w.psel = Q.A2
    end))
    after(300, M(function(w)
        if keep.noProf then return end
        if keep.noDel then check(false, "MM55: the Delete key asks", "a question or Find was open"); return end
        local why = "not pressed: the question is not Delete on " .. Q.A3
        if w.confirm == "delete" and w._pTarget == Q.A3 then why = K.press(w, "confirm:yes") end
        local m = K.model()
        check(keep.delAsk and why == nil and m.presets[Q.A3] == nil and m.presets[Q.A2] ~= nil, "MM55: the Delete key asks, and Delete acts on the profile it was opened on, not the one picked since",
            "asked " .. tostring(keep.delAsk) .. ", " .. tostring(why) .. ", " .. Q.A3 .. " gone " .. tostring(m.presets[Q.A3] == nil) .. ", " .. Q.A2 .. " kept " .. tostring(m.presets[Q.A2] ~= nil))
    end))
    after(250, M(function(w)
        if keep.noProf then return end
        local m = K.model()
        if w.confirm then w:setConfirm(false) end
        for _, n in ipairs({ Q.A, Q.A2, Q.A3, Q.B, Q.R, Q.SL, Q.MISS, Q.BAD }) do
            if m.presets[n] then pcall(function() w.psel = n; w:deletePreset() end) end
        end
        local left = {}
        for _, n in ipairs(w:presetNames()) do if n:sub(1, 8) == "ZeDQA_mu" then left[#left + 1] = n end end
        check(#left == 0 and #w:presetNames() == keep.presets0, "profiles: every QA profile deleted the code's own way", K.short(left))
        w:leaveProfiles()
        w.preset = keep.preset0
        if w:changed() or not K.asFound() then K.restoreSet(w) end
    end))
    after(300, M(function(w)
        if keep.noProf then return end
        check(not w:changed() and K.asFound(), "profiles: the mods and the order as found after the profile checks", K.activeIds())
        K.errCheck("profiles")
    end))
end

-- =========================================================================================================
-- 9: the band (MM61-MM64)
function X.bandChecks()
    after(200, M(function(w)
        local d = K.dev()
        if not d then keep.noDevB = true; return end
        w:toggle(d)
        keep.p1 = w:pendingNow()
        w.filter = "ws"; w.sel = nil; w.wsSel = nil
    end))
    after(300, M(function(w)
        if keep.noDevB then skip("MM61: the band with a change waiting", "no mod to turn on here"); skip("MM63: Back's question", "no mod to turn on here"); return end
        local bad = K.bandFit(w)
        local ids = K.bandIds(w)
        check(#bad == 0 and K.has(ids, "revert") and K.has(ids, "accept") and K.has(ids, "wsopen"),
            "MM61: the band with a change waiting on the Workshop tab: every button inside the window, none over another", table.concat(ids, ", ") .. "; " .. K.short(bad)
            .. " (Quit to restart needs a running mod Steam updated: not staged, no mod here has a Workshop id)")
        keep.bandIds1 = ids
        w.filter = "all"
        -- MM63: a star alone is no change for Back
        w:toggleFav(K.dev())
    end))
    after(200, M(function(w)
        if keep.noDevB then return end
        w:toggle(K.dev())    -- (off again: only the star is left)
        local starOnly = not w:changed()
        w:toggleFav(K.dev())
        w:toggle(K.dev())    -- (on again for Back's question)
        w.focusId = "mrow:" .. keep.devId
        -- (Back only while a change is counted: with none it accepts)
        if w:changed() and w.page == "list" then K.try("MM63: Back with a change waiting", function() w:back() end) end
        keep.backAsk = { w.confirm, w.focusId, starOnly }
    end))
    after(250, M(function(w)
        if keep.noDevB then return end
        local a = keep.backAsk
        check(a[1] == "back" and a[2] == "confirm:no" and a[3], "MM63: Back asks only for on/off changes (a star alone counts none, so Back would accept at once: not pressed); the question lands on Keep editing",
            "question " .. tostring(a[1]) .. ", on " .. tostring(a[2]) .. ", star alone no change " .. tostring(a[3]))
        K.safeB(w)
        check(not w.confirm and w.focusId == "mrow:" .. keep.devId, "MM71: B shuts Back's question, back on the row that asked", tostring(w.focusId))
        -- MM64: the order changed too, then Undo changes
        local l = K.activeList()
        local rev = {}
        for i = #l, 1, -1 do rev[#rev + 1] = l[i] end
        w:saveOrder(rev)
        keep.p2 = w:pendingNow()
        K.try("MM64: Undo changes", function() w:revert() end)
    end))
    after(300, M(function(w)
        if keep.noDevB then return end
        check(not w:changed() and K.asFound(), "MM64: Undo changes puts the mods and the load order back, the window stays", K.activeIds() .. ", page " .. tostring(w.page))
        note("MM64: Discard changes is not run (it accepts): by the code it sets the mods back (applyOnSet) and accepts without the order (no saveOrder), so a changed order stays")
        -- MM62: the pending line's words
        local bad = {}
        local want1 = K.tr("UI_ZeD_Mods_PendingReload", K.tr("UI_ZeD_Mods_TurnedOnOne", 1))
        if keep.p1 ~= want1 then bad[#bad + 1] = "one on: \"" .. tostring(keep.p1) .. "\"" end
        local fc, pr, rp = w._filesChanged, w._picksRefreshed, w._resetPending
        w._filesChanged = 2
        local f = w:pendingNow()
        w._filesChanged = nil
        if f ~= K.tr("UI_ZeD_Mods_PendingFiles", 2) then bad[#bad + 1] = "files: \"" .. tostring(f) .. "\"" end
        if not pr then
            w._picksRefreshed = true
            local p = w:pendingNow()
            if p ~= K.tr("UI_ZeD_Mods_PendingPicks") then bad[#bad + 1] = "picks: \"" .. tostring(p) .. "\"" end
            w._picksRefreshed = pr
            w._resetPending = "ZeDQA"
            local r = w:pendingNow()
            if r ~= K.tr("UI_ZeD_Mods_PendingReset", "ZeDQA") then bad[#bad + 1] = "reset: \"" .. tostring(r) .. "\"" end
        end
        w._filesChanged, w._picksRefreshed, w._resetPending = fc, pr, rp
        if w:pendingNow() ~= nil and not pr then bad[#bad + 1] = "a line left after: \"" .. tostring(w:pendingNow()) .. "\"" end
        check(#bad == 0, "MM62: the pending line's words: one turned on, files switched, picks changed, a reset (staged by hand; Load order changed needs two mods running, not staged)", K.short(bad))
        w:dirty()
        K.errCheck("the band")
    end))
end

-- =========================================================================================================
-- 10: the Workshop tab, faked (MM69, MM70)
function X.workshop()
    after(200, M(function(w)
        w.filter = "ws"; w.sel = nil; w.wsSel = nil; w.scroll = 0; w.dscroll = 0
        keep.paneSaid = {}
        w.paneText = function(s, text, ...)
            keep.paneSaid[#keep.paneSaid + 1] = tostring(text)
            return ZeD_MMMods.paneText(s, text, ...)
        end
    end))
    after(300, M(function(w)
        local bad = {}
        local rows = K.hitsFrom(w, "mods:wrow:")
        local boxes = K.hitsFrom(w, "mods:wcb:")
        if rows ~= #keep.wsItems then bad[#bad + 1] = rows .. " rows for " .. #keep.wsItems .. " items" end
        if boxes ~= 0 then bad[#bad + 1] = boxes .. " boxes on items with no mod" end
        local t = K.tabOf(w, "ws")
        if not (t and t[3] == 4) then bad[#bad + 1] = "the tab says " .. tostring(t and t[3]) end
        if not K.spec(w, "wsopen") then bad[#bad + 1] = "no Open Workshop in the band" end
        if K.spec(w, "fnew") then bad[#bad + 1] = "New folder... on the Workshop tab" end
        if w.wsSel ~= keep.wsItems[1].id then bad[#bad + 1] = "the first item is not picked (" .. tostring(w.wsSel) .. ")" end
        check(#bad == 0, "MM69: the Workshop tab lists every item, boxes only on items with a mod, Open Workshop in the band (MS.ws faked; never pressed)", K.short(bad))
        note("MM69: polling every 10 s on the list page only is not exercised (MS.ws.fake stops it)")
    end))
    each("MM70: a Workshop item with no mod: its pane says why (collection, installed, fetching, not fetched)", 300, 8000, function()
        return { { 1, "UI_ZeD_Mods_WhyCollection" }, { 2, "UI_ZeD_Mods_WhyNoMod" }, { 3, "UI_ZeD_Mods_WhyFetching" }, { 4, "UI_ZeD_Mods_WhyMissing" } }
    end, function(e)
        local w = K.W()
        keep.paneSaid = {}
        w.wsSel = keep.wsItems[e[1]].id; w.sel = nil; w.dscroll = 0
    end, function(e, i, st)
        local w = K.W()
        local want = K.tr(e[2])
        local said = keep.paneSaid[#keep.paneSaid]
        if said ~= want then st.bad[#st.bad + 1] = keep.wsItems[e[1]].title .. ": \"" .. tostring(said) .. "\"" end
        if not K.spec(w, "workshop") then st.bad[#st.bad + 1] = keep.wsItems[e[1]].title .. ": no Open in Steam (never pressed)" end
    end, function() local w = K.W(); if w then w.paneText = nil end end)
    after(200, M(function(w)
        w.paneText = nil
        keep.emptySaid = {}
        keep.drawEmpty0 = ZeD.Molecules.drawEmptyLine
        ZeD.Molecules.drawEmptyLine = function(p, x, y, ww, text)
            keep.emptySaid[#keep.emptySaid + 1] = tostring(text)
            return keep.drawEmpty0(p, x, y, ww, text)
        end
        MS.ws.order, MS.ws.items = {}, {}
        MS.ws.steamOff = true
        w.wsSel = nil
    end))
    after(250, M(function(w)
        keep.e1 = keep.emptySaid[#keep.emptySaid]
        MS.ws.steamOff = false; MS.ws.asked = false
    end))
    after(250, M(function(w)
        keep.e2 = keep.emptySaid[#keep.emptySaid]
        MS.ws.asked = true; MS.ws.pending = false
    end))
    after(250, M(function(w)
        local e3 = keep.emptySaid[#keep.emptySaid]
        ZeD.Molecules.drawEmptyLine = keep.drawEmpty0
        keep.drawEmpty0 = nil
        MS.ws.order, MS.ws.items = keep.wsItems, keep.wsMap
        check(keep.e1 == K.tr("UI_ZeD_Mods_WsNoSteam") and keep.e2 == K.tr("UI_ZeD_Mods_WsAsking") and e3 == K.tr("UI_ZeD_Mods_WsNothing"),
            "MM69: the Workshop tab's empty lines: Steam off, asking, nothing subscribed", tostring(keep.e1) .. " / " .. tostring(keep.e2) .. " / " .. tostring(e3))
        note("MM70: a second click or A on a Workshop row with no mod opens Steam's page: not pressed (by hand)")
        w.filter = "all"; w.wsSel = nil
        K.errCheck("the Workshop tab")
    end))
end

-- =========================================================================================================
-- 11: the pad (MM71, MM72, MM73)
function X.pad()
    after(200, M(function(w)
        MM.forceGamepad = true
        w.filter = "all"
        local d = K.dev() or K.model().mods["ZeD_UI"]
        keep.padId = d and d.modId
        w.sel = keep.padId
        w.focusId = "mrow:" .. tostring(keep.padId)
    end))
    after(250, M(function(w)
        local bad = {}
        local g = K.glyphs(w)
        if g ~= "A,X,Y,LB,RB,B" then bad[#bad + 1] = "a row: " .. g end
        w.filter = "ws"
        w.focusId = "wrow:" .. keep.wsItems[1].id
        g = K.glyphs(w)
        if g ~= "A,LB,RB,B" then bad[#bad + 1] = "a Workshop row: " .. g end
        w.filter = "all"
        w:enterProfiles()
        g = K.glyphs(w)
        if g ~= "A,Y,X,B" then bad[#bad + 1] = "a profile (" .. tostring(w.focusId) .. "): " .. g end
        keep.pf = w.focusId
        -- (asked on No mods: the question holds no profile, and it is never answered)
        w.psel = nil
        w:setConfirm("delete")
        g = K.glyphs(w)
        if g ~= "A,B" then bad[#bad + 1] = "a question: " .. g end
        -- MM72: under a profile question Up and Down move nothing
        local f0 = w.focusId
        w:joyDir("up"); w:joyDir("down")
        keep.delMoved = w.focusId ~= f0
        K.safeB(w)
        if w.focusId ~= keep.pf then bad[#bad + 1] = "B from Delete's question went to " .. tostring(w.focusId) .. " (asked from " .. tostring(keep.pf) .. ")" end
        w:leaveProfiles()
        keep.padBad = bad
        w.sel = keep.padId
        w.focusId = "mrow:" .. tostring(keep.padId)
    end))
    after(250, M(function(w)
        check(#keep.padBad == 0, "MM71: the prompts at a row, a Workshop row, a profile and a question; B goes back to the stop that asked", K.short(keep.padBad))
        -- MM72: under the template question (asked on a stand-in, never answered)
        w._templateFor = K.model().mods[keep.padId]
        w:setConfirm("template")
        keep.selT = w.sel
    end))
    after(250, M(function(w)
        w:joyDir("up"); w:joyDir("up"); w:joyDir("down")
        local picked = w.sel
        local still = w.confirm == "template"
        w:setConfirm(false)
        w._templateFor = nil
        check(not keep.delMoved, "MM72: Up and Down move nothing under a profile question", tostring(keep.delMoved))
        check(picked == keep.selT and still, "MM72: Up and Down under the template question pick no other row", "picked " .. tostring(picked) .. " (was " .. tostring(keep.selT) .. "), question still open " .. tostring(still))
        -- MM73: Find to Hide incompatible
        w.find:setText("")
        w.focusId = "find"
    end))
    after(250, M(function(w)
        w:joyDir("right")
        check(w.focusId == "hideinc", "MM73: Right from Find reaches Hide incompatible", tostring(w.focusId))
        -- the pane's stops: from the first verb, Down a few times; each stop it lands on in sight in the pane
        w.sel = "ZeD_UI"; w.dtab = "about"; w.dscroll = 0
        w.focusId = "toggle"
        keep.f73 = { path = {}, bad = {} }
    end))
    for _ = 1, 3 do
        after(250, M(function(w)
            if keep.f73.n then
                local s = K.spec(w, w.focusId)
                local d = w._detail
                if s and s.paneStop and d and s.y and (s.y < d.y - 1 or s.y + (s.h or 0) > d.y + d.h + 1) then
                    keep.f73.bad[#keep.f73.bad + 1] = tostring(w.focusId) .. " at " .. math.floor(s.y) .. " outside the pane " .. math.floor(d.y) .. "+" .. math.floor(d.h)
                end
            end
            keep.f73.n = (keep.f73.n or 0) + 1
            w:joyDir("down")
            keep.f73.path[#keep.f73.path + 1] = tostring(w.focusId) .. "@" .. math.floor(w.dscroll or 0)
        end))
    end
    after(250, M(function(w)
        local s = K.spec(w, w.focusId)
        local d = w._detail
        if s and s.paneStop and d and s.y and (s.y < d.y - 1 or s.y + (s.h or 0) > d.y + d.h + 1) then
            keep.f73.bad[#keep.f73.bad + 1] = tostring(w.focusId) .. " outside the pane"
        end
        check(#keep.f73.bad == 0, "MM73: the pane's stops the controller walks to are in sight in the pane (Down from the first verb)", table.concat(keep.f73.path, " > ") .. "; " .. K.short(keep.f73.bad))
        w.dscroll = 0; w.focusId = nil; w.sel = nil
        MM.forceGamepad = keep.pad0
        K.errCheck("the pad")
    end))
end

-- =========================================================================================================
-- 12: Large text (MM11, MM32, MM33, MM61 again)
function X.large()
    after(200, M(function(w)
        local big = 2
        for i, k in ipairs(St.sizeKeys or {}) do if k == "large" then big = i end end
        keep.big = big
        if keep.size0 == nil then keep.wasBig = true; note("no Text size option read: the Large text checks run at the size on screen"); return end
        if keep.size0 == big then keep.wasBig = true; return end
        K.try("Large text picked", function() K.setOpt("textSize", big) end)
    end))
    after(900, M(function(w)
        if keep.wasBig then note("Large text was on already: the checks above ran at Large text") end
        w.sel = "ZeD_UI"; w.dtab = "about"; w.dscroll = 0; w.filter = "all"
    end))
    after(300, M(function(w)
        local bad = K.paneFit(w)
        check(#bad == 0, "MM32: the pane's verbs sit inside the pane at Large text", K.short(bad))
        check(#bad == 0, "MM33: the detail tabs sit inside the pane at Large text", K.short(bad))
        local d = K.dev()
        if d then w:toggle(d) end
        w.filter = "ws"; w.sel = nil
    end))
    after(300, M(function(w)
        if K.dev() then
            local bad = K.bandFit(w)
            check(#bad == 0, "MM61: the band with a change waiting fits at Large text", table.concat(K.bandIds(w), ", ") .. "; " .. K.short(bad))
            K.restoreSet(w)
        end
        w.filter = "all"
    end))
    X.tabsFit("MM11: each tab opened in turn sits whole inside the list at Large text")
    after(300, M(function(w)
        if not keep.wasBig then K.try("Text size back", function() K.setOpt("textSize", keep.size0) end) end
    end))
    after(900, M(function(w)
        check(K.val("textSize") == keep.size0, "Text size back as found", tostring(K.val("textSize")))
        K.errCheck("Large text")
    end))
end

-- =========================================================================================================
-- 13: Lite (MM13, MM74, MM75)
function X.lite()
    after(200, M(function(w)
        w.filter = "ws"
        keep.liteFrom = w.filter
        K.style(2)
    end))
    after(900, M(function(w)
        local lite = St.lite() == true and w:simple() == true
        if not check(lite, "Lite: Style set to Lite is read at once", "lite " .. tostring(St.lite())) then return end
        w.sel = K.dev() and keep.devId or "ZeD_UI"
        w.dtab = "options"
    end))
    after(300, M(function(w)
        if not St.lite() then return end
        local view = K.readLines("ZeD_modsview.txt") or {}
        note("MM13: design call: Lite put the " .. tostring(keep.liteFrom) .. " tab back to " .. tostring(w.filter) .. " and wrote \"" .. table.concat(view, " ") .. "\" to ZeD_modsview.txt, so Full opens on that")
        local stars = K.hitsFrom(w, "mods:star:")
        local fav = K.spec(w, "fav")
        local d = w:selected()
        local f0 = d and d.favorite
        if d then w:joyX() end
        local f1 = d and K.model().mods[d.modId].favorite
        if d and f1 ~= f0 then w:joyX() end
        note("MM74: design call: Lite rows draw " .. stars .. " stars and there is no Starred tab, yet the pane offers " .. (fav and ("\"" .. tostring(fav.text) .. "\"") or "no Favourite")
            .. " and X " .. ((f1 ~= f0) and "stars the mod" or "does nothing") .. " (put back)")
        check(w.dtab == "about" and K.spec(w, "profiles") ~= nil and K.spec(w, "order") ~= nil and K.spec(w, "fnew") == nil,
            "Lite: About only, Profiles and Load order stay, no folders", "tab " .. tostring(w.dtab) .. ", band " .. table.concat(K.bandIds(w), ", "))
        note("MM75: drift: modsSimple() " .. tostring(St.modsSimple()) .. " and lite() " .. tostring(St.lite()) .. " in Lite: the band's test \"not simple or lite()\" stays true")
        K.style(1)
    end))
    after(900, M(function(w)
        check(St.lite() == false and not w:simple(), "Full again: Style set to Full is read at once", "filter " .. tostring(w.filter))
        w.filter = "all"; w.sel = nil; w.dtab = "about"
        K.errCheck("Lite")
    end))
end

-- =========================================================================================================
-- 14: a new game's list, read only (MM1, MM42, MM62)
function X.newGame()
    after(200, function()
        if keep.noMods then return end
        K.try("MM1: a new game's Choose mods (as ZeD_MMNewGame:chooseMods, no nag)", function()
            local inst = ModSelector.instance
            inst.model.loadGameFolder = nil
            inst.model.isServerSettingsMods = false
            inst:setNewGame()
            MM.showView("mods")
            inst:reloadMods()
        end)
    end)
    after(400, M(function(w)
        local m = K.model()
        local same = false
        pcall(function() same = m:getActiveMods() == ActiveMods.getById("currentGame") end)
        check(m.isNewGame and same and w.page == "list", "MM1: a new game's Choose mods lands here on the new game's list", "title \"" .. tostring(w.title) .. "\" (the same as the main list's)")
        local d = K.model().mods["ZeD_UI"]
        local tabs = {}
        pcall(function() for _, t in ipairs(w:detailTabs(d)) do tabs[#tabs + 1] = t.id .. (t.none and "-" or "+") end end)
        note("MM42: design call: in a new game's list the conflicts, their chips and the Files and Conflicts tabs come from the running list (MS.isLoaded): ZeD-GUI's tabs " .. table.concat(tabs, " "))
        keep.fc = w._filesChanged
        w._filesChanged = 1
        w.filter = "all"
        w:dirty()
    end))
    after(300, M(function(w)
        local ids = K.bandIds(w)
        local acc = K.spec(w, "accept")
        check(not K.has(ids, "revert") and acc ~= nil and acc.text == getText("UI_btn_accept"), "MM62: no pending line and no Reload in a new game's list",
            table.concat(ids, ", ") .. " (accept reads \"" .. tostring(acc and acc.text) .. "\")")
        w._filesChanged = keep.fc
        w:dirty()
    end))
    X.revisit("MM1 back on the main list")
    after(300, M(function(w)
        local m = K.model()
        check(not m.isNewGame and not m.loadGameFolder and K.asFound() and not w:changed(), "MM1: the main list again after the new game's", K.activeIds())
        K.errCheck("a new game's list")
    end))
end

-- =========================================================================================================
-- 15: leave as the menu bar leaves (never Back: with nothing waiting it accepts)
function X.leave()
    after(200, M(function(w)
        if w.confirm then w:setConfirm(false) end
        if w.page ~= "list" then if w.page == "profiles" then w:leaveProfiles() else pcall(function() w:leaveOrder(false) end) end end
        w.find:setText("")
        w.dtab = "about"
        w.preset = keep.preset0
        if w:changed() or not K.asFound() then note("leaving: the list was not as found: Undo changes"); K.restoreSet(w) end
        w.filter, w.hideInc = keep.filter0, keep.hide0
        w:dirty()
    end))
    after(400, M(function(w)
        check(not w:changed() and K.asFound(), "leaving: the mods and the order as the window opened", K.activeIds())
        MM.showView("main")
    end))
    after(300, function()
        check(MM.view == "main", "leaving: the main window is up (left as the menu bar leaves it, nothing accepted)", "view " .. tostring(MM.view))
    end)
end

-- =========================================================================================================
-- put back
function X.putBack()
    after(300, function()
        pcall(function() local w = K.W(); if w and w.confirm then w:setConfirm(false) end end)
        pcall(function() local p = K.prompt(); if p and p._zedModsNag then note("put back: the About mods note was still up: OK"); p:press(p.ok) end end)
        pcall(function() local w = K.W(); if w then w.paneText = nil end end)
        pcall(function() if keep.drawEmpty0 then ZeD.Molecules.drawEmptyLine = keep.drawEmpty0 end end)
        pcall(function()
            local w = K.W()
            if w and K.model() and (w:changed() or not K.asFound()) then note("put back: the Mods list was left changed: the set and order as found"); K.restoreSet(w) end
        end)
        pcall(function()
            local m = K.model()
            if m and (m.isNewGame or m.loadGameFolder or m.isServerSettingsMods) then m.isNewGame = false; m.loadGameFolder = nil; m.isServerSettingsMods = false end
        end)
        pcall(function() local w = K.W(); if w then w.filter, w.hideInc = keep.filter0 or w.filter, (keep.hide0 == true); w.preset = keep.preset0; w.find:setText("") end end)
        MS.ws = keep.ws0 or MS.ws
        MM.forceGamepad = keep.pad0
        MM.ctx.open = nil
        pcall(function() if MM.view ~= "main" then MM.showView("main") end end)
        if keep.opt0 then
            pcall(K.setAll, keep.opt0)
            pcall(function() St.applyScale() end)
            pcall(function() St.applyThemeNow() end)
        end
    end)
    after(1200, function()
        -- the files as found (the window is hidden: nothing draws or saves now)
        keep.wrote = {}
        for _, f in ipairs(FILES) do
            local k = keep.files[f[1]]
            local now = K.readLines(f[1])
            if k and not K.same(now, k.lines) then
                if k.lines then K.writeLines(f[1], k.lines, f[2]); keep.wrote[#keep.wrote + 1] = f[1]
                elseif not K.empty(now) then K.writeLines(f[1], {}, f[2]); keep.wrote[#keep.wrote + 1] = f[1] .. " (emptied)" end
            end
        end
        -- the model and ZeD's profile file read again from them (presets, stars, the main list's pins and rules)
        pcall(function() ZeD.ModOrder.load() end)
        pcall(function() local m = K.model(); m:loadModDataFromFile(); m:refreshMods() end)
        pcall(function() if keep.clip0 ~= nil then Clipboard.setClipboard(keep.clip0) end end)
        pcall(function() if keep.welcome0 ~= nil then getDebugOptions():setBoolean("UI.DisableWelcomeMessage", keep.welcome0) end end)
        pcall(function() if keep.popup0 ~= nil then getCore():setModsPopupDone(keep.popup0) end end)
        if #keep.wrote > 0 then say("put back: written as found: " .. table.concat(keep.wrote, ", ")) end
    end)
    after(500, function()
        local d = K.diff(keep.opt0, K.snapAll())
        check(keep.opt0 ~= nil and #d == 0, "put back: every ZeD option as found (" .. K.count(keep.opt0) .. " options)", K.short(d))
        check(St.lite() == keep.lite0 and K.val("textSize") == keep.size0, "put back: Style and Text size as found", "Lite " .. tostring(St.lite()) .. ", size " .. tostring(K.val("textSize")))
        for _, f in ipairs(FILES) do
            local k = keep.files[f[1]]
            local now = K.readLines(f[1])
            if k and k.lines then check(K.same(now, k.lines), "put back: " .. f[1] .. " line for line")
            elseif K.empty(now) then
                if now then note("put back: " .. f[1] .. " was not there before and is there now, empty (the same as no file)") end
            else check(false, "put back: " .. f[1] .. " was not there before", "it holds " .. #now .. " lines") end
        end
        local m = K.model()
        local qa = {}
        for n in pairs((m and m.presets) or {}) do if tostring(n):sub(1, 8) == "ZeDQA_mu" then qa[#qa + 1] = n end end
        check(#qa == 0, "put back: no QA profile left in the model", K.short(qa))
        local clip = nil
        pcall(function() clip = tostring(Clipboard.getClipboard() or "") end)
        if keep.clip0 ~= nil then check(clip == keep.clip0, "put back: the clipboard as found") end
        local pd = nil
        pcall(function() pd = getCore():isModsPopupDone() end)
        check(keep.popup0 == nil or pd == keep.popup0, "put back: the About mods flag as found", tostring(pd))
        check(MS.ws == keep.ws0 and not MS.ws.fake, "put back: the Workshop state (MS.ws) as found")
        check(K.wouldReset() == nil, "put back: the mod list in memory is the one running (no Lua reload waiting)", K.wouldReset())
        check(K.activated() == keep.mods0, "put back: the mods in use are the ones found")
        check(MM.forceGamepad == keep.pad0, "put back: MM.forceGamepad as found")
        local w = K.W()
        check(MM.view == "main" and MM.ctx.open == nil and K.prompt() == nil and not (w and w.confirm), "put back: the main window is up, no menu or question open", "view " .. tostring(MM.view))
        local n = K.errs()
        if n ~= nil and keep.errs0 ~= nil then say("Lua errors counted during the run: " .. (n - keep.errs0)) end
    end)
end

-- =========================================================================================================
if not (MM and MM.root and St and MS and MM.showView and ZeD_MMMods) then
    after(100, function() S.fail = S.fail + 1; say("ERR ZeD's main menu is not up (no desk): nothing was done") end)
else
    X.start()
    X.skips()
    X.nag()
    X.open()
    X.wsFake()
    X.counts()
    X.hide()
    X.emptyTab()
    X.tabs()
    X.find()
    X.rowsOnOff()
    X.records()
    X.detail()
    X.jump()
    X.leaving()
    X.profiles()
    X.bandChecks()
    X.workshop()
    X.pad()
    X.large()
    X.lite()
    X.newGame()
    X.leave()
    mark()
    X.putBack()
end
after(300, function()
    say("end: " .. S.pass .. " pass, " .. S.fail .. " fail, " .. S.skips .. " skipped; " .. math.floor((getTimestampMs() - S.start) / 1000) .. " s; view=" .. tostring(MM and MM.view))
    say(S.fail > 0 and ("VERDICT FAIL " .. S.fail) or ("VERDICT PASS " .. S.pass))
end)
after(100, function() say("DONE") end)

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
