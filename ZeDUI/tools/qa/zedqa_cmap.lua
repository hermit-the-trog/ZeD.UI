-- ZeDUI/tools/qa/zedqa_cmap.lua  (Nov 2 2026, QA; punch list 67, the controller map)
-- In game. The quick wheel's Help, Controller map (its entry's own run, ZeD.ControllerMap.open) with each button
-- picture set: Xbox, PlayStation, Deck, Nintendo and Off (the names in boxes). For each: the window is the full card
-- wide (or the screen less its margin), centred, the 12 rows; at 4K the body fits with no scroll (the check is
-- skipped on a short screen, where the scroll checks run instead); a picture zqa_cmap_<set>.png. Each opening is shut a
-- different way: B, A, Escape, a REAL left click on the close box (release_check_mouse.ps1 must be running: run with
-- cmap_run.ps1), and B; after each it is off screen and holds no controller focus.
-- On a short screen (the Deck at Large text): the body runs past the window, D-pad Down scrolls it to the end, Up back,
-- the wheel scrolls it, the footer offers "D-pad: Scroll", and the scroll mark is in the picture.
-- The picture set is put back. grep "ZEDQA cmap".
local function say(s) print("ZEDQA cmap " .. tostring(s)) end
local p = getPlayer()
local CM, S = ZeD and ZeD.ControllerMap, ZeD and ZeD.Settings
local D = ZeD and ZeD.DpadWheels
if not (p and CM and CM.open and S and S.glyphOption) then say("ERR the controller map is not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cmap_" .. n .. "_" .. sw .. "x" .. sh .. ".png") end) end
local T = ZeD.T
local glyphWas = S.glyphOption:getValue()
local SETS = { "xbox", "ps", "deck", "nintendo", "off" }
local WAYS = { "B", "A", "Escape", "close box", "B" }
local function setIndex(key) for i, k in ipairs(S.glyphKeys) do if k == key then return i end end end
local function win() return CM.windows[0] end
local function open() return win() and win():isReallyVisible() end

-- the real click, through release_check_mouse.ps1 (as zedqa_release_check.lua asks it)
local clickAsked
local function askClick(btn, x, y)
    local fw = getFileWriter("zedqa_click_done.txt", true, false); if fw then fw:write(""); fw:close() end
    local w = getFileWriter("zedqa_click.txt", true, false)
    if w then w:write(btn .. " " .. math.floor(x) .. " " .. math.floor(y) .. "\n"); w:close() end
    clickAsked = getTimestampMs()
end
local function clickDone()
    local r = getFileReader("zedqa_click_done.txt", false)
    if not r then return false end
    local l = r:readLine(); r:close()
    return l ~= nil and l ~= ""
end

local Q, qi = {}, 1
local function step(k, fn) Q[#Q + 1] = { n = k, fn = fn } end

-- the wheel's entry runs the map (no "Coming later")
step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    local found
    local function walk(list, depth)
        for _, e in ipairs(list or {}) do
            if e.name == ZeD.tr("UI_ZeD_Wheel_ControllerMap") then found = e end
            if type(e.sub) == "function" and depth < 3 and not found then pcall(function() walk(e.sub(p, 0), depth + 1) end) end
        end
    end
    for _, k in pairs(D and D.B or {}) do if type(k) == "function" and not found then pcall(function() walk(k(p, 0), 1) end) end end
    check(found ~= nil and found.run ~= nil and found.off == nil, "67: the wheel's Controller map entry runs (no \"" .. ZeD.tr("UI_ZeD_Wheel_ComingLater") .. "\")")
end)

for si, key in ipairs(SETS) do
    local way = WAYS[si]
    step(5, function()
        local i = setIndex(key)
        if i then S.glyphOption:setValue(i) end
        CM.open(0)
    end)
    step(40, function()
        local w = win()
        if not check(open(), "67 " .. key .. ": the map opens") then return end
        local want = math.min(T.px(480), sw - T.px(20))
        local cx, cy = w:getX() + w:getWidth() / 2, w:getY() + w:getHeight() / 2
        say(string.format("67 %s: window %d,%d %dx%d | body %d of content %d | glyphs %s", key, w:getX(), w:getY(), w:getWidth(), w:getHeight(), w._bodyH or -1, w._contentH or -1, tostring(S.glyphKey())))
        check(math.abs(w:getWidth() - want) <= 1, "67 " .. key .. ": the full card wide (" .. w:getWidth() .. ", want " .. want .. ")")
        check(math.abs(cx - sw / 2) <= 2 and math.abs(cy - sh / 2) <= 2, "67 " .. key .. ": centred on the screen")
        check(#CM.ROWS == 12, "67: the table has 12 rows")
        if sh >= 2000 then check((w._contentH or 0) <= (w._bodyH or 0), "67 " .. key .. ": at 4K the body fits, no scroll") end
        shot(key)
        -- shut it this opening's way
        if way == "B" then w:onJoypadDown(Joypad.BButton)
        elseif way == "A" then w:onJoypadDown(Joypad.AButton)
        elseif way == "Escape" then w:onKeyPress(Keyboard.KEY_ESCAPE)
        elseif way == "close box" then
            local cb = w:closeRect()
            if cb then askClick("left", w:getAbsoluteX() + cb.x + cb.w / 2, w:getAbsoluteY() + cb.y + cb.h / 2) end
        end
    end)
    -- (a close box click waits for the helper: check first, then act)
    local function waitIt()
        if way == "close box" and not clickDone() and getTimestampMs() - (clickAsked or 0) < 15000 then
            table.insert(Q, qi, { n = 5, fn = waitIt }); return
        end
        if way == "close box" then check(clickDone(), "67: the helper made the real click on the close box") end
    end
    step(5, waitIt)
    step(20, function()
        local jd = JoypadState.players[1]
        check(not open(), "67 " .. key .. ": " .. way .. " closes the map")
        check(not (jd and jd.focus == win()), "67 " .. key .. ": the controller's focus is not left on it")
    end)
end

-- the short screen: the body scrolls
step(10, function() S.glyphOption:setValue(setIndex("xbox") or 2); CM.qaJoy = true; CM.open(0) end)   -- (qaJoy: as a pad's focus, so its prompts show)
step(40, function()
    local w = win()
    if (w._contentH or 0) <= (w._bodyH or 0) then say("67: the body fits this screen (" .. w._contentH .. " of " .. w._bodyH .. "): no scroll to check here"); return end
    check(w.scroll == 0, "67 short screen: it opens at the top")
    local prompts = w:getFooterPrompts() or {}
    local dp = false
    for _, pr in ipairs(prompts) do if pr.glyph == "D-PAD" then dp = true end end
    check(dp, "67 short screen: the footer offers the D-pad to scroll")
    for _ = 1, 60 do w:onJoypadDirDown() end
    local maxS = w._contentH - w._bodyH
    check(math.abs(w.scroll - maxS) <= 1, "67 short screen: D-pad Down scrolls to the end (" .. math.floor(w.scroll) .. " of " .. math.floor(maxS) .. ")")
end)
step(10, function()
    local w = win()
    if not (w and (w._contentH or 0) > (w._bodyH or 0)) then return end
    shot("scrolled_end")   -- (a step after the scroll, so the picture has it drawn)
    for _ = 1, 60 do w:onJoypadDirUp() end
    check(w.scroll == 0, "67 short screen: D-pad Up back to the top")
    w:onMouseWheel(1)
    check(w.scroll > 0, "67 short screen: the wheel scrolls it (" .. math.floor(w.scroll) .. ")")
end)
step(20, function() shot("scrolled_wheel"); if open() then win():close() end end)

step(10, function()
    CM.qaJoy = nil
    S.glyphOption:setValue(glyphWas)
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
    say("DONE")
end)

local wait = nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
