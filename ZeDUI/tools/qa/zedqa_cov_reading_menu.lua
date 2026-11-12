-- ZeDUI/tools/qa/zedqa_cov_reading_menu.lua  (Nov 12 2026, QA coverage: ZeDUI/qa/AUDIT_DESIGN_AND_COVERAGE_20261111.md
-- Table B, the "reading" group, its main menu half; the in-game half is zedqa_cov_reading.lua)
-- AT THE MAIN MENU (never in a zedqa_run.ps1 manifest: the runner refuses main menu scripts). Run it with
--   pwsh -File ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList <an empty file> -Script ZeDUI/tools/qa/zedqa_cov_reading_menu.lua -Tag cov_reading_menu -TimeoutSec 180
-- grep console.txt for "ZEDQA cov_reading_menu": one line per check, "PASS <what>" or "FAIL <what> (<got> vs <want>)",
-- each value read from ZeD's own objects; "SHOT <file>" lines name the captures (Screenshots/zqa_covrdm_*.png);
-- "RESULT <n> pass, <m> fail", then DONE. It loads no save and presses nothing that reaches Steam.
--
-- WHAT IT CHECKS
--   The corkboard change note on the live desk (MenuNote.lua, ZeD_MainMenu.lua): the desk's own frame writes the
--     note (MM.drawNote, recorded on its way to the real panel); the note lies on the screen; this copy's heading,
--     then BETA 11 and BETA 12 (the version swapped for a frame), are drawn whole at the desk's multiple, BETA 100
--     is left off; every line of the word list is drawn whole; the ink is the note's.
--   The Workshop description editor (ZeD_MainMenuDescEdit.lua), opened as the upload window opens it (MM.wsEditor,
--     the "wsdesc" view), every button pressed through the window's own controller A (focusId + joyA): the sample
--     description as its blocks, the first picked, its words in the field; every palette block offered; the band
--     counting the characters; Add list puts a list after the pick; typing goes into the block, one undo step per
--     block; Move up and down, Remove, Undo and Redo; a heading's H2; Bold puts Steam's codes at the cursor; the
--     Steam codes view; over the limit the band says so and Use this description greys; Cancel with changes asks
--     (Cancel, Discard changes, Keep) and Cancel goes back to editing; Use this description hands the blocks back
--     as Steam's codes and asks for the upload window (the hand-off is caught, the upload window is not opened).
-- Put back: MM.drawNote, MM.zedVersion and the note's cache; MM.wsEditor, the upload window's _fromEditor and the
-- view the desk was on.
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

-- ---------------------------------------------------------------------------------------------------------------
-- THE EDITOR
-- ---------------------------------------------------------------------------------------------------------------
local SAMPLE = "[h1]Tidy Sorting[/h1]\n[img]https://example.com/banner.png[/img]\n\n"
    .. "Sorts your bags by kind with [b]one press[/b] and keeps favorites on top.\n\n"
    .. "[h2]Features[/h2]\n[list]\n[*]One-press sort in every bag\n[*]Favorites stay on top\n[/list]\n\n"
    .. "[h2]Compatibility[/h2]\n[table]\n[tr][th]Works with[/th][th]Notes[/th][/tr]\n[tr][td]Knox Radio Plus[/td][td]Load it first[/td][/tr]\n[/table]"
local function ED() return MM.root and MM.root.wsdescWin end
local function kinds(bs)
    local t = {}
    for _, b in ipairs(bs or {}) do t[#t + 1] = b.kind end
    return table.concat(t, ",")
end
local function spec(id)
    for _, s in ipairs(ED()._specs or {}) do if s.id == id then return s end end
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

local function restore(why)
    if S.done then return end
    S.done = true
    MM.drawNote = KEEP.drawNote
    MM.zedVersion = KEEP.zedVersion
    MM._note = nil
    MM.showView = KEEP.showView
    pcall(function() local e = ED(); if e then e.confirm = false; e.focusId = nil; e.edit:unfocus(); e.edit:setVisible(false) end end)
    pcall(function() if MM.view == "wsdesc" then MM.showView(KEEP.view or "main") end end)
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
    local g = S.got
    check(g ~= nil and #g.rec > 0, "the desk's frame writes the change note", g and #g.rec, "> 0 runs")
    if not g then return end
    local x1, x2 = g.ox + NOTE_X * g.s, g.ox + 92 * g.s
    local y1, y2 = g.oy + HEAD_Y * g.s, g.oy + (LINE_Y[#LINE_Y] + 5) * g.s
    if MM._framing == "lean" then
        note("the desk is framed lean (the room cropped): the note's place on the screen is not checked")
    else
        check(x1 >= 0 and x2 <= sw and y1 >= 0 and y2 <= sh, "the note lies on the screen at " .. sw .. "x" .. sh,
            string.format("x %.0f-%.0f y %.0f-%.0f", x1, x2, y1, y2), "inside " .. sw .. "x" .. sh)
    end
    local head = MM.noteHeading(g.version)
    local c, px = rowsOf(g, HEAD_Y, 7)
    local wc, wpx = runsOf("57", head, HEAD_Y)
    check(wc > 0 and c == wc and px == wpx, "this copy's heading " .. head .. " (" .. tostring(g.version) .. ") is drawn whole at x" .. tostring(g.s),
        c .. " runs " .. px .. " px", wc .. " runs " .. wpx .. " px")
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
    local want = g.dipped and { 0, 0x09 / 255, 0x2f / 255 } or { 0, 0x0f / 255, 0x34 / 255 }
    local ok = r1 and math.abs(r1.r - want[1]) < 0.002 and math.abs(r1.g - want[2]) < 0.002 and math.abs(r1.b - want[3]) < 0.002
    check(ok, "the note is in its " .. (g.dipped and "dim " or "") .. "ink", r1 and string.format("%.3f,%.3f,%.3f", r1.r, r1.g, r1.b),
        string.format("%.3f,%.3f,%.3f", want[1], want[2], want[3]))
    shot("note")
    forceVersion("0.3.0-beta11")
end)
noteFrame("the BETA 11 frame")
add(100, function()
    local g = S.got
    local c, px = rowsOf(g, HEAD_Y, 7)
    local wc, wpx = runsOf("57", "BETA 11", HEAD_Y)
    check(MM.noteHeading("0.3.0-beta11") == "BETA 11" and wc > 0 and c == wc and px == wpx, "0.3.0-beta11 puts BETA 11 on the note, whole",
        MM.noteHeading("0.3.0-beta11") .. ", " .. c .. " runs " .. px .. " px", "BETA 11, " .. wc .. " runs " .. wpx .. " px")
    shot("note_beta11")
    forceVersion("0.3.0-beta12")
end)
noteFrame("the BETA 12 frame")
add(100, function()
    local g = S.got
    local c, px = rowsOf(g, HEAD_Y, 7)
    local wc, wpx = runsOf("57", "BETA 12", HEAD_Y)
    check(MM.noteHeading("0.3.0-beta12") == "BETA 12" and wc > 0 and c == wc and px == wpx, "0.3.0-beta12 puts BETA 12 on the note, whole",
        MM.noteHeading("0.3.0-beta12") .. ", " .. c .. " runs " .. px .. " px", "BETA 12, " .. wc .. " runs " .. wpx .. " px")
    shot("note_beta12")
    forceVersion("0.3.0-beta100")
end)
noteFrame("the BETA 100 frame")
add(100, function()
    local c = rowsOf(S.got, HEAD_Y, 7)
    check(c == 0, "a heading wider than the paper (BETA 100) is left off the note", c .. " runs", "0 runs")
    forceVersion(nil)
end)
noteFrame("the note back on this copy's version")

-- 2  the description editor, opened as the upload window opens it
add(300, function()
    S.doneText = nil
    MM.wsEditor = { text = SAMPLE, title = "QA Sample", limit = BB.LIMIT, done = function(t) S.doneText = t end }
    MM.showView("wsdesc")
end)
add(700, function()
    local e = ED()
    check(MM.view == "wsdesc" and e ~= nil and MM.activeWindow() == e, "the editor opens as the desk's wsdesc view", MM.view, "wsdesc")
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
    S.n0 = #e.blocks
    pressId("add:list")
end)
add(400, function()
    local e = ED()
    local b = e.blocks[2]
    check(#e.blocks == S.n0 + 1 and b and b.kind == "list" and e.sel == 2, "Add list puts a list after the picked block and picks it",
        #e.blocks .. " blocks, " .. tostring(b and b.kind) .. ", picked " .. tostring(e.sel), (S.n0 + 1) .. " blocks, list, picked 2")
    check(b and e.edit:getText() == b.text and b.text == BB.text("UI_ZeD_DescEdit_StartList"), "the new list starts with its sample items, in the field",
        b and b.text, BB.text("UI_ZeD_DescEdit_StartList"))
    check(#e.undo == 1 and spec("undo") and not spec("undo").disabled, "Undo is live after a change", #e.undo, 1)
    e.edit:setText("alpha\nbeta")
end)
add(400, function()
    local e = ED()
    check(e.blocks[2].text == "alpha\nbeta", "typing goes into the picked block", e.blocks[2].text, "alpha\\nbeta")
    check(#e.undo == 2, "one undo step for the block typed in", #e.undo, 2)
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
add(400, function()
    local e = ED()
    check(e.sel == 1 and spec("lv:1:2") ~= nil, "a heading picked shows its H1 H2 H3", tostring(e.sel) .. " " .. tostring(spec("lv:1:2") ~= nil), "1 true")
    pressId("lv:1:2")
end)
add(400, function()
    local e = ED()
    check(e.blocks[1].kind == "h2", "H2 makes it a second-level heading", e.blocks[1].kind, "h2")
    pressId("lv:1:1")
    S.textIx = nil
    for k, b in ipairs(e.blocks) do if b.kind == "text" and not S.textIx then S.textIx = k end end
end)
add(400, function()
    local e = ED()
    check(e.blocks[1].kind == "h1", "H1 puts it back", e.blocks[1].kind, "h1")
    if S.textIx then pressId("card:" .. S.textIx) end
end)
add(400, function()
    local e = ED()
    local k = S.textIx
    S.before = e.blocks[k].text
    S.at = #S.before
    pcall(function() e.edit:setCursorPos(S.at) end)
    -- the marks right to left: Link, Strike, Underline, Italic, Bold (mk:<block>:5)
    pressId("mk:" .. k .. ":5")
end)
add(400, function()
    local e = ED()
    local t = e.blocks[S.textIx].text
    local want = S.before .. "[b][/b]"
    check(t == want, "Bold puts Steam's codes at the cursor", t, want)
    local pos = -1
    pcall(function() pos = e.edit:getCursorPos() end)
    check(pos == S.at + 3, "the cursor lands between the codes", pos, S.at + 3)
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
    S.text = e:text()
    S.kinds = kinds(e.blocks)
    -- the hand-off: Use this description asks for the upload window; caught here, so it stays shut
    S.asked = nil
    MM.showView = function(v) S.asked = v end
    local ok, err = pcall(pressId, "use")
    MM.showView = KEEP.showView
    if not ok then error(err) end
    check(S.doneText == S.text, "Use this description hands the blocks back as Steam's codes", S.doneText and #S.doneText .. " chars", #S.text .. " chars")
    check(S.doneText ~= nil and kinds(BB.parse(S.doneText)) == S.kinds, "the codes handed back read as the same blocks", S.doneText and kinds(BB.parse(S.doneText)), S.kinds)
    check(S.asked == "workshop", "it goes back to the upload window", S.asked, "workshop")
    check(not e.edit:isVisible(), "the editor's field is put away", tostring(e.edit:isVisible()), "false")
    pcall(function() if MM.root.workshopWin then MM.root.workshopWin._fromEditor = KEEP.fromEditor end end)
    MM.showView(KEEP.view == "wsdesc" and "main" or (KEEP.view or "main"))
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
