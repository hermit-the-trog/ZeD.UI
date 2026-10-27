# Compatibility round 3: results

Tested Oct 26 2026 with ZeD-GUI 0.2.0-t6 (main, commit 1d7ba92e and later; no ZeD code changed for this round), Project Zomboid 42.21, single player, 3840x2160 fullscreen at ZeD's UI scale 1.75, on copies of the ZeD-QA save (`zedqa_mods_run.ps1`, ZeD loaded last; the save is put back after each run). Candidates and groups: `compat_round3_candidates.md`. Subscriptions: `subscriptions_ledger.md`.

## How each group was tested

- The group's mods on at once (mod ids the game knows, checked at the main menu with `tools/qa/zedqa_r3_ids.lua`; requirements first; for a Workshop item with variants only its base mod; Java and ZombieBuddy sub-mods left out), then a manifest of ZeD's tests for the windows the group touches (`tools/qa/compat_r3_<G>.txt`), led by a survey script (`tools/qa/zedqa_r3_<G>.lua`):
  - a census of every visible UI element (a vanilla window ZeD replaces shown anyway, a mod's own panel or HUD),
  - the item menu and the world menu (which mods add rows to ZeD's menus),
  - the item tooltip of a shirt, a book, a VHS and a seed packet, drawn once by ZeD and once in ZeD's safe mode (the game's own tooltip with every mod's wrapper): a line that shows only in safe mode is one ZeD's tooltip leaves out,
  - ZeD's Character tabs (Equip, Health, Skills, Identity) and World tabs (Craft, Build, Maps), each captured once the windows are still,
  - the group's own mod windows opened through each mod's own open function, each captured.
- Main-menu mods: `tools/qa/zedqa_r3_menu.lua` through `zedqa_menu_mods_run.ps1` (ZeD's main menu, Mods, Options, then New Game through the occupation and traits screen and Looks).
- Vehicle packs (group D): `tools/qa/zedqa_r3_D_cars.lua`, each car spawned at the Irvington Speedway drag strip, driven seat, key, engine, ZeD's dashboard and Vehicle tab captured.
- Any error a mod made was checked with ZeD off (`zedqa_modload_run.ps1 -ZeD off`, same mod list) before it was put on ZeD.
- Screenshots were read for every group (crops of anything notable in `ZeDUI/qa/compat_round3/`).

Lists, as in the Compatibility thread (`steam_threads/compat_v3/README.md`): **Supported** (ZeD has code for the mod), **Works well** (fills a gap or shows well in ZeD's windows), **Compatible** (loads and works; "Part of it does not show" means it adds to a game screen ZeD replaces), **Not needed** (ZeD does the job), **Does not work** (broken, by itself or with ZeD). A note marked (by reading its code) or (expected) was not seen in a test.

## Counts

| List | Mods |
|---|---|
| Supported | 0 |
| Works well | 1 |
| Compatible | 29 |
| Not needed | 6 |
| Does not work | 1 |
| Tested in all | 37 |
| Not tested | 1 |


## Results by group

### Group A

Reports: qa/regression/2026-10-26_1919_mods_fullscreen4k.md; 2026-10-26_1932 (survey rerun); qa/modload/2026-10-26_1928_zed-off.md

| Mod | Workshop id | Tier | List | Evidence |
|---|---|---|---|---|
| PZ-ClothingUI - Clothing items grid view (B41 + B42 Updated) | [2695471997](https://steamcommunity.com/sharedfiles/filedetails/?id=2695471997) | 1 | Compatible | Its clothing window opens from its own button and sits beside ZeD's windows (seen, 8_clothingui). |
| [42.20] Customizable Containers | [2719850086](https://steamcommunity.com/sharedfiles/filedetails/?id=2719850086) | 1 | Compatible | Lua mod only (its Capacity Limit Bypass sub-mod is a Java jar, left out). Loads, no errors of its own. |
| [FIXED] Proximity Inventory B42.20 COMPATIBLE [SP/MP] | [3669550831](https://steamcommunity.com/sharedfiles/filedetails/?id=3669550831) | 1 | Compatible | Part of it does not show: its one container of everything nearby goes on the game's loot window; ZeD's World window shows each container in reach as its own column (by reading its code: ISInventoryPage.localContainer). |
| Container Tags [B42 + MP] | [3066276504](https://steamcommunity.com/sharedfiles/filedetails/?id=3066276504) | 1 | Compatible | Loads; its tag panel is up (census CTagsPanel). Tag window itself not opened. |
| Easy Drop'n'Loot | [2871469707](https://steamcommunity.com/sharedfiles/filedetails/?id=2871469707) | 1 | Compatible | Its Drop all (Category) and Drop all on the floor (Category) rows are in ZeD's item menu (seen); its Loot / Transfer Category buttons for the game's loot window were not seen in ZeD's footer. |
| [B42MP] Take Any Amount | [3389115640](https://steamcommunity.com/sharedfiles/filedetails/?id=3389115640) | 1 | Compatible | Loads, no errors; its rows come through the game's item menu, which ZeD's menu shows (by reading its code). |
| Extended categories - Better Hoarding! (B42 SP/MP) | [3650035249](https://steamcommunity.com/sharedfiles/filedetails/?id=3650035249) | 1 | Compatible | Part of it does not show: its categories and colours are drawn on the game's inventory list, which ZeD replaces (by reading its code: ISInventoryPane drawText). One error of its own at the main menu on 42.21 (option text IGUI_CAEC_Options_categoryColorsTintStrength has a stray %), also with ZeD off. |
| NeatUI Equipment [42.21] | [3790656296](https://steamcommunity.com/sharedfiles/filedetails/?id=3790656296) | 1 | Not needed | ZeD's Equip tab has a paper doll. Its panel hangs on the game's inventory window, which ZeD replaces: its toggle is there with no size (census NEQ_ToggleButton 0x16). |
| Nick's Inventory Selection Fix | [3782920935](https://steamcommunity.com/sharedfiles/filedetails/?id=3782920935) | 1 | Not needed | It fixes selection in the game's inventory list, which ZeD replaces; ZeD's lists have their own selection (expected). |
| [B42/41] Improved Farming Info Window | [3470852353](https://steamcommunity.com/sharedfiles/filedetails/?id=3470852353) | 1 | Not needed | ZeD shows farm plot info in its object card (Overrides/InfoCards); the mod's window is the game's farming info window it replaces (expected). |
| Auto Loot | [3392699932](https://steamcommunity.com/sharedfiles/filedetails/?id=3392699932) | 1 | Works well | Its Auto Loot OFF switch and Store All are buttons in the footer of ZeD's Inventory window, and its Auto Loot Item Type / Container Auto Loot rows are in ZeD's item and container menus (seen, zqa_r3A_1_loot, cl and op tests). |
| [B42] Nested Containers | [3410947298](https://steamcommunity.com/sharedfiles/filedetails/?id=3410947298) | 1 | Compatible | Part of it does not show: the bags inside bags it adds to the game's container buttons are not added to ZeD's columns (by reading its code). |
| O.C.D. Inventory | [3773985930](https://steamcommunity.com/sharedfiles/filedetails/?id=3773985930) | 1 | Compatible | Loads, no errors; it sorts the game's inventory list (ZeD's lists sort themselves) (by reading its code). |
| [B42, READ DESC] Mutie's Context Menu Icons Expanded & Redrawn | [3422112160](https://steamcommunity.com/sharedfiles/filedetails/?id=3422112160) | 1 | Not needed | ZeD's item menu draws its own icon set; a mod's icon shows only on rows ZeD has no icon for (ZeD ContextMenuRegistry: its icon first, the option's iconTexture after). Storage + Redrawn sub-mods tested. |
| Icons Inventory | [3718412967](https://steamcommunity.com/sharedfiles/filedetails/?id=3718412967) | 1 | Compatible | Part of it does not show: its icon grid is on the game's inventory window (by reading its code). Its first-start window (Smart Inventory Gestures) opens over the game at the left, not over ZeD's windows (seen). |
| Stack All | [2629074154](https://steamcommunity.com/sharedfiles/filedetails/?id=2629074154) | 2 | Compatible | Loads, no errors; its Stack All row comes through the game's item menu (by reading its code). |
| Addicted To Weight | [2604943386](https://steamcommunity.com/sharedfiles/filedetails/?id=2604943386) | 2 | Compatible | Loads; its weight HUD and its first-start note window show over the game, clear of ZeD's windows (seen, zqa_r3A_1_loot). |
| Better Generator Info | [3576056135](https://steamcommunity.com/sharedfiles/filedetails/?id=3576056135) | 2 | Not needed | ZeD routes the generator info window to its object card (Overrides/InfoCards), so its better generator window does not show (expected). |
| Known And Collected | [2881764317](https://steamcommunity.com/sharedfiles/filedetails/?id=2881764317) | 2 | Compatible | Loads, no errors; its read marks are drawn on the game's inventory list (ZeD marks read / unread itself from 0.2.0-t6) (by reading its code). |
| [B42] Item Details | [3477237184](https://steamcommunity.com/sharedfiles/filedetails/?id=3477237184) | 2 | Compatible | Loads, no errors; its details are drawn on the game's inventory list (by reading its code). |
| True Weight | [3768669395](https://steamcommunity.com/sharedfiles/filedetails/?id=3768669395) | 2 | Compatible | Loads, no errors (item weight values only). |
| [B41,B42] Show VHS skills in tooltip | [3716522633](https://steamcommunity.com/sharedfiles/filedetails/?id=3716522633) | 2 | Compatible | Loads; it hooks the tooltip at game start, after ZeD, so its lines show on ZeD's tooltip (by reading its code; VHS tooltip same in ZeD and safe mode). |
| [B42] Item Condition Fix | [3394609418](https://steamcommunity.com/sharedfiles/filedetails/?id=3394609418) | 2 | Not needed | Fix for Item Condition, whose bars are on the game's hotbar; ZeD shows condition on the belt and in every list (as Item Condition, round 2). |
| [B42] Horticulture | [3650168851](https://steamcommunity.com/sharedfiles/filedetails/?id=3650168851) | 2 | Compatible | Loads, no errors (farming content). |
| Item Rarity UI (Build 41 + 42) | [3662387304](https://steamcommunity.com/sharedfiles/filedetails/?id=3662387304) | 2 | Compatible | Part of it does not show: its rarity colours and sort are for the game's inventory list (by reading its code: ISInventoryPane). |
| Obvious Skill Tapes - highlight useful VHS tapes | [3739168410](https://steamcommunity.com/sharedfiles/filedetails/?id=3739168410) | 2 | Compatible | Part of it does not show: its tape highlight is drawn on the game's inventory list (by reading its code). |
| Farming Expansion B42 | [3444499190](https://steamcommunity.com/sharedfiles/filedetails/?id=3444499190) | 2 | Compatible | Loads, no errors (farming content). |
| Better Clothing Info | [3604080281](https://steamcommunity.com/sharedfiles/filedetails/?id=3604080281) | 2 | Compatible | Loads, no errors; its wear preview is in the game's item menu tooltip (not checked). |
| Show Sowing Season In Seed Tooltip | [3404461962](https://steamcommunity.com/sharedfiles/filedetails/?id=3404461962) | 2 | Compatible | Part of it does not show: its sowing lines go on the game's item tooltip through Starlit Library, and ZeD's tooltip leaves them out (seen: seed tooltip in ZeD vs ZeD's safe mode, seed_tooltip_ab.png). ZeD bug 1. |
| Smarter Storage - Extra Presets | [3587884762](https://steamcommunity.com/sharedfiles/filedetails/?id=3587884762) | 2 | Compatible | Loads, no errors; Smarter Storage's names and colours go on the game's container buttons (as Smarter Storage, round 2). |
| Immersive Hotwire | [3653092321](https://steamcommunity.com/sharedfiles/filedetails/?id=3653092321) | 2 | Compatible | Loads, no errors (hotwire mini-game not tried). |
| [B42/41] Better Clothing Info Comparison | [3036830549](https://steamcommunity.com/sharedfiles/filedetails/?id=3036830549) | 2 | Does not work | Its clothing tooltip errors every frame on 42.21 in the game's own tooltip (DoTooltipClothing, bcic_TooltipClothing.lua:65, a nil call), seen in ZeD's safe mode; under ZeD's tooltip its comparison is left out (ZeD bug 1). |
| Try Before You Wear | [3797492691](https://steamcommunity.com/sharedfiles/filedetails/?id=3797492691) | 2 | Compatible | Its Try Before You Wear window opens (its own open) centred over the game, clear of ZeD's windows (seen, 9_tbyw). |
| Container Capacity Indicator [B42] | [3789660055](https://steamcommunity.com/sharedfiles/filedetails/?id=3789660055) | 2 | Compatible | Part of it does not show: its capacity marks are drawn on the game's container buttons (by reading its code). |
| Equip Clothing While Moving [B42.20/B42.19/B41] | [3446510982](https://steamcommunity.com/sharedfiles/filedetails/?id=3446510982) | 3 | Compatible | Loads, no errors (timed actions only). |
| Craft Engine Parts | [2744114761](https://steamcommunity.com/sharedfiles/filedetails/?id=2744114761) | 3 | Compatible | Loads, no errors (recipes). CraftEngineParts sub-mod (its price variants are alternatives). |
| Hoarder's Delight - Box & Carton Bulk Packing [42.21 Stable] | [3626823538](https://steamcommunity.com/sharedfiles/filedetails/?id=3626823538) | 3 | Compatible | Loads, no errors (packing recipes). |

## Not tested, and why

| Group | Mod | Workshop id | Why |
|---|---|---|---|
| A | Viperel's Vehicle Spare Parts | [2712632417](https://steamcommunity.com/sharedfiles/filedetails/?id=2712632417) | Its folder on disk has the Build 41 layout only (no 42 or common folder): the game does not list it (getModInfoByID nil at the main menu). |

## ZeD bugs found

### 1. ZeD's item tooltip drops the lines other mods add to the game's tooltip

- **File:** `42/media/lua/client/ZeD/Overrides/Tooltip.lua`, `applyTooltipOverrides` (run on `OnGameBoot`). It keeps whatever `ISToolTipInv.render` is at that moment as "vanilla" (`V.invRender`), then replaces `ISToolTipInv:render` with ZeD's own drawing, which calls only `self.item:DoTooltip(self.tooltip)`. The kept function is called only in safe mode.
- **Effect:** a mod that wraps `ISToolTipInv.render` when its file loads (before `OnGameBoot`) to draw extra lines has its wrapper skipped. Seen with Starlit Library's tooltip lines (Show Sowing Season In Seed Tooltip, 3404461962): the seed packet tooltip has 4 lines under ZeD and 8 in ZeD's safe mode. Same pattern, by reading their code: Better Clothing Info Comparison (3036830549, `bcic_Tooltip.lua:228`), This Is Me (3806020504, `TIMReadUIPatch.lua:45`), Brita's Armor Pack B42 (3780298456). Mods that wrap it at `OnGameStart` (after ZeD), such as Show VHS skills in tooltip, keep working.
- **Steps:** `zedqa_mods_run.ps1 -ModList tools/qa/compat_r3_A_mods.txt -Mode fullscreen4k -Manifest tools/qa/compat_r3_A.txt`; `zedqa_r3_A.lua` gives a Carrot seed packet and draws its `ISToolTipInv` at 900,300, once normally and once with ZeD's safe mode option on.
- **Evidence:** `ZeDUI/qa/compat_round3/A_seed_tooltip_zed_vs_safe.png` (left ZeD 202x79, right safe mode 252x144: Sowing Season, Optimal / Risky Sowing Months, Minimum Water Level); report `qa/regression/2026-10-26_1932_mods_fullscreen4k.md` (`tip seed zed 202x79`, `tip seed safe 252x144`).
- **Fix idea (not done):** call the kept function for the content (or call the previous `render` with ZeD's frame drawn first), the way the other ZeD overrides chain to what was there before.
