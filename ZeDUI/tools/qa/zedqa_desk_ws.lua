-- ZeDUI/tools/qa/zedqa_desk_ws.lua  (Oct 21 2026): at the main menu, the desk for the
-- Workshop gallery: waits ~8 s of menu frames (the monitor switching on, the icons
-- and the save picture arriving), then one full screenshot, ws_35_desk.png.
-- Main menu only (OnFETick), so never unattended. grep "ZEDQA wsd".
local n = 0
local function t()
    n = n + 1
    if n == 480 then
        local ok, e = pcall(function() getCore():TakeFullScreenshot("ws_35_desk.png") end)
        print("ZEDQA wsd 35 desk " .. (ok and "ok" or ("ERR " .. tostring(e))))
        print("ZEDQA wsd DONE")
        Events.OnFETick.Remove(t)
    end
end
Events.OnFETick.Add(t)
print("ZEDQA wsd start")
