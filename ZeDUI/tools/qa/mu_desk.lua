-- ZeDUI/tools/qa/mu_desk.lua  (Nov 27 2026, QA menus sweep; tag mu_desk): MAIN MENU ONLY, pushed through the QA bridge.
-- The gamut sweep of the main menu desk: checks DK1 to DK70 of ZeDUI/qa/audits/2026-11-27_map_menu_desk.md (the room,
-- the menu bar and its pull-downs, the main window and its band, the power button, the desktop's icons, the Pasties,
-- the Trash, Desktop... and the desktops, Credits, Terms, CletusWorks, Documents, ProtoPOP3 Mail, the Workshop window
-- and its description editor, Lite and the pad on the desk). Every check id gets a line: PASS, FAIL, SKIP (why) or NOTE
-- (a design call: what ZeD does now).
--   boot         the ready checks hold the wake (DK1); nothing answers while the monitor switches on (DK2); a held
--                start runs once after the switch-off and the monitor comes back after 2 s (DK3); the watchdog at the
--                menu (DK6)
--   the window   the Continue card and its words (DK7, DK8); Load greyed three ways with no saves (DK9); New Game,
--                Host and Join land on their views (DK10, DK11); Mods (n) (DK12); the quit question, its pad landing,
--                its footer and the cooldown (DK13 to DK15); the close box, B and the Project Zomboid icon (DK16);
--                Return and the arrows (DK17); the power button's hint (DK18); the power button past the notepad (DK19)
--   menu bar     every title and row (DK20); the ZeD menu on the tube (DK21); the clock (DK22); About (DK23); the
--                debug rows (DK24 to DK26); the pointer's rules on stand-in panels (DK27); the pad on the bar (DK28)
--   desktop      the icons (DK29), the left column (DK30), select and open (DK31), the pad off the window's sides
--                (DK32), the bare desktop's prompts (DK33)
--   Pasties      eight at most (DK34), saving and the caps (DK35), throwing away (DK36), a pile and a window over a
--                note (DK37), the old sticky's move (DK38), the pad on a note (DK39)
--   Trash, Desktop...  DK40 to DK45; Credits and Terms DK46 to DK50; CletusWorks, Documents and Mail DK51 to DK57;
--                the Workshop and its editor DK58 to DK65; Lite DK66; small screens, the corkboard, words, drift DK67 to
--                DK70; Safe mode on and off at the desk (DK4, last, before the put-back)
-- The notes and the mail never touch the real files: for the whole sweep ZeD.DeskNotes.io and ZeD.MailStore.io read and
-- write a stand-in disk in memory (their own QA hooks), and the notepad, Documents, Mail and the Pasties' fields are
-- set back as found at the end.
-- NEVER pressed or called: Continue (its vanilla handler is stood in for once, DK51), Load, Play, New game's last step,
-- a challenge's Next, Join's connect, Host's start, Upload, Save in the Workshop, Delete's Yes on a real save, Reset Lua,
-- Quit / Exit / quitToDesktop, Accept terms (its button's function stood in for, DK48), View terms / privacy, Report a
-- bug. No display, language or game option is changed; the game's highlight color is changed in memory and put back.
--
-- What it puts back itself: every ZeD option as found (and the look on screen), Style, the input lock, the desktop,
-- the highlight color, vanilla's hasSaveFiles, the notepad, Documents, Mail and Pasties as found, the notes and mail
-- reading the real files again, the debug scenario list as found, the lightning let go, the main window up. Files kept
-- line for line and written back if changed (all under Zomboid/Lua): ZeD_wallpaper.txt, ModOptions.ini, host.ini,
-- ZeD_workshop.txt, ZeD_desk_pasties.txt, ZeD_desk_pastie_1..8.txt, ZeD_desk_sticky.txt, ZeD_desk_sticky_place.txt,
-- ZeD_desk_notes.txt, ZeD_desk_note_1..24.txt, ZeD_desk_draft.txt, ZeD_mail_boxes.txt, ZeD_mail_1..20.txt. Files it
-- writes on purpose: ZeD_wallpaper.txt (a pick, DK41; put back), ModOptions.ini (a look saved by a desk window; put back).
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself), with $env:ZEDQA_NOSTEAM = "1" first:
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/zed_only_mods.txt `
--        -Script ZeDUI/tools/qa/mu_desk.lua -Tag mu_desk -TimeoutSec 540
-- Lines: "ZEDQA mu_desk PASS ..." / "FAIL ..." / "SKIP ..." / "NOTE ..." / "ERR ...", then "end: ...", "VERDICT PASS n"
-- or "VERDICT FAIL n", then DONE from a later frame. grep "ZEDQA mu_desk".
local TAG = "mu_desk"
local MM = ZeD and ZeD.MainMenu
local St = ZeD and ZeD.Settings
local N = ZeD and ZeD.DeskNotes
local MS = ZeD and ZeD.MailStore
local DS = ZeD and ZeD.Desktops
local Safe = ZeD and ZeD.Safe
local S = { pass = 0, fail = 0, skips = 0, stages = {}, si = 1, maxMs = 400000, start = getTimestampMs() }
local keep = { files = {}, rewrote = {}, fileBad = {}, fileMade = {} }
local K = {}
local X = {}
local D = { disk = {}, writes = 0, failWrite = false, swapped = false }

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

-- ---- small things
function K.short(list)
    local out = {}
    for i, s in ipairs(list or {}) do if i <= 6 then out[#out + 1] = tostring(s) end end
    if #(list or {}) > 6 then out[#out + 1] = "(+" .. (#list - 6) .. " more)" end
    return table.concat(out, "; ")
end
function K.ms() return MainScreen and MainScreen.instance end
function K.main() return MM.root and MM.root.win end
function K.icons() return MM.root and MM.root.icons end
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
function K.n(v)
    if type(v) ~= "number" then return tostring(v) end
    return tostring(math.floor(v + 0.5))
end
function K.q(s)
    if s == nil then return "nil" end
    local t = string.gsub(tostring(s), "\n", "\\n")
    if #t > 80 then t = string.sub(t, 1, 80) .. "..." end
    return "\"" .. t .. "\""
end
function K.near(a, b) return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 0.0005 end
function K.screen() return getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() end

-- ---- ZeD's options (as bx_menu.lua)
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
-- Style as ZeD setup's row sets it (1 Full, 2 Lite)
function K.style(i)
    local o = St.lookStyleOption
    pcall(function() o:setValue(i) end)
    if o.onChange then pcall(o.onChange, o, i) end
end

-- ---- files (Zomboid/Lua): read and written line by line, as bx_menu.lua
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
-- every file the desk may write (the map's list)
function K.fileList()
    local t = { "ZeD_wallpaper.txt", "ModOptions.ini", "host.ini", "ZeD_workshop.txt", "ZeD_desk_pasties.txt", "ZeD_desk_sticky.txt",
                "ZeD_desk_sticky_place.txt", "ZeD_desk_notes.txt", "ZeD_desk_draft.txt", "ZeD_mail_boxes.txt" }
    for i = 1, 8 do t[#t + 1] = "ZeD_desk_pastie_" .. i .. ".txt" end
    for i = 1, 24 do t[#t + 1] = "ZeD_desk_note_" .. i .. ".txt" end
    for i = 1, 20 do t[#t + 1] = "ZeD_mail_" .. i .. ".txt" end
    return t
end

-- ---- the lightning (as bx_menu.lua): held off; let go at the end
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

-- ---- windows, specs, rows
function K.win(view)
    local r = MM.root
    if not r then return nil end
    if view == "main" then return r.win end
    if view == "desktop" then return r.icons end
    if view == "newgame" then return r.newWin end
    for _, rv in ipairs(MM.views or {}) do if rv.view == view then return r[rv.field] end end
    return nil
end
-- (the desk shows and hides its windows in its update, every 100 ms: a wait ends on the window, not on MM.view)
function K.up(view)
    local w = K.win(view)
    return MM.view == view and w ~= nil and w:isVisible() and true or false
end
function K.spec(w, id)
    for _, s in ipairs((w and w._specs) or {}) do if s.id == id then return s end end
    return nil
end
function K.hit(w, id)
    for _, h in ipairs((w and w._hits) or {}) do if h.id == id then return h end end
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
-- a real controller is on the main menu (then the game's on-screen keyboard would come up: not opened blind)
function K.realPad()
    local jd = nil
    pcall(function() jd = JoypadState.getMainMenuJoypad() end)
    return jd ~= nil
end
function K.rowBy(items, pred)
    for _, it in ipairs(items or {}) do
        if type(it) == "table" and (it.text or it.about) then
            local ok, r = pcall(pred, it)
            if ok and r then return it end
        end
    end
    return nil
end
function K.row(key, fn)
    local items = {}
    pcall(function() items = MM.menuItems(key) or {} end)
    return K.rowBy(items, function(it) return it.fn == fn end)
end
function K.leftItem(id)
    for _, it in ipairs(MM.leftItems and MM.leftItems() or {}) do if it.id == id then return it end end
    return nil
end
function K.labels(prompts)
    local t = {}
    for _, p in ipairs(prompts or {}) do
        if type(p) == "table" then t[#t + 1] = tostring(p.label) else t[#t + 1] = tostring(p) end
    end
    return table.concat(t, ", ")
end
function K.hasLabel(prompts, word)
    for _, p in ipairs(prompts or {}) do if type(p) == "table" and p.label == word then return true end end
    return false
end
function K.rect(w) return { x = w:getAbsoluteX(), y = w:getAbsoluteY(), w = w:getWidth(), h = w:getHeight() } end
function K.overlap(a, b) return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
function K.inTube(label, w)
    local L = MM.layout()
    local r = K.rect(w)
    local g = K.n(r.x) .. "," .. K.n(r.y) .. " " .. K.n(r.w) .. "x" .. K.n(r.h) .. "; the tube " .. K.n(L.tx) .. "," .. K.n(L.ty) .. " " .. K.n(L.tw) .. "x" .. K.n(L.th)
    check(w:isVisible() and r.x >= L.tx - 1 and r.y >= L.ty - 1 and r.x + r.w <= L.tx + L.tw + 1 and r.y + r.h <= L.ty + L.th + 1,
        label .. " sits inside the monitor's tube", g)
end
function K.setHL(r, g, b) getCore():setObjectHighlitedColor(ColorInfo.new(r, g, b, 1)) end
function K.hl()
    local t = nil
    pcall(function()
        local ci = getCore():getObjectHighlitedColor()
        if ci then t = { ci:getR(), ci:getG(), ci:getB() } end
    end)
    return t
end
function K.modIds(id)
    local t = {}
    pcall(function()
        local l = ActiveMods.getById(id):getMods()
        for i = 0, l:size() - 1 do t[#t + 1] = tostring(l:get(i)) end
    end)
    return table.concat(t, ";")
end
function K.activated()
    local t = {}
    pcall(function() local l = getActivatedMods(); for i = 0, l:size() - 1 do t[#t + 1] = tostring(l:get(i)) end end)
    return table.concat(t, ";")
end
-- (as bx_menu.lua) a Lua reload waiting: the mod list in memory is not the one running
function K.wouldReset()
    local need = false
    pcall(function() need = ActiveMods.requiresResetLua(ActiveMods.getById("default")) end)
    if need then return "the mod list in memory is not the one running" end
    return nil
end
-- a stand-in panel for MM.pointer: its hit boxes only
function K.fake(hits) return { _hits = hits, isVisible = function() return true end } end
-- MM.pointer driven through a list of { x, y, down } with the mouse stood in for, then the game's own calls back
function K.pointerRun(steps, ctx, panels)
    local MT = ZeD.MouseTick
    local oDown, oX, oY = MT.down, getMouseX, getMouseY
    local cur = { x = 0, y = 0, down = false }
    local ok, err = pcall(function()
        MT.down = function() return cur.down end
        getMouseX = function() return cur.x end
        getMouseY = function() return cur.y end
        for _, s in ipairs(steps) do
            cur.x, cur.y, cur.down = s[1], s[2], s[3]
            MM.pointer(ctx, panels)
        end
    end)
    MT.down, getMouseX, getMouseY = oDown, oX, oY
    return ok, err
end

-- =========================================================================================================
-- THE STAND-IN DISK: the notes (ZeD.DeskNotes.io) and the mail (ZeD.MailStore.io) read and write this for the
-- sweep, as their sims do. A reader drops the line break and gives nil at the end, a writer empties the file first.
-- =========================================================================================================
function D.lines(text)
    local out = {}
    local pos = 1
    while pos <= #text do
        local nl = string.find(text, "[\r\n]", pos)
        if not nl then out[#out + 1] = string.sub(text, pos); break end
        out[#out + 1] = string.sub(text, pos, nl - 1)
        if string.sub(text, nl, nl) == "\r" and string.sub(text, nl + 1, nl + 1) == "\n" then nl = nl + 1 end
        pos = nl + 1
    end
    return out
end
D.io = {
    reader = function(name)
        local text = D.disk[name]
        if text == nil then return nil end
        local ls, i = D.lines(text), 0
        return { readLine = function() i = i + 1; return ls[i] end, close = function() end }
    end,
    writer = function(name)
        if D.failWrite then return nil end
        local buf = {}
        D.disk[name] = ""
        return { write = function(_, s) buf[#buf + 1] = tostring(s) end,
                 close = function() D.disk[name] = table.concat(buf); D.writes = D.writes + 1 end }
    end,
}
function D.swap()
    keep.nio, keep.msio = N.io, MS.io
    N.io, MS.io = D.io, D.io
    N.reset(); MS.reset()
    N.seq = (N.seq or 0) + 1
    MS.seq = (MS.seq or 0) + 1
    D.swapped = true
end
function D.unswap()
    if not D.swapped then return end
    N.io, MS.io = keep.nio, keep.msio
    N.reset(); MS.reset()
    N.seq = (N.seq or 0) + 1
    MS.seq = (MS.seq or 0) + 1
    D.swapped = false
end
-- the Pasties' fields to what the model holds now (unfocused, nothing waiting to save)
function D.syncFields()
    for id, f in pairs((MM.root and MM.root.pasties) or {}) do
        if f.entry then
            pcall(function() if f.entry:isFocused() then f.entry:unfocus() end end)
            f._changedAt = nil
            local text = ""
            pcall(function() if N.pastie(id) then text = N.pastieText(id) or "" end end)
            f.entry:setText(text)
        end
    end
    for k in pairs(MM._pastieAsk or {}) do MM._pastieAsk[k] = nil end
end
-- the notepad on nothing: no page, no question, no draft
function D.npReset()
    local np = K.win("notepad")
    if not np then return end
    pcall(function() np:setConfirm(false) end)
    pcall(function() if np.edit:isFocused() then np.edit:unfocus() end end)
    np.doc, np.pending, np.note, np._draftAt = nil, nil, nil, nil
    pcall(function() np.edit:setText("") end)
    pcall(function() N.clearDraft() end)
end
-- the desk's note and mail windows as found, then emptied for the stand-in disk
function D.keepWindows()
    local r = MM.root
    local np, dc, ml = r.notepadWin, r.docsWin, r.mailWin
    if np then
        keep.np = { doc = np.doc, text = (np.edit and np.edit:getText()) or "", note = np.note, draftAt = np._draftAt }
        pcall(function() np:setConfirm(false) end)
        np.doc, np.pending, np.note, np._draftAt = nil, nil, nil, nil
        pcall(function() np.edit:setText("") end)
    end
    if dc then keep.dc = { sel = dc.sel, scroll = dc.scroll }; dc.sel = nil; dc.scroll = 0 end
    if ml then
        keep.ml = { boxKey = ml.boxKey, folder = ml.folder, sel = ml.sel, compose = ml.compose }
        pcall(function() keep.ml.to, keep.ml.subj, keep.ml.text = ml:composeWords() end)
        ml.boxKey, ml.sel, ml.compose, ml.folder, ml.confirm = nil, nil, nil, "inbox", false
        pcall(function() ml:showFields(false) end)
    end
    keep.fields = {}
    for id, f in pairs(r.pasties or {}) do
        if f.entry then
            keep.fields[id] = f.entry:getText() or ""
            pcall(function() if f.entry:isFocused() then f.entry:unfocus() end end)
            f._changedAt = nil
            f.entry:setText("")
        end
    end
    keep.ask = {}
    for k, v in pairs(MM._pastieAsk or {}) do keep.ask[k] = v end
    for k in pairs(keep.ask) do MM._pastieAsk[k] = nil end
end
function D.restoreWindows()
    local r = MM.root
    local np, dc, ml = r.notepadWin, r.docsWin, r.mailWin
    if np and keep.np then
        pcall(function() np:setConfirm(false) end)
        pcall(function() if np.edit:isFocused() then np.edit:unfocus() end end)
        np.doc, np.pending, np.note, np._draftAt = keep.np.doc, nil, keep.np.note, keep.np.draftAt
        pcall(function() np.edit:setText(keep.np.text) end)
    end
    if dc and keep.dc then pcall(function() dc:setConfirm(false) end); dc.sel, dc.scroll = keep.dc.sel, keep.dc.scroll or 0 end
    if ml and keep.ml then
        local k = keep.ml
        ml.boxKey, ml.folder, ml.sel, ml.compose, ml.confirm, ml.note = k.boxKey, k.folder or "inbox", k.sel, k.compose, false, nil
        pcall(function()
            ml.toEntry:setText(k.to or ""); ml.subjEntry:setText(k.subj or ""); ml.textEntry:setText(k.text or "")
            ml:showFields(k.compose ~= nil)
        end)
    end
    for id, f in pairs(r.pasties or {}) do
        if f.entry and keep.fields then
            pcall(function() if f.entry:isFocused() then f.entry:unfocus() end end)
            f._changedAt = nil
            f.entry:setText(keep.fields[id] or "")
        end
    end
    for k in pairs(MM._pastieAsk or {}) do MM._pastieAsk[k] = nil end
    for k, v in pairs(keep.ask or {}) do MM._pastieAsk[k] = v end
end

-- =========================================================================================================
-- 0: as found
function X.start()
    after(100, function()
        keep.errs = K.errs()
        keep.errs0 = keep.errs
        keep.opt0 = K.snapAll()
        local n = 0
        for _, f in ipairs(K.fileList()) do
            local l = K.readLines(f)
            keep.files[f] = l or false
            if l then n = n + 1 end
        end
        keep.nFiles = n
        keep.wall0 = MM.desktop()
        keep.look0 = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize }
        keep.mods0 = K.activated()
        keep.pad0 = MM.forceGamepad
        keep.lite0 = St.lite and St.lite() or false
        keep.scale0 = ZeD.Scale and ZeD.Scale.userScale
        keep.hl0 = K.hl()
        keep.hs0 = K.ms() and K.ms().hasSaveFiles
        pcall(function() local ds = DebugScenarios and DebugScenarios.instance; if ds then keep.ds0 = ds:isVisible() end end)
        say("as found: " .. K.count(keep.opt0) .. " options; look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize)
            .. ", Style " .. (keep.lite0 and "Lite" or "Full") .. ", desktop " .. tostring(keep.wall0) .. ", view " .. tostring(MM.view) .. ", screen " .. K.screen()
            .. ", debug " .. tostring(getDebug()) .. ", Steam " .. tostring(getSteamModeActive and getSteamModeActive() or false) .. "; " .. n .. " desk files there")
        check(MM.showView and MM.menuItems and MM.menus and MM.act and N and N.io and N.reset and MS and MS.io and MS.reset and DS and St.lookStyleOption and true or false,
            "the desk's parts are loaded (the menu, the notes, the mail, the desktops)")
    end)
    waitFor(function()
        local m = K.ms()
        return m ~= nil and not MM.waking and not MM.poweringOn() and (m.delay or 0) <= 0 and MM.root:isVisible()
    end, 30000, function(met)
        check(met, "the desk is awake (powered on, the fade-in over)", "waking " .. tostring(MM.waking) .. ", delay " .. tostring(K.ms() and K.ms().delay))
    end)
    after(2500, function()
        -- (a first launch opens the welcome by itself: left as it came, nothing answered)
        if MM.view ~= "main" then
            note("the desk had the " .. tostring(MM.view) .. " view up at the start: back to the main window, nothing answered")
            MM.showView("main")
        end
        if keep.lite0 then note("Style was Lite: set to Full for the sweep, put back at the end"); K.style(1) end
    end)
    after(600, function()
        local w = K.main()
        keep.mainFocus = w and w.focusId
        keep.icFocus = K.icons() and K.icons().focusId
        D.keepWindows()
        D.swap()
        check(N.io == D.io and MS.io == D.io, "the desk's notes and mail read and write a stand-in disk for the sweep (the real files are never written)")
        check(MM.view == "main" and K.up("main"), "the main window is up", "view " .. tostring(MM.view))
        K.errCheck("the desk at rest")
    end)
end

-- =========================================================================================================
-- 1: boot and frame (DK1 to DK3, DK5, DK6)
function X.boot()
    after(200, function()
        local ok0, held, back = nil, nil, nil
        pcall(function() ok0 = MM.assetsReady() end)
        MM.readyChecks.zedqa = function() return false end
        pcall(function() held = MM.assetsReady() end)
        MM.readyChecks.zedqa = nil
        pcall(function() back = MM.assetsReady() end)
        check(ok0 == true and held == false and back == true, "DK1: one ready check not in holds the wake; with it gone the wake may go",
            "before " .. tostring(ok0) .. ", with a check not in " .. tostring(held) .. ", after " .. tostring(back))
        local wk = MM.root.wake
        check(MM.waking == false and wk ~= nil and not wk:isVisible(), "DK1: the wake is over and its black cover is down", "waking " .. tostring(MM.waking))
        skip("DK1: the cold boot's black screen and its 10 s give-up", "needs a fresh launch of the game")
    end)
    -- DK2: the switch-on played again; the pointer's hot box and the pad's D-pad watched while it opens
    after(200, function()
        local w = K.main()
        keep.f2 = w.focusId
        w.focusId = "newgame"
        MM.forceGamepad = true
        MM.powerOn = { t0 = getTimestampMs() }
        MM.ctx.hot = "zedqa:dk2"
        keep.dk2 = {}
        pcall(MM.joyDir, K.ms(), "down")
        keep.dk2.to = w.focusId
        w.focusId = "newgame"
    end)
    after(120, function()
        keep.dk2.still = MM.poweringOn()
        keep.dk2.hot = MM.ctx.hot
    end)
    waitFor(function() return not MM.poweringOn() end, 3000, function(met) keep.dk2.over = met end)
    after(300, function()
        local d = keep.dk2
        check(d.over == true, "DK2: the switch-on's opening ends (about 0.47 s) and the desk answers again")
        if d.still then
            check(d.hot == "zedqa:dk2", "DK2: the pointer does not run while the monitor switches on", "hot box " .. tostring(d.hot))
        else
            skip("DK2: the pointer while the monitor switches on", "the frames here were too slow to look inside its 0.47 s")
        end
        check(MM.ctx.hot ~= "zedqa:dk2", "DK2: once it is open the pointer runs again", "hot box " .. tostring(MM.ctx.hot))
        check(d.to == "newgame", "DK2: the pad's D-pad does nothing while the monitor switches on",
            "the main window's focus moved from newgame to " .. tostring(d.to) .. " in the first 0.47 s: MM.joyDir and MM.joyDown have no switch-on test (only the pointer waits)")
        MM.forceGamepad = keep.pad0
        K.main().focusId = keep.f2
    end)
    -- DK3: a held start (o.run, as the respawn's Play) runs once after the switch-off; the monitor comes back after 2 s
    after(200, function()
        keep.dk3 = { n = 0 }
        MM.switchOff({ run = function() keep.dk3.n = keep.dk3.n + 1 end })
    end)
    waitFor(function() return keep.dk3.n > 0 end, 3000, function(met)
        check(met and keep.dk3.n == 1 and MM.powerOff ~= nil, "DK3: what waits on the switch-off runs once, after it has played", "ran " .. keep.dk3.n .. " times")
    end)
    waitFor(function() return MM.powerOff == nil end, 4500, function(met)
        check(met and keep.dk3.n == 1, "DK3: a start that never left the menu brings the monitor back after 2 s", "powerOff " .. tostring(MM.powerOff))
        skip("DK3: a second start during the switch-off starts once", "needs the game's own LoadingQueueState start, which would load a game")
        if MM.powerOff then MM.powerOff = nil end
        K.errCheck("boot")
    end)
    after(150, function()
        skip("DK5: the boot terms window with the Safe mode option On", "needs the terms version reset and a relaunch")
        local pl = nil
        pcall(function() pl = getSpecificPlayer(0) end)
        check(pl == nil, "DK6: at the main menu ZeD.Safe.fault counts nothing (no player), so the watchdog never trips here")
        note("DK6: the desk's windows draw with no ZeD.Safe.guard or pcall: an error in a desk window's prerender repeats every frame and the watchdog stays off at the menu")
        skip("DK6: a desk window that throws in its prerender", "a forced error every frame can stop a -debug run in the game's debugger; by hand")
    end)
end

-- =========================================================================================================
-- 2: the Continue card (DK7, DK8)
function X.card()
    after(200, function()
        local m = K.ms()
        local vis = false
        pcall(function() vis = m.latestSaveOption ~= nil and m.latestSaveOption:isVisible() end)
        local c = MM.continueInfo()
        local spec = K.spec(K.main(), "continue")
        local row = K.row("file", MM.act.continue)
        check((c ~= nil) == vis and (spec ~= nil) == (c ~= nil) and row ~= nil and (row.disabled == true) == (c == nil),
            "DK7: the Continue card, its button and File's row follow vanilla's Continue",
            "vanilla's Continue " .. tostring(vis) .. ", card " .. tostring(c ~= nil) .. ", button " .. tostring(spec ~= nil) .. ", File row greyed " .. tostring(row and row.disabled))
        if c then
            note("DK7: the card reads " .. K.q(c.who) .. " / " .. K.q(c.title) .. " / " .. K.q(c.where) .. " / " .. K.q(c.played) .. "; dead " .. tostring(c.dead) .. ", picture " .. tostring(c.thumb ~= nil))
        end
        skip("DK7: a dead character's red square and a dead save hiding Continue", "needs a save made dead in Saves/Sandbox/ZeD-QA")
    end)
    after(150, function()
        local tr = ZeD.tr
        local want = tr("UI_ZeD_MainMenu_SaveDate", MM.modeName("Sandbox"), tr("UI_ZeD_MainMenu_MonthOct"), 12)
        local t1 = MM.saveTitle("2026-10-12_14-03-22", "Sandbox")
        local t2 = MM.saveTitle("2026-10-12_14-03-22_crash", "Sandbox")
        local t3 = MM.mapText("Brandenburg, KY;Irvington, KY;Muldraugh, KY")
        local t4 = MM.mapText("Riverside, KY")
        local t5 = MM.saveTitle("My Base", "Survivor")
        check(t1 == want, "DK8: a date-named save reads Mode, Mon D", K.q(t1))
        check(t2 == want .. " (crash)", "DK8: the game's _crash copy keeps (crash)", K.q(t2))
        check(t3 == tr("UI_ZeD_MainMenu_KnoxCountry") and t4 == "Riverside, KY", "DK8: the whole county reads Knox Country, a single map reads as itself", K.q(t3) .. ", " .. K.q(t4))
        check(t5 == "My Base", "DK8: a save named by the player keeps its name", K.q(t5))
        local p = MM.playedText("2026-10-14 19:52:03")
        local pm = tr("UI_ZeD_MainMenu_PM")
        check(string.find(p, "7:52", 1, true) ~= nil and string.find(p, pm, 1, true) ~= nil, "DK8: Last played turns the game's date into the 12-hour clock with the language's PM", K.q(p))
        local lang = "?"
        pcall(function() lang = tostring(Translator.getLanguage()) end)
        note("DK8: the words are checked in this run's language only (" .. lang .. ")")
        skip("DK8: DE, JP and KO (the clock's AM and PM order)", "a sweep never changes the language")
        skip("DK8: a long character name cut with ...", "drawn only, and no save here has a long name; by eye")
    end)
end

-- =========================================================================================================
-- 3: the window, its band and the question (DK9 to DK19)
function X.loadGrey()
    after(200, function()
        local m = K.ms()
        keep.hs9 = m.hasSaveFiles
        m.hasSaveFiles = false
    end)
    after(300, function()
        local m = K.ms()
        local w = K.main()
        local s = K.spec(w, "load")
        local row = K.row("file", MM.act.load)
        local ic = K.icons()
        local c = ic and ic:find("load")
        local off = c and c.item.off and c.item.off()
        local hit = ic and K.hit(ic, "desk:load")
        local inRows = false
        pcall(function() for _, r in ipairs(w:focusRows()) do for _, x in ipairs(r) do if x.id == "load" then inRows = true end end end end)
        m.hasSaveFiles = keep.hs9
        check(s ~= nil and s.disabled and row ~= nil and row.disabled and off and not hit and not inRows,
            "DK9: with no saves Load Game greys in the window, in File and on the icon (no hit), and the pad skips it",
            "window " .. tostring(s and s.disabled) .. ", File " .. tostring(row and row.disabled) .. ", icon off " .. tostring(off) .. ", icon hit " .. tostring(hit ~= nil) .. ", in the pad's rows " .. tostring(inRows))
    end)
    after(300, function()
        local s = K.spec(K.main(), "load")
        check(s ~= nil and (s.disabled == true) == (not MM.hasSaves()), "DK9: with vanilla's flag put back, Load Game follows it again", "saves " .. tostring(MM.hasSaves()))
    end)
end
function X.views()
    after(200, function() K.try("DK10: New Game", MM.act.newGame) end)
    waitFor(function() return K.up("newgame") end, 4000, function(met)
        local a, b = K.modIds("currentGame"), K.modIds("default")
        check(met and a == b, "DK10: New Game opens its view with the default mods copied into the new game's list", "view " .. tostring(MM.view) .. "; new game " .. K.q(a) .. ", default " .. K.q(b))
        local nw = MM.root.newWin
        note("DK10: the newgame view opens with its pick " .. tostring(nw and nw.sel) .. " (challenges " .. tostring(nw and nw.challenges ~= nil) .. "); vanilla's soloScreen:onItemClick(panels[1]) is not run")
        MM.showView("main")   -- (never its Back: that may reload Lua)
    end)
    after(250, function() K.try("DK11: Host", MM.act.host) end)
    waitFor(function() return K.up("host") end, 4000, function(met)
        check(met, "DK11: Host a game lands on the host view", "view " .. tostring(MM.view))
        local c = K.ms() and K.ms().onlineCoopScreen
        pcall(function() if c and c:isVisible() then c:setVisible(false) end end)
        if MM.view ~= "main" then MM.showView("main") end
    end)
    after(250, function() K.try("DK11: Join", MM.act.join) end)
    waitFor(function() return K.up("join") end, 4000, function(met)
        check(met, "DK11: Join a server lands on the join view", "view " .. tostring(MM.view))
        note("DK11: the join view's own onShow asks for the server list (ZeD_MainMenuJoin.lua), in place of vanilla's requestServerList")
        skip("DK11: the server list fills", "needs the network; the Join map covers the rest")
        pcall(function() if getSteamModeActive() then steamReleaseInternetServersRequest() end end)
        MM.showView("main")
    end)
    after(300, function()
        local s = K.spec(K.main(), "mods")
        local n = MM.modCount()
        local real = -1
        pcall(function() real = getActivatedMods():size() end)
        check(s ~= nil and s.text == ZeD.tr("UI_ZeD_MainMenu_ModsCount", n) and n == real, "DK12: the band's Mods (n) counts the mods in use", tostring(s and s.text) .. "; " .. real .. " in use")
        local row = K.row("settings", MM.act.mods)
        check(row ~= nil and row.text == ZeD.tr("UI_ZeD_MainMenu_ModsOn", n), "DK12: Settings' Mods row carries the same count", tostring(row and row.text))
        skip("DK12: the count after a change in Mods", "Mods' own map turns mods on and off (nothing is ever accepted here)")
        K.errCheck("the window's views")
    end)
end
function X.quitQ()
    after(200, function()
        MM.forceGamepad = true
        K.try("DK13: Exit asked from File", MM.act.askQuit)
    end)
    after(300, function()
        local w = K.main()
        local r = { confirm = w.confirm, f = w.focusId, view = MM.view }
        local yes = K.spec(w, "confirm:yes")
        r.yesGrey = yes and yes.disabled
        local p1 = w:getFooterPrompts()
        w.focusId = "confirm:no"
        local p2 = w:getFooterPrompts()
        r.a1 = p1 and p1[1] and p1[1].label
        r.a2 = p2 and p2[1] and p2[1].label
        w:setConfirm(false)   -- (Cancel: never Exit)
        r.after = w.confirm
        MM.forceGamepad = keep.pad0
        local cool = nil
        pcall(function() cool = isQuitCooldown() end)
        check(r.confirm == true and r.view == "main", "DK13: Exit asks in the main window's band", "view " .. tostring(r.view))
        check(r.after == false, "DK13: the quit question answered Cancel (never Exit)")
        note("DK13: (director) the quit question puts the pad on " .. tostring(r.f) .. " (Exit): pad A, A quits from the band")
        local exitW = getText("IGUI_Exit")
        check(r.a2 ~= exitW, "DK14: with the pad on Cancel the question's footer no longer says A " .. exitW,
            "the footer says A " .. tostring(r.a2) .. " with the focus on Cancel (A " .. tostring(r.a1) .. " on Exit)")
        check(cool == false, "DK15: no quit cooldown at the main menu", "isQuitCooldown " .. tostring(cool))
        note("DK15: the question's Exit is never greyed by the cooldown (greyed now: " .. tostring(r.yesGrey == true) .. "), while the band's Quit is; MM.act.quit returns silently while cooling")
    end)
end
function X.closeBox()
    after(200, function()
        local w = K.main()
        w.focusId = "newgame"
        w:joyB()
        keep.b16 = MM.view
        K.try("DK16: the main window's close box", function() w:close() end)
    end)
    waitFor(function() return MM.view == "desktop" end, 2000, function(met)
        check(keep.b16 == "main", "DK16: B on the main window closes nothing", "view after B " .. tostring(keep.b16))
        check(met, "DK16: the close box takes the main window down to the bare desktop", "view " .. tostring(MM.view))
        local ic = K.icons()
        ic._openedAt, ic._lastClick = nil, nil
        K.try("DK16: the Project Zomboid icon opened", function() ic:open("pz") end)
    end)
    waitFor(function() return K.up("main") end, 2000, function(met)
        check(met and K.main().focusId == "newgame", "DK16: the Project Zomboid icon brings the main window back on the same focus", "view " .. tostring(MM.view) .. ", focus " .. tostring(K.main().focusId))
    end)
    after(200, function()
        local w = K.main()
        if w.keyOther ~= nil then skip("DK17: Return on the main window", "the main window has a key handler now: not pressed blind"); return end
        local m = K.ms()
        local r1 = MM.keyRelease(m, Keyboard.KEY_RETURN)
        local r2 = MM.keyRelease(m, Keyboard.KEY_DOWN)
        check(not r1 and not r2 and MM.view == "main", "DK17: Return and the arrow keys on the main window do nothing", "handled " .. tostring(r1) .. " " .. tostring(r2))
        note("DK17: (director, keyboard play) the main window has no key of its own; MM.keyRelease's comment says Return plays or goes on (drift); the arrows move only the bare desktop's icons")
    end)
    after(200, function()
        local g = MM.root.glass
        local pr = g and g._hits and g._hits[1]
        local deskHit = MM.root._hits and MM.root._hits[1]
        check(pr ~= nil and pr.id == "power", "DK18: the power button's hint points at the button",
            "the glass has no hit boxes of its own (glass._hits " .. tostring(g and g._hits) .. "); the power hit is the desk's (" .. tostring(deskHit and deskHit.id) .. "), so the hint falls back to the pointer's place")
    end)
end
function X.powerPast()
    after(200, function() D.npReset(); K.try("DK19: the notepad opened", function() MM.openNotepad() end) end)
    waitFor(function() return K.up("notepad") end, 3000, function(met)
        if not met then keep.no19 = true; skip("DK19: the power button past the notepad's question", "the notepad did not open (view " .. tostring(MM.view) .. ")"); return end
        K.win("notepad").edit:setText("zedqa dk19 words")
    end)
    after(200, function()
        if keep.no19 then return end
        local hit = MM.root._hits and MM.root._hits[1]
        if hit and hit.id == "power" and hit.fn then K.try("DK19: the power button", hit.fn) end
    end)
    after(300, function()
        if keep.no19 then return end
        local w = K.main()
        local d = N.draft()
        check(MM.view == "main" and w.confirm == true, "DK19: the power button leaves the notepad (no Save changes?) and asks to quit", "view " .. tostring(MM.view))
        check(d ~= nil and d.text == "zedqa dk19 words", "DK19: the notepad's unsaved words are kept as a draft on the way", "draft " .. K.q(d and d.text))
        w:setConfirm(false)
        note("DK19: the power button, File > Exit and the menu bar leave any view through MM.showView, past its own leave question: the notepad keeps a draft; the Workshop and the description editor keep nothing (DK58, DK59)")
        D.npReset()
        K.errCheck("the main window")
    end)
end

-- =========================================================================================================
-- 4: the menu bar (DK20 to DK28)
function X.barRows()
    after(200, function()
        local A, tr = MM.act, ZeD.tr
        local keys = {}
        for _, mn in ipairs(MM.menus()) do keys[#keys + 1] = mn.key end
        local want = "zed file mp settings" .. (getDebug() and " debug" or "")
        check(table.concat(keys, " ") == want, "DK20: the bar's titles, left to right", table.concat(keys, " "))
        local miss = {}
        local function need(key, label, pred)
            local items = {}
            pcall(function() items = MM.menuItems(key) or {} end)
            if not K.rowBy(items, pred) then miss[#miss + 1] = key .. ": " .. label end
        end
        local function fnIs(f) return function(it) return it.fn == f end end
        local function textIs(t) return function(it) return it.text == t end end
        need("zed", "About", function(it) return it.about end)
        need("zed", "Credits", fnIs(A.credits)); need("zed", "Terms of service", fnIs(A.tos)); need("zed", "Report a bug", fnIs(A.reportBug))
        if not St.lite() then
            need("zed", "CletusWorks Notepad", textIs(tr("UI_ZeD_Desk_NotepadTitle")))
            need("zed", "Pasties", textIs(tr("UI_ZeD_Desk_Pasties")))
            need("zed", "ProtoPOP3 Mail", textIs(tr("UI_ZeD_Mail_AppName")))
        end
        need("file", "Continue", fnIs(A.continue)); need("file", "New Game", fnIs(A.newGame)); need("file", "Load Game", fnIs(A.load))
        need("file", "Tutorial", fnIs(A.tutorial)); need("file", "Exit", fnIs(A.askQuit))
        need("mp", "Join", fnIs(A.join)); need("mp", "Host", fnIs(A.host))
        need("settings", "Options", fnIs(A.options)); need("settings", "Mods", fnIs(A.mods))
        need("settings", "the first-launch setup", textIs(tr("UI_ZeD_Welcome_MenuItem"))); need("settings", "Desktop...", textIs(tr("UI_ZeD_MainMenu_Desktop")))
        if getDebug() then need("debug", "Reset Lua", fnIs(A.resetLua)) end
        local wo = K.ms() and K.ms().workshopOption ~= nil
        local wsRow = K.row("settings", A.workshop) ~= nil
        check(#miss == 0 and wsRow == wo, "DK20: every pull-down holds its rows (Workshop only with vanilla's workshopOption)",
            K.short(miss) .. ((wsRow ~= wo) and ("; Workshop row " .. tostring(wsRow) .. ", workshopOption " .. tostring(wo)) or ""))
        skip("DK20: the rows with Steam on", "the sweep runs without Steam")
    end)
    after(150, function() MM.ctx.open = "zed"; MM.ctx.dropFocus = 1 end)
    after(350, function()
        local d, L = MM.root.drop, MM.layout()
        local bottom = d:getAbsoluteY() + d:getHeight()
        check(d:isVisible() and bottom <= L.ty + L.th + 1, "DK21: the ZeD menu with its About block ends on the monitor's tube",
            "its foot at " .. K.n(bottom) .. ", the tube's at " .. K.n(L.ty + L.th) .. " (" .. K.screen() .. ", scale " .. tostring(ZeD.T and ZeD.T.scale) .. ")")
        note("DK21: a menu bar pull-down is never cut or scrolled (dropScrollMax " .. tostring(MM.ctx.dropScrollMax) .. "): its room test runs for pop-ups only; at 1280 x 720 or with Large text the ZeD menu can run past the tube (not stageable at this screen size)")
        MM.ctx.open = nil
    end)
    after(250, function()
        local c = MM.clock()
        local h24 = true
        pcall(function() h24 = getCore():getOptionClock24Hour() end)
        local am, pm = ZeD.tr("UI_ZeD_MainMenu_AM"), ZeD.tr("UI_ZeD_MainMenu_PM")
        if h24 then
            note("DK22: the game's clock is 24-hour here: the bar reads " .. K.q(c) .. "; in 12-hour mode it is always English (SimpleDateFormat with Locale.ENGLISH)")
            skip("DK22: the bar's 12-hour clock in another language", "the clock option is 24-hour and a sweep never changes the language")
        elseif am == "AM" and pm == "PM" then
            check(string.find(c, "AM", 1, true) ~= nil or string.find(c, "PM", 1, true) ~= nil, "DK22: the bar's 12-hour clock has its AM or PM", K.q(c))
            note("DK22: the bar's clock is English in every language (Locale.ENGLISH) while Last played uses the language's AM and PM; English here, so they agree")
        else
            check(false, "DK22: the bar's 12-hour clock follows the language's AM and PM", "the bar reads " .. K.q(c) .. " in English while Last played uses " .. am .. " / " .. pm)
        end
    end)
    after(150, function()
        local zv, gv = MM.zedVersion(), MM.version()
        check(zv ~= "?" and gv ~= "", "DK23: About has ZeD's version and the game's build", K.q(zv) .. ", " .. K.q(gv))
        local up = getTimestampMs() - (MM._bootMs or 0)
        check(type(MM._bootMs) == "number" and up >= 0, "DK23: Uptime counts from the menu file's load", K.n(up / 60000) .. " min")
        note("DK23: Uptime starts again on a Lua reload (MM._bootMs is set when the file loads); Display reads " .. K.screen() .. " at " .. tostring(ZeD.T and ZeD.T.scale) .. "x")
        check(K.row("zed", MM.act.reportBug) ~= nil, "DK24: the ZeD menu has Report a bug")
        note("DK24: (director) Report a bug sends a ZeD player to TIS's bug forum (vanilla's onClickReportBug); ZeD's own report path is not on the desk")
        skip("DK24: Report a bug pressed", "it opens a web page")
        if getDebug() then
            local ds = DebugScenarios and DebugScenarios.instance
            note("DK25: Debug > Scenarios is " .. (ds and "there" or "gone") .. " (vanilla drops DebugScenarios.instance once any of its items fires)")
            skip("DK25: Scenarios gone after a vanilla item fires", "firing a vanilla item here would start what it starts")
            local row = K.row("debug", MM.act.resetLua)
            check(row ~= nil, "DK26: Debug > Reset Lua is there")
            note("DK26: Reset Lua runs at once with no question (as the game's own button); never pressed here")
        else
            skip("DK25: Debug > Scenarios", "the game is not in debug mode")
            skip("DK26: Debug > Reset Lua", "the game is not in debug mode")
        end
    end)
end
function X.pointer()
    after(200, function()
        local n = { picked = 0 }
        local bar = K.fake({ { id = "menu:a", x = 0, y = 0, w = 10, h = 10, menu = "a" }, { id = "menu:b", x = 20, y = 0, w = 10, h = 10, menu = "b" } })
        local drop = K.fake({ { id = "drop:a:1", x = 0, y = 20, w = 10, h = 10, inDrop = true, fn = function() n.picked = n.picked + 1 end } })
        local panels = { drop, bar }
        local ctx = { open = nil, hot = nil, press = nil, wasDown = false }
        local r = {}
        local function run(steps) local ok, e = K.pointerRun(steps, ctx, panels); if not ok then r.err = tostring(e) end end
        local bl = false
        pcall(function() bl = MM.blocked() end)
        run({ { 5, 5, false }, { 5, 5, true }, { 5, 5, false } }); r.open = ctx.open
        run({ { 5, 5, true }, { 5, 5, false } }); r.shut = ctx.open
        run({ { 5, 5, true }, { 5, 5, false }, { 25, 5, false } }); r.switch = ctx.open
        run({ { 50, 50, true }, { 50, 50, false } }); r.out = ctx.open; r.outPick = n.picked
        run({ { 5, 5, true }, { 5, 15, true }, { 5, 25, true }, { 5, 25, false } }); r.drag = n.picked; r.dragOpen = ctx.open
        local d = "blocked " .. tostring(bl) .. (r.err and (", " .. r.err) or "")
        check(r.open == "a", "DK27: a press on a title opens its menu", tostring(r.open) .. "; " .. d)
        check(r.shut == nil, "DK27: a press on the open title shuts it", tostring(r.shut))
        check(r.switch == "b", "DK27: with a menu open, pointing at another title switches to it", tostring(r.switch))
        check(r.out == nil and r.outPick == 0, "DK27: a press outside the open menu only shuts it", tostring(r.out) .. ", picked " .. r.outPick)
        check(r.drag == 1 and r.dragOpen == nil, "DK27: a press-drag from a title to a row picks the row and shuts the menu", "picked " .. r.drag .. ", open " .. tostring(r.dragOpen))
        note("DK27: driven on stand-in panels through MM.pointer with the mouse stood in for; a real pointer by hand")
    end)
end
function X.padBar()
    after(200, function() MM.forceGamepad = true; MM.showView("main") end)
    after(250, function()
        local m, w = K.ms(), K.main()
        local rows = w:focusRows()
        w.focusId = rows[1] and rows[1][1] and rows[1][1].id
        MM.ctx.barFocus = 1
        local r = {}
        pcall(MM.joyDir, m, "up"); r.up = MM.deskAt
        pcall(MM.joyDir, m, "right"); r.right = MM.ctx.barFocus
        pcall(MM.joyDir, m, "left"); r.left = MM.ctx.barFocus
        pcall(MM.joyDown, m, Joypad.AButton); r.open = MM.ctx.open; r.df = MM.ctx.dropFocus
        pcall(MM.joyDir, m, "right"); r.next = MM.ctx.open
        pcall(MM.joyDir, m, "left"); r.prev = MM.ctx.open
        pcall(MM.joyDown, m, Joypad.BButton); r.shut = MM.ctx.open; r.stay = MM.deskAt
        pcall(MM.joyDown, m, Joypad.BButton); r.back = MM.deskAt
        MM.ctx.open = nil
        check(r.up == "bar", "DK28: Up off the main window's top control goes to the menu bar", tostring(r.up))
        check(r.right == 2 and r.left == 1, "DK28: Left and Right walk the bar's titles", tostring(r.right) .. ", " .. tostring(r.left))
        check(r.open == "zed" and r.df == 1, "DK28: A on a title opens its pull-down on row 1", tostring(r.open) .. ", row " .. tostring(r.df))
        check(r.next == "file" and r.prev == "zed", "DK28: Left and Right inside a pull-down change title", tostring(r.next) .. ", " .. tostring(r.prev))
        check(r.shut == nil and r.stay == "bar" and r.back == nil, "DK28: B shuts the pull-down, a second B goes back to the window", tostring(r.shut) .. ", " .. tostring(r.stay) .. ", " .. tostring(r.back))
    end)
    after(200, function()
        local m = K.ms()
        MM.toBar(nil)
        MM.ctx.barFocus = 1
        pcall(MM.joyDown, m, Joypad.AButton)
        local live = MM.dropLive()
        local it = live[1]
        local tr = ZeD.tr
        -- (only a row that opens a desk window is pressed: the notepad on the stand-in disk, or Credits in Lite)
        local safe = it and (it.text == tr("UI_ZeD_Desk_NotepadTitle") or it.fn == MM.act.credits)
        keep.r28 = { text = it and it.text, safe = safe }
        if safe then pcall(MM.joyDown, m, Joypad.AButton) else MM.ctx.open = nil end
    end)
    after(300, function()
        local r = keep.r28
        if not r.safe then skip("DK28: A on a row hands the pad back to the window", "the ZeD menu's first row is " .. K.q(r.text) .. ": not pressed blind")
        else check(MM.deskAt == nil and MM.ctx.open == nil and MM.view ~= "main", "DK28: A on a row picks it and hands the pad back to the window", "picked " .. K.q(r.text) .. ", view " .. tostring(MM.view) .. ", deskAt " .. tostring(MM.deskAt)) end
        MM.showView("main")
        D.npReset()
        MM.forceGamepad = keep.pad0
        K.errCheck("the menu bar")
    end)
end

-- =========================================================================================================
-- 5: the desktop and its icons (DK29, DK31 to DK33; DK30 once the Pasties are down)
function X.desk()
    after(200, function()
        local ids = {}
        for _, c in ipairs((K.icons() and K.icons()._cells) or {}) do if not c.left then ids[#ids + 1] = tostring(c.item.id) end end
        note("DK29: (director) the right column holds " .. table.concat(ids, " ") .. "; no icon for Continue, Host, Tutorial or Credits, while the file's header says the icons open everything the menus can")
        MM.showView("desktop")
    end)
    after(250, function()
        local ic = K.icons()
        ic._openedAt, ic._lastClick = nil, nil
        ic:click("pz")
        keep.c31 = { sel = ic.focusId, view = MM.view }
        ic:click("pz")
    end)
    after(250, function()
        check(keep.c31.sel == "pz" and keep.c31.view == "desktop" and MM.view == "main", "DK31: one click selects an icon, a second within 450 ms opens it",
            "after one " .. tostring(keep.c31.sel) .. " / " .. tostring(keep.c31.view) .. ", after two " .. tostring(MM.view))
        MM.showView("desktop")
    end)
    after(250, function()
        local ic = K.icons()
        ic._openedAt, ic._lastClick = nil, nil
        ic.focusId = "trash"
        keep.r31 = MM.keyRelease(K.ms(), Keyboard.KEY_RETURN)
    end)
    after(250, function()
        check(keep.r31 == true and MM.view == "trash", "DK31: Return opens the selected icon", "view " .. tostring(MM.view))
        MM.showView("desktop")
    end)
    after(250, function()
        local ic = K.icons()
        ic.focusId = "pz"
        MM.keyRelease(K.ms(), Keyboard.KEY_DOWN)
        check(ic.focusId ~= "pz" and MM.view == "desktop", "DK31: an arrow key moves the desktop's selection", "now on " .. tostring(ic.focusId))
        skip("DK31: the frame-counted double-click opens once", "needs real mouse presses; by hand")
        MM.forceGamepad = true
        ic.focusId = "pz"
        local p = ic:prompts()
        check(K.hasLabel(p, getText("IGUI_Open")), "DK33: on an icon the bare desktop's prompts say Open", K.labels(p))
        note("DK33: the prompts sit along the tube's foot at the left (drawn by the icon layer; read from its code, not from a picture)")
        MM.showView("main")
    end)
    after(250, function()
        local m, w, ic = K.ms(), K.main(), K.icons()
        local r = {}
        w.focusId = "newgame"
        pcall(MM.joyDir, m, "right")
        r.at, r.icon = MM.deskAt, ic.focusId
        local c = ic:find(r.icon or "")
        local wr = K.rect(w)
        if c then
            r.under = (c.x + c.w / 2 >= wr.x and c.x + c.w / 2 < wr.x + wr.w and c.y + c.h / 2 >= wr.y and c.y + c.h / 2 < wr.y + wr.h)
            r.side = c.x + c.w / 2 >= wr.x + wr.w
        end
        for _ = 1, 3 do if MM.deskAt == "icons" then pcall(MM.joyDir, m, "left") end end
        r.back = MM.deskAt
        w.focusId = "newgame"
        pcall(MM.joyDir, m, "left")
        r.lat, r.licon = MM.deskAt, ic.focusId
        if r.lat == "icons" then
            for _ = 1, 12 do if MM.deskAt ~= "bar" then pcall(MM.joyDir, m, "up") end end
            r.bar, r.bback = MM.deskAt, MM.deskBack
            pcall(MM.joyDown, m, Joypad.BButton)
            r.after = MM.deskAt
        end
        MM.deskAt, MM.deskBack = nil, nil
        check(r.at == "icons" and r.side == true and r.under == false, "DK32: Right from New Game leaves the window at once for an icon on that side, not under it",
            tostring(r.at) .. " on " .. tostring(r.icon) .. ", right of the window " .. tostring(r.side) .. ", under it " .. tostring(r.under))
        check(r.back == nil, "DK32: pushing back toward the window returns to it", "deskAt " .. tostring(r.back))
        if St.lite() then skip("DK32: Left to the left column", "Lite has no left column")
        else
            check(r.lat == "icons", "DK32: Left from New Game reaches the left column", tostring(r.lat) .. " on " .. tostring(r.licon))
            check(r.bar == "bar" and r.bback == "icons" and r.after == "icons", "DK28: Up from the icons reaches the bar, and B there goes back to the icons",
                tostring(r.bar) .. " (back " .. tostring(r.bback) .. "), after B " .. tostring(r.after))
        end
        local blk = MM.iconBlock and MM.iconBlock(MM.layout())
        note("DK32: checked in the " .. ((K.main()._small and "small layout") or "room") .. " framing at " .. K.screen() .. (blk and (", the icon block " .. K.n(blk.w) .. " px wide") or ""))
        MM.forceGamepad = keep.pad0
        K.errCheck("the desktop")
    end)
end

-- =========================================================================================================
-- 6: Pasties, on the stand-in disk (DK30, DK34 to DK39)
function X.pastiesMake()
    after(200, function()
        MM.forceGamepad = true   -- (no caret goes into a new note)
        MM.showView("main")
        D.syncFields()
    end)
    after(300, function()
        local ids = {}
        for _ = 1, 9 do
            local id = nil
            pcall(function() id = MM.newPastie() end)
            ids[#ids + 1] = tostring(id)
        end
        keep.p34 = ids
    end)
    after(350, function()
        local n = #N.pasties()
        check(n == 8 and keep.p34[9] == "nil", "DK34: eight Pasties at most: the ninth press makes none", table.concat(keep.p34, " "))
        local item = K.leftItem("pasties")
        local row = K.rowBy(MM.menuItems("zed"), function(it) return it.text == ZeD.tr("UI_ZeD_Desk_Pasties") end)
        check(item ~= nil and item.off() and row ~= nil and row.disabled, "DK34: with eight on the desk the Pasties icon and its ZeD menu row grey",
            "icon off " .. tostring(item and item.off()) .. ", row greyed " .. tostring(row and row.disabled))
        local wr, L = K.rect(K.main()), MM.layout()
        local under, out = 0, 0
        for _, pa in ipairs(N.pasties()) do
            local c = K.icons():find("pastie:" .. pa.id)
            if c then
                if K.overlap({ x = c.x, y = c.y, w = c.w, h = c.h }, wr) then under = under + 1 end
                if c.x < L.tx - 1 or c.y < L.ty - 1 or c.x + c.w > L.tx + L.tw + 1 or c.y + c.h > L.ty + L.th + 1 then out = out + 1 end
            end
        end
        check(out == 0, "DK34: every new note lies on the monitor's tube", out .. " of " .. n .. " off it")
        note("DK34: with the main window open, " .. under .. " of " .. n .. " new notes went under it (a note goes off the window and the icons while there is room, else under the window without the caret)")
        -- DK30 with the notes down
        local cs = MM._deskCells(MM.layout())
        local left, want = 0, 0
        for _, c in ipairs(cs) do if c.left then left = left + 1 end end
        for _, it in ipairs(MM.leftItems()) do if not (it.hide and it.hide()) then want = want + 1 end end
        check(left == want, "DK30: every left-column item and every Pastie note has its place on the desk", left .. " of " .. want .. " laid out at " .. K.screen() .. ", scale " .. tostring(ZeD.T and ZeD.T.scale))
        note("DK30: once the left column would reach the right block, every later item (Mail, Documents, every Pastie note, moved ones too) is dropped from the desk; at UI scale 2, Large text or a narrow tube (not stageable at this size)")
    end)
end
function X.pastiesSave()
    after(200, function()
        local id = N.pasties()[1].id
        keep.p35 = id
        keep.f35 = "ZeD_desk_pastie_" .. id .. ".txt"
        local st = MM.root.pasties[id]
        -- (typing: the field has the keys; an unfocused field saves on its next update)
        pcall(function() st:wake() end)
        st.entry:setText("zedqa note words")
        pcall(function() st.entry:focus() end)
        st._changedAt = MM.now()
        keep.foc35 = st.entry:isFocused()
    end)
    after(200, function() keep.mid35 = D.disk[keep.f35] end)
    waitFor(function() return D.disk[keep.f35] == "zedqa note words\n" end, 3000, function(met)
        if keep.foc35 then
            check(keep.mid35 ~= "zedqa note words\n" and met, "DK35: a note saves a moment (800 ms) after the typing stops",
                "0.2 s in " .. K.q(keep.mid35) .. ", then " .. K.q(D.disk[keep.f35]))
        else
            check(met, "DK35: a note's words are saved (its field would not take the keys here, so the 800 ms wait was not timed)", K.q(D.disk[keep.f35]))
        end
        local id = keep.p35
        local st = MM.root.pasties[id]
        pcall(function() st.entry:unfocus() end)
        N.savePastie(id, string.rep("x", 700))
        check(#N.pastieText(id) == 600, "DK35: a note holds at most 600 characters", #N.pastieText(id))
        st.entry:setText("zedqa escape words")
        st._changedAt = MM.now()
        pcall(function() st.entry.onOtherKey(st.entry, Keyboard.KEY_ESCAPE) end)
        check(N.pastieText(id) == "zedqa escape words", "DK35: Escape saves the words at once", K.q(N.pastieText(id)))
        note("DK35: the field takes 12 lines (setMaxLines); the file itself has no line cap")
        skip("DK35: a press elsewhere saves the note", "needs a real mouse press; by hand")
    end)
    after(200, function()
        local id = keep.p35
        local it = K.leftItem("pastie:" .. id)
        local r = {}
        r.closed = it.close()
        r.asking = it.asking()
        it.answer(false)
        r.kept = N.pastie(id) ~= nil and not it.asking()
        local id2 = N.pasties()[2].id
        local it2 = K.leftItem("pastie:" .. id2)
        N.savePastie(id2, "")
        MM.root.pasties[id2].entry:setText("")
        r.empty = it2.close()
        r.gone = N.pastie(id2) == nil
        r.file = D.disk["ZeD_desk_pastie_" .. id2 .. ".txt"]
        r.reuse = nil
        pcall(function() r.reuse = MM.newPastie() end)
        r.id2 = id2
        r.again = it.close()
        it.answer(true)
        r.thrown = N.pastie(id) == nil
        check(r.closed == false and r.asking == true, "DK36: closing a note with words asks first (Throw away or Keep)", tostring(r.closed) .. ", asking " .. tostring(r.asking))
        check(r.kept, "DK36: Keep keeps the note")
        check(r.empty == true and r.gone, "DK36: an empty note goes at once", tostring(r.empty))
        check(r.file == "\n" and r.reuse == id2, "DK36: a thrown note's file is emptied and its slot reused", K.q(r.file) .. ", new note " .. tostring(r.reuse) .. " for slot " .. id2)
        check(r.again == false and r.thrown, "DK36: Throw away takes the note with words")
    end)
end
function X.pastiesPile()
    after(200, function()
        local ps = N.pasties()
        local a, b = ps[#ps - 1].id, ps[#ps].id
        N.movePastie(a, 0.5, 0.5, true)
        N.movePastie(b, 0.5, 0.5, true)
        keep.p37 = { a = a, b = b }
    end)
    after(350, function()
        local sa = MM.root.pasties[keep.p37.a]
        check(sa._covered == true and not sa.entry:isVisible(), "DK37: a note under another has its box down (the icon layer draws its words)",
            "covered " .. tostring(sa._covered) .. ", box up " .. tostring(sa.entry:isVisible()))
        -- the top note under the main window
        local c = K.icons():find("pastie:" .. keep.p37.b)
        local w = K.main()
        local wr = K.rect(w)
        if c and c.room then
            local fx, fy = MM._stickyFractions(c.room, wr.x + wr.w / 2 - c.w / 2, wr.y + wr.h / 2 - c.h / 2)
            N.movePastie(keep.p37.b, fx, fy, true)
        end
        keep.mid37 = { x = wr.x + wr.w / 2, y = wr.y + wr.h / 2 }
    end)
    after(350, function()
        local e = MM.entryUnder(keep.mid37.x, keep.mid37.y)
        check(e == nil, "DK37: a press on a note under a window goes to the window", "the note's field took it: " .. tostring(e ~= nil))
        skip("DK37: a press on a lower note wakes it", "needs a real pointer on the pile; by hand")
        D.syncFields()
        K.errCheck("Pasties")
    end)
end
function X.pastiesOld()
    after(200, function()
        D.disk["ZeD_desk_pasties.txt"] = nil
        for i = 1, 8 do D.disk["ZeD_desk_pastie_" .. i .. ".txt"] = nil end
        D.disk["ZeD_desk_sticky.txt"] = "old sticky words\n"
        D.disk["ZeD_desk_sticky_place.txt"] = "1|0.2500|0.7500\n"
        N.reset()
        N.seq = N.seq + 1
        local ps = N.pasties()
        local p = ps[1]
        check(#ps == 1 and p and p.id == 1 and K.near(p.fx, 0.25) and K.near(p.fy, 0.75) and N.pastieText(1) == "old sticky words",
            "DK38: the old sticky's words become Pastie 1 at its old place", #ps .. " notes, " .. tostring(p and p.fx) .. "," .. tostring(p and p.fy) .. ", " .. K.q(N.pastieText(1)))
        check(D.disk["ZeD_desk_sticky.txt"] == "\n" and D.disk["ZeD_desk_pasties.txt"] ~= nil, "DK38: the old sticky's file is emptied and the Pasties' file made", K.q(D.disk["ZeD_desk_sticky.txt"]))
        D.syncFields()
        MM.forceGamepad = true
        MM.showView("desktop")
    end)
end
function X.pastiesPad()
    after(300, function()
        local ic = K.icons()
        ic._carry = nil
        ic.focusId = "pastie:1"
        local p0 = N.pastie(1)
        keep.r39 = { fx0 = p0.fx, fy0 = p0.fy, pr0 = ic:prompts() }
        ic:joyA()
        keep.r39.carry = ic._carry ~= nil
        keep.r39.pr1 = ic:prompts()
        ic:joyDir("right")
    end)
    after(250, function()
        local ic, r = K.icons(), keep.r39
        r.moved = not K.near(N.pastie(1).fx, r.fx0)
        ic:joyB()
        r.back = K.near(N.pastie(1).fx, r.fx0) and K.near(N.pastie(1).fy, r.fy0) and ic._carry == nil
    end)
    after(250, function()
        local ic = K.icons()
        ic:joyA()
        ic:joyDir("down")
    end)
    after(250, function()
        local ic, r = K.icons(), keep.r39
        local w0 = D.writes
        ic:joyA()
        r.drop = ic._carry == nil and not K.near(N.pastie(1).fy, r.fy0) and D.writes > w0
        ic:joyY()
        r.ask = MM._pastieAsk[1] == true
        r.pr2 = ic:prompts()
        ic:joyB()
        r.kept = N.pastie(1) ~= nil and not MM._pastieAsk[1]
        r.realPad = K.realPad()
        if not r.realPad then
            ic:joyX()
            local st = MM.root.pasties[1]
            r.typing = st and st.entry and st.entry:isFocused()
            pcall(function() st.entry:unfocus(); st:keep() end)
        end
    end)
    after(200, function()
        local r = keep.r39
        local tr = ZeD.tr
        check(r.carry and r.moved, "DK39: A picks a note up and the D-pad moves it", "carried " .. tostring(r.carry) .. ", moved " .. tostring(r.moved))
        check(r.back, "DK39: B puts it back where it was")
        check(r.drop, "DK39: A puts it down where it is, and the place is kept")
        check(r.ask and r.kept, "DK39: Y asks before a note with words goes, and B keeps it", "asked " .. tostring(r.ask) .. ", kept " .. tostring(r.kept))
        if r.realPad then skip("DK39: X writes on the note", "a real controller is on the menu: X would bring up the game's on-screen keyboard")
        else check(r.typing == true, "DK39: X writes on the note (its field takes the keys)", tostring(r.typing)) end
        skip("DK39: X brings up the game's on-screen keyboard", "the keyboard comes only with a real pad")
        check(K.hasLabel(r.pr0, tr("UI_ZeD_Desk_StickyPickUp")) and K.hasLabel(r.pr0, tr("UI_ZeD_Notebook_Write")) and K.hasLabel(r.pr0, getText("UI_Close")),
            "DK33: on a note the prompts say Pick up, Write and Close", K.labels(r.pr0))
        check(K.hasLabel(r.pr1, tr("UI_ZeD_Desk_StickyPutDown")) and K.hasLabel(r.pr1, getText("UI_Cancel")), "DK33: carrying a note the prompts say Put down and Cancel", K.labels(r.pr1))
        check(K.hasLabel(r.pr2, tr("UI_ZeD_Desk_PastieThrow")) and K.hasLabel(r.pr2, tr("UI_ZeD_Cl_Keep")), "DK33: a note asking says Throw away and Keep", K.labels(r.pr2))
        D.syncFields()
        K.icons().focusId = "pz"
        MM.forceGamepad = keep.pad0
        MM.showView("main")
        K.errCheck("Pasties on the pad")
    end)
end

-- =========================================================================================================
-- 7: the Trash and the desktops (DK40 to DK45)
function X.trash()
    after(200, function() MM.forceGamepad = true; MM.showView("trash") end)
    waitFor(function() return K.up("trash") end, 3000, function(met)
        local w = K.win("trash")
        local r = { f0 = w.focusId }
        w:empty()
        r.ask, r.f1 = w.confirm, w.focusId
        w.focusId = "confirm:no"
        local p2 = w:getFooterPrompts()
        r.a2 = p2 and p2[1] and p2[1].label
        w:joyB()
        r.no, r.f2, r.v = w.confirm, w.focusId, MM.view
        w:empty()
        w:keyEscape()
        r.esc, r.v2 = w.confirm, MM.view
        w:keyEscape()
        r.v3 = MM.view
        MM.forceGamepad = keep.pad0
        check(met and r.f0 == "close", "DK40: the Trash opens with the pad on Close", tostring(r.f0))
        check(r.ask == true, "DK40: Empty trash asks Quit Project Zomboid? in the band")
        note("DK13: (director) the Trash's question puts the pad on " .. tostring(r.f1) .. " (Exit)")
        check(r.no == false and r.f2 == "empty" and r.v == "trash", "DK40: B answers Cancel and goes back to Empty trash", tostring(r.no) .. ", " .. tostring(r.f2))
        check(r.esc == false and r.v2 == "trash" and r.v3 == "desktop", "DK40: Escape cancels the question, a second Escape closes the Trash", tostring(r.v2) .. ", then " .. tostring(r.v3))
        local exitW = getText("IGUI_Exit")
        check(r.a2 ~= exitW, "DK14: with the pad on Cancel the Trash's footer no longer says A " .. exitW, "the footer says A " .. tostring(r.a2) .. " with the focus on Cancel")
        skip("DK40: the quit itself", "never pressed")
        MM.showView("main")
    end)
end
function X.wall()
    after(200, function()
        local w0 = MM.desktop()
        local other = (w0 == "slate") and "classic" or "slate"
        MM.setDesktop(other)
        local f = K.readLines("ZeD_wallpaper.txt")
        MM._wall = nil
        local again = MM.desktop()
        check(f ~= nil and f[1] == other and again == other, "DK41: a pick writes ZeD_wallpaper.txt at once and a fresh read gives it back", K.q(f and f[1]) .. ", read again " .. K.q(again))
        check(DS.idOf("original") == "painting" and DS.idOf("new") == "video" and DS.idOf("zedqa-nonsense") == "painting" and DS.idOf(nil) == "painting",
            "DK41: the old words read as the painting and the video, anything else or no file as the painting")
        MM.setDesktop(w0)
        local vfx = nil
        pcall(function() vfx = getCore():getOptionDoVideoEffects() end)
        check(DS.isGame("video") and DS.isGame("painting"), "DK42: the painting and the title video are the game's own pictures (MM.drawGameArt)")
        note("DK42: the game's video effects are " .. (vfx and "on: Title video plays on the tube and its swatch" or "off: the painting stands in for Title video") .. "; the option is never changed by a sweep")
        skip("DK42: Title video with the video effects the other way", "a sweep never changes the game's video options; by hand")
    end)
    after(200, function()
        local h0 = K.hl()
        local r = {}
        pcall(function()
            K.setHL(1, 0, 0)
            local a1, a2, a3 = DS.ground()
            local b1, b2, b3 = DS.tone(1, 0, 0)
            r.red = K.near(a1, b1) and K.near(a2, b2) and K.near(a3, b3)
            K.setHL(1, 1, 1)
            a1, a2, a3 = DS.ground()
            b1, b2, b3 = DS.tone(1, 1, 1)
            r.white = K.near(a1, b1) and K.near(a2, b2) and K.near(a3, b3)
        end)
        if h0 then K.setHL(h0[1], h0[2], h0[3]) end
        local back = K.hl()
        r.back = h0 ~= nil and back ~= nil and K.near(back[1], h0[1]) and K.near(back[2], h0[2]) and K.near(back[3], h0[3])
        local key = (ZeD.T and ZeD.T.accentKey) or ZeD.currentAccent
        local sets = ZeD.AccentColors or {}
        local set = sets[key] or sets.orange
        local a = set and set.dark and set.dark.accent
        if a then
            local x1, x2, x3 = DS.accentGround()
            local y1, y2, y3 = DS.tone(a.r, a.g, a.b)
            r.accent = K.near(x1, y1) and K.near(x2, y2) and K.near(x3, y3)
        end
        check(r.red and r.white, "DK43: the patterns follow the game's Color of Highlighted Container at the middle tone, re-toned when it changes", "red " .. tostring(r.red) .. ", white " .. tostring(r.white))
        check(r.back, "DK43: the highlight color is back as found")
        check(r.accent == true, "DK43: Accent is the accent's Dark value, toned", "accent " .. tostring(key))
        skip("DK43: each theme drawn", "the theme is not changed here; Accent reads the Dark value whatever the theme (ZeD.Desktops.accentGround)")
    end)
    after(200, function() MM.openDesktopPick() end)
    waitFor(function() return K.up("desktopPick") end, 3000, function(met) end)
    after(300, function()
        local w = K.win("desktopPick")
        local maxB, n = 0, 0
        for _, s in ipairs(w._specs or {}) do
            if string.sub(tostring(s.id), 1, 3) == "sw:" then n = n + 1; maxB = math.max(maxB, s.y + s.h) end
        end
        local stripY = w:getHeight() - w:footerHeight() - MM.bandH()
        check(n == 25 and maxB <= stripY + 1, "DK44: every one of the 25 swatches sits above the Desktop window's band",
            n .. " swatches, the last one's foot at " .. K.n(maxB) .. ", the band at " .. K.n(stripY) .. " (" .. K.screen() .. ")")
        note("DK44: the window's height is cut to the tube with no scroll while its groups always draw in full: with Large text or a short tube the last rows would run under the band")
        MM.showView("desktop")
    end)
    after(200, function() MM.openDesktopPick() end)
    waitFor(function() return K.up("desktopPick") end, 3000, function(met)
        local why = K.press(K.win("desktopPick"), "done")
        keep.v45 = { why = why }
    end)
    after(250, function()
        keep.v45.done = MM.view
        MM.openDesktopPick()
    end)
    after(250, function()
        MM.keyRelease(K.ms(), Keyboard.KEY_ESCAPE)
        keep.v45.esc = MM.view
        MM.openDesktopPick()
    end)
    after(250, function()
        MM.keyRelease(K.ms(), Keyboard.KEY_RETURN)
        local v = keep.v45
        check(v.done == "main" and v.esc == "main" and MM.view == "main", "DK45: Done, Escape and Return close the Desktop window onto the main window",
            "Done " .. tostring(v.done) .. (v.why and (" (" .. v.why .. ")") or "") .. ", Escape " .. tostring(v.esc) .. ", Return " .. tostring(MM.view))
        note("DK45: (director, low) the Desktop window always closes onto the main window, even when it was opened from the bare desktop")
        if MM.view ~= "main" then MM.showView("main") end
        K.errCheck("the Trash and the desktops")
    end)
end
-- =========================================================================================================
-- 8: Credits and Terms (DK46 to DK50)
function X.credits()
    after(200, function() K.try("Credits opened", MM.act.credits) end)
    waitFor(function() return K.up("credits") end, 3000, function(met)
        local w = K.win("credits")
        keep.cl = w.lines
        check(met and type(w.lines) == "table" and #w.lines > 3, "DK46: Credits opens with the game's credits", tostring(w.lines and #w.lines) .. " lines")
        MM.showView("main")
    end)
    after(250, function() MM.act.credits() end)
    waitFor(function() return K.up("credits") end, 3000, function(met)
        local w = K.win("credits")
        check(w.lines == keep.cl, "DK46: the credits lines are read once a session (the same list on a second open)")
        note("DK46: a language changed mid-session keeps the old words in Credits until a Lua reload (the language is never changed here)")
        local r = {}
        w:setMode("fast"); r.f = w.mode; w:setMode("fast"); r.f2 = w.mode
        w:setMode("rewind"); r.r = w.mode; w:setMode("rewind"); r.r2 = w.mode
        w:togglePause(); r.p = w.mode; w:togglePause(); r.p2 = w.mode
        local box = w._box
        r.max = (w._total or 0) + math.floor(((box and box.h) or 0) / 2)
        w.roll = r.max - 1
        w:setMode("fast")
        keep.r47 = r
    end)
    after(400, function()
        local w, r = K.win("credits"), keep.r47
        r.endMode, r.endRoll = w.mode, w.roll
        w.roll = 2
        w.mode = "rewind"
    end)
    after(400, function()
        local w, r = K.win("credits"), keep.r47
        r.topMode, r.topRoll = w.mode, w.roll
        local before = w.roll or 0
        MM.wheel(3)
        r.wheel = (w.roll or 0) > before
        w.mode = "play"
        w:joyA()
        r.ja = w.mode
        w:joyA()
        check(r.f == "fast" and r.f2 == "play" and r.r == "rewind" and r.r2 == "play", "DK47: << and >> are toggles: a second press plays again", r.f .. " " .. r.f2 .. " " .. r.r .. " " .. r.r2)
        check(r.p == "pause" and r.p2 == "play", "DK47: Pause and Play")
        check(r.endMode == "pause" and K.near(r.endRoll, r.max), "DK47: the roll stops paused with the last line halfway up", tostring(r.endMode) .. ", roll " .. K.n(r.endRoll) .. " of " .. K.n(r.max))
        check(r.topMode == "play" and r.topRoll == 0, "DK47: a rewind to the top plays again", tostring(r.topMode) .. ", roll " .. tostring(r.topRoll))
        check(r.wheel, "DK47: the wheel anywhere on the desk rolls the credits (MM.wheel)")
        check(r.ja == "pause", "DK47: the pad's A pauses", tostring(r.ja))
        note("DK47: (director) the pad on Credits: A pause or play, X fast, Y rewind, B back; the game's Credits close on A")
        MM.showView("main")
    end)
end
function X.terms()
    after(200, function()
        if not MM.hasView("terms") then keep.noTerms = true; return end
        K.try("Terms opened", MM.act.tos)
    end)
    waitFor(function() return keep.noTerms or K.up("terms") end, 3000, function(met)
        if keep.noTerms or not met then
            skip("DK48: Return on the terms", "no terms view on the desk")
            return
        end
        local w = K.win("terms")
        check(w.focusId == "terms", "DK49: on the desk the terms open with the pad on View terms of service, never on Accept", tostring(w.focusId))
        -- (Return: the window's own accept stood in for on this window only, then taken off again)
        local hits = 0
        local orig = rawget(w, "accept")
        local stub = function() hits = hits + 1 end
        w.accept = stub
        if rawget(w, "accept") == stub and MM.view == "terms" and MM.activeWindow() == w then
            pcall(MM.keyRelease, K.ms(), Keyboard.KEY_RETURN)
        end
        w.accept = orig
        check(hits == 1 and rawget(w, "accept") == orig, "DK48: Return on the terms accepts at once (Accept stood in for; never the game's)", hits .. " accept")
        note("DK48: (director) the terms' Quit quits at once with no question, as the game's does, while every other quit on the desk asks; Return accepts at once and Accept saves options.ini again; neither runs here")
        skip("DK48: the terms' Quit", "never pressed")
        pcall(function() w:wheel(-50); w:wheel(500) end)
        w:leave()
        skip("DK49: the boot terms window takes no keys", "needs a terms change and a relaunch")
        skip("DK50: View terms and View privacy", "they open the Steam overlay or the browser")
    end)
    after(250, function()
        if MM.view ~= "main" then MM.showView("main") end
        K.errCheck("Credits and Terms")
    end)
end

-- =========================================================================================================
-- 9: CletusWorks, Documents and Mail, on the stand-in disk (DK51 to DK57)
function X.notepad()
    after(200, function() D.npReset(); MM.openNotepad() end)
    waitFor(function() return K.up("notepad") end, 3000, function(met)
        if not met then keep.noNp = true; return end
        K.win("notepad").edit:setText("zedqa words A")
    end)
    waitFor(function() local d = N.draft(); return keep.noNp or (d ~= nil and d.text == "zedqa words A") end, 4000, function(met)
        if keep.noNp then skip("DK51: the notepad's draft", "the notepad did not open"); return end
        check(met, "DK51: unsaved words go to the draft on the notepad's own timer", K.q(N.draft() and N.draft().text))
        local np = K.win("notepad")
        np.edit:setText("zedqa words A and B")
        np._draftAt = MM.now()   -- (the timer's last write was just now)
        -- File > Continue as the menu bar runs it, with vanilla's item handler stood in for (no game ever starts)
        local m = K.ms()
        keep.c51 = { has = m and m.latestSaveOption ~= nil, n = 0 }
        if keep.c51.has then
            local orig = MainScreen.onMenuItemMouseDownMainMenu
            local stub = function() keep.c51.n = keep.c51.n + 1 end
            MainScreen.onMenuItemMouseDownMainMenu = stub
            if MainScreen.onMenuItemMouseDownMainMenu == stub then pcall(MM.act.continue) end
            MainScreen.onMenuItemMouseDownMainMenu = orig
            keep.c51.back = MainScreen.onMenuItemMouseDownMainMenu == orig
        end
    end)
    after(700, function()   -- (the switch-off's 0.6 s, the notepad still on the monitor)
        if keep.noNp then return end
        local c = keep.c51
        local d = N.draft()
        if c.has then
            check(c.back == true, "DK51: vanilla's item handler is back as found")
            check(c.n == 1 and MM.view == "notepad", "DK51: File > Continue goes straight to vanilla's item, past MM.showView", c.n .. " call, view " .. tostring(MM.view))
        else
            note("DK51: no Continue save here: the menu bar's start is read from the code (fire runs vanilla's item, never MM.showView)")
        end
        check(d ~= nil and d.text == "zedqa words A and B", "DK51: a game started from the menu bar keeps the last words typed",
            "the draft holds " .. K.q(d and d.text) .. ": the words typed since the timer's last write (up to 1.5 s) are lost when a game starts from the menu bar")
    end)
    after(200, function()
        if keep.noNp then return end
        local np = K.win("notepad")
        D.npReset()
        np:newPage()
        np.edit:setText("zedqa dk52 words")
        np:doNew()
        local r = { c = np.confirm, f = np.focusId }
        np:answer(false)
        r.after, r.text = np.confirm, np.edit:getText()
        np.edit:setText("zedqa dk52 again")
        np:doNew()
        D.failWrite = true
        np:answer(true)
        D.failWrite = false
        r.fc, r.ftext, r.fnote = np.confirm, np.edit:getText(), np.note
        r.saved = np:save() == true and np.doc and np.doc.id ~= nil
        np:setConfirm("delete")
        r.df = np.focusId
        np:setConfirm(false)
        check(r.c == "unsaved", "DK52: New on a page with unsaved words asks Save changes?", tostring(r.c))
        note("DK13: the notepad's questions put the pad on " .. tostring(r.f) .. " (Save changes?) and " .. tostring(r.df) .. " (Delete): Cancel")
        check(r.after == false and r.text == "", "DK52: Discard changes drops the words and runs what was asked (a new page)", K.q(r.text))
        check(r.fc == false and r.ftext == "zedqa dk52 again" and r.fnote == ZeD.tr("UI_ZeD_Desk_WriteFailed"), "DK52: a Save that fails closes the question and does nothing else, saying so",
            tostring(r.fc) .. ", " .. K.q(r.ftext) .. ", " .. K.q(r.fnote))
        check(r.saved, "DK52: Save then works")
    end)
end
function X.notesCaps()
    after(200, function()
        if keep.noNp then return end
        local r = {}
        while not N.full() do if not N.create(N.freshName("zedqa")) then break end end
        r.n = N.count()
        local x, why = N.create("one too many")
        r.over = (x == nil and why == "full")
        local np = K.win("notepad")
        np:newPage(); np.edit:setText("w"); np:save()
        r.note = np.note
        r.clean = N.cleanName("a|b" .. string.char(9) .. "c")
        r.long = #N.cleanName(string.rep("n", 50))
        local list = N.list()
        local okT, errT = N.rename(list[2].id, string.upper(list[1].name))
        r.taken = (okT == nil and errT == "taken")
        local acc = "Caf" .. string.char(233) .. " list"
        N.rename(list[3].id, acc)
        local okC, cjk = pcall(string.char, 26085, 26412, 35486)
        if okC then N.rename(list[5].id, cjk) end
        local id3, id4, id5 = list[3].id, list[4].id, list[5].id
        N.save(id4, string.rep("t", N.TEXT_MAX + 30))
        N.reset()
        r.acc = N.get(id3) and N.get(id3).name == acc
        r.cjk = okC and N.get(id5) and N.get(id5).name == cjk
        r.text = #(N.read(id4) or "")
        check(r.n == 24 and r.over, "DK53: 24 notes at most: the 25th is refused as full", r.n .. " notes")
        check(r.note == ZeD.tr("UI_ZeD_Desk_Full", N.MAX), "DK53: the notepad's Save on a full desk says so in the band", K.q(r.note))
        check(r.text == 20000, "DK53: a note holds at most 20,000 characters", r.text)
        check(r.clean == "abc" and r.long == 32, "DK53: names lose | and control characters and are cut to 32", K.q(r.clean) .. ", " .. r.long)
        check(r.taken, "DK53: names are unique whatever their case")
        check(r.acc and (r.cjk or not okC), "DK53: an accented and a CJK name round trip (on the stand-in disk)", "accented " .. tostring(r.acc) .. ", CJK " .. tostring(r.cjk))
        skip("DK53: the names through the real file's encoding", "a real round trip would leave a file behind; the stand-in disk keeps the Lua string as it is")
    end)
end
function X.docs()
    after(200, function()
        if keep.noNp then return end
        D.npReset()
        keep.id54 = N.list()[1].id
        MM.openNote(keep.id54)
    end)
    after(300, function()
        if keep.noNp then return end
        local np = K.win("notepad")
        keep.r54 = { opened = np.doc and np.doc.id }
        MM.openDocs("notepad")
    end)
    after(300, function()
        if keep.noNp then return end
        local dc = K.win("docs")
        dc.sel = keep.id54
        N.rename(keep.id54, "zedqa renamed")
        dc:close()
    end)
    after(300, function()
        if keep.noNp then return end
        local np, r = K.win("notepad"), keep.r54
        r.name, r.view = np.doc and np.doc.name, MM.view
        MM.openDocs("notepad")
    end)
    after(300, function()
        if keep.noNp then return end
        local dc, r = K.win("docs"), keep.r54
        dc.sel = keep.id54
        dc:setConfirm("delete")
        r.df = dc.focusId
        dc:setConfirm(false)
        N.saveDraft(keep.id54, "zedqa renamed", "draft words")
        dc:delete()
        r.draft = N.draft()
        dc:close()
    end)
    after(300, function()
        if keep.noNp then skip("DK54: Documents and an open note", "the notepad did not open"); return end
        local np, r = K.win("notepad"), keep.r54
        check(r.opened == keep.id54 and r.view == "notepad" and r.name == "zedqa renamed", "DK54: a note renamed in Documents takes its new name in CletusWorks",
            tostring(r.opened) .. ", " .. tostring(r.view) .. ", " .. K.q(r.name))
        check(np.doc ~= nil and np.doc.id == nil, "DK54: a note deleted in Documents is a page not on the desktop in CletusWorks", "doc id " .. tostring(np.doc and np.doc.id))
        check(r.draft == nil, "DK54: Delete in Documents clears that note's draft")
        note("DK13: Documents' Delete puts the pad on " .. tostring(r.df) .. " (Cancel)")
        D.npReset()
        MM.showView("main")
        K.errCheck("CletusWorks and Documents")
    end)
end
function X.mail()
    after(200, function()
        local w = K.win("mail")
        if not w then keep.noMail = true; return end
        MS.reset()
        local r = {}
        w:startCompose("", "", "")
        r.nobox = w:putWhy()
        w:cancelCompose(true)
        local b = MS.box("10.0.0.1:16261", "zedqa", "QA Server")
        MS.receive(b, { id = 7, from = "admin", to = "zedqa", subj = "Hello", text = "Line one\nLine two" })
        MS.save(b)
        keep.b55, keep.r55 = b, r
        MM.openMail()
    end)
    waitFor(function() return keep.noMail or K.up("mail") end, 3000, function(met)
        if keep.noMail or not met then keep.noMail = true; skip("DK55: Mail", "the mail window did not open"); return end
        local w, b, r = K.win("mail"), keep.b55, keep.r55
        local tr, L = ZeD.tr, ZeD.Ml.L
        local m = MS.load(b).inbox[1]
        local w0 = D.writes
        w.folder = "inbox"
        w:pick(m)
        local txt = D.disk[MS.fileOf(b.n)] or ""
        r.read = m.read == true and D.writes > w0 and string.find(txt, "|1|Hello", 1, true) ~= nil
        w:reply()
        r.rto, r.rsubj, r.rtext = w:composeWords()
        local function why(to, subj, text) w.toEntry:setText(to); w.subjEntry:setText(subj); w.textEntry:setText(text); return w:putWhy() end
        local w1 = D.writes
        r.noTo = why("", "s", "t")
        r.subj = why("a", string.rep("s", L.SUBJ_MAX + 1), "t")
        r.subjHeld = #(w.subjEntry:getText() or "")
        r.noText = why("a", "s", "")
        r.long = why("a", "s", string.rep("t", L.TEXT_MAX + 1))
        r.textHeld = #(w.textEntry:getText() or "")
        r.ok = why("a", "s", "t")
        r.memOnly = D.writes == w1
        for i = 1, MS.OUT_MAX do MS.queue(b, "a", "s" .. i, "t") end
        r.full = why("a", "s", "t")
        w:cancelCompose(true)
        w.sel = MS.load(b).inbox[1]
        w:setConfirm("delete")
        r.df = w.focusId
        w:setConfirm(false)
        check(r.nobox == tr("UI_ZeD_Mail_NoBoxes"), "DK55: with no mailbox Put in Outbox greys with its reason", K.q(r.nobox))
        check(r.read, "DK55: reading an Inbox letter writes its mailbox's file at once")
        check(r.rto == "admin" and r.rsubj == "Re: Hello" and string.find(r.rtext or "", "> Line one", 1, true) ~= nil, "DK55: Reply quotes the letter with > under Re:", K.q(r.rsubj) .. ", " .. K.q(r.rtext))
        check(r.noTo == tr("UI_ZeD_Mail_NeedTo"), "DK55: no To greys Put in Outbox with its reason", K.q(r.noTo))
        if r.subjHeld > L.SUBJ_MAX then check(r.subj == tr("UI_ZeD_Mail_SubjLong", L.SUBJ_MAX), "DK55: a subject too long greys it with its reason", K.q(r.subj))
        else note("DK55: the Subject field holds no more than " .. L.SUBJ_MAX .. " characters, so its too-long reason never shows") end
        check(r.noText == tr("UI_ZeD_Mail_NeedText"), "DK55: no words greys it with its reason", K.q(r.noText))
        if r.textHeld > L.TEXT_MAX then check(r.long == tr("UI_ZeD_Mail_TooLong", L.TEXT_MAX), "DK55: a letter too long greys it with its reason", K.q(r.long))
        else note("DK55: the letter's field holds no more than " .. L.TEXT_MAX .. " characters, so its too-long reason never shows") end
        check(r.ok == nil, "DK55: a letter with To, a subject and words can go", K.q(r.ok))
        check(r.full == tr("UI_ZeD_Mail_OutboxFull", MS.OUT_MAX), "DK55: a full Outbox (20) greys it with its reason", K.q(r.full))
        check(r.memOnly, "DK56: a letter being written lives only in memory (nothing written while it is typed)")
        note("DK56: (director) a game start or a Lua reload drops a letter being written; the notepad keeps a draft, Mail does not")
        note("DK13: Mail's Delete puts the pad on " .. tostring(r.df) .. " (Cancel)")
        note("DK57: (director) the desk has two pad keyboards: the notes, Documents and Mail fields open the game's OnScreenKeyboard, the windows built on the saves' typeIn open ZeD's own")
        skip("DK57: B and RT back from the game's keyboard", "the keyboard comes only with a real pad")
        MM.showView("main")
        K.errCheck("Mail")
    end)
end

-- =========================================================================================================
-- 10: the Workshop window and its description editor (DK58 to DK65); nothing is ever uploaded or saved
function X.workshop()
    after(200, function()
        local m = K.ms()
        local wo = m and m.workshopOption ~= nil or false
        local band = K.spec(K.main(), "workshop") ~= nil
        local row = K.row("settings", MM.act.workshop) ~= nil
        local icon = K.icons() and K.icons():find("uploader") ~= nil or false
        local steam = getSteamModeActive and getSteamModeActive() or false
        check(band == wo and row == wo and icon == wo, "DK65: the band's Workshop, Settings' row and the Mod Uploader icon follow vanilla's workshopOption",
            "workshopOption " .. tostring(wo) .. ": band " .. tostring(band) .. ", row " .. tostring(row) .. ", icon " .. tostring(icon))
        note("DK65: Steam is " .. (steam and "on" or "off") .. " here; the Workshop window hears Steam's upload events only when Steam was on as its file loaded")
        if not MM.hasView("workshop") then keep.noWs = true; return end
        local w = K.win("workshop")
        keep.wsState = { picked = w._pickedLast, sel = w.sel }
        MM.showView("workshop")
    end)
    waitFor(function() return keep.noWs or K.up("workshop") end, 3000, function(met)
        if keep.noWs or not met then keep.noWs = true; skip("DK58: the Workshop window", "no Workshop window on this desk"); return end
        local w = K.win("workshop")
        keep.ws = { items = #(w.items or {}) }
        w.unsaved = { zedqa = true }
        w:back()
        keep.ws.c, keep.ws.f = w.confirm, w.focusId
        w:setConfirm(false)
        if keep.ws.items > 0 then
            local why = K.press(w, "f:title")
            keep.ws.title = why or tostring(w.titleE:isFocused())
            pcall(function() w.titleE:unfocus() end)
        end
        -- an upload waiting on Steam (set by hand: nothing is sent), left by the menu bar and come back to
        w.busy = { stage = "send", t0 = MM.now() }
        MM.showView("main")
    end)
    after(250, function() if not keep.noWs then MM.showView("workshop") end end)
    after(300, function()
        if keep.noWs then return end
        local w, r = K.win("workshop"), keep.ws
        r.busy, r.unsaved = w.busy, K.count(w.unsaved)
        w.busy = nil   -- (never left set)
        w.unsaved = {}
        check(r.c == "leave", "DK59: the Workshop's Back with unsaved edits asks first", tostring(r.c))
        note("DK13: the Workshop's leave question puts the pad on " .. tostring(r.f) .. " (Keep editing)")
        check(r.busy ~= nil, "DK58: an upload left and come back to is still waiting for Steam's answer",
            "onShow set busy to nil: Steam's answer would be dropped (onUpdated returns when not busy), the change note kept and Upload lit for a second send")
        check(r.unsaved > 0, "DK59: unsaved Workshop edits survive leaving by the menu bar", "the edits were dropped with no question (onShow rebuilds the form from the folders)")
        if r.title then note("DK60: pad A on the Workshop's Title focuses the field directly (focused: " .. tostring(r.title) .. "); no pad keyboard is asked for") end
        skip("DK60: a pad keyboard on the Workshop's Title, Change note and the editor's cards", "the keyboard comes only with a real pad")
        MM.showView("main")
    end)
    after(200, function()
        if not MM.hasView("wsdesc") then keep.noDe = true; return end
        keep.de = { n = 0 }
        MM.wsEditor = { text = "", title = "zedqa", limit = 10, done = function() keep.de.n = keep.de.n + 1 end }
        MM.showView("wsdesc")
    end)
    waitFor(function() return keep.noDe or K.up("wsdesc") end, 3000, function(met)
        if keep.noDe or not met then keep.noDe = true; return end
        local w = K.win("wsdesc")
        w.blocks[2] = w.blocks[2] or { kind = "text", text = "" }
        w.blocks[2].text = "zedqa description words, more than the room"
    end)
    after(300, function()
        if keep.noDe then skip("DK62: the description editor", "no description editor on this desk"); return end
        local w, r = K.win("wsdesc"), {}
        local use = K.spec(w, "use")
        r.over = use and use.disabled
        w:back()
        r.c, r.f = w.confirm, w.focusId
        w.confirm, w.focusId = false, nil
        MM.showView("main")
        r.done = keep.de.n
        MM.wsEditor = nil
        check(r.over == true, "DK62: over the room, the editor's Use this description greys (its count turns red)", tostring(r.over))
        check(r.c == "leave", "DK59: the description editor asks before its changes go (Cancel)", tostring(r.c))
        note("DK13: the description editor's leave question puts the pad on " .. tostring(r.f) .. " (Keep)")
        check(r.done > 0, "DK59: a description being edited survives leaving by the menu bar", "the menu bar left the editor with no question and nothing was handed back (done ran " .. r.done .. " times)")
        skip("DK61: a folder with no Workshop ID always makes a new item", "needs real Steam")
        skip("DK62: the room against a real submit", "needs real Steam")
        skip("DK63: a preview.png added while the window is open", "needs a picture copied into a Workshop folder (outside Zomboid/Lua)")
        skip("DK64: ZeD_workshop.txt round trip", "its reader and writer are local to the Workshop window and show only through a real Workshop folder's form")
        K.errCheck("the Workshop")
    end)
end

-- =========================================================================================================
-- 11: Lite (DK66), small screens, the corkboard, words, drift (DK67 to DK70)
function X.lite()
    after(200, function() K.style(2) end)
    after(800, function()
        local r = {}
        r.lite = St.lite()
        r.left = #MM.leftItems()
        local zed = MM.menuItems("zed")
        r.noteRow = K.rowBy(zed, function(it) return it.text == ZeD.tr("UI_ZeD_Desk_NotepadTitle") end) ~= nil
        r.about = type(zed[1]) == "table" and zed[1].about == true
        local ic = K.icons()
        r.pz, r.trash = ic:find("pz") ~= nil, ic:find("trash") ~= nil
        r.pick = MM.hasView("desktopPick") and K.rowBy(MM.menuItems("settings"), function(it) return it.text == ZeD.tr("UI_ZeD_MainMenu_Desktop") end) ~= nil
        r.credits = K.row("zed", MM.act.credits) ~= nil
        keep.r66 = r
        K.style(1)
    end)
    after(800, function()
        local r = keep.r66
        check(r.lite and r.left == 0 and not r.noteRow, "DK66: Lite drops the desk's left column and the ZeD menu's notepad rows", "Lite " .. tostring(r.lite) .. ", left " .. r.left .. ", notepad row " .. tostring(r.noteRow))
        check(r.pz and r.trash and r.pick and r.about and r.credits, "DK66: Lite keeps the right icons, the Trash, Desktop..., the About block and Credits",
            tostring(r.pz) .. " " .. tostring(r.trash) .. " " .. tostring(r.pick) .. " " .. tostring(r.about) .. " " .. tostring(r.credits))
        note("DK66: (director) Lite keeps the room, the right icons, the Trash joke, Desktop... and the wallpapers, About and the corkboard note; the notes keep their files")
        check(St.lite() == false and #MM.leftItems() > 0, "DK66: Full again: the left column is back", #MM.leftItems())
    end)
end
function X.misc()
    after(200, function()
        local room = MM.roomLayout()
        local holds = MM.roomHolds(room)
        local lean = MM.leanLayout()
        K.inTube("DK67: the main window", K.main())
        note("DK67: screen " .. K.screen() .. ", desk x" .. tostring(room.s) .. ", the room's tube " .. K.n(room.tw) .. "x" .. K.n(room.th) .. (holds and " holds" or " does not hold")
            .. " the 960 x 720 menu; leaning " .. (lean and "available" or "not needed") .. ", framing " .. tostring(MM._framing))
        skip("DK67: 1280 x 720, 1280 x 800, 1366 x 768 and a Steam Deck", "a sweep never changes the screen size; the small-screen runs do")
        local h = MM.noteHeading
        check(h("1.0.0") == "V1.0" and h("0.3.0-beta21C") == "BETA 21C" and h("0.3.0-beta4") == "BETA 4" and h("dev") == "DEV", "DK68: the corkboard's heading follows the version",
            h("1.0.0") .. ", " .. h("0.3.0-beta21C") .. ", " .. h("0.3.0-beta4"))
        note("DK68: a version past 1.0 with a dash reads DEV (1.0.0-hotfix gives " .. h("1.0.0-hotfix") .. "); this build " .. K.q(MM.zedVersion()) .. " reads " .. h(MM.zedVersion()))
        local cut = {}
        for i = 1, 5 do
            local l = ZeD.MenuNote and ZeD.MenuNote[i]
            if l and #tostring(l) > 10 then cut[#cut + 1] = tostring(l) end
        end
        if #cut > 0 then note("DK68: corkboard lines cut to 10 letters with no sign: " .. table.concat(cut, "; "))
        else check(true, "DK68: every corkboard line fits its 10 letters") end
        local miss = {}
        for _, g in ipairs(DS.GROUPS) do
            for _, id in ipairs(g.ids) do
                for _, k in ipairs({ DS.nameKey(id), DS.noteKey(id) }) do if ZeD.tr(k) == k then miss[#miss + 1] = k end end
            end
        end
        check(#miss == 0, "DK69: every desktop's name and note has its words", K.short(miss))
        note("DK69: (director) hard-coded English on the desk: Project Zomboid (the icon, the window frame), Zero Day OS, 40 MB, the Debug menu's Debug, Reset Lua and Scenarios")
        note("DK70: drift in comments (no behavior): Show note in the ZeD menu (no such row since Pasties), one sticky note always on the desktop, ZeD_desk_sticky.txt named as current; MM.hideExtras hides versionBtn while Safe mode's hand-back does not show it again (the game's render does)")
        K.errCheck("Lite and the rest")
    end)
end

-- =========================================================================================================
-- 12: Safe mode on and off at the desk (DK4), last before the put-back
function X.safe()
    after(200, function()
        if not (Safe and Safe.reread and St.safeModeOption) then keep.noSafe = "no Safe mode option here"; return end
        if Safe.on() then keep.noSafe = "Safe mode is already on"; return end
        MM.showView("credits")
    end)
    after(300, function()
        if keep.noSafe then return end
        keep.s4 = { view = MM.view }
        pcall(function() St.safeModeOption:setValue(2) end)
        pcall(Safe.reread)
        local m = K.ms()
        keep.s4.on = Safe.on()
        keep.s4.gone = MM.root == nil
        pcall(function() keep.s4.bx = m.bottomPanel:getX() end)
    end)
    after(400, function()
        if keep.noSafe then return end
        pcall(function() St.safeModeOption:setValue(1) end)
        pcall(Safe.reread)
        keep.s4.off = not Safe.on()
        keep.s4.back = MM.root ~= nil
        keep.s4.view2 = MM.view
    end)
    after(600, function()
        if keep.noSafe then skip("DK4: Safe mode at the desk", keep.noSafe); return end
        local s = keep.s4
        check(s.on and s.gone and (s.bx or -20000) > -10000, "DK4: Safe mode on at the desk: the desk goes and vanilla's labels come back",
            "on " .. tostring(s.on) .. ", desk gone " .. tostring(s.gone) .. ", labels at x " .. tostring(s.bx))
        check(s.off and s.back and MM.root ~= nil and MM.root:isVisible(), "DK4: Safe mode off again: the same desk returns", "off " .. tostring(s.off) .. ", desk " .. tostring(s.back))
        note("DK4: the monitor came back on the " .. tostring(s.view2) .. " view, the one up before Safe mode (MM.view is left as it was)")
        if MM.root then MM.showView("main") end
        K.errCheck("Safe mode at the desk")
    end)
end

-- =========================================================================================================
-- put back
function X.putFiles()
    for name, was in pairs(keep.files) do
        local now = K.readLines(name)
        if was then
            if not K.same(now, was) then
                K.writeLines(name, was, (name == "ModOptions.ini") and "\r\n" or "\n")
                if K.same(K.readLines(name), was) then keep.rewrote[#keep.rewrote + 1] = name else keep.fileBad[#keep.fileBad + 1] = name end
            end
        elseif now ~= nil then
            if name == "ZeD_wallpaper.txt" then
                note("put back: ZeD_wallpaper.txt was not there before and now holds " .. K.q(now[1]) .. " (the same meaning as no file); delete Zomboid/Lua/ZeD_wallpaper.txt to have it gone")
            elseif string.find(table.concat(now, ""), "%S") then
                keep.fileMade[#keep.fileMade + 1] = name .. " " .. K.q(now[1])
            else
                note("put back: " .. name .. " was not there before and is there now, empty (the same meaning as no file)")
            end
        end
    end
end
function X.putBack()
    after(300, function()
        -- a question or a field a part left open: shut, nothing answered
        pcall(function()
            local r = MM.root
            local fields = { "win" }
            for _, rv in ipairs(MM.views or {}) do fields[#fields + 1] = rv.field end
            for _, f in ipairs(fields) do
                local w = r[f]
                if w and w.confirm and w.setConfirm then pcall(w.setConfirm, w, false) end
            end
        end)
        -- (as bx_menu.lua) a change left waiting in Options (Lite's pick can leave one): Discard, never Apply
        pcall(function()
            local w = MM.root.optsWin
            if w and w.anyChanged and w:anyChanged() then note("put back: Options had a change waiting (never applied): Discard"); w:discard() end
        end)
        pcall(function()
            local w = K.win("workshop")
            if w then
                w.busy = nil; w.unsaved = {}; w.confirm = false
                if keep.wsState then w._pickedLast, w.sel = keep.wsState.picked, keep.wsState.sel end
            end
        end)
        pcall(function() local w = K.win("wsdesc"); if w then w.confirm = false end end)
        MM.wsEditor = nil
        MM.readyChecks.zedqa = nil
        D.failWrite = false
        pcall(function() local ic = K.icons(); ic._carry = nil; ic._drag = nil; ic.focusId = keep.icFocus end)
        MM.ctx.open = nil
        MM.deskAt, MM.deskBack = nil, nil
        MM.forceGamepad = keep.pad0
        pcall(function() local c = K.ms().onlineCoopScreen; if c and c:isVisible() then c:setVisible(false) end end)
        pcall(MM.showView, "main")
        pcall(function() if keep.hs0 ~= nil or K.ms().hasSaveFiles ~= keep.hs0 then K.ms().hasSaveFiles = keep.hs0 end end)
        pcall(function() if keep.hl0 then K.setHL(keep.hl0[1], keep.hl0[2], keep.hl0[3]) end end)
    end)
    after(300, function()
        pcall(D.unswap)
        pcall(D.restoreWindows)
        pcall(function() K.main().focusId = keep.mainFocus end)
        if keep.opt0 then
            pcall(K.setAll, keep.opt0)
            pcall(function() St.applyThemeNow() end)
        end
        pcall(function() if keep.wall0 and MM.desktop() ~= keep.wall0 then MM.setDesktop(keep.wall0) end end)
        pcall(function()
            local ds = DebugScenarios and DebugScenarios.instance
            if ds and keep.ds0 ~= nil and ds:isVisible() ~= keep.ds0 then ds:setVisible(keep.ds0) end
        end)
    end)
    after(1200, function()
        -- (ZeD's own saves are done: the files as found)
        pcall(X.putFiles)
    end)
    after(500, function()
        local d = K.diff(keep.opt0, K.snapAll())
        check(keep.opt0 ~= nil and #d == 0, "put back: every ZeD option as found (" .. K.count(keep.opt0) .. " options)", K.short(d))
        local L = keep.look0 or {}
        check(ZeD.currentBase == L[1] and ZeD.currentAccent == L[2] and ZeD.currentSize == L[3], "put back: the theme, accent and text size on screen as found",
            tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize))
        check(ZeD.Scale.userScale == keep.scale0 and St.lite() == keep.lite0, "put back: the UI scale step and Style as found", tostring(ZeD.Scale.userScale) .. ", Lite " .. tostring(St.lite()))
        check(#keep.fileBad == 0 and #keep.fileMade == 0, "put back: every desk file as found (" .. tostring(keep.nFiles) .. " there at the start)",
            ((#keep.fileBad > 0) and ("not written back: " .. table.concat(keep.fileBad, ", ") .. "; ") or "") .. ((#keep.fileMade > 0) and ("made with words: " .. table.concat(keep.fileMade, ", ")) or ""))
        if #keep.rewrote > 0 then note("put back: written back as found: " .. table.concat(keep.rewrote, ", ")) end
        check(N.io == keep.nio and MS.io == keep.msio, "put back: the notes and the mail read the real files again")
        check(MM.desktop() == keep.wall0, "put back: the desktop as found", tostring(MM.desktop()))
        local hl = K.hl()
        check(keep.hl0 == nil or (hl ~= nil and K.near(hl[1], keep.hl0[1]) and K.near(hl[2], keep.hl0[2]) and K.near(hl[3], keep.hl0[3])), "put back: the game's highlight color as found")
        check(K.ms().hasSaveFiles == keep.hs0, "put back: vanilla's hasSaveFiles as found")
        check(K.activated() == keep.mods0, "put back: the mods in use are the ones found")
        check(K.wouldReset() == nil, "put back: the mod list in memory is the one running (no Lua reload waiting)", K.wouldReset())
        check(MM.view == "main" and K.up("main") and MM.ctx.open == nil and not K.main().confirm and MM.forceGamepad == keep.pad0,
            "put back: the main window is up, no menu open, no question open", "view " .. tostring(MM.view))
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
if not (MM and MM.root and St and N and MS and DS and MM.showView) then
    after(100, function() S.fail = S.fail + 1; say("ERR ZeD's main menu desk is not up (no desk, notes, mail or desktops): nothing was done") end)
else
    X.start()
    X.boot()
    X.card()
    X.loadGrey()
    X.views()
    X.quitQ()
    X.closeBox()
    X.powerPast()
    X.barRows()
    X.pointer()
    X.padBar()
    X.desk()
    X.pastiesMake()
    X.pastiesSave()
    X.pastiesPile()
    X.pastiesOld()
    X.pastiesPad()
    X.trash()
    X.wall()
    X.credits()
    X.terms()
    X.notepad()
    X.notesCaps()
    X.docs()
    X.mail()
    X.workshop()
    X.lite()
    X.misc()
    X.safe()
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
