-- ZeDUI/tools/qa/zedqa_menu_pagelist.lua  (Nov 2 2026, QA; punch list 52, Kable's "Can't scroll down the Sandbox options")
-- At the main menu with a long mod list: the page list beside Find on the Sandbox step (New game, Sandbox playstyle,
-- each window's own next()) and on Options. The checks are zedqa_pagelist_lib.lua's: the rows inside their box and a bar
-- when they overflow; the wheel over the list to the last page and back; the bar pressed at its end, middle and top;
-- RB from the first page to the last with the picked row whole in view at every step, RB wrapping to the first and LB
-- to the last; a click on a row cut by the box's edge picks it, 2 px past the edge picks none, a click on Find picks
-- no page. The server settings' bumpers are not run here (this machine has no server settings file).
-- Build: cat zedqa_pagelist_lib.lua zedqa_menu_pagelist.lua > <one file>; run that file with
--   zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/compat_r3_full_2_mods.txt -Script <one file> -Tag pgl
-- grep "ZEDQA pgl"; shots zqa_pgl_<window>_<W>x<H>*.png.
local MM = ZeD and ZeD.MainMenu
local function say(s) print("ZEDQA pgl " .. tostring(s)) end
local function ms() return MainScreen and MainScreen.instance end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local Q = { pass = 0, fail = 0, notes = {} }
local function verdict(ok, text)
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. text)
end
local SHOTBASE = "zqa_pgl_"
local curShot = "x"
local function shot(suffix)
    local name = SHOTBASE .. curShot .. "_" .. sw .. "x" .. sh .. (suffix or "")
    local ok, err = pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
    say("shot " .. name .. (ok and "" or (" FAILED " .. tostring(err))))
end
local PL = ZEDQA_PL.new("pgl", say, verdict, shot)

-- OPENING AND LEAVING ------------------------------------------------------------------
local function needsReset()
    local r = false
    pcall(function() r = ActiveMods.requiresResetLua(ActiveMods.getById("default")) and true or false end)
    return r
end
local function toMain() if MM.view ~= "main" then MM.showView("main") end; MM.ctx.open = nil; return true end
local function backOne()
    local m = ms()
    local ws = m and m.worldSelect
    if ws and ws:isVisible() then WorldSelect.clickBack(ws); return true end
    if MM.view == "main" then return true end
    if MM.view == "newgame" and needsReset() then MM.showView("main"); return true end
    local w = MM.activeWindow()
    if not (w and w.back) then MM.showView("main"); return true end
    w:back()
    if w.confirm and MM.view ~= "main" then
        say("NOTE " .. tostring(MM.view) .. "'s back() asked (" .. tostring(w.confirm) .. "): closed without an answer")
        if w.finish then w:finish() else w:setConfirm(false); MM.showView("main") end
    end
    return true
end
local function openNewGame()
    toMain(); MM.act.newGame()
    if MM.view ~= "newgame" then return false, "view " .. tostring(MM.view) .. " after New game" end
    return true
end
local function newGameNext()
    local w = MM.root.newWin
    if MM.view ~= "newgame" or not w then return false, "New game not on show" end
    local want = GameMode and GameMode.SANDBOX and GameMode.SANDBOX:toString()
    for k, d in ipairs(w:items()) do if d.mode == want then w.sel = k end end
    w:next()
    local ws = ms() and ms().worldSelect
    if ws and ws:isVisible() then WorldSelect.clickNext(ws) end
    return true
end
local function spawnNext()
    if MM.view == "sandbox" then return true end
    local w = MM.root.spawnWin
    if MM.view ~= "spawn" or not w then return false, "spawn not on show (view " .. tostring(MM.view) .. ")" end
    if w.nameProblem and w:nameProblem() then w.nameEntry:setText("ZeDQA" .. tostring(getTimestampMs())) end
    w:next()
    return true
end

-- THE RUN ------------------------------------------------------------------------------
local steps = {}
local function add(name, go, opts)
    opts = opts or {}
    steps[#steps + 1] = { name = name, go = go, view = opts.view, wait = opts.wait or 4, rep = opts.rep, only = opts.only, win = opts.win }
end
local function forWindow(label, shotName, getWin)
    add("label " .. label, function() curShot = shotName; return true end, { wait = 1 })
    for _, s in ipairs(PL.steps(label)) do
        local fn = s[2]
        add(s[1], function()
            local w = getWin()
            if not (w and w:isVisible()) then return false, label .. " is not on show" end
            return fn(w)
        end, { rep = s.rep, only = s.only, wait = s.rep and 4 or 12 })
    end
end

add("main", toMain, { view = "main", wait = 30 })
add("newgame", openNewGame, { view = "newgame", wait = 30 })
add("spawn", newGameNext, { view = "spawn", wait = 30 })
add("sandbox", spawnNext, { view = "sandbox", wait = 45 })
forWindow("Sandbox step", "sandbox", function() return MM.root.sandWin end)
-- a real wheel, by hand (small screens only: the run is windowed there): the script waits up to 150 s for the page list
-- to move while QA turns the wheel over it with the desktop's own mouse
local REAL_WHEEL = false   -- (on when QA can turn the desktop mouse over the game window; off: the hold would only wait out its 150 s)
if sw < 2000 and REAL_WHEEL then
    local H = {}
    add("real wheel hold", function()
        local w = MM.root.sandWin
        if not (w and w:isVisible()) then return false, "the Sandbox step is not on show" end
        if not H.t0 then
            H.t0 = getTimestampMs(); w.pageIdx = 1; w._pagesShown = nil; w.pagesScroll = 0
            say("HOLD real wheel: turn the mouse wheel down over the page list now (150 s)")
            return true
        end
        if (w.pagesScroll or 0) > 0.5 then
            H.got = true
            say("real wheel: pagesScroll " .. PL.fl(w.pagesScroll) .. " after " .. math.floor((getTimestampMs() - H.t0) / 1000) .. " s (the real cursor "
                .. tostring(getMouseX()) .. "," .. tostring(getMouseY()) .. ")")
            return false
        end
        return getTimestampMs() - H.t0 < 150000
    end, { rep = true, wait = 2 })
    add("real wheel check", function()
        verdict(H.got == true, "a real mouse wheel over the page list scrolls it")
        shot("_realwheel")
        return true
    end, { wait = 30 })
end
for k = 1, 6 do add("back " .. k, backOne, { wait = 30 }) end
add("to main", toMain, { view = "main", wait = 30 })
add("options", function() MM.openOptions(); return true end, { view = "options", wait = 45 })
forWindow("Options", "options", function() return MM.root.optsWin end)
add("options back", backOne, { wait = 30 })
add("back to main", toMain, { view = "main", wait = 30 })

local n, endAt, i, cur = 0, nil, 0, nil
local function startStep()
    while true do
        i = i + 1
        local st = steps[i]
        if not st then return false end
        if st.only == "over" and not PL.D.over then
            -- (nothing to scroll: skipped quietly; measure said so)
        else
            cur = { st = st, n0 = n }
            local ok, r, why = pcall(st.go)
            if not ok or r == false then
                if st.rep and ok and r == false and why == nil then
                    cur.repDone = true          -- (a repeating step that had nothing more to do)
                else
                    cur.failed = true
                    Q.notes[#Q.notes + 1] = st.name
                    say("NOTE " .. st.name .. " did not run: " .. tostring(ok and why or r))
                end
            end
            return true
        end
    end
end
local function tick()
    n = n + 1
    if endAt then
        if n >= endAt then Events.OnFETick.Remove(tick); say("DONE") end
        return
    end
    if n == 2 then
        if not (MM and MM.root and MM.showView and MM.act and MM.activeWindow and ZEDQA_PL) then
            say("FAIL no ZeD main menu or no page-list library"); endAt = n + 8; return
        end
        if ms() and ms().inGame then say("FAIL a game is loaded: this script is for the main menu"); endAt = n + 8; return end
        say("start | screen " .. sw .. "x" .. sh .. " | root scale " .. tostring(ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root())
            .. " | text " .. tostring(ZeD.currentSize))
        startStep()
        return
    end
    if not cur then return end
    local e = n - cur.n0
    if e < cur.st.wait or MM._dip then return end
    if cur.st.rep and not cur.failed and not cur.repDone then
        local ok, more = pcall(cur.st.go)
        if ok and more then cur.n0 = n; return end
        if not ok then say("FAIL " .. cur.st.name .. ": threw " .. tostring(more)) end
    end
    if cur.st.view and not cur.failed then
        if MM.view ~= cur.st.view and e <= 180 then return end
        if MM.view ~= cur.st.view then verdict(false, cur.st.name .. ": landed on view " .. tostring(MM.view)) end
    end
    local more = true
    local ok, err = pcall(function() more = startStep() end)
    if not ok then say("FAIL starting the step after " .. cur.st.name .. ": " .. tostring(err)); more = i < #steps end
    if not more then
        if MM.view ~= "main" then pcall(MM.showView, "main") end
        MM.ctx.open = nil
        say("did not run: " .. ((#Q.notes > 0) and table.concat(Q.notes, ", ") or "none"))
        say("NOTE not run here: the server settings' bumpers (no server settings file on this machine)")
        say("summary " .. sw .. "x" .. sh .. ": " .. Q.pass .. " PASS, " .. Q.fail .. " FAIL")
        endAt = n + 8
    end
end
Events.OnFETick.Add(tick)
