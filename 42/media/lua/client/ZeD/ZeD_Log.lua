-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Log.lua
-- ============================================================================
-- THE LOG, THE CLIENT'S MODEL (ZeDUI/MP_ADMIN_SCOPE.md, Phase 4). No drawing: ZeD_LogCards.lua reads this and calls it. The
-- server holds the log and filters it (ZeD_ServerLog.lua); a page comes back as l_page, and the words for a line are built here,
-- from the server's codes, so a line reads in the viewer's language. A code this file has no words for reads as the server wrote it.
--
-- Without the server part there is no log to read: the Admin tab's row opens the game's own PvP log instead.
--
-- QA, read at call time (the ticket cards' style):
--   Lm.qaLink   true / false: the server part as the cards read it
--   Lm.qaHold   true: no traffic. The screen shows only what the QA script put in Lm.page
-- ============================================================================

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_LogProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/ZeD_Tickets"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.Logs = ZeD.Logs or {}
local Lm = ZeD.Logs
local S = ZeD.ServerPart
local Tk = ZeD.Tk
local Lg = ZeD.Lg
local C = ZeD.Tickets

Lm.seq = Lm.seq or 0                  -- bumps on every change (the card re-reads)
Lm.qid = Lm.qid or 0                  -- the read being waited for: an older page is dropped

local function tr(k, ...) return ZeD.tr(k, ...) end
function Lm.bump() Lm.seq = Lm.seq + 1 end

function Lm.live()
    if Lm.qaLink ~= nil then return Lm.qaLink end
    return S.available() and S.lg == true
end

-- q: kind, who, when, find, page, around. Refused, cb gets the answer
function Lm.ask(q, cb)
    if Lm.qaHold then return end
    Lm.qid = Lm.qid + 1
    Lm.waiting = true
    C.requestOn(Lg.MOD, "l_query", { qid = Lm.qid, kind = q.kind, who = q.who, when = q.when, find = q.find, page = q.page, around = q.around }, function(a)
        if a.ok == false then
            Lm.waiting = nil
            Lm.bump()
            if cb then cb(a) end
        end
    end)
end

function Lm.close()
    Lm.page, Lm.waiting = nil, nil
    Lm.qid = Lm.qid + 1
end

function Lm.toNote(id, s, cb) return C.requestOn(Lg.MOD, "l_tonote", { id = id, s = s }, cb) end

S.on(Lg.MOD, function(command, args)
    if command == "l_page" then
        if args.qid ~= Lm.qid then return end
        Lm.page = args
        Lm.waiting = nil
        Lm.bump()
    elseif command == "l_probe" then
        Lm.probe = args
        Lm.bump()
    end
end)

-- ---------------------------------------------------------------------------
-- A LINE IN WORDS
-- ---------------------------------------------------------------------------
local function quoted(s) return "\"" .. tostring(s) .. "\"" end

local function vanillaWord(prefix, name)
    if not name then return nil end
    local s = getTextOrNull and getTextOrNull(prefix .. name) or nil
    return s or name
end

-- "Kade_R's Chevalier D6", or "a Chevalier D6" with no owner on record
local function carWords(r)
    local car = vanillaWord("IGUI_VehicleName", r.car) or tr("UI_ZeD_Log_ACar")
    if r.target then return tr("UI_ZeD_Log_CarOf", tostring(r.target), car) end
    return tr("UI_ZeD_Log_CarNone", car)
end

local WHAT = {}
-- what a vehicle line says; the part's name is the game's
local VEH = { smash = "UI_ZeD_Log_V_Smash", eparts = "UI_ZeD_Log_V_Eparts", siphon = "UI_ZeD_Log_V_Siphon", strip = "UI_ZeD_Log_V_Strip",
    drive = "UI_ZeD_Log_V_Drive", hotwire = "UI_ZeD_Log_V_Hotwire", tow = "UI_ZeD_Log_V_Tow" }
function WHAT.vehicle(r)
    local s
    if r.what == "part" then
        s = tr("UI_ZeD_Log_V_Part", vanillaWord("IGUI_VehiclePart", r.part) or tr("UI_ZeD_Log_APart"), carWords(r))
    elseif VEH[r.what] then
        s = tr(VEH[r.what], carWords(r))
    else
        return nil
    end
    if r.locked then s = tr("UI_ZeD_Log_V_Locked", s) end
    return s
end

function WHAT.pvp(r)
    if r.what == "kill" then return tr("UI_ZeD_Log_P_Kill", tostring(r.target)) end
    if r.what == "hit" then
        if r.text then return tr("UI_ZeD_Log_P_HitWith", tostring(r.target), r.text) end
        return tr("UI_ZeD_Log_P_Hit", tostring(r.target))
    end
    return nil
end

local TICKET = { filed = "UI_ZeD_Log_T_Filed", ["player added to it"] = "UI_ZeD_Log_T_Added", seen = "UI_ZeD_Log_T_Seen", taken = "UI_ZeD_Log_T_Taken",
    answered = "UI_ZeD_Log_T_Answered", ["note added"] = "UI_ZeD_Log_T_Note", closed = "UI_ZeD_Log_T_Closed", reopened = "UI_ZeD_Log_T_Reopened",
    ["marked spam"] = "UI_ZeD_Log_T_Spam", ["not spam"] = "UI_ZeD_Log_T_NotSpam", deleted = "UI_ZeD_Log_T_Deleted",
    ["adopted from the game's window"] = "UI_ZeD_Log_T_Adopted", ["removed on the game's window"] = "UI_ZeD_Log_T_Removed" }
function WHAT.ticket(r)
    local key = TICKET[r.what]
    if not key or not r.target then return nil end
    return tr(key, r.target, ZeD.TicketCards and ZeD.TicketCards.kindWord(r.text) or tostring(r.text))
end

-- a claim line's code; "title Riverside" and "owner from Rosa" carry their word
local function claimWords(r, onFaction)
    local what = r.what or ""
    if what == "claim" then return tr("UI_ZeD_Log_S_Claim") end
    if what == "release" then return tr("UI_ZeD_Log_S_Release") end
    if what == "member in" then
        if onFaction then return tr("UI_ZeD_Log_F_In", tostring(r.target)) end
        return tr("UI_ZeD_Log_S_In")
    end
    if what == "member out" then
        if onFaction then return tr("UI_ZeD_Log_F_Out", tostring(r.target)) end
        return tr("UI_ZeD_Log_S_Out")
    end
    if what == "create" then return tr("UI_ZeD_Log_F_Create", tostring(r.target)) end
    if what == "disband" then return tr("UI_ZeD_Log_F_Disband", tostring(r.target)) end
    if what == "invite cancelled" then return tr("UI_ZeD_Log_InviteCancelled", tostring(r.target)) end
    local title = string.match(what, "^title (.*)$")
    if title then return tr("UI_ZeD_Log_S_Title", quoted(title)) end
    local from = string.match(what, "^owner from (.*)$")
    if from then
        if onFaction then return tr("UI_ZeD_Log_F_Owner", tostring(r.target), from) end
        return tr("UI_ZeD_Log_S_Owner", from)
    end
    local name = string.match(what, "^name from (.*)$")
    if name then return tr("UI_ZeD_Log_F_Name", quoted(name), tostring(r.target)) end
    local tag = string.match(what, "^tag (.*)$")
    if tag then return tr("UI_ZeD_Log_F_Tag", tostring(r.target), quoted(tag)) end
    return nil
end
function WHAT.safehouse(r) return claimWords(r, false) end
function WHAT.faction(r) return claimWords(r, true) end

local LEN_WORD = { permanent = "UI_ZeD_Adm_LenPerm", h1 = "UI_ZeD_Adm_Len1h", d1 = "UI_ZeD_Adm_Len1d", d3 = "UI_ZeD_Adm_Len3d", w1 = "UI_ZeD_Adm_Len1w" }
local ADMIN = {}
ADMIN["teleport to"] = function(r) return tr("UI_ZeD_Log_A_Tp", tostring(r.target)) end
ADMIN["teleport to you"] = function(r) return tr("UI_ZeD_Log_A_Bring", tostring(r.target)) end
ADMIN["kick"] = function(r) return tr("UI_ZeD_Log_A_Kick", tostring(r.target), quoted(r.text)) end
ADMIN["warning points"] = function(r)
    local n, why = string.match(r.text or "", "^(%d+): (.*)$")
    if not n then return nil end
    return tr((n == "1") and "UI_ZeD_Log_A_Warn1" or "UI_ZeD_Log_A_Warn", n, tostring(r.target), quoted(why))
end
ADMIN["mute"] = function(r) return tr("UI_ZeD_Log_A_Mute", tostring(r.target)) end
ADMIN["unmute"] = function(r) return tr("UI_ZeD_Log_A_Unmute", tostring(r.target)) end
ADMIN["role"] = function(r) return tr("UI_ZeD_Log_A_Role", tostring(r.target), tostring(r.text)) end
ADMIN["level up"] = function(r) return tr("UI_ZeD_Log_A_LevelUp", tostring(r.target), tostring(r.text)) end
ADMIN["level down"] = function(r) return tr("UI_ZeD_Log_A_LevelDown", tostring(r.target), tostring(r.text)) end
ADMIN["ban"] = function(r)
    local len, why = string.match(r.text or "", "^(.-): (.*)$")
    if not len then return nil end
    return tr("UI_ZeD_Log_A_Ban", tostring(r.target), tr(LEN_WORD[len] or LEN_WORD.permanent), quoted(why))
end
ADMIN["unban"] = function(r) return tr("UI_ZeD_Log_A_Unban", tostring(r.target)) end
ADMIN["ban lifted"] = function(r) return tr("UI_ZeD_Log_A_Lifted", tostring(r.target)) end
ADMIN["game ban"] = function(r) return tr("UI_ZeD_Log_A_GameBan", tostring(r.target), quoted(r.text)) end
ADMIN["server message"] = function(r) return tr("UI_ZeD_Log_A_Msg", quoted(r.text)) end
ADMIN["repeating message"] = function(r) return tr("UI_ZeD_Log_A_Repeat", tostring(r.text)) end
ADMIN["repeating message stopped"] = function(r) return tr("UI_ZeD_Log_A_RepeatStop") end
ADMIN["spawn"] = function(r) return tr("UI_ZeD_Log_A_Spawn", tostring(r.text)) end
function WHAT.admin(r)
    local fn = ADMIN[r.what]
    return fn and fn(r) or nil
end

-- as the server wrote it: "power on: GodMod", and any code from a later ZeD
local function raw(r)
    local s = r.what or ""
    if r.target then s = (s == "") and tostring(r.target) or (s .. " " .. tostring(r.target)) end
    if r.text then s = (s == "") and tostring(r.text) or (s .. ": " .. tostring(r.text)) end
    return s
end

-- what the line says happened, after the name of who did it
function Lm.lineText(r)
    local fn = WHAT[r.k]
    if r.src ~= "tap" and fn then
        local ok, s = pcall(fn, r)
        if ok and s then return s end
    end
    return raw(r)
end

function Lm.whereText(r)
    if r.x and r.y then return tostring(r.x) .. " x " .. tostring(r.y) end
    return nil
end

-- where a line came from, when that isn't ZeD
function Lm.sourceText(r)
    if r.src == "pvp" then return tr("UI_ZeD_Log_FromPvp") end
    if r.src == "tap" then
        if r.by then return tr("UI_ZeD_Log_FromTapBy", tostring(r.lg), r.by) end
        return tr("UI_ZeD_Log_FromTap", tostring(r.lg))
    end
    return nil
end

-- the second line of a row: the place, and the source; "" when a line has neither (a faction's has no place)
function Lm.metaText(r)
    local where, src = Lm.whereText(r), Lm.sourceText(r)
    if where and src then return where .. " | " .. src end
    return where or src or ""
end

-- whose cards a line offers, beyond whoever did it
function Lm.otherName(r)
    if r.src == "tap" or not r.target then return nil end
    if r.k == "pvp" or r.k == "vehicle" then return r.target end
    if r.k == "admin" and ADMIN[r.what] and r.what ~= "repeating message stopped" then return r.target end
    return nil
end

function Lm.kindColor(k)
    local T = ZeD.T
    if k == "admin" or k == "pvp" then return T.danger end
    if k == "safehouse" then return T.accent end
    if k == "faction" then return T.positive end
    if k == "vehicle" then return T.warning end
    if k == "ticket" then return T.info end
    if k == "container" then return T.violet or T.info end
    return T.textDim
end

return Lm
