-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_DashProto.lua
-- ============================================================================
-- THE DASH'S ODOMETER ON A SERVER: WHAT BOTH SIDES AGREE ON, the ash tray's one command, and the cabin color's roll
-- (at the end: the odds, the paint's buckets, the stamp kept on the car). The driver's client
-- (ZeD_Dashboard:_odoSend) asks the server to write the car's three odometer keys; the server (ZeD_ServerDash.lua)
-- writes only those, on its own copy of the car, and tells the car's other seats. Never the client's
-- vehicle:transmitModData(): that sends the whole table, and the server's copy is wiped and replaced with it
-- (ObjectModDataPacket.parse, KahluaTableImpl.load wipes first), so a key another mod keeps only on the server's copy
-- (Roadworthy's, a claim's stamp) would be lost. The server's own transmitModData does the same to each nearby client's
-- copy, so it sends the car out only at the coarse moments (engine off, the driver gone, a press, a first mileage): a
-- key another mod keeps only on a client's copy is wiped then, never every tenth of a mile.
-- Shared: this file loads on the client and on a dedicated server alike, so nothing client-only at file scope. Pure
-- Lua, pure ASCII.
-- ============================================================================

-- Reload-safe: loading this file twice reuses the table instead of wiping it
ZeD = ZeD or {}
ZeD.DashProto = ZeD.DashProto or {}
local DP = ZeD.DashProto

DP.MOD = "ZeDDash"       -- the module on every dash command
DP.ODO = "odo"           -- { veh = the car's short id, odo = miles, trip = miles, show = the electronic window shows the trip,
                         --   save = true at a coarse moment (a press, a first mileage, the engine off, the driver leaving):
                         --   the server sends the car's mod data out then; nil or false otherwise }
DP.SYNC = "sync"         -- server -> the driver, when it refuses their figures as behind its own (the odometer went back,
                         -- or the trip further than it allows): { veh, odo, trip = the server's, sent = the refused odo }
DP.FIG = "fig"           -- server -> the car's other occupants, at each figure it takes, and to a passenger who asks:
                         -- { veh, odo, trip, show }. Their dashes write them to their own copy of the car, and send
                         -- nothing on
DP.ASK = "ask"           -- a passenger's dash as it sits down: { veh }. The server answers with DP.FIG, its own figures,
                         -- to that player alone (a car stopped with its engine on sends none)
DP.ASH = "ash"           -- the driver opens or shuts the car's ash tray (the server takes it from anyone in the car):
                         -- { veh, open = boolean }. The server writes ZeD_ash on its own copy of the car (kept with the
                         -- world, one tray a car: the same for every seat and every session) and sends the car out, as
                         -- at the odometer's presses

DP.ODO_MAX = 10000000    -- miles: no odometer reads this far (a found car starts under 140000)
DP.GRACE_MS = 10000      -- a driver's last send can land after they got out or moved seats (the game's exit packet goes
                         -- first): the server takes it from the car's last driver this long after their last good send,
                         -- while nobody else is at the wheel. The client drops a send later than 3 s (ODO_LATE_MS)
DP.PRUNE_AT = 256        -- the server forgets drivers past their grace once it remembers this many cars
DP.ASK_MS = 1000         -- the server answers one ask a player this often (the dash asks again after 2 s, 3 times at most)
DP.ASH_MS = 500          -- the server takes one ash tray press a player this often (each one sends the car out)

--- a reading either side takes: a number, not NaN or infinite, inside 0 .. ODO_MAX
function DP.okMiles(n) return type(n) == "number" and n == n and n >= 0 and n < DP.ODO_MAX end
--- a vehicle's short number as a client names it (the same test as the extras' Ex.okVeh)
function DP.okVeh(n) return type(n) == "number" and n == math.floor(n) and n >= -32768 and n <= 65535 end
DP.EPS = 0.001           -- miles: the odometer and the trip add the same figures but round apart, so the trip may
                         -- read a hair over the odometer
--- a car's three figures as both sides take them (DP.ODO without its save, DP.FIG): the trip no more than the odometer
function DP.okFigs(a)
    return type(a) == "table" and DP.okVeh(a.veh) and DP.okMiles(a.odo) and DP.okMiles(a.trip) and type(a.show) == "boolean"
        and a.trip <= a.odo + DP.EPS
end
--- an ash tray press as the server takes it (DP.ASH)
function DP.okAsh(a)
    return type(a) == "table" and DP.okVeh(a.veh) and type(a.open) == "boolean"
end

-- ============================================================================
-- THE CABIN COLOR: each civilian dash comes in three cabin colors, and the car's paint sets the odds of which one a
-- car has; the fleet dashes are always black. The roll comes from the car's key number (random when the car is made,
-- saved with it and sent to every client with it), so every machine works out the same color with no command and no
-- wait. The paint bucket and the roll are also stamped on the car's modData (ZeD_cab) the first time a dash or the
-- server sees the car, so a later repaint never changes a cabin someone has already sat in. The client stamps only its
-- own copy (it never transmits the car's modData); the server stamps its copy where it already writes the car.
-- ============================================================================
DP.CAB_KEY = "ZeD_cab"   -- the car's modData: "BUCKET:roll", e.g. "BLUE:37"

-- the paint's buckets, and the words each answers to in the odds below, best first. A maroon car reads a "red" row
-- where its table has no maroon one; silver and gray are one bucket
DP.PAINT_WORDS = {
    RED = { "red" }, MAROON = { "maroon", "red" }, BROWN = { "brown", "tan", "yellow", "orange" }, GREEN = { "green" },
    BLUE = { "blue" }, WHITE = { "white" }, SILVER = { "silver", "gray" }, BLACK = { "black" },
}
-- a car whose paint can't be read: silver, the neutral row in every table that has one
DP.PAINT_UNREAD = "SILVER"

-- which group's colors each dash wears (ZeD/DashPx.lua's des.cabins hold the same colors, lead first)
DP.CAB_GROUP = {
    wagon = "wagon",
    nyala = "s70", d6 = "s70", bulldriver = "s70", rancher = "s70",
    horizon = "s80", dart = "s80", van = "s80",
    dashelite = "s90", primani = "s90", suv = "s90",
    cossette = "lux", luxury = "lux",
    police = "fleet", taxi = "fleet", ambulance = "fleet", fire = "fleet", ranger = "fleet",
}
-- per group, the paint's rows as design wrote them: the paint words, then each cabin color (its ramp) and its odds
-- in a hundred. The fleet always black
DP.CAB_ODDS = {
    wagon = { title = "Station wagon", rows = {
        { paint = { "brown", "tan", "yellow", "orange", "red" }, odds = { { "v_walnut", 80 }, { "v_army", 20 } } },
        { paint = { "green" }, odds = { { "v_army", 75 }, { "v_walnut", 25 } } },
        { paint = { "blue" }, odds = { { "v_navy70", 80 }, { "v_walnut", 20 } } },
        { paint = { "white", "silver", "gray", "black" }, odds = { { "v_walnut", 40 }, { "v_navy70", 30 }, { "v_army", 30 } } },
    } },
    s70 = { title = "70s", rows = {
        { paint = { "green" }, odds = { { "v_moss", 75 }, { "v_ltbrown", 25 } } },
        { paint = { "blue" }, odds = { { "v_navy70", 80 }, { "v_ltbrown", 20 } } },
        { paint = { "brown", "tan", "yellow", "orange", "red" }, odds = { { "v_ltbrown", 85 }, { "v_moss", 15 } } },
        { paint = { "white", "silver", "gray", "black" }, odds = { { "v_ltbrown", 40 }, { "v_navy70", 30 }, { "v_moss", 30 } } },
    } },
    s80 = { title = "80s", rows = {
        { paint = { "red", "maroon" }, odds = { { "v_maroon", 75 }, { "v_beige_d", 25 } } },
        { paint = { "blue" }, odds = { { "v_navy", 80 }, { "v_beige_d", 20 } } },
        { paint = { "brown", "tan", "yellow", "green" }, odds = { { "v_beige_d", 85 }, { "v_maroon", 15 } } },
        { paint = { "white", "silver", "gray", "black" }, odds = { { "v_maroon", 40 }, { "v_navy", 35 }, { "v_beige_d", 25 } } },
    } },
    s90 = { title = "90s late models", rows = {
        { paint = { "brown", "tan", "green", "white" }, odds = { { "v_beige_d", 60 }, { "v_grey", 40 } } },
        { paint = { "blue", "silver", "gray" }, odds = { { "v_grey", 70 }, { "v_black", 30 } } },
        { paint = { "red", "black" }, odds = { { "v_black", 50 }, { "v_grey", 35 }, { "v_beige_d", 15 } } },
    } },
    lux = { title = "Sports and luxury", rows = {
        { paint = { "red" }, odds = { { "l_black", 60 }, { "l_brown", 40 } } },
        { paint = { "black", "white", "silver" }, odds = { { "l_red", 45 }, { "l_black", 35 }, { "l_brown", 20 } } },
        { paint = { "brown", "tan", "green", "blue" }, odds = { { "l_brown", 70 }, { "l_black", 30 } } },
    } },
    fleet = { title = "Public service", always = "v_black" },
}

--- the paint's bucket from the car's hue, saturation and value (each 0..1, as BaseVehicle.getColorHue / Saturation /
--- Value give them), or nil when there is none to read (not numbers, or all three 0: a car not painted yet). Vanilla
--- paints white and silver at value 0.7 to 0.8 (split at 0.75), black under 0.25, and a car that wears its livery
--- (police, fire, the business vans) 0 / 0.1 / 0.9, which reads white
function DP.paintBucket(h, s, v)
    if type(h) ~= "number" or type(s) ~= "number" or type(v) ~= "number" then return nil end
    if h ~= h or s ~= s or v ~= v or (h == 0 and s == 0 and v == 0) then return nil end
    if s < 0.20 then
        if v < 0.40 then return "BLACK" end
        if v >= 0.75 then return "WHITE" end
        return "SILVER"
    end
    if h >= 0.95 or h < 0.03 then return (v >= 0.45) and "RED" or "MAROON" end
    if h < 0.19 then return "BROWN" end           -- orange, brown, tan, yellow: one warm family
    if h < 0.47 then return "GREEN" end
    if h < 0.80 then return "BLUE" end
    return (v >= 0.55) and "RED" or "MAROON"       -- purple and magenta: the nearest the tables name
end

--- the car's roll, 0..99, from its key number. A string hash, as the ash tray's, with its own start so the two don't
--- follow each other; arithmetic on a key up to 10^8 would pass 2^31, where the game's % goes wrong
function DP.cabRoll(key)
    local s, h = "cab" .. tostring(key), 11
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 1000003 end
    return h % 100
end

--- a stamp's bucket and roll, or nil for anything else (a stamp from a later version, junk another mod left)
function DP.cabParse(stamp)
    if type(stamp) ~= "string" then return nil end
    local b, r = stamp:match("^([A-Z]+):(%d+)$")
    r = tonumber(r)
    if b and DP.PAINT_WORDS[b] and r and r >= 0 and r < 100 then return b, r end
    return nil
end

--- a group's row for a paint bucket (nil: unread, the PAINT_UNREAD row): the first row naming the bucket's best word,
--- else its next. Returns the row and its index, or nil for a group with no rows (the fleet)
function DP.cabRow(group, bucket)
    local G = DP.CAB_ODDS[group or ""]
    if not (G and G.rows) then return nil end
    local words = DP.PAINT_WORDS[bucket or DP.PAINT_UNREAD] or DP.PAINT_WORDS[DP.PAINT_UNREAD]
    for wi = 1, #words do
        for ri = 1, #G.rows do
            local pw = G.rows[ri].paint
            for k = 1, #pw do if pw[k] == words[wi] then return G.rows[ri], ri end end
        end
    end
    return nil
end

--- the cabin color (a ramp id) for a dash, a paint bucket (nil: unread) and a roll; nil for a dash in no group
function DP.cabinFor(designId, bucket, roll)
    local group = DP.CAB_GROUP[designId]
    local G = DP.CAB_ODDS[group or ""]
    if not G then return nil end
    if G.always then return G.always end
    local row = DP.cabRow(group, bucket)
    if not row then return nil end
    roll = math.max(0, math.min(99, math.floor(tonumber(roll) or 0)))
    local acc = 0
    for i = 1, #row.odds do
        acc = acc + row.odds[i][2]
        if roll < acc then return row.odds[i][1] end
    end
    return row.odds[#row.odds][1]
end

-- o:m() or nil, never an error (a modded car's object may lack the method or throw)
local function _inv(o, m) return o[m](o) end
local function _call(o, m)
    local ok, v = pcall(_inv, o, m)
    if ok then return v end
    return nil
end

--- the car's paint bucket and roll: its stamp when it has one, else read now. Returns bucket (nil: the paint can't
--- be read), roll, and whether it came from the stamp
function DP.carCabin(vehicle)
    if vehicle == nil then return nil, 0, false end
    local md = _call(vehicle, "getModData")
    local b, r = DP.cabParse(md and md[DP.CAB_KEY])
    if b then return b, r, true end
    b = DP.paintBucket(_call(vehicle, "getColorHue"), _call(vehicle, "getColorSaturation"), _call(vehicle, "getColorValue"))
    local key = _call(vehicle, "getKeyId")
    if key == nil then key = _call(vehicle, "getId") or 0 end
    return b, DP.cabRoll(key), false
end

--- stamps the car's bucket and roll on this machine's copy of its modData, once; true when it wrote one. A car whose
--- paint can't be read is left unstamped (the stamp would freeze the fallback row)
function DP.stampCabin(vehicle)
    local b, r, stamped = DP.carCabin(vehicle)
    if stamped or b == nil then return false end
    local md = _call(vehicle, "getModData")
    if not md then return false end
    md[DP.CAB_KEY] = b .. ":" .. tostring(r)
    return true
end

return DP
