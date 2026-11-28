-- ZeDUI/tools/qa/order_menu_fixes_sim.lua  (Nov 27 2026, Build): the Mods screen's folder and load order fixes from QA's
-- menus sweep, with no game running: the real ZeD_ModOrder.lua, ZeD_ModFolders.lua, ZeD_MainMenuModsFolders.lua and
-- ZeD_MainMenuModsOrder.lua on an in-memory file system (stubs as mods_lists_sim.lua).
--   * MO5: a deleted folder's color and label go with it
--   * MO8: Move to folder says how many moved, not how many were picked
--   * MO9: a refused New folder, open or delete says its own reason (full, a name taken, gone), not the file
--   * MO12: Delete folder's question counts the mods not installed that go too
--   * MO13: closing a folder by its triangle hands a hidden focused row's focus to the folder
--   * MO32: Done refused says "or press Auto" only when Auto would clear the red rows
-- What it can't show: the bands and rows on screen, MO43's row reason (mu_order.lua MO43).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/order_menu_fixes_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]order_menu_fixes_sim%.lua$", "")
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


-- the screen: just enough of ZeD_MMMods and the main menu for the two screen files
local said = {}
local lastAsk = nil
require = noop
Events = setmetatable({}, { __index = function() return { Add = noop, Remove = noop } end })
getText = function(k) return k end
ZeD.T = { px = function(v) return v end, scale = 1 }
ZeD.MainMenu = { U = {}, ctx = {}, clickSound = noop, hoverSound = noop, now = function() return 0 end,
                 ui = { stripSpecs = function(_, _, _, _, _, _, ask) lastAsk = ask end } }
ZeD_MMMods = {}
kload("ZeD_MainMenuModsFolders.lua")
kload("ZeD_MainMenuModsOrder.lua")
check("the two screen files load", ZeD_MMMods.folderMove ~= nil and ZeD_MMMods.orderDone ~= nil)

local mods = {}
ModSelector = { instance = { model = { mods = mods, sortedMods = {} } } }
local function screen()
    local s = setmetatable({}, { __index = ZeD_MMMods })
    s.say = function(_, t) said[#said + 1] = t end
    s.setConfirm = function(self, m) self.confirm = m end
    s.find = { getInternalText = function() return "" end, setText = noop, isFocused = function() return false end, unfocus = noop }
    s.field = { getText = function() return s._text or "" end }
    return s
end
local function lastSaid() return tostring(said[#said]) end
local CFG = "ModFolders.cfg"
local function file(lines) FILES[CFG] = table.concat(lines, "\n") .. "\n"; F.load() end

section("MO5: a deleted folder's color and label go")
do
    file({})
    local ok, id = F.create("QA Doomed")
    check("a folder made", ok and id, tostring(id))
    ZeD_MMMods.setFolderColor(id, "red")
    F.setLabel(id, "blue")
    check("it has both", ZeD_MMMods.folderColorKey(id) == "red" and F.labelOf(id) == "blue")
    F.delete(id)
    check("deleted: no color", ZeD_MMMods.folderColorKey(id) == nil, ZeD_MMMods.folderColorKey(id))
    check("deleted: no label", F.labelOf(id) == nil, F.labelOf(id))
    file({})
    local _, id2 = F.create("QA Fresh")
    check("a new folder with the number starts plain", id2 == id and ZeD_MMMods.folderColorKey(id2) == nil and F.labelOf(id2) == nil)
    check("the colors file no longer names it", not (FILES["ZeD_folder_colors.txt"] or ""):find("\n" .. id .. "=", 1, true))
end

section("MO8: the moved count")
do
    local L = { "version=2", "next=2", "folder=1|1|" .. F.encode("QA Dest") }
    for i = 1, 3 do L[#L + 1] = "member=" .. F.encode("zqa" .. i) .. "|1" end
    file(L)
    local s = screen()
    s:folderMove({ "zqa1", "zqa2", "zqa3", "zqa4", "zqa5" }, 1)
    check("five picked, three there: says two moved", lastSaid() == "UI_ZeD_Folders_SayMovedMany|2|QA Dest", lastSaid())
    s:folderMove({ "zqa1", "zqa6" }, 1)
    check("two picked, one there: says one moved", lastSaid() == "UI_ZeD_Folders_SayMovedCountOne|QA Dest|QA Dest", lastSaid())
    s:folderMove({ "zqa7" }, 1)
    check("one picked names it", lastSaid() == "UI_ZeD_Folders_SayMovedOne|zqa7|QA Dest", lastSaid())
    s:folderMove({ "zqa1", "zqa2", "zqa9" }, nil)
    check("out: says how many came out", lastSaid() == "UI_ZeD_Folders_SayOutMany|2", lastSaid())
end

section("MO9: a refusal says its reason")
do
    local L = { "version=2", "next=100" }
    for i = 1, 99 do L[#L + 1] = "folder=" .. i .. "|1|" .. F.encode("QA F" .. i) end
    file(L)
    local ok, why = F.create("QA One more")
    check("F.create at 99: full", ok == false and why == "full", tostring(why))
    local s = screen()
    s._text = "QA One more"
    s:folderFieldEnter("fnew")
    check("the band says full, not the file", lastSaid() == "UI_ZeD_Folders_HelpFull", lastSaid())
    file({ "version=2", "next=2", "folder=1|1|" .. F.encode("QA Taken") })
    local ok2, why2, arg2 = F.create("qa taken")
    check("F.create with a name taken: its key and the name", ok2 == false and why2 == "UI_ZeD_Folders_NameUsed" and arg2 == "QA Taken", tostring(why2))
    -- the file changes outside while the name field is open: the name is taken meanwhile
    FILES[CFG] = "version=2\nnext=3\nfolder=1|1|" .. F.encode("QA Taken") .. "\nfolder=2|1|" .. F.encode("QA Late") .. "\n"
    s._text = "QA Late"
    s:folderFieldEnter("fnew")
    check("taken meanwhile: says so", lastSaid() == "UI_ZeD_Folders_NameUsed|QA Late", lastSaid())
    check("F.setOpen on a folder gone: gone", select(2, F.setOpen(42, false)) == "gone")
    check("F.delete on a folder gone: gone", select(2, F.delete(42)) == "gone")
    F.load()
    s._fTarget = 2
    FILES[CFG] = "version=2\nnext=3\nfolder=1|1|" .. F.encode("QA Taken") .. "\n"   -- (deleted outside)
    s:folderDelete()
    check("Delete on a folder deleted outside: gone", lastSaid() == "UI_ZeD_Folders_SayGone", lastSaid())
end

section("MO12: Delete folder's question counts what is not installed")
do
    mods.zin = { modId = "zin", name = "zin" }
    file({ "version=2", "next=2", "folder=1|1|" .. F.encode("QA Del"), "member=" .. F.encode("zin") .. "|1",
           "member=" .. F.encode("zgone1") .. "|1", "member=" .. F.encode("zgone2") .. "|1" })
    local s = screen()
    s.folderView = function() return { tot = { [1] = 1 } } end
    s._fTarget, s.confirm = 1, "fdelete"
    s:folderStrip(0, 30, 600, 1)
    check("two not installed: said", tostring(lastAsk) == "UI_ZeD_Folders_AskDeleteOne|QA Del UI_ZeD_Folders_AskDeleteMissingMany|2", lastAsk)
    file({ "version=2", "next=2", "folder=1|1|" .. F.encode("QA Del"), "member=" .. F.encode("zin") .. "|1" })
    s:folderStrip(0, 30, 600, 1)
    check("none not installed: nothing added", tostring(lastAsk) == "UI_ZeD_Folders_AskDeleteOne|QA Del", lastAsk)
    mods.zin = nil
end

section("MO13: closing by the triangle moves a hidden row's focus to the folder")
do
    file({ "version=2", "next=2", "folder=1|1|" .. F.encode("QA Open"), "member=" .. F.encode("za") .. "|1" })
    local s = screen()
    s.focusId, s.sel = "mrow:za", "za"
    s:folderOpenClose({ f = true, fkey = 1, open = true, sid = "frow:1" })
    check("the folder closed", F.byId(1).open == false)
    check("the focus is on the folder's row", s.focusId == "frow:1" and s.fsel == 1 and s.sel == nil, s.focusId)
    -- a row in another folder keeps the focus
    file({ "version=2", "next=3", "folder=1|1|" .. F.encode("QA Open"), "folder=2|1|" .. F.encode("QA Other"),
           "member=" .. F.encode("za") .. "|1", "member=" .. F.encode("zb") .. "|2" })
    s.focusId = "mrow:zb"
    s:folderOpenClose({ f = true, fkey = 1, open = true, sid = "frow:1" })
    check("a row in another folder keeps it", s.focusId == "mrow:zb", s.focusId)
end

section("MO32: Done offers Auto only when Auto would fix it")
do
    -- qa2 needs qa1 and loads before it: Auto fixes that
    local I = { qa1 = { name = "qa1", req = {}, after = {}, before = {}, installed = true }, qa2 = { name = "qa2", req = { "qa1" }, after = {}, before = {}, installed = true } }
    local s = screen()
    s.page, s.order, s.oInfo, s.oLo, s.oZone, s.oVer = "order", { "qa2", "qa1" }, I, O.copyLo(nil), {}, 1
    s.leaveOrder = noop
    check("a red row", s:orderCheck().firstBad ~= nil)
    check("Auto would fix it", s:orderAutoFixes() == true)
    s:orderDone()
    check("so the refusal offers Auto", lastSaid() == "UI_ZeD_Mods_RuleFix", lastSaid())
    -- a requirement not installed: Auto cannot
    I.qa2.req = { "qa_absent" }
    s.oVer = 2
    check("red for good", s:orderCheck().firstBad ~= nil)
    check("Auto would not fix it", s:orderAutoFixes() == false)
    s:orderDone()
    check("so the refusal does not offer Auto", lastSaid() == "UI_ZeD_Mods_RuleFixHand", lastSaid())
    check("Auto was tried on copies: the order stands", s.order[1] == "qa2" and s.order[2] == "qa1")
end

print("order_menu_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
