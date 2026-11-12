-- ZeDUI/tools/qa/zedqa_journal_tags.lua  (Nov 11 2026)
-- In game on the ZeD-QA save: the Journal page's entry tags. Opens the Character window on the
-- Journal, adds four marked entries to the log (one old, with no tags; one with two; one with four,
-- the squares alone; one with three long words), ticks Loot and Base under the write box, writes an
-- entry and presses Save (the entry keeps the two tags, the ticks clear), clicks the Base tag on an
-- entry (its word goes in the search), clears the search, then writes Into a carried notebook with
-- News ticked (the notebook gets the words only, the log entry keeps the tag). Prints the pad's
-- stops (eight picks, the entries' tags, the delete crosses) and their prompts. Takes the entries
-- and the notebook back. grep "ZEDQA jtag"; Screenshots/zqa_jtag_*.png.
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
at(125, function()
    local x = w()
    for _, z in ipairs(x._journalTagZones or {}) do
        if z.k == "base" then JT.onBodyClick(x, z.x + 1, z.y + 1); break end
    end
end)
at(160, function()
    local x = w()
    say("search after the Base click: '" .. tostring(x._journalSearchText) .. "' field '" .. tostring(x._journalSearch:getText()) .. "'")
    local n = 0
    for _, g in ipairs(JT.groups(x, log(), x._journalSearchText or "")) do n = n + #g.entries end
    say("entries kept " .. n)
    shot("04_search_base")
    -- the pad's stops on the page now
    local stops = JT.tagFocusables(x)
    local kinds = {}
    for _, s in ipairs(stops) do kinds[s.journalKind] = (kinds[s.journalKind] or 0) + 1 end
    say("pad stops: picks " .. tostring(kinds.tagPick) .. " entry tags " .. tostring(kinds.tag)
        .. " | pick A '" .. tostring(stops[1] and stops[1].promptA(x, stops[1])) .. "' help '" .. tostring(stops[1] and stops[1].extraPrompts[1]) .. "'")
end)
at(165, function() JT.setSearch(w(), "") end)
at(190, function() say("search cleared: '" .. tostring(w()._journalSearchText) .. "'"); shot("05_cleared") end)
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
    shot("06_into")
    local btn = x._journalSaveBtn; btn.onclick(btn.target, btn)
end)
at(700, function()
    local e = log()[1]
    local pg = book:seePage(1) or ""
    say((e and e.source and tagsOf(e) == "news") and "ok into: log keeps news" or ("FAIL into: entry " .. tostring(e and e.text) .. " tags " .. tagsOf(e) .. " msg " .. tostring(w()._jr.logMsg)))
    say((pg:find("emergency", 1, true) and not pg:find("News", 1, true)) and "ok notebook has the words only" or ("FAIL notebook page: " .. pg:gsub("\n", " / ")))
    say((picked(w()) == "") and "ok ticks cleared after the write" or ("FAIL ticks left " .. picked(w())))
    shot("07_into_logged")
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
