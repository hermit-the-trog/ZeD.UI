-- ZeDUI/tools/qa/zedqa_cov_reading_menu.lua  (Nov 12 2026, QA coverage: ZeDUI/qa/AUDIT_DESIGN_AND_COVERAGE_20261111.md
-- Table B, the "reading" group, its main menu half; the in-game half is zedqa_cov_reading.lua. Repaired the same day
-- after review: every frame read is checked first, and every editor button the header names is pressed)
-- AT THE MAIN MENU (never in a zedqa_run.ps1 manifest: the runner refuses main menu scripts). Run it with
--   pwsh -File ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList <an empty file> -Script ZeDUI/tools/qa/zedqa_cov_reading_menu.lua -Tag cov_reading_menu -TimeoutSec 240
-- grep console.txt for "ZEDQA cov_reading_menu": one line per check, "PASS <what>" or "FAIL <what> (<got> vs <want>)",
-- each value read from ZeD's own objects; "SHOT <file>" lines name the captures (Screenshots/zqa_covrdm_*.png);
-- "RESULT <n> pass, <m> fail", then DONE. It loads no save and presses nothing that reaches Steam.
--
-- WHAT IT CHECKS
--   The corkboard change note on the live desk (MenuNote.lua, ZeD_MainMenu.lua): the desk's own frame writes the
--     note (MM.drawNote, recorded on its way to the real panel; a frame that does not come in 4 s is a FAIL); the note
--     lies on the screen; this copy's heading, then BETA 11 and BETA 12 (the version swapped for a frame), are drawn
--     whole at the desk's multiple, BETA 100 is left off; every line of the word list is drawn whole; the ink is the
--     note's.
--   The Workshop description editor (ZeD_MainMenuDescEdit.lua), opened as the upload window opens it (MM.wsEditor,
--     the "wsdesc" view); each button pressed through the window's own controller A (focusId + joyA): the sample
--     description as its blocks, the first picked, its words in the field; the band counting the characters; each of
--     the palette's blocks (11) added after the pick with its starting words, picked, and taken back by Undo; each of
--     the palette's sections (7) added as a second-level heading and its block, one Undo for both (a section the
--     palette has no room for at this screen size is a FAIL); Add list, typing into it (one undo step per block),
--     Move up and down, Remove, Undo and Redo; a heading's H2, H3 and H1; each of the five marks on a paragraph
--     (Link, Strike, Underline, Italic, Bold) puts Steam's codes at the cursor and the cursor between them; the Steam
--     codes view and back; over the limit the band says so and Use this description greys; Cancel with changes asks
--     (Cancel, Discard changes, Keep): Cancel goes back to editing, Discard changes goes back to the upload window
--     without handing the text over, Keep hands the changed text over; Use this description hands the blocks back as
--     Steam's codes. Every hand-off to the upload window is caught: the upload window is never opened.
-- Put back: MM.drawNote, MM.zedVersion and the note's cache; MM.showView, MM.wsEditor, the upload window's
-- _fromEditor and the view the desk was on.
local MM = ZeD and ZeD.MainMenu
local BB = ZeD and ZeD.BB
local function say(s) print("ZEDQA cov_reading_menu " .. tostring(s)) end
if not (MM and MM.root and MM.drawNote and MM.layout and BB) then
    say("ERR no ZeD main menu here (root " .. tostring(MM and MM.root) .. ")")
    say("RESULT 0 pass, 0 fail")
    say("DONE")
    return
end
local Q = { pass = 0, fail = 0 }
local S = { done = false }
local KEEP = { drawNote = MM.drawNote, zedVersion = MM.zedVersion, view = MM.view, wsEditor = MM.wsEditor, showView = MM.showView }
pcall(function() KEEP.fromEditor = MM.root.workshopWin and MM.root.workshopWin._fromEditor end)
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()

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
    local name = "zqa_covrdm_" .. n .. "_" .. sw .. "x" .. sh .. ".png"
    pcall(function() getCore():TakeFullScreenshot(name) end)
    say("SHOT " .. name)
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE NOTE, RECORDED ON THE LIVE DESK
-- ---------------------------------------------------------------------------------------------------------------
-- (ZeD_MainMenu.lua's NOTE_X 52, NOTE_HEAD_Y 17 in the 5 x 7 face, NOTE_LINE_Y 30 37 44 51 58 in the 3 x 5 face; the
-- note's right edge at 92 art pixels)
local NOTE_X, HEAD_Y, LINE_Y = 52, 17, { 30, 37, 44, 51, 58 }
MM.drawNote = function(p, L, dipped)
    if S.want then
        S.want = false
        local rec = {}
        local pane = { drawRect = function(_, x, y, w, h, a, r, g, b)
            rec[#rec + 1] = { x = x, y = y, w = w, h = h, r = r, g = g, b = b }
            p:drawRect(x, y, w, h, a, r, g, b)
        end }
        KEEP.drawNote(pane, L, dipped)
        S.got = { rec = rec, s = L.s, ox = L.ox, oy = L.oy, dipped = dipped, version = MM.zedVersion() }
        return
    end
    return KEEP.drawNote(p, L, dipped)
end
-- the recorded runs in art rows y0 .. y0 + n - 1: how many, and their pixels
local function rowsOf(got, y0, n)
    local c, px = 0, 0
    for _, r in ipairs(got.rec) do
        local ay = math.floor((r.y - got.oy) / got.s + 0.5)
        if ay >= y0 and ay < y0 + n then c = c + 1; px = px + math.floor(r.w / got.s + 0.5) end
    end
    return c, px
end
local function runsOf(face, text, y0)
    local runs = {}
    MM._noteRuns(runs, face, text, NOTE_X, y0)
    local px = 0
    for _, r in ipairs(runs) do px = px + r.w end
    return #runs, px
end
local function forceVersion(v)
    if v then MM.zedVersion = function() return v end else MM.zedVersion = KEEP.zedVersion end
    MM._note = nil
    S.got = nil
    S.want = true
end
-- the frame asked for came in (else a FAIL, and the step's other checks are left out)
local function gotFrame(what)
    return check(S.got ~= nil and #S.got.rec > 0, "the desk's frame writes the note (" .. what .. ")", S.got and #S.got.rec or "no frame in 4 s", "> 0 runs")
end
local function headingDrawn(v)
    local want = MM.noteHeading(v)
    local c, px = rowsOf(S.got, HEAD_Y, 7)
    local wc, wpx = runsOf("57", want, HEAD_Y)
    return wc > 0 and c == wc and px == wpx, want .. ", " .. c .. " runs " .. px .. " px", want .. ", " .. wc .. " runs " .. wpx .. " px"
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE EDITOR
-- ---------------------------------------------------------------------------------------------------------------
local SAMPLE = "[h1]Tidy Sorting[/h1]\n[img]https://example.com/banner.png[/img]\n\n"
    .. "Sorts your bags by kind with [b]one press[/b] and keeps favorites on top.\n\n"
    .. "[h2]Features[/h2]\n[list]\n[*]One-press sort in every bag\n[*]Favorites stay on top\n[/list]\n\n"
    .. "[h2]Compatibility[/h2]\n[table]\n[tr][th]Works with[/th][th]Notes[/th][/tr]\n[tr][td]Knox Radio Plus[/td][td]Load it first[/td][/tr]\n[/table]"
-- the five marks, as the card's head lists them (mk:<block>:<n>): Link, Strike, Underline, Italic, Bold
local MARKS = { { "Link", "[url=https://]", "[/url]" }, { "Strike", "[strike]", "[/strike]" }, { "Underline", "[u]", "[/u]" },
                { "Italic", "[i]", "[/i]" }, { "Bold", "[b]", "[/b]" } }
local function ED() return MM.root and MM.root.wsdescWin end
local function kinds(bs)
    local t = {}
    for _, b in ipairs(bs or {}) do t[#t + 1] = b.kind end
    return table.concat(t, ",")
end
local function spec(id)
    local e = ED()
    for _, s in ipairs(e and e._specs or {}) do if s.id == id then return s end end
    return nil
end
-- a button pressed with the controller's A: the focus put on it, then the window's own joyA (only a live one: joyA
-- on a missing or greyed id would press the first stop instead)
local function pressId(id)
    local s = spec(id)
    if not s or s.disabled then
        check(false, "the editor has a live '" .. id .. "' button", s and "greyed" or "none", "live")
        return false
    end
    local e = ED()
    e.focusId = id
    e:joyA()
    return true
end
-- a press whose hand-off to the upload window is caught (MM.showView kept for the press only): the view asked for
local function pressCaught(id)
    S.asked = nil
    MM.showView = function(v) S.asked = v end
    local ok, err = pcall(pressId, id)
    MM.showView = KEEP.showView
    if not ok then error(err) end
    pcall(function() if MM.root.workshopWin then MM.root.workshopWin._fromEditor = KEEP.fromEditor end end)
    return S.asked
end
-- the editor opened again on the sample, as the upload window opens it
local function reopen()
    S.doneText = nil
    MM.wsEditor = { text = SAMPLE, title = "QA Sample", limit = BB.LIMIT, done = function(t) S.doneText = t end }
    MM.showView("wsdesc")
end

local function restore(why)
    if S.done then return end
    S.done = true
    MM.drawNote = KEEP.drawNote
    MM.zedVersion = KEEP.zedVersion
    MM._note = nil
    MM.showView = KEEP.showView
    pcall(function() local e = ED(); if e then e.confirm = false; e.focusId = nil; e.edit:unfocus(); e.edit:setVisible(false) end end)
    pcall(function() if MM.view == "wsdesc" then MM.showView((KEEP.view ~= "wsdesc" and KEEP.view) or "main") end end)
    MM.wsEditor = KEEP.wsEditor
    pcall(function() if MM.root.workshopWin then MM.root.workshopWin._fromEditor = KEEP.fromEditor end end)
    say("restored (" .. tostring(why) .. "): the note's draw and version, the editor's hand-off, the view " .. tostring(MM.view))
end

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
local function noteFrame(what) waitFor(4000, function() return S.got ~= nil end, what) end

-- 1  the note as the desk draws it now
add(300, function()
    if MM.view ~= "main" then note("the desk was on view '" .. tostring(MM.view) .. "': back to the main menu"); MM.showView("main") end
    forceVersion(nil)
end)
noteFrame("the desk to write the note")
add(100, function()
    if not gotFrame("this copy's version") then forceVersion("0.3.0-beta11"); return end
    local g = S.got
    local x1, x2 = g.ox + NOTE_X * g.s, g.ox + 92 * g.s
    local y1, y2 = g.oy + HEAD_Y * g.s, g.oy + (LINE_Y[#LINE_Y] + 5) * g.s
    if MM._framing == "lean" then
        note("the desk is framed lean (the room cropped): the note's place on the screen is not checked")
    else
        check(x1 >= 0 and x2 <= sw and y1 >= 0 and y2 <= sh, "the note lies on the screen at " .. sw .. "x" .. sh,
            string.format("x %.0f-%.0f y %.0f-%.0f", x1, x2, y1, y2), "inside " .. sw .. "x" .. sh)
    end
    local ok, got, want = headingDrawn(g.version)
    check(ok, "this copy's heading (" .. tostring(g.version) .. ") is drawn whole at x" .. tostring(g.s), got, want)
    local list = ZeD.MenuNote or {}
    for k, y in ipairs(LINE_Y) do
        if list[k] then
            local s = string.sub(string.upper(tostring(list[k])), 1, 10)
            local lc, lpx = rowsOf(g, y, 5)
            local wlc, wlpx = runsOf("35", s, y)
            check(wlc > 0 and lc == wlc and lpx == wlpx, "line " .. k .. " '" .. s .. "' is drawn whole", lc .. " runs " .. lpx .. " px", wlc .. " runs " .. wlpx .. " px")
        end
    end
    local r1 = g.rec[1]
    local want3 = g.dipped and { 0, 0x09 / 255, 0x2f / 255 } or { 0, 0x0f / 255, 0x34 / 255 }
    local inkOk = r1 and math.abs(r1.r - want3[1]) < 0.002 and math.abs(r1.g - want3[2]) < 0.002 and math.abs(r1.b - want3[3]) < 0.002
    check(inkOk, "the note is in its " .. (g.dipped and "dim " or "") .. "ink", r1 and string.format("%.3f,%.3f,%.3f", r1.r, r1.g, r1.b),
        string.format("%.3f,%.3f,%.3f", want3[1], want3[2], want3[3]))
    shot("note")
    forceVersion("0.3.0-beta11")
end)
noteFrame("the BETA 11 frame")
add(100, function()
    if gotFrame("0.3.0-beta11") then
        local ok, got, want = headingDrawn("0.3.0-beta11")
        check(ok and MM.noteHeading("0.3.0-beta11") == "BETA 11", "0.3.0-beta11 puts BETA 11 on the note, whole", got, want)
        shot("note_beta11")
    end
    forceVersion("0.3.0-beta12")
end)
noteFrame("the BETA 12 frame")
add(100, function()
    if gotFrame("0.3.0-beta12") then
        local ok, got, want = headingDrawn("0.3.0-beta12")
        check(ok and MM.noteHeading("0.3.0-beta12") == "BETA 12", "0.3.0-beta12 puts BETA 12 on the note, whole", got, want)
        shot("note_beta12")
    end
    forceVersion("0.3.0-beta100")
end)
noteFrame("the BETA 100 frame")
add(100, function()
    if gotFrame("0.3.0-beta100") then
        local c = rowsOf(S.got, HEAD_Y, 7)
        check(c == 0, "a heading wider than the paper (BETA 100) is left off the note", c .. " runs", "0 runs")
    end
    forceVersion(nil)
end)
noteFrame("the note back on this copy's version")

-- 2  the description editor, opened as the upload window opens it
add(300, function() reopen() end)
add(700, function()
    local e = ED()
    if not check(MM.view == "wsdesc" and e ~= nil and MM.activeWindow() == e, "the editor opens as the desk's wsdesc view", MM.view, "wsdesc") then
        error("no editor window: the editor's checks cannot run")
    end
    local want = kinds(BB.parse(SAMPLE))
    check(kinds(e.blocks) == want, "the description comes in as its blocks", kinds(e.blocks), want)
    check(e.sel == 1 and e.edit:getText() == e.blocks[1].text, "the first block is picked, its words in the field", tostring(e.sel) .. " '" .. tostring(e.edit:getText()) .. "'", "1 '" .. tostring(e.blocks[1] and e.blocks[1].text) .. "'")
    local missing = ""
    for _, k in ipairs(BB.KINDS) do if not spec("add:" .. k[1]) then missing = missing .. k[1] .. " " end end
    check(missing == "", "the palette offers every block (" .. #BB.KINDS .. ")", missing, "none missing")
    local count = ZeD.tr("UI_ZeD_DescEdit_Count", BB.count(#e:text()), BB.count(BB.LIMIT))
    check(e._bandAsk == count, "the band counts the characters against the limit", e._bandAsk, count)
    local u, use = spec("undo"), spec("use")
    check(u ~= nil and u.disabled and use ~= nil and not use.disabled, "Undo greyed with nothing done, Use this description live",
        tostring(u and u.disabled) .. "/" .. tostring(use and use.disabled), "true/false")
    shot("editor")
end)

-- each palette block: added after the pick with its starting words, picked, then taken back by Undo
for _, kind in ipairs(BB.KINDS) do
    local k = kind
    add(400, function()
        local e = ED()
        S.n, S.sel = #e.blocks, e.sel
        S.added = pressId("add:" .. k[1])
    end)
    add(400, function()
        local e = ED()
        if S.added then
            local b = e.blocks[e.sel or 0]
            local words = BB.text(k[3])
            check(#e.blocks == S.n + 1 and e.sel == S.sel + 1 and b ~= nil and b.kind == k[1] and b.text == words and e.edit:getText() == words,
                "the palette's " .. k[1] .. " goes in after the picked block with its starting words, picked, in the field",
                #e.blocks .. " blocks, picked " .. tostring(e.sel) .. " " .. tostring(b and b.kind) .. " '" .. tostring(b and b.text) .. "'",
                (S.n + 1) .. " blocks, picked " .. (S.sel + 1) .. " " .. k[1] .. " '" .. words .. "'")
            S.undone = pressId("undo")
        end
    end)
    add(400, function()
        local e = ED()
        if S.added and S.undone then
            check(#e.blocks == S.n and e.sel == S.sel, "Undo takes the " .. k[1] .. " back out", #e.blocks .. " blocks, picked " .. tostring(e.sel), S.n .. " blocks, picked " .. S.sel)
        end
    end)
end
-- each section readers look for: a second-level heading and its block, one Undo for both
for idx, sec in ipairs(BB.SECTIONS) do
    local n, s3 = idx, sec
    add(400, function()
        local e = ED()
        S.n, S.sel = #e.blocks, e.sel
        S.added = false
        local sp = spec("sec:" .. n)
        if check(sp ~= nil and not sp.disabled, "the palette offers section " .. n .. " (" .. BB.text(s3[1]) .. ") at " .. sw .. "x" .. sh, sp and "greyed" or "no room for it", "a live button") then
            S.added = pressId("sec:" .. n)
        end
    end)
    add(400, function()
        local e = ED()
        if S.added then
            local h, b = e.blocks[(e.sel or 0) - 1], e.blocks[e.sel or 0]
            local hw, bw = BB.text(s3[1]), BB.text(s3[3])
            check(#e.blocks == S.n + 2 and e.sel == S.sel + 2 and h ~= nil and h.kind == "h2" and h.text == hw and b ~= nil and b.kind == s3[2] and b.text == bw,
                "section " .. n .. " goes in as a second-level heading '" .. hw .. "' and its " .. s3[2] .. ", the block picked",
                #e.blocks .. " blocks, picked " .. tostring(e.sel) .. ", " .. tostring(h and h.kind) .. " '" .. tostring(h and h.text) .. "' then "
                    .. tostring(b and b.kind) .. " '" .. tostring(b and b.text) .. "'",
                (S.n + 2) .. " blocks, picked " .. (S.sel + 2) .. ", h2 '" .. hw .. "' then " .. s3[2] .. " '" .. bw .. "'")
            S.undone = pressId("undo")
        end
    end)
    add(400, function()
        local e = ED()
        if S.added and S.undone then
            check(#e.blocks == S.n and e.sel == S.sel, "one Undo takes section " .. n .. " back out, heading and block", #e.blocks .. " blocks, picked " .. tostring(e.sel), S.n .. " blocks, picked " .. S.sel)
        end
    end)
end

-- Add list, typing, moving, removing, undo and redo
add(400, function()
    local e = ED()
    S.n0 = #e.blocks
    S.u0 = #e.undo
    pressId("add:list")
end)
add(400, function()
    local e = ED()
    local b = e.blocks[2]
    check(#e.blocks == S.n0 + 1 and b and b.kind == "list" and e.sel == 2, "Add list puts a list after the picked block and picks it",
        #e.blocks .. " blocks, " .. tostring(b and b.kind) .. ", picked " .. tostring(e.sel), (S.n0 + 1) .. " blocks, list, picked 2")
    check(#e.undo == S.u0 + 1 and spec("undo") and not spec("undo").disabled, "Undo is live after a change", #e.undo, S.u0 + 1)
    e.edit:setText("alpha\nbeta")
end)
add(400, function()
    local e = ED()
    check(e.blocks[2].text == "alpha\nbeta", "typing goes into the picked block", e.blocks[2].text, "alpha\\nbeta")
    check(#e.undo == S.u0 + 2, "one undo step for the block typed in", #e.undo, S.u0 + 2)
    pressId("up:2")
end)
add(400, function()
    local e = ED()
    check(e.blocks[1].kind == "list" and e.blocks[2].kind == "h1" and e.sel == 1, "Move up swaps it with the block above, the pick with it",
        kinds({ e.blocks[1], e.blocks[2] }) .. ", picked " .. tostring(e.sel), "list,h1, picked 1")
    pressId("dn:1")
end)
add(400, function()
    local e = ED()
    check(e.blocks[2].kind == "list" and e.sel == 2, "Move down takes it back", kinds({ e.blocks[1], e.blocks[2] }) .. ", picked " .. tostring(e.sel), "h1,list, picked 2")
    pressId("del:2")
end)
add(400, function()
    local e = ED()
    check(#e.blocks == S.n0 and e.blocks[2].kind ~= "list", "Remove takes the block out", #e.blocks .. " blocks, " .. tostring(e.blocks[2].kind), S.n0 .. " blocks, img")
    pressId("undo")
end)
add(400, function()
    local e = ED()
    check(#e.blocks == S.n0 + 1 and e.blocks[2].kind == "list" and e.blocks[2].text == "alpha\nbeta", "Undo brings the block back with its words",
        #e.blocks .. " blocks, " .. tostring(e.blocks[2].kind), (S.n0 + 1) .. " blocks, list")
    check(spec("redo") and not spec("redo").disabled, "Redo is live after an undo", spec("redo") and tostring(spec("redo").disabled), "false")
    pressId("redo")
end)
add(400, function()
    local e = ED()
    check(#e.blocks == S.n0, "Redo takes it out again", #e.blocks, S.n0)
    pressId("card:1")
end)

-- the heading's level: H2, H3, H1
add(400, function()
    local e = ED()
    check(e.sel == 1 and spec("lv:1:2") ~= nil and spec("lv:1:3") ~= nil, "a heading picked shows its H1 H2 H3", tostring(e.sel) .. " " .. tostring(spec("lv:1:3") ~= nil), "1 true")
    pressId("lv:1:2")
end)
add(400, function()
    local e = ED()
    check(e.blocks[1].kind == "h2", "H2 makes it a second-level heading", e.blocks[1].kind, "h2")
    pressId("lv:1:3")
end)
add(400, function()
    local e = ED()
    check(e.blocks[1].kind == "h3", "H3 makes it a third-level heading", e.blocks[1].kind, "h3")
    pressId("lv:1:1")
    S.textIx = nil
    for k, b in ipairs(e.blocks) do if b.kind == "text" and not S.textIx then S.textIx = k end end
end)
add(400, function()
    local e = ED()
    check(e.blocks[1].kind == "h1", "H1 puts it back", e.blocks[1].kind, "h1")
    if S.textIx then pressId("card:" .. S.textIx) else check(false, "the sample has a paragraph for the marks", "none", "one") end
end)
-- each mark at the end of the paragraph: its codes at the cursor, the cursor between them
add(400, function()
    local e = ED()
    local k = S.textIx
    if not k then return end
    for mi, mk in ipairs(MARKS) do
        local before = e.blocks[k].text
        pcall(function() e.edit:setCursorPos(#before) end)
        if pressId("mk:" .. k .. ":" .. mi) then
            local t = e.blocks[k].text
            local pos = -1
            pcall(function() pos = e.edit:getCursorPos() end)
            check(t == before .. mk[2] .. mk[3] and pos == #before + #mk[2], mk[1] .. " puts Steam's codes at the cursor, the cursor between them",
                "'" .. string.sub(t, #before + 1) .. "' at " .. tostring(pos), "'" .. mk[2] .. mk[3] .. "' at " .. (#before + #mk[2]))
        end
    end
    pressId("view:codes")
end)
add(400, function()
    local e = ED()
    check(e.view == "codes", "the Steam codes view", e.view, "codes")
    shot("codes")
    pressId("view:steam")
    MM.wsEditor.limit = 10
end)
add(400, function()
    local e = ED()
    local use = spec("use")
    local over = ZeD.tr("UI_ZeD_DescEdit_CountOver", BB.count(#e:text()), BB.count(10))
    check(e.view == "steam", "back on Steam's look", e.view, "steam")
    check(use ~= nil and use.disabled and e._bandAsk == over, "over the limit the band says so and Use this description greys",
        tostring(use and use.disabled) .. " '" .. tostring(e._bandAsk) .. "'", "true '" .. over .. "'")
    shot("over")
    MM.wsEditor.limit = BB.LIMIT
end)
add(400, function()
    local use = spec("use")
    check(use ~= nil and not use.disabled, "back under the limit Use this description is live", use and tostring(use.disabled), "false")
    pressId("cancel")
end)
-- Cancel's question: Cancel goes back to editing
add(400, function()
    local e = ED()
    check(e.confirm == "leave", "Cancel with changes asks first", tostring(e.confirm), "leave")
    local a, b, c = spec("confirm:cancel"), spec("confirm:no"), spec("confirm:yes")
    check(a ~= nil and b ~= nil and c ~= nil and e._bandAsk == ZeD.tr("UI_ZeD_DescEdit_AskKeep"), "the question: Cancel, Discard changes, Keep",
        tostring(a ~= nil) .. tostring(b ~= nil) .. tostring(c ~= nil) .. " '" .. tostring(e._bandAsk) .. "'", "truetruetrue '" .. ZeD.tr("UI_ZeD_DescEdit_AskKeep") .. "'")
    shot("ask")
    pressId("confirm:cancel")
end)
add(400, function()
    local e = ED()
    check(not e.confirm and MM.view == "wsdesc", "Cancel on the question goes back to editing", tostring(e.confirm) .. " " .. tostring(MM.view), "false wsdesc")
    pressId("cancel")
end)
-- Discard changes: back to the upload window, the text not handed over
add(400, function()
    local e = ED()
    check(e.confirm == "leave", "Cancel asks again", tostring(e.confirm), "leave")
    S.doneText = nil
    local asked = pressCaught("confirm:no")
    check(S.doneText == nil, "Discard changes hands nothing to the upload window", S.doneText and (#S.doneText .. " chars") or "nothing", "nothing")
    check(asked == "workshop", "Discard changes goes back to the upload window", asked, "workshop")
    check(not e.edit:isVisible(), "the editor's field is put away", tostring(e.edit:isVisible()), "false")
end)
-- Keep: the changed text handed over
add(400, function() reopen() end)
add(500, function()
    local e = ED()
    check(e.confirm == false and #e.undo == 0 and kinds(e.blocks) == kinds(BB.parse(SAMPLE)), "the editor opens again on the description as it was",
        tostring(e.confirm) .. ", " .. #e.undo .. " undo, " .. kinds(e.blocks), "false, 0 undo, " .. kinds(BB.parse(SAMPLE)))
    pressId("add:divider")
end)
add(400, function()
    S.text = ED():text()
    pressId("cancel")
end)
add(400, function()
    local e = ED()
    check(e.confirm == "leave", "with a divider added, Cancel asks", tostring(e.confirm), "leave")
    local asked = pressCaught("confirm:yes")
    check(S.doneText ~= nil and S.doneText == S.text and string.find(S.doneText, "[hr][/hr]", 1, true) ~= nil,
        "Keep hands the changed text to the upload window", S.doneText and (#S.doneText .. " chars") or "nothing", #S.text .. " chars with the divider")
    check(asked == "workshop", "Keep goes back to the upload window", asked, "workshop")
end)
-- Use this description: the blocks handed back as Steam's codes
add(400, function() reopen() end)
add(500, function()
    local e = ED()
    S.text = e:text()
    S.kinds = kinds(e.blocks)
    local asked = pressCaught("use")
    check(S.doneText == S.text, "Use this description hands the blocks back as Steam's codes", S.doneText and #S.doneText .. " chars", #S.text .. " chars")
    check(S.doneText ~= nil and kinds(BB.parse(S.doneText)) == S.kinds, "the codes handed back read as the same blocks", S.doneText and kinds(BB.parse(S.doneText)), S.kinds)
    check(asked == "workshop", "it goes back to the upload window", asked, "workshop")
    check(not e.edit:isVisible(), "the editor's field is put away", tostring(e.edit:isVisible()), "false")
    MM.showView((KEEP.view ~= "wsdesc" and KEEP.view) or "main")
end)

add(500, function()
    restore("the end")
    say("RESULT " .. Q.pass .. " pass, " .. Q.fail .. " fail")
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnFETick.Remove(drive); return end
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
        Events.OnFETick.Remove(drive)
        restore("an error")
        say("RESULT " .. Q.pass .. " pass, " .. (Q.fail + 1) .. " fail")
        say("DONE")
    end
end
Events.OnFETick.Add(drive)
say("start")
