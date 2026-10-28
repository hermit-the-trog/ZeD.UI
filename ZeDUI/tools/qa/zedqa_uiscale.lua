-- ZeD QA: UI scale option (Auto / fixed steps) + the pixel icon drawn for a 16-unit box (ZeD.PxIcon, Oct 28 2026;
-- the baked tab picture sizes it read before are gone)
local function W() return ZeD_WorldWindow.getWindow() end
local function C() return ZeD_CharacterWindow.getWindow() end
local function report(tag)
  local T = ZeD.T
  local sz = T.px(16)
  local tex = ZeD.PxIcon.tex("crate", sz)
  local w, c = W(), C()
  print("ZEDQA scale " .. tag .. " option=" .. tostring(ZeD.Settings.uiScaleOption:getValue()) .. " userScale=" .. tostring(ZeD.Scale.userScale)
    .. " root=" .. tostring(ZeD.Scale.root()) .. " iconDrawn=" .. sz .. " iconTex=" .. tostring(tex and (tex:getWidth() .. "x" .. tex:getHeight()))
    .. " char=" .. tostring(c and (c:getWidth() .. "x" .. c:getHeight())) .. " world=" .. tostring(w and (w:getWidth() .. "x" .. w:getHeight())))
  pcall(function() getCore():TakeFullScreenshot("zedqa_scale_" .. tag .. ".png") end)
end
local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
-- the step the run started on (Oct 22 2026: it went back to Auto, which left the rest of a
-- 4K regression at Auto instead of the run's 1.75x); put back at the end
local was = ZeD.Settings.uiScaleOption:getValue() or 1
at(5, function()
  if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end
  if not (C() and C():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
at(60, function() report("auto") end)
at(70, function() ZeD.Settings.uiScaleOption:setValue(6); ZeD.Settings.applyScale() end)   -- 1.5x
at(170, function() report("x150") end)
at(180, function() ZeD.Settings.uiScaleOption:setValue(4); ZeD.Settings.applyScale() end)  -- 1x
at(280, function() report("x100") end)
at(290, function() ZeD.Settings.uiScaleOption:setValue(1); ZeD.Settings.applyScale() end)  -- Auto
at(390, function() report("auto_back") end)
at(400, function() ZeD.Settings.uiScaleOption:setValue(was); ZeD.Settings.applyScale() end)  -- the run's own step
at(500, function() report("restored"); print("ZEDQA scale done") end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick); print("ZEDQA scale armed")
