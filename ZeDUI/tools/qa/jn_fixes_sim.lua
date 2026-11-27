-- ZeDUI/tools/qa/jn_fixes_sim.lua
-- (QA's Journal sweep, Nov 27 2026) One check group per bug fixed on the Journal tab: B6 blank entries, B8 the
-- delete question taken over, B12 the question outliving the tab, B9 the kills head too wide, B10 an old entry's
-- day, B3 the write-once lock, B2 Enter in the quick note, J45 the half card's page bar. Each runs the real code,
-- cut from the source files, with stubs; the checks fail on the code before the fixes.
-- Run from the repo root: lua51 ZeDUI/tools/qa/jn_fixes_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]jn_fixes_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readSrc(p) local fh = assert(io.open(ROOT .. p, "rb")); local s = fh:read("*a"):gsub("\r\n", "\n"); fh:close(); return s end
local function fnBody(src, head) return src:match("\n(" .. head .. ".-\nend)\n") end

local Z = "42/media/lua/client/ZeD/"
local jt = readSrc(Z .. "JournalTab.lua")
local cw = readSrc(Z .. "ZeD_CharacterWindow.lua")
local wn = readSrc(Z .. "ZeD_WriteNoteAction.lua")
local mo = readSrc(Z .. "Molecules.lua")
local jr = readSrc(Z .. "ZeD_JournalReaders.lua")

-- ---------------------------------------------------------------------------
-- B6: whitespace only is nothing to save
-- ---------------------------------------------------------------------------
do
    local body = fnBody(jt, "function ZeD%.JournalTab%.save%(")
    check("B6 finds JournalTab.save", body ~= nil)
    if body then
        local added, intoTried = 0, 0
        ZeD = { JournalTab = { pickedTags = function() return {} end, clearPicks = function() end },
                JournalReaders = { saveLog = function() intoTried = intoTried + 1; return false end,
                                   addLogEntry = function() added = added + 1 end } }
        assert(loadstring(body))()
        local win = {}
        check("B6 four spaces are refused", ZeD.JournalTab.save(win, "    ") == false and added == 0 and intoTried == 0, added)
        check("B6 tabs and new lines are refused", ZeD.JournalTab.save(win, " \t\n ") == false and added == 0)
        check("B6 words are kept", ZeD.JournalTab.save(win, "  Supply run ") == true and added == 1)
        check("B6 empty is refused", ZeD.JournalTab.save(win, "") == false and added == 1)
    end
end

-- ---------------------------------------------------------------------------
-- B8 and B9: the Character window's Journal clicks (cut between its own comments)
-- ---------------------------------------------------------------------------
local clickBlock = cw:match("\n(%s*%-%- Journal tags: a pick under the write box.-)\n%s*%-%- Notebooks / Papers / the log box's Into")
check("B8 finds the window's Journal clicks", clickBlock ~= nil)
if clickBlock then
    local clicks = assert(loadstring("local win, x, y, askJournalDelete = ...\n" .. clickBlock .. "\nreturn false"))
    local E1, E2 = { text = "one" }, { text = "two" }
    local function newWin()
        local entries = { E1, E2 }
        local w = {
            _activeTab = "journal", _journalSubTab = 1,
            _journalGroupZones = { { id = "1993-6", x = 18, y = 200, w = 300, h = 20 } },
            _journalGroupCollapsed = {},
            _journalDeleteZones = { { entryIdx = 1, x = 300, y = 240, w = 16, h = 16 }, { entryIdx = 2, x = 300, y = 280, w = 16, h = 16 } },
            _killsRowY = 100, _killsRowH = 20, _killsExpanded = false,
            _journalKillsZone = { x = 18, y = 100, w = 775, h = 20 },
            _playerObj = { getModData = function() return { ZeD_Journal = { entries = entries } } end },
        }
        return w, entries
    end
    local function ask(w, idx) local _, es = nil, w._playerObj:getModData().ZeD_Journal.entries; w._journalAsk = { entry = es[idx] }; return true end
    ZeD = { JournalTab = { onBodyClick = function() return false end } }

    local w = newWin()
    w._journalAsk = { entry = E1 }
    clicks(w, 305, 285, ask)
    check("B8 another cross does not take the question over", w._journalAsk.entry == E1, w._journalAsk.entry.text)
    clicks(w, 50, 205, ask)
    check("B8 a month head does not fold under the question", not w._journalGroupCollapsed["1993-6"])
    clicks(w, 50, 105, ask)
    check("B8 the kills head does not fold under the question", w._killsExpanded == false)

    w = newWin()
    clicks(w, 305, 285, ask)
    check("B8 with no question a cross asks about its entry", w._journalAsk and w._journalAsk.entry == E2)
    w = newWin()
    clicks(w, 50, 205, ask)
    check("B8 with no question a month head folds", w._journalGroupCollapsed["1993-6"] == true)

    w = newWin()
    clicks(w, 825, 110, ask)
    check("B9 a press beside the kills head (x 825, head 18+775) does not fold", w._killsExpanded == false)
    clicks(w, 10, 110, ask)
    check("B9 a press left of the head does not fold", w._killsExpanded == false)
    clicks(w, 400, 110, ask)
    check("B9 a press on the head folds", w._killsExpanded == true)
end

-- ---------------------------------------------------------------------------
-- B12: the question goes when the Journal tab is left
-- ---------------------------------------------------------------------------
do
    local askBody = fnBody(jt, "function ZeD%.JournalTab%.askDelete%(")
    local watch = jt:match("\n(ZeD%.JournalTab%._asking = .-ZeD%.JournalTab%._watchAsks = watchAsks)\n")
    check("B12 finds askDelete and the watch", askBody ~= nil and watch ~= nil)
    if askBody and watch then
        ZeD = { JournalTab = {} }
        local entries = { { text = "one" }, { text = "two" } }
        local function journalEntries() return entries end
        assert(loadstring("local journalEntries = ...\n" .. askBody))(journalEntries)
        assert(loadstring(watch))()
        local shown = true
        local win = { _activeTab = "journal", _drawerMode = "tab", _drawerOpen = true, isVisible = function() return shown end }
        ZeD.JournalTab.askDelete(win, nil, 1)
        ZeD.JournalTab._watchAsks()
        check("B12 the question stays while the Journal shows", win._journalAsk and win._journalAsk.entry == entries[1])
        win._activeTab = "skills"
        ZeD.JournalTab._watchAsks()
        check("B12 the question goes on a visit to Skills", win._journalAsk == nil)
        win._activeTab = "journal"
        ZeD.JournalTab._watchAsks()
        check("B12 back on the Journal: no question", win._journalAsk == nil)
        local n = 0
        for _ in pairs(ZeD.JournalTab._asking) do n = n + 1 end
        check("B12 nothing left in the watch", n == 0, n)
        ZeD.JournalTab.askDelete(win, nil, 2)
        shown = false
        ZeD.JournalTab._watchAsks()
        check("B12 the question goes when the window shuts", win._journalAsk == nil)
    end
end

-- ---------------------------------------------------------------------------
-- B10: an old entry's day on the real calendar
-- ---------------------------------------------------------------------------
do
    local block = jt:match("\n(local _monthDays = .-\nfunction ZeD%.JournalTab%.dayNumber%(.-\nend)\n")
    check("B10 finds the calendar count", block ~= nil)
    check("B10 the 30-day months are gone", jt:find("* 360 + (entry.month or 0) * 30", 1, true) == nil)
    if block then
        ZeD = { JournalTab = {} }
        assert(loadstring(block))()
        local d = ZeD.JournalTab.dayNumber
        -- the game's dates: month and day from 0; the start 1993-07-09 is (1993, 6, 8)
        local start = d(1993, 6, 8)
        check("B10 70 days after Jul 9 1993 (Sep 17) is Day 71", d(1993, 8, 16) - start + 1 == 71, d(1993, 8, 16) - start + 1)
        check("B10 the start day is Day 1", d(1993, 6, 8) - start + 1 == 1)
        check("B10 Jul 31 to Aug 1 is one day", d(1993, 7, 0) - d(1993, 6, 30) == 1)
        check("B10 1993 has 365 days", d(1994, 0, 0) - d(1993, 0, 0) == 365)
        check("B10 1996 is a leap year (366)", d(1997, 0, 0) - d(1996, 0, 0) == 366)
        check("B10 Feb 29 1996 sits before Mar 1", d(1996, 2, 0) - d(1996, 1, 28) == 1)
        check("B10 1900 is not a leap year", d(1900, 2, 0) - d(1900, 1, 0) == 28)
        check("B10 2000 is a leap year", d(2000, 2, 0) - d(2000, 1, 0) == 29)
    end
end

-- ---------------------------------------------------------------------------
-- B3: the quick note locks a write-once item as the game's write window does
-- ---------------------------------------------------------------------------
do
    local body = fnBody(wn, "function ZeD_WriteNoteAction:perform%(")
    check("B3 finds the write action's perform", body ~= nil)
    if body then
        ZeD_WriteNoteAction = {}
        ItemTag = { LOCK_ON_WRITE = "LOCK_ON_WRITE" }
        ZombRand = function(n) return 424242 end
        local synced = 0
        syncItemFields = function() synced = synced + 1 end
        ISBaseTimedAction = { perform = function() end }
        local N = { page = function() return "" end, append = function(a, b) return a .. b end, fits = function() return true end }
        assert(loadstring("local N, isBook = ...\n" .. body))(N, function() return false end)
        local function item(tag)
            return { pages = {}, locked = nil,
                hasTag = function(self, t) return t == tag end,
                seePage = function(self, i) return self.pages[i] end,
                addPage = function(self, i, s) self.pages[i] = s end,
                setLockedBy = function(self, by) self.locked = by end }
        end
        local function act(it) return { item = it, page = 1, text = "Name: Kate", character = { playSound = function() end } } end
        local card = item("LOCK_ON_WRITE")
        ZeD_WriteNoteAction.perform(act(card))
        check("B3 the ID card is written", card.pages[1] == "Name: Kate")
        check("B3 the ID card is locked by a random owner", card.locked == "424242", card.locked)
        check("B3 the lock is synced (after it is set)", synced == 1 and (body:find("setLockedBy", 1, true) or math.huge) < (body:find("syncItemFields", 1, true) or 0))
        local nb = item(nil)
        ZeD_WriteNoteAction.perform(act(nb))
        check("B3 a notebook stays open", nb.locked == nil and nb.pages[1] == "Name: Kate")
    end
end

-- ---------------------------------------------------------------------------
-- B2: Enter in a ZeD_TextEntry with an onSubmit
-- ---------------------------------------------------------------------------
do
    local cc = fnBody(mo, "function ZeD_TextEntry:createChildren%(")
    local pr = fnBody(mo, "function ZeD_TextEntry:prerender%(")
    check("B2 finds ZeD_TextEntry's children and prerender", cc ~= nil and pr ~= nil)
    if cc and pr then
        local function box(text)
            local e = { text = text or "", javaObject = { setMaxLines = function() end, setMaxTextLength = function() end } }
            e.onCommandEntered = function() end   -- (the game's own, empty: ISTextEntryBox.lua:16)
            function e:initialise() end
            function e:instantiate() end
            function e:setMultipleLine() end
            function e:getText() return self.text end
            function e:setText(s) self.text = s end
            function e:setWidth() end
            function e:setHeight() end
            return e
        end
        ISTextEntryBox = { onCommandEntered = function() end, new = function(_, t) return box(t) end }
        ISPanel = { createChildren = function() end }
        ZeD = { T = { borderS = { r = 0, g = 0, b = 0, a = 1 } } }
        ZeD_TextEntry = {}
        assert(loadstring(cc .. "\n" .. pr))()
        local function newEntry(withSubmit)
            local got = {}
            local te = { width = 200, height = 40, maxLines = 2, maxLength = 160 }
            function te:addChild(c) self.child = c end
            if withSubmit then te.onSubmit = function(_, t) got[#got + 1] = t end end
            ZeD_TextEntry.createChildren(te)
            return te, got
        end
        local te, got = newEntry(true)
        te._entry.text = "Water at the school"
        te._entry.onCommandEntered()
        check("B2 a one-line box's Enter submits", got[1] == "Water at the school", got[1])
        te._entry.text = "Water at the school\n"
        ZeD_TextEntry.prerender(te)
        check("B2 a box of lines: Enter's new line submits", got[2] == "Water at the school", got[2])
        check("B2 and the new line is taken out", te._entry.text == "Water at the school", te._entry.text)
        ZeD_TextEntry.prerender(te)
        check("B2 one submit per Enter", #got == 2, #got)
        local plain = newEntry(false)
        plain._entry.text = "line one\nline two"
        ZeD_TextEntry.prerender(plain)
        plain._entry.onCommandEntered()
        check("B2 a box with no onSubmit keeps its new lines", plain._entry.text == "line one\nline two")
        check("B2 the quick note sets an onSubmit", jr:find("e.onSubmit = function() J.writeNote(win) end", 1, true) ~= nil)
        local wbody = fnBody(jr, "function J%.writeNote%(")
        check("B2 one write at a time (Enter is not greyed as Write is)", wbody ~= nil
            and wbody:find("if s.pending and ISTimedActionQueue.hasAction(s.pending) then return end", 1, true) ~= nil)
    end
end

-- ---------------------------------------------------------------------------
-- J45: the Notebooks page bar at the half card
-- ---------------------------------------------------------------------------
do
    local bar = jr:match("%-%- the page bar: < Page n of N >, Open full\n(%s*local page = pageOf%(win, b%)\n.-\n%s*py = py %+ T%.buttonH %+ T%.sp%.sm)\n")
    local pbw = fnBody(jr, "function J%.pageBarW%(")
    check("J45 finds the page bar", bar ~= nil)
    if bar then
        local chunk = assert(loadstring("local pageOf, win, b, ZeD, tw, f3, T, J, pw, px, py, button, panel, s, fh, dc, N, p, ISInventoryPaneContextMenu = ...\n"
            .. bar .. "\nreturn py"))
        local J = {}
        if pbw then assert(loadstring("local J = ...\n" .. pbw))(J) end
        local function run(pw, perChar)
            local rects = {}
            local Ts = { buttonH = 24, sp = { md = 10, sm = 4 }, px = function(n) return n end }
            local tw = function(_, str) return #str * perChar end
            local function button(_, _, id, x, y, text, _, _, opts)
                local w = tw(nil, text) + Ts.sp.md * 2
                rects[id] = { x = x, y = y, w = w, h = Ts.buttonH }
                return w
            end
            local texts = {}
            local panel = { drawText = function(_, str, x, y) texts[#texts + 1] = { s = str, x = x, y = y, w = tw(nil, str) } end }
            local Zs = { tr = function(k, a, b2) if k == "UI_ZeD_Reader_PageOf" then return "Page " .. a .. " of " .. b2 end return "Open full" end,
                         btnCase = function(str) return str end }
            local book = { getID = function() return 7 end, getPageToWrite = function() return 10 end, isEmptyPages = function() return false end }
            local N = { otherLock = function() return false end, hasWritingTool = function() return true end }
            local pl = { tooDarkToRead = function() return false end, getPlayerNum = function() return 0 end }
            local endY = chunk(function() return 10 end, {}, book, Zs, tw, "f3", Ts, J, pw, 10, 100, button, panel, { nbPage = {} },
                function() return 16 end, { r = 1, g = 1, b = 1 }, N, pl, {})
            return rects, texts, endY
        end
        local function overlap(a, b) return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
        local function inside(r, px0, pw) return r.x >= px0 and r.x + r.w <= px0 + pw end
        for _, c in ipairs({ { "normal", 8 }, { "Large text", 10 } }) do
            local pw = 196   -- the half card's room, near 220 less its margins
            local r, t = run(pw, c[2])
            local label = t[#t]
            local labelR = label and { x = label.x, y = label.y, w = label.w, h = 16 }
            check("J45 half card, " .. c[1] .. ": > clear of Open full", r.next and r.full and not overlap(r.next, r.full),
                r.next and r.full and (r.next.x .. "+" .. r.next.w .. " vs " .. r.full.x .. "+" .. r.full.w))
            check("J45 half card, " .. c[1] .. ": the page line clear of Open full", labelR and r.full and not overlap(labelR, r.full))
            check("J45 half card, " .. c[1] .. ": every button inside the card", r.prev and r.next and r.full
                and inside(r.prev, 10, pw) and inside(r.next, 10, pw) and inside(r.full, 10, pw))
        end
        local r, _, endY = run(460, 8)
        check("J45 full card: one row", r.next and r.full and r.next.y == r.full.y and endY == 100 + 24 + 4, endY)
        local r2, t2 = run(130, 10)
        check("J45 very narrow: the page line shortens to n/N", t2[#t2] and t2[#t2].s == "10/10", t2[#t2] and t2[#t2].s)
        check("J45 very narrow: > still clear of Open full", r2.next and r2.full and not overlap(r2.next, r2.full))
    end
end

print("jn_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
