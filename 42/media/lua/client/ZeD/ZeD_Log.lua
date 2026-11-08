-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Log.lua
-- ============================================================================
-- THE LOG, THE CLIENT'S MODEL. Client side, no drawing: ZeD_LogCards.lua reads this and calls it. The server holds the log
-- and filters it (ZeD_ServerLog.lua); a page comes back as l_page, and the words for a line are built on this side, from the
-- server's codes, so a line reads in the viewer's language. A code with no words reads as the server wrote it.
--
-- Without the server part there is no log to read: the Admin tab's row opens the game's own PvP log instead.
--
-- Test hooks, read at call time (as the ticket cards' are):
--   Lm.qaLink   true / false: the server part as the cards read it
--   Lm.qaHold   true: no traffic. The screen shows only what a test script put in Lm.page
-- ============================================================================

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_LogProto"
require "ZeD/ZeD_AdminProto"
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
--- Marks a change: Lm.seq moves, and the card re-reads the model.
function Lm.bump() Lm.seq = Lm.seq + 1 end

--- True when the server part's log is there to read (or whatever the test hook Lm.qaLink says).
function Lm.live()
    if Lm.qaLink ~= nil then return Lm.qaLink end
    return S.available() and S.lg == true
end

--- Asks the server for a page: q = { kind, who, when, find, page, around }. The page comes back as l_page
--- (into Lm.page); a refused read goes to cb with the answer.
function Lm.ask(q, cb)
    if Lm.qaHold then return end
    Lm.lastQ, Lm.lastCb = q, cb       -- (asked again when the join rules are answered: the gate refused it until then)
    Lm.qid = Lm.qid + 1
    Lm.waiting = true
    C.requestOn(Lg.MOD, "l_query", { qid = Lm.qid, kind = q.kind, who = q.who, when = q.when, find = q.find, codes = Lm.findCodes(q.find), page = q.page, around = q.around }, function(a)
        if a.ok == false then
            Lm.waiting = nil
            Lm.bump()
            if cb then cb(a) end
        end
    end)
end

--- The card is done: the page and the wait are dropped, and a page still on its way is ignored.
function Lm.close()
    Lm.page, Lm.waiting = nil, nil
    Lm.lastQ, Lm.lastCb = nil, nil
    Lm.qid = Lm.qid + 1
end

-- the join rules answered: the read still wanted is asked again
S.onAgreed("log", function()
    if Lm.lastQ and Lm.live() then Lm.ask(Lm.lastQ, Lm.lastCb) end
end)

--- Puts log line s on ticket id as an admin note (the server's l_tonote); cb gets the answer.
function Lm.toNote(id, s, cb) return C.requestOn(Lg.MOD, "l_tonote", { id = id, s = s }, cb) end

S.on(Lg.MOD, function(command, args)
    if command == "l_page" then
        if args.qid ~= Lm.qid then return end
        Lm.page = args
        Lm.waiting = nil
        Lm.bump()
    elseif command == "l_probe" then
        -- (what the server's hooks have seen, counts only: read by the test scripts)
        Lm.probe = args
        Lm.bump()
    end
end)

-- ---------------------------------------------------------------------------
-- A LINE IN WORDS: the codes are read in ZeD_LogProto.lua, for the card and the server alike; this is the viewer's side of it
-- ---------------------------------------------------------------------------
local CTX = { w = tr, kind = function(k)
    return ZeD.TicketCards and ZeD.TicketCards.kindWord(k) or tostring(k)
end }
function CTX.name(prefix, id)
    local s = getTextOrNull and getTextOrNull(prefix .. id) or nil
    return s or id
end
function CTX.item(fullType)
    local ok, s = pcall(getItemNameFromFullType, fullType)
    return (ok and s) or fullType
end

--- A line's words, in the viewer's language.
function Lm.lineText(r) return Lg.lineWords(r, CTX) end
--- Who did it, in the viewer's language.
function Lm.whoText(r) return Lg.whoWords(r, CTX) end

-- what the server is to look for besides the typed words (Lg.findCodes); kept, since the card asks at every look
local lastFind, lastCodes = nil, nil
function Lm.findCodes(find)
    if find == nil then return nil end
    if find ~= lastFind then lastFind, lastCodes = find, Lg.findCodes(find, tr) end
    return lastCodes
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

--- The second line of a row: the place, and the source; "" when a line has neither (a faction's has no place with nobody on).
function Lm.metaText(r)
    local where, src = Lm.whereText(r), Lm.sourceText(r)
    if where and src then return where .. " | " .. src end
    return where or src or ""
end

--- Whose card a line offers, beyond whoever did it. A ban's target can be an address: there is no card for one.
function Lm.otherName(r)
    if r.src == "tap" or not r.target then return nil end
    if r.k == "pvp" or r.k == "vehicle" then return r.target end
    if r.k == "ticket" and Lg.REPORT[r.what] then return r.target end
    if r.k == "admin" and Lg.ADMIN[r.what] and r.what ~= "repeating message stopped" and ZeD.Adm.targetKind(r.target) == "user" then return r.target end
    return nil
end

--- The color of a kind's tag.
function Lm.kindColor(k)
    local T = ZeD.T
    if k == "admin" or k == "pvp" then return T.danger end
    if k == "safehouse" then return T.accent end
    if k == "faction" then return T.positive end
    if k == "vehicle" then return T.warning end
    if k == "ticket" then return T.info end
    if k == "container" then return T.violet or T.info end
    -- (the status colors are spoken for, and the tag carries the word: plain text, brighter than Other's)
    if k == "community" then return T.text end
    return T.textDim
end

return Lm
