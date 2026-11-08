-- ZeD-UI/42/media/lua/client/ZeD/ZeD_DeskNotes.lua
-- ============================================================================
-- THE DESK'S NOTES, THE MODEL (punch list 104; the director, Nov 7 2026). No drawing: the sticky note on the
-- desktop and the CletusWorks Notepad (ZeD_MainMenuNotes.lua) read this and call it.
--
-- Everything is a plain file under Zomboid/Lua, the way ZeD keeps its own files (getFileWriter / getFileReader are
-- rooted there and refuse any "..": nothing here can reach anywhere else). They live on the player's computer, so they
-- outlast every update of the mod and every save:
--   ZeD_desk_sticky.txt      the sticky note's words
--   ZeD_desk_notes.txt       the notepad's index: a header line, then one line a file, "id|modified|name"
--   ZeD_desk_note_<id>.txt   a file's words
--   ZeD_desk_draft.txt       words typed in the notepad and not saved yet: "id|name" on the first line, then the words.
--                            Kept while the notepad has unsaved changes, so a game started from the menu bar (or a
--                            crash) loses nothing: the notepad opens with them next time
-- Lua cannot delete a file, so a deleted note's file is emptied and its id is free again: a new note takes the lowest
-- free id, and the folder never holds more than MAX note files.
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
-- every line of a file, or nil when there is none
local function readLines(name)
    local ok, r = pcall(N.io.reader, name)
    if not ok or not r then return nil end
    local out = {}
    local okR, err = pcall(function()
        local l = r:readLine()
        while l ~= nil do
            out[#out + 1] = l
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

local function readWords(name)
    local lines = readLines(name)
    if not lines then return nil end
    return table.concat(lines, "\n")
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
    local lines = readLines(N.INDEX_FILE) or {}
    local seen = {}
    for i = 2, #lines do                 -- (line 1 is the header)
        local id, t, name = string.match(lines[i], "^(%d+)|(%d*)|(.*)$")
        id = tonumber(id)
        if id and id >= 1 and id <= N.MAX * 4 and not seen[id] and #list < N.MAX then
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
    return readWords(N.fileOf(id)) or ""
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
    if N._sticky == nil then N._sticky = readWords(N.STICKY_FILE) or "" end
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
-- THE DRAFT: unsaved words, one at a time. id 0: a note not made yet (the notepad's new page)
-- ---------------------------------------------------------------------------
function N.draft()
    if N._draft == nil then
        local lines = readLines(N.DRAFT_FILE)
        N._draft = false
        if lines and #lines >= 1 then
            local id, name = string.match(lines[1], "^(%d+)|(.*)$")
            if id then
                local body = {}
                for i = 2, #lines do body[#body + 1] = lines[i] end
                N._draft = { id = tonumber(id), name = N.cleanName(name), text = table.concat(body, "\n") }
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
    N._list, N._sticky, N._draft = nil, nil, nil
end

return N
