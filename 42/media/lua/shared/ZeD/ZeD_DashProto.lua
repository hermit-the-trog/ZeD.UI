-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_DashProto.lua
-- ============================================================================
-- THE DASH'S ODOMETER ON A SERVER: WHAT BOTH SIDES AGREE ON (punch list 92 and 94;
-- ZeDUI/HANDOFF_design_dash_roadworthy_20261106.md). The driver's client (ZeD_Dashboard:_odoSend) asks the server to write
-- the car's three odometer keys; the server (ZeD_ServerDash.lua) writes only those, on its own copy of the car, and sends
-- the car's mod data out from there. Never the client's vehicle:transmitModData(): that sends the whole table, and the
-- server's copy is wiped and replaced with it (ObjectModDataPacket.parse, KahluaTableImpl.load wipes first), so a key
-- another mod keeps only on the server's copy (Roadworthy's, a claim's stamp) would be lost.
-- Pure Lua, ASCII, nothing client-only at load: this file also runs on a dedicated server.
-- ============================================================================

ZeD = ZeD or {}
ZeD.DashProto = ZeD.DashProto or {}
local DP = ZeD.DashProto

DP.MOD = "ZeDDash"
DP.ODO = "odo"           -- { veh = the car's short id, odo = miles, trip = miles, show = the electronic window shows the trip }

DP.ODO_MAX = 10000000    -- miles: no odometer reads this far (a found car starts under 140000)
DP.GRACE_MS = 10000      -- a driver's last send can land after they got out or moved seats (the game's exit packet goes
                         -- first): the server takes it from the car's last driver this long after their last good send,
                         -- while nobody else is at the wheel. The client drops a send later than 3 s (ODO_LATE_MS)
DP.PRUNE_AT = 256        -- the server forgets drivers past their grace once it remembers this many cars

-- a reading the server takes: a number, not NaN or infinite, inside 0 .. ODO_MAX
function DP.okMiles(n) return type(n) == "number" and n == n and n >= 0 and n < DP.ODO_MAX end
-- a vehicle's short number as a client names it (the same test as the extras' Ex.okVeh)
function DP.okVeh(n) return type(n) == "number" and n == math.floor(n) and n >= -32768 and n <= 65535 end

return DP
