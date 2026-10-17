-- ZeDUI/tools/qa/zedqa_soak.lua  (Oct 16 2026)
-- A long session in a few minutes, on the ZeD-QA save: both windows open, the
-- game at its fastest speed, every tab of both windows in turn (the Journal's
-- four sub-tabs too), the full reader opened and closed on a carried paper,
-- for ROUNDS rounds. Every round logs the frame time over it, the number of UI
-- elements on screen and in-game hours passed, so a leak (elements piling up)
-- or a slowdown shows as a trend. Takes the paper back and sets speed 1 at the
-- end. grep "ZEDQA soak".
local ROUNDS, PER = 12, 240        -- 12 rounds of 240 frames per tab step (about 7 minutes)
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA soak " .. tostring(s)) end
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
local function nextStep()
    stepIx = stepIx + 1
    if stepIx > #steps then
        local ms = (getTimestampMs() - t0) / (PER * #steps)
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
local function onTick()
    frame = frame + 1
    local now = getTimestampMs()
    worst = math.max(worst, now - last); last = now
    if frame == 1 then setGameSpeed(4); nextStep() end
    if frame % PER == 0 then
        if round > ROUNDS then
            Events.OnTick.Remove(onTick)
            setGameSpeed(1)
            local R = ZeD.Reader.get(pn); if R and R:isVisible() then R:close() end
            p:getInventory():Remove(paper)
            say("DONE")
            return
        end
        local ok, e = pcall(nextStep)
        if not ok then say("ERR " .. tostring(e)) end
    end
end
Events.OnTick.Add(onTick)
say("start ui " .. uiStart)
