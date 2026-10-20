-- ZeDUI/tools/qa/zedqa_flyermap.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the flyer map (FlyerMap.lua).
--   reads four Muldraugh pieces, marks one visited, and checks the visit
--   tracker with a test place under the character; shoots the pins (Paper and
--   Survey), the hover card, the reader opened by a click on a pin, and the
--   pulse of a Show on map. Everything added is taken back.
-- Screenshots zqa_fm_*.png. grep "ZEDQA fm".
local p = getPlayer()
local function say(s) print("ZEDQA fm " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_fm_" .. n .. ".png") end) end
local function ww() return ZeD_WorldWindow.getWindow() end
local function mp() return ww()._worldMapPanel end
local IDS = { "ustoreitmuldraugh", "fossoil1", "sunstarmotel", "muldraughbakesale" }
local added, style0 = {}, nil
local read = p:getReadPrintMedia()
at(2, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    ZeD_WorldWindow.openTab(0, "maps")
    for _, id in ipairs(IDS) do if not read:contains(id) then p:addReadPrintMedia(id); added[#added + 1] = id end end
    local md = p:getModData(); md.ZeD_FlyerSeen = md.ZeD_FlyerSeen or {}
    md.ZeD_FlyerSeen["fossoil1:1:1"] = true
    -- a test place under the character: the tracker must tick it
    PrintMediaDefinitions.MiscDetails.zedqa_here = { location1 = { { x1 = p:getX() - 3, y1 = p:getY() - 3, x2 = p:getX() + 3, y2 = p:getY() + 3 } } }
    say("read " .. read:size() .. " (added " .. #added .. ")")
end)
at(90, function()
    say("tracker ticked the test place: " .. tostring(ZeD.FlyerMap.visited(p, "zedqa_here", 1, 1)))
    style0 = mp().style
    ZeD.MapsTab.setStyle(ww(), "paper")
    mp().mapAPI:centerOn(10700, 9950); mp():_zoomTo(15)
end)
at(130, function()
    local pins = mp()._flyerPins or {}
    local s = {}
    for _, q in ipairs(pins) do s[#s + 1] = q.id .. (q.done and "(done)" or "") end
    say("pins on paper: " .. table.concat(s, ", "))
    shot("paper")
end)
at(140, function() ZeD.MapsTab.setStyle(ww(), "survey"); mp().mapAPI:centerOn(10700, 9950); mp():_zoomTo(15) end)
at(180, function()
    shot("survey")
    -- hover the motel's pin (the mouse is faked on the panel)
    local m = mp()
    for _, q in ipairs(m._flyerPins or {}) do
        if q.id == "sunstarmotel" then
            m._fake = { x = q.x + math.floor(q.w / 2), y = q.y + math.floor(q.h / 2) }
            m.isMouseOver = function() return true end
            m.getMouseX = function() return m._fake.x end
            m.getMouseY = function() return m._fake.y end
        end
    end
end)
at(200, function() say("hover: " .. tostring(mp()._flyerHover and mp()._flyerHover.id)); shot("card") end)
at(210, function()
    local m = mp(); local f = m._fake
    m.isMouseOver, m.getMouseX, m.getMouseY = nil, nil, nil
    if f then m:onMouseDown(f.x, f.y); m:onMouseUp(f.x, f.y) end
end)
at(250, function()
    local r = ZeD.Reader.get(0)
    say("reader open " .. tostring(r and r:isVisible()) .. " media " .. tostring(r and r.media and r.media.id) .. " title " .. tostring(r and r.title))
    shot("reader")
    if r then r:close() end
end)
at(260, function() ISWorldMap.ShowWorldMap(0, 10780, 10180, 16) end)
at(290, function() shot("flash"); say("flash " .. tostring(ZeD.FlyerMap._flash ~= nil)) end)
at(330, function()
    for _, id in ipairs(added) do read:remove(id) end
    local md = p:getModData()
    if md.ZeD_FlyerSeen then md.ZeD_FlyerSeen["fossoil1:1:1"] = nil; md.ZeD_FlyerSeen["zedqa_here:1:1"] = nil end
    PrintMediaDefinitions.MiscDetails.zedqa_here = nil
    if style0 then ZeD.MapsTab.setStyle(ww(), style0) end
    pcall(function() ZeD_WorldWindow.getWindow()._worldMapPanel.mapAPI:centerOn(p:getX(), p:getY()) end)
    say("read back to " .. read:size())
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 335 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
