-- ZeDUI/tools/qa/zedqa_power_on.lua  (Oct 16 2026)
-- At the main menu: the monitor's switch-on (MM.drawPowerOn) replayed and shot
-- at each step: dark, dot, line, opening, glare settling, done. grep "ZEDQA po".
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA po " .. tostring(s)) end
local t0 = getTimestampMs() + 150
MM.powerOn = { t0 = t0 }
local marks = { { 60, "1_dot" }, { 170, "2_line" }, { 330, "3_open" }, { 470, "4_glare" }, { 760, "5_settle" }, { 1400, "6_done" } }
local i = 1
local function tick()
    local m = marks[i]
    if not m then Events.OnFETick.Remove(tick); say("DONE"); return end
    if getTimestampMs() - t0 >= m[1] then
        getCore():TakeFullScreenshot("zqa_po_" .. m[2] .. ".png")
        say(m[2] .. " at " .. (getTimestampMs() - t0) .. " pointer-blocked " .. tostring(MM.poweringOn()))
        i = i + 1
    end
end
Events.OnFETick.Add(tick)
