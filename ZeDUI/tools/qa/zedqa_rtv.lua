-- ZeDUI/tools/qa/zedqa_rtv.lua  (Oct 30 2026; the TV, house and pad parts added after the QA run at 1c9d882)
-- The ordinary radios', the CD player's and the TVs' faces in the radio tab (handoff
-- ZeDUI/HANDOFF_radio_tv_laundry_20261030.md, approved Oct 30 2026; RtvFace.lua). With batteries in:
--   1. each portable in the Character window's hand (the ValuTech and Premium radios, the hand-built
--      radio, the CD player): its own face by the item, at the width that fills the half card (the
--      hand-built radio has no 154 face: the full card at 0.75 and 1.5), centred with its margins, no
--      footer; POWER lights the display; VOL + / -, TUNE both halves, a preset held stores and pressed
--      recalls; the battery key queues vanilla's battery action; the CD slot opens the list of discs
--      carried (red radio, CD player); the headphone jack queues vanilla's action
--   2. the controller: the face's controls are stops, POWER the first; up on the tuning knob turns it. The
--      pad enters the tab and lands on power; A on the battery key (no battery in, none carried), the
--      headphone jack (none carried) and the CD slot (a disc carried) each opens its list, and when the
--      list closes the pad is back on that key in that window
--   3. faces off (ZeD.RadioTab.useFaces, punch list item 17 to come): the simple card (the chassis)
--   4. the grid: the QA world is past the shut-off, so the run turns the game's grid flag on and stands the
--      character on a free square with free ROOM squares round it (grid power is only given inside a room; the
--      Fossoil at West Point when no room is in reach). Three TVs and a radio are placed ON those squares
--      (the data of a set is touched only once it is on a square: set before, it asked a squareless item about
--      power, three Java errors in the first run), picked by their tiles. For each TV: the full card; power
--      (NO POWER dark, the lamp, the channel display); CH up / down wrapping round the twelve and the volume
--      keys (black, wide screen); the antique's 12-stop dial (stops at both ends, a click on either half) and its
--      push / pull knob (turned: volume, the set stays on; pushed or pulled: power); every stop in turn: snow
--      after a change, the bars on 12 and 13, then picture / sign-off / standby as the game's broadcast clock has
--      them (the Triple-N and TURBO cards photographed; which of the three appear is reported, not demanded), a
--      frequency off the dial: snow; the grid going away: NO POWER lit, the screen dark, the key does nothing;
--      the controller on a TV: lands on power, the tape and headphone lists (black), the antique's knob and
--      dial by the D-pad
--   5. a house radio and a house TV as found in the world: a radio tile that answers nothing alone given a dropped
--      item (modData.RadioItemID, the item on its square), a radio and a TV tile that name an item (CustomItem):
--      RtvFace.plateId gives the right face and the Radio tab draws it; every off-air texture present
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
local Focus, Det = ZeD.Input and ZeD.Input.Focus, ZeD.Input and ZeD.Input.Detector
step(5, function()
    local els = RT.buildFocusables(CW())
    check(els[1] ~= nil and els[1].id == "radio:tw:power", "controller: POWER is the first stop on the face (got " .. tostring(els[1] and els[1].id) .. ")")
    local n = 0
    for _, e in ipairs(els) do if e.id:sub(1, 9) == "radio:tw:" then n = n + 1 end end
    check(n == #tw(CW()).hits, "controller: every control is a stop (" .. n .. ")")
end)

-- what the lists would offer is taken out of the bag for a moment, so the list says there is none
local stash = {}
local function stashCarried(types)
    local inv = p:getInventory()
    for _, ft in ipairs(types) do
        local l = inv:getAllTypeRecurse(ft)
        local items = {}
        for i = 0, (l and l:size() or 0) - 1 do items[#items + 1] = l:get(i) end
        for _, it in ipairs(items) do
            local c = it:getContainer()
            if c then c:Remove(it); stash[#stash + 1] = it end
        end
    end
end
local function unstash()
    for _, it in ipairs(stash) do p:getInventory():AddItem(it) end
    stash = {}
end
-- (Oct 30 2026, punch list 21 h/i: these take the window's getter, CW or WW, and ask it when the step runs. They
-- took the window itself, read when the script loaded: in the full pass the windows are shut then (zedqa_sandbox_ig
-- shuts them; this script opens them in its own steps), so win was nil, the first step threw "_focusEntryZone of
-- non-table", the pad never entered the tab, and every pad check after it failed. Short manifests passed because the
-- script before left the windows open.)
-- the pad enters the tab: focus lands on power (the director's rule: land on the primary control)
local function landOnPower(getWin, zoneName, tag)
    step(5, function()
        local win = getWin()
        if not win then check(false, tag .. ": the window is open for the pad"); return end
        local wasZone, wasPend = win._focusEntryZone, win._focusPendingEntry
        Focus.claimFocus(win)
        win._focusEntryZone, win._focusPendingEntry = zoneName, true
        for _, z in ipairs(win._focusRing or {}) do if z.zone == zoneName then z.focusedElementIdx = nil end end
        pcall(Focus.ensureEntry, win)
        win._focusEntryZone, win._focusPendingEntry = wasZone, wasPend
        local e = Focus.getFocusedElement(win)
        check(e ~= nil and (e.id == "radio:tw:power" or e.id == "radio:tw:volpwr"),
            tag .. ": the pad lands on power when it enters the tab (" .. tostring(e and e.id) .. ")")
    end)
end
-- A on a key that opens a list: the list is up, and when it closes the pad is back on that key in that window
local function padKey(getWin, zoneName, id, tag, shotName)
    step(5, function()
        local win = getWin()
        local e = Focus.focusWhere(win, zoneName, function(x) return x.id == "radio:tw:" .. id end)
        lastCtx = nil
        if not e then check(false, tag .. ": " .. id .. " is a controller stop"); return end
        if e.onActivate then e.onActivate(win, e) end
    end)
    step(8, function()
        check(menuOpen(), tag .. ": the pad's A on " .. id .. " opens its list")
        shot(shotName)
        menuClose()
    end)
    step(6, function()
        local win = getWin()
        local f = win and Focus.getFocusedElement(win)
        check(Focus.getFocusedWindow() == win and f ~= nil and f.id == "radio:tw:" .. id,
            tag .. ": the list closed: the pad is back on " .. id .. " (" .. tostring(f and f.id) .. ")")
    end)
end
local function padEnd()
    step(5, function()
        unstash()
        Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
        Focus.releaseFocus()
    end)
end

-- the CD player: no battery in and none carried, no headphones carried, a disc carried
step(5, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    stashCarried({ "Base.Battery", "Base.Headphones", "Base.Earbuds" })
    pcall(function() dd(cur.it):setHasBattery(false) end)
end)
landOnPower(CW, "charTabContent", "cd_player")
padKey(CW, "charTabContent", "battery", "cd_player", "2_pad_cd_player_battery_list")
padKey(CW, "charTabContent", "phones", "cd_player", "2_pad_cd_player_phones_list")
padKey(CW, "charTabContent", "slot", "cd_player", "2_pad_cd_player_disc_list")
step(5, function() pcall(function() dd(cur.it):setHasBattery(true) end) end)
padEnd()

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

-- ===================================================================== 4. indoors, on the grid
-- The QA world is past the shut-off, so the grid is the game's own flag for the run (the world's power switch and a
-- raised ElecShutModifier, as zedqa_appliances.lua does): a square gets grid power only inside a room. Outdoors a
-- set has none (the first run, 1c9d882, set the TVs down outdoors and skipped every power check).
local function sqAt(x, y, z) return getCell():getGridSquare(x, y, z) end
local function freeSq(x, y, z)
    local sq = sqAt(x, y, z)
    local ok = false
    if sq then pcall(function() ok = sq:isFree(false) and not sq:getVehicleContainer() end) end
    return ok and sq or nil
end
local RING = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
-- the free room squares round (x, y) the character can reach
local function roomRing(x, y, z)
    local here = freeSq(x, y, z)
    local out = {}
    if not here then return out end
    for _, d in ipairs(RING) do
        local n = freeSq(x + d[1], y + d[2], z)
        local reach = false
        if n then pcall(function() reach = n:getRoom() ~= nil and here:canReachTo(n) end) end
        if reach then out[#out + 1] = n end
    end
    return out
end
local function findSpot(cx, cy, cz, rad)
    for r = 0, rad do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local ring = roomRing(cx + dx, cy + dy, cz)
                    if #ring >= 4 then return { x = cx + dx + 0.5, y = cy + dy + 0.5, z = cz, ring = ring } end
                end
            end
        end
    end
    return nil
end
local STORE = { x0 = 12052, y0 = 7117, x1 = 12069, y1 = 7126 }   -- the Fossoil at West Point
local home = { x = p:getX(), y = p:getY(), z = p:getZ() }
local spot, travelled, t0 = nil, false, 0
local function moveTo(x, y, z)
    p:teleportTo(x, y, z)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end)
end
-- (the world flag and the shut-off day together: with the flag off and the modifier at 0 no square has grid power)
local function setGrid(on)
    if elec then elec:setValue(on and 99999 or 0); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(on and true or false)
end

step(5, function()
    if elec then elec:setValue(99999); pcall(function() so:toLua() end) end
    setGrid(true)
    spot = findSpot(math.floor(home.x), math.floor(home.y), math.floor(home.z), 45)
    if not spot then
        travelled, t0 = true, getTimestampMs()
        say(string.format("no room in reach of %d,%d: to the Fossoil at West Point", math.floor(home.x), math.floor(home.y)))
        moveTo(math.floor((STORE.x0 + STORE.x1) / 2) + 0.5, math.floor((STORE.y0 + STORE.y1) / 2) + 0.5, 0)
    end
end)
waitFor(5, 3000, function()
    return not travelled or (sqAt(STORE.x0, STORE.y0, 0) ~= nil and sqAt(STORE.x1, STORE.y1, 0) ~= nil and getTimestampMs() - t0 > 9000)
end, function()
    if travelled then spot = findSpot(math.floor((STORE.x0 + STORE.x1) / 2), math.floor((STORE.y0 + STORE.y1) / 2), 0, 12) end
    say(spot and string.format("indoors at %d,%d (%d free room squares round it)", math.floor(spot.x), math.floor(spot.y), #spot.ring)
        or "ERR no room square with four free room squares round it")
    if spot then moveTo(spot.x, spot.y, spot.z) end
end)
step(30, function()
    if not ZeD_WorldWindow.isOpen() then pcall(ZeD_WorldWindow.open, pn) end
    local sq = p:getCurrentSquare()
    local grid = false
    pcall(function() grid = sq:hasGridPower() end)
    say(string.format("grid: world power %s, this square haveElectricity %s, hasGridPower %s, in a room %s", tostring(getWorld():isHydroPowerOn()),
        tostring(sq and sq:haveElectricity()), tostring(grid), tostring(sq and sq:getRoom() ~= nil)))
    check(grid, "the staging square has grid power")
    pcall(function() Mouse.setXY(20, 20) end)
end)

-- ---- the sets, placed ON a square first and their data touched after (the first run's three Java errors: the data of a
-- set not yet on a square asks the square about power). The set's own data is used: a house radio or TV as the game makes one.
local SETS = {
    { pid = "tv_widescreen", spr = "appliances_television_01_1", tv = true },
    { pid = "tv_black", spr = "appliances_television_01_5", tv = true },
    { pid = "tv_antique", spr = "appliances_television_01_9", tv = true },
    { pid = "radio_red", spr = "appliances_radio_01_9" },
}
local objs, worldItems = {}, {}
local function putSet(tv, spr, sq)
    local obj
    if tv then obj = IsoTelevision.new(getCell(), sq, getSprite(spr)) else obj = IsoRadio.new(getCell(), sq, getSprite(spr)) end
    sq:AddTileObject(obj)
    local d = obj:getDeviceData()
    if d then d:setIsTurnedOn(false); d:setDeviceVolume(0.5) end
    placed[#placed + 1] = obj
    return obj
end
local function removePlaced()
    for _, obj in ipairs(placed) do
        local sq = obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end
    end
    for _, it in ipairs(worldItems) do
        pcall(function()
            local wo = it:getWorldItem()
            local sq = wo and wo:getSquare()
            if sq then sq:removeWorldObject(wo) end
            if wo then wo:removeFromWorld() end
        end)
    end
    placed, worldItems, objs = {}, {}, {}
end
local function listed(n)
    local c = 0
    for _, r in ipairs(WW()._radios or {}) do for _, o in pairs(objs) do if r.radioInstance == o then c = c + 1 end end end
    return c >= n
end
-- pid: the face expected, or a function giving it when the step runs (the house tiles are found while the test runs)
local function show(key, pid, tag)
    step(5, function()
        for i, r in ipairs(WW()._radios or {}) do if objs[key] and r.radioInstance == objs[key] then WW()._radioIdx = i end end
    end)
    waitFor(5, 300, function()
        if not objs[key] then return true end
        local t = tw(WW())
        return t ~= nil and t.dev == objs[key] and settled(WW())
    end, function()
        if not objs[key] then return end
        local want = type(pid) == "function" and pid() or pid
        faceChecks(WW(), want, tag or (want .. " (placed, by its tile)"))
    end)
end

step(5, function()
    local ring = spot and spot.ring or {}
    for i, s in ipairs(SETS) do
        if ring[i] then objs[s.pid] = putSet(s.tv, s.spr, ring[i]) end
    end
    say("placed " .. #placed .. " sets (round the character, on their squares)")
end)
waitFor(5, 400, function() return listed(#placed) end, function()
    check(listed(#placed), "the World window lists the placed sets (" .. #placed .. ")")
    check(worldTab("radio"), "the World window's Radio tab opens on the placed sets")
end)
show("radio_red", "radio_red")
step(5, function() shot("4a_radio_red_placed") end)

-- ---- one TV through power, channels, the dial and knob, every screen state, the grid going away
local function S(pid)
    local o, t = objs[pid], tw(WW())
    if not (o and t and t.dev == o) then return nil end
    local s = st(o)
    return s, R.plateState(s, t.pid, t.des), t
end
local function powerId(pid) return pid == "tv_antique" and "volpwr" or "power" end

local function tvPower(pid)
    show(pid, pid)
    step(5, function()
        local o = objs[pid]
        if not o then check(false, pid .. ": placed"); return end
        local s, ps, t = S(pid)
        if not s then check(false, pid .. ": its face is up"); return end
        if pid == "tv_antique" then
            check(hitOf(t, "volpwr") ~= nil and hitOf(t, "power") == nil and hitOf(t, "channel") ~= nil,
                "tv_antique: the volume knob is one control (volpwr), the channel dial another")
        end
        check(s.grid == true, pid .. ": the set has grid power (" .. tostring(s.grid) .. ")")
        check(not ps.noPower, pid .. ": NO POWER dark on the grid")
        check(not s.on, pid .. ": off to start with")
        click(WW(), powerId(pid))
    end)
    step(10, function()
        local o = objs[pid]
        if not o then return end
        local s, ps = S(pid)
        check(dd(o):getIsTurnedOn(), pid .. ": power turns it on")
        check(s and s.on and ps.radioOn, pid .. ": the power lamp lights")
        check(ps.display ~= nil and ps.display.ch ~= nil, pid .. ": the channel display reads (" .. tostring(ps.display and ps.display.ch) .. ")")
    end)
end

local function stopI(o) local s = R.stopOf(dd(o):getChannel()); return s and s.i or 0 end

-- CH up / down (wrapping round the twelve) and the volume keys on the two box sets
local function tvChannelKeys(pid)
    step(5, function() local o = objs[pid]; if o then O.setChannel(p, o, R.stops()[1].freq) end end)
    step(8, function()
        local o = objs[pid]
        if not o then return end
        check(stopI(o) == 1, pid .. ": on the first stop (" .. stopI(o) .. ")")
        click(WW(), "chup")
    end)
    step(5, function() local o = objs[pid]; if o then check(stopI(o) == 2, pid .. ": CH up: the second stop (" .. stopI(o) .. ")"); click(WW(), "chdn") end end)
    step(5, function() local o = objs[pid]; if o then check(stopI(o) == 1, pid .. ": CH down: back to the first (" .. stopI(o) .. ")"); click(WW(), "chdn") end end)
    step(5, function() local o = objs[pid]; if o then check(stopI(o) == 12, pid .. ": CH down from the first wraps to the twelfth (" .. stopI(o) .. ")"); click(WW(), "chup") end end)
    step(5, function() local o = objs[pid]; if o then check(stopI(o) == 1, pid .. ": CH up from the twelfth wraps to the first (" .. stopI(o) .. ")") end end)
    step(5, function() local o = objs[pid]; if o then volWas = dd(o):getDeviceVolume(); click(WW(), "volup") end end)
    step(5, function()
        local o = objs[pid]
        if o then check(dd(o):getDeviceVolume() > volWas + 0.01, pid .. ": VOL up raises the volume"); click(WW(), "voldn") end
    end)
    step(5, function() local o = objs[pid]; if o then check(dd(o):getDeviceVolume() <= volWas + 0.01, pid .. ": VOL down lowers it again") end end)
end

-- the antique's 12-stop dial (it stops at its ends) and its push / pull volume knob
local function tvAntiqueDial(pid)
    step(5, function() local o = objs[pid]; if o then O.setChannel(p, o, R.stops()[1].freq) end end)
    for i = 1, 11 do
        step(3, function() local o = objs[pid]; if o then R.turn(p, o, "channel", 1) end end)
    end
    step(5, function()
        local o = objs[pid]
        if not o then return end
        local s, ps = S(pid)
        check(stopI(o) == 12, pid .. ": eleven clicks up the dial: the twelfth stop (" .. stopI(o) .. ")")
        check(ps.chIdx == 11, pid .. ": the dial's pointer is on the twelfth mark (" .. tostring(ps.chIdx) .. ")")
        R.turn(p, o, "channel", 1)
    end)
    step(5, function() local o = objs[pid]; if o then check(stopI(o) == 12, pid .. ": the dial stops at its upper end (" .. stopI(o) .. ")") end end)
    for i = 1, 11 do
        step(3, function() local o = objs[pid]; if o then R.turn(p, o, "channel", -1) end end)
    end
    step(5, function()
        local o = objs[pid]
        if not o then return end
        check(stopI(o) == 1, pid .. ": eleven clicks down: the first stop (" .. stopI(o) .. ")")
        R.turn(p, o, "channel", -1)
    end)
    step(5, function()
        local o = objs[pid]
        if not o then return end
        check(stopI(o) == 1, pid .. ": the dial stops at its lower end (" .. stopI(o) .. ")")
        click(WW(), "channel", "r")
    end)
    step(5, function()
        local o = objs[pid]
        if not o then return end
        check(stopI(o) == 2, pid .. ": a click on the dial's right half: up a stop (" .. stopI(o) .. ")")
        click(WW(), "channel", "l")
    end)
    step(5, function() local o = objs[pid]; if o then check(stopI(o) == 1, pid .. ": its left half: down a stop (" .. stopI(o) .. ")") end end)
    -- the knob: turned = volume (the set stays on), pushed / pulled = power
    step(5, function()
        local o = objs[pid]
        if not o then return end
        volWas = dd(o):getDeviceVolume()
        R.turn(p, o, "volpwr", 1)
    end)
    step(5, function()
        local o = objs[pid]
        if not o then return end
        check(dd(o):getDeviceVolume() > volWas + 0.01, pid .. ": the knob turned: the volume rises")
        check(dd(o):getIsTurnedOn(), pid .. ": the knob turned: still on")
        click(WW(), "volpwr")
    end)
    step(10, function()
        local o = objs[pid]
        if not o then return end
        check(not dd(o):getIsTurnedOn(), pid .. ": the knob pulled: off")
        click(WW(), "volpwr")
    end)
    step(10, function() local o = objs[pid]; if o then check(dd(o):getIsTurnedOn(), pid .. ": the knob pushed: on again") end end)
end

-- every stop of the dial in turn: snow after a change, the bars where no station is (12 and 13), then whatever the
-- station is doing at this hour (picture, sign-off with its card, standby). The schedule is the game's clock, so which
-- of those three appear is reported, not demanded.
local function tvScreens(pid)
    local seen, shotFor, states = {}, {}, {}
    for _, stop in ipairs(R.stops()) do
        step(2, function() local o = objs[pid]; if o then O.setChannel(p, o, stop.freq) end end)
        step(2, function()
            local o = objs[pid]
            if not o then return end
            local s = S(pid)
            if stop.i == 1 then check(s ~= nil and s.air == "snow", pid .. ": just changed channel: snow (" .. tostring(s and s.air) .. ")") end
        end)
        waitFor(3, 300, function()
            if not objs[pid] then return true end
            local s = S(pid)
            return s ~= nil and s.air ~= "snow"
        end, function()
            local o = objs[pid]
            if not o then return end
            local s, ps = S(pid)
            if not s then return end
            local air = s.air
            seen[air] = (seen[air] or 0) + 1
            states[stop.number] = air
            say(string.format("%s: channel %d (%s): %s, signal bad/fair/good %s/%s/%s", pid, stop.number, tostring(stop.id), tostring(air),
                tostring(ps.sigBad), tostring(ps.sigFair), tostring(ps.sigGood)))
            if not shotFor[air] then shotFor[air] = true; shot("4c_" .. pid .. "_" .. tostring(air)) end
            if stop.id == "triple_n" or stop.id == "turbo" then shot("4d_" .. pid .. "_" .. stop.id .. "_" .. tostring(air)) end
            if air == "bars" then
                check(ps.sigBad and not ps.sigGood, pid .. ": channel " .. stop.number .. ": the signal light bad on the bars")
                check(ps.display and ps.display.ch == string.format("%02d", stop.number), pid .. ": channel " .. stop.number .. ": the display reads it")
            end
            if air == "picture" then check(ps.sigGood, pid .. ": channel " .. stop.number .. ": the signal light good on air") end
            if air == "signoff" then
                local L = ZeD.PhysPx.offair.logos[stop.id]
                if L then check(getTexture(L.file) ~= nil, pid .. ": channel " .. stop.number .. " signs off with its logo, and the game's file loads") end
            end
        end)
    end
    step(3, function()
        local o = objs[pid]
        if not o then return end
        check(states[12] == "bars" and states[13] == "bars", pid .. ": 12 and 13 have no station: the bars (" .. tostring(states[12]) .. ", " .. tostring(states[13]) .. ")")
        local ok, bad = 0, {}
        for _, stop in ipairs(R.stops()) do
            if stop.id then
                local a = states[stop.number]
                if a == "picture" or a == "signoff" or a == "standby" then ok = ok + 1 else bad[#bad + 1] = stop.number .. "=" .. tostring(a) end
            end
        end
        check(ok == 10, pid .. ": the ten stations each show picture, sign-off or standby (" .. ok .. " of 10" .. (#bad > 0 and ("; not: " .. table.concat(bad, " ")) or "") .. ")")
        local list = {}
        for _, k in ipairs({ "snow", "bars", "picture", "signoff", "standby" }) do list[#list + 1] = k .. " x" .. (seen[k] or 0) end
        say(pid .. ": screens seen across the dial: " .. table.concat(list, ", "))
        for _, k in ipairs({ "picture", "signoff", "standby" }) do
            if not seen[k] then say(pid .. ": NOT REACHED at this hour: " .. k .. " (the game's broadcast clock decides)") end
        end
        O.setChannel(p, o, R.stops()[12].freq + 4)             -- a frequency off the dial
    end)
    step(math.floor(R.ZAP_MS / 16) + 12, function()
        local o = objs[pid]
        if not o then return end
        local s = S(pid)
        if s and not R.stopOf(dd(o):getChannel()) then
            check(s.air == "snow", pid .. ": a frequency off the dial: snow (" .. tostring(s.air) .. ")")
        else
            say(pid .. ": the set did not take a frequency off the dial (" .. tostring(dd(o):getChannel()) .. ")")
        end
    end)
end

-- power off, then the grid going away: NO POWER lit, the screen dark, the key does nothing
local function tvOffAndNoGrid(pid)
    step(5, function() local o = objs[pid]; if o then click(WW(), powerId(pid)) end end)
    step(10, function()
        local o = objs[pid]
        if not o then return end
        check(not dd(o):getIsTurnedOn(), pid .. ": power again turns it off")
        setGrid(false)
    end)
    waitFor(5, 300, function() local o = objs[pid]; return o == nil or not st(o).grid end, function()
        local o = objs[pid]
        if not o then return end
        local s, ps = S(pid)
        check(s and s.grid == false, pid .. ": with the grid off the set reports no power")
        check(ps and ps.noPower == true, pid .. ": NO POWER lit without the grid")
        shot("4e_" .. pid .. "_no_power")
        click(WW(), powerId(pid))
    end)
    step(10, function()
        local o = objs[pid]
        if not o then return end
        local s = S(pid)
        check(s and not s.on, pid .. ": the power key without the grid leaves the screen dark")
        pcall(function() dd(o):setIsTurnedOn(false) end)
        setGrid(true)
    end)
    waitFor(5, 300, function() local o = objs[pid]; return o == nil or st(o).grid end, function()
        local o = objs[pid]
        if o then check(st(o).grid, pid .. ": the grid back on: the set has power again") end
    end)
end

-- the controller on a TV: lands on power; the tape and headphone lists; the antique's knob and dial by the D-pad
local function tvPad(pid)
    step(5, function()
        Det.setLockedMode(Det.MODE_GAMEPAD)
        stashCarried({ "Base.Headphones", "Base.Earbuds" })
    end)
    landOnPower(WW, "worldTabContent", pid)
    if pid ~= "tv_antique" then
        padKey(WW, "worldTabContent", "slot", pid, "2_pad_" .. pid .. "_tape_list")
        padKey(WW, "worldTabContent", "phones", pid, "2_pad_" .. pid .. "_phones_list")
    else
        step(5, function()
            local e = Focus.getFocusedElement(WW())
            if e and e.onActivate then e.onActivate(WW(), e) end                 -- A: pushed
        end)
        step(10, function()
            local o = objs[pid]
            if not o then return end
            check(dd(o):getIsTurnedOn(), pid .. ": pad: A on the knob powers it")
            volWas = dd(o):getDeviceVolume()
            Focus.dispatchJoypadDir(WW(), "up")
        end)
        step(5, function()
            local o = objs[pid]
            if not o then return end
            check(dd(o):getDeviceVolume() > volWas + 0.01 and dd(o):getIsTurnedOn(), pid .. ": pad: up on the knob turns the volume, the set stays on")
            O.setChannel(p, o, R.stops()[3].freq)
            Focus.focusWhere(WW(), "worldTabContent", function(x) return x.id == "radio:tw:channel" end)
        end)
        step(8, function() Focus.dispatchJoypadDir(WW(), "up") end)
        step(5, function()
            local o = objs[pid]
            if o then check(stopI(o) == 4, pid .. ": pad: up on the dial: a stop up (" .. stopI(o) .. ")") end
            local e = Focus.focusWhere(WW(), "worldTabContent", function(x) return x.id == "radio:tw:volpwr" end)
            if e and e.onActivate then e.onActivate(WW(), e) end                 -- A: off
        end)
        step(10, function()
            local o = objs[pid]
            if o then check(not dd(o):getIsTurnedOn(), pid .. ": pad: A on the knob again: off") end
        end)
    end
    padEnd()
end

tvPower("tv_black")
tvChannelKeys("tv_black")
tvScreens("tv_black")
tvOffAndNoGrid("tv_black")
tvPad("tv_black")

tvPower("tv_widescreen")
tvChannelKeys("tv_widescreen")
tvScreens("tv_widescreen")
tvOffAndNoGrid("tv_widescreen")

tvPower("tv_antique")
tvAntiqueDial("tv_antique")
tvScreens("tv_antique")
tvOffAndNoGrid("tv_antique")
tvPad("tv_antique")

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

-- ===================================================================== 5. a house radio and a house TV found in the world
-- RtvFace.plateId resolves a world object by the item it was dropped as (modData.RadioItemID, an item on its square),
-- then by its tile's CustomItem, then by the tile's sprite (the sets above are found by that last way). Each way is
-- made to be the one that answers: a tile that answers nothing alone is given a dropped item; a tile that names an item.
local house = {}
step(5, function()
    removePlaced()
    local X = ZeD.PhysPx
    local ring = spot and spot.ring or {}
    local found = {}
    for _, sheet in ipairs({ { "appliances_radio_01_", false }, { "appliances_television_01_", true } }) do
        for i = 0, 63 do
            local name = sheet[1] .. i
            local spr = getSprite(name)
            local props = spr and spr:getProperties()
            if props then
                local ci = props:has("CustomItem") and props:get("CustomItem") or nil
                local pid = ci and X.rtv.items[tostring(ci)]
                local slot = sheet[2] and "tv" or "radio"
                if pid and X.plates[pid] and (R.isTv(pid) == sheet[2]) then
                    if not found[slot] or (i % 4 == 3 and found[slot].i % 4 ~= 3) then found[slot] = { name = name, pid = pid, i = i } end
                elseif not ci and not sheet[2] and not found.bare and ring[1] then
                    -- a radio tile that names no item and answers nothing by itself
                    local ok, probe = pcall(function() return IsoRadio.new(getCell(), ring[1], spr) end)
                    local dev = ok and probe and probe:getDeviceData()
                    if dev and not dev:getIsTwoWay() and R.plateId(probe, dev) == nil then found.bare = { name = name, i = i } end
                end
            end
        end
    end
    house = found
    say(string.format("house tiles: bare radio %s; CustomItem radio %s (%s); CustomItem TV %s (%s)", tostring(found.bare and found.bare.name),
        tostring(found.radio and found.radio.name), tostring(found.radio and found.radio.pid), tostring(found.tv and found.tv.name), tostring(found.tv and found.tv.pid)))
    if found.bare and ring[1] then
        -- a radio dropped on the floor: the IsoRadio beside its world item, modData.RadioItemID the item's id
        local obj = putSet(false, found.bare.name, ring[1])
        objs.house_bare = obj
        local dev = obj:getDeviceData()
        check(R.plateId(obj, dev) == nil, "house radio tile " .. found.bare.name .. ": no face of its own without a dropped item")
        local it = instanceItem("Base.RadioBlack")
        if it then
            ring[1]:AddWorldInventoryItem(it, 0.5, 0.5, 0)
            worldItems[#worldItems + 1] = it
            obj:getModData().RadioItemID = it:getID()
            check(R.plateId(obj, dev) == "radio_black", "house radio dropped as an item (RadioItemID): the item's face (" .. tostring(R.plateId(obj, dev)) .. ")")
        end
    else
        say("WARN no bare radio tile found: the dropped-item path is not exercised")
    end
    if found.radio and ring[2] then
        objs.house_ci_radio = putSet(false, found.radio.name, ring[2])
        local obj = objs.house_ci_radio
        check(R.plateId(obj, obj:getDeviceData()) == found.radio.pid, "house radio tile " .. found.radio.name .. " (CustomItem): " .. found.radio.pid
            .. " (" .. tostring(R.plateId(obj, obj:getDeviceData())) .. ")")
    else
        say("WARN no radio tile names an item with a face: the CustomItem path (radio) is not exercised")
    end
    if found.tv and ring[3] then
        objs.house_ci_tv = putSet(true, found.tv.name, ring[3])
        local obj = objs.house_ci_tv
        check(R.plateId(obj, obj:getDeviceData()) == found.tv.pid, "house TV tile " .. found.tv.name .. " (CustomItem): " .. found.tv.pid
            .. " (" .. tostring(R.plateId(obj, obj:getDeviceData())) .. ")")
    else
        say("WARN no TV tile names an item with a face: the CustomItem path (TV) is not exercised")
    end
end)
waitFor(5, 400, function() return listed(#placed) end, function()
    check(listed(#placed), "the World window lists the house sets (" .. #placed .. ")")
end)
local function houseShow(key, pidFn)
    show(key, pidFn, key .. " in the Radio tab")
    step(5, function()
        local o = objs[key]
        if not o then return end
        local s = R.read(o)
        check(s ~= nil and s.grid == true, key .. ": on the grid (" .. tostring(s and s.grid) .. ")")
        shot("5_" .. key)
    end)
end
houseShow("house_bare", function() return "radio_black" end)
houseShow("house_ci_radio", function() return house.radio and house.radio.pid end)
houseShow("house_ci_tv", function() return house.tv and house.tv.pid end)

-- ===================================================================== cleanup
step(10, function()
    clearQueue()
    menuClose()
    ISContextMenu.get = ctxGet
    RT.useFaces = true
    removePlaced()
    unstash()
    pcall(function() Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil) end)
    pcall(Focus.releaseFocus)
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
    if spot or travelled then moveTo(home.x, home.y, home.z); t0 = getTimestampMs() end
    say("cleanup: sets, house sets and " .. #added .. " items taken away")
end)
waitFor(5, 3000, function()
    return not travelled or (sqAt(math.floor(home.x), math.floor(home.y), math.floor(home.z)) ~= nil and getTimestampMs() - t0 > 3000)
end, function()
    say(string.format("back at %d,%d", math.floor(p:getX()), math.floor(p:getY())))
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
        if not (ok and done) then say("WARN step " .. qi .. ": waited " .. s.max .. " frames, the condition never held") end
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
