-- ZeD QA (Oct 17 2026): the reworked body figure in the engine. A test panel draws the male and female skeletons at
-- 1x and 2x with the left forearm tinted as an injury and the head as hot, screenshots it, and goes away.
local function say(s) print("ZEDQA body " .. tostring(s)) end
require "ZeD/ZeD_BodyFigure"
local P = ISPanel:derive("ZeDQABody")
function P:prerender()
    self:drawRect(0, 0, self.width, self.height, 1, 0.10, 0.11, 0.13)
    local x = 40
    for _, f in ipairs(self.figs) do
        f.fig:drawAt(self, x, 40, 220 * f.k, 260 * f.k)
        x = x + 220 * f.k + 40
    end
end
local p = P:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
p.figs = {}
for _, spec in ipairs({ { false, 1 }, { true, 1 }, { false, 2 }, { true, 2 } }) do
    local fig = ZeD_BodyFigure:new(0, 0, 100, 100, 0)
    fig:setSex(spec[1])
    fig:setPartColor("Left Forearm", 0.9, 0.27, 0.2, 0.9)
    fig:setPartColor("Head", 0.95, 0.66, 0.24, 0.9)
    p.figs[#p.figs + 1] = { fig = fig, k = spec[2] }
end
p:initialise(); p:addToUIManager(); p:bringToTop()
local k = 0
local function tick()
    k = k + 1
    if k == 40 then
        pcall(function() getCore():TakeFullScreenshot("zqa_body.png") end)
        local f = p.figs[3].fig
        say("drawn s=" .. tostring(f._drawAtS) .. " hit(head)=" .. tostring(f:hitTestAt(f._drawAtX + 220, f._drawAtY + 50)) ..
            " hit(left forearm)=" .. tostring(f:hitTestAt(f._drawAtX + 2 * 144, f._drawAtY + 2 * 108)))
    elseif k == 60 then
        p:removeFromUIManager()
        Events.OnRenderTick.Remove(tick)
        say("DONE")
    end
end
Events.OnRenderTick.Add(tick)
