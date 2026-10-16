-- ZeDUI/tools/qa/zedqa_journal_refs.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: the Character window's Journal tab as it is
-- today (the diary, then the Flyers gallery), for the reader mockup's compact
-- scenes. grep "ZEDQA jr"; captures Screenshots/zqa_jr_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA jr " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_jr_" .. n .. ".png") end) end
local t = 0
local function w() return ZeD_CharacterWindow.getWindow() end
local function onTick()
    t = t + 1
    if t == 2 then
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
        if not (w() and w():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    end
    if t == 10 then w()._activeTab = "journal"; w()._journalSubTab = 1 end
    if t == 50 then shot("01_diary") end
    if t == 55 then w()._journalSubTab = 3 end
    if t == 95 then shot("02_flyers"); say("DONE"); Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
