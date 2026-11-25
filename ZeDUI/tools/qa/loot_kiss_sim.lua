-- ZeDUI/tools/qa/loot_kiss_sim.lua  (Nov 24 2026, Build; QA's loot KISS test, ZeDUI/qa/audits/2026-11-24_kiss_loot.md)
-- The five ZeD bugs QA found in looting:
--   SYNC     ZeD_WorldWindow.syncLootPage / restoreLootPage (cut from the real file): the game's hidden loot page goes on
--            the container the World window shows (the viewed one first), named as the strip names it; with the window
--            shut it goes on the floor (the game drops Put in Container and Move to's loot row for a floor page) and
--            restoreLootPage gives back what it held; nothing changes when it already shows it, or in safe mode
--   MENU     Overrides/ContextMenu.lua: the item menu's build and Put in Container's own run sync the page first
--   DEST     ContainerControls CT.takeDest (cut): the Character window's bag on show, else the main inventory
--   WIRED    the double-click, the card's Grab, pad X on a container's button and the item menu's Loot all use it
--   FLOOR    To floor greys while seated with the window shut and says why (the game's ContextMenu_DropFromVehicle)
--   LITE     Lite keeps Same type and Same type nearby (the game has both)
--   TIP      the worn and held setting's tip says "at the end"
-- Run from the repo root:  lua51 ZeDUI/tools/qa/loot_kiss_sim.lua
-- It prints FAIL lines and a last line "loot_kiss_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]loot_kiss_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = src and string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    return string.sub(src, a, b + #to - 1) .. "\n"
end
local function has(src, s) return src ~= nil and string.find(src, s, 1, true) ~= nil end

local WW = readFile(Z .. "ZeD_WorldWindow.lua") or ""
local CC = readFile(Z .. "ContainerControls.lua") or ""
local CM = readFile(Z .. "Overrides/ContextMenu.lua") or ""
local IM = readFile(Z .. "Overrides/ItemMenu.lua") or ""
local IR = readFile(Z .. "InventoryRenderer.lua") or ""
local IC = readFile(Z .. "ItemCard.lua") or ""
local EN = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
check("SOURCE: files read", #WW > 0 and #CC > 0 and #CM > 0 and #IM > 0 and #IR > 0 and #IC > 0 and #EN > 0)

-- ---------------------------------------------------------------------------
print("-- SYNC: the game's loot page follows the World window")
local FLOOR, CRATE_A, CRATE_B, BODY = { n = "floor" }, { n = "A" }, { n = "B" }, { n = "body" }
local safe, windowsFor = false, true
local page = { inventory = CRATE_B, title = "Crate", inventoryPane = { inventory = CRATE_B, lastinventory = CRATE_B } }
ZeD = { Safe = { on = function() return safe end }, windowsFor = function() return windowsFor end }
ISInventoryPage = { GetFloorContainer = function() return FLOOR end }
getPlayerLoot = function() return page end
local wins = {}
local src = (cut(WW, "function ZeD_WorldWindow.syncLootPage(pn)", "\nend\n") or "")
    .. (cut(WW, "function ZeD_WorldWindow.restoreLootPage(pn, old)", "\nend\n") or "")
check("SYNC: both functions found", has(src, "syncLootPage") and has(src, "restoreLootPage"))
ZeD_WorldWindow = {}
local fn, e = loadstring("local _worldWins = ...\n" .. src, "sync")
check("SYNC: loads", fn ~= nil, e)
if fn then
    fn(wins)
    local W = ZeD_WorldWindow
    wins[0] = { _containers = { { inventory = FLOOR, name = "Floor" }, { inventory = CRATE_A, name = "Crate A" },
                                { inventory = BODY, name = "Corpse" } }, _activeContainer = 2 }
    local old = W.syncLootPage(0)
    check("SYNC: page on the shown crate", page.inventory == CRATE_A and page.inventoryPane.inventory == CRATE_A
        and page.inventoryPane.lastinventory == CRATE_A)
    check("SYNC: the row's name is the strip's", page.title == "Crate A", page.title)
    check("SYNC: old fields kept, window up", old and old.inventory == CRATE_B and old.title == "Crate" and old.open == true)
    check("SYNC: nothing to do when it already shows it", W.syncLootPage(0) == nil)
    wins[0]._viewedContainer = 3
    W.syncLootPage(0)
    check("SYNC: a viewed container wins", page.inventory == BODY and page.title == "Corpse")
    wins[0] = nil
    local o2 = W.syncLootPage(0)
    check("SYNC: window shut, the page on the floor", page.inventory == FLOOR and o2 and o2.open == false)
    W.restoreLootPage(0, o2)
    check("SYNC: restore gives it back", page.inventory == BODY and page.inventoryPane.inventory == BODY and page.title == "Corpse")
    safe = true
    check("SYNC: safe mode leaves the page alone", W.syncLootPage(0) == nil and page.inventory == BODY)
    safe, windowsFor = false, false
    check("SYNC: a player without ZeD's windows is left alone", W.syncLootPage(0) == nil)
end

-- ---------------------------------------------------------------------------
print("-- MENU: the item menu and Put in Container sync first")
local cm = cut(CM, "function ISInventoryPaneContextMenu.createMenu(player, isInInv, items, x, y, origin)", "\nend\n") or ""
local sA, mA = string.find(cm, "syncLootPage", 1, true), string.find(cm, "local menu = origInvCreateMenu", 1, true)
check("MENU: createMenu syncs before the game builds", sA ~= nil and mA ~= nil and sA < mA)
check("MENU: createMenu restores with the window shut", has(cm, "if lootOld and not lootOld.open then W.restoreLootPage(player, lootOld) end"))
check("MENU: onPutItems wrapped", has(CM, "ISInventoryPaneContextMenu.onPutItems = function(items, player)")
    and has(CM, "local origPutItems = ISInventoryPaneContextMenu.onPutItems"))

-- ---------------------------------------------------------------------------
print("-- DEST: where a take lands")
local MAIN, BAG = { n = "main" }, { n = "bag" }
local cc
local charContent = function() return cc end
local dsrc = cut(CC, "function CT.takeDest(playerObj)", "\nend\n")
check("DEST: CT.takeDest found", dsrc ~= nil)
if dsrc then
    local f2, e2 = loadstring("local CT, charContent = ...\n" .. dsrc, "takeDest")
    check("DEST: loads", f2 ~= nil, e2)
    if f2 then
        local CT = {}
        f2(CT, charContent)
        local po = { getPlayerNum = function() return 0 end, getInventory = function() return MAIN end }
        cc = nil
        check("DEST: no Character window, the main inventory", CT.takeDest(po) == MAIN)
        cc = { _ccEntry = true, _inventory = BAG }
        check("DEST: the bag on show", CT.takeDest(po) == BAG)
        cc = { _inventory = BAG }
        check("DEST: a list without its band entry, the main inventory", CT.takeDest(po) == MAIN)
        check("DEST: no player, nil", CT.takeDest(nil) == nil)
    end
end

-- ---------------------------------------------------------------------------
print("-- WIRED: every take goes there")
check("WIRED: double-click", has(IR, "local dest = wear and mainInv or ZeD.ContainerControls.takeDest(playerObj) or mainInv")
    and has(IR, "if src == mainInv or src == dest then")
    and has(IR, "ZeD.ContainerControls.moveItems(playerObj, rows or { item }, dest)"))
check("WIRED: the card's Grab", has(IC, "CT.grabItems(player, items, CT.takeDest and CT.takeDest(player) or player:getInventory())"))
check("WIRED: pad X on a container's button",
    has(WW, "ZeD.ContainerControls.lootAllFrom(w._playerObj, cnt.inventory, ZeD.ContainerControls.takeDest(w._playerObj))"))
check("WIRED: the item menu's Loot all", has(IM, "playerObj, CT.takeAll, src, CT.takeDest(playerObj))"))
check("WIRED: no take left into the main inventory", not has(IM, "CT.takeAll, src, playerObj:getInventory()")
    and not has(IC, "CT.grabItems(player, items, player:getInventory())"))

-- ---------------------------------------------------------------------------
print("-- FLOOR, LITE, TIP")
check("FLOOR: To floor greys with the car window shut",
    has(CC, "enabled = not inv:isEmpty() and not shut,") and has(CC, "local shut = ZeD.InventoryRenderer.carWindowShut(playerObj)"))
check("FLOOR: and says why in the game's words", has(CC, "help = shut and getText(\"ContextMenu_DropFromVehicle\") or nil,"))
check("LITE: Same type and Same type nearby kept", has(CC, "local LITE_DROP = {}"))
check("TIP: at the end", has(EN, "in their own group at the end of the inventory list")
    and not has(EN, "in their own group at the top of the inventory list"))

print("loot_kiss_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
