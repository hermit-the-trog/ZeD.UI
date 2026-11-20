-- ZeDUI/tools/qa/hfr_tabs.lua  (Nov 20 2026, QA; tag hft): the beta 21 hotfix report, CUTS E: character and world tabs
-- (git 13b9733ff 62a20a526). Pictures to Screenshots/hfr_E_*.png. Manifest hotfix_tabs.txt. Each section guards itself.
-- Farm, henhouse, pasture and fishing are in hfr_farm.lua and hfr_fish.lua (their own staging). What it puts back: the
-- wound, the tour, the notes, Style/theme/map-light as found, the windows as found. grep "ZEDQA hft".
local S = HFR and HFR.init and HFR.init("hft")
if not S then return end
local Q, TU = S.Q, ZeD.Tutorial
local St = ZeD.Settings

-- one tab, one picture: who "char" or "world", the tab id, the picture name; prep(), an optional function run first
function S.tab(who, id, name, prep, after)
    Q.step(10, function()
        S.openPair()
        if prep then prep() end
        S.tabOk = (who == "char") and S.charTab(id) or S.worldTab(id)
        Q.say(name .. ": tab " .. id .. " " .. tostring(S.tabOk))
    end)
    Q.step(60, function() S.clearChar() end)
    Q.still(10, function()
        local w = (who == "char") and S.CW() or S.WW()
        if S.tabOk and w and w._activeTab == id then S.shot(name) else Q.notTaken(name, "the " .. id .. " tab is not there or did not open") end
    end)
    if after then Q.step(5, after) end
end

Q.step(5, function()
    S.start0()
    S.was.light = St.mapLightOption and St.mapLightOption:getValue()
    S.was.base, S.was.accent, S.was.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    G1.tp(S.P.smoke, "SE")
end)
Q.zoomTo(1.0)

-- E_tour_last: the tour's last step, Done alone
Q.step(10, function()
    S.closePair()
    S.tourOk = TU and pcall(TU.start, S.pn, "mouse") or false
    Q.say("tour started " .. tostring(S.tourOk and TU.running()))
end)
Q.step(40, function()
    local n = #((TU and TU.STEPS) or {})
    for _ = 1, n + 2 do
        if TU and TU.running() and TU.step() < n then pcall(TU.next) end
    end
    Q.say("tour step " .. tostring(TU and TU.running() and TU.step()) .. " of " .. n)
end)
Q.step(50, function() end)
Q.still(10, function()
    if TU and TU.running() and TU.step() == #TU.STEPS then S.shot("E_tour_last_step") else Q.notTaken("E_tour_last_step", "the tour is not on its last step") end
end)
Q.step(10, function() if TU and TU.running() then pcall(TU.stop) end end)

-- the Character window's tabs
S.tab("char", "skills", "E_skills")
S.tab("char", "health", "E_health_uninjured")
Q.step(5, function() G1.wound(Q, true) end)
Q.step(30, function() local w = S.CW(); if w then w._healthFigureExpanded = true; w._healthHoveredPart = "Left Forearm" end end)
S.tab("char", "health", "E_health_wounded")
Q.step(5, function() local w = S.CW(); if w then w._healthHoveredPart = nil end; G1.wound(Q, false) end)
-- E_identity_hair: the Identity tab scrolled to its Hair and beard section (the ID card is above it; HB.takeScroll does the scroll)
Q.step(10, function() S.openPair(); S.identOk = S.charTab("identity") end)
Q.step(40, function() local w = S.CW(); if w and w._hb then w._hb.wantScroll = true end; S.clearChar() end)
Q.step(40, function() local w = S.CW(); if w and w._hb then w._hb.wantScroll = true end end)
Q.still(10, function()
    local w = S.CW()
    Q.say("identity: tab " .. tostring(w and w._activeTab) .. ", hair state " .. tostring(w and w._hb ~= nil) .. ", scroll " .. tostring(w and w._identityScroll and w._identityScroll.scrollPos))
    if S.identOk and w and w._activeTab == "identity" and w._hb then S.shot("E_identity_hair") else Q.notTaken("E_identity_hair", "the Identity tab or its hair section is not there") end
end)
S.tab("char", "thermal", "E_thermal")
S.tab("char", "journal", "E_journal_log")
-- Loadouts: the Journal's fifth page (in the strip only while Loadouts and outfits is on: the option is on for the shot, put back after)
Q.step(10, function()
    local o = St.loadoutsOption
    S.loadWas = o and o:getValue()
    if o then pcall(function() o:setValue(2) end) end
    Q.say("Loadouts and outfits on: " .. tostring(St.loadoutsOn and St.loadoutsOn()))
    S.openPair(); S.charTab("journal")
end)
Q.step(30, function() local w = S.CW(); if w then pcall(ZeD.JournalTab.setPage, w, 5) end; S.clearChar() end)
Q.step(40, function() end)
Q.still(10, function()
    local w = S.CW()
    if w and w._activeTab == "journal" and w._journalSubTab == 5 then S.shot("E_loadouts") else Q.notTaken("E_loadouts", "the Loadouts page did not open (sub tab " .. tostring(w and w._journalSubTab) .. ")") end
end)
Q.step(5, function()
    local w = S.CW(); if w then pcall(ZeD.JournalTab.setPage, w, 1) end
    if S.loadWas and St.loadoutsOption then pcall(function() St.loadoutsOption:setValue(S.loadWas) end) end
end)
-- the equipment doll, at rest and mid-drag
S.tab("char", "equip", "E_doll_rest", function() pcall(function() ZeD.EquipDoll.setView("doll") end) end)
Q.step(10, function()
    S.hammer = S.add("Base.Hammer")
    S.dragWas = ISMouseDrag and ISMouseDrag.dragging
    pcall(function()
        ISMouseDrag.dragging = { S.hammer }
        ISMouseDrag.draggingFocus = S.CW()
    end)
end)
Q.step(40, function() S.clearChar() end)
Q.still(10, function()
    local w = S.CW()
    if w and w._activeTab == "equip" then S.shot("E_doll_dragging") else Q.notTaken("E_doll_dragging", "Equipment tab not showing") end
end)
Q.step(5, function()
    pcall(function() ISMouseDrag.dragging = S.dragWas; ISMouseDrag.draggingFocus = nil end)
    pcall(function() ZeD.EquipDoll.setView(S.was.equip or "list") end)
    S.takeMade()
    S.charTab("loot")
end)
Q.step(5, function() Q.notTaken("E_admin_tab", "the Admin tab exists only for an admin on a server (AdminTab.visible needs isClient()); a single-player save cannot show it") end)
Q.step(5, function() Q.notTaken("E_admin_world_tab", "the Admin tab exists only for an admin on a server (AdminTab.visible needs isClient())") end)
Q.step(5, function() Q.notTaken("E_server_tab", "the Server tab is on a server only (a single-player save has none)") end)

-- the World window's tabs
S.tab("world", "craft", "E_crafting_tab")
S.tab("world", "build", "E_building_tab")
S.tab("world", "furniture", "E_furniture_tab")
S.tab("world", "forage", "E_foraging_tab")

-- Messages: a note, the window open
Q.step(10, function()
    S.closePair()
    S.msg = false
    if ZeD.Messages and ZeD.Messages.add then
        pcall(function() ZeD.Messages.add("ZeDQA hfr", "mods", { head = "Dishes", text = "Dishes 1.0.2 is up to date." }) end)
        S.msg = true
    end
    Q.say("note added " .. tostring(S.msg))
end)
Q.step(20, function()
    local ok = pcall(function()
        if ZeD.Messages.open then ZeD.Messages.open("ZeDQA hfr") elseif ZeD_MessagesWindow and ZeD_MessagesWindow.open then ZeD_MessagesWindow.open(S.pn) end
    end)
    Q.say("messages open call " .. tostring(ok))
end)
Q.step(40, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local t = nil
        pcall(function() t = ui:get(i):getTable() end)
        if t and t.Type == "ZeD_MessagesWindow" and ui:get(i):isVisible() then S.msgWin = t; G1.clear(Q, t, "left", "Messages") end
    end
end)
Q.still(10, function()
    if S.msgWin then S.shot("E_messages") else Q.notTaken("E_messages", "no Messages window found") end
end)
Q.step(10, function()
    if S.msgWin then pcall(function() S.msgWin:close() end) end
    S.msgWin = nil
    pcall(function() ZeD.Messages.clear("ZeDQA hfr") end)
end)

-- Maps: no tool, a tool, the key, the Light map checkbox off and on (Survey, Dark)
Q.step(10, function()
    S.openPair()
    pcall(function() ZeD.applyTheme("dark", ZeD.currentAccent, ZeD.currentSize) end)
    pcall(function() St.mapLightOption:setValue(1) end)
    pcall(function()
        local v = WorldMapVisited.getInstance()
        v:setKnownInSquares(10800, 6000, 13400, 8300)
        v:setVisitedInSquares(10800, 6000, 13400, 8300)
    end)
end)
Q.waitFor(10, 300, function() return S.worldTab("maps") end, function(ok)
    S.mapTab = ok
    local mp = S.WW() and S.WW()._worldMapPanel
    S.mapStyleWas = mp and mp.style
    pcall(function() ZeD.MapsTab.setStyle(S.WW(), "survey") end)
end)
Q.step(40, function()
    local mp = S.WW() and S.WW()._worldMapPanel
    pcall(function() mp.mapAPI:centerOn(12060, 7121); mp:_zoomTo(15.75) end)
    S.clearChar()
end)
Q.step(90, function() end)
Q.still(10, function()
    if S.mapTab then S.shot("E_maps_no_tool") else Q.notTaken("E_maps_no_tool", "no Maps tab") end
end)
Q.step(10, function()
    -- (a pencil and a pen in the bag: a drawing tool can only be picked with something to write with)
    S.pencil = S.add("Base.Pencil"); S.pen = S.add("Base.Pen"); S.add("Base.RedPen"); S.add("Base.BluePen")
end)
Q.step(20, function()
    local w = S.WW()
    local zs = w and w._mapToolZones or {}
    local ids = {}
    for _, z in ipairs(zs) do ids[#ids + 1] = tostring(z.id) end
    Q.say("tool zones: " .. table.concat(ids, ","))
    if w and zs[1] then pcall(ZeD.MapsTab.onClick, w, zs[1].x + 2, zs[1].y + 2) end
end)
Q.step(5, function() local w = S.WW(); Q.say("tool in hand: " .. tostring(w and w._mapActiveTool)) end)
Q.step(40, function() end)
Q.still(10, function()
    local w = S.WW()
    if S.mapTab and w and w._mapActiveTool ~= nil then S.shot("E_maps_with_tool") else Q.notTaken("E_maps_with_tool", "no tool could be picked (tab " .. tostring(S.mapTab) .. ")") end
    -- else Q.notTaken("E_maps_with_tool", "no Maps tab") end
end)
Q.step(10, function() local w = S.WW(); if w and w._mapActiveTool ~= nil then pcall(ZeD.MapsTab.putDownTool, w) end end)
Q.step(10, function()
    local w = S.WW()
    local zs = w and w._mapToolZones or {}
    if w and zs[1] then pcall(ZeD.MapsTab.onClick, w, zs[1].x + 2, zs[1].y + 2) end   -- (again: down)
    if w then w._mapKeyOpen = true end
end)
Q.step(40, function() end)
Q.still(10, function()
    if S.mapTab then S.shot("E_map_key") else Q.notTaken("E_map_key", "no Maps tab") end
end)
Q.step(10, function() local w = S.WW(); if w then w._mapKeyOpen = false end end)
Q.step(40, function() end)
Q.still(10, function()
    local key = ZeD.MapsSurvey and ZeD.MapsSurvey.key and ZeD.MapsSurvey.key()
    Q.say("map palette (Light map off) " .. tostring(key))
    if S.mapTab then S.shot("E_maps_light_map_off") else Q.notTaken("E_maps_light_map_off", "no Maps tab") end
end)
Q.step(10, function() pcall(ZeD.MapsTab.toggleLight) end)
Q.step(90, function() end)
Q.still(10, function()
    local key = ZeD.MapsSurvey and ZeD.MapsSurvey.key and ZeD.MapsSurvey.key()
    Q.say("map palette (Light map on) " .. tostring(key))
    if S.mapTab and key == "light" then S.shot("E_maps_light_map_on") else Q.notTaken("E_maps_light_map_on", "tab " .. tostring(S.mapTab) .. ", palette " .. tostring(key)) end
end)
Q.step(10, function()
    pcall(function() ZeD.MapsTab.setStyle(S.WW(), S.mapStyleWas or "survey") end)
    pcall(function() if S.was.light then St.mapLightOption:setValue(S.was.light); if St.save then St.save() end end end)
    if S.was.base and S.was.base ~= ZeD.currentBase then pcall(function() ZeD.applyTheme(S.was.base, S.was.accent, S.was.size) end) end
    S.worldTab("loot")
end)

-- the context list (the right-click list, Context menu style = List), a tool's row in the Character list
Q.step(10, function()
    S.ctxWas = ZeD.Settings.contextStyleOption and ZeD.Settings.contextStyleOption:getValue()
    pcall(function() ZeD.Settings.contextStyleOption:setValue(2) end)
    S.hammer = S.add("Base.Hammer")
    S.openPair()
    S.charTab("loot")
    S.seekPos = nil
end)
Q.waitFor(5, 600, function() return S.seekRow(S.cc(), S.hammer) end, function(ok)
    Q.say("hammer row " .. tostring(ok))
    local z = ok and S.zone(S.cc(), S.hammer)
    if z then
        local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
        pcall(function() S.cc():onRightMouseDown(x, y); S.cc():onRightMouseUp(x, y) end)
    end
end)
Q.waitFor(5, 120, function() local m = nil; pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end); return m ~= nil end, function(ok)
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    Q.say("context menu " .. tostring(m and m.Type))
    S.ctxMenu = m
end)
Q.step(40, function() end)
Q.step(5, function() if S.ctxMenu then S.shot("E_context_list", true) else Q.notTaken("E_context_list", "no context menu opened") end end)
Q.step(5, function()
    pcall(function() if S.ctxMenu then S.ctxMenu:close() end end)
    G1.closeMenus()
    pcall(function() if S.ctxWas then ZeD.Settings.contextStyleOption:setValue(S.ctxWas) end end)
    S.takeMade()
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    if TU and TU.running() then pcall(TU.stop) end
    pcall(function() ISMouseDrag.dragging = nil; ISMouseDrag.draggingFocus = nil end)
    G1.wound(Q, false)
    pcall(function() ZeD.Messages.clear("ZeDQA hfr") end)
    pcall(function() if S.was.light then St.mapLightOption:setValue(S.was.light); if St.save then St.save() end end end)
    if S.was.base and S.was.base ~= ZeD.currentBase then pcall(function() ZeD.applyTheme(S.was.base, S.was.accent, S.was.size) end) end
    S.takeMade()
    G1.glassesBack(Q)
end)
Q.step(20, function()
    S.openPair(); S.charTab("loot"); S.worldTab("loot")
    S.back0()
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Q.say("put back")
end)
Q.start()
