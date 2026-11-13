-- ZeDUI/tools/qa/zedqa_menu_sandbox_pages.lua  (Nov 2 2026, QA; tester report "Can't scroll down the Sandbox options")
-- At the main menu, no game loaded, with a long mod list (many mods add sandbox pages): New game, the Sandbox
-- playstyle, stepped forward with each window's own next() (newWin:next, spawnWin:next; Looks' play() is never
-- reached) to the Sandbox step. Then, on the Sandbox window's left column (ZeD_MMOptions.drawPages):
--   the screen size, the page count (window:pages()), the page row height (T.px(30), and measured from two
--   consecutive "<kind>:page:" hits), the page list's area (the body drawPages gets: title bar + pad down to the
--   band), the last page row's bottom against the list's bottom, and
--   PASS / FAIL "every sandbox page row lies inside the page list" (FAIL: how many rows fall below, their titles)
--   capture zqa_sbp_pages_<W>x<H>.png
--   the mouse wheel over the page list (Mouse.setXY to the list's middle, then the window's onMouseWheel(1), then
--   the desk's MM.wheel(1)): PASS / FAIL "the wheel scrolls the page list" (the first page row moved or not)
--   the controller: D-pad Down through the window's own joyDir (does focus ever land on a page row?), then the
--   window's own joyBumper(1) (LB / RB change pages) up to the last page: does the last page get chosen, and is
--   its row drawn inside the list and on screen; capture zqa_sbp_pages_<W>x<H>_padlast.png
-- Then back out to the main view with each window's own back() (New game's guarded by ActiveMods.requiresResetLua).
-- grep "ZEDQA sbp"; DONE a few ticks after the summary (OnFETick: the main menu has no OnTick).
-- Run: zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/compat_r3_full_2_mods.txt -Script <this> -Tag sbp
local MM = ZeD and ZeD.MainMenu
local function say(s) print("ZEDQA sbp " .. tostring(s)) end
local function ms() return MainScreen and MainScreen.instance end

local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local SHOT = "zqa_sbp_pages_" .. sw .. "x" .. sh
local PAGE_ROW_H = 30   -- ZeD_MainMenuOptions.lua's PAGE_ROW_H (design px)
local Q = { pass = 0, fail = 0, notes = {} }
local n, endAt = 0, nil

local function fl(v) return math.floor((tonumber(v) or 0) + 0.5) end
local function verdict(ok, text)
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. text)
end
local function shot(name)
    local ok, err = pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
    say("shot " .. name .. (ok and "" or (" FAILED " .. tostring(err))))
end
local function sandWin() return MM and MM.root and MM.root.sandWin end

-- ---------------------------------------------------------------------------
-- READING THE PAGE LIST
-- ---------------------------------------------------------------------------
-- the page hits from the last prerender, in order: { i, x, y, w, h } (screen px)
local function pageHits(w)
    local pre = tostring(w.kind) .. ":page:"
    local t = {}
    for _, h in ipairs(w._hits or {}) do
        if h.id and string.sub(h.id, 1, #pre) == pre then
            t[#t + 1] = { i = tonumber(string.sub(h.id, #pre + 1)), x = h.x, y = h.y, w = h.w, h = h.h }
        end
    end
    table.sort(t, function(a, b) return (a.i or 0) < (b.i or 0) end)
    return t
end

-- the box drawPages is handed (ZeD_MMSandbox:prerender): bodyY = title bar + pad, bodyH down to the band
local function listArea(w)
    local T = ZeD.T
    local pad = T.px(MM.U.STACK_PAD)
    local h = w:getHeight()
    local stripY = h - w:footerHeight() - MM.bandH()
    local bodyY = T.titleBarH + pad
    local bodyH = stripY - T.titleBarH - pad * 2
    local ax, ay = w:getAbsoluteX(), w:getAbsoluteY()
    return { x = ax + pad, y = ay + bodyY, w = T.px(210), h = bodyH, bot = ay + bodyY + bodyH, findH = T.px(34) }
end

local function measure(w)
    local T = ZeD.T
    local pages = w:pages()
    local hits = pageHits(w)
    local A = listArea(w)
    say("screen " .. sw .. "x" .. sh .. " | window " .. fl(w:getAbsoluteX()) .. "," .. fl(w:getAbsoluteY()) .. " "
        .. fl(w:getWidth()) .. "x" .. fl(w:getHeight()) .. " (bottom " .. fl(w:getAbsoluteY() + w:getHeight()) .. ") | root scale "
        .. tostring(ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) .. " | text " .. tostring(ZeD.currentSize))
    say("sandbox pages: " .. #pages .. " (page hits drawn: " .. #hits .. ") | page row height T.px(" .. PAGE_ROW_H .. ") = "
        .. tostring(T.px(PAGE_ROW_H)) .. (hits[2] and (", measured " .. fl(hits[2].y - hits[1].y)) or ""))
    say("page list area: " .. fl(A.x) .. "," .. fl(A.y) .. " " .. fl(A.w) .. "x" .. fl(A.h) .. " (Find box " .. fl(A.findH)
        .. " px, rows from " .. fl(hits[1] and hits[1].y or -1) .. ", list bottom " .. fl(A.bot) .. ")")
    local titles = {}
    for k, p in ipairs(pages) do titles[k] = p.title end
    say("page titles: " .. table.concat(titles, " | "))
    local last = hits[#hits]
    if not last then verdict(false, "every sandbox page row lies inside the page list (no page rows drawn)"); return end
    local lastBot = last.y + last.h
    say("last page row (" .. tostring(last.i) .. " " .. tostring(titles[last.i]) .. "): " .. fl(last.y) .. " to " .. fl(lastBot)
        .. " | list bottom " .. fl(A.bot) .. " | window bottom " .. fl(w:getAbsoluteY() + w:getHeight()) .. " | screen bottom " .. sh
        .. " | over by " .. fl(lastBot - A.bot) .. " px")
    local below, offScreen = {}, 0
    for _, h in ipairs(hits) do
        if h.y + h.h > A.bot + 0.5 then below[#below + 1] = tostring(titles[h.i]) end
        if h.y + h.h > sh then offScreen = offScreen + 1 end
    end
    if #below == 0 then
        verdict(true, "every sandbox page row lies inside the page list (" .. #hits .. " rows, " .. fl(A.bot - lastBot) .. " px spare)")
    else
        verdict(false, "every sandbox page row lies inside the page list: " .. #below .. " of " .. #hits .. " rows fall below it ("
            .. offScreen .. " past the screen's bottom): " .. table.concat(below, " | "))
    end
end

-- ---------------------------------------------------------------------------
-- OPENING AND LEAVING (as zedqa_menu_lean.lua; each returns true, or false and why)
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

local function openNewGame()
    toMain()
    MM.act.newGame()
    if MM.view ~= "newgame" then return false, "the view is " .. tostring(MM.view) .. " after New game" end
    return true
end

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

local function spawnNext()
    if MM.view == "sandbox" then say("NOTE already on sandbox (vanilla skipped spawn)"); return true end
    local w = MM.root.spawnWin
    if MM.view ~= "spawn" or not w then return false, "the spawn page is not on show (view " .. tostring(MM.view) .. ")" end
    if w.nameProblem and w:nameProblem() then
        say("NOTE Spawn's save name had a problem (" .. tostring(w:nameProblem()) .. "): a fresh name, nothing written")
        w.nameEntry:setText("ZeDQA" .. tostring(getTimestampMs()))
    end
    w:next()
    return true
end

-- ---------------------------------------------------------------------------
-- THE SANDBOX CHECKS (each needs the window on show; a frame between steps lets prerender rebuild _hits)
-- ---------------------------------------------------------------------------
local W = {}   -- what the wheel and pad checks carry between ticks

local function needSand()
    local w = sandWin()
    if MM.view ~= "sandbox" or not w then return nil, "the Sandbox step is not on show (view " .. tostring(MM.view) .. ")" end
    return w
end

local function doMeasure()
    local w, why = needSand()
    if not w then return false, why end
    measure(w)
    shot(SHOT)
    return true
end

local function wheelPrep()
    local w, why = needSand()
    if not w then return false, why end
    local A = listArea(w)
    local hits = pageHits(w)
    local mx = math.floor(A.x + A.w / 2)
    local my = math.floor(A.y + A.findH + math.min(A.h - A.findH, sh - A.y - A.findH) / 2)
    W.firstY = hits[1] and hits[1].y
    W.scroll0 = w.scroll
    W.page0 = w.pageIdx
    pcall(function() Mouse.setXY(mx, my) end)
    say("wheel: mouse set to " .. mx .. "," .. my .. " (over the page list) | first page row at " .. fl(W.firstY or -1)
        .. " | right list scroll " .. tostring(w.scroll))
    return true
end

local function wheelSend()
    local w, why = needSand()
    if not w then return false, why end
    say("wheel: the mouse reads " .. tostring(getMouseX()) .. "," .. tostring(getMouseY()))
    local ok1, r1 = pcall(function() return w:onMouseWheel(1) end)
    say("wheel: window onMouseWheel(1) -> " .. (ok1 and tostring(r1) or ("threw " .. tostring(r1))))
    local ok2, r2 = pcall(function() return MM.wheel(1) end)
    say("wheel: desk MM.wheel(1) -> " .. (ok2 and tostring(r2) or ("threw " .. tostring(r2))))
    return true
end

local function wheelCheck()
    local w, why = needSand()
    if not w then return false, why end
    local hits = pageHits(w)
    local y1 = hits[1] and hits[1].y
    local moved = (W.firstY ~= nil and y1 ~= nil and math.abs(y1 - W.firstY) > 0.5)
    say("wheel: first page row " .. fl(W.firstY or -1) .. " -> " .. fl(y1 or -1) .. " | right list scroll " .. tostring(W.scroll0)
        .. " -> " .. tostring(w.scroll) .. " | page " .. tostring(W.page0) .. " -> " .. tostring(w.pageIdx))
    if moved then verdict(true, "the wheel scrolls the page list")
    else verdict(false, "the wheel does not scroll the page list (the first page row did not move)") end
    w.scroll = W.scroll0 or 0
    return true
end

local function padDown()
    local w, why = needSand()
    if not w then return false, why end
    local pre = tostring(w.kind) .. ":page:"
    local n0 = #w:pages()
    local seen, onPage, ids = 0, false, {}
    w.focusId = nil
    for k = 1, n0 + 60 do
        local ok, err = pcall(function() w:joyDir("down") end)
        if not ok then say("FAIL pad: joyDir threw " .. tostring(err)); break end
        local f = tostring(w.focusId)
        if ids[#ids] ~= f then ids[#ids + 1] = f; seen = seen + 1 end
        if string.sub(f, 1, #pre) == pre then onPage = true end
    end
    say("pad Down x" .. (n0 + 60) .. ": focus went through " .. seen .. " controls, last " .. tostring(w.focusId)
        .. " | landed on a page row " .. tostring(onPage) .. " (first few: " .. table.concat(ids, ", ", 1, math.min(#ids, 6)) .. ")")
    if not onPage then say("NOTE pad: the D-pad does not move onto the page list; pages change with LB / RB (joyBumper)") end
    w.focusId = nil
    -- LB / RB: from page 1 forward to the last
    W.padPages = n0
    w.pageIdx = 1
    for k = 1, n0 - 1 do pcall(function() w:joyBumper(1) end) end
    say("pad RB x" .. (n0 - 1) .. " from page 1: page " .. tostring(w.pageIdx) .. " of " .. n0)
    return true
end

local function padCheck()
    local w, why = needSand()
    if not w then return false, why end
    local n0 = W.padPages or #w:pages()
    local A = listArea(w)
    local row
    for _, h in ipairs(pageHits(w)) do if h.i == w.pageIdx then row = h end end
    verdict(w.pageIdx == n0, "the pad's RB reaches the last sandbox page (page " .. tostring(w.pageIdx) .. " of " .. n0 .. ")")
    if row then
        local bot = row.y + row.h
        say("pad: the chosen page's row " .. fl(row.y) .. " to " .. fl(bot) .. " | list bottom " .. fl(A.bot) .. " | screen bottom " .. sh)
        verdict(bot <= A.bot + 0.5, "the last page's row (chosen by the pad) is drawn inside the page list")
        verdict(bot <= sh and row.y >= 0, "the last page's row (chosen by the pad) is on screen")
    else
        verdict(false, "the last page's row is drawn (no hit for page " .. tostring(w.pageIdx) .. ")")
    end
    shot(SHOT .. "_padlast")
    pcall(function() w:joyBumper(1) end)   -- (wraps to page 1)
    say("pad: RB once more -> page " .. tostring(w.pageIdx))
    return true
end

-- ---------------------------------------------------------------------------
-- THE RUN: { name, go, view (to land on), wait (frames after go before the next step) }
-- ---------------------------------------------------------------------------
local steps = {}
local function add(name, go, view, wait) steps[#steps + 1] = { name = name, go = go, view = view, wait = wait or 30 } end
add("main", toMain, "main")
add("newgame", openNewGame, "newgame")
add("spawn", newGameNext, "spawn")
add("sandbox", spawnNext, "sandbox", 45)
add("measure", doMeasure, nil, 4)
add("wheel prep", wheelPrep, nil, 6)
add("wheel send", wheelSend, nil, 6)
add("wheel check", wheelCheck, nil, 4)
add("pad down", padDown, nil, 6)
add("pad check", padCheck, nil, 6)
for k = 1, 6 do add("back " .. k, backOne, nil, 30) end
add("back to main", toMain, "main")

local i, cur = 0, nil

local function startStep()
    i = i + 1
    local st = steps[i]
    if not st then return false end
    cur = { st = st, n0 = n }
    local ok, r, why = pcall(st.go)
    if not ok or r == false then
        cur.failed = true
        Q.notes[#Q.notes + 1] = st.name
        say("NOTE " .. st.name .. " did not run: " .. tostring(ok and why or r))
    end
    return true
end

local function settled()
    local e = n - cur.n0
    if e < cur.st.wait or MM._dip then return false end
    if cur.st.view and MM.view ~= cur.st.view and not cur.failed then return e > 180 end   -- (vanilla went elsewhere)
    return true
end

local function finishStep()
    local st = cur.st
    if st.view then
        say("step " .. st.name .. ": view " .. tostring(MM.view) .. " | " .. (n - cur.n0) .. " frames")
        if not cur.failed and MM.view ~= st.view then
            verdict(false, st.name .. ": landed on view " .. tostring(MM.view) .. ", not " .. st.view)
        end
    end
end

local function cleanUp()
    local m = ms()
    local ws = m and m.worldSelect
    if ws and ws:isVisible() then pcall(function() ws:setVisible(false) end) end
    if MM.view ~= "main" then pcall(MM.showView, "main") end
    MM.ctx.open = nil
    say("put back: view " .. tostring(MM.view))
    say("did not run: " .. ((#Q.notes > 0) and table.concat(Q.notes, ", ") or "none"))
    say("summary " .. sw .. "x" .. sh .. ": " .. Q.pass .. " PASS, " .. Q.fail .. " FAIL")
end

local function tick()
    n = n + 1
    if endAt then
        if n >= endAt then Events.OnFETick.Remove(tick); say("DONE") end
        return
    end
    if n == 2 then
        if not (MM and MM.root and MM.showView and MM.act and MM.activeWindow and MM.U and MM.bandH) then
            say("FAIL no ZeD main menu (root " .. tostring(MM and MM.root) .. ")"); endAt = n + 8; return
        end
        if ms() and ms().inGame then say("FAIL a game is loaded: this script is for the main menu"); endAt = n + 8; return end
        say("start | screen " .. sw .. "x" .. sh .. " | view " .. tostring(MM.view))
        startStep()
        return
    end
    if not cur then return end
    if not settled() then return end
    local ok, err = pcall(finishStep)
    if not ok then say("FAIL " .. cur.st.name .. ": the check threw " .. tostring(err)) end
    local more = true
    ok, err = pcall(function() more = startStep() end)
    if not ok then say("FAIL starting the step after " .. cur.st.name .. ": " .. tostring(err)); more = (i < #steps) end
    if not more then
        pcall(cleanUp)
        endAt = n + 8
    end
end
Events.OnFETick.Add(tick)
