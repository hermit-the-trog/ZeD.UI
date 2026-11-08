-- ZeDUI/tools/qa/desk_sim.lua  (Nov 7 2026, punch list 104): the desk's notes and mail apps on the main menu, with no game. The
-- real ZeD_MainMenuDesktop.lua, ZeD_MainMenuNotes.lua, ZeD_DeskNotes.lua and ZeD_MainMenuMail.lua run against desk_stub.lua.
--   the desktop's left side: the sticky first, CletusWorks and Mail, the files, columns, never over the right column, the
--     right column's block unchanged (the small layout reads it)
--   the sticky: typed in place, saved after the typing stops and on letting go, a press outside lets go, the field under the
--     pointer only where no window lies over it, the controller's A brings up the keyboard
--   CletusWorks: a new page, save (the icon appears), open from an icon, Save changes? on leaving (Discard, Cancel, Save),
--     rename (empty, taken), delete asks and lands on Cancel, the desktop full, the draft brought back after a restart, the
--     ZeD menu's items
--   Mail: the mailboxes kept on this computer, reading, the outbox, writing a reply, deleting (ask), the folders
-- Run from the repo root:  lua51 ZeDUI/tools/qa/desk_sim.lua
-- It prints FAIL lines and a last line "desk_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]desk_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local D = dofile(ROOT .. "ZeDUI/tools/qa/desk_stub.lua")
local W, DISK = D.W, D.DISK
local MAIL = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuMail.lua", "r")
if MAIL then MAIL:close() end
D.boot(ROOT, MAIL ~= nil)
local MM, N = ZeD.MainMenu, ZeD.DeskNotes
local root = D.buildDesk()

local function ids()
    local out = {}
    for _, c in ipairs(root.icons._cells or {}) do out[#out + 1] = c.item.id end
    return table.concat(out, ",")
end

-- ---------------------------------------------------------------------------
section("the desktop's left side")
MM.showView("desktop")
D.frame()
local st = D.cell("sticky")
check("the sticky is drawn", st ~= nil)
check("the sticky is first on the left, at the top", st and st.x == D.L.tx + 14 and st.y == D.L.ty + 24 + 14, st and (st.x .. "," .. st.y))
check("the sticky is 124 x 124 design units", st and st.w == 124 and st.h == 124)
local cw = D.cell("cletusworks")
check("CletusWorks under the sticky", cw and cw.y > st.y + st.h and cw.left)
check("its label reads CletusWorks (the key)", cw and cw.item.label == "UI_ZeD_Desk_CletusWorks")
check("CletusWorks has its own picture", cw and (cw.item.icon or cw.item.id) == "cletusworks")
if MAIL then
    local ml = D.cell("mail")
    check("Mail under CletusWorks", ml and ml.y > cw.y)
end
local block = MM.iconBlock(D.L)
check("the right column's block leaves the left side out", block.w < 200, block.w)
check("the sticky's field is placed over its paper", root.sticky.x == st.x and root.sticky.y == st.y and root.sticky.entry:isVisible())
local right = D.cell("pz")
check("the right column is still there", right and right.x > D.L.tx + D.L.tw / 2)

-- ---------------------------------------------------------------------------
section("the sticky note")
local se = root.sticky.entry
check("an empty sticky reads the file's words", se:getText() == "")
check("its hint", se.placeholder == "UI_ZeD_Desk_StickyHint")
check("it holds STICKY_MAX", se.maxLen == N.STICKY_MAX)
-- the pointer over the sticky's field: the glass hands the press to it on the bare desktop
local ex, ey = se:getAbsoluteX() + 5, se:getAbsoluteY() + 5
check("the field takes the press on the desktop", MM.entryUnder(ex, ey) == se)
se:focus()
se:type("seed 7741")
check("while typing, the desktop's keys are the sticky's", root.icons:keyOther(Keyboard.KEY_UP) == false)
D.frame(100)
check("not saved while typing", DISK[N.STICKY_FILE] == nil)
D.frame(900)
check("saved once the typing stops", DISK[N.STICKY_FILE] == "seed 7741\n", DISK[N.STICKY_FILE])
se:type("\nserver pw: dog")
-- a press outside the sticky lets go of the keys and saves at once
W.mouse.x, W.mouse.y, W.down = D.L.tx + 500, D.L.ty + 400, true
D.frame(16)
W.down = false
D.frame(16)
check("a press outside lets go", not se:isFocused())
check("letting go saves", DISK[N.STICKY_FILE] == "seed 7741\nserver pw: dog\n")
-- with the main window up: the sticky beside it still takes a press, a press inside the window does not reach it
MM.showView("main")
root.win.x, root.win.y, root.win.width, root.win.height = D.L.tx + 150, D.L.ty + 30, 660, 500
root.win.visible = true
D.frame()
check("beside the main window the sticky takes the press", MM.entryUnder(ex, ey) == se)
root.win.x = D.L.tx
check("under the main window it does not", MM.entryUnder(ex, ey) == nil)
root.win.x = D.L.tx + 150
MM.ctx.open = "file"
check("not while a menu is open", MM.entryUnder(ex, ey) == nil)
MM.ctx.open = nil
-- the controller: the D-pad reaches it, A brings up the keyboard on its field
MM.showView("desktop")
D.frame()
W.pad = true
root.icons.focusId = "cletusworks"
root.icons:joyDir("up")
check("up from CletusWorks is the sticky", root.icons.focusId == "sticky", root.icons.focusId)
W.kbd = {}
root.icons:joyA()
check("A on the sticky brings up the keyboard on its field", W.kbd[1] == se)
W.pad = false
-- a fresh start reads the sticky back
N.reset()
local se2 = ZeD_MMSticky:new()
root:addChild(se2)
check("the sticky reads its words at the next start", se2.entry:getText() == "seed 7741\nserver pw: dog")

-- ---------------------------------------------------------------------------
section("a quick double-click on an icon, counted on the frames drawn")
do
    MM.showView("desktop")
    D.frame()
    local c = D.cell("cletusworks")
    W.mouse.x, W.mouse.y = c.x + 4, c.y + 4
    MM.ctx.hot = "desk:other"                -- (the pointer has something else under the mouse: a window over the icons)
    W.down = true; D.frame(16); W.down = false; D.frame(16); W.down = true; D.frame(16); W.down = false; D.frame(16)
    check("not while the pointer has another box under the mouse", MM.view == "desktop", MM.view)
    MM.ctx.hot = "desk:cletusworks"
    W.clock = W.clock + 1000
    -- two presses inside 100 ms: the pointer, every 100 ms, would see one click
    W.down = true; D.frame(16); W.down = false; D.frame(16); W.down = true; D.frame(16)
    check("the second press opens it", MM.view == "notepad", MM.view)
    W.down = false; D.frame(16)
    root.icons:click("cletusworks")          -- (the pointer's own click on the release comes after: no second open)
    check("the pointer's late click does not count again", root.icons._lastClick == nil)
    MM.ctx.hot = nil
    W.mouse.x, W.mouse.y = 0, 0
    MM.showView("desktop")
    D.frame()
end

-- ---------------------------------------------------------------------------
section("CletusWorks: a new page, save, the icon")
root.icons:open("cletusworks")
check("CletusWorks opens its window", MM.view == "notepad")
local np = root.notepadWin
D.frame()
check("the window's title", np.title == "UI_ZeD_Desk_NotepadTitle")
check("a new page is named Untitled 1", np.doc and np.doc.name == "UI_ZeD_Desk_Untitled 1", np.doc and np.doc.name)
check("the name is in the title bar", np.titleStats[1] and np.titleStats[1].text == np.doc.name)
check("not on the desktop yet", np._ask == "UI_ZeD_Desk_NotOnDesktop", np._ask)
check("Delete is gray on a page not saved", D.spec(np, "delete").disabled == true)
check("the band holds New, Open, Rename, Delete, Save", D.spec(np, "new") and D.spec(np, "open") and D.spec(np, "rename") and D.spec(np, "save"))
np.edit:type("Kentucky run:\n1. Muldraugh\n2. the gas station")
D.frame()
check("typed: not saved", np._ask == "UI_ZeD_Desk_NotSaved")
D.frame(1600)
check("unsaved words go to the draft", N.draft() and N.draft().text == "Kentucky run:\n1. Muldraugh\n2. the gas station")
D.press(np, "save")
D.frame()
check("saved", np._ask == "UI_ZeD_Desk_Saved", np._ask)
check("on the desktop as note 1", N.get(1) and N.get(1).name == np.doc.name)
check("the draft is gone", N.draft() == nil)
check("its words on disk", DISK[N.fileOf(1)] == "Kentucky run:\n1. Muldraugh\n2. the gas station\n")
MM.showView("desktop")
D.frame()
check("no icon of its own on the desktop (the director: one Documents folder)", D.cell("note:1") == nil, ids())
check("the Documents folder is on the desktop", D.cell("documents") ~= nil and D.cell("documents").item.label == "UI_ZeD_Desk_Documents")
root.icons:open("documents"); D.frame()
local dw = root.docsWin
check("the folder opens the Documents window", MM.view == "docs" and dw.title == "UI_ZeD_Desk_Documents")
check("it lists the note, picked", D.spec(dw, "row:1") ~= nil and dw.sel == 1)
check("its count against the cap", dw._ask == "UI_ZeD_Desk_DocsCount(1," .. N.MAX .. ")", dw._ask)
check("Open, Rename, Delete in its band", D.spec(dw, "open") and D.spec(dw, "rename") and D.spec(dw, "delete"))
dw:close(); D.frame()
check("closing it goes back to the desktop", MM.view == "desktop")

-- ---------------------------------------------------------------------------
section("CletusWorks: leaving unsaved words")
MM.showView("notepad")
D.frame()
check("back on the same page", np.doc.id == 1)
np.edit:type("\n3. the river")
D.press(np, "new")
D.frame()
check("New asks Save changes? first", np.confirm == "unsaved", tostring(np.confirm))
check("the question names the page", np._ask == "UI_ZeD_Desk_AskSave(" .. np.doc.name .. ")", np._ask)
check("it lands on Cancel", np.focusId == "confirm:no")
D.press(np, "confirm:no")
check("Cancel keeps the page and its words", np.confirm == false and np.doc.id == 1 and np:dirty())
D.press(np, "new")
D.press(np, "confirm:discard")
check("Discard changes drops the words and goes on to a new page", np.doc.id == nil and N.read(1) == "Kentucky run:\n1. Muldraugh\n2. the gas station")
np.edit:type("second page")
np:close(); D.frame()
check("the close box asks too", np.confirm == "unsaved")
D.press(np, "confirm:yes")
check("Save then closes", MM.view == "desktop" and N.count() == 2)
-- opening a note from Documents while CletusWorks has unsaved words
MM.openNote(2); D.frame()
np.edit:type(" more")
MM.openDocs(); D.frame()
dw.sel = 1
D.press(dw, "open")
check("a note opened over unsaved words asks first", MM.view == "notepad" and np.confirm == "unsaved" and np.doc.id == 2)
D.press(np, "confirm:yes")
check("Save, then the note asked for", np.doc.id == 1 and N.read(2) == "second page more", N.read(2))

-- ---------------------------------------------------------------------------
section("CletusWorks and Documents: open, rename, delete")
D.press(np, "open")
check("CletusWorks' Open is the Documents list", MM.view == "docs")
check("newest saved first", D.spec(dw, "row:2") ~= nil)
dw.sel = 2
D.press(dw, "open")
check("its Open opens that page in CletusWorks", MM.view == "notepad" and np.doc.id == 2)
D.press(np, "open")
dw:close(); D.frame()
check("closing the list from CletusWorks goes back to it", MM.view == "notepad")
D.press(np, "rename")
D.frame()
check("Rename puts a field in the band", np.confirm == "rename" and np.renameEntry:isVisible())
np.renameEntry:setText("   ")
D.frame()
check("an empty name: Rename is gray", D.spec(np, "confirm:yes").disabled == true)
np.renameEntry:setText(N.get(1).name)
D.frame()
check("another note's name: gray, and says why", D.spec(np, "confirm:yes").disabled == true and D.spec(np, "confirm:yes").help == "UI_ZeD_Desk_NameTaken")
np.renameEntry:setText("Server list")
D.frame()
D.press(np, "confirm:yes")
check("renamed", N.get(2).name == "Server list" and np.doc.name == "Server list" and np.confirm == false)
-- rename in Documents too, and CletusWorks follows it
MM.openDocs("notepad"); D.frame()
dw.sel = 2
D.press(dw, "rename")
check("Documents' Rename puts a field in its band", dw.confirm == "rename" and dw.renameEntry:isVisible() and dw.focusId == "confirm:no")
dw.renameEntry:setText("Servers"); D.frame()
D.press(dw, "confirm:yes")
check("renamed from Documents", N.get(2).name == "Servers")
dw:close(); D.frame()
check("CletusWorks reads the new name", np.doc.name == "Servers")
D.press(np, "delete")
D.frame()
check("Delete asks", np.confirm == "delete" and np._ask == "UI_ZeD_Desk_AskDelete(Servers)")
check("and lands on Cancel", np.focusId == "confirm:no")
D.press(np, "confirm:yes")
check("deleted, a new page open", N.get(2) == nil and np.doc.id == nil)
MM.openDocs(); D.frame()
dw.sel = 1
D.press(dw, "delete")
check("Documents' Delete asks and lands on Cancel", dw.confirm == "delete" and dw.focusId == "confirm:no" and dw._ask == "UI_ZeD_Desk_AskDelete(" .. N.get(1).name .. ")")
D.press(dw, "confirm:no")
check("Cancel keeps it", N.get(1) ~= nil)
D.press(dw, "delete"); D.press(dw, "confirm:yes")
check("deleted from Documents", N.get(1) == nil and N.count() == 0 and D.spec(dw, "open").disabled == true)
dw:close(); D.frame()

-- ---------------------------------------------------------------------------
section("CletusWorks: the cap of 24, a full note")
while not N.full() do N.create(N.freshName("n")) end
MM.showView("desktop"); D.frame()
local maxX = 0
for _, c in ipairs(root.icons._cells) do
    if c.left and c.x + c.w > maxX then maxX = c.x + c.w end
end
check("the left side never reaches the right column", maxX < right.x, maxX .. " vs " .. right.x)
local lefts = 0
for _, c in ipairs(root.icons._cells) do if c.left then lefts = lefts + 1 end end
check("24 notes still make only the four left items", lefts == (MAIL and 4 or 3), lefts)
MM.openDocs(); D.frame()
check("Documents lists all 24", D.spec(dw, "row:24") ~= nil and D.spec(dw, "row:25") == nil)
MM.showView("notepad"); D.frame()
D.press(np, "new")
np.edit:type(string.rep("z", N.TEXT_MAX + 30))
D.frame()
check("the page's box stops at TEXT_MAX", #np.edit:getText() == N.TEXT_MAX and np.edit.maxLen == N.TEXT_MAX)
check("a full page says so in the band", np._ask == "UI_ZeD_Desk_NoteFull(" .. N.MAX * 0 + N.TEXT_MAX .. ")", np._ask)
np.edit:setText("one too many")
D.press(np, "save")
D.frame()
check("a full desktop says so in the band", np._ask == "UI_ZeD_Desk_Full(" .. N.MAX .. ")", np._ask)
check("the words stay on the page", np.edit:getText() == "one too many" and np:dirty())

-- ---------------------------------------------------------------------------
section("CletusWorks: the draft after a restart")
D.frame(1600)
check("the unsaved page is in the draft", N.draft() and N.draft().text == "one too many")
-- the game restarts: a new desk, the files as they were
N.reset()
MM.views = {}
D.boot(ROOT, MAIL ~= nil)
root = D.buildDesk()
MM.showView("notepad")
np = root.notepadWin
D.frame()
check("the notepad opens with the draft", np.edit:getText() == "one too many" and np.doc.recovered == true)
check("and says it was brought back", np._ask == "UI_ZeD_Desk_Recovered", np._ask)

-- ---------------------------------------------------------------------------
section("the ZeD menu")
local items = MM.menuItems("zed")
local found = {}
for _, it in ipairs(items) do if type(it) == "table" and it.text then found[it.text] = it end end
check("CletusWorks Notepad in the ZeD menu", found["UI_ZeD_Desk_NotepadTitle"] ~= nil)
if MAIL then check("Mail in the ZeD menu", found["UI_ZeD_Mail_AppName"] ~= nil) end
check("the About block stays first", items[1].about == true)

-- ---------------------------------------------------------------------------
if MAIL then
    local MS, mw = ZeD.MailStore, root.mailWin
    section("Mail: nobody has dialed in yet")
    root.icons:open("mail")
    D.frame()
    check("the Mail icon opens its window", MM.view == "mail" and mw ~= nil)
    check("the window's title", mw.title == "UI_ZeD_Mail_AppName")
    check("no mailbox: New letter is gray and says how mail comes", D.spec(mw, "new").disabled == true and D.spec(mw, "new").help == "UI_ZeD_Mail_NoBoxesHow")
    check("the band says so", mw._ask == "UI_ZeD_Mail_NoBoxes")

    section("Mail: the copy on this computer")
    local b = MS.box("10.0.0.5:16261", "Rosa", "Test Server")
    MS.receive(b, { id = 4, from = "Ned", to = "Rosa", subj = "supplies", text = "I have nails.\nYou have wood?", t = 1700003000, day = 12 })
    MS.receive(b, { id = 7, from = "Ada", to = "Rosa", subj = "", text = "Rules changed.", t = 1700004000, day = 13 })
    MS.save(b)
    MS.dialed(b)
    MS.reset()
    b.data = nil
    MM.showView("desktop"); D.frame()
    local mc = D.cell("mail")
    check("the desktop's Mail icon counts the unread", mc and mc.item.label == "UI_ZeD_Mail_IconNew(2)", mc and mc.item.label)
    root.icons:open("mail"); D.frame()
    check("the mailbox in the title bar", mw.titleStats[1] and mw.titleStats[1].text == "UI_ZeD_Mail_BoxName(Rosa,Test Server)")
    check("the Inbox first, newest on top", D.spec(mw, "row:1") and D.spec(mw, "row:2") and mw:letters()[1].id == 7)
    check("one mailbox: its pop-up is gray", D.spec(mw, "box").disabled == true)
    check("the band says the last dial-in", string.find(mw._ask or "", "UI_ZeD_Mail_LastDial", 1, true) == 1, mw._ask)
    check("Reply and Delete gray with nothing picked", D.spec(mw, "reply").disabled and D.spec(mw, "delete").disabled)
    D.press(mw, "row:2")
    check("picking a letter reads it", mw.sel and mw.sel.id == 4)
    check("and marks it read", mw.sel.read == true and MS.unread(b) == 1)
    MS.reset(); b.data = nil
    check("read is kept on the disk", (function() local b2 = MS.find(b.key); return b2 and MS.unread(b2) == 1 end)())
    b = MS.find(b.key)
    mw.sel = MS.load(b).inbox[2]
    D.frame()

    section("Mail: reply, the outbox")
    D.press(mw, "reply")
    check("Reply writes back to the sender", mw.compose and mw.toEntry:getText() == "Ned" and mw.subjEntry:getText() == "Re: supplies")
    check("the letter is quoted, as mail did", string.find(mw.textEntry:getText(), "> I have nails.\n> You have wood?", 1, true) ~= nil, mw.textEntry:getText())
    check("the fields show while writing", mw.toEntry:isVisible() and mw.textEntry:isVisible())
    mw.textEntry:setText("Yes, bring the nails.")
    D.frame()
    D.press(mw, "put")
    check("Put in Outbox: it waits there", #MS.load(b).outbox == 1 and MS.load(b).outbox[1].to == "Ned")
    check("the Outbox is shown, the letter picked", mw.folder == "outbox" and mw.sel == MS.load(b).outbox[1])
    check("the band says it goes at the next join", mw._ask == "UI_ZeD_Mail_Queued(Test Server)", mw._ask)
    check("the fields are gone", not mw.toEntry:isVisible())
    MS.reset(); b.data = nil; b = MS.find(b.key)
    check("the Outbox is on the disk", #MS.load(b).outbox == 1 and MS.load(b).outbox[1].text == "Yes, bring the nails.")

    section("Mail: a new letter, what Put in Outbox needs")
    D.press(mw, "new")
    check("a new letter starts at To", mw.compose and mw.focusId == "f:to")
    check("no name: gray, and says why", D.spec(mw, "put").disabled and D.spec(mw, "put").help == "UI_ZeD_Mail_NeedTo")
    mw.toEntry:setText("Ned"); D.frame()
    check("no words: gray, and says why", D.spec(mw, "put").disabled and D.spec(mw, "put").help == "UI_ZeD_Mail_NeedText")
    mw.textEntry:setText(string.rep("x", Ml_TEXT_MAX or 2001)); D.frame()
    check("too long: gray, and says why", D.spec(mw, "put").disabled and D.spec(mw, "put").help == "UI_ZeD_Mail_TooLong(2000)", D.spec(mw, "put").help)
    mw.textEntry:setText("short"); D.frame()
    D.press(mw, "cancel")
    check("Cancel with words asks", mw.confirm == "discard" and mw.focusId == "confirm:no")
    D.press(mw, "confirm:no")
    check("Keep writing keeps the letter", mw.compose and mw.textEntry:getText() == "short")
    D.press(mw, "cancel"); D.press(mw, "confirm:yes")
    check("Discard drops it", mw.compose == nil and #MS.load(b).outbox == 1)

    section("Mail: delete, a second mailbox, a full Outbox")
    mw.folder = "inbox"; mw.sel = MS.load(b).inbox[1]; D.frame()
    D.press(mw, "delete")
    check("Delete asks and lands on Cancel", mw.confirm == "delete" and mw.focusId == "confirm:no")
    D.press(mw, "confirm:yes")
    check("deleted", #MS.load(b).inbox == 1 and mw.sel == nil)
    MS.box("192.168.1.9:16261", "Rosa", "Other Place")
    D.frame()
    check("two mailboxes: the pop-up opens", D.spec(mw, "box").disabled ~= true)
    D.press(mw, "box")
    check("it lists both", MM.popup and MM.popup.key == "mailboxes" and #MM.popup.items == 2)
    MM.popup.items[2].fn(); D.frame()
    check("picking one shows it", mw:box() and mw:box().server == "Other Place")
    for i = 1, MS.OUT_MAX do MS.queue(mw:box(), "Ned", "", "n" .. i) end
    D.press(mw, "new")
    mw.toEntry:setText("Ned"); mw.textEntry:setText("one more"); D.frame()
    check("a full Outbox: gray, and says why", D.spec(mw, "put").disabled and D.spec(mw, "put").help == "UI_ZeD_Mail_OutboxFull(" .. MS.OUT_MAX .. ")")
    D.press(mw, "cancel"); D.press(mw, "confirm:yes")
    mw:close(); D.frame()
    check("the close box leaves the desktop", MM.view == "desktop")
end

print("desk_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
