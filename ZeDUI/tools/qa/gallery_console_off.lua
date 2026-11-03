-- ZeDUI/tools/qa/gallery_console_off.lua  (Nov 2 2026, QA): hides the debug console before gallery shots taken by
-- test scripts that do not hide it themselves (the two-way radio pages). grep "ZEDQA gco".
local ui = UIManager.getUI()
local n = 0
for i = 0, ui:size() - 1 do
    local e = ui:get(i)
    if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false); n = n + 1 end
end
print("ZEDQA gco console hidden " .. n)
local k = 0
local function tick() k = k + 1; if k >= 5 then Events.OnTick.Remove(tick); print("ZEDQA gco DONE") end end
Events.OnTick.Add(tick)
