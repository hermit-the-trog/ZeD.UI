-- ZeDUI/tools/qa/bx_desktop.lua  (Nov 22 2026, QA; tag bx_desk): MAIN MENU ONLY, pushed through the QA bridge.
-- The main menu's Desktop (merge 355fda884; Design's handoff ZeDUI/HANDOFF_design_desktops_20261122.md, section 8;
-- FEATURE_MAP.md, Main menu, the Desktop row). What it proves:
--   menu row     Settings has one Desktop... row and no wallpaper row; its pull-down hit opens the Desktop window
--                (the "desktopPick" view, the menu shut); the window sits on screen with 25 swatches and Done, every
--                swatch's hit zone inside the window and on top at its middle; Done (its hit zone) closes it
--   swatches     each of the 25 pressed through its hit zone (desktopPick:sw:<id>): MM.desktop() is its id at once,
--                Lua/ZeD_wallpaper.txt holds the id, a fresh read of the file gives it back (a restart), the help
--                band reads "Name: note" for it; ZeD.Desktops.idOf reads the old words "original" and "new" as
--                painting and video (stand-in strings only: the real file never holds them)
--   the color    with Classic, the game's objHighlightColor changed: ZeD.Desktops.ground() follows in the same frame
--                (the middle tone of the new color), the patterns, Solid, Fine and Pinstripe draw on it, Accent,
--                Slate, the Fun set and the flags draw exactly as before, Painting and Title video stay the game's;
--                the window's swatches read the new color the next frame; white gives the middle grey; loud picks
--                stay calm (OKLab lightness at the middle, chroma at most 0.09); the Accent desktop follows the accent
--   the themes   Dark, Light, High contrast and the colorblind status colors: every desktop draws as before
--   the pad      locked to the controller (MM.forceGamepad, as bx_menu): the window opens on the desktop in use; the
--                D-pad graph from there reaches every swatch and Done; each one walked to with real MainScreen
--                D-pad presses (never off the window's edge), A sets it, the focus mark is drawn on it and the help
--                line names it; B closes the window; A on Done closes it
--   pictures     one full-screen picture per desktop, Zomboid/Screenshots/bxd_<id>.png, the Desktop window closed,
--                every window closed (the "desktop" view), no menu open, no focus mark, the debug console hidden,
--                the lightning held; each taken once its texture reports ready (the title video after 2.5 s)
-- What it puts back: the desktop found (Lua/ZeD_wallpaper.txt byte for byte, read and written with getFileInput /
-- getFileOutput, and checked), the highlight color, the theme, accent and status colors, the input lock, the focus
-- mark function it watched, the debug console, the lightning, the main window up with no menu open.
-- Files it writes: Lua/ZeD_wallpaper.txt (put back as found; when there was none, it is left holding the desktop id
-- found, "painting", the same meaning as no file: a NOTE says so), Zomboid/Screenshots/bxd_<id>.png (25).
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself), with $env:ZEDQA_NOSTEAM = "1" first:
--   4K fullscreen at UI scale 1.75:
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/zed_only_mods.txt `
--        -Script ZeDUI/tools/qa/bx_desktop.lua -Tag bx_desk -TimeoutSec 480
--   1920x1080 window, UI scale Auto: the same with -Width 1920 -Height 1080
--   (the second run overwrites the first run's bxd_*.png: move them first)
-- Lines: "ZEDQA bx_desk PASS ..." / "FAIL ..." / "SKIP ..." / "NOTE ..." / "ERR ...", then "VERDICT PASS n" or
-- "VERDICT FAIL n", then DONE. grep "ZEDQA bx_desk".
local TAG = "bx_desk"
local MM = ZeD and ZeD.MainMenu
local DT = ZeD and ZeD.Desktops
local St = ZeD and ZeD.Settings
local WALL = "ZeD_wallpaper.txt"
local L_MID = 0.5152451091457795      -- the middle grey's OKLab lightness (ZeD_MainMenuDesktops.lua)
local DIRS = { "up", "down", "left", "right" }
local S = { pass = 0, fail = 0, skips = 0, stages = {}, si = 1, maxMs = 360000, start = getTimestampMs() }
local keep = { shots = {}, shotBad = {} }
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

-- ---- the stages, on the clock (as bx_menu.lua): after(ms, fn) runs fn ms after the stage before it (three frames at
-- least); waitFor(cond, maxMs, fn) runs fn(true) once cond is true, fn(false) after maxMs; mark() is where the put-back
-- starts (out of time: the queue jumps there)
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
function K.n(v)
    if type(v) ~= "number" then return tostring(v) end
    return tostring(math.floor(v * 10000 + 0.5) / 10000)
end
function K.c3(t)
    if not t then return "nil" end
    return K.n(t[1]) .. "," .. K.n(t[2]) .. "," .. K.n(t[3])
end
-- the largest difference of two r, g, b tables (a nil: far apart)
function K.dist(a, b)
    if not (a and b and a[1] and b[1]) then return 1e9 end
    return math.max(math.abs(a[1] - b[1]), math.abs(a[2] - b[2]), math.abs(a[3] - b[3]))
end
function K.ids()
    local t = {}
    for _, g in ipairs((DT and DT.GROUPS) or {}) do for _, id in ipairs(g.ids) do t[#t + 1] = id end end
    return t
end
function K.kind(id) local o = DT.OPT[id]; return o and o.kind end
function K.help(id) return ZeD.tr("UI_ZeD_Desktop_Help", ZeD.tr(DT.nameKey(id)), ZeD.tr(DT.noteKey(id))) end

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
-- a theme option set as Options' Apply leaves it: the value, then the theme worked out again from the options
function K.setTheme(id, v)
    local o = K.opt(id)
    if not o then return false end
    pcall(function() o:setValue(v) end)
    pcall(function() St.applyThemeNow() end)
    return true
end

-- the status colors found on screen (before ZeD's theme ever ran there is none: the option's own word)
function K.statusFound()
    if keep.look0 and keep.look0[4] ~= nil then return keep.look0[4] end
    return (keep.status0 == 2) and "cb" or "standard"
end

-- ---- the game's Color of Highlighted Container (options.ini objHighlightColor; Core keeps it in memory, saved only by
-- the game's Options Apply)
function K.setHL(r, g, b) getCore():setObjectHighlitedColor(ColorInfo.new(r, g, b, 1)) end
function K.hl()
    local ci = getCore():getObjectHighlitedColor()
    if not ci then return nil end
    return { ci:getR(), ci:getG(), ci:getB() }
end

-- ---- OKLab of an r, g, b (0..1): lightness and chroma (the oracle for "a loud pick stays calm")
function K.lin(c)
    if c <= 0.04045 then return c / 12.92 end
    return ((c + 0.055) / 1.055) ^ 2.4
end
function K.lab(r, g, b)
    r, g, b = K.lin(r), K.lin(g), K.lin(b)
    local l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ^ (1 / 3)
    local m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ^ (1 / 3)
    local s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ^ (1 / 3)
    local L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    local A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    local B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return L, math.sqrt(A * A + B * B)
end

-- ---- a desktop drawn into a stand-in panel that writes down every draw: the rect colors, the textures and where
-- (ZeD.Desktops.draw, the tube's own path; a 200 x 150 rect, so a tile or two)
function K.rec(id)
    local log, first = {}, nil
    local p = {}
    p.drawRect = function(_, x, y, w, h, a, r, g, b)
        if not first then first = { r, g, b } end
        log[#log + 1] = "R" .. K.n(a) .. "," .. K.n(r) .. "," .. K.n(g) .. "," .. K.n(b)
    end
    p.drawTextureScaled = function(_, t, x, y, w, h)
        -- (the texture by its name: its tostring can carry its size, which changes once it has loaded)
        local nm = nil
        pcall(function() nm = t:getName() end)
        log[#log + 1] = "T" .. tostring(nm or t) .. "@" .. K.n(x) .. "," .. K.n(y) .. "," .. K.n(w) .. "," .. K.n(h)
    end
    p.setStencilRect = function() end
    p.clearStencilRect = function() end
    local ok, drew = pcall(DT.draw, p, id, 0, 0, 200, 150)
    return { ok = ok, drew = (ok and drew) and true or false, err = (not ok) and tostring(drew) or nil,
             s = table.concat(log, ";"), first = first }
end
function K.recAll()
    local t = {}
    for _, id in ipairs(K.ids()) do t[id] = K.rec(id) end
    return t
end
-- the desktops that draw differently in b than in a
function K.recDiff(a, b)
    local bad = {}
    for _, id in ipairs(K.ids()) do
        local x, y = a and a[id], b and b[id]
        if not (x and y) then bad[#bad + 1] = id .. ": not drawn"
        elseif not (x.ok and y.ok) then bad[#bad + 1] = id .. ": " .. tostring(x.err or y.err)
        elseif x.drew ~= y.drew or x.s ~= y.s then bad[#bad + 1] = id end
    end
    return bad
end

-- ---- the file, byte for byte. getFileInput / getFileOutput read and write Zomboid/Lua/<name> as raw bytes (the
-- game's own LuaManager globals; endFileInput / endFileOutput close them). getFileInput is only asked for a file that is
-- there (for one that is not, the game hands back a stream over nothing).
function K.exists(name)
    local r = nil
    pcall(function() r = getFileReader(name, false) end)
    if r then pcall(function() r:close() end); return true end
    return false
end
function K.readBytes(name)
    if not K.exists(name) then return nil, "not there" end
    local t, why = nil, nil
    local ok, e = pcall(function()
        local inp = getFileInput(name)
        if not inp then why = "getFileInput gave nothing"; return end
        local bytes = {}
        for _ = 1, 65536 do
            local b = inp:read()
            if b == nil or b < 0 then break end
            bytes[#bytes + 1] = b
        end
        t = bytes
    end)
    pcall(function() endFileInput() end)
    if not ok then return nil, tostring(e) end
    return t, why
end
function K.writeBytes(name, bytes)
    local ok, e = pcall(function()
        local out = getFileOutput(name)
        if not out then error("getFileOutput gave nothing") end
        for i = 1, #bytes do out:writeByte(bytes[i]) end
    end)
    pcall(function() endFileOutput() end)
    return ok, e
end
function K.sameBytes(a, b)
    if a == nil or b == nil then return a == b end
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end
-- the bytes' first line as text (nil when there are none; false when a byte is not ASCII: nothing to compare)
function K.firstLine(bytes)
    if not bytes or #bytes == 0 then return nil end
    local cs = {}
    for i = 1, #bytes do
        local b = bytes[i]
        if b > 127 then return false end
        if b == 10 or b == 13 then break end
        cs[#cs + 1] = string.char(b)
    end
    return table.concat(cs)
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
function K.writeLines(name, lines)
    if not lines then return end
    pcall(function()
        local w = getFileWriter(name, true, false)
        for _, l in ipairs(lines) do w:write(l .. "\n") end
        w:close()
    end)
end

-- ---- the desk's windows and hit zones
function K.win(view)
    local r = MM.root
    if not r then return nil end
    if view == "main" then return r.win end
    if view == "desktop" then return r.icons end
    for _, rv in ipairs(MM.views or {}) do if rv.view == view then return r[rv.field] end end
    return nil
end
function K.up(view)
    local w = K.win(view)
    return MM.view == view and w ~= nil and w:isVisible() and true or false
end
function K.pick() return K.win("desktopPick") end
-- (Nov 22 2026, the first in-game run: the desk shows and hides its windows in ZeD_MMDesk:update(), which the engine
-- runs every 100 ms, so MM.view changes at once and the windows follow up to 100 ms later. A wait ends on the
-- windows, never on MM.view alone.)
function K.closed()
    local pw = K.pick()
    return MM.view == "main" and K.up("main") and not (pw and pw:isVisible()) and true or false
end
-- one line on where the desk stands, after a failed check: the view, both windows, the views table's field
function K.diag(label)
    local r = MM.root
    local mw, pw = r and r.win, K.pick()
    local field = nil
    for _, rv in ipairs(MM.views or {}) do if rv.view == "desktopPick" then field = rv.field end end
    local act = nil
    pcall(function() act = MM.activeWindow() end)
    say("DIAG " .. label .. ": MM.view " .. tostring(MM.view) .. ", main window visible " .. tostring(mw and mw:isVisible())
        .. ", Desktop window visible " .. tostring(pw and pw:isVisible()) .. ", MM.views desktopPick -> field " .. tostring(field)
        .. " (MM.root." .. tostring(field) .. " " .. ((pw ~= nil) and "set" or "nil") .. "), keys go to the Desktop window " .. tostring(pw ~= nil and act == pw))
end
function K.spec(w, id)
    for _, s in ipairs((w and w._specs) or {}) do if s.id == id then return s end end
    return nil
end
function K.hit(w, id)
    for _, h in ipairs((w and w._hits) or {}) do if h.id == id then return h end end
    return nil
end
-- the hit the pointer would find at x, y in this window (the desk's hitAt: the last one made wins)
function K.topAt(w, x, y)
    local hs = (w and w._hits) or {}
    for i = #hs, 1, -1 do
        local h = hs[i]
        if x >= h.x and x < h.x + h.w and y >= h.y and y < h.y + h.h then return h end
    end
    return nil
end
function K.dropHit(key, i)
    local drop = MM.root and MM.root.drop
    local id = "drop:" .. key .. ":" .. i
    for _, h in ipairs((drop and drop._hits) or {}) do if h.id == id then return h end end
    return nil
end

-- ---- the lightning (hfr_disk.lua): held off for the pictures; let go at the end
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

-- ---- the debug console (-debug shows it on the menu): hidden for the pictures, shown again after
function K.hideConsole()
    keep.cons = keep.cons or {}
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e and e:isVisible() and e:getClass():getSimpleName() == "UIDebugConsole" then
                keep.cons[#keep.cons + 1] = e
                e:setVisible(false)
            end
        end
    end)
end
-- shown again; returns how many were hidden and how many are not showing now
function K.showConsole()
    local n, bad = 0, 0
    for _, e in ipairs(keep.cons or {}) do
        n = n + 1
        local vis = false
        pcall(function() e:setVisible(true); vis = e:isVisible() and true or false end)
        if not vis then bad = bad + 1 end
    end
    keep.cons = {}
    return n, bad
end

-- ---- the controller: MainScreen's own handlers, as a real pad press arrives (Overrides/MainMenu.lua)
function K.dpad(d)
    local m = K.ms()
    if not m then error("no MainScreen") end
    if d == "up" then m:onJoypadDirUp(nil)
    elseif d == "down" then m:onJoypadDirDown(nil)
    elseif d == "left" then m:onJoypadDirLeft(nil)
    else m:onJoypadDirRight(nil) end
end
function K.button(b)
    local m = K.ms()
    if not m then error("no MainScreen") end
    m:onJoypadDown(b, nil)
end
-- the D-pad's moves in the window, worked out with the window's own joyDir (which control each press lands on,
-- from each control); the focus is put back after
function K.graph(w)
    local adj, nodes = {}, {}
    local saved = w.focusId
    for _, s in ipairs(w._specs or {}) do if not s.disabled then nodes[#nodes + 1] = s.id end end
    for _, id in ipairs(nodes) do
        adj[id] = {}
        for _, d in ipairs(DIRS) do
            w.focusId = id; w._edge = nil
            local ok = pcall(w.joyDir, w, d)
            if ok and w.focusId ~= id then adj[id][d] = w.focusId end
        end
    end
    w.focusId = saved; w._edge = nil
    keep.adj = adj
    return #nodes
end
-- every control the D-pad reaches from one
function K.reach(from)
    local adj = keep.adj or {}
    local seen, q, qi = {}, { from }, 1
    seen[from] = true
    while qi <= #q do
        local cur = q[qi]; qi = qi + 1
        for _, d in ipairs(DIRS) do
            local nb = adj[cur] and adj[cur][d]
            if nb and not seen[nb] then seen[nb] = true; q[#q + 1] = nb end
        end
    end
    return seen
end
-- the shortest run of presses from one control to another (nil: none)
function K.path(from, to)
    if from == to then return {} end
    local adj = keep.adj or {}
    local prev, seen, q, qi = {}, {}, { from }, 1
    seen[from] = true
    while qi <= #q do
        local cur = q[qi]; qi = qi + 1
        for _, d in ipairs(DIRS) do
            local nb = adj[cur] and adj[cur][d]
            if nb and not seen[nb] then
                seen[nb] = true
                prev[nb] = { cur, d }
                if nb == to then
                    local path, n = {}, to
                    while n ~= from do
                        local pr = prev[n]
                        table.insert(path, 1, pr[2])
                        n = pr[1]
                    end
                    return path
                end
                q[#q + 1] = nb
            end
        end
    end
    return nil
end
-- the focus mark watched: ZeD.Focus.mark wrapped while the pad part runs, writing down the last mark the Desktop
-- window asked for (where, whether it shows, the focus at the time); the wrapped function does all it did
function K.spyOn()
    local F = ZeD.Focus
    if not (F and F.mark) or keep.spy then return end
    local orig = F.mark
    keep.markOrig = orig
    keep.spy = function(panel, x, y, w, h, opts, rounded)
        local pw = K.pick()
        local o = (type(opts) == "table") and opts or nil
        if pw and (panel == pw or (o and o.win == pw)) then
            local shows = false
            pcall(function() shows = F.isShowing((o and o.win) or pw, o) and true or false end)
            keep.markRec = { x = x, y = y, w = w, h = h, shows = shows, fid = pw.focusId, t = getTimestampMs() }
        end
        return orig(panel, x, y, w, h, opts, rounded)
    end
    F.mark = keep.spy
end
function K.spyOff()
    local F = ZeD.Focus
    if F and keep.spy and F.mark == keep.spy then F.mark = keep.markOrig end
    keep.spy = nil
end

-- ---- a desktop's texture asked for early, and whether it is ready to draw (no texture: ready)
function K.texReady(id)
    local o = DT.OPT[id]
    if not (o and o.tex) then return true end
    local ready = true
    pcall(function()
        local t = Texture.getSharedTexture(DT.DIR .. o.tex, 3)
        if not t then ready = false; return end
        ready = t:isReady() and true or false
    end)
    return ready
end

-- =========================================================================================================
-- 1: as found, the parts, the old words
function X.start()
    after(100, function()
        keep.errs = K.errs()
        keep.errs0 = keep.errs
        keep.desk0 = MM.desktop()
        keep.absent0 = not K.exists(WALL)
        keep.lines0 = K.readLines(WALL)
        local b, why = K.readBytes(WALL)
        keep.bytes0 = b
        local fl = b and K.firstLine(b)
        -- (the byte read and the game's line read agree on the first line: getFileInput reads the same file)
        keep.bytesOk = b ~= nil and (fl == false or fl == ((keep.lines0 and keep.lines0[1]) or nil))
        keep.hl0 = K.hl()
        keep.base0, keep.status0, keep.accent0 = K.val("baseTheme"), K.val("statusColors"), K.val("accentColor")
        keep.look0 = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize, ZeD.currentStatus }
        keep.pad0 = MM.forceGamepad
        keep.mark0 = ZeD.Focus and ZeD.Focus.mark
        say("as found: desktop " .. tostring(keep.desk0) .. ", " .. WALL .. " " .. (keep.absent0 and "absent" or ((b and (#b .. " bytes")) or ("unread: " .. tostring(why))))
            .. ", highlight " .. K.c3(keep.hl0) .. ", look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentStatus)
            .. ", pad lock " .. tostring(keep.pad0) .. ", view " .. tostring(MM.view) .. ", screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
            .. ", UI scale " .. tostring(ZeD.T and ZeD.T.scale) .. ", dot zoom " .. tostring(DT.zoom and DT.zoom()) .. ", video effects " .. tostring(getCore():getOptionDoVideoEffects()))
        if keep.absent0 then note(WALL .. " was not there at the start: the put-back can only leave it holding \"" .. tostring(keep.desk0) .. "\" (the same as no file)")
        else check(keep.bytesOk, "the file: its bytes read and agree with the game's line read", "first line " .. tostring(keep.lines0 and keep.lines0[1]) .. ", " .. tostring(why or "")) end
        check(keep.hl0 ~= nil and keep.base0 ~= nil, "the highlight color and the theme option read as found")
        local ids, noOpt = K.ids(), {}
        for _, id in ipairs(ids) do if not DT.OPT[id] then noOpt[#noOpt + 1] = id end end
        check(#ids == 25 and #noOpt == 0, "ZeD.Desktops: 25 desktops in four groups, each with its option", #ids .. " ids; no option: " .. table.concat(noOpt, " "))
        X.oldWords(ids)
        for _, id in ipairs(ids) do K.texReady(id) end   -- (every desktop's texture asked for now: a first ask draws nothing for a frame)
    end)
    waitFor(function()
        local m = K.ms()
        return m ~= nil and not MM.waking and not MM.poweringOn() and (m.delay or 0) <= 0 and MM.root:isVisible()
    end, 30000, function(met)
        check(met, "the desk is awake (powered on, the fade-in over)", "waking " .. tostring(MM.waking))
        MM.ctx.open = nil
        if MM.view ~= "main" then MM.showView("main") end
    end)
end
-- ZeD.Desktops.idOf: the old words (stand-in strings, never written to the file), nothing, garbage, every id
function X.oldWords(ids)
    check(DT.idOf("original") == "painting" and DT.idOf("new") == "video", "the old words: \"original\" reads as painting, \"new\" as video",
        tostring(DT.idOf("original")) .. ", " .. tostring(DT.idOf("new")))
    check(DT.idOf(nil) == "painting" and DT.idOf("") == "painting" and DT.idOf("wallpaper") == "painting", "no file, an empty line or a word it does not know: the painting")
    local bad = {}
    for _, id in ipairs(ids) do if DT.idOf(id) ~= id then bad[#bad + 1] = id end end
    check(#bad == 0, "every desktop's id reads back as itself", table.concat(bad, " "))
end

-- 2: Settings' row, the window, Done
function X.menuRow()
    after(200, function()
        local items = MM.menuItems("settings") or {}
        local want = ZeD.tr("UI_ZeD_MainMenu_Desktop")
        local n, idx, olds, texts = 0, nil, {}, {}
        for i, it in ipairs(items) do
            if type(it) == "table" and it.text then
                local tx = tostring(it.text)
                texts[#texts + 1] = tx
                if tx == want then n = n + 1; if not idx then idx = i end end
                if string.find(string.lower(tx), "wallpaper", 1, true) or it.check ~= nil then olds[#olds + 1] = tx end
            end
        end
        check(n == 1, "Settings menu: one " .. want .. " row", table.concat(texts, " | "))
        check(#olds == 0, "Settings menu: no wallpaper rows left", table.concat(olds, " | "))
        keep.rowIdx = idx
        if idx then check(not items[idx].disabled, "Settings menu: " .. want .. " is live") end
        MM.ctx.open = "settings"; MM.ctx.dropFocus = 1
    end)
    after(300, function()
        local hit = keep.rowIdx and K.dropHit("settings", keep.rowIdx)
        if not check(hit ~= nil and hit.fn ~= nil, "Settings menu: the row has its pull-down hit zone", "row " .. tostring(keep.rowIdx)) then
            MM.ctx.open = nil
            return
        end
        K.try("Settings menu: Desktop... pressed through its hit zone", hit.fn)
    end)
    waitFor(function() return K.up("desktopPick") end, 3000, function(met)
        check(met and MM.ctx.open == nil, "Desktop...: opens the Desktop window, the menu shut", "view " .. tostring(MM.view) .. ", menu " .. tostring(MM.ctx.open))
        if not met then MM.ctx.open = nil; pcall(MM.openDesktopPick) end
    end)
    after(300, function() K.try("the window looked at", X.windowLook) end)
    after(150, function()
        local w = K.pick()
        local h = K.hit(w, "desktopPick:done")
        if not check(h ~= nil and h.fn ~= nil, "Done: its hit zone is in the band") then pcall(MM.showView, "main"); return end
        K.try("Done pressed through its hit zone", h.fn)
    end)
    waitFor(K.closed, 3000, function(met)
        if not check(met, "Done closes the Desktop window (the main window back)", "view " .. tostring(MM.view)) then K.diag("Done") end
    end)
    after(100, function() K.errCheck("the menu row and Done") end)
end
function X.windowLook()
    local w = K.pick()
    if not (w and K.up("desktopPick")) then check(false, "the Desktop window is up to look at"); return end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local ax, ay, ww, wh = w:getAbsoluteX(), w:getAbsoluteY(), w:getWidth(), w:getHeight()
    local g = math.floor(ax) .. "," .. math.floor(ay) .. " " .. math.floor(ww) .. "x" .. math.floor(wh) .. " on " .. sw .. "x" .. sh
    check(ww > 0 and wh > 0 and ax >= -1 and ay >= -1 and ax + ww <= sw + 1 and ay + wh <= sh + 1, "the Desktop window sits on screen", g)
    check(w.title == ZeD.tr("UI_ZeD_Desktop_Title"), "the Desktop window: its title", tostring(w.title))
    check(w.focusId == "sw:" .. MM.desktop(), "the Desktop window: its focus starts on the desktop in use", tostring(w.focusId))
    local missing, outside, covered, nSw = {}, {}, {}, 0
    for _, s in ipairs(w._specs or {}) do if string.sub(s.id, 1, 3) == "sw:" then nSw = nSw + 1 end end
    for _, id in ipairs(K.ids()) do
        local h = K.hit(w, "desktopPick:sw:" .. id)
        if not (K.spec(w, "sw:" .. id) and h) then missing[#missing + 1] = id
        else
            if h.x < ax - 1 or h.y < ay - 1 or h.x + h.w > ax + ww + 1 or h.y + h.h > ay + wh + 1 then outside[#outside + 1] = id end
            local top = K.topAt(w, h.x + h.w / 2, h.y + h.h / 2)
            if top ~= h then covered[#covered + 1] = id .. " (" .. tostring(top and top.id) .. ")" end
        end
    end
    check(nSw == 25 and #missing == 0 and K.spec(w, "done") ~= nil, "the Desktop window: 25 swatches and Done", nSw .. " swatches; missing " .. table.concat(missing, " "))
    check(#outside == 0, "every swatch's hit zone lies inside the window", K.short(outside))
    check(#covered == 0, "every swatch's hit zone is the one the pointer finds at its middle", K.short(covered))
    -- (where it is: for a look at the pictures, the tube's place)
    local ok, L = pcall(MM.layout)
    if ok and L then say("tube " .. math.floor(L.tx) .. "," .. math.floor(L.ty) .. " " .. math.floor(L.tw) .. "x" .. math.floor(L.th) .. "; window " .. g) end
end

-- 3: each swatch through its hit zone
function X.sweep()
    after(150, function()
        MM.ctx.open = nil
        if not K.up("desktopPick") then K.try("the Desktop window opened again", MM.openDesktopPick) end
    end)
    waitFor(function() return K.up("desktopPick") end, 3000, function(met)
        if not check(met, "the Desktop window opens again after Done", "view " .. tostring(MM.view)) then K.diag("the window again") end
    end)
    each("each of the 25 swatches through its hit zone: the desktop at once, the file holds it, a fresh read gives it, the help band reads its note",
        150, 30000, K.ids, X.swStep, X.swLook,
        function(st)
            if #st.bad > 0 then K.diag("the swatches") end
            if st.ptr then note("the pointer rested on swatch " .. tostring(st.ptr) .. " for some steps (its note showed there; the pad part checks the line again)") end
            K.errCheck("the swatches")
        end)
end
function X.swStep(id, i, st)
    local w = K.pick()
    if not (w and K.up("desktopPick")) then st.bad[#st.bad + 1] = id .. ": the window is not up"; return end
    local h = K.hit(w, "desktopPick:sw:" .. id)
    if not (h and h.fn) then st.bad[#st.bad + 1] = id .. ": no hit zone"; return end
    h.fn()
    local now = MM.desktop()
    if now ~= id then st.bad[#st.bad + 1] = id .. ": MM.desktop() is " .. tostring(now) .. " right after" end
    local l = K.readLines(WALL)
    if not (l and l[1] == id) then st.bad[#st.bad + 1] = id .. ": the file holds " .. tostring(l and l[1]) end
    MM._wall = nil   -- (a restart: the choice read from the file again)
    local fresh = MM.desktop()
    if fresh ~= id then st.bad[#st.bad + 1] = id .. ": a fresh read gives " .. tostring(fresh) end
end
function X.swLook(id, i, st)
    local w = K.pick()
    if not w then st.bad[#st.bad + 1] = id .. ": no window"; return end
    if ZeD.tr(DT.nameKey(id)) == DT.nameKey(id) then st.bad[#st.bad + 1] = id .. ": no name text" end
    if ZeD.tr(DT.noteKey(id)) == DT.noteKey(id) then st.bad[#st.bad + 1] = id .. ": no note text" end
    local line = w:getStatusLine()
    if line ~= K.help(id) then
        -- (the real pointer resting on another swatch names that one instead: the window's rule, not a fault)
        if w._helpId and w._helpId ~= id then st.ptr = w._helpId
        else st.bad[#st.bad + 1] = id .. ": the help band reads \"" .. tostring(line) .. "\"" end
    end
end

-- 4: the color
function X.color()
    after(200, function()
        local w = K.pick()
        local h = K.hit(w, "desktopPick:sw:classic")
        if h and h.fn then h.fn() else MM.setDesktop("classic") end
        keep.recs0 = K.recAll()
        keep.g0 = { DT.ground() }
        -- a color far from the one found
        local pick = { 0.1, 0.4, 0.9 }
        if K.dist({ DT.tone(pick[1], pick[2], pick[3]) }, keep.g0) < 0.05 then pick = { 0.9, 0.3, 0.1 } end
        K.setHL(pick[1], pick[2], pick[3])
        local g1 = { DT.ground() }        -- the same frame: no frame between the change and this read
        local c = K.hl()
        local want = c and { DT.tone(c[1], c[2], c[3]) }
        keep.g1 = g1
        check(MM.desktop() == "classic" and K.dist(g1, keep.g0) > 0.02 and K.dist(g1, want) < 0.0001,
            "the color: with Classic, ZeD.Desktops.ground() follows a new highlight color in the same frame",
            "was " .. K.c3(keep.g0) .. ", now " .. K.c3(g1) .. ", the new color's middle tone " .. K.c3(want))
        X.colorRecs(keep.recs0, K.recAll(), g1)
        -- a third color, and no read of it here: only a drawn frame (the tube's Classic, the window's swatches) can
        -- bring ZeD.Desktops.lastGround() to it
        local c3 = (pick[1] < 0.5) and { 0.9, 0.3, 0.1 } or { 0.1, 0.4, 0.9 }
        K.setHL(c3[1], c3[2], c3[3])
        local h3 = K.hl()
        keep.g3 = h3 and { DT.tone(h3[1], h3[2], h3[3]) }
    end)
    after(200, function()
        local r, g, b = DT.lastGround()
        check(r ~= nil and K.dist({ r, g, b }, keep.g3) < 0.0001 and K.dist(keep.g3, keep.g1) > 0.02,
            "the color: by the next frame the tube and the window's swatches draw on another new color, read by the frame itself",
            "last read " .. K.c3({ r, g, b }) .. ", the color's middle tone " .. K.c3(keep.g3))
        X.colorCalm()
        if keep.hl0 then K.setHL(keep.hl0[1], keep.hl0[2], keep.hl0[3]) end
        local back, now = { DT.ground() }, K.hl()
        check(K.dist(now, keep.hl0) == 0 and K.dist(back, keep.g0) < 0.0001, "the color: the highlight color found is back, and the ground with it", K.c3(now))
    end)
    after(150, function() K.errCheck("the color") end)
end
-- which desktops moved with the color and which stayed (recs0 before the change, recs1 after, g1 the new ground)
function X.colorRecs(recs0, recs1, g1)
    local moved, stayed, badM, badS = 0, 0, {}, {}
    for _, id in ipairs(K.ids()) do
        local a, b, k = recs0[id], recs1[id], K.kind(id)
        if not (a and b and a.ok and b.ok) then badS[#badS + 1] = id .. ": " .. tostring((a and a.err) or (b and b.err) or "not drawn")
        elseif k == "pattern" or k == "flat" then
            if b.drew and b.first and K.dist(b.first, g1) < 0.0001 and a.s ~= b.s then moved = moved + 1
            else badM[#badM + 1] = id .. " (" .. K.c3(b.first) .. ")" end
        elseif k == "game" then
            if not a.drew and not b.drew then stayed = stayed + 1 else badS[#badS + 1] = id .. ": drawn by ZeD.Desktops" end
        else
            if a.drew and a.s == b.s then stayed = stayed + 1 else badS[#badS + 1] = id end
        end
    end
    -- (13 follow: 10 patterns, Fine and Pinstripe are "pattern", Solid "flat"; 12 stay: Accent, Slate, 6 art, 2 flags, 2 game)
    check(#badM == 0 and moved == 13, "the color: the 10 patterns, Solid, Fine and Pinstripe draw on the new color (" .. moved .. ")", K.short(badM))
    check(#badS == 0 and stayed == 12, "the color: Accent, Slate, the Fun set and the flags draw as before; Painting and Title video stay the game's (" .. stayed .. ")", K.short(badS))
end
-- white gives the middle grey; loud picks stay calm
function X.colorCalm()
    K.setHL(1, 1, 1)
    local r, g, b = DT.ground()
    local L = K.lab(r, g, b)
    check(math.abs(r - g) < 0.002 and math.abs(g - b) < 0.002 and math.abs(L - L_MID) < 0.002, "the color: white gives the middle grey",
        K.c3({ r, g, b }) .. ", lightness " .. K.n(L))
    local bad = {}
    for _, c in ipairs({ { 1, 0, 1 }, { 0, 1, 0 }, { 1, 0, 0 }, { 0, 1, 1 }, { 1, 1, 0 }, { 0, 0, 1 } }) do
        K.setHL(c[1], c[2], c[3])
        local r2, g2, b2 = DT.ground()
        local L2, C2 = K.lab(r2, g2, b2)
        if math.abs(L2 - L_MID) > 0.002 or C2 > 0.0905 then bad[#bad + 1] = K.c3(c) .. " -> L " .. K.n(L2) .. " C " .. K.n(C2) end
    end
    check(#bad == 0, "the color: loud picks stay calm (the middle lightness, chroma at most 0.09)", K.short(bad))
end

-- 5: the themes and the accent
local THEMES = { { "baseTheme", 1, "dark", "Dark" }, { "baseTheme", 2, "light", "Light" }, { "baseTheme", 3, "hicon", "High contrast" },
                 { "statusColors", 2, "cb", "the colorblind status colors" } }
function X.themes()
    after(200, function()
        keep.recsT = K.recAll()
        keep.gT = { DT.ground() }
    end)
    for _, t in ipairs(THEMES) do X.themeOne(t) end
    after(250, function()
        K.setTheme("statusColors", keep.status0)
        K.setTheme("baseTheme", keep.base0)
        check(ZeD.currentBase == keep.look0[1] and ZeD.currentStatus == K.statusFound(), "the themes: the one found is back", tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentStatus))
    end)
    after(250, function()
        local o = K.opt("accentColor")
        keep.aDid = nil
        if not (o and keep.accent0) then skip("Accent follows the accent", "no accent option"); return end
        keep.aRec0, keep.aG0 = K.rec("accent"), { DT.ground() }
        K.setTheme("accentColor", (keep.accent0 == 1) and 2 or 1)
        keep.aDid = true
    end)
    after(250, function()
        if not keep.aDid then return end
        local r1 = K.rec("accent")
        check(ZeD.currentAccent ~= keep.look0[2] and r1.ok and r1.s ~= keep.aRec0.s, "Accent: the Accent desktop follows the accent color",
            tostring(keep.look0[2]) .. " -> " .. tostring(ZeD.currentAccent) .. ": " .. K.c3(keep.aRec0.first) .. " -> " .. K.c3(r1.first))
        check(K.dist({ DT.ground() }, keep.aG0) < 1e-6, "Accent: the patterns' ground does not follow the accent")
        K.setTheme("accentColor", keep.accent0)
        check(ZeD.currentAccent == keep.look0[2], "Accent: the accent found is back", tostring(ZeD.currentAccent))
        K.errCheck("the themes")
    end)
end
function X.themeOne(t)
    after(250, function()
        keep.tSkip = nil
        if not K.setTheme(t[1], t[2]) then keep.tSkip = true; skip("theme " .. t[4], "no " .. t[1] .. " option") end
    end)
    after(250, function()
        if keep.tSkip then return end
        local got = (t[1] == "baseTheme") and ZeD.currentBase or ZeD.currentStatus
        if not check(got == t[3], "theme " .. t[4] .. ": on screen", tostring(got)) then return end
        local diff = K.recDiff(keep.recsT, K.recAll())
        check(#diff == 0 and K.dist({ DT.ground() }, keep.gT) < 1e-6, "theme " .. t[4] .. ": every desktop draws as before (25), the ground unchanged", K.short(diff))
    end)
end

-- 6: the controller
function X.pad()
    after(150, function()
        MM.ctx.open = nil
        MM.showView("main")
        MM.forceGamepad = true
        MM.deskAt, MM.deskBack = nil, nil
        K.spyOn()
        check(keep.spy ~= nil, "pad: the focus mark is watched (ZeD.Focus.mark)")
    end)
    after(200, function() K.try("pad: the Desktop window opened", MM.openDesktopPick) end)
    after(300, function()
        local w = K.pick()
        if not check(w ~= nil and K.up("desktopPick") and w.focusId == "sw:" .. MM.desktop(), "pad: the window opens with the focus on the desktop in use",
            "focus " .. tostring(w and w.focusId) .. ", desktop " .. tostring(MM.desktop())) then return end
        local n = K.graph(w)
        local seen, missing = K.reach(w.focusId), {}
        for _, t in ipairs(X.padTargets()) do if not seen[t] then missing[#missing + 1] = t end end
        check(n >= 26 and #missing == 0, "pad: the D-pad reaches every swatch and Done from there (" .. n .. " stops)", K.short(missing))
    end)
    each("pad: the D-pad walked to each swatch and Done with real presses, never off the window; A sets the desktop; the focus mark drawn there; the help line names it",
        200, 40000, X.padTargets, X.padStep, X.padLook, function() K.errCheck("the pad walk") end)
    after(150, function() K.try("pad: B", function() K.button(Joypad.BButton) end) end)
    waitFor(K.closed, 3000, function(met)
        if not check(met, "pad: B closes the Desktop window", "view " .. tostring(MM.view)) then K.diag("pad B") end
    end)
    after(200, function() K.try("pad: the Desktop window opened again", MM.openDesktopPick) end)
    waitFor(function() return K.up("desktopPick") end, 3000, function(met)
        if not check(met, "pad: the Desktop window opens again after B", "view " .. tostring(MM.view)) then K.diag("pad reopen") end
    end)
    after(150, function()
        local w = K.pick()
        local path = w and K.path(w.focusId, "done")
        if not check(path ~= nil, "pad: a way to Done", tostring(w and w.focusId)) then return end
        K.try("pad: the D-pad to Done, then A", function()
            for _, d in ipairs(path) do K.dpad(d) end
            if w.focusId ~= "done" then error("the focus is on " .. tostring(w.focusId)) end
            K.button(Joypad.AButton)
        end)
    end)
    waitFor(K.closed, 3000, function(met)
        if not check(met, "pad: A on Done closes the Desktop window", "view " .. tostring(MM.view)) then K.diag("pad A on Done") end
    end)
    after(150, function()
        MM.forceGamepad = keep.pad0
        MM.deskAt, MM.deskBack = nil, nil
        K.spyOff()
        K.errCheck("the pad")
    end)
end
function X.padTargets()
    local t = {}
    for _, id in ipairs(K.ids()) do t[#t + 1] = "sw:" .. id end
    t[#t + 1] = "done"
    return t
end
function X.padStep(target, i, st)
    local w = K.pick()
    if not (w and K.up("desktopPick")) then st.bad[#st.bad + 1] = target .. ": the window is not up"; return end
    local path = K.path(w.focusId, target)
    if not path then st.bad[#st.bad + 1] = target .. ": no way there from " .. tostring(w.focusId); return end
    for _, d in ipairs(path) do
        K.dpad(d)
        if MM.deskAt ~= nil or MM.view ~= "desktopPick" then
            st.bad[#st.bad + 1] = target .. ": " .. d .. " left the window (" .. tostring(MM.deskAt or MM.view) .. ")"
            MM.deskAt, MM.deskBack = nil, nil
            return
        end
    end
    if w.focusId ~= target then st.bad[#st.bad + 1] = target .. ": the presses landed on " .. tostring(w.focusId); return end
    st.stepAt = getTimestampMs()
    if target ~= "done" then
        K.button(Joypad.AButton)
        local id = string.sub(target, 4)
        if MM.desktop() ~= id then st.bad[#st.bad + 1] = target .. ": A left the desktop on " .. tostring(MM.desktop()) end
    end
end
function X.padLook(target, i, st)
    local w = K.pick()
    if not w then st.bad[#st.bad + 1] = target .. ": no window"; return end
    if not st.stepAt then return end   -- (the step itself failed: said there)
    local r = keep.markRec
    if not (r and r.t >= st.stepAt and r.fid == target and r.shows) then
        st.bad[#st.bad + 1] = target .. ": no focus mark drawn (" .. (r and (tostring(r.fid) .. ", shows " .. tostring(r.shows)) or "none") .. ")"
    elseif target ~= "done" then
        local s = K.spec(w, target)
        if s and not (r.x == s.x and r.y == s.y and r.w == s.w and r.h == s.h) then st.bad[#st.bad + 1] = target .. ": the mark is off its cell" end
    end
    if target ~= "done" then
        local id = string.sub(target, 4)
        if w:getStatusLine() ~= K.help(id) then st.bad[#st.bad + 1] = target .. ": the help line reads \"" .. tostring(w:getStatusLine()) .. "\"" end
    end
    st.stepAt = nil
end

-- 7: the pictures
function X.shots()
    after(200, function()
        MM.forceGamepad = false        -- (no focus mark on the icons)
        MM.ctx.open = nil
        MM.deskAt, MM.deskBack = nil, nil
        MM.showView("desktop")
        K.hideConsole()
        for _, id in ipairs(K.ids()) do K.texReady(id) end   -- (every texture asked for early: a first ask draws nothing for a frame)
        if not getCore():getOptionDoVideoEffects() then note("video effects are off: bxd_video.png shows the painting (the game's fallback)") end
    end)
    for _, id in ipairs(K.ids()) do X.shotOne(id) end
    after(200, function()
        check(#keep.shotBad == 0 and #keep.shots == 25, "pictures: one per desktop (" .. #keep.shots .. "), each with its desktop set, every window closed and no menu open",
            K.short(keep.shotBad))
        say("pictures: Zomboid/Screenshots/" .. table.concat(keep.shots, " "))
        K.errCheck("the pictures")
    end)
end
function X.shotOne(id)
    after(100, function()
        keep.shotAt = getTimestampMs()
        MM.ctx.open = nil
        if MM.view ~= "desktop" then MM.showView("desktop") end
        MM.setDesktop(id)
    end)
    waitFor(function()
        return getTimestampMs() - keep.shotAt >= ((id == "video") and 2500 or 700) and K.texReady(id)
    end, 6000, function(met)
        local why = {}
        if not met then why[#why + 1] = "its texture never said ready" end
        if MM.desktop() ~= id then why[#why + 1] = "the desktop is " .. tostring(MM.desktop()) end
        if MM.ctx.open ~= nil then why[#why + 1] = "a menu is open (" .. tostring(MM.ctx.open) .. ")" end
        if MM.view ~= "desktop" or (K.pick() and K.pick():isVisible()) then why[#why + 1] = "a window is up (view " .. tostring(MM.view) .. ")" end
        local name = "bxd_" .. id .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(name) end)
        if not ok then why[#why + 1] = tostring(e) end
        if #why > 0 then keep.shotBad[#keep.shotBad + 1] = id .. ": " .. table.concat(why, ", ") end
        if ok then keep.shots[#keep.shots + 1] = name end
    end)
    after(1800, function() end)   -- (a 4K picture stalls the frames about 1.5 s)
end

-- 8: put back
function X.putBack()
    after(300, function()
        pcall(K.spyOff)
        MM.forceGamepad = keep.pad0
        MM.deskAt, MM.deskBack = nil, nil
        MM.ctx.open = nil
        pcall(MM.showView, "main")
        if keep.hl0 then pcall(K.setHL, keep.hl0[1], keep.hl0[2], keep.hl0[3]) end
        pcall(function()
            for _, p in ipairs({ { "baseTheme", keep.base0 }, { "statusColors", keep.status0 }, { "accentColor", keep.accent0 } }) do
                local o = K.opt(p[1])
                if o and p[2] ~= nil and K.val(p[1]) ~= p[2] then o:setValue(p[2]) end
            end
        end)
        pcall(function() St.applyThemeNow() end)
        if keep.desk0 then pcall(MM.setDesktop, keep.desk0) end
        if keep.bytes0 and keep.bytesOk then
            local ok, e = K.writeBytes(WALL, keep.bytes0)
            if not ok then say("ERR the file's bytes not written back: " .. tostring(e)); K.writeLines(WALL, keep.lines0) end
        elseif keep.lines0 then
            note(WALL .. ": its bytes could not be read at the start; written back line by line")
            K.writeLines(WALL, keep.lines0)
        end
        MM._wall = nil   -- (read from the file again, as the next launch will)
        keep.consN, keep.consBad = K.showConsole()
    end)
    after(400, function()
        check(MM.desktop() == keep.desk0, "put back: the file reads as the desktop found", tostring(MM.desktop()))
        if keep.absent0 then
            local l = K.readLines(WALL)
            note("put back: " .. WALL .. " was not there before and now holds \"" .. tostring(l and l[1]) .. "\" (the same as no file); delete Zomboid/Lua/" .. WALL .. " to have it gone")
        elseif keep.bytes0 and keep.bytesOk then
            local now = K.readBytes(WALL)
            check(K.sameBytes(now, keep.bytes0), "put back: " .. WALL .. " byte for byte (" .. #keep.bytes0 .. " bytes)", now and (#now .. " bytes now") or "unread")
        else
            check(K.readLines(WALL) ~= nil and table.concat(K.readLines(WALL), "\n") == table.concat(keep.lines0 or {}, "\n"), "put back: " .. WALL .. " line for line")
        end
        check(keep.hl0 ~= nil and K.dist(K.hl(), keep.hl0) == 0, "put back: the highlight color as found", K.c3(K.hl()))
        local L = keep.look0 or {}
        check(ZeD.currentBase == L[1] and ZeD.currentAccent == L[2] and ZeD.currentSize == L[3] and ZeD.currentStatus == K.statusFound()
            and K.val("baseTheme") == keep.base0 and K.val("statusColors") == keep.status0 and K.val("accentColor") == keep.accent0,
            "put back: the theme, accent, text size and status colors as found",
            tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize) .. " " .. tostring(ZeD.currentStatus))
        check(MM.forceGamepad == keep.pad0 and (ZeD.Focus == nil or ZeD.Focus.mark == keep.mark0), "put back: the input lock and the focus mark function as found",
            "pad lock " .. tostring(MM.forceGamepad))
        check((keep.consBad or 0) == 0, "put back: the debug console shown again (" .. tostring(keep.consN or 0) .. " hidden for the pictures)")
        check(MM.view == "main" and K.up("main") and MM.ctx.open == nil and not (K.pick() and K.pick():isVisible()), "put back: the main window up, the Desktop window closed, no menu open",
            "view " .. tostring(MM.view))
    end)
    after(300, function()
        keep.zapFree = true
        K.freeZap()
        local z = MM._life and MM._life.zap
        if z then check(z.nextAt < 1e14, "put back: the lightning is let go") end
        K.errCheck("the put-back")
        local n = K.errs()
        if n ~= nil and keep.errs0 ~= nil then say("Lua errors counted during the run: " .. (n - keep.errs0)) end
    end)
end

-- =========================================================================================================
if not (MM and MM.root and MM.showView and MM.openDesktopPick and MM.setDesktop and DT and DT.draw and St) then
    after(100, function() S.fail = S.fail + 1; say("ERR ZeD's main menu or its Desktop is not up: nothing was done") end)
else
    X.start()
    X.menuRow()
    X.sweep()
    X.color()
    X.themes()
    X.pad()
    X.shots()
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
