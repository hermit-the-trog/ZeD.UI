-- ZeDUI/tools/qa/gallery_v3_desk.lua  (Oct 21 2026)
-- MAIN MENU ONLY, hand-pushed through the QA bridge (never unattended: it runs on OnFETick
-- and changes the wallpaper choice, which it puts back). The ZeD OS desk for the Workshop
-- gallery, screenshots only, no button pressed:
--   zed_90  the desk on the original painting        zed_91  Settings menu open (the wallpaper choice)
--   zed_92  the desk on the Build 42 title video     zed_93  Settings menu open on it
--   zed_94  the Trash window open, the Computer in it (Empty Trash is not pressed)
-- The wallpaper is set back to what it was (Zomboid/Lua/ZeD_wallpaper.txt). "ZEDQA g3d ... DONE".
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA g3d " .. tostring(s)) end
local function shot(n)
    local ok, e = pcall(function() getCore():TakeFullScreenshot(n .. ".png") end)
    say("shot " .. n .. " " .. (ok and "ok" or ("ERR " .. tostring(e))))
end
local was = MM.wallpaper()
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function settle() MM.ctx.open = nil; MM.showView("main") end

at(2, function()
    say("wallpaper was " .. tostring(was) .. " | video effects " .. tostring(getCore():getOptionDoVideoEffects()))
    if MM.wallpaper() ~= "original" then MM.setWallpaper("original") end
    settle()
end)
at(240, function() shot("zed_90_desk_painting") end)
at(250, function() MM.ctx.open = "settings" end)
at(300, function() shot("zed_91_desk_wallpaper_menu_painting") end)
at(310, function() MM.ctx.open = nil; MM.setWallpaper("new"); settle() end)
at(700, function() shot("zed_92_desk_video") end)
at(710, function() MM.ctx.open = "settings" end)
at(760, function() shot("zed_93_desk_wallpaper_menu_video") end)
at(770, function() MM.ctx.open = nil; MM.setWallpaper("original"); MM.showView("trash") end)
at(860, function() shot("zed_94_desk_trash_computer") end)
at(870, function()
    MM.showView("main")
    if was ~= MM.wallpaper() then MM.setWallpaper(was) end
    say("wallpaper back to " .. tostring(MM.wallpaper()))
    say("DONE")
end)

local function tick()
    t = t + 1
    for _, s in ipairs(steps) do
        if s.n == t then
            local ok, e = pcall(s.fn)
            if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end
        end
    end
    if t > 880 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
