-- ZeDUI/tools/qa/zedqa_menu_lite.lua  (Nov 18 2026, QA; tag mlite): MAIN MENU ONLY, pushed through the QA bridge.
-- The FEATURE_MAP row "Lite desk and Mods" (beta 21; the director: "If vanilla does it, so does Lite"). The rest of
-- Lite is checked in game by rt_lite.lua. What it checks:
--   1. Style set to Lite through ZeD's own option (ZeD.Settings.lookStyleOption, as ZeD setup's Style row sets it):
--      ZeD.Settings.lite() reads it
--   2. the desk (ZeD_MainMenuNotes.lua): MM.leftItems() is empty (no Pasties, CletusWorks, apps, Documents or
--      notes); the ZeD menu, MM.menuItems("zed"), has no Notepad, Pasties or app rows
--   3. the Mods screen (ZeD_MainMenuMods.lua): opened; its footer band keeps Profiles and Load order and has no
--      New folder
--   4. Style set back to Full: the desk's left column and the ZeD menu's Notepad come back; the Mods footer has
--      New folder, Profiles and Load order
-- What it puts back: every ZeD option's stored value as found (Style among them, and the additions Lite set to the
-- Vanilla preset), ModOptions.ini line for line (zedqa_menu_mods_run.ps1 also puts the file back); the Mods screen
-- left through Back with nothing changed. Nothing is accepted or saved.
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/zed_only_mods.txt `
--        -Script ZeDUI/tools/qa/zedqa_menu_lite.lua -Tag mlite -TimeoutSec 240
-- Lines: "ZEDQA mlite PASS ..." / "FAIL ..." / "ERR ...", then "VERDICT PASS n" or "VERDICT FAIL n", then DONE.
-- grep "ZEDQA mlite".
local MM = ZeD.MainMenu
local St = ZeD.Settings
local function say(s) print("ZEDQA mlite " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what, detail)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (detail ~= nil and (" | " .. tostring(detail)) or ""))
end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local keep = {}
local K = {}

function K.opts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo end
function K.val(id)
    local zo = K.opts()
    local o = zo and zo.dict and zo.dict[id]
    local v = nil
    pcall(function() v = o:getValue() end)
    return v
end
function K.readIni()
    local t = nil
    pcall(function()
        local r = getFileReader("ModOptions.ini", false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function K.writeIni(lines)
    if not lines then return end
    pcall(function()
        local w = getFileWriter("ModOptions.ini", true, false)
        for _, l in ipairs(lines) do w:write(l .. "\r\n") end
        w:close()
    end)
end
-- Style set as ZeD setup's row sets it: the option's value, then its own onChange (Lite sets the additions)
function K.style(i)
    local o = St.lookStyleOption
    pcall(function() o:setValue(i) end)
    if o.onChange then pcall(o.onChange, o, i) end
end
function K.W() return MM.root and MM.root.modsWin end
-- the Mods screen's footer band, by button id
function K.band()
    local out = {}
    local w = K.W()
    for _, b in ipairs((w and w._specs) or {}) do if b.band and b.id then out[b.id] = true end end
    return out
end
function K.ids(t)
    local l = {}
    for k in pairs(t) do l[#l + 1] = tostring(k) end
    table.sort(l)
    return table.concat(l, " ")
end
-- the ZeD menu's rows' words
function K.menuWords()
    local out = {}
    local items = {}
    pcall(function() items = MM.menuItems("zed") or {} end)
    for _, it in ipairs(items) do if type(it) == "table" and it.text then out[tostring(it.text)] = true end end
    return out, #items
end
function K.leftN() local n = -1; pcall(function() n = #MM.leftItems() end); return n end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    keep.opt0 = {}
    local zo = K.opts()
    for _, o in ipairs((zo and zo.data) or {}) do
        if o.type == "combobox" and o.id then keep.opt0[o.id] = o.selected end
    end
    keep.ini0 = K.readIni()
    keep.style0 = K.val("lookStyle")
    say("as found: Style " .. tostring(keep.style0) .. " (1 Full, 2 Lite)")
    check(St and St.lite and St.lookStyleOption and MM and MM.leftItems and MM.menuItems and MM.openMods, "the main menu's Lite parts are loaded")
    K.style(2)
end)

-- 1, 2: Lite, the desk
at(10, function()
    check(St.lite() == true and K.val("lookStyle") == 2, "Lite desk: ZeD.Settings.lite() is true", tostring(K.val("lookStyle")))
    check(K.leftN() == 0, "Lite desk: no desk apps or notes in the left column (#MM.leftItems() == 0)", K.leftN())
    local words, n = K.menuWords()
    local np = ZeD.tr("UI_ZeD_Desk_NotepadTitle")
    local pa = ZeD.tr("UI_ZeD_Desk_Pasties")
    check(not words[np] and not words[pa], "Lite desk: the ZeD menu has no Notepad or Pasties rows", n .. " rows")
    MM.ctx.open = nil
    MM.openMods()
end)
-- 3: Lite, the Mods footer
at(30, function()
    local w = K.W()
    check(w ~= nil and w:isVisible(), "Lite Mods: the Mods screen opens")
    local b = K.band()
    check(b.profiles and b.order, "Lite Mods: the footer keeps Profiles and Load order", K.ids(b))
    check(not b.fnew, "Lite Mods: the footer has no New folder", K.ids(b))
    if w then pcall(function() w:back() end) end
end)
-- 4: Full again
at(45, function()
    check(K.W() == nil or not K.W():isVisible() or MM.view ~= "mods", "Lite Mods: Back leaves the Mods screen", tostring(MM.view))
    K.style(1)
end)
at(55, function()
    check(St.lite() == false, "Full desk: ZeD.Settings.lite() is false")
    check(K.leftN() > 0, "Full desk: the left column has the desk apps again", K.leftN())
    local words, n = K.menuWords()
    check(words[ZeD.tr("UI_ZeD_Desk_NotepadTitle")] == true, "Full desk: the ZeD menu has the Notepad again", n .. " rows")
    MM.ctx.open = nil
    MM.openMods()
end)
at(75, function()
    local w = K.W()
    local b = K.band()
    check(b.profiles and b.order, "Full Mods: the footer has Profiles and Load order", K.ids(b))
    if w and w.folderNewSpec and w.filter ~= "ws" then
        check(b.fnew == true, "Full Mods: the footer has New folder again", K.ids(b))
    else
        say("SKIP Full Mods: the footer has New folder again (no folders here: the Workshop tab, or no ModFolders)")
    end
    if w then pcall(function() w:back() end) end
end)
-- (Nov 19 2026, QA: the FEATURE_MAP row "Folder colors"; ZeD_MainMenuModsFolders.lua. A folder id no folder uses,
-- 9999, so no real folder changes; ModFolders.cfg must not change at all. zedqa_menu_mods_run.ps1 puts both files back.)
function K.lines(name)
    local t = {}
    pcall(function()
        local r = getFileReader(name, false)
        if not r then return end
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
at(80, function()
    local MMM = ZeD_MMMods
    if not (MMM and MMM.setFolderColor and MMM.folderColorKey and MMM.folderTint) then
        check(false, "Folder colors: ZeD_MMMods.setFolderColor, folderColorKey and folderTint are loaded"); return
    end
    local cfg0 = table.concat(K.lines("ModFolders.cfg"), "\n")
    MMM.setFolderColor(9999, "blue")
    local has = false
    for _, l in ipairs(K.lines("ZeD_folder_colors.txt")) do if l == "9999=blue" then has = true end end
    check(MMM.folderColorKey(9999) == "blue" and has, "Folder colors: a folder set to blue reads blue and ZeD_folder_colors.txt has 9999=blue",
        tostring(MMM.folderColorKey(9999)) .. ", file " .. tostring(has))
    local t = MMM.folderTint(9999)
    local A = ZeD.AccentColors and ZeD.AccentColors.blue
    local tone = A and (A[(ZeD.currentBase == "light") and "light" or "dark"] or A.dark)
    check(t ~= nil and tone ~= nil and t == tone.accent, "Folder colors: its rows' wash is the blue accent of this theme")
    MMM.setFolderColor(9999, nil)
    local still = false
    for _, l in ipairs(K.lines("ZeD_folder_colors.txt")) do if l:match("^9999=") then still = true end end
    check(MMM.folderColorKey(9999) == nil and not still and MMM.folderTint(9999) == nil, "Folder colors: No color clears it, in memory and in the file")
    check(table.concat(K.lines("ModFolders.cfg"), "\n") == cfg0, "Folder colors: ModFolders.cfg (the Mod Folders mod's file) is unchanged")
end)
-- put back
at(90, function()
    local zo = K.opts()
    for id, v in pairs(keep.opt0 or {}) do
        local o = zo and zo.dict and zo.dict[id]
        if o and o.selected ~= v then pcall(function() o:setValue(v) end) end
    end
    K.writeIni(keep.ini0)
end)
at(100, function()
    local bad = {}
    for id, v in pairs(keep.opt0 or {}) do if K.val(id) ~= v then bad[#bad + 1] = id end end
    check(#bad == 0 and K.val("lookStyle") == keep.style0, "put back: every ZeD option as found, Style among them", table.concat(bad, " "))
    local now = K.readIni()
    check(keep.ini0 ~= nil and now ~= nil and table.concat(now, "\n") == table.concat(keep.ini0, "\n"), "put back: ModOptions.ini line for line")
end)
at(110, function()
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
    if tick > 130 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
