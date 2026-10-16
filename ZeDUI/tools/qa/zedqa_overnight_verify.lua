-- ZeDUI/tools/qa/zedqa_overnight_verify.lua  (Oct 15 2026)
-- In game on the ZeD-QA save (copy to Zomboid/Lua/zedqa.lua, bump zedqa.go;
-- grep "ZEDQA vf"). Verifies:
--   * clothing's Inspect opens the ZeD item card (a shirt with a hole), and a
--     torn part's dock opens vanilla's tailoring choices in the ZeD list;
--   * the Craft tab's Ready list with something craftable in the bag (a sheet:
--     Rip Sheet), and that it stays listed across the tab's half-second rebuild;
--   * Smoke on the D-pad Right wheel with a lighter in the bag;
--   * the map's left stick (the tick, with the stick and the controller faked).
-- Everything given is taken back at the end.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA vf " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_vf_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local CC, Q = ZeD.CraftingCore, ZeD.QuickWheel
local given, shirt = {}, nil
local function give(ft)
    local ok, it = pcall(function() return p:getInventory():AddItem(ft) end)
    if ok and it then given[#given + 1] = it; return it end
    say("could not give " .. ft)
end
local function ctxNames()
    local ctx = getPlayerContextMenu(pn)
    local t = {}
    for _, o in ipairs(ctx and ctx.options or {}) do t[#t + 1] = tostring(o.name) .. (o.notAvailable and "(off)" or "") .. (o.subOption and "(>)" or "") end
    return table.concat(t, " | ")
end
local function closeCtx()
    local ctx = getPlayerContextMenu(pn)
    if ctx and ctx._zedMenu then pcall(function() ctx._zedMenu:close() end) end
    if ctx then pcall(function() ctx:closeAll() end) end
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    shirt = give("Base.Tshirt_DefaultTEXTURE")
    for _, ft in ipairs({ "Base.Needle", "Base.Thread", "Base.RippedSheets", "Base.RippedSheets", "Base.DenimStrips", "Base.Sheet", "Base.CigaretteSingle", "Base.Lighter" }) do give(ft) end
    if shirt then
        local part = BloodBodyPartType.Torso_Upper
        local ok = pcall(function() shirt:getVisual():setHole(part) end)
        if not ok then ok = pcall(function() shirt:addHole(part) end) end
        say("shirt " .. tostring(shirt:getDisplayName()) .. " hole made=" .. tostring(ok) .. " holes=" .. tostring(shirt:getHolesNumber()))
    end
end)
-- 1. Inspect
at(10, function() ISInventoryPaneContextMenu.onInspectClothing(p, shirt) end)
at(60, function()
    local w = ZeD_CharacterWindow.getWindow()
    say("after Inspect: char window open=" .. tostring(ZeD_CharacterWindow.isOpen()) .. " card item=" .. tostring(w and w._drawerItem and w._drawerItem:getDisplayName())
        .. " vanilla garment window=" .. tostring(ISGarmentUI.windows[pn] and ISGarmentUI.windows[pn]:isVisible()))
    shot("01_inspect_card")
end)
at(70, function()
    local w = ZeD_CharacterWindow.getWindow()
    local card = w and w._itemCard
    local rects = card and card._zoneDockRects or {}
    say("dock rects: " .. #rects)
    local r = rects[1]
    if r then card:_onZonePress(r.zoneIdx, r.zone, r) end
end)
at(85, function() say("tailoring list: " .. ctxNames()); shot("02_tailor_list") end)
at(95, function() closeCtx() end)
-- 2. Craft: Ready
at(100, function() ZeD_WorldWindow.openTab(pn, "craft") end)
at(200, function()
    local w = ZeD_WorldWindow.getWindow()
    local st = w and w._craftState
    local names = {}
    for _, rd in ipairs(st and st.filteredCache or {}) do names[#names + 1] = rd.entry.displayName end
    say("craft Ready (" .. tostring(CC.showMode(st, nil)) .. "): " .. #names .. " [" .. table.concat(names, "; ", 1, math.min(#names, 12)) .. "]")
    shot("03_craft_ready")
end)
at(260, function()
    local w = ZeD_WorldWindow.getWindow()
    local st = w and w._craftState
    say("craft Ready after a rebuild: " .. #(st and st.filteredCache or {}))
end)
-- 3. Smoke
at(270, function()
    for _, g in ipairs({ "smoke" }) do end
    ISDPadWheels.onDisplayRight({ player = pn })
    local menu = getPlayerRadialMenu(pn)
    local t = {}
    for _, s in ipairs(menu.slices or {}) do t[#t + 1] = tostring(s.text) end
    say("D-pad Right: [" .. table.concat(t, " | ") .. "]")
    Q.openGroup(p, "smoke")
    t = {}
    for _, s in ipairs(menu.slices or {}) do t[#t + 1] = tostring(s.text) end
    say("Smoke: [" .. table.concat(t, " | ") .. "]")
end)
at(285, function() shot("04_smoke"); local menu = getPlayerRadialMenu(pn); pcall(function() menu:undisplay() end); pcall(function() menu:removeFromUIManager() end) end)
-- 4. the map's left stick through the tick (the stick and the controller faked)
local fake = {}
at(290, function() ZeD_WorldWindow.openTab(pn, "maps") end)
at(370, function()
    local w = ZeD_WorldWindow.getWindow()
    local F, D = ZeD.Input.Focus, ZeD.Input.Detector
    local mp = w._worldMapPanel
    if not mp then say("no map"); return end
    mp:seedGpCursor()
    fake.x0, fake.y0 = mp._gpCursorX, mp._gpCursorY
    D.setLockedMode("gamepad")
    F.claimFocus(w)
    for zi, z in ipairs(w._focusRing or {}) do
        for ei, e in ipairs(z.elements or {}) do
            if e.isCanvasCursor then w._focusIdx = zi; z.focusedElementIdx = ei end
        end
    end
    local el = F.getFocusedElement(w)
    say("focused " .. tostring(el and el.id) .. " cursor " .. tostring(fake.x0) .. "," .. tostring(fake.y0))
    fake.axis, fake.jd = getControllerAxisValue, getJoypadData
    getControllerAxisValue = function(c, a) if a == 0 then return 0.9 end; if a == 1 then return 0.0 end; return fake.axis(c, a) end
    getJoypadData = function(i) return { id = 0, player = 0 } end
end)
at(400, function()
    getControllerAxisValue, getJoypadData = fake.axis, fake.jd
    local w = ZeD_WorldWindow.getWindow()
    local mp = w._worldMapPanel
    say(string.format("stick right for half a second: cursor %s,%s -> %s,%s", tostring(fake.x0), tostring(fake.y0), tostring(mp._gpCursorX), tostring(mp._gpCursorY)))
    ZeD.Input.Detector.setLockedMode(nil)
    ZeD.Input.Focus.releaseFocus()
end)
at(410, function()
    for _, it in ipairs(given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    closeCtx()
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 420 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
