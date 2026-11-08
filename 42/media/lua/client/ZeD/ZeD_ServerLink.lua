-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ServerLink.lua
-- ============================================================================
-- THE LINK TO THE SERVER PART (ZeDUI/MP_SERVER_PART_DESIGN.md, B9). ZeD.ServerPart: is the server part here, what may
-- this player do, and the one way to talk to it. Only on a server: in single player nothing here runs.
--   present   nil while unknown, true once the server answered, false after three asks with no answer. A late answer
--             still flips it true.
--   v         the server's protocol, so later phases can test v >= n. Each side ignores commands it does not know.
--   staff     AnswerTickets; admin: RolesWrite. The server decides every command regardless; these only draw buttons.
--   adm       the server part holds the admin tools (Phase 2)
--   lg        the server part holds the log (Phase 4)
--   cm        the server part holds community (Phase 5): the rules, the news. A server without it shows none of this
-- The hello's a.ex, the server extras (Phase 6), goes to ZeD_Extras.lua, and a.cm to ZeD_Community.lua; each part of the
-- server's is on its own, so any of them can be missing from a hello.
--   frozen    the server part is up and refuses writes (its data is from a newer ZeD)
--   forceOff  QA: behave as if no server part answered
-- Hello goes out at every OnCreatePlayer, a respawn included. send reads getPlayer() at each call: the object from
-- before a death is not the one to hand sendClientCommand. A caller acting for one split-screen player hands that
-- player (send's fourth argument): the game sends the player's index with the command (GameClient.sendClientCommand,
-- checked on 42.21), so the server sees that player, not the first (the dash's miles, known issue Nov 7 2026).
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

function S.send(module, command, args, player)
    if not isClient() then return false end
    local p = player
    if not (p and p.isLocalPlayer and p:isLocalPlayer()) then p = getPlayer() end
    if not p then return false end
    sendClientCommand(p, module, command, args or {})
    return true
end

function S.available() return S.present == true and not S.forceOff end

-- the same question again, now (a perm answer: this player's role may have changed)
function S.hello()
    local ok = S.send(Tk.MOD_LINK, "hello", { v = Tk.PROTO })
    if ok then S.helloAt = now() end
    return ok
end

function S.on(module, fn) S.routes[module] = fn end

-- THE JOIN RULES ANSWERED. Until a player asked at joining agrees, the server refuses every ZeD command but the hello (Srv.gates.rules),
-- so whatever a part asked for meanwhile came back "perm" or not at all. Once the server takes the agreement, each part asks again:
-- the hello goes out (tickets, admin, extras and community fill from it) and every part's own hook runs (S.onAgreed). agreedN counts
-- the agreements, for a part that keeps no hook (a dash per car compares it)
S.agreeHooks = S.agreeHooks or {}
S.agreedN = S.agreedN or 0
-- past HELLO_MS, the wait before the hello goes again: the server times the gap by when each hello arrives, and one that left on
-- time but landed early through network jitter would be refused with nothing said
S.HELLO_MARGIN_MS = 1000
function S.onAgreed(name, fn) S.agreeHooks[name] = fn end
function S.agreed()
    S.agreedN = S.agreedN + 1
    -- (the server answers one hello a HELLO_MS: one sent sooner after the last is refused, so it waits for its turn, the tick sends it)
    local due = S.helloAt and (S.helloAt + Tk.LIMITS.HELLO_MS + S.HELLO_MARGIN_MS) or 0
    if now() >= due then S.hello() else S.helloDue = due end
    for name, fn in pairs(S.agreeHooks) do
        local ok, err = pcall(fn)
        if not ok and ZeD.logOnce then ZeD.logOnce("agreed " .. tostring(name), err) end
    end
end

local function heard(a)
    a = a or {}
    round = nil
    S.present = true
    S.v = a.v
    S.staff = a.staff == true
    S.admin = a.admin == true
    S.frozen = a.frozen == true
    S.adm = a.adm == 1
    S.lg = a.lg == 1
    S.cm = type(a.cm) == "table"
    if ZeD.Tickets and ZeD.Tickets.onHello then ZeD.Tickets.onHello(a) end
    if ZeD.Admin and ZeD.Admin.onHello then ZeD.Admin.onHello(a) end
    if ZeD.Extras and ZeD.Extras.onHello then ZeD.Extras.onHello(a) end
    if ZeD.Community and ZeD.Community.onHello then ZeD.Community.onHello(a) end
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
    if S.helloDue and now() >= S.helloDue then
        S.helloDue = nil
        S.hello()
    end
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
