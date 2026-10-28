-- ZeDUI/tools/qa/zedqa_mods_nag.lua  (Oct 27 2026)
-- MAIN MENU ONLY (zedqa_menu_mods_run.ps1 -Script ... -Tag mn): vanilla's About Mods
-- warning (HOOK_MAP row 31). With the once-per-run flag cleared, opening the Mods
-- screen the way its button does shows a ZeD note (kind rich, one OK, vanilla's
-- title and words) and no vanilla ISModsNagPanel; OK closes it and leaves the Mods
-- screen up; opening Mods again shows nothing (once per run, vanilla's flag set).
-- Shots: zqa_mn_*.png in Zomboid/Screenshots. grep "ZEDQA mn".
local MM = ZeD.MainMenu
local P = ZeD.Prompt
local function say(s) print("ZEDQA mn " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mn_" .. n .. ".png") end); say("shot zqa_mn_" .. n .. ".png") end
local pass, fail = 0, 0
local function check(name, ok, detail)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. name .. (detail and (" (" .. tostring(detail) .. ")") or ""))
end
local function vanillaNagShown()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        local t = e:getTable()
        if t and t.Type == "ISModsNagPanel" and e:isVisible() then return true end
    end
    return false
end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local cur

-- (-debug: the UI.DisableWelcomeMessage debug option skips the warning in vanilla and in ZeD;
-- it is on in this rig's debug-options.ini, so the run turns it off and puts it back)
local welcomeOff = nil
at(2, function()
    MM.showView("main")
    getCore():setModsPopupDone(false)
    pcall(function()
        welcomeOff = getDebugOptions():getBoolean("UI.DisableWelcomeMessage")
        getDebugOptions():setBoolean("UI.DisableWelcomeMessage", false)
    end)
    say("flag cleared: isModsPopupDone=" .. tostring(getCore():isModsPopupDone()) .. " welcomeOff was " .. tostring(welcomeOff))
    say("hooked=" .. tostring(ModSelector and ModSelector._zedNagHooked))
end)
at(10, function() MM.act.mods() end)
at(70, function()
    cur = P.top()
    check("a ZeD prompt is on top", cur ~= nil, cur and cur.Type)
    check("it is the rich note", cur and cur.kind == "rich" and cur._zedModsNag == true, cur and cur.kind)
    check("one OK, no Yes / No", cur and cur.ok ~= nil and cur.yes == nil)
    local body = cur and tostring(cur.text) or ""
    check("vanilla's title in the heading", body:find("<H1>", 1, true) ~= nil and body:lower():find("about mods", 1, true) ~= nil, body:sub(1, 40))
    check("vanilla's words in the body", body:find("Project Zomboid community", 1, true) ~= nil)
    check("vanilla's panel not shown", not vanillaNagShown())
    check("once-per-run flag set", getCore():isModsPopupDone())
    check("the Mods screen is up behind it", MM.view == "mods", MM.view)
    if cur then
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        local cx, cy = cur.x + cur.width / 2, cur.y + cur.height / 2
        check("centred on the screen", math.abs(cx - sw / 2) < 4 and math.abs(cy - sh / 2) < 4, string.format("%d,%d of %dx%d", cx, cy, sw, sh))
    end
    shot("01_note")
end)
at(80, function() if cur then cur:press(cur.ok) end end)
at(100, function()
    check("OK closes the note", P.top() == nil, P.top() and P.top().kind)
    check("the Mods screen stays up", MM.view == "mods", MM.view)
    shot("02_after_ok")
end)
at(110, function() MM.showView("main") end)
at(120, function() MM.act.mods() end)
at(180, function()
    check("second open: no note (once per run)", P.top() == nil, P.top() and P.top().kind)
    check("second open: no vanilla panel", not vanillaNagShown())
end)
at(190, function()
    MM.showView("main")
    if welcomeOff ~= nil then pcall(function() getDebugOptions():setBoolean("UI.DisableWelcomeMessage", welcomeOff) end) end
    say(string.format("%d pass, %d fail", pass, fail))
    say("DONE")
end)

local function tick()
    t = t + 1
    for _, s in ipairs(steps) do
        if s.n == t then
            local ok, e = pcall(s.fn)
            if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end
        end
    end
    if t > 200 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
