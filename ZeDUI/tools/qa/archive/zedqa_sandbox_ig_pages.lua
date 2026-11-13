-- ZeDUI/tools/qa/zedqa_sandbox_ig_pages.lua  (Nov 2 2026, QA; punch list 52 in game)
-- The Sandbox window in game (pause menu, Sandbox options line) with a long mod list: zedqa_pagelist_lib.lua's checks on
-- its page list (rows in the box, the wheel, the bar, RB / LB, edge clicks), then its change marks: one setting changed
-- on the last page with settings, and the marks the window draws (ZeD.Atoms.drawStatusDot, recorded for a frame) must
-- sit on that page's row, inside the box, left of the bar: none while the row is scrolled out of the box, one when the
-- wheel brings it in, none after Undo changes. Nothing is applied; the switch and the menu are put back.
-- Build: cat zedqa_pagelist_lib.lua zedqa_sandbox_ig_pages.lua > <one file>; run in a game (zedqa_mods_run.ps1).
-- grep "ZEDQA pgi"; shots zqa_pgi_ingame_<W>x<H>*.png.
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA pgi " .. tostring(s)) end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local Q = { pass = 0, fail = 0 }
local function verdict(ok, text)
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. text)
end
local function shot(suffix)
    local name = "zqa_pgi_ingame_" .. sw .. "x" .. sh .. (suffix or "")
    local ok, err = pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
    say("shot " .. name .. (ok and "" or (" FAILED " .. tostring(err))))
end
local opt = ZeD.Settings and ZeD.Settings.sandboxInGameOption
if not (opt and MM and ZeD_MMSandboxIG and ZEDQA_PL) then say("ERR the sandbox window or the page-list library is not loaded"); say("DONE"); return end
local PL = ZEDQA_PL.new("pgi", say, verdict, shot)
local switchWas = opt:getValue()
local function menuUp() return MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
local function toggleMenu() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
local function win() return MM.pauseSandbox end

-- THE CHANGE MARKS ---------------------------------------------------------------------
local M = {}
local origDot = ZeD.Atoms.drawStatusDot
local function recordDots(on)
    if on then
        M.dots = {}
        ZeD.Atoms.drawStatusDot = function(panel, x, y, c, sz, ...)
            if panel == win() then M.dots[#M.dots + 1] = { x = panel:getAbsoluteX() + x, y = panel:getAbsoluteY() + y, sz = sz } end
            return origDot(panel, x, y, c, sz, ...)
        end
    else
        ZeD.Atoms.drawStatusDot = origDot
    end
end
-- the last page with a setting the test can step (a list), and that setting
local function pickTarget(w)
    local pages = w:pages()
    for i = #pages, 1, -1 do
        local p = pages[i]
        if not p.virtual then
            for _, r in ipairs(w:rowsFor(p)) do
                if r.name and r.kind == "combo" and r.control and not w:rowDisabled(r) then return i, r end
            end
        end
    end
    return nil
end
local function dotsOn(w, label, wantPage)
    local B = PL.box(w)
    local _, track = PL.hits(w)
    local rows = {}
    for _, d in ipairs(M.dots or {}) do
        local cy = d.y + (d.sz or 0) / 2
        local on = nil
        for _, h in ipairs((PL.hits(w))) do if cy >= h.y and cy < h.y + h.h then on = h.i end end
        local inBox = cy >= B.y and cy <= B.bot and d.x >= B.x and d.x + (d.sz or 0) <= B.x + B.w
        local leftOfBar = (not track) or (d.x + (d.sz or 0) <= track.x)
        rows[#rows + 1] = tostring(on) .. (inBox and "" or " (outside the box)") .. (leftOfBar and "" or " (on the bar)")
        if wantPage then
            verdict(on == wantPage and inBox and leftOfBar, label .. ": the mark sits on page " .. wantPage .. "'s row, in the box, left of the bar (on row "
                .. tostring(on) .. ", y " .. PL.fl(d.y) .. ", x " .. PL.fl(d.x) .. ")")
        end
    end
    say(label .. ": marks drawn " .. #(M.dots or {}) .. (#rows > 0 and (" on rows " .. table.concat(rows, ", ")) or ""))
    return #(M.dots or {})
end

-- THE RUN ------------------------------------------------------------------------------
local steps = {}
local function add(name, go, wait, rep) steps[#steps + 1] = { name = name, go = go, wait = wait or 4, rep = rep } end
add("open", function()
    if ZeD_CharacterWindow and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(getPlayer():getPlayerNum()) end
    opt:setValue(2)
    pcall(function() Mouse.setXY(5, 5) end)
    if not menuUp() then toggleMenu() end
    return true
end, 40)
add("sandbox", function() MM.openSandboxIG(); return true end, 40)
add("check open", function()
    local w = win()
    verdict(w and w:isVisible() and MM.pauseView == "sandbox", "the Sandbox window is open over the paused game")
    if not (w and w:isVisible()) then return false, "no window" end
    return true
end, 4)
for _, s in ipairs(PL.steps("Sandbox in game")) do
    local fn = s[2]
    add(s[1], function()
        local w = win()
        if not (w and w:isVisible()) then return false, "the window is not on show" end
        if s.only == "over" and not PL.D.over then return not s.rep end   -- (skipped: a repeating step ends at once)
        return fn(w)
    end, s.rep and 4 or 12, s.rep)
end
-- the marks
add("mark change", function()
    local w = win()
    local i, r = pickTarget(w)
    if not i then return false, "no page with a list setting" end
    M.page, M.row = i, r
    w.pageIdx = 1; w._pagesShown = nil; w.pagesScroll = 0
    w:nudge(r, (r.control.selected < #r.control.options) and 1 or -1)
    w:refreshDiff(true)
    say("marks: changed " .. tostring(r.name) .. " on page " .. i .. " (" .. tostring(w:pages()[i].title) .. ") | changes " .. tostring(w.nDiff))
    return true
end, 4)
add("marks at top", function() recordDots(true); return true end, 2)
add("marks at top check", function()
    local w = win()
    recordDots(false)
    local whole = PL.whole(w, M.page)
    local nd = dotsOn(w, "list at the top", whole and M.page or nil)
    if not whole and PL.hitOf(w, M.page) == nil then
        verdict(nd == 0, "no mark drawn while the changed page's row is scrolled out of the box (" .. nd .. ")")
    end
    pcall(function() Mouse.setXY(math.floor(PL.box(w).x + PL.box(w).w / 2), math.floor(PL.box(w).y + PL.box(w).h / 2)) end)
    M.notch = 0
    return true
end, 4)
add("marks wheel", function()
    local w = win()
    if M.notch >= 80 or PL.whole(w, M.page) then return false end
    PL.wheelAt(w, 1)
    M.notch = M.notch + 1
    return true
end, 2, true)
add("marks in view", function() recordDots(true); return true end, 2)
add("marks in view check", function()
    local w = win()
    recordDots(false)
    local nd = dotsOn(w, "after the wheel", M.page)
    verdict(nd == 1, "one mark drawn, on the changed page's row, after a scroll (" .. nd .. ")")
    shot("_marks")
    w:undoAll()
    return true
end, 4)
add("marks after undo", function() recordDots(true); return true end, 2)
add("marks after undo check", function()
    local w = win()
    recordDots(false)
    local nd = dotsOn(w, "after Undo changes")
    verdict(nd == 0 and (w.nDiff or 0) == 0, "no marks after Undo changes (" .. nd .. " marks, " .. tostring(w.nDiff) .. " changes)")
    return true
end, 4)
add("put back", function()
    local w = win()
    if w then w.pageIdx = 1; w._pagesShown = nil; w.pagesScroll = 0; pcall(function() w:finish() end) end
    opt:setValue(switchWas or 1)
    if menuUp() then toggleMenu() end
    return true
end, 20)

local n, i, cur, done = 0, 0, nil, false
local function startStep()
    i = i + 1
    local st = steps[i]
    if not st then return false end
    cur = { st = st, n0 = n }
    local ok, r, why = pcall(st.go)
    if not ok or (r == false and not st.rep) then
        cur.failed = true
        say("NOTE " .. st.name .. " did not run: " .. tostring(ok and why or r))
    elseif r == false then cur.repDone = true end
    return true
end
local function tick()
    if done then return end
    n = n + 1
    if n == 2 then say("start | screen " .. sw .. "x" .. sh); startStep(); return end
    if not cur then return end
    if n - cur.n0 < cur.st.wait then return end
    if cur.st.rep and not cur.failed and not cur.repDone then
        local ok, more = pcall(cur.st.go)
        if ok and more then cur.n0 = n; return end
        if not ok then say("FAIL " .. cur.st.name .. ": threw " .. tostring(more)) end
    end
    if not startStep() then
        done = true
        recordDots(false)
        Events.OnPreUIDraw.Remove(tick)
        say("summary " .. sw .. "x" .. sh .. ": " .. Q.pass .. " PASS, " .. Q.fail .. " FAIL")
        say("DONE")
    end
end
Events.OnPreUIDraw.Add(tick)
