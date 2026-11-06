-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_ClaimProto.lua
-- ============================================================================
-- SAFEHOUSES AND FACTIONS: WHAT BOTH SIDES AGREE ON (ZeDUI/MP_ADMIN_SCOPE.md, Phase 3). The module name, the limits, the
-- tag colors, the checks on a typed name and the wars' rules. Pure Lua, ASCII, nothing client-only at load: this file
-- also runs on a dedicated server.
--
-- The game does this work: every claim, invite and rename here goes through its own calls, which its server checks. The
-- checks in this file only say why before the game would refuse.
-- ============================================================================

require "ZeD/ZeD_TicketProto"

ZeD = ZeD or {}
ZeD.Cl = ZeD.Cl or {}
local Cl = ZeD.Cl

Cl.MOD = "ZeDC"

-- THE DIRECTOR'S QUESTIONS, each answered the careful way and kept to one switch here.
-- The game's code takes 15 characters for a faction's name; its words say 3-14. ZeD holds to the words.
Cl.NAME_MIN, Cl.NAME_MAX = 3, 14
Cl.TAG_MIN, Cl.TAG_MAX = 1, 4
-- The game has no limit on a safehouse's title but "not empty". The drawing's 30.
Cl.TITLE_MAX = 30
-- A tag is saved in capitals, as drawn. The game takes it as typed, and tests "already exists" with the case kept.
Cl.TAG_UPPER = true
-- An invitation that waits in the Server tab also leaves a note on the belt and a toast, as a ticket's answer does. false:
-- only the Server tab shows it.
Cl.INVITE_NOTE = true
-- Accept and End on a war ask first, in the card's foot. The game's window asks nothing.
Cl.WAR_CONFIRM = true

-- typing past the limit is allowed by this much, so the count and the reason can show
Cl.FIELD_OVER = 4

-- Tag colors, as drawn. r, g, b from 0 to 1. The word is for the help line: a color is never the only thing said.
Cl.COLORS = {
    { id = "Red",    r = 0.769, g = 0.314, b = 0.314 },
    { id = "Orange", r = 0.831, g = 0.573, b = 0.165 },
    { id = "Yellow", r = 0.769, g = 0.690, b = 0.251 },
    { id = "Green",  r = 0.353, g = 0.604, b = 0.290 },
    { id = "Teal",   r = 0.247, g = 0.647, b = 0.604 },
    { id = "Blue",   r = 0.310, g = 0.525, b = 0.776 },
    { id = "Violet", r = 0.604, g = 0.416, b = 0.769 },
    { id = "White",  r = 0.831, g = 0.831, b = 0.847 },
}

Cl.LIMITS = {
    INFO_MS = 5000,              -- c_info, per player
    CANCEL_MS = 1000,            -- c_cancel, per player
    WATCH_MS = 5000,             -- how often the server compares the game's lists for the log
    LOG_PER_SCAN = 40,           -- lines one comparison may write
    NAMES_MAX = 40,              -- names in one list sent to a client
    INVITES_MAX = 10,            -- waiting invitations told to one player
    LOG_TEXT = 64,               -- a title or a name in a log line
}

-- is this color the one drawn? (the game keeps a tag color as three floats)
function Cl.sameColor(a, b)
    if not (a and b) then return false end
    return math.abs(a.r - b.r) < 0.02 and math.abs(a.g - b.g) < 0.02 and math.abs(a.b - b.b) < 0.02
end

-- the words of a typed name, trimmed. Line breaks and control characters out: a name is one line.
function Cl.name(s)
    if type(s) ~= "string" then return "" end
    local c = ZeD.Tk and ZeD.Tk.clean and ZeD.Tk.clean(s) or s
    c = string.gsub(c, "[%c]", " ")
    return (string.gsub(string.gsub(c, "^%s+", ""), "%s+$", ""))
end

-- what is wrong with a typed name, as a word the cards turn into the game's own text; nil when it may be saved.
-- exists: the game's own test (Faction.factionExist, Faction.tagExist), called only when the text differs from what is stored
function Cl.nameProblem(text, exists)
    local n = #Cl.name(text)
    if n < Cl.NAME_MIN or n > Cl.NAME_MAX then return "length" end
    if exists then return "exists" end
    return nil
end

function Cl.tagProblem(text, exists)
    local n = #Cl.name(text)
    if n < Cl.TAG_MIN or n > Cl.TAG_MAX then return "length" end
    if exists then return "exists" end
    return nil
end

function Cl.titleProblem(text)
    local n = #Cl.name(text)
    if n < 1 then return "empty" end
    if n > Cl.TITLE_MAX then return "long" end
    return nil
end

function Cl.tagText(s)
    local c = Cl.name(s)
    if Cl.TAG_UPPER then c = string.upper(c) end
    return c
end

-- the game joins its claim reasons with the system's line separator: each reason on its own line, none empty
function Cl.lines(s)
    local out = {}
    if type(s) ~= "string" then return out end
    for one in string.gmatch(s, "[^\r\n]+") do
        local c = string.gsub(string.gsub(one, "^%s+", ""), "%s+$", "")
        if c ~= "" then out[#out + 1] = c end
    end
    return out
end

-- hours until SafeHouse.update releases a safehouse: it goes when now passes lastVisited + the option's hours, whoever
-- is on the member list. Nil when there is nothing to count.
function Cl.hoursLeft(lastVisitedMs, nowMs, removalHours)
    if type(lastVisitedMs) ~= "number" or type(nowMs) ~= "number" or type(removalHours) ~= "number" then return nil end
    if lastVisitedMs <= 0 or removalHours <= 0 then return nil end
    local left = (lastVisitedMs + removalHours * 3600000 - nowMs) / 3600000
    if left < 0 then left = 0 end
    return left
end

-- what this player may do to a war, as ISWarManagerUI:onSelectWar decides it
function Cl.warActions(state, attacker, defender, me, canEnd)
    local out = {}
    if state == "Claimed" and defender == me then
        out[#out + 1] = "Accepted"
        out[#out + 1] = "Refused"
    end
    if state == "Claimed" and attacker == me then out[#out + 1] = "Canceled" end
    if canEnd then out[#out + 1] = "Ended" end
    return out
end

-- which of the game's three countdowns a war's time is (ISWarManagerUI:drawDatas)
function Cl.warClock(state)
    if state == "Claimed" then return "IGUI_WarManager_TimeToAccept" end
    if state == "Accepted" then return "IGUI_WarManager_TimeToStart" end
    if state == "Refused" or state == "Canceled" or state == "Started" or state == "Blocked" then return "IGUI_WarManager_TimeToEnd" end
    return nil
end

return Cl
