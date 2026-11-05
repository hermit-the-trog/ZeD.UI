-- ZeDUI/tools/qa/mp_smoke.lua  (Nov 5 2026, QA; multiplayer): on the multiplayer client (zedqa_run.ps1 -Mp), what the
-- game says about the session, and whether ZeD's windows open and draw. grep "ZEDQA mps".
local function say(s) print("ZEDQA mps " .. tostring(s)) end
local p = getPlayer()
say("isClient " .. tostring(isClient()) .. " isServer " .. tostring(isServer()) .. " coop " .. tostring(isCoopHost and isCoopHost()))
pcall(function() say("player " .. tostring(p:getUsername()) .. " access " .. tostring(p:getAccessLevel()) .. " at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()) .. "," .. math.floor(p:getZ())) end)
pcall(function() say("online players " .. tostring(getOnlinePlayers():size())) end)
pcall(function() say("ZeD loaded " .. tostring(ZeD ~= nil) .. " version " .. tostring(ZeD and ZeD.VERSION)) end)
local n = 0
local steps = {
    [20] = function()
        local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow()
        if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    end,
    [80] = function()
        local cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
        say("character window " .. tostring(cw and cw:isVisible()) .. ", world window " .. tostring(ww and ww:isVisible()))
        say("tabs " .. tostring(cw and cw._activeTab) .. " / " .. tostring(ww and ww._activeTab))
        local inv = p:getInventory()
        say("inventory items " .. tostring(inv:getItems():size()))
        pcall(function() getCore():TakeFullScreenshot("mp_smoke_windows.png") end)
    end,
    [140] = function() say("DONE") end,
}
local function t()
    n = n + 1
    if steps[n] then local ok, e = pcall(steps[n]); if not ok then say("ERR " .. tostring(e)) end end
    if n >= 140 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
