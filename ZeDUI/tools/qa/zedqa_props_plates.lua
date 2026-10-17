-- ZeD QA (Oct 16 2026): the rod and clock radio plates, drawn by the real Overrides/Fishing.lua and Sleeping.lua
-- draw functions on a test panel (no need to cast a line or fall asleep), then screenshotted.
local function say(s) print("ZEDQA props " .. tostring(s)) end
local P = ISPanel:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
P:initialise(); P.backgroundColor = { r = 0.05, g = 0.06, b = 0.05, a = 1 }
local T = { 0, 0.5, 1.0 }
P.idx = 1
function P:render()
    local t = T[self.idx]
    local okA, a = pcall(ZeD.FishRod.draw, self, 40, 40, 2, t)
    local okB, b = pcall(ZeD.FishRod.draw, self, 900, 40, 2, -0.5)
    local okC, c = pcall(ZeD.SleepClock.draw, self, 40, 520, 3, 22.78, true)
    if not self._said then self._said = true; say("draw rod " .. tostring(okA) .. "/" .. tostring(a) .. " slack " .. tostring(okB) .. " clock " .. tostring(okC) .. "/" .. tostring(c)) end
end
P:addToUIManager()
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
at(20, function() pcall(function() getCore():TakeFullScreenshot("zqa_props_1.png") end) end)
at(25, function() P.idx = 2 end)
at(45, function() pcall(function() getCore():TakeFullScreenshot("zqa_props_2.png") end) end)
at(50, function() P.idx = 3 end)
at(70, function() pcall(function() getCore():TakeFullScreenshot("zqa_props_3.png") end) end)
at(75, function() P:removeFromUIManager(); say("DONE") end)
local k, i = 0, 1
local function tick()
    k = k + 1
    while steps[i] and steps[i].n <= k do local ok, e = pcall(steps[i].f); if not ok then say("step error " .. tostring(e)) end; i = i + 1 end
    if not steps[i] then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
