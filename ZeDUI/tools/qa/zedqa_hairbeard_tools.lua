-- ZeDUI/tools/qa/zedqa_hairbeard_tools.lua  (Nov 2 2026, QA; punch list 54)
-- Hair and beard's tool reading (ZeD_HairBeard.lua tools() and the stand-in inventory the game's style menus ask):
-- with long hair and a full beard, the character's own tools put aside, then five cases one after another:
--   none, a razor inside a bag, scissors in the main inventory, hair gel, hair spray.
-- For each: the tools Hair and beard found (st.tools), and whether a shave, a cut, a gel / spray style and a beard trim
-- can be done (each row's ok), against what the game's own rules say (a razor or scissors shaves and trims, scissors
-- cut, gel or spray style). Then, with the razor in the bag, a beard trim picked from the list starts the game's trim
-- on the player (ISTrimBeard in the player's queue), and is cleared.
-- This script reads the inventory by its own walk (no predicate searches). Everything is put back.
-- grep "ZEDQA hbt"; shots zqa_hbt_<case>.png.
local function say(s) print("ZEDQA hbt " .. tostring(s)) end
local p = getPlayer()
local HB = ZeD and ZeD.HairBeard
local CW = ZeD_CharacterWindow
if not (p and HB and CW) then say("ERR Hair and beard is not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_hbt_" .. n .. ".png") end) end
local function win() return CW.getWindow() end
local function st() local w = win(); return w and w._hb end
local function refresh() local s = st(); if s then s.tick = 999 end end

local female = p:isFemale()
local hv = p:getHumanVisual()
local orig = { hair = hv:getHairModel(), beard = hv:getBeardModel(), na = hv:getNonAttachedHair() }
local TOOL = { Razor = true, Scissors = true, Hairgel = true, Hairspray2 = true }
local function isTool(it)
    return TOOL[it:getType()] or it:hasTag(ItemTag.RAZOR) or it:hasTag(ItemTag.SCISSORS) or it:hasTag(ItemTag.DO_HAIRDO)
end
-- every item in the inventory and its bags, by walking (no Eval search)
local function walk(inv, out, depth)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        out[#out + 1] = it
        if depth < 6 and instanceof(it, "InventoryContainer") then walk(it:getInventory(), out, depth + 1) end
    end
    return out
end
local taken, given = {}, {}
local function putAside()
    for _, it in ipairs(walk(p:getInventory(), {}, 0)) do
        if isTool(it) then
            local c = it:getContainer()
            if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
            if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
            if c then c:Remove(it); taken[#taken + 1] = { it = it, c = c } end
        end
    end
end
local function clearGiven()
    for _, g in ipairs(given) do pcall(function() g.c:Remove(g.it) end) end
    given = {}
end
local function give(ft, inBag)
    local c = p:getInventory()
    if inBag then
        local bag = c:AddItem("Base.Bag_Schoolbag")
        given[#given + 1] = { it = bag, c = c }
        c = bag:getInventory()
    end
    local it = c:AddItem(ft)
    if it and not inBag then given[#given + 1] = { it = it, c = c } end
    return it
end
local function rowsOf(part)
    local s = st()
    local b = s and s.byPart and s.byPart[part]
    return b and b.rows or {}
end
-- the first row matching, and whether any of that kind can be done
local function anyOk(part, fn)
    local seen, ok = false, false
    for _, r in ipairs(rowsOf(part)) do if fn(r) then seen = true; if r.ok then ok = true end end end
    return seen, ok
end
local function report(label)
    local s = st()
    local t = s and s.tools or {}
    local found = {}
    for _, k in ipairs({ "razor", "scissors", "gel", "spray", "hairdo" }) do if t[k] then found[#found + 1] = k end end
    local shS, shO = anyOk("hair", function(r) return r.style == "Bald" end)
    local cuS, cuO = anyOk("hair", function(r) return r.req == "s" end)
    local gS, gO = anyOk("hair", function(r) return r.req == "g" or r.req == "gs" end)
    local spS, spO = anyOk("hair", function(r) return r.req == "sp" or r.req == "gs" end)
    local trS, trO = anyOk("beard", function(r) return r.kind == "beard" end)
    say(label .. ": tools found {" .. table.concat(found, ",") .. "} | shave " .. tostring(shS and shO) .. " | cut " .. tostring(cuS and cuO)
        .. " | gel style " .. tostring(gS and gO) .. " | spray style " .. tostring(spS and spO) .. " | beard " .. tostring(trS and trO)
        .. " | rows hair " .. #rowsOf("hair") .. " beard " .. #rowsOf("beard"))
    return { t = t, shave = shS and shO, shaveSeen = shS, cut = cuS and cuO, cutSeen = cuS, gel = gS and gO, gelSeen = gS,
             spray = spS and spO, spraySeen = spS, beard = trS and trO, beardSeen = trS }
end

local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CW.isOpen() and ZeD_WorldWindow.isOpen()) then CW.toggleBothPaired(0) end
end)
step(30, function()
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:identity" and w._activeTab ~= "identity" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
    putAside()
    say("tools put aside: " .. #taken .. " | female " .. tostring(female))
    hv:setNonAttachedHair(nil)
    hv:setHairModel(female and "Long2" or "Fabian")
    if not female then hv:setBeardModel("Full") end
    p:resetModel()
    w._identityCache = nil
    refresh()
end)
local CASES = {
    { "none" },
    { "razor_in_bag", "Base.Razor", true },
    { "scissors", "Base.Scissors" },
    { "gel", "Base.Hairgel" },
    { "spray", "Base.Hairspray2" },
}
for _, c in ipairs(CASES) do
    step(10, function()
        clearGiven()
        if c[2] then give(c[2], c[3]) end
        refresh()
    end)
    step(40, function()
        local r = report(c[1])
        local t = r.t
        if c[1] == "none" then
            check(next(t) == nil, "none: no tool found")
            check(not r.shave and not r.cut and not r.gel and not r.spray, "none: no shave, cut or style can be done")
            if not female then check(r.beardSeen and not r.beard, "none: no beard trim can be done") end
        elseif c[1] == "razor_in_bag" then
            check(t.razor ~= nil and t.scissors == nil, "razor in a bag: the razor is found")
            check(r.shaveSeen and r.shave, "razor in a bag: a shave can be done")
            check(r.cutSeen and not r.cut, "razor in a bag: a cut still needs scissors")
            if not female then check(r.beard, "razor in a bag: a beard trim can be done") end
        elseif c[1] == "scissors" then
            check(t.scissors ~= nil and t.razor == nil, "scissors: found")
            check(r.cut, "scissors: a cut can be done")
            check(r.shave, "scissors: a shave can be done (razor or scissors)")
        elseif c[1] == "gel" then
            check(t.gel ~= nil and t.hairdo ~= nil, "gel: found (and counts as a hairdo tool)")
            check(not r.gelSeen or r.gel, "gel: a gel style can be done" .. (r.gelSeen and "" or " (no gel style in the list)"))
            check(not r.cut, "gel: a cut still needs scissors")
        elseif c[1] == "spray" then
            check(t.spray ~= nil and t.hairdo ~= nil, "spray: found (and counts as a hairdo tool)")
            check(not r.spraySeen or r.spray, "spray: a spray style can be done" .. (r.spraySeen and "" or " (no spray style in the list)"))
        end
        shot(c[1])
    end)
end
-- a pick: the razor in the bag, a beard trim from the list starts the game's trim on the player
step(10, function() clearGiven(); give("Base.Razor", true); refresh() end)
step(40, function()
    if female then say("NOTE the character is female: no beard to trim; the pick is not tried"); return end
    local w, s = win(), st()
    HB.setPart(w, "beard")
    local pick
    for _, r in ipairs(rowsOf("beard")) do if r.ok and r.style ~= "" then pick = r; break end end
    if not check(pick ~= nil, "a beard trim row can be picked") then return end
    local ok = HB.run(w, pick.key)
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local a = q and q.queue and q.queue[1]
    say("picked " .. tostring(pick.key) .. ": run " .. tostring(ok) .. " | first action " .. tostring(a and a.Type) .. " on " .. tostring(a and a.character))
    check(ok and a ~= nil and a.character == p, "the trim starts the game's action on the player (" .. tostring(a and a.Type) .. ")")
    pcall(ISTimedActionQueue.clear, p)
    HB.setPart(w, "hair")
end)
-- put back
step(10, function()
    clearGiven()
    for _, t in ipairs(taken) do pcall(function() t.c:AddItem(t.it) end) end
    hv:setNonAttachedHair(orig.na)
    hv:setHairModel(orig.hair)
    if not female then hv:setBeardModel(orig.beard) end
    p:resetModel()
    local w = win(); if w then w._identityCache = nil end
    refresh()
end)
step(20, function()
    say("put back: " .. #taken .. " tools, the look " .. tostring(hv:getHairModel()) .. " / " .. tostring(hv:getBeardModel()))
    say("summary: " .. passes .. " PASS, " .. fails .. " FAIL")
    say("DONE")
end)

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
say("start")
