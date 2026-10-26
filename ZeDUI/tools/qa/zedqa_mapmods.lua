-- ZeDUI/tools/qa/zedqa_mapmods.lua  (Oct 26 2026)
-- With the five map mods on (mapmods_mods.txt): their pieces in ZeD's Maps tab
-- (ModSupport/DRAW_ON_MAP.lua, MapSymbolSizeSlider.lua, POM.lua,
-- BLTAnnotations.lua, BB_WhereAmI.lua through MapsTabExt.lua), in the drawer and
-- in the unfolded Map window, with the mouse path (zones through
-- ZeD.MapsTab.onClick) and the controller path (the stops' callbacks; A on the
-- map through the extension's padA, the erase sweep at the pad cursor).
--   Draw On The Map: the Draw button opens the row; Erase refused without an
--     eraser; a free stroke (mouse), a stroke along the pad cursor, a line; the
--     sliders by click and by the D-pad; the eraser sweep takes strokes off.
--     Every stroke made is taken off at the end; the pens and eraser it added go.
--   Map Symbol Size Slider: the slider under the grid sets ISMap.SCALE and the
--     mod's modData key; Reset; the old value put back.
--   Players On Map: two players stood in for the mod's list (pom_getPlayers,
--     single player has only you): squares and names, the side list (drawer
--     overlay + list button; docked in the unfolded window), a row centres the
--     map. The mod's function put back.
--   Share Annotations: two learned sets made in the mod's ModData over two real
--     marks, one hidden "on the game's map before": hidden on open, shown by its
--     tick, the other deleted through the footer question. All taken back.
--   Where Am I?: the area name over the map.
-- Captures zqa_mm_<name>.png. grep "ZEDQA mm".
local function say(s) print("ZEDQA mm " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function ww() return ZeD_WorldWindow.getWindow() end
local function mp() return ww()._worldMapPanel end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mm_" .. n .. ".png") end) end
local MS = ZeD.ModSupport or {}
local function zone(id)
    for _, z in ipairs(ww()._mapExtZones or {}) do if z.id == id then return z end end
    return nil
end
local function click(id, dx)
    local z = zone(id)
    if not z then say("ERR no zone " .. id); return false end
    local w = ww()
    w._mapClickFromPopout = w._mapPopout ~= nil
    ZeD.MapsTab.onClick(w, z.x + (dx or 2), z.y + math.floor(z.h / 2))
    w._mapClickFromPopout = false
    w._mapExtDrag, w._mapDragging = nil, false
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
local function api() return ZeD.MapNotes.api() end
local function count() local a = api(); return a and a:getSymbolCount() or -1 end

local P, added, count0, wasScale, wasScaleMd, wasPom, wasStyle = nil, {}, nil, nil, nil, nil, nil
local SET_A = "By QA Tester, July 9th 1993 at 14:20"
local SET_B = "By anonymous in Muldraugh, read on July 10th 1993 at 9:05"
local symA, symB = nil, nil

at(2, function()
    P = getPlayer()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    ZeD_WorldWindow.openTab(0, "maps")
    say("mods: draw=" .. tostring(MS.DRAW_ON_MAP ~= nil) .. " size=" .. tostring(MS.MapSymbolSizeSlider ~= nil) .. " pom=" .. tostring(MS.POM ~= nil)
        .. " blt=" .. tostring(MS.BLTAnnotations ~= nil) .. " where=" .. tostring(MS.BB_WhereAmI ~= nil))
    -- no eraser yet: a red pen only (taken back at the end)
    local inv = P:getInventory()
    say("had: pen " .. tostring(inv:containsTypeRecurse("RedPen")) .. " eraser " .. tostring(inv:containsTypeRecurse("Eraser")))
    while inv:containsTypeRecurse("Eraser") do
        local e = inv:getFirstTypeRecurse("Eraser")
        e:getContainer():Remove(e); added[#added + 1] = { back = e }
    end
    added[#added + 1] = { item = inv:AddItem("Base.RedPen") }
end)
at(40, function()
    local w = ww()
    wasStyle = mp() and mp().style
    ZeD.MapsTab.setStyle(w, "survey")
    -- (zoom 18: a stroke dot of the mod's default thickness is about 6 px at 17 and the
    -- engine's SDF symbol shader does not draw it; it shows from about 18 up, as on the game's map)
    mp().mapAPI:centerOn(P:getX(), P:getY()); mp():_zoomTo(18)
    count0 = count()
    say("marks at start " .. count0)
    if not zone("map:ext:draw") then say("FAIL no Draw button") end
    click("map:ext:draw")
end)
at(60, function()
    local s = MS.DRAW_ON_MAP.state(ww())
    say("draw row open " .. tostring(s.open) .. " | tools " .. tostring(zone("map:ext:draw:draw") ~= nil) .. "," .. tostring(zone("map:ext:draw:line") ~= nil)
        .. "," .. tostring(zone("map:ext:draw:erase") ~= nil) .. " sliders " .. tostring(zone("map:ext:draw:thick") ~= nil) .. "," .. tostring(zone("map:ext:draw:fill") ~= nil))
    click("map:ext:draw:erase")
end)
at(70, function()
    local s = MS.DRAW_ON_MAP.state(ww())
    say("erase without an eraser -> tool " .. tostring(s.tool) .. " (want nil)")
    if s.tool then say("FAIL erase armed without an eraser") end
    ww()._mapActiveColor = 4   -- the red pen
    click("map:ext:draw:draw")
end)
at(80, function()
    local w, m = ww(), mp()
    local X = MS.DRAW_ON_MAP.X
    say("draw armed " .. tostring(X.armed(w)))
    -- a free stroke with the mouse: a loop east of the character
    local cx, cy = math.floor(m:getWidth() * 0.62), math.floor(m:getHeight() * 0.4)
    local c1 = count()
    local function where(tag)
        local a = m.mapAPI
        say(tag .. ": centre " .. math.floor(a:getCenterWorldX()) .. "," .. math.floor(a:getCenterWorldY()) .. " zoom " .. string.format("%.2f", a:getZoomF())
            .. " size " .. math.floor(m:getWidth()) .. "x" .. math.floor(m:getHeight()) .. " player at " .. math.floor(a:worldToUIX(P:getX(), P:getY())) .. "," .. math.floor(a:worldToUIY(P:getX(), P:getY())))
    end
    where("before the stroke")
    X.mouseDown(m, w, cx, cy)
    local first = api():getSymbolByIndex(api():getSymbolCount() - 1)
    w._qaFirstDot = first
    say("pressed at " .. cx .. "," .. cy .. " -> world " .. math.floor(m.mapAPI:uiToWorldX(cx, cy)) .. "," .. math.floor(m.mapAPI:uiToWorldY(cx, cy))
        .. " dot " .. tostring(first and first:getSymbolID()) .. " at " .. tostring(first and math.floor(first:getWorldX())) .. "," .. tostring(first and math.floor(first:getWorldY())))
    for i = 1, 24 do
        local a = i / 24 * math.pi * 2
        X.mouseMove(m, w, cx + math.floor(math.cos(a) * 90), cy + math.floor(math.sin(a) * 60))
    end
    X.mouseUp(m, w, cx + 90, cy)
    say("mouse stroke added " .. (count() - c1))
    if count() - c1 < 10 then say("FAIL the stroke made too few marks") end
end)
at(100, function()
    -- a stroke along the controller's cursor (A held, the stick moving it)
    local w, m = ww(), mp()
    local X = MS.DRAW_ON_MAP.X
    local c1 = count()
    m._gpCursorX, m._gpCursorY = math.floor(m:getWidth() * 0.3), math.floor(m:getHeight() * 0.65)
    X.padA(m, w, m._gpCursorX, m._gpCursorY, "down")
    for i = 1, 20 do
        m._gpCursorX = m._gpCursorX + 8
        X.padA(m, w, m._gpCursorX, m._gpCursorY + math.floor(math.sin(i / 3) * 20), "hold")
    end
    X.padA(m, w, m._gpCursorX, m._gpCursorY, "up")
    say("pad stroke added " .. (count() - c1))
    click("map:ext:draw:line")
end)
at(110, function()
    local w, m = ww(), mp()
    local X = MS.DRAW_ON_MAP.X
    say("line armed " .. tostring(MS.DRAW_ON_MAP.state(w).tool))
    local c1 = count()
    X.mouseDown(m, w, math.floor(m:getWidth() * 0.2), math.floor(m:getHeight() * 0.2))
    X.mouseUp(m, w, math.floor(m:getWidth() * 0.5), math.floor(m:getHeight() * 0.25))
    say("line added " .. (count() - c1))
    -- the sliders: a click on Thickness, D-pad right on Fill
    local before = MS.DRAW_ON_MAP.state(w).thick
    local z = zone("map:ext:draw:thick")
    if z then click("map:ext:draw:thick", z.w - 6) end
    say("thickness by click " .. before .. " -> " .. MS.DRAW_ON_MAP.state(w).thick)
    local e = el("map:ext:draw:fill")
    local f0 = MS.DRAW_ON_MAP.state(w).fill
    if e and e.onDpadDir then e.onDpadDir(w, e, "left"); e.onDpadDir(w, e, "left") end
    say("fill by the D-pad " .. f0 .. " -> " .. MS.DRAW_ON_MAP.state(w).fill)
    MS.DRAW_ON_MAP.state(w).thick, MS.DRAW_ON_MAP.state(w).fill = 2.5, 1.0
    click("map:ext:draw:draw")   -- back to Draw for the picture
end)
at(130, function()
    local m, d = mp(), ww()._qaFirstDot
    local a = m.mapAPI
    say("at the picture: centre " .. math.floor(a:getCenterWorldX()) .. "," .. math.floor(a:getCenterWorldY()) .. " zoom " .. string.format("%.2f", a:getZoomF())
        .. " first dot on screen at " .. (d and (math.floor(a:worldToUIX(d:getWorldX(), d:getWorldY())) .. "," .. math.floor(a:worldToUIY(d:getWorldX(), d:getWorldY()))) or "-"))
    shot("draw_drawer")
end)
at(140, function()
    -- the eraser: given, then Erase at the pad cursor over the pad stroke
    local inv = P:getInventory()
    added[#added + 1] = { item = inv:AddItem("Base.Eraser") }
    click("map:ext:draw:erase")
end)
at(150, function()
    local w, m = ww(), mp()
    say("erase armed " .. tostring(MS.DRAW_ON_MAP.state(w).tool))
    ZeD.Input.Detector.setLockedMode("gamepad")
    ZeD.Input.Focus.claimFocus(w)
    ZeD.Input.Focus.focusWhere(w, "worldTabContent", function(e) return e.isCanvasCursor end)
    m._gpCursorX, m._gpCursorY = math.floor(m:getWidth() * 0.3) + 60, math.floor(m:getHeight() * 0.65)
    w._eraseC1 = count()
    MS.DRAW_ON_MAP.X.padA(m, w, m._gpCursorX, m._gpCursorY, "down")
end)
at(156, function() local m = mp(); m._gpCursorX = m._gpCursorX + 30 end)
at(162, function() local m = mp(); m._gpCursorX = m._gpCursorX + 30 end)
at(168, function() shot("erase_pad") end)
at(175, function()
    local w, m = ww(), mp()
    MS.DRAW_ON_MAP.X.padA(m, w, m._gpCursorX, m._gpCursorY, "up")
    say("pad eraser took off " .. (w._eraseC1 - count()))
    if w._eraseC1 - count() <= 0 then say("FAIL the eraser took nothing off") end
    ZeD.Input.Detector.setLockedMode(nil)
    ZeD.MapsTab.openPopout(w)
end)
at(230, function()
    say("pop-out: draw row " .. tostring(zone("map:ext:draw:draw") ~= nil) .. " | label button w " .. tostring(zone("map:ext:draw") and zone("map:ext:draw").w))
    shot("draw_pop")
    ZeD.MapsTab.closePopout(ww())
end)
-- Map Symbol Size Slider
at(260, function()
    local w = ww()
    local S = MS.MapSymbolSizeSlider
    wasScale = ISMap.SCALE
    wasScaleMd = P:getModData()["MapSymbolSizeSlider_currentScale"]
    MS.DRAW_ON_MAP.state(w).open, MS.DRAW_ON_MAP.state(w).tool = false, nil
    w._mapToolsExpanded = true
end)
at(280, function()
    local w = ww()
    local S = MS.MapSymbolSizeSlider
    local z = zone("map:ext:size")
    if not z then say("FAIL no size slider under the grid") ; return end
    click("map:ext:size", z.w - 10)
    say("size by click: ISMap.SCALE " .. tostring(ISMap.SCALE) .. " saved " .. tostring(P:getModData()["MapSymbolSizeSlider_currentScale"]))
    local e = el("map:ext:size")
    if e and e.onDpadDir then e.onDpadDir(w, e, "left") end
    say("size by the D-pad: " .. tostring(ISMap.SCALE))
    S.set(1.266)
end)
at(300, function() shot("size_drawer") end)
at(310, function()
    click("map:ext:size:reset")
    say("Reset -> " .. tostring(ISMap.SCALE) .. " (game's " .. tostring(MS.MapSymbolSizeSlider.DEFAULT) .. ")")
    ISMap.SCALE = wasScale
    P:getModData()["MapSymbolSizeSlider_currentScale"] = wasScaleMd
    ww()._mapToolsExpanded = false
end)
-- Players On Map: two players stood in for the mod's list
at(330, function()
    wasPom = pom_getPlayers
    local me = pom_getPlayer(P)
    pom_getPlayers = function()
        local a = { id = 901, num = 1, username = "Rook_85", invisible = false, alive = true, x = me.x + 40, y = me.y - 45, z = 0 }
        local b = { id = 902, num = 2, username = "mara.k", invisible = false, alive = true, x = me.x + 190, y = me.y + 20, z = 0 }
        return { count = 3, players = { [0] = me, [1] = a, [2] = b } }
    end
    -- (getSpecificPlayer(1 / 2) is nil in single player, so the stand-ins keep their places)
    ww()._mapSideOpen = true
end)
at(350, function()
    local w = ww()
    say("side list: " .. tostring(ZeD.MapsTabExt.hasSide(w)) .. " list button " .. tostring(zone("map:ext:list") ~= nil))
    local z = zone("map:side:players:Rook_85")
    say("Rook_85 row " .. tostring(z ~= nil))
    shot("players_drawer")
    if z then
        click("map:side:players:Rook_85")
        local m = mp()
        say("centred on Rook_85: " .. math.floor(m.mapAPI:getCenterWorldX()) .. "," .. math.floor(m.mapAPI:getCenterWorldY()))
    end
end)
at(370, function()
    local e = el("map:ext:list")
    if e and e.onActivate then e.onActivate(ww(), e) end
    say("list button (pad) -> side open " .. tostring(ww()._mapSideOpen))
end)
at(380, function() shot("players_drawer_hidden"); ww()._mapSideOpen = true end)
-- Share Annotations: two sets over two real marks
at(400, function()
    local L = BLTAnnotations
    local x, y = P:getX(), P:getY()
    symA = ZeD.MapNotes.addSymbol("Skull", x + 30, y - 20, 4)
    symB = ZeD.MapNotes.addSymbol("Burger", x - 25, y + 30, 1)
    local md = L.getOrCreateModData()
    md.symsets[SET_A] = { { x = symA:getWorldX(), y = symA:getWorldY(), type = "texture" } }
    md.symsets[SET_B] = { { x = symB:getWorldX(), y = symB:getWorldY(), type = "texture" } }
    md.hidden[SET_B] = true
    MS.BLTAnnotations.hiddenBefore = nil
    MS.BLTAnnotations.applyHidden()
    ww()._mapSideSecT = nil
    say("hidden on open: B visible " .. tostring(symB:isVisible()) .. " (want false), A visible " .. tostring(symA:isVisible()))
end)
at(420, function()
    local w = ww()
    say("learned rows: A " .. tostring(zone("map:side:notes:" .. SET_A) ~= nil) .. " B " .. tostring(zone("map:side:notes:" .. SET_B) ~= nil))
    shot("notes_drawer")
    click("map:side:notes:" .. SET_B)
end)
at(440, function()
    say("B shown by its tick: " .. tostring(symB:isVisible()) .. " hidden flag " .. tostring(BLTAnnotations.getOrCreateModData().hidden[SET_B]))
    click("map:side:notes:" .. SET_A .. ":x")
end)
at(460, function()
    say("asked: " .. tostring(ww()._mapSideAsk and ww()._mapSideAsk.text))
    shot("notes_ask")
    local e = el("map:side:yes")
    if e and e.onActivate then e.onActivate(ww(), e) else say("FAIL no Delete stop") end
end)
at(480, function()
    local md = BLTAnnotations.getOrCreateModData()
    say("A deleted: set " .. tostring(md.symsets[SET_A] == nil) .. " mark gone " .. tostring(not ZeD.MapNotes.contains(api(), symA)))
    -- everything on: Where Am I? and the key too, in the unfolded window
    say("where: " .. tostring(MS.BB_WhereAmI and MS.BB_WhereAmI.area()))
    ww()._mapKeyOpen = true
    MS.DRAW_ON_MAP.state(ww()).open = true
    ZeD.MapsTab.openPopout(ww())
end)
at(540, function()
    local w = ww()
    say("pop-out docked side w " .. tostring(ZeD.MapsTabExt.dockedSideW(w, w._mapPopout and w._mapPopout._contentPanel)))
    shot("all_pop_survey")
    ZeD.MapsTab.setStyle(w, "color")
end)
at(600, function() shot("all_pop_color"); ZeD.MapsTab.setStyle(ww(), "paper") end)
at(660, function() shot("all_pop_paper"); ZeD.MapsTab.closePopout(ww()) end)
at(700, function() ZeD.MapsTab.setStyle(ww(), "survey") end)
at(740, function() shot("all_drawer_survey") end)
at(750, function()
    -- take everything back
    pom_getPlayers = wasPom
    local L = BLTAnnotations
    pcall(L.deleteSymset, SET_B)
    local md = L.getOrCreateModData()
    md.symsets[SET_A], md.symsets[SET_B], md.hidden[SET_A], md.hidden[SET_B] = nil, nil, nil, nil
    local a = api()
    if a and count0 then
        local n = 0
        for i = a:getSymbolCount() - 1, count0, -1 do
            local s = a:getSymbolByIndex(i)
            if s and s:isTexture() and (s:getSymbolID() == "c" or s == symA or s == symB) then a:removeSymbolByIndex(i); n = n + 1 end
        end
        say("strokes taken off " .. n .. " | marks now " .. a:getSymbolCount() .. " (start " .. count0 .. ")")
    end
    local inv = P:getInventory()
    for _, r in ipairs(added) do
        if r.item and r.item:getContainer() then r.item:getContainer():Remove(r.item) end
        if r.back then inv:AddItem(r.back) end
    end
    local w = ww()
    w._mapKeyOpen, w._mapSideOpen = false, nil
    MS.DRAW_ON_MAP.state(w).open, MS.DRAW_ON_MAP.state(w).tool = false, nil
    if wasStyle then ZeD.MapsTab.setStyle(w, wasStyle) end
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 760 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
