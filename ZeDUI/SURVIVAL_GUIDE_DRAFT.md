# Survival guide (F1): design draft (Nov 3 2026)

The director, Nov 3 2026: "The ingame survival guide is next. Let's start on it. F1 guide..." Today ZeD passes the
game's guide through untouched (HOOK_MAP row 18). Nothing is built yet; this draft is for the director's answers.

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

## Questions for the director

1. **Its shape:** a plain ZeD window as above, or the ZNIX manual look of the gallery book (the pages, the taped
   prints) in game? *Build's pick: the plain window first. The book look could come later as the Full version, with
   the window as the Simple one.*
2. **ZeD's own pages:** add a "ZeD" section to the guide that explains ZeD's windows (the gallery book's chapters,
   cut down), or keep the guide to the game's topics? *Build's pick: yes, one ZeD section at the end.*
3. **The clips:** keep the game's video clips as they are (they show the game's own UI, not ZeD's), or show the text
   only? *Build's pick: keep them; they show the moves, not the menus.*
4. **First run:** never open by itself (your no-interruptions rule), F1 and the Help wheel only? *Build's pick: yes.*
