# ZeD-UI regression - 2026-11-17 15:42 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 15:42:49 |
| Finished | 2026-11-17 15:47:03 (4 min 14 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\gallery_v1_a_zed.txt (11 scripts) |
| Result | **9/11 pass**, 0 warn, 2 fail, 0 timeout |
| Go numbers | 28366 to 28378 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28377, 28378)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 4 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 5 | gallery_story_stage.lua | sts | PASS | 40 |  |  |
| 6 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 7 | gallery_v1_a_common.lua | g1c | PASS | 1 |  | late output from unl (4 line(s), not counted) |
| 8 | gallery_v1_a_zed.lua | g1z | **FAIL** | 61 |  | 6 Java exception(s) in the log; late output from unl (59 line(s), not counted) |
| 9 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 10 | gallery_story_teardown.lua | stt | **FAIL** | 10 |  | 6 Java exception(s) in the log |
| 11 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28366 at 15:44:06

```text
[ZeD.QA] state #1 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 28367 at 15:44:12

```text
[ZeD.QA] state #2 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28368 at 15:44:16

```text
[ZeD.QA] state #3 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #3 ok=true
ZEDQA g14l DONE
```

### 4. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28369 at 15:44:20

```text
[ZeD.QA] state #4 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #4 ok=true
ZEDQA hcn DONE
```

### 5. gallery_story_stage.lua (`ZEDQA sts`) - PASS, 40 s

- go 28370 at 15:44:25

```text
[ZeD.QA] state #5 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sts start (22 steps)
[ZeD.QA] run #5 ok=true
ZEDQA sts start at 926,13040 | site: Fossoil, West Point | ZeD true
ZEDQA sts at the store: room fossoil, building true
ZEDQA sts stock spot 12053,7121 with 3 shelf containers in reach
ZEDQA sts counter 12054,7123 clerk 12053,7123 queue toward 1,0
ZEDQA sts pump 12066,7147 (location_shop_fossoil_01_13), 8 pump squares round the store
ZEDQA sts window 12063,7127, barricaded from 12063,7127
ZEDQA sts windows 9 (smashed 2, barricaded 0) | shelves 19 counters 7 other containers 13 | free floor 81
ZEDQA sts container types: cardboardbox=2 metal_shelves=1 shelves=14 shelvesmag=4 fridge=10 counter=7 cashregister=1
ZEDQA sts blood 12060,7121
ZEDQA sts smoke spot 12073,7130
ZEDQA sts aside: 7 worn, 0 on the belt, 117 items
ZEDQA sts worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Prescription_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
ZEDQA sts bag back (Base.Bag_ALICEpack_Army): 13 things
ZEDQA sts bag webbing (Base.Bag_ChestRig): 3 things
ZEDQA sts bag fannypackback (Base.Bag_FannyPackBack): 2 things
ZEDQA sts bag satchel (Base.Bag_Satchel_Leather): 2 things
ZEDQA sts loose: 19/19
ZEDQA sts belt: HuntingKnife@smallbeltleft Hammer@smallbeltright Pistol@holsterright Shotgun@back
ZEDQA sts character was: profession base:unemployed, 28 traits on, 42 perks kept
ZEDQA sts profession base:mechanics | traits base:mechanics2 SMOKER SPEED_DEMON STRONG DEXTROUS FAST_READER PRONE_TO_ILLNESS HEARTY_APPETITE SLOW_HEALER PACIFIST | skills Strength=9 Fitness=5 Mechanics=4 MetalWelding=1
ZEDQA sts power: option set true | pump square grid power true, no-power zone false
ZEDQA sts pumps filled: 8 | the pump reads 500
ZEDQA sts car placements to try: 80
ZEDQA sts note: placement 1 (12068,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 2 (12064,7147 N) no good: pump false, tank area free false
ZEDQA sts note: placement 3 (12068,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 4 (12064,7147 S) no good: pump false, tank area free false
ZEDQA sts note: placement 5 (12067,7149 E) no good: pump false, tank area free false
ZEDQA sts note: placement 6 (12065,7149 W) no good: pump false, tank area free false
ZEDQA sts note: placement 7 (12068,7148 N) no good: pump false, tank area free false
ZEDQA sts note: placement 8 (12068,7146 S) no good: pump false, tank area free false
ZEDQA sts note: placement 9 (12066,7150 E) no good: pump false, tank area free false
ZEDQA sts note: placement 10 (12069,7147 N) no good: pump false, tank area free false
ZEDQA sts car Base.CarStationWagon at 12063,7147 facing S: the pump finder sees 12066,7147 | tank area 12064.2,7145.9
ZEDQA sts car fuel 2.9 / 49.0
ZEDQA sts native zombies near the store made useless: 0
ZEDQA sts passive zombies outside: 7
ZEDQA sts blood on 1 squares | stains read back true | blood decals option 10
ZEDQA sts seeds: flyer fossoil2 read (was true) | journal true | note true star true
ZEDQA sts zoom 1.5
ZEDQA sts shot story_00_scout ok
ZEDQA sts staged: car true | zombies 7 outside | blood 1 | carried 44
ZEDQA sts end: 1 shots ok, 0 errors
ZEDQA sts DONE
```

### 6. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28371 at 15:45:07

```text
[ZeD.QA] state #6 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 32.6 of 8 kg, 61 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 35 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #6 ok=true
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (x3)
```

### 7. gallery_v1_a_common.lua (`ZEDQA g1c`) - PASS, 1 s

- go 28372 at 15:45:12
- late output from unl (4 line(s), not counted)

```text
[ZeD.QA] state #7 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1c helpers ready | ZeD loaded true | story staged true | load 12.3 of 8 kg, 26 items, Heavy Load 1
[ZeD.QA] run #7 ok=true
ZEDQA g1c DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x4)
```

### 8. gallery_v1_a_zed.lua (`ZEDQA g1z`) - FAIL, 61 s

- go 28373 at 15:45:16
- 6 Java exception(s) in the log
- late output from unl (59 line(s), not counted)

```text
[ZeD.QA] state #8 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1z start (86 steps)
[ZeD.QA] run #8 ok=true
ZEDQA g1z start at 12073,7130 | screen 3840x2160 | font size option 2 | ZeD dark teal small | pair open false
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z look light blue | the list view | default boxes logged next
ZEDQA g1z box default character 1813,877-2026,1157
ZEDQA g1z box default char 1134,0-1911,735
ZEDQA g1z box default world 1929,0-2706,735
ZEDQA g1z box default belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1z zoom 1
ZEDQA g1z first tabs: Character loot, World loot
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z shot g1_08_intro
ZEDQA g1z load g1_08_intro: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA g1z box g1_08_intro character 1760,776-2080,1196
ZEDQA g1z box g1_08_intro char 1134,0-1911,735
ZEDQA g1z box g1_08_intro world 1929,0-2706,735
ZEDQA g1z box g1_08_intro belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z shelf shelves at 12052,7121: 9 things it held set aside, 10 of 10 put in | capacity 50
ZEDQA g1z apples given: 3
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1z apple stack opened: 3
ZEDQA g1z World window shows the shelf true
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA g1z open stack: Apple (3)
ZEDQA g1z shot g1_17_zed
ZEDQA g1z load g1_17_zed: 12.9 of 18 kg, 29 items, Heavy Load 0
ZEDQA g1z box g1_17_zed character 1760,776-2080,1196
ZEDQA g1z box g1_17_zed char 1134,0-1911,735
ZEDQA g1z box g1_17_zed world 1929,0-2706,735
ZEDQA g1z box g1_17_zed belt 1439,2034-2378,2132
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1z zoom 0.75
ZEDQA g1z moved the Character window from x 1134 to x 21 (left side): it covered the character
ZEDQA g1z moved the World window from x 1929 to x 3042 (right side): it covered the character
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA g1z 01: the same moment as g1_17_zed, closer (zoom 0.75), for the before-and-after spread; if g1_17 reads at 116 x 65, 01 = 17's pair
ZEDQA g1z shot g1_01_zed
ZEDQA g1z load g1_01_zed: 12.9 of 18 kg, 29 items, Heavy Load 0
ZEDQA g1z box g1_01_zed character 1706,675-2133,1235
ZEDQA g1z box g1_01_zed char 21,0-798,735
ZEDQA g1z box g1_01_zed world 3042,0-3819,735
ZEDQA g1z box g1_01_zed belt 1439,2034-2378,2132
ZEDQA unl load 12.9 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1z zoom 1
ZEDQA g1z apples taken back: 3
ZEDQA g1z shelf back: 9 things it held, 10 taken out
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1z shot g1_21_equip_doll
ZEDQA g1z load g1_21_equip_doll: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA g1z box g1_21_equip_doll character 1760,776-2080,1196
ZEDQA g1z box g1_21_equip_doll char 0,0-1617,735
ZEDQA g1z box g1_21_equip_doll belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z left forearm: scratched false, bandaged true
ZEDQA unl load 12.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1z shot g1_26_zed
ZEDQA g1z load g1_26_zed: 12.3 of 18 kg, 28 items, Heavy Load 0
ZEDQA g1z box g1_26_zed character 1760,776-2080,1196
ZEDQA g1z box g1_26_zed char 0,0-1617,735
ZEDQA g1z box g1_26_zed belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA g1z left forearm: scratched false, bandaged false
ZEDQA unl load 12.3 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
    Lua fail. Message: Tried to call nil
    se.krka.kahlua.vm.KahluaUtil.fail(KahluaUtil.java:96)
    se.krka.kahlua.vm.KahluaUtil.luaAssert(KahluaUtil.java:90)
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:67)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
    Lua(Vanilla).pcall(spawnpoints.lua:327)
    Lua(Vanilla).step(spawnpoints.lua:322)
    Lua(Vanilla).tick(spawnpoints.lua:88)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:842)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.stdlib.BaseLib.pcall(BaseLib.java:313)
    se.krka.kahlua.stdlib.BaseLib.call(BaseLib.java:111)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.vm.KahluaThread.pcallvoid(KahluaThread.java:1572)
    se.krka.kahlua.integration.LuaCaller.pcallvoid(LuaCaller.java:60)
    se.krka.kahlua.integration.LuaCaller.protectedCallVoid(LuaCaller.java:131)
    zombie.Lua.Event.trigger(Event.java:55)
    zombie.Lua.LuaEventManager.triggerEvent(LuaEventManager.java:355)
    zombie.Lua.LuaEventManager.triggerEventGarbage(LuaEventManager.java:366)
    zombie.characters.IsoGameCharacter$XP.AddXP(IsoGameCharacter.java:14528)
    zombie.characters.IsoGameCharacter$XP.AddXP(IsoGameCharacter.java:14370)
    zombie.characters.IsoGameCharacter$XP.AddXP(IsoGameCharacter.java:14336)
    zombie.characters.IsoGameCharacter$XP.AddXPNoMultiplier(IsoGameCharacter.java:14361)
    java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)
    java.base/java.lang.reflect.Method.invoke(Unknown Source)
    se.krka.kahlua.integration.expose.caller.MethodCaller.call(MethodCaller.java:58)
    se.krka.kahlua.integration.expose.LuaJavaInvoker.call(LuaJavaInvoker.java:194)
    se.krka.kahlua.integration.expose.LuaJavaInvoker.call(LuaJavaInvoker.java:184)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.stdlib.BaseLib.pcall(BaseLib.java:313)
    se.krka.kahlua.stdlib.BaseLib.call(BaseLib.java:111)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.stdlib.BaseLib.pcall(BaseLib.java:313)
    se.krka.kahlua.stdlib.BaseLib.call(BaseLib.java:111)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.vm.KahluaThread.pcallvoid(KahluaThread.java:1572)
    se.krka.kahlua.integration.LuaCaller.pcallvoid(LuaCaller.java:60)
    se.krka.kahlua.integration.LuaCaller.protectedCallVoid(LuaCaller.java:131)
    zombie.Lua.Event.trigger(Event.java:55)
    zombie.Lua.LuaEventManager.triggerEvent(LuaEventManager.java:248)
    zombie.ui.UIManager.render(UIManager.java:329)
    zombie.gameStates.IngameState.renderFrameUI(IngameState.java:1265)
    zombie.gameStates.IngameState.renderframeui(IngameState.java:1254)
    zombie.gameStates.IngameState.renderInternal(IngameState.java:1364)
    zombie.gameStates.IngameState.render(IngameState.java:1322)
    zombie.gameStates.GameStateMachine.render(GameStateMachine.java:24)
    zombie.GameWindow.renderInternal(GameWindow.java:459)
    zombie.GameWindow.frameStep(GameWindow.java:801)
    zombie.GameWindow.mainThreadStep(GameWindow.java:568)
    zombie.MainThread.mainLoop(MainThread.java:69)
    java.base/java.lang.Thread.run(Unknown Source)
ERROR: General f:6361> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:67)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ERROR: General f:6361> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:67)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ERROR: General f:6361> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:67)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ERROR: General f:6361> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:69)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ERROR: General f:6361> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:69)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ERROR: General f:6361> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:69)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ZEDQA g1z skills Mechanics=7 Maintenance=6 MetalWelding=6 Electricity=3 Woodwork=3 SmallBlunt=3 Cooking=2 Sprinting=2 Sneak=2 Doctor=2 Lightfoot=1 Nimble=1 PlantScavenging=1 Aiming=1 Fitness=6 | kills 23
ZEDQA g1z tall: height 735 -> 1857, at the left edge x 21
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1z shot g1_39_identity_tall
ZEDQA g1z load g1_39_identity_tall: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA g1z box g1_39_identity_tall character 1760,776-2080,1196
ZEDQA g1z box g1_39_identity_tall char 21,0-1638,1857
ZEDQA g1z box g1_39_identity_tall belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1z shot g1_39_identity_traits
ZEDQA g1z load g1_39_identity_traits: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA g1z box g1_39_identity_traits character 1760,776-2080,1196
ZEDQA g1z box g1_39_identity_traits char 21,0-1638,1857
ZEDQA g1z box g1_39_identity_traits belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1z shot g1_39_skills_tall
ZEDQA g1z load g1_39_skills_tall: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA g1z box g1_39_skills_tall character 1760,776-2080,1196
ZEDQA g1z box g1_39_skills_tall char 21,0-1638,1857
ZEDQA g1z box g1_39_skills_tall belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z put back: the window's height, kills 318 (skills go back with the teardown)
ZEDQA unl load 15.4 of 18 kg, 30 items, Heavy Load 0   (late output from unl)   (x4)
ZEDQA g1z dish Stew | plan Base.Carrots, Base.Potato, Base.Cabbage
ZEDQA unl load 15.4 of 18 kg, 30 items, Heavy Load 0   (late output from unl)
ZEDQA g1z shot g1_35_stew_plan
ZEDQA g1z load g1_35_stew_plan: 15.4 of 18 kg, 30 items, Heavy Load 0
ZEDQA g1z box g1_35_stew_plan character 1760,776-2080,1196
ZEDQA g1z box g1_35_stew_plan char 1134,0-2751,735
ZEDQA g1z box g1_35_stew_plan belt 1439,2034-2378,2132
ZEDQA unl load 15.4 of 18 kg, 30 items, Heavy Load 0   (late output from unl)
ZEDQA g1z saved dishes: 1
ZEDQA unl load 15.4 of 18 kg, 30 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1z shot g1_35_dish_list
ZEDQA g1z load g1_35_dish_list: 15.4 of 18 kg, 30 items, Heavy Load 0
ZEDQA g1z box g1_35_dish_list character 1760,776-2080,1196
ZEDQA g1z box g1_35_dish_list char 1134,0-2751,735
ZEDQA g1z box g1_35_dish_list belt 1439,2034-2378,2132
ZEDQA unl load 15.4 of 18 kg, 30 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.3 of 16 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1z zoom 1
ZEDQA unl load 12.3 of 16 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1z moodles left: 3 on (HUNGRY 2, STRESS 2, THIRST 2) | balloon on STRESS (idx 2) at 70,71 370x86.19140625, tail to nil,nil
ZEDQA g1z shot g1_25_left
ZEDQA g1z load g1_25_left: 12.3 of 16 kg, 26 items, Heavy Load 0
ZEDQA g1z box g1_25_left character 1760,776-2080,1196
ZEDQA g1z box g1_25_left moodles 10,998-58,3158
ZEDQA g1z box g1_25_left belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 16 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1z moodles bottom: 3 on (HUNGRY 2, STRESS 2, THIRST 2) | balloon on STRESS (idx 2) at 68,-108.19140625 370x86.19140625, tail to nil,nil
ZEDQA g1z shot g1_25_bottom
ZEDQA g1z load g1_25_bottom: 12.3 of 16 kg, 26 items, Heavy Load 0
ZEDQA g1z box g1_25_bottom character 1760,776-2080,1196
ZEDQA g1z box g1_25_bottom moodles 1838,1965-2002,2013
ZEDQA g1z box g1_25_bottom belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 16 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1z moodles right: 3 on (HUNGRY 2, STRESS 2, THIRST 2) | balloon on STRESS (idx 2) at -392,71 370x86.19140625, tail to nil,nil
ZEDQA g1z shot g1_25_right
ZEDQA g1z load g1_25_right: 12.3 of 16 kg, 26 items, Heavy Load 0
ZEDQA g1z box g1_25_right character 1760,776-2080,1196
ZEDQA g1z box g1_25_right moodles 3782,998-3830,3158
ZEDQA g1z box g1_25_right belt 1439,2034-2378,2132
ZEDQA unl load 12.3 of 16 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z left forearm: scratched false, bandaged false
ZEDQA g1z apples taken back: 0
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1z box put_back character 1760,776-2080,1196
ZEDQA g1z box put_back belt 1439,2034-2378,2132
ZEDQA g1z put back: look dark teal (was dark teal)
ZEDQA g1z end: 13 shots, 0 not taken or failed
ZEDQA g1z DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x4)
```

### 9. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28374 at 15:46:20

```text
[ZeD.QA] state #9 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA rel put back 35 things; after: 32.6 of 18 kg, 61 items, Heavy Load 1 OVER
[ZeD.QA] run #9 ok=true
ZEDQA rel DONE
```

### 10. gallery_story_teardown.lua (`ZEDQA stt`) - FAIL, 10 s

- go 28375 at 15:46:25
- 6 Java exception(s) in the log

```text
[ZeD.QA] state #10 speed=1 paused=false player=12073,7130 grid=19 inCar=false vehicles=12 missing=get
[ZeD.QA] windows reset (R)
ZEDQA stt start (17 steps)
[ZeD.QA] run #10 ok=true
ZEDQA stt removed 7 zombies, 1 cars, 0 ground things; 0 native zombies' flag back
ZEDQA stt planks off 0 | blood cleaned on 1 | lights off 0 | pumps back 8 | sandbox back
ZEDQA stt kit off: 18 worn, 44 items removed
ZEDQA stt back: 117 items, 7 worn
ZEDQA stt belt back: 0/0
    Lua fail. Message: Tried to call nil
    se.krka.kahlua.vm.KahluaUtil.fail(KahluaUtil.java:96)
    se.krka.kahlua.vm.KahluaUtil.luaAssert(KahluaUtil.java:90)
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:67)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
    Lua(Vanilla).pcall(spawnpoints.lua:180)
    Lua(Vanilla).step(spawnpoints.lua:176)
    Lua(Vanilla).onFrame(spawnpoints.lua:114)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:842)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.stdlib.BaseLib.pcall(BaseLib.java:313)
    se.krka.kahlua.stdlib.BaseLib.call(BaseLib.java:111)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.vm.KahluaThread.pcallvoid(KahluaThread.java:1572)
    se.krka.kahlua.integration.LuaCaller.pcallvoid(LuaCaller.java:60)
    se.krka.kahlua.integration.LuaCaller.protectedCallVoid(LuaCaller.java:131)
    zombie.Lua.Event.trigger(Event.java:55)
    zombie.Lua.LuaEventManager.triggerEvent(LuaEventManager.java:355)
    zombie.Lua.LuaEventManager.triggerEventGarbage(LuaEventManager.java:366)
    zombie.characters.IsoGameCharacter$XP.AddXP(IsoGameCharacter.java:14528)
    zombie.characters.IsoGameCharacter$XP.AddXP(IsoGameCharacter.java:14370)
    zombie.characters.IsoGameCharacter$XP.AddXP(IsoGameCharacter.java:14336)
    zombie.characters.IsoGameCharacter$XP.AddXPNoMultiplier(IsoGameCharacter.java:14361)
    java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)
    java.base/java.lang.reflect.Method.invoke(Unknown Source)
    se.krka.kahlua.integration.expose.caller.MethodCaller.call(MethodCaller.java:58)
    se.krka.kahlua.integration.expose.LuaJavaInvoker.call(LuaJavaInvoker.java:194)
    se.krka.kahlua.integration.expose.LuaJavaInvoker.call(LuaJavaInvoker.java:184)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.stdlib.BaseLib.pcall(BaseLib.java:313)
    se.krka.kahlua.stdlib.BaseLib.call(BaseLib.java:111)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.stdlib.BaseLib.pcall(BaseLib.java:313)
    se.krka.kahlua.stdlib.BaseLib.call(BaseLib.java:111)
    se.krka.kahlua.vm.KahluaThread.callJava(KahluaThread.java:178)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:795)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.vm.KahluaThread.pcallvoid(KahluaThread.java:1572)
    se.krka.kahlua.integration.LuaCaller.pcallvoid(LuaCaller.java:60)
    se.krka.kahlua.integration.LuaCaller.protectedCallVoid(LuaCaller.java:131)
    zombie.Lua.Event.trigger(Event.java:55)
    zombie.Lua.LuaEventManager.triggerEvent(LuaEventManager.java:248)
    zombie.GameWindow.onRender(GameWindow.java:866)
    zombie.GameWindow.frameStep(GameWindow.java:805)
    zombie.GameWindow.mainThreadStep(GameWindow.java:568)
    zombie.MainThread.mainLoop(MainThread.java:69)
    java.base/java.lang.Thread.run(Unknown Source)
ERROR: General f:9681> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:67)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ERROR: General f:9681> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:67)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ERROR: General f:9681> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:67)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ERROR: General f:9681> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:69)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ERROR: General f:9681> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:69)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ERROR: General f:9681> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException:  at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).colourOf(ZeD_HaloText.lua:47)
    Lua((MOD:ZeD-GUI)).toneOf(ZeD_HaloText.lua:69)
    Lua((MOD:ZeD-GUI)).addTextWithArrow(ZeD_HaloText.lua:136)
    Lua(Vanilla).addXp(XpUpdate.lua:191)
ZEDQA stt character back: profession base:unemployed | 97 traits | 42 perks
ZEDQA stt seeds back: flyer read true | journal entries removed 1 | map marks removed 2
ZEDQA stt ZeD back: dark teal small (was dark teal small)
ERROR: General f:9725 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA stt zoom 1
ZEDQA stt back at 926,13040 (was 926,13040) | carried 117 | zombies in the cell 0
ZEDQA stt end: 0 shots ok, 0 errors
ZEDQA stt DONE
```

### 11. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28376 at 15:46:38

```text
[ZeD.QA] state #11 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #11 ok=true
ZEDQA g14e DONE
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
