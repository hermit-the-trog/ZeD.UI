-- ZeDUI/tools/qa/zedqa_mapkey.lua  (Oct 26 2026)
-- The map key (MapsTabKey.lua, built into ZeD) and the Maps tab's extension
-- hook (MapsTabExt.lua): the Key button in the drawer (icon only) and in the
-- unfolded Map window (icon + word), the panel on Survey (the game's eight) and
-- on Color / Paper (the note + Show Survey, which switches back), the mouse path
-- (ZeD.MapsTab.onClick on the zones) and the controller path (the elements'
-- onActivate from buildFocusables), close box. Lists every extension button
-- found, so the same script reads the mods-off and mods-on runs.
-- Captures zqa_mk_<where>_<style>.png. grep "ZEDQA mk".
local function say(s) print("ZEDQA mk " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function ww() return ZeD_WorldWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mk_" .. n .. ".png") end) end
local function zone(id)
    for _, z in ipairs(ww()._mapExtZones or {}) do if z.id == id then return z end end
    return nil
end
local function click(id)
    local z = zone(id)
    if not z then say("ERR no zone " .. id); return false end
    local w = ww()
    w._mapClickFromPopout = w._mapPopout ~= nil   -- (as the pop-out's own mouse handler says)
    ZeD.MapsTab.onClick(w, z.x + 2, z.y + 2)
    w._mapClickFromPopout = false
    return true
end
local function el(id)
    local w = ww()
    if w._mapPopout then w._mapBuildingForPopout = true end
    local ok, els = pcall(ZeD.MapsTab.buildFocusables, w)
    w._mapBuildingForPopout = false
    for _, e in ipairs(ok and els or {}) do if e.id == id then return e end end
    return nil
end
local function exts()
    local t = {}
    for _, z in ipairs(ww()._mapExtZones or {}) do t[#t + 1] = z.id end
    return table.concat(t, ",")
end
local wasStyle
at(2, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    ZeD_WorldWindow.openTab(0, "maps")
end)
at(40, function()
    local w = ww()
    local mp = w._worldMapPanel
    wasStyle = mp and mp.style
    ZeD.MapsTab.setStyle(w, "survey")
    w._mapKeyOpen = false
    local p = getPlayer(); if mp then mp.mapAPI:centerOn(p:getX(), p:getY()); mp:_zoomTo(16) end
    say("extensions: " .. tostring(#ZeD.MapsTabExt.list) .. " | zones: " .. exts())
    if not zone("map:ext:key") then say("FAIL no Key button in the drawer") end
end)
at(60, function()
    local z = zone("map:ext:key")
    say("drawer key button " .. (z and (z.w .. "x" .. z.h .. " hint=" .. tostring(z.hint)) or "missing"))
    click("map:ext:key")
end)
at(80, function()
    say("key open (mouse): " .. tostring(ww()._mapKeyOpen))
    if not zone("map:key:close") then say("FAIL key panel zones missing") end
    shot("drawer_survey")
end)
at(90, function() ZeD.MapsTab.setStyle(ww(), "color") end)
at(140, function()
    say("color: survey button " .. tostring(zone("map:key:survey") ~= nil))
    shot("drawer_color")
end)
at(150, function() ZeD.MapsTab.setStyle(ww(), "paper") end)
at(200, function()
    shot("drawer_paper")
    click("map:key:survey")
end)
at(240, function()
    local mp = ww()._worldMapPanel
    say("Show Survey -> style " .. tostring(mp and mp.style))
    if not (mp and mp.style == "survey") then say("FAIL Show Survey did not switch") end
    -- the controller: the button and the close box as stops
    local e = el("map:key:close")
    if not (e and e.onActivate) then say("FAIL no close stop") else e.onActivate(ww(), e) end
end)
at(250, function()
    say("closed by the pad's close stop: " .. tostring(not ww()._mapKeyOpen))
    local e = el("map:ext:key")
    if not (e and e.onActivate) then say("FAIL no Key stop") else e.onActivate(ww(), e) end
end)
at(260, function()
    say("opened by the pad's Key stop: " .. tostring(ww()._mapKeyOpen))
    ZeD.MapsTab.openPopout(ww())
end)
at(320, function()
    local z = zone("map:ext:key")
    say("pop-out key button " .. (z and (z.w .. "x" .. z.h) or "missing") .. " | zones: " .. exts())
    shot("pop_survey")
    ZeD.MapsTab.setStyle(ww(), "color")
end)
at(380, function() shot("pop_color"); ZeD.MapsTab.setStyle(ww(), "paper") end)
at(440, function()
    shot("pop_paper")
    local e = el("map:key:survey")
    if e and e.onActivate then e.onActivate(ww(), e) else say("FAIL no Show Survey stop in the pop-out") end
end)
at(480, function()
    local mp = ww()._worldMapPanel
    say("pop-out Show Survey (pad) -> " .. tostring(mp and mp.style))
    ww()._mapKeyOpen = false
    ZeD.MapsTab.closePopout(ww())
end)
at(520, function()
    if wasStyle then ZeD.MapsTab.setStyle(ww(), wasStyle) end
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 530 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
