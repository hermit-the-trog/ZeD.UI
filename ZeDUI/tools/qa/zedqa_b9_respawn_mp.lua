-- ZeDUI/tools/qa/zedqa_b9_respawn_mp.lua  (Nov 8 2026, QA; beta 9 freeze exception): on the local test server, joined FROM THE MAIN MENU
-- (not a restart of the game in between: the bug needs the main menu's desk still held in ZeD.MainMenu.root).
-- Found on the Mac rig: after joining a server, dying and pressing Restart showed the game's SELECT SPAWN LOCATION screen, because
-- Overrides/Respawn.lua (R.begin) saw the main menu's leftover desk and thought a desk was already up.
-- THIS SCRIPT KILLS THE QA CHARACTER on the server (the zedqa_mp world; never the director's ZeD-QA save: run it with -Mp only).
--   1 before: the leftover (MM.root held, hidden or not on the pause menu's MainScreen), no respawn running
--   2 the character dies, the death screen comes up; Restart is pressed as the button does (ISPostDeathUI.onRespawn)
--   3 ZeD's respawn desk is up (MM.respawn, a desk with .respawn, visible), the Spawn window shows, and the game's own
--     "select spawn location" screen (CoopMapSpawnSelect) is NOT visible
--   4 Back on Spawn: the desk is down, the death screen is back, and MM.root is what it was before (the leftover, not nil)
-- Pictures: zqa_b9rsp_*.png. After it, the QA character is still dead on the death screen: the rest (Spawn, Traits, Looks, Play on the
-- server) is by hand, or quit to the main menu and join again to go on; Back to the main menu after quitting the server should show the
-- ZeD desk as usual (step 5 by hand: Exit on the death screen, then the main menu desk must be there and work).
-- grep "ZEDQA b9rsp".
local TAG = "b9rsp"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local passes, misses = 0, 0
local function check(ok, what, d)
    ok = ok and true or false
    if ok then passes = passes + 1 else misses = misses + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b9rsp_" .. n .. ".png") end) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local p = getPlayer()
local pn = p and p:getPlayerNum() or 0
local MM, R = ZeD and ZeD.MainMenu, ZeD and ZeD.Respawn
if not (p and MM and R) then say("ERR no player or ZeD's respawn is not loaded"); say("DONE"); return end

local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end
local function waitFor(max, cond, fn) Q[#Q + 1] = { max = max, cond = cond, fn = fn } end
local ticker
local function onTick()
    local s = Q[qi]
    if not s then
        Events.OnTick.Remove(ticker)
        say("checks: passes=" .. passes .. " misses=" .. misses)
        say("DONE")
        return
    end
    qc = qc + 1
    local go, timedOut = false, false
    if s.cond then
        local ok, v = pcall(s.cond)
        if ok and v then go = true elseif qc >= s.max then go, timedOut = true, true end
    else
        go = qc >= s.wait
    end
    if go then
        qi = qi + 1; qc = 0
        local ok, e = pcall(s.fn, timedOut)
        if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(e)) end
    end
end

local before, death
step(1, function()
    check(isClient and isClient() or false, "this is a server game (joined, not single player)")
    local ms = MainScreen and MainScreen.instance
    check(ms ~= nil and ms.inGame == true, "the game is running (MainScreen.inGame)")
    check(MM.respawn == nil, "no respawn is running now")
    before = MM.root
    say("NOTE MM.root before: " .. tostring(before) .. (before and (" visible=" .. tostring(safe(function() return before:isVisible() end))) or " (nil: the main menu desk was never built, or safe mode; then this run proves little)"))
    check(before ~= nil, "the main menu's leftover desk is still held (the state the bug needs)")
    -- the character dies: the engine's death, so the real death screen comes up
    pcall(function() p:setGodMod(false) end)
    local ok = pcall(function() p:getBodyDamage():setOverallBodyHealth(0) end)
    pcall(function() p:setHealth(0) end)
    say("NOTE death asked (health set: " .. tostring(ok) .. ")")
end)
waitFor(1800, function() return ISPostDeathUI and ISPostDeathUI.instance and ISPostDeathUI.instance[pn] ~= nil end, function(timedOut)
    death = ISPostDeathUI.instance and ISPostDeathUI.instance[pn]
    check(not timedOut and death ~= nil, "the death screen came up", timedOut and "timed out after 1800 ticks; kill the character by hand and run the rest" or nil)
    if not death then return end
end)
step(30, function()
    shot("01_death")
    if not death then return end
    check(safe(function() return death.buttonRespawn ~= nil or death.zedRules ~= nil end, false), "the death screen has Restart")
    say("NOTE Restart pressed")
    local ok, e = pcall(ISPostDeathUI.onRespawn, death)
    check(ok, "Restart ran without an error", e)
end)
waitFor(120, function() return MM.respawn ~= nil end, function(timedOut)
    check(not timedOut and MM.respawn ~= nil, "ZeD's respawn is running (R.begin did not stop at the leftover desk)")
end)
step(60, function()   -- (the monitor switches on first: wait until it settles before any picture)
    local d = MM.root
    check(d ~= nil and d ~= before and d.respawn == true, "MM.root is the respawn desk now", tostring(d))
    check(safe(function() return d:isVisible() end, false), "the respawn desk is visible")
    check(MM.view == "spawn", "the Spawn window shows on the desk", tostring(MM.view))
    local c = CoopCharacterCreation and CoopCharacterCreation.instance
    local gameSpawn = safe(function() return c.mapSpawnSelect:isVisible() end, false)
    check(c ~= nil and not gameSpawn, "the game's own SELECT SPAWN LOCATION screen is NOT showing")
    check(safe(function() return c:getX() <= -10000 end, false), "the game's respawn panel waits off the screen")
    shot("02_respawn_desk")
end)
step(30, function()
    if not MM.respawn then return end
    local ok, e = pcall(function() ZeD_MMSpawn.back(setmetatable({ sel = 1 }, { __index = ZeD_MMSpawn })) end)
    check(ok, "Spawn's Back ran without an error", e)
end)
step(30, function()
    check(MM.respawn == nil, "the desk is down after Back")
    check(MM.root == before, "MM.root is what it was before (the leftover, kept for the main menu)", tostring(MM.root))
    check(death ~= nil and safe(function() return death:isVisible() end, false), "the death screen is back")
    shot("03_back_on_death")
    say("MANUAL now press Exit on the death screen: the main menu's ZeD desk must show and work (Join, Options); join again to confirm")
end)

ticker = onTick
Events.OnTick.Add(ticker)
say("start")
