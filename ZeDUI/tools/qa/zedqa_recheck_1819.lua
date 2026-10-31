-- ZeDUI/tools/qa/zedqa_recheck_1819.lua  (Oct 30 2026, QA)
-- Punch list 18 and 19 rechecked in game (the pause screen's ZeD setup): the presets move the switches, a hand
-- change reads Custom, Custom brings the hand picks back, Apply writes them; Loadouts off hides its surfaces, on
-- brings them back; the preset and Restock words printed ("Access"); a shot of the Restock row dimmed while the
-- Loadouts pick is Off. "ZEDQA r1819 ..." PASS / FAIL lines, ending DONE. Screenshots/zqa_r1819_*.png.
local G = "run"
local function say(s) print("ZEDQA r1819 " .. tostring(s)) end
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra and (" | " .. tostring(extra)) or "")) end
local p = getPlayer(); local pn = p:getPlayerNum()
local S, L, EL, MM = ZeD.Settings, ZeD.Lists, ZeD.EquipLoadout, ZeD.MainMenu
local O = PZAPI.ModOptions:getOptions("ZeD_UI")
local IDS = S.ADDITION_IDS
local PRESETS = S.ADDITION_PRESETS
local function opt(id) return O.dict[id] end
local function live(id) local o = opt(id); local el = o.element; return (el and el.selected) or o:getValue() end
local function presetLive() local el = S.additionsPresetOption.element; return el and el.selected end
local function pick(n) S.additionsPresetOption.onChange(nil, n) end
local function hand(id, v) local el = opt(id).element; el.selected = v; if el.onChange then el.onChange(el.target, el) end end
local function liveSet() local t = {}; for _, id in ipairs(IDS) do t[#t + 1] = id .. "=" .. tostring(live(id)) end; return table.concat(t, " ") end
local function matches(set) for id, v in pairs(set) do if live(id) ~= v then return false, id end end; return true end
local function shot(n) pcall(function() getCore():TakeFullScreenshot(n .. ".png") end) end
local function cw() return ZeD_CharacterWindow.getWindow() end

local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

step(5, function()
    say("stored at start: preset " .. tostring(S.additionsPresetOption:getValue()) .. " | " .. liveSet())
    ZeD.DpadWheels.H.openSetup(p, pn)
end)
step(90, function()
    local ow = MM.pauseOpts
    check(ow ~= nil and ow:isVisible(), "ZeD setup opens from the pause screen")
    check(S.additionsPresetOption.element ~= nil, "the preset control is on the screen")
    -- the Additions group in view: the page scrolled until the preset row shows
    for _, sc in ipairs({ 0, 400, 800, 1200 }) do ow.scroll = sc end
end)
-- the screenshots for the four words: three scroll places
step(2, function() MM.pauseOpts.scroll = 0 end)
step(30, function() shot("zqa_r1819_setup_0") end)
step(2, function() MM.pauseOpts.scroll = 9999 end)
step(30, function() shot("zqa_r1819_setup_end"); say("scroll at the end " .. tostring(MM.pauseOpts.scroll)) end)
step(2, function() MM.pauseOpts.scroll = math.floor((MM.pauseOpts.scroll or 0) / 2) end)
step(30, function() shot("zqa_r1819_setup_mid") end)
-- the words, and the Restock row dimmed while the Loadouts pick is Off (before Apply)
step(5, function()
    local w = {}
    for _, k in ipairs({ "UI_ZeD_Settings_PresetVanilla", "UI_ZeD_Settings_PresetPlus", "UI_ZeD_Settings_PresetAccessible",
        "UI_ZeD_Settings_RestockHardcore", "UI_ZeD_Settings_RestockCasual", "UI_ZeD_Settings_RestockAccessible" }) do w[#w + 1] = ZeD.tr(k) end
    say("words: presets " .. w[1] .. " | " .. w[2] .. " | " .. w[3] .. "; restock " .. w[4] .. " | " .. w[5] .. " | " .. w[6])
    check(w[3]:find("Access") ~= nil and not w[3]:find("Accessible") and not w[6]:find("Accessible"), "the Access names read Access, not Accessible")
    hand("loadouts", 1)
end)
step(30, function() shot("zqa_r1819_restock_dim_end") end)
step(2, function() MM.pauseOpts.scroll = math.floor((MM.pauseOpts.scroll or 0) / 2) end)
step(30, function() shot("zqa_r1819_restock_dim_mid"); hand("loadouts", 2) end)
-- the presets
step(5, function()
    pick(1); local ok, id = matches(PRESETS[1])
    check(ok and presetLive() == 1, "Vanilla turns every addition off", ok and liveSet() or ("left on: " .. tostring(id)))
    pick(2); ok, id = matches(PRESETS[2])
    check(ok and presetLive() == 2 and live("restock") == 2, "Vanilla Plus turns every addition on, Restock Casual", ok and liveSet() or id)
    pick(3); ok, id = matches(PRESETS[3])
    check(ok and presetLive() == 3 and live("restock") == 3, "Vanilla Accessible: every addition on, Restock Accessible", ok and liveSet() or id)
    pick(2)
    hand("readMarks", 1)
    check(presetLive() == 4, "a hand change (read marks off) reads Custom", "preset " .. tostring(presetLive()))
    pick(1)
    check(presetLive() == 1 and live("readMarks") == 1 and live("loadouts") == 1, "Vanilla over Custom: all off again")
    pick(4)
    check(presetLive() == 4 and live("readMarks") == 1 and live("loadouts") == 2 and live("ammoBox") == 2, "Custom again brings the hand picks back (read marks off, the rest on)", liveSet())
end)
-- Apply: the Custom set stored and kept in its file
step(5, function() MM.pauseOpts:apply(false) end)
step(30, function()
    check(S.additionsPresetOption:getValue() == 4 and opt("readMarks"):getValue() == 1 and opt("loadouts"):getValue() == 2,
        "Apply stores Custom (read marks off, Loadouts on)", "preset " .. tostring(S.additionsPresetOption:getValue()))
    local r = getFileReader("ZeD_custom_additions.txt", false)
    local txt = {}
    if r then local l = r:readLine(); while l do txt[#txt + 1] = l; l = r:readLine() end; r:close() end
    check(#txt > 5 and table.concat(txt, ";"):find("readMarks=1") ~= nil, "Apply wrote the Custom set to ZeD_custom_additions.txt", table.concat(txt, ";"):sub(1, 300))
end)
-- Loadouts off (hand), Apply, close the pause screen
step(5, function() hand("loadouts", 1); MM.pauseOpts:apply(false) end)
step(20, function()
    check(not L.on(), "Loadouts off after Apply", "stored " .. tostring(opt("loadouts"):getValue()))
    ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU))
end)
-- what Loadouts off hides
local function surfaces(label, want)
    local w = cw()
    local hasFold = EL.sectionH(w, 800) > 0
    local ring = false
    for _, e in ipairs(ZeD.DpadWheels.B.character(p, pn) or {}) do if e.name == ZeD.tr("UI_ZeD_Wheel_Loadouts") then ring = true end end
    local jt = ZeD.JournalTab and ZeD.JournalTab.visibleTabs and ZeD.JournalTab.visibleTabs(w)
    local menu = false
    local it = p:getInventory():getItems():get(0)
    local ctx = ISInventoryPaneContextMenu.createMenu(pn, true, { it }, 10, 10)
    for _, o in ipairs((ctx and ctx.options) or {}) do if o.name == ZeD.tr("UI_ZeD_Lists_SaveToLoadout") then menu = true end end
    pcall(function() ctx:setVisible(false) end)
    local ok, started = pcall(function() return ZeD.Restock.start(p, "restock") end)
    local run = ZeD.Restock.runs and ZeD.Restock.runs[pn]
    if run and not want then pcall(function() ZeD.Restock.stop(p, "user") end) end
    check(hasFold == want, label .. ": the Equip fold " .. (want and "shows" or "is hidden"))
    check(ring == want, label .. ": the Loadouts ring " .. (want and "is on" or "is gone from") .. " the Character wheel")
    check(menu == want, label .. ": Save to loadout " .. (want and "is in" or "is gone from") .. " the right-click menu")
    if not want then check(run == nil, label .. ": Restock does not start", tostring(started)) end
end
step(20, function() surfaces("Loadouts off", false) end)
step(5, function()
    local w = cw()
    w._activeTab = "equip"; w._drawerMode = "tab"; w._drawerOpen = true
end)
step(40, function() shot("zqa_r1819_equip_loadouts_off") end)
-- on again: everything back
step(5, function() ZeD.DpadWheels.H.openSetup(p, pn) end)
step(90, function() hand("loadouts", 2); MM.pauseOpts:apply(false) end)
step(20, function() check(L.on(), "Loadouts on again after Apply"); ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end)
step(20, function() surfaces("Loadouts on", true) end)
step(40, function() shot("zqa_r1819_equip_loadouts_on"); local w = cw(); w._activeTab = "loot" end)
step(10, function() say("stored at the end: preset " .. tostring(S.additionsPresetOption:getValue()) .. " | " .. liveSet()); say("DONE (" .. fails .. " failed)") end)

local function onTick()
    if qi >= #Q then Events.OnPreUIDraw.Remove(onTick); return end
    wait = wait + 1
    if wait < Q[qi + 1].n then return end
    wait = 0; qi = qi + 1
    local ok, e = pcall(Q[qi].fn)
    if not ok then fails = fails + 1; say("ERR step " .. qi .. " " .. tostring(e)) end
end
Events.OnPreUIDraw.Add(onTick)
say("start")
