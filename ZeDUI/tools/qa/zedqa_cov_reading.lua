-- ZeDUI/tools/qa/zedqa_cov_reading.lua  (Nov 12 2026, QA coverage: ZeDUI/qa/AUDIT_DESIGN_AND_COVERAGE_20261111.md
-- Table B, the "reading" group: surfaces that were only photographed until now; repaired the same day after review)
-- In game, on the ZeD-QA save only (Saves/Sandbox/ZeD-QA; on any other save it touches nothing and stops).
-- Copy to Zomboid/Lua/zedqa.lua and bump zedqa.go, or run cov_reading.txt with zedqa_run.ps1 -Manifest.
-- grep console.txt for "ZEDQA cov_reading": one line per check, "PASS <what>" or "FAIL <what> (<got> vs <want>)";
-- a section that cannot run says so as one FAIL ("<section> (skipped: <why>)"); NOTE lines carry the numbers read;
-- "SHOT <file>" lines name the captures (Screenshots/zqa_covrd_*.png); "RESULT <n> pass, <m> fail", then DONE.
--
-- WHAT IT CHECKS ("the game's own" is the game's Java; "measured" is a size taken from what is drawn)
--   Journal diary (JournalTab page 1): the tab strip's own press opens the Journal from another tab; the page reads the
--     character's own log and KillTracker's total (a range: a kill can land in between) with nine weapon rows; Save (the
--     button's own mouse down and up) puts the entry first with the date and survival day of the press (a range: the
--     clock runs) and empties the box; an empty Save adds nothing; the search keeps the run's two entries in two month
--     groups, newest first, one row and one cross each; a click on a month row folds it (the log measures shorter, its
--     crosses go) and a second opens it; the kills row folds open and shut; a cross asks first (Cancel keeps the entry,
--     Delete takes it out); in a log longer than its view a cross still asks, and a click on the band's Delete with a
--     log row under it deletes the asked entry.
--   Journal Recipes (page 4, reached through the header's Page list): the switch empties the searches it finds with
--     words in them; the list against the game's own per-item lists (Item.getUsedInRecipes(character): no recipe the
--     game shows is missing, none it hides is listed; a recipe with an OnAddToMenu check is left to the game); every
--     row locked or open as the game's own rule says (CraftRecipe.hasPlayerLearned and characterHasRequiredSkills),
--     and a recipe that needs two skills, staged with its first skill met and its second one short, shows locked;
--     read-only (no pin stars, no Craft); a click opens a row (its detail, no amount) and a second shuts it; the band's
--     Category list keeps the category clicked and All brings every row back; a word in the page's search keeps
--     matching rows; Show Known keeps the rows the game's rule calls known.
--   Newspapers set by ZeD (ZeD_PrintPage.lua: the page drawn by P.draw into a recorder, measured with the game's font
--     metrics), four papers with body columns: the stories found, a body size of 11.5 or more (no column narrower than
--     the setting's floor), every body line inside its column (a word too long for it counts), every story ending
--     above what is under it, every headline inside its width, every column on the page with room, the headline list
--     and Words filled. A picture front page (the Louisville Sun Times) gets no story set over its art and keeps its
--     Words.
--   Newspaper hook (Overrides/PrintMedia.lua): vanilla's read action's displayPrintMedia opens ZeD's reader on the
--     paper (ZeD's page model, Paper first) and no vanilla print window; the paper's art as the game draws it (its
--     layout built as the game's own atoms, each measured through its own pivot, scale and angle) lies inside the
--     canvas at zoom 1; the band's zoom in draws the paper a quarter larger (or filling the canvas); the band's Words
--     shows the paper's words and its Back closes the reader; with safe mode on the same call opens vanilla's window.
--   Garment (Overrides/Garment.lua): Inspect on a torn shirt (the context menu's own callback) opens its item card with
--     the parts shown, not vanilla's garment window; the torn part's dock opens vanilla's tailoring list on Patch hole
--     with the strips carried; the card's PAD (its own controller press) asks for vanilla's padding (ISRepairClothing)
--     on each untorn, unpatched part, with the needle, thread and strips carried (the queue is caught: nothing is
--     sewn); with safe mode on, Inspect opens vanilla's garment window; with the controller's marks on (a row marked
--     by A), Inspect still opens the shirt's card, not vanilla's window.
--   Corkboard change note (MenuNote.lua, ZeD_MainMenu.lua), drawn into a recorder through MM.drawNote: the BETA 11 and
--     BETA 12 headings drawn whole, one wider than the paper (BETA 100) left off, this copy's version read from its
--     mod.info, every word-list line ten characters at most and all in the 3 x 5 face, drawn whole, in the note's ink
--     and its dim ink.
--   Workshop description editor, its model (ZeD_WorkshopText.lua): a sample reads as the expected blocks and writes
--     back to the same; an unknown or unclosed tag stays text; tables and links round-trip; every block the palette
--     adds reads back as itself after a trip through Steam's codes; counts read with commas. The editor window and
--     the note on the live desk: zedqa_cov_reading_menu.lua (main menu).
--
-- FAILS EXPECTED ON NOV 12 2026 (mod bugs these checks are there to catch; the mod's code is not changed here):
--   * Knox Knews July 1 sets at body 0.46 and its second story's column is 3 units wide (the Nov 6 regression run
--     logged "body 0.4615"): ZeD_PrintPage's stories() takes a headline as its story's head only when the headline's
--     box ends at most 2 units below the body's top, and with the game's font height "Hunter injured in deer attack"
--     ends 2.4 below (the lead's headline 2.2), so that headline narrows its story's column to x 519-522 instead.
--   * National Dispatch July 6: its third story runs 11 units past its room at the setting's floor (11.58).
--   * Recipes: a row's lock reads the recipe's first required skill only (JournalTab.lua buildJournalRecipeCatalog,
--     getRequiredSkill(0); the Craft and Build tabs do the same), so a recipe whose second skill is short shows open.
--   * Garment: with the controller's marks on, Overrides/Garment.lua openCard leaves cnt._padMarks set, so the card
--     stays shut and vanilla's garment window opens (the marked rows already wiped).
--
-- THE LEDGER: what it gives (a shirt, needle, thread, sheet strips, a newspaper; marked ZeDQA_spawned), the log entries
-- it writes (text starting "[qa-covrd] "), the skill levels it stages (two perks, for one check), every window field
-- it moves (page, the three searches, folds, picks, the notebook choice, the draft, the Page list, the recipe list's
-- Show, Category, sort, pick, search and scroll, the inventory selection with the controller's marks, the tab) and
-- the functions it swaps for a moment (ZeD.Safe.on, MM.zedVersion, ISTimedActionQueue.add) are put back at the end,
-- and at once on an error. God mode and the debug console go back as they were.
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
local TM = getTextManager()
local CWm, JT, CC, P, RD, MM, BB = ZeD_CharacterWindow, ZeD.JournalTab, ZeD.CraftingCore, ZeD.Print, ZeD.Reader, ZeD.MainMenu, ZeD.BB
local MARK, FIND, SPAWNED = "[qa-covrd] ", "qa-covrd", "ZeDQA_spawned"
local Q = { pass = 0, fail = 0 }
local D, R, N, G, SEC = {}, {}, {}, {}, {}
-- (god mode and the queue read before any step moves them: an error anywhere puts back what was there)
local LG = { items = {}, done = false, safeOn = ZeD.Safe.on, zedVersion = MM and MM.zedVersion, god = p:isGodMod(),
             consoles = {}, queueAdd = ISTimedActionQueue.add }

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
-- a section that cannot run: one FAIL that says why; its later steps stand down
local function skip(sec, why)
    if SEC[sec] then return true end
    SEC[sec] = tostring(why)
    check(false, sec .. " (skipped: " .. tostring(why) .. ")", "not run", "run")
    return true
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
-- vanilla's timed-action queue caught for the length of fn: what fn asks the game to do is kept, nothing is done
local function withQueueCaught(fn)
    local got = {}
    ISTimedActionQueue.add = function(a) got[#got + 1] = a; return nil end
    local ok, err = pcall(fn)
    ISTimedActionQueue.add = LG.queueAdd
    if not ok then error(err) end
    return got
end
-- the reader's press target with this id this frame (its band's buttons: Back, Paper, Words, zoom)
local function hitOf(win, id)
    for _, h in ipairs(win and win._hits or {}) do if h.id == id then return h end end
    return nil
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
-- the date and survival day the Journal's Save would write now
local function today() return gt:getMonth() .. "/" .. gt:getDay() .. "/" .. gt:getYear() end
local function survDay() return math.floor((p:getHoursSurvived() or 0) / 24) + 1 end
-- a search field's words set without its poll filtering again
local function setField(f, text)
    if f and f.input then f.input:setText(text or ""); f._lastText = text or "" end
end
local function fieldText(f) return (f and f.input and f.input:getText()) or "" end

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
    -- (every kind writes its tags even with no words, so a block being written at all proves nothing: each one the
    -- palette adds, with its starting words, must come back from Steam's codes as one block of its kind with its words;
    -- a paragraph starts empty and an empty paragraph is no block, so it is given words of its own)
    local off = ""
    for _, k in ipairs(BB.KINDS) do
        local words = BB.text(k[3])
        if k[1] == "text" and words == "" then words = "Plain words." end
        local back = BB.parse(BB.write({ { kind = k[1], text = words } }))
        if not (#back == 1 and back[1].kind == k[1] and back[1].text == words) then
            off = off .. k[1] .. " as " .. #back .. " " .. tostring(back[1] and back[1].kind) .. "; "
        end
    end
    check(off == "", "every block the palette adds (" .. #BB.KINDS .. ") reads back as itself after a trip through Steam's codes", off, "none off")
    check(BB.LIMIT == 8000, "the editor counts against Steam's 8,000", BB.LIMIT, 8000)
end

-- ---------------------------------------------------------------------------------------------------------------
-- NEWSPAPERS SET BY ZeD (ZeD.Print.page, drawn by P.draw: the Papers page's pictures, the reader's fallback, its
-- headline list)
-- ---------------------------------------------------------------------------------------------------------------
-- (papers with body columns; the Louisville Sun Times is a picture front page, its words in RobertoSans boxes)
local PAPERS = { "KnoxKnews_July1", "KentuckyHerald_July6", "NationalDispatch_July6", "NationalDispatch_July12" }
local PICTURE = "LouisvilleSunTimes_July6"
-- (a real piece carries the registry's lower-case id and the proper-case text keys)
local function media(id)
    return { id = string.lower(id), title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" }
end
local REG, BOLD = UIFont.SdfOldRegular, UIFont.SdfOldBold
-- The page as P.draw draws it at scale 1, into a recorder, each word measured with the game's own font metrics: one
-- box { x1, x2, y1, y2 } per line of pg.lines, in its order (the stories are the last words P.draw draws). nil when
-- fewer words were drawn than the page sets.
local function drawnLines(pg)
    local rec = {}
    local pane = {
        drawRect = function() end,
        drawTextureScaledAspect = function() end,
        drawTextZoomed = function(_, s, x, y, z, r, g, b, a, font) rec[#rec + 1] = { s = s, x = x, y = y, z = z, font = font } end,
    }
    P.draw(pane, pg, 0, 0, 1)
    local n = 0
    for _, o in ipairs(pg.lines) do n = n + #o.line.words end
    local at = #rec - n
    if at < 0 then return nil end
    local out = {}
    for li, o in ipairs(pg.lines) do
        local d = { x1 = 1e9, x2 = -1e9, y1 = 1e9, y2 = -1e9 }
        for k = 1, #o.line.words do
            local wd = rec[at + k]
            local wpx = TM:MeasureStringX(wd.font, tostring(wd.s)) * wd.z
            local hpx = TM:getFontHeight(wd.font) * wd.z
            d.x1 = math.min(d.x1, wd.x)
            d.x2 = math.max(d.x2, wd.x + wpx)
            d.y1 = math.min(d.y1, wd.y)
            d.y2 = math.max(d.y2, wd.y + hpx)
        end
        at = at + #o.line.words
        out[li] = d
    end
    return out
end
local function paperChecks(id)
    local m = media(id)
    local pg = P.page(m)
    if not check(pg ~= nil and #pg.stories > 0, id .. ": ZeD finds the page's stories", pg and #pg.stories, "> 0") then return end
    note(string.format("%s: body %.2f for %d stories", id, pg.body, #pg.stories))
    -- (the setting tries 12 and up; it ends lower only by its last half step, or when a column is so narrow that a
    -- line of it cannot hold six letters: the paper is then unreadable)
    check(pg.body >= 11.5, id .. ": the body sets at a readable size, 11.5 or more (no column narrower than the setting's floor)",
        string.format("%.2f", pg.body), ">= 11.5")
    local dl = drawnLines(pg)
    if not check(dl ~= nil, id .. ": P.draw draws every word the page sets", "fewer words drawn", "all of them") then return end
    local wide, low, head = nil, nil, nil
    for si, st in ipairs(pg.stories) do
        local nextTop = 1e9
        for _, o in ipairs(pg.stories) do if o ~= st and o.x == st.x and o.top > st.top and o.top < nextTop then nextTop = o.top end end
        local firstBody, lastBottom = nil, nil
        for li, o in ipairs(pg.lines) do
            if o.font == REG and o.x == st.x and o.y >= st.top - 0.01 and o.y < nextTop then
                local d = dl[li]
                if not firstBody or o.y < firstBody then firstBody = o.y end
                if not lastBottom or d.y2 > lastBottom then lastBottom = d.y2 end
                if not wide and (d.x1 < st.x - 0.5 or d.x2 > st.x + st.w + 0.5) then
                    wide = string.format("story %d line drawn %.1f to %.1f, column %.1f to %.1f", si, d.x1, d.x2, st.x, st.x + st.w)
                end
            end
        end
        if lastBottom and lastBottom > st.bottom + 0.5 and not low then
            low = string.format("story %d drawn to %.1f, room to %.1f", si, lastBottom, st.bottom)
        end
        if st.head and firstBody then
            local n, hs = 0, nil
            local left = st.center and (st.cx - st.hw / 2) or st.head.box.x
            for li, o in ipairs(pg.lines) do
                local inCol = st.center and math.abs(o.x + o.line.width / 2 - st.cx) < 0.5 or math.abs(o.x - st.head.box.x) < 0.01
                if o.font == BOLD and o.y >= st.top - 0.01 and o.y < firstBody and inCol then
                    local d = dl[li]
                    n = n + 1
                    hs = o.size
                    if not head and (d.x1 < left - 0.5 or d.x2 > left + st.hw + 0.5) then
                        head = string.format("story %d headline drawn %.1f to %.1f, width %.1f to %.1f", si, d.x1, d.x2, left, left + st.hw)
                    end
                end
            end
            note(string.format("%s story %d: headline in %d line(s) at size %s", id, si, n, tostring(hs)))
            if n == 0 and not head then head = "story " .. si .. ": its headline is not drawn" end
        end
    end
    check(wide == nil, id .. ": every story's body, as drawn, lies inside its column (a word too long for it counts)", wide, "none outside")
    check(low == nil, id .. ": every story, as drawn, ends above what is under it", low, "none past")
    check(head == nil, id .. ": every headline, as drawn, lies inside its width (its column, or the paper's own headline when wider)", head, "none outside")
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
local function pictureChecks(id)
    local m = media(id)
    local pg = P.page(m)
    check(pg ~= nil and #pg.els > 0 and #pg.stories == 0 and #pg.lines == 0,
        id .. " (a picture front page, no body column): ZeD sets no story over its art",
        pg and (#pg.stories .. " stories, " .. #pg.lines .. " lines over " .. #pg.els .. " elements"), "0 stories, 0 lines")
    local paras, hd = 0, 0
    for _, b in ipairs(P.words(m)) do
        if b.kind == "para" then paras = paras + 1 elseif b.kind == "head" then hd = hd + 1 end
    end
    check(paras > 0 and hd > 0, id .. ": its Words view keeps the paper's words", hd .. " headings, " .. paras .. " paragraphs", "both")
end

-- The box a piece's art covers as the game draws it, in page units: its layout built the way vanilla's PrintMedia
-- builds it (each texture and text as the game's own PZAPI atom, unscaled) on a bare node that is never shown, and
-- each atom's four corners taken through the atom's own transform (pivot, scale, angle: getLuaAbsolutePosition).
-- The reader scales the same atoms as one by its zoom. Returns the box and the number of atoms measured.
local function artBox(m)
    local UI = PZAPI and PZAPI.UI
    local info = getTextOrNull(m.info)
    if not (UI and UI.Node and UI.Text and UI.Texture and info) then return nil, 0 end
    local root = UI.Node{ x = 0, y = 0, width = 805, height = 910 }
    UI._setParentChildRelationship(root)
    UI._applyHooks(root)
    UI._createAtomObjs(root)
    UI._internalInit(root)
    UI._initElement(root)
    UI._initResize(root)
    local box, n = { x1 = 1e9, y1 = 1e9, x2 = -1e9, y2 = -1e9 }, 0
    for _, val in ipairs(string.split(info, "<")) do
        if val ~= "" then
            local data = string.split(val, ">")
            local params, bad = {}, false
            for _, v in ipairs(string.split(data[1], ",")) do
                local t = string.split(v, ":")
                if t[1] == nil or t[2] == nil then bad = true else params[string.trim(t[1])] = string.trim(t[2]) end
            end
            if bad then break end
            local kind = params.type
            if kind == "text" or kind == "texture" then
                local f = {}
                for kk, v in pairs(params) do
                    if kk ~= "type" then
                        if kk == "font" then f[kk] = UIFont.FromString(v)
                        elseif kk == "texture" then f[kk] = getTexture(v)
                        else f[kk] = tonumber(v) end
                    end
                end
                local node
                if kind == "text" then
                    f.text = (tostring(data[2] or ""):gsub("%^", "\n"))
                    node = UI.Text(f)
                else
                    node = UI.Texture(f)
                end
                UI._addChild(root, node)
                local j = node.javaObj
                local w, h = j:getWidth(), j:getHeight()
                if kind == "text" then w, h = j:getTextWidth(), j:getTextHeight() end
                local px, py = j:getPivotX(), j:getPivotY()
                local xs = { -px * w, (1 - px) * w }
                local ys = { -py * h, (1 - py) * h }
                for _, lx in ipairs(xs) do
                    for _, ly in ipairs(ys) do
                        local a = j:getLuaAbsolutePosition(lx, ly)
                        box.x1 = math.min(box.x1, a.x)
                        box.y1 = math.min(box.y1, a.y)
                        box.x2 = math.max(box.x2, a.x)
                        box.y2 = math.max(box.y2, a.y)
                    end
                end
                n = n + 1
            end
        end
    end
    if n == 0 then return nil, 0 end
    return box, n
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE GAME'S OWN RECIPE RULES (what the Recipes page is held to)
-- ---------------------------------------------------------------------------------------------------------------
-- The craft recipes the game itself shows the character, by name: every script item's
-- Item.getUsedInRecipes(character) (the game's rule: one that must be learned and is not, with See Not Known Recipes
-- off, is left out), beside the same lists with no character (every recipe the items go into).
local function gameRecipeLists()
    local shown, all = {}, {}
    local sm = getScriptManager()
    local items = sm:getAllItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        local every = it:getUsedInRecipes()
        if every and every:size() > 0 then
            for k = 0, every:size() - 1 do
                local r = sm:getCraftRecipe(tostring(every:get(k)))
                if r then all[tostring(r:getName())] = r end
            end
            local mine = it:getUsedInRecipes(p)
            for k = 0, mine:size() - 1 do
                local r = sm:getCraftRecipe(tostring(mine:get(k)))
                if r then shown[tostring(r:getName())] = true end
            end
        end
    end
    return shown, all
end
-- known as the game says it: learned (when it must be) and every required skill at its level
local function gameKnows(r) return r:hasPlayerLearned(p) and r:characterHasRequiredSkills(p) end
local function putPerksBack()
    for _, pk in ipairs(LG.perks or {}) do pcall(function() p:setPerkLevelDebug(pk.perk, pk.level) end) end
    LG.perks = nil
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
    cnt._padMarks = LG.padMarks
    if w._updateDrawer then w._updateDrawer(cnt) end
    LG.sel = nil
end
-- the recipe list as it was: its picks, its open recipe, its search and its scroll (LG.rs: read when the run first
-- drew the page, before it moved anything; without it the run only touched the search)
local function restoreRecipes(w)
    local s, rs = w._jrecipeState, LG.rs
    if not s then return end
    if rs then
        s.show, s.showAll, s.activeCat, s.sort = rs.show, rs.showAll, rs.activeCat, rs.sort
        s.catDropdownScroll = rs.catScroll or 0
        if rs.selected then CC.openCraft(s, rs.selected) elseif s.selected then CC.closeCraft(s) end
        if rs.scroll and s.scroll then s.scroll:setScrollPos(rs.scroll) end
        s.catDropdownOpen, s.sortMenuOpen, s.showMenuOpen = false, false, false
    end
    s.search = LG.recipeSearch0 or ""
    s.filterDirty = true
end
local function restoreJournal(w)
    pcall(function() JT.cancelDelete(w) end)
    pcall(function() if JT.listsOpen(w) then JT.shutLists(w) end end)
    -- (the page first: a page switch empties the searches, so they are put back after it)
    pcall(function() if LG.sub and w._journalSubTab ~= LG.sub then JT.setPage(w, LG.sub) end end)
    pcall(restoreRecipes, w)
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
    pcall(function() setField(w._jrecipeSearch, LG.recipeSearch) end)
    pcall(function() setField(w._flyerSearch, LG.flyerSearch); w._flyerSearchText = LG.flyerSearchText or "" end)
    pcall(function() if w._journalScroll then w._journalScroll:setScrollPos(LG.scroll or 0) end end)
    pcall(function() if w._journalInput then w._journalInput:setText(LG.draft or "") end end)
    pcall(function() if LG.pageOpen then w._journalPageOpen = true end end)
    w._journalCache, w._journalGroupCache, w._jrecipeCache = nil, nil, nil
end
local function restoreTab()
    local w = W()
    if LG.wasOpen == false then
        if CWm.isOpen() then CWm.toggleBothPaired(pn) end
    elseif LG.wasOpen and LG.mode == "tab" and LG.open then
        if LG.tab and w and w._activeTab ~= LG.tab then CWm.openTab(pn, LG.tab) end
    elseif LG.wasOpen and LG.mode ~= "item" then
        -- (the drawer was shut: the showing tab's own press shuts it again)
        if w and w._drawerMode == "tab" and w._drawerOpen and w._activeTab then CWm.openTab(pn, w._activeTab, true) end
    end
end
local function restore(why)
    if LG.done then return end
    LG.done = true
    ZeD.Safe.on = LG.safeOn
    ISTimedActionQueue.add = LG.queueAdd
    pcall(putPerksBack)
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
    if w and LG.win == w then restoreJournal(w) end
    pcall(restoreTab)
    pcall(function() p:setGodMod(LG.god == true) end)
    for _, e in ipairs(LG.consoles) do pcall(function() e:setVisible(true) end) end
    say("restored (" .. tostring(why) .. "): items taken back " .. gone .. " of " .. #LG.items .. ", log entries taken out " .. cut)
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE PLAN
-- ---------------------------------------------------------------------------------------------------------------
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
-- wait for cond (at most maxMs); giving up is a FAIL of its own
local function waitFor(maxMs, cond, what)
    local tEnd
    plan[#plan + 1] = { ms = 0, wait = true, fn = function()
        tEnd = tEnd or (getTimestampMs() + maxMs)
        if cond() then tEnd = nil; return true end
        if getTimestampMs() > tEnd then
            check(false, what .. " within " .. math.floor(maxMs / 1000) .. " s", "gave up", "in time")
            tEnd = nil
            return true
        end
        return false
    end }
end

-- 0  the models that need no window; the pair open, god mode on
add(200, function()
    local u = UIManager.getUI()
    for k = 0, u:size() - 1 do
        local e = u:get(k)
        if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then
            e:setVisible(false)
            LG.consoles[#LG.consoles + 1] = e
        end
    end
    p:setGodMod(true)
    local ok, err = pcall(noteChecks)
    if not ok then check(false, "the corkboard note's checks ran to the end", err, "no error") end
    if MM then MM.zedVersion, MM._note = LG.zedVersion, nil end
    ok, err = pcall(bbChecks)
    if not ok then check(false, "the description editor's model checks ran to the end", err, "no error") end
    local w = W()
    LG.wasOpen = CWm.isOpen()
    if w then LG.tab, LG.mode, LG.open, LG.sub = w._activeTab, w._drawerMode, w._drawerOpen, w._journalSubTab end
    if not LG.wasOpen then CWm.toggleBothPaired(pn) end
end)
-- (openTab does not press the strip when the Journal already shows: then another tab first)
add(800, function()
    local w = W()
    if w and w._activeTab == "journal" and w._drawerMode == "tab" and w._drawerOpen then CWm.openTab(pn, "skills") end
end)
add(800, function()
    local w = W()
    D.before = w and (tostring(w._activeTab) .. "/" .. tostring(w._drawerMode) .. "/" .. tostring(w._drawerOpen)) or "no window"
    D.wasShowing = w ~= nil and w._activeTab == "journal" and w._drawerMode == "tab" and w._drawerOpen == true
    CWm.openTab(pn, "journal")
end)

-- 1  the diary
add(1500, function()
    local w = W()
    if not w then skip("the Journal", "no Character window"); return end
    check(not D.wasShowing and w._activeTab == "journal" and w._drawerMode == "tab" and w._drawerOpen == true,
        "the tab strip's press opens the Journal (from " .. D.before .. ")",
        tostring(w._activeTab) .. "/" .. tostring(w._drawerMode) .. "/" .. tostring(w._drawerOpen) .. (D.wasShowing and ", it already showed: no press" or ""),
        "journal/tab/true after a press")
    LG.win = w
    LG.sub = LG.sub or w._journalSubTab
    LG.jrHad = w._jr ~= nil
    LG.logInto = w._jr and w._jr.logInto
    LG.search = w._journalSearchText or ""
    LG.recipeSearch = fieldText(w._jrecipeSearch)
    LG.recipeSearch0 = w._jrecipeState and w._jrecipeState.search or ""
    LG.flyerSearch = fieldText(w._flyerSearch)
    LG.flyerSearchText = w._flyerSearchText or ""
    LG.pageOpen = w._journalPageOpen == true
    LG.picks = w._journalPicks
    LG.collapsed = {}
    for k, v in pairs(w._journalGroupCollapsed or {}) do LG.collapsed[k] = v end
    LG.kills = w._killsExpanded
    LG.scroll = w._journalScroll and w._journalScroll.scrollPos or 0
    LG.draft = w._journalInput and w._journalInput:getText() or ""
    LG.hadJournal = p:getModData().ZeD_Journal ~= nil
    if JT.listsOpen(w) then JT.shutLists(w) end
    if w._jr then w._jr.logInto = nil end   -- (Save into the log alone, not a carried notebook)
    w._journalPicks = nil
    -- nothing picked in the inventory: no item card over the page (put back at the end, the controller's marks too)
    local cnt = w._mainContent
    if cnt then
        LG.sel = {}
        for k, v in pairs(cnt._selectedItems or {}) do LG.sel[k] = v end
        LG.lastClicked = cnt._lastClickedItem
        LG.padMarks = cnt._padMarks
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
    D.kt0 = ZeD.KillTracker.total(p)
    w._journalCache = nil
end)
add(700, function()
    if SEC["the Journal"] then return end
    local w = W()
    local data = w._journalCache
    check(w._journalView ~= nil and data ~= nil, "the diary draws its log", tostring(w._journalView ~= nil) .. "/" .. tostring(data ~= nil), "true/true")
    check(data ~= nil and data.journalEntries == log(), "the diary reads the character's own log (its mod data)", data and #data.journalEntries, #log())
    local kt1 = ZeD.KillTracker.total(p)
    check(data ~= nil and data.totalKills >= D.kt0 and data.totalKills <= kt1, "the kills row's total is KillTracker's",
        data and data.totalKills, D.kt0 .. " to " .. kt1)
    check(data ~= nil and #data.weaponCats == 9, "nine weapon rows under the kills", data and #data.weaponCats, 9)
    shot("01_diary")
    D.n0 = #log()
    D.text1 = MARK .. "checked the fence line, all quiet"
    w._journalInput:setText(D.text1)
    D.date0, D.sd0 = today(), survDay()
    press(w._journalSaveBtn)
end)
add(500, function()
    if SEC["the Journal"] then return end
    local w = W()
    local L = log()
    local e = L[1]
    check(#L == D.n0 + 1, "Save adds one entry", #L, D.n0 + 1)
    check(e ~= nil and e.text == D.text1, "the entry saved is first in the log, the words as typed", e and e.text, D.text1)
    local d1 = today()
    local got = e and (tostring(e.month) .. "/" .. tostring(e.day) .. "/" .. tostring(e.year))
    check(got == D.date0 or got == d1, "the entry carries the date of the press (month, day, year)", got, D.date0 .. (d1 ~= D.date0 and (" or " .. d1) or ""))
    local sd1 = survDay()
    check(e ~= nil and e.survivalDay ~= nil and e.survivalDay >= D.sd0 and e.survivalDay <= sd1, "the entry carries the survival day",
        e and e.survivalDay, D.sd0 .. " to " .. sd1)
    check(w._journalInput:getText() == "", "Save empties the write box", w._journalInput:getText(), "")
    D.e1 = e
    D.n1 = #L
    -- (the month group the entry fell in, whatever the clock did since step 1)
    if e and e.month and e.year then D.thisKey = e.month .. "_" .. e.year end
    w._journalGroupCollapsed[D.thisKey] = nil
    w._journalInput:setText("")
    press(w._journalSaveBtn)
end)
add(400, function()
    if SEC["the Journal"] then return end
    check(#log() == D.n1, "Save with an empty box adds nothing", #log(), D.n1)
    JT.setSearch(W(), FIND)
end)
add(600, function()
    if SEC["the Journal"] then return end
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
    if SEC["the Journal"] then return end
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
    if SEC["the Journal"] then return end
    local w = W()
    check(not w._journalGroupCollapsed[D.thisKey], "a second click opens the month again", tostring(w._journalGroupCollapsed[D.thisKey]), "nil or false")
    D.kills = w._killsExpanded == true
    local kz = w._journalKillsZone
    if kz then click(w, kz.x + 4, kz.y + 2) end
end)
add(400, function()
    if SEC["the Journal"] then return end
    local w = W()
    check((w._killsExpanded == true) == (not D.kills), "a click on the kills row folds it open", tostring(w._killsExpanded), tostring(not D.kills))
    local kz = w._journalKillsZone
    if kz then click(w, kz.x + 4, kz.y + 2) end
end)
add(400, function()
    if SEC["the Journal"] then return end
    local w = W()
    check((w._killsExpanded == true) == D.kills, "a second click folds the kills shut", tostring(w._killsExpanded), tostring(D.kills))
    local L = log()
    local z = zoneOf(w._journalDeleteZones, function(d) return L[d.entryIdx] == D.e1 end)
    check(z ~= nil, "the new entry has its delete cross", z, "a cross")
    if z then click(w, z.x + 2, z.y + 2) end
end)
add(400, function()
    if SEC["the Journal"] then return end
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
    if SEC["the Journal"] then return end
    local w = W()
    local kept = false
    for _, e in ipairs(log()) do if e == D.e1 then kept = true end end
    check(w._journalAsk == nil and kept, "Cancel drops the question and keeps the entry", tostring(w._journalAsk ~= nil) .. "/" .. tostring(kept), "false/true")
    local L = log()
    local z = zoneOf(w._journalDeleteZones, function(d) return L[d.entryIdx] == D.e1 end)
    if z then click(w, z.x + 2, z.y + 2) end
end)
add(400, function()
    if SEC["the Journal"] then return end
    local w = W()
    local r = w._journalAskRects
    D.n2 = #log()
    if r and r.verb then click(w, center(r.verb)) end
end)
add(400, function()
    if SEC["the Journal"] then return end
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
    if SEC["the Journal"] then return end
    local w = W()
    local v = w._journalView
    local L = log()
    local z = zoneOf(w._journalDeleteZones, function(d) return v and d.y >= v.y and d.y + d.h <= v.y + v.h end)
    D.asked = z and L[z.entryIdx]
    if check(z ~= nil, "the long log draws a cross wholly in its view", #(w._journalDeleteZones or {}) .. " crosses", "one in view") then
        click(w, z.x + 2, z.y + 2)
    end
end)
add(400, function()
    if SEC["the Journal"] then return end
    local w = W()
    local a = w._journalAsk
    D.longAsk = a ~= nil and D.asked ~= nil and a.entry == D.asked
    check(D.longAsk, "in the long log a cross asks first, about its own entry", a and a.entry and a.entry.text, D.asked and D.asked.text or "a question")
end)
-- (scroll the log until one of its zones, a cross or a month row, lies under the band's Delete)
local hunt = { pos = 0, wait = 0 }
waitFor(15000, function()
    if SEC["the Journal"] or not D.longAsk then return true end
    local w = W()
    local r = w._journalAskRects
    if not (w._journalAsk and r and r.verb) then hunt.lost = true; return true end
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
    if SEC["the Journal"] then return end
    local w = W()
    if not D.longAsk then
        check(false, "the band's Delete over a log row (skipped: the long log's cross did not ask)", "no question", "a question")
        return
    end
    if not hunt.hit then
        check(false, "the band's Delete over a log row (skipped: " .. (hunt.lost and "the question went while scrolling" or "no log row came under it, top to bottom") .. ")",
            "no row under Delete", "a row under Delete")
        return
    end
    D.askedNow = w._journalAsk and w._journalAsk.entry
    D.n3 = #log()
    click(w, hunt.hit.x, hunt.hit.y)
end)
add(400, function()
    if SEC["the Journal"] then return end
    local w = W()
    if hunt.hit and D.longAsk then
        local kept = false
        for _, e in ipairs(log()) do if e == D.askedNow then kept = true end end
        local a = w._journalAsk
        local got = "deleted"
        if kept then got = "kept; the question " .. (a and ((a.entry ~= D.askedNow) and "now names another entry" or "still up") or "gone") end
        check(not kept and #log() == D.n3 - 1, "with a log row under the band, its Delete still deletes the asked entry", got, "deleted")
        shot("05_long_log")
    end
    JT.cancelDelete(w)
    cutMarked()
    if w._journalScroll then w._journalScroll:setScrollPos(0) end
    w._journalCache = nil
    -- words left in every search (the Journal's, the recipe list's and the Papers'): the page switch must empty them
    JT.setSearch(w, FIND)
    setField(w._jrecipeSearch, "plank")
    D.hadRecipeState = w._jrecipeState ~= nil
    if w._jrecipeState then w._jrecipeState.search = "plank" end
    setField(w._flyerSearch, "flyer")
    w._flyerSearchText = "flyer"
    -- to Recipes through the header's Page list
    local b = w._journalPageBox
    if b then click(w, center(b)) end
end)
add(400, function()
    if SEC["the Journal"] then skip("the Recipes page", "the Journal did not open"); return end
    local w = W()
    local open = check(w._journalPageOpen == true, "a click on Page opens the page list", tostring(w._journalPageOpen), "true")
    local z = open and zoneOf(w._journalPageZones, function(pz) return pz.id == 4 end) or nil
    check(z ~= nil, "the page list offers Recipes", #(w._journalPageZones or {}) .. " rows", "a Recipes row")
    if z then
        D.viaList = true
        click(w, center(z))
    else
        -- (the list shut first: left open, it would take the next click on the drawer to shut itself)
        if JT.listsOpen(w) then JT.shutLists(w) end
        JT.setPage(w, 4)
    end
end)

-- 2  Recipes
waitFor(10000, function()
    if SEC["the Recipes page"] then return true end
    local w = W()
    local s = w._jrecipeState
    return w._journalSubTab == 4 and s ~= nil and w._jrecipeCache ~= nil and #(s.zones or {}) > 0
end, "the Recipes page to draw")
add(100, function()
    if SEC["the Recipes page"] then return end
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    if not (w._journalSubTab == 4 and s and data and data.recipes) then skip("the Recipes page", "it never drew"); return end
    check(D.viaList == true and w._journalSubTab == 4 and not JT.listsOpen(w), "the Page list's Recipes row opens Recipes and the list shuts",
        (D.viaList and "the row" or "opened by the run, not the list") .. ", page " .. tostring(w._journalSubTab) .. ", lists open " .. tostring(JT.listsOpen(w)),
        "the row, page 4, lists shut")
    local jt, rt, ft = w._journalSearchText or "", fieldText(w._jrecipeSearch), w._flyerSearchText or ""
    local emptied = jt == "" and fieldText(w._journalSearch) == "" and rt == "" and ft == "" and fieldText(w._flyerSearch) == ""
        and (not D.hadRecipeState or s.search == "")
    check(emptied, "the page switch empties the searches it found with words (Journal, recipes, Papers)",
        "'" .. jt .. "' '" .. rt .. "' '" .. ft .. "' state '" .. tostring(s.search) .. "'", "all empty")
    LG.rs = { show = s.show, showAll = s.showAll, activeCat = s.activeCat, sort = s.sort, selected = s.selected,
              catScroll = s.catDropdownScroll, scroll = s.scroll and s.scroll.scrollPos }
    CC.setShow(s, "all")
    s.activeCat, s.sort = "all", "craftable"
    if s.selected then CC.closeCraft(s) end
    s.filterDirty = true
    w._jrecipeCache = nil
end)
add(900, function()
    if SEC["the Recipes page"] then return end
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    if not (s and data and data.recipes) then skip("the Recipes page", "its list was not gathered again"); return end
    -- the page against the game's own per-item lists
    local okL, shown, all = pcall(gameRecipeLists)
    if not okL then
        check(false, "the game's own per-item recipe lists could be read", shown, "the lists")
    else
        local inPage = {}
        for _, rd in ipairs(data.recipes) do inPage[tostring(rd.entry.name)] = true end
        local missing, extra, left, named, firstM, firstE = 0, 0, 0, 0, nil, nil
        for name, r in pairs(all) do
            named = named + 1
            local hook = r:getOnAddToMenu()
            if hook and hook ~= "" then left = left + 1
            elseif shown[name] and not inPage[name] then missing = missing + 1; firstM = firstM or name
            elseif not shown[name] and inPage[name] then extra = extra + 1; firstE = firstE or name end
        end
        note(#data.recipes .. " rows; the game's per-item lists name " .. named .. " craft recipes, " .. left .. " with an OnAddToMenu check left to the game")
        check(named > 0 and missing == 0 and extra == 0, "the page lists what the game itself shows the character (its per-item lists: none missing, none it hides)",
            missing .. " missing (first " .. tostring(firstM) .. "), " .. extra .. " hidden by the game but listed (first " .. tostring(firstE) .. ") of " .. named,
            "0 and 0 of the recipes named")
    end
    -- every row's lock against the game's own rule
    local off, first = 0, nil
    local okK, errK = pcall(function()
        for _, rd in ipairs(data.recipes) do
            local locked = not gameKnows(rd.entry.recipe)
            if (rd.status == "locked") ~= locked then off = off + 1; first = first or (tostring(rd.entry.name) .. " shows " .. tostring(rd.status)) end
        end
    end)
    check(okK and off == 0, "each row is locked or open as the game's own rule says (learned, every required skill at its level)",
        okK and (off .. " off (first " .. tostring(first) .. ")") or errK, "0 off")
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
    if SEC["the Recipes page"] then return end
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    check(R.row ~= nil and s.selected == R.row.id, "a click on a recipe row opens it", s.selected, R.row and R.row.id)
    local rd = nil
    for _, x in ipairs(data and data.recipes or {}) do if x.entry.name == s.selected then rd = x end end
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
    if SEC["the Recipes page"] then return end
    local w = W()
    local s = w._jrecipeState
    check(s.selected == nil, "a second click on the row shuts it", s.selected, "nil")
    local z = zoneOf(s.zones, function(x) return x.type == "catDropdown" end)
    check(z ~= nil, "the band has its Category select", z, "a select")
    if z then click(w, z.x + 4, z.y + 4) end
end)
add(500, function()
    if SEC["the Recipes page"] then return end
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    local g = s._ddGeo
    check(s.catDropdownOpen == true and g ~= nil, "a click on Category opens its list", tostring(s.catDropdownOpen), "true")
    -- the first category in view with a recipe listed (row 1 is All)
    local cats = s.categoryList or {}
    local per = {}
    for _, rd in ipairs(data and data.recipes or {}) do local k = string.lower(rd.entry.category); per[k] = (per[k] or 0) + 1 end
    local rowH = ZeD.T.px(20)   -- (CraftingCore's DD_ROW_H; 14 rows in view, DD_MAX_VIS)
    local top = s.catDropdownScroll or 0
    for vi = 1, math.min(#cats - top, 14) - 1 do
        local c = cats[top + vi + 1]
        if c and (per[c.id] or 0) > 0 and not R.cat then R.cat = c; R.catRow = vi end
    end
    if g and R.cat then click(w, g.x + 6, g.y + math.floor(rowH * (R.catRow + 0.5))) end
end)
add(600, function()
    if SEC["the Recipes page"] then return end
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    local id = R.cat and R.cat.id
    check(id ~= nil and s.activeCat == id, "a click on a category in the list picks it", s.activeCat, id)
    local want, off = 0, 0
    for _, rd in ipairs(data and data.recipes or {}) do if string.lower(rd.entry.category) == id then want = want + 1 end end
    for _, rd in ipairs(s.filteredCache or {}) do if string.lower(rd.entry.category) ~= id then off = off + 1 end end
    check(want > 0 and #(s.filteredCache or {}) == want and off == 0, "the category keeps its own recipes only",
        #(s.filteredCache or {}) .. " rows, " .. off .. " from elsewhere", want .. " rows, 0")
    shot("08_category")
    local z = zoneOf(s.zones, function(x) return x.type == "catDropdown" end)
    if z then click(w, z.x + 4, z.y + 4) end
end)
add(500, function()
    if SEC["the Recipes page"] then return end
    local w = W()
    local s = w._jrecipeState
    local g = s._ddGeo
    if s.catDropdownOpen and g then click(w, g.x + 6, g.y + math.floor(ZeD.T.px(20) / 2)) end
end)
add(600, function()
    if SEC["the Recipes page"] then return end
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    check(s.activeCat == "all" and #(s.filteredCache or {}) == #(data and data.recipes or {}), "All in the list brings every recipe back",
        tostring(s.activeCat) .. ", " .. #(s.filteredCache or {}) .. " rows", "all, " .. #(data and data.recipes or {}) .. " rows")
    for _, rd in ipairs(data and data.recipes or {}) do
        for wd in string.gmatch(string.lower(rd.entry.displayName), "%a+") do
            if #wd >= 5 and not R.term then R.term = wd end
        end
        if R.term then break end
    end
    R.term = R.term or "plank"
    w._jrecipeSearch.input:setText(R.term)
end)
add(700, function()
    if SEC["the Recipes page"] then return end
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
    if SEC["the Recipes page"] then return end
    local s = W()._jrecipeState
    check(s.search == "", "emptying the search field empties the list's search", s.search, "")
    CC.setShow(s, "known")
end)
add(600, function()
    if SEC["the Recipes page"] then return end
    local w = W()
    local s, data = w._jrecipeState, w._jrecipeCache
    local want, off = 0, 0
    local okK, errK = pcall(function()
        for _, rd in ipairs(data and data.recipes or {}) do if gameKnows(rd.entry.recipe) then want = want + 1 end end
        for _, rd in ipairs(s.filteredCache or {}) do if not gameKnows(rd.entry.recipe) then off = off + 1 end end
    end)
    check(okK and #(s.filteredCache or {}) == want and off == 0, "Show Known keeps the recipes the game's rule calls known",
        okK and (#(s.filteredCache or {}) .. " rows, " .. off .. " the game calls unknown") or errK, want .. " rows, 0")
    CC.setShow(s, "all")
    -- staged: a recipe that needs two skills (and no learning, or learned), its first skill met, its second one short
    local pick = nil
    pcall(function()
        for _, rd in ipairs(data and data.recipes or {}) do
            local r = rd.entry.recipe
            if not pick and r:getRequiredSkillCount() >= 2 and r:hasPlayerLearned(p) then
                local s1, s2 = r:getRequiredSkill(0), r:getRequiredSkill(1)
                if s1:getPerk() ~= s2:getPerk() and s2:getLevel() >= 1 then pick = { name = rd.entry.name, recipe = r, s1 = s1, s2 = s2 } end
            end
        end
    end)
    if not check(pick ~= nil, "the page has a recipe that needs two skills, to stage", "none", "one") then return end
    R.two = pick
    local p1, p2 = pick.s1:getPerk(), pick.s2:getPerk()
    LG.perks = { { perk = p1, level = p:getPerkLevel(p1) }, { perk = p2, level = p:getPerkLevel(p2) } }
    p:setPerkLevelDebug(p1, math.max(p:getPerkLevel(p1), pick.s1:getLevel()))
    p:setPerkLevelDebug(p2, pick.s2:getLevel() - 1)
    w._jrecipeCache = nil
end)
add(700, function()
    if SEC["the Recipes page"] or not R.two then putPerksBack(); return end
    local w = W()
    local data = w._jrecipeCache
    local rd = nil
    for _, x in ipairs(data and data.recipes or {}) do if x.entry.name == R.two.name then rd = x end end
    local p1, p2 = R.two.s1:getPerk(), R.two.s2:getPerk()
    local what = string.format("%s: %s %d of %d, %s %d of %d", tostring(R.two.name), tostring(p1:getName()), p:getPerkLevel(p1), R.two.s1:getLevel(),
        tostring(p2:getName()), p:getPerkLevel(p2), R.two.s2:getLevel())
    local gameSays = R.two.recipe:characterHasRequiredSkills(p) and "open" or "locked"
    check(rd ~= nil and gameSays == "locked" and rd.status == "locked",
        "a recipe that needs two skills, its first met and its second one short, shows locked as the game says (" .. what .. ")",
        rd and (tostring(rd.status) .. ", the game: " .. gameSays) or "no row", "locked")
    putPerksBack()
    w._jrecipeCache = nil
end)

-- 3  newspapers: ZeD's setting, then the read action's hook
add(300, function()
    for _, id in ipairs(PAPERS) do
        local ok, err = pcall(paperChecks, id)
        if not ok then check(false, id .. ": the paper's checks ran to the end", err, "no error") end
    end
    local ok, err = pcall(pictureChecks, PICTURE)
    if not ok then check(false, PICTURE .. ": the picture page's checks ran to the end", err, "no error") end
    check(ISReadABook._zedOrigDisplayPrintMedia ~= nil and ISReadABook.displayPrintMedia ~= ISReadABook._zedOrigDisplayPrintMedia,
        "the read action's displayPrintMedia is ZeD's hook (vanilla's kept once)", tostring(ISReadABook._zedOrigDisplayPrintMedia ~= nil), "true")
    N.news = give("Base.Newspaper")
    if not N.news then skip("the reader", "no newspaper given"); return end
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
    if SEC["the reader"] then return end
    local r = RD.get(pn)
    if not check(r ~= nil and r:isVisible(), "displayPrintMedia opens ZeD's reader", r and tostring(r:isVisible()), "true") then
        skip("the reader", "it did not open")
        return
    end
    check(r.mode == "print" and r.item == N.news, "the reader holds the paper read", tostring(r.mode) .. " " .. tostring(r.item == N.news), "print true")
    check(r.media ~= nil and r.media.id == "knoxknews_july1", "the reader's piece is the paper's", r.media and r.media.id, "knoxknews_july1")
    local a = atomTops()
    check(#a == #N.atoms0, "no vanilla print window opens", #a, #N.atoms0)
    check(r.page ~= nil and r.page == P.page(r.media), "the reader holds ZeD's page model of the paper (its headline list and Words)", tostring(r.page ~= nil), "the page")
    check(r.view == "paper", "the reader opens on Paper", r.view, "paper")
    local c = r._g and r._g.canvas
    if c and r.page then
        local k = r:paperScale(c)
        local pw, ph = r.page.w * k, r.page.h * k
        local ox = c.x + math.floor((c.w - pw) / 2 + (r.panX or 0))
        local oy = c.y + math.floor((c.h - ph) / 2 + (r.panY or 0))
        local okB, box, nAtoms = pcall(artBox, r.media)
        if okB and box then
            local x1, y1, x2, y2 = ox + box.x1 * k, oy + box.y1 * k, ox + box.x2 * k, oy + box.y2 * k
            note(string.format("the paper's art reaches %.1f,%.1f to %.1f,%.1f in page units (%d atoms; the page %.0f x %.0f)", box.x1, box.y1, box.x2, box.y2, nAtoms, r.page.w, r.page.h))
            check(x1 >= c.x - 1 and y1 >= c.y - 1 and x2 <= c.x + c.w + 1 and y2 <= c.y + c.h + 1,
                "the whole paper, as the game draws its art, lies inside the canvas at zoom 1",
                string.format("art %.0f,%.0f to %.0f,%.0f", x1, y1, x2, y2), string.format("canvas %.0f,%.0f to %.0f,%.0f", c.x, c.y, c.x + c.w, c.y + c.h))
        else
            check(false, "the paper's art could be measured as the game draws it", okB and "no atoms" or box, "a box")
        end
        local t = r._pageTone
        N.tone1 = t and { w = t.w, h = t.h }
        N.canvas = { w = c.w, h = c.h }
        note("the page is drawn " .. (r._vanillaPage and "as the game draws it (its own atoms, in ZeD's window)" or "as ZeD sets it (P.draw)"))
    else
        check(false, "the reader laid out its canvas", "no canvas", "a canvas")
    end
    shot("10_paper")
    local h = hitOf(r, "zoom:in")
    if check(h ~= nil and h.fn ~= nil, "the band has its zoom-in button", h, "a button") then h.fn() end
end)
add(400, function()
    if SEC["the reader"] then return end
    local r = RD.get(pn)
    local t, t1, c = r._pageTone, N.tone1, N.canvas
    local okT = t ~= nil and t1 ~= nil and c ~= nil
        and math.abs(t.w - math.min(c.w, t1.w * 1.25)) <= 2 and math.abs(t.h - math.min(c.h, t1.h * 1.25)) <= 2
    check(r.zoomIx == 2 and okT, "the band's zoom in draws the paper a quarter larger (or filling the canvas)",
        string.format("step %s, drawn %s", tostring(r.zoomIx), t and string.format("%.0f x %.0f", t.w, t.h) or "nothing"),
        t1 and c and string.format("step 2, %.0f x %.0f", math.min(c.w, t1.w * 1.25), math.min(c.h, t1.h * 1.25)) or "step 2")
    local h = hitOf(r, "view:words")
    if check(h ~= nil and h.fn ~= nil, "the band has its Words button", h, "a button") then h.fn() end
end)
add(400, function()
    if SEC["the reader"] then return end
    local r = RD.get(pn)
    check(r.view == "words" and #(r.words or {}) > 0 and #r.words == #P.words(r.media), "Words shows the paper's words",
        tostring(r.view) .. ", " .. #(r.words or {}) .. " blocks", "words, " .. #P.words(r.media) .. " blocks")
    shot("11_words")
    local h = hitOf(r, "back")
    if check(h ~= nil and h.fn ~= nil, "the band has its Back button", h, "a button") then h.fn() else r:close() end
end)
add(300, function()
    if not N.act then return end
    local r = RD.get(pn)
    if not SEC["the reader"] then check(r == nil or not r:isVisible(), "Back closes the reader", r and tostring(r:isVisible()), "false") end
    N.atoms1 = atomTops()
    withSafeOn(function() N.act:displayPrintMedia() end)
end)
add(700, function()
    if not N.act then return end
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
    G.needle = give("Base.Needle")
    give("Base.Thread")
    G.sheet = give("Base.RippedSheets")
    give("Base.RippedSheets")
    if not G.shirt then skip("the garment", "no shirt given"); return end
    G.part = BloodBodyPartType.Torso_Upper
    G.shirt:getVisual():setHole(G.part)
    local holes = G.shirt:getVisual():getHole(G.part)
    check(holes > 0, "staged: the shirt is torn at the upper torso", holes, "> 0")
    LG.garmentWas = ISGarmentUI.windows[pn] ~= nil
    V.onInspectClothing(p, G.shirt)
end)
add(900, function()
    if SEC["the garment"] then return end
    local w = W()
    if not check(w ~= nil and w._drawerItem == G.shirt, "Inspect opens the shirt's item card in the Character window",
            w and w._drawerItem and w._drawerItem:getDisplayName(), G.shirt:getDisplayName()) then
        skip("the garment's card", "Inspect did not open it")
    end
    local card = w and w._itemCard
    check(card ~= nil and card._foldStates ~= nil and card._foldStates.clothing_zones == true, "the card opens with the garment's parts shown",
        card and card._foldStates and tostring(card._foldStates.clothing_zones), "true")
    check(ISGarmentUI.windows[pn] == nil, "vanilla's garment window stays shut", tostring(ISGarmentUI.windows[pn] ~= nil), "false")
    shot("13_garment_card")
    if SEC["the garment's card"] then return end
    local parts = G.shirt:getCoveredParts()
    for _, r in ipairs(card and card._zoneDockRects or {}) do
        if r.zoneIdx and r.zoneIdx >= 1 and r.zoneIdx <= parts:size() then
            local part = parts:get(r.zoneIdx - 1)
            if G.shirt:getVisual():getHole(part) > 0 and not G.torn then G.torn = r end
        end
    end
    check(G.torn ~= nil, "the torn part has its dock on the card", #(card and card._zoneDockRects or {}) .. " docks", "one on the torn part")
    if G.torn then card:_onZonePress(G.torn.zoneIdx, G.torn.zone, G.torn) end
end)
add(400, function()
    if SEC["the garment"] or SEC["the garment's card"] then return end
    if G.torn then
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
    end
    -- the card's PAD, pressed through its own controller element (A on it): what it asks the game for is caught
    local card = W()._itemCard
    local el = nil
    for _, e in ipairs(card and card:getActionStripElements() or {}) do if e.id == "verb_pad_all" then el = e end end
    if not check(el ~= nil and el.onActivate ~= nil, "the card offers PAD (padding) in its care band", el, "the PAD button") then return end
    G.asked = withQueueCaught(function() el.onActivate() end)
end)
add(300, function()
    if SEC["the garment"] or SEC["the garment's card"] or not G.asked then return end
    -- the parts that can take padding: no hole and no patch
    local want, parts = {}, G.shirt:getCoveredParts()
    for k = 0, parts:size() - 1 do
        local part = parts:get(k)
        if G.shirt:getVisual():getHole(part) <= 0 and G.shirt:getPatchType(part) == nil then want[#want + 1] = part end
    end
    local inv = p:getInventory()
    local bad, onTorn = nil, false
    for _, a in ipairs(G.asked) do
        local fine = a.Type == "ISRepairClothing" and a.clothing == G.shirt and a.fabric ~= nil and a.thread ~= nil and a.needle ~= nil
            and inv:containsRecursive(a.fabric) and inv:containsRecursive(a.thread) and inv:containsRecursive(a.needle)
        if a.part == G.part then onTorn = true end
        if not fine and not bad then bad = tostring(a.Type) .. (a.clothing == G.shirt and "" or " on another item") end
    end
    local covered = 0
    for _, part in ipairs(want) do
        for _, a in ipairs(G.asked) do if a.part == part then covered = covered + 1; break end end
    end
    check(#want > 0 and #G.asked == #want and covered == #want and not onTorn and bad == nil,
        "PAD asks for vanilla's padding on each untorn part (" .. #want .. "), with the needle, thread and strips carried, none on the torn part",
        #G.asked .. " asked, " .. covered .. " of the untorn parts" .. (onTorn and ", one on the torn part" or "") .. (bad and (", " .. bad) or ""),
        #want .. " ISRepairClothing")
    withSafeOn(function() ISInventoryPaneContextMenu.onInspectClothingUI(p, G.shirt) end)
end)
add(500, function()
    if SEC["the garment"] then return end
    if not G.asked then withSafeOn(function() ISInventoryPaneContextMenu.onInspectClothingUI(p, G.shirt) end) end
    local g = ISGarmentUI.windows[pn]
    check(g ~= nil and g.clothing == G.shirt, "with safe mode on, Inspect opens vanilla's garment window on the shirt",
        g and tostring(g.clothing == G.shirt), "true")
    shot("15_safe_garment")
    if g then g:close() end
end)
add(300, function()
    if SEC["the garment"] then return end
    check(ISGarmentUI.windows[pn] == nil, "vanilla's garment window closes", tostring(ISGarmentUI.windows[pn] ~= nil), "false")
    -- staged: the controller's marks on (the needle marked by A), then Inspect from the shirt's menu
    local w = W()
    local cnt = w and w._mainContent
    if not (cnt and w._updateDrawer and G.needle) then skip("Inspect with the controller's marks", "no inventory list to mark"); return end
    local sel = cnt._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    sel[G.needle] = true
    cnt._selectedItems = sel
    cnt._lastClickedItem = G.needle
    cnt._padMarks = true
    w._updateDrawer(cnt)
    ISInventoryPaneContextMenu.onInspectClothing(p, G.shirt)
end)
add(700, function()
    if SEC["the garment"] or SEC["Inspect with the controller's marks"] then return end
    local w = W()
    local g = ISGarmentUI.windows[pn]
    check(w._drawerItem == G.shirt and g == nil, "with the controller's marks on, Inspect still opens the shirt's card, not vanilla's garment window",
        "card " .. tostring(w._drawerItem == G.shirt) .. ", vanilla's window " .. tostring(g ~= nil), "card true, vanilla's window false")
    shot("16_marks_inspect")
    if g then g:close() end
    local cnt = w._mainContent
    local sel = cnt._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    cnt._lastClickedItem = nil
    cnt._padMarks = nil
    w._updateDrawer(cnt)
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
