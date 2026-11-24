-- ZeDUI/tools/qa/rt_system.lua  (Nov 18 2026, QA; tag rt_sys): the release test's system row (ZeDUI/qa/RELEASE_TEST.md).
-- Built on rt_kit.lua (the global RT); run after it. grep "ZEDQA rt_sys".
--   1. ZeD setup's settings (Settings.lua): a setting changed through ZeD's settings API (the action bar's style) is
--      written to ModOptions.ini, comes back when the game reads that file again, and is put back (file and value)
--   2. the in-game Options (ZeD_MainMenuOptions.lua, ZeD_MainMenuOptionGroups.lua): opened from the pause menu; ZeD
--      setup has its rows and groups; every group's page opens on screen with no Lua error; Back leaves it
--   3. UI scale (shared/ZeD/Scale.lua): every step this screen offers (not the retired 0.5x, not one too big for the
--      screen) is applied as ZeD setup applies it; the theme follows the new scale and both windows come back open
--      and on screen (RT.bounds); then the run's own step, and the windows where they were
--   4. themes and accents (Tokens.lua, PlayerTheme.lua): each base theme and each accent applies to ZeD's table and
--      the windows draw on screen in each base theme; then the run's own theme
--   5. safe mode (SafeMode.lua; zedqa_safemode.lua's checks): a trip shuts ZeD's windows and hands back the game's
--      inventory page, hotbar and moodles with a note; the inventory key goes to the game; a reset brings ZeD back;
--      the Safe mode option On and Off is picked up by itself within a second; a short burst of faults leaves ZeD on;
--      one place failing every frame trips it at two seconds, not before
--   6. step-aside (ZeD_StepAside.lua): with a mod that replaces a ZeD screen, that screen is handed back (its switch,
--      the record, "Taken by"); SKIP when no such mod is active
--   7. Messages (ZeD_Messages.lua, ZeD_MessagesWindow.lua): another mod's note is kept, not shown; the window opens
--      on that mod with the note's card; its OK runs the mod's own callback once
--   8. a short soak: two minutes of play with both windows open and their tabs turned, no new Lua error, and Lua
--      memory (collectgarbage("count"), after a full collect) grows by no more than SOAK_KB
--   9. translation (shared/ZeD/Tr.lua): every key in ZeD's English UI.json has text in the game, and every key ZeD
--      asked ZeD.tr for while this script ran (themes, scales, every tab in the soak) has text
-- Added Nov 18 2026 (the FEATURE_MAP gaps of "Settings, look and safety"):
--   2b. ZeD setup's own controls, as the pad works them (ZeD_MMOptions:nudge / activateRow), never applied: a moot
--      row takes no change, a mirrored game row is the game's own control, Find narrows and clears, Wheel toggle
--      mode dims open and commit, each dead zone step reads live, Back with a change asks, the Additions preset
--      sets its additions and a hand change reads Custom, Defaults puts every ZeD option on its first item; each
--      time Discard puts every control back on its stored pick
--   3. each UI scale step: a step the screen does not offer is a SKIP with the reason, and set by hand (as a saved
--      pick) it draws at the floor (0.5x) or the screen's cap; the cap's help line
--   4. the theme and every accent through the window box's own menu (ZeD_WindowMenu.lua): the accent's light or
--      dark variant, See-through forced solid outside Dark, the pick saved; the Character and World windows' own
--      accent, kept over a close and reopen; See-through 60 with no guarded fault; Solid while in use, Low-health
--      blink, Item-colored tiles, the four controller highlights, the Immersive or simple forms
--   5. safe mode also: a hand reset clears the trip, Off brings the windows back, Messages keeps nothing while on
--   6. a supported mod is never detected; 7. a balloon for a new message and its six seconds, the Bug report
--   9b. data: the sandbox WHEN and RISK tags, capitals for every language, the pixel fonts' extra letters
-- Added Nov 18 2026 (the ledger: FEATURE_MAP.md rows marked rt_sys that no check here measured): the Select wheel's
--   ZeD setup and Safe mode rows; each ZeD setup group named in words; the live preview and Discard; Restock needs
--   Loadouts; the text follows the root scale; both text sizes; both status color sets; the split view player's own
--   table (a stand-in player 2); UI sounds; the glyph set; the test language; the inventory key; one screen handed
--   back; the Messages foot band; the Sandbox options line; read marks on a skill book; chord setup
-- Every setting is put back exactly (the option values, the file, the scale, the theme, the windows): every ZeD
-- option's value in memory is kept at the start and set back at the end, and ModOptions.ini is written back line for
-- line (the window box's picks save it at once).
-- (Nov 23 2026, QA: ZeD's plug-in points (Build's fix/plugins) splice an add-on's rows into a ZeD setup group; the
-- group check reads G.groupRows(grp) where it exists, else the group's own list, grp[2].)
if not RT then
    print("ZEDQA rt_sys FAIL the kit (rt_kit.lua) is not loaded")
    print("ZEDQA rt_sys VERDICT FAIL 1")
    print("ZEDQA rt_sys DONE")
    return
end
local Q = RT.make("rt_sys")
Q.maxMs = 1020000                    -- (the runner gives this script 1200 s: the put-back runs before that)
local p, pn = RT.p, RT.pn
local St, Sf, MM, Sc = ZeD.Settings, ZeD.Safe, ZeD.MainMenu, ZeD.Scale
local SOAK_MS = 120000               -- two minutes of play
local SOAK_KB = 262144               -- the soak's memory bound: 256 MB of Java heap after a full collect
-- the run's state, one table (Kahlua's local limit)
local S = { keys = {}, trOn = false }
local H = {}

-- ===================================================================== helpers
function H.errs()
    local n = nil
    pcall(function() n = getLuaDebuggerErrorCount() end)
    return n
end
function H.mem()
    local kb = nil
    pcall(function() collectgarbage("collect") end)
    pcall(function() kb = collectgarbage("count") end)
    return kb
end
function H.menuUp()
    local up = false
    pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end)
    return up
end
function H.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
function H.onScreen(el)
    local ok = false
    pcall(function()
        local W, Hh = getCore():getScreenWidth(), getCore():getScreenHeight()
        local x, y = el:getAbsoluteX(), el:getAbsoluteY()
        ok = x >= -1 and y >= -1 and x + el:getWidth() <= W + 1 and y + el:getHeight() <= Hh + 1
    end)
    return ok
end
-- ModOptions.ini's stored value for one of ZeD's options (the line "combobox|ZeD_UI|<id>|<n>"), nil when absent
function H.iniValue(id)
    local v = nil
    pcall(function()
        local r = getFileReader("ModOptions.ini", false)
        if not r then return end
        local want = "combobox|ZeD_UI|" .. id .. "|"
        local l = r:readLine()
        while l do
            if l:sub(1, #want) == want then v = tonumber(l:sub(#want + 1)) end
            l = r:readLine()
        end
        r:close()
    end)
    return v
end
-- ModOptions.ini as lines (nil when it cannot be read), and written back as it was (the game's own line ends)
function H.readIni()
    local t = nil
    pcall(function()
        local r = getFileReader("ModOptions.ini", false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function H.writeIni(lines)
    if not lines then return false end
    local ok = pcall(function()
        local w = getFileWriter("ModOptions.ini", true, false)
        for _, l in ipairs(lines) do w:write(l .. "\r\n") end
        w:close()
    end)
    return ok
end
-- any file under Zomboid/Lua as lines (nil when there is none), and written back with "\n" ends (the way ZeD's
-- own chord and Messages files are written)
function H.readLines(name)
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
function H.writeLines(name, lines)
    local ok = pcall(function()
        local w = getFileWriter(name, true, false)
        for _, l in ipairs(lines or {}) do w:write(l .. "\n") end
        w:close()
    end)
    return ok
end
function H.bothOpen()
    local c, w = false, false
    pcall(function() c = ZeD_CharacterWindow.isOpen(pn) end)
    pcall(function() w = ZeD_WorldWindow.isOpen(pn) end)
    return c and w
end

-- ZeD's options (PZAPI.ModOptions "ZeD_UI") and one of them by id
function H.opts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo end
function H.opt(id) local zo = H.opts(); return zo and zo.dict and zo.dict[id] or nil end
function H.val(id) local o = H.opt(id); local v = nil; pcall(function() v = o:getValue() end); return v end
-- the pick on the screen (Options open: its control), else the stored one
function H.live(o) if not o then return nil end; local el = o.element; return (el and el.selected) or o:getValue() end
function H.same(c, d) return c ~= nil and d ~= nil and math.abs(c.r - d.r) < 0.002 and math.abs(c.g - d.g) < 0.002 and math.abs(c.b - d.b) < 0.002 end
function H.hexOf(c) if not c then return "nil" end; return string.format("rgb %d %d %d", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5)) end
function H.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = v end
    return o
end
-- parent[key] made equal to snap again, in place (a table other code holds stays the same table)
function H.restoreTable(parent, key, snap)
    if snap == nil then parent[key] = nil; return end
    local t = parent[key]
    if type(t) ~= "table" then t = {}; parent[key] = t end
    local drop = {}
    for k in pairs(t) do if snap[k] == nil then drop[#drop + 1] = k end end
    for _, k in ipairs(drop) do t[k] = nil end
    for k, v in pairs(snap) do t[k] = v end
end
-- the window box's menu (ZeD_WindowMenu.lua's WM.build): the group named by its key, and its i-th choice fired as a
-- click on it fires it. H.stub() stands for a ZeD window that is not the Character / World pair (its Accent is the
-- whole interface's); the pair's own windows give their own accent.
function H.stub() return { playerNum = pn, noResetControl = true } end
function H.menuGroup(win, key)
    local WM = ZeD.WindowMenu
    if not (WM and WM.build and win) then return nil end
    local items = {}
    pcall(function() items = WM.build(win) or {} end)
    local name = ZeD.tr(key)
    for _, it in ipairs(items) do if it.name == name and it.children then return it end end
    return nil
end
function H.menuPick(win, key, i)
    local g = H.menuGroup(win, key)
    local leaf = g and g.children[i]
    if not (leaf and leaf.onFire) then return false end
    return pcall(leaf.onFire) and true or false
end
-- every ZeD option's value back as the script found it (in memory; the file is written back on its own), and the
-- copies Settings.lua keeps on the character
function H.putOptions()
    local zo = H.opts()
    for id, v in pairs(S.opt0 or {}) do
        local o = zo and zo.dict and zo.dict[id]
        if o and (o.selected ~= v or (o.element and o.element.selected ~= v)) then pcall(function() o:setValue(v) end) end
    end
    pcall(function()
        local md = p:getModData()
        H.restoreTable(md, "ZeD_Theme", S.mdTheme0)
        H.restoreTable(md, "ZeD_Gamepad", S.mdPad0)
        local ws = md.ZeD_WinState
        if ws and ws.char then ws.char.accentKey = S.wsC0 end
        if ws and ws.world then ws.world.accentKey = S.wsW0 end
    end)
    ZeD._pendingCharAccent, ZeD._pendingWorldAccent = S.pendC0, S.pendW0
end
-- the look as the script found it: the see-through pick, the status set, the theme
function H.putLook()
    if not S.look0 then return end
    ZeD.surfaceAlpha, ZeD._seePick, ZeD._seeForced = S.look0.a, S.look0.pick, S.look0.forced
    ZeD.currentStatus = S.look0.status
    pcall(function() if ZeD_Window and ZeD_Window.clearPaletteCache then ZeD_Window.clearPaletteCache() end end)
    pcall(ZeD.applyTheme, S.base0, S.accent0, S.size0)
end
-- the ids of ZeD's options whose control (Options open) is not on the stored pick
function H.liveOff()
    local bad = {}
    local zo = H.opts()
    for _, o in ipairs((zo and zo.data) or {}) do
        if o.type == "combobox" and o.element and o.element.selected ~= o.selected then bad[#bad + 1] = tostring(o.id) end
    end
    return bad
end
-- ZeD setup's row for one of ZeD's options, and a row stepped to item want as the pad's Left / Right do
function H.setupRow(w, id)
    local o = H.opt(id)
    local el = o and o.element
    if not el then return nil end
    local rows = {}
    pcall(function() rows = w:zedSetupRows() end)
    for _, r in ipairs(rows) do if r.control == el then return r end end
    -- (Nov 20 2026, Cuts C: a merged row works several options, its own control listing them in r.zedIds)
    for _, r in ipairs(rows) do
        for _, z in ipairs(r.zedIds or (r.control and r.control.zedIds) or {}) do if z == id then return r end end
    end
    return nil
end
function H.nudgeTo(w, r, want)
    local c = r and r.control
    if not c then return false end
    for _ = 1, 16 do
        local cur = c.selected or 1
        if cur == want then return true end
        pcall(function() w:nudge(r, (want > cur) and 1 or -1) end)
        if c.selected == cur then return false end
    end
    return c.selected == want
end
-- the rows the Options window lays out now (its pad stops: every row that takes a press)
function H.listRows(w)
    local out = {}
    for _, sp in ipairs((w and w._specs) or {}) do if sp.listRow and sp.rowRef then out[#out + 1] = sp.rowRef end end
    return out
end
function H.toastsOf(name)
    local n = 0
    for _, t in ipairs((ZeD.Messages and ZeD.Messages.toasts) or {}) do if t.source == name then n = n + 1 end end
    return n
end

-- every key ZeD.tr is asked for while the script runs (checked at the end: section 9)
S.trWas = ZeD.tr
ZeD.tr = function(key, ...)
    if S.trOn and type(key) == "string" then S.keys[key] = true end
    return S.trWas(key, ...)
end

-- ===================================================================== 0. setup
Q.step(5, function()
    S.trOn = true
    S.winsWere = RT.isOpen()
    RT.pairOpen()
    if ZEDQA_LAYOUT_SNAP then pcall(function() S.snap = ZEDQA_LAYOUT_SNAP() end) end
    S.err0 = H.errs()
    -- what this script may change, as found: every ZeD option's value, the copies on the character, the look
    S.opt0 = {}
    local zo = H.opts()
    for _, o in ipairs((zo and zo.data) or {}) do
        if o.type == "combobox" and o.id then S.opt0[o.id] = o.selected end
    end
    pcall(function()
        local md = p:getModData()
        S.mdTheme0, S.mdPad0 = H.copy(md.ZeD_Theme), H.copy(md.ZeD_Gamepad)
        local ws = md.ZeD_WinState
        S.wsC0 = ws and ws.char and ws.char.accentKey
        S.wsW0 = ws and ws.world and ws.world.accentKey
    end)
    S.pendC0, S.pendW0 = ZeD._pendingCharAccent, ZeD._pendingWorldAccent
    S.look0 = { a = ZeD.surfaceAlpha, pick = ZeD._seePick, forced = ZeD._seeForced, status = ZeD.currentStatus }
    S.base0, S.accent0, S.size0 = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    S.root0 = Sc and Sc.root()
    Q.check(St ~= nil and Sf ~= nil and MM ~= nil and Sc ~= nil, "ZeD's settings, safe mode, main menu and scale modules are loaded")
end)

-- ===================================================================== 1. a setting saves and comes back
Q.step(5, function()
    local o = St.lookStyleOption
    if not o then Q.check(false, "ZeD's settings API has the Style option (lookStyle)"); return end
    S.abWas = o:getValue()
    S.abIniWas = H.iniValue("lookStyle")
    -- (the whole file kept: saving writes every option's value in memory, so it is put back line for line)
    S.ini0 = H.readIni()
    S.abNew = (S.abWas == 2) and 1 or 2
    o:setValue(S.abNew)
    St.save()
    Q.check(H.iniValue("lookStyle") == S.abNew, "a changed setting is written to ModOptions.ini", "file " .. tostring(H.iniValue("lookStyle")) .. ", want " .. S.abNew)
    -- the value in memory set back, then the game reads its file again: the saved one comes back
    o:setValue(S.abWas)
    pcall(function() PZAPI.ModOptions:load() end)
    Q.check(o:getValue() == S.abNew, "the saved setting comes back when the game reads ModOptions.ini", "value " .. tostring(o:getValue()))
end)
Q.step(5, function()
    local o = St.lookStyleOption
    if not (o and S.abWas) then return end
    o:setValue(S.abWas)
    if S.ini0 then H.writeIni(S.ini0) else St.save() end
    S.iniBack = true
    Q.check(o:getValue() == S.abWas and H.iniValue("lookStyle") == S.abIniWas, "the setting is put back, in memory and in the file",
        "value " .. tostring(o:getValue()) .. ", file " .. tostring(H.iniValue("lookStyle")))
    local now = H.readIni()
    Q.check(S.ini0 ~= nil and now ~= nil and table.concat(now, "\n") == table.concat(S.ini0, "\n"), "ModOptions.ini is back line for line",
        tostring(now and #now) .. " lines, " .. tostring(S.ini0 and #S.ini0) .. " before")
end)

-- ===================================================================== 2. the in-game Options: ZeD setup and the groups
Q.step(5, function()
    S.menuWas = H.menuUp()
    if not S.menuWas then H.toggleMenu() end
end)
Q.waitFor(10, 400, function() return H.menuUp() and MM.pauseOpts ~= nil end, function(ok)
    Q.check(ok, "the pause menu opens (ZeD's pause window)")
    if ok then pcall(MM.openOptions) end
end)
Q.waitFor(5, 300, function() return MM.pauseOpts ~= nil and MM.pauseOpts:isVisible() end, function(ok)
    Q.check(ok, "Options opens from the pause menu (ZeD's window)")
    S.optsOk = ok
    if not ok then return end
    local w = MM.pauseOpts
    S.pages = w:pages()
    S.pageWas = w.pageIdx
    S.pageRes = {}
    S.pi, S.pf = 0, 0
    S.errOpts = H.errs()
end)
-- each page in turn, six frames each; what each one showed is kept for the checks
Q.waitFor(2, 3000, function()
    if not S.optsOk then return true end
    local w = MM.pauseOpts
    S.pf = S.pf + 1
    if S.pf < 6 then return false end
    S.pf = 0
    if S.pi > 0 then
        local pg = S.pages[S.pi]
        local rows = w:rowsFor(pg) or {}
        local heads = 0
        for _, r in ipairs(rows) do if r.kind == "header" then heads = heads + 1 end end
        S.pageRes[S.pi] = { title = tostring(pg.title), setup = pg.setup, rows = #rows, heads = heads,
            shown = w:isVisible() and w.pageIdx == S.pi, onScreen = H.onScreen(w) }
    end
    S.pi = S.pi + 1
    if S.pi > #S.pages then return true end
    w.pageIdx = S.pi
    w.scroll = 0
    return false
end, function(ok)
    if not S.optsOk then return end
    Q.check(ok and #S.pageRes == #S.pages and #S.pages > 1, "every Options group's page was opened", #S.pageRes .. " of " .. #S.pages)
    local setupSeen = false
    for _, r in ipairs(S.pageRes) do
        if r.setup then
            setupSeen = true
            Q.check(r.rows > 0 and r.heads > 0, "ZeD setup opens with its groups and rows", r.heads .. " groups, " .. r.rows .. " rows")
        end
        Q.check(r.shown and r.onScreen, "Options, " .. r.title .. ": the page opens, the window on screen", r.rows .. " rows")
    end
    Q.check(setupSeen, "Options has ZeD setup")
    local e1 = H.errs()
    if S.errOpts and e1 then Q.check(e1 == S.errOpts, "the Options pages drew with no Lua error", (e1 - S.errOpts) .. " new") end
end)
Q.step(5, function()
    local w = MM.pauseOpts
    if not (S.optsOk and w) then return end
    if S.pageWas then w.pageIdx = S.pageWas end
    pcall(function() w:back() end)
end)
Q.step(10, function()
    if S.optsOk then Q.check(MM.pauseView == "pause", "Back leaves Options for the pause menu", tostring(MM.pauseView)) end
    if not S.menuWas and H.menuUp() then H.toggleMenu() end
end)
Q.waitFor(5, 300, function() return S.menuWas or not H.menuUp() end, function(ok)
    Q.check(ok, "the pause menu shuts again")
end)
-- (Nov 18 2026, the ledger) the Select wheel's ZeD setup row (ZeD_DpadWheels.lua H.openSetup, what the row runs):
-- the pause screen, then three frames on, Options on its first page
Q.step(5, function()
    local D = ZeD.DpadWheels
    S.wsMenuWas = H.menuUp()
    S.wsOk = D ~= nil and D.H ~= nil and D.H.openSetup ~= nil
    if not S.wsOk then Q.check(false, "the Select wheel has its ZeD setup row (DpadWheels H.openSetup)"); return end
    pcall(D.H.openSetup, p, pn)
end)
Q.waitFor(5, 400, function()
    if not S.wsOk then return true end
    local w = MM.pauseOpts
    return H.menuUp() and w ~= nil and w:isVisible() and MM.pauseView == "options"
end, function(ok)
    if not S.wsOk then return end
    local w = MM.pauseOpts
    local F = RT.focus()
    local up = true
    if F and F.pauseMenuUp then pcall(function() up = F.pauseMenuUp() and true or false end) end
    Q.check(ok and up and w ~= nil and w.pageIdx == 1, "the Select wheel's ZeD setup row: the pause screen, then Options on its first page",
        "view " .. tostring(MM.pauseView) .. ", page " .. tostring(w and w.pageIdx) .. ", pause up " .. tostring(up))
    if ok then RT.bounds(Q, "ZeD setup from the Select wheel") end
    if w then pcall(function() w:back() end) end
end)
Q.step(10, function()
    if S.wsOk and not S.wsMenuWas and H.menuUp() then H.toggleMenu() end
end)
Q.waitFor(5, 300, function() return not S.wsOk or S.wsMenuWas or not H.menuUp() end, function(ok)
    if S.wsOk then Q.check(ok, "the pause menu shuts after the wheel's ZeD setup") end
end)

-- ===================================================================== 2b. ZeD setup's controls (never applied)
-- Worked as the pad works them (ZeD_MMOptions:nudge is Left / Right, activateRow is A); a click runs the same
-- functions. Nothing is applied: Discard (the footer's, discardStay) puts every control back on its stored pick, and
-- Settings.lua's wrap re-applies the stored look.
Q.step(5, function()
    S.menuWas2 = H.menuUp()
    if not S.menuWas2 then H.toggleMenu() end
end)
Q.waitFor(10, 400, function() return H.menuUp() and MM.pauseOpts ~= nil end, function(ok)
    if ok then pcall(MM.openOptions) end
end)
Q.waitFor(5, 300, function() return MM.pauseOpts ~= nil and MM.pauseOpts:isVisible() end, function(ok)
    S.o2 = ok
    if not ok then Q.check(false, "Options opens again for ZeD setup's controls"); return end
    local w = MM.pauseOpts
    S.page2 = w.pageIdx
    for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
    w.scroll = 0
    -- the game's rows: the Dyslexic font works only somewhere. (Nov 20 2026, Cuts C, the visual noise audit 29: the
    -- game's settings that do nothing with ZeD on, G.MOOT, are hidden; they were grayed rows with a warning.)
    local moots, only, all, origs = {}, nil, 0, {}
    local MOOT = (MM.optionGroups and MM.optionGroups.MOOT) or {}
    for _, pg in ipairs(w:pages()) do
        for _, r in ipairs(w:rowsFor(pg) or {}) do
            if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then all = all + 1 end
            if not pg.setup and r.opt and r.opt.name and not r.setupCopy then
                if MOOT[r.opt.name] then moots[#moots + 1] = r.opt.name end
                if r.opt.name == "enableDyslexicFont" then only = r end
                origs[r.opt.name] = origs[r.opt.name] or r
            end
        end
    end
    S.allRows = all
    Q.check(MOOT.inventoryFont ~= nil and #moots == 0, "Options: the game's settings that do nothing with ZeD on (Inventory font and the rest) are not listed",
        (#moots > 0) and ("listed: " .. table.concat(moots, " ")) or "none listed")
    Q.check(only ~= nil and only.only ~= nil, "Options: the game's Dyslexic font row says where it still works", only and tostring(only.only and only.only[1]) or "no row")
    -- (Nov 20 2026, Cuts C: ZeD setup no longer copies the game's settings; each is in its own group, Font size first)
    local copies = {}
    for _, r in ipairs(w:zedSetupRows() or {}) do
        local nm = r.setupCopy and r.opt and r.opt.name
        if nm and not tostring(nm):find("ZeD_UI.", 1, true) then copies[#copies + 1] = nm end   -- (ZeD's own rows are ModOptions "ZeD_UI.<id>")
    end
    Q.check(#copies == 0 and origs.fontSize ~= nil, "ZeD setup: no copies of the game's settings; Font size is in its own group",
        #copies .. " copies" .. ((#copies > 0) and (": " .. table.concat(copies, " ")) or "") .. ", Font size row " .. tostring(origs.fontSize ~= nil))
end)
-- Find: "scale" narrows the list to the matching rows, UI scale among them; cleared, the page comes back
Q.step(3, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    S.rows2 = #H.listRows(w)
    pcall(function() w.find:setText("scale") end)
end)
Q.step(4, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    local rows = H.listRows(w)
    local hasScale = false
    for _, r in ipairs(rows) do if r.labelKey == "UI_ZeD_Settings_UiScale" then hasScale = true end end
    Q.check(#rows > 0 and #rows < (S.allRows or 0) and hasScale, "Options, Find \"scale\": only the matching rows, UI scale among them",
        #rows .. " of " .. tostring(S.allRows) .. " rows, UI scale " .. tostring(hasScale))
    pcall(function() w.find:setText("") end)
end)
Q.step(4, function()
    if not S.o2 then return end
    local n = #H.listRows(MM.pauseOpts)
    Q.check(n > 0 and n == S.rows2, "Options, Find cleared: ZeD setup's rows come back", n .. " rows, " .. tostring(S.rows2) .. " before")
end)
-- (Nov 18 2026, the ledger) each group of G.ZED_GROUPS: its heading in words, a row with a control for each of its
-- options, each row's name in words (not its key); the Chords group a row per chord
Q.step(2, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    local G = MM.optionGroups
    local heads, chords = {}, 0
    for _, r in ipairs(w:zedSetupRows() or {}) do
        if r.kind == "header" then heads[tostring(r.text)] = true end
        if r.kind == "chord" then chords = chords + 1 end
    end
    local n, rows, bad = 0, 0, {}
    -- (Nov 21 2026, the Light and Lite run) In Lite, ZeD setup leaves out the Additions and Chords groups and the Watch
    -- row (the director: "If vanilla does it, so does Lite"; FEATURE_MAP "Style: Lite or Full"). They are pinned here,
    -- not read from G.LITE_HIDES, so a group cut from Lite by mistake still fails; and what Lite leaves out must be gone
    -- from the whole page, none of it under Other (the Nov 20 fault: the Additions under Other, Restock taking a change
    -- with Loadouts Off). A row hidden by its own rule (a debug switch outside debug mode, Restock while Loadouts is
    -- off) is not asked for.
    local lite = (St.lite and St.lite()) and true or false
    local dbg = (isDebugEnabled and isDebugEnabled()) and true or false
    -- (Nov 21 2026, the director on B3-2: "Keep and show them", 0bb5eba0e) In Lite the Additions group comes back while
    -- the applied extras are off the Vanilla preset, so a player who came into Lite with extras on sees them; Chords
    -- stays out. Read through ZeD.Settings.additionsOffVanilla() and cross-checked here: an applied Ammo on the belt
    -- set On is off the Vanilla preset for certain.
    local offV = (St.additionsOffVanilla and St.additionsOffVanilla()) and true or false
    local ammoOn = false
    pcall(function() local o = H.opt("ammoBox"); ammoOn = (o and o:getValue() == 2) and true or false end)
    if lite and ammoOn and not offV then bad[#bad + 1] = "additionsOffVanilla false with Ammo on the belt On" end
    local LITE_GROUPS = { UI_ZeD_Options_ZedChords = true }
    if not offV then LITE_GROUPS.UI_ZeD_Options_ZedAdditions = true end    local LITE_ROWS = { watchPlace = true }
    for _, grp in ipairs((G and G.ZED_GROUPS) or {}) do
        n = n + 1
        local title = G.text(grp[1])
        local gone = lite and LITE_GROUPS[grp[1]] == true
        if gone then
            if heads[tostring(title)] then bad[#bad + 1] = "Lite shows heading " .. tostring(grp[1]) end
        elseif title == grp[1] or not heads[tostring(title)] then bad[#bad + 1] = "heading " .. tostring(grp[1]) end
        -- (Nov 23 2026: with the plug-in points, G.groupRows(grp) is the group's rows with an add-on's spliced in)
        for _, e in ipairs((G.groupRows and G.groupRows(grp)) or grp[2] or {}) do
            local o = H.opt(e[1])
            if o and o.element then
                local r = H.setupRow(w, e[1])
                if gone or (lite and LITE_ROWS[e[1]]) then
                    if r then bad[#bad + 1] = "Lite shows " .. tostring(e[1]) end
                elseif not ((e.debugOnly and not dbg) or (e.showIf ~= nil and G.liveOf ~= nil and G.liveOf(H.opts(), e.showIf) ~= 2)) then
                    local key = r and r.labelKey
                    rows = rows + 1
                    if not (r and r.control) or (key ~= nil and ZeD.tr(key) == key) then bad[#bad + 1] = tostring(e[1]) end
                end
            end
        end
        if grp.chords and chords ~= (gone and 0 or #((ZeD.QuickChords and ZeD.QuickChords.CHORDS) or {})) then bad[#bad + 1] = "chords " .. chords end
    end
    Q.check(n > 0 and rows > 0 and #bad == 0, "ZeD setup: every group has its heading and a named row for each of its options",
        n .. " groups, " .. rows .. " rows" .. (lite and (offV and ", Lite, extras off Vanilla" or ", Lite, extras on Vanilla") or "") ..
        ((#bad > 0) and (", wrong: " .. table.concat(bad, " ")) or ""))
end)
-- the wheels (Nov 20 2026, Cuts C: one merged row for open, commit and toggle mode, G.MERGED.wheels): each of its
-- four ways read live; then each Dead zone step read live
Q.step(3, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    local rW, rD = H.setupRow(w, "wheelOpen"), H.setupRow(w, "wheelDeadZone")
    local merged = rW and rW == H.setupRow(w, "wheelCommit") and rW == H.setupRow(w, "wheelToggle")
    if not (merged and rD) then
        Q.check(false, "ZeD setup has the Wheels row (open, commit and toggle as one) and the Dead zone row", tostring(merged) .. " " .. tostring(rD ~= nil))
        return
    end
    -- item: { toggle, open, commit } as ZeD.Settings reads them (open/commit only matter with toggle off)
    local want = { { false, "hold", "flick" }, { false, "tap", "flick" }, { false, "tap", "click" }, { true } }
    local bad = {}
    for i = 1, 4 do
        H.nudgeTo(w, rW, i)
        local wt = want[i]
        local t, o, c = St.wheelToggle(), St.wheelOpen(), St.wheelCommit()
        local ok = rW.control.selected == i and t == wt[1] and (wt[1] or (o == wt[2] and c == wt[3]))
        if not ok then bad[#bad + 1] = i .. "=" .. tostring(t) .. "/" .. tostring(o) .. "/" .. tostring(c) end
    end
    Q.check(#bad == 0, "ZeD setup: each of the Wheels row's four ways (Hold and flick, Tap and flick, Tap and click, Toggle) is read live",
        (#bad > 0) and ("wrong: " .. table.concat(bad, " ")) or "4 ways")
    local nD, bad = #(rD.control.options or {}), {}
    for i = 1, nD do
        H.nudgeTo(w, rD, i)
        local want = nil
        pcall(function() want = tonumber(rD.control:getOptionText(i)) end)
        local got = St.wheelDeadZone()
        if not (rD.control.selected == i and want and math.abs(got - want) < 0.001) then bad[#bad + 1] = i .. "=" .. tostring(got) end
    end
    Q.check(nD > 0 and #bad == 0, "ZeD setup: each Wheel dead zone step is read live", nD .. " steps" .. ((#bad > 0) and (", wrong: " .. table.concat(bad, " ")) or ""))
end)
-- Back with those changes pending asks, and the window stays; Discard puts them back
Q.step(3, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    S.chg2 = w:anyChanged()
    pcall(function() w:back() end)
end)
Q.step(3, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    Q.check(S.chg2 and w.confirm == "back" and MM.pauseView == "options" and w:isVisible(), "Options: Back with a change pending asks first, and the window stays",
        "changed " .. tostring(S.chg2) .. ", confirm " .. tostring(w.confirm) .. ", view " .. tostring(MM.pauseView))
    pcall(function() w:discardStay() end)
end)
Q.step(3, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    local bad = H.liveOff()
    Q.check(#bad == 0 and not w:anyChanged() and not w.confirm, "Options: Discard puts every changed ZeD setup control back on its stored pick", table.concat(bad, " "))
end)
-- the Additions preset: Vanilla Plus sets every addition it names; one addition changed by hand reads Custom
Q.step(3, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    local rP, rA = H.setupRow(w, "additionsPreset"), H.setupRow(w, "ammoBox")
    -- (Nov 21 2026, the Light and Lite run) Lite leaves the Additions group out of ZeD setup, so there is no preset to
    -- pick here: Full's step. A row that shows in Lite anyway fails the step above, and this step still runs on it.
    if not (rP or rA) and St.lite and St.lite() then
        Q.skip("ZeD setup, Additions: picking Vanilla Plus sets every addition to the preset's", "Style is Lite, and Lite leaves the Additions group out of ZeD setup")
        return
    end
    local P2 = St.ADDITION_PRESETS and St.ADDITION_PRESETS[2]
    if not (rP and rA and P2) then Q.check(false, "ZeD setup has the Additions preset and Ammo on the belt rows"); return end
    H.nudgeTo(w, rP, 2)
    local bad = {}
    for _, id in ipairs(St.ADDITION_IDS or {}) do
        local o = H.opt(id)
        if o and P2[id] and H.live(o) ~= P2[id] then bad[#bad + 1] = id .. "=" .. tostring(H.live(o)) end
    end
    Q.check(rP.control.selected == 2 and #bad == 0, "ZeD setup, Additions: picking Vanilla Plus sets every addition to the preset's",
        "preset " .. tostring(rP.control.selected) .. ((#bad > 0) and (", off: " .. table.concat(bad, " ")) or ""))
    H.nudgeTo(w, rA, (rA.control.selected == 2) and 1 or 2)
    pcall(St.syncAdditionsPreset)
    Q.check(rP.control.selected == 4, "ZeD setup, Additions: one addition changed by hand makes the preset read Custom", "preset " .. tostring(rP.control.selected))
    pcall(function() w:discardStay() end)
end)
Q.step(3, function()
    if not S.o2 then return end
    local bad = H.liveOff()
    Q.check(#bad == 0 and not MM.pauseOpts:anyChanged(), "Options: Discard puts the preset and the additions back", table.concat(bad, " "))
end)
-- (Nov 18 2026, the ledger) the live preview: a base theme picked on ZeD setup (not applied) shows at once, and
-- Discard brings the stored one back on screen
Q.step(3, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    local rB = H.setupRow(w, "baseTheme")
    S.prevOk = rB ~= nil
    if not rB then Q.check(false, "ZeD setup has the Base theme row"); return end
    local i = (S.base0 == "light") and 1 or 2
    local want = St.baseKeys[i]
    H.nudgeTo(w, rB, i)
    Q.check(rB.control.selected == i and ZeD.currentBase == want and ZeD.T ~= nil and ZeD.T.baseKey == want,
        "ZeD setup: a base theme picked without Apply shows at once (the live preview)", tostring(ZeD.currentBase) .. ", want " .. tostring(want))
    pcall(function() w:discardStay() end)
end)
Q.step(3, function()
    if not (S.o2 and S.prevOk) then return end
    local bad = H.liveOff()
    Q.check(#bad == 0 and ZeD.currentBase == S.base0 and ZeD.T ~= nil and ZeD.T.baseKey == S.base0,
        "Discard puts back the live preview: the stored base theme is on screen again", tostring(ZeD.currentBase) .. ", want " .. tostring(S.base0) .. " | " .. table.concat(bad, " "))
end)
-- (Nov 18 2026, the ledger) Restock needs Loadouts: with Loadouts Off, A (activateRow) and Left / Right (nudge) on
-- Restock change nothing; with Loadouts On the same nudge changes it; then Discard
Q.step(3, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    local rL, rR = H.setupRow(w, "loadouts"), H.setupRow(w, "restock")
    -- (Nov 21 2026, the Light and Lite run) Lite leaves Loadouts and Restock out of ZeD setup with the Additions group:
    -- nothing to gate. A Restock row that shows in Lite anyway (under Other, the Nov 20 fault) must still follow
    -- Loadouts, so with either row on the page the step runs.
    if not (rL or rR) and St.lite and St.lite() then
        Q.skip("Restock needs Loadouts: with Loadouts Off its row takes no change", "Style is Lite, and Lite leaves Loadouts and Restock out of ZeD setup with the Additions group")
        return
    end
    if not (rL and rR) then Q.check(false, "ZeD setup has the Loadouts and Restock rows"); return end
    H.nudgeTo(w, rL, 1)
    local r0 = rR.control.selected
    local dir = (r0 == 1) and 1 or -1
    pcall(function() w:activateRow(rR) end)
    pcall(function() w:nudge(rR, dir) end)
    local off = rR.control.selected
    H.nudgeTo(w, rL, 2)
    pcall(function() w:nudge(rR, dir) end)
    local on = rR.control.selected
    Q.check(off == r0 and on ~= r0, "Restock needs Loadouts: with Loadouts Off its row takes no change, with Loadouts On it does",
        "item " .. tostring(r0) .. ", Loadouts Off " .. tostring(off) .. ", Loadouts On " .. tostring(on))
    pcall(function() w:discardStay() end)
end)
Q.step(3, function()
    if not S.o2 then return end
    local bad = H.liveOff()
    Q.check(#bad == 0 and not MM.pauseOpts:anyChanged(), "Options: Discard puts Loadouts and Restock back", table.concat(bad, " "))
end)
-- Defaults: every ZeD option on the item it starts on (the quick chords' reset is held back: they save at once,
-- and the director's chords must stay); then Discard
Q.step(3, function()
    if not S.o2 then return end
    local w = MM.pauseOpts
    local QC = ZeD.QuickChords
    S.qcReset = QC and QC.reset
    S.qcCalls = 0
    if QC then QC.reset = function() S.qcCalls = S.qcCalls + 1 end end
    -- (Nov 21 2026, QA B3-1 3593f42c4 and B3-2 0bb5eba0e) In Lite the extras are rows while they are off the Vanilla
    -- preset and in Defaults' hidden list while Lite leaves them out: either way, with one of them on the button is live,
    -- and Defaults puts them on their first item (Off).
    S.liteHid = nil
    if St.lite and St.lite() then
        local function sel(id) local o = H.opt(id); return o and o.element and o.element.selected end
        S.liteHid = { b = { sel("ammoBox"), sel("readMarks"), sel("loadouts") }, live = w:zedOffDefault() and true or false }
    end
    local ok = pcall(function() w:zedDefaults() end)
    if S.liteHid then
        local function sel(id) local o = H.opt(id); return o and o.element and o.element.selected end
        local b = S.liteHid.b
        local was = tostring(b[1]) .. "/" .. tostring(b[2]) .. "/" .. tostring(b[3])
        if (b[1] ~= nil and b[1] ~= 1) or (b[2] ~= nil and b[2] ~= 1) or (b[3] ~= nil and b[3] ~= 1) then
            Q.check(S.liteHid.live, "ZeD setup (Lite): with an extra still on, Defaults is live", "ammo box/read marks/loadouts " .. was)
            local a1, a2, a3 = sel("ammoBox"), sel("readMarks"), sel("loadouts")
            Q.check(a1 == 1 and a2 == 1 and a3 == 1, "ZeD setup (Lite): Defaults puts the extras (ammo box, read marks, loadouts) on their first item",
                "ammo box/read marks/loadouts " .. was .. " -> " .. tostring(a1) .. "/" .. tostring(a2) .. "/" .. tostring(a3))
        else
            Q.skip("ZeD setup (Lite): Defaults on the extras", "none of them was on (" .. was .. ")")
        end
    end    if QC then QC.reset = S.qcReset end
    S.qcReset = nil
    -- (Nov 21 2026, QA B10-1, 9251ebdf6) Style, Map and Restock had no zedDefault, so Defaults skipped them and this
    -- check never saw them. Each of ZeD's own drop-downs and switches on the page must have one: a row whose control is
    -- one of ZeD's options' own, or the stand-in of a row that works several (G.MERGED, control.zedMerged). An add-on's
    -- row may have none by design (ZeD_MainMenuOptionGroups.lua addonRows), and the screens' check boxes are no
    -- drop-down (kind "tick").
    local own = {}
    local zo = H.opts()
    for _, o in ipairs((zo and zo.data) or {}) do if o.element then own[o.element] = tostring(o.id) end end
    local n, bad, noDef = 0, {}, {}
    -- (Nov 21 2026, the director, 7d8dc58ce: Defaults leaves Style as it is, so a Lite player stays in Lite; its row keeps
    -- its zedDefault for the help's "Default: Full" and carries zedNoReset, so it is not held to its default here)
    for _, r in ipairs(w:zedSetupRows() or {}) do
        local c = r.control
        if r.zedDefault and c and not c.disabled and not r.zedNoReset then
            n = n + 1
            if c.selected ~= r.zedDefault then bad[#bad + 1] = tostring(r.labelKey or r.label) .. "=" .. tostring(c.selected) end
        end
        if r.kind == "combo" and c and r.zedDefault == nil then
            local merged = nil
            pcall(function() if type(c) == "table" then merged = rawget(c, "zedMerged") end end)
            local id = own[c] or (merged and ("merged:" .. tostring(merged))) or nil
            if id then noDef[#noDef + 1] = id end
        end
    end
    Q.check(ok and n > 0 and #bad == 0 and #noDef == 0, "ZeD setup, Defaults: every ZeD option's control is on the item it starts on (each of ZeD's own drop-downs and switches has one)",
        n .. " rows" .. ((#bad > 0) and (", off: " .. table.concat(bad, " ")) or "")
        .. ((#noDef > 0) and (", with no default, so Defaults skips them: " .. table.concat(noDef, " ")) or ""))
    local chordsDefault = true
    for _, c in ipairs((QC and QC.CHORDS) or {}) do if not QC.isDefault(c) then chordsDefault = false end end
    if chordsDefault then
        Q.check(not w:zedOffDefault(), "ZeD setup, Defaults: afterwards nothing is off its default (the button greys out)")
    else
        Q.skip("nothing off its default after Defaults", "this game's quick chords are its own, and the test does not reset them (a chord saves at once)")
    end
    pcall(function() w:discardStay() end)
end)
Q.step(5, function()
    if not S.o2 then return end
    local bad = H.liveOff()
    Q.check(#bad == 0 and not MM.pauseOpts:anyChanged() and ZeD.currentBase == S.base0 and ZeD.currentAccent == S.accent0 and ZeD.currentSize == S.size0,
        "Options: Discard after Defaults puts every control and the look back", table.concat(bad, " ") .. " | " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent))
    local w = MM.pauseOpts
    if S.page2 then w.pageIdx = S.page2 end
    pcall(function() w:back() end)
end)
Q.step(10, function()
    if S.o2 then Q.check(MM.pauseView == "pause", "Back leaves Options with nothing pending", tostring(MM.pauseView)) end
    if not S.menuWas2 and H.menuUp() then H.toggleMenu() end
end)
Q.waitFor(10, 900, function()
    local T = ZeD.T
    return (S.menuWas2 or not H.menuUp()) and Sc._reopenAt == nil and T ~= nil and math.abs((T.root or 0) - Sc.root()) < 0.001
end, function(ok)
    Q.check(ok and math.abs(Sc.root() - (S.root0 or Sc.root())) < 0.001, "after ZeD setup's controls the scale is the run's own", "root " .. tostring(Sc.root()))
    RT.pairOpen()
end)
Q.step(30, function() RT.bounds(Q, "the windows after ZeD setup's controls") end)

-- ===================================================================== 3. UI scale: every step offered
Q.step(10, function()
    S.scaleOpt = St.uiScaleOption
    S.scaleWas = S.scaleOpt:getValue() or 1
    S.rootWas = Sc.root()
    S.tooBig = {}
    S.zooms = {}
    RT.pairOpen()
end)
-- (a step the screen does not offer is a SKIP for "drawn at that step", with the reason; it is still set by hand, as
-- a pick saved on a bigger screen or before the beta would be, and must draw at the floor or at this screen's cap)
for i = 1, #((St and St.scaleKeys) or {}) do
    Q.step(5, function()
        local v = St.scaleKeys[i]
        local label = tostring(St.scaleLabels[i])
        S.wantRoot = (type(v) == "number") and v or nil
        S.stepKind = "offered"
        if St.scaleStepOff(S.scaleOpt, i) then
            local W, Hh = RT.core:getScreenWidth(), RT.core:getScreenHeight()
            if St.scaleStepRetired and St.scaleStepRetired(i) then
                S.stepKind = "retired"
                Q.skip("UI scale " .. label .. " drawn at " .. label, "retired in the beta: ZeD setup's slider dims it and the wheel leaves it out")
                S.wantRoot = Sc.STEP_FLOOR or 0.75
            else
                S.stepKind = "toobig"
                S.tooBig[#S.tooBig + 1] = label
                Q.skip("UI scale " .. label .. " drawn at " .. label, "not offered on this " .. W .. "x" .. Hh .. " screen: over its cap of " .. tostring(Sc.fitCap()) .. "x")
                Q.check(St.scaleTooBigHelp() ~= nil, "UI scale " .. label .. ": dimmed, and ZeD setup's help line says it is too big", tostring(St.scaleTooBigHelp()))
                S.wantRoot = Sc.fitCap()
            end
        end
        S.scaleOpt:setValue(i)
        St.applyScale(i)
    end)
    Q.waitFor(10, 900, function()
        local T = ZeD.T
        return Sc._reopenAt == nil and T ~= nil and math.abs((T.root or 0) - Sc.root()) < 0.001 and H.bothOpen()
    end, function(ok)
        local label = tostring(St.scaleLabels[i])
        Q.check(ok, "UI scale " .. label .. ": the theme follows the new scale and both windows are open again", "root " .. tostring(Sc.root()))
        local T = ZeD.T
        local rootNow, tRoot = Sc.root(), T and T.root or -1
        if S.wantRoot then
            local at = math.abs(rootNow - S.wantRoot) < 0.001 and math.abs(tRoot - S.wantRoot) < 0.001
            if S.stepKind == "retired" then
                Q.check(at and S.scaleOpt:getValue() == i, "UI scale " .. label .. " set by hand: drawn at the floor " .. tostring(S.wantRoot) .. "x, the saved pick kept",
                    "root " .. tostring(rootNow) .. ", ZeD.T.root " .. tostring(tRoot) .. ", item " .. tostring(S.scaleOpt:getValue()))
            elseif S.stepKind == "toobig" then
                Q.check(at, "UI scale " .. label .. " set by hand: drawn at this screen's cap " .. tostring(S.wantRoot) .. "x",
                    "root " .. tostring(rootNow) .. ", ZeD.T.root " .. tostring(tRoot))
            else
                Q.check(at, "UI scale " .. label .. ": drawn at that scale (ZeD.T.root)", "root " .. tostring(rootNow) .. ", ZeD.T.root " .. tostring(tRoot))
            end
        end
        RT.bounds(Q, "UI scale " .. label)
        -- (the body font's zoom at this step, for "ZeD text follows the root scale" below)
        pcall(function()
            local T2 = ZeD.T
            S.zooms[#S.zooms + 1] = { z = ZeD.Text.zoomOf(T2.fontF2), r = Sc.root(), fb = T2.fontFallback }
        end)
    end)
end
-- the cap: on a small screen the steps over it are named in the help line; where every step fits there is none
Q.step(2, function()
    local cap, help = Sc.fitCap(), St.scaleTooBigHelp()
    if #(S.tooBig or {}) > 0 then
        Q.check(cap < 2 and help ~= nil, "UI scale cap: this screen offers up to " .. tostring(cap) .. "x and ZeD setup names the steps too big",
            table.concat(S.tooBig, " ") .. " | " .. tostring(help))
    else
        Q.check(help == nil, "UI scale cap: every step fits this screen and there is no too-big line", "cap " .. tostring(cap))
    end
    -- (Nov 18 2026, the ledger) ZeD's text follows the root scale (Overrides/TextScale.lua draws through
    -- ZeD.Text.zoomOf): at every step the body font's zoom is the root times one fixed size, so it grows with the root
    local zs = S.zooms or {}
    if zs[1] and zs[1].fb then
        Q.skip("ZeD text follows the root scale", "the game's own fonts stand in for ZeD's in this language (no zoom kept)")
    else
        local bad, k0 = {}, zs[1] and (zs[1].z / zs[1].r)
        local loR, hiR, loZ, hiZ = 99, -1, 99, -1
        for i, e in ipairs(zs) do
            if not (k0 and e.r > 0 and math.abs(e.z / e.r - k0) < 0.0005) then bad[#bad + 1] = i .. "=" .. tostring(e.z) end
            loR, hiR = math.min(loR, e.r), math.max(hiR, e.r)
            loZ, hiZ = math.min(loZ, e.z), math.max(hiZ, e.z)
        end
        Q.check(#zs > 1 and #bad == 0 and (hiR - loR < 0.001 or hiZ > loZ), "ZeD text follows the root scale: the body font's zoom is the root times its size at every step",
            #zs .. " steps, zoom " .. tostring(loZ) .. " to " .. tostring(hiZ) .. ((#bad > 0) and (", off: " .. table.concat(bad, " ")) or ""))
    end
end)
Q.step(5, function()
    S.scaleOpt:setValue(S.scaleWas)
    St.applyScale(S.scaleWas)
end)
Q.waitFor(10, 900, function()
    local T = ZeD.T
    return Sc._reopenAt == nil and T ~= nil and math.abs((T.root or 0) - Sc.root()) < 0.001
end, function(ok)
    Q.check(ok and S.scaleOpt:getValue() == S.scaleWas and math.abs(Sc.root() - S.rootWas) < 0.001,
        "UI scale put back on the run's own step", "option " .. tostring(S.scaleOpt:getValue()) .. ", root " .. tostring(Sc.root()))
    if ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, S.snap, "rt_sys scale") end
end)
Q.step(30, function() RT.bounds(Q, "the windows back after the scale steps") end)

-- ===================================================================== 4. themes and accents
-- (each pick through the window box's own menu, as a click on it: ZeD.applyTheme, then saved to the options; the
-- options, the file and the character's copy are put back after)
Q.step(5, function()
    RT.pairOpen()
end)
for i, b in ipairs((St and St.baseKeys) or {}) do
    Q.step(3, function() S.picked = H.menuPick(H.stub(), "UI_ZeD_WinMenu_Theme", i) end)
    Q.step(8, function()
        local T = ZeD.T
        Q.check(S.picked and T ~= nil and T.baseKey == b and ZeD.currentBase == b and H.val("baseTheme") == i,
            "theme " .. b .. ": the window box's Theme pick applies to ZeD's table and is saved as item " .. i,
            tostring(T and T.baseKey) .. ", option " .. tostring(H.val("baseTheme")))
        local tone = (b == "light") and "light" or "dark"
        local set = ZeD.AccentColors[ZeD.currentAccent]
        Q.check(T ~= nil and set ~= nil and H.same(T.accent, set[tone].accent), "theme " .. b .. ": the accent is its " .. tone .. " variant",
            H.hexOf(T and T.accent) .. ", want " .. H.hexOf(set and set[tone].accent))
        local wantA = (b == "dark") and (St.seeThrough() / 100) or 1
        Q.check(math.abs((ZeD.surfaceAlpha or -1) - wantA) < 0.001, "theme " .. b .. ": See-through " .. ((b == "dark") and "is the player's pick" or "is forced solid"),
            "surfaceAlpha " .. tostring(ZeD.surfaceAlpha) .. ", want " .. tostring(wantA))
        RT.bounds(Q, "theme " .. b)
    end)
end
Q.step(3, function() ZeD.applyTheme(S.base0, S.accent0, S.size0) end)
for i, a in ipairs((St and St.accentKeys) or {}) do
    Q.step(2, function() S.picked = H.menuPick(H.stub(), "UI_ZeD_WinMenu_Accent", i) end)
    Q.step(4, function()
        local T = ZeD.T
        local tone = (T and T.baseKey == "light") and "light" or "dark"
        local set = ZeD.AccentColors[a]
        Q.check(S.picked and T ~= nil and T.accentKey == a and ZeD.currentAccent == a and set ~= nil and H.same(T.accent, set[tone].accent) and H.val("accentColor") == i,
            "accent " .. a .. ": the window box's Accent pick gives its " .. tone .. " color and is saved as item " .. i,
            tostring(T and T.accentKey) .. ", " .. H.hexOf(T and T.accent) .. ", want " .. H.hexOf(set and set[tone].accent) .. ", option " .. tostring(H.val("accentColor")))
    end)
end
-- (Nov 18 2026, the ledger) each text size through the window box's Text size menu: the scale is the root times the
-- size's, the sort bar's font is F5 at Small and F1 at Large, the pick saved; the windows on screen (Large at 1280x800)
for i, k in ipairs((St and St.sizeKeys) or {}) do
    Q.step(2, function() S.picked = H.menuPick(H.stub(), "UI_ZeD_Settings_TextSize", i) end)
    Q.step(8, function()
        local T = ZeD.T
        local sz = ZeD.TextSizes and ZeD.TextSizes[k]
        local font = T and ((k == "large") and T.fontF1 or T.fontF5)
        local want = (T and sz) and (T.root * sz.scale) or -1
        Q.check(S.picked and T ~= nil and sz ~= nil and ZeD.currentSize == k and math.abs((T.scale or 0) - want) < 0.001 and T.sortFont == font and H.val("textSize") == i,
            "text size " .. k .. ": the window box's Text size pick sets the scale and the sort font, saved as item " .. i,
            "scale " .. tostring(T and T.scale) .. ", want " .. tostring(want) .. ", option " .. tostring(H.val("textSize")))
        RT.bounds(Q, "text size " .. k)
    end)
end
Q.step(3, function()
    ZeD.applyTheme(S.base0, S.accent0, S.size0)
    H.putOptions()
end)
Q.step(5, function()
    local T = ZeD.T
    Q.check(ZeD.currentBase == S.base0 and ZeD.currentAccent == S.accent0 and ZeD.currentSize == S.size0 and T and T.baseKey == S.base0,
        "the run's own theme, accent and text size are back", tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize))
end)
-- (Nov 18 2026, the ledger) Status colors (ZeD setup's radio; its change runs the option's onChange, as the control
-- does): Color blind gives the base theme's color blind set, Standard the theme's own; then the pick as found
Q.step(3, function()
    local o = St.statusColorsOption
    if not (o and o.onChange) then Q.check(false, "ZeD's settings have the Status colors option"); return end
    local v0 = o:getValue()
    local function pick(i) o:setValue(i); o.onChange(o, i) end
    pcall(pick, 2)
    local T, b = ZeD.T, ZeD.currentBase
    local cb = ZeD.StatusColors and ZeD.StatusColors.cb and ZeD.StatusColors.cb[b]
    Q.check(ZeD.currentStatus == "cb" and T ~= nil and T.statusKey == "cb" and cb ~= nil and H.same(T.positive, cb.positive),
        "Status colors Color blind: good, warning and bad come from the color blind set", tostring(b) .. ", " .. H.hexOf(T and T.positive) .. ", want " .. H.hexOf(cb and cb.positive))
    pcall(pick, 1)
    T = ZeD.T
    local base = ZeD.BaseThemes and ZeD.BaseThemes[b]
    Q.check(ZeD.currentStatus == "standard" and T ~= nil and T.statusKey == "standard" and base ~= nil and H.same(T.positive, base.positive),
        "Status colors Standard: good, warning and bad are the base theme's own", H.hexOf(T and T.positive) .. ", want " .. H.hexOf(base and base.positive))
    pcall(pick, v0 or 1)
    H.putOptions()
    H.putLook()
end)
-- (Nov 18 2026, the ledger) the split view's own theme for players 2 to 4 (PlayerTheme.lua): with no second player on
-- this save, player 2's slot is worked with split view switched on for the length of the step (one call, no frame
-- drawn): ZeD.Theme.set gives player 2's table its pick while the shared table stays; then cleared and put back
Q.step(3, function()
    local TH = ZeD.Theme
    if not (TH and TH.set and TH.clear and ZeD.Tfor) then Q.check(false, "ZeD's per-player theme is loaded"); return end
    local p2 = nil
    pcall(function() p2 = getSpecificPlayer(1) end)
    if p2 then Q.skip("split view per-player theme", "a second player is in this game: their own pick is left alone"); return end
    local split0, c0 = ZeD.splitWindows, TH.choice[1]
    local other = (ZeD.currentBase == "light") and "dark" or "light"
    local shared = ZeD.T and ZeD.T.baseKey
    local got, first = nil, nil
    ZeD.splitWindows = true
    pcall(function()
        TH.set(1, other)
        got = ZeD.Tfor(1).baseKey
        first = ZeD.Tfor(0).baseKey
    end)
    pcall(TH.clear, 1)
    TH.choice[1] = c0
    if ZeD._playerT then ZeD._playerT[1] = nil end
    ZeD.splitWindows = split0
    Q.check(got == other and first == shared and ZeD.T ~= nil and ZeD.T.baseKey == shared,
        "split view per-player theme: player 2's pick is in player 2's table only (a stand-in player 2)", tostring(got) .. " / " .. tostring(first) .. ", shared " .. tostring(shared))
end)

-- ===================================================================== 4b. the Character and World windows' own accent
-- (the pair's window box: its Accent sets that window's own; purple on Character, green on World, kept over a close
-- and reopen; then "Same as Accent color"; then each window's own as found)
Q.step(5, function()
    RT.pairOpen()
    S.accC, S.accW = nil, nil
    pcall(function() S.accC = { k = RT.cw()._accentKey } end)
    pcall(function() S.accW = { k = RT.ww()._accentKey } end)
    S.iP, S.iG = nil, nil
    for i, k in ipairs(St.accentKeys or {}) do
        if k == "purple" then S.iP = i end
        if k == "green" then S.iG = i end
    end
    S.pickC = S.iP and H.menuPick(RT.cw(), "UI_ZeD_WinMenu_Accent", S.iP)
    S.pickW = S.iG and H.menuPick(RT.ww(), "UI_ZeD_WinMenu_Accent", S.iG)
end)
Q.step(4, function()
    local cw, ww = RT.cw(), RT.ww()
    Q.check(S.pickC and cw ~= nil and cw._accentKey == "purple" and H.val("charAccent") == S.iP and ZeD._pendingCharAccent == "purple",
        "the Character window's own accent: its window box's pick sets it and saves it", tostring(cw and cw._accentKey) .. ", option " .. tostring(H.val("charAccent")))
    Q.check(S.pickW and ww ~= nil and ww._accentKey == "green" and H.val("worldAccent") == S.iG and ZeD._pendingWorldAccent == "green",
        "the World window's own accent: its window box's pick sets it and saves it", tostring(ww and ww._accentKey) .. ", option " .. tostring(H.val("worldAccent")))
    Q.check(ZeD.currentAccent == S.accent0, "a window's own accent leaves the interface's accent alone", tostring(ZeD.currentAccent))
    RT.pairShut()
end)
Q.step(10, function() RT.pairOpen() end)
Q.waitFor(5, 300, function() return H.bothOpen() end, function(ok)
    local cw, ww = RT.cw(), RT.ww()
    Q.check(ok and cw ~= nil and ww ~= nil and cw._accentKey == "purple" and ww._accentKey == "green", "the windows' own accents are kept over a close and reopen",
        tostring(cw and cw._accentKey) .. " / " .. tostring(ww and ww._accentKey))
    S.pickC = H.menuPick(cw, "UI_ZeD_WinMenu_Accent", #(St.accentKeys or {}) + 1)
end)
Q.step(4, function()
    local cw = RT.cw()
    Q.check(S.pickC and cw ~= nil and cw._accentKey == nil and H.val("charAccent") == #(St.accentKeys or {}) + 1,
        "the Character window's \"Same as Accent color\" follows the interface's accent again", tostring(cw and cw._accentKey) .. ", option " .. tostring(H.val("charAccent")))
    -- put back: each window's own accent as found (the options and the character's copies at the section's end)
    pcall(function() if S.accC then RT.cw()._accentKey = S.accC.k end end)
    pcall(function() if S.accW then RT.ww()._accentKey = S.accW.k end end)
    H.putOptions()
end)

-- ===================================================================== 4c. the look switches
-- See-through 60 (the window box's pick; it works in Dark only, so the base theme option is Dark meanwhile): the
-- windows with their bands draw a second and a half with no fault for safe mode's watchdog and no Lua error (no way to
-- read back the alpha a window drew)
Q.step(5, function()
    S.seeIdx0 = H.val("seeThrough")
    S.baseOpt0 = H.val("baseTheme")
    pcall(function() if S.baseOpt0 ~= 1 then H.opt("baseTheme"):setValue(1) end end)
    S.picked = H.menuPick(H.stub(), "UI_ZeD_Settings_SeeThrough", 5)
    RT.pairOpen()
    pcall(RT.charTab, "equip")
    pcall(RT.worldTab, "craft")
    S.faults = 0
    S.faultWas = Sf.fault
    Sf.fault = function(k, e) S.faults = S.faults + 1; return S.faultWas(k, e) end
    S.errSee = H.errs()
end)
Q.waitMs(1500)
Q.step(1, function()
    if S.faultWas and Sf.fault ~= S.faultWas then Sf.fault = S.faultWas end
    local T = ZeD.T
    Q.check(S.picked and math.abs((ZeD.surfaceAlpha or 0) - 0.6) < 0.001 and T ~= nil and T.baseKey == "dark" and H.val("seeThrough") == 5,
        "See-through 60: the window box's pick draws the windows at 0.6 in Dark and is saved", "surfaceAlpha " .. tostring(ZeD.surfaceAlpha))
    local e1 = H.errs()
    Q.check(S.faults == 0 and (S.errSee == nil or e1 == S.errSee) and not Sf.on(),
        "one see-through layer per window: the windows and their bands draw at 60 with no guarded fault and no Lua error",
        S.faults .. " faults, " .. tostring(S.errSee and e1 and (e1 - S.errSee)) .. " new errors")
    RT.bounds(Q, "the windows at 60 see-through")
    pcall(RT.charTab, "loot")
    pcall(RT.worldTab, "loot")
    pcall(function() H.opt("baseTheme"):setValue(S.baseOpt0) end)
    pcall(St.setSeeThrough, S.seeIdx0)
    Q.check(H.val("seeThrough") == S.seeIdx0 and ZeD.currentBase == S.base0, "See-through and the theme put back", tostring(H.val("seeThrough")) .. ", " .. tostring(ZeD.currentBase))
end)
-- (Nov 20 2026, Cuts C, the visual noise audit's ZeD setup table: Solid while in use is the rule now, the low-health
-- pixel holds solid red, and Item-colored tiles follow Style. The options stay saved and settable, their rows gone.)
-- Solid while in use: always on, whatever the saved option says; the window box's See-through leaf has no such row
Q.step(3, function()
    local o = St.solidInUseOption
    local was = o and o:getValue()
    local both = {}
    for i = 1, 2 do pcall(function() o:setValue(i) end); both[i] = St.solidInUse() end
    if was then pcall(function() o:setValue(was) end) end
    Q.check(both[1] == true and both[2] == true, "Solid while in use: a window in use is always solid, with the saved option Off or On",
        tostring(both[1]) .. ", " .. tostring(both[2]))
    local g = H.menuGroup(H.stub(), "UI_ZeD_Settings_SeeThrough")
    local hit = nil
    for _, c in ipairs((g and g.children) or {}) do
        if tostring(c.name or c.text or ""):find(ZeD.tr("UI_ZeD_Settings_SolidInUse"), 1, true) then hit = c end
    end
    Q.check(g ~= nil and hit == nil, "Solid while in use: the window box's See-through has no row for it", g and (#g.children .. " rows") or "no See-through group")
end)
-- Low-health pixel: solid red, never dark, with the saved option Off or On
Q.step(3, function()
    local o = St.healthBlinkOption
    local was = o and o:getValue()
    local dark = { 0, 0 }
    for i = 1, 2 do
        pcall(function() o:setValue(i) end)
        for ms = 0, 2000, 50 do if not ZeD_Window.pixelLit(true, ms) then dark[i] = dark[i] + 1 end end
    end
    if was then pcall(function() o:setValue(was) end) end
    Q.check(not St.healthBlink() and dark[1] == 0 and dark[2] == 0, "Low-health pixel: it holds lit (solid red) at every moment, with the saved option Off or On",
        dark[1] .. " and " .. dark[2] .. " of 41 moments dark")
    Q.check(o == nil or o:getValue() == was, "Low-health pixel option put back", tostring(o and o:getValue()))
end)
-- Item-colored tiles: on in Full, off in Lite (Style set by value and put back), whatever the saved option says
Q.step(3, function()
    local ls = St.lookStyleOption
    local was = ls and ls:getValue()
    local r = {}
    pcall(function()
        ls:setValue(1); r.full = St.gridTint()
        ls:setValue(2); r.lite = St.gridTint()
    end)
    if was then pcall(function() ls:setValue(was) end) end
    Q.check(r.full == true and r.lite == false, "Item-colored grid tiles: on in Full, off in Lite", "Full " .. tostring(r.full) .. ", Lite " .. tostring(r.lite))
    Q.check(ls == nil or ls:getValue() == was, "Style put back", tostring(ls and ls:getValue()))
    Q.check(ZeD.ItemTints ~= nil and ZeD.ItemTints["Acorn"] == 8806442, "Item-colored grid tiles: the item colors are loaded (Acorn)", tostring(ZeD.ItemTints and ZeD.ItemTints["Acorn"]))
end)
-- the four controller highlights, each through the window box's menu, with the windows drawing a moment each
Q.step(3, function()
    S.focus0 = St.focusStyle()
    S.errFocus = H.errs()
end)
-- (QA, Nov 22: KISS #40, the director's pick: the window box shows Controller highlight only with a pad, so with none
-- joined the four picks are skipped, not failed)
S.padHere = JoypadState and JoypadState.players and JoypadState.players[1] and true or false
for i = 1, #((St and St.focusStyleKeys) or {}) do
    Q.step(2, function() if S.padHere then S.picked = H.menuPick(H.stub(), "UI_ZeD_Settings_FocusStyle", i) end end)
    Q.step(6, function()
        local k = St.focusStyleKeys[i]
        if not S.padHere then Q.skip("Controller highlight " .. k .. ": the window box's pick", "no pad joined: the row shows only with a pad (KISS #40)"); return end
        Q.check(S.picked and St.focusStyle() == k and H.val("focusStyle") == i, "Controller highlight " .. k .. ": the window box's pick is read and saved",
            tostring(St.focusStyle()) .. ", option " .. tostring(H.val("focusStyle")))
    end)
end
Q.step(3, function()
    local e1 = H.errs()
    if S.errFocus and e1 then Q.check(e1 == S.errFocus, "the controller highlights drew with no Lua error", (e1 - S.errFocus) .. " new") end
    pcall(St.setFocusStyle, S.focus0)
    Q.check(St.focusStyle() == S.focus0, "Controller highlight put back", tostring(St.focusStyle()))
end)
-- the forms follow Style at once: each getter answers simple right after Style is Lite (item 2), full at Full (item 1).
-- (Nov 19 2026, QA: beta 21 retired the per-piece switches; every getter reads lookStyle. The dash has no plain
-- form now, so dashSimple() is false in both; Lite's dash is checked in rt_lite. Value only: the option's onChange
-- would also set the additions to Vanilla.)
Q.step(3, function()
    local forms = {
        { "belt", function() return ZeD.Belt and ZeD.Belt.simple and ZeD.Belt.simple() end },
        { "devices", St.devicesSimple }, { "watch", St.watchSimple },
        { "guide", St.guideSimple }, { "mods", St.modsSimple }, { "identity", St.identitySimple },
    }
    local o = St.lookStyleOption
    local bad = {}
    if not o then bad[1] = "lookStyle missing" else
        local v0 = o:getValue()
        for _, f in ipairs(forms) do
            if not f[2] then bad[#bad + 1] = f[1] .. " missing"
            else
                local s2, s1 = nil, nil
                pcall(function() o:setValue(2); s2 = f[2]() end)
                pcall(function() o:setValue(1); s1 = f[2]() end)
                if not (s2 == true and not s1) then bad[#bad + 1] = f[1] .. " " .. tostring(s2) .. "/" .. tostring(s1) end
            end
        end
        local d2, d1 = nil, nil
        pcall(function() o:setValue(2); d2 = St.dashSimple() end)
        pcall(function() o:setValue(1); d1 = St.dashSimple() end)
        if d2 or d1 then bad[#bad + 1] = "dash " .. tostring(d2) .. "/" .. tostring(d1) .. " (the plain dash is retired)" end
        pcall(function() o:setValue(v0) end)
    end
    Q.check(#bad == 0, "Lite or Full forms: each form's getter follows Style at once (belt, devices, watch, guide, mods, identity; the dash has no plain form)",
        (#bad > 0) and table.concat(bad, "; ") or (#forms .. " forms"))
    H.putOptions()
end)
-- (Nov 18 2026, the ledger) UI sounds: at Off ZeD's click plays nothing (ZeD.uiSound gives no sound id), at Full it
-- plays; the Button glyph set: item 3 reads PlayStation, item 1 Auto; each switch as found after
Q.step(3, function()
    local o, g = St.uiSoundsOption, St.glyphOption
    if not (o and ZeD.uiSound) then Q.check(false, "ZeD's settings have the UI sounds option")
    else
        local v0 = o:getValue()
        local off, full = "not asked", nil
        pcall(function() o:setValue(3); off = ZeD.uiSound("UIActivateButton") end)
        pcall(function() o:setValue(1); full = ZeD.uiSound("UIActivateButton") end)
        pcall(function() o:setValue(v0) end)
        Q.check(off == nil and full ~= nil and o:getValue() == v0, "UI sounds: Off plays no click, Full plays it (a sound id)",
            "Off " .. tostring(off) .. ", Full " .. tostring(full))
    end
    if not (g and St.glyphKey) then Q.check(false, "ZeD's settings have the Button glyph option"); return end
    local g0 = g:getValue()
    local k3, k1 = nil, nil
    pcall(function() g:setValue(3); k3 = St.glyphKey() end)
    pcall(function() g:setValue(1); k1 = St.glyphKey() end)
    pcall(function() g:setValue(g0) end)
    Q.check(k3 == "ps" and k1 == "auto" and g:getValue() == g0, "Button glyph set: item 3 reads the PlayStation set, item 1 Auto",
        tostring(k3) .. " / " .. tostring(k1))
end)
-- (Nov 18 2026, the ledger) the test language (ZeD setup, Trouble; shared/ZeD/Tr.lua reads its switch every half
-- second): On, a ZeD phrase reads stretched and in brackets within the half second; Off, plain again; then as found
Q.step(3, function()
    local o = St.testLanguageOption
    S.tlSkip = not (o and ZeD.trPlain)
    if S.tlSkip then Q.check(false, "ZeD's settings have the test language option"); return end
    S.tl0 = o:getValue()
    S.tlKey = "UI_ZeD_Settings_SafeMode"
    S.tlPlain = tostring(ZeD.trPlain(S.tlKey))
    o:setValue(2)
    S.tlT = getTimestampMs()
end)
Q.waitFor(1, 900, function()
    if S.tlSkip then return true end
    local t = ZeD.tr(S.tlKey)
    return (type(t) == "string" and t:sub(1, 1) == "[") or getTimestampMs() - S.tlT > 1500
end, function()
    if S.tlSkip then return end
    local t = ZeD.tr(S.tlKey)
    local ms = getTimestampMs() - S.tlT
    Q.check(type(t) == "string" and t:sub(1, 1) == "[" and #t > #S.tlPlain and ms <= 750, "Test language On: within half a second a ZeD phrase reads stretched, in brackets",
        ms .. " ms, " .. tostring(t and #t) .. " letters, plain " .. #S.tlPlain)
    St.testLanguageOption:setValue(1)
    S.tlT = getTimestampMs()
end)
Q.waitFor(1, 900, function()
    if S.tlSkip then return true end
    return ZeD.tr(S.tlKey) == S.tlPlain or getTimestampMs() - S.tlT > 1500
end, function()
    if S.tlSkip then return end
    local t = ZeD.tr(S.tlKey)
    Q.check(t == S.tlPlain and getTimestampMs() - S.tlT <= 750, "Test language Off: the phrase is plain again", tostring(t))
    St.testLanguageOption:setValue(S.tl0 or 1)
end)

-- ===================================================================== 5. safe mode
function H.vanillaInv() local v = false; pcall(function() local vi = getPlayerInventory(pn); v = vi ~= nil and vi:isVisible() end); return v end
function H.hotbar()
    local orig = Sf._originals and Sf._originals.ISHotbar
    if not orig then return "no original kept" end
    return (ISHotbar.render == orig.render) and "vanilla" or "replaced"
end
function H.moodles() local s = "none"; pcall(function() local l = ZeD.Moodles.getLayer(pn); if l then s = tostring(l:isVisible()) end end); return s end
function H.bothShut()
    local c, w = true, true
    pcall(function() c = ZeD_CharacterWindow.isOpen(pn) end)
    pcall(function() w = ZeD_WorldWindow.isOpen(pn) end)
    return not c and not w
end
function H.note()
    local n = Sf._note
    if n and n.javaObject and n:isVisible() then return n end
    return nil
end
function H.closeNote()
    local n = H.note()
    if not n then return false end
    pcall(function() if n.ok then n:onClick(n.ok) else n:destroy() end end)
    return true
end
function H.state()
    return "on " .. tostring(Sf.on()) .. " | pair shut " .. tostring(H.bothShut()) .. " | game's inventory " .. tostring(H.vanillaInv())
        .. " | hotbar " .. H.hotbar() .. " | moodle layer " .. H.moodles()
end
Q.step(5, function()
    S.safeOpt = St.safeModeOption
    S.safeWas = S.safeOpt:getValue()
    S.invKey = getCore():getKey("Toggle Inventory")
    RT.pairOpen()
end)
-- (Nov 18 2026, the ledger) the inventory key while ZeD runs (ZeD_CharacterWindow._onKeyPressed, the handler on
-- OnKeyPressed): the Character and World windows close together and open together, the game's page stays hidden
Q.step(10, function()
    S.keySkip = Sf.on("windows")
    if S.keySkip then Q.skip("the inventory key works the pair", "safe mode or the windows' own switch gives the key to the game in this game"); return end
    S.keyOpen0 = H.bothOpen()
    pcall(ZeD_CharacterWindow._onKeyPressed, S.invKey)
end)
Q.step(10, function()
    if S.keySkip then return end
    S.keyShut, S.keyVi = H.bothShut(), H.vanillaInv()
    pcall(ZeD_CharacterWindow._onKeyPressed, S.invKey)
end)
Q.waitFor(2, 300, function() return S.keySkip or H.bothOpen() end, function(ok)
    if S.keySkip then return end
    Q.check(S.keyOpen0 and S.keyShut and not S.keyVi and ok and not H.vanillaInv(),
        "the inventory key: the Character and World windows close together and open together, the game's page hidden",
        "open " .. tostring(S.keyOpen0) .. ", shut " .. tostring(S.keyShut) .. ", game's page " .. tostring(S.keyVi) .. ", open again " .. tostring(ok))
    RT.pairOpen()
end)
Q.step(30, function()
    Q.say("safe mode baseline: " .. H.state())
    S.safeSkip = Sf.on()
    if S.safeSkip then Q.skip("safe mode", "safe mode is already on in this game: ZeD is not running to trip"); return end
    Q.check(not H.bothShut() and not H.vanillaInv() and H.hotbar() == "replaced", "safe mode: ZeD runs to start with (its windows, its hotbar)")
    Sf.trip("rt_sys trip", "a test trip")
end)
Q.step(30, function()
    if S.safeSkip then return end
    Q.say("tripped: " .. H.state())
    Q.check(Sf.on() and H.bothShut(), "a trip: ZeD's windows shut")
    Q.check(H.vanillaInv() and H.hotbar() == "vanilla" and H.moodles() ~= "true", "a trip: the game's own inventory page, hotbar and moodles come back")
    Q.check(H.closeNote(), "a trip: the note shows (the game's own dialog) and closes")
end)
Q.step(10, function()
    if S.safeSkip then return end
    S.inv1 = H.vanillaInv()
    pcall(ZeD_CharacterWindow._onKeyPressed, S.invKey)
    S.inv2 = H.vanillaInv()
end)
Q.step(10, function()
    if S.safeSkip then return end
    pcall(ZeD_CharacterWindow._onKeyPressed, S.invKey)
    local inv3 = H.vanillaInv()
    Q.check(S.inv1 and not S.inv2 and inv3 and H.bothShut(), "tripped, the inventory key works the game's own page (hides, shows)",
        tostring(S.inv1) .. " -> " .. tostring(S.inv2) .. " -> " .. tostring(inv3))
    Sf.reset()
end)
Q.step(30, function()
    if S.safeSkip then return end
    Q.say("reset: " .. H.state())
    Q.check(not Sf.on() and H.hotbar() == "replaced" and H.moodles() == "true" and not H.vanillaInv(), "a reset brings ZeD back and hides the game's page")
    Q.check(Sf._state ~= nil and Sf._state.tripped == false and not Sf.on(), "trip recovery by hand: ZeD.Safe.reset() clears the trip and the switch reads Off",
        "tripped " .. tostring(Sf._state and Sf._state.tripped))
    RT.pairOpen()
end)
Q.step(30, function()
    if S.safeSkip then return end
    Q.check(H.bothOpen() and not H.vanillaInv(), "after the reset ZeD's windows open again")
    RT.bounds(Q, "the windows after a safe mode reset")
end)
-- the option, with no forced re-read: the half-second poll picks it up
function H.optionPoll(value, want, name)
    Q.step(5, function()
        if S.safeSkip then return end
        S.safeOpt:setValue(value)
        S.tOpt = getTimestampMs()
    end)
    Q.waitFor(1, 900, function()
        if S.safeSkip then return true end
        return Sf.on() == want or getTimestampMs() - S.tOpt > 1000
    end, function()
        if S.safeSkip then return end
        local ms = getTimestampMs() - S.tOpt
        Q.check(Sf.on() == want and ms <= 1000, name, ms .. " ms")
    end)
end
H.optionPoll(2, true, "the Safe mode option On is picked up by itself within a second")
Q.step(30, function()
    if S.safeSkip then return end
    Q.check(H.bothShut() and H.vanillaInv() and H.hotbar() == "vanilla" and H.note() == nil, "Safe mode On: the game's own pages, no trip note")
    -- Messages keeps nothing while safe mode is on (with the catch switch On meanwhile)
    local MS = ZeD.Messages
    if MS and MS.wouldKeep and St.messagesCatchOption then
        S.catchTmp = St.messagesCatchOption:getValue()
        St.messagesCatchOption:setValue(2)
        Q.check(MS.wouldKeep("ZeD QA test mod") == false, "never caught in safe mode: with safe mode On, Messages keeps no other mod's note")
    end
end)
H.optionPoll(1, false, "the Safe mode option Off is picked up by itself within a second")
Q.step(30, function()
    if S.safeSkip then return end
    Q.check(not Sf.on() and H.hotbar() == "replaced" and not H.vanillaInv(), "Safe mode Off: ZeD back")
    Q.check(Sf._state ~= nil and Sf._state.applied == false, "Safe mode recovery: switched Off, nothing of the game's own is left applied",
        "applied " .. tostring(Sf._state and Sf._state.applied))
    local MS = ZeD.Messages
    if S.catchTmp then
        if MS.popupsFor("ZeD QA test mod") then
            Q.skip("the control: a note kept with safe mode Off", "the test mod's name is on this game's pop-up list")
        else
            Q.check(MS.wouldKeep("ZeD QA test mod") == true, "with safe mode Off the same note would be kept again (the control)")
        end
        St.messagesCatchOption:setValue(S.catchTmp)
        S.catchTmp = nil
    end
    RT.pairOpen()
    S.burstN, S.tBurst = 0, nil
end)
Q.waitFor(5, 300, function() return S.safeSkip or H.bothOpen() end, function(ok)
    if S.safeSkip then return end
    Q.check(ok and not H.vanillaInv(), "Safe mode recovery: the ZeD Character and World windows open again")
end)
-- the watchdog: a burst of five frames (the first with 100 faults, counted once) leaves ZeD on, 2.5 s later still
Q.waitFor(5, 60, function()
    if S.safeSkip then return true end
    if not S.tBurst then
        S.tBurst = getTimestampMs()
        for i = 1, 100 do Sf.fault("rt_sys burst", "burst " .. i) end
    else
        Sf.fault("rt_sys burst", "burst frame " .. S.burstN)
    end
    S.burstN = S.burstN + 1
    return S.burstN >= 5
end, function() end)
Q.waitFor(1, 2000, function()
    if S.safeSkip then return true end
    return Sf.on() or getTimestampMs() - S.tBurst >= 2500
end, function()
    if S.safeSkip then return end
    Q.check(not Sf.on(), "the watchdog: a five-frame burst of faults leaves ZeD on")
    if Sf.on() then H.closeNote(); Sf.reset() end
    S.tStreak, S.streakHits = nil, 0
end)
-- one place failing every frame: no trip before two seconds, a trip by 2.5 s
Q.waitFor(5, 3000, function()
    if S.safeSkip then return true end
    local now = getTimestampMs()
    if not S.tStreak then S.tStreak = now end
    if not Sf.on() then
        Sf.fault("rt_sys streak", "streak " .. S.streakHits)
        S.streakHits = S.streakHits + 1
    end
    if Sf.on() then S.streakMs = getTimestampMs() - S.tStreak; return true end
    return now - S.tStreak > 2500
end, function()
    if S.safeSkip then return end
    local ms = S.streakMs
    Q.check(ms ~= nil and ms >= 1990, "the watchdog: under two seconds of faults ZeD stays on", tostring(ms) .. " ms, " .. S.streakHits .. " frames")
    Q.check(ms ~= nil and ms <= 2500, "the watchdog: two seconds of faults every frame trip it", tostring(ms) .. " ms")
end)
Q.step(30, function()
    if S.safeSkip then return end
    Q.check(H.closeNote(), "the watchdog's note shows and closes")
    Sf.reset()
end)
Q.step(30, function()
    if S.safeSkip then return end
    S.safeOpt:setValue(S.safeWas)
    pcall(Sf.reread)
    -- ZeD keeps the game's pages hidden while it runs; the trip file emptied so the next start shows no note
    pcall(function() local vi = getPlayerInventory(pn); if vi then vi:setVisible(false) end end)
    pcall(function() local vl = getPlayerLoot(pn); if vl then vl:setVisible(false) end end)
    pcall(function() local f = getFileWriter("ZeD_safe_trip.txt", true, false); f:write(""); f:close() end)
    RT.pairOpen()
end)
Q.step(30, function()
    if S.safeSkip then return end
    Q.say("safe mode put back: " .. H.state())
    Q.check(S.safeOpt:getValue() == S.safeWas and not Sf.on() and H.bothOpen() and not H.vanillaInv(), "safe mode put back: the option as it was, ZeD running")
end)
-- (Nov 18 2026, the ledger) the Select wheel's Safe mode row (ZeD_DpadWheels.lua Z.safeMode) asks first: a Yes / No
-- question; No leaves safe mode off and the option as it was
Q.step(5, function()
    if S.safeSkip then return end
    local D = ZeD.DpadWheels
    S.askSkip = not (D and D.Z and D.Z.safeMode)
    if S.askSkip then Q.check(false, "the Select wheel has its Safe mode row (DpadWheels Z.safeMode)"); return end
    S.askModal = nil
    S.newWas = ISModalDialog.new
    ISModalDialog.new = function(self, ...)
        local o = S.newWas(self, ...)
        S.askModal = o
        return o
    end
    pcall(D.Z.safeMode, p, pn)
    ISModalDialog.new = S.newWas
    S.newWas = nil
end)
Q.step(5, function()
    if S.safeSkip or S.askSkip then return end
    local m = S.askModal
    Q.check(m ~= nil and m.yes ~= nil and m.no ~= nil and not Sf.on(), "Safe mode from the Select wheel asks first (Yes and No), and nothing is on yet",
        "question " .. tostring(m ~= nil) .. ", safe mode " .. tostring(Sf.on()))
    if m and m.no then pcall(function() m:onClick(m.no) end) end
end)
Q.step(30, function()
    if S.safeSkip or S.askSkip then return end
    Q.check(not Sf.on() and S.safeOpt:getValue() == S.safeWas, "Safe mode asks first: No leaves safe mode off and the option as it was",
        "safe mode " .. tostring(Sf.on()) .. ", option " .. tostring(S.safeOpt:getValue()))
    pcall(function() local m = S.askModal; if m and m.javaObject and m:isVisible() then m:destroy() end end)
    S.askModal = nil
end)
-- (Nov 18 2026, the ledger) one screen handed back (ZeD setup's Trouble switches, SafeMode.lua pieceOff): the belt's
-- switch On gives the belt alone to the game (safe mode stays off); Off makes it ZeD's again
Q.step(5, function()
    if S.safeSkip then return end
    local o = St.screenOptions and St.screenOptions.belt
    if not o then Q.check(false, "ZeD setup has the belt's screen switch"); return end
    local v0 = o:getValue()
    if v0 == 2 then Q.skip("one screen handed back (the belt)", "the belt is the game's own in this game already (its switch is On)"); return end
    S.beltOpt, S.beltWas = o, v0
    o:setValue(2)
    pcall(Sf.reread)
    local st = Sf._state or {}
    local by = st.by or {}
    Q.check(Sf.on("belt") and not Sf.on() and by.belt == true, "one screen handed back: the belt's switch On gives the belt alone to the game",
        "belt " .. tostring(Sf.on("belt")) .. ", all " .. tostring(Sf.on()) .. ", hook " .. tostring(by.belt))
    o:setValue(v0)
    pcall(Sf.reread)
    Q.check(not Sf.on("belt") and by.belt ~= true, "one screen handed back: the belt's switch Off makes the belt ZeD's again", "hook " .. tostring(by.belt))
end)

-- ===================================================================== 6. step-aside
Q.step(5, function()
    local SA = ZeD.StepAside
    if not SA then Q.check(false, "ZeD's step-aside is loaded"); return end
    local found = {}
    pcall(function() found = SA.detect() or {} end)
    local any = false
    for sc, f in pairs(found) do
        any = true
        local rec = SA.record() or { set = {}, kept = {} }
        local o = St.screenOptions and St.screenOptions[sc]
        local val = o and o:getValue()
        if rec.kept and rec.kept[sc] == f.id then
            Q.check(val ~= 2, "step-aside: " .. sc .. " taken by " .. tostring(f.name) .. " was taken back by the player and stays ZeD's", "switch " .. tostring(val))
        else
            local s = rec.set and rec.set[sc]
            Q.check(s ~= nil and s.id == f.id, "step-aside: " .. sc .. " is handed back to " .. tostring(f.name) .. " (the record)", tostring(s and s.id))
            Q.check(val == 2 and Sf.on(sc), "step-aside: " .. sc .. "'s switch is the game's own and ZeD stays off it", "switch " .. tostring(val))
            local under = SA.underFor(sc)
            Q.check(under ~= nil and string.find(under, tostring(f.name), 1, true) ~= nil, "step-aside: ZeD setup says " .. sc .. " is taken by " .. tostring(f.name), tostring(under))
        end
    end
    if not any then Q.skip("step-aside", "no active mod replaces a ZeD screen in this game") end
    -- the mods ZeD supports (ModSupport) never trigger a hand-back
    local hit = {}
    for sc, f in pairs(found) do if SA.SUPPORTED and SA.SUPPORTED[tostring(f.id)] then hit[#hit + 1] = sc .. ":" .. tostring(f.id) end end
    Q.check(SA.SUPPORTED ~= nil and SA.SUPPORTED.AutoHideHotbar == true and #hit == 0, "step-aside: a supported mod (AutoHideHotbar and the rest) is never detected",
        (#hit > 0) and table.concat(hit, " ") or "none detected")
end)

-- ===================================================================== 7. Messages keeps another mod's note
Q.step(5, function()
    local MS, MW = ZeD.Messages, ZeD.MessagesWindow
    if not (MS and MW) then Q.check(false, "ZeD's Messages is loaded"); S.msgSkip = true; return end
    S.SRC = "ZeD QA test mod"
    S.calls = 0
    S.catchWas = St.messagesCatchOption and St.messagesCatchOption:getValue()
    S.toastWas = St.messagesToastOption and St.messagesToastOption:getValue()
    S.toasts0 = {}
    for _, t in ipairs(MS.toasts or {}) do S.toasts0[#S.toasts0 + 1] = t end
    pcall(function() St.messagesCatchOption:setValue(2); St.messagesToastOption:setValue(2) end)
    S.popWas = MS.popupsFor(S.SRC)
    if S.popWas then MS.setPopups(S.SRC, false) end
    MS.qaSource = S.SRC
    S.target = {}
    S.note = ISModalDialog:new(0, 0, 300, 150, "QA: a note from another mod.", false, S.target, function() S.calls = S.calls + 1 end, pn)
    S.note:initialise()
    S.note:addToUIManager()
    MS.qaSource = nil
end)
Q.step(20, function()
    if S.msgSkip then return end
    local MS = ZeD.Messages
    local shown = false
    pcall(function() shown = S.note.javaObject ~= nil and S.note:isReallyVisible() end)
    Q.check(not shown and S.note._zedCaught == true, "another mod's note is kept in Messages, not shown over the game")
    local s = MS.sources[S.SRC]
    Q.check(s ~= nil and #s.items == 1 and not s.items[1].read, "Messages keeps the note, new, under the mod's name", tostring(s and #s.items))
    S.msgWin = ZeD.MessagesWindow.open(pn, S.SRC)
end)
Q.step(20, function()
    if S.msgSkip then return end
    local win = S.msgWin
    Q.check(win ~= nil and win:isReallyVisible() and win.sel == S.SRC, "the Messages window opens on the mod")
    local g = win and win._g
    Q.check(g ~= nil and #g.cards == 1 and #g.btns == 1, "the window shows the note's card with its OK", tostring(g and #g.cards))
    RT.bounds(Q, "the Messages window")
    if g and g.btns[1] then win:pressCard(g.btns[1]) end
end)
Q.step(10, function()
    if S.msgSkip then return end
    Q.check(S.calls == 1, "OK in Messages runs the mod's own callback once", S.calls .. " calls")
end)
Q.step(5, function()
    if S.msgSkip then return end
    local MS = ZeD.Messages
    MS.clear(S.SRC)
    pcall(function() S.msgWin:close() end)
    MS.toasts = S.toasts0
    if S.popWas then MS.setPopups(S.SRC, true) end
    pcall(function()
        if S.catchWas then St.messagesCatchOption:setValue(S.catchWas) end
        if S.toastWas then St.messagesToastOption:setValue(S.toastWas) end
    end)
    Q.check(MS.sources[S.SRC] == nil, "put back: the test mod's messages are cleared")
end)
-- the balloon: with Balloons On a new message shows one, gone after six seconds; Off, none
Q.step(5, function()
    local MS = ZeD.Messages
    if S.msgSkip or not (MS and MS.notice and St.messagesToastOption) then S.toastSkip = true; return end
    S.HEAD = "ZeD QA balloon"
    S.toasts1 = {}
    for _, t in ipairs(MS.toasts or {}) do S.toasts1[#S.toasts1 + 1] = t end
    S.toastOpt0 = St.messagesToastOption:getValue()
    St.messagesToastOption:setValue(2)
    MS.notice(S.HEAD, "QA: a message with its balloon.")
    S.tToast = getTimestampMs()
    Q.check(H.toastsOf(S.HEAD) == 1, "Messages, balloons On: a new message shows its balloon", H.toastsOf(S.HEAD) .. " balloons")
end)
Q.waitFor(5, 3000, function()
    if S.toastSkip then return true end
    return H.toastsOf(S.HEAD) == 0 or getTimestampMs() - S.tToast > 7500
end, function()
    if S.toastSkip then return end
    local MS = ZeD.Messages
    local ms = getTimestampMs() - S.tToast
    Q.check(H.toastsOf(S.HEAD) == 0 and ms >= 5900 and ms <= 7500, "Messages: the balloon goes after six seconds", ms .. " ms")
    St.messagesToastOption:setValue(1)
    MS.notice(S.HEAD, "QA: a second message, balloons Off.")
    Q.check(H.toastsOf(S.HEAD) == 0, "Messages, balloons Off: a new message shows no balloon", H.toastsOf(S.HEAD) .. " balloons")
    MS.clear(S.HEAD)
    MS.toasts = S.toasts1
    St.messagesToastOption:setValue(S.toastOpt0)
    Q.check(MS.sources[S.HEAD] == nil and St.messagesToastOption:getValue() == S.toastOpt0, "put back: the balloon test's messages and the switch")
end)
-- Bug report: every caught error onto the clipboard, the count returned; the clipboard put back as it was (a test
-- that cannot read it back leaves it alone), the "copied" note closed
Q.step(5, function()
    local MS = ZeD.Messages
    if not (MS and MS.copyBugReport and MS.reportAll) then Q.check(false, "ZeD's Messages has the Bug report"); return end
    S.clip0 = nil
    pcall(function() S.clip0 = Clipboard.getClipboard() end)
    if S.clip0 == nil then Q.skip("Bug report to the clipboard", "the clipboard cannot be read back here, so the test leaves it alone"); return end
    local want = nil
    pcall(function() local _, n = MS.reportAll(); want = n end)
    local src0 = {}
    for name in pairs(MS.sources or {}) do src0[name] = true end
    S.newWas = ISModalDialog.new
    ISModalDialog.new = function(self, ...)
        local o = S.newWas(self, ...)
        S.bugModal = o
        return o
    end
    local okB, n = pcall(MS.copyBugReport, pn)
    ISModalDialog.new = S.newWas
    S.newWas = nil
    local got = nil
    pcall(function() got = Clipboard.getClipboard() end)
    pcall(function() Clipboard.setClipboard(S.clip0) end)
    local back, orig = nil, S.clip0
    pcall(function() back = Clipboard.getClipboard() end)
    S.clip0 = nil
    pcall(function() if S.bugModal then S.bugModal:destroy() end end)
    S.bugModal = nil
    -- (the note is ZeD's own; should Messages have kept it under the test's name, that line goes too)
    local fresh = {}
    for name in pairs(MS.sources or {}) do if not src0[name] then fresh[#fresh + 1] = name end end
    for _, name in ipairs(fresh) do pcall(MS.clear, name) end
    Q.check(okB and n ~= nil and n == want, "Bug report: the count it returns is the caught errors'", tostring(n) .. ", want " .. tostring(want))
    Q.check(type(got) == "string" and string.sub(got, 1, 8) == "ZeD-GUI ", "Bug report: the clipboard holds the report (it starts \"ZeD-GUI \")",
        type(got) == "string" and string.sub(got, 1, 40) or tostring(got))
    Q.check(back ~= nil and back == orig, "put back: the clipboard as it was", tostring(back and #back) .. " characters, " .. tostring(orig and #orig) .. " before")
end)
-- (Nov 18 2026, the ledger) the Messages window's foot band, each button through ZeD_MessagesWindow:pressFoot (what a
-- click on it, or A on the band, runs): Pop-ups on keeps the mod in ZeD_messages.txt and off again; Mark all read;
-- Delete asks first, Yes deletes. Every message's read mark, the file and the balloon switch put back.
function H.footBtn(win, id)
    local g = win and win._g
    for _, b in ipairs((g and g.foot) or {}) do if b.id == id then return b end end
    return nil
end
function H.footBack()
    local MS = ZeD.Messages
    if not MS then return end
    if S.FOOT and MS.sources and MS.sources[S.FOOT] then pcall(MS.clear, S.FOOT) end
    if S.FOOT2 and MS.sources and MS.sources[S.FOOT2] then pcall(MS.clear, S.FOOT2) end
    S.FOOT2 = nil
    for _, e in ipairs(S.readSnap or {}) do e.it.read = e.read end
    S.readSnap = nil
    if S.popFile0 then H.writeLines("ZeD_messages.txt", S.popFile0); MS.popups = nil end
    S.popFile0 = nil
    if S.footToast0 then pcall(function() St.messagesToastOption:setValue(S.footToast0) end) end
    S.footToast0 = nil
    pcall(function() if S.footWin then S.footWin:close() end end)
    S.footWin = nil
end
Q.step(5, function()
    local MS, MW = ZeD.Messages, ZeD.MessagesWindow
    S.footSkip = S.msgSkip or not (MS and MW and MS.notice and St.messagesToastOption)
    if S.footSkip then Q.check(false, "ZeD's Messages and its window are loaded for the foot band"); return end
    S.FOOT = "ZeD QA foot band"
    S.readSnap = {}
    for _, s in pairs(MS.sources or {}) do
        for _, it in ipairs(s.items or {}) do S.readSnap[#S.readSnap + 1] = { it = it, read = it.read } end
    end
    S.popFile0 = H.readLines("ZeD_messages.txt") or {}
    S.footToast0 = St.messagesToastOption:getValue()
    St.messagesToastOption:setValue(1)
    MS.notice(S.FOOT, "QA: a message for the foot band.")
    S.footWin = MW.open(pn, S.FOOT)
end)
Q.step(20, function()
    if S.footSkip then return end
    local MS, win = ZeD.Messages, S.footWin
    local bP, bA, bC = H.footBtn(win, "popups"), H.footBtn(win, "allread"), H.footBtn(win, "clear")
    if not (win and bP and bA and bC) then
        S.footSkip = true
        Q.check(false, "the Messages window's foot band has Pop-ups, Delete and Mark all read", tostring(bP ~= nil) .. " " .. tostring(bC ~= nil) .. " " .. tostring(bA ~= nil))
        H.footBack()
        return
    end
    RT.bounds(Q, "the Messages window with its foot band")
    win:pressFoot(bP)
    local on, inFile = MS.popupsFor(S.FOOT), false
    for _, l in ipairs(H.readLines("ZeD_messages.txt") or {}) do if l == "popup=" .. S.FOOT then inFile = true end end
    win:pressFoot(bP)
    Q.check(on and inFile and not MS.popupsFor(S.FOOT), "Messages foot band: Pop-ups on saves the mod in ZeD_messages.txt, pressed again it is off",
        "on " .. tostring(on) .. ", in the file " .. tostring(inFile) .. ", after " .. tostring(MS.popupsFor(S.FOOT)))
    -- (Nov 18 2026, run r7: "0 -> 0". The window opened on S.FOOT, and choosing a source marks it read, so nothing
    -- was unread to start with. A second mod's note, not the one on show, stays unread for Mark all read to clear.)
    S.FOOT2 = "ZeD QA foot band, unread"
    pcall(MS.add, S.FOOT2, "mods", { k = "notice", text = "QA: an unread message for Mark all read." })
    -- (the check below asks n0 > 0 first: at least this note is unread)
    local n0 = MS.unread()
    win:pressFoot(bA)
    local n1 = MS.unread()
    Q.check(n0 > 0 and n1 == 0, "Messages foot band: Mark all read leaves nothing unread", n0 .. " -> " .. n1)
    win:pressFoot(bC)
    Q.check(win.asking == true and MS.sources[S.FOOT] ~= nil, "Messages foot band: Delete asks first and deletes nothing yet", "asking " .. tostring(win.asking))
end)
Q.step(5, function()
    if S.footSkip then return end
    local MS, win = ZeD.Messages, S.footWin
    local bY = H.footBtn(win, "askyes")
    if bY then win:pressFoot(bY) end
    Q.check(bY ~= nil and MS.sources[S.FOOT] == nil, "Messages foot band: Yes to the question deletes the mod's messages", "Yes button " .. tostring(bY ~= nil))
end)
Q.step(3, function()
    if S.footSkip then return end
    local snap, file0, toast0 = S.readSnap or {}, S.popFile0 or {}, S.footToast0
    H.footBack()
    local bad = 0
    for _, e in ipairs(snap) do if e.it.read ~= e.read then bad = bad + 1 end end
    local now = H.readLines("ZeD_messages.txt") or {}
    Q.check(bad == 0 and ZeD.Messages.sources[S.FOOT] == nil and table.concat(now, "\n") == table.concat(file0, "\n") and St.messagesToastOption:getValue() == toast0,
        "put back: every message's read mark, ZeD_messages.txt and the balloon switch", bad .. " marks off, " .. #now .. " lines, " .. #file0 .. " before")
end)

-- ===================================================================== 8. the soak: two minutes of play
local SOAK_TABS = {
    { c = "loot", w = "loot" }, { c = "equip", w = "craft" }, { c = "health", w = "build" }, { c = "skills", w = "maps" },
    { c = "journal", w = "forage" }, { c = "thermal", w = "loot" },
}
Q.step(10, function()
    RT.pairOpen()
    if getGameSpeed() <= 0 then pcall(setGameSpeed, 1) end
    S.soakErr0 = H.errs()
    S.soakMem0 = H.mem()
    S.soakT0 = getTimestampMs()
    S.soakI = 0
    Q.say(string.format("soak start: %s KB, %s Lua errors so far", tostring(S.soakMem0), tostring(S.soakErr0)))
end)
-- the tabs turn every ten seconds while the game runs
Q.waitFor(5, math.floor(SOAK_MS / 3) + 3000, function()
    local el = getTimestampMs() - S.soakT0
    local want = math.floor(el / 10000)
    if want > S.soakI then
        S.soakI = want
        local t = SOAK_TABS[(want - math.floor(want / #SOAK_TABS) * #SOAK_TABS) + 1]
        RT.pairOpen()
        pcall(RT.charTab, t.c)
        pcall(RT.worldTab, t.w)
    end
    return el >= SOAK_MS
end, function(ok)
    Q.check(ok, "the soak ran its two minutes", math.floor((getTimestampMs() - S.soakT0) / 1000) .. " s")
    pcall(RT.charTab, "loot")
    pcall(RT.worldTab, "loot")
    local e1 = H.errs()
    if S.soakErr0 and e1 then
        Q.check(e1 == S.soakErr0, "the soak: no Lua error in two minutes with the windows open", (e1 - S.soakErr0) .. " new")
    else
        Q.skip("the soak's error count", "the game's Lua error count cannot be read here")
    end
    local m1 = H.mem()
    if S.soakMem0 and m1 then
        Q.check(m1 - S.soakMem0 <= SOAK_KB, string.format("the soak: Lua memory grows by no more than %d KB", SOAK_KB),
            string.format("%d KB -> %d KB (%d KB)", math.floor(S.soakMem0), math.floor(m1), math.floor(m1 - S.soakMem0)))
    else
        Q.skip("the soak's memory", "collectgarbage(\"count\") is not available")
    end
    RT.bounds(Q, "the windows after the soak")
end)

-- ===================================================================== 9. translation
Q.step(5, function()
    S.trOn = false
    -- ZeD's English file: every key in it has text in the game (the file loaded, each key whole)
    local lines = {}
    pcall(function()
        local r = getModFileReader("ZeD_UI", "media/lua/shared/Translate/EN/UI.json", false)
        if not r then return end
        local l = r:readLine()
        while l do lines[#lines + 1] = l; l = r:readLine() end
        r:close()
    end)
    if #lines == 0 then
        Q.skip("UI.json's keys", "ZeD's Translate/EN/UI.json could not be read in game")
    else
        local n, bad = 0, {}
        for _, l in ipairs(lines) do
            local k = l:match('^%s*"(UI_ZeD_[%w_]+)"%s*:')
            if k then
                n = n + 1
                local t = getTextOrNull(k, "%1", "%2", "%3", "%4")
                if t == nil or t == "" then bad[#bad + 1] = k end
            end
        end
        Q.check(n > 0 and #bad == 0, "every key in ZeD's English UI.json has text in the game",
            n .. " keys" .. ((#bad > 0) and (", none for: " .. table.concat(bad, " ", 1, math.min(#bad, 12))) or ""))
    end
end)
Q.step(3, function()
    -- every key ZeD asked for while this script ran
    local defaults = ZeD._trDefaults or {}
    local mine, game, badMine, badGame = 0, 0, {}, {}
    for k in pairs(S.keys) do
        local fam = k:match("^(%a+)_")
        local shaped = fam ~= nil and k:find(" ", 1, true) == nil and k:match("^[%w_]+$") ~= nil
        local isMine = k:sub(1, 7) == "UI_ZeD_"
        local isGame = shaped and not isMine and (fam == "UI" or fam == "IGUI" or fam == "ContextMenu" or fam == "Tooltip" or fam == "Sandbox")
        if isMine or isGame then
            local t = getTextOrNull(k, "%1", "%2", "%3", "%4")
            local has = (t ~= nil and t ~= "") or defaults[k] ~= nil
            if isMine then
                mine = mine + 1
                if not has then badMine[#badMine + 1] = k end
            else
                game = game + 1
                if not has then badGame[#badGame + 1] = k end
            end
        end
    end
    Q.check(mine > 0 and #badMine == 0, "every ZeD key read while the script ran has text",
        mine .. " keys" .. ((#badMine > 0) and (", none for: " .. table.concat(badMine, " ", 1, math.min(#badMine, 12))) or ""))
    Q.check(#badGame == 0, "every game key ZeD borrowed while the script ran has text",
        game .. " keys" .. ((#badGame > 0) and (", none for: " .. table.concat(badGame, " ", 1, math.min(#badGame, 12))) or ""))
end)

-- ===================================================================== 9b. data the screens read
Q.step(3, function()
    -- the in-game sandbox window's WHEN and RISK tags: every tag one the window knows; a "fix" row is locked
    local N = ZeD.SandboxNotes
    if not (N and N.when and N.WHEN) then Q.check(false, "ZeD's sandbox notes are loaded"); return end
    local okW = { now = true, new = true, chr = true, load = true, fix = true }
    local badW, badR = {}, {}
    for k, v in pairs(N.WHEN) do if not okW[v] then badW[#badW + 1] = tostring(k) end end
    for k, v in pairs(N.RISK or {}) do if v ~= "care" and v ~= "undo" then badR[#badR + 1] = tostring(k) end end
    Q.check(okW[N.when("DayLength")] and N.when("StartMonth") == "fix" and N.risk("ErosionDays") == "undo" and #badW == 0 and #badR == 0,
        "sandbox tags: each setting's WHEN and RISK is one the window knows (DayLength " .. tostring(N.when("DayLength")) .. ")",
        table.concat(badW, " ") .. " | " .. table.concat(badR, " "))
    local d1, d2 = nil, nil
    pcall(function() d1 = ZeD_MMSandboxIG.rowDisabled({ ctls = {} }, { name = "StartMonth" }) end)
    pcall(function() d2 = ZeD_MMSandboxIG.rowDisabled({ ctls = {} }, { name = "DayLength" }) end)
    Q.check(d1 == true and d2 == false, "sandbox tags: a \"fix\" setting's row is locked, a \"now\" one is not", tostring(d1) .. " / " .. tostring(d2))
end)
Q.step(3, function()
    -- capitals for every language: the German sharp s stays one letter; an accented letter takes its capital
    local ss = string.char(223)
    local u1 = ZeD.upper("stra" .. ss .. "e")
    local u2 = ZeD.upper(string.char(233))
    Q.check(u1 == "STRA" .. ss .. "E" and u2 == string.char(201), "capitals: the sharp s stays one letter and an accented letter takes its capital",
        tostring(u1 and #u1) .. " letters")
    -- the pixel faces' extra letters (PixelFontsExt.lua merged into PixelFonts.lua's faces): signs, accents, Cyrillic
    local PF = ZeD.PixelFonts or {}
    local f35, f57, f57t = PF["35"], PF["57"], PF["57t"]
    Q.check(f35 ~= nil and f35.A ~= nil and f35[string.char(33)] ~= nil and f57 ~= nil and f57[string.char(201)] ~= nil
        and f57[string.char(1040)] ~= nil and f57t ~= nil and rawget(f57t, string.char(201)) ~= nil,
        "pixel fonts: the 3x5 and 5x7 faces have their signs, accented capitals and Cyrillic (the extra file merged)")
end)
-- (Nov 18 2026, the ledger) the pause window's Sandbox options line (ZeD_SandboxInGame.lua MM.sandboxIGShown, what
-- the pause list asks): shown with its ZeD setup switch On in single player, not Off; the switch as found after
Q.step(3, function()
    local o = St.sandboxInGameOption
    if not (o and MM.sandboxIGShown) then Q.check(false, "ZeD's settings have the Sandbox options in game switch"); return end
    if isClient() then Q.skip("the Sandbox options line", "single player only, and this is a server game"); return end
    local v0 = o:getValue()
    local on, off = nil, nil
    pcall(function() o:setValue(2); on = MM.sandboxIGShown() end)
    pcall(function() o:setValue(1); off = MM.sandboxIGShown() end)
    pcall(function() o:setValue(v0) end)
    Q.check(on == true and off == false and o:getValue() == v0, "Sandbox options line on the pause window: shown with its switch On, gone Off",
        tostring(on) .. " / " .. tostring(off))
end)
-- (Nov 18 2026, the ledger) read marks on a skill book (ReadMarks.lua R.state, what the rows and cells draw): with the
-- switch On the mark is unread, part read or read as the character's own record of pages says (set to none, half,
-- all); Off, no mark. The record, the switch and the book put back (the kit takes the book).
Q.step(3, function()
    local R, o = ZeD.ReadMarks, H.opt("readMarks")
    if not (R and R.state and R.clear and o) then Q.check(false, "ZeD's read marks are loaded"); return end
    local book = RT.give("Base.BookCarpentry1")
    if not book then Q.skip("read marks on a skill book", "no Base.BookCarpentry1 in this game"); return end
    local ft, pages, done0, lvl, hi = book:getFullType(), 0, 0, 0, 0
    pcall(function() pages = book:getNumberOfPages() or 0 end)
    pcall(function() done0 = p:getAlreadyReadPages(ft) or 0 end)
    pcall(function() hi = book:getMaxLevelTrained() or 0 end)
    pcall(function()
        local sb = SkillBook and SkillBook[book:getSkillTrained()]
        if sb and sb.perk then lvl = p:getPerkLevel(sb.perk) end
    end)
    local v0 = o:getValue()
    o:setValue(2)
    local bad, seen = {}, {}
    for _, d in ipairs({ 0, math.floor(pages / 2), pages }) do
        pcall(function() p:setAlreadyReadPages(ft, d) end)
        local now = 0
        pcall(function() now = p:getAlreadyReadPages(ft) or 0 end)
        local want = "u"
        if hi < lvl + 1 or (pages > 0 and now >= pages) then want = "r" elseif now > 0 then want = "p" end
        R.clear()
        local s = R.state(p, book)
        local st = s and s.st
        seen[#seen + 1] = now .. ":" .. tostring(st)
        if st ~= want then bad[#bad + 1] = now .. " pages " .. tostring(st) .. ", want " .. want end
    end
    pcall(function() p:setAlreadyReadPages(ft, done0) end)
    o:setValue(1)
    R.clear()
    local offMark = R.state(p, book)
    o:setValue(v0)
    R.clear()
    local back = -1
    pcall(function() back = p:getAlreadyReadPages(ft) or 0 end)
    Q.check(pages > 0 and #bad == 0 and offMark == nil, "Read marks: a skill book's mark follows the pages read (unread, part, read), none with the switch Off",
        table.concat(seen, " ") .. ((#bad > 0) and (" | " .. table.concat(bad, "; ")) or ""))
    Q.check(back == done0 and o:getValue() == v0, "put back: the character's pages read and the read marks switch", back .. " pages, " .. done0 .. " before")
end)
-- (Nov 18 2026, the ledger) chord setup (ZeD_QuickChords.lua, what ZeD setup's Chords rows run): RB+L3 set to a path
-- reads back, is saved (read again from ZeD_chords.txt) and is off its default; reset, it is its default again; then
-- the chord and the file exactly as found
Q.step(3, function()
    local QC = ZeD.QuickChords
    if not (QC and QC.set and QC.get and QC.reset and QC.isDefault and QC.reload and QC.DEFAULTS) then Q.check(false, "ZeD's quick chords are loaded"); return end
    local c = "RB+L3"
    local file0 = H.readLines("ZeD_chords.txt")
    local def0 = QC.isDefault(c)
    local path0 = QC.get(c)
    QC.set(c, "zedqa:1", { "ZeD QA" })
    local p1, d1 = QC.get(c), QC.isDefault(c)
    QC.reload()
    local p2 = QC.get(c)
    QC.reset(c)
    local d3, p3 = QC.isDefault(c), QC.get(c)
    local dflt = QC.DEFAULTS[c] and QC.DEFAULTS[c][1]
    Q.check(p1 == "zedqa:1" and not d1 and p2 == "zedqa:1", "Chord setup: a chord given a path reads it back, saved, off its default",
        tostring(p1) .. ", saved " .. tostring(p2) .. ", default " .. tostring(d1))
    Q.check(d3 and p3 == dflt, "Chord setup: a reset chord is its default again", tostring(p3) .. ", want " .. tostring(dflt))
    H.writeLines("ZeD_chords.txt", file0 or {})
    QC.reload()
    local now = H.readLines("ZeD_chords.txt") or {}
    Q.check(QC.isDefault(c) == def0 and QC.get(c) == path0 and table.concat(now, "\n") == table.concat(file0 or {}, "\n"),
        "put back: the chord and ZeD_chords.txt as found", tostring(QC.get(c)) .. ", was " .. tostring(path0))
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.trOn = false
    if ZeD.tr ~= S.trWas then ZeD.tr = S.trWas end
    -- (a run cut short: what a section had swapped is its own again)
    if S.faultWas and Sf.fault ~= S.faultWas then Sf.fault = S.faultWas end
    if S.qcReset and ZeD.QuickChords then ZeD.QuickChords.reset = S.qcReset end
    if S.newWas then ISModalDialog.new = S.newWas end
    if S.clip0 then pcall(function() Clipboard.setClipboard(S.clip0) end) end
    pcall(function() if S.accC then RT.cw()._accentKey = S.accC.k end end)
    pcall(function() if S.accW then RT.ww()._accentKey = S.accW.k end end)
    if S.o2 and MM.pauseView == "options" and MM.pauseOpts and MM.pauseOpts:isVisible() then pcall(function() MM.pauseOpts:discardStay() end) end
    -- the settings this script touched, each as it was (a run cut short jumps here)
    pcall(function() if S.abWas and St.lookStyleOption:getValue() ~= S.abWas then St.lookStyleOption:setValue(S.abWas) end end)
    if S.ini0 and not S.iniBack then H.writeIni(S.ini0) end
    pcall(function()
        if S.scaleWas and S.scaleOpt:getValue() ~= S.scaleWas then S.scaleOpt:setValue(S.scaleWas); St.applyScale(S.scaleWas) end
    end)
    pcall(function()
        if S.base0 and (ZeD.currentBase ~= S.base0 or ZeD.currentAccent ~= S.accent0 or ZeD.currentSize ~= S.size0) then
            ZeD.applyTheme(S.base0, S.accent0, S.size0)
        end
    end)
    pcall(function()
        if S.safeWas and S.safeOpt:getValue() ~= S.safeWas then S.safeOpt:setValue(S.safeWas); Sf.reread() end
        if Sf.on() and S.safeWas ~= 2 then H.closeNote(); Sf.reset() end
    end)
    pcall(function()
        local MS = ZeD.Messages
        MS.qaSource = nil
        if S.SRC and MS.sources[S.SRC] then MS.clear(S.SRC) end
        if S.catchWas then St.messagesCatchOption:setValue(S.catchWas) end
        if S.toastWas then St.messagesToastOption:setValue(S.toastWas) end
        if S.HEAD and MS.sources[S.HEAD] then MS.clear(S.HEAD) end
        if S.catchTmp then St.messagesCatchOption:setValue(S.catchTmp) end
    end)
    -- every ZeD option's value in memory as found, the character's copies, the look, and the file line for line
    pcall(H.putOptions)
    -- (the sections added Nov 18 2026: the belt's own switch read again, the foot band's put-back, the test language)
    pcall(function() if S.beltOpt then Sf.reread() end end)
    pcall(H.footBack)
    if S.tl0 then pcall(function() St.testLanguageOption:setValue(S.tl0) end) end
    pcall(function() if S.root0 and math.abs(Sc.root() - S.root0) > 0.001 then St.applyScale(St.uiScaleOption:getValue()) end end)
    pcall(H.putLook)
    if S.ini0 then H.writeIni(S.ini0) end
    if (S.menuWas == false or S.menuWas2 == false or S.wsMenuWas == false) and H.menuUp() then H.toggleMenu() end
    if getGameSpeed() <= 0 then pcall(setGameSpeed, 1) end
end)
Q.waitFor(10, 900, function()
    local T = ZeD.T
    return Sc._reopenAt == nil and T ~= nil and math.abs((T.root or 0) - Sc.root()) < 0.001
end, function()
    if ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, S.snap, "rt_sys") end
    if S.winsWere == false then RT.pairShut() elseif S.winsWere then RT.pairOpen() end
    Q.check(ZeD.tr == S.trWas, "put back: ZeD.tr is ZeD's own again")
    Q.check((not S.abWas or St.lookStyleOption:getValue() == S.abWas) and (not S.scaleWas or S.scaleOpt:getValue() == S.scaleWas)
        and (not S.safeWas or S.safeOpt:getValue() == S.safeWas) and (not S.base0 or ZeD.currentBase == S.base0),
        "put back: every setting this script changed is as it was")
    local zo, off = H.opts(), {}
    for id, v in pairs(S.opt0 or {}) do
        local o = zo and zo.dict and zo.dict[id]
        if o and o.selected ~= v then off[#off + 1] = id end
    end
    Q.check(#off == 0 and ZeD.currentAccent == S.accent0 and ZeD.currentSize == S.size0 and ZeD.currentStatus == (S.look0 and S.look0.status)
        and ZeD.surfaceAlpha == (S.look0 and S.look0.a),
        "put back: every ZeD option's value, the accent, the text size and the see-through as found", table.concat(off, " "))
    local now = H.readIni()
    Q.check(S.ini0 ~= nil and now ~= nil and table.concat(now, "\n") == table.concat(S.ini0, "\n"), "put back: ModOptions.ini is as found, line for line",
        tostring(now and #now) .. " lines, " .. tostring(S.ini0 and #S.ini0) .. " before")
end)
Q.start()
