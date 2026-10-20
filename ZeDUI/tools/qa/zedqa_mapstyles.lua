-- ZeDUI/tools/qa/zedqa_mapstyles.lua  (Oct 19 2026)
-- In game on the ZeD-QA save (whole map known): the Maps tab's three styles,
-- Survey / Color / Paper, each zoomed out (13) and close (17), centred on
-- Muldraugh. Logs the active style and errors. zqa_ms_<style>_<zoom>.png.
-- grep "ZEDQA mst".
local function say(s) print("ZEDQA mst " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function ww() return ZeD_WorldWindow.getWindow() end
local function mp() return ww()._worldMapPanel end
local was
at(2, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    ZeD_WorldWindow.openTab(0, "maps")
end)
local t = 60
for _, style in ipairs({ "survey", "color", "paper" }) do
    at(t, function()
        was = was or (mp() and mp().style)
        ZeD.MapsTab.setStyle(ww(), style)
        local m = mp(); m.mapAPI:centerOn(10900, 9900); m:_zoomTo(13)
    end)
    at(t + 40, function() say(style .. ": style " .. tostring(mp().style) .. " zoom " .. tostring(mp().mapAPI:getZoomF()) .. " images " .. tostring(mp().mapAPI:getImagesCount())); getCore():TakeFullScreenshot("zqa_ms_" .. style .. "_13.png") end)
    at(t + 50, function() mp():_zoomTo(17) end)
    at(t + 90, function() getCore():TakeFullScreenshot("zqa_ms_" .. style .. "_17.png") end)
    t = t + 100
end
at(t, function()
    if was then ZeD.MapsTab.setStyle(ww(), was) end
    local p = getPlayer(); mp().mapAPI:centerOn(p:getX(), p:getY())
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > t + 5 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
