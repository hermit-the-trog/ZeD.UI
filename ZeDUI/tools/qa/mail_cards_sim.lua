-- ZeDUI/tools/qa/mail_cards_sim.lua  (Nov 7 2026, punch list 104): mail's in-game cards in the Server tab with no game running.
-- The harness is community_cards_sim.lua's own (read from that file up to its "-- every state" line, so the two never drift): the
-- real Tokens, Atoms, Molecules, ServerTab and the card frame on Lua 5.1 stubs of a panel, text measures and the focus manager.
-- Every mail state is drawn at the Deck, 720, 1080p and 4K sizes, Normal and Large text, mouse and pad, and checked as that sim
-- checks its own (nothing past the drawer, stops unique and whole, every grayed foot button saying why, no text box outside its
-- view); then the flows: the Mail block, the Inbox card, reading (marked read), Reply, Delete asking first, writing (what Send
-- needs), Send into the Outbox, a server without mail showing no block.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mail_cards_sim.lua
-- It prints FAIL lines and a last line "mail_cards_sim: N checks, M failed", and exits 1 if any failed.

local self = arg and arg[0] or ""
local dir = string.gsub(self, "mail_cards_sim%.lua$", "")
local f = assert(io.open(dir .. "community_cards_sim.lua", "r"))
local src = f:read("*a")
f:close()
local cut = string.find(src, "\n-- every state ---", 1, true)
assert(cut, "community_cards_sim.lua has no '-- every state' line")
local harness = string.sub(src, 1, cut)
harness = string.gsub(harness, "community_cards_sim%%%.lua%$", "mail_cards_sim%%.lua$")

local mail = [==[
do
local MC, ML, MS, Ml = ZeD.MailCards, ZeD.Mail, ZeD.MailStore, ZeD.Ml
check("the mail cards load with the Server tab", MC ~= nil and ML ~= nil and TC.kinds.mlinbox ~= nil)
S.present, S.staff, S.admin = true, false, false
nowMs = 1793913240000
local P0 = newPanel(480, 800)

-- a server without mail: no block
ML.qaHold, ML.qaLink = true, false
frame("server", P0, 480, 800)
-- (the harness reads the real English: a key's words, or the longest piece of them around their %1 and %2)
local function piece(k)
    local w = ZeD.tr(k, "", "")
    local best = ""
    for part in string.gmatch(w .. "", "([^]*)") do if #part > #best then best = part end end
    return best
end
local function drawn(s, p)
    for _, x in ipairs((p or P0).texts) do if string.find(x.s, s, 1, true) then return true end end
    return false
end
check("a server without mail shows no Mail block", not drawn(piece("UI_ZeD_Mail_Title")))

-- the mailbox on this computer, three letters, one waiting in the Outbox
ML.qaLink, ML.state = true, "on"
local b = ML.box()
check("the mailbox for this server and name", b ~= nil and b.key == "10.0.0.5:16261/Aretha", b and b.key)
MS.receive(b, { id = 3, from = "Ned", to = "Aretha", subj = "supplies", text = "I have nails.\nYou have wood?", t = 1793900000, day = 11 })
MS.receive(b, { id = 5, from = "Rosa", to = "Aretha", subj = "", text = string.rep("A long letter about the river crossing. ", 30), t = 1793910000, day = 12 })
MS.receive(b, { id = 9, from = "Ada", to = "Aretha", subj = "Rules", text = "Read the new rules.", t = 1793912000, day = 12 })
MS.save(b)
MS.queue(b, "Ned", "Re: supplies", "Bring them Friday.")
MS.dialed(b)
ML.got, ML.sent = 3, 1

local win = WINS.server
local function st() return stOf("server") end
local function stop(id)
    for _, e in ipairs(stops("server")) do if e.id == id then return e end end
    return nil
end
local function footOf(id)
    for _, r in ipairs(TC.qaState(st()).footRects or {}) do if r.b.id == id then return r.b end end
    return nil
end
local function reset()
    local s0 = st()
    s0.card = nil
    local t0 = TC.qaState(s0)
    t0.confirm, t0.busy, t0.flashText, t0.items = nil, nil, nil, nil
    t0.scroll:setScrollPos(0)
    s0.scroll:setScrollPos(0)
end

-- the states, each from a fresh tab
local STATES = {
    { name = "mail tab", run = function() end },
    { name = "mail inbox card", run = function() MC.openInbox(win, st()) end },
    { name = "mail letter", run = function() MC.openInbox(win, st()); MC.openLetter(win, st(), "inbox", MS.load(b).inbox[3]) end },
    { name = "mail long letter", run = function() MC.openInbox(win, st()); MC.openLetter(win, st(), "inbox", MS.load(b).inbox[2]) end },
    { name = "mail letter confirm", run = function() MC.openInbox(win, st()); MC.openLetter(win, st(), "inbox", MS.load(b).inbox[1]); TC.qaState(st()).confirm = true end },
    { name = "mail outbox letter", run = function() MC.openInbox(win, st()); MC.openLetter(win, st(), "outbox", MS.load(b).outbox[1]) end },
    { name = "mail write empty", run = function() MC.openWrite(win, st()) end },
    { name = "mail write reply", run = function() MC.openWrite(win, st(), "Ned", "Re: supplies", "") end },
    { name = "mail dialing", run = function() ML.state = "dialing" end, after = function() ML.state = "on" end },
}
for _, prof in ipairs(PROFILES) do
    ZEDQA_ROOT = prof.root
    ZEDQA_LARGE = prof.size == "large"
    ZeD.applyTheme("dark", "orange", prof.size)
    local p = newPanel(prof.w, prof.h)
    win._tkFields = nil
    for _, s in ipairs(STATES) do
        for _, pad in ipairs({ false, true }) do
            local name = prof.name .. (pad and " pad " or " mouse ") .. s.name
            FOCUS.pad = pad
            FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
            nowMs = nowMs + 20000
            reset()
            s.run()
            local ok, err = pcall(function()
                frame("server", p, prof.w, prof.h)
                frame("server", p, prof.w, prof.h)
                local list = verify(name, "server", p, prof.w, prof.h)
                if pad then
                    for _, e in ipairs(list) do
                        FOCUS.id, FOCUS.el, FOCUS.win = e.id, e, win
                        frame("server", p, prof.w, prof.h)
                    end
                    FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
                end
            end)
            check(name .. ": draws", ok, err)
            if s.after then s.after() end
        end
    end
end
FOCUS.pad = false
ZEDQA_ROOT, ZEDQA_LARGE = 1, false
ZeD.applyTheme("dark", "orange", "small")

-- the flows at 1080p (the states above read every letter: unread again)
for _, m in ipairs(MS.load(b).inbox) do m.read = false end
local W, H = 480, 800
local P1 = newPanel(W, H)
local function draw() frame("server", P1, W, H); frame("server", P1, W, H) end
local function press(id)
    draw()
    local e = stop(id)
    check("the stop is there: " .. id, e ~= nil)
    if e then e.onActivate(win) end
    draw()
end
reset()
win._tkFields = nil
draw()
check("the Mail block: its head", drawn(piece("UI_ZeD_Mail_Title"), P1))
check("the Mail block counts the new letters", drawn(ZeD.tr("UI_ZeD_Mail_NNew", 3), P1))
check("the dial-in in words", drawn(piece("UI_ZeD_Mail_DialedIn"), P1))
check("Write a letter is a stop", stop("srv:mailwrite") ~= nil)
press("srv:tk:ml:inbox")
check("Inbox opens the Mail card", st().card and st().card.kind == "mlinbox")
check("the card lists the letters, newest first", drawn("Ada", P1) and drawn("Rosa", P1) and drawn("Ned", P1))
check("the Outbox while a letter waits", drawn(piece("UI_ZeD_Mail_Outbox"), P1) and drawn(ZeD.tr("UI_ZeD_Mail_ToName", "Ned"), P1))
check("the help says letters are private", ZeD.Help.last == ZeD.tr("UI_ZeD_Mail_HelpPrivate"), ZeD.Help.last)
local unread0 = MS.unread(b)
press("tk:ml:inbox:1")
check("a letter opens", st().card and st().card.kind == "mlread")
check("opening it marks it read", MS.unread(b) == unread0 - 1)
check("its words are drawn", drawn("Read the new rules.", P1))
check("Reply and Delete in the foot", footOf("mlreply") ~= nil and footOf("mldel") ~= nil)
check("Reply is the main one, last", TC.qaState(st()).footRects[#TC.qaState(st()).footRects].b.id == "mlreply")
-- Report (the director, Nov 7 2026): the letter goes to staff as a ticket, its words in the report's lines
S.cm = true
draw()
check("Report is in the foot", footOf("mlrep") ~= nil and not footOf("mlrep").disabled, footOf("mlrep") and footOf("mlrep").why)
CLIENT = {}
press("tk:mlrep")
check("Report asks first and lands on Cancel", TC.qaState(st()).confirm == "report" and footOf("mlrno") ~= nil and footOf("mlryes") ~= nil)
check("Report's question says staff will read it", ZeD.Help.last == ZeD.tr("UI_ZeD_Mail_HelpReport"), ZeD.Help.last)
press("tk:mlrno")
check("Cancel sends nothing", #CLIENT == 0 and TC.qaState(st()).confirm == nil)
press("tk:mlrep")
press("tk:mlryes")
local filed = nil
for _, c in ipairs(CLIENT) do if c.c == "t_new" then filed = c.a end end
check("Report files a ticket through ZeD's tickets", filed ~= nil and filed.kind == "GRIEF")
check("its words name the sender and subject", filed and filed.text == ZeD.tr("UI_ZeD_Mail_ReportText", "Ada", "Rules"), filed and filed.text)
check("the letter goes as the report's lines, naming the sender", filed and filed.report and filed.report.who == "Ada" and filed.report.n == 1 and filed.report[1].text == "Read the new rules.")
check("the report says it is a letter", filed and filed.report and filed.report.letter == true)
local lab = {}
TC._B.reportChat(lab, { who = "Ada", n = 1, letter = true, { who = "Ada", text = "x" } })
check("the staff card labels it the reported letter", lab[1] and lab[1].text == ZeD.tr("UI_ZeD_Tk_ReportedLetter"), lab[1] and lab[1].text)
check("and its line says the player received it, not that the server hears no chat", lab[#lab].k == "sub" and lab[#lab].text == ZeD.tr("UI_ZeD_Tk_LetterWhose"), lab[#lab].text)
lab = {}
TC._B.reportChat(lab, { who = "Ada", n = 1, { who = "Ada", text = "x" } })
check("a chat report keeps its own label", lab[1] and lab[1].text == ZeD.tr("UI_ZeD_Tk_ChatAround"))
check("and its own line", lab[#lab].text == ZeD.tr("UI_ZeD_Tk_ChatWhose"))
local long = { from = "Rosa", subj = "", text = string.rep("abc ", 500), t = 1 }
local rep = MC._P.reportOf(long)
check("a long letter fits the report's lines, each at most REPORT_TEXT", rep.n <= Tk.LIMITS.REPORT_LINES and #rep[1].text == Tk.LIMITS.REPORT_TEXT)
local all = ""
for i = 1, rep.n do all = all .. rep[i].text end
check("and loses none of a 2000-character letter", all == long.text)
check("returned mail cannot be reported", MC._P.reportWhy({ returned = true, from = "" }) == ZeD.tr("UI_ZeD_Mail_NoReply"))
S.cm = false
check("a server whose tickets keep no reports: gray, and says why", MC._P.reportWhy({ from = "Ned" }) == ZeD.tr("UI_ZeD_Mail_NoReport"))
S.cm = true
press("tk:mldel")
check("Delete asks first", TC.qaState(st()).confirm == true and footOf("mlno") ~= nil and footOf("mlyes") ~= nil)
press("tk:mlno")
check("Cancel keeps it", TC.qaState(st()).confirm == nil and #MS.load(b).inbox == 3)
press("tk:mldel")
press("tk:mlyes")
check("Delete takes it off this computer and goes back", #MS.load(b).inbox == 2 and st().card and st().card.kind == "mlinbox")
press("tk:ml:inbox:2")
press("tk:mlreply")
check("Reply opens a letter to the sender", st().card and st().card.kind == "mlwrite" and win._tkFields["ml:to"] and win._tkFields["ml:to"]._entry:getText() == "Ned")
check("its subject", win._tkFields["ml:subj"]._entry:getText() == "Re: supplies")
draw()
local send = footOf("mlsend")
check("Send is gray with no words, and says why", send and send.disabled and send.why == ZeD.tr("UI_ZeD_Mail_NeedText"), send and send.why)
win._tkFields["ml:text"]._entry:setText(string.rep("w", Ml.L.TEXT_MAX + 1))
draw()
send = footOf("mlsend")
check("too long: gray, and says why", send and send.disabled and send.why == ZeD.tr("UI_ZeD_Mail_TooLong", Ml.L.TEXT_MAX), send and send.why)
win._tkFields["ml:text"]._entry:setText("Friday, then.")
draw()
send = footOf("mlsend")
check("with words Send is live", send and not send.disabled, send and send.why)
local outN = #MS.load(b).outbox
press("tk:mlsend")
check("Send puts it in the Outbox", #MS.load(b).outbox == outN + 1 and MS.load(b).outbox[#MS.load(b).outbox].text == "Friday, then.")
check("and the card goes back", st().card and st().card.kind == "mlread")
check("the fields are cleared for the next", win._tkFields["ml:text"]._entry:getText() == "")
reset()
draw()
press("srv:mailwrite")
check("Write a letter from the tab opens a new letter", st().card and st().card.kind == "mlwrite")
draw()
send = footOf("mlsend")
check("no name: gray, and says why", send and send.disabled and send.why == ZeD.tr("UI_ZeD_Mail_NeedTo"), send and send.why)
for i = #MS.load(b).outbox + 1, MS.OUT_MAX do MS.queue(b, "Ned", "", "x" .. i) end
win._tkFields["ml:to"]._entry:setText("Ned")
win._tkFields["ml:text"]._entry:setText("one more")
draw()
send = footOf("mlsend")
check("a full Outbox: gray, and says why", send and send.disabled and send.why == ZeD.tr("UI_ZeD_Mail_OutboxFull", MS.OUT_MAX), send and send.why)
end
]==]

local chunk = assert(loadstring(harness .. "\n" .. mail .. "\nprint(\"mail_cards_sim: \" .. checks .. \" checks, \" .. failed .. \" failed\")\nif failed > 0 then os.exit(1) end\n", "=mail_cards_sim"))
chunk()
