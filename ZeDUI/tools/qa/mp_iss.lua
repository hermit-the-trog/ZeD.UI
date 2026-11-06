-- ZeDUI/tools/qa/mp_iss.lua  (Nov 5 2026, QA; punch list 89): on a server the license's ISS is the server's start date, not 2012; the left edge with the
-- safety system on. Picture mis_license.png. grep "ZEDQA mis".
local function say(s) print("ZEDQA mis " .. tostring(s)) end
local I = ZeD.IdentityTab
local CWm = ZeD_CharacterWindow
local n = 0
local function W() return CWm.getWindow() end
if not CWm.isOpen() then CWm.toggleBothPaired(0) end
local function t()
    n = n + 1
    if n == 120 then local w = W(); w._activeTab = "identity"; w._drawerMode = "tab"; w._drawerOpen = true; I.qaStyle = "immersive" end
    if n == 420 then
        local d = I.gatherData(getPlayer())
        say("ISS " .. tostring(d.issStr) .. ", EXP " .. tostring(d.expStr) .. ", game year " .. tostring(getGameTime():getYear()) .. ", start year " .. tostring(pcall(function() return getGameTime():getStartYear() end)))
        pcall(function() getCore():TakeFullScreenshot("mis_license.png") end)
    end
    if n == 480 then I.qaStyle = nil; Events.OnTick.Remove(t); say("DONE") end
end
Events.OnTick.Add(t)
