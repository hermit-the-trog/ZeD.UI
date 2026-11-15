-- QA (Nov 14 2026, punch list 184): A with the Place item cursor up. Binds pad 0 to player 0 if a pad is there,
-- starts Place item as the right-click menu does (onPlaceItemOnGround) with focus on ZeD's inventory window,
-- then presses A through the game's own controller path. grep "ZEDQA pla".
local function say(s) print("ZEDQA pla " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local function desc(o)
    if o == nil then return "nil" end
    local s = tostring(o._zedLabel or o.Type or o)
    local ok, v = pcall(function() return o:isReallyVisible() end)
    return s .. " visible=" .. tostring(ok and v)
end
-- 1. a pad for player 0
local jd = JoypadState.players[1]
say("pad bound before: " .. tostring(p:getJoypadBind()) .. " players[1]=" .. tostring(jd))
if not jd then
    local id = nil
    for i = 0, 15 do local c = JoypadState.controllers[i]; if c and c.connected then id = i; break end end
    say("connected controller id " .. tostring(id))
    if id ~= nil then
        pcall(function() triggerEvent("OnJoypadActivate", id) end)
        jd = JoypadState.players[1] or JoypadState.joypads[1]
        if jd and not JoypadState.players[1] then
            pcall(function() p:setJoypadBind(id); jd.player = 0; JoypadState.players[1] = jd end)
        end
    end
end
jd = JoypadState.players[1]
say("pad bound after: " .. tostring(p:getJoypadBind()) .. " players[1]=" .. tostring(jd))
if not jd then say("ERR no pad data for player 0 (no controller connected?)"); say("DONE"); return end
-- 2. an item, the ZeD inventory window up and focused (where the right-click menu leaves the pad)
local item = p:getInventory():AddItem("Base.Mug")
pcall(function() if ZeD.toggleBothPaired and not (ZeD.charWin and ZeD.charWin:isReallyVisible()) then ZeD.toggleBothPaired(0) end end)
local tries = 0
local wraps = {}
local origA = ISButtonPrompt and ISButtonPrompt.onAPress
if origA then ISButtonPrompt.onAPress = function(self, ...) say("ISButtonPrompt.onAPress ran"); return origA(self, ...) end end
local orig3 = ISPlace3DItemCursor and ISPlace3DItemCursor.onJoypadPressButton
if orig3 then ISPlace3DItemCursor.onJoypadPressButton = function(self, ...) say("cursor onJoypadPressButton ran"); return orig3(self, ...) end end
local origTB = ISPlace3DItemCursor and ISPlace3DItemCursor.tryBuild
if origTB then ISPlace3DItemCursor.tryBuild = function(self, ...) say("cursor tryBuild ran"); return origTB(self, ...) end end
local n = 0
local function tick()
    n = n + 1
    if n == 60 then
        local w = ZeD.charWin or (ZeD.windowsFor and ZeD.windowsFor(0) and ZeD.windowsFor(0)[1])
        if w then pcall(function() setJoypadFocus(0, w) end) end
        say("focus before place: " .. desc(jd.focus))
        local items = { item }
        ISInventoryPaneContextMenu.onPlaceItemOnGround(items, p)
        say("after onPlaceItemOnGround: focus " .. desc(jd.focus) .. " | drag " .. tostring(getCell():getDrag(0) and (getCell():getDrag(0).Type or getCell():getDrag(0))))
    elseif n == 120 then
        say("at A: focus " .. desc(jd.focus) .. " | drag " .. tostring(getCell():getDrag(0) and (getCell():getDrag(0).Type or getCell():getDrag(0))))
        local ctl = nil
        for i = 0, 15 do local c = JoypadState.controllers[i]; if c and c.joypad == jd then ctl = c end end
        if not ctl then say("ERR no controller object for the pad"); n = 200 return end
        local ok, e = pcall(function() ctl:onPressButton(Joypad.AButton) end)
        say("A pressed via controller:onPressButton ok=" .. tostring(ok) .. " " .. tostring(e))
    elseif n == 180 then
        say("after A: focus " .. desc(jd.focus) .. " | drag " .. tostring(getCell():getDrag(0)) .. " | mug in inventory " .. tostring(p:getInventory():contains(item)) .. " | sitting " .. tostring(p:isSitOnGround() or (p.isSittingOnFurniture and p:isSittingOnFurniture())))
        pcall(function() local d = getCell():getDrag(0); if d then d:exitCursor() end end)
        if origA then ISButtonPrompt.onAPress = origA end
        if orig3 then ISPlace3DItemCursor.onJoypadPressButton = orig3 end
        if origTB then ISPlace3DItemCursor.tryBuild = origTB end
        Events.OnTick.Remove(tick)
        say("DONE")
    end
end
Events.OnTick.Add(tick)
say("start")
