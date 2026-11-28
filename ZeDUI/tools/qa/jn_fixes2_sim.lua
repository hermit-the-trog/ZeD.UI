-- ZeDUI/tools/qa/jn_fixes2_sim.lua
-- (QA's Journal sweep, second batch, Nov 27 2026) One check group per bug fixed: J20 Save twice while the
-- Into write runs, J8 the striped entry's height, J29 a notebook in a bag (Put things back on), J40 the pad's
-- Down from a tag past an entry with no tags, and the delete question's watch keeping a shut window. Each runs
-- the real code, cut from the source files, with stubs; the checks fail on the code before the fixes.
-- Run from the repo root: lua51 ZeDUI/tools/qa/jn_fixes2_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]jn_fixes2_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readSrc(p) local fh = assert(io.open(ROOT .. p, "rb")); local s = fh:read("*a"):gsub("\r\n", "\n"); fh:close(); return s end
local function fnBody(src, head) return src:match("\n(" .. head .. ".-\nend)\n") end

local Z = "42/media/lua/client/ZeD/"
local jt = readSrc(Z .. "JournalTab.lua")
local wn = readSrc(Z .. "ZeD_WriteNoteAction.lua")
local jr = readSrc(Z .. "ZeD_JournalReaders.lua")
local pb = readSrc(Z .. "ZeD_PutBack.lua")
local sn = readSrc(Z .. "Input/SpatialNav.lua")

-- ---------------------------------------------------------------------------
-- A small world: one player, his main inventory, a schoolbag, the game's action queue
-- ---------------------------------------------------------------------------
local function container(kind)
    local c = { kind = kind, list = {} }
    function c:getType() return self.kind end
    function c:getItems()
        local l = self.list
        return { size = function() return #l end, get = function(_, i) return l[i + 1] end }
    end
    function c:add(it) self.list[#self.list + 1] = it; it.cont = self end
    function c:remove(it) for i = #self.list, 1, -1 do if self.list[i] == it then table.remove(self.list, i) end end; it.cont = nil end
    return c
end
local function world()
    local w = {}
    w.main, w.bag = container("none"), container("Bag_Schoolbag")
    w.book = { name = "ZQA notebook" }
    function w.book:getContainer() return self.cont end
    function w.book:getFullType() return "Base.Notebook" end
    function w.book:getName() return self.name end
    w.bag:add(w.book)
    local main = w.main
    w.p = { _player = true }
    function w.p:getInventory() return main end
    function w.p:isLocalPlayer() return true end
    function w.p:getPrimaryHandItem() return nil end
    function w.p:getSecondaryHandItem() return nil end
    function w.p:isEquippedClothing() return false end
    function w.p:isAttachedItem() return false end
    function w.p:getPlayerNum() return 0 end
    return w
end
local queues = {}
local function setupQueue()
    queues = {}
    ISTimedActionQueue = {}
    -- (the queues look their methods up on ISTimedActionQueue, so Put back's wrapped onCompleted is the one run)
    local Q = { __index = ISTimedActionQueue }
    function ISTimedActionQueue:indexOf(a) for i, v in ipairs(self.queue) do if v == a then return i end end return -1 end
    function ISTimedActionQueue:onCompleted(a) local i = self:indexOf(a); if i ~= -1 then table.remove(self.queue, i) end end
    function ISTimedActionQueue:resetQueue() self.queue = {} end
    ISTimedActionQueue.getTimedActionQueue = function(chr)
        local q = queues[chr]
        if not q then q = setmetatable({ queue = {}, character = chr }, Q); queues[chr] = q end
        return q
    end
    ISTimedActionQueue.add = function(a) local q = ISTimedActionQueue.getTimedActionQueue(a.character); q.queue[#q.queue + 1] = a; return a, q end
    ISTimedActionQueue.hasAction = function(a) local q = a and queues[a.character]; return q ~= nil and q:indexOf(a) ~= -1 end
    ISTimedActionQueue.hasActionType = function(chr, t)
        local q = queues[chr]
        if not q then return false end
        for _, v in ipairs(q.queue) do if v.Type == t then return true end end
        return false
    end
end
local function newTransfer(chr, item, src, dst)
    return { Type = "ISInventoryTransferAction", character = chr, item = item, srcContainer = src, destContainer = dst }
end
local function stubGame()
    setupQueue()
    luautils = { haveToBeTransfered = function(p, item) return item:getContainer() ~= nil and item:getContainer() ~= p:getInventory() end }
    ISInventoryTransferUtil = { newInventoryTransferAction = newTransfer }
    ISInventoryTransferAction = { new = function(_, chr, item, src, dst) return newTransfer(chr, item, src, dst) end }
    ISUnequipAction = { new = function(_, chr, item) return { Type = "ISUnequipAction", character = chr, item = item } end }
    -- (the game's own, as ISInventoryPaneContextMenu.lua:1910 has it, for the code before the fix)
    ISInventoryPaneContextMenu = { transferIfNeeded = function(p, item)
        if luautils.haveToBeTransfered(p, item) then ISTimedActionQueue.add(newTransfer(p, item, item:getContainer(), p:getInventory())) end
    end }
    ZeD_WriteNoteAction = { new = function(_, chr, item, page, text, onDone)
        return { Type = "ZeD_WriteNoteAction", character = chr, item = item, page = page, text = text, onDone = onDone }
    end }
    instanceof = function(o, cls) return cls == "IsoPlayer" and type(o) == "table" and o._player == true end
end
local function loadNotes()
    local N = {}
    local w1, w2 = fnBody(wn, "function N%.write%("), fnBody(wn, "function N%.busy%(")
    assert(loadstring("local N = ...\n" .. (w1 or "") .. "\n" .. (w2 or "")))(N)
    return N, w1 ~= nil, w2 ~= nil
end

-- ---------------------------------------------------------------------------
-- J20: Save twice while the Into write runs: one write, one entry
-- ---------------------------------------------------------------------------
do
    local busyBody = fnBody(jr, "function J%.logBusy%(")
    local saveBody = fnBody(jr, "function J%.saveLog%(")
    check("J20 finds JR.logBusy and JR.saveLog", busyBody ~= nil and saveBody ~= nil)
    if saveBody then
        stubGame()
        local N = loadNotes()
        N.why = function() return nil end
        N.pageFor = function() return 1 end
        local w = world()
        local states = {}
        local function st(win) states[win] = states[win] or {}; return states[win] end
        local J = {}
        local added = 0
        J.addLogEntry = function() added = added + 1 end
        ZeD = { tr = function(k) return k end, JournalTab = { clearPicks = function() end } }
        local win = { _playerObj = w.p, _journalInput = { clear = function() end } }
        local function logBook() return w.book end
        assert(loadstring("local J, st, N, logBook = ...\n" .. (busyBody or "") .. "\n" .. saveBody))(J, st, N, logBook)
        J.saveLog(win, "Water at the school", nil)
        local q = queues[w.p].queue
        local n1 = #q
        J.saveLog(win, "Water at the school", nil)   -- the mouse's second press
        J.saveLog(win, "Water at the school", nil)   -- the pad's A
        local writes = 0
        for _, a in ipairs(q) do if a.Type == "ZeD_WriteNoteAction" then writes = writes + 1 end end
        check("J20 a second and third Save while it writes queue nothing more", #q == n1 and writes == 1, #q .. " queued (were " .. n1 .. "), " .. writes .. " writes")
        check("J20 Save reads busy while the move out of the bag runs", J.logBusy and J.logBusy(win) == true)
        -- the move ends, the write runs (still busy), then ends: its line logged once
        table.remove(q, 1)
        check("J20 still busy while the write itself runs", J.logBusy and J.logBusy(win) == true)
        local wa = table.remove(q, 1)
        if wa and wa.onDone then wa.onDone(1) end
        check("J20 the line is logged once", added == 1, added)
        check("J20 Save is free once it is written", J.logBusy and J.logBusy(win) == false)
        J.saveLog(win, "Second line", nil)
        check("J20 the next Save writes again", #q >= 1 and q[#q].Type == "ZeD_WriteNoteAction", #q)
        -- a quick note's write (Notebooks) queued for him counts too
        for i = #q, 1, -1 do q[i] = nil end
        states[win] = {}
        q[1] = { Type = "ZeD_WriteNoteAction", character = w.p }
        check("J20 any of ZeD's writes queued for him holds Save", J.logBusy and J.logBusy(win) == true)
    end
    local saveJT = fnBody(jt, "function ZeD%.JournalTab%.save%(")
    check("J20 finds JournalTab.save", saveJT ~= nil)
    if saveJT then
        local added, busy = 0, true
        ZeD = { JournalTab = { pickedTags = function() return {} end, clearPicks = function() end },
                JournalReaders = { logBusy = function() return busy end, saveLog = function() return false end,
                                   addLogEntry = function() added = added + 1 end } }
        assert(loadstring(saveJT))()
        local win = {}
        ZeD.JournalTab.save(win, "Words")
        check("J20 JournalTab.save refuses while a write runs (log only too)", added == 0, added)
        busy = false
        ZeD.JournalTab.save(win, "Words")
        check("J20 JournalTab.save keeps it once the write is done", added == 1, added)
    end
    check("J20 Save is greyed while busy (the band sets the button's disabled)",
        jt:find("saveBtn._zedOpts.disabled = (JR and JR.logBusy and JR.logBusy(win)) and true or nil", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
-- J29: a notebook in a bag goes back into it after the write (Put things back on: the director's call, Nov 27 2026)
-- ---------------------------------------------------------------------------
do
    stubGame()
    local N, hasWrite = loadNotes()
    check("J29 finds N.write", hasWrite)
    -- Put things back, the real file, on
    require = function() end
    Events = { OnTick = { Add = function() end }, OnGameBoot = { Add = function() end } }
    ZeD = { Safe = { on = function() return false end }, Settings = { putBackOn = function() return true end } }
    local _print = print
    print = function() end
    assert(loadstring(pb))()
    print = _print
    local w = world()
    local wa = N.write(w.p, w.book, 1, "From the bag", function() end)
    local q = queues[w.p].queue
    check("J29 the move out of the bag is queued before the write", #q == 2 and q[1].Type == "ISInventoryTransferAction"
        and q[2] == wa, #q .. ": " .. tostring(q[1] and q[1].Type) .. ", " .. tostring(q[2] and q[2].Type))
    -- the move runs: the book is in his main inventory; then the write ends
    w.bag:remove(w.book); w.main:add(w.book)
    local mv = table.remove(q, 1)
    queues[w.p]:onCompleted(mv)
    queues[w.p]:onCompleted(wa)
    local back = 0
    for _, a in ipairs(q) do if a.Type == "ISInventoryTransferAction" and a.item == w.book and a.destContainer == w.bag then back = back + 1 end end
    check("J29 Put things back on: the book goes back into its bag after the write", back == 1, back .. " moves back queued")
    -- the control: a plain action with a move in its run is still put back (Put back itself unchanged)
    local w2 = world()
    ISTimedActionQueue.add(newTransfer(w2.p, w2.book, w2.bag, w2.main))
    local other = { Type = "ISReadABook", character = w2.p }
    ISTimedActionQueue.add(other)
    local q2 = queues[w2.p].queue
    w2.bag:remove(w2.book); w2.main:add(w2.book)
    queues[w2.p]:onCompleted(table.remove(q2, 1))
    queues[w2.p]:onCompleted(other)
    local back2 = 0
    for _, a in ipairs(q2) do if a.Type == "ISInventoryTransferAction" and a.destContainer == w2.bag then back2 = back2 + 1 end end
    check("J29 control: Put back still returns another action's book", back2 == 1, back2)
    -- MP53 (the director's call): an action marked _zedBackLater (the game's Read Map with ZeD's paper up) holds its
    -- move back until the thing is put away (PB.release, from the paper's fold)
    local w3 = world()
    ISTimedActionQueue.add(newTransfer(w3.p, w3.book, w3.bag, w3.main))
    local rd = { Type = "ISReadMapItem", character = w3.p, item = w3.book }
    ISTimedActionQueue.add(rd)
    local q3 = queues[w3.p].queue
    w3.bag:remove(w3.book); w3.main:add(w3.book)
    queues[w3.p]:onCompleted(table.remove(q3, 1))
    rd._zedBackLater = true   -- (set by ISReadMapItem:showUI when ZeD's paper is up)
    queues[w3.p]:onCompleted(rd)
    local function backs3()
        local n = 0
        for _, a in ipairs(q3) do if a.Type == "ISInventoryTransferAction" and a.destContainer == w3.bag then n = n + 1 end end
        return n
    end
    check("MP53 Put back holds the read map's move back while the paper is up", backs3() == 0, backs3())
    check("MP53 ... the fold releases it: the map goes back where it came from", ZeD.PutBack.release(w3.book) == true and backs3() == 1, backs3())
    check("MP53 ... once", ZeD.PutBack.release(w3.book) == false and backs3() == 1, backs3())
end

-- ---------------------------------------------------------------------------
-- J8: the striped entry's stripe is the entry's whole height
-- ---------------------------------------------------------------------------
do
    local body = fnBody(jt, "function ZeD%.JournalTab%.entryH%(")
    check("J8 finds JournalTab.entryH", body ~= nil)
    if body then
        ZeD = { JournalTab = {} }
        assert(loadstring(body))()
        -- 4K: head 36, gap 6, line 32 (+4), xs 8: the head row, its gap, 7 lines, xs
        local h = ZeD.JournalTab.entryH(36, 6, 7, 32, 4, 8)
        check("J8 a 7-line entry: head, gap, 7 lines and xs", h == 36 + 6 + 7 * 36 + 8, h)
        check("J8 longer than the old stripe (head, one line, xs)", h > 36 + 32 + 8)
    end
    check("J8 the stripe is drawn at entryH with the entry's lines",
        jt:find("ZeD.JournalTab.entryH(headH, T.sp.rowGap, #lines, bodyH, T.px(2), T.sp.xs)", 1, true) ~= nil)
    check("J8 the old one-line stripe is gone", jt:find("drawW, bodyH + headH + T.sp.xs", 1, true) == nil)
    -- the layout the stripe has to match: the same steps
    check("J8 the layout steps match entryH", jt:find("curY = curY + headH + T.sp.rowGap", 1, true) ~= nil
        and jt:find("curY = curY + bodyH + T.px(2)", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
-- J40: Down from a tag reaches the next entry (one with no tags) before Save
-- ---------------------------------------------------------------------------
do
    local block = jt:match("\n(local ROW_KINDS = .-\nlocal function tagDpad%(.-\nend)\n")
    check("J40 finds rowStep and the tags' D-pad", block ~= nil)
    ZeD = { JournalTab = {} }
    assert(loadstring(sn))()
    local SN = ZeD.SpatialNav
    -- entry 2: two tags left of its cross (they end 8 px short); entry 3: no tags; entry 4: a tag; Save in the band
    local function els()
        return {
            { id = "journal:tag:2:food", journalKind = "tag", x = 600, y = 300, w = 70, h = 24 },
            { id = "journal:tag:2:loot", journalKind = "tag", x = 680, y = 300, w = 70, h = 24 },
            { id = "journal:del:2", journalKind = "delete", x = 758, y = 302, w = 20, h = 20 },
            { id = "journal:del:3", journalKind = "delete", x = 758, y = 362, w = 20, h = 20 },
            { id = "journal:tag:4:base", journalKind = "tag", x = 600, y = 420, w = 60, h = 24 },
            { id = "journal:del:4", journalKind = "delete", x = 758, y = 422, w = 20, h = 20 },
            { id = "journal:__save", journalKind = "save", x = 700, y = 600, w = 70, h = 24 },
        }
    end
    local e = els()
    -- the plain pick, as the bug had it: the lined-up stop that way
    local plain, pt = SN.pick(e[2], { e[3], e[4], e[5], e[6], e[7] }, "down")
    check("J40 setup: the plain pick from tag:2:loot goes to Save (the bug's geometry)", plain == e[7], plain and plain.id)
    if block then
        local focusedId = nil
        ZeD.Input = { Focus = { focusWhere = function(w, zone, pred)
            for _, z in ipairs(w._focusRing) do
                if z.zone == zone then for _, el in ipairs(z.elements) do if pred(el) then focusedId = el.id; return el end end end
            end
            return nil
        end } }
        ZeD.uiSound = function() end
        local tagDpad = assert(loadstring(block .. "\nreturn tagDpad"))()
        local RS = ZeD.JournalTab.rowStep
        local to = RS(e, e[2], "down")
        check("J40 Down from entry 2's tag lands on entry 3's cross", to == e[4], to and to.id)
        to = RS(e, e[1], "down")
        check("J40 Down from entry 2's first tag lands on entry 3's cross", to == e[4], to and to.id)
        to = RS(e, e[5], "up")
        check("J40 Up from entry 4's tag lands on entry 3's cross", to == e[4], to and to.id)
        -- the last row: the plain pick (Save) keeps it
        check("J40 Down from the last row's tag is left to the plain pick (Save)", RS(e, e[5], "down") == nil)
        -- a month head between the rows (full width, lined up): the plain pick keeps it
        local e3 = els()
        e3[#e3 + 1] = { id = "journal:group:1993-7", journalKind = "group", x = 18, y = 335, w = 760, h = 15 }
        check("J40 a month head in between is left to the plain pick", RS(e3, e3[2], "down") == nil)
        -- the next row's tag nearer across than its cross: the tag
        local e4 = els()
        local t3 = { id = "journal:tag:3:food", journalKind = "tag", x = 560, y = 360, w = 40, h = 24 }
        e4[#e4 + 1] = t3
        to = RS(e4, e4[1], "down")
        check("J40 the next row's nearest stop across (its tag, before entry 4's lined-up tag)", to == t3, to and to.id)
        local e5 = els()
        local t3b = { id = "journal:tag:3:loot", journalKind = "tag", x = 690, y = 360, w = 60, h = 24 }
        e5[#e5 + 1] = t3b
        check("J40 a next-row tag already lined up is left to the plain pick", RS(e5, e5[2], "down") == nil
            and SN.pick(e5[2], { e5[3], e5[4], e5[5], e5[6], e5[7], t3b }, "down") == t3b)
        check("J40 Left and Right are left to the plain pick", RS(e, e[2], "right") == nil and RS(e, e[2], "left") == nil)
        check("J40 a cross keeps its plain pick", RS(e, e[3], "down") == nil)
        -- the stop's handler moves the focus there and takes the press
        local win = { _focusRing = { { zone = "journalSub", focusable = true, elements = e } } }
        local took = tagDpad(win, e[2], "down")
        check("J40 the tag stop's D-pad moves the focus to entry 3's cross", took == true and focusedId == "journal:del:3", tostring(took) .. " " .. tostring(focusedId))
        focusedId = nil
        check("J40 the tag stop's Right goes to the plain pick", tagDpad(win, e[2], "right") == false and focusedId == nil)
    end
    check("J40 the entries' tag stops carry the D-pad handler", jt:find("onActivate = tagActivate, onDpadDir = tagDpad", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
-- The delete question's watch: a shut window leaves it
-- ---------------------------------------------------------------------------
do
    local askBody = fnBody(jt, "function ZeD%.JournalTab%.askDelete%(")
    local watch = jt:match("\n(ZeD%.JournalTab%._asking = .-ZeD%.JournalTab%._watchAsks = watchAsks)\n")
    check("Ask watch: finds askDelete and the watch", askBody ~= nil and watch ~= nil)
    if askBody and watch then
        ZeD = { JournalTab = {} }
        local entries = { { text = "one" }, { text = "two" } }
        local function journalEntries() return entries end
        assert(loadstring("local journalEntries = ...\n" .. askBody))(journalEntries)
        assert(loadstring(watch))()
        local reg = {}
        ZeD_CharacterWindow = { getWindow = function(pn) return reg[pn or 0] end }
        -- a window taken off the UI manager still answers visible
        local function newWin() return { playerNum = 0, _activeTab = "journal", _drawerMode = "tab", _drawerOpen = true, isVisible = function() return true end } end
        local function count() local n = 0; for _ in pairs(ZeD.JournalTab._asking) do n = n + 1 end; return n end
        local win = newWin()
        reg[0] = win
        ZeD.JournalTab.askDelete(win, nil, 1)
        ZeD.JournalTab._watchAsks()
        check("Ask watch: the question stays while his window is open", win._journalAsk ~= nil and count() == 1)
        reg[0] = nil   -- shut (toggle drops it from the registry and the UI manager)
        ZeD.JournalTab._watchAsks()
        check("Ask watch: a shut window's question is dropped", win._journalAsk == nil)
        check("Ask watch: and the window leaves the watch", count() == 0, count())
        -- opened again: a new window; the old one, asked again by a stale path, is not kept
        local win2 = newWin()
        reg[0] = win2
        ZeD.JournalTab.askDelete(win, nil, 2)
        ZeD.JournalTab._watchAsks()
        check("Ask watch: an old window (not his open one) is not kept", win._journalAsk == nil and count() == 0, count())
        ZeD.JournalTab.askDelete(win2, nil, 2)
        ZeD.JournalTab._watchAsks()
        check("Ask watch: the open window's question stays", win2._journalAsk ~= nil and count() == 1)
        ZeD_CharacterWindow = nil
    end
end

print("jn_fixes2_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
