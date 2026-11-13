-- ZeD QA: UI scale option (Auto / fixed steps) + the pixel icon drawn for a 16-unit box (ZeD.PxIcon, Oct 28 2026;
-- the baked tab picture sizes it read before are gone)
-- Nov 12 2026 (test cleanup, SHRINK to real checks): at every step both windows must be open, on the screen and not
-- over each other, and the icon must have a drawing; at the end the scale is the one the run started on and the
-- windows are back where they were (the window rule: ZEDQA_LAYOUT_SNAP / ZEDQA_LAYOUT_BACK from the prelude).
-- This is the one scale script now: zedqa_win.lua, zedqa_rootchange.lua and zedqa_scalewalk.lua printed the same
-- geometry with no checks and are out of the main run. Lines "PASS ..." / "FAIL ..."; grep "ZEDQA scale".
local function W() return ZeD_WorldWindow.getWindow() end
local function C() return ZeD_CharacterWindow.getWindow() end
local nPass, nFail = 0, 0
local function check(ok, what)
  if ok then nPass = nPass + 1; print("ZEDQA scale PASS " .. what) else nFail = nFail + 1; print("ZEDQA scale FAIL " .. what) end
end
local SNAP = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP()   -- (nil when run without the prelude)
local function report(tag)
  local T = ZeD.T
  local sz = T.px(16)
  local tex = ZeD.PxIcon.tex("crate", sz)
  local w, c = W(), C()
  print("ZEDQA scale " .. tag .. " option=" .. tostring(ZeD.Settings.uiScaleOption:getValue()) .. " userScale=" .. tostring(ZeD.Scale.userScale)
    .. " root=" .. tostring(ZeD.Scale.root()) .. " iconDrawn=" .. sz .. " iconTex=" .. tostring(tex and (tex:getWidth() .. "x" .. tex:getHeight()))
    .. " char=" .. tostring(c and (c:getWidth() .. "x" .. c:getHeight())) .. " world=" .. tostring(w and (w:getWidth() .. "x" .. w:getHeight())))
  local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
  check(c ~= nil and w ~= nil and c:isVisible() and w:isVisible(), tag .. ": both windows are open")
  if c and w then
    local onScreen = true
    for _, x in ipairs({ c, w }) do
      if x:getX() < 0 or x:getY() < 0 or x:getX() + x:getWidth() > sw or x:getY() + x:getHeight() > sh then onScreen = false end
    end
    check(onScreen, tag .. ": both windows are wholly on the screen (" .. sw .. "x" .. sh .. ")")
    check(c:getX() + c:getWidth() <= w:getX() or w:getX() + w:getWidth() <= c:getX(), tag .. ": the windows do not overlap")
  end
  check(tex ~= nil, tag .. ": the crate icon has a drawing at " .. sz .. " px")
  pcall(function() getCore():TakeFullScreenshot("zedqa_scale_" .. tag .. ".png") end)
end
local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
-- the step the run started on (Oct 22 2026: it went back to Auto, which left the rest of a
-- 4K regression at Auto instead of the run's 1.75x); put back at the end
local was = ZeD.Settings.uiScaleOption:getValue() or 1
local root0 = ZeD.Scale.root()
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
at(470, function() if ZEDQA_LAYOUT_BACK then ZEDQA_LAYOUT_BACK(SNAP, "scale") end end)
at(500, function()
  report("restored")
  check(ZeD.Settings.uiScaleOption:getValue() == was and ZeD.Scale.root() == root0,
    "the scale is back on the run's own step (option " .. tostring(was) .. ", root " .. tostring(root0) .. ")")
  if SNAP and SNAP.char and SNAP.world then
    local c, w = C(), W()
    check(c:getX() == SNAP.char.x and c:getY() == SNAP.char.y and c:getWidth() == SNAP.char.w and c:getHeight() == SNAP.char.h
      and w:getX() == SNAP.world.x and w:getY() == SNAP.world.y and w:getWidth() == SNAP.world.w and w:getHeight() == SNAP.world.h,
      "both windows are back where and as large as the script found them")
  else
    print("ZEDQA scale not run: the put-back check (no prelude, no layout snapshot)")
  end
  print("ZEDQA scale " .. nPass .. " passed, " .. nFail .. " failed")
  print("ZEDQA scale done")
end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick); print("ZEDQA scale armed")
