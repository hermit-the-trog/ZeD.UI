-- ZeDUI/tools/qa/zedqa_padfix_e.lua  (Nov 14 2026, QA): 198 on 722282464. The Journal's Recipes page (win._journalSubTab = 4)
-- and its Sort pull-up opened from code (ZeD.CraftingCore.openPopMenu(win._jrecipeState, "sort")), a picture; then the same
-- for the World window's Building "Show" pull-up if its state is found. grep "ZEDQA pfe".
local function say(s) print("ZEDQA pfe " .. tostring(s)) end
local CC = ZeD.CraftingCore
local cw, ww
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(300, function() ZeD_CharacterWindow.openTab(0, "journal"); cw = ZeD_CharacterWindow.getInstance(0) end)
at(1300, function() cw._journalSubTab = 4; say("journal page set to 4") end)
at(2500, function()
    say("jrecipeState " .. tostring(cw._jrecipeState))
    local ok, e = pcall(function() CC.openPopMenu(cw._jrecipeState, "sort") end)
    say("openPopMenu sort ok=" .. tostring(ok) .. " " .. tostring(e))
end)
at(3500, function() pcall(function() getCore():TakeFullScreenshot("zqa_pfe_recipes_sort.png") end); say("shot recipes sort") end)
at(4000, function() pcall(function() CC.closePopMenu(cw._jrecipeState) end); pcall(function() cw._jrecipeState.popMenu = nil end) end)
at(4500, function()
    local ok, e = pcall(function() ZeD_WorldWindow.openTab(0, "building") end)
    say("World openTab building ok=" .. tostring(ok) .. " " .. tostring(e))
    ww = ZeD.windowsFor and ZeD.windowsFor(0) and ZeD.windowsFor(0)[2]
    if not ww then pcall(function() ww = ZeD_WorldWindow.getInstance(0) end) end
    local keys = {}
    if ww then for k, v in pairs(ww) do if type(v) == "table" and tostring(k):lower():find("state") then keys[#keys + 1] = tostring(k) end end end
    say("World window state tables: " .. table.concat(keys, ", "))
end)
at(6000, function()
    local st = ww and (ww._buildState or ww._buildingState or ww.buildState)
    say("build state " .. tostring(st))
    if st then local ok, e = pcall(function() CC.openPopMenu(st, "show") end); say("openPopMenu show ok=" .. tostring(ok) .. " " .. tostring(e)) end
end)
at(7000, function() pcall(function() getCore():TakeFullScreenshot("zqa_pfe_building_show.png") end); say("shot building show"); say("DONE") end)
local function tick()
    local now = getTimestampMs()
    if not t0 then t0 = now end
    while steps[i + 1] and now - t0 >= steps[i + 1].ms do
        i = i + 1
        local ok, e = pcall(steps[i].fn)
        if not ok then say("ERR step " .. i .. " " .. tostring(e)) end
    end
    if i >= #steps then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
