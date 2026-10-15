-- ZeDUI/tools/qa/zedqa_desk_v3.lua  (Oct 15 2026)
-- The v3 main menu desk (ZeDUI/tools/mainmenu/README.md, check pass): the
-- main menu at 1920 x 1080 three ways: normal (hard disk lit), on a lamp dim
-- beat (desk_lampdim.png), and with the hard disk light off. Run at the main
-- menu: copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA dk".

local MM = ZeD.MainMenu
local life = MM._life
local function say(s) print("ZEDQA dk " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_dk_" .. n .. ".png") end) end
local FAR = 1e12
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function hold()
    -- every bit of desk life parked where the step puts it
    local t = getTimestampMs()
    life.hdd = life.hdd or {}
    life.hdd.stopAt, life.hdd.flipAt, life.hdd.nextAt = nil, nil, t + FAR
    life.floppy = life.floppy or {}
    life.floppy.stopAt, life.floppy.nextAt = nil, t + FAR
    life.needle = life.needle or { dx = 0 }
    life.needle.dx, life.needle.nextAt = 0, t + FAR
    life.zap = life.zap or {}
    life.zap.t0, life.zap.nextAt = nil, t + FAR
    life.lamp = life.lamp or {}
end
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    MM.ctx.open = nil
end)
at(10, function() hold(); life.hdd.on = true; life.lamp.beats = nil; life.lamp.nextAt = getTimestampMs() + FAR end)
at(30, function() shot("01_normal"); say("normal") end)
at(40, function() hold(); life.lamp.beats = { 600000 }; life.lamp.i = 1; life.lamp.beatEnd = getTimestampMs() + 600000 end)
at(60, function() shot("02_lamp_dim"); say("lamp dipped") end)
at(70, function() hold(); life.lamp.beats = nil; life.lamp.nextAt = getTimestampMs() + FAR; life.hdd.on = false end)
at(90, function() shot("03_hdd_off"); say("hard disk off") end)
at(100, function() life.hdd.nextAt = getTimestampMs() + 2000; life.lamp.nextAt = getTimestampMs() + 8000; life.zap.nextAt = getTimestampMs() + 6000; life.needle.nextAt = getTimestampMs() + 4000; life.floppy.nextAt = getTimestampMs() + 20000; say("DONE") end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 110 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
