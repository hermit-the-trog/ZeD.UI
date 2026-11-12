-- ZeDUI/tools/qa/mods_files_sim.lua  (Nov 11 2026, punch list 170): the Mods screen's Files tab and the error cards.
-- Loads the real ZeD_VanillaLua, ZeD_ModPicks, ZeD_ModFiles, ZeD_Messages and ZeD_MainMenuModsFiles on stubs of the
-- game: mods on disk (a version and a common folder each), Zomboid/Lua, and the engine's own rule for which copy of
-- a Lua file runs (every loaded mod's files go into one map by relative path, a later mod's replacing an earlier
-- one's: ZomboidFileSystem.loadMod; LuaManager.LoadDirBase runs each path once from that map). Checks the file list,
-- switching a file off and back on, what lasts through a restart, the game-file guard, "used by", errors filed per
-- place and written for the Mods screen, the plain words, and Open in Mods' jump to the file.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mods_files_sim.lua
-- It prints FAIL lines and a last line "mods_files_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]mods_files_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- ---------------------------------------------------------------------------
-- the game, as little as the files need
-- ---------------------------------------------------------------------------
local function hook() return { Add = function() end, Remove = function() end } end
Events = setmetatable({}, { __index = function(t, k) local e = hook(); rawset(t, k, e); return e end })
function require() end
local function jl(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end

-- mods on disk: id -> { dir = "<folder>", files = { ["media/lua/client/x.lua"] = { lines } } } (both folders as one)
local DISK = {}
local function mod(id, files) DISK[id] = { dir = "C:/Mods/" .. id, files = files or {} } end
local function findKey(t, path)
    local want = string.lower(path)
    for k in pairs(t) do if string.lower(k) == want then return k end end
    return nil
end
function getModInfoByID(id)
    local m = DISK[id]
    if not m then return nil end
    return { getVersionDir = function() return m.dir .. "/42" end, getCommonDir = function() return m.dir .. "/common" end,
             getName = function() return id end }
end
local function reader(lines)
    local i = 0
    return { readLine = function() i = i + 1; return lines[i] end, close = function() end }
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

-- the engine: the load order's mods, a later mod's path replacing an earlier one's; what runs per path
local ORDER = {}
local function activeMap()
    local map = {}
    for _, id in ipairs(ORDER) do
        for k in pairs(DISK[id].files) do map[string.lower(k)] = { id = id, path = k } end
    end
    return map
end
local function runs(path) local e = activeMap()[string.lower(path)]; return e and e.id, e and table.concat(DISK[e.id].files[e.path], "\n") end
local loaded = {}
local function boot(order)
    ORDER = order
    loaded = {}
    for _, e in pairs(activeMap()) do loaded[#loaded + 1] = DISK[e.id].dir .. "/42/" .. e.path end
    table.sort(loaded)
end
function getLoadedLuaCount() return #loaded end
function getLoadedLua(i) return loaded[i + 1] end

GAMEVER = "42.22.2 abcdef"
function getCore() return { getVersion = function() return GAMEVER end } end
function getTimestampMs() return 1000 end
function getMyDocumentFolder() return "C:/Users/Sam/Zomboid" end
function getActivatedMods() return jl(ORDER) end
function getPlayer() return {} end

local trArgs = {}
ZeD = { tr = function(k, ...) trArgs[k] = { ... }; local a = { ... }; return k .. (#a > 0 and ("(" .. table.concat((function() local t = {}; for i = 1, #a do t[i] = tostring(a[i]) end; return t end)(), ",") .. ")") or "") end }
ZeD.ModSettings = {
    readLines = function(id, path)
        local r = getModFileReader(id, path)
        if not r then return nil end
        local t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        return t
    end,
}

-- ---------------------------------------------------------------------------
-- the mods: Bandits Week One (a mod with files that use each other, one in a sub-folder, one that replaces a
-- game file), another mod, and the helper
-- ---------------------------------------------------------------------------
mod("BanditsWeekOne", {
    ["media/lua/client/BWOIntro.lua"] = { "require \"BWOMusic\"", "BWOIntro = {}", "local function onBoot() BWOMusic.play() end" },
    ["media/lua/client/BWOMusic.lua"] = { "BWO = BWO or {}", "BWOMusic = {}", "function BWOMusic.play() end" },
    ["media/lua/client/BWOMenu.lua"] = { "BWO = BWO or {}", "BWOMenu = ISPanel:derive(\"BWOMenu\")", "function BWOMenu:render() BWOMusic.play() end" },
    ["media/lua/client/BWOScheduler.lua"] = { "BWOScheduler = {}", "function BWOScheduler.generateSchedule() local s = nil; return s.schedule end" },
    ["media/lua/client/ISUI/BWOChatWindow.lua"] = { "BWOChatWindow = ISPanel:derive(\"BWOChatWindow\")", "BWOScheduler.generateSchedule()" },
    ["media/lua/client/ISUI/ISInventoryPane.lua"] = { "-- the mod's own copy of the game's ISInventoryPane" },
    ["media/lua/shared/BWOEvents.lua"] = { "BWOEvents = {}", "BWOScheduler.generateSchedule()", "BWOMenu.open()" },
})
mod("Other", { ["media/lua/client/OtherThing.lua"] = { "OtherThing = {}" } })
mod("ZeD_Picks", {})
mod("ZeD_UI", {})
local ON = { "BanditsWeekOne", "Other", "ZeD_UI", "ZeD_Picks" }
boot(ON)

local function load(rel) assert(loadfile(ROOT .. "42/media/lua/client/ZeD/" .. rel))() end
load("ZeD_VanillaLua.lua")
load("ZeD_ModPicks.lua")
load("ZeD_ModFiles.lua")
local P, F = ZeD.ModPicks, ZeD.ModFiles
check("the files load", P and F and ZeD.VanillaLua and F.files)

-- ---------------------------------------------------------------------------
-- 1. the file list
-- ---------------------------------------------------------------------------
local files = F.files("BanditsWeekOne")
local paths = {}
for i, f in ipairs(files) do paths[i] = f.side .. ":" .. f.sub end
local joined = table.concat(paths, " ")
check("every file of the mod is listed (sub-folders from what the game loaded)", #files == 7, joined)
check("client first, shared after, by name", paths[1] == "client:BWOIntro.lua" and paths[#paths] == "shared:BWOEvents.lua", joined)
check("a sub-folder's file is listed under its side", joined:find("client:ISUI/BWOChatWindow.lua", 1, true) ~= nil, joined)
check("another mod's files are not", not joined:find("OtherThing", 1, true))

-- ---------------------------------------------------------------------------
-- 2. the game's own files are never switched off
-- ---------------------------------------------------------------------------
check("a path the game has too is a game file", F.isGameFile("media/lua/client/ISUI/ISInventoryPane.lua"))
check("case does not matter", F.isGameFile("MEDIA/LUA/CLIENT/isui/isinventorypane.lua"))
check("the mod's own path is not", not F.isGameFile("media/lua/client/BWOIntro.lua"))
check("the shipped list was made from this build", F.sameBuild())
GAMEVER = "42.23.0 xyz"
check("another build: a new file in a game sub-folder counts as the game's", F.isGameFile("media/lua/client/ISUI/BWOChatWindow.lua"))
check("another build: a file at a side's top level does not", not F.isGameFile("media/lua/client/BWOIntro.lua"))
GAMEVER = "42.22.2 abcdef"

-- ---------------------------------------------------------------------------
-- 3. reading the files: sizes, first lines, used by
-- ---------------------------------------------------------------------------
local res
for _ = 1, 50 do res = F.scan("BanditsWeekOne"); if res then break end end
check("the scan finishes", res ~= nil)
local intro = "media/lua/client/BWOIntro.lua"
local music = "media/lua/client/BWOMusic.lua"
local sched = "media/lua/client/BWOScheduler.lua"
local e = res.byPath[intro]
check("a file's size is its bytes", e and e.bytes == #"require \"BWOMusic\"" + #"BWOIntro = {}" + #"local function onBoot() BWOMusic.play() end" + 3, e and e.bytes)
check("its first lines are kept", e and #e.first == 3 and e.first[1].n == 1)
check("the size reads in bytes", F.sizeText("BanditsWeekOne", intro) == tostring(e.bytes) .. " B", F.sizeText("BanditsWeekOne", intro))
local usedIntro = F.usedBy("BanditsWeekOne", intro)
check("a file no other file names is used by 0", #usedIntro == 0, table.concat(usedIntro, ","))
local usedMusic = F.usedBy("BanditsWeekOne", music)
check("a file others require or call is used by them", #usedMusic == 2, table.concat(usedMusic, ","))
local usedSched = F.usedBy("BanditsWeekOne", sched)
check("a table's users in sub-folders and other sides count", #usedSched == 2, table.concat(usedSched, ","))
local usedMenu = F.usedBy("BanditsWeekOne", "media/lua/client/BWOMenu.lua")
check("a derive()d table counts as made by its file", #usedMenu == 1 and usedMenu[1] == "media/lua/shared/BWOEvents.lua", table.concat(usedMenu, ","))
check("a table two files make (BWO) tells nothing", not (function() for _, t in ipairs(res.byPath[music].tokens) do if t == "BWO" then return true end end end)())

-- ---------------------------------------------------------------------------
-- 4. switching a file off: the helper's copy runs, the mod's own is untouched
-- ---------------------------------------------------------------------------
local own = table.concat(DISK.BanditsWeekOne.files[intro], "\n")
P.setOff("BanditsWeekOne", { intro }, true)
check("it is listed as off for its mod", P.offOf(intro) == "BanditsWeekOne" and #P.offFor("BanditsWeekOne") == 1)
check("the helper must stay on (it holds something now)", P.holdsAny() and P.activeCount(ON) == 1)
local wrote = P.sync(ON)
check("the helper gets the empty copy", wrote == 1, wrote)
local who, text = runs(intro)
check("after the reload the helper's copy is the one that runs", who == "ZeD_Picks", who)
check("it does nothing (a comment only)", text and text:match("^%-%-") and not text:find("\n%S"), text)
check("the mod's own copy is untouched", table.concat(DISK.BanditsWeekOne.files[intro], "\n") == own)
check("the list is a file in Zomboid/Lua", LUA["ZeD_picks.txt"] and table.concat(LUA["ZeD_picks.txt"], "\n"):find("off=" .. intro .. "|BanditsWeekOne", 1, true))

-- a restart: the modules read their files afresh, the game boots the same mods
ZeD.ModPicks, ZeD.ModFiles = nil, nil
load("ZeD_ModPicks.lua"); load("ZeD_ModFiles.lua")
P, F = ZeD.ModPicks, ZeD.ModFiles
boot(ON)
check("after a restart it is still off", P.offOf(intro) == "BanditsWeekOne")
check("after a restart nothing needs writing", P.sync(ON) == 0)
check("after a restart the empty copy still runs", (runs(intro)) == "ZeD_Picks")
-- the file is still listed for its mod although the game loads it from the helper now
local still = false
for _, f in ipairs(F.files("BanditsWeekOne")) do if f.path == intro and not f.gone then still = true end end
check("a file that is off is still on its mod's list", still)

-- the mod switched off: its file falls out of the helper's list that runs; back on, it is off again
local noBWO = { "Other", "ZeD_UI", "ZeD_Picks" }
P.sync(noBWO)
check("the mod off: the helper's copy is no longer the empty one", (select(2, runs(intro))) ~= nil and not tostring(select(2, runs(intro))):find("switched off", 1, true))
check("the mod off: the switch is kept for when it comes back", P.offOf(intro) == "BanditsWeekOne" and P.activeCount(noBWO) == 0)
P.sync(ON)
check("the mod back on: the file is off again", tostring(select(2, runs(intro))):find("switched off", 1, true) ~= nil)

-- ---------------------------------------------------------------------------
-- 5. back on: the path falls to load order, the mod's own copy (so nothing changes)
-- ---------------------------------------------------------------------------
P.setOff("BanditsWeekOne", { intro }, false)
check("back on: not listed as off", P.offOf(intro) == nil and #P.offFor("BanditsWeekOne") == 0)
P.sync(ON)
local _, back = runs(intro)
check("back on: what runs is the mod's own text", back == own, back)
check("back on: the list keeps the path held (a copy cannot be deleted)", table.concat(LUA["ZeD_picks.txt"], "\n"):find("held=" .. intro, 1, true))

-- ---------------------------------------------------------------------------
-- 6. a game file is never stubbed, even when the list says off
-- ---------------------------------------------------------------------------
local inv = "media/lua/client/ISUI/ISInventoryPane.lua"
P.setOff("BanditsWeekOne", { inv }, true)
P.sync(ON)
local _, invText = runs(inv)
check("a game file listed off: the helper keeps the mod's copy, not an empty one", invText == "-- the mod's own copy of the game's ISInventoryPane", invText)
P.setOff("BanditsWeekOne", { inv }, false)

-- ---------------------------------------------------------------------------
-- 7. an update took a file that is off out of the mod: listed as gone
-- ---------------------------------------------------------------------------
local gonePath = "media/lua/client/BWOOld.lua"
P.setOff("BanditsWeekOne", { gonePath }, true)
F.forget()
local gone = nil
for _, f in ipairs(F.files("BanditsWeekOne")) do if f.path == gonePath then gone = f end end
check("a file off that the mod no longer has is listed, as gone", gone and gone.gone)
P.sync(ON)
check("nothing of a gone file runs", (runs(gonePath)) == "ZeD_Picks" and not tostring(select(2, runs(gonePath))):find("switched off", 1, true))
P.setOff("BanditsWeekOne", { gonePath }, false)

-- ---------------------------------------------------------------------------
-- 8. errors filed by place, plain words, written for the Mods screen
-- ---------------------------------------------------------------------------
load("ZeD_Messages.lua")
local M = ZeD.Messages
local ENTRIES = {}
function getLuaDebuggerErrorCount() return #ENTRIES end
function getLuaDebuggerErrors() return jl(ENTRIES) end
local function err(head, frames)
    ENTRIES[#ENTRIES + 1] = "-----------------------------------------\n" .. head
    ENTRIES[#ENTRIES + 1] = "java.lang.RuntimeException: " .. head .. " at KahluaUtil.fail(KahluaUtil.java:100).\n" .. table.concat(frames, "\n")
end
local BWO = "Bandits Week One"
local f42 = { "\tLua((MOD:Bandits Week One)).generateSchedule(BWOScheduler.lua:42)", "\tLua((MOD:Bandits Week One)).MasterControl(BWOScheduler.lua:303)" }
err("attempted index: schedule of non-table: null", f42)
err("attempted index: schedule of non-table: null", f42)
err("Object tried to call nil in open", { "\tLua(Vanilla).bareCharacter(spawnpoints.lua:206)", "\tLua((MOD:Bandits Week One)).open(BWOMenu.lua:9)" })
err("Object tried to call nil in setLadderClimbingFlags", { "function: setLadderClimbingFlags -- file: Ladders.lua line # 257 | MOD: Ladders!? (v0.0.13)" })
err("attempted index: x of non-table: null", { "\tLua((MOD:Ladders!? (v0.0.13))).climb(Ladders.lua:12)" })
M.readErrors()
local src = M.sources[BWO]
local it = src and src.items[1]
check("errors are filed under the mod's name", it and it.count == 3, it and it.count)
check("one card per place: two places", it and #it.placeOrder == 2, it and #it.placeOrder)
local byFile = {}
for _, p in ipairs(it and it.placeOrder or {}) do byFile[p.file] = p end
local p42 = byFile["BWOScheduler.lua"]
check("a repeat counts up on its place", p42 and p42.count == 2 and p42.line == 42 and p42.fn == "generateSchedule")
check("its caller is the next frame", p42 and p42.caller and p42.caller.fn == "MasterControl" and p42.caller.line == 303)
check("the message without the Java class or its tail", p42 and p42.msg == "attempted index: schedule of non-table: null", p42 and p42.msg)
local pm = byFile["BWOMenu.lua"]
check("the place is the mod's own frame, not the game code at the top", pm and pm.line == 9 and pm.fn == "open")
check("newest place first", it and it.placeOrder[1] == pm)
local lad = M.sources["Ladders!? (v0.0.13)"]
local lp = lad and lad.items[1].placeOrder[1]
check("a name with a bracket of its own: the whole name and its place", lp and lp.file == "Ladders.lua" and lp.line == 12 and lp.fn == "climb", lp and lp.file)
local old = M.placeOf("x\nfunction: setLadderClimbingFlags -- file: Ladders.lua line # 257 | MOD: Ladders!? (v0.0.13).", "Ladders!? (v0.0.13)")
check("the older stack format is read too", old and old.file == "Ladders.lua" and old.line == 257 and old.fn == "setLadderClimbingFlags")
check("plain words: looked up a thing not there", M.plainWords("attempted index: schedule of non-table: null") == "UI_ZeD_Msg_PlainIndex(schedule)", M.plainWords("attempted index: schedule of non-table: null"))
check("plain words: called a function that does not exist", M.plainWords("Object tried to call nil in open") == "UI_ZeD_Msg_PlainCallNil")
check("plain words: none for a kind not known", M.plainWords("__add not defined for operands") == nil)
check("a place's copy is its newest error with the header", M.reportPlace(BWO, p42):find("BWOScheduler.lua, line 42, in generateSchedule | 2x", 1, true) ~= nil)

-- written for the Mods screen, read back there
M.savePlaces()
check("the places file is written", LUA["ZeD_error_places.txt"] and #LUA["ZeD_error_places.txt"] >= 3)
F.forget()
local on42 = F.placesOn(BWO, sched)
check("the Mods screen finds the errors on their file", #on42 == 1 and on42[1].count == 2 and on42[1].line == 42, #on42)
check("by the file's name, any folder", #F.placesOn(BWO, "media/lua/client/BWOMenu.lua") == 1)
check("no errors on a file the game did not name", #F.placesOn(BWO, intro) == 0)
check("the mod's count is every error", F.errorCount(BWO) == 3, F.errorCount(BWO))
check("a mod name with a bracket survives the file", F.errorCount("Ladders!? (v0.0.13)") == 1)

-- ---------------------------------------------------------------------------
-- 9. Open in Mods: the jump to the file, across the trip to the main menu
-- ---------------------------------------------------------------------------
local opened = nil
ZeD.MainMenu = { openPauseMods = function(name, file) opened = name .. "|" .. file end, clickSound = function() end }
check("Open in Mods works from a card", M.openInMods(BWO, p42))
check("the pause window opens on its Mods page with the file", opened == BWO .. "|BWOScheduler.lua", opened)
local j = F.takeJump()
check("the Mods screen reads where to open", j and j.name == BWO and j.file == "BWOScheduler.lua")
check("only once", F.takeJump() == nil)

-- the Files tab's side: the jump picks the mod and its Files tab, the file is found by name
ZeD.ModScan = { isLoaded = function(id) return DISK[id] ~= nil end }
ZeD_MMMods = {}
load("ZeD_MainMenuModsFiles.lua")
local MODS = { BanditsWeekOne = { modId = "BanditsWeekOne", name = BWO, isActive = true }, Other = { modId = "Other", name = "Other", isActive = true } }
ModSelector = { instance = { model = { mods = MODS } } }
local said, after = nil, 0
local W = setmetatable({ dirty = function() end, say = function(_, t) said = t end, afterPicks = function() after = after + 1; P.sync(ON) end },
                       { __index = ZeD_MMMods })
M.openInMods(BWO, p42)
W._pendingJump = F.takeJump()
W:resolveJump()
check("the jump picks the mod by its name, on its Files tab", W.sel == "BanditsWeekOne" and W.dtab == "files" and W._fileJump == "BWOScheduler.lua")

-- switching from the tab: a safe file goes off at once, a used one opens its card first, an off one comes back on
local d = MODS.BanditsWeekOne
P.helper = function() return getModInfoByID("ZeD_Picks") end
local function fileOf(path) for _, f in ipairs(F.files("BanditsWeekOne")) do if f.path == path then return f end end end
F.forget()
for _ = 1, 50 do if F.scan("BanditsWeekOne") then break end end
W:fileA(d, fileOf(intro))
check("A on a file nothing uses: off at once", P.offOf(intro) == "BanditsWeekOne" and after == 1)
check("the note says a reload puts it in place", said == "UI_ZeD_Mods_SayFileOff(1," .. BWO .. ")", said)
check("the band says files were switched", W._filesChanged == BWO)
W:fileA(d, fileOf(music))
check("A on a file others use: its card opens, nothing switched", P.offOf(music) == nil and W.fileSel == music)
W:fileA(d, fileOf(sched))
check("A on a file with errors: its card opens first", P.offOf(sched) == nil and W.fileSel == sched)
W:fileA(d, fileOf(intro))
check("A on a file that is off: back on", P.offOf(intro) == nil)
check("a game file's state", W:fileState(d, fileOf(inv)) == "game")
W:switchFiles(d, { music, intro }, true)
check("Turn off with the files that use it: all of them", P.offOf(music) and P.offOf(intro) and #P.offFor("BanditsWeekOne") == 2)
W:switchFiles(d, P.offFor("BanditsWeekOne"), false)
check("Turn all back on", #P.offFor("BanditsWeekOne") == 0 and said == "UI_ZeD_Mods_SayFilesOn(2," .. BWO .. ")", said)
check("what runs is the mod's own again", (runs(music)) == "ZeD_Picks" and select(2, runs(music)) == table.concat(DISK.BanditsWeekOne.files[music], "\n"))
check("no switching in a server's list", (function() ModSelector.instance.model.isServerSettingsMods = true; local r = W:canSwitchFiles(d); ModSelector.instance.model.isServerSettingsMods = nil; return r == false end)())

print("mods_files_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
