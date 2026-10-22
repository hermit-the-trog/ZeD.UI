-- ZeDUI/tools/qa/gallery_v4_upload.lua  (Oct 22 2026)
-- MAIN MENU ONLY, hand-pushed. After gallery_v4_menus.lua: hot-reloads ZeD_MainMenuWorkshop.lua
-- (the Upload button fix) onto the open window, then the upload window again with the tall
-- monitor, and the strip's upload question. The question is answered Cancel: NOTHING is sent
-- to Steam (upload() is never called). Shots mm4_15/16. "ZEDQA g4u ... DONE".
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA g4u " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("mm4_" .. n .. ".png") end) end
reloadLuaFile("media/lua/client/ZeD/ZeD_MainMenuWorkshop.lua")
if MM.root.workshopWin then setmetatable(MM.root.workshopWin, ZeD_MMWorkshop) end
local steps, t, T0 = {}, 0, 0
local function at(n, fn) T0 = T0 + n; steps[#steps + 1] = { n = T0, fn = fn } end
local function WS() return MM.root.workshopWin end
at(2, function()
    local L = MM.layout()
    L.th = getCore():getScreenHeight() - L.ty - math.floor(L.s * 4)
    MM.act.workshop()
end)
at(30, function()
    local w = WS()
    for i, it in ipairs(w.items) do if tostring(it:getTitle()) == "Sample Loot Tables" then w:pick(i) end end
    w.fscroll = 0
    say("blocker " .. tostring(w:blocker()))
end)
at(20, function() shot("15_upload_ready") end)
at(10, function() WS():setConfirm("upload") end)
at(20, function() shot("16_upload_ask") end)
at(10, function() WS():setConfirm(false) end)
at(10, function() WS():back() end)
at(20, function() MM._layout = nil; say("view " .. tostring(MM.view)); say("DONE") end)
local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > T0 + 5 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
