-- ZeDUI/tools/qa/zedqa_buckles.lua  (Oct 15 2026)
-- The profession buckles (ZeDUI/tools/buckles/README.md, check pass): gives
-- the QA character each stable profession in turn (vanilla's
-- CharacterProfessionDefinition list, as the admin "choose profession" panel
-- does) and captures the belt. The original profession goes back at the end.
-- Run in game: copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA bk".
-- Prints the belt's buckle rect so the captures can be cropped.

local p = getPlayer()
local desc = p:getDescriptor()
local function say(s) print("ZEDQA bk " .. tostring(s)) end
local original = desc:getCharacterProfession()
local list = {}
local defs = CharacterProfessionDefinition.getProfessions()
for i = 0, defs:size() - 1 do list[#list + 1] = defs:get(i) end
say("professions " .. #list)
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
end)
for i, prof in ipairs(list) do
    at(5 + i * 12, function() desc:setCharacterProfession(prof:getType()) end)
    at(5 + i * 12 + 8, function()
        local id = tostring(desc:getCharacterProfession():getName())
        local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD(0)
        local b = hud and hud._buckle
        say(string.format("%02d %s buckle=%s", i, id, b and string.format("%d,%d,%d,%d", hud:getAbsoluteX() + b.x, hud:getAbsoluteY() + b.y, b.w, b.h) or "?"))
        getCore():TakeFullScreenshot(string.format("zqa_bk_%02d_%s.png", i, (id:gsub("[^%w]", "_"))))
    end)
end
at(20 + #list * 12, function() desc:setCharacterProfession(original); say("DONE (profession back to " .. tostring(original:getName()) .. ")") end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 30 + #list * 12 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
