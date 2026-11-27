# Journal tab: map for the gamut sweep (QA, Nov 27 2026)

A read-only map of ZeD's Journal tab (the Character window's "journal" tab: the Log, Notebooks, Papers and Recipes pages and an add-on's pages) against the game's own surfaces for the same jobs (B42: the Info page's kill count and time survived, the Literature window, Write note and Read note on a notebook, Read and Inspect on books and print media, the recorded media lists), written before the sweep scripts. It maps the surfaces the tab hands off to (ZeD's reader, the Craft and Build tabs, the death record) only as far as the tab reaches them. Line refs are as read on Nov 27. Nothing was run.

**The tab is on the Character window.** CHAR_TABS declares it as id "journal", ZeD's key UI_ZeD_Char_TabJournal, group 2, glyph J, between Identity and Skills (CW:860). JT.register puts its renderer in the window's dispatch table (JT:1960-1962, CW:54). Its drawer is the full card, 480 (CW:425-433), the half card 220 when held in. Its focus zone is charTabContent (CW:3236-3445, 3467). There is no Lite branch anywhere in JT, JR or WN.

Short names: JT JournalTab.lua, JR ZeD_JournalReaders.lua, WN ZeD_WriteNoteAction.lua (ZeD.Notes and ZeD_WriteNoteAction), CW ZeD_CharacterWindow.lua, KT KillTracker.lua, CC CraftingCore.lua, RI RecipeIndex.lua, PP ZeD_PrintPage.lua, RD ZeD_Reader.lua, TF ZeD_TabFill.lua, MO Molecules.lua, FM Input/FocusManager.lua, DW ZeD_DpadWheels.lua, ST SkillsTab.lua, PD Overrides/PostDeath.lua, OWN Overrides/WriteNote.lua, OPM Overrides/PrintMedia.lua, OML Overrides/MediaLabel.lua, OCI Overrides/CharacterInfo.lua, ZUI shared/Translate/EN/UI.json (ZeD's words).
The game's files (media/lua unless noted): ISCS client/XpSystem/ISUI/ISCharacterScreen.lua, ISLU client/ISUI/ISLiteratureUI.lua, IPCM client/ISUI/ISInventoryPaneContextMenu.lua, IP client/ISUI/ISInventoryPane.lua, WJ client/ISUI/ISUIWriteJournal.lua, WS shared/TimedActions/ISWriteSomething.lua, RAB shared/TimedActions/ISReadABook.lua, LIT media/scripts/generated/items/literature.txt.

## 1. What the tab does

**Getting there:**
- The Character window's tab strip, tab "journal" (J). The first open lands on the Log (CW:4787); the page picked is kept on the window for the session.
- The D-pad Character wheel's Tabs slice lists Journal with the other tabs (DW:1011-1027, H.charTab DW:796).
- An add-on opens a page by id: ZeD.JournalTab.openPage(winOrPn, id) (JT:1619-1628), only while the window is up on the Journal tab.
- A row on the Notebooks page's "Papers on you" block opens the Papers page on that piece (JR:819).
- Nothing in the game routes here: OCI maps the game's Info page to Identity (OCI:38-46), so the game's Info page and its Literature button never show while ZeD runs.
- Safe mode: the Character window does not open (CW:4371, 4497), so there is no Journal; WriteNote, PrintMedia and MediaLabel give the game's windows back (OWN:26, OPM:22, OML:22).

**Data (each page reads its own):**
- Log (gatherData JT:745-793, every 250 ms while the page draws, at once when the cache drops, JT:984-987): the entries in player:getModData().ZeD_Journal.entries (newest first), the kill total (KT.total KT:211-216: getZombieKills plus ZeD's fire kills) and the kill rows (KT.data KT:222-230). It also reads getTimeSurvived (JT:746, 785), which nothing draws.
- An entry (addLogEntry JR:1086-1104): month, day, year, hour (the game clock), minute (from getTimeOfDay), survivalDay (floor(getHoursSurvived / 24) + 1), text, source { name, page } when written into a notebook too, tags (keys, in TAGS order). An old entry with no survivalDay derives one from the start date on 30-day months (JT:1236-1242).
- Kill rows (KT): weapon kills by the script's weapon category (KT:83-117: Axe, Blunt, Spear, LongBlade, SmallBlade, SmallBlunt, Unarmed, Firearm by sub-category, else Other), explosion (a real bomb, KT:122-128), vehicle (the zombie on the ground and a local driver, KT:367-383), fire (the second death within 20 s, KT:312-326). An old table is rebuilt once into Other (KT:179-188).
- Notebooks and Papers (gather JR:198-226, every 30 asks, about half a second; scan JR:162-175, every bag, recursive): papers are items with modData.printMedia, one row per piece id (two copies show once, JR:167-168); books are Literature items with canBeWrite (Notebook, Journal, Diary1 and 2, SheetPaper2, Notepad, GraphPaper, IndexCard, MenuCard, the greeting cards, IDcard_Blank: LIT:1779-1833, 2646-2700, 3071, 4016, 4161, 4680-4834); reads are the other Literature items (books, magazines, comics, skill books), read or not by the game's own inventory test (IP:2606-2620 through JR:179-183) with their page count.
- Recipes (gatherRecipeData JT:801-890, every 500 ms): a catalog of every craft recipe and every buildable recipe, built once per Lua session with the first character's BuildLogic (JT:620-739); each row is "unlocked" when known (isRecipeKnown(recipe, true), JT:847-851) and every required skill met (characterHasRequiredSkills, JT:840-843), else "locked"; only the rows the game would list (RI.visible: needToBeLearn hidden unless known or SeeNotLearntRecipe, the recipe's OnAddToMenu, RI:136-157). The ingredients scan runs every 5 s (JT:1509-1511).

**The view (render JT:1918-1954):**
- The header (drawHeader JT:1712-1743): row 1 is the open page's search box (Log: "Search entries...", Notebooks: "Find in your notes...", Papers: "Find a paper...", greyed in a paper's quick look; Recipes: CraftingCore's own; an add-on's own); row 2 is the page strip: Log, Notebooks, Papers, the game's "Recipes", then an add-on's pages while their visible() says so (JT:118-123, 1550-1563). Opening a page clears every search (JT:1602-1614).
- **Log** (renderJournal JT:958-1339), one scroll over all of it:
  - "Zombies Killed (n)" (the game's IGUI_char_Zombies_Killed), a fold head; open: Fire, Vehicle, Explosion with status squares, then the nine weapon rows by the game's skill names, zeros shown (JT:1105-1136).
  - The write box (ZeD_TextEntry, 3 lines and 500 letters, MO:918-919, CW:5016), 48 units tall, as wide as the room an open item card leaves (JT:1143-1159).
  - The eight tag picks under it, wrapping at the width: Danger, Loot, News, Food, Weather, Base, Travel, Injury, each the folder label color; a hollow quiet square off, the tag's own square and color on (JT:204-214, 378-409).
  - Into (only with a writable book carried): "Into: the log only", or "Into: <book>" as a primary button; a press steps to the next book, then back to the log only; beside it "Writing..." or why the last Save did not write (JR:1021-1061).
  - The entries in month groups ("July 1993 (3)", the game's month names, JT:510-553), newest month first, each a fold head. An entry: "Day 7  Jul 23  10:05" (the tickets' phrases, JT:1229-1254), then ", <book>, page n" after a bar when it went into a book, then its tags (words and squares; past three, or with no room, the squares alone, JT:417-490) and a delete cross; then the words wrapped; alternate entries striped. "No entries yet" with none (JT:1201-1202).
  - The band at the foot: Save (the game's "Save", CW:5024), or while asking "Delete the entry? It can't be brought back." with Cancel and Delete (JT:1305-1338, ZUI:3739).
- **Notebooks** (renderNotebooks JR:860-982), one scroll:
  - None carried: "No notebook on you", then the Writing block (pencil or pen at hand, or not; light enough, or too dark), "Papers on you" (read or not, a row opens it on Papers) and "Books on you" (read or not, the page count), folding blocks (JR:807-856). With a notebook carried, no books or papers are listed on this page.
  - Each book: its name, then its kind and "blank, n pages", "n of N pages" or "Locked" (JR:752-758); the picked one washed. The side-by-side layout needs 560 units (JR:886), more than the drawer ever has, so the list always sits above the page.
  - The page bar: "<", "Page n of N", ">", Open full (JR:920-937). The page opens at the last written page (JR:723-729).
  - The page small, ruled, its words in ink, filling the drawer's height (JR:765-801).
  - The quick note (2 lines, 160 letters, JR:685-697) with "Add a line to page n...", Write, and the line under it: "Writing...", why not or the lines left on the page (JR:943-977).
- **Papers** (renderPapers JR:651-667):
  - The list: "n read of N carried", with "n with places" when any (JR:353-363); rows read first, then by title (JR:220-223): the thumbnail (the flyer's picture or the page's art), the title, the kind (Newspaper, Brochure, Flyer, Magazine, Paper; PP:71-89), its date, its places once read; Read or Unread at the right, unread dim by tone (JR:314-319, 376-405). "Nothing to read on you" or "None of these on you" when empty.
  - The band: Show (All, News, Flyers, On map) as a pop-up list opening upward (JR:596-647); greyed in a quick look.
  - The quick look (JR:479-557): Back, the title, Open full (read pieces only); the page small; unread: Read (the game's ContextMenu_Read, greyed with "Too dark to read" in the dark) and nothing more; read: "Places" with Show on map (one place) or Show place n (each), then "The words" or "On this page: n stories" and the stories in the tab's fonts.
- **Recipes** (renderRecipes JT:1500-1525): CraftingCore's list in read-only mode: Category, Sort (Craftable, Known, Name), Show (Known, All; All by default, JT:1495), search; a picked recipe's card with no craft or pin, a "How to learn" block (skills met or not, the magazine that teaches it when Hidden facts allow, CC:3951-3990) and the band's key "Open in Craft" or "Open in Build" (JT:1472-1490).
- **An add-on's page** (JT:126-175, 1949-1952): its own render, clicks, stops, scroll and search; Loadouts is one.

**Verbs, each through what it calls:**
- Save, log only: ZeD.JournalTab.save (JT:330-339): the entry at the top of the log with the ticked tags; the box and the ticks clear. Empty text does nothing.
- Save, Into a book: JR.saveLog (JR:1109-1127): the text flattened to one line, a refusal shown beside Into (N.why: locked by another, locked by you, no pencil or pen, too dark, WN:48-54; or "No room in <book>"), else ZeD.Notes.write: the book out of its bag (transferIfNeeded), ZeD_WriteNoteAction (40 ticks plus one per letter, at most 200, WN:157-160), the line appended to the last written page or the next blank one (WN:88-95, 141-152), then the log entry with its source and tags, the box and ticks cleared (JR:1121-1125).
- Tick a tag: togglePick (JT:282-286). A tag on an entry: its word goes in the search (JT:322-325).
- Search: the words or a tag's word, lower case, anywhere in the text (JT:264-273, 586-608).
- Fold the kills, fold a month: CW:5935-5967 (mouse), CW:3255-3321 (pad).
- Delete an entry: the cross asks first (askDelete JT:1357-1366); Delete removes that entry table (JT:1369-1384), Cancel keeps it (JT:1387-1392). There is no edit.
- Notebooks: pick a book (JR:909-911); page < and > (JR:924, 928); Write (J.writeNote JR:731-750: the same action, onto the page shown; "No room left on this page" when the line won't fit); Open full: the game's onWriteSomething (IPCM:2672-2679), editable with a pencil or pen and not locked by another, greyed for a blank book with no pencil and in the dark (JR:929-936); the game's ISWriteSomething then opens ZeD's reader instead of ISUIWriteJournal (OWN:25-37).
- Papers: open a row (JR:337-341); Back; Read (readPiece JR:413-424: the game's readItem, so its transfer, ISReadABook and the item put back; the game's displayPrintMedia then opens ZeD's reader, OPM:21-35); Open full (RD.openPrint, no timed action, JR:495-497); Show on map (PP:583-595: the squares made known, the queue cleared, ISReadWorldMap queued); Show (the filter).
- Recipes: pick, sort, filter, search; Open in Craft or Build (RI.open RI:229-236: the game's OpenHandcraftWindow or OpenBuildWindow, routed to ZeD's World window).

**Settings:** none of ZeD's own. The game's: SeeNotLearntRecipe (RI:105-108), the auto reveal of print media places (OPM:31-33), the clock's date visibility (the game hides Survived For without it, ISCS:237; the Log shows dates regardless). UI scale, text size, theme, language (the month names are the game's, the tags ZeD's; an entry keeps tag keys, not words, JT:193-203).

**Lite:** no branch.

**Pad (zone charTabContent):**
- Header: jtab:<page> for each tab (A opens it), then journal:__find (A opens the pad keyboard; not on Recipes, whose search is CraftingCore's stop) (JT:1878-1892).
- Log (CW:3379-3403): journal:__kills (A folds), journal:__write (A opens the pad keyboard), journal:tagpick:<k> x8 (A ticks; the help band names the tag), jr:into (A steps), journal:group:<key> (A folds), journal:tag:<idx>:<k> (A searches), journal:del:<idx> (A asks), journal:__save. Tags and crosses are stops only within a view's height of the view (inPadReach JT:1769-1773). X on any stop clears the search (JT:1813-1823). The question holds the pad alone: journal:ask:cancel (focus lands on it) and journal:ask:verb; B cancels (JT:1435-1452). After Delete the focus lands on the next entry's cross, else the one before; after Cancel on the same cross (JT:1397-1420).
- Notebooks: jr:book:<id>, jr:prev, jr:next, jr:full, jr:note (A opens the pad keyboard; only while the field shows whole), jr:write; with none carried the fill blocks' fill:notebooks:* stops (JR:1165-1201).
- Papers: jr:paper:<id>, jr:show (A opens the list; its rows jr:showRow:<id> hold the pad alone, focus on the current one, JR:1191-1199); in a quick look jr:back, jr:read, jr:full, jr:place:<i> and jr:words (the D-pad scrolls the words, JR:548-554). B in a quick look goes back.
- Recipes: CraftingCore's jrecipe stops (CW:3409-3412).
- B on a stop with no onCancel stops the running action (FM:1696-1703): on the Log and the lists that includes an Into write in progress.
- Scroll-follow: the Log pins once per focus change (JT:1036-1089); Notebooks and Papers through framed (JR:251-271).

**Small screens:** the half card (220) narrows every page: the tag picks wrap to more rows, entry dates are cut with "..." (JT:1264), Into's label is cut (JR:1037), the Notebooks page bar ("<", "Page 10 of 10", ">", Open full) has no fallback when it runs out of width (JR:923-936). An item card over the tab hides the write box and search boxes it would cover; Save moves into the part left showing (JT:1149-1151, 1327-1330, CW:5551-5557).

**Related surfaces (reached from the tab):**
- ZeD's reader (RD): a notebook through Open full; a paper through Read or Open full.
- The Craft and Build tabs: Open in Craft or Build.
- The death record: the kills line from gatherData and the newest entry's words (PD:121-161).
- The Skills tab: the skill books, read, reading, collected or missing (ST:455-500): the Journal has no skill book list of its own.

## 2. Against the game

The game has no free-text diary; its jobs here are spread over the Info page (ISCS), the Literature window (ISLU, opened by the Info page's Literature button, ISCS:319-323, 452-470), the item menu's Write note and Read note (IPCM:566-580, WS, WJ) and the item menu's Read, Inspect and Read label (IPCM:536-554, 1007-1027, 1029-1110, 2777-2806, RAB).

| Job | Game | ZeD Journal tab |
| --- | --- | --- |
| See the kill count | Info page: Zombies Killed, getZombieKills, fire kills left out (ISCS:227-228) | Log head "Zombies Killed (n)" with fire kills in (KT:211-216); Identity shows the same total |
| Kills by kind | None | Fold the head open (1): fire, vehicle, explosion, nine weapon rows |
| Time survived | Info page: Survived For, only with the clock's date shown (ISCS:236-241) | Not on the Journal (read, not drawn, JT:746); on Identity |
| Favourite weapon | Info page (ISCS:221-225) | Not on the Journal; on Identity |
| Keep a diary | A notebook: right-click (1), Write note (1), type, OK (1) | Log: type, Save (1); tags, search, month groups, kept on the character |
| Diary into a notebook too | The same Write note | Into (1 per book), Save (1): a timed write, then the log entry |
| Add a line to a notebook | Right-click (1), Write note (1), find the page (n), type, OK (1) | Notebooks: the book (1), type, Write (1); the page that has room |
| Read a notebook | Right-click (1), Read note (1), pages | Notebooks: the book (1), the page small, < and > |
| Lock or erase a page | The journal window's lock and erase | Only through Open full (ZeD's reader); the quick note refuses a locked book |
| Read a newspaper or flyer | Right-click (1), Inspect (1); its window after | Papers: the row (1), Read (1); the words then stay in the tab |
| Look at a paper read before | Inspect again (a timed read) | The row (1): the words at once; Open full (1) with no timed action |
| A paper's places on the map | The print window's map button | Show on map, or Show place n (1) |
| Which papers are read | The inventory's tick per item | Papers: Read or Unread per row, the count, On map |
| Skill books read | Literature window, Skill books tab (ISLU:301-305, 77-100) | Not on the Journal; the Skills tab; Books on you only when no notebook is carried |
| Recipe magazines read | Literature window, Recipe magazines (ISLU:308-312) | No list; their recipes show as known on Recipes |
| Recipes known | Literature window, Recipes: magazine recipes only, MetaKnowledge "???" (ISLU:315-320, 120-145) | Recipes: every craft and build recipe the game would list; Known or All; Open in Craft or Build |
| Recorded media heard | Literature window, one tab per media category (ISLU:324-334, 188-227) | None; a VHS or CD carried is not listed anywhere in the tab |
| A tape's or CD's label | Item menu Read label (IPCM:543-554) | Not in the tab (OML opens ZeD's reader from the item menu) |
| Seeds known by season | Literature window, Growing (ISLU:338-345) | None |
| A book's pages read | The item's progress (getAlreadyReadPages) | Unread and the page count only (JR:179-183, 822-826) |

ZeD has, the game doesn't: a diary with tags, search and month groups; kills by kind with fire kills counted; the carried papers in one list with their read state, places and words; quick notes onto a page that has room; every recipe in one read-only list with how to learn it.

The game has, ZeD doesn't: the whole Literature window (skill books, recipe magazines, recorded media, growing), which no ZeD surface opens and which only shows in safe mode; MetaKnowledge's hidden "???" rows; the illiterate and asleep rules on reading print media (IPCM:1022-1026, 2783-2785); the word "Inspect" for print media (IPCM:1017, ZeD says Read); a diary that outlives the character (a notebook is an item; the Log lives in the character's modData and only its newest entry reaches the death record, PD:160-161).

## 3. Cases (J1 to J52)

Truth is the game's own call unless the case says otherwise. Staging assumes the deep-run character (QA save in Saves/Sandbox/ZeD-QA), debug give for items, modData writes for old data.

**Ways in and pages**
- **J1. Open the tab.** Stage: window shut. Do: the strip's J; then the D-pad Character wheel, Tabs, Journal. Read: win._activeTab == "journal", win._journalSubTab == 1 on the first open, the strip's four tabs (five with ZeD-GUI: Loadouts on). Truth: CW.TABS.
- **J2. Page change clears searches.** Stage: three entries. Do: type a word in the Log search, open Notebooks, back to Log. Read: _journalSearchText == "" and the box empty; the same for _flyerSearchText across Notebooks and Papers (JT:1602-1614). Also: a paper's quick look open, Log, then Papers: the quick look is still open (s.paperOpen kept).
- **J3. Safe mode.** Stage: safe mode on. Do: the inventory key, the Info key, Write note on a notebook, Inspect a flyer. Read: no Character window; the game's Info page with its Literature button; ISUIWriteJournal; the game's print window. Truth: ZeD.Safe.on().
- **J4. An add-on's page.** Stage: ZeD-GUI: Loadouts on, then off in setup while its page is open. Read: the strip goes to four tabs and the page falls back to the Log (JT:1923-1926); openPage("loadouts") false while off.

**Log**
- **J5. Empty log.** Stage: md.ZeD_Journal = nil. Read: "No entries yet"; one stop set: kills, write, picks, Save.
- **J6. Save an entry.** Stage: a known game date. Do: type "Supply run", Save. Read: entries[1].text, month == getGameTime():getMonth(), day == getDay(), year, hour, minute, survivalDay == floor(getHoursSurvived() / 24) + 1; the stamp "Day n  Mon d  hh:mm"; the box and picks clear; the group label is the game's month name and the year.
- **J7. Tags.** Do: tick Injury then Danger, Save. Read: entries[1].tags == { "danger", "injury" } (TAGS order, not tick order); the head shows both words; with four tags the squares alone; with two tags and a narrow card the squares alone. Then a tag key unknown to this version written into modData: not drawn, no error.
- **J8. Text edges.** Do: Save with "" (nothing), with only spaces, with two newlines inside, with 500 letters (the box's limit), at 3 lines. Read: entries count and text; the wrap; the stripe on a 4-line entry (B7); the spaces-only case (B6).
- **J9. Month groups.** Stage: entries written into modData across three months and two years, out of order. Read: groups newest year, then newest month first; entries inside a group in array order; fold one (click, then pad A): its count stays, the scroll shortens; folds are per window session (reopen the game: unfolded).
- **J10. An old entry.** Stage: an entry with no survivalDay, dated across a 31-day month from the start date. Read: the derived "Day n" against the real day count (JT:1236-1242, B10).
- **J11. Search.** Stage: entries "found food", "base wall" and one tagged Food with other words. Do: type "food"; press the Food tag on an entry; X on a stop. Read: "food" keeps all three (the words or the tag's word, JT:264-273); the tag press puts the tag's word in the box and scrolls to the top; X clears. In DE: the tag's German word searches, the English one does not.
- **J12. Delete.** Stage: three entries, search narrowed to the third. Do: its cross; Cancel; its cross; Delete. Read: Cancel keeps all; Delete removes exactly that entry table (compare texts), the others keep their order; the pad lands on Cancel first and after Delete on the next cross. Also: with the question up, press another entry's cross and a month head with the mouse (B8); leave for the Skills tab and come back (B12).
- **J13. Kills by kind.** Stage: fresh character; kill two with an axe, one with a spear, one with a bat, one with a pistol, one with bare hands, two with a pipe bomb, one by burning (a Molotov or a campfire), one by car. Read: the head's count == getZombieKills() + md.ZeD_Kills.fire; each row against the staged count; the rows add up to the head. Compare the head with Identity's total and, in safe mode, the game's Info count (lower by the fire kills).
- **J14. An old kill table.** Stage: md.ZeD_Kills with no v and inflated weapon rows, a few game kills. Read: after load the rows add up to the total, the old weapon rows moved into Other, fire kept (KT:171-188).
- **J15. No time survived on the Log.** Read: nothing on the Log says how long he has survived; Identity's Survived matches getTimeSurvived(). Gap, not a fault.

**Into (Save into a book)**
- **J16. Into cycle.** Stage: no writable book, then a Notebook, then also a Diary. Read: no Into without one; then "Into: the log only", a press to the Notebook, the Diary, back to the log only (JR:1038-1050). Drop the picked book: Into falls back to the log only.
- **J17. Into writes.** Stage: a Notebook with page 1 half full and a pencil. Do: Into the Notebook, type, Save. Read: "Writing..." for 40 + letters ticks; then page 1 ends with the text (item:seePage(1)), entries[1].source == { name = the book's name, page = 1 }, the stamp ends ", Notebook, page 1"; tags in the log only. Full page 1: the text goes to page 2.
- **J18. Into refusals.** Stage each: no pencil, too dark (night, no light), a book you locked in the reader, a full book (10 pages of 15 lines). Read: the line beside Into (ZUI:2103 and the others), no entry, the box keeps the text, nothing queued.
- **J19. Into interrupted.** Do: Save, then walk or press B on a Log stop during "Writing...". Read: no entry, the page unchanged, the box keeps the text, "Writing..." clears.
- **J20. Save twice while writing.** Do: Save, then Save again before the write ends (mouse and pad A). Read: entries count and the page's lines (B1).
- **J21. Odd books.** Stage: a stack of five SheetPaper2, an IndexCard, a Card_Birthday, an IDcard_Blank, a Notepad. Read: each listed by Into and on Notebooks (five sheet rows); a one-page sheet full after 15 lines; the ID card's getLockedBy() after one line (B3). With Skill Recovery Journal on: whether its Bound Journal is listed (check its CanBeWrite).
- **J22. Newlines into a book.** Do: Into a book, Save a two-line text. Read: the page and the log entry both hold one line (JR:1114); log only keeps the newline.

**Notebooks**
- **J23. None carried.** Stage: no writable book; a pencil or not; lit or dark; two flyers (one read), a skill book read halfway, a magazine read, a recipe magazine whose recipes are known, a comic unread. Read: the Writing block's two rows against hasWritingTool and tooDarkToRead; Papers on you count; Books on you rows "Read" or "Unread" with "Number of Pages" against ISInventoryPane:isLiteratureRead (the half-read skill book reads Unread); a paper row opens Papers on it.
- **J24. The list.** Stage: Notebook (blank), Journal (3 pages written), Diary renamed "Supply runs", a book locked by you. Read: names; kind lines ("Notebook, blank, 10 pages", "Journal, 3 of N pages", "Locked"); a click picks; the page opens at the last written; < greyed at 1, > at the last page.
- **J25. Quick note.** Do: type a line, Write. Read: "Writing...", then seePage(n) ends with the line; the lines-left count drops; a full page: "No room left on this page", nothing queued; 160 letters at most; Enter in the field (B2); pad A on jr:note opens the keyboard.
- **J26. Quick note refusals.** Stage each: no pencil (the field hides, Write greyed, the reason on the line), dark, locked by you, locked by another (MP, J49).
- **J27. Open full.** Stage: a written notebook with and without a pencil; a blank one without; dark. Read: ISWriteSomething queued and ZeD's reader in notebook mode, editable or read-only as the game's menu would say (IPCM:566-576); greyed on the blank one with no pencil and in the dark.
- **J28. Notebooks search.** Do: a word only on page 4 of one book. Read: that book alone listed; "None of your notebooks has that" for a word in none.
- **J29. A book in a bag.** Stage: the notebook in a backpack. Do: Write. Read: the book is moved to the main inventory and stays there (the game's Write note leaves it too).

**Papers**
- **J30. The list.** Stage: two copies of one flyer, a second flyer read, a newspaper, a brochure, one paper in a backpack. Read: one row for the two copies; read rows first, then by title; "n read of N carried"; each row's state against player:isPrintMediaRead(id); the places count on read rows against PrintMediaDefinitions.MiscDetails.
- **J31. Show and search.** Do: News, Flyers, On map, All; a title word; a press outside the open list. Read: the rows each keeps (Flyers holds brochures); On map only read pieces with places; the list shuts by the Popups rules.
- **J32. Read an unread piece.** Do: open it, Read. Read: ISReadABook queued (the item out of the bag and back); after it, ZeD's reader opens; the row reads Read; the quick look shows places and words; with the game's auto reveal on, the squares known. In the dark: Read greyed, "Too dark to read". As a driver at speed: the game's isValid refuses. With the Illiterate trait: B4.
- **J33. A read piece.** Do: Open full; Show place 2; D-pad on the words; B. Read: the reader opens with no timed action; Show place queues ISReadWorldMap and clears the queue; the words scroll; B goes back to the list.
- **J34. Changes under it.** Do: read a carried flyer from the item menu with the tab open; drop the open piece. Read: the row turns Read within about half a second; the quick look goes back to the list.

**Recipes**
- **J35. The list.** Read: rows against the game's craft and build lists for the character; Known and All; Sort Craftable, Known, Name; a category; a search; a locked recipe's "How to learn" block (skills and the teaching magazine); Open in Craft and Open in Build land on that recipe. Truth: isRecipeKnown(recipe, true), characterHasRequiredSkills, RI.visible.
- **J36. Learning while open.** Do: read a recipe magazine with the page open. Read: its recipes turn unlocked within 500 ms.
- **J37. Sandbox.** Stage: SeeNotLearntRecipe off, then on; MetaKnowledge 1, 2 and 3. Read: unknown recipes hidden or shown per SeeNotLearntRecipe; MetaKnowledge changes nothing in ZeD (compare with the game's Literature window in safe mode).

**What the tab does not hold**
- **J38. Recorded media.** Stage: a home VHS, a retail VHS and a CD carried; watch and listen to one each. Read: none listed on any page; in safe mode the Literature window's media tabs mark them heard (hasListenedToAll). Gap.
- **J39. Skill books and magazines.** Stage: a notebook carried and three skill books. Read: no book listed anywhere in the Journal; the Skills tab lists them with read, reading, collected. Gap.

**Pad**
- **J40. Log tour.** Do: LB or RB into the drawer, then down through every stop. Read: the order jtab:1..n, journal:__find, journal:__kills, journal:__write, eight tagpicks, jr:into, groups, each entry's tags and cross, journal:__save; A on each does the click's job; X clears the search only while there is one.
- **J41. Long log.** Stage: 80 entries over six months, tagged. Do: walk down to the last cross and back up. Read: the view follows; tags and crosses beyond a view's height are not stops until scrolled near; frame time with the log open.
- **J42. Notebooks and Papers tour.** Do: every jr: stop on both pages, the Show list (modal, ends stop), a quick look (B back), the words zone. Read: focus never lands on a hidden field (jr:note only when whole).
- **J43. B.** Do: B on a Log stop with nothing running; during an Into write; during a Read. Read: nothing; the write stops (J19); the read stops.

**Layout, words, themes**
- **J44. Item card over the tab.** Do: open an item card with the Log up. Read: the write box hides where covered, Save sits in the part left showing and still saves.
- **J45. Small screens.** 1280x720 and 1280x800 at UI scale 1 and 2 with Large text, the half card: the picks' rows, a long date cut, the Notebooks page bar (Page 10 of 10 with Open full), Into's cut label, the paper rows, the Recipes card.
- **J46. Languages.** EN, DE, ES, FR, RU, JP: the month names, the stamp's day and month order, the tag words in the picks and in the search, the kills rows' skill names, the Notebooks status line.
- **J47. Themes.** Dark, Light, High contrast: unread paper rows (4.6:1 by tone), the tag colors, the page's paper tone.

**Death and add-ons**
- **J48. Death record.** Stage: three entries, kills of several kinds. Do: die. Read: the record's kills line by kind and the newest entry's words (PD:121-161); the Log is gone with the character.

**Cannot be staged in single player**
- **J49. MP: a notebook locked by another player.** Read: "Locked by its writer", Write greyed; an admin can write (WN:38-41).
- **J50. MP: Into and the quick note on a server.** Read: whether the line reaches the page and the entry is logged (B5).
- **J51. MP: the log and kills after a reconnect.** Read: entries and ZeD_Kills kept in the character's modData; another player's kill on a zombie you hit is not yours (KT:346-347).
- **J52. Split view, two pads.** Read: each player's own Log and kill rows (KT:63-72, 291).

**Tests that touch it now:** rt_media sections 4 to 7 (rt_media.lua:1154-1377: Papers lists a flyer and opens it, Notebooks lists and picks a notebook, the quick note's line on the page, Open full in the reader, a tagged Save, the Recipes fold); journal_tags_sim, kills_sim, ask_cancel_first_sim, tab_fill_sim, subpage_tabs_sim, pad_type_sim, g2_read_marks_sim, card_cover_sim (source and stub checks); gallery_journal_kills (pictures); ad_split (the add-on page by id). Not covered: Into's refusals and double Save, delete with a search, month groups, old entries, every kill kind against the game's count, Papers' Read and Show, the half card, languages, MP.

## 4. Suspected bugs (to prove in the game)

- **B1 (suspected):** Save pressed again while an Into write runs writes and logs the entry twice. JR.saveLog has no guard on s.logPending (JR:1109-1127), Save stays live (CW:5024-5026, 3276-3296) and the box clears only in the first write's onDone (JR:1121-1125), so the same text is queued again; both performs append (WN:141-152) and both log. The Notebooks Write is guarded (JR:963-965); Into is not.
- **B2 (suspected):** Enter in the Notebooks quick note does nothing. JR:694 sets e.onSubmit, but ZeD_TextEntry only declares the field (MO:917) and never calls it: its inner box has no onCommandEntered (MO:922-938), unlike ZeD_SearchField (MO:838-841).
- **B3 (suspected):** A line written through the Journal does not lock a write-once item. The game locks IDcard_Blank (tag lockonwrite, LIT:4823-4834) when its page is written (WJ:197-199, 213-215), and ZeD's reader does the same (RD:875, 891); ZeD_WriteNoteAction:perform writes and never locks (WN:141-152). A blank ID card written by the quick note or Into stays writable.
- **B4 (suspected):** An illiterate character can read newspapers and flyers from the Papers page. readPiece calls the game's readItem directly (JR:419-420), skipping onLiteratureItems' Illiterate filter (IPCM:2783-2785); ISReadABook's isValid has no such check (RAB:5-19); the Read button greys only for the dark (JR:517-519). The button also says Read where the game says Inspect for print media (IPCM:1017), and the asleep rule (IPCM:1022-1026) is not shown.
- **B5 (suspected, MP only):** On a server the quick note and Into likely do nothing. ZeD_WriteNoteAction lives in a client file and has a complete() (WN:155), so the server is asked to build it by type and can't, the case CookingTab.lua:668-672 records for ZeD_CookAdd. Its page write and Into's log entry sit in perform (WN:141-152, JR:1121-1125).
- **B6 (suspected):** Whitespace saves. save checks only text == "" (JT:331): spaces or newlines alone make an entry of blanks. Into strips them to "" (JR:1114), N.pageFor accepts "" (WN:88-95) and the write appends a blank line to the page (WN:68-71) and logs an empty entry.
- **B7 (suspected):** The alternate entry's stripe covers its head and one line only: its height is bodyH + headH + xs (JT:1223), while an entry is headH + rowGap + n lines of bodyH + 2, + xs (JT:1281-1288). A long striped entry reads as two.
- **B8 (suspected):** With the delete question up, the mouse still works on the log. The month head and cross handlers (CW:5935-5959) do not check _journalAsk (onBodyClick does, JT:1755): another cross swaps the question to that entry with no sign of which entry it now means, and a month head folds under the question. The pad is modal (CW:3421).
- **B9 (suspected, low):** The kills head's mouse hit tests y only (CW:5962-5967): a press anywhere across the drawer at that height folds it, including the part an item card covers.
- **B10 (suspected, low):** An old entry's day count uses 360-day years of 30-day months (JT:1239-1241), so entries from before survivalDay was stored can read a day or more off across 31-day months.
- **B11 (suspected, low):** The recipe catalog is built once per Lua session (JT:621) with the first character's BuildLogic (JT:702-711): recipes a mod adds later, or build recipes that depend on the character, are not picked up until a Lua reload.
- **B12 (suspected, low):** The delete question outlives the tab. It is cleared only when another Journal page opens (JT:1928); leaving for another Character tab and coming back shows the old question, and Delete still removes that entry.
- **B13 (drift, not behavior):** The Notebooks side-by-side layout can never show (JR:886 needs 560 units; the drawer is at most 480, CW:425-433). The scroll key reads win._journalPageOpen, which nothing sets (CW:6846); CW:3238-3245, 3414-3416, 4788 and 5922-5923 still describe a Page pop-up ("jpage") that is now the tab strip. Six EN keys are read by no Lua file: UI_ZeD_Journal_EntryStamp (ZUI:1459), UI_ZeD_Journal_PagePick (ZUI:1477), UI_ZeD_Papers_StateUnread (ZUI:2258), UI_ZeD_Journal_HelpPage (ZUI:3746), UI_ZeD_Journal_HelpSubTab (ZUI:3747), UI_ZeD_Papers_HelpFilter (ZUI:3770); the page tabs' help is the reader's "Turn to this page." (JT:1557, ZUI:4091).

**FEATURE_MAP.md (ZeDUI/tools/qa/FEATURE_MAP.md) rows with stale line refs:**
- Row 692: drawer.onMouseDown is CW:5789 (not 5443); onHeaderClick JT:1839 (not 1714); onBodyClick JT:1754 (not 1629); JournalReaders.onClick JR:1133 (not 1137); _buildJournalFocusables CW:3417 (not 3124).
- Row 696: setPage JT:1602 (not 1521); onHeaderClick JT:1839.
- Row 697: save JT:330 (not 267); addLogEntry JR:1086 (not 1090).
- Row 698: togglePick JT:282, pickedTags JT:289, clearPicks JT:303 (not 219, 226, 240).
- Row 699: askDelete JT:1357, confirmDelete JT:1369, cancelDelete JT:1387, onAskClick JT:1424 (not 1290, 1302, 1320, 1357).
- Row 700: setSearch JT:308, searchTag JT:322 (not 245, 259).
- Row 701: saveLog JR:1109 (not 1113).
- Row 702: writeNote JR:731 (not 735).
- Row 703: openPaper JR:337 (not 336); Open full at JR:495-497 is right.
- Row 704: gatherRecipeData JT:801, onRecipeClick JT:1528, onRecipeMouseWheel JT:1534 (not 736, 1450, 1456).
- Row 717 (the reader): openNotebook RD:1245 (not 1262), onJoypadNotebook RD:746 (not 765), turnPage RD:851, goPage RD:860, toggleLock RD:869, erasePage RD:880, done RD:888, endWriting RD:906 (all about 19 lines off).
- Rows 539 and 540 are right (OWN:25; WN:176, 48, 28, 141).
