-- ZeD-UI/42/media/lua/client/ZeD/ZeD_DeskNotes.lua
-- ============================================================================
-- THE DESK'S NOTES, THE MODEL. Client, no drawing of its own: the sticky note on the
-- desktop and the CletusWorks Notepad (ZeD_MainMenuNotes.lua) read this and call it.
--
-- Everything is a plain file under Zomboid/Lua, the way ZeD keeps its own files (getFileWriter / getFileReader are
-- rooted there and refuse any "..": nothing here can reach anywhere else). They live on the player's computer, so they
-- outlast every update of the mod and every save:
--   ZeD_desk_sticky.txt      the sticky note's words
--   ZeD_desk_pasties.txt     the Pasties (the sticky notes) on the desk: "id|fx|fy" a line, oldest first
--   ZeD_desk_pastie_<id>.txt a Pastie's words (ids 1 to 8)
--   ZeD_desk_sticky.txt and ZeD_desk_sticky_place.txt: the one sticky note from before Pasties, read once to move its
--                            words into Pastie 1
--   ZeD_desk_notes.txt       the notepad's index: a header line, then one line a file, "id|modified|name"
--   ZeD_desk_note_<id>.txt   a file's words
--   ZeD_desk_draft.txt       words typed in the notepad and not saved yet: "id|name" on the first line, then the words.
--                            Kept while the notepad has unsaved changes, so a game started from the menu bar (or a
--                            crash) loses nothing: the notepad opens with them next time
-- Lua cannot delete a file, so a deleted note's file is emptied and its id is free again: a new note takes the lowest
-- free id, and the folder never holds more than MAX note files.
--
-- Files edited on disk cannot get round the caps: never more than MAX slots are read (ids 1 to MAX only), a note's
-- file is read no further than TEXT_MAX characters (an oversized one is treated as cut there), the sticky's no further
-- than STICKY_MAX, and the index no further than a bounded few lines (four times MAX, plus the header).
--
-- Words round-trip exactly: a file is the words and one line break more, read back line by line and joined with line
-- breaks (the game's reader drops the last). Carriage returns are taken out on the way in.
--
-- QA and the sims: N.io holds the two file calls, so a sim swaps in its own.
-- ============================================================================

ZeD = ZeD or {}
ZeD.DeskNotes = ZeD.DeskNotes or {}
local N = ZeD.DeskNotes

N.STICKY_FILE = "ZeD_desk_sticky.txt"
N.PLACE_FILE = "ZeD_desk_sticky_place.txt"
N.INDEX_FILE = "ZeD_desk_notes.txt"
N.DRAFT_FILE = "ZeD_desk_draft.txt"
N.NOTE_PREFIX = "ZeD_desk_note_"
N.HEADER = "ZeD desk notes 1"

N.MAX = 24              -- notes on the desktop
N.TEXT_MAX = 20000      -- characters in a note
N.NAME_MAX = 32         -- characters in a note's name
N.STICKY_MAX = 600      -- characters on the sticky note

N.io = N.io or {
    reader = function(name) return getFileReader(name, false) end,
    writer = function(name) return getFileWriter(name, true, false) end,
}

N.seq = N.seq or 0      -- bumps on every change (the desktop and the notepad re-read)
local function bump() N.seq = N.seq + 1 end

local function now()
    local ok, t = pcall(getTimestamp)
    if ok and type(t) == "number" then return math.floor(t) end
    return 0
end

-- ---------------------------------------------------------------------------
-- FILES
-- ---------------------------------------------------------------------------
-- every line of a file, or nil when there is none. maxChars / maxLines: stop there (a file grown on disk is never read whole)
local function readLines(name, maxChars, maxLines)
    local ok, r = pcall(N.io.reader, name)
    if not ok or not r then return nil end
    local out = {}
    local okR, err = pcall(function()
        local l = r:readLine()
        local n = 0
        while l ~= nil do
            out[#out + 1] = l
            n = n + #l + 1
            if (maxChars and n > maxChars) or (maxLines and #out >= maxLines) then break end
            l = r:readLine()
        end
    end)
    pcall(function() r:close() end)
    if not okR then
        if ZeD.logOnce then ZeD.logOnce("desk notes: reading " .. name, err) end
        return nil
    end
    return out
end

local function writeText(name, text)
    local ok, err = pcall(function()
        local w = N.io.writer(name)
        if not w then error("no writer") end
        w:write(text)
        w:close()
    end)
    if not ok and ZeD.logOnce then ZeD.logOnce("desk notes: writing " .. name, err) end
    return ok
end

-- the words as typed: carriage returns out, at most max characters
function N.clean(s, max)
    s = string.gsub(tostring(s or ""), "\r", "")
    if max and #s > max then s = string.sub(s, 1, max) end
    return s
end

local function readWords(name, max)
    local lines = readLines(name, max and (max + 2) or nil)
    if not lines then return nil end
    local s = table.concat(lines, "\n")
    if max and #s > max then s = string.sub(s, 1, max) end
    return s
end
local function writeWords(name, text) return writeText(name, text .. "\n") end

function N.fileOf(id) return N.NOTE_PREFIX .. tostring(id) .. ".txt" end

-- ---------------------------------------------------------------------------
-- NAMES: one line, no "|", no control characters, at most NAME_MAX, never empty
-- ---------------------------------------------------------------------------
-- (by character code and slices, as Tk.clean: the game's strings are UTF-16, and a slice keeps every character whole)
function N.cleanName(s)
    s = tostring(s or "")
    local out, from = {}, 1
    for i = 1, #s do
        local b = string.byte(s, i)
        if b < 32 or b == 127 or b == 124 then
            if i > from then out[#out + 1] = string.sub(s, from, i - 1) end
            from = i + 1
        end
    end
    if from <= #s then out[#out + 1] = string.sub(s, from) end
    s = table.concat(out)
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    if #s > N.NAME_MAX then s = string.gsub(string.sub(s, 1, N.NAME_MAX), "%s+$", "") end
    return s
end

-- ---------------------------------------------------------------------------
-- THE INDEX
-- ---------------------------------------------------------------------------
-- the notes, oldest id first: { id, name, t (seconds, when last saved) }. Read once; every change writes it again
function N.list()
    if N._list then return N._list end
    local list = {}
    local lines = readLines(N.INDEX_FILE, nil, N.MAX * 4 + 1) or {}
    local seen = {}
    for i = 2, #lines do                 -- (line 1 is the header)
        local id, t, name = string.match(lines[i], "^(%d+)|(%d*)|(.*)$")
        id = tonumber(id)
        if id and id >= 1 and id <= N.MAX and not seen[id] and #list < N.MAX then
            seen[id] = true
            name = N.cleanName(name)
            if name == "" then name = "?" end
            list[#list + 1] = { id = id, name = name, t = tonumber(t) or 0 }
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    N._list = list
    return list
end

local function writeIndex()
    local parts = { N.HEADER }
    for _, n in ipairs(N.list()) do parts[#parts + 1] = tostring(n.id) .. "|" .. tostring(n.t or 0) .. "|" .. n.name end
    return writeText(N.INDEX_FILE, table.concat(parts, "\n") .. "\n")
end

function N.get(id)
    for _, n in ipairs(N.list()) do if n.id == id then return n end end
    return nil
end

function N.count() return #N.list() end
function N.full() return #N.list() >= N.MAX end

-- the lowest id no note holds
local function freeId()
    local used = {}
    for _, n in ipairs(N.list()) do used[n.id] = true end
    local id = 1
    while used[id] do id = id + 1 end
    return id
end

-- is this name another note's? (case does not count, as on the desktops of the time)
function N.taken(name, exceptId)
    local low = string.lower(name)
    for _, n in ipairs(N.list()) do
        if n.id ~= exceptId and string.lower(n.name) == low then return true end
    end
    return false
end

-- "Untitled 1", "Untitled 2", ...: the first the desktop does not hold. word: the player's word for untitled
function N.freshName(word)
    word = N.cleanName(word or "Untitled")
    if word == "" then word = "Untitled" end
    local i = 1
    while N.taken(word .. " " .. tostring(i)) do i = i + 1 end
    return word .. " " .. tostring(i)
end

-- ---------------------------------------------------------------------------
-- A NOTE'S WORDS
-- ---------------------------------------------------------------------------
function N.read(id)
    if not N.get(id) then return nil end
    return readWords(N.fileOf(id), N.TEXT_MAX) or ""
end

-- a new, empty note; nil and "full" when the desktop holds MAX
function N.create(name, text)
    if N.full() then return nil, "full" end
    name = N.cleanName(name)
    if name == "" or N.taken(name) then name = N.freshName(name ~= "" and name or nil) end
    local n = { id = freeId(), name = name, t = now() }
    if not writeWords(N.fileOf(n.id), N.clean(text, N.TEXT_MAX)) then return nil, "write" end
    local list = N.list()
    list[#list + 1] = n
    table.sort(list, function(a, b) return a.id < b.id end)
    writeIndex()
    bump()
    return n
end

-- true, or nil and "gone" / "write"
function N.save(id, text)
    local n = N.get(id)
    if not n then return nil, "gone" end
    if not writeWords(N.fileOf(id), N.clean(text, N.TEXT_MAX)) then return nil, "write" end
    n.t = now()
    writeIndex()
    bump()
    return true
end

-- the name it would take, or nil and "empty" / "taken" / "gone"
function N.checkName(id, name)
    if not N.get(id) then return nil, "gone" end
    name = N.cleanName(name)
    if name == "" then return nil, "empty" end
    if N.taken(name, id) then return nil, "taken" end
    return name
end

function N.rename(id, name)
    local clean, err = N.checkName(id, name)
    if not clean then return nil, err end
    N.get(id).name = clean
    writeIndex()
    bump()
    return clean
end

-- the file is emptied (Lua cannot delete one) and the id is free for the next new note
function N.delete(id)
    local list = N.list()
    for i, n in ipairs(list) do
        if n.id == id then
            table.remove(list, i)
            writeText(N.fileOf(id), "")
            writeIndex()
            local d = N.draft()
            if d and d.id == id then N.clearDraft() end
            bump()
            return true
        end
    end
    return nil, "gone"
end

-- ---------------------------------------------------------------------------
-- THE STICKY NOTE
-- ---------------------------------------------------------------------------
function N.sticky()
    if N._sticky == nil then N._sticky = readWords(N.STICKY_FILE, N.STICKY_MAX) or "" end
    return N._sticky
end

function N.saveSticky(text)
    text = N.clean(text, N.STICKY_MAX)
    if text == N.sticky() then return true end
    if not writeWords(N.STICKY_FILE, text) then return nil, "write" end
    N._sticky = text
    bump()
    return true
end

-- ---------------------------------------------------------------------------
-- PASTIES (the director, Nov 10 2026: "what if sticky was an icon, when clicked it creates a new sticky on the desk.
-- Starts with none." and "'Pasties' is the app name"). Up to PASTIES_MAX notes, each a slot id 1 to 8: its place in
-- PASTIES_FILE ("id|fx|fy" a line, in the order they were made; fx, fy the fractions of the room a note moves in, so a
-- place outlasts a change of screen size) and its words in ZeD_desk_pastie_<id>.txt. Closing one throws it away: its
-- line goes and its file is emptied. Replaces punch list 114's one note: the first read moves that note's words, if it
-- had any, into Pastie 1 at its place, and empties its file.
-- ---------------------------------------------------------------------------
N.PASTIES_FILE = "ZeD_desk_pasties.txt"
N.PASTIE_PREFIX = "ZeD_desk_pastie_"
N.PASTIES_MAX = 8
N.PASTIE_MAX = N.STICKY_MAX     -- characters on one

local function f4(v) return string.format("%.4f", v or 0) end
local function pastieFile(id) return N.PASTIE_PREFIX .. tostring(id) .. ".txt" end

local function writePasties()
    local out = {}
    for _, p in ipairs(N._pasties) do out[#out + 1] = tostring(p.id) .. "|" .. f4(p.fx) .. "|" .. f4(p.fy) end
    return writeText(N.PASTIES_FILE, table.concat(out, "\n") .. "\n")
end

--- The notes on the desk, bottom of the pile first: { id, fx, fy } each.
function N.pasties()
    if N._pasties then return N._pasties end
    N._pasties, N._pastieText = {}, {}
    local lines = readLines(N.PASTIES_FILE, 64 * (N.PASTIES_MAX + 1), N.PASTIES_MAX + 1)
    if lines then
        local seen = {}
        for _, l in ipairs(lines) do
            local id, fx, fy = string.match(l, "^(%d+)|([%d%.]+)|([%d%.]+)$")
            id, fx, fy = tonumber(id), tonumber(fx), tonumber(fy)
            if id and fx and fy and id >= 1 and id <= N.PASTIES_MAX and not seen[id] and #N._pasties < N.PASTIES_MAX then
                seen[id] = true
                N._pasties[#N._pasties + 1] = { id = id, fx = math.max(0, math.min(1, fx)), fy = math.max(0, math.min(1, fy)) }
            end
        end
    else
        -- (no Pasties yet: the one sticky note from before, if it had words, becomes Pastie 1 where it sat)
        local old = readWords(N.STICKY_FILE, N.STICKY_MAX) or ""
        if string.find(old, "%S") then
            local fx, fy = 0, 0
            local pl = readLines(N.PLACE_FILE, 64, 1)
            local _, ox, oy = string.match(pl and pl[1] or "", "^([01])|([%d%.]*)|([%d%.]*)$")
            if tonumber(ox) and tonumber(oy) then fx, fy = tonumber(ox), tonumber(oy) end
            N._pasties[1] = { id = 1, fx = math.max(0, math.min(1, fx)), fy = math.max(0, math.min(1, fy)) }
            writeWords(pastieFile(1), old)
            N._pastieText[1] = old
            writeWords(N.STICKY_FILE, "")
        end
        writePasties()
    end
    return N._pasties
end

--- The note with slot id, or nil.
function N.pastie(id)
    for _, p in ipairs(N.pasties()) do if p.id == id then return p end end
    return nil
end

--- True when the desk holds PASTIES_MAX notes.
function N.pastiesFull() return #N.pasties() >= N.PASTIES_MAX end

--- A new, empty note at (fx, fy). Returns its id, or nil when the desk is full.
function N.newPastie(fx, fy)
    local list = N.pasties()
    if #list >= N.PASTIES_MAX then return nil end
    local used = {}
    for _, p in ipairs(list) do used[p.id] = true end
    local id = 1
    while used[id] do id = id + 1 end
    list[#list + 1] = { id = id, fx = math.max(0, math.min(1, fx or 0)), fy = math.max(0, math.min(1, fy or 0)) }
    N._pastieText[id] = ""
    writeWords(pastieFile(id), "")
    writePasties()
    bump()
    return id
end

--- Bring a note to the top of the pile (the last one lies on top): touched, picked up or typed in. True when it moved.
function N.raisePastie(id)
    local list = N.pasties()
    for i, p in ipairs(list) do
        if p.id == id then
            if i == #list then return false end
            table.remove(list, i)
            list[#list + 1] = p
            writePasties()
            bump()
            return true
        end
    end
    return false
end

--- Move a note (fractions). keep: write it now (the drop), else in memory only (a drag in progress).
function N.movePastie(id, fx, fy, keep)
    local p = N.pastie(id)
    if not p then return false end
    p.fx, p.fy = math.max(0, math.min(1, fx or 0)), math.max(0, math.min(1, fy or 0))
    if keep then return writePasties() end
    return true
end

--- A note's words.
function N.pastieText(id)
    N.pasties()
    if N._pastieText[id] == nil then N._pastieText[id] = readWords(pastieFile(id), N.PASTIE_MAX) or "" end
    return N._pastieText[id]
end

--- Keep a note's words.
function N.savePastie(id, text)
    if not N.pastie(id) then return nil, "gone" end
    text = N.clean(text, N.PASTIE_MAX)
    if text == N.pastieText(id) then return true end
    if not writeWords(pastieFile(id), text) then return nil, "write" end
    N._pastieText[id] = text
    return true
end

--- Throw a note away: its line goes, its file is emptied (Lua cannot delete a file), its slot is free again.
function N.throwPastie(id)
    local list = N.pasties()
    for i, p in ipairs(list) do
        if p.id == id then
            table.remove(list, i)
            writeWords(pastieFile(id), "")
            N._pastieText[id] = nil
            writePasties()
            bump()
            return true
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- THE DRAFT: unsaved words, one at a time. id 0: a note not made yet (the notepad's new page)
-- ---------------------------------------------------------------------------
function N.draft()
    if N._draft == nil then
        local lines = readLines(N.DRAFT_FILE, N.TEXT_MAX + 200)
        N._draft = false
        if lines and #lines >= 1 then
            local id, name = string.match(lines[1], "^(%d+)|(.*)$")
            if id then
                local body = {}
                for i = 2, #lines do body[#body + 1] = lines[i] end
                local text = table.concat(body, "\n")
                if #text > N.TEXT_MAX then text = string.sub(text, 1, N.TEXT_MAX) end
                N._draft = { id = tonumber(id), name = N.cleanName(name), text = text }
            end
        end
    end
    return N._draft or nil
end

function N.saveDraft(id, name, text)
    local d = { id = tonumber(id) or 0, name = N.cleanName(name), text = N.clean(text, N.TEXT_MAX) }
    local cur = N.draft()
    if cur and cur.id == d.id and cur.name == d.name and cur.text == d.text then return true end
    if not writeText(N.DRAFT_FILE, tostring(d.id) .. "|" .. d.name .. "\n" .. d.text .. "\n") then return nil end
    N._draft = d
    return true
end

function N.clearDraft()
    if N.draft() == nil then return end
    writeText(N.DRAFT_FILE, "")
    N._draft = false
end

-- forget what was read (the sims start over; a reload reads the files again)
function N.reset()
    N._list, N._sticky, N._draft, N._pasties, N._pastieText = nil, nil, nil, nil, nil
end

return N
