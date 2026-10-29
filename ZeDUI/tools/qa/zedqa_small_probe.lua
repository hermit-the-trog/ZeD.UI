-- ZeDUI/tools/qa/zedqa_small_probe.lua  (Oct 29 2026, the small-screen pass)
-- What is on the screen besides ZeD: every visible top-level UI element the game holds
-- (class, place, size), the game's own Character Info window (should be hidden under ZeD),
-- the screen size and ZeD's root scale, and both ZeD windows' rects. One screenshot with
-- the pair closed (zqa_sp_bare.png) and one with it open (zqa_sp_pair.png). In game on the
-- ZeD-QA save after zedqa_prelude.lua. Leaves the pair as it found it. grep "ZEDQA sp".
local function say(s) print("ZEDQA sp " .. tostring(s)) end
local core = getCore()
say(string.format("screen %dx%d root=%.3f", core:getScreenWidth(), core:getScreenHeight(), (ZeD and ZeD.Scale and ZeD.Scale.root()) or -1))
local function census(label)
    local ui = UIManager.getUI()
    local n = 0
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        if e:isVisible() and e:getWidth() > 0 and e:getHeight() > 0 then
            local t = e:getTable()
            local ty = tostring(t and (t.Type or t.type) or e:getClass():getSimpleName())
            n = n + 1
            say(string.format("%s el %s @%d,%d %dx%d", label, ty, math.floor(e:getX()), math.floor(e:getY()), math.floor(e:getWidth()), math.floor(e:getHeight())))
        end
    end
    say(label .. " visible elements with a size: " .. n)
end
-- the game's own Character Info window (ISCharacterInfoWindow) for player 0
local ci = nil
pcall(function() ci = getPlayerInfoPanel(0) end)
if ci then
    say(string.format("vanilla char info: visible=%s @%d,%d %dx%d visibleOnStartup=%s", tostring(ci:getIsVisible()), math.floor(ci:getX()), math.floor(ci:getY()), math.floor(ci:getWidth()), math.floor(ci:getHeight()), tostring(ci.visibleOnStartup)))
else
    say("vanilla char info: no panel (getPlayerInfoPanel nil)")
end
local CW, WW = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
local wasOpen = CW ~= nil and WW ~= nil
local function rect(name, w) if w then say(string.format("%s @%d,%d %dx%d", name, w:getX(), w:getY(), w:getWidth(), w:getHeight())) else say(name .. " not open") end end
rect("ZeD Character", CW); rect("ZeD World", WW)
census("pair")
local n = 0
local function tick()
    n = n + 1
    if n == 1 and wasOpen then ZeD_CharacterWindow.toggleBothPaired(0) end
    if n == 40 then
        census("bare")
        pcall(function() core:TakeFullScreenshot("zqa_sp_bare.png") end); say("shot zqa_sp_bare.png")
        if wasOpen then ZeD_CharacterWindow.toggleBothPaired(0) end
    end
    if n == 100 then
        pcall(function() core:TakeFullScreenshot("zqa_sp_pair.png") end); say("shot zqa_sp_pair.png")
        say("DONE"); Events.OnTick.Remove(tick)
    end
end
Events.OnTick.Add(tick)
