# The desk's notes and mail: check (Nov 7 2026, Build, punch list 104)

Built on a worktree branch, not run in the game (the rule for this piece: never launch it). Everything below was proved by
sims on Lua 5.1 against stubs of the game; what only the engine can answer is listed for QA at the end.

## What was built

**Notes (the director's pick: both)**
- **The sticky note**: pale yellow paper at the top of the desktop's left edge, always there, under the windows like the
  icons. Typed in place: a click puts the caret in it wherever it shows (a window over it keeps its own part); the
  D-pad reaches it like an icon and A brings up ZeD's keyboard. It saves itself 0.8 s after the typing stops, and at
  once when it lets go of the keys (Escape, or a press anywhere else). 600 characters, 12 lines.
- **CletusWorks** (desktop icon "CletusWorks", a page of handwriting with a pencil, baked in the desk icons' style by
  `tools/mainmenu/bake_desktop_icons.py`; the window "CletusWorks Notepad"): one page in a ZeD window on the monitor. The
  band: New, Open (a pop-up of the desktop's notes), Rename (a field in the band), Delete (asks in the band, lands on
  Cancel), Save. The page's name is in the title bar; the band's line says Saved / Not saved / Not on the desktop yet.
  A new page goes on the desktop as an icon (a page of typed lines) when it is first saved; a double click (or A) on an
  icon opens it. Leaving unsaved words (close box, B, New, Open, another icon) asks "Save changes?": Discard changes,
  Cancel (the focus lands here), Save.
- Words not saved are also kept as a draft every 1.5 s and when the notepad's view is left, so a game started from the
  menu bar or a crash loses nothing: the notepad opens with them next time and says "Brought back from last time".
- The ZeD menu (the logo, where System 7 kept desk accessories) opens CletusWorks Notepad and Mail too.
- Files, under Zomboid/Lua (per player on this computer, outside the mod: they survive updates):
  `ZeD_desk_sticky.txt`, `ZeD_desk_notes.txt` (the index), `ZeD_desk_note_<id>.txt`, `ZeD_desk_draft.txt`. Lua has no
  delete, so a deleted note's file is emptied and its id reused: never more than 24 note files.
- The desktop's left column: the sticky, CletusWorks, Mail, then the notes, in columns to the right when one fills,
  never over the right column and clear of the controller's prompt strip. The right column (and so the small layout's
  sums, `MM.iconBlock`) is unchanged.

**Mail (multiplayer, dial-up)**
- **Server** (`server/ZeD/ZeD_ServerMail.lua`, module `ZeDP`, shared `ZeD_MailProto.lua`): the post office, not the
  mailbox. It holds a player's letters until they are handed over and forgets each one the moment their computer says
  it has it. `p_dial` (the dial-in: this player can be mailed from now on; the first batch comes down), `p_got` (the
  client has these ids; the next batch follows), `p_send` (to, subject, words, a letter number). The sender is always
  the player the event gives. Any player seen on the server since mail came can be written to, online or not.
  Validation: name 64, subject 80 (one line, may be empty), words 1 to 2000 (control characters out), letter number
  32 of [A-Za-z0-9_-]; a letter number already taken answers ok and delivers nothing (an answer that was lost). Limits:
  2 s between letters, 60 letters an hour, the general ZeD limit. Caps, oldest first: 50 letters waiting per player
  (FIFO), 3,000,000 characters in all, 5,000 players known. Batches of 10. Versioned table with a frozen mode, as
  community's. All commands through `Srv.register`, so the gates on the other branch (`Srv.gates`: a standing ban, the
  join rules unanswered) shut mail as they shut the rest once merged. `ZeD_ServerAdmin.lua` is untouched.
- **Joining is the dial-in** (`client/ZeD/ZeD_Mail.lua`): the hello says the server keeps mail (`r.ml`); 3 s later
  (the join is busy) the client dials once in the connection. Letters come down in batches, are written to this
  computer, then answered a batch a second; the Outbox goes up a letter at a time. A letter written in game goes
  through the same Outbox. While a player is on, a letter sent to them comes down at once. A note in Messages says
  who wrote. A refusal of the letter (nobody by that name here, words refused) brings it back to the Inbox as returned
  mail, as 1993 mail did; a refusal of the player (a ban, the rules, the hour, no answer) leaves the Outbox for later.
  No answer to the dial is tried again 3 times; a quick rejoin waits out the server's limit and dials then.
- **The copy on this computer** (`client/ZeD/ZeD_MailStore.lua`): one mailbox per server and username,
  `ZeD_mail_boxes.txt` and `ZeD_mail_<n>.txt`, Inbox (200 kept), Outbox (20, says when full), Sent (100), the ids
  already handed over (so a letter never comes twice). One record a line, fields escaped.
- **The desk's Mail** (`ZeD_MainMenuMail.lua`, desktop icon "Mail", an envelope under a modem's waves, "Mail (2)" when
  letters are unread): the mailbox (a pop-up past one), the folders as tabs, the letters, the letter on the right; New
  letter, Reply (quotes the letter with "> "), Delete (asks); writing: To, Subject, the letter, Cancel (asks when there
  are words) and Put in Outbox, gray with the reason (no name, no words, too long, the Outbox full). The band says the
  last dial-in and what waits. Nobody has dialed in yet: the window says how mail comes.
- **In game** (`ZeD_MailCards.lua`, in the Server tab, ZeD's social place in a world): a Mail block on a server that
  keeps mail (the dial-in in words, Inbox with the count of new letters, Write a letter), the Mail card (the Inbox, the
  Outbox while letters wait), a letter's card (From, To, the date, the game day, the words; Reply, Delete asking in the
  foot) and the new letter's card (To, Subject, the letter; Send, gray with its reason).

**Words**: 97 keys, `UI_ZeD_Desk_*` and `UI_ZeD_Mail_*`, in all 28 languages (machine drafts as the rest; ES_CL and
ES_MX from ES with the American words for the computer and the pad, PT from PTBR with the European words, CH from CN by
character). Buttons reuse the game's words (New, Open, Rename, Delete, Save, Cancel) and ZeD's Discard changes.

## Privacy (the rule this follows)

`MP_SERVER_PART_DESIGN.md` and `MP_ADMIN_SCOPE.md` give staff tickets, reports with their chat lines, and the action
log; **no rule covers letters between players**, so, as asked, mail stays private: the table has a secret random name
and is never transmitted, no capability or command reads anyone's box, and nothing about a letter reaches the log (not
its words, not who wrote to whom). The log hears only what every ZeD command already writes for anyone (bad arguments
with the command's name, the general rate limit). The card's help says letters are private and that the server keeps
each one only until it is handed over. The owner of a server can still read the save's files on disk; Lua cannot stop
that. A design question below.

## Sims (all pass)

| Sim | Checks | What |
|---|---|---|
| `desk_notes_sim.lua` | 56 | the notes model: save, load, rename, delete, the sticky, the draft, the cap, names, exact round-trips, a broken index, a reader that throws |
| `desk_sim.lua` (+ `desk_stub.lua`) | 108 | the real desktop, notepad and Mail windows on a stub desk: the left column, the sticky (typing, saving, letting go, the field under the pointer only where nothing covers it, the pad), every CletusWorks flow, the draft after a restart, the ZeD menu; Mail's mailboxes, reading, Reply, the Outbox, what Put in Outbox needs, Delete asking, two mailboxes, a full Outbox |
| `mail_sim.lua` | 81 | server and clients over a stub network: the dial-in, offline delivery on join, the outbox on connect, live delivery, batches, every field's validation, rate limits, the caps (FIFO, words, players), a letter sent twice, a lost handover, privacy, a gate refusing, a restart, a frozen table, a server without mail |
| `mail_cards_sim.lua` | 4,761 | the in-game cards on community_cards_sim's harness: every state at Deck, 720, 1080p and 4K, Normal and Large, mouse and pad, then the flows |
| existing: community_cards, claim_cards, ticket_cards, extras_cards, admin_cards, log_cards, community, tickets, admin, claims, extras, log | all pass | the Server tab and the link they share, after the hooks |
| `i18n_guard.py` | PASS | keys, placeholders, no unlisted English |

Run from the repo root with Lua 5.1: `lua51 ZeDUI/tools/qa/<sim>.lua`.

## For QA in game (not provable by sims)

1. **The sticky's field in the engine**: a press on it goes through the desk's glass to the field (MM.entryUnder now
   also answers for the sticky, outside the active window). Typing, the caret, a press elsewhere letting go, the pad
   keyboard. That the keys typed into it never reach the desktop's arrow keys.
2. **The notepad's text box at length**: the game's box keeps the caret in view as you type (`keepCursorVisible` is in
   `UITextBox2`); the wheel over the page scrolls it (`setYScroll`). No ZeD scroll bar is drawn on the page: the box
   has no height the Lua can read. Check a page of 100 lines.
3. **The left column at Deck / 720 / 1080p / 4K**: the sticky beside the main window (at 1080p there are 12 units
   between them), the icons' columns, many notes, Large text.
4. **The icons' art** in game at whole multiples (`cletusworks.png`, `note.png`, `mail.png`; the old nine are
   byte-identical after the re-bake).
5. **Mail on the local server with two players** (`batch_two_b7` style): the dial-in, a letter to an offline player
   delivered on their join, live delivery, the Outbox written at the desk going up on the next join, returned mail,
   the Messages note, the desk reading the copy afterwards. Whether a batch of 10 letters of 2,000 characters crosses
   in one `sendServerCommand` (about 20 kB) on a real server.
6. **The rules gate and bans** once the `Srv.gates` branch merges: a player who has not agreed is refused (the Outbox
   stays) and dials the moment they agree (`S.onAgreed`).
7. **The join's burst**: the dial waits 3 s after the hello so tickets, admin and community ask first; check that no
   ZeD command is dropped by the general limit (10 in 5 s) on a real join.

## Design questions for the director

1. **Privacy**: letters are private and staff cannot read them (no rule said otherwise). Should a player be able to
   **report a letter** to the admins (it would go with the report, as chat lines do), and should **Mute** in chat also
   hide that player's letters?
2. **Who can be written to**: anyone who has joined the server since mail came. Should players be able to **look up
   names** (a list of known players in the To field), or keep typing them as in 1993?
3. **The modem moment**: today the dial-in shows as words ("Dialing in...", "Dialed in at 9:42 PM | 3 received | 1
   sent") and a Messages note. A modem sound, or a small "connecting" strip on join?
4. **Mail's name**: CletusWorks has its joke; Mail is plain "Mail". A period name for it?
5. **Notes sync**: notes are per computer. Should the sticky also be readable in game (the Journal, or the desk)?

## Round two: the director's answers (Nov 7 2026)

Questions 1 to 5 above are answered and built. To stays a typed name, and the sticky note stays on the desk only.

- **The name: "ProtoPOP3 Mail"** on the desktop icon ("ProtoPOP3 Mail (2)" with unread letters), the window's title and
  the ZeD menu. The in-game cards keep the short word Mail.
- **Report** (in game, on a received letter's card): Report asks first in the foot and lands on Cancel ("Send this
  letter to the admins? They will read it."). It files a ticket through ZeD's own tickets (`ZeD.Tickets.ask`, kind
  Griefing). The ticket's text names the sender and the subject, and the letter goes as the report's lines (the
  sender named, the words in 300-character pieces, so all 2,000 characters fit in the 11 lines). It is logged like any
  report: the ticket kind with the sender as the target. The words reach staff only because the player chose this.
  Report is gray, with its reason, on returned mail and on a server whose tickets keep no reports (no server part, a
  frozen table, a part from before Phase 5). The game's own tickets are public, so the words never go there. At the
  desk there is no Report: nothing can be sent from the main menu.
- **Mute**: ZeD's mute list was the player's alone (ZeD_Chat.lua: "the server never hears of it"). Mail now hands it
  to the mail part: with the dial-in, before anything comes down, and again at every Mute or Unmute while on (`p_mute`,
  the whole list, at most 200 names). A letter to someone who muted the sender is not delivered, and the sender gets
  the same ok, with the same fields, as for any letter, so nothing tells them. Letters already waiting from a newly
  muted player go. The list sits in the secret table and is never logged.
- **The dial-in**: a short modem handshake made here by `ZeDUI/tools/sound/make_modem.py`. It uses numpy only: a dial
  tone, seven DTMF digits, the 2100 Hz answer tone with its phase reversals, a chirp, alternating tones, then filtered
  noise for the training. No recording from anywhere. It is 4 s, mono 22,050 Hz 16-bit PCM, `media/sound/ZeD_modem.wav`
  (176 kB), a plain .wav like the game's own clips. `media/scripts/ZeD_Sounds.txt` names it `ZeDModemDial` in the UI
  category, so it plays on the game's UI volume through `playUISound`. It plays once a connection, when the dial-in
  starts. When the server answers, "Connecting... sending N, receiving M" goes over the head as a ZeD bubble note
  (`ZeD.Bubbles.note`) and into Messages' log of over-head notes (`ZeD.Messages.halo`). ZeD shipped no sound of its own
  before this.
- **Documents**: notes no longer sit on the desktop one icon each. One Documents folder icon, a lilac folder with two
  pages baked like the rest, opens a ZeD window. It lists every note, newest saved first, with its name and the date
  saved. The band holds Rename (a field), Delete (asks, lands on Cancel) and Open (the main one, into CletusWorks,
  which asks "Save changes?" first). Its line counts "N of 24 notes". CletusWorks' Open goes to the same list, and
  closing it returns to CletusWorks. A note renamed there is renamed in CletusWorks too. The desktop's left column is
  now the sticky, CletusWorks, ProtoPOP3 Mail and Documents. `note.png` is still baked and no longer drawn.
- **Caps**: 24 notes. One note holds 20,000 characters; the box takes no more (`setMaxTextLength`), and at the limit
  the band says "Full: a note holds 20000 characters." Files edited on disk cannot get round either cap:
  - the index is read only for ids 1 to 24 and at most 24 notes, however many lines are planted;
  - a note's file is read no further than 20,000 characters (an oversized one reads as cut there);
  - the sticky's file stops at 600 characters and the draft's at 20,000.

New words: 12 keys in all 28 languages, plus two changed values (the app's icon name, Open's help).

**Sims after round two (all pass):** desk_notes_sim 63, desk_sim 120, mail_sim 98, mail_cards_sim 5,032, plus the shared
MP sims and the i18n guard.

**For QA in game, added:** the modem plays through the game's UI volume and only once a connection, and the .wav loads
from the mod's folder (`file = media/sound/...` in a mod's script). The connecting note over the head on a real join. A
reported letter on the staff ticket card: its Reported row shows the letter as "the chat around the line" (the frame's
words for a report), which reads oddly. Mute and Unmute while on, and a muted sender seeing nothing.

**A design question, from round two:** the staff ticket card labels a reported letter's lines with the chat report's
words ("the chat around it"). Should a letter's report get its own label ("the reported letter")? That would change
the ticket cards, which are another part's.
