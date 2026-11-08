-- ZeDUI/tools/qa/zedqa_b8_respawn_smoke.lua  (Nov 7 2026, QA; CHECK_respawn_20261107.md, the only part that is safe to script)
-- The respawn itself is NOT scripted: dying (or adding a second player) ends the QA character on the director's ZeD-QA save for
-- good (the new survivor replaces it), and the desk needs a real death screen, Restart and Play. This script only proves the
-- pieces are in place in the live game, without touching the character:
--   Overrides/Respawn.lua loaded and hooked the game's CoopCharacterCreation (its original createChildren, accept and cancel kept),
--   the respawn desk class exists, the game's death screen is hooked by ZeD (ISPostDeathUI), no desk is up and no respawn is
--   running now, the Escape taker and the views the desk uses are registered, the main menu's switch-off exists.
-- Manual (all of CHECK_respawn): die and Restart, the desk, Spawn, Traits, Looks, Play (CRT switch-off), Back, Random, keys, name
-- field, the pad, Deck size, Add new player with a second pad, multiplayer, This Is Your Life, safe mode.
-- grep "ZEDQA b8rs".
local TAG = "b8rs"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local pn = p and p:getPlayerNum() or 0
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
if not (p and CW and WW) then say("ERR ZeD's windows are not loaded"); say("DONE"); return end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8rs_" .. n .. ".png") end) end
local function cw() return CW.getWindow() end
local function ww() return WW.getWindow() end
local function keepDown(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
local function holdBoth() keepDown(cw()); keepDown(ww()) end

-- the step list: step(waitTicks, fn) runs fn that many ticks after the step before; waitFor(max, cond, fn) runs fn when cond holds (fn(timedOut))
local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end
local function waitFor(max, cond, fn) Q[#Q + 1] = { max = max, cond = cond, fn = fn } end
local cleanups = {}
local function onCleanup(fn) cleanups[#cleanups + 1] = fn end
local ticker
local function finish()
    for i = #cleanups, 1, -1 do local ok, e = pcall(cleanups[i]); if not ok then say("ERR cleanup " .. i .. ": " .. tostring(e)) end end
    cleanups = {}
    say("checks: passes=" .. passes .. " misses=" .. misses)
    say("DONE")
end
local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(ticker); finish(); return end
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


step(1, function()
    local R, MM = ZeD.Respawn, ZeD.MainMenu
    check(R ~= nil and type(R.begin) == "function" and type(R.finish) == "function" and type(R.accept) == "function", "respawn: ZeD.Respawn has begin, finish and accept")
    check(R ~= nil and type(R.sync) == "function" and type(R.noWindowBack) == "function" and type(R.onKey) == "function", "respawn: sync, noWindowBack and onKey are there")
    check(MM ~= nil and MM.respawn == nil, "respawn: none is running now")
    check(MM ~= nil and MM.root == nil, "respawn: no desk is up over the world")
    check(type(ZeD_MMRespawnDesk) == "table", "respawn: the respawn desk class exists")
    check(CoopCharacterCreation ~= nil and CoopCharacterCreation._zedOrig ~= nil, "respawn: the game's CoopCharacterCreation is hooked, its originals kept")
    local O = CoopCharacterCreation and CoopCharacterCreation._zedOrig
    check(O ~= nil and O.createChildren ~= nil and O.accept ~= nil and O.cancel ~= nil, "respawn: its createChildren, accept and cancel are kept")
    check(CoopCharacterCreation ~= nil and CoopCharacterCreation.cancel ~= O.cancel, "respawn: cancel is ZeD's wrapper")
    check(ISPostDeathUI ~= nil and ISPostDeathUI._zedOrig ~= nil, "respawn: the game's death screen (ISPostDeathUI) is hooked")
    check(ZeD.EscapeTakers ~= nil and type(ZeD.EscapeTakers.respawn) == "function", "respawn: the desk's Escape taker is registered")
    check(R ~= nil and type(R.deskKeys) == "function" and R.deskKeys() == false, "respawn: the desk takes no keys now")
    check(MM ~= nil and type(MM.switchOff) == "function" and type(MM.showView) == "function", "respawn: the monitor's switch-off and showView exist")
    local views = {}
    for _, v in ipairs(MM and MM.views or {}) do views[v.view] = true end
    check(views.spawn and views.traits and views.looks, "respawn: the Spawn, Traits and Looks views are registered")
    check(ZeD.Safe ~= nil and ZeD.Safe.on() == false, "respawn: safe mode is off (the desk runs only then)")
end)
step(5, function() end)

ticker = onTick
Events.OnTick.Add(ticker)
say("start")
