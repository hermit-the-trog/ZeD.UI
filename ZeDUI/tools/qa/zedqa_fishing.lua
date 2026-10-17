-- ZeDUI/tools/qa/zedqa_fishing.lua  (Oct 16 2026)
-- In game on the ZeD-QA save (no water there to cast into): vanilla's own
-- tension meter (Fishing.ISTensionUI, made as FishingManager makes it), shown
-- and fed the tensions a fight goes through: slack, light, tight, strain, at
-- the limit. Each is captured. Takes it back. grep "ZEDQA fi";
-- Screenshots/zqa_fi_*.png.
local p = getPlayer()
local function say(s) print("ZEDQA fi " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_fi_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local ui
local VALS = { { "1_slack", -0.6 }, { "2_light", 0.15 }, { "3_tight", 0.4 }, { "4_strain", 0.72 }, { "5_limit", 0.96 } }
at(2, function()
    local u = UIManager.getUI()
    for i = 0, u:size() - 1 do local e = u:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    local w = ZeD_CharacterWindow.getWindow(); if w and w:isVisible() then ZeD_CharacterWindow.toggleBothPaired(0) end
    ui = Fishing.ISTensionUI:new(p)
    ui:initialise(); ui:instantiate(); ui:setVisible(false); ui:backMost(); ui:addToUIManager()
    ui:setVisible(true)
end)
for i, v in ipairs(VALS) do
    at(10 + i * 20, function() ui:updateValue(v[2]) end)
    at(10 + i * 20 + 15, function() say(v[1] .. " tension " .. tostring(ui.zedTension) .. " vanilla angle " .. tostring(ui.val)); shot(v[1]) end)
end
at(140, function() ui:setVisible(false); ui:removeFromUIManager(); say("DONE") end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 145 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
