-- ZeDUI/tools/qa/mu_ljh.lua  (Nov 27 2026, QA menus sweep; tag mu_ljh): MAIN MENU ONLY, pushed through the QA bridge.
-- Load game, Join (the saved and public lists, the server and account forms, the questions, Connecting), the invite
-- views and Host (with the server settings editor it opens), checked against the map
-- ZeDUI/qa/audits/2026-11-27_map_menu_loadjoinhost.md, checks LJ1 to LJ70. Every check id gets a line: PASS, FAIL,
-- SKIP (why) or NOTE (a design call: what ZeD does now).
--   ways in      the desk's three buttons, File > Load game, Multiplayer > Join and Host (LJ1)
--   Load game    the rows against the save folders, Find on every field, a fold under the pick, Rename's rules and its
--                band field (pad stop, click box), Delete asked and cancelled, the pad's A X Y B, whyNot per frame;
--                then in-memory stand-in saves (never on disk): a dead player 1 with another alive, two living
--                characters (Playing as), New player on an unplayable save, every can't-load reason, a click after
--                the keys moved the pick, a save whose info throws; Play is stood in for the whole time
--   invite       under -nosteam: an invite accepted with Load up lands on Connect to (its fields, its keyboard, its
--                height), then Cancel
--   Join         what opening asks for, getServerList per frame, the pad on Public and on the account form, Streamer
--                mode and the server form, the port; then stand-in servers and accounts (Server.new and Account.new,
--                never saved: every list write is stood in for while they are up): the details pane, two servers on
--                one address, a click under Remove, a double click under the password question, A against a double
--                click, a public server saved with two accounts, a locked server's Save, editing an account
--   Connecting   the game's Connecting screen shown with no connection asked: the mirror, the code field, a failure,
--                B back to Join
--   Steam invite under -nosteam: a Steam-ID invite (red square, Back), the heading with a stand-in address
--   Host         Start's gate, the two pop-ups, the stop reason at idle, a settings name starting with n in Delete
--                world's question (answered Cancel), Return (Start stood in for), safe mode handed over and taken back,
--                Back and Edit settings rewriting host.ini, the menu bar leaving an idle Host
--   Server set.  serverFileExists per frame, the name rules (typed only), Edit through the mods step (only when the
--                server's mods differ from the menu's by ZeD alone: no Lua reload), a tick changed and put back (the
--                dot, the count, the Discard question), the Password row's stars, the Mods page's height, Return on
--                the edit page (its save stood in for), Discard changes, Back to Host
-- NEVER pressed or called: Continue, Play, New player's play, Delete's Yes, Rename's Return, Join's connect, a saved
-- list write, Host's Start, Reset, Delete world, Delete player, Abort while connecting, Install, Send, Save on any
-- settings page, the mods step's Next when it would reload Lua, Reset Lua, Quit, any web page.
-- Files it may write (under Zomboid/Lua): host.ini (a marker line written before Host's Back and Edit settings, which
-- vanilla then writes again, as it does when the menu bar leaves an idle Host, LJ2; put back as found at the end).
-- Nothing else: the stand-ins live in memory only, the
-- Streamer tick is flipped in memory only (never its option), and every list write is stood in for while they live.
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself), with $env:ZEDQA_NOSTEAM = "1" first:
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/zed_only_mods.txt `
--        -Script ZeDUI/tools/qa/mu_ljh.lua -Tag mu_ljh -TimeoutSec 540
-- Lines: "ZEDQA mu_ljh PASS LJn: ..." / FAIL / SKIP / NOTE / ERR, then "end: ...", "VERDICT PASS n" or
-- "VERDICT FAIL n", then DONE from a later frame. Setup and put-back lines are labeled SETUP: and PUTBACK:.
local TAG = "mu_ljh"
local MM = ZeD and ZeD.MainMenu
local St = ZeD and ZeD.Settings
local S = { pass = 0, fail = 0, skips = 0, stages = {}, si = 1, maxMs = 400000, start = getTimestampMs() }
local keep = { stubs = {}, frames = 0, plays = 0, conts = 0 }
local K = {}
local X = {}
local F = {}

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

-- ---- small things
function K.short(list)
    local out = {}
    for i, s in ipairs(list or {}) do if i <= 6 then out[#out + 1] = tostring(s) end end
    if #(list or {}) > 6 then out[#out + 1] = "(+" .. (#list - 6) .. " more)" end
    return table.concat(out, "; ")
end
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
function K.per(n, frames)
    if not frames or frames <= 0 then return "?" end
    return tostring(math.floor(n * 10 / frames) / 10)
end

-- ---- options and files (bx_menu's)
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

-- ---- stand-ins: a table's field replaced for a while, and every one put back (in reverse) at the end. A global the
-- game gives Lua is replaced only when it is really there (rawget), so putting it back can never take it away.
function K.stub(t, k, fn)
    if type(t) ~= "table" then return false end
    local had = rawget(t, k)
    if t == _G and had == nil then return false end
    keep.stubs[#keep.stubs + 1] = { t = t, k = k, had = had }
    local ok = pcall(rawset, t, k, fn)
    if not ok then t[k] = fn end
    return rawget(t, k) == fn
end
function K.unstub(t, k)
    for i = #keep.stubs, 1, -1 do
        local s = keep.stubs[i]
        if s.t == t and s.k == k then
            local ok = pcall(rawset, t, k, s.had)
            if not ok then t[k] = s.had end
            table.remove(keep.stubs, i)
            return true
        end
    end
    return false
end
function K.unstubFrom(n)
    for i = #keep.stubs, (n or 0) + 1, -1 do
        local s = keep.stubs[i]
        local ok = pcall(rawset, s.t, s.k, s.had)
        if not ok then pcall(function() s.t[s.k] = s.had end) end
        table.remove(keep.stubs, i)
    end
end

-- ---- what a window draws, for a frame: its drawText calls and ZeD.Text.draw calls on it
function K.capStart(w)
    K.capStop()
    local c = { w = w, list = {}, td = ZeD.Text and ZeD.Text.draw, dt = rawget(w, "drawText"), orig = w.drawText }
    keep.cap = c
    w.drawText = function(self, str, ...)
        if #c.list < 4000 then c.list[#c.list + 1] = tostring(str) end
        return c.orig(self, str, ...)
    end
    if c.td then
        ZeD.Text.draw = function(p, f, text, ...)
            if p == c.w and #c.list < 4000 then c.list[#c.list + 1] = tostring(text) end
            return c.td(p, f, text, ...)
        end
    end
end
function K.capStop()
    local c = keep.cap
    if not c then return {} end
    keep.cap = nil
    pcall(rawset, c.w, "drawText", c.dt)
    if c.td then ZeD.Text.draw = c.td end
    return c.list
end
function K.capHas(list, s)
    s = tostring(s or "")
    if s == "" then return false end
    for _, l in ipairs(list or {}) do if string.find(l, s, 1, true) then return true end end
    return string.find(table.concat(list or {}, ""), s, 1, true) ~= nil
end
function K.capNext(list, label)
    for i, l in ipairs(list or {}) do if l == label then return list[i + 1] end end
    return nil
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
    if view == "load" then return r.loadWin end
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
function K.spec(w, id)
    for _, s in ipairs((w and w._specs) or {}) do if s.id == id then return s end end
    return nil
end
-- a click box over the middle of a field (absolute place), or nil
function K.hitOn(w, e)
    local cx, cy = e:getAbsoluteX() + math.floor(e:getWidth() / 2), e:getAbsoluteY() + math.floor(e:getHeight() / 2)
    for _, h in ipairs(w._hits or {}) do
        if h.fn and cx >= h.x and cx <= h.x + h.w and cy >= h.y and cy <= h.y + h.h then return h end
    end
    return nil
end
-- back to the main window whatever is up (a vanilla screen left showing would hide the desk)
function K.rescue()
    MM.ctx.open = nil
    pcall(MM.showView, "main")
end
-- (bx_menu's preflight) Join's Back runs MainScreen.resetLuaIfNeeded: why a Back would reload Lua now, or nil
function K.wouldReset()
    local need = false
    pcall(function() need = ActiveMods.requiresResetLua(ActiveMods.getById("default")) end)
    if need then return "the mod list in memory is not the one running" end
    return nil
end
-- a view's window, only while it is up: fn(w, met); flag is the keep field that says the walk was given up
local function V(view, flag, id, fn)
    return function(met)
        if keep[flag] then return end
        local w = K.win(view)
        if not (w and MM.view == view) then
            keep[flag] = true
            check(false, id .. ": the " .. view .. " window stays up while it is walked", "view " .. tostring(MM.view))
            return
        end
        return fn(w, met)
    end
end
local function LD(fn) return V("load", "noLoad", "LJ5", fn) end
local function JN(fn) return V("join", "noJoin", "LJ32", fn) end
local function HO(fn) return V("host", "noHost", "LJ59", fn) end
local function SV(fn) return V("srvset", "noSrv", "LJ63", fn) end

-- Join left without its Lua reload check when that would reload (bx_menu's K.back for Join)
function X.leaveJoin(label)
    local w = K.win("join")
    if MM.view ~= "join" or not w then return end
    pcall(function() if w.page ~= "list" then w:closeForm() end end)
    pcall(function() w:setConfirm(false) end)
    local why = K.wouldReset()
    if why then
        check(false, label .. ": Join's Back can be pressed without a Lua reload", why .. ": left by the menu bar's way instead")
        pcall(function() if getSteamModeActive() then steamReleaseInternetServersRequest() end end)
        MM.ctx.open = nil
        MM.showView("main")
        return
    end
    K.try(label .. ": Join's Back", function() w:back() end)
end

-- ZeD_MainMenuServer.lua's onlyZeDDiffers, read here: the mods step's Next skips vanilla's Lua reload only then
function X.onlyZeD(ids)
    local a, b = {}, {}
    local ok = pcall(function()
        local loaded = getActivatedMods()
        for i = 0, loaded:size() - 1 do
            local id = loaded:get(i)
            if id ~= "ZeD_UI" then a[#a + 1] = id end
        end
    end)
    if not ok then return false end
    for _, id in ipairs(ids) do if id ~= "ZeD_UI" then b[#b + 1] = id end end
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

-- =========================================================================================================
-- 0: as found
function X.start()
    after(100, function()
        keep.errs = K.errs()
        keep.errs0 = keep.errs
        keep.opt0 = K.snapAll()
        keep.host0 = K.readLines("host.ini")
        keep.pad0 = MM.forceGamepad
        keep.sn0 = CoopConnection and CoopConnection.servername
        say("as found: " .. K.count(keep.opt0) .. " options; view " .. tostring(MM.view) .. ", screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
            .. ", saves " .. tostring(MM.hasSaves and MM.hasSaves()) .. ", Steam " .. tostring(getSteamModeActive()) .. ", debug " .. tostring(getDebug())
            .. "; host.ini " .. (keep.host0 and "there" or "absent"))
        check(MM.act and MM.act.load and MM.act.join and MM.act.host and MM.showView and MM.menuItems and ZeD_MMLoad and ZeD_MMJoin and ZeD_MMHost and ZeD_MMServer and true or false,
            "SETUP: the main menu's parts are loaded (Load, Join, Host, Server settings)")
        if K.wouldReset() then note("SETUP: at the start the mod list in memory is not the one running: Join's Back would reload Lua, so Join is left by the menu bar's way and FAILs") end
    end)
    waitFor(function()
        local m = K.ms()
        return m ~= nil and not MM.waking and not MM.poweringOn() and (m.delay or 0) <= 0 and MM.root:isVisible()
    end, 30000, function(met)
        check(met, "SETUP: the desk is awake (powered on, the fade-in over)", "waking " .. tostring(MM.waking) .. ", delay " .. tostring(K.ms() and K.ms().delay))
    end)
    after(2500, function()
        if MM.view ~= "main" then
            note("SETUP: the desk had the " .. tostring(MM.view) .. " view up at the start (the first-launch setup): back to the main window, nothing answered")
            MM.showView("main")
        end
    end)
    after(400, function()
        check(MM.view == "main" and K.up("main"), "SETUP: the main window is up", "view " .. tostring(MM.view))
        K.errCheck("SETUP: the desk at rest")
    end)
end

-- 1: the ways in (LJ1)
function X.waysIn()
    after(200, function()
        local function row(items, key)
            for _, it in ipairs(items or {}) do if type(it) == "table" and it.text == ZeD.tr(key) then return it end end
            return nil
        end
        local fileRows, mpRows = MM.menuItems("file"), MM.menuItems("mp")
        local ld, jn, ho = row(fileRows, "UI_ZeD_MainMenu_LoadGame"), row(mpRows, "UI_ZeD_MainMenu_JoinServer"), row(mpRows, "UI_ZeD_MainMenu_HostGame")
        local main = K.win("main")
        local sl, sj, sh = K.spec(main, "load"), K.spec(main, "join"), K.spec(main, "host")
        local has = MM.hasSaves() and true or false
        local bad = {}
        if not (ld and jn and ho) then bad[#bad + 1] = "menu rows: Load " .. tostring(ld ~= nil) .. ", Join " .. tostring(jn ~= nil) .. ", Host " .. tostring(ho ~= nil) end
        if not (sl and sj and sh) then bad[#bad + 1] = "desk buttons: load " .. tostring(sl ~= nil) .. ", join " .. tostring(sj ~= nil) .. ", host " .. tostring(sh ~= nil) end
        if ld and ((ld.disabled and true or false) ~= (not has)) then bad[#bad + 1] = "File > Load game greyed " .. tostring(ld.disabled) .. " with saves " .. tostring(has) end
        if sl and ((sl.disabled and true or false) ~= (not has)) then bad[#bad + 1] = "the Load button greyed " .. tostring(sl.disabled) .. " with saves " .. tostring(has) end
        if ld and ld.fn ~= MM.act.load then bad[#bad + 1] = "File > Load game runs something else" end
        if jn and jn.fn ~= MM.act.join then bad[#bad + 1] = "Multiplayer > Join runs something else" end
        if ho and ho.fn ~= MM.act.host then bad[#bad + 1] = "Multiplayer > Host runs something else" end
        check(#bad == 0, "LJ1: ways in: the desk's Load, Join and Host buttons and File > Load game, Multiplayer > Join and Host; Load greyed only with no saves",
            (#bad == 0) and ("saves " .. tostring(has)) or K.short(bad))
    end)
end

-- =========================================================================================================
-- 2: Load game, the real saves (nothing renamed, nothing deleted, Play stood in for)
function X.playStub() keep.plays = keep.plays + 1 end
function X.saveKeys(w)
    local t = {}
    for _, s in ipairs(w.saves or {}) do if not s.zedqa then t[#t + 1] = tostring(s.key) end end
    table.sort(t)
    return table.concat(t, ";")
end
function X.loadOpen()
    after(200, function()
        keep.noLoad = nil
        if MM.view ~= "main" then K.rescue() end
        if MM.hasSaves() then K.try("LJ1: Load game opened as its button does", MM.act.load)
        else
            note("LJ5: no saves here: the Load window is put up by hand (MM.showView) for the stand-in checks only")
            MM.showView("load")
        end
    end)
    waitFor(function() return K.up("load") end, 5000, function(met)
        if not check(met, "LJ1: Load game comes up (view load)", "view " .. tostring(MM.view)) then keep.noLoad = true; K.rescue() end
    end)
    after(300, LD(function(w)
        -- (Play stood in for the whole visit: no save is ever played, whatever a check presses)
        K.stub(w, "play", X.playStub)
        K.stub(MainScreen, "continueLatestSave", function() keep.conts = keep.conts + 1 end)
        keep.saves0 = X.saveKeys(w)
        keep.coll0 = {}
        for k, v in pairs(w.collapsed or {}) do keep.coll0[k] = v end
        w.collapsed = {}
        w.find:setText(""); w:filter()
        K.onScreen("LJ5: Load game", w)
        K.errCheck("LJ5: Load game open")
    end))
end

function X.loadReal()
    after(300, LD(function(w)
        local okD, dirs = pcall(getFullSaveDirectoryTable)
        local n = 0
        for _, k in ipairs(okD and dirs or {}) do
            local okI, info = pcall(getSaveInfo, k)
            if okI and type(info) == "table" then n = n + 1 end
        end
        local seen, firstSeen, heads, bad = {}, {}, {}, {}
        for _, s in ipairs(w.saves) do
            if not seen[s.mode] then seen[s.mode] = 0; firstSeen[#firstSeen + 1] = tostring(s.mode) end
            seen[s.mode] = seen[s.mode] + 1
        end
        for _, r in ipairs(w.view) do
            if r.head then
                heads[#heads + 1] = tostring(r.mode)
                if r.count ~= seen[r.mode] then bad[#bad + 1] = tostring(r.mode) .. " head counts " .. tostring(r.count) .. " of " .. tostring(seen[r.mode]) end
            end
        end
        if table.concat(heads, "|") ~= table.concat(firstSeen, "|") then bad[#bad + 1] = "heads " .. table.concat(heads, ", ") .. " against first seen " .. table.concat(firstSeen, ", ") end
        if #w.saves ~= n then bad[#bad + 1] = #w.saves .. " rows for " .. n .. " readable save folders" end
        local stat = w.titleStats and w.titleStats[1] and w.titleStats[1].text
        local want = ZeD.tr(n == 1 and "UI_ZeD_Saves_CountOne" or "UI_ZeD_Saves_CountMany", n)
        if stat ~= want then bad[#bad + 1] = "the title says " .. tostring(stat) .. ", wanted " .. tostring(want) end
        check(#bad == 0, "LJ5: the rows are the save folders, grouped by mode in first-seen order, the heads counted, the count in the title",
            (#bad == 0) and (n .. " saves in " .. #heads .. " groups") or K.short(bad))
    end))
    -- LJ7: Find on every field of the picked save
    after(200, LD(function(w)
        local s = w:selected()
        if not s then skip("LJ7: Find matches the title, save name, character, mode word and map", "no save here"); return end
        local bad, tried = {}, 0
        for _, q in ipairs({ s.title, s.saveName, s.who or "", MM.modeName(s.mode), MM.mapText(s.mapName) }) do
            q = tostring(q or "")
            if q ~= "" then
                tried = tried + 1
                w.find:setText(string.upper(q)); w:filter()
                local found = false
                for _, r in ipairs(w.view) do if r.save and r.save.key == s.key then found = true end end
                if not found then bad[#bad + 1] = q end
            end
        end
        w.find:setText(""); w:filter()
        check(#bad == 0 and tried > 0, "LJ7: Find matches the save on its title, save name, character, mode word and map, in any case",
            (#bad == 0) and (tried .. " words tried, upper case") or ("not found on: " .. K.short(bad)))
        note("LJ7: the German mode word is not tried (the language is never changed here); Find matches MM.modeName, the game's IGUI_Gametime_ word in the language in use")
    end))
    -- LJ8: a fold under the pick, and folds kept when Load opens again
    after(200, LD(function(w)
        local s = w:selected()
        if not s then keep.l8 = nil; skip("LJ8: a fold under the pick moves it; folds survive reopening Load", "no save here"); return end
        keep.l8 = s.mode
        w.collapsed[s.mode] = true; w:filter()
        local first = nil
        for _, r in ipairs(w.view) do if r.save and not first then first = r.save.key end end
        check(w.sel == first, "LJ8: a group folded under the pick moves the pick to the first save shown", "pick " .. tostring(w.sel) .. ", first shown " .. tostring(first))
        K.try("LJ8: Load left and opened again", function() MM.showView("main"); MM.act.load() end)
    end))
    after(400, LD(function(w)
        if not keep.l8 then return end
        check(w.collapsed[keep.l8] == true, "LJ8: a folded group stays folded when Load opens again", tostring(keep.l8))
        w.collapsed[keep.l8] = nil; w:filter()
        if w.saves[1] then w.sel = w.saves[1].key; w.focusId = "save:" .. w.sel end
    end))
    -- LJ23: Rename's rules, asked of the code only (nothing renamed); the folder key's separator
    after(200, LD(function(w)
        local s = w:selected()
        if not s then skip("LJ23: Rename's rules and the key a renamed save is kept chosen by", "no save here"); return end
        w._rTarget = s.key; w._renameChecked = nil
        local bad = {}
        local function want(text, ok, why)
            local okV, v = pcall(function() return w:renameValid(text) end)
            if not okV then bad[#bad + 1] = why .. ": " .. tostring(v); return end
            if (v and true or false) ~= ok then bad[#bad + 1] = why .. " (" .. tostring(text) .. ") gave " .. tostring(v) end
        end
        want(s.saveName, false, "the same name")
        want("", false, "an empty name")
        want(".zedqa", false, "a name starting with a dot")
        want("zedqa.", false, "a name ending with a dot")
        want("zedqa/bad", false, "a name with a slash")
        local other = nil
        for _, o in ipairs(w.saves) do if o.mode == s.mode and o.key ~= s.key then other = o end end
        if other then want(other.saveName, false, "another save's name in the same mode") end
        want("zedqa_LJ23_never_used", true, "a fresh name")
        w._rTarget = nil; w._renameChecked = nil
        check(#bad == 0, "LJ23: Rename refuses the same name, a taken name and vanilla's bad names, takes a fresh one (asked only, nothing renamed)", K.short(bad))
        local built = tostring(s.mode) .. getFileSeparator() .. tostring(s.saveName)
        check(built == tostring(s.key), "LJ23: a renamed save is kept chosen: mode, getFileSeparator() and the name build its folder key",
            "the key " .. tostring(s.key) .. ", built " .. built)
    end))
    -- LJ24 / LJ25: Rename's band field
    after(200, LD(function(w)
        keep.l24 = nil
        if not w:selected() then skip("LJ24: Rename's band field is a controller stop", "no save here"); skip("LJ25: Rename's band field has a click box", "no save here"); return end
        keep.l24 = true
        -- (with a controller Rename lands on its field: the flag is set for the one call and put back at once)
        MM.forceGamepad = true
        K.try("LJ24: Rename asked", function() w:startRename() end)
        keep.l24land = w.focusId
        MM.forceGamepad = keep.pad0
    end))
    after(300, LD(function(w)
        if not keep.l24 then return end
        local stop = K.spec(w, "field:rename")
        check(stop ~= nil and stop.field == w.renameEntry and keep.l24land == "field:rename",
            "LJ24: Rename's band field is a controller stop (field:rename, the pad keyboard opens on it) and a controller lands on it",
            "stop " .. tostring(stop and stop.id) .. ", the hand landed on " .. tostring(keep.l24land))
        local h = nil
        pcall(function() h = K.hitOn(w, w.renameEntry) end)
        check(h ~= nil and h.id == "load:rename", "LJ25: Rename's band field has a click box that focuses it (load:rename)",
            h and tostring(h.id) or "no click box over the field: once a click lands elsewhere, a click on the field does nothing")
        K.try("LJ24: Rename cancelled", function() w:setConfirm(false) end)
    end))
    -- LJ27: Open file location listed only where the desktop can open a folder (never pressed)
    after(150, LD(function(w)
        if not w:selected() then skip("LJ27: Open file location", "no save here"); return end
        local listed = false
        for _, it in ipairs(w:moreItems()) do if type(it) == "table" and it.text == ZeD.tr("UI_LoadGameScreen_ButtonBrowseFiles") then listed = true end end
        local okD, desk = pcall(isDesktopOpenSupported)
        local can = (okD and desk) and true or false
        check(listed == can, "LJ27: More lists Open file location only when the desktop can open a folder (never pressed: it opens Explorer)",
            "supported " .. tostring(can) .. ", listed " .. tostring(listed))
    end))
    -- LJ19: Delete asked on a save, a click on another row, Cancel (Delete itself never pressed)
    after(150, LD(function(w)
        local s = w:selected()
        keep.l19 = nil
        if not s then skip("LJ19: Delete asks in the band on the save it opened on", "no save here"); return end
        local other = nil
        for _, o in ipairs(w.saves) do if o.key ~= s.key and not other then other = o end end
        w._lastClick = nil
        w:askDelete()
        local q = (w.confirm == "delete") and (w.focusId == "confirm:no") and (w._dTarget == s.key)
        if other then w:clickSave(other) end
        keep.l19 = { q = q, still = (w.sel == s.key and w._dTarget == s.key), key = s.key, other = other ~= nil }
    end))
    after(300, LD(function(w)
        local l = keep.l19
        if not l then return end
        local yes = K.spec(w, "confirm:yes")
        check(l.q and l.still and yes ~= nil, "LJ19: Delete asks in the band on the save it opened on, the pad on Cancel, a click on another row moves nothing (Delete itself never pressed)",
            "question " .. tostring(l.q) .. ", target kept " .. tostring(l.still) .. (l.other and "" or " (one save only: no other row clicked)"))
        K.try("LJ19: Delete cancelled", function() w:setConfirm(false) end)
    end))
    -- LJ29: the pad on the list (Play stood in for)
    after(200, LD(function(w)
        local s = w:selected()
        keep.l29 = nil
        if not s then skip("LJ29: the pad's A, X, Y and B on the list", "no save here"); return end
        local bad = {}
        local p0 = keep.plays
        local sp = K.spec(w, "save:" .. s.key)
        if sp and sp.fn then pcall(sp.fn) end
        if keep.plays ~= p0 + 1 then bad[#bad + 1] = "A on the row did not reach Play" end
        pcall(function() w:joyX() end)
        if w.confirm ~= "delete" then bad[#bad + 1] = "X did not ask Delete" end
        local sel0 = w.sel
        pcall(function() w:joyDir("down"); w:joyDir("up") end)
        if w.sel ~= sel0 then bad[#bad + 1] = "up or down under the question moved the pick" end
        pcall(function() w:joyB() end)
        if w.confirm then bad[#bad + 1] = "B did not cancel the question" end
        if MM.view ~= "load" then bad[#bad + 1] = "B on the question left Load" end
        pcall(function() w:joyY() end)
        if MM.ctx.open ~= "more" then bad[#bad + 1] = "Y did not open More" end
        MM.ctx.open = nil
        local last = nil
        for _, r in ipairs(w.view) do if r.save then last = r.save.key end end
        keep.l29 = { bad = bad, last = last }
        if last then w.sel = last; w.focusId = "save:" .. last end
    end))
    after(300, LD(function(w)
        local l = keep.l29
        if not l then return end
        if l.last then
            pcall(function() w:joyDir("down") end)
            local first = nil
            for _, r in ipairs(w.view) do if r.save and not first then first = r.save.key end end
            if w.sel ~= l.last then l.bad[#l.bad + 1] = "down on the last save moved the pick to " .. tostring(w.sel) .. ((w.sel == first) and " (wrapped to the first)" or "") end
        end
        check(#l.bad == 0, "LJ29: pad: A plays (Play stood in for), X asks Delete, Y opens More, B cancels the question; up and down wait under it; no wrap past the last save", K.short(l.bad))
        MM.ctx.open = nil
        w.focusId = w.sel and ("save:" .. w.sel) or nil
    end))
    -- LJ31: whyNot calls a frame
    after(150, LD(function(w)
        keep.wn = 0; keep.wf0 = keep.frames
        K.stub(w, "whyNot", function(self, s) keep.wn = keep.wn + 1; return ZeD_MMLoad.whyNot(self, s) end)
    end))
    after(1000, LD(function(w)
        K.unstub(w, "whyNot")
        local f = keep.frames - (keep.wf0 or keep.frames)
        check(f > 0 and keep.wn > 0, "LJ31: whyNot runs while Load is up (perf)", keep.wn .. " calls in " .. f .. " frames, " .. K.per(keep.wn, f) .. " a frame")
        if f > 0 and keep.wn >= f * 2 then note("LJ31: whyNot runs about " .. K.per(keep.wn, f) .. " times a frame: the band and the preview each ask (BME adds its checks to each)") end
        K.errCheck("LJ5-LJ31: Load game, the real saves")
    end))
    -- LJ16: the preview's Version label (drawn: read off the stand-in's preview in the next part)
    after(100, LD(function(w)
        local key = getTextOrNull("UI_servers_version")
        keep.l16want = ZeD.textCase(ZeD.trBare("UI_servers_version"))
        keep.l16key = key ~= nil
    end))
end

-- 3: Load game, stand-in saves in memory (never on disk; the list read again after)
function F.save(name, players, alive)
    local info = { worldVersion = IsoWorld.getWorldVersion(), mapName = "Muldraugh, KY", players = players or {}, playerAlive = alive, gameMode = "ZedQA", saveName = name }
    return { key = "ZedQA" .. getFileSeparator() .. name, order = 0, info = info, mode = "ZedQA", saveName = name, title = name,
             mapName = info.mapName, played = "", thumb = false, mapsAvailable = true, zedqa = true }
end
function X.loadFakes()
    after(200, LD(function(w)
        local A = F.save("zedqa_LJ9", { { name = "Alive Al", sqlID = 2, isDead = false }, { name = "Dead Dan", sqlID = 1, isDead = true } }, false)
        local B = F.save("zedqa_LJ10", { { name = "Ann Able", sqlID = 1, isDead = false }, { name = "Bob Baker", sqlID = 2, isDead = false } }, true)
        local C = F.save("zedqa_LJ12", { { name = "Cal Cole", sqlID = 1, isDead = false } }, true)
        C.mapsAvailable = false
        for _, s in ipairs({ A, B, C }) do w:readPlayers(s); table.insert(w.saves, 1, s) end
        keep.fk = { A = A, B = B, C = C }
        w.find:setText(""); w.collapsed["ZedQA"] = nil; w:filter()
        w.sel = A.key; w.focusId = "save:" .. A.key; w.scroll = 0
        K.capStart(w)
    end))
    after(300, LD(function(w)
        local list = K.capStop()
        local A = keep.fk.A
        local dead = ZeD.tr("UI_ZeD_Saves_NameDead", "Alive Al")
        local shown = K.capHas(list, dead)
        check(A.dead == true and A.who == "Dead Dan" and not shown, "LJ9: [stub] with player 1 dead and another character alive, the row and preview name player 1 as the dead one, never the living one",
            "dead " .. tostring(A.dead) .. ", named " .. tostring(A.who) .. (shown and (", drawn \"" .. dead .. "\"") or ", \"" .. dead .. "\" not drawn"))
        keep.l15 = K.capHas(list, ZeD.tr("IGUI_None"))
        -- LJ16: the preview's Version label is the game's key (the label drawn on its own, as the other rows)
        local lab = keep.l16want
        local drawn = false
        for _, l in ipairs(list) do if lab ~= nil and l == lab then drawn = true end end
        check(keep.l16key == true and drawn, "LJ16: [stub] the preview's Version label is the game's key UI_servers_version (as Join's), drawn",
            "UI_servers_version " .. (keep.l16key and "is a key" or "is not a key") .. ", the label \"" .. tostring(lab) .. "\" " .. (drawn and "drawn" or "not drawn") .. " (German not staged)")
        w.sel = keep.fk.B.key; w.focusId = "save:" .. keep.fk.B.key
    end))
    after(300, LD(function(w)
        local hit = nil
        for _, h in ipairs(w._hits or {}) do if h.id == "load:players" then hit = h end end
        local stop = K.spec(w, "players")
        if not hit then skip("LJ10: [stub] Playing as is a controller stop", "the Playing as box did not draw for the two-character stand-in")
        else check(stop ~= nil and stop.fn ~= nil and not stop.disabled, "LJ10: [stub] Playing as (two living characters) is a controller stop (players, A opens the list; never pressed)",
            stop and (tostring(stop.id) .. (stop.disabled and ", greyed" or "")) or "a mouse click box only (load:players): the pad cannot reach it") end
        -- LJ11: Playing as, the save's player 1 and its info stood in for
        local B = keep.fk.B
        local rec = {}
        local info2 = { worldVersion = B.info.worldVersion, mapName = B.info.mapName, playerAlive = true, gameMode = "ZedQA", saveName = B.saveName,
                        players = { { name = "Bob Baker", sqlID = 1, isDead = false }, { name = "Ann Able", sqlID = 2, isDead = false } } }
        local okS = K.stub(_G, "setSavefilePlayer1", function(mode, name, id) rec[#rec + 1] = tostring(mode) .. "," .. tostring(name) .. "," .. tostring(id) end)
        local okI = K.stub(_G, "getSaveInfo", function(k) if k == B.key then return info2 end; error("zedqa: only the stand-in is read here") end)
        if okS and okI then pcall(function() w:pickPlayer(B, { name = "Bob Baker", sqlID = 2 }) end) end
        K.unstub(_G, "getSaveInfo"); K.unstub(_G, "setSavefilePlayer1")
        if not (okS and okI) then skip("LJ11: [stub] Playing as writes the save's player 1", "setSavefilePlayer1 or getSaveInfo could not be stood in for")
        else
            check(rec[1] == "ZedQA,zedqa_LJ10,2" and B.who == "Bob Baker", "LJ11: [stub] Playing as writes setSavefilePlayer1 with the character's sqlID and reads the info again",
                "calls: " .. K.short(rec) .. "; now playing as " .. tostring(B.who))
        end
    end))
    -- LJ12: New player on a save that cannot be played (the real Play, its continueLatestSave stood in for)
    after(150, LD(function(w)
        local C = keep.fk.C
        w.sel = C.key; w.focusId = "save:" .. C.key
        local why = w:whyNot(C)
        local item = nil
        for _, it in ipairs(w:moreItems()) do if type(it) == "table" and it.text == ZeD.btnCase(getText("UI_LoadGameScreen_ButtonNewPlayer")) then item = it end end
        local rec = {}
        K.unstub(w, "play")
        local c0 = keep.conts
        local okS = K.stub(_G, "setSavefilePlayer1", function(mode, name, id) rec[#rec + 1] = tostring(id) end)
        if okS then pcall(function() w:newPlayer() end) end
        K.unstub(_G, "setSavefilePlayer1")
        K.stub(w, "play", X.playStub)
        if not okS then skip("LJ12: [stub] New player on an unplayable save", "setSavefilePlayer1 could not be stood in for"); return end
        local wrote = rec[1] == "-1"
        local played = keep.conts ~= c0
        check(why ~= nil and not wrote and not played and item ~= nil and item.disabled == true,
            "LJ12: [stub] New player on a save that cannot be played does not set a new character, and is greyed in More",
            "reason \"" .. tostring(why) .. "\"; setSavefilePlayer1 " .. (wrote and "called with -1" or "not called") .. "; Play " .. (played and "went on" or "not reached")
            .. "; New player " .. ((item and item.disabled) and "greyed" or "not greyed") .. " in More")
        K.capStart(w)
    end))
    -- LJ17: the can't-load note at this screen size
    after(300, LD(function(w)
        local list = K.capStop()
        local shown = K.capHas(list, getText("UI_worldscreen_SaveCannotBeLoaded"))
        note("LJ17: [stub] at " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. " the preview's can't-load note (last, no scroll, cut first at the box's foot) is "
            .. (shown and "drawn" or "NOT drawn") .. " for an unplayable stand-in; 1280x720 with Large text is not staged (the resolution is never changed)")
    end))
    -- LJ13: every can't-load reason and its order
    after(100, LD(function(w)
        local cur = IsoWorld.getWorldVersion()
        local function mk(wv, map, dead, mode, avail) return { key = "ZedQA/x", info = { worldVersion = wv, mapName = map }, dead = dead, mode = mode or "ZedQA", mapsAvailable = avail, zedqa = true } end
        local cases = {
            { mk(nil, "Muldraugh, KY", false, nil, true), "UI_mainscreen_SavefileNotFound", "no version" },
            { mk(cur, nil, false, nil, true), "UI_mainscreen_SavefileNotFound", "no map" },
            { mk(0, "Muldraugh, KY", false, nil, true), "UI_worldscreen_SavefileCorrupt", "version 0" },
            { mk(cur + 1, "Muldraugh, KY", false, nil, true), "UI_worldscreen_SavefileNewerThanGame", "newer" },
            { mk(200, "Muldraugh, KY", false, nil, true), "UI_worldscreen_SavefileOld", "200" },
            { mk(cur, "Muldraugh, KY", false, nil, false), "UI_worldscreen_MapNotFound", "map missing" },
            { mk(cur, "Muldraugh, KY", true, "A Really CD DA", true), "UI_worldscreen_SavefileCDDA", "dead CDDA" },
            { mk(cur, "Muldraugh, KY", true, "Sandbox", true), nil, "dead in Sandbox (playable)" },
            { mk(0, nil, true, "A Really CD DA", false), "UI_mainscreen_SavefileNotFound", "every fault at once (the first wins)" },
        }
        local bad = {}
        for _, c in ipairs(cases) do
            local ok, got = pcall(function() return w:whyNot(c[1]) end)
            local want = c[2] and getText(c[2]) or nil
            if not ok then bad[#bad + 1] = c[3] .. ": " .. tostring(got)
            elseif got ~= want then bad[#bad + 1] = c[3] .. ": \"" .. tostring(got) .. "\", wanted \"" .. tostring(want) .. "\"" end
        end
        check(#bad == 0, "LJ13: [stub] the can't-load reasons and their order are vanilla's (no version or map, 0, newer, 200 or older, map missing, dead CDDA)",
            (#bad == 0) and (#cases .. " cases") or K.short(bad))
        note("LJ14: the preview's Map row is MM.mapText: \"" .. tostring(MM.mapText("Riverside, KY;Rosewood, KY")) .. "\" for two maps, \""
            .. tostring(MM.mapText("Muldraugh, KY;Riverside, KY")) .. "\" when Muldraugh is in the list; a missing map reads only \""
            .. getText("UI_worldscreen_MapNotFound") .. "\", the map not named (vanilla lists each map, the missing ones red)")
        note("LJ15: Mods is one line cut to the box; no mods.txt and no mods both read \"" .. tostring(ZeD.tr("IGUI_None")) .. "\" (vanilla tells them apart); "
            .. "a stand-in with no mods list drew it: " .. tostring(keep.l15))
    end))
    -- LJ18: one click after the keys moved the pick off and back (Play stood in for)
    after(100, LD(function(w)
        local A, B = keep.fk.A, keep.fk.B
        w._lastClick = nil; w._lastClickKey = nil; w._enterAt = nil
        local p0 = keep.plays
        local moved, back = nil, nil
        pcall(function()
            w:clickSave(B)
            w:keyOther(Keyboard.KEY_DOWN)
            moved = w.sel
            w:keyOther(Keyboard.KEY_UP)
            back = w.sel
            w:clickSave(B)
        end)
        local played = keep.plays - p0
        w._lastClick = nil
        -- (two clicks with no move between still play: Play stood in for)
        local p1 = keep.plays
        pcall(function() w:clickSave(B); w:clickSave(B) end)
        local twice = keep.plays - p1
        w._lastClick = nil; w._lastClickKey = nil
        if moved == nil or moved == B.key then skip("LJ18: [stub] a click after a key move is not a double click", "the arrow key did not move the pick off the stand-in")
        else
            check(played == 0 and twice == 1, "LJ18: [stub] one click after the keys moved the pick off and back is a pick, not a double click; two clicks with no move still play",
                "the keys moved the pick to " .. tostring(moved) .. " and back to " .. tostring(back) .. "; Play (stood in for) reached " .. played .. " time(s), then " .. twice .. " for a plain double click")
        end
        -- LJ30: the mode heads are controller rows (A folds, the pick stays); the arrow keys step over them
        local hid = "head:ZedQA"
        local hs = K.spec(w, hid)
        local headHits, others = 0, {}
        for _, h in ipairs(w._hits or {}) do if tostring(h.id):find("load:head:", 1, true) then headHits = headHits + 1 end end
        for _, r in ipairs(w.view or {}) do if r.head and not K.spec(w, "head:" .. tostring(r.mode)) then others[#others + 1] = tostring(r.mode) end end
        local folded, sel0, kept = false, w.sel, false
        if hs and hs.fn then
            w.focusId = hid
            pcall(hs.fn)
            folded = w.collapsed["ZedQA"] == true
            pcall(hs.fn)
            kept = not w.collapsed["ZedQA"]
        end
        -- (Up from the group's first save stays on it, never on its head)
        local first = nil
        for _, r in ipairs(w.view or {}) do if r.save and r.save.mode == "ZedQA" and not first then first = r.save.key end end
        local upOk = false
        if first then
            w.sel = first; w.focusId = "save:" .. first
            pcall(function() w:keyOther(Keyboard.KEY_UP) end)
            upOk = w.sel == first and string.sub(tostring(w.focusId), 1, 5) ~= "head:"
        end
        check(hs ~= nil and #others == 0 and folded and kept and upOk,
            "LJ30: [stub] every mode head is a controller row (head:<mode>) whose A folds and unfolds the group; the arrow keys step over the heads",
            "head stop " .. tostring(hs and hs.id) .. ", heads with no stop: " .. ((#others > 0) and K.short(others) or "none") .. "; A folded " .. tostring(folded) .. ", unfolded " .. tostring(kept)
            .. "; Up from the first save left the hand on " .. tostring(w.focusId) .. " (" .. headHits .. " mouse click boxes on heads)")
        if sel0 then w.sel = sel0; w.focusId = "save:" .. sel0 end
    end))
    -- LJ6: a real save whose getSaveInfo throws (the stand-ins go with this read)
    after(150, LD(function(w)
        local real, n0 = nil, 0
        for _, s in ipairs(w.saves) do if not s.zedqa then n0 = n0 + 1; real = real or s end end
        if not real then
            pcall(function() w:readSaves(); w:filter() end)
            skip("LJ6: [stub] a save whose getSaveInfo throws", "no real save here (the stand-in wraps getSaveInfo for one real folder)")
            return
        end
        local target = real.key
        local orig = getSaveInfo
        local okS = K.stub(_G, "getSaveInfo", function(k) if k == target then error("zedqa: this save's info throws") end; return orig(k) end)
        local okR, err = false, nil
        -- (the stand-in throws on purpose; ZeD's readSaves catches it, and a -debug run counts a caught error too:
        -- those are taken off the Lua error count, with a note below)
        local e0 = K.errs()
        if okS then okR, err = pcall(function() w:readSaves() end) end
        K.unstub(_G, "getSaveInfo")
        local e1 = K.errs()
        if e0 and e1 and keep.errs and e1 > e0 then
            keep.errs = keep.errs + (e1 - e0)
            note("LJ6: the stand-in's own " .. (e1 - e0) .. " thrown error(s) (\"zedqa: this save's info throws\", caught by ZeD) are left out of the Lua error count")
        end
        local n1, still = #w.saves, false
        for _, s in ipairs(w.saves) do if s.key == target then still = true end end
        pcall(function() w:readSaves(); w:filter() end)
        if not okS then skip("LJ6: [stub] a save whose getSaveInfo throws", "getSaveInfo could not be stood in for"); return end
        check(okR and n1 == n0 - 1 and not still, "LJ6: [stub] a save whose getSaveInfo throws is left out of the list, with no error",
            "read " .. tostring(okR) .. (err and (" (" .. tostring(err) .. ")") or "") .. ", " .. n1 .. " rows of " .. n0)
        note("LJ6: vanilla's list keeps such a save (LGS:449-463); ZeD leaves it out without a word")
    end))
    after(200, LD(function(w)
        pcall(function() w:readSaves(); w:filter() end)
        local fakes = 0
        for _, s in ipairs(w.saves) do if s.zedqa then fakes = fakes + 1 end end
        check(fakes == 0 and X.saveKeys(w) == keep.saves0, "PUTBACK: Load game: the stand-ins gone, the saves the ones found (none deleted, none renamed)", #w.saves .. " saves")
        K.unstub(w, "play")
        K.unstub(MainScreen, "continueLatestSave")
        check(keep.conts == 0, "PUTBACK: Load game: no save was played (continueLatestSave stood in for and never reached)", keep.conts .. " calls")
        w.collapsed = {}
        for k, v in pairs(keep.coll0 or {}) do w.collapsed[k] = v end
        w:filter()
        K.errCheck("LJ6-LJ18: Load game, the stand-ins")
    end))
end

-- 4: an invite with Load up, under -nosteam: Connect to (LJ3, LJ53, LJ54, LJ55)
function X.invite()
    after(200, function()
        keep.noInv = nil
        if getSteamModeActive() then
            keep.noInv = true
            for _, id in ipairs({ "LJ3: an invite mid-flow", "LJ53: Connect to's fill from a saved server", "LJ54: Connect to's fields and the keyboard", "LJ55: Connect to's height" }) do
                skip(id, "a Steam launch: an invite asks Steam about the server (staged under -nosteam only)")
            end
            if K.up("load") then pcall(function() K.win("load"):back() end) end
            return
        end
        keep.invFrom = MM.view
        local addr = "127.0.0.1:16261"
        keep.invSaved = nil
        pcall(function()
            local l = getServerList()
            if l and l[1] and l[1]:getIp() and tostring(l[1]:getIp()) ~= "" and not tostring(l[1]:getIp()):find(":", 1, true) then
                addr = tostring(l[1]:getIp()) .. ":" .. tostring(l[1]:getPort()); keep.invSaved = l[1]
            end
        end)
        K.try("LJ3: an invite accepted with " .. tostring(MM.view) .. " up", function() MainScreen.onAcceptInvite("+connect " .. addr) end)
    end)
    waitFor(function() return keep.noInv or K.up("srvform") end, 4000, function(met)
        if keep.noInv then return end
        if met then
            note("LJ3: an invite accepted with the " .. tostring(keep.invFrom) .. " view up replaced it with Connect to: vanilla refuses an invite unless its main menu shows (MS:2061-2063), and ZeD shows the bottom panel on every view")
        else
            check(false, "LJ3: an invite accepted mid-flow puts up Connect to", "view " .. tostring(MM.view))
            keep.noInv = true
            K.rescue()
        end
    end)
    after(300, V("srvform", "noInv", "LJ3", function(w)
        K.onScreen("LJ55: Connect to", w)
        local L = MM.layout()
        check(w:getHeight() <= L.th, "LJ55: Connect to (470 units) fits the monitor's screen at this size",
            math.floor(w:getHeight()) .. " tall in a screen " .. math.floor(L.th) .. " tall (" .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. ")")
        note("LJ55: 1280x720 and 1280x800 are not staged: the resolution is never changed here")
        -- LJ53: ZeD's fields start as vanilla's (setServer's fill)
        local p = K.ms().serverConnectPopup
        local function t(e) local v = ""; pcall(function() v = tostring(e.getInternalText and e:getInternalText() or e:getText() or "") end); return v end
        local same = t(w.fSrvPwd) == t(p.serverPasswordEntry) and t(w.fUser) == t(p.usernameEntry) and t(w.fPwd) == t(p.passwordEntry)
        check(same, "LJ53: Connect to's fields start as vanilla's own (its setServer fill)", "user field " .. ((t(w.fUser) ~= "") and "filled" or "empty") .. ", password field " .. string.len(t(w.fPwd)) .. " characters")
        if keep.invSaved then
            local held = 0
            pcall(function() held = string.len(tostring(keep.invSaved:getPwd() or "")) end)
            note("LJ53: on the first saved server's address the password field holds " .. string.len(t(w.fPwd)) .. " characters (the saved account " .. held
                .. "): vanilla fills it from the saved server (a stored hash) and connects with doHash true (SCP:205-206), so a saved password is hashed again (vanilla's)")
        else
            note("LJ53: no saved server here: Connect to on 127.0.0.1:16261 starts empty; the fill from a saved server is not seen")
        end
        -- LJ54: A on a field, a controller stood in for
        local sp = K.spec(w, "field:1")
        if not (sp and sp.fn) then skip("LJ54: Connect to's fields and the keyboard", "no field stop drawn"); return end
        local rec = {}
        local mark0 = #keep.stubs
        local jd = { player = 0 }
        K.stub(JoypadState, "getMainMenuJoypad", function() return jd end)
        if OnScreenKeyboard then K.stub(OnScreenKeyboard, "Show", function() rec[#rec + 1] = "the game's on-screen keyboard"; return nil end) end
        if ZeD.Keyboard then K.stub(ZeD.Keyboard, "edit", function() rec[#rec + 1] = "ZeD's pad keyboard"; return true end) end
        MM.forceGamepad = true
        pcall(sp.fn)
        MM.forceGamepad = keep.pad0
        K.unstubFrom(mark0)
        pcall(function() for _, e in ipairs(w._fields) do if e:isFocused() then e:unfocus() end end end)
        note("LJ54: [stub] A on a Connect to field asks " .. (rec[1] or "no keyboard (it focused the field)") .. "; the other menu fields open ZeD's pad keyboard (MM.typeIn)")
    end))
    after(250, V("srvform", "noInv", "LJ3", function(w) K.try("LJ3: Connect to cancelled", function() w:cancel() end) end))
    waitFor(function() return keep.noInv or MM.view == "main" end, 3000, function(met)
        if keep.noInv then return end
        check(met, "LJ3: Cancel on Connect to leaves to the main window", "view " .. tostring(MM.view))
        if not met then K.rescue() end
        K.errCheck("LJ3: the invite")
    end)
end

-- =========================================================================================================
-- 5: Join, the real lists (nothing saved)
function X.joinOpen()
    after(200, function()
        keep.noJoin = nil
        if MM.view ~= "main" then K.rescue() end
        local m = K.ms() and K.ms().multiplayer
        keep.mp = m
        keep.rl, keep.rq = 0, 0
        if m then
            K.stub(m, "refreshList", function(self, ...) keep.rl = keep.rl + 1; return MultiplayerUI.refreshList(self, ...) end)
            K.stub(m, "requestServerList", function(self, ...) keep.rq = keep.rq + 1; return MultiplayerUI.requestServerList(self, ...) end)
        end
        K.try("LJ1: Join opened as its button does", MM.act.join)
    end)
    waitFor(function() return K.up("join") end, 5000, function(met)
        if not check(met, "LJ1: Join comes up (view join)", "view " .. tostring(MM.view)) then keep.noJoin = true; K.rescue() end
    end)
    after(300, JN(function(w)
        local m = keep.mp
        K.unstub(m, "requestServerList"); K.unstub(m, "refreshList")
        check(m ~= nil and m.created and keep.rl >= 1 and keep.rq >= 1, "LJ32: opening Join refreshes the saved list and asks for the public one",
            "refreshList " .. keep.rl .. ", requestServerList " .. keep.rq .. (getSteamModeActive() and " (Steam)" or " (-nosteam: the master list)"))
        K.onScreen("LJ32: Join", w)
        keep.gsl = 0; keep.gf0 = keep.frames
        local orig = getServerList
        if not K.stub(_G, "getServerList", function(...) keep.gsl = keep.gsl + 1; return orig(...) end) then keep.gsl = nil end
    end))
    after(1000, JN(function(w)
        K.unstub(_G, "getServerList")
        local f = keep.frames - (keep.gf0 or keep.frames)
        if keep.gsl == nil then skip("LJ45: getServerList per frame (perf)", "getServerList could not be stood in for")
        else
            check(f > 0 and keep.gsl > 0, "LJ45: getServerList runs while Join is up (perf)", keep.gsl .. " calls in " .. f .. " frames, " .. K.per(keep.gsl, f) .. " a frame")
            if f > 0 and keep.gsl >= f * 2 then note("LJ45: getServerList runs about " .. K.per(keep.gsl, f) .. " times a frame (the title and the status line); vanilla reads it on a refresh only (MPUI:869)") end
        end
        K.try("LJ36: the Public tab", function() w:setTab("public") end)
    end))
    after(400, JN(function(w)
        -- (each click box join:flt:<f>, join:streamer and join:sort:<col> wants its stop tick:flt:<f>, tick:streamer, sort:<col>)
        local hits, missing = {}, {}
        for _, h in ipairs(w._hits or {}) do
            local id = tostring(h.id)
            local want = nil
            if id:find("join:flt:", 1, true) == 1 or id == "join:streamer" then want = "tick:" .. string.sub(id, 6)
            elseif id:find("join:sort:", 1, true) == 1 then want = string.sub(id, 6) end
            if want then
                hits[#hits + 1] = id
                local sp = K.spec(w, want)
                if not (sp and sp.fn) then missing[#missing + 1] = want end
            end
        end
        if #hits == 0 then skip("LJ36: the pad reaches the Public filters, sort heads and Streamer mode", "none of them drew on the Public tab")
        else check(#missing == 0, "LJ36: the pad reaches every Public filter, sort head and Streamer mode (tick:<id>, sort:<col>; none pressed)",
            #hits .. " click boxes" .. ((#missing > 0) and (", no controller stop for " .. K.short(missing)) or ", each with its stop")) end
        if not getDebug() then skip("LJ42: in debug, the Refresh label against requestServerList's wait", "not a debug launch")
        else
            local since = getTimestamp() - (MultiplayerUI.startRefreshTime or 0)
            local wait = w:refreshWait()
            check(not (wait == 0 and since <= 60), "LJ42: in debug, Refresh turns live only when requestServerList will run",
                "the label waits " .. tostring(wait) .. " s, " .. tostring(since) .. " s since the last ask (vanilla's request waits 60 s)" .. ((since > 60) and "; past 60 s both are live, the gap not seen" or ""))
        end
        K.try("LJ35: the Saved tab", function() w:setTab("saved") end)
    end))
    -- LJ35 / LJ43: the server form (Streamer mode set in memory only, never its option)
    after(300, JN(function(w)
        local tb = keep.mp and keep.mp.showIPAddressesTickBox
        keep.strTick = tb
        keep.str0 = tb and tb.selected[1]
        if tb then tb.selected[1] = true end
        K.try("LJ35: the Add server form", function() w:openServerForm(nil) end)
    end))
    after(300, JN(function(w)
        local mA, mP = nil, nil
        pcall(function() mA = w.fAddr:isMasked(); mP = w.fPort:isMasked() end)
        local tb = keep.strTick
        if tb then tb.selected[1] = keep.str0 end
        local opt = nil
        pcall(function() opt = getCore():getOptionStreamerMode() end)
        check(mA and mP and true or false, "LJ35: with Streamer mode on, the server form masks the address and the port (as vanilla's ES:28, 38)",
            "address masked " .. tostring(mA) .. ", port masked " .. tostring(mP) .. " (the Streamer tick set in memory only; the option itself " .. tostring(opt) .. ")")
        -- (QA, Nov 27 2026: a masked field reads back as stars, so LJ43 reads the port with the mask off)
        pcall(function() w.fAddr:setMasked(false); w.fPort:setMasked(false) end)
        local def = tostring(w.fPort:getText() or "")
        w.fPort:setText("99999999")
        local p = w:serverProblems()
        check(def == "16261" and p.port == nil, "LJ43: the port reads 16261 by default and has no range check", "default " .. def .. ", 99999999 gives " .. tostring(p.port))
        note("LJ43: no range check on the port, as before (Build's note); the save's fallback port is checked on a stand-in server below")
        K.try("LJ43: the form shut", function() w:closeForm() end)
        K.errCheck("LJ32-LJ45: Join, the real lists")
    end))
end

-- 6: Join with stand-in servers and accounts (Server.new, Account.new: never in the saved list; every list write
-- stood in for while they are up)
function F.server(name, ip, port)
    local sv = Server.new()
    sv:setName(name); sv:setIp(ip); sv:setPort(port)
    return sv
end
function F.account(user)
    local a = Account.new()
    a:setUserName(user)
    return a
end
function F.key(sv) return tostring(sv:getIp()) .. ":" .. tostring(sv:getPort()) end
function X.joinFakes()
    after(200, JN(function(w)
        local m = keep.mp
        local J = {}
        keep.J = nil
        local okB, e = pcall(function()
            J.A = F.server("ZedQA A", "203.0.113.31", 16261)
            J.B = F.server("ZedQA B", "203.0.113.32", 16261)
            J.accA = F.account("zedqa_a"); J.accB = F.account("zedqa_b")
            J.One = F.server("ZedQA one account", "203.0.113.41", 16261)
            J.accOne = F.account("zedqa_one")
            -- (an account added to a stand-in's own list; LJ41 and LJ40 read the size back and skip when it did not take)
            pcall(function() J.One:getAccounts():add(J.accOne) end)
            J.C1 = F.server("ZedQA C one", "203.0.113.44", 16261)
            J.C2 = F.server("ZedQA C two", "203.0.113.44", 16261)
            J.D = F.server("ZedQA details", "203.0.113.46", 16261)
            J.dOk = pcall(function()
                J.D:setDescription("Line one<LINE><RGB:1,0,0>Line two")
                J.D:setMods("ModA;ModB")
                J.D:setLastWipe(getTimestamp() - 86400 * 3)
            end)
            J.Sv2 = F.server("ZedQA two accounts", "203.0.113.40", 16261)
            pcall(function() J.Sv2:getAccounts():add(F.account("zedqa_x")); J.Sv2:getAccounts():add(F.account("zedqa_y")) end)
            J.Pub = F.server("ZedQA public", "203.0.113.40", 16261)
            J.Lock = F.server("ZedQA locked", "203.0.113.47", 16261)
            J.lockOk = pcall(function() J.Lock:setPasswordProtected(true) end)
        end)
        if not okB then keep.noFake = "the stand-ins could not be made: " .. tostring(e); return end
        -- LJ44: the two servers on one address (C1, C2, one account each) get their rows from ZeD's own savedRows, read
        -- over a stand-in account list (m.accountList swapped for this one call and put back at once)
        J.accC1 = F.account("zedqa_c"); J.accC2 = F.account("zedqa_c")
        J.cRows = nil
        local items = { { item = { type = "server", server = J.C1 } }, { item = { type = "account", server = J.C1, account = J.accC1 } },
                        { item = { type = "server", server = J.C2 } }, { item = { type = "account", server = J.C2, account = J.accC2 } } }
        local mk = #keep.stubs
        if K.stub(m, "accountList", { items = items }) then
            local okR, rr = pcall(function() return ZeD_MMJoin.savedRows(w) end)
            if okR then J.cRows = rr end
        end
        K.unstubFrom(mk)
        local c = J.cRows or {}
        J.rows = {
            { kind = "server", key = "s:" .. F.key(J.A), server = J.A, h = 46 },
            { kind = "account", key = "a:" .. F.key(J.A) .. ":zedqa_a", server = J.A, account = J.accA, h = 42 },
            { kind = "server", key = "s:" .. F.key(J.B), server = J.B, h = 46 },
            { kind = "account", key = "a:" .. F.key(J.B) .. ":zedqa_b", server = J.B, account = J.accB, h = 42 },
            { kind = "server", key = "s:" .. F.key(J.One), server = J.One, h = 46 },
            c[1] or { kind = "server", key = "s:" .. F.key(J.C1), server = J.C1, h = 46 },
            c[3] or { kind = "server", key = "s:" .. F.key(J.C2), server = J.C2, h = 46 },
            { kind = "server", key = "s:" .. F.key(J.D), server = J.D, h = 46 },
        }
        -- (LJ40: the public server's saved twin with its two accounts, keyed as savedRows keys them)
        local ax, ay = nil, nil
        pcall(function() if J.Sv2:getAccounts():size() == 2 then ax = J.Sv2:getAccounts():get(0); ay = J.Sv2:getAccounts():get(1) end end)
        if ax and ay then
            J.rows[#J.rows + 1] = { kind = "server", key = "s:" .. F.key(J.Sv2), server = J.Sv2, h = 46 }
            J.rows[#J.rows + 1] = { kind = "account", key = "a:" .. F.key(J.Sv2) .. ":zedqa_x", server = J.Sv2, account = ax, h = 42 }
            J.rows[#J.rows + 1] = { kind = "account", key = "a:" .. F.key(J.Sv2) .. ":zedqa_y", server = J.Sv2, account = ay, h = 42 }
        end
        keep.jMark = #keep.stubs
        keep.jrec = {}
        local function rec(what) return function() keep.jrec[#keep.jrec + 1] = what end end
        local all = true
        for _, g in ipairs({ "addServerToAccountList", "updateServerToAccountList", "deleteServerToAccountList", "addAccountToAccountList", "updateAccountToAccountList", "deleteAccountToAccountList" }) do
            if not K.stub(_G, g, rec(g)) then all = false end
        end
        if not all then
            K.unstubFrom(keep.jMark)
            keep.noFake = "a saved-list write could not be stood in for"
            return
        end
        K.stub(m, "connectToServer", rec("MultiplayerUI.connectToServer"))
        if ConnectToServer and ConnectToServer.instance then K.stub(ConnectToServer.instance, "connect", rec("ConnectToServer.connect")) end
        K.stub(m, "onSelectInternetServer", function(self, sv) self.selectedInternetServer = sv end)
        K.stub(w, "connectAccount", function(self, sv, acc) keep.jrec[#keep.jrec + 1] = "connect " .. tostring(sv and sv:getName()) end)
        K.stub(w, "savedRows", function(self)
            local rows = {}
            for _, r in ipairs(J.rows) do rows[#rows + 1] = r end
            for _, r in ipairs(ZeD_MMJoin.savedRows(self)) do rows[#rows + 1] = r end
            return rows
        end)
        keep.J = J
        w.tab = "saved"; w.scroll = 0
        w.sel = "s:" .. F.key(J.D)
        K.capStart(w)
    end))
    after(300, JN(function(w)
        local list = K.capStop()
        local J = keep.J
        if not J then
            local why = keep.noFake or "the stand-ins did not start"
            for _, id in ipairs({ "LJ33", "LJ34", "LJ38", "LJ39", "LJ40", "LJ41", "LJ44", "LJ46", "LJ47", "LJ36: the account form's ticks", "LJ37", "LJ25: Join's band field", "LJ43: the port's fallback on save" }) do skip(id .. ": the Join stand-ins", why) end
            return
        end
        -- LJ46: the details pane
        local bad = {}
        local pw = K.capNext(list, ZeD.textCase(ZeD.trBare("UI_servers_password")))
        local wl = K.capNext(list, ZeD.tr("UI_ZeD_Join_KvWhitelist"))
        if pw ~= "-" then bad[#bad + 1] = "Password reads " .. tostring(pw) end
        if wl ~= "-" then bad[#bad + 1] = "Whitelist reads " .. tostring(wl) end
        if not (K.capHas(list, "Line one") and K.capHas(list, "Line two")) then bad[#bad + 1] = "the description lines not drawn" end
        if K.capHas(list, "<RGB") or K.capHas(list, "<LINE>") then bad[#bad + 1] = "a tag left in the description" end
        if not K.capHas(list, "ModA, ModB") then bad[#bad + 1] = "the mods not listed as ModA, ModB" end
        if not K.capHas(list, getText("UI_servers_wipe_days_ago", 3)) then bad[#bad + 1] = "the last wipe not in days" end
        if not J.dOk then skip("LJ46: [stub] the details pane", "the stand-in server would not take a description, mods or a last wipe")
        else
            check(#bad == 0, "LJ46: [stub] details: Password and Whitelist \"-\" until the server answers, the last wipe in days, the description's tags stripped, the mods listed",
                (#bad == 0) and "a stand-in server, never asked" or K.short(bad))
        end
        -- LJ44: two saved servers on one address, keyed by ZeD's own savedRows (read over a stand-in list, set up above)
        local cr = J.cRows
        if not (cr and #cr == 4) then
            check(false, "LJ44: [stub] two saved servers on one address each get their own rows", "savedRows over the stand-in list gave " .. tostring(cr and #cr) .. " rows")
        else
            local k1, k2, ka2 = cr[1].key, cr[3].key, cr[4].key
            local base = F.key(J.C1)
            w.sel = k2
            local r = w:selectedRow(w:savedRows())
            -- (Remove asked on the second: its question keeps the second; Cancel, never pressed)
            w._lastClick = nil
            w:setConfirm("delServer")
            local target = w._cRow
            w:setConfirm(false)
            w.sel = ka2
            local ra = w:selectedRow(cr)
            check(k1 == "s:" .. base and k2 == "s:" .. base .. "#2" and ka2 == "a:" .. base .. "#2:zedqa_c" and cr[4].server == J.C2
                and r ~= nil and r.server == J.C2 and target ~= nil and target.server == J.C2 and ra ~= nil and ra.account == J.accC2,
                "LJ44: [stub] two saved servers on one address get their own rows (the second keyed #2, its account under it): the second can be picked and Remove asks on it",
                "keys " .. tostring(k1) .. ", " .. tostring(k2) .. ", " .. tostring(ka2) .. "; the pick lands on \"" .. tostring(r and r.server:getName()) .. "\"; Remove's target \""
                .. tostring(target and target.server and target.server:getName()) .. "\"")
        end
        -- LJ33: a click on another row while Remove asks
        w.sel = nil
        w._lastClick = nil
        w:pick(J.rows[1])
        w:setConfirm("delServer")
        local t0 = w._cRow
        w._lastClick = nil
        w:pick(J.rows[3])
        local moved = w.sel == J.rows[3].key
        local kept = w._cRow == J.rows[1] and t0 == J.rows[1]
        check(not moved and kept, "LJ33: [stub] a click on another row while Remove asks does not change what Remove removes (the question keeps its row)",
            (moved and "the pick moved to \"ZedQA B\" under the question opened on \"ZedQA A\" (Remove never pressed)" or "the pick stayed on the server asked about")
            .. "; the question's row " .. tostring(w._cRow and w._cRow.key))
        w:setConfirm(false)
        -- LJ34: a double click (and A) on another account under the password question
        w._pwdFor = { server = J.A, account = J.accA }
        w:setConfirm("pwd")
        local n0 = #keep.jrec
        w._lastClick = nil
        w:pick(J.rows[4]); w:pick(J.rows[4])
        pcall(function() w:connectOrOpen(J.rows[4]) end)
        local got = #keep.jrec - n0
        check(got == 0, "LJ34: [stub] under the password question neither a double click nor A on another account connects it",
            (got > 0) and ("it reached " .. tostring(keep.jrec[#keep.jrec]) .. " (connect stood in for)") or "no connect")
        w:setConfirm(false)
        w._lastClick = nil
    end))
    after(250, JN(function(w)
        local J = keep.J
        if not J then return end
        local m = keep.mp
        -- LJ41: A against a double click on a saved server with one account
        local rOne = J.rows[5]
        local sp = nil
        for _, s in ipairs(w._specs or {}) do if s.rowRef == rOne then sp = s end end
        local nAcc = 0
        pcall(function() nAcc = J.One:getAccounts():size() end)
        if not sp or nAcc ~= 1 then skip("LJ41: [stub] A against a double click on a saved server", "the one-account stand-in did not draw (" .. nAcc .. " accounts)")
        else
            local n0 = #keep.jrec
            w._lastClick = nil
            pcall(sp.fn)
            local a = #keep.jrec - n0
            w._lastClick = nil
            w:pick(rOne); w:pick(rOne)
            local d = #keep.jrec - n0 - a
            w._lastClick = nil
            check(a == 0 and d == 1 and w.sel == rOne.key, "LJ41: [stub] A on a saved server with one account only picks it; a mouse double click connects it (connect stood in for)",
                "A: " .. a .. " connect(s), double click: " .. d)
        end
        -- LJ40: a public server saved with two accounts
        local n2 = 0
        pcall(function() n2 = J.Sv2:getAccounts():size() end)
        if n2 ~= 2 then skip("LJ40: [stub] Connect on a public server saved with several accounts", "the two-account stand-in has " .. n2)
        else
            local n0 = #keep.jrec
            K.stub(m, "getServerFeatured", function(self, sv)
                if sv == J.Pub then return { type = "server", server = J.Sv2 } end
                return MultiplayerUI.getServerFeatured(self, sv)
            end)
            w.tab = "public"; w.focusId = nil
            pcall(function() w:connectPublic(J.Pub) end)
            local tab, sel, foc = w.tab, w.sel, w.focusId
            K.unstub(m, "getServerFeatured")
            local wantSel = "a:" .. F.key(J.Sv2) .. ":zedqa_x"
            local wantFoc = nil
            for i, rr in ipairs(w:savedRows()) do if rr.key == wantSel and not wantFoc then wantFoc = "row:" .. i end end
            local conns = #keep.jrec - n0
            check(tab == "saved" and sel == wantSel and wantFoc ~= nil and foc == wantFoc and conns == 0,
                "LJ40: [stub] Connect on a public server saved with two accounts lands on Saved with its first account picked and the hand on it (nothing connected)",
                "tab " .. tostring(tab) .. ", pick " .. tostring(sel) .. ", hand " .. tostring(foc) .. " (wanted " .. tostring(wantFoc) .. "), connects " .. conns)
            -- (saved with no account: the account form, connecting when saved; closed, nothing saved)
            K.stub(m, "getServerFeatured", function(self, sv)
                if sv == J.Pub then return { type = "server", server = J.C1 } end
                return MultiplayerUI.getServerFeatured(self, sv)
            end)
            local n1 = #keep.jrec
            w.tab = "public"
            pcall(function() w:connectPublic(J.Pub) end)
            K.unstub(m, "getServerFeatured")
            local f = w.form
            local formOk = f ~= nil and f.account == nil and f.connectAfter == true
            local nC1 = -1
            pcall(function() nC1 = J.C1:getAccounts():size() end)
            if nC1 ~= 0 then skip("LJ40: [stub] Connect on a public server saved with no account", "the stand-in C1 has " .. nC1 .. " accounts")
            else
                check(w.page == "account" and f ~= nil and f.server == J.C1 and formOk and #keep.jrec == n1,
                    "LJ40: [stub] Connect on a public server saved with no account opens the account form for it (closed, nothing saved)",
                    "page " .. tostring(w.page) .. ", form for " .. tostring(f and f.server and f.server:getName()) .. ", connect after " .. tostring(formOk) .. ", writes " .. (#keep.jrec - n1))
            end
            pcall(function() if w.page ~= "list" then w:closeForm() end end)
            note("LJ40: a new account made from Connect on a public server is not kept on the saved server (Build's known gap; not saved here)")
            w.tab = "saved"
        end
        -- LJ47: Save on a locked public server (the list write stood in for)
        keep.l25j = false
        if not J.lockOk then skip("LJ47: [stub] saving a locked public server asks its password first", "the stand-in would not take a password lock"); return end
        local n0 = #keep.jrec
        pcall(function() w:saveServer(J.Lock) end)
        local asked = w.confirm == "srvpwd" and w._srvPwdFor ~= nil and w._srvPwdFor.after == "save"
        check(asked and #keep.jrec == n0, "LJ47: [stub] saving a locked public server asks its password first (nothing saved)",
            "question " .. tostring(w.confirm) .. ", list writes " .. (#keep.jrec - n0))
        keep.l25j = asked
    end))
    after(300, JN(function(w)
        local J = keep.J
        if not J then return end
        -- LJ25: Join's band password field
        if keep.l25j and w.field:isVisible() then
            local h = nil
            pcall(function() h = K.hitOn(w, w.field) end)
            local stop = K.spec(w, "field:band")
            check(h ~= nil and h.id == "join:f:band", "LJ25: Join's band password field has a click box that focuses it (join:f:band)",
                h and tostring(h.id) or ("no click box over it (it has the controller stop " .. tostring(stop and stop.id) .. ")"))
        else
            skip("LJ25: Join's band password field has a click box", "the server password question did not open")
        end
        w:setConfirm(false)
        -- LJ43: a port that is not a number saves as 16261, the form's own default (a stand-in server, the field
        -- checks stood in for so the fallback is reached; its list write stood in for)
        local svP = nil
        pcall(function() svP = F.server("ZedQA port", "203.0.113.48", 16999) end)
        if not svP then skip("LJ43: [stub] the port's fallback on save", "the stand-in server could not be made")
        else
            local n0p = #keep.jrec
            local okP, eP = pcall(function()
                w:openServerForm(svP)
                w.fPort:setText("")
                K.stub(w, "serverProblems", function() return {} end)
                w:saveServerForm()
            end)
            K.unstub(w, "serverProblems")
            pcall(function() if w.page ~= "list" then w:closeForm() end end)
            local port = nil
            pcall(function() port = svP:getPort() end)
            local wrote = keep.jrec[n0p + 1]
            check(okP and tonumber(port) == 16261 and wrote == "updateServerToAccountList", "LJ43: [stub] a port that reads as no number saves as 16261, the port the form offers (never 16262)",
                (okP and "" or (tostring(eP) .. "; ")) .. "saved port " .. tostring(port) .. ", list write " .. tostring(wrote) .. " (stood in for)")
            w.sel = nil; w.tab = "saved"
        end
        -- LJ38: editing an account (the list write stood in for)
        local acc = F.account("zedqa_edit")
        local okA = pcall(function() acc:encryptPwd("zedqa-pass"); acc:setSavePwd(true) end)
        local pwd0 = ""
        pcall(function() pwd0 = tostring(acc:getPwd() or "") end)
        local n0 = #keep.jrec
        local kept, auth1, cleared = false, false, false
        local okE, e = pcall(function()
            w:openAccountForm(J.A, acc, false)
            w.fUser:setText("zedqa_edit"); w.fPwd:setText("")
            w:saveAccountForm()
            kept = pwd0 ~= "" and tostring(acc:getPwd() or "") == pwd0
            auth1 = acc:getAuthType() == 1
            w:openAccountForm(J.A, acc, false)
            w.form.remember = false
            w.fUser:setText("zedqa_edit"); w.fPwd:setText("")
            w:saveAccountForm()
            cleared = tostring(acc:getPwd() or "") == "" and not acc:isSavePwd()
        end)
        local writes = {}
        for i = n0 + 1, #keep.jrec do writes[#writes + 1] = keep.jrec[i] end
        pcall(function() if w.page ~= "list" then w:closeForm() end end)
        if not okA then skip("LJ38: [stub] editing an account", "the stand-in account could not take a password")
        else
            check(okE and kept and auth1 and cleared, "LJ38: [stub] editing an account: an empty password keeps the saved one, Remember off clears it, authType 1",
                (okE and "" or (tostring(e) .. "; ")) .. "kept " .. tostring(kept) .. ", authType 1 " .. tostring(auth1) .. ", cleared " .. tostring(cleared) .. "; list writes stood in for: " .. K.short(writes))
        end
        -- LJ39 / LJ36 / LJ37: a public server's new-account form
        K.try("LJ39: a public server's new-account form", function()
            w:openAccountForm(J.Pub, nil, true)
            w.fUser:setText("zedqa_new"); w.fPwd:setText("")
        end)
    end))
    after(300, JN(function(w)
        local J = keep.J
        if not J then return end
        local rem, relay = false, false
        for _, h in ipairs(w._hits or {}) do
            if h.id == "join:remember" then rem = true end
            if h.id == "join:relay" then relay = true end
        end
        local sRem, sRelay = K.spec(w, "tick:remember"), K.spec(w, "tick:relay")
        note("LJ39: a public server's new account (connect after, never kept) still shows Remember password: " .. tostring(rem))
        if not rem then skip("LJ36: the pad reaches Remember password on the account form", "the tick did not draw")
        else
            check(sRem ~= nil and sRem.fn ~= nil and ((not relay) or sRelay ~= nil), "LJ36: the pad reaches Remember password (tick:remember; and Use Steam relay, tick:relay, on Steam) on the account form",
                "remember " .. tostring(sRem and sRem.id) .. (relay and (", relay " .. tostring(sRelay and sRelay.id)) or ", relay not drawn (not Steam)"))
        end
        local p = {}
        pcall(function() p = w:accountProblems() end)
        note("LJ37: a new account with an empty password is refused: \"" .. tostring(p.pwd) .. "\" (vanilla's form allows none, EA:248-257)")
        pcall(function() w:closeForm() end)
    end))
    after(200, JN(function(w)
        local m = keep.mp
        if keep.jMark then K.unstubFrom(keep.jMark) end
        if keep.J then
            note("LJ33-LJ47: the saved-list writes and connects the stand-ins reached, all stood in for: " .. ((#keep.jrec > 0) and K.short(keep.jrec) or "none"))
        end
        keep.J = nil
        pcall(function() m.selectedInternetServer = nil end)
        w.sel = nil; w.tab = "saved"; w.scroll = 0; w._lastClick = nil
        pcall(function() m:refreshList() end)
        K.errCheck("LJ33-LJ47: Join, the stand-ins")
    end))
end

-- 7: Connecting, the game's screen shown with no connection asked (LJ48, LJ49)
function X.connecting()
    after(200, function()
        local c = K.ms() and K.ms().connectToServer
        keep.cts = c
        keep.noConn = nil
        if not K.up("join") then
            keep.noConn = true
            skip("LJ48: Connecting", "Join is not up (it backs out to Join)"); skip("LJ49: the authenticator code field", "Join is not up")
            return
        end
        if not c then keep.noConn = true; skip("LJ48: Connecting", "no ConnectToServer screen"); skip("LJ49: the authenticator code field", "no ConnectToServer screen"); return end
        if c.connecting or c:getIsVisible() then keep.noConn = true; skip("LJ48: Connecting", "the game's Connecting screen is busy"); skip("LJ49: the authenticator code field", "busy"); return end
        local ok, e = pcall(function()
            c.previousScreen = K.ms().multiplayer
            c.title:setName(getText("UI_ConnectToServer_TitleDedicated"))
            c.serverName1:setVisible(true); c.serverName:setVisible(true)
            c.serverName:setName("ZedQA stand-in server")
            c.userName:setName("zedqa")
            c.connectLabel.name = getText("UI_servers_Connecting")
            c.failMessage = nil
            c.backBtn:setTitle(getText("UI_coopscreen_btn_abort"))
            c.isCoop = false
            c.connecting = true
            c:setVisible(true, nil)
        end)
        if not ok then
            keep.noConn = true
            pcall(function() c.connecting = false end)
            check(false, "LJ48: the game's Connecting screen shown (no connection asked)", e)
        end
    end)
    waitFor(function() return keep.noConn or K.up("connect") end, 3000, function(met)
        if keep.noConn then return end
        if not check(met, "LJ48: [stub] the Connecting view mirrors the game's Connecting screen", "view " .. tostring(MM.view)) then
            keep.noConn = true
            pcall(function() keep.cts.connecting = false end)
            K.rescue()
        end
    end)
    after(300, V("connect", "noConn", "LJ48", function(w)
        local c = keep.cts
        local sp = K.spec(w, "back")
        keep.l48a = sp and sp.text == getText("UI_coopscreen_btn_abort")
        keep.l48x = c:getX()
        K.onScreen("LJ48: Connecting", w)
        pcall(function() c.googleAuthPopup:setVisible(true) end)
        K.capStart(w)
    end))
    after(300, V("connect", "noConn", "LJ48", function(w)
        local list = K.capStop()
        local c = keep.cts
        local named = K.capHas(list, "ZedQA stand-in server") and K.capHas(list, ZeD.tr("UI_ZeD_Join_AsUser", "zedqa"))
        local stop = K.spec(w, "field:code")
        local shown = w.code:isVisible()
        if not shown then skip("LJ49: [stub] the authenticator code field is a controller stop", "the code field did not show")
        else check(stop ~= nil and stop.field == w.code, "LJ49: [stub] the authenticator code field is a controller stop (field:code, A opens the pad keyboard; never sent)",
            stop and tostring(stop.id) or "it takes the keyboard (focused) but has no stop the pad can reach (never sent)") end
        pcall(function() c.googleAuthPopup:setVisible(false) end)
        pcall(function() if w.code:isFocused() then w.code:unfocus() end; w.code:setText("") end)
        -- the try fails (vanilla's own handler, no connection behind it)
        c.connecting = false
        pcall(function() c:OnConnectFailed("ZedQA stand-in failure", "") end)
        keep.l48b = named and keep.l48a and keep.l48x <= -10000
    end))
    after(300, V("connect", "noConn", "LJ48", function(w)
        local c = keep.cts
        local sp = K.spec(w, "back")
        local back = sp and sp.text == getText("UI_btn_back")
        check(keep.l48b and back and not c.connecting, "LJ48: [stub] Connecting: the server and the user drawn, Abort while trying, Back once it failed, the game's screen parked off the screen",
            "named and Abort " .. tostring(keep.l48b) .. ", band after the failure " .. tostring(sp and sp.text))
        if c.connecting then c.connecting = false end
        if not c.connecting then K.try("LJ48: B on the failed Connecting", function() w:joyB() end) end
    end))
    waitFor(function() return keep.noConn or MM.view == "join" end, 3000, function(met)
        if keep.noConn then return end
        check(met, "LJ48: [stub] B on a failed Connecting backs out to Join", "view " .. tostring(MM.view))
        K.errCheck("LJ48-LJ49: Connecting")
    end)
    after(200, function() if MM.view == "join" then X.leaveJoin("LJ32") end end)
    waitFor(function() return MM.view == "main" end, 3000, function(met)
        check(met, "LJ32: Join left to the main window", "view " .. tostring(MM.view))
        if not met then K.rescue() end
    end)
end

-- 8: the Steam invite view under -nosteam (LJ52, LJ35's heading)
function X.bootstrap()
    after(200, function()
        keep.noBoot = nil
        if MM.view ~= "main" then K.rescue() end
        if getSteamModeActive() then
            keep.noBoot = true
            skip("LJ52: the invite view", "a Steam launch: connect would ask Steam or connect to a co-op host")
            skip("LJ35: the invite view's heading", "a Steam launch")
            return
        end
        local okId = false
        pcall(function() okId = isValidSteamID("76561197960287930") end)
        if not (BootstrapConnectPopup and BootstrapConnectPopup.instance and okId) then
            keep.noBoot = true
            skip("LJ52: the invite view", "no BootstrapConnectPopup, or the test Steam ID is not taken as one")
            skip("LJ35: the invite view's heading", "the invite view did not open")
            return
        end
        keep.bh0 = { BootstrapConnectPopup.instance.host, BootstrapConnectPopup.instance.port }
        K.try("LJ52: a Steam-ID invite under -nosteam", function() BootstrapConnectPopup.instance:connect("76561197960287930", "16261", "") end)
    end)
    waitFor(function() return keep.noBoot or K.up("bootstrap") end, 3000, function(met)
        if keep.noBoot then return end
        if not check(met, "LJ52: the invite view comes up", "view " .. tostring(MM.view)) then keep.noBoot = true; K.rescue() end
    end)
    after(300, V("bootstrap", "noBoot", "LJ52", function(w)
        local b = BootstrapConnectPopup.instance
        local sp = K.spec(w, "back")
        check(not b.connecting and sp ~= nil and sp.text == ZeD.btnCase(getText("UI_btn_back")), "LJ52: a Steam-ID invite under -nosteam leaves connecting off and offers Back (the red square)",
            "connecting " .. tostring(b.connecting) .. ", band " .. tostring(sp and sp.text))
        note("LJ52: Cancel while Steam is asked clears vanilla's connecting flag (vanilla greys its Back then, BCP:46); not staged: asking Steam needs a Steam launch")
        b.host = "203.0.113.52"; b.port = 16261
        K.capStart(w)
    end))
    after(300, V("bootstrap", "noBoot", "LJ52", function(w)
        local list = K.capStop()
        local b = BootstrapConnectPopup.instance
        b.host, b.port = keep.bh0[1], keep.bh0[2]
        local shown = K.capHas(list, "203.0.113.52")
        check(not shown, "LJ35: the invite view's heading keeps the server's address out of sight (vanilla's shows none)",
            shown and "it prints the stand-in address whatever Streamer mode says" or "no address drawn")
        note("LJ35: Build's known gap: the invite view now drops host : port in every mode, not only in Streamer mode (as vanilla's shows none; one line would keep it outside Streamer mode)")
        K.try("LJ52: Back", function() w:back() end)
    end))
    waitFor(function() return keep.noBoot or MM.view == "main" end, 3000, function(met)
        if keep.noBoot then return end
        check(met, "LJ52: Back on the invite view leaves to the main window", "view " .. tostring(MM.view))
        if not met then K.rescue() end
        K.errCheck("LJ52: the invite view")
    end)
end

-- =========================================================================================================
-- 9: Host (nothing started, every world question answered Cancel)
function X.hostOpen(label)
    after(200, function()
        keep.noHost = nil
        if MM.view ~= "main" then K.rescue() end
        keep.c = K.ms() and K.ms().onlineCoopScreen
        K.try(label .. ": Host opened as its button does", MM.act.host)
    end)
    waitFor(function() return K.up("host") end, 5000, function(met)
        if not check(met, label .. ": Host comes up (view host)", "view " .. tostring(MM.view)) then keep.noHost = true; K.rescue() end
    end)
end
function X.hostChecks()
    after(300, HO(function(w)
        local c = keep.c
        K.onScreen("LJ59: Host", w)
        if not w:idle() then keep.noHost = true; skip("LJ56-LJ62: Host's idle checks", "the host screen is not idle (" .. tostring(c and c.uiStatus) .. ")"); return end
        keep.acc0 = nil
        if getSteamModeActive() then skip("LJ59: an empty account name keeps Start back", "a Steam launch hosts as the Steam user")
        else
            keep.acc0 = tostring(c.accountNameEntry:getText() or "")
            c.accountNameEntry:setText("")
        end
    end))
    after(300, HO(function(w)
        local c = keep.c
        if keep.acc0 ~= nil then
            local why = w:problem()
            local st = K.spec(w, "start")
            c.accountNameEntry:setText(keep.acc0); c.checkPlayer = true
            check(why == ZeD.tr("UI_ZeD_Host_BadAccount") and st ~= nil and st.disabled, "LJ59: an empty account name keeps Start back, the reason in a red-square line (Start never pressed)",
                "reason \"" .. tostring(why) .. "\", Start " .. ((st and st.disabled) and "greyed" or "live"))
        end
        local now = w:problem()
        note("LJ59: with the account as found, what keeps Start back now: " .. (now and ("\"" .. tostring(now) .. "\"") or "nothing"))
        -- LJ62: the two pop-ups
        local bad = {}
        local anchor = { x = w:getAbsoluteX() + 20, y = w:getAbsoluteY() + 60, w = 200, h = 24 }
        local mc = c.memoryComboBox
        pcall(function() w:openCombo(mc, anchor) end)
        local items = (MM.popup and MM.popup.items) or {}
        local sel = mc.selected or 1
        local g = string.char(171)
        local marks = 0
        for _, it in ipairs(items) do if tostring(it.text):find(g, 1, true) then marks = marks + 1 end end
        if MM.ctx.open ~= "host" then bad[#bad + 1] = "the memory pop-up did not open" end
        if #items ~= 62 then bad[#bad + 1] = #items .. " memory sizes" end
        if not (items[sel] and tostring(items[sel].text):sub(-1) == g and marks == 1) then bad[#bad + 1] = "the memory pick not marked alone (" .. marks .. " marks)" end
        if MM.ctx.dropFocus ~= sel or MM.ctx.dropScroll ~= math.max(0, (sel - 4) * ZeD.T.px(26)) then bad[#bad + 1] = "the memory pop-up not opened on its pick" end
        MM.ctx.open = nil
        local sc = c.settingsComboBox
        pcall(function() w:openCombo(sc, anchor) end)
        local items2 = (MM.popup and MM.popup.items) or {}
        local sel2 = sc.selected or 1
        if #items2 > 0 and not (items2[sel2] and tostring(items2[sel2].text):sub(-1) == g) then bad[#bad + 1] = "the settings pick not marked" end
        MM.ctx.open = nil
        check(#bad == 0, "LJ62: the memory and settings pop-ups mark the chosen row with a guillemet and open on it (62 memory sizes; nothing picked)",
            (#bad == 0) and ("memory " .. sel .. " of " .. #items .. ", settings " .. sel2 .. " of " .. #items2) or K.short(bad))
        -- LJ56: a stop reason at idle
        keep.ss0 = c.serverStatus
        c.serverStatus = "ZEDQA stand-in stop reason"
        K.capStart(w)
    end))
    after(300, HO(function(w)
        local list = K.capStop()
        local c = keep.c
        local shown = K.capHas(list, "ZEDQA stand-in stop reason")
        c.serverStatus = keep.ss0
        check(shown, "LJ56: [stub] at idle the host screen draws vanilla's status line (why a server stopped)",
            shown and "drawn" or "c.serverStatus set at idle is not drawn anywhere: the stop reason never shows")
        -- LJ57: a settings name starting with n, Delete world asked (answered Cancel)
        keep.sn1 = CoopConnection.servername
        CoopConnection.servername = "nzedqa_LJ57"
        pcall(function() w:setConfirm("deleteWorld") end)
        K.capStart(w)
    end))
    after(300, HO(function(w)
        local list = K.capStop()
        local c = keep.c
        local folder = ""
        pcall(function() folder = tostring(getAbsoluteSaveFolderName(c:getServerSaveFolder())) end)
        CoopConnection.servername = keep.sn1
        K.try("LJ57: Delete world answered Cancel", function() w:answer(false) end)
        local all = table.concat(list, "")
        local tail = folder:match("Multiplayer.*$") or folder
        local whole = folder ~= "" and all:find(folder, 1, true) ~= nil
        check(whole, "LJ57: [stub] a settings name starting with n keeps its folder path whole in Delete world's question",
            whole and ("drawn whole (" .. tail .. ")") or ("the path's backslash and n turned into a line break (unescape): " .. tail .. " is not drawn whole"))
        -- LJ58: Return (Start stood in for)
        local n = 0
        K.stub(w, "start", function() n = n + 1 end)
        w._enterAt = nil
        pcall(function() if w.account:isFocused() then w.account:unfocus() end; w:keyOther(Keyboard.KEY_RETURN) end)
        K.unstub(w, "start")
        note("LJ58: [stub] Return on the host screen calls Start (" .. n .. " call with Start stood in for); Reset's help reads \"" .. tostring(ZeD.tr("UI_ZeD_MMHelp_HostReset"))
            .. "\" while its answer runs vanilla's onSoftResetStep2, which launches the server (not pressed)")
        K.errCheck("LJ56-LJ62: Host")
    end))
    -- LJ4: safe mode with Host open: handed back, then taken over again
    after(200, HO(function(w)
        local Sf = ZeD.Safe
        local hk = Sf and Sf._hooks and Sf._hooks["main menu"]
        keep.noSafe = nil
        if not (hk and hk.leave and hk.enter) or (Sf.on and Sf.on()) then
            keep.noSafe = true
            skip("LJ4: safe mode with Host open", (hk and "safe mode is already on") or "no main menu safe-mode hook")
            return
        end
        local c = keep.c
        local ds = DebugScenarios and DebugScenarios.instance
        local ds0 = false
        pcall(function() ds0 = ds and ds:isVisible() end)
        local okL, eL = pcall(hk.leave)
        local gone, vis, x = MM.root == nil, false, -20000
        pcall(function() vis = c:getIsVisible(); x = c:getX() end)
        local okE, eE = pcall(hk.enter)
        pcall(function() c:setVisible(true, nil) end)
        pcall(function() if ds and not ds0 and ds:isVisible() then ds:setVisible(false) end end)
        keep.safeBack = MM.root ~= nil
        check(okL and gone and vis and x > -10000, "LJ4: safe mode with Host open: the desk goes and vanilla's host screen comes back on the screen",
            "hand back " .. (okL and "ran" or tostring(eL)) .. ", desk gone " .. tostring(gone) .. ", vanilla's screen shown " .. tostring(vis) .. " at x " .. math.floor(x))
        if not okE then check(false, "LJ4: ZeD takes the menu over again", eE) end
    end))
    waitFor(function() return keep.noSafe or keep.noHost or K.up("host") end, 3000, function(met)
        if keep.noSafe or keep.noHost then return end
        local x = 0
        pcall(function() x = keep.c:getX() end)
        check(met and keep.safeBack and x <= -10000, "LJ4: safe mode taken back: the desk and the host view again, the game's screen parked", "view " .. tostring(MM.view) .. ", x " .. math.floor(x))
        if not met then K.rescue() end
    end)
    -- LJ61: Back writes host.ini again (a marker line first)
    after(200, HO(function(w)
        if not w:idle() then skip("LJ61: Host's Back writes host.ini", "not idle"); return end
        local lines = {}
        for _, l in ipairs(keep.host0 or {}) do lines[#lines + 1] = l end
        lines[#lines + 1] = "zedqa_marker=LJ61"
        K.writeLines("host.ini", lines, "\r\n")
        keep.hostMarked = true
        K.try("LJ61: Host's Back", function() w:back() end)
    end))
    waitFor(function() return keep.noHost or MM.view == "main" end, 3000, function(met)
        if keep.noHost then return end
        check(met, "LJ61: Host's Back leaves to the main window", "view " .. tostring(MM.view))
        if not met then K.rescue() end
        X.hostIni("LJ61: Host's Back writes Lua/host.ini again (servername, username, memory)")
    end)
end
function X.hostIni(label)
    local now = K.readLines("host.ini") or {}
    local marker, keys = false, {}
    for _, l in ipairs(now) do
        if l:find("zedqa_marker", 1, true) then marker = true end
        keys[#keys + 1] = l:match("^([^=]+)=") or "?"
    end
    check(#now > 0 and not marker and table.concat(keys, ",") == "servername,username,memory", label,
        "keys " .. table.concat(keys, ",") .. (marker and "; the marker line is still there (not written)" or ""))
end

-- 10: Server settings, from Host's Edit settings (nothing saved, nothing made, nothing deleted)
function X.server()
    X.hostOpen("LJ61")
    after(300, HO(function(w)
        local lines = {}
        for _, l in ipairs(keep.host0 or {}) do lines[#lines + 1] = l end
        lines[#lines + 1] = "zedqa_marker=LJ61"
        K.writeLines("host.ini", lines, "\r\n")
        keep.hostMarked = true
        K.try("LJ61: Edit settings", function() w:editSettings() end)
    end))
    waitFor(function() return keep.noHost or K.up("srvset") end, 5000, function(met)
        if keep.noHost then keep.noSrv = true; return end
        keep.noSrv = nil
        if not check(met, "LJ63: Edit settings opens the server settings window (view srvset)", "view " .. tostring(MM.view)) then keep.noSrv = true; K.rescue() end
        X.hostIni("LJ61: Edit settings writes Lua/host.ini again (servername, username, memory)")
    end)
    after(400, SV(function(w)
        K.onScreen("LJ63: Server settings", w)
        if w:mode() ~= "list" then keep.noSrv = true; check(false, "LJ63: Server settings opens on its list", "mode " .. tostring(w:mode())); return end
        keep.sfe = 0; keep.sf0 = keep.frames
        local orig = serverFileExists
        if not K.stub(_G, "serverFileExists", function(...) keep.sfe = keep.sfe + 1; return orig(...) end) then keep.sfe = nil end
    end))
    after(800, SV(function(w)
        K.unstub(_G, "serverFileExists")
        local f = keep.frames - (keep.sf0 or keep.frames)
        local S2 = ServerSettingsScreen.instance
        local n = #S2.pageStart.listbox.items
        keep.noSrvSel = S2.pageStart.listbox.items[S2.pageStart.listbox.selected] == nil
        local suf = 0
        pcall(function() suf = getServerSettingsManager():getSuffixes():size() end)
        if keep.sfe == nil then skip("LJ63: serverFileExists per frame (perf)", "serverFileExists could not be stood in for")
        else
            check(f > 0, "LJ63: the settings list checks each of the picked settings' files every frame (perf)",
                keep.sfe .. " serverFileExists calls in " .. f .. " frames, " .. K.per(keep.sfe, f) .. " a frame (" .. suf .. " suffixes, " .. n .. " settings)")
        end
        K.try("LJ64: New", function() w:act("new") end)
    end))
    after(300, SV(function(w)
        if w:mode() ~= "new" then check(false, "LJ64: New opens the name page", "mode " .. tostring(w:mode())); return end
        local bad = {}
        for _, ch in ipairs({ "\\", "/", ":", "*", "?", "\"", "<", ">", "|" }) do
            w.nameEntry:setText("zedqa" .. ch .. "x")
            if w:nameProblem("new") ~= ZeD.tr("UI_ZeD_Server_ErrCharacters") then bad[#bad + 1] = ch end
        end
        w.nameEntry:setText("")
        local e0 = w:nameProblem("new")
        w.nameEntry:setText("zedqa_LJ64_never_saved")
        check(#bad == 0 and e0 == ZeD.tr("UI_ZeD_Server_ErrNoName"), "LJ64: a settings name refuses \\ / : * ? \" < > | and an empty name (typed only, never Next)",
            (#bad == 0) and ("empty: \"" .. tostring(e0) .. "\"") or ("let through: " .. table.concat(bad, " ")))
        K.try("LJ64: New's Back", function() w:act("back") end)
    end))
    after(300, SV(function(w)
        if w:mode() ~= "list" then check(false, "LJ64: New's Back lands on the list", "mode " .. tostring(w:mode())); return end
        if keep.noSrvSel then skip("LJ64: Duplicate refuses the same name", "no settings here"); return end
        K.try("LJ64: Duplicate", function() w:act("duplicate") end)
    end))
    after(300, SV(function(w)
        if w:mode() ~= "duplicate" then return end
        local S2 = ServerSettingsScreen.instance
        local nm = S2.pageDuplicate.settings and S2.pageDuplicate.settings:getName()
        w.nameEntry:setText(tostring(nm))
        local e = w:nameProblem("duplicate")
        check(e == ZeD.tr("UI_ZeD_Server_ErrSameName"), "LJ64: Duplicate refuses the same name", "\"" .. tostring(e) .. "\"")
        K.try("LJ64: Duplicate cancelled", function() w:act("back") end)
    end))
    -- the edit page, through the mods step (only when its Next reloads nothing)
    after(300, SV(function(w)
        keep.noEdit = nil
        if keep.noSrvSel then keep.noEdit = "no settings here"; return end
        if w:mode() ~= "list" then keep.noEdit = "the list is not up (mode " .. tostring(w:mode()) .. ")"; return end
        K.try("LJ66: Edit", function() w:act("edit") end)
    end))
    waitFor(function() return keep.noSrv or keep.noEdit or (K.up("srvset") and K.win("srvset"):mode() == "mods") end, 3000, function(met)
        if keep.noSrv or keep.noEdit then return end
        local w = K.win("srvset")
        if not met then keep.noEdit = "Edit did not reach the mods step"; return end
        local ids = {}
        pcall(function() for _, it in ipairs(ServerSettingsScreen.instance.pageEdit.chooseModsWindow.listbox.items) do ids[#ids + 1] = it.item.modID end end)
        if not X.onlyZeD(ids) then
            keep.noEdit = "the settings' mods differ from the menu's by more than ZeD: the mods step's Next would reload Lua"
            K.try("LJ66: the mods step cancelled", function() w:act("back") end)
            return
        end
        K.try("LJ66: the mods step's Next (no reload: ZeD alone differs)", function() w:act("next") end)
    end)
    waitFor(function() return keep.noSrv or keep.noEdit or (K.up("srvset") and K.win("srvset"):mode() == "edit") end, 3000, function(met)
        if keep.noSrv or keep.noEdit then return end
        if not met then keep.noEdit = "Next did not reach the edit page" end
    end)
    after(400, SV(function(w)
        if keep.noEdit then
            for _, id in ipairs({ "LJ66: a changed row's dot, the count, the Discard question", "LJ67: Return on the edit page", "LJ69: the Mods page's list height", "LJ70: the Password row's stars" }) do skip(id, keep.noEdit) end
            return
        end
        local pages = w:pages()
        local hit = nil
        for i, p in ipairs(pages) do
            if not hit and not p.head and p.page and not p.page.customui then
                for _, r in ipairs(w:rowsFor(p)) do
                    if not hit and r.kind == "tick" and not r.groupTick and r.name and not w:rowDisabled(r) then hit = { i = i, r = r } end
                end
            end
        end
        keep.l66 = hit
        if not hit then skip("LJ66: a changed row's dot, the count, the Discard question", "no tick on the edit pages"); return end
        w:selectPage(hit.i)
        hit.was = hit.r.control.selected[1]
        hit.r.control.selected[1] = not hit.was
        w:refreshDiff(true)
    end))
    after(400, SV(function(w)
        local h = keep.l66
        if keep.noEdit or not h then return end
        local stat = w.titleStats and w.titleStats[1] and w.titleStats[1].text
        local name = ""
        pcall(function() name = tostring(ServerSettingsScreen.instance.pageEdit.settings:getName()) end)
        local want = ZeD.tr("UI_ZeD_Sandbox_StatChanged", name, 1)
        local dot, nd = w:isChanged(h.r), w.nDiff
        K.try("LJ66: Back with a change", function() w:act("back") end)
        local asked = w.confirm == "discard" and w.focusId == "confirm:no"
        check(dot and nd == 1 and stat == want and asked, "LJ66: a changed tick gets its dot, the title counts it, Back asks Keep editing or Discard changes (the pad on Keep editing)",
            "dot " .. tostring(dot) .. ", " .. tostring(nd) .. " changed, title \"" .. tostring(stat) .. "\", question " .. tostring(w.confirm) .. " on " .. tostring(w.focusId))
        pcall(function() w:setConfirm(false) end)
        h.r.control.selected[1] = h.was
        w:refreshDiff(true)
        note("LJ66: a preset's Apply is counted the same way (SS:825-826); not pressed here")
        -- LJ70: the Password row
        local found = nil
        for i, p in ipairs(w:pages()) do
            if not found and not p.head and p.page and not p.page.customui then
                for _, r in ipairs(w:rowsFor(p)) do if r.secret and not found then found = { i = i, r = r } end end
            end
        end
        keep.l70 = found
        if not found then skip("LJ70: the Password row's stars", "no INI Password row"); return end
        found.t0 = tostring(found.r.control:getText() or "")
        found.r.control:setText("zedqa7")
        w:selectPage(found.i)
        w.scroll = 0
        K.capStart(w)
    end))
    after(300, SV(function(w)
        local list = K.capStop()
        local f = keep.l70
        if keep.noEdit or not f then return end
        local exact = false
        for _, l in ipairs(list) do if l == "******" then exact = true end end
        f.r.control:setText(f.t0)
        w:refreshDiff(true)
        note("LJ70: the INI Password row draws one star per character (" .. (exact and "six stars for a six-character stand-in" or "the six stars for a six-character stand-in were not seen")
            .. "), so its length shows; the password as found is put back in the field (never printed)")
        -- LJ69: the Mods page
        local mi = nil
        for i, p in ipairs(w:pages()) do if not mi and p.panel and p.panel.Type == "ServerSettingsScreenModsPanel" then mi = i end end
        keep.l69 = mi
        if mi then w:selectPage(mi) end
    end))
    after(300, SV(function(w)
        if keep.noEdit then return end
        if not keep.l69 then skip("LJ69: the Mods page's list height", "no Mods page")
        else
            local b = w._listBoxes and w._listBoxes["mods"]
            check(b ~= nil and b.h > 0, "LJ69: the Mods page's list has room at this screen size",
                b and (math.floor(b.h) .. " tall at " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()) or "the list did not draw")
        end
        note("LJ69: the points page and the Mods page set their list heights with no floor (SS:1003, 727), the Map, Regions and Workshop pages floor at 90; 1280x720 with Large text is not staged (the resolution is never changed)")
        -- LJ67: Return on the edit page (its act stood in for)
        local rec = {}
        K.stub(w, "act", function(self, what) rec[#rec + 1] = tostring(what) end)
        if w.act ~= ZeD_MMServer.act then
            w._enterAt = nil
            pcall(function()
                if w.find:isFocused() then w.find:unfocus() end
                for _, e in ipairs(w._extra or {}) do if e:isFocused() then e:unfocus() end end
                w:keyOther(Keyboard.KEY_RETURN)
            end)
        end
        K.unstub(w, "act")
        note("LJ67: [stub] Return on the edit page asks " .. (rec[1] and ("act(\"" .. rec[1] .. "\")") or "nothing") .. " with no question first: it saves every file of the settings at once (stood in for here)")
        note("LJ68: not run (it writes a file): the points page's Save calls Page7:onButtonAccept, which writes the region's spawn points file at once, and the edit page's Cancel does not take it back (SSS:3872-3880)")
    end))
    after(200, SV(function(w)
        if keep.noEdit or w:mode() ~= "edit" then return end
        pcall(function() w:setConfirm(false) end)
        local why = K.wouldReset()
        if why then
            check(false, "LJ66: the edit page can be left without a Lua reload", why .. ": the edit page is hidden by hand instead")
            pcall(function() local S2 = ServerSettingsScreen.instance; S2.pageEdit:setVisible(false); S2.pageStart:setVisible(true) end)
            return
        end
        if w:anyChanged() then note("LJ66: the edit page still counts a change as it is left: Discard changes (nothing saved)") end
        w.confirm = "discard"   -- (straight through the Discard answer: vanilla's Cancel, nothing saved)
        K.try("LJ66: Discard changes", function() w:act("back") end)
    end))
    waitFor(function() return keep.noSrv or (K.up("srvset") and K.win("srvset"):mode() == "list") end, 3000, function(met)
        if keep.noSrv then return end
        check(met, "LJ66: Discard changes lands on the settings list", "mode " .. tostring(K.win("srvset") and K.win("srvset"):mode()))
        K.errCheck("LJ63-LJ70: Server settings")
    end)
    after(200, SV(function(w)
        if w:mode() ~= "list" then return end
        K.try("LJ63: Server settings' Back", function() w:act("back") end)
    end))
    waitFor(function() return keep.noSrv or K.up("host") end, 4000, function(met)
        if keep.noSrv then return end
        check(met, "LJ63: Server settings' Back lands on Host", "view " .. tostring(MM.view))
        if not met then K.rescue() end
    end)
    after(200, function()
        if K.up("host") then
            local w = K.win("host")
            if w:idle() then K.try("LJ61: Host's Back", function() w:back() end) else K.rescue() end
        elseif MM.view ~= "main" then K.rescue() end
    end)
    waitFor(function() return MM.view == "main" end, 3000, function(met)
        if not met then K.rescue() end
    end)
end

-- 11: the menu bar leaving an idle Host (LJ2)
function X.hostLeave()
    X.hostOpen("LJ2")
    after(300, HO(function(w)
        keep.noL2 = nil
        local has = MM.hasSaves()
        local items = MM.menuItems(has and "file" or "mp") or {}
        local key = has and "UI_ZeD_MainMenu_LoadGame" or "UI_ZeD_MainMenu_JoinServer"
        local row = nil
        for _, it in ipairs(items) do if type(it) == "table" and it.text == ZeD.tr(key) then row = it end end
        keep.l2to = has and "load" or "join"
        if not (row and row.fn) then keep.noL2 = true; skip("LJ2: the menu bar leaving an idle Host", "no " .. keep.l2to .. " row in the menu"); return end
        K.try("LJ2: the menu bar's " .. keep.l2to .. " row pressed while Host is up", row.fn)
    end))
    waitFor(function() return keep.noL2 or keep.noHost or MM.view == keep.l2to end, 3000, function(met)
        if keep.noL2 or keep.noHost then return end
        local c = keep.c
        local vis, x = false, 0
        pcall(function() vis = c:getIsVisible(); x = c:getX() end)
        check(met and not vis, "LJ2: leaving an idle Host by the menu bar puts the game's host screen away (onViewLeft hides it)",
            (vis and x <= -10000) and ("the game's host screen stays shown, parked at x " .. math.floor(x) .. ": it keeps following its server off the screen (view " .. tostring(MM.view) .. ")")
            or ("shown " .. tostring(vis) .. ", x " .. math.floor(x) .. ", view " .. tostring(MM.view)))
        note("LJ2: the busy cases (Host launching, Connecting) are not staged: they start a server or a connection")
        pcall(function() if c:getIsVisible() then c:setVisible(false) end end)
        if MM.view == "join" then pcall(function() if getSteamModeActive() then steamReleaseInternetServersRequest() end end) end
        MM.ctx.open = nil
        MM.showView("main")
    end)
end

-- 12: what cannot be staged at the main menu here
function X.notStaged()
    after(100, function()
        skip("LJ20: Delete failing says nothing", "[copy]/[manual]: needs a staged copy of a save held open; Delete's Yes is never pressed on a real save")
        skip("LJ21: the last save deleted", "[no]: needs every real save gone")
        skip("LJ22: Continue after Delete or Rename", "[copy]: needs a staged copy of a save; nothing is deleted or renamed here")
        skip("LJ26: Choose mods returns to Load and Accept writes mods.txt", "[copy]: Accept writes the save's mods.txt; needs a staged copy of a save")
        skip("LJ28: Play with Load still up", "[no]: it loads a save")
        skip("LJ50: Abort while connecting", "[no]: it needs a real connection (backToSinglePlayer)")
        skip("LJ51: Workshop items", "[no]: Steam only, reached only by joining a server whose Workshop mods are missing")
        skip("LJ60: Delete player on Steam", "[no]: a Steam host, and it deletes a player")
        skip("LJ65: the mods step's Next with another difference", "[manual]: it resets Lua")
    end)
end

-- =========================================================================================================
-- the put-back
function X.putBack()
    after(300, function()
        pcall(K.capStop)
        pcall(function() K.unstubFrom(0) end)
        MM.forceGamepad = keep.pad0
        pcall(function() if keep.strTick then keep.strTick.selected[1] = keep.str0 end end)
        pcall(function() if keep.sn1 ~= nil and CoopConnection.servername == "nzedqa_LJ57" then CoopConnection.servername = keep.sn1 end end)
        pcall(function() if keep.ss0 ~= nil and keep.c then keep.c.serverStatus = keep.ss0 end end)
        pcall(function() if keep.acc0 ~= nil and keep.c then keep.c.accountNameEntry:setText(keep.acc0) end end)
        pcall(function() if keep.l70 and keep.l70.t0 then keep.l70.r.control:setText(keep.l70.t0) end end)
        pcall(function() if keep.l66 and keep.l66.was ~= nil then keep.l66.r.control.selected[1] = keep.l66.was end end)
        -- a question or a form a part left open: shut, nothing answered
        pcall(function()
            for _, v in ipairs({ "load", "join", "host", "srvset" }) do
                local w = K.win(v)
                if w and w.confirm and w.setConfirm then pcall(w.setConfirm, w, false) end
            end
            local j = K.win("join")
            if j and j.page ~= "list" then pcall(function() j:closeForm() end) end
        end)
        -- the game's screens this run showed: put away (never Abort while connecting, never Back on a busy host)
        pcall(function()
            local m = K.ms()
            local c = m.connectToServer
            if c and c:getIsVisible() then c.connecting = false; c:setVisible(false) end
            local b = m.bootstrapConnectPopup
            if b and b:getIsVisible() then b.connecting = false; b:setVisible(false) end
            local p = m.serverConnectPopup
            if p and p:getIsVisible() then p:setVisible(false) end
            local s = ServerSettingsScreen and ServerSettingsScreen.instance
            if s and MM.view == "srvset" and not K.wouldReset() then pcall(function() s.pageEdit:setVisible(false) end); s:setVisible(false) end
            local h = m.onlineCoopScreen
            if h and h:getIsVisible() and h.uiStatus == "idle" then h:setVisible(false) end
        end)
        MM.ctx.open = nil
        pcall(K.rescue)
        if keep.opt0 then pcall(K.setAll, keep.opt0) end
    end)
    after(600, function()
        if keep.hostMarked then
            if keep.host0 then K.writeLines("host.ini", keep.host0, "\r\n")
            else note("PUTBACK: Lua/host.ini was not there before; vanilla's Host Back wrote it (the runner's put-back removes it)") end
        end
    end)
    after(400, function()
        local d = K.diff(keep.opt0, K.snapAll())
        check(keep.opt0 ~= nil and #d == 0, "PUTBACK: every ZeD option as found (" .. K.count(keep.opt0) .. " options)", K.short(d))
        if keep.host0 then check(K.same(K.readLines("host.ini"), keep.host0), "PUTBACK: Lua/host.ini line for line as found") end
        local left = #keep.stubs
        check(left == 0 and keep.cap == nil, "PUTBACK: every stand-in put back (functions, fields, the drawing hook)", left .. " left")
        check(MM.forceGamepad == keep.pad0, "PUTBACK: the controller flag as found")
        check(K.wouldReset() == nil, "PUTBACK: the mod list in memory is the one running (no Lua reload waiting)", K.wouldReset())
        local busy = {}
        pcall(function()
            local m = K.ms()
            if m.connectToServer and m.connectToServer:getIsVisible() then busy[#busy + 1] = "Connecting" end
            if m.bootstrapConnectPopup and m.bootstrapConnectPopup:getIsVisible() then busy[#busy + 1] = "the invite" end
            if m.serverConnectPopup and m.serverConnectPopup:getIsVisible() then busy[#busy + 1] = "Connect to" end
            if m.onlineCoopScreen and m.onlineCoopScreen:getIsVisible() then busy[#busy + 1] = "Host" end
        end)
        check(#busy == 0, "PUTBACK: none of the game's join or host screens left showing", K.short(busy))
        local q = false
        pcall(function()
            for _, v in ipairs({ "load", "join", "host", "srvset" }) do local w = K.win(v); if w and w.confirm then q = true end end
        end)
        check(MM.view == "main" and K.up("main") and MM.ctx.open == nil and not q, "PUTBACK: the main window is up, no menu open, no question open", "view " .. tostring(MM.view))
    end)
    after(300, function()
        keep.zapFree = true
        K.freeZap()
        local z = MM._life and MM._life.zap
        if z then check(z.nextAt < 1e14, "PUTBACK: the lightning is let go") end
        local n = K.errs()
        if n ~= nil and keep.errs0 ~= nil then say("Lua errors counted during the run: " .. (n - keep.errs0)) end
    end)
end

-- =========================================================================================================
if not (MM and MM.root and MM.showView and MM.act) then
    after(100, function() S.fail = S.fail + 1; say("ERR ZeD's main menu is not up (no desk): nothing was done") end)
else
    X.start()
    X.waysIn()
    X.loadOpen()
    X.loadReal()
    X.loadFakes()
    X.invite()
    X.joinOpen()
    X.joinFakes()
    X.connecting()
    X.bootstrap()
    X.hostOpen("LJ59")
    X.hostChecks()
    X.server()
    X.hostLeave()
    X.notStaged()
    mark()
    X.putBack()
end
after(300, function()
    say("end: " .. S.pass .. " pass, " .. S.fail .. " fail, " .. S.skips .. " skipped; " .. math.floor((getTimestampMs() - S.start) / 1000) .. " s; view=" .. tostring(MM and MM.view))
    say(S.fail > 0 and ("VERDICT FAIL " .. S.fail) or ("VERDICT PASS " .. S.pass))
end)
after(100, function() say("DONE") end)

local function tickFn()
    keep.frames = keep.frames + 1
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
