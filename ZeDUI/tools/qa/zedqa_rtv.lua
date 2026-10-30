-- ZeDUI/tools/qa/zedqa_rtv.lua  (Oct 30 2026)
-- The ordinary radios', the CD player's and the TVs' faces in the radio tab (handoff
-- ZeDUI/HANDOFF_radio_tv_laundry_20261030.md, approved Oct 30 2026; RtvFace.lua). With batteries in:
--   1. each portable in the Character window's hand (the ValuTech and Premium radios, the hand-built
--      radio, the CD player): its own face by the item, at the width that fills the half card (the
--      hand-built radio has no 154 face: the full card at 0.75 and 1.5), centred with its margins, no
--      footer; POWER lights the display; VOL + / -, TUNE both halves, a preset held stores and pressed
--      recalls; the battery key queues vanilla's battery action; the CD slot opens the list of discs
--      carried (red radio, CD player); the headphone jack queues vanilla's action
--   2. the controller: the face's controls are stops, POWER the first (where focus lands); up on the
--      tuning knob turns it
--   3. faces off (ZeD.RadioTab.useFaces, punch list item 17 to come): the simple card (the chassis)
--   4. three TVs and a radio placed beside the character in the World window, picked by their tiles (the
--      second turn of each, so the four-turns rule is used): the full card for the TVs, the antique's
--      volume knob one control (volpwr) and its channel dial; with the grid on: power, CH up to the first
--      channel, the screen's states (snow after a change, the bars on 12 and 13, a station on air, between
--      broadcasts or gone, a frequency off the dial: snow), the signal light; every off-air texture present
-- Everything made is taken away; the hands and the grid put back; both windows back on Loot.
-- Screenshots/zqa_rtv_*.png; grep "ZEDQA rtv".
local p = getPlayer()
local pn = p:getPlayerNum()
local R, RT, O = ZeD.Rtv, ZeD.RadioTab, ZeD.RadioOps
local function say(s) print("ZEDQA rtv " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what)
    if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rtv_" .. n .. ".png") end) end
local function CW() return ZeD_CharacterWindow.getWindow() end
local function WW() return ZeD_WorldWindow.getWindow() end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
if not (R and RT and O) then say("ERR the radio face modules are not loaded"); say("DONE"); return end

local function root() return (ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or 1 end
local K = ZeD.Px.k(root())
local function goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab or (tab ~= "loot" and not win._drawerOpen) then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function charTab(id) local w = CW(); return (w and goTab(w, w._tabStripPanel, id)) and true or false end
local function worldTab(id) local w = WW(); return (w and goTab(w, w._actionTabStrip, id)) and true or false end
local settle = {}
local function settled(w)
    local e = math.floor(w and w._drawerEffW or -1)
    local s = settle[w] or { v = -2, n = 0 }
    settle[w] = s
    if e == s.v then s.n = s.n + 1 else s.v, s.n = e, 0 end
    return s.n >= 3 and e > 0
end

local prim, sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
local winsWere = ZeD_CharacterWindow.isOpen()
local added, placed = {}, {}
local so = getSandboxOptions()
local elec = so and so:getOptionByName("ElecShutModifier")
local elecWas = elec and elec:getValue()
local hydroWas = getWorld():isHydroPowerOn()

local function newItem(ft)
    local it = p:getInventory():AddItem(ft)
    if it then added[#added + 1] = it end
    return it
end
local function newRadio(ft, charge)
    local it = newItem(ft)
    if not it then say("ERR could not make " .. ft); return nil end
    local dd = it:getDeviceData()
    if dd then
        if dd:getIsBatteryPowered() then dd:setHasBattery(true); dd:setPower(charge or 0.6) end
        dd:setIsTurnedOn(false)
        dd:setDeviceVolume(0.5)
        dd:setChannel(98000)
        local pc = dd:getDevicePresets()
        if pc then pc:getPresets():clear() end
    end
    return it
end
local function hold(it)
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
    if it then p:setPrimaryHandItem(it) end
end
local function tw(w) return w and w._radioTw end
local function hitOf(t, id) for _, h in ipairs((t and t.hits) or {}) do if h.id == id then return h end end; return nil end
local function click(w, id, side)
    local h = hitOf(tw(w), id)
    if not h then say("ERR no control " .. id .. " on the face"); return false end
    local x = (side == "l" and h.x + 2) or (side == "r" and h.x + h.w - 3) or (h.x + math.floor(h.w / 2))
    RT.onClick(w, x, h.y + math.floor(h.h / 2))
    return true
end
local function dd(dev) return dev:getDeviceData() end
local function st(dev) return R.read(dev) end
local function queued(kind)
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    for _, a in ipairs((q and q.queue) or {}) do if a.Type == kind then return true end end
    return false
end
local function clearQueue() pcall(function() ISTimedActionQueue.clear(p) end) end
-- the list a key opened (captured as it opens; ZeD draws a context menu as its own list), closed after the check
local lastCtx = nil
local ctxGet = ISContextMenu.get
ISContextMenu.get = function(...) local c = ctxGet(...); lastCtx = c; return c end
local function menuOpen()
    local c = lastCtx
    if not c then return false end
    local m = c._zedMenu
    if m and m._ctx then return m._ctx.open == true end
    return c:isReallyVisible() and c:getX() > -1000
end
local function menuClose()
    local c = lastCtx
    lastCtx = nil
    if not c then return end
    pcall(function() if c._zedMenu and c._zedMenu.close then c._zedMenu:close() end end)
    pcall(function() c:setVisible(false) end)
end

-- the checks on a face in the tab
local function faceChecks(w, pid, tag)
    local t = tw(w)
    check(t ~= nil and t.drv == R and R.basePid(t.pid) == pid, tag .. ": its own face, " .. pid .. " (got " .. tostring(t and t.pid) .. ")")
    if not t then return end
    local des = t.des
    local dw = math.floor(w._drawerEffW or 0)
    if R.isTv(pid) then
        check(math.abs(dw - ZeD.T.px(480)) <= 1, tag .. ": the full card (" .. dw .. " px)")
    else
        local hid = R.halfFace(pid, K)
        local want = hid and ZeD.T.px(220) or ZeD.T.px(480)
        check(math.abs(dw - want) <= 1, tag .. ": the half card where a width fits, else the full (" .. dw .. " px, want " .. want .. ")")
        if hid then check(t.pid == hid, tag .. ": the width that fills the half card (" .. tostring(hid) .. ", got " .. t.pid .. ")") end
        local x0 = math.floor((t.view.w - des.w * t.k) / 2)
        check(math.abs(t.face.x - x0) <= 1, tag .. ": centred, its margins its own (x " .. t.face.x .. ", want " .. x0 .. ")")
    end
    check(w._radioFullZone == nil, tag .. ": no full view button (a two-way set's)")
    local want = #des.hits - (R.factsOf(des).volPower and 1 or 0)
    check(#t.hits == want, tag .. ": every control on the face (" .. #t.hits .. " of " .. want .. ")")
end

-- ===================================================================== setup
step(10, function()
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    hold(nil)
    RT.useFaces = true
    pcall(function() Mouse.setXY(20, 20) end)
    say(string.format("screen %dx%d, root scale %.2f, plate zoom %d", getCore():getScreenWidth(), getCore():getScreenHeight(), root(), K))
    p:getInventory():AddItem("Base.Battery"); added[#added + 1] = p:getInventory():getFirstType("Base.Battery")
    p:getInventory():AddItem("Base.Disc_Retail"); added[#added + 1] = p:getInventory():getFirstType("Base.Disc_Retail")
    p:getInventory():AddItem("Base.Headphones"); added[#added + 1] = p:getInventory():getFirstType("Base.Headphones")
end)

-- ===================================================================== 1. the portables
local PORTABLE = {
    { ft = "Base.RadioBlack", pid = "radio_black" }, { ft = "Base.RadioRed", pid = "radio_red", cd = true },
    { ft = "Base.RadioMakeShift", pid = "radio_handbuilt" }, { ft = "Base.CDplayer", pid = "cd_player", cd = true, noTuner = true },
}
local cur = {}
local chWas, volWas
local function portable(m)
    step(5, function()
        local it = newRadio(m.ft, 0.6)
        cur = { it = it, pid = m.pid }
        hold(it)
    end)
    waitFor(5, 150, function() local r = CW()._radios and CW()._radios[1]; return r ~= nil and r.radioInstance == cur.it end,
        function() check(charTab("radio"), m.pid .. ": the Character window's Radio tab opens") end)
    waitFor(5, 150, function() local t = tw(CW()); return t ~= nil and t.dev == cur.it and settled(CW()) end, function()
        faceChecks(CW(), m.pid, m.pid)
        click(CW(), "power")
    end)
    step(10, function()
        check(dd(cur.it):getIsTurnedOn(), m.pid .. ": POWER turns it on")
        local ps = R.plateState(st(cur.it), cur.pid, tw(CW()).des)
        check(ps.display ~= nil and ps.radioOn, m.pid .. ": the display reads and the lamp lights while on")
        local d = ps.display or {}
        say(m.pid .. ": display " .. tostring(d.big or d.l1 or d.time) .. " | " .. tostring(d.line or d.l2) .. " | batt " .. tostring(ps.batt))
        shot("1_" .. m.pid)
        volWas = dd(cur.it):getDeviceVolume()
        if hitOf(tw(CW()), "volup") then click(CW(), "volup") else R.turn(p, cur.it, "vol", 1) end
    end)
    step(5, function()
        check(dd(cur.it):getDeviceVolume() > volWas + 0.05, string.format("%s: the volume goes up (%.2f -> %.2f)", m.pid, volWas, dd(cur.it):getDeviceVolume()))
        if m.noTuner then return end
        chWas = dd(cur.it):getChannel()
        click(CW(), "tune", "r")
    end)
    if not m.noTuner then
        step(5, function()
            check(dd(cur.it):getChannel() == chWas + O.STEP, m.pid .. ": TUNE's right half tunes up a step")
            R.secondary(p, cur.it, "p1")                     -- 1 held: stored
            chWas = dd(cur.it):getChannel()
            for _ = 1, 3 do R.turn(p, cur.it, "tune", 1) end
        end)
        step(5, function()
            check(dd(cur.it):getChannel() ~= chWas, m.pid .. ": tuned away")
            click(CW(), "p1")                                 -- acts on the release (the next frame)
        end)
        step(5, function() check(dd(cur.it):getChannel() == chWas, m.pid .. ": P1 pressed goes back to the stored station") end)
    end
    step(2, function() clearQueue(); click(CW(), "battery") end)
    step(5, function()
        check(queued("ISDeviceBatteryAction"), m.pid .. ": the battery key queues vanilla's battery action")
        clearQueue()
        if m.cd then click(CW(), "slot") end
    end)
    if m.cd then
        step(5, function()
            check(menuOpen(), m.pid .. ": the slot opens the list of discs carried")
            shot("1b_" .. m.pid .. "_list")
            menuClose()
        end)
    end
    step(2, function() if hitOf(tw(CW()), "phones") then clearQueue(); click(CW(), "phones") end end)
    step(5, function()
        if hitOf(tw(CW()), "phones") then check(queued("ISRadioAction"), m.pid .. ": the headphone jack queues vanilla's action") end
        clearQueue()
    end)
end
for _, m in ipairs(PORTABLE) do portable(m) end

-- ===================================================================== 2. the controller (the CD player in hand)
step(5, function()
    local els = RT.buildFocusables(CW())
    check(els[1] ~= nil and els[1].id == "radio:tw:power", "controller: POWER is the first stop on the face (got " .. tostring(els[1] and els[1].id) .. ")")
    local n = 0
    for _, e in ipairs(els) do if e.id:sub(1, 9) == "radio:tw:" then n = n + 1 end end
    check(n == #tw(CW()).hits, "controller: every control is a stop (" .. n .. ")")
end)

-- ===================================================================== 3. faces off: the simple card
step(5, function() RT.useFaces = false end)
step(10, function()
    check(tw(CW()) == nil and CW()._radioPwrZone ~= nil, "faces off: the simple card (the chassis) through drawSimple")
    shot("3_simple_card")
    RT.useFaces = true
end)
step(10, function()
    check(tw(CW()) ~= nil, "faces on again: the face is back")
    hold(nil)
end)

-- ===================================================================== 4. the TVs and a radio placed in the world
local SETS = {
    { ft = "Base.TvWideScreen", pid = "tv_widescreen", spr = "appliances_television_01_1", tv = true },
    { ft = "Base.TvBlack", pid = "tv_black", spr = "appliances_television_01_5", tv = true },
    { ft = "Base.TvAntique", pid = "tv_antique", spr = "appliances_television_01_9", tv = true },
    { ft = "Base.RadioRed", pid = "radio_red", spr = "appliances_radio_01_9" },
}
local objs = {}
step(5, function()
    local x0, y0, z0 = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local here = p:getCurrentSquare()
    local spots = {}
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x0 + d[1], y0 + d[2], z0)
        if sq and sq:isFree(false) and here and here:canReachTo(sq) then spots[#spots + 1] = sq end
    end
    say(#spots .. " free squares in reach")
    for i, s in ipairs(SETS) do
        local sq = spots[i]
        local it = instanceItem(s.ft)
        if sq and it then
            local d = it:getDeviceData()
            if d:getIsBatteryPowered() then d:setHasBattery(true); d:setPower(0.8) end
            d:setIsTurnedOn(false)
            local obj
            if s.tv then obj = IsoTelevision.new(getCell(), sq, getSprite(s.spr)) else obj = IsoRadio.new(getCell(), sq, getSprite(s.spr)) end
            obj:setDeviceData(d)
            sq:AddTileObject(obj)
            placed[#placed + 1] = obj
            objs[s.pid] = obj
        end
    end
    say("placed " .. #placed .. " sets")
    if elec then elec:setValue(99999); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(true)
    if not WW():isVisible() then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
waitFor(5, 150, function()
    local n = 0
    for _, r in ipairs(WW()._radios or {}) do for _, o in pairs(objs) do if r.radioInstance == o then n = n + 1 end end end
    return n == #placed
end, function() check(worldTab("radio"), "the World window's Radio tab opens on the placed sets") end)
local function show(pid)
    step(5, function()
        for i, r in ipairs(WW()._radios or {}) do if r.radioInstance == objs[pid] then WW()._radioIdx = i end end
    end)
    waitFor(5, 150, function() local t = tw(WW()); return t ~= nil and t.dev == objs[pid] and settled(WW()) end, function()
        faceChecks(WW(), pid, pid .. " (placed, by its tile)")
    end)
end
show("radio_red")
step(5, function() shot("4a_radio_red_placed") end)

local function tvRun(pid)
    show(pid)
    step(5, function()
        local o = objs[pid]
        if not o then return end
        local t = tw(WW())
        if pid == "tv_antique" then
            check(hitOf(t, "volpwr") ~= nil and hitOf(t, "power") == nil and hitOf(t, "channel") ~= nil,
                "tv_antique: the volume knob is one control (volpwr), the channel dial another")
        end
        local s = st(o)
        local ps = R.plateState(s, t.pid, t.des)
        if not s.grid then
            say(pid .. ": no grid at this square (not in a room); the power checks are skipped")
            check(ps.noPower == true, pid .. ": NO POWER lit without the grid")
            return
        end
        check(not ps.noPower, pid .. ": NO POWER dark on the grid")
        click(WW(), pid == "tv_antique" and "volpwr" or "power")
    end)
    step(10, function()
        local o = objs[pid]
        if not (o and st(o).grid) then return end
        check(dd(o):getIsTurnedOn(), pid .. ": power turns it on")
        if pid == "tv_antique" then R.turn(p, o, "channel", -1) else click(WW(), "chdn") end
    end)
    step(10, function()
        local o = objs[pid]
        if not (o and st(o).grid) then return end
        local s = st(o)
        R.plateState(s, tw(WW()).pid, tw(WW()).des)
        local stop = R.stopOf(s.channel)
        say(pid .. ": channel " .. tostring(s.channel) .. ", stop " .. tostring(stop and stop.number) .. ", screen " .. tostring(s.air))
        check(stop ~= nil, pid .. ": the channel is on the dial")
        O.setChannel(p, o, R.stops()[11].freq)              -- 12: no station
    end)
    step(math.floor(R.ZAP_MS / 16) + 10, function()
        local o = objs[pid]
        if not (o and st(o).grid) then return end
        local s = st(o)
        local ps = R.plateState(s, tw(WW()).pid, tw(WW()).des)
        check(s.air == "bars", pid .. ": 12 has no station: the bars (" .. tostring(s.air) .. ")")
        check(ps.sigBad and not ps.sigGood, pid .. ": the signal light bad on the bars")
        check(ps.display and ps.display.ch == "12", pid .. ": the channel display reads 12 (" .. tostring(ps.display and ps.display.ch) .. ")")
        shot("4b_" .. pid .. "_bars")
        O.setChannel(p, o, R.TV_FREQ.triple_n)
    end)
    step(2, function()
        local o = objs[pid]
        if not (o and st(o).grid) then return end
        local s = st(o)
        R.plateState(s, tw(WW()).pid, tw(WW()).des)
        check(s.air == "snow", pid .. ": just changed channel: snow (" .. tostring(s.air) .. ")")
    end)
    step(math.floor(R.ZAP_MS / 16) + 10, function()
        local o = objs[pid]
        if not (o and st(o).grid) then return end
        local s = st(o)
        local ps = R.plateState(s, tw(WW()).pid, tw(WW()).des)
        local ok = s.air == "picture" or s.air == "signoff" or s.air == "standby"
        check(ok, pid .. ": Triple-N: on air, between broadcasts or gone (" .. tostring(s.air) .. ")")
        check((s.air ~= "picture") or ps.sigGood, pid .. ": the signal light good on air")
        shot("4c_" .. pid .. "_triple_n_" .. tostring(s.air))
        click(WW(), pid == "tv_antique" and "volpwr" or "power")
    end)
    step(10, function()
        local o = objs[pid]
        if not (o and st(o).grid) then return end
        check(not dd(o):getIsTurnedOn(), pid .. ": power again turns it off")
    end)
end
tvRun("tv_black")
tvRun("tv_widescreen")
tvRun("tv_antique")
step(5, function()
    local X = ZeD.PhysPx
    local miss = 0
    for plate, set in pairs(X.offair.sets) do
        for _, scr in ipairs(X.offair.screens) do
            if not ZeD.Px.tex(X.texdir .. set .. scr .. ".png") then miss = miss + 1; say("missing " .. set .. scr) end
        end
    end
    check(miss == 0, "every off-air screen's texture loads (" .. miss .. " missing)")
    for id, L in pairs(X.offair.logos) do check(getTexture(L.file) ~= nil, "the game's own logo loads: " .. id) end
    local els = RT.buildFocusables(WW())
    check(els[1] ~= nil and (els[1].id == "radio:tw:power" or els[1].id == "radio:tw:volpwr"), "controller: the set's power is the first stop (" .. tostring(els[1] and els[1].id) .. ")")
end)

-- ===================================================================== cleanup
step(10, function()
    clearQueue()
    menuClose()
    ISContextMenu.get = ctxGet
    RT.useFaces = true
    for _, obj in ipairs(placed) do
        local sq = obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end
    end
    if elec and elecWas ~= nil then elec:setValue(elecWas); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(hydroWas)
    p:setPrimaryHandItem(prim); p:setSecondaryHandItem(sec)
    for _, it in ipairs(added) do
        local c = it and it:getContainer()
        if c then c:Remove(it) end
    end
    for _, w in ipairs({ CW(), WW() }) do
        local strip = (w == CW()) and w._tabStripPanel or w._actionTabStrip
        goTab(w, strip, "loot")
    end
    if winsWere ~= ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say("cleanup: " .. #placed .. " sets and " .. #added .. " items taken away")
end)
step(10, function()
    say(string.format("%d passed, %d failed", nPass, nFail))
    say(nFail == 0 and "all checks passed" or (nFail .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    if s.cond then
        s.left = (s.left or s.max) - 1
        local ok, done = pcall(s.cond)
        if not (ok and done) and s.left > 0 then wait = 1; return end
        if not (ok and done) then say("ERR step " .. qi .. ": waited " .. s.max .. " frames") end
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
