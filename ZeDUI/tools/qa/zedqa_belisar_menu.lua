-- ZeDUI/tools/qa/zedqa_belisar_menu.lua  (Nov 8 2026, QA; tag belm): Belisar's report 1, "Stay With Me" (mod id Bridge).
-- MAIN MENU ONLY. Walks New Game > Sandbox > map > sandbox settings > traits > ZeD's Looks window, presses ZeD's Play (which sends the
-- game's NEXT to the mod's wrapped CharacterCreationMain.onOptionMouseDown), then reports what is on screen: the mod's companion
-- design screen (BridgePregame.screen), ZeD's desk, who is on top, the mod's "Select to load" presets list (lookCombo) and a pick from it,
-- then the mod's Back (BridgePregame.back) and whether ZeD's Looks window comes back. Nothing is started.
-- Shots: zqa_belm_*.png in Zomboid/Screenshots. grep "ZEDQA belm".
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA belm " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_belm_" .. n .. ".png") end); say("shot " .. n) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end return ok end
local function vwin(view)
    for _, rv in ipairs(MM.views) do if rv.view == view then return R[rv.field] end end
    return nil
end
local function vis(o) local ok, v = pcall(function() return o:isVisible() end); return ok and v or false end
local steps = {}
local function step(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
step(30, function()
    check(type(BridgePregame) == "table" and BridgePregame.installed == true, "the mod's pregame hook is installed (BridgePregame.installed)")
    check(type(BridgeAppearance) == "table" and type(BridgeLooks) == "table", "the mod's appearance and looks code is loaded")
    MM.showView("newgame")
end)
step(40, function()
    local nw = R.newWin
    for i, d in ipairs(nw:items()) do if d.mode == "Sandbox" then nw.sel = i end end
    nw:next()
end)
step(60, function() vwin("spawn"):next() end)
step(60, function() vwin("sandbox"):next() end)
step(60, function() vwin("traits"):next() end)
step(90, function()
    local W = vwin("looks")
    check(W ~= nil and MM.view == "looks", "ZeD's Looks window is up")
    check(BridgePregame.eligible(), "the mod counts this as a new game it can design a companion for")
    shot("1_zed_looks")
    W:play()
end)
step(120, function()
    local S = BridgePregame.screen
    check(BridgePregame.active == true, "the mod's design screen took over (BridgePregame.active)")
    check(S ~= nil and vis(S), "the mod's design screen is visible")
    say("ZeD view now: " .. tostring(MM.view) .. "; ZeD desk visible: " .. tostring(vis(R)))
    say("screen size " .. tostring(S and S:getWidth()) .. "x" .. tostring(S and S:getHeight()) .. "; main screen " .. tostring(MainScreen.instance:getWidth()) .. "x" .. tostring(MainScreen.instance:getHeight()))
    say("lookCombo options: " .. tostring(S and S.lookCombo and S.lookCombo.options and #S.lookCombo.options))
    shot("2_companion_design")
end)
step(10, function()
    local S = BridgePregame.screen
    if not S or not S.lookCombo then return end
    local n = #(S.lookCombo.options or {})
    if n > 0 then
        S.lookCombo.selected = 1
        local ok, err = pcall(function() S:onLook(S.lookCombo) end)
        check(ok, "picking the first preset in the mod's list runs" .. (ok and "" or (": " .. tostring(err))))
        say("preset picked: " .. tostring(S:selectedLook()))
    else
        say("the presets list is empty (no saved looks yet)")
    end
end)
step(40, function() shot("3_preset_picked") end)
-- the mouse: is the mod's screen on top of ZeD's desk at the point of its Back button?
step(10, function()
    local S = BridgePregame.screen
    if not S then return end
    local ok, top = pcall(function() return UIManager.getPickedUI and UIManager.getPickedUI() end)
    say("picked UI at the pointer: " .. tostring(ok and top and top.Type or top))
    local ok2, err = pcall(function() BridgePregame.back() end)
    check(ok2, "the mod's Back runs" .. (ok2 and "" or (": " .. tostring(err))))
end)
step(120, function()
    say("after Back: ZeD view " .. tostring(MM.view) .. "; mod screen active " .. tostring(BridgePregame.active) .. "; ZeD looks visible " .. tostring(vis(vwin("looks"))))
    check(MM.view == "looks" and BridgePregame.active == false, "Back returns to ZeD's Looks window")
    shot("4_back_to_looks")
end)
step(30, function()
    pcall(function() vwin("looks"):back() end); pcall(function() vwin("traits"):back() end)
    pcall(function() vwin("sandbox"):back() end); pcall(function() vwin("spawn"):back() end)
    pcall(function() R.newWin:back() end); MM.showView("main")
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)
local qi, wait = 1, nil
local function tick()
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
