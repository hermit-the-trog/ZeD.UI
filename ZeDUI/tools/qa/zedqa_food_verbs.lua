-- ZeDUI/tools/qa/zedqa_food_verbs.lua  (Oct 24 2026)
-- A food item with a verb of its own (the game's CustomContextMenu: a
-- cigarette is smoked, a juice box drunk): the item card's main button and
-- the action bar say that verb, not Eat / EATING (director, Oct 24 2026:
-- "Seems weird the character would be eating a cig"). A plain apple still
-- says Eat. Run on the deep-run character. grep "ZEDQA fv".
local p = getPlayer()
local pn = p:getPlayerNum()
local AB, IC = ZeD.ActionBar, ZeD.ItemCard
local function say(s) print("ZEDQA fv " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local main = p:getInventory()
local given = {}
local function give(ft) local it = main:AddItem(ft); if it then given[#given + 1] = it end; return it end

local cig, lighter, apple, juice
local function primaryOf(item)
    for _, v in ipairs(IC.headerVerbsForContext("inventory", item) or {}) do if type(v) == "table" and v.primary then return v end end
end

local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
step(10, function()
    pcall(function() p:StopAllActionQueue() end)
    cig, lighter, apple, juice = give("Base.CigaretteSingle"), give("Base.Lighter"), give("Base.Apple"), give("Base.CannedMilkOpen")
    for _, x in ipairs({ { cig, "Smoke" }, { apple, "Eat" }, { juice, "Drink" } }) do
        local v = x[1] and primaryOf(x[1])
        say(tostring(x[1] and x[1]:getDisplayName()) .. ": the card's main button reads " .. tostring(v and v.label) .. " (id " .. tostring(v and v.id) .. ")")
        if x[1] then check(v and v.label == getText("ContextMenu_" .. x[2]), tostring(x[1]:getDisplayName()) .. ": the card says " .. getText("ContextMenu_" .. x[2])) end
    end
    ISInventoryPaneContextMenu.onEatItems({ cig }, 1, pn)
end)
step(90, function()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local a = q and q.queue and q.queue[1]
    local label = a and AB.label(a)
    say("smoking: the action is " .. tostring(a and a.Type) .. ", the bar reads " .. tostring(label))
    check(label == ZeD.tr("UI_ZeD_Act_FoodSmoke"), "smoking: the bar says " .. ZeD.tr("UI_ZeD_Act_FoodSmoke"))
    pcall(function() getCore():TakeFullScreenshot("zqa_fv_smoking.png") end)
    pcall(function() p:StopAllActionQueue() end)
end)
step(10, function()
    ISInventoryPaneContextMenu.onEatItems({ apple }, 0.25, pn)
end)
step(60, function()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local a = q and q.queue and q.queue[1]
    local label = a and AB.label(a)
    say("eating: the action is " .. tostring(a and a.Type) .. ", the bar reads " .. tostring(label))
    check(label == ZeD.tr("UI_ZeD_Act_ISEatFoodAction"), "an apple: the bar still says " .. ZeD.tr("UI_ZeD_Act_ISEatFoodAction"))
    pcall(function() p:StopAllActionQueue() end)
end)
step(10, function()
    for _, it in ipairs(given) do
        if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
        if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
        if it:getContainer() then it:getContainer():Remove(it) end
    end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
