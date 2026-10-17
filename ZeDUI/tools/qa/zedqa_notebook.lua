-- ZeDUI/tools/qa/zedqa_notebook.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: writing in a notebook through vanilla's own
-- Write (ISInventoryPaneContextMenu.onWriteSomething -> ISWriteSomething), which
-- now shows ZeD's page. Writes two pages, renames it, turns pages, asks to
-- erase and keeps, Done (checks the notebook kept the pages and the name);
-- then Read without a pencil (read only); then someone else's locked notebook.
-- Takes the items back. grep "ZEDQA nb"; Screenshots/zqa_nb_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA nb " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_nb_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local book, pencil, other
local function win() return ZeD.Reader.get(pn) end
local PAGE1 = "day 3. truck still wont start. tried the battery\nfrom the van on 31W, nothing. maybe its the starter\n\nthe U-Store It place on that flyer - muldraugh.\nlock-ups. guns n ammo it said!! check tmrw early"
local PAGE2 = "water: 2 bottles + the pot. need more. rain barrel?\nfood: 4 cans beans, crackers, the jerky (half)"
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    local w = ZeD_CharacterWindow.getWindow(); if w and w:isVisible() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    p:setGodMod(true)
    local inv = p:getInventory()
    book = inv:AddItem("Base.Notebook")
    pencil = inv:AddItem("Base.Pencil")
    ISInventoryPaneContextMenu.onWriteSomething(book, true, pn)
end)
at(30, function()
    local r = win()
    say("open " .. tostring(r and r:isVisible()) .. " mode " .. tostring(r and r.mode) .. " pages " .. tostring(r and r.nPages) .. " readOnly " .. tostring(r and r.readOnly))
    r.nbEntry:setText(PAGE1)
    r.nbTitle:setText("Supply runs")
end)
at(45, function() shot("01_page1") end)
at(48, function() win():turnPage(1) end)
at(55, function() win().nbEntry:setText(PAGE2) end)
at(65, function() win().confirm = "erase" end)
at(75, function() shot("02_erase_asks"); win().confirm = nil end)
at(80, function() win():goPage(1) end)
at(90, function() shot("03_rail") end)
at(95, function() win():done() end)
at(110, function()
    say("after done: name " .. tostring(book:getName()) .. " p1 " .. tostring((book:seePage(1) or ""):sub(1, 30)) .. " p2 " .. tostring((book:seePage(2) or ""):sub(1, 30))
        .. " action " .. tostring(ISTimedActionQueue.isPlayerDoingAction(p)) .. " window " .. tostring(win():isVisible()))
    ISInventoryPaneContextMenu.onWriteSomething(book, false, pn)    -- Read note: no pencil
end)
at(140, function() say("read only " .. tostring(win().readOnly)); shot("04_read_only") end)
at(145, function()
    win():endWriting()
    other = p:getInventory():AddItem("Base.Notebook")
    other:addPage(1, "corn bread, the good one\n\n2 cups corn meal (white!!)\n1 cup buttermilk, 1 egg")
    other:setName("Recipes"); other:setCustomName(true)
    other:setLockedBy("someone_else")
end)
at(150, function() ISInventoryPaneContextMenu.onWriteSomething(other, true, pn) end)
at(180, function() say("other lock " .. tostring(win().otherLock) .. " readOnly " .. tostring(win().readOnly)); shot("05_locked_other") end)
at(185, function()
    win():endWriting()
    local inv = p:getInventory()
    for _, it in ipairs({ book, pencil, other }) do if it then inv:Remove(it) end end
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 190 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
