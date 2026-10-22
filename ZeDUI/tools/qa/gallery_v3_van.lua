-- ZeDUI/tools/qa/gallery_v3_van.lua  (Oct 21 2026)
-- Workshop gallery v3, the vanilla half of each comparison: ZeD-UI OFF (the save's
-- mods.txt holds only ZeDQAShim), vanilla UI options at their defaults. After
-- gallery_v3_core.lua (with GAL_FORCE set to the ZeD run's spot), gallery_v3_reveal.lua
-- and gallery_v3_stage.lua, so the scene is the same: same spot, kit, car, bag, zombies.
-- Pictures van_<nn>_<scene>.png in Zomboid/Screenshots, numbered like their ZeD pairs:
--   01-03 inventory + loot (trunk shown) at zoom 1.0 / 0.5 / 1.75   (zed_01-03)
--   10 Protection (clothing) panel  (zed_10 equip doll)   11 Health  (zed_11)
--   12 Skills (zed_12)   13 crafting window (zed_13)   14 world map (zed_14-16)
--   18 / 19 item tooltips food / weapon (zed_18 / 19 cards)   20 context menu (zed_20 / 21)
--   30 HUD: hotbar + clock, zombies near (zed_30)   32 reading progress bar (zed_32)
--   40 / 41 dashboard day / night (zed_40 / 41)
-- Vanilla windows are placed where vanilla places them by default (placeInventoryScreens).
-- Everything opened is shut again. "ZEDQA g3v ..." ending "ZEDQA g3v DONE".
local G = GAL
if not (G and G.spot and G.newSeq) then print("ZEDQA g3v ERR run core and stage first"); print("ZEDQA g3v DONE"); return end
if ZeD and ZeD_CharacterWindow then print("ZEDQA g3v ERR ZeD-UI is loaded: this run is for ZeD off"); print("ZEDQA g3v DONE"); return end
local ONLY = GAL_ONLY
local function want(k) return (not ONLY) or ONLY[k] end
local S = G.newSeq("g3v", 900000)
local say = S.say
local p, pn = G.p, G.pn
local V = { sc = { ok = true, why = "" } }

function V.found(ft)
    local items = G.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
end
-- the two inventory pages open, pinned, at vanilla's default places; the loot page on c
function V.pages(on, c)
    local pi, pl = getPlayerInventory(pn), getPlayerLoot(pn)
    if not (pi and pl) then return false end
    if not on then
        pi:setVisible(false); pl:setVisible(false)
        return true
    end
    local d = getPlayerData(pn)
    pcall(function()
        d:placeInventoryScreens(pn, 1, true)
        pi:setX(d.x1); pi:setY(d.y1); pi:setWidth(d.w1); pi:setHeight(d.h1)
        pl:setX(d.x2); pl:setY(d.y2); pl:setWidth(d.w2); pl:setHeight(d.h2)
    end)
    for _, pg in ipairs({ pi, pl }) do
        pg:setVisible(true)
        pcall(function() pg:setPinned() end)
        pcall(function() pg.isCollapsed = false; pg:setMaxDrawHeight(-1) end)
    end
    if c then pcall(function() pl:setForceSelectedContainer(c, 60000) end) end
    return true
end
function V.info(view)
    local w = getPlayerInfoPanel(pn)
    if not w then return false, "no info panel" end
    if not view then if w:isVisible() then w:close() end; return true end
    if not (w:isVisible() and w.panel:getActiveView() == w.panel:getView(view)) then w:toggleView(view) end
    return true
end
function V.tip(it)
    if V.tipW then pcall(function() V.tipW:removeFromUIManager() end); V.tipW = nil end
    if not it then return true end
    local pi = getPlayerInventory(pn)
    local t = ISToolTipInv:new(it)
    t:initialise()
    t:addToUIManager()
    t:setVisible(true)
    t:setOwner(pi and pi.inventoryPane)
    t:setCharacter(p)
    t.followMouse = false
    local x = pi and (pi:getX() + pi:getWidth() + 10) or 400
    local y = pi and (pi:getY() + 60) or 200
    pcall(function() t:setDesiredPosition(x, y) end)
    t:setX(x); t:setY(y)
    V.tipW = t
    return true
end
function V.setup(fn)
    G.faceFront()
    V.sc.ok, V.sc.why = true, ""
    if not fn then return end
    local ok, a, b = pcall(fn)
    if not ok then V.sc.ok, V.sc.why = false, tostring(a)
    elseif a == false then V.sc.ok, V.sc.why = false, tostring(b or "setup refused") end
end
function V.Sc(name, settle, fn)
    S.step(2, function() V.setup(fn) end)
    S.step(settle or 30, function() if V.sc.ok then S.shot(name) else S.err(name, V.sc.why) end end)
end

S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook()
    G.day()
    G.tp(G.spot.px + 0.5, G.spot.py + 0.5, 0)
    G.openTrunk(G.car)
    say(string.format("vanilla: font size %s, inventory font %s, context font %s, tooltip font %s, moodles %s, sidebar %s",
        tostring(getCore():getOptionFontSize()), tostring(getCore():getOptionInventoryFont()), tostring(getCore():getOptionContextMenuFont()),
        tostring(getCore():getOptionTooltipFont()), tostring(getCore():getOptionMoodleSize()), tostring(getCore():getOptionSidebarSize())))
end)

if want("hero") then
    S.step(30, function() V.pages(true, G.trunk) end)
    S.step(30, function()
        local pi, pl = getPlayerInventory(pn), getPlayerLoot(pn)
        say(string.format("inventory %dx%d at %d,%d | loot %dx%d at %d,%d showing %s", pi:getWidth(), pi:getHeight(), pi:getX(), pi:getY(),
            pl:getWidth(), pl:getHeight(), pl:getX(), pl:getY(), tostring(pl.inventoryPane.inventory and pl.inventoryPane.inventory:getType())))
    end)
    S.zoomTo(1.0)
    V.Sc("van_01_hero_mid", 40)
    S.zoomTo(0.5)
    V.Sc("van_02_hero_close", 40)
    S.zoomTo(1.75)
    V.Sc("van_03_hero_wide", 40)
end
S.zoomTo(1.0)

if want("tabs") then
    S.step(2, function() V.pages(false) end)
    V.Sc("van_10_protection", 45, function() return V.info(xpSystemText.protection) end)
    V.Sc("van_11_health", 45, function() return V.info(xpSystemText.health) end)
    V.Sc("van_12_skills", 45, function() return V.info(xpSystemText.skills) end)
    S.step(2, function() V.info(nil) end)
    V.Sc("van_13_crafting", 90, function() ISEntityUI.OpenHandcraftWindow(p, nil) end)
    S.step(2, function()
        pcall(function()
            if ISEntityUI.IsWindowOpen(pn, "HandcraftWindow") then ISEntityUI.GetWindowInstance(pn, "HandcraftWindow"):close() end
        end)
    end)
    V.Sc("van_14_map", 120, function() ISWorldMap.ShowWorldMap(pn, p:getX(), p:getY(), 15) end)
    S.step(2, function() pcall(function() ISWorldMap.HideWorldMap(pn) end) end)
    S.step(40, function() V.pages(true, G.trunk) end)
    V.Sc("van_18_tooltip_food", 40, function()
        local it = V.found("Base.Apple")
        if not it then return false, "no apple" end
        V.tip(it)
    end)
    V.Sc("van_19_tooltip_weapon", 40, function()
        local it = V.found("Base.Machete")
        if not it then return false, "no machete" end
        V.tip(it)
    end)
    S.step(2, function() V.tip(nil) end)
    V.Sc("van_20_ctx_menu", 30, function()
        local food = V.found("Base.Apple")
        if not food then return false, "no apple" end
        local pi = getPlayerInventory(pn)
        ISInventoryPaneContextMenu.createMenu(pn, true, { food }, pi:getX() + math.floor(pi:getWidth() * 0.42), pi:getY() + math.floor(pi:getHeight() * 0.30))
    end)
    S.step(2, function() pcall(function() getPlayerContextMenu(pn):hideAndChildren() end) end)
    S.step(20, function() end)
end

if want("hud") then
    S.step(2, function() V.pages(false) end)
    S.zoomTo(0.5)
    S.step(2, function()
        G.nearZombies(true)
        pcall(function() p:getStats():set(CharacterStat.HUNGER, 0.3); p:getStats():set(CharacterStat.THIRST, 0.35) end)
    end)
    S.step(90, function() G.faceFront() end)
    V.Sc("van_30_hud_hotbar", 30)
    V.Sc("van_32_action_bar_reading", 90, function()
        local book = V.found("Base.Book")
        if not book then return false, "no book" end
        local ok = pcall(function() ISInventoryPaneContextMenu.readItem(book, pn) end)
        if not ok then ISTimedActionQueue.add(ISReadABook:new(p, book, 150)) end
    end)
    S.step(2, function()
        pcall(function() ISTimedActionQueue.clear(p) end)
        G.nearZombies(false)
        pcall(function() p:getStats():set(CharacterStat.HUNGER, 0); p:getStats():set(CharacterStat.THIRST, 0) end)
    end)
    S.step(30, function() end)
end

if want("car") then
    S.zoomTo(1.0)
    S.step(2, function()
        pcall(function() G.car:enter(0, p) end)
        V.entered = p:getVehicle() ~= nil
        if V.entered then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
    end)
    S.step(30, function() if V.entered then pcall(function() G.car:setKeysInIgnition(true) end) end end)
    local ES = { tries = 0, last = -9999 }
    S.poll(10, 1500, function()
        if not V.entered then return true end
        local run = false
        pcall(function() run = G.car:isEngineRunning() end)
        if run then return true end
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        local busy = q and q.queue and #q.queue > 0
        if not busy and S.tick - ES.last > 120 and ES.tries < 5 then
            ES.tries = ES.tries + 1; ES.last = S.tick
            pcall(function() ISVehicleMenu.onStartEngine(p) end)
        end
        return false
    end)
    S.step(30, function()
        if not V.entered then return end
        pcall(function() ISVehicleMenu.onToggleHeadlights(p) end)
    end)
    S.step(90, function() if V.entered then S.shot("van_40_dash_day") else S.err("van_40_dash_day", "not seated") end end)
    S.step(2, function() if V.entered then G.night() end end)
    S.step(260, function() if V.entered then S.shot("van_41_dash_night") end end)
    S.step(2, function()
        G.dayAgain()
        local v = p:getVehicle()
        if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
    end)
    S.step(40, function() G.tp(G.spot.px + 0.5, G.spot.py + 0.5, 0); G.openTrunk(G.car); G.faceFront() end)
end

S.step(10, function() V.tip(nil); V.info(nil); V.pages(false) end)
S.start()
