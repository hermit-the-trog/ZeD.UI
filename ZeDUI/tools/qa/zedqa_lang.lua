-- ZeDUI/tools/qa/zedqa_lang.lua  (Nov 2 2026, QA; punch list 62, ZeD's machine-translated languages)
-- In game, with the game's language set before launch (lang_run.ps1 -Lang TR | CN | PTBR). Reads every ZeD key from
-- ZeD's English UI.json and counts, in the game's language: keys with no text at all (a raw UI_ZeD_ key would show),
-- and keys whose text is the same as the English (not translated; some are legitimately the same: names, numbers).
-- The language is one of ZeD's machine drafts (ZeD.isMachineLangText on its name). Pictures: both windows on Loot, the
-- Health and Skills tabs, the action bar with an action running (its words in the pixel capitals), the watch on the
-- belt and in the corner (the weekday in the pixel face). grep "ZEDQA lng"; shots zqa_lng_<lang>_*.png.
local function say(s) print("ZEDQA lng " .. tostring(s)) end
local p = getPlayer()
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local lang = "?"
pcall(function() lang = tostring(Translator.getLanguage()) end)
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_lng_" .. lang .. "_" .. n .. ".png") end) end
local CW = ZeD_CharacterWindow

-- ZeD's keys, from its English file
local keys = {}
local function readKeys()
    local r
    for _, path in ipairs({ "media/lua/shared/Translate/EN/UI.json", "42/media/lua/shared/Translate/EN/UI.json" }) do
        pcall(function() r = getModFileReader("ZeD_UI", path, false) end)
        if r then break end
    end
    if not r then return false end
    local l = r:readLine()
    while l do
        local k = l:match('^%s*"(UI_ZeD_[%w_]+)"%s*:')
        if k then keys[#keys + 1] = k end
        l = r:readLine()
    end
    r:close()
    return true
end

local Q, qi = {}, 1
local function step(k, fn) Q[#Q + 1] = { n = k, fn = fn } end
local watch, apple
step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("the game's language: " .. lang)
    check(lang ~= "EN", "the game runs in " .. lang)
    local name = ""
    pcall(function() name = tostring(Translator.getLanguage():text()) end)
    local machine = ZeD.isMachineLangText and ZeD.isMachineLangText(name)
    say("its name in the language list: " .. name .. " | a ZeD machine draft " .. tostring(machine))
    check(machine == true, lang .. " is one of ZeD's machine-translated languages (the list marks it)")
    if not check(readKeys() and #keys > 500, "ZeD's English keys read (" .. #keys .. ")") then return end
    local raw, same, sameList, rawList = 0, 0, {}, {}
    for _, k in ipairs(keys) do
        local s = getTextOrNull(k, "%1", "%2", "%3", "%4")   -- (42.22: a word with a placeholder asked without its arguments logs an exception)
        if s == nil then raw = raw + 1; if #rawList < 12 then rawList[#rawList + 1] = k end
        else
            local en = ZeD.trEnglish and ZeD.trEnglish(k) or nil
            if en and s == en and #s > 3 then same = same + 1; if #sameList < 12 then sameList[#sameList + 1] = k end end
        end
    end
    say(string.format("%s: %d keys | no text %d | same as the English %d (e.g. %s)", lang, #keys, raw, same, table.concat(sameList, ", ")))
    if raw > 0 then say("no text: " .. table.concat(rawList, ", ")) end   -- (Nov 3 2026: name them)
    check(raw == 0, lang .. ": every ZeD key has text (no raw UI_ZeD_ key can show)")
    check(same < #keys * 0.08, lang .. ": nearly every key is translated (" .. same .. " the same as the English)")
end)
step(10, function() if not (CW.isOpen() and ZeD_WorldWindow.isOpen()) then CW.toggleBothPaired(0) end end)
step(60, function() shot("1_windows") end)
local function charTab(id)
    local w = CW.getWindow()
    for _, z in ipairs((w and w._tabStripPanel and w._tabStripPanel._hitZones) or {}) do
        if z.id == "tab:" .. id then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
end
step(5, function() charTab("health") end)
step(40, function() shot("2_health") end)
step(5, function() charTab("skills") end)
step(40, function() shot("3_skills"); charTab("skills") end)
-- the action bar: an apple eaten (the bar's words in the pixel capitals)
step(10, function()
    if CW.isOpen() then CW.toggleBothPaired(0) end
    apple = p:getInventory():AddItem("Base.Apple")
    if apple then ISTimedActionQueue.add(ISEatFoodAction:new(p, apple, 1)) end
end)
step(40, function() shot("4_action_bar") end)
-- the watch: on the belt, then in the corner
local placeWas = ZeD.Settings.watchPlaceOption and ZeD.Settings.watchPlaceOption:getValue()
step(30, function()
    pcall(function() ISTimedActionQueue.clear(p) end)
    watch = p:getInventory():AddItem("Base.WristWatch_Left_DigitalBlack")
    if watch then p:setWornItem(watch:getBodyLocation(), watch) end
    if ZeD.Settings.watchPlaceOption then ZeD.Settings.watchPlaceOption:setValue(2) end
end)
step(40, function() shot("5_watch_corner") end)
step(10, function()
    if watch then pcall(function() p:removeWornItem(watch) end); pcall(function() p:getInventory():Remove(watch) end) end
    if apple then pcall(function() if apple:getContainer() then apple:getContainer():Remove(apple) end end) end
    if ZeD.Settings.watchPlaceOption and placeWas then ZeD.Settings.watchPlaceOption:setValue(placeWas) end
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
