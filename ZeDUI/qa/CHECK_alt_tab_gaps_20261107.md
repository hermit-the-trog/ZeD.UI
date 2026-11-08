# In-game check: the alt-tab gaps (punch list 109), Nov 7 2026

What the sim (ZeDUI/tools/qa/alt_tab_gaps_sim.lua) can't show: how it looks, the game's real recipes and the
game's own focus pause. One test resolution (4K at 1.75x), plus the guide at 1366 x 768.

## 1. Used to make, on the item card

- Open the card for a saw, a hammer, a log, nails, a carrot. Under the card's facts (after In lists) a section
  "Used to make": each recipe the item goes into, Known (green square) or Unknown (red square), known ones first,
  six at most, then a row "N more".
- The Known / Unknown on a row matches the Craft tab's card for that recipe (learn one from a magazine: it turns
  Known within a second, without reopening the card).
- An item no recipe takes (a key, a rock if none): no section, no empty title.
- Click a row: the World window's Craft tab opens with that recipe selected. A build recipe (a wall from planks)
  opens the Build tab on it. Click "N more": the Craft tab with the item's name in the search.
- Controller: from the card's verbs, D-pad down reaches the rows; the focus mark sits on the row; A opens as a click
  does; B still closes the card. Both cards (Character window, World window) and the 220 and 480 widths.
- Time the first card opened after loading a save: no hitch (the index is built as the game starts).
- Large text, every theme: the label ends in "..." before the Known word, never under it.

## 2. What the next skill levels need, on the skill card

- Skills tab, hover a skill below 10 (Carpentry 2, Cooking 0): the row's card shows "Recipes that need each level",
  then "Level N: count" for each level still to come, the next level's first three recipes by name under it, and
  "and N more".
- A skill no recipe needs (Sprinting, Fitness): no lines; a skill at 10: no lines.
- With Skill Recovery Journal or Clear Skill Sheet on: their lines come first, these after.
- Controller focus on a row: the same card under the row.

## 3. Pause when the window loses focus

- Single player, the game's Options > Display "Pause on Focus Loss" on (the game's default): alt-tab out; the game
  pauses (the watch / speed keys show paused). Alt-tab back: still paused, as vanilla.
- The same option off: alt-tab does not pause.
- The watch and the vanilla speed controls: the vanilla ones never draw on screen (they stay parked).
- Multiplayer: nothing pauses (the game never pauses a server), and the vanilla speed controls stay hidden.
- Safe mode on, then off: the vanilla speed controls come back and go away as before.

## 4. The guide at 1366 x 768

- F1, the Full look, at 1366 x 768 Auto, Normal and Large text: the Skill Books, Eating and Drinking, Sow Seeds,
  Treat Water and Zombie Attacks rules tables fit their column, no clipped heads, scroll to the bottom of each.

## Not built (the game does not give it to Lua)

- Moodle thresholds: the numbers live in MoodleStat (zombie.characters.Moodles), which the game does not expose to
  Lua on 42.22 (not in LuaManager's exposer, and no exposed method returns one). Moodles.getMoodleLevel gives only
  the level. No page was made.
