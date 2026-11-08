-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/VSKDash.lua
-- ============================================================================
-- SUPPORT FOR VEHICLE KIT LIBRARY'S DASHBOARD DATA (mod id VehicleSwissKnife,
-- Workshop 3828607335, namespace VSK). Client. Roadworthy (RealisticDrivingOverhaul,
-- Workshop 3828608843) publishes its engine temperature, oil pressure, lamps,
-- odometer and gearbox there, and any other mod built on the library can.
--
-- The library's mods publish and never draw: VSK.Dashboard.register. The library
-- draws what they publish in or above the game's own dash, which ZeD parks
-- (setVisible(false)), so the library sees no dash, reads nothing and shows
-- nothing. ZeD reads the same list through the library's own poll, at the
-- library's own rate, and hands ZeD_Dashboard.lua one small table each frame:
--
--   pub.temp, pub.oil   the needles, 0..1 (the gauges with role "temp" / "oil";
--                       the first in the library's order, as its own needle)
--   pub.lamps[src]      the worst lit lamp for one of the plate's lamps:
--                       { rank (2 amber, 3 red, under that a lit indicator),
--                       blink, name }; a dark lamp is not here, so the plate's
--                       own reading stands
--   pub.list            every lamp this car has published, in the order seen,
--                       kept once seen so the simple strip's row holds still:
--                       { id, name, role (the plate's lamp, or nil), on, rank,
--                       blink }
--   pub.cells           readouts and gauges with nowhere else to go (the simple
--                       strip): { name, text, share }, text or share or both
--   pub.gear            the gearbox's label ("N", "3", "D", "M2", "R")
--   pub.odoMiles, pub.tripMiles   the odometer's figures, in miles
--   pub.speedK          game km/h to the km/h the car stands for (World Scale)
--   pub.stalled         the engine died under the driver and a mod publishes for
--                       this car: the library holds the ignition on, so the dash
--                       stays lit and says why. With nobody publishing there is
--                       nothing to say and the dash goes dark as it always has
--
-- Nothing here patches either mod and ZeD's dash never needs them: V.read gives
-- nil without the library, or when its poll fails, and every reading has ZeD's
-- own value to fall back on (ZeD_Dashboard.lua D.derive, D.applyPublished). The
-- library calls each provider in its own pcall and retires one that keeps
-- failing; this file's pcalls cover the library itself, so a change in its beta
-- costs the readings and not the dash. Its failures go through V.note, never
-- ZeD.logOnce: logOnce feeds safe mode's watchdog, and another mod's beta must not
-- send all of ZeD home. After a failed poll the library is left alone for a while.
-- The providers are written for the car the player drives, so V.read is for the
-- driver. V.figures gives a passenger what comes from no provider: the World Scale
-- and the odometer.
-- Proved by ZeDUI/tools/qa/vskdash_sim.lua; in the game, zedqa_roadworthy.lua.
-- ============================================================================

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local V = {}
ZeD.ModSupport.VSKDash = V

V.POLL_MS = 200                 -- the library's own POLL_MS; the frames between hand back the same table
V.RETRY_MS = 5000               -- after a failed poll: how long before the library is asked again
-- A published lamp with no painted spot on this plate stays off the plate (the simple strip lists it). true: the
-- worst of them borrows the plate's check-engine lamp, or its battery lamp where it has none (ZeD_Dashboard.lua).
V.BORROW_UNPAINTED = false

-- the library's lamp glyphs -> the plate's lamps (ZeD/DashPx.lua src). A glyph that is not here has no painted lamp
-- on any plate (tire, warn, a texture of the mod's own). vanillaIcon names the same lamps. The library's beam glyph is
-- not here either: the plate's blue lamp says the headlights are on, either beam (st.hiBeam), and the library's lamp
-- says high beam and is not there at all on low, so it could only ever add to that lamp, never put it out.
V.ICON_LAMP = { temp = "tempLamp", coolant = "tempLamp", oil = "oilLamp", battery = "genLamp", engine = "engLamp",
                belt = "beltLamp", fuel = "fuelLamp" }

local RANK = { off = 0, ok = 1, warn = 2, crit = 3 }
local KM_PER_MILE = 1.609344
local LIBRARY_ID = "vsk."       -- the library's own providers (its high beam lamp): a lamp, not a mod publishing

-- (x - x is 0 only for a finite number: NaN and the infinities give NaN, which equals nothing)
local function finite(x)
    if type(x) == "number" and x - x == 0 then return x end
    return nil
end
local function share(x)
    x = finite(x)
    if not x then return nil end
    if x < 0 then return 0 end
    if x > 1 then return 1 end
    return x
end
local function word(x) if type(x) == "string" and x ~= "" then return x end; return nil end
local function at(t, k) if k == nil then return nil end; return t[k] end    -- (no nil key into a game table)
local function nameOf(def) return word(def.name) or word(def.short) or tostring(def.id) end

-- The worst lamp holds a plate lamp; at the same level a blink is kept, whichever lamp came first.
local function claim(lamps, src, rank, blink, name)
    local l = lamps[src]
    if not l then lamps[src] = { rank = rank, blink = blink, name = name }
    elseif rank > l.rank then l.rank, l.blink, l.name = rank, blink, name
    elseif rank == l.rank then l.blink, l.name = l.blink or blink, l.name or name end
end

--- Once per place: to console.txt and nowhere else (see the file's head). A failing library costs one line.
local noted = {}
function V.note(place, err)
    if noted[place] then return end
    noted[place] = true
    print("[ZeD] " .. tostring(place) .. ": " .. tostring(err))
end

local function lamp(pub, s, r, def, powered)
    local e = s.seen[def.id]
    if not e then
        e = { id = def.id, name = nameOf(def), role = at(V.ICON_LAMP, def.vanillaIcon) or at(V.ICON_LAMP, def.icon) }
        s.seen[def.id] = e
        s.list[#s.list + 1] = e
    end
    local rank = at(RANK, r.level) or 0
    local on = powered and (rank >= RANK.warn or r.lit == true)
    e.on, e.rank, e.blink = on and true or false, rank, r.blink == true
    if not on then return end
    if e.role then claim(pub.lamps, e.role, rank, e.blink, e.name) end
    -- a lamp flagged checkEngine also lights the dash's engine lamp at that level (no name: the lamp stays the engine's)
    local th = at(RANK, def.checkEngine)
    if th and rank >= th then claim(pub.lamps, "engLamp", rank, e.blink, nil) end
end

-- (a gauge reads only with power, as the library's needle; a text is what the library prints on the dial)
local function gauge(pub, r, def, powered)
    if not powered then return end
    local value = share(r.value)
    if not value then return end
    if def.gauge == "temp" then
        if pub.temp == nil then pub.temp = value; return end
    elseif def.gauge == "oil" then
        if pub.oil == nil then pub.oil = value; return end
    end
    pub.cells[#pub.cells + 1] = { name = nameOf(def), share = value, text = word(r.text) }
end

-- what no provider stands behind, the same from any seat
local function figures(pub, VD, vehicle)
    if type(VD.odometer) == "function" then
        local ok, total, trip = pcall(VD.odometer, vehicle)
        total = ok and finite(total) or nil
        if total and total >= 0 then
            pub.odoMiles = total / KM_PER_MILE
            trip = finite(trip)
            if trip and trip >= 0 then pub.tripMiles = trip / KM_PER_MILE end
        end
    end
    local Sc = VSK.Scale
    if type(Sc) == "table" and type(Sc.toReal) == "function" then
        local ok, k = pcall(Sc.toReal, 1)
        k = ok and finite(k) or nil
        if k and k >= 1 then pub.speedK = k end
    end
end

local function gather(VD, vehicle, c, s)
    local pub = { lamps = {}, list = s.list, cells = {} }
    for i = 1, #s.list do s.list[i].on = false end
    figures(pub, VD, vehicle)      -- (first: a readout of the odometer needs no cell when the figure is in hand)
    if type(VD.gearLabel) == "function" then
        local ok, label = pcall(VD.gearLabel, vehicle)
        if ok then pub.gear = word(label) end
    end
    local power = finite(c.power) or 0
    local published = false
    for i = 1, #c.list do
        local r = c.list[i]
        local def = type(r) == "table" and r.def or nil
        if type(def) == "table" and def.id ~= nil and not r.hidden then
            published = published or tostring(def.id):sub(1, #LIBRARY_ID) ~= LIBRARY_ID
            local powered = power > 0 or def.unpowered == true
            if def.kind == "lamp" then lamp(pub, s, r, def, powered)
            elseif def.kind == "gauge" then gauge(pub, r, def, powered)
            elseif def.kind == "readout" and powered then
                local text = word(r.text)
                if text and not (def.odometer and pub.odoMiles) then
                    pub.cells[#pub.cells + 1] = { name = nameOf(def), text = text }
                end
            end
        end
    end
    -- (the library calls any stall a stall, a mod behind it or not: its hold is for the mods' lamps to say why)
    if published and type(VD.stalled) == "function" then
        local ok, held = pcall(VD.stalled, vehicle)
        if ok and held == true then pub.stalled = true end
    end
    return pub
end

local function library()
    local K = VSK
    local VD = type(K) == "table" and K.Dashboard or nil
    if type(VD) ~= "table" or type(VD.poll) ~= "function" then return nil end
    return VD
end

-- This car's list (seen once, kept while the player keeps this car). The dash's memory outlives a car: getting out and
-- into another hands the new car to the dash before its first frame, so the car is checked here.
local function stateFor(mem, vehicle)
    local s = mem.vsk
    if not s or s.vehicle ~= vehicle then
        s = { vehicle = vehicle, wait = V.POLL_MS, seen = {}, list = {} }
        mem.vsk = s
    end
    return s
end

--- This frame's readings for the car, for its driver. nil: no library, or it failed, and the dash reads as it always
--- has. Low cost: one table read a frame, the library five times a second.
function V.read(vehicle, chr, mem)
    local VD = library()
    if not VD then return nil end
    local s = stateFor(mem, vehicle)
    local now = getTimestampMs()
    if s.t and now - s.t < s.wait then return s.pub end
    s.t = now
    local ok, c = pcall(VD.poll, vehicle, chr)
    local okG, pub = false, nil
    if ok and type(c) == "table" and type(c.list) == "table" then okG, pub = pcall(gather, VD, vehicle, c, s)
    else pub = ok and "the poll gave no list" or c end
    if not okG then
        V.note("vsk dash", pub)
        pub = nil
    end
    s.wait = okG and V.POLL_MS or V.RETRY_MS
    s.pub = pub
    return pub
end

--- The same for a passenger: the World Scale and the odometer, in a table of the same shape. No provider runs and nothing
--- is lit from here. nil: no library.
function V.figures(vehicle, mem)
    local VD = library()
    if not VD then return nil end
    local s = stateFor(mem, vehicle)
    local now = getTimestampMs()
    if s.tFig and now - s.tFig < V.POLL_MS then return s.fig end
    s.tFig = now
    local pub = { lamps = {}, list = {}, cells = {} }
    local ok, err = pcall(figures, pub, VD, vehicle)
    if not ok then
        V.note("vsk dash", err)
        pub = nil
    end
    s.fig = pub
    return pub
end

--- The plate's gear letter for a published label ("M2" -> "2", "D3" -> "D"), or nil when the plate has no such letter
--- and the plate's own selector stands (letters: the gear part's, DashPx). No art is added for the rest.
function V.gearLetter(letters, label)
    if not (letters and label) then return nil end
    if letters[label] then return label end
    local last, first = label:sub(-1), label:sub(1, 1)
    if letters[last] then return last end
    if letters[first] then return first end
    return nil
end
