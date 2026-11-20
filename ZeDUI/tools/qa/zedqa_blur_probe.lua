-- ZeDUI/tools/qa/zedqa_blur_probe.lua  (Nov 17 2026, QA): what blurs the game world in the gallery pictures? The director
-- found ~30 of 65 1.0 captures blurred behind the windows. One picture per suspect, each from the same spot and zoom,
-- each suspect alone and then cleared: a baseline; panic held high; stress high; drunk; the glasses off (the QA
-- character is short-sighted); the game paused. Sharpness is measured afterwards from the pictures (QA, off-line).
-- grep "ZEDQA blp". Pictures Screenshots/zqa_blp_<suspect>.png. Puts back: panic, stress, drunkenness, glasses, speed.
local p = getPlayer()
local function say(s) print("ZEDQA blp " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_blp_" .. n .. ".png") end); say("shot zqa_blp_" .. n) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local S = { st = p:getStats() }
local function hold() pcall(function()
    if S.panic then S.st:set(CharacterStat.PANIC, S.panic) end
    if S.stress then S.st:set(CharacterStat.STRESS, S.stress) end
    if S.drunk then S.st:set(CharacterStat.INTOXICATION, S.drunk) end
end) end
Events.OnPlayerUpdate.Add(hold)
local function clear() S.panic, S.stress, S.drunk = nil, nil, nil
    pcall(function() S.st:set(CharacterStat.PANIC, 0); S.st:set(CharacterStat.STRESS, 0); S.st:set(CharacterStat.INTOXICATION, 0) end) end
local function state(tag)
    local g = "none"
    pcall(function() local w = p:getWornItems(); for i = 0, w:size() - 1 do local it = w:get(i):getItem(); if it:getFullType():find("Glasses") then g = it:getFullType() end end end)
    local paused = false; pcall(function() paused = isGamePaused() end)
    local sm = false; pcall(function() local m = ISSearchManager.getManager(p); sm = m and m.isSearchMode end)
    say(string.format("%s: glasses %s, panic %.0f, stress %.2f, drunk %.0f, paused %s, search mode %s, speed %s", tag, g,
        S.st:get(CharacterStat.PANIC), S.st:get(CharacterStat.STRESS), S.st:get(CharacterStat.INTOXICATION), tostring(paused), tostring(sm), tostring(getGameSpeed())))
end
local function take(tag) step(90, function()
    local ok, err = pcall(state, tag); if not ok then say(tag .. ": state not read: " .. tostring(err)) end
    shot(tag)
end) end

step(30, function()
    say("start")
    pcall(function() if ZeD_CharacterWindow.isOpen(0) then ZeD_CharacterWindow.toggleBothPaired(0) end end)
    pcall(function() Mouse.setCursorVisible(false) end)
    clear()
end)
take("1_base")
step(5, function() S.panic = 60 end)
take("2_panic60")
step(5, function() clear(); S.stress = 0.7 end)
take("3_stress")
step(5, function() clear(); S.drunk = 40 end)
take("4_drunk")
step(5, function() clear() end)
take("5_cleared")
step(5, function()
    pcall(function()
        local w = p:getWornItems()
        for i = 0, w:size() - 1 do local it = w:get(i):getItem(); if it:getFullType():find("Glasses") then S.gl = it end end
        if S.gl then p:removeWornItem(S.gl, false) end
    end)
end)
take("6_no_glasses")
step(5, function() pcall(function() if S.gl then p:setWornItem(S.gl:getBodyLocation(), S.gl) end end) end)
take("7_glasses_back")
step(5, function() pcall(function() setGameSpeed(0) end); pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(0) end) end)
take("8_paused")
step(10, function()
    pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(1) end); pcall(function() setGameSpeed(1) end)
    clear(); Events.OnPlayerUpdate.Remove(hold)
    pcall(function() Mouse.setCursorVisible(true) end)
    say("put back"); say("DONE")
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
