-- ZeDUI/tools/qa/zedqa_workshop_upload.lua  (Oct 16 2026)
-- At the main menu: the Workshop button opens the upload window on the
-- monitor (vanilla's workshopSubmit redirected) with the staged folder
-- (ModTemplate); then the description editor with a sample description, its
-- Steam codes view, and back. Never presses Upload (that publishes to Steam).
-- Shoots each; grep "ZEDQA wu".
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA wu " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_wu_" .. n .. ".png") end) end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local SAMPLE = "[h1]Tidy Sorting[/h1]\n[img]https://i.imgur.com/banner.png[/img]\n\nSorts your bags by kind with [b]one press[/b], keeps favourites on top and remembers each container's order.\n\n[h2]Features[/h2]\n[list]\n[*]One-press sort in every bag\n[*]Favourites stay on top\n[*]Each container remembers its order\n[/list]\n\n[h2]Compatibility[/h2]\n[table]\n[tr][th]Works with[/th][th]Notes[/th][/tr]\n[tr][td]Knox Radio Plus[/td][td]Load Tidy Sorting after it[/td][/tr]\n[tr][td]ZeD UI[/td][td]Buttons in the bottom row[/td][/tr]\n[/table]"
at(2, function() MM.act.workshop() end)
at(25, function()
    local w = R.workshopWin
    say("view " .. tostring(MM.view) .. " items " .. #w.items .. " contents " .. tostring(w.contents) .. " desc " .. #w.desc)
    shot("01_upload")
end)
at(30, function() R.workshopWin.desc = SAMPLE; R.workshopWin:openEditor() end)
at(50, function() say("editor view " .. tostring(MM.view) .. " blocks " .. #R.wsdescWin.blocks); shot("02_editor") end)
at(55, function() local e = R.wsdescWin; e:select(3) end)
at(65, function() shot("03_editor_text_picked") end)
at(70, function() R.wsdescWin.view = "codes" end)
at(80, function() shot("04_codes") end)
at(85, function() R.wsdescWin.view = "steam"; R.wsdescWin:finish(true) end)
at(100, function() local w = R.workshopWin; say("back view " .. tostring(MM.view) .. " desc " .. #w.desc .. " unsaved " .. tostring(w:isUnsaved())); shot("05_upload_with_desc") end)
at(105, function() say("DONE") end)
local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 110 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
