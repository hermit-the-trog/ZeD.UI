-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_LogProto.lua
-- ============================================================================
-- THE LOG'S PROTOCOL (ZeDUI/MP_ADMIN_SCOPE.md, Phase 4; MP_SERVER_PART_DESIGN.md, A5 and A6). What both sides agree on: the
-- module, the kinds, the windows of time, every limit, what a filter keeps, and how a line another mod wrote is read. Pure
-- Lua, ASCII, nothing client-only at load: this file also runs on a dedicated server.
-- ============================================================================

ZeD = ZeD or {}
ZeD.Lg = ZeD.Lg or {}
local Lg = ZeD.Lg

Lg.MOD = "ZeDL"

-- THE DIRECTOR'S QUESTIONS, answered the careful way, each kept to one switch (MP_SERVER_PART_DESIGN.md, the last section)
-- VIEW_CAP: who reads the log? The game gives its own PvP log to PVPLogTool and its user log to ReadUserLog; ZeD's log holds
-- both sorts of thing and answers griefing tickets, so it goes to whoever answers tickets. Lines from the game's PvP log also
-- need PVPLogTool, the game's own test for them.
Lg.VIEW_CAP = "AnswerTickets"
-- CONTAINER_LOG: the Container chip. Off until Phase 6's Server extras can turn it on and tell players it is on. Server Lua
-- never sees a container take (the game's transfer is Java), so nothing writes these lines yet: see the design notes.
Lg.CONTAINER_LOG = false
-- OWN_CAR_LINES: a line when someone works on the car they drove last? false: no, the ring is for what answers a griefing
-- ticket, and a mechanic pulling forty parts off their own car would push that out. A car with no last driver is logged.
Lg.OWN_CAR_LINES = false

-- the chips, in the drawing's order; "other" has no chip and shows under All (a line another mod wrote)
Lg.KINDS = { "admin", "safehouse", "faction", "vehicle", "pvp", "ticket", "container" }
Lg.KIND = {}
for _, k in ipairs(Lg.KINDS) do Lg.KIND[k] = true end
Lg.OTHER = "other"
-- the log's own word for the claims pass: its lines go under Safehouse
Lg.KIND_OF = { claims = "safehouse" }
function Lg.kindOf(k) return Lg.KIND_OF[k] or k end

Lg.WHEN = { hour = true, today = true, d3 = true }
Lg.WHENS = { "hour", "today", "d3" }
Lg.DEFAULT_WHEN = "today"

Lg.AROUND_BEFORE = 10800            -- three hours before a ticket was filed, seconds
Lg.AROUND_AFTER = 1800              -- half an hour after

Lg.L = {
    ROWS = 25,                      -- lines in one page
    NAMES_MAX = 100,                -- names on the Who list
    FIND_MAX = 64,
    QUERY_MS = 400,                 -- between one account's reads
    NOTE_MS = 1000,
    PVP_MAX = 400,                  -- the game's PvP lines kept, oldest out: a fight must not push ZeD's own lines out
    TAP_MAX = 300,                  -- lines from other mods kept, oldest out: any client can write these
    TAP_TEXT = 200,                 -- one such line, cut to this
    TAP_PER_MIN = 20,               -- one sender's lines kept in a minute; past that they still reach the game's log file
    VEH_PER_MIN = 30,               -- one player's vehicle lines in a minute
    DRIVERS_MAX = 3000,             -- cars remembered, oldest out
    POLL_S = 10,                    -- how often the server looks for who is driving, and reads the game's PvP log
    HOOK_MISS = 3,                  -- actions made with no complete seen: the fallback (A6, E2) goes on
    MISSED_MAX = 3,                 -- names the Around line says the ticket's nearby list missed
}

-- a client's word for a time window, as the first second it keeps. Today is the UTC date, as the card's dates are (E5)
function Lg.since(when, now)
    if when == "hour" then return now - 3600 end
    if when == "d3" then return now - 259200 end
    return math.floor(now / 86400) * 86400
end

-- the words a Find looks through, lower case; built once per line
function Lg.hay(l)
    local p = { l.who or "", l.what or "", l.target or "", l.text or "", l.car or "", l.part or "", l.lg or "" }
    if l.x then p[#p + 1] = tostring(l.x) .. " x " .. tostring(l.y) end
    return string.lower(table.concat(p, " "))
end

-- does this line pass the filter? q: kind (a chip), who, since, untilT, find (lower case), near { x, y, r }
function Lg.keep(l, q)
    if q.kind and Lg.kindOf(l.kind) ~= q.kind then return false end
    if q.who and l.who ~= q.who and l.target ~= q.who then return false end
    if q.since and l.t < q.since then return false end
    if q.untilT and l.t > q.untilT then return false end
    if q.near then
        if not l.x then return false end
        local dx, dy = l.x - q.near.x, l.y - q.near.y
        if dx * dx + dy * dy > q.near.r * q.near.r then return false end
    end
    if q.find and not string.find(Lg.hay(l), q.find, 1, true) then return false end
    return true
end

-- newest first; s settles a tie in the same second
function Lg.newest(a, b)
    if a.t ~= b.t then return a.t > b.t end
    return (a.s or 0) > (b.s or 0)
end

-- a line another mod wrote, as the game's ClientActionLog writes them: [steamid][type][username][x,y,z][extra]. Nothing here
-- is proof, so nothing here decides anything but where the line shows. Returns type, user, x, y, z; any may be nil
function Lg.tapParse(text)
    local f, n = {}, 0
    for s in string.gmatch(text, "%[(.-)%]") do
        n = n + 1
        f[n] = s
        if n >= 8 then break end
    end
    for i = 1, n do
        local x, y, z = string.match(f[i], "^(-?%d+),(-?%d+),(-?%d+)$")
        if x then return f[i - 2], f[i - 1], tonumber(x), tonumber(y), tonumber(z) end
    end
    return nil, nil, nil, nil, nil
end

-- which chip a logger's line shows under
local TAP_KIND = { vehicle = "vehicle", safehouse = "safehouse", pvp = "pvp", admin = "admin" }
function Lg.tapKind(logger, kindWord)
    local k = TAP_KIND[string.lower(logger or "")]
    if k then return k end
    if kindWord and string.find(kindWord, "Vehicle", 1, true) then return "vehicle" end
    return Lg.OTHER
end

-- a logger's name with its case and punctuation ignored, for the test that it isn't ZeD's own
function Lg.plainName(s)
    return (string.gsub(string.lower(s), "[^%a]", ""))
end

-- "11-05 20:26 UTC": a note's time, in words the server can write itself (E5)
function Lg.stamp(t)
    local ok, d = pcall(os.date, "*t", t)
    if not ok or type(d) ~= "table" then return tostring(t) end
    return string.format("%02d-%02d %02d:%02d UTC", d.month or 0, d.day or 0, d.hour or 0, d.min or 0)
end

return Lg
