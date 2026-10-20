-- ZeD QA (Oct 16 2026): the lit window tabs. Opens both windows, screenshots, switches the character window to a few
-- tabs and the world window to Crafting, screenshots each, puts the tabs back. grep "ZEDQA tl".
local function say(s) print("ZEDQA tl " .. tostring(s)) end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local cw0, ww0
at(5, function()
    if not ZeD_CharacterWindow.getInstance() then ZeD_CharacterWindow.toggleBothPaired(0) end
    setGameSpeed(1)
end)
at(40, function()
    local cw, ww = ZeD_CharacterWindow.getInstance(), ZeD_WorldWindow.getWindow()
    say("char " .. tostring(cw ~= nil) .. " world " .. tostring(ww ~= nil) .. " TabPx " .. tostring(ZeD.TabPx ~= nil))
    cw0 = cw and cw._activeTab; ww0 = ww and ww._activeTab
    say("active " .. tostring(cw0) .. " / " .. tostring(ww0))
    pcall(function() getCore():TakeFullScreenshot("zqa_tabs_1.png") end)
end)
at(60, function() local cw = ZeD_CharacterWindow.getInstance(); if cw then cw._activeTab = "health" end
                  local ww = ZeD_WorldWindow.getWindow(); if ww then ww._activeTab = "craft" end end)
at(90, function() pcall(function() getCore():TakeFullScreenshot("zqa_tabs_2.png") end) end)
at(110, function() local cw = ZeD_CharacterWindow.getInstance(); if cw then cw._activeTab = "skills" end
                   local ww = ZeD_WorldWindow.getWindow(); if ww then ww._activeTab = "maps" end end)
at(140, function() pcall(function() getCore():TakeFullScreenshot("zqa_tabs_3.png") end) end)
at(150, function()
    local cw = ZeD_CharacterWindow.getInstance(); if cw and cw0 then cw._activeTab = cw0 end
    local ww = ZeD_WorldWindow.getWindow(); if ww and ww0 then ww._activeTab = ww0 end
    say("restored; DONE")
end)
local k, i = 0, 1
local function tick()
    k = k + 1
    while steps[i] and steps[i].n <= k do local ok, e = pcall(steps[i].f); if not ok then say("step error " .. tostring(e)) end; i = i + 1 end
    if not steps[i] then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
