-- ZeDUI/tools/qa/gallery_v1_c1_van.lua  (Nov 17 2026, QA): the vanilla half of the ZeD-GUI 1.0 gallery's lived-in
-- retakes, set c1, in the same West Point house as gallery_v1_c1_house.lua (gallery_v1_c1_common.lua's "kitchen" and
-- "living": the same squares, found the same way). ZeD OFF: the runner swaps the QA save's mods.txt "mod = ZeD_UI,"
-- for "mod = ZeDQAShim," (gallery_v1_c1_van.txt). No ZeD calls here. Same content as gallery_v3_van.lua's two
-- pictures, same names:
--   20 Context Menus  van_20_ctx_menu: the game's inventory and loot pages at vanilla's default places and sizes
--                     (placeInventoryScreens), then moved to one side (both on the left when they fit beside the
--                     character, else the inventory on the left edge and the loot on the right edge); an apple's
--                     context menu opened on the inventory page (at 42% across, 30% down, as before). The kitchen.
--   24 Action Bar     van_32_action_bar_reading: the pages shut, zoom 0.5, hungry and thirsty, reading a book: the
--                     game's progress bar over the head. The living room. (Today's two zombies near are left out, as
--                     in the ZeD half.)
-- Also, with the game's own calls only: the prescription glasses on (the QA character is short-sighted) and the
-- game's build line at the bottom right (WaterMarkUI) hidden for every picture.
-- Puts back: the glasses put on, the build line, the pages' places, sizes and visibility, the apple and book given, the stats, the actions, the zoom.
-- The place, the grid power and the cheats: gallery_v1_c1_end.lua. grep "ZEDQA c1v".
if not C1 then print("ZEDQA c1v ERR run gallery_v1_c1_common.lua first"); print("ZEDQA c1v DONE"); return end
local S = C1.make("c1v")
if C1.zed then S.say("ERR ZeD is loaded: this script is for the run with ZeD off"); S.say("DONE"); return end
S.p, S.pn, S.inv = C1.p, C1.pn, C1.p:getInventory()
S.was, S.added = {}, {}

function S.give(ft)
    local it = nil
    pcall(function() it = S.inv:AddItem(ft) end)
    if it then S.added[#S.added + 1] = it end
    return it
end
function S.found(ft)
    local items = S.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
end
function S.pages(on)
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
    return true
end
-- the two pages to one side: both on the left when they fit left of the character, else inventory left, loot right
function S.side(Q)
    local pi, pl = getPlayerInventory(S.pn), getPlayerLoot(S.pn)
    if not (pi and pl and pi:isVisible()) then return end
    local m = C1.margin()
    local r = C1.charRect()
    if m + pi:getWidth() + m + pl:getWidth() + m <= r.x0 then C1.side(Q, { { "inventory", pi, "left" }, { "loot", pl, "left" } })
    else C1.side(Q, { { "inventory", pi, "left" }, { "loot", pl, "right" } }) end
end

-- the short-sighted QA character's prescription glasses, with the game's own calls only (kept on when worn already)
function S.glasses()
    local worn = false
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do if wi:get(i):getItem():getFullType() == "Base.Glasses_Prescription" then worn = true end end
    end)
    local ss = false
    pcall(function() ss = S.p:getCharacterTraits():get(CharacterTrait.SHORT_SIGHTED) == true end)
    if not ss then
        -- prescription glasses blur the world unless the character is short-sighted: any worn pair comes off
        pcall(function()
            local wi = S.p:getWornItems()
            local drop = {}
            for i = 0, wi:size() - 1 do
                local it = wi:get(i):getItem()
                if it and tostring(it:getFullType()):find("Glasses_Prescription", 1, true) then drop[#drop + 1] = it end
            end
            S.was.glassesTaken = S.was.glassesTaken or {}
            for _, it in ipairs(drop) do
                S.was.glassesTaken[#S.was.glassesTaken + 1] = { it = it, loc = it:getBodyLocation() }
                S.p:removeWornItem(it, false)
            end
        end)
        pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
        S.say("short sighted false, prescription glasses off")
        return
    end
    if worn then S.say("short sighted true, prescription glasses on (already worn)"); return end
    pcall(function()
        local g = S.inv:AddItem("Base.Glasses_Prescription")
        local loc = g:getBodyLocation()
        S.was.glasses = { it = g, loc = loc, prev = S.p:getWornItem(loc) }
        S.p:setWornItem(loc, g)
    end)
    S.say("short sighted true, prescription glasses " .. (S.was.glasses ~= nil and "on" or "off"))
end
-- the game's build line (WaterMarkUI, ISVersionWaterMark.lua: "<version> pzBullet(...)") hidden: its panel is found
-- among the top-level UI elements by its Lua type and set invisible; shown again at the end
function S.watermark(hide)
    if hide then
        S.marks = S.marks or {}
        pcall(function()
            local ui = UIManager.getUI()
            for i = 0, ui:size() - 1 do
                local e = ui:get(i)
                local t = e:getTable()
                if t and t.Type == "WaterMarkUI" and e:isVisible() then
                    e:setVisible(false)
                    S.marks[#S.marks + 1] = e
                end
            end
        end)
        return #S.marks
    end
    for _, e in ipairs(S.marks or {}) do pcall(function() e:setVisible(true) end) end
    S.marks = nil
    return 0
end

C1.go(S, "kitchen")
S.step(5, function()
    S.glasses()
    S.say("build line panels hidden: " .. S.watermark(true))
end)
S.step(10, function()
    local pi, pl = getPlayerInventory(S.pn), getPlayerLoot(S.pn)
    S.was.pages = {}
    for _, pg in ipairs({ pi or false, pl or false }) do
        if pg then S.was.pages[#S.was.pages + 1] = { pg = pg, v = pg:getIsVisible(), x = pg:getX(), y = pg:getY(), w = pg:getWidth(), h = pg:getHeight() } end
    end
    C1.grid(true)
    C1.hold, C1.extraBoxes = nil, nil
    S.apple = S.give("Base.Apple")
    S.pages(true)
end)
S.step(20, function() S.side(S); C1.hold = function() S.side(nil); S.watermark(true) end end)
S.mark()
S.still(30, function()
    local pi = getPlayerInventory(S.pn)
    S.menuUp = false
    if not (S.apple and pi) then return end
    ISInventoryPaneContextMenu.createMenu(S.pn, true, { S.apple }, pi:getX() + math.floor(pi:getWidth() * 0.42), pi:getY() + math.floor(pi:getHeight() * 0.30))
    S.menuUp = true
end)
S.step(30, function() if S.menuUp then S.shot("van_20_ctx_menu", { keepMenu = true }) else S.notTaken("van_20_ctx_menu", "no apple or no inventory page") end end)
S.step(2, function() pcall(function() getPlayerContextMenu(S.pn):hideAndChildren() end); C1.hold = nil end)

C1.go(S, "living")
S.step(5, function() S.pages(false); C1.hold = function() S.watermark(true) end end)
S.zoomTo(0.5)
S.step(2, function()
    pcall(function() S.was.hunger = S.p:getStats():get(CharacterStat.HUNGER); S.was.thirst = S.p:getStats():get(CharacterStat.THIRST) end)
    pcall(function() S.p:getStats():set(CharacterStat.HUNGER, 0.3); S.p:getStats():set(CharacterStat.THIRST, 0.35) end)
end)
S.step(60, function()
    C1.face("SE")
    local book = S.found("Base.Book") or S.give("Base.Book")
    S.was.book = book ~= nil
    if not book then return end
    local ok = pcall(function() ISInventoryPaneContextMenu.readItem(book, S.pn) end)
    if not ok then pcall(function() ISTimedActionQueue.add(ISReadABook:new(S.p, book, 150)) end) end
end)
S.step(90, function() if S.was.book then S.shot("van_32_action_bar_reading") else S.notTaken("van_32_action_bar_reading", "no book") end end)
S.step(5, function() pcall(function() ISTimedActionQueue.clear(S.p) end) end)
S.zoomTo(C1.was.zoom or 1.0)

S.mark()
S.step(5, function()
    C1.hold, C1.extraBoxes = nil, nil
    C1.closeMenus()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    pcall(function() S.p:getStats():set(CharacterStat.HUNGER, S.was.hunger or 0); S.p:getStats():set(CharacterStat.THIRST, S.was.thirst or 0) end)
    for _, it in ipairs(S.added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    S.added = {}
    for _, e in ipairs(S.was.pages or {}) do
        pcall(function() e.pg:setX(e.x); e.pg:setY(e.y); e.pg:setWidth(e.w); e.pg:setHeight(e.h); e.pg:setVisible(e.v) end)
    end
    S.watermark(false)
    local g = S.was.glasses
    if g then
        pcall(function() S.p:removeWornItem(g.it, false); S.inv:Remove(g.it) end)
        if g.prev then pcall(function() S.p:setWornItem(g.loc, g.prev) end) end
    end
    for _, t in ipairs(S.was.glassesTaken or {}) do pcall(function() S.p:setWornItem(t.loc, t.it) end) end
    S.say("put back: the pages, the things given, the stats, the actions, the zoom, the build line, the glasses")
end)
S.start()
