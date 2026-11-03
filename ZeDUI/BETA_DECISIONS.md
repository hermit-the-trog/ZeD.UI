# ZeD-GUI Beta Decisions (Nov 2 2026)

For the build session: save this as `ZeDUI/BETA_DECISIONS.md` in `C:\Users\you\Zomboid\mods\ZeD-UI`, commit only that file and push. The checkout is shared, so never stash, check out, pull with autostash or touch other files. Then turn these into punch list items and hand QA its checks. All answers are the director's, given Nov 2 2026 in a voice session.

## Answers

**UI scale on small screens.** Keep the 0.75 cap on the Deck and at 720p for the beta. The 0.5 step was dropped because it did not look right at scale; revisit bringing it back after the beta for players who want smaller windows and more room. Director: "I watched those tests and it looked fine at 0.75." Build session: confirm 0.5 is really gone (the oven tab's 0.5 note suggests it may still exist).

**Dimmed rows.** Yes. The game's own greyed-out settings lose their highlight too, so every dimmed row behaves the same.

**Simple cards for machines.** In the beta. Bring the layout rules to the director first. Also find every other place where ZeD shows something in a more immersive or graphic way and propose a simple version for each. Director: "the beta release is gonna have our vision and then a more simplified vision."

**Vehicle tab on small screens.** Undecided. QA captures one small-screen screenshot of the Vehicle tab with the hood open; the director picks the fix from it. Must be decided before beta.

**Testing resolution.** Regular testing runs at one resolution (4K or 1080p). The Deck and 720p runs come out of the beta definition. Small-screen shots only when needed.

**Translations.** Every language the game supports, as AI drafts shipped inside the mod and labeled as machine translations in the language list. Start with Turkish, Simplified Chinese and Brazilian Portuguese; the director named Russian, Ukrainian, Latin American Spanish, Chinese and Japanese as large audiences. Post plainly that these are machine translations and that ZeD is looking for players to check and correct them before final release. One discussion thread collects corrections. Note: Steam comments cap near 8,000 characters, so translations do not go in comments.

**Ente's Auto Sorter.** A note in the Compatibility thread ("drag its bar aside"). Not popular enough to special-case.

**This Is Your Life.** The build session takes a short read of what it adds (hometown postcards, Origin Traits, scripted starts, all switchable in sandbox), then the director decides.

**Context menu icon mods.** Leave it. ZeD stays one look. Director: "people should be making add-ons to support their icons." After the beta, make ZeD easy for add-on makers to extend: icons, accent colors, watches and fonts.

**ZeD's version in About.** Yes.

**Bug reports (director's addition, in the beta).**

- Check whether error capture exists in the ZeD menu; if not, build it.
- In the message center, every error gets a copy button producing text ready to paste into a Workshop comment or a paste site.
- Add a Bug report entry to the ZeD menu (where the style options are). It copies the errors with ZeD's version, then says the errors are copied and can be pasted into a Workshop thread or sent to Hermit. No digging through files or the console.

**Controller map.** Build it. Director: "has to have it."

**Hair and beard error with the eight-mod set.** The beta can ship with it as a known issue if unsolved; keep working on it.

**Known issues (director's addition).** A Known issues section front and center on the beta's Workshop description.

**The beta.** Name 0.3.0-beta1; 1.0 is the release. Same Workshop item, renamed from "ZeD-GUI \[TEST BUILD\]" to "ZeD-GUI \[BETA\]". It stays public.

**Thumbnail (director's addition).** Find out why ours shows a margin and make it fill the whole square. The beta thumbnail swaps the test build's red border and strip for yellow (red test, yellow beta, green release).

**Confirmations.**

- Oct 30 band calls: all four kept (Craft's Show pop-up; "Save loadout" and "Save outfit"; no number beside Craft's amount; an exercise you can't do stays listed with Start greyed and the reason shown).
- Walkie-talkie and ham radio faces: remove the printed foot. The brand is already on the graphic.
- The Nov 1 About paragraph was the director's edit. Keep it.

**Discord note for t16.** Skip it. Director: the Discord "didn't bring any traffic"; effort goes to the Workshop.

## Build and QA working together (director's addition)

The director wants the two sessions talking and working as partners. Every fix goes on the punch list with its own check attached. Nothing counts as done until QA confirms it in the game. QA rewrites the old checklist to match the beta build, the director reviews it before testing starts, and both sessions refresh it after every build.

Two QA passes (director's addition). The director thinks QA checks too many things, and too many of the wrong ones.

- **After each build:** QA checks only what that build changed, plus the five-minute release check. Fast and targeted.
- **Before a release:** when the director is ready to push a release, QA runs the full, thorough checklist top to bottom.

QA rewrites its checks for the beta in this two-pass shape. The checklist the director reviews is the full pre-release one.

## What beta means (agreed)

1. Every decision above is built and confirmed in the game by QA.
2. Everything marked fixed or built on the punch list is confirmed, or reopened and fixed again.
3. The refreshed QA checklist, reviewed by the director, is done.
4. Today's test gaps are closed (game inventory by its key under Safe mode; Simple belt with other slot counts, real drag and controller; load order tools by hand and with 1,500 mods; marks with a container column).
5. The five-minute release check exists and passes, and staging sets the version and writes the page text by itself.
6. No placeholders or "coming later" anywhere.
7. One full run at the test resolution passes with no new faults.
8. The open loose ends from older notes are checked and fixed or closed.
