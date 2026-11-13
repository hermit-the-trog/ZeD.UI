-- ZeDUI/tools/qa/zedqa_cov_vehicles.lua  (Nov 12 2026, QA coverage: AUDIT_DESIGN_AND_COVERAGE_20261111.md Table B, vehicles)
-- In game on the ZeD-QA save only (Saves/Sandbox/ZeD-QA), the character on the Irvington drag strip (the prelude's
-- ZEDQA_HOME). Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go, grep console.txt for "ZEDQA cov_vehicles"; runner manifest
-- cov_vehicles.txt. Each check prints "PASS <what>" or "FAIL <what> (<got> vs <want>)" from values read off ZeD's own
-- objects and the game's (the panels' click areas and fields, the radio's device data, the car's lightbar modes and
-- seats); it ends with RESULT and DONE. Screenshots: Zomboid/Screenshots/zqa_covveh_*.png, each on a SHOT line.
--
-- WHAT IT CHECKS
--   Rod and clock-radio plates (ZeD.FishRod.draw, ZeD.SleepClock.draw) on a recording canvas: all 17 rod frames have a
--     plate and anchors; tension picks the frame; the line runs hot from 0.9, MAX lights from 0.85, the dial's pointer
--     sits low when slack and in the red at the limit; the clock lights each digit's seven segments (10:46 PM, 9:05 AM
--     with the leading zero blank, 12:30 AM, 12:00 PM), the AM / PM dot, the ALARM lamp only when asked, whole multiples.
--   Fishing rod prop (Overrides/Fishing.lua on vanilla's Fishing.ISTensionUI): hooked; updateValue keeps the raw tension
--     beside vanilla's angle; render draws the rod with it at the screen's whole multiple, low and near the middle.
--   Sleep clock (Overrides/Sleeping.lua on ISSleepingUI): hooked; render draws the clock at the panel's hour, centred, at
--     the whole multiple; the ALARM lamp follows an alarm clock carried (in the inventory, in a bag) and goes back off.
--   Car radio up close (ZeD_CarRadio.lua, Overrides/CarRadio.lua) in a police car spawned beside the character: the
--     wheel's Device Options opens it, not vanilla's window; every plate and design (RadioPlates.lua) control is a live
--     click area at the dash's multiple; it stands above the dash. Through the mouse handlers: VOL powers it, the glass
--     reads FM and the frequency, TUNE's halves step, a held preset stores (STORE flash), a short press recalls, an empty
--     one flashes EMPTY, MUTE and back, SEEK lands on vanilla's next station, SCAN on and off. Controller: A's prompt,
--     up turns VOL, right moves right, B puts it away.
--   CD deck: no CD -> a greyed "No CDs" row; a row per CD in ZeD's menu; Escape closes the list before the radio; picking
--     inserts (vanilla's action), PLAY plays (CD time on the glass), PLAY again stops at once, EJECT gives the disc back.
--   Plain card (Devices: Simple): the card replaces the face, its power switch works, back to the face.
--   Two-way (ham set): the ham face, first stop CH up, MEM stores, CH up / down step and wrap both ways (01 -> last),
--     MIC (MIC OFF on the glass), a held MEM names a channel; an empty name keeps OK live and forgets it.
--   Siren controller (ZeD_SirenController.lua, SirenPlate.lua, the lightbar hook): the Lightbar slice opens it (not
--     ISLightbarUI) and puts the radio away; its ten click areas are the plate's; clicks and the controller set the car's
--     lightbar modes through vanilla's commands (stops at ALARM, A wraps); the plain card works; the slice closes it.
--   Seat chooser (ZeD_SeatChooser.lua, the seat hook): Switch Seat opens it (not ISVehicleSeatUI); each seat's kind and
--     reach match vanilla's rules, with vanilla's reason; planks read as vanilla's occupied and move tests say; the
--     controller's prompts and seat grid; Cancel and Escape close it; a click moves the character to a back seat (the
--     radio goes away), the 1 key brings it back, X gets out by the door (the radio goes away); from outside: Enter
--     Vehicle, no door, no seat of yours.
-- THE LEDGER: given items, the CD count, the spawned car (removed once the character is out), stubbed readers, the qaJoy /
-- qaPoint hooks, the test panels and god mode are put back at the end, and at once on an error. It enters no car but the
-- one it spawned, and that one only after it settled (square, chunk, physics seen, 1.5 s held: zedqa_dash_keys_edge.lua).

local TAG = "cov_vehicles"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if ZEDQA_HOME then ZEDQA_HOME(TAG) end   -- (open ground: an earlier script can leave the character indoors)
local p = getPlayer()
local pn = p:getPlayerNum()
local CR, RO, SI, SE = ZeD.CarRadio, ZeD.RadioOps, ZeD.Siren, ZeD.Seats
-- the run's state: counts, what was given / spawned / stubbed, which sections came up (gates for the steps)
local V = { pass = 0, fail = 0, given = {}, spawned = {}, ok = {}, stage = { tries = 0, phys = false, since = nil, why = "" } }
pcall(function() V.god0 = p:isGodMod() end)

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

-- a stand-in panel that records what a plate's draw function asks of it
local function canvas()
    local c = { rects = {}, texs = {} }
    c.drawRect = function(self, x, y, w, h, a, r, g, b) self.rects[#self.rects + 1] = { x = x, y = y, w = w, h = h, a = a, r = r, g = g, b = b } end
    c.drawTextureScaledAspect = function(self, t, x, y, w, h) self.texs[#self.texs + 1] = { t = t, x = x, y = y, w = w, h = h } end
    return c
end
local function sameColor(q, col) return math.abs(q.r - col[1]) < 0.002 and math.abs(q.g - col[2]) < 0.002 and math.abs(q.b - col[3]) < 0.002 end
-- rects of a colour (and alpha, when given) on a canvas; inside a box (x0, y0, w, h) when given
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
local function prop() return CR.props[pn] end

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
-- a press and release on a click area, through the panel's own mouse handlers (fx: where across it, 0..1)
local function click(panel, id, fx)
    local h = hitOf(panel, id)
    if not h then return false end
    local x, y = h.x + math.floor(h.w * (fx or 0.5)), h.y + math.floor(h.h / 2)
    panel:onMouseDown(x, y)
    panel:onMouseUp(x, y)
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
local function clickRect(panel, r)
    local x, y = r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2)
    panel:onMouseDown(x, y)
    panel:onMouseUp(x, y)
end

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
-- the naming prompt a radio opened (ZeD's prompt or vanilla's ISTextBox: both keep target, entry and yes)
local function promptFor(target)
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
    if not (d and d:isVisible() and d._consoleRect) then say("note: no dash under the " .. what .. "; its place on the dash is not checked"); return end
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
local function closeList()
    local pr = prop()
    pcall(function() local m = pr and pr:openList(); if m then m:close() end end)
    pcall(function() local c = pr and pr._list; if c and c:isReallyVisible() then c:closeAll() end end)
end
local function modes() local v = V.car; return v:getLightbarLightsMode(), v:getLightbarSirenMode() end

-- ---------------------------------------------------------------------------------------------------------------
-- THE CAR: a police car (lightbar, radio part, four seats) on a free square beside the character, seated only once it
-- has a square and a chunk, its physics seen once and all held 1.5 s (zedqa_dash_keys_edge.lua's staging)
-- ---------------------------------------------------------------------------------------------------------------
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 }, { 6, 6 }, { -6, 0 } }
local function spawnCar()
    local S = V.stage
    while S.tries < #OFFS do
        S.tries = S.tries + 1
        local o = OFFS[S.tries]
        local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], math.floor(p:getZ()))
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if sq and free then
            local ok, v = pcall(addVehicleDebug, "Base.CarLightsPolice", IsoDirections.N, nil, sq)
            if ZEDQA_VPROBE then ZEDQA_VPROBE(TAG, sq, ok and v or nil) end
            if ok and v then
                V.car = v
                V.spawned[#V.spawned + 1] = v
                S.phys, S.since = false, nil
                return true
            end
        end
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
-- pass. need = the section a step depends on (V.ok[need]); a step whose section never came up is skipped. The final
-- steps always run.
-- ---------------------------------------------------------------------------------------------------------------
local PLAN = {}
local function add(ms, fn, need) PLAN[#PLAN + 1] = { ms = ms, fn = fn, need = need } end
local function waitUntil(ms, test, need, onTimeout) PLAN[#PLAN + 1] = { wait = true, ms = ms, fn = test, need = need, onTimeout = onTimeout } end
local function final(ms, fn) PLAN[#PLAN + 1] = { ms = ms, fn = fn, final = true } end

-- ===============================================================================================================
-- 0. SETUP
-- ===============================================================================================================
add(100, function()
    local u = UIManager.getUI()
    for i = 0, u:size() - 1 do local e = u:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    if getGameSpeed and getGameSpeed() == 0 and setGameSpeed then setGameSpeed(1) end
    p:setGodMod(true)
    local safe = ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() or false
    check(not safe, "ZeD's safe mode is off (with it on every hook below hands over to vanilla)", safe, false)
    local hooked = ISVehicleMenu._zedRadio ~= nil and ISVehicleMenu._zedSeats ~= nil and ISLightbarUITimedAction ~= nil and ISLightbarUITimedAction._zedSiren ~= nil
    check(hooked, "the vehicle wheel's hooks are in: Device Options, Switch Seat, Lightbar", hooked, true)
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
-- the rod's pointer tip on a canvas: the NEEDLE square farthest from the dial's centre
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
    check(F ~= nil and ZeD.SleepClock ~= nil, "the rod and clock-radio plates are loaded (ZeD.FishRod, ZeD.SleepClock)", tostring(F ~= nil) .. "/" .. tostring(ZeD.SleepClock ~= nil), "true/true")
    if not F then return end
    local miss = {}
    for i = 0, F.FRAMES do if not (rodFrame(i) and F.ANCH[i + 1]) then miss[#miss + 1] = i end end
    check(#miss == 0 and #F.ANCH == F.FRAMES + 1, "all " .. (F.FRAMES + 1) .. " rod frames have a plate and anchors", "missing " .. table.concat(miss, ","), "none")
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
    -- the line, MAX and the pointer
    local cv5, cv87, cv95 = canvas(), canvas(), canvas()
    F.draw(cv5, 0, 0, 1, 0.5); F.draw(cv87, 0, 0, 1, 0.87); F.draw(cv95, 0, 0, 1, 0.95)
    check(countColor(cv5, LINE) > 0 and countColor(cv5, LINE_HOT) == 0 and countColor(cv87, LINE_HOT) == 0 and countColor(cv95, LINE_HOT) > 0,
        "the line is pale under load and runs hot from 0.9", "hot at 0.5/0.87/0.95: " .. countColor(cv5, LINE_HOT) .. "/" .. countColor(cv87, LINE_HOT) .. "/" .. countColor(cv95, LINE_HOT), "0/0/>0")
    check(countColor(cv5, MAXC, 0.45) == 0 and countColor(cv87, MAXC, 0.45) == 1 and countColor(cv95, MAXC, 0.45) == 1,
        "MAX lights from 0.85", countColor(cv5, MAXC, 0.45) .. "/" .. countColor(cv87, MAXC, 0.45) .. "/" .. countColor(cv95, MAXC, 0.45), "0/1/1")
    local cvS, cvL = canvas(), canvas()
    F.draw(cvS, 0, 0, 1, -0.5); F.draw(cvL, 0, 0, 1, 1.0)
    local dS, dL = F.ANCH[1].dial, F.ANCH[F.FRAMES + 1].dial
    local tS, tL = needleTip(cvS, dS), needleTip(cvL, dL)
    check(tS ~= nil and tL ~= nil and tS.x < dS[1] and tS.y > dS[2] and tL.x > dL[1], "the dial's pointer sits low on the left when slack and in the red at the limit",
        tS and tL and ("slack " .. tostring(tS.x) .. "," .. tostring(tS.y) .. " limit " .. tostring(tL.x) .. "," .. tostring(tL.y)),
        "left of " .. tostring(dS[1]) .. " below " .. tostring(dS[2]) .. ", right of " .. tostring(dL[1]))
    -- whole multiples
    local cv2 = canvas()
    F.draw(cv2, 0, 0, 2, 0.5)
    check(cv2.texs[1] and cv2.texs[1].w == F.W * 2 and cv2.texs[1].h == F.H * 2, "the rod plate draws at whole multiples (2x: " .. (F.W * 2) .. " x " .. (F.H * 2) .. ")",
        cv2.texs[1] and (cv2.texs[1].w .. " x " .. cv2.texs[1].h), (F.W * 2) .. " x " .. (F.H * 2))
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
    check(hooked, "vanilla's tension meter is hooked (render, updateValue)", hooked, true)
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
    local kWant = math.max(1, math.floor(2 * root() + 0.001))
    check(r.k == kWant, "the rod is drawn at this screen's whole multiple", r.k, kWant)
    local x, y, w, h = r.ax + r.ox, r.ay + r.oy, ZeD.FishRod.W * r.k, ZeD.FishRod.H * r.k
    local sl, st, sw, sh = getPlayerScreenLeft(pn), getPlayerScreenTop(pn), getPlayerScreenWidth(pn), getPlayerScreenHeight(pn)
    check(x >= sl and x + w <= sl + sw and y + h <= st + sh and y >= st + sh / 2 - h and math.abs(x + w / 2 - (sl + sw / 2)) <= 42 * root() + 2,
        "the rod stands at the bottom middle of the player's screen", tostring(x) .. "," .. tostring(y) .. " " .. tostring(w) .. "x" .. tostring(h),
        "inside " .. tostring(sl) .. "," .. tostring(st) .. " " .. tostring(sw) .. "x" .. tostring(sh) .. ", low, centred")
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
    check(ISSleepingUI ~= nil and ISSleepingUI._zedOrigRender ~= nil and ISSleepingUI.render ~= ISSleepingUI._zedOrigRender, "vanilla's sleep panel is hooked (render)",
        ISSleepingUI and tostring(ISSleepingUI.render ~= ISSleepingUI._zedOrigRender), true)
    if not ISSleepingUI then return end
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
    local kWant = math.max(1, math.floor(3 * root() + 0.001))
    check(r.k == kWant, "the clock is drawn at this screen's whole multiple", r.k, kWant)
    local cx = r.ax + r.ox + ZeD.SleepClock.W * r.k / 2
    local want = getPlayerScreenLeft(pn) + getPlayerScreenWidth(pn) / 2
    check(math.abs(cx - want) <= 1, "the clock stands in the middle of the player's screen", cx, want)
    V.alarm0 = r.alarm == true
    shot("2_sleep_clock")
    V.clock = give("Base.AlarmClock2")
    V.clock:setAlarmSet(true)
    V.sleep.hourOfDay = 6 + 58 / 60
    V.sleep._zedAlarmAt = nil; V.clockRec = nil
end, "sleep")
add(300, function()
    local r = V.clockRec
    check(r ~= nil and r.alarm == true and near(r.hour, 6 + 58 / 60, 1e-6), "an alarm clock carried with its alarm set lights ALARM; the hour follows the panel",
        r and (tostring(r.alarm) .. " " .. tostring(r.hour)), "true 6.97")
    V.clock:setAlarmSet(false)
    V.sleep._zedAlarmAt = nil; V.clockRec = nil
end, "sleep")
add(300, function()
    local r = V.clockRec
    check(r ~= nil and (r.alarm == true) == V.alarm0, "its alarm switched off, the lamp goes back as it was", r and r.alarm, V.alarm0)
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
end, "sleep")

-- ===============================================================================================================
-- 4. THE CAR: spawned beside the character, settled, then repaired, fuelled, keyed and seated in one tick
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
    check(#want > 0 and m1 == "" and m2 == "", "every control of the plate and of the radio's design (RadioPlates.lua) is a live click area", "missing " .. m1 .. " | " .. m2, "none")
    local h, ph = hitOf(pr, "vol"), nil
    for _, q in ipairs(des and des.hits or {}) do if q.id == "vol" then ph = q end end
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance(pn)
    local dashK = d and d._s or nil
    local onPlate = h ~= nil and ph ~= nil and h.x == ph.x * pr._s and h.w == ph.w * pr._s and (dashK == nil or pr._s == dashK)
    check(onPlate, "the face's click areas sit on the plate at the dash's whole multiple",
        "vol x " .. tostring(h and h.x) .. " at " .. tostring(pr._s), "plate x " .. tostring(ph and ph.x) .. " times " .. tostring(dashK or pr._s))
    onDash(pr, "radio")
    shot("3_radio_premium")
    V.on0 = dd():getIsTurnedOn()
    click(pr, "vol")
end, "car")
add(300, function()
    local on1 = dd():getIsTurnedOn()
    check(on1 ~= V.on0, "a press on VOL switches the set " .. (V.on0 and "off" or "on"), on1, not V.on0)
    if not on1 then click(prop(), "vol") end
end, "radio")
add(300, function()
    local st = rd()
    check(st.on, "the radio is on, powered from the car's battery", tostring(st.switchOn) .. "/" .. tostring(st.powered), "true/true")
    local r = RO.displayReading(st)
    check(r ~= nil and r.band == "FM" and r.big == RO.freqText(st.channel, false), "the glass reads FM and the frequency", r and (tostring(r.band) .. " " .. tostring(r.big)), "FM " .. RO.freqText(st.channel, false))
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
    if rd().channel == V.chS then say("note: TUNE did not move off the stored station; the recall below proves less") end
    click(prop(), "p" .. V.storeIdx)
end, "radio")
add(250, function()
    local st = rd()
    check(st.channel == V.chS, "a short press on P" .. V.storeIdx .. " tunes back to the station stored there", st.channel, V.chS)
    V.chE = st.channel
    if #st.presets < 6 then click(prop(), "p6") end
end, "radio")
add(250, function()
    local st = rd()
    if #st.presets < 6 then
        check(st.flash == ZeD.tr("UI_ZeD_Radio_Empty") and st.channel == V.chE, "a press on an empty preset flashes EMPTY and keeps the station", tostring(st.flash) .. " " .. st.channel, ZeD.tr("UI_ZeD_Radio_Empty") .. " " .. V.chE)
    else
        say("note: all six presets are stored; the empty-preset press is not checked")
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
    V.seekWant = RO.nextStation(dd(), 1)
    V.chB = rd().channel
    click(prop(), "seek")
end, "radio")
add(250, function()
    local want = V.seekWant or V.chB
    check(rd().channel == want, "SEEK tunes to the next station vanilla broadcasts on", rd().channel, want)
    click(prop(), "scan")
end, "radio")
add(250, function()
    check(rd().scanning == (V.seekWant ~= nil), "SCAN starts scanning the stations", rd().scanning, V.seekWant ~= nil)
    if rd().scanning then click(prop(), "scan") end
end, "radio")
add(250, function()
    check(not rd().scanning, "SCAN again stops it", rd().scanning, false)
    -- the controller (the radio's qa hook stands in for a pad holding it)
    CR.qaJoy = {}
    prop().focusId = "vol"
    RO.run("SetVolume", p, part(), 0.5)
end, "radio")
add(300, function()
    local pr = prop()
    check(pr.joyfocus ~= nil and pr:labelA() == ZeD.tr("IGUI_RadioPower"), "with a controller on VOL the strip offers A: Power", pr:labelA(), ZeD.tr("IGUI_RadioPower"))
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
    V.cds0 = #RO.cds(p, part())
    V.discs0 = p:getInventory():getCountTypeRecurse("Base.Disc_Retail")
    if V.cds0 == 0 then click(prop(), "slot") end
end, "radio")
add(400, function()
    if V.cds0 == 0 then
        local ctx = prop()._list
        local n = ctx and (ctx.numOptions - 1)
        local o = ctx and ctx.options[1]
        check(n == 1 and o ~= nil and o.notAvailable == true and o.name == ZeD.tr("UI_ZeD_Radio_NoCds"), "with no CD carried, the slot's list says so, greyed",
            tostring(n) .. " " .. tostring(o and o.name), "1 " .. ZeD.tr("UI_ZeD_Radio_NoCds"))
        closeList()
    else
        say("note: the character carries " .. V.cds0 .. " CDs already; the empty list is not checked")
    end
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
    local ctx = pr._list
    local n = ctx and (ctx.numOptions - 1)
    check(n == #RO.cds(p, part()), "the slot's list has a row per CD carried", n, #RO.cds(p, part()))
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
    check(opt ~= nil, "the CD's row is in the list", opt ~= nil, true)
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
add(200, function()
    V.realDS = ZeD.Settings.devicesSimple
    ZeD.Settings.devicesSimple = function() return true end
end, "radio")
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
    ZeD.Settings.devicesSimple = V.realDS
    V.realDS = nil
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
    check(m1 == "" and m2 == "", "every control of the ham plate and its design is a live click area", "missing " .. m1 .. " | " .. m2, "none")
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
    -- down from 01: round to the last (ZeD_RadioOps.chStep)
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
    check(#s._hits == #want and missing(want, idSet(s._hits)) == "", "its click areas are the plate's ten (two knobs, eight positions)", #s._hits, #want)
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
add(200, function()
    V.realSS = SI.simple
    SI.simple = function() return true end
end, "siren")
add(300, function()
    local s = SI.get(pn)
    local want = {}
    for _, h in ipairs(ZeD.PhysPx.plates.siren.hits) do want[#want + 1] = h.id end
    check(s._plainOn == true and #s._hits == 10 and missing(want, idSet(s._hits)) == "", "the simple dash draws the controller as a plain card with the same ten switches",
        tostring(s._plainOn) .. " " .. #s._hits, "true 10")
    shot("8_siren_plain")
    click(s, "lights:3")
end, "siren")
add(300, function()
    local l = modes()
    check(l == 3, "the plain card's LIGHTS 3 sets the lights to 3", l, 3)
    click(SI.get(pn), "lights:0")
    SI.simple = V.realSS
    V.realSS = nil
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
    V.sw = {}   -- the seats the driver can switch to, fitted and empty
    for i = 1, v:getMaxPassengers() - 1 do
        if v:isSeatInstalled(i) and not v:isSeatOccupied(i) and v:canSwitchSeat(0, i) then V.sw[#V.sw + 1] = i end
    end
    ISVehicleMenu.onShowSeatUI(p, v)
end, "car")
add(400, function()
    local w, v = SE.get(pn), V.car
    V.ok.seats = visible(w)
    check(V.ok.seats, "the wheel's Switch Seat brings up ZeD's seat chooser", visible(w), true)
    check(not vanillaSeatsUp(), "vanilla's seat window stays shut", vanillaSeatsUp(), false)
    if not V.ok.seats then return end
    check(w.title == getText("IGUI_SwitchSeat"), "seated, it is titled Switch Seat", w.title, getText("IGUI_SwitchSeat"))
    check(#(w._seats or {}) == v:getMaxPassengers(), "a place for every seat", #(w._seats or {}), v:getMaxPassengers())
    local bad = {}
    for n, st in ipairs(w._seats or {}) do
        local i = n - 1
        local who = v:getCharacter(i)
        local kind
        if who then kind = (who == p) and "you" or "person"
        elseif v:isSeatOccupied(i) then kind = "items"
        else
            local pt = v:getPartForSeatContainer(i)
            kind = (pt and not pt:getInventoryItem()) and "none" or "empty"
        end
        local far = (i ~= 0) and not v:canSwitchSeat(0, i)
        if st.kind ~= kind or (st.far == true) ~= far then bad[#bad + 1] = n .. ":" .. tostring(st.kind) .. "/" .. tostring(st.far) .. " want " .. kind .. "/" .. tostring(far) end
    end
    check(#bad == 0, "each seat reads as vanilla's rules say (who sits there, which the driver can reach)", table.concat(bad, "; "), "none off")
    local farN
    for n, st in ipairs(w._seats or {}) do if st.far and st.kind == "empty" then farN = n end end
    if farN then
        local why = w:reason(w._seats[farN])
        check(why == getText("IGUI_VehicleSeat_ExitToSwitch"), "a seat out of reach gives vanilla's reason", why, getText("IGUI_VehicleSeat_ExitToSwitch"))
    else
        say("note: every seat of this car can be reached from the wheel; the out-of-reach reason is not checked")
    end
    check(w._doors and w._doors[1] ~= nil, "the driver's door is offered to get out by", w._doors and w._doors[1] ~= nil, true)
    shot("9_seats")
    -- planks on a seat
    V.itemSeat = V.sw[2] or V.sw[1]
    V.planks = {}
    if V.itemSeat then
        local c = v:getPartForSeatContainer(V.itemSeat):getItemContainer()
        for k = 1, 8 do V.planks[k] = c:AddItem("Base.Plank") end
    end
end, "car")
add(400, function()
    if not V.itemSeat then say("note: no seat to load"); return end
    local w, v = SE.get(pn), V.car
    local st = w._seats[V.itemSeat + 1]
    local occ = v:isSeatOccupied(V.itemSeat)
    local want = occ and "items" or "empty"
    check(st.kind == want, "eight planks on seat " .. (V.itemSeat + 1) .. ": it reads as vanilla's occupied test says (" .. want .. ")", st.kind, want)
    if occ then
        local mv = ISVehicleMenu.moveItemsFromSeat(p, v, V.itemSeat, false, false) and true or false
        check(st.movable == mv, "and whether its load can be moved, as vanilla works it out", st.movable, mv)
    end
    for _, it in ipairs(V.planks) do pcall(function() it:getContainer():Remove(it) end) end
    V.planks = {}
end, "seats")
add(300, function()
    if V.itemSeat and SE.get(pn)._seats[V.itemSeat + 1].kind == "items" then say("note: seat " .. (V.itemSeat + 1) .. " still reads items after the planks came off") end
    SE.qaJoy = {}
    SE.get(pn).joypadSeat = 1
end, "seats")
add(250, function()
    local w = SE.get(pn)
    local cnt = V.car:getScript():getPassengerCount()
    local pr = w:getFooterPrompts()
    check(pr ~= nil and #pr == 4, "with a controller the help line offers Move, A Sit, X Get out here, B Cancel", pr and #pr, 4)
    local seen = { w.joypadSeat }
    w:onJoypadDirRight(); seen[2] = w.joypadSeat
    w:onJoypadDirDown(); seen[3] = w.joypadSeat
    w:onJoypadDirLeft(); seen[4] = w.joypadSeat
    w:onJoypadDirUp(); seen[5] = w.joypadSeat
    -- vanilla's grid: two columns, odd seats left; up / down a row of two
    local want = { 1 }
    want[2] = (cnt >= 2) and 2 or 1
    want[3] = (want[2] <= cnt - 2) and want[2] + 2 or want[2]
    want[4] = (want[3] % 2 == 0) and want[3] - 1 or want[3]
    want[5] = (want[4] > 2) and want[4] - 2 or want[4]
    check(table.concat(seen, ">") == table.concat(want, ">"), "the D-pad walks vanilla's two-column seat grid (right, down, left, up)", table.concat(seen, ">"), table.concat(want, ">"))
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
    wheelRadio()   -- (the radio up close: from the back it can't be reached)
end, "seats")
add(400, function()
    V.radioUp = visible(prop())
    ISVehicleMenu.onShowSeatUI(p, V.car)
end, "seats")
add(300, function()
    local w = SE.get(pn)
    local to = V.sw[1]
    if not to then check(false, "a seat the driver can switch to", "none", "one"); return end
    local g = w._g and w._g.seats[to + 1]
    if not g then check(false, "seat " .. (to + 1) .. " has a place on the car", "none", "a place"); return end
    clickRect(w, g.hit)
    check(not visible(w), "a click on seat " .. (to + 1) .. " closes the chooser (vanilla acts on the press)", visible(w), false)
end, "seats")
waitUntil(10000, function() return V.sw[1] == nil or V.car:getSeat(p) == V.sw[1] end, "seats")
add(500, function()
    local to = V.sw[1]
    if not to then return end
    check(V.car:getSeat(p) == to, "the character moved to seat " .. (to + 1) .. " (vanilla's switch)", V.car:getSeat(p), to)
    if to > 1 then check(V.radioUp and not visible(prop()), "the radio is put away: it can't be reached from the back", tostring(V.radioUp) .. "/" .. tostring(visible(prop())), "true/false") end
    ISVehicleMenu.onShowSeatUI(p, V.car)
end, "seats")
add(300, function()
    local w = SE.get(pn)
    local to = V.sw[1]
    if not to then return end
    check(w._seats[to + 1] and w._seats[to + 1].kind == "you", "reopened there, the chooser has you in seat " .. (to + 1), w._seats[to + 1] and w._seats[to + 1].kind, "you")
    w:onKeyRelease(Keyboard.KEY_1)   -- (the 1 key: the driver's seat)
end, "seats")
waitUntil(15000, function() return V.car:getSeat(p) == 0 end, "seats")
add(500, function()
    check(V.car:getSeat(p) == 0, "the 1 key takes the driver's seat again", V.car:getSeat(p), 0)
    wheelRadio()
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
    check(V.radioUp and not visible(prop()), "leaving the car puts the radio away", tostring(V.radioUp) .. "/" .. tostring(visible(prop())), "true/false")
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
-- THE END: everything put back (these steps run whatever happened above)
-- ===============================================================================================================
final(300, function()
    release()
    CR.qaJoy, CR.qaPoint, SI.qaJoy, SI.qaPoint, SE.qaJoy, SE.qaPoint = nil, nil, nil, nil, nil, nil
    if V.realDS then ZeD.Settings.devicesSimple = V.realDS; V.realDS = nil end
    if V.realSS then SI.simple = V.realSS; V.realSS = nil end
    if V.realRod then ZeD.FishRod.draw = V.realRod; V.realRod = nil end
    if V.realClock then ZeD.SleepClock.draw = V.realClock; V.realClock = nil end
    pcall(function() if V.tui then V.tui:setVisible(false); V.tui:removeFromUIManager(); V.tui = nil end end)
    pcall(function() if V.sleep then V.sleep:setVisible(false); V.sleep:removeFromUIManager(); V.sleep = nil end end)
    pcall(function() local b = promptFor(prop()); if b then if b.answerCancel then b:answerCancel() else b:destroy() end end end)
    closeList()
    pcall(function() CR.closeFor(pn) end)
    pcall(function() SI.takeEscape() end)
    pcall(function() SE.takeEscape() end)
    pcall(function() ISTimedActionQueue.clear(p) end)
    local v = p:getVehicle()
    if v then
        pcall(function()
            if v:hasLightbar() then
                sendClientCommand(p, "vehicle", "setLightbarLightsMode", { mode = 0 })
                sendClientCommand(p, "vehicle", "setLightbarSirenMode", { mode = 0 })
            end
        end)
        pcall(function() v:exit(p) end)
        triggerEvent("OnExitVehicle", p)
    end
    for _, it in ipairs({ V.clock, V.clock2 }) do pcall(function() it:setAlarmSet(false) end) end
end)
final(1500, function()
    -- the car, once the character is out of it (a car removed with someone in it takes the game down)
    local left = 0
    for _, car in ipairs(V.spawned) do
        if p:getVehicle() ~= car then pcall(function() car:permanentlyRemove() end) else left = left + 1 end
    end
    if left > 0 then say("note: the character is still in the spawned car: it is left in place") end
    V.spawned = {}
    -- given items, newest first (the clock in the bag before the bag)
    local gone = 0
    for k = #V.given, 1, -1 do
        local it = V.given[k]
        pcall(function()
            local c = it:getContainer()
            if c then pcall(function() p:removeFromHands(it) end); c:Remove(it); gone = gone + 1 end
        end)
    end
    V.given = {}
    -- the disc count as it was (the ejected disc is a new item)
    if V.discs0 then
        pcall(function()
            local list = p:getInventory():getAllTypeRecurse("Base.Disc_Retail")
            local k = list:size() - 1
            while k >= 0 and p:getInventory():getCountTypeRecurse("Base.Disc_Retail") > V.discs0 do
                local it = list:get(k)
                local c = it:getContainer()
                if c then c:Remove(it); gone = gone + 1 end
                k = k - 1
            end
        end)
    end
    pcall(function() p:setGodMod(V.god0 == true) end)
    if ZEDQA_HOME then ZEDQA_HOME(TAG) end
    say("put back: " .. gone .. " items taken away, the car removed, the readers and panels restored")
end)
final(300, function()
    say("RESULT " .. V.pass .. " pass, " .. V.fail .. " fail" .. ((V.skipped or 0) > 0 and (", " .. V.skipped .. " steps skipped (a section never came up)") or ""))
    say("DONE")
end)

-- ---------------------------------------------------------------------------------------------------------------
-- THE DRIVER
-- ---------------------------------------------------------------------------------------------------------------
local Dv = { i = 1, t0 = nil }
local function drive()
    local st = PLAN[Dv.i]
    if not st then Events.OnTick.Remove(drive); return end
    local now = getTimestampMs()
    Dv.t0 = Dv.t0 or now
    if st.need and not V.ok[st.need] then
        V.skipped = (V.skipped or 0) + 1
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
