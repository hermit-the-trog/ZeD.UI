-- ZeDUI/tools/qa/zedqa_autocollapse.lua  (Nov 4 2026, QA; Build's dfbeee1b: the windows roll up when not in use)
-- With the REAL mouse (release_check_mouse.ps1 through Lua/zedqa_click.txt). Both windows open, unpinned:
--   1. pointer to an empty corner: after 1 s both still open; after ~2.6 s both rolled up (windowShaded)
--   2. pointer over the Character window's title bar: it rolls down; the World window stays up
--   3. a real click on the Character window's right pin (its inventory side's, WindowHalves): that half pinned
--      (modData ZeD_WinPinned.charInv), the window stays down with the pointer away (its drawer folds in)
--   4. aiming (setIsAiming): the unpinned World window, rolled down by a hover first, rolls up at once when the pointer leaves
--   5. a real click on the pin again: unpinned; rolls up after the wait
-- Pictures. Pins and windows put back. grep "ZEDQA acl". Pictures zqa_acl_<w>x<h>_<n>.png.
local function say(s) print("ZEDQA acl " .. tostring(s)) end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_acl_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local p = getPlayer()
local md = p:getModData()
-- (every pin key, the halves' too: charInv, charTabs, worldInv, worldTabs)
local keepPins = nil
if md.ZeD_WinPinned then keepPins = {}; for k, v in pairs(md.ZeD_WinPinned) do keepPins[k] = v end end
local function CW() return ZeD_CharacterWindow.getWindow() end
local function WW() return ZeD_WorldWindow.getWindow() end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
local function req(s)
    pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
    pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write(s); f:close() end)
end
local function done() local r = getFileReader("zedqa_click_done.txt", false); local l = r and r:readLine(); if r then r:close() end; return l ~= nil and l:find("done", 1, true) ~= nil end
local function moveTo(x, y) req("move " .. math.floor(x) .. " " .. math.floor(y)) end
local function clickAt(x, y) req("left " .. math.floor(x) .. " " .. math.floor(y)) end
local keepH
local function rolled(w) return w and w.windowShaded == true end

step(30, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    local c, w = CW(), WW()
    if not (c and c:getIsVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    c, w = CW(), WW()
    c:setPinned(false); w:setPinned(false)
    say("autoCollapse char " .. tostring(c.autoCollapse) .. ", world " .. tostring(w.autoCollapse))
    check(c.autoCollapse == true and w.autoCollapse == true, "both windows have autoCollapse")
    -- (the pointer starts inside the Character window, so the count starts when it leaves)
    moveTo(c:getAbsoluteX() + c:getWidth() / 2, c:getAbsoluteY() + c:getHeight() / 2)
end)
waitFor(5, 600, done, function() end)
step(30, function() moveTo(sw - 40, sh / 2) end)
waitFor(5, 600, done, function() end)
step(50, function()   -- ~0.8 s after the pointer left
    check(not rolled(CW()) and not rolled(WW()), "1 s after the pointer leaves: both still open")
end)
step(140, function()  -- ~3 s
    check(rolled(CW()) and rolled(WW()), "after about 3 s away: both rolled up")
    keepH = keepH or {}
    local c, w = CW(), WW()
    say(string.format("rolled heights: char %d (title %d), world %d (title %d)", c:getHeight(), c:titleBarHeight(), w:getHeight(), w:titleBarHeight()))
    local cs, ws = c.shownHeight and c:shownHeight() or c:getHeight(), w.shownHeight and w:shownHeight() or w:getHeight()
    say("shown heights: char " .. tostring(cs) .. ", world " .. tostring(ws))
    check(cs <= c:titleBarHeight() + 2 and ws <= w:titleBarHeight() + 2, "a rolled window shows its title bar only")
    keepH.body = { x = c:getAbsoluteX() + c:getWidth() / 2, y = c:getAbsoluteY() + c:titleBarHeight() + 200 }

    shot("1_both_rolled_up")
    moveTo(keepH.body.x, keepH.body.y)
end)
waitFor(5, 600, done, function() end)
step(20, function()
    local c = CW()
    local over = false; pcall(function() over = c:isMouseOver() end)
    check(not over and rolled(c), "the pointer where the body was is not over the window (the world gets it), and it stays rolled")
    local c = CW()
    moveTo(c:getAbsoluteX() + c:getWidth() / 2, c:getAbsoluteY() + c:titleBarHeight() / 2)
end)
waitFor(5, 600, done, function() end)
step(20, function()
    check(not rolled(CW()) and rolled(WW()), "pointer on the Character window's title bar: it rolls down, the World window stays up")
    say("char height after roll-down " .. CW():getHeight())
    check(CW():getHeight() > 300, "it rolls down to its full height")
    shot("2_char_hovered_open")
    local c = CW()
    local r = c:pinRect()
    say("pin box at " .. tostring(r and (r.x .. "," .. r.y .. " " .. r.w .. "x" .. r.h)))
    if r then clickAt(c:getAbsoluteX() + r.x + r.w / 2, c:getAbsoluteY() + r.y + r.h / 2) end
end)
waitFor(5, 600, done, function() end)
step(20, function()
    check(ZeD.Halves.isPinned(CW(), "inv") and not ZeD.Halves.isPinned(CW(), "drawer") and md.ZeD_WinPinned and md.ZeD_WinPinned.charInv == true, "a real click on the right pin pins the inventory side only, kept in the character's modData")
    moveTo(sw - 40, sh / 2)
end)
waitFor(5, 600, done, function() end)
step(200, function()
    check(not rolled(CW()), "pinned: stays open with the pointer away 3 s")
    shot("3_pinned_stays_open")
    local w = WW()
    moveTo(w:getAbsoluteX() + w:getWidth() / 2, w:getAbsoluteY() + w:titleBarHeight() / 2)
end)
waitFor(5, 600, done, function() end)
step(20, function()
    check(not rolled(WW()), "the World window rolls down on hover")
    pcall(function() p:setIsAiming(true) end)
    moveTo(sw - 40, sh - 200)
end)
waitFor(5, 600, done, function() end)
step(15, function()
    local aim = false; pcall(function() aim = p:isAiming() end)
    say("aiming " .. tostring(aim))
    check(rolled(WW()), "aiming: the World window rolls up at once when the pointer leaves")
    pcall(function() p:setIsAiming(false) end)
    local c = CW(); local r = c:pinRect()
    moveTo(c:getAbsoluteX() + c:getWidth() / 2, c:getAbsoluteY() + 10)
end)
waitFor(5, 600, done, function() end)
step(10, function()
    local c = CW(); local r = c:pinRect()
    if r then clickAt(c:getAbsoluteX() + r.x + r.w / 2, c:getAbsoluteY() + r.y + r.h / 2) end
end)
waitFor(5, 600, done, function() end)
step(20, function()
    check(not ZeD.Halves.isPinned(CW(), "inv") and md.ZeD_WinPinned.charInv == false, "a second click unpins it")
    moveTo(sw - 40, sh / 2)
end)
waitFor(5, 600, done, function() end)
step(400, function()
    check(rolled(CW()), "unpinned again: it rolls up after the wait")
    shot("4_unpinned_rolled")
    -- put back
    local c, w = CW(), WW()
    if keepPins then md.ZeD_WinPinned = keepPins; c.pinned = keepPins.char == true; w.pinned = keepPins.world == true   -- (the halves read their own keys on the next open)
    else md.ZeD_WinPinned = nil; c.pinned = false; w.pinned = false end
    c:setWindowShaded(false); w:setWindowShaded(false)
    -- the rest of the regression expects open windows: pin both for the run's remainder (restored above only in modData)
    c.pinned, w.pinned = true, true
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnTick.Remove(tick); return end
    wait = wait + 1
    if q.cond then
        if q.cond() or wait >= q.max then wait = 0; qi = qi + 1; local ok, e = pcall(q.fn); if not ok then say("ERR " .. tostring(e)) end end
        return
    end
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then fail = fail + 1; say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
