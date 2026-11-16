-- ZeDUI/tools/qa/zedqa_r1b_icons.lua  (Nov 16 2026, QA): pictures of beta 18's round 1b icons (f246d1502) for the
-- director, in Dark and in Light (ZeD.applyTheme, no option touched): the right-click menu on a bag, a hammer and a
-- carrot and a potato with a kitchen knife carried (Place Item, Put in Container, Favorite, Set Unwanted, Move to,
-- Unusable in Recipes, Drop, Rename; Slice / Chop / Dice / Peel where the game offers them), and the Character wheel
-- (D-pad Left) at rest and with each slice pointed. Each menu's options and each slice's name are printed.
-- Compare with ZeD_design_refs/icons_20261116/round1b/icons_r1b_menu_wheel.png.
-- grep "ZEDQA r1b"; screenshots Screenshots/zqa_r1b_*.png. Puts back: the theme, the given things, the menu and wheel shut.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA r1b " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_r1b_" .. n .. ".png") end); say("shot zqa_r1b_" .. n) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local D, W = ZeD.DpadWheels, ZeD.Wheel
local baseWas, accentWas, sizeWas = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
local inv = p:getInventory()
local gave = {}
local function give(full) local x = inv:AddItem(full); if x then gave[#gave + 1] = x end; return x end

local function zm()
    local m
    pcall(function() m = (ZeD.ContextMenu and ZeD.ContextMenu.current and ZeD.ContextMenu.current(pn)) end)
    if m then return m end
    pcall(function() m = getPlayerContextMenu(pn) end)
    return m
end
local function closeMenu()
    pcall(function() local m = zm(); if m and m.close then m:close() elseif m and m.setVisible then m:setVisible(false) end end)
end
local function listOptions(tag)
    pcall(function()
        local m = getPlayerContextMenu(pn)
        local names = {}
        for _, o in ipairs((m and m.options) or {}) do if o and o.name then names[#names + 1] = tostring(o.name) end end
        say(tag .. " options: " .. table.concat(names, " | "))
    end)
end
local function closeWheel()
    pcall(function()
        local st = D and D.state and D.state[pn]
        if st and st.menu and st.menu.undisplay then st.menu:undisplay() end
        if D and D.state then D.state[pn] = nil end
    end)
    if W then W.qaPoint = nil end
end

local items = {}
step(10, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then pcall(ZeD_CharacterWindow.toggleBothPaired, 0) end
    items.bag = give("Base.Bag_Schoolbag")
    give("Base.Bag_DuffelBag")
    items.hammer = give("Base.Hammer")
    give("Base.KitchenKnife")
    items.carrot = give("Base.Carrot")
    items.potato = give("Base.Potato")
    say("given: bag " .. tostring(items.bag ~= nil) .. ", hammer " .. tostring(items.hammer ~= nil) .. ", carrot " .. tostring(items.carrot ~= nil) .. ", potato " .. tostring(items.potato ~= nil))
end)

local mx, my = math.floor(getCore():getScreenWidth() * 0.42), math.floor(getCore():getScreenHeight() * 0.25)
for _, base in ipairs({ "dark", "light" }) do
    step(10, function() pcall(ZeD.applyTheme, base, accentWas, sizeWas); say("theme " .. tostring(ZeD.currentBase)) end)
    for _, k in ipairs({ "bag", "hammer", "carrot", "potato" }) do
        step(20, function()
            if items[k] then pcall(function() ISInventoryPaneContextMenu.createMenu(pn, true, { items[k] }, mx, my) end) end
        end)
        step(30, function() listOptions(base .. " " .. k); shot(base .. "_menu_" .. k) end)
        step(5, closeMenu)
    end
    -- the Character wheel: at rest, then each slice pointed
    local n = 0
    step(10, function()
        closeWheel()
        pcall(function() ISDPadWheels.onDisplayLeft({ player = pn, id = nil }) end)
    end)
    step(20, function()
        local st = D and D.state and D.state[pn]
        local m = st and st.menu
        local names = {}
        for i, s in ipairs((m and m.slices) or {}) do names[#names + 1] = i .. ":" .. tostring(s.text):gsub("\n", " ") end
        n = #names
        say(base .. " Character wheel slices: " .. table.concat(names, "  "))
        shot(base .. "_wheel_rest")
    end)
    for i = 1, 10 do
        step(12, function() if i <= n and W then W.qaPoint = i end end)
        step(12, function() if i <= n then shot(base .. "_wheel_point_" .. i) end end)
    end
    step(5, closeWheel)
end

step(10, function()
    closeMenu(); closeWheel()
    pcall(ZeD.applyTheme, baseWas, accentWas, sizeWas)
    for _, x in ipairs(gave) do pcall(function() local c = x:getContainer(); if c then c:DoRemoveItem(x) end end) end
    say("put back: theme " .. tostring(ZeD.currentBase) .. "/" .. tostring(ZeD.currentAccent) .. "/" .. tostring(ZeD.currentSize) .. ", given things removed")
    say("DONE")
end)

-- (stepped on each drawn frame: a paused game stops the tick)
local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
