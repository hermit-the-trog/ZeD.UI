-- ZeDUI/tools/qa/zedqa_reader.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: the reader through vanilla's own Read action
-- (instant for the run): a newspaper (Knox Knews, July 1) opens in the ZeD
-- reader on Paper; Words; a story picked in the side column; zoomed in; then
-- a flyer (U-Store It, Muldraugh) with its place, and Show on map opening
-- ZeD's map on the spot. Takes the items back. grep "ZEDQA rd";
-- Screenshots/zqa_rd_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA rd " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rd_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local news, flier
-- (a real piece carries the registry's lower-case id and the proper-case text keys)
local function media(id) return { id = string.lower(id), title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" } end
local function win() return ZeD.Reader.get(pn) end
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    local w = ZeD_CharacterWindow.getWindow(); if w and w:isVisible() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    p:setGodMod(true)
    p:setTimedActionInstantCheat(true)
    local inv = p:getInventory()
    news = inv:AddItem("Base.Newspaper"); news:getModData().printMedia = media("KnoxKnews_July1"); news:setName(getText("Print_Media_KnoxKnews_July1_title"))
    flier = inv:AddItem("Base.Flier"); flier:getModData().printMedia = media("UStoreItMuldraugh"); flier:setName(getText("Print_Media_UStoreItMuldraugh_title"))
    ISTimedActionQueue.add(ISReadABook:new(p, news))
end)
at(40, function() say("open " .. tostring(win() and win():isVisible()) .. " view " .. tostring(win() and win().view) .. " body " .. tostring(win() and win().page and win().page.body)); shot("01_paper") end)
at(45, function() win():setView("words") end)
at(70, function() shot("02_words"); say("words blocks " .. #win().words) end)
at(75, function() win():jumpTo(2) end)
at(100, function() shot("03_story2") end)
at(105, function() win():setView("paper"); win():zoom(1); win():zoom(1) end)
at(130, function() shot("04_zoomed") end)
at(135, function() win():close(); ISTimedActionQueue.add(ISReadABook:new(p, flier)) end)
at(175, function() say("flier places " .. #win().places); shot("05_flier") end)
at(180, function() win():showPlace(1) end)
at(300, function() shot("06_map"); local ww = ZeD_WorldWindow.getWindow(); local mp = ww and ww._worldMapPanel; say("map centre " .. tostring(mp and math.floor(mp.mapAPI:getCenterWorldX())) .. "," .. tostring(mp and math.floor(mp.mapAPI:getCenterWorldY()))) end)
at(305, function()
    pcall(function() ISWorldMap.HideWorldMap(pn) end)
    p:setTimedActionInstantCheat(false)
    local inv = p:getInventory()
    for _, it in ipairs({ news, flier }) do if it then inv:Remove(it) end end
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 310 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
