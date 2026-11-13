-- ZeDUI/tools/qa/zedqa_fishing_tab.lua  (Nov 2026, punch list 167)
-- In game on the ZeD-QA save: the World window's Fishing tab and its trophy wall, staged and shot.
-- Copy to Zomboid/Lua/zedqa.lua and bump zedqa.go; grep console.txt for "ZEDQA ft"; Screenshots/zqa_ft_*.png.
-- Gives a fishing rod with a worm on the hook and bait in a satchel, equips it, seeds the player's fishing records
-- (a catch log and fourteen trophies; the save's own records are kept aside and put back), opens the World window
-- on the Fishing tab and shoots each state: ready, line in the water and fish on (a stand-in bobber on the game's
-- own fishing manager: the QA site has no water to cast into), no bait, no rod; then the wall on Top 10 and on Each
-- kind with a plaque picked. Then it takes everything back. Run at 4K 1.75x and at the Deck (1280 x 800, Auto).
local p = getPlayer()
local function say(s) print("ZEDQA ft " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ft_" .. n .. ".png") end) end
local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; say("FAIL " .. m) end end
local L, FT = ZeD.FishingLog, ZeD.FishingTab
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end

local given, keepRecords, keepCaught, keepPrim, rod, mgrRod = {}, nil, nil, nil, nil, nil
local function give(ft)
    local it = p:getInventory():AddItem(ft)
    if it then given[#given + 1] = it end
    return it
end
local function win() return ZeD_WorldWindow.getWindow() end
local function st() local w = win(); return w and w._fishTab end
local function mgr() return L.manager(p) end
local function stage(fr) local m = mgr(); if m then m.fishingRod = fr end end
local function stubRod(fish)
    return { rodItem = rod, tensionLimit = 180, highTensionTimer = fish and 80 or 0,
             bobber = { lure = "Base.Worm", fish = fish, getX = function() return p:getX() + 5 end, getY = function() return p:getY() - 4 end },
             getTension = function() return fish and 0.86 or -0.3 end, damageLine = function() end }
end
local function rec(sp, wt, len, d, h)
    return { type = "Base." .. sp, name = "Big " .. getItemNameFromFullType("Base." .. sp) .. " - " .. len .. "cm", wt = wt, len = len,
             yr = 1993, mo = 6, dy = d, hr = h, mn = 12, wa = 0, bait = "Base.Worm", rod = "Fishing Rod", lv = 6, river = (d % 2 == 0), tx = 10840, ty = 9910 }
end

at(2, function()
    local u = UIManager.getUI()
    for i = 0, u:size() - 1 do local e = u:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    keepPrim = p:getPrimaryHandItem()
    local md = p:getModData()
    keepRecords, keepCaught = md[L.KEY], md.fishing_catchedFish
    md[L.KEY] = nil
    md.fishing_catchedFish = { ["Base.Bluegill"] = true, ["Base.LargemouthBass"] = true, ["Base.FreshwaterDrum"] = true,
                               ["Base.ChannelCatfish"] = true, ["Base.SmallmouthBass"] = true, ["Base.YellowPerch"] = true,
                               ["Base.WhiteCrappie"] = true, ["Base.BaitFish"] = true }
    -- the records: fourteen fish, some junk and a No catch, through the same writer a landing uses
    local seed = { { "FreshwaterDrum", 3.85, 68, 26, 17 }, { "LargemouthBass", 2.54, 48, 24, 19 }, { "FreshwaterDrum", 2.34, 49, 24, 18 },
                   { "ChannelCatfish", 1.99, 28, 21, 20 }, { "SmallmouthBass", 1.93, 37, 19, 6 }, { "LargemouthBass", 1.4, 33, 17, 18 },
                   { "Bluegill", 1.21, 19, 15, 5 }, { "ChannelCatfish", 1.08, 21, 25, 6 }, { "SmallmouthBass", 0.97, 26, 26, 18 },
                   { "WhiteCrappie", 0.87, 28, 24, 18 }, { "YellowPerch", 0.8, 27, 25, 5 }, { "BaitFish", 0.05, 9, 25, 5 },
                   { "Bluegill", 0.19, 12, 24, 5 }, { "YellowPerch", 0.32, 19, 24, 5 } }
    for _, s in ipairs(seed) do
        local r = rec(s[1], s[2], s[3], s[4], s[5])
        L.record(p, { kind = "fish", type = r.type, name = r.name, wt = r.wt, len = r.len, bait = r.bait, rod = r.rod, lv = 6,
                      river = r.river, tx = r.tx, ty = r.ty, clock = { yr = 1993, mo = 6, dy = s[4], hr = s[5], mn = 12, wa = L.clock().wa } })
    end
    L.record(p, { kind = "junk", type = "Base.Seaweed", name = getItemNameFromFullType("Base.Seaweed"), wt = 0.1, bait = "Base.Worm" })
    L.record(p, { kind = "gone", bait = "Base.Worm" })
    local d = L.data(p)
    check(#d.top == 10 and d.top[1].wt == 3.85, "seeded: ten on the wall, the drum first")
    -- the tackle
    rod = give("Base.FishingRod")
    rod:getModData().fishing_Lure = "Base.Worm"
    rod:setName(getText(rod:getScriptItem():getDisplayName()) .. " " .. getText("UI_AttachLure_With") .. " " .. getItemNameFromFullType("Base.Worm"))
    local bag = give("Base.Bag_FishingSatchel")
    if bag then for _ = 1, 4 do bag:getItemContainer():AddItem("Base.Worm") end; bag:getItemContainer():AddItem("Base.Cricket") end
    give("Base.JigLure")
    p:setPrimaryHandItem(rod); p:setSecondaryHandItem(rod)
    Fishing.Handler.handleFishing(p, rod)
end)
at(30, function()
    check(L.visible(p), "a rod in hand: the tab shows")
    ZeD_WorldWindow.openTab(0, "fishing")
end)
at(70, function()
    check(ZeD_WorldWindow.isTabShowing("fishing"), "the Fishing tab is open")
    local s = st() and st().s
    check(s and s.state == "ready", "ready (" .. tostring(s and s.state) .. ")")
    shot("1_ready")
    if st() then st().sel = "Base.Cricket" end
end)
at(90, function() shot("1b_ready_cricket_picked"); if st() then st().fold = true end end)
at(110, function() shot("1c_more_detail"); if st() then st().fold = false end; stage(stubRod(nil)) end)
at(140, function()
    local s = st() and st().s
    check(s and s.state == "wait", "line in the water (" .. tostring(s and s.state) .. ")")
    shot("2_wait")
    stage(stubRod({ isTrash = false }))
end)
at(170, function()
    local s = st() and st().s
    check(s and s.state == "fight", "fish on (" .. tostring(s and s.state) .. ")")
    shot("3_fight")
    stage(nil)
    rod:getModData().fishing_Lure = nil
    rod:setName(getText(rod:getScriptItem():getDisplayName()))
    for _, it in ipairs(given) do
        local c = it:getFullType()
        if c == "Base.Bag_FishingSatchel" then it:getItemContainer():removeAllItems() end
        if c == "Base.JigLure" then p:getInventory():Remove(it) end
    end
    -- (the tab reads the bags twice a second; the bait went all at once, so its copy is dropped for the next check)
    if L._resetCarry then L._resetCarry() end
end)
at(200, function()
    local s = st() and st().s
    check(s and s.state == "nobait", "no bait (" .. tostring(s and s.state) .. ")")
    shot("4_nobait")
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
end)
at(230, function()
    local s = st() and st().s
    check(s and s.state == "norod", "no rod in hand (" .. tostring(s and s.state) .. ")")
    shot("5_norod")
    p:setPrimaryHandItem(rod); p:setSecondaryHandItem(rod)
end)
at(260, function() ZeD_WorldWindow.openTab(0, "fishing") end)   -- (the tab hides with no rod in hand and no water near: bring it back)
at(272, function() FT.press(win(), "wall") end)
at(290, function()
    local w = st() and st().wall
    check(w and w.mode == "top" and #(w.plaques or {}) == 10, "the wall: Top 10, ten plaques")
    shot("6_wall_top")
    if w then w.sel = 2 end
end)
at(310, function() shot("6b_wall_top_second") ; if st() then ZeD.FishingWall.setMode(st(), "each") end end)
at(340, function()
    local w = st() and st().wall
    check(w and #(w.plaques or {}) == 21, "the wall: Each kind, 21 plaques")
    shot("7_wall_each")
    if w then w.sel = 3; w.scroll:setScrollPos(1) end
end)
at(370, function() shot("7b_wall_each_bottom"); ZeD.FishingWall.close(win(), st()) end)
at(390, function()
    check(st() and st().wall == nil, "Back returns to the tab")
    shot("8_back")
    -- take it all back
    p:setPrimaryHandItem(keepPrim); p:setSecondaryHandItem(nil)
    for _, it in ipairs(given) do pcall(function() p:getInventory():Remove(it) end) end
    local md = p:getModData()
    md[L.KEY], md.fishing_catchedFish = keepRecords, keepCaught
    pcall(Fishing.Handler.handleFishing, p, keepPrim)
    p:setGodMod(false)
    say("RESULT " .. pass .. " pass, " .. fail .. " fail")
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 400 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
