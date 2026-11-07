# Good morning: QA's night on the next beta (Nov 7 2026)

Build merged three parts overnight, and QA tested each one as it landed:

- the survival guide's ads;
- the fixes from the Mac review and the rest of the fix list;
- the dashes' lamps and odometers, with a fix for the house ad.

Everything Build changed works in game, with one fault, now fixed. Your questions are in Build's punch list 102. They are short and none of them blocks anything.

Nothing was posted or uploaded.

## What was checked, and how it went

**The ads in the survival guide.** Every spread was turned and measured: Small and Large text, keyboard and controller wording, at 4K, at 1080p and in German. Every ad sits inside the page, clear of the foot and the page number, at its proper size. No ad shows twice in a book, and the book reads the same after closing and opening it. At 4K the fine print is crisp (the bat labels, the pawn shop's box).

- One fault turned up: the publisher's own whole-page ad ran its second line out past its frame in German, and in English at Large text.
- Build fixed it in the night, and it now fits in English, German and French at both sizes.

**The fixes.**

- **Kill counts:** each weapon is filed under its own kind. Only real bombs count as explosions. The Journal's total is the game's own count plus fire kills.
- **Gun cards:** they open without an error and name the ammo ("9x19mm Round").
- **Padlock cards:** they fit the narrow card, at 4K and at the Steam Deck's size with Large text.
- **Book cards:** they show the pages read, matching the Reading Facts.
- **The Z menu:** it shows the right version.
- **The Mods screen:** turning ZeD-GUI off and on brings ZeD picks back with it.
- **Two players on a test server:**
  - a second press of Accept says to wait instead of getting the player kicked;
  - a house released and claimed by someone else at once reads as two lines in the log.
- **German, every line Build named:**
  - the dates read "5. Nov";
  - Spawn items reads in whole German sentences;
  - the Bans hint sits where it should;
  - the Player card shows German job and trait names.

**The dashes.** Two cars were driven up the drag strip. Each odometer counted the distance within 1%, and the trip matched. The trip zeroes, the Dash Elite switches between the odometer and the trip, and every figure is kept after quitting and coming back. The Simple dash reads miles, then kilometers. Every one of the 19 dashes lights its lamps when the key goes in and darkens them once the engine runs.

## Not covered yet

- The dash with two or three players: a passenger seeing the figures, and a bystander getting nothing.
- Two claims cases: an invitation arriving while joining, and the grayed role box on an offline player's card.

Build's own test simulations cover these. QA can run them in game when you want them before the upload.

**Run in game later that morning, on your word: all three pass.** The second invitation waits instead of raising the game's pop-up, so the kick can't happen. The passenger gets the driver's figures, and a bystander gets nothing. The offline card names the power it takes, and the server refuses the role change the same way for a real account and for no account. One small look fault: that grayed role box runs under the card's scroll bar with its sentence cut off. Details are in `QA_NEXT_BETA_20261107.md`.

## Two of mine to own

- The first ads run hung, because my script waited while the open book paused the game.
- When that run timed out, the test save got caught half moved. It was restored and checked against last night's D: backup, and your ZeD settings were put back. The test runs now refuse to touch the save while the game is open.

The full results are in `ZeDUI/qa/QA_NEXT_BETA_20261107.md` and `ZeDUI/qa/QA_GUIDE_ADS_20261107.md`.
