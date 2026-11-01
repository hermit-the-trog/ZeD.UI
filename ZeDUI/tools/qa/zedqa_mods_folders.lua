-- ZeDUI/tools/qa/zedqa_mods_folders.lua  (Oct 31 2026)
-- Main menu QA for the Mods page's folders (MOD_FOLDERS_SPEC.md, punch list 37, stage 2):
--   1. ModFolders.cfg round-trips byte for byte: ZeDUI/ModFolders_sample.cfg (the mod's own save,
--      written in game, c8a237b) read and written back unchanged gives the same text
--   2. a folder named with non-ASCII letters (built from char codes: a literal non-ASCII
--      character in a bridge script arrives as U+FFFD) is saved as one hex code per UTF-16 unit
--   3. a line ZeD does not know stays, in its place, through every change
--   4. Unfiled: a mod in no folder is listed under it; it is last, and never written to the file
--   5. collapse: a folder closed is saved in the file (|0|); its rows are not drawn; Unfiled's
--      state is ZeD's own (ZeD_modfolders.txt), not in ModFolders.cfg
--   6. a folder's box turns its mods on (empty or mixed) or off (all on), at once
--   7. delete: the folder's mods go to Unfiled, none turn off
--   8. making, moving into, closing, reordering and deleting folders never changes what is on or
--      the load order
-- Works on its own file: ZeD.ModFolders.FILE is pointed at Lua/ZeDQA_ModFolders.cfg for the run,
-- so the player's own ModFolders.cfg is never read or written. Puts back: the file name, the
-- Unfiled state file's text, every mod's on / off and the load order (Undo changes); leaves
-- through Discard changes (vanilla's NO), so nothing new is accepted.
--
-- Run (never while the game runs; checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/compat_r4_mods.txt `
--        -Script ZeDUI/tools/qa/zedqa_mods_folders.lua -Tag mfo -TimeoutSec 240
-- Lines: "ZEDQA mfo PASS ..." / "ZEDQA mfo FAIL ..." / "ZEDQA mfo SKIP ...", then a total and DONE.
local MM = ZeD.MainMenu
local F = ZeD.ModFolders
local function say(s) print("ZEDQA mfo " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mfo_" .. n .. ".png") end) end
local pass, fail = 0, 0
local function check(ok, what)
    if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end
end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function W() return MM.root and MM.root.modsWin end
local function model() return ModSelector.instance.model end
local function jlist(l) local t = {}; if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end; return t end

local TEST = "ZeDQA_ModFolders.cfg"
local UISTATE = "ZeD_modfolders.txt"
-- ZeDUI/ModFolders_sample.cfg, line for line (ASCII: the names are hex)
local SAMPLE = table.concat({
    "version=2",
    "next=4",
    "folder=1|1|5730,56FE",
    "folder=2|0|43,61,66,E9",
    "folder=3|1|57,65,61,70,6F,6E,73",
    "member=43,6F,6E,73,74,6F,77,6E,34,32|1",
    "member=6E,65,77,68,61,72,74,62,75,72,67|1",
    "member=4D,6F,64,46,6F,6C,64,65,72,73|2",
    "member=5A,65,44,5F,55,49|2",
    "member=47,61,65,6C,47,75,6E,53,74,6F,72,65,5F,42,34,32|3",
    "member=4D,6F,64,65,72,6E,46,69,72,65,61,72,6D,73,53,79,73,74,65,6D|3",
}, "\n") .. "\n"
local UNKNOWN = "zedqa_unknown=kept|1"

local keep = {}

local function readRaw(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local t = {}
    local line = r:readLine()
    while line do t[#t + 1] = line; line = r:readLine() end
    r:close()
    return table.concat(t, "\n") .. "\n"
end
local function writeRaw(name, s)
    local w = getFileWriter(name, true, false)
    if w then w:write(s); w:close() end
end

-- what is on, and the load order, as one text (foldering must never change it)
local function onAndOrder()
    local m = model()
    local on = {}
    for _, d in ipairs(m.sortedMods or {}) do if d.isActive then on[#on + 1] = d.modId end end
    return table.concat(on, ";") .. " / " .. table.concat(jlist(m:getActiveMods():getMods()), ";")
end

-- the index of the line holding text s in the file (nil: none)
local function lineOf(raw, s)
    local i = 0
    for l in string.gmatch(raw or "", "([^\n]*)\n") do
        i = i + 1
        if l == s then return i end
    end
    return nil
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    keep.file = F.FILE
    keep.ui = readRaw(UISTATE)
    F.FILE = TEST
    writeRaw(TEST, SAMPLE)
    MM.ctx.open = nil
    MM.openMods()
end)

-- 1: the sample read, then written back unchanged (a change that changes nothing still writes)
at(15, function()
    local M = F.get()
    check(#M.folders == 3, "1a the sample's three folders read")
    check(M.folders[1].name == string.char(0x5730, 0x56FE) and M.folders[2].name == "Caf" .. string.char(0xE9), "1b names decoded per UTF-16 unit")
    check(M.folders[2].open == false and M.folders[1].open == true, "1c open / closed read")
    check(table.concat(F.lines(M), "\n") .. "\n" == SAMPLE, "1d the lines as read give the sample's text")
    local ok = F.change(function() return true end)
    check(ok and readRaw(TEST) == SAMPLE, "1e written back unchanged: byte for byte")
end)

-- 2, 3, 8: a non-ASCII folder made, a line ZeD does not know in the file, nothing on / off or in
-- the load order moves
at(25, function()
    writeRaw(TEST, SAMPLE .. UNKNOWN .. "\n")
    F.load()
    keep.state0 = onAndOrder()
    keep.unknownAt = lineOf(readRaw(TEST), UNKNOWN)
    check(F.cur.bad == 1, "3a the line ZeD does not know is counted (the help line says so)")
    local name = string.char(0x5730, 0x56FE) .. " " .. "Caf" .. string.char(0xE9)
    local ok, id = F.create(name)
    keep.fid = id
    local raw = readRaw(TEST) or ""
    check(ok and id == 4, "2a the new folder takes next (4)")
    check(raw:find("folder=4|1|5730,56FE,20,43,61,66,E9\n", 1, true) ~= nil, "2b saved as one hex code per UTF-16 unit")
    check(raw:find("next=5\n", 1, true) ~= nil, "2c next goes up by one")
    F.load()
    check(F.byId(4) and F.byId(4).name == name, "2d read back, the same name")
    check(lineOf(readRaw(TEST), UNKNOWN) ~= nil, "3b the unknown line is still in the file")
end)

-- 4 and 8: two installed mods moved into the new folder, the rest in Unfiled
at(35, function()
    local w = W()
    local m = model()
    local picks = {}
    for _, d in ipairs(m.sortedMods or {}) do
        if #picks < 2 and d.isAvailable and not d.isActive and not w:problemNow(d) and d.modId ~= "ModTemplate" and d.modId ~= "ZeD_UI" then picks[#picks + 1] = d.modId end
    end
    keep.picks = picks
    if #picks < 2 then say("SKIP 4, 6 (fewer than two installed mods that are off and can run)"); return end
    local ok = F.assign(picks, keep.fid)
    check(ok and F.folderOf(picks[1]) == keep.fid and F.folderOf(picks[2]) == keep.fid, "4a two mods moved into the folder")
    w.filter = "all"
    w.find:setText("")
    w:dirty()
    local v = w:folderView()
    local last = v.ents[#v.ents]
    local unf = nil
    for _, e in ipairs(v.ents) do if e.k == "folder" and e.fkey == "unfiled" then unf = e end end
    check(unf ~= nil, "4b Unfiled is listed")
    local afterUnf = true
    local seenUnf = false
    for _, e in ipairs(v.ents) do
        if e == unf then seenUnf = true elseif seenUnf and e.k == "folder" then afterUnf = false end
    end
    check(afterUnf, "4c Unfiled comes after every folder")
    local other = nil
    for _, d in ipairs(m.sortedMods or {}) do if not F.folderOf(d.modId) then other = d.modId; break end end
    if other and F.unfiledOpen() then
        local k = v.at["mrow:" .. other]
        check(k ~= nil and v.ents[k].fkey == "unfiled", "4d a mod in no folder is listed under Unfiled")
    end
    check((readRaw(TEST) or ""):find("nfiled", 1, true) == nil, "4e Unfiled is never written to the file")
    check(onAndOrder() == keep.state0, "8a making a folder and moving mods into it changes nothing on, nor the load order")
end)
at(40, function() shot("01_grouped") end)

-- 5: closed and open again, saved; Unfiled's state in ZeD's own file
at(45, function()
    local w = W()
    if not keep.fid then return end
    local v = w:folderView()
    local e = v.ents[v.at["frow:" .. keep.fid]]
    w:folderOpenClose(e)
    local raw = readRaw(TEST) or ""
    check(raw:find("folder=4|0|", 1, true) ~= nil, "5a closing writes |0| to the file")
    v = w:folderView()
    local shown = false
    for _, id in ipairs(keep.picks or {}) do if v.at["mrow:" .. id] then shown = true end end
    check(not shown, "5b a closed folder's rows are not drawn")
    w.fsel = keep.fid
    w.sel = nil
    w.focusId = "frow:" .. keep.fid
end)
at(50, function() shot("02_closed_detail") end)
at(55, function()
    local w = W()
    if not keep.fid then return end
    local v = w:folderView()
    w:folderOpenClose(v.ents[v.at["frow:" .. keep.fid]])
    check((readRaw(TEST) or ""):find("folder=4|1|", 1, true) ~= nil, "5c opening writes |1|")
    local before = readRaw(TEST)
    local was = F.unfiledOpen()
    F.setUnfiledOpen(not was)
    check(readRaw(UISTATE) == "unfiledOpen=" .. ((not was) and "1" or "0") .. "\n", "5d Unfiled's state goes to ZeD_modfolders.txt")
    check(readRaw(TEST) == before, "5e ModFolders.cfg is not written for Unfiled")
    F.setUnfiledOpen(was)
    check(onAndOrder() == keep.state0, "8b opening and closing changes nothing on, nor the load order")
end)

-- 6: the folder's box: empty -> all on; all on -> all off
at(65, function()
    local w = W()
    local m = model()
    if not (keep.picks and #keep.picks >= 2) then return end
    w:folderBox(keep.fid)
    local allOn = true
    for _, id in ipairs(keep.picks) do if not (m.mods[id] and m.mods[id].isActive) then allOn = false end end
    check(allOn, "6a the box turns every mod in the folder on")
    say("band: " .. tostring(w.note and w.note.text))
    -- mixed: one off, then the box turns all on again
    m:forceActivateMods(m.mods[keep.picks[1]].modInfo, false)
    w:dirty()
    local v = w:folderView()
    local e = v.ents[v.at["frow:" .. keep.fid]]
    check(e.on == 1 and e.n == 2, "6b one of two on: the heading counts it (the box shows the dash)")
    w:folderBox(keep.fid)
    check(m.mods[keep.picks[1]].isActive and m.mods[keep.picks[2]].isActive, "6c mixed: the box turns all on")
    w:folderBox(keep.fid)
    check(not m.mods[keep.picks[1]].isActive and not m.mods[keep.picks[2]].isActive, "6d all on: the box turns all off")
    -- (anything else the box pulled in goes back too)
    w:revert()
    keep.state0 = onAndOrder()
end)
at(70, function() shot("03_box") end)

-- 7, 8, 3: moved down and up, then deleted: its mods go to Unfiled, none turn off; the unknown
-- line still in its place
at(80, function()
    local w = W()
    if not keep.fid then return end
    local ok1 = F.moveFolder(keep.fid, -1)
    check(ok1 and F.folders()[3].id == keep.fid, "8c Move up moves the folder")
    check(onAndOrder() == keep.state0, "8d reordering folders changes nothing on, nor the load order")
    -- one of the picks on, so "none turn off" is seen
    local m = model()
    if keep.picks and keep.picks[1] then m:forceActivateMods(m.mods[keep.picks[1]].modInfo, true); w:dirty() end
    keep.state1 = onAndOrder()
    w._fTarget = keep.fid
    w:setConfirm("fdelete")
end)
at(85, function() shot("04_ask_delete") end)
at(90, function()
    local w = W()
    if not keep.fid then return end
    w:folderDelete()
    local raw = readRaw(TEST) or ""
    check(F.byId(keep.fid) == nil and raw:find("folder=4|", 1, true) == nil, "7a the folder is gone from the file")
    local inUnf = true
    for _, id in ipairs(keep.picks or {}) do if F.folderOf(id) ~= nil then inUnf = false end end
    check(inUnf, "7b its mods are in Unfiled")
    check(onAndOrder() == keep.state1, "7c none turn off; the load order is the same")
    check(lineOf(raw, UNKNOWN) ~= nil, "3c the unknown line is kept through every change")
    check(#F.folders() == 3 and raw:find("folder=1|1|5730,56FE\n", 1, true) ~= nil, "3d the other folders' lines are as they were")
    check(w.fsel == "unfiled" or w.fsel == nil, "7d the pick goes to Unfiled")
end)
at(95, function() shot("05_deleted") end)

-- an edit made outside the game while the screen is open is kept by the next change
at(100, function()
    local raw = readRaw(TEST) or ""
    writeRaw(TEST, raw .. "folder=9|1|51,41\n")
    local ok, id = F.create("QA")
    local raw2 = readRaw(TEST) or ""
    check(ok and id == 10 and raw2:find("folder=9|1|51,41\n", 1, true) ~= nil, "9a an outside edit is kept (the change reads the file first)")
end)

-- put everything back
at(110, function()
    local w = W()
    w:revert()
    F.FILE = keep.file or "ModFolders.cfg"
    writeRaw(TEST, "")
    if keep.ui then writeRaw(UISTATE, keep.ui) else writeRaw(UISTATE, "unfiledOpen=1\n") end
    F.load()
    w:discard()
end)
at(130, function()
    say(string.format("view=%s; %d passed, %d failed", tostring(MM.view), pass, fail))
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 150 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
