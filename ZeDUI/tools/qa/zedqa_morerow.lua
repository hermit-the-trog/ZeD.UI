-- ZeDUI/tools/qa/zedqa_morerow.lua  (Nov 3 2026, QA; Build's aec72d19: the folded "With ..." row wraps in every card)
-- Item cards with a care verb that cannot be done yet (folded into the "With ..." row): a worn baseball bat and a worn
-- hammer (Repair: glue, tape or nails the bag may not hold) and a blunt kitchen knife (Sharpen: a whetstone). Each in the bag, its card opened as a click on its row does
-- (the inventory's selection, then the drawer), and a picture once the window is still. The rect of the Character
-- window is logged for the crops. The items are taken away after. Shots zqa_mrw_<w>x<h>_<item>.png; grep "ZEDQA mrw".
local function say(s) print("ZEDQA mrw " .. tostring(s)) end
local p = getPlayer()
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local function CW() return ZeD_CharacterWindow.getWindow() end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
local made = {}
local function select(item)
    local w = CW()
    local c = w and w._mainContent
    if not (c and w._updateDrawer) then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
local function still()
    local last, same = nil, 0
    return function()
        local w = CW()
        local s = w and string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0)) or ""
        if s == last then same = same + 1 else last, same = s, 0 end
        return same >= 30
    end
end

step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    end)
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
for _, ft in ipairs({ "Base.BaseballBat", "Base.Hammer", "Base.KitchenKnife" }) do
    local it
    step(20, function()
        it = p:getInventory():AddItem(ft)
        if it then
            made[#made + 1] = it
            pcall(function() it:setCondition(math.max(1, math.floor(it:getConditionMax() * 0.3))) end)
            pcall(function() if it.setSharpness then it:setSharpness(0.1) end end)
        end
        pcall(function() ISInventoryPage.dirtyUI() end)
    end)
    step(20, function()
        if not (it and select(it)) then say("ERR " .. ft .. ": no card") end
        pcall(function() Mouse.setXY(sw - 4, sh - 4) end)
    end)
    waitFor(10, 900, still(), function()
        -- the folded row comes after the card's body: scroll the card to its foot (clamped there on its next frame)
        local c = CW() and CW()._itemCard
        if c then c._scrollPixels = 99999 end
    end)
    step(20, function()
        local w = CW()
        local name = ft:gsub("Base%.", "")
        pcall(function() getCore():TakeFullScreenshot("zqa_mrw_" .. sw .. "x" .. sh .. "_" .. name .. ".png") end)
        say(string.format("shot %s: card %s, rect %d %d %d %d, drawer %d", name, tostring(w._drawerItem and w._drawerItem:getDisplayName()),
            w:getAbsoluteX(), w:getAbsoluteY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0)))
    end)
end
step(10, function()
    select(nil)
    for _, it in ipairs(made) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    say("put back: " .. #made .. " items taken away")
end)
step(20, function() say("DONE") end)

local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    if q.cond then
        q.left = (q.left or q.max) - 1
        local ok, done = pcall(q.cond)
        if not (ok and done) and q.left > 0 then return end
        if not (ok and done) then say("WARN step " .. (qi + 1) .. ": waited " .. q.max .. " frames, went on") end
    end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
