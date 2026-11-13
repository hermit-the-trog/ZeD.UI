-- ZeDUI/tools/qa/zedqa_soak.lua  (Oct 16 2026)
-- A long session in a few minutes, on the ZeD-QA save: both windows open, the
-- game at its fastest speed, every tab of both windows in turn (the Journal's
-- four sub-tabs too), the full reader opened and closed on a carried paper,
-- for ROUNDS rounds. Every round logs the frame time over it, the number of UI
-- elements on screen and in-game hours passed. Takes the paper back and sets
-- speed 1 at the end. grep "ZEDQA soak".
-- Nov 12 2026 (test cleanup, SHRINK): 2 rounds (about 2 minutes) with a real before-and-after check, so it can
-- fail. It used to run 12 rounds (10 to 13 minutes of every run) and only log a trend nobody read:
--   * nothing piles up: the UI element count at the end of the last round is no higher than at the end of round 1
--     (the same point of the cycle, the reader open), and once the reader is shut it is no higher than at the start
--     plus the reader's own window;
--   * no slowdown: the last round's average frame is not more than half again the first round's (plus 2 ms).
-- The long one, once per release: run zedqa_soak_long.lua right before it (it sets ZEDQA_SOAK_ROUNDS = 12 for the
-- next run of this script only).
local ROUNDS, PER = 2, 240        -- rounds of 240 frames per tab step (about a minute a round)
if type(ZEDQA_SOAK_ROUNDS) == "number" and ZEDQA_SOAK_ROUNDS >= 2 then ROUNDS = ZEDQA_SOAK_ROUNDS end
ZEDQA_SOAK_ROUNDS = nil
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA soak " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what) if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end end
local CW, WW = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
if not (CW and CW:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn); CW, WW = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow() end
local paper = p:getInventory():AddItem("Base.Newspaper")
paper:getModData().printMedia = { id = "knoxknews_july1", title = "Print_Media_KnoxKnews_July1_title", info = "Print_Media_KnoxKnews_July1_info", text = "Print_Text_KnoxKnews_July1_info" }
local steps = {
    { w = "c", tab = "loot" }, { w = "c", tab = "equip" }, { w = "c", tab = "health" }, { w = "c", tab = "thermal" },
    { w = "c", tab = "identity" }, { w = "c", tab = "journal", sub = 1 }, { w = "c", tab = "journal", sub = 2 },
    { w = "c", tab = "journal", sub = 3 }, { w = "c", tab = "journal", sub = 4 }, { w = "c", tab = "skills" },
    { w = "w", tab = "craft" }, { w = "w", tab = "build" }, { w = "w", tab = "maps" }, { w = "w", tab = "forage" },
    { w = "w", tab = "animals" }, { w = "w", tab = "loot" }, { reader = true },
}
local function goTab(win, tab)
    -- (the strip's own click: the same path a player's click takes; as suite_tabs)
    local strip = (win == CW) and win._tabStripPanel or win._actionTabStrip
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local frame, round, stepIx, t0, worst, startH = 0, 1, 0, getTimestampMs(), 0, getGameTime():getWorldAgeHours()
local last = getTimestampMs()
local uiStart = UIManager.getUI():size()
local roundUi, roundMs = {}, {}
local function nextStep()
    stepIx = stepIx + 1
    if stepIx > #steps then
        local ms = (getTimestampMs() - t0) / (PER * #steps)
        roundUi[round], roundMs[round] = UIManager.getUI():size(), ms
        say(string.format("round %d avg %.2f ms worst %d ms ui %d (start %d) hours %.1f", round, ms, worst, UIManager.getUI():size(), uiStart, getGameTime():getWorldAgeHours() - startH))
        round = round + 1; stepIx = 1; t0 = getTimestampMs(); worst = 0
    end
    local s = steps[stepIx]
    if not s then return end
    local R = ZeD.Reader.get(pn)
    if R and R:isVisible() then R:close() end
    if s.reader then ZeD.Reader.openPrint(p, paper); return end
    local win = (s.w == "c") and CW or WW
    goTab(win, s.tab)
    if s.sub then win._journalSubTab = s.sub end
end
local function finish()
    setGameSpeed(1)
    local R = ZeD.Reader.get(pn); if R and R:isVisible() then R:close() end
    p:getInventory():Remove(paper)
    goTab(CW, "loot"); goTab(WW, "loot")
    local n = #roundUi
    if n >= 2 then
        check(roundUi[n] <= roundUi[1], string.format("nothing piles up: %d UI elements at the end of round %d, %d at the end of round 1", roundUi[n], n, roundUi[1]))
        check(roundMs[n] <= roundMs[1] * 1.5 + 2, string.format("no slowdown: round %d averaged %.2f ms a frame, round 1 %.2f ms", n, roundMs[n], roundMs[1]))
    else
        say("not run: the before-and-after check (" .. n .. " of " .. ROUNDS .. " rounds finished)")
        nFail = nFail + 1; say("FAIL fewer than 2 rounds finished")
    end
    local uiEnd = UIManager.getUI():size()
    check(uiEnd <= uiStart + 1, string.format("after the run, the reader shut: %d UI elements (%d at the start; the reader's own window may stay as one)", uiEnd, uiStart))
    say(nPass .. " passed, " .. nFail .. " failed (" .. ROUNDS .. " rounds)")
    say("DONE")
end
local function onTick()
    frame = frame + 1
    local now = getTimestampMs()
    worst = math.max(worst, now - last); last = now
    if frame == 1 then setGameSpeed(4); nextStep() end
    if frame % PER == 0 then
        if round > ROUNDS then
            Events.OnTick.Remove(onTick)
            local okF, eF = pcall(finish)
            if not okF then say("ERR at the end: " .. tostring(eF)); pcall(setGameSpeed, 1); say("DONE") end
            return
        end
        local ok, e = pcall(nextStep)
        if not ok then say("ERR " .. tostring(e)) end
    end
end
Events.OnTick.Add(onTick)
say("start ui " .. uiStart .. ", " .. ROUNDS .. " rounds")
