# ZeD-UI regression - 2026-11-06 20:32 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-06 20:32:40 |
| Finished | 2026-11-06 20:36:00 (3 min 19 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\tab_sweep.txt (4 scripts) |
| Result | **2/4 pass**, 0 warn, 2 fail, 0 timeout |
| Go numbers | 22579 to 22584 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22583, 22584)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_animals.lua | an | **FAIL** | 2 |  | 1 Java exception(s) in the log |
| 4 | zedqa_tab_sweep.lua | tsw | **FAIL** | 105 | zqa_tsw_char_loot.png, zqa_tsw_char_equip.png, zqa_tsw_char_health.png, zqa_tsw_char_thermal.png, zqa_tsw_char_cooking.png, zqa_tsw_char_identity.png, zqa_tsw_char_journal.png, zqa_tsw_char_skills.png, zqa_tsw_char_server.png, zqa_tsw_char_radio.png, zqa_tsw_world_loot.png, zqa_tsw_world_craft.png, zqa_tsw_world_build.png, zqa_tsw_world_furniture.png, zqa_tsw_world_maps.png, zqa_tsw_world_forage.png, zqa_tsw_world_animals.png, zqa_tsw_world_radio.png, zqa_tsw_world_vehicle.png, zqa_tsw_world_admin.png, zqa_tsw_card_world_craft.png, zqa_tsw_after_world_craft.png, zqa_tsw_card_world_animals.png, zqa_tsw_after_world_animals.png, zqa_tsw_card_world_build.png, zqa_tsw_after_world_build.png, zqa_tsw_card_world_maps.png, zqa_tsw_after_world_maps.png, zqa_tsw_card_world_forage.png, zqa_tsw_after_world_forage.png, zqa_tsw_card_char_journal.png, zqa_tsw_after_char_journal.png, zqa_tsw_card_char_skills.png, zqa_tsw_after_char_skills.png, zqa_tsw_card_char_health.png, zqa_tsw_after_char_health.png | 89 Java exception(s) in the log; 6 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22579 at 20:33:37

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 22580 at 20:33:42

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_animals.lua (`ZEDQA an`) - FAIL, 2 s

- go 22581 at 20:33:46
- 1 Java exception(s) in the log

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ZEDQA an found hutch=true trough=true hook=true
ZEDQA an hutch birds=4 dirt=46
ERROR: General f:946 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: addItems of non-table: null
ERROR: General f:946> Lua(Vanilla).onAddFoodDebug> Exception thrown
    java.lang.RuntimeException: attempted index: addItems of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).onAddFoodDebug(ISFeedingTroughMenu.lua:174)
    Lua(Vanilla).tick(spawnpoints.lua:103)
ZEDQA an trough fed
ZEDQA an cow killed
ZEDQA an zone ok=true
ZEDQA an setup done
```

### 4. zedqa_tab_sweep.lua (`ZEDQA tsw`) - FAIL, 105 s

- go 22582 at 20:33:52
- 89 Java exception(s) in the log
- 6 ERR line(s)
- screenshots: zqa_tsw_char_loot.png, zqa_tsw_char_equip.png, zqa_tsw_char_health.png, zqa_tsw_char_thermal.png, zqa_tsw_char_cooking.png, zqa_tsw_char_identity.png, zqa_tsw_char_journal.png, zqa_tsw_char_skills.png, zqa_tsw_char_server.png, zqa_tsw_char_radio.png, zqa_tsw_world_loot.png, zqa_tsw_world_craft.png, zqa_tsw_world_build.png, zqa_tsw_world_furniture.png, zqa_tsw_world_maps.png, zqa_tsw_world_forage.png, zqa_tsw_world_animals.png, zqa_tsw_world_radio.png, zqa_tsw_world_vehicle.png, zqa_tsw_world_admin.png, zqa_tsw_card_world_craft.png, zqa_tsw_after_world_craft.png, zqa_tsw_card_world_animals.png, zqa_tsw_after_world_animals.png, zqa_tsw_card_world_build.png, zqa_tsw_after_world_build.png, zqa_tsw_card_world_maps.png, zqa_tsw_after_world_maps.png, zqa_tsw_card_world_forage.png, zqa_tsw_after_world_forage.png, zqa_tsw_card_char_journal.png, zqa_tsw_after_char_journal.png, zqa_tsw_card_char_skills.png, zqa_tsw_after_char_skills.png, zqa_tsw_card_char_health.png, zqa_tsw_after_char_health.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #4 ok=true
ZEDQA tsw hooked
ZEDQA tsw PASS char loot: active=loot clips left=0 footer=39 strip vis=nil zones=nil
ZEDQA tsw PASS char equip: active=equip clips left=0 footer=39 strip vis=nil zones=nil
ZEDQA tsw PASS char health: active=health clips left=0 footer=39 strip vis=nil zones=nil
ZEDQA tsw PASS char thermal: active=thermal clips left=0 footer=39 strip vis=nil zones=nil
ZEDQA tsw FORCED cooking
ZEDQA tsw SKIP char cooking: active=loot clips left=0 footer=39 strip vis=nil zones=nil
ZEDQA tsw PASS char identity: active=identity clips left=0 footer=39 strip vis=nil zones=nil
ZEDQA tsw PASS char journal: active=journal clips left=0 footer=39 strip vis=nil zones=nil
ZEDQA tsw PASS char skills: active=skills clips left=0 footer=39 strip vis=nil zones=nil
ZEDQA tsw FORCED server
ZEDQA tsw SKIP char server: active=loot clips left=0 footer=39 strip vis=nil zones=nil
ZEDQA tsw FORCED radio
ZEDQA tsw SKIP char radio: active=loot clips left=0 footer=39 strip vis=nil zones=nil
ZEDQA tsw PASS world loot: active=loot clips left=0 footer=39 strip vis=true zones=7
ZEDQA tsw PASS world craft: active=craft clips left=0 footer=39 strip vis=true zones=7
ZEDQA tsw PASS world build: active=build clips left=0 footer=39 strip vis=true zones=7
ZEDQA tsw PASS world furniture: active=furniture clips left=0 footer=39 strip vis=true zones=7
ZEDQA tsw PASS world maps: active=maps clips left=0 footer=39 strip vis=true zones=7
ZEDQA tsw PASS world forage: active=forage clips left=0 footer=39 strip vis=true zones=7
ZEDQA tsw PASS world animals: active=animals clips left=0 footer=39 strip vis=true zones=7
ZEDQA tsw FORCED radio
ZEDQA tsw SKIP world radio: active=loot clips left=0 footer=39 strip vis=true zones=7
ZEDQA tsw FORCED vehicle
ZEDQA tsw SKIP world vehicle: active=loot clips left=0 footer=39 strip vis=true zones=7
ZEDQA tsw FORCED admin
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_TicketCards.lua:162)
    Lua((MOD:ZeD-GUI)).cap(ZeD_TicketCards.lua:162)
    Lua((MOD:ZeD-GUI)).openCount(ZeD_TicketCards.lua:907)
    Lua((MOD:ZeD-GUI)).tabLabel(ZeD_TicketCards.lua:912)
    Lua((MOD:ZeD-GUI)).composeWorldTitle(ZeD_WorldWindow.lua:141)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).askAll(ZeD_Admin.lua:294)
    Lua((MOD:ZeD-GUI)).watch(ZeD_Admin.lua:320)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).askAll(ZeD_Admin.lua:295)
    Lua((MOD:ZeD-GUI)).watch(ZeD_Admin.lua:320)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).askLists(ZeD_Admin.lua:308)
    Lua((MOD:ZeD-GUI)).watch(ZeD_Admin.lua:324)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).refreshRows(ZeD_Admin.lua:219)
    Lua((MOD:ZeD-GUI)).watch(ZeD_Admin.lua:328)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).render(AdminTab.lua:302)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4138)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_TicketCards.lua:162)
    Lua((MOD:ZeD-GUI)).cap(ZeD_TicketCards.lua:162)
    Lua((MOD:ZeD-GUI)).openCount(ZeD_TicketCards.lua:907)
    Lua((MOD:ZeD-GUI)).homeItems(ZeD_AdminCards.lua:738)
    Lua((MOD:ZeD-GUI)).build(AdminTab.lua:132)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_TicketCards.lua:162)
    Lua((MOD:ZeD-GUI)).cap(ZeD_TicketCards.lua:162)
    Lua((MOD:ZeD-GUI)).openCount(ZeD_TicketCards.lua:907)
    Lua((MOD:ZeD-GUI)).ticketSummary(ZeD_AdminCards.lua:621)
    Lua((MOD:ZeD-GUI)).homeItems(ZeD_AdminCards.lua:739)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:667)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
ERROR: General f:3382> Lua((MOD:ZeD-GUI)).safe> Exception thrown
    java.lang.RuntimeException: attempted index: hasCapability of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).safe(ZeD_Admin.lua:60)
    Lua((MOD:ZeD-GUI)).can(ZeD_Admin.lua:80)
    Lua((MOD:ZeD-GUI)).live(ZeD_AdminCards.lua:89)
    Lua((MOD:ZeD-GUI)).gate(ZeD_AdminCards.lua:95)
ERROR: General f:3382 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: hasCapability of non-table: null
... (459 more lines; see console.txt)
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
