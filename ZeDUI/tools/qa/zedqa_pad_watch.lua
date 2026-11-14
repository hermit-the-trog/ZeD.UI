-- ZeDUI/tools/qa/zedqa_pad_watch.lua  (Nov 14 2026, QA, punch list 188): logs only, for a hands-on check with the real
-- controller. Leaves wrappers in place: every press through the game's controller path is logged with the pad focus,
-- and any change of pad focus, pause, player binding or "mouse more recent than pad" is logged as it happens.
-- grep "ZEDQA pw".
local function say(s) print("ZEDQA pw " .. tostring(s)) end
local function desc(o)
    if o == nil then return "nil" end
    local s = tostring(o._zedLabel or o.Type or o)
    local ok, v = pcall(function() return o:isReallyVisible() end)
    return s .. (ok and v and "" or " (hidden)")
end
local names = {}
for k, v in pairs(Joypad) do if type(v) == "number" then names[v] = k end end
local origPress = JoypadControllerData.onPressButton
JoypadControllerData.onPressButton = function(self, b, ...)
    local jd = self.joypad
    say("press " .. tostring(names[b] or b) .. " | focus " .. desc(jd and jd.focus) .. " | paused " .. tostring(isGamePaused()))
    return origPress(self, b, ...)
end
local origNoFocus = JoypadControllerData.onPressButtonNoFocus
JoypadControllerData.onPressButtonNoFocus = function(self, b, ...)
    say("  no-focus path got " .. tostring(names[b] or b))
    return origNoFocus(self, b, ...)
end
local last = ""
local function tick()
    local jd = JoypadState.players[1]
    local m = "?"
    pcall(function() m = tostring(wasMouseActiveMoreRecentlyThanJoypad()) end)
    local p = getPlayer()
    local s = "focus " .. desc(jd and jd.focus) .. " | pad bound " .. tostring(p and p:getJoypadBind()) .. " | players[1] " ..
        tostring(jd ~= nil) .. " | paused " .. tostring(isGamePaused()) .. " | mouse more recent " .. m
    if s ~= last then say("state: " .. s); last = s end
end
Events.OnRenderTick.Add(tick)
say("watching (wrappers stay until the game quits)")
say("DONE")
