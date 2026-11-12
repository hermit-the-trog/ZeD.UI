-- ZeDUI/tools/qa/zedqa_journal_tags.lua  (Nov 11 2026)
-- In game on the ZeD-QA save: the Journal page's entry tags. Opens the Character window on the
-- Journal, adds four marked entries to the log (one old, with no tags; one with two; one with four,
-- the squares alone; one with three long words), ticks Loot and Base under the write box, writes an
-- entry and presses Save (the entry keeps the two tags, the ticks clear), searches for the run's
-- mark (its entries to the top of the log), prints the pad's stops (eight picks, the entries' tags,
-- the delete crosses) and their prompts and walks the new entry's tags Right to its delete cross,
-- clicks the Base tag on it (its word goes in the search), clears the search, then writes Into a
-- carried notebook with News ticked (the notebook gets the words only, the log entry keeps the
-- tag). Takes the entries and the notebook back. grep "ZEDQA jtag"; Screenshots/zqa_jtag_*.png.
-- The write into the notebook needs light: the run sets noon for it and puts the time back at the end.
local p = getPlayer()
local pn = p:getPlayerNum()
local gt = getGameTime()
local tod0 = gt:getTimeOfDay()
local MARK = "[qa-tags] "
local function say(s) print("ZEDQA jtag " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_jtag_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function w() return ZeD_CharacterWindow.getWindow() end
local JT = ZeD.JournalTab
local book, pencil
local function log() local md = p:getModData(); md.ZeD_Journal = md.ZeD_Journal or { entries = {} }; return md.ZeD_Journal.entries end
local function entry(text, tags, day)
    return { month = gt:getMonth(), day = day, year = gt:getYear(), hour = 9, minute = 30, survivalDay = 1 + day, text = MARK .. text, tags = tags }
end
local function tagsOf(e) return e and e.tags and table.concat(e.tags, ",") or "none" end
local function picked(x) return table.concat(JT.pickedTags(x) or {}, ",") end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    if not (w() and w():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    p:setGodMod(true)
    local L = log()
    table.insert(L, 1, entry("radio said nothing again", nil, 1))
    table.insert(L, 1, entry("cleared the house on the corner. nothing but a crowbar", { "danger", "loot" }, 2))
    table.insert(L, 1, entry("found the gas station empty. took the map and two cans of beans", { "danger", "loot", "food", "travel" }, 3))
    table.insert(L, 1, entry("rain all day. fixed the fence, ran out of nails", { "weather", "travel", "injury" }, 4))
end)
at(10, function()
    local x = w(); x._activeTab = "journal"; x._drawerMode = "tab"; x._drawerOpen = true
    x._journalSubTab = 1; x._killsExpanded = false; x._journalCache = nil
end)
at(60, function()
    local x = w()
    say("picks " .. #(x._journalPickZones or {}) .. " tag zones " .. #(x._journalTagZones or {}))
    local four = 0
    for _, z in ipairs(x._journalTagZones or {}) do if z.entryIdx == 2 then four = four + 1 end end
    say("four-tag entry stops " .. four .. " (want 4, squares alone)")
    -- (the pad's stops on the log are only those within a view's height of it: JournalTab.inPadReach)
    local reach = 0
    for _, z in ipairs(x._journalTagZones or {}) do if JT.inPadReach(x, z) then reach = reach + 1 end end
    local v = x._journalView or {}
    say("tag zones in the pad's reach " .. reach .. " of " .. #(x._journalTagZones or {}) .. " | view y " .. tostring(v.y) .. " h " .. tostring(v.h))
    shot("01_reading")
end)
at(65, function()
    local x = w()
    JT.togglePick(x, "base"); JT.togglePick(x, "loot")
    x._journalInput:setText(MARK .. "found a working generator in the barn past the farm")
end)
at(90, function() say("ticked " .. picked(w())); shot("02_writing") end)
at(95, function() local btn = w()._journalSaveBtn; btn.onclick(btn.target, btn) end)
at(120, function()
    local e = log()[1]
    say((e and e.text:find(MARK, 1, true) and tagsOf(e) == "loot,base") and "ok saved with loot,base" or ("FAIL saved " .. tostring(e and e.text) .. " tags " .. tagsOf(e)))
    say((picked(w()) == "") and "ok ticks cleared" or ("FAIL ticks left " .. picked(w())))
    shot("03_saved")
end)
-- The run's entries are dated this month; the save's own log can hold later months, which sort
-- first, and then the run's entries lie past the view and past the pad's reach (the first run, on
-- the Deck: no entry tag stops, and the Base click fell outside the log). That was the script, not
-- the page. A search for the run's mark brings its entries to the top, as a player would find them.
at(122, function() JT.setSearch(w(), MARK:sub(1, -2)) end)
at(140, function()
    local x = w()
    -- the pad's stops on the page now, and the walk along the newest entry: its tags, then its cross
    local stops = JT.tagFocusables(x)
    local kinds = {}
    for _, s in ipairs(stops) do kinds[s.journalKind] = (kinds[s.journalKind] or 0) + 1 end
    say("pad stops: picks " .. tostring(kinds.tagPick) .. " entry tags " .. tostring(kinds.tag)
        .. " | pick A '" .. tostring(stops[1] and stops[1].promptA(x, stops[1])) .. "' help '" .. tostring(stops[1] and stops[1].extraPrompts[1]) .. "'")
    local all, row = {}, {}
    for _, s in ipairs(stops) do
        all[#all + 1] = s
        if s.journalKind == "tag" and s.entryIdx == 1 then row[#row + 1] = s end
    end
    for _, z in ipairs(x._journalDeleteZones or {}) do
        if JT.inPadReach(x, z) then all[#all + 1] = { x = z.x, y = z.y, w = z.w, h = z.h, id = "journal:del:" .. z.entryIdx } end
    end
    local function go(from, dir)
        local others = {}
        for _, s in ipairs(all) do if s ~= from then others[#others + 1] = s end end
        return (ZeD.SpatialNav.pick(from, others, dir))
    end
    if #row == 2 then
        local a = go(row[1], "right")
        local b = a and go(a, "right")
        local back = b and go(b, "left")
        say((a == row[2] and b and b.id == "journal:del:1" and back == row[2]) and "ok the walk: Loot, Base, the cross, and Left back to Base"
            or ("FAIL the walk: " .. tostring(a and a.id) .. " then " .. tostring(b and b.id) .. " back " .. tostring(back and back.id)))
    else
        say("FAIL the newest entry's tag stops: " .. #row .. " (want 2)")
    end
    shot("04_qa_entries")
end)
at(150, function()
    local x = w()
    local hit = false
    for _, z in ipairs(x._journalTagZones or {}) do
        if z.k == "base" then hit = JT.onBodyClick(x, z.x + 1, z.y + 1); break end
    end
    say(hit and "ok the Base tag took the click" or "FAIL the Base tag did not take the click (no zone, or outside the log's view)")
end)
at(170, function()
    local x = w()
    say("search after the Base click: '" .. tostring(x._journalSearchText) .. "' field '" .. tostring(x._journalSearch:getText()) .. "'")
    local n = 0
    for _, g in ipairs(JT.groups(x, log(), x._journalSearchText or "")) do n = n + #g.entries end
    say("entries kept " .. n)
    shot("05_search_base")
end)
at(175, function() JT.setSearch(w(), "") end)
at(190, function() say("search cleared: '" .. tostring(w()._journalSearchText) .. "'"); shot("06_cleared") end)
-- Into a notebook: News ticked; the notebook gets the words only
at(195, function()
    local inv = p:getInventory()
    book = inv:AddItem("Base.Notebook"); book:setName("QA tags"); book:setCustomName(true)
    pencil = inv:AddItem("Base.Pencil")
    gt:setTimeOfDay(12)
    ZeD.JournalReaders.refresh(w())
end)
at(260, function()
    local x = w()
    x._jr.logInto = book:getID()
    JT.togglePick(x, "news")
    x._journalInput:setText(MARK .. "tv went to the emergency thing")
    shot("07_into")
    local btn = x._journalSaveBtn; btn.onclick(btn.target, btn)
end)
at(700, function()
    local e = log()[1]
    local pg = book:seePage(1) or ""
    say((e and e.source and tagsOf(e) == "news") and "ok into: log keeps news" or ("FAIL into: entry " .. tostring(e and e.text) .. " tags " .. tagsOf(e) .. " msg " .. tostring(w()._jr.logMsg)))
    say((pg:find("emergency", 1, true) and not pg:find("News", 1, true)) and "ok notebook has the words only" or ("FAIL notebook page: " .. pg:gsub("\n", " / ")))
    say((picked(w()) == "") and "ok ticks cleared after the write" or ("FAIL ticks left " .. picked(w())))
    shot("08_into_logged")
end)
at(705, function()
    local L = log()
    for i = #L, 1, -1 do if type(L[i].text) == "string" and L[i].text:find(MARK, 1, true) then table.remove(L, i) end end
    local x = w()
    if x then x._journalCache = nil; x._journalGroupCache = nil; JT.clearPicks(x); if x._jr then x._jr.logInto = nil end end
    local inv = p:getInventory()
    for _, it in ipairs({ book, pencil }) do if it then inv:Remove(it) end end
    gt:setTimeOfDay(tod0)
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 710 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
