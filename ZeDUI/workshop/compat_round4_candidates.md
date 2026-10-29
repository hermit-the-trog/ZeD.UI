# Compatibility round 4: popular Build 42 mods ZeD has not been tested with

Survey date: Oct 29 2026. Read-only: no game launch, no edit to any mod or to ZeD, no subscribing, Steam signed out. Nothing here is a test result.

## How this was made

- "Done" list: every Workshop id in `compat_round3_candidates.md`, `compat_round3_results.md` and every file under `steam_threads/`. 646 ids with 10 digits plus 3 older ids with 9 or fewer digits (515555911 More Builds, 566115016, 899287010). The ZeD item itself (3824968485) is in that set. Anything in it was left out.
- Browse pages read, 30 items a page: Most popular over 30 days with the Build 42 tag, pages 1 to 6; Most popular over 7 days with the Build 42 tag, pages 1 to 6; Most subscribed with the Build 42 and Interface tags, pages 1 to 3. That is 15 pages and 450 listings (about 436 different mods).
- 321 listings were not in the done set. A first pass counted More Builds (1.25M subscribers) as new because its id has only 9 digits; it is already round 3 item 2, so it is out. That leaves 320 mods not yet tested.
- Detail pages: the cap was 40, so 40 were opened, picked for the likelihood that they touch a ZeD surface (inventory, crafting and build menus, map, moodles and health, context menu, main menu, mod manager) and for trend rank. The other 280 are in the last list, id and title only, with the browse list and page they came from (t30 = 30-day trending, t7 = 7-day trending, subp = Interface most subscribed).
- Subscriber figure = "Current Subscribers" in the stats box. Dates are the "Updated" line (or the posted date if never updated). "Tagged B42" = the Build 42 tag on the page.
- Java check: the description and the "required items" list were searched for ZombieBuddy, .jar and Java. Mods that need ZombieBuddy or ship a jar are under "Skipped".
- "On disk" = a folder named with the id exists in `E:\Project Zomboid\steamapps\workshop\content\108600`.
- Steam rate-limited the signed-out pane twice during the page reads ("too many requests"); I waited it out and carried on. A few pages were read through the page's own fetch rather than by loading each one in the pane; the content is the same pages.
- Caveat on the ranking: the trending lists favour new mods. The large old mods that dominate Most Subscribed were mostly already in rounds 1 to 3, so what is left is new or mid-sized (up to 290k subscribers). Only the 34 mods in the table have a subscriber count; the 280 unopened ones have none.

## Candidates (34), ranked by subscribers

| # | Mod | Author | Subs | B42 evidence | UI surface touched | Needs ZombieBuddy / Java | On disk |
|---|---|---|---|---|---|---|---|
| 1 | [Building Craft](https://steamcommunity.com/sharedfiles/filedetails/?id=3459887404) | 十叁 | 288,890 | tagged B42; updated Oct 24 | Build menu (tags Building, Framework, Interface) | no | yes |
| 2 | [Neat Crafting & Neat Building - XP & Mod Display](https://steamcommunity.com/sharedfiles/filedetails/?id=3540503606) | Afyrmo | 275,146 | tagged B42; updated Oct 15; text says B42.12 and B42.21 | Crafting menu and build menu (XP and mod name shown in the lists). Needs NeatUI Framework, Neat Crafting, Neat Building | no | yes |
| 3 | [[B42.21] The Only Cure](https://steamcommunity.com/sharedfiles/filedetails/?id=3580276809) | Pao | 270,471 | tagged B42; title B42.21; updated Oct 24 | Medical and health gameplay; carries the Interface tag, which panel was not confirmed | no | yes |
| 4 | [Kilometers Per Hour](https://steamcommunity.com/sharedfiles/filedetails/?id=2980583716) | Braven | 194,079 | tagged B41 and B42; last update Dec 22 2024 | Vehicle speed readout (tags Interface, Vehicles) | no | yes |
| 5 | [Disable Welcome Message](https://steamcommunity.com/sharedfiles/filedetails/?id=1924146603) | star | 110,366 | tagged B41 and B42; last update Dec 24 2024 | Start-up welcome message on load (tag Interface) | no | no |
| 6 | [The Only Cure+ (Field Surgery)](https://steamcommunity.com/sharedfiles/filedetails/?id=3818733381) | NEXCONKER | 56,033 | tagged B42; updated Oct 22 | Medical items, field surgery actions, clothing; 419 MB | no | yes |
| 7 | [Better World Map](https://steamcommunity.com/sharedfiles/filedetails/?id=3794379457) | EROGZ | 33,737 | tagged B42; updated Oct 26; text says 42.20+ | Map: POI dots and labels on world map, paper map and minimap | no | no |
| 8 | [Mod Load Order Sorter Extension](https://steamcommunity.com/sharedfiles/filedetails/?id=3809995878) | Kaoeutsu | 28,176 | tagged B42; updated Oct 11 | Mod load-order screen (bigger window and extras). Needs Mod Load Order Sorter [b42] (3423660713, done) and Mod Manager Extension | no (a ZombieBuddy add-on is offered and is optional) | no |
| 9 | [Knox Packs: Upgradable Backpacks](https://steamcommunity.com/sharedfiles/filedetails/?id=3822813865) | SA_AS | 23,087 | tagged B42; updated Oct 28; text says 42.21 | Backpacks: capacity and sewn upgrades (inventory weight and container size) | no | yes |
| 10 | [Better Building Plus [B42 MP]](https://steamcommunity.com/sharedfiles/filedetails/?id=3812970899) | RedChili | 21,107 | tagged B42; updated Oct 28; tagged WIP | Build planning and menu (tags Building, Interface). Needs RC's Structures Framework | no | no |
| 11 | [Locksmith - Padlocks, Lockpicking, & Re-pinning [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3797292945) | avenoir | 15,772 | tagged B42; updated Oct 23 | Context menu (lock, pick, pry, cut keys); keys as items (tag Interface) | no | no |
| 12 | [Survivor PDA - RPG Skill Tree, Traders & Missions [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3826426915) | Batoonchi | 15,582 | tagged B42; updated Oct 29 | Its own hand-held device window on K with tabs (skill tree, traders, mail); 86 MB | no | no |
| 13 | [This Is Your Life - Character Creator Overhaul [B42.21]](https://steamcommunity.com/sharedfiles/filedetails/?id=3796139100) | MysticaUmbra | 14,415 | tagged B42; updated Sep 21; built for 42.20+ | Character creation screen. Needs This Is Your Life [B42 Stable] WIP and Modded Clothing Dataset Compatibility | no | no |
| 14 | [SideWinder's Placement+](https://steamcommunity.com/sharedfiles/filedetails/?id=3796440093) | Side Winder | 11,993 | tagged B42; posted Sep 5, never updated; text says 42.20.4 | None found: wall decorations sharing a tile (world placement) | no | no |
| 15 | [Loot Tracker](https://steamcommunity.com/sharedfiles/filedetails/?id=3823828778) | willy_theBean | 10,955 | tagged B42; updated Oct 28 | Map and minimap overlays (visited and looted building colours, restock timer); adds Proximity Inventory support | no | no |
| 16 | [Item Arrange Extension](https://steamcommunity.com/sharedfiles/filedetails/?id=3813943783) | Kechna | 10,735 | tagged B42; updated Oct 27 | Placing and arranging items in the world; needs [B42.20] Item Arrange. Which menus it adds was not confirmed | no | no |
| 17 | [GarageWorks [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3827271522) | telvary | 9,291 | tagged B42; updated Oct 29; text says 42.21 | None: furniture that holds vehicle parts lighter (tags Building, Vehicles) | no | no |
| 18 | [PZ Relationship (Build 42)](https://steamcommunity.com/sharedfiles/filedetails/?id=3820590495) | BostonTee | 8,800 | tagged B42; updated Oct 26 | Right-click menu on other players, an accept/decline box, moodle (needs Moodle Framework); multiplayer; 314 MB | no | no |
| 19 | [DIY Gear - Craft Weapons, Armor, Tools & Parts](https://steamcommunity.com/sharedfiles/filedetails/?id=3820870164) | Phinn | 7,487 | tagged B42; updated Oct 23; text says 42.21 | Crafting menu (many new recipes) | no | no |
| 20 | [PM2 - Complete Repair Overhaul](https://steamcommunity.com/sharedfiles/filedetails/?id=3802480042) | CakeDayZ | 6,636 | tagged B42; updated Sep 27 | Repair actions and item condition; which menus it changes was not confirmed | no | no |
| 21 | [SpiffBoy [B42.21+]](https://steamcommunity.com/sharedfiles/filedetails/?id=3825220364) | OhHoop | 6,465 | tagged B42; updated Oct 26; text says 42.21 and 42.22 | A hand-held console item with its own 180x120 pixel screen window | no | no |
| 22 | [Crosshair Overhaul](https://steamcommunity.com/sharedfiles/filedetails/?id=3814251221) | hogggriiddaaaa | 2,531 | tagged B42; updated Oct 14 | Aiming crosshair on the HUD; settings on the Options > Mods page | no | no |
| 23 | [More Simple Context Menu Icons](https://steamcommunity.com/sharedfiles/filedetails/?id=3795593080) | Kaoeutsu | 2,437 | tagged B42; updated Oct 23 | Right-click menu icons; needs Simple Context Menu Icons | no | no |
| 24 | [Viewpoint Clean UI](https://steamcommunity.com/sharedfiles/filedetails/?id=3826157418) | Bobi Da Baja | 1,994 | tagged B42; updated Oct 27; text says 42.21 | Replaces equipment, inventory, health, skills and character info with one menu (moodles inside it). Page lists no required item; its text mentions ZombieBuddy only for Project Viewpoint's own HUD | no (confirm before testing) | no |
| 25 | [Silent Hill 2 OG Main Menu Background](https://steamcommunity.com/sharedfiles/filedetails/?id=3804255753) | SQz_ | 1,143 | tagged B42; updated Sep 28; text says 42 | Main menu background video; installed by hand (copy a .bik file); 71 MB | no | no |
| 26 | [Vital Signs: The 1993 Pocket Notebook](https://steamcommunity.com/sharedfiles/filedetails/?id=3819507580) | JGuar | 1,055 | tagged B42; updated Oct 26 | Removes the mood icons (moodles) and puts needs, body and wounds in a pocket notebook | no | no |
| 27 | [Item Details Panel](https://steamcommunity.com/sharedfiles/filedetails/?id=3826420021) | DarMeao Haaaa! | 803 | tagged B42; updated Oct 28; text says 42.20+ | Extra panels beside the item tooltip (weapon, ammo, clothing coverage, liquids); tags Framework, Interface | no | no |
| 28 | [Loose Ends: Scenario Editor, Game Master & Story Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3824292323) | nullTrace9342 | 272 | tagged B42; updated Oct 24; text says 42.20 | In-game visual scenario editor windows; radio-delivered stories | no | no |
| 29 | [Ente's Auto Sorter - Inventory/Base/Cars](https://steamcommunity.com/sharedfiles/filedetails/?id=3827432728) | Ente | 264 | tagged B42; updated Oct 28 | One-click sort of carried items into containers (inventory); needs Better Containers | no | no |
| 30 | [Extensive health redone](https://steamcommunity.com/sharedfiles/filedetails/?id=3824731938) | Wartank | 165 | tagged B42; updated Oct 26; text says 42.21 | Health and medical (diseases, blood, medication); which panel it touches was not confirmed | no | no |
| 31 | [Drag And Drop (Item Placements)](https://steamcommunity.com/sharedfiles/filedetails/?id=3828392514) | Crypt Voice | 133 | tagged B42; updated Oct 27 | Inventory: drag an item out to place it in the world; says it works with Inventory Tetris | no | no |
| 32 | [Farm Panel Plus (B42)](https://steamcommunity.com/sharedfiles/filedetails/?id=3826624859) | Lebanon | 98 | tagged B42; updated Oct 26; text says 42.21+ | Its own farming panel on Ctrl+G (crops, water, sickness) | no | no |
| 33 | [SpiffBoy SDK [B42.21+]](https://steamcommunity.com/sharedfiles/filedetails/?id=3825220785) | OhHoop | 67 | tagged B42; updated Oct 25 | None: cartridge kit; needs SpiffBoy | no | no |
| 34 | [Knox Companion: Squad Tablet & Live Map](https://steamcommunity.com/sharedfiles/filedetails/?id=3826373926) | hicaku | 21 | tagged B42; updated Oct 26 | Tablet item, map; links the save to an outside web map (online) | no | no |

Rows worth testing first, by how close they sit to a ZeD surface: 24 (Viewpoint Clean UI, a whole-menu replacement), 26 (Vital Signs, replaces moodles), 27 (Item Details Panel, beside the item card), 1, 2 and 10 (build and crafting menus), 7 and 15 (map), 8 (mod manager), 25 (main menu), 13 (character creation), 28 (editor windows), 12 and 21 (own device windows).

## Parallel UI mod: Xen's Enhanced GUI (XEG)

[3819012597](https://steamcommunity.com/sharedfiles/filedetails/?id=3819012597), author Xen. Read Oct 29 2026.

- Current subscribers: 2,662 (7,912 unique visitors, 438 current favourites).
- Posted Oct 13; last updated Oct 26 @ 2:22pm. Size 23.1 MB.
- Tags: Build 42, Framework, Interface, QoL. Page says "Required mods: None". ZombieBuddy is optional (it turns on a 3D main-menu room); Project Viewpoint is optional.
- Not in the done set (it is not in any file read). Not on disk.
- Page text: modular UI overhaul covering main menu, load and character-creation screens, interface and quality-of-life features; each part can be switched off.

## Skipped

Needs ZombieBuddy or ships Java (not opened further):

- 3816775774 [B42] Knox Inventory - Tarkov-style UI Overhaul (SYNTHETIK, 20,999 subs): requires ZombieBuddy and ships KnoxInventoryJava.jar. Replaces the inventory.
- 3826791028 [B42] Knox Inventory - NO TETRIS addon (.Veles, 237 subs): requires the Knox Inventory mod and ZombieBuddy.
- 3826349170 Viewpoint Interface Plus (keicmoi, 2,077 subs): Lua only itself, but needs Viewpoint - Interface, and the page lists ZombieBuddy as required by Viewpoint.
- 3827856889 Viewpoint Wristwatch (TpaBka, 1,846 subs): requires ZombieBuddy 2.3.0 or newer.
- 3827827224 Save Slots [B42] (Aegon Stark, 213 subs): requires ZombieBuddy (copying folders needs Java); single player only.
- 3825215865 1080P UI Scale (muOkO, 26 subs): requires ZombieBuddy and a full game restart; scales overhead text and UI.

Already in the done set (out of this round):

- 515555911 More Builds (ProjectSky, 1,252,531 subs): round 3 item 2. It showed up as new only because its id has 9 digits.

Judged not worth a page read (no UI surface from the title; they stay in the unopened list below): vehicles, maps, guns, clothing, animations, animals, sound and music packs, "Viewpoint" 3D model add-ons, translations.

## Not opened (280): id and title only

Source tags: t30pN = 30-day trending page N, t7pN = 7-day trending page N, subpN = Interface most-subscribed page N. Within a page, order was not recorded. Subscriber counts were not read.

- 3791948588 Cool Sit: Immersive Leaning/Sitting [B42] [t30p4]
- 3792740760 [42.20.+] True Line of Sight [SP/MP] [t30p3]
- 3793663684 Corpse Plow Attachment [t30p4]
- 3793812290 Coffee Fluid! [t30p3]
- 3793875056 Hop Over It! [t30p5]
- 3793950420 Pet Birds [t30p5]
- 3794207681 Fitted Sheets [t30p1]
- 3794233105 Dog Climb Fences Animation Fix [Companion Dogs] [t30p5]
- 3794429489 Skill & Recipe Collector's Shelf [t30p4]
- 3794455791 Tien's Coolers [t30p2]
- 3794777232 [B42] Visible Belts [t30p3]
- 3795508807 Louisville Sniper | New Zone Update!!! [t30p5]
- 3795521454 Realistic Recipes [t30p3]
- 3795847162 Better Fire Extinguishers [B42] [SP & MP] [t30p1]
- 3795855624 Barricades Rebuilt 2.3b [t30p2]
- 3795894742 Jumbo Stumps Done Right [t30p2]
- 3796555164 PZ Circuits [t30p4]
- 3796649124 Shin's Guitar Case & Amplifier Vol.1 [t30p3]
- 3796749784 Relentless Sprinters [t30p5]
- 3797309561 Firesparks Weapon Fix [t30p3]
- 3797356103 Knox Aquarium V2 - Live Fish Tanks, Turtles, Pet Rats & Fishing Overhaul BR Support [B42] (Beta) [t30p5]
- 3797745688 [B42MP] Excavation Indoor Patch [t30p6]
- 3798112588 CD: Rats [t30p2]
- 3798146388 [B42MP] Frockin Backstage! [t30p4]
- 3798149669 [B42MP] Frockin Splendor! Vol.6 [t30p2]
- 3798211972 Can Repair Doors [t30p3]
- 3798908307 Drop Kick [SP] [t30p6]
- 3799111159 [B42] Pants Collection [t30p6]
- 3799314878 Foggy Breath And Gun Smoke [t30p2]
- 3799523320 [42] Fences Fade (SP/MP) [t30p6]
- 3799596085 Visible Door Damage [B42 MP] - Viewpoint compatible [t30p5]
- 3799732653 '83 GMC G-Series Vans [t30p1]
- 3799977254 Pip's Rad Poster Pack [B42.20] [t30p6]
- 3800233932 Snake's ModPack Build 42 [t30p3]
- 3800327079 It's My Story [WIP] [t30p5]
- 3800471544 Sprockets [t30p3]
- 3800671550 ShadowZ [t30p4]
- 3800854843 Pip's Rad Rugs Pack [B42.20] [t30p5]
- 3800858172 Vehicle Armor Crafting [B42] [t30p5]
- 3801328103 Horse Companion for Pat's NPC Project Remnants & Horse Mod [t30p6]
- 3801382099 Gurney Transport: Wheel Them Out [t30p5]
- 3801773907 Coffee System [t30p6]
- 3802372726 True Swimming [t30p5]
- 3802860016 Bruce Lee's Nunchaku [t30p6]
- 3803082912 True Crawling [t30p2]
- 3803108123 True 3D Items - Project Full HD [t30p6]
- 3804093735 BADLANDS Power [t30p5]
- 3804761131 No Pain No Grain [Baseball Bat Retexture] [t30p2]
- 3805221815 Curl Up [t30p1]
- 3805307651 Let Me Drive! - Anti-Stutter Car Controls [t30p4]
- 3805748433 Casualties Undead (Build 42) [t30p4]
- 3805947764 [B42.21] Dynamic Monologue (WIP) [t7p6]
- 3806072658 Real Vending [t30p3]
- 3806513504 Basement Building (Counts as Indoors / Powered / Multi-Level / Expandable / Multilingual / Mid-Save) [B42.21/42.22] [SP/MP] [t30p6]
- 3806944055 Project A-Life - Jeem Extension [t30p4]
- 3807099610 Hug The Plushie! [t30p1]
- 3807334881 pz3d - Atmospheric Vanilla PZ in 3D [t30p5]
- 3807554391 Restless Waters [B42] [t30p5]
- 3807705597 Barricade The Door [t30p2]
- 3807707103 Radio Trader B42 [t30p2]
- 3808150913 HydeCo. Squirrels! 42.21.0 [t30p2]
- 3808152720 [B42] Dynamic Gear Rattling [t30p2]
- 3808688990 CD: Belgian Malinois [t30p3]
- 3808810941 [42.20]Fanny Pack & Chest Rig(Webbing) Fix [t30p6]
- 3808848579 Rooster Crow [t30p1]
- 3809600807 Mandarin's Bedding - Blanket Warmth [t30p3]
- 3809762635 Throwables 2.0 (BETA) [t30p6]
- 3809817126 Bunnies [t30p2]
- 3809993153 Nick's Moveable Workstations - Furniture Fix [t30p6]
- 3810188405 Sewers Under Every Town (Build 42) [t30p3]
- 3810261246 Training Target - Shooting Range & Training Dummy [t30p5]
- 3810480916 Throw Anything [t30p6]
- 3810876724 Remove & Install Doors [B42.21] - Single & Double Doors [t30p4]
- 3811471690 HydeCo. Knox Underground! 42.21.0 [t30p3]
- 3811679237 HydeCo. Frogs! 42.21.0 [t30p4]
- 3811680191 HydeCo. Robins! 42.21.0 [t30p6]
- 3811987208 Chinook [t30p3]
- 3812024929 '92 Volkswagen Golf Mk2 [t30p2]
- 3812222734 Cummins Onan 12.5JC Generator [t30p6]
- 3812718124 [V2] More Car Variants (KI5) [t30p6]
- 3812799224 Time Control MP - True Pause & Fast-Forward [B42] Multiplayer [t30p6]
- 3813029846 HydeCo. Job Fair! 42.21.0 [t30p4]
- 3813053718 Useful Pallets [t30p1]
- 3813172420 Project Viewpoint: KK's TREE in 3D (Animated & Seasonal) [t30p5]
- 3813362974 They Knew Continued [t30p4]
- 3813406470 Cry of Fear Monster NPCs [Beta] [t30p2]
- 3813489363 SMB steps [t30p1]
- 3813658145 Live to Fight Another Day: CHAPTER 2 "Out There." [t30p2]
- 3814086500 Nyx Hunter - MRAP [B42] [t30p5]
- 3814398576 Surface Fix - Project Viewpoint [t30p4]
- 3814484099 colinel's Division Gadgets [t30p3]
- 3814843526 Spongie's Character Customisation - Extras [t7p5]
- 3814994364 Viewpoint Foraging [t30p6]
- 3815128534 Lost Province [B42] [t30p1]
- 3815188080 Shin's Victorian Fashion Vol.1 [t30p5]
- 3815617457 HydeCo. Orchard! 42.21.0 [t30p3]
- 3815843875 True Helicopter Events [t7p2]
- 3815950578 Flesh & Blood: The 1993 Bodies [t30p4]
- 3815999052 OldPoint - Rotating Overhead Camera [B42 / Viewpoint] [t30p3]
- 3816083168 Hardship: Inertia [t30p6]
- 3816175183 Big Bear Lake [ALPHA] [B42] [t30p1]
- 3816309551 True Sleep Everywhere [t30p1]
- 3816310214 Improved Spear Animation [t30p1]
- 3816830877 PZVR [t30p4]
- 3816847772 Extreme Weather [t30p3]
- 3816929371 Gore - Decapitations & Dismemberment [B42.21] [t30p2]
- 3817268210 Zombie Energy Core [t30p4]
- 3817404599 Analog Memories [t30p6]
- 3817841172 Black Division Combat Gear [t30p5]
- 3817970320 Project Translate B42.15+ | Mod Translation (Localization) [t30p6]
- 3818066204 Functional Pallets [t30p4]
- 3818766091 Dirkerdam Integrated B42 [t30p5]
- 3818840339 After The Beep [t30p3]
- 3818853354 Viewpoint - Grassier Grass Port [t30p6]
- 3819163031 Second Back Slot - Carry Two Weapons On Your Back [t30p4]
- 3819478254 Ros's Radical Animal Remaster [t30p3]
- 3819509915 Davy's Real Crosswords [t7p4]
- 3820183693 Guns of Marz Extension: Guns of Tien [t30p3 t7p1]
- 3820188962 Renewable Energy [t7p4]
- 3820629488 Slight Rocking Animation [t30p2]
- 3820861712 DaeguMetropolitanCity [t30p5]
- 3820874081 Motorcycle Cargo - Vans & Pickups [t7p6]
- 3820938264 '67 Chevrolet Impala [t30p1]
- 3820965001 Viewpoint - Visceral [t30p4]
- 3821294884 Leavenburg Riverside Bridge [B42] [t7p6]
- 3821474157 Leavenburg & Jasperville [B42] [t7p6]
- 3821554678 Brief Sprinters [t30p4]
- 3821610732 Viewpoint - 3D Working TVs & Radios [t7p6]
- 3821752171 Silent Hill Monster NPCs [t30p3]
- 3821807453 Live Wire - Electrical Skill Overhaul [t7p5]
- 3822634333 Project Viewpoint Translation Pack [B42.21] [t7p5]
- 3822736890 [RKC]LV-93 Business Jet (Based on Learjet 60) - Flyable Airplane [t30p5]
- 3822997517 Modular Metal Shelves [B42] [t7p5]
- 3823224669 PZHT - First Person + Graphics & Gameplay Overhaul + Head Tracking [t7p5]
- 3823265327 Persistent Remains [t7p3]
- 3823808773 Weeping Sprinters [t7p6]
- 3823819502 T-90A "Vladimir" - crewed main battle tank [t7p4]
- 3823831569 WW1 Weapons [t7p2]
- 3823941212 Martial Arms [t7p4]
- 3823941573 Operator Gear [B42.20] [t30p5 t7p2]
- 3823956410 Max Time In Server [t7p5]
- 3823978904 Barricades 3D (Viewpoint) [t7p6]
- 3823979843 Ceiling Lights (Viewpoint) [t7p4]
- 3824047133 Dynamic Facial Expressions [t7p3]
- 3824135338 Ada Wong - Tomb's Player Body [t7p3]
- 3824214320 SKATE IMPACT [42.21+MP] [t30p5 t7p1]
- 3824318437 Blazed & Confused: A Cannabis Overhaul [t7p5]
- 3824338280 M270 MLRS [t7p4]
- 3824338636 M142 HIMARS [t7p3]
- 3824344925 WW1 Uniforms [t7p4]
- 3824354252 Visible Vehicle Coupling - Viewpoint Addon [t7p5]
- 3824370812 CIC M1126 Stryker [t7p5]
- 3824394933 Off the Rack: The 1993 Bags [t7p3]
- 3824443052 Stay With Me Korean translation (B42) [t7p6]
- 3824459820 Build Your Own Kayak [B42] [t30p4 t7p1]
- 3824463369 [RKC]BOEING 737-200 / RV-HOPE [t7p2]
- 3824469313 Nikke [t7p5]
- 3824501090 Mustang GT + Engine Sound [t7p4]
- 3824513256 Skyline GT-R R34 + Engine Sound [t7p3]
- 3824520446 A-Life and Jeem Simplified Chinese translation [B42] [t7p5]
- 3824738256 PZ Life Stages [t30p6 t7p2]
- 3824755284 Escape From Zomboid Firearms [t7p1]
- 3824762102 Project A-Life x Stay With Me - Compatibility Patch [t7p4]
- 3824764771 Burners: Charred Zombies [t7p4]
- 3824812561 Fort Redstone B42 [t7p3]
- 3824826320 Viewpoint - 3D Military Armory [B42.21] [WIP] [t7p1]
- 3824848843 Project A-Life: Louisville Checkpoint Garrison [t7p4]
- 3824857053 Rule #18: Limber Up - Stretching That Heals Muscle Strain [B42] [t7p3]
- 3824936355 Gloc's Portable Workstations [B42] [t7p6]
- 3824965917 ForkLift (Build 42.21+ Update) [t7p1]
- 3824968544 Xanny Arms - Sound Volume [t7p3]
- 3825006570 Loose Ends: The Hale Feud [t7p3]
- 3825053092 Viewpoint - Render Distance [t7p5]
- 3825053877 Gore Crawlers & Torn Zombies [t30p5 t7p1]
- 3825080284 [A&M] GirlStink [t7p4]
- 3825082626 Eerie Country [B42] [t7p4]
- 3825097290 M56 Smartgun ALIENS [B42] [t7p5]
- 3825142556 Russian Music Pack by Hornet [B42] [t7p5]
- 3825192271 Frockin Loot Balance [B42] [t7p1]
- 3825208209 Nellis Air Force Base Fixes [B42] [t7p2]
- 3825235994 Bonneville Bobber [t7p5]
- 3825287661 Urla - A dog mod (Beta) [t7p5]
- 3825355680 Escape From Zomboid Firearms Simplified Chinese translation [t7p2]
- 3825431297 Plysken Sensors & Traps [t7p3]
- 3825432125 Spencer Estate (No Hive), KY [t7p6]
- 3825500218 FTZ Helicopters [B42] [BETA] [t7p2]
- 3825500587 FTZ Flying - Helicopter Flight System [B42] [BETA] [t7p2]
- 3825583958 Knox Event Expanded More Presets [t7p6]
- 3825586608 RefugeZ Motorcycle Pack [B42 - MP/SP - WIP] [t7p3]
- 3825638448 Knox Network Tactical Gear [B42] [t7p2]
- 3825674087 TIJUANA MAP-BETA [t7p3]
- 3825682908 Railings 3D (Viewpoint) [t7p3]
- 3825704626 Wildwrought: Electricity [t7p2]
- 3825705636 Clothes HD [t7p3]
- 3825722984 toot's Base Defense [t7p1]
- 3825724093 DeadWorks Vehicle Framework [B42.21] [t7p2]
- 3825771124 M1A2 Abrams [t7p2]
- 3825812871 ProcTown - Procedural World [t7p1]
- 3825832401 Mod scheduling and optimisation pack (SuSir, Chinese) [t7p2]
- 3825887189 Armored 4Runner - Rounded Revision [B42] [t7p2]
- 3825887223 Nomad Armored RV [B42] [t7p1]
- 3825887259 Overland Cruiser 250 - Roof Tent and Hatch [B42] [t7p2]
- 3825976597 Detailed Vanilla Models - Part 1: Lights & Bags [t7p1]
- 3825978464 View Distance Extension for Grassier Grass (Viewpoint) [t7p5]
- 3826075054 PZ PLAYGROUND [t7p5]
- 3826112169 Tool Watches [t7p6]
- 3826175971 Viewpoint [The Motorious Zone Vehicle Pack Interiors] [t7p3]
- 3826176290 Project Viewpoint - Drive-By Shooting [t7p2]
- 3826222476 Vanilla Cannabis [t7p4]
- 3826228411 Fuel From Farming [t7p2]
- 3826328952 Golf Cart [t7p4]
- 3826430751 Old School Magic Cards [t7p4]
- 3826458381 Viewpoint Smooth 3D [t7p5]
- 3826464295 Primitive Stone Crossing [t7p3]
- 3826471854 [B42.21] Terminator-Style Lever Spin - Vanilla + GoM [t7p6]
- 3826482711 Firespark Saved My Animals [t7p1]
- 3826550325 Viewpoint Vehicle Interiors [t7p1]
- 3826564551 Senators Dead Ink [t7p2]
- 3826615028 NEXUS BAGS OF HOLDING (SP/MP 42+) [t7p6]
- 3826650541 KI5 Engine Sounds [t7p1]
- 3826681202 Smooth Performance Optimizer [t7p6]
- 3826707195 Realistic HD Textures - Coming Soon [t7p2]
- 3826724079 Diesel Fuel '93 [t7p4]
- 3826727409 90s Knit Sweaters [t7p6]
- 3826743329 MH-X Silent Hawk [t7p5]
- 3826821328 BloodMoon|7Days [t7p4]
- 3826832381 [B42] JeepGladiator [t7p2]
- 3826882498 MH-6 Little Bird [t7p4]
- 3826905912 Tame the Dead [t7p3]
- 3827001699 FTZ Burn Dumpster [B42] [t7p2]
- 3827055860 [B42.21.0] MIAO (Chinese) [t7p2]
- 3827190227 FrostPack: 80 Days of Winter [t7p6]
- 3827201530 Whiteout - [Compatibility & Gameplay Patch] [t7p4]
- 3827224159 Barebones [t7p3]
- 3827287507 Gilets jaunes - Les sans-pouls [B42] [t7p5]
- 3827348913 It's Quiet, Too quiet. [t30p6 t7p1]
- 3827381192 Toyota Tacoma - Overland Pickup [B42] [t7p2]
- 3827497087 [B42] Tactical Bags by Minidoracat [t7p2]
- 3827516230 Sunflower's Ultimate Character Overhaul (VIEWPOINT SUPPORT) [t7p2]
- 3827710289 Viewpoint - Water Physicality [t7p3]
- 3827714676 EFZ + Recoil & ADS Bridge (DayZ Aiming) [t7p5]
- 3827715702 EFZ Gun Volume [t7p6]
- 3827721851 Pond Keeper - Fischzucht & Kaviar (Fish Farming & Caviar) [t7p2]
- 3827747649 Pink Floyd New Music Pack [t7p6]
- 3827775413 Chinese cold weapons B42 unofficial port [t7p6]
- 3827943865 Project Remnants: Safehouse Expanded [t7p6]
- 3827956263 Detailed Vanilla Models - Part 2: Tools & Melee [t7p1]
- 3827957976 Project Real Limbs - Physics Bodies for Zombies Ragdolls and NPCs [t30p4 t7p1]
- 3827959230 Detailed Vanilla Models - Part 3: Food & Drinks [t7p1]
- 3827994388 Toxic Zones [t7p6]
- 3828254924 Detailed Vanilla Models - Part 4: Medical [t7p2]
- 3828255114 Detailed Vanilla Models - Part 5: Electronics [t7p4]
- 3828255283 Detailed Vanilla Models - Part 6: Kitchen [t7p3]
- 3828260529 Miha Battery Charger [t7p6]
- 3828333447 Girlfriend Mod (In the Spirit of Kate) [t7p4]
- 3828360280 P -Alive [t7p6]
- 3828360540 Radio Voices - Every Broadcast Fully Voiced [B42] [t7p1]
- 3828495725 Wildwrought: Arc Welder [t7p5]
- 3828512337 Cajas del Tesoro/Misteriosas [t7p6]
- 3828551770 Virtual Garage [B42] [t7p6]
- 3828564756 Egg Incubator [t7p3]
- 3828608843 Roadworthy [BETA] - Realistic Driving & Car Maintenance [B42] [t7p1]
- 3828624641 M5 CS [t7p4]
- 3828688417 Tactical Knives Sheath [B42.20+ SP/MP] [t7p5]
- 3828702973 Expanded Helicopter Events Reborn [B42] [t7p3]
- 3828755546 Viewpoint's Workstations Overhaul [t7p4]
- 3828758996 Detailed Vanilla Models - Part 7: Melee II & Instruments [t7p3]
- 3828759859 Detailed Vanilla Models - Part 8: Smoking [t7p3]
- 3828760645 Detailed Vanilla Models - 3D Gloves (for Tomb's Player Body) [t7p4]
- 3828761862 Detailed Vanilla Models - Part 9: Firearms [t7p4]
- 3828766487 Viewpoint: Real VHS - Movies & TV Shows [B42] [t7p3]
- 3828794825 My Sister's Cure [t7p6]
- 3828842183 Viewpoint GPU Fix [t7p5]
- 3828883205 Wall Vines 3D (Viewpoint) [t7p5]
- 3828905319 Shelf Contents 3D (Viewpoint) [t7p3]
- 3828971421 Plague Bunker [t7p4]
- 3829093936 [RKC]LAV-25 8x8 Armored Vehicle / M242 25mm HE [t7p1]
- 3829305140 McDonald Expansion [t7p5]
- 3829335065 WW1 Vehicles [t7p5]
- 3829342573 STEP - Survival Traits Evolution Path [t7p6]

In this list, the ones most likely to touch a ZeD surface if a later round has room: 3817970320 Project Translate (translation tooling), 3823956410 Max Time In Server, 3794429489 Skill & Recipe Collector's Shelf, 3814843526 Spongie's Character Customisation - Extras (character creation), 3826615028 NEXUS BAGS OF HOLDING and 3827497087 Tactical Bags (bags and weight), 3828551770 Virtual Garage (vehicles), 3828608843 Roadworthy (vehicles, dash), 3812799224 Time Control MP (pause and speed controls), 3805947764 Dynamic Monologue (speech text), 3819509915 Davy's Real Crosswords (item with its own window), 3826112169 Tool Watches (watch item), 3825583958 Knox Event Expanded More Presets.

## Results, first group (Oct 29 2026)

The six candidates already on disk, tested at once with their requirements (`tools/qa/compat_r4_mods.txt`: NeatUI Framework, Neat Crafting, Neat Building, then Neat Crafting XP, Neat Building XP, Building Craft, The Only Cure, The Only Cure+, Kilometers Per Hour, Knox Packs; ZeD last), on a copy of the ZeD-QA save at 4K, ZeD scale 1.75, game 42.22, through `zedqa_mods_run.ps1` with `tools/qa/compat_r4.txt` (a census of the visible UI, the tab walk, the grid, the item menu as a list, the card on the pad, the cone-nav audit, the Health tab's exercise info, a spawned car's dashboard). Report `qa/regression/2026-10-29_1013_mods_fullscreen4k.md`: 9/9 pass, no error of ZeD's, no mod window over ZeD's (the census shows only the game's own elements and ZeD's).

| Mod | Workshop id | List | Evidence |
|---|---|---|---|
| Building Craft | 3459887404 | Compatible | Loads, no errors of its own; its recipes come through the game's crafting data, which ZeD's Craft and Build tabs read (tab walk, census). |
| Neat Crafting XP, Neat Building XP | 3540503606 | Compatible | Load with their bases and NeatUI Framework, no errors; they add to the game's crafting and build windows, which ZeD replaces (by reading their names; the XP display was not seen in ZeD's tabs). |
| The Only Cure | 3580276809 | Compatible | Loads, no errors; the Health tab's exercise info and the card on the pad pass with it on. Its own treatments were not exercised (needs a bitten character). |
| The Only Cure+ (Field Surgery) | 3818733381 | Compatible, with its own errors | Nine `Tried to register duplicate object: toc:...` exceptions at load from its `registries.lua` (traits and body locations it registers that The Only Cure also registers); the game went on and every test passed. Not ZeD's; try it without The Only Cure to see whether the duplicates are its own or the pair's. |
| Kilometers Per Hour | 2980583716 | Compatible | Loads (tagged B41 and B42, last updated Dec 2024); ZeD's dashboard draws (`zedqa_dash_props_smoke.lua` passed). Whether its km/h reading reaches ZeD's dash was not checked: ZeD draws its own speed, so expect "Not needed" once read. |
| Knox Packs: Upgradable Backpacks | 3822813865 | Compatible | Loads, no errors; packs are items, which ZeD's lists show. The upgrade flow was not tried. |

Also seen: `no such function "Vehicles.Init.Radio"` twice at load, the game's own (seen in ZeD-alone runs too).

Not yet tested: Xen's Enhanced GUI (3819012597) and the rest of the table: not on disk, and the Steam sign-in in the browser pane lapsed, so nothing could be subscribed. Next: the director signs in (or subscribes), then the compat kit as above, XEG on its own first.

Note (Oct 29 2026, afternoon): 3796139100 "This Is Your Life - Character Creator Overhaul" is the clothing-UI fix add-on; the creator itself is 3773911887 "This Is Your Life [B42 Stable] WIP" (with 3823338627). Both subscribed Oct 29 for the next menu run.

## Results, second group (Oct 29 2026, afternoon): the subscribed candidates

Subscribed the same afternoon (Steam signed in; `subscriptions_ledger.md`), tested at 4K on a copy of the ZeD-QA save with `zedqa_mods_run.ps1` and `tools/qa/compat_r4b.txt` (the round-4 set plus the map, the moodles and Messages), ZeD last; the main-menu mods through `zedqa_menu_mods_run.ps1` with `zedqa_r3_menu.lua`. Reports `qa/regression/2026-10-29_1401_mods_fullscreen4k.md` (XEG), `_1405_` (Viewpoint Clean UI), `_1409_` (the group).

| Mod | Workshop id | List | Evidence |
|---|---|---|---|
| Xen's Enhanced GUI | 3819012597 | Does not work (with ZeD) | Both are whole-interface overhauls. With both on, XEG's HUD (mini health, moodle bar, compass, HUD panel, quick access) draws over ZeD's belt and moodles at once (the census lists them all on screen), and its inventory opens beside ZeD's windows. ZeD's own tests still pass (11/12; the one failure is the game counting XEG's own missing-argument warning for its key `IGUI_XEG_fbb6ca3a`), and XEG logs one `hollow` nil call of its own at load. Run one or the other. |
| Viewpoint Clean UI | 3826157418 | Compatible, with a note | 12/12. On this run only its update notice window showed (centred, 660x600); its own inventory replacement did not take over ZeD's windows. Whether its parts switch on with its options was not tried. |
| Better World Map | 3794379457 | Compatible | Loads, no errors; ZeD's Maps tab and pop-out draw (`zedqa_mapshot.lua`). Its labels are for the game's map; not seen on ZeD's (by the mod's description). |
| Locksmith | 3797292945 | Compatible | Loads, no errors; its rows come through the game's context menu, which ZeD's menu shows (the item menu as a list passed). |
| Survivor PDA (mod id ProjectRPGExpanded) | 3826426915 | Compatible | Loads, no errors; its own window opens on its key beside ZeD's. Not opened in the run. |
| Loot Tracker | 3823828778 | Compatible | Loads, no errors; its overlays are for the game's map. |
| Vital Signs | 3819507580 | Compatible | Loads, no errors; ZeD's moodle test passed with it on (every place, the hover note). What it removes is the game's moodle look; ZeD still places the game's column. |
| Item Details Panel | 3826420021 | Compatible, with its own error | Loads; one `updateDisplayActivation` nil call of its own at load. Its panels sit beside the game's item tooltip, which ZeD's tooltip now runs through (the Oct 27 chaining), so they may show; not seen in the run. |
| Disable Welcome Message | 1924146603 | Compatible | Loads, no errors (in game and at the main menu). |
| Better Building Plus + RC's Structures Framework | 3812970899, 3718883428 | Compatible | Load, no errors; its building pieces come through the game's build data, which ZeD's Build tab reads. |
| SideWinder's Placement+ | 3796440093 | Compatible | Loads, no errors; placement only. |
| Mod Load Order Sorter Extension (with Mod Load Order Sorter) | 3809995878 | Compatible | The main-menu walk (Mods, Options, New Game to Looks) ran with no errors; its extension is for the game's load-order screen, which ZeD replaces (Not needed in practice). |
| This Is Your Life (character creator) | 3773911887 | Not yet tested | 3796139100 turned out to be its clothing-UI fix; the creator itself and its dataset were subscribed at the end of the day for the next menu run. |

Also in the group's log: eight `Index 200 out of bounds ... LexState.new_localvar` refusals, which is the game's debug-build Lua compiler refusing a file with more than 200 locals (knowledge bank Q260). Not ZeD's (ZeD-alone runs show none); one of the ten has such a file. Everything still passed, so it is a mod-own matter under `-debug` only.
