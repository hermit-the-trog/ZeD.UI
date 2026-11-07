-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerDash.lua
-- ============================================================================
-- THE DASH'S ODOMETER, THE SERVER'S SIDE (punch list 92 and 94; ZeDUI/HANDOFF_design_dash_roadworthy_20261106.md;
-- ZeD_DashProto.lua has why). One command, from the driver's client about every tenth of a mile, at a press and as a
-- drive ends: the server writes ZeD_odo, ZeD_trip and ZeD_odoTrip into its own copy of the car's mod data, and nothing
-- else, so a key another mod keeps only here (Roadworthy's, the extras' claim stamp) stays. Then it sends the three
-- figures (DP.FIG) to the car's other occupants, the only players who see this car's dash; their dashes write them to
-- their own copy and send nothing on.
-- The car's whole mod data goes out (transmitModData, to every client near the car) only at the coarse moments, and only
-- when figures were taken since the last time: a first mileage, a press (the trip reset, the ODO / TRIP switch), the
-- engine off, the driver gone from the seat (DP.ODO's save, or what the server sees itself), and a driver forgotten
-- with figures not sent out (prune). Each such send replaces every nearby client's copy, and a key another mod keeps
-- only on a client's copy is gone, so never every tenth of a mile. The coarse ones keep the saved figures reaching a
-- client that loads the car later.
--
-- What it takes (the player from the event, never a name from the arguments; a refusal is silent, junk is logged by Srv.bad):
--   the sender is the car's driver, or was a moment ago (DP.GRACE_MS: the game's exit packet lands before the client's last
--     send) with nobody else at the wheel since
--   the car's number, the miles and the switch are numbers and a boolean in range, and the trip is no more than the odometer;
--     the save flag a boolean or nothing
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

local EPS = DP.EPS

Srv.modules[DP.MOD] = true
-- memory only (a restart forgets it): the car's number -> { u = its last driver, at = their last good send,
-- dirty = figures taken since the car was last sent out }
Srv.dash = Srv.dash or { by = {}, n = 0 }
local M = Srv.dash

-- (IsoObject.transmitModData(), no arguments, checked on 42.22.2: on the server, GameServer.sendObjectModData to the
-- clients near the car, the driver's own too)
local function sendOut(v, r)
    r.dirty = nil
    v:transmitModData()
end

local function prune(now)
    if M.n < DP.PRUNE_AT then return end
    local n = 0
    for id, r in pairs(M.by) do
        if now - r.at > DP.GRACE_MS then
            -- (a driver whose coarse send never came, say a dropped connection: what the server took goes out now)
            if r.dirty then
                local v = getVehicleById(id)
                if v then sendOut(v, r) end
            end
            M.by[id] = nil
        else
            n = n + 1
        end
    end
    M.n = n
end

-- the figures to the car's occupants but the sender (BaseVehicle.getMaxPassengers, getCharacter(int), checked on
-- 42.22.2). Only a player: sendServerCommand takes an IsoPlayer, and no other overload fits
local function tellRiders(v, p, figs)
    for i = 0, v:getMaxPassengers() - 1 do
        local c = v:getCharacter(i)
        if c ~= nil and c ~= p and instanceof(c, "IsoPlayer") then Srv.to(c, DP.MOD, DP.FIG, figs) end
    end
end

-- the trip as sent, against the server's figures: forward by no more than the odometer went, or a reset since
local function tripOk(trip, odo, was, wasTrip)
    if not was then return true end
    local gained = odo - was
    if trip >= wasTrip then return trip - wasTrip <= gained + EPS end
    return trip <= gained + EPS
end

Srv.register(DP.MOD, DP.ODO, {}, function(p, a)
    if not (DP.okFigs(a) and (a.save == nil or type(a.save) == "boolean")) then
        return Srv.bad(p, "dash odo")
    end
    local v = getVehicleById(a.veh)
    if not v then return end
    local u, now = p:getUsername(), getTimestampMs()
    local d = v:getDriver()
    local r = M.by[a.veh]
    if d ~= p then
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
        if not r then r = {}; M.by[a.veh] = r; M.n = M.n + 1 end
        r.u, r.at = u, now
        prune(now)
    end
    local wasShow = vmd.ZeD_odoTrip == true
    -- a coarse moment: the client says so (a press, a first mileage, the engine off, the driver leaving), or the server
    -- sees one itself (a car with no figures yet, the trip down, the switch moved, the driver out of the seat, the engine off)
    local save = a.save == true or not was or a.trip < wasTrip or wasShow ~= a.show or d ~= p or not v:isEngineRunning()
    if not (was == a.odo and wasTrip == a.trip and wasShow == a.show) then
        vmd.ZeD_odo, vmd.ZeD_trip, vmd.ZeD_odoTrip = a.odo, a.trip, a.show
        r.dirty = true
        tellRiders(v, p, { veh = a.veh, odo = a.odo, trip = a.trip, show = a.show })
    end
    if save and r.dirty then sendOut(v, r) end
end)

return M
