-- ZeDUI/tools/qa/zedqa_pins.lua  (Nov 4 2026, QA; Build's 4a6effe6, title bar pins)
-- In game on the QA save with both windows open (the prelude):
--   1. an old skill pin (ZeD_PinnedSkills) carries over to ZeD_Pins
--   2. items given to the character: a skill book, a water bottle, a drainable, a weapon. Each item's right-click
--      menu (the game's OnFillInventoryObjectContextMenu, the real menu path) has "Pin to title bar"; choosing it pins
--   3. the title bar's text for each kind (P.stats) and its mark colour; picture of the Character window's bar
--   4. three at most: a fourth drops the oldest with a note over the head
--   5. the skill row menu (P.skillMenu) offers Pin / Unpin
--   6. a plain click on a skill row no longer pins (togglePinSkill gone from the click path: checked by the list)
-- Put back: the pins, the items. grep "ZEDQA pin". Pictures zqa_pin_<w>x<h>_<n>.png.
local function say(s) print("ZEDQA pin " .. tostring(s)) end
local P = ZeD.Pins
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_pin_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local p = getPlayer()
local md = p:getModData()
local keep = { pins = md.ZeD_Pins, old = md.ZeD_PinnedSkills }
local items = {}
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function menuPin(it)
    local ctx = ISContextMenu.get(0, 400, 400)
    ctx:clear()
    triggerEvent("OnFillInventoryObjectContextMenu", 0, ctx, { it })
    local found
    for _, o in ipairs(ctx.options or {}) do
        if o.name == ZeD.tr("UI_ZeD_Pin_Pin") or o.name == ZeD.tr("UI_ZeD_Pin_Unpin") then found = o end
    end
    if found and found.onSelect then found.onSelect(found.target, found.param1, found.param2) end
    ctx:setVisible(false)
    return found and found.name
end

-- 1 the old pin carries over
step(30, function()
    md.ZeD_Pins = nil
    md.ZeD_PinnedSkills = { "Carpentry" }
    local L = P.list(p)
    check(#L == 1 and L[1].k == "skill" and L[1].id == "Carpentry" and md.ZeD_PinnedSkills == nil, "an old skill pin carries over to the new list")
    md.ZeD_Pins = {}
end)
-- 2 the items and their menus
step(10, function()
    local inv = p:getInventory()
    for _, t in ipairs({ "Base.BookCarpentry1", "Base.WaterBottle", "Base.Lighter", "Base.Axe" }) do
        local it = inv:AddItem(t)
        items[#items + 1] = it
        say(t .. ": " .. tostring(it and it:getDisplayName()) .. ", kind " .. tostring(it and P.kindOf(it)))
    end
    pcall(function() items[1]:setAlreadyReadPages(math.floor(items[1]:getNumberOfPages() / 3)) end)
    pcall(function() local fc = items[2]:getFluidContainer(); fc:Empty(); fc:addFluid(Fluid.Water, fc:getCapacity() * 0.15) end)
    pcall(function() items[4]:setCondition(math.floor(items[4]:getConditionMax() / 5)) end)
end)
step(10, function()
    local names = {}
    for i = 1, 3 do names[#names + 1] = tostring(menuPin(items[i])) end
    say("menu options chosen: " .. table.concat(names, ", "))
    check(#P.list(p) == 3, "Pin to title bar from each item's right-click menu (3 pinned: " .. #P.list(p) .. ")")
end)
-- 3 the bar's text and marks
step(20, function()
    local T = ZeD.T
    local st = P.stats(p)
    for i, s in ipairs(st) do
        local mark = (s.color == T.accent and "accent") or (s.color == T.info and "info") or (s.color == T.warning and "warning") or (s.color == T.positive and "positive") or (s.color == T.danger and "danger") or "?"
        say("bar " .. i .. ": " .. tostring(s.text) .. " [" .. mark .. "]")
    end
    check(#st == 3, "the title bar shows the three pins")
    check(st[1] and st[1].text:find("/", 1, true) and st[1].color == T.accent, "the book: pages read of total, accent")
    check(st[2] and st[2].text:find(" L", 1, true) and st[2].color == T.warning, "the water bottle: litres, warning under 25%")
    check(st[3] and not st[3].text:find("%%%%") and st[3].text:find("%%"), "the lighter: a percentage with one % sign (" .. tostring(st[3] and st[3].text) .. ")")
end)
step(40, function() shot("1_three_pins") end)
-- 4 a fourth drops the oldest with a note
step(10, function()
    menuPin(items[4])
    local L = P.list(p)
    local B = ZeD.Bubbles
    local note = B and B._notes and B._notes[0] and B._notes[0][#B._notes[0]]
    check(#L == 3 and L[1].id == items[2]:getID() and L[3].id == items[4]:getID(), "a fourth pin drops the oldest (the book)")
    check(note and tostring(note.text):find("3", 1, true) ~= nil, "a note over the head says which came off (" .. tostring(note and note.text) .. ")")
    local st = P.stats(p)
    local T = ZeD.T
    check(st[3] and st[3].color == T.warning, "the axe at a fifth of its condition: warning (" .. tostring(st[3] and st[3].text) .. ")")
end)
step(20, function() shot("2_fourth_drops_oldest") end)
-- 5 the skill row's menu
step(10, function()
    P.skillMenu(0, "Carpentry", "Carpentry", 600, 600)
    local ctx = getPlayerContextMenu and getPlayerContextMenu(0)
    local has = false
    for _, o in ipairs(ctx and ctx.options or {}) do if o.name == ZeD.tr("UI_ZeD_Pin_Pin") then has = true; if o.onSelect then o.onSelect(o.target, o.param1, o.param2) end end end
    check(has, "the skill row's menu offers Pin to title bar")
    check(P.isPinned(p, "skill", "Carpentry"), "choosing it pins the skill")
    if ctx then ctx:setVisible(false) end
end)
step(20, function() shot("3_skill_pinned") end)
step(20, function()
    md.ZeD_Pins = keep.pins
    md.ZeD_PinnedSkills = keep.old
    local inv = p:getInventory()
    for _, it in ipairs(items) do pcall(function() inv:Remove(it) end) end
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then fail = fail + 1; say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
