-- ZeDUI/tools/qa/zedqa_b8_mainmenu.lua  (Nov 7 2026, QA; tag b8mm)
-- AT THE MAIN MENU, no game loaded (OnFETick: the main menu has no OnTick). ZeD must be on. Run it with
--   pwsh -File ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList <an empty file> -Script ZeDUI/tools/qa/zedqa_b8_mainmenu.lua -Tag b8mm -TimeoutSec 400
-- (zedqa_run.ps1 refuses a script that uses OnFETick; see b8_menus_review_mainmenu.txt). Set ZEDQA_NOSTEAM=1 to run without Steam
-- (then the invite becomes the connect-to form, and the server Workshop items screen is driven through its own functions).
-- Checks CHECK_mainmenu_vanilla_20261107.md and the outside review of beta 7 (items 4, 5, 6) as Build fixed them:
--   tutorial   the File menu and the main window name the Tutorial as the game's own, without mods (D1)
--   terms      the ZeD menu's Terms of service opens ZeD's window with its band; read, then closed with Back (never Accept or Quit) (A4)
--   find       Options > Find: ZeD's own options are found on ZeD setup with ZeD's controls, not as drop-downs on the Mods page (#6)
--   padpage    Options > Controls: the Button map and test page (A5)
--   sounds     Options > Audio > Advanced game sounds page (A6, rare)
--   world      World select as ZeD's window (A3), with one world only (no map mod needed); Back
--   wsitems    Server Workshop items (A1) fed the game's own calls with made-up ids; never Install; Disconnect
--   invite     the Steam invite (A2) or, without Steam, the Connect to form; Cancel (never Connect)
--   sandbox    New Game > Sandbox: the name question opens with its default selected (#5); one change saved as a preset and the preset
--              deleted: the header reads the nearest preset and 1 changed, not the last preset (#4). The preset file is removed again.
-- Every window is left with its Back / Cancel; nothing is accepted, installed, connected or saved except the one temporary sandbox preset.
-- Pictures zqa_b8_mm_<step>.png. grep "ZEDQA b8mm".
local TAG = "b8mm"
local MM = ZeD and ZeD.MainMenu
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local function ms() return MainScreen and MainScreen.instance end
local Q = { pass = 0, fail = 0, notes = {} }
local function verdict(ok, what)
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what)
    return ok
end
local function note(s) say("NOTE " .. s) end
local function shot(name)
    local ok, err = pcall(function() getCore():TakeFullScreenshot("zqa_b8_mm_" .. name .. ".png") end)
    say("shot zqa_b8_mm_" .. name .. ".png" .. (ok and "" or (" FAILED " .. tostring(err))))
end
local function view() return tostring(MM and MM.view) end
local function root() return MM and MM.root end
local function field(f) local r = root(); return r and r[f] end
local function spec(w, id)
    for _, s in ipairs(w and w._specs or {}) do if s.id == id then return s end end
    return nil
end
local function ids(w)
    local t = {}
    for _, s in ipairs(w and w._specs or {}) do if s.band then t[#t + 1] = tostring(s.id) end end
    return table.concat(t, ",")
end
local function toMain()
    local m = ms()
    local ws = m and m.worldSelect
    if ws and ws:isVisible() then pcall(function() ws:setVisible(false) end) end
    if MM.view ~= "main" then pcall(MM.showView, "main") end
    MM.ctx.open = nil
end

local S = {}   -- what one step leaves for the next
local steps = {}
local function add(name, wait, go) steps[#steps + 1] = { name = name, wait = wait or 20, go = go } end

-- ---------------------------------------------------------------------------
-- tutorial (D1)
-- ---------------------------------------------------------------------------
add("tutorial", 25, function()
    toMain()
    local want = ZeD.tr("UI_ZeD_MainMenu_TutorialVanilla")
    local found = false
    for _, it in ipairs(MM.menuItems("file")) do
        if type(it) == "table" and it.text == want and it.fn == MM.act.tutorial then found = true end
    end
    verdict(found, "D1 the File menu lists the Tutorial as the game's own (" .. tostring(want) .. ")")
    verdict(tostring(want):find("without mods", 1, true) ~= nil, "D1 the label says it runs without mods")
    local w = field("win")
    local s = spec(w, "tutorial")
    if s then
        local tw = 0
        pcall(function() tw = ZeD.TM:MeasureStringX(ZeD.T.fontF2, want) end)
        say("tutorial button " .. tostring(s.w) .. " wide, label about " .. tostring(tw) .. " at F2 (the picture decides the fit)")
        verdict(s.text == want, "D1 the main window's button reads the same label")
    else
        note("the main window has no tutorial button spec yet")
    end
    shot("01_main_tutorial")
end)

-- ---------------------------------------------------------------------------
-- terms (A4): open, read, Back
-- ---------------------------------------------------------------------------
add("terms open", 40, function() MM.act.tos() end)
add("terms read", 20, function()
    local w = field("termsWin")
    verdict(view() == "terms" and w ~= nil, "A4 the Terms of service is ZeD's window on the monitor (view " .. view() .. ")")
    if w then
        say("terms band: " .. ids(w))
        verdict(spec(w, "terms") and spec(w, "privacy") and spec(w, "accept") and spec(w, "back"), "A4 the band holds Back, the two pages and Accept")
        shot("02_terms")
        local ok, err = pcall(function() w:leave() end)   -- Back: no answer, nothing accepted
        if not ok then say("ERR terms leave: " .. tostring(err)) end
    end
end)
add("terms closed", 10, function()
    verdict(view() == "main", "A4 Back leaves the terms for the main window (view " .. view() .. ")")
    toMain()
end)

-- ---------------------------------------------------------------------------
-- Options: Find (#6), the button map page (A5), the sounds page (A6)
-- ---------------------------------------------------------------------------
add("options open", 40, function() MM.openOptions() end)
add("find", 30, function()
    local ow = field("optsWin")
    verdict(view() == "options" and ow ~= nil, "Options opened on the desk (view " .. view() .. ")")
    if not ow then return end
    S.ow = ow
    local G = MM.optionGroups
    if not (G and G.findRows) then verdict(false, "#6 MM.optionGroups.findRows exists"); return end
    local pages = ow:pages()
    local setupTitle
    for _, p in ipairs(pages) do if p.setup then setupTitle = p.title end end
    local function hay(r)
        local name = r.labelKey and ZeD.tr(r.labelKey) or ""
        return string.lower(tostring(r.label or "") .. " " .. name)
    end
    for _, q in ipairs({ "theme", "scale", "font" }) do
        local rows = G.findRows(pages, function(p) return ow:rowsFor(p) end, q, hay)
        local header, own, ownWrong, plainOnMods, n = nil, 0, 0, 0, 0
        for _, r in ipairs(rows) do
            if r.kind == "header" then header = r.text
            else
                n = n + 1
                if r.zedOwn then
                    own = own + 1
                    if header ~= setupTitle then ownWrong = ownWrong + 1 end
                    if r.zedStyle == nil and r.kind == "combo" and header ~= setupTitle then plainOnMods = plainOnMods + 1 end
                end
            end
        end
        say("find '" .. q .. "': " .. n .. " rows, " .. own .. " of ZeD's own (setup page '" .. tostring(setupTitle) .. "')")
        verdict(ownWrong == 0 and plainOnMods == 0, "#6 Find '" .. q .. "': none of ZeD's own options shows outside ZeD setup")
    end
    -- on screen, for the eye
    pcall(function() ow.find:setText("theme") end)
end)
add("find shot", 25, function()
    shot("03_options_find_theme")
    local ow = S.ow
    if ow then pcall(function() ow.find:setText("") end) end
end)
add("pad page", 15, function()
    local ow = S.ow
    if not ow then return end
    local ok, err = pcall(function() ow:openVanillaController() end)
    if not ok then say("ERR openVanillaController: " .. tostring(err)) end
end)
add("pad check", 30, function()
    local ow = S.ow
    if not ow then return end
    verdict(ow.sub == "pad", "A5 Button map and test is a page of ZeD's Options (sub " .. tostring(ow.sub) .. ")")
    local n = -1
    local ok, els = pcall(MM.padElements)
    if ok and els then n = #els end
    say("A5 parts on the drawing: " .. tostring(n) .. " (the sim expects 18 with a full pad)")
    verdict(n >= 10, "A5 the parts of the controller are listed")
    shot("04_button_map")
    pcall(function() ow:closeSub() end)
    verdict(ow.sub == nil, "A5 Back returns to the Options page")
end)
add("sounds page", 15, function()
    local ow = S.ow
    if not ow then return end
    local ok, err = pcall(function() ow:openSub("sounds") end)
    if not ok then say("ERR openSub sounds: " .. tostring(err)) end
end)
add("sounds check", 30, function()
    local ow = S.ow
    if not ow then return end
    verdict(ow.sub == "sounds", "A6 Advanced game sounds is a page of ZeD's Options (sub " .. tostring(ow.sub) .. ")")
    local cats = -1
    pcall(function() cats = GameSounds.getCategories():size() end)
    say("A6 the game lists " .. tostring(cats) .. " sound categories")
    shot("05_advanced_sounds")
    pcall(function() ow:closeSub() end)
    note("A6 only the page is checked; sliders, Play and the saved level are manual (they touch the game's sound file)")
end)
add("options closed", 10, function()
    local ow = S.ow
    if ow and ow.sub then pcall(function() ow:closeSub() end) end
    toMain()
    verdict(view() == "main", "back on the main window after Options")
end)

-- ---------------------------------------------------------------------------
-- World select (A3): one world, no map mod needed
-- ---------------------------------------------------------------------------
add("world open", 40, function()
    local m = ms()
    local wsel = m and m.worldSelect
    if not wsel then note("no WorldSelect screen on MainScreen"); return end
    MM.view = "newgame"
    pcall(function() wsel:hasChoices() end)   -- the game builds its map groups here
    local ok, err = pcall(function() wsel:fillList() end)
    if not ok then say("ERR fillList: " .. tostring(err)); return end
    wsel.previousScreen = "NewGameScreen"
    wsel:setVisible(true)
end)
add("world check", 25, function()
    local ww = field("worldWin")
    if not ww then note("no world window"); return end
    verdict(view() == "world", "A3 World select shows as ZeD's window (view " .. view() .. ")")
    local cards = 0
    pcall(function() cards = #ww:cards() end)
    verdict(cards >= 1, "A3 a card per world (" .. cards .. " here; two or more needs a map mod)")
    say("world band: " .. ids(ww))
    verdict(spec(ww, "back") and spec(ww, "next"), "A3 Back and Next in the band")
    shot("06_world_select")
    pcall(function() ww:back() end)   -- Back, never Next
end)
add("world closed", 25, function()
    say("after Back: view " .. view())
    toMain()
end)

-- ---------------------------------------------------------------------------
-- Server Workshop items (A1): the game's calls, made-up ids, no Install
-- ---------------------------------------------------------------------------
local function jlist(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
add("wsitems open", 40, function()
    local m = ms()
    local scr = m and m.serverWorkshopItem
    if not scr then note("no ServerWorkshopItemScreen on MainScreen"); return end
    -- a stand-in for the screen the join came from, so Disconnect has somewhere to go that starts nothing
    scr.prevScreen = { setVisible = function() end, getIsVisible = function() return false end }
    local ok, err = pcall(function() scr:setRequiredItems(jlist({ "1111111111", "2222222222" })) end)
    if not ok then say("ERR setRequiredItems: " .. tostring(err)) end
    S.ws = scr
end)
add("wsitems check", 25, function()
    local w = field("wsItemsWin")
    if not w then note("no Workshop items window"); return end
    verdict(view() == "wsitems", "A1 the server's Workshop items show as ZeD's window (view " .. view() .. ")")
    say("wsitems band: " .. ids(w))
    local inst = spec(w, "install")
    verdict(inst ~= nil and inst.disabled == true, "A1 Install is grayed until Steam sends the details")
    verdict(spec(w, "disconnect") ~= nil, "A1 Disconnect is in the band")
    local rows = nil
    pcall(function() rows = MM.wsItemRows(S.ws) end)
    verdict(rows ~= nil and #rows == 2, "A1 one row per mod (" .. tostring(rows and #rows) .. ")")
    shot("07_workshop_items")
    pcall(function() w:disconnect() end)   -- the game's own Disconnect; Install is never pressed
end)
add("wsitems closed", 25, function()
    say("after Disconnect: view " .. view())
    local scr = S.ws
    if scr then pcall(function() scr:setVisible(false) end) end
    toMain()
end)

-- ---------------------------------------------------------------------------
-- The invite (Steam) or the Connect to form (no Steam) (A2)
-- ---------------------------------------------------------------------------
add("invite open", 40, function()
    local m = ms()
    local bp = m and m.bootstrapConnectPopup
    if not bp then note("no BootstrapConnectPopup on MainScreen"); return end
    local ok, err = pcall(function() bp:connect("127.0.0.1", "16261", "") end)
    if not ok then say("ERR bp:connect: " .. tostring(err)) end
end)
add("invite check", 25, function()
    local v = view()
    say("A2 the launch landed on view " .. v .. " (bootstrap = a Steam invite, srvform = Connect to)")
    verdict(v == "bootstrap" or v == "srvform", "A2 the connect popup is ZeD's window")
    local w = (v == "bootstrap") and field("bootstrapWin") or field("srvFormWin")
    if w then
        say("A2 band: " .. ids(w))
        shot("08_" .. v)
        if v == "bootstrap" then pcall(function() w:back() end) else pcall(function() w:cancel() end) end   -- Cancel, never Connect
    end
end)
add("invite closed", 25, function()
    say("after Cancel: view " .. view())
    toMain()
    verdict(view() == "main", "A2 Cancel returns to the main window")
end)

-- ---------------------------------------------------------------------------
-- New Game > Sandbox: the name question and the preset delete (#4, #5)
-- ---------------------------------------------------------------------------
local TMP = "b8qa_tmp_preset"
local function needsReset()
    local r = false
    pcall(function() r = ActiveMods.requiresResetLua(ActiveMods.getById("default")) and true or false end)
    return r
end
add("newgame", 40, function()
    toMain()
    MM.act.newGame()
end)
add("newgame next", 40, function()
    local w = root() and root().newWin
    if view() ~= "newgame" or not w then note("New game did not open (view " .. view() .. ")"); S.skipSand = true; return end
    local want = GameMode and GameMode.SANDBOX and GameMode.SANDBOX:toString()
    for k, d in ipairs(w:items()) do if d.mode == want then w.sel = k end end
    pcall(function() w:next() end)
    local ws = ms() and ms().worldSelect
    if ws and ws:isVisible() then pcall(function() WorldSelect.clickNext(ws) end) end
end)
add("spawn next", 45, function()
    if S.skipSand then return end
    if view() == "sandbox" then return end
    local w = root() and root().spawnWin
    if view() ~= "spawn" or not w then note("the spawn step is not on show (view " .. view() .. ")"); S.skipSand = true; return end
    if w.nameProblem and w:nameProblem() then w.nameEntry:setText("ZeDQA" .. tostring(getTimestampMs())) end
    pcall(function() w:next() end)
end)
add("sandbox name", 20, function()
    if S.skipSand then return end
    local sw = field("sandWin")
    if view() ~= "sandbox" or not sw then note("the Sandbox step is not on show (view " .. view() .. ")"); S.skipSand = true; return end
    S.sw = sw
    sw:setConfirm("save")
    local e = sw.field
    local dflt = nil
    pcall(function() dflt = e:getInternalText() end)
    say("#5 Save as preset opens on '" .. tostring(dflt) .. "'; default recorded: " .. tostring(e._zedDefaultText))
    verdict(e._zedDefaultText ~= nil and e._zedDefaultText == dflt, "#5 the sandbox preset name is selected as it opens, so typing replaces it")
    shot("09_sandbox_name_selected")
    sw:setConfirm(false)
end)
add("sandbox preset", 20, function()
    if S.skipSand or not S.sw then return end
    local sw = S.sw
    local s = ms() and ms().sandOptions
    if not (s and s.presets) then note("no sandbox presets"); return end
    -- the first preset, a clean state
    pcall(function() sw:loadPreset(1) end)
    sw:refreshDiff(true)
    local _, base = sw:preset()
    S.base = base
    verdict(sw.nDiff == 0, "#4 preset " .. tostring(base) .. " loaded: 0 changed (" .. tostring(sw.nDiff) .. ")")
    -- one change: the first tick box that is free
    local row = nil
    for _, pg in ipairs(sw:pages()) do
        for _, r in ipairs(sw:rowsFor(pg)) do
            if not row and r.kind == "tick" and not sw:rowDisabled(r) then row = r end
        end
    end
    if not row then note("no free tick box to change: the delete check is skipped"); return end
    S.row = row
    pcall(function() sw:activateRow(row) end)
    sw:refreshDiff(true)
    verdict(sw.nDiff == 1, "#4 one change on the first preset reads 1 changed (" .. tostring(sw.nDiff) .. ")")
    -- save it as a preset, then delete it
    sw.confirm = false
    sw:setConfirm("save")
    pcall(function() sw.field:setText(TMP) end)
    pcall(function() sw:savePreset() end)
    local p, pname = sw:preset()
    S.saved = (pname == TMP)
    verdict(S.saved and p and p.userDefined, "#4 the changed values saved as a preset (" .. tostring(pname) .. ")")
end)
add("sandbox delete", 20, function()
    local sw = S.sw
    if S.skipSand or not sw or not S.saved then return end
    sw:setConfirm("delete")
    pcall(function() sw:deletePreset() end)
    S.saved = false
    sw:refreshDiff(true)
    local _, after = sw:preset()
    say("#4 after the delete the header base is '" .. tostring(after) .. "' and " .. tostring(sw.nDiff) .. " changed (base before: " .. tostring(S.base) .. ")")
    verdict(after == S.base, "#4 the base is the preset the values sit closest to, not the last preset")
    verdict(sw.nDiff == 1, "#4 it still reads 1 changed (" .. tostring(sw.nDiff) .. ")")
    shot("10_sandbox_after_delete")
end)
add("sandbox undo", 20, function()
    local sw = S.sw
    if sw and S.row then
        pcall(function() sw:activateRow(S.row) end)   -- the change back
        sw:refreshDiff(true)
        say("change put back: " .. tostring(sw.nDiff) .. " changed")
    end
    -- the temporary preset must not outlive the run
    local s = ms() and ms().sandOptions
    if s and s.presets then
        for _, p in ipairs(s.presets) do
            if p.name == TMP then
                pcall(deleteSandboxPreset, TMP)
                pcall(function() s:loadPresets() end)
                say("the temporary preset file was still there: removed")
            end
        end
    end
end)
local function backOne()
    local m = ms()
    local ws = m and m.worldSelect
    if ws and ws:isVisible() then pcall(WorldSelect.clickBack, ws); return end
    if MM.view == "main" then return end
    if MM.view == "newgame" and needsReset() then MM.showView("main"); return end
    local w = MM.activeWindow()
    if not (w and w.back) then MM.showView("main"); return end
    pcall(function() w:back() end)
    if w.confirm and MM.view ~= "main" then
        if w.finish then pcall(function() w:finish() end) else pcall(function() w:setConfirm(false) end); MM.showView("main") end
    end
end
for k = 1, 6 do add("back " .. k, 25, backOne) end
add("main again", 10, function() toMain() end)

-- ---------------------------------------------------------------------------
-- the stepper
-- ---------------------------------------------------------------------------
local n, i, cur, endAt = 0, 0, nil, nil
local function cleanUp()
    pcall(toMain)
    local s = ms() and ms().sandOptions
    if s and s.presets then
        for _, p in ipairs(s.presets) do
            if p.name == TMP then pcall(deleteSandboxPreset, TMP); pcall(function() s:loadPresets() end) end
        end
    end
    say("put back: view " .. view())
    say("summary: " .. Q.pass .. " PASS, " .. Q.fail .. " FAIL")
end
local function tick()
    n = n + 1
    if endAt then
        if n >= endAt then Events.OnFETick.Remove(tick); say("DONE") end
        return
    end
    if n == 2 then
        if not (MM and MM.root and MM.showView and MM.act and MM.activeWindow) then
            say("ERR no ZeD main menu (this script runs at the main menu with ZeD on)"); endAt = n + 8; return
        end
        if ms() and ms().inGame then say("ERR a game is loaded: this script is for the main menu"); endAt = n + 8; return end
        say("start | screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. " | steam " .. tostring(getSteamModeActive and getSteamModeActive()))
    end
    if n < 2 then return end
    if cur and (n - cur.n0) < cur.step.wait then return end
    if MM._dip then return end
    i = i + 1
    local st = steps[i]
    if not st then cleanUp(); endAt = n + 8; return end
    cur = { step = st, n0 = n }
    local ok, err = pcall(st.go)
    if not ok then say("ERR step " .. st.name .. ": " .. tostring(err)) end
end
Events.OnFETick.Add(tick)
