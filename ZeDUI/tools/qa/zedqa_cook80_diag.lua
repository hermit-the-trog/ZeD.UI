-- ZeDUI/tools/qa/zedqa_cook80_diag.lua  (Nov 3 2026, QA; punch list 80: why Make leaves the last ingredient out)
-- Logs each ZeD_CookAdd as it is made, checked, started, completed or stopped (the dish it holds, its ingredient,
-- and the game's own two start tests), for one stew of three and then two stews of two; and the count's inputs
-- (the bases the tab sees, how many of each ingredient). The methods are put back after. grep "ZEDQA c8d".
local function say(s) print("ZEDQA c8d " .. tostring(s)) end
if ZEDQA_HOME then ZEDQA_HOME("c8d") end
local p = getPlayer()
local CK = ZeD and ZeD.CookingTab
if not (p and CK and ZeD_CookAdd) then say("ERR the Cooking tab is not loaded"); say("DONE"); return end
local inv = p:getInventory()
local function CW() return ZeD_CharacterWindow.getWindow() end
local function S() local w = CW(); return w and w._cook end
local function zone(id) local s = S(); return s and s.byId and s.byId[id] end
local function press(id)
    local z, w = zone(id), CW()
    if not (z and w) then say("(no zone " .. id .. ")"); return false end
    CK.onClick(w, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    return true
end
local function it2s(it) if not it then return "nil" end; local c = it:getContainer(); return it:getFullType() .. "#" .. tostring(it:getID()) .. (c and (c == inv and "@inv" or "@" .. tostring(c:getType())) or "@gone") end
local made = {}
local function add(ft, n) local last; for _ = 1, n or 1 do local it = inv:AddItem(ft); if it then made[#made + 1] = it; last = it end end; return last end
local function water(pot) pcall(function() local fc = pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end) end
local function stews()
    local out, l = {}, inv:getAllTypeRecurse("Base.PotOfStew")
    for i = 0, l:size() - 1 do local it = l:get(i); local ex = it:getExtraItems(); out[#out + 1] = it2s(it) .. " holds " .. tostring(ex and ex:size() or 0) end
    return #out .. ": " .. table.concat(out, "; ")
end
-- the log on each method
local orig = {}
for _, m in ipairs({ "new", "isValidStart", "isValid", "start", "perform", "complete", "stop" }) do orig[m] = rawget(ZeD_CookAdd, m) end
local function chainOf(a) return a and a.chain and it2s(a.chain.base) or "?" end
ZeD_CookAdd.isValidStart = function(self)
    local r = orig.isValidStart and orig.isValidStart(self) or ISAddItemInRecipe.isValidStart(self)
    local has, can = nil, nil
    pcall(function() has = inv:contains(self.baseItem) end)
    pcall(function() can = self.recipe:getItemsCanBeUse(p, self.baseItem, nil):contains(self.usedItem) end)
    say("isValidStart " .. tostring(r) .. ": dish " .. it2s(self.baseItem) .. " (in bag " .. tostring(has) .. "), adding " .. it2s(self.usedItem) .. " (usable " .. tostring(can) .. ")")
    return r
end
ZeD_CookAdd.start = function(self) say("start: chain " .. chainOf(self) .. ", adding " .. it2s(self.usedItem)); return orig.start(self) end
ZeD_CookAdd.complete = function(self)
    local r = orig.complete(self)
    say("complete -> " .. tostring(r) .. ": chain now " .. chainOf(self) .. "; stews " .. stews())
    return r
end
ZeD_CookAdd.stop = function(self) say("STOP: chain " .. chainOf(self) .. ", adding " .. it2s(self.usedItem)); return ISAddItemInRecipe.stop(self) end
local function restore() for m, f in pairs(orig) do ZeD_CookAdd[m] = f end end

local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
local function stripHas()
    local strip = CW() and CW()._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do if z.id == "tab:cooking" then return z end end
    return nil
end
local function openTab()
    step(10, function() local s = S(); if s then s.scanAt, s.visAt, s.ingCache = -1, nil, nil end end)
    waitFor(10, 600, function() return stripHas() ~= nil end, function()
        local w = CW()
        if w._activeTab ~= "cooking" then local z = stripHas(); if z then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end end
    end)
    waitFor(10, 600, function() local w, s = CW(), S(); return w._activeTab == "cooking" and s and #s.zones > 0 end, function() say("tab open") end)
end
local function report(tag)
    local s = S(); if not s then return end
    local bl = {}
    for _, o in ipairs((s.bases or {})[s.dish or ""] or {}) do bl[#bl + 1] = it2s(o.item) .. (o.ok and " ok" or " dry") .. (o.mine and " mine" or "") end
    local ing = {}
    for ft, g in pairs((s.ingCache and s.ingCache.byFt) or {}) do ing[#ing + 1] = ft .. " x" .. tostring(g.n) .. (g.why and (" (" .. g.why .. ")") or "") end
    say(tag .. ": dish " .. tostring(s.dish) .. ", bases [" .. table.concat(bl, ", ") .. "], in reach [" .. table.concat(ing, ", ") .. "], plan " .. #s.plan
        .. ", count shown " .. tostring(zone("cook:inc") ~= nil) .. ", make " .. tostring(zone("cook:make") and not zone("cook:make").disabled))
end
local function pick(key)
    step(20, function() press("cook:dish") end)
    step(20, function() if not press("cook:pop:dish:" .. key) then local s = S(); if s then s.popup = nil end end end)
end
local function idleLong()
    local n = 0
    return function() if ISTimedActionQueue.isPlayerDoingAction(p) then n = 0 else n = n + 1 end; return n >= 300 end
end

step(120, function()
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    say("before: pots " .. inv:getCountTypeRecurse("Base.Pot") .. ", stews " .. stews())
    local pot = add("Base.Pot"); water(pot); add("Base.Carrots"); add("Base.Potato"); add("Base.Cabbage")
end)
openTab()
pick("Stew")
for _, ft in ipairs({ "Base.Carrots", "Base.Potato", "Base.Cabbage" }) do step(15, function() press("cook:ing:" .. ft) end) end
step(30, function() report("one pot, three in"); say("MAKE 1"); press("cook:make") end)
waitFor(30, 4000, idleLong(), function()
    say("after make 1: stews " .. stews() .. "; carrots " .. inv:getCountTypeRecurse("Base.Carrots") .. ", potatoes " .. inv:getCountTypeRecurse("Base.Potato") .. ", cabbage " .. inv:getCountTypeRecurse("Base.Cabbage"))
    local w = CW(); say("tab after make: " .. tostring(w and w._activeTab))
end)
step(10, function()
    local l = inv:getAllTypeRecurse("Base.PotOfStew"); for i = l:size() - 1, 0, -1 do local it = l:get(i); it:getContainer():Remove(it) end
    for _, ft in ipairs({ "Base.Carrots", "Base.Potato", "Base.Cabbage" }) do local l2 = inv:getAllTypeRecurse(ft); for i = l2:size() - 1, 0, -1 do local it = l2:get(i); it:getContainer():Remove(it) end end
    for _ = 1, 2 do local pot = add("Base.Pot"); water(pot) end
    add("Base.Carrots", 2); add("Base.Potato", 2)
end)
openTab()
pick("Stew")
step(15, function() press("cook:ing:Base.Carrots") end)
step(15, function() press("cook:ing:Base.Potato") end)
step(30, function() report("two pots, carrot and potato") end)
step(10, function() local s = S(); if s then s.qty = 2 end end)
step(10, function() report("count set to 2"); say("MAKE 2"); press("cook:make") end)
waitFor(30, 6000, idleLong(), function()
    say("after make 2: stews " .. stews() .. "; carrots " .. inv:getCountTypeRecurse("Base.Carrots") .. ", potatoes " .. inv:getCountTypeRecurse("Base.Potato") .. ", pots " .. inv:getCountTypeRecurse("Base.Pot"))
end)
step(30, function()
    restore()
    for _, it in ipairs(made) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    local l = inv:getAllTypeRecurse("Base.PotOfStew"); for i = l:size() - 1, 0, -1 do local it = l:get(i); it:getContainer():Remove(it) end
    say("put back: the methods, " .. #made .. " items and the stews taken away")
    say("DONE")
end)

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
