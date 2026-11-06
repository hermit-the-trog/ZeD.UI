-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ServerLink.lua
-- ============================================================================
-- THE LINK TO THE SERVER PART (ZeDUI/MP_SERVER_PART_DESIGN.md, B9). ZeD.ServerPart: is the server part here, what may
-- this player do, and the one way to talk to it. Only on a server: in single player nothing here runs.
--   present   nil while unknown, true once the server answered, false after three asks with no answer. A late answer
--             still flips it true.
--   v         the server's protocol, so later phases can test v >= n. Each side ignores commands it does not know.
--   staff     AnswerTickets; admin: RolesWrite. The server decides every command regardless; these only draw buttons.
--   adm       the server part holds the admin tools (Phase 2)
--   frozen    the server part is up and refuses writes (its data is from a newer ZeD)
--   forceOff  QA: behave as if no server part answered
-- Hello goes out at every OnCreatePlayer, a respawn included. send reads getPlayer() at each call: the object from
-- before a death is not the one to hand sendClientCommand.
-- ============================================================================

require "ZeD/ZeD_TicketProto"

ZeD = ZeD or {}
ZeD.ServerPart = ZeD.ServerPart or {}
local S = ZeD.ServerPart
local Tk = ZeD.Tk

local ASK_AT = { 0, 10000, 30000 }   -- ms after the round starts
local GIVE_UP = 40000

S.routes = S.routes or {}            -- module -> function(command, args)

local round = nil                    -- { at = when it started, sent = how many asks went out }

local function now() return getTimestampMs() end

function S.send(module, command, args)
    if not isClient() then return false end
    local p = getPlayer()
    if not p then return false end
    sendClientCommand(p, module, command, args or {})
    return true
end

function S.available() return S.present == true and not S.forceOff end

-- the same question again, now (a perm answer: this player's role may have changed)
function S.hello() return S.send(Tk.MOD_LINK, "hello", { v = Tk.PROTO }) end

function S.on(module, fn) S.routes[module] = fn end

local function heard(a)
    a = a or {}
    round = nil
    S.present = true
    S.v = a.v
    S.staff = a.staff == true
    S.admin = a.admin == true
    S.frozen = a.frozen == true
    S.adm = a.adm == 1
    if ZeD.Tickets and ZeD.Tickets.onHello then ZeD.Tickets.onHello(a) end
    if ZeD.Admin and ZeD.Admin.onHello then ZeD.Admin.onHello(a) end
end

local function onServerCommand(module, command, args)
    if module == Tk.MOD_LINK then
        if command == "hello" then
            local ok, err = pcall(heard, args)
            if not ok then ZeD.logOnce("server link hello", err) end
        end
        return
    end
    local fn = S.routes[module]
    if fn then
        local ok, err = pcall(fn, command, args or {})
        if not ok then ZeD.logOnce("server link " .. tostring(command), err) end
    end
end

local function tick()
    if not round then return end
    local gone = now() - round.at
    local nextAt = ASK_AT[round.sent + 1]
    if nextAt and gone >= nextAt then
        if S.hello() then round.sent = round.sent + 1 end
    elseif not nextAt and gone >= GIVE_UP then
        round = nil
        S.present = false
    end
end

local function onCreatePlayer()
    if not isClient() then return end
    round = { at = now(), sent = 0 }
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnTick.Add(tick)
Events.OnServerCommand.Add(onServerCommand)

return S
