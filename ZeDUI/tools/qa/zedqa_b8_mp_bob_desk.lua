-- ZeDUI/tools/qa/zedqa_b8_mp_bob_desk.lua  (Nov 7 2026, QA; beta 8): on BOB's client, at the MAIN MENU (his desk, after the kicked screen's Exit; runs on the front-end tick). CHECK_desk_notes_mail_20261107.md
-- "For QA in game" 1 to 5 as far as a script can see: the desktop's left column (sticky, CletusWorks, ProtoPOP3 Mail, Documents), the
-- sticky's 600-character cap, a CletusWorks page saved to the desktop's Documents and read back, renamed, the draft kept when the view is
-- left and "Brought back from last time", Save changes? asking, the 24-note cap and the 20,000-character cap, Documents deleting, and
-- Mail at the desk: a letter written to the admin goes to the Outbox for the next join (zedqa_b8_mp_mail_offline_*.lua reads it going up).
-- bob's own Zomboid\zedqa_p2\Lua files are used; what this run made is removed (the notes, the sticky's words), except the Outbox letter,
-- which the join must send. grep "ZEDQA b8bd". Pictures: zqa_b8_desk_*.png. Fonts, the pad and Deck/4K layouts are manual.
local TAG = "b8bd"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local npass, nfail = 0, 0
local function check(ok, what, d)
    ok = ok and true or false
    if ok then npass = npass + 1 else nfail = nfail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
end
local function note(s) say("NOTE " .. tostring(s)) end
local function manual(s) say("MANUAL " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8_" .. n .. ".png") end) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function has(s, w) return type(s) == "string" and w ~= nil and string.find(string.lower(s), string.lower(w), 1, true) ~= nil end
local function keepDown() pcall(function()
    for _, get in ipairs({ ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow, ZeD_WorldWindow and ZeD_WorldWindow.getWindow }) do
        local w = get and get()
        if w then w._autoShaded = false; if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end; w._outSince = getTimestampMs() + 600000 end
    end
end) end
local plan, pi, pt = {}, 1, getTimestampMs()
local ins = nil
local function push(e) if ins then table.insert(plan, ins, e); ins = ins + 1 else plan[#plan + 1] = e end end
local function add(ms, fn) push({ ms = ms, fn = fn }) end
local function ticks(n, fn) push({ ticks = n, fn = fn }) end
local function waitFor(maxMs, cond, fn) push({ cond = cond, max = maxMs, fn = fn }) end
local function drive()
    local st = plan[pi]
    if not st then return end
    local now = getTimestampMs()
    local timedOut = false
    if st.ticks then
        st.ticks = st.ticks - 1
        if st.ticks > 0 then return end
    elseif st.cond then
        if not st.started then st.started = now end
        local ok, v = pcall(st.cond)
        if not (ok and v) and now - st.started < st.max then return end
        timedOut = not (ok and v)
    elseif now - pt < st.ms then return end
    pt = now
    pi = pi + 1
    keepDown()
    ins = pi
    local ok, e = pcall(st.fn, timedOut)
    ins = nil
    if not ok then nfail = nfail + 1; say("FAIL ERR step " .. (pi - 1) .. ": " .. tostring(e)) end
    if pi > #plan then
        say(npass .. " passed, " .. nfail .. " failed")
        say("DONE")
        Events.OnFETick.Remove(drive)
    end
end
local MM = ZeD.MainMenu
local N = ZeD.DeskNotes
local MS = ZeD.MailStore
local Ml = ZeD.Mail
local sticky0, ids0, made = nil, {}, {}
local function root() return MM.root end
local function noteIds()
    local o = {}
    for _, n in ipairs(N.list()) do o[#o + 1] = n.id end
    return o
end
add(500, function()
    check(MM.root ~= nil, "the desk is up")
    sticky0 = #N.pasties()
    for _, id in ipairs(noteIds()) do ids0[id] = true end
    note("at the start: " .. N.count() .. " notes, " .. tostring(sticky0) .. " Pasties")
    local items = MM.leftItems()
    local o = {}
    for _, it in ipairs(items) do o[#o + 1] = it.id end
    note("the left column: " .. table.concat(o, ", "))
    -- (Nov 10 2026: the sticky became Pasties, an icon; its notes come after Documents in the list, laid out where they lie)
    check(o[1] == "pasties" and o[2] == "cletusworks", "1: the left column starts with Pasties and CletusWorks", table.concat(o, ","))
    local docAt
    for i, id in ipairs(o) do if id == "documents" then docAt = i end end
    check(docAt ~= nil and (docAt == #o or tostring(o[docAt + 1]):find("^pastie:")), "1: the column ends with Documents", tostring(docAt))
    local mailAt
    for i, id in ipairs(o) do if id == "mail" then mailAt = i end end
    check(mailAt ~= nil and mailAt > 2 and mailAt < (docAt or #o), "1: ProtoPOP3 Mail sits between them", mailAt)
    check(has(ZeD.tr("UI_ZeD_Mail_AppName"), "protopop3"), "1: the app is named ProtoPOP3 Mail", ZeD.tr("UI_ZeD_Mail_AppName"))
    check(MM.root.pasties ~= nil and MM.root.pasties[1] ~= nil and MM.root.pasties[1].entry ~= nil, "1: the Pasties' fields are there")
    ticks(30, function() shot("desk_desktop") end)
end)
local madePastie = nil
add(800, function()
    madePastie = N.newPastie(0.5, 0.5)
    if madePastie then
        N.savePastie(madePastie, "b8 sticky words")
        check(N.pastieText(madePastie) == "b8 sticky words", "1: a Pastie keeps its words", N.pastieText(madePastie))
        N.savePastie(madePastie, string.rep("s", 700))
        check(#N.pastieText(madePastie) == N.STICKY_MAX, "1: a Pastie stops at 600 characters", #N.pastieText(madePastie))
    else
        note("1: eight Pasties on this desk already: the cap checks skipped")
    end
end)

-- ---- CletusWorks
add(500, function()
    MM.openNotepad()
end)
ticks(10, function()
    local w = root() and root().notepadWin
    check(MM.view == "notepad" and w ~= nil, "2: CletusWorks opens on the monitor", MM.view)
    if not w then return end
    w.edit:setText("b8 page, first line\nsecond line")
    ticks(5, function() shot("desk_notepad") end)
end)
add(900, function()
    local w = root().notepadWin
    if not (w and w.doc) then check(false, "2: the notepad has a page"); return end
    local ok = w:save()
    check(ok == true, "2: Save writes the page to the desktop's Documents", tostring(ok))
    local id = w.doc.id
    check(id ~= nil and N.get(id) ~= nil, "2: the page is a note now", tostring(id))
    if id then made[#made + 1] = id end
    check(has(N.read(id) or "", "second line"), "2: the file reads back whole", N.read(id))
    check(N.rename(id, "b8 note") ~= false, "2: the page can be renamed")
    check(N.get(id) and N.get(id).name == "b8 note", "2: the new name is kept", N.get(id) and N.get(id).name)
    -- words not saved: the draft
    w.edit:setText("b8 unsaved words")
    w._draftAt = nil
    w:update()
end)
add(700, function()
    local w = root().notepadWin
    local d = N.draft()
    check(d ~= nil and has(d.text, "unsaved words"), "2: unsaved words are kept as a draft", d and d.text)
    MM.showView("desktop")
end)
add(700, function()
    MM.openNotepad(made[1])
end)
ticks(10, function()
    local w = root().notepadWin
    check(w ~= nil and w.doc ~= nil and w.doc.recovered == true, "2: the notepad opens with the draft and says it was brought back", w and w.doc and tostring(w.doc.recovered))
    check(w ~= nil and has(w:text(), "unsaved words"), "2: the unsaved words are on the page", w and w:text())
    if w then
        w:close()
        check(w.confirm == "unsaved", "2: closing a page with unsaved words asks Save changes?", tostring(w.confirm))
        ticks(5, function() shot("desk_savechanges") end)
    end
end)
add(900, function()
    local w = root().notepadWin
    if not w then return end
    w:answer(false)
    check(not w:dirty(), "2: Discard changes drops the words")
    check(has(N.read(made[1]) or "", "second line"), "2: the saved page is untouched", N.read(made[1]))
end)

-- ---- the caps
add(900, function()
    local before = N.count()
    local made2 = 0
    for i = 1, N.MAX + 2 do
        local n, err = N.create("b8 cap " .. i, "x")
        if n then made[#made + 1] = n.id; made2 = made2 + 1 elseif err == "full" then break end
    end
    check(N.full() and N.count() == N.MAX, "3: the desk holds at most " .. N.MAX .. " notes", N.count())
    local n, err = N.create("b8 over", "x")
    check(n == nil and err == "full", "3: a new note over the cap is refused", tostring(err))
    local id = made[1]
    N.save(id, string.rep("y", N.TEXT_MAX + 5000))
    local back = N.read(id) or ""
    check(#back <= N.TEXT_MAX, "3: a note holds at most 20,000 characters", #back)
    N.save(id, "b8 page, first line\nsecond line")
    ticks(5, function() end)
end)
add(500, function()
    MM.openDocs()
end)
ticks(10, function()
    local w = root().docsWin
    check(MM.view == "docs" and w ~= nil, "4: Documents opens", MM.view)
    if not w then return end
    local rows = w:rows()
    check(#rows == N.count(), "4: it lists every note", #rows)
    ticks(5, function() shot("desk_documents") end)
end)
add(1200, function()
    local w = root().docsWin
    if not w then return end
    local victim = made[#made]
    w.sel = victim
    w:delete()
    check(N.get(victim) == nil, "4: Delete takes the note away", tostring(victim))
    made[#made] = nil
    check(not N.full(), "4: there is room again under the cap")
end)
add(500, function()
    MM.showView("desktop")
    -- every note this run made goes (the emptied files are reused, as the design says)
    for _, id in ipairs(made) do pcall(N.delete, id) end
    made = {}
    for _, n in ipairs(N.list()) do
        if not ids0[n.id] then pcall(N.delete, n.id) end
    end
    N.clearDraft()
    if madePastie then N.throwPastie(madePastie) end
    check(N.count() == (function() local c = 0; for _ in pairs(ids0) do c = c + 1 end; return c end)(), "5: the notes are as they were before the run (restored)", N.count())
end)

-- ---- Mail at the desk
add(800, function()
    MM.openMail()
end)
ticks(10, function()
    local w = root().mailWin
    check(MM.view == "mail" and w ~= nil, "5: ProtoPOP3 Mail opens at the desk", MM.view)
    if not w then return end
    local b = w:box()
    check(b ~= nil, "5: the desk reads the mailbox this computer kept from the dial-in", b and b.user)
    if not b then return end
    w:startCompose("zedqa", "b8 from the desk", "Written at the desk with no server in reach. It goes up on the next join, word for word.")
    check(w:putWhy() == nil, "5: Put in Outbox is lit for a good letter", w:putWhy())
    local before = #MS.load(b).outbox
    w:put()
    local after = #MS.load(b).outbox
    check(after == before + 1, "5: Put in Outbox queues the letter for the next join", before .. " -> " .. after)
    ticks(5, function() shot("desk_mail_outbox") end)
end)
add(900, function()
    MM.showView("desktop")
    manual("desk 1: type into the sticky with the keyboard and with the pad's keyboard; the keys do not reach the desktop's arrows")
    manual("desk 2: a page of 100 lines scrolls with the wheel and the caret stays in view")
    manual("desk 3 and 4: the left column and the icons' art at Deck, 720, 1080p and 4K, Large text, many notes")
end)
Events.OnFETick.Add(drive)
