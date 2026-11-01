-- ZeDUI/tools/qa/zedqa_isearch.lua  (Oct 31 2026, QA; punch list 40, Immersive Searching 3760450908)
-- Runs with ZeD on (zedqa_mods_run.ps1) and ZeD off (zedqa_off_run.ps1, the probe mod). A duffel bag with six
-- things in it is put on the floor beside the character; then:
--   1. the bag before any search: Immersive Searching says unsearched; what the loot list shows
--      (vanilla's pane list, and with ZeD the World window's own list); the bag's button icon (its "?" texture);
--   2. ZeD on only: the bag picked in ZeD's World window (ZeD_WorldWindow.selectContainer): does a search start?
--   3. the bag picked the vanilla way (ISInventoryPage:selectContainer, what a click in the loot window does):
--      the search starts; shots mid-search and when done; searched afterwards;
--   4. Take all / Transfer buttons (the loot window handlers) while unsearched, and the search key / the
--      "search all" path when the sandbox has it.
-- Takes the bag away afterwards. Shots zqa_is_<zed|off>_<what>.png. grep "ZEDQA is".
local p = getPlayer(); local pn = p:getPlayerNum()
local ZED = ZeD_WorldWindow ~= nil
local TAG = ZED and "zed" or "off"
local IS = ImmersiveSearching
local function say(s) print("ZEDQA is " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_is_" .. TAG .. "_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local bagItem, bagInv, worldObj
local function vanillaList()
    local loot = getPlayerLoot(pn)
    local pane = loot and loot.inventoryPane
    local n = 0
    for _, v in ipairs((pane and pane.itemslist) or {}) do n = n + (v.count and (v.count - 1) or 1) end
    return tostring(pane and pane.inventory == bagInv) .. " (" .. n .. " things listed)"
end
local function zedList()
    if not ZED then return "-" end
    local w = ZeD_WorldWindow.getWindow()
    if not w then return "no window" end
    local c = (w._containers or {})[w._activeContainer or 0]
    local shown = c and c.inventory == bagInv
    return "bag active " .. tostring(shown) .. ", ZeD reads " .. tostring(shown and bagInv:getItems():size()) .. " things"
end
local function button()
    local loot = getPlayerLoot(pn)
    for _, b in ipairs((loot and loot.backpacks) or {}) do
        if b.inventory == bagInv then return b end
    end
end
local function queue()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local names = {}
    for _, a in ipairs((q and q.queue) or {}) do names[#names + 1] = tostring(a.Type) end
    return table.concat(names, " ")
end
local function state(label)
    local b = button()
    say(string.format("%s: searched %s; vanilla pane on bag %s; %s; button %s, ? icon %s; queue [%s]", label,
        tostring(IS and IS.isSearched(p, bagInv)), vanillaList(), zedList(), tostring(b ~= nil),
        tostring(b and b.textureOverride ~= nil), queue()))
end

step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("Immersive Searching loaded " .. tostring(IS ~= nil) .. ", ZeD " .. tostring(ZED) .. ", sandbox SearchAll "
        .. tostring(SandboxVars.ImmersiveSearching and SandboxVars.ImmersiveSearching.SearchAll))
    if ZED and not (ZeD_CharacterWindow.isOpen() and ZeD_WorldWindow.isOpen()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    if not ZED then
        local inv, loot = getPlayerInventory(pn), getPlayerLoot(pn)
        if inv then inv:setVisible(true) end
        if loot then loot:setVisible(true); loot.isCollapsed = false end
    end
    local sq = p:getCurrentSquare()
    worldObj = nil
    pcall(function() bagItem = sq:AddWorldInventoryItem("Base.Bag_DuffelBag", 0.5, 0.5, 0) end)
    if bagItem then
        bagInv = bagItem:getInventory()
        for _, t in ipairs({ "Base.Hammer", "Base.TinnedBeans", "Base.WaterBottle", "Base.Socks_Ankle", "Base.Pencil", "Base.Battery" }) do
            pcall(function() bagInv:AddItem(t) end)
        end
        worldObj = bagItem:getWorldItem()
    end
    say("bag " .. tostring(bagItem ~= nil) .. ", things in it " .. tostring(bagInv and bagInv:getItems():size()))
end)
step(60, function()
    if not bagInv then return end
    pcall(function() ISInventoryPage.dirtyUI() end)
end)
step(30, function() state("1 before any search"); shot("1_before") end)
-- 2. ZeD's own pick
step(2, function()
    if not (ZED and bagInv) then return end
    say("2 ZeD selectContainer -> " .. tostring(ZeD_WorldWindow.selectContainer(bagInv, 90)))
end)
step(40, function() if ZED then state("2 after ZeD's pick"); shot("2_zed_pick") end end)
-- 3. the vanilla pick
step(2, function()
    if ISTimedActionQueue.getTimedActionQueue(p) and #queue() > 0 then say("3 a search already runs; waiting") return end
    local loot, b = getPlayerLoot(pn), button()
    if loot and b then loot:selectContainer(b); say("3 vanilla selectContainer called") else say("3 no loot button for the bag") end
end)
step(25, function() state("3 mid-search"); shot("3_mid") end)
step(400, function() state("3 after the search"); shot("3_after") end)
-- 4. after: the loot window's handlers ask again (shouldBeVisible)
step(5, function()
    local vis = {}
    for _, h in ipairs({ "ISLootWindowObjectControlHandler_TakeAll", "ISInventoryWindowControlHandler_TransferAll" }) do
        local cls = _G[h]
        if cls and cls.new then
            local ok, o = pcall(function() local o = cls:new(); o.container = bagInv; o.playerObj = p; o.playerNum = pn; return o end)
            local ok2, v = pcall(function() return o:shouldBeVisible() end)
            vis[#vis + 1] = h:gsub("ISLootWindowObjectControlHandler_", ""):gsub("ISInventoryWindowControlHandler_", "") .. "=" .. tostring(ok2 and v)
        end
    end
    say("4 handlers after search: " .. table.concat(vis, " "))
end)
step(10, function()
    if bagItem then
        local sq = bagItem:getWorldItem() and bagItem:getWorldItem():getSquare()
        pcall(function() sq:transmitRemoveItemFromSquare(bagItem:getWorldItem()) end)
        pcall(function() bagItem:getWorldItem():removeFromSquare() end)
    end
    pcall(function() ISInventoryPage.dirtyUI() end)
    say("bag taken away")
end)
step(20, function() say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start " .. TAG)
