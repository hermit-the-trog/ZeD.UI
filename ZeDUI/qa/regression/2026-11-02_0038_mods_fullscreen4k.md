# ZeD-UI regression - 2026-11-02 00:39 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-02 00:39:13 |
| Finished | 2026-11-02 00:41:08 (1 min 55 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r5_nav.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 18400 to 18403 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 18402, 18403)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_navmap.lua | nav | PASS | 15 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 18400 at 00:40:23

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_navmap.lua (`ZEDQA nav`) - PASS, 15 s

- go 18401 at 00:40:29

```text
[ZeD.QA] windows reset (R)
ZEDQA nav start
[ZeD.QA] run #2 ok=true
ZEDQA nav char loot: 27 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char loot STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) invrow:14(D) view:list:player(U) view:grid:player(U) container:1(UD)
ZEDQA nav char loot charTabBar:tab:loot U>- D>tab:equip L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:skills U>tab:journal D>- L>- R>charMainInv:invrow:1
ZEDQA nav char loot charMainInv:invrow:1 U>view:list:player~ D>invrow:2 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:12 U>invrow:11 D>invrow:13 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:13 U>invrow:12 D>invrow:14 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:14 U>invrow:13 D>- L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:view:list:player U>- D>invrow:1~ L>charTabBar:tab:loot R>view:grid:player
ZEDQA nav char loot charMainInv:view:grid:player U>- D>invrow:1~ L>view:list:player R>charContainerStrip:container:1
ZEDQA nav char loot charContainerStrip:container:1 U>- D>- L>charMainInv:view:grid:player R>window:World
ZEDQA nav char loot charCtl:charCtl:xfer U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charTabBar:tab:loot~ R>charMainInv:invrow:10
ZEDQA nav char loot charCtl:charCtl:same U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charCtl:xfer R>charMainInv:invrow:10
ZEDQA nav char loot charCtl:charCtl:near U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charCtl:same R>charMainInv:invrow:10
ZEDQA nav char equip: 60 targets | TRAP 6 {equipslot:INR,equipslot:GLV,equipslot:PNT,equipslot:SOC,equipslot:BOT,equipslot:BLT} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char equip STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) equipslot:__disclosure(U) equipview:list(U) equipview:doll(U) equippart:Right Foot(D) equippart:Left Foot(D) invrow:14(D) view:list:player(U) view:grid:player(U) container:1(UD)
ZEDQA nav char equip charTabBar:tab:loot U>- D>tab:equip L>- R>charTabContent:equipslot:__disclosure
ZEDQA nav char equip charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charTabContent:equipgroup:head
ZEDQA nav char equip charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charTabContent:equipgroup:torso
ZEDQA nav char equip charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charTabContent:equipgroup:arms
ZEDQA nav char equip charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charTabContent:equipgroup:legs
ZEDQA nav char equip charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charTabContent:equipslot:PNT
ZEDQA nav char equip charTabBar:tab:skills U>tab:journal D>- L>- R>charTabContent:equipslot:SOC
ZEDQA nav char equip charTabContent:equipslot:__disclosure U>- D>equipgroup:head L>charTabBar:tab:equip R>equipview:list
ZEDQA nav char equip charTabContent:equipview:list U>- D>equipgroup:head L>equipslot:__disclosure R>equipview:doll
ZEDQA nav char equip charTabContent:equipview:doll U>- D>equipgroup:head L>equipslot:__disclosure R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equippart:Head U>el:fold D>equippart:Neck L>equippart:Neck R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equippart:Neck U>equippart:Head D>equippart:Upper Torso L>charTabBar:tab:equip~ R>equippart:Head
ZEDQA nav char equip charTabContent:equippart:Upper Torso U>equippart:Neck D>equippart:Lower Torso L>equippart:Right Upper Arm R>equippart:Left Upper Arm
ZEDQA nav char equip charTabContent:equippart:Right Upper Arm U>equippart:Upper Torso D>equippart:Right Forearm L>equippart:Right Forearm R>equippart:Upper Torso
ZEDQA nav char equip charTabContent:equippart:Left Upper Arm U>equippart:Upper Torso D>equippart:Left Forearm L>equippart:Upper Torso R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Lower Torso U>equippart:Upper Torso D>equippart:Groin L>equippart:Right Upper Arm R>equippart:Groin
ZEDQA nav char equip charTabContent:equippart:Right Forearm U>equippart:Right Upper Arm D>equippart:Right Hand L>equippart:Right Hand R>equippart:Right Upper Leg
ZEDQA nav char equip charTabContent:equippart:Left Forearm U>equippart:Left Upper Arm D>equippart:Left Hand L>equippart:Groin R>equippart:Left Hand
ZEDQA nav char equip charTabContent:equippart:Groin U>equippart:Lower Torso D>equippart:Right Upper Leg L>equippart:Lower Torso R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Right Hand U>equippart:Right Forearm D>equippart:Right Upper Leg~ L>charTabBar:tab:equip~ R>equippart:Right Forearm
ZEDQA nav char equip charTabContent:equippart:Left Hand U>equippart:Left Forearm D>equippart:Left Upper Leg~ L>equippart:Left Forearm R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equippart:Right Upper Leg U>equippart:Groin D>equippart:Right Lower Leg L>equippart:Right Forearm R>equippart:Groin
ZEDQA nav char equip charTabContent:equippart:Left Upper Leg U>equippart:Groin D>equippart:Left Lower Leg L>equippart:Groin R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Right Lower Leg U>equippart:Right Upper Leg D>equippart:Right Foot L>equippart:Right Foot R>equippart:Right Upper Leg
ZEDQA nav char equip charTabContent:equippart:Left Lower Leg U>equippart:Left Upper Leg D>equippart:Left Foot L>equippart:Left Upper Leg R>equippart:Left Foot
ZEDQA nav char equip charTabContent:equippart:Right Foot U>equippart:Right Lower Leg D>- L>charTabBar:tab:equip~ R>equippart:Right Lower Leg
ZEDQA nav char equip charTabContent:equippart:Left Foot U>equippart:Left Lower Leg D>- L>equippart:Left Lower Leg R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipgroup:head U>equipslot:__disclosure D>equipgroup:torso L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipgroup:torso U>equipgroup:head D>equipslot:INR L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipgroup:arms U>equipslot:INR D>equipslot:GLV L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipgroup:legs U>equipslot:GLV D>equipslot:PNT L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipgroup:held U>equipslot:BOT D>equipslot:BLT L>charTabBar:tab:equip~ R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:INR [OWN D-PAD] U>equipgroup:torso D>equipgroup:arms L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:GLV [OWN D-PAD] U>equipgroup:arms D>equipgroup:legs L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:PNT [OWN D-PAD] U>equipgroup:legs D>equipslot:SOC L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:SOC [OWN D-PAD] U>equipslot:PNT D>equipslot:BOT L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:BOT [OWN D-PAD] U>equipslot:SOC D>equipgroup:held L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:BLT [OWN D-PAD] U>equipgroup:held D>equipbelt:1 L>charTabBar:tab:equip~ R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipbelt:1 U>equipslot:BLT D>el:fold L>charTabBar:tab:equip~ R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:el:fold U>equipbelt:1 D>equippart:Head L>charTabBar:tab:equip~ R>charMainInv:invrow:1
ZEDQA nav char equip charMainInv:invrow:1 U>view:list:player~ D>invrow:2 L>charTabContent:equipgroup:torso R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabContent:equipslot:INR R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabContent:equipgroup:arms R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabContent:equipgroup:legs R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabContent:equipslot:PNT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabContent:equipslot:SOC R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabContent:equipslot:BOT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabContent:equipgroup:held R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabContent:equipslot:BLT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:12 U>invrow:11 D>invrow:13 L>charTabContent:el:fold R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:13 U>invrow:12 D>invrow:14 L>charTabContent:equippart:Head R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:14 U>invrow:13 D>- L>charTabContent:equippart:Left Upper Arm R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:view:list:player U>- D>invrow:1~ L>charTabContent:equipslot:__disclosure R>view:grid:player
ZEDQA nav char equip charMainInv:view:grid:player U>- D>invrow:1~ L>view:list:player R>charContainerStrip:container:1
ZEDQA nav char equip charContainerStrip:container:1 U>- D>- L>charMainInv:view:grid:player R>window:World
ZEDQA nav char equip charCtl:charCtl:xfer U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charTabContent:equipbelt:1 R>charMainInv:invrow:10
ZEDQA nav char equip charCtl:charCtl:same U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charCtl:xfer R>charMainInv:invrow:10
ZEDQA nav char equip charCtl:charCtl:near U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charCtl:same R>charMainInv:invrow:10
ZEDQA nav char health: 49 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char health STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) health:__disclosure(U) health:exercise(D) health:time:dec(D) health:time:inc(D) health:start(D) invrow:14(D) view:list:player(U) view:grid:player(U) container:1(UD)
ZEDQA nav char thermal: 47 targets | TRAP 1 {thermal:__gridscroll} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char thermal STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) thermal:__disclosure(U) thermal:view(D) invrow:14(D) view:list:player(U) view:grid:player(U) container:1(UD)
ZEDQA nav char identity: 41 targets | TRAP 1 {hb:part} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char identity STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) identity:__disclosure(U) identity:trait:Smoker(D) invrow:14(D) view:list:player(U) view:grid:player(U) container:1(UD)
ZEDQA nav char journal: 31 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char journal STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) jpage(U) journal:__save(D) invrow:14(D) view:list:player(U) view:grid:player(U) container:1(UD)
ZEDQA nav char skills: 87 targets | TRAP 35 {skill:Aiming,skill:Reloading,skill:Blacksmithing,skill:Carpentry,skill:Carving,skill:Cooking,skill:Electrical,skill:Glassmaking,skill:Knapping,skill:Masonry,skill:Mechanics,skill:Pottery,skill:Tailoring,skill:Welding,skill:First Aid,skill:Fishing,skill:Foraging,skill:Tracking,skill:Trapping,skill:Axe,skill:Long Blade,skill:Long Blunt,skill:Maintenance,skill:Short Blade,skill:Short Blunt,skill:Spear,skill:Agriculture,skill:Animal Care,skill:Butchering,skill:Fitness,skill:Lightfooted,skill:Nimble,skill:Running,skill:Sneaking,skill:Strength} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char skills STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) skills:__disclosure(U) training:col1_Foraging(D) training:col2_Trapping(D) invrow:14(D) view:list:player(U) view:grid:player(U) container:1(UD)
ZEDQA nav world loot: 15 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world loot STUCK: container:1(UD) view:list:type:floor(U) view:grid:type:floor(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world loot worldContainerStrip:container:1 U>- D>- L>window:Character R>worldMainInv:invrow:1
ZEDQA nav world loot worldMainInv:invrow:1 U>view:list:type:floor~ D>invrow:2 L>worldContainerStrip:container:1 R>worldTabBar:tab:loot
ZEDQA nav world loot worldMainInv:invrow:2 U>invrow:1 D>worldCtl:worldCtl:same L>worldContainerStrip:container:1 R>worldTabBar:tab:loot
ZEDQA nav world loot worldMainInv:view:list:type:floor U>- D>invrow:1~ L>worldContainerStrip:container:1 R>view:grid:type:floor
ZEDQA nav world loot worldMainInv:view:grid:type:floor U>- D>invrow:1~ L>view:list:type:floor R>worldTabBar:tab:loot
ZEDQA nav world loot worldTabBar:tab:loot U>- D>tab:craft L>worldMainInv:view:grid:type:floor R>-
ZEDQA nav world loot worldTabBar:tab:craft U>tab:loot D>tab:build L>worldMainInv:invrow:1 R>-
ZEDQA nav world loot worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldMainInv:invrow:2 R>-
ZEDQA nav world loot worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldMainInv:invrow:2 R>-
ZEDQA nav world loot worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldMainInv:invrow:2~ R>-
ZEDQA nav world loot worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldMainInv:invrow:2~ R>-
ZEDQA nav world loot worldTabBar:tab:animals U>tab:forage D>tab:vehicle L>worldMainInv:invrow:2~ R>-
ZEDQA nav world loot worldTabBar:tab:vehicle U>tab:animals D>- L>worldCtl:worldCtl:same~ R>-
ZEDQA nav world loot worldCtl:worldCtl:take U>worldMainInv:invrow:2 D>- L>worldContainerStrip:container:1 R>worldCtl:same
ZEDQA nav world loot worldCtl:worldCtl:same U>worldMainInv:invrow:2 D>- L>worldCtl:take R>worldTabBar:tab:loot~
ZEDQA nav world craft: 23 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world craft STUCK: container:1(UD) view:list:type:floor(U) view:grid:type:floor(U) craft:stDrop(U) craft:catDrop(U) craft:sortMenu(D) craft:showMenu(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world build: 19 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world build STUCK: container:1(UD) view:list:type:floor(U) view:grid:type:floor(U) build:catDrop(U) build:sortMenu(D) build:showMenu(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world furniture: 20 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world furniture STUCK: container:1(UD) view:list:type:floor(U) view:grid:type:floor(U) fur:mode:pickup(UD) fur:mode:place(UD) fur:mode:rotate(UD) fur:mode:scrap(UD) fur:mode:repair(UD) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world maps: 34 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world maps STUCK: container:1(UD) view:list:type:floor(U) view:grid:type:floor(U) map:disclosure(U) map:tool:house(U) map:tool:target(U) map:tool:skull(U) map:tool:star(U) map:tool:cross(U) map:tool:checkmark(U) map:tool:text(U) map:color:1(U) map:color:2(U) map:color:3(U) map:color:4(U) map:color:5(U) map:popout(U) map:style:survey(D) map:style:color(D) map:style:paper(D) map:ext:key(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world maps worldContainerStrip:container:1 U>- D>- L>window:Character R>worldMainInv:invrow:1
ZEDQA nav world maps worldMainInv:invrow:1 U>view:list:type:floor~ D>invrow:2 L>worldContainerStrip:container:1 R>worldTabContent:map:canvas:cursor
ZEDQA nav world maps worldMainInv:invrow:2 U>invrow:1 D>worldCtl:worldCtl:same L>worldContainerStrip:container:1 R>worldTabContent:map:canvas:cursor
ZEDQA nav world maps worldMainInv:view:list:type:floor U>- D>invrow:1~ L>worldContainerStrip:container:1 R>view:grid:type:floor
ZEDQA nav world maps worldMainInv:view:grid:type:floor U>- D>invrow:1~ L>view:list:type:floor R>worldTabContent:map:disclosure
ZEDQA nav world maps worldTabContent:map:disclosure U>- D>map:canvas:cursor L>worldMainInv:view:grid:type:floor R>map:tool:house
ZEDQA nav world maps worldTabContent:map:tool:house U>- D>map:canvas:cursor L>map:disclosure R>map:tool:target
ZEDQA nav world maps worldTabContent:map:tool:target U>- D>map:canvas:cursor L>map:tool:house R>map:tool:skull
ZEDQA nav world maps worldTabContent:map:tool:skull U>- D>map:canvas:cursor L>map:tool:target R>map:tool:star
ZEDQA nav world maps worldTabContent:map:tool:star U>- D>map:canvas:cursor L>map:tool:skull R>map:tool:cross
ZEDQA nav world maps worldTabContent:map:tool:cross U>- D>map:canvas:cursor L>map:tool:star R>map:tool:checkmark
ZEDQA nav world maps worldTabContent:map:tool:checkmark U>- D>map:canvas:cursor L>map:tool:cross R>map:tool:text
ZEDQA nav world maps worldTabContent:map:tool:text U>- D>map:canvas:cursor L>map:tool:checkmark R>map:color:1
ZEDQA nav world maps worldTabContent:map:color:1 U>- D>map:canvas:cursor L>map:tool:text R>map:color:2
ZEDQA nav world maps worldTabContent:map:color:2 U>- D>map:canvas:cursor L>map:color:1 R>map:color:3
ZEDQA nav world maps worldTabContent:map:color:3 U>- D>map:canvas:cursor L>map:color:2 R>map:color:4
ZEDQA nav world maps worldTabContent:map:color:4 U>- D>map:canvas:cursor L>map:color:3 R>map:color:5
ZEDQA nav world maps worldTabContent:map:color:5 U>- D>map:canvas:cursor L>map:color:4 R>map:popout
ZEDQA nav world maps worldTabContent:map:popout U>- D>map:canvas:cursor L>map:color:5 R>worldTabBar:tab:maps
ZEDQA nav world maps worldTabContent:map:canvas:cursor U>map:disclosure D>map:style:paper L>worldMainInv:invrow:2 R>worldTabBar:tab:maps
ZEDQA nav world maps worldTabContent:map:style:survey U>map:canvas:cursor D>- L>worldCtl:worldCtl:same R>map:style:color
ZEDQA nav world maps worldTabContent:map:style:color U>map:canvas:cursor D>- L>map:style:survey R>map:style:paper
ZEDQA nav world maps worldTabContent:map:style:paper U>map:canvas:cursor D>- L>map:style:color R>map:ext:key
ZEDQA nav world maps worldTabContent:map:ext:key U>map:canvas:cursor D>- L>map:style:paper R>worldTabBar:tab:maps~
ZEDQA nav world maps worldTabBar:tab:loot U>- D>tab:craft L>worldTabContent:map:popout R>-
ZEDQA nav world maps worldTabBar:tab:craft U>tab:loot D>tab:build L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:animals U>tab:forage D>tab:vehicle L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:vehicle U>tab:animals D>- L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldCtl:worldCtl:take U>worldMainInv:invrow:2 D>- L>worldContainerStrip:container:1 R>worldCtl:same
ZEDQA nav world maps worldCtl:worldCtl:same U>worldMainInv:invrow:2 D>- L>worldCtl:take R>worldTabContent:map:style:survey
ZEDQA nav world forage: 18 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world forage STUCK: container:1(UD) view:list:type:floor(U) view:grid:type:floor(U) forage:dropdown(U) forage:search(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world animals: 18 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world animals STUCK: container:1(UD) view:list:type:floor(U) view:grid:type:floor(U) animals:submode:ranch(U) animals:submode:butcher(U) animals:createzone(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world vehicle: 16 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world vehicle STUCK: container:1(UD) view:list:type:floor(U) view:grid:type:floor(U) mech:inspect(UD) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(DR) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N> LuaManager.RunLuaInternal> Exception thrown  :: java.lang.ArrayIndexOutOfBoundsException: Index 200 out of bounds for length 200 at LexState.new_localvar(LexState.java:730).
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
