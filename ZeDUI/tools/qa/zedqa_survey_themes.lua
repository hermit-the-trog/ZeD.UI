-- ZeDUI/tools/qa/zedqa_survey_themes.lua  (Nov 18 2026, QA, for Build): pictures of the Survey map's labels per theme.
-- The director: "the text is hard to read... Does it have a stroke around it? An outline? And is the outline the same
-- color as the font?" Build found the game draws map labels as SDF text with an outline and a black drop shadow (a
-- shader constant) and asked for one Survey picture per theme (Dark, Light, High contrast) at zoom 13 over a town and
-- zoom 16 over streets, so it can tell the label colours from the shadow. Not a release check: pictures only, for a
-- diagnosis. Needs rt_kit.lua first. Puts back: the theme, the map style, the view, the tab. grep "ZEDQA svt".
-- Pictures: Screenshots/zqa_svt_<theme>_z13.png and _z16.png.
local Q = RT.make("svt")
local MT = ZeD.MapsTab
local S = { themes = (ZEDQA_SVT_THEMES or { "dark", "light", "hicon" }) }
local function mp() local w = RT.ww(); return w and w._worldMapPanel end
local function shot(n)
    pcall(function() Mouse.setCursorVisible(false) end)
    pcall(function() getCore():TakeFullScreenshot("zqa_svt_" .. n .. ".png") end)
    Q.say("shot zqa_svt_" .. n .. ".png")
end
local function view(x, y, z)
    local m = mp()
    if not m then return end
    pcall(function() m.mapAPI:centerOn(x, y) end)
    pcall(function() m.mapAPI:setZoom(z) end)
end

Q.step(5, function()
    S.base0, S.accent0, S.size0 = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    RT.pairOpen()
end)
Q.step(10, function() Q.check(RT.worldTab("maps"), "the World window's Maps tab opens") end)
Q.waitFor(5, 300, function() return mp() ~= nil end, function(ok)
    Q.check(ok, "the map is up")
    local m = mp()
    if m then
        S.style0 = m.style
        pcall(function() S.cx, S.cy, S.z0 = m.mapAPI:getCenterWorldX(), m.mapAPI:getCenterWorldY(), m.mapAPI:getZoomF() end)
        if m.style ~= "survey" then MT.setStyle(RT.ww(), "survey") end
    end
end)
for _, th in ipairs(S.themes) do
    Q.step(10, function() pcall(ZeD.applyTheme, th, S.accent0, S.size0); Q.say("theme " .. th .. " (now " .. tostring(ZeD.currentBase) .. ")") end)
    Q.step(30, function() view(10630, 9830, 13) end)   -- Muldraugh, the town's names
    Q.step(60, function() shot(th .. "_z13") end)
    Q.step(5, function() view(10615, 9790, 16) end)    -- Muldraugh's streets
    Q.step(60, function() shot(th .. "_z16") end)
end

Q.mark()
Q.step(10, function()
    pcall(ZeD.applyTheme, S.base0, S.accent0, S.size0)
    local m = mp()
    if m and S.style0 and m.style ~= S.style0 then MT.setStyle(RT.ww(), S.style0) end
    if S.cx then view(S.cx, S.cy, S.z0 or 13) end
    RT.worldTab("loot")
    Q.check(ZeD.currentBase == S.base0, "the theme is put back", tostring(ZeD.currentBase))
end)
Q.start()
