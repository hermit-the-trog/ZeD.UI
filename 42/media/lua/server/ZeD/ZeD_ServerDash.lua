-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerDash.lua
-- ============================================================================
-- THE DASH'S ODOMETER, THE SERVER'S SIDE (punch list 92 and 94; ZeDUI/HANDOFF_design_dash_roadworthy_20261106.md;
-- ZeD_DashProto.lua has why). One command, from the driver's client about every tenth of a mile, at a press and as a
-- drive ends: the server writes ZeD_odo, ZeD_trip and ZeD_odoTrip into its own copy of the car's mod data, and nothing
-- else, then sends the car's mod data from here. A send from the server replaces each client's copy and leaves its own
-- whole, so a key another mod keeps only here (Roadworthy's, the extras' claim stamp) stays.
--
-- What it takes (the player from the event, never a name from the arguments; a refusal is silent, junk is logged by Srv.bad):
--   the sender is the car's driver, or was a moment ago (DP.GRACE_MS: the game's exit packet lands before the client's last
--     send) with nobody else at the wheel since
--   the car's number, the miles and the switch are numbers and a boolean in range, and the trip is no more than the odometer
--   the odometer only goes forward. The trip goes forward by no more than the odometer did, or back down as far as the miles
--     since the server's figure (a reset, then what was driven after it)
-- A refusal of the car's driver on those last two (not junk, not someone else) answers them with the server's figures
-- (DP.SYNC; ZeD_Dashboard:_odoSync): their copy of the car is behind this one, say a trip another driver zeroed that never
-- reached them, and it would be refused for the whole drive.
-- No clock and no listener of its own: the server part's one OnClientCommand listener hands the command here, and the car
-- is only read when a command comes.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_DashProto"
require "ZeD/ZeD_ServerCore"

local Srv = ZeD.Srv
local DP = ZeD.DashProto
if not Srv or Srv.off then return end

local EPS = 0.001                    -- miles: the odometer and the trip add the same figures, rounded apart

Srv.modules[DP.MOD] = true
-- memory only (a restart forgets it): the car's number -> { u = its last driver, at = their last good send }
Srv.dash = Srv.dash or { by = {}, n = 0 }
local M = Srv.dash

local function prune(now)
    if M.n < DP.PRUNE_AT then return end
    local n = 0
    for id, r in pairs(M.by) do
        if now - r.at > DP.GRACE_MS then M.by[id] = nil else n = n + 1 end
    end
    M.n = n
end

-- the trip as sent, against the server's figures: forward by no more than the odometer went, or a reset since
local function tripOk(trip, odo, was, wasTrip)
    if not was then return true end
    local gained = odo - was
    if trip >= wasTrip then return trip - wasTrip <= gained + EPS end
    return trip <= gained + EPS
end

Srv.register(DP.MOD, DP.ODO, {}, function(p, a)
    if not (DP.okVeh(a.veh) and DP.okMiles(a.odo) and DP.okMiles(a.trip) and type(a.show) == "boolean") or a.trip > a.odo + EPS then
        return Srv.bad(p, "dash odo")
    end
    local v = getVehicleById(a.veh)
    if not v then return end
    local u, now = p:getUsername(), getTimestampMs()
    local d = v:getDriver()
    if d ~= p then
        local r = M.by[a.veh]
        if d ~= nil or not r or r.u ~= u or now - r.at > DP.GRACE_MS then return end
    end
    local vmd = v:getModData()
    local was = tonumber(vmd.ZeD_odo)
    local wasTrip = tonumber(vmd.ZeD_trip) or 0
    if was and (a.odo < was or not tripOk(a.trip, a.odo, was, wasTrip)) then
        if d == p then
            Srv.to(p, DP.MOD, DP.SYNC, { veh = a.veh, odo = was, trip = wasTrip, sent = a.odo })
        end
        return
    end
    if d == p then
        if not M.by[a.veh] then M.n = M.n + 1 end
        M.by[a.veh] = { u = u, at = now }
        prune(now)
    end
    if was == a.odo and wasTrip == a.trip and (vmd.ZeD_odoTrip == true) == a.show then return end
    vmd.ZeD_odo, vmd.ZeD_trip, vmd.ZeD_odoTrip = a.odo, a.trip, a.show
    -- (IsoObject.transmitModData(), no arguments, checked on 42.22.2: on the server, GameServer.sendObjectModData to the
    -- clients near the car, the driver's own too)
    v:transmitModData()
end)

return M
