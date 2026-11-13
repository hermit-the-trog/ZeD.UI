-- ZeDUI/tools/qa/zedqa_cov_vehicles.lua  (Nov 12 2026, QA coverage: AUDIT_DESIGN_AND_COVERAGE_20261111.md Table B, vehicles;
-- repaired the same day after its independent review)
-- In game on the ZeD-QA save only (Saves/Sandbox/ZeD-QA; on any other save it touches nothing and stops), the character
-- on the Irvington drag strip (the prelude's ZEDQA_HOME). Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go, grep console.txt
-- for "ZEDQA cov_vehicles"; runner manifest cov_vehicles.txt (also in regression.txt's vehicles block). Each check prints
-- "PASS <what>" or "FAIL <what> (<got> vs <want>)" from values read off ZeD's own objects and the game's (the panels'
-- click areas and fields, the radio's device data, the car's lightbar modes and seats). A check headed "presence:" proves
-- only that a thing is there (a hook, a click area, a prompt); the effect checks after it press it. A "staging:" line
-- FAILs only when the run could not set up what the next check needs. It ends with RESULT and DONE. Screenshots:
-- Zomboid/Screenshots/zqa_covveh_*.png, each on a SHOT line.
--
-- WHAT IT CHECKS
--   Rod and clock-radio plates (ZeD.FishRod.draw, ZeD.SleepClock.draw) on a recording canvas: all 17 rod frames have a
--     plate and anchors; tension picks the frame; the line is pale at 0.89 and hot from 0.9, MAX dark at 0.84 and lit
--     from 0.85, the dial's pointer sits low when slack and in the red at the limit; at 2x the plate doubles and the line
--     and pointer are 2 x 2 squares on the 2x grid; the clock lights each digit's seven segments (10:46 PM, 9:05 AM with
--     the leading zero blank, 12:30 AM, 12:00 PM), the AM / PM dot, the ALARM lamp only when asked, 2x digits.
--   Fishing rod prop (Overrides/Fishing.lua on vanilla's Fishing.ISTensionUI): hooked; updateValue keeps the raw tension
--     beside vanilla's angle; render draws the rod with it at a whole multiple, low and near the middle.
--   Sleep clock (Overrides/Sleeping.lua on ISSleepingUI): hooked; render draws the clock at the panel's hour, centered, at
--     a whole multiple; with the character's own alarms switched off (back on after) the ALARM lamp is dark, an alarm
--     clock carried (in the inventory, in a bag) lights it, and it goes dark again.
--   Car radio up close (ZeD_CarRadio.lua, Overrides/CarRadio.lua) in a police car spawned beside the character, Devices
--     and the siren's Dashboard form pinned to Immersive for the face sections whatever ZeD setup says: the wheel's
--     Device Options opens it, not vanilla's window; every plate and design (RadioPlates.lua) control has a click area
--     (presence); the face draws at a whole multiple, the dash's; it stands above the dash; a press where the plate draws
--     VOL powers it (the click area sits on the plate). Through the mouse handlers: the glass reads FM and the frequency,
--     TUNE's halves step, a held preset stores (STORE flash), a short press recalls, an empty one flashes EMPTY, MUTE and
--     back, SEEK lands on the next station vanilla names (worked out here from vanilla's own list, not ZeD's), SCAN
--     starts on the one after and moves on after its dwell, SCAN again stops it. Controller: A's prompt, up turns VOL,
--     right moves right, B puts it away.
--   CD deck: no CD -> a grayed "No CDs" row; the list grows by one row for the CD given (a row per CD carried, counted
--     here); Escape closes the list before the radio; picking inserts (vanilla's action), PLAY plays (CD time on the
--     glass), PLAY again stops at once, EJECT gives the disc back.
--   Plain card (Devices: Simple): the card replaces the face, its power switch works, back to the face.
--   Two-way (ham set): the ham face, first stop CH up, MEM stores, CH up / down step and wrap both ways (01 -> last),
--     MIC (MIC OFF on the glass), a held MEM names a channel; an empty name keeps OK live and forgets it.
--   Siren controller (ZeD_SirenController.lua, SirenPlate.lua, the lightbar hook): the Lightbar slice opens it (not
--     ISLightbarUI) and puts the radio away; its ten click areas are the plate's (presence); clicks and the controller set
--     the car's lightbar modes through vanilla's commands (stops at ALARM, A wraps); the plain card works; the slice
--     closes it.
--   Seat chooser (ZeD_SeatChooser.lua, the seat hook), the car's own loot taken off its seats first: Switch Seat opens it
--     (not ISVehicleSeatUI); you at the wheel and every other seat empty, the ones vanilla's canSwitchSeat can't reach
--     marked out of reach, with vanilla's reason; planks read as items, their reason as vanilla's moveItemsFromSeat
--     answers, and the seat empty again once they are off; the controller's prompts (presence) and its seat grid; Cancel
--     and Escape close it; a click moves the character to a seat the driver can switch to: a back seat when the car has
--     one (the radio goes away there); the police car has none (its cage: its script empties the front seats' switches
--     to the back), so the click takes the seat beside, where the radio stays, and ZeD's reach test is asked about the
--     back seats with a stand-in occupant. The 1 key takes the wheel again, X gets out by the door (the radio goes
--     away); from outside: Enter Vehicle, no door, no seat of yours.
-- THE MOD BUG IT CATCHES: ZeD_RadioOps.chStep steps with ((at - 1 + dir) % n) + 1; Kahlua's % keeps the sign, so CH down
-- on channel 01 gives 0 and l:get(-1) throws. "CH down on channel 01 goes round to the last channel" FAILs until the count
-- is added before the % (the same trap: ObjectCards.lua, StationPopout.lua, ZeD_MainMenuOptions.lua).
-- THE LEDGER: given items, the discs (by id: a disc that is not one of the character's own goes), the character's alarms
-- switched off, the planks, the spawned car (removed once the character is out), the stood-in readers, the rod and clock
-- drawing wrappers, the qaJoy / qaPoint hooks as they were, the test panels, the debug console, god mode and a pause
-- lifted at the start are put back by the final steps. Those always run, each put-back on its own (one that throws is an
-- ERR line and the rest still run). A step that throws counts as a FAIL and the run goes on; a section that never came
-- up counts one FAIL and its steps are skipped. It enters no car but the one it spawned, and that one only after it
-- settled (square, chunk, physics seen, 1.5 s held: zedqa_dash_keys_edge.lua).

local TAG = "cov_vehicles"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end

-- only the QA save: anywhere else nothing is touched
local SAVE = nil
pcall(function() SAVE = getWorld():getWorld() end)
if SAVE ~= "ZeD-QA" or getPlayer() == nil then
    say("ERR not the ZeD-QA save with a player (" .. tostring(SAVE) .. "): nothing was touched")
    say("FAIL the run is on the ZeD-QA save (" .. tostring(SAVE) .. " vs ZeD-QA)")
    say("RESULT 0 pass, 1 fail")
    say("DONE")
    return
end

-- (a game paused when the run starts: unpaused for the steps, which run on ticks, and paused again at the very end)
local unpaused = false
pcall(function() if getGameSpeed and setGameSpeed and getGameSpeed() == 0 then setGameSpeed(1); unpaused = true end end)
if ZEDQA_HOME then ZEDQA_HOME(TAG) end   -- (open ground: an earlier script can leave the character indoors)
local p = getPlayer()
local pn = p:getPlayerNum()
local Z = ZeD or {}
local CR, RO, SI, SE = Z.CarRadio, Z.RadioOps, Z.Siren, Z.Seats
-- the run's state: counts, what was given / spawned / stood in, which sections came up (gates for the steps)
local V = { pass = 0, fail = 0, given = {}, spawned = {}, ok = {}, skipSec = {}, alarmsOff = {}, consoles = {}, planks = {},
            unpaused = unpaused, stage = { tries = 0, phys = false, since = nil, why = "" } }
pcall(function() V.god0 = p:isGodMod() end)
-- the test hooks as they were (put back as they were, not just cleared)
V.qa0 = {}
pcall(function() V.qa0.crJ, V.qa0.crP = CR.qaJoy, CR.qaPoint end)
pcall(function() V.qa0.siJ, V.qa0.siP = SI.qaJoy, SI.qaPoint end)
pcall(function() V.qa0.seJ, V.qa0.seP = SE.qaJoy, SE.qaPoint end)

-- ---------------------------------------------------------------------------------------------------------------
-- WORDS, CAPTURES, THE LEDGER'S HELPERS
-- ---------------------------------------------------------------------------------------------------------------
local function check(ok, what, got, want)
    if ok then
        V.pass = V.pass + 1
        say("PASS " .. what)
    else
        V.fail = V.fail + 1
        say("FAIL " .. what .. " (" .. tostring(got) .. " vs " .. tostring(want) .. ")")
    end
    return ok
end
-- set-up the next check needs: silent when it worked, a FAIL headed "staging:" when it did not
local function staged(ok, what, got, want)
    if not ok then check(false, "staging: " .. what, got, want) end
    return ok
end
local function shot(name)
    local f = "zqa_covveh_" .. name .. ".png"
    pcall(function() getCore():TakeFullScreenshot(f) end)
    say("SHOT " .. f)
end
local function give(full, cont)
    local it = (cont or p:getInventory()):AddItem(full)
    if it then V.given[#V.given + 1] = it end
    return it
end
local function visible(o) return o ~= nil and o:isReallyVisible() == true end
local function root() return (ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or (getPlayerScreenHeight(pn) / 1080) end
local function near(a, b, eps) return a ~= nil and b ~= nil and math.abs(a - b) <= (eps or 0.001) end
local function whole(k) return type(k) == "number" and k >= 1 and k == math.floor(k) end

-- a stand-in panel that records what a plate's draw function asks of it
local function canvas()
    local c = { rects = {}, texs = {} }
    c.drawRect = function(self, x, y, w, h, a, r, g, b) self.rects[#self.rects + 1] = { x = x, y = y, w = w, h = h, a = a, r = r, g = g, b = b } end
    c.drawTextureScaledAspect = function(self, t, x, y, w, h) self.texs[#self.texs + 1] = { t = t, x = x, y = y, w = w, h = h } end
    return c
end
local function sameColor(q, col) return math.abs(q.r - col[1]) < 0.002 and math.abs(q.g - col[2]) < 0.002 and math.abs(q.b - col[3]) < 0.002 end
-- rects of a color (and alpha, when given) on a canvas; inside a box (x0, y0, w, h) when given
local function countColor(cv, col, a, box)
    local n = 0
    for _, q in ipairs(cv.rects) do
        if sameColor(q, col) and (a == nil or math.abs(q.a - a) < 0.002)
           and (box == nil or (q.x >= box[1] and q.x < box[1] + box[3] and q.y >= box[2] and q.y < box[2] + box[4])) then
            n = n + 1
        end
    end
    return n
end

-- the car's radio, its device data, a fresh reading, the prop up close
local function part() return V.car and V.car:getPartById("Radio") end
local function dd() local pt = part(); return pt and pt:getDeviceData() end
local function rd() local pt = part(); return pt and RO.read(pt) end
local function prop() return CR and CR.props and CR.props[pn] or nil end

-- a click area of a panel (the radio, the siren: x, y, w, h in the panel's px) by id
local function hitOf(panel, id)
    for _, h in ipairs(panel and panel._hits or {}) do if h.id == id then return h end end
    return nil
end
local function idSet(list) local s = {}; for _, h in ipairs(list or {}) do s[h.id] = true end; return s end
-- the ids of want missing from the set have ("" when none)
local function missing(want, have)
    local out = {}
    for _, id in ipairs(want or {}) do if not have[id] then out[#out + 1] = id end end
    return table.concat(out, ",")
end
-- a press and release at (x, y) of a panel, through its own mouse handlers
local function pressAt(panel, x, y)
    x, y = math.floor(x), math.floor(y)
    panel:onMouseDown(x, y)
    panel:onMouseUp(x, y)
end
-- a press and release on a click area (fx: where across it, 0..1)
local function click(panel, id, fx)
    local h = hitOf(panel, id)
    if not h then return false end
    pressAt(panel, h.x + math.floor(h.w * (fx or 0.5)), h.y + math.floor(h.h / 2))
    return true
end
-- the press only (a hold); release() lets go where it was pressed
local function hold(panel, id)
    local h = hitOf(panel, id)
    if not h then return false end
    V.hold = { panel = panel, x = h.x + math.floor(h.w / 2), y = h.y + math.floor(h.h / 2) }
    panel:onMouseDown(V.hold.x, V.hold.y)
    return true
end
local function release()
    local hd = V.hold
    V.hold = nil
    if hd then pcall(function() hd.panel:onMouseUp(hd.x, hd.y) end) end
end
local function clickRect(panel, r) pressAt(panel, r.x + r.w / 2, r.y + r.h / 2) end

-- the vanilla windows ZeD's take the place of
local function uiOfType(typ)
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local ok, t = pcall(function() return ui:get(i):getTable() end)
        if ok and t and t.Type == typ then return t end
    end
    return nil
end
local function vanillaRadioUp()
    if not ISRadioWindow then return false end
    local a = ISRadioWindow.instances and ISRadioWindow.instances[pn]
    local b = ISRadioWindow.instancesIso and ISRadioWindow.instancesIso[pn]
    return visible(a) or visible(b)
end
local function vanillaSeatsUp()
    local u = ISVehicleMenu.seatUI and ISVehicleMenu.seatUI[pn]
    return visible(u)
end
-- the naming prompt a radio opened (ZeD's prompt or vanilla's ISTextBox: both keep target, entry and yes); nil without
-- a radio to ask for, so no other dialog is ever taken for it
local function promptFor(target)
    if target == nil then return nil end
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local ok, t = pcall(function() return ui:get(i):getTable() end)
        if ok and t and t.target == target and t.entry and t.yes then return t end
    end
    return nil
end

-- the radio's plate controls (PhysPx, what the face draws) and its design's (RadioPlates.lua, baked with the plates)
local function plateIds(kind)
    local X = ZeD.PhysPx
    local des = X and X.plates[X.radios[kind]]
    local out = {}
    for _, h in ipairs(des and des.hits or {}) do if (h.kind or "press") ~= "look" then out[#out + 1] = h.id end end
    return out, des
end
local function plateHitOf(des, id)
    for _, q in ipairs(des and des.hits or {}) do if q.id == id then return q end end
    return nil
end
local function designIds(kind)
    local f = ZeD.RadioPlates and ZeD.RadioPlates.faces and ZeD.RadioPlates.faces[kind]
    if not f then return nil end
    local out = { "vol", "tune" }
    if f.slot then out[#out + 1] = "slot" end
    for _, b in ipairs(f.buttons or {}) do out[#out + 1] = b.id end
    return out
end
-- a prop (the radio, the siren) up close: above the dash, its right edge on the dash console's (or the screen's)
local function onDash(panel, what)
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance(pn)
    if not (d and d:isVisible() and d._consoleRect) then staged(false, "a dash under the " .. what .. " to check its place against", "no dash", "a dash"); return end
    local cs = d._consoleRect
    local consoleRight = d:getX() + math.floor((cs.x + cs.w) * (d._s or 1))
    local right = panel:getX() + panel:getWidth()
    local screenRight = getPlayerScreenLeft(pn) + getPlayerScreenWidth(pn)
    check(panel:getY() + panel:getHeight() <= d:getY() and (math.abs(right - consoleRight) <= 1 or right == screenRight),
        "the " .. what .. " stands above the dash, its right edge on the console's",
        "bottom " .. tostring(panel:getY() + panel:getHeight()) .. " right " .. tostring(right), "<= " .. tostring(d:getY()) .. ", " .. tostring(consoleRight))
end
local function wheelRadio() ISVehicleMenu.onSignalDevice(p, part()) end
local function fit(ft)
    local pt = part()
    if not pt then return false end
    pt:setInventoryItem(instanceItem(ft))
    Vehicles.InstallComplete.Radio(V.car, pt)
    return true
end
local function storedAt(st, hz)
    for _, q in ipairs(st.presets or {}) do if q.freq == hz then return true end end
    return false
end
-- TUNE up (the face's knob) until the frequency is stored on no button
local function tuneFree()
    for _ = 1, 40 do
        local st = rd()
        if not st or not storedAt(st, st.channel) then return end
        click(prop(), "tune", 0.8)
    end
end
-- one TUNE click from cur (vanilla's 200 kHz grid; the band wraps)
local function stepFrom(cur, dir, st)
    local nv = math.floor((cur + dir * RO.STEP) / RO.STEP + 0.5) * RO.STEP
    if nv > st.max then nv = st.min elseif nv < st.min then nv = st.max end
    return nv
end
-- the next frequency up the band (vanilla's 200 kHz grid; past the top it starts again at the bottom) that vanilla's own
-- list names a station on (ZomboidRadio:getChannelName), worked out here apart from ZeD_RadioOps; vanilla's "Unknown
-- Frequency" is no station. nil when the band holds no station but cur.
local function stationAfter(cur, lo, hi)
    local zr = getZomboidRadio()
    if not (zr and cur and lo and hi) then return nil end
    local f = cur
    for _ = 1, math.floor((hi - lo) / 200) + 1 do
        f = f + 200
        if f > hi then f = lo end
        if f == cur then return nil end
        local ok, name = pcall(function() return zr:getChannelName(f) end)
        if ok and name ~= nil and tostring(name) ~= "" and not string.find(string.upper(tostring(name)), "UNKNOWN") then return f end
    end
    return nil
end
-- the CDs the character carries and in the bags in its inventory (two bags deep) of the radio's media type, counted here
-- from vanilla's item calls apart from ZeD_RadioOps.cds
local function cdsCarried(mt)
    local out = {}
    local function walk(inv, depth)
        local items = inv and inv:getItems()
        if not items then return end
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local ok, isCd = pcall(function() return it:isRecordedMedia() and it:getMediaType() == mt end)
            if ok and isCd then out[#out + 1] = it end
            if depth < 2 and instanceof(it, "InventoryContainer") then walk(it:getInventory(), depth + 1) end
        end
    end
    pcall(function() walk(p:getInventory(), 0) end)
    return out
end
-- the slot's list: the CDs its rows hold, and whether the grayed "No CDs" row is there
local function listRows(ctx)
    local rows, noCds = {}, false
    if not ctx then return rows, false end
    for k = 1, (ctx.numOptions or 1) - 1 do
        local o = ctx.options[k]
        if o then
            if o.param1 ~= nil then rows[#rows + 1] = o.param1
            elseif o.notAvailable == true and o.name == ZeD.tr("UI_ZeD_Radio_NoCds") then noCds = true end
        end
    end
    return rows, noCds
end
local function closeList()
    pcall(function() local pr = prop(); local m = pr and pr:openList(); if m then m:close() end end)
    pcall(function() local pr = prop(); local c = pr and pr._list; if c and c:isReallyVisible() then c:closeAll() end end)
end
-- the character's retail discs by id (put back: a disc that is not among them goes)
local function discIds()
    local set = {}
    pcall(function()
        local list = p:getInventory():getAllTypeRecurse("Base.Disc_Retail")
        for i = 0, list:size() - 1 do set[list:get(i):getID()] = true end
    end)
    return set
end
-- the alarms set on anything the character carries or wears (alarm clocks and watches, bags four deep)
local function alarmsOn()
    local out = {}
    local function walk(inv, depth)
        if not inv or depth > 4 then return end
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if instanceof(it, "AlarmClock") or instanceof(it, "AlarmClockClothing") then
                local ok, on = pcall(function() return it:isAlarmSet() end)
                if ok and on then out[#out + 1] = it end
            end
            if instanceof(it, "InventoryContainer") then walk(it:getInventory(), depth + 1) end
        end
    end
    pcall(function() walk(p:getInventory(), 0) end)
    return out
end
local function restoreAlarms()
    for _, it in ipairs(V.alarmsOff) do pcall(function() it:setAlarmSet(true) end) end
    V.alarmsOff = {}
end
-- (stood in) a form setting's reader, pinned while the sections that need a form run: Devices (the radio's face or its
-- plain card) and the siren's Dashboard form. ZeD setup's choice is not touched; the real readers go back at the end.
local function pinDevices(simple)
    local S = ZeD.Settings
    if not S then return end
    if not V.dsPinned then V.realDS, V.dsPinned = S.devicesSimple, true end
    V.devSimple = simple
    S.devicesSimple = function() return V.devSimple == true end
end
local function pinSiren(simple)
    if not SI then return end
    if not V.ssPinned then V.realSS, V.ssPinned = SI.simple, true end
    V.sirSimple = simple
    SI.simple = function() return V.sirSimple == true end
end
local function modes() local v = V.car; return v:getLightbarLightsMode(), v:getLightbarSirenMode() end
-- ZeD's reach test (ZeD_RadioOps.reachable: what keeps the radio up close or puts it away on a seat switch) asked about a
-- stand-in occupant of seat i of the car
local function reachFrom(i)
    local car = V.car
    local sv = { getSeat = function() return i end, getPartById = function(_, id) return car:getPartById(id) end }
    local ok, r = pcall(RO.reachable, { getVehicle = function() return sv end })
    if ok then return r end
    return nil
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE CAR: a police car (lightbar, radio part, four seats) on a free square beside the character, seated only once it
-- has a square and a chunk, its physics seen once and all held 1.5 s (zedqa_dash_keys_edge.lua's staging)
-- ---------------------------------------------------------------------------------------------------------------
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 }, { 6, 6 }, { -6, 0 } }
local function spawnCar()
    local S = V.stage
    -- (Nov 12 2026, test cleanup rule 7: the one shared car spawn in zedqa_prelude.lua; the whole footprint is checked there)
    if not ZEDQA_CAR_SPAWN then say("ERR needs zedqa_prelude.lua first (ZEDQA_CAR_SPAWN)"); return false end
    if S.tries >= 3 then return false end
    S.tries = S.tries + 1
    local v = ZEDQA_CAR_SPAWN("Base.CarLightsPolice", TAG)
    if v then
        V.car = v
        V.spawned[#V.spawned + 1] = v
        S.phys, S.since = false, nil
        return true
    end
    return false
end
local function carSettled(v)
    local S = V.stage
    local sq, chunk, dist, removed = nil, nil, 999, false
    pcall(function() removed = v:isRemovedFromWorld() end)
    pcall(function() sq = v:getSquare() end)
    if sq then pcall(function() chunk = sq:getChunk() end) end
    pcall(function() dist = v:DistTo(p) end)
    if not S.phys then pcall(function() S.phys = v:isPhysicsActive() == true end) end
    S.why = string.format("square %s, chunk %s, %.1f away, physics seen %s", tostring(sq ~= nil), tostring(chunk ~= nil), dist, tostring(S.phys))
    if removed or not (sq and chunk and dist <= 12 and S.phys) then S.since = nil; return false end
    S.since = S.since or getTimestampMs()
    return getTimestampMs() - S.since >= 1500
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE PLAN: steps run one after another, ms after the previous one; a wait step polls until its test is true or ms
-- pass. need = the section a step depends on (V.ok[need]); a step whose section never came up is skipped, and the
-- section counts one FAIL. The final steps always run.
-- ---------------------------------------------------------------------------------------------------------------
local PLAN = {}
local drive   -- (the driver, declared here: the last final step takes it off OnTick before it pauses the game again)
local function add(ms, fn, need) PLAN[#PLAN + 1] = { ms = ms, fn = fn, need = need } end
local function waitUntil(ms, test, need, onTimeout) PLAN[#PLAN + 1] = { wait = true, ms = ms, fn = test, need = need, onTimeout = onTimeout } end
local function final(ms, fn) PLAN[#PLAN + 1] = { ms = ms, fn = fn, final = true } end

-- ===============================================================================================================
-- 0. SETUP
-- ===============================================================================================================
add(100, function()
    -- the game's debug console off the pictures (each one hidden is shown again at the end)
    local u = UIManager.getUI()
    for i = 0, u:size() - 1 do
        local e = u:get(i)
        if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false); V.consoles[#V.consoles + 1] = e end
    end
    p:setGodMod(true)
    check(CR ~= nil and RO ~= nil and SI ~= nil and SE ~= nil, "presence: ZeD's car radio, radio workings, siren controller and seat chooser are loaded",
        tostring(CR ~= nil) .. "/" .. tostring(RO ~= nil) .. "/" .. tostring(SI ~= nil) .. "/" .. tostring(SE ~= nil), "true/true/true/true")
    local safe = ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() or false
    check(not safe, "ZeD's safe mode is off (with it on every hook below hands over to vanilla)", safe, false)
    local hooked = ISVehicleMenu._zedRadio ~= nil and ISVehicleMenu._zedSeats ~= nil and ISLightbarUITimedAction ~= nil and ISLightbarUITimedAction._zedSiren ~= nil
    check(hooked, "presence: the vehicle wheel's hooks are in: Device Options, Switch Seat, Lightbar", hooked, true)
end)

-- ===============================================================================================================
-- 1. THE ROD AND CLOCK-RADIO PLATES, drawn on a recording canvas
-- ===============================================================================================================
local LINE, LINE_HOT, NEEDLE, MAXC = { 0.914, 0.902, 0.855 }, { 1.0, 0.541, 0.431 }, { 0.91, 0.251, 0.173 }, { 1.0, 0.353, 0.235 }
local function rodFrame(i) return Texture.getSharedTexture(ZeD.FishRod.TEXDIR .. string.format("%02d", i) .. ".png", 3) end
-- the same plate: the shared texture itself, or one of the same name
local function sameTex(a, b)
    if a == nil or b == nil then return false end
    if a == b then return true end
    local ok, same = pcall(function() local na = a:getName(); return na ~= nil and na ~= "" and tostring(na) == tostring(b:getName()) end)
    return ok and same == true
end
-- the rod's pointer tip on a canvas: the NEEDLE square farthest from the dial's center
local function needleTip(cv, dial)
    local best, bd = nil, -1
    for _, q in ipairs(cv.rects) do
        if sameColor(q, NEEDLE) then
            local d = (q.x - dial[1]) ^ 2 + (q.y - dial[2]) ^ 2
            if d > bd then best, bd = q, d end
        end
    end
    return best
end
add(100, function()
    local F = ZeD.FishRod
    check(F ~= nil and ZeD.SleepClock ~= nil, "presence: the rod and clock-radio plates are loaded (ZeD.FishRod, ZeD.SleepClock)", tostring(F ~= nil) .. "/" .. tostring(ZeD.SleepClock ~= nil), "true/true")
    if not F then return end
    local miss = {}
    for i = 0, F.FRAMES do if not (rodFrame(i) and F.ANCH[i + 1]) then miss[#miss + 1] = i end end
    check(#miss == 0 and #F.ANCH == F.FRAMES + 1, "presence: all " .. (F.FRAMES + 1) .. " rod frames have a plate and anchors", "missing " .. table.concat(miss, ","), "none")
    -- the tension picks the frame (slack and none: the straight blank; past 1: the last)
    local bad = {}
    for _, c in ipairs({ { -0.5, 0 }, { 0, 0 }, { 0.5, 8 }, { 0.9, 14 }, { 1.0, 16 }, { 1.4, 16 } }) do
        local cv = canvas()
        local ok, ret = pcall(F.draw, cv, 0, 0, 1, c[1])
        local t = cv.texs[1] and cv.texs[1].t
        if not (ok and ret == true and sameTex(t, rodFrame(c[2]))) then
            local got = "?"
            for i = 0, F.FRAMES do if sameTex(t, rodFrame(i)) then got = i end end
            bad[#bad + 1] = tostring(c[1]) .. "->" .. tostring(got) .. (ok and "" or (" " .. tostring(ret)))
        end
    end
    check(#bad == 0, "the rod's tension picks its frame (slack 0, 0.5 frame 8, 0.9 frame 14, 1 and past it 16)", table.concat(bad, " "), "all as listed")
    -- the line and MAX on each side of their thresholds (0.89 / 0.9 and 0.84 / 0.85)
    local TS = { 0.5, 0.84, 0.85, 0.87, 0.89, 0.9, 0.95 }
    local hot, pale, mx = {}, {}, {}
    for i, t in ipairs(TS) do
        local cv = canvas()
        F.draw(cv, 0, 0, 1, t)
        hot[i], pale[i], mx[i] = countColor(cv, LINE_HOT), countColor(cv, LINE), countColor(cv, MAXC, 0.45)
    end
    local hotOk = pale[1] > 0 and pale[5] > 0 and pale[6] == 0
    for i = 1, 5 do if hot[i] ~= 0 then hotOk = false end end
    if not (hot[6] > 0 and hot[7] > 0) then hotOk = false end
    check(hotOk, "the line is pale under load and runs hot from 0.9 (pale at 0.89, all hot at 0.9)",
        "hot / pale squares at 0.5, 0.84, 0.85, 0.87, 0.89, 0.9, 0.95: " .. table.concat(hot, "/") .. " ; " .. table.concat(pale, "/"), "0/0/0/0/0/>0/>0 ; pale >0 to 0.89, 0 at 0.9")
    local mxOk = mx[1] == 0 and mx[2] == 0
    for i = 3, 7 do if mx[i] ~= 1 then mxOk = false end end
    check(mxOk, "MAX lights from 0.85 (dark at 0.84)", "MAX at 0.5, 0.84, 0.85, 0.87, 0.89, 0.9, 0.95: " .. table.concat(mx, "/"), "0/0/1/1/1/1/1")
    local cvS, cvL = canvas(), canvas()
    F.draw(cvS, 0, 0, 1, -0.5); F.draw(cvL, 0, 0, 1, 1.0)
    local dS, dL = F.ANCH[1].dial, F.ANCH[F.FRAMES + 1].dial
    local tS, tL = needleTip(cvS, dS), needleTip(cvL, dL)
    check(tS ~= nil and tL ~= nil and tS.x < dS[1] and tS.y > dS[2] and tL.x > dL[1], "the dial's pointer sits low on the left when slack and in the red at the limit",
        tS and tL and ("slack " .. tostring(tS.x) .. "," .. tostring(tS.y) .. " limit " .. tostring(tL.x) .. "," .. tostring(tL.y)),
        "left of " .. tostring(dS[1]) .. " below " .. tostring(dS[2]) .. ", right of " .. tostring(dL[1]))
    -- whole multiples: at 2x the plate doubles and the live line and pointer are 2 x 2 squares on the 2x grid
    local cv2 = canvas()
    F.draw(cv2, 0, 0, 2, 0.5)
    local live, offGrid = 0, 0
    for _, q in ipairs(cv2.rects) do
        if sameColor(q, LINE) or sameColor(q, NEEDLE) then
            live = live + 1
            if not (q.w == 2 and q.h == 2 and math.floor(q.x / 2) * 2 == q.x and math.floor(q.y / 2) * 2 == q.y) then offGrid = offGrid + 1 end
        end
    end
    local t2 = cv2.texs[1]
    check(t2 ~= nil and t2.w == F.W * 2 and t2.h == F.H * 2 and live > 0 and offGrid == 0,
        "the rod draws at whole multiples (2x: the plate " .. (F.W * 2) .. " x " .. (F.H * 2) .. ", its line and pointer 2 x 2 squares on the 2x grid)",
        (t2 and (t2.w .. " x " .. t2.h) or "no plate") .. ", " .. offGrid .. " of " .. live .. " squares off", (F.W * 2) .. " x " .. (F.H * 2) .. ", 0 off")
end)
-- the clock's digits: plate pixels of the four digit cells (DX 36, DY 26; cells 16 x 34 at 0, 22, 52, 74), the dots
local LIT = { 1.0, 0.2, 0.133 }
local SEGS = { [0] = 6, 2, 5, 5, 4, 5, 6, 3, 7, 6 }   -- lit segments of each seven-segment digit
local CELLX = { 36, 58, 88, 110 }
add(100, function()
    local C = ZeD.SleepClock
    if not C then return end
    local bad = {}
    -- hour of day, the four digits (false: blank), PM
    local cases = { { 22.78, { 1, 0, 4, 6 }, true, "10:46 PM" }, { 9 + 5 / 60, { false, 9, 0, 5 }, false, "9:05 AM" },
                    { 0.5, { 1, 2, 3, 0 }, false, "12:30 AM" }, { 12.0, { 1, 2, 0, 0 }, true, "12:00 PM" } }
    for _, c in ipairs(cases) do
        local cv = canvas()
        local ok, ret = pcall(C.draw, cv, 0, 0, 1, c[1], false)
        local got = {}
        for d = 1, 4 do got[d] = countColor(cv, LIT, nil, { CELLX[d], 26, 16, 34 }) end
        local good = ok and ret == true
        for d = 1, 4 do if got[d] ~= (c[2][d] and SEGS[c[2][d]] or 0) then good = false end end
        local am, pm = countColor(cv, LIT, nil, { 25, 29, 3, 3 }), countColor(cv, LIT, nil, { 25, 54, 3, 3 })
        if am ~= (c[3] and 0 or 1) or pm ~= (c[3] and 1 or 0) then good = false end
        if countColor(cv, LIT, nil, { 132, 54, 3, 3 }) ~= 0 then good = false end
        if not good then bad[#bad + 1] = c[4] .. " segs " .. table.concat(got, "/") .. " am " .. am .. " pm " .. pm end
    end
    check(#bad == 0, "the clock radio lights each digit's segments, a blank leading hour, AM / PM, no ALARM unasked", table.concat(bad, "; "), "10:46 PM, 9:05 AM, 12:30 AM, 12:00 PM")
    local cvA = canvas()
    C.draw(cvA, 0, 0, 1, 7.5, true)
    check(countColor(cvA, LIT, nil, { 132, 54, 3, 3 }) == 1, "the ALARM lamp lights when the alarm is set", countColor(cvA, LIT, nil, { 132, 54, 3, 3 }), 1)
    local cv2 = canvas()
    C.draw(cv2, 0, 0, 2, 22.78, false)
    local t = cv2.texs[1]
    check(t and t.w == C.W * 2 and t.h == C.H * 2 and countColor(cv2, LIT, nil, { CELLX[1] * 2, 52, 32, 68 }) == 2,
        "the clock plate and its digits scale by whole multiples (2x)", t and (t.w .. " x " .. t.h), (C.W * 2) .. " x " .. (C.H * 2))
end)

-- ===============================================================================================================
-- 2. THE FISHING ROD PROP: vanilla's tension meter, made as FishingManager makes it
-- ===============================================================================================================
add(100, function()
    local TUI = Fishing and Fishing.ISTensionUI
    local hooked = TUI ~= nil and TUI._zedOrigRender ~= nil and TUI.render ~= TUI._zedOrigRender and TUI.updateValue ~= TUI._zedOrigUpdateValue
    check(hooked, "presence: vanilla's tension meter is hooked (render, updateValue)", hooked, true)
    if not TUI then return end
    -- the rod's drawing, watched: what the meter's render passed it
    V.realRod = ZeD.FishRod.draw
    ZeD.FishRod.draw = function(self, ox, oy, k, t)
        local r = V.realRod(self, ox, oy, k, t)
        V.rodRec = { ax = self:getAbsoluteX(), ay = self:getAbsoluteY(), ox = ox, oy = oy, k = k, t = t, ret = r }
        return r
    end
    local ui = TUI:new(p)
    ui:initialise(); ui:instantiate(); ui:addToUIManager(); ui:setVisible(true)
    V.tui = ui
    ui:updateValue(0.72)
    V.ok.rod = true
end)
add(400, function()
    local ui, r = V.tui, V.rodRec
    check(near(ui.zedTension, 0.72, 1e-6) and near(ui.val, -50 + 120 * 0.72, 1e-6), "updateValue keeps the raw tension for the rod and vanilla's dial angle",
        tostring(ui.zedTension) .. " / " .. tostring(ui.val), "0.72 / 36.4")
    check(r ~= nil and r.ret == true and near(r.t, 0.72, 1e-6), "the meter's render draws the rod (its plates loaded) with the tension it was fed",
        r and (tostring(r.ret) .. " t=" .. tostring(r.t)), "true t=0.72")
    if not r then return end
    check(whole(r.k), "the rod is drawn at a whole multiple (" .. tostring(r.k) .. "x)", r.k, "a whole number from 1")
    local x, y, w, h = r.ax + r.ox, r.ay + r.oy, ZeD.FishRod.W * r.k, ZeD.FishRod.H * r.k
    local sl, st, sw, sh = getPlayerScreenLeft(pn), getPlayerScreenTop(pn), getPlayerScreenWidth(pn), getPlayerScreenHeight(pn)
    check(x >= sl and x + w <= sl + sw and y + h <= st + sh and y >= st + sh / 2 - h and math.abs(x + w / 2 - (sl + sw / 2)) <= 42 * root() + 2,
        "the rod stands at the bottom middle of the player's screen", tostring(x) .. "," .. tostring(y) .. " " .. tostring(w) .. "x" .. tostring(h),
        "inside " .. tostring(sl) .. "," .. tostring(st) .. " " .. tostring(sw) .. "x" .. tostring(sh) .. ", low, centered")
    shot("1_rod")
    V.rodRec = nil
    ui:updateValue(-0.6)
end, "rod")
add(300, function()
    local r = V.rodRec
    check(r ~= nil and near(r.t, -0.6, 1e-6) and near(V.tui.val, -70 + 20 * 0.4, 1e-6), "slack: the rod gets the slack tension, vanilla's dial its own angle",
        r and (tostring(r.t) .. " / " .. tostring(V.tui.val)), "-0.6 / -62")
    V.tui:setVisible(false); V.tui:removeFromUIManager(); V.tui = nil
    ZeD.FishRod.draw = V.realRod; V.realRod = nil
end, "rod")

-- ===============================================================================================================
-- 3. THE SLEEP CLOCK: vanilla's sleep panel, its own update off so it stays while awake
-- ===============================================================================================================
add(100, function()
    check(ISSleepingUI ~= nil and ISSleepingUI._zedOrigRender ~= nil and ISSleepingUI.render ~= ISSleepingUI._zedOrigRender, "presence: vanilla's sleep panel is hooked (render)",
        ISSleepingUI and tostring(ISSleepingUI.render ~= ISSleepingUI._zedOrigRender), true)
    if not (ISSleepingUI and ZeD.SleepClock) then return end
    -- (staged) the character's own alarms off for the lamp's checks, so the clocks given below are the only ones set
    V.alarmsOff = alarmsOn()
    for _, it in ipairs(V.alarmsOff) do pcall(function() it:setAlarmSet(false) end) end
    if #V.alarmsOff > 0 then say("note: " .. #V.alarmsOff .. " alarm(s) the character carries switched off for the lamp's checks (back on after)") end
    V.realClock = ZeD.SleepClock.draw
    ZeD.SleepClock.draw = function(self, ox, oy, k, hour, alarm)
        local r = V.realClock(self, ox, oy, k, hour, alarm)
        V.clockRec = { ax = self:getAbsoluteX(), ox = ox, k = k, hour = hour, alarm = alarm, ret = r }
        return r
    end
    local ui = ISSleepingUI:new(pn)
    ui.update = function() end
    ui.hourOfDay = 14 + 40 / 60
    ui:setVisible(true); ui:addToUIManager()
    V.sleep = ui
    V.ok.sleep = true
end)
add(400, function()
    local r = V.clockRec
    check(r ~= nil and r.ret == true and near(r.hour, 14 + 40 / 60, 1e-6), "the sleep panel draws the clock radio (its plate loaded) at the hour it was given",
        r and (tostring(r.ret) .. " " .. tostring(r.hour)), "true 14.67")
    if not r then return end
    check(whole(r.k), "the clock is drawn at a whole multiple (" .. tostring(r.k) .. "x)", r.k, "a whole number from 1")
    local cx = r.ax + r.ox + ZeD.SleepClock.W * r.k / 2
    local want = getPlayerScreenLeft(pn) + getPlayerScreenWidth(pn) / 2
    check(math.abs(cx - want) <= 1, "the clock stands in the middle of the player's screen", cx, want)
    check(r.alarm ~= true, "with no alarm set on anything the character carries, the ALARM lamp is dark", r.alarm, false)
    shot("2_sleep_clock")
    V.clock = give("Base.AlarmClock2")
    if V.clock then V.clock:setAlarmSet(true) end
    V.sleep.hourOfDay = 6 + 58 / 60
    V.sleep._zedAlarmAt = nil; V.clockRec = nil
end, "sleep")
add(300, function()
    local r = V.clockRec
    check(V.clock ~= nil and r ~= nil and r.alarm == true and near(r.hour, 6 + 58 / 60, 1e-6), "an alarm clock carried with its alarm set lights ALARM; the hour follows the panel",
        r and (tostring(r.alarm) .. " " .. tostring(r.hour)), "true 6.97")
    if V.clock then V.clock:setAlarmSet(false) end
    V.sleep._zedAlarmAt = nil; V.clockRec = nil
end, "sleep")
add(300, function()
    local r = V.clockRec
    check(r ~= nil and r.alarm ~= true, "its alarm switched off, the lamp goes dark again", r and r.alarm, false)
    local bag = give("Base.Bag_Satchel")
    if bag then
        local c2 = give("Base.AlarmClock2", bag:getInventory())
        if c2 then c2:setAlarmSet(true); V.clock2 = c2 end
    end
    V.sleep._zedAlarmAt = nil; V.clockRec = nil
end, "sleep")
add(300, function()
    local r = V.clockRec
    check(V.clock2 ~= nil and r ~= nil and r.alarm == true, "an alarm clock set inside a bag the character carries lights ALARM too", r and r.alarm, true)
    if V.clock2 then V.clock2:setAlarmSet(false) end
    V.sleep:setVisible(false); V.sleep:removeFromUIManager(); V.sleep = nil
    ZeD.SleepClock.draw = V.realClock; V.realClock = nil
    restoreAlarms()
end, "sleep")

-- ===============================================================================================================
-- 4. THE CAR: spawned beside the character, settled, then repaired, fueled, keyed and seated in one tick
-- ===============================================================================================================
add(300, function()
    if not spawnCar() then check(false, "a police car spawned beside the character", "no free loaded square near " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()), "a car") end
end)
waitUntil(8000, function() return V.car == nil or carSettled(V.car) end, nil, function()
    say("note: the car did not settle (" .. V.stage.why .. "); a second one on the next square")
    if V.car then pcall(function() V.car:permanentlyRemove() end); V.car = nil end
    spawnCar()
end)
waitUntil(8000, function() return V.car == nil or carSettled(V.car) end)
add(0, function()
    local v = V.car
    if not v then return end
    if not carSettled(v) then check(false, "the police car settled beside the character before seating", V.stage.why, "square, chunk, physics seen, held 1.5 s"); return end
    pcall(function() v:repair() end)
    pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
    pcall(function()
        local b = v:getPartById("Battery")
        local it = b and b:getInventoryItem()
        if it then pcall(function() it:setCurrentUsesFloat(1.0) end); pcall(function() it:setUsedDelta(1.0) end) end
    end)
    pcall(function() if v:isKeysInIgnition() then v:setKeysInIgnition(false) end end)
    pcall(function() local k = p:getInventory():AddItem(v:createVehicleKey()); if k then V.given[#V.given + 1] = k end end)
    pcall(function() v:enter(0, p) end)
    if p:getVehicle() == v then triggerEvent("OnEnterVehicle", p) end
end)
add(1500, function()
    local v = V.car
    local seated = v ~= nil and p:getVehicle() == v and v:getSeat(p) == 0
    check(seated, "seated at the wheel of the police car spawned beside the character", v and (tostring(p:getVehicle() == v) .. " seat " .. tostring(v:getSeat(p))), "in it, seat 0")
    V.ok.car = seated
    if seated then say(string.format("note: battery %.2f, radio part %s, lightbar %s", v:getBatteryCharge(), tostring(part() ~= nil), tostring(v:hasLightbar()))) end
end)

-- ===============================================================================================================
-- 5. THE CAR RADIO UP CLOSE: the Premium Technologies CD receiver
-- ===============================================================================================================
add(200, function()
    pinDevices(false)   -- (stood in) Devices: Immersive for the face sections, whatever ZeD setup says
    CR.closeFor(pn)
    fit("Base.RadioRed")
    local st = rd()
    check(st ~= nil and st.kind == "premium", "the Premium Technologies CD radio is fitted (vanilla's install)", st and st.kind, "premium")
    wheelRadio()
end, "car")
add(500, function()
    local pr = prop()
    V.ok.radio = visible(pr)
    check(V.ok.radio, "the wheel's Device Options brings the radio up close", visible(pr), true)
    check(not vanillaRadioUp(), "vanilla's radio window stays shut", vanillaRadioUp(), false)
    if not V.ok.radio then return end
    local have = idSet(pr._hits)
    local want, des = plateIds("premium")
    local m1, m2 = missing(want, have), missing(designIds("premium"), have)
    check(#want > 0 and m1 == "" and m2 == "", "presence: every control of the plate and of the radio's design (RadioPlates.lua) has a click area", "missing " .. m1 .. " | " .. m2, "none")
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance(pn)
    local dashK = d and d._s or nil
    local s = pr._s
    check(whole(s) and (dashK == nil or s == dashK), "the radio's face draws at a whole multiple" .. (dashK and ", the dash's own" or ""), s, dashK or "a whole number from 1")
    onDash(pr, "radio")
    shot("3_radio_premium")
    V.on0 = dd():getIsTurnedOn()
    -- a press where the plate draws VOL (its place in the design times the face's multiple), through the face's own mouse
    -- handlers: it reaches VOL only when the click area sits on the plate
    local ph = plateHitOf(des, "vol")
    V.volPressed = ph ~= nil and whole(s)
    if V.volPressed then pressAt(pr, (ph.x + ph.w / 2) * s, (ph.y + ph.h / 2) * s) end
end, "car")
add(300, function()
    local on1 = dd():getIsTurnedOn()
    check(V.volPressed and on1 ~= V.on0, "a press where the plate draws VOL switches the set " .. (V.on0 and "off" or "on") .. " (its click area sits on the plate)",
        (not V.volPressed) and "no VOL on the plate to press" or tostring(on1), not V.on0)
    if not on1 then click(prop(), "vol") end
end, "radio")
add(300, function()
    local st = rd()
    check(st.on, "the radio is on, powered from the car's battery", tostring(st.switchOn) .. "/" .. tostring(st.powered), "true/true")
    local r = RO.displayReading(st)
    local freq = string.format("%.1f", st.channel / 1000)   -- (an FM set's frequency in MHz, one decimal)
    check(r ~= nil and r.band == "FM" and r.big == freq, "the glass reads FM and the frequency", r and (tostring(r.band) .. " " .. tostring(r.big)), "FM " .. freq)
    RO.run("SetVolume", p, part(), 0.6)
    V.ch0 = st.channel
    click(prop(), "tune", 0.8)
end, "radio")
add(250, function()
    local st = rd()
    local want = stepFrom(V.ch0, 1, st)
    check(st.channel == want, "a click on TUNE's right half turns up one step", st.channel, want)
    V.ch1 = st.channel
    click(prop(), "tune", 0.2)
end, "radio")
add(250, function()
    local st = rd()
    local want = stepFrom(V.ch1, -1, st)
    check(st.channel == want, "a click on TUNE's left half turns down one step", st.channel, want)
    tuneFree()
    st = rd()
    V.n0, V.chS = #st.presets, st.channel
    V.storeIdx = math.min(3, V.n0 + 1)
    hold(prop(), "p3")
end, "radio")
add(950, function()   -- (held past O.HOLD_MS: the radio's update stores once)
    release()
    local st = rd()
    local q = st.presets[V.storeIdx]
    check(q ~= nil and q.freq == V.chS, "holding P3 stores the station (on button " .. V.storeIdx .. ")", q and q.freq, V.chS)
    check(st.flash == ZeD.tr("UI_ZeD_Radio_Store", V.storeIdx), "the glass flashes STORE " .. V.storeIdx, st.flash, ZeD.tr("UI_ZeD_Radio_Store", V.storeIdx))
    local r = RO.displayReading(st)
    check(r ~= nil and r.preset == "P" .. V.storeIdx, "the glass marks the station P" .. V.storeIdx, r and r.preset, "P" .. V.storeIdx)
    click(prop(), "tune", 0.8)
end, "radio")
add(250, function()
    V.tuneMoved = rd().channel ~= V.chS
    staged(V.tuneMoved, "TUNE moves off the stored station, so the recall below tests a real recall", rd().channel, "not " .. tostring(V.chS))
    click(prop(), "p" .. V.storeIdx)
end, "radio")
add(250, function()
    local st = rd()
    if V.tuneMoved then check(st.channel == V.chS, "a short press on P" .. V.storeIdx .. " tunes back to the station stored there", st.channel, V.chS) end
    V.chE = st.channel
    if #st.presets < 6 then click(prop(), "p6") end
end, "radio")
add(250, function()
    local st = rd()
    if #st.presets < 6 then
        check(st.flash == ZeD.tr("UI_ZeD_Radio_Empty") and st.channel == V.chE, "a press on an empty preset flashes EMPTY and keeps the station", tostring(st.flash) .. " " .. st.channel, ZeD.tr("UI_ZeD_Radio_Empty") .. " " .. V.chE)
    else
        staged(false, "an empty preset to press (all six are stored, so the empty-preset press is not checked)", #st.presets, "under 6")
    end
    V.vol0 = st.volume
    click(prop(), "mute")
end, "radio")
add(250, function()
    local st = rd()
    check(st.muted and st.volume <= 0.001, "MUTE silences the set", st.volume, 0)
    click(prop(), "mute")
end, "radio")
add(250, function()
    check(near(rd().volume, V.vol0), "MUTE again brings back the volume it had", rd().volume, V.vol0)
    -- SEEK and SCAN against the stations worked out here from vanilla's own list: the next one up, and the one after it
    -- (SCAN's first stop); with fewer than two named stations on the band neither can be told from doing nothing
    local st = rd()
    V.chB = st.channel
    V.seekWant = stationAfter(st.channel, st.min, st.max)
    V.scanWant = V.seekWant and stationAfter(V.seekWant, st.min, st.max)
    if staged(V.scanWant ~= nil, "two stations vanilla names on the radio's band, to SEEK to and SCAN between (SEEK and SCAN are not checked)",
              "from " .. tostring(st.channel) .. ": " .. tostring(V.seekWant) .. ", " .. tostring(V.scanWant), "two stations") then
        click(prop(), "seek")
    else
        V.seekWant = nil
    end
end, "radio")
add(250, function()
    if not V.seekWant then return end
    local st = rd()
    check(st.channel == V.seekWant, "SEEK tunes to the next station up that vanilla names (" .. tostring(V.seekWant) .. ", worked out from vanilla's list)", st.channel, V.seekWant)
    click(prop(), "scan")
end, "radio")
add(250, function()
    if not V.seekWant then return end
    local st = rd()
    check(st.scanning and st.channel == V.scanWant, "SCAN starts scanning, on to the next station (" .. tostring(V.scanWant) .. ")",
        tostring(st.scanning) .. " " .. tostring(st.channel), "true " .. tostring(V.scanWant))
    V.scanNext = stationAfter(V.scanWant, st.min, st.max) or V.scanWant
end, "radio")
waitUntil(9000, function() local st = rd(); return st == nil or not V.seekWant or not st.scanning or st.channel ~= V.scanWant end, "radio")
add(100, function()
    if not V.seekWant then return end
    local st = rd()
    check(st.scanning and st.channel == V.scanNext, "SCAN moves on to the station after it once its dwell is up (" .. tostring(V.scanNext) .. ")",
        tostring(st.scanning) .. " " .. tostring(st.channel), "true " .. tostring(V.scanNext))
    V.scanOn = st.scanning
    if st.scanning then click(prop(), "scan") end
end, "radio")
add(250, function()
    if V.seekWant and V.scanOn then
        local st = rd()
        check(not st.scanning and st.channel == V.scanNext, "SCAN again stops it, on the station it was at", tostring(st.scanning) .. " " .. tostring(st.channel), "false " .. tostring(V.scanNext))
    end
    -- the controller (the radio's qa hook stands in for a pad holding it)
    CR.qaJoy = {}
    prop().focusId = "vol"
    RO.run("SetVolume", p, part(), 0.5)
end, "radio")
add(300, function()
    local pr = prop()
    check(pr.joyfocus ~= nil and pr:labelA() == ZeD.tr("IGUI_RadioPower"), "presence: with a controller on VOL the strip offers A: Power", pr:labelA(), ZeD.tr("IGUI_RadioPower"))
    V.volA = rd().volume
    pr:onJoypadDirUp()
end, "radio")
add(250, function()
    local want = math.min(1, math.floor((V.volA + 0.1) * 10 + 0.5) / 10)
    check(near(rd().volume, want), "up on the D-pad turns VOL up a tenth", rd().volume, want)
    local pr = prop()
    V.f0 = hitOf(pr, "vol")
    pr:onJoypadDirRight()
end, "radio")
add(200, function()
    local pr = prop()
    local h = hitOf(pr, pr.focusId)
    check(pr.focusId ~= "vol" and h ~= nil and V.f0 ~= nil and h.x + h.w / 2 > V.f0.x + V.f0.w / 2, "right on the D-pad moves to a control to the right", pr.focusId, "a control right of VOL")
    pr:onJoypadDown(Joypad.BButton)
end, "radio")
add(200, function()
    check(not visible(prop()), "B puts the radio away", visible(prop()), false)
    CR.qaJoy = nil
    wheelRadio()
end, "radio")
add(400, function()
    check(visible(prop()), "the wheel's slice brings it back", visible(prop()), true)
end, "radio")

-- ===============================================================================================================
-- 6. THE CD DECK
-- ===============================================================================================================
add(200, function()
    local st = rd()
    V.mt = st.mediaType
    V.discIds0 = discIds()
    V.discs0 = p:getInventory():getCountTypeRecurse("Base.Disc_Retail")
    V.cdsHad = #cdsCarried(V.mt)
    V.listOpened = not st.hasMedia
    if V.listOpened then click(prop(), "slot") end   -- (a disc already in: one staging FAIL in the next step)
end, "radio")
add(400, function()
    local rows, noCds = listRows(V.listOpened and prop()._list or nil)
    V.rows0 = V.listOpened and #rows or nil
    if not V.listOpened then
        staged(false, "an empty CD slot to open the list before the CD (a disc was in; the empty list is not checked)", "a disc in", "no disc")
    elseif V.cdsHad == 0 then
        check(#rows == 0 and noCds, "with no CD carried (counted here), the slot's list says so, grayed", #rows .. " rows, No CDs " .. tostring(noCds), "0 rows, No CDs true")
    else
        staged(false, "a character with no CDs, for the 'No CDs' list (carries " .. V.cdsHad .. "; the empty list is not checked)", V.cdsHad, 0)
    end
    closeList()
    local cd = give("Base.Disc_Retail")
    local list = getZomboidRadio():getRecordedMedia():getAllMediaForCategory("CDs")
    if cd and list and list:size() > 0 then cd:setRecordedMediaData(list:get(0)) end
    V.cd = cd
end, "radio")
add(200, function()
    local cds, has = RO.cds(p, part()), false
    for _, it in ipairs(cds) do if it == V.cd then has = true end end
    check(has, "a CD carried is one the slot offers (vanilla's media type)", #cds, "includes the CD given")
    click(prop(), "slot")
end, "radio")
add(400, function()
    local pr = prop()
    local rows = listRows(pr._list)
    local carried = cdsCarried(V.mt)
    local carriedSet, seen = {}, {}
    for _, it in ipairs(carried) do carriedSet[it] = true end
    local has, twice, stray = false, 0, 0
    for _, it in ipairs(rows) do
        if it == V.cd then has = true end
        if seen[it] then twice = twice + 1 end
        seen[it] = true
        if not carriedSet[it] then stray = stray + 1 end
    end
    check(has and twice == 0 and stray == 0 and #rows == #carried and (V.rows0 == nil or #rows == V.rows0 + 1),
        "the slot's list gains a row for the CD given: a row per CD carried (counted here), none twice",
        #rows .. " rows (before " .. tostring(V.rows0) .. "), the CD's " .. tostring(has) .. ", twice " .. twice .. ", not carried " .. stray,
        #carried .. " rows, the CD's true, 0, 0")
    check(pr:openList() ~= nil, "the list is ZeD's menu, open over the radio", pr:openList() ~= nil, true)
    CR.takeEscape()
end, "radio")
add(250, function()
    check(prop():openList() == nil and visible(prop()), "Escape closes the CD list first; the radio stays up", tostring(prop():openList() ~= nil) .. "/" .. tostring(visible(prop())), "false/true")
    click(prop(), "slot")
end, "radio")
add(400, function()
    local ctx = prop()._list
    local opt
    for k = 1, (ctx and ctx.numOptions - 1 or 0) do
        local o = ctx.options[k]
        if o and o.param1 == V.cd then opt = o end
    end
    check(opt ~= nil, "presence: the CD's row is in the list", opt ~= nil, true)
    if opt then opt.onSelect(opt.target, opt.param1) end   -- (what a click on the row runs)
    closeList()
end, "radio")
waitUntil(6000, function() local st = rd(); return st == nil or st.hasMedia end, "radio")
add(100, function()
    local st = rd()
    check(st.hasMedia, "picking the CD puts it in the slot (vanilla's media action)", st.hasMedia, true)
    local r = RO.displayReading(st)
    check(r ~= nil and r.cdTag == "CD", "the glass shows CD with a disc in", r and r.cdTag, "CD")
    click(prop(), "play")
end, "radio")
waitUntil(3000, function() local st = rd(); return st == nil or st.playing end, "radio")
add(400, function()
    local st = rd()
    local r = RO.displayReading(st)
    check(st.playing and r ~= nil and r.band == "CD" and r.cd == true, "PLAY plays the disc: the glass turns to the CD's time", tostring(st.playing) .. " " .. tostring(r and r.band), "true CD")
    shot("4_radio_cd")
    click(prop(), "play")
    check(not rd().playing, "PLAY again reads stopped at once", rd().playing, false)
end, "radio")
add(250, function() click(prop(), "eject") end, "radio")
waitUntil(6000, function() local st = rd(); return st == nil or not st.hasMedia end, "radio")
add(200, function()
    check(not rd().hasMedia, "EJECT takes the disc out", rd().hasMedia, false)
    local n = p:getInventory():getCountTypeRecurse("Base.Disc_Retail")
    check(n == V.discs0 + 1, "the disc is back in the character's inventory (one, no copy)", n, V.discs0 + 1)
end, "radio")

-- ===============================================================================================================
-- 7. THE PLAIN CARD (Devices: Simple; the setting's reader stood in for, so nothing is saved)
-- ===============================================================================================================
add(200, function() pinDevices(true) end, "radio")
add(300, function()
    local pr = prop()
    check(pr._plain == true and hitOf(pr, "power") ~= nil, "Devices: Simple draws the plain card, with its power switch", tostring(pr._plain) .. " " .. tostring(hitOf(pr, "power") ~= nil), "true true")
    shot("5_radio_plain")
    V.onP = dd():getIsTurnedOn()
    click(pr, "power")
end, "radio")
add(250, function()
    check(dd():getIsTurnedOn() ~= V.onP, "the plain card's power switch switches the set", dd():getIsTurnedOn(), not V.onP)
    click(prop(), "power")
end, "radio")
add(250, function()
    check(dd():getIsTurnedOn() == V.onP, "and switches it back", dd():getIsTurnedOn(), V.onP)
    pinDevices(false)
end, "radio")
add(300, function()
    check(prop()._plain == false and hitOf(prop(), "vol") ~= nil, "back to Immersive, the face again", prop()._plain, false)
end, "radio")

-- ===============================================================================================================
-- 8. THE TWO-WAY SET: the ham radio (the police car's own kind)
-- ===============================================================================================================
add(200, function()
    CR.closeFor(pn)
    fit("Base.HamRadio1")
    wheelRadio()
end, "radio")
add(500, function()
    local pr, st = prop(), rd()
    V.ok.ham = visible(pr) and st ~= nil and st.kind == "ham"
    check(V.ok.ham, "the ham set fitted comes up close as the ham face", st and st.kind, "ham")
    if not V.ok.ham then return end
    check(pr.focusId == "chup", "a two-way set's controller starts on CH up", pr.focusId, "chup")
    local have = idSet(pr._hits)
    local m1, m2 = missing((plateIds("ham")), have), missing(designIds("ham"), have)
    check(m1 == "" and m2 == "", "presence: every control of the ham plate and its design has a click area", "missing " .. m1 .. " | " .. m2, "none")
    if not st.on then click(pr, "vol") end
end, "radio")
add(300, function()
    local st = rd()
    check(st.on, "VOL switches the two-way set on", st.on, true)
    -- (set-up) room for two channels, and off any stored one
    local pc = dd():getDevicePresets()
    local l, max = pc:getPresets(), pc:getMaxPresets()
    while l:size() > math.max(0, max - 2) do l:remove(l:get(l:size() - 1)) end
    tuneFree()
    V.tw0 = #rd().presets
    click(prop(), "mem")
end, "ham")
add(250, function()
    local st = rd()
    local n = #st.presets
    check(n == V.tw0 + 1 and st.presets[n].freq == st.channel, "MEM stores the channel", n, V.tw0 + 1)
    check(st.flash == ZeD.tr("UI_ZeD_Radio_ChStored", string.format("%02d", n)), "the glass says CH " .. string.format("%02d", n) .. " STORED", st.flash, ZeD.tr("UI_ZeD_Radio_ChStored", string.format("%02d", n)))
    tuneFree()
    click(prop(), "mem")
end, "ham")
add(250, function()
    local st = rd()
    check(#st.presets == V.tw0 + 2, "a second MEM stores another channel", #st.presets, V.tw0 + 2)
    click(prop(), "chup")
end, "ham")
add(250, function()
    local st = rd()
    check(st.channel == st.presets[1].freq, "CH up on the last channel goes round to channel 01", st.channel, st.presets[1].freq)
    click(prop(), "chup")
end, "ham")
add(250, function()
    local st = rd()
    check(#st.presets >= 2 and st.channel == st.presets[2].freq, "CH up steps on to channel 02", st.channel, st.presets[2] and st.presets[2].freq)
    click(prop(), "chdn")
end, "ham")
add(250, function()
    local st = rd()
    check(st.channel == st.presets[1].freq, "CH down steps back to channel 01", st.channel, st.presets[1].freq)
    -- down from 01: round to the last (ZeD_RadioOps.chStep; Kahlua's % keeps the sign, the mod bug this catches)
    local ok, e = pcall(click, prop(), "chdn")
    V.chdnErr = (not ok) and tostring(e) or nil
    if not ok then pcall(function() prop():onMouseUpOutside(0, 0) end) end
end, "ham")
add(250, function()
    local st = rd()
    local want = st.presets[#st.presets].freq
    check(V.chdnErr == nil and st.channel == want, "CH down on channel 01 goes round to the last channel", V.chdnErr or st.channel, want)
    V.mic0 = st.micMuted
    click(prop(), "mic")
end, "ham")
add(250, function()
    local st = rd()
    local r = RO.displayReading(st)
    check(st.micMuted ~= V.mic0, "MIC mutes the microphone", st.micMuted, not V.mic0)
    local want = st.micMuted and ZeD.tr("UI_ZeD_Radio_MicOff") or ZeD.tr("UI_ZeD_Radio_TxOk")
    check(r ~= nil and r.tx == want, "the glass says " .. want .. " to match", r and r.tx, want)
    click(prop(), "mic")
end, "ham")
add(250, function()
    check(rd().micMuted == V.mic0, "MIC again: back as it was", rd().micMuted, V.mic0)
    -- naming: on a stored channel, MEM held
    if not rd().presetIdx then click(prop(), "chup") end
end, "ham")
add(200, function()
    V.nameIdx = rd().presetIdx
    hold(prop(), "mem")
end, "ham")
add(950, function()
    release()
    local box = promptFor(prop())
    check(box ~= nil, "holding MEM opens the naming prompt", box ~= nil, true)
    if not box then return end
    box.entry:setText("QA NET")
    if box.pressPrimary then box:pressPrimary() else box:onClick(box.yes) end   -- (Enter: OK)
end, "ham")
add(300, function()
    local st = rd()
    local q = V.nameIdx and st.presets[V.nameIdx]
    check(q ~= nil and q.name == "QA NET", "OK names the channel", q and q.name, "QA NET")
    V.nBefore = #st.presets
    hold(prop(), "mem")
end, "ham")
add(950, function()
    release()
    local box = promptFor(prop())
    if not box then check(false, "holding MEM again opens the prompt", "none", "the prompt"); return end
    box.entry:setText("")
    pcall(function() box:updateButtons() end)
    check(box.yes.enable ~= false, "an empty name keeps OK live (the way to forget a channel)", box.yes.enable, true)
    if box.pressPrimary then box:pressPrimary() else box:onClick(box.yes) end
end, "ham")
add(300, function()
    local st = rd()
    check(#st.presets == V.nBefore - 1, "OK with an empty name forgets the channel", #st.presets, V.nBefore - 1)
    local want = ZeD.tr("UI_ZeD_Radio_ChCleared", string.format("%02d", V.nameIdx or 0))
    check(st.flash == want, "the glass says " .. want, st.flash, want)
    shot("6_radio_ham")
end, "ham")

-- ===============================================================================================================
-- 9. THE SIREN CONTROLLER (the Lightbar slice, through vanilla's timed action)
-- ===============================================================================================================
add(200, function()
    pinSiren(false)   -- (stood in) the siren's Dashboard form: Immersive for the face, whatever ZeD setup says
    if not visible(prop()) then wheelRadio() end
end, "car")
add(400, function()
    V.radioUp = visible(prop())
    ISVehicleMenu.onLightbar(p)
end, "car")
waitUntil(3000, function() return visible(SI.get(pn)) end, "car")
add(300, function()
    local s = SI.get(pn)
    V.ok.siren = visible(s)
    check(V.ok.siren, "the wheel's Lightbar slice brings up the siren controller", visible(s), true)
    check(uiOfType("ISLightbarUI") == nil, "vanilla's lightbar window stays shut", uiOfType("ISLightbarUI") ~= nil, false)
    check(V.radioUp and not visible(prop()), "one prop up close at a time: the radio went away", tostring(V.radioUp) .. "/" .. tostring(visible(prop())), "true/false")
    if not V.ok.siren then return end
    local des = ZeD.PhysPx.plates.siren
    local want = {}
    for _, h in ipairs(des.hits) do want[#want + 1] = h.id end
    check(#s._hits == #want and missing(want, idSet(s._hits)) == "", "presence: its click areas are the plate's ten (two knobs, eight positions)", #s._hits, #want)
    onDash(s, "siren controller")
    shot("7_siren")
    click(s, "lights:2")
end, "car")
add(300, function()
    local l = modes()
    check(l == 2, "a click on LIGHTS 2 sets the bar's lights to 2 (vanilla's command)", l, 2)
    click(SI.get(pn), "siren:1")
end, "siren")
add(300, function()
    local _, s = modes()
    check(s == 1, "a click on YELP sets the siren to 1", s, 1)
    click(SI.get(pn), "siren:knob")
end, "siren")
add(300, function()
    local _, s = modes()
    check(s == 2, "a click on the SIREN knob steps it on to WAIL", s, 2)
    click(SI.get(pn), "lights:0")
end, "siren")
add(300, function()
    local l = modes()
    check(l == 0, "a click on OFF puts the lights off", l, 0)
    SI.qaJoy = {}
    local s = SI.get(pn)
    s.focus = 1
    s:onJoypadDirRight()
end, "siren")
add(200, function()
    local s = SI.get(pn)
    check(s.focus == 2, "right on the D-pad picks the SIREN switch", s.focus, 2)
    s:onJoypadDirUp()
end, "siren")
add(300, function()
    local _, sm = modes()
    check(sm == 3, "up turns the siren to ALARM", sm, 3)
    SI.get(pn):onJoypadDirUp()
end, "siren")
add(300, function()
    local _, sm = modes()
    check(sm == 3, "up at ALARM stays there (the switch's end)", sm, 3)
    SI.get(pn):onJoypadDown(Joypad.AButton)
end, "siren")
add(300, function()
    local _, sm = modes()
    check(sm == 0, "A steps it on round to STANDBY", sm, 0)
    local s = SI.get(pn)
    s:onJoypadDirLeft()
    s:onJoypadDirUp()
end, "siren")
add(300, function()
    local s = SI.get(pn)
    local l = modes()
    check(s.focus == 1 and l == 1, "left goes back to LIGHTS and up turns them to 1", s.focus .. "/" .. l, "1/1")
    s:onJoypadDown(Joypad.BButton)
end, "siren")
add(200, function()
    check(not visible(SI.get(pn)), "B puts the controller away", visible(SI.get(pn)), false)
    SI.qaJoy = nil
    ISVehicleMenu.onLightbar(p)
end, "siren")
waitUntil(3000, function() return visible(SI.get(pn)) end, "siren")
add(200, function() pinSiren(true) end, "siren")
add(300, function()
    local s = SI.get(pn)
    local want = {}
    for _, h in ipairs(ZeD.PhysPx.plates.siren.hits) do want[#want + 1] = h.id end
    check(s._plainOn == true and #s._hits == 10 and missing(want, idSet(s._hits)) == "", "presence: the simple dash draws the controller as a plain card with the same ten switches",
        tostring(s._plainOn) .. " " .. #s._hits, "true 10")
    shot("8_siren_plain")
    click(s, "lights:3")
end, "siren")
add(300, function()
    local l = modes()
    check(l == 3, "the plain card's LIGHTS 3 sets the lights to 3", l, 3)
    click(SI.get(pn), "lights:0")
    pinSiren(false)
end, "siren")
add(300, function()
    local l = modes()
    check(l == 0, "and its OFF puts them off", l, 0)
    ISVehicleMenu.onLightbar(p)
end, "siren")
waitUntil(3000, function() return not visible(SI.get(pn)) end, "siren")
add(100, function()
    check(not visible(SI.get(pn)), "the Lightbar slice again puts the controller away", visible(SI.get(pn)), false)
end, "siren")

-- ===============================================================================================================
-- 10. THE SEAT CHOOSER
-- ===============================================================================================================
add(200, function()
    local v = V.car
    local maxP = v:getMaxPassengers()
    -- (staged) the car's own loot off its seats, so what each seat holds is known (the car goes at the end)
    for i = 0, maxP - 1 do
        pcall(function() local c = v:getPartForSeatContainer(i):getItemContainer(); if c and not c:isEmpty() then c:removeAllItems() end end)
    end
    V.sw = {}   -- the seats the driver can switch to (vanilla's canSwitchSeat), fitted and empty
    for i = 1, maxP - 1 do
        if v:isSeatInstalled(i) and not v:isSeatOccupied(i) and v:canSwitchSeat(0, i) then V.sw[#V.sw + 1] = i end
    end
    V.back = nil
    for _, i in ipairs(V.sw) do if i > 1 and not V.back then V.back = i end end
    V.to = V.back or V.sw[1]   -- (a back seat when the driver can reach one: the radio goes away there; else the seat beside)
    V.itemSeat = nil           -- a fitted seat for the planks: not the driver's, not the one switched to
    for i = 1, maxP - 1 do if not V.itemSeat and i ~= V.to and v:isSeatInstalled(i) then V.itemSeat = i end end
    V.itemSeat = V.itemSeat or V.to
    ISVehicleMenu.onShowSeatUI(p, v)
end, "car")
add(400, function()
    local w, v = SE.get(pn), V.car
    V.ok.seats = visible(w)
    check(V.ok.seats, "the wheel's Switch Seat brings up ZeD's seat chooser", visible(w), true)
    check(not vanillaSeatsUp(), "vanilla's seat window stays shut", vanillaSeatsUp(), false)
    if not V.ok.seats then return end
    check(w.title == getText("IGUI_SwitchSeat"), "seated, it is titled Switch Seat", w.title, getText("IGUI_SwitchSeat"))
    local maxP = v:getMaxPassengers()
    check(#(w._seats or {}) == maxP, "presence: a place for every seat", #(w._seats or {}), maxP)
    -- what is in each seat is known (the character at the wheel, the rest emptied above); the reach is vanilla's rule
    local busy = {}
    for i = 1, maxP - 1 do if v:isSeatOccupied(i) or not v:isSeatInstalled(i) then busy[#busy + 1] = i + 1 end end
    if staged(#busy == 0 and v:getSeat(p) == 0, "the character at the wheel, every other seat fitted and empty", "seat " .. tostring(v:getSeat(p)) .. ", busy or missing " .. table.concat(busy, ","), "seat 0, none") then
        local bad = {}
        for n, st in ipairs(w._seats or {}) do
            local i = n - 1
            local kind = (i == 0) and "you" or "empty"
            local far = (i ~= 0) and not v:canSwitchSeat(0, i)
            if st.kind ~= kind or (st.far == true) ~= far then bad[#bad + 1] = n .. ":" .. tostring(st.kind) .. "/" .. tostring(st.far) .. " want " .. kind .. "/" .. tostring(far) end
        end
        check(#bad == 0, "each seat reads as it is (you at the wheel, the rest empty), the ones vanilla's canSwitchSeat can't reach out of reach", table.concat(bad, "; "), "none off")
    end
    local farN
    for n, st in ipairs(w._seats or {}) do if st.far and st.kind == "empty" then farN = n end end
    if farN then
        local why = w:reason(w._seats[farN])
        check(why == getText("IGUI_VehicleSeat_ExitToSwitch"), "a seat out of reach gives vanilla's reason", why, getText("IGUI_VehicleSeat_ExitToSwitch"))
    else
        staged(false, "a seat out of reach from the wheel (every seat can be reached; the out-of-reach reason is not checked)", "none", "one")
    end
    check(w._doors and w._doors[1] ~= nil, "presence: the driver's door is offered to get out by", w._doors and w._doors[1] ~= nil, true)
    shot("9_seats")
    -- planks on a seat
    V.planks = {}
    if V.itemSeat then
        local c = v:getPartForSeatContainer(V.itemSeat):getItemContainer()
        for k = 1, 8 do V.planks[k] = c:AddItem("Base.Plank") end
    end
end, "car")
add(400, function()
    if not staged(V.itemSeat ~= nil, "a fitted seat besides the driver's to load", "none", "one") then return end
    local w, v = SE.get(pn), V.car
    local st = w._seats[V.itemSeat + 1]
    V.itemsRead = st ~= nil and st.kind == "items"
    if staged(v:isSeatOccupied(V.itemSeat), "eight planks make seat " .. (V.itemSeat + 1) .. " occupied for vanilla", false, true) then
        check(st ~= nil and st.kind == "items", "eight planks on seat " .. (V.itemSeat + 1) .. ": it reads as items", st and st.kind, "items")
        local mv = ISVehicleMenu.moveItemsFromSeat(p, v, V.itemSeat, false, false) and true or false
        local why = st and w:reason(st)
        local want = getText(mv and "IGUI_VehicleSeat_MoveItems" or "IGUI_VehicleSeat_Items")
        check(why == want, "its reason says whether the load can be moved, as vanilla's moveItemsFromSeat answers (" .. tostring(mv) .. ")", why, want)
    end
    for _, it in ipairs(V.planks) do pcall(function() it:getContainer():Remove(it) end) end
    V.planks = {}
end, "seats")
add(300, function()
    if V.itemSeat and V.itemsRead then
        local st = SE.get(pn)._seats[V.itemSeat + 1]
        check(st ~= nil and st.kind == "empty", "the planks off, seat " .. (V.itemSeat + 1) .. " reads empty again", st and st.kind, "empty")
    end
    SE.qaJoy = {}
    SE.get(pn).joypadSeat = 1
end, "seats")
add(250, function()
    local w = SE.get(pn)
    local cnt = V.car:getScript():getPassengerCount()
    local pr = w:getFooterPrompts()
    local glyphs = {}
    for k = 2, #(pr or {}) do glyphs[#glyphs + 1] = tostring(type(pr[k]) == "table" and pr[k].glyph) end
    check(pr ~= nil and #pr == 4 and table.concat(glyphs, ",") == "A,X,B", "presence: with a controller the help line offers Move, A Sit, X Get out here, B Cancel", pr and table.concat(glyphs, ","), "A,X,B")
    local seen = { w.joypadSeat }
    w:onJoypadDirRight(); seen[2] = w.joypadSeat
    w:onJoypadDirDown(); seen[3] = w.joypadSeat
    w:onJoypadDirLeft(); seen[4] = w.joypadSeat
    w:onJoypadDirUp(); seen[5] = w.joypadSeat
    -- vanilla's grid for a four-seat car: seats 1 2 over 3 4 (both sides written by table.concat, so they read alike)
    local walk = table.concat({ 1, 2, 4, 3, 1 }, ">")
    check(cnt == 4 and table.concat(seen, ">") == walk, "the D-pad walks vanilla's two-column seat grid: right, down, left, up from seat 1 (1 2 over 3 4)",
        cnt .. " seats: " .. table.concat(seen, ">"), "4 seats: " .. walk)
    SE.qaJoy = nil
end, "seats")
add(200, function()
    local w = SE.get(pn)
    clickRect(w, w._g.cancel)
end, "seats")
add(200, function()
    check(not visible(SE.get(pn)), "Cancel closes the chooser", visible(SE.get(pn)), false)
    ISVehicleMenu.onShowSeatUI(p, V.car)
end, "seats")
add(300, function()
    local took = SE.takeEscape()
    check(took == true and not visible(SE.get(pn)), "Escape closes it", tostring(took) .. "/" .. tostring(visible(SE.get(pn))), "true/false")
    if not visible(prop()) then wheelRadio() end   -- (the radio up close for the switch; the wheel toggles it, so only when away)
end, "seats")
add(400, function()
    V.radioUp = visible(prop())
    ISVehicleMenu.onShowSeatUI(p, V.car)
end, "seats")
add(300, function()
    local w = SE.get(pn)
    local to = V.to
    if not to then check(false, "a seat the driver can switch to (vanilla's canSwitchSeat)", "none", "one"); return end
    local g = w._g and w._g.seats[to + 1]
    if not g then check(false, "seat " .. (to + 1) .. " has a place on the car", "none", "a place"); V.to = nil; return end
    clickRect(w, g.hit)
    check(not visible(w), "a click on seat " .. (to + 1) .. " closes the chooser (vanilla acts on the press)", visible(w), false)
end, "seats")
waitUntil(10000, function() return V.to == nil or V.car:getSeat(p) == V.to end, "seats")
add(500, function()
    local to = V.to
    if not to then return end
    V.moved = V.car:getSeat(p) == to
    check(V.moved, "the character moved to seat " .. (to + 1) .. " (vanilla's switch)", V.car:getSeat(p), to)
    if V.moved and to > 1 then
        check(V.radioUp and not visible(prop()), "the radio is put away: it can't be reached from the back", tostring(V.radioUp) .. "/" .. tostring(visible(prop())), "true/false")
    elseif V.moved then
        check(V.radioUp and visible(prop()), "the radio stays up close from the seat beside the driver (vanilla: both front seats reach it)", tostring(V.radioUp) .. "/" .. tostring(visible(prop())), "true/true")
    end
    if not V.back then
        say("note: no back seat of this car can be reached from the wheel (the police car's cage: its script empties the front seats' switches to the back); the radio's back-seat rule is asked of ZeD's reach test with a stand-in occupant")
        local rp = part()
        local r0, r1, r2, r3 = reachFrom(0), reachFrom(1), reachFrom(2), reachFrom(3)
        check(rp ~= nil and r0 == rp and r1 == rp and r2 == nil and r3 == nil, "ZeD's reach test keeps vanilla's rule, front seats only: seats 1 and 2 reach the radio, 3 and 4 don't (a stand-in occupant)",
            tostring(r0 ~= nil) .. "/" .. tostring(r1 ~= nil) .. "/" .. tostring(r2 ~= nil) .. "/" .. tostring(r3 ~= nil), "true/true/false/false")
    end
    ISVehicleMenu.onShowSeatUI(p, V.car)
end, "seats")
add(300, function()
    if not (V.to and V.moved) then return end
    local w = SE.get(pn)
    local to = V.to
    check(w._seats[to + 1] and w._seats[to + 1].kind == "you", "reopened there, the chooser has you in seat " .. (to + 1), w._seats[to + 1] and w._seats[to + 1].kind, "you")
    w:onKeyRelease(Keyboard.KEY_1)   -- (the 1 key: the driver's seat)
end, "seats")
waitUntil(15000, function() return V.car:getSeat(p) == 0 end, "seats")
add(500, function()
    if V.to and V.moved then check(V.car:getSeat(p) == 0, "the 1 key takes the driver's seat again", V.car:getSeat(p), 0) end
    if not visible(prop()) then wheelRadio() end   -- (the radio up close again for the exit)
end, "seats")
add(400, function()
    V.radioUp = visible(prop())
    ISVehicleMenu.onShowSeatUI(p, V.car)
end, "seats")
add(300, function()
    local w = SE.get(pn)
    w:onJoypadDown(Joypad.XButton)   -- (X on your own seat: out by its door)
end, "seats")
waitUntil(15000, function() return p:getVehicle() == nil end, "seats")
add(1500, function()
    check(p:getVehicle() == nil, "X on your own seat gets you out (vanilla's exit, door and all)", p:getVehicle() ~= nil, false)
    check(V.radioUp and not visible(prop()), "leaving the car puts the radio away", "up before " .. tostring(V.radioUp) .. ", after " .. tostring(visible(prop())), "up before true, after false")
    ISVehicleMenu.onShowSeatUI(p, V.car)
end, "seats")
add(400, function()
    local w = SE.get(pn)
    check(visible(w) and w.title == getText("IGUI_EnterVehicle"), "from outside it is titled Enter Vehicle", w and w.title, getText("IGUI_EnterVehicle"))
    local doors, you = 0, false
    for _ in pairs(w and w._doors or {}) do doors = doors + 1 end
    for _, st in ipairs(w and w._seats or {}) do if st.kind == "you" then you = true end end
    check(doors == 0 and not you, "from outside: no door to leave by, no seat of yours", doors .. "/" .. tostring(you), "0/false")
    shot("10_seats_outside")
    SE.takeEscape()
end, "seats")

-- ===============================================================================================================
-- THE END: everything put back. These steps run whatever happened above; each put-back runs on its own, so one
-- that throws (an ERR line) leaves the rest to run. The stood-in readers and the exit come first.
-- ===============================================================================================================
local function try(what, fn)
    local ok, e = pcall(fn)
    if not ok then say("ERR putting back " .. what .. ": " .. tostring(e)) end
end
final(300, function()
    try("the held press", release)
    try("the Devices reader", function() if V.dsPinned then ZeD.Settings.devicesSimple = V.realDS; V.dsPinned = nil end end)
    try("the siren's Dashboard reader", function() if V.ssPinned then SI.simple = V.realSS; V.ssPinned = nil end end)
    try("the rod's drawing", function() if V.realRod then ZeD.FishRod.draw = V.realRod; V.realRod = nil end end)
    try("the clock's drawing", function() if V.realClock then ZeD.SleepClock.draw = V.realClock; V.realClock = nil end end)
    try("the radio's test hooks", function() if CR then CR.qaJoy, CR.qaPoint = V.qa0.crJ, V.qa0.crP end end)
    try("the siren's test hooks", function() if SI then SI.qaJoy, SI.qaPoint = V.qa0.siJ, V.qa0.siP end end)
    try("the chooser's test hooks", function() if SE then SE.qaJoy, SE.qaPoint = V.qa0.seJ, V.qa0.seP end end)
    -- out of the car: the queue dropped, the bar off, the exit
    try("the action queue", function() ISTimedActionQueue.clear(p) end)
    local v = nil
    pcall(function() v = p:getVehicle() end)
    if v then
        try("the lightbar", function()
            if v:hasLightbar() then
                sendClientCommand(p, "vehicle", "setLightbarLightsMode", { mode = 0 })
                sendClientCommand(p, "vehicle", "setLightbarSirenMode", { mode = 0 })
            end
        end)
        try("the seat (the exit)", function() v:exit(p); triggerEvent("OnExitVehicle", p) end)
    end
    -- the windows and the test panels
    try("the naming prompt", function()
        local pr = prop()
        local b = pr and promptFor(pr)
        if b then if b.answerCancel then b:answerCancel() else b:destroy() end end
    end)
    try("the CD list", closeList)
    try("the radio", function() if CR then CR.closeFor(pn) end end)
    try("the siren controller", function() if SI then SI.takeEscape() end end)
    try("the seat chooser", function() if SE then SE.takeEscape() end end)
    try("the tension meter", function() if V.tui then V.tui:setVisible(false); V.tui:removeFromUIManager(); V.tui = nil end end)
    try("the sleep panel", function() if V.sleep then V.sleep:setVisible(false); V.sleep:removeFromUIManager(); V.sleep = nil end end)
    -- the alarms: the given clocks off, the character's own back on
    if V.clock then try("the given clock's alarm", function() V.clock:setAlarmSet(false) end) end
    if V.clock2 then try("the bag's clock's alarm", function() V.clock2:setAlarmSet(false) end) end
    try("the character's alarms", restoreAlarms)
    try("the debug console", function() for _, e in ipairs(V.consoles) do e:setVisible(true) end; V.consoles = {} end)
end)
final(1500, function()
    -- the car, once the character is out of it (a car removed with someone in it takes the game down); still in: out
    -- again now, and the car goes in the next step
    V.later, V.carsGone = {}, 0
    for _, car in ipairs(V.spawned) do
        local inIt = false
        pcall(function() inIt = p:getVehicle() == car end)
        if inIt then
            try("the seat (the exit again)", function() car:exit(p); triggerEvent("OnExitVehicle", p) end)
            V.later[#V.later + 1] = car
        else
            try("the car", function() car:permanentlyRemove(); V.carsGone = V.carsGone + 1 end)
        end
    end
    V.spawned = {}
end)
final(1500, function()
    for _, car in ipairs(V.later or {}) do
        local inIt = true
        pcall(function() inIt = p:getVehicle() == car end)
        if inIt then say("ERR the character is still in the spawned car: it is left in place")
        else try("the car", function() car:permanentlyRemove(); V.carsGone = V.carsGone + 1 end) end
    end
    V.later = {}
    -- given items, newest first (the clock in the bag before the bag)
    local gone = 0
    for k = #V.given, 1, -1 do
        local it = V.given[k]
        try("a given item", function()
            local c = it:getContainer()
            if c then pcall(function() p:removeFromHands(it) end); c:Remove(it); gone = gone + 1 end
        end)
    end
    V.given = {}
    -- the planks, if their step stopped before taking them off
    for _, it in ipairs(V.planks) do try("a plank", function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    V.planks = {}
    -- the discs: any that is not one of the character's own (the ejected disc is a new item)
    if V.discIds0 then
        try("the discs", function()
            local list = p:getInventory():getAllTypeRecurse("Base.Disc_Retail")
            for i = list:size() - 1, 0, -1 do
                local it = list:get(i)
                if not V.discIds0[it:getID()] then
                    local c = it:getContainer()
                    if c then c:Remove(it); gone = gone + 1 end
                end
            end
        end)
    end
    try("god mode", function() p:setGodMod(V.god0 == true) end)
    if ZEDQA_HOME then try("the character's place", function() ZEDQA_HOME(TAG) end) end
    say("put back: " .. gone .. " items taken away, " .. tostring(V.carsGone or 0) .. " spawned car(s) removed, the readers, hooks, alarms and panels restored")
end)
final(300, function()
    say("RESULT " .. V.pass .. " pass, " .. V.fail .. " fail" .. ((V.skipped or 0) > 0 and (", " .. V.skipped .. " steps skipped (a section never came up)") or ""))
    say("DONE")
    if V.unpaused then
        pcall(function() Events.OnTick.Remove(drive) end)
        pcall(function() setGameSpeed(0) end)
    end
end)

-- ---------------------------------------------------------------------------------------------------------------
-- THE DRIVER
-- ---------------------------------------------------------------------------------------------------------------
local Dv = { i = 1, t0 = nil }
drive = function()
    local st = PLAN[Dv.i]
    if not st then Events.OnTick.Remove(drive); return end
    local now = getTimestampMs()
    Dv.t0 = Dv.t0 or now
    if st.need and not V.ok[st.need] then
        -- a section that never came up: one FAIL for it, then its steps are skipped
        V.skipped = (V.skipped or 0) + 1
        if not V.skipSec[st.need] then
            V.skipSec[st.need] = true
            check(false, "the " .. st.need .. " section came up (its steps are skipped)", "it never came up", "up")
        end
        Dv.i = Dv.i + 1
        return
    end
    if st.wait then
        local ok, done = pcall(st.fn)
        if not ok then say("ERR wait " .. Dv.i .. ": " .. tostring(done)); done = true end
        if not done and now - Dv.t0 >= st.ms then
            done = true
            if st.onTimeout then
                local okT, eT = pcall(st.onTimeout)
                if not okT then say("ERR after the wait " .. Dv.i .. ": " .. tostring(eT)) end
            end
        end
        if done then Dv.i = Dv.i + 1; Dv.t0 = now end
        return
    end
    if now - Dv.t0 < st.ms then return end
    Dv.i = Dv.i + 1
    Dv.t0 = now
    local ok, e = pcall(st.fn)
    if not ok then
        V.fail = V.fail + 1
        say("ERR step " .. (Dv.i - 1) .. ": " .. tostring(e))
    end
end
Events.OnTick.Add(drive)
say("start")
