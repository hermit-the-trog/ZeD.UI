-- ZeDUI/tools/qa/zedqa_etp.lua  (Nov 8 2026, Build; tag etp): Ellie's Tattoo Parlor V4 with ZeD's Make Up rows
-- (punch list 116), in the mod list etp_mods.txt (mod id Ellie'sTattooParlor, ZeD last). Read-only except a lipstick
-- and a mirror it adds to the bag and takes back. It reports (ZEDQA etp PASS / FAIL / info lines):
--   0. the mod is on, ZeD is on, ZeD's make-up part is loaded
--   1. ZeD.MakeUp.mirror(player) with no mirror (the stand-in item): false with a reason (the patch used to error on the
--      stand-in; the error shows in console.txt as a "makeup mirror" line from ZeD.logOnce)
--   2. with a mirror in the bag: true. Before the fix the rows read "needs a mirror" here
--   3. ZeD.MakeUp.rows(player) with the lipstick and the mirror: the Apply rows are not greyed; shot of the Identity tab's
--      Make Up part
-- Shots zqa_etp_*.png in Zomboid/Screenshots. grep "ZEDQA etp ".
local function say(s) print("ZEDQA etp " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_etp_" .. n .. ".png") end); say("shot " .. n) end
local active = {}
do local list = getActivatedMods(); for i = 0, list:size() - 1 do active[(tostring(list:get(i)):gsub("^\\", ""))] = true end end
local steps = {}
local function step(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local P, lipstick, mirror = nil, nil, nil

step(5, function()
    P = getPlayer()
    say("mods: Ellie's=" .. tostring(active["Ellie'sTattooParlor"] == true) .. " ZeD_UI=" .. tostring(active.ZeD_UI == true)
        .. "; ZeD.MakeUp loaded: " .. tostring(ZeD ~= nil and ZeD.MakeUp ~= nil))
    check(active["Ellie'sTattooParlor"] and ZeD and ZeD.MakeUp, "the mod and ZeD's make-up are on")
    say("doMakeUpMenu: " .. tostring(ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.doMakeUpMenu))
    if getGameSpeed() <= 0 then setGameSpeed(1) end
end)
step(10, function()
    -- no mirror to start: a carried one is taken out of the way (put back at the end)
    mirror = P:getInventory():getFirstType("Mirror")
    if mirror then P:getInventory():Remove(mirror); say("a mirror taken out of the bag for the first check") end
    local ok, why = ZeD.MakeUp.mirror(P, nil)
    say("no mirror: ok=" .. tostring(ok) .. " why=" .. tostring(why))
    -- (a world mirror within reach also reads true: the character stands on the QA site, none)
    check(ok == false and why ~= nil, "no mirror: false, with a reason")
end)
step(10, function()
    lipstick = P:getInventory():AddItem("Base.Lipstick")
    local m = P:getInventory():AddItem("Base.Mirror")
    local ok, why = ZeD.MakeUp.mirror(P, nil)
    check(ok == true, "a mirror in the bag: true (was: needs a mirror) " .. tostring(why))
    local ok2, why2 = ZeD.MakeUp.mirror(P, lipstick)
    check(ok2 == true, "the lipstick as the item: true " .. tostring(why2))
    local rows = ZeD.MakeUp.rows(P, lipstick)
    local n, bad = 0, 0
    for _, r in ipairs(rows) do
        if r.verb == "Apply" then n = n + 1; if not r.ok then bad = bad + 1 end end
    end
    say("rows: " .. #rows .. ", Apply rows " .. n .. ", greyed " .. bad)
    check(n > 0 and bad == 0, "the Apply rows are not greyed")
    pcall(function() ZeD.MakeUp.open(P, lipstick) end)
    P:getInventory():Remove(m)
end)
step(60, function() shot("makeup") end)
step(10, function()
    if lipstick then P:getInventory():Remove(lipstick) end
    if mirror then P:getInventory():AddItem(mirror) end
    say("by hand: console.txt has no 'makeup mirror' and no ETPMakeUpUIFix error line")
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)
local qi, wait = 1, nil
local function tick()
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
