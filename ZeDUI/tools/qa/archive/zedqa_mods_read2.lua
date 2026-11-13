-- ZeDUI/tools/qa/zedqa_mods_read2.lua  (Nov 4 2026, QA; Build's 133c0dc4) MAIN MENU ONLY, part B after a restart.
-- Part A (zedqa_mods_read.lua) left: tab=off, hideInc=1, folder 2 labelled "red", the main menu list's
-- separator labelled "teal". Checks each came back after the game restarted, then puts back the files
-- part A kept (Lua/ZeDQA_keep_*.txt). grep "ZEDQA mrd2".
local MM = ZeD.MainMenu
local O = ZeD.ModOrder
local F = ZeD.ModFolders
local function say(s) print("ZEDQA mrd2 " .. tostring(s)) end
local core = getCore()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_mrd2_" .. n .. ".png") end) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function W() return MM.root and MM.root.modsWin end
local function readRaw(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local t, line = {}, r:readLine()
    while line do t[#t + 1] = line; line = r:readLine() end
    r:close()
    return table.concat(t, "\n") .. "\n"
end
local function writeRaw(name, s) local w = getFileWriter(name, true, false); if w then w:write(s or ""); w:close() end end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    check(F.labelOf("2") == "red", "after a restart folder 2 still has its label (" .. tostring(F.labelOf("2")) .. ")")
    O.load()
    local e = O.entry("@list main menu")
    local lab
    for _, sp in ipairs(e and e.seps or {}) do if sp.name == "QA Label" then lab = sp.label end end
    check(lab == "teal", "after a restart the separator still has its label (" .. tostring(lab) .. ")")
    MM.openMods()
end)
at(40, function()
    local w = W()
    check(w.filter == "off" and w.hideInc == true, "after a restart the Mods screen opens on Off with Hide incompatible ticked (" .. tostring(w.filter) .. ", " .. tostring(w.hideInc) .. ")")
end)
at(70, function() shot("1_reopened") end)
at(80, function()
    local w = W()
    writeRaw("ZeD_modprofiles.txt", readRaw("ZeDQA_keep_prof.txt") or "")
    writeRaw("ZeD_modfolders.txt", readRaw("ZeDQA_keep_ui.txt") or "")
    O.load()
    F.load()
    w.filter = "all"; w.hideInc = false; w:dirty()
end)
at(100, function()
    -- the view file goes back last (the screen writes it while drawing)
    local w = W()
    w:discard()
    writeRaw("ZeD_modsview.txt", readRaw("ZeDQA_keep_view.txt") or "")
    say("put back: the profile file, the folder state, the view file")
end)
at(120, function()
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 140 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
