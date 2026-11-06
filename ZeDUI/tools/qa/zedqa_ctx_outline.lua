-- ZeDUI/tools/qa/zedqa_ctx_outline.lua  (Nov 6 2026, QA): the right-click menu's highlight on a world object, Build's 30afff9b. The game gives a world item's Grab row no highlight,
-- so a test row carries the game's own (ISWorldObjectContextMenu.initWorldItemHighlightOption, as an animal's and a corpse's rows have): selected, the item lights; closed by the
-- close path a click away takes, by B and by picking the row, it goes dark. Read through the object's isOutlineHighlight. grep "ZEDQA cxo". Pictures: zqa_cxo_*.png.
local function say(s) print("ZEDQA cxo " .. tostring(s)) end
local function check(ok, s) say((ok and "PASS " or "FAIL ") .. s); return ok end
if ZEDQA_HOME then ZEDQA_HOME("cxo") end
local p = getPlayer()
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function zm() local v = getPlayerContextMenu(0); return v and v._zedMenu end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cxo_" .. n:gsub(" ", "_") .. ".png") end) end
local mx, my = math.floor(getCore():getScreenWidth() / 2), math.floor(getCore():getScreenHeight() / 2)
local wo = nil
local function place()
    local sq = getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()) + 1, 0)
    local it = sq and sq:AddWorldInventoryItem("Base.Hammer", 0.5, 0.5, 0)
    wo = it and it:getWorldItem()
    return wo ~= nil
end
local function addRow(player, context, objs)
    local opt = context:addOptionOnTop("QA test row", nil, function() say("the row ran") end)
    ISWorldObjectContextMenu.initWorldItemHighlightOption(opt, wo)
end
local function labelOf(e) return tostring(e and (e.label or e.name or e.text or (e.opt and e.opt.name) or "?")) end
local function rowIndex()
    local m = zm()
    for n, e in ipairs(m and m._ctx and m._ctx.items or {}) do
        if labelOf(e):find("QA test row", 1, true) then return n end
    end
    return nil
end
local function lit()
    if not wo then return false end
    local ok, v = pcall(function() return wo:isOutlineHighlight(0) end)
    if ok then return v == true end
    return false
end
local function case(tag, closeIt)
    add(500, function()
        if not (wo and wo:getSquare()) then place() end
        ISWorldObjectContextMenu.createMenu(0, { wo }, mx, my)
    end)
    add(900, function()
        local m, n = zm(), rowIndex()
        if not check(m ~= nil and n ~= nil, tag .. ": the test row is in the menu") then return end
        m._ctx.selected = n
    end)
    add(900, function()
        check(lit(), tag .. ": selected, the item is lit")
        shot(tag .. "_lit")
        local m = zm()
        if m then closeIt(m) end
    end)
    add(1500, function()
        check(zm() == nil or not zm():isVisible(), tag .. ": the menu is gone")
        check(not lit(), tag .. ": the light is gone")
        shot(tag .. "_closed")
    end)
    add(1500, function() end)
end
add(600, function()
    check(place(), "an item on the ground beside the character")
    Events.OnFillWorldObjectContextMenu.Add(addRow)
end)
case("click away", function(m) m:close() end)
case("B", function(m) m:cancel() end)
case("picking it", function(m) m:confirm() end)
add(500, function()
    Events.OnFillWorldObjectContextMenu.Remove(addRow)
    pcall(function() wo:removeFromWorld(); wo:removeFromSquare() end)
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
