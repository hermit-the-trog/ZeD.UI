-- ZeDUI/tools/qa/zedqa_menu_lean.lua  (Nov 1 2026, QA; punch list 48, commit e573d1d)
-- At the main menu, no game loaded, at the run's screen size: the desk's two framings (the room and leaning in).
-- Prints ZeD.Scale.root() (and the game's own scale), the framing, the desk multiple, the monitor rect
-- (MM.layout / MM.roomLayout / MM.leanLayout) and the screen size; then captures, each after the 200 ms dip has
-- cleared (30 frames at least, MM._dip nil and the framing the one the view wants):
--   mln_<W>x<H>_<size>_main.png      the main view
--   ..._options, _newgame, _spawn, _sandbox, _traits, _looks   (New game's Sandbox playstyle, stepped forward
--                                     with each window's own next(); Looks' play() is never called), Back out
--   ..._mods, _load, _workshop, _credits   (Back to the main view between pages)
--   ..._back                          the main view after the last Back
--   ..._dip                           ~100 ms into the first switch that dips (black or the right framing)
-- After each capture: the page, the framing, the monitor rect, the page window's rect, PASS / FAIL "the page fits
-- inside the monitor's glass", the framing against the design, and when leaning in "10 desk px of the right bezel
-- showing" and "the desk at 4x, the monitor 960x720 px whole on screen". <size> is normal (ZeD's small text) or
-- large, read from ZeD.currentSize. A page that will not open is logged (NOTE) and skipped. Everything is put
-- back to the main view at the end. grep "ZEDQA mln"; DONE a few ticks after the summary (OnFETick: the main
-- menu has no OnTick). Run through zedqa_menu_about_run.ps1 -Scripts "zedqa_menu_lean.lua|mln|240".
local MM = ZeD and ZeD.MainMenu
local function say(s) print("ZEDQA mln " .. tostring(s)) end
local function ms() return MainScreen and MainScreen.instance end
if not (MM and MM.root and MM.layout and MM.leanLayout and MM.roomLayout and MM.wantFraming and MM.showView and MM.act) then
    say("FAIL no ZeD main menu with the two framings (root " .. tostring(MM and MM.root) .. ", leanLayout " .. tostring(MM and MM.leanLayout) .. ")")
    say("DONE"); return
end
if ms() and ms().inGame then say("FAIL a game is loaded: this script is for the main menu"); say("DONE"); return end

local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local SIZE = (ZeD.currentSize == "large") and "large" or "normal"
local PRE = "mln_" .. sw .. "x" .. sh .. "_" .. SIZE .. "_"
local Q = { pass = 0, fail = 0, skipped = {}, dipDone = false, dips = {} }
local BEZEL = 10   -- desk px of the right bezel in view when leaning in (ZeD_MainMenu.lua LEAN_BEZEL)

local function fl(v) return math.floor((tonumber(v) or 0) + 0.5) end
local function rs(x, y, w, h) return fl(x) .. "," .. fl(y) .. " " .. fl(w) .. "x" .. fl(h) end
local function mon(L) return rs(L.tx, L.ty, L.tw, L.th) end
local function verdict(ok, text)
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. text)
end
local function shot(name)
    pcall(function() getCore():TakeFullScreenshot(PRE .. name .. ".png") end)
    say("shot " .. PRE .. name)
end

-- the scale and the framings
local function framingInfo()
    local S = ZeD.Scale
    local L = MM.layout()
    local root = S and S.root and S.root()
    local game = S and S.computeGame and S.computeGame()
    return L, "framing " .. tostring(MM._framing) .. " (wants " .. tostring(MM.wantFraming()) .. ") | desk " .. tostring(L.s)
        .. "x | monitor " .. mon(L) .. " | screen " .. sw .. "x" .. sh .. " | root " .. tostring(root) .. ", game "
        .. tostring(game) .. " | text " .. SIZE .. " (" .. tostring(ZeD.currentSize) .. ")"
end
local function layoutsLine()
    local R, Ln = MM.roomLayout(), MM.leanLayout()
    local holds = MM.roomHolds and MM.roomHolds(R)
    local small = MM.smallFits and MM.smallFits(R)
    say("roomLayout: desk " .. tostring(R.s) .. "x, origin " .. fl(R.ox) .. "," .. fl(R.oy) .. ", monitor " .. mon(R)
        .. " | holds the 1080p menu " .. tostring(holds) .. " | small layout fits " .. tostring(small))
    if Ln then
        say("leanLayout: desk " .. tostring(Ln.s) .. "x, origin " .. fl(Ln.ox) .. "," .. fl(Ln.oy) .. ", monitor " .. mon(Ln)
            .. " | right bezel " .. fl(sw - Ln.tx - Ln.tw) .. " px")
    else
        say("leanLayout: none (the room is the only framing at this size)")
    end
end

-- what the design says the view should show (punch list 48)
local function designFraming(view)
    if MM.roomHolds(MM.roomLayout()) or not MM.leanLayout() then return "room" end
    if view == "main" or view == "desktop" then return (SIZE == "large") and "lean" or "room" end
    return "lean"
end

local function checkLean(name, L)
    local bz = sw - (L.tx + L.tw)
    verdict(bz == BEZEL * L.s, name .. ": 10 desk px of the right bezel showing (" .. fl(bz) .. " px = "
        .. tostring(bz / L.s) .. " desk px at " .. tostring(L.s) .. "x)")
    local whole = L.tx >= 0 and L.ty >= 0 and L.tx + L.tw <= sw and L.ty + L.th <= sh
    verdict(whole and L.s == 4 and L.tw == 960 and L.th == 720, name .. ": the desk at 4x, the monitor 960x720 px and whole on screen ("
        .. tostring(L.s) .. "x, monitor " .. mon(L) .. ", whole " .. tostring(whole) .. ")")
end

local function checkMainRoom(name, L, x, ww)
    local blk = MM.iconBlock and MM.iconBlock(L)
    say(name .. ": the main window starts " .. fl(x - L.tx) .. " px from the monitor's left edge")
    if not blk then return end
    local iconLeft = L.tx + L.tw - blk.edge - blk.w
    verdict(x + ww <= iconLeft, name .. ": the main window ends left of the icon block (window right " .. fl(x + ww)
        .. ", icons from " .. fl(iconLeft) .. ", block fits " .. tostring(blk.fits) .. ")")
end

local function checkPage(name, view)
    local L, info = framingInfo()
    local w = MM.activeWindow()
    say(name .. " | view " .. tostring(MM.view) .. " | " .. info)
    if not w then verdict(false, name .. ": no window for view " .. tostring(MM.view)); return end
    local x, y, ww, wh = w:getAbsoluteX(), w:getAbsoluteY(), w:getWidth(), w:getHeight()
    say(name .. " window " .. rs(x, y, ww, wh) .. " (right " .. fl(x + ww) .. ", bottom " .. fl(y + wh) .. ") | visible " .. tostring(w:isVisible()))
    local inside = x >= L.tx and y >= L.ty and x + ww <= L.tx + L.tw and y + wh <= L.ty + L.th
    local over = ""
    if not inside then
        over = " (past the glass: left " .. fl(math.max(0, L.tx - x)) .. ", top " .. fl(math.max(0, L.ty - y)) .. ", right "
            .. fl(math.max(0, x + ww - L.tx - L.tw)) .. ", bottom " .. fl(math.max(0, y + wh - L.ty - L.th)) .. " px)"
    end
    verdict(inside, name .. ": the page fits inside the monitor's glass" .. over)
    local want = designFraming(view)
    verdict(MM._framing == want, name .. ": framing " .. tostring(MM._framing) .. ", the design's " .. want)
    if MM._framing == "lean" then checkLean(name, L)
    elseif view == "main" then checkMainRoom(name, L, x, ww) end
end

-- ---------------------------------------------------------------------------
-- OPENING AND LEAVING PAGES (each go returns true, or false and why; every call is pcall'd)
-- ---------------------------------------------------------------------------
local function toMain()
    if MM.view ~= "main" then MM.showView("main") end
    MM.ctx.open = nil
    return true
end

local function needsReset()
    local r = false
    pcall(function() r = ActiveMods.requiresResetLua(ActiveMods.getById("default")) and true or false end)
    return r
end

-- one Back from whatever is on show, along the page's own back(); vanilla's world select (more than one
-- map group) has no ZeD view and gets its own clickBack
local function backOne()
    local m = ms()
    local ws = m and m.worldSelect
    if ws and ws:isVisible() then WorldSelect.clickBack(ws); say("NOTE back through vanilla's world select"); return true end
    if MM.view == "main" then return true end
    if MM.view == "newgame" and needsReset() then
        say("NOTE New game's back() would reset Lua (the default mods differ from the loaded set): straight to the main view")
        MM.showView("main"); return true
    end
    local w = MM.activeWindow()
    if not (w and w.back) then say("NOTE view " .. tostring(MM.view) .. " has no back(): straight to the main view"); MM.showView("main"); return true end
    w:back()
    if w.confirm and MM.view ~= "main" then
        say("NOTE " .. tostring(MM.view) .. "'s back() asked a question (" .. tostring(w.confirm) .. "): closed without an answer")
        if w.finish then w:finish() else w:setConfirm(false); MM.showView("main") end
    end
    return true
end

local function openWith(fn, view, why)
    return function()
        if MM.view ~= "main" then toMain() end
        fn()
        if MM.view ~= view then return false, why or ("the view is " .. tostring(MM.view) .. " after the open") end
        return true
    end
end

-- New game: the Sandbox playstyle (so its Sandbox step comes), Next through each window's own next()
local function newGameNext()
    local w = MM.root.newWin
    if MM.view ~= "newgame" or not w then return false, "New game is not on show (view " .. tostring(MM.view) .. ")" end
    local want = GameMode and GameMode.SANDBOX and GameMode.SANDBOX:toString()
    for k, d in ipairs(w:items()) do if d.mode == want then w.sel = k end end
    say("NOTE New game: playstyle " .. tostring(w.sel) .. " (" .. tostring(want) .. "), its next()")
    w:next()
    local ws = ms() and ms().worldSelect
    if ws and ws:isVisible() then say("NOTE vanilla's world select came up (more than one map group): its own clickNext"); WorldSelect.clickNext(ws) end
    return true
end

local function stepNext(from, field, to)
    return function()
        if MM.view == to then say("NOTE already on " .. to .. " (vanilla skipped " .. from .. ")"); return true end
        local w = MM.root[field]
        if MM.view ~= from or not w then return false, "the " .. from .. " page is not on show (view " .. tostring(MM.view) .. ")" end
        if field == "spawnWin" and w.nameProblem and w:nameProblem() then
            say("NOTE Spawn's save name had a problem (" .. tostring(w:nameProblem()) .. "): a fresh name, nothing written")
            w.nameEntry:setText("ZeDQA" .. tostring(getTimestampMs()))
        end
        w:next()
        return true
    end
end

local function openLoad()
    if not MM.hasSaves() then return false, "no saves (Load is greyed out)" end
    return openWith(MM.act.load, "load")()
end
local function openWorkshop()
    local m = ms()
    if not (m and m.workshopSubmit and MM.views) then return false, "vanilla's Workshop screen is not there (workshopSubmit " .. tostring(m and m.workshopSubmit) .. ")" end
    return openWith(MM.act.workshop, "workshop")()
end

-- the run: { name, go, view (the view to land on; nil = any), shot }
local steps = {}
local function add(name, go, view, doShot) steps[#steps + 1] = { name = name, go = go, view = view, shot = doShot } end
add("main", toMain, "main", true)
add("options", openWith(MM.act.options, "options"), "options", true)
add("back from options", backOne, "main", false)
add("newgame", openWith(MM.act.newGame, "newgame"), "newgame", true)
add("spawn", newGameNext, "spawn", true)
add("sandbox", stepNext("spawn", "spawnWin", "sandbox"), "sandbox", true)
add("traits", stepNext("sandbox", "sandWin", "traits"), "traits", true)
add("looks", stepNext("traits", "traitsWin", "looks"), "looks", true)
for k = 1, 6 do add("back out of new game " .. k, backOne, nil, false) end
add("back to main", toMain, "main", false)
add("mods", openWith(MM.act.mods, "mods"), "mods", true)
add("back from mods", backOne, "main", false)
add("load", openLoad, "load", true)
add("back from load", backOne, "main", false)
add("workshop", openWorkshop, "workshop", true)
add("back from workshop", backOne, "main", false)
add("credits", openWith(MM.act.credits, "credits"), "credits", true)
add("back", backOne, "main", true)

-- ---------------------------------------------------------------------------
-- THE TICK
-- ---------------------------------------------------------------------------
local n, i, cur, endAt = 0, 0, nil, nil

local function dipShot()
    local d = MM._dip
    local t = getTimestampMs()
    local a = MM.dipAlpha(t)
    local e = d and (t - d.t0) or -1
    local to = (d and d.to) or MM.wantFraming()
    shot("dip")
    local what
    if a >= 0.75 then what = "black (darkness " .. tostring(a) .. ")"
    elseif MM._framing == to then what = "the right framing (" .. tostring(to) .. ", darkness " .. tostring(a) .. ")"
    else what = "the wrong framing (" .. tostring(MM._framing) .. " on show, going to " .. tostring(to) .. ", darkness " .. tostring(a) .. ")" end
    verdict(a >= 0.75 or MM._framing == to, "mid-dip shot " .. fl(e) .. " ms into the dip on the switch to " .. cur.st.name
        .. ": " .. what .. " | switched " .. tostring(d and d.switched) .. " (darkness read this tick; the picture is this frame's)")
    Q.dipDone = true
end

local function startStep()
    i = i + 1
    local st = steps[i]
    if not st then return false end
    cur = { st = st, n0 = n, dip = false, from = MM._framing }
    local ok, r, why = pcall(st.go)
    if not ok or r == false then
        cur.failed = true
        Q.skipped[#Q.skipped + 1] = st.name
        say("NOTE " .. st.name .. " will not open: " .. tostring(ok and why or r))
    end
    return true
end

local function settled()
    local e = n - cur.n0
    if e < 30 or MM._dip then return false end
    if MM._framing ~= MM.wantFraming() then return e > 600 end
    if cur.st.view and MM.view ~= cur.st.view and not cur.failed then return e > 120 end   -- (vanilla went elsewhere)
    return true
end

local function finishStep()
    local st = cur.st
    local e = n - cur.n0
    say("step " .. st.name .. ": view " .. tostring(MM.view) .. ", framing " .. tostring(cur.from) .. " -> " .. tostring(MM._framing)
        .. " | dip " .. (cur.dip and "yes" or "no") .. " | " .. e .. " frames")
    if cur.dip then Q.dips[#Q.dips + 1] = st.name .. " (" .. tostring(cur.from) .. " -> " .. tostring(MM._framing) .. ")" end
    if cur.failed then return end
    if st.view and MM.view ~= st.view then
        verdict(false, st.name .. ": landed on view " .. tostring(MM.view) .. ", not " .. st.view .. " (no capture)")
        return
    end
    if st.shot then shot(st.name); checkPage(st.name, st.view or MM.view) end
end

local function cleanUp()
    local m = ms()
    local ws = m and m.worldSelect
    if ws and ws:isVisible() then pcall(function() ws:setVisible(false) end) end
    if MM.view ~= "main" then pcall(MM.showView, "main") end
    MM.ctx.open = nil
    say("put back: view " .. tostring(MM.view) .. ", framing " .. tostring(MM._framing) .. ", ZeD menu closed " .. tostring(MM.ctx.open == nil))
    say("dips seen: " .. ((#Q.dips > 0) and table.concat(Q.dips, "; ") or "none") .. (Q.dipDone and "" or " | no mid-dip shot (no switch dipped)"))
    say("not opened: " .. ((#Q.skipped > 0) and table.concat(Q.skipped, ", ") or "none"))
    say("summary " .. sw .. "x" .. sh .. " " .. SIZE .. ": " .. Q.pass .. " PASS, " .. Q.fail .. " FAIL")
end

local function tick()
    n = n + 1
    if endAt then
        if n >= endAt then Events.OnFETick.Remove(tick); say("DONE") end
        return
    end
    if n == 2 then
        say("start | " .. select(2, framingInfo()))
        layoutsLine()
        startStep()
        return
    end
    if not cur then return end
    if MM._dip and n > cur.n0 then
        cur.dip = true
        if not Q.dipDone and getTimestampMs() - MM._dip.t0 >= 100 then dipShot() end
    end
    if not settled() then return end
    local ok, err = pcall(finishStep)
    if not ok then say("FAIL " .. cur.st.name .. ": the check threw " .. tostring(err)) end
    if not startStep() then
        pcall(cleanUp)
        endAt = n + 8
    end
end
Events.OnFETick.Add(tick)
