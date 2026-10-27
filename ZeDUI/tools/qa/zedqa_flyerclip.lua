-- ZeDUI/tools/qa/zedqa_flyerclip.lua  (Oct 27 2026)
-- In game on the ZeD-QA save: flyer pins at the map's edges (FlyerMap.lua,
-- MapsTab render). A read piece's place is panned just past each edge of the
-- Maps tab's map (top-right first) and just inside the top-right corner:
--   * a place past an edge has no pin (layout drops it, nothing to hover);
--   * a place just inside the corner keeps its pin; the part that hangs past
--     the map's edge is clipped and cannot be hovered.
-- Shots zqa_fc_<case>.png (full 4K); the map panel's screen box is printed
-- ("ZEDQA fc box") for cropping. Everything added is taken back. grep "ZEDQA fc".
local p = getPlayer()
local function say(s) print("ZEDQA fc " .. tostring(s)) end
local ID = "sunstarmotel"
local D = 6                      -- px past / inside the edge
local function ww() return ZeD_WorldWindow.getWindow() end
local function mp() return ww()._worldMapPanel end
local read = p:getReadPrintMedia()
local added = false
local place = nil

-- a queue of steps, each run once the map panel has held still (window settle rule)
local queue, waitT, still, last, waited = {}, 0, 0, nil, 0
local function next_(fn, ticks) queue[#queue + 1] = { fn = fn, wait = ticks or 5 } end
local function shape()
    local m = mp()
    if not m then return "nil" end
    return string.format("%d,%d,%d,%d,%s", m:getAbsoluteX(), m:getAbsoluteY(), m:getWidth(), m:getHeight(), tostring(m:isVisible()))
end

local function box(tag)
    local m = mp()
    say(string.format("box %s x=%d y=%d w=%d h=%d screen=%dx%d scale=%s", tag, m:getAbsoluteX(), m:getAbsoluteY(),
        m:getWidth(), m:getHeight(), getCore():getScreenWidth(), getCore():getScreenHeight(), tostring(ZeD.T and ZeD.T.scale)))
end

-- centre the map so the place lands at panel point (ux, uy)
local function putPlaceAt(ux, uy)
    local m = mp(); local api = m.mapAPI
    api:centerOn(place.x, place.y)
    local ax, ay = api:uiToWorldX(ux, uy), api:uiToWorldY(ux, uy)
    api:centerOn(place.x - (ax - place.x), place.y - (ay - place.y))
end

local function ourPin()
    for _, q in ipairs(mp()._flyerPins or {}) do if q.id == ID then return q end end
    return nil
end

local fails = 0
local function check(ok, what) if not ok then fails = fails + 1; say("FAIL " .. what) else say("ok " .. what) end end

local function outsideCase(name, fx, fy)
    next_(function()
        local m = mp(); local w, h = m:getWidth(), m:getHeight()
        putPlaceAt(fx(w), fy(h))
    end, 5)
    next_(function()
        local m = mp(); local api = m.mapAPI
        local tx, ty = api:worldToUIX(place.x, place.y), api:worldToUIY(place.x, place.y)
        say(string.format("%s: place at panel %.1f,%.1f (panel %dx%d)", name, tx, ty, m:getWidth(), m:getHeight()))
        check(ourPin() == nil, name .. ": no pin for a place past the edge")
        box(name)
        getCore():TakeFullScreenshot("zqa_fc_" .. name .. ".png")
    end, 40)
end

next_(function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    ZeD_WorldWindow.openTab(0, "maps")
    if not read:contains(ID) then p:addReadPrintMedia(ID); added = true end
    local d = PrintMediaDefinitions.MiscDetails[ID]
    local r = d and d.location1 and d.location1[1]
    if r then place = { x = (r.x1 + r.x2) / 2, y = (r.y1 + r.y2) / 2 } end
    say("place " .. tostring(place and (place.x .. "," .. place.y)))
end, 2)
next_(function() mp():_zoomTo(15) end, 60)

-- just inside the top-right corner: the pin is kept, its overhang clipped
next_(function()
    local m = mp(); putPlaceAt(m:getWidth() - D, D)
end, 5)
next_(function()
    local m = mp(); local w, h = m:getWidth(), m:getHeight()
    local q = ourPin()
    check(q ~= nil, "inside top-right: the pin is there")
    if q then
        say(string.format("inside top-right: pin x=%d y=%d w=%d h=%d (panel %dx%d)", q.x, q.y, q.w, q.h, w, h))
        check(q.x + q.w > w, "inside top-right: the pin reaches past the right edge (the clip has work to do)")
        local ry = q.y + math.floor(q.h / 2)
        check(ZeD.FlyerMap.hit(m, w - 2, ry) == q, "inside top-right: the visible part hovers")
        check(ZeD.FlyerMap.hit(m, w + 2, ry) == nil, "inside top-right: the clipped part past the edge does not hover")
        check(ZeD.FlyerMap.hit(m, w - 2, -2) == nil, "inside top-right: nothing hovers above the map")
    end
    box("in_topright")
    getCore():TakeFullScreenshot("zqa_fc_in_topright.png")
end, 40)

outsideCase("out_topright", function(w) return w + D end, function() return -D end)
outsideCase("out_top",      function(w) return math.floor(w / 2) end, function() return -D end)
outsideCase("out_right",    function(w) return w + D end, function(h) return math.floor(h / 2) end)
outsideCase("out_bottom",   function(w) return math.floor(w / 2) end, function(h) return h + D end)
outsideCase("out_left",     function() return -D end, function(h) return math.floor(h / 2) end)

next_(function()
    if added then read:remove(ID) end
    pcall(function() mp().mapAPI:centerOn(p:getX(), p:getY()) end)
    say("fails " .. fails)
    say("DONE")
end, 5)

local function onTick()
    local s = queue[1]
    if not s then Events.OnTick.Remove(onTick); return end
    if s.wait > 0 then s.wait = s.wait - 1; return end
    -- the map must hold still for 30 ticks (900 cap) before each step
    local sh = shape()
    if sh == last then still = still + 1 else still, last = 0, sh end
    waited = waited + 1
    if still < 30 and waited < 900 then return end
    if still < 30 then say("WARN the map was still moving after " .. waited .. " ticks") end
    table.remove(queue, 1); still, waited = 0, 0
    local ok, e = pcall(s.fn)
    if not ok then say("ERR " .. tostring(e)) end
end
Events.OnTick.Add(onTick)
say("start")
