-- ZeDUI/tools/qa/zedqa_guide_device.lua  (Nov 4 2026, QA; Build's fb0b560f, the guide's text follows the device)
-- In game on the QA save. ZeD.Guide.onPad is swapped for the run (the pad cannot be plugged in by a script).
--   1. every topic's text on keyboard and on a pad: no "%1" left, no raw <JOYPAD:...>, no IGUI_ key, no "<KEY";
--      key caps (key:) on keyboard, buttons (pad:) on the pad
--   2. a rebound key: Aiming's first binding moved to Z shows "Z"; put back after
--   3. the window on Aiming and Shove: keyboard, then the pad in Xbox, PlayStation and Deck (pictures)
--   4. swap with the guide open, both looks: the topics are read again for the new device
--   5. the book on Aiming, keyboard and PlayStation (pictures)
-- Settings put back. grep "ZEDQA gdv". Pictures zqa_gdv_<w>x<h>_<n>.png.
local function say(s) print("ZEDQA gdv " .. tostring(s)) end
local G, B = ZeD.Guide, ZeD.GuideBook
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_gdv_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local pad = false
local origOnPad = G.onPad
G.onPad = function(pn) return pad end
local look = ZeD.Settings.guideStyleOption
local glyph = ZeD.Settings.glyphOption
local keep = { look = look:getValue(), glyph = glyph:getValue() }
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function entries()
    local out = {}
    local ok, all = pcall(function() return SurvivalGuideEntry.getAll() end)
    if not ok or not all then return out end
    for i = 0, all:size() - 1 do local e = all:get(i); if e:getSubCategory() then out[#out + 1] = e end end
    return out
end
local function findTopic(w, words)
    for _, t in ipairs(w.flat) do
        local tl = string.lower(tostring(t.title))
        for _, wd in ipairs(words) do if tl:find(wd, 1, true) then return t end end
    end
end

-- 1 every topic, both devices
step(30, function()
    local es = entries()
    local badK, badP, capsK, btnP, nK, nP = {}, {}, 0, 0, 0, 0
    for _, e in ipairs(es) do
        local title = getText(e:getTitle())
        for _, joy in ipairs({ false, true }) do
            local ok, s = pcall(G.entryText, e, joy)
            if not ok then (joy and badP or badK)[#(joy and badP or badK) + 1] = title .. " (error " .. tostring(s) .. ")"
            elseif s then
                if joy then nP = nP + 1 else nK = nK + 1 end
                local bad = s:find("%%%d") or s:find("<JOYPAD", 1, true) or s:find("IGUI_", 1, true) or s:find("<KEY", 1, true)
                if bad then local t = joy and badP or badK; t[#t + 1] = title .. ": " .. s:sub(math.max(1, bad - 20), bad + 30) end
                if not joy and s:find("key:", 1, true) then capsK = capsK + 1 end
                if joy and s:find("pad:", 1, true) then btnP = btnP + 1 end
            end
        end
    end
    say(string.format("topics read: keyboard %d (%d with key caps), pad %d (%d with buttons)", nK, capsK, nP, btnP))
    check(#badK == 0, "keyboard text: nothing left unfilled" .. (#badK > 0 and (" (" .. table.concat(badK, " || ", 1, math.min(#badK, 5)) .. ")") or ""))
    check(#badP == 0, "pad text: nothing left unfilled" .. (#badP > 0 and (" (" .. table.concat(badP, " || ", 1, math.min(#badP, 5)) .. ")") or ""))
    check(capsK >= 10 and btnP >= 10, "key caps on keyboard and buttons on the pad in many topics")
end)
-- 2 a rebound key
step(10, function()
    for _, e in ipairs(entries()) do
        if string.lower(getText(e:getTitle())):find("aim", 1, true) then
            local ks = e:getKeys()
            for i = 0, (ks and ks:size() or 0) - 1 do
                local k = tostring(ks:get(i))
                local code = core:getKey(k)
                if code and code ~= 0 and not k:find("IGUI_", 1, true) and not k:find("<", 1, true) then
                    keep.bind, keep.code, keep.alt = k, code, core:getAltKey(k)
                    core:addKeyBinding(k, Keyboard.KEY_Z, keep.alt or 0, false, false, false)
                    local s = G.entryText(e, false) or ""
                    check(s:find("key:Z", 1, true) ~= nil, "a rebound key shows its new key (" .. k .. " on Z)")
                    core:addKeyBinding(k, keep.code, keep.alt or 0, false, false, false)
                    check(core:getKey(k) == keep.code, "the binding is put back (" .. tostring(core:getKey(k)) .. ")")
                    return
                end
            end
        end
    end
    say("SKIP rebind: Aiming has no plain key binding")
end)
-- 3 the window: keyboard, then pad sets
step(10, function() look:setValue(2); pad = false; G.openWindow(0) end)
step(40, function()
    local w = G.get(0)
    local t = findTopic(w, { "aim" })
    if t then w:choose(t.id, true) end
end)
step(60, function() shot("1_window_aiming_keyboard") end)
step(10, function()
    local w = G.get(0)
    local t = findTopic(w, { "shov", "push" })
    if t then w:choose(t.id, true) end
end)
step(60, function() shot("2_window_shove_keyboard") end)
-- 4 swap with the window open
step(10, function() pad = true; glyph:setValue(2) end)
step(30, function()
    local w = G.get(0)
    check(w._joyRead == true, "the window read the topics again for the pad")
    local t = findTopic(w, { "aim" })
    if t then w:choose(t.id, true) end
end)
step(60, function() shot("3_window_aiming_xbox") end)
step(10, function() glyph:setValue(3) end)
step(40, function() shot("4_window_aiming_playstation") end)
step(10, function() glyph:setValue(4) end)
step(40, function() shot("5_window_aiming_deck") end)
step(10, function() pad = false end)
step(30, function() check(G.get(0)._joyRead == false, "back on keyboard, the window reads the keyboard text again"); G.get(0):close() end)
-- 5 the book
step(20, function() look:setValue(1); pad = false; B.open(0, "SurvivalGuide_aiming_title") end)
step(90, function() shot("6_book_aiming_keyboard") end)
step(10, function() pad = true; glyph:setValue(3) end)
step(60, function()
    local b = B.books[0]
    check(b and b._joyRead == true, "the book read the topics again for the pad")
    pcall(function() b:goToTopic((function() for _, t in ipairs(b.flat) do if t.titleKey == "SurvivalGuide_aiming_title" then return t.id end end end)()) end)
end)
step(90, function() shot("7_book_aiming_playstation") end)
step(20, function()
    B.close(0)
    pad = false
    G.onPad = origOnPad
    look:setValue(keep.look); glyph:setValue(keep.glyph)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnRenderTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then fail = fail + 1; say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
