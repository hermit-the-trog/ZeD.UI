-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerHelper.lua
-- ============================================================================
-- THE HOST HELPER'S FILES. Server only (the first line); pure Lua, pure ASCII. Optional, off by default: the sandbox option
-- ZeD.HostHelper turns it on. The helper is a small program the server's owner runs on the server machine
-- (ZeDUI/server_helper/zed_rcon_helper.py, from the project's repository). It talks to the game's own remote console (RCON)
-- and makes the game calls ZeD owes (ban, unban, kick, a mute's voice ban, the role a lifted ban gives back), so the rules
-- hold with no staff online.
-- Nothing here goes over the wire to a client: ZeD_ServerAdmin.lua decides what is owed and calls H.write and H.read. Server
-- Lua cannot reach the console itself, so the two talk through two files in Zomboid/Lua/ZeD_helper/ on the server
-- (getFileWriter and getFileReader both work under the server's own Lua folder):
--
--   queue.txt    this file writes it: "ZEDQ 1 <epoch>", then one call a line: id, try, act, target, reason (tab-separated),
--                then "ZEDQ end". The game's file writer is not atomic, so the helper takes a queue only with its last line.
--                A lifted ban's role restore is "SetRole", the name, the role, then a sixth field "restore"
--   answers.txt  the helper writes it: "ZEDA 1 <epoch> <unix seconds>", then one answer a line: id, try, result, text
--
-- The epoch is a random word made at each server start (never saved), so the helper never takes another world's numbers, or
-- the numbers of a table a crash rolled back, for these. Only the calls on the helper's own allow-list go in the queue, with targets already
-- checked against the same patterns it checks them against again. A ban's reason is the only typed text: it loses its tabs and
-- line breaks here, its quotes and anything past plain ASCII in the helper. Results: ok; gone (a Kick or a voice ban on
-- someone not on); refused (the game or the helper said no: the call goes to a staff client); failed (it goes to a staff
-- client too, and the helper tries again HELPER_WAIT_S later, HELPER_TRIES tries in all).
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_AdminProto"
require "ZeD/ZeD_ServerCore"

local Srv = ZeD.Srv
if not Srv or Srv.off then return end

local H = Srv.H or {}
Srv.H = H

H.QUEUE = "ZeD_helper/queue.txt"
H.ANSWERS = "ZeD_helper/answers.txt"
H.READ_MAX = 1000                     -- answer lines read at most, so a runaway file costs nothing
H.END = "ZEDQ end"                     -- the queue's last line: a file without it was read mid-write

-- the calls the helper makes, and the kind of target each takes. Never an IP: the game's IP ban needs the player's
-- connection, which only a staff client's call has. VoiceBan is "voiceban <name> -true" (VoiceBanCommand: the name, then
-- -true or -false), so its name may not start with "-", which the console could read as that word
H.ACTS = { Kick = "user", Ban = "user", UnBan = "user", BanSteamID = "sid", UnBanSteamID = "sid", VoiceBan = "voice" }

--- The host helper is switched on (the sandbox option ZeD.HostHelper).
function H.on()
    local z = SandboxVars and SandboxVars.ZeD
    return z ~= nil and z.HostHelper == true
end

-- the helper's own patterns: a name of 2 to 32 ASCII letters, digits, _ - or inner spaces; a Steam ID of 17 digits from 7656119;
-- a voice ban's name as a name, never starting with "-"
function H.okTarget(kind, s)
    if type(s) ~= "string" then return false end
    if kind == "sid" then return string.find(s, "^7656119%d%d%d%d%d%d%d%d%d%d$") ~= nil end
    if kind == "voice" and string.sub(s, 1, 1) == "-" then return false end
    if #s < 2 or #s > 32 or string.find(s, "[^A-Za-z0-9_%- ]") then return false end
    return string.sub(s, 1, 1) ~= " " and string.sub(s, -1) ~= " "
end

-- a role name the console takes: SetAccessLevelCommand reads it as (\w+), so 1 to 32 ASCII letters, digits or _
function H.okRole(s)
    return type(s) == "string" and #s >= 1 and #s <= 32 and string.find(s, "[^A-Za-z0-9_]") == nil
end

--- The helper may make this owed call: its act is on the allow-list and its target has the right shape. A SetRole only
--- when it is a lifted ban's restore (e.restore, set by the server in undoGame alone), with the role the server recorded
--- at the ban in its reason; a role change staff ask for is never the helper's.
function H.can(e)
    if e.act == "SetRole" then
        return e.restore == true and H.okTarget("user", e.target) and H.okRole(e.reason)
    end
    local kind = H.ACTS[e.act]
    return kind ~= nil and H.okTarget(kind, e.target)
end

-- this start's word: new at every server start, so ids a crash rolled back never meet the answers they had before
function H.epoch()
    if not H.word then H.word = tostring(getRandomUUID()) end
    return H.word
end

--- The helper is running: its last answers file is fresh (H.seen is that file's own time).
function H.alive(now) return H.seen ~= nil and now - H.seen <= ZeD.Adm.L.HELPER_ALIVE_S end

local function line(e)
    local reason = (string.gsub(tostring(e.reason or ""), "%c", " "))
    local f = { tostring(e.id), tostring(e.try or 1), e.act, e.target, reason }
    -- (a restore's mark is the line's last field: a line cut short loses it first, and the helper refuses a bare SetRole)
    if e.act == "SetRole" and e.restore == true then f[#f + 1] = "restore" end
    return table.concat(f, "\t")
end

--- The queue, rewritten when what it holds changed: every owed call the helper holds. True when the file says what it
--- should.
function H.write(md)
    local ids = {}
    for id, e in pairs(md.owed) do
        if e.helper and H.can(e) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    local out = { "ZEDQ 1 " .. H.epoch() }
    for _, id in ipairs(ids) do out[#out + 1] = line(md.owed[id]) end
    out[#out + 1] = H.END
    local text = table.concat(out, "\n") .. "\n"
    if text == H.wrote then return true end
    local w = getFileWriter(H.QUEUE, true, false)
    if not w then return false end
    w:write(text)
    w:close()
    H.wrote = text
    return true
end

--- The helper's answers for this world: a list of { id, try, res, text }. H.seen becomes the file's time. Nothing
--- there: {}
function H.read(md)
    local r = getFileReader(H.ANSWERS, false)
    if not r then return {} end
    local out = {}
    local head = r:readLine()
    local epoch, at = nil, nil
    if head then epoch, at = string.match(head, "^ZEDA 1 (%S+) (%d+)$") end
    if epoch == H.epoch() then
        H.seen = tonumber(at)
        for _ = 1, H.READ_MAX do
            local l = r:readLine()
            if not l then break end
            local id, try, res, text = string.match(l, "^(%d+)\t(%d+)\t(%a+)\t?(.*)$")
            if id then out[#out + 1] = { id = tonumber(id), try = tonumber(try), res = res, text = text } end
        end
    end
    r:close()
    return out
end

return H
