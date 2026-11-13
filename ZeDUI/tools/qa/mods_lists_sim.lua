-- ZeDUI/tools/qa/mods_lists_sim.lua  (Nov 12 2026, Build; the QA cleanup's "move to sim" list)
-- The Mods screen's load order pins and rules, its separators and its folders, with no game running: the real
-- ZeD_ModOrder.lua and ZeD_ModFolders.lua on an in-memory file system (getFileReader / getFileWriter), and the screen's
-- folderBox and sepFromFolders cut from their files, on made-up mods. Kahlua strings are UTF-16 (string.char and
-- string.byte take code points); under Lua 5.1 the two files get a string table that keeps a code point past 255 as
-- one private byte, so folder and separator names in any script round-trip as they do in the game.
-- From zedqa_mods_order.lua:
--   ORDER  pinned first carries what it needs above it, pinned last at the bottom, no red row; a Load after rule laid
--          out and kept through Auto; a rule that would close a circle is seen through the rules' chain; the profile
--          file keeps the lines it does not know through a save and a reload
-- From zedqa_mods_separators.lua:
--   SEPS   the order follows the separators' places, a mod new to the list goes under the last one, Auto sorts inside
--          a section and never across one, a mod turned off keeps its place, a separator moved takes its mods; in the
--          profile file a separator's name as hex per UTF-16 unit, on / off, collapsed, its mods, unknown lines kept;
--          Start separators from folders: one per folder in the folders' order, only the mods that are on, the rest
--          under Unfiled last, nothing turned on or off, the folders file untouched; separators never write it
-- From zedqa_mods_folders.lua:
--   FOLDERS ModFolders.cfg read and written back byte for byte; a non-ASCII name saved as one hex code per UTF-16
--          unit; a line ZeD does not know kept in its place through every change; Unfiled never written to the file,
--          its open state in ZeD_modfolders.txt; closed and opened written |0| / |1|; delete sends the folder's mods
--          to Unfiled; an edit made outside the game kept by the next change; the box turns a folder's mods on
--          (empty or mixed) or off (all on); the folders file never turns a mod on or off or moves the load order
-- What stays in the game: the screen itself (the list's rows, Find, the picker, the bands; zedqa_mods_*.lua).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mods_lists_sim.lua
-- It prints FAIL lines and a last line "mods_lists_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]mods_lists_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function join(t) return table.concat(t or {}, ";") end
local function idx(t, v) for i, x in ipairs(t) do if x == v then return i end end end
local function readSrc(name) local f = assert(io.open(CLIENT .. name, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s end

-- ---------------------------------------------------------------------------
-- THE STUBS: files in memory, Kahlua's strings
-- ---------------------------------------------------------------------------
local FILES = {}
local function raw(name) return FILES[name] end
function getFileReader(name)
    local text = FILES[name]
    if not text then return nil end
    local lines = {}
    for l in text:gmatch("([^\n]*)\n") do lines[#lines + 1] = l end
    local tail = text:match("([^\n]+)$")
    if tail then lines[#lines + 1] = tail end
    local i = 0
    return { readLine = function() i = i + 1; return lines[i] end, close = noop }
end
function getFileWriter(name)
    local buf = {}
    return { write = function(_, s) buf[#buf + 1] = s end, close = function() FILES[name] = table.concat(buf) end }
end

local CP, PRIV, nextPriv = {}, {}, 0x80
local function priv(c)
    if c <= 255 then return c end
    local b = PRIV[c]
    if not b then b = nextPriv; nextPriv = nextPriv + 1; PRIV[c] = b; CP[b] = c end
    return b
end
local KS = setmetatable({
    char = function(...) local t = { ... }; for i = 1, #t do t[i] = priv(t[i]) end; return string.char(unpack(t)) end,
    byte = function(s, i, j)
        local t = { string.byte(s, i, j) }
        for k = 1, #t do t[k] = CP[t[k]] or t[k] end
        return unpack(t)
    end }, { __index = string })
local U = KS.char
local function kload(name)
    local chunk = assert(loadfile(CLIENT .. name))
    setfenv(chunk, setmetatable({ string = KS }, { __index = _G, __newindex = _G }))
    chunk()
end

ZeD = { ModPicks = { HELPER = "ZeD_Picks" },
        tr = function(k, ...) local p = { k }; for _, v in ipairs({ ... }) do p[#p + 1] = tostring(v) end; return table.concat(p, "|") end }
kload("ZeD_ModOrder.lua")
kload("ZeD_ModFolders.lua")
local O, F = ZeD.ModOrder, ZeD.ModFolders
check("ZeD_ModOrder.lua and ZeD_ModFolders.lua load", O and O.layout and F and F.parse)

local function fakeInfo(n)
    local I, order = {}, {}
    for i = 1, n do
        local id = "qa" .. i
        order[i] = id
        I[id] = { name = "QA Mod " .. i, req = {}, after = {}, before = {}, installed = true, hay = "qa mod " .. i .. " qa" .. i }
    end
    return I, order
end

-- ---------------------------------------------------------------------------
section("ORDER: pins, a Load after rule, a circle, the profile file")
-- ---------------------------------------------------------------------------
do
    local I, order = fakeInfo(400)
    I.qa200.req = { "qa10" }
    local lo = { first = { "qa200" }, last = { "qa3" }, rules = { { id = "qa50", how = "after", other = "qa300" } } }
    local out, zone, carried = O.layout(order, I, lo, false)
    check("ORDER pinned first carries what it needs above it", out[1] == "qa10" and out[2] == "qa200" and carried.qa10 == true, join({ out[1], out[2] }))
    check("ORDER pinned last at the bottom", out[#out] == "qa3" and zone.qa3 == 3)
    check("ORDER Load after laid out", idx(out, "qa50") == idx(out, "qa300") + 1)
    local auto = O.layout(out, I, lo, true)
    check("ORDER the rule survives Auto", idx(auto, "qa50") > idx(auto, "qa300"))
    check("ORDER no red row with the pins", O.check(out, I, lo, zone).nBad == 0)
    -- pinned last but needed by a pinned-first mod: carried up, yellow, never red
    local lo2 = { first = { "qa200" }, last = { "qa10" }, rules = {} }
    local out2, zone2 = O.layout(order, I, lo2, false)
    local res2 = O.check(out2, I, lo2, zone2)
    check("ORDER pinned last but needed by a pinned-first mod: carried up, yellow, never red",
        zone2.qa10 == 1 and idx(out2, "qa10") < idx(out2, "qa200") and res2.st[idx(out2, "qa10")] == "soft" and res2.nBad == 0,
        tostring(zone2.qa10) .. " " .. tostring(res2.st[idx(out2, "qa10")]))
    -- qa50 after qa300 after qa301: qa301 after qa50 would close a circle
    lo.rules[#lo.rules + 1] = { id = "qa300", how = "after", other = "qa301" }
    local back = O.reach(I, lo, "qa301", true, false)
    local fwd = O.reach(I, lo, "qa301", false, false)
    check("ORDER the rules' chain is seen (a circle would be refused)", fwd.qa300 and fwd.qa50 and not back.qa50)

    O.load()
    local e = O.entry("ZeDQA order", true)
    e.keep = { "zedqa_unknown=kept", "sep=QA section|qa1;qa2" }
    e.rules = { { id = "qa50", how = "after", other = "qa300" } }
    O.save()
    O.load()
    local e2 = O.entry("ZeDQA order")
    check("ORDER unknown lines survive a save and a reload", e2 and #e2.keep == 2 and e2.keep[1] == "zedqa_unknown=kept", e2 and #e2.keep)
    check("ORDER a later stage's line is in the file", (raw("ZeD_modprofiles.txt") or ""):find("sep=QA section|qa1;qa2", 1, true) ~= nil)
    check("ORDER the profile keeps its rule", e2 and #e2.rules == 1 and e2.rules[1].other == "qa300")
    O.entries()["ZeDQA order"] = nil
    O.save()
end

-- ---------------------------------------------------------------------------
section("SEPS: places, Auto inside a section, off mods kept, a separator moved, the file")
-- ---------------------------------------------------------------------------
do
    local I = fakeInfo(8)
    local A = { uid = O.newUid(), name = "A", on = true, open = true, ids = { "qa3", "qa4", "qa5" } }
    local B = { uid = O.newUid(), name = "B", on = true, open = true, ids = { "qa6", "qa7" } }
    local C = { uid = O.newUid(), name = "C", on = true, open = true, ids = {} }
    local lo = { first = {}, last = {}, rules = {}, top = { "qa1", "qa2" }, seps = { A, B, C } }
    local out, zone, carried, sec = O.layout({ "qa6", "qa1", "qa3", "qa7", "qa2", "qa4", "qa5", "qa8" }, I, lo, false)
    check("SEPS the order follows the separators' places", join(out) == "qa1;qa2;qa3;qa4;qa5;qa6;qa7;qa8", join(out))
    check("SEPS a mod new to the list goes under the last separator", sec.qa8 == C.uid)
    I.qa4.req = { "qa5" }
    I.qa3.req = { "qa7" }
    local auto, z2, _, s2 = O.layout(out, I, lo, true)
    check("SEPS Auto sorts inside a section", idx(auto, "qa5") < idx(auto, "qa4") and s2.qa5 == A.uid and s2.qa4 == A.uid)
    check("SEPS Auto never moves a mod across a separator", s2.qa3 == A.uid and s2.qa7 == B.uid and idx(auto, "qa3") < idx(auto, "qa7"))
    check("SEPS a mod that needs one under a later separator stays red", O.check(auto, I, lo, z2).st[idx(auto, "qa3")] == "bad")
    local onOrder = {}
    for _, id in ipairs(auto) do if id ~= "qa4" then onOrder[#onOrder + 1] = id end end
    O.secSync(lo, onOrder, z2, s2)
    check("SEPS a mod turned off keeps its place under its separator", join(A.ids) == "qa3;qa4;qa5", join(A.ids))
    lo.seps = { B, A, C }
    local g = O.secGroup(auto, z2, s2, lo)
    check("SEPS moving a separator moves its mods with it", idx(g, "qa6") < idx(g, "qa3") and idx(g, "qa7") < idx(g, "qa3") and idx(g, "qa1") < idx(g, "qa6"), join(g))
    check("SEPS the laid-out order holds only mod ids (what the game's mods.txt gets)", (function()
        for _, id in ipairs(g) do if not I[id] then return false end end
        return #g == 8 end)())

    O.load()
    local e = O.entry("ZeDQA separators", true)
    e.order = { "qa1", "qa2", "qa3" }
    local name1 = U(0x5730, 0x56FE)
    e.top = { "qa1" }
    e.seps = { { uid = O.newUid(), name = name1, on = false, open = false, ids = { "qa2" } },
               { uid = O.newUid(), name = "a|b;c", on = true, open = true, ids = { "qa3", "qa9" } } }
    e.keep = { "sep=QA section|qa1;qa2", "zedqa_unknown=kept" }
    O.save()
    local text = raw("ZeD_modprofiles.txt") or ""
    check("SEPS a separator's line: off, collapsed, its name as hex per UTF-16 unit", text:find("sep=0|0|5730,56FE|qa2\n", 1, true) ~= nil)
    check("SEPS the mods above the first separator are kept", text:find("top=qa1\n", 1, true) ~= nil)
    O.load()
    local e2 = O.entry("ZeDQA separators")
    check("SEPS names read back as written", e2 and #e2.seps == 2 and e2.seps[1].name == name1 and e2.seps[2].name == "a|b;c")
    check("SEPS on / off, collapsed and members read back", e2 and e2.seps[1].on == false and e2.seps[1].open == false and join(e2.seps[2].ids) == "qa3;qa9")
    check("SEPS lines ZeD does not know are kept", e2 and #e2.keep == 2)
    O.entries()["ZeDQA separators"] = nil
    O.save()
end

-- ---------------------------------------------------------------------------
section("FOLDERS: ModFolders.cfg, Unfiled, the box")
-- ---------------------------------------------------------------------------
local SAMPLE = table.concat({
    "version=2", "next=4",
    "folder=1|1|5730,56FE", "folder=2|0|43,61,66,E9", "folder=3|1|57,65,61,70,6F,6E,73",
    "member=43,6F,6E,73,74,6F,77,6E,34,32|1", "member=6E,65,77,68,61,72,74,62,75,72,67|1",
    "member=4D,6F,64,46,6F,6C,64,65,72,73|2", "member=5A,65,44,5F,55,49|2",
    "member=47,61,65,6C,47,75,6E,53,74,6F,72,65,5F,42,34,32|3",
    "member=4D,6F,64,65,72,6E,46,69,72,65,61,72,6D,73,53,79,73,74,65,6D|3",
}, "\n") .. "\n"   -- (ZeDUI/ModFolders_sample.cfg, the mod's own save written in the game)
local UNKNOWN = "zedqa_unknown=kept|1"
local TEST = "ZeDQA_ModFolders.cfg"
local function lineOf(text, s)
    local i = 0
    for l in (text or ""):gmatch("([^\n]*)\n") do i = i + 1; if l == s then return i end end
end
do
    F.FILE = TEST
    FILES[TEST] = SAMPLE
    F.load()
    local M = F.get()
    check("FOLDERS the sample's three folders read", #M.folders == 3, #M.folders)
    check("FOLDERS names decoded per UTF-16 unit", M.folders[1].name == U(0x5730, 0x56FE) and M.folders[2].name == "Caf" .. U(0xE9))
    check("FOLDERS open / closed read", M.folders[2].open == false and M.folders[1].open == true)
    check("FOLDERS the lines as read give the sample's text", table.concat(F.lines(M), "\n") .. "\n" == SAMPLE)
    check("FOLDERS written back unchanged: byte for byte", F.change(function() return true end) and raw(TEST) == SAMPLE)

    FILES[TEST] = SAMPLE .. UNKNOWN .. "\n"
    F.load()
    check("FOLDERS a line ZeD does not know is counted", F.cur.bad == 1, F.cur.bad)
    local name = U(0x5730, 0x56FE) .. " Caf" .. U(0xE9)
    local ok, id = F.create(name)
    check("FOLDERS a new folder takes next (4)", ok and id == 4, id)
    check("FOLDERS saved as one hex code per UTF-16 unit", (raw(TEST) or ""):find("folder=4|1|5730,56FE,20,43,61,66,E9\n", 1, true) ~= nil)
    check("FOLDERS next goes up by one", (raw(TEST) or ""):find("next=5\n", 1, true) ~= nil)
    F.load()
    check("FOLDERS read back, the same name", F.byId(4) and F.byId(4).name == name)
    local okA = F.assign({ "ModA", "ModB" }, 4)
    check("FOLDERS two mods moved into the folder", okA and F.folderOf("ModA") == 4 and F.folderOf("ModB") == 4)
    check("FOLDERS Unfiled is never written to the file", not (raw(TEST) or ""):find("nfiled", 1, true))
    check("FOLDERS closing writes |0|", F.setOpen(4, false) and (raw(TEST) or ""):find("folder=4|0|", 1, true) ~= nil)
    check("FOLDERS opening writes |1|", F.setOpen(4, true) and (raw(TEST) or ""):find("folder=4|1|", 1, true) ~= nil)
    local before = raw(TEST)
    local was = F.unfiledOpen()
    F.setUnfiledOpen(not was)
    check("FOLDERS Unfiled's state goes to ZeD_modfolders.txt", raw("ZeD_modfolders.txt") == "unfiledOpen=" .. ((not was) and "1" or "0") .. "\n", raw("ZeD_modfolders.txt"))
    check("FOLDERS ModFolders.cfg is not written for Unfiled", raw(TEST) == before)
    F.setUnfiledOpen(was)
    check("FOLDERS Move up moves the folder", F.moveFolder(4, -1) and F.folders()[3].id == 4)
    check("FOLDERS delete: the folder is gone from the file", F.delete(4) and F.byId(4) == nil and not (raw(TEST) or ""):find("folder=4|", 1, true))
    check("FOLDERS delete: its mods are in Unfiled", F.folderOf("ModA") == nil and F.folderOf("ModB") == nil)
    check("FOLDERS the unknown line is kept through every change", lineOf(raw(TEST), UNKNOWN) ~= nil)
    check("FOLDERS the other folders' lines are as they were", #F.folders() == 3 and (raw(TEST) or ""):find("folder=1|1|5730,56FE\n", 1, true) ~= nil)
    FILES[TEST] = raw(TEST) .. "folder=9|1|51,41\n"
    local okN, idN = F.create("QA new")
    check("FOLDERS an outside edit is kept (the change reads the file first)", okN and idN == 10 and (raw(TEST) or ""):find("folder=9|1|51,41\n", 1, true) ~= nil, idN)
    local fsrc = readSrc("ZeD_ModFolders.lua")
    check("FOLDERS the folders never turn a mod on or off, nor move the load order",
        not fsrc:find("forceActivateMods", 1, true) and not fsrc:find("setModActive", 1, true) and not fsrc:find("correctAndSaveModOrder", 1, true))
    local ssrc = readSrc("ZeD_MainMenuModsSeps.lua")
    check("SEPS separators never write the folders file", not (ssrc:find("F.create(", 1, true) or ssrc:find("F.assign(", 1, true)
        or ssrc:find("F.delete(", 1, true) or ssrc:find("F.rename(", 1, true) or ssrc:find("F.setOpen(", 1, true) or ssrc:find("F.moveFolder(", 1, true)))
end

-- the folder's box (ZeD_MainMenuModsFolders.lua's folderBox) on a made-up list
do
    local fsrc = readSrc("ZeD_MainMenuModsFolders.lua")
    local a = fsrc:find("function ZeD_MMMods:folderBox(fid)", 1, true)
    local b = a and fsrc:find("\nend\n", a, true)
    check("FOLDERS folderBox found", a and b)
    if a and b then
        ZeD_MMMods = {}
        local m = { mods = {}, sortedMods = {} }
        for _, id in ipairs({ "BoxA", "BoxB", "Else" }) do
            local d = { modId = id, name = id, isActive = false, modInfo = id }
            m.mods[id] = d; m.sortedMods[#m.sortedMods + 1] = d
        end
        function m:forceActivateMods(info, on) self.mods[info].isActive = on end
        ModSelector = { instance = { model = m } }
        local chunk = assert(loadstring("local MM, F, EMPTY = ...\nlocal function model() return ModSelector.instance.model end\n"
            .. "local function activeSet(m) local s = {} for id, d in pairs(m.mods or EMPTY) do if d.isActive then s[id] = true end end return s end\n"
            .. fsrc:sub(a, b + 4)))
        chunk({ hoverSound = noop, clickSound = noop }, F, {})
        local page = setmetatable({ say = noop, dirty = noop,
            modsOnBatch = function(_, ids) for _, id in ipairs(ids) do m.mods[id].isActive = true end; return ids, {} end }, { __index = ZeD_MMMods })
        local _, fid = F.create("QA Box")
        F.assign({ "BoxA", "BoxB" }, fid)
        local function on(id) return m.mods[id].isActive end
        page:folderBox(fid)
        check("FOLDERS the box turns every mod in the folder on", on("BoxA") and on("BoxB") and not on("Else"))
        m.mods.BoxA.isActive = false
        page:folderBox(fid)
        check("FOLDERS mixed: the box turns all on", on("BoxA") and on("BoxB"))
        page:folderBox(fid)
        check("FOLDERS all on: the box turns all off", not on("BoxA") and not on("BoxB") and not on("Else"))
    end
end

-- Start separators from folders (ZeD_MainMenuModsSeps.lua's sepFromFolders) on a made-up list
do
    local ssrc = readSrc("ZeD_MainMenuModsSeps.lua")
    local a = ssrc:find("function ZeD_MMMods:sepFromFolders(confirmed)", 1, true)
    local b = a and ssrc:find("\nend\n", a, true)
    check("SEPS sepFromFolders found", a and b)
    if a and b then
        ZeD_MMMods = {}
        assert(loadstring("local MM, O, F = ...\n" .. ssrc:sub(a, b + 4)))({ hoverSound = noop, clickSound = noop }, O, F)
        FILES[TEST] = "version=2\nnext=1\n"
        F.load()
        local _, f1 = F.create("QA First")
        local _, f2 = F.create("QA Second")
        F.assign({ "m2", "mOff" }, f1)        -- mOff is in the folder but off (not in the order)
        F.assign({ "m4" }, f2)
        local folders0 = raw(TEST)
        local asked
        local page = setmetatable({ page = "order", order = { "m1", "m2", "m3", "m4", "ZeD_Picks" }, oZone = { ZeD_Picks = 3 },
            oLo = { first = {}, last = {}, rules = {}, seps = { { uid = 99, name = "Old", on = true, open = true, ids = {} } }, top = {} },
            setConfirm = function(self, c) asked = c; self.confirm = c or nil end, say = noop, orderSnap = noop, orderLayout = noop,
            orderCheck = function() return { nBad = 0 } end, sepSelect = noop }, { __index = ZeD_MMMods })
        page:sepFromFolders(false)
        check("SEPS from folders: with separators already there, it asks first", asked == "sreplace" and page.oLo.seps[1].name == "Old")
        page:sepFromFolders(true)
        local s = page.oLo.seps
        check("SEPS from folders: one separator per folder, in the folders' order, only its mods that are on",
            #s == 3 and s[1].name == "QA First" and join(s[1].ids) == "m2" and s[2].name == "QA Second" and join(s[2].ids) == "m4", #s)
        check("SEPS from folders: the rest under Unfiled, last; the pinned helper stays out",
            s[3] and s[3].name == "UI_ZeD_Folders_Unfiled" and join(s[3].ids) == "m1;m3", s[3] and join(s[3].ids))
        check("SEPS from folders: nothing turned on or off (the order as it was)", join(page.order) == "m1;m2;m3;m4;ZeD_Picks")
        check("SEPS from folders: the folders file is not touched", raw(TEST) == folders0)
        F.rename(f1, "QA First renamed")
        check("SEPS a folder renamed later leaves its separator's name", s[1].name == "QA First")
    end
end

print("mods_lists_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
