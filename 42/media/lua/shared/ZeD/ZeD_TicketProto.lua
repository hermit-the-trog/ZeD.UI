-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_TicketProto.lua
-- ============================================================================
-- THE TICKET PROTOCOL: what both sides agree on. The module names, the kinds, the statuses and what a player sees of
-- them, every limit, the checks on what a client sends, and the tag on the game's ticket. Shared: this file loads on
-- the client and on a dedicated server alike, so nothing client-only at file scope. Pure Lua, pure ASCII.
-- ============================================================================

-- Reload-safe: loading this file twice reuses the tables instead of wiping them
ZeD = ZeD or {}
ZeD.Tk = ZeD.Tk or {}
local Tk = ZeD.Tk

Tk.MOD_LINK = "ZeD"         -- the link's module: the hello handshake rides on it, both ways
Tk.MOD = "ZeDT"             -- the module on every ticket command
Tk.PROTO = 1                -- the version each side states in its hello
-- who the server's own lines are by. The game refuses a username holding @ (ServerWorldDatabase.isValidUserName), so no account
-- can pass for it
Tk.SYS = "@server"
Tk.NEAR = 30                -- the reach of "near": tiles, on any floor; a settled choice, not a placeholder

-- TWO QUESTIONS THE DESIGN LEFT OPEN, each kept to one switch so the answer can turn without touching the rest.
-- May a ticket take more words once it is Answered? false is as the screens were first drawn: the player's field
-- closes at Answered, staff press Reopen to reply again. true: the field stays open, a player's reply puts it back at
-- Progress so it re-enters the queue, and staff can Answer and Close an Answered ticket.
Tk.REPLY_AT_ANSWERED = true
-- What goes in the game's own ticket. true: the player's words in full, as public as the game makes them (any
-- logged-in client reads every game ticket). false files only "[GRIEF #14] see the Tickets queue", keeping the words
-- off that public row, and the staff's first answer goes to the game as that same stub.
Tk.FILE_FULL_TEXT = false
Tk.FILE_STUB = "see the Tickets queue"

-- the kinds a ticket may carry: KINDS keeps the order, KIND answers "is this one?"
Tk.KINDS = { "BUG", "GRIEF", "STUCK", "QUESTION", "APPEAL", "OTHER" }
Tk.KIND = {}
for _, k in ipairs(Tk.KINDS) do Tk.KIND[k] = true end
Tk.NONE = "NONE"            -- a ticket adopted from the game's window with no tag

-- stored status -> what the player reads. The word Spam never reaches a player's client.
Tk.PLAYER_ST = { Open = "Sent", Seen = "Seen", Progress = "Progress", Answered = "Answered", Closed = "Closed", Spam = "Closed" }
Tk.QUEUE_ST = { Open = true, Answered = true, Closed = true, All = true, Spam = true }   -- the views a queue request may name

-- every limit in one place, so they can become server settings later
-- How many chat lines go with a report, each side of the picked line. One switch: what the client sends and what the
-- server allows both come from it.
Tk.REPORT_AROUND = 5

Tk.LIMITS = {
    GENERAL_N = 10, GENERAL_MS = 5000,          -- commands in any 5 s, per username; past that dropped with no reply
    HELLO_MS = 5000,
    NEW_MS = 60000,                             -- starts at an accepted ticket or a forged refusal
    MINE_MS = 5000,
    REPLY_MS = 10000,
    QUEUE_MS = 1000,
    SYNC_MS = 1000,
    DIFF_MS = 1000,
    MINUTE_MS = 60000,                          -- the log's pace for one player
    BAD_LINES = 6,                              -- bad-argument lines in a minute, per player
    OPEN_PER_PLAYER = 5,
    OPEN_ALL = 300,
    ADOPT_OPEN = 100,
    ADOPT_PER_AUTHOR = 3,
    HISTORY = 500,                              -- Answered, Closed and Spam records
    THREAD_MAX = 40,
    NOTES_MAX = 20,
    TEXT_MAX = 1000,
    CHARS_MAX = 4000000,                        -- all the text in the table
    PLAYER_CHARS = 3500000,                     -- where a player's words stop; the rest is kept for staff
    TOMBS_MAX = 50,                             -- deleted tickets whose game row has not been seen yet
    NEAR_MAX = 20,
    MINE_ROWS = 50,
    PAGE_ROWS = 25,
    AUTHORS_MAX = 100,
    PREVIEW = 120,
    FIND_MAX = 64,
    SYNC_ROWS = 20,
    DIFF_ROWS = 50,
    SYNC_CUT = 1100,                            -- a game row's strings, cut on the client
    NAME_MAX = 64,
    REPORT_LINES = 2 * Tk.REPORT_AROUND + 1,    -- chat lines on a report from chat: the picked line and those around it
    REPORT_TEXT = 300,                          -- each, cut to this
}

--- one of the kinds above?
function Tk.isKind(k) return type(k) == "string" and Tk.KIND[k] == true end
--- still open: Open, Seen or Progress, not yet Answered, Closed or marked Spam
function Tk.isOpen(st) return st == "Open" or st == "Seen" or st == "Progress" end

-- what each status allows. REPLY_AT_ANSWERED above is the one switch: with it on, Answered allows all three too
--- may the player add words to this ticket?
function Tk.canReply(st) return Tk.isOpen(st) or (Tk.REPLY_AT_ANSWERED and st == "Answered") end
--- may staff answer it?
function Tk.canAnswer(st) return Tk.isOpen(st) or (Tk.REPLY_AT_ANSWERED and st == "Answered") end
--- may staff close it?
function Tk.canClose(st) return Tk.isOpen(st) or (Tk.REPLY_AT_ANSWERED and st == "Answered") end

--- a whole positive number a client may name: an id, a page, a request number; kept below Java's int ceiling
function Tk.whole(n)
    return type(n) == "number" and n >= 1 and n < 2147483647 and n == math.floor(n)
end

--- Trim, and control characters out but for line breaks. By character code, not a pattern: pattern classes can differ
-- between the game's Lua (Kahlua) and plain Lua, and a byte-by-byte scan stays linear on any text a client can send.
-- Nil unless given a string.
function Tk.clean(s)
    if type(s) ~= "string" then return nil end
    local byte, sub = string.byte, string.sub
    local n = #s
    local parts, np, from = {}, 0, 1
    for i = 1, n do
        local b = byte(s, i)
        if (b < 32 and b ~= 10) or b == 127 then
            if i > from then np = np + 1; parts[np] = sub(s, from, i - 1) end
            from = i + 1
        end
    end
    local out = s
    if from > 1 then
        if from <= n then np = np + 1; parts[np] = sub(s, from, n) end
        out = table.concat(parts)
    end
    local a, b = 1, #out
    while a <= b do
        local c = byte(out, a)
        if c == 32 or c == 10 then a = a + 1 else break end
    end
    while b >= a do
        local c = byte(out, b)
        if c == 32 or c == 10 then b = b - 1 else break end
    end
    return sub(out, a, b)
end

--- the tag on the game's ticket while the server part is here: "[GRIEF #14] words", the number naming ZeD's record
function Tk.tag(kind, id, text) return "[" .. tostring(kind) .. " #" .. tostring(id) .. "] " .. tostring(text) end
--- the tag without the server part: no record will hold the place, so it goes in the words
function Tk.plainTag(kind, text, x, y)
    local s = "[" .. tostring(kind) .. "] " .. tostring(text)
    if x and y then s = s .. " (" .. tostring(x) .. " x " .. tostring(y) .. ")" end
    return s
end
--- what the player's client files in the game for a record: the words in full or the stub, as FILE_FULL_TEXT says
function Tk.fileText(kind, id, text)
    return Tk.tag(kind, id, Tk.FILE_FULL_TEXT and text or Tk.FILE_STUB)
end
--- what the staff's first answer files in the game: the same switch, or the answer would be public
function Tk.answerText(text)
    return Tk.FILE_FULL_TEXT and text or Tk.FILE_STUB
end
--- kind, id, the rest of the words. "[KIND #7] words" gives all three, "[KIND] words" gives kind alone, anything else
-- gives nil, nil, the whole message. The kind comes back unchecked: callers test isKind
function Tk.parse(msg)
    if type(msg) ~= "string" then return nil, nil, "" end
    local k, id, rest = string.match(msg, "^%[(%u+) #(%d+)%] (.*)$")
    if k then return k, tonumber(id), rest or "" end
    k, rest = string.match(msg, "^%[(%u+)%] (.*)$")
    if k then return k, nil, rest or "" end
    return nil, nil, msg
end

--- is this game message the one a ZeD record filed? Either form, so turning FILE_FULL_TEXT over leaves old tickets linked
function Tk.fileMatches(rec, msg)
    local first = rec.thread and rec.thread[1]
    if msg == Tk.tag(rec.kind, rec.id, Tk.FILE_STUB) then return true end
    return first ~= nil and msg == Tk.tag(rec.kind, rec.id, first.text)
end

--- a name a game row claims, for one line: a line break stops at the door, or it reads as a second line in the log
function Tk.name(s)
    local c = string.gsub(Tk.clean(s) or "", "\n", " ")
    return string.sub(c, 1, Tk.LIMITS.NAME_MAX)
end

--- the test before any game call: is this game row still that record? The game's ticket table can be wiped or
-- replaced and a number reused, so the author and the words are the proof, not the number alone
function Tk.sameTicket(author, msg, rec)
    if type(rec) ~= "table" then return false end
    if rec.source == "zed" then return author == rec.author and Tk.fileMatches(rec, msg) end
    if Tk.name(author) ~= rec.author then return false end
    local first = rec.thread and rec.thread[1]
    if not first then return false end
    local kind, _, rest = Tk.parse(msg)
    if not Tk.isKind(kind) then rest = msg end
    local text = Tk.clean(rest) or ""
    return string.sub(text, 1, Tk.LIMITS.TEXT_MAX) == first.text
end

--- the game's message to staff about a new ticket: "user %s added a ticket ..."
function Tk.isTicketMessage(msg)
    return type(msg) == "string" and string.sub(msg, 1, 5) == "user " and string.find(msg, " added a ticket", 1, true) ~= nil
end

--- the place in words, for a row: its name once the server has proved one, else the coordinates. No vanilla call
-- turns coordinates into a town name, so a name is never promised
function Tk.whereText(place)
    if type(place) ~= "table" then return nil end
    if place.name then return place.name end
    if place.x and place.y then return tostring(place.x) .. " x " .. tostring(place.y) end
    return nil
end
--- the place on a card: the name and the coordinates, as drawn
function Tk.whereFull(place)
    if type(place) ~= "table" then return nil end
    if place.name and place.x and place.y then
        return place.name .. ", " .. tostring(place.x) .. " x " .. tostring(place.y)
    end
    return Tk.whereText(place)
end

return Tk
