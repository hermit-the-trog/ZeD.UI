-- ZeDUI/tools/qa/zedqa_b6a_left.lua  (Nov 7 2026, QA): what beta 6a's QA left untested, on real data with the real mouse (release_check_mouse.ps1 beside it, batch_b6a_left.ps1).
-- 1. the Radio tab: a walkie in the hand (Character window), a ham set placed beside the character (World window): the tab rail and the footer.
-- 2. Journal > Recipes with an item card over it (the Character window has no clip drain): the list, the rail and the footer, card open and after X.
-- 3. a police vest and army boots: their cards at the drawer's own width, with the protection values.
-- 4. a carpentry book half read: its card's Read and Progress.
-- Everything made is taken away. Pictures zqa_b6l_*.png; grep "ZEDQA b6l".
local function say(s) print("ZEDQA b6l " .. tostring(s)) end
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b6l_" .. n .. ".png") end) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function CW() return CWm.getWindow() end
local p = getPlayer()
local inv = p:getInventory()
local made, placed = {}, {}
local handWas = { p:getPrimaryHandItem(), p:getSecondaryHandItem() }
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function state(tag, w)
    w = w or CW()
    local d = w and w._drawerPanel
    local c = w and w._itemCard
    say(tag .. ": tab=" .. tostring(w and w._activeTab) .. " mode=" .. tostring(w and w._drawerMode) .. " card=" .. tostring(w and w._drawerItem and w._drawerItem:getDisplayName())
        .. " cardW=" .. tostring(c and c:isVisible() and math.floor(c:getWidth())) .. " clips=" .. tostring(d and d._zedStencilN) .. " sub=" .. tostring(w and w._journalSubTab))
end
-- the Character window's main list row holding item (or the first row)
local function rowXY(item)
    local w = CW()
    local cc = w and w._mainContent
    if not cc then return nil end
    local first
    for _, z in ipairs(w._focusRing or {}) do
        if tostring(z.zone):find("MainInv", 1, true) then
            for _, e in ipairs(z.elements or {}) do
                if tostring(e.id):find("invrow", 1, true) and type(e.x) == "number" then
                    local x, y = math.floor(cc:getAbsoluteX() + e.x + 120), math.floor(cc:getAbsoluteY() + e.y + (e.h or 20) / 2)
                    first = first or { x, y }
                    if item and (e.item == item or (e.items and e.items[1] == item) or (e.item and e.item.getFullType and e.item:getFullType() == item:getFullType())) then return x, y end
                end
            end
        end
    end
    if item then return nil end
    return first and first[1], first and first[2]
end
local function press(item, tag)
    local x, y = rowXY(item)
    if not x then say("ERR no row for " .. tostring(tag)); return end
    say("press " .. tag .. " at " .. x .. "," .. y); req("left " .. x .. " " .. y)
end
local function closeCard(w)
    w = w or CW()
    if w._drawerItem and w._itemCard then
        local x, y = math.floor(w._itemCard:getAbsoluteX() + 24), math.floor(w._itemCard:getAbsoluteY() + 24)
        say("the card's X at " .. x .. "," .. y); req("left " .. x .. " " .. y)
    end
end
add(500, function() if not CWm.isOpen() then CWm.toggleBothPaired(0) end end)
-- 1. Radio
add(1500, function()
    local wt = inv:AddItem("Base.WalkieTalkie3"); made[#made + 1] = wt
    p:setSecondaryHandItem(nil); p:setPrimaryHandItem(wt)
    local x0, y0, z0 = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for _, d in ipairs({ { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x0 + d[1], y0 + d[2], z0)
        if #placed == 0 and sq and sq:isFree(false) then
            local it = instanceItem("Base.HamRadio2")
            local dv = it and it:getDeviceData()
            if dv then
                local r = IsoRadio.new(getCell(), sq, getSprite("appliances_com_01_8"))
                r:setDeviceData(dv); sq:AddTileObject(r); placed[#placed + 1] = r
            end
        end
    end
    say("walkie in hand " .. tostring(p:getPrimaryHandItem() == wt) .. ", ham set placed " .. tostring(#placed))
end)
add(2500, function() say("char radio tab " .. tostring(CWm.openTab(0, "radio"))) end)
add(2500, function() state("char radio"); shot("01_char_radio") end)
add(1000, function() say("world radio tab " .. tostring(WWm.openTab(0, "radio"))) end)
add(2500, function() state("world radio", WWm.getWindow()); shot("02_world_radio") end)
-- 2. Journal > Recipes under a card
add(1000, function()
    p:setPrimaryHandItem(handWas[1]); p:setSecondaryHandItem(handWas[2])
    WWm.openTab(0, "loot")
    CWm.openTab(0, "journal")
end)
add(2000, function() local w = CW(); if ZeD.JournalTab.switchSub then pcall(ZeD.JournalTab.switchSub, w, 4) end; w._journalSubTab = 4 end)
add(2000, function() state("recipes"); shot("03_recipes"); press(nil, "first row") end)
add(6000, function() state("recipes card"); shot("04_recipes_card"); closeCard() end)
add(6000, function() state("recipes after X"); shot("05_recipes_closed"); req("move 3000 1800") end)
-- 3. clothing cards
local vest, boots, book
add(1500, function()
    CWm.openTab(0, "loot")
    vest = inv:AddItem("Base.Vest_BulletPolice"); boots = inv:AddItem("Base.Shoes_ArmyBoots"); book = inv:AddItem("Base.BookCarpentry1")
    made[#made + 1] = vest; made[#made + 1] = boots; made[#made + 1] = book
    local pages = book and book.getNumberOfPages and book:getNumberOfPages() or 0
    if pages and pages > 0 then p:setAlreadyReadPages("Base.BookCarpentry1", math.floor(pages / 2)) end
    say("vest " .. tostring(vest and vest:getBulletDefense()) .. " bullet, " .. tostring(vest and vest:getBiteDefense()) .. " bite, " .. tostring(vest and vest:getScratchDefense()) .. " scratch; boots "
        .. tostring(boots and boots:getBiteDefense()) .. " bite, " .. tostring(boots and boots:getScratchDefense()) .. " scratch; book pages " .. tostring(pages) .. ", read " .. tostring(p:getAlreadyReadPages("Base.BookCarpentry1")))
end)
add(2500, function() press(vest, "vest") end)
add(6000, function() state("vest card"); shot("06_vest_card"); closeCard() end)
add(6000, function() press(boots, "boots") end)
add(6000, function() state("boots card"); shot("07_boots_card"); closeCard() end)
-- 4. the book
add(6000, function() press(book, "book") end)
add(6000, function() state("book card"); shot("08_book_card"); closeCard() end)
add(6000, function()
    state("all closed"); shot("09_closed"); req("move 3000 1800")
    for _, it in ipairs(made) do local c = it and it:getContainer(); if c then c:Remove(it) end end
    for _, o in ipairs(placed) do local sq = o:getSquare(); if sq then sq:transmitRemoveItemFromSquare(o) end end
    p:setAlreadyReadPages("Base.BookCarpentry1", 0)
    p:setPrimaryHandItem(handWas[1]); p:setSecondaryHandItem(handWas[2])
    say("taken away " .. #made .. " items, " .. #placed .. " sets")
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
say("start")
Events.OnTick.Add(drive)
