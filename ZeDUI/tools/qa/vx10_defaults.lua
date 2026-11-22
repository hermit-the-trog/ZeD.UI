-- ZeDUI/tools/qa/vx10_defaults.lua  (Nov 21 2026, QA; tag vx10_def; reworked Nov 22 2026 to the director's rule in
-- 7d8dc58ce): the in-game proof of ZeD setup's Reset to defaults as it stands. Built on rt_kit.lua (the global RT); run
-- after zedqa_prelude.lua and rt_kit.lua. grep "ZEDQA vx10_def". No pictures.
--
-- B10-1     (QA batch 10, ZeDUI/qa/audits/2026-11-21_beast_batch10.md) Reset to defaults skipped Style, Map and
--           Restock: Settings.lua noted no default (zedDefault) for lookStyle, mapLight and restock, and the Style row's
--           help band had no help line and no "Default: Full". Build's fix, 9251ebdf6, gave the three their defaults,
--           and Defaults then reset all three, Lite back to Full (this script passed on that code at 4K and 1280x800 on
--           Nov 21: 17 pass).
-- The rule now (the director, Nov 21 2026; Build's commit 7d8dc58ce): Reset to defaults LEAVES Style as it is, so a
--           Lite player stays in Lite. The Style row keeps its default (Full), so its help band still shows its help
--           line and "Default: Full", but the row carries zedNoReset: zedOffDefault does not count it and zedDefaults
--           does not set it. Map and Restock keep their defaults and Defaults still resets them (9251ebdf6 stands for
--           those two).
--
-- The scene, in memory only, in two parts. Both windows are shut first (the UI scale's default can differ from the
-- run's, and a scale change shuts open windows), and the game's save of ModOptions.ini is held from the staging until
-- every value is back as found: a stand-in counts the asks and nothing is written. While Options is up the pointer the
-- game reads is held on the window's title bar (no row lit by chance).
--   Part 1  every ZeD setting's stored value on the item it starts on (its zedDefault; an option with none takes the
--           item its mod declared, ZeD.ModOptionsOwners.default) and Style stored Lite, set as a value the way
--           bxr_lite.lua sets it (not picked, so the extras stay on their own defaults, the Vanilla preset); the look
--           then applied from those values as a game start applies it (ZeD.Settings.reapplyFromOptions). Then the pause
--           menu, ZeD's Options and the ZeD setup page: Style is the only setting off its default.
--   Part 2  Back from Options with nothing changed, as a player leaves it; while the pause menu shows, ONE ordinary
--           setting stored off its default: Ammo on the belt (ammoBox) On, with the preset row stored on Custom, the
--           preset those values make; then Options again from the pause menu. So Reset to defaults is live for a reason
--           other than Style and is pressed through its own button.
--           Why Ammo on the belt: an addition with a plain row of its own (an on/off switch, Off its default; not a row
--           that works several settings, not a screen a mod can take, not Loadouts, whose pick adds or takes away the
--           Restock row), and On it restyles and rescales nothing and shuts no window (a Look row would). It is also
--           the Lite player's own case: an extra kept on shows the Additions group in Lite (QA B3-2), and Defaults
--           takes the extras back to Vanilla while Style stays Lite.
--           Why the preset row with it: each open of Options (ZeD_MMOptions:onShow) runs ZeD.Settings.reconcileAdditions,
--           which sets the stored preset to the one the stored additions make and, reading Custom, WRITES the Custom set
--           file (ZeD_custom_additions.txt). Stored already on Custom, it finds nothing to set: no file, no save.
--           (QA review, Nov 22 2026) The preset stored is Settings.lua's own reading, not a copy of its rule kept here:
--           with Options shut every control sits on its stored value, so ZeD.Settings.syncAdditionsPreset puts the
--           preset control on the preset the stored values make, and that item is stored. With a control off its
--           stored value or no reading, part 2 is not staged.
-- (QA review, Nov 21 2026) A screen switch a mod holds (ZeD_StepAside.lua handed that screen to the mod) is left as
-- found: moved in memory, StepAside's look once a second (paused too) would take it for the player taking the screen
-- back and write its record file, Zomboid/Lua/ZeD_step_aside.txt. One that is on keeps the button live on any code, so
-- check "alone" is then a SKIP with the reason, as for an add-on's row off its own default.
--
-- The checks, in the order they run ("9251ebdf6 alone" is the code before 7d8dc58ce, when Defaults reset Style):
--   scene 1  ZeD setup in Lite: the Style row reads Lite, every other setting on its default, nothing changed yet.
--   alone    the Style row has its default (Full) and is off it, yet Reset to defaults (the bottom row, by Back) is gray
--            and nothing counts as off its default: Style alone does not count. 9251ebdf6 alone: live (Style's default
--            counted). Before 9251ebdf6: Style had no default to be off, so nothing is proven (FAIL).
--   again    Options closes with Back (nothing waiting) and opens again from the pause menu. (Should part 2 not stage,
--            a FAIL line says why, Options stays shut and the checks below are left out.)
--   scene 2  ZeD setup in Lite shows the Additions group: the Ammo on the belt row reads On, the preset row Custom, the
--            Style row Lite, every other setting on its default, nothing changed yet.
--   live     Reset to defaults is live (Ammo on the belt is off its default).
--   help     the pointer held on the Style row: the help band shows Style's help line (UI_ZeD_Settings_LookStyleTip)
--            and, in its right column, "Default: Full". Read from what the Options window draws that frame (its
--            drawText calls, by their place in the band), not from the row's fields. Before 9251ebdf6: an empty band.
--   press    Reset to defaults pressed through its button (the call a click makes; on a gray button the call the
--            button would make, said so, so a wrong reach still shows). Then:
--   style    the Style row still reads Lite with NO changed mark (nothing waits for it); the stored Style still Lite.
--            9251ebdf6 alone: Full, a change waiting with its changed mark.
--   extra    the Ammo on the belt row back on its default (Off) with its changed mark and the preset row on its default
--            (Vanilla), a change waiting for Apply; the stored Ammo on the belt still On (nothing applied).
--   gray     the button grays and nothing counts as off its default, with Style still on Lite, off its default (Full).
--            9251ebdf6 alone: gray, but only because Style went to Full, so the check fails on Style. Before 9251ebdf6:
--            Style had no default to be off.
--   rows     every one of ZeD's own drop-downs and switches on the page has a default (Style's too, for its help) and
--            sits on it, but the one Defaults leaves alone (marked zedNoReset): Style and only Style, still on its pick
--            from before the press (Lite). An add-on's row may have no default by design (ZeD_MainMenuOptionGroups.lua
--            addonRows): counted, not checked. 9251ebdf6 alone: no row marked, Style on Full.
--   hidden   ZeD's settings with no row on the page (Map always; Restock while Loadouts is off) each have a default and
--            sit on it. Before 9251ebdf6: Map and Restock had none.
--   discard  Discard changes in the footer, then the band's Discard changes: every control back on its stored pick
--            (Style Lite, Ammo on the belt On, the preset Custom; no changed mark, nothing waiting) and nothing applied
--            (every stored value still the staged one, Style still Lite, no save asked, ModOptions.ini line for line as
--            found). It passes on 9251ebdf6 alone too: it guards Defaults' reach.
-- If Defaults reset Style again (9251ebdf6 alone, before 7d8dc58ce), four checks FAIL: alone, style, gray and rows. The
-- others pass there too. On the code before 9251ebdf6 (no default for Style, Map or Restock) five FAIL: alone and gray
-- (Style had no default to be off), help, rows and hidden.
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
-- part 2's one ordinary setting off its default (see the head): Ammo on the belt, item 2 On (item 1 Off, its default)
local X = { id = "ammoBox", on = 2, name = "Ammo on the belt" }
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
-- (asked first: no option, no call, so nothing throws, even caught; in -debug a caught throw still logs an exception)
function H.val(id) local o = H.opt(id); local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.el(id) local o = H.opt(id); return o and o.element or nil end
-- every one of ZeD's settings (all are drop-downs to ModOptions: Settings.lua)
function H.combos()
    local out = {}
    local zo = H.opts()
    for _, o in ipairs((zo and zo.data) or {}) do if o.type == "combobox" and o.id then out[#out + 1] = o end end
    return out
end
-- the item a setting starts on: its zedDefault (Settings.lua), else the item its mod declared before the saved values
-- were read (ZeD.ModOptionsOwners: the code before 9251ebdf6 gave Style, Map and Restock only this one)
function H.defOf(o)
    if o.zedDefault ~= nil then return o.zedDefault end
    local d = nil
    pcall(function() local MO = ZeD.ModOptionsOwners; d = MO and MO.default and MO.default("ZeD_UI", o.id) end)
    if type(d) == "number" then return d end
    return nil
end
-- (the stored Style; the stored additions against the Vanilla preset)
function H.lite() local v = false; if St.lite then pcall(function() v = St.lite() and true or false end) end; return v end
function H.offVanilla() local v = nil; if St.additionsOffVanilla then pcall(function() v = St.additionsOffVanilla() and true or false end) end; return v end
-- an item's words on a drop-down ("?" with no drop-down or no item to ask about)
function H.itemText(el, i)
    if not (el and i ~= nil and el.getOptionText) then return "?" end
    local t = nil
    pcall(function() t = el:getOptionText(i) end)
    return tostring(t)
end
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
-- part 1 of the scene, in memory: every setting on the item it starts on, Style on Lite. Returns how many, the ones
-- moved, the ones with no default found (left as they are) and the held screen switches left off their default
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
-- part 2 of the scene (see the head): Ammo on the belt stored On, then the preset row stored on the preset the stored
-- additions now make, as Apply would leave it, so the next open of Options (ZeD_MMOptions:onShow runs
-- ZeD.Settings.reconcileAdditions) finds nothing to set: no Custom set file written, no save asked. (QA review) The
-- preset is Settings.lua's own reading: with Options shut every control sits on its stored value (checked), so
-- ZeD.Settings.syncAdditionsPreset puts the preset control on the preset the STORED values make. The control is
-- cleared to 0 first, so a reading that did not run shows. Returns true and the preset's item, or false and why (then
-- Options is not opened again, and the put-back runs)
function H.stageExtra()
    local o, po = H.opt(X.id), H.opt("additionsPreset")
    local def = o and H.defOf(o)
    if not (o and po and po.element and o.values and o.values[X.on] and def ~= nil and def ~= X.on and St.syncAdditionsPreset) then
        return false, X.name .. " (" .. X.id .. ") or the preset row is missing, On is its default (default " .. tostring(def)
            .. ") or Settings.lua has no syncAdditionsPreset"
    end
    pcall(function() o:setValue(X.on) end)
    local off = H.liveOff()
    local want = nil
    if #off == 0 then
        local pel = po.element
        pel.selected = 0
        pcall(St.syncAdditionsPreset)
        want = pel.selected
    end
    if not (want and po.values and po.values[want]) then
        pcall(function() o:setValue(def) end)
        pcall(function() po:setValue(po.selected) end)   -- (its control back on its stored item)
        return false, "Settings.lua's reading of the preset the stored additions make: " .. tostring(want)
            .. " (controls off their stored value: " .. H.list(off) .. "); " .. X.name .. " put back Off"
    end
    pcall(function() po:setValue(want) end)
    S.staged[X.id], S.staged.additionsPreset = X.on, want
    if H.val(X.id) ~= X.on or H.val("additionsPreset") ~= want then
        return false, X.name .. " stored " .. tostring(H.val(X.id)) .. ", the preset " .. tostring(H.val("additionsPreset"))
            .. " (wanted " .. tostring(X.on) .. " and " .. tostring(want) .. ")"
    end
    return true, want
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
-- whether a row shows its changed mark (a change waiting for Apply): true or false; nil with no row to ask about
function H.marked(w, row)
    if not (w and row) then return nil end
    local m = nil
    pcall(function() m = w:isChanged(row) and true or false end)
    return m
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
-- each of ZeD's own drop-downs and switches on ZeD setup: its pick now, by its name (H.ownName)
function H.ownPicks()
    local m = H.ownMap()
    local t = {}
    for _, r in ipairs(H.rows()) do
        local c = r.control
        if r.kind == "combo" and c then
            local nm = H.ownName(c, m)
            if nm then t[nm] = c.selected end
        end
    end
    return t
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
    -- (asked first: no control, no call, so nothing throws, even caught)
    if el and el.getOptionText then pcall(function() full = tostring(el:getOptionText(1) or "") end) end
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
-- (7d8dc58ce) every one of ZeD's own rows has a default and sits on it, but the rows marked zedNoReset: those Defaults
-- leaves as they were. Only Style's is marked, and it must still read its pick from before the press (S.pre: Lite).
-- (9251ebdf6 alone: no row marked, Style on Full; before 9251ebdf6: the Style row with no default)
function H.checkRows()
    local m = H.ownMap()
    local n, noDef, off, names, addon = 0, {}, {}, {}, 0
    local alone, notStyle, styleAlone = {}, {}, false
    for _, r in ipairs(H.rows()) do
        local c = r.control
        if r.kind == "combo" and c then
            local nm = H.ownName(c, m)
            if nm then
                n = n + 1
                names[nm] = true
                local was = S.pre and S.pre[nm]
                if r.zedDefault == nil then noDef[#noDef + 1] = nm end
                if r.zedNoReset then
                    alone[#alone + 1] = nm .. "=" .. tostring(c.selected) .. " (before the press " .. tostring(was) .. ")"
                    if nm ~= "lookStyle" then notStyle[#notStyle + 1] = nm
                    elseif c.selected == was then styleAlone = true end
                elseif r.zedDefault ~= nil and not c.disabled and c.selected ~= r.zedDefault then
                    off[#off + 1] = nm .. "=" .. tostring(c.selected) .. " (default " .. tostring(r.zedDefault) .. ")"
                end
            else
                addon = addon + 1
            end
        end
    end
    Q.check(n > 0 and names.lookStyle == true and #noDef == 0 and #off == 0 and styleAlone and #notStyle == 0,
        "7d8dc58ce: after Reset to defaults every one of ZeD's own drop-downs and switches on ZeD setup has a default (Style's too, for its help) and sits on it, but the one Defaults leaves alone: Style, still on Lite as before the press",
        n .. " of ZeD's rows, no default: " .. H.list(noDef) .. ", off their default: " .. H.list(off)
        .. ", left alone by Defaults (zedNoReset): " .. H.list(alone) .. ((#notStyle > 0) and (" (not Style: " .. H.list(notStyle) .. ")") or "")
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
        "B10-1: Reset to defaults still reaches ZeD's settings with no row on the page (Map always; Restock while Loadouts is off): each has a default and sits on it",
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
    -- (a window that is not built has no accent to put back: asked first, so nothing throws, even caught; in -debug a
    -- caught throw still counts as a new Lua error, Nov 21 run 1)
    local cw, ww = RT.cw(), RT.ww()
    if S.cwAcc and cw then pcall(function() cw._accentKey = S.cwAcc.k end) end
    if S.wwAcc and ww then pcall(function() ww._accentKey = S.wwAcc.k end) end
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
-- part 1 of the scene, in memory only (the save held first: a save now would write Lite into the player's file)
Q.waitFor(5, 300, function() return not S.go or not RT.isOpen() end, function(ok)
    if not S.go then return end
    if not ok then Q.say("the windows did not shut; the run goes on with them open") end
    if not H.holdSave() then
        Q.skip("Reset to defaults in Lite (7d8dc58ce)", "the game's save of ModOptions.ini could not be held, so Style Lite is not staged (a save would write it)")
        S.go = false
        return
    end
    S.stagedDone = true    -- (first: a staging that threw part way still gets every value put back)
    local n, moved, none, kept = H.stage()
    S.kept = kept
    pcall(function() if St.forgetHeldCustom then St.forgetHeldCustom() end end)
    pcall(St.reapplyFromOptions)
    Q.say("scene, part 1: " .. n .. " ZeD settings staged in memory, " .. #moved .. " moved (" .. H.list(moved) .. "); no default found for: " .. H.list(none)
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

-- ===================================================================== part 1: only Style off its default
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
    local what = "7d8dc58ce: in Lite with every other setting on its default, Reset to defaults (bottom row, by Back) is gray: Style alone does not count"
    if #addon > 0 or #(S.kept or {}) > 0 then
        -- (another mod's setting off its own default, or a screen switch a mod holds left on, keeps the button live on any
        -- code: no proof either way)
        Q.skip(what, "the button is live whatever Style does: an add-on's row off its own default (" .. H.list(addon)
            .. "), a screen switch a mod holds left as found (" .. H.list(S.kept or {}) .. ")")
        return
    end
    local b = H.spec("defaults")
    local live = nil
    pcall(function() live = w:zedOffDefault() and true or false end)
    -- (9251ebdf6 alone: live. Style's default counted, and Style sat on Lite. QA review: Style must have its default and
    -- be off it, or a gray button proves nothing: before 9251ebdf6 it was gray because Style had no default)
    local styleOff = row.zedDefault ~= nil and el ~= nil and el.selected ~= row.zedDefault
    Q.check(styleOff and b ~= nil and b.disabled == true and live == false, what,
        "button drawn " .. tostring(b ~= nil) .. ", gray " .. tostring(b and b.disabled) .. ", something off its default " .. tostring(live)
        .. "; the Style row reads " .. tostring(el and el.selected) .. ", its default " .. tostring(row.zedDefault)
        .. ", left alone by Defaults (zedNoReset) " .. tostring(row.zedNoReset == true))
end)

-- ===================================================================== part 2: one ordinary setting off its default too
-- (Back with nothing changed, as a player leaves ZeD setup; the setting stored while the pause menu shows; then Options
-- again, which takes every value afresh as any open does: ZeD_MMOptions:onShow)
Q.step(2, function()
    if not S.go then return end
    local w = H.W()
    S.backHow = "Back"
    S.backPlain = true
    -- (nothing should wait here; if something does, it goes first, so Back leaves at once instead of asking, and check
    -- "again", which claims a plain Back, fails)
    if w.confirm or w:anyChanged() then
        S.backPlain = false
        S.backHow = "Discard changes first (confirm " .. tostring(w.confirm) .. ", changes waiting " .. tostring(w:anyChanged()) .. "), then Back"
        pcall(function() w:discardStay() end)
    end
    pcall(function() w:back() end)
end)
Q.waitFor(2, 120, function() return not S.go or not H.optsUp() end, function(ok)
    if not S.go then return end
    S.backOk = ok and true or false
    if not ok then return end
    local staged, info = H.stageExtra()
    if not staged then
        -- (a change in Settings.lua, or a control off its stored value, stops it: Options is not opened again, every
        -- check after it is left out, and the put-back runs)
        S.go = Q.check(false, "part 2 of the scene: " .. X.name .. " stored On, the preset row on the preset those values make", tostring(info))
        return
    end
    Q.say("scene, part 2: " .. X.name .. " (" .. X.id .. ") stored " .. tostring(H.val(X.id)) .. ", the preset row stored " .. tostring(H.val("additionsPreset"))
        .. " (the preset the stored additions make: " .. tostring(info) .. "), extras off Vanilla " .. tostring(H.offVanilla()) .. ", Lite " .. tostring(H.lite())
        .. ", pause menu up " .. tostring(H.menuUp()))
    pcall(MM.openOptions)
end)
Q.waitFor(5, 300, function() return not S.go or not S.backOk or H.optsUp() end, function()
    if not S.go then return end
    local up = (S.backOk and H.optsUp()) and true or false
    Q.check(up and S.backPlain == true, "ZeD's Options closes with Back (nothing waiting) and opens again from the pause menu",
        "left with " .. tostring(S.backHow) .. ", closed " .. tostring(S.backOk) .. ", open again " .. tostring(H.optsUp()))
    S.go = up
    if not S.go then return end
    local w = H.W()
    pcall(function() for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end end)
    w.scroll = 0
    w.focusId = nil
    H.park()
end)
Q.step(6, function()
    if not S.go then return end
    local w = H.W()
    H.park()
    local pg = nil
    pcall(function() pg = w:pages()[w.pageIdx] end)
    local onSetup = pg ~= nil and pg.setup == true
    local row, el = H.rowOf("lookStyle"), H.el("lookStyle")
    local xrow, xel, pel = H.rowOf(X.id), H.el(X.id), H.el("additionsPreset")
    local off = H.notStaged()
    local waiting = w:anyChanged()
    S.row, S.xrow = row, xrow
    Q.check(onSetup and row ~= nil and el ~= nil and el.selected == 2 and H.lite() and xrow ~= nil and xel ~= nil and xel.selected == X.on
        and pel ~= nil and pel.selected == S.staged.additionsPreset and #off == 0 and not waiting,
        "the scene with one setting more, " .. X.name .. " stored On (the preset row on the preset those values make), Options opened again: ZeD setup in Lite shows the Additions group with the " .. X.name .. " row reading On, the Style row reading Lite, every other ZeD setting on its default, nothing changed yet",
        "page " .. tostring(pg and pg.title) .. ", Style row " .. tostring(row ~= nil) .. " reading " .. tostring(el and el.selected) .. " (" .. H.itemText(el, el and el.selected) .. ")"
        .. ", " .. X.name .. " row " .. tostring(xrow ~= nil) .. " reading " .. tostring(xel and xel.selected) .. " (" .. H.itemText(xel, xel and xel.selected) .. ")"
        .. ", preset control " .. tostring(pel and pel.selected) .. " (" .. H.itemText(pel, pel and pel.selected) .. ")"
        .. ", controls not on the staged item: " .. H.list(off) .. ", extras off Vanilla " .. tostring(H.offVanilla()) .. ", changes waiting " .. tostring(waiting)
        .. ", screen switches a mod holds, off their default: " .. H.list(S.kept or {}))
    if not row then S.go = false; return end
    local b = H.spec("defaults")
    local live = nil
    pcall(function() live = w:zedOffDefault() and true or false end)
    Q.check(b ~= nil and not b.disabled and live == true,
        "with " .. X.name .. " On as well, Reset to defaults (bottom row, by Back) is live: it is pressed through its own button",
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
            -- (before 9251ebdf6: the row had no help key and no default, so the band drew nothing for it. 7d8dc58ce keeps
            -- Style's default, so the band still says it although Defaults leaves Style alone)
            Q.check(helpOk and defOk, "B10-1: with the pointer on the Style row the help band shows Style's help line and, at its right, '" .. tostring(B.dt) .. "' (still, though Defaults leaves Style alone)",
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
    S.pre = H.ownPicks()   -- (each of ZeD's own rows' pick just before the press: the row Defaults leaves alone is held to it)
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
    local mark = H.marked(w, row)
    local waiting = w:anyChanged()
    -- (9251ebdf6 alone: the Style row read Full, a change waiting with its changed mark)
    Q.check(S.defOk == true and sel == 2 and mark == false and H.val("lookStyle") == 2 and H.lite(),
        "7d8dc58ce: after Reset to defaults the Style row still reads Lite with no changed mark (nothing waits for it), and the stored Style is still Lite",
        "Style control " .. tostring(sel) .. " (" .. H.itemText(el, sel) .. "), changed mark " .. tostring(mark) .. ", stored Style " .. tostring(H.val("lookStyle"))
        .. ", pressed through " .. tostring(S.defHow))
    local xo, po = H.opt(X.id), H.opt("additionsPreset")
    local xel, pel = xo and xo.element, po and po.element
    local xdef, pdef = xo and H.defOf(xo), po and H.defOf(po)
    local xsel, psel = xel and xel.selected, pel and pel.selected
    local xmark = H.marked(w, H.rowOf(X.id) or S.xrow)
    local pmark = H.marked(w, H.rowOf("additionsPreset"))
    Q.check(S.defOk == true and xdef ~= nil and xsel == xdef and xmark == true and pdef ~= nil and psel == pdef and waiting and H.val(X.id) == X.on,
        "after Reset to defaults the " .. X.name .. " row is back on its default (Off) with its changed mark and the preset row on its default (Vanilla), a change waiting for Apply (the stored " .. X.name .. " still On: nothing applied)",
        X.name .. " control " .. tostring(xsel) .. " (" .. H.itemText(xel, xsel) .. ", default " .. tostring(xdef) .. "), changed mark " .. tostring(xmark)
        .. "; preset control " .. tostring(psel) .. " (" .. H.itemText(pel, psel) .. ", default " .. tostring(pdef) .. "), changed mark " .. tostring(pmark)
        .. "; changes waiting " .. tostring(waiting) .. ", stored " .. X.name .. " " .. tostring(H.val(X.id)))
    local b = H.spec("defaults")
    local live = nil
    pcall(function() live = w:zedOffDefault() and true or false end)
    -- (9251ebdf6 alone: gray as well, but only because Style went to Full; this check needs Style still on Lite, off the
    -- default its row has, so the gray proves Style does not count; before 9251ebdf6 the row had no default)
    local sdef = row and row.zedDefault
    Q.check(b ~= nil and b.disabled == true and live == false and sel == 2 and sdef ~= nil and sel ~= sdef,
        "7d8dc58ce: after Reset to defaults the button grays while Style still reads Lite: nothing that counts is left off its default",
        "button drawn " .. tostring(b ~= nil) .. ", gray " .. tostring(b and b.disabled) .. ", something off its default " .. tostring(live)
        .. ", Style control " .. tostring(sel) .. " (" .. H.itemText(el, sel) .. "), its default " .. tostring(sdef))
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
    local xrow, xel = H.rowOf(X.id) or S.xrow, H.el(X.id)
    local lo, moved = H.liveOff(), H.storedMoved()
    local mark, xmark = H.marked(w, row), H.marked(w, xrow)
    local waiting = w:anyChanged()
    local same, sameHow = H.fileSame("ModOptions.ini", S.ini0, S.iniState)
    -- (no Ammo on the belt row is the scene's fault, said by its own check: here only a mark it shows counts)
    Q.check(#lo == 0 and el ~= nil and el.selected == 2 and mark == false and xel ~= nil and xel.selected == X.on and xmark ~= true
        and not waiting and not w.confirm and #moved == 0 and H.lite() and H.val(X.id) == X.on and S.saves == 0 and same ~= false,
        "Discard changes puts every row back on its stored pick (Style reads Lite, " .. X.name .. " On again, no changed mark) and nothing was applied (the stored Style still Lite, nothing saved)",
        "through " .. tostring(S.discHow) .. "; controls off their stored pick: " .. H.list(lo) .. ", Style control " .. tostring(el and el.selected)
        .. ", changed mark " .. tostring(mark) .. ", " .. X.name .. " control " .. tostring(xel and xel.selected) .. ", changed mark " .. tostring(xmark)
        .. ", changes waiting " .. tostring(waiting) .. ", stored values moved: " .. H.list(moved)
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
