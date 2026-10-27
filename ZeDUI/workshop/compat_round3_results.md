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
| Works well | 8 |
| Compatible | 261 |
| Not needed | 27 |
| Does not work | 6 |
| Tested in all | 302 |
| Not tested | 3 |


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

### Group B

Reports: qa/regression/2026-10-26_1939_mods_fullscreen4k.md (13/13 pass); main menu: zedqa_r3_menu.lua, 2026-10-26 19:52

| Mod | Workshop id | Tier | List | Evidence |
|---|---|---|---|---|
| Combat Text (B40+B41+B42) | [2286124931](https://steamcommunity.com/sharedfiles/filedetails/?id=2286124931) | 1 | Compatible | Loads, no errors of its own; its floating text manager is up (census ISHealthBarManager). |
| Dynamic Traits and Expanded Moodles [B41 & B42] | [2459400130](https://steamcommunity.com/sharedfiles/filedetails/?id=2459400130) | 1 | Compatible | Loads, no errors. Its own moodles go through Moodle Framework, which keeps them at the game's old place at the right edge (as Moodle Framework, round 2) (expected). |
| Moodle Quarters [B42] | [2854030563](https://steamcommunity.com/sharedfiles/filedetails/?id=2854030563) | 1 | Compatible | Part of it does not show: its quarter marks are for the game's moodle column; its layer is up with no height (census MoodleQuartersUI 48x0). |
| [B42] Mod Manager | [3567084868](https://steamcommunity.com/sharedfiles/filedetails/?id=3567084868) | 1 | Not needed | ZeD's mod manager does the job; with the mod on, ZeD's Mods window lists and switches mods as usual (29 of 1361 on, seen) and the mod's own screens do not show (they patch the game's mod screen). |
| Moodles in lua [B42.20] | [3395171770](https://steamcommunity.com/sharedfiles/filedetails/?id=3395171770) | 1 | Not needed | ZeD draws and places the moodles itself (its Moodles setting: right, left or above the belt) and puts the game's column back where it set it. With this mod on, it also draws some moodles a second time at the game's old place, the right edge 120 down (two seen, whatever ZeD's setting), so use one (seen, B_moodles_bottom_plus_two_at_old_place.png). |
| [B42] Bigger Character Avatar | [3387640099](https://steamcommunity.com/sharedfiles/filedetails/?id=3387640099) | 1 | Compatible | Part of it does not show: it enlarges the figure on the game's character screen; ZeD's Character window has its own figure (by reading its code: ISCharacterScreen). Large size sub-mod tested. |
| Dynamic Moodles | [3674800555](https://steamcommunity.com/sharedfiles/filedetails/?id=3674800555) | 1 | Compatible | Part of it does not show: its moodle looks go to Moodles in lua's drawing, not to ZeD's moodles (expected). |
| CH Status HUD | [3776182375](https://steamcommunity.com/sharedfiles/filedetails/?id=3776182375) | 1 | Compatible | Its status panel shows at the top left (seen, B_hud_mods_windows_open.jpg); ZeD's windows can lie over it when a drawer is open. |
| Minimal Display Bars + Nutritions + Discomfort [B41/B42.20] | [3388844542](https://steamcommunity.com/sharedfiles/filedetails/?id=3388844542) | 1 | Compatible | Its bars show at the top left (seen). |
| Mini Health Plus | [3710913197](https://steamcommunity.com/sharedfiles/filedetails/?id=3710913197) | 1 | Compatible | Its body figure panel shows mid-screen (seen); its click to the Health page was not tried with ZeD (Mini Health Panel's is supported). |
| [B42] Survival HUD | [3495906499](https://steamcommunity.com/sharedfiles/filedetails/?id=3495906499) | 1 | Compatible | Its needs and endurance HUD show at the bottom corners, clear of ZeD's belt (seen); its hotbar dragging is for the game's hotbar, which ZeD's belt replaces (by reading its code). |
| Lua Digital Watch Framework | [3676456221](https://steamcommunity.com/sharedfiles/filedetails/?id=3676456221) | 1 | Not needed | ZeD shows the watch (top right and on the belt); this framework draws the game's digital watch HUD (expected). Not seen: no digital watch worn in the test. |
| [FIXED] Combat Text Patch b42.20 | [3775113600](https://steamcommunity.com/sharedfiles/filedetails/?id=3775113600) | 1 | Compatible | Loads, no errors (patch for Combat Text, loaded after it). |
| Nested Health Info | [3779405481](https://steamcommunity.com/sharedfiles/filedetails/?id=3779405481) | 1 | Not needed | It lays out the game's health panel; ZeD's Health tab replaces that panel (expected). |
| [B41&B42] Show Wall Health | [3002666175](https://steamcommunity.com/sharedfiles/filedetails/?id=3002666175) | 2 | Compatible | Loads, no errors (its wall health window not opened). |
| Stairs Alert | [3044807092](https://steamcommunity.com/sharedfiles/filedetails/?id=3044807092) | 2 | Compatible | Loads, no errors. |
| Large Progress Indicator | [2926455909](https://steamcommunity.com/sharedfiles/filedetails/?id=2926455909) | 2 | Not needed | Textures for the game's action progress bar; ZeD's action bar shows progress (suite_band passed) (expected). |
| [B42] Moodle Descriptions Expanded | [3389003300](https://steamcommunity.com/sharedfiles/filedetails/?id=3389003300) | 2 | Works well | Its longer moodle texts (effects with numbers) are what ZeD's moodle notes show (seen: Nervous, -1.3% Crit, in ZeD's bubble above the belt). |
| [B42.13+] SimpleStatus-Fixed | [3399432867](https://steamcommunity.com/sharedfiles/filedetails/?id=3399432867) | 2 | Compatible | Its status bars show at the left (seen). |
| Simple Moodle Indicators | [3402171609](https://steamcommunity.com/sharedfiles/filedetails/?id=3402171609) | 2 | Compatible | Part of it does not show: its level marks are for Moodles in lua's drawing (expected). |
| Injury Indicator [B42] | [3565698092](https://steamcommunity.com/sharedfiles/filedetails/?id=3565698092) | 2 | Compatible | Loads, no errors. |
| [B42MP] Simple Show XP | [2891170430](https://steamcommunity.com/sharedfiles/filedetails/?id=2891170430) | 2 | Compatible | Loads, no errors. |
| Cone Vision Outline [42.21.0] [SP&MP] | [3659137034](https://steamcommunity.com/sharedfiles/filedetails/?id=3659137034) | 2 | Compatible | Loads, no errors. |
| Pixel Strike Indicator & Health Bar | [3793657917](https://steamcommunity.com/sharedfiles/filedetails/?id=3793657917) | 2 | Compatible | Loads, no errors. |
| Mattnetic's Heart Health Meter [B42] | [3805849470](https://steamcommunity.com/sharedfiles/filedetails/?id=3805849470) | 2 | Compatible | Loads (its log: compatibility renderer installed), no errors. |
| Wound Expansion | [3819438691](https://steamcommunity.com/sharedfiles/filedetails/?id=3819438691) | 2 | Compatible | Base mod only (its ZombieBuddy add-on left out). Part of it does not show: its wound details are on the game's health panel, which ZeD's Health tab replaces (by reading its code). |

### Group C

Reports: qa/regression/2026-10-26_2009_mods_fullscreen4k.md (8/8 pass; an earlier run at 19:54 stalled when the game was minimized by another program and is not graded); main menu: zedqa_r3_menu.lua 20:18

| Mod | Workshop id | Tier | List | Evidence |
|---|---|---|---|---|
| Evolving Traits World (ETW) + More Traits continuation | [2914075159](https://steamcommunity.com/sharedfiles/filedetails/?id=2914075159) | 1 | Compatible | Loads, no errors. Part of it does not show: its trait progress page is added to the game's character window, which ZeD replaces (by reading its code: xpUpdate.characterInfo). Its traits are in ZeD's trait list. |
| Efficiency Skill Mod 2 | [3374408921](https://steamcommunity.com/sharedfiles/filedetails/?id=3374408921) | 1 | Compatible | Its Efficiency skill is in ZeD's starting skills on the occupation screen (seen). Efficiency Skill Mod 2 sub-mod (Legacy left out). |
| [B41/B42] Toughness Skill | [3545533939](https://steamcommunity.com/sharedfiles/filedetails/?id=3545533939) | 1 | Compatible | Loads, no errors (skill). |
| RPGSkillTree[42.13][SP] | [3621388762](https://steamcommunity.com/sharedfiles/filedetails/?id=3621388762) | 1 | Compatible | Its full-screen skill tree opens through its own open (pauses the game, as it does without ZeD) and closes back to ZeD's windows (seen, C_rpg_skill_tree.jpg). Some of its labels show as text keys (UI_RPG_Status): its own. |
| Yaki's Hair Salon | [2761200458](https://steamcommunity.com/sharedfiles/filedetails/?id=2761200458) | 2 | Compatible | Loads, no errors (with Fluffy Hair). |
| First Aid VHS Tapes | [3153010942](https://steamcommunity.com/sharedfiles/filedetails/?id=3153010942) | 2 | Compatible | Loads, no errors. |
| Ellie's Tattoo Parlor V4 b41/b42 | [2735059209](https://steamcommunity.com/sharedfiles/filedetails/?id=2735059209) | 2 | Compatible | Loads, no errors. |
| +300 Points Trait | [899287010](https://steamcommunity.com/sharedfiles/filedetails/?id=899287010) | 2 | Compatible | Its points show in ZeD's occupation screen title (seen). |
| RYG Progress Indicator | [3220040578](https://steamcommunity.com/sharedfiles/filedetails/?id=3220040578) | 2 | Not needed | Textures for the game's action progress bar; ZeD's action bar shows progress (expected). |
| Defecation v3.59 (Build 42.20mp+) | [1436878551](https://steamcommunity.com/sharedfiles/filedetails/?id=1436878551) | 2 | Compatible | Loads, no errors (its windows not opened). |
| True Smoking [B42MP] | [3423984426](https://steamcommunity.com/sharedfiles/filedetails/?id=3423984426) | 2 | Compatible | Loads, no errors; its moodles go through Moodle Framework (game's old place at the right edge, expected). |
| SixthSense | [2863908612](https://steamcommunity.com/sharedfiles/filedetails/?id=2863908612) | 2 | Compatible | Loads, no errors. |
| Somewhat Traits | [3498347699](https://steamcommunity.com/sharedfiles/filedetails/?id=3498347699) | 2 | Compatible | Its traits are in ZeD's trait list (seen). Core + Traits sub-mods. |
| [B42] OSRS Exp Drops | [3391145494](https://steamcommunity.com/sharedfiles/filedetails/?id=3391145494) | 2 | Compatible | Its XP bar shows at the top right below ZeD's watch (census ISExpBar 3440,200). |
| [B42] OSRS XP Drops Retextured | [3413529369](https://steamcommunity.com/sharedfiles/filedetails/?id=3413529369) | 2 | Compatible | Loads with OSRS Exp Drops, no errors. |
| Neon moodle levels | [3392116408](https://steamcommunity.com/sharedfiles/filedetails/?id=3392116408) | 2 | Compatible | Part of it does not show: its level colours are for Moodles in lua's drawing (expected). |
|  Hephas Occupations and Traits | [3256482412](https://steamcommunity.com/sharedfiles/filedetails/?id=3256482412) | 2 | Compatible | Loads on 42.21 without the B41 Profession Framework (its mod.info does not ask for it), no errors. Its 20 occupations replace the game's in ZeD's occupation list (seen; its WithVanillaProfessions sub-mod keeps the game's). |
| Combat Traits | [3427091746](https://steamcommunity.com/sharedfiles/filedetails/?id=3427091746) | 2 | Compatible | Its traits are in ZeD's trait list. Core + Traits sub-mods. |
| Become Desensitized [B42.20 Stable Unofficial SP/MP] | [3738669352](https://steamcommunity.com/sharedfiles/filedetails/?id=3738669352) | 2 | Compatible | Loads, no errors. |
| Adaptive Traits | [3622328997](https://steamcommunity.com/sharedfiles/filedetails/?id=3622328997) | 2 | Compatible | Loads, no errors. |
| Skill Book Expansion | [3557111695](https://steamcommunity.com/sharedfiles/filedetails/?id=3557111695) | 2 | Compatible | Loads, no errors. |
| Exp Recovery for Skill Books | [2923554542](https://steamcommunity.com/sharedfiles/filedetails/?id=2923554542) | 2 | Compatible | Part of it does not show: its marks are for the game's skill page (by reading its code: ISSkillProgressBar). |
| Working Knowledge - Lootable Skill Documents | [3717099183](https://steamcommunity.com/sharedfiles/filedetails/?id=3717099183) | 2 | Compatible | Loads, no errors. |
| Practice Crafting Skills | [3765795716](https://steamcommunity.com/sharedfiles/filedetails/?id=3765795716) | 2 | Compatible | Loads, no errors. Base sub-mod. |
| Eat Smart | [3456212729](https://steamcommunity.com/sharedfiles/filedetails/?id=3456212729) | 2 | Compatible | Loads, no errors; its food rows come through the game's item menu. |
| Challenge Traits - Headshots, CDDA, and More [42.21 Stable] | [3634630898](https://steamcommunity.com/sharedfiles/filedetails/?id=3634630898) | 2 | Compatible | Loads, no errors. |
| This Is Me - More Character Traits | [3806020504](https://steamcommunity.com/sharedfiles/filedetails/?id=3806020504) | 2 | Compatible | Its traits are in ZeD's Traits tab (zedqa_traits.lua passed with it). Part of it does not show: its read-tooltip lines wrap ISToolTipInv.render at load (ZeD bug 1). |
| The Psychopath Trait [B42.20+ SP/MP] | [3736555309](https://steamcommunity.com/sharedfiles/filedetails/?id=3736555309) | 2 | Compatible | One error of its own at load on 42.21: a recipe input LabItems.LabSmallRandomHumanBones not found (a script line, before any UI). Otherwise loads. |
| [B42] Mastered Traits | [3423601261](https://steamcommunity.com/sharedfiles/filedetails/?id=3423601261) | 2 | Compatible | Loads, no errors. MasteredT-20 sub-mod. |
| Become Brave [B42.20 Stable Unofficial SP/MP] | [3738660077](https://steamcommunity.com/sharedfiles/filedetails/?id=3738660077) | 2 | Compatible | Loads, no errors. |
| Gyde's Trait Magazines Extended+ | [3776852122](https://steamcommunity.com/sharedfiles/filedetails/?id=3776852122) | 2 | Compatible | Loads with Gyde's Trait Magazines, no errors. |
| Football & Shoving [SP & MP] | [3750861914](https://steamcommunity.com/sharedfiles/filedetails/?id=3750861914) | 2 | Compatible | Its NFL Player occupation is in ZeD's occupation list (seen). Football sub-mod. |
| Martial Arts - Version 2 | [3812456765](https://steamcommunity.com/sharedfiles/filedetails/?id=3812456765) | 2 | Compatible | Its Martial Arts skill is in ZeD's Skills tab (seen, C_skills_martial_arts.jpg); its style window button is on the game's left side bar (by reading its code). |
| Instinctive Hearing [B42] | [3789584579](https://steamcommunity.com/sharedfiles/filedetails/?id=3789584579) | 2 | Compatible | Base mod only (its outline add-on needs ZombieBuddy). Loads, no errors. |
| [B41/B42] /bin/'s Profession and Skill Based Starting Items | [2974652138](https://steamcommunity.com/sharedfiles/filedetails/?id=2974652138) | 3 | Compatible | Loads, no errors. |

### Group D

Reports: qa/regression/2026-10-26_2020_mods_fullscreen4k.md (ZeD's tests 5/5 pass; vehicle script 68 of 76 checks, the 8 failures were the test's: trailers spawned out of reach, a burnt wreck, the Humvee without its Military Tool Kit); rerun 2026-10-26_2032 (trailers and Humvee 8/8)

| Mod | Workshop id | Tier | List | Evidence |
|---|---|---|---|---|
| Better Auto Mechanics [B42.20.4+ MP+SP] | [3635856965](https://steamcommunity.com/sharedfiles/filedetails/?id=3635856965) | 1 | Works well | Its part actions patch the game's part menu (doPartContextMenu), which ZeD's Vehicle tab calls for its part menu, so they come up there; its own mechanics window is the game's, which ZeD routes to the Vehicle tab (by reading its code; as Auto Mechanics). |
| Standardized Vehicle Upgrades 3 - Vanilla Addon | [3304582091](https://steamcommunity.com/sharedfiles/filedetails/?id=3304582091) | 1 | Compatible | Loads with SVU3 Core and Tsar's library, no errors. |
| Standardized Vehicle Upgrades 3 - Core - B42 | [3403490889](https://steamcommunity.com/sharedfiles/filedetails/?id=3403490889) | 1 | Compatible | Loads, no errors; its upgrades go through the game's part menu (by reading its code). |
| Another Vehicle Claim System | [2957935793](https://steamcommunity.com/sharedfiles/filedetails/?id=2957935793) | 1 | Compatible | Multiplayer mod; its Claimed Vehicles Manager row is in ZeD's world menu (seen). Base sub-mod only. |
| Banger's Retro Car Dashboard [B42] | [3739256322](https://steamcommunity.com/sharedfiles/filedetails/?id=3739256322) | 1 | Not needed | ZeD replaces the dashboard; seated, only ZeD's dashboard shows (census, every car) (as Realistic Dashboard, round 2). |
| Better Lockpicking (Continued) b42.20+ | [3768298886](https://steamcommunity.com/sharedfiles/filedetails/?id=3768298886) | 1 | Compatible | Loads, no errors (its lockpick windows not opened). |
| More Traits Definitive Edition | [3799050151](https://steamcommunity.com/sharedfiles/filedetails/?id=3799050151) | 1 | Compatible | Loads, no errors; its traits go to ZeD's trait list (expected, as More Traits). |
| [B42/B41] The Motorious Zone Vehicle Pack | [2791656602](https://steamcommunity.com/sharedfiles/filedetails/?id=2791656602) | 2 | Compatible | fhqH1 and fhqAZ1 spawned, driven seat, key, engine: ZeD's dashboard shows (generic design) and the Vehicle tab lists 41 / 37 parts. Base + US Motors sub-mods. |
| '90 Mercedes-Benz Unimog U1550L | [2843855721](https://steamcommunity.com/sharedfiles/filedetails/?id=2843855721) | 2 | Compatible | U1550L and U1550L OffRoad: ZeD's dashboard and Vehicle tab (49 / 40 parts). |
| You drive, I sleep | [2830570280](https://steamcommunity.com/sharedfiles/filedetails/?id=2830570280) | 2 | Compatible | Loads, no errors (sleeping in a car not tried). |
| Nepenthe's Colored Engine Status (Now a vanilla feature in B42) | [2975204120](https://steamcommunity.com/sharedfiles/filedetails/?id=2975204120) | 2 | Not needed | Says itself it is now a game feature; its colours are for the game's mechanics window, which ZeD's Vehicle tab replaces (expected). |
| Nepenthe's Colored Battery Status (Now a vanilla feature in B42) | [2973053380](https://steamcommunity.com/sharedfiles/filedetails/?id=2973053380) | 2 | Not needed | Says itself it is now a game feature; its colours are for the game's mechanics window (expected). |
| [B41 / B42.12+] bikinitools - independent vehicle spawner, skin changer and automations! | [2634426926](https://steamcommunity.com/sharedfiles/filedetails/?id=2634426926) | 2 | Compatible | Its bikinitools rows are in ZeD's world menu (seen); three of its own menu texts miss an argument on 42.21 (game warnings, not errors). Base sub-mod. |
| Autotsar Motor Club B42 | [3404737883](https://steamcommunity.com/sharedfiles/filedetails/?id=3404737883) | 2 | Compatible | AMC quad and Harley: ZeD's dashboard and Vehicle tab (27 parts each). |
| Autotsar Trailers B42 | [3402493701](https://steamcommunity.com/sharedfiles/filedetails/?id=3402493701) | 2 | Compatible | TrailerHome and TrailerKbac: ZeD's Vehicle tab beside them (37 / 7 parts) (rerun with the character beside the trailer). |
| [B41/B42] More Immersive Vehicles | [3162566044](https://steamcommunity.com/sharedfiles/filedetails/?id=3162566044) | 2 | Compatible | Loads, no errors. |
| RV Interior Expansion [B42] | [3618427553](https://steamcommunity.com/sharedfiles/filedetails/?id=3618427553) | 2 | Compatible | Loads with Project RV Interior, no errors (interior not entered). |
| Autotsar Bus B42 | [3402812859](https://steamcommunity.com/sharedfiles/filedetails/?id=3402812859) | 2 | Compatible | Army Bus and Prison Bus: ZeD's dashboard and Vehicle tab (60 / 51 parts) (seen, D_bus_dashboard.jpg, D_bus_vehicle_tab.jpg). Its roof rack containers log 'cannot get ID' lines (engine log, not errors). |
| RV Interior Expansion Part 2 [B42] | [3622163276](https://steamcommunity.com/sharedfiles/filedetails/?id=3622163276) | 2 | Compatible | Loads, no errors. |
| Dismantle Any Car | [3428369137](https://steamcommunity.com/sharedfiles/filedetails/?id=3428369137) | 2 | Compatible | Loads, no errors. |
| [B42MP] FlipVehiclePlusTrailer | [3430172149](https://steamcommunity.com/sharedfiles/filedetails/?id=3430172149) | 2 | Compatible | Loads, no errors. |
| [B42] UH-1B Helicopter (Beta) | [3409723807](https://steamcommunity.com/sharedfiles/filedetails/?id=3409723807) | 2 | Compatible | UH-1B Huey (with Aviation Core): ZeD's dashboard and Vehicle tab (33 parts). Its burnt wreck is not a car to sit in (entering it errors in the game's own dashboard code). |
| [B42.21+ MP] - Push Vehicle | [3780639614](https://steamcommunity.com/sharedfiles/filedetails/?id=3780639614) | 2 | Compatible | Loads, no errors. |
| [B42.19] Filibuster Rhymes' Certified Used Cars | [3683878228](https://steamcommunity.com/sharedfiles/filedetails/?id=3683878228) | 2 | Compatible | Two of its cars (llv_89, gto_65): ZeD's dashboard and Vehicle tab (45 / 53 parts). Its title-screen sub-mod loaded too. |
| [B42.20+] Vehicle Aim Roof Fix | [3781616141](https://steamcommunity.com/sharedfiles/filedetails/?id=3781616141) | 2 | Compatible | Loads, no errors. |
| Old moodles +new [B42+] | [3386486141](https://steamcommunity.com/sharedfiles/filedetails/?id=3386486141) | 2 | Compatible | Loads, no errors (moodle icons). |
| True Cargo - Project Full HD | [3806955469](https://steamcommunity.com/sharedfiles/filedetails/?id=3806955469) | 2 | Compatible | Part of it does not show: its cargo view is drawn on the game's inventory window (by reading its code: ISInventoryPage.render). |
| Effortless Towing | [3442862183](https://steamcommunity.com/sharedfiles/filedetails/?id=3442862183) | 2 | Compatible | Loads, no errors. |
| Dash Roamer [B42] | [3775809123](https://steamcommunity.com/sharedfiles/filedetails/?id=3775809123) | 2 | Compatible | DashRoamer and Stellar Command (with its SVU patch): ZeD's dashboard and Vehicle tab (55 parts each). |
| Vehicle Ground Guard [B42 SP + MP] | [3690308807](https://steamcommunity.com/sharedfiles/filedetails/?id=3690308807) | 2 | Compatible | Loads, no errors. |
| NeatUI XP Drop [42.21] | [3760545452](https://steamcommunity.com/sharedfiles/filedetails/?id=3760545452) | 2 | Compatible | Its XP bar shows at the top right (census NeatXPBar 3480,180); ZeD's World window covers its left edge when the Vehicle drawer is open (seen). |
| [B42.20+] Vehicle Enter/Exit Fix | [3785695033](https://steamcommunity.com/sharedfiles/filedetails/?id=3785695033) | 2 | Compatible | Loads, no errors (every car entered and left without error). |
| Legendary Professions and Traits | [3669469283](https://steamcommunity.com/sharedfiles/filedetails/?id=3669469283) | 2 | Compatible | Loads, no errors. |
| Vehicle Military Zones | [3436499337](https://steamcommunity.com/sharedfiles/filedetails/?id=3436499337) | 3 | Compatible | Loads with Yet Another PZ Library, no errors. |
| W900 Semi-Truck [B42] | [3409472393](https://steamcommunity.com/sharedfiles/filedetails/?id=3409472393) | 3 | Compatible | Semi Truck and Semi Truck Box: ZeD's dashboard and Vehicle tab (59 / 55 parts). |
| U.S. M998 Humvee by Papa_Chad | [3554424111](https://steamcommunity.com/sharedfiles/filedetails/?id=3554424111) | 3 | Compatible | Needs Military Tool Kit (2705406713), which its mod.info does not name: without it the Humvee spawns with errors (Vehicles.Create.PC_Default missing) and cannot be driven. With it: ZeD's dashboard and Vehicle tab (54 parts) (rerun). |
| Specific Loot (KI5) | [3457132019](https://steamcommunity.com/sharedfiles/filedetails/?id=3457132019) | 3 | Compatible | Loads with Yet Another PZ Library, no errors. |
| Dynamic Snow for Vanilla Vehicles [B42 MP] | [3781818628](https://steamcommunity.com/sharedfiles/filedetails/?id=3781818628) | 3 | Compatible | Loads, no errors. |

### Group E

Reports: qa/regression/2026-10-26_2037_mods_fullscreen4k.md (11/11 pass); ZeD off: qa/modload/2026-10-26_2048_r3off_console.txt; main menu 20:54; Plain Moodles Redone alone with ZeD's moodle test: 2026-10-26_2044 (2/2)

| Mod | Workshop id | Tier | List | Evidence |
|---|---|---|---|---|
| More Builds | [515555911](https://steamcommunity.com/sharedfiles/filedetails/?id=515555911) | 1 | Works well | Its build window opens from its More Builds row in ZeD's world menu (seen) and works beside ZeD's windows (seen, E_more_builds.jpg). |
| Darker Map | [2939187818](https://steamcommunity.com/sharedfiles/filedetails/?id=2939187818) | 1 | Compatible | Part of it does not show: it darkens the game's map; the game's map key opens ZeD's map pop-out, which has its own styles (Survey, Color, Paper) (seen). |
| Military Grid Reference System For Map Callouts Cause You And Your Friends Get Lost Easily | [2928660831](https://steamcommunity.com/sharedfiles/filedetails/?id=2928660831) | 1 | Compatible | Part of it does not show: its grid is drawn on the game's map, which ZeD's map replaces (expected). |
| Hide Menu Debug + Remove Build Information | [3554048011](https://steamcommunity.com/sharedfiles/filedetails/?id=3554048011) | 1 | Compatible | Part of it does not show: it hides the game's own Debug and build texts; ZeD's main menu keeps its Debug menu under -debug (seen). HideDebugMenu sub-mod. |
| Better Server Settings | [2756434288](https://steamcommunity.com/sharedfiles/filedetails/?id=2756434288) | 1 | Compatible | Loads, no errors (server settings screens not opened). |
| Spawn Selector [B42 Stable] | [3772052709](https://steamcommunity.com/sharedfiles/filedetails/?id=3772052709) | 1 | Compatible | Its Spawn Selector is a spawn place in ZeD's New Game list, with its picture and text (seen); its own map after character creation was not tried. |
| True Moozic B42+  The Music System for Project Zomboid (SP/MP) | [3632610172](https://steamcommunity.com/sharedfiles/filedetails/?id=3632610172) | 1 | Compatible | Loads, no errors; its music rows are in ZeD's world menu (Ban Music List, seen). Part of it may not show: its Hi-Fi window hooks the game's radio window (by reading its code). |
| TwisTonFire - Improved Soundoptions | [3575778063](https://steamcommunity.com/sharedfiles/filedetails/?id=3575778063) | 1 | Compatible | Part of it does not show: it restyles the game's sound options page; ZeD's Options are its own (expected). |
| TwisTonFire - Map Improvements | [3627539752](https://steamcommunity.com/sharedfiles/filedetails/?id=3627539752) | 1 | Compatible | Part of it does not show: its map tools are on the game's map (expected). |
| B42 Native ModOptions Example | [3386860561](https://steamcommunity.com/sharedfiles/filedetails/?id=3386860561) | 1 | Compatible | Loads, no errors; its example options page is in the game's Mod Options (as any mod's options). |
| Workshop Update Checker | [3628835042](https://steamcommunity.com/sharedfiles/filedetails/?id=3628835042) | 1 | Works well | Its Mod Updates button shows at the bottom right of ZeD's main menu (seen, E_main_menu_mod_updates.png). |
| Mod Comparer | [3019672735](https://steamcommunity.com/sharedfiles/filedetails/?id=3019672735) | 1 | Compatible | Loads, no errors; it compares mod lists when a save is continued (not tried). |
| No Welcome Window [B42.21+] | [3389338537](https://steamcommunity.com/sharedfiles/filedetails/?id=3389338537) | 1 | Not needed | ZeD already keeps the welcome and other notes out of the way (Messages); it patches the game's welcome panel (expected). |
| [B42+]L4D2 Zombie Siege Background Main Menu [16:9+21:9] | [3388808256](https://steamcommunity.com/sharedfiles/filedetails/?id=3388808256) | 1 | Compatible | Part of it does not show: ZeD's main menu is its own desk, so the game's menu background it replaces is not seen (seen: same desk as with ZeD alone). 16:9 sub-mod. |
| Cheat Menu: Reloaded [B42 Fixed] | [3683918273](https://steamcommunity.com/sharedfiles/filedetails/?id=3683918273) | 1 | Compatible | Its Cheat Menu: Reloaded rows are in ZeD's world menu (seen). |
| Neat Lockpicking | [3783535220](https://steamcommunity.com/sharedfiles/filedetails/?id=3783535220) | 1 | Compatible | Loads with NeatUI Framework, no errors (lock windows not opened). |
| TwisTonFire - minimap | [3572564421](https://steamcommunity.com/sharedfiles/filedetails/?id=3572564421) | 1 | Compatible | Loads, no errors; its minimap window did not show in this test (census). |
| [B42]Mod Folders | [3779201168](https://steamcommunity.com/sharedfiles/filedetails/?id=3779201168) | 1 | Not needed | ZeD's mod manager does the job (categories, search, profiles); it patches the game's mod screen (expected). |
| Proximity Inventory | [3740165370](https://steamcommunity.com/sharedfiles/filedetails/?id=3740165370) | 1 | Compatible | Tested as a local copy with the id R3_ProximityInventory (its id is the same as two other Proximity Inventory items, and the game loads only one per id). Part of it does not show: its one container goes on the game's loot window (by reading its code). |
| Project Writing [42.21] | [3796402502](https://steamcommunity.com/sharedfiles/filedetails/?id=3796402502) | 1 | Compatible | Part of it does not show: its writing tools are on the game's map (by reading its code: ISWorldMap); its write-note rows come through the item menu. |
| Radio Frequency Manager [B42] | [3659543622](https://steamcommunity.com/sharedfiles/filedetails/?id=3659543622) | 1 | Compatible | Its frequency window opens through its own toggle at the left, clear of ZeD's windows (seen). |
| Retro Dashboard Digitals | [3743082626](https://steamcommunity.com/sharedfiles/filedetails/?id=3743082626) | 1 | Not needed | ZeD replaces the dashboard, including the radio (its digital readouts are for the game's dashboard) (expected; as Realistic Dashboard). |
| Yaki's BarberShop | [2810471370](https://steamcommunity.com/sharedfiles/filedetails/?id=2810471370) | 2 | Compatible | Loads, no errors (barber content). |
| Map Symbols Plus (Hand-drawn) | [3399645148](https://steamcommunity.com/sharedfiles/filedetails/?id=3399645148) | 2 | Compatible | Loads, no errors; its symbols are for the game's map symbol list (not checked in ZeD's mark grid). |
| [B42] Custom Map Labels | [3559737194](https://steamcommunity.com/sharedfiles/filedetails/?id=3559737194) | 2 | Compatible | Loads, no errors; its labels are for the game's map (expected). |
| Map Symbols Plus (Stensil) | [3395592779](https://steamcommunity.com/sharedfiles/filedetails/?id=3395592779) | 2 | Compatible | Loads, no errors; as the Hand-drawn pack. |
| [B42] More Item Information | [3494474677](https://steamcommunity.com/sharedfiles/filedetails/?id=3494474677) | 2 | Compatible | Part of it does not show: its tooltip lines (insulation, wind, material, growing season) show without ZeD and not on ZeD's tooltip (seen, E_more_item_information_tooltip_zed_vs_zed_off.png). ZeD bug 1. |
| [B42.20] Plain Moodles Redone | [3772979228](https://steamcommunity.com/sharedfiles/filedetails/?id=3772979228) | 2 | Works well | Its plain icons and level bars show in ZeD's right-edge column, and its icons in ZeD's row above the belt (level bars not there); no double drawing (ZeD's moodle test 2/2 with it alone, seen). |
| Better Safehouse [B42.20- MP] | [3634569678](https://steamcommunity.com/sharedfiles/filedetails/?id=3634569678) | 2 | Compatible | Multiplayer safehouse screens; loads, no errors in single player. |
| More Maps [B42] | [3390897023](https://steamcommunity.com/sharedfiles/filedetails/?id=3390897023) | 2 | Compatible | Loads, no errors. |
| Voiced Radio and TVs | [2950750587](https://steamcommunity.com/sharedfiles/filedetails/?id=2950750587) | 2 | Compatible | One error of its own at load on 42.21 (ISWeatherChannel.lua:62, Init calls nil), also with ZeD off. Otherwise loads (with Broadcast Voicer). |
| Map All Known Fix [B42] | [3785198639](https://steamcommunity.com/sharedfiles/filedetails/?id=3785198639) | 2 | Compatible | Loads, no errors. |
| [B42] Briefing | [3565244378](https://steamcommunity.com/sharedfiles/filedetails/?id=3565244378) | 2 | Compatible | Loads; its briefing layer is up at game start (census ISBriefingUI) and does not cover ZeD's windows (seen). |
| Better Daily Reports | [3580557206](https://steamcommunity.com/sharedfiles/filedetails/?id=3580557206) | 2 | Compatible | Its daily report window opens by itself at game start, centred, clear of ZeD's windows (seen). |
| TwisTonFire - Quick'n'Auto Mark | [3579410548](https://steamcommunity.com/sharedfiles/filedetails/?id=3579410548) | 2 | Compatible | Loads; its colour dock sits above the belt (census WIMC_ColorDock 1763,2128); the map parts are for the game's map. SP sub-mod. |
| [B42 STABLE] Expanded Professions | [3440958051](https://steamcommunity.com/sharedfiles/filedetails/?id=3440958051) | 2 | Compatible | Its 7 occupations are in ZeD's occupation list (seen: ascetic, convict, hunter, mailman, soldier, paramedic, priest). |
| [B42] Functional TV Movies & Series - Framework | [3685672179](https://steamcommunity.com/sharedfiles/filedetails/?id=3685672179) | 2 | Compatible | Loads, no errors (TV window not opened). |
| GPS Cross-Device - ProjectZomboidMap.com | [3793289804](https://steamcommunity.com/sharedfiles/filedetails/?id=3793289804) | 2 | Compatible | Loads, no errors. |
| Functional Pager - Immersive Map-Wide Communication [B42] | [3744455714](https://steamcommunity.com/sharedfiles/filedetails/?id=3744455714) | 2 | Compatible | Loads, no errors (pager window not opened). |
| [B42.16+] XP Gain Bar v1.4 - DBD | [3656128167](https://steamcommunity.com/sharedfiles/filedetails/?id=3656128167) | 2 | Compatible | Its XP bar shows at the top left (seen). |
| Auto Center Map | [3790912405](https://steamcommunity.com/sharedfiles/filedetails/?id=3790912405) | 2 | Compatible | Part of it does not show: it centres the game's map; the map key opens ZeD's map pop-out (seen). |
| Civil Defense Sirens [B42 SP/MP] | [3750612709](https://steamcommunity.com/sharedfiles/filedetails/?id=3750612709) | 3 | Compatible | Its Civil Defense Sirens row is in ZeD's world menu (seen); some of its option texts have a stray % (game warnings, also with ZeD off). |

### Group F

Reports: qa/regression/2026-10-26_2056_mods_fullscreen4k.md (13/17 pass: the survey's Smart Radial Menu error, Quick Item Action's double-click error, quick chords' ZeD setup check (ZeD bug 4), and Messages' first check, which fails in every run with mods that leave notes); Smart Radial Menu on/off: 2026-10-26_2109 and qa/modload/*_srm_console.txt; quick chords with ZeD alone 2026-10-26_2113, with True Music Jukebox alone 2026-10-26_2116

| Mod | Workshop id | Tier | List | Evidence |
|---|---|---|---|---|
| [B42] Noir's Rifle Slings | [3388107363](https://steamcommunity.com/sharedfiles/filedetails/?id=3388107363) | 1 | Does not work | Errors at load on 42.21: Sling_BodyLocations.lua passes a body location as text where 42.21 wants an ItemBodyLocation ('expected argument of type ItemBodyLocation, got String'), so its sling slot is not made. Not ZeD (a load-time script line). |
| [Deprecated] What can I craft? | [3390169945](https://steamcommunity.com/sharedfiles/filedetails/?id=3390169945) | 1 | Compatible | Deprecated by its maker. Its row shows in ZeD's item menu as the raw key ContextMenu_WhatCanICraft (its text is missing on 42.21, its own). |
| [B42] Simple Belt Flashlight! (Fix for angled flashlight) | [3625933422](https://steamcommunity.com/sharedfiles/filedetails/?id=3625933422) | 1 | Compatible | Loads, no errors (its belt flashlight needs a flashlight on the belt slot; not tried). |
| Quick Item Action | [2642486124](https://steamcommunity.com/sharedfiles/filedetails/?id=2642486124) | 1 | Does not work | Every double-click on an item errors on 42.21 before its action and before the game's own (QuickItemAction.lua:140 calls scriptItem:getTypeString(), which 42.21 removed); seen through ZeD's double-click, the same call the game's list makes. |
| Context Menu Icons | [3634921455](https://steamcommunity.com/sharedfiles/filedetails/?id=3634921455) | 1 | Not needed | ZeD's item menu draws its own icon set; a mod's icon shows only on rows ZeD has none for (as Mutie's). |
| Choose Your Spawn! | [3287958074](https://steamcommunity.com/sharedfiles/filedetails/?id=3287958074) | 1 | Compatible | Loads, no errors (its spawn picker is a spawn place; not checked on ZeD's New Game screen). |
| Easy Set Alarm | [3566088272](https://steamcommunity.com/sharedfiles/filedetails/?id=3566088272) | 1 | Compatible | Loads, no errors (watch alarm not tried). |
| Simple Context Menu Icons | [3634921763](https://steamcommunity.com/sharedfiles/filedetails/?id=3634921763) | 1 | Not needed | Icons for Context Menu Icons; ZeD's menu uses its own icons first (as above). |
| Reorder The Hotbar (B42+ Fixed) | [3663625294](https://steamcommunity.com/sharedfiles/filedetails/?id=3663625294) | 1 | Not needed | ZeD's belt does this job; it reorders the game's hotbar, which ZeD keeps hidden (as Reorder The Hotbar, round 2). |
| The Best Lockpicking [B42.21] [MP Ready] | [3440867775](https://steamcommunity.com/sharedfiles/filedetails/?id=3440867775) | 1 | Compatible | Loads, no errors. Part of it does not show: its hotwire panel hangs on the game's dashboard, which ZeD replaces (by reading its code: ISVehicleDashboard). |
| Clothing Actions - Radial Menu | [2786689104](https://steamcommunity.com/sharedfiles/filedetails/?id=2786689104) | 1 | Compatible | Loads, no errors; its wheel is the game's radial, which ZeD draws as its wheel (ZeD's wheel tests passed with it). Part of it does not show: its D-pad Up wheel (ISDPadWheels.onDisplayUp) gives way to ZeD's D-pad wheels (by reading its code). |
| Cheat Menu Phoenix [B42] [B41 Re-Up] | [3453422228](https://steamcommunity.com/sharedfiles/filedetails/?id=3453422228) | 1 | Compatible | Its Cheat Menu: PX row is in ZeD's world menu (seen). |
| [B42] Intuitive Crafting | [3486217110](https://steamcommunity.com/sharedfiles/filedetails/?id=3486217110) | 1 | Compatible | Part of it does not show: it changes the game's crafting window, which ZeD routes to the World window's Craft tab (expected). |
| Darker Map & Satellite View | [3571222611](https://steamcommunity.com/sharedfiles/filedetails/?id=3571222611) | 1 | Compatible | Part of it does not show: it restyles the game's map; the map key opens ZeD's map pop-out (expected). |
| Smart Radial Menu [B42 Stable] | [3494108029](https://steamcommunity.com/sharedfiles/filedetails/?id=3494108029) | 1 | Does not work | With ZeD on, opening its wheel errors (SRMOverlay.lua:420: its menu's javaObject has no getSliceIndexFromMouse) and no wheel draws; with ZeD off it opens (seen, F_smart_radial_menu_zed_off_vs_on.png). ZeD bug 3. |
| Plysken Attachments Reborn | [3749848348](https://steamcommunity.com/sharedfiles/filedetails/?id=3749848348) | 1 | Compatible | Its rows (Add Attachment Slot, Adjust attachment position) are in ZeD's item menu (seen). |
| [42.13] Zed's Watch Slots | [3630525533](https://steamcommunity.com/sharedfiles/filedetails/?id=3630525533) | 1 | Compatible | A watch worn on its wrist slot shows on ZeD's belt (seen). |
| Blacklist & Proximity Inventory | [3498294068](https://steamcommunity.com/sharedfiles/filedetails/?id=3498294068) | 1 | Compatible | Part of it does not show: its container and blacklist go on the game's loot window (by reading its code). Inventory + Blacklist sub-mods. |
| Context Menu Cleanup | [3780688809](https://steamcommunity.com/sharedfiles/filedetails/?id=3780688809) | 1 | Compatible | Loads, no errors. |
| Hands: Stow, Equip, Place [B42] | [3786918614](https://steamcommunity.com/sharedfiles/filedetails/?id=3786918614) | 1 | Compatible | Loads, no errors. |
| Auto Tailoring | [3388183573](https://steamcommunity.com/sharedfiles/filedetails/?id=3388183573) | 2 | Compatible | Its Auto Rip rows are in ZeD's item menu (seen). Part of it does not show: its buttons on the game's protection page (by reading its code: ISCharacterProtection). |
| True Action Dancing B42 | [3650071729](https://steamcommunity.com/sharedfiles/filedetails/?id=3650071729) | 2 | Compatible | Loads, no errors. |
| Auto Reload | [3389448389](https://steamcommunity.com/sharedfiles/filedetails/?id=3389448389) | 2 | Compatible | Loads, no errors; its reload rows come through the game's item menu. |
| Auto Cook | [3388721641](https://steamcommunity.com/sharedfiles/filedetails/?id=3388721641) | 2 | Compatible | Loads, no errors. |
| Place Anywhere | [3613917826](https://steamcommunity.com/sharedfiles/filedetails/?id=3613917826) | 2 | Compatible | Loads, no errors. |
| Washing Menus Improved [B42] | [3460812542](https://steamcommunity.com/sharedfiles/filedetails/?id=3460812542) | 2 | Compatible | Loads, no errors. |
| [B42][MP]MoreMenuOptions | [3636171151](https://steamcommunity.com/sharedfiles/filedetails/?id=3636171151) | 2 | Compatible | Loads, no errors. |
| True Music Jukebox 42 | [3398874593](https://steamcommunity.com/sharedfiles/filedetails/?id=3398874593) | 2 | Compatible | Loads, no errors; but its options page, added the old way, empties ZeD setup of ZeD's own options (ZeD bug 4, F_zed_setup_loses_zed_options_with_true_music_jukebox.jpg). Its jukebox not tried. |
| [B42] [MP] Quick Remove Broken Glass | [3669016488](https://steamcommunity.com/sharedfiles/filedetails/?id=3669016488) | 2 | Compatible | Loads, no errors. |
| [B41 & B42] Rope Towing | [3261334016](https://steamcommunity.com/sharedfiles/filedetails/?id=3261334016) | 2 | Compatible | Loads, no errors. |
| True Music Radio 42 | [3631572046](https://steamcommunity.com/sharedfiles/filedetails/?id=3631572046) | 2 | Compatible | Loads, no errors. TrueMusicRadio42 sub-mod. |
| [42] Rip All Button In context Menu | [3641027178](https://steamcommunity.com/sharedfiles/filedetails/?id=3641027178) | 2 | Compatible | Its Rip Clothing row is in ZeD's item menu (seen). |
| Devcatt's Furry Moodles [Build 42+] | [3392964216](https://steamcommunity.com/sharedfiles/filedetails/?id=3392964216) | 2 | Compatible | Loads, no errors (moodle icons). |
| Dismantle All at Once | [3761218629](https://steamcommunity.com/sharedfiles/filedetails/?id=3761218629) | 2 | Compatible | Loads, no errors; part of it hangs on the game's list right-click (by reading its code: ISInventoryPane.onRightMouseUp). |
| Crafting XP Display | [3428715523](https://steamcommunity.com/sharedfiles/filedetails/?id=3428715523) | 2 | Compatible | Loads, no errors. |
| [B42.20] Auto All - Cook, Medicine, Read, Clean, Rip, Tailoring, Mechanics, Exercise, Reload, Open & Dismantle | [3777237134](https://steamcommunity.com/sharedfiles/filedetails/?id=3777237134) | 2 | Compatible | Its rows (Read Everything Automatically, Auto Rip, Train Tailoring) are in ZeD's item menu (seen). |
| Better Corpse Burning | [3790089095](https://steamcommunity.com/sharedfiles/filedetails/?id=3790089095) | 2 | Compatible | Loads, no errors. |
| Hide Equipped Items | [3600186927](https://steamcommunity.com/sharedfiles/filedetails/?id=3600186927) | 2 | Compatible | Its Hide Equipped Items row is in ZeD's item menu (seen); what it hides is the game's list (expected). |
| Two Weapons on Back [42.21] | [3778319798](https://steamcommunity.com/sharedfiles/filedetails/?id=3778319798) | 2 | Compatible | Loads, no errors. |
| [B42]Whose Key Is This? | [3784348098](https://steamcommunity.com/sharedfiles/filedetails/?id=3784348098) | 2 | Compatible | Loads, no errors; its key map overlay is for the game's map (by reading its code). |
| Balaclava Slot | [3789234614](https://steamcommunity.com/sharedfiles/filedetails/?id=3789234614) | 2 | Compatible | Loads, no errors. |
| Area Tasks - Select an area for vanilla tasks [B42] | [3793163745](https://steamcommunity.com/sharedfiles/filedetails/?id=3793163745) | 2 | Compatible | Its Area Tasks row is in ZeD's world menu (seen). |

### Group G

Reports: qa/regression/2026-10-26_2121_mods_fullscreen4k.md (9/11 pass: the survey's Spear Traps errors, and Messages' first check, which fails in every run with mods that leave notes)

| Mod | Workshop id | Tier | List | Evidence |
|---|---|---|---|---|
| [B42]Simple sling mod | [2868394326](https://steamcommunity.com/sharedfiles/filedetails/?id=2868394326) | 1 | Compatible | Loads, no errors. |
| Equipment UI – STABLE + | [3682936016](https://steamcommunity.com/sharedfiles/filedetails/?id=3682936016) | 1 | Not needed | ZeD's Equip tab has a paper doll (as Equipment UI, round 2). Tested its standalone EQUIPMENT_UI_B42 sub-mod (its other sub-mod shares the id of the tested Inventory Tetris one). |
| [B42.20/B42.21] Simple Belt Flashlight+ (Better Flashlights Compatible) | [3778709615](https://steamcommunity.com/sharedfiles/filedetails/?id=3778709615) | 1 | Compatible | Tested as a local copy with the id R3_FixedLightOnBeltAF (same id as Simple Belt Flashlight 3625933422, group F). Loads, no errors. |
| Attachments UI [B42] | [3816324722](https://steamcommunity.com/sharedfiles/filedetails/?id=3816324722) | 1 | Compatible | Loads, no errors; its workbench did not open from the test's call (not seen). |
| MinimalHotbar | [3688576740](https://steamcommunity.com/sharedfiles/filedetails/?id=3688576740) | 1 | Not needed | ZeD's belt replaces the game's hotbar it restyles (expected). |
| Palm Pilot | [3776531193](https://steamcommunity.com/sharedfiles/filedetails/?id=3776531193) | 1 | Works well | Its Palm Pilot screen opens through its own open, beside ZeD's windows (seen, G_mod_windows.jpg). |
| Sandbox Control - Cheat & Creative Menu [B42.21] | [3825312974](https://steamcommunity.com/sharedfiles/filedetails/?id=3825312974) | 1 | Compatible | Its window opens through its own toggle (pauses the game, as it does without ZeD) and its rows are in ZeD's item and world menus (seen). |
| Night Vision Chucked | [2842179206](https://steamcommunity.com/sharedfiles/filedetails/?id=2842179206) | 2 | Compatible | Loads (with errorMagnifier), no errors (goggles not worn). |
| [B42.20] Carry Visible Items In Hands [WIP] | [3749026793](https://steamcommunity.com/sharedfiles/filedetails/?id=3749026793) | 2 | Compatible | Loads, no errors. |
| Advanced Trajectory's Realistic Overhaul | [3036878362](https://steamcommunity.com/sharedfiles/filedetails/?id=3036878362) | 2 | Compatible | Loads, no errors. |
| Common Sense [B42.20+] | [3750253491](https://steamcommunity.com/sharedfiles/filedetails/?id=3750253491) | 2 | Compatible | Loads, no errors. |
| Skullys Lowerback Dufflebags, Chest Rigs + Fannypack, Container Rebalance [42.20] | [3698401476](https://steamcommunity.com/sharedfiles/filedetails/?id=3698401476) | 2 | Compatible | Loads, no errors. Duffles and Rigs + Container Rebalance sub-mods. |
| HEF - Helicopter Event Framework | [3672792485](https://steamcommunity.com/sharedfiles/filedetails/?id=3672792485) | 2 | Compatible | Loads, no errors. |
| Ping Items! Friends! 42.20 MP Official | [3776262249](https://steamcommunity.com/sharedfiles/filedetails/?id=3776262249) | 2 | Compatible | Loads, no errors. Default wheel sub-mod. |
| Inspect Items Framework | [3617732907](https://steamcommunity.com/sharedfiles/filedetails/?id=3617732907) | 2 | Works well | Its inspect window opens on a rifle through its own open, centred, clear of ZeD's windows (seen); its Inspect item row is in ZeD's item menu. |
| [B42] MandoDB - Old Moodles Icons + Redrawn | [3386409674](https://steamcommunity.com/sharedfiles/filedetails/?id=3386409674) | 2 | Compatible | Loads, no errors (moodle icons). |
| Tooltiplib - Tooltip Framework for Modders | [3694097672](https://steamcommunity.com/sharedfiles/filedetails/?id=3694097672) | 2 | Compatible | Loads, no errors. |
| Bushcraft Gear - Tools [B41/B42] | [2423906082](https://steamcommunity.com/sharedfiles/filedetails/?id=2423906082) | 3 | Compatible | Loads, no errors. |
| Bushcraft Gear - Rare Weapons [B41/B42] | [2432621382](https://steamcommunity.com/sharedfiles/filedetails/?id=2432621382) | 3 | Compatible | Loads, no errors. |
| Undead Survivor [B41/B42] | [2713921292](https://steamcommunity.com/sharedfiles/filedetails/?id=2713921292) | 3 | Compatible | Loads, no errors. |
| Military Ponchos [B42] | [2629286881](https://steamcommunity.com/sharedfiles/filedetails/?id=2629286881) | 3 | Compatible | Loads, no errors. |
| [HOTFIX for B42.13] Tactical Weapons | [2324223029](https://steamcommunity.com/sharedfiles/filedetails/?id=2324223029) | 3 | Compatible | Loads, no errors. |
| Spear Traps | [2640351732](https://steamcommunity.com/sharedfiles/filedetails/?id=2640351732) | 3 | Does not work | Every right-click on the world errors on 42.21, once per item in the inventory (SpearTraps_ContextMenu.lua:97 calls getScriptItem():getCategories(), which 42.21 removed). Seen through ZeD's world menu, which calls the game's own createMenu. |
| KATTAJ1 Military Pack [B41/B42MP] | [3470426196](https://steamcommunity.com/sharedfiles/filedetails/?id=3470426196) | 3 | Compatible | Loads with KATTAJ1 Clothes Core, no errors. |
| [42.21MP] GoM - Guns of Marz | [3722134990](https://steamcommunity.com/sharedfiles/filedetails/?id=3722134990) | 3 | Compatible | Loads with Gunworks Framework, no errors (its Java tracer add-on left out). |
| [ Reworked] Madax Weapon Pack - B42 | [2732407704](https://steamcommunity.com/sharedfiles/filedetails/?id=2732407704) | 3 | Compatible | Loads, no errors. |
| [B42] Carry visible generators | [3390487814](https://steamcommunity.com/sharedfiles/filedetails/?id=3390487814) | 3 | Compatible | Loads, no errors. |
| Vanilla Outfits Expanded | [3783094058](https://steamcommunity.com/sharedfiles/filedetails/?id=3783094058) | 3 | Compatible | Loads, no errors. |
| Buttstroke / Gun Stock Attack [B42] | [3394044313](https://steamcommunity.com/sharedfiles/filedetails/?id=3394044313) | 3 | Compatible | Loads, no errors. |
| Legendary Backpacks | [3538353228](https://steamcommunity.com/sharedfiles/filedetails/?id=3538353228) | 3 | Compatible | Loads, no errors. |
| Escape From Tarkov Backpacks [B42.20] | [3432928943](https://steamcommunity.com/sharedfiles/filedetails/?id=3432928943) | 3 | Compatible | Loads, no errors. |
| They Knew [B42] | [3387110070](https://steamcommunity.com/sharedfiles/filedetails/?id=3387110070) | 3 | Compatible | One error of its own at load on 42.21: TheyKnew_BodyLocations.lua passes a body location as text ('expected argument of type ItemBodyLocation'). Not ZeD. |
| Vanilla Clothing Expansion | [3421271152](https://steamcommunity.com/sharedfiles/filedetails/?id=3421271152) | 3 | Compatible | Loads, no errors. |
| [B42.21] Better Flashlights | [3420478458](https://steamcommunity.com/sharedfiles/filedetails/?id=3420478458) | 3 | Compatible | Loads, no errors. |
| [42.20.4MP] Vanilla Weapons PLUS - Gunworks Edition | [3773834525](https://steamcommunity.com/sharedfiles/filedetails/?id=3773834525) | 3 | Compatible | Loads, no errors. |
| Run and Reload [B42] | [3397207461](https://steamcommunity.com/sharedfiles/filedetails/?id=3397207461) | 3 | Compatible | Loads, no errors. |
| Ammo Loot Drop / Zombies Drop Ammo B42 | [3389050623](https://steamcommunity.com/sharedfiles/filedetails/?id=3389050623) | 3 | Compatible | Loads, no errors. Base sub-mod. |
| [B42] Vanilla Firearms Expansion [CLASSIC] | [3761077099](https://steamcommunity.com/sharedfiles/filedetails/?id=3761077099) | 3 | Compatible | Loads, no errors. |
| Lean & Lie | [3652012357](https://steamcommunity.com/sharedfiles/filedetails/?id=3652012357) | 3 | Compatible | Loads with TchernoLib, no errors. |
| Long Term Preservation [42.20] | [3774789651](https://steamcommunity.com/sharedfiles/filedetails/?id=3774789651) | 3 | Compatible | Loads, no errors. |
| Brita Weapon and Armor B42 Unified Compatibility Port | [3777433827](https://steamcommunity.com/sharedfiles/filedetails/?id=3777433827) | 3 | Compatible | Its two belt slots show on ZeD's belt (slots 5 and 6), named by their raw ids, which run out of the box (ZeD bug 5, G_belt_mod_slot_names_overflow.png). |

### Group H

Reports: qa/regression/2026-10-26_2225_mods_fullscreen4k.md (without Horde Night: 8/11 pass; Messages and one moodle-note check fail because of Neat Rocco's UI); the first run 2026-10-26_2130 closed the game (Horde Night); ZeD off: qa/modload/2026-10-26_2133_r3off_console.txt and the *_idle_console.txt bisect runs; Messages with Neat Rocco's UI alone: 2026-10-26_2245

| Mod | Workshop id | Tier | List | Evidence |
|---|---|---|---|---|
| Mutie's Context Menu Icons | [3101668503](https://steamcommunity.com/sharedfiles/filedetails/?id=3101668503) | 1 | Not needed | ZeD's item menu draws its own icon set; a mod's icon shows only on rows ZeD has none for. |
| Neat Rocco's UI [B42] | [3723726293](https://steamcommunity.com/sharedfiles/filedetails/?id=3723726293) | 1 | Not needed | Both restyle the whole interface: use one. With both on, the game's character window toggle still lands on ZeD's tabs (seen), but its dialogs take the place of ZeD's: other mods' notes are no longer kept in ZeD's Messages and stay on screen (seen, H_mod_notes_on_screen_with_neat_rocco.jpg; ZeD's Messages test fails 12 checks with this mod alone). It swaps ISModalDialog.new and ISModalRichText.new for its own after ZeD has set its hooks (NR_Patch.lua, NR_MakePatch). |
| Inventory Tetris - Grid Based Items and Equipment Overhaul | [3775513231](https://steamcommunity.com/sharedfiles/filedetails/?id=3775513231) | 1 | Not needed | A whole-inventory overhaul on the game's inventory and loot windows, which ZeD replaces: its grid never shows (expected; as Inventory Tetris, round 1). Tested as a local copy with the id R3_INVENTORY_TETRIS (same id as the tested Inventory Tetris). Its grid errors every frame when the game's inventory comes back for a moment (ZeD's safe mode switched on and off in the test), not in normal play. |
| Equipment UI - Paper Doll Equipment Interface SP/MP [B42.20+] | [3780682550](https://steamcommunity.com/sharedfiles/filedetails/?id=3780682550) | 1 | Not needed | ZeD's Equip tab has a paper doll (as Equipment UI, round 2). |
| Second Back Slot [B42.20] | [3751668602](https://steamcommunity.com/sharedfiles/filedetails/?id=3751668602) | 1 | Compatible | Loads, no errors. |
| N3WO Map Overhaul [B42] | [3785033563](https://steamcommunity.com/sharedfiles/filedetails/?id=3785033563) | 1 | Compatible | Part of it does not show: it changes the game's map; the map key opens ZeD's map pop-out (seen). |
| Horde Night | [2714850307](https://steamcommunity.com/sharedfiles/filedetails/?id=2714850307) | 2 | Does not work | Closes the game on 42.21 as the save loads (StackOverflowError in KahluaTableImpl.save, saving its own data), also with ZeD off and with it alone (seen, bisect runs). |
| Video Game Consoles | [2831786301](https://steamcommunity.com/sharedfiles/filedetails/?id=2831786301) | 2 | Compatible | Loads, no errors. |
| Pillow's Random Spawns [B42] | [1911132112](https://steamcommunity.com/sharedfiles/filedetails/?id=1911132112) | 2 | Compatible | Loads, no errors (spawn choices not checked on ZeD's New Game screen). ManySpawns sub-mod. |
| [B42MP/B41]Surviving Through Seasons | [2753086629](https://steamcommunity.com/sharedfiles/filedetails/?id=2753086629) | 2 | Compatible | Loads, no errors. |
| Ladders?! B42.20 SP/MP (Unofficial) | [3629835761](https://steamcommunity.com/sharedfiles/filedetails/?id=3629835761) | 2 | Compatible | Loads, no errors. Ladders4220 sub-mod. |
| [KYR] Real Weather Mod | [3051276857](https://steamcommunity.com/sharedfiles/filedetails/?id=3051276857) | 2 | Compatible | Loads, no errors. |
| [B41/B42] Cryogenic Winter +Easy/Hard Modes (SP/MP) | [2210760610](https://steamcommunity.com/sharedfiles/filedetails/?id=2210760610) | 2 | Compatible | Loads, no errors. Normal mode sub-mod. |
| [B42] Survival | [3402516345](https://steamcommunity.com/sharedfiles/filedetails/?id=3402516345) | 2 | Compatible | Loads, no errors. |
| [B42] Bandits Creator | [3469292499](https://steamcommunity.com/sharedfiles/filedetails/?id=3469292499) | 2 | Compatible | Its Bandit Creator and Spawn Bandit Clan rows are in ZeD's world menu (seen). |
| Plysken Solar Revolution | [3725311427](https://steamcommunity.com/sharedfiles/filedetails/?id=3725311427) | 2 | Compatible | Loads, no errors; part of it draws on the game's inventory list (by reading its code: ISInventoryPane.drawItemDetails). |
| Immersive Blackouts [B42MP] | [3607686447](https://steamcommunity.com/sharedfiles/filedetails/?id=3607686447) | 2 | Compatible | Loads, no errors. |
| SaucedCarts - Pushable Carts | [3651954650](https://steamcommunity.com/sharedfiles/filedetails/?id=3651954650) | 2 | Compatible | Loads, no errors. Part of it does not show: its cart handling patches the game's inventory and loot windows (by reading its code). |
| LG Extended Electricity | [3779562002](https://steamcommunity.com/sharedfiles/filedetails/?id=3779562002) | 2 | Compatible | Loads, no errors. |
| ImmersiveSolarArrays [42.16+] | [3647117173](https://steamcommunity.com/sharedfiles/filedetails/?id=3647117173) | 2 | Compatible | Loads, no errors; part of it draws on the game's inventory list (by reading its code). |
| Playable Minigames (Previously Playable Pool) | [3716934959](https://steamcommunity.com/sharedfiles/filedetails/?id=3716934959) | 2 | Compatible | Its Debug Minigames row is in ZeD's world menu (seen). |
| Over the Shoulder | [3808805481](https://steamcommunity.com/sharedfiles/filedetails/?id=3808805481) | 2 | Compatible | Loads, no errors. Main mod only (its patch sub-mods are for mods not on). |
| Stay With Me [B42 - NPC Companion] | [3800989007](https://steamcommunity.com/sharedfiles/filedetails/?id=3800989007) | 2 | Compatible | Loads, no errors; its first-start note (zombie spawning off in this world) is one of the notes ZeD's Messages keeps. |
| Roaming Survivors | [3797874733](https://steamcommunity.com/sharedfiles/filedetails/?id=3797874733) | 2 | Compatible | Its rows (Survivors, Reputation, Quest journal, Roaming Survivors) are in ZeD's world menu (seen); it seeded 120 survivors with no errors. |
| Sleep with Friends v2.1 | [2686624983](https://steamcommunity.com/sharedfiles/filedetails/?id=2686624983) | 3 | Compatible | Loads, no errors. |
| [B42] Drag Bodies Faster | [3393821407](https://steamcommunity.com/sharedfiles/filedetails/?id=3393821407) | 3 | Compatible | Loads, no errors. 50% sub-mod. |
| Long Term Preservation [B42.13] | [3406392630](https://steamcommunity.com/sharedfiles/filedetails/?id=3406392630) | 3 | Compatible | Loads, no errors. |
| Slower Sprinters \ B42 | [2716710487](https://steamcommunity.com/sharedfiles/filedetails/?id=2716710487) | 3 | Compatible | Loads, no errors. 35% sub-mod. |
| Everything Has a Name | [2867163008](https://steamcommunity.com/sharedfiles/filedetails/?id=2867163008) | 3 | Compatible | Its Rename Stack row is in ZeD's item menu (seen). |
| Trees Have Loot [B41 &  B42] | [2951270166](https://steamcommunity.com/sharedfiles/filedetails/?id=2951270166) | 3 | Compatible | Loads, no errors. |
| Skully's Zombie Collision [B42.20+] | [3778511497](https://steamcommunity.com/sharedfiles/filedetails/?id=3778511497) | 3 | Compatible | Loads, no errors. |
| ModernFirearmsSystem 42.21 (SP/MP) | [3633421539](https://steamcommunity.com/sharedfiles/filedetails/?id=3633421539) | 3 | Compatible | Loads, no errors (its UniqueSounds patched 54 guns). Base sub-mod. |
| CDDA Zombies | [2749928925](https://steamcommunity.com/sharedfiles/filedetails/?id=2749928925) | 3 | Compatible | Loads, no errors. Base sub-mod. |
| [B42] Madax Weapons Pack - Fixed 42.21 | [3747202678](https://steamcommunity.com/sharedfiles/filedetails/?id=3747202678) | 3 | Compatible | Loads, no errors. |
| [B42.20+ MP] Skateboard! | [3456675747](https://steamcommunity.com/sharedfiles/filedetails/?id=3456675747) | 3 | Compatible | Loads, no errors. |
| CD: Rottweiler | [3762296152](https://steamcommunity.com/sharedfiles/filedetails/?id=3762296152) | 3 | Compatible | Loads with Companion Dogs, no errors. |
| Brita's Armor Pack B42.20+ / Standalone Armor Port & Multilingual Fixes | [3780298456](https://steamcommunity.com/sharedfiles/filedetails/?id=3780298456) | 3 | Compatible | Loads, no errors. Part of it does not show: its armour tooltip lines wrap ISToolTipInv.render at load (ZeD bug 1, by reading its code). |
| Zombie Dismemberment | [3811483602](https://steamcommunity.com/sharedfiles/filedetails/?id=3811483602) | 3 | Compatible | Loads, no errors. |
| Blood Pools & Footprints [B42.20+] | [3784951301](https://steamcommunity.com/sharedfiles/filedetails/?id=3784951301) | 3 | Compatible | Loads, no errors. |
| Proper Ragdolls | [3821280085](https://steamcommunity.com/sharedfiles/filedetails/?id=3821280085) | 3 | Compatible | Loads, no errors. |
| Wash Or Rot [B42 SP/MP] | [3674907249](https://steamcommunity.com/sharedfiles/filedetails/?id=3674907249) | 3 | Compatible | Loads with Moodle Framework, no errors. |

## Not tested, and why

| Group | Mod | Workshop id | Why |
|---|---|---|---|
| A | Viperel's Vehicle Spare Parts | [2712632417](https://steamcommunity.com/sharedfiles/filedetails/?id=2712632417) | Its folder on disk has the Build 41 layout only (no 42 or common folder): the game does not list it (getModInfoByID nil at the main menu). |
| D | Better Car Physics | [2909035179](https://steamcommunity.com/sharedfiles/filedetails/?id=2909035179) | Ships Java class files (CarController*.class): left out by rule. |
| H | Bandits Extra Options | [3412682512](https://steamcommunity.com/sharedfiles/filedetails/?id=3412682512) | Its mod.info requires the mod id Bandits; the B42 Bandits NPC is Bandits2, and no Bandits id is on disk (missing requirement). |

## ZeD bugs found

### 1. ZeD's item tooltip drops the lines other mods add to the game's tooltip

- **File:** `42/media/lua/client/ZeD/Overrides/Tooltip.lua`, `applyTooltipOverrides` (run on `OnGameBoot`). It keeps whatever `ISToolTipInv.render` is at that moment as "vanilla" (`V.invRender`), then replaces `ISToolTipInv:render` with ZeD's own drawing, which calls only `self.item:DoTooltip(self.tooltip)`. The kept function is called only in safe mode.
- **Effect:** a mod that wraps `ISToolTipInv.render` when its file loads (before `OnGameBoot`) to draw extra lines has its wrapper skipped. Seen with Starlit Library's tooltip lines (Show Sowing Season In Seed Tooltip, 3404461962): the seed packet tooltip has 4 lines under ZeD and 8 in ZeD's safe mode. Same pattern, by reading their code: Better Clothing Info Comparison (3036830549, `bcic_Tooltip.lua:228`), This Is Me (3806020504, `TIMReadUIPatch.lua:45`), Brita's Armor Pack B42 (3780298456). Confirmed with ZeD fully off for [B42] More Item Information (3494474677, `ItemInfo.lua:754`, group E): a formal shirt's tooltip has Insulation 25 (+25), Wind resistance 15 (+15) and Material: Cotton, and a seed packet Growing Seasons, without ZeD; none of them under ZeD (`E_more_item_information_tooltip_zed_vs_zed_off.png`, `zedqa_off_run.ps1` with `zedqa_r3_off.lua`). Mods that wrap it at `OnGameStart` (after ZeD), such as Show VHS skills in tooltip, keep working.
- **Steps:** `zedqa_mods_run.ps1 -ModList tools/qa/compat_r3_A_mods.txt -Mode fullscreen4k -Manifest tools/qa/compat_r3_A.txt`; `zedqa_r3_A.lua` gives a Carrot seed packet and draws its `ISToolTipInv` at 900,300, once normally and once with ZeD's safe mode option on.
- **Evidence:** `ZeDUI/qa/compat_round3/A_seed_tooltip_zed_vs_safe.png` (left ZeD 202x79, right safe mode 252x144: Sowing Season, Optimal / Risky Sowing Months, Minimum Water Level); report `qa/regression/2026-10-26_1932_mods_fullscreen4k.md` (`tip seed zed 202x79`, `tip seed safe 252x144`).
- **Fix idea (not done):** call the kept function for the content (or call the previous `render` with ZeD's frame drawn first), the way the other ZeD overrides chain to what was there before.

### 2. Main menu: the desktop's icons show through ZeD's Mods window (seen with ZeD alone too)

- **Where:** ZeD's main menu (the monitor), Mods window opened through `MM.openMods()` (`ZeD_MainMenuMods.lua`). The desktop icons behind the window (Project Zomboid, New game, Load game, Join a server, Options, Mods, Mod Uploader) are drawn faintly over the window's right-hand detail pane, at 4K, scale 1.75.
- **Not caused by a mod:** the same with ZeD as the only mod (baseline run of `zedqa_r3_menu.lua` with `mods/default.txt` = ZeD_UI only).
- **Steps:** `zedqa_menu_mods_run.ps1 -ModList <ZeD only> -Script tools/qa/zedqa_r3_menu.lua -Tag r3m`; picture `zqa_r3m_2_mods.png`.
- **Evidence:** `ZeDUI/qa/compat_round3/ZeD_mods_window_desktop_icons_show_through_noMods.png` (crop of the right pane), `B_zed_mods_window_with_mod_manager.jpg` (same with group B's mods).
- May be meant (a see-through window); if not, the desktop icons are drawn over, or the pane is not opaque.

### 3. Smart Radial Menu errors and draws no wheel with ZeD (ZeD's wheel element has none of the engine RadialMenu's methods)

- **File:** `42/media/lua/client/ZeD/Overrides/Wheels.lua` (HOOK_MAP row 29): `ISRadialMenu.instantiate` makes a plain element instead of the engine's `RadialMenu`, so `getPlayerRadialMenu(n).javaObject` has none of the Java methods. Smart Radial Menu (3494108029) calls `self.menu.javaObject:getSliceIndexFromMouse(x, y)` (`SRMOverlay.lua:420`, from `display` -> `updateSelectedSlice`), which errors ("Object tried to call nil in getSliceTooltipUnderMouseFocus") when its menu is shown; its overlay never draws, and only loose slice icons show round the character.
- **Not the mod alone:** with ZeD off and the same mod (`zedqa_off_run.ps1 -ModList tools/qa/compat_r3_srm_mods.txt -Script tools/qa/zedqa_r3_srm.lua -Tag srm`) its wheel opens, no error. With ZeD on (`zedqa_mods_run.ps1 ... -Manifest tools/qa/compat_r3_srm.txt`, report `qa/regression/2026-10-26_2109_mods_fullscreen4k.md`) it errors.
- **Evidence:** `ZeDUI/qa/compat_round3/F_smart_radial_menu_zed_off_vs_on.png` (left ZeD off: its wheel; right ZeD on: scattered icons).
- **Fix idea (not done):** give ZeD's wheel element the engine RadialMenu methods mods call (`getSliceIndexFromMouse`, `getSliceIndexFromJoypad`, and the like, through `ZeD.Wheel.sliceFromMouse / sliceFromJoypad`), or let a wheel a mod draws itself stay the engine's.

### 4. ZeD setup loses all of ZeD's own options when a mod adds its own page to the game's Options

- **File:** `42/media/lua/client/ZeD/ZeD_MainMenuOptionGroups.lua`, `G.build`: each of the game's option pages is filed under `pageId(p.raw) or "mods"`, so a page a mod adds with `MainOptions:addPage` (an unknown title) is also filed as `"mods"`; when it comes after the real Mods page it replaces `byPage.mods`. ZeD setup then looks for ZeD's own ModOptions controls in `byPage.mods` (`local mods = byPage.mods or {}`, about line 264) and finds none.
- **Effect:** ZeD setup (Options > ZeD setup, in game and at the main menu) shows only the quick-action chord rows and "Game settings ZeD uses": Look (theme, accent, text size, UI scale), Windows, HUD (moodle place, watch), Controls, Put things back, Messages, Sandbox and Troubleshooting (safe mode) are all gone.
- **Found with:** True Music Jukebox 42 (3398874593), which adds its own page in `MainOptions:create` (`Jukebox/Options.lua:53`). Any mod that adds an options page the old way can do it.
- **Steps:** `zedqa_mods_run.ps1 -ModList <TrueMusicJukebox> -Mode fullscreen4k -Manifest <zedqa_prelude.lua, zedqa_quick_chords.lua>`: `ZEDQA qc FAIL ZeD setup has Put things back` (report `qa/regression/2026-10-26_2116_mods_fullscreen4k.md`); the same test with ZeD alone passes (`qa/regression/2026-10-26_2113_fullscreen4k.md`). First seen in group F's run (`2026-10-26_2056_mods_fullscreen4k.md`).
- **Evidence:** `ZeDUI/qa/compat_round3/F_zed_setup_loses_zed_options_with_true_music_jukebox.jpg` (ZeD setup opens on Quick actions; nothing above it).
- **Fix idea (not done):** file only the page whose title is the Mods page as `"mods"` (give unknown pages their own id), or find ZeD's controls across every page.

### 5. The belt names a mod's hotbar slot by its raw id, and the name runs out of its box

- **File:** `42/media/lua/client/ZeD/ZeD_Belt.lua`, `B.shortName` (about line 355): a slot type ZeD has no short word for falls back to `string.upper(slotType)`, not to the slot's own name (the game shows `slot.name`, translated by the mod).
- **Seen with:** Brita Weapon and Armor B42 Unified Compatibility Port (3777433827): its two belt slots read BRITABELTFRONT and BRITABELTBACK, wider than the slot box, the letters running over the next box (slots 5 and 6 on the belt).
- **Steps:** group G's run (`zedqa_mods_run.ps1 -ModList tools/qa/compat_r3_G_mods.txt -Mode fullscreen4k -Manifest tools/qa/compat_r3_G.txt`), picture `zqa_r3G_12_belt.png`; report `qa/regression/2026-10-26_2121_mods_fullscreen4k.md`.
- **Evidence:** `ZeDUI/qa/compat_round3/G_belt_mod_slot_names_overflow.png`.
- **Fix idea (not done):** fall back to the slot's own name (`slot.name`, through getText), and fit or clip the label to the box.

### 6. (Clash, for a decision) A mod that swaps a dialog's constructor after ZeD bypasses ZeD's prompts and Messages

- **What:** ZeD's prompt override (`Overrides/Prompts.lua`) and Messages catch other mods' notes through the game's dialog classes (`ISModalDialog`, `ISModalRichText`, ...). Neat Rocco's UI (3723726293) keeps the constructor it found when its files loaded (before ZeD's) and, from its options callback, sets `ISModalDialog.new` / `ISModalRichText.new` to its own (`NR_Patch.lua`, `NR_MakePatch`), so ZeD's hook is skipped: mods' notes stay on screen (Stay With Me's and Bandits' first-start notes over the game, seen), are not kept in Messages, and ZeD's dialog styling is not used.
- **Steps:** `zedqa_mods_run.ps1 -ModList <NeatUI_Framework, Neat_Rocco> -Manifest <zedqa_prelude.lua, zedqa_messages.lua>`: 12 Messages checks fail (`qa/regression/2026-10-26_2245_mods_fullscreen4k.md`); they pass with ZeD alone and in groups B, C, E.
- **Evidence:** `ZeDUI/qa/compat_round3/H_mod_notes_on_screen_with_neat_rocco.jpg`.
- **Note:** two whole-UI mods meeting; listed as Not needed (use one). A fix on ZeD's side would be to wrap whatever `new` is current when a dialog is shown, or re-check its hook after the game starts.
