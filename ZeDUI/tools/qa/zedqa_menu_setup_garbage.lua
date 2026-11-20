-- ZeDUI/tools/qa/zedqa_menu_setup_garbage.lua  (Nov 20 2026, QA; tag msg): MAIN MENU ONLY. The bug hunt's P2: a setup
-- file with values no option has. ZeD.Settings.loadSetup takes any number or word and hands it to the option
-- (PZAPI's combo box setValue keeps whatever it is given), then saves ModOptions.ini. This script loads such a file
-- (its own, Lua/zedqa_setup_garbage.txt; the director's ZeD_setup.txt is not touched) and checks what is left:
--   1. every ZeD combo box is still on one of its own items (a whole number from 1 to its item count)
--   2. the look on screen names a real theme, accent and size
--   3. ModOptions.ini has no ZeD line with a value outside its option's items
--   4. the options window opens on ZeD setup and draws 30 ticks with no new Lua error
-- What it puts back: every option's value, the look, ModOptions.ini line for line (zedqa_menu_mods_run.ps1 also puts
-- the file back). The garbage file stays in Zomboid/Lua (Lua cannot delete); delete it after the run.
-- Run: zedqa_menu_mods_run.ps1 -ModList zed_only_mods.txt -Script zedqa_menu_setup_garbage.lua -Tag msg
local MM = ZeD.MainMenu
local St = ZeD.Settings
local FILE = "zedqa_setup_garbage.txt"
local function say(s) print("ZEDQA msg " .. tostring(s)) end
local pass, fail, tick = 0, 0, 0
local steps = {}
local function at(n, fn) steps[#steps + 1] = { n = n + 80, fn = fn } end
local function check(ok, what, detail)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (detail ~= nil and (" | " .. tostring(detail)) or ""))
end
local keep = {}
local function opts() return St and St.opts end
local function readLines(name)
    local t = nil
    pcall(function()
        local r = getFileReader(name, false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
local function writeLines(name, lines)
    pcall(function()
        local w = getFileWriter(name, true, false)
        for _, l in ipairs(lines) do w:write(l .. "\r\n") end
        w:close()
    end)
end
local function errs() local n = -1; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
-- the combo boxes off their own items: id=value
local function offItems()
    local bad = {}
    for _, o in ipairs((opts() and opts().data) or {}) do
        if o.type == "combobox" and o.id then
            local v = o.selected
            local n = #(o.values or {})
            if type(v) ~= "number" or v < 1 or v > n or v ~= math.floor(v) then bad[#bad + 1] = o.id .. "=" .. tostring(v) .. " (1.." .. n .. ")" end
        end
    end
    return bad
end

at(2, function()
    keep.sel = {}
    for _, o in ipairs((opts() and opts().data) or {}) do
        if o.type == "combobox" and o.id then keep.sel[o.id] = o.selected end
    end
    keep.ini = readLines("ModOptions.ini")
    keep.base, keep.accent, keep.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    keep.err0 = errs()
    check(St and St.loadSetup and opts() ~= nil, "ZeD.Settings.loadSetup and the options are there")
    check(#offItems() == 0, "before: every ZeD combo box is on one of its own items", table.concat(offItems(), "; "))
    writeLines(FILE, {
        "ZeD-GUI setup; <option id>=<item>",
        "baseTheme=9", "accentColor=-1", "textSize=0", "lookStyle=3", "moodlePlace=abc", "uiScale=99",
        "seeThrough=1.5", "statusColors=true", "noSuchOption=2", "garbage line with no equals", "=4", "mapLight=2",
    })
end)
at(6, function()
    local ok, n = pcall(St.loadSetup, FILE)
    keep.loaded = ok and n or nil
    say("loadSetup returned " .. tostring(n) .. (ok and "" or " (it threw)"))
    check(ok, "loadSetup with a garbage file does not throw", tostring(n))
end)
at(12, function()
    local bad = offItems()
    check(#bad == 0, "after a garbage setup file every ZeD combo box is still on one of its own items", table.concat(bad, "; "))
    check(ZeD.BaseThemes[ZeD.currentBase] ~= nil and ZeD.AccentColors[ZeD.currentAccent] ~= nil and ZeD.TextSizes[ZeD.currentSize] ~= nil,
        "the look on screen names a real theme, accent and size", tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize))
    -- the file: each ZeD combobox line's value within its option's items
    local badIni = {}
    for _, l in ipairs(readLines("ModOptions.ini") or {}) do
        local id, v = l:match("^combobox|ZeD_UI|([%w_]+)|(.*)$")
        local o = id and opts().dict and opts().dict[id]
        if o then
            local nv = tonumber(v)
            if not nv or nv < 1 or nv > #(o.values or {}) or nv ~= math.floor(nv) then badIni[#badIni + 1] = id .. "=" .. tostring(v) end
        end
    end
    check(#badIni == 0, "ModOptions.ini holds no ZeD value outside its option's items", table.concat(badIni, "; "))
    check(opts().dict.mapLight and opts().dict.mapLight.selected == 2, "a good line in the same file is still taken (mapLight=2)",
        tostring(opts().dict.mapLight and opts().dict.mapLight.selected))
    pcall(MM.openOptions)
end)
at(45, function()
    local w = MM.root and MM.root.optsWin
    local shown = false
    pcall(function() shown = w ~= nil and w:isVisible() end)
    if shown then pcall(function() for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end end) end
    keep.optShown = shown
end)
at(80, function()
    local e1 = errs()
    check(keep.optShown, "the options window opens after the garbage load")
    check(keep.err0 >= 0 and e1 == keep.err0, "no new Lua error from the load or from ZeD setup drawing 30 ticks", (e1 - keep.err0) .. " new")
    local w = MM.root and MM.root.optsWin
    if w then pcall(function() w:back() end); if w.confirm == "back" then pcall(function() w:discard() end) end end
    if MM.view ~= "main" then pcall(MM.showView, "main") end
end)
-- put back
at(90, function()
    for id, v in pairs(keep.sel or {}) do
        local o = opts().dict[id]
        if o then o.selected = v; if o.element then o.element.selected = v end end
    end
    pcall(St.reapplyFromOptions)
    if keep.base then pcall(ZeD.applyTheme, keep.base, keep.accent, keep.size) end
    if keep.ini then writeLines("ModOptions.ini", keep.ini) end
end)
at(100, function()
    local bad = {}
    for id, v in pairs(keep.sel or {}) do if opts().dict[id] and opts().dict[id].selected ~= v then bad[#bad + 1] = id end end
    check(#bad == 0, "put back: every option as found", table.concat(bad, " "))
    say(string.format("end: %d pass, %d fail; view=%s", pass, fail, tostring(MM.view)))
    say(fail > 0 and ("VERDICT FAIL " .. fail) or ("VERDICT PASS " .. pass))
    say("DONE")
end)
local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, e = pcall(s.fn)
            if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end
        end
    end
    if tick > 220 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
