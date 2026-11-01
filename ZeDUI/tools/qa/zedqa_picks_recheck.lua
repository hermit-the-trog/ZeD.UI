-- ZeDUI/tools/qa/zedqa_picks_recheck.lua  (Oct 31 2026, QA; punch list 28, 29, 35 re-built)
-- Run after zedqa_picks_large.lua (Large text) at the small settings. Shots zqa_prc_<what>_<height>.png:
--   Craft: a recipe that can be made once (maxBatchQty 1) and one that can be made 10 or more times (12 cigarette
--     packs given for "Take Cigarette" if none is); for each the band shot, the amount box's pad stop
--     (craft:actQty) present, A / Right / Left on it and the help line.
--   Equip list, Skills (opened by setting the tab when its strip button is scrolled out of reach).
-- Takes back what it gave. grep "ZEDQA prc".
local TEXT = ZEDQA_PICK_TEXT or "small"; ZEDQA_PICK_TEXT = nil
local TAG = TEXT .. "_" .. tostring(getCore():getScreenHeight())
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local p = getPlayer(); local inv = p:getInventory()
local function say(s) print("ZEDQA prc " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_prc_" .. n .. "_" .. TAG .. ".png") end) end
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function zone(w, name) for _, z in ipairs(w._focusRing or {}) do if z.zone == name then return z end end end
local function stop(w, zn, id) local z = zone(w, zn); for _, e in ipairs((z and z.elements) or {}) do if tostring(e.id) == id then return e end end end
-- a tab by its strip button, else by setting it (a button scrolled out of the strip has no zone)
local function tab(win, key, id)
    local s = win and win[key]
    for _, z in ipairs((s and s._hitZones) or {}) do
        if z.id == "tab:" .. id then if win._activeTab ~= id then s:onMouseDown(z.x + 2, z.y + 2) end; return "button" end
    end
    win._activeTab = id; win._drawerMode = "tab"; win._drawerOpen = true
    return "set"
end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local sizeWas = ZeD.currentSize
local given = {}
local picks = {}
step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
    if TEXT == "large" then ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, "large") end
    for _ = 1, 12 do local it = inv:AddItem("Base.CigarettePack"); if it then given[#given + 1] = it end end
end)
step(40, function() pcall(ZeD_Window.resetLayout); tab(WW(), "_actionTabStrip", "craft") end)
-- each recipe opened in turn until one that can be made once and one that can be made 10 or more times are found
-- (the most is worked out while a recipe is open: state._maxQty)
local list, found = {}, {}
step(30, function()
    local data = ZeD.CraftingTab.gatherData(p, WW())
    for _, rd in ipairs(data and data.recipes or {}) do list[#list + 1] = rd end
    say("recipes to try: " .. #list)
end)
for k = 1, 25 do
    step(3, function()
        local rd = list[k]
        if rd and not (found.one and found.many) then ZeD.CraftingCore.openCraft(WW()._craftState, rd.entry.name) end
    end)
    step(12, function()
        local rd = list[k]
        if not rd or (found.one and found.many) then return end
        local m = WW()._craftState._maxQty
        if m == 1 and not found.one then found.one = rd end
        if m and m >= 10 and not found.many then found.many = rd end
    end)
end
step(5, function()
    pcall(function() ZeD.CraftingCore.closeCraft(WW()._craftState) end)
    say("recipes: once " .. tostring(found.one and found.one.entry.name) .. ", 10 or more " .. tostring(found.many and found.many.entry.name))
    picks = { { "max1", found.one }, { "max10", found.many } }
end)
local function craftPass(i)
    step(5, function()
        local pk = picks[i]
        if pk and pk[2] then ZeD.CraftingCore.openCraft(WW()._craftState, pk[2].entry.name) end
    end)
    step(60, function()
        local pk = picks[i]
        if not (pk and pk[2]) then say("no recipe for " .. tostring(pk and pk[1])); return end
        local st, w = WW()._craftState, WW()
        local qb = st._qtyBox
        shot("craft_" .. pk[1])
        local e = stop(w, "worldTabContent", "craft:actQty")
        say(string.format("%s: one box %s, max %s, stop %s", pk[1], tostring(qb and qb.on), tostring(st._maxQty), tostring(e ~= nil)))
        if qb and qb.on then
            check(e ~= nil, pk[1] .. ": the amount box is a pad stop")
            if e then
                st.qty = 1
                e.onActivate(w, e); local a = st.qty
                local r = e.onDpadDir(w, e, "right"); local b = st.qty
                local l = e.onDpadDir(w, e, "left"); local c = st.qty
                say(string.format("%s: A 1->%s, Right ->%s (%s), Left ->%s (%s)", pk[1], tostring(a), tostring(b), tostring(r), tostring(c), tostring(l)))
                if (st._maxQty or 1) <= 1 then
                    check(a == 1 and r == false and l == false, pk[1] .. ": at most one: A does nothing, Left / Right move on")
                else
                    check(a == 2 and b == 3 and c == 2, pk[1] .. ": A up, Right up, Left down")
                end
                st.qty = 1
                pcall(function() if e.onFocus then e.onFocus(w, e) end end)
                say(pk[1] .. ": help line '" .. tostring(w._helpText) .. "'")
            end
        end
        pcall(function() ZeD.CraftingCore.closeCraft(st) end)
    end)
end
craftPass(1); craftPass(2)
step(5, function() tab(WW(), "_actionTabStrip", "loot"); ZeD.EquipDoll.setView("list"); tab(CW(), "_tabStripPanel", "equip") end)
step(40, function() shot("equip") end)
step(5, function() say("skills opened by " .. tab(CW(), "_tabStripPanel", "skills")) end)
step(40, function() say("skills showing: " .. tostring(CW()._activeTab)); shot("skills") end)
step(5, function()
    for _, it in ipairs(given) do local c = it:getContainer(); if c then pcall(function() c:Remove(it) end) end end
    tab(CW(), "_tabStripPanel", "loot")
    if TEXT == "large" then ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, sizeWas) end
end)
step(20, function() say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE") end)

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
say("start " .. TAG)
