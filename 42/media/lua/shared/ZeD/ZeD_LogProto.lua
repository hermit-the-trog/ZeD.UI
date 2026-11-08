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
-- OWN_CAR_LINES: a line when someone works on their own car? false: no, the ring is for what answers a griefing ticket, and a
-- mechanic pulling forty parts off their own car would push that out. A car is yours once you have held it for SETTLE_S: until
-- then it stays the driver's before you, so a thief's strip job still writes lines naming the owner. Work on a car nobody has
-- on record is logged too, in a ring of its own (VEH_MAX), so scavenging can't push out ZeD's other lines.
Lg.OWN_CAR_LINES = false

-- the chips, in the drawing's order; "other" has no chip and shows under All (a line another mod wrote). The drawing is from before
-- community: its chip stands with the kinds always there, ahead of Container, the one that comes and goes
Lg.KINDS = { "admin", "safehouse", "faction", "vehicle", "pvp", "ticket", "community", "container" }
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
    TAP_FIELDS = 8,                 -- bracket fields read from one such line
    MAP_MAX = 60000,                -- a line's place past this is no place
    VEH_PER_MIN = 30,               -- one player's vehicle lines in a minute; "drove off" and tows are not counted
    VEH_MAX = 1000,                 -- work on cars with no owner on record, oldest out
    TOW_PER_MIN = 4,                -- tow commands one player can have looked at in a minute
    TOW_REPEAT_S = 300,             -- one tow line for one player and pair of cars in this long
    TOW_REACH = 10,                 -- tiles from the player to each car, the game's own warning distance
    SETTLE_S = 86400,               -- how long a new driver holds a car before it counts as theirs
    DRIVERS_MAX = 3000,             -- cars remembered, oldest out
    POLL_S = 10,                    -- how often the server looks for who is driving, and reads the game's PvP log
    HOOK_MISS = 3,                  -- actions made with no wrap of ours ever reached: the fallback (A6, E2) goes on
    HOOK_WAIT_S = 120,              -- and this long since the first: an action still under way has reached nothing yet
    CODES_MAX = 16,                 -- codes one Find sends
    CODE_TEXT = 40,
    MISSED_MAX = 3,                 -- names the Around line says the ticket's nearby list missed
}

-- a client's word for a time window, as the first second it keeps. Today is the UTC date, as the card's dates are (E5)
function Lg.since(when, now)
    if when == "hour" then return now - 3600 end
    if when == "d3" then return now - 259200 end
    return math.floor(now / 86400) * 86400
end

-- the words a Find looks through, lower case. say: the line in words (Lg.lineWords), so Find reaches what the card shows as
-- well as the codes
function Lg.hay(l, say)
    local p = { l.who or "", l.what or "", l.target or "", l.text or "", l.car or "", l.part or "", l.lg or "", l.by or "", l.via or "", say or "" }
    if l.x then p[#p + 1] = tostring(l.x) .. " x " .. tostring(l.y) end
    return string.lower(table.concat(p, " "))
end

-- does this line pass the filter? q: kind (a chip), who, since, untilT, near { x, y, r }, find (lower case); hay, a function that
-- gives a line's words; codes, what the viewer's own words for find came to (Lg.findCodes)
function Lg.keep(l, q)
    if q.kind and Lg.kindOf(l.kind) ~= q.kind then return false end
    if q.who and l.who ~= q.who and l.target ~= q.who and l.by ~= q.who and l.via ~= q.who then return false end
    if q.since and l.t < q.since then return false end
    if q.untilT and l.t > q.untilT then return false end
    if q.near then
        if not l.x then return false end
        local dx, dy = l.x - q.near.x, l.y - q.near.y
        if dx * dx + dy * dy > q.near.r * q.near.r then return false end
    end
    if q.find then
        local hay = q.hay and q.hay(l) or Lg.hay(l)
        if not string.find(hay, q.find, 1, true) and not (q.codes and l.what and q.codes[l.what]) then return false end
    end
    return true
end

-- newest first; s settles a tie in the same second
function Lg.newest(a, b)
    if a.t ~= b.t then return a.t > b.t end
    return (a.s or 0) > (b.s or 0)
end

-- the game's own loggers: its chatter, not another mod's lines. ClientActionLog says who got in a car, each line opening with
-- the Steam ID; PerkLog the same for logins and levels. Both reach the game's files, and the Log leaves them out
Lg.GAME_LOGGERS = { ClientActionLog = true, PerkLog = true }

-- a client's whole number, kept only inside the map
local function inMap(n, lo, hi)
    n = tonumber(n)
    if not n or n < lo or n > hi then return nil end
    return n
end

-- a line another mod wrote, as the game's ClientActionLog writes them: [steamid][type][username][x,y,z][extra]. Nothing here
-- is proof, so nothing here decides anything but where the line shows. Any client can send this text and it runs on the
-- server's main loop, so it is cut first and read with plain finds in one pass, never a pattern over the whole line.
-- Returns type, user, x, y, z, rest; any may be nil. rest is what the card may print: the fields after the place, or with no
-- place the line without a leading all-digit field. A place lives in x, y and z alone and a Steam ID is left out, so the
-- rule on a higher role's place holds for these lines and no ID reaches a reader
function Lg.tapParse(text)
    text = string.sub(text, 1, 2 * Lg.L.TAP_TEXT)
    local f, ends, n, at = {}, {}, 0, 1
    while n < Lg.L.TAP_FIELDS do
        local a = string.find(text, "[", at, true)
        local b = a and string.find(text, "]", a + 1, true)
        if not b then break end
        n = n + 1
        f[n], ends[n] = string.sub(text, a + 1, b - 1), b
        at = b + 1
    end
    for i = 1, n do
        local x, y, z = string.match(f[i], "^(-?%d+),(-?%d+),(-?%d+)$")
        if x then
            local max = Lg.L.MAP_MAX
            local kx, ky, kz = inMap(x, 0, max), inMap(y, 0, max), inMap(z, -32, 32)
            if not (kx and ky and kz) then kx, ky, kz = nil, nil, nil end
            local word = f[i - 2]
            if word and string.match(word, "^%d+$") then word = nil end
            return word, f[i - 1], kx, ky, kz, string.sub(text, ends[i] + 1)
        end
    end
    if n > 0 and string.sub(text, 1, 1) == "[" and string.match(f[1], "^%d+$") then text = string.sub(text, ends[1] + 1) end
    return nil, nil, nil, nil, nil, text
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

-- ---------------------------------------------------------------------------
-- A LINE IN WORDS. One reading of the codes for three readers: the card, in the viewer's language (ZeD_Log.lua), and the server's
-- Find and notes, in the plain English of Lg.EN. A code with no words here reads as the server wrote it, which is how a later
-- ZeD's lines and the server's own reports show. c holds what differs between them:
--   c.w(key, ...)        the words for a key
--   c.name(prefix, id)   the game's name for a car, a part or a power, or the id
--   c.kind(k)            a ticket kind's word
--   c.item(fullType)     an item's name
-- r is a row of the view (k) or a line of a ring (kind).
-- ---------------------------------------------------------------------------
local function quoted(s) return "\"" .. tostring(s) .. "\"" end

-- "Kade_R's Chevalier D6", or "a Chevalier D6" with no owner on record
local function carWords(r, c)
    local car = r.car and c.name("IGUI_VehicleName", r.car) or c.w("UI_ZeD_Log_ACar")
    if r.target then return c.w("UI_ZeD_Log_CarOf", tostring(r.target), car) end
    return c.w("UI_ZeD_Log_CarNone", car)
end

-- a ban line's target, which the server leaves off for a reader who can't see IP addresses and Steam IDs
local function banTarget(r, c) return r.target and tostring(r.target) or c.w("UI_ZeD_Log_AnAddress") end

-- every fixed code and its words; Lg.findCodes reads this for the viewer's language
Lg.VEH = { smash = "UI_ZeD_Log_V_Smash", eparts = "UI_ZeD_Log_V_Eparts", siphon = "UI_ZeD_Log_V_Siphon", strip = "UI_ZeD_Log_V_Strip",
    drive = "UI_ZeD_Log_V_Drive", hotwire = "UI_ZeD_Log_V_Hotwire", tow = "UI_ZeD_Log_V_Tow" }
-- the server extras' lines (ZeD_ServerExtras.lua): a claim on a car, and what a claim or a safehouse refused. A claim's car is r.car;
-- its target is the owner, on a refusal and on a release by staff
Lg.CLAIM = { claim = "UI_ZeD_Log_V_Claim", release = "UI_ZeD_Log_V_Release", ["claim lapsed"] = "UI_ZeD_Log_V_Lapsed",
    ["claim gone: burnt"] = "UI_ZeD_Log_V_ClaimBurnt", ["claim gone: that car is gone"] = "UI_ZeD_Log_V_ClaimGone",
    ["refused: parts"] = "UI_ZeD_Log_V_NoParts", ["refused: drive"] = "UI_ZeD_Log_V_NoDrive", ["refused: tow"] = "UI_ZeD_Log_V_NoTow" }
Lg.HOUSE_NO = { ["refused: dismantle"] = "UI_ZeD_Log_S_NoDismantle", ["refused: destroy"] = "UI_ZeD_Log_S_NoDestroy" }
-- lines that carry the car's place with whoever they name anywhere, or off the server. They say nothing of who stood there
Lg.NOT_THERE = { release = true, ["claim lapsed"] = true, ["claim gone: burnt"] = true, ["claim gone: that car is gone"] = true }
-- what ZeD_ServerExtras.lua puts after a container line in the file. The words here say it in the viewer's language
Lg.TOLD = " (reported by their game)"
Lg.TICKET = { filed = "UI_ZeD_Log_T_Filed", ["player added to it"] = "UI_ZeD_Log_T_Added", seen = "UI_ZeD_Log_T_Seen", taken = "UI_ZeD_Log_T_Taken",
    answered = "UI_ZeD_Log_T_Answered", ["note added"] = "UI_ZeD_Log_T_Note", closed = "UI_ZeD_Log_T_Closed", reopened = "UI_ZeD_Log_T_Reopened",
    ["marked spam"] = "UI_ZeD_Log_T_Spam", ["not spam"] = "UI_ZeD_Log_T_NotSpam", deleted = "UI_ZeD_Log_T_Deleted",
    ["removed on the game's window"] = "UI_ZeD_Log_T_Removed" }
-- what is done to a report from chat (ZeD_ServerTickets.lua). Its target is the player the report names, its detail "ticket 14"
Lg.REPORT = { ["report answered"] = "UI_ZeD_Log_T_RepAnswered", ["report closed"] = "UI_ZeD_Log_T_RepClosed",
    ["report marked spam"] = "UI_ZeD_Log_T_RepSpam", ["report deleted"] = "UI_ZeD_Log_T_RepDeleted" }
-- community's lines (ZeD_ServerCommunity.lua). The details hold the numbers, and a post's words after its number
Lg.COMMUNITY = { ["rules saved"] = "UI_ZeD_Log_C_Saved", ["rules not answered"] = "UI_ZeD_Log_C_NoAnswer", ["news posted"] = "UI_ZeD_Log_C_Post",
    ["news deleted"] = "UI_ZeD_Log_C_Del", ["news pushed off the board"] = "UI_ZeD_Log_C_Pushed", ["news pinned"] = "UI_ZeD_Log_C_Pin",
    ["news unpinned"] = "UI_ZeD_Log_C_Unpin" }

local WHAT = {}
function WHAT.vehicle(r, c)
    local s
    if r.what == "part" then
        s = c.w("UI_ZeD_Log_V_Part", r.part and c.name("IGUI_VehiclePart", r.part) or c.w("UI_ZeD_Log_APart"), carWords(r, c))
    elseif r.what == "dropped" then
        return c.w("UI_ZeD_Log_V_Dropped", tostring(r.text))
    elseif Lg.VEH[r.what] then
        s = c.w(Lg.VEH[r.what], carWords(r, c))
    elseif Lg.CLAIM[r.what] then
        return c.w(Lg.CLAIM[r.what], carWords(r, c))
    else
        return nil
    end
    if r.locked then s = c.w("UI_ZeD_Log_V_Locked", s) end
    return s
end

function WHAT.pvp(r, c)
    if r.what == "kill" then return c.w("UI_ZeD_Log_P_Kill", tostring(r.target)) end
    if r.what == "hit" then
        if r.text then return c.w("UI_ZeD_Log_P_HitWith", tostring(r.target), r.text) end
        return c.w("UI_ZeD_Log_P_Hit", tostring(r.target))
    end
    return nil
end

function WHAT.ticket(r, c)
    if r.what == "tickets full" then return c.w("UI_ZeD_Log_T_Full", tostring(r.text)) end
    if Lg.REPORT[r.what] then
        local id = string.match(r.text or "", "(%d+)")
        if not (id and r.target) then return nil end
        return c.w(Lg.REPORT[r.what], tostring(r.target), id)
    end
    if r.what == "adopted from the game's window" and r.target then
        -- (the name came with the game's row: a claim, so the line says so and nothing counts it as theirs)
        local kind, name = string.match(r.text or "", "^([^:]*): (.*)$")
        if kind then return c.w("UI_ZeD_Log_T_Adopted", r.target, c.kind(kind), name) end
    end
    local key = Lg.TICKET[r.what]
    if not key or not r.target then return nil end
    return c.w(key, r.target, c.kind(r.text))
end

-- a claim line's code; "title Riverside" and "owner from Rosa" carry their word
local function claimWords(r, c, onFaction)
    local what, w = r.what or "", c.w
    if Lg.HOUSE_NO[what] then return w(Lg.HOUSE_NO[what], tostring(r.target)) end
    if what == "claim" then return w("UI_ZeD_Log_S_Claim") end
    if what == "release" then return w("UI_ZeD_Log_S_Release") end
    if what == "member in" then
        if onFaction then return w("UI_ZeD_Log_F_In", tostring(r.target)) end
        return w("UI_ZeD_Log_S_In")
    end
    if what == "member out" then
        if onFaction then return w("UI_ZeD_Log_F_Out", tostring(r.target)) end
        return w("UI_ZeD_Log_S_Out")
    end
    if what == "create" then return w("UI_ZeD_Log_F_Create", tostring(r.target)) end
    if what == "disband" then return w("UI_ZeD_Log_F_Disband", tostring(r.target)) end
    if what == "invite cancelled" then return w("UI_ZeD_Log_InviteCancelled", tostring(r.target)) end
    local title = string.match(what, "^title (.*)$")
    if title then return w("UI_ZeD_Log_S_Title", quoted(title)) end
    local from = string.match(what, "^owner from (.*)$")
    if from then
        if onFaction then return w("UI_ZeD_Log_F_Owner", tostring(r.target), from) end
        return w("UI_ZeD_Log_S_Owner", from)
    end
    local name = string.match(what, "^name from (.*)$")
    if name then return w("UI_ZeD_Log_F_Name", quoted(name), tostring(r.target)) end
    local tag = string.match(what, "^tag (.*)$")
    if tag then return w("UI_ZeD_Log_F_Tag", tostring(r.target), quoted(tag)) end
    return nil
end
function WHAT.safehouse(r, c) return claimWords(r, c, false) end
function WHAT.faction(r, c) return claimWords(r, c, true) end

-- a take a player's own game reported: the only kind of line that isn't the server's own word, and the words say so
function WHAT.container(r, c)
    if r.what ~= "took" then return nil end
    local s = tostring(r.text)
    if string.sub(s, -#Lg.TOLD) == Lg.TOLD then s = string.sub(s, 1, -#Lg.TOLD - 1) end
    return c.w("UI_ZeD_Log_Took", s)
end

-- a post's words go on one line, as the file has them
local function oneLine(s) return (string.gsub(s, "\n", " ")) end

function WHAT.community(r, c)
    local what, text = r.what or "", r.text or ""
    if what == "rules not answered" then return c.w(Lg.COMMUNITY[what]) end
    if what == "rules saved" then
        local n, fresh = string.match(text, "^(%d+) rules, (%d+) new or changed")
        if not n then return nil end
        local s = c.w(Lg.COMMUNITY[what], n, fresh)
        if string.find(text, ", message or appeal changed", 1, true) then s = c.w("UI_ZeD_Log_C_SavedMsg", s) end
        return s
    end
    local id, rest = string.match(text, "^#(%d+)(.*)$")
    if not (id and Lg.COMMUNITY[what]) then return nil end
    if what == "news pinned" or what == "news unpinned" then return c.w(Lg.COMMUNITY[what], id) end
    if what == "news pushed off the board" then
        local by, words = string.match(rest, "^ by (.-): (.*)$")
        if not by then return nil end
        return c.w(Lg.COMMUNITY[what], id, by, quoted(oneLine(words)))
    end
    local words = string.match(rest, "^: (.*)$")
    if not words then return nil end
    return c.w(Lg.COMMUNITY[what], id, quoted(oneLine(words)))
end

local LEN_WORD = { permanent = "UI_ZeD_Adm_LenPerm", h1 = "UI_ZeD_Adm_Len1h", d1 = "UI_ZeD_Adm_Len1d", d3 = "UI_ZeD_Adm_Len3d", w1 = "UI_ZeD_Adm_Len1w" }
local ROLE_ACT = { add = "UI_ZeD_Log_A_RoleAdd", save = "UI_ZeD_Log_A_RoleSave", delete = "UI_ZeD_Log_A_RoleDelete",
    default = "UI_ZeD_Log_A_RoleDefault", up = "UI_ZeD_Log_A_RoleUp", down = "UI_ZeD_Log_A_RoleDown" }
local ADMIN = {}
Lg.ADMIN = ADMIN
ADMIN["teleport to"] = function(r, c) return c.w("UI_ZeD_Log_A_Tp", tostring(r.target)) end
ADMIN["teleport to you"] = function(r, c) return c.w("UI_ZeD_Log_A_Bring", tostring(r.target)) end
ADMIN["kick"] = function(r, c) return c.w("UI_ZeD_Log_A_Kick", tostring(r.target), quoted(r.text)) end
ADMIN["warning points"] = function(r, c)
    local n, why = string.match(r.text or "", "^(%d+): (.*)$")
    if not n then return nil end
    return c.w((n == "1") and "UI_ZeD_Log_A_Warn1" or "UI_ZeD_Log_A_Warn", n, tostring(r.target), quoted(why))
end
ADMIN["mute"] = function(r, c) return c.w("UI_ZeD_Log_A_Mute", tostring(r.target)) end
ADMIN["unmute"] = function(r, c) return c.w("UI_ZeD_Log_A_Unmute", tostring(r.target)) end
ADMIN["role"] = function(r, c) return c.w("UI_ZeD_Log_A_Role", tostring(r.target), tostring(r.text)) end
ADMIN["level up"] = function(r, c) return c.w("UI_ZeD_Log_A_LevelUp", tostring(r.target), tostring(r.text)) end
ADMIN["level down"] = function(r, c) return c.w("UI_ZeD_Log_A_LevelDown", tostring(r.target), tostring(r.text)) end
ADMIN["ban"] = function(r, c)
    local len, why = string.match(r.text or "", "^(.-): (.*)$")
    if not len then return nil end
    return c.w("UI_ZeD_Log_A_Ban", banTarget(r, c), c.w(LEN_WORD[len] or LEN_WORD.permanent), quoted(why))
end
ADMIN["unban"] = function(r, c) return c.w("UI_ZeD_Log_A_Unban", banTarget(r, c)) end
ADMIN["ban lifted"] = function(r, c) return c.w("UI_ZeD_Log_A_Lifted", banTarget(r, c)) end
-- via: the staff client whose look at the game's user list showed it (the server's lines from before this build have none)
ADMIN["ban lifted in the game"] = function(r, c)
    if r.via then return c.w("UI_ZeD_Log_A_LiftedGameBy", banTarget(r, c), tostring(r.via)) end
    return c.w("UI_ZeD_Log_A_LiftedGame", banTarget(r, c))
end
ADMIN["ip ban lifted in the game"] = function(r, c) return c.w("UI_ZeD_Log_A_IpLiftedGame", tostring(r.target)) end
ADMIN["game ban"] = function(r, c) return c.w("UI_ZeD_Log_A_GameBan", banTarget(r, c), quoted(r.text)) end
ADMIN["server message"] = function(r, c) return c.w("UI_ZeD_Log_A_Msg", quoted(r.text)) end
ADMIN["repeating message"] = function(r, c) return c.w("UI_ZeD_Log_A_Repeat", tostring(r.text)) end
ADMIN["repeating message stopped"] = function(r, c) return c.w("UI_ZeD_Log_A_RepeatStop") end
-- "10 x Base.Bandage to Rosa"; "me" and "ground" are as the one who did it said them
ADMIN["spawn"] = function(r, c)
    local n, item, to = string.match(r.text or "", "^(%d+) x (%S+) to (.*)$")
    if not n then return nil end
    local name = c.item(item)
    if to == "me" then return c.w("UI_ZeD_Log_A_SpawnSelf", n, name) end
    if to == "ground" then return c.w("UI_ZeD_Log_A_SpawnGround", n, name) end
    return c.w("UI_ZeD_Log_A_Spawn", n, name, to)
end
ADMIN["refused"] = function(r, c)
    local what = string.match(r.text or "", "^has no right to (.*)$")
    if not what then return nil end
    return c.w("UI_ZeD_Log_A_Refused", what)
end
ADMIN["rate limit"] = function(r, c)
    local n = string.match(r.text or "", "(%d+) dropped")
    if not n then return nil end
    return c.w("UI_ZeD_Log_A_Rate", n)
end
ADMIN["bad arguments"] = function(r, c) return c.w("UI_ZeD_Log_A_Bad", tostring(r.text)) end
ADMIN["server extras"] = function(r, c) return c.w("UI_ZeD_Log_A_Extras", tostring(r.text)) end
ADMIN["map teleport"] = function(r, c) return c.w("UI_ZeD_Log_A_MapTp") end

function WHAT.admin(r, c)
    local fn = ADMIN[r.what]
    if fn then return fn(r, c) end
    local what = r.what or ""
    local power = string.match(what, "^power on: (.*)$")
    if power then return c.w("UI_ZeD_Log_A_PowerOn", c.name("IGUI_CheatPanel_", power)) end
    power = string.match(what, "^power off: (.*)$")
    if power then return c.w("UI_ZeD_Log_A_PowerOff", c.name("IGUI_CheatPanel_", power)) end
    local act = string.match(what, "^roles: (.*)$")
    if act and ROLE_ACT[act] then return c.w(ROLE_ACT[act], tostring(r.target)) end
    return nil
end

-- as the server wrote it, and how any code from a later ZeD reads
local function rawWords(r)
    local s = r.what or ""
    if r.target then s = (s == "") and tostring(r.target) or (s .. " " .. tostring(r.target)) end
    if r.text then s = (s == "") and tostring(r.text) or (s .. ": " .. tostring(r.text)) end
    return s
end

-- what the line says happened, after the name of who did it
function Lg.lineWords(r, c)
    local fn = WHAT[r.k or Lg.kindOf(r.kind)]
    if r.src ~= "tap" and fn then
        local ok, s = pcall(fn, r, c)
        if ok and s then return s end
    end
    return rawWords(r)
end

-- who did it. The server's own lines carry a name no account can hold (Tk.SYS); a tapped line's name is only what it claims
function Lg.whoWords(r, c)
    if r.who == ZeD.Tk.SYS and r.src ~= "tap" then return c.w("UI_ZeD_Log_TheServer") end
    return tostring(r.who or "")
end

-- the English the server writes for itself: the game's language files can't be counted on for a mod's keys on a dedicated
-- server. These are the EN file's words (log_sim.lua holds them to it)
Lg.EN = {
    UI_ZeD_Log_TheServer = "Server:", UI_ZeD_Log_AnAddress = "a hidden address", UI_ZeD_Log_ACar = "car", UI_ZeD_Log_APart = "a part",
    UI_ZeD_Log_CarOf = "%1's %2", UI_ZeD_Log_CarNone = "a %1",
    UI_ZeD_Log_V_Smash = "smashed a window of %1", UI_ZeD_Log_V_Part = "removed the %1 from %2", UI_ZeD_Log_V_Eparts = "took engine parts from %1",
    UI_ZeD_Log_V_Siphon = "siphoned gas from %1", UI_ZeD_Log_V_Strip = "stripped %1", UI_ZeD_Log_V_Drive = "drove off in %1",
    UI_ZeD_Log_V_Hotwire = "hotwired %1", UI_ZeD_Log_V_Tow = "hooked %1 up to tow", UI_ZeD_Log_V_Locked = "%1 (locked)",
    UI_ZeD_Log_V_Dropped = "had %1 more vehicle lines not kept, over the limit for one minute",
    UI_ZeD_Log_V_Claim = "claimed %1", UI_ZeD_Log_V_Release = "released %1", UI_ZeD_Log_V_Lapsed = "lost the claim on %1, away too long",
    UI_ZeD_Log_V_ClaimBurnt = "lost the claim on %1, it burned", UI_ZeD_Log_V_ClaimGone = "lost the claim on %1, the car is gone",
    UI_ZeD_Log_V_NoParts = "was refused taking parts from %1", UI_ZeD_Log_V_NoDrive = "was refused driving %1", UI_ZeD_Log_V_NoTow = "was refused towing %1",
    UI_ZeD_Log_S_NoDismantle = "was refused dismantling in %1's safehouse", UI_ZeD_Log_S_NoDestroy = "was refused breaking things in %1's safehouse",
    UI_ZeD_Log_Took = "took %1 (reported by their game)",
    UI_ZeD_Log_P_Kill = "killed %1", UI_ZeD_Log_P_Hit = "hit %1", UI_ZeD_Log_P_HitWith = "hit %1 with %2",
    UI_ZeD_Log_T_Filed = "filed %1 %2", UI_ZeD_Log_T_Added = "added to %1 %2", UI_ZeD_Log_T_Seen = "saw %1 %2", UI_ZeD_Log_T_Taken = "took %1 %2",
    UI_ZeD_Log_T_Answered = "answered %1 %2", UI_ZeD_Log_T_Note = "added a note to %1 %2", UI_ZeD_Log_T_Closed = "closed %1 %2",
    UI_ZeD_Log_T_Reopened = "reopened %1 %2", UI_ZeD_Log_T_Spam = "marked %1 %2 as spam", UI_ZeD_Log_T_NotSpam = "marked %1 %2 as not spam",
    UI_ZeD_Log_T_Deleted = "deleted %1 %2", UI_ZeD_Log_T_Adopted = "took in %1 %2 from the game's window, filed in the name of %3, not proved",
    UI_ZeD_Log_T_Removed = "removed %1 %2 on the game's window", UI_ZeD_Log_T_Full = "could not file a ticket, the tickets are full: %1",
    UI_ZeD_Log_T_RepAnswered = "answered the report on %1, ticket #%2", UI_ZeD_Log_T_RepClosed = "closed the report on %1, ticket #%2",
    UI_ZeD_Log_T_RepSpam = "marked the report on %1 as spam, ticket #%2", UI_ZeD_Log_T_RepDeleted = "deleted the report on %1, ticket #%2",
    UI_ZeD_Log_C_Saved = "saved the rules: %1 in all, %2 new or changed", UI_ZeD_Log_C_SavedMsg = "%1, and the message of the day or the appeal line",
    UI_ZeD_Log_C_NoAnswer = "was asked to agree to the rules and has not answered", UI_ZeD_Log_C_Post = "posted news #%1: %2",
    UI_ZeD_Log_C_Del = "deleted news #%1: %2", UI_ZeD_Log_C_Pushed = "pushed news #%1 by %2 off the board: %3", UI_ZeD_Log_C_Pin = "pinned news #%1",
    UI_ZeD_Log_C_Unpin = "unpinned news #%1",
    UI_ZeD_Log_S_Claim = "claimed a safehouse", UI_ZeD_Log_S_Release = "released a safehouse", UI_ZeD_Log_S_In = "joined the safehouse",
    UI_ZeD_Log_S_Out = "left the safehouse", UI_ZeD_Log_S_Title = "renamed the safehouse %1", UI_ZeD_Log_S_Owner = "took the safehouse over from %1",
    UI_ZeD_Log_F_In = "joined %1", UI_ZeD_Log_F_Out = "left %1", UI_ZeD_Log_F_Create = "created %1", UI_ZeD_Log_F_Disband = "disbanded %1",
    UI_ZeD_Log_F_Owner = "took %1 over from %2", UI_ZeD_Log_F_Name = "renamed %1 to %2", UI_ZeD_Log_F_Tag = "changed the tag of %1 to %2",
    UI_ZeD_Log_InviteCancelled = "cancelled the invitation to %1",
    UI_ZeD_Log_A_Tp = "teleported to %1", UI_ZeD_Log_A_Bring = "teleported %1 to them", UI_ZeD_Log_A_Kick = "kicked %1: %2",
    UI_ZeD_Log_A_Warn1 = "added %1 warning point to %2: %3", UI_ZeD_Log_A_Warn = "added %1 warning points to %2: %3",
    UI_ZeD_Log_A_Mute = "muted %1", UI_ZeD_Log_A_Unmute = "unmuted %1", UI_ZeD_Log_A_Role = "gave %1 the role %2",
    UI_ZeD_Log_A_LevelUp = "leveled %1 up: %2", UI_ZeD_Log_A_LevelDown = "leveled %1 down: %2", UI_ZeD_Log_A_Ban = "banned %1 (%2): %3",
    UI_ZeD_Log_A_Unban = "unbanned %1", UI_ZeD_Log_A_Lifted = "the ban on %1 ran out", UI_ZeD_Log_A_LiftedGame = "the ban on %1 was lifted in the game",
    UI_ZeD_Log_A_LiftedGameBy = "the ban on %1 was lifted in the game, seen by %2",
    UI_ZeD_Log_A_IpLiftedGame = "the IP ban on %1 was lifted in the game", UI_ZeD_Log_A_GameBan = "put the game's ban on %1: %2",
    UI_ZeD_Log_A_Msg = "sent a server message: %1", UI_ZeD_Log_A_Repeat = "set a repeating message, %1", UI_ZeD_Log_A_RepeatStop = "stopped a repeating message",
    UI_ZeD_Log_A_Spawn = "spawned %1 x %2 to %3", UI_ZeD_Log_A_SpawnSelf = "spawned %1 x %2 to themselves", UI_ZeD_Log_A_SpawnGround = "spawned %1 x %2 on the ground",
    UI_ZeD_Log_A_Refused = "tried a command they have no right to (%1)", UI_ZeD_Log_A_Rate = "went over the rate limit, %1 commands dropped so far",
    UI_ZeD_Log_A_Bad = "sent arguments no ZeD client sends (%1)", UI_ZeD_Log_A_PowerOn = "turned on %1", UI_ZeD_Log_A_PowerOff = "turned off %1",
    UI_ZeD_Log_A_RoleAdd = "added the role %1", UI_ZeD_Log_A_RoleSave = "changed the role %1", UI_ZeD_Log_A_RoleDelete = "deleted the role %1",
    UI_ZeD_Log_A_RoleDefault = "changed the default role to %1", UI_ZeD_Log_A_RoleUp = "moved the role %1 up", UI_ZeD_Log_A_RoleDown = "moved the role %1 down",
    UI_ZeD_Log_A_Extras = "changed the server extras: %1", UI_ZeD_Log_A_MapTp = "teleported by the map",
    UI_ZeD_Adm_LenPerm = "Permanent", UI_ZeD_Adm_Len1h = "1 hour", UI_ZeD_Adm_Len1d = "1 day", UI_ZeD_Adm_Len3d = "3 days", UI_ZeD_Adm_Len1w = "1 week",
}

function Lg.enWords(key, ...)
    local args = { ... }
    return (string.gsub(Lg.EN[key] or key, "%%(%d)", function(n) return tostring(args[tonumber(n)]) end))
end

-- a ticket's kind in the server's words: the card says it through ZeD_TicketCards
Lg.KIND_EN = { BUG = "Bug", GRIEF = "Griefing", STUCK = "Stuck", QUESTION = "Question", APPEAL = "Appeal", OTHER = "Other" }

-- the codes whose words hold what was typed, in the viewer's language: the server's hay is English, so a translated client's
-- words reach their lines this way. A word with no code, a car's name in another language, stays out of Find's reach
local CODE_KEY = { kill = "UI_ZeD_Log_P_Kill", hit = "UI_ZeD_Log_P_Hit", claim = "UI_ZeD_Log_S_Claim", release = "UI_ZeD_Log_S_Release",
    ["member in"] = "UI_ZeD_Log_S_In", ["member out"] = "UI_ZeD_Log_S_Out", create = "UI_ZeD_Log_F_Create", disband = "UI_ZeD_Log_F_Disband",
    ["teleport to"] = "UI_ZeD_Log_A_Tp", ["teleport to you"] = "UI_ZeD_Log_A_Bring", kick = "UI_ZeD_Log_A_Kick", mute = "UI_ZeD_Log_A_Mute",
    unmute = "UI_ZeD_Log_A_Unmute", role = "UI_ZeD_Log_A_Role", ban = "UI_ZeD_Log_A_Ban", unban = "UI_ZeD_Log_A_Unban",
    ["warning points"] = "UI_ZeD_Log_A_Warn", spawn = "UI_ZeD_Log_A_Spawn", part = "UI_ZeD_Log_V_Part" }
for code, key in pairs(Lg.VEH) do CODE_KEY[code] = key end
for code, key in pairs(Lg.TICKET) do CODE_KEY[code] = key end
for code, key in pairs(Lg.HOUSE_NO) do CODE_KEY[code] = key end
for code, key in pairs(Lg.REPORT) do CODE_KEY[code] = key end
for code, key in pairs(Lg.COMMUNITY) do CODE_KEY[code] = key end
CODE_KEY.took = "UI_ZeD_Log_Took"

function Lg.findCodes(find, w)
    local low = string.lower(find)
    local out, n = {}, 0
    local function look(code, key)
        if n < Lg.L.CODES_MAX and string.find(string.lower(w(key, "", "", "")), low, 1, true) then
            n = n + 1
            out[n] = code
        end
    end
    for code, key in pairs(CODE_KEY) do look(code, key) end
    -- ("claim" and "release" are words for a safehouse and for a car: one code, two sets of words)
    for code, key in pairs(Lg.CLAIM) do look(code, key) end
    return (n > 0) and out or nil
end

-- "11-05 20:26 UTC": a note's time, in words the server can write itself (E5)
function Lg.stamp(t)
    local ok, d = pcall(os.date, "*t", t)
    if not ok or type(d) ~= "table" then return tostring(t) end
    return string.format("%02d-%02d %02d:%02d UTC", d.month or 0, d.day or 0, d.hour or 0, d.min or 0)
end

return Lg
