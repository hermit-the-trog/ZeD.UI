# Check: the hidden facts open with a find (punch list 109), Nov 7 2026

Build's check of the TV schedule and infection odds pages, with no game running. The game was not launched. The game here is 42.21.

## What was built

- **ZeD_HiddenFacts.lua** (new): two guide pages read live from the game.
  - **TV schedule**, on the game's Television/Radio topic: the shows on the TV channels that teach a skill or a recipe from now to seven days on, with the day (Today, Tomorrow, In n days), the time (the game's 24-hour or 12-hour clock option), the channel and what it teaches. Read from the stations' broadcast scripts (ZomboidRadio, RadioScriptManager, each TV channel's current RadioScript, its RadioBroadCasts' start and end stamps and the codes on their RadioLines: a skill code with "+", Build 42's newer ones too (MAS, POT, BLA, GLA, HUS, BUT, TRK), or RCP= for a recipe, as ISRadioInteractions applies them). Each channel is read on its own, so one that fails leaves the rest. A note gives this world's LevelForMediaXPCutoff.
  - **Not available here:** when no TV channel has a script (a server's client: the server runs the broadcasts), the page says "The broadcast schedule is not available here: the server keeps it." instead of claiming nothing airs.
  - **Infection odds**, on the game's Zombie Attacks topic, after the world's infection table the guide already had: Bitten, Laceration, Scratched with Always, Sometimes or Never for this world's Transmission (the game's BodyPart: a bite passes it unless Transmission is None; a scratch or a laceration sometimes, never with Saliva Only or None). The world's choice in a note. When Mortality is Never, the first note says plainly that the infection is not fatal in this world. Behind the spoiler bar, as the world's table. Nothing reads the character's body: never a live "you are infected".
  - **Locked pages:** until the find is read, the page says what more it could show and what to find: "Read Magazine: TV Monthly to add the broadcast schedule here." / "Read a First Aid book to add the infection odds here." (one column and one row, so the Simple window and the Full book both draw it).
  - **The finds:** Magazine: TV Monthly (Base.TVMagazine, Base.TVMagazine_New) opens the schedule; a First Aid book (Base.BookFirstAid1 to 5) read to its last page opens the odds. ZeD marks the find in the character's mod data when the reading ends (ISReadABook:perform, wrapped), as KillTracker keeps its marks. On a server's client the game never moves the pages on, so there the end of the reading itself counts (the action lasts the whole book; a book too hard or outgrown is stopped first and never reaches perform). The game's own records count too (a "TVMagazine_<month>_<year>" title in getReadLiterature; a First Aid book's pages in getAlreadyReadPages).
  - **Split screen:** W.open is wrapped to note the player the guide opens for (W._pn); the pages read that player's finds.
- **Settings.lua:** a new addition, **Hidden facts** (Find first / Always). Find first for a new player, in Vanilla and in Vanilla Plus; Always in Vanilla Access; Custom holds the hand pick. A player saved on Vanilla Access before the row existed gets Always. The beta 6 Identity repair now compares only the rows beta 6 had (REPAIR_IDS), so Hidden facts or any later addition never stops it; when it runs, newer rows the save has no line for are set to Vanilla Access too. Its row is in ZeD setup's additions group, after Sandbox options in game.
- **CraftingCore.lua:** on Always, How to learn names the magazine that teaches the recipe (the item scripts' LearnedRecipes; up to two names): "Find Angler USA Magazine Vol. 1, ...". A group in LearnedRecipes (base:kitchentools) resolves to the craft recipes whose MetaRecipe it is. Otherwise, and for a recipe no magazine teaches, it stays "Find recipe magazine or schematic". A failed build of the index is not kept.
- **UI.json, all 28 languages:** 29 new keys (UI_ZeD_Hidden_*, UI_ZeD_Settings_HiddenFacts, _HiddenFactsTip, _FindFirst, UI_ZeD_Craft_FindNamed), the project's AI drafts. The game's own keys where they fit: IGUI_RadioChannel, IGUI_health_Bitten / _Cut / _Scratched, IGUI_perks_*, the item names, the sandbox options' own names and choices. Main merged in with both sides kept.

## Why a First Aid book opens the odds

The game's own first aid literature, already in its loot, is the First Aid skill books (First Aid I to V, SkillTrained = FirstAid). The other medical items are generic: Book_Medical, Paperback_Medical and BookFancy_Medical draw as "Book", "Paperback" and "Leatherbound Book" with random titles, so a player could not tell which to look for, and Magazine_Health is a general health magazine (its issues include Men's Health), not first aid. Any First Aid volume counts; the locked line names the skill, not a volume, since volume I is the one a new character can read (the game resets the pages of a book more than one level above the reader). A character whose First Aid has outgrown every volume cannot finish one (the game stops an outgrown book); Vanilla Access or Always is their way to the page.

## What the game cannot give

- **The scratch and laceration chances.** The 7% and 25% are numbers passed inside the game's Java (BodyDamage calls BodyPart.generateZombieInfection with them); no getter, sandbox option or script holds them, so Lua cannot read them live. The page says so in its note and shows Always / Sometimes / Never instead. If the director wants the numbers, they would have to be written into ZeD and checked by hand at each game update.
- **The schedule on a multiplayer client:** the server keeps the broadcast scripts, so a client says the schedule is not available there.

## Tests

- `lua51 ZeDUI/tools/qa/hidden_facts_sim.lua`: **1995 checks, 0 failed.** Loads the real Settings.lua and ZeD_HiddenFacts.lua on stubs and the game's real media/radio/RadioData.xml:
  - the choice, its default, the three presets, picking a preset, Custom, the older Vanilla Access save, the ZeD setup row;
  - the beta 6 repair with Hidden facts unsaved (repaired, Always, the preset back to Vanilla Access), with a saved Find first (kept, Identity still repaired), and with a real hand pick (not repaired);
  - locked in Vanilla and Vanilla Plus, open in Vanilla Access with nothing read;
  - reading: other reading opens nothing; TV Monthly opens only the schedule; a First Aid book part read opens nothing, read to the end opens the odds; the game's own records; split screen (player 2's reading opens player 2's page only); a server's client with stale page counts (the end of the reading counts, a stopped one does not);
  - the live schedule against the real data at three times; a hand-made week; no scripts on a client, no channels, no radio (not available here); a bad channel beside a good one; the newer skill codes; both clocks;
  - the odds for each Transmission choice, and Mortality Never; recipe sources per preset, a tag group, a failed build retried; every key in all 28 languages with the English %n markers and no middle dot.
  - On a4f55a07's code it fails 19 checks: split screen, the beta 6 repair, the client schedule and the bad channel, Mortality Never, the client finds, the newer skill codes and the tag groups.
- Other sims that read the changed files, all 0 failed: guide_contents_sim, guide_ads_sim, admin_cards_sim, card_cover_sim, claim_cards_sim, community_cards_sim, extras_cards_sim, log_cards_sim, log_sim, menus_b7_sim, ticket_cards_sim.
- `i18n_guard.py`: PASS.
- javap against the installed 42.21 jar for every Java call added: ZomboidRadio.getScriptManager, RadioScriptManager.getCurrentTimeStamp / getChannelsList, RadioChannel.IsTv / getCurrentScript / GetName, RadioScript.getStartDayStamp / getBroadcastList, RadioBroadCast.getStartStamp / getEndStamp / getLines, RadioLine.getEffectsString, IsoGameCharacter.getReadLiterature / getAlreadyReadPages(String), ScriptManager.FindItem(String) / getAllItems / getAllCraftRecipes / getCraftRecipe(String), CraftRecipe.getMetaRecipe / getTranslationName, Item.getNumberOfPages / getLearnedRecipes / getDisplayName / getFullName, getItemNameFromFullType, getZomboidRadio. The timestamp math was read from the bytecode (RadioScriptManager.UpdateScripts: day * 1440 + hour * 60 + minute; RadioScript.setStartDayStamp: day * 1440).

## Not tested

- In the game: nothing was launched. QA should open F1 on Television/Radio and Zombie Attacks in Vanilla (locked), read a TV Monthly and a First Aid book, then reopen (open), and pick Vanilla Access in ZeD setup; in both looks (Simple window and the Full book), at 1366 x 768 and on the Deck with Large text.
- 42.22: only the 42.21 jar is installed here now, so the calls were not checked against a 42.22 jar.
- Multiplayer: whether the client's timed action perform comes after the server completes the reading, and whether the character's mod data mark survives a server save as KillTracker's does (the game's own reading records are the fallback).
- Split screen with both guides open at once: the guide keeps one rules cache, emptied at each open, so the second player's open refreshes it for both.
- The Full book gains a rules page on Television/Radio, so later pages and the gallery spreads may move by one or two.
