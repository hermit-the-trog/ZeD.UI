-- ZeDUI/tools/qa/zedqa_mods_profiles.lua  (Oct 15 2026)
-- Main menu QA: the build shown once (the ZeD menu's About block), the About
-- block itself, the mod manager's Problems tab and the Profiles page (new,
-- paste, the "No mods" row, MORE, update / rename questions, load, then
-- DISCARD so nothing is accepted). Run at the main menu: copy to
-- Zomboid/Lua/zedqa.lua and bump zedqa.go; grep console.txt for "ZEDQA mp".
-- Back up Zomboid/Lua/pz_modlist_settings.cfg first; the script deletes its
-- two test profiles at the end.

local MM = ZeD.MainMenu
local function say(s) print("ZEDQA mp " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mp_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local win
local function W() win = win or (MM.root and MM.root.modsWin); return win end
local function state(tag)
    local w = W()
    if not w then say(tag .. " no window"); return end
    local names = {}
    for _, p in ipairs(w:profiles()) do
        local d = w:profileDiff(p)
        names[#names + 1] = string.format("%s[n=%d on=%d off=%d miss=%d cant=%d use=%s]", tostring(p.label), d.count, #d.on, #d.off, #d.missing, #d.cannot, tostring(d.inUse))
    end
    local all, on, favs, maps, probs = w:counts()
    say(string.format("%s page=%s confirm=%s psel=%s inUse=%s counts=%d/%d/%d/%d/%d | %s", tag, tostring(w.page), tostring(w.confirm), tostring(w.psel),
        tostring(w:profileInUse()), all, on, favs, maps, probs, table.concat(names, " ")))
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
end)
at(20, function() shot("01_main") end)
at(30, function() MM.ctx.open = "zed" end)
at(45, function() shot("02_about") end)
at(55, function() MM.ctx.open = nil; MM.openMods() end)
at(90, function() state("list"); shot("03_list") end)
at(100, function() W().filter = "problems" end)
at(115, function() shot("04_problems"); W().filter = "all" end)
at(125, function() W():enterProfiles() end)
at(140, function() state("profiles"); shot("05_profiles_empty") end)
at(150, function() local w = W(); w:setConfirm("save"); w.field:setText("ZeD only") end)
at(165, function() shot("06_new_field") end)
at(170, function() W():savePreset() end)
at(185, function() state("saved"); shot("07_saved") end)
at(195, function() local w = W(); w:setConfirm("paste"); w.field:setText("Test pack:ModTemplate;ZeD_UI;NotARealMod42;") end)
at(205, function() W():pastePreset() end)
at(220, function() state("pasted"); shot("08_pasted") end)
at(230, function() W().psel = nil; W().dscroll = 0 end)
at(245, function() shot("09_no_mods") end)
at(255, function() W().psel = "ZeD only"; W():openMore() end)
at(270, function() shot("10_more") end)
at(275, function() MM.ctx.open = nil; W():setConfirm("update") end)
at(290, function() shot("11_update_ask") end)
at(295, function() W():setConfirm("rename") end)
at(310, function() shot("12_rename_field") end)
at(315, function() W():setConfirm(false); W().psel = "Test pack"; W().focusId = "prow:3" end)
at(330, function() local w = W(); w:loadProfile({ name = "Test pack" }) end)
at(345, function() state("loaded"); say("order now " .. table.concat((function() local t = {}; local l = ModSelector.instance.model:getActiveMods():getMods(); for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end; return t end)(), ";")); shot("13_loaded_note") end)
at(355, function() W():enterProfiles() end)
at(370, function() state("profiles after load"); shot("14_profiles_after_load") end)
-- put everything back: discard the change (vanilla's NO), delete the two test profiles
at(380, function() local w = W(); w:leaveProfiles(); w:discard() end)
at(410, function()
    local m = ModSelector.instance.model
    say("after discard ZeD_UI active=" .. tostring(m.mods.ZeD_UI and m.mods.ZeD_UI.isActive) .. " view=" .. tostring(MM.view))
    MM.openMods()
end)
at(440, function()
    local w = W()
    w.psel = "ZeD only"; w:deletePreset()
    w.psel = "Test pack"; w:deletePreset()
    state("cleaned")
    w:back()
end)
at(470, function() say("view=" .. tostring(MM.view)); shot("15_back_main"); say("DONE") end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 490 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
