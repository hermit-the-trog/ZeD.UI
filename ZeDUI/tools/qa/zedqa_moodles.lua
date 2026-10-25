-- ZeDUI/tools/qa/zedqa_moodles.lua  (Oct 24 2026)
-- The moodles in each of ZeD's three places (Options, ZeD setup, Moodles; the
-- director: "confirm moodles show on centered and left settings"):
--   right   vanilla's column on the right edge, under the watch
--   left    vanilla's column on the left edge
--   bottom  ZeD's copy as a row, centred above the belt (vanilla's column out of sight)
-- The character gets a few moodles (hungry, thirsty, tired, bored, stressed),
-- each place is set, and the moodles are checked on screen where the place puts
-- them, with a picture. The stats and the place are put back.
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

if not (MO and ZeD.Settings and ZeD.Settings.moodlePlaceOption) then say("ERR ZeD.Moodles is not loaded"); say("DONE"); return end
local opt = ZeD.Settings.moodlePlaceOption
local placeWas = opt:getValue()
local st = p:getStats()
local STATS = { "HUNGER", "THIRST", "FATIGUE", "BOREDOM", "STRESS" }
local kept = {}
local god = p:isGodMod()

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
step(90, function() setStats(); sayStats("180 frames on") end)

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
end

step(10, function()
    opt:setValue(placeWas or 1)
    for k, v in pairs(kept) do pcall(function() st:set(CharacterStat[k], v) end) end
    p:setGodMod(god)
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
