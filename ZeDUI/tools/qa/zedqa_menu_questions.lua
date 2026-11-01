-- ZeDUI/tools/qa/zedqa_menu_questions.lua  (Nov 1 2026)
-- Main menu QA: B on a question goes back to the stop that asked (commit 7bca987, the director's
-- rule; t15 pre-upload). Each page's question is opened from a known pad stop, through the
-- screen's own pad handlers (MM.joyDown / the window's joyA, joyB, joyY; no real pad), then:
--   a  the question is up and the focus is on its default answer (confirm:yes)
--   b  B again cancels it: the focus is back on the stop it came from, the page still open
-- Pages and their questions:
--   Options    a setting changed (a Gameplay tick), B asks before leaving ("back")
--   Workshop   a tag ticked on the picked folder, B asks before leaving ("leave")
--   Server     a tick changed on the edit page, B asks before leaving ("discard")
--   Host       no leave question (B leaves): the world's upkeep question instead (reset /
--              delete), opened with A on its button, when a hosted world exists
--   Sandbox    no leave question (B leaves; vanilla's BACK keeps the values): the preset menu's
--              Load over changes instead (a tick changed, Y, a different preset, A)
--   Traits     no leave question (B leaves): Builds..., Save build... (Y, A) instead
--   Looks      no leave question (B leaves): Outfits..., Save outfit... (Y, A) instead
-- Puts back: Options through Discard changes (vanilla's No), checked again after reopening;
-- Workshop through the question's Discard changes (the folder read again from workshop.txt);
-- Server by A on the same stop (the tick back, nothing changed), then Cancel (never Save);
-- Sandbox by A on the same stop (the tick back, the preset never loaded); Traits / Looks and
-- Host answer Cancel (nothing written). Never Apply, Save, Upload, Load, Reset or Delete.
-- Server, Sandbox, Traits and Looks are skipped when the menu's mods already need a Lua reload
-- (leaving them would reload Lua and end the run). Shots: zqa_mmq_*.png, each question open.
--
-- Run (never while the game runs; checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/compat_r4_mods.txt `
--        -Script ZeDUI/tools/qa/zedqa_menu_questions.lua -Tag mmq -TimeoutSec 300
-- Lines: "ZEDQA mmq PASS ..." / "ZEDQA mmq FAIL ..." / "ZEDQA mmq SKIP ...", then a total and DONE.
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA mmq " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mmq_" .. n .. ".png") end); say("shot zqa_mmq_" .. n .. ".png") end
local pass, fail = 0, 0
local function check(ok, what)
    if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end
    return ok
end
local steps, T0 = {}, 0
local function after(d, fn) T0 = T0 + d; steps[#steps + 1] = { n = T0, fn = fn } end
local JP = Joypad
local keep = {}

-- (MM.joyDown takes vanilla's MainScreen, as its overrides pass it: MM.isUp reads its bottomPanel; MM.root has none)
local function ms() return MainScreen.instance end
local function pressA() MM.joyDown(ms(), JP.AButton) end
local function pressB() MM.joyDown(ms(), JP.BButton) end
local function pressY() MM.joyDown(ms(), JP.YButton) end
local function win(view)
    for _, rv in ipairs(MM.views) do if rv.view == view then return MM.root[rv.field] end end
    return nil
end
local function firstSpec(w, pred)
    for _, s in ipairs(w and w._specs or {}) do if not s.disabled and pred(s) then return s end end
    return nil
end
local function jlist(l) local t = {}; if l then for i = 0, l:size() - 1 do t[#t + 1] = tostring(l:get(i)) end end; return t end
local function sorted(t) table.sort(t); return table.concat(t, ";") end
local function readRaw(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local t = {}
    local line = r:readLine()
    while line do t[#t + 1] = line; line = r:readLine() end
    r:close()
    return table.concat(t, "\n")
end
local function ticked(c) return c and c.selected and c.selected[1] == true end
local function empty(t) for _ in pairs(t or {}) do return false end; return true end

-- the open pop-up's live entry that pred picks: the controller's focus on it, then A
local function dropPick(pred)
    for i, it in ipairs(MM.dropLive()) do
        if pred(i, it) then MM.ctx.dropFocus = i; pressA(); return it end
    end
    return nil
end

-- the two checks every page makes
local function askCheck(tag, page, w, mode, how)
    local ok = w.confirm == mode and w.focusId == "confirm:yes"
    check(ok, tag .. "a " .. page .. ": " .. how .. " (" .. tostring(mode) .. "), the focus on its default answer")
    if not ok then say("   " .. page .. " confirm " .. tostring(w.confirm) .. ", focus " .. tostring(w.focusId)) end
    return ok
end
local function backCheck(tag, page, w, view, from)
    say("NOTE " .. page .. ": after the question the focus is " .. tostring(w.focusId) .. " (asked from " .. tostring(from) .. ")")
    local ok = (not w.confirm) and w.focusId == from and from ~= nil and MM.view == view
    check(ok, tag .. "b " .. page .. ": B again cancels; the focus back on the stop that asked, the page still open")
    if not ok then say("   " .. page .. " confirm " .. tostring(w.confirm) .. ", focus " .. tostring(w.focusId) .. ", view " .. tostring(MM.view)) end
    return ok
end

-- ============================================================================
-- SET-UP
-- ============================================================================
after(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    keep.fg = MM.forceGamepad
    MM.forceGamepad = true     -- (the focus paints in the shots; the handlers do not read it)
    MM.ctx.open = nil
    local ok, need = pcall(function() return ActiveMods.requiresResetLua(ActiveMods.getById("default")) end)
    keep.resetNeeded = (not ok) or need == true
    say("the menu's mods need a Lua reload already: " .. tostring(keep.resetNeeded))
    MM.showView("main")
end)

-- ============================================================================
-- 1. OPTIONS: a Gameplay tick changed, B asks before leaving
-- ============================================================================
local OPT_PICK = { autoDrink = true, keyInIgnition = true, autoWalkContainer = true, timedActionGameSpeedReset = true,
                   mapViewPause = true, dropItemsOnSquareCenter = true, showCursorWhileAiming = true,
                   panCameraWhileAiming = true, panCameraWhileDriving = true }
after(5, function() MM.openOptions() end)
after(20, function()
    local w = MM.root.optsWin
    if MM.view ~= "options" then say("SKIP Options (the window did not open: view " .. tostring(MM.view) .. ")"); return end
    for i, p in ipairs(w:pages()) do if p.raw == "gameplay" then w.pageIdx = i end end
    w.scroll, w.focusId = 0, nil
    keep.o = true
end)
after(10, function()
    if not keep.o then return end
    local w = MM.root.optsWin
    local s = firstSpec(w, function(x)
        local r = x.rowRef
        return r and r.kind == "tick" and r.opt and OPT_PICK[r.opt.name] and not r.moot and #(r.control.options or {}) == 1
    end)
    if not s then say("SKIP Options (no plain Gameplay tick on the page)"); keep.o = nil; return end
    keep.oRow, keep.oFrom, keep.oVal = s.rowRef, s.id, ticked(s.rowRef.control)
    keep.oChanged0 = w:anyChanged()
    say("Options stop " .. s.id .. " = " .. tostring(s.rowRef.opt.name) .. " (" .. tostring(keep.oVal) .. "), changes waiting before: " .. tostring(keep.oChanged0))
    w.focusId, w._tickCol = s.id, 1
    pressA()
    check(ticked(keep.oRow.control) == not keep.oVal and w:anyChanged(), "1 Options: A on " .. tostring(s.rowRef.opt.name) .. " changes it (a change waiting)")
end)
after(5, function()
    if not keep.o then return end
    pressB()
    askCheck("1", "Options", MM.root.optsWin, "back", "B with a change waiting asks first")
end)
after(3, function() if keep.o then shot("01_options") end end)
after(5, function()
    if not keep.o then return end
    pressB()
    backCheck("1", "Options", MM.root.optsWin, "options", keep.oFrom)
end)
-- put back: Discard changes (vanilla's No: the live values restored), the window closes
after(5, function()
    if not keep.o then return end
    local w = MM.root.optsWin
    if w.confirm then w:setConfirm(false) end
    w:discard()
    check(MM.view == "main" and not w:anyChanged() and ticked(keep.oRow.control) == keep.oVal, "1c Options: Discard changes puts the setting back and closes")
end)
after(10, function() if keep.o then MM.openOptions() end end)
after(20, function()
    if not keep.o then return end
    local w = MM.root.optsWin
    check(MM.view == "options" and ticked(keep.oRow.control) == keep.oVal and w:anyChanged() == keep.oChanged0,
          "1d Options opened again: the setting reads as before (nothing applied)")
    w:back()
end)
after(10, function() if keep.o and MM.view ~= "main" then say("Options left on " .. tostring(MM.view)); MM.showView("main") end end)

-- ============================================================================
-- 2. WORKSHOP: a tag ticked, B asks before leaving; Discard changes
-- ============================================================================
local function wsState(w)
    local it = w:item()
    if not it then return "" end
    return table.concat({ tostring(it:getTitle()), tostring(it:getVisibilityInteger()), sorted(jlist(it:getTags())),
                          tostring(#tostring(it:getDescription() or "")), tostring(it:getChangeNote()) }, " | ")
end
after(5, function() MM.act.workshop() end)
after(25, function()
    local w = win("workshop")
    if MM.view ~= "workshop" or not w then say("SKIP Workshop (the window did not open: view " .. tostring(MM.view) .. ")"); return end
    if #(w.items or {}) == 0 then say("SKIP Workshop (no staged folder in Zomboid/Workshop)"); return end
    if not empty(w.unsaved) then say("SKIP Workshop (edits already waiting)"); return end
    keep.wsState, keep.wsKeep = wsState(w), readRaw("ZeD_workshop.txt")
    local s = firstSpec(w, function(x) return tostring(x.id):sub(1, 4) == "tag:" end)
        or firstSpec(w, function(x) return tostring(x.id):sub(1, 4) == "vis:" and x.id ~= "vis:" .. tostring(w.vis) end)
    if not s then say("SKIP Workshop (no tag or visibility stop)"); return end
    keep.ws, keep.wsFrom = true, s.id
    say("Workshop stop " .. s.id .. " on " .. tostring(w:item():getFolderName()))
    w.focusId = s.id
    pressA()
    check(w:isUnsaved() and true or false, "2 Workshop: A on " .. s.id .. " is an edit waiting to be saved")
end)
after(5, function()
    if not keep.ws then return end
    pressB()
    askCheck("2", "Workshop", win("workshop"), "leave", "B with an edit waiting asks first")
end)
after(3, function() if keep.ws then shot("02_workshop") end end)
after(5, function()
    if not keep.ws then return end
    pressB()
    backCheck("2", "Workshop", win("workshop"), "workshop", keep.wsFrom)
end)
-- put back: the question again, its Discard changes (confirm:no) through A
after(5, function()
    if not keep.ws then return end
    pressB()
end)
after(4, function()
    if not keep.ws then return end
    local w = win("workshop")
    if w.confirm ~= "leave" then check(false, "2c Workshop: the question did not open again to discard"); return end
    w.focusId = "confirm:no"
    pressA()
    check(MM.view == "main" and empty(w.unsaved) and not w.confirm, "2c Workshop: Discard changes leaves, nothing waiting")
end)
after(10, function()
    if not keep.ws then return end
    local w = win("workshop")
    local now = wsState(w)
    if now ~= keep.wsState then say("   was [" .. tostring(keep.wsState) .. "] now [" .. now .. "]") end
    check(now == keep.wsState and readRaw("ZeD_workshop.txt") == keep.wsKeep, "2d Workshop: the folder's title, visibility, tags, description, note and ZeD_workshop.txt as before")
end)

-- ============================================================================
-- 3. SERVER SETTINGS (from Host): a tick changed on the edit page, B asks before leaving
-- ============================================================================
-- (the mods step's NEXT reloads Lua when the server's mods differ from the menu's; the edit page is
-- opened the way vanilla's no-reload branch does instead: nothing is saved, Cancel leaves it)
local function needsReload(cw)
    local loaded = {}
    local l = getActivatedMods()
    for i = 0, l:size() - 1 do if l:get(i) ~= "ZeD_UI" then loaded[#loaded + 1] = l:get(i) end end
    local want = {}
    for _, it in ipairs(cw.listbox.items or {}) do if it.item.modID ~= "ZeD_UI" then want[#want + 1] = it.item.modID end end
    if #loaded ~= #want then return true end
    for i = 1, #want do if loaded[i] ~= want[i] then return true end end
    return false
end
local function srvNext(sw, cw)
    if not needsReload(cw) then sw:act("next"); return end
    say("NOTE Server: the server's mods differ from the menu's; the edit page opens without the Lua reload")
    local orig = ActiveMods.requiresResetLua
    ActiveMods.requiresResetLua = function() return false end
    local ok, err = pcall(function() cw:onButtonNext() end)
    ActiveMods.requiresResetLua = orig
    if not ok then say("   " .. tostring(err)) end
end
-- the first page with a tick that is no group's "defaults" box and not greyed
local function srvTickPage(sw)
    for i, p in ipairs(sw:pages()) do
        if not p.head then
            for _, r in ipairs(sw:rowsFor(p)) do
                if r.kind == "tick" and not r.groupTick and r.name and not sw:rowDisabled(r) then return i, r end
            end
        end
    end
    return nil
end

after(5, function() MM.showView("main"); MM.act.host() end)
after(25, function()
    if MM.view ~= "host" then say("SKIP Host and Server (Host did not open: view " .. tostring(MM.view) .. ")"); return end
    keep.h = true
    if keep.resetNeeded then say("SKIP Server (the menu's mods need a Lua reload: leaving the editor would reload Lua)"); return end
    win("host"):editSettings()
end)
after(25, function()
    if not keep.h or keep.resetNeeded then return end
    local sw = win("srvset")
    local S = ServerSettingsScreen.instance
    local p1 = S and S.pageStart
    if MM.view ~= "srvset" or sw:mode() ~= "list" then say("SKIP Server (the settings list did not open: view " .. tostring(MM.view) .. ")"); return end
    if not (p1.listbox.items[p1.listbox.selected]) then say("SKIP Server (no server settings to edit; making some writes files)"); keep.sList = true; return end
    keep.sList = true
    say("Server settings: " .. tostring(p1.listbox.items[p1.listbox.selected].text))
    sw:act("edit")
end)
after(20, function()
    if not keep.sList then return end
    local sw = win("srvset")
    if sw:mode() ~= "mods" then return end
    srvNext(sw, ServerSettingsScreen.instance.pageEdit.chooseModsWindow)
end)
after(30, function()
    if not keep.sList then return end
    local sw = win("srvset")
    if sw:mode() ~= "edit" then say("SKIP Server (the edit page did not open: " .. tostring(sw:mode()) .. ")"); return end
    local i, r = srvTickPage(sw)
    if not i then say("SKIP Server (no tick on the edit pages)"); return end
    sw:selectPage(i)
    sw.scroll, sw.focusId = 0, nil
    keep.sRow, keep.s = r, true
end)
after(10, function()
    if not keep.s then return end
    local sw = win("srvset")
    local s = firstSpec(sw, function(x) return x.rowRef == keep.sRow end)
    if not s then say("SKIP Server (the tick's row has no stop)"); keep.s = nil; return end
    keep.sFrom, keep.sVal = s.id, ticked(keep.sRow.control)
    say("Server stop " .. s.id .. " = " .. tostring(keep.sRow.name) .. " (" .. tostring(keep.sVal) .. ")")
    sw.focusId, sw._tickCol = s.id, 1
    pressA()
    check(ticked(keep.sRow.control) == not keep.sVal and sw:anyChanged(), "3 Server: A on " .. tostring(keep.sRow.name) .. " changes it (a change waiting)")
end)
after(5, function()
    if not keep.s then return end
    pressB()
    askCheck("3", "Server", win("srvset"), "discard", "B with a change waiting asks first")
end)
after(3, function() if keep.s then shot("03_server") end end)
after(5, function()
    if not keep.s then return end
    local sw = win("srvset")
    pressB()
    backCheck("3", "Server", sw, "srvset", keep.sFrom)
    check(sw:mode() == "edit", "3c Server: still on the edit page")
end)
-- put back: A on the same stop (the tick back), then B leaves through Cancel (never Save)
after(5, function()
    if not keep.s then return end
    local sw = win("srvset")
    pressA()
    check(ticked(keep.sRow.control) == keep.sVal and not sw:anyChanged(), "3d Server: A on the same stop puts the tick back (nothing changed)")
    if sw:anyChanged() then sw:setConfirm(false); sw.dirty = false; sw.nDiff = 0 end   -- (Cancel either way: never Save)
    pressB()
end)
after(20, function()
    if not keep.sList then return end
    local sw = win("srvset")
    if keep.s then check(MM.view == "srvset" and sw:mode() == "list", "3e Server: Cancel back to the settings list (nothing saved)") end
    if sw:mode() == "edit" then sw:setConfirm(false); sw.dirty = false; sw.nDiff = 0; sw:act("back") end
    if sw:mode() == "mods" then sw:act("back") end
end)
after(15, function()
    if not keep.sList then return end
    local sw = win("srvset")
    if MM.view == "srvset" then sw:act("back") end
end)

-- ============================================================================
-- 4. HOST: no leave question; the world's upkeep question (Cancel only)
-- ============================================================================
after(25, function()
    if not keep.h then return end
    if MM.view ~= "host" then say("SKIP Host (not back on Host: view " .. tostring(MM.view) .. ")"); keep.h = nil; return end
    say("SKIP Host leave question (Host has none: B leaves at once)")
    local hw = win("host")
    local s = firstSpec(hw, function(x) return x.id == "reset" end)
        or firstSpec(hw, function(x) return x.id == "delPlayer" end)
        or firstSpec(hw, function(x) return x.id == "delWorld" end)
    if not s then say("SKIP Host world question (no hosted world yet: Reset / Delete are greyed)"); return end
    keep.hq, keep.hFrom = true, s.id
    hw.focusId = s.id
    pressA()
    askCheck("4", "Host", hw, ({ reset = "reset", delPlayer = "deletePlayer", delWorld = "deleteWorld" })[s.id], "A on " .. s.id .. " asks first")
end)
after(3, function() if keep.hq then shot("04_host") end end)
after(5, function()
    if not keep.hq then return end
    pressB()
    backCheck("4", "Host", win("host"), "host", keep.hFrom)
end)
after(5, function()
    if not keep.h then return end
    pressB()
end)
after(20, function()
    if not keep.h then return end
    check(MM.view == "main", "4c Host: B leaves to the menu")
    if MM.view ~= "main" then MM.showView("main") end
end)

-- ============================================================================
-- 5. NEW GAME: Sandbox, Traits, Looks (the way New game goes)
-- ============================================================================
after(10, function()
    if keep.resetNeeded then say("SKIP Sandbox, Traits and Looks (the menu's mods need a Lua reload: leaving New game would reload Lua)"); return end
    MM.showView("newgame")
    local nw = MM.root.newWin
    for i, d in ipairs(nw:items()) do if d.mode == "Sandbox" then nw.sel = i end end
    nw:next()
    keep.ng = true
end)
after(30, function()
    if not keep.ng then return end
    if MM.view ~= "spawn" then say("SKIP Sandbox, Traits and Looks (map / spawn did not open: view " .. tostring(MM.view) .. ")"); return end
    win("spawn"):next()
end)

-- SANDBOX: a tick changed; Y, a different preset, A: Load asks first
local SB_AVOID = { ["Map.AllowWorldMap"] = true, ["MultiplierConfig.GlobalToggle"] = true }
local function sbTickPage(w)
    for i, p in ipairs(w:pages()) do
        for _, r in ipairs(w:rowsFor(p)) do
            if r.kind == "tick" and r.name and not SB_AVOID[r.name] and not w:rowDisabled(r) then return i, r end
        end
    end
    return nil
end
after(30, function()
    if not keep.ng then return end
    if MM.view ~= "sandbox" then say("SKIP Sandbox, Traits and Looks (Sandbox did not open: view " .. tostring(MM.view) .. ")"); keep.ng = nil; return end
    say("SKIP Sandbox leave question (Sandbox has none: B leaves, vanilla's BACK keeps the values)")
    local w = win("sandbox")
    local i, r = sbTickPage(w)
    if not i then say("SKIP Sandbox preset question (no tick on any page)"); return end
    w.pageIdx, w.scroll, w.focusId = i, 0, nil
    keep.sbRow = r
end)
after(10, function()
    if not keep.sbRow then return end
    local w = win("sandbox")
    local sp = MainScreen.instance.sandOptions
    local s = firstSpec(w, function(x) return x.rowRef == keep.sbRow end)
    if not s or #(sp.presets or {}) < 2 then say("SKIP Sandbox preset question (no stop for the tick, or one preset only)"); keep.sbRow = nil; return end
    w:refreshDiff(true)
    keep.sbFrom, keep.sbVal, keep.sbN, keep.sbPreset = s.id, ticked(keep.sbRow.control), w.nDiff, sp.presetList.selected
    say("Sandbox stop " .. s.id .. " = " .. tostring(keep.sbRow.name) .. " (" .. tostring(keep.sbVal) .. "), " .. keep.sbN .. " differ from the preset")
    w.focusId, w._tickCol = s.id, 1
    pressA()
    w:refreshDiff(true)
    if not w:anyChanged() then say("SKIP Sandbox preset question (the tick left nothing changed)"); keep.sbUndo = true; return end
    check(ticked(keep.sbRow.control) == not keep.sbVal, "5 Sandbox: A on " .. tostring(keep.sbRow.name) .. " changes it")
    keep.sb = true
    pressY()
    check(MM.ctx.open == "presets", "5 Sandbox: Y opens the presets menu")
end)
after(5, function()
    if not keep.sb then return end
    local w = win("sandbox")
    local sp = MainScreen.instance.sandOptions
    local n = #sp.presets
    local it = dropPick(function(i) return i <= n and i ~= keep.sbPreset end)
    say("Sandbox picks preset " .. tostring(it and it.text))
    askCheck("5", "Sandbox", w, "load", "another preset over changes asks first")
end)
after(3, function() if keep.sb then shot("05_sandbox") end end)
after(5, function()
    if not keep.sb then return end
    local w = win("sandbox")
    pressB()
    backCheck("5", "Sandbox", w, "sandbox", keep.sbFrom)
    check(MainScreen.instance.sandOptions.presetList.selected == keep.sbPreset, "5c Sandbox: the preset not loaded")
    keep.sbUndo = true
end)
-- put back: A on the same stop, the tick as it was
after(5, function()
    if not keep.sbUndo then return end
    local w = win("sandbox")
    w.focusId, w._tickCol = keep.sbFrom, 1
    pressA()
    w:refreshDiff(true)
    check(ticked(keep.sbRow.control) == keep.sbVal and w.nDiff == keep.sbN, "5d Sandbox: A on the same stop puts the tick back (as many differ from the preset as before)")
end)
after(10, function()
    if not keep.ng then return end
    local w = win("sandbox")
    w.focusId = nil
    w:next()
end)

-- TRAITS: Y, Save build..., A: the name question
after(30, function()
    if not keep.ng then return end
    if MM.view ~= "traits" then say("SKIP Traits and Looks (Traits did not open: view " .. tostring(MM.view) .. ")"); keep.ng = nil; return end
    say("SKIP Traits leave question (Traits has none: B leaves)")
    local w = win("traits")
    w:setJoy(1, w.jidx or 1)
    keep.tFrom = w.focusId
    local p = MainScreen.instance.charCreationProfession
    keep.tBuilds = #(p.savedBuilds.options or {})
    pressY()
    if MM.ctx.open ~= "builds" then check(false, "6 Traits: Y opens Builds..."); return end
    local it = dropPick(function(_, x) return x.text == ZeD.tr("UI_ZeD_Traits_SaveBuild") end)
    if not it then check(false, "6 Traits: Save build... in the menu"); MM.ctx.open = nil; return end
    keep.t = true
    askCheck("6", "Traits", w, "save", "Save build... asks for a name")
end)
after(3, function() if keep.t then shot("06_traits") end end)
after(5, function()
    if not keep.t then return end
    local w = win("traits")
    pressB()
    backCheck("6", "Traits", w, "traits", keep.tFrom)
    local p = MainScreen.instance.charCreationProfession
    check(#(p.savedBuilds.options or {}) == keep.tBuilds and not w.field:isFocused(), "6c Traits: no build saved, the name field let go")
end)
after(5, function()
    if not keep.ng then return end
    local w = win("traits")
    w.focusId = nil
    w:next()
end)

-- LOOKS: Y, Save outfit..., A: the name question
after(30, function()
    if not keep.ng then return end
    if MM.view ~= "looks" then say("SKIP Looks (Looks did not open: view " .. tostring(MM.view) .. ")"); return end
    say("SKIP Looks leave question (Looks has none: B leaves)")
    local w = win("looks")
    local s = firstSpec(w, function(x) return x.rowRef and x.rowRef.kind ~= "name" end)
    if not s then say("SKIP Looks question (no row stop)"); return end
    keep.lFrom = s.id
    w.focusId = s.id
    local v = MainScreen.instance.charCreationMain
    keep.lOutfits = #(v.savedBuilds.options or {})
    pressY()
    if MM.ctx.open ~= "outfits" then check(false, "7 Looks: Y opens Outfits..."); return end
    local it = dropPick(function(_, x) return x.text == ZeD.tr("UI_ZeD_Looks_SaveOutfit") end)
    if not it then check(false, "7 Looks: Save outfit... in the menu"); MM.ctx.open = nil; return end
    keep.l = true
    askCheck("7", "Looks", w, "save", "Save outfit... asks for a name")
end)
after(3, function() if keep.l then shot("07_looks") end end)
after(5, function()
    if not keep.l then return end
    local w = win("looks")
    pressB()
    backCheck("7", "Looks", w, "looks", keep.lFrom)
    local v = MainScreen.instance.charCreationMain
    check(#(v.savedBuilds.options or {}) == keep.lOutfits and not w.field:isFocused(), "7c Looks: no outfit saved, the name field let go")
end)

-- back out the way New game came: Looks, Traits, Sandbox, map / spawn, New game
local BACK_CHAIN = { "looks", "traits", "sandbox", "spawn" }
for _, v in ipairs(BACK_CHAIN) do
    after(15, function()
        if not keep.ng or MM.view ~= v then return end
        local w = win(v)
        if w.confirm then w:setConfirm(false) end
        w:back()
    end)
end
after(15, function()
    if not keep.ng then return end
    if MM.view == "newgame" then MM.root.newWin:back() end
end)
after(20, function()
    if keep.ng then check(MM.view == "main", "8 New game: back to the menu the way it came (view " .. tostring(MM.view) .. ")") end
end)

-- ============================================================================
-- END
-- ============================================================================
after(10, function()
    MM.forceGamepad = keep.fg
    MM.ctx.open = nil
    if MM.view ~= "main" then MM.showView("main") end
    say(string.format("view=%s; %d passed, %d failed", tostring(MM.view), pass, fail))
    say("DONE")
end)

local tick = 0
local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > T0 + 20 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
