-- ZeDUI/tools/qa/zedqa_immersive_moodles.lua  (Nov 2 2026, QA; punch list 53, Immersive Moodles support)
-- In game with Immersive Moodles (mod id ImmersiveMoodles) on. Moodles raised (hunger, thirst, tiredness, boredom,
-- stress), then:
--   each ZeD Moodles place (right, left, bottom): ZeD's layer hidden (_show false), M.rect nil, the game's column
--   parked by the mod (x below -10000), the mod's HUD panel on, no ZeD chip drawn (ZeD_MoodleLayer._drawChip counted);
--   a level change (hunger up): still no ZeD chip;
--   the corner watch worn, the mod on the right: the mod's top offset reads at least the watch's bottom + T.px(10);
--   ZeD's safe mode on: ZeD steps aside, the mod still draws, no chip; off again: as before;
--   the mod's HUD off (as its "Show Immersive HUD" off does at load: hudOff true, no HUD panel): ZeD's moodles back
--   (its layer shown, the game's column on screen), and a chip on a level change; then the HUD put back.
-- Everything is put back: stats, the places, the watch (removed), safe mode, the mod's HUD.
-- grep "ZEDQA imo"; shots zqa_imo_*.png. The support's own load line is grepped from console.txt by QA.
local function say(s) print("ZEDQA imo " .. tostring(s)) end
local p = getPlayer()
local MO = ZeD and ZeD.Moodles
local Sx = ZeD and ZeD.Settings
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_imo_" .. n .. ".png") end); say("shot zqa_imo_" .. n) end
local IM = type(ImmersiveMoodles) == "table" and ImmersiveMoodles or nil
local SUP = ZeD and ZeD.ModSupport and ZeD.ModSupport.ImmersiveMoodles
if not (p and MO and Sx and Sx.moodlePlaceOption) then say("ERR ZeD.Moodles is not loaded"); say("DONE"); return end
if not IM then say("ERR Immersive Moodles is not loaded (no ImmersiveMoodles table)"); say("DONE"); return end
check(SUP ~= nil, "ZeD's Immersive Moodles support is loaded (ZeD.ModSupport.ImmersiveMoodles)")
check(IM._zedWrapped == true, "the mod's option reader is wrapped")

local placeOpt, watchOpt, safeOpt = Sx.moodlePlaceOption, Sx.watchPlaceOption, Sx.safeModeOption
local placeWas = placeOpt:getValue()
local watchWas = watchOpt and watchOpt:getValue()
local safeWas = safeOpt and safeOpt:getValue()
local st = p:getStats()
local WANT = { HUNGER = 0.45, THIRST = 0.45, FATIGUE = 0.75, BOREDOM = 0.6, STRESS = 0.6 }
local kept = {}
for k in pairs(WANT) do pcall(function() kept[k] = st:get(CharacterStat[k]) end) end
local watchItem
local godWas = p:isGodMod()   -- (god mode holds the stats at zero: off while the test runs, as zedqa_moodles does)

-- ZeD's chips, counted (the hover note and the level-change notice are both drawn by _drawChip)
local chips = 0
local origChip = ZeD_MoodleLayer._drawChip
ZeD_MoodleLayer._drawChip = function(self, ...) chips = chips + 1; return origChip(self, ...) end

local function layer() return MO.getLayer(0) end
local function vanillaUI() return UIManager.getMoodleUI and UIManager.getMoodleUI(0) or nil end
local function hudPanel() local e = IM.elements and IM.elements[0]; return e and e[2] or nil end
local function state(label)
    local L, v, h = layer(), vanillaUI(), hudPanel()
    say(label .. ": ZeD layer shown " .. tostring(L and L._show) .. " | M.rect " .. tostring(MO.rect(0) ~= nil)
        .. " | game column " .. tostring(v and (math.floor(v:getX()) .. "," .. math.floor(v:getY())))
        .. " | mod HUD panel " .. tostring(h ~= nil) .. " hudOff " .. tostring(IM.hudOff)
        .. " | support drawing " .. tostring(SUP and SUP.drawing(0)) .. " | moodles " .. #MO.active(p) .. " | chips " .. chips)
end
local function modDraws(label)
    local L, v, h = layer(), vanillaUI(), hudPanel()
    state(label)
    check(L and L._show == false, label .. ": ZeD draws no moodles (layer hidden)")
    check(MO.rect(0) == nil, label .. ": ZeD's moodle rect is nil")
    check(v and v:getX() < -10000, label .. ": the game's column is parked off screen by the mod")
    check(h ~= nil and IM.hudOff == false, label .. ": the mod's HUD panel is on")
    check(chips == 0, label .. ": no ZeD note drawn (" .. chips .. ")")
    check(#MO.active(p) >= 3, label .. ": at least three moodles are up (" .. #MO.active(p) .. ")")
end

local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

step(5, function()
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    p:setGodMod(false)
    for k, v in pairs(WANT) do pcall(function() st:set(CharacterStat[k], v) end) end
    placeOpt:setValue(1)
    if watchOpt then watchOpt:setValue(1) end
    pcall(function() Mouse.setXY(5, 5) end)
end)
-- the three places
for i, name in ipairs({ "right", "left", "bottom" }) do
    step(5, function() placeOpt:setValue(i); chips = 0 end)
    step(60, function() modDraws("ZeD place " .. name); shot("place_" .. name) end)
end
-- a level change, ZeD place right
step(5, function() placeOpt:setValue(1); chips = 0; pcall(function() st:set(CharacterStat.HUNGER, 0.8) end) end)
step(90, function() modDraws("after a hunger level change") end)
-- the corner watch, the mod on the right
step(5, function()
    watchItem = p:getInventory():AddItem("Base.WristWatch_Left_DigitalBlack")
    p:setWornItem(watchItem:getBodyLocation(), watchItem)
    if watchOpt then watchOpt:setValue(2) end
end)
step(60, function()
    local w = ZeD.Watch and ZeD.Watch.getInstance and ZeD.Watch.getInstance()
    local side = IM.opt("HudSide", 1)
    local raw = IM.vals and IM.vals.HudOffsetY
    local got = IM.opt("HudOffsetY", 0)
    if w and w:getIsVisible() then
        local want = math.floor(w:getY() + w:getHeight() - getPlayerScreenTop(0) + ZeD.T.px(10))
        say("corner watch " .. math.floor(w:getX()) .. "," .. math.floor(w:getY()) .. " " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight())
            .. " | mod side " .. tostring(side) .. " | its top offset: set " .. tostring(raw) .. ", read " .. tostring(got) .. " | the watch wants " .. want)
        check(side ~= 1 or (tonumber(got) or 0) >= want, "the mod's column starts below the corner watch (top offset " .. tostring(got) .. " >= " .. want .. ")")
    else
        check(false, "the corner watch shows (worn watch, Watch place Corner)")
    end
    shot("corner_watch")
end)
-- safe mode on, then off
step(5, function()
    if not safeOpt then say("NOTE no safe mode option"); return end
    safeOpt:setValue(2); pcall(ZeD.Safe.reread); chips = 0
end)
step(60, function()
    state("safe mode on")
    local v, h = vanillaUI(), hudPanel()
    check(ZeD.Safe.on() == true, "safe mode is on")
    check(h ~= nil and v and v:getX() < -10000, "safe mode: the mod still draws its moodles and parks the game's column")
    check(chips == 0, "safe mode: no ZeD note drawn (" .. chips .. ")")
    shot("safe_on")
end)
step(5, function() if safeOpt then safeOpt:setValue(1); pcall(ZeD.Safe.reread); chips = 0 end end)
step(60, function() check(not ZeD.Safe.on(), "safe mode is off again"); modDraws("safe mode off") end)
-- the mod's HUD off (what its "Show Immersive HUD" off does when a game loads), then back on
local hudKept
step(5, function()
    if watchOpt then watchOpt:setValue(1) end
    hudKept = hudPanel()
    IM.hudOff = true
    if hudKept then pcall(function() hudKept:removeFromUIManager() end) end
    IM.elements[0] = { IM.elements[0][1] }
    chips = 0
end)
step(60, function()
    state("the mod's HUD off")
    local L, v = layer(), vanillaUI()
    check(SUP.drawing(0) == false, "HUD off: the support says the mod is not drawing")
    check(L and L._show == true, "HUD off: ZeD shows the moodles again")
    check(v and v:getX() > -10000, "HUD off: the game's column is on screen where ZeD puts it (" .. tostring(v and math.floor(v:getX())) .. ")")
    shot("hud_off")
    chips = 0
    pcall(function() st:set(CharacterStat.HUNGER, 0.45) end)
end)
step(90, function()
    local on = Sx.moodleNoticesOn and Sx.moodleNoticesOn()
    say("HUD off, after a hunger level change: chips " .. chips .. " (Moodle notices " .. tostring(on) .. ")")
    if on then check(chips > 0, "HUD off: ZeD's note shows on a level change") end
    shot("hud_off_notice")
end)
step(5, function()
    IM.hudOff = false
    if hudKept then pcall(function() hudKept:addToUIManager() end); IM.elements[0] = { IM.elements[0][1], hudKept } end
    chips = 0
end)
step(60, function() modDraws("the mod's HUD back on") end)
-- put back
step(5, function()
    ZeD_MoodleLayer._drawChip = origChip
    for k, v in pairs(kept) do pcall(function() st:set(CharacterStat[k], v) end) end
    p:setGodMod(godWas)
    placeOpt:setValue(placeWas)
    if watchOpt and watchWas ~= nil then watchOpt:setValue(watchWas) end
    if safeOpt and safeWas ~= nil then safeOpt:setValue(safeWas); pcall(ZeD.Safe.reread) end
    if watchItem then
        pcall(function() p:removeWornItem(watchItem) end)
        pcall(function() p:getInventory():Remove(watchItem) end)
    end
end)
step(20, function()
    say("put back: place " .. tostring(placeOpt:getValue()) .. ", watch " .. tostring(watchOpt and watchOpt:getValue()) .. ", safe " .. tostring(ZeD.Safe.on()))
    say("summary: " .. passes .. " PASS, " .. fails .. " FAIL")
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
