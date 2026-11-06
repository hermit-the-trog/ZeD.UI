-- ZeDUI/tools/qa/zedqa_identity.lua  (Nov 5 2026, QA; e6188ce4, punch list 89): the Identity tab. Both styles, the photo to full body and back, the
-- weight's four states, each permit profession and one without, a long name; at 4K also the three themes with the nine accents and UI scale
-- 1x and 2x. The real mouse on the photo, on the model and on the sky around it, both directions (run by release_check.ps1, its helper).
-- Everything is put back or the save is (batch_identity.ps1). Pictures zqa_id_<WxH>_<name>.png. grep "ZEDQA idt".
local function say(s) print("ZEDQA idt " .. tostring(s)) end
local function check(ok, s) say((ok and "PASS " or "FAIL ") .. s) end
local I = ZeD.IdentityTab
local CWm = ZeD_CharacterWindow
local p = getPlayer()
local SZ = getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
local BIG = getCore():getScreenWidth() >= 3000
local function W() return CWm.getWindow() end
local function shot(n)
    local w = W()
    pcall(function() getCore():TakeFullScreenshot("zqa_id_" .. SZ .. "_" .. n .. ".png") end)
    say(string.format("shot %s window %d,%d %dx%d", n, w:getX(), w:getY(), w:getWidth(), w:getHeight()))
end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function showTab() local w = W(); w._activeTab = "identity"; w._drawerMode = "tab"; w._drawerOpen = true end
local function state(style, expanded)
    I.qaStyle = style
    W()._identityPhotoExpanded = expanded
    W()._identityCustomZoom = 0
end
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local keepF, keepS
add(300, function()
    local u = UIManager.getUI()
    for k = 0, u:size() - 1 do local e = u:get(k); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    keepF, keepS = p:getDescriptor():getForename(), p:getDescriptor():getSurname()
end)
add(1500, showTab)
add(2500, function()
    local w = W()
    say("the drawer's width " .. tostring(w._drawerEffW) .. ", scale " .. tostring(ZeD.T.scale) .. ", narrow card " .. tostring(I.isTall and I.isTall(w._drawerEffW or 0)))
end)
-- the styles and the photo
for _, style in ipairs({ "immersive", "simple" }) do
    for _, ex in ipairs({ false, true }) do
        add(300, function() state(style, ex) end)
        add(1800, function() shot(style .. (ex and "_body" or "_bust")) end)
    end
end
-- the weight
for _, tr in ipairs({ "steady", "up", "upup", "down" }) do
    add(300, function() state("immersive", false); I.qaTrend = tr end)
    add(900, function() shot("immersive_trend_" .. tr) end)
    add(100, function() I.qaStyle = "simple" end)
    add(900, function() shot("simple_trend_" .. tr) end)
end
add(100, function() I.qaTrend = nil; I.qaStyle = "immersive" end)
-- the permit
for _, pr in ipairs({ "base:policeofficer", "base:veteran", "base:securityguard", "base:parkranger", "base:burgerflipper", "base:burglar", "base:unemployed" }) do
    add(200, function() I.qaProf = pr end)
    add(900, function() shot("prof_" .. pr:gsub("base:", "")) end)
end
add(200, function() I.qaProf = nil end)
-- a long name
add(200, function()
    p:getDescriptor():setForename("Maximiliana-Bartholomea")
    p:getDescriptor():setSurname("Wolfeschlegelsteinhausen")
    W()._identityCache = nil; W()._identityTimer = 0
    pcall(function() W()._identityCache = I.gatherData(p) end)
end)
add(1200, function() shot("longname_immersive"); I.qaStyle = "simple" end)
add(1000, function()
    shot("longname_simple")
    p:getDescriptor():setForename(keepF); p:getDescriptor():setSurname(keepS)
    pcall(function() W()._identityCache = I.gatherData(p) end)
    I.qaStyle = nil
end)
-- the real mouse: on the model and on the sky, both directions
local function photoAt()
    local w = W()
    local z = w._identityPhotoZone
    local m = w._identityModel
    local panel = w._drawerPanel or w
    return z, m, panel
end
add(800, function() state("immersive", false) end)
for _, spot in ipairs({ "model", "sky" }) do
    for k = 1, 2 do
        add(6000, function()
            local w = W()
            local z, m, panel = photoAt()
            BEFORE_ID = w._identityPhotoExpanded and true or false
            local x, y
            if spot == "model" then x, y = m:getAbsoluteX() + m:getWidth() / 2, m:getAbsoluteY() + m:getHeight() / 2
            else x, y = panel:getAbsoluteX() + z.x + 5, panel:getAbsoluteY() + z.y + 5 end
            say(string.format("%s press %d at %d,%d, zone %s,%s %sx%s, model %d,%d %dx%d, full body %s", spot, k, x, y, tostring(z.x), tostring(z.y), tostring(z.w), tostring(z.h), m:getAbsoluteX(), m:getAbsoluteY(), m:getWidth(), m:getHeight(), tostring(BEFORE_ID)))
            req("left " .. math.floor(x) .. " " .. math.floor(y))
        end)
        add(6000, function()
            local w = W()
            local now = w._identityPhotoExpanded and true or false
            check(now ~= BEFORE_ID, spot .. " press " .. k .. " turns the photo: " .. tostring(BEFORE_ID) .. " to " .. tostring(now))
        end)
    end
end
if BIG then
    -- themes and accents
    local S = ZeD.Settings
    for _, base in ipairs(S.baseKeys) do
        for _, ac in ipairs(S.accentKeys) do
            add(250, function() ZeD.applyTheme(base, ac, nil); state("immersive", false) end)
            add(700, function() shot("theme_" .. base .. "_" .. ac .. "_immersive"); I.qaStyle = "simple" end)
            add(700, function() shot("theme_" .. base .. "_" .. ac .. "_simple") end)
        end
    end
    add(300, function() ZeD.applyTheme("dark", "teal", nil); state("immersive", false) end)
    -- UI scale 1x and 2x
    for _, sc in ipairs({ 1.0, 2.0 }) do
        add(300, function() ZeD.Scale.override = sc; ZeD.Scale.refresh(); ZeD.applyTheme(); pcall(ZeD_Window.resetLayout) end)
        add(1500, function() if not CWm.isOpen() then CWm.toggleBothPaired(0) end; showTab() end)
        for _, style in ipairs({ "immersive", "simple" }) do
            for _, ex in ipairs({ false, true }) do
                add(300, function() state(style, ex) end)
                add(1800, function() shot("scale" .. sc .. "_" .. style .. (ex and "_body" or "_bust")) end)
            end
        end
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
