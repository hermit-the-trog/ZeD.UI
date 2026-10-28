-- ZeDUI/tools/qa/zedqa_wallpaper.lua  (Oct 28 2026)
-- MAIN MENU ONLY (zedqa_menu_mods_run.ps1 -ModList mods_none.txt -Script ... -Tag wp):
-- the desk's wallpaper is drawn from the game's own title pictures (media/ui/Title*.png,
-- four tiles each for the painting and its lightning frame), not from copies in the mod.
-- Checks: the mod no longer blanks the game's files (each tile has its real size), the
-- desk's pictures count as ready, the Original wallpaper draws, a lightning strike draws
-- over it, the New wallpaper (the video) still works, and Original comes back.
-- Shots: zqa_wp_*.png in Zomboid/Screenshots. grep "ZEDQA wp".
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA wp " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_wp_" .. n .. ".png") end); say("shot zqa_wp_" .. n .. ".png") end
local pass, fail = 0, 0
local function check(name, ok, detail)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. name .. (detail and (" (" .. tostring(detail) .. ")") or ""))
end
local TILES = {
    { "media/ui/Title.png", 1024, 1024 }, { "media/ui/Title2.png", 896, 1024 },
    { "media/ui/Title3.png", 1024, 56 }, { "media/ui/Title4.png", 896, 56 },
    { "media/ui/Title_lightning.png", 1024, 1024 }, { "media/ui/Title_lightning2.png", 896, 1024 },
    { "media/ui/Title_lightning3.png", 1024, 56 }, { "media/ui/Title_lightning4.png", 896, 56 },
}
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local wallWas

at(2, function()
    wallWas = MM.wallpaper()
    say("wallpaper was " .. tostring(wallWas) .. ", video effects " .. tostring(getCore():getOptionDoVideoEffects()))
    MM.showView("main")
    MM.setWallpaper("original")
    for _, tile in ipairs(TILES) do
        local tx = getTexture(tile[1])
        local w, h = tx and tx:getWidth() or -1, tx and tx:getHeight() or -1
        check("the game's own " .. tile[1] .. " loads at its size", tx ~= nil and w == tile[2] and h == tile[3], w .. "x" .. h)
    end
    check("no copy of the painting in the mod", getTexture("media/textures/ZeD/mainmenu/wallpaper.png") == nil)
end)
at(40, function()
    check("the desk's pictures are ready", MM.assetsReady() == true)
    shot("01_original")
end)
at(50, function()
    -- a lightning strike now (the bridge's handle on the desk's small life)
    local life = MM._life
    if life and life.zap then life.zap.nextAt = 0 end
    say("lightning asked for")
end)
at(56, function() shot("02_lightning") end)
at(70, function() MM.setWallpaper("new") end)
at(130, function()
    check("New wallpaper set", MM.wallpaper() == "new", MM.wallpaper())
    shot("03_new_video")
end)
at(140, function() MM.setWallpaper("original") end)
at(170, function()
    check("Original wallpaper back", MM.wallpaper() == "original", MM.wallpaper())
    shot("04_original_again")
end)
at(180, function()
    if wallWas and wallWas ~= MM.wallpaper() then MM.setWallpaper(wallWas) end
    say(string.format("%d pass, %d fail", pass, fail))
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
    if t > 190 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
