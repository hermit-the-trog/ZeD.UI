-- ZeDUI/tools/qa/zedqa_cook80.lua  (Nov 3 2026, QA; punch list 80, Build's 8d3b20d8 first cut of the Cooking tab)
-- From the drag strip (ZEDQA_HOME), with the character's own bags as they are: (1) the tab shows with a pot of water,
-- a carrot and a potato on the character and goes when the pot goes; (2) a stew of three vegetables made with Make,
-- one pot of stew holding all three, as by hand; (3) two pots of water and enough for two: the count shows, Make 2;
-- (4) a stir-fry stops at 4, seasoning past the limit, a frozen item greys with the game's words (and a frozen carrot
-- beside a good carrot); (5) a saved dish with an ingredient gone: Use <same kind> (and none with no other);
-- (6) the controller's A and B (add, take out, open a list, pick, shut it). Presses go through the tab's own onClick
-- at a zone's middle, as the window passes a click. Everything made is taken away and the saved dishes put back.
-- Shots zqa_c80_<w>x<h>_*.png; grep "ZEDQA c80".
local function say(s) print("ZEDQA c80 " .. tostring(s)) end
if ZEDQA_HOME then ZEDQA_HOME("c80") end
local p = getPlayer()
local CK = ZeD and ZeD.CookingTab
if not (p and CK) then say("ERR the Cooking tab is not loaded"); say("DONE"); return end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local inv = p:getInventory()
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_c80_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local function CW() return ZeD_CharacterWindow.getWindow() end
local function S() local w = CW(); return w and w._cook end
local function zone(id) local s = S(); return s and s.byId and s.byId[id] end
local function press(id)
    local z, w = zone(id), CW()
    if not (z and w) then say("(no zone " .. id .. ")"); return false end
    CK.onClick(w, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    return true
end
local function plan() local s = S(); return s and s.plan or {} end
local function planFts() local o = {}; for _, e in ipairs(plan()) do o[#o + 1] = e.ft end; return table.concat(o, ", ") end
local function count(ft) local n = 0; pcall(function() n = inv:getCountTypeRecurse(ft) end); return n end
local made = {}
local function add(ft, n)
    local last
    for _ = 1, n or 1 do local it = inv:AddItem(ft); if it then made[#made + 1] = it; last = it end end
    return last
end
local function water(pot) pcall(function() local fc = pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end) end
local function take(ft) for _, it in ipairs(made) do if it:getFullType() == ft and it:getContainer() then it:getContainer():Remove(it) end end end
local function takeAllOf(ft) local l = inv:getAllTypeRecurse(ft); for i = l:size() - 1, 0, -1 do local it = l:get(i); it:getContainer():Remove(it) end end
local function rescan() local s = S(); if s then s.scanAt = -1; s.visAt = nil; s.ingCache = nil end end
local function tabShown() local w = CW(); if not w then return false end; local s = w._cook; if s then s.visAt = nil end; return CK.visible(w) end
local function stripHas()
    local strip = CW() and CW()._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do if z.id == "tab:cooking" then return z end end
    return nil
end
local function idle() return not ISTimedActionQueue.isPlayerDoingAction(p) end
local function drawn() local w, s = CW(), S(); return w and w._activeTab == "cooking" and s and #s.zones > 0 end
local function stews(ft)
    local out, l = {}, inv:getAllTypeRecurse(ft)
    for i = 0, l:size() - 1 do local it = l:get(i); local ex = it:getExtraItems(); out[#out + 1] = { n = ex and ex:size() or 0, name = it:getDisplayName() } end
    return out
end
-- what the tab sees: the bases for the dish and each ingredient's count (and the game's reason)
local function report(tag)
    local s = S(); if not s then return end
    local bl, ing = {}, {}
    for _, o in ipairs((s.bases or {})[s.dish or ""] or {}) do bl[#bl + 1] = o.item:getFullType() .. (o.ok and " ok" or " dry") .. (o.mine and " mine" or "") end
    for ft, g in pairs((s.ingCache and s.ingCache.byFt) or {}) do ing[#ing + 1] = ft .. " x" .. tostring(g.n) .. (g.why and (" (" .. g.why .. ")") or "") end
    say(tag .. ": dish " .. tostring(s.dish) .. ", bases [" .. table.concat(bl, ", ") .. "], in reach [" .. table.concat(ing, ", ") .. "], plan " .. planFts())
end
local mdWas
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
local function openTab()
    -- the strip redraws with the tab a frame or more after the rescan: wait for it, then press it
    step(70, function() rescan() end)
    waitFor(10, 600, function() return stripHas() ~= nil end, function()
        local w = CW()
        if w._activeTab ~= "cooking" then local z = stripHas(); if z then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end end
    end)
    waitFor(10, 600, drawn, function() pcall(function() Mouse.setXY(sw - 4, sh - 4) end) end)
end
-- by the dish's name as the list shows it (Build's b8cd702d keys a dish by the first of the game's recipes with
-- that name: Stew may be StewForged inside)
local function pickDish(un)
    local label = (getTextOrNull and getTextOrNull("ContextMenu_EvolvedRecipe_" .. un)) or un
    local key
    step(20, function() press("cook:dish") end)
    step(20, function()
        local s = S()
        for _, m in ipairs((s and s.dishGeo and s.dishGeo.modes) or {}) do
            if not key and m.label == label and m.id:sub(1, 5) == "dish:" then key = m.id:sub(6) end
        end
        if not (key and press("cook:pop:dish:" .. key)) then say("(no " .. label .. " in the Dish list)"); if s then s.popup = nil end end
    end)
    step(20, function() local s = S(); check(s and key and s.dish == key, "the Dish list picks " .. label .. " (now " .. tostring(s and s.dish) .. ")") end)
end
if getGameSpeed() <= 0 then setGameSpeed(1) end

-- ---- (1) the tab comes and goes with a base on the character
step(120, function()
    local md = p:getModData()
    mdWas = md.ZeD_CookDishes
    md.ZeD_CookDishes = {}
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    say("before: tab shown " .. tostring(tabShown()) .. " (the character's own bags)")
    say("own bags: carrots " .. count("Base.Carrots") .. ", potatoes " .. count("Base.Potato") .. ", cabbage " .. count("Base.Cabbage") .. ", stews " .. count("Base.PotOfStew") .. ", pots " .. count("Base.Pot"))
end)
step(30, function()
    local pot = add("Base.Pot"); water(pot)
    add("Base.Carrots"); add("Base.Potato")
    local amt = nil; pcall(function() amt = pot:getFluidContainer():getAmount() end)
    say("pot water: " .. tostring(amt))
end)
step(90, function() check(tabShown() and stripHas() ~= nil, "a pot of water, a carrot and a potato on the character: the Cooking tab is in the strip") end)
openTab()
step(30, function()
    local s = S()
    check(drawn(), "the Cooking tab opens")
    say("dish " .. tostring(s and s.dish) .. "; dishes: " .. table.concat((s and s.dishList) or {}, ", "))
    shot("1_open")
end)
step(10, function() take("Base.Pot") end)
step(90, function() check(not tabShown(), "the pot taken away: the tab goes (carrot and potato still there)") end)
step(60, function() local w = CW(); check(w and w._activeTab ~= "cooking", "the window leaves the tab when it goes (now " .. tostring(w and w._activeTab) .. ")") end)

-- ---- (2) a stew of three vegetables
step(10, function() local pot = add("Base.Pot"); water(pot); add("Base.Cabbage") end)
openTab()
pickDish("Stew")
step(20, function() press("cook:ing:Base.Carrots") end)
step(20, function() press("cook:ing:Base.Potato") end)
step(20, function() press("cook:ing:Base.Cabbage") end)
step(30, function()
    check(#plan() == 3, "three vegetables in the dish (" .. planFts() .. ")")
    local z = zone("cook:make"); check(z and not z.disabled, "Make is lit")
    check(zone("cook:inc") == nil, "no count for one pot")
    shot("2_stew_plan")
    press("cook:make")
end)
waitFor(30, 3600, function() return idle() and count("Base.PotOfStew") > 0 and count("Base.Potato") == 0 end, function()
    local st = stews("Base.PotOfStew")
    check(#st == 1, "one pot of stew made (" .. #st .. ")")
    check(st[1] and st[1].n == 3, "it holds all three (" .. tostring(st[1] and st[1].n) .. "): " .. tostring(st[1] and st[1].name))
    -- a cabbage is more than one dish takes: the game uses part of it and leaves the rest (as by hand)
    check(count("Base.Carrots") + count("Base.Potato") == 0, "the carrot and the potato went in (cabbage left: " .. count("Base.Cabbage") .. ", part used)")
    check(count("Base.Pot") == 0, "no empty pot left behind")
    shot("2_stew_made")
end)
step(30, function() takeAllOf("Base.PotOfStew") end)

-- ---- (3) two at once
step(10, function()
    takeAllOf("Base.Cabbage")
    local s = S(); if s then s.plan = {} end
    for _ = 1, 2 do local pot = add("Base.Pot"); water(pot) end
    add("Base.Carrots", 2); add("Base.Potato", 2)
end)
openTab()
pickDish("Stew")
step(20, function() press("cook:ing:Base.Carrots") end)
step(20, function() press("cook:ing:Base.Potato") end)
step(30, function()
    report("two pots")
    check(zone("cook:inc") ~= nil, "two pots and enough for two: the count shows")
    press("cook:inc")
end)
step(20, function()
    local s = S(); check(s and s.qty == 2, "the count goes to 2 (" .. tostring(s and s.qty) .. ")")
    press("cook:inc")
end)
step(20, function()
    local s = S(); check(s and s.qty == 2, "and stops at 2 (" .. tostring(s and s.qty) .. ")")
    shot("3_count")
    press("cook:make")
end)
waitFor(30, 3600, function() return idle() and count("Base.PotOfStew") >= 2 and count("Base.Potato") == 0 end, function()
    local st = stews("Base.PotOfStew")
    check(#st == 2, "two pots of stew made (" .. #st .. ")")
    check(st[1] and st[2] and st[1].n == 2 and st[2].n == 2, "each holds a carrot and a potato (" .. tostring(st[1] and st[1].n) .. ", " .. tostring(st[2] and st[2].n) .. ")")
end)
step(30, function() takeAllOf("Base.PotOfStew") end)

-- ---- (4) limits: a stir-fry stops at 4; seasoning past it; frozen
step(10, function()
    add("Base.Pan")
    for _, ft in ipairs({ "Base.Carrots", "Base.Potato", "Base.Cabbage", "Base.Tomato", "Base.Onion", "Base.BellPepper" }) do add(ft) end
    add("Base.Pepper")
    local fz = {}
    for _, ft in ipairs({ "Base.Broccoli", "Base.Carrots" }) do
        local it = add(ft)
        pcall(function() it:setFreezingTime(100) end); pcall(function() it:setFrozen(true) end)
        fz[#fz + 1] = ft .. " frozen " .. tostring(it:isFrozen())
    end
    say(table.concat(fz, "; "))
end)
openTab()
step(10, function() local s = S(); say("dishes now: " .. table.concat((s and s.dishList) or {}, ", ")) end)
pickDish("Stir fry")
for _, ft in ipairs({ "Base.Potato", "Base.Cabbage", "Base.Tomato", "Base.Onion" }) do step(15, function() press("cook:ing:" .. ft) end) end
step(30, function()
    local s = S()
    local b = s and s.bases and s.bases[s.dish] and s.bases[s.dish][s.baseIdx or 1]
    local r = b and b.recipe
    local mx = r and r:getMaxItems()
    local canUse = {}
    pcall(function() local l = r:getItemsCanBeUse(p, b.item, s.containers); for i = 0, l:size() - 1 do local it = l:get(i); canUse[#canUse + 1] = it:getFullType() .. (instanceof(it, "Food") and it:isFrozen() and " frozen" or "") end end)
    local fr = {}
    for _, it in ipairs(made) do if it:getContainer() and instanceof(it, "Food") and it:isFrozen() then fr[#fr + 1] = it:getFullType() end end
    say("stir-fry: recipe " .. tostring(r and r:getUntranslatedName()) .. ", max " .. tostring(mx) .. ", base " .. tostring(b and b.item:getFullType()) .. "; the game offers [" .. table.concat(canUse, ", ") .. "]; frozen now [" .. table.concat(fr, ", ") .. "]")
    report("stir-fry four in")
    check(#plan() == 4, "four in the stir-fry (" .. planFts() .. ")")
    local z = zone("cook:ing:Base.BellPepper"); check(z and z.disabled, "a fifth greys (bell pepper)")
    press("cook:ing:Base.BellPepper")
end)
step(20, function()
    check(#plan() == 4, "a press on it adds nothing")
    -- the game offers no seasoning to a dish not yet begun (Pepper is not in its list; QA, Nov 3): the tab lists none
    check(zone("cook:ing:Base.Pepper") == nil, "no seasoning offered to a new stir-fry (as the game)")
end)
step(20, function()
    check(#plan() == 4, "still four (" .. planFts() .. ")")
    local s = S(); local g = s and s.ingCache and s.ingCache.byFt or {}
    -- the game leaves frozen food out of what it offers (QA, Nov 3): not listed, rather than greyed
    check(g["Base.Broccoli"] == nil, "frozen broccoli is not offered (as the game)")
    local ca = g["Base.Carrots"]
    say("carrots: " .. tostring(ca and ca.n) .. " usable, why " .. tostring(ca and ca.why))
    report("stir-fry full")
    check(ca and ca.n == 1 and not ca.why, "a frozen carrot beside a good one: the good one still goes in")
    shot("4_stirfry_full")
end)
step(10, function() local s = S(); if s then s.sort = "kind" end end)
step(30, function() shot("4_by_kind"); local s = S(); if s then s.sort = "name"; s.plan = {} end end)
step(10, function()
    for _, ft in ipairs({ "Base.Pan", "Base.Carrots", "Base.Potato", "Base.Cabbage", "Base.Tomato", "Base.Onion", "Base.BellPepper", "Base.Pepper", "Base.Broccoli" }) do take(ft) end
end)

-- ---- (5) a saved dish with an ingredient gone
step(10, function() local pot = add("Base.Pot"); water(pot); add("Base.Carrots"); add("Base.Potato"); add("Base.Cabbage") end)
openTab()
pickDish("Stew")
step(20, function() press("cook:ing:Base.Carrots") end)
step(20, function() press("cook:ing:Base.Potato") end)
step(20, function() check(press("cook:save"), "Save is in the band") end)
step(20, function()
    local l = p:getModData().ZeD_CookDishes or {}
    check(#l == 1, "the dish is saved (" .. #l .. ")")
    check(zone("cook:forget") ~= nil, "Save turns to Forget")
    take("Base.Potato")
    local s = S(); if s then s.plan = {} end
end)
step(90, function() rescan() end)
step(20, function() press("cook:dish") end)
step(20, function()
    check(zone("cook:pop:saved:1") ~= nil, "the saved dish heads the Dish list")
    shot("5_dish_list")
    press("cook:pop:saved:1")
end)
step(30, function()
    check(#plan() == 2, "the saved dish loads (" .. planFts() .. ")")
    check(zone("cook:alt:2") ~= nil, "the potato not in reach: Use <same kind> is offered")
    local mk = zone("cook:make"); check(mk and mk.disabled, "Make waits while an ingredient is missing")
    shot("5_use_instead")
    press("cook:alt:2")
end)
step(20, function()
    check(plan()[2] and plan()[2].ft == "Base.Cabbage", "Use takes the cabbage (" .. planFts() .. ")")
    take("Base.Cabbage")
    local s = S(); if s then s.plan = {} end
end)
step(90, function() rescan() end)
step(20, function() press("cook:dish") end)
step(20, function() press("cook:pop:saved:1") end)
step(30, function()
    check(zone("cook:alt:2") == nil, "nothing of the same kind: no Use offered")
    shot("5_not_in_reach")
    press("cook:forget")
end)
step(20, function() local l = p:getModData().ZeD_CookDishes or {}; check(#l == 0, "Forget takes it off the list (" .. #l .. ")") end)

-- ---- (6) the controller: A and B
local function el(id) for _, e in ipairs(CK.buildFocusables(CW())) do if e.id == id then return e end end; return nil end
step(20, function() add("Base.Potato"); local s = S(); if s then s.plan = {} end end)
step(90, function() rescan() end)
step(20, function()
    local e = el("cook:ing:Base.Carrots"); check(e ~= nil, "A on an ingredient: a stop for it")
    if e then e.onActivate() end
end)
step(20, function()
    check(#plan() == 1, "A adds it (" .. planFts() .. ")")
    local e = el("cook:plan:1"); if e then e.onActivate() end
end)
step(20, function()
    check(#plan() == 0, "A on the dish's row takes it out")
    local e = el("cook:sort"); if e then e.onActivate() end
end)
step(20, function()
    local s = S(); check(s and s.popup == "sort", "A on Sort opens its list")
    local only = true
    for _, e in ipairs(CK.buildFocusables(CW())) do
        if not (e.id:sub(1, 9) == "cook:pop:" or e.id == "cook:dish" or e.id == "cook:base" or e.id == "cook:sort") then only = false end
    end
    check(only, "with the list open, only its choices and the boxes are stops")
    local e = el("cook:pop:kind"); if e then e.onActivate() end
end)
step(20, function()
    local s = S(); check(s and s.sort == "kind" and not s.popup, "A picks By category and shuts the list")
    local e = el("cook:dish"); if e then e.onActivate() end
end)
step(20, function()
    local b; for _, e in ipairs(CK.buildFocusables(CW())) do if e.onCancel then b = e end end
    check(b ~= nil and b.onCancel() == true, "B shuts an open list")
end)
step(20, function() local s = S(); check(s and not s.popup, "the list is shut"); shot("6_by_kind_pad") end)

-- ---- put back
step(30, function()
    for _, it in ipairs(made) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    for _, ft in ipairs({ "Base.PotOfStew", "Base.PanFriedVegetables" }) do pcall(takeAllOf, ft) end
    p:getModData().ZeD_CookDishes = mdWas
    local s = S(); if s then s.plan, s.sort, s.popup = {}, "name", nil end
    say("put back: " .. #made .. " items taken away, the saved dishes as they were")
end)
step(30, function() say(string.format("RESULT %d pass, %d fail", passes, fails)); say("DONE") end)

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
