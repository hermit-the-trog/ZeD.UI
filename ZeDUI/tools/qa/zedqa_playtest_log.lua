-- ZeDUI/tools/qa/zedqa_playtest_log.lua  (Nov 14 2026, QA): the logger alone, for a later playtest in ZeD-Playtest (nothing
-- else changed in the save). Pad presses with focus / cursor / pause, focus changes, and while a game cursor is up its
-- build, canBeBuild and fine-aim state, plus tryBuild runs. grep "ZEDQA ptl".
local function say(s) print("ZEDQA ptl " .. tostring(s)) end
local function desc(o)
    if o == nil then return "nil" end
    local s = tostring(o._zedLabel or o.Type or o)
    local ok, v = pcall(function() return o:isReallyVisible() end)
    return s .. ((ok and v) and "" or " (hidden)")
end
local names = {}
for k, v in pairs(Joypad) do if type(v) == "number" then names[v] = k end end
if not ZEDQA_PTL2 then
    ZEDQA_PTL2 = true
    local origPress = JoypadControllerData.onPressButton
    JoypadControllerData.onPressButton = function(self, b, ...)
        local jd = self.joypad
        local d = getCell() and getCell():getDrag(0)
        local extra = ""
        if d then extra = " | build " .. tostring(d.build) .. " canBeBuild " .. tostring(d.canBeBuild) .. " fineAim " .. tostring(d.joypadPositionActive) end
        say("press " .. tostring(names[b] or b) .. " | focus " .. desc(jd and jd.focus) .. " | cursor " .. tostring(d and (d.Type or "yes")) .. extra .. " | paused " .. tostring(isGamePaused()))
        return origPress(self, b, ...)
    end
    local origNoFocus = JoypadControllerData.onPressButtonNoFocus
    JoypadControllerData.onPressButtonNoFocus = function(self, b, ...)
        say("  no-focus path got " .. tostring(names[b] or b))
        return origNoFocus(self, b, ...)
    end
    local tb = ISBuildingObject.tryBuild
    ISBuildingObject.tryBuild = function(self, x, y, z, ...) say("tryBuild ran (" .. tostring(self.Type) .. ")"); return tb(self, x, y, z, ...) end
end
local last = ""
local function tick()
    local jd = JoypadState.players[1]
    local pl = getPlayer()
    local d = getCell() and getCell():getDrag(0)
    local s = "focus " .. desc(jd and jd.focus) .. " | cursor " .. tostring(d and (d.Type or "yes")) .. " | pad bound " ..
        tostring(pl and pl:getJoypadBind()) .. " | paused " .. tostring(isGamePaused()) .. " | dead " .. tostring(pl and pl:isDead())
    if s ~= last then say("state: " .. s); last = s end
end
Events.OnRenderTick.Add(tick)
say("logger running; the director can play")

-- (Nov 14 2026, second pass) 218: the button prompt's A; 217: slow frames; 210: every Lua sound call; 212: focus after a bumper.
if not ZEDQA_PTL_EXTRA then
  ZEDQA_PTL_EXTRA = true
  local oA = ISButtonPrompt.onAPress
  ISButtonPrompt.onAPress = function(self, ...)
    print("ZEDQA ptl prompt A | aPrompt " .. tostring(self.aPrompt) .. " | aFunc " .. tostring(self.aFunc) .. " | aParam1 " .. tostring(self.aParameter1))
    local ok, e = pcall(oA, self, ...)
    if not ok then print("ZEDQA ptl prompt A ERROR " .. tostring(e)) end
  end
  local last = getTimestampMs()
  local frames = 0
  local bump = 0
  local lastF = nil
  Events.OnRenderTick.Add(function()
    local now = getTimestampMs(); local dt = now - last; last = now; frames = frames + 1
    if dt > 60 then
      local cv, wv = "?", "?"
      pcall(function() cv = tostring(ZeD_CharacterWindow.getInstance(0):isReallyVisible()) end)
      pcall(function() wv = tostring(ZeD_WorldWindow.getWindow(0):isReallyVisible()) end)
      print("ZEDQA ptl hitch " .. dt .. " ms | Character visible " .. cv .. " | World visible " .. wv)
    end
    if bump > 0 then
      bump = bump - 1
      local f = getJoypadFocus(0); local s = f and tostring(f._zedLabel or f.Type) or "nil"
      if s ~= lastF then print("ZEDQA ptl bumper focus " .. s .. " (" .. (60 - bump) .. " frames after)"); lastF = s end
    end
  end)
  local prevPress = JoypadControllerData.onPressButton
  JoypadControllerData.onPressButton = function(self, b, ...)
    if b == Joypad.RBumper or b == Joypad.LBumper then bump = 60; lastF = nil end
    return prevPress(self, b, ...)
  end
  local realGet = getSoundManager
  local real = realGet()
  getSoundManager = function() return setmetatable({}, { __index = function(_, k)
    return function(_, ...)
      if k == "playUISound" or k == "PlaySound" or k == "playSound" or k == "PlayWorldSound" then print("ZEDQA ptl sound " .. k .. " " .. tostring((...)) .. " | ms " .. getTimestampMs()) end
      return real[k](real, ...)
    end
  end }) end
  print("ZEDQA ptl extras on: prompt A, hitches, sounds, bumper focus")
end