-- ZeDUI/tools/qa/fix_mods_msgs_sim.lua  (Nov 12 2026): the Mods screen's file picks, Files tab and conflict scan, the
-- fixes of the review of Nov 12, with no game running. The real ZeD_VanillaLua, ZeD_ModPicks, ZeD_ModFiles,
-- ZeD_ModScan, ZeD_ModReset, ZeD_MainMenuModsPanes and ZeD_MainMenuModsFiles run on Lua 5.1 against stubs of the game
-- (mods on disk with their own folders, Zomboid/Lua, the engine's rule that the last mod to ship a Lua path runs it)
-- and the game's own ModSelectorModel.lua (vanilla's model, read from the install, for a server's list).
--   PICKOFF  a path picked and switched off at once keeps both through a reload of the list
--   OTHER    a file another mod's copy stands in for: never stubbed for that mod, and no switch on its Files tab
--   MENU     the main menu rebuilds the helper's copies at launch (a mod Steam updated, or took away) and asks the
--            game's deferred reload once; never after a reset (a save's list, Accept, its own reload)
--   FRAME    the Files tab's reading moves on once a frame, however many rows ask; a long file carries over
--   SERVER   a server's list: no switching back on, and the helper's copies follow the player's own list
--   TAKEOVER a shadowed copy (one that never runs) never takes the switch-off of the mod whose copy runs
--   OWN      ZeD-GUI's own files and ZeD picks' copies are never switched off
--   MEDIA    a Steam library under a folder called Media (or /run/media/): the Files tab, the conflict scan and
--            Reset settings still find a mod's files in sub-folders
-- Run from the repo root:  lua51 ZeDUI/tools/qa/fix_mods_msgs_sim.lua [path to the game's ModSelectorModel.lua]
-- It prints FAIL lines and a last line "fix_mods_msgs_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]fix_mods_msgs_sim%.lua$", "")
local VANILLA = arg and arg[1] or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/client/OptionScreens/ModSelector/ModSelectorModel.lua"
local ZDIR = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end

-- ---------------------------------------------------------------------------
-- THE GAME
-- ---------------------------------------------------------------------------
-- events: handlers kept by name; fire runs a copy of the list (a handler may remove itself)
local HANDLERS = {}
Events = setmetatable({}, { __index = function(t, k)
    local e = {}
    e.Add = function(fn) local l = HANDLERS[k] or {}; HANDLERS[k] = l; l[#l + 1] = fn end
    e.Remove = function(fn) local l = HANDLERS[k] or {}; for i = #l, 1, -1 do if l[i] == fn then table.remove(l, i) end end end
    rawset(t, k, e)
    return e
end })
local function fire(name, ...)
    local copy = {}
    for i, fn in ipairs(HANDLERS[name] or {}) do copy[i] = fn end
    for _, fn in ipairs(copy) do fn(...) end
end
function require() end

-- a Java list
local function jl(t)
    t = t or {}
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
             clear = function() for i = #t, 1, -1 do t[i] = nil end end, add = function(_, v) t[#t + 1] = v end, _t = t }
end

-- mods on disk: id -> { dir, files = { ["media/lua/client/x.lua"] = { lines } } } (version and common folder as one)
local DISK = {}
local function mod(id, files, dir, req) DISK[id] = { dir = dir or ("C:/Mods/" .. id), files = files or {}, req = req } end
local function findKey(t, path)
    local want = string.lower(path)
    for k in pairs(t) do if string.lower(k) == want then return k end end
    return nil
end
function getModInfoByID(id)
    local m = DISK[id]
    if not m then return nil end
    return { getVersionDir = function() return m.dir .. "/42" end, getCommonDir = function() return m.dir .. "/common" end,
             getName = function() return id end, getId = function() return id end, getDir = function() return m.dir end,
             isAvailable = function() return true end, getIncompatible = function() return nil end,
             getRequire = function() return m.req and jl(m.req) or nil end, getWorkshopID = function() return "" end }
end
-- the reading: every line handed out is counted, every reader opened and shut too
local READ = { lines = 0, opened = 0, closed = 0, perLine = nil }
local function reader(lines)
    local i = 0
    READ.opened = READ.opened + 1
    return { readLine = function()
                 i = i + 1
                 local l = lines[i]
                 if l ~= nil then READ.lines = READ.lines + 1; if READ.perLine then READ.perLine() end end
                 return l
             end,
             close = function() READ.closed = READ.closed + 1 end }
end
local function writer(onClose)
    local buf = {}
    return { write = function(_, s) buf[#buf + 1] = s end, close = function() onClose(table.concat(buf)) end }
end
local function toLines(s)
    local t = {}
    for l in (s .. (s:sub(-1) == "\n" and "" or "\n")):gmatch("([^\n]*)\n") do t[#t + 1] = l end
    return t
end
function getModFileReader(id, path)
    local m = DISK[id]
    local k = m and findKey(m.files, path)
    return k and reader(m.files[k]) or nil
end
function getModFileWriter(id, path)
    local m = DISK[id]
    if not m then return nil end
    return writer(function(s) m.files[findKey(m.files, path) or path] = toLines(s) end)
end
function listFilesInModDirectory(id, dir)
    local m = DISK[id]
    local out = {}
    if not m then return jl(out) end
    for k in pairs(m.files) do
        local d, n = k:match("^(.*)/([^/]+)$")
        if d and string.lower(d) == string.lower(dir) then out[#out + 1] = n end
    end
    table.sort(out)
    return jl(out)
end
-- Zomboid/Lua
local LUA = {}
function getFileReader(name) return LUA[name] and reader(LUA[name]) or nil end
function getFileWriter(name) return writer(function(s) LUA[name] = toLines(s) end) end
function listFilesInZomboidLuaDirectory(dir)
    local out = {}
    for name in pairs(LUA) do
        local d, n = name:match("^(.*)/([^/]+)$")
        if not d then d, n = "", name end
        if d == dir then out[#out + 1] = n end
    end
    return jl(out)
end

-- the engine: the load order's mods, a later mod's path replacing an earlier one's; what runs per path
local ORDER = {}
local function activeMap()
    local map = {}
    for _, id in ipairs(ORDER) do
        if DISK[id] then for k in pairs(DISK[id].files) do map[string.lower(k)] = { id = id, path = k } end end
    end
    return map
end
local function runs(path)
    local e = activeMap()[string.lower(path)]
    return e and e.id, e and table.concat(DISK[e.id].files[e.path], "\n")
end
local loaded = {}
local function boot(order)
    ORDER = order
    loaded = {}
    for _, e in pairs(activeMap()) do loaded[#loaded + 1] = DISK[e.id].dir .. "/42/" .. e.path end
    table.sort(loaded)
end
function getLoadedLuaCount() return #loaded end
function getLoadedLua(i) return loaded[i + 1] end
function getActivatedMods() return jl(ORDER) end

local CLOCK = 1000
function getTimestampMs() return CLOCK end
local RESETS = {}
GAMEVER = "42.22.2 abcdef"
function getCore()
    return { getVersion = function() return GAMEVER end, getOptionModsEnabled = function() return true end,
             DelayResetLua = function(_, mods, why) RESETS[#RESETS + 1] = tostring(mods) .. "|" .. tostring(why) end }
end
function getScriptManager() return {} end

ZeD = { tr = function(k, ...)
    local a = { ... }
    local t = {}
    for i = 1, #a do t[i] = tostring(a[i]) end
    return k .. (#a > 0 and ("(" .. table.concat(t, ",") .. ")") or "")
end }
ZeD.ModSettings = {
    readLines = function(id, path)
        local r = getModFileReader(id, path)
        if not r then return nil end
        local t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
        return t
    end,
    reset = noop,
}

local function load(rel) assert(loadfile(ZDIR .. rel))() end
local function lines(n, fn) local t = {}; for i = 1, n do t[i] = fn(i) end; return t end
local function text(id, path)
    local k = DISK[id] and findKey(DISK[id].files, path)
    return k and table.concat(DISK[id].files[k], "\n") or nil
end

-- a fresh Lua load of these files (a restart, or a reset): the engine drops every handler first. The files keep
-- their tables (ZeD.ModPicks = ZeD.ModPicks or {}), so the Files tab, loaded once, sees the fresh functions too
local function reloadPicks()
    HANDLERS = {}
    load("ZeD_ModPicks.lua")
    load("ZeD_ModFiles.lua")
    return ZeD.ModPicks, ZeD.ModFiles
end
-- the Files tab's read for this frame (before the fix the scan moved on wherever it was asked: F.scan)
local function step(modId) return (ZeD.ModFiles.step or ZeD.ModFiles.scan)(modId) end

load("ZeD_VanillaLua.lua")
local P, F = reloadPicks()
check("the files load", P and F and P.sync and F.files)
local function helperRuns(path) local who, t = runs(path); return who == P.HELPER, t end

-- ---------------------------------------------------------------------------
section("PICKOFF: a path picked and switched off keeps both")
-- ---------------------------------------------------------------------------
local X = "media/lua/client/Shared.lua"
mod("ModA", { [X] = { "-- A's Shared", "SharedA = {}" } })
mod("ModB", { [X] = { "-- B's Shared", "SharedB = {}" } })
mod("ZeD_UI", { ["media/lua/client/ZeD/ZeD_ModPicks.lua"] = { "-- ZeD's own ModPicks", "ZeD = ZeD or {}" } })
mod("ZeD_Picks", {}, nil, { "ZeD_UI" })
local OWN = { "ModA", "ModB", "ZeD_UI", "ZeD_Picks" }
boot(OWN)
P.commit({ X }, { [X] = "ModA" })
P.setOff("ModA", { X }, true)
local list = table.concat(LUA["ZeD_picks.txt"], "\n")
check("PICKOFF: the list has the pick line", list:find("pick=" .. X .. "|ModA", 1, true) ~= nil, list)
check("PICKOFF: and the off line", list:find("off=" .. X .. "|ModA", 1, true) ~= nil, list)
P, F = reloadPicks()
check("PICKOFF: after a reload the pick is still there", P.pickOf(X) == "ModA", P.pickOf(X))
check("PICKOFF: and the switch-off", P.offOf(X) == "ModA", P.offOf(X))
check("PICKOFF: the helper's chip counts the path once (picked and off)", P.changedCount and P.changedCount() == 1, P.changedCount and P.changedCount())
P.sync(OWN)
boot(OWN)
check("PICKOFF: while off, the picked copy is the one stubbed", (select(2, helperRuns(X)) or ""):find("switched off", 1, true) ~= nil)
P.setOff("ModA", { X }, false)
P, F = reloadPicks()
P.sync(OWN)
boot(OWN)
local _, backText = helperRuns(X)
check("PICKOFF: back on after a reload, the picked copy runs again (not load order's)", backText == text("ModA", X), backText)
-- the other order: off first, then the pick
P.commit({ X }, {})
P.setOff("ModB", { X }, true)
P.commit({ X }, { [X] = "ModA" })
P, F = reloadPicks()
check("PICKOFF: switched off first, picked after: both kept", P.pickOf(X) == "ModA" and P.offOf(X) == "ModB", tostring(P.pickOf(X)) .. " " .. tostring(P.offOf(X)))
P.setOff("ModB", { X }, false)
P.commit({ X }, {})

-- ---------------------------------------------------------------------------
section("OTHER: a file another mod's copy stands in for")
-- ---------------------------------------------------------------------------
-- (no pick: ModB loads later, so ModB's copy is the one that runs)
P.setOff("ModA", { X }, true)
P.sync(OWN)
boot(OWN)
local _, otherText = helperRuns(X)
check("OTHER: ModA's shadowed copy switched off: ModB's copy still runs", otherText == text("ModB", X), otherText)
P.setOff("ModB", { X }, true)
P.sync(OWN)
boot(OWN)
check("OTHER: ModB's own copy switched off: nothing runs", (select(2, helperRuns(X)) or ""):find("switched off", 1, true) ~= nil)
P.commit({ X }, { [X] = "ModA" })
P.sync(OWN)
boot(OWN)
check("OTHER: ModB off but ModA picked: ModA's copy runs", select(2, helperRuns(X)) == text("ModA", X), select(2, helperRuns(X)))
P.setOff("ModB", { X }, false)
P.commit({ X }, {})
P.sync(OWN)

-- the Files tab, on the real conflict scan
ZeD.MainMenu = { U = {}, ui = {}, clickSound = noop, hoverSound = noop, now = function() return 0 end }
ZeD.ModSafety, ZeD.ModReset = { reset = noop }, nil
ZeD_MMOptions = {}
ZeD_MMMods = {}
ZeD.ModScan = nil
load("ZeD_ModScan.lua")
local MS = ZeD.ModScan
load("ZeD_ModReset.lua")
load("ZeD_MainMenuModsPanes.lua")
load("ZeD_MainMenuModsFiles.lua")
boot({ "ModA", "ModB", "ZeD_UI", "ZeD_Picks" })
MS.start()
for _ = 1, 200 do MS.step(); if MS.res.done then break end end
check("OTHER: the scan finds ModA and ModB's shared file", MS.res.done and #(MS.res.byMod.ModA or {}) == 1, MS.res.done)
P.helper = function() return getModInfoByID("ZeD_Picks") end
local MODS = {}
for _, id in ipairs({ "ModA", "ModB", "ZeD_UI", "ZeD_Picks" }) do MODS[id] = { modId = id, name = id, isActive = true, modInfo = getModInfoByID(id) } end
ModSelector = { instance = { model = { mods = MODS } } }
local said = nil
local W = setmetatable({ dirty = noop, say = function(_, t) said = t end, afterPicks = function() P.sync(ORDER) end, _filesSeen = {} },
                       { __index = ZeD_MMMods })
local function fileOf(id, path) F.forget(); for _, f in ipairs(F.files(id)) do if f.path == path then return f end end end
local fa, fb = fileOf("ModA", X), fileOf("ModB", X)
check("OTHER: the file is on both mods' Files tabs", fa ~= nil and fb ~= nil)
check("OTHER: on ModA's tab it never runs (ModB's copy does)", W:fileState(MODS.ModA, fa) == "other", W:fileState(MODS.ModA, fa))
check("OTHER: and the copy that runs is named", W.fileRunsFrom and W:fileRunsFrom(MODS.ModA, fa) == "ModB", W.fileRunsFrom and W:fileRunsFrom(MODS.ModA, fa))
check("OTHER: on ModB's tab it is on", W:fileState(MODS.ModB, fb) == "on", W:fileState(MODS.ModB, fb))
W:fileA(MODS.ModA, fa)
check("OTHER: the box (or A) on ModA's copy switches nothing, its card opens", P.offOf(X) == nil and W.fileSel == X, P.offOf(X))
P.commit({ X }, { [X] = "ModA" })
check("OTHER: ModA picked: on ModA's tab it runs", W:fileState(MODS.ModA, fa) == "on", W:fileState(MODS.ModA, fa))
check("OTHER: ModA picked: on ModB's tab ModA's copy stands in", W:fileState(MODS.ModB, fb) == "other" and W:fileRunsFrom(MODS.ModB, fb) == "ModA")
P.commit({ X }, {})

-- ---------------------------------------------------------------------------
section("MENU: the copies rebuilt at the main menu")
-- ---------------------------------------------------------------------------
local Y = "media/lua/client/CThing.lua"
mod("ModC", { [Y] = { "-- C v1", "CThing = {}" } })
local WITH_C = { "ModA", "ModB", "ModC", "ZeD_UI", "ZeD_Picks" }
boot(WITH_C)
P.setOff("ModC", { Y }, true)
P.setOff("ModC", { Y }, false)
P.sync(WITH_C)
boot(WITH_C)
check("MENU: switched off and back on, the helper holds ModC's text", select(2, helperRuns(Y)) == "-- C v1\nCThing = {}")
-- Steam updates ModC; the game starts again (no reset: OnResetLua does not fire)
DISK.ModC.files[Y] = { "-- C v2", "CThing = { v = 2 }" }
local function launch(why)
    P, F = reloadPicks()
    RESETS = {}
    fire("OnMainMenuEnter")
    if why then fire("OnResetLua", why) end
    fire("OnFETick", 0)
    fire("OnFETick", 0)
end
launch(nil)
check("MENU: at launch the helper's copy follows the update", text("ZeD_Picks", Y) == "-- C v2\nCThing = { v = 2 }", text("ZeD_Picks", Y))
check("MENU: and the game's deferred reload is asked for, once", #RESETS == 1 and RESETS[1]:sub(1, 8) == "default|", table.concat(RESETS, ","))
local why = RESETS[1] and RESETS[1]:match("|(.*)$")
launch(why)
check("MENU: the reload it asked for does not ask again", #RESETS == 0, table.concat(RESETS, ","))
launch(nil)
check("MENU: a launch with nothing stale asks nothing", #RESETS == 0, table.concat(RESETS, ","))
-- a reset for a save's list (another list loaded, a game starting): left alone
DISK.ModC.files[Y] = { "-- C v3" }
launch("continueSave")
check("MENU: after a reset (a save is loading) nothing is written", text("ZeD_Picks", Y) == "-- C v2\nCThing = { v = 2 }", text("ZeD_Picks", Y))
check("MENU: and no reload is asked for", #RESETS == 0, table.concat(RESETS, ","))
-- the helper not loaded: its copies do not run, so nothing to reload
boot({ "ModA", "ModB", "ModC", "ZeD_UI" })
launch(nil)
check("MENU: the helper off: no reload", #RESETS == 0, table.concat(RESETS, ","))
-- a QA autoload launch continues a save by itself: the copies are rebuilt, no reload
boot(WITH_C)
ZeD.QAAutoload = true
launch(nil)
check("MENU: a QA autoload launch rebuilds the copy", text("ZeD_Picks", Y) == "-- C v3", text("ZeD_Picks", Y))
check("MENU: and asks no reload", #RESETS == 0, table.concat(RESETS, ","))
ZeD.QAAutoload = nil
-- the player unsubscribes ModC: its copy must not keep running from the helper
DISK.ModC = nil
boot({ "ModA", "ModB", "ZeD_UI", "ZeD_Picks" })
launch(nil)
check("MENU: a mod taken away: the helper's copy does nothing now", (text("ZeD_Picks", Y) or ""):find("no mod that is on ships", 1, true) ~= nil, text("ZeD_Picks", Y))
check("MENU: and a reload puts it in place", #RESETS == 1, table.concat(RESETS, ","))
-- a write that does not take asks no reload (it would ask again at every launch)
mod("ModC", { [Y] = { "-- C v4" } })
boot(WITH_C)
local realWriter = getModFileWriter
getModFileWriter = function() return writer(noop) end
launch(nil)
getModFileWriter = realWriter
check("MENU: a copy that could not be written asks no reload", #RESETS == 0, table.concat(RESETS, ","))
P.sync(WITH_C)

-- ---------------------------------------------------------------------------
section("FRAME: the Files tab reads once a frame")
-- ---------------------------------------------------------------------------
local BIG = "media/lua/client/BigLemma.lua"
mod("Big", {
    [BIG] = lines(10000, function(i) return (i == 1) and "BigLemma = {}" or ("BigLemma[" .. i .. "] = \"word" .. i .. "\"") end),
    ["media/lua/client/BigUser.lua"] = { "require \"BigLemma\"", "BigUser = {}", "function BigUser.go() return BigLemma[2] end" },
    ["media/lua/client/BigAlone.lua"] = { "BigAlone = {}" },
})
mod("Small", { ["media/lua/client/SmallOne.lua"] = { "SmallOne = {}" } })
boot({ "Big", "Small", "ZeD_UI", "ZeD_Picks" })
F.forget()
READ.lines, READ.opened, READ.closed = 0, 0, 0
step("Big")
local first = READ.lines
check("FRAME: one frame reads at most its share (4000 lines), even with a file of 10000", first > 0 and first <= 4000, first)
for _ = 1, 20 do F.usedBy("Big", BIG); F.usedBy("Big", "media/lua/client/BigUser.lua") end
F.scan("Big")
check("FRAME: the rows' used-by and the card read nothing more in that frame", READ.lines == first, READ.lines - first)
local res
for _ = 1, 20 do res = step("Big"); if res then break end end
check("FRAME: the scan finishes over the next frames", res ~= nil)
local e = res and res.byPath[BIG]
check("FRAME: the long file is read whole, carried across frames", e and e.lines == 10000, e and e.lines)
check("FRAME: and never twice", READ.lines == 10000 + 3 + 1, READ.lines)
check("FRAME: its first lines are its own first lines", e and e.first[1] and e.first[1].n == 1 and e.first[1].text == "BigLemma = {}")
local used = F.usedBy("Big", BIG)
check("FRAME: used by is found as before", used and #used == 1 and used[1] == "media/lua/client/BigUser.lua", used and table.concat(used, ","))
check("FRAME: every file opened is shut", READ.opened == READ.closed, READ.opened .. " " .. READ.closed)
-- a slow game: the share also ends after a few milliseconds
F.forget()
READ.lines = 0
READ.perLine = function() CLOCK = CLOCK + 1 end
step("Big")
READ.perLine = nil
check("FRAME: a frame also stops after a few milliseconds of reading", READ.lines <= 200, READ.lines)
-- another mod's tab takes over: the open file is shut, and read again from its start later
step("Small")
check("FRAME: the first mod's open file is shut when another mod reads", READ.opened == READ.closed, READ.opened .. " " .. READ.closed)
for _ = 1, 200 do res = step("Big"); if res then break end end
check("FRAME: the first mod still reads to the end, its file whole", res and res.byPath[BIG] and res.byPath[BIG].lines == 10000, res and res.byPath[BIG] and res.byPath[BIG].lines)
-- the player leaves the Files tab partway through a file: the next frame without the tab shuts it
F.forget()
READ.opened, READ.closed = 0, 0
READ.perLine = function() CLOCK = CLOCK + 1 end
if W.stepFiles then W:stepFiles("Big") else step("Big") end
READ.perLine = nil
check("FRAME: partway through a long file, it is open", READ.opened > READ.closed, READ.opened .. " " .. READ.closed)
if W.filesFrameEnd then W:filesFrameEnd() end
check("FRAME: a frame that drew the Files tab keeps it open", READ.opened > READ.closed, READ.opened .. " " .. READ.closed)
if W.filesFrameEnd then W:filesFrameEnd() end
check("FRAME: a frame with no Files tab (another tab, or the screen left) shuts it", READ.opened == READ.closed, READ.opened .. " " .. READ.closed)
READ.lines = 0
for _ = 1, 200 do res = step("Big"); if res then break end end
check("FRAME: back on the tab, the file is read again from its start, whole", res and res.byPath[BIG] and res.byPath[BIG].lines == 10000, res and res.byPath[BIG] and res.byPath[BIG].lines)
check("FRAME: and shut at its end", READ.opened == READ.closed, READ.opened .. " " .. READ.closed)

-- ---------------------------------------------------------------------------
section("SERVER: a server's list")
-- ---------------------------------------------------------------------------
local vf = io.open(VANILLA, "rb")
if not vf then print("fix_mods_msgs_sim: the game's ModSelectorModel.lua is not at " .. VANILLA); os.exit(1) end
local vsrc = vf:read("*a")
vf:close()
MapGroups = { new = function() return {} end }
local saveModSelector = ModSelector
ModSelector = {}
assert(loadstring(vsrc, "@ModSelectorModel.lua"))()
local Model = ModSelector.Model
ModSelector = saveModSelector
-- the lists: the player's own and the server's
local LISTS = {}
local function newList(ids)
    local a = { list = jl(ids) }
    function a:getMods() return self.list end
    function a:isModActive(id) for _, x in ipairs(self.list._t) do if x == id then return true end end return false end
    function a:setModActive(id, on)
        local t = self.list._t
        if on then if not self:isModActive(id) then t[#t + 1] = id end
        else for i = #t, 1, -1 do if t[i] == id then table.remove(t, i) end end end
    end
    return a
end
ActiveMods = { getById = function(id) LISTS[id] = LISTS[id] or newList({}); return LISTS[id] end }
local C1, C2 = "media/lua/client/c1.lua", "media/lua/client/c2.lua"
mod("ModC", { [C1] = { "-- C one" }, [C2] = { "-- C two" } })
OWN = { "ModA", "ModB", "ModC", "ZeD_UI", "ZeD_Picks" }
LISTS.default = newList({ "ModA", "ModB", "ModC", "ZeD_UI", "ZeD_Picks" })
boot(OWN)
P.commit({ X }, { [X] = "ModA" })
P.setOff("ModC", { C1, C2 }, true)
P.sync(OWN)
check("SERVER: the player's own list: ModA's X picked", text("ZeD_Picks", X) == text("ModA", X))
-- Host > Edit > Choose mods: the Mods screen on the server's list (ModC only)
local m = Model:new({ updateView = noop })
for _, id in ipairs({ "ModA", "ModB", "ModC", "ZeD_UI", "ZeD_Picks" }) do
    local d = { modId = id, modInfo = getModInfoByID(id), name = id }
    m.mods[id] = d
    m.sortedMods[#m.sortedMods + 1] = d
end
m:setServerSettingsMods({ { modID = "ModC" } }, noop)
m:refreshMods()
ModSelector = { instance = { model = m } }
local orderWrites = 0
local S = setmetatable({ dirty = noop, say = noop, saveOrder = function() orderWrites = orderWrites + 1 end, _filesSeen = {} },
                       { __index = ZeD_MMMods })
local fc1 = fileOf("ModC", C1)
check("SERVER: the file is off on the server's list too", S:fileState(m.mods.ModC, fc1) == "off", S:fileState(m.mods.ModC, fc1))
S:fileA(m.mods.ModC, fc1)
check("SERVER: the box (or A) on it does not switch it back on", P.offOf(C1) == "ModC", P.offOf(C1))
check("SERVER: the server's list is left as it was", table.concat(LISTS.serversettings.list._t, ",") == "ModC", table.concat(LISTS.serversettings.list._t, ","))
check("SERVER: the helper's copy of the picked file is untouched", text("ZeD_Picks", X) == text("ModA", X), text("ZeD_Picks", X))
check("SERVER: Turn back on is not offered here", S.canSwitchBack and S:canSwitchBack() == false)
-- Undo picks from the server's list: the copies follow the player's own list, the server's list stays
S:undoPicks({ things = { X } })
check("SERVER: picks undone in a server's list: the server's list stays", table.concat(LISTS.serversettings.list._t, ",") == "ModC", table.concat(LISTS.serversettings.list._t, ","))
check("SERVER: and its order is never written", orderWrites == 0, orderWrites)
check("SERVER: the copy follows the player's own list (ModB's, load order there)", text("ZeD_Picks", X) == text("ModB", X), text("ZeD_Picks", X))
check("SERVER: the files still off stay off in the player's game", (text("ZeD_Picks", C1) or ""):find("switched off", 1, true) ~= nil, text("ZeD_Picks", C1))
ModSelector = { instance = { model = { mods = MODS } } }
P.setOff("ModC", { C1, C2 }, false)
P.sync(OWN)

-- ---------------------------------------------------------------------------
section("OWN: ZeD-GUI's files and ZeD picks' copies")
-- ---------------------------------------------------------------------------
local ZP = "media/lua/client/ZeD/ZeD_ModPicks.lua"
MODS.ModC = { modId = "ModC", name = "ModC", isActive = true, modInfo = getModInfoByID("ModC") }
boot(OWN)
MS.isLoaded = function(id) for _, x in ipairs(ORDER) do if x == id then return true end end return false end
check("OWN: an ordinary mod's files can be switched", W:canSwitchFiles(MODS.ModC) == true)
check("OWN: ZeD-GUI's cannot", W:canSwitchFiles(MODS.ZeD_UI) == false)
check("OWN: ZeD picks' cannot", W:canSwitchFiles(MODS.ZeD_Picks) == false)
P.setOff("ZeD_UI", { ZP }, true)
check("OWN: the list refuses ZeD-GUI's file", P.offOf(ZP) == nil, P.offOf(ZP))
P.setOff("ModA", { X }, true)
P.setOff("ZeD_Picks", { X }, true)
check("OWN: the helper never takes over another mod's switch", P.offOf(X) == "ModA", P.offOf(X))
P.setOff("ModA", { X }, false)
local fz = fileOf("ZeD_UI", ZP)
W:fileA(MODS.ZeD_UI, fz)
check("OWN: the box (or A) on ZeD-GUI's file switches nothing", P.offOf(ZP) == nil)
-- a switch left from an older build: the copy stays ZeD's own text, and it can be switched back on
LUA["ZeD_picks.txt"] = { "header", "off=" .. ZP .. "|ZeD_UI" }
P, F = reloadPicks()
P.helper = function() return getModInfoByID("ZeD_Picks") end
P.sync(OWN)
boot(OWN)
check("OWN: an old switch on ZeD-GUI's file never empties it", select(2, helperRuns(ZP)) == text("ZeD_UI", ZP), select(2, helperRuns(ZP)))
P.setOff("ZeD_UI", { ZP }, false)
check("OWN: and it can be switched back on", P.offOf(ZP) == nil)

-- ---------------------------------------------------------------------------
section("TAKEOVER: a shadowed copy never takes another mod's switch")
-- ---------------------------------------------------------------------------
-- ModT ships XLib.lua and Shared3.lua (which needs XLib); ModU ships Shared3.lua too and loads later, so ModU's
-- Shared3 runs. ModU's Shared3 is switched off on ModU's tab.
local XL, SH = "media/lua/client/XLib.lua", "media/lua/client/Shared3.lua"
mod("ModT", { [XL] = { "XLib = {}" }, [SH] = { "require \"XLib\"", "Shared3 = XLib" } })
mod("ModU", { [SH] = { "-- U's Shared3", "Shared3 = {}" } })
local TU = { "ModT", "ModU", "ZeD_UI", "ZeD_Picks" }
boot(TU)
for _, id in ipairs({ "ModT", "ModU" }) do MODS[id] = { modId = id, name = id, isActive = true, modInfo = getModInfoByID(id) } end
ModSelector = { instance = { model = { mods = MODS } } }
P.setOff("ModU", { SH }, true, TU)
P.sync(TU)
check("TAKEOVER: ModU's Shared3 is off", P.offOf(SH) == "ModU" and (text("ZeD_Picks", SH) or ""):find("switched off", 1, true) ~= nil, P.offOf(SH))
F.forget()
local tf = {}
for _, f in ipairs(F.files("ModT")) do tf[f.path] = f end
for _ = 1, 50 do if step("ModT") then break end end
local xlUsed = F.usedBy("ModT", XL)
check("TAKEOVER: XLib is used by ModT's Shared3", xlUsed and #xlUsed == 1 and xlUsed[1] == SH, xlUsed and table.concat(xlUsed, ","))
-- the box (or A) on ModT's Shared3 before the conflict scan is done: it reads 'on' there
MS.start()
check("TAKEOVER: before the scan, ModT's shadowed Shared3 reads on", W:fileState(MODS.ModT, tf[SH]) == "on", W:fileState(MODS.ModT, tf[SH]))
W:fileA(MODS.ModT, tf[SH])
check("TAKEOVER: the box on it leaves ModU's switch alone", P.offOf(SH) == "ModU", P.offOf(SH))
P.setOff("ModT", { SH }, true, TU)
check("TAKEOVER: the list never hands a path off for a mod whose copy runs to a shadowed one", P.offOf(SH) == "ModU", P.offOf(SH))
for _ = 1, 200 do MS.step(); if MS.res.done then break end end
check("TAKEOVER: the scan is done, and ModT's Shared3 never runs", MS.res.done and W:fileState(MODS.ModT, tf[SH]) == "other", W:fileState(MODS.ModT, tf[SH]))
-- Turn off with the 1 on ModT's XLib card: XLib only (ModT's Shared3 never runs)
local with = W.offWith and W:offWith(MODS.ModT, tf[XL], xlUsed) or { XL, SH }
check("TAKEOVER: Turn off with takes no file another mod's copy stands in for", #with == 1 and with[1] == XL, table.concat(with, ","))
-- (G7, Nov 12 2026) the card offers "Turn off with the N" only when N > 0: XLib's card, its one user a shadowed copy
do
    local seen = nil
    local T0, A0, fh0 = ZeD.T, ZeD.Atoms, ZeD.MainMenu.fontH
    local col = { r = 1, g = 1, b = 1, a = 1 }
    ZeD.T = setmetatable({ px = function(n) return n end }, { __index = function() return col end })
    ZeD.Atoms = { truncateText = function(s) return s end, frame = noop }
    ZeD.MainMenu.fontH = function() return 10 end
    local C = setmetatable({ fileNote = function(_, _, _, _, _, y) return y end, paneText = function(_, _, _, y) return y end,
                             paneVerbs = function(_, v) seen = v; return 0 end, drawText = noop, drawCode = noop,
                             canSwitchBack = function() return true end }, { __index = W })
    local function ids()
        local out = {}
        for _, v in ipairs(seen or {}) do out[#out + 1] = v[1] .. "=" .. tostring(v[2]) end
        return table.concat(out, ",")
    end
    local ok, err = pcall(C.drawFileCard, C, MODS.ModT, tf[XL], 1, 0, 400, 0, 0, 2000, true)
    check("G7 OFFWITH: XLib's card draws", ok, err)
    local hasWith = ids():find("mf:offwith", 1, true) ~= nil
    check("G7 OFFWITH: with no other file to take along, no 'Turn off with the 0'", ok and seen ~= nil and not hasWith, ids())
    check("G7 OFFWITH: Turn off anyway is still offered", ids():find("mf:off=", 1, true) ~= nil, ids())
    C.offWith = function() return { XL, "media/lua/client/Other.lua" } end
    seen = nil
    ok, err = pcall(C.drawFileCard, C, MODS.ModT, tf[XL], 1, 0, 400, 0, 0, 2000, true)
    check("G7 OFFWITH: with one file to take along, 'Turn off with the 1' shows", ok and ids():find("mf:offwith", 1, true) ~= nil, ids())
    ZeD.T, ZeD.Atoms, ZeD.MainMenu.fontH = T0, A0, fh0
end
-- (G7) a switch the list refuses (ModT's shadowed Shared3, ModU holds it off): no click, no band, no notice
do
    local clicks = 0
    local cs0 = ZeD.MainMenu.clickSound
    ZeD.MainMenu.clickSound = function() clicks = clicks + 1 end
    W._filesChanged, said = nil, nil
    W:switchFiles(MODS.ModT, { SH }, true)
    check("G7 REFUSED: the switch is refused (ModU still holds it)", P.offOf(SH) == "ModU", P.offOf(SH))
    check("G7 REFUSED: no click", clicks == 0, clicks)
    check("G7 REFUSED: no files-changed band", W._filesChanged == nil, W._filesChanged)
    check("G7 REFUSED: no notice", said == nil, said)
    ZeD.MainMenu.clickSound = cs0
end
W:switchFiles(MODS.ModT, with, true)
P.sync(TU)
check("TAKEOVER: after it ModU's Shared3 is still off for ModU", P.offOf(SH) == "ModU", P.offOf(SH))
check("TAKEOVER: and the helper's copy still does nothing", (text("ZeD_Picks", SH) or ""):find("switched off", 1, true) ~= nil, text("ZeD_Picks", SH))
check("TAKEOVER: XLib is off for ModT", P.offOf(XL) == "ModT", P.offOf(XL))
-- a record a mod no longer runs (ModU off): the mod whose copy runs now takes it over
P.setOff("ModT", { SH }, true, { "ModT", "ZeD_UI", "ZeD_Picks" })
check("TAKEOVER: with ModU off, ModT's copy runs and takes the switch", P.offOf(SH) == "ModT", P.offOf(SH))
P.setOff("ModT", { SH, XL }, false)
P.sync(TU)

-- ---------------------------------------------------------------------------
section("MEDIA: a Steam library under a folder called Media")
-- ---------------------------------------------------------------------------
local LIB = "D:/Media/SteamLibrary/steamapps/workshop/content/108600/"
mod("Foo", {
    ["media/lua/client/FooMain.lua"] = { "FooMain = {}", "function FooMain.open() end" },
    ["media/lua/client/ISUI/FooWindow.lua"] = { "require \"FooMain\"", "FooWindow = ISPanel:derive(\"FooWindow\")",
                                                "function FooWindow:render() FooMain.open() end", "local f = getFileReader(\"FooSettings.ini\", false)" },
    ["media/lua/shared/Foo/FooDefs.lua"] = { "FooDefs = {}" },
}, LIB .. "123/mods/Foo")
mod("Deck", { ["media/lua/client/Deck/DeckThing.lua"] = { "DeckThing = {}" } }, "/run/media/mmcblk0p1/steamapps/workshop/content/108600/124/mods/Deck")
mod("Bar", { ["media/lua/client/ISUI/Shared2.lua"] = { "-- Bar's" } }, LIB .. "125/mods/Bar")
mod("Baz", { ["media/lua/client/ISUI/Shared2.lua"] = { "-- Baz's" } }, LIB .. "126/mods/Baz")
boot({ "Foo", "Deck", "Bar", "Baz", "ZeD_UI", "ZeD_Picks" })
F.forget()
local got = {}
for _, f in ipairs(F.files("Foo")) do got[#got + 1] = f.side .. ":" .. f.sub end
check("MEDIA: the Files tab lists the files in sub-folders", #got == 3, table.concat(got, " "))
local gotDeck = 0
for _ in ipairs(F.files("Deck")) do gotDeck = gotDeck + 1 end
check("MEDIA: a Steam Deck card under /run/media/ too", gotDeck == 1, gotDeck)
for _ = 1, 20 do if step("Foo") then break end end
local fooUsed = F.usedBy("Foo", "media/lua/client/FooMain.lua")
check("MEDIA: used by counts the files in sub-folders", fooUsed and #fooUsed == 1, fooUsed and #fooUsed)
MS.start()
for _ = 1, 200 do MS.step(); if MS.res.done then break end end
local conf = MS.res.byMod.Bar or {}
check("MEDIA: the conflict scan finds two mods' file in a sub-folder", #conf == 1 and conf[1].winner == "Baz", #conf)
LUA["FooSettings.ini"] = { "volume=3" }
ZeD.ModReset.forget()
local rf
for _ = 1, 20 do rf = ZeD.ModReset.find("Foo"); if rf then break end end
local named = false
for _, f in ipairs(rf and rf.files or {}) do if f.path == "FooSettings.ini" then named = true end end
check("MEDIA: Reset settings finds the file a sub-folder's code names", named, rf and #rf.files)

print("fix_mods_msgs_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
