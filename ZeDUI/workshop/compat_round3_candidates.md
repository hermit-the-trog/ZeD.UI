# Compatibility round 3: popular Build 42 mods ZeD has not been tested with

Survey date: Oct 26 2026. Read-only: no game launch, no edit to any mod or to ZeD. Nothing here is a test result.

## How this list was made

- "Done" list: every Workshop id in `workshop/steam_threads/` (all compatibility posts, credits, the vehicle round, the mod-list and manifest files there), `workshop/compat_round2_tab_survey.md` and `tools/qa/` (mod lists, manifests, scripts). 271 ids. Mod-id lists (traits, hair, map mods) were matched to their Workshop folders on disk; they added nothing new.
- Workshop pages read: Most Subscribed (all time) top 360; Most Subscribed with the Build 42 tag top 900; Most Popular over the last year top 600; plus about 65 text searches for well-known mods and for UI words (hotbar, moodle, minimap, radio, main menu, context menu, inventory, loot window and so on), and two Build 42 "best mods" guides. Subscriber counts are lifetime counts from Steam on Oct 26 2026.
- B42 evidence: "tagged B42" = the Build 42 tag; "description says B42" = no tag (or B41 tag only) but the page says Build 42 is supported. Every mod in the table was last updated after Dec 2024.
- Java check: the mods on disk were searched for .jar / .class / .dll / .exe files and for ZombieBuddy in mod.info; for the rest, each page's "required items" list and description were read. Anything needing ZombieBuddy or Java is in "Skipped".
- Tier: 1 = replaces or redraws a ZeD surface; 2 = adds to a ZeD surface; 3 = popular gameplay. The table is ranked by tier, then subscribers.
- "On disk" = already subscribed on this PC (E:\Project Zomboid\SteamApps\workshop\content\108600), so it only needs enabling.

## Candidates (305)

| # | Mod | Author | Subs | B42 evidence | On disk | Tier | ZeD surface it touches | Group | Needs / notes |
|---|---|---|---|---|---|---|---|---|---|
| 1 | [Combat Text (B40+B41+B42)](https://steamcommunity.com/sharedfiles/filedetails/?id=2286124931) | Rezistor | 2.9M | tagged B42 | yes | 1 | Floating combat text over the HUD | B | Page says B40 to B42; its B42 bug-fix patch (3775113600) is in the same group |
| 2 | [More Builds](https://steamcommunity.com/sharedfiles/filedetails/?id=515555911) | ProjectSky | 2.3M | tagged B42 | no | 1 | Build menu (B42 refactor, search, categories) | E | Big build-menu UI |
| 3 | [PZ-ClothingUI - Clothing items grid view (B41 + B42 Updated)](https://steamcommunity.com/sharedfiles/filedetails/?id=2695471997) | Ramp | 1.6M | tagged B42 | no | 1 | Clothing grid window beside inventory; item tooltips | A | Own clothing window, opens from a hotkey; needs no Mod Options on B42 |
| 4 | [Dynamic Traits and Expanded Moodles [B41 & B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=2459400130) | PepperCat | 939k | tagged B42 | no | 1 | Moodles + traits that change in play | B | Needs Moodle Framework (tested) |
| 5 | [Moodle Quarters [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=2854030563) | DahakaMVl | 705k | tagged B42 | no | 1 | Moodles (new moodles) | B |  |
| 6 | [Better Auto Mechanics [B42.20.4+ MP+SP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3635856965) | Hotox | 688k | tagged B42 | yes | 1 | Mechanics window | D | Alternative to Auto Mechanics (tested): both rework the mechanics window |
| 7 | [[42.20] Customizable Containers](https://steamcommunity.com/sharedfiles/filedetails/?id=2719850086) | dane | 606k | tagged B42 | yes | 1 | Container capacity, backpack items | A | Test the Lua mod only; its "Capacity Limit Bypass" sub-mod is a Java jar (skip it); needs dane's Library (3715021740, not tested, add to the group) |
| 8 | [Standardized Vehicle Upgrades 3 - Vanilla Addon](https://steamcommunity.com/sharedfiles/filedetails/?id=3304582091) | Jack Rossman | 569k | tagged B42 | yes | 1 | Vehicle upgrades | D | Needs SVU3 Core B42; needs Standardized Vehicle Upgrades 3 - Core - B42 (3403490889, group D); needs Tsar's Common Library B42 (3402491515, tested) |
| 9 | [Standardized Vehicle Upgrades 3 - Core - B42](https://steamcommunity.com/sharedfiles/filedetails/?id=3403490889) | Jack Rossman | 554k | tagged B42 | yes | 1 | Vehicle upgrades (mechanics window) | D | Core for the Vanilla Addon; needs Tsar's Common Library B42 (3402491515, tested) |
| 10 | [Evolving Traits World (ETW) + More Traits continuation](https://steamcommunity.com/sharedfiles/filedetails/?id=2914075159) | MusicManiac | 549k | tagged B42 | no | 1 | Traits / character screen | C | ETW: big trait mod, adds trait progress UI |
| 11 | [Darker Map](https://steamcommunity.com/sharedfiles/filedetails/?id=2939187818) | Lightja | 536k | tagged B42 | yes | 1 | Map look | E | ZeD has map styles |
| 12 | [[B42] Mod Manager](https://steamcommunity.com/sharedfiles/filedetails/?id=3567084868) | Duncan E. | 525k | tagged B42 | yes | 1 | Mod manager window | B | Does the job of ZeD's mod manager; expect C grade; needs Mod Load Order Sorter [b42] (3423660713, tested) |
| 13 | [Another Vehicle Claim System](https://steamcommunity.com/sharedfiles/filedetails/?id=2957935793) | Lu5ck | 522k | tagged B42 | no | 1 | Vehicle claim UI | D | Multiplayer |
| 14 | [[B42] Noir's Rifle Slings](https://steamcommunity.com/sharedfiles/filedetails/?id=3388107363) | Hx | 517k | tagged B42 | yes | 1 | Rifle sling slot | F | Belt / hotbar slot |
| 15 | [Military Grid Reference System For Map Callouts Cause You And Your Friends Get Lost Easily](https://steamcommunity.com/sharedfiles/filedetails/?id=2928660831) | Chuckleberry Finn | 488k | tagged B42 | no | 1 | Map grid labels | E |  |
| 16 | [[Deprecated] What can I craft?](https://steamcommunity.com/sharedfiles/filedetails/?id=3390169945) | Defoxale | 446k | tagged B42 | yes | 1 | Crafting helper | F | Deprecated on its page |
| 17 | [Hide Menu Debug + Remove Build Information](https://steamcommunity.com/sharedfiles/filedetails/?id=3554048011) | SuperJetPlus | 438k | tagged B42 | yes | 1 | Main menu text | E |  |
| 18 | [Moodles in lua [B42.20]](https://steamcommunity.com/sharedfiles/filedetails/?id=3395171770) | molecule31 | 426k | tagged B42 | yes | 1 | Moodles drawn in Lua | B | Replaces how moodles draw: ZeD places moodles, so high risk |
| 19 | [[B42]Simple sling mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2868394326) | YGfish | 407k | tagged B42 | yes | 1 | Sling slot | G |  |
| 20 | [Mutie's Context Menu Icons](https://steamcommunity.com/sharedfiles/filedetails/?id=3101668503) | Mutie | 402k | tagged B42 | yes | 1 | Context menu icons | H |  |
| 21 | [Better Server Settings](https://steamcommunity.com/sharedfiles/filedetails/?id=2756434288) | Revan | 395k | tagged B42 | yes | 1 | Server settings screens | E |  |
| 22 | [Spawn Selector [B42 Stable]](https://steamcommunity.com/sharedfiles/filedetails/?id=3772052709) | N3WO | 390k | tagged B42 | yes | 1 | Spawn selection screen | E | Spawn pickers are alternatives |
| 23 | [[B42] Simple Belt Flashlight! (Fix for angled flashlight)](https://steamcommunity.com/sharedfiles/filedetails/?id=3625933422) | RazpyPineapple | 361k | tagged B42 | yes | 1 | Belt flashlight slot | F | Alternative to Simple Flashlight on Belt (tested) |
| 24 | [Quick Item Action](https://steamcommunity.com/sharedfiles/filedetails/?id=2642486124) | co` | 266k | tagged B42 | no | 1 | Inventory quick actions | F |  |
| 25 | [Equipment UI – STABLE +](https://steamcommunity.com/sharedfiles/filedetails/?id=3682936016) | TwisTonFire | 261k | tagged B42 | yes | 1 | Paper-doll equipment window | G | Alternative to Equipment UI (tested) |
| 26 | [[FIXED] Proximity Inventory B42.20 COMPATIBLE [SP/MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3669550831) | Juliosy | 258k | tagged B42 | yes | 1 | Proximity loot in inventory pane | A | Alternative to Proximity Inventory (tested); test alone with ZeD, not with the original |
| 27 | [True Moozic B42+  The Music System for Project Zomboid (SP/MP)](https://steamcommunity.com/sharedfiles/filedetails/?id=3632610172) | a_COW_says | 243k | tagged B42 | no | 1 | Music, radio, items | E | True Moozic (B42 rewrite) |
| 28 | [Efficiency Skill Mod 2](https://steamcommunity.com/sharedfiles/filedetails/?id=3374408921) | GersonRess | 239k | tagged B42 | yes | 1 | New skill on skills page | C |  |
| 29 | [TwisTonFire - Improved Soundoptions](https://steamcommunity.com/sharedfiles/filedetails/?id=3575778063) | TwisTonFire | 221k | tagged B42 | no | 1 | Sound options screen | E |  |
| 30 | [Container Tags [B42 + MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3066276504) | Dismellion | 219k | tagged B42 | no | 1 | Container labels in loot window | A |  |
| 31 | [Context Menu Icons](https://steamcommunity.com/sharedfiles/filedetails/?id=3634921455) | Artmine15🍂 | 216k | tagged B42 | yes | 1 | Context menu icons | F | Context-menu icon packs are alternatives: one per group |
| 32 | [Choose Your Spawn!](https://steamcommunity.com/sharedfiles/filedetails/?id=3287958074) | Serellan | 215k | tagged B42 | yes | 1 | Spawn selection screen | F |  |
| 33 | [[B42] Bigger Character Avatar](https://steamcommunity.com/sharedfiles/filedetails/?id=3387640099) | rentalcow | 211k | tagged B42 | yes | 1 | Character avatar size | B | ZeD draws its own avatar |
| 34 | [Easy Drop'n'Loot](https://steamcommunity.com/sharedfiles/filedetails/?id=2871469707) | [usa] | 209k | tagged B42 | no | 1 | Loot window drop/loot buttons | A |  |
| 35 | [Easy Set Alarm](https://steamcommunity.com/sharedfiles/filedetails/?id=3566088272) | Mad | 208k | tagged B42 | yes | 1 | Watch alarm dialog | F |  |
| 36 | [Neat Rocco's UI [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3723726293) | ArtNod | 203k | tagged B42 | yes | 1 | Whole-game UI restyle | H | Needs NeatUI Framework (tested); expect C grade |
| 37 | [TwisTonFire - Map Improvements](https://steamcommunity.com/sharedfiles/filedetails/?id=3627539752) | TwisTonFire | 202k | tagged B42 | no | 1 | Map window | E |  |
| 38 | [[B42MP] Take Any Amount](https://steamcommunity.com/sharedfiles/filedetails/?id=3389115640) | Bananaut | 198k | tagged B42 | yes | 1 | Inventory transfer amount dialog | A | B42 port of Take Any Amount |
| 39 | [[B41/B42] Toughness Skill](https://steamcommunity.com/sharedfiles/filedetails/?id=3545533939) | FishLord | 198k | tagged B42 | yes | 1 | New skill on skills page | C |  |
| 40 | [Extended categories - Better Hoarding! (B42 SP/MP)](https://steamcommunity.com/sharedfiles/filedetails/?id=3650035249) | Kechna | 190k | tagged B42 | yes | 1 | Item categories in inventory list | A |  |
| 41 | [Banger's Retro Car Dashboard [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3739256322) | Banger | 186k | tagged B42 | yes | 1 | Vehicle dashboard | D | ZeD replaces the dashboard; alternative to Realistic Dashboard (tested) |
| 42 | [B42 Native ModOptions Example](https://steamcommunity.com/sharedfiles/filedetails/?id=3386860561) | dhert | 182k | tagged B42 | yes | 1 | Mod Options (native) example | E | Shows what a mod's Mod Options page looks like |
| 43 | [Dynamic Moodles](https://steamcommunity.com/sharedfiles/filedetails/?id=3674800555) | Luigiceva | 181k | tagged B42 | yes | 1 | Moodle icons / animation | B | needs Moodles in lua [B42.20] (3395171770, group B) |
| 44 | [CH Status HUD](https://steamcommunity.com/sharedfiles/filedetails/?id=3776182375) | Neglosz | 181k | tagged B42 | yes | 1 | Status HUD | B |  |
| 45 | [Workshop Update Checker](https://steamcommunity.com/sharedfiles/filedetails/?id=3628835042) | Anach | 175k | tagged B42 | yes | 1 | Main menu / mod list | E |  |
| 46 | [Simple Context Menu Icons](https://steamcommunity.com/sharedfiles/filedetails/?id=3634921763) | Artmine15🍂 | 172k | tagged B42 | yes | 1 | Context menu icons | F | needs Context Menu Icons (3634921455, group F) |
| 47 | [NeatUI Equipment [42.21]](https://steamcommunity.com/sharedfiles/filedetails/?id=3790656296) | Gimmi | 172k | tagged B42 | yes | 1 | Equipment window | A | Needs NeatUI Framework (tested) |
| 48 | [Mod Comparer](https://steamcommunity.com/sharedfiles/filedetails/?id=3019672735) | Lanceris | 170k | tagged B42 | no | 1 | Mod list compare | E |  |
| 49 | [[B42.20/B42.21] Simple Belt Flashlight+ (Better Flashlights Compatible)](https://steamcommunity.com/sharedfiles/filedetails/?id=3778709615) | ACE | 161k | tagged B42 | yes | 1 | Belt flashlight slot | G | Alternative to Simple Flashlight on Belt (tested) |
| 50 | [No Welcome Window [B42.21+]](https://steamcommunity.com/sharedfiles/filedetails/?id=3389338537) | Ben.en | 161k | tagged B42 | no | 1 | Welcome window | E |  |
| 51 | [Nick's Inventory Selection Fix](https://steamcommunity.com/sharedfiles/filedetails/?id=3782920935) | Nick | 159k | tagged B42 | yes | 1 | Inventory selection handling | A | Patches vanilla inventory pane selection |
| 52 | [Reorder The Hotbar (B42+ Fixed)](https://steamcommunity.com/sharedfiles/filedetails/?id=3663625294) | Feldons | 153k | tagged B42 | no | 1 | Hotbar reorder | F | Alternative to Reorder The Hotbar (tested) |
| 53 | [[B42+]L4D2 Zombie Siege Background Main Menu [16:9+21:9]](https://steamcommunity.com/sharedfiles/filedetails/?id=3388808256) | [MLT]뉴비 까마귀 | 150k | tagged B42 | no | 1 | Main menu background | E | Main menu backgrounds are alternatives |
| 54 | [Minimal Display Bars + Nutritions + Discomfort [B41/B42.20]](https://steamcommunity.com/sharedfiles/filedetails/?id=3388844542) | Vorshim | 149k | tagged B42 | yes | 1 | Display bars HUD | B | B42 version of Minimal Display Bars |
| 55 | [Mini Health Plus](https://steamcommunity.com/sharedfiles/filedetails/?id=3710913197) | TwisTonFire | 146k | tagged B42 | yes | 1 | Health mini panel | B | Alternative to Mini Health Panel (tested) |
| 56 | [[B42] Survival HUD](https://steamcommunity.com/sharedfiles/filedetails/?id=3495906499) | Duncan E. | 145k | tagged B42 | yes | 1 | Survival HUD | B | needs [B42] Mod Manager (3567084868, group B); needs Moodles in lua [B42.20] (3395171770, group B) |
| 57 | [Cheat Menu: Reloaded [B42 Fixed]](https://steamcommunity.com/sharedfiles/filedetails/?id=3683918273) | Stoneboi | 143k | tagged B42 | no | 1 | Cheat menu (context menu) | E | Cheat menus are alternatives: one per group |
| 58 | [Neat Lockpicking](https://steamcommunity.com/sharedfiles/filedetails/?id=3783535220) | Repsak | 138k | tagged B42 | yes | 1 | Lockpicking UI | E | Needs NeatUI Framework (tested) |
| 59 | [[B42/41] Improved Farming Info Window](https://steamcommunity.com/sharedfiles/filedetails/?id=3470852353) | SkyBlue | 137k | tagged B42 | yes | 1 | Farming info window | A |  |
| 60 | [The Best Lockpicking [B42.21] [MP Ready]](https://steamcommunity.com/sharedfiles/filedetails/?id=3440867775) | NickFleim | 135k | tagged B42 | yes | 1 | Lockpicking UI | F |  |
| 61 | [Lua Digital Watch Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3676456221) | RedChili | 131k | tagged B42 | yes | 1 | Digital watch HUD | B | ZeD has its own watch plate on the belt |
| 62 | [Auto Loot](https://steamcommunity.com/sharedfiles/filedetails/?id=3392699932) | Tchernobill | 126k | tagged B42 | yes | 1 | Loot window auto-loot rules | A |  |
| 63 | [Better Lockpicking (Continued) b42.20+](https://steamcommunity.com/sharedfiles/filedetails/?id=3768298886) | Ulas | 123k | tagged B42 | no | 1 | Lockpicking UI | D | Lockpicking mods are alternatives: one per group |
| 64 | [[B42] Nested Containers](https://steamcommunity.com/sharedfiles/filedetails/?id=3410947298) | Nikku Miru | 119k | tagged B42 | yes | 1 | Nested containers in loot/inventory pane | A |  |
| 65 | [O.C.D. Inventory](https://steamcommunity.com/sharedfiles/filedetails/?id=3773985930) | Monster | 114k | tagged B42 | yes | 1 | Inventory list sorting / layout | A |  |
| 66 | [TwisTonFire - minimap](https://steamcommunity.com/sharedfiles/filedetails/?id=3572564421) | TwisTonFire | 113k | tagged B42 | yes | 1 | Minimap | E | ZeD has its own map surfaces |
| 67 | [Clothing Actions - Radial Menu](https://steamcommunity.com/sharedfiles/filedetails/?id=2786689104) | dhert | 112k | tagged B42 | no | 1 | Radial menu | F |  |
| 68 | [[B42, READ DESC] Mutie's Context Menu Icons Expanded & Redrawn](https://steamcommunity.com/sharedfiles/filedetails/?id=3422112160) | Artmine15🍂 | 105k | tagged B42 | yes | 1 | Context menu icons | A |  |
| 69 | [Cheat Menu Phoenix [B42] [B41 Re-Up]](https://steamcommunity.com/sharedfiles/filedetails/?id=3453422228) | 🌴 Zunder 🌴 | 102k | tagged B42 | no | 1 | Cheat menu | F |  |
| 70 | [[B42]Mod Folders](https://steamcommunity.com/sharedfiles/filedetails/?id=3779201168) | FieClaussell | 101k | tagged B42 | yes | 1 | Mod list folders | E |  |
| 71 | [[B42] Intuitive Crafting](https://steamcommunity.com/sharedfiles/filedetails/?id=3486217110) | Duncan E. | 98k | tagged B42 | yes | 1 | Crafting window | F | ZeD has Neat Crafting tested; this is a different crafting UI |
| 72 | [Inventory Tetris - Grid Based Items and Equipment Overhaul](https://steamcommunity.com/sharedfiles/filedetails/?id=3775513231) | Naneek | 96k | tagged B42 | yes | 1 | Grid inventory (Tetris) for items and equipment | H | Alternative to Inventory Tetris (tested); a whole-inventory overhaul, expect C grade |
| 73 | [More Traits Definitive Edition](https://steamcommunity.com/sharedfiles/filedetails/?id=3799050151) | GersonRess | 95k | tagged B42 | yes | 1 | Traits (character creation) | D | Alternative to More Traits (tested) and to ETW (group C), so it sits in another group |
| 74 | [Attachments UI [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3816324722) | Agente_FLOWERS | 91k | tagged B42 | yes | 1 | Attachments UI | G | Alternative to Plysken Attachments |
| 75 | [Darker Map & Satellite View](https://steamcommunity.com/sharedfiles/filedetails/?id=3571222611) | TwisTonFire | 90k | tagged B42 | yes | 1 | Map look + satellite view | F | Alternative to Darker Map |
| 76 | [Equipment UI - Paper Doll Equipment Interface SP/MP [B42.20+]](https://steamcommunity.com/sharedfiles/filedetails/?id=3780682550) | WildBrian | 85k | tagged B42 | yes | 1 | Paper-doll equipment window | H | Alternative |
| 77 | [Smart Radial Menu [B42 Stable]](https://steamcommunity.com/sharedfiles/filedetails/?id=3494108029) | Phoenix | 84k | tagged B42 | yes | 1 | Radial menu | F |  |
| 78 | [Plysken Attachments Reborn](https://steamcommunity.com/sharedfiles/filedetails/?id=3749848348) | Plysken | 82k | tagged B42 | yes | 1 | Attachments (hotbar slots) | F | ZeD owns the belt |
| 79 | [[42.13] Zed's Watch Slots](https://steamcommunity.com/sharedfiles/filedetails/?id=3630525533) | Zed | 73k | tagged B42 | no | 1 | Watch slots | F | ZeD shows watches on the belt |
| 80 | [MinimalHotbar](https://steamcommunity.com/sharedfiles/filedetails/?id=3688576740) | Esphex7kyo | 73k | tagged B42 | yes | 1 | Hotbar look | G | Hotbar mods are alternatives |
| 81 | [Blacklist & Proximity Inventory](https://steamcommunity.com/sharedfiles/filedetails/?id=3498294068) | TwisTonFire | 65k | tagged B42 | no | 1 | Proximity loot + blacklist | F | Alternative to Proximity Inventory (tested) |
| 82 | [Proximity Inventory](https://steamcommunity.com/sharedfiles/filedetails/?id=3740165370) | DevL0rd | 61k | tagged B42 | yes | 1 | Proximity loot in inventory pane | E | Alternative to Proximity Inventory (tested); keep apart from the other proximity mods |
| 83 | [Context Menu Cleanup](https://steamcommunity.com/sharedfiles/filedetails/?id=3780688809) | Kaoeutsu | 58k | tagged B42 | yes | 1 | Context menu layout | F |  |
| 84 | [Palm Pilot](https://steamcommunity.com/sharedfiles/filedetails/?id=3776531193) | YELLOW_MEOW | 58k | tagged B42 | yes | 1 | Palm Pilot (handheld UI) | G |  |
| 85 | [Hands: Stow, Equip, Place [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3786918614) | CoffeeCat | 52k | tagged B42 | yes | 1 | Hands / equip | F |  |
| 86 | [[FIXED] Combat Text Patch b42.20](https://steamcommunity.com/sharedfiles/filedetails/?id=3775113600) | ifchan | 52k | tagged B42 | no | 1 | Combat Text fix for 42.20 | B | Bug-fix patch for Combat Text (same group); load it after Combat Text |
| 87 | [RPGSkillTree[42.13][SP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3621388762) | Gratia197 | 52k | tagged B42 | yes | 1 | Skill tree window | C |  |
| 88 | [Project Writing [42.21]](https://steamcommunity.com/sharedfiles/filedetails/?id=3796402502) | Gimmi | 44k | tagged B42 | yes | 1 | Writing / notes window, map | E | Needs NeatUI Framework (tested) |
| 89 | [Icons Inventory](https://steamcommunity.com/sharedfiles/filedetails/?id=3718412967) | blint | 43k | tagged B42 | no | 1 | Inventory icons | A |  |
| 90 | [Second Back Slot [B42.20]](https://steamcommunity.com/sharedfiles/filedetails/?id=3751668602) | я двухсотый | 39k | tagged B42 | no | 1 | Back slot | H |  |
| 91 | [N3WO Map Overhaul [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3785033563) | N3WO | 39k | tagged B42 | yes | 1 | Map window overhaul | H | Alternative to the other map-look mods |
| 92 | [Radio Frequency Manager [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3659543622) | SP4RTAN | 38k | tagged B42 | no | 1 | Radio window | E | ZeD has its own radio window |
| 93 | [Nested Health Info](https://steamcommunity.com/sharedfiles/filedetails/?id=3779405481) | Kaoeutsu | 37k | tagged B42 | no | 1 | Health panel layout | B | ZeD replaces the Health panel |
| 94 | [Retro Dashboard Digitals](https://steamcommunity.com/sharedfiles/filedetails/?id=3743082626) | frey | 36k | tagged B42 | no | 1 | Vehicle dashboard gauges | E |  |
| 95 | [Sandbox Control - Cheat & Creative Menu [B42.21]](https://steamcommunity.com/sharedfiles/filedetails/?id=3825312974) | Hadge2506 | 8k | tagged B42 | no | 1 | Cheat / creative menu | G |  |
| 96 | [Yaki's Hair Salon](https://steamcommunity.com/sharedfiles/filedetails/?id=2761200458) | Yaki | 1.5M | description says B42 | no | 2 | Hair salon (character) | C | Page says B42 Stable compatible (tag B41); needs Fluffy Hair (tested) |
| 97 | [[B42/B41] The Motorious Zone Vehicle Pack](https://steamcommunity.com/sharedfiles/filedetails/?id=2791656602) | fhqwhgads | 1.3M | tagged B42 | no | 2 | Vehicle pack | D |  |
| 98 | [Horde Night](https://steamcommunity.com/sharedfiles/filedetails/?id=2714850307) | WindFly | 949k | description says B42 | no | 2 | Horde events | H | Page says B42 support added Dec 2024 (tag is B41 only) |
| 99 | [Night Vision Chucked](https://steamcommunity.com/sharedfiles/filedetails/?id=2842179206) | Chuckleberry Finn | 861k | tagged B42 | no | 2 | Night vision overlay | G | Needs errorMagnifier (tested) |
| 100 | ['90 Mercedes-Benz Unimog U1550L](https://steamcommunity.com/sharedfiles/filedetails/?id=2843855721) | cyt | 852k | tagged B42 | no | 2 | Vehicle | D |  |
| 101 | [You drive, I sleep](https://steamcommunity.com/sharedfiles/filedetails/?id=2830570280) | Chuckleberry Finn | 779k | tagged B42 | no | 2 | Sleep in vehicles | D | Needs errorMagnifier (tested) |
| 102 | [[B42.20] Carry Visible Items In Hands [WIP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3749026793) | Nik | 758k | tagged B42 | yes | 2 | Items carried in hands | G |  |
| 103 | [Video Game Consoles](https://steamcommunity.com/sharedfiles/filedetails/?id=2831786301) | 🍎Spicy_Apples🍎 | 724k | tagged B42 | yes | 2 | Consoles (minigame UI) | H |  |
| 104 | [Pillow's Random Spawns [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=1911132112) | pillow | 720k | tagged B42 | yes | 2 | Spawn location choice | H | Alternative to the spawn pickers in E and F |
| 105 | [Advanced Trajectory's Realistic Overhaul](https://steamcommunity.com/sharedfiles/filedetails/?id=3036878362) | Radon226 | 705k | tagged B42 | yes | 2 | Aiming / ballistics | G |  |
| 106 | [[B41&B42] Show Wall Health](https://steamcommunity.com/sharedfiles/filedetails/?id=3002666175) | Kamer | 697k | tagged B42 | yes | 2 | Wall health overlay | B |  |
| 107 | [Nepenthe's Colored Engine Status (Now a vanilla feature in B42)](https://steamcommunity.com/sharedfiles/filedetails/?id=2975204120) | Nepenthe | 689k | tagged B42 | yes | 2 | Mechanics window colours | D | Says it is now a vanilla feature |
| 108 | [Nepenthe's Colored Battery Status (Now a vanilla feature in B42)](https://steamcommunity.com/sharedfiles/filedetails/?id=2973053380) | Nepenthe | 666k | tagged B42 | yes | 2 | Mechanics window colours | D | Says it is now a vanilla feature |
| 109 | [Stack All](https://steamcommunity.com/sharedfiles/filedetails/?id=2629074154) | star | 645k | tagged B42 | yes | 2 | Inventory context menu (Stack All) | A |  |
| 110 | [[B41 / B42.12+] bikinitools - independent vehicle spawner, skin changer and automations!](https://steamcommunity.com/sharedfiles/filedetails/?id=2634426926) | bikinihorst | 637k | tagged B42 | yes | 2 | Vehicle spawner / skin window | D | Admin-style tool with its own window |
| 111 | [[B42MP/B41]Surviving Through Seasons](https://steamcommunity.com/sharedfiles/filedetails/?id=2753086629) | Daimyo | 636k | tagged B42 | yes | 2 | Seasons | H |  |
| 112 | [Stairs Alert](https://steamcommunity.com/sharedfiles/filedetails/?id=3044807092) | Braven | 628k | tagged B42 | yes | 2 | Stairs warning overlay | B |  |
| 113 | [Ladders?! B42.20 SP/MP (Unofficial)](https://steamcommunity.com/sharedfiles/filedetails/?id=3629835761) | Birget | 618k | tagged B42 | yes | 2 | Ladders | H | B42 port; Ladders!? (tested) breaks on 42.21 |
| 114 | [Yaki's BarberShop](https://steamcommunity.com/sharedfiles/filedetails/?id=2810471370) | Yaki | 604k | tagged B42 | no | 2 | Barbershop (character) | E |  |
| 115 | [Addicted To Weight](https://steamcommunity.com/sharedfiles/filedetails/?id=2604943386) | PePePePePeil | 593k | tagged B42 | yes | 2 | Weight display in inventory | A |  |
| 116 | [Autotsar Motor Club B42](https://steamcommunity.com/sharedfiles/filedetails/?id=3404737883) | Tchernobill | 571k | tagged B42 | yes | 2 | Vehicles | D | Needs Tsar's Common Library B42 (tested) |
| 117 | [Autotsar Trailers B42](https://steamcommunity.com/sharedfiles/filedetails/?id=3402493701) | Tchernobill | 536k | tagged B42 | yes | 2 | Trailers | D | Needs Tsar's Common Library B42 |
| 118 | [[B41/B42] More Immersive Vehicles](https://steamcommunity.com/sharedfiles/filedetails/?id=3162566044) | DaNiG | 529k | tagged B42 | yes | 2 | Vehicles | D |  |
| 119 | [Better Generator Info](https://steamcommunity.com/sharedfiles/filedetails/?id=3576056135) | Eurymachus | 512k | tagged B42 | yes | 2 | Generator info window | A |  |
| 120 | [First Aid VHS Tapes](https://steamcommunity.com/sharedfiles/filedetails/?id=3153010942) | MrStevee | 501k | tagged B42 | yes | 2 | Skill VHS | C |  |
| 121 | [RV Interior Expansion [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3618427553) | Caçador | 492k | tagged B42 | yes | 2 | RV interiors | D | Needs Project RV Interior (tested) |
| 122 | [Large Progress Indicator](https://steamcommunity.com/sharedfiles/filedetails/?id=2926455909) | Riko Prushka | 481k | tagged B42 | yes | 2 | Action progress bar | B | Same author as RYG / Medium Progress Indicator: one per group |
| 123 | [Common Sense [B42.20+]](https://steamcommunity.com/sharedfiles/filedetails/?id=3750253491) | 1Vita | 460k | tagged B42 | yes | 2 | Common Sense B42 rewrite | G | Common Sense (Braven) breaks 42.21; this is the B42 port |
| 124 | [Auto Tailoring](https://steamcommunity.com/sharedfiles/filedetails/?id=3388183573) | Tchernobill | 453k | tagged B42 | yes | 2 | Tailoring | F |  |
| 125 | [Autotsar Bus B42](https://steamcommunity.com/sharedfiles/filedetails/?id=3402812859) | Tchernobill | 445k | tagged B42 | yes | 2 | Vehicles | D | Needs Tsar's Common Library B42 |
| 126 | [RV Interior Expansion Part 2 [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3622163276) | Caçador | 441k | tagged B42 | yes | 2 | RV interiors | D | Needs Project RV Interior + part 1 |
| 127 | [Better Car Physics](https://steamcommunity.com/sharedfiles/filedetails/?id=2909035179) | Neidmare | 432k | tagged B42 | no | 2 | Vehicle physics | D |  |
| 128 | [Ellie's Tattoo Parlor V4 b41/b42](https://steamcommunity.com/sharedfiles/filedetails/?id=2735059209) | ElictraV | 400k | tagged B42 | no | 2 | Tattoos (character UI) | C |  |
| 129 | [Dismantle Any Car](https://steamcommunity.com/sharedfiles/filedetails/?id=3428369137) | Nepenthe | 395k | tagged B42 | yes | 2 | Vehicle context menu | D |  |
| 130 | [+300 Points Trait](https://steamcommunity.com/sharedfiles/filedetails/?id=899287010) | Peu | 383k | tagged B42 | yes | 2 | Trait points (creation screen) | C |  |
| 131 | [[B42] Moodle Descriptions Expanded](https://steamcommunity.com/sharedfiles/filedetails/?id=3389003300) | geib | 377k | tagged B42 | yes | 2 | Moodle hover text | B | ZeD draws moodle hover text |
| 132 | [[KYR] Real Weather Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=3051276857) | tot4ll3d | 357k | tagged B42 | no | 2 | Weather | H |  |
| 133 | [True Action Dancing B42](https://steamcommunity.com/sharedfiles/filedetails/?id=3650071729) | Tchernobill | 354k | tagged B42 | yes | 2 | Dancing | F |  |
| 134 | [[B41/B42] Cryogenic Winter +Easy/Hard Modes (SP/MP)](https://steamcommunity.com/sharedfiles/filedetails/?id=2210760610) | path | 348k | tagged B42 | yes | 2 | Weather | H |  |
| 135 | [Map Symbols Plus (Hand-drawn)](https://steamcommunity.com/sharedfiles/filedetails/?id=3399645148) | Deon | 343k | tagged B42 | yes | 2 | Map symbols | E |  |
| 136 | [Auto Reload](https://steamcommunity.com/sharedfiles/filedetails/?id=3389448389) | Tchernobill | 343k | tagged B42 | yes | 2 | Reload | F |  |
| 137 | [[B42MP] FlipVehiclePlusTrailer](https://steamcommunity.com/sharedfiles/filedetails/?id=3430172149) | Bananaut | 338k | tagged B42 | yes | 2 | Vehicle context menu | D |  |
| 138 | [Known And Collected](https://steamcommunity.com/sharedfiles/filedetails/?id=2881764317) | UnCheat | 335k | tagged B42 | yes | 2 | Book / media tooltips | A |  |
| 139 | [RYG Progress Indicator](https://steamcommunity.com/sharedfiles/filedetails/?id=3220040578) | Riko Prushka | 325k | tagged B42 | yes | 2 | Action progress bar | C | Alternative to Large Progress Indicator |
| 140 | [[B42] Survival](https://steamcommunity.com/sharedfiles/filedetails/?id=3402516345) | Balance | 314k | tagged B42 | yes | 2 | Survival content | H |  |
| 141 | [[B42] UH-1B Helicopter (Beta)](https://steamcommunity.com/sharedfiles/filedetails/?id=3409723807) | User | 309k | tagged B42 | yes | 2 | Helicopter vehicle | D | needs [B42]Aviation Core (Beta) (3783444342, not tested, add to the group) |
| 142 | [Auto Cook](https://steamcommunity.com/sharedfiles/filedetails/?id=3388721641) | Tchernobill | 309k | tagged B42 | yes | 2 | Cooking | F |  |
| 143 | [[B42] Item Details](https://steamcommunity.com/sharedfiles/filedetails/?id=3477237184) | Bravo | 304k | tagged B42 | yes | 2 | Item tooltip details | A |  |
| 144 | [Place Anywhere](https://steamcommunity.com/sharedfiles/filedetails/?id=3613917826) | gunslinger | 297k | tagged B42 | yes | 2 | Item placement | F |  |
| 145 | [[B42] Bandits Creator](https://steamcommunity.com/sharedfiles/filedetails/?id=3469292499) | Slayer | 295k | tagged B42 | yes | 2 | NPC editor window | H | Needs Bandits NPC (tested) |
| 146 | [Defecation v3.59 (Build 42.20mp+)](https://steamcommunity.com/sharedfiles/filedetails/?id=1436878551) | nater | 286k | tagged B42 | no | 2 | Needs moodles | C | Defecation |
| 147 | [[B42] Custom Map Labels](https://steamcommunity.com/sharedfiles/filedetails/?id=3559737194) | 𝒎𝒐 | 275k | tagged B42 | no | 2 | Map labels | E |  |
| 148 | [[B42.13+] SimpleStatus-Fixed](https://steamcommunity.com/sharedfiles/filedetails/?id=3399432867) | 瓦尔基里，你太baby辣 | 274k | tagged B42 | yes | 2 | Status bars | B | Alternative to Simple Status (tested) |
| 149 | [True Weight](https://steamcommunity.com/sharedfiles/filedetails/?id=3768669395) | Jesus.Christ | 266k | tagged B42 | yes | 2 | Item weight values | A |  |
| 150 | [True Smoking [B42MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3423984426) | Ratamus | 263k | tagged B42 | yes | 2 | Smoking | C | needs Moodle Framework (3396446795, tested); needs Starlit Library (3378285185, tested) |
| 151 | [Map Symbols Plus (Stensil)](https://steamcommunity.com/sharedfiles/filedetails/?id=3395592779) | Deon | 263k | tagged B42 | yes | 2 | Map symbols | E |  |
| 152 | [Plysken Solar Revolution](https://steamcommunity.com/sharedfiles/filedetails/?id=3725311427) | Plysken | 261k | tagged B42 | yes | 2 | Power | H |  |
| 153 | [Immersive Blackouts [B42MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3607686447) | キツネユキ | 241k | tagged B42 | yes | 2 | Blackouts | H |  |
| 154 | [Simple Moodle Indicators](https://steamcommunity.com/sharedfiles/filedetails/?id=3402171609) | ShlurpDurgen | 234k | tagged B42 | no | 2 | Moodle level marks | B | needs Moodles in lua [B42.20] (3395171770, group B) |
| 155 | [[B42.21+ MP] - Push Vehicle](https://steamcommunity.com/sharedfiles/filedetails/?id=3780639614) | Trashcan | 222k | tagged B42 | yes | 2 | Vehicle push | D |  |
| 156 | [SixthSense](https://steamcommunity.com/sharedfiles/filedetails/?id=2863908612) | Tchernobill | 221k | tagged B42 | no | 2 | Trait / overlay | C |  |
| 157 | [[B41,B42] Show VHS skills in tooltip](https://steamcommunity.com/sharedfiles/filedetails/?id=3716522633) | Aire Ayquaza | 220k | tagged B42 | yes | 2 | VHS tooltip | A |  |
| 158 | [[B42] Item Condition Fix](https://steamcommunity.com/sharedfiles/filedetails/?id=3394609418) | Hx | 212k | tagged B42 | yes | 2 | Item condition display | A | needs [B41/B42] Item Condition (2852309899, tested) |
| 159 | [Injury Indicator [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3565698092) | BOBcat | 208k | tagged B42 | yes | 2 | Injury indicator on HUD | B |  |
| 160 | [Somewhat Traits](https://steamcommunity.com/sharedfiles/filedetails/?id=3498347699) | somewhatfrog | 208k | tagged B42 | yes | 2 | Traits | C |  |
| 161 | [[B42MP] Simple Show XP](https://steamcommunity.com/sharedfiles/filedetails/?id=2891170430) | GuiriGuy | 196k | tagged B42 | yes | 2 | XP gain text | B | XP drop mods are alternatives: one per group |
| 162 | [[B42] Horticulture](https://steamcommunity.com/sharedfiles/filedetails/?id=3650168851) | Balance | 195k | tagged B42 | yes | 2 | Farming | A |  |
| 163 | [[B42] OSRS Exp Drops](https://steamcommunity.com/sharedfiles/filedetails/?id=3391145494) | Courvix | 190k | tagged B42 | yes | 2 | XP drops (OSRS style) | C |  |
| 164 | [Washing Menus Improved [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3460812542) | Afyrmo | 190k | tagged B42 | yes | 2 | Wash context menu | F |  |
| 165 | [Item Rarity UI (Build 41 + 42)](https://steamcommunity.com/sharedfiles/filedetails/?id=3662387304) | Tim Habay | 187k | tagged B42 | yes | 2 | Item rarity colouring in inventory | A |  |
| 166 | [[B42][MP]MoreMenuOptions](https://steamcommunity.com/sharedfiles/filedetails/?id=3636171151) | 十叁 | 184k | tagged B42 | no | 2 | Context menu options | F |  |
| 167 | [[B42] OSRS XP Drops Retextured](https://steamcommunity.com/sharedfiles/filedetails/?id=3413529369) | FishLord | 183k | tagged B42 | yes | 2 | XP drops retexture | C | Needs OSRS Exp Drops (same group) |
| 168 | [Obvious Skill Tapes - highlight useful VHS tapes](https://steamcommunity.com/sharedfiles/filedetails/?id=3739168410) | qwerto | 181k | tagged B42 | yes | 2 | VHS highlight in inventory | A |  |
| 169 | [Neon moodle levels](https://steamcommunity.com/sharedfiles/filedetails/?id=3392116408) | UnCheat | 177k | tagged B42 | yes | 2 | Moodle level colours | C | needs Moodles in lua [B42.20] (3395171770, group B) |
| 170 | [Farming Expansion B42](https://steamcommunity.com/sharedfiles/filedetails/?id=3444499190) | Ratchat | 176k | tagged B42 | yes | 2 | Farming | A |  |
| 171 | [SaucedCarts - Pushable Carts](https://steamcommunity.com/sharedfiles/filedetails/?id=3651954650) | Dark Sauce | 172k | tagged B42 | yes | 2 | Pushable carts (containers) | H |  |
| 172 | [True Music Jukebox 42](https://steamcommunity.com/sharedfiles/filedetails/?id=3398874593) | norby007 | 163k | tagged B42 | yes | 2 | Jukebox | F | True Music Jukebox 42; its page may still list True Music (last updated Feb 2023, see Skipped): check before the run |
| 173 | [[B42] More Item Information](https://steamcommunity.com/sharedfiles/filedetails/?id=3494474677) | FishLord | 163k | tagged B42 | yes | 2 | Item tooltip details | E | Alternative to Item Details (group A) |
| 174 | [[B42.20] Plain Moodles Redone](https://steamcommunity.com/sharedfiles/filedetails/?id=3772979228) | Slobodskoy | 157k | tagged B42 | yes | 2 | Moodle icon set | E | Moodle texture pack |
| 175 | [Better Clothing Info](https://steamcommunity.com/sharedfiles/filedetails/?id=3604080281) | Eurymachus | 155k | tagged B42 | yes | 2 | Clothing item tooltip / info | A |  |
| 176 | [[B42.19] Filibuster Rhymes' Certified Used Cars](https://steamcommunity.com/sharedfiles/filedetails/?id=3683878228) | NWBear | 155k | tagged B42 | no | 2 | Vehicle pack (B42 Filibuster) | D |  |
| 177 | [[B42.20+] Vehicle Aim Roof Fix](https://steamcommunity.com/sharedfiles/filedetails/?id=3781616141) | bob | 153k | tagged B42 | yes | 2 | Vehicle fixes | D |  |
| 178 | [Better Safehouse [B42.20- MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3634569678) | Refúgio Z | 150k | tagged B42 | no | 2 | Safehouse UI | E | Multiplayer |
| 179 | [Old moodles +new [B42+]](https://steamcommunity.com/sharedfiles/filedetails/?id=3386486141) | molecule31 | 149k | tagged B42 | yes | 2 | Moodle icon set | D | Moodle texture packs are alternatives: one per group |
| 180 | [ Hephas Occupations and Traits](https://steamcommunity.com/sharedfiles/filedetails/?id=3256482412) | Hephaistos | 148k | tagged B42 | no | 2 | Occupations and traits (creation screen) | C |  |
| 181 | [[B42] [MP] Quick Remove Broken Glass](https://steamcommunity.com/sharedfiles/filedetails/?id=3669016488) | PikaMel | 147k | tagged B42 | no | 2 | Context menu | F |  |
| 182 | [Combat Traits](https://steamcommunity.com/sharedfiles/filedetails/?id=3427091746) | somewhatfrog | 147k | tagged B42 | yes | 2 | Traits | C |  |
| 183 | [LG Extended Electricity](https://steamcommunity.com/sharedfiles/filedetails/?id=3779562002) | LittleGroove | 145k | tagged B42 | yes | 2 | Electricity | H |  |
| 184 | [More Maps [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3390897023) | Champy | 144k | tagged B42 | yes | 2 | Map items | E |  |
| 185 | [Show Sowing Season In Seed Tooltip](https://steamcommunity.com/sharedfiles/filedetails/?id=3404461962) | anor | 144k | tagged B42 | yes | 2 | Seed tooltip | A | needs Starlit Library (3378285185, tested) |
| 186 | [Bandits Extra Options](https://steamcommunity.com/sharedfiles/filedetails/?id=3412682512) | 9kgsofrice | 143k | tagged B42 | no | 2 | Bandits options | H | Needs Bandits NPC (tested) |
| 187 | [True Cargo - Project Full HD](https://steamcommunity.com/sharedfiles/filedetails/?id=3806955469) | under | 142k | tagged B42 | yes | 2 | Vehicle cargo | D |  |
| 188 | [Voiced Radio and TVs](https://steamcommunity.com/sharedfiles/filedetails/?id=2950750587) | Fed-cap | 142k | tagged B42 | no | 2 | Radio/TV voices | E |  |
| 189 | [Map All Known Fix [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3785198639) | Dusk | 141k | tagged B42 | no | 2 | Map reveal | E |  |
| 190 | [Smarter Storage - Extra Presets](https://steamcommunity.com/sharedfiles/filedetails/?id=3587884762) | Phoenix | 139k | tagged B42 | no | 2 | Smarter Storage presets | A | Needs Smarter Storage (tested) |
| 191 | [Effortless Towing](https://steamcommunity.com/sharedfiles/filedetails/?id=3442862183) | Mich | 135k | tagged B42 | yes | 2 | Towing context menu | D | Towing mods are alternatives: one per group |
| 192 | [Become Desensitized [B42.20 Stable Unofficial SP/MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3738669352) | Stultusaur | 133k | tagged B42 | yes | 2 | Trait | C |  |
| 193 | [Immersive Hotwire](https://steamcommunity.com/sharedfiles/filedetails/?id=3653092321) | BarbiE | 132k | tagged B42 | yes | 2 | Hotwire | A |  |
| 194 | [Adaptive Traits](https://steamcommunity.com/sharedfiles/filedetails/?id=3622328997) | Mich | 130k | tagged B42 | yes | 2 | Traits | C |  |
| 195 | [Skill Book Expansion](https://steamcommunity.com/sharedfiles/filedetails/?id=3557111695) | Josko | 129k | tagged B42 | no | 2 | Skill books | C |  |
| 196 | [Dash Roamer [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3775809123) | Midgar | 108k | tagged B42 | yes | 2 | Vehicle (camper) | D | needs Standardized Vehicle Upgrades 3 - Core - B42 (3403490889, group D); needs Standardized Vehicle Upgrades 3 - Vanilla Addon (3304582091, group D); needs Tsar's Common Library B42 (3402491515, tested) |
| 197 | [Exp Recovery for Skill Books](https://steamcommunity.com/sharedfiles/filedetails/?id=2923554542) | 𝚅𝚒𝚜𝚑𝚗𝚢𝚊 | 106k | tagged B42 | no | 2 | Skill books | C |  |
| 198 | [Skullys Lowerback Dufflebags, Chest Rigs + Fannypack, Container Rebalance [42.20]](https://steamcommunity.com/sharedfiles/filedetails/?id=3698401476) | Skully | 105k | tagged B42 | yes | 2 | Bags and container sizes | G |  |
| 199 | [[B41 & B42] Rope Towing](https://steamcommunity.com/sharedfiles/filedetails/?id=3261334016) | LaChips | 104k | tagged B42 | no | 2 | Rope towing | F |  |
| 200 | [Working Knowledge - Lootable Skill Documents](https://steamcommunity.com/sharedfiles/filedetails/?id=3717099183) | booweries | 104k | tagged B42 | no | 2 | Skill documents | C |  |
| 201 | [ImmersiveSolarArrays [42.16+]](https://steamcommunity.com/sharedfiles/filedetails/?id=3647117173) | Zeratulis | 104k | description says B42 | no | 2 | Solar power (ISA B42) | H | Immersive Solar Arrays BETA (tested) is the older one: alternatives |
| 202 | [Playable Minigames (Previously Playable Pool)](https://steamcommunity.com/sharedfiles/filedetails/?id=3716934959) | Wickedlizerd | 102k | tagged B42 | yes | 2 | Minigames (UI) | H |  |
| 203 | [Practice Crafting Skills](https://steamcommunity.com/sharedfiles/filedetails/?id=3765795716) | AnnLikki | 100k | tagged B42 | yes | 2 | Skill XP | C |  |
| 204 | [[B42] Briefing](https://steamcommunity.com/sharedfiles/filedetails/?id=3565244378) | Duncan E. | 98k | tagged B42 | yes | 2 | Briefing window | E | Alternative to Survivor Briefing (tested) |
| 205 | [True Music Radio 42](https://steamcommunity.com/sharedfiles/filedetails/?id=3631572046) | norby007 | 98k | tagged B42 | no | 2 | Car radio music | F |  |
| 206 | [[42] Rip All Button In context Menu](https://steamcommunity.com/sharedfiles/filedetails/?id=3641027178) | Unclear | 97k | tagged B42 | no | 2 | Rip context menu | F |  |
| 207 | [Eat Smart](https://steamcommunity.com/sharedfiles/filedetails/?id=3456212729) | ? | 95k | tagged B42 | no | 2 | Food info UI | C |  |
| 208 | [Devcatt's Furry Moodles [Build 42+]](https://steamcommunity.com/sharedfiles/filedetails/?id=3392964216) | Devcatt | 91k | tagged B42 | yes | 2 | Moodle icon set | F | Moodle texture pack |
| 209 | [Vehicle Ground Guard [B42 SP + MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3690308807) | NullToken | 90k | tagged B42 | yes | 2 | Vehicles | D |  |
| 210 | [Better Daily Reports](https://steamcommunity.com/sharedfiles/filedetails/?id=3580557206) | Eurymachus | 89k | tagged B42 | yes | 2 | Daily reports window | E |  |
| 211 | [NeatUI XP Drop [42.21]](https://steamcommunity.com/sharedfiles/filedetails/?id=3760545452) | Gimmi | 88k | tagged B42 | yes | 2 | XP drop | D | Needs NeatUI Framework (tested) |
| 212 | [Dismantle All at Once](https://steamcommunity.com/sharedfiles/filedetails/?id=3761218629) | Finy | 87k | tagged B42 | yes | 2 | Dismantle context menu | F |  |
| 213 | [Challenge Traits - Headshots, CDDA, and More [42.21 Stable]](https://steamcommunity.com/sharedfiles/filedetails/?id=3634630898) | Tenhats | 85k | tagged B42 | no | 2 | Traits | C |  |
| 214 | [[B42/41] Better Clothing Info Comparison](https://steamcommunity.com/sharedfiles/filedetails/?id=3036830549) | Bruno Menezes | 81k | tagged B42 | no | 2 | Clothing tooltip comparison | A |  |
| 215 | [Crafting XP Display](https://steamcommunity.com/sharedfiles/filedetails/?id=3428715523) | N0wh3re | 81k | tagged B42 | no | 2 | Crafting XP display | F |  |
| 216 | [[B42.20+] Vehicle Enter/Exit Fix](https://steamcommunity.com/sharedfiles/filedetails/?id=3785695033) | bob | 77k | tagged B42 | no | 2 | Vehicle enter/exit | D |  |
| 217 | [HEF - Helicopter Event Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3672792485) | MasterGG | 73k | tagged B42 | no | 2 | Helicopter events | G | B42 helicopter framework; Expanded Helicopter Events has no B42 version |
| 218 | [[B42.20] Auto All - Cook, Medicine, Read, Clean, Rip, Tailoring, Mechanics, Exercise, Reload, Open & Dismantle](https://steamcommunity.com/sharedfiles/filedetails/?id=3777237134) | Robson Foster | 71k | tagged B42 | yes | 2 | Context menu batch actions | F |  |
| 219 | [This Is Me - More Character Traits](https://steamcommunity.com/sharedfiles/filedetails/?id=3806020504) | GersonRess | 71k | tagged B42 | yes | 2 | Traits | C | needs Traits As Skills (3784847437, tested) |
| 220 | [Cone Vision Outline [42.21.0] [SP&MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3659137034) | HOFNARR | 70k | tagged B42 | yes | 2 | Vision cone outline | B |  |
| 221 | [Ping Items! Friends! 42.20 MP Official](https://steamcommunity.com/sharedfiles/filedetails/?id=3776262249) | FistOfTheNoob | 69k | tagged B42 | yes | 2 | Ping items (multiplayer) | G |  |
| 222 | [TwisTonFire - Quick'n'Auto Mark](https://steamcommunity.com/sharedfiles/filedetails/?id=3579410548) | TwisTonFire | 67k | tagged B42 | yes | 2 | Map marks | E |  |
| 223 | [The Psychopath Trait [B42.20+ SP/MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3736555309) | ЯΞxx | 67k | tagged B42 | yes | 2 | Traits | C |  |
| 224 | [Inspect Items Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3617732907) | MasterGG | 64k | tagged B42 | no | 2 | Inspect items window | G |  |
| 225 | [Better Corpse Burning](https://steamcommunity.com/sharedfiles/filedetails/?id=3790089095) | EROGZ | 63k | tagged B42 | yes | 2 | Corpse context menu | F |  |
| 226 | [[B42] MandoDB - Old Moodles Icons + Redrawn](https://steamcommunity.com/sharedfiles/filedetails/?id=3386409674) | MandoDB | 63k | tagged B42 | yes | 2 | Moodle icon set | G | Moodle texture pack |
| 227 | [Legendary Professions and Traits](https://steamcommunity.com/sharedfiles/filedetails/?id=3669469283) | Akyrohunter | 63k | tagged B42 | no | 2 | Occupations and traits | D |  |
| 228 | [Over the Shoulder](https://steamcommunity.com/sharedfiles/filedetails/?id=3808805481) | SweetBabyINC | 60k | tagged B42 | yes | 2 | Camera | H | Some of its sub-mods are patches for other mods (Authentic Z, Fancy Handwork B42): enable only the main one |
| 229 | [Hide Equipped Items](https://steamcommunity.com/sharedfiles/filedetails/?id=3600186927) | somewhatfrog | 56k | tagged B42 | no | 2 | Equipped item display | F |  |
| 230 | [Tooltiplib - Tooltip Framework for Modders](https://steamcommunity.com/sharedfiles/filedetails/?id=3694097672) | Dark Sauce | 55k | tagged B42 | yes | 2 | Tooltip framework | G |  |
| 231 | [[B42 STABLE] Expanded Professions](https://steamcommunity.com/sharedfiles/filedetails/?id=3440958051) | Obstructed | 54k | tagged B42 | no | 2 | Occupations | E |  |
| 232 | [[B42] Mastered Traits](https://steamcommunity.com/sharedfiles/filedetails/?id=3423601261) | Neighz | 51k | tagged B42 | no | 2 | Traits | C |  |
| 233 | [Two Weapons on Back [42.21]](https://steamcommunity.com/sharedfiles/filedetails/?id=3778319798) | Alcazar | 51k | tagged B42 | no | 2 | Back slot | F |  |
| 234 | [Become Brave [B42.20 Stable Unofficial SP/MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3738660077) | Stultusaur | 45k | tagged B42 | no | 2 | Trait | C |  |
| 235 | [[B42] Functional TV Movies & Series - Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3685672179) | Mr MaeuL | 39k | tagged B42 | yes | 2 | TV programmes | E |  |
| 236 | [[B42]Whose Key Is This?](https://steamcommunity.com/sharedfiles/filedetails/?id=3784348098) | [MLT]뉴비 까마귀 | 38k | tagged B42 | no | 2 | Key tooltip | F |  |
| 237 | [Balaclava Slot](https://steamcommunity.com/sharedfiles/filedetails/?id=3789234614) | Envian | 37k | tagged B42 | no | 2 | Clothing slot | F |  |
| 238 | [GPS Cross-Device - ProjectZomboidMap.com](https://steamcommunity.com/sharedfiles/filedetails/?id=3793289804) | Exit | 32k | tagged B42 | yes | 2 | Map export | E |  |
| 239 | [Stay With Me [B42 - NPC Companion]](https://steamcommunity.com/sharedfiles/filedetails/?id=3800989007) | Albrecht | 31k | tagged B42 | yes | 2 | NPC companion | H |  |
| 240 | [Pixel Strike Indicator & Health Bar](https://steamcommunity.com/sharedfiles/filedetails/?id=3793657917) | Riko Prushka | 31k | tagged B42 | yes | 2 | Hit indicator + health bar | B |  |
| 241 | [Functional Pager - Immersive Map-Wide Communication [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3744455714) | turnip | 30k | tagged B42 | no | 2 | Pager (radio-like) | E |  |
| 242 | [[B42.16+] XP Gain Bar v1.4 - DBD](https://steamcommunity.com/sharedfiles/filedetails/?id=3656128167) | deathbeforedinner | 28k | tagged B42 | no | 2 | XP gain bar | E |  |
| 243 | [Mattnetic's Heart Health Meter [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3805849470) | Mattnetic | 25k | tagged B42 | no | 2 | Heart health meter | B |  |
| 244 | [Gyde's Trait Magazines Extended+](https://steamcommunity.com/sharedfiles/filedetails/?id=3776852122) | awakutuhop | 24k | tagged B42 | no | 2 | Trait magazines | C | Needs Gyde's Trait Magazines (tested) |
| 245 | [Try Before You Wear](https://steamcommunity.com/sharedfiles/filedetails/?id=3797492691) | Diakøe | 22k | tagged B42 | no | 2 | Clothing try-on from inventory | A |  |
| 246 | [Wound Expansion](https://steamcommunity.com/sharedfiles/filedetails/?id=3819438691) | Kaoeutsu | 22k | tagged B42 | no | 2 | Wounds (health panel) | B | Test without its optional ZombieBuddy add-on |
| 247 | [Area Tasks - Select an area for vanilla tasks [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3793163745) | ferret | 20k | tagged B42 | no | 2 | Area-select tasks | F |  |
| 248 | [Roaming Survivors](https://steamcommunity.com/sharedfiles/filedetails/?id=3797874733) | Link | 20k | tagged B42 | yes | 2 | NPC survivors | H |  |
| 249 | [Football & Shoving [SP & MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3750861914) | Salmancyan | 18k | tagged B42 | no | 2 | Skill | C |  |
| 250 | [Auto Center Map](https://steamcommunity.com/sharedfiles/filedetails/?id=3790912405) | TOYSGUNNER | 14k | tagged B42 | no | 2 | Map centering | E |  |
| 251 | [Martial Arts - Version 2](https://steamcommunity.com/sharedfiles/filedetails/?id=3812456765) | The Senator | 11k | tagged B42 | no | 2 | Skill | C |  |
| 252 | [Container Capacity Indicator [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3789660055) | Bigminer | 11k | tagged B42 | no | 2 | Container capacity indicator | A |  |
| 253 | [Instinctive Hearing [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3789584579) | Twøne | 9k | tagged B42 | no | 2 | Trait + HUD | C | Test the base mod only: its outline add-on needs ZombieBuddy |
| 254 | [Bushcraft Gear - Tools [B41/B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=2423906082) | Scavenger | 3.3M | tagged B42 | yes | 3 | Tools | G |  |
| 255 | [Bushcraft Gear - Rare Weapons [B41/B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=2432621382) | Scavenger | 2.6M | tagged B42 | yes | 3 | Weapons | G |  |
| 256 | [Undead Survivor [B41/B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=2713921292) | Scavenger | 1.8M | tagged B42 | no | 3 | Clothing + weapons | G |  |
| 257 | [Military Ponchos [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=2629286881) | Akyet | 1.4M | tagged B42 | no | 3 | Clothing | G |  |
| 258 | [Sleep with Friends v2.1](https://steamcommunity.com/sharedfiles/filedetails/?id=2686624983) | Snuggles | 1.2M | tagged B42 | no | 3 | Sleep (multiplayer) | H |  |
| 259 | [[HOTFIX for B42.13] Tactical Weapons](https://steamcommunity.com/sharedfiles/filedetails/?id=2324223029) | Bandi232 | 1.1M | tagged B42 | no | 3 | Weapons | G |  |
| 260 | [Spear Traps](https://steamcommunity.com/sharedfiles/filedetails/?id=2640351732) | co` | 704k | tagged B42 | no | 3 | Traps | G |  |
| 261 | [KATTAJ1 Military Pack [B41/B42MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3470426196) | TTAJ1bl4 | 696k | tagged B42 | yes | 3 | Clothing | G | Needs KATTAJ1 Clothes Core (tested) |
| 262 | [[42.21MP] GoM - Guns of Marz](https://steamcommunity.com/sharedfiles/filedetails/?id=3722134990) | Marz | 673k | tagged B42 | yes | 3 | Firearms | G | Its tracer feature needs a separate Java mod: leave that out; needs [42.20.4MP] Gunworks Framework (3722064198, tested) |
| 263 | [Vehicle Military Zones](https://steamcommunity.com/sharedfiles/filedetails/?id=3436499337) | Пупсич | 649k | tagged B42 | yes | 3 | Vehicle spawns | D | needs Yet Another PZ LIbrary (3624971238, not tested, add to the group) |
| 264 | [Equip Clothing While Moving [B42.20/B42.19/B41]](https://steamcommunity.com/sharedfiles/filedetails/?id=3446510982) | laggyshield | 622k | tagged B42 | yes | 3 | Equip while moving (timed actions) | A |  |
| 265 | [[ Reworked] Madax Weapon Pack - B42](https://steamcommunity.com/sharedfiles/filedetails/?id=2732407704) | EzeePeez | 604k | tagged B42 | no | 3 | Weapons | G | Madax variants are alternatives |
| 266 | [[B42] Drag Bodies Faster](https://steamcommunity.com/sharedfiles/filedetails/?id=3393821407) | Neighz | 594k | tagged B42 | yes | 3 | Corpse dragging | H |  |
| 267 | [[B42] Carry visible generators](https://steamcommunity.com/sharedfiles/filedetails/?id=3390487814) | Deon | 552k | tagged B42 | yes | 3 | Carry generators | G |  |
| 268 | [Long Term Preservation [B42.13]](https://steamcommunity.com/sharedfiles/filedetails/?id=3406392630) | Skittles | 550k | tagged B42 | yes | 3 | Food spoilage | H | Long Term Preservation variants are alternatives |
| 269 | [Vanilla Outfits Expanded](https://steamcommunity.com/sharedfiles/filedetails/?id=3783094058) | Tango | 547k | tagged B42 | yes | 3 | Clothing | G |  |
| 270 | [Buttstroke / Gun Stock Attack [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3394044313) | SurrealPX | 546k | tagged B42 | yes | 3 | Melee from guns | G |  |
| 271 | [W900 Semi-Truck [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3409472393) | Beathoven | 537k | tagged B42 | yes | 3 | Vehicle | D | needs '82 Oshkosh M911 + Military Semi-Trailers (2618213077, tested); needs Tsar's Common Library B42 (3402491515, tested) |
| 272 | [Craft Engine Parts](https://steamcommunity.com/sharedfiles/filedetails/?id=2744114761) | Titoxic | 524k | tagged B42 | no | 3 | Engine parts | A |  |
| 273 | [U.S. M998 Humvee by Papa_Chad](https://steamcommunity.com/sharedfiles/filedetails/?id=3554424111) | Papa_Chad | 506k | tagged B42 | no | 3 | Vehicle | D |  |
| 274 | [Legendary Backpacks](https://steamcommunity.com/sharedfiles/filedetails/?id=3538353228) | Akyrohunter | 504k | tagged B42 | yes | 3 | Backpacks (containers) | G |  |
| 275 | [Slower Sprinters \ B42](https://steamcommunity.com/sharedfiles/filedetails/?id=2716710487) | AZoT | 485k | tagged B42 | no | 3 | Zombies | H |  |
| 276 | [Escape From Tarkov Backpacks [B42.20]](https://steamcommunity.com/sharedfiles/filedetails/?id=3432928943) | Nik | 484k | tagged B42 | yes | 3 | Backpacks (containers) | G |  |
| 277 | [Everything Has a Name](https://steamcommunity.com/sharedfiles/filedetails/?id=2867163008) | Arendameth | 462k | tagged B42 | yes | 3 | Names on zombies / items | H |  |
| 278 | [They Knew [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3387110070) | Afterworlds | 462k | tagged B42 | yes | 3 | Loot | G |  |
| 279 | [Vanilla Clothing Expansion](https://steamcommunity.com/sharedfiles/filedetails/?id=3421271152) | Reconspiracy | 459k | tagged B42 | yes | 3 | Clothing | G |  |
| 280 | [Viperel's Vehicle Spare Parts](https://steamcommunity.com/sharedfiles/filedetails/?id=2712632417) | Viperel | 379k | tagged B42 | no | 3 | Spare parts | A |  |
| 281 | [Trees Have Loot [B41 &  B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=2951270166) | PepperCat | 366k | tagged B42 | yes | 3 | Foraging loot | H |  |
| 282 | [Skully's Zombie Collision [B42.20+]](https://steamcommunity.com/sharedfiles/filedetails/?id=3778511497) | Skully | 345k | tagged B42 | yes | 3 | Zombie collision | H |  |
| 283 | [Specific Loot (KI5)](https://steamcommunity.com/sharedfiles/filedetails/?id=3457132019) | Пупсич | 311k | tagged B42 | yes | 3 | Vehicle loot | D | Needs KI5 packs; needs Yet Another PZ LIbrary (3624971238, not tested, add to the group) |
| 284 | [ModernFirearmsSystem 42.21 (SP/MP)](https://steamcommunity.com/sharedfiles/filedetails/?id=3633421539) | 布偶旧猫 | 307k | tagged B42 | yes | 3 | Firearms | H | Shares files with GaelGunStore (round 1 note) |
| 285 | [[B42.21] Better Flashlights](https://steamcommunity.com/sharedfiles/filedetails/?id=3420478458) | Slobodskoy | 302k | tagged B42 | yes | 3 | Flashlights | G |  |
| 286 | [CDDA Zombies](https://steamcommunity.com/sharedfiles/filedetails/?id=2749928925) | HW_Lover | 295k | tagged B42 | no | 3 | Zombies | H |  |
| 287 | [[42.20.4MP] Vanilla Weapons PLUS - Gunworks Edition](https://steamcommunity.com/sharedfiles/filedetails/?id=3773834525) | Marz | 281k | tagged B42 | yes | 3 | Firearms | G | Needs Gunworks Framework (tested) |
| 288 | [Run and Reload [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3397207461) | SurrealPX | 280k | tagged B42 | yes | 3 | Reload | G |  |
| 289 | [[B42] Madax Weapons Pack - Fixed 42.21](https://steamcommunity.com/sharedfiles/filedetails/?id=3747202678) | shmoodle | 262k | tagged B42 | yes | 3 | Weapons | H | Madax variant |
| 290 | [[B42.20+ MP] Skateboard!](https://steamcommunity.com/sharedfiles/filedetails/?id=3456675747) | RedChili | 257k | tagged B42 | yes | 3 | Skateboard | H |  |
| 291 | [CD: Rottweiler](https://steamcommunity.com/sharedfiles/filedetails/?id=3762296152) | Björn | 232k | tagged B42 | yes | 3 | Dog | H | Needs Companion Dogs (tested) |
| 292 | [Ammo Loot Drop / Zombies Drop Ammo B42](https://steamcommunity.com/sharedfiles/filedetails/?id=3389050623) | Riko Prushka | 219k | tagged B42 | yes | 3 | Zombie loot | G |  |
| 293 | [[B42] Vanilla Firearms Expansion [CLASSIC]](https://steamcommunity.com/sharedfiles/filedetails/?id=3761077099) | Sejbr | 218k | tagged B42 | yes | 3 | Firearms | G |  |
| 294 | [Hoarder's Delight - Box & Carton Bulk Packing [42.21 Stable]](https://steamcommunity.com/sharedfiles/filedetails/?id=3626823538) | Tenhats | 217k | tagged B42 | yes | 3 | Packing recipes and containers | A |  |
| 295 | [Lean & Lie](https://steamcommunity.com/sharedfiles/filedetails/?id=3652012357) | Tchernobill | 216k | tagged B42 | yes | 3 | Lean / lie | G | needs TchernoLib (3389605231, not tested, add to the group) |
| 296 | [Long Term Preservation [42.20]](https://steamcommunity.com/sharedfiles/filedetails/?id=3774789651) | Darkyosh | 180k | tagged B42 | yes | 3 | Food spoilage | G | Variant |
| 297 | [Brita's Armor Pack B42.20+ / Standalone Armor Port & Multilingual Fixes](https://steamcommunity.com/sharedfiles/filedetails/?id=3780298456) | babybobo | 134k | tagged B42 | yes | 3 | Armor (Brita port) | H | B42 port of Brita's Armor Pack (original is B41 only) |
| 298 | [Dynamic Snow for Vanilla Vehicles [B42 MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3781818628) | RNGesus | 124k | tagged B42 | yes | 3 | Vehicle textures | D |  |
| 299 | [Zombie Dismemberment](https://steamcommunity.com/sharedfiles/filedetails/?id=3811483602) | Choko | 117k | tagged B42 | yes | 3 | Gore | H |  |
| 300 | [Brita Weapon and Armor B42 Unified Compatibility Port](https://steamcommunity.com/sharedfiles/filedetails/?id=3777433827) | 적 폐 | 80k | tagged B42 | no | 3 | Weapons + armor (Brita port) | G | B42 port; may need its own dependencies, see column |
| 301 | [Blood Pools & Footprints [B42.20+]](https://steamcommunity.com/sharedfiles/filedetails/?id=3784951301) | Hallucinogen | 74k | tagged B42 | yes | 3 | Blood | H |  |
| 302 | [Proper Ragdolls](https://steamcommunity.com/sharedfiles/filedetails/?id=3821280085) | Boobie | 62k | tagged B42 | yes | 3 | Ragdolls | H |  |
| 303 | [Civil Defense Sirens [B42 SP/MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3750612709) | jbdiablo | 48k | tagged B42 | no | 3 | Sirens | E |  |
| 304 | [Wash Or Rot [B42 SP/MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3674907249) | PepperCat | 31k | tagged B42 | no | 3 | Hygiene | H |  |
| 305 | [[B41/B42] /bin/'s Profession and Skill Based Starting Items](https://steamcommunity.com/sharedfiles/filedetails/?id=2974652138) | ? | 8k | tagged B42 | no | 3 | Starting items by profession | C |  |

## Suggested test groups

Each group can run together: mods that do the same job (two proximity-inventory mods, two moodle icon sets, two lockpicking mods, two cheat menus, two XP-drop mods, two towing mods, two belt-flashlight mods and so on) are in different groups. Required mods are listed under each group; "tested" ones were in an earlier round and simply need enabling again. Load ZeD last, as in rounds 1 and 2.

### Group A: Inventory, loot window and containers (38 mods)

PZ-ClothingUI - Clothing items grid view (B41 + B42 Updated) (2695471997); [42.20] Customizable Containers (2719850086); [FIXED] Proximity Inventory B42.20 COMPATIBLE [SP/MP] (3669550831); Container Tags [B42 + MP] (3066276504); Easy Drop'n'Loot (2871469707); [B42MP] Take Any Amount (3389115640); Extended categories - Better Hoarding! (B42 SP/MP) (3650035249); NeatUI Equipment [42.21] (3790656296); Nick's Inventory Selection Fix (3782920935); [B42/41] Improved Farming Info Window (3470852353); Auto Loot (3392699932); [B42] Nested Containers (3410947298); O.C.D. Inventory (3773985930); [B42, READ DESC] Mutie's Context Menu Icons Expanded & Redrawn (3422112160); Icons Inventory (3718412967); Stack All (2629074154); Addicted To Weight (2604943386); Better Generator Info (3576056135); Known And Collected (2881764317); [B42] Item Details (3477237184); True Weight (3768669395); [B41,B42] Show VHS skills in tooltip (3716522633); [B42] Item Condition Fix (3394609418); [B42] Horticulture (3650168851); Item Rarity UI (Build 41 + 42) (3662387304); Obvious Skill Tapes - highlight useful VHS tapes (3739168410); Farming Expansion B42 (3444499190); Better Clothing Info (3604080281); Show Sowing Season In Seed Tooltip (3404461962); Smarter Storage - Extra Presets (3587884762); Immersive Hotwire (3653092321); [B42/41] Better Clothing Info Comparison (3036830549); Try Before You Wear (3797492691); Container Capacity Indicator [B42] (3789660055); Equip Clothing While Moving [B42.20/B42.19/B41] (3446510982); Craft Engine Parts (2744114761); Viperel's Vehicle Spare Parts (2712632417); Hoarder's Delight - Box & Carton Bulk Packing [42.21 Stable] (3626823538)

Also enable: dane's Library (3715021740, not tested); NeatUI Framework [B42] (3508537032, tested); [B41/B42] Item Condition (2852309899, tested); Starlit Library (3378285185, tested)

### Group B: HUD, moodles, health and XP (26 mods)

Combat Text (B40+B41+B42) (2286124931); Dynamic Traits and Expanded Moodles [B41 & B42] (2459400130); Moodle Quarters [B42] (2854030563); [B42] Mod Manager (3567084868); Moodles in lua [B42.20] (3395171770); [B42] Bigger Character Avatar (3387640099); Dynamic Moodles (3674800555); CH Status HUD (3776182375); Minimal Display Bars + Nutritions + Discomfort [B41/B42.20] (3388844542); Mini Health Plus (3710913197); [B42] Survival HUD (3495906499); Lua Digital Watch Framework (3676456221); [FIXED] Combat Text Patch b42.20 (3775113600); Nested Health Info (3779405481); [B41&B42] Show Wall Health (3002666175); Stairs Alert (3044807092); Large Progress Indicator (2926455909); [B42] Moodle Descriptions Expanded (3389003300); [B42.13+] SimpleStatus-Fixed (3399432867); Simple Moodle Indicators (3402171609); Injury Indicator [B42] (3565698092); [B42MP] Simple Show XP (2891170430); Cone Vision Outline [42.21.0] [SP&MP] (3659137034); Pixel Strike Indicator & Health Bar (3793657917); Mattnetic's Heart Health Meter [B42] (3805849470); Wound Expansion (3819438691)

Also enable: Moodle Framework (3396446795, tested); Mod Load Order Sorter [b42] (3423660713, tested)

### Group C: Character: traits, skills, professions (35 mods)

Evolving Traits World (ETW) + More Traits continuation (2914075159); Efficiency Skill Mod 2 (3374408921); [B41/B42] Toughness Skill (3545533939); RPGSkillTree[42.13][SP] (3621388762); Yaki's Hair Salon (2761200458); First Aid VHS Tapes (3153010942); Ellie's Tattoo Parlor V4 b41/b42 (2735059209); +300 Points Trait (899287010); RYG Progress Indicator (3220040578); Defecation v3.59 (Build 42.20mp+) (1436878551); True Smoking [B42MP] (3423984426); SixthSense (2863908612); Somewhat Traits (3498347699); [B42] OSRS Exp Drops (3391145494); [B42] OSRS XP Drops Retextured (3413529369); Neon moodle levels (3392116408);  Hephas Occupations and Traits (3256482412); Combat Traits (3427091746); Become Desensitized [B42.20 Stable Unofficial SP/MP] (3738669352); Adaptive Traits (3622328997); Skill Book Expansion (3557111695); Exp Recovery for Skill Books (2923554542); Working Knowledge - Lootable Skill Documents (3717099183); Practice Crafting Skills (3765795716); Eat Smart (3456212729); Challenge Traits - Headshots, CDDA, and More [42.21 Stable] (3634630898); This Is Me - More Character Traits (3806020504); The Psychopath Trait [B42.20+ SP/MP] (3736555309); [B42] Mastered Traits (3423601261); Become Brave [B42.20 Stable Unofficial SP/MP] (3738660077); Gyde's Trait Magazines Extended+ (3776852122); Football & Shoving [SP & MP] (3750861914); Martial Arts - Version 2 (3812456765); Instinctive Hearing [B42] (3789584579); [B41/B42] /bin/'s Profession and Skill Based Starting Items (2974652138)

Also enable: Fluffy Hair [B41/B42] (2447729538, tested); Moodle Framework (3396446795, tested); Starlit Library (3378285185, tested); Moodles in lua [B42.20] (3395171770, not tested); Traits As Skills (3784847437, tested)

### Group D: Vehicles, dashboard and mechanics (39 mods)

Better Auto Mechanics [B42.20.4+ MP+SP] (3635856965); Standardized Vehicle Upgrades 3 - Vanilla Addon (3304582091); Standardized Vehicle Upgrades 3 - Core - B42 (3403490889); Another Vehicle Claim System (2957935793); Banger's Retro Car Dashboard [B42] (3739256322); Better Lockpicking (Continued) b42.20+ (3768298886); More Traits Definitive Edition (3799050151); [B42/B41] The Motorious Zone Vehicle Pack (2791656602); '90 Mercedes-Benz Unimog U1550L (2843855721); You drive, I sleep (2830570280); Nepenthe's Colored Engine Status (Now a vanilla feature in B42) (2975204120); Nepenthe's Colored Battery Status (Now a vanilla feature in B42) (2973053380); [B41 / B42.12+] bikinitools - independent vehicle spawner, skin changer and automations! (2634426926); Autotsar Motor Club B42 (3404737883); Autotsar Trailers B42 (3402493701); [B41/B42] More Immersive Vehicles (3162566044); RV Interior Expansion [B42] (3618427553); Autotsar Bus B42 (3402812859); RV Interior Expansion Part 2 [B42] (3622163276); Better Car Physics (2909035179); Dismantle Any Car (3428369137); [B42MP] FlipVehiclePlusTrailer (3430172149); [B42] UH-1B Helicopter (Beta) (3409723807); [B42.21+ MP] - Push Vehicle (3780639614); [B42.19] Filibuster Rhymes' Certified Used Cars (3683878228); [B42.20+] Vehicle Aim Roof Fix (3781616141); Old moodles +new [B42+] (3386486141); True Cargo - Project Full HD (3806955469); Effortless Towing (3442862183); Dash Roamer [B42] (3775809123); Vehicle Ground Guard [B42 SP + MP] (3690308807); NeatUI XP Drop [42.21] (3760545452); [B42.20+] Vehicle Enter/Exit Fix (3785695033); Legendary Professions and Traits (3669469283); Vehicle Military Zones (3436499337); W900 Semi-Truck [B42] (3409472393); U.S. M998 Humvee by Papa_Chad (3554424111); Specific Loot (KI5) (3457132019); Dynamic Snow for Vanilla Vehicles [B42 MP] (3781818628)

Also enable: Tsar's Common Library B42 (3402491515, tested); errorMagnifier (2896041179, tested); [B42]Project RV Interior (3543229299, tested); [B42]Aviation Core (Beta) (3783444342, not tested); NeatUI Framework [B42] (3508537032, tested); Yet Another PZ LIbrary (3624971238, not tested); '82 Oshkosh M911 + Military Semi-Trailers (2618213077, tested)

### Group E: Map, radio and TV, main menu, mod list, options (42 mods)

More Builds (515555911); Darker Map (2939187818); Military Grid Reference System For Map Callouts Cause You And Your Friends Get Lost Easily (2928660831); Hide Menu Debug + Remove Build Information (3554048011); Better Server Settings (2756434288); Spawn Selector [B42 Stable] (3772052709); True Moozic B42+  The Music System for Project Zomboid (SP/MP) (3632610172); TwisTonFire - Improved Soundoptions (3575778063); TwisTonFire - Map Improvements (3627539752); B42 Native ModOptions Example (3386860561); Workshop Update Checker (3628835042); Mod Comparer (3019672735); No Welcome Window [B42.21+] (3389338537); [B42+]L4D2 Zombie Siege Background Main Menu [16:9+21:9] (3388808256); Cheat Menu: Reloaded [B42 Fixed] (3683918273); Neat Lockpicking (3783535220); TwisTonFire - minimap (3572564421); [B42]Mod Folders (3779201168); Proximity Inventory (3740165370); Project Writing [42.21] (3796402502); Radio Frequency Manager [B42] (3659543622); Retro Dashboard Digitals (3743082626); Yaki's BarberShop (2810471370); Map Symbols Plus (Hand-drawn) (3399645148); [B42] Custom Map Labels (3559737194); Map Symbols Plus (Stensil) (3395592779); [B42] More Item Information (3494474677); [B42.20] Plain Moodles Redone (3772979228); Better Safehouse [B42.20- MP] (3634569678); More Maps [B42] (3390897023); Voiced Radio and TVs (2950750587); Map All Known Fix [B42] (3785198639); [B42] Briefing (3565244378); Better Daily Reports (3580557206); TwisTonFire - Quick'n'Auto Mark (3579410548); [B42 STABLE] Expanded Professions (3440958051); [B42] Functional TV Movies & Series - Framework (3685672179); GPS Cross-Device - ProjectZomboidMap.com (3793289804); Functional Pager - Immersive Map-Wide Communication [B42] (3744455714); [B42.16+] XP Gain Bar v1.4 - DBD (3656128167); Auto Center Map (3790912405); Civil Defense Sirens [B42 SP/MP] (3750612709)

Also enable: NeatUI Framework [B42] (3508537032, tested)

### Group F: Context menu, hotbar, belt slots, equipment, crafting (42 mods)

[B42] Noir's Rifle Slings (3388107363); [Deprecated] What can I craft? (3390169945); [B42] Simple Belt Flashlight! (Fix for angled flashlight) (3625933422); Quick Item Action (2642486124); Context Menu Icons (3634921455); Choose Your Spawn! (3287958074); Easy Set Alarm (3566088272); Simple Context Menu Icons (3634921763); Reorder The Hotbar (B42+ Fixed) (3663625294); The Best Lockpicking [B42.21] [MP Ready] (3440867775); Clothing Actions - Radial Menu (2786689104); Cheat Menu Phoenix [B42] [B41 Re-Up] (3453422228); [B42] Intuitive Crafting (3486217110); Darker Map & Satellite View (3571222611); Smart Radial Menu [B42 Stable] (3494108029); Plysken Attachments Reborn (3749848348); [42.13] Zed's Watch Slots (3630525533); Blacklist & Proximity Inventory (3498294068); Context Menu Cleanup (3780688809); Hands: Stow, Equip, Place [B42] (3786918614); Auto Tailoring (3388183573); True Action Dancing B42 (3650071729); Auto Reload (3389448389); Auto Cook (3388721641); Place Anywhere (3613917826); Washing Menus Improved [B42] (3460812542); [B42][MP]MoreMenuOptions (3636171151); True Music Jukebox 42 (3398874593); [B42] [MP] Quick Remove Broken Glass (3669016488); [B41 & B42] Rope Towing (3261334016); True Music Radio 42 (3631572046); [42] Rip All Button In context Menu (3641027178); Devcatt's Furry Moodles [Build 42+] (3392964216); Dismantle All at Once (3761218629); Crafting XP Display (3428715523); [B42.20] Auto All - Cook, Medicine, Read, Clean, Rip, Tailoring, Mechanics, Exercise, Reload, Open & Dismantle (3777237134); Better Corpse Burning (3790089095); Hide Equipped Items (3600186927); Two Weapons on Back [42.21] (3778319798); [B42]Whose Key Is This? (3784348098); Balaclava Slot (3789234614); Area Tasks - Select an area for vanilla tasks [B42] (3793163745)

### Group G: Popular gameplay 1: weapons, clothing, content (41 mods)

[B42]Simple sling mod (2868394326); Equipment UI – STABLE + (3682936016); [B42.20/B42.21] Simple Belt Flashlight+ (Better Flashlights Compatible) (3778709615); Attachments UI [B42] (3816324722); MinimalHotbar (3688576740); Palm Pilot (3776531193); Sandbox Control - Cheat & Creative Menu [B42.21] (3825312974); Night Vision Chucked (2842179206); [B42.20] Carry Visible Items In Hands [WIP] (3749026793); Advanced Trajectory's Realistic Overhaul (3036878362); Common Sense [B42.20+] (3750253491); Skullys Lowerback Dufflebags, Chest Rigs + Fannypack, Container Rebalance [42.20] (3698401476); HEF - Helicopter Event Framework (3672792485); Ping Items! Friends! 42.20 MP Official (3776262249); Inspect Items Framework (3617732907); [B42] MandoDB - Old Moodles Icons + Redrawn (3386409674); Tooltiplib - Tooltip Framework for Modders (3694097672); Bushcraft Gear - Tools [B41/B42] (2423906082); Bushcraft Gear - Rare Weapons [B41/B42] (2432621382); Undead Survivor [B41/B42] (2713921292); Military Ponchos [B42] (2629286881); [HOTFIX for B42.13] Tactical Weapons (2324223029); Spear Traps (2640351732); KATTAJ1 Military Pack [B41/B42MP] (3470426196); [42.21MP] GoM - Guns of Marz (3722134990); [ Reworked] Madax Weapon Pack - B42 (2732407704); [B42] Carry visible generators (3390487814); Vanilla Outfits Expanded (3783094058); Buttstroke / Gun Stock Attack [B42] (3394044313); Legendary Backpacks (3538353228); Escape From Tarkov Backpacks [B42.20] (3432928943); They Knew [B42] (3387110070); Vanilla Clothing Expansion (3421271152); [B42.21] Better Flashlights (3420478458); [42.20.4MP] Vanilla Weapons PLUS - Gunworks Edition (3773834525); Run and Reload [B42] (3397207461); Ammo Loot Drop / Zombies Drop Ammo B42 (3389050623); [B42] Vanilla Firearms Expansion [CLASSIC] (3761077099); Lean & Lie (3652012357); Long Term Preservation [42.20] (3774789651); Brita Weapon and Armor B42 Unified Compatibility Port (3777433827)

Also enable: errorMagnifier (2896041179, tested); KATTAJ1 Clothes Core (3470422050, tested); [42.20.4MP] Gunworks Framework (3722064198, tested); TchernoLib (3389605231, not tested)

### Group H: Popular gameplay 2: world, survival, NPCs, and whole-UI alternatives (42 mods)

Mutie's Context Menu Icons (3101668503); Neat Rocco's UI [B42] (3723726293); Inventory Tetris - Grid Based Items and Equipment Overhaul (3775513231); Equipment UI - Paper Doll Equipment Interface SP/MP [B42.20+] (3780682550); Second Back Slot [B42.20] (3751668602); N3WO Map Overhaul [B42] (3785033563); Horde Night (2714850307); Video Game Consoles (2831786301); Pillow's Random Spawns [B42] (1911132112); [B42MP/B41]Surviving Through Seasons (2753086629); Ladders?! B42.20 SP/MP (Unofficial) (3629835761); [KYR] Real Weather Mod (3051276857); [B41/B42] Cryogenic Winter +Easy/Hard Modes (SP/MP) (2210760610); [B42] Survival (3402516345); [B42] Bandits Creator (3469292499); Plysken Solar Revolution (3725311427); Immersive Blackouts [B42MP] (3607686447); SaucedCarts - Pushable Carts (3651954650); LG Extended Electricity (3779562002); Bandits Extra Options (3412682512); ImmersiveSolarArrays [42.16+] (3647117173); Playable Minigames (Previously Playable Pool) (3716934959); Over the Shoulder (3808805481); Stay With Me [B42 - NPC Companion] (3800989007); Roaming Survivors (3797874733); Sleep with Friends v2.1 (2686624983); [B42] Drag Bodies Faster (3393821407); Long Term Preservation [B42.13] (3406392630); Slower Sprinters \ B42 (2716710487); Everything Has a Name (2867163008); Trees Have Loot [B41 &  B42] (2951270166); Skully's Zombie Collision [B42.20+] (3778511497); ModernFirearmsSystem 42.21 (SP/MP) (3633421539); CDDA Zombies (2749928925); [B42] Madax Weapons Pack - Fixed 42.21 (3747202678); [B42.20+ MP] Skateboard! (3456675747); CD: Rottweiler (3762296152); Brita's Armor Pack B42.20+ / Standalone Armor Port & Multilingual Fixes (3780298456); Zombie Dismemberment (3811483602); Blood Pools & Footprints [B42.20+] (3784951301); Proper Ragdolls (3821280085); Wash Or Rot [B42 SP/MP] (3674907249)

Also enable: NeatUI Framework [B42] (3508537032, tested); [B42] Bandits NPC (3268487204, tested); Companion Dogs [ALPHA] (3740052292, tested)

### Optional: KI5 cars not yet tested

57 KI5 car packs with the Build 42 tag are on disk but have no id in the done list. Rounds 1 and 2 passed about 40 KI5 packs with ZeD's dashboard and Vehicle tab, and they all share KI5's library, so another pass is low value. If wanted, one group of up to 45 (with that DAMN Library, tested) covers them. The biggest: '76 Chevrolet K Series (3161951724, 1.6M), '89 Dodge Caravan (3034636011, 1.6M), '87 Toyota MR2 (3052360250, 1.6M), '91 Geo Metro (3008795514, 1.5M), '99 Ford Crown Victoria Police Interceptor (2971246021, 1.4M), '86 Chevrolet CUCVs (3428008364, 1.4M), '92 Jeep YJ Wrangler (3287727378, 1.4M), '81 DeLorean (3253385114, 1.4M), '87 Chevrolet Suburban (3196180339, 1.4M), '88 Toyota Hilux (3435796523, 1.4M).

## Maps (short separate group)

Maps rarely touch the UI. The ones worth a single load-and-look (map window, Maps tab, spawn list) because they are very popular:

| Map | Subs | B42 evidence | On disk |
|---|---|---|---|
| [Grapeseed [B42 Unstable Remake]](https://steamcommunity.com/sharedfiles/filedetails/?id=2463499011) by Dylan | 2.4M | tagged B42 (says unstable remake) | no |
| [TryHonesty's Tiles B41 & B42](https://steamcommunity.com/sharedfiles/filedetails/?id=2844685624) (tiles many maps need) | 1.4M | tagged B42 | no |
| [[B42] Chestown](https://steamcommunity.com/sharedfiles/filedetails/?id=2840889213) by poopmans | 1.3M | tagged B42 | no |
| [Rabbit Hash, KY [B42+ Update]](https://steamcommunity.com/sharedfiles/filedetails/?id=2815966702) by Haragon | 711k | tagged B42 | no |
| [LV International Airport [B41/B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3045726312) | 589k | tagged B42 | no |
| [Petroville [B41/B42 LITE]](https://steamcommunity.com/sharedfiles/filedetails/?id=2886261613) by Petrovick | 517k | tagged B42 | no |
| [Louisville Quarantine Zone [B41/B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=2934132344) by Erika | 512k | tagged B42 | no |
| [Tikitown & Powerplant](https://steamcommunity.com/sharedfiles/filedetails/?id=3037854728) by Drazion | 488k | tagged B42 | no |
| [Cedar Hill B41 & B42 Alpha](https://steamcommunity.com/sharedfiles/filedetails/?id=2915656059) by Try Honesty | 466k | tagged B42 | no |
| [Constown (B42)](https://steamcommunity.com/sharedfiles/filedetails/?id=3480990544) | 456k | tagged B42 | yes |
| [Taylorsville [B41/B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3134394569) by Erika | 426k | tagged B42 | no |
| [RaccoonCityB42](https://steamcommunity.com/sharedfiles/filedetails/?id=3388468313) | 415k | tagged B42 | yes |
| [Raven Creek B42](https://steamcommunity.com/sharedfiles/filedetails/?id=3484263516) by BuchoJefe (the original Raven Creek is B41) | 378k | tagged B42 | yes |
| [Dawn Town](https://steamcommunity.com/sharedfiles/filedetails/?id=3666180085) by Rocco | 292k | tagged B42 | yes |
| [Maplewood [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3644794945) by Kyber (a hosting guide could not verify it) | 183k | tagged B42 | no |

Note: map mods that change the spawn list are worth one look at ZeD's new-game screens. Spawn Selector and Choose Your Spawn are in the main table for that reason.

## Skipped and why

**Java, ZombieBuddy or other engine patches (director's rule)**
- [Project Viewpoint](https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528) (759k, on disk): requires ZombieBuddy. So do its add-ons: 6244 3D models for Viewpoint (3810302175), 3d Blood VFX for Viewpoint (3811472160), Project Viewpoint QOL (3811256204), Viewpoint - Interface (3812616893), Project Viewpoint Minimap (3810179295), Viewpoint True Ballistics (3812864848), Project Viewpoint: Recoil & ADS (3812612054), Viewpoint - Visible Loot (3818189653), Viewpoint - Immersive Effects (3812984535), Project Viewpoint - Immersive Driving (3817413313), Bandits Radio Expansion "Project Viewpoint+" (3630494926).
- [[B42] ZombieBuddy Extensions](https://steamcommunity.com/sharedfiles/filedetails/?id=3807686870) (299k).
- Knox Event Expanded NPC mod (3397396843, 174k): its page says it needs ZombieBuddy. Tow Truck [B42] (3446203945, 121k): its page says Java files are mandatory. Musical Menu Framework (3173081439, 186k): its page says it needs a Java mod.
- On disk and needing ZombieBuddy (mod.info): Better Vehicle Dynamics (3728775267), Knox Survivors (3749727604), Shoot to Thrill (3813032735), VSGirlBody (3640496116).
- On disk and shipping Java class or jar files: [B42]DebugMenu (3386556284, replaces zombie/characters/PlayerCheats.class), B42 Fix Generators Bunkers Skyscrapers (3402067343, IsoGenerator class files), Project Remnants (3738362476, NPCFW.jar), KnoxBridge Runtime (3810025624, jar).
- Customizable Containers (2719850086) stays in the table, but only its Lua mod: its "Capacity Limit Bypass" sub-mod is a jar.

**Build 41 only (popular, but the page or the tag says B41, or the B42 version is a separate item already tested or listed)**
- Mod Options (Build 41) (2169435993; B42 has native mod options). Tsar's Common Library 2.0 [Only for B41] (2392709985; B42 version tested). TchernoLib B41 (2986578314; B42 TchernoLib 3389605231 is in the table's "needs").
- Brita's Weapon Pack (2200148440) and Brita's Armor Pack (2460154811): the page says B42 broke them; B42 ports are in the table (3780298456, 3777433827).
- Filibuster Rhymes' Used Cars! (1510950729): "won't be updated" on that item; the B42 version is Filibuster Rhymes' Certified Used Cars (3683878228, in the table).
- Minimal Display Bars (2004998206; B42 version 3388844542 in the table), [B41] Fuel Side Indicator (2616986064), Item Tweaker API (566115016, title says B42 unsupported), Moodle Framework B41 (2859296947; B42 version tested), Auto Mechanics B41 (2588598892; B42 version tested), Backpack Borders [b41] (2808679062), They Knew [B41] (2725378876; B42 version in table), Snow is water (2704811006; page says it is vanilla in B42), VFE (B41) (2667899942; B42 "Classic" in table), Sapph's Cooking [B41] (2832136889; B42 version tested), Lifestyle B41 (2997342681; B42 version tested).
- [B41] Expanded Helicopter Events (2458631365, 2.5M): no B42 version found; HEF - Helicopter Event Framework (3672792485) is in the table instead. Easy Config Chucked (2529746725, 3.3M): B41 tag, required only by the B41 helicopter mods; unclear on B42, left out.
- More Description for Traits (2685168362, on disk): its own page says it does not work on 42.15+.
- Fancy Handwork (2904920097), True Crouching (2966176354, on disk), True Crawl 3.0 (3008448748, on disk), STALKER Armor Pack (2831715402), Better lockpicking by Aiteron (2368058459; needs the B41 Profession Framework; "Better Lockpicking (Continued)" is in the table): pages say B41 only or "B42 version later".
- True Music (2613146550, 2.4M, on disk): last updated Feb 2023, no B42 statement; True Moozic (3632610172) is its B42 rewrite and is in the table.
- Older B41 favourites with no B42 version found: True Actions (sitting, dancing, talking), Arsenal[26] GunFighter, Craft Helper, Superb Survivors, Hydrocraft, Immersive Medicine, Take A Bath (B42 "Take A Bath And Shower" was tested), Essential Crafting, Rename Containers, Refillable Lighters, Radial Menu API, Easy Packing, Sleeping Bags!, Simple Overhaul: Melee Weapons, Become Desensitized (original), Brutal Handwork (original; a "Build 42 Patch" exists, 3778038193, not added), Clean dirt, Raven Creek (original; B42 version in Maps).

**Server-only or admin tools**
- Log Extender (1844524972), Server Tweaker (2951816996), SSR: Core (1178769629) and SSR: Newsboard, Loja do Servidor / Server Shop (3638990871), Aegis Panel (3766508989).

**Duplicates, outdated or marked dead by their makers**
- OUTDATED: Become Desensitized [B42] (3388017161) and OUTDATED Become Brave [B42] (3388028737): the unofficial 42.20 versions are in the table. Boredom Tweaks (OUTDATED) DONT INSTALL (3392745472), [B42] Sleep On It (OUTDATED) (3392769667), [ABANDONED][B42] Better Sorting (3413005308; Better Sorting is tested), [OBSOLETE] Barricade Option in Menu (3593912571), [DEPRECATED] Disable Build 42 Welcome Panel (3408704797), Extensive Power Rework (no longer supported) (3643765614), Profession Framework B42 Hephas Edition ("Currently Not Working", 3493634160), Multiplayer Bug Fixes [Depreciated] (3627047348), Hot Brass - Ammo Craft [Deprecated] (3637364024), [UNOFFICIAL][B42.13] Proximity Inventory (3624308198; older than the 42.20 forks in the table), [Abandoned] Inventory Tetris - All the Mods (3044609444).
- Wood / metal weight variants (50%, 25%, 75% Wood Weight, Customizable Wood and Metal Weight by Kechna): item numbers only, no UI.
- Translation packs (Chinese packs by As1 Project and others): text only.


## Subscribed but never tested

681 of the Workshop folders on disk have no id in the done list (672 carry the Build 42 tag). Most are content (KI5 cars, clothing, weapons, tiles, maps). 203 of them are in the candidate table above ("On disk: yes"). The most-subscribed ones that are NOT in the table:

KI5 cars on disk and untested: 57 (see the KI5 note above). The rest, most-subscribed first:

| Mod | Subs | B42 tag | Why not in the table |
|---|---|---|---|
| [Mod Options (Build 41)](https://steamcommunity.com/sharedfiles/filedetails/?id=2169435993) | 7.2M | no | B41 only (B42 has native mod options) |
| [Tsar's Common Library 2.0 [Only for B41]](https://steamcommunity.com/sharedfiles/filedetails/?id=2392709985) | 6.4M | no | B41 only; the B42 Tsar's Common Library is tested |
| [More Description for Traits [b41] [Not b42!]](https://steamcommunity.com/sharedfiles/filedetails/?id=2685168362) | 3.2M | yes | Its page says it does not work on 42.15+ |
| [True Music](https://steamcommunity.com/sharedfiles/filedetails/?id=2613146550) | 2.4M | no | content only (no UI hooks expected); fine to add to group G or H |
| [41.78+ Propane Torch Fix [B42 Supported]](https://steamcommunity.com/sharedfiles/filedetails/?id=2883755057) | 1.8M | yes | Item fix, no UI |
| [TchernoLib B41](https://steamcommunity.com/sharedfiles/filedetails/?id=2986578314) | 1.3M | no | B41 only; B42 TchernoLib is listed as a dependency |
| [True Crouching](https://steamcommunity.com/sharedfiles/filedetails/?id=2966176354) | 1.2M | no | B41 only (page) |
| [个人mod汉化](https://steamcommunity.com/sharedfiles/filedetails/?id=2216172287) | 1.2M | yes | Translation pack |
| [No Vanilla Vehicles (B42)](https://steamcommunity.com/sharedfiles/filedetails/?id=2535461640) | 877k | yes | Vehicle spawn change, no UI |
| [True Crawl 3.0 [Updated B41]](https://steamcommunity.com/sharedfiles/filedetails/?id=3008448748) | 822k | no | B41 only (title) |
| [Project Viewpoint](https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528) | 760k | yes | Requires ZombieBuddy |
| [Target Square: On Load Commands](https://steamcommunity.com/sharedfiles/filedetails/?id=2969455858) | 711k | yes | Library |
| [SearchModeAPI](https://steamcommunity.com/sharedfiles/filedetails/?id=2851764922) | 707k | yes | Library (search mode); comes in with mods that need it |
| [[B42MP] Frockin Splendor! Vol.2](https://steamcommunity.com/sharedfiles/filedetails/?id=3411888105) | 702k | yes | Clothing content |
| [Ammo Maker](https://steamcommunity.com/sharedfiles/filedetails/?id=2788256295) | 681k | yes | Crafting content |
| [Clean Ashes](https://steamcommunity.com/sharedfiles/filedetails/?id=2816646537) | 674k | yes | World cleanup, no UI |
| [Yaki's Hair Retexture](https://steamcommunity.com/sharedfiles/filedetails/?id=2787539183) | 648k | yes | Texture only |
| [Erika's tiles](https://steamcommunity.com/sharedfiles/filedetails/?id=3346506593) | 641k | yes | Tiles |
| [Adrenaline - Panic Counters Tiredness [DISCONTINUED]](https://steamcommunity.com/sharedfiles/filedetails/?id=2807001835) | 638k | yes | Discontinued by its maker |
| [TchernoLib](https://steamcommunity.com/sharedfiles/filedetails/?id=3389605231) | 635k | yes | Library; listed as a dependency (Lean & Lie) |
| [[B42MP] Frockin Splendor! Vol.1](https://steamcommunity.com/sharedfiles/filedetails/?id=3307376332) | 622k | yes | Clothing content |
| [Tomb's Wardrobe - Alternative](https://steamcommunity.com/sharedfiles/filedetails/?id=3616536783) | 604k | yes | Clothing content |
| [75% Wood Weight](https://steamcommunity.com/sharedfiles/filedetails/?id=2671262464) | 600k | yes | Item weights only |
| [Climb Down the Rope](https://steamcommunity.com/sharedfiles/filedetails/?id=3000725405) | 587k | yes | Animation |
| [Every Missing Vanilla Food Static Model](https://steamcommunity.com/sharedfiles/filedetails/?id=3322066592) | 533k | yes | Models only |
| [[B42/41] Fix BlowTorch & PropaneTank](https://steamcommunity.com/sharedfiles/filedetails/?id=3044705007) | 529k | yes | Item fix |
| [Nepenthe's Nearby Traps](https://steamcommunity.com/sharedfiles/filedetails/?id=2974760428) | 524k | yes | Small marker on traps; worth adding to group H if room |
| [Yet Another PZ LIbrary](https://steamcommunity.com/sharedfiles/filedetails/?id=3624971238) | 522k | yes | Library; listed as a dependency |
| [Wolf Extraction Quest](https://steamcommunity.com/sharedfiles/filedetails/?id=2987772693) | 522k | yes | Quest content |
| [Jumbo Tree Indoor Fix](https://steamcommunity.com/sharedfiles/filedetails/?id=3774826484) | 514k | yes | World fix |
| [Standardized Vehicle Upgrades 3 - Core](https://steamcommunity.com/sharedfiles/filedetails/?id=3304580957) | 514k | no | B41 tag version of SVU3 Core; the B42 Core (3403490889) is in the table |
| [Hand Crank Flashlights [41.78 and 42.20.2]](https://steamcommunity.com/sharedfiles/filedetails/?id=2897115343) | 511k | yes | Item content |
| [[B42MP] Frockin Splendor! Vol.5](https://steamcommunity.com/sharedfiles/filedetails/?id=3635394848) | 489k | yes | Clothing content |
| [Barricade Hurt Zombies](https://steamcommunity.com/sharedfiles/filedetails/?id=2913137598) | 483k | yes | Combat balance |
| [[B42MP] Frockin Shirts & Ties!](https://steamcommunity.com/sharedfiles/filedetails/?id=3453676250) | 481k | yes | Clothing content |
| [[B42MP] Frockin Splendor! Vol.3](https://steamcommunity.com/sharedfiles/filedetails/?id=3431256608) | 479k | yes | Clothing content |
| [Constown (B42)](https://steamcommunity.com/sharedfiles/filedetails/?id=3480990544) | 456k | yes | Map: in the Maps list |
| [[B42MP] Frockin Splendor! Vol.4](https://steamcommunity.com/sharedfiles/filedetails/?id=3475347500) | 444k | yes | Clothing content |
| [Cheval de frise](https://steamcommunity.com/sharedfiles/filedetails/?id=2927800433) | 444k | yes | Building content |
| [Community Tile Pack](https://steamcommunity.com/sharedfiles/filedetails/?id=3628736763) | 442k | yes | Tiles |
| [[B42MP] Frockin Wiseguys!](https://steamcommunity.com/sharedfiles/filedetails/?id=3538760023) | 430k | yes | Clothing content |
| [RaccoonCityB42](https://steamcommunity.com/sharedfiles/filedetails/?id=3388468313) | 415k | yes | Map: in the Maps list |
| [Simple Silencers](https://steamcommunity.com/sharedfiles/filedetails/?id=3309896124) | 402k | yes | Weapon content |
| [Rocco's Tiles](https://steamcommunity.com/sharedfiles/filedetails/?id=3666137359) | 393k | yes | content only (no UI hooks expected); fine to add to group G or H |
| [Tomb's Player Body - Goth Skin](https://steamcommunity.com/sharedfiles/filedetails/?id=3531765630) | 392k | yes | content only (no UI hooks expected); fine to add to group G or H |
