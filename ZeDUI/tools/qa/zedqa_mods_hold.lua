-- ZeDUI/tools/qa/zedqa_mods_hold.lua  (Nov 1 2026, QA; punch list 37 / 41 hand checks)
-- Opens the Mods page and holds the game at the main menu for checks by hand (mouse, keys). Folders use
-- their own file (Lua/ZeDQA_ModFolders.cfg, the mod's sample with 3 folders), never the player's
-- ModFolders.cfg. Ends when Lua/zedqa_release.txt appears: Discard changes (vanilla's NO), the file name
-- and the Unfiled state file put back, the test file emptied, then DONE. FE ticks only (the main menu).
local MM = ZeD.MainMenu
local F = ZeD.ModFolders
local function say(s) print("ZEDQA mho " .. tostring(s)) end
local TEST, UISTATE = "ZeDQA_ModFolders.cfg", "ZeD_modfolders.txt"
local function readRaw(name)
    local r = getFileReader(name, false); if not r then return nil end
    local t, l = {}, r:readLine()
    while l do t[#t + 1] = l; l = r:readLine() end
    r:close(); return table.concat(t, "\n") .. (#t > 0 and "\n" or "")
end
local function writeRaw(name, s) local w = getFileWriter(name, true, false); w:write(s); w:close() end
local keep = { file = F.FILE, ui = readRaw(UISTATE) }
local SAMPLE = table.concat({ "version=2", "next=4", "folder=1|1|5730,56FE", "folder=2|0|43,61,66,E9",
    "folder=3|1|57,65,61,70,6F,6E,73", "member=4E,65,61,74,5F,43,72,61,66,74,69,6E,67|2",
    "member=4E,65,61,74,5F,42,75,69,6C,64,69,6E,67|2", "member=4B,6E,6F,78,50,61,63,6B,73|3", "" }, "\n")
writeRaw(TEST, SAMPLE)
F.FILE = TEST
F.load()
pcall(function() writeRaw("zedqa_release.txt", "") end)
local released = false
local tick = 0
local function t()
    tick = tick + 1
    if tick == 10 then MM.ctx.open = nil; MM.openMods(); say("Mods page open; waiting for Lua/zedqa_release.txt to have text") end
    if tick % 60 ~= 0 or released then return end
    local r = readRaw("zedqa_release.txt")
    if r and r:find("%S") then
        released = true
        pcall(function() local w = MM.root and MM.root.modsWin; if w then if w.revert then w:revert() end; w:discard() end end)
        F.FILE = keep.file or "ModFolders.cfg"
        writeRaw(TEST, "")
        if keep.ui then writeRaw(UISTATE, keep.ui) end
        F.load()
        writeRaw("zedqa_release.txt", "")
        say("released"); say("DONE")   -- (the runner looks for "ZEDQA mho DONE" exactly)
        Events.OnFETick.Remove(t)
    end
end
Events.OnFETick.Add(t)
say("start")
