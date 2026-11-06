-- ZeDUI/tools/qa/zedqa_identity_half.lua  (Nov 5 2026, QA; punch list 89): the half card, the only narrow width the game gives. At the Deck with the
-- scale at 1x (or Large text) the inventory can't hold a full card beside it. License and Simple, bust and full body, with the inventory open.
-- Pictures zqa_idh_<name>.png. grep "ZEDQA idh".
local function say(s) print("ZEDQA idh " .. tostring(s)) end
local I = ZeD.IdentityTab
local CWm = ZeD_CharacterWindow
local function W() return CWm.getWindow() end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_idh_" .. n .. ".png") end); local w = W(); say(string.format("shot %s window %d,%d %dx%d drawer %s", n, w:getX(), w:getY(), w:getWidth(), w:getHeight(), tostring(w._drawerEffW))) end
add(300, function()
    local u = UIManager.getUI()
    for k = 0, u:size() - 1 do local e = u:get(k); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    ZeD.Scale.override = 1.0; ZeD.Scale.refresh(); ZeD.applyTheme(); pcall(ZeD_Window.resetLayout)
end)
add(1500, function() if not CWm.isOpen() then CWm.toggleBothPaired(0) end end)
add(1500, function() local w = W(); w._activeTab = "identity"; w._drawerMode = "tab"; w._drawerOpen = true; w._invDrawerOpen = true end)
add(2500, function() local w = W(); say("drawer " .. tostring(w._drawerEffW) .. ", scale " .. tostring(ZeD.T.scale) .. ", narrow " .. tostring(I.isTall(w._drawerEffW or 0))) end)
for _, style in ipairs({ "immersive", "simple" }) do
    for _, ex in ipairs({ false, true }) do
        add(300, function() I.qaStyle = style; W()._identityPhotoExpanded = ex; W()._identityCustomZoom = 0 end)
        add(2500, function() shot(style .. (ex and "_body" or "_bust")) end)
    end
end
add(300, function() I.qaStyle = nil; W()._identityPhotoExpanded = false; say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
