-- ZeDUI/tools/qa/jn_tab.lua  (Nov 27 2026, QA; tag jn_tab): the Character window's Journal tab (the Log, Notebooks,
-- Papers and Recipes pages), the gamut sweep, in the style of the Mechanics and Thermal sweeps (mt_tab.lua, th_tab.lua).
-- Its spec is the map ZeDUI/qa/audits/2026-11-27_map_journal.md (cases J1-J52, suspected bugs B1-B13). Run after
-- zedqa_prelude.lua and rt_kit.lua (jn.txt). grep "ZEDQA jn_tab".
-- Each suspected bug single player can stage is proved or cleared with values: PASS when ZeD does what the game does
-- (or what the map says the tab promises), FAIL with the evidence when it does not.
-- How it drives the tab: a mouse press is the drawer's own onMouseDown and onMouseUp at the zone's middle (drawer
-- coordinates: the header's page tabs, the picks, the tags, the month heads, the crosses, the kills head, the Notebooks
-- and Papers zones, the question's answers); Save is the window's own button (its onMouseDown and onMouseUp with the
-- pointer held over it). A zone the press does not reach where it is drawn (scrolled out of the view) is pressed as the
-- pad's A presses it, said once. The pad's presses go through FocusManager's QA hook and its own dispatch on the
-- Character window (RT.pad + RT.padDown / RT.padDir, focus by focusWhere in charTabContent), the input mode locked to
-- the controller and put back as found. Typing is the box's own text set (the search fields' own poll sends it on).
-- The truth is the game's own answer: getGameTime (the date and clock), getHoursSurvived, getZombieKills, the item's
-- pages (seePage, getPageToWrite, getLockedBy, hasTag LOCK_ON_WRITE), canBeWrite, isPrintMediaRead, ISInventoryPane's
-- isLiteratureRead, PrintMediaDefinitions.MiscDetails, the weapon's own categories, isRecipeKnown and
-- characterHasRequiredSkills, the sandbox's SeeNotLearntRecipe, the game's queue (ISTimedActionQueue). What the tab drew
-- is read from the draw itself: every word the drawer panel drew in the Journal's last frame (its drawText wrapped for
-- the run, a frame being one JournalReaders.beginFrame to the next) and the stripe rectangles it drew.
-- Cases (J<n> = the map's case, B<n> = its suspected bug; mouse and pad where the page has a pad path):
--   J1  open the tab: the strip's J (mouse), the D-pad Character wheel's Tabs slice (the wheel's own run), the
--       Character strip's tab by the pad's A; the strip's order (Identity, Journal, Skills); the page strip's tabs
--   J2  a page change clears the Log search and the Notebooks and Papers search; a paper's quick look stays open
--   J3  safe mode: the Character window does not open; Write note opens the game's journal window, not ZeD's reader
--   J4  an add-on's page (when one is registered): its tab while visible, switched off with the page open (its own
--       visible() held false for the leg, put back): the strip and the page fall back; openPage while off
--   J5  an empty log: "No entries yet", the stops kills, write, picks and Save
--   J6  Save (mouse, then pad A on Save): the entry's date and clock against getGameTime, its survival day against
--       getHoursSurvived, the stamp, the box and picks cleared, the month head's words (the game's month name, the year)
--   J7  tags: Injury then Danger ticked, kept in TAGS order; their words on the head; four tags squares alone; a tag
--       key this version does not know: not drawn, no error
--   J8  text edges and B6, B7: nothing, spaces only, newlines inside, 500 letters, a 4-line entry's stripe
--   J9  month groups out of order across two years: newest first; a fold by the mouse and by the pad's A
--   J10 B10: an old entry with no survivalDay across a 31-day month: its Day n against the calendar
--   J11 search: the words or a tag's word; a tag pressed on an entry (mouse, pad A); X on a stop clears it
--   J12 delete with a narrowed search: Cancel keeps all, Delete takes exactly that entry; the pad's landing; B8 (the
--       mouse on another cross and a month head with the question up); B12 (the question after another tab)
--   J13 kills by kind and B9: zombies made harmless beside him and killed with the game's own Hit by an axe (2), a
--       spear, a bat, a pistol, bare hands and a pipe bomb (2): the head against getZombieKills plus fire, each row
--       against the kills staged, the rows add up; the head folded by the mouse and the pad; B9's press beside it
--   J14 an old kill table (no v, inflated rows) rebuilt from the game's count
--   J15 the Log has no time survived (a NOTE of the game's getTimeSurvived)
--   J16 Into's cycle (mouse, pad A); the picked book dropped
--   J17 Into writes: Writing..., the page's last line, the entry's source; a full page 1 goes to page 2
--   J18 Into's refusals: no pencil, too dark, locked by you, a full book
--   J19 an Into write stopped by the pad's B on a Log stop, and by the game's own stop (forceStop)
--   J20 B1: Save twice while the Into write runs (mouse, then pad A A)
--   J21 odd books and B3: five sheets, an index card, a birthday card, a blank ID card, a notepad
--   J22 newlines into a book: one line on the page and in the entry
--   J23 none carried: the Writing block, Papers on you, Books on you against isLiteratureRead; a paper row opens Papers
--   J24 the Notebooks list: kind lines, a click picks, the last written page, < and > greyed at the ends
--   J25 the quick note and B2: Write, the lines left, a full page, 160 letters, Enter, the pad's A on the note
--   J26 the quick note's refusals: no pencil, dark, locked by you, locked by another (J49's single-player half)
--   J27 Open full: written with and without a pencil, blank with none, dark
--   J28 the Notebooks search: a word on page 4 of one book; a word in none
--   J29 a notebook in a bag: Write takes it out and leaves it in his main inventory
--   J30 the Papers list: one row for two copies, read first then by title, the count line, each row's state
--   J31 Show (News, Flyers, On map, All), a title word, a press outside the open list
--   J32 Read on an unread piece: the pad's B stops the read (J43); Read through: ISReadABook, the reader, the row
--       Read; in the dark greyed with Too dark; B4 with the Illiterate trait (the game's own filter as the baseline)
--   J33 a read piece: Open full with no timed action; Show place (the squares recorded, not marked); the D-pad on the
--       words; B back to the list
--   J34 a piece read by the game's own read with the tab open turns Read; the open piece taken away: back to the list
--   J35 Recipes against the game: each row's status, what the game would list, a pick, Sort Name, Show Known, a
--       search, Open in Craft or Build; B11 a NOTE
--   J36 a recipe learned with the page open turns unlocked
--   J37 SeeNotLearntRecipe off and on (put back); MetaKnowledge a NOTE
--   J38 recorded media carried are listed nowhere (a gap: NOTE)
--   J39 a notebook and three skill books carried: no book listed on Notebooks (a gap: NOTE)
--   J40 the pad's tour of the Log: the D-pad Down's order, A on each kind, X clears the search only while there is
--       one; B on a stop with nothing running (J43)
--   J41 a long log (80 entries over six months): the walk down to the last cross and back; tags and crosses beyond a
--       view's height are no stops; frame time (NOTE)
--   J42 the pad's tour of Notebooks and Papers: no stop on a hidden note; the Show list holds the pad; a quick look
--   J44 an item card over the Log: the write box, Save in the part left showing and still saving
--   J45 the half card (220, held in by the window's width cap) at the text size found and Large: the picks' rows, a
--       long date cut, the Notebooks page bar, Into's label, the paper rows. Pictures jn_half_log_<WxH>,
--       jn_half_notebook_<WxH>
--   J46 the words in the run's language (others SKIP): month names, kills rows, the Notebooks status line
--   J47 Dark, Light, High contrast: unread paper rows by tone (4.5 : 1 at least), the tag colors, the paper tone.
--       Pictures jn_theme_<theme>_<WxH>
--   J48 the death record as built at death (ZeD.Death.capture, no death): the kills line and the newest entry
--   J49-J52, B5 SKIP (multiplayer, split view); B13 drift a NOTE
--   Pictures jn_log_<WxH> (the Log), jn_notebook_<WxH> (a notebook picked), jn_papers_<WxH> (a quick look)
--   every case: no Lua error over it; the journal put back exactly
-- Puts back: the journal entries he had (the same entry tables in the same order, his entries' words checked; every
-- entry the run made taken away; the table nil again when he had none), the kill count and ZeD_Kills, the Fav: weapon
-- counts and every skill's XP and level, every zombie and corpse made, every thing given (the notebooks, papers, pencils,
-- bags, weapons), his own writing tools, notebooks, papers and books set aside for the run and given back, the read
-- marks the run added (getReadPrintMedia), the read pages of the skill book, the recipe learned, the Illiterate trait,
-- the sandbox's SeeNotLearntRecipe, the game's auto reveal option, safe mode, the death record, the Journal's page, the
-- kills fold, the month folds, the searches, the picks, the Into pick, the Papers filter, the picked notebook, the
-- window's width cap and layout, the Character window's tab, the World window's tab, the theme and the text size, the
-- input lock, the pad focus, the pointer, the draw watchers, the time of day, game speed 1, god mode and invincible,
-- where he stood.

if not (RT and RT.make) then
    print("ZEDQA jn_tab ERR rt_kit.lua did not run first")
    print("ZEDQA jn_tab VERDICT FAIL 1")
    print("ZEDQA jn_tab DONE")
    return
end
local Q = RT.make("jn_tab")
Q.maxMs = 2200000                    -- (the runner gives this script 2400 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, errs = 0, dead = false, xp = {},
            said = {}, texts = {}, rects = {}, rec = {}, recR = {}, jf = 0, zs = {}, readAdded = {}, held = {} }
local H = {}
local C = {}
S.JT = ZeD and ZeD.JournalTab
S.JR = ZeD and ZeD.JournalReaders
S.N = ZeD and ZeD.Notes
S.KT = ZeD and ZeD.KillTracker
S.F = RT.focus()
S.NL = string.char(10)
S.NOON = 12
S.WRITE_TAGS = { "WRITE", "BLUE_PEN", "PEN", "PENCIL", "RED_PEN", "GREEN_PEN" }
S.TAG_ORDER = { "danger", "loot", "news", "food", "weather", "base", "travel", "injury" }
S.THEMES = { { key = "dark", say = "Dark" }, { key = "light", say = "Light" }, { key = "hicon", say = "High contrast" } }

if not (S.p and S.JT and S.JR and S.N and S.KT and ZeD_CharacterWindow and ZeD.Molecules) then
    Q.check(false, "the player, ZeD's Journal tab, its readers, the notes, the kill tracker and the Character window are loaded")
    Q.start()
    return
end

-- ===================================================================== small helpers
function H.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function H.note(s) Q.say("NOTE " .. tostring(s)) end
-- time, not frames: cond asked every drawn frame until it holds, at most ms; fn(ok)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 4000000, function()
        if S.dead then return true end
        local now = getTimestampMs()
        st.t = st.t or now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() if S.dead then return end; fn(st.ok == true) end)
end
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
function H.list(t, max)
    local o = {}
    for i, v in ipairs(t or {}) do
        if max and i > max then o[#o + 1] = "..."; break end
        o[#o + 1] = tostring(v)
    end
    return (#o > 0) and table.concat(o, ", ") or "none"
end
function H.n2(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.2f", x) end
function H.screen() local w, h = 0, 0; pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end); return math.floor(w), math.floor(h) end
function H.sizeTag() local w, h = H.screen(); return w .. "x" .. h end
function H.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function H.home() local f = S.found; if f.pos then H.goTo(f.pos.x, f.pos.y, f.pos.z) end; if f.dir then pcall(function() S.p:setDir(f.dir) end) end end
function H.zcall(fn)
    local ok, err = pcall(fn)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(err) end
    return ok
end
function H.has(s, sub) return type(s) == "string" and type(sub) == "string" and sub ~= "" and string.find(s, sub, 1, true) ~= nil end
function H.lang() local l = "?"; pcall(function() l = tostring(Translator.getLanguage():name()) end); return l end
function H.tr(key, a1, a2, a3) local s = tostring(key); pcall(function() s = ZeD.tr(key, a1, a2, a3) end); return s end
function H.gt(key) local s = tostring(key); pcall(function() s = getText(key) end); return s end
-- a string of n copies of s (no string.rep: built by hand)
function H.rep(s, n) local o = {}; for i = 1, n do o[i] = s end; return table.concat(o) end
function H.lines(n, word)
    local o = {}
    for i = 1, n do o[i] = tostring(word or "zq") .. " line " .. i end
    return table.concat(o, S.NL)
end
function H.tod(t) pcall(function() getGameTime():setTimeOfDay(t) end) end
function H.dark() local d = false; pcall(function() d = S.p:tooDarkToRead() and true or false end); return d end
function H.user() local u = nil; pcall(function() u = S.p:getUsername() end); return u end

-- ===================================================================== the timed-action queue (the game's)
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 10) end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.qfirst(ty) for _, a in ipairs(H.queue()) do if a.Type == ty then return a end end; return nil end

-- ===================================================================== things
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.ft(it) local s = "?"; if H.isItem(it) then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function H.nm(it) local s = "nothing"; if H.isItem(it) then pcall(function() s = tostring(it:getName()) end) end; return s end
function H.where(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getContainer() end) end; return c end
function H.inv() return S.p:getInventory() end
function H.ctypeOf(it)
    local c = H.where(it)
    if c == nil then return "no container" end
    if c == H.inv() then return "his main inventory" end
    local t = "?"
    pcall(function() t = tostring(c:getType()) end)
    return "the container " .. t
end
function H.known(ft) local ok = false; if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end; return ok end
function H.firstKnown(list) for _, ft in ipairs(list) do if H.known(ft) then return ft end end; return nil end
function H.walkInv(inv, out, depth)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        out[#out + 1] = it
        if depth < 4 and instanceof(it, "InventoryContainer") then
            local sub = nil
            pcall(function() sub = it:getInventory() end)
            if sub then H.walkInv(sub, out, depth + 1) end
        end
    end
end
function H.all() local out = {}; pcall(H.walkInv, H.inv(), out, 0); return out end
function H.mark(it)
    if not H.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    S.caseMade[#S.caseMade + 1] = it
    return it
end
function H.give(ft) if not ft then return nil end; local it = nil; pcall(function() it = H.inv():AddItem(ft) end); return H.mark(it) end
function H.giveTo(inv, ft) local it = nil; if inv and ft then pcall(function() it = inv:AddItem(ft) end) end; return H.mark(it) end
function H.loose(it)
    if not H.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
end
function H.removeItem(it)
    if not H.isItem(it) then return end
    H.loose(it)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            pcall(function() it:setWorldItem(nil) end)
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function H.gone(it) return H.where(it) == nil end
function H.sweepNew()
    local n = 0
    for _, it in ipairs(H.all()) do
        if not S.found.inv0[it] then H.removeItem(it); n = n + 1 end
    end
    return n
end
function H.hands()
    local f = S.found
    if not f.hands then return end
    pcall(function()
        local a, b = f.hands.p, f.hands.s
        S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
        S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
    end)
end
-- a writing tool by the game's own tags (ISInventoryPaneContextMenu's canBeWrite list)
function H.isTool(it)
    local yes = false
    for _, t in ipairs(S.WRITE_TAGS) do
        pcall(function() local tag = ItemTag and ItemTag[t]; if tag and it:hasTag(tag) then yes = true end end)
    end
    return yes
end
-- the things the cases count on being his only when given: writing tools, writable books, print media, Literature
function H.stashKind(it)
    if H.isTool(it) then return "tool" end
    local kind = nil
    pcall(function()
        local md = it:hasModData() and it:getModData() or nil
        if md and md.printMedia then kind = "paper"
        elseif it:getCategory() == "Literature" then kind = it:canBeWrite() and "book" or "read" end
    end)
    return kind
end
function H.stashMine()
    local n, kept = 0, 0
    for _, it in ipairs(H.all()) do
        if S.found.inv0[it] and not S.found.stashed[it] and H.stashKind(it) then
            local c, free = nil, false
            pcall(function()
                c = it:getContainer()
                free = it:getAttachedSlot() == -1 and not it:isEquipped() and not S.p:isEquippedClothing(it)
                    and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
            end)
            if c and free and pcall(function() c:Remove(it) end) then
                S.stash = S.stash or {}
                S.stash[#S.stash + 1] = { it = it, c = c }
                S.found.stashed[it] = true
                n = n + 1
            else
                kept = kept + 1
            end
        end
    end
    return n, kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash or {}) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        if H.where(s.it) == nil then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end
function H.toolNow() local t = false; pcall(function() t = S.N.hasWritingTool(S.p) end); return t end
-- the game's own count of his writing tools (his bags, recursively, by the game's tags)
function H.toolsHeld() local n = 0; for _, it in ipairs(H.all()) do if H.isTool(it) then n = n + 1 end end; return n end

-- ===================================================================== notebooks and papers (staging)
function H.book(ft, name)
    local it = H.give(ft)
    if it and name then pcall(function() it:setName(name); it:setCustomName(true) end) end
    return it
end
function H.page(it, i) local s = nil; pcall(function() s = it:seePage(i) end); return s or "" end
function H.setPage(it, i, text) pcall(function() for k = 1, i - 1 do if it:seePage(k) == nil then it:addPage(k, "") end end; it:addPage(i, text) end) end
function H.pages(it) local n = 0; pcall(function() n = it:getPageToWrite() end); return n end
function H.endsWith(s, tail) s = tostring(s or ""); return #tail > 0 and #s >= #tail and string.sub(s, #s - #tail + 1) == tail end
function H.lineCount(s) if s == nil or s == "" then return 0 end; local n = 1; for _ in string.gmatch(s, S.NL) do n = n + 1 end; return n end
function H.id(it) local n = nil; pcall(function() n = it:getID() end); return n end
-- a paper: the item given with a piece on it (modData.printMedia, the game's own keys by its registry where it has them)
function H.paper(ft, id)
    local it = H.give(ft)
    if not it then return nil end
    pcall(function()
        local m = (ZeD.Print and ZeD.Print.ofId) and ZeD.Print.ofId(id) or { id = id, title = "Print_Media_" .. id .. "_title" }
        it:getModData().printMedia = { id = id, title = m.title, info = m.info, text = m.text }
        local t = getTextOrNull(m.title)
        if t then it:setName(t) end
    end)
    return it
end
function H.isRead(id) local r = false; pcall(function() r = S.p:isPrintMediaRead(id) and true or false end); return r end
function H.places(id)
    local n = 0
    pcall(function()
        local d = PrintMediaDefinitions.MiscDetails[id]
        for i = 1, 5 do if d and d["location" .. i] then n = i end end
    end)
    return n
end
-- read marks: added for a case and taken back at the end (only those he had not read)
function H.markRead(id)
    if H.isRead(id) then return end
    pcall(function() S.p:addReadPrintMedia(id) end)
    S.readAdded[#S.readAdded + 1] = id
end
function H.readBack()
    local left = {}
    for _, id in ipairs(S.readAdded) do
        pcall(function() local set = S.p:getReadPrintMedia(); if set then set:remove(id) end end)
        if H.isRead(id) then left[#left + 1] = id end
    end
    return left
end
-- a flyer id the game knows (its registry), unread by him, with n places at least (or exactly none: n = 0)
function H.pickFlyer(n, skip)
    local best = nil
    pcall(function()
        for id, d in pairs(PrintMediaDefinitions.MiscDetails) do
            local pl = H.places(id)
            local fits = (n == 0 and pl == 0) or (n > 0 and pl >= n)
            if not best and fits and not H.isRead(id) and not (skip and skip[id]) then
                local named = false
                pcall(function() local loc = ResourceLocation.of(id); named = (Flier.get(loc) or Brochure.get(loc)) ~= nil end)
                if named then best = id end
            end
        end
    end)
    return best
end

-- ===================================================================== the journal (his entries kept, the run's taken away)
function H.w() return RT.cw() end
function H.st() local w = RT.cw(); if not w then return nil end; if not w._jr then pcall(S.JR.scroll, w) end; return w._jr end
function H.md() return S.p:getModData() end
function H.ents() local md = H.md(); return md.ZeD_Journal and md.ZeD_Journal.entries or nil end
function H.entN() local e = H.ents(); return e and #e or 0 end
-- a staged entry, written into the player's data as an old save would hold it (pos: its place, 1 = newest)
function H.entAdd(t, pos)
    local md = H.md()
    md.ZeD_Journal = md.ZeD_Journal or { entries = {} }
    md.ZeD_Journal.entries = md.ZeD_Journal.entries or {}
    local e = md.ZeD_Journal.entries
    local gt = getGameTime()
    t.month = t.month or gt:getMonth()
    t.day = t.day or gt:getDay()
    t.year = t.year or gt:getYear()
    t.hour = t.hour or 9
    t.minute = t.minute or 30
    if t.noDay then t.noDay = nil else t.survivalDay = t.survivalDay or 3 end
    t.text = t.text or "ZQA entry"
    table.insert(e, math.max(1, math.min(pos or 1, #e + 1)), t)
    local w = RT.cw()
    if w then w._journalCache = nil; w._journalGroupCache = nil end
    return t
end
function H.idxOf(entry) for i, e in ipairs(H.ents() or {}) do if e == entry then return i end end; return nil end
function H.entByText(text) for i, e in ipairs(H.ents() or {}) do if e.text == text then return e, i end end; return nil, nil end
function H.isMine(e) return S.found.jSet[e] == true end
-- the entries back as found: his tables, in his order, in his own list; the run's gone
function H.jClean()
    local f = S.found
    if not f.jRecorded then return end
    local md = H.md()
    if f.jHad == nil then
        md.ZeD_Journal = nil
    else
        if md.ZeD_Journal ~= f.jHad then md.ZeD_Journal = f.jHad end
        local E = f.jEnts
        if E then
            for i = #E, 1, -1 do E[i] = nil end
            for i, e in ipairs(f.jList) do E[i] = e end
            f.jHad.entries = E
        else
            f.jHad.entries = nil
        end
    end
    local w = RT.cw()
    if w then w._journalCache = nil; w._journalGroupCache = nil end
end
-- the run's entries in the list now (not his)
function H.runEnts() local o = {}; for _, e in ipairs(H.ents() or {}) do if not H.isMine(e) then o[#o + 1] = e end end; return o end
-- the window's Journal state cleared for a case (the found state is put back at the end)
function H.jUi()
    local w = RT.cw()
    if not w then return end
    w._journalAsk, w._journalAskRects, w._journalLand = nil, nil, nil
    pcall(S.JT.setSearch, w, "")
    pcall(function() if w._journalSearch then w._journalSearch:clear() end end)
    pcall(function() if w._flyerSearch then w._flyerSearch:clear() end end)
    w._flyerSearchText = ""
    pcall(S.JT.clearPicks, w)
    pcall(function() w._journalInput:clear() end)
    pcall(function() if w._jrNote then w._jrNote:clear() end end)
    w._killsExpanded = false
    w._journalGroupCollapsed = {}
    w._journalCache, w._journalGroupCache = nil, nil
    local s = H.st()
    if s then
        s.logInto, s.logMsg, s.logPending, s.msg, s.pending = nil, nil, nil, nil, nil
        s.paperOpen, s.showOpen, s.showZones = nil, nil, nil
        s.filter = "all"
        s.carried = nil
    end
end

-- ===================================================================== the drawer: presses and what it drew
function H.drawer() local w = RT.cw(); return w and w._drawerPanel or nil end
function H.mid(z) return z.x + math.floor((z.w or 0) / 2), z.y + math.floor((z.h or 0) / 2) end
-- a press and its release on the drawer at x, y (drawer-local), through its own handlers
function H.click(x, y)
    local d = H.drawer()
    if not d then return false end
    local ok = H.zcall(function() d:onMouseDown(x, y) end)
    pcall(function() d:onMouseUp(x, y) end)
    return ok
end
function H.clickZ(z) if not z then return false end; local x, y = H.mid(z); return H.click(x, y) end
function H.jrZone(id) local w = RT.cw(); for _, z in ipairs((w and w._jrZones) or {}) do if z.id == id then return z end end; return nil end
function H.jrIds(pre)
    local w = RT.cw()
    local o = {}
    for _, z in ipairs((w and w._jrZones) or {}) do
        if pre == nil or string.sub(tostring(z.id), 1, #pre) == pre then o[#o + 1] = tostring(z.id) .. (z.fn and "" or "(grey)") end
    end
    return o
end
-- a Notebooks or Papers zone pressed: the drawer's click at its middle; where the click is not taken (outside the
-- page's view) it is pressed as the pad's A presses it, said once per zone
function H.jrPress(id, what)
    local z = H.jrZone(id)
    if not z then return false end
    local s = H.st()
    local x, y = H.mid(z)
    local c = s and s.clip
    local inView = (not c) or z.fixed or z.id == "into" or (x >= c.x and x < c.x + c.w and y >= c.y and y < c.y + c.h)
    if inView and z.fn then return H.click(x, y) end
    if z.fn then
        if not S.said[id] then S.said[id] = true; H.note(tostring(what) .. ": " .. id .. " sat outside the page's view: pressed as the pad's A presses it") end
        H.zcall(z.fn)
        return true
    end
    return false
end
-- a press through the drawer's own route (header, picks, tags, heads, crosses, kills, the readers' zones)
function H.press(z) return H.clickZ(z) end
function H.pageZone(i) local w = RT.cw(); for _, z in ipairs((w and w._journalTabZones) or {}) do if z.page == i then return z end end; return nil end
function H.pageClick(i) local z = H.pageZone(i); if z then return H.clickZ(z) end; return false end
function H.pickZone(k) local w = RT.cw(); for _, z in ipairs((w and w._journalPickZones) or {}) do if z.k == k then return z end end; return nil end
function H.tagZone(idx, k)
    local w = RT.cw()
    for _, z in ipairs((w and w._journalTagZones) or {}) do if z.entryIdx == idx and (k == nil or z.k == k) then return z end end
    return nil
end
function H.delZone(idx) local w = RT.cw(); for _, z in ipairs((w and w._journalDeleteZones) or {}) do if z.entryIdx == idx then return z end end; return nil end
function H.groupZone(key) local w = RT.cw(); for _, z in ipairs((w and w._journalGroupZones) or {}) do if z.id == key then return z end end; return nil end
-- the window's Save button: its own press and release, the pointer held over it
function H.saveClick()
    local w = RT.cw()
    local b = w and w._journalSaveBtn
    if not b then return false end
    local vis = false
    pcall(function() vis = b:isVisible() end)
    if not vis then return false end
    H.zcall(function() b:onMouseDown(2, 2); b._hovered = true; b:onMouseUp(2, 2) end)
    return true
end
function H.type(text) local w = RT.cw(); pcall(function() w._journalInput:setText(text) end) end
function H.boxText() local w = RT.cw(); local t = nil; pcall(function() t = w._journalInput:getText() end); return t end
-- the group key and the stamp the tab made for an entry (its own wrapped row, as drawn last frame)
function H.wrapOf(entry)
    local w = RT.cw()
    local ents = H.ents()
    if not (w and ents) then return nil end
    local groups = nil
    pcall(function() groups = S.JT.groups(w, ents, w._journalSearchText or "") end)
    for _, g in ipairs(groups or {}) do
        for _, wr in ipairs(g.entries or {}) do if wr.entry == entry then return wr, g end end
    end
    return nil
end
-- what the Journal drew last frame
function H.drewExact(s) for _, t in ipairs(S.texts or {}) do if t.s == s then return t end end; return nil end
function H.drewI(sub) local l = string.lower(tostring(sub)); for _, t in ipairs(S.texts or {}) do if H.has(string.lower(t.s), l) then return t end end; return nil end
function H.drewLike(sub, max) local o = {}; for _, t in ipairs(S.texts or {}) do if H.has(t.s, sub) then o[#o + 1] = t.s end end; return H.list(o, max or 6) end
-- a drawn word cut with "..." at its end: starts like the whole
function H.drewCut(whole)
    for _, t in ipairs(S.texts or {}) do
        local s = t.s
        if #s >= 4 and string.sub(s, #s - 2) == "..." and string.sub(whole, 1, #s - 3) == string.sub(s, 1, #s - 3) then return t end
    end
    return nil
end
function H.drewOrCut(s) return H.drewI(s) or H.drewCut(s) end
function H.onLog() local w = RT.cw(); return w ~= nil and w._activeTab == "journal" and (w._journalSubTab or 1) == 1 end
function H.onPage(i) local w = RT.cw(); return w ~= nil and w._activeTab == "journal" and (w._journalSubTab or 1) == i end
-- the pair open, the Journal tab up, on page i (set directly: a page press is its own check)
function H.front(i)
    RT.pairOpen()
    local w = RT.cw()
    if not w then return false end
    if w._activeTab ~= "journal" then RT.charTab("journal") end
    if i and (w._journalSubTab or 1) ~= i then pcall(S.JT.setPage, w, i) end
    return true
end
-- queue: the tab up on page i and drawn three times since
function H.frontQ(T, i)
    H.step(1, function() if T.off then return end; H.front(i); T.jf0 = S.jf end)
    H.wait(4000, function() return T.off or (H.onPage(i) and S.jf >= (T.jf0 or 0) + 3) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the Journal tab is up on page " .. i, "tab " .. tostring(RT.cw() and RT.cw()._activeTab) .. ", page " .. tostring(RT.cw() and RT.cw()._journalSubTab) .. ", frames " .. (S.jf - (T.jf0 or 0))) then T.off = true end
    end)
end
-- queue: n Journal frames drawn
function H.drawn(T, n)
    H.step(1, function() T.jf1 = S.jf end)
    H.wait(3000, function() return T.off or S.jf >= (T.jf1 or 0) + (n or 3) end, function() end)
end

-- ===================================================================== the draw watched (on for the run)
-- the drawer panel's drawText, drawTextRight, drawTextCentre and drawRect wrapped: every word and every rectangle drawn
-- while the Journal draws; a frame is one JournalReaders.beginFrame to the next (S.texts / S.rects: the last whole one).
-- (run 1, Nov 27 2026: the Character window is made again each time it opens (CW:4490-4492 drops it), so its drawer
-- is a new panel: every drawer a Journal frame starts on is wrapped, from the readers' frame start)
function H.hookDrawer(W, d)
    if not d or W.hooked[d] then return end
    local R = { d = d, own = {} }
    W.hooked[d] = R
    W.list[#W.list + 1] = R
    W.d = d
    for _, k in ipairs({ "drawText", "drawTextRight", "drawTextCentre" }) do
        local own = nil
        pcall(function() own = rawget(d, k) end)
        R.own[k] = own or false
        local base = d[k]
        if base then
            d[k] = function(self, text, tx, ty, ...)
                local r = S.rec
                if r and #r < 3000 then r[#r + 1] = { s = tostring(text), x = tonumber(tx) or 0, y = tonumber(ty) or 0 } end
                return base(self, text, tx, ty, ...)
            end
        end
    end
    local ownR = nil
    pcall(function() ownR = rawget(d, "drawRect") end)
    R.own.drawRect = ownR or false
    local baseR = d.drawRect
    if baseR then
        d.drawRect = function(self, rx, ry, rw, rh, a, cr, cg, cb)
            local st = S.stripe
            if st and a == st.a and cr == st.r and cg == st.g and cb == st.b then
                local r = S.recR
                if r and #r < 400 then r[#r + 1] = { x = tonumber(rx) or 0, y = tonumber(ry) or 0, w = tonumber(rw) or 0, h = tonumber(rh) or 0 } end
            end
            return baseR(self, rx, ry, rw, rh, a, cr, cg, cb)
        end
    end
end
function H.wrapOn()
    if S.w0 then return end
    local d = H.drawer()
    if not d then return end
    local W = { hooked = {}, list = {}, bf = S.JR.beginFrame }
    S.w0 = W
    H.hookDrawer(W, d)
    W.bfFn = function(win)
        S.texts, S.rects = S.rec, S.recR
        S.rec, S.recR = {}, {}
        S.jf = S.jf + 1
        pcall(function() S.stripe = ZeD.T.stripe end)
        pcall(function() local dd = win and win._drawerPanel; if dd and dd ~= W.d then H.hookDrawer(W, dd); S.rehooks = (S.rehooks or 0) + 1 end end)
        return W.bf(win)
    end
    S.JR.beginFrame = W.bfFn
end
function H.wrapOff()
    local W = S.w0
    if not W then return end
    for _, R in ipairs(W.list) do
        for k, own in pairs(R.own) do
            local d = R.d
            if own then d[k] = own else pcall(function() rawset(d, k, nil) end) end
        end
    end
    if S.JR.beginFrame == W.bfFn then S.JR.beginFrame = W.bf end
    S.w0 = nil
end
function H.wrapped()
    local W = S.w0
    if not W then return true end
    return S.JR.beginFrame == W.bf
end

-- ===================================================================== the pad (th_tab's, on the Character window)
function H.lockFound()
    local key = nil
    pcall(function()
        local o = H.zopt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
function H.padOn()
    local Det = ZeD.Input and ZeD.Input.Detector
    if not (Det and Det.setLockedMode and S.F) then return false end
    if S.lockWas == nil then S.lockWas = H.lockFound() end
    pcall(Det.setLockedMode, "gamepad")
    S.back.pad = true
    local w = RT.cw()
    if w then pcall(S.F.releaseFocus, S.pn); pcall(S.F.claimFocus, w) end
    return true
end
function H.padOff()
    if not S.back.pad then return end
    S.back.pad = nil
    for _, b in ipairs({ "A", "B", "X", "Y" }) do RT.pad(b, nil) end
    pcall(function() S.F.releaseFocus(S.pn) end)
    local Det = ZeD.Input and ZeD.Input.Detector
    pcall(function()
        Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
    end)
end
function H.stops()
    local w = RT.cw()
    for _, z in ipairs((w and w._focusRing) or {}) do if z.zone == "charTabContent" then return z.elements or {} end end
    return {}
end
function H.stopIds(max) local o = {}; for _, e in ipairs(H.stops()) do o[#o + 1] = tostring(e.id) end; return H.list(o, max or 24) end
function H.stopHas(id) for _, e in ipairs(H.stops()) do if e.id == id then return e end end; return nil end
function H.focEl() local w = RT.cw(); local e = nil; pcall(function() e = S.F.getFocusedElement(w) end); return e end
function H.focId() local e = H.focEl(); return e and e.id or nil end
function H.focusOn(pred)
    local w = RT.cw()
    if not (w and S.F and S.F.focusWhere) then return nil end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "charTabContent", pred) end)
    return e
end
function H.focusId(id) return H.focusOn(function(el) return el.id == id end) ~= nil end
-- a tap: the QA hook holds the button, FocusManager's dispatch takes the press on the Character window, up after 4
-- frames, then the hook lets go (gate false: nothing pressed)
function H.tap(name, joy, gate)
    local st = {}
    H.step(1, function()
        if gate and not gate() then return end
        st.on = true
        RT.pad(name, true)
        if joy then RT.padDown(Joypad[joy], RT.cw()) end
    end)
    H.step(4, function() if st.on then RT.pad(name, false) end end)
    H.step(4, function() if st.on then RT.pad(name, nil) end end)
end
function H.tapA(gate) H.tap("A", "AButton", gate) end
function H.tapB(gate) H.tap("B", "BButton", gate) end
function H.tapX(gate) H.tap("X", "XButton", gate) end
function H.dir(d) return RT.padDir(d, RT.cw()) end
function H.kbUp() local v = false; pcall(function() v = ZeD.Keyboard.isVisible() and true or false end); return v end
function H.kbHide() pcall(function() ZeD.Keyboard.hide() end) end

-- ===================================================================== theme, text size, pictures, the half card
function H.theme(key)
    local o = H.zopt("baseTheme")
    local i = nil
    for k, v in ipairs((ZeD.Settings and ZeD.Settings.baseKeys) or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.back.theme = true
end
function H.themeBack()
    if not S.back.theme then return end
    S.back.theme = nil
    local o = H.zopt("baseTheme")
    if o and S.found.baseIdx then pcall(function() o:setValue(S.found.baseIdx) end) end
    pcall(ZeD.applyTheme, S.found.base, nil, nil)
end
function H.sizeSet(key)
    local o = H.zopt("textSize")
    local i = nil
    for k, v in ipairs((ZeD.Settings and ZeD.Settings.sizeKeys) or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, nil, nil, key)
    S.back.size = true
end
function H.sizeBack()
    if not S.back.size then return end
    S.back.size = nil
    local o = H.zopt("textSize")
    if o and S.found.sizeIdx then pcall(function() o:setValue(S.found.sizeIdx) end) end
    pcall(ZeD.applyTheme, nil, nil, S.found.size)
end
function H.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return -9000 end
            getMouseY = function() return -9000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function H.shot(name, what, gate)
    Q.step(1, function() if not S.dead and (gate == nil or gate()) then H.park(true) end end)
    Q.step(4, function()
        if S.dead or not (gate == nil or gate()) then H.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then H.note("picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else H.note("the picture " .. name .. " was not taken: " .. tostring(e)) end
        H.park(false)
    end)
    Q.waitMs(1200)
end
function H.drawerW() local w = RT.cw(); return math.floor((w and w._drawerEffW) or 0) end
function H.isHalf() local w = RT.cw(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(220)) <= 1 end
-- queue: the drawer held in to the half card (th_tab's way: the window's half-screen cap lowered to 620 units); T.half
function H.halfOn(T)
    H.step(2, function()
        T.half = nil
        if T.off then return end
        local w = RT.cw()
        if w and not H.isHalf() then
            if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
            S.layoutTouched = true
            w._maxWinW = ZeD.T.px(620)
        end
        T.hs = { last = -1, n = 0 }
    end)
    H.wait(6000, function()
        if T.off then return true end
        local e = H.drawerW()
        if e == T.hs.last then T.hs.n = T.hs.n + 1 else T.hs.last, T.hs.n = e, 0 end
        return T.hs.n >= 8 and H.isHalf()
    end, function(ok) if not T.off then T.half = ok end end)
end
function H.halfBack()
    if not S.back.maxW then return end
    local w = RT.cw()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end

-- ===================================================================== kills (zombies made harmless, the game's own Hit)
function H.copy(t) if type(t) ~= "table" then return t end; local o = {}; for k, v in pairs(t) do o[k] = H.copy(v) end; return o end
function H.kills() local n = nil; pcall(function() n = S.p:getZombieKills() end); return n end
function H.favSnap() local o = {}; pcall(function() for k, v in pairs(S.p:getModData()) do if type(k) == "string" and string.sub(k, 1, 4) == "Fav:" then o[k] = v end end end); return o end
function H.killsBack()
    local f = S.found
    if not f.kRecorded then return end
    pcall(function() S.p:setZombieKills(f.kills) end)
    local md = H.md()
    md.ZeD_Kills = H.copy(f.zk)
    pcall(function()
        local drop = {}
        for k, _ in pairs(md) do if type(k) == "string" and string.sub(k, 1, 4) == "Fav:" and f.fav[k] == nil then drop[#drop + 1] = k end end
        for _, k in ipairs(drop) do md[k] = nil end
        for k, v in pairs(f.fav) do md[k] = v end
    end)
end
function H.bodiesNear(r)
    local out = {}
    local px, py = math.floor(S.p:getX()), math.floor(S.p:getY())
    for x = px - r, px + r do
        for y = py - r, py + r do
            local sq = getCell():getGridSquare(x, y, 0)
            if sq then
                local l = sq:getStaticMovingObjects()
                for i = 0, l:size() - 1 do
                    local o = l:get(i)
                    if instanceof(o, "IsoDeadBody") then out[#out + 1] = { sq = sq, body = o } end
                end
            end
        end
    end
    return out
end
function H.sweepBodies()
    local n = 0
    local ok, list = pcall(H.bodiesNear, 12)
    for _, b in ipairs(ok and list or {}) do
        if not (S.found.bodies0 or {})[b.body] then
            pcall(function() b.sq:removeCorpse(b.body, false) end)
            pcall(function() b.sq:removeBlood(false, false) end)
            n = n + 1
        end
    end
    return n
end
function H.sweepZombies()
    local n = 0
    for _, z in ipairs(S.zs) do
        pcall(function()
            if z:getCurrentSquare() ~= nil or not z:isDead() then z:removeFromWorld(); z:removeFromSquare(); n = n + 1 end
        end)
    end
    S.zs = {}
    return n
end
-- a harmless zombie 2 tiles east of him
function H.spawnZ()
    local z = nil
    pcall(function()
        local list = addZombiesInOutfit(math.floor(S.p:getX()) + 2, math.floor(S.p:getY()), 0, 1, nil, 0)
        if list and list:size() > 0 then z = list:get(0) end
    end)
    if z then pcall(function() z:setUseless(true) end); S.zs[#S.zs + 1] = z end
    return z
end
function H.zDead(z) local d = true; pcall(function() d = z:isDead() or z:getHealth() <= 0 end); return d end

-- ===================================================================== skills (the hits give XP: put back)
function H.xpSnap()
    pcall(function()
        local xp = S.p:getXp()
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            S.xp[#S.xp + 1] = { perk = perk, xp = xp:getXP(perk), lvl = S.p:getPerkLevel(perk) }
        end
    end)
end
function H.xpBack()
    local grew, left = 0, 0
    pcall(function()
        local xp = S.p:getXp()
        for _, r in ipairs(S.xp) do
            if math.abs(xp:getXP(r.perk) - r.xp) > 0.001 or S.p:getPerkLevel(r.perk) ~= r.lvl then
                grew = grew + 1
                pcall(function()
                    S.p:setPerkLevelDebug(r.perk, r.lvl)
                    xp:setXPToLevel(r.perk, r.lvl)
                    local now = xp:getXP(r.perk)
                    if math.abs(r.xp - now) > 0.001 then xp:AddXPNoMultiplier(r.perk, r.xp - now) end
                end)
                if S.p:getPerkLevel(r.perk) ~= r.lvl then left = left + 1 end
            end
        end
    end)
    pcall(function() SyncXp(S.p) end)
    return grew, left
end
function H.hasTrait(key) local has = false; pcall(function() local ct = CharacterTrait[key]; if ct then has = S.p:hasTrait(ct) and true or false end end); return has end
function H.setTrait(key, on)
    pcall(function()
        local ct = CharacterTrait[key]
        if not ct then return end
        if on and not S.p:hasTrait(ct) then S.p:getCharacterTraits():add(ct) end
        if not on and S.p:hasTrait(ct) then S.p:getCharacterTraits():remove(ct) end
    end)
end

-- ===================================================================== a case's start and end
function H.readerShut() pcall(function() local r = ZeD.Reader.get(S.pn); if r and r:isReallyVisible() then r:close() end end) end
function H.readerUp() local r = nil; pcall(function() r = ZeD.Reader.get(S.pn) end); local up = false; if r then pcall(function() up = r:isReallyVisible() end) end; return up and r or nil end
function H.legClean()
    H.speed(1)
    H.qstop()
    H.padOff()
    H.park(false)
    H.kbHide()
    H.readerShut()
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    S.caseMade = {}
    H.sweepNew()
    H.jClean()
    H.jUi()
    H.tod(S.NOON)
    H.hands()
end
function H.caseStart(T)
    S.caseMade = {}
    T.t0 = getTimestampMs()
    H.legClean()
    H.front(1)
    return true
end
function H.caseEnd(label)
    H.step(2, function()
        H.legClean()
        H.halfBack()
        H.front(1)
    end)
    H.step(10, function()
        local e1 = H.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, label .. ": no Lua error over the case",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        if S.zerr then Q.check(false, label .. ": nothing ZeD ran for the case threw", S.zerr); S.zerr = nil end
        S.e0 = e1
        local mine = 0
        for _, e in ipairs(H.ents() or {}) do if H.isMine(e) then mine = mine + 1 end end
        if mine ~= #S.found.jList or #H.runEnts() > 0 then
            Q.check(false, label .. ": his journal entries are back as found after the case", mine .. " of his " .. #S.found.jList .. ", " .. #H.runEnts() .. " of the run's left")
        end
    end)
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        if not (S.F and S.F.focusWhere and S.F.claimFocus and ISTimedActionQueue and ISInventoryPaneContextMenu and ZeD_TextEntry) then
            S.dead = true
            Q.check(false, "setup: the pad's focus manager and the game's queue and item menu are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "jn_tab") end
        H.speed(1)
        H.qstop()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.pair = RT.isOpen()
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.inv0, f.stashed = {}, {}
        for _, it in ipairs(H.all()) do f.inv0[it] = true end
        pcall(function() f.tod = getGameTime():getTimeOfDay() end)
        pcall(function() f.god = S.p:isGodMod() and true or false; S.p:setGodMod(true) end)
        pcall(function() f.invinc = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
        f.base, f.size = ZeD.currentBase, ZeD.currentSize
        f.baseIdx, f.sizeIdx = H.optVal(H.zopt("baseTheme")), H.optVal(H.zopt("textSize"))
        S.lockWas = H.lockFound()
        H.xpSnap()
        -- the kills, the favourite weapon counts, the corpses round him
        local md = H.md()
        f.kills, f.zk, f.fav = H.kills(), H.copy(md.ZeD_Kills), H.favSnap()
        f.kRecorded = true
        f.bodies0 = {}
        local okB, bl = pcall(H.bodiesNear, 12)
        for _, b in ipairs(okB and bl or {}) do f.bodies0[b.body] = true end
        -- his journal: the table, its list and each entry (the same tables come back, in this order)
        f.jHad = md.ZeD_Journal
        f.jEnts = f.jHad and f.jHad.entries or nil
        f.jList, f.jSet, f.jSig = {}, {}, {}
        for i, e in ipairs(f.jEnts or {}) do
            f.jList[i] = e
            f.jSet[e] = true
            f.jSig[i] = tostring(e.text) .. "|" .. tostring(e.month) .. "|" .. tostring(e.day) .. "|" .. tostring(e.year) .. "|" .. tostring(e.survivalDay)
        end
        f.jRecorded = true
        -- the windows and the Journal's own state
        RT.pairOpen()
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        local cw, ww = RT.cw(), RT.ww()
        f.ctab, f.wtab = cw and cw._activeTab, ww and ww._activeTab
        f.maxW = cw and cw._maxWinW
        if cw then
            f.sub, f.killsExp = cw._journalSubTab, cw._killsExpanded
            f.folds = H.copy(cw._journalGroupCollapsed or {})
            f.picks = H.copy(cw._journalPicks)
            f.search = cw._journalSearchText
        end
        RT.charTab("journal")
        local s = H.st()
        if s then f.jr = { logInto = s.logInto, filter = s.filter, nbId = s.nbId, paperOpen = s.paperOpen, nbPage = H.copy(s.nbPage) } end
        f.illit = H.hasTrait("ILLITERATE")
        pcall(function() f.seeUnknown = getSandboxOptions():getOptionByName("SeeNotLearntRecipe"):getValue() end)
        pcall(function() f.autoReveal = getCore():getOptionAutoRevealPrintMediaMapLocations() end)
        f.safe = H.optVal(ZeD.Settings and ZeD.Settings.safeModeOption)
        f.death = ZeD.Death and ZeD.Death.records and ZeD.Death.records[S.pn]
        f.recorded = true
        S.back.on = true
        H.wrapOn()
        local aside, kept = H.stashMine()
        f.toolsKept = H.toolsHeld()
        H.note("setup: " .. aside .. " of his own writing tools, notebooks, papers and books set aside for the run" .. (kept > 0 and (", " .. kept .. " worn or held stay") or ""))
        H.tod(S.NOON)
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", screen " .. H.sizeTag() .. ", language " .. H.lang()
            .. ", " .. #f.jList .. " journal entries, kills " .. tostring(f.kills) .. ", Journal page " .. tostring(f.sub) .. ", input lock " .. tostring(S.lockWas)
            .. ", theme " .. tostring(f.base) .. ", text " .. tostring(f.size) .. ", drawer " .. H.drawerW() .. " px, safe mode option " .. tostring(f.safe))
        Q.check(S.w0 ~= nil, "setup: the Journal's draw is watched (the drawer's text and the readers' frame)")
    end)
    H.wait(5000, function() return S.jf >= 3 end, function(ok)
        Q.check(ok, "setup: the Journal tab draws", S.jf .. " frames seen")
        if not ok then S.dead = true end
    end)
end

-- ===================================================================== put back
function H.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    H.speed(1)
    H.qstop()
    H.park(false)
    H.padOff()
    H.kbHide()
    H.readerShut()
    H.halfBack()
    H.themeBack()
    H.sizeBack()
    H.legClean()
    S.zSwept = H.sweepZombies()
    S.bSwept = H.sweepBodies()
    for _, it in ipairs(S.made) do H.removeItem(it) end
    H.killsBack()
    S.xpGrew, S.xpLeft = H.xpBack()
    S.readLeft = H.readBack()
    if S.back.pages then pcall(function() S.p:setAlreadyReadPages(S.back.pages.ft, S.back.pages.n) end); S.back.pages = nil end
    if S.back.recipe then pcall(function() if not S.back.recipe.was then S.p:getKnownRecipes():remove(S.back.recipe.name) end end); S.back.recipe = nil end
    H.setTrait("ILLITERATE", f.illit == true)
    if f.seeUnknown ~= nil then pcall(function() getSandboxOptions():getOptionByName("SeeNotLearntRecipe"):setValue(f.seeUnknown) end) end
    if f.autoReveal ~= nil then pcall(function() getCore():setOptionAutoRevealPrintMediaMapLocations(f.autoReveal) end) end
    if S.back.safe then
        pcall(function() ZeD.Settings.safeModeOption:setValue(f.safe) end)
        pcall(function() ZeD.Safe.reread() end)
        S.back.safe = nil
    end
    if ZeD.Death and ZeD.Death.records then ZeD.Death.records[S.pn] = f.death end
    if S.back.addon then pcall(function() S.back.addon.def.visible = S.back.addon.visible end); S.back.addon = nil end
    H.wrapOff()
    pcall(function() getGameTime():setTimeOfDay(f.tod) end)
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        H.putBack()
        H.home()
    end)
    Q.step(10, function()
        local f = S.found
        if not f.recorded then return end
        S.swept = H.sweepNew()
        S.lost = H.unstash()
        H.hands()
        H.home()
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "jn_tab") end
        local w = RT.cw()
        if w then
            w._maxWinW = f.maxW
            if f.sub then pcall(S.JT.setPage, w, f.sub) end
            w._killsExpanded = f.killsExp
            w._journalGroupCollapsed = H.copy(f.folds or {})
            w._journalPicks = H.copy(f.picks)
            pcall(S.JT.setSearch, w, f.search or "")
            local s = H.st()
            if s and f.jr then
                s.logInto, s.filter, s.nbId, s.paperOpen = f.jr.logInto, f.jr.filter or "all", f.jr.nbId, f.jr.paperOpen
                s.nbPage = f.jr.nbPage or {}
                s.carried = nil
            end
        end
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then return end
        pcall(ZeD_CharacterWindow.openTab, S.pn, f.ctab or "loot")
        if f.wtab then RT.worldTab(f.wtab) end
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        -- the journal: his tables, his order, his words; the run's gone
        local md = H.md()
        local E = H.ents()
        local same = (md.ZeD_Journal == f.jHad) and ((f.jHad == nil) or (f.jHad.entries == f.jEnts))
        local n, order, words = E and #E or 0, true, true
        for i, e in ipairs(f.jList) do
            if not (E and E[i] == e) then order = false end
            local sig = tostring(e.text) .. "|" .. tostring(e.month) .. "|" .. tostring(e.day) .. "|" .. tostring(e.year) .. "|" .. tostring(e.survivalDay)
            if sig ~= f.jSig[i] then words = false end
        end
        Q.check(same and n == #f.jList and order and words, "put back: his journal entries come back exactly as found (the same entries, in order, their words unchanged)",
            n .. " entries (found " .. #f.jList .. "), the table " .. (same and "his" or "NOT his") .. ", order " .. tostring(order) .. ", words " .. tostring(words)
            .. ((f.jHad == nil) and ", he had no journal: none now " .. tostring(md.ZeD_Journal == nil) or ""))
        local left = {}
        for _, it in ipairs(S.made) do if not H.gone(it) then left[#left + 1] = H.ft(it) end end
        Q.check(#left == 0, "put back: every thing the run gave is gone (notebooks, papers, pencils, bags, weapons)", #S.made .. " given; left " .. H.list(left, 8))
        local extra = {}
        for _, it in ipairs(H.all()) do if not f.inv0[it] then extra[#extra + 1] = H.ft(it) end end
        Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (his set-aside things back)",
            "new " .. H.list(extra, 8) .. "; " .. tostring(S.swept) .. " swept, " .. tostring(S.lost) .. " set-aside things not given back")
        local zk = md.ZeD_Kills
        local zkSame = (f.zk == nil and zk == nil) or (f.zk ~= nil and zk ~= nil and tostring(zk.fire) == tostring(f.zk.fire) and tostring(zk.v) == tostring(f.zk.v)
            and tostring(zk.vehicle) == tostring(f.zk.vehicle) and tostring(zk.explosion) == tostring(f.zk.explosion))
        Q.check(H.kills() == f.kills and zkSame, "put back: the game's kill count and ZeD's kill rows as found", tostring(H.kills()) .. " (found " .. tostring(f.kills) .. "), rows " .. tostring(zkSame))
        Q.check((S.xpLeft or 0) == 0, "put back: every skill level as found", tostring(S.xpGrew) .. " skills touched, " .. tostring(S.xpLeft) .. " not at their level")
        Q.check(#(S.readLeft or {}) == 0, "put back: the read marks the run added are gone (the game's read print media)", H.list(S.readLeft))
        local see = nil
        pcall(function() see = getSandboxOptions():getOptionByName("SeeNotLearntRecipe"):getValue() end)
        Q.check(H.hasTrait("ILLITERATE") == (f.illit == true) and see == f.seeUnknown, "put back: the Illiterate trait and the sandbox's SeeNotLearntRecipe as found",
            "illiterate " .. tostring(H.hasTrait("ILLITERATE")) .. ", SeeNotLearntRecipe " .. tostring(see) .. " (found " .. tostring(f.seeUnknown) .. ")")
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and H.qlen() == 0 and getGameSpeed() == 1, "put back: he stands where he stood, no action queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
        local w = RT.cw()
        Q.check(ZeD.currentBase == f.base and ZeD.currentSize == f.size and H.lockFound() == (S.lockWas or H.lockFound()) and S.parked == nil
            and S.back.maxW == nil and S.w0 == nil and (w == nil or w._maxWinW == f.maxW) and H.wrapped(),
            "put back: the theme, the text size, the input lock, the width cap, the pointer and the draw watchers as found",
            tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", lock " .. H.lockFound() .. ", width cap " .. tostring(w and w._maxWinW))
        Q.check(w == nil or ((w._journalSubTab or 1) == (f.sub or 1) and w._killsExpanded == f.killsExp), "put back: the Journal's page and the kills fold as found",
            "page " .. tostring(w and w._journalSubTab) .. " (found " .. tostring(f.sub) .. ")")
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught" .. (S.zerr and (": " .. S.zerr) or ""))
        local e1 = H.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the Journal run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the Journal run's Lua error count", "the game's Lua error count cannot be read here") end
        H.note("put back: " .. tostring(S.zSwept) .. " zombies and " .. tostring(S.bSwept) .. " corpses taken away")
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
        if f.recorded then
            pcall(function() if f.invinc ~= nil then S.p:setInvincible(f.invinc) end end)
            pcall(function() if f.god ~= nil then S.p:setGodMod(f.god) end end)
        end
    end)
end

-- ===================================================================== J1 open the tab
function C.j1()
    local T = { L = "J1 open the tab" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        RT.charTab("loot")
    end)
    H.wait(2000, function() local w = RT.cw(); return w ~= nil and w._activeTab == "loot" end, function() end)
    H.step(2, function() T.pressed = RT.charTab("journal"); T.jf0 = S.jf end)
    H.wait(3000, function() local w = RT.cw(); return w ~= nil and w._activeTab == "journal" and S.jf > (T.jf0 or 0) + 2 end, function(ok)
        local w = RT.cw()
        Q.check(ok and T.pressed, T.L .. " (mouse): the strip's Journal tab opens the Journal", "tab " .. tostring(w and w._activeTab))
        local tabs = RT.tabs(RT.charStrip())
        local iI, iJ, iS = nil, nil, nil
        for i, id in ipairs(tabs) do
            if id == "identity" then iI = i elseif id == "journal" then iJ = i elseif id == "skills" then iS = i end
        end
        Q.check(iI ~= nil and iJ ~= nil and iS ~= nil and iI < iJ and iJ < iS, T.L .. ": the strip holds Journal between Identity and Skills", H.list(tabs, 14))
        local shown = 4
        for _, def in ipairs(S.JT._pages.list or {}) do
            local vis = true
            if def.visible then pcall(function() vis = def.visible() and true or false end) end
            if vis then shown = shown + 1 end
        end
        local zones = (w and w._journalTabZones) or {}
        local words = {}
        for _, k in ipairs({ "UI_ZeD_Journal_TabJournal", "UI_ZeD_Journal_TabNotebooks", "UI_ZeD_Journal_TabPapers" }) do
            if not H.drewI(H.tr(k)) then words[#words + 1] = H.tr(k) end
        end
        if not H.drewI(H.gt("IGUI_LiteratureUI_Recipes")) then words[#words + 1] = H.gt("IGUI_LiteratureUI_Recipes") end
        Q.check(#zones == shown and #words == 0, T.L .. ": the page strip holds Log, Notebooks, the game's Recipes, Papers and each add-on page shown",
            #zones .. " tabs (want " .. shown .. "); words not drawn: " .. H.list(words))
        T.sub = w and w._journalSubTab
        if w then pcall(S.JT.setPage, w, 2) end
    end)
    -- the page picked is kept on the window for the session: shut and open again
    H.step(3, function() RT.pairShut() end)
    H.step(10, function() RT.pairOpen() end)
    H.step(10, function() RT.charTab("journal") end)
    H.step(5, function()
        local w = RT.cw()
        Q.check(w ~= nil and w._journalSubTab == 2, T.L .. ": the page picked (Notebooks) is kept when the window shuts and opens again (the map: kept for the session)",
            "page " .. tostring(w and w._journalSubTab) .. "; the window is made again on each open (CW:4490-4492 drops it, CW:4787 sets page 1; saveCharState keeps no Journal page)")
        H.note(T.L .. ": the first open of a session lands on the Log (win._journalSubTab = 1 at the window's making); a session's first open cannot be staged again here")
        if w then pcall(S.JT.setPage, w, 1) end
        RT.charTab("loot")
    end)
    -- the D-pad Character wheel's Tabs slice: Journal (the wheel's own run)
    H.step(5, function()
        local W = ZeD.DpadWheels and ZeD.DpadWheels.C
        T.wheel = nil
        if W and W.tabs then
            local ok, list = pcall(W.tabs, S.p, S.pn)
            for _, e in ipairs(ok and list or {}) do if e.key == "journal" then T.wheel = e end end
        end
        if not (T.wheel and T.wheel.run) then Q.skip(T.L .. " (pad): the D-pad Character wheel's Tabs slice", "no Journal slice found (ZeD.DpadWheels.C.tabs)"); return end
        Q.check(T.wheel.off == nil, T.L .. " (pad): the wheel's Tabs slice offers Journal (not greyed)", tostring(T.wheel.off))
        H.zcall(function() T.wheel.run(S.p, S.pn) end)
    end)
    H.wait(3000, function() local w = RT.cw(); return T.wheel == nil or (w ~= nil and w._activeTab == "journal") end, function(ok)
        if not T.wheel then return end
        local w = RT.cw()
        Q.check(ok, T.L .. " (pad): the wheel's Journal slice opens the Journal tab", "tab " .. tostring(w and w._activeTab))
        RT.charTab("loot")
    end)
    -- the strip's tab by the pad's A
    H.step(10, function()
        T.stripGo = false
        if not H.padOn() then Q.skip(T.L .. " (pad): the strip's tab by A", "ZeD's input mode cannot be locked to the controller"); return end
        local w = RT.cw()
        local e = nil
        pcall(function() e = S.F.focusWhere(w, "charTabBar", function(el) return el.tabId == "journal" end) end)
        T.stripGo = e ~= nil
        if not Q.check(T.stripGo, T.L .. " (pad): the pad's focus lands on the strip's Journal tab", "focus " .. tostring(H.focId())) then return end
    end)
    H.tapA(function() return T.stripGo end)
    H.step(10, function()
        if not T.stripGo then return end
        local w = RT.cw()
        Q.check(w ~= nil and w._activeTab == "journal", T.L .. " (pad): A on the strip's Journal tab opens it", "tab " .. tostring(w and w._activeTab))
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J2 a page change clears the searches
function C.j2()
    local T = { L = "J2 a page change clears the searches" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        for i = 1, 3 do H.entAdd({ text = "ZQA search clears " .. i .. " zqsc" }) end
        T.fly = H.paper("Base.Flier", "ustoreitmuldraugh")
        T.nb = H.book("Base.Notebook", "ZQA clears")
    end)
    H.frontQ(T, 1)
    H.step(2, function()
        if T.off then return end
        local w = RT.cw()
        pcall(function() w._journalSearch.input:setText("zqsc") end)
    end)
    H.wait(2000, function() local w = RT.cw(); return T.off or (w._journalSearchText == "zqsc") end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": typed in the Log's search box, the log filters by it", "search " .. tostring(RT.cw()._journalSearchText))
        T.went = H.pageClick(2)
    end)
    H.step(5, function() if not T.off then H.pageClick(1) end end)
    H.step(5, function()
        if T.off then return end
        local w = RT.cw()
        local box = nil
        pcall(function() box = w._journalSearch.input:getText() end)
        Q.check(T.went and w._journalSubTab == 1 and (w._journalSearchText or "") == "" and (box or "") == "", T.L .. " (mouse): Notebooks and back clears the Log's search and its box",
            "search " .. tostring(w._journalSearchText) .. ", box " .. tostring(box) .. ", page " .. tostring(w._journalSubTab))
        H.pageClick(2)
    end)
    H.step(5, function()
        if T.off then return end
        local w = RT.cw()
        pcall(function() w._flyerSearch.input:setText("zqfly") end)
    end)
    H.wait(2000, function() local w = RT.cw(); return T.off or w._flyerSearchText == "zqfly" end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": typed in the Notebooks search box, the page holds it", tostring(RT.cw()._flyerSearchText))
        H.pageClick(3)
    end)
    H.step(5, function()
        if T.off then return end
        local w = RT.cw()
        local box = nil
        pcall(function() box = w._flyerSearch.input:getText() end)
        Q.check((w._flyerSearchText or "") == "" and (box or "") == "", T.L .. ": Notebooks to Papers clears the shared search", "search " .. tostring(w._flyerSearchText) .. ", box " .. tostring(box))
    end)
    -- a paper's quick look open, the Log, then Papers: still open
    H.wait(3000, function() return T.off or H.jrZone("paper:ustoreitmuldraugh") ~= nil end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the flyer has its row on Papers", H.list(H.jrIds("paper:"))) then return end
        H.jrPress("paper:ustoreitmuldraugh", T.L)
    end)
    H.step(5, function() if not T.off then T.open1 = H.st().paperOpen; H.pageClick(1) end end)
    H.step(5, function() if not T.off then H.pageClick(3) end end)
    H.step(5, function()
        if T.off then return end
        local s = H.st()
        Q.check(T.open1 == "ustoreitmuldraugh" and s.paperOpen == "ustoreitmuldraugh", T.L .. ": a paper's quick look stays open across a visit to the Log (as the map says)",
            "open before " .. tostring(T.open1) .. ", after " .. tostring(s.paperOpen))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J4 an add-on's page
function C.j4()
    local T = { L = "J4 an add-on's page" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        for _, def in ipairs(S.JT._pages.list or {}) do
            local vis = true
            if def.visible then pcall(function() vis = def.visible() and true or false end) end
            if vis and not T.def then T.def = def end
        end
        if not T.def then T.off = true; Q.skip(T.L, "no add-on page is registered and shown (ZeD-GUI: Loadouts off or not installed)"); return end
        T.idx = S.JT.pageIndex(T.def.id)
    end)
    H.frontQ(T, 1)
    H.step(2, function() if not T.off then T.n0 = #(RT.cw()._journalTabZones or {}); H.pageClick(T.idx) end end)
    H.step(8, function()
        if T.off then return end
        local w = RT.cw()
        Q.check(w._journalSubTab == T.idx, T.L .. ": its tab opens its page (" .. tostring(T.def.id) .. ")", "page " .. tostring(w._journalSubTab) .. ", want " .. tostring(T.idx))
        -- switched off with the page open (its own visible() held false for the leg)
        S.back.addon = { def = T.def, visible = T.def.visible }
        T.def.visible = function() return false end
    end)
    H.step(10, function()
        if T.off then return end
        local w = RT.cw()
        Q.check(w._journalSubTab == 1 and #(w._journalTabZones or {}) == T.n0 - 1, T.L .. ": switched off, the strip drops its tab and the page falls back to the Log",
            "page " .. tostring(w._journalSubTab) .. ", " .. #(w._journalTabZones or {}) .. " tabs (were " .. tostring(T.n0) .. ")")
        local r = nil
        pcall(function() r = S.JT.openPage(w, T.def.id) end)
        T.r = r
    end)
    H.step(5, function()
        if T.off then return end
        local w = RT.cw()
        Q.check(T.r == false, T.L .. ": openPage on a page switched off says false (the map: nothing to open)", "openPage gave " .. tostring(T.r) .. ", the page shown " .. tostring(w._journalSubTab))
        if S.back.addon then T.def.visible = S.back.addon.visible; S.back.addon = nil end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J5 an empty log
function C.j5()
    local T = { L = "J5 an empty log" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local md = H.md()
        T.was = md.ZeD_Journal
        md.ZeD_Journal = nil
        RT.cw()._journalCache = nil
    end)
    H.frontQ(T, 1)
    H.step(2, function() if not T.off then H.padOn() end end)
    H.step(12, function()
        if T.off then return end
        local word = H.tr("UI_ZeD_Journal_NoEntries")
        Q.check(H.drewI(word) ~= nil, T.L .. ": with no journal it reads \"" .. word .. "\"", H.drewLike(" ", 4))
        local kinds = { kills = 0, write = 0, pick = 0, save = 0, other = 0 }
        for _, e in ipairs(H.stops()) do
            local id = tostring(e.id)
            if id == "journal:__kills" then kinds.kills = kinds.kills + 1
            elseif id == "journal:__write" then kinds.write = kinds.write + 1
            elseif string.sub(id, 1, 16) == "journal:tagpick:" then kinds.pick = kinds.pick + 1
            elseif id == "journal:__save" then kinds.save = kinds.save + 1
            elseif string.sub(id, 1, 5) ~= "jtab:" and id ~= "journal:__find" then kinds.other = kinds.other + 1 end
        end
        Q.check(kinds.kills == 1 and kinds.write == 1 and kinds.pick == 8 and kinds.save == 1 and kinds.other == 0,
            T.L .. ": the stops are the kills head, the write box, the eight picks and Save (no month, tag or cross)", H.stopIds(20))
        H.padOff()
        H.md().ZeD_Journal = T.was
        RT.cw()._journalCache = nil
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J6 Save
function C.j6()
    local T = { L = "J6 Save" }
    H.step(2, function()
        if not H.caseStart(T) then return end
    end)
    H.frontQ(T, 1)
    H.step(2, function()
        if T.off then return end
        T.n0 = H.entN()
        H.type("ZQA supply run")
        local gt = getGameTime()
        T.g = { month = gt:getMonth(), day = gt:getDay(), year = gt:getYear(), hour = gt:getHour(), min = math.floor((gt:getTimeOfDay() % 1) * 60) }
        T.hrs = S.p:getHoursSurvived()
        local cal = "?"
        pcall(function()
            cal = "getYear " .. gt:getYear() .. ", getMonth " .. gt:getMonth() .. ", getDay " .. gt:getDay() .. "; start " .. gt:getStartYear() .. "-" .. gt:getStartMonth() .. "-" .. gt:getStartDay()
                .. "; world age " .. H.n2(gt:getWorldAgeHours()) .. " h"
        end)
        H.note(T.L .. ": the game's calendar now (0-based month and day): " .. cal)
        T.pressed = H.saveClick()
    end)
    H.step(3, function()
        if T.off then return end
        local e = (H.ents() or {})[1]
        T.e = e
        Q.check(T.pressed and e ~= nil and e.text == "ZQA supply run" and H.entN() == T.n0 + 1, T.L .. " (mouse): Save puts the entry at the top of the log", tostring(e and e.text) .. ", " .. H.entN() .. " entries (were " .. T.n0 .. ")")
        if not e then T.off = true; return end
        local g = T.g
        local day = math.floor((T.hrs or 0) / 24) + 1
        Q.check(e.month == g.month and e.day == g.day and e.year == g.year and math.abs((e.hour or -9) - g.hour) <= 1,
            T.L .. ": the entry's date and hour are the game's clock (getGameTime)", "entry " .. tostring(e.year) .. "-" .. tostring(e.month) .. "-" .. tostring(e.day) .. " " .. tostring(e.hour) .. ":" .. tostring(e.minute)
            .. "; the game " .. g.year .. "-" .. g.month .. "-" .. g.day .. " " .. g.hour .. ":" .. g.min)
        Q.check(e.minute ~= nil and math.abs(e.minute - g.min) <= 2 or (e.minute ~= nil and math.abs(e.minute - g.min) >= 58), T.L .. ": the entry's minute is the game's (getTimeOfDay)", tostring(e.minute) .. " against " .. g.min)
        Q.check(e.survivalDay == day, T.L .. ": the entry's survival day is floor(getHoursSurvived / 24) + 1", tostring(e.survivalDay) .. " against " .. day .. " (" .. H.n2(T.hrs) .. " hours)")
        local w = RT.cw()
        Q.check((H.boxText() or "") == "" and S.JT.pickedTags(w) == nil, T.L .. ": Save clears the box and the picks", "box \"" .. tostring(H.boxText()) .. "\"")
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local wr, g = H.wrapOf(T.e)
        local e = T.e
        local dayW = H.tr("UI_ZeD_Tk_Day", e.survivalDay)
        local clock = string.format("%02d:%02d", e.hour or 0, e.minute or 0)
        local stamp = wr and wr.stamp or ""
        local drawn = H.drewI(dayW) ~= nil or H.drewCut(stamp) ~= nil
        Q.check(wr ~= nil and H.has(stamp, dayW) and H.has(stamp, clock) and drawn, T.L .. ": the stamp reads \"" .. dayW .. "\", the short date and the clock, and is drawn",
            "stamp \"" .. tostring(stamp) .. "\"")
        local month = H.gt("Sandbox_StartMonth_option" .. ((e.month or 0) + 1))
        local label = g and g.label or ""
        Q.check(H.has(label, month) and H.has(label, tostring(e.year)) and H.drewI(label) ~= nil, T.L .. ": the month head is the game's month name and the year, drawn", "head \"" .. tostring(label) .. "\", the game's month \"" .. month .. "\"")
        -- the pad: A on Save
        H.type("ZQA pad save")
        T.n1 = H.entN()
        T.pad = H.padOn()
        T.go = T.pad and H.focusId("journal:__save")
        if T.pad then Q.check(T.go, T.L .. " (pad): the focus lands on Save", "focus " .. tostring(H.focId()) .. "; stops " .. H.stopIds()) end
    end)
    H.tapA(function() return T.go end)
    H.step(4, function()
        if T.off or not T.go then return end
        local e = (H.ents() or {})[1]
        Q.check(e ~= nil and e.text == "ZQA pad save" and H.entN() == T.n1 + 1, T.L .. " (pad): A on Save saves the entry", tostring(e and e.text))
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J7 tags
-- a drawn word inside a zone's rectangle
function H.drewIn(z, word)
    if not z then return false end
    for _, t in ipairs(S.texts or {}) do
        if t.s == word and t.y >= z.y - 2 and t.y <= z.y + z.h and t.x >= z.x - 2 and t.x <= z.x + z.w + 2 then return true end
    end
    return false
end
function C.j7()
    local T = { L = "J7 tags" }
    H.step(2, function() if not H.caseStart(T) then return end end)
    H.frontQ(T, 1)
    H.step(2, function()
        if T.off then return end
        T.pi = H.press(H.pickZone("injury"))
    end)
    H.step(3, function() if not T.off then T.pd = H.press(H.pickZone("danger")) end end)
    H.step(3, function()
        if T.off then return end
        local w = RT.cw()
        Q.check(T.pi and T.pd and S.JT.isPicked(w, "injury") and S.JT.isPicked(w, "danger"), T.L .. " (mouse): a press on a pick ticks it (Injury, then Danger)", H.list(S.JT.pickedTags(w)))
        H.type("ZQA tagged zqtags")
        H.saveClick()
    end)
    H.step(3, function()
        if T.off then return end
        local e = (H.ents() or {})[1]
        T.e = e
        local tags = e and e.tags or {}
        Q.check(e ~= nil and #tags == 2 and tags[1] == "danger" and tags[2] == "injury", T.L .. ": the entry keeps its tags in TAGS order, not the order ticked", H.list(tags))
        -- four tags: the squares alone; a tag this version does not know: left out
        T.e4 = H.entAdd({ text = "ZQA four tags zqtags", tags = { "danger", "loot", "news", "food" } }, 2)
        T.eu = H.entAdd({ text = "ZQA unknown tag zqtags", tags = { "zqa_future", "food" } }, 3)
        pcall(S.JT.setSearch, RT.cw(), "zqtags")
    end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off then return end
        local i1, i4, iu = H.idxOf(T.e), H.idxOf(T.e4), H.idxOf(T.eu)
        local wD, wI = H.tr("UI_ZeD_Journal_Tag_Danger"), H.tr("UI_ZeD_Journal_Tag_Injury")
        local zD, zI = H.tagZone(i1, "danger"), H.tagZone(i1, "injury")
        Q.check(zD ~= nil and zI ~= nil and H.drewIn(zD, wD) and H.drewIn(zI, wI), T.L .. ": the entry's head shows both tags with their words", "zones " .. tostring(zD ~= nil) .. "/" .. tostring(zI ~= nil))
        local z4 = H.tagZone(i4, "news")
        local wr4 = H.wrapOf(T.e4)
        Q.check(z4 ~= nil and wr4 ~= nil and wr4.tagLay ~= nil and wr4.tagLay.words == false and not H.drewIn(z4, H.tr("UI_ZeD_Journal_Tag_News")),
            T.L .. ": four tags draw as squares alone", "layout words " .. tostring(wr4 and wr4.tagLay and wr4.tagLay.words))
        Q.check(H.tagZone(iu, "zqa_future") == nil and H.tagZone(iu, "food") ~= nil, T.L .. ": a tag key this version does not know is not drawn; the known one is",
            "unknown " .. tostring(H.tagZone(iu, "zqa_future") ~= nil) .. ", food " .. tostring(H.tagZone(iu, "food") ~= nil))
        -- pad: A on a pick
        T.go = H.padOn() and H.focusId("journal:tagpick:food")
    end)
    H.tapA(function() return T.go end)
    H.step(3, function()
        if T.off or not T.go then return end
        Q.check(S.JT.isPicked(RT.cw(), "food"), T.L .. " (pad): A on the Food pick ticks it", H.list(S.JT.pickedTags(RT.cw())))
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J8 text edges, B6, B7
function C.j8()
    local T = { L = "J8 text edges" }
    H.step(2, function() if not H.caseStart(T) then return end end)
    H.frontQ(T, 1)
    H.step(2, function()
        if T.off then return end
        T.n0 = H.entN()
        H.type("")
        H.saveClick()
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.entN() == T.n0, T.L .. ": Save with nothing written saves nothing", H.entN() .. " entries (were " .. T.n0 .. ")")
        H.type("    ")
        H.saveClick()
    end)
    H.step(3, function()
        if T.off then return end
        local e = (H.ents() or {})[1]
        local made = H.entN() == T.n0 + 1
        Q.check(not made, T.L .. " (B6): Save with spaces only saves nothing (an entry of blanks is nothing kept)",
            made and ("an entry of " .. #(e and e.text or "") .. " blanks was made") or "nothing saved")
        H.jClean()
        T.n0 = H.entN()
        T.nl = "ZQA one" .. S.NL .. S.NL .. "two zqedge"
        H.type(T.nl)
        H.saveClick()
    end)
    H.step(3, function()
        if T.off then return end
        local e = (H.ents() or {})[1]
        Q.check(e ~= nil and e.text == T.nl, T.L .. ": two newlines inside are kept in the entry (log only)", "lines " .. H.lineCount(e and e.text) .. ", want 3")
        H.type(H.rep("a", 600))
    end)
    H.step(2, function()
        if T.off then return end
        local t = H.boxText() or ""
        T.long = #t
        H.note(T.L .. ": 600 letters set into the box read back " .. #t .. " letters (the box is ZeD_TextEntry: 3 lines, 500 letters)")
        H.saveClick()
    end)
    H.step(3, function()
        if T.off then return end
        local e = (H.ents() or {})[1]
        local n = e and #(e.text or "") or 0
        if T.long > 500 then
            Q.skip(T.L .. ": the entry holds at most the box's 500 letters", "a text set by code is not held to the box's limit (" .. T.long .. " letters): only typing is; " .. n .. " saved")
        else
            Q.check(n <= 500, T.L .. ": the entry holds at most the box's 500 letters", n .. " letters")
        end
        H.jClean()
        -- B7: the stripe on a long entry (the second in its group: the stripe's turn)
        T.short = H.entAdd({ text = "ZQA stripe short zqstripe", year = 1977, month = 5 }, 1)
        T.longE = H.entAdd({ text = "ZQA stripe long zqstripe " .. H.rep("words that wrap across the drawer ", 12), year = 1977, month = 5 }, 2)
        pcall(S.JT.setSearch, RT.cw(), "zqstripe")
    end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off then return end
        local Tk = ZeD.T
        local dz = H.delZone(H.idxOf(T.longE))
        local r = nil
        for _, rr in ipairs(S.rects or {}) do
            if dz and rr.y <= dz.y + 1 and rr.y + Tk.px(30) >= dz.y and (r == nil or math.abs(rr.y - dz.y) < math.abs(r.y - dz.y)) then r = rr end
        end
        if not (dz and r) then Q.check(false, T.L .. " (B7): the long entry has a stripe drawn", "cross " .. tostring(dz ~= nil) .. ", stripes " .. #(S.rects or {})); return end
        local headH = math.max(ZeD.TM:getFontHeight(Tk.fontF1), Tk.buttonH - Tk.px(4))
        local bodyH = ZeD.TM:getFontHeight(Tk.fontF2)
        local n = 0
        pcall(function() n = #ZeD.Atoms.wrapText(T.longE.text, Tk.fontF2, r.w) end)
        local want = headH + Tk.sp.rowGap + n * (bodyH + Tk.px(2)) + Tk.sp.xs
        Q.check(r.h >= want - 1, T.L .. " (B7): the stripe covers the whole striped entry (its head and all " .. n .. " lines)",
            "stripe " .. math.floor(r.h) .. " px tall, the entry " .. math.floor(want) .. " px")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J9 month groups
function C.j9()
    local T = { L = "J9 month groups" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        -- out of order across two years (text marks them); month keys are 0-based as the game's getMonth
        H.entAdd({ text = "ZQA grp a zqgrp", year = 1980, month = 3 })
        H.entAdd({ text = "ZQA grp b zqgrp", year = 1981, month = 2 })
        H.entAdd({ text = "ZQA grp c zqgrp", year = 1980, month = 11 })
        H.entAdd({ text = "ZQA grp d zqgrp", year = 1981, month = 0 })
        H.entAdd({ text = "ZQA grp e zqgrp", year = 1981, month = 2 })
    end)
    H.frontQ(T, 1)
    H.step(2, function() if not T.off then pcall(S.JT.setSearch, RT.cw(), "zqgrp") end end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off then return end
        local w = RT.cw()
        local ids = {}
        for _, z in ipairs(w._journalGroupZones or {}) do ids[#ids + 1] = tostring(z.id) end
        local want = { "2_1981", "0_1981", "11_1980", "3_1980" }
        local okO = #ids == 4
        for i = 1, 4 do if ids[i] ~= want[i] then okO = false end end
        Q.check(okO, T.L .. ": the month heads run newest year, then newest month first", "drawn " .. H.list(ids) .. "; want " .. H.list(want))
        -- inside a group: array order (the two of March 1981: e before b, e being newer in the list)
        local yE, yB = nil, nil
        local eE, iE = H.entByText("ZQA grp e zqgrp")
        local eB, iB = H.entByText("ZQA grp b zqgrp")
        local dE, dB = H.delZone(iE), H.delZone(iB)
        Q.check(dE ~= nil and dB ~= nil and iE < iB and dE.y < dB.y, T.L .. ": inside a month the entries keep the list's order", "e at " .. tostring(dE and dE.y) .. " (index " .. tostring(iE) .. "), b at " .. tostring(dB and dB.y) .. " (index " .. tostring(iB) .. ")")
        T.dels0 = #(w._journalDeleteZones or {})
        local gz = H.groupZone("0_1981")
        local v = w._journalView
        T.where = gz and ("head " .. math.floor(gz.x) .. "," .. math.floor(gz.y) .. " " .. math.floor(gz.w) .. "x" .. math.floor(gz.h)
            .. (v and (", view y " .. math.floor(v.y) .. "-" .. math.floor(v.y + v.h)) or "")) or "no head zone"
        T.press = H.press(gz)
        T.c1 = w._journalGroupCollapsed["0_1981"]
        local m = H.gt("Sandbox_StartMonth_option1")
        H.note(T.L .. ": the head words for January 1981 hold the game's \"" .. m .. "\": " .. tostring(H.drewI(m) and H.drewI(m).s))
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local w = RT.cw()
        local dels = #(w._journalDeleteZones or {})
        Q.check(T.press and w._journalGroupCollapsed["0_1981"] == true and dels == T.dels0 - 1 and H.groupZone("0_1981") ~= nil,
            T.L .. " (mouse): a press on a month head folds it: its entry goes, the head stays", "folded " .. tostring(w._journalGroupCollapsed["0_1981"]) .. " (right after the press "
            .. tostring(T.c1) .. ", pressed " .. tostring(T.press) .. "), crosses " .. dels .. " (were " .. tostring(T.dels0) .. "); " .. tostring(T.where))
        -- (the pad's leg starts from the head folded, whatever the mouse did)
        w._journalGroupCollapsed["0_1981"] = true
        T.go = H.padOn() and H.focusId("journal:group:0_1981")
    end)
    H.tapA(function() return T.go end)
    H.step(3, function()
        if T.off or not T.go then return end
        Q.check(not RT.cw()._journalGroupCollapsed["0_1981"], T.L .. " (pad): A on the folded head opens it again", tostring(RT.cw()._journalGroupCollapsed["0_1981"]))
        H.padOff()
        H.note(T.L .. ": folds are kept on the window (win._journalGroupCollapsed), so a game loaded again starts unfolded; not staged here")
    end)
    H.shot("jn_log_" .. H.sizeTag(), "the Log: month heads across two years, one folded and opened again", function() return not T.off end)
    H.caseEnd(T.L)
end

-- ===================================================================== J10 an old entry's day (B10)
-- days from a civil date (Gregorian; y, m 1..12, d 1..31)
function H.civil(y, m, d)
    y = (m <= 2) and (y - 1) or y
    local era = math.floor(y / 400)
    local yoe = y - era * 400
    local mp = (m > 2) and (m - 3) or (m + 9)
    local doy = math.floor((153 * mp + 2) / 5) + d - 1
    local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
    return era * 146097 + doe
end
function H.mlen(y, m0)
    local L = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    local n = L[m0 + 1]
    if m0 == 1 and ((y - math.floor(y / 4) * 4 == 0 and y - math.floor(y / 100) * 100 ~= 0) or y - math.floor(y / 400) * 400 == 0) then n = 29 end
    return n
end
function C.j10()
    local T = { L = "J10 an old entry's day (B10)" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local gt = getGameTime()
        local sy, sm, sd = gt:getStartYear(), gt:getStartMonth(), gt:getStartDay()
        -- 70 days after the start date by the calendar (two or more month ends crossed)
        local y, m, d = sy, sm, sd
        for _ = 1, 70 do
            d = d + 1
            if d >= H.mlen(y, m) then d = 0; m = m + 1; if m > 11 then m = 0; y = y + 1 end end
        end
        T.real = H.civil(y, m + 1, d + 1) - H.civil(sy, sm + 1, sd + 1) + 1
        T.flat = (y * 360 + m * 30 + d) - (sy * 360 + sm * 30 + sd) + 1
        T.date = y .. "-" .. (m + 1) .. "-" .. (d + 1) .. " from the start " .. sy .. "-" .. (sm + 1) .. "-" .. (sd + 1)
        T.e = H.entAdd({ text = "ZQA old entry zqold", year = y, month = m, day = d, noDay = true })
    end)
    H.frontQ(T, 1)
    H.step(2, function() if not T.off then pcall(S.JT.setSearch, RT.cw(), "zqold") end end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local wr = H.wrapOf(T.e)
        local stamp = wr and wr.stamp or ""
        local want = H.tr("UI_ZeD_Tk_Day", T.real)
        Q.check(H.has(stamp, want .. " ") or stamp == want, T.L .. ": an entry with no survivalDay reads its day by the calendar (" .. T.real .. " days)",
            "stamp \"" .. stamp .. "\"; the 30-day count gives " .. T.flat .. "; " .. T.date)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J11 search
function C.j11()
    local T = { L = "J11 search" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.a = H.entAdd({ text = "ZQA found food here zqs" })
        T.b = H.entAdd({ text = "ZQA base wall zqs" })
        T.c = H.entAdd({ text = "ZQA quiet day zqs", tags = { "food" } })
    end)
    H.frontQ(T, 1)
    H.step(2, function() if not T.off then pcall(function() RT.cw()._journalSearch.input:setText("food") end) end end)
    H.wait(2000, function() return T.off or RT.cw()._journalSearchText == "food" end, function() end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local shown = {}
        for _, z in ipairs(RT.cw()._journalDeleteZones or {}) do local e = (H.ents() or {})[z.entryIdx]; if e then shown[e] = true end end
        Q.check(shown[T.a] == true and shown[T.c] == true and not shown[T.b], T.L .. ": \"food\" keeps the entry with the word and the one tagged Food, not the other",
            "found food " .. tostring(shown[T.a] == true) .. ", tagged Food " .. tostring(shown[T.c] == true) .. ", base wall " .. tostring(shown[T.b] == true)
            .. " (the map says all three; base wall holds neither the word nor the tag)")
        pcall(S.JT.setSearch, RT.cw(), "")
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local w = RT.cw()
        pcall(function() w._journalScroll:setScrollPos(0.5) end)
        T.press = H.press(H.tagZone(H.idxOf(T.c), "food"))
    end)
    H.step(3, function()
        if T.off then return end
        local w = RT.cw()
        local word = H.tr("UI_ZeD_Journal_Tag_Food")
        Q.check(T.press and w._journalSearchText == word and (w._journalScroll.scrollPos or 0) == 0, T.L .. " (mouse): a press on an entry's Food tag puts its word in the search, the log at its top",
            "search \"" .. tostring(w._journalSearchText) .. "\", scroll " .. H.n2(w._journalScroll.scrollPos))
        pcall(S.JT.setSearch, w, "")
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        T.go = H.padOn() and H.focusId("journal:tag:" .. tostring(H.idxOf(T.c)) .. ":food")
        if not T.go then Q.check(false, T.L .. " (pad): the entry's Food tag is a stop", "stops " .. H.stopIds()) end
    end)
    H.tapA(function() return T.go end)
    H.step(3, function()
        if T.off or not T.go then return end
        Q.check(RT.cw()._journalSearchText == H.tr("UI_ZeD_Journal_Tag_Food"), T.L .. " (pad): A on the tag puts its word in the search", tostring(RT.cw()._journalSearchText))
        T.goX = H.focusId("journal:__kills")
    end)
    H.tapX(function() return T.go and T.goX end)
    H.step(3, function()
        if T.off or not T.go then return end
        local w = RT.cw()
        Q.check((w._journalSearchText or "") == "", T.L .. " (pad): X on a Log stop clears the search", "search \"" .. tostring(w._journalSearchText) .. "\"")
        local el = H.focEl()
        local pr = el and el.promptX and el.promptX(w)
        Q.check(pr == false, T.L .. " (pad): with no search X offers nothing (its prompt off)", tostring(pr))
        H.padOff()
        Q.skip(T.L .. ": a tag's word searches in another language (DE)", "the run is in " .. H.lang() .. ": a game started in German is needed")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J12 delete, B8, B12
function C.j12()
    local T = { L = "J12 delete" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.c = H.entAdd({ text = "ZQA del three zqthree" })
        T.b = H.entAdd({ text = "ZQA del two zqdel" })
        T.a = H.entAdd({ text = "ZQA del one zqdel" })
    end)
    H.frontQ(T, 1)
    H.step(2, function() if not T.off then pcall(S.JT.setSearch, RT.cw(), "zqthree") end end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        T.press = H.press(H.delZone(H.idxOf(T.c)))
    end)
    H.drawn(T, 2)
    H.step(1, function()
        if T.off then return end
        local w = RT.cw()
        local ask = w._journalAsk
        Q.check(T.press and ask ~= nil and ask.entry == T.c and H.drewI(H.tr("UI_ZeD_Journal_AskDelete")) ~= nil, T.L .. " (mouse): the cross asks first, about that entry", "asking " .. tostring(ask and ask.entry and ask.entry.text))
        local r = w._journalAskRects
        T.pc = r and r.cancel and H.click(H.mid(r.cancel))
    end)
    H.step(3, function()
        if T.off then return end
        local w = RT.cw()
        Q.check(T.pc and w._journalAsk == nil and H.idxOf(T.c) ~= nil, T.L .. " (mouse): Cancel keeps every entry", "asking " .. tostring(w._journalAsk ~= nil) .. ", three " .. tostring(H.idxOf(T.c)))
        H.press(H.delZone(H.idxOf(T.c)))
    end)
    H.drawn(T, 2)
    H.step(1, function()
        if T.off then return end
        T.before = {}
        for i, e in ipairs(H.ents() or {}) do if e ~= T.c then T.before[#T.before + 1] = e end end
        local r = RT.cw()._journalAskRects
        T.pv = r and r.verb and H.click(H.mid(r.verb))
    end)
    H.step(3, function()
        if T.off then return end
        local E = H.ents() or {}
        local same = #E == #T.before
        for i, e in ipairs(T.before) do if E[i] ~= e then same = false end end
        Q.check(T.pv and H.idxOf(T.c) == nil and same, T.L .. " (mouse): Delete takes exactly that entry; the rest keep their order (his among them)", #E .. " entries, want " .. #T.before)
        T.c = H.entAdd({ text = "ZQA del three zqthree" }, 3)
        pcall(S.JT.setSearch, RT.cw(), "")
    end)
    -- B8: with the question up, the mouse on another cross and a month head
    H.drawn(T, 3)
    H.step(1, function() if not T.off then H.press(H.delZone(H.idxOf(T.a))) end end)
    H.drawn(T, 2)
    H.step(1, function()
        if T.off then return end
        T.ask0 = RT.cw()._journalAsk and RT.cw()._journalAsk.entry
        H.press(H.delZone(H.idxOf(T.b)))
    end)
    H.step(3, function()
        if T.off then return end
        local w = RT.cw()
        local now = w._journalAsk and w._journalAsk.entry
        Q.check(T.ask0 == T.a and now == T.a, T.L .. " (B8): with the question up, another entry's cross does not take the question over",
            "asked about " .. tostring(T.ask0 and T.ask0.text) .. ", then " .. tostring(now and now.text))
        local wr, g = H.wrapOf(T.a)
        T.gk = g and g.key
        T.f0 = T.gk and w._journalGroupCollapsed[T.gk] or false
        H.press(H.groupZone(T.gk))
    end)
    H.step(3, function()
        if T.off then return end
        local w = RT.cw()
        local f1 = T.gk and w._journalGroupCollapsed[T.gk] or false
        Q.check(f1 == T.f0, T.L .. " (B8): with the question up, a month head does not fold under it", "folded " .. tostring(T.f0) .. " -> " .. tostring(f1))
        if T.gk then w._journalGroupCollapsed[T.gk] = nil end
        pcall(S.JT.cancelDelete, w)
    end)
    -- B12: the question after another Character tab
    H.drawn(T, 2)
    H.step(1, function() if not T.off then H.press(H.delZone(H.idxOf(T.a))) end end)
    H.step(3, function() if not T.off then T.asked = RT.cw()._journalAsk ~= nil; RT.charTab("skills") end end)
    H.step(10, function() if not T.off then RT.charTab("journal") end end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local w = RT.cw()
        Q.check(T.asked and w._journalAsk == nil, T.L .. " (B12): the question does not outlive a visit to another tab", "asked " .. tostring(T.asked) .. ", still asking " .. tostring(w._journalAsk ~= nil)
            .. (w._journalAsk and (" about " .. tostring(w._journalAsk.entry and w._journalAsk.entry.text)) or ""))
        pcall(S.JT.cancelDelete, w)
    end)
    -- the pad: A on a cross asks with the focus on Cancel; A on Cancel back on that cross; Delete lands on the next
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        T.ib = H.idxOf(T.b)
        T.go = H.padOn() and H.focusId("journal:del:" .. tostring(T.ib))
        if not T.go then Q.check(false, T.L .. " (pad): the second entry's cross is a stop", "stops " .. H.stopIds()) end
    end)
    H.tapA(function() return T.go end)
    H.step(6, function()
        if T.off or not T.go then return end
        local w = RT.cw()
        Q.check(w._journalAsk ~= nil and w._journalAsk.entry == T.b and H.focId() == "journal:ask:cancel", T.L .. " (pad): A on the cross asks, the focus on Cancel", "focus " .. tostring(H.focId()))
    end)
    H.tapA(function() return T.go end)
    H.step(8, function()
        if T.off or not T.go then return end
        Q.check(RT.cw()._journalAsk == nil and H.focId() == "journal:del:" .. tostring(H.idxOf(T.b)), T.L .. " (pad): A on Cancel keeps it, the focus back on its cross", "focus " .. tostring(H.focId()))
        H.focusId("journal:del:" .. tostring(H.idxOf(T.b)))
    end)
    H.tapA(function() return T.go end)
    H.step(6, function() if not T.off and T.go then T.goV = H.focusId("journal:ask:verb") end end)
    H.tapA(function() return T.go and T.goV end)
    H.step(10, function()
        if T.off or not (T.go and T.goV) then return end
        local want = "journal:del:" .. tostring(H.idxOf(T.c))
        Q.check(H.idxOf(T.b) == nil and H.focId() == want, T.L .. " (pad): Delete takes it, the focus on the next entry's cross", "focus " .. tostring(H.focId()) .. ", want " .. want)
        T.goB = H.focusId(want)
    end)
    H.tapA(function() return T.goB end)
    H.tapB(function() return T.goB end)
    H.step(6, function()
        if T.off or not T.goB then return end
        Q.check(RT.cw()._journalAsk == nil and H.idxOf(T.c) ~= nil, T.L .. " (pad): B on the question cancels it", "asking " .. tostring(RT.cw()._journalAsk ~= nil))
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J13 kills by kind, B9
S.KILLS = {
    { list = { "Base.Axe" }, row = "Axe", cat = "AXE", n = 2 },
    { list = { "Base.SpearCrafted", "Base.SpearShort", "Base.Spear" }, row = "Spear", cat = "SPEAR", n = 1 },
    { list = { "Base.BaseballBat" }, row = "Blunt", cat = "BLUNT", n = 1 },
    { list = { "Base.Pistol" }, row = "Firearm", n = 1 },
    { list = { "Base.BareHands" }, row = "Unarmed", n = 1 },
    { list = { "Base.PipeBomb" }, row = "explosion", n = 2 },
}
function C.j13kill(T, K)
    H.step(5, function()
        T.cur = nil
        if T.off then return end
        local ft = H.firstKnown(K.list)
        if not ft then T.noType[#T.noType + 1] = K.row; return end
        local wpn = nil
        pcall(function() wpn = instanceItem(ft) end)
        local z = H.spawnZ()
        T.cur = { K = K, ft = ft, w = wpn, z = z }
    end)
    H.step(20, function()
        local c = T.cur
        if T.off or not (c and c.w and c.z) then return end
        for _ = 1, 30 do
            if H.zDead(c.z) then break end
            pcall(function() c.z:Hit(c.w, S.p, 3.0, false, 1.0) end)
        end
        c.dead = H.zDead(c.z)
    end)
    H.step(30, function()
        local c = T.cur
        if T.off or not c then return end
        if c.dead then
            T.dead[K.row] = (T.dead[K.row] or 0) + 1
            T.made = T.made + 1
        else
            T.alive[#T.alive + 1] = c.ft
        end
        if K.cat and c.w and not T.catSaid[K.row] then
            T.catSaid[K.row] = true
            local has = nil
            pcall(function() has = c.w:getScriptItem():containsWeaponCategory(WeaponCategory[K.cat]) and true or false end)
            T.cats[#T.cats + 1] = c.ft .. " " .. K.cat .. " " .. tostring(has)
        end
    end)
end
function C.j13()
    local T = { L = "J13 kills by kind", dead = {}, made = 0, alive = {}, noType = {}, cats = {}, catSaid = {} }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.k0 = H.kills()
        local kd = nil
        pcall(function() kd = S.KT.data(S.p) end)
        T.r0 = H.copy(kd or {})
        T.r0.weapon = T.r0.weapon or {}
    end)
    for _, K in ipairs(S.KILLS) do for _ = 1, K.n do C.j13kill(T, K) end end
    H.step(10, function()
        if T.off then return end
        local kd = H.md().ZeD_Kills or {}
        local k1 = H.kills()
        H.note(T.L .. ": the game's own categories: " .. H.list(T.cats) .. (#T.noType > 0 and ("; no such item here: " .. H.list(T.noType)) or "")
            .. (#T.alive > 0 and ("; not killed in 30 hits: " .. H.list(T.alive)) or ""))
        Q.check((k1 or 0) - (T.k0 or 0) == T.made, T.L .. ": the game's own count rose by the kills made", tostring(T.k0) .. " -> " .. tostring(k1) .. ", " .. T.made .. " zombies killed")
        local bad = {}
        for _, K in ipairs(S.KILLS) do
            local want = T.dead[K.row] or 0
            local got
            if K.row == "explosion" then got = (tonumber(kd.explosion) or 0) - (tonumber(T.r0.explosion) or 0)
            else got = ((kd.weapon or {})[K.row] or 0) - (T.r0.weapon[K.row] or 0) end
            if got ~= want then bad[#bad + 1] = K.row .. " +" .. got .. " (killed " .. want .. ")" end
        end
        local fire = (tonumber(kd.fire) or 0) - (tonumber(T.r0.fire) or 0)
        local veh = (tonumber(kd.vehicle) or 0) - (tonumber(T.r0.vehicle) or 0)
        if fire ~= 0 then bad[#bad + 1] = "fire +" .. fire end
        if veh ~= 0 then bad[#bad + 1] = "vehicle +" .. veh end
        Q.check(#bad == 0 and T.made > 0, T.L .. ": each kill lands in its own row (axe, spear, bat, pistol, bare hands, pipe bomb)", #bad == 0 and (T.made .. " kills, each in its row") or H.list(bad))
        Q.skip(T.L .. ": a fire kill (a Molotov or a campfire)", "a burn spreads and takes 20 s to confirm: not staged in the sweep")
        Q.skip(T.L .. ": a kill by car", "a car must be driven into the zombie")
        local w = RT.cw()
        if w then w._journalCache = nil end
    end)
    H.frontQ(T, 1)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local w = RT.cw()
        local data = w._journalCache or {}
        local kd = H.md().ZeD_Kills or {}
        local truth = (H.kills() or 0) + (tonumber(kd.fire) or 0)
        local sum = (data.fireKills or 0) + (data.carKills or 0) + (data.explosionKills or 0)
        for _, c in ipairs(data.weaponCats or {}) do sum = sum + (c.count or 0) end
        Q.check(data.totalKills == truth and H.drewI(getText("IGUI_char_Zombies_Killed")) ~= nil and H.drewI(tostring(truth)) ~= nil,
            T.L .. ": the head \"Zombies Killed\" shows getZombieKills plus the fire kills", tostring(data.totalKills) .. " against " .. truth)
        Q.check(sum == truth, T.L .. ": the rows add up to the head", sum .. " against " .. truth)
        T.kz = w._journalKillsZone
        T.fold0 = w._killsExpanded
        T.press = H.press(T.kz)
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local w = RT.cw()
        local miss = {}
        for _, k in ipairs({ "IGUI_perks_Axe", "IGUI_perks_Spear", "IGUI_perks_Blunt", "IGUI_perks_Firearm" }) do if not H.drewI(H.gt(k)) then miss[#miss + 1] = H.gt(k) end end
        for _, k in ipairs({ "UI_ZeD_Journal_KillFire", "UI_ZeD_Journal_KillVehicle", "UI_ZeD_Journal_KillExplosion", "UI_ZeD_Journal_WeaponUnarmed" }) do if not H.drewI(H.tr(k)) then miss[#miss + 1] = H.tr(k) end end
        Q.check(T.press and w._killsExpanded == not T.fold0 and #miss == 0, T.L .. " (mouse): a press on the head opens the rows: fire, vehicle, explosion and the weapon rows by the game's skill names",
            "open " .. tostring(w._killsExpanded) .. "; not drawn: " .. H.list(miss))
        T.go = H.padOn() and H.focusId("journal:__kills")
    end)
    H.tapA(function() return T.go end)
    H.step(4, function()
        if T.off or not T.go then return end
        local w = RT.cw()
        Q.check(w._killsExpanded == T.fold0, T.L .. " (pad): A on the head folds it again", tostring(w._killsExpanded))
        H.padOff()
        -- B9: a press beside the head at its height (outside its width)
        local z = w._journalKillsZone
        local d = H.drawer()
        local dw = 0
        pcall(function() dw = d:getWidth() end)
        T.bx = nil
        if z then
            if z.x + z.w + 3 < dw - 1 then T.bx = z.x + z.w + 3 elseif z.x > 3 then T.bx = z.x - 3 end
        end
        if not T.bx then Q.skip(T.L .. " (B9): a press beside the kills head", "no room beside the head in the drawer"); return end
        T.f1 = w._killsExpanded
        H.click(T.bx, z.y + math.floor(z.h / 2))
    end)
    H.step(3, function()
        if T.off or not T.bx then return end
        local w = RT.cw()
        Q.check(w._killsExpanded == T.f1, T.L .. " (B9): a press beside the kills head, outside its width, does not fold it", "x " .. T.bx .. " (head " .. math.floor(w._journalKillsZone.x) .. "+" .. math.floor(w._journalKillsZone.w)
            .. "), folded " .. tostring(T.f1) .. " -> " .. tostring(w._killsExpanded))
        w._killsExpanded = false
        Q.skip(T.L .. ": the game's Info page count in safe mode (lower by the fire kills)", "no fire kill staged; safe mode is J3's")
        H.note(T.L .. ": Identity's total is the same ZeD.KillTracker.total (the Identity map's)")
    end)
    H.step(2, function()
        H.killsBack()
        H.sweepZombies()
        H.sweepBodies()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J14 an old kill table
function C.j14()
    local T = { L = "J14 an old kill table" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.md().ZeD_Kills = { weapon = { Axe = 50, Blunt = 40 }, fire = 2, vehicle = 1, explosion = 30 }
        pcall(function() S.p:setZombieKills(12) end)
        RT.cw()._journalCache = nil
    end)
    H.frontQ(T, 1)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local w = RT.cw()
        local data = w._journalCache or {}
        local kd = H.md().ZeD_Kills or {}
        local sum = (data.fireKills or 0) + (data.carKills or 0) + (data.explosionKills or 0)
        local other = 0
        for _, c in ipairs(data.weaponCats or {}) do
            sum = sum + (c.count or 0)
            if c.label == H.tr("UI_ZeD_Journal_WeaponOther") then other = c.count end
        end
        Q.check(data.totalKills == 14 and sum == 14, T.L .. ": an old table's rows add up to the head (the game's 12 plus 2 fire)", "head " .. tostring(data.totalKills) .. ", rows " .. sum)
        Q.check(other == 11 and data.fireKills == 2 and data.carKills == 1 and (data.explosionKills or 0) == 0 and kd.v == 2,
            T.L .. ": the old weapon and explosion rows rebuilt into Other from the game's count, fire and vehicle kept",
            "Other " .. tostring(other) .. ", fire " .. tostring(data.fireKills) .. ", vehicle " .. tostring(data.carKills) .. ", explosion " .. tostring(data.explosionKills) .. ", v " .. tostring(kd.v))
        H.killsBack()
        w._journalCache = nil
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J15 no time survived on the Log
function C.j15()
    local T = { L = "J15 no time survived on the Log" }
    H.step(2, function() if not H.caseStart(T) then return end end)
    H.frontQ(T, 1)
    H.step(2, function()
        if T.off then return end
        local w = RT.cw()
        w._killsExpanded = true
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local surv = ""
        pcall(function() surv = tostring(S.p:getTimeSurvived()) end)
        Q.check(H.drewI(H.gt("IGUI_char_Survived_For")) == nil and (surv == "" or H.drewI(surv) == nil), T.L .. ": nothing on the Log says how long he has survived (a gap the map records)",
            "the game's getTimeSurvived \"" .. surv .. "\"")
        H.note(T.L .. ": the game's Survived For reads \"" .. surv .. "\" (Identity shows it: the Identity map's)")
        RT.cw()._killsExpanded = false
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J48 the death record (as built at death)
function C.j48()
    local T = { L = "J48 the death record" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not (ZeD.Death and ZeD.Death.capture) then T.off = true; Q.skip(T.L, "ZeD.Death.capture is not loaded"); return end
        H.entAdd({ text = "ZQA first words zq48" })
        H.entAdd({ text = "ZQA second words zq48" })
        T.last = H.entAdd({ text = "ZQA last words zq48" })
        H.md().ZeD_Kills = { v = 2, weapon = { Axe = 3, Blunt = 2 }, fire = 1, vehicle = 1, explosion = 0 }
        pcall(function() S.p:setZombieKills(6) end)
        H.zcall(function() ZeD.Death.capture(S.p) end)
    end)
    H.step(3, function()
        if T.off then return end
        local rec = ZeD.Death.records and ZeD.Death.records[S.pn]
        local kills = rec and rec.kills or ""
        local axe = H.gt("IGUI_perks_Axe") .. " 3"
        local fire = H.tr("UI_ZeD_Death_KillFire") .. " 1"
        Q.check(rec ~= nil and rec.last == T.last.text, T.L .. ": the record keeps the newest entry's words (no death: ZeD.Death.capture as the death hook calls it)", tostring(rec and rec.last))
        Q.check(H.has(kills, axe) and H.has(kills, fire) and string.find(kills, axe, 1, true) < (string.find(kills, fire, 1, true) or 0),
            T.L .. ": the kills line lists each kind with its count, most first", "\"" .. kills .. "\"")
        H.note(T.L .. ": the Log lives in the character's modData: it goes with the character (dying is not staged)")
        H.killsBack()
        if ZeD.Death.records then ZeD.Death.records[S.pn] = S.found.death end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== Into (J16-J22)
-- the readers' own scan asked again (it runs every 30 asks; J34 checks the timing)
function H.rescan() local w = RT.cw(); if w then pcall(S.JR.refresh, w) end end
function H.intoId() local s = H.st(); return s and s.logInto or nil end
-- queue: Into pressed (one press every 3 frames) until it holds the book T[key] (nil key: the log only)
function H.intoQ(T, key)
    local st = {}
    H.step(1, function() st.n, st.k = 0, 0 end)
    H.wait(6000, function()
        if T.off then return true end
        local b = key and T[key] or nil
        local want = b and H.id(b) or nil
        if H.intoId() == want then return true end
        st.k = st.k + 1
        if st.k >= 3 then st.k = 0; st.n = st.n + 1; H.jrPress("into", T.L) end
        return st.n > 14
    end, function(ok)
        if T.off then return end
        if not ok then Q.check(false, T.L .. ": Into steps to the book wanted", "Into holds " .. tostring(H.intoId()) .. " after " .. st.n .. " presses") ; T.off = true end
    end)
end
-- queue: the write ends (no ZeD_WriteNoteAction left in the game's queue)
function H.writeWait(T, ms)
    H.step(2, function() end)
    H.wait(ms or 20000, function() return T.off or H.qcount("ZeD_WriteNoteAction") == 0 end, function(ok)
        if T.off then return end
        if not ok then H.note(T.L .. ": the write did not end in time (" .. H.qkinds() .. "): cleared"); H.qstop() end
    end)
end
function H.writingDrawn() local w = H.tr("UI_ZeD_Notebook_Writing"); return H.drewI(w) ~= nil or H.drewCut(w) ~= nil end

function C.j16()
    local T = { L = "J16 Into's cycle" }
    H.step(2, function() if not H.caseStart(T) then return end end)
    H.frontQ(T, 1)
    H.step(1, function()
        if T.off then return end
        Q.check(H.jrZone("into") == nil and not S.JR.intoShown(RT.cw()), T.L .. ": with no writable book carried there is no Into", H.list(H.jrIds()))
        T.nb = H.book("Base.Notebook", "ZQA into notebook")
        H.rescan()
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local label = H.tr("UI_ZeD_Notebook_Into", H.tr("UI_ZeD_Notebook_LogOnly"))
        Q.check(H.jrZone("into") ~= nil and H.intoId() == nil and (H.drewI(label) ~= nil or H.drewCut(label) ~= nil), T.L .. ": a notebook carried: Into shows \"" .. label .. "\"", H.drewLike(":", 4))
        T.d = H.book(H.firstKnown({ "Base.Diary1", "Base.Journal" }) or "Base.Notebook", "ZQA into diary")
        H.rescan()
    end)
    H.drawn(T, 3)
    H.step(1, function() T.seq, T.k = {}, 0 end)
    H.wait(4000, function()
        if T.off then return true end
        T.k = T.k + 1
        if T.k >= 3 then
            T.k = 0
            H.jrPress("into", T.L)
            T.seq[#T.seq + 1] = H.intoId() or "log"
        end
        return #T.seq >= 3
    end, function()
        if T.off then return end
        local books = (H.st().carried or {}).books or {}
        local want = { books[1] and H.id(books[1]) or "?", books[2] and H.id(books[2]) or "?", "log" }
        local ok = #T.seq == 3
        for i = 1, 3 do if tostring(T.seq[i]) ~= tostring(want[i]) then ok = false end end
        Q.check(ok, T.L .. " (mouse): presses step to the first book, the second, then back to the log only", "got " .. H.list(T.seq) .. ", want " .. H.list(want))
        T.go = H.padOn() and H.focusId("jr:into")
        T.want1 = want[1]
    end)
    H.tapA(function() return T.go end)
    H.step(4, function()
        if T.off or not T.go then return end
        Q.check(tostring(H.intoId()) == tostring(T.want1), T.L .. " (pad): A on Into steps it as a press does", tostring(H.intoId()))
        H.padOff()
        -- the picked book dropped: Into falls back to the log only
        local picked = nil
        for _, b in ipairs({ T.nb, T.d }) do if H.id(b) == H.intoId() then picked = b end end
        H.removeItem(picked)
        H.rescan()
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        Q.check(H.intoId() == nil, T.L .. ": the picked book taken away, Into falls back to the log only", tostring(H.intoId()))
    end)
    H.caseEnd(T.L)
end

function C.j17()
    local T = { L = "J17 Into writes" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA into writes")
        H.setPage(T.nb, 1, H.lines(7, "zq17"))
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 1)
    H.intoQ(T, "nb")
    H.step(2, function()
        if T.off then return end
        H.press(H.pickZone("loot"))
        T.text = "ZQA into run zq17"
        H.type(T.text)
        T.n0 = H.entN()
        T.pressed = H.saveClick()
    end)
    H.step(3, function()
        if T.off then return end
        local a = H.qfirst("ZeD_WriteNoteAction")
        local want = math.min(200, 40 + #T.text)
        Q.check(T.pressed and a ~= nil and a.maxTime == want, T.L .. ": Save with Into on a notebook queues the write (40 ticks and one a letter)", "action " .. tostring(a and a.Type) .. ", " .. tostring(a and a.maxTime) .. " ticks, want " .. want)
        T.writing = H.writingDrawn()
    end)
    H.step(2, function() if not T.off then T.writing = T.writing or H.writingDrawn() end end)
    H.writeWait(T)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        Q.check(T.writing, T.L .. ": \"" .. H.tr("UI_ZeD_Notebook_Writing") .. "\" shows beside Into while it writes", H.drewLike("...", 4))
        local pg = H.page(T.nb, 1)
        local e = (H.ents() or {})[1]
        local nm = H.nm(T.nb)
        Q.check(H.endsWith(pg, T.text) and H.lineCount(pg) == 8, T.L .. ": page 1 ends with the words (the game's seePage)", H.lineCount(pg) .. " lines, last \"" .. tostring(string.sub(pg, -30)) .. "\"")
        Q.check(e ~= nil and e.text == T.text and e.source ~= nil and e.source.name == nm and e.source.page == 1 and H.entN() == T.n0 + 1,
            T.L .. ": then the log keeps the entry with its source (the book's name, page 1)", tostring(e and e.source and e.source.name) .. ", page " .. tostring(e and e.source and e.source.page))
        local tags = e and e.tags or {}
        Q.check(tags[1] == "loot" and not H.has(pg, H.tr("UI_ZeD_Journal_Tag_Loot")), T.L .. ": the tag goes with the log only, not onto the page", H.list(tags))
        local wr = e and H.wrapOf(e)
        local src = H.tr("UI_ZeD_Journal_EntrySource", nm, 1)
        Q.check(wr ~= nil and H.has(wr.stamp, src), T.L .. ": the entry's stamp names the book and the page", "stamp \"" .. tostring(wr and wr.stamp) .. "\"")
        Q.check((H.boxText() or "") == "" and S.JT.pickedTags(RT.cw()) == nil, T.L .. ": the box and the picks clear once it is written", "box \"" .. tostring(H.boxText()) .. "\"")
        -- a full page 1: the words go to page 2
        H.setPage(T.nb, 1, H.lines(15, "zq17"))
        T.text2 = "ZQA page two zq17"
        H.type(T.text2)
        H.saveClick()
    end)
    H.writeWait(T)
    H.step(3, function()
        if T.off then return end
        local e = (H.ents() or {})[1]
        Q.check(H.page(T.nb, 2) == T.text2 and e ~= nil and e.source ~= nil and e.source.page == 2, T.L .. ": with page 1 full the words go to page 2", "page 2 \"" .. H.page(T.nb, 2) .. "\", entry page " .. tostring(e and e.source and e.source.page))
    end)
    H.caseEnd(T.L)
end

-- one refusal: arm() sets it up, want() is the line, undo() takes it away
function C.j18leg(T, name, arm, want, undo)
    H.step(2, function()
        T.legOff, T.ready = nil, nil
        if T.off then return end
        T.n0 = H.entN()
        local why = arm()
        -- (the page read after the leg is armed: a full book's leg fills it; run 1 read it before)
        T.pg0 = H.page(T.nb, 1)
        if why then T.legOff = true; Q.skip(T.L .. ": " .. name, why) end
    end)
    H.wait(5000, function() return T.off or T.legOff or T.ready == nil or T.ready() end, function()
        if T.off or T.legOff or T.ready == nil or T.ready() then return end
        T.legOff = true
        Q.skip(T.L .. ": " .. name, "still light enough to read here at midnight (a lit square)")
        undo()
        T.ready = nil
    end)
    H.step(2, function()
        if T.off or T.legOff then return end
        T.text = "ZQA refused " .. name .. " zq18"
        H.type(T.text)
        H.saveClick()
    end)
    H.step(4, function()
        if T.off or T.legOff then return end
        local s = H.st()
        local w = want()
        Q.check(s.logMsg == w and H.entN() == T.n0 and H.boxText() == T.text and H.qcount("ZeD_WriteNoteAction") == 0 and H.page(T.nb, 1) == T.pg0,
            T.L .. ": " .. name .. ": the reason shows beside Into, no entry, the box keeps the words, nothing queued",
            "line \"" .. tostring(s.logMsg) .. "\" (want \"" .. w .. "\"), entries " .. H.entN() .. " (were " .. T.n0 .. "), queue " .. H.qkinds())
        Q.check(H.drewI(w) ~= nil or H.drewCut(w) ~= nil, T.L .. ": " .. name .. ": the reason is drawn", H.drewLike(" ", 3))
        undo()
        T.ready = nil
        H.type("")
    end)
end
function C.j18()
    local T = { L = "J18 Into's refusals" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA refusals")
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 1)
    H.intoQ(T, "nb")
    C.j18leg(T, "no pencil or pen", function()
        if S.found.toolsKept > 0 then return "a writing tool of his stays worn or held" end
        H.removeItem(T.pen)
        return nil
    end, function() return H.tr("UI_ZeD_Notebook_WhyNoTool") end, function() T.pen = H.give("Base.Pencil") end)
    C.j18leg(T, "too dark", function()
        H.tod(0)
        T.ready = function() return H.dark() end
        return nil
    end, function() return H.tr("UI_ZeD_Notebook_WhyTooDark") end, function() H.tod(S.NOON) end)
    -- (too dark not reached in 5 s, the square lit: the leg is a SKIP)
    C.j18leg(T, "a book locked by you", function()
        pcall(function() T.nb:setLockedBy(H.user()) end)
        return nil
    end, function() return H.tr("UI_ZeD_Notebook_WhyLockedMine") end, function() pcall(function() T.nb:setLockedBy(nil) end) end)
    C.j18leg(T, "a full book", function()
        for i = 1, H.pages(T.nb) do H.setPage(T.nb, i, H.lines(15, "full" .. i)) end
        return nil
    end, function() return H.tr("UI_ZeD_Notebook_NoRoomIn", H.nm(T.nb)) end, function() for i = 1, H.pages(T.nb) do H.setPage(T.nb, i, "") end end)
    H.caseEnd(T.L)
end

-- the write stopped: by the pad's B on a Log stop, then by the game's own stop
function C.j19leg(T, how)
    H.step(2, function()
        if T.off then return end
        T.n0 = H.entN()
        T.pg0 = H.page(T.nb, 1)
        T.text = "ZQA stopped " .. how .. " " .. H.rep("long words to write ", 6)
        H.type(T.text)
        H.saveClick()
        if how == "pad B" then T.go = H.padOn() and H.focusId("journal:__kills") end
    end)
    if how == "pad B" then H.tapB(function() return T.go end) end
    H.step(3, function()
        if T.off then return end
        if how ~= "pad B" then
            local a = H.qfirst("ZeD_WriteNoteAction")
            T.go = a ~= nil
            if a then H.zcall(function() a:forceStop() end) end
        end
    end)
    H.step(10, function()
        if T.off then return end
        H.padOff()
        Q.check(T.go and H.qcount("ZeD_WriteNoteAction") == 0 and H.entN() == T.n0 and H.page(T.nb, 1) == T.pg0 and H.boxText() == T.text,
            T.L .. " (" .. how .. "): the write stops: no entry, the page unchanged, the box keeps the words", "queue " .. H.qkinds() .. ", entries " .. H.entN() .. " (were " .. T.n0 .. ")")
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        Q.check(not H.writingDrawn(), T.L .. " (" .. how .. "): Writing... is gone", H.drewLike("...", 3))
        H.type("")
        H.qstop()
    end)
end
function C.j19()
    local T = { L = "J19 Into interrupted" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA interrupted")
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 1)
    H.intoQ(T, "nb")
    C.j19leg(T, "pad B")
    C.j19leg(T, "the game's own stop")
    H.caseEnd(T.L)
end

-- B1: Save twice while the write runs
function H.count(s, sub) local n, i = 0, 1; while true do local a = string.find(s, sub, i, true); if not a then break end; n = n + 1; i = a + 1 end; return n end
function C.j20leg(T, how)
    H.step(2, function()
        if T.off then return end
        T.n0 = #H.runEnts()
        -- (no space at the end: Into trims the words before it writes them, JR:1114; run 1 counted a text with one)
        T.text = "ZQA twice " .. how .. " zq20 " .. H.rep("more words ", 6) .. "end"
        H.type(T.text)
        if how == "mouse" then H.saveClick() else T.go = H.padOn() and H.focusId("journal:__save") end
    end)
    if how == "mouse" then
        H.step(3, function() if not T.off then T.q1 = H.qcount("ZeD_WriteNoteAction"); H.saveClick() end end)
    else
        H.tapA(function() return T.go end)
        H.step(1, function() if not T.off then T.q1 = H.qcount("ZeD_WriteNoteAction") end end)
        H.tapA(function() return T.go end)
    end
    H.step(2, function() if not T.off then T.q2 = H.qcount("ZeD_WriteNoteAction") end end)
    H.writeWait(T)
    H.step(3, function()
        if T.off then return end
        H.padOff()
        local made = 0
        for _, e in ipairs(H.runEnts()) do if e.text == T.text then made = made + 1 end end
        local onPage = 0
        for i = 1, H.pages(T.nb) do onPage = onPage + H.count(H.page(T.nb, i), T.text) end
        Q.check(made == 1 and onPage == 1, T.L .. " (" .. how .. ", B1): Save pressed again while the write runs writes and logs it once",
            made .. " entries, " .. onPage .. " times on the page; the queue held " .. tostring(T.q1) .. " then " .. tostring(T.q2) .. " writes")
        H.type("")
    end)
end
function C.j20()
    local T = { L = "J20 Save twice while writing" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA twice")
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 1)
    H.intoQ(T, "nb")
    C.j20leg(T, "mouse")
    C.j20leg(T, "pad")
    H.caseEnd(T.L)
end

-- odd books, B3
function C.j21()
    local T = { L = "J21 odd books" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.items, T.miss = {}, {}
        for _ = 1, 5 do local it = H.give("Base.SheetPaper2"); if it then T.items[#T.items + 1] = it end end
        for _, ft in ipairs({ "Base.IndexCard", "Base.Card_Birthday", "Base.IDcard_Blank", "Base.Notepad" }) do
            if H.known(ft) then
                local it = H.give(ft)
                if it then T.items[#T.items + 1] = it end
                if ft == "Base.IDcard_Blank" then T.id = it end
                if ft == "Base.SheetPaper2" then T.sheet = it end
            else T.miss[#T.miss + 1] = ft end
        end
        T.sheet = T.items[1]
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 2)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local books = (H.st().carried or {}).books or {}
        local set = {}
        for _, b in ipairs(books) do set[b] = true end
        local notIn, noRow, writable = {}, {}, 0
        for _, it in ipairs(T.items) do
            local cw = false
            pcall(function() cw = it:canBeWrite() and true or false end)
            if cw then writable = writable + 1 end
            if not set[it] then notIn[#notIn + 1] = H.ft(it) end
            if not H.jrZone("book:" .. tostring(H.id(it))) then noRow[#noRow + 1] = H.ft(it) end
        end
        Q.check(writable == #T.items and #notIn == 0 and #noRow == 0, T.L .. ": every item the game can write in is listed with its own row (five sheets, five rows)",
            #T.items .. " given (" .. writable .. " canBeWrite); not listed " .. H.list(notIn) .. "; no row " .. H.list(noRow) .. (#T.miss > 0 and ("; unknown here " .. H.list(T.miss)) or ""))
        -- a one-page sheet full after 15 lines
        H.setPage(T.sheet, 1, H.lines(15, "sheet"))
        H.jrPress("book:" .. tostring(H.id(T.sheet)), T.L)
    end)
    H.step(3, function()
        if T.off then return end
        pcall(function() RT.cw()._jrNote:setText("ZQA one line more") end)
        H.jrPress("write", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        local s = H.st()
        Q.check(s.msg == H.tr("UI_ZeD_Notebook_NoRoomPage") and H.qcount("ZeD_WriteNoteAction") == 0,
            T.L .. ": a sheet's page is full after 15 lines: no room, nothing queued", H.ft(T.sheet) .. ", " .. H.pages(T.sheet) .. " page(s) (the game's PageToWrite), line \"" .. tostring(s.msg) .. "\"")
        if not T.id then T.noId = true; Q.skip(T.L .. " (B3): a blank ID card locks once written", "Base.IDcard_Blank is not in this game"); return end
        H.jrPress("book:" .. tostring(H.id(T.id)), T.L)
    end)
    H.step(3, function()
        if T.off or T.noId then return end
        pcall(function() RT.cw()._jrNote:setText("ZQA id card") end)
        H.jrPress("write", T.L)
    end)
    H.writeWait(T)
    H.step(3, function()
        if T.off or T.noId then return end
        local tagged, by = false, nil
        pcall(function() tagged = T.id:hasTag(ItemTag.LOCK_ON_WRITE) and true or false end)
        pcall(function() by = T.id:getLockedBy() end)
        local written = H.endsWith(H.page(T.id, 1), "ZQA id card")
        Q.check(written and ((not tagged) or by ~= nil), T.L .. " (B3): a write-once item (the game's LOCK_ON_WRITE) is locked once the quick note writes it, as the game's journal window locks it",
            "written " .. tostring(written) .. ", tag " .. tostring(tagged) .. ", locked by " .. tostring(by))
        local srj = H.firstKnown({ "SkillRecoveryJournal.SkillRecoveryBoundJournal", "Base.SkillRecoveryBoundJournal" })
        if srj then H.note(T.L .. ": Skill Recovery Journal's " .. srj .. " is here: its CanBeWrite decides whether the Journal lists it")
        else Q.skip(T.L .. ": Skill Recovery Journal's Bound Journal", "the mod is not on in this game") end
    end)
    H.caseEnd(T.L)
end

function C.j22()
    local T = { L = "J22 newlines into a book" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA newlines")
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 1)
    H.intoQ(T, "nb")
    H.step(2, function()
        if T.off then return end
        H.type("ZQA two" .. S.NL .. "lines zq22")
        H.saveClick()
    end)
    H.writeWait(T)
    H.step(3, function()
        if T.off then return end
        local e = (H.ents() or {})[1]
        local pg = H.page(T.nb, 1)
        Q.check(pg == "ZQA two lines zq22" and e ~= nil and e.text == "ZQA two lines zq22", T.L .. ": Into writes a two-line text as one line, on the page and in the entry",
            "page \"" .. pg .. "\", entry \"" .. tostring(e and e.text) .. "\"")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== Notebooks (J23-J29)
function H.litRead(it) local r = false; pcall(function() r = ISInventoryPane.isLiteratureRead(nil, S.p, it) == true end); return r end
function H.fillRows(block) local s = H.st(); local c = s and s.carried; return (c and c.rows and c.rows[block]) or {} end
function H.fillZone(id) local w = RT.cw(); local z = nil; pcall(function() for _, zz in ipairs(ZeD.TabFill.zones(w, "notebooks") or {}) do if zz.id == id then z = zz end end end); return z end
function H.pagesBack()
    if S.back.pages then pcall(function() S.p:setAlreadyReadPages(S.back.pages.ft, S.back.pages.n) end); S.back.pages = nil end
end
function C.j23()
    local T = { L = "J23 no notebook carried" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.id1 = H.pickFlyer(0) or H.pickFlyer(1) or "zqa_flyer_one"
        T.id2 = H.pickFlyer(1, { [T.id1] = true }) or "zqa_flyer_two"
        T.f1 = H.paper("Base.Flier", T.id1)
        T.f2 = H.paper("Base.Flier", T.id2)
        H.markRead(T.id2)
        T.skill = H.give("Base.BookCarpentry1")
        pcall(function()
            local ft = T.skill:getFullType()
            local n = T.skill:getNumberOfPages()
            S.back.pages = { ft = ft, n = S.p:getAlreadyReadPages(ft) }
            S.p:setAlreadyReadPages(ft, math.floor(n / 2))
        end)
        T.mag = H.give(H.firstKnown({ "Base.Magazine", "Base.TVMagazine" }))
        T.comic = H.give(H.firstKnown({ "Base.ComicBook" }))
        T.pen = H.give("Base.Pencil")
        H.rescan()
        -- (the blocks open, as found after)
        pcall(function()
            local fs = RT.cw()._fill and RT.cw()._fill.notebooks
            if fs and fs.fold then T.fold0 = H.copy(fs.fold); fs.fold.writing, fs.fold.papers, fs.fold.books = nil, nil, nil end
        end)
    end)
    H.frontQ(T, 2)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        Q.check(H.drewI(H.tr("UI_ZeD_Notebook_NoneCarried")) ~= nil, T.L .. ": it reads \"" .. H.tr("UI_ZeD_Notebook_NoneCarried") .. "\"", H.drewLike(" ", 3))
        local tool, light = H.toolsHeld() > 0, not H.dark()
        Q.check(H.drewOrCut(H.tr(tool and "UI_ZeD_Notebook_HasTool" or "UI_ZeD_Notebook_WhyNoTool")) ~= nil and H.drewOrCut(H.tr(light and "UI_ZeD_Notebook_LightOk" or "UI_ZeD_Notebook_WhyTooDark")) ~= nil,
            T.L .. ": the Writing block's two rows match the game (a pencil by its tags, the light by tooDarkToRead)", "tool " .. tostring(tool) .. ", light " .. tostring(light))
        local nRead = (H.isRead(T.id1) and 1 or 0) + (H.isRead(T.id2) and 1 or 0)
        local cnt = H.tr("UI_ZeD_Papers_Count", nRead, 2)
        Q.check(H.drewI(cnt) ~= nil or #H.fillRows("papers") == 2, T.L .. ": Papers on you counts the two flyers and the one read (\"" .. cnt .. "\")", #H.fillRows("papers") .. " rows")
        local bad, seen = {}, {}
        for _, it in ipairs({ T.skill, T.mag, T.comic }) do
            if it then
                local name = ""
                pcall(function() name = it:getDisplayName() end)
                local row = nil
                for _, r in ipairs(H.fillRows("reads")) do if r.label == name then row = r end end
                local want = H.tr(H.litRead(it) and "UI_ZeD_Papers_StateRead" or "UI_ZeD_Read_Unread")
                seen[#seen + 1] = name .. ": " .. tostring(row and row.sub)
                if not (row and string.sub(tostring(row.sub), 1, #want) == want) then bad[#bad + 1] = name .. " (the game: " .. want .. ")" end
            end
        end
        Q.check(#bad == 0, T.L .. ": Books on you: each row's Read or Unread is the game's isLiteratureRead (the half-read skill book too)", #bad == 0 and H.list(seen) or H.list(bad))
        if S.found.toolsKept == 0 then H.removeItem(T.pen); H.rescan() end
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        if S.found.toolsKept == 0 then
            Q.check(H.drewOrCut(H.tr("UI_ZeD_Notebook_WhyNoTool")) ~= nil, T.L .. ": the pencil taken away, the Writing block says why", H.drewLike(" ", 3))
        else Q.skip(T.L .. ": the Writing block with no pencil", "a writing tool of his stays worn or held") end
        local rows = H.fillRows("papers")
        T.want = nil
        if rows[1] then
            for _, e in ipairs((H.st().carried or {}).papers or {}) do if not T.want then T.want = e.id end end
        end
        T.press = H.press(H.fillZone("fill:notebooks:paper:1"))
    end)
    H.step(4, function()
        if T.off then return end
        local w = RT.cw()
        Q.check(T.press and w._journalSubTab == 3 and H.st().paperOpen == T.want, T.L .. ": a row under Papers on you opens Papers on that piece", "page " .. tostring(w._journalSubTab) .. ", open " .. tostring(H.st().paperOpen) .. ", want " .. tostring(T.want))
        H.pagesBack()
        if T.fold0 then pcall(function() RT.cw()._fill.notebooks.fold = T.fold0 end) end
    end)
    H.caseEnd(T.L)
end

function C.j24()
    local T = { L = "J24 the Notebooks list" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.blank = H.book("Base.Notebook", "ZQA blank book")
        T.jr = H.book(H.firstKnown({ "Base.Journal", "Base.Notebook" }), "ZQA journal")
        for i = 1, 3 do H.setPage(T.jr, i, "zq page " .. i) end
        T.diary = H.book(H.firstKnown({ "Base.Diary1", "Base.Notebook" }), "Supply runs")
        T.lock = H.book("Base.Notebook", "ZQA locked")
        pcall(function() T.lock:setLockedBy(H.user()) end)
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 2)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local kind = function(it) local k = "?"; pcall(function() k = it:getScriptItem():getDisplayName() end); return k end
        local subB = H.tr("UI_ZeD_Notebook_SubBlank", kind(T.blank), H.pages(T.blank))
        local subJ = H.tr("UI_ZeD_Notebook_SubWritten", kind(T.jr), 3, H.pages(T.jr))
        Q.check(H.drewI("Supply runs") ~= nil and (H.drewI(subB) ~= nil or H.drewCut(subB) ~= nil) and (H.drewI(subJ) ~= nil or H.drewCut(subJ) ~= nil),
            T.L .. ": the rows read the books' names and kinds (\"" .. subB .. "\", \"" .. subJ .. "\", the renamed diary)", H.drewLike(",", 6))
        local lockedW = H.tr("UI_ZeD_Notebook_SubLockedOne")
        H.note(T.L .. ": a book locked by you draws its kind line (\"" .. tostring(H.drewI(kind(T.lock)) and H.drewI(kind(T.lock)).s) .. "\"); \"Locked\" (" .. lockedW
            .. ") is drawn only for a book another locked (JR bookSub: N.otherLock); the map's J24 reads Locked for yours")
        T.press = H.jrPress("book:" .. tostring(H.id(T.jr)), T.L)
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local s = H.st()
        local id = H.id(T.jr)
        local all = H.pages(T.jr)
        Q.check(T.press and s.nbId == id and s.nbPage[id] == 3 and H.drewI(H.tr("UI_ZeD_Reader_PageOf", 3, all)) ~= nil, T.L .. " (mouse): a press picks the book; its page opens at the last written (3)",
            "picked " .. tostring(s.nbId) .. ", page " .. tostring(s.nbPage[id]))
        local prev, nxt = H.jrZone("prev"), H.jrZone("next")
        Q.check(prev ~= nil and prev.fn ~= nil and nxt ~= nil and nxt.fn ~= nil, T.L .. ": on page 3 of " .. all .. " both < and > are live", H.list(H.jrIds()))
        s.nbPage[id] = 1
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local prev = H.jrZone("prev")
        Q.check(prev ~= nil and prev.fn == nil, T.L .. ": on page 1 < is greyed", H.list(H.jrIds("p")))
        T.goN = 0
    end)
    H.wait(4000, function()
        if T.off then return true end
        local s = H.st()
        local id = H.id(T.jr)
        if (s.nbPage[id] or 1) >= H.pages(T.jr) then return true end
        T.goN = T.goN + 1
        if T.goN - math.floor(T.goN / 3) * 3 == 0 then H.jrPress("next", T.L) end
        return false
    end, function(ok)
        if T.off then return end
        local nxt = H.jrZone("next")
        Q.check(ok and nxt ~= nil and nxt.fn == nil, T.L .. ": > walks to the last page, where it is greyed", "page " .. tostring(H.st().nbPage[H.id(T.jr)]) .. " of " .. H.pages(T.jr))
        H.st().nbPage[H.id(T.jr)] = 3
    end)
    H.shot("jn_notebook_" .. H.sizeTag(), "Notebooks: four books, a journal picked on its third page", function() return not T.off end)
    H.step(1, function() pcall(function() T.lock:setLockedBy(nil) end) end)
    H.caseEnd(T.L)
end

function C.j25()
    local T = { L = "J25 the quick note" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA quick note")
        H.setPage(T.nb, 1, H.lines(2, "zq25"))
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 2)
    H.step(2, function() if not T.off then H.jrPress("book:" .. tostring(H.id(T.nb)), T.L) end end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local left = 15 - 2
        Q.check(H.drewOrCut(H.tr("UI_ZeD_Notebook_ReadyMany", left)) ~= nil, T.L .. ": the line under the note counts the lines left (" .. left .. ")", H.drewLike(" ", 4))
        pcall(function() RT.cw()._jrNote:setText("ZQA quick line zq25") end)
        T.press = H.jrPress("write", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(T.press and H.qcount("ZeD_WriteNoteAction") == 1, T.L .. " (mouse): Write queues the line", H.qkinds())
        T.writing = H.writingDrawn()
    end)
    H.writeWait(T)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local pg = H.page(T.nb, 1)
        Q.check(H.endsWith(pg, "ZQA quick line zq25") and H.drewOrCut(H.tr("UI_ZeD_Notebook_ReadyMany", 12)) ~= nil, T.L .. ": the line is on the page (seePage) and the lines left drop to 12",
            "page ends \"" .. tostring(string.sub(pg, -24)) .. "\"; Writing shown " .. tostring(T.writing))
        H.setPage(T.nb, 1, H.lines(15, "zq25"))
        pcall(function() RT.cw()._jrNote:setText("ZQA no room zq25") end)
        H.jrPress("write", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        local s = H.st()
        Q.check(s.msg == H.tr("UI_ZeD_Notebook_NoRoomPage") and H.qcount("ZeD_WriteNoteAction") == 0, T.L .. ": a full page: no room, nothing queued", "\"" .. tostring(s.msg) .. "\", " .. H.qkinds())
        local e = RT.cw()._jrNote
        local n = 0
        pcall(function() e:setText(H.rep("b", 200)); n = #(e:getText() or "") end)
        H.note(T.L .. ": the note's limit is " .. tostring(e and e.maxLength) .. " letters; 200 set by code read back " .. n)
        Q.check(e ~= nil and e.maxLength == 160, T.L .. ": the note takes at most 160 letters (2 lines of 80)", tostring(e and e.maxLength))
        -- B2: Enter in the note
        local inner = e and e._entry
        local hook = inner and inner.onCommandEntered
        T.hook = hook
        T.own = false
        pcall(function() T.own = rawget(inner, "onCommandEntered") ~= nil end)
        pcall(function() e:setText("ZQA enter zq25") end)
        H.setPage(T.nb, 1, "")
        if type(hook) == "function" then H.zcall(function() hook(inner) end) end
    end)
    H.step(3, function()
        if T.off then return end
        local e = RT.cw()._jrNote
        Q.check(type(T.hook) == "function" and H.qcount("ZeD_WriteNoteAction") == 1, T.L .. " (B2): Enter in the note writes the line (its onSubmit reached)",
            "the note's inner box onCommandEntered " .. type(T.hook) .. (T.own and " (its own)" or " (the game's ISTextEntryBox default, empty)") .. ", onSubmit " .. type(e and e.onSubmit)
            .. " (set at JR:694, called by nothing in ZeD_TextEntry, MO:910-938), queued " .. H.qcount("ZeD_WriteNoteAction"))
        H.qstop()
        T.go = H.padOn() and H.focusId("jr:note")
        if not T.go then Q.check(false, T.L .. " (pad): the note is a stop while it shows whole", "stops " .. H.stopIds()) end
    end)
    H.tapA(function() return T.go end)
    H.step(5, function()
        if T.off or not T.go then return end
        Q.check(H.kbUp(), T.L .. " (pad): A on the note opens the pad keyboard", tostring(H.kbUp()))
        H.kbHide()
        H.padOff()
    end)
    H.caseEnd(T.L)
end

function C.j26leg(T, name, arm, wantKey, undo)
    H.step(2, function()
        T.legOff, T.ready = nil, nil
        if T.off then return end
        local why = arm()
        if why then T.legOff = true; Q.skip(T.L .. ": " .. name, why) end
        H.rescan()
    end)
    H.wait(5000, function() return T.off or T.legOff or T.ready == nil or T.ready() end, function()
        if T.off or T.legOff or T.ready == nil or T.ready() then return end
        T.legOff = true
        Q.skip(T.L .. ": " .. name, "still light enough to read here at midnight (a lit square)")
        undo()
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off or T.legOff then return end
        local w = RT.cw()
        local want = H.tr(wantKey)
        local wz = H.jrZone("write")
        local shown = false
        pcall(function() shown = w._jrNote:isVisible() end)
        Q.check(not shown and wz ~= nil and wz.fn == nil and (H.drewI(want) ~= nil or H.drewCut(want) ~= nil), T.L .. ": " .. name .. ": the note hides, Write is greyed and the line says why",
            "note shown " .. tostring(shown) .. ", Write " .. tostring(wz and (wz.fn and "live" or "grey")) .. ", line \"" .. want .. "\"")
        if T.other then
            local sub = H.tr("UI_ZeD_Notebook_SubLockedOne")
            local sub2 = H.tr("UI_ZeD_Notebook_SubLockedMany", 1)
            Q.check(H.drewI(sub) ~= nil or H.drewI(sub2) ~= nil, T.L .. ": " .. name .. ": the book's row reads Locked", H.drewLike(" ", 4))
            T.other = nil
        end
        undo()
    end)
end
function C.j26()
    local T = { L = "J26 the quick note's refusals" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA refuse note")
        H.setPage(T.nb, 1, "zq26 written")
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 2)
    H.step(2, function() if not T.off then H.jrPress("book:" .. tostring(H.id(T.nb)), T.L) end end)
    C.j26leg(T, "no pencil or pen", function()
        if S.found.toolsKept > 0 then return "a writing tool of his stays worn or held" end
        H.removeItem(T.pen); return nil
    end, "UI_ZeD_Notebook_WhyNoTool", function() T.pen = H.give("Base.Pencil") end)
    C.j26leg(T, "too dark", function() H.tod(0); T.ready = function() return H.dark() end; return nil end, "UI_ZeD_Notebook_WhyTooDark", function() H.tod(S.NOON) end)
    C.j26leg(T, "locked by you", function() pcall(function() T.nb:setLockedBy(H.user()) end); return nil end, "UI_ZeD_Notebook_WhyLockedMine", function() pcall(function() T.nb:setLockedBy(nil) end) end)
    C.j26leg(T, "locked by another (J49's single-player half)", function()
        local adm = false
        pcall(function() adm = isAdmin() and true or false end)
        if adm then return "this game counts him an admin: another's lock does not hold for him" end
        pcall(function() T.nb:setLockedBy("zqa_other_writer") end)
        T.other = true
        return nil
    end, "UI_ZeD_Notebook_WhyLockedOther", function() pcall(function() T.nb:setLockedBy(nil) end) end)
    H.caseEnd(T.L)
end

function C.j27()
    local T = { L = "J27 Open full" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA open full")
        H.setPage(T.nb, 1, "zq27 written page")
        T.blank = H.book("Base.Notebook", "ZQA open blank")
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 2)
    H.step(2, function() if not T.off then H.jrPress("book:" .. tostring(H.id(T.nb)), T.L) end end)
    H.step(4, function() if not T.off then T.press = H.jrPress("full", T.L) end end)
    H.wait(6000, function() return T.off or H.readerUp() ~= nil end, function(ok)
        if T.off then return end
        local r = H.readerUp()
        Q.check(T.press and ok and r.mode == "notebook" and r.item == T.nb and not r.readOnly, T.L .. ": written, a pencil carried: Open full opens ZeD's reader on it to write (the game's Write note)",
            "reader " .. tostring(r and r.mode) .. ", read only " .. tostring(r and r.readOnly) .. ", queue " .. H.qkinds())
        H.readerShut()
        H.qstop()
        if S.found.toolsKept == 0 then H.removeItem(T.pen); H.rescan() else T.noPenSkip = true end
    end)
    H.step(6, function()
        if T.off then return end
        if T.noPenSkip then Q.skip(T.L .. ": written, no pencil", "a writing tool of his stays worn or held"); return end
        T.press2 = H.jrPress("full", T.L)
    end)
    H.wait(6000, function() return T.off or T.noPenSkip or H.readerUp() ~= nil end, function(ok)
        if T.off or T.noPenSkip then return end
        local r = H.readerUp()
        Q.check(T.press2 and ok and r.readOnly == true, T.L .. ": written, no pencil: Open full opens it to read only (the game's Read note)", "read only " .. tostring(r and r.readOnly))
        H.readerShut()
        H.qstop()
        H.jrPress("book:" .. tostring(H.id(T.blank)), T.L)
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        if T.noPenSkip then
            Q.skip(T.L .. ": a blank book and no pencil", "a writing tool of his stays worn or held")
        else
            local z = H.jrZone("full")
            Q.check(z ~= nil and z.fn == nil, T.L .. ": a blank book and no pencil: Open full is greyed", tostring(z and (z.fn and "live" or "grey")))
            T.pen = H.give("Base.Pencil")
        end
        H.jrPress("book:" .. tostring(H.id(T.nb)), T.L)
        H.tod(0)
    end)
    H.wait(5000, function() return T.off or H.dark() end, function(ok)
        if T.off then return end
        if not ok then Q.skip(T.L .. ": in the dark", "still light enough to read here at midnight (a lit square)"); return end
        T.darkOk = true
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off or not T.darkOk then H.tod(S.NOON); return end
        local z = H.jrZone("full")
        Q.check(z ~= nil and z.fn == nil, T.L .. ": in the dark Open full is greyed", tostring(z and (z.fn and "live" or "grey")))
        H.tod(S.NOON)
    end)
    H.caseEnd(T.L)
end

function C.j28()
    local T = { L = "J28 the Notebooks search" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.a = H.book("Base.Notebook", "ZQA alpha")
        H.setPage(T.a, 4, "the word zqpagefour is here")
        T.b = H.book("Base.Notebook", "ZQA beta")
        H.setPage(T.b, 1, "nothing of it")
        H.rescan()
    end)
    H.frontQ(T, 2)
    H.step(2, function() if not T.off then pcall(function() RT.cw()._flyerSearch.input:setText("zqpagefour") end) end end)
    H.wait(2000, function() return T.off or RT.cw()._flyerSearchText == "zqpagefour" end, function() end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        Q.check(H.jrZone("book:" .. tostring(H.id(T.a))) ~= nil and H.jrZone("book:" .. tostring(H.id(T.b))) == nil, T.L .. ": a word only on page 4 of one book lists that book alone",
            H.list(H.jrIds("book:")))
        pcall(function() RT.cw()._flyerSearch.input:setText("zqnowhere") end)
    end)
    H.wait(2000, function() return T.off or RT.cw()._flyerSearchText == "zqnowhere" end, function() end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local word = H.tr("UI_ZeD_Notebook_NoneMatch")
        Q.check(H.drewI(word) ~= nil and #H.jrIds("book:") == 0, T.L .. ": a word in none reads \"" .. word .. "\"", H.drewLike(" ", 3))
    end)
    H.caseEnd(T.L)
end

function C.j29()
    local T = { L = "J29 a notebook in a bag" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.bag = H.give(H.firstKnown({ "Base.Bag_Schoolbag", "Base.Bag_Satchel", "Base.Bag_DuffelBag" }))
        local inv = nil
        pcall(function() inv = T.bag:getInventory() end)
        if not inv then T.off = true; Q.skip(T.L, "no bag type found here"); return end
        T.nb = H.giveTo(inv, "Base.Notebook")
        pcall(function() T.nb:setName("ZQA in a bag"); T.nb:setCustomName(true) end)
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 2)
    H.step(2, function() if not T.off then H.jrPress("book:" .. tostring(H.id(T.nb)), T.L) end end)
    H.step(4, function()
        if T.off then return end
        pcall(function() RT.cw()._jrNote:setText("ZQA from the bag zq29") end)
        H.jrPress("write", T.L)
        T.q = H.qkinds()
    end)
    H.writeWait(T)
    H.wait(5000, function() return T.off or H.qlen() == 0 end, function() end)
    H.step(30, function()
        if T.off then return end
        T.zIn = H.where(T.nb) == H.inv()
        T.zWhere = H.ctypeOf(T.nb)
        -- the game's own way out of the bag (transferIfNeeded, which its Write note and ZeD both call) on a second book
        local inv = nil
        pcall(function() inv = T.bag:getInventory() end)
        T.nb2 = inv and H.giveTo(inv, "Base.Notebook")
        pcall(function() ISInventoryPaneContextMenu.transferIfNeeded(S.p, T.nb2) end)
        T.q2 = H.qkinds()
        H.speed(2)
    end)
    H.wait(8000, function() return T.off or H.qlen() == 0 end, function() H.speed(1) end)
    H.step(30, function()
        if T.off then return end
        local gIn = H.where(T.nb2) == H.inv()
        H.note(T.L .. ": queued at Write: " .. tostring(T.q) .. "; the game's transferIfNeeded queued " .. tostring(T.q2) .. " and left its book in " .. H.ctypeOf(T.nb2))
        Q.check(T.zIn and gIn and H.endsWith(H.page(T.nb, 1), "ZQA from the bag zq29"), T.L .. ": Write takes the book out of the bag and leaves it in his main inventory (the game's own transfer does)",
            "ZeD's book in " .. tostring(T.zWhere) .. ", the game's in " .. H.ctypeOf(T.nb2) .. ", page \"" .. H.page(T.nb, 1) .. "\"")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== Papers (J30-J34)
function H.paperIn(inv, ft, id)
    local it = H.giveTo(inv, ft)
    if not it then return nil end
    pcall(function()
        local m = (ZeD.Print and ZeD.Print.ofId) and ZeD.Print.ofId(id) or { id = id, title = "Print_Media_" .. id .. "_title" }
        it:getModData().printMedia = { id = id, title = m.title, info = m.info, text = m.text }
    end)
    return it
end
function H.titleOf(id)
    local t = id
    pcall(function()
        local m = (ZeD.Print and ZeD.Print.ofId) and ZeD.Print.ofId(id) or { title = "Print_Media_" .. id .. "_title" }
        t = getTextOrNull(m.title) or id
    end)
    return tostring(t)
end
function H.paperIds() local o = {}; local w = RT.cw(); for _, z in ipairs((w and w._jrZones) or {}) do local id = string.match(tostring(z.id), "^paper:(.+)$"); if id then o[#o + 1] = id end end; return o end
function H.autoRevealOff() pcall(function() getCore():setOptionAutoRevealPrintMediaMapLocations(false) end) end
function H.autoRevealBack() if S.found.autoReveal ~= nil then pcall(function() getCore():setOptionAutoRevealPrintMediaMapLocations(S.found.autoReveal) end) end end
-- five pieces: two copies of one flyer, a second flyer read, a newspaper, a brochure, a flyer in a bag
function H.stagePapers(T)
    T.idA = H.pickFlyer(1) or "zqa_flyer_a"
    T.idB = H.pickFlyer(1, { [T.idA] = true }) or "zqa_flyer_b"
    T.idC = H.pickFlyer(1, { [T.idA] = true, [T.idB] = true }) or "zqa_flyer_c"
    T.a1 = H.paper("Base.Flier", T.idA)
    T.a2 = H.paper("Base.Flier", T.idA)
    T.b = H.paper("Base.Flier", T.idB)
    H.markRead(T.idB)
    T.news = H.paper("Base.Newspaper", "zqa_news")
    T.bro = H.paper("Base.Brochure", "zqa_brochure")
    T.bag = H.give(H.firstKnown({ "Base.Bag_Schoolbag", "Base.Bag_Satchel", "Base.Bag_DuffelBag" }))
    local inv = nil
    pcall(function() inv = T.bag:getInventory() end)
    T.c = inv and H.paperIn(inv, "Base.Flier", T.idC) or H.paper("Base.Flier", T.idC)
    T.all = { T.idA, T.idB, T.idC, "zqa_news", "zqa_brochure" }
    H.rescan()
end
function C.j30()
    local T = { L = "J30 the Papers list" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.stagePapers(T)
    end)
    H.frontQ(T, 3)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local ids = H.paperIds()
        local nA = 0
        for _, id in ipairs(ids) do if id == T.idA then nA = nA + 1 end end
        Q.check(#ids == 5 and nA == 1, T.L .. ": one row per piece: the two copies show once; the one in the bag is listed", #ids .. " rows: " .. H.list(ids))
        -- read first, then by title (the game's text for the title)
        local want = {}
        for _, id in ipairs(T.all) do want[#want + 1] = { id = id, read = H.isRead(id), t = H.titleOf(id) } end
        table.sort(want, function(a, b) if a.read ~= b.read then return a.read end; return a.t < b.t end)
        local okO = #ids == #want
        local wl = {}
        for i, e in ipairs(want) do wl[#wl + 1] = e.id; if ids[i] ~= e.id then okO = false end end
        Q.check(okO, T.L .. ": the rows run read first, then by title", "drawn " .. H.list(ids) .. "; want " .. H.list(wl))
        local nRead, nMap = 0, 0
        for _, id in ipairs(T.all) do if H.isRead(id) then nRead = nRead + 1; if H.places(id) > 0 then nMap = nMap + 1 end end end
        local cnt = (nMap > 0) and H.tr("UI_ZeD_Papers_CountWithPlaces", nRead, 5, nMap) or H.tr("UI_ZeD_Papers_Count", nRead, 5)
        Q.check(H.drewI(cnt) ~= nil, T.L .. ": the count line reads \"" .. cnt .. "\" (the game's read marks, PrintMediaDefinitions' places)", H.drewLike(" ", 3))
        local bad = {}
        for _, id in ipairs(T.all) do
            local z = H.jrZone("paper:" .. id)
            local want1 = H.tr(H.isRead(id) and "UI_ZeD_Papers_StateRead" or "UI_ZeD_Read_Unread")
            if not (z and H.drewIn(z, want1)) then bad[#bad + 1] = id .. " (the game: " .. want1 .. ")" end
        end
        Q.check(#bad == 0, T.L .. ": each row's Read or Unread is the game's isPrintMediaRead", #bad == 0 and "all five" or H.list(bad))
        local n = H.places(T.idB)
        local pl = (n == 1) and H.tr("UI_ZeD_Papers_PlaceOne") or H.tr("UI_ZeD_Papers_PlaceMany", n)
        if n > 0 then Q.check(H.drewI(pl) ~= nil, T.L .. ": the read row counts its places (" .. n .. ", PrintMediaDefinitions.MiscDetails)", "\"" .. pl .. "\"; " .. H.drewLike("|", 4))
        else Q.skip(T.L .. ": the read row's places", "the read piece has none") end
    end)
    H.caseEnd(T.L)
end

function C.j31()
    local T = { L = "J31 Show and search" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.stagePapers(T)
    end)
    H.frontQ(T, 3)
    local legs = { { f = "news", want = { "zqa_news" } }, { f = "flyer", want = nil }, { f = "map", want = nil }, { f = "all", want = nil } }
    for _, L in ipairs(legs) do
        H.step(2, function() if not T.off then H.jrPress("show", T.L) end end)
        H.drawn(T, 2)
        H.step(1, function() if not T.off then T.pr = H.jrPress("showRow:" .. L.f, T.L) end end)
        H.drawn(T, 3)
        H.step(1, function()
            if T.off then return end
            local want = L.want
            if L.f == "flyer" then want = { T.idA, T.idB, T.idC, "zqa_brochure" } end
            if L.f == "map" then want = {}; for _, id in ipairs(T.all) do if H.isRead(id) and H.places(id) > 0 then want[#want + 1] = id end end end
            if L.f == "all" then want = T.all end
            local ids, set = H.paperIds(), {}
            for _, id in ipairs(ids) do set[id] = true end
            local ok = #ids == #want
            for _, id in ipairs(want) do if not set[id] then ok = false end end
            Q.check(T.pr and H.st().filter == L.f and ok and not H.st().showOpen, T.L .. " (mouse): Show " .. L.f .. " keeps its rows and shuts the list",
                "rows " .. H.list(ids) .. "; want " .. H.list(want) .. "; open " .. tostring(H.st().showOpen))
        end)
    end
    -- a title word
    H.step(2, function()
        if T.off then return end
        local t = string.lower(H.titleOf(T.idA))
        T.word = string.match(t, "%a%a%a%a+") or string.sub(t, 1, 4)
        pcall(function() RT.cw()._flyerSearch.input:setText(T.word) end)
    end)
    H.wait(2000, function() return T.off or RT.cw()._flyerSearchText == T.word end, function() end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local ids = H.paperIds()
        local bad = {}
        for _, id in ipairs(ids) do if not H.has(string.lower(H.titleOf(id)), T.word) then bad[#bad + 1] = id end end
        local hasA = false
        for _, id in ipairs(ids) do if id == T.idA then hasA = true end end
        Q.check(hasA and #bad == 0, T.L .. ": a title word (\"" .. T.word .. "\") keeps the pieces whose title holds it", "rows " .. H.list(ids) .. "; without it " .. H.list(bad))
        pcall(function() RT.cw()._flyerSearch.input:setText("") end)
        H.jrPress("show", T.L)
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        T.f0 = H.st().filter
        local z = H.jrZone("paper:" .. T.idB)
        T.out = z ~= nil and H.click(z.x + 4, z.y + math.floor(z.h / 2))
    end)
    H.step(3, function()
        if T.off then return end
        local s = H.st()
        Q.check(T.out and not s.showOpen and s.filter == T.f0 and s.paperOpen == nil, T.L .. ": a press outside the open list shuts it and does nothing else", "open " .. tostring(s.showOpen) .. ", filter " .. tostring(s.filter) .. ", opened " .. tostring(s.paperOpen))
    end)
    H.caseEnd(T.L)
end

function C.j32()
    local T = { L = "J32 Read an unread piece" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.autoRevealOff()
        T.idU = H.pickFlyer(1)
        T.idU2 = T.idU and H.pickFlyer(1, { [T.idU] = true })
        if not (T.idU and T.idU2) then T.off = true; Q.skip(T.L, "no two flyers the game knows are left unread by him"); return end
        T.fU = H.paper("Base.Flier", T.idU)
        T.fU2 = H.paper("Base.Flier", T.idU2)
        H.note(T.L .. ": the game's auto reveal of print media places is off for this case (a read would mark the map for good)")
        H.rescan()
    end)
    H.frontQ(T, 3)
    H.step(2, function() if not T.off then H.jrPress("paper:" .. T.idU, T.L) end end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local z = H.jrZone("read")
        Q.check(H.st().paperOpen == T.idU and z ~= nil and z.fn ~= nil and H.drewI(H.gt("ContextMenu_Read")) ~= nil, T.L .. ": an unread piece's quick look offers Read (live in the light)", H.list(H.jrIds()))
        H.note(T.L .. ": the button says \"" .. H.gt("ContextMenu_Read") .. "\" where the game's item menu says \"" .. H.gt("ContextMenu_Inspect") .. "\" for print media")
        T.press = H.jrPress("read", T.L)
    end)
    H.step(2, function()
        if T.off then return end
        T.q1 = H.qcount("ISReadABook")
        Q.check(T.press and T.q1 >= 1, T.L .. " (mouse): Read queues the game's ISReadABook", H.qkinds())
        T.go = H.padOn() and H.focusId("jr:read")
    end)
    H.tapB(function() return T.go end)
    H.step(4, function()
        if T.off then return end
        local s = H.st()
        Q.check(T.go and H.qcount("ISReadABook") == 0 and not H.isRead(T.idU), T.L .. " (J43): the pad's B during the read stops it",
            "queue " .. H.qkinds() .. ", read " .. tostring(H.isRead(T.idU)) .. ", the quick look " .. tostring(s.paperOpen)
            .. " (the Read stop's B is its Back, cancel = back at JR:518-519; FM stops the action only on a stop with no onCancel)")
        H.padOff()
        H.qstop()
        if s.paperOpen ~= T.idU then H.jrPress("paper:" .. T.idU, T.L) end
    end)
    H.step(4, function()
        if T.off then return end
        T.press2 = H.jrPress("read", T.L)
        H.speed(2)
    end)
    H.wait(30000, function() return T.off or H.isRead(T.idU) end, function(ok)
        H.speed(1)
        if T.off then return end
        if ok then S.readAdded[#S.readAdded + 1] = T.idU end
        Q.check(T.press2 and ok, T.L .. ": read through, the game marks it read (isPrintMediaRead)", H.qkinds())
    end)
    H.wait(4000, function() return T.off or H.readerUp() ~= nil end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": then ZeD's reader opens on it (the game's displayPrintMedia hooked)", tostring(H.readerUp() and H.readerUp().mode))
        H.readerShut()
    end)
    H.wait(3000, function() return T.off or H.jrZone("full") ~= nil end, function(ok)
        if T.off then return end
        Q.check(ok and H.jrZone("read") == nil, T.L .. ": the quick look turns to a read piece (Open full, no Read)", H.list(H.jrIds()))
        H.jrPress("back", T.L)
    end)
    -- in the dark: Read greyed, Too dark
    H.step(3, function()
        if T.off then return end
        H.jrPress("paper:" .. T.idU2, T.L)
        H.tod(0)
    end)
    H.wait(5000, function() return T.off or H.dark() end, function(ok) if not T.off then T.darkOk = ok end end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        if T.darkOk then
            local z = H.jrZone("read")
            Q.check(z ~= nil and z.fn == nil and H.drewI(H.tr("UI_ZeD_Papers_TooDark")) ~= nil, T.L .. ": in the dark Read is greyed and the line says too dark", tostring(z and (z.fn and "live" or "grey")))
        else Q.skip(T.L .. ": Read in the dark", "still light enough to read here at midnight (a lit square)") end
        H.tod(S.NOON)
        H.setTrait("ILLITERATE", true)
        S.back.illit = true
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        H.qstop()
        T.zr = H.jrZone("read")
        T.pressI = H.jrPress("read", T.L)
        T.qZ = H.qcount("ISReadABook")
        H.qstop()
        pcall(function() ISInventoryPaneContextMenu.onLiteratureItems({ T.fU2 }, S.pn) end)
        T.qG = H.qcount("ISReadABook")
        H.qstop()
        T.ill = H.hasTrait("ILLITERATE")
        H.setTrait("ILLITERATE", S.found.illit == true)
        S.back.illit = nil
        -- (run 1: the game's own filter let the illiterate read the flyer too, a flyer being a picture for him; the
        -- truth is the game's onLiteratureItems on the same piece, whatever it says)
        local pic = false
        pcall(function() pic = T.fU2:hasTag(ItemTag.PICTURE) or T.fU2:hasTag(ItemTag.PICTUREBOOK) end)
        Q.check(T.ill and (T.qZ > 0) == (T.qG > 0), T.L .. " (B4): an illiterate character reads a paper from the Papers page only where the game's own read filter lets him",
            "Read " .. tostring(T.zr and (T.zr.fn and "live" or "grey")) .. ", it queued " .. T.qZ .. " reads; the game's onLiteratureItems queued " .. T.qG .. " (picture tag " .. tostring(pic) .. ", the trait on " .. tostring(T.ill) .. ")")
        if T.qG > 0 then H.note(T.L .. " (B4): a flyer is one the game lets an illiterate read; the case the map fears (a newspaper) needs a real newspaper piece, not staged") end
        Q.skip(T.L .. ": asleep (the game refuses a read asleep)", "sleep is not staged in the sweep")
        Q.skip(T.L .. ": as a driver at speed", "a car must be driven")
    end)
    H.step(2, function() H.autoRevealBack() end)
    H.caseEnd(T.L)
end

function C.j33()
    local T = { L = "J33 a read piece" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.autoRevealOff()
        T.id = H.pickFlyer(2) or H.pickFlyer(1)
        if not T.id then T.off = true; Q.skip(T.L, "no flyer with places the game knows is left unread by him"); return end
        T.f = H.paper("Base.Flier", T.id)
        H.markRead(T.id)
        H.rescan()
    end)
    H.frontQ(T, 3)
    H.step(2, function() if not T.off then H.jrPress("paper:" .. T.id, T.L) end end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        T.n = H.places(T.id)
        local miss = {}
        for i = 1, T.n do if not H.jrZone("place:" .. i) then miss[#miss + 1] = i end end
        Q.check(H.drewI(H.tr("UI_ZeD_Reader_HeadPlaces")) ~= nil and #miss == 0, T.L .. ": the quick look lists its " .. T.n .. " places (PrintMediaDefinitions)", "missing " .. H.list(miss))
        T.q0 = H.qlen()
        T.pf = H.jrPress("full", T.L)
    end)
    H.wait(3000, function() return T.off or H.readerUp() ~= nil end, function(ok)
        if T.off then return end
        Q.check(T.pf and ok and H.qlen() == T.q0, T.L .. ": Open full opens ZeD's reader with no timed action", "queue " .. H.qkinds())
        H.readerShut()
    end)
    H.step(4, function()
        if T.off then return end
        local k = (T.n >= 2) and 2 or 1
        local loc = nil
        pcall(function() loc = PrintMediaDefinitions.MiscDetails[T.id]["location" .. k] end)
        local real = WorldMapVisited
        local got = {}
        local rec = { setKnownInSquares = function(self, x1, y1, x2, y2) got[#got + 1] = x1 .. "," .. y1 .. "," .. x2 .. "," .. y2 end }
        WorldMapVisited = { getInstance = function() return rec end }
        local okP = pcall(function() T.pp = H.jrPress("place:" .. k, T.L) end)
        WorldMapVisited = real
        local q = H.qcount("ISReadWorldMap")
        H.qstop()
        local want = loc and #loc or -1
        Q.check(okP and T.pp and q == 1 and #got == want, T.L .. ": Show place " .. k .. " makes its squares known (recorded, not marked) and queues the game's ISReadWorldMap",
            #got .. " squares (the place has " .. want .. "), map reads queued " .. q)
        T.goW = H.padOn() and H.focusId("jr:words")
        local s = H.st()
        T.sp0 = s.scroll.scrollPos
        T.scrolls = (s.total or 0) > ((s.clip and s.clip.h) or 99999)
        if T.goW then H.dir("down") end
    end)
    H.step(5, function()
        if T.off then return end
        local s = H.st()
        if not T.goW then Q.skip(T.L .. " (pad): the D-pad on the words", "the words are no stop here: " .. H.stopIds(12))
        elseif not T.scrolls then Q.skip(T.L .. " (pad): the D-pad on the words", "the quick look fits without a scroll")
        else Q.check(s.scroll.scrollPos > T.sp0, T.L .. " (pad): the D-pad's Down on the words scrolls them", H.n2(T.sp0) .. " -> " .. H.n2(s.scroll.scrollPos)) end
    end)
    H.shot("jn_papers_" .. H.sizeTag(), "Papers: a read flyer's quick look, its places and its words", function() return not T.off end)
    H.step(2, function() if not T.off then T.goB = H.padOn() and H.focusId("jr:back") end end)
    H.tapB(function() return T.goB end)
    H.step(4, function()
        if T.off then return end
        Q.check(T.goB and H.st().paperOpen == nil, T.L .. " (pad): B in a quick look goes back to the list", "open " .. tostring(H.st().paperOpen))
        H.padOff()
        H.autoRevealBack()
    end)
    H.caseEnd(T.L)
end

function C.j34()
    local T = { L = "J34 changes under it" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.autoRevealOff()
        T.id = H.pickFlyer(1)
        if not T.id then T.off = true; Q.skip(T.L, "no flyer the game knows is left unread by him"); return end
        T.f = H.paper("Base.Flier", T.id)
        H.rescan()
    end)
    H.frontQ(T, 3)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        Q.check(H.drewIn(H.jrZone("paper:" .. T.id), H.tr("UI_ZeD_Read_Unread")), T.L .. ": the flyer's row reads Unread", H.list(H.paperIds()))
        pcall(function() ISInventoryPaneContextMenu.readItem(T.f, S.pn) end)
        H.speed(2)
    end)
    H.wait(30000, function() return T.off or H.isRead(T.id) end, function(ok)
        H.speed(1)
        if T.off then return end
        T.t1 = getTimestampMs()
        if ok then S.readAdded[#S.readAdded + 1] = T.id else T.off = true; Q.check(false, T.L .. ": the game's own read marks it read", H.qkinds()) end
    end)
    H.wait(3000, function() return T.off or H.drewIn(H.jrZone("paper:" .. T.id), H.tr("UI_ZeD_Papers_StateRead")) end, function(ok)
        if T.off then return end
        local ms = getTimestampMs() - (T.t1 or 0)
        Q.check(ok and ms <= 1500, T.L .. ": read by the game with the tab open, the row turns Read within about half a second", ms .. " ms")
        H.readerShut()
        H.jrPress("paper:" .. T.id, T.L)
    end)
    H.step(4, function()
        if T.off then return end
        T.open = H.st().paperOpen
        H.removeItem(T.f)
        T.t2 = getTimestampMs()
    end)
    H.wait(3000, function() return T.off or H.st().paperOpen == nil end, function(ok)
        if T.off then return end
        Q.check(T.open == T.id and ok, T.L .. ": the open piece taken away, the quick look goes back to the list", (getTimestampMs() - (T.t2 or 0)) .. " ms")
        H.autoRevealBack()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== Recipes (J35-J37)
function H.rst() local w = RT.cw(); return w and w._jrecipeState or nil end
function H.rdata() local w = RT.cw(); return w and w._jrecipeCache or nil end
function H.rzone(ty, id)
    local st = H.rst()
    for _, z in ipairs((st and st.zones) or {}) do if z.type == ty and (id == nil or tostring(z.id) == tostring(id)) then return z end end
    return nil
end
function H.seeUnknown() local v = nil; pcall(function() v = getSandboxOptions():getOptionByName("SeeNotLearntRecipe"):getValue() end); return v end
function H.setSeeUnknown(v) pcall(function() getSandboxOptions():getOptionByName("SeeNotLearntRecipe"):setValue(v) end) end
-- the game's own verdict on one recipe for him: { learned, skills, status }
function H.rTruth(recipe, needLearn)
    local learned, skills = true, true
    if needLearn then learned = false; pcall(function() learned = S.p:isRecipeKnown(recipe, true) and true or false end) end
    pcall(function() skills = recipe:characterHasRequiredSkills(S.p) and true or false end)
    return learned, skills, (learned and skills) and "unlocked" or "locked"
end
function H.rowsWait(T)
    H.wait(15000, function() local d = H.rdata(); return T.off or (H.onPage(4) and d ~= nil and #(d.recipes or {}) > 0) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the Recipes page gathers its rows", tostring(H.rdata() and #(H.rdata().recipes or {}))) then T.off = true end
    end)
end
function C.j35status(T)
    H.step(1, function()
        if T.off then return end
        local d = H.rdata()
        local bad, n = {}, 0
        for _, rd in ipairs(d.recipes or {}) do
            local e = rd.entry
            if e and e.recipe then
                n = n + 1
                local _, _, want = H.rTruth(e.recipe, e.needLearn)
                -- (run 1: the ingredients scan turns an unlocked row into "craftable" or "missing" (CraftingCore's
                -- backgroundIngredientScan); locked is the only verdict the game's rule makes)
                if (rd.status == "locked") ~= (want == "locked") and #bad < 6 then bad[#bad + 1] = tostring(e.name) .. " " .. tostring(rd.status) .. " (the game: " .. want .. ")" end
            end
        end
        Q.check(n > 0 and #bad == 0, T.L .. ": each row is unlocked or locked as the game says (isRecipeKnown, characterHasRequiredSkills)", n .. " rows; " .. H.list(bad))
        -- what the game would list: the craft recipes it does not hide (a needToBeLearn recipe he does not know is hidden
        -- unless SeeNotLearntRecipe); those with an OnAddToMenu test are left out of this count
        local listed = {}
        for _, rd in ipairs(d.recipes or {}) do if rd.entry and rd.entry.source == "craft" then listed[tostring(rd.entry.name)] = true end end
        local see = H.seeUnknown() == true
        local missing, extra, skipped = {}, {}, 0
        pcall(function()
            local all = ScriptManager.instance:getAllCraftRecipes()
            for i = 0, all:size() - 1 do
                local r = all:get(i)
                local name = tostring(r:getName())
                local onAdd = nil
                pcall(function() onAdd = r:getOnAddToMenu() end)
                if onAdd and onAdd ~= "" then skipped = skipped + 1
                else
                    local need = false
                    pcall(function() need = r:needToBeLearn() and true or false end)
                    local known = false
                    pcall(function() known = S.p:isRecipeActuallyKnown(r) and true or false end)
                    local vis = (not need) or known or see
                    if vis and not listed[name] and #missing < 5 then missing[#missing + 1] = name end
                    if (not vis) and listed[name] and #extra < 5 then extra[#extra + 1] = name end
                end
            end
        end)
        Q.check(#missing == 0 and #extra == 0, T.L .. ": the craft rows are the ones the game would list for him", "missing " .. H.list(missing) .. "; listed though hidden " .. H.list(extra) .. "; " .. skipped .. " with an OnAddToMenu test not counted")
    end)
end
function C.j35()
    local T = { L = "J35 Recipes" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local st = H.rst()
        T.st0 = st and { sort = st.sort, show = st.show, showAll = st.showAll, search = st.search, selected = st.selected } or nil
    end)
    H.frontQ(T, 4)
    H.rowsWait(T)
    C.j35status(T)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local z = H.rzone("recipeRow")
        T.pick = z and tostring(z.id)
        if not z then Q.check(false, T.L .. ": the list draws its rows", "no recipeRow zone"); return end
        H.press(z)
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off or not T.pick then return end
        local st = H.rst()
        Q.check(st.selected ~= nil and tostring(st.selected) == T.pick, T.L .. " (mouse): a press on a row picks it (its card)", tostring(st.selected) .. ", want " .. T.pick)
        local z = H.rzone("action_open")
        T.open = z
        T.ww0 = RT.ww() and RT.ww()._activeTab
        if z then H.press(z) else Q.check(false, T.L .. ": the picked recipe's band has Open in Craft or Build", "no action_open zone") end
    end)
    H.wait(3000, function() local ww = RT.ww(); return T.off or not T.open or (ww ~= nil and (ww._activeTab == "craft" or ww._activeTab == "build")) end, function(ok)
        if T.off or not T.open then return end
        local ww = RT.ww()
        Q.check(ok, T.L .. ": Open in Craft or Build opens the World window's tab (RecipeIndex.open, the game's OpenHandcraftWindow / OpenBuildWindow routed)", "World tab " .. tostring(ww and ww._activeTab))
        if T.ww0 then RT.worldTab(T.ww0) end
        H.front(4)
    end)
    -- Sort Name
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local st = H.rst()
        st.selected = nil
        local z = H.rzone("sortMenu")
        if not z then T.noSort = true; Q.skip(T.L .. ": Sort Name", "no Sort box drawn"); return end
        H.press(z)
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off or T.noSort then return end
        local st = H.rst()
        local row = nil
        for _, z in ipairs(st._sortMenuZones or {}) do if tostring(z.id) == "name" then row = z end end
        if row then H.press(row) else Q.check(false, T.L .. ": the Sort list offers Name", "rows " .. #(st._sortMenuZones or {})) end
    end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off or T.noSort then return end
        local st = H.rst()
        -- (run 1 compared lower case; CraftingCore orders by its key (pins first), then displayName as written, CC:1440-1470)
        local inv, prev, pk, ex = 0, nil, nil, {}
        for _, rd in ipairs(st.filteredCache or {}) do
            local n = tostring(rd.entry and rd.entry.displayName or "")
            local k = rd._sortKey
            if prev and k == pk and n < prev then inv = inv + 1; if #ex < 3 then ex[#ex + 1] = prev .. " > " .. n end end
            prev, pk = n, k
        end
        Q.check(st.sort == "name" and inv == 0, T.L .. " (mouse): Sort Name orders the rows by name", "sort " .. tostring(st.sort) .. ", " .. inv .. " out of order in " .. #(st.filteredCache or {}) .. (#ex > 0 and (": " .. H.list(ex)) or ""))
        local z = H.rzone("showMenu")
        T.noShow = z == nil
        if z then H.press(z) else Q.skip(T.L .. ": Show Known", "no Show box drawn") end
    end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off or T.noShow then return end
        local st = H.rst()
        local row = nil
        for _, z in ipairs(st._showMenuZones or {}) do if tostring(z.id) == "known" then row = z end end
        if row then H.press(row) else Q.check(false, T.L .. ": the Show list offers Known", "rows " .. #(st._showMenuZones or {})) end
    end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off or T.noShow then return end
        local st = H.rst()
        local notKnown = 0
        for _, rd in ipairs(st.filteredCache or {}) do
            local e = rd.entry
            if e and e.recipe then local l = H.rTruth(e.recipe, e.needLearn); if not l then notKnown = notKnown + 1 end end
        end
        Q.check(st.showAll == false and notKnown == 0, T.L .. " (mouse): Show Known keeps only recipes he knows (the game's isRecipeKnown)", "showAll " .. tostring(st.showAll) .. ", " .. notKnown .. " not known of " .. #(st.filteredCache or {}))
        -- a search
        local first = st.filteredCache and st.filteredCache[1]
        local nm = first and first.entry and string.lower(tostring(first.entry.displayName)) or "plank"
        T.word = string.match(nm, "%a%a%a%a+") or "plank"
        pcall(function() RT.cw()._jrecipeSearch.input:setText(T.word) end)
    end)
    H.wait(3000, function() local st = H.rst(); return T.off or (st and st.search == T.word) end, function() end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off then return end
        local st = H.rst()
        local n, named = 0, 0
        for _, rd in ipairs(st.filteredCache or {}) do
            n = n + 1
            if H.has(string.lower(tostring(rd.entry and rd.entry.displayName or "")), T.word) then named = named + 1 end
        end
        Q.check(st.search == T.word and n > 0, T.L .. ": a search (\"" .. tostring(T.word) .. "\") keeps rows", n .. " rows, " .. named .. " with the word in the name")
        if named < n then H.note(T.L .. ": " .. (n - named) .. " rows kept by the search do not hold the word in their name (CraftingCore searches more than the name)") end
        pcall(function() RT.cw()._jrecipeSearch.input:setText("") end)
        Q.skip(T.L .. ": a category", "the Category list is CraftingCore's (the Crafting sweep's)")
        -- B11: the catalog is built once per Lua session
        local nCraft = 0
        pcall(function() nCraft = ScriptManager.instance:getAllCraftRecipes():size() end)
        H.note(T.L .. " (B11): the catalog was built once this Lua session with the first character's BuildLogic; the game now has " .. nCraft
            .. " craft recipes; a recipe a mod adds later is not seen until a Lua reload (not staged)")
    end)
    H.step(2, function()
        local st = H.rst()
        if st and T.st0 then
            st.sort, st.show, st.showAll, st.search, st.selected = T.st0.sort, T.st0.show, T.st0.showAll, T.st0.search or "", T.st0.selected
            st.filterDirty = true
            st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen = false, false, false
        end
    end)
    H.caseEnd(T.L)
end

function C.j36()
    local T = { L = "J36 a recipe learned with the page open" }
    H.step(2, function() if not H.caseStart(T) then return end end)
    H.frontQ(T, 4)
    H.rowsWait(T)
    H.step(1, function()
        if T.off then return end
        for _, rd in ipairs(H.rdata().recipes or {}) do
            local e = rd.entry
            if not T.name and e and e.recipe and e.needLearn and e.source == "craft" and rd.status == "locked" then
                local learned, skills = H.rTruth(e.recipe, true)
                if not learned and skills then T.name = tostring(e.name); T.recipe = e.recipe end
            end
        end
        if not T.name then T.off = true; Q.skip(T.L, "no recipe he could use but has not learned is listed (SeeNotLearntRecipe off hides them)"); return end
        S.back.recipe = { name = T.name, was = false }
        pcall(function() S.p:learnRecipe(T.name) end)
        T.t0 = getTimestampMs()
    end)
    H.wait(3000, function()
        if T.off then return true end
        for _, rd in ipairs((H.rdata() or {}).recipes or {}) do if rd.entry and tostring(rd.entry.name) == T.name and rd.status ~= "locked" then return true end end
        return false
    end, function(ok)
        if T.off then return end
        local known = H.rTruth(T.recipe, true)
        Q.check(known and ok and getTimestampMs() - T.t0 <= 1500, T.L .. ": learned (the game's learnRecipe, as a magazine teaches), its row turns unlocked within the page's 500 ms",
            T.name .. ": known " .. tostring(known) .. ", " .. (getTimestampMs() - T.t0) .. " ms")
        pcall(function() S.p:getKnownRecipes():remove(T.name) end)
        S.back.recipe = nil
    end)
    H.caseEnd(T.L)
end

function C.j37()
    local T = { L = "J37 SeeNotLearntRecipe" }
    H.step(2, function() if not H.caseStart(T) then return end end)
    H.frontQ(T, 4)
    H.rowsWait(T)
    local function count()
        local n = 0
        for _, rd in ipairs((H.rdata() or {}).recipes or {}) do
            local e = rd.entry
            if e and e.recipe and e.needLearn then local l = H.rTruth(e.recipe, true); if not l then n = n + 1 end end
        end
        return n
    end
    for _, v in ipairs({ false, true }) do
        H.step(1, function() if not T.off then H.setSeeUnknown(v); S.back.see = true end end)
        H.step(70, function() end)
        H.drawn(T, 3)
        H.step(1, function()
            if T.off then return end
            local n = count()
            if v then Q.check(n > 0, T.L .. ": SeeNotLearntRecipe on: recipes he has not learned are listed", n .. " listed")
            else Q.check(n == 0, T.L .. ": SeeNotLearntRecipe off: recipes he has not learned are hidden", n .. " listed") end
        end)
    end
    H.step(1, function()
        H.setSeeUnknown(S.found.seeUnknown)
        S.back.see = nil
        H.note(T.L .. ": MetaKnowledge is read by no ZeD file (the game's Literature window marks unknown rows ???): not staged")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== what the tab does not hold (J38, J39)
function C.j38()
    local T = { L = "J38 recorded media" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.items = {}
        for _, ft in ipairs({ "Base.VHS_Home", "Base.VHS_Retail", "Base.Disc_Retail" }) do
            local it = H.known(ft) and H.give(ft) or nil
            if it then T.items[#T.items + 1] = it end
        end
        if #T.items == 0 then T.off = true; Q.skip(T.L, "no tape or disc type found here"); return end
        H.rescan()
    end)
    for _, page in ipairs({ 2, 3 }) do
        H.frontQ(T, page)
        H.drawn(T, 3)
        H.step(1, function()
            if T.off then return end
            local c = H.st().carried or {}
            local shown = {}
            for _, it in ipairs(T.items) do
                local name = ""
                pcall(function() name = it:getDisplayName() end)
                local inLists = false
                for _, e in ipairs(c.books or {}) do if e == it then inLists = true end end
                for _, e in ipairs(c.papers or {}) do if type(e) == "table" and e.item == it then inLists = true end end
                if inLists or H.drewExact(name) then shown[#shown + 1] = name end
            end
            Q.check(#shown == 0, T.L .. ": on page " .. page .. " no tape or disc carried is listed (a gap the map records)", H.list(shown))
        end)
    end
    H.step(1, function()
        if T.off then return end
        H.note(T.L .. ": recorded media heard are the game's Literature window's (safe mode only); watching and listening are not staged")
    end)
    H.caseEnd(T.L)
end

function C.j39()
    local T = { L = "J39 skill books with a notebook carried" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA beside skill books")
        T.books = {}
        for _, ft in ipairs({ "Base.BookCarpentry1", "Base.BookMechanic1", "Base.BookCooking1" }) do
            local it = H.known(ft) and H.give(ft) or nil
            if it then T.books[#T.books + 1] = it end
        end
        H.rescan()
    end)
    H.frontQ(T, 2)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local shown = {}
        for _, it in ipairs(T.books) do
            local name = ""
            pcall(function() name = it:getDisplayName() end)
            if H.drewI(name) then shown[#shown + 1] = name end
        end
        Q.check(#T.books > 0 and #shown == 0, T.L .. ": with a notebook carried no skill book is listed on Notebooks (a gap the map records)", #T.books .. " given; drawn " .. H.list(shown))
        H.note(T.L .. ": the Skills tab lists skill books read, reading, collected (the Skills map's)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== the pad's tours (J40-J42)
S.KINDS = { "the header", "the kills head", "the write box", "the tag picks", "Into", "the log (months, tags, crosses)", "Save" }
function H.kindOf(id)
    id = tostring(id or "")
    if string.sub(id, 1, 5) == "jtab:" or id == "journal:__find" then return 1 end
    if id == "journal:__kills" then return 2 end
    if id == "journal:__write" then return 3 end
    if string.sub(id, 1, 16) == "journal:tagpick:" then return 4 end
    if id == "jr:into" then return 5 end
    if string.sub(id, 1, 14) == "journal:group:" or string.sub(id, 1, 12) == "journal:tag:" or string.sub(id, 1, 12) == "journal:del:" then return 6 end
    if id == "journal:__save" then return 7 end
    return 0
end
-- the live zone of a Log stop, by its id
function H.zoneOfId(id)
    id = tostring(id or "")
    local n = string.match(id, "^journal:del:(%d+)$")
    if n then return H.delZone(tonumber(n)) end
    local key = string.match(id, "^journal:group:(.+)$")
    if key then return H.groupZone(key) end
    local i, k = string.match(id, "^journal:tag:(%d+):(%a+)$")
    if i then return H.tagZone(tonumber(i), k) end
    return nil
end
function H.inView(z)
    local v = RT.cw() and RT.cw()._journalView
    if not (v and z) then return true end
    return z.y >= v.y - 1 and z.y + z.h <= v.y + v.h + 1
end
-- queue: the D-pad pressed dir every 4 frames until stop(id) or the same stop 3 times or max presses; W gathers
function H.walk(T, W, dir, max, stopAt, each)
    H.step(1, function() W.n, W.k, W.same, W.last, W.ids = 0, 0, 0, nil, {} end)
    H.wait(120000, function()
        if T.off or not T.go then return true end
        W.k = W.k + 1
        if W.k < 4 then return false end
        W.k = 0
        local id = H.focId()
        if #W.ids < 400 then W.ids[#W.ids + 1] = tostring(id) end
        if each then each(id) end
        if stopAt(id) then W.done = true; return true end
        if id == W.last then W.same = W.same + 1 else W.same = 0 end
        W.last = id
        if W.same >= 3 or W.n >= max then return true end
        W.n = W.n + 1
        H.dir(dir)
        return false
    end, function() end)
end
function H.fold(list)
    local out, last, n = {}, nil, 0
    for _, kd in ipairs(list) do
        if kd == last then n = n + 1 else if last then out[#out + 1] = last .. (n > 1 and (" x" .. n) or "") end; last, n = kd, 1 end
    end
    if last then out[#out + 1] = last .. (n > 1 and (" x" .. n) or "") end
    return table.concat(out, ", ")
end
function C.j40()
    local T = { L = "J40 the pad's tour of the Log" }
    local W = {}
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.e1 = H.entAdd({ text = "ZQA tour one zqtour", tags = { "food" } })
        T.e2 = H.entAdd({ text = "ZQA tour two zqtour", tags = { "base" } })
        T.nb = H.book("Base.Notebook", "ZQA tour book")
        H.rescan()
    end)
    H.frontQ(T, 1)
    H.step(2, function()
        if T.off then return end
        T.go = H.padOn() and H.focusId("jtab:1")
        if not Q.check(T.go, T.L .. ": the pad's focus lands on the Log's page tab", "focus " .. tostring(H.focId()) .. "; stops " .. H.stopIds()) then return end
    end)
    H.walk(T, W, "down", 80, function(id) return id == "journal:__save" end)
    H.step(1, function()
        if T.off or not T.go then return end
        local seen, seq, ok, last = {}, {}, true, 0
        for _, id in ipairs(W.ids) do
            local k = H.kindOf(id)
            seen[k] = true
            seq[#seq + 1] = S.KINDS[k] or ("other " .. id)
            if k < last or k == 0 then ok = false end
            last = k
        end
        local miss = {}
        for k = 1, 7 do if not seen[k] then miss[#miss + 1] = S.KINDS[k] end end
        Q.check(W.done and #miss == 0, T.L .. ": Down from the page tab reaches the kills head, the write box, the picks, Into, the log and Save", H.fold(seq) .. (#miss > 0 and ("; never reached: " .. H.list(miss)) or "") .. "; the stops walked: " .. H.list(W.ids, 14))
        Q.check(ok, T.L .. ": the walk keeps the map's order (header, kills, write, picks, Into, the log, Save)", H.fold(seq))
        T.goW = H.focusId("journal:__write")
    end)
    H.tapA(function() return T.go and T.goW end)
    H.step(5, function()
        if T.off or not T.go then return end
        Q.check(T.goW and H.kbUp(), T.L .. ": A on the write box opens the pad keyboard", tostring(H.kbUp()))
        H.kbHide()
        T.goF = H.focusId("journal:__find")
    end)
    H.tapA(function() return T.go and T.goF end)
    H.step(5, function()
        if T.off or not T.go then return end
        Q.check(T.goF and H.kbUp(), T.L .. ": A on the search opens the pad keyboard", tostring(H.kbUp()))
        H.kbHide()
        T.into0 = H.intoId()
        T.goI = H.focusId("jr:into")
    end)
    H.tapA(function() return T.go and T.goI end)
    H.step(5, function()
        if T.off or not T.go then return end
        Q.check(T.goI and H.intoId() ~= T.into0, T.L .. ": A on Into steps it", tostring(T.into0) .. " -> " .. tostring(H.intoId()))
        local wr, g = H.wrapOf(T.e1)
        T.gk = g and g.key
        T.goG = T.gk and H.focusId("journal:group:" .. T.gk)
    end)
    H.tapA(function() return T.go and T.goG end)
    H.step(5, function()
        if T.off or not T.go then return end
        Q.check(T.goG and RT.cw()._journalGroupCollapsed[T.gk] == true, T.L .. ": A on a month head folds it", tostring(T.gk))
        RT.cw()._journalGroupCollapsed[T.gk or "?"] = nil
    end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off or not T.go then return end
        T.goD = H.focusId("journal:del:" .. tostring(H.idxOf(T.e2)))
    end)
    H.tapA(function() return T.go and T.goD end)
    H.step(5, function() if not T.off and T.go then T.askUp = RT.cw()._journalAsk ~= nil end end)
    H.tapB(function() return T.go and T.goD end)
    H.step(5, function()
        if T.off or not T.go then return end
        Q.check(T.goD and T.askUp and RT.cw()._journalAsk == nil and H.idxOf(T.e2) ~= nil, T.L .. ": A on a cross asks; B cancels and keeps the entry", "asked " .. tostring(T.askUp))
        -- J43: B on a Log stop with nothing running does nothing
        H.qstop()
        T.goK = H.focusId("journal:__kills")
    end)
    H.tapB(function() return T.go and T.goK end)
    H.step(5, function()
        if T.off or not T.go then return end
        local w = RT.cw()
        Q.check(T.goK and RT.isOpen() and w._activeTab == "journal" and (w._journalSubTab or 1) == 1 and H.qlen() == 0, T.L .. " (J43): B on a Log stop with nothing running does nothing",
            "open " .. tostring(RT.isOpen()) .. ", tab " .. tostring(w and w._activeTab) .. ", focus " .. tostring(H.focId()))
        H.padOff()
    end)
    H.caseEnd(T.L)
end

function C.j41()
    local T = { L = "J41 a long log" }
    local W, U = {}, {}
    H.step(2, function()
        if not H.caseStart(T) then return end
        for i = 1, 80 do
            local tags = (i - math.floor(i / 2) * 2 == 0) and { "food" } or { "base", "travel" }
            H.entAdd({ text = "ZQA long " .. i .. " zqlong", year = 1978, month = math.floor((i - 1) / 14), day = i - math.floor((i - 1) / 14) * 14, tags = tags }, 1)
        end
    end)
    H.frontQ(T, 1)
    H.step(2, function() if not T.off then pcall(function() RT.cw()._journalSearch.input:setText("zqlong") end) end end)
    H.wait(2000, function() return T.off or RT.cw()._journalSearchText == "zqlong" end, function() end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off then return end
        T.go = H.padOn()
        if not T.go then Q.skip(T.L, "ZeD's input mode cannot be locked to the controller"); return end
        T.jf0, T.t0 = S.jf, getTimestampMs()
    end)
    H.step(60, function()
        if T.off or not T.go then return end
        local ms = getTimestampMs() - T.t0
        local frames = S.jf - T.jf0
        H.note(T.L .. ": with 80 entries open, " .. frames .. " frames in " .. ms .. " ms (" .. H.n2(frames > 0 and ms / frames or 0) .. " ms a frame)")
        local v = RT.cw()._journalView
        local far = 0
        for _, e in ipairs(H.stops()) do
            local id = tostring(e.id)
            if (string.sub(id, 1, 12) == "journal:tag:" or string.sub(id, 1, 12) == "journal:del:") and v and (e.y > v.y + v.h * 2 or e.y + e.h < v.y - v.h) then far = far + 1 end
        end
        Q.check(far == 0, T.L .. ": tags and crosses more than a view's height away are no stops", far .. " far stops of " .. #H.stops())
        -- the last cross: the last month's last entry
        local groups = nil
        pcall(function() groups = S.JT.groups(RT.cw(), H.ents(), "zqlong") end)
        local g = groups and groups[#groups]
        local last = g and g.entries[#g.entries]
        T.lastId = last and ("journal:del:" .. tostring(last.idx)) or "?"
        T.out = {}
        T.go = H.focusId("journal:__write")
    end)
    H.walk(T, W, "down", 300, function(id) return id == T.lastId or id == "journal:__save" end, function(id)
        if H.kindOf(id) == 6 then
            local z = H.zoneOfId(id)
            if z and not H.inView(z) and #T.out < 6 then T.out[#T.out + 1] = tostring(id) end
        end
    end)
    H.step(1, function()
        if T.off or not T.go then return end
        local reached = false
        for _, id in ipairs(W.ids) do if id == T.lastId then reached = true end end
        Q.check(reached, T.L .. ": Down walks to the last entry's cross (" .. T.lastId .. ")", W.n .. " presses: " .. H.list(W.ids, 12) .. "; " .. #H.stops() .. " stops now")
        Q.check(#T.out == 0, T.L .. ": the view follows the focus down the log", "out of view: " .. H.list(T.out))
    end)
    H.walk(T, U, "up", 300, function(id) return H.kindOf(id) == 1 end)
    H.step(1, function()
        if T.off or not T.go then return end
        Q.check(U.done == true, T.L .. ": Up walks back to the page tabs", U.n .. " presses; last focus " .. tostring(U.ids[#U.ids]))
        H.padOff()
    end)
    H.caseEnd(T.L)
end

function C.j42()
    local T = { L = "J42 the pad's tour of Notebooks and Papers" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA pad book")
        H.setPage(T.nb, 1, "zq42 page")
        T.pen = H.give("Base.Pencil")
        T.id1 = H.pickFlyer(1) or "zqa_pad_a"
        T.id2 = H.pickFlyer(1, { [T.id1] = true }) or "zqa_pad_b"
        H.paper("Base.Flier", T.id1)
        H.paper("Base.Flier", T.id2)
        H.markRead(T.id2)
        H.rescan()
    end)
    H.frontQ(T, 2)
    H.step(2, function() if not T.off then T.go = H.padOn() end end)
    H.step(10, function()
        if T.off or not T.go then return end
        local shown = false
        pcall(function() shown = RT.cw()._jrNote:isVisible() end)
        -- (run 1 wanted jr:prev: on page 1 of the book < is greyed and a greyed button is no stop, JR:924, JR:1170)
        local need = { "jr:book:" .. tostring(H.id(T.nb)), "jr:next", "jr:full", "jr:write" }
        local miss = {}
        for _, id in ipairs(need) do if not H.stopHas(id) then miss[#miss + 1] = id end end
        if H.stopHas("jr:prev") then miss[#miss + 1] = "jr:prev is a stop though greyed" end
        Q.check(#miss == 0 and ((H.stopHas("jr:note") ~= nil) == shown), T.L .. ": Notebooks' stops: the book, > (< greyed on page 1, no stop), Open full, Write, and the note only while it shows whole",
            "missing " .. H.list(miss) .. "; note shown " .. tostring(shown) .. ", a stop " .. tostring(H.stopHas("jr:note") ~= nil) .. "; " .. H.stopIds(16))
        if S.found.toolsKept == 0 then H.removeItem(T.pen); H.rescan() else T.penKept = true end
    end)
    H.step(10, function()
        if T.off or not T.go then return end
        if T.penKept then Q.skip(T.L .. ": no stop on a hidden note", "a writing tool of his stays worn or held")
        else
            local shown = false
            pcall(function() shown = RT.cw()._jrNote:isVisible() end)
            Q.check(not shown and H.stopHas("jr:note") == nil, T.L .. ": the note hidden (no pencil), it is no stop", "shown " .. tostring(shown) .. "; " .. H.stopIds(16))
        end
        H.front(3)
    end)
    H.step(10, function() if not T.off and T.go then T.goS = H.focusId("jr:show") end end)
    H.tapA(function() return T.go and T.goS end)
    H.step(6, function()
        if T.off or not T.go then return end
        local rows = 0
        for _, e in ipairs(H.stops()) do if string.sub(tostring(e.id), 1, 11) == "jr:showRow:" then rows = rows + 1 end end
        local onlyRows = rows > 0 and rows == #H.stops()
        Q.check(T.goS and S.JR.listOpen(RT.cw()) and onlyRows and H.focId() == "jr:showRow:" .. tostring(H.st().filter), T.L .. ": A on Show opens the list; its rows alone hold the pad, the focus on the current one",
            "focus " .. tostring(H.focId()) .. "; " .. H.stopIds(10))
    end)
    H.tapB(function() return T.go and T.goS end)
    H.step(6, function()
        if T.off or not T.go then return end
        Q.check(not S.JR.listOpen(RT.cw()) and H.focId() == "jr:show", T.L .. ": B shuts the list, the focus back on Show", "focus " .. tostring(H.focId()))
        T.goP = H.focusId("jr:paper:" .. T.id2)
    end)
    H.tapA(function() return T.go and T.goP end)
    H.step(6, function()
        if T.off or not T.go then return end
        local s = H.st()
        Q.check(T.goP and s.paperOpen == T.id2 and H.stopHas("jr:back") ~= nil, T.L .. ": A on a paper's row opens its quick look (Back a stop)", "open " .. tostring(s.paperOpen) .. "; " .. H.stopIds(10))
        T.goB = H.focusId("jr:back")
    end)
    H.tapB(function() return T.go and T.goB end)
    H.step(6, function()
        if T.off or not T.go then return end
        Q.check(H.st().paperOpen == nil, T.L .. ": B in the quick look goes back to the list", tostring(H.st().paperOpen))
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J44 an item card over the Log
function C.j44()
    local T = { L = "J44 an item card over the Log" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.it = H.give("Base.Pencil")
    end)
    H.frontQ(T, 1)
    H.step(2, function()
        if T.off then return end
        local w = RT.cw()
        local c = w._mainContent
        T.c = c
        local z = nil
        for _, hz in ipairs((c and c._hitZones) or {}) do if hz.id == T.it then z = hz end end
        if z then
            H.zcall(function() local x, y = H.mid(z); c:onMouseDown(x, y); c:onMouseUp(x, y) end)
        else
            H.note(T.L .. ": the pencil's row is not drawn in the list now: picked through the list's selection and the window's own drawer update")
            H.zcall(function() c._selectedItems = { [T.it] = true }; w._updateDrawer(c) end)
        end
    end)
    H.wait(3000, function() return T.off or RT.cw()._drawerItem == T.it end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the pencil's item card opens over the tab", tostring(RT.cw()._drawerItem)) then T.off = true end
    end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off then return end
        local w = RT.cw()
        local card = w._itemCard
        local cx = nil
        pcall(function() cx = card:getAbsoluteX() end)
        local function right(el) local r = nil; pcall(function() if el:isVisible() then r = el:getAbsoluteX() + el:getWidth() end end); return r end
        local inR, svR = right(w._journalInput), right(w._journalSaveBtn)
        Q.check(cx ~= nil and (inR == nil or inR <= cx + 1), T.L .. ": the write box hides or ends where the card starts", "box right " .. tostring(inR) .. ", card left " .. tostring(cx))
        Q.check(cx ~= nil and svR ~= nil and svR <= cx + 1, T.L .. ": Save shows in the part the card leaves", "Save right " .. tostring(svR) .. ", card left " .. tostring(cx))
        T.n0 = H.entN()
        H.type("ZQA under a card zq44")
        T.pr = H.saveClick()
    end)
    H.step(3, function()
        if T.off then return end
        local e = (H.ents() or {})[1]
        Q.check(T.pr and e ~= nil and e.text == "ZQA under a card zq44", T.L .. ": Save still saves with the card open", tostring(e and e.text))
        local w = RT.cw()
        H.zcall(function() T.c._selectedItems = {}; w._updateDrawer(T.c) end)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== J45 the half card
function C.j45pass(T, tag, shots)
    H.halfOn(T)
    H.step(1, function()
        if T.off then return end
        if T.noPass then T.pass = false; return end
        local w, h = H.screen()
        if not T.half then
            if w == 1280 and h == 800 then Q.check(false, T.L .. " (" .. tag .. "): the drawer holds the half card at 1280x800", H.drawerW() .. " px")
            else H.note(T.L .. " (" .. tag .. "): the drawer could not be held in to the half card at " .. H.sizeTag() .. " (" .. H.drawerW() .. " px)") end
            T.pass = false
            return
        end
        T.pass = true
        H.front(1)
    end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off or not T.pass then return end
        local w = RT.cw()
        local v = w._journalView or { x = 0, w = 99999 }
        local outP, rows = {}, {}
        for _, z in ipairs(w._journalPickZones or {}) do
            if z.x + z.w > v.x + v.w + 1 then outP[#outP + 1] = z.k end
            rows[tostring(z.y)] = true
        end
        local nRows = 0
        for _ in pairs(rows) do nRows = nRows + 1 end
        Q.check(#outP == 0, T.L .. " (" .. tag .. "): the eight picks wrap inside the half card", nRows .. " rows; past the edge " .. H.list(outP))
        local wr = H.wrapOf(T.long)
        local stamp = wr and wr.stamp or ""
        Q.check(H.drewCut(stamp) ~= nil or H.drewExact(stamp) ~= nil, T.L .. " (" .. tag .. "): a long stamp is cut with \"...\" (or fits whole)", "stamp \"" .. stamp .. "\"")
        local iz = H.jrZone("into")
        local dw = H.drawerW()
        Q.check(iz ~= nil and iz.x + iz.w <= dw + 1, T.L .. " (" .. tag .. "): Into's label is held inside the card", iz and (math.floor(iz.x) .. "+" .. math.floor(iz.w) .. " of " .. dw) or "no Into")
    end)
    if shots then H.shot("jn_half_log_" .. H.sizeTag(), "the Log on the half card: the picks, a cut stamp, Into", function() return T.pass and not T.off end) end
    H.step(1, function()
        if T.off or not T.pass then return end
        H.front(2)
        local s = H.st()
        local id = H.id(T.nb)
        s.nbId = id
        s.nbPage[id] = H.pages(T.nb)
    end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off or not T.pass then return end
        local s = H.st()
        local pv, nx, fu = H.jrZone("prev"), H.jrZone("next"), H.jrZone("full")
        local c = s.clip or { x = 0, w = 99999 }
        local fits = pv and nx and fu and nx.x + nx.w <= fu.x and pv.x + pv.w <= nx.x and fu.x + fu.w <= c.x + c.w + 1
        Q.check(fits == true, T.L .. " (" .. tag .. "): the Notebooks page bar (<, Page 10 of 10, >, Open full) fits the half card without overlap",
            (pv and nx and fu) and ("< " .. math.floor(pv.x) .. "+" .. math.floor(pv.w) .. ", > " .. math.floor(nx.x) .. "+" .. math.floor(nx.w) .. ", Open full " .. math.floor(fu.x) .. "+" .. math.floor(fu.w)
            .. ", the view ends " .. math.floor(c.x + c.w)) or ("zones " .. H.list(H.jrIds())))
        RT.bounds(Q, T.L .. " (" .. tag .. "), Notebooks")
    end)
    if shots then H.shot("jn_half_notebook_" .. H.sizeTag(), "Notebooks on the half card: the page bar at Page 10 of 10", function() return T.pass and not T.off end) end
    H.step(2, function()
        if T.off or not T.pass then return end
        H.front(3)
    end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off or not T.pass then return end
        local c = H.st().clip or { x = 0, w = 99999 }
        local out = {}
        for _, id in ipairs(H.paperIds()) do local z = H.jrZone("paper:" .. id); if z and z.x + z.w > c.x + c.w + 1 then out[#out + 1] = id end end
        Q.check(#out == 0, T.L .. " (" .. tag .. "): the paper rows stay inside the half card", H.list(out))
        RT.bounds(Q, T.L .. " (" .. tag .. "), Papers")
        H.halfBack()
        H.front(1)
    end)
end
function C.j45()
    local T = { L = "J45 the half card" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.nb = H.book("Base.Notebook", "ZQA a notebook with a long name for the cut")
        for i = 1, H.pages(T.nb) do H.setPage(T.nb, i, "zq45 page " .. i) end
        T.long = H.entAdd({ text = "ZQA long stamp zq45", source = { name = "ZQA a notebook with a long name for the cut", page = 10 }, tags = { "danger", "loot" } })
        H.paper("Base.Flier", H.pickFlyer(1) or "zqa_half_a")
        H.paper("Base.Newspaper", "zqa_half_news")
        H.rescan()
    end)
    H.frontQ(T, 1)
    H.step(1, function() if not T.off then H.jrPress("into", T.L) end end)
    C.j45pass(T, tostring(S.found.size) .. " text", true)
    H.step(1, function()
        if T.off then return end
        T.big = S.found.size ~= "large"
        if T.big then H.sizeSet("large") else T.noPass = true; Q.skip(T.L .. ": Large text", "the run is already in Large text") end
    end)
    H.step(30, function() end)
    C.j45pass(T, "Large text", false)
    H.step(2, function()
        H.sizeBack()
        Q.skip(T.L .. ": UI scale 2 and 1280x720", "the runner sets the screen; the game's UI scale needs a restart")
    end)
    H.step(30, function() end)
    H.caseEnd(T.L)
end

-- ===================================================================== J46 the words, J47 themes
function C.j46()
    local T = { L = "J46 the words" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.e = H.entAdd({ text = "ZQA words zq46", year = 1979, month = 6 })
        T.nb = H.book("Base.Notebook", "ZQA words book")
        T.pen = H.give("Base.Pencil")
        H.rescan()
    end)
    H.frontQ(T, 1)
    H.step(2, function() if not T.off then RT.cw()._killsExpanded = true; pcall(S.JT.setSearch, RT.cw(), "zq46") end end)
    H.drawn(T, 3)
    H.step(1, function()
        if T.off then return end
        local lang = H.lang()
        local month = H.gt("Sandbox_StartMonth_option7")
        Q.check(H.drewI(month) ~= nil, T.L .. ": the month head uses the game's month name in " .. lang .. " (\"" .. month .. "\")", H.drewLike("1979", 3))
        local miss = {}
        for _, k in ipairs({ "IGUI_perks_Blunt", "IGUI_perks_SmallBlunt", "IGUI_perks_LongBlade", "IGUI_perks_SmallBlade", "IGUI_perks_Axe", "IGUI_perks_Spear", "IGUI_perks_Firearm" }) do
            if not H.drewI(H.gt(k)) then miss[#miss + 1] = H.gt(k) end
        end
        Q.check(#miss == 0, T.L .. ": the kills rows use the game's skill names", "not drawn " .. H.list(miss))
        RT.cw()._killsExpanded = false
        H.front(2)
        H.jrPress("book:" .. tostring(H.id(T.nb)), T.L)
    end)
    H.drawn(T, 4)
    H.step(1, function()
        if T.off then return end
        Q.check(H.drewOrCut(H.tr("UI_ZeD_Notebook_ReadyMany", 15)) ~= nil, T.L .. ": the Notebooks status line in " .. H.lang(), "\"" .. H.tr("UI_ZeD_Notebook_ReadyMany", 15) .. "\"")
        for _, L in ipairs({ "DE", "ES", "FR", "RU", "JP" }) do
            if L ~= H.lang() then Q.skip(T.L .. ": " .. L, "the run is in " .. H.lang() .. ": a game started in " .. L .. " is needed") end
        end
    end)
    H.caseEnd(T.L)
end

-- the WCAG contrast of two colors (each r, g, b in 0..1)
function H.lum(c)
    local function ch(v) if v <= 0.03928 then return v / 12.92 end; return ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b)
end
function H.contrast(a, b) local la, lb = H.lum(a), H.lum(b); if la < lb then la, lb = lb, la end; return (la + 0.05) / (lb + 0.05) end
function H.over(fg, bg) local a = fg.a or 1; return { r = fg.r * a + bg.r * (1 - a), g = fg.g * a + bg.g * (1 - a), b = fg.b * a + bg.b * (1 - a) } end
function C.j47()
    local T = { L = "J47 themes" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.idR = H.pickFlyer(1) or "zqa_theme_a"
        T.idU = H.pickFlyer(1, { [T.idR] = true }) or "zqa_theme_b"
        H.paper("Base.Flier", T.idR)
        H.paper("Base.Flier", T.idU)
        H.markRead(T.idR)
        H.rescan()
    end)
    H.frontQ(T, 3)
    for _, th in ipairs(S.THEMES) do
        H.step(2, function() if not T.off then H.theme(th.key) end end)
        H.step(30, function() end)
        H.drawn(T, 3)
        H.step(1, function()
            if T.off then return end
            local Tk = ZeD.T
            local world = (th.key == "light") and { r = 0, g = 0, b = 0 } or { r = 1, g = 1, b = 1 }
            local bg = H.over(Tk.surf1 or { r = 0, g = 0, b = 0 }, world)
            local hi, sc, tc = S.JR.paperTones(false, false)
            local cr = H.contrast(H.over(hi, bg), bg)
            Q.check(cr >= 4.5, T.L .. " (" .. th.say .. "): an unread paper row's words reach 4.5 : 1 by tone (over the window)", string.format("%.2f : 1", cr))
            local low = {}
            for _, lc in ipairs({ "red", "orange", "yellow", "green", "blue", "teal", "purple", "pink" }) do
                local c = Tk.labelsText and Tk.labelsText[lc]
                if not c then low[#low + 1] = lc .. " none"
                else local r = H.contrast(H.over(c, bg), bg); if r < 4.5 then low[#low + 1] = lc .. string.format(" %.2f", r) end end
            end
            Q.check(#low == 0, T.L .. " (" .. th.say .. "): the eight tag words' colors reach 4.5 : 1 on the window", H.list(low))
        end)
        H.shot("jn_theme_" .. th.key .. "_" .. H.sizeTag(), "Papers in " .. th.say .. ": a read and an unread flyer", function() return not T.off end)
    end
    H.step(2, function()
        H.themeBack()
        H.note(T.L .. ": the page's paper tone is ZeD.paperTone (Tokens: no large near-white areas); its look is the pictures'")
    end)
    H.step(30, function() end)
    H.caseEnd(T.L)
end

-- ===================================================================== J3 safe mode (run last of the cases)
function C.j3()
    local T = { L = "J3 safe mode" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local o = ZeD.Settings and ZeD.Settings.safeModeOption
        if not (o and ZeD.Safe and ZeD.Safe.reread and ZeD.Safe.on) then T.off = true; Q.skip(T.L, "no safe mode option here"); return end
        T.o = o
        T.nb = H.book("Base.Notebook", "ZQA safe mode")
        H.setPage(T.nb, 1, "zq safe page")
        T.pen = H.give("Base.Pencil")
        RT.pairShut()
        S.back.safe = true
        pcall(function() o:setValue(2) end)
        pcall(ZeD.Safe.reread)
    end)
    H.wait(3000, function() return T.off or ZeD.Safe.on() end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": safe mode holds (its option on)", tostring(ZeD.Safe.on())) then T.off = true end
    end)
    H.step(5, function() if not T.off then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn) end end)
    H.step(20, function()
        if T.off then return end
        Q.check(not RT.isOpen(), T.L .. ": the Character window does not open in safe mode (no Journal)", "open " .. tostring(RT.isOpen()))
        pcall(function() ISInventoryPaneContextMenu.onWriteSomething(T.nb, true, S.pn) end)
    end)
    H.wait(8000, function() return T.off or RT.find(function(t) return t.Type == "ISUIWriteJournal" end) ~= nil or H.readerUp() ~= nil end, function(ok)
        if T.off then return end
        local gw = RT.find(function(t) return t.Type == "ISUIWriteJournal" end)
        Q.check(gw ~= nil and H.readerUp() == nil, T.L .. ": Write note opens the game's journal window (ISUIWriteJournal), not ZeD's reader", "game window " .. tostring(gw ~= nil) .. ", ZeD reader " .. tostring(H.readerUp() ~= nil) .. ", queue " .. H.qkinds())
        if gw then pcall(function() gw:setVisible(false); gw:removeFromUIManager() end) end
        H.readerShut()
        H.qstop()
        Q.skip(T.L .. ": Inspect on a flyer opens the game's print window", "a read marks the piece for good and the game's print window has no close here")
        Q.skip(T.L .. ": the Info key opens the game's Info page with its Literature button", "the game's own window: not ZeD's to test")
    end)
    H.step(5, function()
        if T.o then pcall(function() T.o:setValue(S.found.safe) end) end
        pcall(ZeD.Safe.reread)
        S.back.safe = nil
    end)
    H.wait(4000, function() return not (ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on()) end, function(ok)
        Q.check(ok, T.L .. ": safe mode off again as found", tostring(ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on()))
    end)
    H.step(20, function() RT.pairOpen() end)
    H.step(20, function() RT.charTab("journal") end)
    H.caseEnd(T.L)
end

-- ===================================================================== what single player cannot stage
function C.skips()
    H.step(2, function()
        Q.skip("J49 a notebook locked by another player (the admin's write)", "multiplayer: the single-player half is J26")
        Q.skip("J50 B5 Into and the quick note on a server", "multiplayer: ZeD_WriteNoteAction is a client action with a complete(); a server is needed")
        Q.skip("J51 the log and kills after a reconnect; another player's kill", "multiplayer")
        Q.skip("J52 split view, two pads: each player's own Log and kill rows", "split view needs a second pad")
        H.note("B13 (drift, not behavior): the Notebooks side-by-side layout needs 560 units and the drawer is at most 480; win._journalPageOpen is set by nothing; CW comments still name the Page pop-up; six EN keys are read by no Lua file (the map lists them): no in-game case")
        H.note("J43's three legs: B with nothing running (J40), during an Into write (J19), during a Read (J32)")
    end)
end

-- ===================================================================== the run
S.setup()
C.j1()
C.j2()
C.j4()
C.j5()
C.j6()
C.j7()
C.j8()
C.j9()
C.j10()
C.j11()
C.j12()
C.j15()
C.j13()
C.j14()
C.j48()
C.j16()
C.j17()
C.j18()
C.j19()
C.j20()
C.j21()
C.j22()
C.j23()
C.j24()
C.j25()
C.j26()
C.j27()
C.j28()
C.j29()
C.j30()
C.j31()
C.j32()
C.j33()
C.j34()
C.j35()
C.j36()
C.j37()
C.j38()
C.j39()
C.j40()
C.j41()
C.j42()
C.j44()
C.j45()
C.j46()
C.j47()
C.j3()
C.skips()
S.buildPutBack()
Q.start()
