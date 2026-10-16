-- ZeDUI/tools/qa/zedqa_reader_refs.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: reference captures for the reader mockup. Gives a
-- newspaper (Knox Knews, July 1), a flyer (U-Store It, Muldraugh), a notebook and
-- a pencil; shoots the Character window's Journal > Flyers, the newspaper's item
-- card in the drawer, vanilla's print media window (paper, then its words) for
-- both pieces, and vanilla's notebook writer. Takes the items back.
-- grep "ZEDQA rr"; captures Screenshots/zqa_rr_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA rr " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rr_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local news, flier, book, pencil, win, jw
local function media(id)
    return { id = id, title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" }
end
local function openPM(item)
    local val = item:getModData().printMedia
    local w = PZAPI.UI.PrintMedia{ x = 730, y = 100 }
    w.media_id = val.id
    w.data = getText(val.info)
    w.children.bar.children.name.text = getText(val.title)
    w.textTitle = getText(val.title)
    w.textData = string.gsub(getText(val.text), "\n", "\n")
    w:instantiate()
    w.javaObj:setAlwaysOnTop(false)
    w:centerOnScreen(pn)
    return w
end
local function closePM() if win then pcall(function() UIManager.RemoveElement(win.javaObj) end); win = nil end end
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    local inv = p:getInventory()
    news = inv:AddItem("Base.Newspaper"); news:getModData().printMedia = media("KnoxKnews_July1"); news:setName(getText("Print_Media_KnoxKnews_July1_title"))
    flier = inv:AddItem("Base.Flier"); flier:getModData().printMedia = media("UStoreItMuldraugh"); flier:setName(getText("Print_Media_UStoreItMuldraugh_title"))
    book = inv:AddItem("Base.Notebook")
    pencil = inv:AddItem("Base.Pencil")
    say("items " .. tostring(news) .. " " .. tostring(flier) .. " " .. tostring(book))
    local w = ZeD_CharacterWindow.getWindow()
    if not (w and w:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    w = ZeD_CharacterWindow.getWindow()
    if w then w._activeTab = "journal"; w._journalSubTab = 4 end
end)
at(40, function() shot("01_journal_flyers") end)
at(45, function()
    local w = ZeD_CharacterWindow.getWindow()
    w._activeTab = "loot"
    local cnt = w._contentPanel
    cnt._selectedItems = { [news] = true }
    cnt._lastClickedItem = news
    if w._updateDrawer then w._updateDrawer(cnt) end
end)
at(85, function() shot("02_news_card") end)
at(90, function() win = openPM(news) end)
at(130, function() shot("03_vanilla_news_paper") end)
at(135, function() pcall(function() win.children.bottomButtons.children.readNewspaper:onLeftClick() end) end)
at(165, function() shot("04_vanilla_news_words") end)
at(170, function() closePM(); win = openPM(flier) end)
at(210, function() shot("05_vanilla_flier_paper") end)
at(215, function() pcall(function() win.children.bottomButtons.children.readNewspaper:onLeftClick() end) end)
at(245, function() shot("06_vanilla_flier_words") end)
at(250, function()
    closePM()
    local fh = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
    jw = ISUIWriteJournal:new(0, 0, 350, 15 * fh + 140, nil, function() end, p, book, book:seePage(1), book:getName(), 15, true, book:getPageToWrite())
    jw:initialise(); jw:addToUIManager()
end)
at(290, function() shot("07_vanilla_journal") end)
at(295, function()
    if jw then jw:removeFromUIManager() end
    local inv = p:getInventory()
    for _, it in ipairs({ news, flier, book, pencil }) do if it then inv:Remove(it) end end
    local w = ZeD_CharacterWindow.getWindow()
    if w then w._contentPanel._selectedItems = {}; w._contentPanel._lastClickedItem = nil; if w._updateDrawer then w._updateDrawer(w._contentPanel) end end
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 300 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
