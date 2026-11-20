-- ZeDUI/tools/qa/deep_large_shots.lua  (Nov 20 2026, QA; tag dls): pictures for the bug hunt's P4, text that may not
-- fit at Large text on a small screen. After zedqa_cfg_large.lua and zedqa_style_lite.lua, at 1280x720 or 1280x800:
--   dls_inv.png    both windows on Loot (Lite's "Filter" and "List view" word keys in the column header)
--   dls_kbmap.png  the Keyboard map (key cap labels Esc, F10 to F12; long key names in their boxes)
--   dls_setup.png  ZeD setup from the pause menu
-- No checks beyond "the window opened": the pictures are for the eye. grep "ZEDQA dls".
local function say(s) print("ZEDQA dls " .. tostring(s)) end
local CWm, WWm, KM, MM = ZeD_CharacterWindow, ZeD_WorldWindow, ZeD.KeyboardMap, ZeD.MainMenu
local steps, qi, wait = {}, 1, nil
local function step(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function shot(n)
    pcall(function() Mouse.setXY(4, 4) end)
    pcall(function() getCore():TakeFullScreenshot("dls_" .. n .. ".png") end)
    say("shot dls_" .. n .. " at " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. ", size " .. tostring(ZeD.currentSize) .. ", lite " .. tostring(ZeD.Settings.lite()))
end
step(10, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
end)
step(90, function() say("PASS windows open " .. tostring(CWm.isOpen() and WWm.isOpen())); shot("inv") end)
step(10, function() if CWm.isOpen() then CWm.toggleBothPaired(0) end; pcall(KM.open, 0) end)
step(60, function() local w = KM.windows and KM.windows[0]; say((w and "PASS" or "FAIL") .. " keyboard map open"); shot("kbmap") end)
step(10, function() pcall(KM.close, 0); pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end)
step(40, function() pcall(MM.openOptions) end)
step(40, function()
    local w = MM.pauseOpts
    if w then pcall(function() for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end; w.scroll = 0 end) end
end)
step(40, function() say((MM.pauseOpts and "PASS" or "FAIL") .. " ZeD setup open"); shot("setup") end)
step(10, function()
    local w = MM.pauseOpts
    if w then pcall(function() w:back() end); if w.confirm == "back" then pcall(function() w:discard() end) end end
end)
step(20, function() pcall(function() if MainScreen.instance and MainScreen.instance:isVisible() then ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end end) end)
step(30, function() say("DONE") end)
local function tick()
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
