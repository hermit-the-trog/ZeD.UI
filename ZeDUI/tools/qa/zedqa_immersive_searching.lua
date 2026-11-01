-- ZeDUI/tools/qa/zedqa_immersive_searching.lua  (Nov 1 2026, punch list 40)
-- Immersive Searching [B42MP] (Workshop 3760450908) support:
-- ModSupport/ImmersiveSearching.lua through ContainerGates.lua, the strip decorators and the band's provider.
-- Runs two ways:
--   * the mod ON (the compat rig): zedqa_mods_run.ps1 -ModList isearch_mods.txt -Mode fullscreen4k
--     -Manifest isearch_manifest.txt (mods: ImmersiveSearching; ZeD_UI as always). Three duffel bags go on the
--     floor beside the character (A: six things, B: two, C: one), then:
--       1. the "?" chip on each bag's World strip button (the support's stamp and win._stripDecorated);
--       2. bag A before any search: the gate says unsearched, refuses things, lists 0, the empty line
--          "Not searched.", the weight line "Not searched"; a move into it (ContainerControls.moveItems) queues
--          nothing (the mod's hasRoomFor rule);
--       3. bag A picked in ZeD's World window: the mod's search is queued (S.lastStart how=pick, the queue holds
--          ImmersiveSearching_ISSearch for A);
--       4. during the search, every few ticks: the band's moves are left out (no Take all), the band's bar
--          (gate band.progress) rises, the list's count rises one by one and always equals what the mod has
--          revealed (ImmersiveSearching.Items[A].Searched); shot mid-search;
--       5. after: searched, no gate, all six listed, the "?" gone, Take all back in the band;
--       6. Search all: with the sandbox's SearchAll off (1) no "Search all" button; set to 2 for the run, the
--          button shows in A's band (B and C unsearched); pressed: searches for B and C queued; then done; the
--          sandbox value put back;
--   * the mod OFF (the default regression run): nothing changes: no gate, no pick hook, no decorator or band
--     provider for the mod, bag A lists six things, Take all shows, picking A queues nothing.
-- Takes the bags away and empties the action queue afterwards. Shots zqa_iss_<on|off>_<what>.png.
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA iss"; ends "ZEDQA iss DONE".
local p = getPlayer()
local pn = p:getPlayerNum()
local IS = ImmersiveSearching
local S = ZeD.ModSupport and ZeD.ModSupport.ImmersiveSearching
local G = ZeD.ContainerGates
local CT = ZeD.ContainerControls
local ON = S ~= nil and IS ~= nil
local TAG = ON and "on" or "off"
local ID = "ImmersiveSearching"
local function say(s) print("ZEDQA iss " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_iss_" .. TAG .. "_" .. n .. ".png") end) end
local function ww() return ZeD_WorldWindow.getWindow() end
local fails = 0
local function check(label, ok, detail)
    if not ok then fails = fails + 1 end
    say((ok and "PASS " or "FAIL ") .. label .. (detail and (" (" .. tostring(detail) .. ")") or ""))
end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local bags = {}        -- { item, inv }
local A, B, C
local sandboxWas

local function queueTypes()
    local q = ISTimedActionQueue.queues and ISTimedActionQueue.queues[p]
    local names = {}
    for _, a in ipairs((q and q.queue) or {}) do names[#names + 1] = tostring(a.Type) end
    return table.concat(names, " ")
end
local function searchQueued(inv)
    local q = ISTimedActionQueue.queues and ISTimedActionQueue.queues[p]
    for _, a in ipairs((q and q.queue) or {}) do
        if a.Type == "ImmersiveSearching_ISSearch" and a.container == inv then return true end
    end
    return false
end
local function transferQueued()
    local q = ISTimedActionQueue.queues and ISTimedActionQueue.queues[p]
    for _, a in ipairs((q and q.queue) or {}) do
        if a.Type == "ISInventoryTransferAction" then return true end
    end
    return false
end
local function content() local w = ww(); return w and w._mainContent end
local function bandIds()
    local c = content()
    local cc = c and c._cc
    local ids = {}
    for _, s in ipairs((cc and cc.moves) or {}) do ids[#ids + 1] = "m:" .. tostring(s.id) end
    for _, s in ipairs((cc and cc.objs) or {}) do ids[#ids + 1] = "o:" .. tostring(s.id) end
    return table.concat(ids, ","), cc
end
local function hasId(list, id)
    for _, s in ipairs(list or {}) do if s.id == id then return s end end
    return nil
end
local function revealed(inv)
    local r = IS and IS.Items and IS.Items[inv]
    local n = 0
    if r and r.Searched then for _ in pairs(r.Searched) do n = n + 1 end end
    return n
end
local function show(inv)
    local w = ww()
    if not w then return false end
    w._viewedContainer = nil
    return ZeD_WorldWindow.selectContainer(inv, 90)
end
local function stripStamp(inv)
    local w = ww()
    local st = w and w._stripDecorated and w._stripDecorated[inv]
    return st and st[ID] or false
end

step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("start " .. TAG .. ": mod loaded " .. tostring(IS ~= nil) .. ", support " .. tostring(S ~= nil)
        .. ", sandbox SearchAll " .. tostring(SandboxVars.ImmersiveSearching and SandboxVars.ImmersiveSearching.SearchAll))
    if not (ZeD_CharacterWindow.isOpen() and ZeD_WorldWindow.isOpen()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    pcall(function() ISTimedActionQueue.clear(p) end)
    local sq = p:getCurrentSquare()
    local fills = {
        { "Base.Hammer", "Base.TinnedBeans", "Base.WaterBottle", "Base.Socks_Ankle", "Base.Pencil", "Base.Battery" },
        { "Base.Pencil", "Base.Battery" },
        { "Base.TinnedBeans" },
    }
    for i, list in ipairs(fills) do
        local item
        pcall(function() item = sq:AddWorldInventoryItem("Base.Bag_DuffelBag", 0.3 + i * 0.15, 0.5, 0) end)
        if item then
            local inv = item:getInventory()
            for _, t in ipairs(list) do pcall(function() inv:AddItem(t) end) end
            bags[#bags + 1] = { item = item, inv = inv }
        end
    end
    A, B, C = bags[1] and bags[1].inv, bags[2] and bags[2].inv, bags[3] and bags[3].inv
    say("bags on the floor " .. #bags .. ", A holds " .. tostring(A and A:getItems():size()))
    local w = ww()
    if w then w._containerTimer = 30 end
end)
step(60, function()
    -- (the strip's list refreshes every 30 frames)
    local w = ww()
    local found = 0
    for _, e in ipairs((w and w._containers) or {}) do
        if e.inventory == A or e.inventory == B or e.inventory == C then found = found + 1 end
    end
    check("the three bags are on the World strip", found == 3, found)
end)

-- ---------------------------------------------------------------- the mod OFF: nothing changes
if not ON then
    step(2, function()
        check("no gate registered for the mod", G == nil or #G.gates == 0, G and #G.gates)
        check("no pick hook registered", G == nil or #G.chosen == 0, G and #G.chosen)
        local dec = false
        for _, d in ipairs((ZeD.StripDecorators and ZeD.StripDecorators.world) or {}) do if d.id == ID then dec = true end end
        check("no strip decorator for the mod", not dec)
        local prov = false
        for _, pr in ipairs((CT and CT.providers) or {}) do if pr.id == ID then prov = true end end
        check("no band provider for the mod", not prov)
        check("bag A counts six with no gate", G.count(A, p) == 6, G.count(A, p))
        show(A)
    end)
    step(30, function()
        local ids, cc = bandIds()
        check("A on show lists six, Take all in the band", content() and content()._inventory == A and hasId(cc and cc.moves, "take") ~= nil, ids)
        check("picking A queued nothing", queueTypes() == "", queueTypes())
        check("no empty-line or weight words from a gate", G.emptyText(A, p) == nil and G.status(A, p) == nil)
        shot("a")
    end)
end

-- ---------------------------------------------------------------- the mod ON
if ON then
    step(2, function()
        -- 1. the "?" chip
        local now = getTimestampMs()
        for i, inv in ipairs({ A, B, C }) do
            local at = S.badged[inv]
            check("bag " .. i .. " unsearched, its ? chip drawn", not S.isSearched(p, inv) and at ~= nil and now - at < 2000 and stripStamp(inv), at)
        end
        -- 2. before any search
        local g = G.get(A, p)
        check("A: the gate says unsearched and refuses things", g ~= nil and g.mode == "unsearched" and g.refuse == true, g and g.mode)
        check("A: lists 0 before the search", G.count(A, p) == 0, G.count(A, p))
        check("A: empty line", G.emptyText(A, p) == ZeD.tr("UI_ZeD_Search_EmptyNot"), G.emptyText(A, p))
        check("A: weight line", G.status(A, p) == ZeD.tr("UI_ZeD_Search_NotSearched"), G.status(A, p))
        local pencil = p:getInventory():AddItem("Base.Pencil")
        bags.pencil = pencil
        CT.moveItems(p, { pencil }, A)
        check("A: a move into it queues nothing (the mod's hasRoomFor)", not transferQueued(), queueTypes())
        shot("1_before")
        -- 3. picked in ZeD's World window
        show(A)
    end)
    step(10, function()
        local L = S.lastStart
        check("A picked: the mod's search started by the pick", L.inv == A and L.how == "pick" and L.ok, tostring(L.how))
        check("A picked: the search is in the queue", searchQueued(A), queueTypes())
    end)
    -- 4. during the search
    local samples = {}
    for k = 1, 12 do
        step(8, function()
            local g = G.get(A, p)
            if not g then return end
            local ids, cc = bandIds()
            samples[#samples + 1] = { n = G.count(A, p), rev = revealed(A), prog = g.band and g.band.progress, mode = g.mode,
                take = hasId(cc and cc.moves, "take") ~= nil, ids = ids }
            if k == 5 then shot("2_mid") end
        end)
    end
    step(2, function()
        local rising, equal, noTake, prog, maxN = true, true, true, false, 0
        local lastN, lastP = -1, -1
        for _, s in ipairs(samples) do
            if s.n < lastN then rising = false end
            if s.n ~= s.rev then equal = false end
            if s.take then noTake = false end
            if s.prog and s.prog > lastP then prog = true; lastP = s.prog end
            lastN = s.n
            if s.n > maxN then maxN = s.n end
        end
        local trace = {}
        for _, s in ipairs(samples) do trace[#trace + 1] = s.mode .. ":" .. s.n .. "/" .. s.rev .. "@" .. string.format("%.2f", s.prog or -1) end
        say("search trace " .. table.concat(trace, " "))
        check("during: samples taken", #samples >= 3, #samples)
        check("during: the list count never falls", rising)
        check("during: the list shows exactly what the mod revealed", equal)
        check("during: things turn up while the search runs", maxN > 0, maxN)
        check("during: no Take all in the band", noTake, samples[1] and samples[1].ids)
        check("during: the band's bar rises", prog)
    end)
    step(300, function()
        -- 5. after
        check("after: A searched", S.isSearched(p, A))
        check("after: no gate, six listed", G.get(A, p) == nil and G.count(A, p) == 6, G.count(A, p))
        local w = ww()
        if w then w._containerTimer = 30 end
    end)
    step(40, function()
        local ids, cc = bandIds()
        check("after: Take all back in A's band", hasId(cc and cc.moves, "take") ~= nil, ids)
        local at = S.badged[A]
        check("after: A's ? chip gone", at == nil or getTimestampMs() - at > 500, at)
        shot("3_after")
        -- 6. Search all: the sandbox off first
        local sv = SandboxVars.ImmersiveSearching
        sandboxWas = sv and sv.SearchAll
        if sv then sv.SearchAll = 1 end
        if cc then cc.frame = -1000 end
    end)
    step(5, function()
        local ids, cc = bandIds()
        check("Search all off in the sandbox: no button", hasId(cc and cc.objs, "is:all") == nil, ids)
        local sv = SandboxVars.ImmersiveSearching
        if sv then sv.SearchAll = 2 end
        if cc then cc.frame = -1000 end
    end)
    step(5, function()
        local ids, cc = bandIds()
        local spec = hasId(cc and cc.objs, "is:all")
        check("Search all on (2): the button shows with B and C unsearched", spec ~= nil, ids)
        if spec then
            pcall(spec.run, content())
            -- (the mod's startSearch queues its ISWaitWhileGettingUp first, which queues the search when it ends:
            -- either counts as that container's search being under way)
            local n = 0
            local q = ISTimedActionQueue.queues and ISTimedActionQueue.queues[p]
            for _, a in ipairs((q and q.queue) or {}) do
                if a.Type == "ImmersiveSearching_ISSearch" or a.Type == "ISWaitWhileGettingUp" then n = n + 1 end
            end
            check("Search all pressed: B and C searches queued", (searchQueued(B) and searchQueued(C)) or n >= 2, queueTypes())
            shot("4_search_all")
        end
    end)
    step(400, function()
        check("Search all: B and C searched", S.isSearched(p, B) and S.isSearched(p, C))
        local w = ww()
        if w then w._containerTimer = 30 end
    end)
    step(40, function()
        local ids, cc = bandIds()
        check("nothing unsearched in reach: no Search all", hasId(cc and cc.objs, "is:all") == nil, ids)
        local sv = SandboxVars.ImmersiveSearching
        if sv then sv.SearchAll = sandboxWas end
        say("sandbox SearchAll put back to " .. tostring(sandboxWas))
    end)
end

-- ---------------------------------------------------------------- put back
step(5, function()
    pcall(function() ISTimedActionQueue.clear(p) end)
    if bags.pencil then pcall(function() bags.pencil:getContainer():DoRemoveItem(bags.pencil) end) end
    for _, b in ipairs(bags) do
        local wi = b.item and b.item:getWorldItem()
        local sq = wi and wi:getSquare()
        pcall(function() sq:transmitRemoveItemFromSquare(wi) end)
        pcall(function() wi:removeFromSquare() end)
    end
    local w = ww()
    if w then w._containerTimer = 30; w._activeContainer = #(w._containers or {}) end
    pcall(function() ISInventoryPage.dirtyUI() end)
    say("bags taken away")
end)
step(10, function()
    say("RESULT " .. (fails == 0 and "PASS" or ("FAIL " .. fails)))
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
