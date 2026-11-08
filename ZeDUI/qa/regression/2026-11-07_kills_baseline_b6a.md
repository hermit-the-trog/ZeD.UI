# ZeD-UI regression - 2026-11-07 01:27 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-07 01:27:51 |
| Finished | 2026-11-07 01:30:12 (2 min 21 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\merge1_quick.txt (4 scripts) |
| Result | **2/4 pass**, 1 warn, 1 fail, 0 timeout |
| Go numbers | 22813 to 22818 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_firearm_facts.lua: no DONE within 30 s; the script may still be running in the game
- quit: quit to the main menu, then to the desktop (go 22817, 22818)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_kills_kind.lua | kk | WARN | 19 |  | 5 ERR line(s) |
| 4 | zedqa_firearm_facts.lua | ff | **FAIL** | 30 |  | 6 Java exception(s) in the log; 6 ERR line(s); no DONE within 30 s; the script may still be running in the game |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22813 at 01:28:48

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

- go 22814 at 01:28:53

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_kills_kind.lua (`ZEDQA kk`) - WARN, 19 s

- go 22815 at 01:28:57
- 5 ERR line(s)

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA kk start
[ZeD.QA] run #3 ok=true
ZEDQA kk before: engine 318, explosion 3, fire 14, vehicle 23
ZEDQA kk Base.BaseballBat: zombie true
ZEDQA kk Base.BaseballBat: dead true after 5 hits, instant true, power 0, engine +1, ZeD explosion+1
ZEDQA kk FAIL Base.BaseballBat is not filed as an explosion
ZEDQA kk Base.Axe: zombie true
ZEDQA kk Base.Axe: dead true after 5 hits, instant true, power 0, engine +1, ZeD explosion+1
ZEDQA kk FAIL Base.Axe is not filed as an explosion
ZEDQA kk Base.HuntingKnife: zombie true
ZEDQA kk Base.HuntingKnife: dead true after 4 hits, instant true, power 0, engine +1, ZeD explosion+1
ZEDQA kk FAIL Base.HuntingKnife is not filed as an explosion
ZEDQA kk Base.Pistol: zombie true
ZEDQA kk Base.Pistol: dead true after 1 hits, instant true, power 0, engine +1, ZeD explosion+1
ZEDQA kk FAIL Base.Pistol is not filed as an explosion
ZEDQA kk Base.Hammer: zombie true
ZEDQA kk Base.Hammer: dead true after 4 hits, instant true, power 0, engine +1, ZeD fire+1
ZEDQA kk PASS Base.Hammer is not filed as an explosion
ZEDQA kk BARE: zombie true
ZEDQA kk BARE: dead true after 4 hits, instant true, power 0, engine +1, ZeD fire+1
ZEDQA kk PASS BARE is not filed as an explosion
ZEDQA kk Base.PipeBomb: zombie true
ZEDQA kk Base.PipeBomb: dead true after 1 hits, instant true, power 90, engine +1, ZeD fire+1
ZEDQA kk PASS Base.PipeBomb may count as an explosion
ZEDQA kk after: engine 325, ZeD explosion 7, Journal header 372
ZEDQA kk FAIL the Journal header is the game's own count (header 372, game 325, fire 17, vehicle 23, explosion 7)
ZEDQA kk this run's own kills: engine +7, ZeD extra rows +7
ZEDQA kk 3 passed, 5 failed
ZEDQA kk DONE
```

### 4. zedqa_firearm_facts.lua (`ZEDQA ff`) - FAIL, 30 s

- go 22816 at 01:29:20
- 6 Java exception(s) in the log
- 6 ERR line(s)
- no DONE within 30 s; the script may still be running in the game

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ERROR: General f:2047> Lua((MOD:ZeD-GUI)).formatFirearm> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in formatFirearm at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).formatFirearm(ItemCard.lua:86)
    Lua((MOD:ZeD-GUI)).itemFacts(ItemCard.lua:187)
    Lua(Vanilla).zedqa.lua(spawnpoints.lua:8)
    Lua((MOD:ZeD-GUI)).runScript(QABridge.lua:123)
    Lua((MOD:ZeD-GUI)).poll(QABridge.lua:135)
ZEDQA ff FAIL Base.Pistol: Object tried to call nil in formatFirearm java.lang.RuntimeException
ERROR: General f:2047> Lua((MOD:ZeD-GUI)).formatFirearm> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in formatFirearm at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).formatFirearm(ItemCard.lua:86)
    Lua((MOD:ZeD-GUI)).itemFacts(ItemCard.lua:187)
    Lua(Vanilla).zedqa.lua(spawnpoints.lua:8)
    Lua((MOD:ZeD-GUI)).runScript(QABridge.lua:123)
    Lua((MOD:ZeD-GUI)).poll(QABridge.lua:135)
ZEDQA ff FAIL Base.Pistol2: Object tried to call nil in formatFirearm java.lang.RuntimeException
ERROR: General f:2047> Lua((MOD:ZeD-GUI)).formatFirearm> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in formatFirearm at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).formatFirearm(ItemCard.lua:86)
    Lua((MOD:ZeD-GUI)).itemFacts(ItemCard.lua:187)
    Lua(Vanilla).zedqa.lua(spawnpoints.lua:8)
    Lua((MOD:ZeD-GUI)).runScript(QABridge.lua:123)
    Lua((MOD:ZeD-GUI)).poll(QABridge.lua:135)
ZEDQA ff FAIL Base.Revolver: Object tried to call nil in formatFirearm java.lang.RuntimeException
ERROR: General f:2047> Lua((MOD:ZeD-GUI)).formatFirearm> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in formatFirearm at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).formatFirearm(ItemCard.lua:86)
    Lua((MOD:ZeD-GUI)).itemFacts(ItemCard.lua:187)
    Lua(Vanilla).zedqa.lua(spawnpoints.lua:8)
    Lua((MOD:ZeD-GUI)).runScript(QABridge.lua:123)
    Lua((MOD:ZeD-GUI)).poll(QABridge.lua:135)
ZEDQA ff FAIL Base.Shotgun: Object tried to call nil in formatFirearm java.lang.RuntimeException
ERROR: General f:2047> Lua((MOD:ZeD-GUI)).formatFirearm> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in formatFirearm at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).formatFirearm(ItemCard.lua:86)
    Lua((MOD:ZeD-GUI)).itemFacts(ItemCard.lua:187)
    Lua(Vanilla).zedqa.lua(spawnpoints.lua:8)
    Lua((MOD:ZeD-GUI)).runScript(QABridge.lua:123)
    Lua((MOD:ZeD-GUI)).poll(QABridge.lua:135)
ZEDQA ff FAIL Base.AssaultRifle: Object tried to call nil in formatFirearm java.lang.RuntimeException
ERROR: General f:2047> Lua((MOD:ZeD-GUI)).formatFirearm> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in formatFirearm at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).formatFirearm(ItemCard.lua:86)
    Lua((MOD:ZeD-GUI)).itemFacts(ItemCard.lua:187)
    Lua(Vanilla).zedqa.lua(spawnpoints.lua:8)
    Lua((MOD:ZeD-GUI)).runScript(QABridge.lua:123)
    Lua((MOD:ZeD-GUI)).poll(QABridge.lua:135)
ZEDQA ff FAIL Base.HuntingRifle: Object tried to call nil in formatFirearm java.lang.RuntimeException
ZEDQA ff PASS Base.BaseballBat ammo type nil
ZEDQA ff 6 failed
ZEDQA ff DONE
[ZeD.QA] run #4 ok=true
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
