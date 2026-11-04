# Survival guide (F1): design draft (Nov 3 2026)

The director, Nov 3 2026: "The ingame survival guide is next. Let's start on it. F1 guide..." Today ZeD passes the
game's guide through untouched (HOOK_MAP row 18). Nothing is built yet.

## The director's answers (Nov 3 2026)

1. **Both looks:** the ZNIX manual book (Full) and the plain ZeD window (Simple).
2. **More than the game's guide:** "Yes, in addition to the vanilla guide and whatever else we can add. Make F1
   useful for noobs and vets alike." A ZeD section, plus more (see "What else" below).
3. **New clips:** "Can we make new clips with our UI instead of Vanilla?" Yes (below).
4. **First run:** "Keep it the vanilla mechanic": it opens by itself on a new game, with the Show guide tick box.
   This is the one exception to the no-pop-ups rule.

## New clips: how

The game plays clips a mod brings (VideoTexture.getOrCreate looks through the mods' media folders), in the game's
own video format (Bink). Two ways to make them:
- **RAD Video Tools** (the maker's free Bink encoder): real video, smooth, light on memory. A new program on this PC:
  needs the director's OK (the no-installs rule). QA records with Windows' own recorder (Xbox Game Bar), the encoder
  turns it into a clip.
- **Flipbooks** (QA's screenshots played as frames, no new program): choppier, and heavy on memory past a few
  seconds. Only for a short loop.
Build's pick: RAD Video Tools. Remake only the clips that show the game's menus; the ones that show moves (walking,
vaulting, aiming) stay as they are.

**Installed Nov 3 2026 (the director: "Yes, install it"):** C:\RADVideoTools (radvideo64.exe, binkplay.exe), unpacked
from the maker's RADTools.7z (sha1 93d2ec21, signed by Epic Games), no installer run. The game's guide clips are
Bink 1 ("BIKi"), 960 x 480, 15 frames a second. Encode from PowerShell (from Git Bash it hangs):
`Start-Process C:\RADVideoToolsadvideo64.exe -ArgumentList 'Bink','"<dir>???.png*0-95"','"<out>.bik"','/Bink1','/F15','/O','/#'`.
A 24-frame test gave the same header as sg_aiming.bik. Not yet played in the game (QA's job).

## What the game's guide is

- A window on F1 (and on the controller's Help wheel). A list on the left, a video clip and its text on the right,
  a "Show guide" tick box at the foot.
- **15 sections, about 80 topics:** Movement, Loot, Interactables, Combat, Food & Water, Character, Crafting and
  Building, Vehicles, Weather, Foraging & Mining, Farming, Ranching, Fishing, Cleaning, Multiplayer.
- **82 short video clips** (media/videos/survival_guide), one per topic, shown by the game's own player.
- Each section opens on a Spiffo picture; each topic's text names your keys (or your controller's buttons).
- It opens by itself at the start of a new game until the tick box is cleared.
- The topics come from the game (SurvivalGuideEntry), so new ones arrive with game updates.

## Proposal

A ZeD window on F1, laid out like the Crafting, Vehicle and Cooking tabs: topics on the left by section (folding as
the Vehicle tab's sections do), the clip and its text on the right, the band at the foot.

- **The game's content, the game's words:** every section, topic, clip and line of text is the game's own, read
  from the game, so updates and translations come for free. Keys and buttons are drawn as ZeD's key caps and button
  pictures instead of the game's words in brackets.
- **No Spiffo pictures:** a section's first page is its topics as a list (or the first topic), in ZeD's look.
- **Never opens by itself** (no first-run pop-ups): F1 and the Help wheel only. The tick box goes.
- **Search** in the band: type a word, the list keeps the topics that have it.
- **Controller:** the same paths as the other split tabs (list, then clip, B back).

## What else (for new players and old hands)

Candidates; the research thread (director, Nov 3) feeds the list. Nothing here changes the game's rules or shows
what the game keeps hidden.
- **ZeD's own section:** each window and tab, how it works, cut down from the gallery book's chapters.
- **F1 opens on where you are:** pressed in the Vehicle tab it opens Vehicles, in Cooking it opens Cooking.
- **Your controls:** your keys and the controller map as they are set now, in the guide.
- **First days:** a short path for a new character (water, food, a weapon, a safe place, light, sleep).
- **Reference read from the game:** what each skill book and magazine teaches, what each skill level opens, the
  recipes by station. The game's own data, so updates and mods show up.
- **What's new in ZeD:** the change note of the build you are running.

## Open questions

1. **RAD Video Tools:** OK to put the maker's free Bink encoder on this PC for the new clips?
2. **What else:** which of the candidates above, after the research?
