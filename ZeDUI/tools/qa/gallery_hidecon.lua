-- ZeDUI/tools/qa/gallery_hidecon.lua  (Nov 3 2026, QA; gallery pictures taken by the check scripts)
-- Keeps the game's debug console (UIDebugConsole, open under -debug) hidden while the scripts after it in the run
-- list take their pictures; gallery_t14_end.lua's run ends with the game, so nothing is put back. grep "ZEDQA hcn".
local n = 0
local function hide()
    n = n + 1
    if n % 30 ~= 1 then return end
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false) end end
    end)
end
Events.OnTick.Add(hide)
print("ZEDQA hcn the debug console kept hidden")
local k = 0
local function later() k = k + 1; if k < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA hcn DONE") end
Events.OnTick.Add(later)
