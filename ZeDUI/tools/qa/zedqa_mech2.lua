-- ZeD QA: Vehicle tab pass 2 — tinted figure, primary verb, recipe rows, gamepad focus cue, a real install
local p = getPlayer()
local MT = ZeD.MechanicsTab
local function shot(tag) pcall(function() getCore():TakeFullScreenshot("zedqa_mech2_" .. tag .. ".png") end); print("ZEDQA mech2 shot " .. tag) end
local function W() return ZeD_WorldWindow.getWindow() end
local function S() local w = W(); return w and MT.getState(w) end
local v = nil
do
  local it = getCell():getVehicles():iterator()
  while it:hasNext() do
    local c = it:next()
    if c:getScriptName() == "Base.CarNormal" and p:DistTo(c:getX(), c:getY()) < 12 then v = c end
  end
end
print("ZEDQA mech2 car=" .. tostring(v and v:getId()) .. " dist=" .. tostring(v and p:DistTo(v:getX(), v:getY())))
if not v then return end
pcall(function() if not p:getInventory():haveThisKeyId(v:getKeyId()) then p:getInventory():AddItem(v:createVehicleKey()) end end)
if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end
local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local function card(id, verb) local s = S(); s.view, s.card, s.verb, s.confirm, s.cardScroll, s.pick, s.fixPick = "card", id, verb, nil, 0, 1, 1 end
local phase, n, waitStart = "wait", 0, 0
local function afterInspect(t)
  at(t + 40, function() shot("overview") end)
  at(t + 50, function() card("TireRearRight", nil) end)
  at(t + 90, function() local s = S(); print("ZEDQA mech2 tire verb=" .. tostring(s.verb)); shot("card_tire") end)
  at(t + 100, function() card("EngineDoor", "fix") end)
  at(t + 140, function() shot("card_hood") end)
  at(t + 150, function() local s = S(); s.view, s.card = "overview", nil end)
  -- gamepad: claim focus on the World window and land on the Rear Right Tire row
  at(t + 180, function()
    local w = W(); local Focus = ZeD.Input.Focus
    local els = MT.buildFocusables(w)
    local first, last = els[1] and els[1].id, els[#els] and els[#els].id
    print("ZEDQA mech2 focusables n=" .. #els .. " first=" .. tostring(first) .. " last=" .. tostring(last))
    pcall(function() Focus.claimFocus(w) end)
    for zi, z in ipairs(w._focusRing or {}) do
      if z.zone == "worldTabContent" then
        for ei, e in ipairs(z.elements or {}) do
          if e.id == "mech:row:TireRearRight" then w._focusIdx = zi; z.focusedElementIdx = ei; print("ZEDQA mech2 focus set zone=" .. zi .. " el=" .. ei) end
        end
      end
    end
  end)
  at(t + 220, function() shot("gamepad_row"); print("ZEDQA mech2 focused=" .. tostring(ZeD.Input.Focus.getFocusedElement(W()) and ZeD.Input.Focus.getFocusedElement(W()).id)) end)
  at(t + 230, function() pcall(function() ZeD.Input.Focus.releaseFocus() end) end)
  -- a real install on the missing rear-left tire
  at(t + 260, function() card("TireRearLeft", "install") end)
  at(t + 290, function()
    local s = S(); local z = s.byId["mech:verb:install"]
    print("ZEDQA mech2 install zone=" .. tostring(z ~= nil)); if z then z.fn() end
  end)
  at(t + 700, function() shot("installing") end)
  at(t + 2000, function()
    local rl = v:getPartById("TireRearLeft")
    print("ZEDQA mech2 after install RL item=" .. tostring(rl and rl:getInventoryItem()) .. " cond=" .. tostring(rl and rl:getCondition()))
    shot("after_install")
  end)
  at(t + 2010, function() local s = S(); s.view, s.card = "overview", nil end)
  at(t + 2050, function() shot("overview_after"); print("ZEDQA mech2 done") end)
end
local function tick()
  n = n + 1
  if phase == "wait" then
    if n == 5 then ISVehicleMenu.onMechanic(p, v); waitStart = n; print("ZEDQA mech2 onMechanic") end
    local w = W()
    if n > 5 and MT.isInspected(v) and w and w._activeTab == "vehicle" then
      print("ZEDQA mech2 inspected after " .. (n - waitStart)); phase = "run"; afterInspect(n)
    elseif n > 2400 then print("ZEDQA mech2 TIMEOUT"); Events.OnTick.Remove(tick) end
    return
  end
  local i = 1
  while steps[i] do
    if steps[i].n <= n then local ok, e = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(e)) end; table.remove(steps, i)
    else i = i + 1 end
  end
  if #steps == 0 then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick); print("ZEDQA mech2 armed")
