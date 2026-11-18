-- ZeDUI/tools/qa/gallery_v1_a_van.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery, the vanilla half of set A. ZeD OFF
-- (the save's mods.txt holds ZeDQAShim in place of ZeD_UI): only the game's own UI is used (ISInventoryPage through
-- getPlayerInventory / getPlayerLoot, ISCharacterInfoWindow through getPlayerInfoPanel); ZeD is never called.
-- Manifest gallery_v1_a_van.txt: after gallery_story_stage.lua, gallery_unload.lua and gallery_v1_a_common.lua, so the
-- scene is the ZeD run's: Angel at the Fossoil, West Point, the same kit, the same load, the same spots, the same shelf
-- with the same ten things, the same three apples, the same wound. Daylight 11:00.
--   17  g1_17_vanilla   the stock spot (STORY.P.stock): the inventory page (the apple stack open: the game's
--                       expanded group) and the loot page on the shelf, at the game's default places
--                       (placeInventoryScreens), zoom 1.0
--   01  g1_01_vanilla   the same moment at zoom 0.75 (the before-and-after spread; 01 = 17's pair if 17 reads at 116 x 65)
--   26  g1_26_vanilla   the forecourt (STORY.P.smoke): the game's Health panel, a bandaged scratch on the left forearm
-- THE RULE: a page over the character goes to its side (inventory left, loot right, the info window left), logged
-- "moved ..."; every box is logged with "COVERS the character" if one still does.
-- Puts back: the pages' places, sizes and visibility, the info window, the wound, the apples, the shelf; actions and
-- menus cleared (gallery_story_teardown.lua's first step calls ZeD and stops early with ZeD off). grep "ZEDQA g1v".
local S = { was = {} }
local Q = G1 and G1.make and G1.make("g1v")
if not Q then print("ZEDQA g1v ERR run gallery_v1_a_common.lua first"); print("ZEDQA g1v DONE"); return end
if G1.zed or ZeD then Q.say("ERR ZeD is loaded: this script is for the ZeD-off run"); Q.say("DONE"); return end
if not (STORY and STORY.ready and STORY.P) then Q.say("ERR run gallery_story_stage.lua first"); Q.say("DONE"); return end
S.p, S.pn, S.core = G1.p, G1.pn, G1.core
S.P = STORY.P

function S.keep(pg)
    if not pg then return nil end
    return { x = pg:getX(), y = pg:getY(), w = pg:getWidth(), h = pg:getHeight(), vis = pg:isVisible() }
end
function S.back(pg, b)
    if not (pg and b) then return end
    pcall(function() pg:setX(b.x); pg:setY(b.y); pg:setWidth(b.w); pg:setHeight(b.h); pg:setVisible(b.vis) end)
end
-- the two inventory pages at the game's default places, pinned and open; the loot page on c
function S.pages(on, c)
    local pi, pl = getPlayerInventory(S.pn), getPlayerLoot(S.pn)
    if not (pi and pl) then return false end
    if not on then pi:setVisible(false); pl:setVisible(false); return true end
    local d = getPlayerData(S.pn)
    pcall(function()
        d:placeInventoryScreens(S.pn, 1, true)
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
-- the apple group in the inventory page opened (the game's collapsed[name] = false)
function S.openApples(on)
    local pi = getPlayerInventory(S.pn)
    local pane = pi and pi.inventoryPane
    local a = G1.apples and G1.apples[1]
    if not (pane and a) then return nil end
    local name = a:getName()
    pane.collapsed = pane.collapsed or {}
    pane.collapsed[name] = not on
    pcall(function() pane:refreshContainer() end)
    local n = nil
    for _, v in ipairs(pane.itemslist or {}) do
        if v.name == name then n = v.count or (v.items and #v.items) end
    end
    return n, name
end
function S.info(view)
    local w = getPlayerInfoPanel(S.pn)
    if not w then return false end
    if not view then if w:isVisible() then w:close() end; return true end
    if not (w:isVisible() and w.panel:getActiveView() == w.panel:getView(view)) then w:toggleView(view) end
    return true
end

-- ===================================================================== start
Q.step(5, function()
    S.was.pi, S.was.pl = S.keep(getPlayerInventory(S.pn)), S.keep(getPlayerLoot(S.pn))
    pcall(function() local ip = getPlayerInfoPanel(S.pn); S.was.info = S.keep(ip) end)
    pcall(function() S.was.inv = S.p:isInvisible(); S.was.god = S.p:isGodMod(); S.was.dda = S.p:isZombiesDontAttack() end)
    S.was.speed = getGameSpeed()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G1.clean(Q)
    pcall(function() STORY.day(11.0) end)
    Q.say(string.format("start at %d,%d | screen %dx%d | font size %s, inventory font %s, moodles %s",
        math.floor(S.p:getX()), math.floor(S.p:getY()), S.core:getScreenWidth(), S.core:getScreenHeight(),
        tostring(S.core:getOptionFontSize()), tostring(S.core:getOptionInventoryFont()), tostring(S.core:getOptionMoodleSize())))
end)

-- ===================================================================== 17 (and 01) inventory and loot
Q.step(10, function()
    G1.tp(S.P.stock, "SE")
    G1.fillShelf(Q)
    G1.giveApples(Q)
end)
Q.zoomTo(1.0)
Q.step(30, function() S.pages(true, G1.shelf and G1.shelf.inv) end)
Q.step(30, function()
    local n, name = S.openApples(true)
    Q.say("apple group " .. tostring(name) .. " opened: " .. tostring(n))
    local pi, pl = getPlayerInventory(S.pn), getPlayerLoot(S.pn)
    G1.boxes(Q, "default_pages")
    G1.clear(Q, pi, "left", "the inventory page")
    G1.clear(Q, pl, "right", "the loot page")
    Q.say("loot page shows the shelf " .. tostring(G1.shelf ~= nil and pl.inventoryPane.inventory == G1.shelf.inv))
end)
Q.still(10, function()
    S.openApples(true)
    if G1.shelf then Q.shot("g1_17_vanilla") else Q.notTaken("g1_17_vanilla", "no shelf") end
end)
Q.zoomTo(0.75)
Q.step(10, function()
    S.openApples(true)
    G1.clear(Q, getPlayerInventory(S.pn), "left", "the inventory page")
    G1.clear(Q, getPlayerLoot(S.pn), "right", "the loot page")
end)
Q.still(10, function()
    Q.say("01: the same moment as g1_17_vanilla, closer (zoom 0.75); if g1_17 reads at 116 x 65, 01 = 17's pair")
    if G1.shelf then Q.shot("g1_01_vanilla") else Q.notTaken("g1_01_vanilla", "no shelf") end
end)
Q.zoomTo(1.0)
Q.step(5, function()
    S.openApples(false)
    S.pages(false)
    G1.applesBack(Q)
    G1.shelfBack(Q)
end)

-- ===================================================================== 26 the Health panel, a bandaged scratch
Q.step(10, function() G1.tp(S.P.smoke, "SE"); G1.wound(Q, true) end)
Q.step(45, function() S.info(xpSystemText.health) end)
Q.step(30, function()
    local ip = getPlayerInfoPanel(S.pn)
    G1.boxes(Q, "default_info")
    G1.clear(Q, ip, "left", "the info window")
end)
Q.still(10, function()
    local ip = getPlayerInfoPanel(S.pn)
    if ip and ip:isVisible() then Q.shot("g1_26_vanilla") else Q.notTaken("g1_26_vanilla", "the info window did not open") end
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.info(nil)
    G1.wound(Q, false)
    S.openApples(false)
    G1.applesBack(Q)
    G1.shelfBack(Q)
    G1.glassesBack(Q)
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    pcall(function() local m = getPlayerContextMenu(S.pn); if m then m:hideAndChildren() end end)
end)
Q.step(10, function()
    S.back(getPlayerInventory(S.pn), S.was.pi)
    S.back(getPlayerLoot(S.pn), S.was.pl)
    pcall(function() local ip = getPlayerInfoPanel(S.pn); if ip and S.was.info then ip:setX(S.was.info.x); ip:setY(S.was.info.y) end end)
    pcall(function() getPlayerLoot(S.pn):setForceSelectedContainer(nil, 0) end)
    pcall(function() S.p:setInvisible(S.was.inv == true); S.p:setGodMod(S.was.god == true); S.p:setZombiesDontAttack(S.was.dda == true) end)
    pcall(function() setGameSpeed((S.was.speed and S.was.speed > 0) and S.was.speed or 1) end)
    G1.boxes(Q, "put_back")
end)
Q.start()
