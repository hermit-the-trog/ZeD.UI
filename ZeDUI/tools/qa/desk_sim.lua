-- ZeDUI/tools/qa/desk_sim.lua  (Nov 7 2026, punch list 104): the desk's notes and mail apps on the main menu, with no game. The
-- real ZeD_MainMenuDesktop.lua, ZeD_MainMenuNotes.lua, ZeD_DeskNotes.lua and ZeD_MainMenuMail.lua run against desk_stub.lua.
--   the desktop's left side: the sticky first, CletusWorks and Mail, the files, columns, never over the right column, the
--     right column's block unchanged (the small layout reads it)
--   Pasties (Nov 10 2026): none at first; the icon sticks a note beside it, stepped, up to eight (the icon gray then);
--     typed in place, saved after the typing stops and on letting go, the field under the pointer only where no window
--     lies over it; the close box throws a note away, asking first when it has words (Throw away, Keep; on a pad Y, A,
--     B, Escape); dragged by its strip, kept where it was let go, held on the desktop, over the icons; on a pad A picks
--     it up, the D-pad moves it, A puts it down, B puts it back, X writes; Enter writes; the one sticky note from
--     before moves into Pastie 1
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
local pz = D.cell("pasties")
check("Pasties heads the left column", pz and pz.x == D.L.tx + 14 and pz.y == D.L.ty + 24 + 14, pz and (pz.x .. "," .. pz.y))
check("its label reads Pasties (the key)", pz and pz.item.label == "UI_ZeD_Desk_Pasties")
check("Pasties has its own picture", pz and (pz.item.icon or pz.item.id) == "pasties")
check("the desk starts with no notes", #N.pasties() == 0 and not ids():find("pastie:", 1, true), ids())
local cw = D.cell("cletusworks")
check("CletusWorks under Pasties", cw and cw.y > pz.y and cw.left)
check("its label reads CletusWorks (the key)", cw and cw.item.label == "UI_ZeD_Desk_CletusWorks")
check("CletusWorks has its own picture", cw and (cw.item.icon or cw.item.id) == "cletusworks")
if MAIL then
    local ml = D.cell("mail")
    check("Mail under CletusWorks", ml and ml.y > cw.y)
end
local block = MM.iconBlock(D.L)
check("the right column's block leaves the left side out", block.w < 200, block.w)
local right = D.cell("pz")
check("the right column is still there", right and right.x > D.L.tx + D.L.tw / 2)

-- ---------------------------------------------------------------------------
section("Pasties: a note")
root.icons:open("pasties")
D.frame()
local n1 = D.cell("pastie:1")
check("opening Pasties sticks a note on the desk", n1 ~= nil and #N.pasties() == 1, ids())
check("124 x 124 design units", n1 and n1.w == 124 and n1.h == 124)
check("beside the icon, at its top", n1 and n1.x == pz.x + pz.w + 8 and n1.y == pz.y, n1 and (n1.x .. "," .. n1.y))
check("kept in the Pasties file", DISK[N.PASTIES_FILE] and DISK[N.PASTIES_FILE]:sub(1, 2) == "1|", DISK[N.PASTIES_FILE])
check("selected", root.icons.focusId == "pastie:1", root.icons.focusId)
local se = root.pasties[1].entry
check("with the mouse the caret is in it", se:isFocused())
check("its field is placed over its paper", root.pasties[1].x == n1.x and root.pasties[1].y == n1.y and se:isVisible())
check("its hint", se._zedPh == "UI_ZeD_Desk_StickyHint" or se.placeholder == "UI_ZeD_Desk_StickyHint", se._zedPh or se.placeholder)
check("it holds STICKY_MAX", se.maxLen == N.STICKY_MAX)
local F1 = N.PASTIE_PREFIX .. "1.txt"
se:type("seed 7741")
check("while typing, the desktop's keys are the note's", root.icons:keyOther(Keyboard.KEY_UP) == false)
D.frame(100)
check("not saved while typing", DISK[F1] == "\n", DISK[F1])
D.frame(900)
check("saved once the typing stops", DISK[F1] == "seed 7741\n", DISK[F1])
se:type("\nserver pw: dog")
local ex, ey = se:getAbsoluteX() + 5, se:getAbsoluteY() + 5
W.mouse.x, W.mouse.y, W.down = D.L.tx + 500, D.L.ty + 600, true
D.frame(16)
W.down = false
D.frame(16)
check("a press outside lets go", not se:isFocused())
check("letting go saves", DISK[F1] == "seed 7741\nserver pw: dog\n", DISK[F1])
check("the field takes the press on the desktop", MM.entryUnder(ex, ey) == se)
MM.showView("main")
root.win.x, root.win.y, root.win.width, root.win.height = n1.x + 300, D.L.ty + 30, 500, 500
root.win.visible = true
D.frame()
check("beside the main window the note takes the press", MM.entryUnder(ex, ey) == se)
root.win.x = D.L.tx
check("under the main window it does not", MM.entryUnder(ex, ey) == nil)
root.win.x = n1.x + 300
MM.ctx.open = "file"
check("not while a menu is open", MM.entryUnder(ex, ey) == nil)
MM.ctx.open = nil
MM.showView("desktop")
D.frame()
-- the controller reaches it from the icon, X brings up the keyboard on its field
W.pad = true
root.icons.focusId = "pasties"
root.icons:joyDir("right")
check("right from the Pasties icon is its note", root.icons.focusId == "pastie:1", root.icons.focusId)
W.kbd = {}
root.icons:joyX()
check("X on a note brings up the keyboard on its field", W.kbd[1] == se)
W.pad = false
se:unfocus()
N.reset()
local se2 = ZeD_MMSticky:new(1)
root:addChild(se2)
check("a note reads its words at the next start", se2.entry:getText() == "seed 7741\nserver pw: dog")
check("and its place", N.pastie(1) ~= nil)

-- ---------------------------------------------------------------------------
section("Pasties: up to eight, stepped")
for _ = 2, 8 do root.icons:open("pasties"); D.frame() end
check("eight on the desk", #N.pasties() == 8, #N.pasties())
for k = 2, 8 do
    local c = D.cell("pastie:" .. k)
    check("note " .. k .. " stepped 14 down and right from the one before", c and c.x == n1.x + 14 * (k - 1) and c.y == n1.y + 14 * (k - 1), c and (c.x .. "," .. c.y))
end
check("the icon is gray at eight", D.cell("pasties").item.off() == true)
root.icons:open("pasties"); D.frame()
check("a ninth isn't made", #N.pasties() == 8)
local function zedItem(text) for _, it in ipairs(MM.menuItems("zed")) do if type(it) == "table" and it.text == text then return it end end end
check("Pasties in the ZeD menu, gray at eight", zedItem("UI_ZeD_Desk_Pasties") and zedItem("UI_ZeD_Desk_Pasties").disabled == true)
local last = D.cell("pastie:8")
local lastHit
for _, h in ipairs(root.icons._hits) do
    if last.x + 20 >= h.x and last.x + 20 < h.x + h.w and last.y + 3 >= h.y and last.y + 3 < h.y + h.h then lastHit = h.id end
end
check("the newest lies on top: its strip takes the pointer", lastHit == "desk:pastie:8", lastHit)

-- ---------------------------------------------------------------------------
section("Pasties: closing throws away")
local function pressRelease(x, y)
    W.mouse.x, W.mouse.y = x, y
    W.down = true; D.frame(16); W.down = false; D.frame(16)
end
local c8 = D.cell("pastie:8")
MM.ctx.hot = "desk:pastie:8"
local cb = c8.item.closeBox(c8)
pressRelease(cb.x + 2, cb.y + 2)
check("an empty note goes at once", D.cell("pastie:8") == nil and #N.pasties() == 7, #N.pasties())
check("its file emptied", DISK[N.PASTIE_PREFIX .. "8.txt"] == "\n")
check("with the mouse nothing is selected after", root.icons.focusId == nil, root.icons.focusId)
check("the icon is live again", not D.cell("pasties").item.off())
-- a note with words asks first
local c1 = D.cell("pastie:1")
MM.ctx.hot = "desk:pastie:1"
cb = c1.item.closeBox(c1)
pressRelease(cb.x + 2, cb.y + 2)
check("a note with words asks first", D.cell("pastie:1") ~= nil and MM._pastieAsk[1] == true)
local function hitFn(id) for _, h in ipairs(root.icons._hits) do if h.id == id then return h.fn end end end
check("its question's buttons take the pointer", hitFn("desk:pastie:1:throw") ~= nil and hitFn("desk:pastie:1:keep") ~= nil)
hitFn("desk:pastie:1:keep")(); D.frame()
check("Keep: still there, its words too", D.cell("pastie:1") ~= nil and N.pastieText(1) == "seed 7741\nserver pw: dog" and not MM._pastieAsk[1])
pressRelease(cb.x + 2, cb.y + 2)
hitFn("desk:pastie:1:throw")(); D.frame()
check("Throw away: gone, its words with it", D.cell("pastie:1") == nil and DISK[F1] == "\n" and #N.pasties() == 6)
root.icons:open("pasties"); D.frame()
check("a new note takes the freed slot, empty", D.cell("pastie:1") ~= nil and root.pasties[1].entry:getText() == "")
-- the controller: Y asks, B keeps, Y and A throw away
local c2 = D.cell("pastie:2")
root.pasties[2].entry:setText("milk"); root.pasties[2]:keep()
W.pad = true
root.icons.focusId = "pastie:2"
root.icons:joyY(); D.frame()
check("Y on a note with words asks", MM._pastieAsk[2] == true and D.cell("pastie:2") ~= nil)
check("the prompts: A Throw away, B Keep", root.icons:prompts()[1].label == "UI_ZeD_Desk_PastieThrow" and root.icons:prompts()[2].label == "UI_ZeD_Cl_Keep")
root.icons:joyB(); D.frame()
check("B keeps it", not MM._pastieAsk[2] and D.cell("pastie:2") ~= nil)
root.icons:joyY(); root.icons:joyA(); D.frame()
check("Y then A throws it away", D.cell("pastie:2") == nil)
check("the focus moves on", root.icons.focusId ~= "pastie:2" and root.icons.focusId ~= nil, root.icons.focusId)
root.icons.focusId = "pastie:3"
root.pasties[3].entry:setText("x"); root.pasties[3]:keep()
root.icons:joyY()
check("Escape keeps an asking note", root.icons:keyEscape() == true and not MM._pastieAsk[3] and D.cell("pastie:3") ~= nil)
W.pad = false
MM.ctx.hot = nil

-- ---------------------------------------------------------------------------
section("Pasties: a note moves (punch list 114)")
do
    W.down = false
    D.frame()
    local s0 = D.cell("pastie:3")
    local room = s0.room
    MM.ctx.hot = "desk:pastie:3"
    W.mouse.x, W.mouse.y = s0.x + 20, s0.y + 3
    W.down = true; D.frame()
    W.mouse.x, W.mouse.y = s0.x + 220, s0.y + 153
    D.frame()
    local s1 = D.cell("pastie:3")
    check("114: it follows the pointer while held", s1.x == s0.x + 200 and s1.y == s0.y + 150, s1.x .. "," .. s1.y)
    local before = DISK[N.PASTIES_FILE]
    W.down = false; D.frame()
    s1 = D.cell("pastie:3")
    check("114: let go, it stays there", s1.x == s0.x + 200 and s1.y == s0.y + 150)
    check("114: its place is kept", DISK[N.PASTIES_FILE] ~= before)
    check("114: the field moved with its paper", root.pasties[3].x == s1.x and root.pasties[3].y == s1.y)
    W.mouse.x, W.mouse.y = s1.x + 40, s1.y + 60
    W.down = true; D.frame(); W.mouse.x = W.mouse.x + 100; D.frame(); W.down = false; D.frame()
    check("114: a press on the words doesn't move it", D.cell("pastie:3").x == s1.x)
    W.mouse.x, W.mouse.y = s1.x + 20, s1.y + 3
    W.down = true; D.frame(); W.mouse.x, W.mouse.y = -500, -500; D.frame(); W.down = false; D.frame()
    local s2 = D.cell("pastie:3")
    check("114: it stops at the desktop's corner", s2.x == D.L.tx + 14 and s2.y == room.y0, s2.x .. "," .. s2.y)
    local lastHit
    for _, h in ipairs(root.icons._hits) do
        if s2.x + 20 >= h.x and s2.x + 20 < h.x + h.w and s2.y + 3 >= h.y and s2.y + 3 < h.y + h.h then lastHit = h.id end
    end
    check("114: over the Pasties icon its strip still takes the pointer", lastHit == "desk:pastie:3", lastHit)
    W.mouse.x, W.mouse.y = s2.x + 20, s2.y + 3
    W.down = true; D.frame(); W.mouse.x, W.mouse.y = 5000, 5000; D.frame(); W.down = false; D.frame()
    local s3 = D.cell("pastie:3")
    check("114: and at the far one", s3.x + s3.w == D.L.tx + D.L.tw - 14 and s3.y + s3.h == D.L.ty + D.L.th - 14, s3.x .. "," .. s3.y)
    MM.ctx.hot = nil
    W.mouse.x, W.mouse.y = s3.x + 20, s3.y + 3
    W.down = true; D.frame(); W.mouse.x = W.mouse.x - 300; D.frame(); W.down = false; D.frame()
    check("114: not where something lies over it", D.cell("pastie:3").x == s3.x)
    N.reset(); D.frame()
    check("114: the place is read back at the next start", D.cell("pastie:3").x == s3.x and D.cell("pastie:3").y == s3.y)
    -- the controller: A picks it up, the D-pad moves it, A puts it down, B and Escape put it back
    W.pad = true
    root.icons.focusId = "pastie:3"
    local p0 = D.cell("pastie:3")
    root.icons:joyA()
    check("114: A picks it up", root.icons._carry ~= nil)
    check("114: the prompts while carrying: Put down", root.icons:prompts()[2].label == "UI_ZeD_Desk_StickyPutDown")
    root.icons:joyDir("left"); D.frame(); root.icons:joyDir("left"); D.frame(); root.icons:joyDir("up"); D.frame()
    local p1 = D.cell("pastie:3")
    check("114: the D-pad moves it a step each press", p1.x == p0.x - 32 and p1.y == p0.y - 16, p1.x .. "," .. p1.y)
    root.icons:joyA(); D.frame()
    check("114: A puts it down", root.icons._carry == nil)
    root.icons:joyA(); root.icons:joyDir("right"); D.frame(); root.icons:joyB(); D.frame()
    check("114: B puts it back", D.cell("pastie:3").x == p1.x and D.cell("pastie:3").y == p1.y)
    W.pad = false
    root.icons.focusId = "pastie:3"
    root.pasties[3].entry:unfocus()
    root.icons:keyOther(Keyboard.KEY_RETURN)
    check("114: Enter on a note writes on it", root.pasties[3].entry:isFocused())
    root.pasties[3].entry:unfocus()
end

-- ---------------------------------------------------------------------------
section("Pasties: the one sticky note from before")
do
    local saved = {}
    for k, v in pairs(DISK) do saved[k] = v end
    for k in pairs(saved) do if k:find("^ZeD_desk_pastie") then DISK[k] = nil end end
    DISK[N.STICKY_FILE] = "old words\nsecond line\n"
    DISK[N.PLACE_FILE] = "1|0.5000|0.2500\n"
    N.reset()
    local list = N.pasties()
    check("its words become Pastie 1", #list == 1 and list[1].id == 1 and N.pastieText(1) == "old words\nsecond line")
    check("where it sat", list[1].fx == 0.5 and list[1].fy == 0.25)
    check("the old note's file is emptied", DISK[N.STICKY_FILE] == "\n")
    check("the Pasties file is written", DISK[N.PASTIES_FILE] ~= nil and DISK[N.PASTIES_FILE]:sub(1, 2) == "1|")
    N.reset()
    check("read once: the next start keeps it", #N.pasties() == 1)
    for k in pairs(DISK) do if k:find("^ZeD_desk_pastie") then DISK[k] = nil end end
    DISK[N.STICKY_FILE] = "\n"
    N.reset()
    check("an empty old note brings none", #N.pasties() == 0)
    for k in pairs(DISK) do DISK[k] = nil end
    for k, v in pairs(saved) do DISK[k] = v end
    N.reset(); D.frame()
end
MM.showView("desktop")
D.frame()

-- ---------------------------------------------------------------------------
section("Pasties: QA's Mac run, Nov 10 2026 (stacked words, a new note under a window, Throw away)")
do
    MM.showView("desktop"); D.frame()
    local ids0 = {}
    for _, pa in ipairs(N.pasties()) do ids0[#ids0 + 1] = pa.id end
    for _, id in ipairs(ids0) do N.throwPastie(id) end
    D.frame()
    -- two notes, the second dragged over the first
    root.icons:open("pasties"); D.frame()
    root.icons:open("pasties"); D.frame()
    local a, b = N.pasties()[1].id, N.pasties()[2].id
    root.pasties[a].entry:setText("under words"); root.pasties[a]:keep()
    root.pasties[a].entry:unfocus(); root.pasties[b].entry:unfocus()
    local ca, cbb = D.cell("pastie:" .. a), D.cell("pastie:" .. b)
    N.movePastie(b, N.pastie(b).fx, N.pastie(b).fy, true)
    -- (b sits 14 down and right of a: they overlap; a moment on, so the new notes' boxes have settled)
    D.frame(500); D.frame()
    check("QA 2: the lower note's own box is down", not root.pasties[a].entry:isVisible())
    check("QA 2: the top note's box is up", root.pasties[b].entry:isVisible())
    -- its words are drawn by the icon layer, in the pile's order
    local drawn = {}
    local real = root.icons.drawText
    root.icons.drawText = function(self, s2) drawn[#drawn + 1] = tostring(s2) end
    D.frame()
    root.icons.drawText = real
    local saw = false
    for _, t in ipairs(drawn) do if t == "under words" then saw = true end end
    check("QA 2: the icon layer draws the lower note's words", saw)
    -- a press on the lower note's words where they show: it comes up, on top, with the caret
    local ea = root.pasties[a].entry
    local px, py = ea:getAbsoluteX() + 3, ea:getAbsoluteY() + 3      -- (its top left: b's starts 14 to the right)
    local got = MM.entryUnder(px, py)
    check("QA 2: a press on the lower note's words reaches them", got == ea)
    check("QA 2: and brings that note to the top of the pile", N.pasties()[#N.pasties()].id == a, N.pasties()[#N.pasties()].id)
    check("QA 2: its box up with the caret", ea:isVisible() and ea:isFocused())
    D.frame()
    check("QA 2: now the other one's box is down", not root.pasties[b].entry:isVisible())
    -- a press where the top note lies over the lower one goes to the top note only
    ea:unfocus(); D.frame(600)
    local eb = root.pasties[b].entry
    local qx, qy = eb:getAbsoluteX() + 3, eb:getAbsoluteY() + 3
    check("QA 2: where they overlap the top note has the press", MM.entryUnder(qx, qy) ~= eb)
    -- dragging a note by its strip brings it to the top
    local cb2 = D.cell("pastie:" .. b)
    MM.ctx.hot = "desk:pastie:" .. b
    W.mouse.x, W.mouse.y = cb2.x + 20, cb2.y + 3
    W.down = true; D.frame(); W.down = false; D.frame()
    MM.ctx.hot = nil
    check("QA 2: a note picked up by its strip lies on top", N.pasties()[#N.pasties()].id == b)
    -- the ask: Throw away over Keep, each the note's width
    root.pasties[b].entry:setText("x"); root.pasties[b]:keep()
    local cB = D.cell("pastie:" .. b)
    cB.item.close(); D.frame()
    local hs = cB.item.hits(nil, D.cell("pastie:" .. b))
    local th, kp = hs[1], hs[2]
    check("QA 4: Throw away over Keep", th.y + th.h <= kp.y and th.x == kp.x, th.y .. " / " .. kp.y)
    check("QA 4: each the note's width less its pads", th.w == cB.w - 10 and kp.w == cB.w - 10, th.w)
    MM.answerPastie(b, false); D.frame()
    -- a new note with the main window over the place beside the icon: it goes beside the window, the caret in it
    for _, id in ipairs({ a, b }) do N.throwPastie(id) end
    D.frame()
    MM.showView("main")
    local pz2 = D.cell("pasties")
    root.win.x, root.win.y, root.win.width, root.win.height = pz2.x + pz2.w, D.L.ty + 30, 400, 400
    root.win.visible = true
    D.frame()
    local id3 = MM.newPastie(); D.frame()
    local c3 = D.cell("pastie:" .. id3)
    local wx = root.win:getAbsoluteX() - root.icons:getAbsoluteX()
    check("QA 3: a new note goes beside the window, not under it", c3 and c3.x >= wx + root.win.width, c3 and (c3.x .. " vs " .. (wx + root.win.width)))
    check("QA 3: the caret in it", root.pasties[id3].entry:isFocused())
    root.pasties[id3].entry:unfocus()
    -- a window over the whole desk: the note goes beside the icon, and no caret (the typing would go out of sight)
    root.win.x, root.win.y, root.win.width, root.win.height = D.L.tx, D.L.ty, D.L.tw, D.L.th
    D.frame()
    local id4 = MM.newPastie(); D.frame()
    check("QA 3: under a window over the whole desk, no caret", id4 and not root.pasties[id4].entry:isFocused())
    for _, id in ipairs({ id3, id4 }) do if id then N.throwPastie(id) end end
    root.win.visible = false
    MM.showView("desktop"); D.frame()
end

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
-- (the column's items only: a Pastie lies where it was put, anywhere on the desk)
for _, c in ipairs(root.icons._cells) do
    if c.left and not c.free and c.x + c.w > maxX then maxX = c.x + c.w end
end
check("the left column never reaches the right column", maxX < right.x, maxX .. " vs " .. right.x)
local lefts = 0
for _, c in ipairs(root.icons._cells) do if c.left and not c.free then lefts = lefts + 1 end end
check("24 notes still make only the four column items", lefts == (MAIL and 4 or 3), lefts)
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
check("Pasties in the ZeD menu", found["UI_ZeD_Desk_Pasties"] ~= nil)
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
