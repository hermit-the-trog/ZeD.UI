-- ZeDUI/tools/qa/zedqa_studio_frame_probe.lua  (Nov 10 2026, Build; punch list 145, the studio's framings)
-- QA's Mac run on ec3fb25: Full body and Bust frame right, Three-quarter (halfway between their zoom and their y offset)
-- framed collar to shins and cut the head off; and in Full body, turned three-quarters away, the shoes were cut flat.
-- How the figure's y offset moves it at a given zoom can't be read from here, so this probe opens the real studio and
-- shoots a grid of framings, each named in the studio's own help line ("zoom 11  y -0.80"):
--   FULL     zoom -2, -1, 0 at y 0, the figure turned three-quarters (SW): which keeps the shoes whole
--   MIDDLE   zoom 6, 11 and 15, each with y 0 to -1.6 in steps of 0.2: at each zoom, the y that puts the top of the
--            frame just above the head (the head whole, a little paper over it)
-- Run in game after zedqa_prelude.lua (any save, single player, -debug off). Shots zqa_frame_<zoom>_<y>.png. Send back,
-- for each zoom, the best y (the head whole, the least paper above it) and the full body zoom that keeps the shoes.
local function say(s) print("ZEDQA fr " .. tostring(s)) end
local steps, qi, wait = {}, 1, nil
local function step(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
local room = nil
local function frame(z, y, label)
    local m = room and room.fig
    if not m then return end
    m:setZoom(z); m:setYOffset(y)
    room.saved = nil
    room._probeLabel = label
end
local function shot(n)
    pcall(function() getCore():TakeFullScreenshot("zqa_frame_" .. n .. ".png") end)
    say("shot zqa_frame_" .. n .. ".png")
end
step(300, function()
    local ok = ZeD.Studio and ZeD.Studio.open(getPlayer())
    say("studio open: " .. tostring(ok))
    room = ZeD.Studio and ZeD.Studio.room
    if room then
        -- the probe's label in the help line's place
        local tr0 = ZeD.tr
        room._zedTr = tr0
        room.drawBar = function(self, L)
            local T = ZeD.T
            local y0 = self.height - L.bar
            local s2 = T.surf2
            self:drawRect(0, y0, self.width, L.bar, 1, s2.r, s2.g, s2.b)
            self:drawText(tostring(self._probeLabel or ""), T.px(16), y0 + T.px(10), 1, 1, 0.4, 1, UIFont.Large)
        end
        pcall(function() room.fig:setDirection(IsoDirections.SW) end)
    end
end)
local function fmt(v) return string.format("%.1f", v) end
for _, z in ipairs({ -2, -1, 0 }) do
    step(300, function() frame(z, 0, "FULL  zoom " .. z .. "  y 0  (turned SW)") end)
    step(700, function() shot("full_" .. z) end)
end
step(200, function() pcall(function() room.fig:setDirection(IsoDirections.S) end) end)
for _, z in ipairs({ 6, 11, 15 }) do
    for i = 0, 8 do
        local y = -0.2 * i
        step(250, function() frame(z, y, "MIDDLE  zoom " .. z .. "  y " .. fmt(y)) end)
        step(600, function() shot(z .. "_" .. fmt(y)) end)
    end
end
step(300, function()
    if ZeD.Studio then ZeD.Studio.close() end
    say("DONE")
end)
local function tick()
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.ms)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
