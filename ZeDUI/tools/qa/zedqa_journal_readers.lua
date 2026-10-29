-- ZeDUI/tools/qa/zedqa_journal_readers.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: the Journal tab's Notebooks and Papers and the
-- log box's Into. Carries a newspaper (unread), a flyer (read), a notebook and
-- a pencil. Papers: the list (unread dim), the unread quick look (paper only +
-- Read), the read quick look (page, places, words). Notebooks: the page small,
-- a quick note written (a few seconds a line) and checked on the page. Journal:
-- Into the notebook, Save, and the log entry naming the page. Takes the items
-- and the log entry back. grep "ZEDQA jrd"; Screenshots/zqa_jr_*.png.
-- The QA save is often at night and vanilla refuses to write in the dark, so before the
-- quick note the run sets noon, queues the write once the light has reached the player
-- (the steps after it count from that moment), checks the line is on the page, and puts
-- the time of day back at the end.
local p = getPlayer()
local pn = p:getPlayerNum()
local gt = getGameTime()
local tod0 = gt:getTimeOfDay()
local function say(s) print("ZEDQA jrd " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_jr_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end        -- n ticks after the start (before the write)
local later = {}
local function after(n, fn) later[#later + 1] = { n = n, fn = fn } end     -- n ticks after the write is queued
local NOTE = "fossoil on the flyer too. go round back"
local noonAt, queuedAt = nil, nil
local function pageWith(item, line)
    for i = 1, item:getPageToWrite() do
        local t = item:seePage(i)
        if t and string.find(t, line, 1, true) then return i end
    end
    return nil
end
local function media(id) return { id = string.lower(id), title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" } end
local function w() return ZeD_CharacterWindow.getWindow() end
local J = ZeD.JournalReaders
local news, flier, book, pencil
local hadRead = false
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    if not (w() and w():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    p:setGodMod(true)
    local inv = p:getInventory()
    news = inv:AddItem("Base.Newspaper"); news:getModData().printMedia = media("KnoxKnews_July2"); news:setName(getText("Print_Media_KnoxKnews_July2_title"))
    flier = inv:AddItem("Base.Flier"); flier:getModData().printMedia = media("UStoreItMuldraugh"); flier:setName(getText("Print_Media_UStoreItMuldraugh_title"))
    hadRead = p:isPrintMediaRead("knoxknews_july2")
    p:addReadPrintMedia("ustoreitmuldraugh")
    book = inv:AddItem("Base.Notebook"); book:setName("Supply runs"); book:setCustomName(true)
    book:addPage(1, "day 3. truck still wont start. tried the battery\nfrom the van on 31W, nothing. maybe its the starter")
    pencil = inv:AddItem("Base.Pencil")
end)
at(10, function()
    local x = w(); x._activeTab = "journal"; x._drawerMode = "tab"; x._drawerOpen = true
    x._journalSubTab = 3
    J.refresh(x)
end)
at(50, function()
    local c = w()._jr and w()._jr.carried
    say("papers " .. tostring(c and #c.papers) .. " books " .. tostring(c and #c.books) .. " zones " .. #(w()._jrZones or {}))
    shot("01_papers")
end)
at(55, function() w()._jr.paperOpen = "knoxknews_july2" end)
at(85, function()
    local ids = {}
    for _, z in ipairs(w()._jrZones or {}) do ids[#ids + 1] = z.id end
    say("unread look zones " .. table.concat(ids, ","))
    shot("02_unread_look")
end)
at(90, function() w()._jr.paperOpen = "ustoreitmuldraugh" end)
at(120, function()
    local ids = {}
    for _, z in ipairs(w()._jrZones or {}) do ids[#ids + 1] = z.id end
    say("read look zones " .. table.concat(ids, ","))
    shot("03_read_look")
end)
-- (Oct 28 2026: the quick note goes into the notebook the tab has current, which is the first one carried unless one
-- was picked; with another notebook in the QA character's bags the note landed there, so the test picks its own)
at(125, function() local x = w(); x._jr.paperOpen = nil; x._journalSubTab = 2; x._jr.nbId = book:getID() end)
at(160, function()
    say("note field " .. tostring(w()._jrNote and w()._jrNote:isVisible()) .. " page " .. tostring(w()._jr.nbPage[book:getID()]))
    w()._jrNote:setText(NOTE)
    -- noon, then the write waits for the light below
    noonAt = tick
    gt:setTimeOfDay(12)
end)
after(0, function()
    shot("04_notebooks")
    J.writeNote(w())
end)
after(260, function()
    local pg = pageWith(book, NOTE)
    if pg then say("ok written line on page " .. tostring(pg))
    else
        local s = w()._jr
        local others = {}
        for _, b in ipairs((s and s.carried and s.carried.books) or {}) do
            if b ~= book and pageWith(b, NOTE) then others[#others + 1] = b:getName() end
        end
        say("FAIL written line missing (current " .. tostring(s and s.nbId) .. " book " .. tostring(book:getID()) .. " msg " .. tostring(s and s.msg)
            .. " pending " .. tostring(s and s.pending ~= nil) .. (#others > 0 and (" | found in: " .. table.concat(others, ", ")) or "") .. ")")
    end
    shot("05_written")
    local x = w(); x._journalSubTab = 1
    x._jr.logInto = book:getID()
    x._journalInput:setText("saw 3 of them by the gas station around noon")
end)
after(290, function()
    shot("06_into")
    local btn = w()._journalSaveBtn
    btn.onclick(btn.target, btn)
end)
after(560, function()
    local md = p:getModData()
    local e = md.ZeD_Journal and md.ZeD_Journal.entries and md.ZeD_Journal.entries[1]
    say("log entry " .. tostring(e and e.text) .. " | source " .. tostring(e and e.source and e.source.name) .. " p" .. tostring(e and e.source and e.source.page))
    say("book p1 now " .. tostring(book:seePage(1)):gsub("\n", " / "))
    shot("07_logged")
end)
after(565, function()
    local md = p:getModData()
    local e = md.ZeD_Journal and md.ZeD_Journal.entries and md.ZeD_Journal.entries[1]
    if e and e.source then table.remove(md.ZeD_Journal.entries, 1) end
    -- (the window may have been rebuilt since: only touch what is there)
    local x = w()
    if x then x._journalCache = nil; if x._jr then x._jr.logInto = nil end end
    local inv = p:getInventory()
    for _, it in ipairs({ news, flier, book, pencil }) do if it then inv:Remove(it) end end
    gt:setTimeOfDay(tod0)
    say("DONE (newspaper had been read before: " .. tostring(hadRead) .. ")")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    -- the write waits for the light after noon (400 ticks at most, then it is queued anyway so a failure shows)
    if noonAt and tick > noonAt and not queuedAt and (not p:tooDarkToRead() or tick - noonAt >= 400) then
        queuedAt = tick
        say("light after " .. (tick - noonAt) .. " ticks: tooDark " .. tostring(p:tooDarkToRead()))
    end
    if queuedAt then
        for _, s in ipairs(later) do
            if s.n == tick - queuedAt then local ok, e = pcall(s.fn); if not ok then say("ERR +" .. s.n .. " " .. tostring(e)) end end
        end
        if tick - queuedAt > 570 then Events.OnTick.Remove(onTick) end
    end
end
Events.OnTick.Add(onTick)
say("start")
