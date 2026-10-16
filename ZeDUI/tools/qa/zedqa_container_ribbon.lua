-- ZeDUI/tools/qa/zedqa_container_ribbon.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: the container buttons' row is one line that
-- scrolls sideways when it is wider than the column. A campfire placed beside
-- you (Take all, Same type, To floor, Light, Add fuel, Take apart) is wider
-- than the World window's usual list. Shoots the ribbon at its start, after
-- its right arrow, and with the controller's focus walked to its last button
-- (the ribbon follows); logs the row's place for a real mouse-wheel check
-- (ZEDQA cr row x y w h, screen pixels). ZEDQA_CR_STEP = "end" removes the
-- campfire and closes the windows. grep "ZEDQA cr".
local p = getPlayer()
local pn = p:getPlayerNum()
local CT = ZeD.ContainerControls
local function say(s) print("ZEDQA cr " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cr_" .. n .. ".png") end) end
local function ww() return ZeD_WorldWindow.getWindow() end
local function wc() return ww()._mainContent end
local function camp()
    return getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), 0)
end
local function ribbon()
    local cc = wc()._cc
    local L = cc and cc.layout
    local S = L and L.scroll
    return string.format("scroll %s x=%s of %s, view %s", tostring(S ~= nil), tostring(cc and cc.scrollX),
        tostring(S and S.total), tostring(S and S.viewW))
end

if (ZEDQA_CR_STEP or "run") == "end" then
    local lo = camp() and SCampfireSystem.instance:getLuaObjectOnSquare(camp())
    if lo then pcall(function() SCampfireSystem.instance:removeCampfire(lo) end) end
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    ZeD.Input.Detector.setLockedMode(nil)
    ZeD.Input.Focus.releaseFocus()
    say("DONE")
    return
end

local steps = {
    { 1, function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
        local lo = camp() and SCampfireSystem.instance:getLuaObjectOnSquare(camp())
        if not lo then lo = SCampfireSystem.instance:addCampfire(camp()) end
        say("campfire " .. tostring(lo ~= nil))
        if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    end },
    { 60, function()
        local w = ww()
        for i, c in ipairs(w._containers or {}) do
            if c.inventory and c.inventory:getType() == "campfire" then w._activeContainer = i; w._viewedContainer = nil; w._mainVisible = false end
        end
    end },
    { 40, function()
        local c = wc()
        local R = c._cc and c._cc.row
        if R then say(string.format("row %d %d %d %d", c:getAbsoluteX() + R.x, c:getAbsoluteY() + R.y, R.w, R.h)) end
        say("at the start: " .. ribbon())
        shot("01_start")
    end },
    { 5, function() CT.press(wc(), -2) end },
    { 20, function() say("after the right arrow: " .. ribbon()); shot("02_right_arrow") end },
    { 5, function() CT.press(wc(), -1); CT.press(wc(), -1); CT.press(wc(), -1) end },
    { 20, function() say("back to the start: " .. ribbon()) end },
    -- the controller walks to the last button
    { 5, function()
        local F, D = ZeD.Input.Focus, ZeD.Input.Detector
        D.setLockedMode("gamepad")
        F.claimFocus(ww())
        for zi, z in ipairs(ww()._focusRing) do
            if z.zone == "worldCtl" then ww()._focusIdx = zi; z.focusedElementIdx = #z.elements end
        end
        local el = F.getFocusedElement(ww())
        say("focused " .. tostring(el and el.id))
    end },
    { 30, function() say("focus on the last button: " .. ribbon()); shot("03_pad_last") end },
    { 5, function()
        ZeD.Input.Detector.setLockedMode(nil)
        ZeD.Input.Focus.releaseFocus()
        CT.press(wc(), -1); CT.press(wc(), -1); CT.press(wc(), -1)
        say("ready for the wheel: " .. ribbon())
    end },
}
local si, wait = 1, 0
local function t()
    local s = steps[si]
    if not s then Events.OnTick.Remove(t); return end
    wait = wait + 1
    if wait >= s[1] then
        local ok, e = pcall(s[2])
        if not ok then say("ERR step " .. si .. " " .. tostring(e)) end
        si, wait = si + 1, 0
    end
end
Events.OnTick.Add(t)
say("start")
