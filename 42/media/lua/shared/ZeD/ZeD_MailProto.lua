-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_MailProto.lua
-- ============================================================================
-- MAIL: WHAT BOTH SIDES AGREE ON (punch list 104; the director, Nov 7 2026: "email back then, you would dial in to connect,
-- to send and receive. So most of it was done offline."). The module, every limit, the checks on typed words. Pure Lua,
-- ASCII, nothing client-only at load: this file also runs on a dedicated server.
--
-- The shape (ZeD_ServerMail.lua, ZeD_Mail.lua, ZeD_MailStore.lua):
--   the server keeps each player's mail until it is handed over, and no longer. Joining is the dial-in: the client says
--   p_dial, the waiting mail comes down in batches (p_in), each batch answered with p_got (then the server forgets it),
--   and the outbox goes up a letter at a time (p_send). While a player is on, mail sent to them comes down at once.
--   Everything read or written on the desk at the main menu is the copy on the player's own computer.
-- ============================================================================

require "ZeD/ZeD_TicketProto"

ZeD = ZeD or {}
ZeD.Ml = ZeD.Ml or {}
local Ml = ZeD.Ml

Ml.MOD = "ZeDP"
Ml.PROTO = 1

-- every limit in one place, so they can become server settings later
Ml.L = {
    TO_MAX = 64,                -- a username
    SUBJ_MAX = 80,              -- a subject: one line
    TEXT_MAX = 2000,            -- a letter
    INBOX_MAX = 50,             -- letters waiting on the server for one player; past it the oldest goes
    CHARS_MAX = 3000000,        -- all the words the server keeps; past it the oldest letter anywhere goes
    KNOWN_MAX = 5000,           -- players this server can mail (seen here since mail came); past it the one seen longest ago goes
    SEND_MS = 2000,             -- between two letters from one player
    HOUR_MAX = 60,              -- letters from one player in any hour
    HOUR_MS = 3600000,
    DIAL_MS = 5000,
    BATCH = 10,                 -- letters in one handover
    CIDS = 40,                  -- each sender's last letter numbers, so a letter sent again after a lost answer is not delivered twice
    CID_MAX = 32,
}

-- one line: a username, a subject. nil if not words, empty after trimming, or longer than max
function Ml.line(s, max)
    local c = ZeD.Tk.clean(s)
    if not c then return nil end
    c = string.gsub(c, "\n", " ")
    if c == "" or #c > max then return nil end
    return c
end

-- a letter's words: several lines, trimmed, not empty, at most TEXT_MAX
function Ml.text(s)
    local c = ZeD.Tk.clean(s)
    if not c or c == "" or #c > Ml.L.TEXT_MAX then return nil end
    return c
end

-- a subject may be left empty
function Ml.subject(s)
    if s == nil or s == "" then return "" end
    local c = ZeD.Tk.clean(s)
    if not c then return nil end
    c = string.gsub(c, "\n", " ")
    if #c > Ml.L.SUBJ_MAX then return nil end
    return c
end

-- a client's number for one letter: letters, digits, "-" and "_", at most CID_MAX
function Ml.cid(s)
    if type(s) ~= "string" or s == "" or #s > Ml.L.CID_MAX then return nil end
    if string.find(s, "[^%w%-_]") then return nil end
    return s
end

return Ml
