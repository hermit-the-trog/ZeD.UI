-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MailCards.lua
-- ============================================================================
-- MAIL IN GAME (punch list 104). Drawing and input only: ZeD_Mail.lua is the model, ZeD_MailStore.lua the copy on this
-- computer. The frame is the ticket cards' (ZeD_TicketCards.lua), in the Server tab, ZeD's social place in a world:
--   the Mail block    the dial-in's state, Inbox with its new letters (a row that opens the Mail card), Write a letter
--   mlinbox           the Mail card: Write a letter, the Inbox, the Outbox while letters wait in it
--   mlread            one letter: who, when, the words; Report, Delete, Reply (Report and Delete ask in the foot). Report
--                     (the director, Nov 7 2026) files a ticket through ZeD's tickets with the letter as the report's
--                     lines: its words reach staff only because the player chose to send them, logged as any report
--   mlwrite           a new letter: To, Subject, the letter; Send puts it in the Outbox and it goes at once
-- A letter can go to any player who has joined this server since it began keeping mail, online or not: the server holds
-- it until they join. Letters are private (ZeD_ServerMail.lua): the help says the server forgets each one once it is
-- handed over and staff cannot read them.
--
-- A server without mail shows no block at all. All player words are drawn with drawText, never as the game's rich text.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Tr"
require "ZeD/ZeD_MailProto"
require "ZeD/ZeD_MailStore"
require "ZeD/ZeD_Mail"
require "ZeD/ZeD_TicketCards"
require "ZeD/ZeD_AdminCards"

ZeD = ZeD or {}
ZeD.MailCards = ZeD.MailCards or {}
local MC = ZeD.MailCards
local M = ZeD.Mail
local MS = ZeD.MailStore
local Ml = ZeD.Ml
local TC = ZeD.TicketCards
local AC = ZeD.AdminCards
local D, B, F = TC._D, TC._B, AC._F

local SHOW_MAX = 50                  -- letters listed on the card (the rest are on the desk at the main menu)

local P = {}     -- the file's helpers (a table: Kahlua counts every local in the chunk)
MC._P = P

local function tr(k, ...) return ZeD.tr(k, ...) end

-- the dial-in in words
function P.dialWords()
    if M.state == "dialing" or M.dialAt then return tr("UI_ZeD_Mail_Dialing") end
    if M.state == "off" then return tr("UI_ZeD_Mail_DialRefused") end
    if M.state ~= "on" then return tr("UI_ZeD_Mail_NotDialed") end
    local b = M.box()
    local parts = { tr("UI_ZeD_Mail_DialedIn", (b and D.clock(b.t)) or "") }
    if (M.got or 0) > 0 then parts[#parts + 1] = tr("UI_ZeD_Mail_GotN", M.got) end
    if (M.sent or 0) > 0 then parts[#parts + 1] = tr("UI_ZeD_Mail_SentN", M.sent) end
    if M.sending then parts[#parts + 1] = tr("UI_ZeD_Mail_Sending") end
    return table.concat(parts, " | ")
end

function P.who(m) return m.returned and tr("UI_ZeD_Mail_Returned") or tostring(m.from) end
function P.subj(m) return (m.subj and m.subj ~= "") and m.subj or tr("UI_ZeD_Mail_NoSubject") end

-- ---------------------------------------------------------------------------
-- THE SERVER TAB'S BLOCK
-- ---------------------------------------------------------------------------
function MC.serverItems(L, win, st)
    if not M.live() then return end
    local b = M.box()
    if not b then return end
    local S2 = ZeD.ServerTab
    if S2 and S2.OPEN and not S2.OPEN.mailwrite then
        S2.OPEN.mailwrite = function(p, w) MC.openWrite(w, w._serverTab) end
    end
    local n = MS.unread(b)
    L[#L + 1] = { k = "head", text = tr("UI_ZeD_Mail_Title"), right = (n > 0) and tr("UI_ZeD_Mail_NNew", n) or nil }
    -- (the dial-in's words are the row's meta: they give way first in a narrow drawer)
    L[#L + 1] = { k = "tk", t = "arow", win = win, left = tr("UI_ZeD_Mail_Inbox"), leftMin = 60, chev = true, meta = P.dialWords(),
        c = { id = "ml:inbox", help = tr("UI_ZeD_Mail_HelpInboxRow"), run = function(ww) MC.openInbox(ww, st) end } }
    L[#L + 1] = { k = "btn", id = "mailwrite", text = tr("UI_ZeD_Mail_WriteLetter"), help = tr("UI_ZeD_Mail_HelpWrite") }
end

function MC.openInbox(win, st) F.push(win, st, { kind = "mlinbox", from = "srv:tk:ml:inbox" }) end

function MC.openWrite(win, st, to, subj, text)
    D.setField(win, "ml:to", to or "")
    D.setField(win, "ml:subj", subj or "")
    D.setField(win, "ml:text", text or "")
    -- (the seeds fill a box the first time it is drawn: before that there is no box to set)
    F.push(win, st, { kind = "mlwrite", from = st.card and "tk:mlwrite" or "srv:mailwrite", to = to,
        seed = { to = to or "", subj = subj or "", text = text or "" } })
end

function MC.openLetter(win, st, folder, m)
    local b = M.box()
    if b and folder == "inbox" then MS.markRead(b, m) end
    F.push(win, st, { kind = "mlread", folder = folder, m = m, from = "tk:ml:" .. folder .. ":" .. tostring(m.id or m.cid) })
end

-- ---------------------------------------------------------------------------
-- THE CARDS
-- ---------------------------------------------------------------------------
TC.kinds.mlinbox = {
    data = function() return M.box() end,
    key = function() return tostring(MS.seq) .. ":" .. tostring(M.seq) end,
    title = function() return tr("UI_ZeD_Mail_Title") end,
    help = function() return tr("UI_ZeD_Mail_HelpPrivate") end,
    gone = function() return tr("UI_ZeD_Mail_Gone") end,
    items = function(win, st, t, card, b)
        local items = {}
        local d = MS.load(b)
        B.sub(items, P.dialWords())
        items[#items + 1] = { k = "btn", c = F.gate({ id = "mlwrite", text = tr("UI_ZeD_Mail_WriteLetter"), help = tr("UI_ZeD_Mail_HelpWrite"),
            run = function(ww) MC.openWrite(ww, st) end }) }
        B.label(items, tr("UI_ZeD_Mail_Inbox"), tostring(#d.inbox))
        if #d.inbox == 0 then B.sub(items, tr("UI_ZeD_Mail_EmptyFolder")) end
        for i = 1, math.min(#d.inbox, SHOW_MAX) do
            local m = d.inbox[i]
            items[#items + 1] = { k = "arow", win = win, left = P.who(m), meta = P.subj(m), dot = not m.read, right = D.shortDate(m.t), chev = true, leftMin = 90,
                c = { id = "ml:inbox:" .. tostring(i), help = tr("UI_ZeD_Mail_HelpLetter"), land = i == 1, run = function(ww) MC.openLetter(ww, st, "inbox", m) end } }
        end
        if #d.inbox > SHOW_MAX then B.sub(items, tr("UI_ZeD_Mail_MoreOnDesk", #d.inbox - SHOW_MAX)) end
        if #d.outbox > 0 then
            B.label(items, tr("UI_ZeD_Mail_Outbox"), tostring(#d.outbox))
            for i, m in ipairs(d.outbox) do
                items[#items + 1] = { k = "arow", win = win, left = tr("UI_ZeD_Mail_ToName", m.to), meta = P.subj(m), chev = true, leftMin = 90,
                    c = { id = "ml:outbox:" .. tostring(i), help = tr("UI_ZeD_Mail_HelpLetter"), run = function(ww) MC.openLetter(ww, st, "outbox", m) end } }
            end
        end
        return items
    end,
}

TC.kinds.mlread = {
    data = function(card) return card.m end,
    key = function(t, card) return tostring(card.folder) .. ":" .. tostring(MS.seq) end,
    title = function(card) return P.subj(card.m) end,
    help = function(t)
        if t.confirm == "report" then return tr("UI_ZeD_Mail_HelpReport") end
        if t.confirm then return tr("UI_ZeD_Mail_AskDelete") end
        return tr("UI_ZeD_Mail_HelpPrivate")
    end,
    gone = function() return tr("UI_ZeD_Mail_Gone") end,
    items = function(win, st, t, card, m)
        local items = {}
        if card.folder == "inbox" then
            B.fact(items, tr("UI_ZeD_Mail_From"), P.who(m))
            B.fact(items, tr("UI_ZeD_Mail_To"), tostring(m.to))
        else
            B.fact(items, tr("UI_ZeD_Mail_To"), tostring(m.to))
        end
        B.fact(items, tr("UI_ZeD_Mail_Date"), D.realDate(m.t) or "")
        if (m.day or 0) > 0 then B.fact(items, tr("UI_ZeD_Mail_Day"), D.day(m.day)) end
        if card.folder == "outbox" then B.sub(items, tr("UI_ZeD_Mail_WaitingHere")) end
        B.msg(items, P.who(m), m.text or "", "plain")
        return items
    end,
    foot = function(win, st, t, card, m)
        if t.confirm == "report" then
            return { question = tr("UI_ZeD_Mail_AskReport"), main = {
                D.btn("mlrno", getText("UI_btn_cancel"), function(ww) t.confirm = nil; D.focusId(ww, st, "tk:mlrep") end, nil, tr("UI_ZeD_Mail_HelpKeep")),
                D.btn("mlryes", tr("UI_ZeD_Mail_Report"), function(ww) t.confirm = nil; P.report(ww, st, t, m) end, "primary", tr("UI_ZeD_Mail_HelpReport")) } }
        end
        if t.confirm then
            return { question = tr("UI_ZeD_Mail_AskDelete"), main = {
                D.btn("mlno", getText("UI_btn_cancel"), function(ww) t.confirm = nil; D.focusId(ww, st, "tk:mldel") end, nil, tr("UI_ZeD_Mail_HelpKeep")),
                D.btn("mlyes", getText("UI_btn_delete"), function(ww)
                    t.confirm = nil
                    local b = M.box()
                    if b then MS.remove(b, card.folder, m) end
                    D.flash(t, tr("UI_ZeD_Mail_Deleted"))
                    TC.back(ww, st)
                end, "danger", tr("UI_ZeD_Mail_HelpDelete")) } }
        end
        local main = {}
        if card.folder == "inbox" then
            local reply = D.btn("mlreply", tr("UI_ZeD_Mail_Reply"), function(ww) P.reply(ww, st, m) end, "primary", tr("UI_ZeD_Mail_HelpReply"))
            if m.returned or (m.from or "") == "" then D.disable(reply, tr("UI_ZeD_Mail_NoReply")) end
            main[#main + 1] = reply
        end
        if card.folder == "inbox" then
            local rep = D.btn("mlrep", tr("UI_ZeD_Mail_Report"), function(ww)
                t.confirm = "report"
                D.focusId(ww, st, "tk:mlrno")             -- (sending a private letter to staff lands on Cancel)
            end, nil, tr("UI_ZeD_Mail_HelpReport"))
            local why = P.reportWhy(m, t)
            if why then D.disable(rep, why) end
            table.insert(main, 1, rep)
        end
        table.insert(main, 1, D.btn("mldel", getText("UI_btn_delete"), function(ww)
            t.confirm = true
            D.focusId(ww, st, "tk:mlno")              -- (a question that loses something lands on Cancel)
        end, nil, tr("UI_ZeD_Mail_HelpDelete")))
        return { main = main }
    end,
    cancel = function(win, st, t)
        if not t.confirm then return false end
        t.confirm = nil
        D.focusId(win, st, "tk:mldel")
        return true
    end,
}

-- why Report is gray, or nil. A report keeps the letter's words on the ticket's record, which needs the server part's
-- reports (the game's own tickets are public: the words never go there)
function P.reportWhy(m, t)
    local S2 = ZeD.ServerPart
    if m.returned or (m.from or "") == "" then return tr("UI_ZeD_Mail_NoReply") end
    if not (S2 and S2.available() and not S2.frozen and S2.cm == true) then return tr("UI_ZeD_Mail_NoReport") end
    if t and t.busy then return tr("UI_ZeD_Tk_Busy") end
    return nil
end

-- the letter as a report's lines: the sender named, the words in pieces of the report's line length
function P.reportOf(m)
    local L = ZeD.Tk.LIMITS
    local text = string.gsub(m.text or "", "\n", " ")
    local rep = { who = tostring(m.from), n = 0 }
    local i = 1
    while i <= #text and rep.n < L.REPORT_LINES do
        rep.n = rep.n + 1
        rep[rep.n] = { who = tostring(m.from), text = string.sub(text, i, i + L.REPORT_TEXT - 1), mark = rep.n == 1 }
        i = i + L.REPORT_TEXT
    end
    return rep
end

function P.report(win, st, t, m)
    if P.reportWhy(m, t) then return end
    local C = ZeD.Tickets
    t.busy = true
    local r = C.ask("GRIEF", false, tr("UI_ZeD_Mail_ReportText", m.from, P.subj(m)), function(a)
        t.busy = nil
        if a.ok == false then D.flash(t, C.errText(a.err, a.left)); return end
        m.reported = true
        D.flash(t, tr("UI_ZeD_Mail_Reported", a.id or ""))
    end, P.reportOf(m))
    if r ~= "sent" then
        t.busy = nil
        D.flash(t, C.errText(r == "wait" and "fail" or "text"))
    end
end

function P.reply(win, st, m)
    local subj = m.subj or ""
    if string.sub(string.lower(subj), 1, 4) ~= "re: " then subj = "Re: " .. subj end
    if #subj > Ml.L.SUBJ_MAX then subj = string.sub(subj, 1, Ml.L.SUBJ_MAX) end
    MC.openWrite(win, st, m.from, subj, "")
end

-- why Send is gray, or nil
function P.sendWhy(win, t)
    local b = M.box()
    if not b then return tr("UI_ZeD_Mail_NotDialed") end
    if t.busy then return tr("UI_ZeD_Tk_Busy") end
    if #MS.load(b).outbox >= MS.OUT_MAX then return tr("UI_ZeD_Mail_OutboxFull", MS.OUT_MAX) end
    if not Ml.line(F.text(win, "ml:to"), Ml.L.TO_MAX) then return tr("UI_ZeD_Mail_NeedTo") end
    if not Ml.subject(F.text(win, "ml:subj")) then return tr("UI_ZeD_Mail_SubjLong", Ml.L.SUBJ_MAX) end
    local text = F.text(win, "ml:text")
    if text == "" then return tr("UI_ZeD_Mail_NeedText") end
    if #text > Ml.L.TEXT_MAX then return tr("UI_ZeD_Mail_TooLong", Ml.L.TEXT_MAX) end
    return nil
end

function P.send(win, st, t)
    if P.sendWhy(win, t) then return end
    local m, err = M.write(F.text(win, "ml:to"), F.text(win, "ml:subj"), F.text(win, "ml:text"))
    if not m then
        D.flash(t, (err == "full") and tr("UI_ZeD_Mail_OutboxFull", MS.OUT_MAX) or tr("UI_ZeD_Mail_NeedText"))
        return
    end
    D.flash(t, tr(M.state == "on" and "UI_ZeD_Mail_OnItsWay" or "UI_ZeD_Mail_QueuedGame"))
    D.setField(win, "ml:to", "")
    D.setField(win, "ml:subj", "")
    D.setField(win, "ml:text", "")
    TC.back(win, st)
end

TC.kinds.mlwrite = {
    data = function() return M.box() end,
    key = function(t, card) return "w:" .. tostring(card.to) end,
    title = function() return tr("UI_ZeD_Mail_NewLetter") end,
    help = function() return tr("UI_ZeD_Mail_HelpWriteCard") end,
    gone = function() return tr("UI_ZeD_Mail_Gone") end,
    items = function(win, st, t, card)
        local items = {}
        B.label(items, tr("UI_ZeD_Mail_To"))
        local seed = card.seed or {}
        F.field(items, "ml:to", 1, tr("UI_ZeD_Mail_HintTo"), card.to == nil, Ml.L.TO_MAX)
        items[#items].seed = seed.to
        B.label(items, tr("UI_ZeD_Mail_Subject"))
        F.field(items, "ml:subj", 1, tr("UI_ZeD_Mail_HintSubject"), false, Ml.L.SUBJ_MAX)
        items[#items].seed = seed.subj
        B.label(items, tr("UI_ZeD_Mail_Letter"))
        F.field(items, "ml:text", 8, tr("UI_ZeD_Mail_HintLetter"), card.to ~= nil, Ml.L.TEXT_MAX)
        items[#items].seed = seed.text
        B.sub(items, tr("UI_ZeD_Mail_HelpPrivate"))
        return items
    end,
    foot = function(win, st, t, card)
        local b = D.btn("mlsend", tr("UI_ZeD_Mail_Send"), function(ww) P.send(ww, st, t) end, "primary", tr("UI_ZeD_Mail_HelpSend"))
        local why = P.sendWhy(win, t)
        if why then D.disable(b, why) end
        return { main = { b } }
    end,
    padX = function(win, st, t)
        local b = D.btn("mlsend", tr("UI_ZeD_Mail_Send"), function(ww) P.send(ww, st, t) end, "primary", tr("UI_ZeD_Mail_HelpSend"))
        local why = P.sendWhy(win, t)
        if why then D.disable(b, why) end
        return b
    end,
}

return MC
