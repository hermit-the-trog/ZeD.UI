-- ZeDUI/tools/qa/rt_media.lua  (Nov 18 2026, QA; tag rt_media): the release test's media row (ZeDUI/qa/RELEASE_TEST.md).
-- Built on rt_kit.lua (the global RT); run after it. grep "ZEDQA rt_media".
--   1. the Radio tab's faces (RadioTab.lua, RadioPlates.lua, RtvFace.lua, TwoWayFace.lua): a radio (the red one), a
--      two-way (the ValuTech walkie) and a CD player, each given and held: the Character window's Radio tab opens on
--      it, its own face draws, its power control turns the set on (the game's device data says so), TUNE turns the
--      frequency a step each way (the CD player has no tuner: VOL raises its volume), power turns it off again; on
--      the radio the pad's first stop is power and A on it works the set (FocusManager's elements)
--   2. a TV placed on a free room square beside the character, on the grid (the game's grid flag and the shut-off
--      day raised for the test, put back after; the Fossoil at West Point when no room is in reach): the World
--      window's Radio tab lists it, its face draws, power turns it on, CH up tunes the next channel, power off
--   3. the Maps tab (MapsTab.lua, MapNotes.lua): the map draws; Survey, Color and Paper (when this install has the
--      paper map) each restyle the map (Paper hides the map's own place labels, the other two show them, the note
--      hand keeps its ink on all three); a note placed with the note tool at the cursor (the pad's A) lands in the
--      game's own map marks, and Delete in ZeD's menu on it takes it off
--   4. the Journal tab (JournalTab.lua, ZeD_JournalReaders.lua): the Papers page lists a flyer carried, the
--      Notebooks page lists a notebook carried and a click on its row picks it; a line written from the quick note
--      (ZeD_WriteNoteAction) is kept on the page
--   5. the reader (ZeD_Reader.lua): Open full opens the notebook in ZeD's reader with the line on its page; a second
--      page written there and Done keep both pages' text
-- (The newspaper / print media page is not tested here: the director ruled it is not ZeD's.)
-- Every surface is measured with RT.bounds. Put back: the hands, the sets taken away, the map's style and marks, the
-- time of day, the grid, the character's place, both windows on Loot and open or shut as found; RT.takeBack takes
-- what was given.
if not RT then
    print("ZEDQA rt_media FAIL the kit (rt_kit.lua) is not loaded")
    print("ZEDQA rt_media VERDICT FAIL 1")
    print("ZEDQA rt_media DONE")
    return
end
local Q = RT.make("rt_media")
Q.maxMs = 780000                     -- (the runner gives this script 900 s: the put-back runs before that)
local p, pn = RT.p, RT.pn
local R, RTab, O, TW = ZeD.Rtv, ZeD.RadioTab, ZeD.RadioOps, ZeD.TwoWay
local N, MT, J = ZeD.MapNotes, ZeD.MapsTab, ZeD.JournalReaders
-- the run's state, one table (Kahlua's local limit)
local S = { placed = {}, settle = {}, moved = false }
local H = {}

-- ===================================================================== helpers
function H.CW() return RT.cw() end
function H.WW() return RT.ww() end
function H.tw(w) return w and w._radioTw end
function H.hit(t, id)
    for _, h in ipairs((t and t.hits) or {}) do if h.id == id then return h end end
    return nil
end
-- a press on a face's control through the tab's own mouse handler (side "l" / "r": a knob's left / right half)
function H.click(w, id, side)
    local h = H.hit(H.tw(w), id)
    if not h then return false end
    local x = (side == "l" and h.x + 2) or (side == "r" and h.x + h.w - 3) or (h.x + math.floor(h.w / 2))
    RTab.onClick(w, x, h.y + math.floor(h.h / 2))
    return true
end
function H.dd(dev)
    local d = nil
    pcall(function() d = dev:getDeviceData() end)
    return d
end
function H.on(dev) local d = H.dd(dev); local v = false; pcall(function() v = d:getIsTurnedOn() end); return v end
function H.chan(dev) local d = H.dd(dev); local v = -1; pcall(function() v = d:getChannel() end); return v end
function H.vol(dev) local d = H.dd(dev); local v = -1; pcall(function() v = d:getDeviceVolume() end); return v end
-- the drawer has stopped growing (its width the same three frames running)
function H.settled(w)
    local e = math.floor(w and w._drawerEffW or -1)
    local s = S.settle[w] or { v = -2, n = 0 }
    S.settle[w] = s
    if e == s.v then s.n = s.n + 1 else s.v, s.n = e, 0 end
    return s.n >= 3 and e > 0
end
-- a set given, batteries in, off, half volume, no presets
function H.newSet(ft)
    local it = RT.give(ft)
    if not it then return nil end
    local d = H.dd(it)
    if d then
        pcall(function()
            if d:getIsBatteryPowered() then d:setHasBattery(true); d:setPower(0.6) end
        end)
        pcall(function() d:setIsTurnedOn(false) end)
        pcall(function() d:setDeviceVolume(0.5) end)
        pcall(function() d:setMicIsMuted(true) end)
        pcall(function() local pc = d:getDevicePresets(); if pc then pc:getPresets():clear() end end)
    end
    return it
end
function H.hold(it)
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    if it then pcall(function() p:setPrimaryHandItem(it) end) end
end
function H.clearQueue() pcall(function() ISTimedActionQueue.clear(p) end) end

-- ===================================================================== 0. setup
Q.step(5, function()
    S.prim, S.sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    S.winsWere = RT.isOpen()
    S.gt = getGameTime()
    S.tod0 = S.gt:getTimeOfDay()
    S.home = { x = p:getX(), y = p:getY(), z = p:getZ() }
    RT.pairOpen()
    H.hold(nil)
    pcall(function() Mouse.setXY(20, 20) end)
    Q.check(R ~= nil and RTab ~= nil and O ~= nil and TW ~= nil and N ~= nil and MT ~= nil and J ~= nil,
        "the media modules are loaded (RtvFace, RadioTab, RadioOps, TwoWayFace, MapNotes, MapsTab, JournalReaders)")
end)

-- ===================================================================== 1. the portable sets in the Character window
local SETS = {
    { name = "the radio", ft = "Base.RadioRed", pid = "radio_red", drv = "rtv", power = "power", tune = true, pad = true },
    { name = "the two-way", ft = "Base.WalkieTalkie2", pid = "walkie_valutech", drv = "tw", power = "vol", tune = true },
    { name = "the CD player", ft = "Base.CDplayer", pid = "cd_player", drv = "rtv", power = "power", tune = false },
}
function H.drv(m) return (m.drv == "tw") and TW or R end
function H.portable(m)
    Q.step(5, function()
        S.cur = H.newSet(m.ft)
        Q.check(S.cur ~= nil, m.name .. ": given (" .. m.ft .. ")")
        H.hold(S.cur)
    end)
    Q.waitFor(5, 200, function()
        local w = H.CW()
        local r = w and w._radios and w._radios[1]
        return S.cur ~= nil and r ~= nil and r.radioInstance == S.cur
    end, function(ok)
        Q.check(ok and RT.charTab("radio"), m.name .. ": in hand, the Character window's Radio tab opens on it from the strip")
    end)
    Q.waitFor(5, 300, function()
        local t = H.tw(H.CW())
        return S.cur ~= nil and t ~= nil and t.dev == S.cur and H.settled(H.CW())
    end, function(ok)
        local t = H.tw(H.CW())
        local base = t and H.drv(m).basePid(t.pid)
        Q.check(ok and base == m.pid, m.name .. ": its own face draws in the tab", "face " .. tostring(t and t.pid) .. ", want " .. m.pid)
        RT.bounds(Q, m.name .. "'s face in the Radio tab")
        S.wasOn = S.cur and H.on(S.cur)
        Q.check(H.click(H.CW(), m.power), m.name .. ": the face has its power control (" .. m.power .. ")")
    end)
    Q.step(10, function()
        if not S.cur then return end
        Q.check(H.on(S.cur) and not S.wasOn, m.name .. ": a click on power turns the set on (the game's device data)")
        if m.tune then
            S.ch = H.chan(S.cur)
            Q.check(H.click(H.CW(), "tune", "r"), m.name .. ": the face has its tuning knob")
        else
            S.v0 = H.vol(S.cur)
            if not H.click(H.CW(), "volup") then H.click(H.CW(), "vol", "r") end
        end
    end)
    if m.tune then
        Q.step(8, function()
            if not S.cur then return end
            Q.check(H.chan(S.cur) == S.ch + O.STEP, m.name .. ": TUNE's right half tunes up one step", S.ch .. " -> " .. H.chan(S.cur))
            H.click(H.CW(), "tune", "l")
        end)
        Q.step(8, function()
            if not S.cur then return end
            Q.check(H.chan(S.cur) == S.ch, m.name .. ": TUNE's left half tunes back down", "now " .. H.chan(S.cur) .. ", want " .. S.ch)
        end)
    else
        Q.step(8, function()
            if not S.cur then return end
            Q.check(H.vol(S.cur) > S.v0 + 0.05, string.format("%s: VOL raises the volume (%.2f -> %.2f; it has no tuner)", m.name, S.v0, H.vol(S.cur)))
        end)
    end
    Q.step(3, function() if S.cur then H.click(H.CW(), m.power) end end)
    Q.step(10, function()
        if not S.cur then return end
        Q.check(not H.on(S.cur), m.name .. ": power again turns it off")
    end)
    if m.pad then
        -- the pad: FocusManager asks the tab for its stops; the first is power, and A on it works the set
        Q.step(3, function()
            local els = RTab.buildFocusables(H.CW()) or {}
            local e = els[1]
            Q.check(e ~= nil and e.id == "radio:tw:power" and e.onActivate ~= nil, m.name .. ": the pad's first stop on the face is power",
                tostring(e and e.id))
            if e and e.onActivate then e.onActivate(H.CW(), e) end
        end)
        Q.step(10, function()
            if not S.cur then return end
            Q.check(H.on(S.cur), m.name .. ": A on the power stop turns it on")
            local els = RTab.buildFocusables(H.CW()) or {}
            if els[1] and els[1].onActivate then els[1].onActivate(H.CW(), els[1]) end
        end)
        Q.step(10, function() if S.cur then Q.check(not H.on(S.cur), m.name .. ": A again turns it off") end end)
    end
    Q.step(3, function() H.hold(nil) end)
end
for _, m in ipairs(SETS) do H.portable(m) end

-- ===================================================================== 2. a TV on the grid, in the World window
-- (zedqa_rtv.lua's staging: a square gets grid power only inside a room, so the TV goes on a free room square next to
-- the character; the set's data is touched only once it is on its square)
local RING = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
local STORE = { x0 = 12052, y0 = 7117, x1 = 12069, y1 = 7126 }   -- the Fossoil at West Point
function H.sq(x, y, z) local s = nil; pcall(function() s = getCell():getGridSquare(x, y, z) end); return s end
function H.freeSq(x, y, z)
    local sq = H.sq(x, y, z)
    local ok = false
    if sq then pcall(function() ok = sq:isFree(false) and not sq:getVehicleContainer() end) end
    return ok and sq or nil
end
function H.roomRing(x, y, z)
    local here = H.freeSq(x, y, z)
    local out = {}
    if not here then return out end
    for _, d in ipairs(RING) do
        local n = H.freeSq(x + d[1], y + d[2], z)
        local reach = false
        if n then pcall(function() reach = n:getRoom() ~= nil and here:canReachTo(n) end) end
        if reach then out[#out + 1] = n end
    end
    return out
end
function H.findSpot(cx, cy, cz, rad)
    for r = 0, rad do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local ring = H.roomRing(cx + dx, cy + dy, cz)
                    if #ring >= 2 then return { x = cx + dx + 0.5, y = cy + dy + 0.5, z = cz, ring = ring } end
                end
            end
        end
    end
    return nil
end
function H.moveTo(x, y, z)
    pcall(function() p:teleportTo(x, y, z) end)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end)
end
function H.setGrid(on)
    pcall(function()
        if S.elec then S.elec:setValue(on and 99999 or 0); S.so:toLua() end
    end)
    pcall(function() getWorld():setHydroPowerOn(on and true or false) end)
end
function H.gridBack()
    if S.gridTouched then
        pcall(function() if S.elec and S.elecWas ~= nil then S.elec:setValue(S.elecWas); S.so:toLua() end end)
        pcall(function() getWorld():setHydroPowerOn(S.hydroWas) end)
        S.gridTouched = false
    end
end
function H.removeTv()
    for _, obj in ipairs(S.placed) do
        pcall(function() local sq = obj:getSquare(); if sq then sq:transmitRemoveItemFromSquare(obj) end end)
    end
    S.placed = {}
    S.tv = nil
end
function H.stopI(o) local s = R.stopOf(H.chan(o)); return s and s.i or 0 end

Q.step(5, function()
    pcall(function() S.so = getSandboxOptions(); S.elec = S.so:getOptionByName("ElecShutModifier"); S.elecWas = S.elec:getValue() end)
    pcall(function() S.hydroWas = getWorld():isHydroPowerOn() end)
    S.gridTouched = true
    H.setGrid(true)
    S.spot = H.findSpot(math.floor(S.home.x), math.floor(S.home.y), math.floor(S.home.z), 45)
    if not S.spot then
        S.moved, S.t0 = true, getTimestampMs()
        Q.say(string.format("no room in reach of %d,%d: to the Fossoil at West Point for the TV", math.floor(S.home.x), math.floor(S.home.y)))
        H.moveTo(math.floor((STORE.x0 + STORE.x1) / 2) + 0.5, math.floor((STORE.y0 + STORE.y1) / 2) + 0.5, 0)
    end
end)
Q.waitFor(5, 3000, function()
    return not S.moved or (H.sq(STORE.x0, STORE.y0, 0) ~= nil and H.sq(STORE.x1, STORE.y1, 0) ~= nil and getTimestampMs() - S.t0 > 9000)
end, function()
    if S.moved then S.spot = H.findSpot(math.floor((STORE.x0 + STORE.x1) / 2), math.floor((STORE.y0 + STORE.y1) / 2), 0, 12) end
    Q.check(S.spot ~= nil, "a free room square with room for the TV beside it is found")
    if S.spot then
        S.moved = true
        H.moveTo(S.spot.x, S.spot.y, S.spot.z)
    end
end)
Q.step(30, function()
    if not S.spot then return end
    RT.pairOpen()
    local grid = false
    pcall(function() grid = p:getCurrentSquare():hasGridPower() end)
    Q.check(grid, "the TV's room has grid power (the grid turned on for the test)")
    pcall(function() Mouse.setXY(20, 20) end)
    pcall(function()
        local sq = S.spot.ring[1]
        local obj = IsoTelevision.new(getCell(), sq, getSprite("appliances_television_01_5"))
        sq:AddTileObject(obj)
        S.placed[#S.placed + 1] = obj
        local d = obj:getDeviceData()
        if d then d:setIsTurnedOn(false); d:setDeviceVolume(0.5) end
        S.tv = obj
    end)
    Q.check(S.tv ~= nil, "a TV is placed beside the character")
end)
Q.waitFor(5, 400, function()
    if not S.tv then return true end
    local w = H.WW()
    for _, r in ipairs((w and w._radios) or {}) do if r.radioInstance == S.tv then return true end end
    return false
end, function(ok)
    if not S.tv then return end
    Q.check(ok, "the World window's Radio list has the TV")
    Q.check(RT.worldTab("radio"), "the World window's Radio tab opens from the strip")
end)
Q.step(5, function()
    local w = H.WW()
    for i, r in ipairs((w and w._radios) or {}) do if S.tv and r.radioInstance == S.tv then RTab.selectRadio(w, i) end end
end)
Q.waitFor(5, 300, function()
    if not S.tv then return true end
    local t = H.tw(H.WW())
    return t ~= nil and t.dev == S.tv and H.settled(H.WW())
end, function(ok)
    if not S.tv then return end
    local t = H.tw(H.WW())
    Q.check(ok and t ~= nil and R.basePid(t.pid) == "tv_black", "the TV: its own face draws in the tab", "face " .. tostring(t and t.pid))
    RT.bounds(Q, "the TV's face in the World window")
    local st = R.read(S.tv)
    Q.check(st ~= nil and st.grid == true and not H.on(S.tv), "the TV: on the grid and off to start with")
    Q.check(H.click(H.WW(), "power"), "the TV's face has its power key")
end)
Q.step(10, function()
    if not S.tv then return end
    Q.check(H.on(S.tv), "the TV: a click on power turns it on")
    O.setChannel(p, S.tv, R.stops()[1].freq)
end)
Q.step(8, function()
    if not S.tv then return end
    S.stop = H.stopI(S.tv)
    Q.check(H.click(H.WW(), "chup"), "the TV's face has CH up")
end)
Q.step(8, function()
    if not S.tv then return end
    Q.check(H.stopI(S.tv) == S.stop + 1, "the TV: CH up tunes the next channel", S.stop .. " -> " .. H.stopI(S.tv))
    H.click(H.WW(), "power")
end)
Q.step(10, function()
    if not S.tv then return end
    Q.check(not H.on(S.tv), "the TV: power again turns it off")
    H.removeTv()
    H.gridBack()
    if S.moved then H.moveTo(S.home.x, S.home.y, S.home.z); S.t0 = getTimestampMs() end
end)
Q.waitFor(5, 3000, function()
    return not S.moved or (H.sq(math.floor(S.home.x), math.floor(S.home.y), math.floor(S.home.z)) ~= nil and getTimestampMs() - S.t0 > 3000)
end, function()
    S.moved = false
    Q.say(string.format("back at %d,%d", math.floor(p:getX()), math.floor(p:getY())))
end)

-- ===================================================================== 3. the Maps tab
function H.mp() local w = H.WW(); return w and w._worldMapPanel end
function H.toolZone(id, grid)
    local w = H.WW()
    for _, z in ipairs((w and w._mapToolZones) or {}) do if z.id == id and (z.isGrid == true) == (grid == true) then return z end end
    return nil
end
-- a tool's button on the header (or under the fold arrow where the header is narrow), pressed through the tab's handler
function H.clickTool(id)
    local w = H.WW()
    local z = H.toolZone(id)
    if not z then
        local d = w and w._mapDisclosureZone
        if d then MT.onClick(w, d.x + 2, d.y + 2); S.foldOpen = true end
        z = H.toolZone(id, true)
    end
    if not z then return false end
    MT.onClick(w, z.x + 2, z.y + 2)
    if S.foldOpen then
        local d = w._mapDisclosureZone
        if d then MT.onClick(w, d.x + 2, d.y + 2) end
        S.foldOpen = false
    end
    return w._mapActiveTool == id
end
-- the strongest fill alpha of the map's own place labels, how many label layers, and the note hand's alpha
function H.labelAlpha()
    local style = H.mp().mapAPI:getStyleAPI()
    local mx, seen = 0, 0
    for _, name in ipairs(MT.LABEL_LAYERS) do
        local layer = style:getLayerByName(name)
        if layer then
            seen = seen + 1
            for i = 0, layer:getFillStops() - 1 do mx = math.max(mx, layer:getFillAlpha(i)) end
        end
    end
    local note = style:getLayerByName("text-note")
    local noteMx = 0
    if note then for i = 0, note:getFillStops() - 1 do noteMx = math.max(noteMx, note:getFillAlpha(i)) end end
    return mx, seen, noteMx
end

Q.step(10, function()
    RT.pairOpen()
    S.md = p:getModData()
    S.mdStyle, S.mdPaper = S.md.ZeD_MapStyle, S.md.ZeD_MapPaper
    local w = H.WW()
    if w and w._mapPopout then pcall(MT.closePopout, w) end
    RT.give("Base.Pencil")
    RT.give("Base.Eraser")
    Q.check(RT.worldTab("maps"), "the World window's Maps tab opens from the strip")
end)
Q.waitFor(10, 300, function()
    local m = H.mp()
    return m ~= nil and m:isReallyVisible() and H.settled(H.WW())
end, function(ok)
    Q.check(ok, "the Maps tab draws its map")
    S.style0 = H.mp() and H.mp().style
    RT.bounds(Q, "the Maps tab")
end)
local STYLES = { { id = "survey", labels = true }, { id = "color", labels = true }, { id = "paper", labels = false } }
for _, st in ipairs(STYLES) do
    Q.step(3, function()
        S.styleSkip = nil
        if not H.mp() then S.styleSkip = "no map"; return end
        if st.id == "paper" and not MT.hasPaper() then
            S.styleSkip = "this install has no paper map"
            Q.skip("Paper style", S.styleSkip)
            return
        end
        MT.setStyle(H.WW(), st.id)
    end)
    Q.waitFor(5, 200, function()
        local m = H.mp()
        return S.styleSkip ~= nil or (m ~= nil and m.style == st.id and not m._styleWanted)
    end, function(ok)
        if S.styleSkip then return end
        local m = H.mp()
        Q.check(ok, st.id .. ": the map restyles and draws", "style " .. tostring(m and m.style))
        local mx, seen, noteMx = H.labelAlpha()
        if st.labels then
            Q.check(seen > 0 and mx > 0, st.id .. ": the map's own place labels show", seen .. " label layers, strongest alpha " .. mx)
        else
            Q.check(seen > 0 and mx <= 0, st.id .. ": the map's own place labels are hidden (the paper prints its own)", seen .. " label layers, strongest alpha " .. mx)
        end
        Q.check(noteMx > 0, st.id .. ": the note hand keeps its ink", "alpha " .. noteMx)
    end)
end
Q.step(5, function()
    if S.style0 and H.mp() and H.mp().style ~= S.style0 then MT.setStyle(H.WW(), S.style0) end
end)
-- a note through ZeD: the note tool armed from the header, placed at the cursor (the pad's A on the canvas)
Q.waitFor(5, 200, function() local m = H.mp(); return m == nil or not m._styleWanted end, function()
    local m = H.mp()
    if not m then Q.check(false, "the map is up for a note"); return end
    S.TEXT = "ZEDQA rt note " .. tostring(ZombRand(100000))
    -- (60 tiles off the character: the save's own marks lie nearer)
    m.mapAPI:centerOn(p:getX() - 60, p:getY() - 60)
    m:_zoomTo(18)
    S.c0 = N.count()
    Q.check(H.clickTool("text"), "the note tool arms from the Maps header")
    local w = H.WW()
    if w._mapTextEntry then w._mapTextEntry:setText(S.TEXT) end
    m:seedGpCursor()
    m._gpCursorX = math.floor(m:getWidth() / 2)
    m._gpCursorY = math.floor(m:getHeight() / 2)
end)
Q.step(10, function()
    MT.gpPlaceAtCursor(H.WW())
    S.note = N.findByText(S.TEXT)
    Q.check(S.note ~= nil and N.count() == (S.c0 or -1) + 1, "a note placed at the cursor lands once in the game's own map marks",
        "marks " .. tostring(S.c0) .. " -> " .. tostring(N.count()))
    H.WW()._mapActiveTool = nil
end)
Q.step(10, function()
    if not S.note then return end
    local hit = MT.gpFindAnnotAtCursor(H.WW())
    Q.check(hit ~= nil and N.textOf(hit.sym) == S.TEXT, "the cursor finds the note")
    MT.gpContextMenuAtCursor(H.WW())
    S.ctx = getPlayerContextMenu(pn)
    S.del = S.ctx and S.ctx:getOptionFromName(getText("ContextMenu_Delete"))
    Q.check(S.del ~= nil, "ZeD's menu on the note offers Delete")
end)
Q.step(5, function()
    if not S.note then return end
    RT.bounds(Q, "the menu on a map note")
    if S.del and S.del.onSelect then S.del.onSelect(S.del.target) end
    pcall(function() S.ctx:hideAndChildren() end)
end)
Q.step(5, function()
    if not S.note then return end
    Q.check(N.findByText(S.TEXT) == nil and N.count() == S.c0, "Delete takes the note off the map", "marks now " .. N.count())
    S.note = nil
end)

-- ===================================================================== 4. the Journal tab: the lists, the quick note
local NOTE = "fossoil out back. two cans. check again tomorrow"
local PAGE2 = "water: 2 bottles and the pot.\nfood: beans, crackers"
function H.zone(id)
    local w = H.CW()
    for _, z in ipairs((w and w._jrZones) or {}) do if z.id == id then return z end end
    return nil
end
-- a button or row pressed through the tab's own click handler; a zone outside the page's view (a short drawer, the
-- page scrolled) is pressed through its zone and said so
function H.press(id)
    local z = H.zone(id)
    if not (z and z.fn) then return false end
    if J.onClick(H.CW(), z.x + 2, z.y + 2) == true then return true end
    Q.say("(" .. id .. " sat outside the page's view: pressed through its zone)")
    z.fn()
    return true
end
function H.hasLine(item, line, page)
    local t = nil
    pcall(function() t = item:seePage(page or 1) end)
    return t ~= nil and string.find(t, line, 1, true) ~= nil
end
Q.step(10, function()
    S.flier = RT.give("Base.Flier")
    pcall(function()
        S.flier:getModData().printMedia = { id = "ustoreitmuldraugh", title = "Print_Media_UStoreItMuldraugh_title",
            info = "Print_Media_UStoreItMuldraugh_info", text = "Print_Text_UStoreItMuldraugh_info" }
        S.flier:setName(getText("Print_Media_UStoreItMuldraugh_title"))
    end)
    S.book = RT.give("Base.Notebook")
    pcall(function() S.book:setName("ZeD QA notes"); S.book:setCustomName(true) end)
    -- (the QA save is often at night: the game will not write in the dark, so noon for the test, put back after)
    pcall(function() S.gt:setTimeOfDay(12) end)
    Q.check(S.flier ~= nil and S.book ~= nil, "a flyer and a notebook are given")
    Q.check(RT.charTab("journal"), "the Character window's Journal tab opens from the strip")
end)
Q.step(10, function() ZeD.JournalTab.setPage(H.CW(), 3) end)
Q.waitFor(5, 200, function()
    local w = H.CW()
    local c = w and w._jr and w._jr.carried
    for _, e in ipairs((c and c.papers) or {}) do if e.item == S.flier then return true end end
    return false
end, function(ok)
    Q.check(ok, "Papers lists the flyer carried")
    Q.check(H.zone("paper:ustoreitmuldraugh") ~= nil, "the flyer has its row on the page")
    RT.bounds(Q, "the Journal's Papers page")
end)
Q.step(5, function() ZeD.JournalTab.setPage(H.CW(), 2) end)
Q.waitFor(5, 200, function()
    local w = H.CW()
    local c = w and w._jr and w._jr.carried
    for _, b in ipairs((c and c.books) or {}) do if b == S.book then return H.zone("book:" .. S.book:getID()) ~= nil end end
    return false
end, function(ok)
    Q.check(ok, "Notebooks lists the notebook carried, with its row")
    if S.book then H.press("book:" .. S.book:getID()) end
end)
Q.step(5, function()
    local w = H.CW()
    Q.check(S.book ~= nil and w._jr and w._jr.nbId == S.book:getID(), "a click on the notebook's row picks it")
    RT.bounds(Q, "the Journal's Notebooks page")
end)
Q.waitFor(2, 900, function() return not p:tooDarkToRead() end, function(ok)
    Q.check(ok, "light to write by (noon set for the test)")
    H.clearQueue()
    local w = H.CW()
    if w._jrNote then w._jrNote:setText(NOTE) end
    Q.check(H.press("write"), "the quick note's Write button is live")
end)
Q.waitFor(10, 1200, function() return S.book ~= nil and H.hasLine(S.book, NOTE, 1) end, function(ok)
    Q.check(ok, "the line written from the quick note is kept on the notebook's page (ZeD_WriteNoteAction)")
end)

-- ===================================================================== 5. the reader on the notebook
Q.step(10, function()
    Q.check(H.press("full"), "the notebook's Open full button is live")
end)
Q.waitFor(5, 400, function()
    local r = ZeD.Reader.get(pn)
    return r ~= nil and r:isReallyVisible() and r.mode == "notebook"
end, function(ok)
    local r = ZeD.Reader.get(pn)
    Q.check(ok and r.item == S.book, "Open full opens the notebook in ZeD's reader")
    if not ok then return end
    Q.check(not r.readOnly, "the reader opens it to write (a pencil carried)")
    Q.check(string.find(r.nbEntry:getText() or "", NOTE, 1, true) ~= nil, "the reader shows the written line on its first page")
    RT.bounds(Q, "the reader")
    r:goPage(2)
end)
Q.step(5, function()
    local r = ZeD.Reader.get(pn)
    if not (r and r.mode == "notebook") then return end
    r.nbEntry:setText(PAGE2)
end)
Q.step(5, function()
    local r = ZeD.Reader.get(pn)
    if not (r and r.mode == "notebook") then return end
    r:done()
end)
Q.step(10, function()
    local r = ZeD.Reader.get(pn)
    local t2 = nil
    pcall(function() t2 = S.book:seePage(2) end)
    Q.check(t2 == PAGE2, "Done keeps the second page's text as written")
    Q.check(H.hasLine(S.book, NOTE, 1), "Done keeps the first page's line")
    Q.check(not (r and r:isReallyVisible()), "Done closes the reader")
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    H.clearQueue()
    pcall(function() local r = ZeD.Reader.get(pn); if r and r:isReallyVisible() then r:close() end end)
    pcall(function() ZeD.TwoWayFull.close(pn) end)
    -- the map: a note left, the style, the character's own records of it, the note box's words
    pcall(function() if S.note then N.remove(S.note) end end)
    pcall(function()
        local w = H.WW()
        if S.style0 and H.mp() and H.mp().style ~= S.style0 then MT.setStyle(w, S.style0) end
        w._mapActiveTool = nil
        w._mapEdit = nil
        if w._mapTextEntry then w._mapTextEntry:setText(ZeD.tr("UI_ZeD_Map_NoteDefault")) end
    end)
    if S.md then S.md.ZeD_MapStyle, S.md.ZeD_MapPaper = S.mdStyle, S.mdPaper end
    pcall(function() local w = H.CW(); if w and w._jrNote then w._jrNote:clear() end end)
    pcall(function() ZeD.JournalTab.setPage(H.CW(), 1) end)
    H.removeTv()
    H.gridBack()
    if S.moved and S.home then H.moveTo(S.home.x, S.home.y, S.home.z); S.t0 = getTimestampMs() end
    pcall(function() p:setPrimaryHandItem(S.prim); p:setSecondaryHandItem(S.sec) end)
    if S.tod0 then pcall(function() S.gt:setTimeOfDay(S.tod0) end) end
    pcall(function() RT.charTab("loot") end)
    pcall(function() RT.worldTab("loot") end)
end)
Q.waitFor(10, 3000, function()
    return not S.moved or (H.sq(math.floor(S.home.x), math.floor(S.home.y), math.floor(S.home.z)) ~= nil and getTimestampMs() - S.t0 > 3000)
end, function()
    if S.winsWere == false then RT.pairShut() elseif S.winsWere then RT.pairOpen() end
    local hx, hy = math.floor(S.home and S.home.x or 0), math.floor(S.home and S.home.y or 0)
    Q.check(math.floor(p:getX()) == hx and math.floor(p:getY()) == hy, "put back: the character is where it started", math.floor(p:getX()) .. "," .. math.floor(p:getY()))
    Q.check(p:getPrimaryHandItem() == S.prim and p:getSecondaryHandItem() == S.sec, "put back: the hands hold what they held")
end)
Q.start()
