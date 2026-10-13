-- ZeD QA S124: a root change while the pair is open must re-derive the window geometry (close + reopen from design units)
local Sc = ZeD.Scale
local function info(tag) local cw = ZeD_CharacterWindow.getWindow(); local ww = ZeD_WorldWindow.getWindow(); print("ZEDQA rc " .. tag .. " root=" .. tostring(Sc.root()) .. " applied=" .. tostring(Sc._appliedRoot) .. " char=" .. tostring(cw and cw:isVisible()) .. " " .. tostring(cw and cw:getWidth()) .. "x" .. tostring(cw and cw:getHeight()) .. " at " .. tostring(cw and cw:getX()) .. "," .. tostring(cw and cw:getY()) .. " world=" .. tostring(ww and ww:isVisible()) .. " " .. tostring(ww and ww:getWidth()) .. "x" .. tostring(ww and ww:getHeight()) .. " rowH=" .. tostring(ZeD.T.rowH)) end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
at(5, function() if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end; if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
at(40, function() info("open at natural") end)
at(45, function() Sc.override = 1.0; Sc.refresh() end)          -- the tick hook notices within 30 ticks, re-applies, closes + reopens
at(130, function() info("after override 1.0"); pcall(function() getCore():TakeFullScreenshot("zedqa_rc_100.png") end) end)
at(140, function() Sc.override = nil; Sc.refresh() end)
at(225, function() info("after override cleared"); pcall(function() getCore():TakeFullScreenshot("zedqa_rc_200.png") end); print("ZEDQA rc done") end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick)
