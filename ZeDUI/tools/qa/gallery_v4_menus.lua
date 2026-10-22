-- ZeDUI/tools/qa/gallery_v4_menus.lua  (Oct 22 2026)
-- MAIN MENU ONLY, hand-pushed through the QA bridge. The Workshop gallery's menu cards
-- (director, Oct 22: "show options screen and the mod manager features ... load orders,
-- profiles ... workshop uploader ... description editor and preview before uploading").
-- Needs the gallery's sample mods (Zomboid/mods/Sample*, plainly named, built for these
-- shots) on in mods/default.txt, and the staged folder Zomboid/Workshop/SampleLootTables.
-- Screenshots only. Nothing is accepted or uploaded: the mod list changes are discarded,
-- the order pages are left without keeping, the description editor is cancelled.
-- It does save three profiles (Everything / Crafting run / ZeD only); restore
-- Lua/pz_modlist_settings.cfg and Lua/ZeD_modprofiles.txt from the backup afterwards.
-- Tall windows (director, Oct 22: "make windows taller to show the full flow"): for the run the
-- monitor's screen area (MM.layout's tube) is stretched to the bottom of the display, so every
-- window on it shows its whole page; MM._layout is dropped at the end and rebuilt as it was.
-- Shots: mm4_*.png in Zomboid/Screenshots. "ZEDQA g4m ... DONE".
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA g4m " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("mm4_" .. n .. ".png") end) end
local steps, t = {}, 0
local T0 = 0
local function at(n, fn) T0 = T0 + n; steps[#steps + 1] = { n = T0, fn = fn } end
local function O() return MM.root.optsWin end
local function M() return MM.root.modsWin end
local function WS() return MM.root.workshopWin end
local function park() pcall(function() Mouse.setXY(getCore():getScreenWidth() - 4, getCore():getScreenHeight() - 4) end) end

-- 1. Options
at(2, function()
    park()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    local L = MM.layout()
    L.th = getCore():getScreenHeight() - L.ty - math.floor(L.s * 4)
    say("tube " .. L.tx .. "," .. L.ty .. " " .. L.tw .. "x" .. L.th)
    MM.openOptions()
end)
at(30, function() local w = O(); w.pageIdx = 1; w.scroll = 0; w.focusId = nil end)
at(20, function() shot("01_options_zed") end)
at(10, function() local w = O(); w.pageIdx = 7; w.scroll = 0; w.focusId = nil end)
at(20, function() shot("02_options_interface") end)
at(10, function() O():back() end)

-- 2. Mods: list, conflicts, needs, problems
at(30, function() MM.act.mods() end)
at(90, function()
    local w = M()
    local all, on, favs, maps, probs, confs, wsn = w:counts()
    say(string.format("mods all %d on %d maps %d problems %d conflicts %d ws %d", all, on, maps, probs, confs, wsn))
    w.filter = "all"; w.scroll = 0; w.sel = "SampleLootRebalance"; w.dscroll = 0
end)
at(20, function() shot("03_mods_conflict") end)
at(10, function() local w = M(); w.filter = "conflicts"; w.scroll = 0; w.sel = "SampleLootTables"; w.dscroll = 0 end)
at(20, function() shot("04_mods_conflicts_tab") end)
at(10, function() local w = M(); w.filter = "all"; w.scroll = 0; w.sel = "SampleCraftingPack"; w.dscroll = 0 end)
at(20, function() shot("05_mods_needs") end)
at(10, function() local w = M(); w.filter = "problems"; w.scroll = 0; w.sel = "SampleCarSounds"; w.dscroll = 0 end)
at(20, function() shot("06_mods_problem_missing") end)
at(10, function() local w = M(); w.sel = "SampleOldHud"; w.dscroll = 0 end)
at(20, function() shot("07_mods_problem_version") end)

-- 3. Profiles
at(10, function() local w = M(); w.filter = "all"; w.sel = nil; w:enterProfiles() end)
at(15, function() local w = M(); w:setConfirm("save"); w.field:setText("Everything") end)
at(10, function() M():savePreset() end)
at(15, function() local w = M(); w:setConfirm("paste"); w.field:setText("Crafting run:ZeD_UI;ExtraBooks;SampleCraftingCore;SampleCraftingPack;") end)
at(10, function() M():pastePreset() end)
at(15, function() local w = M(); w:setConfirm("paste"); w.field:setText("ZeD only:ZeD_UI;") end)
at(10, function() M():pastePreset() end)
at(15, function() local w = M(); w:setConfirm(false); w:enterProfiles(); w.psel = "Crafting run"; w.dscroll = 0; w.focusId = nil end)
at(20, function()
    for _, p in ipairs(M():profiles()) do local d = M():profileDiff(p); say(string.format("profile %s n=%d on=%d off=%d use=%s", tostring(p.label), d.count, #d.on, #d.off, tostring(d.inUse))) end
    shot("08_profiles")
end)

-- 4. Load order and map order (left without keeping)
-- (Crafting Core moved below Crafting Pack, which needs it, on the page only: the rule shows broken)
at(10, function() local w = M(); w:leaveProfiles(); w:enterOrder("order")
    local core, pack
    for i, id in ipairs(w.order) do if id == "SampleCraftingCore" then core = i elseif id == "SampleCraftingPack" then pack = i end end
    if core and pack and core < pack then table.remove(w.order, core); table.insert(w.order, pack, "SampleCraftingCore") end
    for i, id in ipairs(w.order) do if id == "SampleCraftingPack" then w.oSel = i end end
    say("order " .. table.concat(w.order, ";")) end)
at(20, function() shot("09_load_order") end)
at(10, function() M():leaveOrder(false) end)
at(10, function() local w = M(); if w:changed() then w:discard() else w:back() end end)

-- 5. The upload window and the description editor (never Upload)
at(30, function() MM.act.workshop() end)
at(30, function()
    local w = WS()
    for i, it in ipairs(w.items) do say("ws item " .. i .. " " .. tostring(it:getTitle())); if tostring(it:getTitle()) == "Sample Loot Tables" then w:pick(i) end end
    w.fscroll = 0
end)
at(20, function() shot("11_upload") end)
at(10, function() WS():openEditor() end)
at(30, function() local e = MM.root.wsdescWin; say("editor blocks " .. #e.blocks); e:select(2) end)
at(20, function() shot("12_editor") end)
at(10, function() local e = MM.root.wsdescWin; e:select(9) end)
at(20, function() shot("13_editor_table") end)
at(10, function() MM.root.wsdescWin:finish(false) end)
at(20, function() shot("14_upload_back") end)
at(10, function() WS():back() end)
at(20, function() MM._layout = nil; say("view " .. tostring(MM.view)); say("DONE") end)

local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > T0 + 5 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
