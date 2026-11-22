-- ZeDUI/tools/qa/vx10_defaults.lua  (Nov 21 2026, QA; tag vx10_def): the in-game proof of Build's fix for B10-1 of
-- QA batch 10 (ZeDUI/qa/audits/2026-11-21_beast_batch10.md; Build's fix: commit 9251ebdf6). Built on rt_kit.lua (the
-- global RT); run after zedqa_prelude.lua and rt_kit.lua. grep "ZEDQA vx10_def". No pictures.
--
-- B10-1  Reset to defaults in ZeD setup skipped Style, Map and Restock. Settings.lua noted no default (zedDefault) for
--        lookStyle, mapLight and restock, so in Lite with everything else on its default the button sat gray from the
--        start and Defaults could never take a Lite player back to Full; the Style row's help band had no help line
--        and no "Default: Full".
-- The scene, in memory only: every ZeD setting's stored value put on the item it starts on (its zedDefault; an option
-- with none takes the item its mod declared, ZeD.ModOptionsOwners.default) and Style stored Lite, set as a value the
-- way bxr_lite.lua sets it (not picked, so the extras stay on their own defaults, the Vanilla preset); the look then
-- applied from those values as a game start applies it (ZeD.Settings.reapplyFromOptions). Both windows are shut
-- first (the UI scale's default can differ from the run's, and a scale change shuts open windows), and the game's save
-- of ModOptions.ini is held from the staging until every value is back as found: a stand-in counts the asks and
-- nothing is written. Then the pause menu, ZeD's Options, the ZeD setup page, the pointer the game reads held on the
-- window's title bar (no row lit by chance).
-- (QA review, Nov 21 2026) A screen switch a mod holds (ZeD_StepAside.lua handed that screen to the mod) is left as
-- found: moved in memory, StepAside's look once a second (paused too) would take it for the player taking the screen
-- back and write its record file, Zomboid/Lua/ZeD_step_aside.txt. One that is on keeps the button live on any code,
-- so check "live" is then a SKIP with the reason, as for an add-on's row off its own default.
-- The checks, in the order they run:
--   live      before the press, Reset to defaults (the bottom row, by Back) is live. Old code: gray, since nothing it
--             reached was off its default (Style had no default to be off).
--   help      the pointer held on the Style row: the help band shows Style's help line (UI_ZeD_Settings_LookStyleTip)
--             and, in its right column, "Default: Full". Read from what the Options window draws that frame (its
--             drawText calls, by their place in the band), not from the row's fields. Old code: the band was empty.
--   press     Reset to defaults pressed through its button (the call a click makes; on a gray button the call the
--             button would make, so the old code's reach still shows). Then: the Style row reads Full, a change
--             waiting for Apply with its changed mark, the stored Style still Lite; the button grays; every one of
--             ZeD's own drop-downs and switches on the page has a default and sits on it (an add-on's may have none
--             by design, ZeD_MainMenuOptionGroups.lua addonRows); and ZeD's settings with no row on the page (Map
--             always, Restock while Lite leaves the extras out) each have a default and sit on it. Old code: Style
--             still Lite with no changed mark; the Style row with no default; Map and Restock with none.
--   discard   Discard changes in the footer, then the band's Discard changes: every control back on its stored pick
--             (Style Lite again, no changed mark, nothing waiting) and nothing applied (every stored value still the
--             staged one, Style still Lite, no save asked, ModOptions.ini line for line as found). This passes on the
--             old code too: it guards the fix's new reach into Style.
-- Put back (also when a step throws or the time runs out): Options left on the page it had and the pause menu shut as
-- found; every ZeD setting's stored value as found and the look applied again from them, then the look, the window
-- accents and the character's copies exactly as found; the game's own pointer, save of ModOptions.ini, the window's
-- own text drawing and the chords' own reset; the windows open or shut as found, with their layout. The script never
-- presses Apply and writes no file: at the end ModOptions.ini, the extras' Custom set file, the chords file and the
-- screens' step-aside record must read line for line as found. (QA review: the layout's put-back, ZEDQA_LAYOUT_BACK, runs ZeD_Window.resetLayout,
-- which sets each window's accent option to Accent color and asks for ModOptions.ini to be saved. So the save stays
-- held through it, the accents and every value go back as found after it, and only then is the game's save its own.)

if not (RT and ZeD and ZeD.Settings and ZeD.MainMenu and PZAPI and PZAPI.ModOptions) then
    print("ZEDQA vx10_def FAIL the kit (rt_kit.lua), ZeD's settings or its menus are not loaded")
    print("ZEDQA vx10_def VERDICT FAIL 1")
    print("ZEDQA vx10_def DONE")
    return
end

local Q = RT.make("vx10_def")
Q.maxMs = 240000                     -- (four minutes, then the put-back; the script itself takes well under one)
local S = { p = RT.p, opt0 = {}, staged = {}, nOpt = 0, saves = 0, cap = {}, capOn = false, qcCalls = 0 }
local H = {}
local St, MM, Sc, Sf = ZeD.Settings, ZeD.MainMenu, ZeD.Scale, ZeD.Safe
S.gmx0, S.gmy0 = getMouseX, getMouseY

-- ===================================================================== helpers: the game
function H.errs() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.menuUp()
    local up = false
    pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end)
    return up
end
function H.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
function H.aside() local a = false; pcall(function() a = (Sf ~= nil and Sf.on("windows")) and true or false end); return a end
function H.f(n) if type(n) ~= "number" then return tostring(n) end; return string.format("%.3f", n) end
function H.near(a, b) return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 0.001 end
function H.list(t) if #t == 0 then return "none" end; return table.concat(t, " ") end
-- a file under Zomboid/Lua as lines, and how the read went: "ok", "none" (no such file) or "failed" (a read that broke
-- part way gives no lines). Read only: this script writes no file.
function H.readLines(name)
    local t, state = nil, "failed"
    local okAll = pcall(function()
        local r = getFileReader(name, false)
        if not r then state = "none"; return end
        local lines = {}
        local okRead = pcall(function()
            local l = r:readLine()
            while l do lines[#lines + 1] = l; l = r:readLine() end
        end)
        pcall(function() r:close() end)
        if okRead then t, state = lines, "ok" end
    end)
    if not okAll then t, state = nil, "failed" end
    return t, state
end
function H.sameLines(a, b) return a ~= nil and b ~= nil and table.concat(a, "\n") == table.concat(b, "\n") end
-- the file now against the read at the start: true or false, nil when the start's read was not whole; and a word on it
function H.fileSame(name, lines0, state0)
    local now, st = H.readLines(name)
    if state0 == "none" then return st == "none", (st == "none") and "still none" or ("made during the run, " .. tostring(now and #now) .. " lines") end
    if state0 ~= "ok" then return nil, "not read whole at the start" end
    local same = (st == "ok" and H.sameLines(now, lines0)) and true or false
    return same, tostring(now and #now or 0) .. " lines, " .. tostring(#lines0) .. " at the start"
end
function H.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = v end
    return o
end
-- whether table t holds key as a field of its own, and its value. (Kahlua's rawget looks through an __index table,
-- so on a window it answers the class's method for a field the window does not own: pairs lists own fields only.)
function H.ownField(t, key)
    local has, val = false, nil
    pcall(function()
        for k, v in pairs(t) do
            if k == key then has, val = true, v; break end
        end
    end)
    return has, val
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
function H.troot() return ZeD.T and ZeD.T.root or nil end
function H.scaleSettled() return Sc == nil or (Sc._reopenAt == nil and H.near(H.troot(), Sc.root())) end
function H.lookSay()
    return tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize) .. ", status " .. tostring(ZeD.currentStatus)
        .. ", see-through " .. tostring(ZeD.surfaceAlpha) .. ", UI scale root " .. H.f(Sc and Sc.root()) .. " (tokens on " .. H.f(H.troot()) .. ")"
end

-- ===================================================================== helpers: ZeD's settings
function H.opts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo end
function H.opt(id) local zo = H.opts(); return zo and zo.dict and zo.dict[id] or nil end
function H.val(id) local o = H.opt(id); local v = nil; pcall(function() v = o:getValue() end); return v end
function H.el(id) local o = H.opt(id); return o and o.element or nil end
-- every one of ZeD's settings (all are drop-downs to ModOptions: Settings.lua)
function H.combos()
    local out = {}
    local zo = H.opts()
    for _, o in ipairs((zo and zo.data) or {}) do if o.type == "combobox" and o.id then out[#out + 1] = o end end
    return out
end
-- the item a setting starts on: its zedDefault (Settings.lua), else the item its mod declared before the saved values
-- were read (ZeD.ModOptionsOwners: the old code's Style, Map and Restock had only this one)
function H.defOf(o)
    if o.zedDefault ~= nil then return o.zedDefault end
    local d = nil
    pcall(function() local MO = ZeD.ModOptionsOwners; d = MO and MO.default and MO.default("ZeD_UI", o.id) end)
    if type(d) == "number" then return d end
    return nil
end
function H.lite() local v = false; pcall(function() v = St.lite() and true or false end); return v end
function H.offVanilla() local v = nil; pcall(function() v = St.additionsOffVanilla() and true or false end); return v end
function H.itemText(el, i) local t = nil; pcall(function() t = el:getOptionText(i) end); return tostring(t) end
-- the screen switches a mod holds now (ZeD_StepAside.lua handed that screen to the mod): option id -> the screen.
-- Left as found by the scene: StepAside reads the stored switch once a second, paused too, and a switch moved to Off
-- would read as the player taking the screen back (its record file written, the hand-back forgotten)
function H.heldScreens()
    local out = {}
    pcall(function()
        local SA = ZeD.StepAside
        local rec = SA and SA.record and SA.record()
        for sc in pairs((rec and rec.set) or {}) do
            local o = St.screenOptions and St.screenOptions[sc]
            if o and o.id then out[tostring(o.id)] = tostring(sc) end
        end
    end)
    return out
end
-- the scene, in memory: every setting on the item it starts on, Style on Lite. Returns how many, the ones moved, the
-- ones with no default found (left as they are) and the held screen switches left off their default
function H.stage()
    local n, moved, none, kept = 0, {}, {}, {}
    local held = H.heldScreens()
    for _, o in ipairs(H.combos()) do
        local id = tostring(o.id)
        local want = (id == "lookStyle") and 2 or H.defOf(o)
        if held[id] then
            if want == nil or o.selected ~= want then kept[#kept + 1] = id .. " (" .. held[id] .. ", item " .. tostring(o.selected) .. ")" end
        elseif want and o.values and o.values[want] then
            S.staged[id] = want
            n = n + 1
            if o.selected ~= want then
                moved[#moved + 1] = id .. " " .. tostring(o.selected) .. ">" .. tostring(want)
                pcall(function() o:setValue(want) end)
            end
        else
            none[#none + 1] = id
        end
    end
    return n, moved, none, kept
end
-- the staged settings whose control (Options open) is not on the staged item
function H.notStaged()
    local out = {}
    for _, o in ipairs(H.combos()) do
        local v = S.staged[tostring(o.id)]
        if v ~= nil and o.element and o.element.selected ~= v then out[#out + 1] = tostring(o.id) .. "=" .. tostring(o.element.selected) end
    end
    return out
end
-- the staged settings whose stored value is no longer the staged one (something applied)
function H.storedMoved()
    local out = {}
    for _, o in ipairs(H.combos()) do
        local v = S.staged[tostring(o.id)]
        if v ~= nil and o.selected ~= v then out[#out + 1] = tostring(o.id) .. "=" .. tostring(o.selected) end
    end
    return out
end
-- the settings whose control is not on the stored value
function H.liveOff()
    local out = {}
    for _, o in ipairs(H.combos()) do
        if o.element and o.element.selected ~= o.selected then out[#out + 1] = tostring(o.id) .. "=" .. tostring(o.element.selected) end
    end
    return out
end

-- ===================================================================== helpers: the Options window
function H.W() return MM.pauseOpts end
function H.optsUp() local w = MM.pauseOpts; return w ~= nil and w:isVisible() and MM.pauseView == "options" end
function H.rows() local w = H.W(); local r = {}; if w then pcall(function() r = w:zedSetupRows() or {} end) end; return r end
-- ZeD setup's row for one of ZeD's settings (the row whose control is the setting's own)
function H.rowOf(id)
    local el = H.el(id)
    if not el then return nil end
    for _, r in ipairs(H.rows()) do if r.control == el then return r end end
    return nil
end
-- a button of the window's bottom row, as the last frame built it (its id: "defaults", "discard", "confirm:yes")
function H.spec(id)
    local w = H.W()
    for _, b in ipairs((w and w._specs) or {}) do if b.band and b.id == id then return b end end
    return nil
end
-- ZeD's own controls: each of its settings' control, by the setting's id
function H.ownMap()
    local m = {}
    for _, o in ipairs(H.combos()) do if o.element then m[o.element] = tostring(o.id) end end
    return m
end
-- the name of one of ZeD's own controls: its setting's id, or the stand-in of a row that works several (G.MERGED);
-- nil for anything else (an add-on's control, the game's)
function H.ownName(c, m)
    if c == nil then return nil end
    if m[c] then return m[c] end
    local mk = nil
    pcall(function() if type(c) == "table" then mk = rawget(c, "zedMerged") end end)
    if mk then return "merged:" .. tostring(mk) end
    return nil
end
-- the add-on rows on the page off their own default (each would keep the button live on any code: said in the scene)
function H.addonOff()
    local m = H.ownMap()
    local out = {}
    for _, r in ipairs(H.rows()) do
        local c = r.control
        if r.kind == "combo" and c and not H.ownName(c, m) and r.zedDefault ~= nil and c.selected ~= r.zedDefault then
            out[#out + 1] = tostring(r.zedOwner) .. ":" .. tostring(r.labelKey or r.label)
        end
    end
    return out
end

-- ----- the pointer the game reads (Mouse.setXY does not move it): held where the script says, and given back
function H.holdMouse(x, y)
    if not S.gmx then
        S.gmx, S.gmy = getMouseX, getMouseY
        getMouseX = function() return S.fx end
        getMouseY = function() return S.fy end
    end
    S.fx, S.fy = math.floor(x), math.floor(y)
end
function H.freeMouse()
    if S.gmx then getMouseX, getMouseY = S.gmx, S.gmy end
    S.gmx, S.gmy = nil, nil
end
-- on the Options window's title bar: no row under it, so the help band is empty
function H.park()
    local w = H.W()
    if w then pcall(function() H.holdMouse(w:getAbsoluteX() + w:getWidth() / 2, w:getAbsoluteY() + ZeD.T.px(8)) end) end
end
-- on a row's name, from the last frame's layout (the row's place in the list: its controller stop). Scrolls the list
-- when the row is not wholly in view and says so (the caller tries again next frame)
function H.pointAtRow(row)
    local w = H.W()
    local L = w and w._list
    if not (row and L) then return false, "the Style row or the list was not laid out" end
    local sp = nil
    for _, b in ipairs(w._specs or {}) do if b.listRow and b.rowRef == row then sp = b end end
    if not sp then return false, "the Style row has no place in the list yet" end
    local top = sp.ry - (w.scroll or 0)
    if top < 0 or top + sp.rh > L.h then
        w.scroll = math.max(0, sp.ry)
        return false, "the list was scrolled to the Style row"
    end
    H.holdMouse(w:getAbsoluteX() + L.x + ZeD.T.px(40), w:getAbsoluteY() + L.y + top + math.floor(sp.rh / 2))
    -- (with the controller in use the band follows the focused row: the focus goes on the Style row too)
    if MM.gamepad and MM.gamepad() then w.focusId = sp.id end
    return true, "the pointer at " .. tostring(S.fx) .. "," .. tostring(S.fy)
end

-- ----- what the window draws: its own drawText calls, while S.capOn, as { s, x, y } (window coordinates)
function H.capInstall(w)
    if S.capW or not w then return end
    local base = w.drawText
    if type(base) ~= "function" then return end
    S.capW = w
    S.dtHas, S.dtOwn = H.ownField(w, "drawText")
    w.drawText = function(self, text, x, y, ...)
        if S.capOn then S.cap[#S.cap + 1] = { s = tostring(text), x = x, y = y } end
        return base(self, text, x, y, ...)
    end
end
-- (the window's own field as found: none, so its class's drawText again, or the one it had)
function H.capRemove()
    S.capOn = false
    if not S.capW then return end
    local w = S.capW
    pcall(function() if S.dtHas then w.drawText = S.dtOwn else w.drawText = nil end end)
    S.capW = nil
end
-- the help band's two parts as drawn that frame (ZeD_MainMenuOptions.lua drawRows): the help line at the band's left
-- (the list's x + 12 units), the default at the right column's x (the column is as wide as "Default: <item>" needs,
-- up to 240 units). Only what is drawn below the list and above the bottom row counts.
function H.bandRead(w)
    local T, L = ZeD.T, w and w._list
    if not (T and L) then return nil end
    local el = H.el("lookStyle")
    local full = ""
    pcall(function() full = tostring(el:getOptionText(1) or "") end)
    local dt = ZeD.tr("UI_ZeD_Options_DefaultIs", full)
    local tip = ZeD.tr("UI_ZeD_Settings_LookStyleTip")
    pcall(function() if MM.ui and MM.ui.plain then tip = MM.ui.plain(tip) end end)
    local dcol = nil
    pcall(function() dcol = math.min(T.px(240), MM.textW(T.fontF2, dt) + T.px(26)) end)
    local top, bot = L.y + L.h, w._bandY or 1000000
    local hx = L.x + T.px(12)
    local dx = dcol and (L.x + L.w - T.px(1) - dcol + T.px(12)) or nil
    local B = { help = {}, def = {}, dt = dt, tip = tip, full = full }
    for _, c in ipairs(S.cap) do
        if type(c.x) == "number" and type(c.y) == "number" and c.y >= top and c.y < bot and c.s ~= "" then
            if math.abs(c.x - hx) < 1 then B.help[#B.help + 1] = c.s
            elseif dx and math.abs(c.x - dx) < 1 then B.def[#B.def + 1] = c.s end
        end
    end
    return B
end

-- ----- the stand-ins: the game's save of ModOptions.ini (held for the whole run) and the quick chords' reset (it saves
-- at once; held around the press, as rt_system.lua and bxr_lite.lua hold it)
function H.holdSave()
    local mo = PZAPI and PZAPI.ModOptions
    if not mo then return false end
    if S.saveHeld then return true end
    local has, raw = H.ownField(mo, "save")
    if not (has and type(raw) == "function") then return false end
    S.saveRaw = raw
    rawset(mo, "save", function()
        S.saves = S.saves + 1
        Q.say("ZeD asked for ModOptions.ini to be saved (held: nothing is written)")
    end)
    S.saveHeld = true
    return true
end
function H.freeSave()
    if not S.saveHeld then return end
    pcall(function() rawset(PZAPI.ModOptions, "save", S.saveRaw) end)
    S.saveHeld = false
end
function H.holdChords()
    local QC = ZeD.QuickChords
    if not QC or S.qcHeld then return end
    S.qcReset, S.qcHeld = QC.reset, true
    QC.reset = function() S.qcCalls = S.qcCalls + 1 end
end
function H.freeChords()
    local QC = ZeD.QuickChords
    if QC and S.qcHeld then QC.reset = S.qcReset end
    S.qcHeld, S.qcReset = false, nil
end

-- ----- the checks after the press, on the page's rows and on the settings with no row
function H.checkRows()
    local m = H.ownMap()
    local n, noDef, off, names, addon = 0, {}, {}, {}, 0
    for _, r in ipairs(H.rows()) do
        local c = r.control
        if r.kind == "combo" and c then
            local nm = H.ownName(c, m)
            if nm then
                n = n + 1
                names[nm] = true
                if r.zedDefault == nil then noDef[#noDef + 1] = nm
                elseif not c.disabled and c.selected ~= r.zedDefault then off[#off + 1] = nm .. "=" .. tostring(c.selected) .. " (default " .. tostring(r.zedDefault) .. ")" end
            else
                addon = addon + 1
            end
        end
    end
    Q.check(n > 0 and names.lookStyle == true and #noDef == 0 and #off == 0,
        "B10-1: after Reset to defaults every one of ZeD's own drop-downs and switches on ZeD setup has a default and sits on it (Style among them)",
        n .. " of ZeD's rows, no default: " .. H.list(noDef) .. ", off their default: " .. H.list(off)
        .. ", other drop-downs left to their own rules (the game's settings, an add-on's): " .. addon)
end
function H.checkHidden()
    local w = H.W()
    local hid = {}
    pcall(function() hid = w:zedHiddenOpts() or {} end)
    local noDef, off = {}, {}
    local hasMap, hasRestock = false, false
    for _, o in ipairs(hid) do
        local id = tostring(o.id)
        if id == "mapLight" then hasMap = true end
        if id == "restock" then hasRestock = true end
        local el = o.element
        if o.zedDefault == nil then noDef[#noDef + 1] = id
        elseif el and not el.disabled and el.selected ~= o.zedDefault then off[#off + 1] = id .. "=" .. tostring(el.selected) .. " (default " .. tostring(o.zedDefault) .. ")" end
    end
    -- (QA review: Map and Restock must each be reached, here or as a row of the page, checked just above; a check that
    -- found neither would pass without proving either)
    local mapAt = hasMap and "no row" or ((H.rowOf("mapLight") ~= nil) and "a row" or "nowhere")
    local resAt = hasRestock and "no row" or ((H.rowOf("restock") ~= nil) and "a row" or "nowhere")
    Q.check(#hid > 0 and #noDef == 0 and #off == 0 and mapAt ~= "nowhere" and resAt ~= "nowhere",
        "B10-1: Reset to defaults also reaches ZeD's settings with no row on the page (Map; Restock while Lite leaves the extras out): each has a default and sits on it",
        #hid .. " settings with no row; Map: " .. mapAt .. ", Restock: " .. resAt .. "; no default: " .. H.list(noDef) .. ", off their default: " .. H.list(off))
end

-- ----- the put-back
function H.putOptions()
    for _, o in ipairs(H.combos()) do
        local v = S.opt0[tostring(o.id)]
        if v ~= nil and (o.selected ~= v or (o.element and o.element.selected ~= v)) then pcall(function() o:setValue(v) end) end
    end
end
-- the copies Settings.lua keeps (the character's theme and pad copies, the windows' accents) as found
function H.putCopies()
    pcall(function()
        local md = S.p:getModData()
        H.restoreTable(md, "ZeD_Theme", S.mdTheme0)
        H.restoreTable(md, "ZeD_Gamepad", S.mdPad0)
        local ws = md.ZeD_WinState
        if ws and ws.char then ws.char.accentKey = S.wsC0 end
        if ws and ws.world then ws.world.accentKey = S.wsW0 end
    end)
    ZeD._pendingCharAccent, ZeD._pendingWorldAccent = S.pendC0, S.pendW0
    pcall(function() if S.cwAcc then RT.cw()._accentKey = S.cwAcc.k end end)
    pcall(function() if S.wwAcc then RT.ww()._accentKey = S.wwAcc.k end end)
end
-- the look as found: the see-through pick, the status set, the theme
function H.putLook()
    local L = S.look0
    if not L then return end
    ZeD.surfaceAlpha, ZeD._seePick, ZeD._seeForced = L.a, L.pick, L.forced
    ZeD.currentStatus = L.status
    pcall(function() if ZeD_Window and ZeD_Window.clearPaletteCache then ZeD_Window.clearPaletteCache() end end)
    pcall(ZeD.applyTheme, L.base, L.accent, L.size)
end
-- Options left (any change discarded, its page as found) and the pause menu shut as found
function H.leaveOptions()
    pcall(function()
        local w = MM.pauseOpts
        if not w then return end
        w.focusId = nil
        if MM.pauseView == "options" then
            if w.confirm or w:anyChanged() then w:discardStay() end
            if S.page0 then w.pageIdx = S.page0 end
            w.scroll = 0
            w:back()
        end
    end)
    if not S.menuWas0 and H.menuUp() then H.toggleMenu() end
end

-- ===================================================================== 0. as found
Q.step(5, function()
    S.err0 = H.errs()
    S.menuWas0 = H.menuUp()
    S.winsWere = RT.isOpen()
    if ZEDQA_LAYOUT_SNAP then pcall(function() S.snap = ZEDQA_LAYOUT_SNAP() end) end
    S.ini0, S.iniState = H.readLines("ModOptions.ini")
    S.cus0, S.cusState = H.readLines("ZeD_custom_additions.txt")
    S.ch0, S.chState = H.readLines("ZeD_chords.txt")
    S.sa0, S.saState = H.readLines("ZeD_step_aside.txt")   -- (StepAside's record: see the head)
    for _, o in ipairs(H.combos()) do S.opt0[tostring(o.id)] = o.selected; S.nOpt = S.nOpt + 1 end
    S.look0 = { a = ZeD.surfaceAlpha, pick = ZeD._seePick, forced = ZeD._seeForced, status = ZeD.currentStatus,
                base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize }
    if Sc then S.root0, S.user0 = Sc.root(), Sc.userScale end
    S.pendC0, S.pendW0 = ZeD._pendingCharAccent, ZeD._pendingWorldAccent
    pcall(function()
        local md = S.p:getModData()
        S.mdTheme0, S.mdPad0 = H.copy(md.ZeD_Theme), H.copy(md.ZeD_Gamepad)
        local ws = md.ZeD_WinState
        S.wsC0 = ws and ws.char and ws.char.accentKey
        S.wsW0 = ws and ws.world and ws.world.accentKey
    end)
    pcall(function() local cw = RT.cw(); if cw then S.cwAcc = { k = cw._accentKey } end end)
    pcall(function() local ww = RT.ww(); if ww then S.wwAcc = { k = ww._accentKey } end end)
    S.go = Q.check(S.nOpt > 0 and MM.openOptions ~= nil and St.lookStyleOption ~= nil and St.lite ~= nil and St.reapplyFromOptions ~= nil,
        "as found: ZeD's settings are there (PZAPI.ModOptions ZeD_UI), Style among them, and ZeD's Options window",
        S.nOpt .. " settings, Style stored " .. tostring(S.opt0.lookStyle) .. ", " .. H.lookSay() .. ", windows open " .. tostring(S.winsWere)
        .. ", pause menu up " .. tostring(S.menuWas0) .. ", ModOptions.ini " .. (S.ini0 and (#S.ini0 .. " lines") or tostring(S.iniState)))
    if not S.go then return end
    S.shut = true          -- (the script shut them: the put-back opens them again and puts their layout back)
    RT.pairShut()
end)
-- the scene, in memory only (the save held first: a save now would write Lite into the player's file)
Q.waitFor(5, 300, function() return not S.go or not RT.isOpen() end, function(ok)
    if not S.go then return end
    if not ok then Q.say("the windows did not shut; the run goes on with them open") end
    if not H.holdSave() then
        Q.skip("B10-1: Reset to defaults in Lite", "the game's save of ModOptions.ini could not be held, so Style Lite is not staged (a save would write it)")
        S.go = false
        return
    end
    S.stagedDone = true    -- (first: a staging that threw part way still gets every value put back)
    local n, moved, none, kept = H.stage()
    S.kept = kept
    pcall(function() if St.forgetHeldCustom then St.forgetHeldCustom() end end)
    pcall(St.reapplyFromOptions)
    Q.say("scene: " .. n .. " ZeD settings staged in memory, " .. #moved .. " moved (" .. H.list(moved) .. "); no default found for: " .. H.list(none)
        .. "; screen switches a mod holds, left as found off their default: " .. H.list(kept)
        .. " | Lite " .. tostring(H.lite()) .. ", extras off Vanilla " .. tostring(H.offVanilla()) .. ", " .. H.lookSay())
end)
Q.waitFor(3, 600, function() return not S.go or H.scaleSettled() end, function(ok)
    if not S.go then return end
    if not ok then Q.say("the UI scale had not settled after the scene was applied: " .. H.lookSay()) end
    if not H.menuUp() then H.toggleMenu() end
end)
Q.waitFor(10, 400, function() return not S.go or (H.menuUp() and MM.pauseOpts ~= nil) end, function(ok)
    if not S.go then return end
    S.go = Q.check(ok, "the pause menu opens, with ZeD's Options window made")
    if S.go then pcall(MM.openOptions) end
end)
Q.waitFor(5, 300, function() return not S.go or H.optsUp() end, function(ok)
    if not S.go then return end
    S.go = Q.check(ok, "ZeD's Options opens from the pause menu")
    if not S.go then return end
    local w = H.W()
    S.page0 = w.pageIdx
    pcall(function() for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end end)
    w.scroll = 0
    w.focusId = nil
    H.park()
end)

-- ===================================================================== the scene, and the button before the press
Q.step(6, function()
    if not S.go then return end
    local w = H.W()
    H.park()
    local pg = nil
    pcall(function() pg = w:pages()[w.pageIdx] end)
    local onSetup = pg ~= nil and pg.setup == true
    local row, el = H.rowOf("lookStyle"), H.el("lookStyle")
    local off, addon = H.notStaged(), H.addonOff()
    S.row = row
    Q.check(onSetup and row ~= nil and el ~= nil and el.selected == 2 and H.lite() and #off == 0 and H.offVanilla() == false and not w:anyChanged(),
        "the scene: ZeD setup from the pause menu in Lite, the Style row reading Lite, every other ZeD setting on its default (the extras on the Vanilla preset), nothing changed yet",
        "page " .. tostring(pg and pg.title) .. ", Style row " .. tostring(row ~= nil) .. " reading " .. tostring(el and el.selected) .. " (" .. H.itemText(el, el and el.selected) .. ")"
        .. ", controls not on the staged item: " .. H.list(off) .. ", extras off Vanilla " .. tostring(H.offVanilla()) .. ", changes waiting " .. tostring(w:anyChanged())
        .. ", add-on rows off their default: " .. H.list(addon) .. ", screen switches a mod holds, off their default: " .. H.list(S.kept or {}))
    if not row then S.go = false; return end
    local b = H.spec("defaults")
    local live = nil
    pcall(function() live = w:zedOffDefault() and true or false end)
    if #addon > 0 or #(S.kept or {}) > 0 then
        -- (another mod's setting off its own default, or a screen switch a mod holds left on, keeps the button live on any
        -- code: no proof either way)
        Q.skip("B10-1: in Lite with every other setting on its default, Reset to defaults is live before it is pressed",
            "the button is live whatever Style does: an add-on's row off its own default (" .. H.list(addon)
            .. "), a screen switch a mod holds left as found (" .. H.list(S.kept or {}) .. ")")
        return
    end
    -- (old code: gray. Style had no default, Map and Restock none either, and everything else sat on its own)
    Q.check(b ~= nil and not b.disabled, "B10-1: in Lite with every other setting on its default, Reset to defaults (bottom row, by Back) is live before it is pressed",
        "button drawn " .. tostring(b ~= nil) .. ", gray " .. tostring(b and b.disabled) .. ", something off its default " .. tostring(live))
end)

-- ===================================================================== the Style row's help band
Q.waitFor(2, 90, function()
    if not S.go then return true end
    local ok, why = H.pointAtRow(H.rowOf("lookStyle") or S.row)
    S.pointWhy = why
    return ok
end, function(ok)
    if not S.go then return end
    S.pointed = ok and true or false
    H.capInstall(H.W())
end)
Q.step(2, function()
    if not (S.go and S.pointed) then return end
    S.cap = {}
    S.capOn = true      -- (the next frame's drawing is kept)
end)
Q.step(1, function()
    S.capOn = false
    if not S.go then return end
    local w = H.W()
    if not S.pointed then
        Q.skip("B10-1: the Style row's help line and its default in the help band", "the Style row could not be brought under the pointer (" .. tostring(S.pointWhy) .. ")")
    elseif not S.capW then
        Q.skip("B10-1: the Style row's help line and its default in the help band", "the Options window's drawing could not be read")
    else
        local B = H.bandRead(w)
        if not B then
            Q.check(false, "B10-1: with the pointer on the Style row the help band shows Style's help line and its default", "the help band was not laid out")
        else
            local helpJ, defJ = table.concat(B.help, " "), table.concat(B.def, " ")
            -- (the band holds three lines: a help line cut there must still be the help's start)
            local helpOk = helpJ ~= "" and B.tip ~= "" and B.tip:sub(1, #helpJ) == helpJ and (#helpJ == #B.tip or #B.help >= 3)
            local defOk = B.full ~= "" and defJ == B.dt
            -- (old code: the row had no help key and no default, so the band drew nothing for it)
            Q.check(helpOk and defOk, "B10-1: with the pointer on the Style row the help band shows Style's help line and, at its right, '" .. tostring(B.dt) .. "'",
                "help line: '" .. helpJ .. "' | right column: '" .. defJ .. "' | " .. #S.cap .. " texts drawn that frame, " .. tostring(S.pointWhy))
        end
    end
    H.capRemove()
    H.park()
    pcall(function() if MM.gamepad and MM.gamepad() then w.focusId = nil end end)
end)

-- ===================================================================== Reset to defaults
Q.step(3, function()
    if not S.go then return end
    local w = H.W()
    H.park()
    S.row = H.rowOf("lookStyle") or S.row
    H.holdChords()
    local b = H.spec("defaults")
    if b and not b.disabled and b.fn then
        S.defOk = pcall(b.fn)
        S.defHow = "its button"
    else
        S.defOk = pcall(function() w:zedDefaults() end)
        S.defHow = "the call its button makes (the button was " .. (b and "gray" or "not drawn") .. ")"
    end
    H.freeChords()
    Q.say("Reset to defaults pressed through " .. S.defHow .. ": ran " .. tostring(S.defOk) .. ", quick chord resets held back " .. S.qcCalls)
end)
Q.step(3, function()
    if not S.go then return end
    local w = H.W()
    local row, el = H.rowOf("lookStyle") or S.row, H.el("lookStyle")
    local sel = el and el.selected
    local mark = false
    pcall(function() mark = w:isChanged(row) and true or false end)
    local waiting = w:anyChanged()
    -- (old code: Style stayed on Lite, no changed mark)
    Q.check(S.defOk and sel == 1 and mark and waiting and H.val("lookStyle") == 2 and H.lite(),
        "B10-1: after Reset to defaults the Style row reads Full, a change waiting for Apply with its changed mark (the stored Style still Lite)",
        "Style control " .. tostring(sel) .. " (" .. H.itemText(el, sel) .. "), changed mark " .. tostring(mark) .. ", changes waiting " .. tostring(waiting)
        .. ", stored Style " .. tostring(H.val("lookStyle")) .. ", pressed through " .. tostring(S.defHow))
    local b = H.spec("defaults")
    local live = nil
    pcall(function() live = w:zedOffDefault() and true or false end)
    Q.check(b ~= nil and b.disabled == true and live == false, "B10-1: after Reset to defaults the button grays: nothing on ZeD setup is left off its default",
        "button drawn " .. tostring(b ~= nil) .. ", gray " .. tostring(b and b.disabled) .. ", something off its default " .. tostring(live))
    -- (old code: the Style row with no default; Map and Restock with none among the settings with no row)
    H.checkRows()
    H.checkHidden()
end)

-- ===================================================================== Discard changes
Q.step(2, function()
    if not S.go then return end
    local b = H.spec("discard")
    S.discHow = nil
    if b and not b.disabled and b.fn then
        pcall(b.fn)
        S.discHow = "the footer's Discard changes"
    end
end)
Q.step(3, function()
    if not S.go then return end
    local w = H.W()
    local y = H.spec("confirm:yes")
    if S.discHow and w.confirm == "discard" and y and y.fn then
        pcall(y.fn)
        S.discHow = S.discHow .. ", then the band's Discard changes"
    else
        pcall(function() w:discardStay() end)
        S.discHow = "discardStay(), the band's answer (the footer's question did not come up: confirm " .. tostring(w.confirm) .. ")"
    end
end)
Q.step(3, function()
    if not S.go then return end
    local w = H.W()
    local row, el = H.rowOf("lookStyle") or S.row, H.el("lookStyle")
    local lo, moved = H.liveOff(), H.storedMoved()
    local mark = true
    pcall(function() mark = w:isChanged(row) and true or false end)
    local same, sameHow = H.fileSame("ModOptions.ini", S.ini0, S.iniState)
    Q.check(#lo == 0 and el ~= nil and el.selected == 2 and not mark and not w:anyChanged() and not w.confirm and #moved == 0 and H.lite()
        and S.saves == 0 and same ~= false,
        "B10-1: Discard changes puts every row back on its stored pick (Style reads Lite again, no changed mark) and nothing was applied (the stored Style still Lite, nothing saved)",
        "through " .. tostring(S.discHow) .. "; controls off their stored pick: " .. H.list(lo) .. ", Style control " .. tostring(el and el.selected)
        .. ", changed mark " .. tostring(mark) .. ", changes waiting " .. tostring(w:anyChanged()) .. ", stored values moved: " .. H.list(moved)
        .. ", saves asked " .. S.saves .. ", ModOptions.ini as found " .. tostring(same) .. " (" .. tostring(sameHow) .. ")")
end)

-- ===================================================================== put back
Q.mark()
Q.step(3, function()
    -- (a run cut short lands here: the stand-ins first)
    H.capRemove()
    H.freeChords()
    H.freeMouse()
    H.leaveOptions()
    if S.stagedDone then
        pcall(H.putOptions)
        pcall(function() if St.forgetHeldCustom then St.forgetHeldCustom() end end)
        pcall(St.reapplyFromOptions)       -- (the UI scale, the theme, the window accents, the input lock from the values as found)
        pcall(H.putCopies)
        pcall(H.putLook)
        pcall(function() if Sf and Sf.reread then Sf.reread() end end)
    end
end)
Q.waitFor(10, 900, function()
    if H.menuUp() and not S.menuWas0 then
        -- (still up: once a second, Options left again and the menu shut again, so the game is never left paused)
        S.menuWait = (S.menuWait or 0) + 1
        if S.menuWait >= 60 then
            S.menuWait = 0
            H.leaveOptions()
        end
        return false
    end
    return H.scaleSettled()
end, function(ok)
    if S.stagedDone then pcall(H.putOptions) end   -- (anything that moved while the menu shut)
    Q.check(ok, "put back: the pause menu as found and the UI scale settled", H.lookSay() .. ", pause menu up " .. tostring(H.menuUp()))
    if S.shut and S.winsWere and not H.aside() and not RT.isOpen() then RT.pairOpen() end
end)
Q.waitFor(10, 300, function() return not (S.shut and S.winsWere) or H.aside() or RT.isOpen() end, function()
    if S.shut and S.winsWere and ZEDQA_LAYOUT_BACK and S.snap then
        -- (QA review: the layout's put-back runs ZeD_Window.resetLayout, which sets each window's accent option to Accent
        -- color and asks for ModOptions.ini to be saved. The save is held through it, then the accents, the copies and
        -- every value go back as found, and only then is the save the game's own: nothing is written)
        H.holdSave()
        pcall(ZEDQA_LAYOUT_BACK, S.snap, "vx10_def")
        pcall(H.putOptions)
        pcall(H.putCopies)
    end
    H.freeSave()
end)
Q.step(20, function()
    local off = {}
    for _, o in ipairs(H.combos()) do
        local id = tostring(o.id)
        local v = S.opt0[id]
        if v ~= nil then
            if o.selected ~= v then off[#off + 1] = id .. " stored " .. tostring(o.selected) .. " (was " .. tostring(v) .. ")"
            elseif o.element and o.element.selected ~= v then off[#off + 1] = id .. " control " .. tostring(o.element.selected) .. " (stored " .. tostring(v) .. ")" end
        end
    end
    Q.check(#off == 0, "put back: every ZeD setting, stored and on its control, is as found (Style " .. tostring(S.opt0.lookStyle) .. ")",
        (#off == 0) and (S.nOpt .. " settings") or table.concat(off, "; "))
    local L = S.look0 or {}
    Q.check(ZeD.currentBase == L.base and ZeD.currentAccent == L.accent and ZeD.currentSize == L.size and ZeD.currentStatus == L.status
        and ZeD.surfaceAlpha == L.a and (Sc == nil or (H.near(Sc.root(), S.root0) and H.near(H.troot(), S.root0) and Sc.userScale == S.user0)),
        "put back: the theme, accent, text size, status colors, see-through and UI scale are as found",
        H.lookSay() .. " | as found " .. tostring(L.base) .. " / " .. tostring(L.accent) .. " / " .. tostring(L.size) .. ", status " .. tostring(L.status)
        .. ", see-through " .. tostring(L.a) .. ", UI scale root " .. H.f(S.root0))
    local a, an = H.fileSame("ModOptions.ini", S.ini0, S.iniState)
    local b, bn = H.fileSame("ZeD_custom_additions.txt", S.cus0, S.cusState)
    local c, cn = H.fileSame("ZeD_chords.txt", S.ch0, S.chState)
    local d, dn = H.fileSame("ZeD_step_aside.txt", S.sa0, S.saState)
    local fWhat = "put back: ModOptions.ini, the extras' Custom set file, the chords file and the screens' step-aside record read line for line as found (the script wrote nothing)"
    local fHow = "ModOptions.ini " .. tostring(a) .. " (" .. an .. "), Custom set " .. tostring(b) .. " (" .. bn .. "), chords " .. tostring(c) .. " (" .. cn
        .. "), step-aside record " .. tostring(d) .. " (" .. dn .. "); saves ZeD asked for while held: " .. S.saves
    -- (QA review: a file not read whole at the start cannot be compared, so it is no PASS; any file changed is a FAIL)
    if a == false or b == false or c == false or d == false or (a == true and b == true and c == true and d == true) then
        Q.check(a == true and b == true and c == true and d == true, fWhat, fHow)
    else
        Q.skip(fWhat, "a file was not read whole at the start, so it cannot be compared: " .. fHow)
    end
    local stand = {}
    if getMouseX ~= S.gmx0 or getMouseY ~= S.gmy0 then stand[#stand + 1] = "the pointer" end
    local _, saveNow = H.ownField(PZAPI.ModOptions, "save")
    if S.saveRaw and saveNow ~= S.saveRaw then stand[#stand + 1] = "the save of ModOptions.ini" end
    if S.dtHas ~= nil then
        local w = MM.pauseOpts
        local has, own = H.ownField(w, "drawText")
        if has ~= S.dtHas or (has and own ~= S.dtOwn) then stand[#stand + 1] = "the Options window's text drawing" end
    end
    if S.qcHeld then stand[#stand + 1] = "the chords' reset" end
    Q.check(#stand == 0 and H.menuUp() == S.menuWas0 and (S.winsWere == nil or H.aside() or RT.isOpen() == S.winsWere),
        "put back: the pause menu and the windows open or shut as found; the pointer, the save, the text drawing and the chords' reset the game's own",
        "stand-ins left: " .. H.list(stand) .. ", pause menu up " .. tostring(H.menuUp()) .. ", windows open " .. tostring(RT.isOpen()) .. " (" .. tostring(S.winsWere) .. " at the start)")
    local e = H.errs()
    -- (QA review: an error count the game does not give is no PASS)
    if type(S.err0) == "number" and type(e) == "number" then
        Q.check(e == S.err0, "no new Lua error during the run", (e - S.err0) .. " new")
    else
        Q.skip("no new Lua error during the run", "the game's Lua error count could not be read (" .. tostring(S.err0) .. ", " .. tostring(e) .. ")")
    end
end)
-- (whatever threw above: every stand-in is the game's own again; each of these does nothing when already done)
Q.step(1, function()
    H.freeSave()
    H.capRemove()
    H.freeChords()
    H.freeMouse()
end)
Q.start()
