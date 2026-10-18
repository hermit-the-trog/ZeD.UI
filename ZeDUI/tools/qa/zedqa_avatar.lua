-- ZeD QA (Oct 17 2026): the game's own male and female body, unclothed, bald, facing front, standing idle, on a flat
-- green ground, side by side, for tracing the body figure's outlines (d_skeleton.py). Screenshot, then gone.
local function say(s) print("ZEDQA avatar " .. tostring(s)) end
local function desc(female)
    local d = nil
    pcall(function() d = SurvivorFactory.CreateSurvivor(SurvivorType.Neutral, female) end)
    if not d then pcall(function() d = SurvivorFactory.CreateSurvivor(); d:setFemale(female) end) end
    if not d then return nil end
    pcall(function() d:setFemale(female) end)
    pcall(function() d:getWornItems():clear() end)
    pcall(function() d:getHumanVisual():setHairModel("Bald") end)
    pcall(function() d:getHumanVisual():setBeardModel("") end)
    return d
end
local P = ISPanel:derive("ZeDQAAvatar")
function P:prerender() self:drawRect(0, 0, self.width, self.height, 1, 0, 1, 0) end
function P:render() end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local p = P:new(0, 0, sw, sh)
p:initialise(); p:addToUIManager(); p:bringToTop()
p.models = {}
for i, female in ipairs({ false, true }) do
    local d = desc(female)
    local m = ISUI3DModel:new(sw / 2 - 520 + (i - 1) * 540, 20, 500, sh - 40)
    m:initialise(); m:instantiate()
    p:addChild(m)
    m:setState("idle"); m:setDirection(IsoDirections.S); m:setIsometric(false)
    pcall(function() m:setDoRandomExtAnimations(false) end)
    m:setAnimateWhilePaused(true)
    if d then m:setSurvivorDesc(d) end
    p.models[i] = m
    say((female and "female" or "male") .. " desc " .. tostring(d ~= nil))
end
local k = 0
local function tick()
    k = k + 1
    p:bringToTop()
    if k == 240 then
        pcall(function() getCore():TakeFullScreenshot("zqa_avatar.png") end)
        say("shot " .. sw .. "x" .. sh)
    elseif k == 260 then
        p:removeFromUIManager()
        Events.OnRenderTick.Remove(tick)
        say("DONE")
    end
end
Events.OnRenderTick.Add(tick)
