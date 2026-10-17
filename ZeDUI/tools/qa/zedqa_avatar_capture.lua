-- ZeDUI/tools/qa/zedqa_avatar_capture.lua  (Oct 17 2026)
-- Captures the character's full-body 3D model (the Identity tab's ISUI3DModel set-up, full-body
-- camera) on a flat dark backdrop, front and three-quarter, for mockups. grep "ZEDQA av";
-- Screenshots/zqa_av_*.png. Takes it all back.
local p = getPlayer()
local function say(s) print("ZEDQA av " .. tostring(s)) end
local t, bg, m = 0, nil, nil
local function tick()
    t = t + 1
    if t == 2 then
        local u = UIManager.getUI()
        for i = 0, u:size() - 1 do local e = u:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
        local w = ZeD_CharacterWindow.getWindow(); if w and w:isVisible() then ZeD_CharacterWindow.toggleBothPaired(0) end
        bg = ISPanel:new(700, 160, 520, 760)
        bg.backgroundColor = { r = 0.086, g = 0.094, b = 0.102, a = 1 }; bg.borderColor = { r = 0, g = 0, b = 0, a = 0 }
        bg:initialise(); bg:addToUIManager()
        m = ISUI3DModel:new(710, 170, 500, 740)
        m:initialise(); m:instantiate()
        m:setState("idle"); m:setDirection(IsoDirections.S); m:setIsometric(false)
        m:setZoom(0); m:setYOffset(0)
        m:setCharacter(p)
        m:addToUIManager(); m:setVisible(true); m.javaObject:setVisible(true)
    end
    if t == 60 then getCore():TakeFullScreenshot("zqa_av_front.png"); m:setDirection(IsoDirections.SE) end
    if t == 100 then getCore():TakeFullScreenshot("zqa_av_three_quarter.png") end
    if t == 105 then m:removeFromUIManager(); bg:removeFromUIManager(); Events.OnTick.Remove(tick); say("DONE") end
end
Events.OnTick.Add(tick)
say("start")
