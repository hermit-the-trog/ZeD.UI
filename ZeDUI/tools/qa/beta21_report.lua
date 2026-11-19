-- ZeDUI/tools/qa/beta21_report.lua  (Nov 19 2026, QA; tag b21r): the beta 21 visual report's in-game pictures (the
-- director's standing ask, Nov 19: before a full release test, full-screen pictures of every change). Manifest
-- beta21_report.txt: after gallery_story_stage.lua (Angel at the Fossoil, West Point), gallery_unload.lua and
-- gallery_v1_a_common.lua (G1: the gallery rule on every shot, the pointer hidden, glasses on, debug hidden).
-- Pictures to Zomboid/Screenshots/b21r_*.png, moved by the run wrapper to Screenshots/beta21_report/ (4K at 1.75x), Style = Lite unless named full_:
--   lite_07_setup      ZeD setup, Look group, Style = Lite applied (no Additions or Chords group)
--   lite_01_world      both windows at working size on Loot, a shelf shown, a hammer's card out, belt and watch
--   lite_02_confirm    a vanilla question in ZeD's prompt with OK and Cancel (Rename bag): the good and bad colors
--   lite_03_radio      a radio in hand on the Character window's Radio tab (the plain face)
--   lite_04_appliance  a microwave on the World window's Craft tab
--   lite_05_dash       in a pickup with the engine running (the Dash Elite)
--   lite_06_watch      the corner clock with its speed row, windows shut
--   kbmap_11           the Keyboard map, a key picked and its action's key box listening
--   tour_14 .. tour_20 each of the tour's seven balloons
--   full_10_same       lite_01's moment with Style = Full
-- What it puts back: Style as found (picked the same way, ZeD setup and Apply), the radio, hammer and pickup taken
-- away, the microwave removed, the tour stopped, the windows open or shut as found. grep "ZEDQA b21r".
local S = { was = {}, made = {} }
local Q = G1 and G1.make and G1.make("b21r")
if not Q then print("ZEDQA b21r ERR run gallery_v1_a_common.lua first"); print("ZEDQA b21r DONE"); return end
if not (STORY and STORY.ready and STORY.P) then Q.say("ERR run gallery_story_stage.lua first"); Q.say("DONE"); return end
S.p, S.pn, S.core = G1.p, G1.pn, G1.core
S.CWm, S.WWm = ZeD_CharacterWindow, ZeD_WorldWindow
S.P = STORY.P
local St, MM, TU, KM = ZeD.Settings, ZeD.MainMenu, ZeD.Tutorial, ZeD.KeyboardMap
local DIR = "b21r_"   -- (taken to the top of Screenshots; beta21_report_run.ps1 moves them into beta21_report/)

-- ===================================================================== helpers
function S.CW() return S.CWm.getWindow() end
function S.WW() return S.WWm.getWindow() end
function S.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab or (tab ~= "loot" and win._drawerOpen == false) then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function S.charTab(id) local w = S.CW(); return (w and S.goTab(w, w._tabStripPanel, id)) and true or false end
function S.worldTab(id) local w = S.WW(); return (w and S.goTab(w, w._actionTabStrip, id)) and true or false end
function S.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (S.CWm.isOpen() and S.WWm.isOpen()) then S.CWm.toggleBothPaired(S.pn) end
end
function S.closePair()
    if S.CWm.isOpen() and S.WWm.isOpen() then S.CWm.toggleBothPaired(S.pn)
    else
        if S.CWm.isOpen() then S.CWm.toggle(S.pn) end
        if S.WWm.isOpen() then S.WWm.close(S.pn) end
    end
end
function S.clearChar()
    G1.clear(Q, S.CW(), "left", "the Character window")
    G1.clear(Q, S.WW(), "right", "the World window")
end
function S.add(ft)
    local it = nil
    pcall(function() it = S.p:getInventory():AddItem(ft) end)
    if it then S.made[#S.made + 1] = it end
    return it
end
function S.takeMade()
    for _, it in ipairs(S.made) do
        pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
        pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
        pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    end
    S.made = {}
end
function S.shot(name, keepMenu) Q.shot(DIR .. name, keepMenu) end
-- one source per window (as gallery_v1_a_zed.lua)
function S.oneSource()
    local done = true
    for _, pair in ipairs({ { S.CW(), S.CWm }, { S.WW(), S.WWm } }) do
        local win, mod = pair[1], pair[2]
        if win then
            for _, j in ipairs(win._mcSelected or {}) do
                local c = win._containers and win._containers[j]
                if c and c.inventory and mod.toggleColumn and #(win._mcSelected or {}) > 1 then mod.toggleColumn(c.inventory); done = false; break end
            end
        end
    end
    return done
end
-- the Character list's row for an item, its card opened by the list's own mouse handlers (as rt_lite.lua)
function S.content() local w = S.CW(); return w and w._mainContent end
function S.rowZone(item)
    local c = S.content()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
function S.seekRow(item)
    local c = S.content()
    if not (c and item) then return false end
    if S.rowZone(item) then return true end
    local sc = c._scroll
    if sc and sc.setScrollPos then
        S.seekPos = (S.seekPos or -0.1) + 0.1
        if S.seekPos > 1.001 then S.seekPos = 0 end
        sc:setScrollPos(S.seekPos)
    end
    return false
end
function S.clickRow(item)
    local c = S.content()
    local z = S.rowZone(item)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c._zedLastClick = nil
    c:onMouseDown(x, y)
    c:onMouseUp(x, y)
    return true
end
function S.cardOn(item)
    local w = S.CW()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end

-- ===================================================================== Style, picked as a player picks it
function S.opt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function S.menuUp() local up = false; pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end); return up end
function S.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
function S.setupRow(w, id)
    local o = S.opt(id)
    local el = o and o.element
    if not el then return nil end
    local rows = {}
    pcall(function() rows = w:zedSetupRows() end)
    for _, r in ipairs(rows) do if r.control == el then return r end end
    return nil
end
function S.stepTo(w, r, want)
    local c = r and r.control
    if not c then return false end
    for _ = 1, 8 do
        local cur = c.selected or 1
        if cur == want then return true end
        pcall(function() w:nudge(r, (want > cur) and 1 or -1) end)
        if c.selected == cur then break end
    end
    if c.selected ~= want then
        c.selected = want
        if c.onChange then pcall(c.onChange, c.target, c) end
    end
    return c.selected == want
end
-- Style to want (1 Full, 2 Lite): pause menu, Options, ZeD setup, the Style row, Apply; shotName: a picture of ZeD
-- setup after Apply (the Look group in view)
function S.pickStyle(want, shotName)
    Q.step(5, function()
        S.mu = S.menuUp()
        S.optOk = false
        if not S.mu then S.toggleMenu() end
    end)
    Q.waitFor(10, 400, function() return S.menuUp() and MM.pauseOpts ~= nil end, function(ok)
        if ok then pcall(MM.openOptions) end
    end)
    Q.waitFor(5, 300, function() return MM.pauseOpts ~= nil and MM.pauseOpts:isVisible() end, function(ok)
        local o = St.lookStyleOption
        if not ok then
            Q.say("note: Options did not open; Style set straight on the option")
            pcall(function() o:setValue(want); o:onChange(want) end)
            return
        end
        S.optOk = true
        local w = MM.pauseOpts
        for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
        w.scroll = 0
        local r = S.setupRow(w, "lookStyle")
        Q.say("Style row " .. tostring(r ~= nil) .. "; stepped to " .. want .. ": " .. tostring(r and S.stepTo(w, r, want)))
        pcall(function() w:apply(false) end)
    end)
    Q.step(30, function()
        local w = MM.pauseOpts
        if not (S.optOk and w) then return end
        if w.confirm and w.confirm ~= "back" then pcall(function() w:setConfirm(false) end) end
        w._groupCache = nil
        w.scroll = 0
        pcall(function() Mouse.setXY(20, 20) end)
    end)
    if shotName then
        Q.step(40, function()
            if S.optOk then
                G1.clear(Q, MM.pauseOpts, "left", "ZeD setup")
                S.shot(shotName, true)
            else Q.notTaken(shotName, "Options did not open") end
        end)
    end
    Q.step(10, function()
        local w = MM.pauseOpts
        if not (S.optOk and w) then return end
        pcall(function() w:back() end)
        if w.confirm == "back" then pcall(function() w:discard() end) end
    end)
    Q.step(10, function() if not S.mu and S.menuUp() then S.toggleMenu() end end)
    Q.waitFor(5, 300, function() return S.mu or not S.menuUp() end, function()
        Q.say("Style now " .. tostring(St.lookStyleOption:getValue()) .. ", lite() " .. tostring(St.lite and St.lite()))
    end)
end

-- the Loot moment: the stock spot, the shelf shown, a hammer's card out (lite_01 and full_10)
function S.lootMoment(name)
    Q.step(10, function()
        G1.tp(S.P.stock, "SE")
        S.openPair()
        if not S.hammer then S.hammer = S.add("Base.Hammer") end
    end)
    Q.step(60, function()
        S.charTab("loot"); S.worldTab("loot")
        if G1.shelf then S.WWm.selectContainer(G1.shelf.inv, 120, S.pn) end
    end)
    Q.waitFor(10, 600, function() return S.oneSource() end, function() end)
    Q.step(20, function() if G1.shelf then S.WWm.selectContainer(G1.shelf.inv, 120, S.pn) end; S.seekPos = nil end)
    Q.waitFor(5, 400, function() return S.seekRow(S.hammer) end, function(ok)
        Q.say("hammer row " .. tostring(ok) .. ", clicked " .. tostring(ok and S.clickRow(S.hammer)))
    end)
    Q.waitFor(10, 300, function() return S.cardOn(S.hammer) end, function(ok)
        Q.say("hammer card out " .. tostring(ok))
        S.clearChar()
    end)
    Q.still(10, function()
        if S.cardOn(S.hammer) then S.shot(name) else Q.notTaken(name, "the hammer's card did not open") end
    end)
    Q.step(5, function() if S.cardOn(S.hammer) then S.clickRow(S.hammer) end end)
end

-- ===================================================================== start
Q.step(5, function()
    local W = S.was
    W.style = St.lookStyleOption:getValue()
    W.speed = getGameSpeed()
    W.pairOpen = S.CWm.isOpen() and S.WWm.isOpen()
    pcall(function() W.inv = S.p:isInvisible(); W.god = S.p:isGodMod(); W.dda = S.p:isZombiesDontAttack() end)
    G1.clean(Q)
    pcall(function() STORY.day(11.0) end)
    Q.say(string.format("start at %d,%d | screen %dx%d | Style %s | look %s %s",
        math.floor(S.p:getX()), math.floor(S.p:getY()), S.core:getScreenWidth(), S.core:getScreenHeight(),
        tostring(W.style), tostring(ZeD.currentBase), tostring(ZeD.currentAccent)))
    G1.fillShelf(Q)
    G1.tp(S.P.stock, "SE")
end)
-- (the gallery's zoom: Angel readable at 4K, as gallery_v1_a_zed.lua's pictures)
Q.zoomTo(1.0)
-- lite_07: Lite picked on ZeD setup, the picture after Apply
S.pickStyle(2, "lite_07_setup")
-- lite_01: the Loot moment
S.lootMoment("lite_01_world")
-- lite_02: a vanilla question with OK and Cancel (Rename bag), in ZeD's prompt
Q.step(10, function()
    local bag = S.add("Base.Bag_Schoolbag")
    S.box = nil
    pcall(function()
        local W, H = S.core:getScreenWidth(), S.core:getScreenHeight()
        S.box = ISTextBox:new(math.floor(W * 0.18), math.floor(H * 0.45), 280, 180, getText("ContextMenu_NameThisBag"), bag and bag:getName() or "", nil, function() end, S.pn)
        S.box:initialise()
        S.box:addToUIManager()
    end)
    Q.say("rename prompt asked " .. tostring(S.box ~= nil))
end)
Q.step(60, function()
    S.prompt = G1.findTop and G1.findTop("ZeD_Prompt") or nil
    if not S.prompt then
        pcall(function()
            local ui = UIManager.getUI()
            for i = 0, ui:size() - 1 do
                local t = nil
                pcall(function() t = ui:get(i):getTable() end)
                if t and t.Type == "ZeD_Prompt" and ui:get(i):isVisible() then S.prompt = t end
            end
        end)
    end
    Q.say("ZeD prompt up " .. tostring(S.prompt ~= nil))
    if S.prompt then S.shot("lite_02_confirm", true) else Q.notTaken("lite_02_confirm", "no ZeD prompt on screen") end
end)
Q.step(10, function()
    local P = S.prompt or S.box
    if P then
        pcall(function() if P.close then P:close() else P:setVisible(false); P:removeFromUIManager() end end)
    end
    S.prompt, S.box = nil, nil
end)
-- lite_06: the corner clock, windows shut
Q.step(10, function() S.closePair() end)
Q.still(20, function()
    local W = ZeD.Watch and ZeD.Watch._instance
    local vis = false
    pcall(function() vis = W ~= nil and W:isReallyVisible() end)
    Q.say("watch in the corner " .. tostring(vis) .. ", belt mode " .. tostring(ZeD.Watch and ZeD.Watch.beltMode and ZeD.Watch.beltMode()))
    if vis then S.shot("lite_06_watch") else Q.notTaken("lite_06_watch", "no watch on screen") end
end)
-- lite_03: a radio in hand on the Radio tab
Q.step(10, function()
    S.radio = S.add("Base.RadioRed")
    pcall(function() S.p:setPrimaryHandItem(S.radio) end)
    S.openPair()
end)
Q.waitFor(10, 300, function()
    local w = S.CW()
    local r = w and w._radios and w._radios[1]
    return r ~= nil and r.radioInstance == S.radio
end, function(ok) Q.say("radio in hand, Radio tab " .. tostring(ok and S.charTab("radio"))) end)
Q.step(40, function() S.clearChar() end)
Q.still(10, function()
    local w = S.CW()
    if w and w._activeTab == "radio" then S.shot("lite_03_radio") else Q.notTaken("lite_03_radio", "the Radio tab did not open") end
end)
Q.step(5, function()
    -- (the radio and the bag taken back, so full_10 shows lite_01's inventory)
    pcall(function() S.p:setPrimaryHandItem(nil) end)
    local keep = {}
    for _, it in ipairs(S.made) do
        if it == S.hammer then keep[#keep + 1] = it
        else pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    end
    S.made = keep
    S.charTab("loot")
end)
-- lite_04: a microwave on the Craft tab (a white microwave placed beside Angel, inside the store: power)
Q.step(10, function()
    S.micro = nil
    for _, o in ipairs({ { -2, 0 }, { 2, 0 }, { 0, -2 }, { 0, 2 } }) do
        local sq = getCell():getGridSquare(math.floor(S.p:getX()) + o[1], math.floor(S.p:getY()) + o[2], math.floor(S.p:getZ()))
        local free = false
        if sq then pcall(function() free = sq:isFree(false) end) end
        if free then
            pcall(function()
                local obj = IsoStove.new(getCell(), sq, getSprite("appliances_cooking_01_24"))
                pcall(function() obj:createContainersFromSpriteProperties() end)
                sq:AddSpecialObject(obj)
                if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
                S.micro, S.microSq = obj, sq
            end)
            if S.micro then break end
        end
    end
    Q.say("microwave placed " .. tostring(S.micro ~= nil))
end)
Q.step(30, function()
    S.microOpen = S.micro ~= nil and ZeD.Stations and ZeD.Stations.open(S.p, S.micro) or false
    Q.say("microwave on the Craft tab " .. tostring(S.microOpen))
end)
Q.step(60, function() S.clearChar() end)
Q.still(10, function()
    if S.microOpen then S.shot("lite_04_appliance") else Q.notTaken("lite_04_appliance", "the microwave did not open") end
end)
Q.step(10, function()
    pcall(function() ZeD.Stations.unbind(S.p) end)
    if S.micro and S.microSq then pcall(function() S.microSq:transmitRemoveItemFromSquare(S.micro) end) end
    S.micro = nil
    S.worldTab("loot")
end)
-- kbmap_11: the Keyboard map, a key picked, its action listening
Q.step(10, function()
    S.closePair()
    S.kmOk = KM and pcall(KM.open, S.pn) or false
end)
Q.step(40, function()
    local w = KM and KM.windows and KM.windows[S.pn]
    if not w then Q.say("keyboard map window " .. tostring(S.kmOk)); return end
    S.kmWin = w
    G1.clear(Q, w, "left", "the Keyboard map")
    w.picked = Keyboard.KEY_E
    for _, b in ipairs(keyBinding or {}) do
        local v = b.value and tostring(b.value) or ""
        if v ~= "" and v:sub(1, 1) ~= "[" and getCore():getKey(v) == Keyboard.KEY_E then w.listening = v; break end
    end
    Q.say("picked E; listening " .. tostring(w.listening))
end)
Q.still(10, function()
    if S.kmWin then S.shot("kbmap_11") else Q.notTaken("kbmap_11", "the Keyboard map did not open") end
end)
Q.step(5, function()
    if S.kmWin then S.kmWin.listening = nil; S.kmWin.picked = nil end
    pcall(KM.close, S.pn)
    S.kmWin = nil
end)
-- tour_14 .. tour_20: each balloon (the tour opens what each step shows)
Q.step(10, function()
    G1.tp(S.P.stock, "SE")
    -- (a Messages note, so the belt draws its lamp: the tour's step 7 points at it)
    if ZeD.Messages and ZeD.Messages.count() == 0 then pcall(function() ZeD.Messages.add("ZeDQA b21r", "mods", { head = "Dishes", text = "Dishes 1.0.2 is up to date." }) end); S.msgStaged = true end
    S.tourOk = TU and pcall(TU.start, S.pn, "mouse") or false
    Q.say("tour started " .. tostring(S.tourOk and TU.running()))
end)
for i = 1, 7 do
    Q.step(40, function() end)
    Q.still(10, function()
        local n = string.format("tour_%02d", 13 + i)
        if TU and TU.running() then
            Q.say(n .. ": step " .. TU.step() .. " " .. tostring(TU.STEPS[TU.step()] and TU.STEPS[TU.step()].key))
            S.shot(n)
            pcall(TU.next)
        else Q.notTaken(n, "the tour is not running") end
    end)
end
Q.step(10, function()
    if TU and TU.running() then pcall(TU.stop) end
    if S.msgStaged then pcall(function() ZeD.Messages.clear("ZeDQA b21r") end); S.msgStaged = nil end
end)
-- lite_05: a pickup with the engine running (the Dash Elite)
Q.step(10, function()
    S.closePair()
    G1.tp(S.P.smoke, "SE")
end)
Q.step(120, function()
    for _, o in ipairs({ { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 } }) do
        local sq = getCell():getGridSquare(math.floor(S.p:getX()) + o[1], math.floor(S.p:getY()) + o[2], math.floor(S.p:getZ()))
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if free then pcall(function() S.car = addVehicleDebug("Base.PickUpTruck", IsoDirections.N, nil, sq) end); if S.car then break end end
    end
    Q.say("pickup placed " .. tostring(S.car ~= nil))
end)
Q.waitFor(5, 300, function()
    if not S.car then return true end
    local phys = false; pcall(function() phys = S.car:isPhysicsActive() end)
    return phys
end, function()
    if not S.car then return end
    pcall(function() S.car:repair() end)
    pcall(function() local g = S.car:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
    pcall(function() S.carKey = S.p:getInventory():AddItem(S.car:createVehicleKey()) end)
    pcall(function() S.car:enter(0, S.p); triggerEvent("OnEnterVehicle", S.p) end)
end)
Q.step(20, function() pcall(function() S.car:setKeysInIgnition(true) end) end)
Q.step(15, function() pcall(function() ISVehicleMenu.onStartEngine(S.p) end) end)
Q.step(150, function()
    local run = false; pcall(function() run = S.car:isEngineRunning() end)
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance()
    local vis = false; pcall(function() vis = d ~= nil and d:isReallyVisible() end)
    Q.say("engine running " .. tostring(run) .. ", dash up " .. tostring(vis))
    if run and vis then S.shot("lite_05_dash") else Q.notTaken("lite_05_dash", "engine " .. tostring(run) .. ", dash " .. tostring(vis)) end
end)
Q.step(10, function()
    local v = S.p:getVehicle(); if v then pcall(function() v:exit(S.p) end); triggerEvent("OnExitVehicle", S.p) end
    if S.carKey then pcall(function() S.p:getInventory():Remove(S.carKey) end); S.carKey = nil end
end)
Q.step(30, function()
    if S.car and S.p:getVehicle() ~= S.car then pcall(function() S.car:permanentlyRemove() end) end
    S.car = nil
end)
-- full_10: Full picked the same way, the Loot moment again
S.pickStyle(1, nil)
S.lootMoment("full_10_same")

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    if TU and TU.running() then pcall(TU.stop) end
    if S.kmWin then S.kmWin.listening = nil; pcall(KM.close, S.pn) end
    if S.micro and S.microSq then pcall(function() S.microSq:transmitRemoveItemFromSquare(S.micro) end) end
    local v = S.p:getVehicle(); if v then pcall(function() v:exit(S.p) end); triggerEvent("OnExitVehicle", S.p) end
    if S.car then pcall(function() S.car:permanentlyRemove() end) end
    if S.carKey then pcall(function() S.p:getInventory():Remove(S.carKey) end) end
    S.takeMade()
    G1.shelfBack(Q)
    G1.glassesBack(Q)
end)
Q.step(10, function()
    if St.lookStyleOption:getValue() ~= S.was.style then
        Q.say("Style put back to " .. tostring(S.was.style))
        pcall(function() St.lookStyleOption:setValue(S.was.style); St.lookStyleOption:onChange(S.was.style) end)
        pcall(ZeD.Settings.reapplyFromOptions)
    end
end)
Q.step(20, function()
    S.openPair()
    S.charTab("loot"); S.worldTab("loot")
    pcall(function() S.p:setInvisible(S.was.inv == true); S.p:setGodMod(S.was.god == true); S.p:setZombiesDontAttack(S.was.dda == true) end)
    pcall(function() setGameSpeed((S.was.speed and S.was.speed > 0) and S.was.speed or 1) end)
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Q.say("put back: Style " .. tostring(St.lookStyleOption:getValue()) .. " (was " .. tostring(S.was.style) .. ")")
end)
Q.start()
