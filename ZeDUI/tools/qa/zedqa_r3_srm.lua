-- ZeDUI/tools/qa/zedqa_r3_srm.lua  (Oct 26 2026, compatibility round 3)
-- Smart Radial Menu's own radial (SRMRadialMenu.showRadialMenu), with ZeD on (zedqa_mods_run.ps1) or off
-- (zedqa_off_run.ps1 -Tag srm): does it open, does it error. Picture zqa_srm_<on|off>.png. grep "ZEDQA srm".
local function say(s) print("ZEDQA srm " .. tostring(s)) end
local p = getPlayer()
local zed = ZeD ~= nil and ZeD_CharacterWindow ~= nil
local n, opened = 0, false
local function tick()
    n = n + 1
    if n == 30 then
        if getGameSpeed() <= 0 then setGameSpeed(1) end
        local ok, e = pcall(function() SRMRadialMenu.showRadialMenu(p) end)
        say("show " .. tostring(ok) .. " " .. tostring(e))
        local m = getPlayerRadialMenu(0)
        say("radial menu " .. tostring(m and m.Type) .. ", javaObject " .. tostring(m and m.javaObject ~= nil) .. ", visible " .. tostring(m and m:isReallyVisible()))
    elseif n == 90 then
        pcall(function() getCore():TakeFullScreenshot("zqa_srm_" .. (zed and "on" or "off") .. ".png") end)
    elseif n == 120 then
        pcall(function() getPlayerRadialMenu(0):undisplay() end)
        Events.OnRenderTick.Remove(tick); say("DONE")
    end
end
Events.OnRenderTick.Add(tick)
say("start, ZeD " .. tostring(zed))
