-- ZeDUI/tools/qa/zedqa_cov_reading.lua  (Nov 12 2026, QA coverage: ZeDUI/qa/AUDIT_DESIGN_AND_COVERAGE_20261111.md
-- Table B, the "reading" group: surfaces that were only photographed until now)
-- In game, on the ZeD-QA save only (Saves/Sandbox/ZeD-QA; on any other save it touches nothing and stops).
-- Copy to Zomboid/Lua/zedqa.lua and bump zedqa.go, or run cov_reading.txt with zedqa_run.ps1 -Manifest.
-- grep console.txt for "ZEDQA cov_reading": one line per check, "PASS <what>" or "FAIL <what> (<got> vs <want>)",
-- each value read from ZeD's own objects (window fields, the model a page draws from, what a click changed);
-- "SHOT <file>" lines name the captures (Screenshots/zqa_covrd_*.png); "RESULT <n> pass, <m> fail", then DONE.
--
-- WHAT IT CHECKS
--   Journal diary (JournalTab page 1; the tab opened by the strip's own press): the page reads the character's
--     own log and KillTracker's total with nine weapon rows; Save (the button's own mouse down and up) puts the
--     entry first with today's month, day, year and survival day and empties the box; an empty Save adds
--     nothing; the search keeps the run's two entries in two month groups, newest first, one row and one cross
--     each; a click on a month row folds it (the log measures shorter, its crosses go) and a second opens it;
--     the kills row folds open and shut; a cross asks first (Cancel keeps the entry, Delete takes it out); with
--     the log longer than its view, a click on the band's Delete still deletes the asked entry.
--   Journal Recipes (page 4, reached through the header's Page list): every recipe the game lists for the
--     character (RecipeIndex), each row locked or open as the character's skills and known recipes say, all of
--     them under Show All; read-only (no pin stars, no Craft); a click opens a row (its detail, no amount) and
--     a second shuts it; the band's Category list picked by clicks keeps that category and All brings all back;
--     a word typed in the page's search keeps matching rows; Show Known keeps known rows.
--   Newspaper fit and typesetting (ZeD_PrintPage.lua), four papers: one body size per page (12 to 40), every
--     line inside its column, every story ending above what is under it, every headline inside its column in
--     three lines at most (four for the lead), every column on the page with room, headlines and Words filled.
--   Newspaper hook (Overrides/PrintMedia.lua): vanilla's read action's displayPrintMedia opens ZeD's reader on
--     the paper (its page model, Paper first, the whole page inside the canvas at zoom 1, zoom in x1.25, Words)
--     and no vanilla print window; with safe mode on the same call opens vanilla's window instead.
--   Garment (Overrides/Garment.lua): Inspect on a torn shirt (the context menu's own callback) opens its item
--     card with the parts shown, not vanilla's garment window; the torn part's dock opens vanilla's tailoring
--     list on Patch hole with the fabric carried; an untorn part's dock offers padding; with safe mode on,
--     Inspect opens vanilla's garment window.
--   Corkboard change note (MenuNote.lua, ZeD_MainMenu.lua), drawn into a recorder through MM.drawNote: the
--     BETA 11 and BETA 12 headings drawn whole, one wider than the paper (BETA 100) left off, this copy's
--     version read from its mod.info, every word-list line drawn whole (ten characters at most, all in the
--     3 x 5 face), in the note's ink and its dim ink.
--   Workshop description editor, its model (ZeD_WorkshopText.lua): a sample reads as the expected blocks and
--     writes back to the same, an unknown or unclosed tag stays text, tables and links round-trip, counts
--     read with commas. The editor window and the note on the live desk: zedqa_cov_reading_menu.lua.
--
-- THE LEDGER: what it gives (a shirt, needle, thread, sheet strips, a newspaper; marked ZeDQA_spawned), the log
-- entries it writes (text starting "[qa-covrd] "), every window field it moves (page, searches, folds, picks,
-- the notebook choice, the draft in the write box, the recipe list's Show, Category, sort and pick, the
-- inventory selection, the tab) and the functions it swaps for a moment (ZeD.Safe.on, MM.zedVersion) are put
-- back at the end, and at once on an error. God mode goes back as it was.
local function say(s) print("ZEDQA cov_reading " .. tostring(s)) end

-- only the QA save
local saveName = nil
pcall(function() saveName = getWorld():getWorld() end)
if saveName ~= "ZeD-QA" then
    say("ERR not the ZeD-QA save (" .. tostring(saveName) .. "): nothing touched")
    say("RESULT 0 pass, 0 fail")
    say("DONE")
    return
end

local p = getPlayer()
local pn = p:getPlayerNum()
local gt = getGameTime()
local CWm, JT, CC, P, RD, MM, BB = ZeD_CharacterWindow, ZeD.JournalTab, ZeD.CraftingCore, ZeD.Print, ZeD.Reader, ZeD.MainMenu, ZeD.BB
local MARK, FIND, SPAWNED = "[qa-covrd] ", "qa-covrd", "ZeDQA_spawned"
local Q = { pass = 0, fail = 0 }
local D, R, N, G = {}, {}, {}, {}
local LG = { items = {}, done = false, safeOn = ZeD.Safe.on, zedVersion = MM and MM.zedVersion }

local function check(ok, what, got, want)
    if ok then
        Q.pass = Q.pass + 1
        say("PASS " .. what)
    else
        Q.fail = Q.fail + 1
        say("FAIL " .. what .. " (" .. tostring(got) .. " vs " .. tostring(want) .. ")")
    end
    return ok
end
local function note(s) say("NOTE " .. tostring(s)) end
local function shot(n)
    local name = "zqa_covrd_" .. n .. ".png"
    pcall(function() getCore():TakeFullScreenshot(name) end)
    say("SHOT " .. name)
end
local function W() return CWm.getWindow() end
local function log()
    local md = p:getModData()
    md.ZeD_Journal = md.ZeD_Journal or { entries = {} }
    md.ZeD_Journal.entries = md.ZeD_Journal.entries or {}
    return md.ZeD_Journal.entries
end
local function give(full)
    local it = p:getInventory():AddItem(full)
    if it then
        pcall(function() it:getModData()[SPAWNED] = true end)
        LG.items[#LG.items + 1] = it
    end
    return it
end
-- a click on the Character window's drawer at (x, y), drawer coordinates: its own mouse down and up
local function click(w, x, y)
    local dp = w._drawerPanel
    dp.onMouseDown(dp, x, y)
    if dp.onMouseUp then dp.onMouseUp(dp, x, y) end
end
-- a ZeD button pressed with the mouse: down, then up over it
local function press(btn)
    btn:onMouseDown(2, 2)
    btn._hovered = true
    btn:onMouseUp(2, 2)
end
local function center(r) return r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2) end
-- ZeD.Safe.on answering true for the length of fn only (the hooks ask it when they are called)
local function withSafeOn(fn)
    ZeD.Safe.on = function() return true end
    local ok, err = pcall(fn)
    ZeD.Safe.on = LG.safeOn
    if not ok then error(err) end
end
-- the top-level PZAPI windows (vanilla's print window is one: an AtomUI node in the UIManager)
local function atomTops()
    local out = {}
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        local n = e and e:getClass():getSimpleName() or ""
        if string.sub(n, 1, 6) == "AtomUI" then out[#out + 1] = e end
    end
    return out
end
local function newAtoms(before, after)
    local out = {}
    for _, e in ipairs(after) do
        local seen = false
        for _, b in ipairs(before) do if b == e then seen = true end end
        if not seen then out[#out + 1] = e end
    end
    return out
end
local function closeCtx()
    local ctx = getPlayerContextMenu(pn)
    if ctx and ctx._zedMenu then pcall(function() ctx._zedMenu:close() end) end
    if ctx then pcall(function() ctx:closeAll() end) end
end
local function zoneOf(list, test)
    for _, z in ipairs(list or {}) do if test(z) then return z end end
    return nil
end
local function cutMarked()
    local md = p:getModData()
    if not (md.ZeD_Journal and md.ZeD_Journal.entries) then return 0 end
    local L, n = md.ZeD_Journal.entries, 0
    for i = #L, 1, -1 do
        local e = L[i]
        if type(e) == "table" and type(e.text) == "string" and string.find(e.text, MARK, 1, true) == 1 then
            table.remove(L, i)
            n = n + 1
        end
    end
    return n
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE CORKBOARD NOTE'S MODEL (MM.drawNote into a recorder; no menu needed)
-- ---------------------------------------------------------------------------------------------------------------
-- (ZeD_MainMenu.lua's NOTE_X 52, NOTE_HEAD_Y 17 in the 5 x 7 face, NOTE_LINE_Y 30 37 44 51 58 in the 3 x 5 face)
local NOTE_X, HEAD_Y, LINE_Y = 52, 17, { 30, 37, 44, 51, 58 }
local function drawnNote(version, dipped)
    MM.zedVersion = function() return version end
    MM._note = nil
    local rec = {}
    local pane = { drawRect = function(_, x, y, w, h, a, r, g, b) rec[#rec + 1] = { x = x, y = y, w = w, r = r, g = g, b = b } end }
    local ok, err = pcall(MM.drawNote, pane, { s = 1, ox = 0, oy = 0 }, dipped)
    MM.zedVersion = LG.zedVersion
    MM._note = nil
    if not ok then error(err) end
    return rec
end
local function rowsOf(rec, y0, n)
    local c, px = 0, 0
    for _, r in ipairs(rec) do if r.y >= y0 and r.y < y0 + n then c = c + 1; px = px + r.w end end
    return c, px
end
local function runsOf(face, text, y0)
    local runs = {}
    MM._noteRuns(runs, face, text, NOTE_X, y0)
    local px = 0
    for _, r in ipairs(runs) do px = px + r.w end
    return #runs, px
end
local function noteChecks()
    for _, v in ipairs({ "0.3.0-beta11", "0.3.0-beta12" }) do
        local want = "BETA " .. string.upper(string.match(v, "beta(%w+)$"))
        local head = MM.noteHeading(v)
        check(head == want, "the note's heading for " .. v .. " reads " .. want, head, want)
        local c, px = rowsOf(drawnNote(v, false), HEAD_Y, 7)
        local wc, wpx = runsOf("57", want, HEAD_Y)
        check(wc > 0 and c == wc and px == wpx, "the note draws the whole " .. want .. " heading on the paper",
            c .. " runs " .. px .. " px", wc .. " runs " .. wpx .. " px")
    end
    local c = rowsOf(drawnNote("0.3.0-beta100", false), HEAD_Y, 7)
    check(c == 0, "a heading wider than the paper (BETA 100) is left off", c .. " runs", "0 runs")
    local v = LG.zedVersion and LG.zedVersion() or "?"
    check(v ~= "?" and v ~= "", "this copy's version is read from its mod.info", v, "a version")
    local head = MM.noteHeading(v)
    local hc = rowsOf(drawnNote(v, false), HEAD_Y, 7)
    local wc = runsOf("57", head, HEAD_Y)
    check(wc > 0 and hc == wc, "this copy's heading (" .. head .. ") is drawn whole", hc .. " runs", wc .. " runs")
    -- the word list
    local list = ZeD.MenuNote or {}
    check(#list >= 1 and #list <= #LINE_Y, "the word list fills the note's lines (1 to 5)", #list, "1 to 5")
    local F = ZeD.PixelFonts and ZeD.PixelFonts["35"] or {}
    local rec = drawnNote(v, false)
    for i, y in ipairs(LINE_Y) do
        local line = list[i]
        if line then
            local s = string.upper(tostring(line))
            local missing = ""
            for k = 1, #s do local ch = string.sub(s, k, k); if not F[ch] then missing = missing .. ch end end
            check(#s <= 10 and missing == "", "line " .. i .. " '" .. s .. "' fits: ten characters at most, all in the face",
                #s .. " chars" .. (missing ~= "" and (", no glyph for '" .. missing .. "'") or ""), "<= 10, all drawn")
            local lc, lpx = rowsOf(rec, y, 5)
            local wlc, wlpx = runsOf("35", string.sub(s, 1, 10), y)
            check(wlc > 0 and lc == wlc and lpx == wlpx, "line " .. i .. " is drawn whole", lc .. " runs " .. lpx .. " px", wlc .. " runs " .. wlpx .. " px")
        end
    end
    local function ink(r, R0, G0, B0) return r and math.abs(r.r - R0) < 0.002 and math.abs(r.g - G0) < 0.002 and math.abs(r.b - B0) < 0.002 end
    local r1 = rec[1]
    check(ink(r1, 0, 0x0f / 255, 0x34 / 255), "the note is written in its ballpoint ink",
        r1 and string.format("%.3f,%.3f,%.3f", r1.r, r1.g, r1.b), "0.000,0.059,0.204")
    local d1 = drawnNote(v, true)[1]
    check(ink(d1, 0, 0x09 / 255, 0x2f / 255), "on a lamp dip the ink dims",
        d1 and string.format("%.3f,%.3f,%.3f", d1.r, d1.g, d1.b), "0.000,0.035,0.184")
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE DESCRIPTION EDITOR'S MODEL (ZeD.BB: what the editor's cards, preview and count draw from)
-- ---------------------------------------------------------------------------------------------------------------
local SAMPLE = "[h1]Tidy Sorting[/h1]\n[img]https://example.com/banner.png[/img]\n\n"
    .. "Sorts your bags by kind with [b]one press[/b] and keeps favorites on top.\n\n"
    .. "[h2]Features[/h2]\n[list]\n[*]One-press sort in every bag\n[*]Favorites stay on top\n[/list]\n\n"
    .. "[h2]Compatibility[/h2]\n[table]\n[tr][th]Works with[/th][th]Notes[/th][/tr]\n[tr][td]Knox Radio Plus[/td][td]Load it first[/td][/tr]\n[/table]\n\n"
    .. "[url=https://example.com/page]The mod's page[/url]\n\n[hr][/hr]"
local function kinds(bs)
    local t = {}
    for _, b in ipairs(bs) do t[#t + 1] = b.kind end
    return table.concat(t, ",")
end
local function bbChecks()
    local bs = BB.parse(SAMPLE)
    local want = "h1,img,text,h2,list,h2,table,url,divider"
    check(kinds(bs) == want, "a sample description reads as its blocks", kinds(bs), want)
    local list = bs[5] and bs[5].text
    check(list == "One-press sort in every bag\nFavorites stay on top", "a list block holds one item per line", list, "two lines")
    local tbl = bs[7] and bs[7].text
    check(tbl == "Works with | Notes\nKnox Radio Plus | Load it first", "a table block holds its rows, cells split by ' | '", tbl, "two rows")
    local url = bs[8] and bs[8].text
    check(url == "https://example.com/page\nThe mod's page", "a link alone on its paragraph is a link block", url, "address and words")
    local out = BB.write(bs)
    local again = BB.parse(out)
    local same = #again == #bs
    for i = 1, math.min(#again, #bs) do if again[i].kind ~= bs[i].kind or again[i].text ~= bs[i].text then same = false end end
    check(same and BB.write(again) == out, "the blocks write back to Steam's codes and read back the same", kinds(again), kinds(bs))
    local u = BB.parse("[foo]keep me[/foo]")
    check(#u == 1 and u[1].kind == "text" and u[1].text == "[foo]keep me[/foo]", "an unknown tag stays as text", u[1] and u[1].text, "[foo]keep me[/foo]")
    local o = BB.parse("[h1]no end")
    check(#o == 1 and o[1].kind == "text" and o[1].text == "[h1]no end", "an unclosed tag stays as text", o[1] and (o[1].kind .. ":" .. o[1].text), "text:[h1]no end")
    local t = BB.write({ { kind = "table", text = "A | B\n1 | 2" } })
    local tw = "[table]\n[tr][th]A[/th][th]B[/th][/tr]\n[tr][td]1[/td][td]2[/td][/tr]\n[/table]"
    check(t == tw, "a table writes its first row as the header", t, tw)
    local c = BB.count(8000) .. " " .. BB.count(950) .. " " .. BB.count(1234567)
    check(c == "8,000 950 1,234,567", "the count reads with commas", c, "8,000 950 1,234,567")
    local empty = ""
    for _, k in ipairs(BB.KINDS) do
        if k[1] ~= "text" and BB.write({ { kind = k[1], text = BB.text(k[3]) } }) == "" then empty = empty .. k[1] .. " " end
    end
    check(empty == "", "every block the palette adds writes out", empty, "none empty")
    check(BB.LIMIT == 8000, "the editor counts against Steam's 8,000", BB.LIMIT, 8000)
end

-- ---------------------------------------------------------------------------------------------------------------
-- NEWSPAPERS SET BY ZeD (ZeD.Print.page: what the reader's headline list and thumbnails draw from)
-- ---------------------------------------------------------------------------------------------------------------
local PAPERS = { "KnoxKnews_July1", "KentuckyHerald_July6", "NationalDispatch_July6", "LouisvilleSunTimes_July6" }
-- (a real piece carries the registry's lower-case id and the proper-case text keys)
local function media(id)
    return { id = string.lower(id), title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" }
end
local TM = getTextManager()
local function lineH(font, size) return TM:getFontHeight(font) * size / 32 end
local function paperChecks(id)
    local m = media(id)
    local pg = P.page(m)
    if not check(pg ~= nil and #pg.stories > 0, id .. ": ZeD sets the page (its stories found)", pg and #pg.stories, "> 0") then return end
    local reg, bold = UIFont.SdfOldRegular, UIFont.SdfOldBold
    local other, nBody = nil, 0
    for _, o in ipairs(pg.lines) do
        if o.font == reg then nBody = nBody + 1; if o.size ~= pg.body then other = o.size end end
    end
    check(nBody > 0 and other == nil and pg.body >= 12 and pg.body <= 40, id .. ": one body size for the whole page, 12 to 40",
        tostring(pg.body) .. (other and (" and " .. tostring(other)) or ""), "one size, 12..40")
    local wide, low, head = nil, nil, nil
    for si, st in ipairs(pg.stories) do
        local nextTop = 1e9
        for _, o in ipairs(pg.stories) do if o ~= st and o.x == st.x and o.top > st.top and o.top < nextTop then nextTop = o.top end end
        local firstBody, lastBottom = nil, nil
        for _, o in ipairs(pg.lines) do
            if o.font == reg and o.x == st.x and o.y >= st.top - 0.01 and o.y < nextTop then
                if not firstBody or o.y < firstBody then firstBody = o.y end
                local b = o.y + lineH(reg, o.size)
                if not lastBottom or b > lastBottom then lastBottom = b end
                local lw = o.line.width + o.line.indent
                if lw > st.w + 0.5 and #o.line.words > 1 and not wide then
                    wide = string.format("story %s line %.1f wide in %.1f", tostring(si), lw, st.w)
                end
            end
        end
        if lastBottom and lastBottom > st.bottom + 0.5 and not low then
            low = string.format("story %s ends at %.1f, room to %.1f", tostring(si), lastBottom, st.bottom)
        end
        if st.head and firstBody then
            local n, hs = 0, nil
            for _, o in ipairs(pg.lines) do
                local inCol = st.center and math.abs(o.x + o.line.width / 2 - st.cx) < 0.5 or math.abs(o.x - st.head.box.x) < 0.01
                if o.font == bold and o.y >= st.top - 0.01 and o.y < firstBody and inCol then
                    n = n + 1
                    hs = o.size
                    if o.line.width > st.hw + 0.5 and #o.line.words > 1 and not head then
                        head = string.format("story %s headline line %.1f wide in %.1f", tostring(si), o.line.width, st.hw)
                    end
                end
            end
            local most = st.lead and 4 or 3
            if (n == 0 or (n > most and (hs or 0) > 20)) and not head then
                head = "story " .. tostring(si) .. " headline in " .. tostring(n) .. " lines"
            end
        end
    end
    check(wide == nil, id .. ": every body line inside its column", wide, "none wider")
    check(low == nil, id .. ": every story ends above what is under it", low, "none past")
    check(head == nil, id .. ": every headline inside its column, 3 lines at most (4 for the lead)", head, "none")
    local cramped = nil
    for si, st in ipairs(pg.stories) do
        if not cramped and (st.w < 40 or st.bottom - st.top < 40 or st.x < 0 or st.x + st.w > pg.w + 0.5) then
            cramped = string.format("story %s column %.0f wide from %.0f, %.0f tall", tostring(si), st.w, st.x, st.bottom - st.top)
        end
    end
    check(cramped == nil, id .. ": every story's column lies on the page with room to set it", cramped, "none cramped")
    local heads = 0
    for _, h in ipairs(P.headlines(pg)) do if string.find(h, "%a") then heads = heads + 1 end end
    check(heads > 0, id .. ": the reader's headline list has its headlines", heads, "> 0")
    local paras, hd = 0, 0
    for _, b in ipairs(P.words(m)) do
        if b.kind == "para" then paras = paras + 1 elseif b.kind == "head" then hd = hd + 1 end
    end
    check(paras > 0, id .. ": the Words view has its paragraphs (" .. hd .. " headings)", paras, "> 0")
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE LEDGER: everything put back
-- ---------------------------------------------------------------------------------------------------------------
local function restoreSelection(w)
    if not (w and LG.sel) then return end
    local cnt = w._mainContent
    if not cnt then return end
    local s = cnt._selectedItems or {}
    for k in pairs(s) do s[k] = nil end
    for k, v in pairs(LG.sel) do s[k] = v end
    cnt._selectedItems = s
    cnt._lastClickedItem = LG.lastClicked
    if w._updateDrawer then w._updateDrawer(cnt) end
    LG.sel = nil
end
local function restore(why)
    if LG.done then return end
    LG.done = true
    ZeD.Safe.on = LG.safeOn
    pcall(function() MM.zedVersion = LG.zedVersion; MM._note = nil end)
    pcall(closeCtx)
    pcall(function() local g = ISGarmentUI.windows[pn]; if g and LG.garmentWas == false then g:close() end end)
    pcall(function() for _, e in ipairs(LG.atoms or {}) do UIManager.RemoveElement(e) end end)
    pcall(function() local r = RD.get(pn); if LG.readerOpened and r and r:isVisible() then r:close() end end)
    local w = W()
    pcall(restoreSelection, w)
    local gone = 0
    for k = #LG.items, 1, -1 do
        pcall(function()
            local it = LG.items[k]
            local c = it:getContainer()
            if c then pcall(function() p:removeFromHands(it) end); c:Remove(it); gone = gone + 1 end
        end)
    end
    local cut = 0
    pcall(function()
        cut = cutMarked()
        local md = p:getModData()
        if LG.hadJournal == false and md.ZeD_Journal and #(md.ZeD_Journal.entries or {}) == 0 then md.ZeD_Journal = nil end
    end)
    if w and LG.win == w then
        pcall(function() JT.cancelDelete(w) end)
        pcall(function()
            local s = w._jrecipeState
            if s and LG.rs then
                if s.selected then CC.closeCraft(s) end
                s.show, s.showAll, s.activeCat, s.sort = LG.rs.show, LG.rs.showAll, LG.rs.activeCat, LG.rs.sort
                s.catDropdownOpen = false
                s.filterDirty = true
            end
        end)
        pcall(function() if LG.sub and w._journalSubTab ~= LG.sub then JT.setPage(w, LG.sub) end end)
        pcall(function()
            local c = w._journalGroupCollapsed or {}
            for k in pairs(c) do c[k] = nil end
            for k, v in pairs(LG.collapsed or {}) do c[k] = v end
            w._journalGroupCollapsed = c
        end)
        pcall(function() w._killsExpanded = LG.kills end)
        pcall(function() w._journalPicks = LG.picks end)
        pcall(function() if w._jr and LG.jrHad then w._jr.logInto = LG.logInto end end)
        pcall(function() JT.setSearch(w, LG.search or "") end)
        pcall(function() if w._journalScroll then w._journalScroll:setScrollPos(LG.scroll or 0) end end)
        pcall(function() if w._journalInput then w._journalInput:setText(LG.draft or "") end end)
        w._journalCache, w._journalGroupCache = nil, nil
    end
    pcall(function()
        if LG.wasOpen == false then
            if CWm.isOpen() then CWm.toggleBothPaired(pn) end
        elseif LG.wasOpen and LG.mode == "tab" and LG.open and LG.tab and LG.tab ~= "journal" then
            CWm.openTab(pn, LG.tab)
        elseif LG.wasOpen and not (LG.mode == "tab" and LG.open) then
            CWm.openTab(pn, "journal", true)   -- (the drawer was shut: the Journal tab's own press shuts it)
        end
    end)
    pcall(function() p:setGodMod(LG.god == true) end)
    say("restored (" .. tostring(why) .. "): items taken back " .. gone .. " of " .. #LG.items .. ", log entries taken out " .. cut)
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE PLAN
-- ---------------------------------------------------------------------------------------------------------------
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function waitFor(maxMs, cond, what)
    local tEnd
    plan[#plan + 1] = { ms = 0, wait = true, fn = function()
        tEnd = tEnd or (getTimestampMs() + maxMs)
        if cond() then tEnd = nil; return true end
        if getTimestampMs() > tEnd then say("NOTE gave up waiting for " .. what); tEnd = nil; return true end
        return false
    end }
end

-- 0  the models that need no window; the Journal opened by the tab strip's press
add(200, function()
    local u = UIManager.getUI()
    for k = 0, u:size() - 1 do local e = u:get(k); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    LG.god = p:isGodMod()
    p:setGodMod(true)
    local ok, err = pcall(noteChecks)
    if not ok then check(false, "the corkboard note's checks ran to the end", err, "no error") end
    if MM then MM.zedVersion, MM._note = LG.zedVersion, nil end
    ok, err = pcall(bbChecks)
    if not ok then check(false, "the description editor's model checks ran to the end", err, "no error") end
    local w = W()
    LG.wasOpen = CWm.isOpen()
    if w then LG.tab, LG.mode, LG.open, LG.sub = w._activeTab, w._drawerMode, w._drawerOpen, w._journalSubTab end
    CWm.openTab(pn, "journal")
end)

-- 1  the diary
add(1500, function()
    local w = W()
    check(w ~= nil and w._activeTab == "journal" and w._drawerMode == "tab" and w._drawerOpen == true, "the tab strip's press opens the Journal",
        w and (tostring(w._activeTab) .. "/" .. tostring(w._drawerMode) .. "/" .. tostring(w._drawerOpen)), "journal/tab/true")
    LG.win = w
    LG.sub = LG.sub or w._journalSubTab
    LG.jrHad = w._jr ~= nil
    LG.logInto = w._jr and w._jr.logInto
    LG.search = w._journalSearchText or ""
    LG.picks = w._journalPicks
    LG.collapsed = {}
    for k, v in pairs(w._journalGroupCollapsed or {}) do LG.collapsed[k] = v end
    LG.kills = w._killsExpanded
    LG.scroll = w._journalScroll and w._journalScroll.scrollPos or 0
    LG.draft = w._journalInput and w._journalInput:getText() or ""
    LG.hadJournal = p:getModData().ZeD_Journal ~= nil
    if w._jr then w._jr.logInto = nil end   -- (Save into the log alone, not a carried notebook)
    w._journalPicks = nil
    -- nothing picked in the inventory: no item card over the page (put back at the end)
    local cnt = w._mainContent
    if cnt then
        LG.sel = {}
        for k, v in pairs(cnt._selectedItems or {}) do LG.sel[k] = v end
        LG.lastClicked = cnt._lastClickedItem
        local sel = cnt._selectedItems or {}
        for k in pairs(sel) do sel[k] = nil end
        cnt._selectedItems = sel
        if w._updateDrawer then w._updateDrawer(cnt) end
    end
    JT.setPage(w, 1)
    JT.setSearch(w, "")
    D.thisKey = gt:getMonth() .. "_" .. gt:getYear()
    D.oldKey = gt:getMonth() .. "_" .. (gt:getYear() - 1)
    w._journalGroupCollapsed = w._journalGroupCollapsed or {}
    w._journalGroupCollapsed[D.thisKey], w._journalGroupCollapsed[D.oldKey] = nil, nil
    w._killsExpanded = false
    if w._journalScroll then w._journalScroll:setScrollPos(0) end
    -- an entry a year back: its own month group, after this month's
    local L = log()
    L[#L + 1] = { month = gt:getMonth(), day = 0, year = gt:getYear() - 1, hour = 8, minute = 5, survivalDay = 1, text = MARK .. "a page from a year back" }
    w._journalCache = nil
end)
add(700, function()
    local w = W()
    local data = w._journalCache
    check(w._journalView ~= nil and data ~= nil, "the diary draws its log", tostring(w._journalView ~= nil) .. "/" .. tostring(data ~= nil), "true/true")
    check(data ~= nil and data.journalEntries == log(), "the diary reads the character's own log (its mod data)", data and #data.journalEntries, #log())
    local kt = ZeD.KillTracker.total(p)
    check(data ~= nil and data.totalKills == kt, "the kills row's total is KillTracker's", data and data.totalKills, kt)
    check(data ~= nil and #data.weaponCats == 9, "nine weapon rows under the kills", data and #data.weaponCats, 9)
    shot("01_diary")
    D.n0 = #log()
    D.text1 = MARK .. "checked the fence line, all quiet"
    w._journalInput:setText(D.text1)
    press(w._journalSaveBtn)
end)
add(500, function()
    local w = W()
    local L = log()
    local e = L[1]
    check(#L == D.n0 + 1, "Save adds one entry", #L, D.n0 + 1)
    check(e ~= nil and e.text == D.text1, "the entry saved is first in the log, the words as typed", e and e.text, D.text1)
    local want = gt:getMonth() .. "/" .. gt:getDay() .. "/" .. gt:getYear()
    local got = e and (tostring(e.month) .. "/" .. tostring(e.day) .. "/" .. tostring(e.year))
    check(got == want, "the entry carries today's month, day and year", got, want)
    local sd = math.floor((p:getHoursSurvived() or 0) / 24) + 1
    check(e ~= nil and e.survivalDay == sd, "the entry carries the survival day", e and e.survivalDay, sd)
    check(w._journalInput:getText() == "", "Save empties the write box", w._journalInput:getText(), "")
    D.e1 = e
    D.n1 = #L
    w._journalInput:setText("")
    press(w._journalSaveBtn)
end)
add(400, function()
    check(#log() == D.n1, "Save with an empty box adds nothing", #log(), D.n1)
    JT.setSearch(W(), FIND)
end)
add(600, function()
    local w = W()
    local groups = JT.groups(w, log(), w._journalSearchText or "")
    local n = 0
    for _, g in ipairs(groups) do n = n + #g.entries end
    check(#groups == 2 and n == 2, "the search keeps the run's two entries, in two month groups", #groups .. " groups, " .. n .. " entries", "2 groups, 2 entries")
    local order = tostring(groups[1] and groups[1].key) .. " then " .. tostring(groups[2] and groups[2].key)
    check(order == D.thisKey .. " then " .. D.oldKey, "the month groups run newest first", order, D.thisKey .. " then " .. D.oldKey)
    check(#(w._journalGroupZones or {}) == #groups, "one month row drawn per group", #(w._journalGroupZones or {}), #groups)
    check(#(w._journalDeleteZones or {}) == n, "one delete cross drawn per entry", #(w._journalDeleteZones or {}), n)
    shot("02_search")
    D.groups = groups
    D.h0 = JT._measureJournalContent(w._journalCache, w._journalView.w, w._journalGroupCollapsed, groups)
    local z = zoneOf(w._journalGroupZones, function(g) return g.id == D.thisKey end)
    if z then click(w, z.x + 4, z.y + 2) end
end)
add(400, function()
    local w = W()
    check(w._journalGroupCollapsed[D.thisKey] == true, "a click on this month's row folds it", tostring(w._journalGroupCollapsed[D.thisKey]), "true")
    local h1 = JT._measureJournalContent(w._journalCache or { journalEntries = log() }, w._journalView.w, w._journalGroupCollapsed, D.groups)
    check(h1 < D.h0, "the folded log measures shorter", h1, "< " .. tostring(D.h0))
    check(#(w._journalDeleteZones or {}) == 1, "a folded month's entries lose their crosses", #(w._journalDeleteZones or {}), 1)
    shot("03_folded")
    local z = zoneOf(w._journalGroupZones, function(g) return g.id == D.thisKey end)
    if z then click(w, z.x + 4, z.y + 2) end
end)
add(400, function()
    local w = W()
    check(not w._journalGroupCollapsed[D.thisKey], "a second click opens the month again", tostring(w._journalGroupCollapsed[D.thisKey]), "nil or false")
    D.kills = w._killsExpanded == true
    local kz = w._journalKillsZone
    if kz then click(w, kz.x + 4, kz.y + 2) end
end)
add(400, function()
    local w = W()
    check((w._killsExpanded == true) == (not D.kills), "a click on the kills row folds it open", tostring(w._killsExpanded), tostring(not D.kills))
    local kz = w._journalKillsZone
    if kz then click(w, kz.x + 4, kz.y + 2) end
end)
add(400, function()
    local w = W()
    check((w._killsExpanded == true) == D.kills, "a second click folds the kills shut", tostring(w._killsExpanded), tostring(D.kills))
    local L = log()
    local z = zoneOf(w._journalDeleteZones, function(d) return L[d.entryIdx] == D.e1 end)
    check(z ~= nil, "the new entry has its delete cross", z, "a cross")
    if z then click(w, z.x + 2, z.y + 2) end
end)
add(400, function()
    local w = W()
    local a = w._journalAsk
    check(a ~= nil and a.entry == D.e1, "the cross asks first, about its own entry", a and a.entry and a.entry.text, D.e1 and D.e1.text)
    local r = w._journalAskRects
    check(r ~= nil and r.cancel ~= nil and r.verb ~= nil, "the question band shows Cancel and Delete", r and tostring(r.cancel ~= nil) .. "/" .. tostring(r.verb ~= nil), "true/true")
    check(not w._journalSaveBtn:isVisible(), "Save hides while the band asks", tostring(w._journalSaveBtn:isVisible()), "false")
    shot("04_ask")
    if r and r.cancel then click(w, center(r.cancel)) end
end)
add(400, function()
    local w = W()
    local kept = false
    for _, e in ipairs(log()) do if e == D.e1 then kept = true end end
    check(w._journalAsk == nil and kept, "Cancel drops the question and keeps the entry", tostring(w._journalAsk ~= nil) .. "/" .. tostring(kept), "false/true")
    local L = log()
    local z = zoneOf(w._journalDeleteZones, function(d) return L[d.entryIdx] == D.e1 end)
    if z then click(w, z.x + 2, z.y + 2) end
end)
add(400, function()
    local w = W()
    local r = w._journalAskRects
    D.n2 = #log()
    if r and r.verb then click(w, center(r.verb)) end
end)
add(400, function()
    local w = W()
    local kept = false
    for _, e in ipairs(log()) do if e == D.e1 then kept = true end end
    check(not kept and #log() == D.n2 - 1 and w._journalAsk == nil, "Delete on the band takes the entry out", tostring(kept) .. ", " .. #log() .. " entries", "false, " .. tostring(D.n2 - 1) .. " entries")
    -- the long log: thirty more entries this month, the search still on the run's mark
    local L = log()
    for k = 1, 30 do
        table.insert(L, 1, { month = gt:getMonth(), day = gt:getDay(), year = gt:getYear(), hour = 7, minute = k, survivalDay = 1,
                             text = MARK .. "filler line " .. k .. " so the log runs past its view" })
    end
    w._journalCache = nil
    if w._journalScroll then w._journalScroll:setScrollPos(0) end
end)
add(700, function()
    local w = W()
    local v = w._journalView
    local L = log()
    local z = zoneOf(w._journalDeleteZones, function(d) return v and d.y >= v.y and d.y + d.h <= v.y + v.h end)
    D.asked = z and L[z.entryIdx]
    if z then click(w, z.x + 2, z.y + 2) end
end)
-- (scroll the log until one of its zones, a cross or a month row, lies under the band's Delete)
local hunt = { pos = 0, wait = 0 }
waitFor(15000, function()
    local w = W()
    local r = w._journalAskRects
    if not (w._journalAsk and r and r.verb) then return false end
    if hunt.wait > 0 then hunt.wait = hunt.wait - 1; return false end
    local vb = r.verb
    for _, list in ipairs({ w._journalDeleteZones or {}, w._journalGroupZones or {} }) do
        for _, z in ipairs(list) do
            local x1, y1 = math.max(z.x, vb.x), math.max(z.y, vb.y)
            local x2, y2 = math.min(z.x + z.w, vb.x + vb.w), math.min(z.y + z.h, vb.y + vb.h)
            if not hunt.hit and x2 - x1 >= 2 and y2 - y1 >= 2 then hunt.hit = { x = math.floor((x1 + x2) / 2), y = math.floor((y1 + y2) / 2) } end
        end
    end
    if hunt.hit or hunt.pos >= 1 then return true end
    hunt.pos = math.min(1, hunt.pos + 0.04)
    w._journalScroll:setScrollPos(hunt.pos)
    hunt.wait = 3
    return false
end, "a log zone under the band's Delete")
add(100, function()
    local w = W()
    if not hunt.hit then note("SKIP the long log never put a zone under the band's Delete"); return end
    D.askedNow = w._journalAsk and w._journalAsk.entry
    D.n3 = #log()
    click(w, hunt.hit.x, hunt.hit.y)
end)
add(400, function()
    local w = W()
    if hunt.hit then
        local kept = false
        for _, e in ipairs(log()) do if e == D.askedNow then kept = true end end
        local a = w._journalAsk
        local got = "deleted"
        if kept then got = "kept; the question " .. (a and ((a.entry ~= D.askedNow) and "now names another entry" or "still up") or "gone") end
        check(not kept and #log() == D.n3 - 1, "with a log entry under the band, its Delete still deletes the asked entry", got, "deleted")
        shot("05_long_log")
    end
    JT.cancelDelete(w)
    cutMarked()
    JT.setSearch(w, "")
    if w._journalScroll then w._journalScroll:setScrollPos(0) end
    w._journalCache = nil
    -- to Recipes through the header's Page list
    local b = w._journalPageBox
    if b then click(w, center(b)) end
end)
add(400, function()
    local w = W()
    check(w._journalPageOpen == true, "a click on Page opens the page list", tostring(w._journalPageOpen), "true")
    local z = zoneOf(w._journalPageZones, function(pz) return pz.id == 4 end)
    check(z ~= nil, "the page list offers Recipes", #(w._journalPageZones or {}) .. " rows", "a Recipes row")
    if z then click(w, center(z)) else JT.setPage(w, 4) end
end)

-- 2  Recipes
waitFor(10000, function()
    local w = W()
    local s = w._jrecipeState
    return w._journalSubTab == 4 and s ~= nil and w._jrecipeCache ~= nil and #(s.zones or {}) > 0
end, "the Recipes page to draw")
add(100, function()
    local w = W()
    local s = w._jrecipeState
    check(w._journalSubTab == 4 and (w._journalSearchText or "") == "", "Recipes opens from the list, the searches emptied",
        tostring(w._journalSubTab) .. " '" .. tostring(w._journalSearchText) .. "'", "4 ''")
    LG.rs = { show = s.show, showAll = s.showAll, activeCat = s.activeCat, sort = s.sort }
    CC.setShow(s, "all")
    s.activeCat, s.sort = "all", "craftable"
    if s.selected then CC.closeCraft(s) end
    s.filterDirty = true
    w._jrecipeCache = nil
end)
add(900, function()
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    local RI = ZeD.RecipeIndex
    local nVis = 0
    for _, e in ipairs(data.flatRecipes or {}) do if (not RI) or RI.visible(p, e.recipe, e.source) then nVis = nVis + 1 end end
    check(#data.recipes > 0 and #data.recipes == nVis, "the page lists every recipe the game shows the character", #data.recipes, nVis)
    local off, first = 0, nil
    for _, rd in ipairs(data.recipes) do
        local e = rd.entry
        local hasSkill = true
        if e.skillName then
            local lv = 0
            local perk = CC.getPerkType(e.skillName)
            if perk and perk ~= Perks.None then lv = p:getPerkLevel(perk) end
            hasSkill = lv >= e.requiredLevel
        end
        local learned = true
        if e.needLearn then
            learned = false
            pcall(function() if p:isRecipeKnown(e.recipe) then learned = true end end)
        end
        local locked = (not learned) or (not hasSkill)
        if (rd.status == "locked") ~= locked or rd.hasSkill ~= hasSkill or rd.learned ~= learned then
            off = off + 1
            first = first or e.name
        end
    end
    check(off == 0, "each row is locked or open as the character's skills and known recipes say", off .. " off (first " .. tostring(first) .. ")", "0 off")
    check(#(s.filteredCache or {}) == #data.recipes, "Show All lists every recipe", #(s.filteredCache or {}), #data.recipes)
    local rows, stars, crafts = 0, 0, 0
    for _, z in ipairs(s.zones or {}) do
        local t = tostring(z.type)
        if t == "recipeRow" then rows = rows + 1 elseif t == "recipeStar" then stars = stars + 1 elseif string.sub(t, 1, 7) == "action_" then crafts = crafts + 1 end
    end
    check(rows > 0 and stars == 0 and crafts == 0, "read-only: rows with no pin stars and no Craft button", rows .. " rows, " .. stars .. " stars, " .. crafts .. " craft", "rows, 0, 0")
    shot("06_recipes")
    local dh = w._drawerPanel:getHeight()
    R.row = zoneOf(s.zones, function(z) return z.type == "recipeRow" and z.y >= 0 and z.y + z.h <= dh end)
    if R.row then click(w, R.row.x + 6, R.row.y + math.floor(R.row.h / 2)) end
end)
add(700, function()
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    check(R.row ~= nil and s.selected == R.row.id, "a click on a recipe row opens it", s.selected, R.row and R.row.id)
    local rd = nil
    for _, x in ipairs(data.recipes) do if x.entry.name == s.selected then rd = x end end
    check(rd ~= nil and rd.ingredients ~= nil and rd.maxBatchQty == 0, "the open recipe's detail is gathered, with no amount to make",
        rd and (tostring(rd.ingredients ~= nil) .. "/" .. tostring(rd.maxBatchQty)), "true/0")
    local crafts = 0
    for _, z in ipairs(s.zones or {}) do if string.sub(tostring(z.type), 1, 7) == "action_" then crafts = crafts + 1 end end
    check(crafts == 0, "no Craft button with a recipe open", crafts, 0)
    shot("07_recipe_open")
    local z = zoneOf(s.zones, function(x) return x.type == "recipeRow" and x.id == s.selected end)
    if z then click(w, z.x + 6, z.y + math.floor(z.h / 2)) end
end)
add(600, function()
    local w = W()
    local s = w._jrecipeState
    check(s.selected == nil, "a second click on the row shuts it", s.selected, "nil")
    local z = zoneOf(s.zones, function(x) return x.type == "catDropdown" end)
    check(z ~= nil, "the band has its Category select", z, "a select")
    if z then click(w, z.x + 4, z.y + 4) end
end)
add(500, function()
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    local g = s._ddGeo
    check(s.catDropdownOpen == true and g ~= nil, "a click on Category opens its list", tostring(s.catDropdownOpen), "true")
    -- the first category in view with a recipe listed (row 1 is All)
    local cats = s.categoryList or {}
    local per = {}
    for _, rd in ipairs(data.recipes) do local k = string.lower(rd.entry.category); per[k] = (per[k] or 0) + 1 end
    local rowH = ZeD.T.px(20)   -- (CraftingCore's DD_ROW_H; 14 rows in view, DD_MAX_VIS)
    local top = s.catDropdownScroll or 0
    for vi = 1, math.min(#cats - top, 14) - 1 do
        local c = cats[top + vi + 1]
        if c and (per[c.id] or 0) > 0 and not R.cat then R.cat = c; R.catRow = vi end
    end
    if g and R.cat then click(w, g.x + 6, g.y + math.floor(rowH * (R.catRow + 0.5))) end
end)
add(600, function()
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    local id = R.cat and R.cat.id
    check(id ~= nil and s.activeCat == id, "a click on a category in the list picks it", s.activeCat, id)
    local want, off = 0, 0
    for _, rd in ipairs(data.recipes) do if string.lower(rd.entry.category) == id then want = want + 1 end end
    for _, rd in ipairs(s.filteredCache or {}) do if string.lower(rd.entry.category) ~= id then off = off + 1 end end
    check(want > 0 and #(s.filteredCache or {}) == want and off == 0, "the category keeps its own recipes only",
        #(s.filteredCache or {}) .. " rows, " .. off .. " from elsewhere", want .. " rows, 0")
    shot("08_category")
    local z = zoneOf(s.zones, function(x) return x.type == "catDropdown" end)
    if z then click(w, z.x + 4, z.y + 4) end
end)
add(500, function()
    local w = W()
    local s = w._jrecipeState
    local g = s._ddGeo
    if s.catDropdownOpen and g then click(w, g.x + 6, g.y + math.floor(ZeD.T.px(20) / 2)) end
end)
add(600, function()
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    check(s.activeCat == "all" and #(s.filteredCache or {}) == #data.recipes, "All in the list brings every recipe back",
        tostring(s.activeCat) .. ", " .. #(s.filteredCache or {}) .. " rows", "all, " .. #data.recipes .. " rows")
    for _, rd in ipairs(data.recipes) do
        for wd in string.gmatch(string.lower(rd.entry.displayName), "%a+") do
            if #wd >= 5 and not R.term then R.term = wd end
        end
        if R.term then break end
    end
    R.term = R.term or "plank"
    w._jrecipeSearch.input:setText(R.term)
end)
add(700, function()
    local w = W()
    local s = w._jrecipeState
    check(s.search == R.term, "a word typed in the page's search reaches the list", s.search, R.term)
    local q = R.term
    local off = 0
    for _, rd in ipairs(s.filteredCache or {}) do
        local e = rd.entry
        local hit = string.find(string.lower(e.displayName), q, 1, true) or string.find(string.lower(e.category), q, 1, true)
        for _, inp in ipairs(e.inputDefs or {}) do if string.find(string.lower(tostring(inp.name)), q, 1, true) then hit = true end end
        for _, out in ipairs(e.outputDefs or {}) do if string.find(string.lower(tostring(out.name)), q, 1, true) then hit = true end end
        if not hit then off = off + 1 end
    end
    check(#(s.filteredCache or {}) > 0 and off == 0, "the search keeps matching recipes only ('" .. q .. "')",
        #(s.filteredCache or {}) .. " rows, " .. off .. " not matching", "rows, 0 not matching")
    shot("09_recipe_search")
    w._jrecipeSearch.input:setText("")
end)
add(600, function()
    local s = W()._jrecipeState
    check(s.search == "", "emptying the search field empties the list's search", s.search, "")
    CC.setShow(s, "known")
end)
add(600, function()
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    local want, off = 0, 0
    for _, rd in ipairs(data.recipes) do if rd.learned ~= false and rd.hasSkill then want = want + 1 end end
    for _, rd in ipairs(s.filteredCache or {}) do if rd.learned == false or not rd.hasSkill then off = off + 1 end end
    check(#(s.filteredCache or {}) == want and off == 0, "Show Known keeps the known recipes only",
        #(s.filteredCache or {}) .. " rows, " .. off .. " unknown", want .. " rows, 0")
    CC.setShow(s, "all")
end)

-- 3  newspapers: ZeD's setting, then the read action's hook
add(300, function()
    for _, id in ipairs(PAPERS) do paperChecks(id) end
    check(ISReadABook._zedOrigDisplayPrintMedia ~= nil and ISReadABook.displayPrintMedia ~= ISReadABook._zedOrigDisplayPrintMedia,
        "the read action's displayPrintMedia is ZeD's hook (vanilla's kept once)", tostring(ISReadABook._zedOrigDisplayPrintMedia ~= nil), "true")
    N.news = give("Base.Newspaper")
    N.news:getModData().printMedia = media("KnoxKnews_July1")
    N.news:setName(getText("Print_Media_KnoxKnews_July1_title"))
    local r = RD.get(pn)
    if r and r:isVisible() then note("the reader was open before the run: it is reused"); r:close() end
    N.atoms0 = atomTops()
    N.act = ISReadABook:new(p, N.news)
    LG.readerOpened = true
    N.act:displayPrintMedia()
end)
add(900, function()
    local r = RD.get(pn)
    check(r ~= nil and r:isVisible(), "displayPrintMedia opens ZeD's reader", r and tostring(r:isVisible()), "true")
    check(r ~= nil and r.mode == "print" and r.item == N.news, "the reader holds the paper read", r and (tostring(r.mode) .. " " .. tostring(r.item == N.news)), "print true")
    check(r ~= nil and r.media ~= nil and r.media.id == "knoxknews_july1", "the reader's piece is the paper's", r and r.media and r.media.id, "knoxknews_july1")
    local a = atomTops()
    check(#a == #N.atoms0, "no vanilla print window opens", #a, #N.atoms0)
    check(r ~= nil and r.page ~= nil and r.page == P.page(r.media), "the reader draws ZeD's page model of the paper", r and tostring(r.page ~= nil), "the page")
    check(r ~= nil and r.view == "paper", "the reader opens on Paper", r and r.view, "paper")
    local c = r and r._g and r._g.canvas
    if c and r.page then
        local k = r:paperScale(c)
        N.k1 = k
        local pw, ph = r.page.w * k, r.page.h * k
        check(pw <= c.w + 0.5 and ph <= c.h + 0.5, "the whole page fits the canvas at zoom 1",
            string.format("%.0f x %.0f", pw, ph), string.format("%.0f x %.0f", c.w, c.h))
        local t = r._pageTone
        check(t ~= nil and t.x >= c.x - 0.5 and t.y >= c.y - 0.5 and t.x + t.w <= c.x + c.w + 0.5 and t.y + t.h <= c.y + c.h + 0.5,
            "the paper lies inside the canvas", t and string.format("%.0f,%.0f %.0fx%.0f", t.x, t.y, t.w, t.h), "inside")
        note("the page is drawn " .. (r._vanillaPage and "as the game draws it (its own atoms, in ZeD's window)" or "as ZeD sets it (P.draw)"))
    else
        check(false, "the reader laid out its canvas", "no canvas", "a canvas")
    end
    shot("10_paper")
    if r then r:zoom(1) end
end)
add(400, function()
    local r = RD.get(pn)
    local k2 = r:paperScale(r._g.canvas)
    check(r.zoomIx == 2 and N.k1 ~= nil and math.abs(k2 / N.k1 - 1.25) < 0.01, "zoom in steps the page to x1.25",
        string.format("step %s, x%.2f", tostring(r.zoomIx), k2 / (N.k1 or k2)), "step 2, x1.25")
    r:setView("words")
end)
add(400, function()
    local r = RD.get(pn)
    check(r.view == "words" and #(r.words or {}) > 0 and #r.words == #P.words(r.media), "Words shows the paper's words",
        tostring(r.view) .. ", " .. #(r.words or {}) .. " blocks", "words, " .. #P.words(r.media) .. " blocks")
    shot("11_words")
    r:close()
end)
add(300, function()
    local r = RD.get(pn)
    check(r == nil or not r:isVisible(), "the reader closes", r and tostring(r:isVisible()), "false")
    N.atoms1 = atomTops()
    withSafeOn(function() N.act:displayPrintMedia() end)
end)
add(700, function()
    local new = newAtoms(N.atoms1, atomTops())
    LG.atoms = new
    local r = RD.get(pn)
    check(#new >= 1 and (r == nil or not r:isVisible()), "with safe mode on, the same call opens vanilla's print window, not the reader",
        #new .. " new, reader " .. tostring(r ~= nil and r:isVisible()), "1 new, reader false")
    shot("12_safe_print")
    for _, e in ipairs(new) do pcall(function() UIManager.RemoveElement(e) end) end
    LG.atoms = nil
end)

-- 4  the garment
add(300, function()
    local V = ISInventoryPaneContextMenu
    check(V._zedGarment == true and V._zedGarmentVanilla ~= nil and V.onInspectClothingUI ~= V._zedGarmentVanilla,
        "clothing's Inspect is ZeD's hook (vanilla's kept once)", tostring(V._zedGarment), "true")
    G.shirt = give("Base.Tshirt_DefaultTEXTURE")
    give("Base.Needle")
    give("Base.Thread")
    G.sheet = give("Base.RippedSheets")
    give("Base.RippedSheets")
    G.part = BloodBodyPartType.Torso_Upper
    G.shirt:getVisual():setHole(G.part)
    local holes = G.shirt:getVisual():getHole(G.part)
    check(holes > 0, "staged: the shirt is torn at the upper torso", holes, "> 0")
    LG.garmentWas = ISGarmentUI.windows[pn] ~= nil
    V.onInspectClothing(p, G.shirt)
end)
add(900, function()
    local w = W()
    check(w._drawerItem == G.shirt, "Inspect opens the shirt's item card in the Character window",
        w._drawerItem and w._drawerItem:getDisplayName(), G.shirt:getDisplayName())
    local card = w._itemCard
    check(card ~= nil and card._foldStates ~= nil and card._foldStates.clothing_zones == true, "the card opens with the garment's parts shown",
        card and card._foldStates and tostring(card._foldStates.clothing_zones), "true")
    check(ISGarmentUI.windows[pn] == nil, "vanilla's garment window stays shut", tostring(ISGarmentUI.windows[pn] ~= nil), "false")
    shot("13_garment_card")
    local parts = G.shirt:getCoveredParts()
    for _, r in ipairs(card and card._zoneDockRects or {}) do
        if r.zoneIdx and r.zoneIdx >= 1 and r.zoneIdx <= parts:size() then
            local part = parts:get(r.zoneIdx - 1)
            local hole = G.shirt:getVisual():getHole(part)
            if hole > 0 and not G.torn then G.torn = r
            elseif hole <= 0 and not G.whole and G.shirt:getPatchType(part) == nil then G.whole = r end
        end
    end
    check(G.torn ~= nil, "the torn part has its dock on the card", #(card and card._zoneDockRects or {}) .. " docks", "one on the torn part")
    if G.torn then card:_onZonePress(G.torn.zoneIdx, G.torn.zone, G.torn) end
end)
add(400, function()
    local ctx = getPlayerContextMenu(pn)
    local o1 = ctx and ctx.options and ctx.options[1]
    local want = getText("ContextMenu_PatchHole")
    local subs = {}
    if o1 and o1.subOption then
        local sm = ctx:getSubMenu(o1.subOption)
        for _, o in ipairs(sm and sm.options or {}) do subs[#subs + 1] = tostring(o.name) end
    end
    check(o1 ~= nil and o1.name == want, "the torn part's dock opens vanilla's tailoring list on Patch hole", o1 and o1.name, want)
    local fabric = G.sheet:getDisplayName()
    local names = table.concat(subs, " | ")
    check(string.find(names, fabric, 1, true) ~= nil, "its fabric list offers the strips carried (" .. fabric .. ")", names, fabric)
    shot("14_tailor_list")
    closeCtx()
    if G.whole then local card = W()._itemCard; card:_onZonePress(G.whole.zoneIdx, G.whole.zone, G.whole) end
end)
add(400, function()
    if G.whole then
        local ctx = getPlayerContextMenu(pn)
        local o1 = ctx and ctx.options and ctx.options[1]
        local want = getText("ContextMenu_AddPadding")
        check(o1 ~= nil and o1.name == want, "an untorn part's dock offers vanilla's Add padding", o1 and o1.name, want)
        closeCtx()
    else
        note("SKIP the card shows no dock on an untorn part (no padding offered there)")
    end
    withSafeOn(function() ISInventoryPaneContextMenu.onInspectClothingUI(p, G.shirt) end)
end)
add(500, function()
    local g = ISGarmentUI.windows[pn]
    check(g ~= nil and g.clothing == G.shirt, "with safe mode on, Inspect opens vanilla's garment window on the shirt",
        g and tostring(g.clothing == G.shirt), "true")
    shot("15_safe_garment")
    if g then g:close() end
end)
add(300, function()
    check(ISGarmentUI.windows[pn] == nil, "vanilla's garment window closes", tostring(ISGarmentUI.windows[pn] ~= nil), "false")
end)

-- the end: everything put back
add(500, function()
    restore("the end")
    say("RESULT " .. Q.pass .. " pass, " .. Q.fail .. " fail")
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if st.wait then
        local ok, done = pcall(st.fn)
        if not ok then say("ERR wait " .. i .. ": " .. tostring(done)); done = true end
        if done then i = i + 1; t0 = getTimestampMs() end
        return
    end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs()
    i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then
        say("ERR step " .. (i - 1) .. ": " .. tostring(e))
        Events.OnTick.Remove(drive)
        restore("an error")
        say("RESULT " .. Q.pass .. " pass, " .. (Q.fail + 1) .. " fail")
        say("DONE")
    end
end
if isGamePaused() then setGameSpeed(1) end
Events.OnTick.Add(drive)
say("start")
