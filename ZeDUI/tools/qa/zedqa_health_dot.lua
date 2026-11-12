-- ZeDUI/tools/qa/zedqa_health_dot.lua  (Nov 11 2026, Build; the health status pixel beside the Character window's name)
-- In game on the QA save with both windows open (the prelude). The character's overall health is held at each value
-- with the debug API (setOverallBodyHealth, set again before every frame drawn so the game's own update never moves
-- it), then put back as it was.
--   1. the bands at their boundaries: 100 and 80 good, 79 and 40 warning, 39 and 21 danger, 20 and 5 danger blinking
--   2. no "NN%" stat in the title stats; the name stays in the title (never hidden) with three pins
--   3. the blink: lit and dark frames both seen at 15 over about two seconds; solid at 63
--   4. the help line's words for the title: "Health: 63%" in the game's word for Health
--   5. pictures at 100, 63, 30 and 15 with three pins (the Deck run: health_dot_deck.txt)
-- Put back: the health, the pins. grep "ZEDQA hdot". Pictures zqa_hdot_<w>x<h>_<n>.png.
local function say(s) print("ZEDQA hdot " .. tostring(s)) end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_hdot_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local p = getPlayer()
local bd = p:getBodyDamage()
local md = p:getModData()
local keep = { hp = bd:getOverallBodyHealth(), pins = md.ZeD_Pins }
local HOLD = nil   -- the health held before each frame drawn (nil: the game's own)
local function cw() return ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow() end
local function tone(c)
    local T = ZeD.T
    return (c == T.positive and "good") or (c == T.warning and "warning") or (c == T.danger and "danger") or tostring(c)
end

local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

-- three pins, as a player would have them
step(20, function()
    md.ZeD_Pins = { { k = "skill", id = "Carpentry" }, { k = "skill", id = "Cooking" }, { k = "skill", id = "Strength" } }
    say("pins: " .. #(ZeD.Pins.list(p)))
end)

-- 1 the bands
local BANDS = { { 100, "good", false }, { 80, "good", false }, { 79, "warning", false }, { 40, "warning", false },
    { 39, "danger", false }, { 21, "danger", false }, { 20, "danger", true }, { 5, "danger", true } }
for _, b in ipairs(BANDS) do
    step(1, function() HOLD = b[1] end)
    step(15, function()
        local w = cw()
        check(w and tone(w._titleMark) == b[2] and (w._titleMarkBlink == true) == b[3],
            b[1] .. ": " .. b[2] .. (b[3] and ", blinking" or "") .. " (got " .. tostring(w and tone(w._titleMark)) .. ", blink " .. tostring(w and w._titleMarkBlink) .. ")")
    end)
end

-- 2 the title with three pins
step(1, function() HOLD = 63 end)
step(15, function()
    local w = cw()
    local ts = w and w.titleStats or {}
    local pct, parts = false, {}
    for _, s in ipairs(ts) do
        parts[#parts + 1] = tostring(s.text)
        if tostring(s.text):match("^%d+%%$") then pct = true end
    end
    say("title '" .. tostring(w and w.title) .. "', stats " .. #ts .. " (" .. table.concat(parts, " | ") .. "), width " .. tostring(w and w:getWidth()) .. ", name drawn " .. tostring(w and w._titleShownW))
    check(not pct, "no health percent among the title stats")
    check(w and not w._hideTitle and (w._titleShownW or 0) > ZeD.T.px(10), "the name stays in the title with pins")
    check(#ts == 4, "three pins and the weight (" .. #ts .. ")")
    -- 4 the hover words
    local want = ZeD.tr("UI_ZeD_Char_HealthHelp", getText("IGUI_XP_Health"), "63%")
    check(w and w._titleHelp == want, "the title's help words: " .. tostring(w and w._titleHelp))
    check(w and tone(w._titleMark) == "warning" and not w._titleMarkBlink, "63: warning, solid")
    shot("1_63_three_pins")
end)
step(1, function() HOLD = 100 end)
step(15, function() shot("2_100") end)
step(1, function() HOLD = 30 end)
step(15, function() shot("3_30") end)

-- 3 the blink at 15: lit and dark frames over about two seconds
local lit, dark = 0, 0
step(1, function() HOLD = 15 end)
step(10, function() shot("4_15") end)
for _ = 1, 120 do
    step(1, function()
        local w = cw()
        if w and ZeD_Window.pixelLit(w._titleMarkBlink) then lit = lit + 1 else dark = dark + 1 end
    end)
end
step(1, function()
    say("at 15: " .. lit .. " lit frames, " .. dark .. " dark")
    check(lit > 0 and dark > 0, "the pixel blinks at 15")
end)

-- put back
step(5, function()
    HOLD = nil
    pcall(function() bd:setOverallBodyHealth(keep.hp) end)
    md.ZeD_Pins = keep.pins
    say("put back: health " .. tostring(bd:getOverallBodyHealth()) .. " (was " .. tostring(keep.hp) .. "), pins")
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)

-- (stepped on each drawn frame, the health set again before the windows draw)
local qi, wait = 1, nil
local function tick()
    if HOLD then pcall(function() bd:setOverallBodyHealth(HOLD) end) end
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fail = fail + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
