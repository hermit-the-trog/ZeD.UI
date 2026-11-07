-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_DashProto.lua
-- ============================================================================
-- THE DASH'S ODOMETER ON A SERVER: WHAT BOTH SIDES AGREE ON (punch list 92 and 94;
-- ZeDUI/HANDOFF_design_dash_roadworthy_20261106.md). The driver's client (ZeD_Dashboard:_odoSend) asks the server to write
-- the car's three odometer keys; the server (ZeD_ServerDash.lua) writes only those, on its own copy of the car, and tells
-- the car's other seats. Never the client's vehicle:transmitModData(): that sends the whole table, and the server's copy
-- is wiped and replaced with it (ObjectModDataPacket.parse, KahluaTableImpl.load wipes first), so a key another mod keeps
-- only on the server's copy (Roadworthy's, a claim's stamp) would be lost. The server's own transmitModData does the same
-- to each nearby client's copy, so it sends the car out only at the coarse moments (engine off, the driver gone, a press,
-- a first mileage): a key another mod keeps only on a client's copy is wiped then, never every tenth of a mile.
-- Pure Lua, ASCII, nothing client-only at load: this file also runs on a dedicated server.
-- ============================================================================

ZeD = ZeD or {}
ZeD.DashProto = ZeD.DashProto or {}
local DP = ZeD.DashProto

DP.MOD = "ZeDDash"
DP.ODO = "odo"           -- { veh = the car's short id, odo = miles, trip = miles, show = the electronic window shows the trip,
                         --   save = true at a coarse moment (a press, a first mileage, the engine off, the driver leaving):
                         --   the server sends the car's mod data out then; nil or false otherwise }
DP.SYNC = "sync"         -- server -> the driver, when it refuses their figures as behind its own (the odometer went back,
                         -- or the trip further than it allows): { veh, odo, trip = the server's, sent = the refused odo }
DP.FIG = "fig"           -- server -> the car's other occupants, at each figure it takes: { veh, odo, trip, show }. Their
                         -- dashes write them to their own copy of the car, and send nothing on

DP.ODO_MAX = 10000000    -- miles: no odometer reads this far (a found car starts under 140000)
DP.GRACE_MS = 10000      -- a driver's last send can land after they got out or moved seats (the game's exit packet goes
                         -- first): the server takes it from the car's last driver this long after their last good send,
                         -- while nobody else is at the wheel. The client drops a send later than 3 s (ODO_LATE_MS)
DP.PRUNE_AT = 256        -- the server forgets drivers past their grace once it remembers this many cars

-- a reading the server takes: a number, not NaN or infinite, inside 0 .. ODO_MAX
function DP.okMiles(n) return type(n) == "number" and n == n and n >= 0 and n < DP.ODO_MAX end
-- a vehicle's short number as a client names it (the same test as the extras' Ex.okVeh)
function DP.okVeh(n) return type(n) == "number" and n == math.floor(n) and n >= -32768 and n <= 65535 end
DP.EPS = 0.001           -- miles: the odometer and the trip add the same figures, rounded apart
-- a car's three figures as both sides take them (DP.ODO without its save, DP.FIG): the trip no more than the odometer
function DP.okFigs(a)
    return type(a) == "table" and DP.okVeh(a.veh) and DP.okMiles(a.odo) and DP.okMiles(a.trip) and type(a.show) == "boolean"
        and a.trip <= a.odo + DP.EPS
end

return DP
