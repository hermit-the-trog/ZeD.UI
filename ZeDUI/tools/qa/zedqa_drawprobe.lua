-- ZeDUI/tools/qa/zedqa_drawprobe.lua  (Oct 26 2026)
-- Draw On The Map: why strokes made into the store did not show. Logs the
-- mod's "c" symbol definition, a stroke dot's size on the map at three sizes,
-- and takes them off again. grep "ZEDQA dp".
local function say(s) print("ZEDQA dp " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function ww() return ZeD_WorldWindow.getWindow() end
local made = {}
at(2, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    ZeD_WorldWindow.openTab(0, "maps")
end)
at(40, function()
    local defs = MapSymbolDefinitions.getInstance()
    local d = defs:getSymbolById("c")
    local function q(o, m) local ok, r = pcall(function() return o[m](o) end); return ok and tostring(r) or "?" end
    say("def c " .. tostring(d) .. (d and (" tex " .. q(d, "getTexturePath") .. " w " .. q(d, "getWidth") .. " h " .. q(d, "getHeight")) or ""))
    local d2 = defs:getSymbolById("Skull")
    say("def Skull " .. tostring(d2 and d2:getWidth()))
    local mp = ww()._worldMapPanel
    local p = getPlayer()
    mp.mapAPI:centerOn(p:getX(), p:getY()); mp:_zoomTo(17)
    say("worldScale " .. tostring(mp.mapAPI:getWorldScale()) .. " zoom " .. tostring(mp.mapAPI:getZoomF()))
    local api = ZeD.MapNotes.api()
    for i, sc in ipairs({ 0.1665, 0.666, 2.0 }) do
        local s = api:addTexture("c", p:getX() + 10 * i, p:getY() - 10)
        s:setRGBA(0.65, 0.054, 0.054, 1); s:setAnchor(0.5, 0.5); s:setScale(sc)
        made[#made + 1] = s
        local s2 = api:addTexture("Skull", p:getX() + 10 * i, p:getY() + 10)
        s2:setRGBA(0.65, 0.054, 0.054, 1); s2:setAnchor(0.5, 0.5); s2:setScale(sc)
        made[#made + 1] = s2
    end
end)
at(80, function()
    local mp = ww()._worldMapPanel
    for _, s in ipairs(made) do
        say(string.format("%s scale %.3f visible %s dispW %s dispH %s at %d,%d", tostring(s:getSymbolID()), s:getScale(), tostring(s:isVisible()),
            tostring(s:getDisplayWidth()), tostring(s:getDisplayHeight()),
            math.floor(mp.mapAPI:worldToUIX(s:getWorldX(), s:getWorldY())), math.floor(mp.mapAPI:worldToUIY(s:getWorldX(), s:getWorldY()))))
    end
    pcall(function() getCore():TakeFullScreenshot("zqa_dp.png") end)
end)
at(90, function()
    local api = ZeD.MapNotes.api()
    for _, s in ipairs(made) do ZeD.MapNotes.remove(s, api) end
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 95 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
