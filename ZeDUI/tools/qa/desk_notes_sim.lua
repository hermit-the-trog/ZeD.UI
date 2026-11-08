-- ZeDUI/tools/qa/desk_notes_sim.lua  (Nov 7 2026, punch list 104): the desk's notes with no game running. ZeD_DeskNotes.lua
-- runs against a stub of Zomboid/Lua (getFileReader / getFileWriter as the game's: a reader's readLine drops the line break and
-- gives nil at the end, a writer opened without append empties the file). Save, load, rename, delete, the sticky note, the draft,
-- the cap, names, words that must round-trip exactly, a fresh start reading what an earlier run wrote, a broken index.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/desk_notes_sim.lua
-- It prints FAIL lines and a last line "desk_notes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]desk_notes_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

-- ---------------------------------------------------------------------------
-- Zomboid/Lua, as the game's file calls see it
-- ---------------------------------------------------------------------------
local DISK = {}
local WRITES = 0
local function lines(text)
    local out = {}
    local pos = 1
    while pos <= #text do
        local nl = string.find(text, "[\r\n]", pos)
        if not nl then out[#out + 1] = string.sub(text, pos); break end
        out[#out + 1] = string.sub(text, pos, nl - 1)
        if string.sub(text, nl, nl) == "\r" and string.sub(text, nl + 1, nl + 1) == "\n" then nl = nl + 1 end
        pos = nl + 1
    end
    return out
end
function getFileReader(name, create)
    if string.find(name, "..", 1, true) then error("hasRelativePath") end
    local text = DISK[name]
    if text == nil then return nil end
    local ls, i = lines(text), 0
    return { readLine = function() i = i + 1; return ls[i] end, close = function() end }
end
function getFileWriter(name, create, append)
    if string.find(name, "..", 1, true) then error("hasRelativePath") end
    local buf = {}
    if append and DISK[name] then buf[1] = DISK[name] end
    DISK[name] = table.concat(buf)
    return { write = function(_, s) buf[#buf + 1] = s end, close = function() DISK[name] = table.concat(buf); WRITES = WRITES + 1 end }
end
local CLOCK = 1000000
function getTimestamp() return CLOCK end

ZeD = { logOnce = function(what, err) print("logOnce " .. tostring(what) .. ": " .. tostring(err)) end }
dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_DeskNotes.lua")
local N = ZeD.DeskNotes

-- a fresh session: the model forgets what it read, the disk stays
local function restart() N.reset() end

section("empty desk")
check("no notes at first", N.count() == 0)
check("no sticky words at first", N.sticky() == "")
check("no draft at first", N.draft() == nil)

section("create, save, read")
local a = N.create(N.freshName("Untitled"))
check("first is Untitled 1", a and a.name == "Untitled 1", a and a.name)
check("first takes id 1", a and a.id == 1)
check("its file exists, empty", DISK["ZeD_desk_note_1.txt"] == "\n")
local b = N.create(N.freshName("Untitled"), "hello")
check("second is Untitled 2", b and b.name == "Untitled 2", b and b.name)
check("second's words", N.read(b.id) == "hello")
local words = "Server: 192.168.0.4:16261\nPassword hint: the dog's name\n\n  indented line\nlast line, a trailing break\n"
check("save", N.save(a.id, words) == true)
restart()
check("words round-trip exactly after a restart", N.read(1) == words, string.format("%q", tostring(N.read(1))))
check("both notes listed after a restart", N.count() == 2)
check("names kept", N.get(1).name == "Untitled 1" and N.get(2).name == "Untitled 2")
check("carriage returns out", (function() N.save(2, "a\r\nb\rc"); restart(); return N.read(2) == "a\nbc" end)(), N.read(2))
check("empty words round-trip", (function() N.save(2, ""); restart(); return N.read(2) == "" end)())
check("only line breaks round-trip", (function() N.save(2, "\n\n"); restart(); return N.read(2) == "\n\n" end)())
check("a note past TEXT_MAX is cut", (function() N.save(2, string.rep("x", N.TEXT_MAX + 50)); restart(); return #N.read(2) == N.TEXT_MAX end)())
CLOCK = CLOCK + 60
N.save(2, "later")
check("saving stamps the time", N.get(2).t == CLOCK)

section("names")
check("a name with | and control characters is cleaned", N.cleanName("a|b\tc\1d") == "abcd", N.cleanName("a|b\tc\1d"))
check("names are trimmed", N.cleanName("   seeds  ") == "seeds")
check("names are cut to NAME_MAX", #N.cleanName(string.rep("n", 80)) == N.NAME_MAX)
check("rename", N.rename(1, "Server list") == "Server list")
restart()
check("rename kept after a restart", N.get(1).name == "Server list")
local okR, errR = N.rename(2, "  ")
check("an empty name is refused", okR == nil and errR == "empty")
okR, errR = N.rename(2, "SERVER LIST")
check("a name another note holds is refused, any case", okR == nil and errR == "taken")
check("a note may keep its own name in another case", N.rename(1, "server list") == "server list")
okR, errR = N.rename(99, "x")
check("renaming a note that is gone", okR == nil and errR == "gone")
check("checkName says what a name would be", N.checkName(2, "  Mod list  ") == "Mod list")
check("freshName skips names that are taken", (function() N.rename(2, "Untitled 1"); return N.freshName("Untitled") == "Untitled 2" end)())
local c = N.create("Untitled 1")
check("a new note given a taken name gets a fresh one", c and c.name ~= "Untitled 1", c and c.name)

section("delete")
local before = N.count()
check("delete", N.delete(c.id) == true)
check("one fewer", N.count() == before - 1)
check("its file is emptied", DISK[N.fileOf(c.id)] == "")
restart()
check("still gone after a restart", N.get(c.id) == nil)
local okD, errD = N.delete(c.id)
check("deleting again says gone", okD == nil and errD == "gone")
local d = N.create("Again")
check("a new note takes the lowest free id", d and d.id == c.id, d and d.id)

section("the cap")
while not N.full() do N.create(N.freshName("Untitled")) end
check("the desktop holds MAX", N.count() == N.MAX)
local over, why = N.create("one too many")
check("one past MAX is refused", over == nil and why == "full")
local files = 0
for k in pairs(DISK) do if string.find(k, "^ZeD_desk_note_") then files = files + 1 end end
check("never more note files than MAX", files <= N.MAX, files)
for _, n in ipairs({ 3, 7, 11 }) do N.delete(n) end
local e = N.create("refill")
check("a refill reuses the lowest free id", e and e.id == 3)
restart()
check("count after a restart", N.count() == N.MAX - 2)

section("the sticky note")
check("save the sticky", N.saveSticky("buy batteries\nseed 12345") == true)
restart()
check("sticky words after a restart", N.sticky() == "buy batteries\nseed 12345")
local w0 = WRITES
N.saveSticky("buy batteries\nseed 12345")
check("the same words write nothing", WRITES == w0)
N.saveSticky(string.rep("s", N.STICKY_MAX + 10))
restart()
check("the sticky is cut to STICKY_MAX", #N.sticky() == N.STICKY_MAX)
N.saveSticky("")
restart()
check("an empty sticky", N.sticky() == "")

section("the draft")
check("save a draft for a new page", N.saveDraft(0, "Untitled 9", "half a thought\nand more") == true)
restart()
local dr = N.draft()
check("the draft comes back after a restart", dr and dr.id == 0 and dr.name == "Untitled 9" and dr.text == "half a thought\nand more")
N.saveDraft(1, "server list", "")
restart()
dr = N.draft()
check("an empty draft text", dr and dr.id == 1 and dr.text == "")
N.clearDraft()
restart()
check("a cleared draft is gone", N.draft() == nil)
N.saveDraft(1, "server list", "x")
N.delete(1)
restart()
check("deleting a note drops its draft", N.draft() == nil)

section("a broken index")
DISK[N.INDEX_FILE] = "ZeD desk notes 1\n5|12|Good one\nnot a line\n5|13|same id twice\n-2|1|bad\n6||no time\n9999|1|too high\n7|1|\n"
restart()
check("bad lines are skipped", N.count() == 3, N.count())
check("a line with no time reads 0", N.get(6) and N.get(6).t == 0)
check("a line with no name gets one", N.get(7) and N.get(7).name == "?")
check("the first of a doubled id wins", N.get(5) and N.get(5).name == "Good one")
DISK[N.INDEX_FILE] = nil
restart()
check("no index: an empty desktop, no error", N.count() == 0)
getFileReader = function() error("disk gone") end
restart()
check("a reader that throws: an empty desktop", N.count() == 0 and N.sticky() == "")

print("desk_notes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
