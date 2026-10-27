-- ZeDUI/tools/qa/gallery_daylight.lua  (Oct 27 2026)
-- Sets the QA save's clock to 11:00 so the captures after it are taken in daylight (the 0.2.0-t7
-- gallery's third run came out at night: the bubbles, the wheels and see-through over a black scene).
-- Run it right after zedqa_prelude.lua in a gallery manifest. The time stays changed (the QA save
-- only). Waits two seconds for the light to settle. grep "ZEDQA day".
local function say(s) print("ZEDQA day " .. tostring(s)) end
local gt = getGameTime()
local was = gt:getTimeOfDay()
gt:setTimeOfDay(11.0)
say(string.format("time %.2f -> 11.00", was))
local n = 0
local function later()
    n = n + 1
    if n < 120 then return end
    Events.OnTick.Remove(later)
    say("DONE")
end
Events.OnTick.Add(later)
