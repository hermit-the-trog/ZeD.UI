# Check: the hidden facts open with a find (punch list 109), Nov 7 2026

Build's check of the TV schedule and infection odds pages, with no game running. The game was not launched.

## What was built

- **ZeD_HiddenFacts.lua** (new): two guide pages read live from the game.
  - **TV schedule**, on the game's Television/Radio topic: the shows on the TV channels that teach a skill or a recipe from now to seven days on, with the day (Today, Tomorrow, In n days), the time (the game's 24-hour or 12-hour clock option), the channel and what it teaches. Read from the stations' broadcast scripts (ZomboidRadio, RadioScriptManager, each TV channel's current RadioScript, its RadioBroadCasts' start and end stamps and the codes on their RadioLines: a skill code with "+", or RCP= for a recipe, as ISRadioInteractions applies them). A note gives this world's LevelForMediaXPCutoff.
  - **Infection odds**, on the game's Zombie Attacks topic, after the world's infection table the guide already had: Bitten, Laceration, Scratched with Always, Sometimes or Never for this world's Transmission (the game's BodyPart: a bite passes it unless Transmission is None; a scratch or a laceration sometimes, never with Saliva Only or None). The world's choice in a note. Behind the spoiler bar, as the world's table. Nothing reads the character's body: never a live "you are infected".
  - **Locked pages:** until the find is read, the page says what more it could show and what to find: "Read Magazine: TV Monthly to add the broadcast schedule here." / "Read a First Aid book to add the infection odds here." (one column and one row, so the Simple window and the Full book both draw it).
  - **The finds:** Magazine: TV Monthly (Base.TVMagazine, Base.TVMagazine_New) opens the schedule; a First Aid book (Base.BookFirstAid1 to 5) read to its last page opens the odds. Kept on the character: ZeD marks it when the reading ends (ISReadABook:perform, wrapped), and the game's own records count too (a "TVMagazine_<month>_<year>" title in getReadLiterature; a First Aid book's pages in getAlreadyReadPages), so a magazine read before this build opens the page.
- **Settings.lua:** a new addition, **Hidden facts** (Find first / Always). Find first for a new player, in Vanilla and in Vanilla Plus; Always in Vanilla Access; Custom holds the hand pick. A player saved on Vanilla Access before the row existed gets Always, as with the Identity row in beta 6, so the preset does not drop to Custom. Its row is in ZeD setup's additions group, after Sandbox options in game.
- **CraftingCore.lua:** on Always, How to learn names the magazine that teaches the recipe (the item scripts' LearnedRecipes; up to two names): "Find Angler USA Magazine Vol. 1, ...". Otherwise, and for a recipe no magazine teaches, it stays "Find recipe magazine or schematic".
- **UI.json, all 28 languages:** 27 new keys (UI_ZeD_Hidden_*, UI_ZeD_Settings_HiddenFacts, _HiddenFactsTip, _FindFirst, UI_ZeD_Craft_FindNamed), the project's AI drafts. The game's own keys where they fit: IGUI_RadioChannel, IGUI_health_Bitten / _Cut / _Scratched, IGUI_perks_*, the item names, the sandbox option's own name and choice.

## Why a First Aid book opens the odds

The game's own first aid literature, already in its loot, is the First Aid skill books (First Aid I to V, SkillTrained = FirstAid). The other medical items are generic: Book_Medical, Paperback_Medical and BookFancy_Medical draw as "Book", "Paperback" and "Leatherbound Book" with random titles, so a player could not tell which to look for, and Magazine_Health is a general health magazine (its issues include Men's Health), not first aid. Any First Aid volume counts; the locked line names the skill, not a volume, since volume I is the one every character can read (the game resets the pages of a book more than one level above the reader).

## What the game cannot give

- **The scratch and laceration chances.** The 7% and 25% are numbers passed inside the game's Java (BodyDamage calls BodyPart.generateZombieInfection with them); no getter, sandbox option or script holds them, so Lua cannot read them live. The page says so in its note and shows Always / Sometimes / Never instead. If the director wants the numbers, they would have to be written into ZeD and checked by hand at each game update.
- **The schedule on a multiplayer client** may be empty if the server has not sent its broadcast data; the page then says no show is listed instead of failing.

## Tests

- `lua51 ZeDUI/tools/qa/hidden_facts_sim.lua`: **1798 checks, 0 failed.** Loads the real Settings.lua and ZeD_HiddenFacts.lua on stubs and the game's real media/radio/RadioData.xml:
  - the choice, its default, the three presets, picking a preset, Custom, the older Vanilla Access save, the ZeD setup row;
  - locked in Vanilla and Vanilla Plus (the lines, the item name, the world's table still first), open in Vanilla Access with nothing read;
  - reading: other reading opens nothing; TV Monthly opens only the schedule; a First Aid book part read opens nothing, read to the end opens the odds; both TV Monthly items and any volume; the game's own records with no ZeD mark;
  - the live schedule against the real data at three times (only TV, only teaching shows, the next seven days, in order), Fishing, Cooking, Carpentry and "Recipe: Make Fishing Rod" found, no stat codes; a hand-made week (a show airing now, yesterday's gone, one beyond the week, a radio station that teaches, a script starting on a later day, a tie at one minute), both clocks, no radio at all;
  - the odds for each Transmission choice; recipe sources per preset; every key in all 28 languages with the English %n markers and no middle dot.
  - It fails on the old code: ZeD_HiddenFacts.lua and the hiddenFacts option do not exist there.
- Other sims that read the changed files, all 0 failed: guide_contents_sim (1721), guide_ads_sim (405), admin_cards_sim, card_cover_sim, claim_cards_sim, community_cards_sim, extras_cards_sim, log_cards_sim, log_sim, menus_b7_sim, ticket_cards_sim.
- `i18n_guard.py`: PASS.
- javap (42.22) for every Java call added: ZomboidRadio.getScriptManager, RadioScriptManager.getCurrentTimeStamp / getChannelsList, RadioChannel.IsTv / getCurrentScript / GetName, RadioScript.getStartDayStamp / getBroadcastList, RadioBroadCast.getStartStamp / getEndStamp / getLines, RadioLine.getEffectsString, IsoGameCharacter.getReadLiterature / getAlreadyReadPages(String), ScriptManager.FindItem(String) / getAllItems / getCraftRecipe(String), Item.getNumberOfPages / getLearnedRecipes / getDisplayName / getFullName, CraftRecipe.getTranslationName, getItemNameFromFullType. The timestamp math was read from the bytecode (RadioScriptManager.UpdateScripts: day * 1440 + hour * 60 + minute; RadioScript.setStartDayStamp: day * 1440).

## Not tested

- In the game: nothing was launched. QA should open F1 on Television/Radio and Zombie Attacks in Vanilla (locked), read a TV Monthly and a First Aid book, then reopen (open), and pick Vanilla Access in ZeD setup; in both looks (Simple window and the Full book), at 1366 x 768 and on the Deck with Large text.
- 42.21: only 42.22 is installed here. The radio classes and calls are the ones the game's own debug radio windows use, which 42.21 has too, but this was not checked against a 42.21 jar.
- Multiplayer: whether the broadcast scripts reach a client, and whether ZeD's mark in the character's mod data survives a server save (the game's own reading records are the fallback).
- Split screen: the pages read player 1's finds.
- The Full book gains a rules page on Television/Radio, so later pages and the gallery spreads may move by one or two.
