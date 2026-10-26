-- ZeDUI/tools/qa/zedqa_moodles.lua  (Oct 24 2026)
-- The moodles in each of ZeD's three places (Options, ZeD setup, Moodles; the
-- director: "confirm moodles show on centered and left settings"):
--   right   vanilla's column on the right edge, under the watch
--   left    vanilla's column on the left edge
--   bottom  ZeD's copy as a row, centred above the belt (vanilla's column out of sight)
-- The character gets a few moodles (hungry, thirsty, tired, bored, stressed),
-- each place is set, and the moodles are checked on screen where the place puts
-- them, with a picture. The stats and the place are put back.
-- The note (Oct 25 2026), a thought bubble: a moodle that comes on shows its note by itself; in each place the note
-- for the moodle under the pointer (moodle 2) has its trail of bubbles from the cloud to that moodle
-- (picture *_hover); with nothing changing the box goes by itself.
-- grep "ZEDQA mood".
local p = getPlayer()
local pn = p:getPlayerNum()
local MO = ZeD.Moodles
local function say(s) print("ZEDQA mood " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mood_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- after n frames, every frame until cond() is true or maxMs have gone, then fn(ok)
local function waitFor(n, maxMs, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, maxMs = maxMs } end

if not (MO and ZeD.Settings and ZeD.Settings.moodlePlaceOption) then say("ERR ZeD.Moodles is not loaded"); say("DONE"); return end
local opt = ZeD.Settings.moodlePlaceOption
local placeWas = opt:getValue()
local st = p:getStats()
local STATS = { "HUNGER", "THIRST", "FATIGUE", "BOREDOM", "STRESS" }
local kept = {}
local god = p:isGodMod()
local winsWere = ZeD_CharacterWindow.isOpen()

local WANT = { HUNGER = 0.45, THIRST = 0.45, FATIGUE = 0.75, BOREDOM = 0.6, STRESS = 0.6 }
local function setStats()
    for k, v in pairs(WANT) do
        local ok, err = pcall(function() st:set(CharacterStat[k], v) end)
        if not ok then say("ERR set " .. k .. ": " .. tostring(err)) end
    end
end
local function sayStats(when)
    local t = {}
    for _, k in ipairs(STATS) do t[#t + 1] = k .. " " .. string.format("%.2f", st:get(CharacterStat[k]) or -1) end
    say(when .. ": " .. table.concat(t, ", ") .. "; god " .. tostring(p:isGodMod()) .. "; moodles on " .. #MO.active(p))
end

step(10, function()
    for _, k in ipairs(STATS) do
        local cs = CharacterStat[k]
        if cs then kept[k] = st:get(cs) end
    end
    setStats()
    sayStats("set")
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(function() Mouse.setXY(20, 20) end)
end)
step(90, function()
    sayStats("90 frames on")
    -- god mode can hold the stats at zero; it is off for the few seconds this
    -- takes (the stats are kept up by setting them again) and put back after
    if #MO.active(p) < 3 then p:setGodMod(false); setStats() end
end)
step(90, function()
    setStats(); sayStats("180 frames on")
    local L = MO.getLayer(pn)
    local c = L and L._chip
    say("box by itself: " .. tostring(c and c.key) .. " | waiting " .. #(L and L._notices or {}))
    check(c ~= nil and L:_hoverIndex() == nil, "a moodle that came on shows its box by itself, with no pointer on it")
end)

local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local function onScreen(x, y, w, h) return x >= 0 and y >= 0 and x + w <= sw and y + h <= sh and w > 0 and h > 0 end

for _, place in ipairs({ { 1, "right" }, { 2, "left" }, { 3, "bottom" } }) do
    step(10, function() opt:setValue(place[1]) end)
    step(60, function()
        local layer = MO.getLayer(pn)
        local mui = UIManager.getMoodleUI(pn)
        local list = layer and layer._list or {}
        say(place[2] .. ": " .. #list .. " moodles on (" .. table.concat((function() local t = {} for _, m in ipairs(list) do t[#t + 1] = m.key .. " " .. m.level end return t end)(), ", ") .. ")")
        check(MO.place() == place[2] and layer and layer._mode == place[2], place[2] .. ": the place is in effect")
        check(#list >= 3, place[2] .. ": at least three moodles are on")
        check(layer and layer._show, place[2] .. ": the moodles are shown (layer)")
        local size = layer and layer._size or 0
        if place[2] == "bottom" then
            local x, y, w, h = layer:getX(), layer:getY(), layer:getWidth(), layer:getHeight()
            say("bottom row at " .. x .. "," .. y .. " " .. w .. "x" .. h .. "; vanilla's column y " .. mui:getY())
            check(onScreen(x, y, w, h), "bottom: the row is on screen")
            local mid = x + w / 2
            check(math.abs(mid - sw / 2) <= 2, "bottom: the row is centred (middle " .. math.floor(mid) .. " of " .. sw .. ")")
            local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD()
            if hud and hud._drawn then check(y + h <= hud:getY(), "bottom: the row sits above the belt") end
            check(w == #list * size + (#list - 1) * 10, "bottom: one slot per moodle")
            check(mui:getY() < -5000, "bottom: vanilla's column is out of sight (no double)")
        else
            local x, y, w = mui:getX(), mui:getY(), mui:getWidth()
            local stackH = #list * size + (#list - 1) * 10
            say(place[2] .. " column at " .. x .. "," .. y .. " size " .. size .. ", stack " .. stackH .. "; visible " .. tostring(mui:isVisible()))
            check(mui:isVisible(), place[2] .. ": vanilla's column is visible")
            check(onScreen(x, y, w, stackH), place[2] .. ": every moodle is on screen")
            if place[2] == "left" then check(x <= 20, "left: the column is on the left edge (x " .. x .. ")")
            else check(x + w >= sw - 20, "right: the column is on the right edge (x " .. x .. ")") end
            check(layer:getX() == x and layer:getY() == y, place[2] .. ": ZeD's hover layer lies over the column")
        end
    end)
    step(10, function() shot(place[2]) end)
    -- the pointer on moodle 2 (ZeD's box reads the layer's mouse only; a script cannot move a fullscreen pointer)
    step(2, function()
        local L = MO.getLayer(pn)
        local s = L._size or 32
        local lx, ly = s / 2, s + 10 + s / 2
        if L._mode == "bottom" then lx, ly = s + 10 + s / 2, s / 2 end
        L.getMouseX = function() return lx end
        L.getMouseY = function() return ly end
    end)
    step(10, function()
        local L = MO.getLayer(pn)
        local c, s = L._chip, L._size or 0
        local mx0, my0 = 0, s + 10                 -- moodle 2's cell in the layer
        if place[2] == "bottom" then mx0, my0 = s + 10, 0 end
        say(string.format("%s bubble: moodle %s, cloud %s, trail %s from %s", place[2], tostring(c and c.idx),
            c and (c.x .. "," .. c.y .. " " .. c.w .. "x" .. c.h) or "-", c and c.dir or "-", c and (c.tox .. "," .. c.toy) or "-"))
        check(c and c.idx == 2, place[2] .. ": the bubble is for the moodle under the pointer")
        if c then
            local k, len = c.k, ZeD.Bubbles.TRAIL_LEN * c.tk / c.k   -- (the trail is drawn at 2k: its length in the cloud's units)
            local fromCloud, toMoodle
            if place[2] == "bottom" then
                fromCloud = c.dir == "down" and c.toy == c.y + c.h + k
                local endY = c.toy + len * k
                toMoodle = endY <= my0 and endY >= my0 - 4 * k and c.tox > mx0 and c.tox < mx0 + s
            elseif place[2] == "left" then
                fromCloud = c.dir == "left" and c.tox == c.x - k
                local endX = c.tox - len * k
                toMoodle = endX >= mx0 + s and endX <= mx0 + s + 4 * k and c.toy > my0 and c.toy < my0 + s
            else
                fromCloud = c.dir == "right" and c.tox == c.x + c.w + k
                local endX = c.tox + len * k
                toMoodle = endX <= mx0 and endX >= mx0 - 4 * k and c.toy > my0 and c.toy < my0 + s
            end
            check(fromCloud, place[2] .. ": the trail leaves the cloud on the moodle's side")
            check(toMoodle, place[2] .. ": the trail ends at the moodle, level with it")
        end
        shot(place[2] .. "_hover")
    end)
    step(2, function() local L = MO.getLayer(pn); L.getMouseX, L.getMouseY = nil, nil end)
end
-- nothing changing (the stats held), the box goes by itself
waitFor(5, 20000, function() local L = MO.getLayer(pn); setStats(); return L and L._chip == nil end, function(ok)
    local L = MO.getLayer(pn)
    check(ok, "with nothing changing the box goes by itself (" .. tostring(L and L._chip and L._chip.key) .. ")")
end)

-- ZeD setup's "Moodle notices" off (Oct 26 2026): a moodle that changes shows no box by itself; the pointer's still does
local noticesWas = ZeD.Settings.moodleNoticesOption and ZeD.Settings.moodleNoticesOption:getValue() or 2
step(5, function()
    if ZeD.Settings.moodleNoticesOption then ZeD.Settings.moodleNoticesOption:setValue(1) end
    WANT.STRESS = 0.9; WANT.HUNGER = 0.7; setStats()
end)
step(60, function()
    setStats()
    local L = MO.getLayer(pn)
    say("notices off: box " .. tostring(L and L._chip and L._chip.key) .. " | waiting " .. #(L and L._notices or {}))
    check(L and L._chip == nil, "Moodle notices off: a moodle that changes shows no box by itself")
    shot("notices_off")
end)
step(5, function() if ZeD.Settings.moodleNoticesOption then ZeD.Settings.moodleNoticesOption:setValue(noticesWas) end end)

step(10, function()
    opt:setValue(placeWas or 1)
    for k, v in pairs(kept) do pcall(function() st:set(CharacterStat[k], v) end) end
    p:setGodMod(god)
    if winsWere and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    local res
    if s.cond then
        s.t0 = s.t0 or getTimestampMs()
        local okc, done = pcall(s.cond)
        res = okc and done and true or false
        if not res and getTimestampMs() - s.t0 < s.maxMs then wait = 1; return end
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn, res)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
