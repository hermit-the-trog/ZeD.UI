# Mods screen: readability (Workshop feedback, Nov 4 2026)

QA notes for the director and Build. Findings and options only; nothing is built.

## What players said

- **FAIV (Suggestions thread, Nov 4):** the Mods screen is overwhelming in a large list. Every row looks the same: one accent, one transparency, so on and off mods can't be told apart at a glance. Asks for a filter that shows only the mods that are off, a way to hide incompatible mods, and a different look for mods that are on (a different colour, or a darker solid background).
- **Kable (comments, Oct 31, about 1500 mods):** folders, Find in the load order, Load first / last, Load before / after. All of these are built now (ZeD_MainMenuModsOrder.lua, ZeD_MainMenuModsSeps.lua, ZeD_ModFolders.lua). The reply can say so.
- **糕级冻雾 (comments, Nov 3):** ZeD takes a lot of learning, and they ask whether other UI mods are still needed.

## What the code shows (ZeD_MainMenuMods.lua)

- `drawModRow`: on and off rows differ only by the checkbox. A row's name dims only when it is off *and* has a problem. Selection, hover and focus all use the accent.
- Filter tabs: All, On, Starred, Maps, Problems, Conflicts, Workshop. There is no Off tab and no way to hide incompatible mods.
- Each row has two lines: the name, then the mod ID (or the problem). Chips for conflicts and Steam's state sit at the right.

## What other managers do (research summary)

- On/off is a checkbox or the list a mod sits in (Active vs Available). Off is usually also shown by dimmed text.
- Problems are shown by one marker shape plus a hover line that gives the cause and the fix. When colour is the only signal, players complain (MO2's cyan and magenta).
- Enabled / Disabled filters are the common minimum. The better managers hide a filter when it would be empty (ZeD already does) and remember the filter between visits.
- Newcomers get auto-sort and defaults. Experts get rules, pins and keyboard moves. ZeD already has the expert half.
- Separators that can be collapsed, with a count, are the standard for big lists (ZeD has them in the load order).
- Sources: RimSort docs, Fluffy's Mod Manager README, MO2 and STEP forum posts, Factorio wiki and FFF-272, Modrinth app changelog, Irony FAQ, PZ "[B42] Mod Manager" (3567084868).

## Options (design calls for the director)

1. **How "on" looks in the list**
   - (a) On rows get a darker solid band. Off rows stay plain, with their name dimmed. *Recommended: it answers FAIV directly, and the accent stays free for selection.*
   - (b) Off rows only dim their name and icon. On rows stay as now.
   - (c) A thin bar on the left edge of rows that are on.
2. **New filters**
   - An **Off** tab beside On.
   - A **Hide incompatible** box by Find, kept between visits.
   - Optionally an **Updates** tab for Workshop items that need updating.
3. **A Simple view for newcomers** (the rule that every surface gets a Simple version)
   - One line per mod: the checkbox, the name and a single problem mark.
   - IDs, chips and the info pane's tabs only in Full.
   - The choice lives in ZeD setup, like the guide's Full / Simple.
4. **The filter is remembered** when the screen closes and reopens.

## The director's decisions (Nov 4 2026)

- **Approved:** 1(a), the darker solid band on rows that are on, with off rows' names dimmed. Also the Off tab, Hide incompatible (kept between visits), the Simple view in ZeD setup, and the filter remembered.
- **Not wanted:** a mark on the left edge of a row ("too modern web standard").
- **New:** a colour for each mod folder and each separator, picked by the player. Use what is already in the toolbox:
  - The colour shows the way System 7's Finder labels did. It tints the folder's own pixel icon, and the separator's rule and name. No edge bar or stripe.
  - The picker is the Maps tab's ink swatch row (MapsTab.lua `_swatch`: hover wash, controller focus, an edge so dark inks stay apart). "None" is the first swatch.
  - **Decided: System 7 Finder labels.** A fixed set: None, then the seven label colours (Essential orange, Hot red, In Progress magenta, Cool cyan, Personal blue, Project 1 green, Project 2 brown). Each is tuned to stay readable in every theme and accent.
