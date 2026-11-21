-- ZeDUI/tools/qa/vx_health.lua  (Nov 21 2026, QA beast day; tag vx_hlth)
-- The in-game proof of Build's fixes for W16, W17, W18 and W19 (commit 27545ddeb; the findings are in
-- ZeDUI/qa/audits/2026-11-21_beast_code_sweep.md). Run after zedqa_prelude.lua and rt_kit.lua. About half a minute.
-- Nothing here can hurt the character; god mode and invincible are still ON for the run and put back as found.
--
--   W16  TV Monthly read BEFORE ZeD was installed. Hidden facts on Find first, ZeD's own mark set aside, then the
--        game's own reading record gets one TV Monthly issue, staged so it prints FIRST in the record (the case
--        that broke): titles are tried until one prints first; if none does, the records that print before the
--        earliest one are set aside for the check (each an exact key, given back with its own value). Checked:
--        the record prints with "{", ZeD.Finds.has("tv") says yes, and the guide's Television page
--        (ZeD.Finds.tvPage) is no longer the locked "find TV Monthly" page.
--        The old code looked for "[TVMagazine_" and said no: the page stayed locked.
--        (The record is asked with the map's own containsKey: the game's isLiteratureRead also asks the sandbox's
--        literature cooldown, so a title read long ago says no while it is still in the record.)
--   W17  A skill book carried in a bag. The Skills tab is open at its Training materials; an unread skill book is
--        put inside a bag (the worn backpack, or a school bag given for the test). Checked: within the tab's next
--        re-reads (500 ms each) its own list (win._trainingCache) turns exactly one row from "missing" to
--        "collected"; moved to the main inventory it stays collected; taken away it is missing again.
--        The old code read only the top level of the main inventory: the row stayed "missing" in the bag.
--   W18  The Health tab's exercise block, measured. The game's exercise table (FitnessExercises.exercisesType) is
--        swapped for a counting stand-in for three seconds with the Health tab open and the figure unfolded: every
--        "does he have the item" test and every info build reads it once. Checked: the reads fit the clock the fix
--        promises (four state reads a second plus the fill block's two), most frames read nothing at all, the
--        exercise box's widest label is not measured again, the clocked state (win._healthEx) is rebuilt about
--        four times a second, 200 layout measures in one frame cost no more than one rebuild, and the state still
--        follows a dumbbell picked up and put down inside a second.
--        The old code read the table at least 7 times EVERY frame (the 7 item tests of the layout key, plus the
--        info block and Start), 3 to 5 of them a search of the whole inventory with its bags, and measured the 7
--        "Exercise: <name>" labels every frame; 200 measures cost 1400 reads.
--   W19  The body figure's colour tables. With the Health tab open for 60 frames: the figure's colour map is the
--        same table every frame, each part's colour table is the same table every frame, nobody wipes the map, and
--        the colours are still right (each part's colour is the one for its health).
--        The old code wiped the map every frame: 1 new map and 17 new colour tables per frame.
--        The medical check card's figure (the same fix in ObjectCardMedic.lua) needs a second player: SKIP here.
--
-- Faked for the measure only: the pointer is reported off every ZeD hot spot (ZeD.Atoms.mouseIn says no) so a
-- pointer resting on Start does not add its help line's reads, and ZeD.Molecules.popupMenuW counts the band's
-- labels (it measures as before). Put back: the exercise table, the pointer test, the label measure, the figure's
-- wipe function, the Hidden facts setting, ZeD's find mark, the reading record (the test issue removed, every
-- record set aside returned), the Skills tab's Find text and scroll, the book, the bag, the dumbbell, the
-- figure's fold, the window's roll-up hold, the windows and tab, god mode and invincible. grep "ZEDQA vx_hlth".
if not RT then print("ZEDQA vx_hlth ERR rt_kit.lua did not run first"); print("ZEDQA vx_hlth DONE"); return end
local Q = RT.make("vx_hlth")
Q.maxMs = 300000   -- (five minutes, then the put-back; the manifest's timeout is 420 s)
local p = RT.p
local pn = RT.pn
local X = {}
local S = { found = {}, tv = { held = {}, heldSet = {}, aside = {}, added = {} }, sk = {}, ex = {}, fg = {} }
local HT = ZeD and ZeD.HealthTab
local ST = ZeD and ZeD.SkillsTab
local F = ZeD and ZeD.Finds
local G = ZeD and ZeD.Guide
local CW = ZeD_CharacterWindow
if not (p and HT and HT.gatherData and ST and ST.gatherTrainingData and F and F.has and CW) then
    Q.check(false, "ZeD's Health tab, Skills tab, finds and Character window are loaded", "missing")
    Q.start()
    return
end
if ZEDQA_HOME then pcall(ZEDQA_HOME, "vx_hlth") end

-- ===================================================================== small helpers
-- every poll: the Character window stays drawn (it rolls up by itself when the pointer is away)
function X.hold()
    local w = RT.cw()
    if not w then return end
    pcall(function()
        w._autoShaded = false
        if w.windowShaded then w:setWindowShaded(false) end
        w._outSince = getTimestampMs() + 600000
    end)
end
-- wait (real time) until cond() or ms have gone, then fn(ok, ms waited)
function X.untilMs(ms, cond, fn)
    local t = {}
    Q.waitFor(1, 1000000, function()
        t.t = t.t or getTimestampMs()
        X.hold()
        local ok, r = pcall(cond)
        if ok and r then t.ok = true; return true end
        return getTimestampMs() - t.t >= ms
    end, function() fn(t.ok == true, getTimestampMs() - (t.t or getTimestampMs())) end)
end
-- every drawn frame until cond() says done (cond ends itself on a clock or a frame count); an error inside ends the
-- wait at once, and fn gets its text
function X.everyFrame(cond, fn)
    local st = {}
    Q.waitFor(1, 1000000, function()
        local ok, done = pcall(cond)
        if not ok then st.err = tostring(done); return true end
        return done and true or false
    end, function() fn(st.err) end)
end
function X.tab(id)
    RT.pairOpen()
    local ok = false
    pcall(function() ok = RT.charTab(id) end)
    if not ok then pcall(CW.openTab, pn, id) end
end
function X.carries(ft)
    local has = false
    pcall(function() has = p:getInventory():contains(ft, true) end)
    return has and true or false
end
function X.removeItem(it)
    if not it then return end
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
-- a thing given for this script (taken back by RT.takeBack too; the mark lets the put-back find it)
function X.give(ft)
    local it = RT.give(ft)
    if it then pcall(function() it:getModData().ZeDQA_vxh = true end) end
    return it
end
function X.recordText()
    local s = "?"
    pcall(function() s = tostring(p:getReadLiterature()) end)
    return s
end
function X.short(s, n)
    s = tostring(s)
    if #s > n then return s:sub(1, n) .. "..." end
    return s
end

-- ===================================================================== START: what was found, the guards
Q.step(5, function()
    local f = S.found
    f.god = p:isGodMod() and true or false
    f.inv = p:isInvincible() and true or false
    pcall(function() f.health = p:getBodyDamage():getOverallBodyHealth() end)
    p:setGodMod(true)
    p:setInvincible(true)
    f.open = RT.isOpen() and true or false
    local w = RT.cw()
    f.tab = w and w._activeTab or nil
    f.outSince = w and w._outSince or nil
    Q.say("found: god mode " .. tostring(f.god) .. ", invincible " .. tostring(f.inv) .. ", health " .. tostring(f.health)
        .. ", windows open " .. tostring(f.open) .. ", tab " .. tostring(f.tab))
end)

-- ===================================================================== W16: TV Monthly read before ZeD
-- a title in the game's reading record? The map's own key test (isLiteratureRead also asks the literature cooldown)
function X.inRecord(key)
    local map = S.tv.map
    if not map then pcall(function() map = p:getReadLiterature() end) end
    if not map then return false end
    local ok, has = pcall(function() return map:containsKey(key) end)
    if ok then return has == true end
    local text = X.recordText()
    return text:find("{" .. key .. "=", 1, true) ~= nil or text:find(", " .. key .. "=", 1, true) ~= nil
end
-- does the record print this title first ("{title=n, ...")?
function X.printsFirst(key)
    return X.recordText():sub(1, #key + 2) == "{" .. key .. "="
end
-- the records set aside (the real TV Monthly ones and those moved for the first place) that are back: back, of
function X.recordBack()
    local T = S.tv
    local back, want = 0, 0
    for _, list in ipairs({ T.aside, T.held }) do
        for _, h in ipairs(list) do
            want = want + 1
            if X.inRecord(h.key) then back = back + 1 end
        end
    end
    return back, want
end

Q.step(5, function()
    local T = S.tv
    local opt = ZeD.Settings and ZeD.Settings.hiddenFactsOption
    if not (opt and F.tvPage) then
        Q.check(false, "W16: the Hidden facts setting and the TV page are there", "missing")
        return
    end
    T.opt = opt
    pcall(function() T.optWas = opt:getValue() end)
    pcall(function() T.marksWas = p:getModData().ZeD_Finds end)
    T.staged = true
    -- Find first, and no ZeD mark: the character as someone who read the magazine before ZeD was installed
    pcall(function() opt:setValue(1) end)
    pcall(function() p:getModData().ZeD_Finds = nil end)
    if G then G._rulesC = {} end
    if F.always() then
        Q.skip("W16: TV Monthly read before ZeD", "Hidden facts stays on Always here, every page is open without a find")
        T.skip = true
        return
    end
    local map = nil
    pcall(function() map = p:getReadLiterature() end)
    if not map then Q.check(false, "W16: the game's reading record can be read", "nil"); T.skip = true; return end
    T.map = map
    -- the record can be asked and taken from? (tried before anything is added, so the test never leaves a title behind)
    local okR = pcall(function() map:remove("zedqa_vx_none") end)
    local okK = pcall(function() return map:containsKey("zedqa_vx_none") end)
    if not (okR and okK) then
        Q.skip("W16: TV Monthly read before ZeD", "this game build will not let a script ask or take a title off the reading record, so nothing was added")
        T.skip = true
        return
    end
    -- real TV Monthly records of this character are set aside (returned right after the check and in the put-back)
    local text0 = X.recordText()
    for key, val in text0:gmatch("(TVMagazine_[^=,}]*)=(%-?%d+)") do
        if not T.heldSet[key] and X.inRecord(key) then
            T.heldSet[key] = true
            T.held[#T.held + 1] = { key = key, val = tonumber(val) or 0 }
        end
    end
    for _, h in ipairs(T.held) do pcall(function() map:remove(h.key) end) end
    Q.say("W16 the record before: " .. X.short(text0, 160) .. " (" .. #T.held .. " real TV Monthly record(s) set aside)")
    local lockedBefore = false
    pcall(function() local pg = F.tvPage(); lockedBefore = pg ~= nil and pg.locked == true end)
    local hasBefore = F.has("tv", p)
    T.clean = Q.check(hasBefore == false and lockedBefore, "W16 stage: nothing read yet, the Television page is the locked one",
        "has " .. tostring(hasBefore) .. ", locked " .. tostring(lockedBefore))
    -- one issue (the game's own day as its value, as a read gives it), tried under different titles until it prints
    -- FIRST in the record (the old code's blind spot); the earliest one is kept in mind
    local tries, best, bestPos = 0, nil, nil
    for year = 1993, 1996 do
        for month = 1, 12 do
            local title = "TVMagazine_" .. month .. "_" .. year
            if not T.title and not T.heldSet[title] and not X.inRecord(title) then
                tries = tries + 1
                T.added[#T.added + 1] = title
                pcall(function() p:addReadLiterature(title) end)
                if X.printsFirst(title) then
                    T.title = title
                else
                    local pos = X.recordText():find(", " .. title .. "=", 1, true)
                    if pos and (bestPos == nil or pos < bestPos) then best, bestPos = title, pos end
                    pcall(function() map:remove(title) end)
                end
            end
        end
    end
    if not T.title and best then
        -- no title printed first (a record sits in the map's first slot): the earliest one goes back on and the records
        -- that print before it are set aside, one by one, each an exact key of the record (given back with its value)
        T.title = best
        pcall(function() p:addReadLiterature(best) end)
        for _ = 1, 1000 do
            if X.printsFirst(best) then break end
            local k, v = X.recordText():match("^{([^=]+)=(%-?%d+)[,}]")
            if not k or k == best or not X.inRecord(k) then break end
            T.aside[#T.aside + 1] = { key = k, val = tonumber(v) or 0 }
            pcall(function() map:remove(k) end)
            if X.inRecord(k) then break end
        end
    end
    T.first = T.title ~= nil and X.printsFirst(T.title)
    if G then G._rulesC = {} end
    if not T.title then
        Q.check(false, "W16 stage: a test issue went on the reading record", tries .. " title(s) tried, none held")
        return
    end
    Q.say("W16 the record now: " .. X.short(X.recordText(), 160) .. " (title " .. tostring(T.title) .. ", " .. tries
        .. " tried, " .. #T.aside .. " record(s) set aside for the first place)")
end)
Q.step(3, function()
    local T = S.tv
    if T.skip or not T.staged or not T.title then return end
    local text = X.recordText()
    local inRec = X.inRecord(T.title)
    Q.check(inRec and text:sub(1, 1) == "{", "W16 stage: the game's reading record holds the issue and prints with a curly bracket",
        "in the record " .. tostring(inRec) .. ", starts " .. text:sub(1, 1))
    if T.first then
        Q.check(X.printsFirst(T.title), "W16 stage: the issue prints first in the record (the case the old code missed)",
            X.short(text, 80) .. (#T.aside > 0 and (" (" .. #T.aside .. " record(s) that printed before it set aside for the check)") or ""))
    else
        Q.skip("W16: the issue printed first in the record", "a record before it could not be read back exactly, so it was not moved; the two lines below would pass on the old code too")
    end
    local has = F.has("tv", p)
    Q.check(has == true, "W16: ZeD counts a TV Monthly the game has on record with no ZeD mark" .. (T.first and " (old code: false)" or ""),
        "has " .. tostring(has))
    local pg = nil
    pcall(function() pg = F.tvPage() end)
    local locked = pg ~= nil and pg.locked == true
    Q.check(pg ~= nil and not locked, "W16: the guide's Television page is open" .. (T.first and " (old code: locked, find TV Monthly)" or ""),
        "locked " .. tostring(locked) .. ", columns " .. tostring(pg and pg.cols and #pg.cols) .. ", rows " .. tostring(pg and pg.rows and #pg.rows))
end)
-- W16's own put-back at once (again in the put-back, should a step above throw)
function X.tvBack()
    local T = S.tv
    if not T.staged then return end
    if T.map then
        -- (the test titles were never real records: each was checked against the record and the set-aside list)
        for _, title in ipairs(T.added) do pcall(function() T.map:remove(title) end) end
        for _, list in ipairs({ T.aside, T.held }) do
            for _, h in ipairs(list) do
                if not X.inRecord(h.key) then pcall(function() p:addReadLiterature(h.key, h.val) end) end
            end
        end
    end
    if T.optWas ~= nil then pcall(function() T.opt:setValue(T.optWas) end) end
    pcall(function() p:getModData().ZeD_Finds = T.marksWas end)
    if G then G._rulesC = {} end
end
Q.step(3, function()
    local T = S.tv
    X.tvBack()
    if T.skip or not T.staged or not T.title then return end
    local still = X.inRecord(T.title)
    local back, want = X.recordBack()
    Q.check(not still and back == want, "W16: the test issue is off the reading record and every record set aside is back",
        "test issue still there " .. tostring(still) .. ", records back " .. back .. " of " .. want .. "; " .. X.short(X.recordText(), 120))
    if T.clean and #T.held == 0 then
        local has = F.has("tv", p)
        local optNow = nil
        pcall(function() optNow = T.opt:getValue() end)
        if optNow == 1 and not T.marksWas then
            Q.check(has == false, "W16: with the issue gone again the page is locked again (nothing stale)", "has " .. tostring(has))
        end
    end
end)

-- ===================================================================== W17: a skill book in a bag
local BOOKS = { "Base.BookCarpentry1", "Base.BookCooking1", "Base.BookFishing1", "Base.BookTrapping1", "Base.BookMechanic1",
                "Base.BookElectrician1", "Base.BookFarming1", "Base.BookForaging1", "Base.BookTailoring1", "Base.BookMasonry1",
                "Base.BookPottery1", "Base.BookCarving1", "Base.BookGlassmaking1", "Base.BookBlacksmith1" }
-- the tab's list as one flat list of rows
function X.rows()
    local w = RT.cw()
    local out = {}
    for _, g in ipairs(w and w._trainingCache or {}) do
        for _, b in ipairs(g.items or {}) do
            out[#out + 1] = { group = tostring(g.disp or g.label), vol = tostring(b.volume), title = tostring(b.title), status = tostring(b.status) }
        end
    end
    return out
end
-- the rows whose status differs from the base line
function X.changed()
    local now = X.rows()
    local base = S.sk.base or {}
    local diff = {}
    if #now ~= #base then return diff, now end
    for i = 1, #now do
        if now[i].status ~= base[i].status then diff[#diff + 1] = { i = i, was = base[i].status, now = now[i].status, row = now[i] } end
    end
    return diff, now
end
function X.diffText(diff)
    local t = {}
    for i, d in ipairs(diff) do
        if i <= 4 then t[#t + 1] = d.row.group .. " " .. d.row.vol .. " (" .. d.row.title .. "): " .. d.was .. " to " .. d.now end
    end
    return #diff .. " row(s) changed" .. (#t > 0 and (": " .. table.concat(t, "; ")) or "")
end
-- the tab re-read its list: a new table on win._trainingCache
function X.rereads()
    local w = RT.cw()
    local c = w and w._trainingCache
    if c ~= S.sk.lastCache then S.sk.lastCache = c; S.sk.reads = (S.sk.reads or 0) + 1 end
    return S.sk.reads or 0
end
function X.skillsBottom()
    local w = RT.cw()
    local s = w and w._skillsScroll
    if s and s.setScrollPos then pcall(function() s:setScrollPos(1) end) end
end

Q.step(5, function() X.tab("skills") end)
X.untilMs(4000, function() local w = RT.cw(); return w and w._activeTab == "skills" and w._trainingCache ~= nil and w._skillsScroll ~= nil end, function(ok)
    local K = S.sk
    local w = RT.cw()
    K.ready = Q.check(ok, "W17 stage: the Skills tab is open with its Training materials list", "tab " .. tostring(w and w._activeTab))
    if not ok then return end
    K.scrollWas = w._skillsScroll.scrollPos
    -- a Find text left on the tab could hide the list (it is re-read only while drawn): cleared for the check
    local TF = ZeD.TabFind
    if TF and TF.text and TF.setText then
        local txt = TF.text(w, "skills")
        if txt ~= nil and txt ~= "" then
            K.findWas = txt
            pcall(TF.setText, w, "skills", "")
            Q.say("W17 the Skills tab's Find text \"" .. tostring(txt) .. "\" cleared for the check (put back after)")
        end
    end
    X.skillsBottom()   -- (the list is re-read only while the section shows in the scroll view)
end)
Q.step(10, function()
    local K = S.sk
    if not K.ready then return end
    -- an unread skill book the character does not carry anywhere
    for _, ft in ipairs(BOOKS) do
        if not K.ft then
            local okB, free = pcall(function()
                return p:getAlreadyReadPages(ft) == 0 and not p:getAlreadyReadBook():contains(ft) and not X.carries(ft)
            end)
            if okB and free then K.ft = ft end
        end
    end
    if not K.ft then Q.skip("W17: a skill book in a bag", "the character has read or carries every volume I tried"); K.ready = false; return end
    -- the bag: the worn backpack, else a school bag given for the test
    local bag = nil
    pcall(function()
        local b = p:getClothingItem_Back()
        if b and instanceof(b, "InventoryContainer") then bag = b end
    end)
    K.bagWhat = "the worn backpack"
    if not bag then
        bag = X.give("Base.Bag_Schoolbag")
        K.bagGiven = bag
        K.bagWhat = "a school bag in the main inventory"
        if bag and not instanceof(bag, "InventoryContainer") then bag = nil end
    end
    if not bag then Q.check(false, "W17 stage: a bag to put the book in", "none worn, none could be given"); K.ready = false; return end
    K.bag = bag
end)
-- the base line is read once the tab has re-read its list with the bag in place
X.untilMs(2500, function()
    if not S.sk.ready then return true end
    if not S.sk.t0 then S.sk.t0 = true; S.sk.reads = 0; S.sk.lastCache = RT.cw() and RT.cw()._trainingCache end
    X.skillsBottom()
    return X.rereads() >= 1
end, function(ok)
    local K = S.sk
    if not K.ready then return end
    if not Q.check(ok, "W17 stage: the tab re-reads its list while the section shows", "re-reads " .. tostring(K.reads)) then K.ready = false; return end
    K.base = X.rows()
    local okA, it = pcall(function() return K.bag:getInventory():AddItem(K.ft) end)
    K.book = okA and it or nil
    if K.book then pcall(function() local md = K.book:getModData(); md.ZeDQA_spawned = true; md.ZeDQA_vxh = true end) end
    if not K.book then Q.check(false, "W17 stage: the book went into the bag", tostring(it)); K.ready = false; return end
    K.reads = 0
    K.lastCache = RT.cw() and RT.cw()._trainingCache
    Q.say("W17 " .. K.ft .. " put inside " .. K.bagWhat .. "; the list has " .. #K.base .. " rows")
end)
X.untilMs(5000, function()
    if not S.sk.ready then return true end
    X.skillsBottom()
    local n = X.rereads()
    local diff = X.changed()
    return #diff > 0 or n >= 3
end, function(_, ms)
    local K = S.sk
    if not K.ready then return end
    local diff = X.changed()
    local one = #diff == 1 and diff[1].was == "missing" and diff[1].now == "collected"
    Q.check(one, "W17: a skill book inside a bag shows as collected (old code: it stayed missing)",
        X.diffText(diff) .. " after " .. ms .. " ms and " .. tostring(K.reads) .. " re-read(s) of the list")
    K.row = one and diff[1].i or nil
    -- the book moved to the main inventory (collected on the old code too)
    pcall(function() K.bag:getInventory():Remove(K.book) end)
    pcall(function() p:getInventory():AddItem(K.book) end)
    K.reads = 0
end)
X.untilMs(3000, function()
    if not S.sk.ready then return true end
    X.skillsBottom()
    return X.rereads() >= 2
end, function()
    local K = S.sk
    if not K.ready then return end
    local diff = X.changed()
    local inMain = false
    pcall(function() inMain = K.book:getContainer() == p:getInventory() end)
    Q.check(inMain and #diff == 1 and diff[1].now == "collected" and (K.row == nil or diff[1].i == K.row),
        "W17: moved to the main inventory the same row stays collected", "in main " .. tostring(inMain) .. ", " .. X.diffText(diff))
    X.removeItem(K.book)
    K.bookGone = true
    K.reads = 0
end)
X.untilMs(3000, function()
    if not S.sk.ready then return true end
    X.skillsBottom()
    local diff = X.changed()
    return X.rereads() >= 1 and #diff == 0
end, function(_, ms)
    local K = S.sk
    if not K.ready then return end
    local diff = X.changed()
    Q.check(#diff == 0, "W17: the book taken away, the row is missing again (nothing stale)", X.diffText(diff) .. " after " .. ms .. " ms")
end)
function X.skillsBack()
    local K = S.sk
    if K.book and not K.bookGone then X.removeItem(K.book); K.bookGone = true end
    local w = RT.cw()
    if K.findWas ~= nil then
        local TF = ZeD.TabFind
        if w and TF and TF.setText then pcall(TF.setText, w, "skills", K.findWas) end
        K.findWas = nil
    end
    if K.scrollWas ~= nil then
        local s = w and w._skillsScroll
        if s and s.setScrollPos then pcall(function() s:setScrollPos(K.scrollWas) end) end
        K.scrollWas = nil
    end
end
Q.step(2, function() X.skillsBack() end)

-- ===================================================================== W18: the exercise block on the tab's clock
-- (the tab's own seven, in its order: vanilla's FitnessExercises ids)
local EXIDS = { "squats", "pushups", "situp", "burpees", "barbellcurl", "dumbbellpress", "bicepscurl" }
-- the band's "Exercise: <name>" labels, the words the old code measured for the box's width every frame (a label
-- that reads the same as a bare name is left out: the band measures the bare name for its least room each frame)
function X.pickSet()
    local set, bare, n, clash = {}, {}, 0, false
    for _, id in ipairs(EXIDS) do bare[tostring(HT.exerciseLabel(id))] = true end
    for _, id in ipairs(EXIDS) do
        local s = tostring(ZeD.tr("UI_ZeD_Health_ExercisePick", HT.exerciseLabel(id)))
        if bare[s] then clash = true elseif not set[s] then set[s] = true; n = n + 1 end
    end
    return set, n, clash
end
-- the game's exercise table behind a counting stand-in: every read of an exercise is counted
function X.countOn()
    local E = S.ex
    if E.real or not (FitnessExercises and FitnessExercises.exercisesType) then return false end
    E.real = FitnessExercises.exercisesType
    E.reads, E.itemReads, E.picks = 0, 0, 0
    local real = E.real
    FitnessExercises.exercisesType = setmetatable({}, { __index = function(_, k)
        local v = real[k]
        E.reads = E.reads + 1
        if type(v) == "table" and v.item then E.itemReads = E.itemReads + 1 end
        return v
    end })
    -- the pointer off every hot spot (a pointer resting on Start would add its help line's reads)
    if ZeD.Atoms and ZeD.Atoms.mouseIn then
        E.mouseIn = ZeD.Atoms.mouseIn
        ZeD.Atoms.mouseIn = function() return false end
    end
    -- the pop-up box's label measure: the band's "Exercise: <name>" measures counted, every measure answered as before
    local M = ZeD.Molecules
    if M and M.popupMenuW and E.pickSet then
        E.pmw = M.popupMenuW
        local pmw, set = E.pmw, E.pickSet
        M.popupMenuW = function(label, ...)
            if label ~= nil and set[label] then E.picks = E.picks + 1 end
            return pmw(label, ...)
        end
    end
    return true
end
function X.countOff()
    local E = S.ex
    if E.real then FitnessExercises.exercisesType = E.real; E.real = nil end
    if E.mouseIn then ZeD.Atoms.mouseIn = E.mouseIn; E.mouseIn = nil end
    if E.pmw then ZeD.Molecules.popupMenuW = E.pmw; E.pmw = nil end
end

Q.step(5, function() X.tab("health") end)
X.untilMs(4000, function()
    local w = RT.cw()
    if not (w and w._activeTab == "health") then return false end
    -- the figure unfolded (the exercise block is beside it; a folded figure is never drawn): its fold kept to put back
    if not S.fg.expSet then S.fg.expWas = w._healthFigureExpanded; S.fg.expSet = true end
    w._healthFigureExpanded = true
    return w._healthCache ~= nil and w._healthBodyFigure ~= nil and w._healthBand ~= nil
end, function(ok)
    local w = RT.cw()
    S.ex.ready = Q.check(ok, "W18 stage: the Health tab is open and drawn with the figure unfolded",
        "tab " .. tostring(w and w._activeTab) .. ", figure " .. tostring(w and w._healthBodyFigure ~= nil))
    if not ok then return end
    if not (FitnessExercises and FitnessExercises.exercisesType) then
        Q.check(false, "W18 stage: the game's exercise table is there", "missing")
        S.ex.ready = false
        return
    end
    local okP, set, n, clash = pcall(X.pickSet)
    if okP then S.ex.pickSet, S.ex.pickN, S.ex.pickClash = set, n, clash end
end)
-- A. three seconds of the tab drawing, the reads counted frame by frame
Q.step(20, function()
    if not S.ex.ready then return end
    local E = S.ex
    E.frames, E.busy, E.rebuilds, E.lastReads = 0, 0, 0, 0
    local w = RT.cw()
    E.lastState = w and w._healthEx
    E.sawState = E.lastState ~= nil
    X.countOn()
    E.t0 = getTimestampMs()
end)
X.everyFrame(function()
    local E = S.ex
    if not (E.ready and E.t0) then return true end
    X.hold()
    E.frames = E.frames + 1
    if (E.reads or 0) ~= E.lastReads then E.busy = E.busy + 1; E.lastReads = E.reads or 0 end
    local w = RT.cw()
    local st = w and w._healthEx
    if st ~= nil then E.sawState = true end
    if st ~= E.lastState then E.rebuilds = E.rebuilds + 1; E.lastState = st end
    return getTimestampMs() - E.t0 >= 3000
end, function(err)
    local E = S.ex
    if not (E.ready and E.t0) then X.countOff(); return end
    local ms = getTimestampMs() - E.t0
    local reads, itemReads, picks = E.reads or 0, E.itemReads or 0, E.picks or 0
    X.countOff()
    if err then Q.check(false, "W18: the three-second count ran without an error", err) end
    local w = RT.cw()
    local drawn = w ~= nil and w._activeTab == "health" and reads > 0
    Q.check(drawn, "W18 stage: the tab kept drawing for the measure", reads .. " reads in " .. E.frames .. " frames, " .. ms .. " ms")
    -- what the fix promises: the state 4 times a second (7 item tests and the picked one's info: 8 reads, 10
    -- allowed), the fill block twice a second (14 reads), and nothing in between. The old code read at least 7 a
    -- frame (the layout key's 7 item tests), so below about 15 frames a second the two cannot be told apart.
    local stateRuns = math.floor(ms / 250) + 2
    local fillRuns = math.floor(ms / 500) + 2
    local allowed = stateRuns * 10 + fillRuns * 14 + 20
    local old = E.frames * 7
    local seen = string.format("%d reads (%d of an exercise that needs an item) in %d frames and %d ms, %.2f a frame; allowed %d; the old code at least %d",
        reads, itemReads, E.frames, ms, reads / math.max(1, E.frames), allowed, old)
    if old <= allowed * 1.15 then
        Q.skip("W18: the reads fit the clock", "too few frames drawn to tell the old code from the new, " .. seen)
    else
        Q.check(reads <= allowed, "W18: the exercise reads fit the 250 ms clock, not a batch every frame", seen)
        -- (the state's and the fill's beats, a little slack; the old code: every frame, and this line runs only past
        -- 44 frames)
        local busyMax = stateRuns + fillRuns + 4
        Q.check(E.busy <= busyMax,
            "W18: most frames read no exercise and search no inventory (old code: every frame did)",
            E.busy .. " of " .. E.frames .. " frames read something; at most " .. busyMax .. " expected")
    end
    if (E.pickN or 0) > 0 then
        Q.check(picks <= 7, "W18: the exercise box's widest label is not measured again every frame (old code: 7 measures a frame)",
            picks .. " measures of the " .. E.pickN .. " \"Exercise: <name>\" labels in " .. E.frames .. " frames; the old code about " .. (E.frames * 7))
    else
        Q.skip("W18: the exercise box's widest label measured once", "the labels read the same as the bare names in this language" .. (E.pickClash and "" or " (none found)"))
    end
    local lo, hi = math.floor(ms / 250) - 3, math.floor(ms / 250) + 2
    Q.check(E.sawState and E.rebuilds >= math.max(1, lo) and E.rebuilds <= hi,
        "W18: the exercise state is rebuilt about four times a second (old code: no clocked state at all)",
        "state " .. (E.sawState and "there" or "never there") .. ", " .. E.rebuilds .. " rebuilds in " .. ms .. " ms, " .. math.max(1, lo) .. " to " .. hi .. " expected")
end)
-- B. 200 layout measures in one frame cost no more than one rebuild
Q.step(6, function()
    if not S.ex.ready then return end
    local E = S.ex
    local w = RT.cw()
    if not (w and HT._measureExerciseInfo) then Q.check(false, "W18: the layout measure is there", "missing"); return end
    -- (another width than the tab's: one fresh layout is made on the first call, the worst case)
    local width = (w._healthInfoW or 300) + 260
    X.countOn()
    local okM, err = true, nil
    local t0 = getTimestampMs()
    for _ = 1, 200 do
        if okM then okM, err = pcall(HT._measureExerciseInfo, w, width) end
    end
    local ms = getTimestampMs() - t0
    local reads, itemReads = E.reads or 0, E.itemReads or 0
    X.countOff()
    if not okM then Q.check(false, "W18: the layout measure ran without an error", tostring(err)); return end
    -- (one state rebuild if it came due: 7; one fresh layout for the new width: at most 14)
    Q.check(reads <= 40, "W18: 200 layout measures in one frame read the exercises at most once over (old code: 1400 reads, 600 inventory searches)",
        reads .. " reads, " .. itemReads .. " of an item exercise, " .. ms .. " ms")
end)
-- C. the clocked state still follows the inventory: a dumbbell picked up, then put down
Q.step(6, function()
    if not S.ex.ready then return end
    local E = S.ex
    local w = RT.cw()
    local st = w and w._healthEx
    if not st then
        Q.check(false, "W18: the tab keeps a clocked exercise state to follow", "win._healthEx is nil (the old code has none)")
        return
    end
    if X.carries("Base.DumbBell") then Q.skip("W18: the state follows a dumbbell picked up", "the character already carries one"); return end
    E.availWas = st.avail and st.avail.dumbbellpress
    E.bell = X.give("Base.DumbBell")
    E.follow = E.bell ~= nil
    if not E.bell then Q.check(false, "W18 stage: a dumbbell given", "AddItem returned nothing") end
end)
X.untilMs(1500, function()
    if not S.ex.follow then return true end
    local w = RT.cw()
    local st = w and w._healthEx
    return st and st.avail and st.avail.dumbbellpress == true and st.avail.bicepscurl == true
end, function(ok, ms)
    local E = S.ex
    if not E.follow then return end
    local w = RT.cw()
    local st = w and w._healthEx
    Q.check(E.availWas == false and ok and ms <= 700, "W18: a dumbbell picked up, the dumbbell exercises open within the clock's beat",
        "before " .. tostring(E.availWas) .. ", now " .. tostring(st and st.avail and st.avail.dumbbellpress) .. " after " .. ms .. " ms")
    local live, was = false, w and w._healthExerciseSel
    pcall(function()
        w._healthExerciseSel = "dumbbellpress"
        live = HT.canStart(w) == true
    end)
    if w then w._healthExerciseSel = was end
    Q.say("W18 Start's own live test for the dumbbell press says " .. tostring(live))
    X.removeItem(E.bell)
    E.bellGone = true
end)
X.untilMs(1500, function()
    if not S.ex.follow then return true end
    local w = RT.cw()
    local st = w and w._healthEx
    return st and st.avail and st.avail.dumbbellpress == false
end, function(ok, ms)
    local E = S.ex
    if not E.follow then return end
    Q.check(ok and ms <= 700, "W18: the dumbbell put down, the dumbbell exercises need it again (nothing stale)", "after " .. ms .. " ms")
end)

-- ===================================================================== W19: the body figure keeps its colour tables
function X.bucket(h)
    local T = ZeD.T
    if h > 80 then return T.positive end
    if h > 50 then return T.warning end
    if h > 20 then return T.danger end
    return { r = 0.95, g = 0.15, b = 0.15 }
end
Q.step(6, function()
    local w = RT.cw()
    local fig = w and w._healthBodyFigure
    local G9 = S.fg
    if not (S.ex.ready and fig and fig.colorMap) then
        Q.check(false, "W19 stage: the Health tab's body figure is drawn", "figure " .. tostring(fig ~= nil))
        return
    end
    G9.ready = true
    G9.fig = fig
    G9.map = fig.colorMap
    G9.snap = {}
    G9.parts = 0
    for name, c in pairs(fig.colorMap) do G9.snap[name] = c; G9.parts = G9.parts + 1 end
    G9.frames, G9.mapNew, G9.partNew, G9.wipes = 0, 0, 0, 0
    -- every wipe of any figure's colours is counted (the class's own function, put back after)
    if ZeD_BodyFigure and ZeD_BodyFigure.clearColors then
        G9.clear = ZeD_BodyFigure.clearColors
        ZeD_BodyFigure.clearColors = function(self, ...)
            G9.wipes = G9.wipes + 1
            return G9.clear(self, ...)
        end
    end
end)
function X.figBack()
    local G9 = S.fg
    if G9.clear then ZeD_BodyFigure.clearColors = G9.clear; G9.clear = nil end
end
X.everyFrame(function()
    local G9 = S.fg
    if not G9.ready then return true end
    X.hold()
    G9.frames = G9.frames + 1
    local m = G9.fig.colorMap or {}
    if m ~= G9.map then G9.mapNew = G9.mapNew + 1; G9.map = m end
    for name, c in pairs(m) do
        if G9.snap[name] ~= c then G9.partNew = G9.partNew + 1; G9.snap[name] = c end
    end
    return G9.frames >= 60
end, function(err)
    local G9 = S.fg
    X.figBack()
    if not G9.ready then return end
    if err then Q.check(false, "W19: the 60-frame count ran without an error", err) end
    local w = RT.cw()
    Q.check(w ~= nil and w._activeTab == "health" and G9.parts >= 10, "W19 stage: the figure was drawn with its parts coloured",
        G9.parts .. " parts, tab " .. tostring(w and w._activeTab))
    Q.check(G9.mapNew == 0, "W19: the figure's colour map is the same table for 60 frames (old code: a new one every frame)",
        G9.mapNew .. " new maps in " .. G9.frames .. " frames")
    Q.check(G9.partNew == 0, "W19: every part keeps its colour table for 60 frames (old code: 17 new tables every frame)",
        G9.partNew .. " new colour tables in " .. G9.frames .. " frames, " .. G9.parts .. " parts")
    Q.check(G9.wipes == 0, "W19: nothing wipes a figure's colours while the tab draws (old code: once a frame)", G9.wipes .. " wipes")
    -- the colours are still set: each part's colour is the one for its health
    local okD, d = pcall(HT.gatherData, p)
    local bad, n = {}, 0
    if okD and d and d.partHealth then
        for name, health in pairs(d.partHealth) do
            n = n + 1
            local c = G9.fig.colorMap and G9.fig.colorMap[name]
            local want = X.bucket(health)
            if not (c and math.abs(c.r - want.r) < 0.01 and math.abs(c.g - want.g) < 0.01 and math.abs(c.b - want.b) < 0.01
                    and math.abs((c.a or 0) - 0.65) < 0.01) then
                bad[#bad + 1] = tostring(name) .. " (health " .. math.floor(health) .. ")"
            end
        end
    end
    Q.check(okD and n >= 10 and #bad == 0, "W19: every part still carries the colour for its health",
        n .. " parts read" .. (#bad > 0 and (", wrong: " .. table.concat(bad, ", ")) or ""))
    Q.skip("W19: the medical check card's figure", "the card opens only on another player (a server or split screen); the same wipe was taken out of it")
end)

-- ===================================================================== PUT BACK
Q.mark()
Q.step(2, function()
    pcall(X.countOff)
    pcall(X.figBack)
    pcall(X.tvBack)
    pcall(X.skillsBack)
    local E, K = S.ex, S.sk
    if E.bell and not E.bellGone then X.removeItem(E.bell); E.bellGone = true end
    if K.bagGiven then X.removeItem(K.bagGiven) end
    -- anything this script gave that is still in the main inventory (only its own mark: nothing else is touched)
    pcall(function()
        local inv = p:getInventory()
        local items = inv:getItems()
        for i = items:size() - 1, 0, -1 do
            local it = items:get(i)
            if it:hasModData() and it:getModData().ZeDQA_vxh then inv:Remove(it) end
        end
    end)
    if S.fg.expSet then
        local w = RT.cw()
        if w then w._healthFigureExpanded = S.fg.expWas end
        S.fg.expSet = false
    end
end)
Q.step(4, function()
    local f = S.found
    -- healed only if the health went down (nothing here hurts him; RestoreToFullHealth takes no argument)
    pcall(function()
        local bd = p:getBodyDamage()
        if f.health and bd:getOverallBodyHealth() < f.health - 0.5 then bd:RestoreToFullHealth() end
    end)
    if f.open then
        RT.pairOpen()
        if f.tab then pcall(RT.charTab, f.tab) end
    else
        RT.pairShut()
    end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "vx_hlth") end
end)
Q.step(10, function()
    local f = S.found
    local T, K = S.tv, S.sk
    local w = RT.cw()
    if w then pcall(function() w._outSince = f.outSince end) end   -- (the roll-up hold the polls kept ahead)
    local health = nil
    pcall(function() health = p:getBodyDamage():getOverallBodyHealth() end)
    Q.check(not p:isDead() and (f.health == nil or (health ~= nil and health >= f.health - 0.5)), "put back: the character is alive and as healthy as found",
        tostring(health) .. " (found " .. tostring(f.health) .. ")")
    if f.inv ~= nil then pcall(function() p:setInvincible(f.inv) end) end
    if f.god ~= nil then pcall(function() p:setGodMod(f.god) end) end
    Q.check(p:isGodMod() == f.god and p:isInvincible() == f.inv, "put back: god mode and invincible as found",
        tostring(p:isGodMod()) .. " / " .. tostring(p:isInvincible()))
    Q.check(FitnessExercises ~= nil and S.ex.real == nil and S.ex.mouseIn == nil and S.ex.pmw == nil and S.fg.clear == nil,
        "put back: the game's exercise table, the pointer test, the label measure and the figure's wipe are the real ones again")
    if T.staged then
        local optNow = nil
        pcall(function() optNow = T.opt:getValue() end)
        local still = false
        for _, title in ipairs(T.added) do if X.inRecord(title) then still = true end end
        local back, want = X.recordBack()
        local marksNow = nil
        pcall(function() marksNow = p:getModData().ZeD_Finds end)
        Q.check(optNow == T.optWas and not still and back == want and marksNow == T.marksWas,
            "put back: Hidden facts, ZeD's find mark and the reading record as found",
            "setting " .. tostring(optNow) .. " (was " .. tostring(T.optWas) .. "), a test issue still on record " .. tostring(still)
            .. ", records set aside back " .. back .. " of " .. want)
    end
    local bookLeft = K.book ~= nil and X.carries(K.ft)
    local bellLeft = S.ex.bell ~= nil and X.carries("Base.DumbBell")
    Q.check(not bookLeft and not bellLeft, "put back: the test's book and dumbbell are gone",
        "book carried " .. tostring(bookLeft) .. ", dumbbell carried " .. tostring(bellLeft))
    Q.check(RT.isOpen() == f.open, "put back: the windows as found", tostring(RT.isOpen()))
end)
Q.start()
