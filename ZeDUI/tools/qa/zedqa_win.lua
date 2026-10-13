-- ZeD QA S124 phase 2: open the window pair, capture at the natural root (2.0) and at a forced 1.0
local Sc = ZeD.Scale; local T = ZeD.T
local function info(tag)
    local cw = ZeD_CharacterWindow.getWindow(); local ww = ZeD_WorldWindow.getWindow()
    print("ZEDQA win " .. tag .. " root=" .. tostring(Sc.root()) .. " T.scale=" .. tostring(ZeD.T.scale) .. " rowH=" .. tostring(ZeD.T.rowH) .. " sp.md=" .. tostring(ZeD.T.sp.md) .. " F2H=" .. tostring(ZeD.T.fontF2H)
        .. " char=" .. tostring(cw and cw:isVisible()) .. " " .. tostring(cw and cw:getX()) .. "," .. tostring(cw and cw:getY()) .. " " .. tostring(cw and cw:getWidth()) .. "x" .. tostring(cw and cw:getHeight())
        .. " world=" .. tostring(ww and ww:isVisible()) .. " " .. tostring(ww and ww:getX()) .. "," .. tostring(ww and ww:getY()) .. " " .. tostring(ww and ww:getWidth()) .. "x" .. tostring(ww and ww:getHeight()))
end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
at(5, function() if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end; local cw = ZeD_CharacterWindow.getWindow(); if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end end)
at(60, function() info("natural"); pcall(function() getCore():TakeFullScreenshot("zedqa_win_200.png") end) end)
at(70, function() Sc.override = 1.0; Sc.refresh(); ZeD.applyTheme() end)
at(130, function() info("forced1"); pcall(function() getCore():TakeFullScreenshot("zedqa_win_100.png") end) end)
at(140, function() Sc.override = nil; Sc.refresh(); ZeD.applyTheme(); print("ZEDQA win done root=" .. tostring(Sc.root())) end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick)
